//
//  export.m
//  Cindex
//
//  Created by PL on 4/23/05.
//  Copyright 2005 Indexing Research. All rights reserved.
//

#import "export.h"
#import "IRIndexArchive.h"
#import "records.h"
#import "type.h"
#import "strings_c.h"
#import "formattedtext.h"
#import "formattedexport.h"
#import "rtfwriter.h"
#import "textwriter.h"
#import "commandutils.h"
#import "iconv.h"
#import "xmlwriter.h"
#import "group.h"
#import "utime.h"

static char * xmlheader =
"<?xml version=\"1.0\" encoding=\"UTF-8\"?>\n\
<!DOCTYPE indexdata [\n\
<!ELEMENT indexdata (source, fonts, records) >\n\
<!ELEMENT source EMPTY >\n\
<!ATTLIST source\n\
	creator CDATA #REQUIRED\n\
	version CDATA #REQUIRED\n\
	time CDATA #REQUIRED >\n\
<!-- creator is code source, e.g., \"cindex\" -->\n\
<!-- time value is UTC in this format: 2011-03-03T03:41:14 -->\n\
<!ELEMENT fonts (font+) >\n\
<!ELEMENT font (fname, aname) >\n\
<!ATTLIST font\n\
	id CDATA #REQUIRED >\n\
<!ELEMENT fname (#PCDATA) >\n\
<!ELEMENT aname (#PCDATA) >\n\
<!ELEMENT records (record)* >\n\
<!ATTLIST records\n\
	type CDATA #IMPLIED\n\
	loc-separator CDATA #IMPLIED\n\
	loc-connector CDATA #IMPLIED\n\
	xref-separator CDATA #IMPLIED >\n\
<!-- type value is integer (Cindex: 1 for required last field) -->\n\
<!-- loc-separator value is single ASCII character (Cindex default: ,) -->\n\
<!-- loc-connector value is single ASCII character (Cindex default: -) -->\n\
<!-- xref-separator value is single ASCII character (Cindex default: ;) -->\n\
<!ELEMENT record (field+) >\n\
<!ATTLIST record\n\
	time CDATA #REQUIRED\n\
	id CDATA #IMPLIED\n\
	user CDATA #IMPLIED\n\
	label CDATA #IMPLIED\n\
	deleted (y | n) #IMPLIED\n\
	type CDATA #IMPLIED >\n\
<!-- time value is UTC in this format: 2008-08-02T16:27:44 -->\n\
<!-- id value is integer (unique within file) -->\n\
<!-- label value is integer -->\n\
<!-- type value can be \"generated\" (automatically generated) -->\n\
<!ELEMENT field (#PCDATA | text | literal | hide | sort)* >\n\
<!ATTLIST field\n\
	class CDATA #IMPLIED >\n\
<!-- class value can be \"locator\" -->\n\
<!ELEMENT text EMPTY >\n\
<!ATTLIST text\n\
	font CDATA #IMPLIED\n\
	color CDATA #IMPLIED\n\
	smallcaps ( y | n ) #IMPLIED\n\
	style ( b | i | u | bi | bu | iu | biu ) #IMPLIED\n\
	offset ( u | d ) #IMPLIED\n\
>\n\
<!-- font and color attribute values are integers in range 0-31 -->\n\
<!-- color attribute currently not used by Cindex -->\n\
<!ELEMENT literal EMPTY >\n\
<!-- literal: forces the succeeding character to be used in sort (Cindex: ~) -->\n\
<!ELEMENT hide (#PCDATA) >\n\
<!-- hide: contains text to be ignored in sorting (Cindex: < >) -->\n\
<!ELEMENT sort (#PCDATA) >\n\
<!-- sort: contains text to be used in sorting but not displayed (Cindex: { }) -->\n\
]>\n";

static const char *protected = "<>&'\"";
static const char *protectedstrings[] = {"&lt;","&gt;","&amp;","&apos;","&quot;"};

static char * writearchiverecords(char * wfptr, INDEX * FF, EXPORTPARAMS * exp, short *fontids);	// writes records as archive
static char * writexmlrecords(char * wfptr, INDEX * FF, EXPORTPARAMS * exp, short *fontids);	// writes records as xml
static char * writerawtext(char * fptr, char *sptr);	/* write field as plain text */
static char * writefordos(char * fptr, char *sptr);	/* write field for DOS */
static BOOL convertrecordtext(char * outbuff, char * text);	// converts record to V2 form
static char charfromsymbol(unichar uc);		// returns symbol font char for unicode
static char * timestring(time_c time);	// returns time string
static char * xmlchartostring( char xc);		// appends character (escaped as necessary)

static iconv_t converter;
/******************************************************************************/
void export_setdefaultparams(INDEX * FF, int type)

{
	EXPORTPARAMS *ep = [FF->owner exportParameters];
	char tsort = FF->head.sortpars.ison;
	char tdel = FF->head.privpars.hidedelete;
	
	memset(ep,0,sizeof(EXPORTPARAMS));
	memset(&FF->pf,0,sizeof(PRINTFORMAT));
	if (type == E_ARCHIVE)
		ep->extendflag = YES;
	if (type == E_TAB || type >= E_TEXTNOBREAK)	// if tabbed or formatted (other record formats all default unsorted)
		ep->sorted = FF->head.sortpars.ison;
	ep->type = type;
	ep->usetabs = g_prefs.gen.indentdef;	// default formatted indent from pref
	FF->head.sortpars.ison = ep->sorted;
	FF->head.privpars.hidedelete = !ep->includedeleted;
//	sort_setfilter(FF,ep->includedeleted ? SF_OFF : SF_HIDEDELETEONLY);
	ep->first = rec_number(sort_top(FF));
	ep->last = UINT_MAX;
	FF->head.sortpars.ison = tsort;
	FF->head.privpars.hidedelete = tdel;
//	sort_setfilter(FF, SF_VIEWDEFAULT);
}
/******************************************************************************/
NSData * export_writerecords(INDEX * FF, EXPORTPARAMS * exp)	/* forms export data as NSData */

{
	RECORD * curptr;
	RECN rnum;
	short farray[FONTLIMIT];
	NSMutableData * edata;
	char * wfbase;
	int wfbaselength;

	if (exp->appendflag)	{	// if appending to existing file
		edata = [NSMutableData dataWithContentsOfFile:FF->owner.lastSavedName];	// start with existing contents
		wfbaselength = [edata length];
		[edata increaseLengthBy:FF->head.rtot*FF->head.indexpars.recsize+sizeof(HEAD)];	// add space for new data
		wfbase = [edata mutableBytes]+wfbaselength;
	}
	else {
		edata = [NSMutableData dataWithLength:2*FF->head.rtot*FF->head.indexpars.recsize+sizeof(HEAD)];
		wfbaselength = 0;
		wfbase = [edata mutableBytes];
	}
	if (edata)   {	/* open file */
		char oldsort = FF->head.sortpars.ison;
		char olddel = FF->head.privpars.hidedelete;
		char * wfptr = wfbase;
		
		FF->head.sortpars.ison = exp->sorted;
		FF->head.privpars.hidedelete = !exp->includedeleted;
//		sort_setfilter(FF, exp->includedeleted ? SF_OFF : SF_HIDEDELETEONLY);
		memset(farray,0,sizeof(farray));
		for (rnum = 1; (curptr = rec_getrec(FF,rnum)); rnum++)		/* for all records */
			type_tagfonts(curptr->rtext,farray);		/* marks fonts used */
		if (exp->type == E_XMLRECORDS)
			wfptr = writexmlrecords(wfptr, FF,exp, farray);
		else
			wfptr = writearchiverecords(wfptr, FF,exp, farray);
		FF->head.sortpars.ison = oldsort;
		FF->head.privpars.hidedelete = olddel;
		[edata setLength:wfbaselength+wfptr-wfbase];
	}
	return (edata);
}
/******************************************************************************/
static char * writearchiverecords(char * wfbase, INDEX * FF, EXPORTPARAMS * exp, short *fontids)	// writes records as archive

{
	char * wfptr = wfbase;
	RECORD * curptr;
	char outbuff[MAXREC];
	CSTR fields[FIELDLIM];
	RECN rcount;
	short fieldcnt, ftot, efield;
	int curmax, newlen, deepest, count, writeindex;
	time_t modtime;

	if (exp->type == E_ARCHIVE)		
		wfptr += sprintf(wfptr,"xxxxxxxxxxxxxxxx");	/* reserve space for id stuff */
	if (exp->type == E_TAB && exp->encoding == 0)		
		wfptr += sprintf(wfptr,utf8BOM);	//write UTF-8 marker
	curptr = rec_getrec(FF,exp->first);	/* get start record */
	for (rcount = curmax = deepest = 0; curptr && curptr->num != exp->last ; curptr = sort_skip(FF,curptr,1), rcount++) {	  /* for all records */
		if (!*curptr->rtext)	 /* if not wanted or empty */
			continue;			/* don't write */
		if (exp->type == E_TAB && exp->encoding == 0)	// if exporting plain text & want utf-8
			str_xcpy(outbuff, curptr->rtext);		// maintain utf-8
		else
			exp->errorcount += convertrecordtext(outbuff, curptr->rtext);
		if ((ftot = str_xparse(outbuff, fields)) > deepest)		/* parse */
			deepest = ftot;
		if ((newlen = str_xlen(outbuff)) > curmax)     /* if this is longest field */
			curmax = newlen;
		for (fieldcnt = 0; fieldcnt < ftot-1; fieldcnt++)   { /* for all regular fields */
			if (exp->type == E_ARCHIVE)
				wfptr += sprintf(wfptr, "%s\t", fields[fieldcnt].str);  /* tab delimited */
			else if (exp->type == E_TAB)	{
				wfptr = writerawtext(wfptr,fields[fieldcnt].str);		/* write as plain text */
				*wfptr++ = '\t';
			}
			else	{
				wfptr = writefordos(wfptr,fields[fieldcnt].str);	/* write string, translating & stripping */
				*wfptr++ = '\t';
			}
		}
		for (efield = fieldcnt; efield < exp->minfields-1; efield++)     /* while not enough fields */
			wfptr += sprintf(wfptr, "\t");     /* pad with empty fields */
		if (exp->type == E_ARCHIVE)
			wfptr += sprintf(wfptr,"%s",fields[fieldcnt].str);	/* locator field */
		else if (exp->type == E_TAB)
			wfptr = writerawtext(wfptr,fields[fieldcnt].str);		/* write as plain text */
		else 
			wfptr = writefordos(wfptr,fields[fieldcnt].str);	/* write string, translating & stripping */
		if (exp->extendflag)	{
			char recflags = 0;
			
			if (exp->type == E_ARCHIVE)	{	/* if archive, save extra flags */
				if (curptr->label)	{	// build label value in compatible way
					// low order bit shifted 1 to left two high order bits shifted 2 to left
					recflags = ((curptr->label&1) << 1) + ((curptr->label&6) << 2);
				}
				if (curptr->isgen)
					recflags |= W_GENFLAG;
				if (FF->head.indexpars.required && fields[ftot-2].ln)	// if required field populated
					recflags |= W_PUSHLAST;
			}
			if (curptr->isdel)
				recflags |= W_DELFLAG;
			// DOS legacy: either flag is 64 (deleted) or space (not deleted)
			if (recflags)
				recflags |= 64;			/* allows DOS value to be 'A' */
			else
				recflags = SPACE;
			modtime = exp->type != E_DOS ? (time_t)unix_to_mw_time(curptr->time) : curptr->time;	// archive exported with time in mw format
			wfptr += sprintf(wfptr, "\023%c%lu %.4s", recflags, modtime, curptr->user);				
		}
		*wfptr++ = '\r';
		*wfptr++ = '\n';
	}
	if (exp->type == E_ARCHIVE)	{	/* if archive, add fixups */
		int curpos = (int)(wfptr-wfbase);

		for (writeindex = count = 0; count < FONTLIMIT; count++, writeindex++)	{
			if (fontids[count] || count < VOLATILEFONTS)	{	/* if this font was used or is protected */
				wfptr += sprintf(wfptr,"%d@@%s@@%s\r\n",writeindex,FF->head.fm[count].pname,FF->head.fm[count].name);	/* add its name */
				if (!writeindex)	{	// if have written first font, insert line for symbol
					wfptr += sprintf(wfptr,"%d@@%s@@%s\r\n",1,"Symbol","Symbol");
					writeindex++;	// increment id index
				}
			}
		}
		wfptr++;	// move beyond terminal '0'
		sprintf(wfbase,"\2\2\2\2%10d\r",curpos);	/* write version and info offset as header */
		wfbase[ARCHIVEOFFSET-1] = '\n';	// overwrite '\0' string terminator with terminal newline
		/* !!NB size of lead must be set in ARCHIVEOFFSET; must match dummy string length written at start */
	}
	exp->records = rcount;
	exp->longest = curmax+1;
	return wfptr;
}
/******************************************************************************/
static BOOL convertrecordtext(char * outbuff, char * text)	// converts record to V2 form

{
	char currentfont = FX_FONT;	// default font
	BOOL error = FALSE;
	char * sptr, *dptr;
	
	if (!converter)
		converter = iconv_open(V2_CHARSET,"UTF-8");
	for (sptr = text, dptr = outbuff; *sptr != EOCS; sptr = u8_forward1(sptr))		{
		unichar uc = u8_toU(sptr);
		
		if (uc >0x80)	{	// if needs conversion
			char * source = sptr;
			size_t sourcecount = u8_forward1(sptr)-sptr;	// number of bytes to convert
			size_t destcount = MAXREC-(dptr-outbuff);
			size_t length = iconv(converter,&source,&sourcecount,&dptr,&destcount);
			
			if ((int)length < 0)	{	// if error, assume unencodable char
				char symbolchar = charfromsymbol(uc);
				if (symbolchar)	{	// if good conversion
					char * tptr = sptr;
					*dptr++ = CODECHR;
					*dptr++ = FX_FONT|1;	// set symbol font
					do  {
						*dptr++ = symbolchar;
						tptr = u8_forward1(tptr);
					} while ((symbolchar = charfromsymbol(u8_toU(tptr))));		// while symbols to convert
					sptr = u8_back1(tptr);
					*dptr++ = CODECHR;
					*dptr++ = currentfont;	// restore prev font
				}
				else	{
					*dptr++ = (char)UNKNOWNCHAR;	// unknown char (Apple logo)
					error = TRUE;
				}
			}
		}
		else if (iscodechar(uc))	{
			if (uc == FONTCHR)	{	// if font
				if (*++sptr&FX_FONT)	{	// if font
					*dptr++ = CODECHR;	// change to code char
					currentfont = *sptr;
					if (currentfont&FX_FONTMASK)	// if it's not the default font
						currentfont++;	// increase id by 1 to allow for symbol font
					*dptr++ = currentfont;
				}
				else if (*sptr&FX_COLOR)	{	// if color
					*dptr++ = CODECHR;		// change to code char
					*dptr++ = *sptr|FX_FONT;	// add obligatory FX_FONT bit
				}
			}
			else {		// style code
				*dptr++ = *sptr++;	// copy codechar
				if (*sptr&FX_OFF)	// if off code
					*dptr++ = (*sptr&FX_STYLEMASK)|FX_OLDOFF;
				else		// normal 'on' style code
					*dptr++ = *sptr;
			}
		}
		else		// simple ascii char
			*dptr++ = uc;
	}
	*dptr = EOCS;
	return error;
}
/*******************************************************************************/
static char charfromsymbol(unichar uc)		// returns symbol font char for unicode

{
	int sindex;

	for (sindex = 0; sindex < 256; sindex++)	{
		if (t_specialfonts[0].ucode[sindex] == uc)
			return sindex;
	}
	return 0;
}
/******************************************************************************/
static char * writexmlrecords(char * wfptr, INDEX * FF, EXPORTPARAMS * exp, short *fontids)	// writes record as xml

{
	static const char *special = "\\~<>{}";
	static const char *specialstrings[] = {"<esc/>","<literal/>","<hide>","</hide>","<sort>","</sort>"};
	RECORD * curptr;
	CSTR fields[FIELDLIM];
	RECN rcount;
	short fieldcnt, ftot;
	char scapsstring[100], stylestring[100], fontstring[100], colorstring[100], offsetstring[100];
	char recordstype[100], recordstring[100], lseparator[100], xseparator[100], lconnector[100];
	char fieldclass[100];
	int font, style, color;
	int curmax, deepest,newlen, sindex;
	char * string, *tptr;

	wfptr += sprintf(wfptr, "%s", xmlheader); 
	wfptr += sprintf(wfptr, "<indexdata>\n"); 
	wfptr += sprintf(wfptr, "<source creator=\"cindex\" version=\"%d.%d\"%s/>\n", CINVERSION/100, CINVERSION%100,timestring((int)time(NULL)));
	wfptr += sprintf(wfptr, "<fonts>\n"); 
	for (int findex = 0; *FF->head.fm[findex].name; findex++)	{	// for all fonts claimed in index
		if (!findex || fontids[findex])	// if base font or another used
			wfptr += sprintf(wfptr, "<font id=\"%d\">\n\t<fname>%s</fname>\n\t<aname>%s</aname>\n</font>\n",findex,FF->head.fm[findex].pname,FF->head.fm[findex].name);
	}
	wfptr += sprintf(wfptr, "</fonts>\n"); 
	*recordstype = *lseparator = *xseparator = '\0';
	if (FF->head.indexpars.required)	// if required last field
		sprintf(recordstype," type=\"1\"");		// 1 is required last field
//	if (FF->head.refpars.psep != ',')	// if page separator not comma
	sprintf(lseparator," loc-separator=\"%s\"",xmlchartostring(FF->head.refpars.psep));	// form it
	sprintf(lconnector," loc-connector=\"%s\"",xmlchartostring(FF->head.refpars.rsep));	// form it
//	if (FF->head.refpars.csep != ';')	// if page separator not semicolon
	sprintf(xseparator," xref-separator=\"%s\"",xmlchartostring(FF->head.refpars.csep));	// form it
	wfptr += sprintf(wfptr, "<records%s%s%s%s>\n",recordstype,lseparator,xseparator,lconnector);
	curptr = rec_getrec(FF,exp->first);	/* get start record */
	for (rcount = curmax = deepest = 0; curptr && curptr->num != exp->last; curptr = sort_skip(FF,curptr,1), rcount++) {	  /* for all records */
		
		*recordstring = '\0';
		tptr = recordstring;
		if (!*curptr->rtext)	 /* if not wanted or empty */
			continue;			/* don't write */
		if ((ftot = str_xparse(curptr->rtext, fields)) > deepest)		/* parse */
			deepest = ftot;
		if ((newlen = str_xlen(curptr->rtext)) > curmax)     /* if this is longest field */
			curmax = newlen;
			
		// set record attributes
		tptr += sprintf(tptr,"%s",timestring(curptr->time));
		tptr += sprintf(tptr," id=\"%d\"",curptr->num);
		if (*curptr->user)
			tptr += sprintf(tptr," user=\"%.4s\"",curptr->user);
		if (curptr->label)
			tptr += sprintf(tptr," label=\"%d\"",curptr->label);
		if (curptr->isdel)
			tptr += sprintf(tptr," deleted=\"y\"");
		if (curptr->isgen)
			sprintf(tptr," type=\"generated\"");
		wfptr += sprintf(wfptr, "<record%s>\n",recordstring); 
		for (fieldcnt = 0; fieldcnt < ftot; fieldcnt++)   { /* for all fields */
			if (fields[fieldcnt].ln || fieldcnt == ftot-1)	{	// if field has content or is locator
				font = style = color = 0;
				*fieldclass = '\0';
				// set field attributes
				
				if (fieldcnt == ftot-1)
					sprintf(fieldclass," class=\"locator\"");
				wfptr += sprintf(wfptr, "\t<field%s>", fieldclass);
				*fontstring = '\0';			// 4/17/2017
				for (sindex = 0, string = fields[fieldcnt].str; sindex < fields[fieldcnt].ln; sindex++)	{
					if (iscodechar(string[sindex]))	{
//						*scapsstring = *stylestring = *fontstring = *colorstring = *offsetstring = '\0';
						*scapsstring = *stylestring = *colorstring = *offsetstring = '\0';	// 4/17/2017
						do	{	// while in code chars, accumulate composite code
							if (string[sindex++] == FONTCHR)	{
								if (string[sindex]&FX_COLOR)	{
									color = string[sindex]&FX_COLORMASK;
									if (color)
										// configure color value
										sprintf(colorstring, " color=\"%d\"",color);
								}
								else {
									font = string[sindex]&FX_FONTMASK;
//									if (font)							// 4/17/207
										sprintf(fontstring, " font=\"%d\"",font);
								}
							}
							else	{	// style code
								if (string[sindex]&FX_OFF)
									style &= ~(string[sindex]&FX_STYLEMASK);
								else
									style |= string[sindex];
							}
							if (style)	{
								char stylechars[7];
								int stindex = 0;
								memset(stylechars,0, sizeof(stylechars));
								if (style&FX_BOLD)
									stylechars[stindex++] = 'b';
								if (style&FX_ITAL)
									stylechars[stindex++] = 'i';
								if (style&FX_ULINE)
									stylechars[stindex++] = 'u';
#if 0
								if (style&FX_SMALL)
									stylechars[stindex++] = 's';
								if (style&FX_SUPER)
									stylechars[stindex++] = 'u';
								if (style&FX_SUB)
									stylechars[stindex++] = 'd';
#endif
								if (style&FX_SMALL)
									strcpy(scapsstring, " smallcaps=\"y\"");
								if (stindex)	// if any style chars to emit
									sprintf(stylestring, " style=\"%s\"",stylechars);
								if (style&FX_SUPER)
									strcpy(offsetstring," offset=\"u\"");
								else if (style&FX_SUB)
									strcpy(offsetstring," offset=\"d\"");
							}
							sindex++;
						} while (iscodechar(string[sindex]));
						wfptr += sprintf(wfptr,"<text%s%s%s%s%s/>",scapsstring,stylestring, offsetstring,fontstring, colorstring);
					}
					if (string[sindex]) {
						if ((tptr = strchr(special, string[sindex])))	{	// ~\{} <>
							switch (*tptr)	{
								case KEEPCHR:
									if (string[++sindex])	// if a char follows
										wfptr += sprintf(wfptr,"%s", specialstrings[tptr-special]);	// emit tag; follow through with char
									break;
								case ESCCHR:
									if (string[++sindex])	// if a char follows
										break;		// break to emit it
								case OBRACE:
								case CBRACE:
								case OBRACKET:
								case CBRACKET:
									wfptr += sprintf(wfptr,"%s", specialstrings[tptr-special]);	// emit tag and continue
								continue;
							}
						}
						if ((tptr = strchr(protected, string[sindex])))	// if protected char
							wfptr += sprintf(wfptr,"%s",protectedstrings[tptr-protected]);
						else			// normal write
							*wfptr++ = string[sindex];
					}
				}
				wfptr += sprintf(wfptr, "</field>\n");
			}
		}
		wfptr += sprintf(wfptr, "</record>\n");
	}
	wfptr += sprintf(wfptr, "</records>\n"); 
	wfptr += sprintf(wfptr, "</indexdata>\n");
	exp->records = rcount;
	exp->longest = curmax+1;
	return wfptr;
}
/******************************************************************************/
NSData * export_writestationery(INDEX * FF, EXPORTPARAMS * exp)	/* forms export stationery as NSData */

{
	return [NSData dataWithBytes:&FF->head length:HEADSIZE];
}
/****************************************************************************/
void export_pastabletext(NSMutableData * edata,INDEX * FF, BOOL rtf)	/* generates embedded text */

{
	FCONTROLX * xptr = rtf ? &rtfcontrol : &textcontrol;	// always rtf if draft format
	NSRange rr = [FF->owner selectionMaxRange];
	RECORD * curptr = rec_getrec(FF,rr.location);	/* get start record */
	char * baseptr = [edata mutableBytes];
	
	xptr->newlinestring = "\r";	/* set newline string */
	xptr->usetabs = g_prefs.gen.indentdef;		/* set leader tab control */
	xptr->esptr = baseptr;
	FF->typesetter = xptr;
	
	if (FF->head.privpars.vmode == VM_FULL)	{		/* if fully formatted */
		(xptr->efstart)(FF,xptr);	/*  initialize */
		for (; curptr && curptr->num != rr.length; curptr = form_skip(FF,curptr,1))	  /* for all records */
			formexport_buildentry(FF, curptr);
	}
	else	{		// draft (thus embedded entry)
		if (rtf) {
			strcpy(xptr->esptr,"{\\rtf1\\mac");	/* generate header */
			xptr->esptr += strlen(xptr->esptr);
			rtf_setfonts(FF, xptr);			/* and font table */
		}
		for (; curptr && curptr->num != rr.length; curptr = [FF->owner skip:1 from:curptr])
			(xptr->efembed)(FF, xptr, curptr);	/* generate text */
	}
	(xptr->efend)(FF,xptr);	/* build end string */
	[edata setLength:xptr->esptr-baseptr];		// set correct length of data
}
/******************************************************************************/
static char * writerawtext(char * fptr, char *sptr)	/* write field as plain text */

{	
	while (*sptr)	{			/* for all chars */
		if (iscodechar(*sptr))	{	/* if codechar */
			if (*++sptr)
				sptr++;			/* discard code */
		}
		else if (*sptr == ESCCHR || *sptr == KEEPCHR)	{	// if escaped char
			if (*++sptr)	// pass over it
				*fptr++ = *sptr++;	// force write of next char
		}
		else if (*sptr == OBRACKET || *sptr == CBRACKET)	// if open or close ignored text
			sptr++;		// discard
		else if (*sptr == OBRACE)
			sptr = str_skiptoclose(++sptr, CBRACE);	// skip to char after closing brace
		else
			*fptr++ = *sptr++;
	}
	return fptr;
}
/******************************************************************************/
static char * writefordos(char * fptr, char *sptr)	/* write field for DOS */

{
	int index, codeindex, transsymbol;
	char *xptr;
	
	transsymbol = FALSE;
	// text is already converted to v2 form
	while (*sptr)	{	/* for all chars */
		if (*sptr == FONTCHR)	{
			if (*++sptr && ((*sptr++)&FX_FONTMASK) == 1)	/* if symbol font */
				transsymbol = TRUE;
			else
				transsymbol = FALSE;
		}
		else if (*sptr == CODECHR)	{
			if (*++sptr)	{		/* if a style code follows */
				for (index = 0, codeindex = 1; codeindex < FX_FONT; codeindex <<= 1, index++)	{
					if (*sptr&codeindex)	{	/* if this code is active */
						*fptr++ = '\\';	/* send code(s) */
						*fptr++ = tr_escname[(index<<1) + (*sptr&FX_OFF ? 1 : 0)];	/* set code */
					}
				}
				sptr++;
			}
		}
		else {
			if (*sptr < 0)	/* extended char */
				*fptr++ = mac_to_dos[(unsigned char)(*sptr++)-128];
			else	{	/* ordinary character */
				if (transsymbol && (xptr = strchr(dos_greek,*sptr)))	/* if in symbol font and char for translation */
					*fptr++ = dos_fromsymbol[xptr-dos_greek];
				else
					*fptr++ = *sptr;
				sptr++;
			}
		}
	}
	return fptr;
}
/******************************************************************************/
static char * timestring(time_c time)	// returns time string

{
	static char ts[40];
#if 1
	sprintf(ts," time=\"%s\"",time_stringFromTime(time, FALSE));
	return ts;
#else
	time_t ttime = time;
	struct tm * rectime = gmtime(&ttime);
	
	if (ttime >= 0) {
		sprintf(ts," time=\"%d-%02d-%02dT%02d:%02d:%02d\"",rectime->tm_year+1900,rectime->tm_mon+1,rectime->tm_mday,rectime->tm_hour,rectime->tm_min,rectime->tm_sec);
		return ts;
	}
	return " time=\"1970-01-01T00:00:00\"";
#endif
}
/******************************************************************************/
static char * xmlchartostring( char xc)		// appends character (escaped as necessary)

{
	static char cs[2];
	
	char * tptr;
	if ((tptr = strchr(protected, xc)))	// if protected char
		return (char *)protectedstrings[tptr-protected];
	else {		// normal write
		cs[0] = xc;
		cs[1] = '\0';
		return cs;
	}
}

//
//  import.m
//  Cindex
//
//  Created by Peter Lennie on 2/3/11.
//  Copyright 2011 Indexing Research. All rights reserved.
//

#import "import.h"
#import "ReplaceFontController.h"
#import "index.h"
#import "type.h"
#import "sort.h"
#import "records.h"
#import "commandutils.h"
#import "strings_c.h"
#import "cindexmenuitems.h"
#import "v3handler.h"
#import "ManageFontController.h"
#import "regex.h"

typedef struct {
	char * in;
	char * out;
} ctrans;

typedef struct {
	char * data;
	ctrans * translations;
} transet;

static FONTMAP sfm[] = {{"Symbol","Symbol",CHARSETSYMBOLS},{"Courier New","Courier New",0},{"Times New Roman","Times New Roman",0}};	// sky 7 set

//static char scodes[] = "biukcps";	// k and c are both small caps
//static char ccodes[] = {FX_BOLD,FX_ITAL,FX_ULINE,FX_SMALL,FX_SMALL,FX_SUPER,FX_SUB};
//static char mcodes[] = "ASUasu";	/* MACREX small caps, super, sub */
//static char mtrans[] = "iudIUD";	/* our (DOS) trans from Macrex ital, super, sub */
static char * mpageset = "0123456789-|^\\., :";	/* permissible chars in MACREX page ref */

static BOOL checkline(INDEX * FF, IMPORTPARAMS *imp, char * fbuff, RECORD * recptr);	
static BOOL isgoodchar(int type, unsigned char * ch);
static unsigned long findfontbase(IMPORTPARAMS *imp,char * readbase, unsigned long datalength);
static BOOL setfonts(INDEX * FF, IMPORTPARAMS *imp, char * data, unsigned long exroffset);
static BOOL setskyfonts(INDEX * FF, IMPORTPARAMS *imp);
static BOOL getreplacementfont(char * fname);
static void manageSky(IMPORTPARAMS *imp, char * fbuff);
static void manageMacrex(IMPORTPARAMS *imp, char * fbuff);
static void translatestrings(char * base, ctrans * trans);
static ctrans * loadtranslationset(char * name, char ** savedstring);

/***************************************************************************/
BOOL imp_findtexttype(IMPORTPARAMS * imp, char * data, unsigned long datalength)

{
	char * eptr = data+datalength;
	char * base, *tptr;
	int mlimit;
	
	imp->type = I_PLAINTAB;	// default text type is plain
	imp->subtype = TEXTKEY_NATIVE;	// default is native
	if (!strncmp(data,utf8BOM,strlen(utf8BOM)))		{	// if utf-8
		imp->subtype = TEXTKEY_UTF8;
		data += strlen(utf8BOM);
	}
	while (*data == '\r' || *data == '\n')		// skip leading blank lines
		data++;
	mlimit = eptr-data > MAXREC ? MAXREC : eptr-data;
	if (!(tptr = memchr(data,'\r',mlimit)) && !(tptr = memchr(data,'\n',mlimit)))	// no first line ending within record limit
		return NO;
	else if (!memchr(data, '\t',mlimit)) {	// can't be tab-delimited (might be single field import)
		if (memchr(data,*imp->sepstr,mlimit))	// if quote-delimited ... stronger test?
			imp->delimited = YES;
		else	// can't be quoted
			return NO;		//!! error
	}
	if ((base = strnstr(data,"/b1",eptr-data)) && ((tptr = strchr(base,'\r')) || (tptr = strchr(base,'\n'))) && tptr-base < MAXREC && strnstr(base,"/b0",tptr-base) ||	// if bold codes
		(base = strnstr(data,"/i1",eptr-data)) && ((tptr = strchr(base,'\r')) || (tptr = strchr(base,'\n'))) && tptr-base < MAXREC && strnstr(base,"/i0",tptr-base)	||	// or ital codes
		(base = strnstr(data,"/u1",eptr-data)) && ((tptr = strchr(base,'\r')) || (tptr = strchr(base,'\n'))) && tptr-base < MAXREC && strnstr(base,"/u0",tptr-base)	|| // or underline codes
		(base = strnstr(data,"/z1",eptr-data)) && ((tptr = strchr(base,'\r')) || (tptr = strchr(base,'\n'))) && tptr-base < MAXREC && strnstr(base,"/z0",tptr-base)	|| // or hidden text
		(base = strnstr(data,"/y1",eptr-data)) && ((tptr = strchr(base,'\r')) || (tptr = strchr(base,'\n'))) && tptr-base < MAXREC && strnstr(base,"/y0",tptr-base)	)	//  or ignored text
		imp->type = I_SKY;
	return YES;
}
/***************************************************************************/
int imp_readrecords(INDEX * FF, IMPORTPARAMS * imp, char * data, unsigned long datalength)

{
	char fbuff[MAXREC*3];		// space for fields + (room for expanding codes before length test)
	RECN num;
	unsigned long ctot;
	RECORD * recptr, trec;
	int err = 0, index;
	int length;
	unsigned long baseoffset = 0;
	unsigned long exroffset = datalength;

	imp->mode = PM_SCAN;
	if (imp->type == I_CINARCHIVE)	{
		if (*(int*)data == KEY_WIN)
			imp->subtype = KEY_WIN;
		else if (*(int*)data == KEY_MAC)
			imp->subtype = KEY_MAC;
		else
			imp->subtype = KEY_UNKNOWN;
		if (imp->subtype != KEY_UNKNOWN) {
			exroffset = findfontbase(imp,data,datalength);
			baseoffset = ARCHIVEOFFSET;
			if (!setfonts(FF, imp,data,exroffset))		// if can't set up archive
				return FALSE;
		}
	}
	else if (imp->type == I_SKY)	{	// sky
		str_setgetlimits(data, datalength);	// set up reader
		imp->subtype = KEY_WIN;
		baseoffset = str_getline(fbuff, MAXREC,&length)-data;	// get offset to discard first line
		if (strnstr(data,"/f0",datalength) || strnstr(data,"/f1",datalength) || strnstr(data,"/f2",datalength) || strnstr(data,"/f3",datalength))	{	// if before version 8
			memcpy(imp->tfm,&FF->head.fm[0],sizeof(FONTMAP));	// always initialized with current default font
			memcpy(&imp->tfm[1],sfm,sizeof(sfm));			// add fixed set of alternate fonts for sky 7
			imp->skytype = SKYTYPE_7;
		}
		else if (u8_isvalidUTF8(data, (int32_t)datalength))	{	// could be unicode if v8 -- do big check
			memcpy(imp->tfm,&FF->head.fm,sizeof(imp->tfm));		// always initialized with current font set
			imp->subtype = TEXTKEY_UTF8;
			imp->skytype = SKYTYPE_8;
		}
	}
	else if (imp->type == I_PLAINTAB)	{
		if (imp->subtype == TEXTKEY_UTF8)	// if we already know utf-8
			baseoffset = strlen(utf8BOM);
		else if (u8_isvalidUTF8(data, (int32_t)datalength))		// do big check
			imp->subtype = TEXTKEY_UTF8;
	}
	if (imp->subtype == KEY_WIN)
		v3_openconverter(V2_FOREIGN);
	else if (imp->type == I_MACREX)
		v3_openconverter("CP850");
	else
		v3_openconverter(NULL);		// converts from old standard for this platform
	str_setgetlimits(data+baseoffset, exroffset-baseoffset);	// set up reader
	for (ctot = 0; str_getline(fbuff, MAXREC,&length); ctot += length) {  /* while not eof and index not full */
		if (!checkline(FF, imp, fbuff,&trec))	{	// if record is decent
			if (imp->type == I_CINARCHIVE && imp->subtype == KEY_UNKNOWN)	/* if old Mac archive */
				type_tagfonts(fbuff,imp->farray);
		}
		imp->recordcount++;
	}
	if ((err = imp_resolveerrors(FF, imp)) > 0)	{		/* if no errors or resolved */
		imp->mode = PM_READ;
		if (imp->gh.flags&READ_HASGH && !tr_ghok(&imp->gh))	{	/* if have gh codes and don't want translated */
			err = FILEREADERR;
			goto abort;
		}
		if (imp->type == I_CINARCHIVE)	{
			if (imp->subtype == KEY_UNKNOWN)	{		/* if old Mac archive */
				for (index = OLDVOLATILEFONTS; index < FONTLIMIT; index++)	{
					if (imp->farray[index] && !*FF->head.fm[index].name)	{	// if used font with no name
						if (!sendwarning(MISSINGARCHIVEFONT,index) || !getreplacementfont(FF->head.fm[index].name))
							strcpy(FF->head.fm[index].name,FF->head.fm[0].name);	/* set default cause didn't choose */
						strcpy(FF->head.fm[index].pname,FF->head.fm[index].name);
					}
				}
				for (index = OLDVOLATILEFONTS; index < FONTLIMIT; index++)
					imp->farray[index-1] = imp->farray[index];	// push down translation entries for removed symbol font
			}
			else	// normal archive
				setfonts(FF, imp,data,exroffset);		// set up fonts
		}
		else if (imp->type == I_SKY)	// translate font ids as needed
			setskyfonts(FF,imp);	// set fonts
		if (index_setworkingsize(FF,imp->recordcount+MAPMARGIN))	{	// if can resize index
			str_setgetlimits(data+baseoffset, exroffset-baseoffset);	// set up reader
			for (ctot = 0, num = FF->head.rtot; str_getline(fbuff, MAXREC,&length); ctot += length) {  /* while not eof and index not full */
				if (!checkline(FF, imp, fbuff,&trec))	{	/* if no error forming record */
					if (recptr = rec_makenew(FF,fbuff,++num)) { 	/* if can make new record */
						if (recptr->ismark = trec.ismark)	/* always flag a bad translation */
							imp->markcount++;
						if (trec.num)	{		/* if have to pick up extended info */
							recptr->isdel = trec.isdel;
							recptr->label = trec.label;
							recptr->isgen = trec.isgen;
							recptr->time = trec.time;
							strncpy(recptr->user,trec.user,4);
						}
						sort_makenode(FF,++FF->head.rtot);		/* make nodes */
					}
					else
						break;
				}
			}
		}
	}
	abort: 
	return (err);
}
/***************************************************************************/
int imp_resolveerrors(INDEX * FF, IMPORTPARAMS *imp)

{
#if 0
	needsize = imp->longest > FF->head.indexpars.recsize ? imp->longest : FF->head.indexpars.recsize;
	if (imp->freespace < imp->recordcount*(needsize+RECSIZE))	{	/* if would have room */
		senderr(DISKFULLERR,WARN);
		return (0);
	}
#endif
	if (imp->ecount > imp->fielderrcnt + imp->lenerrcnt +imp->fonterrcnt+imp->emptyerrcnt)	{	// if errors that we can't correct or ignore			
		if (!sendwarning(IMPORTERRORSWARN))		/* if don't want to ignore */
			return (-1);		
	}
	if (imp->fonterrcnt)	{		/* if need font query */
		if (!sendwarning(MISSINGFONTWARNING, imp->fonterrcnt))
			return (-1);
	}
	if (imp->fielderrcnt && FF->head.rtot)	{		/* if need field query */
		if (imp->deepest > FIELDLIM || !sendwarning(RECFIELDNUMWARN, imp->deepest))
			return (-1);
	}
	if (imp->lenerrcnt && FF->head.rtot)	{		/* if need length query */
		if (imp->longest > MAXREC || !sendwarning(RECENLARGEWARN,imp->longest-FF->head.indexpars.recsize))
			return (-1);
	}
	if (imp->conflictingseparators && FF->head.rtot)	{		// if specifying separators for index that has records
		if (!sendwarning(CONFLICTINGESPARATORSWARN))
			return (-1);
	}
	if (imp->deepest > FF->head.indexpars.maxfields)	{	/* if need to increase # fields */
		short oldmaxfieldcount = FF->head.indexpars.maxfields;
		FF->head.indexpars.maxfields = imp->deepest;
		adjustsortfieldorder(FF->head.sortpars.fieldorder, oldmaxfieldcount, FF->head.indexpars.maxfields);
	}
	if (imp->longest > FF->head.indexpars.recsize)		{	/* if need to increase record size */
		if (![FF->owner resizeIndex:10 + 10*(imp->longest/10)])	/* if can't resize */ 
			return (0);
	}
	if (imp->xflags && !FF->head.rtot)	{	// if imported records used special last field
		if (FF->head.indexpars.minfields < 3)
			FF->head.indexpars.minfields = 3;
		FF->head.indexpars.required = TRUE;
	}
	if (imp->emptyerrcnt)		// if empty error
		sendinfo(EMPTYRECORDWARNING, imp->emptyerrcnt);	// just send info
	return (1);
}
/***************************************************************************/
BOOL imp_adderror(IMPORTPARAMS *imp, int type, int line)		// adds a new error to the list

{
	if (imp->ecount < IMP_MAXERRBUFF)	{
		imp->errlist[imp->ecount].type = type;
		imp->errlist[imp->ecount].line = line;
	}
	imp->ecount++;
	return TRUE;		// error flagged
}
/***************************************************************************/
static BOOL setfonts(INDEX * FF, IMPORTPARAMS *imp, char * data, unsigned long exroffset)

{
	char *readbase;
	int readcount;
	int fontcount;
	short fontindex;
	char pname[FONTNAMELEN], name[FONTNAMELEN];

	if (imp->mode == PM_SCAN)	{	// read font info only on scan pass
		for (readbase = data+exroffset, fontcount = 0; fontcount < FONTLIMIT; fontcount++, readbase += readcount)	 {/* for all fonts */
			int count = sscanf(readbase,"%hd@@%[ A-Za-z0-9]@@%[ A-Za-z0-9]%n",&fontindex,pname,name,&readcount);
			
			if (count != 3)	// if didn't get 3 items
				break;
			strcpy(imp->tfm[fontindex].pname, pname);
			strcpy(imp->tfm[fontindex].name, pname);
//			if (!strcmp(imp->tfm[fontindex].pname,"Symbol"))
			if (type_ispecialfont(imp->tfm[fontindex].pname))
				imp->tfm[fontindex].flags |= CHARSETSYMBOLS;
		}
		if (fontcount < 2)	{
			senderr(NOFONTERR,WARN);
			return FALSE;
		}
	}
	if (type_checkfonts(imp->tfm) || [ManageFontController manageFonts:imp->tfm])	{	/* if fonts ok or substituted */
		FONTMAP ttfm[FONTLIMIT];	// placeholder font map for scan pass
		FONTMAP * fmp;
	
		if (imp->mode == PM_SCAN)	{	// if scanning
			fmp = ttfm;			// use placeholder map
			memset(ttfm, 0, sizeof(ttfm));
		}
		else
			fmp = FF->head.fm;	// use real font map
		if (!FF->head.rtot)		{	/* if index has no records */
			strcpy(fmp[0].pname,imp->tfm[0].pname);	// take default font from archive
			strcpy(fmp[0].name,imp->tfm[0].name);
		}
		for (int index = OLDVOLATILEFONTS; index < FONTLIMIT; index++)	{	/* for all possible import fonts */
			if (*imp->tfm[index].pname)	{	// if font wanted
				int lfnum = type_makelocal(fmp,imp->tfm[index].pname,imp->tfm[index].name,VOLATILEFONTS);	// make local font
			
				imp->farray[index-1] = lfnum;	// build translation entry; take off 1 for removed symbol font
			}
		}
		return TRUE;
	}
	return (FALSE);
}
/***************************************************************************/
static unsigned long findfontbase(IMPORTPARAMS *imp,char * readbase, unsigned long datalength)

{
	unsigned long exroffset = atol(readbase+sizeof(long));	// offset to extended information
	char * fbase = NULL;
	
	if ((long)(datalength-sizeof(imp->tfm)) >= 0)	// if search would start after beginning of data
		fbase = strstr(readbase+datalength-sizeof(imp->tfm),"0@@");// scan from earliest possible font base	
	if (fbase)
		exroffset = fbase-readbase;
	return exroffset;
}
/***************************************************************************/
static BOOL setskyfonts(INDEX * FF, IMPORTPARAMS *imp)

{
	if (type_checkfonts(imp->tfm) || [ManageFontController manageFonts:imp->tfm])	{	/* if fonts ok or substituted */
		FONTMAP * fmp = FF->head.fm;	// use real font map
		
		for (int index = imp->skytype == SKYTYPE_7 ? OLDVOLATILEFONTS : VOLATILEFONTS; index < FONTLIMIT; index++)	{	/* for all possible import fonts */
			if (*imp->tfm[index].pname)	{	// if font wanted
				int lfnum = type_makelocal(fmp,imp->tfm[index].pname,imp->tfm[index].name,VOLATILEFONTS);	// make local font
				
				imp->farray[index] = lfnum;	// build translation entry
			}
		}
		return (TRUE);
	}
	return (FALSE);
}
/***************************************************************************/
static BOOL isgoodchar(int type, unsigned char * ch)

{
	if (iscntrl(*ch))	{	/* if control char */
		if (*ch == '\t' && (type == I_CINARCHIVE || type == I_PLAINTAB || type == I_DOSDATA || type == I_SKY))	/* if tab && OK type */
			return TRUE;
		if (type == I_CINARCHIVE && (*ch == CODECHR || *(ch-1) == CODECHR))	/* if code in archive */
			return TRUE;
		if ((*ch == '\024' || *ch == '\025') && type == I_DOSDATA)	/* if DOS CINDEX para or section */
			return TRUE;
		return FALSE;
	}
	else if (*ch == EOCS)
		return (FALSE);
	return (TRUE);
}
/***************************************************************************/
static BOOL checkline(INDEX * FF, IMPORTPARAMS *imp, char * fbuff, RECORD * recptr)	

{
	char *cptr, *sptr, *tptr;
	short fcount, reclen;
	BOOL error = FALSE;
	
	for (cptr = fbuff; *cptr && (*cptr != EXRCHR || *(cptr-1) == CODECHR); cptr++)	{	/* scan for too long && bad chars */
		if (!isgoodchar(imp->type, cptr))
			return imp_adderror(imp,BADCHAR,imp->recordcount+1);
	}
	if (!*cptr && cptr-fbuff > MAXREC-2)	// if record would be too long
		return imp_adderror(imp,TOOLONGFORINDEX,imp->recordcount+1);
	if (*cptr == EXRCHR)	{	/* if have extended info in tail */
		sptr = cptr;
		*sptr++ = '\0';		/* terminate real string */
		recptr->num = 1;	/* has extended record info */
		recptr->isdel = *sptr&W_DELFLAG ? TRUE : FALSE;
		recptr->label = *sptr&W_TAGFLAG ? TRUE : FALSE;
		recptr->isgen = *sptr&W_GENFLAG ? TRUE : FALSE;
		if (*sptr&W_NEWTAGS)	// compatible way of extracting new labels
			recptr->label += (*sptr&W_NEWTAGS) >> 2;
		if (*sptr&W_PUSHLAST)	// last field was written as special
			imp->xflags = TRUE;		// picked up in resolverrors
		sptr++;
		recptr->time = strtoul(sptr, &sptr,10);
		if (imp->type == I_CINARCHIVE && imp->subtype == KEY_MAC)	// if need time translation for mac archive  (5/6/2017)
			recptr->time = mw_to_unix_time(recptr->time);
		strncpy(recptr->user, ++sptr,4);
	}
	else
		recptr->num = 0;			/* no extended record info */
	recptr->ismark = FALSE;
	cptr = fbuff+strlen(fbuff);		// all cases start pointing to end of locator field
	if (imp->type == I_PLAINTAB)	{
		for (cptr = fbuff; cptr = strpbrk(cptr, "{}<>~\\"); cptr++)	{
			memmove(cptr+1,cptr,strlen(cptr)+1);	// make space
			*cptr++ = '\\';	// insert escape
		}
		cptr = fbuff+strlen(fbuff);	// sit on terminal zero
	}
	else if (imp->type == I_SKY && imp->skytype == SKYTYPE_7) {	// preprocess fonts in sky7 format (make like v2 cindex), so that v3_convertrecord will deal with symbol font
		for (cptr = fbuff; *cptr;)	{
			char * mark = cptr;
			if (*cptr == '/' && *++cptr == 'f' && isdigit(*++cptr))	{	// a font code [doesn't seem to be emitted by sky8 export]
				int fontid = *cptr-'0';
				*mark++ = CODECHR;
				*mark++ = fontid|FX_FONT;	// set V2 font id
				memmove(mark,cptr+1,strlen(cptr)+1);
				imp->farray[fontid] = fontid;	// build translation entry
			}
			else
				cptr++;
		}
	}
	else if (imp->type == I_MACREX) {	// preprocess to organize field structure
		short digitflag;
		for (digitflag = fcount = 0, sptr = cptr-1; sptr > fbuff; sptr--)	{		/* scan backwards */
			if (*sptr == '}')	{		/* if closing brace */
				while (*--sptr != '{' && sptr > fbuff)	/* while not at opening */
					;
				if (*sptr-- != '{')		/* if no opening brace before start */
					error = imp_adderror(imp,BADMACREX,imp->recordcount+1);
			}
			else if (!fcount && digitflag && !strchr(mpageset,*sptr))	{	/* if in candidate page field && not a ref char */
				for (tptr = sptr+1; *tptr && *tptr != ',' && *tptr != SPACE; tptr++)	{/* advance to first break point */
					if (*tptr == '{' && !(tptr = strchr(tptr,'}')))	/* skip over braced stuff */
						error = imp_adderror(imp,BADMACREX,imp->recordcount+1);
				}
				*tptr = '\t';	/* page field starts beyond this char */
				fcount++;
			}
			else if ((fcount || !digitflag) && *sptr == ',')	{	/* a conventional field break */
				*sptr-- = '\t';	/* identify a field break */
				fcount++;
			}
			else if (!fcount && isdigit(*sptr))	/* if a possible number for page field */
				digitflag = TRUE;
		}
	}
	if (imp->delimited) {	    /* quote delimited format */
		if (*fbuff == *imp->sepstr && *(cptr = fbuff+strlen(fbuff)-1) == *imp->sepstr)	{
			memmove(fbuff,fbuff+1,cptr-fbuff);	/* move over initial separator */
			*--cptr = '\0';		/*  set new termination */
			for (sptr = fbuff; sptr = strstr(sptr, imp->sepstr);)	{
				memmove(sptr+1,sptr+3,cptr-sptr);
				*sptr++ = '\0';
				cptr -= 2;		/* adjust end for removed chars */
			}
		}
		else
			error = imp_adderror(imp,BADDELIMIT,imp->recordcount+1);
	}
	else  {		/*  tab-delimited */
		for (sptr = fbuff; sptr = strchr(sptr, '\t'); sptr++)
			if (*(sptr-1) != CODECHR)		/* if not a code */
				*sptr = '\0';
	}
	// cbuff here should be sitting at terminating 0 on last field
	if (cptr == fbuff)	{	// if empty record
		imp->emptyerrcnt++;		/* add to tally of empty errors */
		error = imp_adderror(imp,EMPTYRECORD,imp->recordcount+1);
	}
	*++cptr = EOCS;						/* terminate record */
	if (imp->type == I_DOSDATA)	{		/* if need translation from DOS */
		recptr->ismark = tr_dosxstring(fbuff,&imp->gh,TR_DOFONTS|TR_DOSYMBOLS);
		tr_movesubcross(FF,fbuff);		/* shift cross-refs to page field if necess */
	}
	// convert record string !! must do this after char conversions and before checking fonts
	if (imp->subtype != TEXTKEY_UTF8)	// if not already utf-8
		v3_convertrecord(fbuff,imp->tfm,TRUE);
	// now post conversion parsing
	if (imp->type == I_SKY)	// sky text
		manageSky(imp,fbuff);
	else if (imp->type == I_MACREX)
		manageMacrex(imp,fbuff);
	fcount = rec_strip(FF, fbuff);		/* strip surplus fields */
	if (fcount < FF->head.indexpars.minfields)		/* if too few fields */
		rec_pad(FF,fbuff);	/* pad the record */
	if (fcount > imp->deepest)	{
		imp->deepest = fcount;
		if (fcount > FF->head.indexpars.maxfields)	{ 	/* if too many fields */
			imp->fielderrcnt++;				/* add to tally of field # errors */
			error = imp_adderror(imp,TOOMANYFIELDS,imp->recordcount+1);
		}
	}
	reclen = str_adjustcodes(fbuff,CC_TRIM|(g_prefs.gen.remspaces ? CC_ONESPACE : 0))+1;
	if (reclen > MAXREC-2)	// if exceeds max record size (this check after record fully built)
		error = imp_adderror(imp,TOOLONGFORINDEX,imp->recordcount+1);
	else if (reclen > imp->longest)	{
		imp->longest = reclen;
		if (reclen > FF->head.indexpars.recsize)		{	/* if record too long */
			imp->lenerrcnt++;				/* add to tally of length errors */
			error = imp_adderror(imp,TOOLONGFORRECORD,imp->recordcount+1);
		}
	}
	if (type_setfontids(fbuff,imp->farray)) {
		imp->fonterrcnt++;		// count font error
		error = imp_adderror(imp,MISSINGFONT,imp->recordcount+1);
	}
	return (error);
}
/***************************************************************************/
static BOOL getreplacementfont(char * fname)

{
	NSValue * val = [NSValue valueWithPointer:fname];
	NSWindowController * tcontrol = [[ReplaceFontController alloc] init];

	[tcontrol showWindow:val];
	return [NSApp runModalForWindow:[tcontrol window]] != 0;
}
/***************************************************************************/
static void manageSky(IMPORTPARAMS * imp, char * fbuff)

{
	static char codes[][6] = {
		{CODECHR,FX_BOLD,0},
		{CODECHR,FX_BOLD|FX_OFF,0},
		{CODECHR,FX_ITAL,0},
		{CODECHR,FX_ITAL|FX_OFF,0},
		{CODECHR,FX_ULINE,0},
		{CODECHR,FX_ULINE|FX_OFF,0},
		{CODECHR,FX_SUPER,0},
		{CODECHR,FX_SUPER|FX_OFF,0},
		{CODECHR,FX_SUB,0},
		{CODECHR,FX_SUB|FX_OFF,0},
		{CODECHR,FX_SMALL,0},
		{CODECHR,FX_SMALL|FX_OFF,0},
	};
	static ctrans styles[] = {
		{"/b1",codes[0]},
		{"/b0",codes[1]},
		{"/i1",codes[2]},
		{"/i0",codes[3]},
		{"/u1",codes[4]},
		{"/u0",codes[5]},
		{"/p1",codes[6]},
		{"/p0",codes[7]},
		{"/s1",codes[8]},
		{"/s0",codes[9]},
		{"/k1",codes[10]},			// strikeout as small caps
		{"/k0",codes[11]},
//		{"/z1","{"},		// sk8 hidden translated in loop
//		{"/z0","}"},
		{"/x1","/y3"},		//  translate sk8 note code to sky7 code, which is fixed in loop below
		{"/x0","/y0"},
//		{"\\/","/"},		// sky literal for slash (sk7)
		{NULL}
	};
	static URegularExpression *uregex;
	char tmode = '\0';
	
	if (!uregex)
		uregex = regex_build("^u[0-9]+]",0);	// encoded unicode character
	translatestrings(fbuff, styles);
	
	// need special handling for /y codes, because work differently in different versions
	for (char *cptr = fbuff; *cptr != EOCS;)	{	// do code/character translations
		if (*cptr == '/')	{	// a potential format code
			char * mark = cptr;
			if (*++cptr)	{	// if something follows
				if (*cptr == 'y' && (*++cptr == '0' || *cptr == '1' || *cptr == '2' || *cptr == '3')) {		// special text
					if (*cptr == '3')	{		// start note text
						*mark++ = '<';
						*mark++ = '{';
					}
					else if (*cptr == '1')	{	// start ignored text
						*mark++ = '<';
					}
					else if (*cptr == '2')	{	// start hidden text
						*mark++ = '{';
					}
					else if (*cptr == '0')	{
						if (tmode == 3)	{		// end note text
							*mark++ = '}';
							*mark++ = '>';
						}
						else
							*mark++ = tmode == 1 ? '>' : '}';
					}
					tmode = *cptr-'0';
					cptr++;
					memmove(mark,cptr,str_xlen(cptr)+1);
				}
				else if (*cptr == 'z' && (*++cptr == '0' || *cptr == '1'))	{	// hidden text sky 6 & 8
					*mark++ = *cptr == '1' ? '{' : '}';
					cptr++;
					memmove(mark,cptr,str_xlen(cptr)+1);
				}
				else if (*cptr == 'f' && *++cptr && *cptr == '"')	{	// sky8 font
					char * eptr = strchr(cptr+1,'"');
					int fontid;
					if (eptr && eptr-cptr > 1) {	// if not default
						char name[64];
						memset(name,0,64);
						strncpy(name,cptr+1,eptr-cptr-1);
						fontid = type_findlocal(imp->tfm, name, VOLATILEFONTS);
						if (type_available(name))	// if font is available
							imp->farray[fontid] = fontid;	// build translation entry
					}
					else
						fontid = 0;
					*mark++ = FONTCHR;
					*mark++ = fontid|FX_FONT;
					memmove(mark,eptr+1,str_xlen(cptr)+1);	// strip font info
				}
				else {	//		/ is literal
					if (*cptr == '/')
						mark++;
					mark++;
				}
			}
			cptr = mark;
		}
		else if (*cptr == '[') {	// potential [u888] code (sk8 export only)
			short ilength;
			char * fptr = regex_find(uregex,cptr+1,0,&ilength);
			if (fptr) {
				short uc = atoi(cptr+2);
				char utf8string[6];
				short olength;
				memset(utf8string,0,6);
				u8_appendU(utf8string,uc);
				olength = strlen(utf8string);
				memmove(cptr+olength,cptr+ilength+1,str_xlen(cptr)+1);
				strncpy(cptr,utf8string,olength);
				cptr += olength;
			}
			else
				cptr++;
		}
		else {
			if (*cptr && strchr("{}<>~\\", *cptr))	{	/* if must protect one of our special chars */
#if 0
				if (*cptr == '\\' && *(cptr+1) == '\\' && strchr(scodes,*(cptr+2)) && isdigit(*(cptr+3)))	{	// if special sky7 literal (\\) for leading slash
					*cptr++ = '/';	// replace surrogate \\ with /
					memmove(cptr,cptr+1,str_xlen(cptr)+1);
				}
				else				{
					memmove(cptr+1,cptr,str_xlen(cptr)+1);	// make space
					*cptr++ = '\\';	// insert protection char
				}
#else
				if (*cptr != '\\' || *(cptr+1) != '\\')	{ 		// if not special sky7 protected literal (\\)
					memmove(cptr+1,cptr,str_xlen(cptr)+1);		// make space
					*cptr++ = '\\';	// insert protection char
				}
#endif
			}
			cptr++;
		}
	}
}
/***************************************************************************/
static void manageMacrex(IMPORTPARAMS * imp, char * fbuff)

{
	static char codes[][6] = {
		{CODECHR,FX_SMALL,0},
		{CODECHR,FX_SMALL|FX_OFF,0},
		{CODECHR,FX_SUPER,0},
		{CODECHR,FX_SUPER|FX_OFF,0},
		{CODECHR,FX_SUB,0},
		{CODECHR,FX_SUB|FX_OFF,0},
	};
	static ctrans styles[] = {
		{"{[A]}",codes[0]},
		{"{[a]}",codes[1]},
		{"{[S]}",codes[2]},
		{"{[s]}",codes[3]},
		{"{[U]}",codes[4]},
		{"{[u]}",codes[5]},
		{"{[\\\\]}","\\\\"},	// for some reason I don't understand, these two won't work if in main translation table
		{"{[!!]}","\\~"},
		{NULL}
	};
	static char * translationdata;
	static ctrans * translations;
	char *cptr;
	short tcount, ccount, ecount, inbrace, inspecial;
	
	if (!translations)	// if haven't load translations
		translations = loadtranslationset("macrex_translations.txt", &translationdata);
	for (cptr = fbuff, inbrace = tcount = ecount = ccount = inspecial = 0; *cptr != EOCS; cptr++)  {    /* convert characters */
		switch (*cptr) {
			case '~':
				if (*(cptr+1) == '!' && *(cptr+2) == '~' && !tcount)	/* if ~!~ 'blocker' */
					memmove(cptr,cptr+3,str_xlen(cptr+2)+1);	/* strip it */
				else {
					*cptr = tcount ? CBRACE : OBRACE;	/* to correct brace */
					tcount = ~tcount;
				}
				break;
			case '{':
				if (*(cptr+1) == ',' && *(cptr+2) == '}')	{	/* if just protected comma */
					memmove(cptr+1,cptr+3,str_xlen(cptr+2)+1);	/* move text over comma */
					*cptr = ',';			/* replace first brace with comma */
				}
				else if (*(cptr+1) != '[') {	// if not starting special code for reserved characters
					*cptr = OBRACKET;		/* to opening bracket */
					inbrace = TRUE;
				}
				else
					inspecial = TRUE;		// in code for reserved chars
				break;
			case '}':
				if (inbrace)	{
					*cptr = CBRACKET;
					inbrace = FALSE;
				}
				else
					inspecial = FALSE;
				break;
			case '\\':			// translate bold
				if (!inspecial)  {
					memmove(cptr+2,cptr+1,str_xlen(cptr)+1);   /* shift right */
					*cptr++ = CODECHR;		/* write escape char */
					*cptr = ecount ? FX_BOLD|FX_OFF : FX_BOLD;
					ecount = ~ecount;
				}
				break;
			case '^':		// translate italics
				if (!inspecial)  {
					memmove(cptr+2,cptr+1,str_xlen(cptr)+1);   /* shift right */
					*cptr++ = CODECHR;
					*cptr = ccount ? FX_ITAL|FX_OFF : FX_ITAL;
					ccount = ~ccount;
				}
				break;
		}
	}
	translatestrings(fbuff, styles);
	translatestrings(fbuff,translations);
}
/******************************************************************************/
static void translatestrings(char * base, ctrans * trans) {
	for (ctrans * tptr = trans; tptr->in; tptr++)	{	// for each possible translation
//		NSLog(@"In: %s; Out: %s",tptr->in, tptr->out);
		for (char * cptr = base; *cptr != EOCS; cptr += strlen(cptr)+1) {	// search strings in turn
			char * xptr = cptr;
			while (xptr = strstr(xptr,tptr->in))	{	// while we have matches in current string
				int inlen = (int)strlen(tptr->in);
				int outlen = (int)strlen(tptr->out);
				memmove(xptr+outlen,xptr+inlen,str_xlen(xptr));   // shift
				strncpy(xptr,tptr->out,outlen);
				xptr += outlen;
			}
		}
	}
}

 /******************************************************************************/
static ctrans * loadtranslationset(char * name, char ** savedstring)
	// source is string\ttranslation\r[\n]
 {
	 NSString * path = [[[NSBundle mainBundle] resourcePath] stringByAppendingPathComponent:[NSString stringWithFormat:@"%s",name]];
	 NSData * md = [NSData dataWithContentsOfFile:path];
	 if (md)	{
		 char * string = (char *)[md bytes];
		 int length = (int)md.length;
		 char * dest = malloc(length);		// whole multi-element string
		 ctrans * trans = malloc(length/2*sizeof(char*));	// set of trans ptrs
		 char * cptr, *dptr;
		 ctrans * tptr = trans;
		 tptr->in = dest;	// initialize first one
		 for (cptr = string, dptr = dest; cptr < string+length; cptr++) {
			 if (*cptr == '\t') {
				 *dptr++ = '\0';
				 tptr->out = dptr;	// anticipates next char
			 }
			 else if (*cptr == '\r') {
				 *dptr++ = '\0';
				 tptr++;
				 tptr->in = dptr;	// anticipates next char
			 }
			 else if (*cptr != '\n')
				 *dptr++ = *cptr;
		 }
		 tptr->in = NULL;	// mark end
		 *savedstring = dest;
		 return trans;
	 }
	 return NULL;
 }

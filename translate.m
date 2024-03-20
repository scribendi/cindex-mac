//
//  translate.m
//  Cindex
//
//  Created by PL on 1/17/05.
//  Copyright 2005 Indexing Research. All rights reserved.
//

#import "translate.h"
#import "commandutils.h" 
#import "strings_c.h"
#import "type.h"

char mac_to_dos[] = {
142,143,128,144,165,153,154,160,133,131,132,206,134,135,130,138,
136,137,161,141,140,139,164,162,149,147,148,206,163,151,150,129,
206,248,155,156,206,249,206,206,206,206,206,206,206,206,146,206,
236,241,243,242,157,230,206,228,206,227,244,166,167,234,145,206,
168,173,170,251,159,247,206,174,175,206,206,206,206,206,206,206,
196,206,206,206,206,206,246,206,152,206,206,206,206,206,206,206,
206,250,206,206,206,206,206,206,206,206,206,206,206,206,206,206,
206,206,206,206,206,206,206,206,206,206,206,206,206,206,206,206
};

char doslow_to_mac[] =	/* DOS low characters that can be mapped */
"\0ðð©¨§ª·ðððððððð"\
"ðððð¦¤ðððððððððð";

char dos_to_mac[] = 
"‚ŸŽ‰ŠˆŒ‘•”“€"\
"ƒ¾®™š˜žØ…†¢£´ëÄ"\
"‡’—œ–„»¼ÀðÂððÁÇÈ"\
"ðððððððððððððððð"\
"ððððÐððððððððððð"\
"ðððððððððððððððð"\
"abg¹·sµtFQ½d°¯ÎÇ"\
"º±²³ººÖÅ¡¥áÃðððð";


char win_to_mac[] =
"ððâÄãÉ àöäSÜÎððð"\
"ðÔÕÒÓ¥ÐÑ÷ªsÝÏððÙ"\
"ÊÁ¢£Û´ð¤¬©»ÇÂ-¨ø"\
"¡±ðð«µ¦áüð¼ÈðððÀ"\
"ËçåÌ€®‚éƒæèíêëì"\
"ð„ñîïÍ…ð¯ôòó†ðð§"\
"ˆ‡‰‹ŠŒ¾Ž‘“’”•"\
"ð–˜—™›šÖ¿œžŸððØ";

char dos_greek[] = "abdFGmpQSstW";	/* characters that in symbol font match DOS greek */
char dos_fromsymbol[] = {224,225,235,232,226,230,227,233,228, 229, 231, 234};	/* DOS extend chars that match chars from the symbol font */
/* dos_greek and dos_fromsymbol arrays have to be aligned */

char tr_escname[] = "bBiIlLaAuUdDgGhH";	/* key chars for DOS escape sequences */
unsigned char tr_attrib[] = {FX_BOLD,FX_ITAL,FX_ULINE,FX_SMALL,FX_SUPER,FX_SUB,FX_FONT,FX_FONT};		/* text attribute flags */

//static short moverecords(short fid,HEAD * hp,long base, long shift);	/* moves record positions in file */
//static void copyhf(HEADERFOOTER * nhf, struct V10_headfoot * ohf, V10_FONTMAP * fm);	/*copies header/footer */
static char * dosextendedtomac(char * sptr, int flags);     /* translates dos extended char */
static char * doslowtomac(char * sptr);     /* translates dos low char */
static unsigned char str_transnum(char **iptr);	   /* translates (up to three) decimal digits to char */

#if 0
/*******************************************************************************/
short tr_V10toV11(FSSpec *fsptr)	/* converts old index to current format */

{
	short fid;
	HEAD *hp;
	V10_HEAD *ohp;
	int count;
	long size;
	short err;
			
	hp = calloc(1,sizeof(HEAD));
	if (!hp)
		return (0);
	ohp = calloc(1,sizeof(V10_HEAD));
	if (!ohp)	{
		free(hp);
		return (0);
	}
	if (!(err = FSpOpenDF(fsptr,fsCurPerm,&fid)))	{
		size = HEADSIZE;
		FSRead(fid,&size,hp);
		if ((hp->headsize > SHRT_MAX || hp->version < 110))	{		/* old structure */
			if (sendwarning(CONVERTWARNING))	{
				memcpy(ohp,hp,sizeof(V10_HEAD));		/* transfer headers */
				hp->headsize = HEADSIZE;		/* size of header */
				hp->version = CINVERSION; 		/* set defaults for header */
				hp->rtot = ohp->rtot;
				hp->elapsed = ohp->elapsed;
				hp->createtime = ohp->createtime;
				hp->resized = ohp->resized;
				hp->squeezetime = ohp->squeezetime;			
				memcpy(&hp->indexpars,&ohp->indexpars,sizeof(struct V10_indexgroup));	/* v11 & v10 are the same */
				memcpy(&hp->sortpars,&ohp->sortpars, sizeof(struct V10_sortgroup));	/* v11 & v10 are the same */
				
				hp->refpars = g_prefs.refpars;
				strcpy(hp->refpars.crosstart,ohp->refpars.crosstart);
				strcpy(hp->refpars.crossexclude,ohp->refpars.crossexclude);
				hp->refpars.csep = ohp->refpars.csep;
				hp->refpars.psep = ohp->refpars.psep;
				hp->refpars.rsep = ohp->refpars.rsep;
				
				memcpy(&hp->privpars,&ohp->privpars,sizeof (struct V10_privgroup));	/* v11 & v10 are the same */
				
				hp->formpars = g_prefs.formpars;
				memcpy(&hp->formpars.pf.mc,&ohp->formpars.pf.mc, sizeof(struct V10_margcol));	/* v11 & v10 are the same */
				copyhf(&hp->formpars.pf.lefthead,&ohp->formpars.pf.lefthead,ohp->fm);
				copyhf(&hp->formpars.pf.leftfoot,&ohp->formpars.pf.leftfoot,ohp->fm);
				copyhf(&hp->formpars.pf.righthead,&ohp->formpars.pf.righthead,ohp->fm);
				copyhf(&hp->formpars.pf.rightfoot,&ohp->formpars.pf.rightfoot,ohp->fm);
				hp->formpars.pf.linespace = ohp->formpars.pf.linespace;
				hp->formpars.pf.firstpage = ohp->formpars.pf.firstpage;
				hp->formpars.pf.lineheight = ohp->formpars.pf.lineheight;
				hp->formpars.pf.entryspace = ohp->formpars.pf.entryspace;
				hp->formpars.pf.above = ohp->formpars.pf.above;
				hp->formpars.pf.lineunit = ohp->formpars.pf.lineunit;
				hp->formpars.pf.autospace = ohp->formpars.pf.autospace;
				hp->formpars.pf.dateformat = ohp->formpars.pf.dateformat;
				hp->formpars.pf.timeflag = ohp->formpars.pf.timeflag;
	
				hp->formpars.ef.runlevel = ohp->formpars.ef.runlevel;
				hp->formpars.ef.style = ohp->formpars.ef.style;
				hp->formpars.ef.itype = ohp->formpars.ef.itype;
				hp->formpars.ef.adjustpunct = ohp->formpars.ef.adjustpunct;
				hp->formpars.ef.adjstyles = ohp->formpars.ef.adjstyles;
				hp->formpars.ef.fixedunit = ohp->formpars.ef.fixedems ? 0 : 1;
				hp->formpars.ef.autounit = ohp->formpars.ef.autoems ? 0 : 1;
				hp->formpars.ef.autolead = ohp->formpars.ef.autolead;
				hp->formpars.ef.autorun = ohp->formpars.ef.autorun;
				
				hp->formpars.ef.eg.method = ohp->formpars.ef.eg.method;
				if (ohp->formpars.ef.eg.gfont)	/* if had group font */
					p2cstrcpy(hp->formpars.ef.eg.gfont,ohp->fm[ohp->formpars.ef.eg.gfont].name);
				memcpy(&hp->formpars.ef.eg.gstyle,&ohp->formpars.ef.eg.gstyle, sizeof(V10_CSTYLE));	/* v11 & v10 are the same */
				hp->formpars.ef.eg.gsize = ohp->formpars.ef.eg.gsize;
				strcpy(hp->formpars.ef.eg.title,ohp->formpars.ef.eg.title);
	
				hp->formpars.ef.cf.level[0] = ohp->formpars.ef.cf.level[0];
				hp->formpars.ef.cf.level[1] = ohp->formpars.ef.cf.level[1];
				memcpy(&hp->formpars.ef.cf.leadstyle,&ohp->formpars.ef.cf.leadstyle,sizeof(V10_CSTYLE));	/* v11 & v10 are the same */
				memcpy(&hp->formpars.ef.cf.bodystyle,&ohp->formpars.ef.cf.bodystyle,sizeof(V10_CSTYLE));	/* v11 & v10 are the same */
				hp->formpars.ef.cf.mainposition = ohp->formpars.ef.cf.position;
				hp->formpars.ef.cf.sortcross = ohp->formpars.ef.cf.sortcross;
	
				hp->formpars.ef.lf.sortrefs = ohp->formpars.ef.lf.sortrefs;
				hp->formpars.ef.lf.rjust = ohp->formpars.ef.lf.rjust;
				hp->formpars.ef.lf.suppressparts = ohp->formpars.ef.lf.supflag;
				strcpy(hp->formpars.ef.lf.llead1,ohp->formpars.ef.lf.llead1);
				strcpy(hp->formpars.ef.lf.lleadm,ohp->formpars.ef.lf.lleadm);
				strcpy(hp->formpars.ef.lf.trail,ohp->formpars.ef.lf.trail);
				strcpy(hp->formpars.ef.lf.connect,ohp->formpars.ef.lf.connect);
				hp->formpars.ef.lf.conflate = ohp->formpars.ef.lf.conflate;
				hp->formpars.ef.lf.abbrevrule = ohp->formpars.ef.lf.abbrevrule;
				strcpy(hp->formpars.ef.lf.suppress,ohp->formpars.ef.lf.suppress);
				strcpy(hp->formpars.ef.lf.concatenate,ohp->formpars.ef.lf.concatenate);
				for (count = 0; count < COMPMAX; count++)
					memcpy(&hp->formpars.ef.lf.lstyle[count],&ohp->formpars.ef.lf.lstyle[count],sizeof(V10_LSTYLE));	/* v11 & v10 are the same */
				
				for (count = 0; count < ohp->indexpars.maxfields-1; count++)	{	/* for fields */
					if (ohp->formpars.ef.field[count].font)	/* if had heading font */
						p2cstrcpy(hp->formpars.ef.field[count].font,ohp->fm[ohp->formpars.ef.field[count].font].name);
					hp->formpars.ef.field[count].size = ohp->formpars.ef.field[count].size;
					memcpy(&hp->formpars.ef.field[count].style,&ohp->formpars.ef.field[count].style,sizeof(V10_CSTYLE));	/* v11 & v10 are the same */
					hp->formpars.ef.field[count].leadindent = ohp->formpars.ef.field[count].leadindent;
					hp->formpars.ef.field[count].runindent = ohp->formpars.ef.field[count].runindent;
					strcpy(hp->formpars.ef.field[count].trailtext,ohp->formpars.ef.field[count].trailtext);
				}
	
				str_xcpy(hp->stylestrings,ohp->stylestrings);
				for (count = 0; count < FONTLIMIT; count++)	{	/* for fonts */
					p2cstrcpy(hp->fm[count].pname,ohp->fm[count].name);
					p2cstrcpy(hp->fm[count].name,ohp->fm[count].name);
				}
				hp->root = ohp->root;
				hp->dirty = ohp->dirty;
				
				if (err = moverecords(fid,hp,sizeof(V10_HEAD),HEADSIZE-sizeof(V10_HEAD)))	/* if an error */
					senderr(CONVERSIONERR,WARN,fsptr->name);
			}
			else
				err = TRUE;	/* force failure if don't want to convert */
		}
		FSClose(fid);
	}
	free(hp);
	free(ohp);
	return (err);
}
#endif
/*******************************************************************************/
short tr_ghok(struct ghstruct * ghp)	/* gets DOS font translation specs */

{
#define GHSUBID 167

	enum	{
		GH_OUTLINE = 3,
		GH_TRANSG = 5,
		GH_TRANSH = 7
	};
	
	if (sendwarning(CODETRANSLATION))	{	/* if want translation */
#if 0
		Handle ihandle;
		Rect irect;
		short itype, itemhit;
		DialogPtr dptr;
		char fname[32];
			
		if (dptr = dlog_installmove(GHSUBID,GH_OUTLINE))	{	/* get dialog */
			menu_buildmapped(dptr,GH_TRANSG,g_nullstr);
			menu_buildmapped(dptr,GH_TRANSH,g_nullstr);
			ShowWindow(dptr);		/* make visible */	
			for (;;) 	{			/* until itemhit = go or cancel */
				dlog_moveable(NULL,&itemhit,0,0);			/* track activity in dialog */
				GetDialogItem(dptr,itemhit,&itype,&ihandle,&irect);	/* get data on item */
				
				switch (itemhit)	{		/* deal with items */		
					case ok:
						menu_getlocalfrom(dptr, GH_TRANSG,fname);
						ghp->fcode[0] = type_findlocal(ghp->fmp,fname,1);
						menu_getlocalfrom(dptr, GH_TRANSH,fname);
						ghp->fcode[1] = type_findlocal(ghp->fmp,fname,1);
						ghp->flags |= READ_TRANSGH;
					case cancel:
						DisposeDialog(dptr);
						return (itemhit == ok);
				}
			}
		}
#endif
	}
	return (FALSE);
}
/******************************************************************************/
int tr_dosxstring(char * buff,struct ghstruct *ghp, int flags)	/* in-place translation of DOS CINDEX control codes in string */

	/* assumes dest string has room for any expansion */
{
	char * sptr, *tptr;
	short index;
	int xcode;
		
	for (xcode = FALSE, sptr = buff; *sptr != EOCS; sptr++)	{
		if (*sptr < 0)	{	/* extended character */
			sptr = dosextendedtomac(sptr,flags);
			if ((unsigned char)*sptr == UNKNOWNCHAR)
				xcode = TRUE;
		}
		else if (*sptr < SPACE)
			sptr = doslowtomac(sptr);
		else if (*sptr == KEEPCHR && *(sptr+1))
			sptr++;			/* ensure don't treat following \ specially */
		else if (*sptr == ESCCHR && *(sptr+1))	{
		 	if (strchr(tr_escname,*(sptr+1)))	{
#if 1
				*sptr++ = CODECHR;
				index = strchr(tr_escname,*sptr)-tr_escname;
				*sptr = tr_attrib[index >>1]|(index&1 ? FX_OLDOFF : 0);
#else
				index = strchr(tr_escname,*(sptr+1))-tr_escname;
				*sptr++ = index&1 ? CODEOCHR : CODECHR;
				*sptr = tr_attrib[index >>1];
#endif
				if (*sptr&FX_FONT)	{	/* if a g or h code */
					if (!(index&1) && flags&TR_DOFONTS)	{	/* if 'on' code and might want translated */
						ghp->flags |= READ_HASGH;			/* flag presence of codes (first pass) */
						if (ghp->flags & READ_TRANSGH)		/* if want translated */
							*sptr += ghp->fcode[(index>>1)-6];	/* add right font id */
					}
					else	/* off GH code or no translation */
						*sptr &= ~FX_OLDOFF;	/* clear any 'off' style code -> default font */
					if (ghp->flags&READ_TRANSGH && !ghp->fcode[((index&~1)>>1)-6])	{	/* if have specified translation to default font */
						sptr--;				/* move to CODECHR */
						str_xshift(sptr+2,-2);	/* remove code altogether */
					}
				}
			}
			else if (*(sptr+1) == SPACE)	{	/* non-breaking space */
				str_xshift(sptr+1,-1);	/* move over code */
				*sptr = FSPACE;			/* replace character */
			}
			else if (*(sptr+1) == '-')	{	/* non-breaking hyphen */
				str_xshift(sptr+1,-1);	/* move over code */
				*sptr = 0xd0;			/* replace character with en-dash */
			}
			else if (isdigit(*(sptr+1)))	{	/* encoded character */
				tptr = sptr+1;
				*sptr = str_transnum(&tptr);
				str_xshift(tptr,sptr-tptr+1);	/* move over the code */
				if (*sptr < 0)	{	/* if extended char */
					sptr = dosextendedtomac(sptr,flags);	/*  translate */
					if ((unsigned char)*sptr == UNKNOWNCHAR)
						xcode = TRUE;
				}
				else if (*sptr < SPACE)
					sptr = doslowtomac(sptr);	/*  translate */
				else if (*sptr == EOCS)	/* if unacceptable char */
					str_xshift(sptr+1,-1);	/* get rid of it */
			}
			else			/* need to protect another char */
				sptr += 2;	/* preserve slash and following char */
		}
	}
	return (xcode);
}
#if 0
/******************************************************************************/
BOOL tr_winxstring(char * buff)	/* translates Windows characters in extended string */

{
	char * sptr;
	BOOL xcode;
	int activefont;

	/* NB could ultimately improve this by converting some Win Symbol font to extended char,
		as per dosextendedtomac() */
		
	for (activefont = 0, xcode = FALSE, sptr = buff; *sptr != EOCS; sptr++)	{
		if (*sptr == CODECHR)	{
			char codetype = *++sptr;

			if ((codetype&FX_FONT) && !(codetype&FX_COLOR))	// if a font change
				activefont = codetype&FX_FONTMASK;	// get active font
		}
		else if (*sptr < 0 && activefont != 1)	{	/* if extended character && not in symbol font */
			*sptr = win_to_mac[(unsigned char)(*sptr)-128];
			if ((unsigned char)*sptr == UNKNOWNCHAR)	
				xcode = TRUE;
		}
	}
	return (xcode);
}
#else
/******************************************************************************/
BOOL tr_winxstring(FONTMAP * fm, char * buff)	/* translates Windows characters in extended string */

{
	char * sptr;
	BOOL xcode;
	int protected;

	/* NB could ultimately improve this by converting some Win Symbol font to extended char,
		as per dosextendedtomac() */
		
	for (protected = 0, xcode = FALSE, sptr = buff; *sptr != EOCS; sptr++)	{
		if (*sptr == CODECHR)	{
			char codetype = *++sptr;

			if ((codetype&FX_FONT) && !(codetype&FX_COLOR))	{	// if a font change
//				activefont = codetype&FX_FONTMASK;	// get active font
				protected = fm[codetype&FX_FONTMASK].flags&CHARSETSYMBOLS;	// won't translate chars in special fonts
			}
		}
		else if (*sptr < 0 && !protected)	{	// if extended character && not protected
			*sptr = win_to_mac[(unsigned char)(*sptr)-128];
			if ((unsigned char)*sptr == UNKNOWNCHAR)	// !! what is this?
				xcode = TRUE;
		}
	}
	return (xcode);
}
#endif
/******************************************************************************/
void tr_movesubcross(INDEX * FF, char * buff)	/* moves any subhead cross-ref to page field */

{
	CSTR sarray[FIELDLIM];
	int scount;

	scount = str_xparse(buff, sarray);
	if (scount > 2 && !sarray[scount-1].ln)	{	/* if at least one subhead && empty page field */
		if (str_crosscheck(FF,sarray[scount-2].str))	/* if last subhead is cross-ref */
			*sarray[scount-1].str = EOCS;	/* clip off page field */
	}
}
#if 0
/*******************************************************************************/
static short moverecords(short fid,HEAD * hp,long base, long shift)	/* moves record positions in file */
	/* writes new header */
{
	RECN rnum, rcount;
	char buff[MAXREC+1];
	long size, newfilesize, trecsize;
	short err;

	err = 0;
	if (shift != 0)	{	/* if need to move records */
		trecsize = hp->indexpars.recsize+RECSIZE;
		newfilesize = HEADSIZE+hp->rtot*trecsize;
		if (shift > 0 && SetEOF(fid,newfilesize))	/* if can't increase size */
			return (FALSE);
		hp->resized = TRUE;
		rnum = shift > 0 ? hp->rtot-1 : 0;
		for (rcount = 0; rcount < hp->rtot && !err; rcount++)		{	/* for all records */
//			showprogress("Converting Indexâ€šÃ„Â¶",hp->rtot,rcount);
			if (!(err = SetFPos(fid, fsFromStart, base+rnum*trecsize)))	{	/* point to old position */
				size = trecsize;
				if (!(err = FSRead(fid,&size,buff)))	{
					if (!(err = SetFPos(fid, fsFromStart,HEADSIZE+rnum*trecsize)))	{	/* point to new posn */
						size = trecsize;
						/* following line to clean up codes from 1.04 and below */
						str_adjustcodes(((RECORD *)buff)->rtext,CC_TRIM|(g_prefs.gen.remspaces ? CC_ONESPACE : 0));	/* adjust any codes */
						if (!(err = FSWrite(fid,&size,buff)))	{	/* write it */
							if (shift > 0)
								rnum--;
							else
								rnum++;							
							continue;
						}
					}
				}
			}
		}
//		showprogress(g_nullstr,0,0);
	}
	if (!err)	{
		SetFPos(fid,fsFromStart, 0);	/* set to start */
		size = HEADSIZE;
		FSWrite(fid,&size,hp);	/* write header */
	}
	return (err);
}
/*******************************************************************************/
static void copyhf(HEADERFOOTER * nhf, struct V10_headfoot * ohf, V10_FONTMAP * fm)	/*copies header/footer */

{
	strcpy(nhf->left,ohf->left);
	strcpy(nhf->center,ohf->center);
	strcpy(nhf->right,ohf->right);
	memcpy(&nhf->hfstyle,&ohf->hfstyle,sizeof(V10_CSTYLE));	/* v11 & v10 are the same */
	if (ohf->hffont)	/* if had hf font */
		p2cstrcpy(nhf->hffont,fm[ohf->hffont].name);
}
#endif
/******************************************************************************/
static char * dosextendedtomac(char * sptr, int flags)     /* translates dos extended char */

{
	*sptr = dos_to_mac[(unsigned char)(*sptr)-128];
	if (strchr(dos_greek,*sptr) && flags&TR_DOSYMBOLS)	{	/* if needs to go to symbol font */
		char gchar = *sptr;
		str_xshift(sptr,4);		/* make room for font codes */
		*sptr++ = CODECHR;
		*sptr++ = FX_FONT|1;	/* symbol font */
		*sptr++ = gchar;		/* symbol */
		*sptr++ = CODECHR;
		*sptr = FX_FONT;		/* default font */
	}
	return (sptr);
}
/******************************************************************************/
static char * doslowtomac(char * sptr)     /* translates dos low char */

{
	char cc;

	if (*sptr)	{
		cc = doslow_to_mac[*sptr];
		if (*sptr <= 7)	{		/* if want symbol translation */
			str_xshift(sptr,4);		/* make room for font codes */
			*sptr++ = CODECHR;
			*sptr++ = FX_FONT|1;	/* symbol font */
			*sptr++ = cc;		/* symbol */
			*sptr++ = CODECHR;
			*sptr = FX_FONT;		/* default font */
		}
		else		/* take in text font */
			*sptr = cc;
	}
	return (sptr);
}
/******************************************************************************/
static unsigned char str_transnum(char **iptr)	   /* translates (up to three) decimal digits to char */
			/* returns with altered pointer to input string */

{
	register char c, *index;
	unsigned short count;

	for (index = *iptr, count = 3, c = 0; isdigit(*index) && count--;)	       /* while a digit */
		c = c*10 + *index++ -'0';	/* convert */
	*iptr = index;                /* advance input pointer */
	return (c);
}

//
//  drafttext.m
//  Cindex
//
//  Created by PL on 2/5/05.
//  Copyright 2005 Indexing Research. All rights reserved.
//

#import "drafttext.h"
#import "sort.h"
#import "strings_c.h"
#import "search.h"

static char * makelead(INDEX * FF, char * lptr, RECORD * recptr);		/* makes lead */
/**********************************************************************/
RECORD * draft_skip(INDEX * FF, RECORD * recptr, short dir)	/* skips in draft display mode */

{
	char tbuff[MAXREC+100];
	
	if (recptr = sort_skip(FF,recptr,dir))	{	/* if have a record */
		if (FF->head.privpars.hidebelow != ALLFIELDS || FF->owner.sumsource)	{	/* if some restriction on display */
			short ulevel;
			while (recptr && !*draft_buildentry(FF,tbuff, recptr, &ulevel))	/* while entry would be invisible */
				recptr = sort_skip(FF,recptr,dir);	/* skip again */
		}
	}
	return (recptr);
}
/**********************************************************************/
char * draft_buildentry(INDEX * FF, char * buffer, RECORD * recptr, short * ulevel)		/* forms entry for record */

{
	CSTR scur[FIELDLIM];
	short count, fcount, curcount, baseshift;
	char *string, pagecodechar;
	int leadlength;
	short sprlevel, hidelevel,clevel;
	
	string = makelead(FF,buffer,recptr);
	leadlength = string-buffer;
	str_xcpy(string, recptr->rtext);
	if (FF->owner.sumsource)	{		/* if are working with summary */
		INDEX * XF = [FF->owner.sumsource iIndex];
		char * sptr = string+strlen(string)+1;		/* start pos is beginning of second field */
		char * eptr = string+MAXREC-6;			/* limit */
		RECORD * crossptr;
		char lookup[20];
		
		sprintf(lookup, "%u$", recptr->num);		/* form target name */
		str_extend(lookup);
		if (crossptr = search_findbylead(XF,lookup))	{	/* if there's an entry */
			int ccount = 0;
			int length;
			RECN sourcenum;
			CSTR flist[FIELDLIM];
			RECORD * sourceptr;
			char *lptr;
			do {
				str_xparse(crossptr->rtext,flist);
				sourcenum = atol(flist[1].str);		/* number of source record */
				length = (short)strtoul(flist[2].str, &lptr,10);	/* length of source body (eptr has level) */
				if (*lptr == 'B')		/* if target was matched at subhead */
					sptr += strlen(sptr)+1;		/* show another target field */
				if (sourceptr = rec_getrec(FF, sourcenum))	{	/* if have source */
					if (ccount++)		/* if not the first ref */
						*sptr++ = SPACE;
					*sptr++ = '[';
					for (count = 0; count < length && sptr < eptr; count++, sptr++)	{
						if (!(*sptr = sourceptr->rtext[count]))	{
							*sptr++ = ';';
							*sptr = SPACE;
						}
					}
				    *sptr++ = ']';
				}
			} while ((crossptr = sort_skip(XF,crossptr,1)) && !strcmp(crossptr->rtext, lookup) && sptr < eptr);
			*sptr++ = '\0';	/* terminate */
			*sptr = EOCS;	/* terminate after  */
		}
		else if (!str_xfindcross(FF,recptr->rtext,FALSE))	{	/* if doesn't have cross-ref */
			*sptr++ = '\0';		/* set empty page field */
			*sptr = EOCS;	/* terminate after  */
		}
	}
	curcount = str_xparse(string,scur);	/* parse it */
	pagecodechar = FO_ELIPSIS;
	baseshift = 0;
	if (!FF->head.privpars.vmode)	/* if unformatted */
		*ulevel = 0;				/* don't suppress repeated headings */
	else	{
		rec_uniquelevel(FF, recptr, ulevel,&sprlevel,&hidelevel,&clevel);	/* find level at which heading unique */
		if (FF->head.privpars.vmode == VM_SUMMARY)	{	/* if summary */
			if (*ulevel >= curcount-1)		/* suppress fields beyond lowest */
				*ulevel = curcount-1;
		}
		else if (*ulevel == PAGEINDEX)		/* if page field in normal view */
			*ulevel = curcount-1;		/* position to it */
		if (((!*ulevel && curcount == 2 && FF->head.formpars.ef.cf.mainposition == CP_FIRSTSUB)	/* if want main head cross-ref as first subhead */
			 || (curcount > 2 && FF->head.formpars.ef.cf.subposition == CP_FIRSTSUB))	/* or subhead cross-ref as subhead */
			 && str_crosscheck(FF,scur[curcount-1].str))	/* and crossref */
				pagecodechar = FO_LEVELBREAK;		/* page field cross-ref for display as first sub */
		else if (*ulevel == curcount-1 && (FF->head.privpars.vmode != VM_SUMMARY || *scur[curcount-1].str) &&
			(FF->head.formpars.ef.cf.mainposition != CP_FIRSTSUB || !str_crosscheck(FF,scur[curcount-1].str)))	/* if not to format as a subhead cross-ref */
			baseshift = 1;
	}
	*(scur[curcount-2].str+scur[curcount-2].ln) = pagecodechar;	/* set page field lead (newline or elipsis) */
	for (fcount = 0; fcount < curcount-2; fcount++)		/* for fields to display */
		*(scur[fcount].str+scur[fcount].ln) = FF->head.privpars.vmode ? FO_LEVELBREAK : FO_ELIPSIS;	/* change null to elipsis */
	if (FF->head.privpars.hidebelow != ALLFIELDS && FF->head.privpars.vmode != VM_SUMMARY)	{	/* if some restriction on display */
		if (FF->head.privpars.hidebelow == ALLBUTPAGE)
			fcount = curcount-2;					/* not showing page */
		else if (FF->head.privpars.hidebelow < curcount-1)	/* if want a level above last field */
			fcount = FF->head.privpars.hidebelow-1;
		*(scur[fcount].str+scur[fcount].ln) = '\0';		/* terminate entry */
		if (*ulevel > fcount)	{	/* if unique in suppressed part */
			*ulevel = fcount;		/* ensures text copy is indented properly */
			return (g_nullstr);		/* nothing to display */
		}
	}
	if (!FF->owner.sumsource || *scur[*ulevel].str) {		// if not summary or have text to display
		char * nptr = scur[*ulevel].str;
		char * bptr;
//		if (bptr = strrchr(nptr,FO_NEWLEVEL))	{		// if last head level is beyond unique
		if (bptr = strrchr(nptr,FO_LEVELBREAK))	{		// if last head level is beyond unique
			memmove(bptr+1+leadlength,bptr+1, strlen(bptr+1)+1);	// shift string up
			strncpy(bptr+1,buffer,leadlength);		// insert lead
			while (--bptr > nptr) {
//				if (*bptr == FO_NEWLEVEL)	{	// if another field
				if (*bptr == FO_LEVELBREAK)	{	// if another field
					memmove(bptr+3,bptr+1, strlen(bptr+1)+1);	// shift string up
					*(bptr+1) = '\t';	// insert tab
					*(bptr+2) = '\t';	// insert tab
				}
			}
			memmove(buffer+2,nptr, strlen(nptr)+1);		// shift all down leaving two lead spaces for tabs
			*buffer = '\t';	// insert tab
			*(buffer+1) = '\t';	// insert tab
		}
		else if (*ulevel)	// unique is last level
//			memcpy(string,scur[*ulevel].str-baseshift,strlen(scur[*ulevel].str-baseshift)+1);
			memmove(string,scur[*ulevel].str-baseshift,strlen(scur[*ulevel].str-baseshift)+1);
		return buffer;
	}
	return g_nullstr;
}
/**********************************************************************/
static char * makelead(INDEX * FF, char * lptr, RECORD * recptr)		/* makes lead */

{
	*lptr++ = FONTCHR;			// set lead color
	*lptr++ = FX_COLOR|LEADCOLOR;
	if (recptr->time > FF->opentime)
		lptr = u8_appendU(lptr,BULLET);
	if (recptr->isdel)
		lptr = u8_appendU(lptr,NEQUAL);
	if (recptr->ismark)
		*lptr++ = '#';
#if 1
	*lptr++ = '\t';
	if (FF->righttoleftreading)
		lptr = u8_appendU(lptr,RLM);
	if (FF->head.privpars.shownum)
		lptr += sprintf(lptr, "%u", recptr->num);
#else
	if (FF->head.privpars.shownum)	{
		lptr += sprintf(lptr, "%lu", recptr->num);
		for (char *tptr = lptr; *tptr == SPACE; tptr++)
			*tptr = FGSPACE;
	}
#endif
	*lptr++ = FONTCHR;			// clear lead color
	*lptr++ = FX_COLOR;
	*lptr++ = '\t';
	if (recptr->label) {
		*lptr++ = FONTCHR;		// set tag color
		*lptr++ = FX_COLOR|recptr->label;
	}
	return lptr;
}

//
//  taggedtextwriter.m
//  Cindex
//
//  Created by PL on 4/26/05.
//  Copyright 2005 Indexing Research. All rights reserved.
//

#import "taggedtextwriter.h"
#import "IRIndexDocument.h"
#import "tags.h"
#import "strings_c.h"
#import "formattedexport.h"

static short taginit(INDEX * FF, FCONTROLX * fxp);	/* initializes control struct and emits header */
static void tagcleanup(INDEX * FF, FCONTROLX * fxp);	/* cleans up */
static void tagwriter(FCONTROLX * fxp,unichar uc);

static char newparaset[32];		/* assembled string for new paragraph */
static char * structtags[T_STRUCTCOUNT];	/* pointers to strings that define structure tags */
static char * styletags[T_STYLECOUNT];		/* pointers to strings that define style codes */
static char * fonttags[T_FONTCOUNT];		/* pointers to strings that define font codes */
static char * auxtags[T_OTHERCOUNT];		// pointers to auxiliary tags
static char protchars[MAXTSTRINGS+1];		/* string of protected ASCII characters */

FCONTROLX tagcontrol = {
	FALSE,		// file type
	FALSE,			// nested tags
	50,				// character overhead per entry
	NULL,			/* string pointer */
	taginit,		/* initialize */
	tagcleanup,		/* cleanup */
	NULL,			/* embedder */
	tagwriter,		// character writer
	structtags,		/* structure tags */
	styletags,		/* styles */
	fonttags,		/* fonts */
	auxtags,		// auxiliary tags
	NULL,			/* line break */
	newparaset,		/* new para */
	NULL,			/* obligatory newline (set at format time) */
	NULL,			/* tab */
	protchars,		/* characters needing protection */
	{
		NULL,		/* translation strings for protected characters */
	},
	FALSE,			/* use lead tags */
	FALSE,			/* don't suppress ref lead/end */
	FALSE,			/* don't tag individual refs */
	FALSE,			// don't tag individual crossrefs
	FALSE			/* not internal set */
};

static TAGSET * t_th;
/**********************************************************************/
static short taginit(INDEX * FF, FCONTROLX * fxp)	/* initializes control struct and emits header */

{
	char * fsptr;
	short count;
	
	if (t_th = ts_openset(ts_getactivetagsetpath(SGMLTAGS)))	{			/* if can get tag set */
		fxp->suppressrefs = t_th->suppress;	/* set reference lead/end control */
		fxp->nested = t_th->nested;			// nested heading tags
		fxp->individualrefs = t_th->individualrefs;	// tag individual refs
		fxp->individualcrossrefs = t_th->individualrefs;	// tag individual crossrefs (always same as for page refs)
		for (fsptr = str_xatindex(t_th->xstr,0), count = 0; count < T_STRUCTCOUNT; count++, fsptr += strlen(fsptr)+1)
			structtags[count] = fsptr;		/* pointer for struct tag string */
		for (fsptr = str_xatindex(t_th->xstr,T_STYLEBASE), count = 0; count < T_STYLECOUNT; count++, fsptr += strlen(fsptr)+1)
			styletags[count] = fsptr;		/* pointer for style tag string */
		for (fsptr = str_xatindex(t_th->xstr,T_FONTBASE), count = 0; count < T_FONTCOUNT; count++, fsptr += strlen(fsptr)+1)
			fonttags[count] = fsptr;		/* pointer for font ID string */
		for (fsptr = str_xatindex(t_th->xstr,T_OTHERBASE+OT_PR1),count = 0; count < MAXTSTRINGS; count++)	{
			protchars[count] = *fsptr;		/* add protected char to string */
			fsptr += strlen(fsptr)+1;		/* point to partner translation string */
			fxp->pstrings[count] = fsptr;	/* set translation string */
			fsptr += strlen(fsptr)+1;
		}
		for (fsptr = str_xatindex(t_th->xstr,T_OTHERBASE),count = 0; count < T_OTHERCOUNT; count++,	fsptr += strlen(fsptr)+1)
			auxtags[count] = fsptr;		// get auxiliary tags
		auxtags[OT_STARTTEXT] = g_nullstr;		// body text start (won't have been set in previous loop because of T_OTHERCOUNT)
		auxtags[OT_ENDTEXT] = g_nullstr;		// body text end
		fxp->newline = str_xatindex(t_th->xstr,T_OTHERBASE+OT_ENDLINE);
		sprintf(newparaset,"%.30s%s",str_xatindex(t_th->xstr,T_OTHERBASE+OT_PARA), fxp->newlinestring);	/* new para string + newline */
		fxp->tab = str_xatindex(t_th->xstr,T_OTHERBASE+OT_TAB);
		if (*structtags[STR_BEGIN])	/* if have start tag */
			fxp->esptr += sprintf(fxp->esptr,"%s%s",structtags[STR_BEGIN], fxp->newlinestring);		/* doc header */
		return (TRUE);
	}
	return (FALSE);
}
/**********************************************************************/
static void tagcleanup(INDEX * FF, FCONTROLX * fxp)	/* cleans up */

{
	if (t_th)	{	/* if have tags */
		if (*structtags[STR_END])	/*  if ending tag */
			fxp->esptr += sprintf(fxp->esptr,"%s%s",structtags[STR_END], tagcontrol.newlinestring);		/* doc footer string */
		t_th = NULL;
	}
}
/**********************************************************************/
static void tagwriter(FCONTROLX * fxp,unichar uc)	// emits unichar

{
	if (uc > 0x80 && !t_th->useUTF8)	{	// if want encoding
		char * formatstring = t_th->hex ? "%s%04x%s" : "%s%04d%s";
		fxp->esptr += sprintf(fxp->esptr, formatstring, auxtags[OT_UPREFIX], uc, auxtags[OT_USUFFIX]);
	}
	else
		fxp->esptr = u8_appendU(fxp->esptr,uc);
}

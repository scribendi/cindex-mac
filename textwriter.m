//
//  textwriter.m
//  Cindex
//
//  Created by PL on 4/26/05.
//  Copyright 2005 Indexing Research. All rights reserved.
//

#import "textwriter.h"
#import "IRIndexDocument.h"
#import "tags.h"
#import "commandutils.h"
#import "strings_c.h"
#import "formatparams.h"
#import "formattedexport.h"
#import "iconv.h"

static char * structtags[T_STRUCTCOUNT];
static char * styletags[T_STYLECOUNT] = {	/* pointers to strings that define style codes */
	g_nullstr,g_nullstr,
	g_nullstr,g_nullstr,
	g_nullstr,g_nullstr,
	g_nullstr,g_nullstr,
	g_nullstr,g_nullstr,
	g_nullstr,g_nullstr,
	g_nullstr,g_nullstr
};

static char * fonttags[T_FONTCOUNT] = {	/* pointers to strings that define font codes */
	g_nullstr,g_nullstr,
	g_nullstr,g_nullstr,
	g_nullstr,g_nullstr,
	g_nullstr,g_nullstr,
	g_nullstr,g_nullstr,
	g_nullstr,g_nullstr,
	g_nullstr,g_nullstr,
	g_nullstr,g_nullstr,
	g_nullstr,g_nullstr,
	g_nullstr,g_nullstr,
	g_nullstr,g_nullstr,
	g_nullstr,g_nullstr
};
static char * auxtags[T_OTHERCOUNT];	// pointers to auxiliary tags
static char protchars[MAXTSTRINGS];	/* characters needing protection */
static char stringbase[1500];	/* holds strings that define dynamically-built formatting tags */

static short textinit(INDEX * FF, FCONTROLX * fxp);	/* initializes control struct and emits header */
static void textcleanup(INDEX * FF, FCONTROLX * fxp);	/* cleans up */
static void textembedder(INDEX * FF, FCONTROLX * fxp, RECORD * recptr);	/* forms embedded entry */
static void textwriter(FCONTROLX * fxp,unichar uc);

FCONTROLX textcontrol = {
	FALSE,		// file type
	FALSE,			// nested tags
	20,				// character overhead per entry
	NULL,			/* string pointer */
	textinit,		/* initialize */
	textcleanup,	/* cleanup */
	textembedder,	/* embedder */
	textwriter,		// character writer
	structtags,		/* structure tags */
	styletags,		/* styles */
	fonttags,		/* fonts */
	auxtags,		// auxiliary tags
	"",				/* line break */
	NULL,			/* new para (set at format time) */
	NULL,			/* obligatory newline (set at format time) */
	"\t",			/* tab */
	protchars,		/* characters needing protection */
	{
		NULL,		/* translation strings for protected characters */
	},
	FALSE,			/* define lead indent with spaces (not tabs) */
	FALSE,			/* don't suppress ref lead/end */
	FALSE,			/* don't tag individual refs */
	FALSE,			// don't tag individual crossrefs
	TRUE			/* internal set */
};

static iconv_t converter;

/**********************************************************************/
static short textinit(INDEX * FF, FCONTROLX * fxp)	/* initializes control struct and emits header */

{
	int count, fieldlimit;
	int baseindent, firstindent;
	char * fsptr;
	char tabstops[200];
	char tabstring[FIELDLIM];

	fieldlimit = FF->head.indexpars.maxfields < FIELDLIM ? FF->head.indexpars.maxfields : FF->head.indexpars.maxfields-1;	// need 1 extra level for subhead cref
	for (fsptr = stringbase,count = 0; count < fieldlimit; count++)	{	/* for all text fields in index */
		float emwidth = type_getfontmetrics(FF->head.fm[0].name,FF->head.privpars.size, FF).width;
		
		formexport_gettypeindents(FF,count,fxp->usetabs, 1,&firstindent,&baseindent,g_nullstr,tabstops,tabstring);	/* gets base and first indents */
		structtags[count+STR_MAIN] = fsptr;		/* pointer for string (none) */
		structtags[count+STR_MAINEND] = g_nullstr;	/* pointer for trailing string (none) */
		fsptr += sprintf(fsptr, "%*s%s", (int)((baseindent+firstindent)/emwidth),g_nullstr,tabstring)+1;
	}
	structtags[STR_PAGE] = g_nullstr;		/* pointer for page tag */
	structtags[STR_PAGEND] = g_nullstr;		/* pointer for page end tag */
	structtags[STR_CROSS] = g_nullstr;		/* pointer for cross tag */
	structtags[STR_CROSSEND] = g_nullstr;	/* pointer for cross end tag */
	structtags[STR_GROUP] = g_nullstr;		// group start tag
	structtags[STR_GROUPEND] = g_nullstr;	// group end tag
	structtags[STR_AHEAD] = g_nullstr;		/* set ahead tag */
	structtags[STR_AHEADEND] = g_nullstr;	/* set ahead end tag */
	auxtags[OT_STARTTEXT] = g_nullstr;		// body text start
	auxtags[OT_ENDTEXT] = g_nullstr;		// body text end
	fxp->newpara = fxp->newlinestring;		/* set end of line string */
	
//	converter = iconv_open(V2_CHARSET,"UTF-16LE");

	if (!g_prefs.gen.nativetextencoding)	{	// if want utf8 encoding
		strcpy(fxp->esptr,utf8BOM);
		fxp->esptr += strlen(utf8BOM);
	}
	return (TRUE);
}
/**********************************************************************/
static void textcleanup(INDEX * FF, FCONTROLX * fxp)	/* cleans up */

{
	*fxp->esptr = '\0';		/* end of file */
//	iconv_close(converter);
}
/**********************************************************************/
static void textwriter(FCONTROLX * fxp,unichar uc)	// emits unichar

{
//	if (uc > 0x80 && g_prefs.gen.nativetextencoding)	{	// if want native encoding
	if (g_prefs.gen.nativetextencoding)	{	// if want native encoding
		char * ucp = (char *)&uc;
		size_t sourcecount = 2;		// number of bytes to convert (utf-16 == 2)
		size_t destcount = 6;		// larger than largest utf-8 string
		size_t length = -1;			// default failure
		
		if (converter || (converter = iconv_open(V2_CHARSET,"UTF-16LE")))
			length = iconv(converter,&ucp,&sourcecount,&fxp->esptr,&destcount);
		if ((int)length < 0)	// if error, assume unencodable char
			*fxp->esptr++ = (unsigned char)UNKNOWNCHAR;		// write unknown char
	}
	else
		fxp->esptr = u8_appendU(fxp->esptr,uc);
}
/**********************************************************************/
static void textembedder(INDEX * FF, FCONTROLX * fxp, RECORD * recptr)	/* forms embedded entry */

{
	CSTR scur[FIELDLIM];
	int curcount, fcount;

	curcount = str_xparse(recptr->rtext, scur);	/* parse string */
	for (fcount = 0; fcount < curcount; fcount++)	{	/* for all fields */
		formexport_makefield(fxp,FF,scur[fcount].str);
		if (fcount < curcount-1)	/* if not last field */
			*fxp->esptr++ = '\t';
	}
}

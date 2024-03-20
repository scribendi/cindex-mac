//
//  tags.h
//  Cindex
//
//  Created by PL on 1/23/05.
//  Copyright 2005 Indexing Research. All rights reserved.
//

#import "formattedexport.h"

enum {		// tag types
	XMLTAGS = 0,
	SGMLTAGS
};

enum {		/* structure tag indexes */
	STR_BEGIN = 0,
	STR_END,
	STR_GROUP,
	STR_GROUPEND,
	STR_AHEAD,
	STR_AHEADEND,
	STR_MAIN,
	STR_MAINEND = STR_MAIN+15,
	STR_PAGE = STR_MAIN+30,
	STR_PAGEND,
	STR_CROSS,
	STR_CROSSEND,
	
	T_STRUCTCOUNT	// number of structure tags
};

enum {		/* 'other' tag indexes */
	OT_PR1,			/* first protected character */
	OT_ENDLINE = MAXTSTRINGS*2,	/* end of line (after sets of protected chars) */
	OT_PARA,		/* end of para */
	OT_TAB,			/* tab */
	OT_UPREFIX,		// unicode prefix
	OT_USUFFIX,		// suffix
	// following 2 structure tags stuck here so that tagsets can be backward compatible with Cindex 3
	// reading tags reads to the end of the EOCS, so V3 ignores these
	OT_STARTTEXT,	// start heading text
	OT_ENDTEXT,		// end heading text
	
	T_OTHERCOUNT	// number of aux tags
};

//#define T_STRUCTCOUNT 40		/* number of structure tags */
#define T_STYLECOUNT 14			/* number of style tags */
#define T_FONTCOUNT 24			/* number of font tags */
//#define T_OTHERCOUNT 21			/* miscellaneous tags */

#define T_STRUCTBASE 0			/* index of first structure string */
#define T_STYLEBASE  (T_STRUCTBASE+T_STRUCTCOUNT)	/* index to first style string */
#define T_FONTBASE (T_STYLEBASE+T_STYLECOUNT)	/* index to first font string */
#define T_OTHERBASE (T_FONTBASE+T_FONTCOUNT)	/* index to first other string */

#define T_NUMTAGS (T_OTHERBASE+T_OTHERCOUNT)	/* index to first character code */
#define T_NUMFONTS (T_FONTCOUNT/2)				/* number of fonts */


typedef struct {	/* tagset structure */
	short tssize;	/* size of TAGSET */
	int total;		/* complete size of object */
	short version;	/* version of tags */
	char extn[4];	/* default extension for output file */	
	char readonly;	/* TRUE if set unmodifiable */
	char suppress;	/* TRUE if suppressing ref leader & trailer */
	char hex;		// true when hex; otherwise decimal
	char nested;	// TRUE when nested
	char fontmode;	// font tag type
	char individualrefs;	// TRUE if references coded individually
	char levelmode;	// heading level tag type
	char useUTF8;	// encode uchars as utf8 (SGML only)
	int spare[5];
	char xstr[];	/* base of compound string */
} TAGSET;

#define EMPTYTAGSETSIZE (sizeof(TAGSET)+T_NUMTAGS+1)
#define TS_VERSION 2	/* tag set version */

NSString * ts_getactivetagsetname(int type);	// gets active tagset name
NSString * ts_getactivetagsetpath(int type);	// gets active tagset for type
TAGSET * ts_openset(NSString * path);
NSArray * ts_gettagsets(NSString * type);
char * ts_gettagsetextension(NSString * path);
void ts_convert(TAGSET * ts);

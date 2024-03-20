//
//  translate.h
//  Cindex
//
//  Created by PL on 1/17/05.
//  Copyright 2005 Indexing Research. All rights reserved.
//

#import "indexdocument.h"

#define V1STSTRING 256	/* basic standard string */
#define V1FTSTRING 128
#define V1FSSTRING 32
#define V1FMSTRING 16
#define V1STYLESTRINGLEN 256

#define V1COMPMAX 10

typedef struct {	/* maps font name to local ID */
	Str31 name;		/* font name */
	short familyID;	/* family ID (fill in when index loaded) */
} V10_FONTMAP;

struct V10_typegroup	{	/* typesetting info */
	char wp[9];			/* wp driver */
	char inserttag;		/* insert tags */
	char fixlength;		/* fix line length */
	char useindent;		/* use indents */
	char usespacing;	/* use line spacing */
	int spare[4];		/* !!spare */
};

typedef struct {	/* character style/position structure */
	short style;	/* character style */
	short cap;		/* capitalization type */
	short spare;	/* !!spare */
} V10_CSTYLE;

struct V10_margcol	{		/* margins & columns */
	short top;
	short bottom;
	short left;
	short right;
	short ncols;
	short gutter;
	short reflect;
	short pgcont;		/* repeat broken head after break */
	char continued[V1FSSTRING];	/* 'continued' text */
	V10_CSTYLE cstyle;
	short clevel;		/* level down to which want continuation */
	int spare[4];		/* !!spare */
};

struct V10_headfoot	{	/* header & footer content */
	char left[V1FTSTRING];
	char center[V1FTSTRING];
	char right [V1FTSTRING];
	V10_CSTYLE hfstyle;		/* style */
	short hffont;		/* font */
	int spare[4];		/* !!spare */
};

struct V10_pageform {		/*	page format */
	struct V10_margcol mc;
	struct V10_headfoot lefthead;
	struct V10_headfoot leftfoot;
	struct V10_headfoot righthead;
	struct V10_headfoot rightfoot;
	short linespace;		/* line spacing (single, double, etc.) */
	short firstpage;
	short lineheight;		/* line height */
	short entryspace;		/* space between entries*/
	short above;			/* space above group header */
	char lineunit;			/* unit of measurement for vertical spacing */
	char autospace;			/* TRUE if line-spacing derived automatically */
	char dateformat;		/* date format index */
	char timeflag;			/* TRUE when to add time to date */
	int spare[4];			/* !!spare */
};

typedef struct {			/* cross-ref punctuation structure */
	char cleada[V1FMSTRING];	/* lead text for open ref (see also) */
	char cenda[V1FMSTRING];	/* end text */
	char cleadb[V1FMSTRING];	/* lead text for blind ref (see) */
	char cendb[V1FMSTRING];	/* end text */
} V1CROSSPUNCT;

struct V10_crossform {		/* cross-reference formatting */
	V1CROSSPUNCT level[2];	/* array of 2 punctuation structures (head & subhead) */
	V10_CSTYLE leadstyle;		/* lead style */
	V10_CSTYLE bodystyle;		/* body style */
	short position;			/* how placed in entry */
	char sortcross;			/* TRUE: arrange refs */
	char spare1;			/* !!spare */
	int spare[4];			/* !!spare */
};

typedef struct {	/* locator segment style structure */
	V10_CSTYLE loc;		/* locator itself */
	V10_CSTYLE punct;	/* trailing punctuation */
	int spare;		/* !!spare */
} V10_LSTYLE;

struct V10_locatorform	{		/* locator formatting */
	char sortrefs;			/* TRUE: arrange refs */
	char rjust;				/* right justify */
	char llead1[V1FMSTRING];	/* lead text for single ref */
	char lleadm[V1FMSTRING];	/* lead text for multiple refs */
	char trail[V1FMSTRING];	/* trailing text for refs */
	char connect[V1FMSTRING];	/* connecting sequence */
	short conflate;			/* threshold for conflation */
	short abbrevrule;		/* abbreviation rule */
	short supflag;			/* suppress repeated parts */
	char suppress[V1FMSTRING];	/* suppress to last of these chars */
	char concatenate[V1FMSTRING];	/* concatenate with this sequence */
	V10_LSTYLE lstyle[V1COMPMAX];	/* segment style sequence */
	int spare[4];			/* !!spare */
};

struct V10_groupform	{	/* grouping of entries */
	short method;		/* grouping method */
	short gfont;		/* font */
	V10_CSTYLE gstyle;		/* style */
	short gsize;		/* text size */
	char title[V1FSSTRING];	/* title/format string */
	int spare[4];			/* !!spare */
};

struct V10_fieldform	{	/* individual field layout */
	short font;			/* font */
	short size;			/* size */
	V10_CSTYLE style;		/* style */
	float leadindent;	/* first line indent (points) */
	float runindent;	/* runover indent (points) */
	char trailtext[V1FMSTRING];	/* trailing text for when no ref */
	int spare[4];			/* !!spare */
};
struct V10_entryform	{		/* overall heading layout */
	short runlevel;			/* runon level */
	char style;				/* index style modifiers */
	char itype;				/* indentation type (auto, etc) */
	char adjustpunct;		/* adjust punctuation */
	char adjstyles;			/* adjust style codes around punctuation */
	char fixedems;			/* TRUE if fixed spacing unit is ems */
	char autoems;			/* TRUE if auto spacing unit is ems */
	float autolead;			/* space for auto lead */
	float autorun;			/* space for autorunin */
	struct V10_groupform eg;
	struct V10_crossform cf;
	struct V10_locatorform lf;
	struct V10_fieldform field[FIELDLIM-1];	/* field info */
	int spare[16];			/* !!spare */
};

struct V10_formgroup	{		/* overall format structure */
	struct V10_pageform pf; 
	struct V10_entryform ef;
	int spare[32];			/* !!spare */
};

struct V10_indexgroup 	{		/* index structure */
	short recsize;			/* record size */
	short minfields;		/* min fields required in record */
	short maxfields;		/* max fields allowed in record */
	FIELDPARAMS field[FIELDLIM];		/* field information */
	int spare[4];			/* !!spare */
};
	
#define V1PREFIXLEN 256

struct V10_sortgroup {		/* struct for sort pars */
	char type;			/* sort type */
	short fieldorder[FIELDLIM+1];		/* order of fields */
	short charpri[CHARPRI+1];	/* character priority */
	char ignorepunct;	/* ignore l-by-l punctuation */
	char ignoreslash;	/* ignore /- in word sort */
	char ignoreparen;	/* ignore text in parens */
	char evalnums;		/* evaluate numbers */
	char crossfirst;	/* cross-refs first */
	char ignore[V1PREFIXLEN];	/* ignored leading words in subheads */
	char skiplast;			/* skip last heading field */
	char ordered;		/* references ordered */
	char ascendingorder;	/* refs in ascending order */
	short refpri[REFTYPES+1];		/* reference priority */
	short partorder[V1COMPMAX+1];	/* component comparison order */
	unsigned char chartab[256];	/* character value table */
	char spare1;		/* spare */
	char ison;			/* sort is on */
	char reftab[REFTYPES];	/* priority table for ref types */
	int spare[4];			/* !!spare */
};

struct V10_refgroup {		/* reference parameters */
	char crosstart[256];	/* words that can begin cross-refs */
	char crossexclude[256];	/* word that begin general cross ref */
	char csep;			/* cross-ref separator */
	char psep;			/* page ref separator */
	char rsep;			/* page ref connector */
	int spare[4];		/* !!spare */
};

struct V10_privgroup	{		/* general config parameters to remember silently */
	char vmode;				/* full format/ draft flag */
	char wrap;				/* line wrap flag */
	char shownum;			/* show record numbers */
	char hidedelete;		/* hide deleted records */
	short hidebelow;		/* hide headings below this level */
	short size;				/* default font size */
	Rect rwrect;			/* size/position of editing window */
	char eunit;				/* unit in which measurements are expressed */
	char spare1;
	int spare[6];			/* !!spare */
};

typedef struct {
	unsigned short version;		/* version # */
	RECN rtot;					/* total number of records */
	time_c elapsed;				/* time spent executing commands */
	time_c createtime; 			/* time of creation  */
	short resized;				/* true if resized */
	short spare1;				/* spare */
	time_c squeezetime;			/* time of last squeeze */
	struct V10_indexgroup indexpars;/* index structure pars */
	struct V10_sortgroup sortpars;	 /* sort parameters */
	struct V10_refgroup refpars;	 /* reference parameters */
	struct V10_privgroup privpars;	/* private preferences */
	struct V10_formgroup formpars;	/* format parameters */
	struct V10_typegroup typepars;	/* typesetting params */
	char stylestrings[V1STYLESTRINGLEN];		/* strings for auto style */
	V10_FONTMAP fm[FONTLIMIT];		/* mapping of local IDs to font names (0 is default) */
	RECN root;					/* number of root of alpha tree */
	short dirty;				/* TRUE if any record written before close */
	char spare[256];		/* !!spare */
} V10_HEAD;

#define DOSEOCS '\377'
#define DOSENDASH '\196'

enum	{		/* DOS translation flags */
	TR_DOFONTS = 1,
	TR_DOSYMBOLS = 2
};

struct ghstruct		{	/* for handling DOS g & h code translations */
	short flags;
	short fcode[2];		/* font ids for translation of DOS g & h codes */
	FONTMAP * fmp;		/* fontmap for translation of g,h codes */
};
enum {		/* import control flags */
	READ_IGNORERR = 1,
	READ_HASGH = 2,		/* dos import uses gh codes */
	READ_TRANSGH = 4	/* dos import translates gh codes */
};

extern char mac_to_dos[];
extern char dos_to_win[];
extern char win_to_mac[];
extern char dos_greek[];	/* Mac characters that in symbol font match dos greek */
extern char dos_fromsymbol[];	/* DOS extend chars that match chars from the symbol font */
extern char tr_escname[];	/* key chars for DOS escape sequences */
extern unsigned char tr_attrib[];		/* text attribute flags */

short tr_V10toV11(FSSpec *fsptr);	/* converts old index to current format */
short tr_ghok(struct ghstruct * ghp);	/* gets spec and goes to record */
int tr_dosxstring(char * buff,struct ghstruct *ghp, int flags);	/* translates DOS CINDEX control codes in record */
BOOL tr_winxstring(FONTMAP * fm, char * buff);	/* translates Windows characters in extended string */
void tr_movesubcross(INDEX * FF, char * buff);	/* moves any subhead cross-ref to page field */

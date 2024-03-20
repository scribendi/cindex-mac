//
//  import.h
//  Cindex
//
//  Created by Peter Lennie on 2/3/11.
//  Copyright 2011 Indexing Research. All rights reserved.
//

#import "indexdocument.h"
#import "expat.h"
#import "translate.h"

#define IMP_MAXERRBUFF 500
#define ARCHIVEOFFSET 16	/* offset from start of file for reading archive records */


enum {		/* record formation errors */
	BADCHAR = -10,	/* illegal character */
	TOOLONGFORINDEX,		/* exceeds max record size */
	BADMACREX,		/* macrex record parsing error */
	BADDELIMIT,		/* missing delimiter at start or end of line */
	TOOMANYFIELDS,	/* too many fields */
	TOOLONGFORRECORD,	/* exceeds record size */
	MISSINGFONT,		// records call missing font
	DIFFERENTSEPARATORS,	// page or crossref separator doesn't match existing
	EMPTYRECORD			// empty record
};

enum {		// extended record flags
	W_DELFLAG = 1,
	W_TAGFLAG = 2,
	W_GENFLAG = 4,
	W_NEWTAGS = (8+16),
	W_PUSHLAST = 128
};

enum {
	KEY_WIN = 0x01010101,		/* Windows archive key */
	KEY_MAC =  0x02020202,		/* Mac archive key */
	KEY_ABBREV = 0x41414141,	/* abbreviation file key ("AAAA") (windows only) */
	KEY_UNKNOWN = 0xFFFFFFFF	/* unknown */
};

enum {				// subtype keys
	TEXTKEY_NATIVE = 0,
	TEXTKEY_UTF8 = 4,
};

enum	{		/* import file types */
	I_CINARCHIVE,
	I_CINXML,
	I_PLAINTAB,		// tab delimited text
	I_DOSDATA,		// DOS cindex
	I_MACREX,
	I_SKY,
};

enum	{
	SKYTYPE_7,
	SKYTYPE_8
};

enum {
	PM_SCAN = 0,
	PM_READ = 1
};

struct rerr {		/* read error structure */
	short type;
	int line;
};

typedef struct {
	XML_Parser parser;
	int activefont;		// id of active font
	int activefield;	// index of active field
	char * destination;	// where to put character data
	char * limit;		// limit char position
	int errorline;		// line number of element unknown
	BOOL overflow;		// TRUE when element value overflow
	BOOL collect;		// can collect character data
	int textfont;		// current font info
	char textcode;		// current style info
	char textcolor;		// current color info
	BOOL inindex;		// is inside the index
	BOOL infonts;		// gathering font info
	BOOL inrecords;		// gathering records
	BOOL fontsOK;		// got good font info;
	RECN activerecord;	// record being parsed
	int error;			// error id
	BOOL protectedchar;	// protectedchar
} PARSERDATA;

typedef struct {
	int mode;			// parser mode
	RECN recordcount;	// line/record count
	short xflags;		/* control flags */
	BOOL conflictingseparators;	// import specifies conflicting locator and/or xref separators
	struct ghstruct gh;	/* for translation of DOS gh codes */
	unsigned int type;			/* file type */
	unsigned int subtype;		/* distinguishes file subtypes */
	unsigned int skytype;		// distinguishes sky subtypes
	BOOL delimited;		// true if quote-delimited
	struct rerr errlist[IMP_MAXERRBUFF];	/* record error info */
	RECN ecount;		/* error count */
	RECN emptyerrcnt;	/* count of empty rec errors */
	RECN lenerrcnt;		/* count of length errors */
	RECN fielderrcnt;	/* number of records with too many fields */
	RECN fonterrcnt;	// number of records with bad fonts
	RECN markcount;		/* number of marked records */
	char sepstr[4];		/* string for delimited separators */
	UInt64 freespace;	/* space available to expand index */
	short longest;		/* longest record scanned */
	short deepest;		/* # fields in deepest record scanned */
	FONTMAP tfm[FONTLIMIT];	/* font map for archive */
	short farray[FONTLIMIT]; /* font substitution array */
	char buffer[MAXREC+2];	// record buffer
	INDEX * FF;
	PARSERDATA pdata;		// parser data
	RECORD prec;		// temporary record
} IMPORTPARAMS;

BOOL imp_findtexttype(IMPORTPARAMS * imp, char * data, unsigned long datalength);
int imp_readrecords(INDEX * FF, IMPORTPARAMS * imp, char * data, unsigned long datalength);
int imp_resolveerrors(INDEX * FF, IMPORTPARAMS *imp);
BOOL imp_adderror(IMPORTPARAMS *imp, int type, int line);		// adds a new error to the list

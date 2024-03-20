//
//  indexdocument.h
//  Cindex
//
//  Created by Peter Lennie on 6/1/11.
//  Copyright 2011 Indexing Research. All rights reserved.
//

#import "mfile.h"

typedef unichar LMONTH[20];

typedef struct {
	UCollator * ucol;
	int mode;
	LMONTH longmonths[12];
	LMONTH shortmonths[12];
	const UNormalizer2 * unorm;
} COLLATOR;


#define MAXTSTRINGS 8	/* maximum number of translations for ASCII chars */

@class IRIndexDocument;

typedef struct index INDEX;

typedef struct fxc {		/* file writing control struct */
	short filetype;			// type of file to write
	BOOL nested;			// nested tags
	int entrypadding;		// overhead allowance per entry
	char * esptr;			/* output string ptr */
	short (*efstart) (INDEX *FF, struct fxc * fxp);	/* setup function */
	void (*efend) (INDEX * FF, struct fxc * fxp);	/* cleanup function */
	void (*efembed) (INDEX * FF, struct fxc * fxp, RECORD * recptr);	/* forms embedded entry */
	void (*efwriter) (struct fxc * fxp, unichar uc);	// emits unicode character
	char **structtags;		/* heading style tags */
	char **styleset;		/* table of style code strings */
	char **fontset;			/* table of font code strings */
	char **auxtags;			// strings for auxiliary tags
	char *newline;			/* optional line (not para) break */
	char *newpara;			/* string that defines paragraph break */
	char *newlinestring;	/* obligatory new line (mac or dos) */
	char *tab;				/* tab code */
	char * protected;		/* string of protected characters */
	char * pstrings[MAXTSTRINGS];		/* translation strings for protected characters */
	short usetabs;			/* TRUE if to define lead indent with tabs */
	short suppressrefs;		/* TRUE if suppressing ref lead/end when tagging */
	short individualrefs;	/* TRUE if tagging refs individually */
	short individualcrossrefs;	/* TRUE if tagging refs individually */
	short internal;			/* TRUE if internal code set */
	char stylenames[FIELDLIM][FNAMELEN];	// style names
} FCONTROLX;

struct index {		/* runtime index structure */
	IRIndexDocument * __unsafe_unretained owner;
	char readonly;			/* TRUE if index is read only */
	char ishidden;			/* can't be used explicitly */
	time_c opentime;		/* time at which index opened */
	time_t lastflush;		/* time of last flush */
	RECN lastfound;			/* last record found in search */
	RECN startnum;			/* number of records in index when opened */
	RECN lastedited;		/* last record edited */
	size_t wholerec;		/* size of record including header */
	short viewtype;			/* flags indcate what view we have */
	GROUPHANDLE lastfile;	/* file for most recent search */
	GROUPHANDLE curfile;	/* file used for skip, etc */
	RECN curfilepos;		/* index of current record in group */
	RECN recordlimit;		// highest numbered record for which we have room
	GROUP * gbase;			// base of groups
	char wasdirty;			/* TRUE if index was ever dirty */
	char wasedited;			/* TRUE if record window ever used */
	PRINTFORMAT pf;			/* page format structure */
	short stylecount;		/* count of styled strings */
	CSTR slist[AUTOSIZE];	/* parsed styled strings */
	HEAD head;				/* index header */
	MFILE mf;				// mapped file struct
	BOOL continued;			// TRUE when working with continuation heading
	BOOL singlerefcount;	// TRUE when page range to be counted as single ref
	int overlappedrefs;		// TRUE when some page reference has overlapping range
	unsigned char * formBuffer;	// buffer for formatted entry
	COLLATOR collator;
	FCONTROLX * typesetter;
	BOOL needsresort;		// TRUE when needs resort;
	BOOL righttoleftreading;	// right to left reading
};

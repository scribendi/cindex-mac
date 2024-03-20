//
//  formattedtext.h
//  Cindex
//
//  Created by PL on 2/11/05.
//  Copyright 2005 Indexing Research. All rights reserved.
//
#import "indexdocument.h"
#import "records.h"

typedef struct {		/* information about entry */
	short ulevel;		/* unique level */
	short llevel;		/* lowest level text field */
	short ahead;		/* TRUE if this is ahead */
	unichar leadchange;	/* TRUE if lead changes */
	short firstrec;		/* TRUE if first record in view */
	unsigned int length;		/* end position */
	short prefs;		/* number of page refs */
	short crefs;		/* number of cross-refs */
	int drecs;			/* number of unique records consumed in building it */
	short forcedrun;	/* level of forced run-on heading */
	int consumed;		// number of records consumed (including non-unique)
} ENTRYINFO;

RECORD * form_getrec(INDEX * FF, RECN rnum);	/* returns ptr to record (or parent) */
RECORD * form_skip(INDEX * FF, RECORD * recptr, short dir);	/* skips in formatted mode */
char * form_buildentry(INDEX * FF, RECORD * recptr, ENTRYINFO *esp);	/* builds entry text */
char * form_formatcross(INDEX * FF, char * source);	/* formats cross-ref into static string */
char *form_stripcopy(char *dptr, char *sptr);	 /* copies, skipping over braced text */

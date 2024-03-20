/*
 *  printformat.h
 *  Cindex
 *
 *  Created by PL on 1/11/05.
 *  Copyright 2005 Indexing Research. All rights reserved.
 *
 */

typedef struct 	{	/* page formatting structure */
	int characters;		// total characters
	short totalpages;	// total pages examined/generated
	int first;			/* first page to produce */
	int last;			/* last page to produce */
	short oddeven;		/* flags for odd even pages */
	RECN firstrec;		/* record to start at */
	RECN lastrec;		/* last record */
	short pagenum;		/* number given starting page */
	int uniquemain;	// unique ain headings
	int entries;		/* # entries produced */
	int prefs;			/* page refs produced */
	int crefs;			/* # cross refs */
	int lines;			/* # lines */
	short pageout;		/* number of pages that would be output */
	short lastpage;		/* number of last page formatted */
	RECN rnum;			// record at top of first page
	RECN lastrnum;		// record at bottom of last page
	short offset;		/* # lines into record */
	short labelmark;	/* print bullet on labeled records */
	int spare[128];
} PRINTFORMAT;


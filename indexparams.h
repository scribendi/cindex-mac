/*
 *  indexparams.h
 *  Cindex
 *
 *  Created by PL on 1/10/05.
 *  Copyright 2005 Indexing Research. All rights reserved.
 *
 */

#define FNAMELEN 32		// max length of field name
#define PATTERNLEN 64

typedef struct {		/* specs of field */
	char name[FNAMELEN];	/* name */
	unsigned short minlength;		/* minimum */
	unsigned short maxlength;		/* max */
	char matchtext[PATTERNLEN];/* field must match this pattern */
	int spare[32];			/* !!spare */
} FIELDPARAMS;

typedef struct 	{		/* index structure */
	unsigned short recsize;			/* record size */
	unsigned short minfields;		/* min fields required in record */
	unsigned short maxfields;		/* max fields allowed in record */
	FIELDPARAMS field[FIELDLIM];		/* field information */
	short required;		// last text field is required
	short sspare;		// spare
	int spare[64];		// spare
} INDEXPARAMS;

#define FLAGLIMIT 8		/* max # of flags*/

typedef struct {		// properties of display filter
	unsigned char label[FLAGLIMIT];	// labels (coded by bit positions)
	unsigned char on;	// filtering enabled
	unsigned char spare[128];
} DISPLAYFILTER;

typedef struct	{		/* general config parameters to remember silently */
	char vmode;				/* full format/ draft flag */
	char wrap;				/* line wrap flag */
	char shownum;			/* show record numbers */
	char hidedelete;		/* hide deleted records */
	short hidebelow;		/* hide headings below this level */
	short size;				/* default font size */
	char eunit;				/* unit in which measurements are expressed */
	char filterenabled;		// display filtering enabled
	DISPLAYFILTER filter;	// display filter
	RECT rwrect;			/* size/position of editing window */
	int spare[64];			/* !!spare */
} PRIVATEPARAMS;

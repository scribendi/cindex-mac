//
//  tools.h
//  Cindex
//
//  Created by PL on 1/17/05.
//  Copyright 2005 Indexing Research. All rights reserved.
//

#import "indexdocument.h"

#define ORPHANARRAYBLOCK 500
enum {
	OR_ABSORB = 0,
	OR_DELETE,
	OR_PRESERVE
};

enum {
	SPLIT_PHRASE,
	SPLIT_NAME_S,
	SPLIT_NAME_F,
	SPLIT_USER,
};

typedef struct {
	VERIFY * crossrefs;
	int refcount;
	unsigned int fields[];
} CHECKERROR;

typedef struct  {		/* contains parameters for joining records */
	short firstfield;	/* highest level field to join */
	char jchar;			/* joining character */
	short nosplit;		/* don't split modified fields */
	short protectnames;	/* don't split where cap follows join char */
	short orphanaction;	// don't joint orphans
//	BOOL showorphans;	// show orphans
//	int * orphans;		// array of orphan records
	int orphancount;
	CHECKERROR ** errors;
} JOINPARAMS;

#define SPLITPATTERNLEN 256
typedef struct  {		// contains parameters for splitting records
	char userpattern[SPLITPATTERNLEN];
	int patternindex;
	BOOL preflight;		// just run parser and show string output
	BOOL markmissing;	// mark records with missing targets
	BOOL cleanoriginal;	// clean original heading
	BOOL removestyles;	// removes styles
	RECN gencount;
	RECN markcount;
	RECN modcount;
	char ** reportlist;
} SPLITPARAMS;

#if 1
enum errorTypes {	// item tags are shift size +1
	CE_MULTISPACE = 1,
	CE_PUNCTSPACE = 1<<1,
	CE_MISSINGSPACE = 1<<2,
	CE_UNBALANCEDPAREN = 1<<3,
	CE_UNBALANCEDQUOTE = 1<<4,
	CE_MIXEDCASE = 1<<5,
	CE_MISUSEDESCAPE = 1<<6,
	CE_MISUSEDBRACKETS = 1<<7,
	CE_BADCODE = 1<<8,

	CE_INCONSISTENTCAPS = 1<<9,
	CE_INCONSISTENTSTYLE = 1<<10,
	CE_INCONSISTENTPUNCT = 1<<11,
	CE_INCONSISTENTLEADPREP = 1<<12,
	CE_INCONSISTENTENDPLURAL = 1<<13,
	CE_INCONSISTENTENDPREP = 1<<14,
	CE_INCONSISTENTENDPHRASE = 1<<15,
	CE_ORPHANEDSUBHEADINGINDEX = 16,
	CE_ORPHANEDSUBHEADING = 1<<CE_ORPHANEDSUBHEADINGINDEX,

	CE_EMPTYPAGE = 1<<17,
	CE_TOOMANYPAGEINDEX = 18,
	CE_TOOMANYPAGE = 1<<CE_TOOMANYPAGEINDEX,
	CE_OVERLAPPINGINDEX = 19,
	CE_OVERLAPPING = 1<<CE_OVERLAPPINGINDEX,
	CE_HEADINGLEVEL = 1<<20,
	
	CE_CROSSERR = 1<<21,

};
#else
enum errorTypes {	// item tags are shift size +1
	CE_MULTISPACE = 1,
	CE_PUNCTSPACE = CE_MULTISPACE<<1,
	CE_MISSINGSPACE = CE_PUNCTSPACE<<1,
	CE_UNBALANCEDPAREN = CE_MISSINGSPACE<<1,
	CE_UNBALANCEDQUOTE = CE_UNBALANCEDPAREN<<1,
	CE_MIXEDCASE = CE_UNBALANCEDQUOTE<<1,
	CE_MISUSEDESCAPE = CE_MIXEDCASE<<1,
	CE_MISUSEDBRACKETS = CE_MISUSEDESCAPE<<1,
	CE_BADCODE = CE_MISUSEDBRACKETS<<1,
	
	CE_INCONSISTENTCAPS = CE_BADCODE<<1,
	CE_INCONSISTENTSTYLE = CE_INCONSISTENTCAPS<<1,
	CE_INCONSISTENTPUNCT = CE_INCONSISTENTSTYLE<<1,
	CE_INCONSISTENTLEADPREP = CE_INCONSISTENTPUNCT<<1,
	CE_INCONSISTENTENDPLURAL = CE_INCONSISTENTLEADPREP<<1,
	CE_INCONSISTENTENDPREP = CE_INCONSISTENTENDPLURAL<<1,
	CE_INCONSISTENTENDPHRASE = CE_INCONSISTENTENDPREP<<1,
	CE_ORPHANEDSUBHEADING = CE_INCONSISTENTENDPHRASE<<1,
	
	CE_EMPTYPAGE = CE_ORPHANEDSUBHEADING<<1,
	CE_TOOMANYPAGE = CE_EMPTYPAGE<<1,
	CE_OVERLAPPING = CE_TOOMANYPAGE<<1,
	CE_HEADINGLEVEL = CE_OVERLAPPING<<1,
	
	CE_CROSSERR = CE_HEADINGLEVEL<<1,
	
#endif

typedef struct {
	int version;
	BOOL reportKeys[32];
//	int orphanlevel;
	int pagereflimit;
//	int crossminmatch;
//	BOOL crossexactmatch;
	JOINPARAMS jng;
	VERIFYGROUP vg;
	CHECKERROR ** errors;
} CHECKPARAMS;


RECN tool_join(INDEX * FF, JOINPARAMS *js);	 /* joins fields of records that have redundant subheadings */
RECN tool_explode (INDEX * FF, SPLITPARAMS *sp);	 // explodes headings by separating entities
void tool_check (INDEX * FF, CHECKPARAMS *cp);	 // makes comprehensive checks on entries

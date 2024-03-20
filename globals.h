//
//  globals.h
//  Cindex
//
//  Created by PL on 1/10/05.
//  Copyright 2005 Indexing Research. All rights reserved.
//
typedef struct {
	CGFloat red;
	CGFloat green;
	CGFloat blue;
}RGB;

enum {
	PASTEMODE_ALL,
	PASTEMODE_STYLEONLY,
	PASTEMODE_PLAIN
};

extern unichar abbrev_prefix[];	/* prefixes */
extern unichar abbrev_suffix[];   /* suffixes that can trigger expansion */

extern char g_nullstr[];		/* a null string */
extern char g_nullrec[];	/* null record */
extern int g_tzoffset;		// time zone offset from GMT (sec)

struct genpref {		/* general preferences */
	char openflag;		/* open last index on startup */
	char labelsetsdate;	// labeling record stamps date
	char showlabel;		/* show labeled records in formatted view */
	char smartflip;		// make flips smart
	char autorange;		/* spare */
	char setid;			/* want user id */
	char propagate;		/* propagate edit changes */
	short saveinterval;	/* preferred save interval */
	char pagealarm;		/* alarm level for page refs */
	char crossalarm;	/* alarm level for page refs */
	char templatealarm;	/* alarm level for template mismatch */
	char carryrefs;		/* carry refs from one record to the next */
	char switchview;	/* TRUE if to switch to draft mode for editing */
	char track;			/* TRUE if want to track position of new entries */
	char vreturn;		/* TRUE if want to return display to original record */
	char saverule;		/* saving behavior on record window */
	RGB lcolors[FLAGLIMIT];
	FONTMAP fm[FONTLIMIT];	/* mapping of local IDs to font names (0 is default) */
	char autoextend;	/* autoextends fields while typing */
	char autoignorecase;	/* ignores case in autoextend matching */
	char remspaces;		/* remove duplicate spaces */
	char tracksource;	/* tracks source entry */
	char newlinetype;	/* newline type */
	char indentdef;		/* type of indent for formatted export */
	short recordtextsize;
	char embedsort;		// TRUE if want to embed sort info
	char autoupdate;	//TRUE if auto updating
	char nativetextencoding;	// TRUE if native encoding
	char pastemode;		// mode for pasting styles/fonts
	char spare[7];		/* !!spare */
};

struct hiddenpref {		/* hidden preferences (always become defaults) */
	int crossminmatch;	// verify min count
	int pagemaxcount;	// page max count
	short hideinactive;	/* show/hide windows for inactive indexes */
	char user[6];		/* user initials */
	char absort;		/* abbreviation sort type */
	char spare1;
	int spare[8];		/* !!spare */
};

struct langprefs {	/* aggregate of language preferences */
	short suggestflag;	/* auto-suggest */
	short ignallcaps;		/* check words in caps */
	short ignalnums;		/* check alnums */
	int spare[8];			/* !!spare */
};

struct prefs {			/* preferences struct */
	unsigned int key;			/* key number identifies file generation */
	struct hiddenpref hidden;	/* hidden preferences */
	struct genpref gen;	/* general preferences */
	struct langprefs langpars;	/* spell checker language settings */
	INDEXPARAMS indexpars;	/* index structure prefs */
	SORTPARAMS sortpars;	/* sort preferences */
	REFPARAMS refpars;	/* ref preferences */
	PRIVATEPARAMS privpars;	/* private preferences */
	FORMATPARAMS formpars;	/* format preferences */
	char stylestrings[STYLESTRINGLEN];		/* strings for auto style */
	char flipwords[STSTRING];		/* strings for auto style */
	char spare[STSTRING];		/* keys strings */
};

enum {
	GPREF_GENERAL = 1
};

extern NSString * CIPrefs;
extern NSString * CIFunctionKeys;
extern struct prefs g_prefs;		/* preferences info */

void global_registerdefaults (void);
void global_readdefaults (void);
void global_saveprefs(int type);	// saves preferences settings
NSString * global_preferencesdirectory(void);	// returns User's Cindex Prefs directory
NSString * global_supportdirectory(BOOL writable);	// returns System App Support directory
BOOL global_authorize(void);


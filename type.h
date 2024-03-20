//
//  type.h
//  Cindex
//
//  Created by PL on 1/12/05.
//  Copyright 2005 Indexing Research. All rights reserved.
//

#import "indexdocument.h"

#define VOLATILEFONTS 1	// V3 base id of changeable fonts
#define OLDVOLATILEFONTS 2	/* base id of changeable fonts in earlier versions */

enum {		/* case conversion codes */
	FC_NONE,
	FC_INITIAL,
	FC_UPPER,
	FC_AUTO,
	FC_TITLE
};

typedef struct {
	char * name;
	unichar *ucode;
} SPECIALFONT;

extern SPECIALFONT t_specialfonts[];// fonts that require character conversion

BOOL type_available(char * fname);		/* returns id of font (or 0) */
short type_checkfonts(FONTMAP * fm);	/* checks that preferred or substitute fonts exist */
short type_scanfonts(INDEX * FF, short * farray);	/* identifies fonts used in index */
void type_trimfonts(INDEX * FF);	// removes unused fonts from font list
void type_findlostfonts(INDEX * FF);	// finds/marks dead fonts from references in records
void type_tagfonts(char * text, short * farray);	  /* tags index of fonts used in xstring */
short type_findcodestate(char * start, char * end, char *attr, char * font);	/*finds active codes/fonts at end of span */
void type_adjustfonts(INDEX * FF, short * farray);	/* adjusts font ids used in index */
BOOL type_setfontids(char * text, short * farray);	  /* adjusts ids of fonts used in xstring */
short type_ispecialfont(char *name);		//TRUE if not letter font
BOOL type_isvalidfontid(INDEX * FF, int fid);	// return true if font id is valid
short type_maplocal(FONTMAP * fmp, char * fname, int base);	// finds local id for preferred font
short type_findlocal(FONTMAP * fmp, char * fname, int base);	/* finds/assigns local id for font */
short type_makelocal(FONTMAP * fmp, char * pname, char * fname, int base);	/* finds/assigns local id for possibly unknown font */
char * type_pickcodes(char *sptr, char * eptr, struct codeseq * cs);	/* picks up loose codes at end point */
char * type_dropcodes(char *sptr, struct codeseq * cs);	/* drops codes, advances ptr */
char * type_balancecodes(char *sptr, char * eptr, struct codeseq * cs, short match);	/* finds loose codes (and balances) at end of string */
char * type_matchcodes(char *sptr, struct codeseq * cs, short free);	/* sets codes on string */
NSSize type_getfontmetrics(char * font, int size, INDEX * FF);	// returns line spacing and em width for font

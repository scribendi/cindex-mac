//
//  strings.h
//  Cindex
//
//  Created by PL on 1/8/05.
//  Copyright 2005 Indexing Research. All rights reserved.
//

#import "indexdocument.h"

#define str_xlen(A)	(((char *)memchr(A,EOCS,UINT_MAX))-((char *)A))
#define str_xshift(source,count) memmove((source)+(short)(count),source,str_xlen(source)+1)
#define str_shift(source,count) memmove((source)+(short)(count),source,strlen(source)+1)

enum	{			/* compound string search flags */
	CCASE = 1, 		/* case sensitivity for compound string search */
	CSINGLE = 2,	/* search only first string */
	CWORD = 4,		/* need whole word match */
	CNOCODE = 8,	/* ignores codes */
	CSWORD = 16	/* need match to start of word */
};

enum {			/* code cleanup flags */
	CC_TRIM = 1,	/* trim leading and trailing spaces */
	CC_ONESPACE = 2,	/* remove spaces > 1 */
	CC_INPLACE = 4	// in place adjustment
};

//short _toupper(char c);
//short _tolower(char c);
void str_upr(char * str);		/* converts to upper case (deals with esc chars & extended) */
void str_lwr(char * str);		/* converts to upper case (deals with esc chars & extended) */
void str_title(char * string, char * skiplist);		// returns title case string
char * str_xstr(char * list, char * string);	/* finds string in array */
int str_xcount(char * list);		/* # strings in list */
int str_xparse(char * list, CSTR * array);		/* puts string pointers in array */
int str_xindex(char * list, char * string);	/* finds index of string in array */
char * str_xatindex(char * list, short index);	/* finds string at indexed position */
char * str_extend(char * string);		/* converts string to extended string */
void str_flip(char * fields, char * presuf, BOOL smart, BOOL half, BOOL page);	// flips fields
BOOL str_swapparen(char * field, char * presuf,BOOL real);	//  in-place swap of text in parens and outside
CSTATE str_codesatposition(char * string, int offset, int * span, char stylemask, char fontmask);	// returns net code value at offset
char * str_spanforcodes(char * base, char style, char font, char forbiddenstyle, char forbiddenfont, short * span);	// returns position and span of specified style/font
BOOL str_containscodes(char * base, char style, char  font, short span);	// returns position and span of specified style/font
char * str_encloseinstyle(char * string, CSTATE style);	// encloses string in style
char str_capturecodes(char * string, int length);	// returns net code value at length
char * str_skipcodes(char * string);		/* returns ptr to first non- codesequence */
char * str_rskipcodes(char * string);		/* returns ptr to last non- codesequence */
char *str_xlast(char * text);    /* returns pointer to start of last field */
char * str_xdup(char *source);	// duplicates compound string
char * str_xcpy(register char *to, register char *from);	/* copies extended string */
void str_xswap(char *string, short index1, short index2);	  /* swaps two component strings */
int str_xcmp(register char *str1, register char *str2);	  /* compares two compound strings */
char *str_xfind(char *source, char *target, unsigned short flags, unsigned short maxlen, unsigned short * actuallen);	   /* finds substring in compound string */
//char *str_skipbrackets(char *sptr);		/* skips to closing bracket */
char * str_skiptoword(char * string);		// returns ptr to first non-punct, non code
char * str_skiptowordbreak(char * string);		// returns ptr to first non-word character
char *str_skiptoclose(char *sptr, unichar tc);	/* skips to char beyond closing char */
char *str_skiplist(char *base, char *list, short * tokens);		/* points to first word in base that isn't in list */
char *str_skiplistrev(char *base, char *list, short * tokens);		/* points to end of last word in base that isn't in list */
char *str_skiplistmax(char *base, char *list);		/* points to first char in base that isn't start of potential word in list */
void str_xpad(char *string, short max, BOOL addonend);	  /* expands string to max fields */
int str_xstrip(char *string, short min);	  /* strips empty strings from extended (to min) */
int str_adjustcodes(char * dest, int flags);	/* cleans up codes, removes surplus spaces (if trimming) */
char * str_xfindcross(INDEX * FF, register char * string, short sflag);	/* find cross-ref (if any) in string */
short str_crosscheck(INDEX * FF,char *str);        /* checks string to see if begins with 'see' */
int str_xtextlen(char *cptr);	   /* counts # of text chars in xstring (ignores codes) */
int str_textlen(char *cptr);	   /* counts # of text chars in string (ignores codes) */
int str_utextlen(char *cptr, int length);	   /* counts # of unicode chars in string (ignores codes) */
void str_textcpy(char *dptr, char *cptr);	   /* copy text, stripping codes */
int str_textcpylimit(char *base, char *cptr, char *limit);	   /* copy text up to limit, stripping codes */
int str_stripcopy(register unsigned char *dest, register unsigned char *source);	   // copies chars in string (ignores special chars); returns text count
int str_texticmp(char *s1, char *s2);	   /* compares case insensitive, ignoring codes, up s1 len */
void str_setgetlimits(unsigned char *base, unsigned long limit);	// sets limits on read buffer
char * str_getline(char * buff, int max, int * ctptr);	// reads input line from buffer
int str_roman(char * string, int num, int upperflag);		/* makes roman numeral from int */
//NSAttributedString * str_xtoastring(char * string, FONTMAP * fm, unsigned char echar);	// makes attributed string from xstring
//int str_atoxstring(NSAttributedString * astring, unsigned char * rstring, FONTMAP * fm);	// makes xstring from attributed string

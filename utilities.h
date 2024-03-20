//
//  utilities.h
//  Cindex
//
//  Created by Peter Lennie on 1/14/11.
//  Copyright 2011 Peter Lennie. All rights reserved.
//


extern char codecharset[];

IRRect IRRectFromNSRect(NSRect rect);
NSRect NSRectFromIRRect(IRRect rect);
NSArray * getfilelist(NSString * dirpath, NSString * type);
void checktextfield(NSControl * field, int limit);	// limits length of text in NSControl
BOOL iscodechar(short cc);	// tests if character is code char
int isfontcodeptr(char *cc);	// tests if code represents font
char * u8_back1(char * ptr);	// moves back one code point
char * u8_forward1(char * ptr);	// moves forward one code point
unichar u8_toU(char * ptr);	// returns single char from utf-8
unichar u8_prevU(char ** pptr);	// returns prev char from utf-8
unichar u8_nextU(char ** pptr);	// returns next char from utf-8
char * u8_appendU(char * ptr, unichar uc);	// appends utf8 string for unichar
char * u8_insertU(char * ptr, unichar uc, int gapchars);	// inserts utf8 string for unichar
int u8_countU(char * ptr, int length);	// counts uchars for length
BOOL u8_isvalidUTF8(char * ptr, int32_t length);	// checks validity of utf8
void u8_normalize(char * ptr, int length);		// normalizes utf-8 string to composed characters
//unichar symbolcharfromroman(unsigned char schar);	// return unichar value of symbol font character
//char charfromsymbol(unichar uc);	// returns symbol font char for unicode

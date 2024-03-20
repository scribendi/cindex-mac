//
//  utilities.m
//  Cindex
//
//  Created by Peter Lennie on 1/14/11.
//  Copyright 2011 Peter Lennie. All rights reserved.
//

#import "utilities.h"

#define shiftstring(source,count) memmove((source)+(short)(count),source,strlen(source)+1)

char codecharset[] = {CODECHR,FONTCHR,0};

/***************************************************************************/
IRRect IRRectFromNSRect(NSRect rect)

{
	static IRRect irr;
	
	irr.origin.x = (float)rect.origin.x;
	irr.origin.y = (float)rect.origin.y;
	irr.size.width = (float)rect.size.width;
	irr.size.height = (float)rect.size.height;
	return irr;
}
/***************************************************************************/
NSRect NSRectFromIRRect(IRRect rect)

{
	static NSRect nrr;
	
	nrr.origin.x = rect.origin.x;
	nrr.origin.y = rect.origin.y;
	nrr.size.width = rect.size.width;
	nrr.size.height = rect.size.height;
	return nrr;
}
/***************************************************************************/
NSArray * getfilelist(NSString * dirpath, NSString * type)

{
	NSDirectoryEnumerator * dirEnum = [[NSFileManager defaultManager] enumeratorAtPath:dirpath];
	NSMutableArray * list = [NSMutableArray arrayWithCapacity:10];
	NSString * file;
	while ((file = [dirEnum nextObject])) {
		if ([[file pathExtension] isEqualToString:type])
			[list addObject:[dirpath stringByAppendingPathComponent:file]];
	}
	return list;
}
/***************************************************************************/
void checktextfield(NSControl * field, int limit)	// limits length of text in NSControl

{
	NSString * ustring = [field stringValue];
	int initlength = [ustring length];
	int length = initlength;
	
	while (strlen([ustring UTF8String]) > limit-1)
		ustring = [ustring substringToIndex:--length];
	if (initlength > length)	// if needed to reduce length
		[field setStringValue:ustring];
}
/***************************************************************************/
BOOL iscodechar(short cc)	// tests if character is code char

{
	if (cc == CODECHR || cc == FONTCHR)
		return TRUE;
	return FALSE;
}
/***************************************************************************/
int isfontcodeptr(char *cc)	// tests if code represents font

{
	if (*cc++ == FONTCHR && *cc&FX_FONT)
		return TRUE;
	return FALSE;
}
/***************************************************************************/
char * u8_back1(char * ptr)	// moves back one code point

{
	int sindex = 0;
	U8_BACK_1_UNSAFE(ptr,sindex);
	return ptr+sindex;
}
/***************************************************************************/
char * u8_forward1(char * ptr)	// moves forward one code point

{
	int sindex = 0;
	U8_FWD_1_UNSAFE(ptr,sindex);
	return ptr+sindex;
}
/***************************************************************************/
unichar u8_toU(char * ptr)	// returns single char from utf-8

{
	unichar cc;
	U8_GET_UNSAFE(ptr,0,cc);
	return cc;
}
/***************************************************************************/
unichar u8_prevU(char ** pptr)	// returns single char from utf-8

{
	unichar cc;
	int sindex = 0;
	
	U8_PREV_UNSAFE(*pptr,sindex,cc);
	*pptr += sindex;
	return cc;
}
/***************************************************************************/
unichar u8_nextU(char ** pptr)	// returns single char from utf-8

{
	unichar cc;
	int sindex = 0;
	
	U8_NEXT_UNSAFE(*pptr,sindex,cc);
	*pptr += sindex;
	return cc;
}
/***************************************************************************/
char * u8_appendU(char * ptr, unichar uc)	// appends utf8 string for unichar

{
	int sindex = 0;
	
	U8_APPEND_UNSAFE(ptr,sindex,uc);
	return ptr+sindex;
}
/***************************************************************************/
char * u8_insertU(char * ptr, unichar uc, int gapchars)	// inserts utf8 string for unichar

{
	int length = U8_LENGTH(uc);
	int sindex = 0;

	if (length > gapchars)
		shiftstring(ptr+1,length-gapchars);
	U8_APPEND_UNSAFE(ptr,sindex,uc);
	return ptr+length;
}
/***************************************************************************/
int u8_countU(char * ptr, int length)	// counts uchars for length

{
	int ucount, ccount;
	
	// which method is faster?
#if 0
	UErrorCode error = U_ZERO_ERROR;
	u_strFromUTF8(NULL,0,&ucount,ptr,length,&error);		// preflighting count
#else
	for (ucount = ccount = 0; ccount < length; ucount++)
		U8_FWD_1_UNSAFE(ptr,ccount);
#endif
	return ucount;
}
/****************************************************************************************/
BOOL u8_isvalidUTF8(char * ptr, int32_t length)	// checks validity of utf8

{
	UErrorCode error = U_ZERO_ERROR;
	unichar * dest = malloc(length*sizeof(unichar));
	int32_t destlength = 0;
	u_strFromUTF8(dest,length,&destlength,ptr,length,&error);
	free(dest);
	return U_SUCCESS(error);
}
#if 0
/***************************************************************************************/
void u8_normalize(char * ptr, int length)		// normalizes utf-8 string to composed characters

{
	static const UNormalizer2 * n2;
	unichar * sourcestring = malloc(length*sizeof(unichar));
	UErrorCode error = U_ZERO_ERROR;
	int32_t sourcelength,cleanlength;
	
	if (!n2)	{
		n2 = unorm2_getInstance(NULL,"nfc",UNORM2_COMPOSE,&error);
		error = U_ZERO_ERROR;
	}
	u_strFromUTF8(sourcestring,length,&sourcelength,ptr,length,&error);
	if (error == U_ZERO_ERROR)	{
		cleanlength = unorm2_spanQuickCheckYes(n2,sourcestring,sourcelength,&error);
		if (cleanlength < sourcelength && error == U_ZERO_ERROR)	{		// if need normalization
			unichar * normstring = malloc(2*sourcelength*sizeof(unichar));
			int32_t normlength, utf8length;
			
			u_strncpy(normstring,sourcestring,cleanlength);
			normlength = unorm2_normalizeSecondAndAppend(n2,normstring,cleanlength,2*sourcelength,&sourcestring[cleanlength],sourcelength-cleanlength,&error);
			if (error == U_ZERO_ERROR)
				u_strToUTF8(ptr, length, &utf8length, normstring, normlength, &error);
			free(normstring);
		}
	}
	free(sourcestring);
}
#else
/***************************************************************************************/
void u8_normalize(char * ptr, int length)		// normalizes utf-8 string to composed characters

{
	static const UNormalizer2 * n2;
	unichar * sourcestring = malloc(length*sizeof(unichar));
	UErrorCode error = U_ZERO_ERROR;
	int32_t sourcelength,cleanlength;
	
	if (!n2)	{
		n2 = unorm2_getInstance(NULL,"nfc",UNORM2_COMPOSE,&error);
		error = U_ZERO_ERROR;
	}
	u_strFromUTF8(sourcestring,length,&sourcelength,ptr,length,&error);
	if (error == U_ZERO_ERROR)	{
		cleanlength = unorm2_spanQuickCheckYes(n2,sourcestring,sourcelength,&error);
		if (cleanlength < sourcelength && error == U_ZERO_ERROR)	{		// if need normalization
			unichar * normstring = malloc(2*sourcelength*sizeof(unichar));
			int32_t normlength, utf8length;
			
			normlength = unorm2_normalize(n2,sourcestring,sourcelength,normstring,2*sourcelength*sizeof(unichar),&error);
			if (error == U_ZERO_ERROR)
				u_strToUTF8(ptr, length, &utf8length, normstring, normlength, &error);
			free(normstring);
		}
	}
	free(sourcestring);
}
#endif

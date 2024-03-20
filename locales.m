//
//  locales.m
//  Cindex
//
//  Created by Peter Lennie on 1/6/11.
//  Copyright 2011 Peter Lennie. All rights reserved.
//

#import "locales.h"
#import "unicode/uloc.h"

/****************************************************************************************/
const char * loc_currentLocale(void)

{
	return [[[NSLocale autoupdatingCurrentLocale] localeIdentifier] UTF8String];
}
/****************************************************************************************/
char * displayNameForLocale(char * identifier)

{
	static char displayname[100];
	unichar buffer[100];
	UErrorCode error = U_ZERO_ERROR;
	int dlength;
	
	uloc_getDisplayName(identifier,"en_US",buffer,100,&error);
//	NSLog(@"%s:%S",identifier,buffer);
	error = U_ZERO_ERROR;
	 u_strToUTF8(displayname,100,&dlength,buffer,-1,&error);
//	NSLog(@"%s",displayname);
	if (U_SUCCESS(error))
		return displayname;
	return identifier;
}
/****************************************************************************************/
BOOL localeSameLanguage(char * root1, char * root2)

{
	int index;
	
	for (index = 0; isalpha(root1[index]); index++)
		;
	return !strncasecmp(root1, root2, index);
}
/****************************************************************************************/
uint32_t LCIDforCurrentLocale(void)	// returns windows language code

{
	NSLocale *loc = [NSLocale autoupdatingCurrentLocale];
	const char * identifier = [[loc localeIdentifier] UTF8String];
	
	return uloc_getLCID(identifier);
}
/****************************************************************************************/
uint32_t LCIDforLocale(char * sortLocale)	// returns windows language code for named locale

{
	NSLocale * loc = [NSLocale autoupdatingCurrentLocale];
	char * identifier = (char *)[[loc localeIdentifier] UTF8String];
	
// do this because LCID for unadorned 'en', etc does not include sort component code, and then MS Word doesn't check spelling
	if (!strncmp(sortLocale, identifier, strlen(sortLocale)))	// if current locale is same or more specific than sort
		sortLocale = identifier;
	return uloc_getLCID(sortLocale);
}

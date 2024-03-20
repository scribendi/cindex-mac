//
//  v3handler.h
//  Cindex
//
//  Created by Peter Lennie on 1/17/11.
//  Copyright 2011 Peter Lennie. All rights reserved.
//

#import "iconv.h"

char * v3_warnings(char * warnstring);	// forms warning message
BOOL v3_convertstylesheet(NSString * path, NSString * oType);	// converts style sheet
//BOOL v3_convertstationery(NSString * path, NSString * oType);	// converts stationary
BOOL v3_convertindex(NSString * path, NSString * aType);	// converts index
int v3_convertrecord(char * xstring, FONTMAP * fm, BOOL replace);	// converts xstring to UTF-8
iconv_t v3_openconverter(char * ctype);	// opens converter

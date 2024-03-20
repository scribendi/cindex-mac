//
//  AttributedStringCategories.h
//  Cindex
//
//  Created by PL on 3/27/05.
//  Copyright 2005 Indexing Research. All rights reserved.
//
#import "fontmap.h"

@interface NSAttributedString (AttributedStringCategories)
+ (NSAttributedString *)asFromXString:(char *)string fontMap:(FONTMAP *)fm size:(float)size termchar:(unsigned char)echar;	// makes attributed string from xstring
- (NSComparisonResult)caseInsensitiveCompare:(NSAttributedString *)aString;
- (NSAttributedString *)normalizeAttributesWithMap:(FONTMAP *)fmap;
- (NSAttributedString *)normalizeAttributesWithMap:(FONTMAP *)fmap size:(float)size;
- (NSAttributedString *)normalizeToBaseFont:(FONTMAP *)fmap size:(float)size;
- (int)convertToXString:(unsigned char *)rstring fontMap:(FONTMAP *)fm mode:(int)flags;	// makes xstring from attributed string
@end

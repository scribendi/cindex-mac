//
//  TextViewCategories.m
//  Cindex
//
//  Created by PL on 3/16/05.
//  Copyright 2005 Indexing Research. All rights reserved.
//

// some of this stolen from Apple's TipWrapper example

#import "TextViewCategories.h"

@implementation NSTextView (TextViewCategories)
- (unsigned int) numberOfLines {
    unsigned int	result;
    NSLayoutManager	*lm;
    unsigned int				glyphIndex;
    NSRange			allCharactersRange, allGlyphsRange;
    NSRange			lineFragmentGlyphRange;

    result = 0;

    //	Note our range of characters
    allCharactersRange = NSMakeRange (0, [[self string] length]);

    //	Find how many glyphs there are
    lm = [self layoutManager];
	allGlyphsRange = [lm glyphRangeForCharacterRange: allCharactersRange
        actualCharacterRange: NULL];

    glyphIndex = 0;
    while (glyphIndex < NSMaxRange (allGlyphsRange))
    {
        (void) [lm lineFragmentRectForGlyphAtIndex: glyphIndex
            effectiveRange: &lineFragmentGlyphRange];

        //	Count the line we found
        ++result;

        //	Move to the start of the next line
        glyphIndex = NSMaxRange (lineFragmentGlyphRange);
    }

    return result;
}

//	lines -- Return the lines as an array of strings, reflecting both hard and soft line breaks.
//	This is a lot like code above. It would be better to create an enumerator to return line ranges,
//	then have both the method above and this method use that enumerator.
- (NSArray *) lines {
    NSString	*s;
    NSMutableArray	*result;
    NSLayoutManager	*lm;
    unsigned int	glyphIndex;
    NSRange		allCharactersRange, allGlyphsRange;
    NSRange		lineFragmentGlyphRange, lineFragmentCharacterRange;

    s = [self string];
    result = [NSMutableArray array];

    //	Find our range of characters
    allCharactersRange = NSMakeRange (0, [[self string] length]);

    //	Find how many glyphs there are
    lm = [self layoutManager];
	allGlyphsRange = [lm glyphRangeForCharacterRange: allCharactersRange
        actualCharacterRange: NULL];

    glyphIndex = 0;
    while (glyphIndex < NSMaxRange (allGlyphsRange))
    {
        NSString	*oneLine;

        (void) [lm lineFragmentRectForGlyphAtIndex: glyphIndex
            effectiveRange: &lineFragmentGlyphRange];

        lineFragmentCharacterRange =
            [lm characterRangeForGlyphRange: lineFragmentGlyphRange  actualGlyphRange: NULL];

        oneLine = [s substringWithRange: lineFragmentCharacterRange];
        [result addObject: oneLine];

        glyphIndex = NSMaxRange (lineFragmentGlyphRange);
    }
    return result;
}
- (NSArray *) lineRanges {
//    NSString		*s;
    NSMutableArray	*result;
    NSLayoutManager	*lm;
    unsigned int				glyphIndex;
    NSRange			allCharactersRange, allGlyphsRange;
    NSRange			lineFragmentGlyphRange, lineFragmentCharacterRange;

//    s = [self string];
    result = [NSMutableArray array];

    //	Find our range of characters
    allCharactersRange = NSMakeRange (0, [[self string] length]);

    //	Find how many glyphs there are
    lm = [self layoutManager];
	allGlyphsRange = [lm glyphRangeForCharacterRange: allCharactersRange actualCharacterRange: NULL];

    glyphIndex = 0;
    while (glyphIndex < NSMaxRange (allGlyphsRange)) {
        NSValue * lrange;

        (void) [lm lineFragmentRectForGlyphAtIndex: glyphIndex effectiveRange: &lineFragmentGlyphRange];
        lineFragmentCharacterRange = [lm characterRangeForGlyphRange:lineFragmentGlyphRange  actualGlyphRange:NULL];
		lrange = [NSValue valueWithRange:lineFragmentCharacterRange];
        [result addObject:lrange];
        glyphIndex = NSMaxRange (lineFragmentGlyphRange);
    }
    return result;
}
- (unichar)rightCharacter {
	NSRange crange = [self selectedRange];
	NSUInteger index = NSMaxRange(crange);
	
	if (index < [[self string] length])
		return [[self string] characterAtIndex:index];
	return 0;
}
- (unichar)leftCharacter {
	NSRange crange = [self selectedRange];
	
	if (crange.location >= 1)
		return [[self string] characterAtIndex:crange.location-1];
	return 0;
}
- (unichar)lastSelectedCharacter {
	NSRange crange = [self selectedRange];
	
	if (crange.length >= 1)
		return [[self string] characterAtIndex:crange.location+crange.length-1];
	return 0;
}
@end

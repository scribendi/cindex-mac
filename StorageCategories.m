//
//  StorageCategories.m
//  Cindex
//
//  Created by PL on 4/9/05.
//  Copyright 2005 Indexing Research. All rights reserved.
//

#import "StorageCategories.h"
#import "LayoutDescriptor.h"

@implementation NSTextStorage (StorageCategories)
- (LayoutDescriptor *) descriptor {
	LayoutDescriptor * layout = [[LayoutDescriptor alloc] init];
    NSString		*s = [self string];
    NSLayoutManager	*lm;
    NSUInteger	glyphIndex;
    NSRange			allCharactersRange, allGlyphsRange;
    NSRange			lineFragmentGlyphRange, lineFragmentCharacterRange;
	
	float height = 0;
	float linecount = 0;
	NSUInteger length = [s length];

    //	Find our range of characters
    allCharactersRange = NSMakeRange (0, length);
    //	Find how many glyphs there are
    lm = [[self layoutManagers] objectAtIndex:0];
	allGlyphsRange = [lm glyphRangeForCharacterRange: allCharactersRange actualCharacterRange: NULL];

    glyphIndex = 0;
    while (glyphIndex < NSMaxRange (allGlyphsRange)) {
        NSRect lrect =  [lm lineFragmentRectForGlyphAtIndex: glyphIndex effectiveRange: &lineFragmentGlyphRange];
        lineFragmentCharacterRange = [lm characterRangeForGlyphRange:lineFragmentGlyphRange  actualGlyphRange:NULL];
        [[layout lineRanges] addObject:[NSValue valueWithRange:lineFragmentCharacterRange]];
        [[layout lineHeights] addObject:[NSNumber numberWithFloat:lrect.size.height]];
        height += lrect.size.height;
		linecount++;
        glyphIndex = NSMaxRange(lineFragmentGlyphRange);
    }
	[layout setEntryLength:length];
	[layout setHeight:height];
	[layout setLineCount:linecount];
    return layout;
}
-(int)linesForRange:(NSRange)range	{
	NSLayoutManager * lm = [[self layoutManagers] objectAtIndex:0];
	NSRange allGlyphsRange = [lm glyphRangeForCharacterRange:range actualCharacterRange:NULL];
	NSUInteger glyphIndex = 0;
	int linecount = 0;
    NSRange lineFragmentGlyphRange;

    for (glyphIndex = allGlyphsRange.location; glyphIndex < NSMaxRange(allGlyphsRange); glyphIndex = NSMaxRange(lineFragmentGlyphRange)) {
        [lm lineFragmentRectForGlyphAtIndex: glyphIndex effectiveRange: &lineFragmentGlyphRange];
        [lm characterRangeForGlyphRange:lineFragmentGlyphRange  actualGlyphRange:NULL];
		linecount++;
    }
	return linecount;
}
@end

//
//  LayoutDescriptor.m
//  Cindex
//
//  Created by PL on 4/9/05.
//  Copyright 2005 Indexing Research. All rights reserved.
//

#import "LayoutDescriptor.h"
#import "strings_c.h"

@implementation LayoutDescriptor
- (id)init {
	if (self = [super init]) {
		_lineRanges = [[NSMutableArray alloc] initWithCapacity:5];
		_lineHeights = [[NSMutableArray alloc] initWithCapacity:5];
	}
	return self;
}
- (id)initWithStorage:(NSTextStorage *)storage range:(NSRange)range {
	if (self = [self init]) {
		NSLayoutManager	*lm = [[storage layoutManagers] objectAtIndex:0];
		NSUInteger	glyphIndex;
		NSRange			/* allCharactersRange, */ allGlyphsRange;
		NSRange			lineFragmentGlyphRange, lineFragmentCharacterRange;

		_length = range.length;
		//	Find our range of characters
//		allCharactersRange = NSMakeRange (0, _length);
		//	Find how many glyphs there are
		allGlyphsRange = [lm glyphRangeForCharacterRange:range actualCharacterRange: NULL];

		glyphIndex = allGlyphsRange.location;
		while (glyphIndex < NSMaxRange (allGlyphsRange)) {
			NSRect lrect =  [lm lineFragmentRectForGlyphAtIndex: glyphIndex effectiveRange: &lineFragmentGlyphRange];
			lineFragmentCharacterRange = [lm characterRangeForGlyphRange:lineFragmentGlyphRange  actualGlyphRange:NULL];
			[_lineRanges addObject:[NSValue valueWithRange:lineFragmentCharacterRange]];
			[_lineHeights addObject:[NSNumber numberWithFloat:lrect.size.height]];
			_height += lrect.size.height;
			_lineCount++;
			glyphIndex = NSMaxRange(lineFragmentGlyphRange);
		}
	}
	return self;
}
- (id)initWithStorage:(NSTextStorage *)storage entry:(IRAttributedDisplayString *)string {
	if (self = [self init]) {
		NSLayoutManager	*lm = [[storage layoutManagers] objectAtIndex:0];
		NSUInteger glyphIndex;
		NSRange allCharactersRange, allGlyphsRange;
		NSRange lineFragmentGlyphRange, lineFragmentCharacterRange;

		[storage setAttributedString:string];
		_length = [[storage string] length];
		//	Find our range of characters
		allCharactersRange = NSMakeRange (0, _length);
		//	Find how many glyphs there are
		allGlyphsRange = [lm glyphRangeForCharacterRange: allCharactersRange actualCharacterRange: NULL];

		glyphIndex = 0;
		while (glyphIndex < NSMaxRange (allGlyphsRange)) {
			NSRect lrect =  [lm lineFragmentRectForGlyphAtIndex: glyphIndex effectiveRange: &lineFragmentGlyphRange];
			lineFragmentCharacterRange = [lm characterRangeForGlyphRange:lineFragmentGlyphRange  actualGlyphRange:NULL];
			[_lineRanges addObject:[NSValue valueWithRange:lineFragmentCharacterRange]];
			if (!glyphIndex)	{	// if first character
				NSParagraphStyle * pp = [storage attribute:NSParagraphStyleAttributeName atIndex:0 effectiveRange:NULL];
				lrect.size.height += [pp paragraphSpacingBefore];	// add any otherwise uncounted lead
			}
			[_lineHeights addObject:[NSNumber numberWithFloat:lrect.size.height]];
			_height += lrect.size.height;
			_lineCount++;
			glyphIndex = NSMaxRange(lineFragmentGlyphRange);
		}
		_entry = string;
		_record = string.record;
		_recordsConsumed = [string entryInformation]->consumed;
	}
	return self;
}
- (NSRange)displayRangeForSourceRange:(NSRange)range{		// for draft formatted text only
	INDEX * FF = ((IRDisplayString *)_entry.string).index;
	RECORD * recptr = rec_getrec(FF,_record);
	int baseLevel = ((IRDisplayString *)_entry.string).entryInformation->ulevel;
	ATTRIBUTEDSTRING * att = ((IRDisplayString *)_entry.string).attributedText;
	CSTR levels[FIELDLIM];
	
	str_xparse(recptr->rtext,levels);
	char * rptr = levels[baseLevel].str;
	unichar * aptr = att->string;
	int offset, location, mcount, tabcount;
	
	for (offset = 0; * rptr != EOCS && rptr < recptr->rtext+range.location; ) {	// find offset of ptr in original record (starting at right level)
		if (iscodechar(*rptr) && *(rptr+1))
			rptr += 2;
		else {
			offset++;
			rptr = u8_forward1(rptr);
		}
	}
	location = mcount = tabcount = 0;
	do {
		if (!location || *(aptr-1) == FO_LEVELBREAK) {		// if at start of any line, count and skip lead chars
			while (*aptr != '\t')	{ // skip any lead markers up to first tab
				location++;
				aptr++;
			}
			location++;		// must be at first tab; skip it and all through next one
			while (*++aptr != '\t')
				location++;
			location++;
			aptr++;
			if (*aptr == FO_ELIPSIS)	// skip any elipsis
				location++;
		}
	} while (mcount++ < offset && location++ && aptr++);
	if (!range.length)	// if want all record text
		range.length = att->length-location-1;
	return NSMakeRange(location, range.length);
}
- (void)dealloc {
	[self setEntry:nil];
}
- (RECN)record {
	return _record;
}
- (int)recordsConsumed {
	return _recordsConsumed;
}
- (void)setEntry:(NSAttributedString *)text {
	_entry = text;
}
- (NSAttributedString *)entry {
	return _entry;
}
- (void)setEntryLength:(NSUInteger)length {
	_length = length;
}
- (NSUInteger)entryLength {
	return _length;
}
- (void)setLineCount:(NSUInteger)count {
	_lineCount = count;
}
- (NSUInteger)lineCount {
	return _lineCount;
}
- (void)setHeight:(float)height {
	_height = height;
}
- (float)height {
	return _height;
}
- (NSMutableArray *)lineRanges {
	return _lineRanges;
}
- (NSMutableArray *)lineHeights {
	return _lineHeights;
}
- (NSString *)description {
	return [NSString stringWithFormat:@"Record: %u, Lines: %ld, Height: %g, Ranges: %@",
	_record, (long)_lineCount, _height, [_lineRanges description]];
}
@end

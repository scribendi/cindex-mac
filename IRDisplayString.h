//
//  IRDisplayString.h
//  Cindex
//
//  Created by PL on 4/9/05.
//  Copyright 2005 Indexing Research. All rights reserved.
//
#import "IRIndexDocument.h"
#import "type.h"
#import "formattedtext.h"
#import "attributedstrings.h"

extern NSString * IRHeadingLevelKey;
extern NSString * IRRecordNumberKey;
extern NSString * IRRecordInfoKey;

@interface IRDisplayString : NSString {
	INDEX * FF;
	NSMutableArray * _iHeadings;
	__weak NSMutableArray * _iHeadingParagraphs;
	ATTRIBUTES _attributes;	// attributes
	ENTRYINFO _entryinfo;	// entry details
	BOOL _fullviewmode;
	RECN _record;
	ATTRIBUTEDSTRING * _as;
}
- (id)initWithIRIndex:(IRIndexDocument *)doc paragraphs:paragraphs record:(RECN)record;
- (NSDictionary *)attributesAtIndex:(NSUInteger)index effectiveRange:(NSRangePointer)aRange;
- (NSDictionary *)attributesAtIndex:(NSUInteger)index longestEffectiveRange:(NSRangePointer)aRange inRange:(NSRange)rangeLimit;
- (INDEX *)index;
- (RECN)record;
- (ATTRIBUTEDSTRING *)attributedText;
- (ENTRYINFO *)entryInformation;
@end

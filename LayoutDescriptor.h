//
//  LayoutDescriptor.h
//  Cindex
//
//  Created by PL on 4/9/05.
//  Copyright 2005 Indexing Research. All rights reserved.
//

#import "IRAttributedDisplayString.h"

@interface LayoutDescriptor : NSObject {
	RECN _record;
	int _recordsConsumed;
	NSAttributedString * _entry;
	NSUInteger _length;
	NSUInteger _lineCount;
	float _height;
	NSMutableArray * _lineRanges;
	NSMutableArray * _lineHeights;
}
- (id)initWithStorage:(NSTextStorage *)storage range:(NSRange)range;
- (id)initWithStorage:(NSTextStorage *)storage entry:(IRAttributedDisplayString *)string;
- (NSRange)displayRangeForSourceRange:(NSRange)range;
- (RECN)record;
- (int)recordsConsumed;
- (void)setEntry:(NSAttributedString *)text;
- (NSAttributedString *)entry;
- (void)setEntryLength:(NSUInteger)length;
- (NSUInteger)entryLength;
- (void)setLineCount:(NSUInteger)count;
- (NSUInteger)lineCount;
- (void)setHeight:(float)height;
- (float)height;
- (NSMutableArray *)lineRanges;
- (NSMutableArray *)lineHeights;
@end

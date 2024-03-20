//
//  IRAttributedDisplayString.m
//  Cindex
//
//  Created by PL on 4/9/05.
//  Copyright 2005 Indexing Research. All rights reserved.
//

#import "IRAttributedDisplayString.h"

@interface IRAttributedDisplayString () {
	IRDisplayString * _recordString;
}
@end

// retrieves all its attributes from the underlying IRDisplayString

@implementation IRAttributedDisplayString
- (id)initWithIRIndex:(IRIndexDocument *)doc paragraphs:paragraphs record:(RECN)record {
	if (self = [super init]) {
		_recordString = [[IRDisplayString alloc] initWithIRIndex:doc paragraphs:paragraphs record:record];
	}
	return self;
}
- (void)dealloc {
}
- (NSString *)string {
	return _recordString;
}
- (NSDictionary *)attributesAtIndex:(NSUInteger)index effectiveRange:(NSRangePointer)aRange {
	return [_recordString attributesAtIndex:index effectiveRange:aRange];
}
- (NSDictionary *)attributesAtIndex:(NSUInteger)index longestEffectiveRange:(NSRangePointer)aRange inRange:(NSRange)rangeLimit{
	return [_recordString attributesAtIndex:index longestEffectiveRange:aRange inRange:rangeLimit];
}
- (RECN)record {
	return [_recordString record];
}
- (ENTRYINFO *)entryInformation {
	return [_recordString entryInformation];
}
@end

//
//  StringCategories.m
//  Cindex
//
//  Created by PL on 1/24/05.
//  Copyright 2005 Indexing Research. All rights reserved.
//

#import "StringCategories.h"
#import "IRIndexDocument.h"
#import "utime.h"

@implementation NSString (StringCategories)

+ (NSString *)stringFromCinTime:(time_c)ctime {
	time_t seconds = ctime;	// set up time_t
	char tstring[256];
	
	strftime(tstring, 100, "%b %d %Y %H:%M", localtime(&seconds));
	return [NSString stringWithUTF8String:tstring];
}
- (int)paragraphBreaksForRange:(NSRange)trange {
	int count = 0;
	
	if (trange.length) {	// if not empty selection
		NSRange prange = NSMakeRange(trange.location,0);
		unsigned int length = NSMaxRange(trange);
		
		for (count = 0; prange.location < length; count++) {
			prange = [self paragraphRangeForRange:prange];
			prange = NSMakeRange(NSMaxRange(prange),0);
		}
		if (length && [self characterAtIndex:length-1] != '\n')	// if don't end on break
			count--;
	}
	return count;
}
- (int)paragraphBreaks {
	return [self paragraphBreaksForRange:NSMakeRange(0,[self length])];
}
- (NSArray *)paragraphRanges {
    NSMutableArray	*result = [NSMutableArray array];
	unsigned int length = [self length];
	
	if (length)	{
		NSRange prange = NSMakeRange(0,0);
		while (prange.location < length) {
			prange = [self paragraphRangeForRange:prange];
			[result addObject:[NSValue valueWithRange:prange]];
			prange = NSMakeRange(NSMaxRange(prange),0);
		}
		if ([self characterAtIndex:length-1] == '\n') 	// if last char is newline; must have empty page field
			[result addObject:[NSValue valueWithRange:NSMakeRange(length,0)]];
	}
	else
		[NSException raise:IRDocumentException format:@"Invalid character index"]; 
	return result;
}
- (NSComparisonResult)compareEvaluateNumbers:(NSString *)aString {
	return [self compare:aString options:NSCaseInsensitiveSearch|NSNumericSearch range:NSMakeRange(0,[self length])];
}
- (NSDate *)dateValue {
	UDate date = time_dateValue([self UTF8String]);
//	NSLog(@"Resolved Date: %s",time_stringFromDate(date));
	if (date > 0)
		return [NSDate dateWithTimeIntervalSince1970:date/1000];
	return nil;
}
@end

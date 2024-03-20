//
//  StringCategories.h
//  Cindex
//
//  Created by PL on 1/24/05.
//  Copyright 2005 Indexing Research. All rights reserved.
//


@interface NSString (StringCategories)
+ (NSString *)stringFromCinTime:(time_c)ctime;
- (int)paragraphBreaks;
- (int)paragraphBreaksForRange:(NSRange)trange;
- (NSArray *)paragraphRanges;
- (NSComparisonResult)compareEvaluateNumbers:(NSString *)aString;
- (NSDate *)dateValue;

@end

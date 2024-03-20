//
//  IRAbbreviations.h
//  Cindex
//
//  Created by PL on 3/26/05.
//  Copyright 2005 Indexing Research. All rights reserved.
//


@interface IRAbbreviations : NSDocument {
	NSMutableDictionary * _currentDictionary;
}
+ (void)setAbbreviations:(IRAbbreviations *)abbrevs;
+ (IRAbbreviations *)abbreviations;
- (void)setDictionary:(NSMutableDictionary *)dict;
- (NSMutableDictionary *)dictionary;
@end

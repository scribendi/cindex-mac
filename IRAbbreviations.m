//
//  IRAbbreviations.m
//  Cindex
//
//  Created by PL on 3/26/05.
//  Copyright 2005 Indexing Research. All rights reserved.
//

#import "IRAbbreviations.h"

IRAbbreviations * _currentAbbreviations;

@interface IRAbbreviations (PrivateMethods)
;
@end
@implementation IRAbbreviations
+ (void)setAbbreviations:(IRAbbreviations *)abbrevs {
	_currentAbbreviations = abbrevs;
}
+ (IRAbbreviations *)abbreviations {
	if (_currentAbbreviations) {
		[IRAbbreviations setAbbreviations:[[IRAbbreviations alloc] init]];
	}
	return _currentAbbreviations;
}
- (id)init {
    if (self = [super init])
		[self setDictionary:[[NSMutableDictionary alloc] init]];
	return self;	
}
- (void)dealloc {
	[self setDictionary:nil];
}
- (NSData *)dataRepresentationOfType:(NSString *)type {
	return [NSKeyedArchiver archivedDataWithRootObject:_currentAbbreviations];
}
- (BOOL)loadDataRepresentation:(NSData *)data ofType:(NSString *)type {
	[IRAbbreviations setAbbreviations:[NSKeyedUnarchiver unarchiveObjectWithData:data]];
    return YES;
}
- (void)setDictionary:(NSMutableDictionary *)abbrevs {
	_currentDictionary = abbrevs;
}
- (NSMutableDictionary *)dictionary {
	return _currentDictionary;
}
@end

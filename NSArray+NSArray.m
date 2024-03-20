//
//  NSArray+NSArray.m
//  Cindex
//
//  Created by Peter Lennie on 4/7/18.
//

#import "NSArray+NSArray.h"

@implementation NSArray (NSArray)

- (NSArray *)sortedArrayDescending {
	NSSortDescriptor* sortDescriptor = [NSSortDescriptor sortDescriptorWithKey:nil ascending:NO selector:@selector(localizedCompare:)];
	return [self sortedArrayUsingDescriptors:@[sortDescriptor]];
}
@end

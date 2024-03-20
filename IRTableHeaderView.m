//
//  IRTableHeaderView.m
//  Cindex
//
//  Created by Peter Lennie on 4/8/18.
//

#import "IRTableHeaderView.h"

@implementation IRTableHeaderView

- (void)mouseDown:(NSEvent *)theEvent	{
	if (self.enabled)
		[super mouseDown:theEvent];
}
@end

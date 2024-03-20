//
//  SpellTextField.m
//  Cindex
//
//  Created by PL on 12/9/05.
//  Copyright 2005 Indexing Research. All rights reserved.
//

#import "SpellTextField.h"
#import "SpellController.h"

@implementation SpellTextField
- (void)mouseDown:(NSEvent *)theEvent	{
	[(SpellController *)[self delegate] setDefaultChangedWord];
}
@end

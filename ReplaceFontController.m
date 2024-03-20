//
//  ReplaceFontController.m
//  Cindex
//
//  Created by PL on 3/6/05.
//  Copyright 2005 Indexing Research. All rights reserved.
//

#import "ReplaceFontController.h"
#import "IRIndexDocumentController.h"


@implementation ReplaceFontController
- (id)init	{
    self = [super initWithWindowNibName:@"ReplaceFontController"];
    return self;
}
- (void)awakeFromNib {
	[super awakeFromNib];
	[fonts removeAllItems];
	[fonts addItemsWithTitles:[IRdc fonts]];
}
- (void)showWindow:(id)sender {
	_nameptr = (char *)[sender pointerValue];
	[NSApp runModalForWindow:[self window]]; 
}
- (IBAction)closePanel:(id)sender {    
	if ([sender tag] == OKTAG)	{
		if (![[self window] makeFirstResponder:[self window]])	// if bad text somewhere
			return;
		strcpy(_nameptr,(char *)[[fonts titleOfSelectedItem] UTF8String]);
	}
	[self close];
	[NSApp stopModal]; 
}
@end

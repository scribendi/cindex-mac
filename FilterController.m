//
//  FilterController.m
//  Cindex
//
//  Created by Peter Lennie on 6/7/08.
//  Copyright 2008 Indexing Research. All rights reserved.
//

#import "FilterController.h"


@implementation FilterController
- (void)awakeFromNib {
	[super awakeFromNib];
	int count;
	
	FF = [[self document] iIndex];
	[enablefilter setState:FF->head.privpars.filter.on];
	for (count = 0; count < FLAGLIMIT; count++)
		[[labels cellWithTag:count] setState:FF->head.privpars.filter.label[count]];
}
- (IBAction)showHelp:(id)sender {
	[[NSHelpManager sharedHelpManager] openHelpAnchor:@"hiding0_Anchor-14210" inBook:@"Cindex 4.2.5 Help"];
}
- (IBAction)closeSheet:(id)sender {    
	if ([sender tag] == OKTAG)	{
		int count;
		
		FF->head.privpars.filter.on = [enablefilter state];
		for (count = 0; count < FLAGLIMIT; count++)
			FF->head.privpars.filter.label[count] = [[labels cellWithTag:count] state];
		[[self document] redisplay:0 mode:0];	// redisplay all records
	}
	[self.window.sheetParent endSheet:self.window returnCode:[sender tag]];
}

@end

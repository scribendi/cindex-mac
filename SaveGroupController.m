//
//  SaveGroupController.m
//  Cindex
//
//  Created by PL on 1/9/05.
//  Copyright 2005 Indexing Research. All rights reserved.
//

#import "group.h"
#import "SaveGroupController.h"
#import "IRIndexDocument.h"
#import "cindexmenuitems.h"

@implementation SaveGroupController
- (void)awakeFromNib {
	[super awakeFromNib];
	FF = [[self document] iIndex];
}
- (IBAction)closeSheet:(id)sender {
	if ([sender tag] == OKTAG)	{
		NSString * gname = [name stringValue];
		GROUPHANDLE gh = FF->lastfile;
		
		if (grp_make(FF,gh, (char *)[gname UTF8String], FALSE))	{	/* converts handle to permanent group */
			grp_dispose(gh);			/* get rid of this copy of group (will reopen officially) */
			
			[[self document] setGroupMenu:[[self document] groupMenu:NO]];	// rebuild menu
			[[self document] installGroupMenu];	// install it
			[[self document] setViewType:VIEW_GROUP name:gname];
			FF->lastfile = NULL;	// now have no temporary group
		}
		else		/* some error */
			return;
	}
	[self.window.sheetParent endSheet:self.window returnCode:[sender tag]];
}
@end

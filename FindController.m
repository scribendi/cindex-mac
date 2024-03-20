//
//  FindController.m
//  Cindex
//
//  Created by PL on 2/19/05.
//  Copyright 2005 Indexing Research. All rights reserved.
//

#import "IRIndexDocumentController.h"
#import "IRIndexDocWController.h"
#import "FindController.h"
#import "ReplaceController.h"
#import "cindexmenuitems.h"
#import "commandutils.h"
#import "type.h"
#import "records.h"
#import "search.h"
#import "group.h"
#import "strings_c.h"

NSString * IRWindowFind = @"FindWindow";

@interface FindController () {
	
}
@end

@implementation FindController
- (id)init	{
    self = [super initWithWindowNibName:@"FindController"];
    return self;
}
- (void)awakeFromNib {
	[super awakeFromNib];
    [[self window] setFrameAutosaveName:IRWindowFind];
	[self stop:self];
}
- (void)showWindow:(id)sender {
	NSPanel * replacePanel = [IRdc replacePanel];
	
	if (replacePanel && [replacePanel isVisible])	{	// if have visible replace panel
		NSRect frect = [replacePanel frame];
		
		frect.origin.y += frect.size.height;	// make top left point
		[[self window] setFrameTopLeftPoint:frect.origin];
		[comboforset(0) setStringValue:[(SearchController *)[replacePanel delegate] searchString]];
	}
	[comboforset(0) selectText:self];
	[super showWindow:sender];
	[replacePanel orderOut:nil];	// hide any replace panel
}
-(void)enableLocalButtons:(BOOL)enable {
	if ([self checkFindSettings]) {
		[findbutton setEnabled:YES];
		[findallbutton setEnabled:[self.currentDocument recordWindowController] ? NO : YES];
	}
	else {
		[findbutton setEnabled:NO];
		[findallbutton setEnabled:NO];
	}
}
- (IBAction)showHelp:(id)sender {
	[[NSHelpManager sharedHelpManager] openHelpAnchor:@"fnd0_Anchor-14210" inBook:@"Cindex 4.2.5 Help"];
}
- (IBAction)findall:(id)sender {
	if ([self checkFindValid]) {
		GROUPHANDLE gh = grp_startgroup(FF); 	/* initialize a group */
		if (gh)	{
			int count;
			
			gh->lg = lg;				/* load current search pars */
			for (count = 0; count < lg.size; count++)	/* for all possible arrays */
				lg.lsarray[count].auxptr = NULL;		/* empty pointer (mem is freed by grp) */
			if (grp_buildfromsearch(FF,&gh))	{	/* make temporary group */
				grp_installtemp(FF,gh);
				[self.currentDocument setViewType:VIEW_TEMP name:nil];
				[[self window] performClose:self];
			}
			else{
				grp_dispose(gh);
				errorSheet(self.window,RECNOTFOUNDERR, WARN);
			}
		}
		[self setNewFind];	// always re-initialize after find all
	}
}
- (IBAction)stop:(id)sender {
	[super stop:sender];
	[userid setStringValue:@""];
	[backward setState:NO];
	[self sizeForSets:1];
	[self setNewFind];
}
@end


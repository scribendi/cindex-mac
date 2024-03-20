//
//  CompressController.m
//  Cindex
//
//  Created by PL on 1/9/05.
//  Copyright 2005 Indexing Research. All rights reserved.
//

#import "CompressController.h"
#import "IRIndexDocument.h"
#import "sort.h"
#import "commandutils.h"
#import "cindexmenuitems.h"

enum {
	SQ_DELETE = 0,
	SQ_EMPTY,
	SQ_DUPLICATE,
	SQ_GENERATED,
	SQ_COMBINE,
};
@interface CompressController () {
	INDEX * FF;
}
@end

@implementation CompressController
- (void)awakeFromNib {
	[super awakeFromNib];
	FF = [[self document] iIndex];
	SORTPARAMS * sp = &FF->head.sortpars;
#if 0
	short tp = (short)[[NSUserDefaults standardUserDefaults] integerForKey:@"compressParams"];
	if (tp) {	// if have saved state
		[[compressmode cellWithTag:SQ_DELETE] setState:tp&SQDELDEL];
		[[compressmode cellWithTag:SQ_EMPTY] setState:tp&SQDELEMPTY];
		[[compressmode cellWithTag:SQ_DUPLICATE] setState:tp&SQDELDUP];
		[[compressmode cellWithTag:SQ_GENERATED] setState:tp&SQDELGEN];
		[[compressmode cellWithTag:SQ_COMBINE] setState:tp&SQCOMBINE];
		[ignorelabel  setState:tp&SQIGNORELABEL];
	}
#endif
	if (sp->fieldorder[0] == PAGEINDEX)	{		// if page sort
		[[compressmode cellWithTag:SQ_DUPLICATE] setState:NO];
		[[compressmode cellWithTag:SQ_DUPLICATE] setEnabled:NO];
		[[compressmode cellWithTag:SQ_COMBINE] setEnabled:NO];
	}
}
- (IBAction)showHelp:(id)sender {
	[[NSHelpManager sharedHelpManager] openHelpAnchor:@"compress0_Anchor-14210" inBook:@"Cindex 4.2.5 Help"];
}
- (void)windowDidUpdate:(NSNotification *)aNotification {
	if ([[compressmode cellWithTag:SQ_COMBINE] state])
		[ignorelabel setEnabled:YES];
	else {
		[ignorelabel setState:NO];
		[ignorelabel setEnabled:NO];
	}
}
- (IBAction)closeSheet:(id)sender {    
	if ([sender tag] == OKTAG)	{
		short flags = 0;
		
		if ([[compressmode cellWithTag:SQ_DELETE] state])
			flags |= SQDELDEL;
		if ([[compressmode cellWithTag:SQ_EMPTY] state])
			flags |= SQDELEMPTY;
		if ([[compressmode cellWithTag:SQ_DUPLICATE] state])
			flags |= SQDELDUP;
		if ([[compressmode cellWithTag:SQ_GENERATED] state])
			flags |= SQDELGEN;
		if ([[compressmode cellWithTag:SQ_COMBINE] state])
			flags |= SQCOMBINE;
		if ([ignorelabel state])
			flags |= SQIGNORELABEL;
//		[[NSUserDefaults standardUserDefaults] setInteger:flags forKey:@"compressParams"];
		 NSAlert * warning = criticalAlert(SQUEEZEWARNING);
		[warning beginSheetModalForWindow:[self.document windowForSheet] completionHandler:^(NSInteger result) {
			if (result == NSAlertFirstButtonReturn){
				short tsort = self->FF->head.sortpars.ison;	/* get sort state */
				
				[[NSNotificationCenter defaultCenter] postNotificationName:NOTE_GLOBALLYCHANGING object:[self document]];
				if (flags&(SQDELDUP|SQCOMBINE))
					self->FF->head.sortpars.ison = TRUE;	/* make sure sort on if removing dup or consolidating */
				sort_squeeze(self->FF, flags);
				self->FF->head.sortpars.ison = tsort;
				[[self document] setViewType:VIEW_ALL name:nil];
				[[self document] setGroupMenu:[[self document] groupMenu:NO]];	// rebuild menu after invalidating groups
			}
		}];
	}
	[self.window.sheetParent endSheet:self.window returnCode:[sender tag]];
}
@end

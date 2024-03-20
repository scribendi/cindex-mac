//
//  GoToController.m
//  Cindex
//
//  Created by PL on 1/9/05.
//  Copyright Indexing Research. All rights reserved.
//

#import "GoToController.h"
#import "commandutils.h"
#import "IRIndexDocument.h"
#import "IRIndexDocWController.h"
#import "sort.h"

@implementation GoToController
- (void)awakeFromNib {
	[super awakeFromNib];
	NSInteger nitems;
	
	FF = [[self document] iIndex];
	[gotostring addItemsWithObjectValues:((IRIndexDocument *)self.document).gotoitems];
	nitems = [gotostring numberOfItems];
	if (nitems) {
		[gotostring selectItemAtIndex:0];
		[gotostring setObjectValue:[gotostring objectValueOfSelectedItem]];
	}
	[gotostring setNumberOfVisibleItems: nitems < 10 ? nitems : 10];
	[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(_showpage:) name:NOTE_PAGEFORMATTED object:[self document]];
	[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(updateProgress:) name:NOTE_PROGRESSCHANGED object:nil];
}
- (void)dealloc {
	[[NSNotificationCenter defaultCenter] removeObserver:self];
}
- (void)updateProgress:(NSNotification *)note {
	indicator.doubleValue = [[note object] doubleValue];
}
- (void)_showpage:(NSNotification *)note {
	[pagecount setStringValue:[NSString stringWithFormat:@"%@",[[note userInfo] objectForKey:@"Page"]]];
	[pagecount display];
}
- (IBAction)showHelp:(id)sender {
	[[NSHelpManager sharedHelpManager] openHelpAnchor:@"goto0_Anchor-14210" inBook:@"Cindex 4.2.5 Help"];
}
- (IBAction)closeSheet:(id)sender {    
	if ([sender tag] == OKTAG)	{
		NSString * gstring;
		
		if (![[self window] makeFirstResponder:[self window]])	// if bad text somewhere
			return;
		gstring = [gotostring stringValue];
		[gotostring removeItemWithObjectValue:gstring];		// remove it if it's in list already
		[gotostring insertItemWithObjectValue:gstring atIndex:0];		// add search text to top of combo list
		((IRIndexDocument *)self.document).gotoitems = [[gotostring objectValues] copy];
		if ([gototype selectedColumn])	{	// want page
			RECORD * recptr = sort_top(FF);
			if (recptr)	{
				memset(&FF->pf,0,sizeof(PRINTFORMAT));		/* clear format info struct */
				FF->pf.pagenum = FF->head.formpars.pf.firstpage;
				FF->pf.first = [gotostring intValue];
				FF->pf.last = [gotostring intValue];
				FF->pf.firstrec = recptr->num;
				FF->pf.lastrec = UINT_MAX;
				if (![[self document] formPageImages])	// if canceled
					[self.window.sheetParent endSheet:self.window returnCode:[sender tag]];
			}
		}
		else
			FF->pf.rnum = com_findrecord(FF,(char *)[[gotostring stringValue] UTF8String],FALSE,WARN);
		if (FF->pf.rnum)		{	// if found record
			if ([[self document] canCloseActiveRecord])
				[[self document] selectRecord:FF->pf.rnum range:NSMakeRange(0,0)];
		}
		else
			return;
	}
	[self.window.sheetParent endSheet:self.window returnCode:[sender tag]];
	[(IRIndexDocWController *)[[self document] mainWindowController] displayError:nil];
}
- (BOOL)control:(NSControl *)control textShouldEndEditing:(NSText *)editor {
	if (control == gotostring)
		return [[gotostring stringValue] length] > 0;
	return YES;
}
@end

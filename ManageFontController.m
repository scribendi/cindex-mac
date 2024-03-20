//
//  ManageFontController.m
//  Cindex
//
//  Created by PL on 1/10/05.
//  Copyright 2005 Indexing Research. All rights reserved.
//

#import "ManageFontController.h"
#import "IRIndexDocumentController.h"
#import "IRIndexDocument.h"
#import "type.h"
#import "commandutils.h"

static int countfonts(FONTMAP * fm);		// counts # fonts in map

@interface ManageFontController () {
	INDEX * FF;
	FONTMAP _fm[FONTLIMIT];
	short _farray[FONTLIMIT];
}
@end

@implementation ManageFontController
+ (BOOL)manageFonts:(FONTMAP *)fm{
	ManageFontController * fcontroller = [[ManageFontController alloc] initWithWindowNibName:@"ManageFontController"];
	fcontroller.fmp = fm;
	return [NSApp runModalForWindow:[fcontroller window]] == OKTAG;
}
- (void)awakeFromNib {
	[super awakeFromNib];
	NSArray * farray = [IRdc fonts];
	BOOL allfontsused = YES;	// assume surplusfonts
	
	if (self.document) {	// if called from document
		FF = [self.document iIndex];
		self.fmp = FF->head.fm;
		allfontsused = type_scanfonts(FF,_farray);
		[check setEnabled:!allfontsused && !FF->readonly];	// enabled cleanup if there are unused fonts
	}
	else	// hidden while handling check on opening
		[check setHidden:YES];
	memcpy(_fm,self.fmp,sizeof(_fm));
	NSComboBoxCell *pcell = [[table tableColumnWithIdentifier:@"pref"] dataCell];
	NSPopUpButtonCell *acell = [[table tableColumnWithIdentifier:@"alt"] dataCell];

	[pcell addItemsWithObjectValues:farray];
	[acell addItemsWithTitles:farray];
//	[check setHidden:countfonts(_fm) <= VOLATILEFONTS || !FF || FF->readonly || allfontsused];	// don't display fontcheck during index opening checks
}
- (IBAction)showHelp:(id)sender {
	[[NSHelpManager sharedHelpManager] openHelpAnchor:@"font0_Anchor-14210" inBook:@"Cindex 4.2.5 Help"];
}
- (IBAction)checkUse:(id)sender {
//	if (!type_scanfonts(FF,_farray)) {		// if not all used
//		if (sendwarning(FONTGAPWARNING))	{	// if want to adjust
			memcpy(self.fmp,_fm,sizeof(_fm));	// copy current map
			type_adjustfonts(FF,_farray);
			memcpy(_fm,self.fmp,sizeof(_fm));	// get new copy of map
			[table reloadData];
			[cancel setEnabled:NO];		// not undoable
			[check setEnabled:NO];
//		}
//	}
//	else
//		sendinfo(ALLFONTSUSED);
}
- (IBAction)closeSheet:(id)sender {    
	if ([sender tag] == OKTAG)	{
		int index;
		if (![[self window] makeFirstResponder:[self window]])
			return;
		for (index = 0;*_fm[index].pname;index++) {	// check that every font has alternate
			if (!*_fm[index].name)	{	// if missing alternate
				[table selectRowIndexes:[NSIndexSet indexSetWithIndex:index] byExtendingSelection:NO];
				NSBeep();
				return;
			}
		}
		memcpy(self.fmp,_fm,sizeof(_fm));
		[[NSNotificationCenter defaultCenter] postNotificationName:NOTE_FONTSCHANGED object:[self document]];
	}
	if ([self document])
		[self.window.sheetParent endSheet:self.window returnCode:[sender tag]];
	else {
		[self close];
		[NSApp stopModalWithCode:[sender tag]]; 
	}
}
#if 0
- (BOOL)tableView:(NSTableView *)aTableView shouldEditTableColumn:(NSTableColumn *)aTableColumn row:(int)rowIndex	{
	return rowIndex != 1;		// not symbol entry
}
#endif
- (NSInteger)numberOfRowsInTableView:(NSTableView *)tableView	{
	return countfonts(_fm);
}
- (id)tableView:(NSTableView *)tableView objectValueForTableColumn:(NSTableColumn *)tableColumn row:(NSInteger)row	{
	if ([[tableColumn identifier] isEqualToString:@"pref"]) {
		return [NSString stringWithCString:_fm[row].pname encoding:NSUTF8StringEncoding];
	}
	else {
		NSPopUpButtonCell *acell = [tableColumn dataCell];
		return [NSNumber numberWithLong:[acell indexOfItemWithTitle:[NSString stringWithCString:_fm[row].name encoding:NSUTF8StringEncoding]]];
	}
}
- (void)tableView:(NSTableView *)tableView setObjectValue:(id)object forTableColumn:(NSTableColumn *)tableColumn row:(NSInteger)row	{
	if ([[tableColumn identifier] isEqualToString:@"pref"])	{	// object is text string
		if (object)	{	// for some reason can be called with no object
			strcpy(_fm[row].pname,(char *)[object UTF8String]);
			if ([[[tableView tableColumnWithIdentifier:@"alt"] dataCell] indexOfItemWithTitle:object] >= 0)		{	// if this is possible alternate
				strcpy(_fm[row].name,_fm[row].pname);		// make it also the alternate
				[tableView reloadData];	// force update alternate display
			}
		}
	}
	else {		// object is index of selected item
		NSPopUpButtonCell * acell = [tableColumn dataCell];
		strcpy(_fm[row].name,[[acell itemTitleAtIndex:[object intValue]] UTF8String]);
	}
}
/********************************************************************************/
static int countfonts(FONTMAP * fm)		// counts # fonts in map

{
	int count;
	
	for (count = 0; count < FONTLIMIT; count++) {	// find how many fonts we should have
		if (!*fm[count].pname)
			break;
	}
	return count;
}
@end

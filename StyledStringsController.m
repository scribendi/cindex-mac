//
//  StyledStringsController.m
//  Cindex
//
//  Created by PL on 1/9/05.
//  Copyright 2005 Indexing Research. All rights reserved.
//

#import "IRIndexDocument.h"
#import "StyledStringsController.h"
#import "strings_c.h"
#import "index.h"

char newstring[] = {FX_OFF,0};

@interface StyledStringsController () {
	id activeText;
}
- (void)_showStyles:(NSInteger)index;
- (char *)_recoverString:(NSInteger)index;
- (void)_removeString:(NSInteger)index;
- (void)_updateStyles:(NSInteger)index;
- (void)_addString:(char *)string;
@end

@implementation StyledStringsController
- (id)init	{
    self = [super initWithWindowNibName:@"StyledStringsController"];
    return self;
}
- (void)awakeFromNib {
	[super awakeFromNib];
	if ([self document])
		_stringPtr = [[self document] iIndex]->head.stylestrings;
	else
		_stringPtr = g_prefs.stylestrings;
	str_xcpy(_string,_stringPtr);	// copy string
	[self _showStyles:[table selectedRow]];
}
- (IBAction)showHelp:(id)sender {
	[[NSHelpManager sharedHelpManager] openHelpAnchor:@"styledstring0_Anchor-14210" inBook:@"Cindex 4.2.5 Help"];
}
- (void)windowDidUpdate:(NSNotification *)aNotification {
	[segs setEnabled:([table selectedRow] >= 0) forSegment:1];
}
- (void)_showStyles:(NSInteger)index {
	if (index >= 0) {
		char * sptr = str_xatindex(_string,index);
		int pos = 0;
		
		[[style cellWithTag:0] setState:*sptr&FX_BOLD];
		[[style cellWithTag:1] setState:*sptr&FX_ITAL];
		[[style cellWithTag:2] setState:*sptr&FX_ULINE];
		[[style cellWithTag:3] setState:*sptr&FX_SMALL];
		if (*sptr&FX_SUPER)
			pos = 1;
		else if (*sptr&FX_SUB)
			pos = 2;
		[offset selectCellWithTag:pos];
//		[deletebutton setEnabled:YES];
		[style setEnabled:YES];
		[offset setEnabled:YES];
	}
	else {
//		[deletebutton setEnabled:NO];
		[style setEnabled:NO];
		[offset setEnabled:NO];
	}
}
- (void)_updateStyles:(NSInteger)index {
	if (index >= 0)	{	// if have existing item
		char * oldptr = str_xatindex(_string,index);
		char * newptr = [self _recoverString:index];
		*oldptr = *newptr;	// set style codes
	}
}
- (char *)_recoverString:(NSInteger)index {
	if (index >= 0)	{
		*_tstring = FX_OFF;		// special use of off code so that style attribute never 0
		if ([[style cellWithTag:0] state])
			*_tstring |= FX_BOLD;
		if ([[style cellWithTag:1] state])
			*_tstring |= FX_ITAL;
		if ([[style cellWithTag:2] state])
			*_tstring |= FX_ULINE;
		if ([[style cellWithTag:3] state])
			*_tstring |= FX_SMALL;
		if ([[offset selectedCell] tag] == 1)
			*_tstring |= FX_SUPER;
		if ([[offset selectedCell] tag] == 2)
			*_tstring |= FX_SUB;
		strcpy(_tstring+1,[[table stringValue] UTF8String]);
	}
	return _tstring;
}
- (void)_removeString:(NSInteger)index {
	if (index >= 0)	{	// if have existing item
		char * rptr = str_xatindex(_string,index);
		NSInteger slen = strlen(rptr)+1;
		
		str_xshift(rptr+slen,-slen);
		[table reloadData];
	}
}
- (void)_addString:(char *)string {
	char * iptr;
	for (iptr = _string; *iptr != EOCS; iptr += strlen(iptr)+1)	{
		if (strcmp(string+1,iptr+1) < 0) // if insertion pt
			break;
	}
	str_xshift(iptr,strlen(string)+1);	// make room
	strcpy(iptr,string);
	[table reloadData];
}
- (IBAction)doSetAction:(id)sender {
	[self _recoverString:[table selectedRow]];
	[self _updateStyles:[table selectedRow]];
}
- (IBAction)manageString:(id)sender {
	if ([sender selectedSegment] == 0)	{	// adding
		[self _addString:newstring];
		[table editColumn:0 row:0 withEvent:nil select:YES];
		[table selectRowIndexes:[NSIndexSet indexSetWithIndex:0] byExtendingSelection:NO];
	}
	else if ([sender selectedSegment] == 1)	{
		[self _removeString:[table selectedRow]];
	}
}
- (IBAction)closePanel:(id)sender {
	if ([sender tag] == OKTAG)	{
		if (![[self window] makeFirstResponder:[self window]])	// if bad text somewhere
			return;
		for (int xindex = str_xcount(_string)-1; xindex >= 0; xindex--) {	// remove any strings that are empty or have only the code byte set
			char * xptr = str_xatindex(_string,xindex);
			NSInteger len = strlen(xptr);
			if (len <= 1) {
				len++;
				str_xshift(xptr+len,-len);
			}
		}
//		str_xstrip(_string, 0);
		str_xcpy(_stringPtr,_string);
		[[self document] buildStyledStrings];
		[[self document] reformat];
		index_markdirty([[self document] iIndex]);
	}
	if ([self document])
		[self.window.sheetParent endSheet:self.window returnCode:[sender tag]];
	else {
		[self close];
		[NSApp stopModal]; 
	}
}
- (BOOL)control:(NSControl *)control textShouldBeginEditing:(NSText *)fieldEditor {
	if (control == table)
		activeText = control.objectValue;
	return YES;
}
- (BOOL)control:(NSControl *)control textView:(NSTextView *)textView doCommandBySelector:(SEL)command	{
	if (command == @selector(cancelOperation:) || command == @selector(insertNewline:)) {
		if (command == @selector(cancelOperation:) && activeText)
			control.objectValue = activeText;
		[[self window] makeFirstResponder:table];	 // force close of editor
		return YES;
	}
	if (control == table && (command == @selector(insertTab:) || command == @selector(insertBacktab:))) {
		NSInteger editedRow = [table editedRow];
		if (command == @selector(insertBacktab:))
			editedRow--;
		else if (command == @selector(insertTab:))
			editedRow++;
		if (editedRow >= table.numberOfRows)
			editedRow = 0;
		else if (editedRow < 0)
			editedRow = table.numberOfRows-1;
		[table editColumn:0 row:editedRow withEvent:nil select:YES];
		return YES;
	}
	return NO;
}
- (void)controlTextDidEndEditing:(NSNotification *)aNotification	{
	activeText = nil;
}
- (int)numberOfRowsInTableView:(NSTableView *)tableView  {
	return str_xcount(_string);
}
- (BOOL)tableView:(NSTableView *)aTableView shouldEditTableColumn:(NSTableColumn *)aTableColumn row:(int)rowIndex {
	[table deselectAll:nil];
	return YES;
}
- (void)tableView:(NSTableView *)tableView willDisplayCell:(id)aCell forTableColumn:(NSTableColumn *)tableColumn row:(NSInteger)row {
}
- (void)tableView:(NSTableView *)tableView setObjectValue:(id)anObject forTableColumn:(NSTableColumn *)tableColumn row:(NSInteger)row {
	char * newptr = [self _recoverString:row];

	[self _removeString:row];
	[self _addString:newptr];
}
- (id)tableView:(NSTableView *)tableView objectValueForTableColumn:(NSTableColumn *)tableColumn row:(int)row {
	char * sptr = str_xatindex(_string,row);
	return [NSString stringWithCString:sptr+1 encoding:NSUTF8StringEncoding];
}
- (void)tableViewSelectionDidChange:(NSNotification *)aNotification {
	NSTableView * tv = [aNotification object];
	[self _showStyles:[tv selectedRow]];
}
- (void)controlTextDidChange:(NSNotification *)note	{
	NSControl * control = [note object];
	
	if (control == table)	{
		NSInteger index = [table selectedRow];
		NSInteger nlength = strlen([[control stringValue] UTF8String])+1;
		NSInteger olength = index >= 0 ? strlen(str_xatindex(_string,index)) : 0;
		checktextfield(control,STYLESTRINGLEN-(str_xlen(_string)-olength+nlength)-1);
	}
}
@end

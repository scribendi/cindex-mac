//
//  FunctionkeyController.m
//  Cindex
//
//  Created by PL on 10/12/05.
//  Copyright 2005 Indexing Research. All rights reserved.
//

#import "IRIndexDocumentController.h"
#import "IRIndexDocument.h"
#import "FunctionkeyController.h"
#import "cindexmenuitems.h"
#import "AttributedStringCategories.h"
#import "IRTableHeaderView.h"
#import "StringCategories.h"

NSString * IRWindowFunctionkey = @"FunctionkeyWindow";
FunctionkeyController * fkc;

@interface FunctionkeyController () {
	id activeText;
}
- (void)_setSortedArray:(NSArray *)sarray;
- (void)_setDictionary:(NSMutableDictionary *)dic;
- (void)tableView:(NSTableView *)tableView sortDescriptorsDidChange:(NSArray *)oldDescriptors;
@end

@implementation FunctionkeyController
+ (void)show {
	fkc = [[FunctionkeyController alloc] initWithWindowNibName:@"FunctionkeyController"];
	[fkc showWindow:nil];
}
- (id)init	{
    self = [super initWithWindowNibName:@"FunctionkeyController"];
    return self;
}
-(void)dealloc {
	[self _setSortedArray:nil];
	[self _setDictionary:nil];
}
- (void)awakeFromNib {
	[super awakeFromNib];
	NSTextFieldCell * tcell = [[table tableColumnWithIdentifier:@"_text"] dataCell];
	
	[tcell setAllowsEditingTextAttributes:YES];
	[tcell setTag:1];

	[self setShouldCascadeWindows:NO];
    [[self window] setExcludedFromWindowsMenu:YES];
    [[self window] setFrameAutosaveName:IRWindowFunctionkey];
	NSMutableDictionary * newset = [NSKeyedUnarchiver unarchiveObjectWithData:[[NSUserDefaults standardUserDefaults] objectForKey:CIFunctionKeys]];
	[self _setDictionary:[NSMutableDictionary dictionaryWithDictionary:newset]];
}
- (IBAction)showHelp:(id)sender {
	[[NSHelpManager sharedHelpManager] openHelpAnchor:@"functkey0_Anchor-14210" inBook:@"Cindex 4.2.5 Help"];
}
- (void)windowWillClose:(NSNotification *)aNotification {
	[[self window] makeFirstResponder:table];	// deselect all to force write
	fkc = nil;
}
- (BOOL)validateMenuItem:(NSMenuItem *)mitem {
	NSInteger itemid = [mitem tag];
	
//	NSLog([mitem title]);
	if (itemid == MI_DELETE && [[self window] firstResponder] == table)
		return [table selectedRow] >= 0;
	return YES;
}
- (IBAction)delete:(id)sender {
	[_dictionary removeObjectForKey:[_sortedArray objectAtIndex:[table selectedRow]]];
}
- (void)_setDictionary:(NSMutableDictionary *)dic {
	_dictionary = dic;
	[table setSortDescriptors:[NSArray arrayWithObject:[[table tableColumnWithIdentifier:@"_key"] sortDescriptorPrototype]]];
	[self tableView:table sortDescriptorsDidChange:nil];	// resort array and display
}
- (void)_setSortedArray:(NSArray *)sarray {
	_sortedArray = sarray;
}
- (BOOL)control:(NSControl *)control textShouldBeginEditing:(NSText *)fieldEditor {
	if (control == table)
		activeText = control.objectValue;
	return YES;
}
- (BOOL)control:(NSControl *)control textView:(NSTextView *)textView doCommandBySelector:(SEL)command	{
	((IRTableHeaderView *)[table headerView]).enabled = NO;
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
		[table editColumn:1 row:editedRow withEvent:nil select:YES];
		((IRTableHeaderView *)[table headerView]).enabled = NO;
		return YES;
	}
	return NO;
}
- (void)controlTextDidEndEditing:(NSNotification *)aNotification	{
	((IRTableHeaderView *)[table headerView]).enabled = YES;
	activeText = nil;
}
- (BOOL)tableView:(NSTableView *)aTableView shouldEditTableColumn:(NSTableColumn *)aTableColumn row:(NSInteger)rowIndex {
	if ([[aTableColumn identifier] isEqualToString:@"_text"]) {
		[table deselectAll:nil];
		return YES;
	}
	return NO;
}
- (NSInteger)numberOfRowsInTableView:(NSTableView *)tableView {
	return [_dictionary count];
}
- (id)tableView:(NSTableView *)tableView objectValueForTableColumn:(NSTableColumn *)tableColumn row:(NSInteger)row {
	if ([[tableColumn identifier] isEqualToString:@"_key"]) {
		int index = [[_sortedArray objectAtIndex:row] intValue];
		return [NSString stringWithFormat:@"%@ F%d",[NSString stringWithUTF8String:"⌥"], index+1];		// return key
	}
	else {			// text
		return [_dictionary objectForKey:[_sortedArray objectAtIndex:row]];
	}
}
- (void)tableView:(NSTableView *)tableView setObjectValue:(id)object forTableColumn:(NSTableColumn *)tableColumn row:(NSInteger)row {
	[_dictionary setObject:[object normalizeAttributesWithMap:NULL] forKey:[_sortedArray objectAtIndex:row]];
	[[NSUserDefaults standardUserDefaults] setObject:[NSKeyedArchiver archivedDataWithRootObject:_dictionary] forKey:CIFunctionKeys];	// set new set as default
	[self tableView:table sortDescriptorsDidChange:nil];	// resort array and display
}
- (void)tableView:(NSTableView *)tableView sortDescriptorsDidChange:(NSArray *)oldDescriptors {
	NSSortDescriptor * sd = [[table sortDescriptors] objectAtIndex:0];
	NSArray *sortedarray;
	
	if ([[sd key] isEqualToString:@"_key"])	{ // sort by key
		sortedarray = [[_dictionary allKeys] sortedArrayUsingSelector:[sd selector]];
	}
	else {
		sortedarray = [_dictionary keysSortedByValueUsingSelector:[sd selector]];
	}
	if (![sd ascending])	// if wanted inverse order
		sortedarray = [sortedarray sortedArrayDescending];
	[self _setSortedArray:sortedarray];
	[table reloadData];
}
@end

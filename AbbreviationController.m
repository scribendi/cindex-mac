//
//  AbbreviationController.m
//  Cindex
//
//  Created by PL on 3/26/05.
//  Copyright 2005 Indexing Research. All rights reserved.
//

#import "IRIndexDocumentController.h"
#import "IRIndexDocument.h"
#import "AbbreviationController.h"
#import "cindexmenuitems.h"
#import "AttributedStringCategories.h"
#import "IRTableHeaderView.h"
#import "strings_c.h"
#import "commandutils.h"

NSString * IRWindowAbbreviation = @"AbbreviationWindow";

enum {
	TAG_ABBREV = 0,
	TAG_EXPANSION
};

@interface AbbreviationController () {
	NSMutableDictionary * _dictionary;	// working copy
}
@property(retain)id activeText;
@property(retain)NSString * dicpath;
@property(retain)NSMutableArray * sortedArray;

- (BOOL)_saveAbbreviations;
- (void)_setDictionary:(NSMutableDictionary *)dic forPath:(NSString *)path;
- (void)_setNewFile;
- (void)_startNewAbbreviation:(id)stringObject;
@end

@implementation AbbreviationController

+ (void)showWithExpansion:(NSAttributedString *)text {
	AbbreviationController * abc = [[AbbreviationController alloc] initWithWindowNibName:@"AbbreviationController"];
	abc.activeText = text;
	[NSApp runModalForWindow:[abc window]];
}
- (id)init	{
    self = [super initWithWindowNibName:@"AbbreviationController"];
    return self;
}
-(void)dealloc {
	self.sortedArray = nil;
	self.dicpath = nil;
}
- (void)awakeFromNib {
	[super awakeFromNib];
	NSTextFieldCell * tcell = [[table tableColumnWithIdentifier:@"_expansion"] dataCell];
	
	[tcell setAllowsEditingTextAttributes:YES];
	[self setShouldCascadeWindows:NO];
    [[self window] setExcludedFromWindowsMenu:YES];
    [[self window] setFrameAutosaveName:IRWindowAbbreviation];
	[[self window] makeKeyAndOrderFront:nil];		// needed to ensure that autosaved position is used
	[self _setDictionary:[NSMutableDictionary dictionaryWithDictionary:[IRdc abbreviations]] forPath:[[NSUserDefaults standardUserDefaults] objectForKey:CIAbbreviations]];
	if (_activeText)	// if opened from an expansion entry
		[self manageAbbreviation:_activeText];	// set attributed string
}
- (IBAction)showHelp:(id)sender {
	[[NSHelpManager sharedHelpManager] openHelpAnchor:@"abbrev0_Anchor-14210" inBook:@"Cindex 4.2.5 Help"];
}
- (void)windowDidUpdate:(NSNotification *)aNotification {
	[segs setEnabled:_dictionary ? YES : NO forSegment:0];
	[segs setEnabled:[table selectedRow] >= 0 forSegment:1];
}
- (IBAction)printDocument:(id)sender {
	NSPrintOperation *printop = [NSPrintOperation printOperationWithView:table];
	NSPrintInfo * pinfo = [printop printInfo];
	[pinfo setVerticallyCentered:NO];

	[printop runOperation];
}
- (BOOL)validateMenuItem:(NSMenuItem *)mitem {
	NSInteger itemid = [mitem tag];
	
//	NSLog([mitem title]);
	if (itemid == MI_DELETE)
		return [table selectedRow] >= 0;
	return YES;
}
- (void)newAbbreviation:(id)sender {
	[self _startNewAbbreviation:@""];
}
- (IBAction)delete:(id)sender {
	NSIndexSet * iset = [table selectedRowIndexes];
	NSInteger index = [iset firstIndex];
	
	[[self window] makeFirstResponder:table];	 // force close of editor
	while (index != NSNotFound) {
		[_dictionary removeObjectForKey:[_sortedArray objectAtIndex:index]];
		index = [iset indexGreaterThanIndex:index];
	}
	[self sortAndReload];
}
- (IBAction)newAbbreviations:(id)sender {
	[self closeAbbreviations:nil];
	[self _setNewFile];
}
- (IBAction)closeAbbreviations:(id)sender {
	if ([[self window] makeFirstResponder:table])	 {	// if  good close
		[self _saveAbbreviations];
		[self _setDictionary:[NSMutableDictionary dictionaryWithCapacity:1] forPath:nil];
	}
}
- (IBAction)closePanel:(id)sender {
	if ([sender tag] == OKTAG)		{
		if (![[self window] makeFirstResponder:table] || ![self _saveAbbreviations])	// if have dirty abbreviation
			return;
	}
	[self close];
	[NSApp stopModal];
}
- (IBAction)openAbbreviations:(id)sender {
    NSArray *fileTypes = [NSArray arrayWithObjects:CINAbbrevExtension/*, NSFileTypeForHFSTypeCode(CINAbbrevType) */,nil]; // !! might add old abbrev type
    NSOpenPanel *openpanel = [NSOpenPanel openPanel];
	NSString * defaultDirectory = [[NSUserDefaults standardUserDefaults] stringForKey:CIIndexFolder];
	
	if (defaultDirectory)
		[openpanel setDirectoryURL:[NSURL fileURLWithPath:defaultDirectory isDirectory:YES]];
	[openpanel setAllowedFileTypes:fileTypes];
	[openpanel beginSheetModalForWindow:[self window] completionHandler:^(NSInteger result) {
		if (result == NSFileHandlingPanelOKButton)	{
			NSMutableDictionary * newset = [NSKeyedUnarchiver unarchiveObjectWithData:[NSData dataWithContentsOfURL:[openpanel URL]]];
			
			[self _setDictionary:newset forPath:[[openpanel URL] path]];
		}
		[[NSUserDefaults standardUserDefaults] setObject:[[openpanel directoryURL] path] forKey:CIBackupFolder];
	}];
}
- (IBAction)manageAbbreviation:(id)sender {
	if ([sender isKindOfClass:[NSAttributedString class]] || [sender selectedSegment] == 0)	{	// adding
		id stringobject;

		if ([sender isKindOfClass:[NSAttributedString class]])	// if opened from expansion text
			stringobject = [sender normalizeAttributesWithMap:NULL];	// set attributed string
		else {
			if ([[self window] makeFirstResponder:table]) 	// forces completion of any item currently being edited
				stringobject = @"";
		}
		[self _startNewAbbreviation:stringobject];
	}
	else if ([sender selectedSegment] == 1)		// deleting
		[self delete:nil];
}
- (void)_startNewAbbreviation:(id)stringObject {
	[table setSortDescriptors:[NSArray arrayWithObject:[[table tableColumnWithIdentifier:@"_abbreviation"] sortDescriptorPrototype]]];
	[_dictionary setObject:stringObject forKey:@""];
	[self sortAndReload];
	[table editColumn:0 row:0 withEvent:nil select:YES];
	((IRTableHeaderView *)[table headerView]).enabled = NO;
}
- (void)_setNewFile {
	NSSavePanel *savepanel = [NSSavePanel savePanel];
	
    [savepanel setCanSelectHiddenExtension:YES];
    [savepanel setAllowedFileTypes:[NSArray arrayWithObject:CINAbbrevExtension]];
	[savepanel setNameFieldLabel:@"Create As:"];
	[savepanel setPrompt:@"Create"];
	[savepanel setMessage:@"Create a new set of abbreviations"];
	[savepanel setNameFieldStringValue:[[NSUserDefaults standardUserDefaults] objectForKey:CIAbbreviations] ? @"New Abbreviations" : @"Default Abbreviations"];
	[savepanel beginSheetModalForWindow:[self window] completionHandler:^(NSInteger result) {
		if (result == NSFileHandlingPanelOKButton)	{
			NSDictionary * dic = [NSDictionary dictionaryWithObject:[NSNumber numberWithBool:[savepanel isExtensionHidden]] forKey:NSFileExtensionHidden];
			
			self.dicpath = [[savepanel URL] path];
			[self _saveAbbreviations];
			[[NSFileManager defaultManager] setAttributes:dic ofItemAtPath:self->_dicpath error:nil];
			[[self window] setTitleWithRepresentedFilename:self->_dicpath];
		}
		[[NSUserDefaults standardUserDefaults] setObject:[[savepanel directoryURL] path] forKey:CIIndexFolder];
	}];
}
- (BOOL)_saveAbbreviations {	
	for (id key in [_dictionary allKeys])	{	// for all keys
		if (![key length] || ![[_dictionary objectForKey:key] length])	// if empty key or expansion
			[_dictionary removeObjectForKey:key];
	}
	if ([_dictionary count] && !_dicpath)	// if have defined some abbrev and have no save path
		[self _setNewFile];		// abort this save to get file name
	else	{
		BOOL result = TRUE;
		if (_dicpath) {
			NSData * ddata = [NSKeyedArchiver archivedDataWithRootObject:_dictionary];
			result = [ddata writeToFile:_dicpath atomically:NO];
		}
		if (result) {	// if ok
			[[NSUserDefaults standardUserDefaults] setObject:_dicpath forKey:CIAbbreviations];	// ensure it's current set
			[IRdc setAbbreviations:_dictionary];
			return YES;
		}
	}
	return NO;
}
- (void)_setDictionary:(NSMutableDictionary *)dic forPath:(NSString *)path{
	_dictionary = dic;
	self.dicpath = path;
	if (path)
		[[self window] setTitleWithRepresentedFilename:path];
	else
		[[self window] setTitle:@"Abbreviations"];
	[table setSortDescriptors:[NSArray arrayWithObject:[[table tableColumnWithIdentifier:@"_abbreviation"] sortDescriptorPrototype]]];
}
- (void)sortAndReload {
	NSSortDescriptor * sd = [[table sortDescriptors] objectAtIndex:0];
	NSArray *sortedarray;
	
	if ([[sd key] isEqualToString:@"_abbreviation"]) // sort by abbrev
		sortedarray = [[_dictionary allKeys] sortedArrayUsingSelector:[sd selector]];
	else
		sortedarray = [_dictionary keysSortedByValueUsingSelector:[sd selector]];
	if (![sd ascending])		// if wanted inverse order
		sortedarray = [sortedarray sortedArrayDescending];
	self.sortedArray = [NSMutableArray arrayWithArray: sortedarray];
	[table reloadData];
}
- (BOOL)control:(NSControl *)control textShouldBeginEditing:(NSText *)fieldEditor {
	if (control == table)
		self.activeText = control.objectValue;
	return YES;
}
- (BOOL)control:(NSControl *)control textView:(NSTextView *)textView doCommandBySelector:(SEL)command	{
	((IRTableHeaderView *)[table headerView]).enabled = NO;
	if (command == @selector(cancelOperation:) || command == @selector(insertNewline:)) {
		if (command == @selector(cancelOperation:) && _activeText)
			control.objectValue = _activeText;
		[[self window] makeFirstResponder:table];	 // force close of editor
		return YES;
	}
	if (![[control stringValue] length])	// if leaving empty field
		return YES;
	if (control == table && (command == @selector(insertTab:) || command == @selector(insertBacktab:))) {
		NSInteger editedColumn = [table editedColumn];
		NSInteger editedRow = [table editedRow];
		if (command == @selector(insertBacktab:)) {
			if (editedColumn == TAG_ABBREV) {
				editedColumn = TAG_EXPANSION;
//				editedRow--;
			}
			else {
				editedColumn--;
			}
		}
		else if (command == @selector(insertTab:)) {
			if (editedColumn == TAG_EXPANSION) {
				editedColumn = TAG_ABBREV;
//				editedRow++;
			}
			else {
				editedColumn++;
			}
		}
		if (editedRow >= table.numberOfRows)
			editedRow = 0;
		else if (editedRow < 0)
			editedRow = table.numberOfRows-1;
		if (editedColumn >= table.numberOfColumns)
			editedColumn = 0;
		[table editColumn:editedColumn row:editedRow withEvent:nil select:YES];
		((IRTableHeaderView *)[table headerView]).enabled = NO;
		return YES;
	}
	return NO;
}
- (BOOL)control:(NSControl *)control textShouldEndEditing:(NSText *)editor {
	if (control == table) {
		NSString * abbText = [control stringValue];
		NSInteger length = [abbText length];
		if (!length || length >= MAXREC)
			return NO;
		if ([control selectedTag] == TAG_ABBREV) {	// check permissible chars in abbrev cell
			unichar buff[MAXREC];
			[abbText getCharacters:buff];
			*(buff+length) = 0;
			if (u_strpbrk(buff,abbrev_prefix) || u_strpbrk(buff,abbrev_suffix))		// if ab contains forbidden char
				return NO;
			if (![abbText isEqualToString:_activeText] && [_dictionary objectForKey:abbText])	// if name not same as current && abbreviation already exists
				 return NO;
		}
	}
	return YES;	// don't check expansion text
}
- (void)controlTextDidEndEditing:(NSNotification *)aNotification	{
	((IRTableHeaderView *)[table headerView]).enabled = YES;
	self.activeText = nil;
}
- (void)tableViewSelectionDidChange:(NSNotification *)notification {
//	NSLog(@"selectionchanged");
}
- (BOOL)tableView:(NSTableView *)aTableView shouldEditTableColumn:(NSTableColumn *)aTableColumn row:(NSInteger)rowIndex {
	[table deselectAll:nil];
	return YES;
}
- (NSInteger)numberOfRowsInTableView:(NSTableView *)tableView {
	return [_dictionary count];
}
- (id)tableView:(NSTableView *)tableView objectValueForTableColumn:(NSTableColumn *)tableColumn row:(NSInteger)row {
	if ([[tableColumn identifier] isEqualToString:@"_abbreviation"])
		return [_sortedArray objectAtIndex:row];		// return key
	else			// abbrev text
		return [_dictionary objectForKey:[_sortedArray objectAtIndex:row]];
}
- (void)tableView:(NSTableView *)tableView setObjectValue:(id)object forTableColumn:(NSTableColumn *)tableColumn row:(NSInteger)row {
	if ([(NSString *)object length]) {	// some other checks (e.g., abbrev is single word)
		NSString * currentkey = [_sortedArray objectAtIndex:row];
		
		if ([[tableColumn identifier] isEqualToString:@"_abbreviation"])	{
			if (![currentkey isEqualToString:object])	{	// if changed key
				[_dictionary setObject:[_dictionary objectForKey:currentkey] forKey:object];
				[_dictionary removeObjectForKey:currentkey];
				[_sortedArray replaceObjectAtIndex:row withObject:object];
			}
		}
		else
			[_dictionary setObject:[object normalizeAttributesWithMap:NULL] forKey:currentkey];
	}
}
- (void)tableView:(NSTableView *)tableView sortDescriptorsDidChange:(NSArray *)oldDescriptors {
	[self sortAndReload];
}
@end

//
//  MarkupTagsController.m
//  Cindex
//
//  Created by PL on 1/9/05.
//  Copyright 2005 Indexing Research. All rights reserved.
//

//#import "CindexController.h"
#import "tags.h"
#import "strings_c.h"
#import "commandutils.h"
#import "StringCategories.h"
#import "MarkupTagsController.h"
#import "IRIndexDocument.h"
#import "IRIndexDocumentController.h"
#import "regex.h"

#define gettagsetsize(TS) (sizeof(TAGSET)+str_xlen(TS->xstr)+1)

@interface MarkupTagsController () {
	TAGSET *_tset;
	URegularExpression * element;
}
- (void)_setTagset:(NSString *)path;
- (NSData *)_recoverTagset;
- (NSTextField *)_fieldForTag:(int)tindex;
@end

@implementation MarkupTagsController
- (id)init	{
    self = [super initWithWindowNibName:@"MarkupTagsController"];
    return self;
}
- (void)dealloc {
	uregex_close(element);
}
- (void)awakeFromNib {
	[super awakeFromNib];
	[self buildTagsetMenu:xmltagset type:CINXMLTagExtension key:CIXMLTagSet];
	[self buildTagsetMenu:tagset type:CINTagExtension key:CISGMLTagSet];
	[tagtype selectTabViewItemAtIndex:SGMLTAGS];	// forces button setup via chooseTags via didSelectTabViewItem
	[tagtype selectTabViewItemAtIndex:XMLTAGS];
	// element name must start with letter or underscore; can't start with 'xml'; only other permissible chars are . and -
	element = regex_build("^[^A-Za-z_]|[^A-Za-z0-9_.-]",0);
}
- (void)buildTagsetMenu:(NSPopUpButton *)popup type:(NSString *)type key:(NSString *)key{
	NSArray * sets = ts_gettagsets(type);
	[popup removeAllItems];
	for (NSString * path in sets)	{
		if (ts_openset(path)) {	// if can open as valid set
			NSString * name = [[path lastPathComponent] stringByDeletingPathExtension];
			
			[popup addItemWithTitle:name];
			[[popup itemWithTitle:name] setRepresentedObject:path];
		}
	}
	NSInteger itemindex = [popup indexOfItemWithRepresentedObject:[[NSUserDefaults standardUserDefaults] objectForKey:key]];
	[popup selectItemAtIndex:itemindex >= 0 ? itemindex : 0];
}
- (IBAction)showHelp:(id)sender {
	[[NSHelpManager sharedHelpManager] openHelpAnchor:_currentTagType == XMLTAGS ? @"tags1_Anchor-14210" : @"tags0_Anchor-14210" inBook:@"Cindex 4.2.5 Help"];
}
- (void)_setTagset:(NSString *)path {
	_tset = ts_openset(path);
//	ts_convert(_tset);		// converts tag set to current format
	for (int tindex = 0; tindex < T_NUMTAGS; tindex++) {
		NSTextField * tf = [self _fieldForTag:tindex];
		
		if (tf && tindex != T_OTHERBASE+OT_ENDLINE)	{	// if not disabled end line
			[tf setStringValue:[NSString stringWithUTF8String:str_xatindex(_tset->xstr,tindex)]];
			[tf setEnabled:!_tset->readonly];
		}
	}
	if (_currentTagType == SGMLTAGS)	{
		[suppress setState:_tset->suppress];
		[suppress setEnabled:!_tset->readonly];
		[nested setState:_tset->nested];
		[nested setEnabled:!_tset->readonly];
		[tagindividual setState:_tset->individualrefs];
		[tagindividual setEnabled:!_tset->readonly];
		[encodeasascii setState:!_tset->useUTF8];
		[encodeasascii setEnabled:!_tset->readonly];
		[unicodetype selectCellAtRow:0 column:_tset->hex];
		[unicodetype setEnabled:!_tset->readonly];
		[extension setStringValue:[NSString stringWithUTF8String:_tset->extn]];
		[extension setEnabled:!_tset->readonly];
		[self changeEncoding:encodeasascii];	// deal with enables/disables
	}
	else {
		[xmllevelmode setState:_tset->levelmode];
		[xmllevelmode setEnabled:!_tset->readonly];
		[xmlsuppress setState:_tset->suppress];
		[xmlsuppress setEnabled:!_tset->readonly];
		[xmlnested setState:_tset->nested];
		[xmlnested setEnabled:!_tset->readonly];
		[xmltagindividual setState:_tset->individualrefs];
		[xmltagindividual setEnabled:!_tset->readonly];
		[xmlfontmode selectCellWithTag:_tset->fontmode];
		[xmlfontmode setEnabled:!_tset->readonly];
	}
}
- (NSData *)_recoverTagset{
	NSMutableData * tdata = [NSMutableData dataWithCapacity:5000];
	int tindex;
	char echar = EOCS;
	
	_tset->version = TS_VERSION;
	_tset->tssize = sizeof(TAGSET);
	if (_currentTagType == SGMLTAGS)	{
		_tset->hex	= [unicodetype selectedColumn];
		strcpy(_tset->extn,[[extension stringValue] UTF8String]);
		_tset->suppress = [suppress state];
		_tset->individualrefs = [tagindividual state];
		_tset->useUTF8 = ![encodeasascii state];
		_tset->nested = [nested state];
	}
	else {
		_tset->levelmode = [xmllevelmode state];		
		_tset->nested = [xmlnested state];		
		_tset->suppress = [xmlsuppress state];
		_tset->individualrefs = [xmltagindividual state];
		_tset->fontmode = [xmlfontmode selectedColumn];		
	}
	[tdata appendBytes:_tset length:sizeof(TAGSET)];
	for (tindex = 0; tindex < T_NUMTAGS; tindex++) {
		NSTextField * tf = [self _fieldForTag:tindex];
		char * tstring;
		
		if (tf)
			tstring = (char *)[[tf stringValue] UTF8String];
		else
			tstring = "";
		[tdata appendBytes:tstring length:strlen(tstring)+1];
	}
	[tdata appendBytes:&echar length:1];	// terminate compound string
	return tdata;
}
- (NSTextField *)_fieldForTag:(int)tindex {
	NSView * tview;
	
	if (_currentTagType == XMLTAGS)	{
		if (tindex < T_STYLEBASE || tindex > T_OTHERBASE)		// body tag kludge is in OTHER collection
			tview = [[_currentTab tabViewItemAtIndex:0] view];
		else
			tview = [[_currentTab tabViewItemAtIndex:1] view];
	}
	else {
		if (tindex < T_STYLEBASE)
			tview = [[_currentTab tabViewItemAtIndex:0] view];
		else if (tindex < T_FONTBASE)
			tview = [[_currentTab tabViewItemAtIndex:1] view];
		else if (tindex < T_OTHERBASE)
			tview = [[_currentTab tabViewItemAtIndex:2] view];
		else 
			tview = [[_currentTab tabViewItemAtIndex:3] view];
	}
	return [tview viewWithTag:tindex];
}
- (IBAction)duplicateTags:(id)sender {
	_dupmode = TRUE;
	[newname setStringValue:@""];
	[NSApp runModalForWindow:namepanel]; 
}
- (IBAction)deleteTags:(id)sender {
	NSString * setname = [[_currentPopUp selectedItem] representedObject];

	if (sendwarning(DELTAGWARNING, [[_currentPopUp titleOfSelectedItem] UTF8String]))	{	/* if really want to delete tag set */
		if ([[NSFileManager defaultManager] removeItemAtPath:setname error:NULL])	// if have removed
			[_currentPopUp removeItemAtIndex:[_currentPopUp indexOfItemWithRepresentedObject: setname]];
		[self chooseTags:_currentPopUp];	// force update of buttons. etc.
	}
}
- (IBAction)newTags:(id)sender {
	_dupmode = FALSE;
	[newname setStringValue:@""];
	[NSApp runModalForWindow:namepanel]; 
}
- (IBAction)viewTags:(id)sender {
	[self _setTagset:[[_currentPopUp selectedItem] representedObject]];
	[_currentPanel setTitle:[_currentPopUp titleOfSelectedItem]];
	[_currentTab selectFirstTabViewItem:self];
	[NSApp runModalForWindow:_currentPanel]; 
}
- (IBAction)chooseTags:(id)sender {
	NSData * tdata = [NSData dataWithContentsOfFile:[[sender selectedItem] representedObject]];
	if (tdata)	{	// if have data
		[_currentViewButton setEnabled:YES];
		[_currentDupButton setEnabled:YES];
		if (((TAGSET *)[tdata bytes])->readonly)	{
			[_currentViewButton setTitle:[NSString stringWithUTF8String:"View…"]];
			[_currentDeleteButton setEnabled:NO];
			[tagok setEnabled:NO];
		}
		else {
			[_currentViewButton setTitle:[NSString stringWithUTF8String:"Edit…"]];
			[_currentDeleteButton setEnabled:YES];
			[tagok setEnabled:YES];
		}
	}
	else {
		[_currentViewButton setEnabled:NO];
		[_currentDupButton setEnabled:NO];
		[_currentDeleteButton setEnabled:NO];
	}
}
- (IBAction)closePanel:(id)sender {
	if ([sender tag] == OKTAG)	{
		if ([sender window] == _currentPanel) 	{	// if closing set
			if (![[self window] makeFirstResponder:nil])	// if can't finish editing
				return;
			[[self _recoverTagset] writeToFile:[[_currentPopUp selectedItem] representedObject] atomically:YES];
		}
		else if ([sender window] == namepanel) {	// if naming new set
			NSString * name = [newname stringValue];		// get name of new set
			NSString *pathname = global_preferencesdirectory();
			NSString * textension = _currentTagType == XMLTAGS ? CINXMLTagExtension : CINTagExtension;
			NSMutableData * dp;
			TAGSET * tp;
			
			if ([tagset itemWithTitle:name] || [xmltagset itemWithTitle:name])	{	// if set already exists
				NSString * fullpath = [[_currentPopUp selectedItem] representedObject];
				if ([fullpath rangeOfString:pathname].location == NSNotFound)	{	// if not a user tagset
					senderr(TAGDUPERR, WARN, [name UTF8String]);		// forbid name
					return;
				}
				else if (!sendwarning(DUPTAGWARNING, [name UTF8String]))	// if don't want to replace
					return;
			}
			pathname = [[pathname stringByAppendingPathComponent:name] stringByAppendingPathExtension:textension];	// now have full path to new set
			if (_dupmode)	{		// if duplicating
				dp = [NSMutableData dataWithContentsOfFile:[[_currentPopUp selectedItem] representedObject]];
				tp = [dp mutableBytes];
				tp->readonly = FALSE;
			}
			else {		// new set
				dp = [NSMutableData dataWithLength:EMPTYTAGSETSIZE];	// empty set
				tp = [dp mutableBytes];
				tp->version = TS_VERSION;
				tp->tssize = sizeof(TAGSET);
				char * sptr = str_xatindex(tp->xstr,T_NUMTAGS);
				*sptr = EOCS;			/* terminate x string */
			}
			if ([dp writeToFile:pathname atomically:YES])	{
				[_currentPopUp addItemWithTitle:name];
				[[_currentPopUp itemWithTitle:name] setRepresentedObject:pathname];
				[_currentPopUp selectItemWithTitle:name];
				[[sender window] close];	// need to get rid of name panel
				[NSApp stopModal]; 
				[self chooseTags:_currentPopUp];	// force update of buttons. etc.
				[self viewTags:self];
			}
			else
				NSLog(@"Error saving new tagest");
			return;
		}
		else {		// closing main panel
			[[NSUserDefaults standardUserDefaults] setObject:[[xmltagset selectedItem] representedObject] forKey:CIXMLTagSet];
			[[NSUserDefaults standardUserDefaults] setObject:[[tagset selectedItem] representedObject] forKey:CISGMLTagSet];
		}
	}
	[[sender window] close];
	[NSApp stopModal]; 
}
- (IBAction)changeEncoding:(id)sender {
	if (!_tset->readonly)	{
		[unicodetype setEnabled:[sender state]];
		[[self _fieldForTag:T_OTHERBASE+OT_UPREFIX] setEnabled:[sender state]];
		[[self _fieldForTag:T_OTHERBASE+OT_USUFFIX] setEnabled:[sender state]];
	}
}
#if 0
- (BOOL)tabView:(NSTabView *)tabView shouldSelectTabViewItem:(NSTabViewItem *)tabViewItem {
//	return tabView == tagtype ? YES : [[self window] makeFirstResponder:nil];
	return [[self window] makeFirstResponder:tabView];
}
#endif
- (void)tabView:(NSTabView *)tabView didSelectTabViewItem:(NSTabViewItem *)tabViewItem	{
	if (tabView == tagtype)	{
		_currentTagType = [tabView indexOfTabViewItem:[tabView selectedTabViewItem]];
		if (_currentTagType == XMLTAGS)	{
			_currentPanel = xmlpanel;
			_currentPopUp = xmltagset;
			_currentViewButton = xmlviewset;
			_currentDeleteButton = xmldeleteset;
			_currentDupButton = xmldupset;
			_currentTab = xmltab;
		}
		else {
			_currentPanel = tagpanel;
			_currentPopUp = tagset;
			_currentViewButton = viewset;
			_currentDeleteButton = deleteset;
			_currentDupButton = dupset;
			_currentTab = tab;
		}
		[self chooseTags:_currentPopUp];
	}
}
- (void)controlTextDidChange:(NSNotification *)note	{
	NSTextField * control = [note object];
	if (control == extension)
		checktextfield(control,4);
	else if (_currentTagType == XMLTAGS){	// check for forbidden chars in xml tag [sgml doesn't have delegate set]
		const char * curtext = control.stringValue.UTF8String;
		char newtext[400];
		
		strcpy(newtext,curtext);
		regex_replace(element,newtext,"");	// strip all forbidden chars
		if (strcmp(curtext,newtext)) {
			int index = 0;
			while (newtext[index] && curtext[index] == newtext[index])
				index++;
			[control setStringValue:[NSString stringWithUTF8String:newtext]];
			NSText* fieldEditor = [control currentEditor];
			[fieldEditor setSelectedRange:NSMakeRange(index, 1)];
		}
	}
}
@end

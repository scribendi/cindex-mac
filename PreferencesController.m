//
//  PreferencesController.m
//  Cindex
//
//  Created by PL on 1/9/05.
//  Copyright 2005 Indexing Research. All rights reserved.
//

#import "IRIndexDocumentController.h"
#import "IRIndexDocument.h"
#import "PreferencesController.h"
#import "cindexmenuitems.h"
#import "commandutils.h"

@interface PreferencesController (PrivateMethods)
- (void)_setItems;
@end

@implementation PreferencesController
- (id)init	{
    self = [super initWithWindowNibName:@"PreferencesController"];
    return self;
}
- (void)awakeFromNib {
	[super awakeFromNib];
#if defined _DEMOCOPY || defined _STUDENTCOPY
	[checkforupdates setState:NO];
	[checkforupdates setEnabled:NO];
#endif
	[defaultfont removeAllItems];
	[defaultfont addItemsWithTitles:[IRdc fonts]];
	wells[0] = labelcolor1;
	wells[1] = labelcolor2;
	wells[2] = labelcolor3;
	wells[3] = labelcolor4;
	wells[4] = labelcolor5;
	wells[5] = labelcolor6;
	wells[6] = labelcolor7;
	[self _setItems];
}
- (IBAction)doSetAction:(id)sender {
	if (sender == autocompleteentries) {
		if ([sender state]) {	// enable
			[autocompletignorestyle setEnabled:YES];
			[autocompletetrack setEnabled:YES];
		}
		else {	// disable
			[autocompletignorestyle setState:NO];
			[autocompletetrack setState:NO];
			[autocompletignorestyle setEnabled:NO];
			[autocompletetrack setEnabled:NO];
		}
	}
}
- (IBAction)showHelp:(id)sender {
	NSInteger index = [_tabView indexOfTabViewItem:[_tabView selectedTabViewItem]];
	NSString * anchor;
	
	if (index == 0)
		anchor = @"prf0_Anchor-47857";
	else if (index == 1)
		anchor = @"prf1_Anchor-11481";
	else if (index == 2)
		anchor = @"prf2_Anchor-35882";
	else
		anchor = @"prf3_Anchor-14210";
	[[NSHelpManager sharedHelpManager] openHelpAnchor:anchor inBook:@"Cindex 4.2.5 Help"];
}
- (IBAction)closePanel:(id)sender {    
	if ([sender tag] == OKTAG)	{
		int indent, count;
		
		if (![[self window] makeFirstResponder:[self window]])	// if bad text somewhere
			return;
		g_prefs.gen.openflag = [[startaction selectedCell] tag];
		g_prefs.gen.setid = [userprompt state];
#if _DEBUG_ON
		g_prefs.gen.saveinterval = [saveinterval floatValue]*6;
#else
		g_prefs.gen.saveinterval = [saveinterval floatValue]*60;
#endif
		g_prefs.privpars.eunit = [[unit selectedItem] tag];
//		g_prefs.gen.autoupdate = [checkforupdates state];
		
		g_prefs.gen.switchview = [switchtodraft state];
		g_prefs.gen.remspaces = [stripspaces state];
		g_prefs.gen.smartflip = [smartflip state];
		g_prefs.gen.autorange = [autorange state];
		
		g_prefs.gen.track = [tracknewentries state];
		g_prefs.gen.carryrefs = [carrylocators state];
		g_prefs.gen.autoextend = [autocompleteentries state];
		g_prefs.gen.autoignorecase = [autocompletignorestyle state];
		g_prefs.gen.tracksource = [autocompletetrack state];
		
		g_prefs.gen.propagate = [propagatechanges state];
		g_prefs.gen.vreturn = [returntoentryoint state];
		g_prefs.gen.labelsetsdate = [labelchangesdate state];

		g_prefs.gen.saverule = [[closeaction selectedCell] tag];
		g_prefs.gen.pagealarm = [[badlocatoraction selectedCell] tag];
		g_prefs.gen.crossalarm = [[badcrossrefaction selectedCell] tag];
		g_prefs.gen.templatealarm = [[mismatchaction selectedCell] tag];
		g_prefs.gen.pastemode = [[pasteaction selectedCell] tag];

		strcpy(g_prefs.gen.fm[0].pname, [[defaultfont titleOfSelectedItem] UTF8String]);
		g_prefs.privpars.size = [defaultsize intValue];
		
		for (count = 0; count < FLAGLIMIT-1; count++)
			[[wells[count] color] getRed:&g_prefs.gen.lcolors[count].red green:&g_prefs.gen.lcolors[count].green blue:&g_prefs.gen.lcolors[count].blue alpha:NULL];
		g_prefs.gen.showlabel = [showformattedlabels state];
		g_prefs.gen.recordtextsize = [recordtextsize intValue];
		
		strcpy(g_prefs.hidden.user, (char *)[[userid stringValue] UTF8String]);
		
		g_prefs.gen.newlinetype = [[exportformat selectedCell] tag];
		indent = (int)[[indenttype selectedCell] tag];
		if (indent == 1)
			g_prefs.gen.indentdef = '\t';
		else if (indent == 2)
			g_prefs.gen.indentdef = *(char *)[[indentchar stringValue] UTF8String];
		else
			g_prefs.gen.indentdef = '\0';
		g_prefs.gen.embedsort = [embedsort state];
		g_prefs.gen.nativetextencoding = [[textencoding selectedCell] tag];
		global_saveprefs(GPREF_GENERAL);
		buildlabelmenu([findmenuitem(MI_LABELED) submenu],14);
		[[NSNotificationCenter defaultCenter] postNotificationName:NOTE_PREFERENCESCHANGED object:nil];
	}
	if ([NSColorPanel sharedColorPanelExists])
		[[NSColorPanel sharedColorPanel] close];
	[self close];
	[NSApp stopModal];
}
- (void)_setItems {
	int indent = 0;
	int count;

	[_tabView selectTabViewItemAtIndex:0];
	[startaction selectCellWithTag:g_prefs.gen.openflag];

	[userprompt setState:g_prefs.gen.setid];
	[saveinterval setFloatValue:g_prefs.gen.saveinterval/60.];
	[unit selectItemAtIndex:[unit indexOfItemWithTag:g_prefs.privpars.eunit]];
//	[checkforupdates setState:g_prefs.gen.autoupdate];
	
	[switchtodraft setState:g_prefs.gen.switchview];
	[stripspaces setState:g_prefs.gen.remspaces];
	[smartflip setState:g_prefs.gen.smartflip];
	[autorange setState:g_prefs.gen.autorange];
	
	[tracknewentries setState:g_prefs.gen.track];
	[carrylocators setState:g_prefs.gen.carryrefs];
	[autocompleteentries setState:g_prefs.gen.autoextend];
	[autocompletignorestyle setState:g_prefs.gen.autoignorecase];
	[autocompletetrack setState:g_prefs.gen.tracksource];
	[self doSetAction:autocompleteentries];		// enable/disable check boxes
	
	[propagatechanges setState:g_prefs.gen.propagate];
	[returntoentryoint setState:g_prefs.gen.vreturn];
	[labelchangesdate setState:g_prefs.gen.labelsetsdate];

	[closeaction selectCellWithTag:g_prefs.gen.saverule];
	[badlocatoraction selectCellWithTag:g_prefs.gen.pagealarm];
	[badcrossrefaction selectCellWithTag:g_prefs.gen.crossalarm];
	[mismatchaction selectCellWithTag:g_prefs.gen.templatealarm];
	[pasteaction selectCellWithTag:g_prefs.gen.pastemode];

	[defaultfont selectItemWithTitle:[NSString stringWithCString:g_prefs.gen.fm[0].pname encoding:NSUTF8StringEncoding]];
	[defaultsize setIntValue:g_prefs.privpars.size];
	[defaultsize selectItemWithObjectValue:[defaultsize stringValue]];

	[recordtextsize setIntValue:g_prefs.gen.recordtextsize];
	[recordtextsize selectItemWithObjectValue:[recordtextsize stringValue]];
	
	for (count = 0; count < FLAGLIMIT; count++)
		[wells[count] setColor:[NSColor colorWithCalibratedRed:g_prefs.gen.lcolors[count].red green:g_prefs.gen.lcolors[count].green blue:g_prefs.gen.lcolors[count].blue alpha:1]];
	[showformattedlabels setState:g_prefs.gen.showlabel];
	
	[userid setStringValue:[NSString stringWithCString:g_prefs.hidden.user encoding:NSUTF8StringEncoding]];
	
	[exportformat selectCellWithTag:g_prefs.gen.newlinetype];
	if (g_prefs.gen.indentdef) {
		if (g_prefs.gen.indentdef == '\t')
			indent = 1;
		else {
			[indentchar setStringValue:[NSString stringWithFormat:@"%c",g_prefs.gen.indentdef]];
			indent = 2;
		}
	}
	[indenttype selectCellWithTag:indent];
	[embedsort setState:g_prefs.gen.embedsort];
	[textencoding selectCellWithTag:g_prefs.gen.nativetextencoding];
}
- (void)controlTextDidChange:(NSNotification *)note	{
	NSControl * control = [note object];
	
	if (control == indentchar)	{// if record range
		checktextfield(control,2);
		[indenttype selectCellWithTag:2];
	}
	else if (control == userid) {
		checktextfield(control,5);
	}
}
#if 0
- (BOOL)tabView:(NSTabView *)tabView shouldSelectTabViewItem:(NSTabViewItem *)tabViewItem {
	return [[self window] makeFirstResponder:_tabView];	// if bad text somewhere
}
#endif
@end

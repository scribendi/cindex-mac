//
//  PreferencesController.h
//  Cindex
//
//  Created by PL on 1/9/05.
//  Copyright 2005 Indexing Research. All rights reserved.
//


@interface PreferencesController : NSWindowController {
	IBOutlet NSTabView * _tabView;
	
	IBOutlet NSMatrix * startaction;
	IBOutlet NSButton * userprompt;
	IBOutlet NSTextField * saveinterval;
	IBOutlet NSTextField * userid;
	IBOutlet NSPopUpButton * unit;
	IBOutlet NSButton * checkforupdates;
	
	IBOutlet NSButton * switchtodraft;
	IBOutlet NSButton * stripspaces;
	IBOutlet NSButton * smartflip;
	IBOutlet NSButton * autorange;
	
	IBOutlet NSButton * tracknewentries;
	IBOutlet NSButton * carrylocators;
	IBOutlet NSButton * autocompleteentries;
	IBOutlet NSButton * autocompletignorestyle;
	IBOutlet NSButton * autocompletetrack;
	
	IBOutlet NSButton * propagatechanges;
	IBOutlet NSButton * returntoentryoint;
	IBOutlet NSButton * labelchangesdate;
	
	IBOutlet NSMatrix * pasteaction;	
	IBOutlet NSMatrix * closeaction;
	IBOutlet NSMatrix * badlocatoraction;
	IBOutlet NSMatrix * badcrossrefaction;
	IBOutlet NSMatrix * mismatchaction;
	
	IBOutlet NSPopUpButton * defaultfont;
	IBOutlet NSComboBox * defaultsize;
	IBOutlet NSColorWell * labelcolor1;
	IBOutlet NSColorWell * labelcolor2;
	IBOutlet NSColorWell * labelcolor3;
	IBOutlet NSColorWell * labelcolor4;
	IBOutlet NSColorWell * labelcolor5;
	IBOutlet NSColorWell * labelcolor6;
	IBOutlet NSColorWell * labelcolor7;
	IBOutlet NSButton * showformattedlabels;

	IBOutlet NSComboBox * recordtextsize;

	IBOutlet NSMatrix * exportformat;
	IBOutlet NSMatrix * indenttype;
	IBOutlet NSTextField * indentchar;
	IBOutlet NSButton * embedsort;
	IBOutlet NSMatrix * textencoding;
	
	NSColorWell * wells[FLAGLIMIT];
}
- (IBAction)doSetAction:(id)sender;
@end

//
//  MarkupTagsController.h
//  Cindex
//
//  Created by PL on 1/9/05.
//  Copyright 2005 Indexing Research. All rights reserved.
//
#import "tags.h"

@interface MarkupTagsController : NSWindowController {
	// manage panel
	IBOutlet NSTabView * tagtype;
	
	IBOutlet NSPanel * xmlpanel;
	IBOutlet NSPopUpButton * xmltagset;
	IBOutlet NSButton * xmldeleteset;
	IBOutlet NSButton * xmldupset;
	IBOutlet NSButton * xmlviewset;

	IBOutlet NSPanel * tagpanel;
	IBOutlet NSPopUpButton * tagset;
	IBOutlet NSButton * deleteset;
	IBOutlet NSButton * dupset;
	IBOutlet NSButton * viewset;
	
	// new name panel
	IBOutlet NSPanel * namepanel;
	IBOutlet NSTextField * newname;

	// xml panel
	IBOutlet NSTabView * xmltab;
	IBOutlet NSButton * xmlsuppress;
	IBOutlet NSButton * xmlnested;
	IBOutlet NSButton * xmltagindividual;
	IBOutlet NSMatrix * xmlfontmode;
	IBOutlet NSButton * xmllevelmode;
	
	// sgml panel
	IBOutlet NSTabView * tab;
	IBOutlet NSTextField * extension;
	IBOutlet NSButton * suppress;
	IBOutlet NSButton * nested;
	IBOutlet NSButton * encodeasascii;
	IBOutlet NSButton * tagindividual;
	IBOutlet NSMatrix * unicodetype;
	
	IBOutlet NSButton * tagok;
	
	BOOL _dupmode;
	int _currentTagType;
	NSPanel * _currentPanel;
	NSPopUpButton * _currentPopUp;
	NSButton * _currentDeleteButton;
	NSButton * _currentDupButton;
	NSButton * _currentViewButton;
	NSTabView * _currentTab;
}
- (IBAction)duplicateTags:(id)sender;
- (IBAction)deleteTags:(id)sender;
- (IBAction)newTags:(id)sender;
- (IBAction)chooseTags:(id)sender;
- (IBAction)viewTags:(id)sender;
- (IBAction)closePanel:(id)sender;
@end

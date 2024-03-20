//
//  SpellController.h
//  Cindex
//
//  Created by PL on 2/21/05.
//  Copyright 2005 Indexing Research. All rights reserved.
//

#import "IRIndexDocument.h"
#import "spell.h"
#import "hspell.h"

@interface SpellController : NSWindowController <NSTableViewDataSource, NSTableViewDelegate>{
	IBOutlet NSMatrix * scope;
	IBOutlet NSTextField * firstrecord;
	IBOutlet NSTextField * lastrecord;
	IBOutlet NSMatrix * recordfilter;
	IBOutlet NSButton * checkpagerefs;
	IBOutlet NSPopUpButton * field;
	
	IBOutlet NSTextField * unknownprompt;
	IBOutlet NSTextField * unknownword;
	IBOutlet NSTextField * changedword;
	IBOutlet NSTableView * suggesttable;
	
	IBOutlet NSTextField * languagename;
	IBOutlet NSPopUpButton * personaldictionary;
	IBOutlet NSButton * startbutton;
	IBOutlet NSButton * addbutton;
	IBOutlet NSButton * changebutton;
	IBOutlet NSButton * ignoreallbutton;
	IBOutlet NSButton * suggestbutton;
	IBOutlet NSButton * optionsbutton;

	IBOutlet NSPanel * optionspanel;
	IBOutlet NSPopUpButton * language;
	
	IBOutlet NSTableView * extradictionaries;
	IBOutlet NSMatrix * dialect;
	IBOutlet NSMatrix * supplement;
	IBOutlet NSMatrix * mdialect;
	IBOutlet NSMatrix * msupplement;
	IBOutlet NSMatrix * french;
	IBOutlet NSMatrix * spanish;

	IBOutlet NSButton * alwayssuggest;
	IBOutlet NSButton * ignorecaps;
	IBOutlet NSButton * ignorealnum;
	IBOutlet NSButton * clearignorelist;
	IBOutlet NSPopUpButton * pdictionary;
	IBOutlet NSButton * editdictionary;
	IBOutlet NSButton * newdictionary;

	IBOutlet NSPanel * editdicpanel;
	IBOutlet NSTextView * edittext;
	IBOutlet NSTextField * wordcount;

	IBOutlet NSPanel * newdicpanel;
	IBOutlet NSTextField * newdicname;

	INDEX * FF;
	SPELL sps;	/* spelling control struct */
	struct numstruct *nptr;	/* numstruct array for resorting */
	NSMutableArray * _personaldics;
	NSMutableArray * _auxSetCopy;
	NSMutableArray * _alternatives;
	NSMutableArray * _pdwords;
//	IRIndexDocument * _currentDocument;
	RECN _target;
	BOOL _restart;
	BOOL _needsSetup;
	short offset, mlength;
	BOOL _delayedClearIgnore;
	BOOL _languageChanged;
	int _languageIndex;
	int _wordcount;
	DICTIONARYSET * _activeDicSet;
}
@property (strong) NSMutableArray * _personaldics;
@property (strong) NSMutableArray * _alternatives;
@property (strong) NSMutableArray * _pdwords;
@property (strong) NSMutableArray * _auxSetCopy;

- (IBAction)reset:(id)sender;
- (IBAction)spell:(id)sender;
- (IBAction)change:(id)sender;
- (IBAction)stop:(id)sender;
- (IBAction)doSetAction:(id)sender;
- (IBAction)closeSheet:(id)sender;
- (IBAction)closePanel:(id)sender;

- (void)setDefaultChangedWord;
@end

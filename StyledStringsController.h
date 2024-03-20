//
//  StyledStringsController.h
//  Cindex
//
//  Created by PL on 1/9/05.
//  Copyright 2005 Indexing Research. All rights reserved.
//


@interface StyledStringsController : NSWindowController {
	IBOutlet NSMatrix * style;
	IBOutlet NSMatrix * offset;
	IBOutlet NSTableView * table;
	
	IBOutlet NSSegmentedControl * segs;
//	IBOutlet NSButton * addbutton;
//	IBOutlet NSButton * deletebutton;
	
	char * _stringPtr;
	char _string[STYLESTRINGLEN];
	char _tstring[STYLESTRINGLEN];
	int _lastSelection, _currentSelection;
}
//- (IBAction)addString:(id)sender;
//- (IBAction)deleteString:(id)sender;
- (IBAction)manageString:(id)sender;
@end

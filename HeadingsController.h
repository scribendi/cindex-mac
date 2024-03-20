//
//  HeadingsController.h
//  Cindex
//
//  Created by PL on 1/9/05.
//  Copyright 2005 Indexing Research. All rights reserved.
//


@interface HeadingsController : NSWindowController {
	IBOutlet NSPopUpButton * heading;
	IBOutlet NSPopUpButton * font;
	IBOutlet NSComboBox * size;
	IBOutlet NSButton * suppress;
	IBOutlet NSTextField * lead;
	IBOutlet NSTextField * trail;
	
	ENTRYFORMAT _hParams;
	ENTRYFORMAT * _hParamPtr;
	int _currentfield;
}
- (IBAction)showForHeading:(id)sender;
@end

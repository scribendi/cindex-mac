//
//  MarginColumnController.h
//  Cindex
//
//  Created by PL on 1/9/05.
//  Copyright 2005 Indexing Research. All rights reserved.
//


@interface MarginColumnController : NSWindowController {
	IBOutlet NSTextField * top;
	IBOutlet NSTextField * left;
	IBOutlet NSTextField * bottom;
	IBOutlet NSTextField * right;
	IBOutlet NSButton * facingpages;
	
	IBOutlet NSPopUpButton * columns;
	IBOutlet NSTextField * gutter;

	IBOutlet NSPopUpButton * unit;

	IBOutlet NSMatrix * breakcontrol;
	IBOutlet NSTextField * appendtext;
	IBOutlet NSPopUpButton * level;
	
	MARGINCOLUMN * _iParamPtr;
	MARGINCOLUMN _iParams;
	int _unit;
}
- (IBAction)changeUnit:(id)sender;
@end

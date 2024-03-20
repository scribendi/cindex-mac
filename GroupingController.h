//
//  GroupingController.h
//  Cindex
//
//  Created by PL on 1/9/05.
//  Copyright 2005 Indexing Research. All rights reserved.
//


@interface GroupingController : NSWindowController {
	IBOutlet NSTextField * text;
	IBOutlet NSPopUpButton * font;
	IBOutlet NSComboBox * combo;
	IBOutlet NSPopUpButton * symbolgrouping;
	IBOutlet NSTextField * numbers;
	IBOutlet NSTextField * symbols;
	IBOutlet NSTextField * numbersSymbols;

	GROUPFORMAT _gParams;
	GROUPFORMAT * _gParamPtr;
}

@end

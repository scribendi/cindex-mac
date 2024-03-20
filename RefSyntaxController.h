//
//  RefSyntaxController.h
//  Cindex
//
//  Created by PL on 1/9/05.
//  Copyright 2005 Indexing Research. All rights reserved.
//


@interface RefSyntaxController : NSWindowController {
	IBOutlet NSTextField * clead;
	IBOutlet NSTextField * cgeneral;
	IBOutlet NSTextField * cseparator;
	IBOutlet NSButton * locatoronly;
	IBOutlet NSTextField * plead;
	IBOutlet NSTextField * pconnect;
	IBOutlet NSTextField * pmax;
	IBOutlet NSTextField * prange;

	REFPARAMS _lParam;
	REFPARAMS * _lParamPtr;
}

@end

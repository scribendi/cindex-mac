//
//  CountController.h
//  Cindex
//
//  Created by PL on 1/9/05.
//  Copyright 2005 Indexing Research. All rights reserved.
//

#import "indexdocument.h"

@interface CountController : NSWindowController {
	IBOutlet NSMatrix * scope;
	IBOutlet NSTextField * rangestart;
	IBOutlet NSTextField * rangeend;

	IBOutlet NSMatrix * among;

	IBOutlet NSTextField * locatorstart;
	IBOutlet NSTextField * locatorend;

	IBOutlet NSTextView * countview;
	
	COUNTPARAMS _cParams;
	INDEX * FF;
}

@end

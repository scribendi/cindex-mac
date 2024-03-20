//
//  StatisticsController.h
//  Cindex
//
//  Created by PL on 1/9/05.
//  Copyright 2005 Indexing Research. All rights reserved.
//

#import "indexdocument.h"

@interface StatisticsController : NSWindowController {
	IBOutlet NSMatrix * scope;
	IBOutlet NSTextField * rangestart;
	IBOutlet NSTextField * rangeend;
	IBOutlet NSTextField * pagestart;
	IBOutlet NSTextField * pageend;
	IBOutlet NSTextField * pagecount;

	IBOutlet NSTextView * display;
	IBOutlet NSProgressIndicator * indicator;
	IBOutlet NSButton * done;

	INDEX * FF;
	char _buffer[500];
	char * _statsbase;
}

@end

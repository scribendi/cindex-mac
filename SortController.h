//
//  SortController.h
//  Cindex
//
//  Created by PL on 1/9/05.
//  Copyright 2005 Indexing Research. All rights reserved.
//

@interface SortController : NSWindowController <NSTableViewDataSource, NSTableViewDelegate>{
	IBOutlet NSTabView * sorttab;
	IBOutlet NSProgressIndicator * indicator;
	
	IBOutlet NSPopUpButton * language;
	IBOutlet NSPopUpButton * alpharule;
	IBOutlet NSMatrix * exceptions;
	IBOutlet NSTableView * charpriority;
	IBOutlet NSTextField * ignoreprefix;
	IBOutlet NSButton * scriptfirst;
	IBOutlet NSButton * substitutions;

	IBOutlet NSTableView * fieldorder;
	IBOutlet NSButton * ignorelowest;

	IBOutlet NSTableView * segmentorder;
	IBOutlet NSTableView * typeprecedence;
	IBOutlet NSTableView * styleprecedence;
	IBOutlet NSMatrix * multiplerefs;
	IBOutlet NSButton * leftrightorder;

	IBOutlet NSPanel * subPanel;
	IBOutlet NSTableView * subtable;
	IBOutlet NSSegmentedControl * segs;

}
@end

//
//  FunctionkeyController.h
//  Cindex
//
//  Created by PL on 10/1205.
//  Copyright 2005 Indexing Research. All rights reserved.
//

@interface FunctionkeyController : NSWindowController <NSWindowDelegate, NSTableViewDataSource, NSTableViewDelegate,NSControlTextEditingDelegate>{
	IBOutlet NSTableView * table;

	NSMutableDictionary * _dictionary;	// working copy
	NSArray * _sortedArray;
}
+ (void)show;
@end

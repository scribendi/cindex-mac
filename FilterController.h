//
//  FilterController.h
//  Cindex
//
//  Created by Peter Lennie on 6/7/08.
//  Copyright 2008 Indexing Research. All rights reserved.
//

#import "IRIndexDocument.h"

@interface FilterController : NSWindowController {
	IBOutlet NSButton * enablefilter;
	IBOutlet NSMatrix * labels;

	INDEX * FF;
}

@end

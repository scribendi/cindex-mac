//
//  AlterRefsController.h
//  Cindex
//
//  Created by PL on 1/9/05.
//  Copyright 2005 Indexing Research. All rights reserved.
//

//#import "IRIndexDocument.h"
#import "indexdocument.h"

@interface AlterRefsController : NSWindowController {
	IBOutlet NSMatrix * scope;
	IBOutlet NSTextField * rangestart;
	IBOutlet NSTextField * rangeend;

	IBOutlet NSTextField * match;
	
	IBOutlet NSMatrix * action;
	IBOutlet NSButton * holdvalues;
	IBOutlet NSTextField * adjustment;
	
	INDEX * FF;
}
- (IBAction)removeAction:(id)sender;
@end

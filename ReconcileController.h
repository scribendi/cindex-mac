//
//  ReconcileController.h
//  Cindex
//
//  Created by PL on 1/9/05.
//  Copyright 2005 Indexing Research All rights reserved.
//

#import "indexdocument.h"

@interface ReconcileController : NSWindowController {
	IBOutlet NSPopUpButton * headings;
//	IBOutlet NSMatrix * mode;
	IBOutlet NSButton * preservemodified;
	IBOutlet NSButton * protectnames;
	IBOutlet NSMatrix * handleorphans;
	IBOutlet NSTextField * phrasechar;
	IBOutlet NSBox * box;

	INDEX * FF;
}
@end

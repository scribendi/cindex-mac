//
//  VerifyRefsController.h
//  Cindex
//
//  Created by PL on 1/9/05.
//  Copyright 2005 Indexing Research. All rights reserved.
//

#import "indexdocument.h"

@interface VerifyRefsController : NSWindowController {
	IBOutlet NSButton * checkcross;
	IBOutlet NSButton * checkpage;
	IBOutlet NSButton * requireexact;
	IBOutlet NSTextField * matches;
	IBOutlet NSTextField * refcount;

	INDEX * FF;
}

@end

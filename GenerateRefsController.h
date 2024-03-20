//
//  GenerateRefsController.h
//  Cindex
//
//  Created by PL on 1/9/05.
//  Copyright 2005 Indexing Research. All rights reserved.
//

#import "indexdocument.h"

@interface GenerateRefsController : NSWindowController {
	IBOutlet NSMatrix * _mode;
	IBOutlet NSTextField * _targetcount;
	IBOutlet NSView * _accessory;
	
	INDEX * FF;
}

@end

//
//  GoToController.h
//  Cindex
//
//  Created by PL on 1/9/05.
//  Copyright 2005 Indexing Research. All rights reserved.
//

#import "indexdocument.h"

@interface GoToController : NSWindowController {

    IBOutlet NSMatrix *gototype;
    IBOutlet NSComboBox *gotostring;
	IBOutlet NSTextField * pagecount;
	IBOutlet NSProgressIndicator * indicator;
	
	INDEX * FF;
}

@end

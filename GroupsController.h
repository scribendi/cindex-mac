//
//  GroupsController.h
//  Cindex
//
//  Created by PL on 1/9/05.
//  Copyright 2005 Indexing Research. All rights reserved.
//

#import "indexdocument.h"

@interface GroupsController : NSWindowController {
	IBOutlet NSPanel * infopanel;
	
	IBOutlet NSMatrix * groupmode;
	IBOutlet NSPopUpButton * group;
	
	IBOutlet NSMatrix * action;
	
	IBOutlet NSBox * contextbox;
	IBOutlet NSTextField * notstring;
	IBOutlet NSTextField * searchstring;
	IBOutlet NSTextField * andstring;
	IBOutlet NSTextField * attribstring;
	IBOutlet NSTextField * fieldstring;
	IBOutlet NSMatrix * ginfo;
	IBOutlet NSMatrix * gcontext;
	
	INDEX * FF;
}

@end

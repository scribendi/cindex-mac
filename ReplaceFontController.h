//
//  ReplaceFontController.h
//  Cindex
//
//  Created by PL on 3/6/05.
//  Copyright 2005 Indexing Research. All rights reserved.
//

@interface ReplaceFontController : NSWindowController {
	IBOutlet NSPopUpButton * fonts;
	IBOutlet NSTextField * badfont;
	
	char * _nameptr;
}
- (IBAction)closePanel:(id)sender;    

@end

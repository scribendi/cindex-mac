//
//  AbbreviationController.h
//  Cindex
//
//  Created by PL on 3/26/05.
//  Copyright 2005 Indexing Research. All rights reserved.
//

@interface AbbreviationController : NSWindowController <NSTableViewDataSource, NSTableViewDelegate,NSControlTextEditingDelegate>{
	IBOutlet NSTableView * table;
	IBOutlet NSButton * enter;
	IBOutlet NSSegmentedControl * segs;
}

- (IBAction)newAbbreviations:(id)sender;
- (IBAction)openAbbreviations:(id)sender;
- (IBAction)closeAbbreviations:(id)sender;
- (IBAction)manageAbbreviation:(id)sender;

+ (void)showWithExpansion:(NSAttributedString *)text;
@end

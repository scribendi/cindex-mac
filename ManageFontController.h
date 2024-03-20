//
//  ManageFontController.h
//  Cindex
//
//  Created by PL on 1/10/05.
//  Copyright 2005 Indexing Research. All rights reserved.
//

#import "indexdocument.h"

@interface ManageFontController : NSWindowController <NSTableViewDataSource, NSTableViewDelegate>{
	IBOutlet NSTableView * table;
	IBOutlet NSButton * check;
	IBOutlet NSButton * ok;
	IBOutlet NSButton * cancel;
	
}
@property FONTMAP * fmp;

+ (BOOL)manageFonts:(FONTMAP *)fm;
- (IBAction)checkUse:(id)sender;
@end

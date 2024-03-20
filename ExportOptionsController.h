//
//  ExportOptionsController.h
//  Cindex
//
//  Created by PL on 1/26/05.
//  Copyright 2005 Indexing Research. All rights reserved.
//

#import "IRIndexDocument.h"

@interface ExportOptionsController : NSWindowController {
	IBOutlet NSPanel * stylePanel;
	IBOutlet NSMatrix * mode;
	
	IBOutlet NSTabView * tab;
	
	IBOutlet NSMatrix * archivescope;
	IBOutlet NSTextField * archiverangefrom;
	IBOutlet NSTextField * archiverangeto;
	IBOutlet NSButton * archivenumberorder;
	IBOutlet NSButton * archiveincludedeleted;
	
	IBOutlet NSMatrix * plainscope;
	IBOutlet NSTextField * plainrangefrom;
	IBOutlet NSTextField * plainrangeto;
	IBOutlet NSButton * plainnumberorder;
	IBOutlet NSMatrix * plainencoding;
	IBOutlet NSTextField * plainminfields;

	IBOutlet NSMatrix * delimitedscope;
	IBOutlet NSTextField * delimitedrangefrom;
	IBOutlet NSTextField * delimitedrangeto;
	IBOutlet NSButton * delimitednumberorder;
	IBOutlet NSButton * delimitedappend;
	IBOutlet NSButton * delimitedincludedeleted;
	IBOutlet NSTextField * delimitedminfields;
	
	IBOutlet NSMatrix * formattedscope;
	IBOutlet NSTextField * formattedrangefrom;
	IBOutlet NSTextField * formattedrangeto;
	IBOutlet NSTextField * formattedpagerangefrom;
	IBOutlet NSTextField * formattedpagerangeto;
	IBOutlet NSMatrix * formattednewline;
	IBOutlet NSMatrix * formattedindent;
	IBOutlet NSTextField * formattedotherindent;
	IBOutlet NSButton * paragraphStyles;
	
	IBOutlet NSMatrix * taggedscope;
	IBOutlet NSTextField * taggedrangefrom;
	IBOutlet NSTextField * taggedrangeto;
	IBOutlet NSTextField * taggedpagerangefrom;
	IBOutlet NSTextField * taggedpagerangeto;
	IBOutlet NSMatrix * taggednewline;
}
- (IBAction)closePanel:(id)sender;
@end

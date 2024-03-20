//
//  ReplaceController.h
//  Cindex
//
//  Created by PL on 2/19/05.
//  Copyright 2005 Indexing Research. All rights reserved.
//

#import "SearchController.h"

@interface ReplaceController : SearchController {
	IBOutlet NSButton * replacebutton;
	IBOutlet NSButton * replaceallbutton;

	IBOutlet NSTextField * replacetext;
	IBOutlet NSPanel * replaceattributepanel;
	IBOutlet NSButton * replaceattributes;
	IBOutlet NSTextField * showreplaceattributes;
	
	IBOutlet NSMatrix * replacebold;
	IBOutlet NSMatrix * replaceitalic;
	IBOutlet NSMatrix * replaceunderline;
	IBOutlet NSMatrix * replacesmallcaps;
	IBOutlet NSMatrix * replacesuperscript;
	IBOutlet NSMatrix * replacesubscript;
	IBOutlet NSMatrix * changefont;
	IBOutlet NSPopUpButton * replacetextfont;	

	REPLACEGROUP rg;
	REPLACEATTRIBUTES ra;
	RECN repcount;
	RECN markcount;
}
- (IBAction)replace:(id)sender;
- (IBAction)replaceall:(id)sender;

@end

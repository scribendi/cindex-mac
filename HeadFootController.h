//
//  HeadFootController.h
//  Cindex
//
//  Created by PL on 1/9/05.
//  Copyright 2005 Indexing Research. All rights reserved.
//


@interface HeadFootController : NSWindowController {
	IBOutlet NSTabView * tab;
	
	IBOutlet NSTextField * lhleft;
	IBOutlet NSTextField * lhcenter;
	IBOutlet NSTextField * lhright;
	IBOutlet NSPopUpButton * lhfont;
	IBOutlet NSComboBox * lhcombo;
	IBOutlet NSButton * lhstyle;

	IBOutlet NSTextField * lfleft;
	IBOutlet NSTextField * lfcenter;
	IBOutlet NSTextField * lfright;
	IBOutlet NSPopUpButton * lffont;
	IBOutlet NSComboBox * lfcombo;
	IBOutlet NSButton * lfstyle;

	IBOutlet NSTextField * rhleft;
	IBOutlet NSTextField * rhcenter;
	IBOutlet NSTextField * rhright;
	IBOutlet NSPopUpButton * rhfont;
	IBOutlet NSComboBox * rhcombo;
	IBOutlet NSButton * rhstyle;

	IBOutlet NSTextField * rfleft;
	IBOutlet NSTextField * rfcenter;
	IBOutlet NSTextField * rfright;
	IBOutlet NSPopUpButton * rffont;
	IBOutlet NSComboBox * rfcombo;
	IBOutlet NSButton * rfstyle;
	
	IBOutlet NSMatrix * dateformat;
	IBOutlet NSButton * addtime;
	IBOutlet NSTextField * firstpage;
	IBOutlet NSPopUpButton * numberformat;
	IBOutlet NSButton * copy;
	
	PAGEFORMAT _hParams;
	PAGEFORMAT *_hParamPtr;
}
- (IBAction)copyPageSettings:(id)sender;
@end

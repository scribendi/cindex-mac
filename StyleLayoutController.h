//
//  StyleLayoutController.h
//  Cindex
//
//  Created by PL on 1/9/05.
//  Copyright 2005 Indexing Research. All rights reserved.
//


@interface StyleLayoutController : NSWindowController {
	IBOutlet NSMatrix *style;
	IBOutlet NSPopUpButton * heading;
	IBOutlet NSPopUpButton * variant;
	IBOutlet NSPopUpButton * collapseheading;
	IBOutlet NSButton * collapsebelow;

	IBOutlet NSPopUpButton * alignmenttype;
	IBOutlet NSPopUpButton * indenttype;
	IBOutlet NSPopUpButton * indentlevel;
	IBOutlet NSTextField * indentlead;
	IBOutlet NSTextField * indentrunover;
	IBOutlet NSPopUpButton * indentunit;
	IBOutlet NSBox * indentfieldbox;
	IBOutlet NSBox * indentsizesbox;

	IBOutlet NSPopUpButton * spacing;
	IBOutlet NSButton * autospace;
	IBOutlet NSTextField * spacesize;
	IBOutlet NSPopUpButton * spacingunit;
	IBOutlet NSTextField * mainheadspace;
	IBOutlet NSTextField * alphaspace;

	IBOutlet NSButton * quotepunct;
	IBOutlet NSButton * stylepunct;

	INDEXPARAMS * _ip;
	FORMATPARAMS _fParams;
	FORMATPARAMS * _fParamPtr;
	char *_indentunitptr;
	float * _leadindentptr;
	float * _runindentptr;
	short * _linespaceptr;
	int _currentunit;
	int _unit;
}
- (IBAction)setEnables:(id)sender;
@end

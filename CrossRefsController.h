//
//  CrossRefsController.h
//  Cindex
//
//  Created by PL on 1/9/05.
//  Copyright 2005 Indexing Research. All rights reserved.
//


@interface CrossRefsController : NSWindowController {
	IBOutlet NSTabView * tab;
	
	IBOutlet NSTextField * mseeprefix;
	IBOutlet NSTextField * mseealsoprefix;
	IBOutlet NSTextField * mseesuffix;
	IBOutlet NSTextField * mseealsosuffix;
	IBOutlet NSPopUpButton * mseeposition;
	IBOutlet NSPopUpButton * mseealsoposition;

	IBOutlet NSTextField * sseeprefix;
	IBOutlet NSTextField * sseealsoprefix;
	IBOutlet NSTextField * sseesuffix;
	IBOutlet NSTextField * sseealsosuffix;
	IBOutlet NSPopUpButton * sseeposition;
	IBOutlet NSPopUpButton * sseealsoposition;

	IBOutlet NSButton * prefixstyle;
	IBOutlet NSButton * prefixstylecheck;
	IBOutlet NSButton * bodystyle;
	IBOutlet NSButton * alphabetical;
	IBOutlet NSButton * suppressall;
	
	CROSSREFFORMAT _cParams;
	CROSSREFFORMAT * _cParamPtr;
}

@end

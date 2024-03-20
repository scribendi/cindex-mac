//
//  PageRefsController.h
//  Cindex
//
//  Created by PL on 1/9/05.
//  Copyright 2005 Indexing Research. All rights reserved.
//


@interface PageRefsController : NSWindowController {
	IBOutlet NSTextField * connecttext;
	IBOutlet NSPopUpButton * conflate;
	IBOutlet NSPopUpButton * abbrevrule;

	IBOutlet NSTextField * beforesingle;
	IBOutlet NSTextField * beforemultiple;
	IBOutlet NSTextField * after;
	IBOutlet NSButton * rightjustify;
	IBOutlet NSButton * dotleader;

	IBOutlet NSButton * suppressparts;
	IBOutlet NSTextField * suppressto;
	IBOutlet NSTextField * concatwith;

	IBOutlet NSButton * arrangesorted;
	IBOutlet NSButton * hideduplicates;
	IBOutlet NSButton * suppressall;
	IBOutlet NSButton * style;
	
	IBOutlet NSPanel * locatorstyle;
	IBOutlet NSPopUpButton * segment;
	IBOutlet NSMatrix * styles;
	IBOutlet NSMatrix * leadpunct;
	
	LOCATORFORMAT _lParams;
	LOCATORFORMAT * _lParamPtr;
	LSTYLE _lstyle[COMPMAX];
	int _currentsegment;
}
- (IBAction)showLeader:(id)sender;
- (IBAction)showSegment:(id)sender;
- (IBAction)showStylePanel:(id)sender;
- (IBAction)closeStylePanel:(id)sender;    
@end

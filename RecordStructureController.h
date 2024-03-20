//
//  RecordStructureController.h
//  Cindex
//
//  Created by PL on 1/9/05.
//  Copyright 2005 Indexing Research. All rights reserved.
//

@interface RecordStructureController : NSWindowController
{
	IBOutlet NSTextField * maxchars;
	IBOutlet NSTextField * usedchars;
	IBOutlet NSPopUpButton * minfields;
	IBOutlet NSPopUpButton * maxfields;
	IBOutlet NSButton * required;

	IBOutlet NSPopUpButton * field;
	IBOutlet NSTextField * fieldname;
	IBOutlet NSTextField * fieldmin;
	IBOutlet NSTextField * fieldmax;
	IBOutlet NSTextField * fieldcurrent;
	IBOutlet NSTextField * pattern;
	
	INDEX * FF;
	INDEXPARAMS	 _iParam;
	INDEXPARAMS	 * _iParamPtr;
	SORTPARAMS * _sParamPtr;
	COUNTPARAMS _cs;
	int _currentfield;
	int _oldmaxfields;
	int _minlength;
}
- (IBAction)changeField:(id)sender;
- (IBAction)changeNumberOfFields:(id)sender;
@end

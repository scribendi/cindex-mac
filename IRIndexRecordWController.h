//
//  IRIndexRecordWController.h
//  Cindex
//
//  Created by PL on 3/12/05.
//  Copyright 2005 Indexing Research. All rights reserved.
//

#import "IRIndexDocument.h"
#import "IRRecordView.h"

@interface IRIndexRecordWController : NSWindowController <NSWindowDelegate, NSToolbarDelegate, IRRecordViewDelegate, NSTextViewDelegate>{
	IBOutlet IRRecordView * _entry;
	IBOutlet NSTextView * _prompt;
	IBOutlet NSTextField * _entrydetails;
	IBOutlet NSTextField * _recordlength;
	IBOutlet NSMenu * _recordMenu;
	IBOutlet NSButton * _propagateButton;
	
	INDEX * FF;
	struct numstruct * _nptr;
	RECN _currentRecord;
	RECN _prevRecord;
	RECN _nextRecord;
	char _originalString[MAXREC];
	char * _revisedString;
	BOOL _deleted;
	int _labeled;
	BOOL _propagate;
	BOOL _originalDeleted;
	int _originalLabeled;
	BOOL _textDiffers;
	int _promptline[FIELDLIM];
	int _fieldcount;
	int _linetot;
	BOOL _allowFrameSet;
	BOOL _addMode;
	BOOL _dirty;
	NSDateFormatter * _dateformatter;
}
- (IBAction)duplicate:(id)sender;
- (IBAction)labeled:(id)sender;
- (IBAction)setPropagate:(id)sender;
- (BOOL)canAbandonRecord;
- (BOOL)canCompleteRecord;
- (IBAction)openRecord:(RECN)record;
- (void)checkFormatItems:(NSMenu *)menu;
- (void)displayError:(NSString *)error;
- (void)showStatus;
- (void)setDemoting;
@end

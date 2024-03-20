//
//  IRIndexDocWController.h
//  Cindex
//
//  Created by PL on 1/8/05.
//  Copyright 2005 Indexing Research. All rights reserved.
//
#import "IRIndexDocument.h"
#import "IRIndexView.h"
#import "IRIndexPrintView.h"

#import "SaveGroupController.h"
#import "GoToController.h"
//#import "VerifyRefsController.h"
#import "AlterRefsController.h"
#import "GenerateRefsController.h"
#import "ReconcileController.h"
#import "SplitController.h"
#import "CheckController.h"
#import "CompressController.h"
#import "CountController.h"
#import "StatisticsController.h"
#import "ManageFontController.h"
#import "GroupsController.h"
#import "FilterController.h"
#import "IRIndexView.h"

typedef struct {		/* for copying records as data object */
	RECN rtot;
	COUNTPARAMS cs;
	FONTMAP fm[FONTLIMIT];
	char array[];
} RECCOPY;


@interface IRIndexDocWController : NSWindowController <IRIndexViewDelegate, NSToolbarDelegate, NSLayoutManagerDelegate>{
    IBOutlet IRIndexView *_indexView;
	IBOutlet NSScrollView * _scrollView;
	IBOutlet NSClipView * _clipView;
	
	IBOutlet NSTextField * viewStats;
	IBOutlet NSTextField * viewError;
	IBOutlet NSTextField * searchString;
	IBOutlet NSProgressIndicator * progress;

	IBOutlet NSView * _scrollingView;
	
	INDEX * FF;
	BOOL _contextSort;
	PRIVATEPARAMS _contextPrivParams;
	RECN _contextTopRecord;
	NSRange _contextSelectedRecords;
	BOOL _addMode;
	
//	NSTextStorage * _recordStorage;
//	NSMutableArray * _layoutDescriptors;
	float _lastScrollPosition;
	float _rightCursorWidth;
	unsigned int _startLine;
	unsigned int _endLine;
	unsigned int _filledLines;
	unsigned int _viewCapacity;
	float _height;
	NSRect _displayRect;
	float _scrollLineHeight;
	NSMutableArray * _paragraphs;
	RECN _baseSelectionRecord;
	NSRange _selectedRecords;
	BOOL _allowFrameSet;
	RECN _visibleRecords;
//	double _filledHeight;
//	double _filledRecords;
	BOOL _stoppages;
	
	BOOL _needpage;
	BOOL _notdone;
	int _currententrylength;
	BOOL _brokenheading;
	int _overflow;
	unsigned int _writtenlimit;
}

- (void)updateDisplay;
- (NSRange)normalizedCharacterRange:(NSRange)range;
- (void)enableToolbarItems:(BOOL)enabled;
- (IRIndexPrintView *)printView;
- (void)setDisplayForEditing:(BOOL)opening adding:(BOOL)addmode;
- (BOOL)editingMode;
- (void)setSelectedRecords:(NSRange)recordrange;
- (NSRange)selectedRecords;
- (void)showRecord:(RECN)record position:(int)position;
- (void)selectRecord:(RECN)record range:(NSRange)range;
- (void)selectAllRecords;
- (void)copySelectionToPasteboard:(NSPasteboard *)pboard;
- (void)copySelectionToPasteboard:(NSPasteboard *)pboard forType:(NSString *)type;
- (BOOL)copyRecordsFromPasteboard:(NSPasteboard *)pb;
//- (NSRange)characterRangeForRecord:(RECN)record;
//- (BOOL)isVisibleRecord:(RECN)record;
- (float)rightCursorWidth;
//- (IBAction)getExportOptions:(id)sender;
- (void)displayError:(NSString *)error;
- (void)displaySearchString:(NSString *)search error:(BOOL)error;
- (RECN)stepRecord:(int)step from:(RECN)record;
@end

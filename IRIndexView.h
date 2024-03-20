//
//  IRIndexView.h
//  Cindex
//
//  Created by PL on 2/18/05.
//  Copyright 2005 Indexing Research. All rights reserved.
//

@class IRIndexDocument;

extern NSString * IRRecordsPBoardType;

@protocol IRIndexViewDelegate <NSObject>	// delegate methods for IRIndexView
- (void)showRecord:(RECN)record position:(int)position;
- (void)selectRecord:(RECN)record range:(NSRange)range;
- (void)copySelectionToPasteboard:(NSPasteboard *)pboard;
- (void)copySelectionToPasteboard:(NSPasteboard *)pboard forType:(NSString *)type;
- (BOOL)copyRecordsFromPasteboard:(NSPasteboard *)pb;
- (NSRange)selectedRecords;
- (void)selectAllRecords;
- (void)selectLowerRecords;
- (void)setSelectedRecords:(NSRange)recordrange;
//- (NSRange)characterRangeForRecord:(RECN)record;
- (NSRange)normalizedCharacterRange:(NSRange)range;
- (RECN)stepRecord:(int)step from:(RECN)record;
- (float)rightCursorWidth;
- (void)displayError:(NSString *)error;
- (void)displaySearchString:(NSString *)search error:(BOOL)error;
@end

@interface IRIndexView : NSTextView <NSPasteboardItemDataProvider,NSDraggingSource,NSDraggingDestination >{
//	id  <IRIndexViewDelegate, NSObject> _owner;
	unichar _searchstring[32];
	unichar * _stringptr, *_holdptr;
	BOOL _badstring;
	NSTimeInterval _lastkeytime, _currentkeytime;
	NSDragOperation _currentDragOperation;
	RECN _firstSelected;	// record at start of selection operation
	RECN _lastSelected;		// record at end of selection operation
	int _repeatdelay;
}
- (RECN)recordAtMouseLocationWithAttributes:(NSDictionary **)dicptr;	// returns record num & dictionary if wanted
//- (RECN)lastVisibleRecord:(NSDictionary **)dicptr;	// returns record num & dictionary if wanted
- (void)setFirstSelected:(RECN)base;		// sets first record of new selection
- (NSRange)characterRangeForRecord:(RECN)record;
@end

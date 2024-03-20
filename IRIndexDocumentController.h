//
//  IRIndexDocumentController.h
//  Cindex
//
//  Created by PL on 1/8/05.
//  Copyright 2005 Indexing Research. All rights reserved.
//

extern NSString * CIOpenFolder;
extern NSString * CIIndexFolder;
extern NSString * CIStyleSheetFolder;
extern NSString * CIBackupFolder;
extern NSString * CIAbbreviations;
extern NSString * CILastIndex;
extern NSString * CIXMLTagSet;
extern NSString * CISGMLTagSet;

@class FindController;
@class ReplaceController;
@class SpellController;
@class IRIndexDocument;

@interface IRIndexDocumentController : NSDocumentController <NSApplicationDelegate>{
	FindController * _findWindow;
	ReplaceController * _replaceWindow;
	SpellController * _spellWindow;
	NSWindow * _lastKeyWindow;
}
@property (weak) IRIndexDocument * IRrevertsource;

- (BOOL)loadStyleSheet:(STYLESHEET *)sp;
- (void)setAbbreviations:(NSMutableDictionary *)abbrev;
- (NSMutableDictionary *)abbreviations;
- (NSArray *)fonts;
- (NSPanel *)findPanel;
- (NSPanel *)replacePanel;
- (NSWindow *)lastKeyWindow;
@end

extern IRIndexDocumentController * IRdc;		// global for doc controller
//extern IRIndexDocument * IRrevertsource;		// source for reverting current document


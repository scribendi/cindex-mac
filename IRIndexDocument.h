//
//  IRIndexDocument.h
//  Cindex
//
//  Created by PL on 11/27/04.
//  Copyright Indexing Research 2004. All rights reserved.
//

#import "indexdocument.h"
#import "export.h"

typedef struct {
	NSString * __unsafe_unretained identifier;
	int tag;
	NSString * __unsafe_unretained label;
	NSString * __unsafe_unretained tooltip;
	id __unsafe_unretained target;
	NSString * __unsafe_unretained action;
	NSString * __unsafe_unretained image;
}TOOLBARITEM;

#define CIN_REF 	'CNDX'	/* creator */
#define CIN_NDX		'CDXU'	/* index file */
#define CIN_V2NDX	'CDXF'	/* v2 index file */
#define CIN_V1NDX	'NDXF'	/* v1 index file */
#define CIN_ABR		'ABRF'	/* abbrev file file */
#define CIN_FORM	'CFRU'	/* format (style) file */
#define CIN_V2FORM	'CFR2'	/* V2 format (style) file */
#define CIN_V1FORM	'CFRM'	/* V1 format (style) file */
#define CIN_STAT	'tDXU'	/* index stationery */
#define CIN_V2STAT	'tDXF'	/* v2 index stationery */
#define CIN_V1STAT	'sDXF'	/* v1 index stationery */
#define CIN_MDAT	'CDAM'	/* archive */
#define CIN_XMLDAT	'CXML'	// xml records
#define CIN_DBSPELL 'CDSP'	/* main spelling database */
#define CIN_DBUSER 	'CDSD'	/* user dictionary */
#define CIN_WILD	'????'	/* any type */
#define CIN_TEXT	'TEXT'	/* text */

extern NSString * IRDocumentException;
extern NSString * IRRecordException;	// damaged record
extern NSString * IRMappingException;

extern NSString * CINIndexType;
extern NSString * CINV2IndexType;
extern NSString * CINV1IndexType;
extern NSString * CINStationeryType;
extern NSString * CINV2StationeryType;
extern NSString * CINV1StationeryType;
extern NSString * CINArchiveType;
extern NSString * CINXMLRecordType;
extern NSString * CINAbbrevType;
extern NSString * CINStyleSheetType;
extern NSString * CINV2StyleSheetType;
extern NSString * CINV1StyleSheetType;
extern NSString * CINDataType;
extern NSString * DOSDataType;
extern NSString * CINDelimitedRecords;
extern NSString * SkyType;
extern NSString * MBackupType;

extern NSString * CINPlainTextType;
extern NSString * CINQuarkType;
extern NSString * CINInDesignType;
extern NSString * CINRTFType;
extern NSString * CINTaggedText;
extern NSString * CINIMType;

extern NSString * CINIndexExtension;
extern NSString * CINIndexV2Extension;
extern NSString * CINIndexV1Extension;
extern NSString * CINStationeryExtension;
extern NSString * CINArchiveExtension;
extern NSString * CINAbbrevExtension;
extern NSString * CINStyleSheetExtension;
extern NSString * CINV2StyleSheetExtension;
extern NSString * CINV1StyleSheetExtension;
extern NSString * CINTagExtension;
extern NSString * CINXMLTagExtension;
extern NSString * CINMainDicExtension;
extern NSString * CINPDicExtension;

extern NSString * NOTE_HEADERFOOTERCHANGED;
extern NSString * NOTE_REDISPLAYDOC;
extern NSString * NOTE_REVISEDLAYOUT;
extern NSString * NOTE_FONTSCHANGED;
extern NSString * NOTE_NEWKEYTEXT;
extern NSString * NOTE_INDEXWILLCLOSE;
extern NSString * NOTE_CONDITIONALOPENRECORD;
extern NSString * NOTE_PAGEFORMATTED;
//extern NSString * NOTE_AUTOSAVE;
extern NSString * NOTE_PREFERENCESCHANGED;
extern NSString * NOTE_GLOBALLYCHANGING;
extern NSString * NOTE_STRUCTURECHANGED;
extern NSString * NOTE_ACTIVEINDEXCHANGED;

extern NSString * NOTE_SCROLLKEYEVENT;


//notification dictionary keys
extern NSString * TextRangeKey;
extern NSString * TextLengthChangeKey;
extern NSString * RecordNumberKey;
extern NSString * RecordRangeKey;
extern NSString * ViewModeKey;
extern NSString * RecordAttributesKey;

@class IRIndexDocument;
@class IRIndexDocWController;
@class IRIndexTextWController;
@class IRIndexRecordWController;
@class SearchController;

#define MAPMARGIN 500	// file mapping record margin

enum 	{		/* view display flags */
	VD_CUR = 1,		/* redisplay from record at top of screen */
	VD_TOP = 2,		/* position target at top of screen (default unless screen empty at bottom) */
	VD_SELPOS = 4,	/* put in standard selection position */
	VD_MIDDLE = 8,	/* position target record in middle of screen */
	VD_BOTTOM = 16, /* position target at bottom of screen */
	VD_RESET = 32,	/* reset of all display params */
	VD_IMMEDIATE = 64,	/* redraw immediately */
	VD_SELECT = 128	// select target after display
};

@interface IRIndexDocument : NSDocument <NSOpenSavePanelDelegate> {
	IRIndexDocWController * _mainWindowController;
	IRIndexTextWController * _textWindowController;
	IRIndexRecordWController * _recordWindowController;
	INDEX _index;
	NSMenu * _groupmenu;
	NSMenu * _fieldmenu;
	EXPORTPARAMS _eparams;
	NSButton * _optionsButton;
	NSString * _backupPath;
	int _saveOp;
	BOOL _hasBackup;
	NSPopUpButton * _typeSelector;
	NSString * _selectedTypeForSaveToOperation;
	NSDictionary<NSString *, NSString *> * _exportTypeLabels;
}
@property (strong) NSWindowController * currentSheet;
@property (strong) NSString * lastSavedName;
@property (strong) IRIndexDocument * sumsource;
@property (strong) NSDate * modtime;
@property (strong) NSArray * gotoitems;
@property (strong) SearchController * currentSearchController;

//+ (id)newDocumentWithMessage:(NSString *)message error:(NSError **)err;		// creates new index file
+ (id)newDocumentFromURL:(NSURL *)url error:(NSError **)err;		// creates new index file

- (BOOL)readForbidden:(NSInteger)itemID;
- (IBAction)saveGroup:(id)sender;
- (IBAction)goTo:(id)sender;
- (IBAction)hideByAttribute:(id)sender;
//- (IBAction)verifyRefs:(id)sender;
- (IBAction)reconcile:(id)sender;
- (IBAction)generateRefs:(id)sender;
- (IBAction)alterRefs:(id)sender;
- (IBAction)compress:(id)sender;
- (IBAction)expand:(id)sender;
- (IBAction)count:(id)sender;
- (IBAction)statistics:(id)sender;
- (IBAction)groups:(id)sender;
- (IBAction)fonts:(id)sender;
- (IBAction)newGroup:(id)sender;
- (IBAction)newRecord:(id)sender;
- (IBAction)editRecord:(id)sender;
- (IBAction)duplicate:(id)sender;
- (IBAction)demote:(id)sender;
- (IBAction)deleted:(id)sender;
- (IBAction)labeled:(id)sender;
- (IBAction)removeMark:(id)sender;

- (void)setViewType:(int)type name:(NSString *)name;
- (int)viewType;
- (void)setViewFormat:(int)format;
- (int)viewFormat;
- (void)openRecord:(RECN)record;
- (BOOL)canCloseActiveRecord;
- (BOOL)closeIndex;

//- (id)initWithName:(NSString *)name hideExtension:(BOOL)hide error:(NSError **)err;	// creates new index with name
- (id)initWithName:(NSString *)name template:(NSURL *)template hideExtension:(BOOL)hide error:(NSError **)err;	// creates new index with name
//- (id)initForNewWithMessage:(NSString *)message error:(NSError **)err;	// creates new index file
- (id)initWithTemplateURL:(NSURL *)url error:(NSError **)outError;
//- (void)updateFromHeader:(HEAD *)header;
- (void)configurePrintInfo;
- (void)buildStyledStrings;
- (INDEX *)iIndex;
- (void)showText:(NSMutableAttributedString *)astring title:(NSString *)title;
- (void)closeText;
- (void)updateDisplay;
- (void)reformat;
- (void)redisplay:(RECN)record mode:(int)flags;
- (BOOL)formPageImages;
- (RECORD *)skip:(int)size from:(RECORD *)record;
- (RECN)normalizeRecord:(RECN)record;
- (NSRange)selectedRecords;
- (NSRange)selectionMaxRange;
- (void)selectRecord:(RECN)record range:(NSRange)range;
- (void)installGroupMenu;
- (void)setGroupMenu:menu;
- (NSMenu *)groupMenu:(BOOL)enabled;
- (void)installFieldMenu;
- (void)setFieldMenu:menu;
- (NSMenu *)fieldMenu;
- (void)checkEditItems:(NSMenu *)tmenu;
- (void)checkViewItems:(NSMenu *)menu;
- (void)checkFormatItems:(NSMenu *)menu;
- (BOOL)flush;
- (BOOL)resizeIndex:(int)newrecsize;
- (EXPORTPARAMS *)exportParameters;
- (IRIndexDocWController *)mainWindowController;
- (IRIndexRecordWController *)recordWindowController;
- (IRIndexTextWController *)textWindowController;
- (void)closeSummary;
- (void)hideWindows;		// hides all doc windows
- (void)showSheet:(NSWindowController *)sheet;
- (NSString *)fileNameExtensionForType:(NSString *)typeName saveOperation:(NSSaveOperationType)saveOperation;
@end

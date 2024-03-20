//
//  SearchController.h
//  Cindex
//
//  Created by PL on 2/19/05.
//  Copyright 2005 Indexing Research. All rights reserved.
//

#import "IRIndexDocument.h"

//#define MAXFINDSETS 4
#define FINDBOXSIZE 50

enum {
	TT_NOT,
	TT_FINDTEXT,
	TT_ATTRIBUTES,
	TT_ATTRIBUTESDISPLAY,
	TT_ANDOR,
	TT_FIELD,
	TT_EVALREF,
	TT_WORD,
	TT_CASE,
	TT_PATTERN
};

#define setindexfromtag(A) ((int)(A)/10)
#define notforset(A) 	([frow[(A)].fbox viewWithTag:(A)*10+0])
#define comboforset(A) 	([frow[(A)].fbox viewWithTag:(A)*10+1])
#define showattribsforset(A) 	([frow[(A)].fbox viewWithTag:(A)*10+3])
#define andorforset(A) 	([frow[(A)].fbox viewWithTag:(A)*10+4])
#define fieldmenuforset(A) 	([frow[(A)].fbox viewWithTag:(A)*10+5])
#define evalpageforset(A) 	([frow[(A)].fbox viewWithTag:(A)*10+6])
#define wholewordforset(A) 	([frow[(A)].fbox viewWithTag:(A)*10+7])
#define caseforset(A) 	([frow[(A)].fbox viewWithTag:(A)*10+8])
#define patternforset(A) 	([frow[(A)].fbox viewWithTag:(A)*10+9])

#define sendertype(A) 	([(A) tag]%10)

struct find_row {
    NSBox * __unsafe_unretained fbox;
};

@interface SearchController : NSWindowController {
	IBOutlet NSMatrix * recordscope;
	IBOutlet NSTextField * firstrecord;
	IBOutlet NSTextField * lastrecord;
	
	IBOutlet NSMatrix * datescope;
	IBOutlet NSTextField * firstdate;
	IBOutlet NSTextField * lastdate;
	
	IBOutlet NSTextField * userid;

	IBOutlet NSMatrix * amongtype;
	IBOutlet NSButton * amongnew;
	IBOutlet NSButton * amongmodified;
	IBOutlet NSButton * amongdeleted;
	IBOutlet NSButton * amongmarked;
	IBOutlet NSButton * amonggenerated;
	IBOutlet NSButton * amonglabeled;
	IBOutlet NSPopUpButton * label;	

	IBOutlet NSButton * findbutton;
	IBOutlet NSButton * findallbutton;
	IBOutlet NSButton * backward;

	IBOutlet NSBox * box0;
	IBOutlet NSBox * box1;
	IBOutlet NSBox * box2;
	IBOutlet NSBox * box3;
	
	IBOutlet NSPanel * attributepanel;
	IBOutlet NSMatrix * textstyle;
	IBOutlet NSMatrix * textoffset;
	IBOutlet NSPopUpButton * textfont;	

	IBOutlet NSPanel * findattributepanel;
	IBOutlet NSMatrix * findbold;
	IBOutlet NSMatrix * finditalic;
	IBOutlet NSMatrix * findunderline;
	IBOutlet NSMatrix * findsmallcaps;
	IBOutlet NSMatrix * findsuperscript;
	IBOutlet NSMatrix * findsubscript;
	IBOutlet NSMatrix * findfont;
	IBOutlet NSPopUpButton * findtextfont;

	LISTGROUP lg;
	struct find_row frow[MAXLISTS];
//	IRIndexDocument * _currentDocument;
	RECN _target;
	BOOL _restart;
	BOOL _needsSetup;
	INDEX * FF;
}
@property (weak) IRIndexDocument * currentDocument;
@property (assign) BOOL replaceEnabled;

- (IBAction)find:(id)sender;
- (IBAction)reset:(id)sender;		// triggered by a change in search params
- (IBAction)stop:(id)sender;
- (IBAction)doSetAction:(id)sender;
- (IBAction)closeFindSheet:(id)sender;
- (BOOL)canFindAgainInDocument:(IRIndexDocument *)doc;
- (BOOL)checkFindSettings;
- (BOOL)checkFindValid;
- (void)enableLocalButtons:(BOOL)enable;
- (void)setFindAttributes:(int)groupIndex;
- (void)setNewFind;
- (void)cleanup;
- (void)sizeForSets:(int)findsets;
- (void)resetGroup:(int)set;
- (LISTGROUP *)listgroup;
- (NSString *)searchString;
@end

//
//  IRRecordView.h
//  Cindex
//
//  Created by PL on 3/12/05.
//  Copyright 2005 Indexing Research. All rights reserved.
//

//#import "IRIndexDocument.h"
#import "indexdocument.h"
#import "regex.h"

enum {		/* save rules */
	M_SAVE,
	M_ASK,
	M_DISCARD
};

enum {		/* alarm flags */
	AL_OFF,
	AL_WARN,
	AL_REQUIRED
};

enum {		/* alarm indices */
	A_TEMPLATE,	/* template */
	A_PAGE,		/* page */
	A_CROSS,	// crossref
	A_CODE,		/* code */
	A_PAREN,	/* paren */
	A_SQBR,		/* square brackets */
	A_QUOTE,	// fancy quote
	A_DQUOTE,	// simple double quote
	ALARMTYPES	/* number of alarm types */
};

enum {		/* field errors */
	KEEPCS= 1,	/* bad code after ~ */
	ESCS,		/* bad code after \ */
	BRACES,		/* mismatched {} */
	BRACKETS,	/* mismatched <> */
	PAREN,		/* mismatched () */
	SQBR,		/* mismatched [] */
	QUOTE,		// mismatched fancy quotes
	DQUOTE,		// mismatched double quote
	CCODES		/* some incomplete code */
};

@protocol IRRecordViewDelegate <NSTextViewDelegate,NSDraggingDestination >	// delegate methods for IRRecordView
- (BOOL)canCompleteRecord;
- (void)displayError:(NSString *)error;
- (void)showStatus;
- (void)labeled:(id)sender;
@end

@interface IRRecordView : NSTextView {
	INDEX * FF;
	float _fontsize;
	char _originalString[MAXREC];
	char _newString[MAXREC+500];
	NSArray * _fieldRanges;
	unsigned int _fieldCount;
	unsigned int _protectIndex;	// index of first field that can't be split/joined
	int _recordLength;
	int _attributeChange;
	int _label;
	short _alarms[ALARMTYPES];	/* alarm flags for checks */
	URegularExpression * _regex[FIELDLIM];
	BOOL _locked;		// TRUE if won't release record
	BOOL _errDisplay;		// TRUE when error displayed
	FONTMAP _fontMap[FONTLIMIT];	// working copy of font map
}
- (IBAction)defaultFont:(id)sender;
- (void)setIndex:(INDEX *)indexptr;
- (void)setColorForLabel:(int)label;		// sets text color per label
- (void)selectField:(int)field;
- (void)setText:(char *)recordtext label:(int)label;
- (void)textViewDidChangeSelection:(NSNotification *)notification;
- (void)textViewDidChangeTypingAttributes:(NSNotification *)notification;
- (char *)getText:(BOOL)check;
- (int)textLength;
- (BOOL)checkErrors:(char *)rtext;
- (unsigned int)textAttributes:(NSDictionary *)attributes;
- (void)copyToFontMap:(FONTMAP *)fm;
@end



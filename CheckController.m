//
//  CheckController.h.m
//  Cindex
//
//  Created by PL on 4/29/18.
//  Copyright 2018 Indexing Research. All rights reserved.
//

#import "strings_c.h"
#import "tools.h"
#import "CheckController.h"
#import "commandutils.h"
#import "sort.h"
#import "records.h"

// static int tabset[] = {-40,48,100,0};

static char * verifyerrors[] = 	{	// verification error messages
	"",
	"too few targets",
	"circular or open",
	"missing target",
	"case/style/accent mismatch",
};

static char * errorstrings[] = {
	"Multiple spaces",		// currently unused
	"Misplaced or questionable punctuation",
	"Space missing before ( or [",
	"Unbalanced parens or brackets",
	"Unbalanced quotation marks",
	"Mixed case word(s)",
	"Misused special character",
	"Misused brackets",
	"Extraneous code",

	"Inconsistent letter case",
	"Inconsistent style/typeface",
	"Inconsistent punctuation",
	"Inconsistent leading conjunction/preposition",
	"Inconsistent plural ending",
	"Inconsistent trailing conjunction/preposition",
	"Inconsistent parenthetical ending",
	"Orphaned subheading",
	
	"Missing locator",
	"Too many page references",
	"Overlapping page references",
	"Locator not at lowest heading",
	
	"Invalid cross reference"
};

@interface CheckController () {
	IBOutlet NSTabView * checktab;
	
	IBOutlet NSButton * b_multiSpace;
	IBOutlet NSButton * b_punctSpace;
	IBOutlet NSButton * b_missingSpace;
	IBOutlet NSButton * b_unbalancedParen;
	IBOutlet NSButton * b_unbalancedQuote;
	IBOutlet NSButton * b_mixedCase;

	IBOutlet NSButton * h_inconsistentCaps;
	IBOutlet NSButton * h_inconsistentStyle;
	IBOutlet NSButton * h_inconsistentPunct;
	IBOutlet NSButton * h_inconsistentLeadPrep;
	IBOutlet NSButton * h_inconsistentEndingPlural;
	IBOutlet NSButton * h_inconsistentEndingPrep;
	IBOutlet NSButton * h_inconsistentEndingPhrase;
	IBOutlet NSButton * h_checkOrphans;
	IBOutlet NSPopUpButton * h_orphans;

	IBOutlet NSButton * l_missing;
	IBOutlet NSButton * l_tooMany;
	IBOutlet NSTextField * l_limit;
	IBOutlet NSButton * l_headinglevel;
	IBOutlet NSButton * l_overlapping;

	IBOutlet NSButton * c_verify;
	IBOutlet NSButton * c_exactMatch;
	IBOutlet NSTextField * c_minMatches;

	INDEX * FF;
	CHECKPARAMS _cParam;
}
@end

@implementation CheckController
- (id)init	{
    self = [super initWithWindowNibName:@"CheckController"];
    return self;
}
- (void)awakeFromNib {
	[super awakeFromNib];
	FF = [self.document iIndex];
	[h_orphans removeAllItems];
	for (int count = 0; count < FF->head.indexpars.maxfields-1; count++)	/* for all fields */
		[h_orphans addItemWithTitle:[NSString stringWithCString:FF->head.indexpars.field[count].name encoding:NSUTF8StringEncoding]];
	NSData * cd = [[NSUserDefaults standardUserDefaults] objectForKey:@"checkParams"];
	if (cd && cd.length == sizeof(CHECKPARAMS)) {	// set defaults if they're good
		_cParam = *(CHECKPARAMS *)cd.bytes;
		[h_orphans selectItemAtIndex:_cParam.jng.firstfield];
		[l_limit setIntValue:_cParam.pagereflimit];
		[c_minMatches setIntValue:_cParam.vg.lowlim];
		c_exactMatch.state = _cParam.vg.fullflag;
		BOOL * rKeyPtr = _cParam.reportKeys;
		b_multiSpace.state = *rKeyPtr++;	// !! currently unused
		b_punctSpace.state = *rKeyPtr++;
		b_missingSpace.state = *rKeyPtr++;
		b_unbalancedParen.state = *rKeyPtr++;
		b_unbalancedQuote.state = *rKeyPtr++;
		b_mixedCase.state = *rKeyPtr++;
		*rKeyPtr++ = YES;		// misused escape
		*rKeyPtr++ = YES;		// misued brackets
		*rKeyPtr++ = YES;		// bad code
		
		h_inconsistentCaps.state = *rKeyPtr++;
		h_inconsistentStyle.state = *rKeyPtr++;
		h_inconsistentPunct.state = *rKeyPtr++;
		h_inconsistentLeadPrep.state = *rKeyPtr++;
		h_inconsistentEndingPlural.state = *rKeyPtr++;
		h_inconsistentEndingPrep.state = *rKeyPtr++;
		h_inconsistentEndingPhrase.state = *rKeyPtr++;
		h_checkOrphans.state = *rKeyPtr++;
		
		l_missing.state = *rKeyPtr++;
		l_tooMany.state = *rKeyPtr++;
		l_overlapping.state = *rKeyPtr++;
		l_headinglevel.state = *rKeyPtr++;
		
		c_verify.state = *rKeyPtr++;
	}
}
- (void)dealloc {
	[[NSNotificationCenter defaultCenter] removeObserver:self];
}
- (void)windowDidUpdate:(NSNotification *)aNotification {
	if (c_verify.state) {	// if verify enabled
		c_exactMatch.enabled = YES;
		c_minMatches.enabled = YES;
	}
	else {
		c_exactMatch.enabled = NO;
		c_minMatches.enabled = NO;
	}
	h_orphans.enabled = h_checkOrphans.state;
}
- (IBAction)showHelp:(id)sender {
	NSInteger index = [checktab indexOfTabViewItem:[checktab selectedTabViewItem]];
	NSString * anchor;
	
	if (index == 0)
		anchor = @"checkindex0_Anchor-14210";
	else if (index == 1)
		anchor = @"checkindex1_Anchor-14210";
	else
		anchor = @"checkindex2_Anchor-14210";
	[[NSHelpManager sharedHelpManager] openHelpAnchor:anchor inBook:@"Cindex 4.2.5 Help"];
}
- (IBAction)closePanel:(id)sender {
	if ([sender tag] == OKTAG)	{
		if (![[self window] makeFirstResponder:[self window]])
			return;		//error failure
		BOOL * rKeyPtr = _cParam.reportKeys;
		*rKeyPtr++ = b_multiSpace.state;		// !! currently unused
		*rKeyPtr++ = b_punctSpace.state;
		*rKeyPtr++ = b_missingSpace.state;
		*rKeyPtr++ = b_unbalancedParen.state;
		*rKeyPtr++ = b_unbalancedQuote.state;
		*rKeyPtr++ = b_mixedCase.state;
		*rKeyPtr++ = YES;		// misused escape
		*rKeyPtr++ = YES;		// misued brackets
		*rKeyPtr++ = YES;		// bad code

		*rKeyPtr++ = h_inconsistentCaps.state;
		*rKeyPtr++ = h_inconsistentStyle.state;
		*rKeyPtr++ = h_inconsistentPunct.state;
		*rKeyPtr++ = h_inconsistentLeadPrep.state;
		*rKeyPtr++ = h_inconsistentEndingPlural.state;
		*rKeyPtr++ = h_inconsistentEndingPrep.state;
		*rKeyPtr++ = h_inconsistentEndingPhrase.state;
		*rKeyPtr++ = h_checkOrphans.state;

		*rKeyPtr++ = l_missing.state;
		*rKeyPtr++ = l_tooMany.state;
		*rKeyPtr++ = l_overlapping.state;
		*rKeyPtr++ = l_headinglevel.state;

		*rKeyPtr++ = c_verify.state;

		_cParam.errors = calloc(FF->head.rtot+1,sizeof(CHECKERROR *));
		_cParam.pagereflimit = [l_limit intValue];
		
		_cParam.vg.lowlim = [c_minMatches intValue];
		_cParam.vg.fullflag = c_exactMatch.state;
		_cParam.vg.locatoronly = FF->head.refpars.clocatoronly;
		
		_cParam.jng.nosplit = TRUE;
		_cParam.jng.firstfield = (int)[h_orphans indexOfSelectedItem];
		_cParam.jng.orphanaction = OR_PRESERVE;
		_cParam.jng.errors = _cParam.errors;
//		_cParam.jng.orphans = nil;	// !!** need this while  method still available through old 'Reconcile Headings'

		[[self document] closeText];
		tool_check(FF, &_cParam);
		NSMutableAttributedString * checklist = [[NSMutableAttributedString alloc] init];
		for (RECORD * curptr = sort_top(FF); curptr; curptr = sort_skip(FF,curptr,1)) {
			CHECKERROR * ebase = _cParam.errors[curptr->num];
			if (ebase) {	// if any errors recorded
				char rbase[MAXREC];
				int errorCount = 0;
				char * pos = rbase;
				for (int findex = 0; findex < FF->head.indexpars.maxfields; findex++) {
					if (ebase->fields[findex]) {	// if errors
						for (int bitpos = 0; bitpos < 31; bitpos++) {	// for all potential errors
							if (ebase->fields[findex]&(1 << bitpos) && _cParam.reportKeys[bitpos])	{	// if error and want to see it
								char * fname = FF->head.indexpars.field[findex < FF->head.indexpars.maxfields-1 ? findex : PAGEINDEX].name;
								char message[MAXREC];
								if ((1 << bitpos) == CE_CROSSERR)	{	// if a crossref error, create description
									for (VERIFY * ceptr = ebase->crossrefs; ceptr->error; ceptr++)	{	// for all errors
										char * typeerror = "";		// default no type error
										bool wrongtype = ceptr->error&V_TYPEERR;
										ceptr->error &= ~ V_TYPEERR;	// clear type flag
										if (wrongtype)
											typeerror = ceptr->error ? "wrong type and " : "wrong type";
										sprintf(message,"Cross reference from “%s” to “%.*s”: %s%s",curptr->rtext,ceptr->length,curptr->rtext+ceptr->offset,typeerror, verifyerrors[ceptr->error]);
									}
								}
								else if ((1 << bitpos) == CE_TOOMANYPAGE)	// if re count error
									sprintf(message,"Too many references (%d) to “%s”",ebase->refcount,curptr->rtext);
								else	// other error; just show string
									strcpy(message,errorstrings[bitpos]);
								if (!errorCount)
									pos += sprintf(rbase,"\t%u\t%s: %s",curptr->num, fname,message);	// lead for record, with error report
								else 	// start a new error field
									pos += sprintf(pos, "%s\t%s: %s",LINEBREAK,fname,message);	// lead for field, with error report
								errorCount++;
							}
						}
					}
				}
				if (ebase->crossrefs)
					free(ebase->crossrefs);
				free(ebase);
				if (errorCount) {
					*pos++ = '\r';
					*pos++ = '\0';
					[checklist appendAttributedString:[NSAttributedString asFromXString:rbase fontMap:NULL size:0 termchar:0]];
				}
			}
		}
		free(_cParam.errors);
		if (checklist.length) {
			[checklist setTabsForRecordCount:FF->head.rtot];
			[[self document] showText:checklist title:@"Index Check Results"];
		}
		else
			infoSheet(((IRIndexDocument *)self.document).windowForSheet, CHECKINFO);
		[[NSUserDefaults standardUserDefaults] setObject:[NSData dataWithBytes:&_cParam length:sizeof(CHECKPARAMS)] forKey:@"checkParams"];
//		[[self document] redisplay:0 mode:0];	// redisplay all records
	}
	[self.window.sheetParent endSheet:self.window returnCode:[sender tag]];
}
@end


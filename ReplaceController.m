//
//  ReplaceController.m
//  Cindex
//
//  Created by PL on 2/19/05.
//  Copyright 2005 Indexing Research. All rights reserved.
//

#import "IRIndexDocumentController.h"
#import "IRIndexDocWController.h"
#import "ReplaceController.h"
#import "FindController.h"
#import "commandutils.h"
#import "type.h"
#import "records.h"
#import "search.h"
#import "strings_c.h"
#import "regex.h"


NSString * IRWindowReplace = @"ReplaceWindow";

static struct numstruct * repset(INDEX * FF, LISTGROUP * lg, REPLACEGROUP * rg, REPLACEATTRIBUTES *rap, char * replace);	/* sets up structures */
static void setreplacestyle(NSMatrix * control,REPLACEATTRIBUTES *ra, int index,int enabled);	// sets replace style
static void recoverreplacestyle(NSMatrix * control,REPLACEATTRIBUTES *ra,int index);

@interface ReplaceController () {
	struct numstruct *nptr;	/* numstruct array for resorting */
	short offset,mlength;
}
@end

@implementation ReplaceController
- (id)init	{
	if (self = [super initWithWindowNibName:@"ReplaceController"]) {
		lg.size = 1;
		self.replaceEnabled = YES;
	}
    return self;
}
- (void)awakeFromNib {
	[super awakeFromNib];
    [[self window] setFrameAutosaveName:IRWindowReplace];
	[replacetextfont addItemsWithTitles:[IRdc fonts]];
}
- (void)showWindow:(id)sender {
	NSPanel * findPanel = [IRdc findPanel];

	if (findPanel && [findPanel isVisible])	{	// if have visible find panel
		NSRect frect = [findPanel frame];
		
		frect.origin.y += frect.size.height;	// make top left point
		[[self window] setFrameTopLeftPoint:frect.origin];
		[comboforset(0) setStringValue:[(SearchController *)[findPanel delegate] searchString]];
	}
	[comboforset(0) selectText:self];
	[super showWindow:sender];
	[findPanel orderOut:nil];	// hide any find panel
}
- (void)windowDidResignKey:(NSNotification *)aNotification {
	[self cleanup];	// force sort, etc. as necessary
	[replacebutton setEnabled:NO];
	offset = mlength = 0;		// force new search of string in any current record
}
-(void)enableLocalButtons:(BOOL)enable {
	if (enable && [self checkReplaceSettings] && ![self.currentDocument recordWindowController]) {
		[findbutton setEnabled:YES];
		[replaceallbutton setEnabled:YES];
	}
	else {
		[findbutton setEnabled:NO];
		[replacebutton setEnabled:NO];
		[replaceallbutton setEnabled:NO];
	}
}
- (IBAction)showHelp:(id)sender {
	[[NSHelpManager sharedHelpManager] openHelpAnchor:@"rep0_Anchor-14210" inBook:@"Cindex 4.2.5 Help"];
}
- (void)setNewFind {
	[super setNewFind];
	[replacebutton setEnabled:NO];
	offset = 0;
	mlength = 0;
	repcount = 0;
	markcount = 0;
}
- (void)cleanup {
	if (nptr)	{		/* if have some replacements */
		sort_resortlist(FF,nptr);		/* make new nodes */
		free(nptr);
		nptr = NULL;
		[FF->owner redisplay:0 mode:VD_CUR];
	}
}
- (BOOL)checkReplaceSettings {
	NSString * cs = [comboforset(0) stringValue];
	int tlen = (int)[cs length];
	int trlen = (int)[[replacetext stringValue] length];
	
	if (trlen < STSTRING && tlen < LISTSTRING && (tlen && (trlen || !ra.onstyle && !ra.offstyle && !ra.fontchange)		/* if find target & (rep target || no style or font) */
		  || !tlen && (lg.lsarray[0].style || lg.lsarray[0].font || lg.lsarray[0].forbiddenstyle || lg.lsarray[0].forbiddenfont) && !trlen
		  && (ra.onstyle || ra.offstyle || ra.fontchange)))	{	/* or no targets and just fonts/styles */
		strcpy(lg.lsarray[0].string,[cs UTF8String]);
		return TRUE;
	}
	return FALSE;
}
- (IBAction)doSetAction:(id)sender {
	if (sender == replaceattributes)	{	// replace attributes
		setreplacestyle(replacebold,&ra,0,lg.lsarray[0].style&FX_BOLD);
		setreplacestyle(replaceitalic,&ra,1,lg.lsarray[0].style&FX_ITAL);
		setreplacestyle(replaceunderline,&ra,2,lg.lsarray[0].style&FX_ULINE);
		setreplacestyle(replacesmallcaps,&ra,3,lg.lsarray[0].style&FX_SMALL);
		setreplacestyle(replacesuperscript,&ra,4,lg.lsarray[0].style&FX_SUPER);
		setreplacestyle(replacesubscript,&ra,5,lg.lsarray[0].style&FX_SUB);
		[changefont selectCellWithTag:ra.fontchange];
		if (ra.fontchange) {
			[replacetextfont setEnabled:YES];
			int ii = [replacetextfont indexOfItemWithTitle:[NSString stringWithCString:ra.font encoding:NSUTF8StringEncoding]];
			if (ii < 0)		// if wanted (unnameed) default font
				ii = 0;
			[replacetextfont selectItemAtIndex:ii];
		}
		else {
			[replacetextfont selectItemAtIndex:-1];
			[replacetextfont setEnabled:NO];
		}
		[self.window beginSheet:replaceattributepanel completionHandler:^(NSInteger result) {
			if (result == OKTAG){
				;
			}
		}];
	}
	else if (sender == replacesuperscript) {
		if (replacesuperscript.selectedCell.tag == 1 && replacesubscript.selectedCell.tag == 1)	// if both would be enabled
			[replacesubscript selectCellWithTag:0];	// disable subscript
	}
	else if (sender == replacesubscript) {
		if (replacesubscript.selectedCell.tag == 1 && replacesuperscript.selectedCell.tag == 1)	// if both would be enabled
			[replacesuperscript selectCellWithTag:0];	// disable superscript
	}
	else if (sender == changefont) {
		[replacetextfont selectItemAtIndex:[[sender selectedCell] tag] ? 0 : -1];
		[replacetextfont setEnabled:[[sender selectedCell] tag]];
	}
	else	// do the find settings
		[super doSetAction:(id)sender];
}
- (IBAction)closeFindSheet:(id)sender {
	[super closeFindSheet:sender];
	ra.offstyle &= lg.lsarray[0].style;	/* adjust permitted removal styles */
	[showreplaceattributes setStringValue:attribdescriptor(ra.onstyle,ra.fontchange,ra.offstyle,0)];
}
- (IBAction)closeReplaceSheet:(id)sender {
	if ([sender tag] == OKTAG)	{
		ra.fontchange = [[changefont selectedCell] tag];
		if (ra.fontchange && [replacetextfont indexOfSelectedItem])
			strcpy(ra.font,(char *)[[replacetextfont titleOfSelectedItem] UTF8String]);
		else
			*ra.font = '\0';
		ra.onstyle = ra.offstyle = 0;
		recoverreplacestyle(replacebold,&ra,0);
		recoverreplacestyle(replaceitalic,&ra,1);
		recoverreplacestyle(replaceunderline,&ra,2);
		recoverreplacestyle(replacesmallcaps,&ra,3);
		recoverreplacestyle(replacesuperscript,&ra,4);
		recoverreplacestyle(replacesubscript,&ra,5);
		[showreplaceattributes setStringValue:attribdescriptor(ra.onstyle,ra.fontchange,ra.offstyle,0)];
		[self setNewFind];
	}
	[self.window endSheet:[sender window] returnCode:[sender tag]];
	[[self window] makeKeyWindow];
}

- (IBAction)find:(id)sender {
	if ([self.currentDocument canCloseActiveRecord] && (_target || [self checkFindValid])) {
		RECORD * recptr = NULL;
		char * sptr = NULL;	// no target string
	
		if (_target && (recptr = rec_getrec(FF,_target)))		{	/* if already have a target */
			sptr = recptr->rtext+offset;		// set offset for search
//			if (!*sptr)	// if we've not previously matched real text, don't look for more in this record
//				sptr = NULL;
		}
		if (!sptr || !(sptr = search_findbycontent(FF,recptr, sptr+mlength, &lg, &mlength)))	 {	// if no more matches in this record
			do {
				recptr = search_findfirst(FF,&lg,_restart,&sptr,&mlength);		/* while target in invis part of rec */
			} while (recptr && !(sptr = vistarget(FF,recptr,sptr,&lg, &mlength, TRUE)));
		}
		if (recptr)	{
			offset = sptr-recptr->rtext;
			_restart = FALSE;		/* can proceed with search */
			_target = recptr->num;
			[findbutton setTitle:@"Find Again"];
			[replacebutton setEnabled:YES];
			[self.currentDocument selectRecord:_target range:NSMakeRange(sptr-recptr->rtext,str_utextlen(sptr,mlength))];
//			[[[_currentDocument mainWindowController] window] makeKeyWindow];
			return;
		}
		else if (_restart)		{	/* if we've had a completely failed search */
			[self.currentDocument selectRecord:0 range:NSMakeRange(0,0)];	// clear selection
			errorSheet(self.window,RECNOTFOUNDERR, WARN);
		}
		else	/* found something */
			sendinfo(NOMORERECINFO);		/* done */
		[self setNewFind];		// reinitialize after failure
	}
}
- (IBAction)replace:(id)sender {
	char dupcopy[MAXREC], *sptr = NULL;
	RECORD * recptr = NULL;
	
	if (_target && (recptr = rec_getrec(FF,_target)))		/* if already have a target */
		sptr = recptr->rtext+offset;
	if (sptr && (nptr || (nptr = repset(FF,&lg,&rg,&ra,(char *)[[replacetext stringValue] UTF8String]))))	{	/* if have/can set up structures */
		str_xcpy(dupcopy, recptr->rtext);		/* save copy */
		if (sptr = search_reptext(FF,recptr, sptr, mlength, &rg, &lg.lsarray[0])) {		// if replaced
			int pcount;
			
			long oxlen = str_xlen(recptr->rtext);
			long xlen = str_adjustcodes(recptr->rtext,CC_TRIM|(g_prefs.gen.remspaces ? CC_ONESPACE : 0));	/* clean up codes */
			sptr -= oxlen-xlen;	// adjust ptr for any stripped codes (assumes any redundant codes will have been added in this replacement)
			if (!*sptr)	// if at end of field
				sptr++;	// force skip to next
			rec_strip(FF,recptr->rtext);		/* remove empty fields */
			sort_addtolist(nptr,recptr->num);	/* add to sort list */
			pcount = rec_propagate(FF,recptr,dupcopy, nptr);	/* propagate */
			[FF->owner updateDisplay];
			repcount += pcount+1;
			offset = sptr-recptr->rtext;	// set for char beyond replacement
			mlength = 0;	// now redundant clear
			[self find:self];	// get next
		}
		else	{	/* record too long */
			markcount++;
			NSBeep();
		}
	}
}
- (IBAction)replaceall:(id)sender {
	char *tptr = NULL, *sptr = NULL;
	RECORD * recptr = NULL;
	
	if (!_target)		// if don't have target
		[self find:self];		// try to find one
	if (_target && (recptr = rec_getrec(FF,_target)))		/* if have a target */
		sptr = recptr->rtext+offset;
	if (sptr && (nptr || (nptr = repset(FF,&lg,&rg,&ra,(char *)[[replacetext stringValue] UTF8String]))))	{	/* if have target & have/can set up structures */
		do {
			while (sptr && (tptr = search_reptext(FF,recptr, sptr, mlength, &rg, &lg.lsarray[0])))	{	/* while can replace a target */
				long oxlen = str_xlen(recptr->rtext);
				long xlen = str_adjustcodes(recptr->rtext,CC_TRIM|(g_prefs.gen.remspaces ? CC_ONESPACE : 0));	/* clean up codes */
				tptr -= oxlen-xlen;	// adjust ptr for any stripped codes (assumes any redundant codes will have been added in this replacement)
				if (!*tptr)	// if at end of field
					tptr++;	// force skip to next
				repcount++;
				sort_addtolist(nptr,recptr->num);		/* add to sort list */
//				if (!*sptr)			// if we have an empty field after replacement, don't look for more
//					break;
				sptr = search_findbycontent(FF, recptr,tptr, &lg, &mlength); /* more in current record? */
			}
			if (sptr && !tptr)		/* if couldn't make a replacement */
				markcount++;
//			str_adjustcodes(recptr->rtext,CC_TRIM|(g_prefs.gen.remspaces ? CC_ONESPACE : 0));	/* clean up codes */
			rec_strip(FF,recptr->rtext);		/* remove empty fields */
		} while ((recptr = search_findfirst(FF,&lg,FALSE,&sptr, &mlength)));
		[self cleanup];		// resort & redisplay if any replacements
		if (markcount)	/* if some marked records */
			infoSheet(FF->owner.windowForSheet,REPLACEMARKEDINFO,repcount,markcount);
		else	
			infoSheet(FF->owner.windowForSheet,REPLACECOUNTINFO,repcount);
		[[self window] performClose:self];
		[self setNewFind];	// always re-initialize after replace all
	}
}
- (IBAction)stop:(id)sender {
	[super stop:sender];
	[replacetext setObjectValue:nil];
	ra.onstyle = ra.offstyle = 0;
	*ra.font = '\0';
	[showreplaceattributes setObjectValue:nil];
	lg.size = 1;
	[self setNewFind];
}
@end
/******************************************************************************/
struct numstruct * repset(INDEX * FF, LISTGROUP * lg, REPLACEGROUP * rg, REPLACEATTRIBUTES *rap, char * replace)	/* sets up structures */

{
	char *tptr, c;
	
	memset(rg,0,sizeof(REPLACEGROUP));	/* initialize */
	strcpy(rg->sourcestring, replace);	/* replacement string. We'll tinker with it */
	u8_normalize(rg->sourcestring, strlen(rg->sourcestring)+1);		// normalize to composed characters
	rg->regex = lg->lsarray[0].regex;
	rg->ra = *rap;		/* copy text attributes */
	if ((rg->ra.onstyle || rg->ra.offstyle || rg->ra.fontchange) && !*lg->lsarray[0].string)	{	/* if replacing style or font & no search target */
		rg->reptot = 1;		/* mark one replacement */
		rg->rep[0].index = 0;	// set replacement to capture group 0 (full match)
	}
	else {	/* some actual text/pattern being replaced */
		for (tptr = rg->sourcestring; *tptr && rg->reptot < SREPLIM; rg->reptot++)	{	/* extract parts of substitution string */
			for (rg->rep[rg->reptot].start = tptr; *tptr; tptr++)	{ /* while in string */
				if (lg->lsarray[0].patflag && *tptr == ESCCHR)	{	/* if pattern & escape with following char */
					if (isdigit(c = *(tptr+1)) && c != '0' || c == '&') {	/* if special replacement	*/
						if (!rg->rep[rg->reptot].len)	 {	/* if haven't been building an ordinary string */
							if (c == '&')
								c = '0';	// capture group 0 is whole string
							if ((rg->rep[rg->reptot].index = c - '0') > regex_groupcount(lg->lsarray[0].regex))	 { /* put in index; if not that many subexpressions */
								senderr(BADREPERR, WARN);
								return (NULL);
							}
							tptr += 2;	/* now points to char beyond string designator */
							if (*tptr == '+' || *tptr == '-')		  /* if want case change */
								rg->rep[rg->reptot].flag = *tptr++ == '+' ? 1 : -1;	  /* put in flag and skip over sign */
							rg->rep[rg->reptot].start = NULL;		/* indicates a special replacement */
						}
						break;	/* force up one component */
					}
					else {
						if (!*(tptr+1))		/* if dangling \ on end of line */
							continue;		/* will ignore */
						memmove(tptr, tptr+1, strlen(tptr));	/* shift over esc char */
					}
				}
				rg->rep[rg->reptot].len++;		/* count one char in replacement string */
			}
		}
	}
	rg->maxlen = FF->head.indexpars.recsize-1;
    return sort_setuplist(FF);		/* if can set up sort list */
}
/******************************************************************************/
static void setreplacestyle(NSMatrix * control,REPLACEATTRIBUTES *ra, int index,int enabled)	// sets replace style

{
	if (enabled) {		// if could remove style
		[[control cellWithTag:2] setEnabled:YES];
		if (ra->offstyle&(1 << index)) 	// off style
			[control selectCellWithTag:2];
	}
	else {		// disable/clear remove style
		[control selectCellWithTag:0];
		[[control cellWithTag:2] setEnabled:NO];
		ra->offstyle &= ~(1 << index);	// clear attribute
	}
	if (ra->onstyle&(1 << index))		// add style
		[control selectCellWithTag:1];
}
/******************************************************************************/
static void recoverreplacestyle(NSMatrix * control,REPLACEATTRIBUTES *ra, int index)	// recovers replace style
			
{
	if ([[control selectedCell] tag] == 1)	{// if on
		ra->onstyle |= (1 << index);
	}
	if ([[control selectedCell] tag] == 2)	{	// if off
		ra->offstyle |= (1 << index);
	}
}

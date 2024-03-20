//
//  SearchController.m
//  Cindex
//
//  Created by PL on 2/19/05.
//  Copyright 2005 Indexing Research. All rights reserved.
//

#import "IRIndexDocumentController.h"
#import "IRIndexDocWController.h"
#import "SearchController.h"
#import "cindexmenuitems.h"
#import "commandutils.h"
#import "type.h"
#import "records.h"
#import "search.h"
#import "group.h"
#import "strings_c.h"


enum {		// among tags
	F_NEWRECS = 0,
	F_MODRECS,
	F_DELRECS,
	F_MARKEDRECS,
	F_GENRECS,
	F_LABELRECS
};

@interface SearchController () {
	NSRect _fullFrame;
	int _currentsetindex;
	id lastClient;;
	NSMenu * fieldMenu;
}

@end

@implementation SearchController
-(void)dealloc {
	[[NSNotificationCenter defaultCenter] removeObserver:self];
}
- (void)awakeFromNib {
	[super awakeFromNib];
	frow[0].fbox = box0;
	frow[1].fbox = box1;
	frow[2].fbox = box2;
	frow[3].fbox = box3;
	_fullFrame = [[self window] frame];		// base frame
	[self setShouldCascadeWindows:NO];
    [[self window] setExcludedFromWindowsMenu:YES];
	fieldMenu = [[[self window] fieldEditor:YES forObject:nil] menu];
	addregexitems(fieldMenu);
	[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(_activeIndexChanged:) name:NOTE_ACTIVEINDEXCHANGED object:nil];
	[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(_indexClosing:) name:NOTE_INDEXWILLCLOSE object:nil];
	[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(_globallyChanging:) name:NOTE_GLOBALLYCHANGING object:nil];
}
- (LISTGROUP *)listgroup {
	return &lg;
}
- (void)sizeForSets:(int)findsets {
	int index;
	float height, heightchange;
	NSRect wrect;
	
	[[self window] setAutodisplay:NO];		// prevent updates while adjusting
	for (index = 1; index < MAXLISTS; index++)	{	// for all boxes beyond first
		if (index < findsets && index >= lg.size)	// if to be visible and not already visible
			[self resetGroup:index];		// reset interface to default
		[frow[index].fbox setHidden:index >= findsets];
	}
	[[self window] makeFirstResponder:comboforset(findsets-1)];
	wrect = [[self window] frame];
	height = _fullFrame.size.height-FINDBOXSIZE*(MAXLISTS-findsets);
	heightchange = wrect.size.height-height;
	wrect.size.height = height;
	wrect.origin.y += heightchange;
	[[self window] setFrame:wrect display:YES];
	[[self window] setAutodisplay:YES];		// enable updates after adjusting
	lg.size = findsets;
}
- (void)setRegex:(id)sender	{
	NSView * cview = (NSView *)[[self window] firstResponder];	// get text view
	[cview insertText:regexfortag([sender tag])];
	for (int set = 0; set < lg.size; set++)	{	// find the set for the menu
		if ([cview isDescendantOf:comboforset(set)]) {
			[patternforset(set) setState:YES];
			[caseforset(set) setState:YES];
			[evalpageforset(set) setState:NO];
			[evalpageforset(set) setEnabled:NO];
			break;
		}
	}
}
- (void)showWindow:(id)sender {
	if (![[self window] isVisible])	{	// if not on screen
		if (self.currentDocument != [IRdc currentDocument])	{	// full setup
			self.currentDocument = [IRdc currentDocument];
			_needsSetup = TRUE;
		}
		else
			[self setNewFind];	// just start new
	}
	[super showWindow:sender];
}
- (void)windowDidBecomeKey:(NSNotification *)aNotification {
	_currentDocument.currentSearchController = self;
}
- (void)windowDidUpdate:(NSNotification *)aNotification {
	if (_currentDocument) {
		if (_needsSetup) {		// window has just become key
			int set;
			
			FF = [_currentDocument iIndex];
			for (set = 0; set < lg.size; set++)
				buildfieldmenu(FF, fieldmenuforset(set));
			[self setNewFind];	// set up new
			_needsSetup = FALSE;
		}
		if ([[self window] isKeyWindow]) {
			if (FF->startnum == FF->head.rtot)	{	/* if no new records */
				[amongnew setEnabled:NO];
				[amongnew setState:NO];
			}
			else
				[amongnew setEnabled:YES];
			if (FF->head.privpars.vmode == VM_FULL)	{	/* if formatted view */
				[amongdeleted setEnabled:NO];
				[amongdeleted setState:NO];
			}
			else
				[amongdeleted setEnabled:YES];
			if ([_currentDocument selectedRecords].location)
				[[recordscope cellWithTag:COMR_SELECT] setEnabled:YES];
			else {
				if ([[recordscope selectedCell] tag] == COMR_SELECT) 	// if previously wanted selection
					[recordscope selectCellWithTag:COMR_ALL];
				[[recordscope cellWithTag:COMR_SELECT] setEnabled:NO];
			}
		}
		else {		// if not key window, set display, titles
			if (_target) 	// if already started in current document
				[findbutton setTitle:@"Find Again"];
			else
				[findbutton setTitle:@"Find"];
		}
		[self enableLocalButtons:[self checkFindSettings]];
	}
	else if (![[IRdc documents] count])	{	// if no documents
		if ([[self window] attachedSheet])// remove sheet before hiding
			[self.window endSheet:[[self window] attachedSheet] returnCode:NSModalResponseCancel];
		[[self window] orderOut:self];
	}
}
- (void)enableLocalButtons:(BOOL)enable {
	if (enable) {
		[findbutton setEnabled:YES];
		[findallbutton setEnabled:[_currentDocument recordWindowController] ? NO : YES];
	}
	else {
		[findbutton setEnabled:NO];
		[findallbutton setEnabled:NO];
	}
}
- (void)_activeIndexChanged:(NSNotification *)aNotification {
	IRIndexDocument * frontdoc = [aNotification object];
	
	if (frontdoc != _currentDocument)	{	// if front index not current
		[self cleanup];
		_currentDocument = frontdoc;
		_needsSetup = TRUE;
	}
}
- (void)_indexClosing:(NSNotification *)aNotification {
	if ([aNotification object] == _currentDocument)	{
		[self cleanup];
		_currentDocument = nil;
	}
}
- (void)_globallyChanging:(NSNotification *)aNotification {
	if ([aNotification object] == _currentDocument) {
		[[self window] orderOut:self];
	}
}
- (IBAction)find:(id)sender {
	if ([_currentDocument canCloseActiveRecord] && (_target || [self checkFindValid])) {
		RECORD * recptr;
		char * sptr;
		short mlength;
		
		do {
			recptr = search_findfirst(FF,&lg,_restart,&sptr,&mlength);		/* while target in invis part of rec */
			if (recptr)	{	// if a hit
				sptr = vistarget(FF,recptr,sptr,&lg, &mlength, FALSE);	// find if target visible
				if (sptr)	// target visible, so done
					break;
				if (lg.revflag)	{	// if reverse search, keep going to find visible
					_restart = FALSE;
					FF->lastfound = recptr->num;
				}
			}
		} while (recptr);
		
		if (recptr)	{
			_restart = FALSE;		/* can proceed with search */
			_target = recptr->num;
			[findbutton setTitle:@"Find Again"];
			[_currentDocument selectRecord:_target range:NSMakeRange(sptr-recptr->rtext,str_utextlen(sptr,mlength))];
			[[[_currentDocument mainWindowController] window] makeKeyWindow];
			return;
		}
		else if (_restart)	{	/* if we've had a completely failed search */
			[_currentDocument selectRecord:0 range:NSMakeRange(0,0)];	// clear selection
			errorSheet(self.window,RECNOTFOUNDERR, WARN);
		}
		else	/* found something */
			sendinfo(NOMORERECINFO);		/* done */
		[self setNewFind];		// reinitialize after failure
	}
}
- (IBAction)showHelp:(id)sender {
	[[NSHelpManager sharedHelpManager] openHelpAnchor:@"fnd0_Anchor-14210" inBook:@"Cindex 4.2.5 Help"];
}
- (IBAction)doSetAction:(id)sender {
	if (sender == label && [sender indexOfSelectedItem] != lg.tagvalue) {	// if changing active label
		[amonglabeled setState:NSOnState];
		[self setNewFind];
	}
	else if (sender == findsuperscript) {
		if (findsuperscript.selectedCell.tag == 1 && findsubscript.selectedCell.tag == 1)	// if both would be enabled
			[findsubscript selectCellWithTag:0];	// disable subscript
	}
	else if (sender == findsubscript) {
		if (findsubscript.selectedCell.tag == 1 && findsuperscript.selectedCell.tag == 1)	// if both would be enabled
			[findsuperscript selectCellWithTag:0];	// disable superscript
	}
	else if (sender == findfont) {
		[findtextfont selectItemAtIndex:findfont.selectedCell.tag ? 0 : -1];
		[findtextfont setEnabled:findfont.selectedCell.tag];
	}
	else {
		int setindex = setindexfromtag([sender tag]);
		int type = sendertype(sender);
		
		if (type == TT_ATTRIBUTES)	{	// attributes button
			[self setFindAttributes:setindex];
			return;		// setNewFind called if necessary when sheet closed
		}
		else if (type == TT_ANDOR)	{	// and/or menu
			if (![[sender selectedItem] tag])	// if need nothing below this
				[self sizeForSets:setindex+1];
			else if (setindex == lg.size-1)	// if need to expand
				[self sizeForSets:setindex+2];
		}
		else if (type == TT_FIELD) {	// field menu
			BOOL pageenable = [[sender selectedItem] tag] == PAGEINDEX && ![patternforset(setindex) state]; // if page field and no pattern
			NSButton * pageval = evalpageforset(setindex);
			
			[pageval setEnabled:pageenable];
			[pageval setState:pageenable];		// default evaluate refs in page field
			[comboforset(setindex) setCompletes:!pageenable];	// no autocomplete for page field
			[comboforset(setindex) selectText:self];	// select text on change of field
		}
		else if (type == TT_PATTERN) {	// pattern button
			NSButton * wholeword = wholewordforset(setindex);
			NSButton * wordcase = caseforset(setindex);
			NSButton * pageval = evalpageforset(setindex);
			
			if ([sender state])	{		// setting
				[pageval setState:NO];
				[wholeword setState:NO];
				[wordcase setState:YES];
				[pageval setEnabled:NO];
				[wholeword setEnabled:NO];
			}
			else {
				[pageval setEnabled:[[fieldmenuforset(setindex) selectedItem] tag] == PAGEINDEX];
				[wholeword setEnabled:stringiswholeword(comboforset(setindex))];
				[wordcase setState:NO];
			}
		}
		[self setNewFind];		// reset for new search
	}
}
- (void)setNewFind {
	[findbutton setTitle:@"Find"];
	_target = 0;
	_restart = TRUE;
}
- (void)cleanup {
}
- (BOOL)checkFindSettings {
	BOOL wantdate, wantrange;

	lg.excludeflag = [amongtype selectedRow];
	lg.newflag = [amongnew state];
	lg.modflag = [amongmodified state];
	lg.delflag = [amongdeleted state];
	lg.markflag = [amongmarked state];
	lg.genflag = [amonggenerated state];
	lg.tagflag = [amonglabeled state];
	lg.tagvalue = [label indexOfSelectedItem];
	lg.lflags = [[recordscope selectedCell] tag];

	if (!_replaceEnabled) {
		strncpy(lg.userid,[[userid stringValue] UTF8String],4);
		lg.revflag = [backward state];
	}
	wantrange = lg.lflags && ([[firstrecord stringValue] length] || [[lastrecord stringValue] length]);	// want search for range
	wantdate = [[datescope selectedCell] tag] && ([[firstdate stringValue] length] || [[lastdate stringValue] length]);	// want search for dates
	lg.sortmode = FF->head.sortpars.ison;
	for (int set = 0; set < lg.size; set++)	{	// for all wanted sets, recover params
		NSString * cs = [comboforset(set) stringValue];
		int tlen = [cs length];
		
		if (!_replaceEnabled) {
			lg.lsarray[set].notflag = [notforset(set) state];
			lg.lsarray[set].andflag = [[andorforset(set) selectedItem] tag] == 1;	// TRUE if 'and'
			lg.lsarray[set].evalrefflag = [evalpageforset(set) state];
		}
		lg.lsarray[set].field = [[fieldmenuforset(set) selectedItem] tag];
		lg.lsarray[set].wordflag = [wholewordforset(set) state];
		lg.lsarray[set].caseflag = [caseforset(set) state];
		lg.lsarray[set].patflag = [patternforset(set) state];
		if (tlen < LISTSTRING && (tlen || !lg.lsarray[set].patflag
			&& (lg.newflag || lg.modflag || lg.delflag || lg.markflag || lg.genflag || lg.tagflag || *lg.userid
				|| lg.lsarray[set].field > 0 || lg.lsarray[set].style || lg.lsarray[set].font
				|| lg.lsarray[set].forbiddenstyle || lg.lsarray[set].forbiddenfont 
				|| wantdate || wantrange)))	// if valid search target
			strcpy(lg.lsarray[set].string,[cs UTF8String]);
		else
			return FALSE;
		strcpy(lg.range0,[[firstrecord stringValue] UTF8String]);	// save range specifiers for group rebuild
		strcpy(lg.range1,[[lastrecord stringValue] UTF8String]);
	}
	return TRUE;
}
- (BOOL)checkFindValid {
	if ([self checkFindSettings]) {
		short field;
		int err;
		
		if (err = com_getrecrange(FF,lg.lflags, firstrecord,lastrecord,&lg.firstr, &lg.lastr))	{	/* bad range */
			[(err < 0 ? firstrecord : lastrecord) selectText:self];
			return FALSE;
		}
		if (err = com_getdates([[datescope selectedCell] tag],firstdate, lastdate,&lg.firstdate, &lg.lastdate))	{
			[(err == 1 ? firstdate : lastdate) selectText:self];
			return FALSE;
		}
		if (!search_setupfind(FF, &lg, &field))	{	// check expressions, etc
			[comboforset(field) selectText:self];	// select bad search field
			return FALSE;
		}
		for (int set = 0; set < lg.size; set++)	{	// for each set
			NSComboBox * cb = comboforset(set);
			NSString * cs = [cb stringValue];
			if ([cs length])	{		// if there's a new string to add
				[cb removeItemWithObjectValue:cs];		// remove it if it's in list already
				[cb insertItemWithObjectValue:cs atIndex:0];		// add search text to top of combo list
			}
		}
		return TRUE;
	}
	return FALSE;
}
- (void)setFindAttributes:(int)groupIndex {
	LIST * lp = &lg.lsarray[groupIndex];
	buildattributefontmenu(FF,findtextfont);	// ensure we have most up-to-date font list
	[self setFindStyle:findbold list:lp mask:FX_BOLD];
	[self setFindStyle:finditalic list:lp mask:FX_ITAL];
	[self setFindStyle:findunderline list:lp mask:FX_ULINE];
	[self setFindStyle:findsmallcaps list:lp mask:FX_SMALL];
	[self setFindStyle:findsuperscript list:lp mask:FX_SUPER];
	[self setFindStyle:findsubscript list:lp mask:FX_SUB];
	if (lp->font) {
		[findfont selectCellWithTag:1];
		[findtextfont selectItemAtIndex:lp->font&FX_FONTMASK];
	}
	else if (lp->forbiddenfont) {
		[findfont selectCellWithTag:2];
		[findtextfont selectItemAtIndex:lp->forbiddenfont&FX_FONTMASK];
	}
	else {
		[findfont selectCellWithTag:0];
		[findtextfont selectItemAtIndex:-1];
	}
	[findtextfont setEnabled:findfont.selectedCell.tag];
	_currentsetindex = groupIndex;
	[self.window beginSheet:findattributepanel completionHandler:^(NSInteger result) {
		if (result == OKTAG){
			;
		}
	}];
}
- (void)setFindStyle:(NSMatrix *)control list:(LIST *)lp mask:(char)mask {
	if (lp->style & mask)
		[control selectCellWithTag:1];
	else if (lp->forbiddenstyle & mask)
		[control selectCellWithTag:2];
	else
		[control selectCellWithTag:0];
}
- (IBAction)closeFindSheet:(id)sender {
	if ([sender tag] == OKTAG)	{
		LIST * lp = &lg.lsarray[_currentsetindex];
		char wantedfont = 0;
		
		lp->style = lp->forbiddenstyle = 0;
		lp->font = lp->forbiddenfont = 0;
		if (findbold.selectedCell.tag == 1)
			lp->style |= FX_BOLD;
		else if (findbold.selectedCell.tag == 2)
			lp->forbiddenstyle |= FX_BOLD;
		if (finditalic.selectedCell.tag == 1)
			lp->style |= FX_ITAL;
		else if (finditalic.selectedCell.tag == 2)
			lp->forbiddenstyle |= FX_ITAL;
		if (findunderline.selectedCell.tag == 1)
			lp->style |= FX_ULINE;
		else if (findunderline.selectedCell.tag == 2)
			lp->forbiddenstyle |= FX_ULINE;
		if (findsmallcaps.selectedCell.tag == 1)
			lp->style |= FX_SMALL;
		else if (findsmallcaps.selectedCell.tag == 2)
			lp->forbiddenstyle |= FX_SMALL;
		if (findsuperscript.selectedCell.tag == 1)
			lp->style |= FX_SUPER;
		else if (findsuperscript.selectedCell.tag == 2)
			lp->forbiddenstyle |= FX_SUPER;
		if (findsubscript.selectedCell.tag == 1)
			lp->style |= FX_SUB;
		else if (findsubscript.selectedCell.tag == 2)
			lp->forbiddenstyle |= FX_SUB;
		if (findfont.selectedCell.tag) {
			// explicit font 0 action only if FX_FONT bit enabled; otherwise means no font action
			if (findtextfont.indexOfSelectedItem)
				wantedfont = type_maplocal(FF->head.fm,(char *)[[findtextfont titleOfSelectedItem] UTF8String],1);
			else
				wantedfont = 0;
			if (findfont.selectedCell.tag == 1) {
				lp->font = wantedfont|FX_FONT;
			}
			else {
				lp->forbiddenfont = wantedfont|FX_FONT;
			}
		}
		[showattribsforset(_currentsetindex) setStringValue:attribdescriptor(lp->style,lp->font,lp->forbiddenstyle,lp->forbiddenfont)];
		[self setNewFind];
	}
	[self.window endSheet:[sender window] returnCode:[sender tag]];
	[[self window] makeKeyWindow];
}
- (IBAction)reset:(id)sender {		// triggered by a change in search params
	[self setNewFind];
}
- (IBAction)stop:(id)sender {
	[self cleanup];
	for (int set = 0; set < lg.size; set++)		// for all sets
		[self resetGroup:set];
	[firstrecord setStringValue:@""];
	[lastrecord setStringValue:@""];
	[firstdate setStringValue:@""];
	[lastdate setStringValue:@""];
	[userid setStringValue:@""];
	[recordscope selectCellWithTag:COMR_ALL];
	[datescope selectCellWithTag:0];
	[amongtype selectCellWithTag:0];
	[amongnew setState:NO];
	[amongmodified setState:NO];
	[amongdeleted setState:NO];
	[amongmarked setState:NO];
	[amonggenerated setState:NO];
	[amonglabeled setState:NO];
	[label selectItemAtIndex:0];
	[comboforset(0) selectText:self];
}
#if 0
- (IBAction)click:(id)sender {
	NSLog(@"clicked");
}
#endif
- (BOOL)canFindAgainInDocument:(IRIndexDocument *)doc {
	return _currentDocument == doc && _target;
}
#if 0
- (id)windowWillReturnFieldEditor:(NSWindow *)sender toObject:(id)client {
	if (client) {
		for (int set = 0; set < lg.size; set++)	{	// find the set for the menu
			if ([client isDescendantOf:comboforset(set)]) {
				NSLog([client description]);
				break;
			}
		}
#if 0
		BOOL isCombo = client == comboforset(0) || client == cbv[0];
		[self configureMenu:fieldMenu withRegex:isCombo];
		int tag = ((NSView*)client).tag;
//		NSLog([client description]);
		NSLog(@"Tag:%d (%@)[%@]",tag,[client description],[cbv[0] description]);
#endif
	}
	return nil;
}
#endif
- (BOOL)control:(NSControl *)control textShouldEndEditing:(NSText *)editor {
	if (control == firstdate || control == lastdate) {
		NSString * ds = [control stringValue];
		return (ds.length == 0 || [ds dateValue]) ? YES : NO;
	}
	return YES;
}
- (void)resetGroup:(int)set{
	search_clearauxbuff(&lg);		/* release any buffers */
	memset(&lg,0,sizeof(LISTGROUP));
	if (!_replaceEnabled) {
		[notforset(set) setState:NO];
		[andorforset(set) selectItemAtIndex:0];
		[evalpageforset(set) setState:NO];
		[evalpageforset(set) setEnabled:NO];
	}
	[comboforset(set) setObjectValue:nil];
	[comboforset(set) setCompletes:YES];
	[showattribsforset(set) setObjectValue:nil];
	[fieldmenuforset(set) selectItemAtIndex:0];
	[wholewordforset(set) setState:NO];
	[wholewordforset(set) setEnabled:YES];
	[caseforset(set) setState:NO];
	[caseforset(set) setEnabled:YES];
	[patternforset(set) setState:NO];
}
- (void)controlTextDidChange:(NSNotification *)note	{
	NSControl * control = [note object];
	
	if (control == firstrecord || control == lastrecord)
		[recordscope selectCellWithTag:COMR_RANGE];
	else if (control == firstdate || control == lastdate)
		[datescope selectCellWithTag:1];
	else if (control == userid)	{
		checktextfield(control,5);	// 5 = 4 + 1
	}
	else {
		int setindex = setindexfromtag([control tag]);
		NSButton * wholeword = wholewordforset(setindex);
		
		if (stringiswholeword(control) && ![patternforset(setindex) state])	// if no punctuation & not pattern search
			[wholeword setEnabled:YES];
		else {
			[wholeword setState:NO];
			[wholeword setEnabled:NO];
		}
	}
	[self setNewFind];	// any of the above changes provoke reset
}
- (NSString *)searchString {
	return [comboforset(0) stringValue];
}
- (void)configureMenu:(NSMenu *)mm withRegex:(BOOL)regex{
	[mm removeAllItems];
	[mm addItem:[[NSMenuItem alloc] initWithTitle:@"Cut" action:@selector(cut:) keyEquivalent:@""]];
	[mm addItem:[[NSMenuItem alloc] initWithTitle:@"Copy" action:@selector(copy:) keyEquivalent:@""]];
	[mm addItem:[[NSMenuItem alloc] initWithTitle:@"Paste" action:@selector(paste:) keyEquivalent:@""]];
	if (regex)
		addregexitems(mm);
}

@end



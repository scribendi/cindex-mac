//
//  SpellController.m
//  Cindex
//
//  Created by PL on 2/21/05.
//  Copyright 2005 Indexing Research. All rights reserved.
//

#import "IRIndexDocumentController.h"
#import "SpellController.h"
#import "commandutils.h"
#import "records.h"
#import "strings_c.h"
#import "locales.h"

static NSString * IRMainDic = @"HspellMainDictionary";
static NSString * IRPersonalDic = @"HspellPersonalDictionary";
static NSString * IRAuxDics = @"HspellAuxiliaryDictionaries";

NSString * IRSpellException = @"IRSpellException";

NSString * IRWindowSpell = @"SpellWindow";

static char * visibletarget(INDEX * FF, RECORD * recptr, char *sptr);	/* returns ptr if target vis */

@interface SpellController () {
	
}
@property (weak) IRIndexDocument * currentDocument;

- (void)_activeIndexChanged:(NSNotification *)aNotification;
- (void)_indexClosing:(NSNotification *)aNotification;
- (void)_globallyChanging:(NSNotification *)aNotification;
- (void)_setNewSpell;
- (void)_openForMainDictionary:(NSString *)md;
- (void)_openPersonalDictionary:(NSString *)pd;
- (void)_clearAlternatives;
- (void)_showAlternatives;
- (void)_makeNewDictionary;
- (void)_editDictionary:(NSString *)pd;
- (void)_cleanup;
- (int)_buildDictionaryMenu:(NSPopUpButton *)dmenu;
- (BOOL)_checkSpell;
@end

@implementation SpellController

@synthesize _alternatives, _pdwords, _auxSetCopy,_personaldics;

- (id)init	{
    if (self = [super initWithWindowNibName:@"SpellController"])
		return self;
	return nil;
}
-(void)dealloc {
	[[NSNotificationCenter defaultCenter] removeObserver:self];
	self._alternatives = nil;
	self._pdwords = nil;
	self._auxSetCopy = nil;
	self._personaldics = nil;
}
-(void)close {
	hspell_close();
	[super close];
}
- (void)awakeFromNib {
	[super awakeFromNib];
	NSBundle * pdbundle = [NSBundle bundleWithPath:global_preferencesdirectory()];
	NSString * mdname = [[NSUserDefaults standardUserDefaults] objectForKey:IRMainDic];
//	NSString * pdname = [[NSUserDefaults standardUserDefaults] objectForKey:IRPersonalDic];
	unsigned int index;
	
	_personaldics = [NSMutableArray arrayWithCapacity:10];
	[_personaldics addObjectsFromArray:[pdbundle pathsForResourcesOfType:CINPDicExtension inDirectory:nil]];		// in preferences
	[_personaldics sortUsingSelector:@selector(caseInsensitiveCompare:)];

	hspell_init();
	[language removeAllItems];
	for (index = 0; index < hs_dictionaryCount; index++)	{
		if (!(hs_dictionaries[index].flags&DIC_ISAUX))	{	// if isn't auxiliary
			char * lname = hs_dictionaries[index].displayname;
			
			if (lname) {
				NSString * name = [NSString stringWithFormat:@"%s", lname];
			
				[language addItemWithTitle:name];
				[[language itemWithTitle:name] setRepresentedObject:[NSString stringWithFormat:@"%s",hs_dictionaries[index].root]];
//				NSLog(name);
			}
		}
	}	
	[self _buildDictionaryMenu:personaldictionary];
	[self _openForMainDictionary:mdname];
	sps.lp = g_prefs.langpars;	/* install language prefs */
	[self setShouldCascadeWindows:NO];
    [[self window] setExcludedFromWindowsMenu:YES];
    [[self window] setFrameAutosaveName:IRWindowSpell];
	[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(_activeIndexChanged:) name:NOTE_ACTIVEINDEXCHANGED object:nil];
	[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(_indexClosing:) name:NOTE_INDEXWILLCLOSE object:nil];
	[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(_globallyChanging:) name:NOTE_GLOBALLYCHANGING object:nil];
}
- (void)showWindow:(id)sender {
	if (![[self window] isVisible])	{	// if not on screen
		if (self.currentDocument != [IRdc currentDocument])	{	// full setup
			self.currentDocument = [IRdc currentDocument];
			_needsSetup = TRUE;
		}
		else
			[self _setNewSpell];
	}
	[super showWindow:sender];
}
- (void)windowDidResignKey:(NSNotification *)aNotification {
	[self _cleanup];	// force sort, etc. as necessary
	offset = mlength = 0;		// force new check of string in any current record
}
#if 0
- (void)windowDidBecomeKey:(NSNotification *)aNotification {
	_needsSetup = TRUE;	// need to do it thiis way because main window can be nil on reactivate ap
}
#endif
- (void)windowDidUpdate:(NSNotification *)aNotification {
	if (_currentDocument) {
		if (_needsSetup) {		// window has just become key
			FF = [_currentDocument iIndex];
			buildfieldmenu(FF, field);
			[self _setNewSpell];
#if 0
			if (FF->startnum == FF->head.rtot)	{	/* if no new records */
				[[recordfilter cellWithTag:0] setEnabled:NO];
				[[recordfilter cellWithTag:0] setState:NO];
			}
			else
				[[recordfilter cellWithTag:0] setEnabled:YES];
			if ([_currentDocument selectedRecords].location)
				[[scope cellWithTag:COMR_SELECT] setEnabled:YES];
			else { 
				if ([[scope selectedCell] tag] == COMR_SELECT) 	// if previously wanted selection
					[scope selectCellWithTag:COMR_ALL];
				[[scope cellWithTag:COMR_SELECT] setEnabled:NO];
			}
#endif
			_needsSetup = FALSE;
		}
		if ([[self window] isKeyWindow]) {
			if (FF->startnum == FF->head.rtot)	{	/* if no new records */
				[[recordfilter cellWithTag:0] setEnabled:NO];
				[[recordfilter cellWithTag:0] setState:NO];
			}
			else
				[[recordfilter cellWithTag:0] setEnabled:YES];
			if ([_currentDocument selectedRecords].location)
				[[scope cellWithTag:COMR_SELECT] setEnabled:YES];
			else { 
				if ([[scope selectedCell] tag] == COMR_SELECT) 	// if previously wanted selection
					[scope selectCellWithTag:COMR_ALL];
				[[scope cellWithTag:COMR_SELECT] setEnabled:NO];
			}
		}
		else {	// if not key window, set display, titles
			if (_target) 	// if already started
				[startbutton setTitle:@"Resume"];
			else	{
//				[self _clearAlternatives];
				[startbutton setTitle:@"Start"];
			}
			[self _clearAlternatives];
		}
		if (![_currentDocument recordWindowController])
			[startbutton setEnabled:YES];
		else {
			[startbutton setEnabled:NO];
			[changebutton setEnabled:NO];
		}
	}
	else if (![[IRdc documents] count])	{	// if no documents
		if ([[self window] attachedSheet])// remove sheet before hiding 
			[[self window] endSheet:[[self window] attachedSheet]];
		[[self window] orderOut:self];
	}
}
- (void)_activeIndexChanged:(NSNotification *)aNotification {
	IRIndexDocument * frontdoc = [aNotification object];
		
	if (frontdoc != _currentDocument)	{	// if front index not current
		[self _cleanup];
		_currentDocument = frontdoc;
		_needsSetup = TRUE;
	}
}
- (void)_indexClosing:(NSNotification *)aNotification {
	if ([aNotification object] == _currentDocument)	{
		[self _cleanup];
		_currentDocument = nil;
	}
}
- (void)_globallyChanging:(NSNotification *)aNotification {
	if ([aNotification object] == _currentDocument) {
		[[self window] orderOut:self];
//		_currentDocument = nil;
	}
}
- (IBAction)showHelp:(id)sender {
	NSString * anchor;
	if ([[self window] attachedSheet])	// if displaying options sheet
		anchor = @"spell1_Anchor-14210";
	else
		anchor = @"spell0_Anchor-14210";
	[[NSHelpManager sharedHelpManager] openHelpAnchor:anchor inBook:@"Cindex 4.2.5 Help"];
}
- (void)_setNewSpell {
	[startbutton setTitle:@"Start"];
	_target = 0;
	_restart = TRUE;
	[addbutton setEnabled:NO];
	[changebutton setEnabled:NO];
	[ignoreallbutton setEnabled:NO];
	[suggestbutton setEnabled:NO];
	offset = 0;
	mlength = 0;
	[self _clearAlternatives];
}
- (void)_openForMainDictionary:(NSString *)md {
	if ([language indexOfItemWithRepresentedObject:md] < 0)	// if can't find main dictionary
		md = [[language itemAtIndex:0] representedObject];
	[language selectItemAtIndex:[language indexOfItemWithRepresentedObject:md]];
	[languagename setStringValue:[language titleOfSelectedItem]];
	sps.speller = hspell_open([md UTF8String]);
	if (sps.speller)	{
		NSArray * auxdics = [[NSUserDefaults standardUserDefaults] objectForKey:IRAuxDics];
		DICTIONARYSET ** ds = sps.speller->dicset->sets;	// get arrary of pointers to auxiliary sets
		
		while (*ds)	{	// run through all the sets
			for (NSString * dicname in auxdics)	{	// aux dic strings stored as display names
				if (!strcmp((*ds)->displayname,[dicname UTF8String]))	// if match
					hspell_openauxdic(*ds);	// open and add words
			}
			ds++;
		}
		[self _openPersonalDictionary:[[NSUserDefaults standardUserDefaults] objectForKey:IRPersonalDic]];	// open any preferred pd
		[[NSUserDefaults standardUserDefaults] setObject:md forKey:IRMainDic];	// set new default
	}
	else
		senderr(SPELLOPENERR,WARN);
}
- (void)_openPersonalDictionary:(NSString *)pd {
	int ok = FALSE;
	
	hspell_closepd();	// close any open dic
	if ([_personaldics containsObject:pd])
		ok = hspell_openpd([pd UTF8String]);
	if (ok)
		[personaldictionary selectItemAtIndex:[personaldictionary indexOfItemWithRepresentedObject:pd]];
	else {
		[personaldictionary selectItemAtIndex:0];
		pd = @"";
	}
	[[NSUserDefaults standardUserDefaults] setObject:pd forKey:IRPersonalDic];	// set new default
}
- (void)_clearAlternatives {
	[unknownword setObjectValue:nil];
	[changedword setObjectValue:nil];
	sps.doubleflag = FALSE;
	self._alternatives = nil;
	[ignoreallbutton setEnabled:NO];
	[changebutton setTitle:@"Change"];
	[changebutton setEnabled:NO];
	[addbutton setEnabled:NO];
	[suggesttable noteNumberOfRowsChanged];
//	[[self window] makeFirstResponder:firstrecord];
}
- (void)_showAlternatives {
	NSMutableArray * wlist = [NSMutableArray arrayWithCapacity:20];
	char badword[200];
	int altcount, listindex;
	
	[[unknownword stringValue] getCString:badword maxLength:200 encoding:NSUTF8StringEncoding];
	altcount = hspell_suggest(badword);
	
	for (listindex = 0; listindex < altcount; listindex++) {
		char * cword = hspell_convertword(sps.speller->suggestions.list[listindex],TONATIVE);	// convert to native charset
		[wlist addObject:[NSString stringWithUTF8String:cword]];
	}
	self._alternatives = wlist;
	[suggesttable reloadData];
	if ([wlist count]) {
		[changedword setStringValue:[wlist objectAtIndex:0]];
		[changebutton setEnabled:YES];
	}
	else 
		[self setDefaultChangedWord];
}
- (void)_makeNewDictionary {
	centerwindow(optionspanel, newdicpanel);
	if ([NSApp runModalForWindow:newdicpanel])	{	// if have new dic
		[editdictionary setEnabled:YES];
		[self _openPersonalDictionary:[_personaldics lastObject]];
	}
}
- (void)_editDictionary:(NSString *)pd {
	WORDLIST *listptr = hspell_wlfromfile([pd UTF8String],NULL);
	int wcount;
	UChar * base = hspell_wlToUtext(listptr,&wcount);
	
	[edittext setString:[NSString stringWithCharacters:base length:u_strlen(base)]];
//	[[edittext textStorage] beginEditing];
//	[[edittext textStorage] replaceCharactersInRange:NSMakeRange(0,[[edittext textStorage] length]) withString:[NSString stringWithCharacters:base length:u_strlen(base)]];
//	[[edittext textStorage] endEditing];
	hspell_wlfree(&listptr);
	free(base);
	[wordcount setIntValue:wcount];
	centerwindow(optionspanel, editdicpanel);
	[NSApp runModalForWindow:editdicpanel];	// if have new dic
}
- (void)_cleanup {
	if (nptr)	{		/* if have some changes */
		sort_resortlist(FF,nptr);	/* make new nodes */
		free(nptr);
		nptr = NULL;
		[FF->owner redisplay:0 mode:VD_CUR];
	}
}
- (int)_buildDictionaryMenu:(NSPopUpButton *)dmenu {
	NSInteger index;
	
	[dmenu removeAllItems];
	for (index = 0; index < [_personaldics count]; index++)	{
		NSString * name = [[[_personaldics objectAtIndex:index] lastPathComponent] stringByDeletingPathExtension];
		
		[dmenu addItemWithTitle:name];
		[[dmenu itemWithTitle:name] setRepresentedObject:[_personaldics objectAtIndex:index]];
	}
	if (dmenu == personaldictionary) {
		[dmenu insertItemWithTitle:@"<None Selected>" atIndex:0];
		[[dmenu itemAtIndex:0] setRepresentedObject:nil];
	}
	return [dmenu numberOfItems];
}
-(void)setDefaultChangedWord {
	[changedword setStringValue:[unknownword stringValue]];
	[changebutton setEnabled:NO];
}
- (BOOL)_checkSpell {
	int err;
	
	if (err = com_getrecrange(FF,[[scope selectedCell] tag], firstrecord, lastrecord,&sps.firstr, &sps.lastr))	{	/* bad range */
		[(err < 0 ? firstrecord : lastrecord) selectText:self];
		return FALSE;
	}
	sps.field = [[field selectedItem] tag];
	sps.checkpage = [checkpagerefs state];
	sps.newflag = [[recordfilter cellWithTag:0] state];
	sps.modflag = [[recordfilter cellWithTag:1] state];
	return TRUE;
}
- (IBAction)reset:(id)sender {		// triggered by a change in search params
	[self _setNewSpell];
}
- (IBAction)spell:(id)sender {
	[self _clearAlternatives];
	if ([_currentDocument canCloseActiveRecord] && (_target || [self _checkSpell])) {
		RECORD * recptr = NULL;
		char * sptr = NULL;	// no target string
	
		@try {
			if (_target && (recptr = rec_getrec(FF,_target)))		/* if already have a target */
				sptr = recptr->rtext+offset;		// set offset for search
			if (!sptr || !(sptr = sp_checktext(FF,recptr, sptr+mlength, &sps, &mlength)))	 {	// if no more matches in this record
				do {
					recptr = sp_findfirst(FF,&sps,_restart,&sptr,&mlength);		/* while target in invis part of rec */
				} while (recptr && !(sptr = visibletarget(FF,recptr,sptr)));
			}
			if (recptr)	{
				char badword[200];
				
				strncpy(badword,sptr,mlength);	// copy relevant word
				badword[mlength] = '\0';	// terminate
				offset = sptr-recptr->rtext;
				_restart = FALSE;		/* can proceed with search */
				_target = recptr->num;
				[startbutton setTitle:@"Ignore"];
				[unknownword setStringValue:[NSString stringWithUTF8String:badword]];
				[_currentDocument selectRecord:_target range:NSMakeRange(sptr-recptr->rtext,str_utextlen(sptr,mlength))];
				if (!sps.doubleflag)	{		/* if not double-word err */
					[unknownprompt setStringValue:@"Unknown:"];
					[addbutton setEnabled:YES];
					[ignoreallbutton setEnabled:YES];
					if (sps.lp.suggestflag)	// if want suggestions
						[self _showAlternatives];
					else
						[suggestbutton setEnabled:YES];	// enable button
				}
				else {
					[unknownprompt setStringValue:@"Duplicate:"];
					[changebutton setTitle:@"Delete"];
					[changebutton setEnabled:YES];
				}
				[[self window] makeFirstResponder:changedword];
			}
			else	{/* found something */
				sendinfo(NOMORERECINFO);		/* done */
				[self _setNewSpell];		// reinitialize after finish
			}
		}
		@catch (NSException * exception) {
		    if ([[exception name] isEqualToString:IRSpellException]) 	// if spell system error
				NSRunCriticalAlertPanel(@"Spell Error",@"%@",@"OK", nil,nil,[exception reason]);	// display error string
			else
				[exception raise];		// forward it
		}
		@finally {
		}
	}
}
- (IBAction)change:(id)sender {
	if (nptr || (nptr = sort_setuplist(FF)))	{	/* if have/can set up structures */
		char newword[200], badword[200];
		
		char dupcopy[MAXREC];
		char *sptr = NULL;
		RECORD * recptr = NULL;

		[[changedword stringValue] getCString:newword maxLength:200 encoding:NSUTF8StringEncoding];
		[[unknownword stringValue] getCString:badword maxLength:200 encoding:NSUTF8StringEncoding];
		if (_target && (recptr = rec_getrec(FF,_target)))		/* if already have a target */
			sptr = recptr->rtext+offset;
		if (!hspell_spellword(newword))	// if don't have new word in dic
			hspell_addword(newword);
		str_xcpy(dupcopy, recptr->rtext);		/* save copy */
		if (sptr = sp_reptext(FF,recptr, sptr, mlength, sps.doubleflag ? NULL : newword)) {
			str_adjustcodes(recptr->rtext,CC_TRIM|(g_prefs.gen.remspaces ? CC_ONESPACE : 0));	/* clean up codes */
			rec_strip(FF,recptr->rtext);		/* remove empty fields */
			sort_addtolist(nptr,recptr->num);	/* add to sort list */
			rec_propagate(FF,recptr,dupcopy, nptr);	/* propagate */
			[FF->owner updateDisplay];
			offset = sptr-recptr->rtext;	// set for char beyond replacement
			mlength = 0;	// now redundant
		}
		[self spell:self];	// get next
	}
}
- (IBAction)stop:(id)sender {
	[self _cleanup];	// force sort, etc. as necessary
	
	[firstrecord setStringValue:@""];
	[lastrecord setStringValue:@""];
	[scope selectCellWithTag:COMR_ALL];
	[recordfilter deselectAllCells];
	[field selectItemAtIndex:0];
	[checkpagerefs setEnabled:YES];
	[checkpagerefs setState:NO];
	
	[self _setNewSpell];
}
- (IBAction)doSetAction:(id)sender {	
	char badword[300];
	
	[[unknownword stringValue] getCString:badword maxLength:200 encoding:NSUTF8StringEncoding];
	if (sender == ignoreallbutton)	{	// ignore all
		if (hspell_addignoredword(badword))
			[self spell:self];	// get next
	}
	else if (sender == addbutton)	{	// add word
		if ([personaldictionary indexOfSelectedItem] < 1)	{	// if don't have active pd
			if (sendwarning(NODICWARNING))
				[self _makeNewDictionary];
			else
				return;
		}
		if (hspell_addpdword(badword))
			[self spell:self];	// find next
	}
	else if (sender == suggestbutton)	{	// suggest alts
		[self _showAlternatives];
	}
	else if (sender == field)	{
		if ([[field selectedItem] tag] == ALLFIELDS || [[field selectedItem] tag] == PAGEINDEX)	// if page check ok
			[checkpagerefs setEnabled:YES];
		else {
			[checkpagerefs setState:NO];
			[checkpagerefs setEnabled:NO];
		}
		[self _setNewSpell];
	}
	else if (sender == optionsbutton)	{	// options button
		_delayedClearIgnore = FALSE;
		_languageChanged = FALSE;
		_languageIndex = [language indexOfSelectedItem];
		_activeDicSet = hspell_dictionarysetforlocale([[[language selectedItem] representedObject] UTF8String]);
		self._auxSetCopy = [NSMutableArray arrayWithArray:[[NSUserDefaults standardUserDefaults] objectForKey:IRAuxDics]];
		if ([self _buildDictionaryMenu:pdictionary]) {	// if have items
			NSString * pdname = [[personaldictionary selectedItem] representedObject];
		
			[editdictionary setEnabled:YES];
			[pdictionary selectItemAtIndex: pdname ? [pdictionary indexOfItemWithRepresentedObject:pdname] : 0];
		}
		else
			[editdictionary setEnabled:NO];
		[alwayssuggest setState:sps.lp.suggestflag];
		[ignorecaps setState:sps.lp.ignallcaps];
		[ignorealnum setState:sps.lp.ignalnums];
		[extradictionaries reloadData];
#if 0
		[NSApp beginSheet:optionspanel modalForWindow:[self window] modalDelegate:self		// put up sheet
		   didEndSelector:nil contextInfo:nil];
#else
		[self.window beginSheet:optionspanel completionHandler:^(NSInteger result) {
			if (result == OKTAG){
				;
			}
		}];
#endif
	}
	else if (sender == extradictionaries) {
		NSLog(@"&&&&&");
	}
	else if (sender == language)	{
		if ([language indexOfSelectedItem] != _languageIndex)	{	// if changed language
			_activeDicSet = hspell_dictionarysetforlocale([[[language selectedItem]representedObject] UTF8String]);
			[_auxSetCopy removeAllObjects];
			[extradictionaries reloadData];
			_languageIndex = [language indexOfSelectedItem];
			_languageChanged = TRUE;
		}
	}
	else if (sender == editdictionary)	{	// edit dictionary
		if ([[pdictionary selectedItem] representedObject] == [[personaldictionary selectedItem] representedObject]) // if current
			hspell_savepd();	// make sure personal dic saved image is up to date
		[self _editDictionary:[[pdictionary selectedItem] representedObject]];
	}
	else if (sender == newdictionary)	{	// new dictionary
		[self _makeNewDictionary];	// makes new dictionary and sets up
	}
	else if (sender == clearignorelist) {
		_delayedClearIgnore = TRUE;
	}
	else if (sender == personaldictionary)	{	// personaldic
		[self _openPersonalDictionary:[[sender selectedItem] representedObject]];
	}
}
- (IBAction)closeSheet:(id)sender {
	if ([sender tag] == OKTAG)	{
		BOOL sameaux =[ _auxSetCopy isEqualToArray:[[NSUserDefaults standardUserDefaults] objectForKey:IRAuxDics]];

		[[NSUserDefaults standardUserDefaults] setObject:_auxSetCopy forKey:IRAuxDics];
		sps.lp.suggestflag = [alwayssuggest state];
		sps.lp.ignallcaps = [ignorecaps state];
		sps.lp.ignalnums = [ignorealnum state];
		if (_delayedClearIgnore)
			hspell_removeignoredwords();
		if (_languageChanged || !sameaux)	{// if changed language or aux dics
			[self _openForMainDictionary:[[language selectedItem] representedObject]];
			[self _setNewSpell];
		}
		g_prefs.langpars = sps.lp;	/* save language prefs */
	}
	self._auxSetCopy = nil;
//	[[sender window] orderOut:sender];
//	[NSApp endSheet:[sender window]];
	[self.window endSheet:[sender window] returnCode:[sender tag]];
	[[self window] makeKeyWindow];
}
- (IBAction)closePanel:(id)sender {
	if ([sender tag] == OKTAG)	{
		if (![[sender window] makeFirstResponder:nil])	// if bad text somewhere
			return;
		if ([sender window] == newdicpanel) {
			NSString * newdic = [newdicname stringValue];
			
			if ([newdic length] > 0)	{	// for some reason can't test this in textShouldEndEditing
				NSString * path = [[global_preferencesdirectory() stringByAppendingPathComponent:newdic]
						stringByAppendingPathExtension:CINPDicExtension];
				if (![_personaldics containsObject:path]) {		// if doesn't already exist
					if (hspell_createpd([path UTF8String]))		{	// if can create new pd
						[_personaldics addObject:path];	// add to array
						[self _buildDictionaryMenu:personaldictionary];	//rebuild dictionary menus
						[self _buildDictionaryMenu:pdictionary];
						[pdictionary selectItemWithTitle:newdic];
					}
				}
				else {
					senderr(SPELLDICEXISTERR,WARN,[newdic cStringUsingEncoding:NSUTF8StringEncoding]);
					return;
				}
			}
			else
				return;		// no name for new dic
		}
		if ([sender window] == editdicpanel) {
			char * path = [[[pdictionary selectedItem] representedObject] UTF8String];		
			NSInteger length = [[edittext string] length];
			UChar * ustring = malloc(length*sizeof(UChar)+2);
			WORDLIST * wlp;
			
			[[[edittext textStorage] string] getCharacters:ustring];
			*(ustring+length) = 0;
			wlp = hspell_wlFromUtext(ustring);
			free(ustring);
//			[[edittext textStorage] replaceCharactersInRange:NSMakeRange(0,[[edittext textStorage] length]) withString:@""];	// clear dic text
			
			if ([[[pdictionary selectedItem] representedObject] isEqualToString:[[personaldictionary selectedItem] representedObject]])	// if active dic
				hspell_closepd();	// need to close so that we remove words that should disappear from active dic
			hspell_wlsavetofile(wlp,path,"w");	//replace existing file
			hspell_wlfree(&wlp);		// free list
			if ([[[pdictionary selectedItem] representedObject] isEqualToString:[[personaldictionary selectedItem] representedObject]])	// if active dic
				[self _openPersonalDictionary:[[pdictionary selectedItem] representedObject]];
		}
	}
	[[sender window] orderOut:sender];
	[NSApp stopModalWithCode:[sender tag]]; 
}
- (BOOL)control:(NSControl *)control textShouldEndEditing:(NSText *)editor {
	if (control == newdicname)
		return [[newdicname stringValue] length] > 0;
	return YES;
}
- (void)controlTextDidChange:(NSNotification *)note	{
	NSControl * control = [note object];
	if (control == firstrecord || control == lastrecord) {
		[scope selectCellWithTag:COMR_RANGE];
		[self _setNewSpell];
	}
	if (control == changedword) {
		if ([[changedword stringValue] length])
			[changebutton setTitle:@"Change"];
		else
			[changebutton setTitle:@"Delete"];
		[changebutton setEnabled:![[changedword stringValue] isEqualToString:[unknownword stringValue]]];
	}
}
- (NSInteger)numberOfRowsInTableView:(NSTableView *)tableView
{
	if (tableView == extradictionaries)
		return _activeDicSet ? _activeDicSet->setcount : 0;
	else if (tableView == suggesttable)
		return [_alternatives count];
	else
		return [_pdwords count];
}
#if 0
- (BOOL)tableView:(NSTableView *)aTableView shouldEditTableColumn:(NSTableColumn *)aTableColumn row:(int)rowIndex {
	if (aTableView == edittable)
		return YES;
	return NO;
}
#endif
- (void)tableView:(NSTableView *)tableView willDisplayCell:(id)aCell forTableColumn:(NSTableColumn *)tableColumn row:(NSInteger)row	{

	if (tableView == extradictionaries)	{
		[aCell setTitle:[NSString stringWithFormat:@"%s", _activeDicSet->sets[row]->displayname]];
	}
}
- (void)tableView:(NSTableView *)tableView setObjectValue:(id)anObject forTableColumn:(NSTableColumn *)tableColumn row:(NSInteger)row
{
	if (tableView == extradictionaries)	{
		NSString * title = [NSString stringWithFormat:@"%s", _activeDicSet->sets[row]->displayname];
		BOOL inlist = [anObject boolValue];
		
		if (inlist)
			[self._auxSetCopy addObject:title];
		else
			[self._auxSetCopy removeObject:title];
	}
}
- (id)tableView:(NSTableView *)tableView objectValueForTableColumn:(NSTableColumn *)tableColumn row:(NSInteger)row
{
	if (tableView == extradictionaries)	{
		NSString * name = [NSString stringWithFormat:@"%s", _activeDicSet->sets[row]->displayname];
		return [NSNumber numberWithBool:[_auxSetCopy containsObject:name]];
	}
	else if (tableView == suggesttable) {
		if (row < (int)[_alternatives count])
			return [_alternatives objectAtIndex:row];
	}
	else {		// pd word list
		if (row < (int)[_pdwords count])
			return [_pdwords objectAtIndex:row];
	}
	return nil;
}
- (void)tableViewSelectionDidChange:(NSNotification *)aNotification {
	NSTableView * table = [aNotification object];
	NSInteger row = [table selectedRow];
	
	if (table == extradictionaries)
		return;
	if (table == suggesttable) {
		if (row >= 0)
			[changedword setStringValue:[_alternatives objectAtIndex:row]];
	}
}
@end
/******************************************************************************/
static char * visibletarget(INDEX * FF, RECORD * recptr, char *sptr)	/* returns ptr if target vis */

{
	short hlevel,sprlevel,hidelevel, clevel;
	char *uptr;
	
	uptr = rec_uniquelevel(FF,recptr,&hlevel,&sprlevel,&hidelevel,&clevel);		/* find unique level */
	if (sptr < uptr) 	/* if target before unique level */			
		return (NULL);	/* not visible */
	return (sptr);
}




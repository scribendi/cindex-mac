//
//  IRIndexRecordWController.m
//  Cindex
//
//  Created by PL on 3/12/05.
//  Copyright 2005 Indexing Research. All rights reserved.
//

#import "TextViewCategories.h"
#import "IRIndexDocWController.h"
#import "IRIndexRecordWController.h"
#import "AttributedStringCategories.h"
#import "cindexmenuitems.h"
#import "commandutils.h"
#import "records.h"
#import "strings_c.h"

//static NSString* IRRecordWToolbarID = @"IRRecordToolbarIdentifier";

static NSString* IRPropagateToolbarID = @"IRPropagateTBIdentifier";

//static NSString* IRBraceToolbarID = @"IRBraceTBIdentifier";
//static NSString* IRAngleToolbarID = @"IRAngleTBIdentifier";
//static NSString* IRFlipNoToolbarID = @"IRFlipNoTBIdentifier";
//static NSString* IRFlipToolbarID = @"IRFlipTBIdentifier";
//static NSString* IRParenToolbarID = @"IRParenTBIdentifier";
//static NSString* IRFontToolbarID = @"IRFontTBIdentifier";
//static NSString* IRBoldToolbarID = @"IRBoldTBIdentifier";
//static NSString* IRItalicToolbarID = @"IRItalicTBIdentifier";
//static NSString* IRUlineToolbarID = @"IRUlineTBIdentifier";
//static NSString* IRRevertToolbarID = @"IRRevertTBIdentifier";
//static NSString* IRPrevToolbarID = @"IRPrevTBIdentifier";
//static NSString* IRNextToolbarID = @"IRNextTBIdentifier";
//static NSString* IREnterToolbarID = @"IREnterTBIdentifier";

#if 0
static TOOLBARITEM tbitems[] = {
//	{@"IRPropagateTBIdentifier",TB_PROPAGATE,@"Propagation",@"Propagate changes to succeeding records",nil,@"setPropagate:",@"32propagate"},
	{@"IRBraceTBIdentifier",MI_BRACES,@"Spell Out",@"Sort on hidden text [Control B]",nil,@"encloseText:",@"32braces"},
	{@"IRAngleTBIdentifier",MI_BRACKETS,@"Hide Text",@"Hide selected text from sort [Control A]",nil,@"encloseText:",@"32brackets"},
	{@"IRFlipNoTBIdentifier",TB_FLIPFULL,@"Flip",@"Full Flip [Control +]",nil,@"flipField:",@"32fullflip"},
	{@"IRFlipTBIdentifier",TB_FLIPHALF,@"Half Flip",@"Half flip [Control -]",nil,@"flipField:",@"32halfflip"},
	{@"IRParenTBIdentifier",TB_SWAPPAREN,@"Swap Text",@"Swap Text in Parens [Control P]",nil,@"swapParens:",@"32fliphoriz"},
	{@"IRFontTBIdentifier",MI_DEFAULTFONT,@"Default Font",@"Set font to default [Control F]",nil,@"defaultFont:",@"32defaultfont"},
//	{@"IRBoldTBIdentifier",TB_BOLD,@"Bold",@"Set boldface",nil,@"addFontTrait:",@"bold"},
//	{@"IRItalicTBIdentifier",TB_ITALIC,@"Italic",@"Set italic",nil,@"addFontTrait:",@"italic"},
//	{@"IRUlineTBIdentifier",TB_UNDERLINE,@"Underline",@"Underline",nil,@"underline:",@"underline"},
	{@"IRRevertTBIdentifier",TB_REVERT,@"Revert",@"Restore record to original state [Option ESC]",nil,@"toolbarAction:",@"32revert"},
	{@"IRPrevTBIdentifier",TB_PREVRECORD,@"Previous",@"Enter record and move to previous [Page Up]",nil,@"toolbarAction:",@"32prevrecord"},
	{@"IRNextTBIdentifier",TB_NEXTRECORD,@"Next",@"Enter record and move to next [Page Down]",nil,@"toolbarAction:",@"32nextrecord"},
	{@"IREnterTBIdentifier",TB_ENTERRECORD,@"Enter/copy",@"Enter record and leave copy [Option Page Down]",nil,@"toolbarAction:",@"32enter_copy"},
};
#define MAXTBITEMS (sizeof(tbitems)/sizeof(TOOLBARITEM))

#endif
@interface IRIndexRecordWController () {

}
@property (weak) IRIndexDocWController * parentController;

- (void)_showRecord;
- (void)_setRecord:(RECN)record;
- (void)_stepRecord:(int)direction;
- (void)_setPrevNext:(RECORD *)recptr;
- (void)_checkPrompt;
- (void)_scrollPrompt;
@end

@implementation IRIndexRecordWController
- (id)init	{
    if (self = [super initWithWindowNibName:@"IRIndexRecordWController"])
		;
    return self;
}
- (void)dealloc {
	[[NSNotificationCenter defaultCenter] removeObserver:self];
	free(_nptr);
}
- (void)keyDown:(NSEvent *)theEvent {
	NSString * kchars = [theEvent charactersIgnoringModifiers];

	if ([kchars length]) {	// if not special input
		unichar uchar = [kchars characterAtIndex:0];
		unsigned int flags = [theEvent modifierFlags];
		
		switch (uchar) {
			case NSPageUpFunctionKey:
				[self _stepRecord:-1];
				return;
			case NSPageDownFunctionKey:
				if (flags&NSAlternateKeyMask)	// enter and leave copy
					[self duplicate:nil];
				else 
					[self _stepRecord:1];
				return;
			case 0x1b:	// escape key
				if (flags&NSAlternateKeyMask)
					[self _setRecord:_currentRecord];	// reset current record
				else
					[[self window] close];		// abandon
				return;
		}
	}	// all other chars ignored
}
- (void)awakeFromNib {	
	[super awakeFromNib];
	NSPoint origin;

	FF = [[self document] iIndex];
	self.parentController = [[self document] mainWindowController];
	_addMode = [_parentController editingMode];
	_propagate = g_prefs.gen.propagate;		// set up before configuring toolbar
	for (NSToolbarItem * ti in self.window.toolbar.items) {
		if ([ti.itemIdentifier isEqualToString:IRPropagateToolbarID])	{
			[(NSButton*)ti.view setState:_propagate];
			break;
		}
	}
	[_parentController enableToolbarItems:NO];	// disable font/size items in main window
	[self setShouldCascadeWindows:NO];
	if (@available(macOS 11.0, *)) {
		[self window].toolbarStyle = NSWindowToolbarStyleExpanded;
	}
	if (FF->head.recordviewrect.size.height)
		[[self window] setFrame:[[self window] frameRectForContentRect:NSRectFromIRRect(FF->head.recordviewrect)] display:NO];
	_allowFrameSet = YES;
	origin = [[_parentController window] frame].origin;
	[[self window] setFrameOrigin:NSMakePoint(FF->head.recordviewrect.origin.x+origin.x, FF->head.recordviewrect.origin.y+origin.y)];
    [[self window] setExcludedFromWindowsMenu:YES];
	
	[[_recordMenu itemWithTag:MI_BOLD] setTarget:[NSFontManager sharedFontManager]];
	[[_recordMenu itemWithTag:MI_ITALIC] setTarget:[NSFontManager sharedFontManager]];
	[_entry setIndex:FF];
	_nptr = sort_setuplist(FF);
	[[_entry superview] setPostsBoundsChangedNotifications:YES];	// scroll view posts notifications
	
	[_prompt setAlignment:NSRightTextAlignment];
	[[_prompt textStorage] setAttributedString:[NSAttributedString asFromXString:" " 
		fontMap:FF->head.fm size:g_prefs.gen.recordtextsize ? g_prefs.gen.recordtextsize : FF->head.privpars.size termchar:0]];	// force settings for default font
	[_prompt.textStorage addAttribute:NSForegroundColorAttributeName value:NSColor.textColor range:NSMakeRange(0, _prompt.textStorage.length)];

	_dateformatter = [[NSDateFormatter alloc] init];
//	[_dateformatter setFormatterBehavior:NSDateFormatterBehavior10_4];
	[_dateformatter setDateStyle:NSDateFormatterMediumStyle];
	[_dateformatter setTimeStyle:NSDateFormatterShortStyle];
	
	[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(_scrollPrompt) name:NSViewBoundsDidChangeNotification object:[_entry superview]];
	[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(_showRecord) name:NOTE_CONDITIONALOPENRECORD object:[self document]];
}
- (BOOL)validateMenuItem:(NSMenuItem *)mitem {
	int itemid = [mitem tag];
	
//	NSLog([mitem title]);
	if (itemid == MI_DUPLICATE)
		return _currentRecord > 0;
	if (itemid == TB_PROPAGATE)		// not really validating; just quick way to set state
		[mitem setState:_propagate];
	return YES;
}
- (BOOL)validateToolbarItem: (NSToolbarItem *)toolbarItem {
	int tag = [toolbarItem tag];

//	NSLog(@"RWindow %@",[toolbarItem label]);
	if (![[self window] isMainWindow] || [[self window] toolbar] != [toolbarItem toolbar])
		return NO;
	if (tag == TB_REVERT || tag == TB_ENTERRECORD)
		return _dirty;
	if (tag == TB_PREVRECORD)
		return _prevRecord ? YES : NO;
	if (tag == TB_NEXTRECORD)
		return _nextRecord || _addMode ? YES : NO;
	return YES;		// never validate other items
}
- (NSString *)windowTitleForDocumentDisplayName:(NSString *)docname {
	if (_currentRecord)
		return [NSString stringWithFormat:@"%@: Record %u",docname, _currentRecord];
	else 
		return [NSString stringWithFormat:@"%@: New Record %u",docname, FF->head.rtot+1];
}
- (NSRect)windowWillUseStandardFrame:(NSWindow *)sender defaultFrame:(NSRect)defaultFrame {
	NSRect nrect = [[_parentController window] frame];
	nrect.size.height = 150;
	return nrect;
}
- (void)windowDidMove:(NSNotification *)aNotification {
	if (_allowFrameSet) {
		NSPoint origin = [[_parentController window] frame].origin;
		FF->head.recordviewrect = IRRectFromNSRect([[self window] contentRectForFrameRect:[[self window] frame]]);	// remember content
		FF->head.recordviewrect.origin.x -= origin.x;
		FF->head.recordviewrect.origin.y -= origin.y;
	}
}
- (void)windowDidResize:(NSNotification *)aNotification {
	[self _checkPrompt];	// check, redraw prompt view
	if (_allowFrameSet) {
		NSPoint origin = [[_parentController window] frame].origin;
		FF->head.recordviewrect = IRRectFromNSRect([[self window] contentRectForFrameRect:[[self window] frame]]);	// remember content
		FF->head.recordviewrect.origin.x -= origin.x;
		FF->head.recordviewrect.origin.y -= origin.y;
	}
}
- (void)windowDidUpdate:(NSNotification *)aNotification {
	// need this to stop prompt misscroll after release from resize
	if ([[_prompt superview] bounds].origin.y != [[_entry superview]bounds].origin.y)
		[self _scrollPrompt];
}
- (void)windowWillClose:(NSNotification *)aNotification {
	[[_parentController window] removeChildWindow:[self window]];
	[_parentController enableToolbarItems:YES];	// re-enable font/size items in main window
}
- (BOOL)windowShouldClose:(id)sender {
	if (![self canAbandonRecord]) {	// if we need to consider changes
		int action = NSAlertAlternateReturn;	/* default action check is discard */
		
		if (!sender || g_prefs.gen.saverule == M_SAVE || g_prefs.gen.saverule == M_ASK && 
			(action = savewarning(RECCHANGED, _currentRecord ? _currentRecord : FF->head.rtot+1)) == NSAlertDefaultReturn)
			return [self canCompleteRecord];
		return action == NSAlertOtherReturn;
	}
	return YES;
}
- (void)windowDidBecomeMain:(NSNotification *)notification {
	if (_currentRecord)	// if have active recod
		[_parentController selectRecord:_currentRecord range:NSMakeRange(0,0)];	// select in main window
	else if (_addMode && !g_prefs.gen.track)	{	// if adding and not tracking
		RECN toshow = rec_number(sort_bottom(FF));
		if (toshow)
			[_parentController showRecord:toshow position:VD_SELPOS];
	}
	[_propagateButton setEnabled:YES];
}
- (void)windowDidResignMain:(NSNotification *)notification {
	sort_resortlist(FF,_nptr);		/* bring sort up to date */
	[_parentController updateDisplay];		// just refresh display
	[_propagateButton setEnabled:NO];
}
- (void)setDemoting {
	// make other settings here: force propagate on and disable control? disable other controls?
	// force limit on field splitting and length ?
	[_entry selectField:0];
}
- (BOOL)canAbandonRecord {
	_textDiffers = FALSE;
	if (_dirty) {	// if edited text or changed del/label status
		_revisedString = [_entry getText:YES];	// always recover most recent text
		_textDiffers = !_revisedString || str_xcmp(_originalString, _revisedString);	// if won't release or there's a change changed
	}
	return !_textDiffers && (_deleted == _originalDeleted && _labeled == _originalLabeled || !_currentRecord);
}
- (void)textDidChange:(NSNotification *)note {
	if ([note object] == _entry) {
		[self _checkPrompt];	// check, redraw prompt view
		[_entry getText:NO];	// call to set record length
		[_recordlength setIntValue:FF->head.indexpars.recsize-[_entry textLength]-1];
		_dirty = YES;
	}
}
- (IBAction)toolbarAction:(id)sender {
	NSInteger tag = [sender tag];
	
	if (tag == TB_REVERT)
		[self _setRecord:_currentRecord ? _currentRecord : UINT_MAX];	// reset it
	else if (tag == TB_PREVRECORD)
		[self _stepRecord:-1];
	else if (tag == TB_NEXTRECORD)
		[self _stepRecord:1];
	else if (tag == TB_ENTERRECORD)
		[self duplicate:nil];
}
- (IBAction)duplicate:(id)sender {
	if ([self canAbandonRecord] || [self canCompleteRecord])	{// if can enter
		str_xcpy(_originalString,[_entry getText:YES]);	// get current entry contents
		[self _setRecord:UINT_MAX];	// new record from _originalString
	}
}
- (IBAction)deleted:(id)sender {
	_deleted ^= 1;
	_dirty = TRUE;
	[self showStatus];
}
- (IBAction)labeled:(id)sender {
	int newlabel = [sender tag]-MI_LABEL0;
	if (sender == _entry)	{	// if want V1 toggle
		if (_labeled <= 1)	// if can toggle
			_labeled ^= 1;
		else
			return;
	}
	else 
		_labeled = newlabel == _labeled ? 0 : newlabel;
	_dirty = TRUE;
	[_entry setColorForLabel:_labeled];
	[self showStatus];
}
- (IBAction)setPropagate:(id)sender {
	if ([sender isKindOfClass:[NSMenuItem class]])
		_propagate ^= 1;
	else
		_propagate = [sender state];
}
- (BOOL)canCompleteRecord {
	if (_revisedString) {		// if have string for record
		BOOL newflag = FALSE;
		RECORD * curptr;

		if ([_entry checkErrors:_revisedString])
			return NO;
		if (_currentRecord)	{	// if editing existing
			curptr = rec_getrec(FF,_currentRecord);
			str_xcpy(curptr->rtext,_revisedString);
			curptr->ismark = FALSE;		/* remove any mark */
			curptr->isgen = FALSE;		/* clear autogen flag */
			if (_textDiffers || curptr->isdel != _deleted || curptr->label == _labeled && g_prefs.gen.labelsetsdate)
				rec_stamp(FF,curptr);
		}
		else if (curptr = rec_writenew(FF,_revisedString))
			newflag = TRUE;
		else	// some error
			return NO;
		[_entry copyToFontMap:FF->head.fm];		// recover font map
		curptr->isdel = _originalDeleted = _deleted;	// transfer deleted and label states
		curptr->label = _originalLabeled = _labeled;
		if (_textDiffers)		// update last edited only if text changed (not for del/label)
			FF->lastedited = curptr->num;
		sort_addtolist(_nptr,curptr->num);	/* add to sort list */
		_dirty = NO;
		if (newflag)	{					/* if a new record */
			[_parentController synchronizeWindowTitleWithDocumentName];
			sort_resortlist(FF,_nptr);		/* bring sort up to date */
			if (!FF->curfile)	{		//	(don't display additions when viewing group)
				if (g_prefs.gen.track)		{	/* if tracking new records */
					[self _setPrevNext:curptr];		// reset previous and next records
					_nextRecord = 0;
					[_parentController showRecord:FF->head.rtot position:VD_SELPOS];
				}
				else
					[_parentController updateDisplay];		// just follow selection
			}
		}			/* an existing record revised */
		else {
			if (_propagate)	/* if wanting to propagate changes */
				rec_propagate(FF,curptr,_originalString, _nptr); 	/* do it */
			[_parentController updateDisplay];
		}
		return YES;
	}
	return NO;
}
- (void)openRecord:(RECN)record {
	if ([self canAbandonRecord] || [self canCompleteRecord])
		[self _setRecord:record];
}
- (void)_showRecord {
	if ([[self document] selectedRecords].location != _currentRecord)	// if some object wants new record
		[self openRecord:[[self document] selectedRecords].location];
}
- (void)_setRecord:(RECN)record {
	RECORD * curptr = rec_getrec(FF, record);
	
	if (curptr) {		
		str_xcpy(_originalString,curptr->rtext);	// save original text
		_deleted = _originalDeleted = curptr->isdel;		// initial deleted status
		_labeled = _originalLabeled = curptr->label;	// initial label status
		[self _setPrevNext:curptr];
	}
	else {	// want a new empty record, or a new copy of current
		if (!record) {	// want new empty one
			RECORD * lastptr;
			
			str_xcpy(_originalString,g_nullrec);	// set up empty record
			rec_pad(FF,_originalString);	// pad to min fields
			if (g_prefs.gen.carryrefs && (lastptr = rec_getrec(FF,FF->head.rtot)))	/* if to carry page refs */
				str_xcpy(str_xlast(_originalString),str_xlast(lastptr->rtext));	/* transfer locator & terminate */
		}
		else	// assumed duplicate current (UINT_MAX)
			record = 0;		// ensure _currentRecord set properly
		[_parentController selectRecord:0 range:NSMakeRange(0,0)];	// deselect 
		if (_addMode)	{	// in add mode
			_nextRecord = 0;
			if (!g_prefs.gen.track)	{
				_prevRecord = rec_number(sort_bottom(FF));
				[_parentController showRecord:_prevRecord position:VD_SELPOS];	// shift display
			}
		}
		_labeled = _deleted = 0;	// clear state
	}
	_currentRecord = record;
	[_entry setText:_originalString label:_labeled];
	_dirty = NO;
	[self _checkPrompt];
	[self showStatus];
	[self synchronizeWindowTitleWithDocumentName];	
	[self setDocumentEdited: curptr ? curptr->time > FF->opentime : NO];	// set modified status
}
- (void)_stepRecord:(int)direction {
	if ([self canAbandonRecord] || [self canCompleteRecord])	{
		if (direction > 0 || _prevRecord)	{	// if not trying to move before start
			RECN rec = direction < 0 ? _prevRecord : _nextRecord;
			if (rec)	{	// if anywhere to go
				if ([_parentController selectedRecords].location)	// if selection in main window
					rec = [_parentController stepRecord:direction from:0];	// step to it
				[_parentController selectRecord:rec range:NSMakeRange(0,0)];	// select it directly, since it's unselected
			}
			else if (_addMode)	// set for new record
				[self _setRecord:rec];
		}
	}
}
- (void)_setPrevNext:(RECORD *)recptr {
	RECORD * tptr;
	
	tptr = [[self document] skip:-1 from:recptr];
	_prevRecord = tptr ? tptr->num : 0;
	tptr = [[self document] skip:1 from:recptr];
	_nextRecord = tptr ? tptr->num : 0;
}
- (void)displayError:(NSString *)error {
	if (error)	{
		[_entrydetails setTextColor:[NSColor redColor]];
		[_entrydetails setStringValue:error];
	}	
	else	{
		[_entrydetails setTextColor:[NSColor textColor]];
		[self showStatus];
	}
}
- (void)showStatus {
	NSMutableString * ss = [NSMutableString stringWithCapacity:50];
	char * user;
	BOOL marked;
	double dtime;
	
	if (_currentRecord)	{
		RECORD * curptr = rec_getrec(FF,_currentRecord);
		user = curptr->user;
		marked = curptr->ismark;
		dtime = curptr->time;
	}
	else {
		user = g_prefs.hidden.user;
		marked = FALSE;
		dtime = time(NULL);
	}
	if (dtime >= 0)
		[ss appendFormat:@"%@ %.4s ",[_dateformatter stringFromDate:[NSDate dateWithTimeIntervalSince1970:dtime]], user];
	else
		[ss appendFormat:@"Invalid Date"];
	if (_deleted)
		[ss appendString:@"Deleted "];
	if (_labeled)
		[ss appendFormat:@"Labeled %d ", _labeled];
	if (marked)
		[ss appendString:@"Marked"];
	[_entrydetails setStringValue:ss];
}
- (void)_checkPrompt {
	NSArray *sarray = [_entry lineRanges];
	NSString * tstring = [_entry string];
	int linetot = [sarray count];
	BOOL invalid = FALSE;
	int lcount, level, fieldcount;
	NSRange lrange;
	
	if (linetot) {	// if we have some text to handle
		for (fieldcount = lcount = 0; lcount < linetot; lcount++) {
			unichar echar = 0;
			
			lrange = [[sarray objectAtIndex:lcount] rangeValue];
			if (lcount)	// if not first line, check prev char for end of field
				echar = [tstring characterAtIndex:lrange.location-1];
			if (!lcount || echar == '\n') {
				if (_promptline[fieldcount] != lcount) {	// if prompt line changed
					_promptline[fieldcount] = lcount;
					invalid = TRUE;
				}
				fieldcount++;
			}	
		}
		if ([tstring characterAtIndex:NSMaxRange(lrange)-1] == '\n')	// if haven't counted empty page field
			fieldcount++;
		if (invalid || fieldcount != _fieldcount || linetot != _linetot) {
			NSMutableString *pstring = [NSMutableString stringWithCapacity:50];
			for (level = lcount = 0; lcount < linetot; lcount++) {
				unichar echar = 0;
				
				lrange = [[sarray objectAtIndex:lcount] rangeValue];
				if (lcount)
					echar = [tstring characterAtIndex:lrange.location-1];
				if (!lcount || echar == '\n') {
					int tlevel = level;
					if (tlevel == fieldcount-1)	// if page field
						tlevel = PAGEINDEX;		// use page prompt
					else if (FF->head.indexpars.required && tlevel == fieldcount-2)	// if required last subhead
						tlevel = FF->head.indexpars.maxfields-2;
					[pstring appendString:[NSString stringWithUTF8String:FF->head.indexpars.field[tlevel].name]];
					level++;
				}	
				[pstring appendString:@"\n"];
			}
			if ([tstring characterAtIndex:NSMaxRange(lrange)-1] == '\n')	// if need prompt for empty page field
				[pstring appendString:[NSString stringWithUTF8String:FF->head.indexpars.field[PAGEINDEX].name]];
			[_prompt setString:pstring];
			_fieldcount = fieldcount;
			_linetot = linetot;
		}
	}
}
- (void)_scrollPrompt {
	NSRect erect = [_entry visibleRect];	// get entry view's visible rect
	[(NSClipView *)[_prompt superview] scrollToPoint:erect.origin];	// force prompt clip view to show matching range
}
- (void)textViewDidChangeSelection:(NSNotification *)notification	{
	[_entry textViewDidChangeSelection:notification];
}
- (void)textViewDidChangeTypingAttributes:(NSNotification *)notification {
	[_entry textViewDidChangeTypingAttributes:notification];
}
#if 0
- (NSToolbarItem *)toolbar:(NSToolbar *)toolbar itemForItemIdentifier:(NSString *)itemIdent willBeInsertedIntoToolbar:(BOOL)willBeInserted {
	NSToolbarItem * toolbarItem;
	unsigned int index;
	
	if([itemIdent isEqualToString:IRPropagateToolbarID]) {
		NSMenu *submenu = nil;
		NSMenuItem *submenuItem = nil, *menuFormRep = nil;
	
		toolbarItem = [[NSToolbarItem alloc] initWithItemIdentifier: itemIdent];
		[toolbarItem setLabel:@"Propagate"];
		[toolbarItem setPaletteLabel:@"Propagate"];
		[toolbarItem setToolTip: @"Switch propagation on or off"];
		[toolbarItem setView:_propagateButton];
		[toolbarItem setMinSize:NSMakeSize(24,24)];
		[toolbarItem setMaxSize:NSMakeSize(32,32)];
		[toolbarItem setTarget:nil];
		[toolbarItem setAction:@selector(setPropagate:)];
		[_propagateButton setState:_propagate];

		// now set menu in case need text mode
		submenu = [[NSMenu alloc] init];
		submenuItem = [[NSMenuItem alloc] initWithTitle: @"Propagate" action: @selector(setPropagate:) keyEquivalent: @""];
		[submenuItem setState:_propagate];
		[submenuItem setTag:TB_PROPAGATE];
		menuFormRep = [[NSMenuItem alloc] init];
		[submenu addItem: submenuItem];
		[submenuItem setTarget: self];
		[menuFormRep setSubmenu: submenu];
		[menuFormRep setTitle: [toolbarItem label]];
		[toolbarItem setMenuFormRepresentation: menuFormRep];

		return toolbarItem;
	}
	for (index = 0; index < MAXTBITEMS; index++) {
		if ([itemIdent isEqualToString:tbitems[index].identifier]) {
			toolbarItem = [[NSToolbarItem alloc] initWithItemIdentifier: itemIdent];
			
			[toolbarItem setTag:tbitems[index].tag];
			[toolbarItem setLabel:tbitems[index].label];
			[toolbarItem setPaletteLabel:tbitems[index].label];
			[toolbarItem setToolTip:tbitems[index].tooltip];
			[toolbarItem setImage:[NSImage imageNamed:tbitems[index].image]];
//			if (tbitems[index].tag == TB_BOLD || tbitems[index].tag == TB_ITALIC)
//				[toolbarItem setTarget:[NSFontManager sharedFontManager]];
//			else
//				[toolbarItem setTarget:self];
			[toolbarItem setTarget:tbitems[index].target];
			[toolbarItem setAction:NSSelectorFromString(tbitems[index].action)];
			return toolbarItem;
		}
	}
	return nil;
}
- (NSArray *)toolbarDefaultItemIdentifiers: (NSToolbar *) toolbar {
    return [NSArray arrayWithObjects:IRPropagateToolbarID,IRBraceToolbarID,IRAngleToolbarID,IRFlipNoToolbarID,IRFlipToolbarID,IRParenToolbarID,
		IRFontToolbarID,IRBoldToolbarID,IRItalicToolbarID,IRUlineToolbarID,IRRevertToolbarID,IRPrevToolbarID,IRNextToolbarID,IREnterToolbarID,
		nil];
}
- (NSArray *)toolbarAllowedItemIdentifiers: (NSToolbar *) toolbar {
    return [NSArray arrayWithObjects:IRPropagateToolbarID,IRBraceToolbarID,IRAngleToolbarID,IRFlipNoToolbarID,IRFlipToolbarID,IRParenToolbarID,
		IRFontToolbarID,IRBoldToolbarID,IRItalicToolbarID,IRUlineToolbarID,IRRevertToolbarID,IRPrevToolbarID,IRNextToolbarID,IREnterToolbarID,
		/* NSToolbarShowColorsItemIdentifier, */ NSToolbarShowFontsItemIdentifier,  NSToolbarCustomizeToolbarItemIdentifier,
		NSToolbarFlexibleSpaceItemIdentifier, NSToolbarSpaceItemIdentifier, NSToolbarSeparatorItemIdentifier, nil];
}
#endif
- (void)checkFormatItems:(NSMenu *)tmenu {
	unsigned int attribs = [_entry textAttributes:nil];
	
	[[tmenu itemWithTag:MI_SMALL] setState:attribs&FX_SMALL];
	[[tmenu itemWithTag:MI_SUPER] setState:attribs&FX_SUPER];
	[[tmenu itemWithTag:MI_SUB] setState:attribs&FX_SUB];
}
@end

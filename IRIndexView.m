//
//  IRIndexView.m
//  Cindex
//
//  Created by PL on 2/18/05.
//  Copyright 2005 Indexing Research. All rights reserved.
//

#import "IRIndexDocument.h"
#import "IRIndexDocumentController.h"
#import "IRIndexDocWController.h"
#import "IRIndexView.h"
#import "IRIndexRecordWController.h"
#import "sort.h"
#import "collate.h"
#import "commandutils.h"
#import "cindexmenuitems.h"
#import "strings_c.h"
#import "IRDisplayString.h"

//NSString * IRRecordsPBoardType = @"IRRecordsPasteboard3";
NSString * IRRecordsPBoardType = @"com.indexres.pbrecords3";

static NSCursor * _rightCursor;
static NSTrackingArea * rightCursorTrackingArea;

@interface IRIndexView () {
}
@property (assign) IRIndexDocWController <IRIndexViewDelegate, NSObject> * owner;
@property (assign) IRIndexDocument * document;

- (void)_stepRecord:(int)step mode:(int)mode;
- (void)_selectFrom:(RECN)base to:(RECN)end;
@end

@implementation IRIndexView


+ (void)initialize {
	_rightCursor = getcursor(@"rightcursor",NSMakePoint(14,1));
	[_rightCursor setOnMouseEntered:YES];
}
- (void)awakeFromNib {
	[super awakeFromNib];
	self.editable = NO;
	self.verticallyResizable = NO;
	self.autoresizingMask = NSViewNotSizable;
	self.owner = (id)[self delegate];	// NSTextView delegate is owning IRIndexDocWController
	self.document = [(IRIndexDocWController *)_owner document];
	_repeatdelay = [[NSUserDefaults standardUserDefaults] integerForKey:@"InitialKeyRepeat"];
	if (!_repeatdelay)
		_repeatdelay = 35;
	[self registerForDraggedTypes:[NSArray arrayWithObject:IRRecordsPBoardType]];
}
- (void)dealloc {
	self.owner = nil;
	self.document = nil;
}
- (NSMenu *)menuForEvent:(NSEvent *)theEvent {
	NSMenuItem * titem = [[self menu] itemWithTag:MI_LABELED];
	
	buildlabelmenu([titem submenu],14);	// set current label colors
	[titem setEnabled:_firstSelected > 0];
	return [self menu];
}
- (BOOL)performKeyEquivalent:(NSEvent *)theEvent {
	NSEventModifierFlags mflags = [theEvent modifierFlags];

	if (mflags&NSCommandKeyMask) {	// if cmnd-key (function keys don't necess need it to have Key Equivs)
		NSString * kchars = [theEvent charactersIgnoringModifiers];
		unichar uchar = [kchars characterAtIndex:0];
		
		switch (uchar)		{
			case '=':		// toggle label 1
				if ([_document selectedRecords].location)
					[_document labeled:nil];
				else
					NSBeep();
				return YES;
		}
	}
	return NO;
}
- (void)changeFont:(id)sender {
	INDEX * FF = [_document iIndex];
	NSString * oldname = [NSString stringWithUTF8String:FF->head.fm[0].name];
	NSFont *oldFont = [[NSFontManager sharedFontManager] fontWithFamily:oldname traits:0 weight:5 size:FF->head.privpars.size];
    NSFont *newFont = [sender convertFont:oldFont];
	char * newname = (char *)[[newFont familyName] UTF8String];
	
	if (!strcmp(FF->head.fm[0].name,FF->head.fm[0].pname))	// if preferred and alt were same
		strcpy(FF->head.fm[0].pname,newname);		// change preferred
	strcpy(FF->head.fm[0].name,newname);
	FF->head.privpars.size = [newFont pointSize];
	[_document redisplay:0 mode:VD_CUR];
}
- (NSFontPanelModeMask)validModesForFontPanel:(NSFontPanel *)fp {
	return NSFontPanelFaceModeMask|NSFontPanelCollectionModeMask|NSFontPanelSizeModeMask;
}
- (BOOL)validateMenuItem:(NSMenuItem *)mitem {
	NSInteger itemid = [mitem tag];
	
//	NSLog([mitem title]);
	if (itemid == MI_SELECTALL)
		return ![_document recordWindowController];
	if (itemid == MI_PASTE)
		return ![_document recordWindowController] && [[[NSPasteboard generalPasteboard] types] indexOfObject:IRRecordsPBoardType] != NSNotFound;
	if (itemid >= MI_ALIGNNATURAL && itemid <= MI_ALIGNRIGHT)	{
		[mitem setState:[_document iIndex]->head.formpars.pf.alignment == itemid-MI_ALIGNNATURAL];
		return YES;
	}
	return [super validateMenuItem:mitem];
}

- (void)cursorUpdate:(NSEvent *)theEvent	{if ( rightCursorTrackingArea ) {
	// check if mouse pointer is in the tracking area; avoid resetting if it is
	if ( !NSPointInRect([[self window] mouseLocationOutsideOfEventStream], [rightCursorTrackingArea rect]) ) {
			[[NSCursor arrowCursor] set];
		}
	}
}
- (BOOL)acceptsFirstMouse:(NSEvent *)theEvent	{
	return [[_document recordWindowController] window] == [IRdc lastKeyWindow];	// accept click from record-entry window
}
- (void)mouseMoved:(NSEvent *)theEvent	{
	// need to override to prevent text cursor overriding our cursor
}
- (void)mouseEntered:(NSEvent *)theEvent	{
	// need to override to prevent text cursor overriding our cursor
	
	// set mouse cursor to rightCursor
	[_rightCursor set];
}
- (void)mouseExited:(NSEvent *)theEvent	{
	// need to override to prevent text cursor overriding our cursor
	
	// reset mouse cursor back to regular pointer
	[[NSCursor arrowCursor] set];
}
- (void)mouseDown:(NSEvent *)theEvent	{
	[_owner displayError:nil];	// clear any displayed error
	if ([_document canCloseActiveRecord])	{	// if don't have record window or entry is ok
		RECN recordatmouse = [self recordAtMouseLocationWithAttributes:nil];	// get current record
		
		BOOL down = YES;
		BOOL rightcursor = [NSCursor currentCursor] == _rightCursor;
		NSEvent * scrollevent = nil;
		BOOL isinselection = NSLocationInRange([self characterIndexForPoint:[NSEvent mouseLocation]],[self selectedRange]);
//		NSTimeInterval downtime = [theEvent timestamp];
		BOOL hasdragged = NO;
		
		if ([theEvent clickCount] == 2 && recordatmouse == _firstSelected)		{	// if double click 
			[_document openRecord:_firstSelected];	// open current record
			return;
		}
		if (rightcursor) 	{	// select any lower identical headings if right click
			[_owner selectLowerRecords];
			_lastSelected = [_owner selectedRecords].location;
			_firstSelected = [_owner selectedRecords].length;
		}
		else if ([theEvent modifierFlags]&NSShiftKeyMask)		{	// if extending selection
			_lastSelected = recordatmouse;
			[self _selectFrom:_firstSelected to:_lastSelected];
		}
		else	{	// set default start and end
			_firstSelected = _lastSelected = recordatmouse;
			if (!isinselection)	
				[self _selectFrom:_firstSelected to:_lastSelected];
		}
		[NSEvent startPeriodicEventsAfterDelay:0.2 withPeriod:.05];
		while (down)	{
			theEvent = [NSApp nextEventMatchingMask:NSPeriodicMask|NSLeftMouseUpMask|NSLeftMouseDraggedMask untilDate:[NSDate date] inMode:NSEventTrackingRunLoopMode dequeue:YES];
			
			switch ([theEvent type])	{
				case NSLeftMouseUp:
					down = NO;
					break;
				case NSPeriodic:
					if (scrollevent)	{	// if ready for autoscroll
						[self autoscroll:scrollevent];
						break;
					}
					continue;
				case NSLeftMouseDragged:
					if (!hasdragged && isinselection && !rightcursor)	{	// if drag started in existing selection
						[NSEvent stopPeriodicEvents];
						NSPasteboardItem *pbItem = [NSPasteboardItem new];
						if ([_document iIndex]->head.privpars.vmode == VM_FULL)
							[pbItem setDataProvider:self forTypes:[NSArray arrayWithObjects:IRRecordsPBoardType,NSPasteboardTypeRTF,NSPasteboardTypeString,nil]];
						else
							[pbItem setDataProvider:self forTypes:[NSArray arrayWithObjects:IRRecordsPBoardType,NSPasteboardTypeRTF,nil]];
						NSDraggingItem *dragItem = [[NSDraggingItem alloc] initWithPasteboardWriter:pbItem];
						NSPoint dragPosition;
						NSImage * di = [self dragImageForSelectionWithEvent:theEvent origin:&dragPosition];
//						NSPoint eventPosition = [self convertPoint:theEvent.locationInWindow fromView:nil];
						NSRect draggingRect = NSMakeRect(dragPosition.x, dragPosition.y-di.size.height, di.size.width, di.size.height);
						[dragItem setDraggingFrame:draggingRect contents:di];
						NSDraggingSession *draggingSession = [self beginDraggingSessionWithItems:[NSArray arrayWithObject:dragItem] event:theEvent source:self];
						draggingSession.animatesToStartingPositionsOnCancelOrFail = YES;
						return;
					}
					hasdragged = YES;
					scrollevent = nil;
					if ([self autoscroll:theEvent])
						scrollevent = theEvent;	// save this event to provide mouse loc for periodic
					break;
				default:
					continue;
			}
			_lastSelected = [self recordAtMouseLocationWithAttributes:nil];
			[self _selectFrom:_firstSelected to:_lastSelected];
		}
		[NSEvent stopPeriodicEvents];
		if (_firstSelected != _lastSelected && [_document recordWindowController])	// ensure single selection if rec window open
			[self _selectFrom:_lastSelected to:_lastSelected];
		[[NSNotificationCenter defaultCenter] postNotificationName:NOTE_CONDITIONALOPENRECORD object:_document];
	}
}
#if 0
- (void)keyUp:(NSEvent *)theEvent {
	[[NSNotificationCenter defaultCenter] postNotificationName:NOTE_SCROLLKEYEVENT object:theEvent];
	[super keyUp:theEvent];
}
#endif
- (void)keyDown:(NSEvent *)theEvent {
	NSString * kchars = [theEvent characters];
	if (kchars.length) {	// if not a dead key
		unichar uchar = [kchars characterAtIndex:0];

		[_owner displayError:nil];
		switch (uchar) {
			case 0x1b:	// escape key
				if (![_document recordWindowController])	{
					[_owner selectRecord:0 range:NSMakeRange(0,0)];
	//				[self setSelectedRange:NSMakeRange(0,0)];
					_lastkeytime = 0;
					[_owner displaySearchString:[NSString string] error:NO];
				}
				return;
			case NSUpArrowFunctionKey:
				[self _stepRecord:-1 mode:[theEvent modifierFlags]&NSShiftKeyMask];
				return;
			case NSDownArrowFunctionKey:
				[self _stepRecord:1 mode:[theEvent modifierFlags]&NSShiftKeyMask];
				return;
			case NSHomeFunctionKey:
				[_owner showRecord:rec_number(sort_top([_document iIndex])) position:VD_TOP];
				return;
	#if 0
			case NSPageDownFunctionKey:
			case NSPageUpFunctionKey:
				_fromKey = YES;
				[super keyDown:theEvent];
				return;
	#endif
			case NSEndFunctionKey:
				[_owner showRecord:rec_number(sort_bottom([_document iIndex])) position:VD_TOP];
				return;
			case '\t':
	//			[_owner selectRecord:[_owner selectedRecords].location range:NSMakeRange(0,0)];
				[_owner showRecord:[_owner selectedRecords].location position:VD_SELPOS];
				return;
			case 0x3:	// enter key
			case '\r':
				[NSApp sendAction:@selector(editRecord:) to:nil from:self];
				return;
		}
		_currentkeytime = [theEvent timestamp];		//!! NB time is set from any key, not just character key
	}
	[super keyDown:theEvent];
}
#if 0
-(void)setSelectedRange:(NSRange)range {
	[super setSelectedRange:range];
	NSLog ([[[self textStorage] string] substringWithRange:range]);
}
#endif
- (void)setFirstSelected:(RECN)base {		// sets first record of new selection
	_firstSelected = _lastSelected = base;
}
- (void)_selectFrom:(RECN)base to:(RECN)end {
	NSRange startrange = NSMakeRange(0,0);
	NSRange endrange = NSMakeRange([[self string] length],0);
	NSRange baserange = [self characterRangeForRecord:base];
	NSRange currentrange = [self characterRangeForRecord:end];
	int direction = sort_relpos([_document iIndex],base,end);
	
//	NSLog(@"%d,%d,%@,%@",base, end, NSStringFromRange(baserange),NSStringFromRange(currentrange));
	if (!baserange.length)	// if base not visible
		baserange = direction < 0 ? startrange : endrange;
	if (!currentrange.length)	// if current not visible
		currentrange = direction < 0 ? endrange : startrange;
	[self setSelectedRange:NSUnionRange(baserange,currentrange)];
	[_owner setSelectedRecords:direction < 0 ? NSMakeRange(base,end) : NSMakeRange(end,base)];
}
- (NSRange)selectionRangeForProposedRange:(NSRange)prange granularity:(NSSelectionGranularity)granularity {
	return [_owner normalizedCharacterRange:prange];	// select by records
}
- (void)_stepRecord:(int)step mode:(int)mode {
	if ([_document canCloseActiveRecord])		{	// if don't have record window or entry is ok
		if (mode)	{		// if extending selection
			RECORD * recptr = rec_getrec([_document iIndex],_lastSelected);
			if (recptr)	{
				recptr = [_document skip:step from:recptr];
				if (recptr)	{
					NSRange cr = [self characterRangeForRecord:recptr->num];
					if (!cr.length)	// if not on screen	{
						[_owner stepRecord:step from: _lastSelected];
					[self _selectFrom:_firstSelected to:recptr->num];
					_lastSelected = recptr->num;
				}
			}
		}
		else	{
			[_owner stepRecord:step from:0];
			_lastSelected = [_owner selectedRecords].location;
		}
	}
}
-(IBAction)copy:(id)sender {
	[_owner copySelectionToPasteboard:[NSPasteboard generalPasteboard]];
}
-(IBAction)paste:(id)sender {
	if (![_document iIndex]->readonly)
		[_owner copyRecordsFromPasteboard:[NSPasteboard generalPasteboard]];
}
- (IBAction)selectAll:(id)sender {
	[super selectAll:sender];
	[_owner selectAllRecords];
}
- (IBAction)alignCenter:(id)sender {
	[_document iIndex]->head.formpars.pf.alignment = [sender tag]-MI_ALIGNNATURAL;
	[_document redisplay:0 mode:VD_CUR];
}
- (IBAction)alignLeft:(id)sender {
	[_document iIndex]->head.formpars.pf.alignment = [sender tag]-MI_ALIGNNATURAL;
	[_document redisplay:0 mode:VD_CUR];
}
- (IBAction)alignRight:(id)sender {
	[_document iIndex]->head.formpars.pf.alignment = [sender tag]-MI_ALIGNNATURAL;
	[_document redisplay:0 mode:VD_CUR];
}
//- (void)insertText:(NSString *)text {
- (void)insertText:(id)text replacementRange:(NSRange)replacementRange {
	if ([text length] && [_document canCloseActiveRecord])	{	// if not dead key && don't have record window or entry is ok
		NSUInteger length = [text length];
		UErrorCode error = 0;
		int stringlength;
		char buffer[100];
		
		if (!_lastkeytime || _currentkeytime > _lastkeytime + _repeatdelay*2./60) {
			memset(_searchstring,0,sizeof(_searchstring));
			_holdptr = _stringptr = _searchstring;	// reset string
		}
		_badstring = FALSE;
		for (int index = 0; index < length; index++)	// add new characters to string
			*_stringptr++ = [text characterAtIndex:index];
		u_strToUTF8(buffer,100,&stringlength,_searchstring,-1,&error);
		if ((*(_stringptr-1) == '\\' || *(_stringptr-1) == ';') && *(_stringptr-2) != '\\' || (!col_collatablelength([_document iIndex],buffer) && !u_isdigit(*(_stringptr-1))))	// if special lead or no primary search text
			_holdptr = _stringptr;	/* don't seek until we have another character */
		if (_stringptr > _holdptr)	{	/* if not holding */
//			NSLog(@"Search: %s",buffer);
			RECN rnum;
			if (rnum = com_findrecord([_document iIndex],buffer,FALSE, WARNNEVERBOX))		/* if can find record */
				[_document selectRecord:rnum range:NSMakeRange(0,0)];
			else
				_badstring = TRUE;
		}
		[_owner displaySearchString:[NSString stringWithUTF8String: buffer] error:_badstring];
		_lastkeytime = _currentkeytime;
	}
	else
		[super insertText:text replacementRange:replacementRange];
}

// add tracking area upon update event if isn't already initialized
- (void) updateTrackingAreas {
	[self createAndAddRightMarginTrack];
	[super updateTrackingAreas];
}

- (void) createAndAddRightMarginTrack {
	// invalidate tracking area before initializing
	if ( rightCursorTrackingArea != nil )
		[self removeTrackingArea:rightCursorTrackingArea];
		
	int rwidth = [_owner rightCursorWidth];
	NSRect rrect = [self visibleRect];

	rrect.origin.x += 1;		// doesn't catch left entry if origin is 0;
	rrect.size.width = rwidth;	// marginal rect for right-pointing cursor
	
	// create tracking area and add it to the window
	rightCursorTrackingArea = [[NSTrackingArea alloc] initWithRect:rrect options:(NSTrackingMouseEnteredAndExited | NSTrackingActiveAlways) owner:self userInfo:nil];
	[self addTrackingArea:rightCursorTrackingArea];
}

#pragma NSDraggingSession
- (NSDragOperation)draggingSession:(NSDraggingSession *)session sourceOperationMaskForDraggingContext:(NSDraggingContext)context {
	return NSDragOperationCopy;
}
- (void)pasteboard:(NSPasteboard *)sender item:(NSPasteboardItem *)item provideDataForType:(NSString *)type {
	//sender has accepted the drag and now we need to send the data for the type we promised
	[_owner copySelectionToPasteboard:sender forType:type];
}
- (BOOL)prepareForDragOperation:(id < NSDraggingInfo >)sender	{
	return YES;
}
- (BOOL)performDragOperation:(id <NSDraggingInfo>)sender {
	return [_owner copyRecordsFromPasteboard:[sender draggingPasteboard]];
}
- (void)concludeDragOperation:(id <NSDraggingInfo>)sender {
	[[self window] makeKeyAndOrderFront:self];
}
- (NSDragOperation)draggingEntered:(id <NSDraggingInfo>)sender {
	if (![_document recordWindowController] && [[[sender draggingPasteboard] types] indexOfObject:IRRecordsPBoardType] != NSNotFound && [sender draggingSource] != self && ![_document iIndex]->readonly)
		_currentDragOperation =  NSDragOperationCopy;
	else
		_currentDragOperation = NSDragOperationNone;
	return _currentDragOperation;
}
- (NSDragOperation)draggingUpdated:(id <NSDraggingInfo>)sender {
	return _currentDragOperation;
}
- (RECN)recordAtMouseLocationWithAttributes:(NSDictionary **)dicptr {	// returns record num & dictionary if wanted
	NSUInteger textlen = [[self textStorage] length];

	if (textlen)	{
		NSUInteger charindex = [self characterIndexForPoint:[NSEvent mouseLocation]];
		NSNumber * recnum;
		
		if (charindex >= textlen)	// if location not within range
			charindex = textlen-1;	// force record that's last
		recnum = [[self textStorage] attribute:IRRecordNumberKey atIndex:charindex effectiveRange:NULL];
		if (dicptr)
			*dicptr = [[self textStorage] attributesAtIndex:charindex effectiveRange:nil];
		return [recnum intValue];
	}
	return 0;
}
- (NSRange)characterRangeForRecord:(RECN)record {
	NSUInteger length = [[self textStorage] length];
	NSRange limitRange = NSMakeRange(0, length);
	id attributeValue;
	NSRange effectiveRange;

	while (limitRange.length > 0) {
		attributeValue = [[self textStorage] attribute:IRRecordNumberKey atIndex:limitRange.location longestEffectiveRange:&effectiveRange inRange:limitRange];
		if ([attributeValue intValue] == record) {
//			NSLog(@"%@ %@", [attributeValue stringValue] ,NSStringFromRange(effectiveRange));	// offset and range
			return effectiveRange;
		}
		limitRange = NSMakeRange(NSMaxRange(effectiveRange),  NSMaxRange(limitRange) - NSMaxRange(effectiveRange));
	}
	return NSMakeRange(NSNotFound,0);
}
#if 0
- (RECN)lastVisibleRecord:(NSDictionary **)dicptr {	// returns record num & dictionary if wanted
	NSUInteger tlength = [[self textStorage] length];
	
	if (tlength)	{
		NSRect vrect = [self visibleRect];
#if 0
		NSPoint lpoint = NSMakePoint(vrect.origin.x+vrect.size.width, vrect.origin.y+vrect.size.height);
		NSUInteger charindex = [self characterIndexForPoint:[[self window] convertBaseToScreen:[self convertPoint:lpoint toView:nil]]];
#else
		NSRect pr = NSZeroRect;
		pr.origin = [self convertPoint:NSMakePoint(vrect.origin.x+vrect.size.width, vrect.origin.y+vrect.size.height) toView:nil];
		NSRect loc = [[self window] convertRectToScreen:pr];	// get loc in screen coordinates
		NSUInteger charindex = [self characterIndexForPoint:loc.origin];
#endif
		NSNumber * recnum;
		
		if (charindex >= tlength)	// if location not within range
			charindex = tlength-1;	// force record that's last
		recnum = [[self textStorage] attribute:IRRecordNumberKey atIndex:charindex effectiveRange:NULL];
		if (dicptr)
			*dicptr = [[self textStorage] attributesAtIndex:charindex effectiveRange:nil];
		return [recnum intValue];
	}
	return 0;
}
#endif
@end

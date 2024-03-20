//
//  IRIndexDocWController.m
//  Cindex
//
//  Created by PL on 1/8/05.
//  Copyright 2005 Indexing Research. All rights reserved.
//

#import "IRIndexDocumentController.h"
#import "IRIndexDocWController.h"
#import "IRIndexRecordWController.h"
#import "ExportOptionsController.h"
#import "IRAttributedDisplayString.h"
#import "AttributedStringCategories.h"
#import "formattedtext.h"
#import "type.h"
#import "strings_c.h"
#import "search.h"
#import "commandutils.h"
#import "cindexmenuitems.h"
#import "export.h"
#import "index.h"
#import "collate.h"

#import "StorageCategories.h"
#import "LayoutDescriptor.h"

#define cliprec(AA,BB)	((RECORD *)((AA)->array+(BB)*(sizeof(RECORD)+(AA)->cs.longest)))

#define SMALLVIEWSET 300

//static NSString* IRDocWToolbarID = @"IRDocToolbarIdentifier";

//static NSString* IRFontItemToolbarID = @"IRFontItemIdentifier";
//static NSString* IRSizeItemToolbarID = @"IRSizeItemIdentifier";
//static NSString* IRNewRecordToolbarID = @"IRNewRecordTBIdentifier";
//static NSString* IRLabelToolbarID = @"IRlabelTBIdentifier";
//static NSString* IRDeleteToolbarID = @"IRDeleteTBIdentifier";
//static NSString* IRAllRecordsToolbarID = @"IRAllRecordsTBIdentifier";
//static NSString* IRFullToolbarID = @"IRFullTBIdentifier";
//static NSString* IRDraftToolbarID = @"IRDraftTBIdentifier";
//static NSString* IRIndentedToolbarID = @"IRIndentedTBIdentifier";
//static NSString* IRRuninToolbarID = @"IRRuninTBIdentifier";
//static NSString* IRAlphaSortToolbarID = @"IRAlphaSortTBIdentifier";
//static NSString* IRPageSortToolbarID = @"IRPageSortTBIdentifier";
//static NSString* IRFormatToolbarID = @"IRFormatTBIdentifier";
//static NSString* IRStyleToolbarID = @"IRStyleTBIdentifier";
//static NSString* IRSortToolbarID = @"IRSortTBIdentifier";

//static unichar nl[] = {'\n','\n','\n','\n','\n','\n','\n','\n','\n','\n'};
//#define MAXWIDOWS (sizeof (nl)/sizeof(unichar))

@interface IRIndexDocWController () {
	IBOutlet NSComboBox * defaultFont;
	IBOutlet NSComboBox * defaultSize;
	IBOutlet NSPopUpButton * label;
//	IBOutlet __weak NSSegmentedControl * iFormat;
//	IBOutlet __weak NSSegmentedControl * iStyle;
//	IBOutlet __weak NSSegmentedControl * iSort;
//	IBOutlet __weak NSButton * viewAll;
//	IBOutlet __weak NSButton * delete;
//	IBOutlet __weak NSButton * newRecord;
	
//	IBOutlet NSToolbar * toolbar;

	BOOL scrollDisabled;
	BOOL shownReadonlyInfo;
}
@property(strong) NSMutableArray * paragraphs;
@property(strong) NSMutableArray * layoutDescriptors;
@property(strong) NSTextStorage * recordStorage;

- (BOOL)_isScrollable;
- (void)_setScrollIndicator;
- (void)_setScrollLimit;
- (void)_resetContainer;
- (void)_redisplay:(NSNotification *)note;
- (void)_fillViewFromRecord:(RECN)record line:(int)start;
- (void)_loadMainView;	
- (LayoutDescriptor *)_makeDescriptorForRecord:(RECORD *)recptr;
- (void)_stepView:(int)step;
- (LayoutDescriptor *)_descriptorForRecord:(RECN)record startLine:(int *)lineptr;
- (void)_configureParagraphs;
@end

@implementation IRIndexDocWController

- (id)init	{
    if (self = [super initWithWindowNibName:@"IRIndexDocWController"]) {
		[self setShouldCloseDocument:YES];
		_scrollLineHeight = 10;		// default scrollline
	}
    return self;
}
- (void)dealloc {
	self.recordStorage = nil;
	self.layoutDescriptors = nil;
	self.paragraphs = nil;
}
- (void)enableToolbarItems:(BOOL)enabled {
	[defaultFont setEnabled:enabled];
	[defaultSize setEnabled:enabled];
	[label setEnabled:enabled];
}
- (IRIndexPrintView *)printView {
	IRIndexPrintView * pview = [[IRIndexPrintView alloc] initWithDocument:self.document paragraphs:_paragraphs];
	return pview;
}
- (void)awakeFromNib {
	[super awakeFromNib];
	FF = [self.document iIndex];
	NSPrintInfo * pinfo = [self.document printInfo];
	NSRect prect = NSMakeRect(0,0,[pinfo paperSize].width-[pinfo rightMargin]-[pinfo leftMargin],
					[pinfo paperSize].height-[pinfo topMargin]-[pinfo bottomMargin]);
	NSLayoutManager * lm = [[NSLayoutManager alloc] init];
	NSTextContainer * tc = [[NSTextContainer alloc] initWithContainerSize:[[_indexView textContainer] containerSize]];
	
	self.recordStorage = [[NSTextStorage alloc] init];
	[_recordStorage addLayoutManager:lm];
	[lm addTextContainer:tc];
	buildlabelmenu([label menu],0);	// set current label colors
	[defaultFont addItemsWithObjectValues:[IRdc fonts]];
	if (@available(macOS 11.0, *)) {
		[self window].toolbarStyle = NSWindowToolbarStyleExpanded;
	}
	if (FF->head.mainviewrect.size.height)	{
		[self setShouldCascadeWindows:NO];
		[[self window] setFrame:[[self window] frameRectForContentRect:NSRectFromIRRect(FF->head.mainviewrect)] display:NO];
	}
	else		// never had frame set 
		[[self window] setContentSize:prect.size];
	_allowFrameSet = YES;
	[self _resetContainer];

	[_clipView setCopiesOnScroll:NO];
	[_clipView setDocumentCursor:[NSCursor arrowCursor]];
	_displayRect = _clipView.bounds;	// a convenience; always tracks bounds rect of clip view
	_indexView.frame = _displayRect;
//	[_indexView setVerticallyResizable:NO];
//	[_indexView setAutoresizingMask:NSViewNotSizable];
//	[_indexView removeFromSuperview];	// hold to reinstate as subview of _scrollingView

//	_scrollingView = [[NSView alloc] initWithFrame:[_indexView frame]];	// variable height scrolling view that will contain fixed height text view
	[_scrollView setDocumentView:_scrollingView];
//	[_scrollingView addSubview:_indexView];	// text view must end up as subview somewhere as descedent of clip view, otherwise text drag doesn't force scroll
	
//	[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(_scrollMainView:) name:NSScrollViewDidLiveScrollNotification object:nil];
//	[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(_scrollMainView:) name:NSScrollViewDidEndLiveScrollNotification object:nil];
	[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(_scrollMainView:) name:NSViewBoundsDidChangeNotification object:_clipView];
	[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(_sizemainView:) name:NSViewFrameDidChangeNotification object:_clipView];
	
	[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(_redisplay:) name:NOTE_REDISPLAYDOC object:self.document];
	[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(_resetContainer) name:NOTE_REVISEDLAYOUT object:self.document];
	[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(_fontsChanged) name:NOTE_FONTSCHANGED object:self.document];
	[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(_prefsChanged) name:NOTE_PREFERENCESCHANGED object:nil];
	[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(updateProgress:) name:NOTE_PROGRESSCHANGED object:nil];
//	[[self window] makeFirstResponder:_indexView];
	[self.document redisplay:0 mode:VD_RESET];
}
#if 0		// use if implement hideinactive
- (void)showWindow:(id)sender {
	if (g_prefs.hidden.hideinactive)	{	// if hiding inactive programs
		NSEnumerator * docnum = [[IRdc documents] objectEnumerator];
		IRIndexDocument * doc;
		
		while (doc = [docnum nextObject])	{	// for all documents
			if (self.document != doc)	// if not wanted 
				[doc hideWindows];	// hide
		}
	}
}
#endif
- (void)_prefsChanged {
	buildlabelmenu([label menu], 0);	// set current label colors
	[self updateDisplay];
}
- (void)updateProgress:(NSNotification *)note {
	if (self.window.isKeyWindow )
		progress.doubleValue = [[note object] doubleValue];
}
- (BOOL)_isScrollable {
	return [_scrollingView frame].size.height > _displayRect.size.height;
}
- (void)_setScrollLimit {
//	NSLog(@"Start limit");
	NSRect srect = _displayRect;		// scrollable height defaults to 1 page
	RECORD * recptr = sort_top(FF);
	double filledHeight = 0, filledRecords = 0;
	for (int count = 0; recptr && count < 250; recptr = [self.document skip:1 from:recptr],count++)	{	// scan sample records
		LayoutDescriptor * ld = [self _makeDescriptorForRecord:recptr];
		filledHeight += [ld height];
		filledRecords += [ld recordsConsumed];
	}
	if (filledHeight)	// if anything to display
		srect.size.height += _visibleRecords * filledHeight / filledRecords;	// scrollable height is index height + 1 page
	scrollDisabled = YES;
	[_scrollingView setFrameSize:srect.size];
	scrollDisabled = NO;
	[self _setScrollIndicator];		// reset indicator as relevant
//	NSLog(@"End limit");
}
- (void)_setScrollIndicator{
	// called after direct load of records into _indexView
	if (_layoutDescriptors) {	// if any records in view
		RECN record = [[_layoutDescriptors objectAtIndex:0] record];
		float position;
		float scrollposition;
		
		if (_visibleRecords < SMALLVIEWSET)	// if small viewable set
			position = (float)sort_viewindexforrecord(FF,record)/_visibleRecords;	// zero based position
		else
			position = sort_findpos(FF,record);	// zero based position
//		NSLog(@"position: %f", position);
		if (!position || rec_number(sort_top(FF)) == record)	// to top (test record because position might reflect invisible deleted records)
			scrollposition = [_scrollingView frame].size.height-_displayRect.size.height;
		else if (position == 1)	// bottom
			scrollposition = 0;
		else
			scrollposition = ([_scrollingView frame].size.height-_displayRect.size.height)*(1-position);
		scrollDisabled = YES;
		_displayRect.origin.y = scrollposition;
		_lastScrollPosition = scrollposition;		// reset scroll position
		[_clipView setBoundsOrigin:_displayRect.origin];
		[_indexView setFrameOrigin:_displayRect.origin];
		scrollDisabled = NO;
	}
}
- (void)_scrollMainView:(NSNotification *)aNotification {	// called on bounds change for clip view
//	NSLog (@"Bounds: %@",NSStringFromRect([_clipView bounds]));	// use position of bounds rect of clip view
//	if (floorf(_displayRect.origin.y+_displayRect.size.height) <= floorf([_scrollingView frame].size.height))	{	// if not bouncing
//		NSLog (@"In Bounds: %@",NSStringFromRect([_clipView bounds]));	// use position of bounds rect of clip view
	if ([self _isScrollable] && !scrollDisabled)	{
		_displayRect.origin = [_clipView bounds].origin;	// use position of bounds rect of clip view
		[_indexView setFrameOrigin:_displayRect.origin];
		float pos = _displayRect.origin.y;
		float rawstep = _lastScrollPosition-pos;
		float toppos = [_scrollingView frame].size.height-_displayRect.size.height;
		int pagescrolllines = _viewCapacity-1;
		RECORD * recptr = NULL;
		int linestep;
		
		// need both page tests because pg up/dn keys & scroller clicks give diff step amounts
//		if (pos > toppos)
//			NSLog(@"Pos: %g, top: %g", pos, toppos);
		if (rawstep == _displayRect.size.height-_scrollLineHeight || rawstep == _displayRect.size.height-2*_scrollLineHeight)	// if a page down to scroll
			linestep = pagescrolllines;
		else if (-rawstep == _displayRect.size.height-_scrollLineHeight || -rawstep == _displayRect.size.height-2*_scrollLineHeight)	// if a page up to scroll
			linestep = -pagescrolllines;
		else
			linestep = rawstep/_scrollLineHeight;
//		NSLog(@"%.0f, %d, %.0f %.0f", pos,linestep, toppos, rawstep);
		if (pos == 0) // if at bottom
			recptr = sort_bottom(FF);
		else if (pos >= toppos)	// or top (or above from bounce)
			recptr = sort_top(FF);
		else if (linestep > pagescrolllines || linestep < -pagescrolllines)	{
//			NSLog(@"Jump position: %f", 1-pos/toppos);
			if (_visibleRecords < SMALLVIEWSET)	// if small viewable set
				recptr = sort_recordforviewindex(FF,(1-pos/toppos)*_visibleRecords);
			else
				recptr = sort_jump(FF,1-pos/toppos);
		}
		if (recptr)	{
//			LayoutDescriptor * ld = [self _descriptorForRecord:recptr->num startLine:0];
//			if (ld.record != recptr->num || _startLine != 0) {	// if record not already in the right place
				[self _fillViewFromRecord:recptr->num line:0];
				[self _loadMainView];
				_lastScrollPosition = pos;
//			}
		}
		else if (linestep)	{	// want to step by lines (and have accumulated at least 1)
			[self _stepView:linestep];
			[self _loadMainView];
			_lastScrollPosition = pos + (rawstep-linestep*_scrollLineHeight);	// last position becomes intended + any shortfall from moving integral # lines
		}
	}
}
- (void)displayError:(NSString *)error {
	if (error)	{
		[viewError setStringValue:error];
		[searchString setHidden:YES];
		[viewStats setHidden:YES];
		[viewError setHidden:NO];
	}
	else	{
		[viewError setHidden:YES];
		[viewStats setHidden:NO];
		[searchString setHidden:NO];
//		[viewError setObjectValue:nil];
	}
}
- (void)displaySearchString:(NSString *)search error:(BOOL)error {
	if (error)
		[searchString setTextColor:[NSColor redColor]];
	else
		[searchString setTextColor:[NSColor textColor]];
	[searchString setStringValue:search];
}
- (void)_fillViewFromRecord:(RECN)record line:(int)start {
	RECORD * recptr, * baseptr;
	
	if (record)
		recptr = rec_getrec(FF, record);
	else if (_layoutDescriptors)
		recptr = rec_getrec(FF, [[_layoutDescriptors objectAtIndex:0] record]);
	else
		recptr = sort_top(FF);
	baseptr = recptr;
	if (start >= 0)		// if specifying start
		_startLine = start;	// use current start
	_endLine = _filledLines = 0;
	_height = 0;
	while (recptr && sort_isignored(FF,recptr))	// if can't display record
		recptr = [self.document skip:1 from:recptr];	// try skipping forward
	if (!recptr)	{	// if can't skip forward
		recptr = baseptr;
		while (recptr && sort_isignored(FF,recptr))	// if can't display record
			recptr = [self.document skip:-1 from:recptr];	// try skippng backwards
	}
	if (recptr)	{	// if any record to show
		NSMutableArray * darray = [NSMutableArray arrayWithCapacity:100];
		unsigned int displayedlines = 0;
		do {
			LayoutDescriptor * ld = [self _makeDescriptorForRecord:recptr];
			unsigned int linecount = [ld lineCount];
			unsigned int lineindex;

//			NSLog(@"avail: %f, this: %f (%d)", _displayRect.size.height-height, [ld height], [ld record]);
			if (!_endLine && _startLine >= linecount)	// if first descriptor starts beyond startline (might, following view type change)
				_startLine = linecount-1;	// set to last line of entry
			for (lineindex = 0; lineindex < linecount && _height < _displayRect.size.height; lineindex++) {
				if (_endLine++ >= _startLine)	{	// if want to count this line
					_height += [[[ld lineHeights] objectAtIndex:lineindex] floatValue];
					displayedlines++;
				}
			}
			if (lineindex) {		// if took any lines from this record
				[darray addObject:ld];		// add it to array
				_filledLines += linecount;		// number of lines covered by lines array
			}
		} while (_height < _displayRect.size.height && (recptr = [self.document skip:1 from:recptr]));
		if (_endLine)	// if any to display
			_endLine--;	// make count the index of the last one
		self.layoutDescriptors = darray;
		_scrollLineHeight = _height/displayedlines;
		_viewCapacity = _displayRect.size.height/(_height/displayedlines);	// best estimate of view capacity in lines
		[_scrollView setVerticalLineScroll:_scrollLineHeight];
		[_scrollView setVerticalPageScroll:_scrollLineHeight];
	}
	else	// no records to show
		self.layoutDescriptors = nil;
//	NSLog(@"%d, %d, %d",_startLine, _endLine, _filledLines);
}
- (void)_loadMainView {
	NSTextStorage * ts = [_indexView textStorage];
	unsigned int count = [_layoutDescriptors count];
	unsigned int lineindex = 0;
	int selstart = -1, sellength = 0;
	
	[ts beginEditing];
	[ts deleteCharactersInRange:NSMakeRange(0,[[ts string] length])];
	for (int index = 0; index < count && lineindex <= _endLine; index++) {
		LayoutDescriptor * ld = [_layoutDescriptors objectAtIndex:index];
		NSAttributedString * as = [ld entry];
		int lines = [ld lineCount];
		NSRange span;
		
		if (lineindex < _startLine) {	// if not using beginning of entry (assume this is the first one)
			span.location = [[[ld lineRanges] objectAtIndex:_startLine] rangeValue].location;
			span.length = [ld entryLength]-span.location;
			unichar leftchar = [[as string] characterAtIndex:span.location-1];
			as = [as attributedSubstringFromRange:span];
			
			if (leftchar != '\n')	{	// if our line isn't first of para
				// create mutable intermediate so we can reset first line indent to be runover
				NSMutableParagraphStyle *tp = [[NSMutableParagraphStyle alloc] init];
				NSMutableAttributedString *tas = [[NSMutableAttributedString alloc] initWithAttributedString:as];
				
				[tp setParagraphStyle:[tas attribute:NSParagraphStyleAttributeName atIndex:0 effectiveRange:nil]];
				[tp setFirstLineHeadIndent:[tp headIndent]];	// set first line to be run-in
				[tas addAttribute:NSParagraphStyleAttributeName value:tp range:NSMakeRange(0,1)];
				as = tas;
			}
		}
		else if (lineindex+lines > _endLine+1) {	// if don't need end of entry
			span.location = 0;
			span.length = NSMaxRange([[[ld lineRanges] objectAtIndex:_endLine-lineindex] rangeValue]);
			as = [as attributedSubstringFromRange:span];
		}
		if (_selectedRecords.location && !sellength && sort_relpos(FF, [ld record], _selectedRecords.location) >= 0)	// if first in selection
			selstart = [[ts string] length];		// start selecting
		[ts appendAttributedString:as];
		if (selstart >= 0 && sort_relpos(FF, [ld record], _selectedRecords.length) <= 0)	// if still in selection
			sellength = [[ts string] length]-selstart;		// add to selection length
		lineindex += lines;
	}
	[ts endEditing];
	if (sellength)	// if want selection
		[_indexView setSelectedRange:NSMakeRange(selstart,sellength)];
}
- (LayoutDescriptor *)_makeDescriptorForRecord:(RECORD *)recptr {
	IRAttributedDisplayString *as = [[IRAttributedDisplayString alloc] initWithIRIndex:self.document paragraphs:_paragraphs record:recptr->num];
	return [[LayoutDescriptor alloc] initWithStorage:_recordStorage entry:as];
}
- (void)showRecord:(RECN)record position:(int)position {
	unsigned int steplines = 0;
	
	for (LayoutDescriptor * ld in _layoutDescriptors)	{   // for all descriptors
#if 0
		if ([ld record] == record)	{
			if (position == VD_TOP)
				[self _stepView:steplines-_startLine];
			return;
		}
		else if (steplines-_startLine >= _endLine)	// if at last of displayed lines
			break;
#else
		if ([ld record] == record)	{	// if target on screen
			if (position == VD_TOP)
				[self _stepView:steplines-_startLine];
			if (steplines-_startLine == _endLine && (int)_height > _displayRect.size.height)	// if on last line & it's incompletely displayed
				break;
			return;
		}
		if (steplines-_startLine >= _endLine)	// if at last of displayed lines
			break;
#endif
		steplines += [ld lineCount];
	}
	[self _fillViewFromRecord:record line:0];	// refill array
	if (position == VD_SELPOS)
		[self _stepView:-(int)(_viewCapacity/2)];
	[self _loadMainView];
	[self _setScrollIndicator];		// set scroll bar
	return;
}
- (void)_stepView:(int)step {
	unsigned int displayedlines = _endLine-_startLine+1;
	int newbaseoffset = _startLine;
	int unsigned index;
	
	if (step == 0)
		return;
	if (step < 0) {	// step towards top
		if (newbaseoffset < -step) {	// if will need to read record(s)
			RECORD * recptr = rec_getrec(FF,[[_layoutDescriptors objectAtIndex:0] record]);
			displayedlines = 0;
			float height = 0;
			int checkindex;
			
			newbaseoffset += step;
			while (newbaseoffset < 0 && (recptr = [self.document skip:-1 from:recptr])) {	// while we haven't got enough lines
				LayoutDescriptor * ld = [self _makeDescriptorForRecord:recptr];
				[_layoutDescriptors insertObject:ld atIndex:0];
				newbaseoffset += [ld lineCount];
				_filledLines += [ld lineCount];
			}
			if (newbaseoffset < 0)	// if step was before beginning
				newbaseoffset = 0;	// set 0 offset
			// find last new last line 
			for (checkindex = index = 0; index < [_layoutDescriptors count] && height < _displayRect.size.height; index++) {
				LayoutDescriptor * ld = [_layoutDescriptors objectAtIndex:index];
				unsigned int lineindex;

				for (lineindex = 0; lineindex < [ld lineCount] && height < _displayRect.size.height; lineindex++) {
					if (checkindex++ >= newbaseoffset) {
						height += [[[ld lineHeights] objectAtIndex:lineindex] floatValue];
						displayedlines++;
					}
				}
			}
			while (index < [_layoutDescriptors count])	{	// while have more descriptors than we need
				NSUInteger lines = [[_layoutDescriptors objectAtIndex:index] lineCount];
				_filledLines -= lines;
				[_layoutDescriptors removeObjectAtIndex:index];	// drop descriptors
			}
		}
		else {
			newbaseoffset += step;
			displayedlines -= step;
		}
	}
	else if ([self _isScrollable])   {	// step towards bottom if there's something to move
		if (_filledLines < _endLine + step +1) {	// if will need to read record(s)
			RECORD * recptr = rec_getrec(FF,[[_layoutDescriptors lastObject] record]);
			displayedlines = 0;
			float height = 0;
			int checkindex;
			
			while (_filledLines < _endLine + step +1 && (recptr = [self.document skip:1 from:recptr])) {	// while we haven't got enough lines
				LayoutDescriptor * ld = [self _makeDescriptorForRecord:recptr];
				[_layoutDescriptors addObject:ld];
				_filledLines += [ld lineCount];
			}
			newbaseoffset += step;
			// find new last line
			for (checkindex = index = 0; index < [_layoutDescriptors count] && height < _displayRect.size.height; index++) {
				LayoutDescriptor * ld = [_layoutDescriptors objectAtIndex:index];
				unsigned int lineindex;

				for (lineindex = 0; lineindex < [ld lineCount] && height < _displayRect.size.height; lineindex++) {
					if (checkindex++ >= newbaseoffset) {
						height += [[[ld lineHeights] objectAtIndex:lineindex] floatValue];
						displayedlines++;
					}
				}
			}
			if (!displayedlines)	{	// if step would be beyond last record
				displayedlines = [[_layoutDescriptors lastObject] lineCount];
				newbaseoffset = checkindex-displayedlines;
			}
		}
		else
			newbaseoffset += step;
		while ((index = [[_layoutDescriptors objectAtIndex:0] lineCount]) <= newbaseoffset) {	// drop unused descriptors at start
			newbaseoffset -= index;
			_filledLines -= index;
			[_layoutDescriptors removeObjectAtIndex:0];
		}
	}
	_startLine = newbaseoffset;
	_endLine = _startLine+displayedlines-1;
//	NSLog(@"Start: %d; end: %d; displayed: %d, total: %d",_startLine, _endLine, displayedlines,_filledLines);
}
- (void)_sizemainView:(NSNotification *)aNotification {
	_displayRect = [[aNotification object] bounds];	// bounds rect of clip view
	[_indexView setFrame:_displayRect];
	[self _fillViewFromRecord:[[_layoutDescriptors objectAtIndex:0] record] line:-1];	// reset layout descriptors
	[self _loadMainView];
	[self _setScrollLimit];
}
- (void)selectLowerRecords {
	NSDictionary * adic;
	RECN record;
	RECORD * curptr;
	char sptr[MAXREC+1], *xptr;
	
	record = [_indexView recordAtMouseLocationWithAttributes:&adic];
	curptr = rec_getrec(FF,record);

	if (curptr)	{
		int sindex = [[adic objectForKey:IRHeadingLevelKey] intValue];	// index of heading displayed
		
		if (sindex < 0)		// if alpha group header
			sindex = 0;		// set to main heading
		str_xcpy(sptr, curptr->rtext);		// get full text
		if (xptr = str_xatindex(sptr,sindex))	{	/* find field displayed */
			RECN lastrecord;
			
			xptr += strlen(xptr)+1;
			*xptr = EOCS;	// terminate after unique field
			curptr = search_lastmatch(FF,curptr,sptr,0);	/* find last that matches at that level */
			lastrecord = [self.document normalizeRecord:curptr->num];
			_selectedRecords.location = record;
			_selectedRecords.length = lastrecord;
			[self _loadMainView];
		}
	}
}
- (NSRange)normalizedCharacterRange:(NSRange)range {
	RECN record = [_indexView recordAtMouseLocationWithAttributes:NULL];

	if (record) {
		int direction = 0;
		NSRange br, er;
		
		if (!range.length) 		// if starting out
			_baseSelectionRecord = record;

		br = [_indexView characterRangeForRecord:_baseSelectionRecord];
		er = [_indexView characterRangeForRecord:record];
		
		if (!br.length)	{	// if base record not visible
			if (sort_relpos(FF,_baseSelectionRecord,[[_layoutDescriptors lastObject] record]) > 0) {// if sel ends before base
				br.location = [[_indexView string] length];
				direction = -1;
			}
			if (sort_relpos(FF,_baseSelectionRecord,[[_layoutDescriptors objectAtIndex:0] record]) < 0)	{// if sel start after base
				br.location = 0;
				direction = 1;
			}
		}
		else
			direction = sort_relpos(FF,record, _baseSelectionRecord);
		if (direction < 0) {	// if moved back from start position
			_selectedRecords.location = record;
			_selectedRecords.length = _baseSelectionRecord;
			return NSMakeRange(er.location,NSMaxRange(br)-er.location);
		}
		else {				// moved forward from start position
			_selectedRecords.location = _baseSelectionRecord;
			_selectedRecords.length = record;
			return NSMakeRange(br.location,NSMaxRange(er)-br.location);
		}
	}
	else	{		// no selection
		_selectedRecords.location = 0;
		_selectedRecords.length = 0;
	}
	return range;
}
- (LayoutDescriptor *)descriptorForRecord:(RECN)record {
	for (LayoutDescriptor * ld in _layoutDescriptors) {	// for all descriptors
		if ([ld record] == record)
			return ld;
	}
	return nil;
}
- (LayoutDescriptor *)_descriptorForRecord:(RECN)record startLine:(int *)lineptr {
	NSUInteger count = [_layoutDescriptors count];
	int index;
	int lineindex;
	
	for (lineindex = index = 0; index < count; index++) {	// for all descriptors
		LayoutDescriptor * ld = [_layoutDescriptors objectAtIndex:index];
		
		if ([ld record] == record) {
			if (lineptr)
				*lineptr = lineindex >= 0 ? lineindex : 0;	// make sure correct adjustment for _startLine
			return ld;
		}
		lineindex += [ld lineCount];
	}
	return nil;
}
#if 0
- (NSRange)characterRangeForRecord:(RECN)record {
	[_indexView characterRangeForRecord:record];
	if (record)	{
		int count = [_layoutDescriptors count];
		LayoutDescriptor * ld = [_layoutDescriptors objectAtIndex:0];
		int characters, base, length;
		int index;
		
		base = 0;		// set values for first record
		length = [ld entryLength];
		characters = length;
		if (_startLine)		{	// if we start at offset line
			int offset = [[[ld lineRanges] objectAtIndex:_startLine] rangeValue].location;// back out skipped lines in first entry
			characters -= offset;
			length -= offset;
		}
		for (index = 1; index < count && [ld record] != record; index++) {	// until we hit our record
			base = characters;
			ld = [_layoutDescriptors objectAtIndex:index];
			length = [ld entryLength];
			characters += length;
		}
		if ([ld record] == record)
			return NSMakeRange(base, length);
	}
	return NSMakeRange(0,0);
}
#endif
- (NSString *)windowTitleForDocumentDisplayName:(NSString *)docname {
	NSMutableString *statusname = [NSMutableString stringWithCapacity:50];
    NSString * name = nil;
	NSString * sortstring = nil;
	BOOL sflag = NO, locatorFirst = NO;
	RECN availableRecords = 0;
	
	switch (FF->viewtype)	{
		case VIEW_ALL:
			name = [NSString stringWithFormat:@"%@: All Records",docname];
			availableRecords = FF->head.rtot;
			[statusname appendFormat:@"%u", availableRecords];
			sflag = FF->head.sortpars.ison;
			locatorFirst = FF->head.sortpars.fieldorder[0] == PAGEINDEX;
			break;
		case VIEW_GROUP:
			name = [NSString stringWithFormat:@"%@: Group %s", docname, FF->curfile->gname];
			availableRecords = FF->curfile->rectot;
			[statusname appendFormat:@"%u of %u", availableRecords,FF->head.rtot];
			sflag = FF->curfile->lg.sortmode; 
			break;
		case VIEW_TEMP:
			name = [NSString stringWithFormat:@"%@: Temporary Group", docname];
			availableRecords = FF->lastfile->rectot;
			[statusname appendFormat:@"%u of %u", availableRecords,FF->head.rtot];
			sflag = FF->lastfile->lg.sortmode;
			break;
		case VIEW_NEW:
			name = [NSString stringWithFormat:@"%@: New Records", docname];
			availableRecords = FF->head.rtot-FF->startnum;
			[statusname appendFormat:@"%u of %u", availableRecords,FF->head.rtot];
			break;
	}
	if (FF->head.privpars.vmode == VM_FULL)	{	// if full format, count visible (can be less than all available records)
		_visibleRecords = 0;
		for (RECORD * curptr = sort_top(FF); curptr; curptr = sort_skip(FF,curptr,1))
			_visibleRecords++;
	}
	else
		_visibleRecords = availableRecords;
	[self _setScrollLimit];
	if (sflag) {
		NSString * format = locatorFirst ? @"Sorted (%@ [By Locator]) " : @"Sorted (%@)";
		sortstring = [NSString stringWithFormat:format, [NSString stringWithUTF8String:cl_sorttypes[FF->head.sortpars.type]]];
	}
	else
		sortstring = @"Unsorted";
	[statusname appendFormat:[NSString stringWithUTF8String:" • %ld New • %@"],FF->head.rtot-FF->startnum, sortstring];
	if (FF->head.privpars.vmode == VM_FULL && FF->head.privpars.filter.on)
		[statusname appendString:@" • Hiding enabled"];
	[viewStats setStringValue:statusname];
    return name;
}
#if 0
- (void)windowWillClose:(NSNotification *)notification {
	[[NSNotificationCenter defaultCenter] removeObserver:self];	// window can be resized after index gone
}
#endif
- (NSRect)windowWillUseStandardFrame:(NSWindow *)sender defaultFrame:(NSRect)defaultFrame {
	NSPrintInfo * pinfo = [self.document printInfo];
	NSSize csize = NSMakeSize([pinfo paperSize].width-[pinfo rightMargin]-[pinfo leftMargin],[pinfo paperSize].height-[pinfo topMargin]-[pinfo bottomMargin]);
	NSSize inset = [_indexView textContainerInset];
	NSSize scrollsize = [NSScrollView frameSizeForContentSize:NSMakeSize(csize.width+inset.width,csize.height+inset.height)
					horizontalScrollerClass:nil verticalScrollerClass:[NSScroller class]
					borderType:NSNoBorder controlSize:NSRegularControlSize scrollerStyle:NSScrollerStyleOverlay];
	
	NSRect nrect = [sender frameRectForContentRect:NSMakeRect([sender frame].origin.x,[sender frame].origin.y,scrollsize.width, scrollsize.height)];
	
	nrect.origin.y += [sender frame].size.height-nrect.size.height;	// adjust origin so that top of window doesn't move
	return nrect;
}
- (void)windowDidMove:(NSNotification *)aNotification {
	if (_allowFrameSet)
		FF->head.mainviewrect = IRRectFromNSRect([[self window] contentRectForFrameRect:[[self window] frame]]);	// remember content
}
- (void)windowDidResize:(NSNotification *)aNotification {
	if (_allowFrameSet)
		FF->head.mainviewrect = IRRectFromNSRect([[self window] contentRectForFrameRect:[[self window] frame]]);	// remember content
	
	// updating margin tracking area when the window is resized
	[_indexView updateTrackingAreas];
}
- (void)windowWillEnterFullScreen:(NSNotification *)aNotification {
	_allowFrameSet = NO;
}
- (void)windowWillExitFullScreen:(NSNotification *)aNotification {
	_allowFrameSet = YES;
}
#if 0
- (void)windowDidEndSheet:(NSNotification *)notification {
	if (!self.window.attachedSheet && ((IRIndexDocument *)self.document).currentSheet)	{	// if no sheet attached, and we've got one retained
//		[((IRIndexDocument *)self.document).currentSheet.window close];
//		((IRIndexDocument *)self.document).currentSheet = nil;	// release it
		// NSLog(@"++++++Update");
	}
}
#endif
- (void)windowDidUpdate:(NSNotification *)aNotification {
	if (((IRIndexDocument*)self.document).iIndex->readonly && !shownReadonlyInfo) {		// if first time window becomes main...
		shownReadonlyInfo = YES;
		infoSheet(self.window,INFO_READONLY);
	}
	[self.document updateChangeCount: FF->head.dirty ? NSChangeDone : NSChangeCleared];	// set/clear clear change
}
- (void)windowDidBecomeMain:(NSNotification *)notification {
	[self.document installGroupMenu];	// installs group menu
	[self.document installFieldMenu];	// installs view depth menu
}
- (void)setDisplayForEditing:(BOOL)opening adding:(BOOL)addmode{
	BOOL redisplay = FALSE;
	
	if (opening) {	// if opening record window
		RECN target;	// default record to display
		
		_contextSort = FF->head.sortpars.ison;
		_contextPrivParams = FF->head.privpars;
		_contextTopRecord = _layoutDescriptors ? [[_layoutDescriptors objectAtIndex:0] record] : 0;
		_addMode = addmode && !FF->curfile;	// add mode if wanted and not working on group
		if (g_prefs.gen.switchview && FF->head.privpars.vmode == VM_FULL) {	// if need view switch
			FF->head.privpars.vmode = VM_DRAFT;
			FF->head.privpars.hidedelete = FALSE;
			redisplay = TRUE;
		}
		if (_addMode && !g_prefs.gen.track) {	// if want to enter unsorted mode
			FF->head.sortpars.ison = FALSE;
			FF->head.privpars.hidebelow = ALLFIELDS;
			target = rec_number(sort_bottom(FF));
			redisplay |= FF->head.sortpars.ison != _contextSort || FF->head.privpars.hidebelow != _contextPrivParams.hidebelow;
		}
		else
			target = (RECN)[self selectedRecords].location;
		if (redisplay)
			[self.document redisplay:target mode:VD_SELPOS];
	}
	else {	// closing record window
#if 0
		redisplay = (g_prefs.gen.vreturn || _addMode && !g_prefs.gen.track) 
			|| _contextPrivParams.vmode == VM_FULL && g_prefs.gen.switchview || _nptr->tot;
#else
		redisplay = TRUE;		// need way to capture setting of _nptr->tot
#endif			
		FF->head.sortpars.ison = _contextSort;
		FF->head.privpars = _contextPrivParams;
		if (redisplay) {
			if (g_prefs.gen.vreturn || _addMode)
				[self.document redisplay:_contextTopRecord mode:VD_CUR];
			else
				[self.document redisplay:0 mode:VD_CUR];
		}
	}
}
- (BOOL)editingMode {
	return _addMode;
}
- (void)_resetContainer {
	NSPrintInfo * pinfo = [self.document printInfo];
	NSTextContainer * cp = [_indexView textContainer];
	NSSize csize = NSMakeSize([pinfo paperSize].width-[pinfo rightMargin]-[pinfo leftMargin],10000000);
	
	[cp setWidthTracksTextView:NO];
	[cp setHeightTracksTextView:NO];
	[cp setContainerSize:csize];
	[[[[[_recordStorage layoutManagers] objectAtIndex:0] textContainers] objectAtIndex:0] setContainerSize:csize];
#if 0
	NSSize inset = [_indexView textContainerInset];
	NSSize scrollsize = [NSScrollView frameSizeForContentSize:NSMakeSize(csize.width+inset.width,csize.height+inset.height)
			hasHorizontalScroller:NO hasVerticalScroller:YES borderType:NSNoBorder];
	NSSize wcontentsize = [[[self window] contentView] frame].size;
	NSSize wmaxsize = [[self window] maxSize];
	
	wcontentsize.width = scrollsize.width;
	[[self window] setContentSize:wcontentsize];	// resize window for content
	wmaxsize.width = [[self window] frame].size.width;
	[[self window] setMaxSize:wmaxsize];	// reset maximum window width
#endif
}
- (void)updateDisplay {
	RECN record = 0;
	if (![self _isScrollable]) 	//	if no active scrollbar (all records fit)
		record = rec_number(sort_top(FF));
	[self _fillViewFromRecord:record line:-1];	// reset layout descriptors
	[self _loadMainView];		// refresh display
	[self synchronizeWindowTitleWithDocumentName];
}
- (void)_redisplay:(NSNotification *)note {
	RECN record = [[[note userInfo] objectForKey:RecordNumberKey] unsignedIntValue];
	unsigned int mode = [[[note userInfo] objectForKey:ViewModeKey] unsignedIntValue];
	int startline = 0;	// default start on first line of record
	BOOL fontsizeoverride = FALSE;
	BOOL fontnameoverride = FALSE;
	int index;
	
	if (mode&VD_RESET)	{
		self.layoutDescriptors = nil;
		_startLine = _endLine = _filledLines = _viewCapacity = 0;
		[self setSelectedRecords:NSMakeRange(0,0)];
	}
	if (!record)	{		// find a default record
		if (mode&VD_CUR && _layoutDescriptors && [self _isScrollable])	{	// if want current redisplayed (and there is one, and all doesn't fit)
			record = [[_layoutDescriptors objectAtIndex:0] record];		// get record
			startline = -1;			// and current start line
		}
		else
			record = rec_number(sort_top(FF));
	}
	[self _configureParagraphs];
	[self _fillViewFromRecord:record line:startline];	// reset layout descriptors
	if (record && mode&VD_SELPOS)		// if want record in selection position
		[self _stepView:-(int)(_viewCapacity-_startLine)/2];
	[self _loadMainView];		// refresh display
	[self synchronizeWindowTitleWithDocumentName];
	[defaultFont setStringValue:[NSString stringWithUTF8String:FF->head.fm[0].name]];
	[defaultSize setIntValue:FF->head.privpars.size];
	if (FF->head.privpars.vmode == VM_FULL) {		// check font name and size overrides
		if (FF->head.formpars.ef.eg.gsize)
			fontsizeoverride = TRUE;
		if (*FF->head.formpars.ef.eg.gfont)
			fontnameoverride = TRUE;
		for (index = 0; index < FF->head.indexpars.maxfields-1; index++) {
			if (FF->head.formpars.ef.field[index].size)	// if overridden size
				fontsizeoverride = TRUE;
			if (*FF->head.formpars.ef.field[index].font)
				fontnameoverride = TRUE;
		}
	}
	[defaultFont setTextColor:(fontnameoverride ? [NSColor redColor] :[NSColor textColor])];
	[defaultSize setTextColor:(fontsizeoverride ? [NSColor redColor] :[NSColor textColor])];
}
- (void)_fontsChanged {
	[FF->owner redisplay:0 mode:VD_CUR];
}
- (void)textViewDidChangeSelection:(NSNotification *)aNotification	{
	if (_selectedRecords.location)	{	// if not empty selection
		RECORD * recptr = rec_getrec(FF,(RECN)_selectedRecords.location);
		if (recptr)
			[label selectItemAtIndex:recptr->label];
	}
//	[label setEnabled: _selectedRecords.location && ![self.document recordWindowController]];
}
- (void)setSelectedRecords:(NSRange)recordrange {
	_selectedRecords = recordrange;
}
- (NSRange)selectedRecords {
	return _selectedRecords;
}
- (void)selectRecord:(RECN)record range:(NSRange)range {
	[self setSelectedRecords:NSMakeRange(record,record)];
	if (record) {
		NSRange sr;
		[self showRecord:record position:VD_SELPOS];
		[[NSNotificationCenter defaultCenter] postNotificationName:NOTE_CONDITIONALOPENRECORD object:self.document];
		sr = [_indexView characterRangeForRecord:record];	// default whole record
		if (FF->head.privpars.vmode != VM_FULL && range.length > 0) {	// if draft and selection range
			LayoutDescriptor *ld = [self descriptorForRecord:record];
//			if (range.length) {	// if want to specify real range
				sr = [ld displayRangeForSourceRange:range];
				sr.location += [_indexView characterRangeForRecord:record].location;
//			}
		}
		[_indexView setSelectedRange:sr];
	}
	else
		[_indexView setSelectedRange:NSMakeRange(0,0)];
	[_indexView setFirstSelected:record];	// set base of selection
}
- (void)selectAllRecords {
	RECORD * firstptr = sort_top(FF);
	RECORD * lastptr = sort_bottom(FF);
	
	if (firstptr && lastptr)
		[self setSelectedRecords:NSMakeRange(firstptr->num, lastptr->num)];
}
- (RECN)stepRecord:(int)step from:(RECN)record {
	RECN steppedrecord = 0;
	if (step) {
		RECN baserecord = record ? record : (RECN)_selectedRecords.location;
		RECORD * recptr = rec_getrec(FF, baserecord);
		
		if (recptr) {
			recptr = [self.document skip:step from:recptr];
			if (recptr) {
				int lines = [[self _descriptorForRecord:baserecord startLine:NULL] lineCount];
				
				if (lines)	{	// if selected record is on screen
					[self _stepView:step*lines];
					[self setSelectedRecords:NSMakeRange(recptr->num,recptr->num)];
					[[NSNotificationCenter defaultCenter] postNotificationName:NOTE_CONDITIONALOPENRECORD object:self.document];
					steppedrecord = recptr->num;
				}
				else
					[self _stepView:step];
			}
		}
		else	// no selection, so step line if poss
			[self _stepView:step];
		[self _loadMainView];
		[self _setScrollIndicator];		// set scroll bar
	}
	return steppedrecord;
}
- (void)copySelectionToPasteboard:(NSPasteboard *)pboard {
	NSRange rrange = [self.document selectionMaxRange];
	NSMutableData * pbdata;
	NSMutableData * pbstring, * pbrtf;
	COUNTPARAMS cs;
	int rcount, clippedsize;
	
	memset(&cs,0,sizeof(cs));
	cs.firstrec = (RECN)rrange.location;
	cs.lastrec = (RECN)rrange.length;
	cs.smode = FF->head.sortpars.ison;		/* sort is as the view */
	rcount = search_count(FF, &cs, SF_VIEWDEFAULT);
	clippedsize = sizeof(RECORD)+cs.longest+1;
	pbdata = [[NSMutableData alloc] initWithLength:sizeof(RECCOPY)+rcount*clippedsize];
	if (pbdata)	{	// if have memory
		RECCOPY * rc = (RECCOPY *)[pbdata mutableBytes];
		RECORD * recptr;
		
		rc->cs = cs;	/* copy stats */
		memcpy(rc->fm,FF->head.fm, sizeof(FF->head.fm));	/* and font map */
		rc->rtot = rcount;
		// build copy objects
		for (rcount = 0, recptr = rec_getrec(FF,cs.firstrec); recptr && recptr->num != cs.lastrec; recptr = sort_skip(FF,recptr,1), rcount++)	{/* for all in sel range */
			memcpy(cliprec(rc,rcount),recptr,clippedsize);	/* copy record */
		}
	}
	pbrtf = [[NSMutableData alloc] initWithLength:sizeof(RECCOPY)+rcount*clippedsize];
	if (pbrtf)	// if have memory
		export_pastabletext(pbrtf,FF,YES);
#if 1
	if (FF->head.privpars.vmode == VM_FULL) {
		[pboard declareTypes:[NSArray arrayWithObjects:IRRecordsPBoardType,NSPasteboardTypeRTF,NSPasteboardTypeString,nil] owner:nil];	// don't need owner when providing all formats immediately
		pbstring = [[NSMutableData alloc] initWithLength:sizeof(RECCOPY)+rcount*clippedsize];
		if (pbstring)	// if have memory
			export_pastabletext(pbstring,FF,NO);
		[pboard setData:pbstring forType:NSPasteboardTypeString];
	}
	else	// don't permit plain text for draft view (embedding)
		[pboard declareTypes:[NSArray arrayWithObjects:IRRecordsPBoardType,NSPasteboardTypeRTF,nil] owner:nil];	// don't need owner when providing all formats immediately
#else
	[pboard declareTypes:[NSArray arrayWithObjects:IRRecordsPBoardType,NSPasteboardTypeRTF,NSPasteboardTypeString,nil] owner:nil];	// don't need owner when providing all formats immediately
#endif
	[pboard setData:pbdata forType:IRRecordsPBoardType];
	[pboard setData:pbrtf forType:NSPasteboardTypeRTF];
}
- (void)copySelectionToPasteboard:(NSPasteboard *)pboard forType:(NSString *)type{
	NSRange rrange = [self.document selectionMaxRange];
	NSMutableData * pbdata;
	NSMutableData * pbstring;
	COUNTPARAMS cs;
	int rcount, clippedsize;
	
	memset(&cs,0,sizeof(cs));
	cs.firstrec = (RECN)rrange.location;
	cs.lastrec = (RECN)rrange.length;
	cs.smode = FF->head.sortpars.ison;		/* sort is as the view */
	rcount = search_count(FF, &cs, SF_VIEWDEFAULT);
	cs.longest = (cs.longest+1+3)&~3;	// 6/25/18 make sure longest is properly rounded up
	clippedsize = sizeof(RECORD)+cs.longest;
	
	if ([type isEqualToString:IRRecordsPBoardType]) {
		pbdata = [[NSMutableData alloc] initWithLength:sizeof(RECCOPY)+rcount*clippedsize];
		if (pbdata)	{	// if have memory
			RECCOPY * rc = (RECCOPY *)[pbdata mutableBytes];
			RECORD * recptr;
			
			rc->cs = cs;	/* copy stats */
			memcpy(rc->fm,FF->head.fm, sizeof(FF->head.fm));	/* and font map */
			rc->rtot = rcount;
			// build copy objects
			for (rcount = 0, recptr = rec_getrec(FF,cs.firstrec); recptr && recptr->num != cs.lastrec; recptr = sort_skip(FF,recptr,1), rcount++)	{/* for all in sel range */
				memcpy(cliprec(rc,rcount),recptr,clippedsize);	/* copy record */
			}
			[pboard setData:pbdata forType:IRRecordsPBoardType];
		}
	}
	else if ([type isEqualToString:NSPasteboardTypeRTF] || [type isEqualToString:NSPasteboardTypeString]) {
		pbstring = [[NSMutableData alloc] initWithLength:sizeof(RECCOPY)+rcount*clippedsize];
		if (pbstring)	{// if have memory
			export_pastabletext(pbstring,FF,[type isEqualToString:NSPasteboardTypeRTF]);
			[pboard setData:pbstring forType:type];
		}
	}
}
- (BOOL)copyRecordsFromPasteboard:(NSPasteboard *)pb {
	RECCOPY * rc = (RECCOPY *)[[pb dataForType:IRRecordsPBoardType] bytes];
	short nfarray[FONTLIMIT], farray[FONTLIMIT];
	RECN rcount, oldbase;
	int nfindex;

	if (rc->cs.deepest > FF->head.indexpars.maxfields)	{	/* if need to increase field limit */
		if (sendwarning(RECFIELDNUMWARN, rc->cs.deepest))	{
			int oldmaxfieldcount = FF->head.indexpars.maxfields;
			
			FF->head.indexpars.maxfields = rc->cs.deepest;
			adjustsortfieldorder(FF->head.sortpars.fieldorder, oldmaxfieldcount, FF->head.indexpars.maxfields);
		}
		else
			return NO;
	}
	if (rc->cs.longest > FF->head.indexpars.recsize)	{	/* if need record enlargement */
		if (!sendwarning(RECENLARGEWARN,rc->cs.longest-FF->head.indexpars.recsize) ||	/* if don't want resize */
			![self.document resizeIndex:rc->cs.longest])
			return NO;		/* can't do it */
	}
	/* here we build font conversion map */
	memset(farray,0,FONTLIMIT * sizeof(short));		/* this array holds tags for fonts used */
	for (rcount = 0; rcount < rc->rtot; rcount++)	{/* for all records */
		RECORD * srecptr = cliprec(rc,rcount);
		type_tagfonts(srecptr->rtext,farray);		/* marks source fonts used */
	}
	memset(nfarray,0,FONTLIMIT*sizeof(short));		/* this array holds distination ids indexed by source id */
	for (nfindex = VOLATILEFONTS; nfindex < FONTLIMIT; nfindex++)	{	/* for every font index */
		if (farray[nfindex])					/* if source local id is used */
			nfarray[nfindex] = type_findlocal(FF->head.fm,rc->fm[nfindex].name,VOLATILEFONTS);	/* get new local id for it */
	}
	if (index_setworkingsize(FF,rc->rtot+MAPMARGIN))	{	// if can resize for new records
		for (oldbase = FF->head.rtot, rcount = 0; rcount < rc->rtot; rcount++) {	/* for all records */
			RECORD * srecptr = cliprec(rc,rcount);
			RECORD * drecptr = rec_makenew(FF,srecptr->rtext,FF->head.rtot+1);
			
			if (drecptr)	{
				int fcount;
				
				type_setfontids(drecptr->rtext,nfarray);
				str_adjustcodes(drecptr->rtext,CC_TRIM|(g_prefs.gen.remspaces ? CC_ONESPACE : 0));
				fcount = rec_strip(FF,drecptr->rtext);	/* strip surplus fields */
				if (fcount < FF->head.indexpars.minfields)		/* if too few fields */
					rec_pad(FF,drecptr->rtext);	/* pad to min fields if necess */
				drecptr->isdel = srecptr->isdel;
				drecptr->label = srecptr->label;
				sort_makenode(FF,++FF->head.rtot);		/* make nodes */
			}
		}
		[self.document flush];		// 6/25/18 force update
		[self.document closeSummary];	/* dispose of any summary */
		[self setSelectedRecords:NSMakeRange(oldbase+1,oldbase+1)];		// select first new record
		if (FF->curfile)		/* if viewing group */
			[self.document setViewType:VIEW_ALL name:nil];	/* show all records */
		else
			[self.document redisplay:oldbase+1 mode:VD_SELPOS];	// display from first new one
		return YES;
	}
	return NO;
}
- (void)_configureParagraphs {
	ENTRYFORMAT * efp = &FF->head.formpars.ef;
	PAGEFORMAT * pfp = &FF->head.formpars.pf;
	int level;
	char leadbuff[20];
	NSMutableParagraphStyle *tpara;
	NSSize defaultspacing;
	NSTextTab * rightpagetab = nil /*, *dummypagetab = nil */;
	float draftlead;
	float lineheightmultiple = 1.;
	int alignment, righttab, lefttab, padding;
	
	if (pfp->linespace)		// if want more than single spacing
		lineheightmultiple = pfp->linespace == 1 ? 1.5 : 2.0;
	if (pfp->alignment == 0)	{	// if want writing direction per language
		int direction = col_getLocaleInfo(&FF->head.sortpars)->direction;
		if (direction == ULOC_LAYOUT_RTL)
			alignment = NSRightTextAlignment;
		else
			alignment = NSLeftTextAlignment;
	}
	else
		alignment = pfp->alignment == 1 ? NSLeftTextAlignment : NSRightTextAlignment;
	if (alignment == NSLeftTextAlignment)	{
		righttab = NSRightTabStopType;
		lefttab = NSLeftTabStopType;
		padding = 10;
	}
	else {		// right-aligned
		righttab = NSLeftTabStopType;
		lefttab = NSRightTabStopType;
		// non-zero first line indent messes up tab handling on right->left text; kludge to get reasonable behavior for text size up to 14 pt
		padding = 25;
	}
	FF->righttoleftreading = alignment == NSRightTextAlignment;
	self.paragraphs = [NSMutableArray arrayWithCapacity:FF->head.indexpars.maxfields+1];
	if (FF->head.privpars.vmode == VM_FULL) {
		NSSize headerspacing = type_getfontmetrics(efp->eg.gfont, efp->eg.gsize, FF);
		
		tpara = [[NSMutableParagraphStyle alloc] init];	// alpha header
		[tpara setAlignment:alignment];
		[tpara setBaseWritingDirection:NSWritingDirectionNatural];
		[tpara setHeadIndent:headerspacing.width];	// set runover
		if (pfp->above)		// if need extra space before
			[tpara setParagraphSpacingBefore:headerspacing.height * pfp->above];
		[_paragraphs addObject:tpara];
		// need to find some way to compute properly the right bound for tab
//		rightpagetab = [[NSTextTab alloc] initWithType:righttab location:[[_indexView textContainer] containerSize].width-10];
		rightpagetab = [[NSTextTab alloc] initWithType:righttab location:[[_indexView textContainer] containerSize].width-padding];
	}
	else {
		sprintf(leadbuff,FF->head.privpars.shownum ? "nnn%u" :"nnn" ,FF->head.rtot+100);	// lead size for draft format
		draftlead = [[NSAttributedString asFromXString:leadbuff fontMap:FF->head.fm size:FF->head.privpars.size termchar:0] size].width;
		[_paragraphs addObject:[NSNull null]];
		defaultspacing = type_getfontmetrics(FF->head.fm[0].name,FF->head.privpars.size,FF);
	}
	for (level = 0; level < FF->head.indexpars.maxfields; level++)	{	// build heading para attributes
		tpara = [[NSMutableParagraphStyle alloc] init];
		[tpara setAlignment:alignment];
		[tpara setBaseWritingDirection:NSWritingDirectionNatural];
		if (pfp->linespace)		// if want more than single spacing
			[tpara setLineHeightMultiple:lineheightmultiple];
		if (FF->head.privpars.vmode == VM_FULL) {	// full format
			NSSize levelspacing = type_getfontmetrics(efp->field[level].font, efp->field[level].size, FF);
			float leadindent, runindent;
			
			if (!pfp->autospace)	// if not autospacing
				[tpara setMinimumLineHeight:pfp->lineheight];
			if (!level)	{
				_rightCursorWidth = levelspacing.width+6;
				if (_rightCursorWidth < 12)
					_rightCursorWidth = 12;
				[[self window] invalidateCursorRectsForView:_indexView];
				if (pfp->entryspace)	{	// if main head and need extra para space
					float lineheight = pfp->autospace ? levelspacing.height : pfp->lineheight;
					[tpara setParagraphSpacingBefore:lineheight * pfp->entryspace];
				}
			}
			if (efp->itype == FI_NONE) 	// no indent
				leadindent = runindent = 0.;
			else if (efp->itype == FI_AUTO || efp->itype == FI_SPECIAL && level < FF->head.indexpars.maxfields-2)	{	// auto indent
				leadindent = level * efp->autolead;
				runindent = leadindent + efp->autorun;
				if (!efp->autounit) {
					leadindent *= levelspacing.width;
					runindent *= levelspacing.width;
				}
			}
			else {	// must be fixed or special indent
				int tlevel = FF->head.formpars.ef.itype == FI_SPECIAL && level == FF->head.indexpars.maxfields-2 ? L_SPECIAL : level;
				leadindent = efp->field[tlevel].leadindent;
				runindent = efp->field[tlevel].runindent;
				if (!efp->fixedunit)	{	/* if unit is ems */
					leadindent *= levelspacing.width;
					runindent *= levelspacing.width;
				}
			}
			[tpara setTabStops:[NSArray arrayWithObject:rightpagetab]];
//			dummypagetab = [[NSTextTab alloc] initWithType:righttab location:leadindent+10];
//			[tpara setTabStops:[NSArray arrayWithObjects:dummypagetab, rightpagetab,nil]];
			[tpara setFirstLineHeadIndent:leadindent];	// lead indent
			[tpara setHeadIndent:runindent];			// runover indent
//			NSLog([tpara description]);
		}
		else {		// draft format
			NSTextTab * rightTab = [[NSTextTab alloc] initWithType:righttab location:draftlead];
			NSTextTab * leftTab = [[NSTextTab alloc] initWithType:lefttab location:draftlead+(level+0.5)*defaultspacing.width];
			
			[tpara setTabStops:[NSArray arrayWithObjects:rightTab, leftTab,nil]];
			[tpara setLineBreakMode: FF->head.privpars.vmode || FF->head.privpars.wrap ? NSLineBreakByWordWrapping : NSLineBreakByClipping];
			[tpara setHeadIndent:draftlead+(level+2.5)*defaultspacing.width];
			_rightCursorWidth = draftlead+12;
		}
		[_paragraphs addObject:tpara];
	}
	[[self window] invalidateCursorRectsForView:_indexView];
}
- (float)rightCursorWidth {
	return _rightCursorWidth;
}
- (void)toolbarWillAddItem: (NSNotification *) notif {
    // Optional delegate method:  Before an new item is added to the toolbar, this notification is posted.
    // This is the best place to notice a new item is going into the toolbar.  For instance, if you need to 
    // cache a reference to the toolbar item or need to set up some initial state, this is the best place 
    // to do it.  The notification object is the toolbar to which the item is being added.  The item being 
    // added is found by referencing the @"item" key in the userInfo 
    NSToolbarItem *addedItem = [[notif userInfo] objectForKey: @"item"];

	if ([[addedItem itemIdentifier] isEqual:NSToolbarPrintItemIdentifier]) {
//		[addedItem setToolTip: @"Print the index"];
		[addedItem setTarget: self];
    }
#if 0
	else if([[addedItem itemIdentifier] isEqual:IRFontItemToolbarID]) {
		[defaultFont setStringValue:[NSString stringWithUTF8String:FF->head.fm[0].name]];
	}
	else if([[addedItem itemIdentifier] isEqual:IRSizeItemToolbarID]) {
		[defaultSize setIntValue:FF->head.privpars.size];
	}
#endif
}  
#if 0
- (void)toolbarDidRemoveItem: (NSNotification *) notif {
    // Optional delegate method:  After an item is removed from a toolbar, this notification is sent.   This allows 
    // the chance to tear down information related to the item that may have been cached.   The notification object
    // is the toolbar from which the item is being removed.  The item being added is found by referencing the @"item"
    // key in the userInfo
    NSToolbarItem *removedItem = [[notif userInfo] objectForKey: @"item"];
	
    if (removedItem == activeSearchItem) {
		[activeSearchItem autorelease];
		activeSearchItem = nil;    
    }
}
#endif
- (IBAction)setTextFont:(id)sender {
	if ([sender indexOfItemWithObjectValue:[sender stringValue]] != NSNotFound) {	// if font is available
		char * fname = (char *)[[sender stringValue] cStringUsingEncoding:NSUTF8StringEncoding];
		if (strcmp(FF->head.fm[0].name,fname))	{	/* if current alt not same as default */
			if (!strcmp(FF->head.fm[0].name,FF->head.fm[0].pname))	/* if preferred and alt were same */
				strcpy(FF->head.fm[0].pname,fname);		/* change preferred */
			strcpy(FF->head.fm[0].name,fname);		// change alt
			[self.document redisplay:0 mode:VD_CUR];
		}
	}
	else 		// typed a bad font;	reset previous
		[sender setStringValue:[NSString stringWithUTF8String:FF->head.fm[0].name]];
	[[self window] makeFirstResponder:_indexView];
}
- (IBAction)setTextSize:(id)sender {
	int size = [sender intValue];
	
	if (size != FF->head.privpars.size)	{
		FF->head.privpars.size = size;
		[self.document redisplay:0 mode:VD_CUR];
	}
	[[self window] makeFirstResponder:_indexView];
}
#if 0
- (void)controlTextDidChange:(NSNotification *)note	{
	if ([note object] == printfirstrecord || [note object] == printfirstrecord)	// if record range
		[printrecords selectCellWithTag:COMR_RANGE];
}
#endif
- (void)comboBoxWillDismiss:(NSNotification *)notification {
	[[self window] makeFirstResponder:_indexView];
}
@end

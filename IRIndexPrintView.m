//
//  IRIndexPrintView.m
//  Cindex
//
//  Created by PL on 9/19/05.
//  Copyright 2005 Indexing Research. All rights reserved.
//

#import "IRIndexDocument.h"
#import "IRIndexPrintView.h"
#import "IRIndexDocWController.h"
#import "type.h"
#import "commandutils.h"
#import "strings_c.h"
#import "AttributedStringCategories.h"
#import "IRAttributedDisplayString.h"
#import "LayoutDescriptor.h"
#import "StorageCategories.h"
#import "sort.h"

static unichar nl[] = {'\n','\n','\n','\n','\n','\n','\n','\n','\n','\n'};
#define MAXWIDOWS (sizeof (nl)/sizeof(unichar))

static short getdatetime(char *dstring, char dateform, char timeflag, time_t time);		/* forms long or short date string */

@interface IRIndexPrintView () {
//	IRIndexDocument * _document;
	time_t _currenttime;
	NSUInteger _currentpage;
	INDEX * FF;
	
	BOOL silentMode;
	
	NSTextStorage * _printstorage;
	NSLayoutManager * _layoutmanager;
//	IRAttributedDisplayString * _as;
	NSUInteger _currententrylength;
	BOOL _brokenheading;
	long _overflow;
	RECORD * _currentrecord, *previousRecord;
//	int _totalpages;
	NSRect _pagerect;
	NSArray * _paragraphs;
	RECN _consumed;

	BOOL pageDone;
	NSInteger targetPage;
	PRINTFORMAT xf;
}
@property (weak) IRIndexDocument * document;

- (NSAttributedString *)getTitleString:(BOOL)header position:(int)sourceindex;
- (void)_addColumnForLayout:(NSLayoutManager *)lm;
@end

@implementation IRIndexPrintView
- (id)initWithDocument:(IRIndexDocument *)document paragraphs:(NSArray *)paras {
	self = [self initWithFrame:NSMakeRect(0,0,0,0)];
	if (self)	{
		self.document = document;
		FF = document.iIndex;
		_paragraphs = paras;
		NSPrintInfo * pinfo = [document printInfo];
		_pagerect = NSMakeRect(0,0,[pinfo paperSize].width-[pinfo rightMargin]-[pinfo leftMargin],
							   [pinfo paperSize].height-[pinfo topMargin]-[pinfo bottomMargin]);
		self.frame = _pagerect;
	}
	return self;
}
- (BOOL)buildPageStatistics {
	silentMode = YES;
	NSRange pr = NSMakeRange(0, ULONG_MAX);
	[self knowsPageRange:&pr];	// force setup
	for (int pcount = 1; FF->pf.totalpages < FF->pf.last && _currentrecord && _currentrecord->num != FF->pf.lastrec; pcount++) {
		if (main_comiscancel())
			return NO;
		if (FF->pf.totalpages == FF->pf.first-1)	{	// if at start of target page
			FF->pf.rnum = previousRecord ? previousRecord->num : _currentrecord->num;	// starting record (page break detected after current record incremented)
			FF->pf.pageout = 0;					// reset page count
		}
		[self rectForPage:pcount];
		if (FF->pf.last == INT_MAX)	// if no restriction on page count
			showprogress((100.*_consumed)/FF->head.rtot);
		else
			showprogress((100.*FF->pf.totalpages)/FF->pf.last);
		FF->pf.pageout++;
	}
	showprogress(100.);
	if (FF->pf.rnum)	{	// if produced anything in our range
		NSUInteger firstCIndex = (FF->pf.first-1)*FF->head.formpars.pf.mc.ncols;	// text container index for start of first page
		NSUInteger lastCIndex = FF->pf.last*FF->head.formpars.pf.mc.ncols-1;	//  text container index for end of last page
		if (lastCIndex >= _layoutmanager.textContainers.count)	// if container for intended last page is beyond end of index
			lastCIndex = _layoutmanager.textContainers.count-1;	// set to last
		NSRange grs = [_layoutmanager glyphRangeForTextContainer:[[_layoutmanager textContainers] objectAtIndex:firstCIndex]];
		NSRange gre = [_layoutmanager glyphRangeForTextContainer:[[_layoutmanager textContainers] objectAtIndex:lastCIndex]];
		NSRange lineRange;
		NSUInteger numlines, gindex;
		
		for (numlines = 0, gindex = grs.location; gindex < NSMaxRange(gre); numlines++){
			[_layoutmanager lineFragmentRectForGlyphAtIndex:gindex effectiveRange:&lineRange];
			gindex = NSMaxRange(lineRange);
		}
		FF->pf.lines = (int)numlines;
		FF->pf.characters = (int)[_layoutmanager characterRangeForGlyphRange:NSMakeRange(grs.location, NSMaxRange(gre)-grs.location) actualGlyphRange:NULL].length;
	}
	return YES;
}
- (BOOL)knowsPageRange:(NSRange *)rangeptr {
	if (xf.firstrec != FF->pf.firstrec || xf.lastrec != FF->pf.lastrec ) {	// if changed the records we want to see
		xf = FF->pf;	// update from index
		_currentrecord = rec_getrec(FF,FF->pf.firstrec);
		_printstorage = [[NSTextStorage alloc] init];
		_layoutmanager = [[NSLayoutManager alloc] init];
		[_layoutmanager setDelegate:self];
		[_layoutmanager setBackgroundLayoutEnabled:NO];
		[_printstorage addLayoutManager:_layoutmanager];
		for (NSInteger vcount = self.subviews.count; vcount >= 0; vcount--)	// remove any subviews from previous preview use
			[self.subviews.lastObject removeFromSuperview];
	}
//	NSLog(@"PR: %@", NSStringFromRange(*rangeptr));
	return YES;
}
- (NSRect)rectForPage:(NSInteger)page {
//	NSLog(@"Seeking Page: %ld", page);
	if (FF->pf.totalpages < page && _currentrecord && _currentrecord->num != FF->pf.lastrec) {	// not already generated, and there's still some to generate
		targetPage = page;
		pageDone = NO;
		while (_currentrecord && !pageDone && _currentrecord->num != FF->pf.lastrec)	{	// while need to generate
			IRAttributedDisplayString *as = [[IRAttributedDisplayString alloc] initWithIRIndex:_document paragraphs:_paragraphs record:_currentrecord->num];
			
			_currententrylength = [[as string] length];
			_brokenheading = FALSE;
			_overflow = 0;
			[_printstorage appendAttributedString:as];
			
			NSUInteger slength = [[_printstorage string] length];
			[_printstorage linesForRange:NSMakeRange(slength-_currententrylength,_currententrylength)];	// get lines; force glyph generation
			if (_overflow)	{	// if run in to new container
				unsigned long baseindex = slength-_currententrylength;		// start of text to manipulate
				unsigned long gbase = baseindex;		// glyph generation base
				int hlevel = [[as attribute:IRHeadingLevelKey atIndex:0 effectiveRange:nil] intValue];
				BOOL pushed = FALSE;
				
				if (_brokenheading)	{
					int widows = [_printstorage linesForRange:NSMakeRange(baseindex,_currententrylength-_overflow)];
					if (widows) {
						if (widows <= MAXWIDOWS && (!FF->head.formpars.ef.runlevel || widows == 1 )) {	// if have broken entry with pushable lines
							[_printstorage beginEditing];
							[_printstorage replaceCharactersInRange:NSMakeRange(baseindex,0) withString:[NSString stringWithCharacters:nl length:widows]];
							[_printstorage endEditing];
							baseindex += widows;
							pushed = TRUE;
						}
						else	// set base to index beyond widows
							baseindex = slength-_overflow;
					}
				}
				if ((hlevel > 0 || !pushed && FF->head.formpars.ef.runlevel == 1 && _brokenheading) && FF->head.privpars.vmode == VM_FULL && (FF->head.formpars.pf.mc.pgcont == RH_COL || FF->head.formpars.pf.mc.pgcont == RH_PAGE
					&& (([[_layoutmanager textContainers] count])%FF->head.formpars.pf.mc.ncols) == 1)) {
					unichar cc = [[_printstorage string] characterAtIndex:baseindex-1];		// is newline if end of para
					
					if (cc != '\n')		// if we inserted continuation text within a para
						[_printstorage replaceCharactersInRange:NSMakeRange(baseindex++,0) withString:@"\n"];	// insert para break
					FF->continued = TRUE;
					IRAttributedDisplayString *cs = [[IRAttributedDisplayString alloc] initWithIRIndex:_document paragraphs:_paragraphs record:_currentrecord->num];
					[_printstorage insertAttributedString:cs atIndex:baseindex];
					if (cc != '\n')	{	// if we inserted continuation text within a para
						NSMutableDictionary * tdic = [NSMutableDictionary dictionaryWithDictionary:[_printstorage attributesAtIndex:baseindex effectiveRange:NULL]];
						NSMutableParagraphStyle * pm = [[NSMutableParagraphStyle alloc] init];
						
						[pm setParagraphStyle:[tdic objectForKey:NSParagraphStyleAttributeName]];
						[pm setFirstLineHeadIndent:[pm headIndent]];
						[tdic setObject:pm forKey:NSParagraphStyleAttributeName];	// modify para style for continuation
						[_printstorage setAttributes:tdic range:NSMakeRange(baseindex+[cs length], 1)];	// restore attributes
					}
				}
				[_printstorage linesForRange:NSMakeRange(gbase,[[_printstorage string] length]-gbase)];	// force glyph generation
			}
			ENTRYINFO * eip = [as entryInformation];
			_consumed += eip->consumed;
			if (FF->pf.rnum && FF->pf.totalpages >= FF->pf.first-1 && FF->pf.totalpages <= FF->pf.last)	{	// if started counting (valid record) and within page range
				FF->pf.entries++;
				FF->pf.prefs += eip->prefs;
				FF->pf.crefs += eip->crefs;
				FF->pf.characters += _currententrylength;
				FF->pf.lastrnum = _currentrecord->num;
				if (eip->ulevel <= 0)
					FF->pf.uniquemain++;
			}
			previousRecord = _currentrecord;
			_currentrecord = [_document skip:1 from:_currentrecord];
		}
	}
	if (FF->pf.totalpages >= page || FF->pf.totalpages == page-1 && ([[_layoutmanager textContainers] count]%FF->head.formpars.pf.mc.ncols))	// if filled to or beyond target page or filled on fractional page
		return NSMakeRect(_pagerect.origin.x,(page-1)*_pagerect.size.height,_pagerect.size.width,_pagerect.size.height);
	else
		return NSZeroRect;
}
- (void)layoutManager:(NSLayoutManager *)layoutManager didCompleteLayoutForTextContainer:(NSTextContainer *)textContainer atEnd:(BOOL)layoutFinishedFlag {
	if (textContainer == nil) {	// if need to add container(s)
		[self _addColumnForLayout:layoutManager];
//		NSLog(@"Container Added: %ld", [layoutManager textContainers].count-1);
	}
	else {
		if (!_overflow || silentMode)	// if not redoing for overflow, or silent for statistics [last fix 3/17/20]
			FF->pf.totalpages = _layoutmanager.textContainers.count/FF->head.formpars.pf.mc.ncols;	// total completed
		if (!layoutFinishedFlag) {		// can't fit all in this container
			NSRange gr = [layoutManager glyphRangeForTextContainer:textContainer];
			unsigned long laidout = [layoutManager characterIndexForGlyphAtIndex:NSMaxRange(gr)-1]+1;
			NSUInteger slength = [[_printstorage string] length];
			
			_overflow = slength - laidout;
			if (_overflow && slength != laidout + _currententrylength)	// if heading broken
				_brokenheading = TRUE;
			NSUInteger index = [[layoutManager textContainers] indexOfObject:textContainer];
			if (index == targetPage*FF->head.formpars.pf.mc.ncols-1)	{	// if at end of page we want
				pageDone = TRUE;
	//			NSLog(@"Page %d Done: [%ld]", (long)targetPage, [[layoutManager textContainers] indexOfObject:textContainer]);
			}
		}
	}
//	else
//		NSLog(@"Need More Text: [%ld]", [[layoutManager textContainers] indexOfObject:textContainer]);
}
- (void)_addColumnForLayout:(NSLayoutManager *)lm {
	int voffset = _pagerect.size.height*([[lm textContainers] count]/FF->head.formpars.pf.mc.ncols);	// vertical offset (height of all pages above current)
	NSSize csize = _pagerect.size;	// base container is page rect
	NSSize newsize = NSMakeSize(_pagerect.size.width,_pagerect.size.height+voffset);
	int colindex = [[lm textContainers] count]%FF->head.formpars.pf.mc.ncols;

	[self setFrameSize:newsize];	// enlarge if necessary
	if (FF->head.formpars.pf.mc.ncols > 1)
		csize.width = (_pagerect.size.width-FF->head.formpars.pf.mc.ncols*FF->head.formpars.pf.mc.gutter)/FF->head.formpars.pf.mc.ncols;
	NSTextContainer * tc = [[NSTextContainer alloc] initWithContainerSize:csize];
	[lm addTextContainer:tc];
	if (!silentMode) {
		float xpos = colindex ? colindex * (csize.width+FF->head.formpars.pf.mc.gutter) : 0;
		NSTextView * tv = [[NSTextView alloc] initWithFrame:NSMakeRect(xpos,newsize.height-csize.height,csize.width, csize.height) textContainer:tc];
		[self addSubview:tv];
	}
}
- (void)drawPageBorderWithSize:(NSSize)borderSize {
	NSPrintOperation * po = [NSPrintOperation currentOperation];
	NSPrintInfo * pinfo = [po printInfo];
	NSRect frame = [self frame];
	float writexpos, writeypos;
	NSAttributedString * as;

	_currentpage = [po currentPage] + FF->head.formpars.pf.firstpage-1;	// add offset for base page number
	[self setFrame:NSMakeRect(0,0,borderSize.width,borderSize.height)];
	[self lockFocus];
	
	as = [self getTitleString:YES position:0];
	writexpos = [pinfo leftMargin];
	writeypos = borderSize.height-([pinfo topMargin]+[as size].height)/2;
	[as drawAtPoint:NSMakePoint(writexpos, writeypos)];
	
	as = [self getTitleString:YES position:1];
	writexpos = (borderSize.width-[as size].width)/2;
	[as drawAtPoint:NSMakePoint(writexpos, writeypos)];
	
	as = [self getTitleString:YES position:2];
	writexpos = borderSize.width-[as size].width-[pinfo rightMargin];
	[as drawAtPoint:NSMakePoint(writexpos, writeypos)];
	
	as = [self getTitleString:NO position:0];
	writexpos = [pinfo leftMargin];
	writeypos = ([pinfo bottomMargin]-[as size].height)/2;
	[as drawAtPoint:NSMakePoint(writexpos, writeypos)];
	
	as = [self getTitleString:NO position:1];
	writexpos = (borderSize.width-[as size].width)/2;
	[as drawAtPoint:NSMakePoint(writexpos, writeypos)];
	
	as = [self getTitleString:NO position:2];
	writexpos = borderSize.width-[as size].width-[pinfo rightMargin];
	[as drawAtPoint:NSMakePoint(writexpos, writeypos)];
	[self unlockFocus];
	[self setFrame:frame];
}
- (void)beginDocument {
	[super beginDocument];
	_currenttime = time(NULL);
}
- (void)endDocument {
	[super endDocument];
}
- (NSAttributedString *)getTitleString:(BOOL)header position:(int)sourceindex {
	BOOL rightpage = _currentpage&1 || !FF->head.formpars.pf.mc.reflect;
	char base[500];
	int limit = 500;
	HEADERFOOTER * hfp;
	char * source;
	char cc, *tpos, *dest;
	char fontid;
	enum {
		PNUM_ARAB = 0,
		PNUM_ROMANLOWER,
		PNUM_ROMANUPPER
	};
	
	if (rightpage)
		hfp = header ? &FF->head.formpars.pf.righthead : &FF->head.formpars.pf.rightfoot;
	else
		hfp = header ? &FF->head.formpars.pf.lefthead : &FF->head.formpars.pf.leftfoot;
	if (sourceindex == 0)
		source = hfp->left;
	else if (sourceindex == 1)
		source = hfp->center;
	else
		source = hfp->right;
	dest = base;
	if (fontid = type_findlocal(FF->head.fm,hfp->hffont,0))	{	// if want other than default font
		*dest++ = FONTCHR;
		*dest++ = fontid+FX_FONT;
	}
	if (hfp->hfstyle.style) {
		*dest++ = CODECHR;
		*dest++ = hfp->hfstyle.style;
	}
	while (*source && dest-base < limit)	{ 
		switch (cc = *source++)	{
			case ESCCHR:		/* escaped special char */
				if (*source)
					*dest++ = *source++;
				continue;
			case '#':		/* page # */
				if (!FF->head.formpars.pf.numformat)	/* arabic numerals */
					dest += sprintf(dest,"%lu", (unsigned long)_currentpage);
				else
					dest += str_roman(dest, (int)_currentpage, FF->head.formpars.pf.numformat == PNUM_ROMANUPPER);
				break;
			case '@':		/* date */
				dest += getdatetime(dest,FF->head.formpars.pf.dateformat,FF->head.formpars.pf.timeflag,_currenttime);
				break;
			case '%':		/* index file name */
				strcpy(dest,(char *)[[FF->owner displayName] UTF8String]);
				dest += strlen(dest);
				break;
			default:
				*dest++ = cc;
		}
	}
	if (dest-base >= limit)
		dest = base+limit;
	*dest = '\0';
	if (hfp->hfstyle.cap == FC_INITIAL)	{
		unichar cu;
		
		tpos = str_skipcodes(base);
		while (*tpos == '\"' || *tpos == '\'')
			tpos++;
		cu = u8_toU(tpos);
		if (u_islower(cu))
			u8_appendU(tpos,u_toupper(cu));	// conversion relies on fact that uc and lc are same size
	}
	else if (hfp->hfstyle.cap == FC_UPPER)
		str_upr(base);
	return [NSAttributedString asFromXString:base fontMap:FF->head.fm size:hfp->size termchar:0];
}
@end
/**********************************************************************/
static short getdatetime(char *dstring, char dateform, char timeflag, time_t time)		/* forms long or short date string */

{
	NSDateFormatter * df = [[NSDateFormatter alloc] init];
	
	[df setFormatterBehavior:NSDateFormatterBehavior10_4];
	[df setDateStyle:dateform];	// 1 is short, 3 is long
	[df setTimeStyle: timeflag ? NSDateFormatterShortStyle : dateform];
	strcpy(dstring,(char *)[[df stringFromDate:[NSDate dateWithTimeIntervalSince1970:time]] cStringUsingEncoding:NSUTF8StringEncoding]);
	return (strlen(dstring));
}

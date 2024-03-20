//
//  IRTextView.m
//  Cindex
//
//  Created by PL on 6/25/05.
//  Copyright 2005 Indexing Research. All rights reserved.
//

#import "IRIndexDocument.h"
#import "IRIndexTextWController.h"
#import "IRTextView.h"

@interface IRTextView (PrivateMethods)
- (void)_displaySelection:(BOOL)openmode;
@end

@implementation IRTextView
- (void)keyDown:(NSEvent *)theEvent {
	NSString * kchars = [theEvent characters];
	unichar uchar = [kchars characterAtIndex:0];

	if (uchar == NSUpArrowFunctionKey || uchar == NSDownArrowFunctionKey)	{
		NSRange selrange = [self selectedRange];
		
		if (uchar == NSUpArrowFunctionKey)	{
			if (selrange.location > 0)	// if room to go back
				selrange.location--;
		}
		else if (NSMaxRange(selrange) < [[self string] length])	// if room to go forward
			selrange.location = NSMaxRange(selrange);
		selrange.length = 0;
		[self setSelectedRange:[self selectionRangeForProposedRange:selrange granularity:NSSelectByParagraph]];
		[self scrollRangeToVisible:[self selectedRange]];
		[self _displaySelection:NO];
	}
	else if (uchar == '\r')
		[self _displaySelection:YES];
	else
		[super keyDown:theEvent];
}
- (void)cursorUpdate:(NSEvent *)theEvent	{
	[[NSCursor arrowCursor] set];
}
- (void)mouseMoved:(NSEvent *)theEvent	{
	// need to override to prevent text cursor overriding our cursor
}
- (void)mouseEntered:(NSEvent *)theEvent	{
	// need to override to prevent text cursor overriding our cursor
}
- (void)mouseExited:(NSEvent *)theEvent	{
	// need to override to prevent text cursor overriding our cursor
}
- (void)mouseDown:(NSEvent *)theEvent	{
	[super mouseDown:theEvent];
	[self _displaySelection:[theEvent clickCount] == 2];
}
- (void)resetCursorRects {
	[self addCursorRect:[self visibleRect] cursor:[NSCursor arrowCursor]];
}
- (NSRange)selectionRangeForProposedRange:(NSRange)prange granularity:(NSSelectionGranularity)granularity {
	NSRange linerange;
//	[[self string] getLineStart:&linerange.location end:&linerange.length contentsEnd:NULL forRange:prange];
	[[self string] getParagraphStart:&linerange.location end:&linerange.length contentsEnd:NULL forRange:prange];
	linerange.length -= linerange.location;
	return linerange;
}
- (void)selectFirstMessage {
	[self setSelectedRange:[self selectionRangeForProposedRange:NSMakeRange(0,1) granularity:NSSelectByParagraph]];
	[self _displaySelection:NO];
}
- (void)_displaySelection:(BOOL)openmode {
	RECN record = [[[self string] substringWithRange:[self selectedRange]] intValue];
	if (record && [[(IRIndexTextWController *)[self delegate] document] canCloseActiveRecord])	{	// if legal value
		if (openmode)	// if force open mode
			[[(IRIndexTextWController *)[self delegate] document] openRecord:record];
		else
			[[(IRIndexTextWController *)[self delegate] document] selectRecord:record range:NSMakeRange(0,0)];
	}
}
- (void)drawPageBorderWithSize:(NSSize)borderSize {
	NSPrintOperation * po = [NSPrintOperation currentOperation];
	NSPrintInfo * pInfo = [po printInfo];
	NSRect frame = [self frame];
	float writexpos, writeypos;
	NSAttributedString * as = [[NSAttributedString alloc] initWithString:[[self window] title]];
	NSAttributedString * as1 = [[NSAttributedString alloc] initWithString:[NSString stringWithFormat:@"%ld", (long)[po currentPage]]];

	[self setFrame:NSMakeRect(0,0,borderSize.width,borderSize.height)];
	[self lockFocus];
	
	writeypos = ([pInfo topMargin]-[as size].height)/2;	// for flipped view
	writexpos = (borderSize.width-[as size].width)/2;
	[as drawAtPoint:NSMakePoint(writexpos, writeypos)];

	writeypos = borderSize.height-([pInfo bottomMargin]+[as1 size].height)/2;	// for flipped view
	writexpos = (borderSize.width-[as1 size].width)/2;
	[as1 drawAtPoint:NSMakePoint(writexpos, writeypos)];
	
	[self unlockFocus];
	[self setFrame:frame];
}
#if 0
- (void)beginDocument {
	NSPrintInfo * pinfo = [[[self delegate] document] printInfo];
	
	NSRect prect = NSMakeRect(0,0,[pinfo paperSize].width-[pinfo rightMargin]-[pinfo leftMargin],
				[pinfo paperSize].height-[pinfo topMargin]-[pinfo bottomMargin]);
	_oldframesize = [self frame].size;
	[self setFrameSize:NSMakeSize([self frame].size.height, prect.size.width)];	// set frame width to printable
	[super beginDocument];
}
- (void)endDocument {
	[super endDocument];
	[self setFrameSize:_oldframesize];	// set frame width to printable
}
#endif
@end

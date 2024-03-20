//
//  IRIndexTextWController.m
//  Cindex
//
//  Created by PL on 1/17/05.
//  Copyright 2005 Indexing Research. All rights reserved.
//

#import "IRIndexTextWController.h"

@implementation IRIndexTextWController
- (id)init	{
	return [self initWithAttributedString:nil];
}
- (id)initWithAttributedString:(NSAttributedString *)string	{
    if (self = [super initWithWindowNibName:@"IRIndexTextWController"])
		_string = string;
    return self;
}
- (void)setTitle:(NSString *)string	{
	_title = string;
	[self synchronizeWindowTitleWithDocumentName];
}
- (void)setAttributedString:(NSAttributedString *)astring	{
	unichar firstchar = [[astring string] characterAtIndex:0];
	
	[[_mainview textStorage] setAttributedString:astring];
	if (!u_isdigit(firstchar) && !u_isspace(firstchar))	// if not potential record number lead
		[_mainview setSelectable:NO];
	else
		[_mainview selectFirstMessage];
}
- (void)awakeFromNib {
	[super awakeFromNib];
	NSPrintInfo * pinfo = [NSPrintInfo sharedPrintInfo];
	NSSize csize = NSMakeSize([pinfo paperSize].width-[pinfo rightMargin]-[pinfo leftMargin],[pinfo paperSize].height-[pinfo topMargin]-[pinfo bottomMargin]);
	NSSize scrollsize = [NSScrollView frameSizeForContentSize:csize
									horizontalScrollerClass:nil verticalScrollerClass:[NSScroller class]
									borderType:NSNoBorder controlSize:NSRegularControlSize scrollerStyle:NSScrollerStyleOverlay];
	
	[[self window] setContentMaxSize:scrollsize];		// set max width
	[[self window] setContentSize:NSMakeSize(scrollsize.width,[[[self window] contentView] frame].size.height)];	// set display width
	[(NSClipView *)[_mainview superview] setDocumentCursor:[NSCursor arrowCursor]];
	[_mainview setUsesFontPanel:NO];
	[self setAttributedString:_string];
}
- (NSString *)windowTitleForDocumentDisplayName:(NSString *)docname {
	return [NSString stringWithFormat:@"%@: %@",docname, _title];
}
#if 0
- (void)windowWillClose:(NSNotification *)notification {
	NSLog(@"Closing");
}
- (void)windowDidUpdate:(NSNotification *)aNotification {
	NSLog(@"Updating");
}
- (void)windowDidBecomeMain:(NSNotification *)notification {
	NSLog(@"Became Main");
}
#endif
- (NSView *)printView {
	return _mainview;
}
@end

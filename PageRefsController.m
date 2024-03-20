//
//  PageRefsController.m
//  Cindex
//
//  Created by PL on 1/9/05.
//  Copyright 2005 Indexing Research. All rights reserved.
//

#import "PageRefsController.h"
#import "IRIndexDocument.h"
#import "commandutils.h"
#import "utilities.h"
#import "index.h"

@interface PageRefsController (PrivateMethods)
- (void)_recoverStyles:(int)sindex;
- (void)_setStyles:(int)sindex;
@end

@implementation PageRefsController
- (id)init	{
    self = [super initWithWindowNibName:@"PageRefsController"];
    return self;
}
- (void)awakeFromNib {
	[super awakeFromNib];
	if ([self document])
		_lParamPtr = &[[self document] iIndex]->head.formpars.ef.lf;
	else
		_lParamPtr = &g_prefs.formpars.ef.lf;
	_lParams = *_lParamPtr;
	[connecttext setStringValue:[NSString stringWithCString:_lParams.connect encoding:NSUTF8StringEncoding]];
	[conflate selectItemAtIndex:_lParams.conflate];
	[abbrevrule selectItemAtIndex:_lParams.abbrevrule];
	[suppressparts setState:_lParams.suppressparts];
	[suppressto setStringValue:[NSString stringWithCString:_lParams.suppress encoding:NSUTF8StringEncoding]];
	[concatwith setStringValue:[NSString stringWithCString:_lParams.concatenate encoding:NSUTF8StringEncoding]];

	[beforesingle setStringValue:[NSString stringWithCString:_lParams.llead1 encoding:NSUTF8StringEncoding]];
	[beforemultiple setStringValue:[NSString stringWithCString:_lParams.lleadm encoding:NSUTF8StringEncoding]];
	[after setStringValue:[NSString stringWithCString:_lParams.trail encoding:NSUTF8StringEncoding]];
	[rightjustify setState:_lParams.rjust];
	[self showLeader:rightjustify];

	[arrangesorted setState:_lParams.sortrefs];
	hideduplicates.enabled = arrangesorted.state;
	[hideduplicates setState: hideduplicates.enabled ? _lParams.noduplicates : NO];
	[suppressall setState:_lParams.suppressall];
}
- (IBAction)showHelp:(id)sender {
	NSString * hstring = [sender window] == [self window] ? @"pageform0_Anchor-14210" : @"pageform4_Anchor-14210";
	[[NSHelpManager sharedHelpManager] openHelpAnchor:hstring inBook:@"Cindex 4.2.5 Help"];
}
- (IBAction)showLeader:(id)sender {
	if ([sender state])	{
		[dotleader setEnabled:YES];
		[dotleader setState:_lParams.leader];
	}
	else {
		[dotleader setEnabled:NO];
		[dotleader setState:NO];
	}
}
- (IBAction)arrangeSorted:(id)sender {
	if ([sender state])
		[hideduplicates setEnabled:YES];
	else {
		[hideduplicates setEnabled:NO];
		[hideduplicates setState:NO];
	}
}- (IBAction)showSegment:(id)sender {
	NSInteger index = [sender indexOfSelectedItem];
	
	[self _recoverStyles:_currentsegment];
	[self _setStyles:index];
	_currentsegment = index;
}
- (void)_recoverStyles:(int)sindex {
	_lstyle[sindex].loc.style = 0;
	if ([[styles cellWithTag:0] state])
		_lstyle[sindex].loc.style |= FX_BOLD;
	if ([[styles cellWithTag:1] state])
		_lstyle[sindex].loc.style |= FX_ITAL;
	if ([[styles cellWithTag:2] state])
		_lstyle[sindex].loc.style |= FX_ULINE;
	if ([[styles cellWithTag:3] state])
		_lstyle[sindex].loc.style |= FX_SMALL;

	_lstyle[sindex].punct.style = 0;
	if ([[leadpunct cellWithTag:0] state])
		_lstyle[sindex].punct.style |= FX_BOLD;
	if ([[leadpunct cellWithTag:1] state])
		_lstyle[sindex].punct.style |= FX_ITAL;
	if ([[leadpunct cellWithTag:2] state])
		_lstyle[sindex].punct.style |= FX_ULINE;
	if ([[leadpunct cellWithTag:3] state])
		_lstyle[sindex].punct.style |= FX_SMALL;
}
- (void)_setStyles:(int)sindex {
	[[styles cellWithTag:0] setState:_lstyle[sindex].loc.style&FX_BOLD ? YES : NO];
	[[styles cellWithTag:1] setState:_lstyle[sindex].loc.style&FX_ITAL ? YES : NO];
	[[styles cellWithTag:2] setState:_lstyle[sindex].loc.style&FX_ULINE ? YES : NO];
	[[styles cellWithTag:3] setState:_lParams.lstyle[sindex].loc.style&FX_SMALL ? YES : NO];
	
	[[leadpunct cellWithTag:0] setState:_lstyle[sindex].punct.style&FX_BOLD ? YES : NO];
	[[leadpunct cellWithTag:1] setState:_lstyle[sindex].punct.style&FX_ITAL ? YES : NO];
	[[leadpunct cellWithTag:2] setState:_lstyle[sindex].punct.style&FX_ULINE ? YES : NO];
	[[leadpunct cellWithTag:3] setState:_lstyle[sindex].punct.style&FX_SMALL ? YES : NO];
}
- (IBAction)showStylePanel:(id)sender {
	memcpy(&_lstyle,_lParams.lstyle, sizeof(_lstyle));	// save copy for editing
	_currentsegment = 0;
	[self _setStyles:0];
	[segment selectItemAtIndex:0];
	centerwindow([self window],locatorstyle);
	[NSApp runModalForWindow:locatorstyle]; 
}
- (IBAction)closeStylePanel:(id)sender {    
	if ([sender tag] == OKTAG)
		[self _recoverStyles:_currentsegment];
		memcpy(_lParams.lstyle,&_lstyle, sizeof(_lstyle));	// copy back style params
	[locatorstyle close];
	[NSApp stopModal]; 
}
- (IBAction)closePanel:(id)sender {    
	if ([sender tag] == OKTAG)	{
		if (![[self window] makeFirstResponder:[self window]])	// if bad text somewhere
			return;
		strcpy(_lParams.connect,[[connecttext stringValue] UTF8String]);
		_lParams.conflate = [conflate indexOfSelectedItem];
		_lParams.abbrevrule = [abbrevrule indexOfSelectedItem];
		_lParams.suppressparts = [suppressparts state];
		strcpy(_lParams.suppress,[[suppressto stringValue] UTF8String]);
		strcpy(_lParams.concatenate,[[concatwith stringValue] UTF8String]);
		
		strcpy(_lParams.llead1,[[beforesingle stringValue] UTF8String]);
		strcpy(_lParams.lleadm,[[beforemultiple stringValue] UTF8String]);
		strcpy(_lParams.trail,[[after stringValue] UTF8String]);

		_lParams.rjust = [rightjustify state];
		_lParams.leader = [dotleader state];
		_lParams.sortrefs = [arrangesorted state];
		_lParams.suppressall = [suppressall state];
		_lParams.noduplicates = [hideduplicates state];
		*_lParamPtr = _lParams;
		index_markdirty([[self document] iIndex]);
		[[self document] reformat];
	}
	if ([self document])
		[self.window.sheetParent endSheet:self.window returnCode:[sender tag]];
	else {
		[self close];
		[NSApp stopModal]; 
	}
}
- (void)controlTextDidChange:(NSNotification *)note	{
	NSControl * control = [note object];
	
	if (control == connecttext || control == suppressto || control == concatwith ||
		control == beforesingle || control == beforemultiple || control == after) {
		checktextfield(control, FMSTRING);
	}
}
@end

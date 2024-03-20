//
//  HeadFootController.m
//  Cindex
//
//  Created by PL on 1/9/05.
//  Copyright 2005 Indexing Research. All rights reserved.
//

#import "IRIndexDocumentController.h"
#import "IRIndexDocument.h"
#import "HeadFootController.h"
#import "TextStyleController.h"
#import "index.h"

@interface HeadFootController (PrivateMethods)
- (void)_setLeftHeadText;
- (void)_setLeftFootText;
- (void)_setRightHeadText;
- (void)_setRightFootText;
- (void)_getLeftHeadText;
- (void)_getLeftFootText;
- (void)_getRightHeadText;
- (void)_getRightFootText;
- (void)_setFont:(char *)font menu:(NSPopUpButton *)menu;
- (void)_getFont:(char *)font menu:(NSPopUpButton *)menu;
@end

@implementation HeadFootController
- (id)init	{
    self = [super initWithWindowNibName:@"HeadFootController"];
    return self;
}
- (void)awakeFromNib {
	[super awakeFromNib];
	if ([self document])
		_hParamPtr = &[[self document] iIndex]->head.formpars.pf;
	else 
		_hParamPtr = &g_prefs.formpars.pf;
	_hParams = *_hParamPtr;
	
	[rhfont addItemsWithTitles:[IRdc fonts]];
	[rffont addItemsWithTitles:[IRdc fonts]];
	[self _setRightHeadText];
	[self _setRightFootText];
	if (_hParams.mc.reflect)	{	// if facing pages
		[lhfont addItemsWithTitles:[IRdc fonts]];
		[lffont addItemsWithTitles:[IRdc fonts]];
		[self _setLeftHeadText];
		[self _setLeftFootText];
	}
	else {	// remove tabs
		[tab removeTabViewItem:[tab tabViewItemAtIndex:0]];
		[tab removeTabViewItem:[tab tabViewItemAtIndex:0]];
		[[tab tabViewItemAtIndex:0] setLabel:@"Header"];
		[[tab tabViewItemAtIndex:1] setLabel:@"Footer"];
		[copy setHidden:YES];
	}
	[dateformat selectCellWithTag:_hParams.dateformat];
	[addtime setState:_hParams.timeflag];
	[firstpage setIntValue:_hParams.firstpage];
	[numberformat selectItemAtIndex:_hParams.numformat];
	[tab selectTabViewItemAtIndex:0];
}
- (IBAction)showHelp:(id)sender {
	[[NSHelpManager sharedHelpManager] openHelpAnchor:@"headfoot0_Anchor-14210" inBook:@"Cindex 4.2.5 Help"];
}
- (void)_setLeftHeadText{
	[lhleft setStringValue:[NSString stringWithCString:_hParams.lefthead.left encoding:NSUTF8StringEncoding]];
	[lhcenter setStringValue:[NSString stringWithCString:_hParams.lefthead.center encoding:NSUTF8StringEncoding]];
	[lhright setStringValue:[NSString stringWithCString:_hParams.lefthead.right encoding:NSUTF8StringEncoding]];
	[self _setFont:_hParams.lefthead.hffont menu:lhfont];
	[lhcombo setIntValue:_hParams.lefthead.size];
}
- (void)_setLeftFootText{
	[lfleft setStringValue:[NSString stringWithCString:_hParams.leftfoot.left encoding:NSUTF8StringEncoding]];
	[lfcenter setStringValue:[NSString stringWithCString:_hParams.leftfoot.center encoding:NSUTF8StringEncoding]];
	[lfright setStringValue:[NSString stringWithCString:_hParams.leftfoot.right encoding:NSUTF8StringEncoding]];
	[self _setFont:_hParams.leftfoot.hffont menu:lffont];
	[lfcombo setIntValue:_hParams.leftfoot.size];
}
- (void)_setRightHeadText{
	[rhleft setStringValue:[NSString stringWithCString:_hParams.righthead.left encoding:NSUTF8StringEncoding]];
	[rhcenter setStringValue:[NSString stringWithCString:_hParams.righthead.center encoding:NSUTF8StringEncoding]];
	[rhright setStringValue:[NSString stringWithCString:_hParams.righthead.right encoding:NSUTF8StringEncoding]];
	[self _setFont:_hParams.righthead.hffont menu:rhfont];
	[rhcombo setIntValue:_hParams.righthead.size];
}
- (void)_setRightFootText{
	[rfleft setStringValue:[NSString stringWithCString:_hParams.rightfoot.left encoding:NSUTF8StringEncoding]];
	[rfcenter setStringValue:[NSString stringWithCString:_hParams.rightfoot.center encoding:NSUTF8StringEncoding]];
	[rfright setStringValue:[NSString stringWithCString:_hParams.rightfoot.right encoding:NSUTF8StringEncoding]];
	[self _setFont:_hParams.rightfoot.hffont menu:rffont];
	[rfcombo setIntValue:_hParams.rightfoot.size];
}
- (void)_getLeftHeadText{
	strcpy(_hParams.lefthead.left,[[lhleft stringValue] UTF8String]);
	strcpy(_hParams.lefthead.center,[[lhcenter stringValue] UTF8String]);
	strcpy(_hParams.lefthead.right,[[lhright stringValue] UTF8String]);
	[self _getFont:_hParams.lefthead.hffont menu:lhfont];
	_hParams.lefthead.size = [lhcombo intValue];
}
- (void)_getLeftFootText{
	strcpy(_hParams.leftfoot.left,[[lfleft stringValue] UTF8String]);
	strcpy(_hParams.leftfoot.center,[[lfcenter stringValue] UTF8String]);
	strcpy(_hParams.leftfoot.right,[[lfright stringValue] UTF8String]);
	[self _getFont:_hParams.leftfoot.hffont menu:lffont];
	_hParams.leftfoot.size = [lfcombo intValue];
}
- (void)_getRightHeadText{
	strcpy(_hParams.righthead.left,[[rhleft stringValue] UTF8String]);
	strcpy(_hParams.righthead.center,[[rhcenter stringValue] UTF8String]);
	strcpy(_hParams.righthead.right,[[rhright stringValue] UTF8String]);
	[self _getFont:_hParams.righthead.hffont menu:rhfont];
	_hParams.righthead.size = [rhcombo intValue];
}
- (void)_getRightFootText{
	strcpy(_hParams.rightfoot.left,[[rfleft stringValue] UTF8String]);
	strcpy(_hParams.rightfoot.center,[[rfcenter stringValue] UTF8String]);
	strcpy(_hParams.rightfoot.right,[[rfright stringValue] UTF8String]);
	[self _getFont:_hParams.rightfoot.hffont menu:rffont];
	_hParams.rightfoot.size = [rfcombo intValue];
}
- (void)_setFont:(char *)font menu:(NSPopUpButton *)menu {
	if (*font)
		[menu selectItemWithTitle:[NSString stringWithCString:font encoding:NSUTF8StringEncoding]];
	else
		[menu selectItemAtIndex:0];
}
- (void)_getFont:(char *)font menu:(NSPopUpButton *)menu {
	if ([menu indexOfSelectedItem])
		strcpy(font,[[menu title] UTF8String]);
	else
		*font = '\0';
}
- (IBAction)copyPageSettings:(id)sender {
	if ([[[tab selectedTabViewItem] identifier] intValue])	{	// right page displayed
		[self _getRightHeadText];
		[self _getRightFootText];		
		_hParams.lefthead = _hParams.righthead;
		_hParams.leftfoot = _hParams.rightfoot;
		[self _setLeftHeadText];
		[self _setLeftFootText];
	}
	else	{	// left page displayed
		[self _getLeftHeadText];
		[self _getLeftFootText];
		_hParams.righthead = _hParams.lefthead;
		_hParams.rightfoot = _hParams.leftfoot;
		[self _setRightHeadText];
		[self _setRightFootText];
	}
}
- (IBAction)showTextStylePanel:(id)sender {
	CSTYLE * eStyle = NULL;
	if (sender == lhstyle)
		eStyle = &_hParams.lefthead.hfstyle;
	else if (sender == lfstyle)
		eStyle = &_hParams.leftfoot.hfstyle;
	else if (sender == rhstyle)
		eStyle = &_hParams.righthead.hfstyle;
	else if (sender == rfstyle)
		eStyle = &_hParams.rightfoot.hfstyle;
	[TextStyleController showForStyle:eStyle extraMode:0];
}
- (IBAction)closePanel:(id)sender {    
	if ([sender tag] == OKTAG)	{
		if (![[self window] makeFirstResponder:[self window]])	// if bad text somewhere
			return;
		if ([tab numberOfTabViewItems] > 2)	{	// left page settings visible
			[self _getLeftHeadText];
			[self _getLeftFootText];
		}
		[self _getRightHeadText];
		[self _getRightFootText];		
		_hParams.dateformat = [[dateformat selectedCell] tag];
		_hParams.timeflag = [addtime state];
		_hParams.firstpage = [firstpage intValue];
		_hParams.numformat = [numberformat indexOfSelectedItem];
			
		*_hParamPtr = _hParams;
		index_markdirty([[self document] iIndex]);
		[[NSNotificationCenter defaultCenter] postNotificationName:NOTE_HEADERFOOTERCHANGED object:[self document]];
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
	
	if (control == lhleft || control == lhcenter || control == lhright || 
		control == lfleft || control == lfcenter || control == lfright || 
		control == rhleft || control == rhcenter || control == rhright || 
		control == rfleft || control == rfcenter || control == rfright) {
		checktextfield(control,FTSTRING);
	}
}
@end

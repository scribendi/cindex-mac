//
//  StyleLayoutController.m
//  Cindex
//
//  Created by PL on 1/9/05.
//  Copyright 2005 Indexing Research. All rights reserved.
//

#import "units.h"
#import "commandutils.h"
#import "type.h"
#import "index.h"
#import "StyleLayoutController.h"
#import "IRIndexDocument.h"

static short DUMMYLINESPACE;

@interface StyleLayoutController (PrivateMethods)
- (void)_displayIndentsInUnit:(int)unit;
@end

@implementation StyleLayoutController
- (id)init	{
    self = [super initWithWindowNibName:@"StyleLayoutController"];
    return self;
}
- (void)awakeFromNib {
	[super awakeFromNib];
	int count;
	NSSize metrics;
	
	if ([self document])	{
		INDEX * FF = [[self document] iIndex];
		_fParamPtr = &FF->head.formpars;
		_ip = &FF->head.indexpars;
		metrics = type_getfontmetrics(FF->head.formpars.ef.field[0].font,FF->head.formpars.ef.field[0].size, FF);
	}
	else {
		_fParamPtr = &g_prefs.formpars;
		_ip = &g_prefs.indexpars;
		metrics = type_getfontmetrics(_fParamPtr->ef.field[0].font,_fParamPtr->ef.field[0].size,NULL);
	}
	_fParams = *_fParamPtr;
	_unit = g_prefs.privpars.eunit;
	env_setemspace(metrics.width);	// set size of em space
	DUMMYLINESPACE = metrics.height;
	[heading removeAllItems];
	[indentlevel removeAllItems];
	[collapseheading removeAllItems];
	for (count = 0; count < _ip->maxfields-1; count++)	{	/* for all fields */
		NSString * tstring = [NSString stringWithCString:_ip->field[count].name encoding:NSUTF8StringEncoding];
		[indentlevel addItemWithTitle:tstring];
		if (count < _ip->maxfields-2)	{
			[heading addItemWithTitle:tstring];
			[collapseheading addItemWithTitle:tstring];
		}
	}
	[collapsebelow setState:_fParams.ef.collapselevel];
	[self setEnables:collapsebelow];
	[collapseheading selectItemAtIndex:_fParams.ef.collapselevel-1];
	[style selectCellWithTag:_fParams.ef.runlevel ? 1 : 0];
	[self setEnables:style];
	[variant selectItemAtIndex:_fParams.ef.style];

	[indenttype selectItemAtIndex:_fParams.ef.itype];
	[self setEnables:indenttype];
	
	[spacing selectItemAtIndex:_fParams.pf.linespace];
	[spacingunit selectItemAtIndex:_unit];
	[autospace setState:_fParams.pf.autospace];
	[self setEnables:autospace];
	[mainheadspace setIntValue:_fParams.pf.entryspace];
	[alphaspace setIntValue:_fParams.pf.above];
	
	[quotepunct setState:_fParams.ef.adjustpunct];
	[stylepunct setState:_fParams.ef.adjstyles];
}
- (IBAction)showHelp:(id)sender {
	[[NSHelpManager sharedHelpManager] openHelpAnchor:@"stylelayout0_Anchor-14210" inBook:@"Cindex 4.2.5 Help"];
}
- (IBAction)setEnables:(id)sender {
	if (sender == collapsebelow)	{
		if (![sender state])	// if disabling
			[collapseheading selectItemAtIndex:-1];
		else
			[collapseheading selectItemAtIndex:0];
		[collapseheading setEnabled:[sender state]];
	}
	else if (sender == style) {
		if ([[sender selectedCell] tag]) {	// if run-in
			[heading setEnabled:YES];
			[heading selectItemAtIndex:_fParams.ef.runlevel > 0 ? _fParams.ef.runlevel-1 : 0];
			[[variant itemAtIndex:FL_RUNBACK] setEnabled:NO];
			[[variant itemAtIndex:FL_NOSUPPRESS] setEnabled:NO];
			[[variant itemAtIndex:FL_MODRUNIN] setEnabled:YES];
		}
		else {		// indented
			[heading setEnabled:NO];
			[heading selectItemAtIndex:-1];
			[[variant itemAtIndex:FL_RUNBACK] setEnabled:YES];
			[[variant itemAtIndex:FL_NOSUPPRESS] setEnabled:YES];
			[[variant itemAtIndex:FL_MODRUNIN] setEnabled:NO];
		}
		[variant selectItemAtIndex:0];
	}
	else if (sender == autospace) {
		if ([sender state])	{	// if autospacing enabled
			[spacesize setEnabled:NO];
			_linespaceptr = &DUMMYLINESPACE;
		}
		else {
			[spacesize setEnabled:YES];
			_linespaceptr = &_fParams.pf.lineheight;
		}
		[self setEnables:spacingunit];
	}
	else if (sender == indenttype) {
		NSInteger itype = [indenttype indexOfSelectedItem];
		
		[indentfieldbox setHidden:itype != FI_FIXED];
		[indentsizesbox setHidden:itype == FI_NONE];
		if (itype == FI_AUTO || itype == FI_NONE)	{	// if auto
			_indentunitptr = &_fParams.ef.autounit;
			_leadindentptr = &_fParams.ef.autolead;
			_runindentptr = &_fParams.ef.autorun;
		}
		else {		// fixed or special spacing
			NSInteger field;
			
			if (itype == FI_SPECIAL)
//				field = _ip->maxfields-2;	// field before page field
				field = L_SPECIAL;	// level 15 heading
			else
				field = [indentlevel indexOfSelectedItem];
			_indentunitptr = &_fParams.ef.fixedunit;
			_leadindentptr = &_fParams.ef.field[field].leadindent;
			_runindentptr = &_fParams.ef.field[field].runindent;
		}
		[indentunit selectItemAtIndex:*_indentunitptr ? [indentunit indexOfItemWithTag:_unit] : 0];
		_currentunit = [[indentunit selectedItem] tag];
		[self _displayIndentsInUnit:_currentunit];
	}
	else if (sender == indentlevel) {
		NSInteger field = [indentlevel indexOfSelectedItem];
		
		[[self window] makeFirstResponder:[self window]];
		_leadindentptr = &_fParams.ef.field[field].leadindent;
		_runindentptr = &_fParams.ef.field[field].runindent;
		[self _displayIndentsInUnit:_currentunit];
	}
	else if (sender == indentunit) {
		if ([[self window] makeFirstResponder:[self window]])	{	// if text OK
			*_indentunitptr = [sender indexOfSelectedItem];	// relevant values: 0 (auto); >0 (fixed)
			short newunit = *_indentunitptr-1;
			
			[self _displayIndentsInUnit:newunit];
			_currentunit = newunit;
		}
	}
	else if (sender == spacingunit) {
		if ([[self window] makeFirstResponder:[self window]])	{	// if text OK
			_unit = [sender indexOfSelectedItem];
			[spacesize setFloatValue:env_toexpress(_unit,*_linespaceptr)];
		}
	}
}
- (void)_displayIndentsInUnit:(int)unit {
	if (_currentunit == U_EMS) {		// if current unit ems
		*_leadindentptr = env_tobase(U_EMS,*_leadindentptr);	// convert from stored ems
		*_runindentptr = env_tobase(U_EMS,*_runindentptr);
	}
	[indentlead setFloatValue:env_toexpress(unit,*_leadindentptr)];
	[indentrunover setFloatValue:env_toexpress(unit,*_runindentptr)];
	if (unit == U_EMS) {		// if to ems, convert stored to ems
		*_leadindentptr = env_toexpress(U_EMS,*_leadindentptr);
		*_runindentptr = env_toexpress(U_EMS,*_runindentptr);
	}
}
- (IBAction)closePanel:(id)sender {    
	if ([sender tag] == OKTAG)	{
		if (![[self window] makeFirstResponder:[self window]])	// if bad text somewhere
			return;
		_fParams.ef.style = [variant indexOfSelectedItem];
		_fParams.ef.collapselevel = [collapsebelow state] ? [collapseheading indexOfSelectedItem]+1 : 0;
		_fParams.ef.runlevel = [[style selectedCell] tag] ? [heading indexOfSelectedItem]+1 : 0;
		_fParams.ef.itype = [indenttype indexOfSelectedItem];
		_fParams.pf.linespace = [spacing indexOfSelectedItem];
//		_fParams.pf.lineunit = [spacingunit indexOfSelectedItem];
		_fParams.pf.autospace = [autospace state];
		_fParams.pf.entryspace = [mainheadspace intValue];
		_fParams.pf.above = [alphaspace intValue];
		_fParams.ef.adjustpunct = [quotepunct state];
		_fParams.ef.adjstyles = [stylepunct state];
		
		*_fParamPtr = _fParams; 
		index_markdirty([[self document] iIndex]);
		[[self document] redisplay:0 mode:VD_CUR];	// redisplay all records
	}
	if ([self document])
		[self.window.sheetParent endSheet:self.window returnCode:[sender tag]];
	else {
		[self close];
		[NSApp stopModal]; 
	}
}
- (BOOL)control:(NSControl *)control textShouldEndEditing:(NSText *)editor {
	if (control == indentlead)	{
		if (_currentunit == U_EMS)	// if em spacing
			*_leadindentptr = [control floatValue];	// recover as unconverted value
		else	// set in points
			*_leadindentptr = env_tobase(_currentunit,[control floatValue]);
	}
	else if (control == indentrunover)	{
		if (_currentunit == U_EMS)	// if em spacing
			*_runindentptr = [control floatValue];// recover as unconverted value
		else	// set in points
			*_runindentptr = env_tobase(_currentunit,[control floatValue]);
	}
	else if (control == spacesize)
		*_linespaceptr = env_tobase(_unit,[control floatValue]);
	else if (control == mainheadspace)
		_fParams.pf.entryspace = [control intValue];
	else if (control == alphaspace)
		_fParams.pf.above = [control intValue];
	return YES;
}
@end

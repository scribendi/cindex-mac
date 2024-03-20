//
//  MarginColumnController.m
//  Cindex
//
//  Created by PL on 1/9/05.
//  Copyright 2005 Indexing Research. All rights reserved.
//

#import "units.h"
#import "index.h"
#import "MarginColumnController.h"
#import "IRIndexDocument.h"
#import "TextStyleController.h"

@interface MarginColumnController (PrivateMethods)

@end

@implementation MarginColumnController
- (id)init	{
    self = [super initWithWindowNibName:@"MarginColumnController"];
    return self;
}
- (void)awakeFromNib {
	[super awakeFromNib];
	int count;
	INDEXPARAMS	 * ip;
	
	if ([self document])	{
		INDEX * FF = [[self document] iIndex];
		
		_iParamPtr = &FF->head.formpars.pf.mc;
//		_unit = FF->head.privpars.eunit;
		ip = &FF->head.indexpars;
	}
	else	{
		_iParamPtr = &g_prefs.formpars.pf.mc;
		ip = &g_prefs.indexpars;
	}
	_iParams = *_iParamPtr;
	_unit = g_prefs.privpars.eunit;
	[columns selectItemAtIndex:_iParams.ncols-1];
	[facingpages setState:_iParams.reflect];
	[unit selectItemAtIndex:_unit];
	[self changeUnit:unit];
	[breakcontrol selectCellWithTag:_iParams.pgcont];
	[appendtext setStringValue:[NSString stringWithCString:_iParams.continued encoding:NSUTF8StringEncoding]];
	
	[level removeAllItems];
	for (count = 0; count < ip->maxfields-1; count++)	/* for all fields */
		[level addItemWithTitle:[NSString stringWithCString:ip->field[count].name encoding:NSUTF8StringEncoding]];
	[level selectItemAtIndex:_iParams.clevel];
}
- (IBAction)showHelp:(id)sender {
	[[NSHelpManager sharedHelpManager] openHelpAnchor:@"margcol0_Anchor-14210" inBook:@"Cindex 4.2.5 Help"];
}
- (IBAction)showTextStylePanel:(id)sender {
	[TextStyleController showForStyle:&_iParams.cstyle extraMode:0];
}
- (IBAction)closePanel:(id)sender {    
	if ([sender tag] == OKTAG)	{
	
		if (![[self window] makeFirstResponder:[self window]])	// if bad text somewhere
			return;
		_iParamPtr->top = env_tobase(_unit,[top floatValue]);
		_iParamPtr->left = env_tobase(_unit,[left floatValue]);
		_iParamPtr->bottom = env_tobase(_unit,[bottom floatValue]);
		_iParamPtr->right = env_tobase(_unit,[right floatValue]);
		_iParamPtr->gutter = env_tobase(_unit,[gutter floatValue]);
		_iParamPtr->ncols = [columns indexOfSelectedItem]+1;
		_iParamPtr->reflect = [facingpages state];
		_iParamPtr->pgcont = [[breakcontrol selectedCell] tag];
		strcpy(_iParamPtr->continued,(char *)[[appendtext stringValue] UTF8String]);
		_iParamPtr->clevel = [level indexOfSelectedItem];
		_iParamPtr->cstyle = _iParams.cstyle;
		index_markdirty([[self document] iIndex]);
		if ([self document])	{
			[[self document] configurePrintInfo];
			[[NSNotificationCenter defaultCenter] postNotificationName:NOTE_REVISEDLAYOUT object:[self document]];
		}
	}
	if (self.document)
		[self.window.sheetParent endSheet:self.window returnCode:[sender tag]];
	else {
		[self close];
		[NSApp stopModal]; 
	}
}
- (IBAction)changeUnit:(id)sender {
//	id responder = [[self window] firstResponder];
	
	if ([[self window] makeFirstResponder:[self window]])	{	// if get good test on active field
		_unit = [[unit selectedItem] tag];
		[top setFloatValue:env_toexpress(_unit,_iParams.top)];
		[left setFloatValue:env_toexpress(_unit,_iParams.left)];
		[bottom setFloatValue:env_toexpress(_unit,_iParams.bottom)];
		[right setFloatValue:env_toexpress(_unit,_iParams.right)];
		[gutter setFloatValue:env_toexpress(_unit,_iParams.gutter)];
//		[[self window] makeFirstResponder:responder];		// restore responder
	}
}   
- (void)controlTextDidChange:(NSNotification *)note	{
	NSControl * control = [note object];

	if (control == appendtext)
		checktextfield(control,FSSTRING);
}
- (BOOL)control:(NSControl *)control textShouldEndEditing:(NSText *)editor {
	if (control == top)
		_iParams.top = env_tobase(_unit,[control floatValue]);
	else if (control == left)
		_iParams.left = env_tobase(_unit,[control floatValue]);
	else if (control == bottom)
		_iParams.bottom = env_tobase(_unit,[control floatValue]);
	else if (control == right)
		_iParams.right = env_tobase(_unit,[control floatValue]);
	else if (control == gutter)
		_iParams.gutter = env_tobase(_unit,[control floatValue]);
	return YES;
}
@end

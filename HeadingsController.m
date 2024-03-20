//
//  HeadingsController.m
//  Cindex
//
//  Created by PL on 1/9/05.
//  Copyright 2005 Indexing Research. All rights reserved.
//

#import "IRIndexDocumentController.h"
#import "HeadingsController.h"
#import "IRIndexDocument.h"
#import "TextStyleController.h"
#import "type.h"
#import "index.h"

@interface HeadingsController (PrivateMethods)
- (void)_setField:(int)field;
- (void)_recoverField:(int)field;
@end


@implementation HeadingsController
- (id)init	{
    self = [super initWithWindowNibName:@"HeadingsController"];
    return self;
}
- (void)awakeFromNib {
	[super awakeFromNib];
	INDEXPARAMS * ip;
	int count;
	
	if ([self document])	{
		_hParamPtr = &[[self document] iIndex]->head.formpars.ef;
		ip = &[[self document] iIndex]->head.indexpars;
	}
	else {
		_hParamPtr = &g_prefs.formpars.ef;
		ip = &g_prefs.indexpars;
	}
	_hParams = *_hParamPtr;
	
	[heading removeAllItems];
	for (count = 0; count < ip->maxfields-1; count++)	/* for all fields */
		[heading addItemWithTitle:[NSString stringWithCString:ip->field[count].name encoding:NSUTF8StringEncoding]];
	[font addItemsWithTitles:[IRdc fonts]];
	[self _setField:0];
}
- (IBAction)showHelp:(id)sender {
	[[NSHelpManager sharedHelpManager] openHelpAnchor:@"headings0_Anchor-14210" inBook:@"Cindex 4.2.5 Help"];
}
- (IBAction)showForHeading:(id)sender {
	NSInteger index = [sender indexOfSelectedItem];
	
	[self _recoverField:_currentfield];
	[self _setField:index];
	_currentfield = index;
}
- (IBAction)showTextStylePanel:(id)sender {
	[TextStyleController showForStyle:&_hParams.field[_currentfield].style extraMode:FC_TITLE];
}
- (IBAction)closePanel:(id)sender {    
	if ([sender tag] == OKTAG)	{
		if (![[self window] makeFirstResponder:[self window]])	// if bad text somewhere
			return;
		[self _recoverField:_currentfield];
		*_hParamPtr = _hParams;
		if ([self document]) {
			INDEX * FF = [[self document] iIndex];
			int limit = FF->head.indexpars.maxfields-1;
			int field;
			
			for (field = 0; field < limit; field++)
				type_findlocal(FF->head.fm,_hParams.field[field].font,0);	// check/enter font in table
			index_markdirty([[self document] iIndex]);
			[[self document] reformat];
		}
	}
	if ([self document])
		[self.window.sheetParent endSheet:self.window returnCode:[sender tag]];
	else {
		[self close];
		[NSApp stopModal]; 
	}
}
- (void)_setField:(int)field {
	int sindex;
	
	if (*_hParams.field[field].font)	// if have named font
		[font selectItemWithTitle:[NSString stringWithCString:_hParams.field[field].font encoding:NSUTF8StringEncoding]];
	else
		[font selectItemAtIndex:0];
	[size setIntValue:_hParams.field[field].size];
	for (sindex = 0; sindex < field; sindex++)	{	// check suppression level
		if (_hParams.field[sindex].flags&FH_SUPPRESS)	// if earlier field suppressed
			break;
	}
	if (sindex < field)	{	// if earlier level suppressed
		[suppress setEnabled:NO];
		[suppress setState:YES];
	}
	else	{
		[suppress setEnabled:YES];
		[suppress setState:_hParams.field[field].flags&FH_SUPPRESS ? TRUE : FALSE];
	}
	[lead setStringValue:[NSString stringWithCString:_hParams.field[field].leadtext encoding:NSUTF8StringEncoding]];
	[trail setStringValue:[NSString stringWithCString:_hParams.field[field].trailtext encoding:NSUTF8StringEncoding]];
}
- (void)_recoverField:(int)field {
	if ([font indexOfSelectedItem] > 0)	// if not default font
		strcpy(_hParams.field[field].font,[[font titleOfSelectedItem] UTF8String]);	// fix for getting font name
	else if ([font indexOfSelectedItem] == 0)
		*_hParams.field[field].font = '\0';
		// could be < 0 (and we do nothing) if preferred font isn't available
	_hParams.field[field].size = [size intValue];
	_hParams.field[field].flags = 0;
	if ([suppress isEnabled] && [suppress state])
		_hParams.field[field].flags |= FH_SUPPRESS;
	strcpy(_hParams.field[field].leadtext,[[lead stringValue] UTF8String]);
	strcpy(_hParams.field[field].trailtext,[[trail stringValue] UTF8String]);
}
- (void)controlTextDidChange:(NSNotification *)note	{
	NSControl * control = [note object];

	if (control == lead)
		checktextfield(control,FMSTRING-4);
	if (control == trail)
		checktextfield(control,FMSTRING);
}
@end

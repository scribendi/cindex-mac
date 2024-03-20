//
//  GroupingController.m
//  Cindex
//
//  Created by PL on 1/9/05.
//  Copyright 2005 Indexing Research. All rights reserved.
//

#import "IRIndexDocumentController.h"
#import "GroupingController.h"
#import "IRIndexDocument.h"
#import "TextStyleController.h"
#import "type.h"
#import "index.h"


@implementation GroupingController
- (id)init	{
    self = [super initWithWindowNibName:@"GroupingController"];
    return self;
}
- (void)awakeFromNib {
	[super awakeFromNib];
	if ([self document])
		_gParamPtr = &[[self document] iIndex]->head.formpars.ef.eg;
	else 
		_gParamPtr = &g_prefs.formpars.ef.eg;
	_gParams = *_gParamPtr;
	
	[font addItemsWithTitles:[IRdc fonts]];
	if (*_gParams.gfont)
		[font selectItemWithTitle:[NSString stringWithUTF8String:_gParams.gfont]];
	else
		[font selectItemAtIndex:0];
	[combo setIntValue:_gParams.gsize];
	[text setStringValue:[NSString stringWithUTF8String:_gParams.title]];
	[numbers setStringValue:[NSString stringWithUTF8String:_gParams.ninsert]];
	[symbols setStringValue:[NSString stringWithUTF8String:_gParams.sinsert]];
	[numbersSymbols setStringValue:[NSString stringWithUTF8String:_gParams.nsinsert]];
	[symbolgrouping selectItemAtIndex:_gParams.method];
}
- (IBAction)showHelp:(id)sender {
	[[NSHelpManager sharedHelpManager] openHelpAnchor:@"groupentry0_Anchor-14210" inBook:@"Cindex 4.2.5 Help"];
}
- (IBAction)showTextStylePanel:(id)sender {
	[TextStyleController showForStyle:&_gParams.gstyle extraMode:0];
}
- (IBAction)closePanel:(id)sender {    
	if ([sender tag] == OKTAG)	{
		if (![[self window] makeFirstResponder:[self window]])	// if bad text somewhere
			return;
		strcpy(_gParams.title,[[text stringValue] UTF8String]);
		strcpy(_gParams.ninsert,[[numbers stringValue] UTF8String]);
		strcpy(_gParams.sinsert,[[symbols stringValue] UTF8String]);
		strcpy(_gParams.nsinsert,[[numbersSymbols stringValue] UTF8String]);
		if ([font indexOfSelectedItem] > 0)
			strcpy(_gParams.gfont,[[font titleOfSelectedItem] UTF8String]);
		else if ([font indexOfSelectedItem] == 0)
			*_gParams.gfont = 0;
		// could be < 0 (and we do nothing) if preferred font isn't available
		_gParams.gsize = [combo intValue];
		_gParams.method = [symbolgrouping indexOfSelectedItem];
		*_gParamPtr = _gParams;
		if ([self document])	{
			INDEX * FF = [[self document] iIndex];
			
			type_findlocal(FF->head.fm,_gParams.gfont,0);	// check/enter font in table
			[[self document] reformat];
		}
		index_markdirty([[self document] iIndex]);
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

	if (control == text || control == numbers || control == symbols || control == numbersSymbols)
		checktextfield(control,FSSTRING);
}
@end

//
//  CrossRefsController.m
//  Cindex
//
//  Created by PL on 1/9/05.
//  Copyright 2005 Indexing Research. All rights reserved.
//

#import "CrossRefsController.h"
#import "IRIndexDocument.h"
#import "TextStyleController.h"
#import "sort.h"
#import "collate.h"
#import "commandutils.h"
#import "index.h"

@implementation CrossRefsController
- (id)init	{
    self = [super initWithWindowNibName:@"CrossRefsController"];
    return self;
}
- (void)awakeFromNib {
	[super awakeFromNib];
	if ([self document])
		_cParamPtr = &[[self document] iIndex]->head.formpars.ef.cf;
	else
		_cParamPtr = &g_prefs.formpars.ef.cf;
	_cParams = *_cParamPtr;
//	_cParams.leadstyle.allowauto = TRUE;	// allow auto format for lead
	// heading
	[mseeprefix setStringValue:[NSString stringWithCString:_cParams.level[0].cleadb encoding:NSUTF8StringEncoding]];
	[mseesuffix setStringValue:[NSString stringWithCString:_cParams.level[0].cendb encoding:NSUTF8StringEncoding]];
	[mseealsoprefix setStringValue:[NSString stringWithCString:_cParams.level[0].cleada encoding:NSUTF8StringEncoding]];
	[mseealsosuffix setStringValue:[NSString stringWithCString:_cParams.level[0].cenda encoding:NSUTF8StringEncoding]];
	[mseeposition selectItemAtIndex:_cParams.mainseeposition];
	[mseealsoposition selectItemAtIndex:_cParams.mainposition];
	// subheading
	[sseeprefix setStringValue:[NSString stringWithCString:_cParams.level[1].cleadb encoding:NSUTF8StringEncoding]];
	[sseesuffix setStringValue:[NSString stringWithCString:_cParams.level[1].cendb encoding:NSUTF8StringEncoding]];
	[sseealsoprefix setStringValue:[NSString stringWithCString:_cParams.level[1].cleada encoding:NSUTF8StringEncoding]];
	[sseealsosuffix setStringValue:[NSString stringWithCString:_cParams.level[1].cenda encoding:NSUTF8StringEncoding]];
	[sseeposition selectItemAtIndex:_cParams.subseeposition];
	[sseealsoposition selectItemAtIndex:_cParams.subposition];
	
	[alphabetical setState:_cParams.sortcross];
	[suppressall setState:_cParams.suppressall];
	[prefixstylecheck setState:_cParams.suppressifbodystyle];
}
- (IBAction)showHelp:(id)sender {
	[[NSHelpManager sharedHelpManager] openHelpAnchor:@"crossform0_Anchor-14210" inBook:@"Cindex 4.2.5 Help"];
}
- (IBAction)showTextStylePanel:(id)sender {
	if (prefixstyle == sender)
		[TextStyleController showForStyle:&_cParams.leadstyle extraMode:FC_AUTO];
	else
		[TextStyleController showForStyle:&_cParams.bodystyle extraMode:FC_TITLE];
}
- (IBAction)closePanel:(id)sender {
	BOOL needsresort = NO;
	if ([sender tag] == OKTAG)	{
		if (![[self window] makeFirstResponder:[self window]])	// if bad text somewhere
			return;
		// heading
		strcpy(_cParams.level[0].cleadb,[[mseeprefix stringValue] UTF8String]);
		strcpy(_cParams.level[0].cendb,[[mseesuffix stringValue] UTF8String]);
		strcpy(_cParams.level[0].cleada,[[mseealsoprefix stringValue] UTF8String]);
		strcpy(_cParams.level[0].cenda,[[mseealsosuffix stringValue] UTF8String]);
		_cParams.mainseeposition = [mseeposition indexOfSelectedItem];
		_cParams.mainposition = [mseealsoposition indexOfSelectedItem];
		
		// subhead
		strcpy(_cParams.level[1].cleadb,[[sseeprefix stringValue] UTF8String]);
		strcpy(_cParams.level[1].cendb,[[sseesuffix stringValue] UTF8String]);
		strcpy(_cParams.level[1].cleada,[[sseealsoprefix stringValue] UTF8String]);
		strcpy(_cParams.level[1].cenda,[[sseealsosuffix stringValue] UTF8String]);
		_cParams.subseeposition = [sseeposition indexOfSelectedItem];
		_cParams.subposition = [sseealsoposition indexOfSelectedItem];
		
		_cParams.sortcross = [alphabetical state];
		_cParams.suppressall = [suppressall state];
		_cParams.suppressifbodystyle = [prefixstylecheck state];
		needsresort = _cParams.mainposition <= CP_FIRSTSUB && _cParamPtr->mainposition >= CP_LASTSUB
					|| _cParams.mainposition >= CP_LASTSUB && _cParamPtr->mainposition <= CP_FIRSTSUB
					|| _cParams.subposition <= CP_FIRSTSUB && _cParamPtr->subposition >= CP_LASTSUB
					|| _cParams.subposition >= CP_LASTSUB && _cParamPtr->subposition <= CP_FIRSTSUB;
		*_cParamPtr = _cParams;
		index_markdirty([[self document] iIndex]);
	}
	if ([self document])	{
		if (needsresort) {
			INDEX * FF = [[self document] iIndex];
			col_init(&FF->head.sortpars,FF);		// initialize collator
			sort_resort(FF);		/* sort whole index anyway */
			if (FF->curfile)
				sort_sortgroup(FF);
		}
		[[self document] reformat];
		[self.window.sheetParent endSheet:self.window returnCode:[sender tag]];
	}
	else {
		[self close];
		[NSApp stopModal]; 
	}
}
#if 0
- (BOOL)control:(NSControl *)control textShouldEndEditing:(NSText *)editor {
	if (control == mseeprefix || control == mseesuffix || control == mseealsoprefix || control == mseealsosuffix ||
		control == sseeprefix || control == sseesuffix || control == sseealsoprefix || control == sseealsosuffix)
		return [[control stringValue] length] < FMSTRING;
	return YES;
}
#endif
- (void)controlTextDidChange:(NSNotification *)note	{
	NSControl * control = [note object];
	if (control == mseeprefix || control == mseesuffix || control == mseealsoprefix || control == mseealsosuffix ||
		control == sseeprefix || control == sseesuffix || control == sseealsoprefix || control == sseealsosuffix)
		checktextfield(control,FMSTRING);
}
@end

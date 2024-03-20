//
//  RefSyntaxController.m
//  Cindex
//
//  Created by PL on 1/9/05.
//  Copyright 2005 Indexing Research All rights reserved.
//

#import "index.h"
#import "RefSyntaxController.h"
#import "IRIndexDocument.h"

@implementation RefSyntaxController
- (id)init	{
    self = [super initWithWindowNibName:@"RefSyntaxController"];
    return self;
}
- (void)awakeFromNib {
	[super awakeFromNib];
	if ([self document])
		_lParamPtr = &[[self document] iIndex]->head.refpars;
	else
		_lParamPtr = &g_prefs.refpars;
	_lParam = *_lParamPtr;
	[clead setStringValue:[NSString stringWithCString:_lParam.crosstart encoding:NSUTF8StringEncoding]];
	[cgeneral setStringValue:[NSString stringWithCString:_lParam.crossexclude encoding:NSUTF8StringEncoding]];
//	[cseparator setStringValue:[NSString stringWithCString:&_lParam.csep encoding:NSUTF8StringEncoding]];
	[cseparator setStringValue:[NSString stringWithFormat:@"%c",_lParam.csep]];
	[locatoronly setState:_lParam.clocatoronly];
//	[plead setStringValue:[NSString stringWithCString:&_lParam.psep encoding:NSUTF8StringEncoding]];
	[plead setStringValue:[NSString stringWithFormat:@"%c",_lParam.psep]];
//	[pconnect setStringValue:[NSString stringWithCString:&_lParam.rsep encoding:NSUTF8StringEncoding]];
	[pconnect setStringValue:[NSString stringWithFormat:@"%c",_lParam.rsep]];
	[pmax setStringValue:[NSString stringWithCString:_lParam.maxvalue encoding:NSUTF8StringEncoding]];
	[prange setIntValue:_lParam.maxspan];
}	
- (IBAction)showHelp:(id)sender {
	[[NSHelpManager sharedHelpManager] openHelpAnchor:@"refsyntax0_Anchor-14210" inBook:@"Cindex 4.2.5 Help"];
}
- (IBAction)closePanel:(id)sender {    
	if ([sender tag] == OKTAG)	{
		if (![[self window] makeFirstResponder:[self window]])	// if a bad field
			return;
		strcpy(_lParamPtr->crosstart,[[clead stringValue] UTF8String]);
		strcpy(_lParamPtr->crossexclude,[[cgeneral stringValue] UTF8String]);
		_lParamPtr->csep = *[[cseparator stringValue] UTF8String];
		_lParamPtr->clocatoronly = [locatoronly state];
		_lParamPtr->psep = *[[plead stringValue] UTF8String];
		_lParamPtr->rsep = *[[pconnect stringValue] UTF8String];
		strcpy(_lParamPtr->maxvalue,[[pmax stringValue] UTF8String]);
		_lParamPtr->maxspan = [prange intValue];
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

	if (control == cseparator || control == plead || control == pconnect) {
//		if ([ustring length] > 1)
//			[control setStringValue:[ustring substringToIndex:1]];
		checktextfield(control,2);
	}
	else if (control == clead) {
		checktextfield(control,STSTRING);
	}
	else if (control == cgeneral || control == pmax) {
		checktextfield(control,FTSTRING);
	}
}
@end

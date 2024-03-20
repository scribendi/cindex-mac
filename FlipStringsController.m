//
//  FlipStringsController.m
//  Cindex
//
//  Created by Peter Lennie on 7/5/11.
//  Copyright 2011 Indexing Research. All rights reserved.
//

#import "FlipStringsController.h"
#import "IRIndexDocument.h"
#import "index.h"

@implementation FlipStringsController

- (id)init	{
    self = [super initWithWindowNibName:@"FlipStringsController"];
    return self;
}
- (void)awakeFromNib {
	[super awakeFromNib];
	if ([self document])
		_stringPtr = [[self document] iIndex]->head.flipwords;
	else
		_stringPtr = g_prefs.flipwords;
	[flipStrings setStringValue:[NSString stringWithUTF8String:_stringPtr]];
}
- (IBAction)showHelp:(id)sender {
	[[NSHelpManager sharedHelpManager] openHelpAnchor:@"flipwords0_Anchor-14210" inBook:@"Cindex 4.2.5 Help"];
}
- (IBAction)closePanel:(id)sender {    
	if ([sender tag] == OKTAG)	{
		if (![[self window] makeFirstResponder:[self window]])	// if bad text somewhere
			return;
		strcpy(_stringPtr,[[flipStrings stringValue] UTF8String]);
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
	
	if (control == flipStrings)
		checktextfield(control,STSTRING);
}
@end

//
//  AlterRefsController.m
//  Cindex
//
//  Created by PL on 1/9/05.
//  Copyright 2005 Indexing Research. All rights reserved.
//

#import "AlterRefsController.h"
#import "IRIndexDocument.h"
#import "refs.h"
#import "regex.h"
#import "commandutils.h"

@implementation AlterRefsController
- (void)awakeFromNib {
	[super awakeFromNib];
	FF = [[self document] iIndex];
	[self removeAction:action];
}
- (IBAction)showHelp:(id)sender {
	[[NSHelpManager sharedHelpManager] openHelpAnchor:@"alter0_Anchor-14210" inBook:@"Cindex 4.2.5 Help"];
}
- (IBAction)removeAction:(id)sender {
	if (![[sender selectedCell] tag])	{	// if adjustment only
		[holdvalues setState:NO];
		[holdvalues setEnabled:NO];
	}
	else
		[holdvalues setEnabled:YES];
}
- (IBAction)closeSheet:(id)sender {    
	if ([sender tag] == OKTAG)	{
		struct adjstruct aparams;
		char * sptr = (char *)[[match stringValue] UTF8String];
//		int ecount;
		
		memset(&aparams, 0, sizeof(struct adjstruct));
		if (*sptr)	{	// if have pattern text
			if (!(aparams.regex = regex_build(sptr,0)))	{	/* if bad expression */
				errorSheet(self.window,BADEXPERR,WARN,sptr);
				[[self window] makeFirstResponder:match];
				return;
			}
			aparams.patflag = TRUE;
		}
		aparams.cut = [[action cellWithTag:1] state];
		aparams.hold = [holdvalues state];
		aparams.low = [rangestart intValue];
		aparams.high = [rangeend intValue];
		if (!aparams.low)
			aparams.low = 1;
		if (!aparams.high)
			aparams.high = INT_MAX;
		if (aparams.low > aparams.high)	{
			errorSheet(self.window,REFORDERERR,WARN);
			[[self window] makeFirstResponder:rangestart];
			return;
		}
		aparams.shift = [adjustment intValue];
		if (aparams.low+aparams.shift < 1)	{	/* if would potentially remove refs */
			NSAlert * warning = criticalAlert(NEGADJUSTWARNING, aparams.low, -aparams.shift);
			[warning beginSheetModalForWindow:[self.document windowForSheet] completionHandler:^(NSInteger result) {
				if (result == NSAlertFirstButtonReturn){
					[self doAlter:&aparams];
					[self.window.sheetParent endSheet:self.window returnCode:[sender tag]];
				}
			}];
		}
		else {
			[self doAlter:&aparams];
			[self.window.sheetParent endSheet:self.window returnCode:[sender tag]];
		}
	}
	else
		[self.window.sheetParent endSheet:self.window returnCode:[sender tag]];
}
- (void)doAlter:(struct adjstruct *)params {
	int ecount;
	[[NSNotificationCenter defaultCenter] postNotificationName:NOTE_GLOBALLYCHANGING object:[self document]];
	if (ecount = ref_adjust(FF,params))	// if marked records
		senderr(RECMARKERR,WARN, ecount);  // warn
	if (params->regex)
		uregex_close(params->regex);
	[[self document] redisplay:0 mode:VD_CUR];

}
@end

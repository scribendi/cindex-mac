//
//  SplitController.m
//  Cindex
//
//  Created by PL on 4/12/18.
//  Copyright 2018 Indexing Research. All rights reserved.
//

#import "indexdocument.h"
#import "SplitController.h"
#import "IRIndexTextWController.h"
#import "tools.h"
#import "commandutils.h"
#import "strings_c.h"
#import "records.h"
#import "regex.h"

static int tabset[] = {-40,48,125,160,0};

@interface SplitController  () {
	IBOutlet NSPopUpButton * pattern;
	IBOutlet NSButton * removeStyles;
	IBOutlet NSButton * cleanHeadings;
	IBOutlet NSButton * markMissing;
	IBOutlet NSButton * showPreview;
	IBOutlet NSTextField * userPattern;
	IBOutlet NSBox * box;

	INDEX * FF;
	SPLITPARAMS params;
}
@end
@implementation SplitController

- (void)awakeFromNib {
	[super awakeFromNib];
	FF = [[self document] iIndex];
	NSData * sd = [[NSUserDefaults standardUserDefaults] objectForKey:@"splitParams"];
	if (sd && sd.length == sizeof(SPLITPARAMS))	// set defaults if they're good
		params = *(SPLITPARAMS *)sd.bytes;
	[pattern selectItemWithTag:params.patternindex];
	removeStyles.state = params.removestyles;
	markMissing.state = params.markmissing;
	userPattern.stringValue = [NSString stringWithUTF8String:params.userpattern];
}
- (IBAction)showHelp:(id)sender {
	[[NSHelpManager sharedHelpManager] openHelpAnchor:@"split0_Anchor-14210" inBook:@"Cindex 4.2.5 Help"];
}
- (void)windowDidUpdate:(NSNotification *)aNotification {
	if (pattern.selectedTag < 0) {
		if (!userPattern.enabled) {
			userPattern.enabled = YES;
			[[self window] makeFirstResponder:userPattern];
		}
	}
	else {
		userPattern.enabled = NO;
	}
}
-(void)getParams {
	[[self document] closeText];
	memset(&params,0,sizeof(SPLITPARAMS));
//	params.cleanoriginal = cleanHeadings.state;
	params.cleanoriginal = YES;
	params.removestyles = removeStyles.state;
	params.patternindex = (int)pattern.selectedTag;
	strncpy(params.userpattern,[userPattern.stringValue UTF8String],SPLITPATTERNLEN-1);
	params.markmissing = markMissing.state;
	[[NSUserDefaults standardUserDefaults] setObject:[NSData dataWithBytes:&params length:sizeof(SPLITPARAMS)] forKey:@"splitParams"];
}
- (IBAction)changePattern:(id)sender {
//	if (pattern.indexOfSelectedItem != pattern.itemArray.count-1)
//		userPattern.stringValue = @"";
}
- (IBAction)showPreview:(id)sender {
	if ([[self window] makeFirstResponder:nil]) {
		[self getParams];
		params.preflight = YES;
		params.reportlist = calloc(FF->head.rtot+1,sizeof(char *));		// memory for pointer array
		tool_explode(FF,&params);
		if (params.reportlist[0]) {	// if have anything to report
			NSMutableAttributedString * splitlist = [[NSMutableAttributedString alloc] init];
			for (RECN rindex = 0; params.reportlist[rindex]; rindex++) {
				[splitlist appendAttributedString:[NSAttributedString asFromXString:params.reportlist[rindex] fontMap:NULL size:0 termchar:0]];
				free(params.reportlist[rindex]);
			}
			[splitlist setTabs:tabset headIndent:60];
			[[self document] showText:splitlist title:@"Split Preview"];
		}
		free(params.reportlist);
		[self.window.sheetParent endSheet:self.window returnCode:[sender tag]];
	}
}
- (IBAction)closeSheet:(id)sender {    
	if ([sender tag] == OKTAG)	{
		if ([[self window] makeFirstResponder:nil]) {
			NSAlert * warning = criticalAlert(SPLITWARNING);
			[warning beginSheetModalForWindow:[self.document windowForSheet] completionHandler:^(NSInteger result) {
				if (result == NSAlertFirstButtonReturn){
					[self getParams];
					tool_explode(self->FF,&self->params);
					[[self document] redisplay:0 mode:0];	// redisplay all records
					infoSheet(((IRIndexDocument *)self.document).windowForSheet, SPLITRECINFO, self->params.gencount, self->params.modcount, self->params.markcount);
				}
			}];
		}
		else
			return;
	}
	[self.window.sheetParent endSheet:self.window returnCode:[sender tag]];
}
- (void)controlTextDidChange:(NSNotification *)note	{
//	NSControl * control = [note object];

}
- (BOOL)control:(NSControl *)control textShouldEndEditing:(NSText *)editor {
	if (control == userPattern)
		return regex_validexpression([[control stringValue] UTF8String],0);
	return YES;
}
@end

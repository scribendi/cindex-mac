//
//  GenerateRefsController.m
//  Cindex
//
//  Created by PL on 1/9/05.
//  Copyright 2005 Indexing Research. All rights reserved.
//

#import "IRIndexDocumentController.h"
#import "IRIndexDocWController.h"
#import "IRIndexDocument.h"
#import "GenerateRefsController.h"
#import "commandutils.h"
#import "cindexmenuitems.h"
#import "search.h"

@implementation GenerateRefsController
- (void)awakeFromNib {
	[super awakeFromNib];
	FF = [[self document] iIndex];
}
- (IBAction)showHelp:(id)sender {
	[[NSHelpManager sharedHelpManager] openHelpAnchor:@"crossmanage0_Anchor-14210" inBook:@"Cindex 4.2.5 Help"];
}
- (IBAction)doSetAction:(id)sender {
	if ([sender selectedRow] == 1)	{
		[_targetcount setEnabled:YES];
		[[self window] makeFirstResponder:_targetcount];
	}
	else
		[_targetcount setEnabled:NO];
}
- (IBAction)closeSheet:(id)sender {    
	[self.window.sheetParent endSheet:self.window returnCode:[sender tag]];
	if ([sender tag] == OKTAG)	{
		[[NSNotificationCenter defaultCenter] postNotificationName:NOTE_GLOBALLYCHANGING object:[self document]];
		if ([[_mode selectedCell] tag] == 0)	{	// if generate from file
			NSOpenPanel *openpanel = [NSOpenPanel openPanel];
			NSString * defaultDirectory = [[NSUserDefaults standardUserDefaults] stringForKey:CIIndexFolder];
			
			if (defaultDirectory)
				[openpanel setDirectoryURL:[NSURL fileURLWithPath:defaultDirectory isDirectory:YES]];
			[openpanel setAllowedFileTypes:[NSArray arrayWithObject:CINIndexExtension]];
			[openpanel setAccessoryView:_accessory];
			[openpanel beginSheetModalForWindow:IRdc.currentDocument.windowForSheet completionHandler:^(NSModalResponse result)  {
				if (result == NSFileHandlingPanelOKButton) {
					NSURL * url = [[openpanel URLs] objectAtIndex:0];
					[IRdc openDocumentWithContentsOfURL:url display:NO completionHandler:^(NSDocument *gendoc, BOOL alreadyOpen, NSError *error){
						if (gendoc)	{	// if have document as source
							RECN reccount;
							AUTOGENERATE ag;
							
							memset(&ag,0,sizeof(AUTOGENERATE));
							ag.seeonly = [[self->_accessory viewWithTag:0] state];
							reccount = search_autogen(self->FF,[(IRIndexDocument *)gendoc iIndex], &ag);		// generate refs
							if (!alreadyOpen)		/* if cref index wasn't already open */
								[[[(IRIndexDocument *)gendoc mainWindowController] window] performClose:self];
							if (reccount)	{		/* if generated any records */
								if (ag.skipcount)
									sendinfo(RECGENSKIPINFO,reccount,ag.skipcount,ag.maxneed);
								else
									sendinfo(RECGENNUMINFO,reccount);
								[[self document] setViewType:VIEW_ALL name:nil];
							}
							else
								sendinfo(NONGENNUMINFO);
						}
					}];
				}
			}];
		}
		else {	// convert
			RECN reccount = search_convertcross(FF,[_targetcount intValue]);
			
			if (reccount)	{
				sendinfo(INFO_RECCONVERT,reccount);
				[[self document] setViewType:VIEW_ALL name:nil];
			}
			else
				sendinfo(INFO_NORECCONVERT);
		}
	}
}
@end

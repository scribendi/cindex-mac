//
//  ReconcileController.m
//  Cindex
//
//  Created by PL on 1/9/05.
//  Copyright 2005 Indexing Research. All rights reserved.
//

#import "ReconcileController.h"
#import "IRIndexTextWController.h"
#import "AttributedStringCategories.h"
#import "tools.h"
#import "commandutils.h"
#import "strings_c.h"
#import "records.h"

//static int tabset[] = {-40,48,100,0};

@implementation ReconcileController
- (void)awakeFromNib {
	[super awakeFromNib];
	FF = [[self document] iIndex];
	int count;

	[headings removeAllItems];
	for (count = 0; count < FF->head.indexpars.maxfields-1; count++)	/* for all fields */
		[headings addItemWithTitle:[NSString stringWithCString:FF->head.indexpars.field[count].name encoding:NSUTF8StringEncoding]];
	[phrasechar setStringValue:@","];
	if (!sort_isinfieldorder(FF->head.sortpars.fieldorder,FF->head.indexpars.maxfields))	/* if isn't straight field order */
		[preservemodified setEnabled:NO];	// disable splitting
	[protectnames setState:YES];
}
- (IBAction)showHelp:(id)sender {
	[[NSHelpManager sharedHelpManager] openHelpAnchor:@"reconcile0_Anchor-14210" inBook:@"Cindex 4.2.5 Help"];
}
- (void)windowDidUpdate:(NSNotification *)aNotification {
//	if ([[mode selectedCell] tag])	{	// if want reconciliation
		[phrasechar setEnabled:YES];
		[preservemodified setEnabled:YES];
		[protectnames setEnabled:YES];
		[handleorphans setEnabled:YES];
//	}
//	else {
//		[phrasechar setEnabled:NO];
//		[preservemodified setEnabled:NO];
//		[protectnames setEnabled:NO];
//		[handleorphans setEnabled:NO];
//	}
}
- (IBAction)closeSheet:(id)sender {    
	if ([sender tag] == OKTAG)	{
		JOINPARAMS tjn;
		RECN markcount;
		
		if (![[self window] makeFirstResponder:[self window]])	// if a bad field
			return;
		memset(&tjn,0,sizeof(tjn));
		tjn.firstfield = [headings indexOfSelectedItem];
//		tjn.showorphans = [[mode selectedCell] tag] == 0;	// if want orphan list
//		if (tjn.showorphans)	{
//			tjn.orphanaction = OR_PRESERVE;
//			tjn.nosplit = TRUE;
//		}
//		else	{
			tjn.protectnames = [protectnames state];
			tjn.orphanaction = [[handleorphans selectedCell] tag];
			tjn.nosplit = [preservemodified state];
			[[NSNotificationCenter defaultCenter] postNotificationName:NOTE_GLOBALLYCHANGING object:[self document]];
//		}
		tjn.jchar = *[[phrasechar stringValue] UTF8String];
//		tjn.orphans = calloc(FF->head.rtot+1,sizeof(RECN));
//		tjn.orphans = malloc(ORPHANARRAYBLOCK*sizeof(int));
		tjn.orphancount = 0;
		if (markcount = tool_join(FF, &tjn))
			senderr(RECMARKERR,WARN, markcount);
#if 0
		if (tjn.showorphans) {
			NSMutableAttributedString * orphanlist = [[NSMutableAttributedString alloc] init];
			int index;
			
			for (index = 0; index < tjn.orphancount; index++)	{
				RECORD * curptr = rec_getrec(FF,tjn.orphans[index]);	// get record
				if (curptr) {
					char string[MAXREC];
					int fcount = str_xcount(curptr->rtext);
					sprintf(string,"\t%u\tOrphan\t%s... %s\r",curptr->num,curptr->rtext,str_xatindex(curptr->rtext,fcount-2));
					[orphanlist appendAttributedString:[NSAttributedString asFromXString:string fontMap:NULL size:0 termchar:0]];
				}
			}
			if (index)	{	// if have orphans to show
				[orphanlist setTabs:tabset headIndent:60];
				[[self document] showText:orphanlist title:@"Orphaned Subheadings"];
			}
			else {
				[(IRIndexTextWController *)[[self document] textWindowController] close];
				sendinfo(INFO_NOORPHANS);
			}
		}
		else {	// some kind of join action
			[[self document] redisplay:0 mode:0];	// redisplay all records
		}
		free(tjn.orphans);
#endif
		[[self document] redisplay:0 mode:0];	// redisplay all records
	}
	[self.window.sheetParent endSheet:self.window returnCode:[sender tag]];
}
- (void)controlTextDidChange:(NSNotification *)note	{
	NSControl * control = [note object];

	checktextfield(control,2);
	if (!ispunct(*[[control stringValue] UTF8String]))
		[control setStringValue:@""];
}
@end

//
//  StatisticsController.m
//  Cindex
//
//  Created by PL on 1/9/05.
//  Copyright 2005 Indexing Research All rights reserved.
//

#import "StatisticsController.h"
#import "IRIndexDocument.h"
#import "commandutils.h"

enum {
	CALLREC = 0,
	CSELECTREC,
	CRANGEREC,
	CRANGEPAGE
};
@interface StatisticsController (PrivateMethods)
- (void)_showPage:(NSNotification *)note;
- (void)_displayBase;
@end

@implementation StatisticsController
- (void)awakeFromNib {
	[super awakeFromNib];
	FF = [[self document] iIndex];
	if (![FF->owner selectedRecords].location)		// if no records selected
		[[scope cellWithTag:CSELECTREC] setEnabled:NO];
	[self _displayBase];
	[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(_showPage:) name:NOTE_PAGEFORMATTED object:[self document]];
	[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(updateProgress:) name:NOTE_PROGRESSCHANGED object:nil];
}
- (void)dealloc {
	[[NSNotificationCenter defaultCenter] removeObserver:self];
}
- (void)updateProgress:(NSNotification *)note {
	indicator.doubleValue = [[note object] doubleValue];
}
- (void)_showPage:(NSNotification *)note {
	[pagecount setStringValue:[NSString stringWithFormat:@"Page %@",[[note userInfo] objectForKey:@"Page"]]];
	[pagecount display];
}
- (IBAction)showHelp:(id)sender {
	[[NSHelpManager sharedHelpManager] openHelpAnchor:@"statistics0_Anchor-14210" inBook:@"Cindex 4.2.5 Help"];
}
- (void)_displayBase {
	char *bptr;
	long tottime;

	bptr = _buffer;
#if 0
	strftime(tbuff, 100, "%b %d %Y %H:%M", localtime(&FF->head.createtime));
	bptr += sprintf(bptr, "Created: %s\r",tbuff);
#else
	bptr += sprintf(bptr,"Created: %s\r",[[NSString stringFromCinTime:FF->head.createtime] UTF8String]);
#endif
	
	bptr += sprintf(bptr, "Modified: %s\r",[[((IRIndexDocument *)self.document).modtime descriptionWithCalendarFormat:@"%b %d %Y %H:%M" timeZone:nil locale:nil] UTF8String]);
	tottime = FF->head.elapsed + time(NULL)-FF->lastflush;	 /* make total time */
	bptr += sprintf(bptr, "Open for: %ldhrs %ldmin\r",tottime/3600, (tottime%3600)/60);
//	bptr += sprintf(bptr, "Record size: %d characters\r",FF->head.indexpars.recsize);
	_statsbase = bptr;
	[display setString:[NSString stringWithCString:_buffer encoding:NSUTF8StringEncoding]];
}
- (IBAction)closeSheet:(id)sender {    
	if ([sender tag] == OKTAG)	{
		NSInteger sscope = [[scope selectedCell] tag];
		char *bptr;
		int err;

		memset(&FF->pf,0,sizeof(PRINTFORMAT));
		FF->singlerefcount = FALSE;		// page range to count as 2 refs
		FF->pf.first = 1;
		FF->pf.last = INT_MAX;
		if (sscope == COMR_PAGE) {
			FF->pf.first = [pagestart intValue];
			FF->pf.last = [pageend intValue];
			if (FF->pf.first > FF->pf.last)	{
				errorSheet(self.window,INVALPAGERANGE,WARN);
				[[self window] makeFirstResponder:pageend];
				return;
			}
			sscope = COMR_ALL;		/* set scope to all records */
		}
		if (err = com_getrecrange(FF,sscope, rangestart,rangeend,&FF->pf.firstrec, &FF->pf.lastrec))	{	/* bad range */
			[[self window] makeFirstResponder: err < 0 ? rangestart : rangeend];
			return;
		}
		FF->pf.pagenum = FF->pf.firstrec ? 1 : FF->head.formpars.pf.firstpage;	/* number pages from 1 if records */
		[self _displayBase];	// refresh base display
		bptr = _statsbase;	// for appending text to buffer
		[done setTitle:@"Cancel"];
		if ([[self document] formPageImages])	{	// if not cancelled
			showprogress(0);
			[done setTitle:@"Done"];
			[pagecount setStringValue:@""];
			bptr += sprintf(bptr, "%d Pages, %d Lines, %d Characters.", FF->pf.pageout, FF->pf.lines, FF->pf.characters);
			bptr += sprintf(bptr, "\r%u entries, %u Unique main headings.", FF->pf.entries, FF->pf.uniquemain);
			if (FF->head.privpars.vmode == VM_FULL)	/* if doing formatted */
				sprintf(bptr,"\r%u Page references, %u Cross-references.",FF->pf.prefs,FF->pf.crefs);
			[display setString:[NSString stringWithUTF8String:_buffer]];
			return;
		}
	}
	[self.window.sheetParent endSheet:self.window returnCode:[sender tag]];
}
- (void)controlTextDidChange:(NSNotification *)note	{
	if ([note object] == rangestart || [note object] == rangeend)	// if record range
		[scope selectCellWithTag:COMR_RANGE];
	if ([note object] == pagestart || [note object] == pageend)		// if page range
		[scope selectCellWithTag:COMR_PAGE];
}
@end

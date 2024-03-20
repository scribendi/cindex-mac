//
//  CountController.m
//  Cindex
//
//  Created by PL on 1/9/05.
//  Copyright 2005 Indexing Research. All rights reserved.
//

#import "CountController.h"
#import "refs.h"
#import "commandutils.h"
#import "search.h"
#import "sort.h"
#import "records.h"

enum {
	CALLREC = 0,
	CSELECTREC,
	CRANGEREC,
};

@implementation CountController
- (void)awakeFromNib {
	[super awakeFromNib];
	FF = [[self document] iIndex];
	if (![FF->owner selectedRecords].length)		// if no records selected
		[[scope cellWithTag:CSELECTREC] setEnabled:NO];
}
- (IBAction)showHelp:(id)sender {
	[[NSHelpManager sharedHelpManager] openHelpAnchor:@"count0_Anchor-14210" inBook:@"Cindex 4.2.5 Help"];
}
- (IBAction)closeSheet:(id)sender {    
	if ([sender tag] == OKTAG)	{
		NSMutableString * leadstring = [NSMutableString stringWithCapacity:200];
		NSInteger rscope = [[scope selectedCell] tag];
		int err;
		RECN total;
		char buffer[2048];
		char *bptr = buffer;
		
		memset(&_cParams,0,sizeof(_cParams));		// clear before each scan
		strcpy(_cParams.firstref,[[locatorstart stringValue] UTF8String]);
		strcpy(_cParams.lastref,[[locatorend stringValue] UTF8String]);
		_cParams.modflag = [[among cellWithTag:0] state];
		_cParams.delflag = [[among cellWithTag:1] state] ? CO_ONLYDEL : COMR_ALL;
		_cParams.markflag = [[among cellWithTag:2] state];
		_cParams.genflag = [[among cellWithTag:3] state];
		_cParams.tagflag = [[among cellWithTag:4] state];
		if (*_cParams.lastref && !*_cParams.firstref || ref_match(FF,_cParams.firstref, _cParams.lastref, FF->head.sortpars.partorder, PMEXACT|PMSENSE) > 0)	{
			errorSheet(self.window, *_cParams.firstref ? INVALPAGERANGE : INVALLOCATORRANGE,WARN);
			[[self window] makeFirstResponder: *_cParams.firstref ? locatorend : locatorstart];
			return;
		}
		_cParams.smode = FF->head.sortpars.ison;	// always counte sorted so that we get accented characters grouped/counted correctly
		if (rscope == COMR_ALL && !FF->curfile)	{	// if want all records, and no active group
//			_cParams.smode = FALSE;
			_cParams.firstrec = rec_number(sort_top(FF));
			_cParams.lastrec = UINT_MAX;
		}
		else {
//			_cParams.smode = FF->head.sortpars.ison;
			if (err = com_getrecrange(FF,rscope, rangestart, rangeend,&_cParams.firstrec, &_cParams.lastrec))	{
				[[self window] makeFirstResponder: err < 0 ? rangestart : rangeend];
				return;
			}
		}
		total = search_count(FF,&_cParams,SF_VIEWDEFAULT);	// get count
		bptr += sprintf(bptr,"%u records: ",total);
		if (total)		{	/* if have any records */
			char *e1ptr, *e2ptr;
			long ref1 = strtol(_cParams.firstref,&e1ptr,10);
			long ref2 = strtol(_cParams.lastref,&e2ptr,10);
			int i, colcount;
			
			if (!*e1ptr && !*e2ptr && ref1 && ref2)	/* if decent arabic range */
				bptr += sprintf(bptr," (%01.1f per page)", (float)total/(ref2+1-ref1));
			bptr += sprintf(bptr,"\rModified: %u; Deleted: %u; Marked: %u; Generated: %u; Labeled: [%u %u %u %u %u %u %u]",
				_cParams.modified, _cParams.deleted, _cParams.marked, _cParams.generated,
				_cParams.labeled[1],_cParams.labeled[2],_cParams.labeled[3],_cParams.labeled[4],_cParams.labeled[5],_cParams.labeled[6],_cParams.labeled[7]);
			sprintf(bptr,"\rDeepest: %u levels (#%u); Longest: %u chars (#%u)\r",
				_cParams.deepest-1, _cParams.deeprec, _cParams.longest, _cParams.longrec);		 /* print number */
			for (i = colcount = 0; _cParams.leads[i].total && i < COUNTTABSIZE; i++) {		// for all the leads we have
				[leadstring appendFormat:@"%C%6u\t", _cParams.leads[i].lead,_cParams.leads[i].total];
				colcount++;
				if (!(colcount %= 7))	/* if at end of line */
					[leadstring appendString:@"\n"];
			}
//			*bptr = '\0';
		}
		[countview setString:[NSString stringWithFormat:@"%@%@",[NSString stringWithUTF8String:buffer],leadstring]];
		return;
	}
	[self.window.sheetParent endSheet:self.window returnCode:[sender tag]];
}
- (void)controlTextDidChange:(NSNotification *)note	{
	if ([note object] == rangestart || [note object] == rangeend)	// if record range
		[scope selectCellWithTag:COMR_RANGE];
}
@end

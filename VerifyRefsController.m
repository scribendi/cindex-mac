//
//  VerifyRefsController.m
//  Cindex
//
//  Created by PL on 1/9/05.
//  Copyright 2005 Indexing Research. All rights reserved.
//

#import "VerifyRefsController.h"
#import "IRIndexDocWController.h"
#import "AttributedStringCategories.h"
#import "search.h"
#import "sort.h"
#import "commandutils.h"
#import "formattedtext.h"
#import "strings_c.h"

static int tabset[] = {-40,48,125,160,0};

static char * v_err[] = 	{	/* verification error messages */
	"",
	"Too few",
	"Circular",
	"Missing",
	"Case/Accent"
};
	
@implementation VerifyRefsController
- (void)awakeFromNib {
	[super awakeFromNib];
	[matches setIntValue:g_prefs.hidden.crossminmatch];
	[refcount setIntValue:g_prefs.hidden.pagemaxcount];
	FF = [[self document] iIndex];
}
- (IBAction)showHelp:(id)sender {
	[[NSHelpManager sharedHelpManager] openHelpAnchor:@"checkrefs0_Anchor-14210" inBook:@"Cindex 4.2.5 Help"];
}
- (IBAction)closeSheet:(id)sender {    
	if ([sender tag] == OKTAG)	{
		NSMutableAttributedString * verifylist = [[NSMutableAttributedString alloc] init];
		NSMutableAttributedString * countlist = [[NSMutableAttributedString alloc] init];
		RECN errtot = 0;
		VERIFYGROUP tvg;
		RECORD * recptr;
		char trec[MAXREC];
		BOOL docross = [checkcross state];
		BOOL dopage = [checkpage state];
		int pagelimit = [refcount intValue];
		unsigned char delstat;
				
		memset(&tvg,0,sizeof(VERIFYGROUP));
		tvg.lowlim = [matches intValue];
		tvg.fullflag = [requireexact state];
		tvg.t1 = trec;
		tvg.locatoronly = FF->head.refpars.clocatoronly;

		delstat = FF->head.privpars.hidedelete;
		FF->head.privpars.hidedelete = TRUE;
//		sort_setfilter(FF,SF_HIDEDELETEONLY);
		if (docross)	{		// if want cross-refs
			for (recptr = sort_top(FF); recptr; recptr = sort_skip(FF,recptr,1)) {	   /* for all records */
				int crosscount = search_verify(FF,recptr->rtext,&tvg);
				
				if (crosscount)	{	/* if have cross-ref */
					int count;
					
					for (count = 0; count < crosscount; count++)	{
						if (tvg.cr[count].error || tvg.eflags&V_TYPEERR)	{	// if an error
							char string[MAXREC], tstring[256];
							sprintf(tstring, "%s\t%s", v_err[tvg.cr[count].error], tvg.eflags&V_TYPEERR ? "Type" : g_nullstr);
							sprintf(string,"\t%u\t%s\t%.*s [from %s]\r",recptr->num,tstring,tvg.cr[count].length,recptr->rtext+tvg.cr[count].offset, recptr->rtext);
							[verifylist appendAttributedString:[NSAttributedString asFromXString:string fontMap:NULL size:0 termchar:0]];
							errtot++;
						}
					}
				}
			}
		}
		if (dopage)	{	// if want page refs
			char vmode = FF->head.privpars. vmode; 
			short runlevel = FF->head.formpars.ef.runlevel;
				
			FF->head.privpars.vmode = VM_FULL;	// force into full form, full indented
			FF->head.formpars.ef.runlevel = 0;
			for (recptr = sort_top(FF); recptr; recptr = form_skip(FF, recptr,1)) {	   /* for all records */
				ENTRYINFO es;
				
				FF->singlerefcount = FALSE;		// for net count of locators
				form_buildentry(FF, recptr, &es);
//				NSLog(@"+++(%d) %d: %d",recptr->num,FF->singlerefcount, es.prefs);
				if (FF->singlerefcount > pagelimit) {
					char string[MAXREC+100];
					sprintf(string,"\t%u\tLocator\t[%d]\t%s\r",recptr->num, FF->singlerefcount, recptr->rtext);
					[countlist appendAttributedString:[NSAttributedString asFromXString:string fontMap:NULL size:0 termchar:0]];
					errtot++;
				}
			}
			FF->head.privpars.vmode = vmode;
			FF->head.formpars.ef.runlevel = runlevel;
		}
		FF->head.privpars.hidedelete = delstat;
//		sort_setfilter(FF,SF_VIEWDEFAULT);
		[verifylist appendAttributedString:countlist];
		if (errtot) {
			[verifylist setTabs:tabset headIndent:160];
			[[self document] showText:verifylist title:@"Reference Check"];
		}
		else {
			[(IRIndexDocWController *)[[self document] textWindowController] close];
			sendinfo(VERIFYOK);
		}
		g_prefs.hidden.crossminmatch = [matches intValue];
		g_prefs.hidden.pagemaxcount = [refcount intValue];
	}
	[self.window.sheetParent endSheet:self.window returnCode:[sender tag]];
}
@end

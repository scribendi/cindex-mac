//
//  GroupsController.m
//  Cindex
//
//  Created by PL on 1/9/05.
//  Copyright 2005 Indexing Research. All rights reserved.
//

#import "GroupsController.h"
#import "commandutils.h"
#import "IRIndexDocument.h"
#import "group.h"
#import "cindexmenuitems.h"

enum	{	/* action types */
	G_REVISE,
	G_DELETE,
	G_LINK
};
static char *fname[] = {"All","All Text","Last Text"};

//char * makestylestring(unsigned char style, unsigned char font);

@implementation GroupsController
- (void)awakeFromNib {
	[super awakeFromNib];
	FF = [[self document] iIndex];
	
	[group setMenu:[[self document] groupMenu:YES]];
	if (FF->viewtype == VIEW_GROUP)		// if there's active group
		[group selectItemWithTitle:[NSString stringWithCString:FF->curfile->gname encoding:NSUTF8StringEncoding]];	// select it
	if (FF->head.sortpars.fieldorder[0] == PAGEINDEX)	// if page sort
		[[action cellWithTag:2] setEnabled:NO];		// no linking
}
- (IBAction)showHelp:(id)sender {
	[[NSHelpManager sharedHelpManager] openHelpAnchor:@"group2_Anchor-14210" inBook:@"Cindex 4.2.5 Help"];
}
- (IBAction)showInformation:(id)sender {
	NSString * gname = [group titleOfSelectedItem];
	GROUPHANDLE gh = grp_open(FF, (char *)[gname UTF8String]);
	
	if (gh)	{	// if can open group
		GROUP * gp = gh;
		char tstring[256], *tptr;
		
		[[ginfo cellWithTag:0] setStringValue:gname];		// name
		[[ginfo cellWithTag:1] setIntValue:gp->rectot];	// records
#if 0
		strftime(tstring, 100, "%b %d %Y %H:%M", localtime(&gp->tstamp));
		[[ginfo cellWithTag:2] setStringValue:[NSString stringWithUTF8String:tstring]];	// time stamp
#else
		[[ginfo cellWithTag:2] setStringValue:[NSString stringFromCinTime:gp->tstamp]];
#endif
		if (gp->gflags&GF_SEARCH)	{	// if built from search
			NSString * rstring = @"";
			if (strlen(gp->lg.range0) || strlen(gp->lg.range1))	// if had range
				rstring = [NSString stringWithFormat:@" in range [%s] [%s]",gp->lg.range0,gp->lg.range1];
			[contextbox setHidden: NO];
			[[ginfo cellWithTag:3] setStringValue:[NSString stringWithFormat:@"Search%@",rstring]];		// method
			[notstring setStringValue:gp->lg.lsarray[0].notflag ? @"Not" : @""];
			[searchstring setStringValue:[NSString stringWithUTF8String:gp->lg.lsarray[0].string]];
			if (gp->lg.size > 1)		// if have more than one search criterion
				[andstring setStringValue:gp->lg.lsarray[0].andflag ? @"and…" : @"or…"];
			else
				[andstring setStringValue:@""];
			LIST * lp = &gp->lg.lsarray[0];
			[attribstring setStringValue:attribdescriptor(lp->style,lp->font,lp->forbiddenstyle,lp->forbiddenfont)];
			if (gp->lg.lsarray[0].field < 0)
				tptr = fname[gp->lg.lsarray[0].field+(-ALLFIELDS)];
			else {
				if (gp->lg.lsarray[0].field == PAGEINDEX)
					tptr = FF->head.indexpars.field[PAGEINDEX].name;
				else
					tptr = FF->head.indexpars.field[gp->lg.lsarray[0].field].name;
			}
			[fieldstring setStringValue:[NSString stringWithUTF8String:tptr]];
			[[gcontext cellWithTag:0] setState:gp->lg.lsarray[0].evalrefflag];
			[[gcontext cellWithTag:1] setState:gp->lg.lsarray[0].wordflag];
			[[gcontext cellWithTag:2] setState:gp->lg.lsarray[0].caseflag];
			[[gcontext cellWithTag:3] setState:gp->lg.lsarray[0].patflag];
		}
		else	{
			[contextbox setHidden: YES];
			[[ginfo cellWithTag:3] setStringValue:@"From selection"];	// method
		}
		*tstring = '\0';
		if (gp->gflags&GF_REVISED)
			strcpy(tstring, "Revised ");
		if (gp->gflags&GF_COMBINE)
			strcat(tstring, "Combined ");
		if (gp->gflags&GF_LINKED)
			strcat(tstring,"Linked");
		[[ginfo cellWithTag:4] setStringValue:[NSString stringWithUTF8String:tstring]];	// name
		
		grp_dispose(gh);
		centerwindow([self window],infopanel);
		[NSApp runModalForWindow:infopanel];
	}
}
- (IBAction)closePanel:(id)sender {    
	[infopanel close];
	[NSApp stopModal]; 
}
- (IBAction)closeSheet:(id)sender {
	if ([sender tag] == OKTAG)	{
		int firstgroup, lastgroup;
		
		if ([[groupmode selectedCell] tag])	{	// if doing selected group
			firstgroup = [group indexOfSelectedItem];
			lastgroup = firstgroup+1;
		}
		else {		// all groups
			firstgroup = 0;
			lastgroup = [group numberOfItems];
		}
		while (firstgroup < lastgroup) {		// for all groups we want
			char * gname = (char *)[[group itemTitleAtIndex:firstgroup] UTF8String];
			GROUPHANDLE gh = grp_open(FF, gname);
			
			if (gh)	{	// if can open group
				int gaction = [[action selectedCell] tag];
				if (gaction == G_REVISE)	/* revise */
					grp_revise(FF,&gh);		/* if ok */
				else if (gaction == G_DELETE)	/* delete */
					grp_delete(FF,gname);
				else if (!grp_link(FF,&gh))	/* if can link */
					grp_make(FF,gh,gname,TRUE);
				grp_dispose(gh);			/* dispose of it after finishing */
				// things to do if action was on current group
				if (FF->viewtype == VIEW_GROUP && !strcmp(FF->curfile->gname,gname))		// if viewing this group
					[[self document] setViewType:VIEW_GROUP name:[group itemTitleAtIndex:firstgroup]];	// redisplay (or view_all if group gone)
			}
			firstgroup++;
		}
		[[self document] setGroupMenu:[[self document] groupMenu:NO]];	// rebuild menu
		[[self document] installGroupMenu];	// install it
	}
	[self.window.sheetParent endSheet:self.window returnCode:[sender tag]];
}
@end

//
//  ExportOptionsController.m
//  Cindex
//
//  Created by PL on 1/26/05.
//  Copyright 2005 Indexing Research. All rights reserved.
//

#define MINTAG 10
#define MAXTAG 25

#import "ExportOptionsController.h"
#import "commandutils.h"
#import "sort.h"
#import "formattedexport.h"

@interface ExportOptionsController () {
	NSDictionary * styleDic;
	NSMutableArray * styleArray;
	EXPORTPARAMS * _exportParams;
	INDEX * FF;
	BOOL useExplicitNames;
}
@end
@implementation ExportOptionsController
- (id)init	{
    self = [super initWithWindowNibName:@"ExportOptionsController"];
    return self;
}
- (void)awakeFromNib {
	[super awakeFromNib];
	_exportParams = [[self document] exportParameters];
	FF = [[self document] iIndex];
	if (_exportParams->type == E_ARCHIVE || _exportParams->type == E_XMLRECORDS) {
		[tab selectTabViewItemWithIdentifier:@"Archive"];
		[archivenumberorder setState:_exportParams->sorted ? NO : YES];
	}
	else if (_exportParams->type == E_TAB)	{
		[tab selectTabViewItemWithIdentifier:@"PlainText"];
		[plainencoding selectCellWithTag:_exportParams->encoding];
	}
	else if (_exportParams->type == E_DOS)
		[tab selectTabViewItemWithIdentifier:@"Delimited"];
	else if (_exportParams->type == E_XMLTAGGED || _exportParams->type == E_TAGGED)
		[tab selectTabViewItemWithIdentifier:@"Tagged"];
	else	{
		[tab selectTabViewItemWithIdentifier:@"Formatted"];
#if 1
		if (_exportParams->type == E_TEXTNOBREAK)	// plain text formatted export
			paragraphStyles.hidden = YES;
		else
			paragraphStyles.action = @selector(doStyles:);
#endif
		if (g_prefs.gen.indentdef == '\t')
			[formattedindent selectCellWithTag:1];
		else if (g_prefs.gen.indentdef != '\0'){
			[formattedindent selectCellWithTag:2];
			[formattedotherindent setStringValue:[NSString stringWithFormat:@"%c",g_prefs.gen.indentdef]];
		}
	}
	// set up stylenames from saved config;
	styleDic = [[NSUserDefaults standardUserDefaults] dictionaryForKey:[NSString stringWithFormat:@"exportStyles%d",_exportParams->type]];
	styleArray = [styleDic objectForKey:kStyleStyleNames];
	[mode selectCellWithTag:[[styleDic objectForKey:kStyleUseExplicitNames] boolValue]];
	[self setStyleMode:nil];
	centerwindow([NSApp keyWindow], [self window]);
}
- (void)doStyles:(id)sender {
	centerwindow([NSApp keyWindow], stylePanel);
	[NSApp runModalForWindow:stylePanel];
}
- (IBAction)setStyleMode:(id)sender {
	if (useExplicitNames)	// if currently set for explicit names
		[self recoverStyleFields];	// recover current ones
	useExplicitNames = mode.selectedCell.tag;	// set new mode
	if (useExplicitNames) {
		[self loadStyleFields];
		[self enableStyleFields:YES];
	}
	else {
		[self enableStyleFields:NO];
		for (int fcount = MINTAG; fcount < MAXTAG ; fcount++) {
			if (fcount-MINTAG < FF->head.indexpars.maxfields-1)	// if have a field name
				((NSTextField *)[stylePanel.contentView viewWithTag:fcount]).stringValue = [NSString stringWithUTF8String:FF->head.indexpars.field[fcount-MINTAG].name];
			else		// no field name
				((NSTextField *)[stylePanel.contentView viewWithTag:fcount]).stringValue = @"";
		}
		((NSTextField *)[stylePanel.contentView viewWithTag:MAXTAG]).stringValue = _exportParams->type == E_RTF ? @"ahead" : @"Ahead";
	}
}
- (IBAction)showHelp:(id)sender {
	NSInteger index = [tab indexOfTabViewItem:[tab selectedTabViewItem]];
	NSString * anchor;
	
	if (index == 0)
		anchor = _exportParams->type == E_ARCHIVE ? @"exopt0_Anchor-11481" : @"exopt0a_Anchor-11481";
	else if (index == 1)		// plain text
		anchor = @"exopt1_Anchor-11481";
	else if (index == 2)		// DOS text
		anchor = @"exopt1_Anchor-11481";
	else if (index == 3)
		anchor = @"exopt2_Anchor-11481";
	else
		anchor = @"exopt3_Anchor-11481";
	[[NSHelpManager sharedHelpManager] openHelpAnchor:anchor inBook:@"Cindex 4.2.5 Help"];
}
- (IBAction)closePanel:(id)sender {    
//	NSLog([[tab selectedTabViewItem] identifier]);
	if ([sender tag] == OKTAG)	{
		if (![[self window] makeFirstResponder:[self window]])
			return;
		if ([sender window] == stylePanel) 	{	// if closing set
			if (useExplicitNames)	// if want table contents
				[self recoverStyleFields];	// recover current explicit settings
			NSDictionary * sdic = [NSDictionary dictionaryWithObjectsAndKeys:[NSNumber numberWithBool:useExplicitNames], kStyleUseExplicitNames, styleArray, kStyleStyleNames,nil];
			[[NSUserDefaults standardUserDefaults] setObject:sdic forKey:[NSString stringWithFormat:@"exportStyles%d",_exportParams->type]];
		}
		else {
			NSTextField * trstart, *trend, *tpstart, *tpend;
			int scope = 0, tsort, err;
			char tdel;
			
			if ([[[tab selectedTabViewItem] identifier] isEqualToString:@"Archive"]) {
				_exportParams->sorted = [archivenumberorder state] ? NO : YES;
				_exportParams->includedeleted = [archiveincludedeleted state];
				trstart = archiverangefrom;
				trend = archiverangeto;
				scope = (int)[[archivescope selectedCell] tag];
			}
			else if ([[[tab selectedTabViewItem] identifier] isEqualToString:@"PlainText"]) {
				_exportParams->sorted = [plainnumberorder state] ? NO : YES;
				_exportParams->encoding = (int)[[plainencoding selectedCell] tag];
				_exportParams->minfields = [plainminfields intValue];
				trstart = plainrangefrom;
				trend = plainrangeto;
				scope = (int)[[plainscope selectedCell] tag];
			}
			else if ([[[tab selectedTabViewItem] identifier] isEqualToString:@"Delimited"]) {
				_exportParams->sorted = [delimitednumberorder state] ? NO : YES;
				_exportParams->appendflag = [delimitedappend state];
				_exportParams->includedeleted = [delimitedincludedeleted state];
				_exportParams->minfields = [delimitedminfields intValue];
				trstart = delimitedrangefrom;
				trend = delimitedrangeto;
				scope = (int)[[delimitedscope selectedCell] tag];
			}
			else if ([[[tab selectedTabViewItem] identifier] isEqualToString:@"Formatted"]) {
				int tabtype = (int)[formattedindent selectedColumn];

				if (tabtype == 1)
					_exportParams->usetabs = '\t';
				else if (tabtype == 2)
					_exportParams->usetabs = *[[formattedotherindent stringValue] UTF8String];
				_exportParams->newlinetype = (int)[formattednewline selectedColumn];
				trstart = formattedrangefrom;
				trend = formattedrangeto;
				tpstart = formattedpagerangefrom;
				tpend = formattedpagerangeto;
				scope = (int)[[formattedscope selectedCell] tag];
			}
			else if ([[[tab selectedTabViewItem] identifier] isEqualToString:@"Tagged"]) {
				_exportParams->newlinetype = (int)[taggednewline selectedColumn];
				trstart = taggedrangefrom;
				trend = taggedrangeto;
				tpstart = taggedpagerangefrom;
				tpend = taggedpagerangeto;
				scope = (int)[[taggedscope selectedCell] tag];
			}
			tsort = FF->head.sortpars.ison;
			FF->head.sortpars.ison = _exportParams->sorted;
			tdel = FF->head.privpars.hidedelete;
			FF->head.privpars.hidedelete = !_exportParams->includedeleted;
	//		sort_setfilter(FF,_exportParams->includedeleted ? SF_OFF : SF_HIDEDELETEONLY);
			err = com_getrecrange(FF,scope, trstart, trend,&_exportParams->first, &_exportParams->last);
			FF->head.sortpars.ison = tsort;
			FF->head.privpars.hidedelete = tdel;
	//		sort_setfilter(FF,SF_VIEWDEFAULT);
			if (err) {
				[[self window] makeFirstResponder: err < 0 ? trstart : trend];
				return;
			}
			if (scope == COMR_PAGE) {		// if page range
				_exportParams->firstpage = [tpstart intValue];
				_exportParams->lastpage = [tpend intValue];
			}
		}
	}
	[[sender window] close];
	[NSApp stopModal];
}
- (void)controlTextDidChange:(NSNotification *)note	{
	NSControl * control = [note object];
	if (control == archiverangefrom || control == archiverangefrom)	// if record range
		[archivescope selectCellWithTag:COMR_RANGE];
	else if (control == plainrangefrom || control == plainrangeto)	// if record range
		[plainscope selectCellWithTag:COMR_RANGE];
	else if (control == delimitedrangefrom || control == delimitedrangeto)	// if record range
		[delimitedscope selectCellWithTag:COMR_RANGE];
	else if (control == formattedrangefrom || control == formattedrangeto)	// if record range
		[formattedscope selectCellWithTag:COMR_RANGE];
	else if (control == taggedrangefrom || control == taggedrangeto)	// if record range
		[taggedscope selectCellWithTag:COMR_RANGE];
	else if (control == formattedpagerangefrom || control == formattedpagerangeto)	// if page range
		[formattedscope selectCellWithTag:COMR_PAGE];
	else if (control == taggedpagerangefrom || control == taggedpagerangeto)	// if page range
		[taggedscope selectCellWithTag:COMR_PAGE];
	else if (control == formattedotherindent) {
//		NSString * ustring = [control stringValue];
//		if ([ustring length] > 1)
//			[control setStringValue:[ustring substringToIndex:1]];
		checktextfield(control,2);
	}
}
- (BOOL)control:(NSControl *)control textShouldEndEditing:(NSText *)editor {
	if (control.tag >= MINTAG && control.tag <= MAXTAG) {
		const char * style = [control.stringValue UTF8String];
		return strlen(style) < FNAMELEN /* && !strchr(style,SPACE) */;
	}
	return YES;
}
- (void)enableStyleFields:(BOOL)state {
	for (int tcount = MINTAG; tcount <= MAXTAG; tcount++)
		((NSTextField *)[stylePanel.contentView viewWithTag:tcount]).enabled = state;
}
- (void)clearStyleFields {
	for (int tcount = MINTAG; tcount <= MAXTAG; tcount++)
		((NSTextField *)[stylePanel.contentView viewWithTag:tcount]).stringValue = @"";
}
- (void)recoverStyleFields {
	styleArray = [NSMutableArray arrayWithCapacity:MAXTAG-MINTAG+1];
	for (int tcount = MINTAG; tcount <= MAXTAG; tcount++)
		[styleArray addObject:((NSTextField *)[stylePanel.contentView viewWithTag:tcount]).stringValue];
}
- (void)loadStyleFields {
	if (styleArray && styleArray.count) {
		for (int tcount = MINTAG; tcount <= MAXTAG; tcount++)
			((NSTextField *)[stylePanel.contentView viewWithTag:tcount]).stringValue = [styleArray objectAtIndex:tcount-MINTAG];
	}
}
@end

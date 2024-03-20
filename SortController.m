//
//  SortController.m
//  Cindex
//
//  Created by PL on 1/9/05.
//  Copyright 2005 Indexing Research. All rights reserved.
//

#import "strings_c.h"
#import "sort.h"
#import "collate.h"
#import "SortController.h"
#import "IRIndexDocument.h"
#import "commandutils.h"

#define kSubSource @"subSource"
#define kSubRep @"subRep"

enum {	// exceptions matrix tags
	EX_IGNHYPHEN = 0,
	EX_IGNPERIOD,
	EX_EVALNNUMBER,
	EX_IGNPARENPHRASE,
	EX_IGNPAREN
};
enum  {
	COLUMN_S = 0,
	COLUMN_R
};

NSString * charPriorityBoardType = @"CICharPri";
NSString * refPriorityBoardType = @"CIRefPri";
NSString * segOrderBoardType = @"CISegOrderPri";
NSString * fieldOrderBoardType = @"CIFieldOrder";
NSString * styleOrderBoardType = @"CIStyleOrder";

static char chprilist[] = "Symbols\0Numbers\0Letters\0\177";
static char refprilist[] = "Roman Numerals\0Arabic Numerals\0Letters\0Months\0\177";
static char complist[] = "First\0Second\0Third\0Fourth\0Fifth\0Sixth\0Seventh\0Eighth\0Ninth\0Tenth\0\177";
static char stylelist[] = "Plain\0Bold\0Italic\0Underline\0\177";

static short defcharpri[] = {0,1,2,-1};

static NSString * getliststring(char *string, short *list, NSInteger row , int *rindex);
static void switchlistpositions(short *list, int sourcerow, NSInteger destrow);
static void switchitemstate(char *string, short *list, NSInteger row);
static BOOL getitemstate(char *string, short *list, NSInteger row);
/************************************************************************************/
@interface SortController () {
	NSMutableArray * subArray;
	
	INDEX * FF;
	SORTPARAMS _sParam;	// working copy
	SORTPARAMS * _sParamPtr;
	INDEXPARAMS	 * _iParamPtr;
	char folist[256];
}
@property(retain)id activeText;

- (void)_setAlphaRule:(int)rule;
- (void)_doubleClick:(id)sender;
@end

@implementation SortController
- (id)init	{
    self = [super initWithWindowNibName:@"SortController"];
    return self;
}
- (void)awakeFromNib {
	[super awakeFromNib];
	char * sptr;
	int count, lindex;
	
	if (self.document)	{
		FF = [self.document iIndex];
		
		_sParamPtr = FF->curfile ? &FF->curfile->sg : &FF->head.sortpars;	// get sort params for group or main index
		_iParamPtr = &FF->head.indexpars;
	}
	else	{
		_sParamPtr = &g_prefs.sortpars;
		_iParamPtr = &g_prefs.indexpars;
	}
	_sParam = *_sParamPtr;
	
	[charpriority registerForDraggedTypes:[NSArray arrayWithObject:charPriorityBoardType]];
	[fieldorder registerForDraggedTypes:[NSArray arrayWithObject:fieldOrderBoardType]];
	[segmentorder registerForDraggedTypes:[NSArray arrayWithObject:segOrderBoardType]];
	[typeprecedence registerForDraggedTypes:[NSArray arrayWithObject:refPriorityBoardType]];
 	[styleprecedence registerForDraggedTypes:[NSArray arrayWithObject:styleOrderBoardType]];
    [typeprecedence setDoubleAction:@selector(_doubleClick:)];
    [segmentorder setDoubleAction:@selector(_doubleClick:)];
    [fieldorder setDoubleAction:@selector(_doubleClick:)];
	[leftrightorder setState:_sParam.forceleftrightorder];
	
	for (int lcount = lindex = 0; lcount < cl_languagecount; lcount++)	{
		NSString * name = [NSString stringWithUTF8String:cl_languages[lcount].name];
		[language addItemWithTitle:name];
		[[language itemWithTitle:name] setTag:lcount];
		if (!strcmp(_sParam.localeID,cl_languages[lcount].localeID)) {	// if our locale (try full first)
			lindex = lcount;
		}
	}
	[language selectItemAtIndex:lindex];
	[self setScript:language];
	[alpharule selectItemWithTag:_sParam.type];
	[self _setAlphaRule:_sParam.type];	// set rule and exceptions
	[[exceptions cellWithTag:EX_IGNHYPHEN] setState:_sParam.ignoreslash];
	[[exceptions cellWithTag:EX_IGNPERIOD] setState:_sParam.ignorepunct];
	[[exceptions cellWithTag:EX_EVALNNUMBER] setState:_sParam.evalnums];
	[[exceptions cellWithTag:EX_IGNPAREN] setState:_sParam.ignoreparen];
	[[exceptions cellWithTag:EX_IGNPARENPHRASE] setState:_sParam.ignoreparenphrase];
	[ignoreprefix setStringValue:[NSString stringWithUTF8String:_sParam.ignore]];
	[ignorelowest setState:_sParam.skiplast];
	[scriptfirst setState:_sParam.nativescriptfirst];
	[[multiplerefs cellWithTag:0] setState:_sParam.ascendingorder];
	[[multiplerefs cellWithTag:1] setState:_sParam.ordered];
	for (sptr = folist, count = 0; count < _iParamPtr->maxfields; count++)	{	/* for all fields */
		strcpy(sptr,_iParamPtr->field[count == _iParamPtr->maxfields-1 ? PAGEINDEX : count].name);		/* add field to xstring */
		sptr += strlen(sptr)+1;
		if (_sParam.fieldorder[count] == PAGEINDEX)		// set right temp index for page field
			_sParam.fieldorder[count] = _iParamPtr->maxfields-1;
	}
	*sptr = EOCS;
	subArray = [NSMutableArray arrayWithCapacity:10];
	[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(updateProgress:) name:NOTE_PROGRESSCHANGED object:nil];
}
- (void)dealloc {
	[[NSNotificationCenter defaultCenter] removeObserver:self];
}
- (void)updateProgress:(NSNotification *)note {
	indicator.doubleValue = [[note object] doubleValue];
}
- (IBAction)showHelp:(id)sender {
	NSString * anchor;
	
	if ([sender window] == subPanel)
		anchor = @"sort2a_Anchor-14210";
	else {
		NSInteger index = [sorttab indexOfTabViewItem:[sorttab selectedTabViewItem]];
		if (index == 0)
			anchor = @"sort2_Anchor-14210";
		else if (index == 1)
			anchor = @"sort1_Anchor-14210";
		else
			anchor = @"sort4_Anchor-14210";
	}
	[[NSHelpManager sharedHelpManager] openHelpAnchor:anchor inBook:@"Cindex 4.2.5 Help"];
}
- (IBAction)setAlphaRule:(id)sender {
	[self _setAlphaRule:[[sender selectedCell] tag]];
	memcpy(_sParam.charpri,defcharpri,sizeof(defcharpri));	// reset default char priority
	[charpriority reloadData];
}
- (IBAction)setScript:(id)sender {
	char * script = cl_languages[[[sender selectedItem] tag]].script;
	bool islatin = !strcmp("Latn", script);
	
	[scriptfirst setEnabled:!islatin];
	[scriptfirst setState:islatin];
}
- (IBAction)doSubstitutions:(id)sender {
	[subArray removeAllObjects];
	for (char * suptr = _sParam.substitutes; *suptr != EOCS; suptr += strlen(suptr)+1) {
		NSString * source = [NSString stringWithUTF8String:suptr];
		NSString * rep = [NSString stringWithUTF8String:(suptr += strlen(suptr)+1)];
		NSMutableDictionary * rowdic = [NSMutableDictionary dictionaryWithObjectsAndKeys:source,kSubSource, rep,kSubRep,nil];
		[subArray addObject:rowdic];
	}
	if (!subArray.count)	// if empty
		[subArray addObject:[NSMutableDictionary dictionaryWithObjectsAndKeys:@"",kSubSource, @"",kSubRep,nil]];	// set placeholder
	[subtable reloadData];
	centerwindow(self.window, subPanel);
	[NSApp runModalForWindow:subPanel];
}
- (IBAction)manageSubstitution:(id)sender {
	[subPanel makeFirstResponder:subtable];	// complete any item currently being edited
	if ([sender selectedSegment] == 0)	{	// adding
		NSDictionary * lastdic = subArray.lastObject;
		if (!lastdic || [[lastdic objectForKey:kSubSource] length])
			[subArray addObject:[NSMutableDictionary dictionaryWithObjectsAndKeys:@"",kSubSource, @"",kSubRep,nil]];
		[subtable reloadData];
		[subtable editColumn:0 row:subArray.count-1 withEvent:nil select:YES];	// open empty field
	}
	else if ([sender selectedSegment] == 1)	{	// deleting
		NSIndexSet * iset = [subtable selectedRowIndexes];
		NSInteger row = [iset firstIndex];
		if (row != NSNotFound)
			[subArray removeObjectAtIndex:row];
		[subtable reloadData];
		[subtable deselectAll:nil];
	}
}
- (IBAction)closePanel:(id)sender {
	if ([sender window] == subPanel) {
		if ([sender tag] == OKTAG) {
			char * sptr = _sParam.substitutes;
			[subPanel makeFirstResponder:subtable];	// complete any item currently being edited
			int totLength = 1;	// count EOCS
			for (NSDictionary * rdic in subArray) {
				NSString * source = [rdic objectForKey:kSubSource];
				if (source.length)	{	// if have a sub source
					const char * sstr = [source UTF8String];
					const char * rstr = [[rdic objectForKey:kSubRep] UTF8String];
					totLength += strlen(sstr) + strlen(rstr) + 2;
					if (sptr - _sParam.substitutes + totLength < STSTRING) {	// if will fit
						strcpy(sptr,sstr);
						sptr += strlen(sptr)+1;
						strcpy(sptr,rstr);
						sptr += strlen(sptr)+1;
					}
				}
			}
			*sptr = EOCS;
		}
		[subPanel orderOut:sender];
		[NSApp stopModalWithCode:[sender tag]];
		return;
	}
	if ([sender tag] == OKTAG)	{
		int count;
		
		if (![[self window] makeFirstResponder:[self window]])
			return;		//error failure
		strcpy(_sParamPtr->ignore,[[ignoreprefix stringValue] UTF8String]);
		for (count = 0; count < _iParamPtr->maxfields; count++)	{	// for all record fields
			if (_sParam.fieldorder[count] == _iParamPtr->maxfields-1)
				_sParam.fieldorder[count] = PAGEINDEX;
		}
		_sParamPtr->type = [[alpharule selectedItem] tag];
		_sParamPtr->ignoreslash = [[exceptions cellWithTag:EX_IGNHYPHEN] state];
		_sParamPtr->ignorepunct = [[exceptions cellWithTag:EX_IGNPERIOD] state];
		_sParamPtr->evalnums = [[exceptions cellWithTag:EX_EVALNNUMBER] state];
		_sParamPtr->ignoreparen = [[exceptions cellWithTag:EX_IGNPAREN] state];
		_sParamPtr->ignoreparenphrase = [[exceptions cellWithTag:EX_IGNPARENPHRASE] state];
		_sParamPtr->skiplast = [ignorelowest state];
		_sParamPtr->nativescriptfirst = [scriptfirst state];
		_sParamPtr->ascendingorder = [[multiplerefs cellWithTag:0] state];
		_sParamPtr->ordered = [[multiplerefs cellWithTag:1] state];
#if 0
		strcpy(_sParamPtr->language,[[[language selectedItem] representedObject] UTF8String]);
#else
		strcpy(_sParamPtr->language,cl_languages[[[language selectedItem] tag]].id);
		strcpy(_sParamPtr->localeID,cl_languages[[[language selectedItem] tag]].localeID);
#endif
		memcpy(_sParamPtr->substitutes,&_sParam.substitutes, sizeof(_sParam.substitutes));
		memcpy(_sParamPtr->charpri,&_sParam.charpri, sizeof(_sParam.charpri));
		memcpy(_sParamPtr->refpri,&_sParam.refpri, sizeof(_sParam.refpri));
		memcpy(_sParamPtr->partorder,&_sParam.partorder, sizeof(_sParam.partorder));
		memcpy(_sParamPtr->fieldorder,&_sParam.fieldorder, sizeof(_sParam.fieldorder));
		memcpy(_sParamPtr->styleorder,&_sParam.styleorder, sizeof(_sParam.styleorder));
		_sParamPtr->forceleftrightorder = [leftrightorder state];
		if ([self document])	{
			[[NSNotificationCenter defaultCenter] postNotificationName:NOTE_GLOBALLYCHANGING object:[self document]];
			col_init(_sParamPtr,FF);	// rebuild tables
			if (FF->curfile)	// if have active group
				sort_sortgroup(FF);
			else
				sort_resort(FF);
			[[self document] redisplay:0 mode:0];	// redisplay all records
		}
	}
	if ([self document])
		[self.window.sheetParent endSheet:self.window returnCode:[sender tag]];
	else {
		[self close];
		[NSApp stopModal]; 
	}
}
- (void)_setAlphaRule:(int)rule {
	[[exceptions cellWithTag:EX_IGNPERIOD] setAllowsMixedState:NO];	// default no mixed state
	switch (rule)	{
		case RAWSORT:
			[exceptions setEnabled:NO];
			[[exceptions cellWithTag:EX_IGNHYPHEN] setState:NO];
			[[exceptions cellWithTag:EX_IGNPERIOD] setState:NO];
			[[exceptions cellWithTag:EX_EVALNNUMBER] setState:NO];
			[[exceptions cellWithTag:EX_IGNPAREN] setState:NO];
			[[exceptions cellWithTag:EX_IGNPARENPHRASE] setState:NO];
			[ignoreprefix setEnabled:NO];
			[charpriority setEnabled:YES];
			substitutions.enabled = NO;
			break;
		case LETTERSORT:
			[[exceptions cellWithTag:EX_IGNHYPHEN] setState:YES];
			[[exceptions cellWithTag:EX_IGNPERIOD] setState:NO];
			[[exceptions cellWithTag:EX_EVALNNUMBER] setState:NO];
			[[exceptions cellWithTag:EX_IGNPAREN] setState:NO];
			[[exceptions cellWithTag:EX_IGNPARENPHRASE] setState:NO];
			[exceptions setEnabled:YES];
			[[exceptions cellWithTag:EX_IGNHYPHEN] setEnabled:NO];
			[[exceptions cellWithTag:EX_IGNPERIOD] setEnabled:YES];
			[[exceptions cellWithTag:EX_EVALNNUMBER] setEnabled:YES];
			[[exceptions cellWithTag:EX_IGNPAREN] setEnabled:YES];
			[[exceptions cellWithTag:EX_IGNPARENPHRASE] setEnabled:YES];
			[ignoreprefix setEnabled:YES];
			[charpriority setEnabled:YES];
			substitutions.enabled = YES;
			break;
		case LETTERSORT_CMS:
			[[exceptions cellWithTag:EX_IGNHYPHEN] setState:YES];
			[[exceptions cellWithTag:EX_IGNPERIOD] setAllowsMixedState:YES];
			[[exceptions cellWithTag:EX_IGNPERIOD] setState:NSMixedState];
			[[exceptions cellWithTag:EX_EVALNNUMBER] setState:YES];
			[[exceptions cellWithTag:EX_IGNPAREN] setState:NO];
			[[exceptions cellWithTag:EX_IGNPARENPHRASE] setState:YES];
			[exceptions setEnabled:YES];
			[[exceptions cellWithTag:EX_IGNHYPHEN] setEnabled:NO];
			[[exceptions cellWithTag:EX_IGNPERIOD] setEnabled:NO];
			[[exceptions cellWithTag:EX_EVALNNUMBER] setEnabled:NO];
			[[exceptions cellWithTag:EX_IGNPAREN] setEnabled:YES];
			[[exceptions cellWithTag:EX_IGNPARENPHRASE] setEnabled:NO];
			[ignoreprefix setEnabled:YES];
			[charpriority setEnabled:NO];
			substitutions.enabled = YES;
			break;
		case LETTERSORT_ISO:
			[[exceptions cellWithTag:EX_IGNHYPHEN] setState:YES];
			[[exceptions cellWithTag:EX_IGNPERIOD] setState:YES];
			[[exceptions cellWithTag:EX_EVALNNUMBER] setState:YES];
			[[exceptions cellWithTag:EX_IGNPAREN] setState:NO];
			[[exceptions cellWithTag:EX_IGNPARENPHRASE] setState:YES];
			[exceptions setEnabled:YES];
			[[exceptions cellWithTag:EX_IGNHYPHEN] setEnabled:NO];
			[[exceptions cellWithTag:EX_IGNPERIOD] setEnabled:NO];
			[[exceptions cellWithTag:EX_EVALNNUMBER] setEnabled:NO];
			[[exceptions cellWithTag:EX_IGNPAREN] setEnabled:YES];
			[[exceptions cellWithTag:EX_IGNPARENPHRASE] setEnabled:NO];
			[ignoreprefix setEnabled:YES];
			[charpriority setEnabled:NO];
			substitutions.enabled = YES;
			break;
		case LETTERSORT_SBL:
			[[exceptions cellWithTag:EX_IGNHYPHEN] setState:YES];
			[[exceptions cellWithTag:EX_IGNPERIOD] setAllowsMixedState:YES];
			[[exceptions cellWithTag:EX_IGNPERIOD] setState:NSMixedState];
			[[exceptions cellWithTag:EX_EVALNNUMBER] setState:YES];
			[[exceptions cellWithTag:EX_IGNPAREN] setState:NO];
			[[exceptions cellWithTag:EX_IGNPARENPHRASE] setState:NO];
			[exceptions setEnabled:YES];
			[[exceptions cellWithTag:EX_IGNHYPHEN] setEnabled:NO];
			[[exceptions cellWithTag:EX_IGNPERIOD] setEnabled:NO];
			[[exceptions cellWithTag:EX_EVALNNUMBER] setEnabled:NO];
			[[exceptions cellWithTag:EX_IGNPAREN] setEnabled:YES];
			[[exceptions cellWithTag:EX_IGNPARENPHRASE] setEnabled:YES];
			[ignoreprefix setEnabled:YES];
			[charpriority setEnabled:NO];
			substitutions.enabled = YES;
			break;
		case WORDSORT:
			[[exceptions cellWithTag:EX_IGNHYPHEN] setState:NO];
			[[exceptions cellWithTag:EX_IGNPERIOD] setState:NO];
			[[exceptions cellWithTag:EX_EVALNNUMBER] setState:NO];
			[[exceptions cellWithTag:EX_IGNPAREN] setState:NO];
			[[exceptions cellWithTag:EX_IGNPARENPHRASE] setState:NO];
			[exceptions setEnabled:YES];
			[[exceptions cellWithTag:EX_IGNHYPHEN] setEnabled:YES];
			[[exceptions cellWithTag:EX_IGNPERIOD] setEnabled:YES];
			[[exceptions cellWithTag:EX_EVALNNUMBER] setEnabled:YES];
			[[exceptions cellWithTag:EX_IGNPAREN] setEnabled:YES];
			[[exceptions cellWithTag:EX_IGNPARENPHRASE] setEnabled:YES];
			[ignoreprefix setEnabled:YES];
			[charpriority setEnabled:YES];
			substitutions.enabled = YES;
			break;
		case WORDSORT_CMS:
			[[exceptions cellWithTag:EX_IGNHYPHEN] setState:YES];
			[[exceptions cellWithTag:EX_IGNPERIOD] setAllowsMixedState:YES];
			[[exceptions cellWithTag:EX_IGNPERIOD] setState:NSMixedState];
			[[exceptions cellWithTag:EX_EVALNNUMBER] setState:YES];
			[[exceptions cellWithTag:EX_IGNPAREN] setState:NO];
			[[exceptions cellWithTag:EX_IGNPARENPHRASE] setState:YES];
			[exceptions setEnabled:YES];
			[[exceptions cellWithTag:EX_IGNHYPHEN] setEnabled:NO];
			[[exceptions cellWithTag:EX_IGNPERIOD] setEnabled:NO];
			[[exceptions cellWithTag:EX_EVALNNUMBER] setEnabled:NO];
			[[exceptions cellWithTag:EX_IGNPAREN] setEnabled:YES];
			[[exceptions cellWithTag:EX_IGNPARENPHRASE] setEnabled:NO];
			[ignoreprefix setEnabled:YES];
			[charpriority setEnabled:NO];
			substitutions.enabled = YES;
			break;
		case WORDSORT_ISO:
			[[exceptions cellWithTag:EX_IGNHYPHEN] setState:NO];
			[[exceptions cellWithTag:EX_IGNPERIOD] setState:YES];
			[[exceptions cellWithTag:EX_EVALNNUMBER] setState:YES];
			[[exceptions cellWithTag:EX_IGNPAREN] setState:NO];
			[[exceptions cellWithTag:EX_IGNPARENPHRASE] setState:YES];
			[exceptions setEnabled:YES];
			[[exceptions cellWithTag:EX_IGNHYPHEN] setEnabled:NO];
			[[exceptions cellWithTag:EX_IGNPERIOD] setEnabled:NO];
			[[exceptions cellWithTag:EX_EVALNNUMBER] setEnabled:NO];
			[[exceptions cellWithTag:EX_IGNPAREN] setEnabled:YES];
			[[exceptions cellWithTag:EX_IGNPARENPHRASE] setEnabled:NO];
			[ignoreprefix setEnabled:YES];
			[charpriority setEnabled:NO];
			substitutions.enabled = YES;
			break;
		case WORDSORT_SBL:
			[[exceptions cellWithTag:EX_IGNHYPHEN] setState:YES];
			[[exceptions cellWithTag:EX_IGNPERIOD] setAllowsMixedState:YES];
			[[exceptions cellWithTag:EX_IGNPERIOD] setState:NSMixedState];
			[[exceptions cellWithTag:EX_EVALNNUMBER] setState:YES];
			[[exceptions cellWithTag:EX_IGNPAREN] setState:NO];
			[[exceptions cellWithTag:EX_IGNPARENPHRASE] setState:NO];
			[exceptions setEnabled:YES];
			[[exceptions cellWithTag:EX_IGNHYPHEN] setEnabled:NO];
			[[exceptions cellWithTag:EX_IGNPERIOD] setEnabled:NO];
			[[exceptions cellWithTag:EX_EVALNNUMBER] setEnabled:NO];
			[[exceptions cellWithTag:EX_IGNPAREN] setEnabled:YES];
			[[exceptions cellWithTag:EX_IGNPARENPHRASE] setEnabled:YES];
			[ignoreprefix setEnabled:YES];
			[charpriority setEnabled:NO];
			substitutions.enabled = YES;
			break;
	}
}
- (void)_doubleClick:(id)sender {
	NSInteger row = [sender selectedRow];

	if (sender == typeprecedence)
		switchitemstate(refprilist,_sParam.refpri,row);
	else if (sender == segmentorder)
		switchitemstate(complist,_sParam.partorder,row);
	else if (sender == fieldorder)
		switchitemstate(folist,_sParam.fieldorder,row);
	[sender reloadData];
}
- (NSInteger)numberOfRowsInTableView:(NSTableView *)tableView {
	if (tableView == subtable)
		return subArray.count;
	else if (tableView == charpriority)
		return str_xcount(chprilist);
	else if (tableView == typeprecedence)
		return str_xcount(refprilist);
	else if (tableView == segmentorder)
		return str_xcount(complist);
	else if (tableView == fieldorder)
		return _iParamPtr ? _iParamPtr->maxfields : 0;	// could be 0 before awakeFrom Nib called.
	else
		return str_xcount(stylelist);
}
- (BOOL)tableView:(NSTableView *)aTableView shouldEditTableColumn:(NSTableColumn *)aTableColumn row:(NSInteger)rowIndex {
	if (aTableView == subtable) {
		[subtable deselectAll:nil];
		return YES;
	}
	return NO;
}
- (void)tableView:(NSTableView *)tableView setObjectValue:(id)object forTableColumn:(NSTableColumn *)tableColumn row:(NSInteger)row	{
	if (row < subArray.count)	{	// if row is valid for list (could have row that's placeholder)
		NSMutableDictionary * rowdic = [subArray objectAtIndex:row];
		[rowdic setObject:object forKey:[tableColumn identifier]];
	}
}
- (id)tableView:(NSTableView *)tableView objectValueForTableColumn:(NSTableColumn *)tableColumn row:(NSInteger)row {
	int baseindex;
	
	if (tableView == subtable)	{
		if (row < subArray.count)	{	// if row is valid for list (could have row that's placeholder)
			NSMutableDictionary * rowdic = [subArray objectAtIndex:row];
			return [rowdic objectForKey:[tableColumn identifier]];
		}
		return nil;
	}
	else if (tableView == charpriority)	{
		return getliststring(chprilist, _sParam.charpri, row, &baseindex);
	}
	else if (tableView == typeprecedence)	{
		return getliststring(refprilist, _sParam.refpri, row, &baseindex);
	}
	else if (tableView == segmentorder)	{
		return getliststring(complist, _sParam.partorder, row, &baseindex);
	}
	else if (tableView == fieldorder) {
		return getliststring(folist, _sParam.fieldorder, row, &baseindex);
	}
	else 	{
		return getliststring(stylelist, _sParam.styleorder, row, &baseindex);
	}
}
- (BOOL)tableView:(NSTableView *)tv writeRowsWithIndexes:(NSIndexSet *)rowIndexes toPasteboard:(NSPasteboard *)pboard {
	NSString * pbtype;
	int row = (int)rowIndexes.firstIndex;
	
	if (tv == subtable)
		return NO;
	if (tv == charpriority)
		pbtype = charPriorityBoardType;
	else if (tv == typeprecedence) {
		if (!getitemstate(refprilist,_sParam.refpri,row))
			return NO;
		pbtype = refPriorityBoardType;
	}
	else if (tv == segmentorder) {
		if (!getitemstate(complist,_sParam.partorder,row))
			return NO;
		pbtype = segOrderBoardType;
	}
	else if (tv == fieldorder) {
		if (!getitemstate(folist,_sParam.fieldorder,row))
			return NO;
		pbtype = fieldOrderBoardType;
	}
	else {
		if (!getitemstate(stylelist,_sParam.styleorder,row))
			return NO;
		pbtype = styleOrderBoardType;
	}
	[pboard declareTypes:[NSArray arrayWithObject: pbtype] owner:self];
	[pboard setData:[NSData dataWithBytes:&row length:(sizeof row)] forType:pbtype];
	return YES;
}
- (NSDragOperation)tableView:(NSTableView*)tv validateDrop:(id <NSDraggingInfo>)info proposedRow:(NSInteger)row proposedDropOperation:(NSTableViewDropOperation)op {
	if (tv == subtable)
		return NSDragOperationNone;
	if (tv == typeprecedence)	{
		if (!getitemstate(refprilist,_sParam.refpri,row))
			return NSDragOperationNone;
	}
	else if (tv == segmentorder)	{
		if (!getitemstate(complist,_sParam.partorder,row))
			return NSDragOperationNone;
	}
	else if (tv == fieldorder) {
		if (!getitemstate(folist,_sParam.fieldorder,row))
			return NSDragOperationNone;
	}
	else  {
		if (!getitemstate(stylelist,_sParam.styleorder,row))
			return NSDragOperationNone;
	}
	if (row < [tv numberOfRows])
		return NSDragOperationMove;
	else
		return NSDragOperationNone;
}
- (BOOL)tableView:(NSTableView*)tv acceptDrop:(id <NSDraggingInfo>)info row:(NSInteger)row dropOperation:(NSTableViewDropOperation)op {
	NSPasteboard * pb = [info draggingPasteboard];
	int sourcerow;

	if (tv == charpriority)	{
		sourcerow = *(int *)[[pb dataForType:charPriorityBoardType] bytes];
		switchlistpositions(_sParam.charpri,sourcerow,row);
	}
	else if (tv == typeprecedence)	{
		sourcerow = *(int *)[[pb dataForType:refPriorityBoardType] bytes];
		switchlistpositions(_sParam.refpri,sourcerow,row);
	}
	else if (tv == segmentorder)	{
		sourcerow = *(int *)[[pb dataForType:segOrderBoardType] bytes];
		switchlistpositions(_sParam.partorder,sourcerow,row);
	}
	else if (tv == fieldorder) {
		sourcerow = *(int *)[[pb dataForType:fieldOrderBoardType] bytes];
		switchlistpositions(_sParam.fieldorder,sourcerow,row);
	}
	else  {
		sourcerow = *(int *)[[pb dataForType:styleOrderBoardType] bytes];
		switchlistpositions(_sParam.styleorder,sourcerow,row);
	}
	[tv reloadData];
	[tv selectRowIndexes:[NSIndexSet indexSetWithIndex:row] byExtendingSelection:NO];
	return YES;
}
- (void)controlTextDidChange:(NSNotification *)note	{
	if ([note object] == ignoreprefix)
		checktextfield([note object],STSTRING);
}
- (BOOL)control:(NSControl *)control textShouldBeginEditing:(NSText *)fieldEditor {
	if (control == subtable)
		self.activeText = control.objectValue;
	return YES;
}
- (BOOL)control:(NSControl *)control textShouldEndEditing:(NSText *)editor {
	if (control == subtable) {
		NSString * sourceText = [control stringValue];
		NSInteger editedColumn = [subtable editedColumn];
		NSInteger editedRow = [subtable editedRow];
		int rowIndex = 0;
		if (editedColumn == COLUMN_S && (!sourceText.length || !u_isalnum([sourceText characterAtIndex:0])))	// must begin with alnum
			return NO;
		for (NSDictionary * rdic in subArray)	{
			if (editedColumn == COLUMN_R && [sourceText hasPrefix:[rdic objectForKey:kSubSource]] && rowIndex != editedRow	// for rep, no source (except own) can be prefix
				// for source, can't be empty, and for any row except own can't be prefix to any rep and can't match any source
				|| editedColumn == COLUMN_S && rowIndex != editedRow && ([sourceText isEqualToString:[rdic objectForKey:kSubSource]] || [[rdic objectForKey:kSubRep] hasPrefix:sourceText]))
				return NO;
			rowIndex++;
		}
		self.activeText = nil;
	}
	return YES;	// don't check expansion text
}
- (BOOL)control:(NSControl *)control textView:(NSTextView *)textView doCommandBySelector:(SEL)command	{
	if (control == subtable) {
		if (command == @selector(cancelOperation:) || command == @selector(insertNewline:)) {
			if (command == @selector(cancelOperation:) && _activeText)
				control.objectValue = _activeText;
			[subPanel makeFirstResponder:subtable];	 // force close of editor
			return YES;
		}
		if ((command == @selector(insertTab:) || command == @selector(insertBacktab:))) {
			NSInteger editedColumn = [subtable editedColumn];
			NSInteger editedRow = [subtable editedRow];
			if (command == @selector(insertBacktab:)) {
				if (editedColumn == COLUMN_S) {
					editedColumn = COLUMN_R;
					editedRow--;
				}
				else
					editedColumn--;
			}
			else if (command == @selector(insertTab:)) {
				if (editedColumn == COLUMN_R) {
					editedColumn = COLUMN_S;
					editedRow++;
				}
				else
					editedColumn++;
			}
			if (editedRow >= subtable.numberOfRows)
				editedRow = 0;
			else if (editedRow < 0)
				editedRow = subtable.numberOfRows-1;
			if (editedColumn >= subtable.numberOfColumns)
				editedColumn = COLUMN_S;
			[subtable editColumn:editedColumn row:editedRow withEvent:nil select:YES];
			return YES;
		}
		return NO;
	}
	else
		return NO;
}
@end
/********************************************************************************/
static NSString * getliststring(char *string, short *list, NSInteger row, int *rindex)

{
	int tcount = str_xcount(string);
	int index, hitindex;
	
	for (index = 0; index < tcount && list[index] >= 0; index++)	{ // among enabled strings
		if (index == row)	{
			*rindex = index;
			return [NSString stringWithFormat:@"+%s",str_xatindex(string,list[index])];
		}
	}
	for (hitindex = index-1, index = 0; index < tcount; index++)	{	// for all strings
		int lcount;
		for (lcount = 0; list[lcount] >= 0; lcount++)	{	// for all items in enabled list
			if (index == list[lcount])	// if current is one
				break;
		}
		if (list[lcount] < 0)		// if we're not already in list
			hitindex++;
		if (hitindex == row)	{
			*rindex = index;
			return [NSString stringWithFormat:@"  %s",str_xatindex(string,index)];
		}
	}
	return nil;
}
/********************************************************************************/
static void switchlistpositions(short *list, int sourcerow, NSInteger destrow)

{
	int tempval = list[sourcerow];
	int index;
	
	if (sourcerow < destrow) {	// moving down
		for (index = sourcerow; index < destrow; index++)
			list[index] = list[index+1];
	}
	else {	// moving up
		for (index = sourcerow; index > destrow; index--)
			list[index] = list[index-1];
	}
	list[index] = tempval;
}
/********************************************************************************/
static void switchitemstate(char *string, short *list, NSInteger row)

{
	int tcount = str_xcount(string);
	int index;
	
	for (index = 0; index < tcount && list[index] >= 0; index++)	 // among enabled strings
		;		// leave point at first disabled item
	if (row >= index)	{	// if our item currently disabled
		int findex;
		getliststring(string,list,row,&findex);	// findex identifies field to be enabled
		list[index] = findex;	// set our (enabled) item in first disabled position
		if (++index < tcount)	// if not last field
			list[index] = -1;	// make sure next is disabled
	}
	else {
		while (row < index-1)	{
			list[row] = list[row+1];		// NB interesting compiler optimization problem:  = list[++row];
			row++;
		}
		list[row] = -1;
	}
}
/********************************************************************************/
static BOOL getitemstate(char *string, short *list, NSInteger row)

{
	int tcount = str_xcount(string);
	int index;
	
	for (index = 0; index < tcount && list[index] >= 0; index++)	 // among enabled strings
		;		// leave point at first disabled item
	return row < index;	// return enabled state
}

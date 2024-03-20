//
//  RecordStructureController.h
//  Cindex
//
//  Created by PL on 1/9/05.
//  Copyright 2005 Indexing Research. All rights reserved.
//
#import "regex.h"
#import "commandutils.h"
#import "records.h"
#import "search.h"
#import "index.h"
#import "RecordStructureController.h"
#import "IRIndexDocument.h"

static NSString *fnames[] = {
	@"First Field", @"Second Field", @"Third Field", @"Fourth Field", @"Fifth Field", @"Sixth Field", @"Seventh Field", @"Eighth Field",
	@"Ninth Field", @"Tenth Field", @"Eleventh Field", @"Twelfth Field", @"Thirteenth Field", @"Fourteenth Field", @"Fifteenth Field",
	@"Locator Field"
};

@interface RecordStructureController (PrivateMethods)
- (void)buildFieldMenu;
@end

@implementation RecordStructureController
- (id)init	{
    self = [super initWithWindowNibName:@"RecordStructureController"];
    return self;
}
- (void)awakeFromNib {
	[super awakeFromNib];
	if ([self document])	{
		int count;
		
		FF = [[self document] iIndex];
		_iParamPtr = &FF->head.indexpars;
		_iParam = *_iParamPtr;
		_sParamPtr = &FF->head.sortpars;
		_cs.firstrec = 1;
		_cs.lastrec = UINT_MAX;
		search_count(FF, &_cs,SF_OFF);
		[usedchars setIntValue:_cs.longest];
		for (count = 0; count < _cs.deepest-2; count++)
			[[maxfields itemAtIndex:count] setEnabled:NO];	// disable below current depth to prevent reduction in # fields
		if (FF->head.rtot)			// disable min if any records
//			[minfields setEnabled:NO];
			[fieldmin setEnabled:NO];
	}
	else	{
		[usedchars setHidden:TRUE];
		[fieldcurrent setHidden:TRUE];
		_iParamPtr = &g_prefs.indexpars;
		_iParam = *_iParamPtr;
		_sParamPtr = &g_prefs.sortpars;
		_cs.longest = 20;		// minimum settable length of record
	}
	_oldmaxfields = _iParam.maxfields;	// save for later use
	_minlength = _cs.longest;
	[maxchars setIntValue:_iParam.recsize];
	[minfields selectItemAtIndex:[minfields indexOfItemWithTag:_iParam.minfields]];
	[maxfields selectItemAtIndex:[maxfields indexOfItemWithTag:_iParam.maxfields]];
	[required setEnabled:_iParam.minfields > 2];
	[required setState:_iParam.required];
	[self buildFieldMenu];
	[self changeField:field];	// force update of field contents
}
- (void)buildFieldMenu {
	int count;
	
	[field removeAllItems];
	for (count = 0; count < _iParam.maxfields; count++)		/* build menu */
		[field addItemWithTitle: fnames[count < _iParam.maxfields-1 ? count : PAGEINDEX]];
}
- (IBAction)showHelp:(id)sender {
	[[NSHelpManager sharedHelpManager] openHelpAnchor:@"recordstruct0_Anchor-14210" inBook:@"Cindex 4.2.5 Help"];
}
- (IBAction)changeNumberOfFields:(id)sender {
	if (sender == minfields)	{
		_iParam.minfields = [[sender selectedItem] tag];
		if ([self document])	{	// if working on index
			if (_iParam.minfields-_cs.longestdepth > 0)	// if longest record needs more fields
				_minlength = _iParam.minfields-_cs.longestdepth+_cs.longest;	// set new min length
			else
				_minlength = _cs.longest;			
		}
		if (_iParam.minfields > _iParam.maxfields) {	// if max now less than min
			_iParam.maxfields = _iParam.minfields;		// increase max
			[maxfields selectItemAtIndex:[maxfields indexOfItemWithTag:_iParam.maxfields]];
		}
	}
	if (sender == maxfields) {
		_iParam.maxfields = [[sender selectedItem] tag];
		if (_iParam.minfields > _iParam.maxfields) {	// if min now bigger than max
			_iParam.minfields = _iParam.maxfields;		// reduce min
			[minfields selectItemAtIndex:[minfields indexOfItemWithTag:_iParam.minfields]];
		}
	}
	[required setEnabled:_iParam.minfields > 2];
	if (_iParam.minfields <= 2)
		[required setState:NO];
	[self buildFieldMenu];
	[self changeField:field];	// force update of field contents
}
- (IBAction)changeField:(id)sender {
	if (![[self window] makeFirstResponder:fieldname])	{	// if can't shift responder
		[[self window] endEditingFor:nil];		// force it
		[[self window] makeFirstResponder:fieldname];		// restore responder
	}
	NSInteger index = [sender indexOfSelectedItem];
	
	if (index == _iParam.maxfields-1)
		index = PAGEINDEX;
	[fieldname setStringValue:[NSString stringWithCString:_iParam.field[index].name encoding:NSUTF8StringEncoding]];
	[fieldmax setIntValue:_iParam.field[index].minlength];
	[fieldcurrent setIntValue:_cs.fieldlen[index]];
	[fieldmax setIntValue:_iParam.field[index].maxlength];
	[pattern setStringValue:[NSString stringWithCString:_iParam.field[index].matchtext encoding:NSUTF8StringEncoding]];
	_currentfield = index;
}
- (IBAction)closePanel:(id)sender {    
	if ([sender tag] == OKTAG)	{
		int mintot, maxtot, count;
		
		if (![[self window] makeFirstResponder:[self window]])	// if a bad field
			return;
		for (mintot = maxtot = count = 0; count < _iParam.maxfields; count++)	{ /* for all fields */
			mintot += _iParam.field[count].minlength;
			if (_iParam.field[count].maxlength >= _iParam.recsize && _iParam.field[count].maxlength > maxtot)
				maxtot = _iParam.field[count].maxlength;
		}
		if (mintot < maxtot)	/* find bigger error */
			mintot = maxtot;
#if 0
		if (mintot > _iParam.recsize)	{		/* if require more space than recsize */
			if (sendwarning(LONGFIELDWARNING,mintot-_iParam.recsize))
				_iParam.recsize = mintot;
			else
				return;
		}
#endif
		if (mintot < _minlength)
			mintot = _minlength;
		_iParam.recsize = [maxchars intValue];
		if (_iParam.recsize < mintot)	{	// if record size too small
			if (sendwarning(SHORTRECORDWARNING,mintot))
				_iParam.recsize = mintot;
			else
				return;
		}
		_iParam.required = [required state];
#if 0
		if (_iParam.recsize&1)	// if odd # chars
			_iParam.recsize++;	// increment
#else
		_iParam.recsize = (_iParam.recsize+3)&~3; // round up to nearest multiple of 4
#endif
		if ([self document])	{		// if working on real index
			if ([[self document] resizeIndex:_iParam.recsize])	{	// if can resize with new settings
				int tminfields = FF->head.indexpars.minfields;		// catch current min fields
				BOOL requiredfieldchanged = FF->head.indexpars.required != _iParam.required;	// note required change
				
				*_iParamPtr = _iParam;		// install new params
				if (requiredfieldchanged)
					FF->head.indexpars.required ^= 1;	// do field number adjustments with old setting
				if (tminfields != FF->head.indexpars.minfields)	{	// if changed min fields
					RECN rcount;
					for (rcount = 1; rcount <= FF->head.rtot; rcount++)	{	// for all records
						RECORD * recptr = getaddress(FF,rcount);			// bypass integrity check, which looks at minfields
						int fcount = rec_strip(FF,recptr->rtext);		// strip surplus

						if (fcount < FF->head.indexpars.minfields)		// if too few fields
							rec_pad(FF, recptr->rtext);		// pad
					}
				}
				if (requiredfieldchanged)	{
					FF->head.indexpars.required ^= 1;	// restore new setting
					sort_resort(FF);
				}
				index_markdirty(FF);
			}
		}
		else 
			*_iParamPtr = _iParam;
		adjustsortfieldorder(_sParamPtr->fieldorder, _oldmaxfields,_iParamPtr->maxfields);	// adjust sort fields
	}
	if ([self document])	{
		[self.window.sheetParent endSheet:self.window returnCode:[sender tag]];
		[[NSNotificationCenter defaultCenter] postNotificationName:NOTE_STRUCTURECHANGED object:[self document]];
	}
	else {
		[self close];
		[NSApp stopModal]; 
	}
}
- (void)controlTextDidChange:(NSNotification *)note	{
	NSControl * control = [note object];

	if (control == fieldname)
		checktextfield(control,FNAMELEN);
	if (control == pattern)
		checktextfield(control,PATTERNLEN);
}
- (BOOL)control:(NSControl *)control textShouldEndEditing:(NSText *)editor {
	if (control == fieldname)	{
		NSInteger length = [[control stringValue] length];
		if (!length)
			return NO;
		strcpy(_iParam.field[_currentfield].name, [[fieldname stringValue] UTF8String]);
	}
	else if (control == pattern)	{
		char * string = (char *)[[control stringValue] UTF8String];
		if (!regex_validexpression(string,0)) {
			errorSheet(self.window,BADEXPERR,WARN,string);
			return NO;
		}
		strcpy(_iParam.field[_currentfield].matchtext, string);
	}
	else if (control == fieldmin) {
		int value = [control intValue];
		if (_cs.fieldlen[_currentfield] && value > _cs.fieldlen[_currentfield])	// if has content && would enlarge field
			return NO;
		_iParam.field[_currentfield].minlength = value;
	}
	else if (control == fieldmax)	{
		int value = [control intValue];
		if (value && value < _cs.fieldlen[_currentfield])	// if would reduce length of field
			return NO;
		_iParam.field[_currentfield].maxlength = value;
	}
	return YES;
}
@end

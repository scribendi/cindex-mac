//
//  IRRecordView.m
//  Cindex
//
//  Created by PL on 3/12/05.
//  Copyright 2005 Indexing Research. All rights reserved.
//

#import "IRIndexDocumentController.h"
#import "IRIndexRecordWController.h"
#import "AbbreviationController.h"
#import "IRRecordView.h"
#import "IRIndexView.h"
#import "TextViewCategories.h"
#import "AttributedStringCategories.h"
#import "StringCategories.h"
#import "strings_c.h"
#import "commandutils.h"
#import "type.h"
#import "records.h"
#import "cindexmenuitems.h"
#import "search.h"
#import "collate.h"
#import "attributedstrings.h"
#import "refs.h"

enum {
	DA_DEFAULTFONT,
	DA_PLAIN,
	DA_SUPER,
	DA_SUB,
	DA_SMALL,
	DA_SETFONT
};

enum {
	DC_INITIAL,
	DC_UPPER,
	DC_LOWER
};

static char *m_string[] = {		/* mismatch table */
	"{...}",
	"<...>",
	"(...)",
	"[...]",
	"“...”",
	"\"...\"",
	"control codes"
};

#define textchar(A) (!(A >= 0xF700 && A <= 0xF747))		// not a function character value
static short checkfield(unsigned char * source, short *alarms);		/* checks record field */
static NSInteger pbChangeCount;

@interface IRRecordView () {
	BOOL _completingSelection;	// true if selection results from completion
	unsigned int mflags;
	NSDictionary * baseAttributes;	// pre paste/drop typing attrbutes
}
@property (strong) NSDictionary * completionAttributes;
@property (strong) NSMutableDictionary * defaultAttributes;

- (void)_handleDeletion:(BOOL)direction event:(NSEvent *)theEvent;
- (BOOL)_fixBreaks;	// fixes breaks
- (void)_setFieldRanges;
- (NSRange)_selectedFields;
- (void)_flipField:(int)halfmode;
- (void)_swapParens;	// swaps contents of parens
- (void)_incDec:(int)mode;	// increments/decrements last numerical component
- (BOOL)_extendRef;	// adds upper element of range as lower+1
- (void)_changeCase:(int)mode;
- (void)_checkFunctionKey:(int)keyindex;
- (void)_checkAbbreviation;
- (void)_checkCompletion:(NSEvent *)theEvent;
- (void)_insertPreviousField:(int)index;
- (BOOL)_canPaste:(NSPasteboard *)pb drag:(BOOL)drag at:(unsigned int)index;
- (void)_normalizeRange:(NSRange)range;
- (void)_encloseBracketsOfType:(int)type;
- (void)_replaceRangeOfCharacters:(NSRange)range withAttributedString:(NSAttributedString *)as;
- (void)_copyFromFontMap:(FONTMAP *)fm;
@end

@implementation IRRecordView
		
- (void)dealloc {
	for (int count = 0; count < FF->head.indexpars.maxfields; count++) {
		if (_regex[count])
			uregex_close(_regex[count]);
	}
	self.defaultAttributes = nil;
	self.completionAttributes = nil;
}
- (void)changeFont:(id)sender {
	float size;
	
	baseAttributes = self.typingAttributes;	// restored by _normalizeRange
	[super changeFont:sender];
	size = [[self font] pointSize];
	if (size != _fontsize)	{	// if changed font size (only possible through font panel)
		NSRange selrange = [self selectedRange];
		[self _normalizeRange:selrange];
		[self setSelectedRange:selrange];
	}
}
- (NSFontPanelModeMask)validModesForFontPanel:(NSFontPanel *)fp {
	return NSFontPanelFaceModeMask|NSFontPanelCollectionModeMask;
}
- (BOOL)validateMenuItem:(NSMenuItem *)mitem {
	NSInteger itemid = [mitem tag];
	
//	NSLog([mitem title]);
	if (itemid == MI_SWAPPARENS)
		return [self _selectedFields].location < _fieldCount-1 && [self _selectedFields].length == 1;
	else if (itemid >= MI_DEFAULTFONT) {		// this just applies or removes check marks on current font
		NSString * fname = ((NSFont *)[self.typingAttributes objectForKey:NSFontAttributeName]).familyName;
		if (type_findlocal(FF->head.fm, fname.UTF8String, 0) == itemid-MI_DEFAULTFONT)	// if this is active font
			mitem.state = NSControlStateValueOn;
		else
			mitem.state = NSControlStateValueOff;
		return YES;
	}
	else if (itemid == MI_NEWABBREV || itemid == MI_BRACES || itemid == MI_BRACKETS)
		return [self selectedRange].length > 0 && [self _selectedFields].length == 1;
	else if (itemid >= MI_INITIALCAP && itemid <= MI_LOWERCASE)
		return [self selectedRange].length > 0;
	return [super validateMenuItem:mitem];
}
- (BOOL)validateToolbarItem:(NSToolbarItem *)toolbarItem {
	NSInteger tag = [toolbarItem tag];

//	NSLog(@"RView %@",[toolbarItem label]);
	if (![[self window] isMainWindow] || [[self window] toolbar] != [toolbarItem toolbar])
		return NO;
	if (tag == TB_SWAPPAREN)
		return [self _selectedFields].location < _fieldCount-1 && [self _selectedFields].length == 1;
	if (tag == TB_DEFFONT)
		return ![self isAllDefaultFont];
	if (tag == MI_BRACES || tag == MI_BRACKETS)
		return [self selectedRange].length > 0 && [self _selectedFields].length == 1 && [self lastSelectedCharacter] != '\n';
	if (tag == TB_FLIPFULL || tag == TB_FLIPHALF)
		return [self _selectedFields].location < _fieldCount-1;
	return YES;
}
- (BOOL)isAllDefaultFont {	// returns true if all selected text is in default font
	if (self.selectedRange.location < [self textStorage].length) {
		NSRange erange;
		NSFont * finfo = [[self textStorage] attribute:NSFontAttributeName atIndex:self.selectedRange.location effectiveRange:&erange];
//		NSLog([finfo description]);
		BOOL sameFont = [finfo.familyName isEqualToString:[NSString stringWithFormat:@"%s",FF->head.fm[0].name]];
		BOOL isFullRange = NSEqualRanges(NSUnionRange(erange,self.selectedRange), erange);	// disabled unless selection contains multiple fonts
		return sameFont && isFullRange;
	}
	return YES;
}
- (NSMenu *)menuForEvent:(NSEvent *)theEvent {
	unsigned int attribs = [self textAttributes:nil];
	[[[self menu] itemWithTag:MI_SMALL] setState:attribs&FX_SMALL];
	[[[self menu] itemWithTag:MI_SUPER] setState:attribs&FX_SUPER];
	[[[self menu] itemWithTag:MI_SUB] setState:attribs&FX_SUB];
	
	NSMenu * fontMenu = [[self menu] itemWithTag:MI_FONTLIST].submenu;	// build font submenu
	[fontMenu removeAllItems];
	for (int index = 0; index < FONTLIMIT && *FF->head.fm[index].name; index++) {
		NSString * title = index == 0 ? @"Default Font" : [NSString stringWithUTF8String:FF->head.fm[index].name];
		[fontMenu insertItemWithTitle:title action: @selector(setFont:) keyEquivalent:@"" atIndex:index];
		[fontMenu itemAtIndex:index].tag = MI_DEFAULTFONT+index;
	}

	return [self menu];
}
- (BOOL)performKeyEquivalent:(NSEvent *)theEvent {
	NSString * kchars = [theEvent charactersIgnoringModifiers];
	unichar uchar = [kchars characterAtIndex:0];
	mflags = [theEvent modifierFlags];

	if (mflags&NSCommandKeyMask) {	// if cmnd-key (function keys don't necess need it to have Key Equivs)
		switch (uchar)		{
			case '\r':	// enter and close
				if ([(IRIndexRecordWController *)[self delegate] windowShouldClose:nil])
					[[self window] close];
				return YES;
			case '=':		// toggle label 1
				[(IRIndexRecordWController *)[self delegate] labeled:self];
				return YES;
			case 0x7f:			// delete to beginning of field
			case NSDeleteFunctionKey:	// delete to end of field
				[self keyDown:theEvent];	// pass to our key handler
				return YES;
			default:
				if (uchar >= NSF1FunctionKey && uchar <= NSF16FunctionKey && mflags&NSAlternateKeyMask) {	// if a function key with option
					if ([self selectedRange].length)	{	// if want to set one
						NSData * ddata = [[NSUserDefaults standardUserDefaults] objectForKey:CIFunctionKeys];
						NSMutableDictionary * kdic = [NSKeyedUnarchiver unarchiveObjectWithData:ddata];
						NSAttributedString * astring = [[self textStorage] attributedSubstringFromRange:[self selectedRange]];
											
						[kdic setObject:[astring normalizeAttributesWithMap:NULL] forKey:[NSString stringWithFormat:@"%d",uchar-NSF1FunctionKey]];
						[[NSUserDefaults standardUserDefaults] setObject:[NSKeyedArchiver archivedDataWithRootObject:kdic] forKey:CIFunctionKeys];	// set new set as default
						[[NSNotificationCenter defaultCenter] postNotificationName:NOTE_NEWKEYTEXT object:self];
						return YES;
					}
				}
		}
	}
	return [super performKeyEquivalent:theEvent];
}
- (void)mouseDown:(NSEvent *)theEvent {
	if (_errDisplay)	{	// if had error display
		[(IRIndexRecordWController *)[self delegate] displayError:nil];
		_errDisplay = FALSE;
	}
	[super mouseDown:theEvent];
}
#if 0
- (void)keyUp:(NSEvent *)theEvent {
	[[NSNotificationCenter defaultCenter] postNotificationName:NOTE_SCROLLKEYEVENT object:theEvent];
	[super keyUp:theEvent];
}
#endif
- (void)keyDown:(NSEvent *)theEvent {
	NSString * kchars = [theEvent characters];

	if ([kchars length]) {	// if not special input (e.g., diacritic mark)
		unichar uchar = [kchars characterAtIndex:0];
		unsigned int flags = [theEvent modifierFlags];
		NSRange selrange;
		NSRange selfields;
		unichar leftchar, rightchar;

		if (flags&NSControlKeyMask) {	// !! but for 10.4 bug would do this in performKeyEquivalent
			uchar = [[theEvent charactersIgnoringModifiers] characterAtIndex:0];	// get ignoring modifiers
			switch (uchar) {
				case 'f':
					[self defaultFont:self];	// set default font
					return;
				case '-':		// half flip
				case '_':		// half flip (shift down)
					[self _flipField:YES];
					return;
				case '=':		// full flip
				case '+':		// full flip (shift down)
					[self _flipField:NO];
					return;
				case 'b':		// braces
					[self _encloseBracketsOfType:MI_BRACES];
					return;
				case 'a':		// angle brackets
					[self _encloseBracketsOfType:MI_BRACKETS];
					return;
				case ']':		// increment/decrement
				case '[':		// increment/decrement
					[self _incDec:uchar == ']'];
					return;
				case 'p':
					[self _swapParens];
					return;
				default:
					if (uchar >= '0' && uchar <= '9')	// if want field from last record
						[self _insertPreviousField:uchar-'0'];
			}
			return;
		}
		if (uchar == NSDeleteCharacter || uchar == NSDeleteFunctionKey) {	// if either delete key
			[self _handleDeletion:(uchar == NSDeleteFunctionKey) event:theEvent];
			return;
		}
		selrange = [self selectedRange];
		selfields = [self _selectedFields];
		leftchar = [self leftCharacter];
		rightchar = [self rightCharacter];
		switch (uchar) {
			case NSEnterCharacter:	// enter key
				if (!(flags&NSAlternateKeyMask) && [(IRIndexRecordWController *)[self delegate] windowShouldClose:nil])	// (option-enter is close doc?)
					[[self window] close];
				return;
			case 0x1b:	// escape key
			case NSPageUpFunctionKey:
			case NSPageDownFunctionKey:
				[(IRIndexRecordWController *)[self delegate] keyDown:theEvent];
				return;
			case NSDownArrowFunctionKey:
				if (rightchar == '\n')
					[self _checkAbbreviation];
				break;
			case '\t':
				if (rightchar == '\n')
					[self _checkAbbreviation];
				selfields.location++;
				if (selfields.location >= _fieldCount)
					selfields.location = 0;
				[self setSelectedRange:NSMakeRange([[_fieldRanges objectAtIndex:selfields.location] rangeValue].location,0) ];
				return;
			case NSBackTabCharacter:		// back tab (shift-tab)
				selfields.location--;
				if (selfields.location >= _fieldCount)	// (negative overflow is big positive number)
					selfields.location = _fieldCount-1;
				[self setSelectedRange:NSMakeRange([[_fieldRanges objectAtIndex:selfields.location] rangeValue].location,0) ];
				return;
			case '\r':
				if (_completingSelection && (rightchar == '\n' || !rightchar)) // if need to autocomplete
					[self setSelectedRange:NSMakeRange(selrange.location+selrange.length,0)];	// don't replace current selection
				if (_fieldCount >= FF->head.indexpars.maxfields || _fieldCount > 1 && selfields.location >= _protectIndex) {
					// would make too many fields or would split page field
					NSBeep();
					return;
				}
				[self _checkAbbreviation];
				selrange = [self selectedRange];	// reset selection range
				leftchar = [self leftCharacter];	// and left and right chars
				rightchar = [self rightCharacter];
				if (leftchar == SPACE)	{	// if want to catch space
					selrange.location--;	// expand selection
					selrange.length++;
				}
				if (rightchar == SPACE)		// if want to catch space
					selrange.length++;
				if (!selrange.location || leftchar == '\n' || rightchar == '\n') // if should clear style
					[self setTypingAttributes:_defaultAttributes];
				[self setSelectedRange:selrange];
				break;
			default:
				if (uchar >= NSF1FunctionKey && uchar <= NSF16FunctionKey && flags&NSAlternateKeyMask) {	// if a function key
					[self _checkFunctionKey:uchar-NSF1FunctionKey];
					return;
				}
				if (!selrange.length && u_strchr(abbrev_suffix,uchar))	// if no selection and char might expand abbrev
					[self _checkAbbreviation];	// check it
				if (selfields.location == _fieldCount-1 && uchar == FF->head.refpars.rsep && g_prefs.gen.autorange && [self _extendRef])	// if want to autoextend ref
					return;
				if (g_prefs.gen.autoextend && (rightchar == '\n' || !rightchar) && selfields.length == 1 && textchar(uchar)) {	// if potential autocompletion
					[self _checkCompletion:theEvent];
					return;
				}
		}
		[super keyDown:theEvent];
		[self _fixBreaks];
		return;
	}
	[super keyDown:theEvent];
}
- (void)_handleDeletion:(BOOL)direction event:(NSEvent *)theEvent {
	NSRange selfields = [self _selectedFields];
	NSRange selrange = [self selectedRange];
	unichar leftchar = [self leftCharacter];
	unichar rightchar = [self rightCharacter];
	unichar lastselchar = [self lastSelectedCharacter];

	if (!selrange.length && (direction && rightchar == '\n' && (NSMaxRange(selfields) >= _protectIndex || _fieldCount == FF->head.indexpars.minfields)
		|| !direction && leftchar == '\n' && (selfields.location >= _protectIndex || _fieldCount == FF->head.indexpars.minfields)))	{	// if empty selection delete into or out of page (or removing below min)

		NSBeep();
		return;
	}
	if ([self _fixBreaks])	// if handled field deletions
		return;
	if ([theEvent modifierFlags]&NSCommandKeyMask) {		// if command del forward or backward
		if (direction)
			[self deleteToEndOfParagraph:self];
		else
			[self deleteToBeginningOfParagraph:self];
		return;
	}
	if ([theEvent modifierFlags]&NSAlternateKeyMask) {		// if word del forward or backward
		if (direction) {
			[self moveWordForwardAndModifySelection:self];
			if ([[self string] paragraphBreaksForRange:[self selectedRange]])	{	// if spanned para break
				[self setSelectedRange:selrange];	// restore original selection
				[self deleteToEndOfParagraph:self];	// only to end
			}
			else
				[self delete:self];
		}
		else {
			[self moveWordBackwardAndModifySelection:self];
			if ([[self string] paragraphBreaksForRange:[self selectedRange]])	{// if spanned para break
				[self setSelectedRange:selrange];	// restore original selection
				[self deleteToBeginningOfParagraph:self];	// only to start
			}
			else
				[self delete:self];
		}
		return;
	}
	if (direction && (!selrange.length && rightchar == '\n' && selrange.location && leftchar != '\n' || selrange.length == 1 && lastselchar == '\n'))	{	// forward delete newline, replace with space
		[self setSelectedRange:NSMakeRange(selrange.location,1)];
		[self insertText:@" "];
		return;
	}
	if (!direction && (!selrange.length && leftchar == '\n' && selrange.location > 1 && [[self string] characterAtIndex:selrange.location-2] != '\n' || selrange.length == 1 && lastselchar == '\n'))	{// backwards delete newline, replace with space
		if (!selrange.length)
			[self setSelectedRange:NSMakeRange(selrange.location-1,1)];
		[self insertText:@" "];
		return;
	}
	[super keyDown:theEvent];		// pass on
}
- (BOOL)_fixBreaks {	// fixes breaks
	NSRange selrange = [self selectedRange];
	int selbreaks = [[self string] paragraphBreaksForRange:selrange];
	NSRange selfields = [self _selectedFields];
	int need = FF->head.indexpars.minfields - (_fieldCount-selbreaks);

	if (need < 0)
		need = 0;
	if (selbreaks && !need && NSMaxRange(selfields) > _protectIndex)	// if would remove break before protected field
		need++;		// force retention
	if (need) { 	// if wouldn't have enough fields
		[self setTypingAttributes:_defaultAttributes];	// set default typing attributes for replacement
		[self insertText:[NSString stringWithFormat:@"%.*s",need, "\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n"]];	// make sure we restore min num fields
		[self setSelectedRange:NSMakeRange(selrange.location,0)];	// set to beginning of sel range
		return YES;
	}
	return NO;
}
- (NSRange)selectionRangeForProposedRange:(NSRange)proposedSelRange granularity:(NSSelectionGranularity)granularity {
	NSRange crange = [super selectionRangeForProposedRange:proposedSelRange granularity:granularity];
	// remove newline if it's last-selected character
//	NSLog(@"Selecting %@ : %@", NSStringFromRange(proposedSelRange),NSStringFromRange(crange));
	if (crange.length && [[self string] characterAtIndex:crange.location+crange.length-1] == '\n')
		crange.length--;
	return crange;
}
- (void)didChangeText {
	if (_errDisplay)	{	// if had error display
		[(IRIndexRecordWController *)[self delegate] displayError:nil];
		_errDisplay = FALSE;
	}
	[self _setFieldRanges];
	[super didChangeText];
}
#if 0
- (IBAction)insertUnicode:(id)sender {
	NSRange selrange = [self selectedRange];
	NSString * insert = @"\u200E";
	if ([self shouldChangeTextInRange:selrange replacementString:insert])	{
		[[self textStorage] replaceCharactersInRange:selrange withString:insert];
		[self didChangeText];
	}
}
#endif
- (IBAction)encloseText:(id)sender {
	[self _encloseBracketsOfType:[sender tag]];
}
- (void)_encloseBracketsOfType:(int)type	{
	NSRange selrange = [self selectedRange];
	NSMutableAttributedString * converted;
	
	if (type == MI_BRACES)
		converted = [[NSMutableAttributedString alloc] initWithString:@"{}"];
	else if (type == MI_BRACKETS) {
		converted = [[NSMutableAttributedString alloc] initWithString:@"<>"];
		if ([self leftCharacter] == SPACE && [self rightCharacter] == SPACE)
			selrange.length++;
			[self setSelectedRange:selrange];
	}
//	else 	// embedding right-left
//		converted = [[NSMutableAttributedString alloc] initWithString:@"\u202F\u202E"];
	[converted insertAttributedString:[[self textStorage] attributedSubstringFromRange:[self selectedRange]] atIndex:1];
	if ([self shouldChangeTextInRange:selrange replacementString:[converted string]])	{
		[self _replaceRangeOfCharacters:selrange withAttributedString:converted];
		selrange.length += 2;
		[self setSelectedRange:selrange];
	}
}
- (void)newAbbreviation:(id)sender {
	NSAttributedString * as = [[self textStorage] attributedSubstringFromRange:[self selectedRange]];
	[AbbreviationController showWithExpansion:as];
}
- (IBAction)copy:(id)sender {
	[super copy:sender];
	pbChangeCount = [NSPasteboard generalPasteboard].changeCount;
}
- (IBAction)cut:(id)sender {
	[super copy:sender];
	if (![self _fixBreaks])	// if didn't deal with breaks
		[super cut:sender];
}
- (IBAction)paste:(id)sender {
	NSRange baserange = self.selectedRange;
	
	baseAttributes = self.typingAttributes;	// restored by _normalizeRange
	if ([self _canPaste:[NSPasteboard generalPasteboard] drag:NO at:baserange.location]) {
		if ([self lastSelectedCharacter] == '\n')	// if paste would remove terminal newline
			self.selectedRange = NSMakeRange(baserange.location, baserange.length-1);	// shorten selection
		[super paste:sender];
		NSRange xr = self.selectedRange;
		while (u_iscntrl(xr.location >= 1 ? [[self string] characterAtIndex:xr.location-1] : 0))	// while trailing control characters (e.g., from PDF paste)
			xr.location--;
		if (xr.location != self.selectedRange.location)	{ 	// some extra trailing stuff to get rid of
			NSRange badRange = NSMakeRange(xr.location,self.selectedRange.location-xr.location);
			if ([self shouldChangeTextInRange:badRange replacementString:@""]) {
				[[self textStorage] deleteCharactersInRange:badRange];
				[self didChangeText];
			}
		}
		[self _normalizeRange:NSMakeRange(baserange.location,self.selectedRange.location-baserange.location)];
		[self _fixBreaks];
		return;
	}
	NSBeep();
}
- (IBAction)flipField:(id)sender {
	[self _flipField:[sender tag] != TB_FLIPFULL];	// full flip
}
- (IBAction)swapParens:(id)sender {
	[self _swapParens];
}
- (IBAction)defaultFont:(id)sender {
	_attributeChange = DA_DEFAULTFONT;
	[self changeAttributes:self];
}
- (IBAction)setFont:(id)sender {
	_attributeChange = (int)((NSMenuItem *)sender).tag;
	[self changeAttributes:self];
}
- (IBAction)plain:(id)sender {
	_attributeChange = DA_PLAIN;
	[self changeAttributes:self];
	[self setColorForLabel:_label];
}
- (IBAction)superscript:(id)sender {
	_attributeChange = DA_SUPER;
	[self changeAttributes:self];
}
- (IBAction)subscript:(id)sender {
	_attributeChange = DA_SUB;
	[self changeAttributes:self];
}
- (IBAction)smallscript:(id)sender {
	_attributeChange = DA_SMALL;
	[self changeAttributes:self];
}
- (IBAction)initialcaps:(id)sender {
	[self _changeCase:DC_INITIAL];
}
- (IBAction)uppercase:(id)sender {
	[self _changeCase:DC_UPPER];
}
- (IBAction)lowercase:(id)sender {
	[self _changeCase:DC_LOWER];
}
- (void)setIndex:(INDEX *)indexptr {
	int count;
	
	FF = indexptr;
	for (count = 0; count < FF->head.indexpars.maxfields; count++)	{
		if (*FF->head.indexpars.field[count].matchtext)		/* if need regex as template */
			_regex[count] = regex_build(FF->head.indexpars.field[count].matchtext,0);
	}
	_fontsize = g_prefs.gen.recordtextsize ? g_prefs.gen.recordtextsize : FF->head.privpars.size;
	if (!_fontsize)	{	// if want default user font size
		NSFont * sfont = [NSFont userFontOfSize:0];	// make font
		_fontsize = [sfont pointSize];	// get size
	}
	// following needed to set default attributes
	[[self textStorage] setAttributedString:[NSAttributedString asFromXString:" " fontMap:FF->head.fm size:_fontsize termchar:0]];
	self.defaultAttributes = [NSMutableDictionary dictionaryWithDictionary:[[self textStorage] attributesAtIndex:0 effectiveRange:nil]];
}
- (NSDictionary *)convertAttributes:(NSDictionary *)attributes {
	NSMutableDictionary * mdic = [NSMutableDictionary dictionaryWithDictionary:attributes];
	
	if (_attributeChange >= MI_DEFAULTFONT) {	// change to specified font
		NSFont * font = [attributes objectForKey:NSFontAttributeName];	// get active font
		NSString * fname = [NSString stringWithUTF8String:FF->head.fm[_attributeChange-MI_DEFAULTFONT].name];	// get new family name
		[mdic setObject:[[NSFontManager sharedFontManager] convertFont:font toFamily:fname] forKey:NSFontAttributeName];
	}
	else if (_attributeChange == DA_DEFAULTFONT) {	// restores default font
		NSFont * font = [attributes objectForKey:NSFontAttributeName];	// get active font
		NSString * fname = ((NSFont *)[_defaultAttributes objectForKey:NSFontAttributeName]).familyName;	// name of base font		
		[mdic setObject:[[NSFontManager sharedFontManager] convertFont:font toFamily:fname] forKey:NSFontAttributeName];
	}
	else if (_attributeChange == DA_PLAIN) {	// restores default formatting
		NSFont * dfont = [_defaultAttributes objectForKey:NSFontAttributeName];	// base is default font
		NSFont * font = [attributes objectForKey:NSFontAttributeName];	// will use this only for family
		
		[mdic removeObjectForKey:NSForegroundColorAttributeName];
		[mdic removeObjectForKey:NSUnderlineStyleAttributeName];
		[mdic removeObjectForKey:NSBaselineOffsetAttributeName];
		[mdic setObject:[[NSFontManager sharedFontManager] convertFont:dfont toFamily:[font familyName]] forKey:NSFontAttributeName];
	}
	else if (_attributeChange == DA_SMALL) {
		NSColor * color = [attributes objectForKey:NSBackgroundColorAttributeName];
		NSFont * font = [attributes objectForKey:NSFontAttributeName];
		if (color) {
			[mdic removeObjectForKey:NSBackgroundColorAttributeName];
			[mdic setObject:[[NSFontManager sharedFontManager] convertFont:font toSize:_fontsize] forKey:NSFontAttributeName];
		}
		else {
			[mdic setObject:[NSColor gridColor] forKey:NSBackgroundColorAttributeName];
			[mdic setObject:[[NSFontManager sharedFontManager] convertFont:font toSize:_fontsize*SMALLCAPSCALE] forKey:NSFontAttributeName];
		}
	}
	else {
		NSFont * font = [attributes objectForKey:NSFontAttributeName];
		NSNumber * offset = [attributes objectForKey:NSBaselineOffsetAttributeName];
		int offsetval = [offset intValue];
		
		if (_attributeChange == DA_SUPER)
			offsetval = offsetval > 0 ? 0 : _fontsize*SUPERRISE;
		else // sub
			offsetval = offsetval < 0 ? 0 : -_fontsize*SUBDROP;
		[mdic setObject:[NSNumber numberWithInt:offsetval] forKey:NSBaselineOffsetAttributeName];
		[mdic setObject:[[NSFontManager sharedFontManager] convertFont:font toSize:offsetval ? _fontsize*SUPSUBCALE : _fontsize] forKey:NSFontAttributeName];
	}
	return mdic;
}
- (void)setColorForLabel:(int)label	{		// sets text color per label
	NSColor * ccolor = [NSColor textColor];
	
	_label = label;		// save label for restoration after text manipulations
	if (label--)	// if has label
		ccolor = [NSColor colorWithCalibratedRed:g_prefs.gen.lcolors[label].red green:g_prefs.gen.lcolors[label].green blue:g_prefs.gen.lcolors[label].blue alpha:1];
	[self setTextColor:ccolor];
	[self.defaultAttributes setObject:ccolor forKey:NSForegroundColorAttributeName];
}
- (void)setText:(char *)recordtext label:(int)label{
	str_xcpy(_originalString,recordtext);	// save copy
	_recordLength = (int)str_xlen(_originalString);
	[[self textStorage] setAttributedString:[NSAttributedString asFromXString:recordtext fontMap:FF->head.fm size:_fontsize termchar:EOCS]];
	[self setColorForLabel:label];
	[self setSelectedRange:NSMakeRange(0,0)];
	[self didChangeText];
	[[self undoManager] removeAllActions];
	_completingSelection = FALSE;
}
- (void)textViewDidChangeSelection:(NSNotification *)aNotification	{
//	NSLog(@"Selection: %@",[aNotification description]);
	NSRange oldRange = [[aNotification.userInfo objectForKey:@"NSOldSelectedCharacterRange"] rangeValue];
	NSRange oldFieldRange = [self fieldRangeForTextRange:oldRange];
	NSRange newFieldRange = [self _selectedFields];
	if (!NSEqualRanges(oldFieldRange,newFieldRange))	{	// if any change in field
		_completingSelection = FALSE;	// kill any autocomplete
		if (newFieldRange.length == 1) {	// if selection is in single field, save attributes at start
			NSRange newFieldCharRange = [[_fieldRanges objectAtIndex:newFieldRange.location] rangeValue];
			self.completionAttributes = [self.textStorage attributesAtIndex:newFieldCharRange.location effectiveRange:NULL];
		}
	}
}
- (void)textViewDidChangeTypingAttributes:(NSNotification *)notification {
//	return;
//	NSLog(@"Attributes: %@",[notification description]);
	if ([self selectionIsEmptyField])
		self.completionAttributes = self.typingAttributes;
//	else
//		self.completionAttributes = nil;
}
- (BOOL)selectionIsEmptyField {
	return self.selectedRange.length == 0 && (!self.selectedRange.location || [self leftCharacter] == '\n') && ([self rightCharacter] == '\n' || ![self rightCharacter]);	// in empty field
}
- (char *)getText:(BOOL)check {
	if (!_locked)	{		// if don't have lock on text 
		[self _copyFromFontMap:FF->head.fm];
		_recordLength = [[self textStorage] convertToXString:_newString fontMap:_fontMap mode:CC_TRIM];
		rec_pad(FF,_newString);	// add if have empty page field
		if (check) {
			int fcount = rec_strip(FF,_newString);	/* strip empty fields */
			
			if (fcount < FF->head.indexpars.minfields)	{	/* if for any reason too few fields */
				senderr(INTERNALERR, WARN, "Lost Headings");
				return NULL;
			}
		}
		return _newString;
	}
	return NULL;
}
- (int)textLength	{
	return _recordLength;
}
- (unsigned int)textAttributes:(NSDictionary *) attr {
	unsigned int attributes = 0;
	
	if (!attr)
		attr = self.typingAttributes;
	NSNumber * offset = [attr objectForKey:NSBaselineOffsetAttributeName];
	NSNumber * color = [attr objectForKey:NSBackgroundColorAttributeName];
	NSFont * font = [attr objectForKey:NSFontAttributeName];
	NSNumber * underline = [attr objectForKey:NSUnderlineStyleAttributeName];
	NSFontTraitMask traits = [[NSFontManager sharedFontManager] traitsOfFont:font];
	
	if (traits&NSBoldFontMask)
		attributes |= FX_BOLD;
	if (traits&NSItalicFontMask)
		attributes |= FX_ITAL;
	if ([offset intValue] > 0)
		attributes |= FX_SUPER;
	if ([offset intValue] < 0)
		attributes |= FX_SUB;
	if (color != nil)
		attributes |= FX_SMALL;
	if (underline)
		attributes |= FX_ULINE;
	return attributes;
}
- (void)copyToFontMap:(FONTMAP *)fm {
	for (int findex = 0; findex < FONTLIMIT; findex++)
		fm[findex] = _fontMap[findex];
}
- (void)_setFieldRanges{
	_fieldRanges = [[self string] paragraphRanges];
	_fieldCount = (int)[_fieldRanges count];
	_protectIndex = FF->head.indexpars.required ? _fieldCount-2 : _fieldCount-1;
}
- (NSRange)_selectedFields {	// returns range of selected fields
	[self _setFieldRanges];
	return [self fieldRangeForTextRange:[self selectedRange]];
}
- (void)selectField:(int)field {
	NSRange range = [[_fieldRanges objectAtIndex:0] rangeValue];
	range.length -=1;
	[self setSelectedRange:range];
}
- (NSRange)fieldRangeForTextRange:(NSRange)tRange {	// returns first and last fields as range
	NSRange frange = NSMakeRange(_fieldCount-1,1);	// default value for off end of page field
	unsigned int index;
	
	for (index = 0; index < _fieldCount; index++) {
		NSRange fieldrange = [[_fieldRanges objectAtIndex:index] rangeValue];
		if (NSLocationInRange(tRange.location,fieldrange))	{// if this field contains start
			frange.location = index;
			frange.length = 1;
			if (!tRange.length)		// if selection is just entry point
				break;
		}
		if (NSMaxRange(tRange) > fieldrange.location)	// if selection runs beyond start of this field
			frange.length = index-frange.location+1;	// presumptively ends in this field (update on each pass)
		else
			break;
	}
//	NSLog(@"SFields: %@",NSStringFromRange(frange));

	return frange;
}
- (void)_flipField:(int)halfmode {
	NSRange sfields = [self _selectedFields];
	if (sfields.length == 1 && sfields.location < _fieldCount-1)		{	// if selection all in single field and not page field
		NSRange f1range = [[_fieldRanges objectAtIndex:sfields.location] rangeValue];
		NSRange f2range = [[_fieldRanges objectAtIndex:sfields.location+1] rangeValue];
		NSRange f1f2range = NSUnionRange(f1range,f2range);
		char * list = sfields.location < _fieldCount-2 ? FF->head.flipwords : FF->head.refpars.crosstart;
		int shiftstate = [[NSApp currentEvent] modifierFlags]&NSShiftKeyMask;
		BOOL smartstate = g_prefs.gen.smartflip && !shiftstate || !g_prefs.gen.smartflip && shiftstate;
		char xbuff[MAXREC];
		NSAttributedString * reptext;
		
		if (sfields.location < _fieldCount-2)	// if lower field isn't page field
			f1f2range.length -= 1;	// lose newline at end of second field (page field doesn't have one)
		[self _copyFromFontMap:FF->head.fm];
		[[[self textStorage] attributedSubstringFromRange:f1f2range] convertToXString:xbuff fontMap:_fontMap mode:CC_TRIM];	// recover xstring
		str_flip(xbuff, list,smartstate,halfmode,sfields.location == _fieldCount-2 );		// flip
		reptext = [NSAttributedString asFromXString:xbuff fontMap:FF->head.fm size:_fontsize termchar:EOCS];
		if ([self shouldChangeTextInRange:f1f2range replacementString:[reptext string]])	{
			[self _replaceRangeOfCharacters:f1f2range withAttributedString:reptext];
			[self setSelectedRange:NSMakeRange(f1f2range.location,0)];
		}
	}
}
- (void)_swapParens {	// swaps contents of parens
	NSRange sfields = [self _selectedFields];
	if (sfields.length == 1 && sfields.location < _fieldCount-1)		{	// if selection all in single field and not page field
		NSRange f1range = [[_fieldRanges objectAtIndex:sfields.location] rangeValue];
		char xbuff[MAXREC];
		NSAttributedString * reptext;
		
		f1range.length -= 1;	// lose newline at end of field
		[self _copyFromFontMap:FF->head.fm];
		[[[self textStorage] attributedSubstringFromRange:f1range] convertToXString:xbuff fontMap:_fontMap mode:CC_TRIM];	// recover xstring
		if (str_swapparen(xbuff, FF->head.flipwords,TRUE))			{	// if swapped
			reptext = [NSAttributedString asFromXString:xbuff fontMap:FF->head.fm size:_fontsize termchar:0];
			if ([self shouldChangeTextInRange:f1range replacementString:[reptext string]])	{
				[self _replaceRangeOfCharacters:f1range withAttributedString:reptext];
				[self setSelectedRange:NSMakeRange(f1range.location,0)];
			}
		}
	}
}
- (void)_incDec:(int)mode {	// increments/decrements last numerical component
	NSRange frange = [[_fieldRanges objectAtIndex:_fieldCount-1] rangeValue];
	char xbuff[MAXREC];
	char *base;

	[self _copyFromFontMap:FF->head.fm];
	[[[self textStorage] attributedSubstringFromRange:frange] convertToXString:xbuff fontMap:_fontMap mode:CC_TRIM];	// recover xstring
	base = ref_incdec(FF,xbuff,mode);
	if (base)	{
		NSRange selRange = [self selectedRange];
		NSRange tr = [[self string] rangeOfString:[NSString stringWithUTF8String:base] options:NSBackwardsSearch range:frange];
		
		if (tr.location != NSNotFound)	{
			NSString * reptext = [NSString stringWithUTF8String:base+strlen(base)+1];
			if ([self shouldChangeTextInRange:tr replacementString:reptext])	{
				[[self textStorage] replaceCharactersInRange:tr withString:reptext];
				[self didChangeText];
				if (selRange.length && NSIntersectionRange(selRange,tr).length)	// if had original sel range on changed number
					[self setSelectedRange:NSMakeRange(tr.location,reptext.length)];	// select new
			}
		}
	}
}
- (BOOL)_extendRef {	// adds upper element of range as lower+1
	NSRange frange = [[_fieldRanges objectAtIndex:_fieldCount-1] rangeValue];
	NSRange tr = [self selectedRange];
	char xbuff[MAXREC];
	char *base;
	

	if (tr.location == [[self textStorage] length])	{	// if at end of locator field
		[self _copyFromFontMap:FF->head.fm];
		[[[self textStorage] attributedSubstringFromRange:frange] convertToXString:xbuff fontMap:_fontMap mode:CC_TRIM];	// recover xstring
		base = ref_autorange(FF,xbuff);
		if (base)	{
			NSAttributedString * reptext = [NSAttributedString asFromXString:base fontMap:FF->head.fm size:_fontsize termchar:'\0'];
			if ([self shouldChangeTextInRange:tr replacementString:reptext.string])
				[self _replaceRangeOfCharacters:tr withAttributedString:reptext];
			return TRUE;
		}
	}
	return FALSE;
}
- (void)_changeCase:(int)mode {
	NSRange selrange = [self selectedRange];
	NSString * tstring = [[self string] substringWithRange:selrange];
	NSString * converted;
	unsigned int index;
	
	if (mode == DC_INITIAL)
		converted = [tstring capitalizedString];
	else if (mode == DC_UPPER)
		converted = [tstring uppercaseString];
	else
		converted = [tstring lowercaseString];

	if ([self shouldChangeTextInRange:selrange replacementString:tstring])	{
		for (index = 0; index < selrange.length; index++)
			if ([converted characterAtIndex:index] != [tstring characterAtIndex:index]) {
				[self replaceCharactersInRange:NSMakeRange(selrange.location+index,1) withString:[converted substringWithRange:NSMakeRange(index,1)]];
		}
		[self didChangeText];
		[self setSelectedRange:selrange];
	}
}
- (BOOL)checkErrors:(char *)rtext	{
	short err = 0;
	int findex;
	CSTR field[FIELDLIM];
	FIELDPARAMS * fiptr;
	int fcount = str_xparse(rtext, field);
	
	for (fiptr = FF->head.indexpars.field, findex = 0; findex < fcount; findex++, fiptr++)	{
		if (findex == fcount-1)		/* if last field */
			fiptr = &FF->head.indexpars.field[PAGEINDEX];	/* point to page field pars */
		if (fiptr->minlength && str_textlen(field[findex].str) < fiptr->minlength)	{	/* too few chars */
			err = sendwindowerr(TOOFEWCHARFIELD, WARN);
			break;
		}
		if (fiptr->maxlength && str_textlen(field[findex].str) > fiptr->maxlength)	{	/* too many chars */
			err = sendwindowerr(TOOMANYCHARFIELD, WARN);
			break;
		}
		if (*fiptr->matchtext && !regex_find(_regex[findex == fcount-1 ? PAGEINDEX : findex],field[findex].str,0,NULL)
			&& (g_prefs.gen.templatealarm == AL_REQUIRED || g_prefs.gen.templatealarm == AL_WARN && !_alarms[A_TEMPLATE]++))	{	/* if bad pattern match */
			err = sendwindowerr(BADPATTERNFIELD,WARN);
			break;
		}
		if (err = checkfield(field[findex].str,_alarms))	{	/* flag error */
			if (err == KEEPCS || err == ESCS)
				sendwindowerr(BADCODEFIELD,WARN,err == KEEPCS ? '~' : '\\');
			else
				sendwindowerr(MISMATCHFIELD,WARN,m_string[err-BRACES]);
			break;
		}
	}
	if (!err)	{	/* if individual fields OK */
		int length = str_xlen(rtext); 
		if (length > FF->head.indexpars.minfields)	{	/* check main head & page field if not empty rec */
			if (field[fcount-1].str-rtext == FF->head.indexpars.minfields-1) {	/* if empty as far as page */
				if (strcmp(field[fcount-1].str,str_xlast(_originalString)))	{	/* will be error if page field altered */
					err = sendwindowerr(EMPTYMAINFIELD,WARN);
					findex = 0;
				}
			}
			if (!err)	{	/* check page field */
				findex = fcount-1;
				if (str_xfindcross(FF,rtext,FALSE))	{
					char * estring;
					if (estring = search_testverify(FF,rtext))	{	// if bad crossref
						if (g_prefs.gen.crossalarm == AL_REQUIRED || g_prefs.gen.crossalarm == AL_WARN && !_alarms[A_CROSS]++)	// if an error						
							err = sendwindowerr(MISSINGCROSSREF,WARN,estring);
					}
				}
				else if ((!*field[fcount-1].str || ref_isinrange(FF,field[fcount-1].str, g_nullstr, g_nullstr,&err))
					&& (g_prefs.gen.pagealarm == AL_REQUIRED 	/* check missing page only on key */
					|| g_prefs.gen.pagealarm == AL_WARN && !_alarms[A_PAGE]++))	{	/* if missing page needs flagging */
					err = sendwindowerr(*field[fcount-1].str ? err : EMPTYPAGEFIELD,WARN);		/* bad/missing refs */
				}
				else			/* need to clear errors in case err flag set and we're actually ignoring */
					err = 0;
			}
			if (!err)	{	// check length
				if (length > FF->head.indexpars.recsize-1)	{	// if contents too long
					sendwindowerr(RECOVERFLOW, WARN);
					findex = 0;
					err = TRUE;
				}
			}
		}
		if (!err)	{	/* if ok */
			memset(&_alarms,0,sizeof(_alarms));
			return (FALSE);
		}
	}
	_errDisplay = err;
	[self setSelectedRange:[[_fieldRanges objectAtIndex:findex] rangeValue]];
	return (TRUE);
}
- (void)_checkFunctionKey:(int)keyindex {
	NSDictionary * kdic = [NSKeyedUnarchiver unarchiveObjectWithData:[[NSUserDefaults standardUserDefaults] objectForKey:CIFunctionKeys]];
	NSAttributedString * as = [kdic objectForKey:[NSString stringWithFormat:@"%d",keyindex]];
	
	if (as) {
		if (_recordLength + [[as string] length] < FF->head.indexpars.recsize)	 {	// if not too long
			if ([self shouldChangeTextInRange:[self selectedRange] replacementString:[as string]])	{
				[self _replaceRangeOfCharacters:[self selectedRange] withAttributedString:[as normalizeToBaseFont:FF->head.fm size:_fontsize]];
				[self setTypingAttributes:_defaultAttributes];
			}
		}
		else
			NSBeep();
	}
}
- (void)_checkAbbreviation {
	unsigned int baseindex = [self selectedRange].location;
	unsigned int charindex;
	
	for (charindex = baseindex; charindex; charindex--) {	// recover possible abbrev string
		unichar cc = [[self string] characterAtIndex:charindex-1];
		if (u_strchr(abbrev_prefix, cc))	// if we've hit a prefix char
			break;
	}
	if (baseindex > charindex) {	// if have some range to test
		NSRange abbrevrange = NSMakeRange(charindex, baseindex-charindex);
		NSString * abbrev = [[self string] substringWithRange:abbrevrange];
		NSAttributedString * as = [[IRdc abbreviations] objectForKey:abbrev];
		
		if (as) {
			if (_recordLength + [[as string] length] < FF->head.indexpars.recsize)	 {	// if not too long
				if ([self shouldChangeTextInRange:abbrevrange replacementString:[as string]])	{
					NSDictionary * currentattributes = [self typingAttributes];	// save current text attributes
					[self _replaceRangeOfCharacters:abbrevrange withAttributedString:[as normalizeToBaseFont:FF->head.fm size:_fontsize]];
					[self setTypingAttributes:currentattributes];		// restore current attributes
				}
			}
			else
				NSBeep();
		}
	}
}
- (void)_checkCompletion:(NSEvent *)theEvent {
	unichar uchar = [[theEvent characters] characterAtIndex:0];
	NSRange curselrange = self.selectedRange;;
	RECORD * hitptr;
	char tstring[MAXREC], *baseptr, *xptr;
	CSTR s1[FIELDLIM];
	int s1count, tsort;
	NSRange selfields;
	BOOL isCrossref = NO;
	
	if (curselrange.length)	{	// if have anything selected
		unichar selchar = [[self string] characterAtIndex:curselrange.location];
		if (uchar == selchar || g_prefs.gen.autoignorecase && u_tolower(selchar) == u_tolower(uchar)) {	// if new character matches first in selection range
			[self setSelectedRange:NSMakeRange(curselrange.location+1,curselrange.length-1)];
			return;		// continuing match in current selection range
		}
		// if we're replacing some selection with a new character, and not at start of field, set attributes from char before selection
		if (curselrange.location && [self leftCharacter] != '\n')
			[self setTypingAttributes:[[self textStorage] attributesAtIndex:curselrange.location-1 effectiveRange:nil]];
	}
	selfields = [self _selectedFields];
	[super keyDown:theEvent];		// do replace selection with new character
	curselrange = self.selectedRange;;		// get new range (in case inserted special char -- e.g., after diacritical)
	[self _copyFromFontMap:FF->head.fm];
	[[self textStorage] convertToXString:tstring fontMap:_fontMap mode:CC_TRIM];
	rec_pad(FF,tstring);	// add if have empty page field
	str_xparse(tstring,s1);			/* parse string */
	s1count = selfields.location;
	if (selfields.location == _fieldCount-1)	{	// if page field
		if (str_crosscheck(FF,s1[s1count].str))	{	// if cross ref
			baseptr = str_skiplistmax(s1[s1count].str, FF->head.refpars.crosstart);	// get to end of xref lead
			isCrossref = YES;
		}
		else
			baseptr = g_nullstr;
	}
	else
		baseptr = tstring;
	xptr = s1[s1count].str+s1[s1count].ln;		/* NULL at end of last text field */
	if (s1[s1count].ln > 1)	{			/* if could have had trailing codes */
		while (iscodechar(*(xptr-2)))	/* pass back over any codes */
			xptr -= 2;
	}
	if (uchar == SPACE)		/* if field had terminal space (now stripped) */
		*xptr++ = uchar;		/* restore it */
	s1[s1count].ln = xptr - s1[s1count].str;	/* reset length */
	*xptr++ = '\0';			/* terminate string */
	*xptr = EOCS;
	tsort = FF->head.sortpars.ison;
	FF->head.sortpars.ison = TRUE;		/* sort is always on for lookup */
	hitptr = *baseptr ? search_treelookup(FF,baseptr) : NULL;
	FF->head.sortpars.ison = tsort;
	NSRange newrange = [[_fieldRanges objectAtIndex:s1count] rangeValue];	// text range for field we're in
	if (hitptr)	{	// if not leading space && content matches a record
		CSTR s2[FIELDLIM];
		int sourcefield = -1;		// assume no match
		
//		NSLog(@"%s",hitptr->rtext);
		str_xparse(hitptr->rtext,s2);		/* parse new text */
		if (selfields.location < _fieldCount-1)	{	/* if not page field */
			if ((g_prefs.gen.autoignorecase && !str_texticmp(s1[s1count].str,s2[s1count].str) || !strncmp(s1[s1count].str,s2[s1count].str,s1[s1count].ln))	/* if match on last text field */
				&& (!s1count || !col_match(FF,&FF->head.sortpars,s1[s1count-1].str,s2[s1count-1].str,MATCH_IGNORECODES|MATCH_IGNORECASE)))	{ /* and is first field or prev is full match */
				sourcefield = s1count;
			}
		}
		else if (isCrossref && (g_prefs.gen.autoignorecase && !str_texticmp(baseptr,s2[0].str) || !strncmp(baseptr,s2[0].str,strlen(baseptr))))	{/* if match on first text field */
			*baseptr = '\0';	/* terminate lead to cross-ref */
			newrange.location += str_utextlen(s1[s1count].str,-1);		// offset start by length of cross-ref lead (need to count uchars 4/17/2017)
			sourcefield = 0;	// ensure we pick main heading as potential cross-ref
		}
		if (sourcefield >= 0)	{		/* if matched field */
			char * xsptr;
			int xsattr = [self textAttributes:_completionAttributes];
			if (xsattr) {
				char xstring[MAXREC];
				xsptr = xstring;
				*xsptr++ = CODECHR;
				*xsptr++ = xsattr;
				strcpy(xsptr,s2[sourcefield].str);
				xsptr += strlen(xsptr);
				*xsptr++ = CODECHR;
				*xsptr++ = xsattr|FX_OFF;
				*xsptr = '\0';
				xsptr = xstring;
			}
			else
				xsptr = s2[sourcefield].str;
			NSAttributedString * as = [NSAttributedString asFromXString:xsptr fontMap:FF->head.fm size:_fontsize termchar:0];
			NSRange replacementrange = NSMakeRange(newrange.location,curselrange.location-newrange.location);
			
			if ([self shouldChangeTextInRange:replacementrange replacementString:[as string]])	{
				[self _replaceRangeOfCharacters:replacementrange withAttributedString:as];
				[self setSelectedRange:NSMakeRange(curselrange.location,self.selectedRange.location-curselrange.location)];
				_completingSelection = TRUE;
				if (g_prefs.gen.tracksource && !sort_isignored(FF, hitptr)) {	/* if tracking source && record viewable */
					_locked = TRUE;
					[FF->owner selectRecord:hitptr->num range:NSMakeRange(0,0)];
					_locked = FALSE;
				}
			}
		}
	}
	else if (_completingSelection){		// no match after having found one; make sure any text has default attributes restored
		if (g_prefs.gen.autoignorecase) {
			if (selfields.location <_fieldCount-1)	// if not in page field
				newrange.length -=1;		// stop before newline
			else if (isCrossref) {
				*baseptr = '\0';	/* terminate lead to cross-ref */
				newrange.location += str_utextlen(s1[s1count].str,-1);		// offset start by length of cross-ref lead
			}
			if ([self textAttributes:_completionAttributes])
				[self.textStorage setAttributes:_completionAttributes range:newrange];
			[self setSelectedRange:NSMakeRange(newrange.location+newrange.length,0)];
		}
		_completingSelection = FALSE;
	}
}
- (void)_insertPreviousField:(int)keyindex	{
	RECORD * recptr = rec_getrec(FF,FF->lastedited);
	
	if (recptr)	{	/* if can get record */
		CSTR fstrings[FIELDLIM];
		int fcount = str_xparse(recptr->rtext,fstrings);	/* parse search string */
		
		if (keyindex < fcount && fstrings[keyindex].ln)	{	// if desired field exists && contains text
			NSRange selfields = [self _selectedFields];
			if (--keyindex < 0)			/* if want page field */
				keyindex = fcount-1;	/* fix its index */
			if (NSMaxRange(selfields) < _fieldCount || selfields.length == 1)	{	// if not multifield selection into page field
				NSAttributedString * fieldstring = [NSAttributedString asFromXString:fstrings[keyindex].str fontMap:FF->head.fm size:_fontsize termchar:0];
				[self setTypingAttributes:_defaultAttributes];
				[self insertText:fieldstring];
				[self _fixBreaks];
				return;
			}
		}
	}
	NSBeep();
}
- (void)concludeDragOperation:(id <NSDraggingInfo>)sender {	
	if ([sender draggingSource] != self) {
		NSRange selrange = [self selectedRange];
		[self _normalizeRange:selrange];
		[self setSelectedRange:selrange];
		[[self window] makeKeyAndOrderFront:self];
	}
	[super concludeDragOperation:sender];
}
- (NSDragOperation)draggingUpdated:(id <NSDraggingInfo>)sender {
	if ([[sender draggingSource] isKindOfClass:[IRIndexView class]])	// if dragging from index view
		return NSDragOperationNone;
	if ([sender draggingSource] != self || [sender draggingSourceOperationMask] == NSDragOperationCopy) {	// if not moving within sender
		NSPasteboard * pb = [sender draggingPasteboard];
		NSRect pr = NSZeroRect;
		pr.origin = [sender draggingLocation];
		NSRect loc = [[self window] convertRectToScreen:pr];	// get loc in screen coordinates
//		NSPoint loc = [[self window] convertBaseToScreen:[sender draggingLocation]];	// get loc in screen coordinates
		NSUInteger index = [self characterIndexForPoint:loc.origin];	// get character index
		
		if ([self _canPaste:pb drag:YES at:index])
			return [super draggingUpdated:sender];
		return NSDragOperationNone;
	}
	return [super draggingUpdated:sender];
}
- (NSString *)preferredPasteboardTypeFromArray:(NSArray *)availableTypes restrictedToTypesFromArray:(NSArray *)allowedTypes {
	BOOL wantplain;
	if ([NSPasteboard generalPasteboard].changeCount == pbChangeCount)	// if we pasted data
		wantplain = !(mflags&NSControlKeyMask) && (mflags&NSShiftKeyMask);
	else		// toggle as relevant by prefs
		wantplain = !(mflags&NSControlKeyMask) && ((mflags&NSShiftKeyMask) && g_prefs.gen.pastemode != PASTEMODE_PLAIN || !(mflags&NSShiftKeyMask) && g_prefs.gen.pastemode == PASTEMODE_PLAIN);
	if (wantplain && [availableTypes indexOfObject:NSStringPboardType])
		return NSStringPboardType;	// paste plain text
	else
		return [super preferredPasteboardTypeFromArray:availableTypes restrictedToTypesFromArray:allowedTypes];
}
- (BOOL)_canPaste:(NSPasteboard *)pb drag:(BOOL)drag at:(unsigned int)index {
	NSString * tstring = [pb stringForType:NSStringPboardType];
	
	if (tstring) {
		unsigned int addedbreaks = [tstring paragraphBreaks];
		unsigned int addedlength = [tstring length];
		if (!drag)	{	// if pasting, discount existing selection
			NSRange selrange = self.selectedRange;
			addedbreaks -= [[self string] paragraphBreaksForRange:selrange];
			addedlength -= selrange.length;
		}
		if (!addedbreaks || addedbreaks + _fieldCount <= FF->head.indexpars.maxfields && // if no breaks, or within maxfields
			index < [[_fieldRanges objectAtIndex:_protectIndex] rangeValue].location) {	// and not in protected field
			if (_recordLength + addedlength < FF->head.indexpars.recsize)	// if not too long
				return YES;
		}
	}
	return NO;
}
- (void)_normalizeRange:(NSRange)range {
	NSAttributedString * as = [[self textStorage] attributedSubstringFromRange:range];
	NSAttributedString * ts;
	BOOL wantstyle;
	
	if ([NSPasteboard generalPasteboard].changeCount == pbChangeCount)	// if we pasted data
		wantstyle = mflags&NSControlKeyMask;
	else	// toggle as relevant by prefs
		wantstyle = (mflags&NSControlKeyMask) && g_prefs.gen.pastemode != PASTEMODE_STYLEONLY || !(mflags&NSControlKeyMask) && g_prefs.gen.pastemode == PASTEMODE_STYLEONLY;
	if (wantstyle)
		ts = [as normalizeToBaseFont:FF->head.fm size:_fontsize];
	else
		ts = [as normalizeAttributesWithMap:FF->head.fm size:_fontsize];
	if ([self shouldChangeTextInRange:range replacementString:ts.string])
		[self _replaceRangeOfCharacters:range withAttributedString:ts];
	self.typingAttributes = baseAttributes;		// restore attributes
}
- (void)_replaceRangeOfCharacters:(NSRange)range withAttributedString:(NSAttributedString *)as {
	[[self textStorage] replaceCharactersInRange:range withAttributedString:as];
	[self setColorForLabel:_label];	// reset current label
	[self didChangeText];
}
- (void)_copyFromFontMap:(FONTMAP *)fm {
	for (int findex = 0; findex < FONTLIMIT; findex++)
	_fontMap[findex] = fm[findex];
}
@end
/****************************************************************************/
static short checkfield(unsigned char * source, short *alarms)		/* checks record field */

{
	short bcount, brcount, parencnt, sqbrcnt, qcnt, dqcnt, parenbad, sqbrbad, qbad;
	unichar uc;

	bcount = brcount = parencnt = sqbrcnt = qcnt = dqcnt = parenbad = sqbrbad = qbad = 0;

	while (*source)     {       	/* for all chars in string */
		uc = u8_nextU((char **)&source);
		switch (uc)      {      /* check chars */
			case CODECHR:
			case FONTCHR:
				if (!*source++)			// skip code; if end of line
					return (CCODES);	/* error return (should never happen) */
				continue;
			case KEEPCHR:       	/* next is char literal */
				if (!*source)    /* if no following char */
					return (KEEPCS);       /* error return */
				source = u8_forward1(source);	// skip protected char
				continue;   	/* round for next */
			case ESCCHR:       	/* next is escape seq */
				if (!*source)    /* if at end of line */
					return (ESCS);     /* return error */
				source = u8_forward1(source);	// skip protected char
				continue;
			case OBRACE:        /* opening brace */
				if (bcount++)
					goto end;
				continue;
			case CBRACE:      /* closing brace */
				if (--bcount)
					goto end;
				continue;
			case OBRACKET:       /* opening < */
				if (brcount++)
					goto end;
				continue;
			case CBRACKET:      /* closing > */
				if (--brcount)
					goto end;
				continue;
			case '(':       /* opening paren */
				parencnt++;
				continue;
			case ')':       /* closing paren */
				if (--parencnt < 0)     /* if closing ever precedes opening */
					parenbad++;
				continue;
			case '[':       /* opening sqbr */
				sqbrcnt++;
				continue;
			case ']':       /* closing sqbr */
				if (--sqbrcnt < 0)      /* if closing ever precedes opening */
					sqbrbad++;
				continue;
			case OQUOTE:       /* opening quote */
				qcnt++;
				continue;
			case CQUOTE:       /* closing quote */
				if (--qcnt < 0)      /* if closing ever precedes opening */
					qbad++;
				continue;
			case '"':       /* dquote */
				dqcnt++;
				continue;
		}
	}
end:
	if (bcount)
		return (BRACES);
	if (brcount)
		return (BRACKETS);
	if ((parencnt || parenbad) && !alarms[A_PAREN]++)   /* if mismatched parens */
		return (PAREN);
	if ((sqbrcnt || sqbrbad) && !alarms[A_SQBR]++)   /* if mismatched sqbr */
		return (SQBR);
	if ((qcnt || qbad) && !alarms[A_QUOTE]++)   /* if mismatched curly quotes */
		return (QUOTE);
 	if (dqcnt&1 && !alarms[A_DQUOTE]++)   /* if mismatched simple quotes */
		return (DQUOTE);
	return (FALSE);
}

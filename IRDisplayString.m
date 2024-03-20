//
//  IRDisplayString.m
//  Cindex
//
//  Created by PL on 4/9/05.
//  Copyright 2005 Indexing Research. All rights reserved.
//

#import "IRDisplayString.h"
#import "IRIndexDocument.h"
#import "drafttext.h"
#import "formattedtext.h"
#import "commandutils.h"
#import "search.h"
#import "strings_c.h"

NSString * IRHeadingLevelKey = @"IRHeadingLevel";
NSString * IRRecordNumberKey = @"IRRecordNumber";
NSString * IRRecordInfoKey = @"IRRecordInfoKey";

@interface IRDisplayString (PrivateMethods)
- (void)_makeDictionaryForHeading:(int)index characterIndex:(int)charindex;
- (void)_setHeadings:(NSMutableArray *)headings;
- (void)_setHeadingParagraphs:(NSMutableArray *)paras;
- (void)_configureForHeadings:(int)levels;
@end

@implementation IRDisplayString
+ (void)initialize {
	;
}
- (id)initWithIRIndex:(IRIndexDocument *)doc paragraphs:paragraphs record:(RECN)record {
	if (self = [super init]) {
		FF = [doc iIndex];
		_fullviewmode = FF->head.privpars.vmode == VM_FULL;
		_record = record;
		RECORD * recptr = _fullviewmode ? form_getrec(FF, record) :  rec_getrec(FF, record);
		
		if (recptr) {
			[self _setHeadingParagraphs:paragraphs];
			[self _configureForHeadings:FIELDLIM + 1];	// add 1 level for alpha header
			if (_fullviewmode)	{
				form_buildentry(FF,recptr,&_entryinfo);
				_as = astr_fromformattedUTF8string(FF->formBuffer,&FF->head,ATS_STRIP);
			}
			else {
				char * tbuffer = malloc(MAXREC+500)+2;	// buffer is prefixed by 2 empty chars for addressing underflow (e.g., transposepunt)
				draft_buildentry(FF,tbuffer,recptr,&_entryinfo.ulevel);
				_entryinfo.consumed = 1;		// makes sure set to one record
				_as = astr_fromformattedUTF8string(tbuffer,&FF->head,0);
				free(tbuffer-2);
			}
			_as->string[_as->length++] = '\n';	// add terminating newline to display string
			return self;
		}
	}
	return nil;
}
- (void)dealloc {
	[self _setHeadings:nil];
	[self _setHeadingParagraphs:nil];
	astr_free(_as);
}
- (NSUInteger)length {
	return _as->length;
}
- (unichar)characterAtIndex:(NSUInteger)index {
	unichar uc = _as->string[index];
	ATTRIBUTES attribs;

	if (index >= _as->length)
		[NSException raise:IRDocumentException format:@"Character index %lu beyond string",(unsigned long)index]; 
	if (uc == FO_LEVELBREAK)
		return '\n';
	if (uc == FO_RPADCHAR)
		return '\t';
	if (uc == FO_ELIPSIS)
		uc = ELIPSIS;
	memset(&attribs,0,sizeof(ATTRIBUTES));
	astr_attributesatindex(_as,index,&attribs);	// get attrbutes
	if (attribs.attr&FX_SMALL && u_islower(uc))
		return u_toupper(uc);
	return uc;
}
- (void)getCharacters:(unichar *)buffer range:(NSRange)aRange {	
	unsigned int limit = aRange.location+aRange.length;
	ATTRIBUTES attribs;
	NSUInteger attribspan = 0;
	
	if (limit > _as->length)
		[NSException raise:IRDocumentException format:@"Character range %@ beyond string",NSStringFromRange(aRange)]; 
	memset(&attribs,0,sizeof(ATTRIBUTES));
	while (aRange.location < limit)	{
		*buffer = _as->string[aRange.location];
		if (*buffer == FO_LEVELBREAK)
			*buffer = '\n';
		if (*buffer == FO_RPADCHAR)
			*buffer = '\t';
		if (*buffer == FO_ELIPSIS)
			*buffer = ELIPSIS;
		if (attribspan == aRange.location)	{	// if don't have attributes for this location
			memset(&attribs,0,sizeof(ATTRIBUTES));
			attribspan = aRange.location+astr_attributesatindex(_as,aRange.location,&attribs);	// get attributes so we can deal with small caps
		}
		if (attribs.attr&FX_SMALL && u_islower(*buffer))
			*buffer = u_toupper(*buffer);
		aRange.location++;
		buffer++;
	}
}
- (NSDictionary *)attributesAtIndex:(NSUInteger)index effectiveRange:(NSRangePointer)aRange {
	int headinglevel;
	int span;
	
	if (index >= _as->length)
		[NSException raise:IRDocumentException format:@"Attribute range %@ beyond string",NSStringFromRange(*aRange)];
	headinglevel = astr_levelatindex(_as,index)+_entryinfo.ulevel;	// find heading level for index
	if (headinglevel > 0 && FF->head.formpars.ef.itype == FI_SPECIAL && headinglevel == _entryinfo.llevel)	// if special indent
		headinglevel = FF->head.indexpars.maxfields-2;		// drive lowest-level indent
	astr_setattributesforheading(_as,headinglevel,&_attributes);	// initialize with heading attributes
	span = astr_attributesatindex(_as,index,&_attributes);	// add attributes at index, and their span
	if (_attributes.attr&FX_SMALL) {	// if small caps -- special handling for size
		int tspan;
		for (tspan = 0; tspan < span && !u_islower(_as->string[index+tspan]); tspan++)	// find length of run that's not lowercase
			;
		if (tspan)		// some run exists; remove small caps
			_attributes.attr &= ~FX_SMALL;	// remove small caps
		else	{	// legit lower case; find length of run
			while (u_islower(_as->string[index+tspan]) && tspan < span)
				tspan++;
		}
		span = tspan;
	}
	if (aRange) {	// if want range returned
		aRange->location = index;
		aRange->length = span;
	}
	[self _makeDictionaryForHeading:headinglevel characterIndex:index];		// rebuild dictionary
	return [_iHeadings objectAtIndex:headinglevel+1];	// return right dictionary (index offset for alpha header)
}
- (NSDictionary *)attributesAtIndex:(NSUInteger)index longestEffectiveRange:(NSRangePointer)aRange inRange:(NSRange)rangeLimit{
	NSDictionary * tdic = [self attributesAtIndex:index effectiveRange:aRange];
	
	*aRange = NSIntersectionRange(*aRange,rangeLimit);
	return tdic;
}
- (void)_makeDictionaryForHeading:(int)index characterIndex:(int)charindex {
	// assume index is -1 based for alpha header
	NSMutableDictionary * adic = [[NSMutableDictionary alloc] initWithCapacity:7];
	NSString * fname = [NSString stringWithUTF8String:_attributes.fmp[currentfont(&_attributes)].name];
	float fsize = _attributes.nsize;
	int traits = 0;
	float offset = 0;
	NSFont * ff;
	
	if (_attributes.attr&FX_BOLD)
		traits |= NSBoldFontMask;
	if (_attributes.attr&FX_ITAL)
		traits |= NSItalicFontMask;
	if (_attributes.attr&FX_SMALL)
		fsize *= SMALLCAPSCALE;		// this does our faking of small caps
	if (_attributes.soffset > 0)	{	// if super
		offset = _attributes.nsize*SUPERRISE;
		fsize *= SUPSUBCALE;
	}
	else if (_attributes.soffset < 0)	{
		offset = -_attributes.nsize*SUBDROP;
		fsize *= SUPSUBCALE;
	}
	
	ff = [[NSFontManager sharedFontManager] fontWithFamily:fname traits:traits weight:5 size:fsize];
#if 0
	if (traits&NSBoldFontMask)		// circumvent Leopard bug that drops bold in call to fontWithFamily
		ff = [[NSFontManager sharedFontManager] convertFont:ff toHaveTrait:NSBoldFontMask];
#endif
	if (!ff)	{		// doesn't support a requested trait (bold or italic)
		if (![[NSFontManager sharedFontManager] fontNamed:fname hasTraits:NSBoldFontMask&traits])	// if can't do boldface
			traits &= ~NSBoldFontMask;
		if (![[NSFontManager sharedFontManager] fontNamed:fname hasTraits:NSItalicFontMask&traits])	// if can't do italics
			traits &= ~NSItalicFontMask;
		ff = [[NSFontManager sharedFontManager] fontWithFamily:fname traits:traits weight:5 size:fsize];	// get font for what's possible
	}
	if (!ff)	{
		NSLog(@"Record: %u; Heading: %d; font:%d (%s)", _record, index, currentfont(&_attributes), _attributes.fmp[currentfont(&_attributes)].name );
		NSLog(@"Bad font");
		ff = [[NSFontManager sharedFontManager] fontWithFamily:@"Times" traits:0 weight:5 size:fsize];	// get font for what's possible
	}
	[adic setObject:ff forKey:NSFontAttributeName];
	if (offset)
		[adic setObject:[NSNumber numberWithFloat:offset] forKey:NSBaselineOffsetAttributeName];
	if (_attributes.attr&FX_ULINE)
		[adic setObject:[NSNumber numberWithInt:1] forKey:NSUnderlineStyleAttributeName];
	if (_attributes.color)	{	// color will default to black
		if (_attributes.color == LEADCOLOR)	// lead color
			[adic setObject:[NSColor leadColor] forKey:NSForegroundColorAttributeName];
		else	{
			int color = _attributes.color-1;	// get base index;
			[adic setObject:[NSColor colorWithCalibratedRed:g_prefs.gen.lcolors[color].red green:g_prefs.gen.lcolors[color].green blue:g_prefs.gen.lcolors[color].blue alpha:1] forKey:NSForegroundColorAttributeName];
		}
	}
	else
		[adic setObject:[NSColor textColor] forKey:NSForegroundColorAttributeName];
	[adic setObject:[_iHeadingParagraphs objectAtIndex:index+1] forKey:NSParagraphStyleAttributeName];
	[adic setObject:[NSNumber numberWithInt:index] forKey:IRHeadingLevelKey];	// what happens for -1?
	[adic setObject:[NSData dataWithBytes:&_entryinfo length:sizeof(ENTRYINFO)] forKey:IRRecordInfoKey];
	[adic setObject:[NSNumber numberWithInt:_record] forKey:IRRecordNumberKey];
	[_iHeadings replaceObjectAtIndex:index+1 withObject:adic];
}
- (void)_setHeadings:(NSMutableArray *)headings {
	_iHeadings = headings;
}
- (void)_setHeadingParagraphs:(NSMutableArray *)paras {
	_iHeadingParagraphs = paras;
}
- (void)_configureForHeadings:(int)levels {
	int count;
	
	[self _setHeadings:[[NSMutableArray alloc] initWithCapacity:20]];
	for (count = 0; count < levels; count++)	// build array for heading dictionaries
		[_iHeadings addObject:[NSNull null]];
}
- (RECN)record {
	return _record;
}
- (INDEX *)index {
	return FF;
}
- (ATTRIBUTEDSTRING *)attributedText {
	return _as;
}
- (ENTRYINFO *)entryInformation {
	return &_entryinfo;
}
@end

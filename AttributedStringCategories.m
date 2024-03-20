//
//  AttributedStringCategories.m
//  Cindex
//
//  Created by PL on 3/27/05.
//  Copyright 2005 Indexing Research. All rights reserved.
//

#import "AttributedStringCategories.h"
#import "attributedstrings.h"
#import "strings_c.h"
#import "type.h"

@implementation NSAttributedString (AttributedStringCategories)

+ (NSAttributedString *)asFromXString:(char *)string fontMap:(FONTMAP *)fm size:(float)size termchar:(unsigned char)echar {	// makes attributed string from xstring
	int traits = 0;
	float basesize = size ? size : 12;
	NSString * fname;
	NSString * ts;
	NSFont * ff;
	NSMutableAttributedString * as;
	int count;
	float fsize;
	
	// build text string
	ATTRIBUTEDSTRING * asp = astr_fromUTF8string(string,(echar == EOCS ? ATS_XSTRING|ATS_NEWLINES : 0));
	
	ts = [[NSString alloc] initWithCharacters:asp->string length:asp->length];
	as = [[NSMutableAttributedString alloc] initWithString:ts];

	// now set default attributes
	fname = fm ? [NSString stringWithUTF8String:fm[0].name] : @"Helvetica";	// start with default font;
	ff = [[NSFontManager sharedFontManager] fontWithFamily:fname traits:0 weight:5 size:basesize];
//	NSLog([ff description]);
	[as addAttribute:NSFontAttributeName value:ff range:NSMakeRange(0, asp->length)];
	
	for (count = 0; count < asp->codecount; count++)	{	// add attributes
		char code = asp->codesets[count].code;
		NSRange frange = NSMakeRange(asp->codesets[count].offset, asp->length-asp->codesets[count].offset);
		
		fsize = basesize;		// assume default font size
		if (code & FX_AUTOFONT)	{	// font change
			code &= ~FX_AUTOFONT;
			if (code & FX_COLOR) {
				unsigned char color = code & FX_COLORMASK;
				NSColor *lcolor;
				
				if (color--)	// if one to choose
					lcolor = [NSColor colorWithCalibratedRed:g_prefs.gen.lcolors[color].red green:g_prefs.gen.lcolors[color].green blue:g_prefs.gen.lcolors[color].blue alpha:1];
				else
					lcolor = [NSColor textColor];
				[as addAttribute:NSBackgroundColorAttributeName value:lcolor range:frange];
			}
			else if (fm)		// if care about fonts
				fname = [NSString stringWithUTF8String:fm[code&FX_FONTMASK].name];
		}
		else if (code&FX_OFF) {					
			if (code & FX_BOLD) 
				traits &= ~NSBoldFontMask;
			if (code & FX_ITAL)
				traits &= ~NSItalicFontMask;
			if (code & FX_ULINE)
				[as removeAttribute:NSUnderlineStyleAttributeName range:frange];
			if (code & FX_SMALL)
				[as removeAttribute:NSBackgroundColorAttributeName range:frange];
			if (code & FX_SUPER)
				[as removeAttribute:NSBaselineOffsetAttributeName range:frange];
			if (code & FX_SUB)
				[as removeAttribute:NSBaselineOffsetAttributeName range:frange];
		}
		else {		// turning on
			if (code & FX_BOLD) 
				traits |= NSBoldFontMask;
			if (code & FX_ITAL)
				traits |= NSItalicFontMask;
			if (code & FX_ULINE)
				[as addAttribute:NSUnderlineStyleAttributeName value:[NSNumber numberWithInt:1] range:frange];
			if (code & FX_SMALL)	{
//				traits |= NSSmallCapsFontMask;	// few fonts support; use as token for explicit size change
//				[as addAttribute:NSBackgroundColorAttributeName value:[NSColor windowBackgroundColor] range:frange];
				[as addAttribute:NSBackgroundColorAttributeName value:[NSColor gridColor] range:frange];
				fsize = basesize*SMALLCAPSCALE;
			}
			if (code & FX_SUPER) {
				[as addAttribute:NSBaselineOffsetAttributeName value:[NSNumber numberWithFloat:basesize*SUPERRISE] range:frange];
				fsize = basesize*SUPSUBCALE;
			}
			if (code & FX_SUB) {
				[as addAttribute:NSBaselineOffsetAttributeName value:[NSNumber numberWithFloat:-basesize*SUBDROP] range:frange];
				fsize = basesize*SUPSUBCALE;
			}
		}
		ff = [[NSFontManager sharedFontManager] fontWithFamily:fname traits:traits weight:5 size:fsize];
//		if (traits&NSBoldFontMask)		// circumvent Leopard bug that drops bold in call to fontWithFamily
//			ff = [[NSFontManager sharedFontManager] convertFont:ff toHaveTrait:NSBoldFontMask];
		[as addAttribute:NSFontAttributeName value:ff range:frange];
	}
	astr_free(asp);
	return as;
}
- (NSComparisonResult)caseInsensitiveCompare:(NSAttributedString *)aString {
	return [[self string] caseInsensitiveCompare:[aString string]];
}
- (NSAttributedString *)normalizeAttributesWithMap:(FONTMAP *)fmap {
	unsigned char recovered[MAXREC+500];
	
	[self convertToXString:recovered fontMap:fmap mode:0];
	return [NSAttributedString asFromXString:recovered fontMap:fmap size:0 termchar:EOCS];
}
- (NSAttributedString *)normalizeAttributesWithMap:(FONTMAP *)fmap size:(float)size {	// set attrobutsd with right font and size
	unsigned char recovered[MAXREC+500];
	
	[self convertToXString:recovered fontMap:fmap mode:0];
	return [NSAttributedString asFromXString:recovered fontMap:fmap size:size termchar:EOCS];
}
- (NSAttributedString *)normalizeToBaseFont:(FONTMAP *)fmap size:(float)size {	// sets font in selection to be base font and size
	unsigned char recovered[MAXREC+500];
	
	[self convertToXString:recovered fontMap:NULL mode:0];
	return [NSAttributedString asFromXString:recovered fontMap:fmap size:size termchar:EOCS];
}
- (int)convertToXString:(unsigned char *)rstring fontMap:(FONTMAP *)fm mode:(int)flags{	// makes xstring from attributed string
	unsigned int length = [[self string] length];
	unsigned int index = 0;
	char attributes = 0;
	char fontid = 0;
	ATTRIBUTEDSTRING * as = astr_createforsize(length);
	
	if (as)	{	// if have attributed string
		[[self string] getCharacters:as->string];	// get string as unichars
		as->length = length;
		astr_normalize(as);
		while (index < length) {
			NSRange extent;
			NSDictionary * dic = [self attributesAtIndex:index effectiveRange:&extent];
			NSFont * newfont = [dic objectForKey:NSFontAttributeName];
			NSNumber * offset = [dic objectForKey:NSBaselineOffsetAttributeName];
			NSNumber * superbase = [dic objectForKey:NSSuperscriptAttributeName];	// NSTextView attrib
			NSNumber * underline = [dic objectForKey:NSUnderlineStyleAttributeName];
			NSColor * color = [dic objectForKey:NSBackgroundColorAttributeName];
			char newfontid = fm ? type_findlocal(fm,(char *)[[newfont familyName] UTF8String],0) : 0;
			unsigned int traits = [[NSFontManager sharedFontManager] traitsOfFont:newfont];
			char newattributes, onstylecode, offstylecode, fontcode;
			
			fontcode = onstylecode = offstylecode = newattributes = 0;
			if (traits&NSBoldFontMask)
				newattributes |= FX_BOLD;
			if (traits&NSUnboldFontMask)
				newattributes &= ~FX_BOLD;
			if (traits&NSItalicFontMask)
				newattributes |= FX_ITAL;
			if (traits&NSUnitalicFontMask)
				newattributes &= ~FX_ITAL;
			if (underline && [underline intValue]) 
				newattributes |= FX_ULINE;
			if ([color isEqual:[NSColor gridColor]])
//			if (color)			// assumes only color attribute can be gridColor for small caps (otherwise need detailed comparison of colors
				newattributes |= FX_SMALL;
			if (offset) {
				float shift = [offset floatValue];
				if (shift > 0)
					newattributes |= FX_SUPER;
				else if (shift < 0)
					newattributes |= FX_SUB;		
			}
			if (superbase) {		// this here to catch sub/super from default text attrib
				float shift = [superbase floatValue];
				if (shift > 0)
					newattributes |= FX_SUPER;
				else if (shift < 0)
					newattributes |= FX_SUB;		
			}
			if ((newattributes&FX_BOLD) != (attributes&FX_BOLD)) {
				if (newattributes&FX_BOLD)
					onstylecode |= FX_BOLD;
				else
					offstylecode |= FX_BOLD;
			}
			if ((newattributes&FX_ITAL) != (attributes&FX_ITAL)) {
				if (newattributes&FX_ITAL)
					onstylecode |= FX_ITAL;
				else
					offstylecode |= FX_ITAL;
			}
			if ((newattributes&FX_ULINE) != (attributes&FX_ULINE)) {
				if (newattributes&FX_ULINE)
					onstylecode |= FX_ULINE;
				else
					offstylecode |= FX_ULINE;
			}
			if ((newattributes&FX_SMALL) != (attributes&FX_SMALL)) { 
				if (newattributes&FX_SMALL)
					onstylecode |= FX_SMALL;
				else
					offstylecode |= FX_SMALL;
			}
			if ((newattributes&FX_SUPER) != (attributes&FX_SUPER)) {
				if (newattributes&FX_SUPER)
					onstylecode |= FX_SUPER;
				else
					offstylecode |= FX_SUPER;
			}
			if ((newattributes&FX_SUB) != (attributes&FX_SUB)) {
				if (newattributes&FX_SUB)
					onstylecode |= FX_SUB;
				else
					offstylecode |= FX_SUB;
			}
			if (fontid != newfontid && fm)	// if want font change and recovering font info
				fontcode = newfontid|FX_FONT|FX_AUTOFONT;
			if (offstylecode)	{	/* if off code, then off styles come before font */
				as->codesets[as->codecount].offset = index;
				as->codesets[as->codecount++].code = offstylecode|FX_OFF;
				if (fontcode)	{
					as->codesets[as->codecount].offset = index;
					as->codesets[as->codecount++].code = fontcode;
				}
				if (onstylecode)	{	/* if any on style to add */
					as->codesets[as->codecount].offset = index;
					as->codesets[as->codecount++].code = onstylecode;
				}
			}
			else {			/* otherwise fonts come first */
				if (fontcode)	{
					as->codesets[as->codecount].offset = index;
					as->codesets[as->codecount++].code = fontcode;
				}
				if (onstylecode)	{
					as->codesets[as->codecount].offset = index;
					as->codesets[as->codecount++].code = onstylecode;
				}
			}
			while (index < NSMaxRange(extent))	{	// while within scope of attributes
				if (as->string[index] == '\n')	// if newline
					as->string[index] = 0;		// end string
				index++;
			}
			attributes = newattributes;
			fontid = newfontid;
		}
	}
	astr_toUTF8string(rstring,as);
	astr_free(as);
	return str_adjustcodes(rstring,flags|(g_prefs.gen.remspaces ? CC_ONESPACE : 0));	// clean up codes
}
@end

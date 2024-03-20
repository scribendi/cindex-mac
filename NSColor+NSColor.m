//
//  NSColor+NSColor.m
//  Cindex
//
//  Created by Peter Lennie on 5/26/19.
//


@implementation NSColor (NSColor)

+(NSColor *)leadColor {
	if (@available(macOS 10.14, *)) {
		return [NSColor controlAccentColor];
	} else {
		return [NSColor blueColor];
	}
}
@end

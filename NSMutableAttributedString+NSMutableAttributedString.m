//
//  NSMutableAttributedString+NSMutableAttributedString.m
//  Cindex
//
//  Created by Peter Lennie on 4/12/18.
//


@implementation NSMutableAttributedString (NSMutableAttributedString)

- (void)setTabs:(int *)tabs headIndent:(int)indent {
	NSMutableParagraphStyle * paraStyle = [[NSMutableParagraphStyle alloc] init];
	NSMutableArray * tabarray = [NSMutableArray arrayWithCapacity:10];
	
	for (int tindex = 0; tabs[tindex]; tindex++)	{
		NSTextTab * tb;
		
		if (tabs[tindex] > 0)
			tb = [[NSTextTab alloc] initWithType:NSLeftTabStopType location:tabs[tindex]];
		else
			tb = [[NSTextTab alloc] initWithType:NSRightTabStopType location:-tabs[tindex]];
		[tabarray addObject:tb];
	}
	[paraStyle setTabStops:tabarray];
	[paraStyle setHeadIndent:indent];
	[self addAttributes:[NSDictionary dictionaryWithObject:paraStyle forKey:NSParagraphStyleAttributeName] range:NSMakeRange(0,[[self string] length])];
}
- (void)setTabsForRecordCount:(RECN)number {
	static NSString * digits = @"99999999999";
	int count = 0;
	for (int tnum = 1; tnum < number; tnum *= 10, count++)
		;
	NSString * ts = [digits substringToIndex:count];
	NSSize size = [ts sizeWithAttributes:[self attributesAtIndex:0 effectiveRange:NULL]];
	NSMutableParagraphStyle * paraStyle = [[NSMutableParagraphStyle alloc] init];
	NSMutableArray * tabarray = [NSMutableArray arrayWithCapacity:2];
	[tabarray addObject:[[NSTextTab alloc] initWithType:NSRightTabStopType location:size.width]];
	[tabarray addObject:[[NSTextTab alloc] initWithType:NSLeftTabStopType location:size.width+10]];
	[paraStyle setTabStops:tabarray];
	[paraStyle setHeadIndent:size.width+9.9];
	[self addAttributes:[NSDictionary dictionaryWithObject:paraStyle forKey:NSParagraphStyleAttributeName] range:NSMakeRange(0,[[self string] length])];
}
@end

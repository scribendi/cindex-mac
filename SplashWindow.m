//
//  SplashWindow.m
//  Cindex
//
//  Created by PL on 9/25/05.
//  Copyright 2005 Indexing Research. All rights reserved.
//

#import "SplashWindow.h"

@implementation SplashWindow
- (id)initWithContentRect:(NSRect)contentRect styleMask:(NSWindowStyleMask)aStyle backing:(NSBackingStoreType)bufferingType defer:(BOOL)flag {
    SplashWindow *result = [super initWithContentRect:contentRect styleMask:NSBorderlessWindowMask backing:NSBackingStoreBuffered defer:NO];
    [result setBackgroundColor: [NSColor clearColor]];
    [result setLevel: NSSubmenuWindowLevel];
    [result setOpaque:NO];
    [result setHasShadow: YES];
	[result center];
	return result;
}
- (BOOL)canBecomeKeyWindow {
	return YES;
}
#if 0
- (BOOL)canBecomeMainWindow {
	return YES;
}
#endif
@end

//
//  IRApp.m
//  Cindex
//
//  Created by PL on 9/3/05.
//  Copyright 2005 Indexing Research. All rights reserved.
//

#import "IRApp.h"
#import "IRIndexDocument.h"
#import "IRIndexDocumentController.h"
#import "IRIndexDocWController.h"
#import "SplashWindowController.h"

@implementation IRApp
#if 0
- (void)removeWindowsItem:(NSWindow *)aWindow {
	if ([aWindow isVisible])
		[super removeWindowsItem:aWindow];
}
#endif
- (void)terminate:(id)sender {
	// do this cleanup here because [IRdc applicationShouldTerminate] is called *after*
	// doc controller handles any dirty programs.
	
    IRIndexDocument * doc = [(IRIndexDocumentController *)[self delegate] currentDocument];
    NSArray * docarray = [(IRIndexDocumentController *)[self delegate] documents];
	int index;

	if ([[doc fileType] isEqualToString:CINIndexType])	// if have current index doc
		[[NSUserDefaults standardUserDefaults] setObject:[[doc fileURL] path] forKey:CILastIndex];	// save it as last used
#if 0
	while (doc = [dnum nextObject])	{   // for all docs
		[[[doc mainWindowController] window] performClose:self];
	}
#else				// need this because objects are removed from array
	for (index = [docarray count]; --index >= 0;)
		[[[[docarray objectAtIndex:index] mainWindowController] window] performClose:self];
#endif
	[[NSPasteboard pasteboardWithName:NSDragPboard] clearContents];		// terminate calls Pboard to deliver any promised data
	[super terminate:sender];
}
- (void)orderFrontStandardAboutPanel:(id)sender {
	[SplashWindowController showWithButton:YES];
}
@end

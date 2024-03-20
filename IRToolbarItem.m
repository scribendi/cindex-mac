//
//  IRToolbarItem.m
//  Cindex
//
//  Created by Peter Lennie on 6/12/18.
//

#import "IRToolbarItem.h"
#import "IRIndexDocumentController.h"
#import "IRIndexDocWController.h"
#import "IRIndexDocument.h"

@implementation IRToolbarItem

- (void)validate {
	//	NSLog(@"Tag: %ld", self.tag);
	if ([NSApp mainWindow] == [IRdc.currentDocument mainWindowController].window)
		self.enabled = [IRdc.currentDocument validateToolbarItem:self];
//	else if ([NSApp mainWindow] == [IRdc.currentDocument recordWindowController].window)
//		self.enabled = [[NSApp mainWindow].firstResponder validateToolbarItem:self];
}

@end

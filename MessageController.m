//
//  MessageController.m
//  Cindex
//
//  Created by PL on 5/7/18.
//  Copyright 2018 Indexing Research. All rights reserved.
//

#import <WebKit/WebView.h>
#import "MessageController.h"

NSString * IRMessage = @"MessageWindow";


@interface MessageController () {
	IBOutlet WebView * webView;
}
@end

@implementation MessageController

- (id)initWithURL:(NSString *)url	{
    self = [super initWithWindowNibName:@"MessageController"];
	if (self) {
		
	}
    return self;
}
-(void)dealloc {
	;
}
- (void)awakeFromNib {
	[super awakeFromNib];
}
- (IBAction)showHelp:(id)sender {
	;
	
}
- (void)windowDidUpdate:(NSNotification *)aNotification {
	;
	
}
- (IBAction)closePanel:(id)sender {
	if ([sender tag] == OKTAG)		{
		;
		
	}
	[self close];
	[NSApp stopModal];
}
- (BOOL)control:(NSControl *)control textShouldBeginEditing:(NSText *)fieldEditor {
	;
	return YES;
}
- (BOOL)control:(NSControl *)control textShouldEndEditing:(NSText *)editor {
	return YES;	// don't check expansion text
}
- (void)controlTextDidEndEditing:(NSNotification *)aNotification	{
	;
}
@end

//
//  UserIDController.m
//  Cindex
//
//  Created by PL on 6/25/05.
//  Copyright 2005 Indexing Research. All rights reserved.
//

#import "UserIDController.h"

@implementation UserIDController
- (id)init	{
   self = [super initWithWindowNibName:@"UserIDController"];
   return self;
}
- (void)awakeFromNib {
	[super awakeFromNib];
	[userid setStringValue:[NSString stringWithCString:g_prefs.hidden.user encoding:NSUTF8StringEncoding]];
}
- (IBAction)closePanel:(id)sender {
	if ([sender tag] == OKTAG)	{
		strcpy(g_prefs.hidden.user, (char *)[[userid stringValue] UTF8String]);
	}
	[self close];
	[NSApp stopModal];
}
- (void)controlTextDidChange:(NSNotification *)note	{
	checktextfield([note object],64);
}
@end

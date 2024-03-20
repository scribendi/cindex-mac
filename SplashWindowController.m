//
//  SplashWindowController.m
//  Cindex
//
//  Created by PL on 9/25/05.
//  Copyright 2005 Indexing Research. All rights reserved.
//

#import "SplashWindowController.h"
#import "commandutils.h"

#define BASETIME 3.0
#define FADETIME 2.0
#define TICKTIME 0.05

#define LICENSENAME @"/.license4"

static BOOL checkserial (char * sernum);

SplashWindowController * spc;

@interface SplashWindowController () {
	NSTimer * _splashtimer;
	int _ticks;
	LICENSE _license;
}
@property (assign) BOOL showButton;
- (void)_displayLicense;
@end

@implementation SplashWindowController
+ (void)showWithButton:(BOOL)button {
	spc = [[SplashWindowController alloc] initWithWindowNibName:@"SplashWController"];
	spc.showButton = button;
	[spc showWindow:nil];
}
- (void)dealloc {
	[_splashtimer invalidate];
}
- (void)awakeFromNib {
	[super awakeFromNib];
	NSBundle * bundle = [NSBundle mainBundle];

	[version setStringValue:[bundle objectForInfoDictionaryKey:@"CFBundleVersion"]];
#if TOPREC == 100
	[tf2 setStringValue:@"Demonstration Copy"];
	[tf3 setStringValue:@"Capacity 100 Records"];
#elif TOPREC < RECLIMIT
	[tf2 setStringValue:@"Student Edition"];
	[tf3 setStringValue:@"Capacity 500 Records"];
#else
	NSString * licensepath = [global_supportdirectory(NO) stringByAppendingString:LICENSENAME];
	if (licensepath)	{
//	if (TRUE)	{		// don't check license path for the moment
		NSData * ld = [NSData dataWithContentsOfFile:licensepath];
		
		if (ld) {	// if have license
			memcpy(&_license,[ld bytes],[ld length]);	// fetch it
			if (checkserial(_license.serial))	// if serial # OK
				[self _displayLicense];
			return;
		}
		else if (global_supportdirectory(YES))	{	// if could store license
			[NSApp runModalForWindow:licensepanel];	// ask for it
			return;
		}
	}
	senderr(BADINSTALLERR,WARN);
	[NSApp terminate:self];
#endif
}
- (IBAction)showWindow:(id)sender {
	[[self window] makeFirstResponder:self];
	if (!_showButton)	{
		[credits setHidden:YES];
		_splashtimer = [NSTimer scheduledTimerWithTimeInterval:TICKTIME target:self selector:@selector(changeTransparency:) userInfo:nil repeats:YES];
	}
	[super showWindow:self];
}
- (void)closewhenready {
	if (!creditpanel.isVisible) {
		[_splashtimer invalidate];
		_splashtimer = nil;
		[self close];
		spc = nil;
	}
}
- (void)keyDown:(NSEvent *)theEvent {
	[self closewhenready];
}
- (void)mouseDown:(NSEvent *)theEvent	{
	[self closewhenready];
}
- (void)windowDidResignKey:(NSNotification *)notification {
	[self closewhenready];
}
- (void)changeTransparency:(id)sender {
	float elapsed = ++_ticks*TICKTIME;
	if (elapsed > BASETIME)	{
		if (elapsed < BASETIME+FADETIME)	{
			[[self window] setAlphaValue:1-(elapsed-BASETIME)/FADETIME];
			[[self window] display];		// force redraw
		}
		else {
			[self closewhenready];
		}
	}
}
- (void)_displayLicense {
	[tf1 setStringValue:[NSString stringWithUTF8String:_license.name]];
	[tf2 setStringValue:[NSString stringWithUTF8String:_license.org]];
	[tf3 setStringValue:[NSString stringWithUTF8String:_license.serial]];
}
- (IBAction)showCredits:(id)sender {
	NSData * rtfdata = [NSData dataWithContentsOfFile:[[NSBundle mainBundle] pathForResource:@"notices" ofType:@"rtf"]];
	[creditview replaceCharactersInRange:NSMakeRange(0, 0) withRTF:rtfdata];
	[creditview.textStorage addAttribute:NSForegroundColorAttributeName value:NSColor.textColor range:NSMakeRange(0, creditview.textStorage.length)];
	[creditpanel setLevel:NSPopUpMenuWindowLevel];
	[NSApp runModalForWindow:creditpanel];
}
- (IBAction)closeCredits:(id)sender {
	[[sender window] orderOut:sender];
	[NSApp stopModal];
	[self close];
}
- (IBAction)closePanel:(id)sender {
	if ([sender tag] == OKTAG)	{
		if (![[sender window] makeFirstResponder:nil])	// if bad text somewhere
			return;
		strcpy(_license.name,[[lf1 stringValue] UTF8String]);
		strcpy(_license.org,[[lf2 stringValue] UTF8String]);
		strcpy(_license.serial,[[lf3 stringValue] UTF8String]);
		if (checkserial(_license.serial))	{	// if serial OK
			NSString * licensepath = [global_supportdirectory(YES) stringByAppendingString:LICENSENAME];
			NSData * ld = [NSData dataWithBytes:&_license length:sizeof(LICENSE)];
			
			[ld writeToFile:licensepath atomically:YES];
			[self _displayLicense];
			[[sender window] orderOut:sender];
			[NSApp stopModal];
		}
	}
	else
		[NSApp terminate:self];
}
- (void)controlTextDidChange:(NSNotification *)note	{
	NSControl * control = [note object];
//	NSString * ustring = [control stringValue];
	
//	if ([ustring length] >= 64)	// if string too long
//		[control setStringValue:[ustring substringWithRange:NSMakeRange(0,63)]];
		checktextfield(control,64);
	if ([[lf1 stringValue] length] > 0 && checkserial((char *)[[lf3 stringValue] UTF8String]))
		[okbutton setEnabled:YES];
	else
		[okbutton setEnabled:NO];
}
@end
/********************************************************************************/
static BOOL checkserial (char * serial)

{
	enum {
		TOTLENGTH = 15
	};

	return strlen(serial) == TOTLENGTH && true;	// return test result
}

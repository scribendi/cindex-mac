//
//  TextStyleController.m
//  Cindex
//
//  Created by PL on 1/9/05.
//  Copyright Indexing Research.. All rights reserved.
//

#import "TextStyleController.h"
#import "commandutils.h"
#import "type.h"

@interface TextStyleController () {
}
@property(assign)CSTYLE * style;
@property(assign)int extraMode;

@end
@implementation TextStyleController
+ (void)showForStyle:(CSTYLE *)style extraMode:(int)mode{
	TextStyleController * tsc = [[TextStyleController alloc] initWithWindowNibName:@"TextStyleController"];
	tsc.style = style;
	tsc.extraMode = mode;
	[NSApp runModalForWindow:[tsc window]];
}
- (void)awakeFromNib {
	[super awakeFromNib];
	[[styles cellWithTag:0] setState:_style->style&FX_BOLD ? TRUE : FALSE];
	[[styles cellWithTag:1] setState:_style->style&FX_ITAL ? TRUE : FALSE];
	[[styles cellWithTag:2] setState:_style->style&FX_ULINE ? TRUE : FALSE];
	[[styles cellWithTag:3] setState:_style->style&FX_SMALL ? TRUE : FALSE];
	if (_extraMode)	// if extra mode allowed
		[caps cellWithTag:3].title = _extraMode == FC_AUTO ? @"Auto" : @"Title Case";
	else
		[caps removeRow:3];
	[caps selectCellWithTag:_style->cap <= FC_UPPER ? _style->cap : 3];
	centerwindow([NSApp keyWindow],[self window]);
}
- (IBAction)showHelp:(id)sender {
	[[NSHelpManager sharedHelpManager] openHelpAnchor:@"textstyles0_Anchor-14210" inBook:@"Cindex 4.2.5 Help"];
}
- (IBAction)closePanel:(id)sender {    
	if ([sender tag] == OKTAG)	{
		_style->style = 0;
		if ([[styles cellWithTag:0] state])
			_style->style |= FX_BOLD;
		if ([[styles cellWithTag:1] state])
			_style->style |= FX_ITAL;
		if ([[styles cellWithTag:2] state])
			_style->style |= FX_ULINE;
		if ([[styles cellWithTag:3] state])
			_style->style |= FX_SMALL;
		_style->cap = [caps selectedCell].tag;
		if (_style->cap == 3)	// if chosen extra mode
			_style->cap = _extraMode;	// set right one
	}
	[self close];
	[NSApp stopModal]; 
}
@end

//
//  IRIndexTextWController.h
//  Cindex
//
//  Created by PL on 1/17/05.
//  Copyright 2005 Indexing Research. All rights reserved.
//

#import "IRTextView.h"

@interface IRIndexTextWController : NSWindowController <NSWindowDelegate>{
    IBOutlet IRTextView * _mainview;

    NSAttributedString * _string;
	NSString * _title;
}
- (NSView *)printView;
- (id)initWithAttributedString:(NSAttributedString *)astring;
- (void)setTitle:(NSString *)string;
- (void)setAttributedString:(NSAttributedString *)string;
@end

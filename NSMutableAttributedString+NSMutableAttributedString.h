//
//  NSMutableAttributedString+NSMutableAttributedString.h
//  Cindex
//
//  Created by Peter Lennie on 4/12/18.
//


@interface NSMutableAttributedString (NSMutableAttributedString)
- (void)setTabs:(int *)tabs headIndent:(int)indent;
- (void)setTabsForRecordCount:(RECN)number;

@end

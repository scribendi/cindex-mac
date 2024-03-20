//
//  TextViewCategories.h
//  Cindex
//
//  Created by PL on 3/16/05.
//  Copyright 2005 Indexing Research. All rights reserved.
//


@interface NSTextView (TextViewCategories)
- (unsigned int) numberOfLines;
- (NSArray *) lines;
- (NSArray *) lineRanges;
- (unichar)rightCharacter;
- (unichar)leftCharacter;
- (unichar)lastSelectedCharacter;
@end

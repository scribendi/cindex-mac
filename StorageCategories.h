//
//  StorageCategories.h
//  Cindex
//
//  Created by PL on 4/9/05.
//  Copyright 2005 Indexing Research. All rights reserved.
//

@class LayoutDescriptor;

@interface NSTextStorage (StorageCategories)
- (LayoutDescriptor *) descriptor;
-(int)linesForRange:(NSRange)range;
@end

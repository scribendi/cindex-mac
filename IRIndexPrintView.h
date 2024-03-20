//
//  IRIndexPrintView.h
//  Cindex
//
//  Created by PL on 9/19/05.
//  Copyright 2005 Indexing Research. All rights reserved.
//


@interface IRIndexPrintView : NSView <NSLayoutManagerDelegate>
{
}
- (id)initWithDocument:(IRIndexDocument *)document paragraphs:(NSArray *)paras;
- (BOOL)buildPageStatistics ;

@end

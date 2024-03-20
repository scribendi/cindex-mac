//
//  TextStyleController.h
//  Cindex
//
//  Created by PL on 1/9/05.
//  Copyright 2005 Indexing Research.. All rights reserved.
//


@interface TextStyleController : NSWindowController {
	IBOutlet NSMatrix * styles;
	IBOutlet NSMatrix * caps;
}
+ (void)showForStyle:(CSTYLE *)style extraMode:(int)mode;
@end

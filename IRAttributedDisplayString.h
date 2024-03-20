//
//  IRAttributedDisplayString.h
//  Cindex
//
//  Created by PL on 4/9/05.
//  Copyright 2005 Indexing Research. All rights reserved.
//

#import "IRDisplayString.h"

@interface IRAttributedDisplayString : NSAttributedString {
}
- (id)initWithIRIndex:(IRIndexDocument *)doc paragraphs:paragraphs record:(RECN)record;
//- (IRDisplayString *)string;
- (RECN)record;
- (ENTRYINFO *)entryInformation;
@end

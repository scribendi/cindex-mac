//
//  SpellTextField.h
//  Cindex
//
//  Created by PL on 12/9/05.
//  Copyright 2005 Indexing Research. All rights reserved.
//

@interface SpellTextField : NSTextField {

}
@end

@interface NSObject(SpellTextFieldDelegate) // delegate methods for text Field
- (void)setDefaultChangedWord;
@end

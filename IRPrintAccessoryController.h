//
//  IRPrintAccessoryController.h
//  Cindex
//
//  Created by Peter Lennie on 4/15/18.
//

#import "IRIndexDocument.h"

@interface IRPrintAccessoryController : NSViewController <NSPrintPanelAccessorizing> 
@property () RECN firstRecord;
@property () RECN lastRecord;

- (instancetype)initForDocument:(IRIndexDocument *)document;

@end

//
//  HTTPService.h
//  Cindex
//
//  Created by Peter Lennie on 6/12/08.
//  Copyright 2008 Indexing Research. All rights reserved.
//

enum {
	U_MAC = 1,
	U_WIN = 2,
	U_WIN_PUB = 4
};


@interface HTTPService : NSObject {
	NSMutableData * _data;
}
- (void)check:(id)sender;
@end

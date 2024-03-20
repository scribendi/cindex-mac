//
//  IRIndexArchive.h
//  Cindex
//
//  Created by PL on 1/22/05.
//  Copyright 2005 Indexing Research. All rights reserved.
//

#import "import.h"


@interface IRIndexArchive : NSDocument {
	INDEX * FF;
	NSString * importName;
	IMPORTPARAMS imp;
}

@property (strong) NSString * importName;

- (id)initWithContentsOfURL:(NSURL*)url ofType:(NSString *)docType forIndex:(INDEX *)index;
@end

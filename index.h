//
//  index.h
//  Cindex
//
//  Created by PL on 1/15/05.
//  Copyright 2005 Indexing Research. All rights reserved.
//

#import "indexdocument.h"

void index_cleartags(INDEX * FF);	// clears tags, etc
int index_checkintegrity(INDEX * FF, RECN rtot);	// checks integrity of index
int index_repair(INDEX * FF);	// repairs index
BOOL index_setworkingsize(INDEX * FF, RECN extrarecords);	// sets working size with margin
BOOL index_setsize(INDEX * FF,RECN total,int recsize,RECN margin);	// sets size with any margin
BOOL index_sizeforgroups(INDEX * FF, unsigned int groupsize);	// extends group collection
void index_markdirty(INDEX * FF);		// marks index as dirty
BOOL index_writehead(INDEX * FF);		// writes header
BOOL index_flush(INDEX * FF);		/* flushes all records & header */

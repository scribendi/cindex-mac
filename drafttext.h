//
//  drafttext.h
//  Cindex
//
//  Created by PL on 2/5/05.
//  Copyright 2005 Indexing Research. All rights reserved.
//

#import "indexdocument.h"
#import "records.h"

#define LEADCOLOR 31

char * draft_build(INDEX * FF, RECORD * recptr, short * hlevel);	/* returns text of formed entry */
RECORD * draft_skip(INDEX * FF, RECORD * recptr, short dir);	/* skips in draft display mode */
char * draft_buildentry(INDEX * FF, char * buffer, RECORD * recptr, short * ulevel);		/* forms entry for record */

/*
 *  fontmap.h
 *  Cindex
 *
 *  Created by PL on 5/22/11.
 *  Copyright 2005 Indexing Research. All rights reserved.
 *
 */

#define FONTLIMIT 32	/* number of local fonts we can manage */
#define FONTNAMELEN 64	// font name

enum FONTFLAGS {
	CHARSETALPHA = 1,
	CHARSETSYMBOLS = 2
};

typedef struct {	/* maps font name to local ID */
	char name[FONTNAMELEN];	/* alt (working) font name */
	char pname[FONTNAMELEN];	/* name of preferred font */
	short flags;	
} FONTMAP;


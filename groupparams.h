/*
 *  groupparams.h
 *  Cindex
 *
 *  Created by PL on 1/11/05.
 *  Copyright 2005 Indexing Research. All rights reserved.
 *
 */

#define GROUPLEN 256
#define GPNOTELEN 128

#pragma pack(4)

typedef struct {		/* header to group */
	int size;
	time_c tstamp;		/* time created */
	time_c indextime;	/* time owning index created */
	char gname[GROUPLEN];	/* name of group */
	char comment[GPNOTELEN];	/* comment */
	RECN limit;			/* max number of records that can be in group */
	short gflags;		/* flags describing group status */
	LISTGROUP lg;	/* search structure */
	SORTPARAMS sg;	/* sort structure */
	RECN rectot;		/* # records in it */
	int spare[32];	// spare
	RECN recbase[];		/* array of record numbers */
} GROUP;

typedef GROUP *GROUPHANDLE;

#pragma options align=reset

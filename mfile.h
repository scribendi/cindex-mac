//
//  mfile.h
//  Cindex
//
//  Created by Peter Lennie on 5/1/11.
//  Copyright 2011 Indexing Research. All rights reserved.
//

typedef struct {
	int fref;	// file descriptor
	char * base;	// view base
	size_t size;	// size of mapped section
	BOOL readonly;
} MFILE;

BOOL mfile_open(MFILE *mf, char * path, int flags,unsigned long extend);	// opens file with mapped memory
BOOL mfile_resize(MFILE *mf, size_t newsize);	// resizes mapped file
BOOL mfile_flush(MFILE *mf);		// flushes map to file
BOOL mfile_close(MFILE *mf);		// closes mapped file

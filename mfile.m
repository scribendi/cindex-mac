//
//  mfile.m
//  Cindex
//
//  Created by Peter Lennie on 5/1/11.
//  Copyright 2011 Indexing Research. All rights reserved.
//

#import "mfile.h"
#import <sys/stat.h>
#import <sys/mman.h>
#import "IRIndexDocument.h"

/*****************************************************************************/
BOOL mfile_open(MFILE *mf, char * path, int flags, unsigned long extend)	// opens file with mapped memory

{
	memset(mf, 0, sizeof(MFILE));
	mf->fref = open(path,flags);
	if (mf->fref >= 0)	{
		struct stat statInfo;
		size_t cursize;
		int err = 0;
		
		fstat(mf->fref, &statInfo);
		cursize = statInfo.st_size;
		
		mf->readonly = !(flags&O_RDWR);	// O_RDONLY is defined as 0
		if (mf->readonly)
			extend = 0;
		if (extend && !mf->readonly)
			err = ftruncate(mf->fref,cursize+extend);
		if (!err)	{
			if (cursize+extend)	{
				mf->base = mmap(NULL,cursize+extend,mf->readonly ? PROT_READ : PROT_READ|PROT_WRITE,MAP_SHARED,mf->fref,0);
				if (mf->base != MAP_FAILED)	{
					mf->size = cursize+extend;
					return TRUE;
				}
				NSLog(@"Mapping error %d",errno);
			}
			else
				return TRUE;
		}
		close(mf->fref);
	}
//	NSLog(@"%s",strerror(errno));
	return FALSE;
}
/*****************************************************************************/
BOOL mfile_resize(MFILE *mf, size_t newsize)	// resizes mapped file

{
	if (!mf->readonly && newsize != mf->size)	{
		if (mf->base)	{	// if have mapping
			if (msync(mf->base,mf->size,MS_SYNC|MS_INVALIDATE) || munmap(mf->base,mf->size))	{	// force flush and unmap
				[NSException raise:IRMappingException format:@"Error %u when unmapping file",errno];
				NSLog(@"Unmapping error %d",errno);
				return FALSE;
			}
			mf->base = NULL;
		}
		if (ftruncate(mf->fref, newsize) == 0)	{	// set file size
			mf->base = mmap(NULL,newsize,PROT_READ|PROT_WRITE,MAP_SHARED,mf->fref,0);
			if (mf->base != MAP_FAILED)	{
				mf->size = newsize;
				return TRUE;
			}
			[NSException raise:IRMappingException format:@"Error %u when mapping file",errno];
			NSLog(@"Mapping error %d",errno);
		}
		[NSException raise:IRMappingException format:@"Error %u when truncating file",errno];
		return FALSE;
	}
	return TRUE;
}
/*****************************************************************************/
BOOL mfile_flush(MFILE *mf)		// flushes map to file

{
	return msync(mf->base,mf->size,MS_SYNC) == 0;
}
/*****************************************************************************/
BOOL mfile_close(MFILE *mf)		// closes mapped file

{
	if (mf->base)	{
		if (msync(mf->base,mf->size,MS_SYNC) || munmap(mf->base,mf->size))
			return FALSE;
		mf->base = NULL;
	}
	return !close(mf->fref);
}

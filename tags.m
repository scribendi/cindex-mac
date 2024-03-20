//
//  tags.m
//  Cindex
//
//  Created by PL on 1/23/05.
//  Copyright 2005 Indexing Research. All rights reserved.
//

#import "tags.h"
#import "strings_c.h"
#import "IRIndexDocumentController.h"
#import "IRIndexDocument.h"

#define OLDAHEADBASE 4	// Cindex 3: T_STRUCTBASE+4
#define OLDCHARBASE 95	// Cindex 3: T_NUMTAGS-4

/******************************************************************************/
NSString * ts_getactivetagsetname(int type)	// gets active tagset name

{
	NSString * ns = ts_getactivetagsetpath(type);
	if (ns)	
		ns = [[ns lastPathComponent] stringByDeletingPathExtension];
	return ns;
}
/******************************************************************************/
NSString * ts_getactivetagsetpath(int type)	// gets active tagset for type

{
	NSString * path = nil;
	
	if (type == XMLTAGS)	{
		path = [[NSUserDefaults standardUserDefaults] objectForKey:CIXMLTagSet];
		if (!ts_openset(path))
			path = [ts_gettagsets(CINXMLTagExtension) objectAtIndex:0];
	}
	else {
		path = [[NSUserDefaults standardUserDefaults] objectForKey:CISGMLTagSet];
		if (!ts_openset(path))
			path = [ts_gettagsets(CINTagExtension) objectAtIndex:0];
	}
	return path;
}
/******************************************************************************/
TAGSET * ts_openset(NSString * path)

{
	NSMutableData * md = [NSMutableData dataWithContentsOfFile:path];
	if (md)	{
		[md increaseLengthBy:200];	// add free space for conversion of returned tag set
		TAGSET * ts = (TAGSET *)md.bytes;
		if (ts && ts->tssize == sizeof(TAGSET) && ts->version <= TS_VERSION) {
			ts_convert(ts);		// convert old tags as necessary
			return ts;
		}
	}
	return NULL;
}
/*******************************************************************************/
NSArray * ts_gettagsets(NSString * type)

{
	NSBundle * mainbundle = [NSBundle mainBundle];
	NSMutableArray * sets = [NSMutableArray arrayWithCapacity:20];
	
	[sets addObjectsFromArray:[mainbundle pathsForResourcesOfType:type inDirectory:nil]];	// in main bundle
	[sets addObjectsFromArray:getfilelist(global_preferencesdirectory(),type)];		// in preferences
	
	return sets;
}
/******************************************************************************/
char * ts_gettagsetextension(NSString * path)

{
	TAGSET * ts = ts_openset(path);
	return ts->extn;
}
/******************************************************************************/
void ts_convert(TAGSET * ts)

{
	char * base;

	if (ts->version <= 1)	{
		base = str_xatindex(ts->xstr, OLDCHARBASE);	// set point to old character tag base
		*base++ = 0;	// append new char code tags
		*base++ = 0;
		*base = EOCS;
		base = str_xatindex(ts->xstr, OLDAHEADBASE);	// create space for new group tags
		str_xshift(base,2);
		*base++ = 0;
		*base = 0;
		ts->version = TS_VERSION;	// update to version 2 (Cindex 3)
	}
	if (!str_xatindex(ts->xstr, T_OTHERBASE+OT_STARTTEXT)) {	// if don't have extra body string (Cindex 4)
		base = str_xlast(ts->xstr);	// set point to current last string
		base += strlen(base)+1;		// now points to EOCS
		*base++ = 0;	// append new heading text tags
		*base++ = 0;
		*base = EOCS;
	}
}


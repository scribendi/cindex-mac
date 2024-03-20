//
//  export.h
//  Cindex
//
//  Created by PL on 4/23/05.
//  Copyright 2005 Indexing Research. All rights reserved.
//
#import "type.h"

enum {			/* export file types */
	E_NATIVE,
	E_XMLRECORDS,
	E_STATIONERY,
	E_ARCHIVE,
	E_TAB,
	E_DOS,
	E_TEXTNOBREAK,
	E_RTF,
	E_XPRESS,
	E_INDEXMANAGER,
	E_INDESIGN,
	E_XMLTAGGED,
	E_TAGGED
};


typedef struct {	/* export structure */
	short type;		/* file type */
	RECN first;		/* first record */
	RECN last;
	int firstpage;	// first page
	int lastpage;
	int encoding;	// character encoding
	BOOL includedeleted;		/* include deleted */
	BOOL extendflag;	/* write extended info */
	BOOL minfields;		/* min # fields in tab/quote write (presently unused) */
	BOOL appendflag;	/* append to existing file */
	BOOL sorted;
	int records;	/* records written */
	int longest;	/* chars required by longest record */
	int newlinetype;
	char usetabs;	// tab character
	RECN errorcount;	// count of records with character conversion errors
//	NSString * tagpath;		// path to active tag set
//	NSString * __unsafe_unretained lastSavedName;		// name of last saved file
} EXPORTPARAMS;


void export_setdefaultparams(INDEX * FF, int type);
NSData * export_writerecords(INDEX * FF, EXPORTPARAMS * exp);	/* forms export data as NSData */
NSData * export_writestationery(INDEX * FF, EXPORTPARAMS * exp);	/* forms export stationery as NSData */
void export_pastabletext(NSMutableData * data,INDEX * FF, BOOL rtf);	/* generates embedded text */

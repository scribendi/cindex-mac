//
//  IRIndexArchive.m
//  Cindex
//
//  Created by PL on 1/22/05.
//  Copyright 2005 Indexing Research. All rights reserved.
//

#import "IRIndexArchive.h"
#import "IRIndexTextWController.h"
#import "IRIndexDocument.h"
#import "ReplaceFontController.h"
#import "xmlparser.h"
#import "commandutils.h"
#import "index.h"

static char * r_err[] = 	{		/* read error messages */
	"Line contains an illegal character",
	"Record would exceed maximum record size",
	"Can't parse Macrex record",
	"Missing delimiter",
	"Record would contain too many fields",
	"Record would be too long",
	"Record would use an unknown font",
	"Record would be empty"
};	

@interface IRIndexArchive (PrivateMethods)
- (BOOL)_setFonts:(NSData *)data;
- (int)_checkData:(NSData *)data;
- (BOOL)_checkLine:(char *)fbuff record:(RECORD *)recptr;
- (int)_resolveErrors;
- (BOOL)_isGoodChar:(unsigned char *)ch;
- (BOOL)_getReplacementFont:(char *)fname;
- (BOOL)_checkFonts:(FONTMAP *)fm;
- (void)_checkFontBase:(NSData *)data;		// checks/fixes errors in font offset index
@end

@implementation IRIndexArchive

@synthesize importName;

- (id)init {
    if (self = [super init]) {
		imp.sepstr[0] = imp.sepstr[2] = '"';	/* set delimit chars */
		imp.sepstr[1] = ',';
    }
    return self;
}
- (id)initWithContentsOfURL:(NSURL *)url ofType:(NSString *)docType forIndex:(INDEX *)index{
	if ([self init]) {
		FF = index;
		self.importName = [[url absoluteString] lastPathComponent];
		if ([self readFromURL:url ofType:docType error:nil])
			return self;
	}
	return nil;
}
- (void)dealloc {
	self.importName = nil;
}
#if 1
- (BOOL)loadDataRepresentation:(NSData *)data ofType:(NSString *)type {
	char * base = (char *)[data bytes];
	char * errormessage;
	int result = 0;
	
//	NSLog(type);
	if ([type isEqualToString:CINXMLRecordType])	{		
		imp.type = I_CINXML;
		result = xml_parserecords(FF,&imp,(char *)[data bytes],[data length], &errormessage);
		if (result > 1)	{
			senderr(result,WARN,errormessage);	/* send error message */
			return NO;
		}
	}
	else {
		if ([type isEqualToString:CINArchiveType])
			imp.type = I_CINARCHIVE;
		else if ([type isEqualToString:CINDelimitedRecords])	{
			if (!imp_findtexttype(&imp,(char *)[data bytes],[data length]))	{
				if (!sendwarning(BADIMPORTTYPE,[importName UTF8String]))
					return NO;
			}
		}
		else if ([type isEqualToString:DOSDataType])	{	// DOS type
			imp.type = I_DOSDATA;
			if (!memchr(base, '\t',MAXREC) && memchr(base,*imp.sepstr,MAXREC))	// if contains no tab and has delimiter
				imp.delimited = TRUE;
		}
		else if ([type isEqualToString:MBackupType])
			imp.type = I_MACREX;
		else if ([type isEqualToString:SkyType])
			imp.type = I_SKY;
		result = imp_readrecords(FF,&imp,(char *)[data bytes],[data length]);
		if (result > 1)	{
			senderr(result,WARN,[importName UTF8String]);	/* send error message */
			return NO;
		}
	}
	if (result < 0)	{	// unresolved errors to display
		NSMutableString * errorlist = [NSMutableString stringWithCapacity:50000];
		NSMutableAttributedString * ts;
		struct rerr * erptr;
		int lcount;
		int displaycount = imp.ecount < IMP_MAXERRBUFF ? imp.ecount : IMP_MAXERRBUFF;
		
		[errorlist appendFormat:@"Longest record contains %d characters.\rErrors were found in %u of %u records.\r", imp.longest+1, imp.ecount, imp.recordcount];
		[errorlist appendFormat:@"Showing %d of %u  errors:\r\r", displaycount, imp.ecount];
		for (erptr = imp.errlist, lcount = 0; erptr->type && lcount < displaycount; lcount++, erptr++)
			[errorlist appendFormat:@"Line%6d %s\r", erptr->line, r_err[erptr->type-BADCHAR]];
		ts = [[NSMutableAttributedString alloc] initWithString:errorlist];
		[FF->owner showText:ts title:@"Import Errors"];
		return NO;
	}
	else 	{	// no or manageable error
//		index_setworkingsize(FF,MAPMARGIN);	// 6/25/18 import has already set working size
		[FF->owner flush];					// 6/25/18
		[FF->owner setViewType:VIEW_ALL name:nil];
		if (imp.markcount)		/* if marked any bad characters */
			infoSheet(FF->owner.windowForSheet,IMPORTMARKED, imp.markcount);
		[[FF->owner textWindowController] close];
	}
	return YES;
}
#else
- (BOOL)readFromData:(NSData *)data ofType:(NSString *)type error:(NSError * _Nullable *)outError; {
	char * base = (char *)[data bytes];
	char * errormessage;
	int result = 0;
	*outError = nil;		// don't display standard error message
	
	//	NSLog(type);
	if ([type isEqualToString:CINXMLRecordType])	{
		imp.type = I_CINXML;
		result = xml_parserecords(FF,&imp,(char *)[data bytes],[data length], &errormessage);
		if (result > 1)	{
			senderr(result,WARN,errormessage);	/* send error message */
			return NO;
		}
	}
	else {
		if ([type isEqualToString:CINArchiveType])
			imp.type = I_CINARCHIVE;
		else if ([type isEqualToString:CINDelimitedRecords])	{
			if (!imp_findtexttype(&imp,(char *)[data bytes],[data length]))	{
				if (!sendwarning(BADIMPORTTYPE,[importName UTF8String]))
					return NO;
			}
		}
		else if ([type isEqualToString:DOSDataType])	{	// DOS type
			imp.type = I_DOSDATA;
			if (!memchr(base, '\t',MAXREC) && memchr(base,*imp.sepstr,MAXREC))	// if contains no tab and has delimiter
				imp.delimited = TRUE;
		}
		else if ([type isEqualToString:MBackupType])
			imp.type = I_MACREX;
		else if ([type isEqualToString:SkyType])
			imp.type = I_SKY;
		result = imp_readrecords(FF,&imp,(char *)[data bytes],[data length]);
		if (result > 1)	{
			senderr(result,WARN,[importName UTF8String]);	/* send error message */
			return NO;
		}
	}
	if (result < 0)	{	// unresolved errors to display
		NSMutableString * errorlist = [NSMutableString stringWithCapacity:50000];
		NSAttributedString * ts;
		struct rerr * erptr;
		int lcount;
		int displaycount = imp.ecount < IMP_MAXERRBUFF ? imp.ecount : IMP_MAXERRBUFF;
		
		[errorlist appendFormat:@"Longest record contains %d characters.\rErrors were found in %u of %u records.\r", imp.longest+1, imp.ecount, imp.recordcount];
		[errorlist appendFormat:@"Showing %d of %u  errors:\r\r", displaycount, imp.ecount];
		for (erptr = imp.errlist, lcount = 0; erptr->type && lcount < displaycount; lcount++, erptr++)
			[errorlist appendFormat:@"Line%6d %s\r", erptr->line, r_err[erptr->type-BADCHAR]];
		ts = [[NSNutableAttributedString alloc] initWithString:errorlist];
		[FF->owner showText:ts title:@"Import Errors"];
		return NO;
	}
	else 	{	// no or manageable error
		index_setworkingsize(FF,MAPMARGIN);
		[FF->owner setViewType:VIEW_ALL name:nil];
		if (imp.markcount)		/* if marked any bad characters */
			infoSheet(FF->owner.windowForSheet,IMPORTMARKED, imp.markcount);
		[[FF->owner textWindowController] close];
	}
	return YES;
}
#endif
@end

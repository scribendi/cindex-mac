//
//  commandutils.m
//  Cindex
//
//  Created by PL on 1/15/05.
//  Copyright 2005 Indexing Research. All rights reserved.
//

#import "IRIndexDocumentController.h"
#import "IRIndexDocWController.h"
#import "IRIndexRecordWController.h"
#import "commandutils.h"
#import "sort.h"
#import "collate.h"
#import "search.h"
#import "records.h"
#import "strings_c.h"
#import "formattedtext.h"
#import "cindexmenuitems.h"
#import "utime.h"

NSString * NOTE_PROGRESSCHANGED = @"progressChanged";

typedef struct {
	char * name;
	char * abbrev;
	char * display;
} UPATTERN;

typedef struct {
	char * name;
	UPATTERN *pat;
} UPGROUP;

static UPATTERN pa[] = {
	{"", "[:l:]+","Any word"},
	{"", "(\\b[:l:]+) \\1","Repeated word"},
	{"", "[:nd:]+","Any number"},
	{"", "[:nd:]+-[:nd:]+","Any page range"},
	{"", "([:p:]+)\\1","Repeated punctuation"},
	{"", "(?<=')[^']+(?=')|(?<=\")[^\"]+(?=\")|(?<=‘)[^‘]+(?=’)|(?<=“)[^“]+(?=”)","Text in Quotes"},		// uses pos lookbehind and lookahead
	{"", "(?<=\\()[^(]+(?=\\))","Text in Parentheses"},		// uses pos lookbehind and lookahead
//	{"", "(?:[:l:]+[’' ])?[:l:][:l:]+(?:[- ][:lu:][:l:]*)?, (?:[:lu:][:l:]+|[:lu:]\\.)(?:[- ](?:[:lu:][:l:]+|[:lu:]\\.))*","Surname, Forenames(s)"},
	{"", "((?:[:l:]+[’' ])?[:lu:][:l:]+(?:[- ][:l:][:l:]*)?), ((?:[:lu:][:l:]+|(?:[:lu:]\\.)*)(?:[- ](?:[:lu:][:l:]+|(?:[:lu:]\\.)))*)","Surname, Forenames(s)"},
//	{"", "(?:[:lu:][:l:]+|[:lu:]\\.)(?:[- ](?:[:lu:][:l:]+|[:lu:]\\.))* (?:[:l:]+[’' ])?[:lu:][:l:]+(?:[- ][:l:][:l:]*)?","Forename(s) Surname"},
	{"", "((?:[:lu:][:l:]+|(?:[:lu:]\\.)*)(?:[- ](?:[:lu:][:l:]+|(?:[:lu:]\\.)))*) ((?:[:l:]+[’' ])?[:lu:][:l:]+(?:[- ][:l:][:l:]*)?)","Forename(s) Surname"},
	{"", "^$","Empty field"},
	{"", "",NULL},
};
static UPATTERN pc[] = {
	{"[:ascii:]", "[:ascii:]","ASCII character"},
	{"[:letter:]", "[:l:]","Any letter"},
	{"[]", "[a-zA-Z]","Unaccented letter"},
	{"[]", "[[:latin:]-[a-zA-Z]]","Accented letter"},
	{"[:lowercase letter:]", "[:ll:]","Lowercase letter"},
	{"[:uppercase letter:]", "[:lu:]","Uppercase letter"},
	{"[:mark:]", "[:m:]","Diacritical mark"},
	{"[:separator:]", "[:z:]","Any space"},
	{"[:symbol:]", "[:s:]","Any symbol"},
	{"[:math symbol:]", "[:sm:]","Math Symbol"},
	{"[:currency symbol:]", "[:sc:]","Currency Symbol"},
	{"[:other symbol:]", "[:so:]","Other Symbol"},
	{"[:number:]", "[:n:]","Number"},
	{"[:decimal digit number:]", "[:nd:]","Decimal number"},
	{"[:punctuation:]", "[:p:]","Punctuation"},
	{"[:dash punctuation:]", "[:pd:]","Dash punctuation"},
	{"[:open punctuation:]", "[:ps:]","Opening punctuation"},
	{"[:close punctuation:]", "[:pe:]","Closing punctuation"},
	{"[:initial punctuation:]", "[:pi:]","Opening quote"},
	{"[:final punctuation:]", "[:pf:]","Closing quote"},
	{"[:private use:]", "[:co:]","Private use"},
	{"", "",NULL},
};
static UPATTERN ps[] = {
	{"[:arabic:]", "[:arabic:]","Arabic"},
	{"[:cyrillic:]", "[:cyrillic:]","Cyrillic"},
	{"[:devanagari:]", "[:devanagari:]","Devanagari"},
	{"[:greek:]", "[:greek:]","Greek"},
	{"[:han:]", "[:han:]","Han"},
	{"[:hangul:]", "[:hangul:]","Hangul"},
	{"[:hebrew:]", "[:hebrew:]","Hebrew"},
	{"[:hiragana:]", "[:hiragana:]","Hiragana"},
	{"[:katakana:]", "[:katakana:]","Katakana"},
	{"[:latin:]", "[:latin:]","Latin"},
	{"", "",NULL},
};

static UPGROUP pg[] = {
	"General patterns",pa,
	"Character Properties",pc,
	"Scripts", ps,
};
#define UPGCOUNT (sizeof(pg)/sizeof(UPGROUP))

static NSString * IRDomain = @"com.indexres.cindex";

static char * _infos[] = {
	"All references satisfy the checks",
	"All specified records have been examined",
	"%d replacements have been made",
	"%d replacements have been made.\n%d replacements could not be made, and records have been marked",
	"%d records from the current view have been saved to “%s”.\nThe longest contains %d characters.",
	"%d records from the current view have been saved to “%s”.\nThe longest contains %d characters.\n%d records contain Unicode characters that cannot be represented in the Mac Roman character set.",
	"%d records were created; %d records were modified; %d records were marked",
	"%d cross-references have been added to the index",
	"No cross-references have been added to the index",
	"%d cross-references have been added.\n%d references were too long;\nthey can be added if you increase the record size to %d",
	"“%s” is a dictionary that you can use by choosing Spell from the Edit menu",
	"The index has been opened for reading only, and cannot be modified",
	"All fonts in the list are used in the index",
	"%d records contain characters that could not be translated.\nThese records have been marked",
	"“%s” contains, from the current view:\n  %d entries occupying %d lines\n  %d page references\n  %d cross-references",
	"Your current sort rules will not evaluate the additional fields you have permitted in records.\nTo check or change settings, choose Sort… from the Tools menu",
	"There is not enough memory to add more records to the group",
	"There are no orphaned subheadings",
	"%d cross-references were converted to full entries",
	"No cross-references were converted to full entries",
	"The index needs repair but cannot be repaired when opened for Reading Only.\nTo allow repair open the index for write access",
	"The index has been repaired.\n%d records have been repaired and marked",
	"Cindex version 4 has been released by Indexing Research.\nWould you like to know more about it?",
	"Your copy of Cindex is up-to-date",
	"During conversion Cindex changed the following characters: %s",
	"There are %d empty records in the file. These will be discarded.",
	"No errors were found in the index.",
	"The index is locked. You can view it in different formats, but cannot modify entries."
};
static char * _warnings[] = {
	"The file containing Cindex preferences is out of date.  Should Cindex replace it?",
	"The record size needs to be enlarged by %d to accommodate the specified field sizes.  Do you want to increase the record size?",
	"The group “%s” already exists.  Do you want to replace it?",
	"The page reference connector or the page and/or cross-reference separator in the import does not match that in the index.  Do you want to import records anyway?",
	"The record size needs to be enlarged by %d to accommodate the new records.  Do you want to increase the record size?",
	"The number of fields that a record may hold needs to be increased to %d to accommodate the new records. Do you want to increase the number of fields?",
	"The record size needs to be enlarged by %d to accommodate the new heading.  Do you want to increase the record size?",
	"The number of fields that a record may hold needs to be increased to %d to accommodate the new heading. Do you want to increase the number of fields?",
	"There are bad records in the file being read. Do you want to read it, ignoring bad records? (For error report hit Cancel.)",
	"The index was not closed properly when last used, and might be mis-sorted.  Do you want to re-sort it?",
	"Do you want to save changes to your current set of abbreviations?",
	"The tag set “%s” already exists.  Do you want to replace it?",
	"Do you really want to delete the tag set “%s”?",
	"Do you want to replace the phrase currently assigned to “%s”?",
	"For “See also…” references to appear in the correct position, the index must be re-sorted.  Do you want to continue?", 
	"No personal dictionary is selected. Do you want to make a new one?",
	"Compressing the index can remove records permanently, and will invalidate any record groups. Do you want to proceed?",
	"Expanding the index can substantially increase the number of records, and will invalidate any record groups. Do you want to proceed?",
	"Splitting headings can substantially increase the number of records, and cannot be undone. Do you want to proceed?",
	"The index was not closed properly when last used. It should contain %d records but contains %d. Should Cindex repair the index?",
	"Some entries use an unknown font number %d. Click Yes to assign a font. Click No to let Cindex assign the default font.",
	"This adjustment will remove locators referring to pages %d through %d. Do you want to continue?",
	"Records you are importing use \\g and \\h attributes. Cindex can convert these attributes to fonts of your choice. Do you want to continue, and convert the attributes?",
	"Some fonts associated with the index are not being used. Should Cindex remove unused fonts from the list?",
	"Do you want to save changes to record %d?",
	"This document was made by an earlier version of Cindex. Should Cindex make a new document from this one and leave the original unchanged?",
	"%d entries use an unknown font. Should Cindex assign the default font as an alternate?",
	"The record size needs to be at least %d.  Do you want to increase the record size?",
	"The index is damaged.\nShould Cindex try to repair it?",
	"By reverting to the last-saved copy you will lose any recent changes. Do you want to proceed?",
	"A document named “%s” already exists.\nDo you want to replace it?",
	"Groups are damaged.\nShould Cindex try to repair them?",
	"“%s” contains data in an unknown format.\nDo you want to read it anyway?"
};
static char * _errors[] = {
	"Internal error: %s",
	"You must be an Administrator to complete installation of Cindex.",
	"Error %d returned by file manager",
	"There was an error writing to the file",
//	"There is not enough memory to complete the command",
	"“%s” is not a valid number",
	"The pattern “%s” is improperly formed",
//	"No content for function %s",
//	"Error %d returned while adding resource “%s” to Cindex Preferences",
	"The Preferences folder can't be found",
	"The Temporary Items folder can't be found",
	"Error %d returned while installing Apple Events",
	"Error %d returned while handling Apple Event",
	"%s",
	"There was a printing error [%d]",
	"There was an error while reading record %d",
	"There was an error while writing record %d",
	"%d records would have become too long; they have been marked",
	"There was an error while reading from %s",
	"There is no record number %d",
	"Record %d is not visible in the current view",
	"The first record specified is beyond the last",
	"No record in the current view begins with “%s…”",
	"No records meet the search criteria",
	"The first reference in a range must have a lower value than the second",
	"There was an error writing to the new file",
	"The index contains the maximum possible number of records",
	"There is no more room on your disk",
	"Cindex cannot open a version %.1f index",
	"The date is unrecognizable",
	"The last date is not after the first",
	"Cindex cannot create the group “%s”",
	"Replacement text cannot be constructed from the grouping expression",
	"Text following record %d is too long to format",
//	"There was an error while attempting to close index “%s”",
	"Demoting the heading would cause one or more records to contain too many fields",
	"“%s” is the name of a built-in set. Please use another name.",
	"The tag set is too large. Try shortening tags or removing unused ones",
//	"The index “%s” is in use and cannot be replaced",
	"“%s” does not contain a Cindex index",
	"The record lacks a main heading",
	"A locator contains an improper range",
	"The locator is missing",
	"There are too few characters in the field",
	"There are too many characters in the field",
	"The field does not match its template",
	"The field contains an illegal character following ‘%c’",
	"The field contains mismatched %s",
	"Missing target: %s",
	"The spell-checker cannot open its main dictionary",
//	"The spell-checker returned error %d, %d at startup",
//	"The spell-checker returned error %d, %d at shutdown",
//	"The spell-checker returned error %d, %d when opening a personal dictionary",
//	"The spell-checker returned error %d, %d when closing a personal dictionary",
//	"The spell-checker returned error %d, %d when examining a word",
//	"The spell-checker returned error %d, %d when modifying attributes of the main dictionary",
//	"The spell-checker returned error %d, %d when adding a word to a dictionary",
//	"The spell-checker returned error %d, %d when removing a word from a dictionary",
//	"%s",
	"The dictionary “%s” already exists. Please choose another name",
	"The abbreviation contains a space or unacceptable punctuation",
//	"To use Cindex Guide, you must enable or install the Apple Guide System Extension.",
	"The index uses fonts that are unavailable. You must select permanent or temporary substitutes for %s",
	"A locator value is larger than the maximum allowed",
	"A reference spans too large a range",
	"The alternate font for %s does not exist. Select an alternate font from the Alternate menu",
	"The document is damaged or contains characters that cannot be converted.",
	"The last page specified is before the first",
	"To count records referring to particular pages you must specify both starting and ending pages",
//	"The tag set “%s” contains invalid tags and cannot be opened",
	"This style sheet is incompatible with this version of Cindex",
	"The record would contain too few fields",
	"There is not enough room in the record",
	"The locator field cannot accept text that contains a field break",
	"Top and bottom margins leave too little space for text",
	"Left and right margins leave too little space for text columns",
	"Too many page references or cross-references to format",
//	"“%s” is not a Cindex archive",
	"%s",
	"The index is badly damaged and cannot be repaired",
	"Cindex could not make a connection to the server: %s",
	"The archive contains no information about fonts",
	"The XML document cannot be parsed. %s",
	"\nSome records contain fields with mismatched <…> or {…} or a misused special character. These records are displayed in a group."
};

struct elevel{
	char beep;
	char box;
};

static struct elevel exx[4][4] ={
	{{1,1},{1,1},{2,1},{3,1}},	/* 1 sound, box; 1 sound, box; 2 sounds, box; 3 sounds, box */
	{{1,0},{1,1},{1,1},{1,1}},	/* 1 sound, no box; 1 sound, box; 1 sound, box; 1 sound, box */
	{{1,0},{1,0},{1,0},{1,0}},	/* sound, no box, always */
	{{0,1},{0,1},{0,1},{0,1}}	/* no sound, box, always */
};

short err_eflag;	/* global error flag -- TRUE after any error */

static short e_lasterr, e_samecount;
static time_t e_lasttime;
static char e_laststring[256];

static NSMenu * m_regexmenu;

static NSString * attribdescription(unsigned char style, unsigned char font);

/******************************************************************************/
short com_getdates(short scope, NSTextField * first, NSTextField * last, time_c * low, time_c * high)		/* finds & parses date range */

{
	*low = INT_MIN;
	*high = INT_MAX;
	if (scope)	{	/* if not all dates */
		NSString * fs = [first stringValue];
		NSString * ls = [last stringValue];
		NSDate * date;

		if ([fs length])	{
			date = [fs dateValue];
			if (date)
				*low = (time_c)[date timeIntervalSince1970];
			else {
				errorSheet([NSApp keyWindow], BADDATEERR,WARN);
				return 1;
			}
		}
		if ([ls length])	{
			date = [ls dateValue];
			if (date)
				*high = (time_c)[date timeIntervalSince1970];
			else {
				errorSheet([NSApp keyWindow], BADDATEERR,WARN);
				return 2;
			}
		}
		if (*low >= *high)	{ // if bad date range
			errorSheet([NSApp keyWindow], DATERANGERR,WARN);
			return -1;
		}
//		NSLog(@"%d, %d, %ld", *low, *high, time(NULL));
	}
	return (0);
}
/******************************************************************************/
short com_getrecrange(INDEX * FF, short scope, NSTextField *firstfield, NSTextField * lastfield, RECN * first, RECN * last)		/* finds start and stop recs */

{
	RECORD * recptr, *curptr;
	
	*first = 0;			/* default first we'll never start at */
	*last = UINT_MAX;			/* default one we'll never stop at */
	
	if (scope == COMR_RANGE)   {	  /* if setting range */
		char * lptr = (char *)[[firstfield stringValue] UTF8String];
		char * hptr = (char *)[[lastfield stringValue] UTF8String];
		if (*lptr)	{			/* if specifying start */
			if (!(*first = com_findrecord(FF,lptr,FALSE,WARN)))	/* bad low limit */
				return (-1);
		}
		if (*hptr)	{		/* want specifying last */
			if (recptr = rec_getrec(FF,com_findrecord(FF,hptr, TRUE,WARN))) 	{	/* if can get last matching record */
				if (curptr = [FF->owner skip:1 from:recptr])	{	/* if can get beyond */
					*last = curptr->num; 	/* set it */
					if (*first && sort_relpos(FF,*first,*last) >= 0)	/* if last not after first */
//						return (senderr(RECRANGERR,WARN));
						return (errorSheet([[NSApplication sharedApplication] keyWindow], RECRANGERR,WARN));
				}
			}
			else
				return (1);		/* bad record spec (message already sent) */
		}
	}
	else if (scope == COMR_SELECT)	{		/* selection */
		NSRange rrange = [FF->owner selectionMaxRange];
		*first = rrange.location;
		*last = rrange.length;
	}
	if (!*first && (recptr = sort_top(FF)))	/* if no first spec, and rec exists */
		*first = recptr->num;   	/* set it */
	return (0);		/* ok */
}
/******************************************************************************/
RECN com_findrecord(INDEX * FF, char *arg, short lastmatchflag, int warnmode)		/* finds record by lead or number */

{
	char astring[256], *tptr, *eptr;
	RECORD * recptr;
	RECN num;
	
	if (*arg)	{		/* if specifying a record */
		recptr = NULL;		/* set up to fail */
		strcpy(astring, *arg == ESCCHR ? arg+1 : arg);	/* make copy of search string */
		str_extend(astring);		/* make xstring */
		for (tptr = astring; (tptr = strchr(tptr,';')); tptr++) {	/* for all semicolons */
			if (*(tptr-1) != '\\')		/* if not protected */	
				*tptr = '\0';
		}		/* NB: this loop will screw up semicolons that are part of a page ref for page sort lookup */
		if (isdigit(*arg))	{				/* if number */
			num = strtoul(astring,&eptr,10);
			if (!(recptr = search_findbynumber(FF,num)))
				sendwindowerr(RECNOTEXISTERR, warnmode,num);
		}
		else {
			if (!(recptr = search_findbylead(FF,astring)))	/* else by leads */
				sendwindowerr(RECMATCHERR, warnmode, astring);
			else if (lastmatchflag)		/* if want to find last matching record */
				recptr = search_lastmatch(FF,recptr, astring,MATCH_LOOKUP|MATCH_IGNOREACCENTS|MATCH_IGNORECODES);
		}
		if (recptr)	{	// if have record
			if (sort_isignored(FF, recptr))
				sendwindowerr(RECNOTINVIEWERR, WARN,recptr->num);
			return recptr->num;
		}
	}
	return 0;
}
/*******************************************************************************/
void sendinfo(int infonum, ...)		/*  O.K. */

{
	char tbuff[256];
	va_list aptr;

	va_start (aptr, infonum);		 /* initialize arg pointer */
	vsprintf(tbuff, _infos[infonum], aptr); /* get string */
	va_end(aptr);
	NSRunInformationalAlertPanel([NSString stringWithUTF8String:tbuff],@"",@"OK", nil,nil);	// display info string
}
/*******************************************************************************/
void infoSheet(NSWindow * parent, int infonum, ...)		/*  O.K. */

{
	char tbuff[256];
	va_list aptr;
	
	va_start (aptr, infonum);		 /* initialize arg pointer */
	vsprintf(tbuff, _infos[infonum], aptr); /* get string */
	va_end(aptr);
	NSAlert * warning = [[NSAlert alloc] init];
	warning.alertStyle = NSAlertStyleInformational;
	warning.messageText = [NSString stringWithUTF8String:tbuff];
	[warning beginSheetModalForWindow:parent completionHandler:^(NSInteger result) {
		;
	}];
}
#if 0
/*******************************************************************************/
short sendinfooption(int infonum, ...)		/*  O.K. */

{
	char tbuff[256];
	va_list aptr;

	va_start (aptr, infonum);		 /* initialize arg pointer */
	vsprintf(tbuff, _infos[infonum], aptr); /* get string */
	va_end(aptr);
	return NSRunInformationalAlertPanel([NSString stringWithUTF8String:tbuff],@"",@"Yes", @"No",nil);	// display info string with option
}
#endif
/*******************************************************************************/
short sendwarning(int warnnum, ...)		/* cancel, O.K. */

{
	char tbuff[256];
	va_list aptr;

	va_start (aptr, warnnum);		 /* initialize arg pointer */
	vsprintf(tbuff, _warnings[warnnum], aptr); /* get string */
	va_end(aptr);
	return NSRunCriticalAlertPanel([NSString stringWithUTF8String:tbuff],@"",@"Yes", @"Cancel",nil);	// display warning string
}
/*******************************************************************************/
NSAlert * warningAlert(int warnnum, ...)		/* cancel, O.K. */

{
	char tbuff[256];
	va_list aptr;
	
	va_start (aptr, warnnum);		 /* initialize arg pointer */
	vsprintf(tbuff, _warnings[warnnum], aptr); /* get string */
	va_end(aptr);
	NSAlert * warning = [[NSAlert alloc] init];
	warning.alertStyle = NSAlertStyleInformational;
	warning.messageText = [NSString stringWithUTF8String:tbuff];
	[warning addButtonWithTitle:@"OK"];
	[warning addButtonWithTitle:@"Cancel"];
	return warning;
}
/*******************************************************************************/
NSAlert * criticalAlert(int warnnum, ...)		/* cancel, O.K. */

{
	char tbuff[256];
	va_list aptr;
	
	va_start (aptr, warnnum);		 /* initialize arg pointer */
	vsprintf(tbuff, _warnings[warnnum], aptr); /* get string */
	va_end(aptr);
	NSAlert * warning = [[NSAlert alloc] init];
	warning.alertStyle = NSAlertStyleCritical;
	warning.messageText = [NSString stringWithUTF8String:tbuff];
	[warning addButtonWithTitle:@"OK"];
	[warning addButtonWithTitle:@"Cancel"];
	return warning;
}
/*******************************************************************************/
short savewarning(int warnnum, ...)		/* discard, cancel, o.k. */

{
	char tbuff[256];
	va_list aptr;
	
	va_start (aptr, warnnum);		 /* initialize arg pointer */
	vsprintf(tbuff, _warnings[warnnum], aptr); /* get string */
	va_end(aptr);
	return NSRunCriticalAlertPanel(@"Changed Record",@"%@",@"Yes",@"Cancel", @"Don't Save",[NSString stringWithUTF8String:tbuff]);	// display warning string
}
/*******************************************************************************/
short senderr(int errnum, int level, ...)

{
	char tbuff[256];
	va_list aptr;
	int bcount;

	va_start(aptr, level);		 /* initialize arg pointer */
	vsprintf(tbuff, _errors[errnum], aptr); /* assemble string */
	va_end(aptr);
	if (e_lasterr != errnum || time(NULL) > e_lasttime+10 || strcmp(tbuff,e_laststring)) 	{	/* if changed error or more than 10 sec or diff string */
		e_lasterr = errnum;
		e_samecount = 0;		/* reset alert stage */
		e_lasttime = time(NULL);
	}
	strcpy(e_laststring,tbuff);
	e_samecount &= 3;			/* limit alert level */
	if (exx[level][e_samecount].box)
		NSRunAlertPanel([NSString stringWithUTF8String:tbuff],@"",@"OK", nil,nil);	// display error string
	else {
		for (bcount = 0; bcount < exx[level][e_samecount].beep; bcount++)
			NSBeep();
	}
	e_samecount++;	/* counts number of identical errors */
	err_eflag = -1;
	return (err_eflag);
}
/*******************************************************************************/
short errorSheet(NSWindow * parent, int errnum, int level, ...)

{
	char tbuff[256];
	va_list aptr;
	int bcount;
	
	va_start(aptr, level);		 /* initialize arg pointer */
	vsprintf(tbuff, _errors[errnum], aptr); /* assemble string */
	va_end(aptr);
	if (e_lasterr != errnum || time(NULL) > e_lasttime+10 || strcmp(tbuff,e_laststring)) 	{	/* if changed error or more than 10 sec or diff string */
		e_lasterr = errnum;
		e_samecount = 0;		/* reset alert stage */
		e_lasttime = time(NULL);
	}
	strcpy(e_laststring,tbuff);
	e_samecount &= 3;			/* limit alert level */
	if (exx[level][e_samecount].box) {
//		NSRunAlertPanel([NSString stringWithUTF8String:tbuff],@"",@"OK", nil,nil);	// display error string
		NSAlert * warning = [[NSAlert alloc] init];
		warning.alertStyle = NSAlertStyleCritical;
		warning.messageText = [NSString stringWithUTF8String:tbuff];
//		[warning.buttons objectAtIndex:0].keyEquivalent = @"\e";
		[warning beginSheetModalForWindow:parent completionHandler:^(NSInteger result) {
			;
		}];
	}
	else {
		for (bcount = 0; bcount < exx[level][e_samecount].beep; bcount++)
			NSBeep();
	}
	e_samecount++;	/* counts number of identical errors */
	err_eflag = -1;
	return (err_eflag);
}

/*******************************************************************************/
short sendwindowerr(int errnum, int level, ...)

{
	char tbuff[256];
	va_list aptr;
	int bcount;
	
	va_start(aptr, level);		 /* initialize arg pointer */
	vsprintf(tbuff, _errors[errnum], aptr); /* assemble string */
	va_end(aptr);
	if (e_lasterr != errnum || time(NULL) > e_lasttime+10 || strcmp(tbuff,e_laststring)) 	{	/* if changed error or more than 10 sec or diff string */
		e_lasterr = errnum;
		e_samecount = 0;		/* reset alert stage */
		e_lasttime = time(NULL);
	}
	strcpy(e_laststring,tbuff);
	e_samecount &= 3;			/* limit alert level */
	for (bcount = 0; bcount < exx[level][e_samecount].beep; bcount++)
		NSBeep();
	if (exx[level][e_samecount].box)	{
		IRIndexDocument * keydoc = [IRdc documentForWindow:[NSApp keyWindow]];
		id idelegate = [keydoc recordWindowController] ? (id)[keydoc recordWindowController] : (id)[keydoc mainWindowController];
		
		if (keydoc && [idelegate respondsToSelector:@selector(displayError:)])		// if can do status line
			[idelegate displayError:[NSString stringWithUTF8String:tbuff]];
		else
			NSRunAlertPanel([NSString stringWithUTF8String:tbuff],@"",@"OK", nil,nil);	// display error string
	}
	e_samecount++;	/* counts number of identical errors */
	err_eflag = -1;
	return (err_eflag);
}
/*******************************************************************************/
void showprogress(float percent)	/* displays progress */
{
	NSNumber * npercent = [NSNumber numberWithFloat:percent];
//	NSLog(@"Percent: %f", percent);
	[[NSNotificationCenter defaultCenter] postNotificationName:NOTE_PROGRESSCHANGED object:npercent];
	[NSApp nextEventMatchingMask:0 untilDate:[NSDate date] inMode:NSModalPanelRunLoopMode dequeue:NO];	// drive events to force notification
}
/*******************************************************************************/
NSError * makeNSError(int errnum, ...)

{
	char tbuff[256];
	va_list aptr;
	NSError * err;
	NSDictionary * dic;
	NSString * errstring;

	va_start(aptr, errnum);		 /* initialize arg pointer */
	vsprintf(tbuff, _errors[errnum], aptr); /* assemble string */
	va_end(aptr);
	errstring = [NSString stringWithUTF8String:tbuff];
	dic = [NSDictionary dictionaryWithObject:errstring forKey:NSLocalizedFailureReasonErrorKey];
	err = [NSError errorWithDomain:IRDomain code:errnum userInfo:dic];
//	NSLog([err description]);
	return err;
}
/*******************************************************************************/
int numberofdigits(unsigned long number)		/* returns number of digits in the number */

{
	int count;
	unsigned long tnum;
	
	for (count = 0,tnum = 1; tnum < number; tnum *= 10, count++)
		;
	return (count);
}
/*******************************************************************************/
void centerwindow(NSWindow * parent, NSWindow * child)	// centers window on dest

{
	NSRect destframe = [parent frame];
	NSRect wframe = [child frame];
	float xoffset = (destframe.size.width-wframe.size.width)/2;
	float yoffset = (destframe.size.height-wframe.size.height)/2;
	
	destframe.origin.x += xoffset;
	destframe.origin.y += yoffset;
	[child setFrameOrigin:destframe.origin];
	[parent addChildWindow:child ordered:NSWindowAbove];
	[child makeKeyAndOrderFront:nil];
}
/*******************************************************************************/
BOOL main_comiscancel(void)	// aborts command
{
	NSEvent * abort = [NSApp nextEventMatchingMask:NSKeyDownMask|NSLeftMouseDownMask untilDate:[NSDate date] inMode:NSModalPanelRunLoopMode dequeue:YES];
	
	if (abort) {
		NSString * kchars = nil;
		if ([abort type] == NSKeyDown)
			kchars = [abort characters];
		else if ([abort type] == NSLeftMouseDown) {
			NSWindow * wind = [abort window];
			NSView *hitview = [[wind contentView] hitTest:[abort locationInWindow]];
			if ([hitview isKindOfClass:[NSButton class]]) 
				kchars = [(NSButton *)hitview keyEquivalent];
		}
		if ([kchars length])	{
			unichar uchar = [kchars characterAtIndex:0];
			if (uchar == 0x1b)
				return YES;
		}
	}
	return NO;
}
/**********************************************************************************/
void adjustsortfieldorder(short * fieldorder, short oldtot, short newtot)	/* expands/contracts field order table, or warns */

{
	int count;

	if (oldtot != newtot)	{	/* if changed number of fields */
		for (count = 0; count < newtot && fieldorder[count] >= 0;)	{	/* until checked all fields we'll want to use */
			if (fieldorder[count] > newtot-2 && fieldorder[count] != PAGEINDEX)	/* if using a field we'll discard */
				memmove(&fieldorder[count],&fieldorder[count+1],(FIELDLIM-count)*sizeof(short));	/* copy over it */
			else
				count++;
		}
		/* now old array is adjusted for lost fields */
		if (sort_isinfieldorder(fieldorder,oldtot < newtot ? oldtot : newtot))	/* if currently in field order */
			sort_buildfieldorder(fieldorder,oldtot,newtot);
		else if (newtot > oldtot)	/* if added new fields that we don't know how to use */
			sendinfo(SORTORDERINFO);
	}
}
/*******************************************************************************/
void addregexitems(NSMenu * mm)	// adds regex items to contextual menu

{
	unsigned long group;

//	if (![mm itemWithTag:-1])	{		// if haven't already added the regex stuff
		[mm addItem:[NSMenuItem separatorItem]];
		for (group = 0; group < UPGCOUNT; group++)	{	// for all groups
			NSMenu * sm = [[NSMenu alloc] initWithTitle:@""];
			int count;
			NSMenuItem * ti;
			
			[sm setAutoenablesItems:NO];
			for (count = 0; pg[group].pat[count].display; count++)	{
				ti = [sm addItemWithTitle:[NSString stringWithUTF8String:pg[group].pat[count].display] action:@selector(setRegex:) keyEquivalent:@""];
				[ti setTag:group*100+count+1];
			}
			ti = [mm addItemWithTitle:[NSString stringWithUTF8String:pg[group].name] action:NULL keyEquivalent:@""];
			ti.tag = -1;		// so that we can detect if it's already been added
			[mm setSubmenu:sm forItem:ti];
		}
//	}
}
/*******************************************************************************/
NSString * regexfortag(NSInteger tag)		// returns regex text for tag

{
	int group = tag/100;
	int item = tag%100-1;
	
	return [NSString stringWithUTF8String: pg[group].pat[item].abbrev];
}
/*******************************************************************************/
NSMenuItem * findmenuitem(NSInteger tag)	// finds menu item with tag

{
	NSMenuItem * mitem;
	NSMenu * tempmenu;
	
	mitem = (NSMenuItem *)[[NSApp mainMenu] itemWithTag:MENUMASK(tag)];	// get item from main menu
	tempmenu = [mitem submenu];			// get menu from that item
	mitem = (NSMenuItem *)[tempmenu itemWithTag:tag];
	return mitem;
}
/*******************************************************************************/
void buildfieldmenu(INDEX * FF, NSPopUpButton * menu)	// builds popup menu for search panel
{
	#define BASEITEMCOUNT 5
	int itemcount = [menu numberOfItems];
	
	while (itemcount > BASEITEMCOUNT)
		[menu removeItemAtIndex:--itemcount];
	while (itemcount < BASEITEMCOUNT+FF->head.indexpars.maxfields-1)  {
		[menu insertItemWithTitle:[NSString stringWithUTF8String:FF->head.indexpars.field[itemcount-BASEITEMCOUNT].name] atIndex:itemcount];
		[[menu itemAtIndex:itemcount] setTag:itemcount-BASEITEMCOUNT];
		itemcount++;
	}
}
/*******************************************************************************/
void buildlabelmenu(NSMenu * labelmenu, float size) // builds properly colored label menu

{
	int count;
	
	for (count = 0; count < FLAGLIMIT-1; count++)	{
		NSColor * curcolor = [NSColor colorWithCalibratedRed:g_prefs.gen.lcolors[count].red green:g_prefs.gen.lcolors[count].green blue:g_prefs.gen.lcolors[count].blue alpha:1 ];
		NSFont * mfont = [NSFont menuFontOfSize:size];
		NSDictionary * adic = [NSDictionary dictionaryWithObjectsAndKeys:mfont,NSFontAttributeName,curcolor,NSForegroundColorAttributeName,nil];
		NSString * title = [[labelmenu itemAtIndex:count+1] title];
		NSMutableAttributedString * as = [[NSMutableAttributedString alloc]initWithString:title attributes:adic];
		
		[[labelmenu itemAtIndex:count+1] setAttributedTitle:as];
	}
}
/*******************************************************************************/
void buildattributefontmenu(INDEX *FF, NSPopUpButton * pmenu) // builds font attribute popup menu

{
	int index;
	
	[pmenu removeAllItems];
	[pmenu addItemWithTitle:@"<Default Font>"];
	for (index = 1; index < FONTLIMIT && *FF->head.fm[index].name; index++)
		[[pmenu menu] insertItemWithTitle:[NSString stringWithUTF8String:FF->head.fm[index].pname] action: nil keyEquivalent:@"" atIndex:index];
}
/*******************************************************************************/
BOOL stringiswholeword(NSControl * control)	// returns TRUE if control text is whole word
{
	NSString * cs = [control stringValue];
	NSInteger length = [cs length];
	for (int index = 0; index < length; index++)
		if (!u_isalpha([cs characterAtIndex:index]))
			return NO;
	return YES;
}
/******************************************************************************/
char * vistarget(INDEX * FF, RECORD * recptr, char *sptr, LISTGROUP *lg, short *lenptr, short subflag)	/* returns ptr if target vis */

{
	short hlevel, sprlevel, hidelevel,clevel;
	char * tptr, *uptr;
	
	if (*lenptr && (FF->head.privpars.vmode || subflag))	{	/* if finite match && formatted or substituting */
		uptr = rec_uniquelevel(FF,recptr,&hlevel,&sprlevel,&hidelevel,&clevel);		/* find unique level */
		while (sptr < uptr) 	{	/* while target before unique level */
			short mlen;
			if (tptr = search_findbycontent(FF, recptr, sptr+*lenptr, lg, &mlen))	{	/* if a target after current */
				sptr = tptr;	/* set ptr */
				*lenptr = mlen;	/* and length */
			}
			else {			/* no targets at level below unique */
				if (hlevel < PAGEINDEX || sptr+strlen(sptr) < uptr || subflag)	/* if unique level isn't lowest (unsuppressed), or substituting */
					return (NULL);		/* skip */
				break;
			}
		}
	}
	return (sptr);
}
#if 0
/******************************************************************************/
NSString * styledescriptor(unsigned char style, unsigned char font)	// returns string for styles

{
	char astring[20];
	
	*astring = '\0';
	if (style&FX_BOLD)
		strcat(astring,"B");
	if (style&FX_ITAL)
		strcat(astring,"I");
	if (style&FX_ULINE)
		strcat(astring,"U");
	if (style&FX_SMALL)
		strcat(astring,"S");
	if (style&FX_SUPER)
		strcat(astring,"Sp");
	if (style&FX_SUB)
		strcat(astring,"Sb");
	if (font)
		strcat(astring,"ƒ");
	return [NSString stringWithUTF8String:astring];
}
#endif
/******************************************************************************/
NSString * attribdescriptor(unsigned char style, unsigned char font, unsigned char forbiddenstyle, unsigned char forbiddenfont)	// returns string for styles

{
	NSMutableString * ss = [NSMutableString stringWithString:attribdescription(style,font)];
	if (forbiddenstyle || forbiddenfont)
		[ss appendFormat:@" -%@",attribdescription(forbiddenstyle,forbiddenfont)];
	return ss;
}
/******************************************************************************/
static NSString * attribdescription(unsigned char style, unsigned char font)

{
	static char tstring[20];
	
	*tstring = '\0';
	if (style&FX_BOLD)
		strcat(tstring,"B");
	if (style&FX_ITAL)
		strcat(tstring,"I");
	if (style&FX_ULINE)
		strcat(tstring,"U");
	if (style&FX_SMALL)
		strcat(tstring,"S");
	if (style&FX_SUPER)
		strcat(tstring,"Sp");
	if (style&FX_SUB)
		strcat(tstring,"Sb");
	if (font)
		strcat(tstring,"ƒ");
	return [NSString stringWithUTF8String:tstring];
}
/*******************************************************************************/
NSCursor * getcursor(NSString * name, NSPoint hotspot)	// loads cursor

{
	NSString * pictpath;
	NSImage * cursimage;

    pictpath = [[NSBundle mainBundle] pathForImageResource:name];
	cursimage = [[NSImage alloc] initWithContentsOfFile:pictpath];
	return ([[NSCursor alloc] initWithImage:cursimage hotSpot:hotspot]);
}

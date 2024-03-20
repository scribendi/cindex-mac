//
//  globals.m
//  Cindex
//
//  Created by PL on 1/10/05.
//  Copyright 2005 Indexing Research. All rights reserved.
//

#import "collate.h"

#if  (TARGET_RT_LITTLE_ENDIAN)	// if intel machine is target
NSString * CIPrefs = @"3_Preferences_I";
NSString * CIFunctionKeys = @"FunctionKeys_I";
#else
NSString * CIPrefs = @"3_Preferences";
NSString * CIFunctionKeys = @"FunctionKeys";
#endif

#if 0
char * abbrev_prefix = "\n (['\"“‘";		/* prefixes */
char * abbrev_suffix = "\r )],.;:'\"”’";   /* suffixes that can trigger expansion */
#else
unichar abbrev_prefix[] = {'\n',SPACE,'(','[','\"','\'',8220,8216,0};		/* prefixes */
unichar abbrev_suffix[] = {SPACE,')',']',',','.',';',':','\"','\'', 8221,8217,0};		// suffixes that trigger expansion
#endif
char g_nullstr[] = "";		/* a null string */
char g_nullrec[] = {0,0,'\177'};	/* null record */
int g_tzoffset;		// time zone offset from GMT (sec)

struct prefs g_prefs = {		/* preferences info */
	80002,		/* key */
	{		/* hidden */
		1,	/* verify min matches */
		7,	/* page check max count */
		0,	/* show windows for inactive indexes */
		"",	/* user ID */
		0,	/* sort abbrevs by name */
	},
	{		/* gen prefs */
		0,		/* open dialog on startup */
		FALSE,	// label sets date
		0,		/* show labels in formatted view */
		TRUE,	// smart flip
		FALSE,	// autorange
		FALSE,	/* require user id */
		TRUE,	/* propagate */
		600,	/* flush interval (sec) */
		1,		/* empty/malformed page warning */
		1,		/* bad crossref warning */
		1,		/* template mismatch alarm */
		FALSE,	/* carry refs */
		TRUE,	/* switch to draft mode for adding/editing */
		FALSE,	/* track entries */
		FALSE,	/* return edit display */
		1,		/* ask about saving changes to records */
		{		// label colors
			{1,0,0},
			{1,.5,0},
			{0,1,0},
			{0,1,1},
			{0,0,1},
			{.5,0,.5},
			{.6,.4,.2},
			{0,0,0}
		},
		{		/* fontmap array */
			{"Helvetica","Helvetica",0},
		},
		FALSE,	/* autoextend */
		FALSE,	/* ignorecase in autoextend */
		TRUE,	/* remove duplicate spaces */
		FALSE,	/* track source record */
		FALSE,	/* Mac newlines */
		0,		/* use styles to define format indents */
		0,		// use main window text size
		TRUE,	// embed sort info
		TRUE,	// check for updates
		0,		// utf-8 encoding of plain text
		PASTEMODE_STYLEONLY		// paste styles but not fonts
	},
	{			/* language preferences for spell-checker */
		TRUE,		/* always suggest */
		FALSE,		/* don't ignore words in caps */
		FALSE,		/* don't ignore alnums */
	},
	{		/* index structure pars */
		100,	/* record size */
		2,		/* minfields */
		5,		/* max fields */
		{
			{"Main", 0, 0, ""},
			{"Sub 1", 0, 0, ""},
			{"Sub 2", 0, 0, ""},
			{"Sub 3", 0, 0, ""},
			{"Sub 4", 0, 0, ""},
			{"Sub 5", 0, 0, ""},
			{"Sub 6", 0, 0, ""},
			{"Sub 7", 0, 0, ""},
			{"Sub 8", 0, 0, ""},
			{"Sub 9", 0, 0, ""},
			{"Sub 10", 0, 0, ""},
			{"Sub 11", 0, 0, ""},
			{"Sub 12", 0, 0, ""},
			{"Sub 13", 0, 0, ""},
			{"Sub 14", 0, 0, ""},
			{"Page", 0, 0, ""}
		},
	},
	{		/* sort pars */
		0,		/* raw sort */
		SORTVERSION,	// sort version
		{"en"},		// language
		{0,1,2,3,4,5,6,7,8,9,10,11,12,13,14,15,-1},	/* field order */
		{0,1,2,-1},		/* character priority */
		FALSE,	/* ignore punct in letter sort */
		FALSE,	/* ignore slash */
		FALSE,	/* eval num */
		FALSE,	// ignore paren phrase
		FALSE,	// ignore paren ending
		{"a against and as at before between by during for from in into of on the to under versus vs. with within"},
		{"\177"},	// substitutes (empty compound string)
		FALSE,	/* skip last heading field */
		TRUE,	/* ordered refs */
		TRUE,	/* ascending order refs */
		TRUE,	/* sort on */
		TRUE,	// language script first -- default is en (SORTVERSION 6 and higher)
		{1,2,-1,-1,-1},		/* reference priority (arabic & letters only) */
		{0},		/* priority table for reference types */
		{0,1,2,3,4,5,6,7,8,9,-1},	/* component comparison order */
		{0,1,2,3,-1},		// style priority
		{0},		// ref style precedence order
		0,		// symcode (unused from SORTVERSION 6)
		0,		// numcode (unused from SORTVERSION 6)
		{"en"}	// localID (SORTVERSION 6 and higher)
	},
	{		/* ref pars */
		{"See also under"},		/* cross refs begin */
		{"individual specific"},	/* excluded refs */
		{""},		/* highest valued page ref */
		';',		/* cross ref separator */
		',',		/* page ref separator */
		'-',		/* page ref connector */
		TRUE,		// recognize crossref in locator only
		0			/* max span */
	},
	{		/* private prefs */
		VM_DRAFT,	/* display mode */
		TRUE,		/* line wrap */
		FALSE,		/* show numbers */
		FALSE,		/* hide deleted records */
		ALLFIELDS,	/* hide fields below this level */
		12,			/* default font size */
		U_INCH,		/* unit in which dimensions expressed */
		FALSE,
//		{200,50,300,372},		/* default record window size/posn */
	},
	{		/* format preferences */
		sizeof(FORMATPARAMS),
		FORMVERSION,
		{		/* page format */
			{		/* margins & columns */
				72,		/* top */
				72,		/* bottom */
				72,		/* left */
				72,		/* right */
				1,		/* # columns */
				18,		/* gutter */
				FALSE,	/* reflection flag */
				1,		/* repeat broken heading after page break */
				" (Continued)",		/* continued text */
				{FX_ITAL,0},
				0,		/* heading level for continuation repeat */
			},
			{"","%","",FX_BOLD},	/* left header */
			{"#","","",FX_BOLD},	/* left footer */
			{"","%","",FX_BOLD},	/* right header */
			{"","","#",FX_BOLD},	/* right footer */
			0,				/* line spacing (single) */
			1,				/* number of first page  */
			16,				/* line height (points) */
			0,				/* extra entry space */
			1,				/* extra group space */
			U_INCH,			/* line spacing unit (inch) */
			TRUE,			/* autospacing */
			NSDateFormatterMediumStyle,		/* date format */
			FALSE,			/* don't show time */
			{				// paper info used only by Windows; need for interchange
				1,			/* DMORIENT_PORTRAIT portrait orientation */
				1,			/* DMPAPER_LETTER,letter paper */
				0,			/* no override length */
				0,			/* no override width */
				612,		/* actual width (points) */
				792			/* actual height (points) */
			}
		},
		{		/* overall heading layout */
			0,			/* run-on level */
			0, 			/* collapselevel */
			0,			/* style modifier */
			1,			/* indentation type */
			TRUE,		/* adjust punctuation */
			TRUE,		/* adjust style codes around punct */
			0,			/* use em spacing when fixed */
			0,			/* use em spacing when auto */
			1,			/* ems for auto lead */
			2.5,		/* ems for auto runover */
			{		/* grouping of entries */
				3,		/* method */
				"",		/* use default font */
				{0},	/* style */
				0,		/* size */
				"%",	/* format string */
				"",	// all numbers
				"",	// all symbols
				""	// numbers and symbols
			},
			{		/* cross-ref format */
				{
					{			/* refs from main head */
						". ",		/* see also lead */
						"",			/* end */
						". ",		/* see lead */
						"",			/* end */
					},
					{			/* refs from subhead */
						" (",		/* see also lead */
						")",			/* end */
						" (",		/* see lead */
						")",			/* end */
					}
				},
				{2},	/* lead style italic */
				{0,0},	/* body style */
				0,		/* subhead see also position (follows heading) */
				0,		/* main head see also position */
				TRUE,	/* sort cross-refs */
				FALSE,	/* don't suppress */
				0,		/* subhead see position */
				0,		/* main head see position */
				0, 		/* !! spare */
			},
			{		/* locator format */
				TRUE,		/* sort refs */
				FALSE,		/* right justify */
				FALSE,		/* suppress all (don't) */
				FALSE,		/* disable suppression of multiple parts */
				", ",		/* lead to single */
				", ",		/* lead to multiple */
				"",			/* trailing text */
				"–",		/* range connector (default en dash) */
				0,			/* conflation threshold */
				0,			/* abbreviation rule */
				"",			/* suppression sequence */
				", ",		/* concatenation characters */
				{0},   		/* style sequence */
				0,			/* leader type */
				TRUE,		// hide duplicates
				0, 			/* !! spare */
			},
			{		/* field layout/typography */
				{
					"",		/* use default font */
					0,		/* font size */
					{0},	/* style */
					0,		/* lead indent for explicit indent */
					1.5,	/* runover text for explicit indent */
					"",		/* trailing text */
					0,		// flags
					""		// lead text
				},
				{
					"",		/* use default font */
					0,		/* font size */
					{0},	/* style */
					1,		/* lead indent for explicit indent */
					2.5,	/* runover text for explicit indent */
					"",		/* trailing text */
					0,		// flags
					""		// lead text
				},
				{
					"",		/* use default font */
					0,		/* font size */
					{0},	/* style */
					2,		/* lead indent for explicit indent */
					3.5,	/* runover text for explicit indent */
					"",		/* trailing text */
					0,		// flags
					""		// lead text
				},
				{
					"",		/* use default font */
					0,		/* font size */
					{0},	/* style */
					3,		/* lead indent for explicit indent */
					4.5,	/* runover text for explicit indent */
					"",		/* trailing text */
					0,		// flags
					""		// lead text
				},
				{
					"",		/* use default font */
					0,		/* font size */
					{0},	/* style */
					4,		/* lead indent for explicit indent */
					5.5,	/* runover text for explicit indent */
					"",		/* trailing text */
				},
				{
					"",		/* use default font */
					0,		/* font size */
					{0},	/* style */
					5,		/* lead indent for explicit indent */
					6.5,	/* runover text for explicit indent */
					"",		/* trailing text */
					0,		// flags
					""		// lead text
				},
				{
					"",		/* use default font */
					0,		/* font size */
					{0},	/* style */
					6,		/* lead indent for explicit indent */
					7.5,	/* runover text for explicit indent */
					"",		/* trailing text */
					0,		// flags
					""		// lead text
				},
				{
					"",		/* use default font */
					0,		/* font size */
					{0},	/* style */
					7,		/* lead indent for explicit indent */
					8.5,	/* runover text for explicit indent */
					"",		/* trailing text */
					0,		// flags
					""		// lead text
				},
				{
					"",		/* use default font */
					0,		/* font size */
					{0},	/* style */
					8,		/* lead indent for explicit indent */
					9.5,	/* runover text for explicit indent */
					"",		/* trailing text */
					0,		// flags
					""		// lead text
				},
				{
					"",		/* use default font */
					0,		/* font size */
					{0},	/* style */
					9,		/* lead indent for explicit indent */
					10.5,	/* runover text for explicit indent */
					"",		/* trailing text */
					0,		// flags
					""		// lead text
				},
				{
					"",		/* use default font */
					0,		/* font size */
					{0},	/* style */
					10,		/* lead indent for explicit indent */
					11.5,	/* runover text for explicit indent */
					"",		/* trailing text */
					0,		// flags
					""		// lead text
				},
				{
					"",		/* use default font */
					0,		/* font size */
					{0},	/* style */
					11,		/* lead indent for explicit indent */
					12.5,	/* runover text for explicit indent */
					"",		/* trailing text */
					0,		// flags
					""		// lead text
				},
				{
					"",		/* use default font */
					0,		/* font size */
					{0},	/* style */
					12,		/* lead indent for explicit indent */
					13.5,	/* runover text for explicit indent */
					"",		/* trailing text */
					0,		// flags
					""		// lead text
				},
				{
					"",		/* use default font */
					0,		/* font size */
					{0},	/* style */
					13,		/* lead indent for explicit indent */
					14.5,	/* runover text for explicit indent */
					"",		/* trailing text */
					0,		// flags
					""		// lead text
				},
				{
					"",		/* use default font */
					0,		/* font size */
					{0},	/* style */
					14,		/* lead indent for explicit indent */
					15.5,	/* runover text for explicit indent */
					"",		/* trailing text */
					0,		// flags
					""		// lead text
				}
			}
		}
	},
	{		/* styled strings */
		"\2versus\0\2vs.\0\177"
	},
	{"a after against ~and as at before between by during for from in into of on over the to under ~versus ~vs. with within"}	// flip words
};

static BOOL createCinDirectory(void);

/**************************************************************************/
void global_registerdefaults (void)

{
    NSMutableDictionary * def = [NSMutableDictionary dictionaryWithCapacity:2];
	NSMutableDictionary * fkeys = [NSMutableDictionary dictionaryWithCapacity:15];
	NSAttributedString * astring = [[NSAttributedString alloc] initWithString:@""];
	NSData * ddata;
	int index;
	
	for (index = 0; index < 16; index++) {
		NSString *keystring = [[NSString alloc] initWithFormat:@"%d",index];
		[fkeys setObject:astring forKey:keystring];
	}
	ddata = [NSKeyedArchiver archivedDataWithRootObject:fkeys];
    [def setObject:ddata forKey:CIFunctionKeys];		// fkeys
    [def setObject:[NSData dataWithBytes:&g_prefs length:sizeof(g_prefs)] forKey:CIPrefs];		// prefs
    [[NSUserDefaults standardUserDefaults] registerDefaults:def];
}
/**************************************************************************/
void global_readdefaults (void)

{
    NSUserDefaults * def = [NSUserDefaults standardUserDefaults];
	NSData * dd;
	unsigned int key;
    
	dd = [def objectForKey:CIPrefs];
	[dd getBytes:&key length:4];		// get prefs key
    if ([dd length] == sizeof(g_prefs) && g_prefs.key == key)	{	// if structures match
		[dd getBytes:&g_prefs];			// restore preferences;
		if (g_prefs.sortpars.sversion < LOCALESORTVERSION)	// patch sort collation params (avoids invalidating all prefs)
			col_fixLocaleInfo(&g_prefs.sortpars);
	}
	else	{
		global_saveprefs(GPREF_GENERAL);	// save current
		NSRunInformationalAlertPanel(@"Preferences",@"Current settings are invalid\nDefault settings have been restored",@"OK", nil, nil);
	}
}
/**************************************************************************/
void global_saveprefs(int type)	// saves preferences settings

{
	NSUserDefaults * def = [NSUserDefaults standardUserDefaults];
	
    if (type&GPREF_GENERAL)
		[def setObject:[NSData dataWithBytes:&g_prefs length:sizeof(g_prefs)] forKey:CIPrefs];		// prefs
}
/**************************************************************************/
NSString * global_preferencesdirectory(void)	// returns User's Cindex Prefs directory

{
	NSString * path = NSHomeDirectory();
	NSString * prefsdirectory = [path stringByAppendingPathComponent:@"Library/Preferences/Cindex"];
	BOOL isdirectory;
	NSError * error;
	
	if ([[NSFileManager defaultManager] fileExistsAtPath:prefsdirectory isDirectory:&isdirectory])	{
		if (isdirectory)
			return prefsdirectory;
	}
	if ([[NSFileManager defaultManager] createDirectoryAtPath:prefsdirectory withIntermediateDirectories:NO attributes:nil error:&error])
		return prefsdirectory;
	NSLog(@"Can't create: %@ [%@]",prefsdirectory, [error localizedFailureReason]);
	return nil;
}
/**************************************************************************/
NSString * global_supportdirectory(BOOL writeable)	// returns Path to Cindex dir in Library App Support directory

{
	NSArray * parray = NSSearchPathForDirectoriesInDomains(NSApplicationSupportDirectory,NSLocalDomainMask,YES);
	NSString * supportdirectory = [[parray objectAtIndex:0] stringByAppendingPathComponent:@"Cindex"];
	BOOL isdirectory;
	NSError * error;
	
	BOOL directoryexists = [[NSFileManager defaultManager] fileExistsAtPath:supportdirectory isDirectory:&isdirectory];
	
	if (directoryexists && isdirectory || createCinDirectory()) {
		if (writeable) {
			if ([[NSFileManager defaultManager] isWritableFileAtPath:supportdirectory])
				return supportdirectory;
			NSLog(@"Can't write to: %@ [%@]",supportdirectory, [error localizedFailureReason]);
		}
		else {
			if ([[NSFileManager defaultManager] isReadableFileAtPath:supportdirectory])
				return supportdirectory;
			NSLog(@"Can't read from: %@ [%@]",supportdirectory, [error localizedFailureReason]);
		}
	}
	else
		NSLog(@"Can't create: %@",supportdirectory);
	return nil;
}
/**************************************************************************/
static BOOL createCinDirectory()	{
	
	// see https://github.com/michaelvobrien/OSXSlightlyBetterAuth
	

#if TOPREC < RECLIMIT
	return NO;
#else
	AuthorizationItem ritems[] = {
		{kAuthorizationRightExecute, 0,NULL,0},
	};
	AuthorizationItem eitems[] = {
		{kAuthorizationEnvironmentPrompt, 64,"You must be an Administrator to complete installation of Cindex.",0},
	};
	AuthorizationRights myRights;
	AuthorizationEnvironment myEnv;
	AuthorizationRef authorization;

	char *tool = "/bin/mkdir";
	char *args[] = {"-m", "775", "/Library/Application Support/Cindex", NULL};
	FILE *pipe = NULL;

	myRights.count = sizeof (ritems) / sizeof (AuthorizationItem);
	myRights.items = ritems;
	myEnv.count = sizeof (eitems) / sizeof (AuthorizationItem);
	myEnv.items = eitems;
	
	AuthorizationFlags myFlags = kAuthorizationFlagDefaults | kAuthorizationFlagInteractionAllowed |kAuthorizationFlagExtendRights;	
	OSStatus myStatus = errAuthorizationCanceled;
	if (AuthorizationCreate(&myRights,&myEnv,myFlags,&authorization) == errAuthorizationSuccess)
		myStatus = AuthorizationExecuteWithPrivileges(authorization, tool, kAuthorizationFlagDefaults, args, &pipe);
	AuthorizationFree(authorization, kAuthorizationFlagDestroyRights);
	[NSThread sleepForTimeInterval:1.0f];	// need delay before trying first access
	return myStatus == errAuthorizationSuccess ? YES : NO;
#endif
}

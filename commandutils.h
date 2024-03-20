//
//  commandutils.h
//  Cindex
//
//  Created by PL on 1/15/05.
//  Copyright 2005 Indexing Research. All rights reserved.
//

#import "indexdocument.h"

extern NSString * NOTE_PROGRESSCHANGED;

enum {		/* info message ids */
	VERIFYOK = 0,
	NOMORERECINFO,
	REPLACECOUNTINFO,
	REPLACEMARKEDINFO,
	WRITERECINFO,
	WRITERECINFOWITHERROR,
	SPLITRECINFO,
	RECGENNUMINFO,
	NONGENNUMINFO,
	RECGENSKIPINFO,
	NODICFROMFINDERINFO,
	READONLYINFO,
	ALLFONTSUSED,
	IMPORTMARKED,
	FILESTATSINFO,
	SORTORDERINFO,
	INFO_FULLGROUP,
	INFO_NOORPHANS,
	INFO_RECCONVERT,
	INFO_NORECCONVERT,
	INFO_INDEXNEEDSREPAIR,
	INFO_REPAIRMARKED,
	INFO_UPDATEAVALIABLE,
	INFO_CINUPTODATE,
	INFO_CONVERSIONCHANGES,
	EMPTYRECORDWARNING,
	CHECKINFO,
	INFO_READONLY
};

enum {			
	BADCONFIG = 0,	/* warning message ids */
	LONGFIELDWARNING,
	DUPGROUPWARNING,
	CONFLICTINGESPARATORSWARN,
	RECENLARGEWARN,
	RECFIELDNUMWARN,
	DEMOTEENLARGEWARN,
	DEMOTEFIELDNUMWARN,
	IMPORTERRORSWARN,
	CORRUPTINDEX,
	ABBREVWARNING,
	DUPTAGWARNING,
	DELTAGWARNING,
	CLEARABBREVWARNING,
	CROSSSORTWARN,
	NODICWARNING,
	SQUEEZEWARNING,
	EXPANDWARNING,
	SPLITWARNING,
	MISSINGRECORDS,
	MISSINGARCHIVEFONT,
	NEGADJUSTWARNING,
	CODETRANSLATION,
	FONTGAPWARNING,
	RECCHANGED,
	CONVERTWARNING,
	MISSINGFONTWARNING,
	SHORTRECORDWARNING,
	DAMAGEDINDEXWARNING,
	REVERTWARNING,
	OVERWRITEDOC,
	DAMAGEDGROUPS,
	BADIMPORTTYPE
};

/* error ids */
enum {
	INTERNALERR = 0,
	BADINSTALLERR,
	FILESYSERR,
	WRITEERR,
//	MEMERR,
	BADNUMERR,
	BADEXPERR,
//	NOCONTENT,
//	RESADDERR,
	BADPREFSFOLDER,
	BADTEMPFOLDER,
	AEINSTALLERR,
	AEDISPATCHERR,
	AEREPLYERR,
	PRINTERR,
	RECREADERR,
	RECWRITEERR,
	RECMARKERR,
	FILEREADERR,
	RECNOTEXISTERR,
	RECNOTINVIEWERR,
	RECRANGERR,
	RECMATCHERR,
	RECNOTFOUNDERR,
	REFORDERERR,
	EXPORTWRITEERR,
	INDEXFULLERR,
	DISKFULLERR,
	FILEVERSERR,
	BADDATEERR,
	DATERANGERR,
	GROUPCREATEERR,
	BADREPERR,
	LONGENTRYERR,
//	INDEXCLOSERR,
	EXCESSFIELDS,
	TAGDUPERR,
	TAGOVERFLOWERR,
//	OVERWRITEINDEXERR,
	UNKNOWNFILERR,
		EMPTYMAINFIELD,
		BADRANGEFIELD,
		EMPTYPAGEFIELD,
		TOOFEWCHARFIELD,
		TOOMANYCHARFIELD,
		BADPATTERNFIELD,
		BADCODEFIELD,
		MISMATCHFIELD,
		MISSINGCROSSREF,
	SPELLOPENERR,
//	SPELLCLOSERR,
//	SPELLOPENUSERERR,
//	SPELLCLOSEUSERERR,
//	SPELLWORDCHECKERR,
//	SPELLDICMODERR,
//	SPELLADDUSERERR,
//	SPELLDELUSERERR,
//	SPELLNODBERR,
//	SPELLWORDOPERR,
	SPELLDICEXISTERR,
	BADABBREVERR,
//	NOGUIDEERR,
	FONTMISSING,
	VALUETOOLARGE,
	SPANTOOLARGE,
	FONTBADSUB,
	CONVERSIONERR,
	INVALPAGERANGE,
	INVALLOCATORRANGE,
//	INVALTAGSET,
	INVALSTYLESHEET,
	TOOFEWFIELDS,
	RECOVERFLOW,
	BREAKPAGEFIELD,
	BADVERTMARGINS,
	BADHORIZMARGINS,
	TOOMANYREFSERR,
//	BADARCHIVERR,
	FILEOPENERR,
	FATALDAMAGEERR,
	NOCONNECTIONERR,
	NOFONTERR,
	BADXMLERR,
	RECORDSYNTAXERR
};

enum {			/* error level ids */
	WARN = 0,	/* 1 sound, box; 1 sound, box; 2 sounds, box; 3 sounds, box */
	WARNNB,		/* 1 sound, no box; 1 sound, box; 1 sound, box; 1 sound, box */
	WARNNEVERBOX,		/* no sound, box; 1 sound, box; 1 sound, box; 1 sound, box */
	WNEVER		/* box but never sound */
};

enum {		/* command scope flags */
	COMR_ALL,
	COMR_SELECT,
	COMR_RANGE,
	COMR_PAGE
};

#define SEC_PER_DAY ((unsigned long)86400)
#define MACTIMEOFFSET ((365L * 4L) * 24L * 60L * 60L)	/* four years worth of seconds (1900-1904) */

#define mac_from_unix_offset (2208988800UL-MACTIMEOFFSET)	/* 1970 base time from 1904 based time (Mac standard) */
#define unix_from_mac_offset (-2208988800UL+MACTIMEOFFSET)	/* 1904 based time from 1970 based time */

#define mw_to_unix_time(A) ((A) -2208988800UL-g_tzoffset)	// converts old mw ime value to local time
#define unix_to_mw_time(A) ((A) +2208988800UL+g_tzoffset) // converts local time to old mw time value

extern short err_eflag;	/* global error flag -- TRUE after any error */

short com_getdates(short scope, NSTextField * first, NSTextField * last, time_c * low, time_c * high);		/* finds & parses date range */
short com_getrecrange(INDEX * FF, short scope, NSTextField *firstfield, NSTextField * lastfield, RECN * first, RECN * last);		/* finds start and stop recs */
RECN com_findrecord(INDEX * FF, char *arg, short lastmatchflag, int warnmode);		/* finds record by lead or number */

void sendinfo(int infonum, ...);		/*  O.K. */
void infoSheet(NSWindow * parent, int infonum, ...);		/*  O.K. */
//short sendinfooption(int infonum, ...);		/*  Yes, No */
short sendwarning(int warnnum, ...);	/* cancel, ok */
NSAlert * warningAlert(int warnnum, ...);		/* cancel, O.K. */
NSAlert * criticalAlert(int warnnum, ...);		/* cancel, O.K. */
short savewarning(int warnnum, ...);		/* discard, cancel, o.k. */
short senderr(int errnum, int level, ...);
short errorSheet(NSWindow * parent, int errnum, int level, ...);
short sendwindowerr(int errnum, int level, ...);
NSError * makeNSError(int errnum, ...);

int numberofdigits(unsigned long number);		/* returns number of digits in the number */
void centerwindow(NSWindow * destwindow, NSWindow * window);	// centers window on dest
void showprogress(float percent);	/* displays progress */
BOOL main_comiscancel(void);	// aborts command
void adjustsortfieldorder(short * fieldorder, short oldtot, short newtot);	/* expands/contracts field order table, or warns */
void addregexitems(NSMenu * mm);	// adds regex items to contextual menu
NSString * regexfortag(NSInteger tag);		// returns regex text for tag
NSMenuItem * findmenuitem(NSInteger tag);	// finds menu item with tag
void buildfieldmenu(INDEX * FF, NSPopUpButton * menu);	// builds popup menu for search panel
void buildlabelmenu(NSMenu * labelmenu, float size); // builds properly colored label menu
void buildattributefontmenu(INDEX *FF, NSPopUpButton * menu); // builds font attribute popup menu
BOOL stringiswholeword(NSControl * control);	// returns TRUE if control text is whole word
char * vistarget(INDEX * FF, RECORD * recptr, char *sptr, LISTGROUP *lg, short *lenptr, short subflag);	/* returns ptr if target vis */
NSString * attribdescriptor(unsigned char style, unsigned char font, unsigned char forbiddenstyle, unsigned char forbiddenfont);	// returns string for attribs
//NSString * styledescriptor(unsigned char style, unsigned char font);	// returns string for styles
NSCursor * getcursor(NSString * name, NSPoint hotspot);	// loads cursor

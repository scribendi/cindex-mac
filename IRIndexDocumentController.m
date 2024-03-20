//
//  IRIndexDocumentController.m
//  Cindex
//
//  Created by PL on 1/8/05.
//  Copyright 2005 Indexing Research. All rights reserved.
//

#import <ExceptionHandling/NSExceptionHandler.h>
#import <Carbon/Carbon.h>
#import "IRIndexDocument.h"
#import "IRIndexArchive.h"
#import "IRIndexDocumentController.h"
#import "IRIndexDocWController.h"
#import "IRIndexTextWController.h"
#import "SplashWindowController.h"
#import "UserIDController.h"
#import "FindController.h"
#import "ReplaceController.h"
#import "SpellController.h"
#import "HTTPService.h"
#import "cindexmenuitems.h"
#import "commandutils.h"
#import "collate.h"
#import "type.h"
#import "v1handler.h"
#import "v3handler.h"

#import "PreferencesController.h"
#import "MarkupTagsController.h"
#import "AbbreviationController.h"
#import "FunctionkeyController.h"
#import "MarginColumnController.h"
#import "HeadFootController.h"
#import "GroupingController.h"
#import "StyleLayoutController.h"
#import "HeadingsController.h"
#import "CrossRefsController.h"
#import "PageRefsController.h"
#import "StyledStringsController.h"
#import "FlipStringsController.h"
#import "RecordStructureController.h"
#import "RefSyntaxController.h"
#import "SortController.h"

#import "unicode/ucnv.h"

NSString * CIOpenFolder = @"OpenFolder";
NSString * CIIndexFolder = @"IndexFolder";
NSString * CIStyleSheetFolder = @"StyleSheetFolder";
NSString * CIBackupFolder = @"BackupFolder";
NSString * CIAbbreviations = @"Abbreviations";
NSString * CILastIndex = @"LastIndex";
NSString * CIXMLTagSet = @"XMLTagSet";
NSString * CISGMLTagSet = @"SGMLTagSet";


IRIndexDocumentController * IRdc;		// global for doc controller
//IRIndexDocument * IRrevertsource;
//BOOL cancelERR;			// global for cancelling error messages

NSArray * _fonts;
NSMutableDictionary * _abbreviations;

@interface IRIndexDocumentController () {
	
}
@property (weak) IRIndexDocument * activeIndex;

- (void)_saveStyleSheet:(NSURL *)url;
- (void)_setActiveIndex:(NSNotification *)aNotification;		// finds doc for mainwindow
@end

@implementation IRIndexDocumentController

- (id)init	{
    self = [super init];
	IRdc = self;		// global ref to instance
    return self;
}
- (BOOL)validateMenuItem:(NSMenuItem *)mitem {
	NSInteger itemid = [mitem tag];
	IRIndexDocument * doc = self.currentDocument;
	
//	NSLog(@"%ld: %@",itemid, [mitem title]);
	if (doc.currentSheet || [doc readForbidden:itemid])
		return NO;
	if (itemid == MI_FIND || itemid == MI_REPLACE || itemid == MI_SPELL)
		return [[[doc mainWindowController] window] isMainWindow];	// if document && active window is main
	if ([doc recordWindowController] || [[[doc textWindowController] window] isMainWindow])		// if there's a record window or active is text
		return itemid == MI_ABBREVIATIONS || itemid == MI_TAGS || itemid == MI_FKEYS || itemid == MI_OPEN || mitem.parentItem.tag == MI_RECENT;	// only these items available for record or text window
	if (itemid == MI_RECSTRUCTURE && doc && [doc iIndex]->curfile)	// if viewing a group
		return NO;
	return [super validateMenuItem:mitem];
}
- (BOOL)applicationShouldOpenUntitledFile:(id)sender {
    return NO;
}
- (void)applicationDidUpdate:(NSNotification *)note {
	_lastKeyWindow = [NSApp keyWindow];
}
- (NSWindow *)lastKeyWindow {
	return _lastKeyWindow;
}
- (void)applicationWillFinishLaunching:(NSNotification *)note {
	NSExceptionHandler * handler = [NSExceptionHandler defaultExceptionHandler];
	NSData * abbrevs;

// #ifdef _DEBUG_ON
//	[handler setExceptionHangingMask:NSHangOnUncaughtSystemExceptionMask|NSHangOnUncaughtRuntimeErrorMask];
//#endif
	[handler setExceptionHandlingMask:NSLogUncaughtExceptionMask/* |NSHandleUncaughtSystemExceptionMask|NSHandleUncaughtRuntimeErrorMask */
		|NSHandleTopLevelExceptionMask|NSHandleUncaughtExceptionMask|NSHandleOtherExceptionMask];
	[handler setDelegate:self];
	ucnv_setDefaultName("UTF-8");	// set default code page
//	NSLog(@"%s",ucnv_getDefaultName());
	col_findlocales();		// find potential collators
	if ((GetCurrentKeyModifiers()&shiftKey))	{	// if shift key down (no cocoa function for this)
		NSString *appDomain = [[NSBundle mainBundle] bundleIdentifier];	// remove & rebuild all defaults for app
		[[NSUserDefaults standardUserDefaults] removePersistentDomainForName:appDomain];
	}
	global_registerdefaults();
	global_readdefaults();	// load defaults
	
//	NSApplicationPresentationOptions opt = [NSApplication sharedApplication].currentSystemPresentationOptions;
//	[NSApplication sharedApplication].presentationOptions = opt & ~NSApplicationPresentationFullScreen;
	
	[SplashWindowController showWithButton:NO];
	abbrevs = [NSData dataWithContentsOfFile:[[NSUserDefaults standardUserDefaults] objectForKey:CIAbbreviations]];
	if (abbrevs)
		[self setAbbreviations:[NSKeyedUnarchiver unarchiveObjectWithData:abbrevs]];
	else
		[[NSUserDefaults standardUserDefaults] setObject:nil forKey:CIAbbreviations];	// no abbrevs
	_fonts = [[[NSFontManager sharedFontManager] availableFontFamilies] sortedArrayUsingSelector:@selector(caseInsensitiveCompare:)];
	g_tzoffset = [[NSTimeZone localTimeZone] secondsFromGMT];
	buildlabelmenu([findmenuitem(MI_LABELED) submenu],14);
	[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(_setActiveIndex:) name:NSWindowDidBecomeMainNotification object:nil];

#if TOPREC < RECLIMIT	// disable update for Student or Demo
	[findmenuitem(MI_CHECKUPDATE) setTarget:nil];
	[findmenuitem(MI_CHECKUPDATE) setState:NSOffState];
#endif
//	[findmenuitem(MI_HIDEINACTIVE) setState: g_prefs.hidden.hideinactive ? NSOnState : NSOffState];	// set hide/show menu
}
- (void)applicationDidFinishLaunching:(NSNotification *)note {
	if (g_prefs.gen.setid)	{	// if want prompt for user id
		UserIDController * uid = [[UserIDController alloc] init];
		[NSApp runModalForWindow:[uid window]];
	}
	if (![[self documents] count])	{	// if didn't open anything by double-click
		if (g_prefs.gen.openflag == 1)	// if want open panel
			[self openDocument:self];
		else if (g_prefs.gen.openflag == 2)	{	// else if want to open last index
			NSString * lastPath = [[NSUserDefaults standardUserDefaults] objectForKey:CILastIndex];
			if (lastPath && [[NSFileManager defaultManager] fileExistsAtPath:lastPath])
//				[self openDocumentWithContentsOfURL:[NSURL fileURLWithPath:lastPath] display:YES error:&err];
				[self openDocumentWithContentsOfURL:[NSURL fileURLWithPath:lastPath] display:YES completionHandler:^(NSDocument *document, BOOL alreadyOpen, NSError *error){
					if (error)
						NSLog(@"%@",[error description]);
				}];
			else
				[self openDocument:self];
		}
	}
	[[NSAppleEventManager sharedAppleEventManager] setEventHandler:self andSelector:@selector(getUrl:withReplyEvent:) forEventClass:kInternetEventClass andEventID:kAEGetURL];
	[[[HTTPService alloc] init] check:nil];	// check
}
- (void)getUrl:(NSAppleEventDescriptor *)event withReplyEvent:(NSAppleEventDescriptor *)replyEvent {
	NSString * url = [[event paramDescriptorForKeyword:keyDirectObject] stringValue]; // Now you can parse the URL and perform whatever action is needed }
//	NSLog(url);
}
- (void)applicationWillTerminate:(NSNotification *)note {
	[[NSNotificationCenter defaultCenter] removeObserver:self];
	[_spellWindow close];		// force graceful close of speller (save personal dic)
	global_saveprefs(GPREF_GENERAL);
}
- (BOOL)application:(NSApplication *)sender openFile:(NSString *)filename {
	NSURL* url = [NSURL fileURLWithPath:filename isDirectory:NO];
	[self openDocumentWithContentsOfURL:url display:YES completionHandler:^(NSDocument *document, BOOL alreadyOpen, NSError *error){
		if (!alreadyOpen && error && error.code != NSUserCancelledError) {
			if (error.code == 61)
				senderr(FILEOPENERR, WARN,error.localizedDescription.UTF8String);
			else
				senderr(FILEOPENERR, WARN,"The document cannot be opened.");
		}
//		NSLog(@"%@",[error description]);
	}];
	return YES;
}
- (id)makeUntitledDocumentOfType:(NSString*)type error:(NSError **)err {
	if ([type isEqualToString:CINIndexType])	// if new index
//		return [IRIndexDocument newDocumentWithMessage:@"" error:err];
		return [IRIndexDocument newDocumentFromURL:nil error:err];
	return [super makeUntitledDocumentOfType:type error:err];
}
-(void)addDocument:(NSDocument *)document {
	if ([[document fileType] isEqualToString:CINStyleSheetType])	// it stylesheet
		[document close];		// discard it
	else
		[super addDocument:document];   // add it
}
- (void)noteNewRecentDocument:(NSDocument *)aDocument	{
	if (!self.IRrevertsource)	// if not reverting
		[super noteNewRecentDocument:aDocument];
}
- (int)convertpath:(NSString *)oldpath newpath:(NSString **)newpath extension:(NSString *)extension type:(unsigned long)type{
	int code = -1;	// presume error
	if (sendwarning(CONVERTWARNING))		{	// if want to make new file
		*newpath = [[oldpath stringByDeletingPathExtension] stringByAppendingPathExtension:extension];
		if (![[NSFileManager defaultManager] fileExistsAtPath:*newpath]	// if doesn't exist
			|| sendwarning(OVERWRITEDOC,[[*newpath lastPathComponent] UTF8String]))	{	// or want to overwrite
			[[NSFileManager defaultManager] removeItemAtPath:*newpath error:NULL];
			if ([[NSFileManager defaultManager] copyItemAtPath:oldpath toPath:*newpath error:NULL])	{
				NSDictionary * adic = [NSDictionary dictionaryWithObject:[NSNumber numberWithUnsignedLong:type] forKey:NSFileHFSTypeCode];
				[[NSFileManager defaultManager] setAttributes:adic ofItemAtPath:*newpath error:NULL];
				code = 1;	// ok
			}
		}
		else	// didn't want to overwrite
			code = 0;
	}
	else		// didn't want to convert
		code = 0;
	return code;
}
#if 1
- (void)openDocumentWithContentsOfURL:(NSURL *)url display:(BOOL)displayDocument completionHandler:(void (^)(NSDocument *document, BOOL documentWasAlreadyOpen, NSError *error))completionHandler {
	NSString * path = [NSString stringWithString:[url path]];
	NSString * docType = [self typeForContentsOfURL:url error:NULL];
	NSError * err = [NSError errorWithDomain:NSCocoaErrorDomain code:NSUserCancelledError userInfo:nil];	// suppress any error
	BOOL ok = FALSE;		// default for file that needs conversion
	int creturn;
	NSString * newpath;
	
	if ([docType isEqualToString:CINV2IndexType] || [docType isEqualToString:CINV1IndexType])	{	// if convertable index
		NSString * tpath = [[path stringByDeletingPathExtension] stringByAppendingPathExtension:CINIndexExtension];
		NSDocument * opendoc = [self documentForURL:[NSURL fileURLWithPath:tpath]];
		if (opendoc)	// if new doc already open
			completionHandler(opendoc,TRUE,nil);
		else {
			creturn = [self convertpath:path newpath:&newpath extension:CINIndexExtension type:CIN_NDX];
			if (creturn > 0)
				ok = v3_convertindex(newpath,docType);
//			else if (creturn == 0)
//				completionHandler(nil,FALSE,err);
		}
	}
	else if ([docType isEqualToString:CINV2StationeryType] || [docType isEqualToString:CINV1StationeryType])	{
		creturn = [self convertpath:path newpath:&newpath extension:CINStationeryExtension type:CIN_STAT];
		if (creturn > 0)
			ok = v3_convertindex(newpath,docType);
//		else if (creturn == 0)
//			completionHandler(nil,FALSE,err);
	}
	else if ([docType isEqualToString:CINV2StyleSheetType] || [docType isEqualToString:CINV1StyleSheetType])	{
		creturn = [self convertpath:path newpath:&newpath extension:CINStyleSheetExtension type:CIN_FORM];
		if (creturn > 0)
			ok = v3_convertstylesheet(newpath,docType);
//		else if (creturn == 0)
//			completionHandler(nil,FALSE,err);
	}
	else	{		// existing index; open normally
		newpath = path;
		ok = TRUE;
	}
	if (ok)	{	// if ok to open file
		NSURL * nurl = [NSURL fileURLWithPath:newpath];
		BOOL display = ![[self typeForContentsOfURL:nurl error:NULL] isEqualToString:CINStyleSheetType];
		
		if ([docType isEqualToString:CINV2IndexType] || [docType isEqualToString:CINV1IndexType] ||
			[docType isEqualToString:CINV2StationeryType] || [docType isEqualToString:CINV1StationeryType])	{
			char warnings[500];
			
			if (v3_warnings(warnings))
				sendinfo(INFO_CONVERSIONCHANGES,warnings);
		}
		[[NSUserDefaults standardUserDefaults] setObject:[newpath stringByDeletingLastPathComponent] forKey:CIOpenFolder];	// save directory as current default
		return [super openDocumentWithContentsOfURL:nurl display:display completionHandler:completionHandler];
	}
	if (creturn < 0) {	// must be conversion error (not cancelled)
		[[NSFileManager defaultManager] removeItemAtPath:newpath error:NULL];	// delete any new file
		senderr(CONVERSIONERR, WARN);
	}
	completionHandler(nil,FALSE,err);
}
#else
- (id)openDocumentWithContentsOfURL:(NSURL *)url display:(BOOL)displayDocument error:(NSError **)err	{
	NSString * path = [NSString stringWithString:[url path]];
	NSString * docType = [self typeForContentsOfURL:url error:NULL];
	BOOL ok = FALSE;		// default for file that needs conversion
	int creturn; 
	NSString * newpath;
	
	if (err)
		*err = [NSError errorWithDomain:NSCocoaErrorDomain code:NSUserCancelledError userInfo:nil];	// suppress any error
	if ([docType isEqualToString:CINV2IndexType] || [docType isEqualToString:CINV1IndexType])	{	// if convertable index
		NSString * tpath = [[path stringByDeletingPathExtension] stringByAppendingPathExtension:CINIndexExtension];
		NSDocument * opendoc = [self documentForURL:[NSURL fileURLWithPath:tpath]];
		if (opendoc)	// if new doc already open
			return opendoc;
		creturn = [self convertpath:path newpath:&newpath extension:CINIndexExtension type:CIN_NDX];
		if (creturn > 0)
			ok = v3_convertindex(newpath,docType);
		else if (creturn == 0)
			return nil;
	}
	else if ([docType isEqualToString:CINV2StationeryType] || [docType isEqualToString:CINV1StationeryType])	{
		creturn = [self convertpath:path newpath:&newpath extension:CINStationeryExtension type:CIN_STAT];
		if (creturn > 0)
			ok = v3_convertindex(newpath,docType);
		else if (creturn == 0)
			return nil;
	}
	else if ([docType isEqualToString:CINV2StyleSheetType] || [docType isEqualToString:CINV1StyleSheetType])	{
		creturn = [self convertpath:path newpath:&newpath extension:CINStyleSheetExtension type:CIN_FORM];
		if (creturn > 0)
			ok = v3_convertstylesheet(newpath,docType);
		else if (creturn == 0)
			return nil;
	}
	else	{
		newpath = path;	// existing index; open normally
		ok = TRUE;
	}
	if (ok)	{	// if ok to open file
		NSURL * nurl = [NSURL fileURLWithPath:newpath];
		BOOL display = ![[self typeForContentsOfURL:nurl error:NULL] isEqualToString:CINStyleSheetType];
		
		if ([docType isEqualToString:CINV2IndexType] || [docType isEqualToString:CINV1IndexType] ||
			[docType isEqualToString:CINV2StationeryType] || [docType isEqualToString:CINV1StationeryType])	{
			char warnings[500];
			
			if (v3_warnings(warnings))
				sendinfo(INFO_CONVERSIONCHANGES,warnings);
		}
		[[NSUserDefaults standardUserDefaults] setObject:[newpath stringByDeletingLastPathComponent] forKey:CIOpenFolder];	// save directory as current default
		return [super openDocumentWithContentsOfURL:nurl display:display error:err];
	}
	// must be conversion error
	[[NSFileManager defaultManager] removeItemAtPath:newpath error:NULL];	// delete any new file
//	if (!ok)
//		*err = makeNSError(CONVERSIONERR);
	senderr(CONVERSIONERR, WARN);
	return nil;
}
#endif
- (NSDocument *)makeDocumentWithContentsOfURL:(NSURL *)url ofType:(NSString *)typeName error:(NSError * _Nullable *)outError {
	IRIndexDocument * newndx;
	if ([typeName isEqualToString:CINArchiveType] || [typeName isEqualToString:CINXMLRecordType] ||
			[typeName isEqualToString:CINDelimitedRecords] || [typeName isEqualToString:DOSDataType] ||
			[typeName isEqualToString:MBackupType] || [typeName isEqualToString:SkyType]) {
		
		NSString * fileName = [url path];
		NSString * newname = [[fileName stringByDeletingPathExtension] stringByAppendingPathExtension:CINIndexExtension];
		
		if ([[NSFileManager defaultManager] fileExistsAtPath:newname])		// if file exists
#if 0
			newndx = [IRIndexDocument newDocumentWithMessage:[NSString stringWithFormat:@"Create a new index from the archive \"%@\"",[fileName lastPathComponent]] error:outError];		// set up for naming new
		else
			newndx = [[IRIndexDocument alloc] initWithName:newname hideExtension:[[NSSavePanel savePanel] isExtensionHidden] error:outError];
#else
			newndx = [IRIndexDocument newDocumentFromURL:url error:outError];		// set up for naming new
		else
			newndx = [[IRIndexDocument alloc] initWithName:newname template:nil hideExtension:[[NSSavePanel savePanel] isExtensionHidden] error:outError];
#endif
		if (newndx)	{	// if have created new index
			if ([[IRIndexArchive alloc] initWithContentsOfURL:url ofType:typeName forIndex:[newndx iIndex]])
				return (id)newndx;
			[[NSFileManager defaultManager] removeItemAtPath:newname error:nil];
		}
		return nil;
	}
	else if ([typeName isEqualToString:CINStationeryType])	{
#if 0
		NSString * message = [NSString stringWithFormat:@"Create a new index from the template \"%@\"",[[url path] lastPathComponent]];
		newndx = [IRIndexDocument newDocumentWithMessage:message error:outError];
		if (newndx)
			return [newndx initWithTemplateURL:url error:outError];
		return nil;
#else
		return [IRIndexDocument newDocumentFromURL:url error:outError];
#endif
	}
	return [super makeDocumentWithContentsOfURL:url ofType:typeName error:outError];
}
- (NSInteger)runModalOpenPanel:(NSOpenPanel *)openPanel forTypes:(NSArray *)openableFileExtensions {
	NSString * defaultPath = [[NSUserDefaults standardUserDefaults] stringForKey:CIOpenFolder];
	NSArray * types = [NSArray arrayWithObjects:
				CINIndexExtension,NSFileTypeForHFSTypeCode(CIN_NDX),
				CINIndexV2Extension,NSFileTypeForHFSTypeCode(CIN_V2NDX),
				CINIndexV1Extension,NSFileTypeForHFSTypeCode(CIN_V1NDX),
				CINStyleSheetExtension,NSFileTypeForHFSTypeCode(CIN_FORM),
				CINV1StyleSheetExtension,NSFileTypeForHFSTypeCode(CIN_V1FORM),
				CINV2StyleSheetExtension,NSFileTypeForHFSTypeCode(CIN_V2FORM),
				@"ixml",
				@"arc",NSFileTypeForHFSTypeCode(CIN_MDAT),
				@"tdxf",NSFileTypeForHFSTypeCode(CIN_STAT),
				@"sdxf",NSFileTypeForHFSTypeCode(CIN_V1STAT),nil];
	int result;
	
	if (defaultPath)
		[openPanel setDirectoryURL:[NSURL fileURLWithPath:defaultPath isDirectory:YES]];
	result = [super runModalOpenPanel:openPanel forTypes:types];
	[[NSUserDefaults standardUserDefaults] setObject:[[openPanel directoryURL] path] forKey:CIOpenFolder];
	return result;
}
- (void)menuNeedsUpdate:(NSMenu *)menu	{	// used to enable/disable submenus
	NSInteger tag = [[menu itemAtIndex:0] tag]/100;
	if (tag == 0 && [[menu title] isEqualToString:@"View"])	// to deal with added tab items in view menu (sierra + removes menu tag)
		tag = MIM_VIEW/100;
	switch (tag)  {   // use tag to identify menu
		case MIM_FILE/100:
			break;
		case MIM_EDIT/100:
			[[self currentDocument] checkEditItems:menu];
			break;
		case MIM_VIEW/100:
			[[self currentDocument] checkViewItems:menu];
			break;
		case MIM_FORMAT/100:
			[[self currentDocument] checkFormatItems:menu];
			break;
		case MIM_DOCUMENT/100:
			break;
		case MIM_TOOLS/100:
			break;
	}
}
- (BOOL)loadStyleSheet:(STYLESHEET *)sp {
	IRIndexDocument * doc = [self documentForWindow:[NSApp mainWindow]];
	FONTMAP * fmp;

	if (doc) {	// if to load into index
		INDEX * FF = [doc iIndex];
		FF->head.formpars = sp->fg;
		fmp = &FF->head.fm[0];
		FF->head.privpars.size = sp->fontsize;
	}
	else {		// preferences
		g_prefs.formpars = sp->fg;
		fmp = &g_prefs.gen.fm[0];
		g_prefs.privpars.size = sp->fontsize;
	}
	strcpy(fmp->pname,sp->fm.pname);		/* set preferred */
	if (type_available(sp->fm.pname))	/* if it exists */
		strcpy(fmp->name,sp->fm.pname);		/* set alt */
	if (doc) {	// if need to apply to index
		[doc redisplay:0 mode:VD_RESET];
		[doc configurePrintInfo];
		[[NSNotificationCenter defaultCenter] postNotificationName:NOTE_REVISEDLAYOUT object:doc];
	}
	return YES;
}
- (IBAction)saveStyleSheet:(id)sender {
	NSSavePanel *savepanel = [NSSavePanel savePanel];
	IRIndexDocument * curdoc = [self currentDocument];
	NSString * defaultDirectory = [[NSUserDefaults standardUserDefaults] stringForKey:CIStyleSheetFolder];
	
	if (defaultDirectory)
		[savepanel setDirectoryURL:[NSURL fileURLWithPath:defaultDirectory isDirectory:YES]];
	[savepanel setCanSelectHiddenExtension:YES];
    [savepanel setAllowedFileTypes:[NSArray arrayWithObject:CINStyleSheetExtension]];
	if (curdoc)	{
		[savepanel setNameFieldStringValue:[curdoc displayName]];
		[savepanel beginSheetModalForWindow:[NSApp mainWindow] completionHandler:^(NSInteger result) {
			if (result == NSFileHandlingPanelOKButton)
				[self _saveStyleSheet:[savepanel URL]];
			[[NSUserDefaults standardUserDefaults] setObject:[[savepanel directoryURL] path] forKey:CIStyleSheetFolder];
		}];
	}
	else {
		[savepanel setTitle:@"Save Style Sheet"];
		if ([savepanel runModal] == NSFileHandlingPanelOKButton)
			[self _saveStyleSheet:[savepanel URL]];
	}
}
- (IBAction)showFindPanel:(id)sender {
	if (!_findWindow) 
		_findWindow = [[FindController alloc] init];
	[_findWindow showWindow:[self currentDocument]];
}
- (IBAction)showReplacePanel:(id)sender {
	if (!_replaceWindow) 
		_replaceWindow = [[ReplaceController alloc] init];
	[_replaceWindow showWindow:[self currentDocument]];
}
- (IBAction)showSpellPanel:(id)sender {
	if (!_spellWindow) 
		_spellWindow = [[SpellController alloc] init];
	[_spellWindow showWindow:[self currentDocument]];
}
#if 0		// use if implement hideinactive
- (IBAction)hideInactiveDocuments:(id)sender	 {
	g_prefs.hidden.hideinactive ^= 1;		// switch state
	[sender setState: g_prefs.hidden.hideinactive ? NSOnState : NSOffState];		// hide/show menu
	global_saveprefs(GPREF_GENERAL);
	if (g_prefs.hidden.hideinactive)
		[[self currentDocument] showWindows];
	else
		[[self documents] makeObjectsPerformSelector:@selector(showWindows)];
}
#endif
- (void)setAbbreviations:(NSMutableDictionary *)abbrev {
	_abbreviations = abbrev;
}
- (NSMutableDictionary *)abbreviations {
	return _abbreviations;
}
- (NSArray *)fonts {
	return _fonts;
}
- (NSPanel *)findPanel {
	return (NSPanel *)[_findWindow window];
}
- (NSPanel *)replacePanel {
	return (NSPanel *)[_replaceWindow window];
}
- (void)_saveStyleSheet:(NSURL *)url {
	NSMutableData * sdata = [NSMutableData dataWithLength:sizeof(STYLESHEET)];
	STYLESHEET * ss = [sdata mutableBytes];
	IRIndexDocument * cd = [self currentDocument];
	
	ss->endian = TARGET_RT_LITTLE_ENDIAN;
	if (cd)	{
		INDEX * FF = [cd iIndex];
		ss->fg = FF->head.formpars;
		ss->fm = FF->head.fm[0];		/* set up default stuff */
		ss->fontsize = FF->head.privpars.size;
	}
	else {
		ss->fg = g_prefs.formpars;
		ss->fm = g_prefs.gen.fm[0];
		ss->fontsize = g_prefs.privpars.size;
	}
	if ([sdata writeToURL:url atomically:YES])	{
		NSDictionary * sdic = [[NSFileManager defaultManager] attributesOfItemAtPath:[url path] error:nil];
		NSMutableDictionary * mdic = [NSMutableDictionary dictionaryWithDictionary:sdic];
		
		[mdic setObject:[NSNumber numberWithUnsignedLong:CIN_REF] forKey:NSFileHFSCreatorCode];
		[mdic setObject:[NSNumber numberWithUnsignedLong:CIN_FORM] forKey:NSFileHFSTypeCode];
		[[NSFileManager defaultManager] setAttributes:mdic ofItemAtPath:[url path] error:nil];
	}
}
- (IBAction)showPreferences:(id)sender {
	PreferencesController * pc = [[PreferencesController alloc] init];
	[NSApp runModalForWindow:[pc window]];
}
- (IBAction)showMarkupTags:(id)sender {
	MarkupTagsController * tc = [[MarkupTagsController alloc] init];
	[NSApp runModalForWindow:[tc window]];
}
- (IBAction)setMarginsColumns:(id)sender {
	[self showPanel:[[MarginColumnController alloc] init]];
}
- (IBAction)setHeadersFooters:(id)sender {
	[self showPanel:[[HeadFootController alloc] init]];
}
- (IBAction)setGrouping:(id)sender {
	[self showPanel:[[GroupingController alloc] init]];
}
- (IBAction)setStyleLayout:(id)sender {
	[self showPanel:[[StyleLayoutController alloc] init]];
}
- (IBAction)setHeadings:(id)sender {
	[self showPanel:[[HeadingsController alloc] init]];
}
- (IBAction)setCrossRefs:(id)sender {
	[self showPanel:[[CrossRefsController alloc] init]];
}
- (IBAction)setPageRefs:(id)sender {
	[self showPanel:[[PageRefsController alloc] init]];
}
- (IBAction)setStyledStrings:(id)sender {
	[self showPanel:[[StyledStringsController alloc] init]];
}
- (IBAction)setRecordStructure:(id)sender {
	[self showPanel:[[RecordStructureController alloc] init]];
}
- (IBAction)setRefSyntax:(id)sender {
	[self showPanel:[[RefSyntaxController alloc] init]];
}
- (IBAction)setFlipWords:(id)sender {
	[self showPanel:[[FlipStringsController alloc] init]];
}
- (IBAction)setSort:(id)sender {
	[self showPanel:[[SortController alloc] init]];
}
- (IBAction)showAbbreviations:(id)sender {
	[AbbreviationController showWithExpansion:nil];
}
- (IBAction)showFunctionKeys:(id)sender {
	[FunctionkeyController show];
}
- (void)showPanel:(NSWindowController *)panel{
	if (self.currentDocument)		// if there's a document, run as sheet
		[self.currentDocument showSheet:panel];
	else 	// run as panel
		[NSApp runModalForWindow:panel.window];
}
- (void)_setActiveIndex:(NSNotification *)aNotification {		// finds doc for mainwindow
	IRIndexDocument * tdoc = [self documentForWindow:[aNotification object]];
	
	if (tdoc != self.activeIndex)	{	// if changed active document
//		NSLog(@"%d, %@",tdoc, [tdoc displayName]);
		self.activeIndex = tdoc;
		[[NSNotificationCenter defaultCenter] postNotificationName:NOTE_ACTIVEINDEXCHANGED object:self.activeIndex];
	}
}
- (BOOL)exceptionHandler:(NSExceptionHandler *)sender shouldHandleException:(NSException *)exception mask:(NSUInteger)aMask {
	NSString * actionstring;
	
	if ([[self currentDocument] displayName])
		actionstring = [NSString stringWithFormat:@"\nYou should close the index “%@” and reopen it",[[self currentDocument] displayName]];
	else
		actionstring = @"";
	if ([[exception name] isEqualToString:IRRecordException])		{// if record exception
		NSBeep();
		NSRunAlertPanel(@"Cannot Read Record",@"%@%@",@"OK", nil,nil, [exception reason],actionstring);	// display warning string
		return NO;
	}
	else if ([[exception name] isEqualToString:IRDocumentException])		{// if document exception
		NSBeep();
		NSRunAlertPanel(@"Cannot Format Record",@"%@%@",@"OK", nil,nil, [exception reason],actionstring);	// display warning string
		return NO;
	}
	else {
		// do something to close gracefully when we can, then allow handler to work
//		actionstring = @"Cindex must Quit";
//		NSRunCriticalAlertPanel(@"Internal Error",@"%@\n%@\n%@",@"OK", nil,nil,[exception name], [exception reason],actionstring);	// display warning string
#ifdef _DEBUG_ON
		NSLog(@"%@", [exception description]);
#endif
		return YES;
	}
}
@end

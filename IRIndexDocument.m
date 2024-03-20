//
//  IRIndexDocument.m
//  Cindex
//
//  Created by PL on 11/27/04.
//  Copyright Indexing Research 2004. All rights reserved.
//

#import "IRIndexDocumentController.h"
#import "IRIndexDocument.h"
#import "IRIndexArchive.h"
#import "IRIndexDocWController.h"
#import "IRIndexTextWController.h"
#import "IRIndexRecordWController.h"
#import "ExportOptionsController.h"
#import "FindController.h"
#import "ReplaceController.h"
#import "SearchController.h"
#import "formattedtext.h"
#import "drafttext.h"
#import "commandutils.h"
#import "strings_c.h"
#import "index.h"
#import "sort.h"
#import "group.h"
#import "records.h"
#import "cindexmenuitems.h"
#import "type.h"
#import "export.h"
#import "rtfwriter.h"
#import "taggedtextwriter.h"
#import "xpresswriter.h"
#import "xmlwriter.h"
#import "imwriter.h"
#import "indesign.h"
#import "textwriter.h"
#import "tags.h"
#import "swap.h"
#import "search.h"
#import "collate.h"
#import "utime.h"
#import "IRPrintAccessoryController.h"

NSString * CINIndexType 		= @"com.example.cindex";
NSString * CINStationeryType 	= @"com.example.cindex.template";
NSString * CINXMLRecordType 	= @"com.example.cindex.ixml";
NSString * CINArchiveType 		= @"com.example.cindex.archive";
NSString * CINDelimitedRecords 	= @"com.example.delimited";
NSString * CINPlainTextType 	= @"public.plain-text";
NSString * CINRTFType 			= @"public.rtf";
NSString * CINQuarkType 		= @"com.quark.xpress";
NSString * CINInDesignType 		= @"com.adobe.indesign";
NSString * CINIMType 			= @"com.index.manager";
NSString * CINXMLType 			= @"public.xml";
NSString * CINTaggedText 		= @"com.example.cindex.sgml";
NSString * CINStyleSheetType 	= @"com.example.cindex.stylesheet";
NSString * CINV1IndexType 		= @"com.example.cindex-v1";
NSString * CINV2IndexType 		= @"com.example.cindex-v2";
NSString * CINV2StationeryType 	= @"com.example.cindex-v2.template";
NSString * CINV1StationeryType 	= @"com.example.cindex-v1.template";
NSString * CINAbbrevType 		= @"com.example.cindex.abbreviations";
NSString * CINV2StyleSheetType 	= @"com.example.cindex.stylesheet-v2";
NSString * CINV1StyleSheetType 	= @"com.example.cindex.stylesheet-v1";
NSString * DOSDataType 			= @"com.example.cindex.dos-data";
NSString * SkyType 				= @"com.sky.text";
NSString * MBackupType 			= @"com.macrex.backup";

NSString * CINDataType = @"Delimited Data";

NSString * IRDocumentException = @"IRDocumentException";
NSString * IRRecordException = @"IRRecordException";
NSString * IRMappingException = @"IRMappingException";

NSString * CINIndexExtension = @"ucdx";
NSString * CINIndexV2Extension = @"cdxf";
NSString * CINIndexV1Extension = @"ndxf";
NSString * CINStationeryExtension = @"utpl";
NSString * CINArchiveExtension = @"xaf";
NSString * CINAbbrevExtension = @"abrf";
NSString * CINStyleSheetExtension = @"ustl";
NSString * CINV2StyleSheetExtension = @"cfr2";
NSString * CINV1StyleSheetExtension = @"cfrm";
NSString * CINTagExtension = @"cstg";
NSString * CINXMLTagExtension = @"cxtg";
NSString * CINMainDicExtension = @"dic";
NSString * CINPDicExtension = @"pdic";

NSString * NOTE_HEADERFOOTERCHANGED = @"headerFooterChanged";
NSString * NOTE_REDISPLAYDOC = @"redisplayIndex";
NSString * NOTE_REVISEDLAYOUT = @"layoutIndex";
NSString * NOTE_FONTSCHANGED = @"fontChanged";
NSString * NOTE_NEWKEYTEXT = @"functionKeyChanged";
NSString * NOTE_INDEXWILLCLOSE = @"indexWillCLose";
NSString * NOTE_CONDITIONALOPENRECORD = @"conditionalOpenRecord";
NSString * NOTE_PAGEFORMATTED = @"pageFormatted";
//NSString * NOTE_AUTOSAVE = @"autoSave";
NSString * NOTE_PREFERENCESCHANGED = @"preferencesChanged";
NSString * NOTE_GLOBALLYCHANGING = @"globallyChanging";
NSString * NOTE_STRUCTURECHANGED = @"structureChanged";
NSString * NOTE_ACTIVEINDEXCHANGED = @"indexChanged";

NSString * NOTE_SCROLLKEYEVENT = @"scrollKeyEvent";

// notification dictionary keys
NSString * TextRangeKey = @"textRange";
NSString * TextLengthChangeKey = @"textLengthChange";
NSString * RecordNumberKey = @"recordNumber";
NSString * RecordRangeKey = @"recordRange";
NSString * ViewModeKey = @"viewMode";
NSString * RecordAttributesKey = @"recordAttributes";

/********************************************/

@interface IRIndexDocument () {
//	NSTimer * saveTimer;
}
@property (weak) NSTimer * saveTimer;

- (IRIndexDocument *)_buildSummary;
//- (void)_setLastSavedName:(NSString *)name;
- (BOOL)_installIndex;
- (void)_checkFixes;	// does minor version fixups
- (BOOL)_savePrivateBackup;		// saves private backup of active in
- (BOOL)_duplicateIndexToFile:(NSString *)file;
- (void)_prefsChanged;
- (void)setAutosave:(double)seconds;
@end

@implementation IRIndexDocument

#if 0
+ (id)newDocumentWithMessage:(NSString *)message error:(NSError **)err {		// creates new index file
	NSSavePanel * savepanel = [NSSavePanel savePanel];
	NSString * defaultFolder = [[NSUserDefaults standardUserDefaults] stringForKey:CIOpenFolder];
	
	if (defaultFolder)
		[savepanel setDirectoryURL:[NSURL fileURLWithPath:defaultFolder isDirectory:YES]];
	[savepanel setTitle:@"New Index"];
	[savepanel setMessage:message];
	[savepanel setNameFieldLabel:@"Create as"];
	[savepanel setAllowedFileTypes:[NSArray arrayWithObject:CINIndexExtension]];
	[savepanel setCanSelectHiddenExtension:YES];
	if ([savepanel runModal] == NSFileHandlingPanelOKButton)
//		return [[IRIndexDocument alloc] initWithName:[[savepanel URL] path] hideExtension:[savepanel isExtensionHidden] error:err];
		return [[IRIndexDocument alloc] initWithName:[[savepanel URL] path] template:nil hideExtension:[savepanel isExtensionHidden] error:err];
	if (err)
		*err = [NSError errorWithDomain:NSCocoaErrorDomain code:NSUserCancelledError userInfo:nil];	// canceled; suppress any error
	return nil;
}
#endif
+ (id)newDocumentFromURL:(NSURL *)url error:(NSError **)err {		// creates new index (from template or archive as relevant)
	NSSavePanel * savepanel = [NSSavePanel savePanel];
	NSString * defaultFolder = [[NSUserDefaults standardUserDefaults] stringForKey:CIOpenFolder];
	NSString * message;
	
	if (url) {	// if from template or archive
		NSString * ext = [[url path] pathExtension];
		if ([ext caseInsensitiveCompare:@"utpl"] == NSOrderedSame)
			message = [NSString stringWithFormat:@"Create a new index from the template \"%@\"",[[url path] lastPathComponent]];
		else	{
			message = [NSString stringWithFormat:@"Create a new index from the archive \"%@\"",[[url path] lastPathComponent]];
			url = nil;		// make sure we don't mistake archive for template
		}
	}
	else
		message = @"";
	if (defaultFolder)
		[savepanel setDirectoryURL:[NSURL fileURLWithPath:defaultFolder isDirectory:YES]];
	[savepanel setTitle:@"New Index"];
	[savepanel setMessage:message];
	[savepanel setNameFieldLabel:@"Create as:"];
	[savepanel setAllowedFileTypes:[NSArray arrayWithObject:CINIndexExtension]];
	[savepanel setCanSelectHiddenExtension:YES];
	if ([savepanel runModal] == NSFileHandlingPanelOKButton)
		return [[IRIndexDocument alloc] initWithName:[[savepanel URL] path] template:url hideExtension:[savepanel isExtensionHidden] error:err];
	if (err)
		*err = [NSError errorWithDomain:NSCocoaErrorDomain code:NSUserCancelledError userInfo:nil];	// canceled; suppress any error
	return nil;
}
- (id)init {
    if (self = [super init]) {
		_index.head.endian = TARGET_RT_LITTLE_ENDIAN;
		_index.head.headsize = HEADSIZE;		/* size of header */
		_index.head.version = CINVERSION; 		/* version under which file created */
		_index.head.indexpars = g_prefs.indexpars;
		_index.head.sortpars = g_prefs.sortpars;
//		_index.head.sortpars.sversion = SORTVERSION;
		_index.head.refpars = g_prefs.refpars;
		_index.head.privpars = g_prefs.privpars;
		_index.head.formpars = g_prefs.formpars;
		str_xcpy(_index.head.stylestrings,g_prefs.stylestrings);	/* copy style strings */
		strcpy(_index.head.flipwords,g_prefs.flipwords);	// copy flip words
		memcpy(_index.head.fm,g_prefs.gen.fm,sizeof(g_prefs.gen.fm));	/* copy local font set */
		type_checkfonts(_index.head.fm);	/* sets up font ids */

		_index.lastflush = time(NULL);
		_index.head.createtime = _index.head.squeezetime = _index.opentime = (time_c)_index.lastflush;
		_index.owner = self;
		_index.formBuffer = malloc(EBUFSIZE+2)+2;	// buffer is prefixed by 2 empty chars for addressing underflow (e.g., transposepunct)
		[self setHasUndoManager:NO];
//		[self setPrintInfo:[NSPrintInfo sharedPrintInfo]];
		
		// initializing export type labels
		[self initializeExportTypes];
    }
    return self;
}
- (id)initWithName:(NSString *)name template:(NSURL *)template hideExtension:(BOOL)hide error:(NSError **)err {	// creates new index with name
	NSError * dError;
	if ([self initWithTemplateURL:template error:err]) {
		
		// initializing export type labels
		[self initializeExportTypes];
		
		if ([[NSData data] writeToFile:name options:NSDataWritingWithoutOverwriting error:&dError])	{
			NSMutableDictionary * adic = [NSMutableDictionary dictionaryWithCapacity:3];
			
			[adic setObject:[NSNumber numberWithBool:hide] forKey:NSFileExtensionHidden];
			[adic setObject:[NSNumber numberWithUnsignedLong:CIN_REF] forKey:NSFileHFSCreatorCode];
			[adic setObject:[NSNumber numberWithUnsignedLong:CIN_NDX] forKey:NSFileHFSTypeCode];
			[self setFileURL:[NSURL fileURLWithPath:name]];
			[self setFileType:CINIndexType];
			[[NSFileManager defaultManager] setAttributes:adic ofItemAtPath:name error:nil];
			if (mfile_open(&_index.mf,(char *)[name UTF8String],O_RDWR|O_EXLOCK,HEADSIZE))	{
				if ([self _installIndex])		// if can complete setup
					return self;
				mfile_close(&_index.mf);
			}
		}
		[self close];
		[[NSFileManager defaultManager] removeItemAtPath:name error:NULL];	// delete file
		if (err)
			*err = makeNSError(FILEOPENERR, [[dError localizedDescription] UTF8String]);
	}
	return nil;	// no file
}

- (void) initializeExportTypes {
	// initializing export type labels
	   NSArray<NSString *> * labels = @[
		   @"Cindex Index",
		   @"Cindex Template",
		   @"XML Records",
		   @"Cindex Archive",
		   @"Delimited Records",
		   @"Plain Text",
		   @"Rich Text Format",
		   @"QuarkXPress",
		   @"InDesign",
		   @"Index-Manager",
		   @"XML Tagged Text",
		   @"SGML Tagged Text",
	   ];
	   NSArray<NSString *> * types = @[
		   CINIndexType,
		   CINStationeryType,
		   CINXMLRecordType,
		   CINArchiveType,
		   CINDelimitedRecords,
		   CINPlainTextType,
		   CINRTFType,
		   CINQuarkType,
		   CINInDesignType,
		   CINIMType,
		   CINXMLType,
		   CINTaggedText
	   ];

	   _exportTypeLabels = [NSDictionary dictionaryWithObjects:labels forKeys:types];
}

#if 0
- (id)initWithTemplateURL:(NSURL *)url error:(NSError **)outError	{
	HEAD * header = (HEAD *)[[NSData dataWithContentsOfFile:[url path]] bytes];
	if (header)	{
		swap_Header(header);	// swap bytes as necessary
		_index.head.indexpars = header->indexpars;
		_index.head.sortpars = header->sortpars;
		_index.head.refpars = header->refpars;
		_index.head.privpars = header->privpars;
		_index.head.formpars = header->formpars;
		str_xcpy(_index.head.stylestrings,g_prefs.stylestrings);	// copy style strings
		strcpy(_index.head.flipwords,g_prefs.flipwords);	// copy flip words
		memcpy(_index.head.fm,header->fm,sizeof(header->fm));	/* copy local font set */
		if ([self _installIndex])
			return self;
	}
	if (outError)
		*outError = makeNSError(FILEOPENERR, @"The template cannot be read.");
	return nil;
}
#else
- (id)initWithTemplateURL:(NSURL *)url error:(NSError **)outError	{
	if (self = [super init]) {
		if (url) {		// if want from template
			HEAD * header = (HEAD *)[[NSData dataWithContentsOfFile:[url path]] bytes];
			if (header)	{
				swap_Header(header);	// swap bytes as necessary
				_index.head.headsize = header->headsize;		/* size of header */
				_index.head.version = header->version; 		/* version under which file created */
				_index.head.indexpars = header->indexpars;
				_index.head.sortpars = header->sortpars;
				_index.head.refpars = header->refpars;
				_index.head.privpars = header->privpars;
				_index.head.formpars = header->formpars;
				str_xcpy(_index.head.stylestrings,header->stylestrings);	// copy styled strings
				strcpy(_index.head.flipwords,header->flipwords);	// copy flip words
				memcpy(_index.head.fm,header->fm,sizeof(header->fm));	/* copy local font set */
			}
			else {
				if (outError)
					*outError = makeNSError(FILEOPENERR, @"The template cannot be read.");
				return nil;
			}
		}
		else {	// new index with defult settings
			_index.head.headsize = HEADSIZE;		/* size of header */
			_index.head.version = CINVERSION; 		/* version under which file created */
			_index.head.indexpars = g_prefs.indexpars;
			_index.head.sortpars = g_prefs.sortpars;
			_index.head.refpars = g_prefs.refpars;
			_index.head.privpars = g_prefs.privpars;
			_index.head.formpars = g_prefs.formpars;
			str_xcpy(_index.head.stylestrings,g_prefs.stylestrings);	/* copy styled strings */
			strcpy(_index.head.flipwords,g_prefs.flipwords);	// copy flip words
			memcpy(_index.head.fm,g_prefs.gen.fm,sizeof(g_prefs.gen.fm));	/* copy local font set */
			type_checkfonts(_index.head.fm);	/* set up font ids */
		}
		_index.head.endian = TARGET_RT_LITTLE_ENDIAN;
		_index.lastflush = time(NULL);
		_index.head.createtime = _index.head.squeezetime = _index.opentime = (time_c)_index.lastflush;
		_index.owner = self;
		_index.formBuffer = malloc(EBUFSIZE+2)+2;	// buffer is prefixed by 2 empty chars for addressing underflow (e.g., transposepunct)
		[self setHasUndoManager:NO];
	}
	return self;
}
#endif
- (void)dealloc {
	[[NSNotificationCenter defaultCenter] removeObserver:self];
	free(_index.formBuffer-2);	// allowing for the prefix chars
	ucol_close(_index.collator.ucol);
	[self closeSummary];
	grp_closecurrent(&_index);
	if (_index.lastfile)
		grp_dispose(_index.lastfile);
	self.lastSavedName = nil;
	if (!(self == IRdc.IRrevertsource))	// if we're not the source of a reversion
		[[NSFileManager defaultManager] removeItemAtPath:_backupPath error:NULL];		// remove any backup file
	IRdc.IRrevertsource = nil;
}
- (void)makeWindowControllers {
	_mainWindowController = [[IRIndexDocWController alloc] init];
	[self addWindowController:(NSWindowController *)_mainWindowController];
}
- (void)removeWindowController:(NSWindowController *)controller {
    if (controller == _textWindowController)
        _textWindowController = nil;
    if (controller == _recordWindowController) {
        _recordWindowController = nil;
		[_mainWindowController setDisplayForEditing:NO adding:NO];
	}
    [super removeWindowController:controller];
}
- (BOOL)_duplicateIndexToFile:(NSString *)file	{
	BOOL result = NO;
	if ([self flush])	{
		if (index_setworkingsize(&_index,0))	{	// if can resize index
			[[NSFileManager defaultManager] removeItemAtPath:file error:NULL];		// remove any existing file with name of destination
			result = [[NSFileManager defaultManager] copyItemAtURL:[self fileURL] toURL:[NSURL fileURLWithPath:file] error:nil];
			index_setworkingsize(&_index,MAPMARGIN);
		}
	}
	return result;
}
- (IBAction)saveDocument:(id)sender {
	// need to intercept this because in 10.5 & higher following call posts alert about file change
	//- (void)saveDocumentWithDelegate:(id)delegate didSaveSelector:(SEL)didSaveSelector contextInfo:(void *)contextInfo 
	if (![self _savePrivateBackup])	{
		senderr(FILEOPENERR,WARN,"There was an error while saving the index.");
	}
}
#if 0
- (BOOL)saveToURL:(NSURL *)absoluteURL ofType:(NSString *)typeName forSaveOperation:(NSSaveOperationType)saveOperation error:(NSError **)outError	{
	NSString * file = [absoluteURL path];
	
	if ([typeName isEqualToString:CINIndexType])	{	// saving native index
		if ([IRdc documentForURL:absoluteURL])		{	// if trying to overwrite an open index
			if (outError)
				*outError = makeNSError(FILEOPENERR,"You cannot replace an index that is in use.");
			return NO;
		}
	}
	if ([typeName isEqualToString:CINTaggedText]) {	// if might want to change extension on tagged text
		char * extn = ts_gettagsetextension(ts_getactivetagsetpath(SGMLTAGS));
		if (*extn) {		// if want to supply extension for the file
			file = [[file stringByDeletingPathExtension] stringByAppendingPathExtension:[NSString stringWithUTF8String:extn]];
			absoluteURL = [NSURL fileURLWithPath:file];
		}
	}
//	[self _setLastSavedName:[file lastPathComponent]];	// reset reported filename
	self.lastSavedName = [file lastPathComponent];
	return [super saveToURL:absoluteURL ofType:typeName forSaveOperation:saveOperation error:outError];
}
#else
- (void)saveToURL:(NSURL *)absoluteURL ofType:(NSString *)typeName forSaveOperation:(NSSaveOperationType)saveOperation completionHandler:(void (^)(NSError *errorOrNil))completionHandler {
	NSString * file = [absoluteURL path];
	NSError * outError = nil;
	
	// override typeName to our stored type
	if ( _selectedTypeForSaveToOperation != nil && ![typeName isEqual:_selectedTypeForSaveToOperation] ) {
		typeName = _selectedTypeForSaveToOperation;
	}
	
	if ([typeName isEqualToString:CINIndexType])	{	// saving native index
		if ([IRdc documentForURL:absoluteURL])	{	// if trying to overwrite an open index
			outError = makeNSError(FILEOPENERR,"You cannot replace an index that is in use.");
			completionHandler(outError);
			return;
		}
	}
	if ([typeName isEqualToString:CINTaggedText]) {	// if might want to change extension on tagged text
		char * extn = ts_gettagsetextension(ts_getactivetagsetpath(SGMLTAGS));
		if (*extn) {		// if want to supply extension for the file
			file = [[file stringByDeletingPathExtension] stringByAppendingPathExtension:[NSString stringWithUTF8String:extn]];
			absoluteURL = [NSURL fileURLWithPath:file];
		}
	}
	//	[self _setLastSavedName:[file lastPathComponent]];	// reset reported filename
	self.lastSavedName = [file lastPathComponent];
	[super saveToURL:absoluteURL ofType:typeName forSaveOperation:saveOperation completionHandler:completionHandler];
}
#endif
- (NSDictionary *)fileAttributesToWriteToURL:(NSURL *)nURL ofType:(NSString *)type forSaveOperation:(NSSaveOperationType)op originalContentsURL:(NSURL *)oURL error:(NSError **)error {
    NSMutableDictionary * dic = [NSMutableDictionary dictionaryWithDictionary:[super fileAttributesToWriteToURL:nURL ofType:type forSaveOperation:op originalContentsURL:oURL error:error]];
    
    [dic setObject:[NSNumber numberWithBool:[self fileNameExtensionWasHiddenInLastRunSavePanel]] forKey:NSFileExtensionHidden];
	if ([type isEqualToString:CINIndexType]) {
		[dic setObject:[NSNumber numberWithUnsignedLong:CIN_REF] forKey:NSFileHFSCreatorCode];
        [dic setObject:[NSNumber numberWithUnsignedLong:CIN_NDX] forKey:NSFileHFSTypeCode];
	}
	else if ([type isEqualToString:CINArchiveType]) {
		[dic setObject:[NSNumber numberWithUnsignedLong:CIN_REF] forKey:NSFileHFSCreatorCode];
        [dic setObject:[NSNumber numberWithUnsignedLong:CIN_MDAT] forKey:NSFileHFSTypeCode];
	}
	else if ([type isEqualToString:CINXMLRecordType]) {
		[dic setObject:[NSNumber numberWithUnsignedLong:CIN_REF] forKey:NSFileHFSCreatorCode];
        [dic setObject:[NSNumber numberWithUnsignedLong:CIN_XMLDAT] forKey:NSFileHFSTypeCode];
	}
	else if ([type isEqualToString:CINStationeryType]) {
		[dic setObject:[NSNumber numberWithUnsignedLong:CIN_REF] forKey:NSFileHFSCreatorCode];
        [dic setObject:[NSNumber numberWithUnsignedLong:CIN_STAT] forKey:NSFileHFSTypeCode];
	}
	else if ([type isEqualToString:CINDelimitedRecords]) {
		[dic setObject:[NSNumber numberWithUnsignedLong:CIN_REF] forKey:NSFileHFSCreatorCode];
        [dic setObject:[NSNumber numberWithUnsignedLong:CIN_TEXT] forKey:NSFileHFSTypeCode];
	}
	else if ([type isEqualToString:DOSDataType]) {
		[dic setObject:[NSNumber numberWithUnsignedLong:CIN_REF] forKey:NSFileHFSCreatorCode];
        [dic setObject:[NSNumber numberWithUnsignedLong:CIN_TEXT] forKey:NSFileHFSTypeCode];
	}
	else if ([type isEqualToString:CINRTFType]) {
		[dic setObject:[NSNumber numberWithUnsignedLong:'MSWD'] forKey:NSFileHFSCreatorCode];
        [dic setObject:[NSNumber numberWithUnsignedLong:'RTF '] forKey:NSFileHFSTypeCode];
	}
	else if ([type isEqualToString:CINQuarkType]) {
		[dic setObject:[NSNumber numberWithUnsignedLong:'XPR3'] forKey:NSFileHFSCreatorCode];
        [dic setObject:[NSNumber numberWithUnsignedLong:CIN_TEXT] forKey:NSFileHFSTypeCode];
	}
	else if ([type isEqualToString:CINPlainTextType]) {
		[dic setObject:[NSNumber numberWithUnsignedLong:CIN_WILD] forKey:NSFileHFSCreatorCode];
        [dic setObject:[NSNumber numberWithUnsignedLong:CIN_TEXT] forKey:NSFileHFSTypeCode];
	}
	else if ([type isEqualToString:CINIMType]) {
		[dic setObject:[NSNumber numberWithUnsignedLong:CIN_WILD] forKey:NSFileHFSCreatorCode];
        [dic setObject:[NSNumber numberWithUnsignedLong:CIN_TEXT] forKey:NSFileHFSTypeCode];
	}
    return dic;
}

// Method to handle extension change for the custom `accessoryView` for `Save To` NSSavePanel
- (IBAction) typeSelectorChange:(id)sender {
	
	// only continue for `Save To` operation
	if ( _saveOp != NSSaveToOperation )
		return;
	
	// get selected label
	NSString * selectedOption = [(NSPopUpButton *) sender titleOfSelectedItem];
	
	// identify tagged formats for their changed names
	if ( [selectedOption containsString:[_exportTypeLabels objectForKey:CINXMLType]] || [selectedOption containsString:[_exportTypeLabels objectForKey:CINTaggedText]] ) {
		selectedOption = ( [selectedOption containsString:[_exportTypeLabels objectForKey:CINXMLType]] ) ? [_exportTypeLabels objectForKey:CINXMLType] : [_exportTypeLabels objectForKey:CINTaggedText];
	}
	
	// parse the type from selected label
	NSString * selectedType = [_exportTypeLabels allKeysForObject:selectedOption][0];
	// Parse the extension from the selected type
	NSString * selectedExtension = [self fileNameExtensionForType:selectedType saveOperation:NSSaveToOperation];
	
	if ( selectedExtension == nil ) {
		NSLog(@"Invalid extension; exiting...");
		// unset stored extension
		_selectedTypeForSaveToOperation = nil;
		return;
	}
	
	// fetch the parent NSSavePanel
	NSSavePanel * savePanel = (NSSavePanel *)[sender window];
	
	// set the correct extension for the file type
	[savePanel setAllowedFileTypes:@[selectedExtension]];
	
	// save selected type in our variable for use in `saveToURL` method
	_selectedTypeForSaveToOperation = selectedType;
	
	// set export params and `Options` button state
	[self setExportParams:selectedType];

}

- (NSArray<NSString *> *)writableTypesForSaveOperation:(NSSaveOperationType)saveOperation {
	
	// checking if _exportTypeLabels is initialized
	if ( _exportTypeLabels == NULL )
		[self initializeExportTypes];
	
	if ( saveOperation == NSSaveToOperation ) {
		// get allowed file types
		NSArray * types = [super writableTypesForSaveOperation:saveOperation];
		
		// initialize type selector NSPopUpButton
		_typeSelector = [[NSPopUpButton alloc] initWithFrame:NSMakeRect(10, 0, 50, 50)];
		
		// iterate through the types array and add them to the NSPopUpButton
		for ( NSString * docType in types ) {
			// get the label from the label dictionary
			NSString * typeLabel = [_exportTypeLabels objectForKey:docType];
			
			// process tagged labels (XML Tagged Text, SGML Tagged Text)
			if ( [docType isEqual:CINXMLType] || [docType isEqual:CINTaggedText] ) {
				typeLabel = [NSString stringWithFormat:@"%@ [%@]", typeLabel,ts_getactivetagsetname(( [docType isEqual:CINXMLType] ) ? XMLTAGS : SGMLTAGS)];
			}
			
			NSMenuItem * menuItem = [[NSMenuItem alloc] initWithTitle:typeLabel action:NULL keyEquivalent:@""];
			[[_typeSelector menu] addItem:menuItem];
		}
		[_typeSelector setAction:@selector(typeSelectorChange:)];
	}
	
	return [super writableTypesForSaveOperation:saveOperation];
}

- (BOOL)prepareSavePanel:(NSSavePanel *)savePanel {	// to customize save panel for saving
	if (_saveOp == NSSaveToOperation)	{		// if need to deal with accessory views
		NSStackView * stack = [[NSStackView alloc] init];
		
		// initialize `Options` button and disable it by default
		_optionsButton = [[NSButton alloc] initWithFrame:NSMakeRect(0,0,103,32)];
		[_optionsButton setBezelStyle:NSRoundedBezelStyle];
		[_optionsButton setTitle:@"Options…"];
		[_optionsButton sizeToFit];
		[_optionsButton setAction:@selector(getExportOptions:)];
		[_optionsButton setEnabled:NO];
		
		// Text field label for the type selector
		NSTextField * typeSelectorLabel = [NSTextField labelWithString:@"File Format: "];
		[typeSelectorLabel setFont:[NSFont fontWithName:[[typeSelectorLabel font] fontName] size:11]];
	
		// Append all elements to the NSStackView
		[stack setViews:@[typeSelectorLabel, _typeSelector, _optionsButton] inGravity:NSStackViewGravityCenter];
		stack.edgeInsets = NSEdgeInsetsMake(20, 10, 20, 20);
		
		// set the accessoryView for the "Save To" NSSavePanel
		[savePanel setAccessoryView:stack];
		
		export_setdefaultparams(&_index,E_NATIVE);
		[savePanel setDelegate:self];
	}
	return YES;
}
- (IBAction)getExportOptions:(id)sender {
	NSWindowController * panel = [[ExportOptionsController alloc] init];
	[panel setDocument:self];
	[NSApp runModalForWindow:[panel window]];
}
- (void)panelSelectionDidChange:(id)sender	{
//	NSLog(@"selection changed");
}

// Modifying the existing method to accommodate the param change
- (void)setExportParams:(NSString *) dataType {
	
	if ([dataType isEqualToString:CINIndexType]) {
		[_optionsButton setEnabled:NO];
		export_setdefaultparams(&_index,E_NATIVE);
	}
	else if ([dataType isEqualToString:CINStationeryType]) {
		[_optionsButton setEnabled:NO];
		export_setdefaultparams(&_index,E_STATIONERY);
	}
	else if ([dataType isEqualToString:CINArchiveType]) {
		[_optionsButton setEnabled:YES];
		export_setdefaultparams(&_index,E_ARCHIVE);
	}
	else if ([dataType isEqualToString:CINXMLRecordType]) {
		[_optionsButton setEnabled:YES];
		export_setdefaultparams(&_index,E_XMLRECORDS);
	}
	else if ([dataType isEqualToString:CINDelimitedRecords]) {
		[_optionsButton setEnabled:YES];
		export_setdefaultparams(&_index,E_TAB);
	}
	else if ([dataType isEqualToString:CINPlainTextType]) {
		[_optionsButton setEnabled:YES];
		export_setdefaultparams(&_index,E_TEXTNOBREAK);
	}
	else if ([dataType isEqualToString:DOSDataType]) {
		[_optionsButton setEnabled:YES];
		export_setdefaultparams(&_index,E_DOS);
	}
	else if ([dataType isEqualToString:CINRTFType]) {
		[_optionsButton setEnabled:YES];
		export_setdefaultparams(&_index,E_RTF);
	}
	else if ([dataType isEqualToString:CINQuarkType]) {
		[_optionsButton setEnabled:YES];
		export_setdefaultparams(&_index,E_XPRESS);
	}
	else if ([dataType isEqualToString:CINInDesignType]) {
		[_optionsButton setEnabled:YES];
		export_setdefaultparams(&_index,E_INDESIGN);
	}
	else if ([dataType isEqualToString:CINXMLType]) {
		[_optionsButton setEnabled:YES];
		export_setdefaultparams(&_index,E_XMLTAGGED);
	}
	else if ([dataType isEqualToString:CINTaggedText]) {
		[_optionsButton setEnabled:YES];
		export_setdefaultparams(&_index,E_TAGGED);
	}
	else if ([dataType isEqualToString:CINIMType]) {
		[_optionsButton setEnabled:YES];
		export_setdefaultparams(&_index,E_INDEXMANAGER);
	}
	else
		[_optionsButton setEnabled:NO];
}
//- (void)_setLastSavedName:(NSString *)name {
//	_eparams.lastSavedName = name;
//}
- (void)runModalSavePanelForSaveOperation:(NSSaveOperationType)op delegate:(id)delegate didSaveSelector:(SEL)sel contextInfo:(void *)contextInfo {
	_saveOp = NSSaveToOperation;		// control display of accessory view
	[super runModalSavePanelForSaveOperation:op delegate:self didSaveSelector:@selector(document:didSave:contextInfo:) contextInfo:&_eparams];
}
- (NSString *)displayName {
	return [[super displayName] stringByDeletingPathExtension];
}
- (void)document:(NSDocument *)doc didSave:(BOOL)didSave contextInfo:(void *)contextInfo {
	if (didSave && contextInfo) {
		EXPORTPARAMS * ep = contextInfo;
		
		if (ep->type == E_ARCHIVE || ep->type == E_XMLRECORDS || ep->type == E_TAB || ep->type == E_DOS)	{	// records
			if (ep->errorcount)	
				infoSheet(self.windowForSheet, WRITERECINFOWITHERROR, ep->records, [self.lastSavedName UTF8String], ep->longest, ep->errorcount);
			else
				infoSheet(self.windowForSheet, WRITERECINFO, ep->records, [self.lastSavedName UTF8String], ep->longest);
		}
		else if (ep->type == E_RTF || ep->type == E_XPRESS || ep->type == E_INDESIGN || ep->type == E_XMLTAGGED || ep->type == E_TAGGED || ep->type == E_TEXTNOBREAK || ep->type == E_INDEXMANAGER)	// formatted
			infoSheet(self.windowForSheet, FILESTATSINFO, [self.lastSavedName UTF8String], _index.pf.entries, _index.pf.lines, _index.pf.prefs, _index.pf.crefs);
	}
}
- (BOOL)writeToURL:(NSURL *)absoluteURL ofType:(NSString *)typeName error:(NSError **)outError {
	if ([typeName isEqualToString:CINIndexType])	{	// saving native index
		if (![self _duplicateIndexToFile:[absoluteURL path]])	{
			if (outError)
				*outError = makeNSError(FILEOPENERR,"There was an error when saving a copy of the index.");
			return NO;
		}
		return YES;
	}
	return [super writeToURL:absoluteURL ofType:typeName error:outError];
}
- (NSData *)dataOfType:(NSString *)aType error:(NSError **)error {
	if ([aType isEqualToString:CINArchiveType] || [aType isEqualToString:CINXMLRecordType] 
		|| [aType isEqualToString:CINDelimitedRecords] || [aType isEqualToString:DOSDataType])	{	// if records
		
		if ([aType isEqualToString:CINXMLRecordType])	{	// if need syntax check on records
			GROUPHANDLE gh = grp_startgroup(&_index); 	/* initialize a group */
			
			if (grp_buildfromcheck(&_index,&gh))	{
				grp_installtemp(&_index,gh);
				[self setViewType:VIEW_TEMP name:nil];
				if (error)
					*error = makeNSError(RECORDSYNTAXERR);
				return nil;
			}
			grp_dispose(gh);
		}
		return export_writerecords(&_index,&_eparams);
	}
	if ([aType isEqualToString:CINStationeryType])	// if stationery
		return export_writestationery(&_index,&_eparams);	
	if ([aType isEqualToString:CINRTFType])	// if rtf
		return formexport_write(&_index,&_eparams, &rtfcontrol);	
	if ([aType isEqualToString:CINQuarkType])	// if quark
		return formexport_write(&_index,&_eparams, &xpresscontrol);	
	if ([aType isEqualToString:CINInDesignType])	// if InDesign
		return formexport_write(&_index,&_eparams, &indesigncontrol);	
	if ([aType isEqualToString:CINXMLType])	// if xml text
		return formexport_write(&_index,&_eparams, &xmlcontrol);	
	if ([aType isEqualToString:CINPlainTextType])	// if plain text
		return formexport_write(&_index,&_eparams, &textcontrol);	
	if ([aType isEqualToString:CINTaggedText])	// if tagged
		return formexport_write(&_index,&_eparams, &tagcontrol);
	if ([aType isEqualToString:CINIMType])	// if index manager
		return formexport_write(&_index,&_eparams, &imcontrol);
	return nil;
}
- (void)setAutosave:(double)seconds {
	[self.saveTimer invalidate];
	self.saveTimer = nil;
	if (seconds && !_index.readonly)
		self.saveTimer = [NSTimer scheduledTimerWithTimeInterval:seconds target:self selector:@selector(timerFired:) userInfo:nil repeats:NO];
}
- (void)timerFired:(NSTimer *)timer {
//	NSLog(@"Timer Fired");
	if (_index.mf.base)		// precaution: unknown circumstances (which shouldn't arise) might have timer fire after indexClose, so mfile config is gone
		[self _savePrivateBackup];
//	[self setAutosave:g_prefs.gen.saveinterval];	// reset save timer
}
- (void)_prefsChanged {
	[self setAutosave:g_prefs.gen.saveinterval];
}
- (BOOL)_installIndex {
	NSDictionary * attr = [[NSFileManager defaultManager] attributesOfItemAtPath:[[self fileURL] path] error:NULL];
	short tdirty = _index.head.dirty;
	short farray[FONTLIMIT];
	
	_index.wholerec = RECSIZE+_index.head.indexpars.recsize;
	self.modtime = [[attr fileModificationDate] copy];
	col_init(&_index.head.sortpars,&_index);		// initialize collator
	[self buildStyledStrings];	// set up styled strings
	[self configurePrintInfo];	// set print defaults
	if (index_setworkingsize(&_index, MAPMARGIN))		{	// set mapping size
		RECN nomrtot = (RECN)(_index.mf.size-_index.head.groupsize-HEADSIZE)/(_index.head.indexpars.recsize+RECSIZE);	// max possible capacity
		int error;
		
		if ([self resizeIndex:_index.head.indexpars.recsize])	{	// 6/24/18 ensure record size is multiple of 4
			error = index_checkintegrity(&_index, nomrtot);
			if (_index.readonly && (tdirty && !error || error > 0))	{	/* wanting readonly but dirty or damaged */
				sendinfo(INFO_INDEXNEEDSREPAIR);		/* send info */
				return FALSE;
			}
			if (error < 0)	{		// fatal damage to header; can't repair
				senderr(FATALDAMAGEERR, WARN);
				return FALSE;
			}
			if (error > 0) {	// record error(s)
				if (sendwarning(DAMAGEDINDEXWARNING))	{
					RECN mcount;

					if (_index.head.rtot > nomrtot)	// if claim too many records
						_index.head.rtot = nomrtot;	// force from size of file
					tdirty = FALSE;
					mcount = index_repair(&_index);		// do repairs
					_index.needsresort = TRUE;
					if (mcount)
						sendinfo(INFO_REPAIRMARKED,mcount);
				}
				else	// don't want to repair
					return FALSE;
			}
			if (_index.head.rtot <= nomrtot || sendwarning(MISSINGRECORDS, nomrtot, _index.head.rtot)
				&& (_index.head.rtot = nomrtot) && index_writehead(&_index))	{	// if # records matches, or repaired OK
					if (tdirty)		{	/* if badly closed */
						if (sendwarning(CORRUPTINDEX))	{	/* if want resort */
							_index.needsresort = TRUE;
//							[self flush];		// 7/25/18; redundant
						}
						else
							_index.readonly = TRUE;
					}
				if (!grp_checkintegrity(&_index))	{	// if corrupt groups
					if (sendwarning(DAMAGEDGROUPS))	// if want repair
						grp_repair(&_index);
					else
						return FALSE;
				}
				_index.startnum = _index.head.rtot;
				if (!_index.readonly) {
					[self _checkFixes];	// do minor version fixups
					if (_index.needsresort)	{
						sort_resort(&_index);
						[self flush];
					}
				}
				if (_index.head.privpars.vmode == VM_SUMMARY)	// if closed in summary
					_index.head.privpars.vmode = VM_DRAFT;
				[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(_prefsChanged) name:NOTE_PREFERENCESCHANGED object:nil];
				[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(updateDisplay) name:NOTE_STRUCTURECHANGED object:self];
				type_findlostfonts(&_index);
				if (!type_scanfonts(&_index,farray))		// if there are unused fonts
					type_adjustfonts(&_index,farray);	// remove them
				if (type_checkfonts(_index.head.fm) || [ManageFontController manageFonts:_index.head.fm])	{	/* if fonts ok or fixed */
					[self setAutosave:g_prefs.gen.saveinterval];
					if (IRdc.IRrevertsource)		{	// if reverting
						_index.head.mainviewrect = [IRdc.IRrevertsource iIndex]->head.mainviewrect;	// get main view rect from source;
						[self setFileURL:[IRdc.IRrevertsource fileURL]];	// make sure new index will display proper name (actual file renamed in cleanup)
					}
					else if (!_index.readonly)	// if not readonly && if not reverting reverting -- underlying file not yet safely renamed if reverting
						[self _savePrivateBackup];		// make private backup
					return YES;
				}
			}
		}
	}
	return NO;
}
- (BOOL)readFromURL:(NSURL *)url ofType:(NSString *)aType error:(NSError **)error {
	if ([aType isEqualToString:CINIndexType])	{	// if index
//		NSDictionary * attributes =  [[NSFileManager defaultManager] attributesOfItemAtPath:url.path error:nil];
//		short ppermissions = [[attributes objectForKey:@"NSFilePosixPermissions"] shortValue];
//		_index.readonly = [[attributes objectForKey:@"NSFileImmutable"] boolValue] || !([[attributes objectForKey:@"NSFilePosixPermissions"] shortValue]&0200);	// if locked or not writable by owner
		_index.readonly = ![[NSFileManager defaultManager] isWritableFileAtPath:url.path];
		int flags = _index.readonly ? O_RDONLY|O_EXLOCK|O_NONBLOCK : O_RDWR|O_EXLOCK|O_NONBLOCK;
		if (mfile_open(&_index.mf,[url.path UTF8String],flags,0))	{
			if (_index.mf.size >= HEADSIZE)	{	// if could be index
				memcpy(&_index.head,_index.mf.base,HEADSIZE);	// install header
				BOOL goodversion = _index.head.version >= BASEVERSION && _index.head.version <= TOPVERSION;
				if (_index.head.headsize == HEADSIZE && goodversion)	{	/* if compatible versions */
					if ([self _installIndex])	// set up and check everything
						return YES;
					else {
						mfile_close(&_index.mf);
						return NO;
					}
				}
				else if (!goodversion) {
					mfile_close(&_index.mf);
					senderr(FILEVERSERR, WARN, (float)_index.head.version/100);	/* bad version */
					return NO;
				}
			}
			mfile_close(&_index.mf);
			senderr(UNKNOWNFILERR, WARN, [[url.path lastPathComponent] UTF8String]);	// not an index
		}
		else
			senderr(FILEOPENERR,WARN,strerror(errno));
	}
	else if ([aType isEqualToString:CINStyleSheetType] )	{
		STYLESHEET * ssp = (STYLESHEET *)[[NSData dataWithContentsOfFile:url.path] bytes];
		
		return [IRdc loadStyleSheet:ssp];
	}
	return NO;
}
#if 0
#if 0	// April 5 2018
- (void)canCloseDocumentWithDelegate:(id)delegate shouldCloseSelector:(SEL)shouldCloseSelector contextInfo:(void *)contextInfo {
	if ([self closeIndex])	{	// if no error closing
		[super canCloseDocumentWithDelegate:delegate shouldCloseSelector:shouldCloseSelector contextInfo:contextInfo];
		[self close];	// Dec 3 2017
	}
}
#endif
// following method from April 5 2018
- (void)shouldCloseWindowController:(NSWindowController *)windowController delegate:(id)delegate shouldCloseSelector:(SEL)shouldCloseSelector contextInfo:(void *)contextInfo {
	if (windowController == _mainWindowController) {
		if ([self closeIndex])	// if no error closing
			[self close];
	}
	else
		[super shouldCloseWindowController:windowController delegate:delegate shouldCloseSelector:shouldCloseSelector contextInfo:contextInfo];
}
#else
- (void)canCloseDocumentWithDelegate:(id)delegate shouldCloseSelector:(SEL)shouldCloseSelector contextInfo:(void *)contextInfo {
//	NSTimer * xx = self.saveTimer;
//	NSLog(@"Pre:%d",xx.isValid);
	[self document:self shouldClose:[self closeIndex] contextInfo:contextInfo];
//	NSLog(@"Post:%d",xx.isValid);
}
- (void)document:(NSDocument *)document shouldClose:(BOOL)shouldClose contextInfo:(void  *)contextInfo {
	if (shouldClose)
		[self close];
}
#endif
- (BOOL)_savePrivateBackup {		// saves private backup of active index
	if (!_backupPath)	{		// if have no backup name
		NSString * name = @".";		// as prefix to file name makes it hidden
		
		name = [name stringByAppendingString:[[self fileURL] lastPathComponent]];
		_backupPath = [[[[self fileURL] path] stringByDeletingLastPathComponent] stringByAppendingPathComponent:name];
	}
	[self setAutosave:0];		// kill save timer (could be running if this save is other than autosave)
	_hasBackup = [self _duplicateIndexToFile:_backupPath];
	[self setAutosave:g_prefs.gen.saveinterval];	// reset save timer
	return _hasBackup;
}
#if 1
- (IBAction)revertToSaved:(id)sender {	// reverts to private backup
	if (sendwarning(REVERTWARNING))	{
		NSURL * burl = [NSURL fileURLWithPath:_backupPath];
		NSURL * furl = [self fileURL];
	
		IRdc.IRrevertsource = self;
		[IRdc openDocumentWithContentsOfURL:burl display:YES completionHandler:^(NSDocument *document, BOOL alreadyOpen, NSError *error){
		//	by now, the reverted doc has retrieved and displayed the right internal name
			if (document) {
				[[[self mainWindowController] window] performClose:self];		// close us
				[[NSFileManager defaultManager] removeItemAtURL:furl error:NULL];		// remove file underlying self
				[[NSFileManager defaultManager] moveItemAtURL:burl toURL:furl error:nil];	// rename what was the backup file
				[(IRIndexDocument *)document _savePrivateBackup];		// make new private backup
			}
			else {
				IRdc.IRrevertsource = nil;
				senderr(INTERNALERR, WARN, "Cannot revert to saved document");
			}
		}];
	}
}
#else
- (IBAction)revertToSaved:(id)sender {	// reverts to private backup
	if (sendwarning(REVERTWARNING))	{
		if (_backupPath)	{
			NSURL * burl = [NSURL fileURLWithPath:_backupPath];
			NSURL * furl = [self fileURL];
			IRIndexDocument * ndoc;
			NSError * error;
			
			IRrevertsource = self;
			if (ndoc = [IRdc openDocumentWithContentsOfURL:burl display:YES error:&error])	{	// open and display backup
				//	by now, the reverted doc has retrieved and displayed the right internal name
				[[[self mainWindowController] window] performClose:self];		// close us
				[[NSFileManager defaultManager] removeItemAtURL:furl error:NULL];		// remove file underlying self
				[[NSFileManager defaultManager] moveItemAtURL:burl toURL:furl error:nil];	// rename what was the backup file
				[ndoc _savePrivateBackup];		// make new private backup
				return;
			}
			IRrevertsource = nil;
		}
		senderr(INTERNALERR, WARN, "Cannot revert to saved document");
	}
}
#endif
- (BOOL)readForbidden:(NSInteger)itemID {
	static int fcommand[] = {
		MI_SAVE,MI_REVERT,MI_IMPORT,MI_SAVEGROUP,
		MI_UNDO,MI_REDO,MI_CUT,MI_DEMOTE,MI_DELETED,MI_LABEL0,MI_LABEL1,MI_LABEL2,MI_LABEL3,MI_LABEL4,MI_LABEL5,MI_LABEL6,MI_LABEL7,MI_NEWRECORD,MI_EDITRECORD,MI_DUPLICATE,MI_REPLACE,MI_SPELL,
		MI_REMOVEMARK,
		MI_RECSTRUCTURE,/* MI_REFSYNTAX, MI_FLIPWORDS, */
		MI_RECONCILE,MI_GENERATE,MI_ALTER,MI_SPLIT,MI_SORT,MI_COMPRESS,MI_EXPAND,MI_GROUPS,
	};
	if (_index.readonly) {
		for (int rindex = 0; rindex < sizeof(fcommand)/sizeof(int); rindex++) {
			if (fcommand[rindex] == itemID)
				return YES;
		}
	}
	return NO;
}
- (BOOL)validateMenuItem:(NSMenuItem *)mitem {
	NSInteger itemid = [mitem tag];
	
//	NSLog([mitem title]);
	if (self.currentSheet || [self readForbidden:itemid])
		return NO;
	if([[_textWindowController window] isMainWindow])
		return (itemid == MI_PRINT || itemid == MI_PAGESETUP);
	if (_recordWindowController &&		// if have record window
		itemid != MI_NEWRECORD && itemid != MI_FINDAGAIN && itemid != MI_CHECK && itemid != MI_COUNT && itemid != MI_STATISTICS)
		return NO;
	if (itemid == MI_EDITRECORD)
		return [self selectedRecords].location > 0 && [self selectedRecords].location == [self selectedRecords].length;
	if (itemid == MI_NEWGROUP || itemid == MI_DUPLICATE || itemid == MI_DELETED || itemid == MI_DEMOTE || itemid == MI_REMOVEMARK)
		return [self selectedRecords].location > 0;
	if (itemid == MI_FINDAGAIN)
		return [self.currentSearchController canFindAgainInDocument:self];
	if (itemid == MI_HIDEBYATTRIBUTE)
		return _index.head.privpars.vmode == VM_FULL;
	if (itemid == MI_NEWRECORDS)
		return _index.startnum < _index.head.rtot;
	if (itemid == MI_TEMPORARYGROUP)
		return _index.lastfile ? YES : NO;
	if (itemid == MI_SHOWNUMBERS)
		return _index.head.privpars.vmode != VM_FULL;
	if (itemid == MI_WRAPLINES)
		return _index.head.privpars.vmode == VM_NONE;
	if (itemid == MI_SHOWSORTED)
		return !(_index.curfile || _index.viewtype == VIEW_NEW);	// no unsorted if group or new

	if (itemid == MI_REVERT)
		return _hasBackup && (_index.head.dirty || _index.wasdirty);
	if (itemid == MI_SAVEGROUP)
		return _index.lastfile && _index.viewtype == VIEW_TEMP ? YES : NO;
	if (itemid == MI_GROUPS)
		return [_groupmenu numberOfItems] > 0;

	if (itemid == MI_GENERATE || itemid == MI_CHECK)
		return _index.head.sortpars.fieldorder[0] != PAGEINDEX;
	if (itemid == MI_RECONCILE)
		return !(_index.viewtype == VIEW_NEW || _index.curfile || _index.head.sortpars.fieldorder[0] == PAGEINDEX);
	if (itemid == MI_COMPRESS || itemid == MI_EXPAND)
		return !(_index.viewtype == VIEW_NEW || _index.curfile);
		
	if (itemid > MI_LABEL0 && itemid <= MI_LABEL7)	{		// set checks on labels
		RECORD * recptr;
		if (recptr = rec_getrec(&_index, [self selectedRecords].location))
			[mitem setState: recptr->label == itemid-MI_LABEL0];
	}
	return YES;
}
- (BOOL)validateToolbarItem: (NSToolbarItem *)toolbarItem {
	NSInteger tag = [toolbarItem tag];
	
//	NSLog([toolbarItem label]);
//	if ([[_mainWindowController window] toolbar] != [toolbarItem toolbar] || _recordWindowController)
	if (_recordWindowController)
		return NO;
	if (tag == TB_DELETED || tag == TB_LABELED)
		return [self selectedRecords].location && !_index.readonly;
	if (tag == TB_VIEWALL)
		return _index.viewtype != VIEW_ALL;
//	if (tag == TB_FULLFORMAT)
//		return _index.head.privpars.vmode != VM_FULL;
//	if (tag == TB_DRAFTFORMAT)
//		return _index.head.privpars.vmode != VM_DRAFT;
//	if (tag == TB_INDENTED)
//		return _index.head.formpars.ef.runlevel > 0 && _index.head.privpars.vmode != VM_DRAFT;
//	if (tag == TB_RUNIN)
//		return _index.head.formpars.ef.runlevel == 0 && _index.head.privpars.vmode != VM_DRAFT;
	else if (tag == TB_STYLETYPE) {
		((NSSegmentedControl *)toolbarItem.view).selectedSegment = _index.head.formpars.ef.runlevel > 0 ? 1 : 0;
		return _index.head.privpars.vmode == VM_FULL;
	}
	if (tag == TB_FORMATTYPE)  {
		((NSSegmentedControl *)toolbarItem.view).selectedSegment = _index.head.privpars.vmode != VM_FULL ? 1 : 0;
	}
	if (tag == TB_SORTTYPE) {
		[(NSSegmentedControl *)toolbarItem.view setEnabled:!_index.readonly forSegment:0];
		[(NSSegmentedControl *)toolbarItem.view setEnabled:!_index.readonly forSegment:1];
		if (_index.head.sortpars.ison) {
			SORTPARAMS *sg = _index.curfile ? &_index.curfile->sg : &_index.head.sortpars;
			((NSSegmentedControl *)toolbarItem.view).selectedSegment = sg->fieldorder[0] == PAGEINDEX ? 1 : 0;
		}
		else
			((NSSegmentedControl *)toolbarItem.view).selectedSegment = 2;
	}
    return YES;
}
- (NSWindow *)windowForSheet {
	if ([[[NSApp keyWindow] delegate] isKindOfClass:[IRIndexTextWController class]])
		return [NSApp keyWindow];
	return super.windowForSheet;
}
- (NSPrintOperation *)printOperationWithSettings:(NSDictionary<NSPrintInfoAttributeKey, id> *)printSettings error:(NSError * _Nullable *)outError {
	NSWindow * printw = self.windowForSheet;
	id wc = [printw delegate];
	NSPrintInfo * pinfo;
	NSPrintOperation *printop;
	
	if ([wc isKindOfClass:[IRIndexTextWController class]])
		pinfo = [[NSPrintInfo sharedPrintInfo] copy];
	else {	// main document window
		pinfo = [[self printInfo] copy];
		memset(&self.iIndex->pf,0,sizeof(PRINTFORMAT));
		self.iIndex->pf.lastrec = UINT_MAX;		// set default print all
		self.iIndex->pf.firstrec = rec_number(sort_top(self.iIndex));
	}
	[pinfo.dictionary addEntriesFromDictionary:printSettings];
	[pinfo setVerticallyCentered:NO];
	printop = [NSPrintOperation printOperationWithView:[wc printView] printInfo:pinfo];
	[printop setCanSpawnSeparateThread: NO];
	if ([wc isKindOfClass:[IRIndexDocWController class]]) {
		IRPrintAccessoryController * pa = [[IRPrintAccessoryController alloc] initForDocument:self];
		[printop.printPanel addAccessoryController:pa];
	}
	return printop;
}
- (void)setPrintInfo:(NSPrintInfo *)printInfo {
	[super setPrintInfo:printInfo];
	_index.head.formpars.pf.orientation = [printInfo orientation];
	// set pi info for Windows
	_index.head.formpars.pf.pi.porien = _index.head.formpars.pf.orientation == NSPortraitOrientation ? DMORIENT_PORTRAIT : DMORIENT_LANDSCAPE;
	_index.head.formpars.pf.pi.pwidthactual = [printInfo paperSize].width;
	_index.head.formpars.pf.pi.pheightactual = [printInfo paperSize].height;
	index_markdirty(&_index);
	[[NSNotificationCenter defaultCenter] postNotificationName:NOTE_REVISEDLAYOUT object:self];
}
- (IBAction)saveACopy:(id)sender {
	NSSavePanel *savepanel = [NSSavePanel savePanel];
	NSString * defaultDirectory = [[NSUserDefaults standardUserDefaults] stringForKey:CIBackupFolder];
	
	if (defaultDirectory)
		[savepanel setDirectoryURL:[NSURL fileURLWithPath:defaultDirectory isDirectory:YES]];
	[savepanel setCanSelectHiddenExtension:YES];
    [savepanel setAllowedFileTypes:[NSArray arrayWithObject:CINIndexExtension]];
	[savepanel setNameFieldStringValue:[[self displayName] stringByAppendingString:@" copy"]];
	[savepanel beginSheetModalForWindow:[NSApp mainWindow] completionHandler:^(NSInteger result) {
		if (result == NSFileHandlingPanelOKButton)	{
			[self saveToURL:[savepanel URL] ofType:CINIndexType forSaveOperation:NSSaveToOperation delegate:self didSaveSelector:@selector(document:didSave:contextInfo:) contextInfo:nil];
		}
		[[NSUserDefaults standardUserDefaults] setObject:[[savepanel directoryURL] path] forKey:CIBackupFolder];
	}];
}
- (IBAction)importRecords:(id)sender {
	NSArray * types = [NSArray arrayWithObjects:@"text",@"txt",NSFileTypeForHFSTypeCode(CIN_TEXT),@"xaf",@"ixml",@"arc",NSFileTypeForHFSTypeCode(CIN_MDAT),
					   @"mbk",@"dat",@"sky7",@"txtsky7", @"txtsky8",nil];
	NSOpenPanel * openpanel = [NSOpenPanel openPanel];
	NSString * defaultDirectory = [[NSUserDefaults standardUserDefaults] stringForKey:CIOpenFolder];
	
	if (defaultDirectory)
		[openpanel setDirectoryURL:[NSURL fileURLWithPath:defaultDirectory isDirectory:YES]];
    [openpanel setAllowsMultipleSelection:NO];
	[openpanel setTitle:@"Import Records"];
	[openpanel setPrompt:@"Import"];
    [openpanel setAllowedFileTypes:types];
	[openpanel beginSheetModalForWindow:[_mainWindowController window] completionHandler:^(NSInteger result) {
		if (result == NSFileHandlingPanelOKButton)	{
			NSURL * url = [[openpanel URLs] objectAtIndex:0];
			NSString * path = [url path];
			NSString * typestring;
			IRIndexArchive * doc;
			
			if ([[path pathExtension] isEqualToString:@"text"] || [[path pathExtension] isEqualToString:@"txt"]
				|| [[path pathExtension] isEqualToString:NSFileTypeForHFSTypeCode(CIN_TEXT)])	// to cope with InDesign return from 10.4 implementation
				typestring = CINDelimitedRecords;
			else
				typestring = [IRdc typeForContentsOfURL:url error:nil];
			doc = [[IRIndexArchive alloc] initWithContentsOfURL:url ofType:typestring forIndex:[self iIndex]];	// open, read contents
			if (doc)	// if successful import
				[self setViewType:VIEW_ALL name:nil];
		}
	 }];
}
- (IBAction)newGroup:(id)sender {
	GROUPHANDLE gh = grp_startgroup(&_index);
	NSRange rr = [self selectionMaxRange];
	
	grp_buildfromrange(&_index,&gh,rr.location,rr.length,GF_SELECT);
	grp_installtemp(&_index,gh);
	[self setViewType:VIEW_TEMP name:nil];
}
- (IBAction)saveGroup:(id)sender {
	[self showSheet:[[SaveGroupController alloc] initWithWindowNibName:@"SaveGroupController"]];
}
- (IBAction)goTo:(id)sender {
	[self showSheet:[[GoToController alloc] initWithWindowNibName:@"GoToController"]];
}
- (IBAction)findAgain:(id)sender {
	[(FindController *)[[IRdc findPanel] delegate] find:self];
	[[_mainWindowController window] makeKeyWindow];
}
- (IBAction)hideByAttribute:(id)sender {
	[self showSheet:[[FilterController alloc] initWithWindowNibName:@"FilterController"]];
}
//- (IBAction)verifyRefs:(id)sender {
//	[self showSheet:[[VerifyRefsController alloc] initWithWindowNibName:@"VerifyRefsController"]];
//}
- (IBAction)reconcile:(id)sender {
	[self showSheet:[[ReconcileController alloc] initWithWindowNibName:@"ReconcileController"]];
}
- (IBAction)splitHeadings:(id)sender {
	[self showSheet:[[SplitController alloc] initWithWindowNibName:@"SplitController"]];
}
- (IBAction)checkEntries:(id)sender {
	[self showSheet:[[CheckController alloc] initWithWindowNibName:@"CheckController"]];
}
- (IBAction)generateRefs:(id)sender {
	[self showSheet:[[GenerateRefsController alloc] initWithWindowNibName:@"GenerateRefsController"]];
}
- (IBAction)alterRefs:(id)sender {
	[self showSheet:[[AlterRefsController alloc] initWithWindowNibName:@"AlterRefsController"]];
}
- (IBAction)compress:(id)sender {
	[self showSheet:[[CompressController alloc] initWithWindowNibName:@"CompressController"]];
}
- (IBAction)expand:(id)sender {
	NSAlert * warning = criticalAlert(EXPANDWARNING);
	[warning beginSheetModalForWindow:[self windowForSheet] completionHandler:^(NSInteger result) {
		if (result == NSAlertFirstButtonReturn){
			sort_squeeze(&self->_index,SQSINGLE);
			[self setViewType:VIEW_ALL name:nil];
			[self setGroupMenu:[self groupMenu:NO]];	// rebuild menu after invalidating groups
			[[NSNotificationCenter defaultCenter] postNotificationName:NOTE_GLOBALLYCHANGING object:self];
		}
	}];
}
- (IBAction)count:(id)sender {
	[self showSheet:[[CountController alloc] initWithWindowNibName:@"CountController"]];
}
- (IBAction)statistics:(id)sender {
	[self showSheet:[[StatisticsController alloc] initWithWindowNibName:@"StatisticsController"]];
}
- (IBAction)groups:(id)sender {
	[self showSheet:[[GroupsController alloc] initWithWindowNibName:@"GroupsController"]];
}
- (IBAction)fonts:(id)sender {
	[self showSheet:[[ManageFontController alloc] initWithWindowNibName:@"ManageFontController"]];
}
- (void)showSheet:(NSWindowController *)sheet{
	self.currentSheet = sheet;
	sheet.document = self;
//	[self setAutosave:0];		// kill save timer while modal
	[[self windowForSheet] beginSheet:sheet.window completionHandler:^(NSInteger result) {
		if (result == OKTAG){
		}
//		[self setAutosave:g_prefs.gen.saveinterval];	// restart any autosave
		[self.currentSheet close];
		self.currentSheet = nil;	// release it
	}];
}
- (IBAction)changeView:(id)sender {
	NSInteger ttype = [sender tag];
	int type;
	
	if (ttype == MI_VIEWALL || ttype == TB_VIEWALL)		// all records
		type = VIEW_ALL;
	else if (ttype == MI_NEWRECORDS)	// new records
		type = VIEW_NEW;
	else if (ttype == MI_GROUP)		// named group
		type = VIEW_GROUP;
	else if (ttype == MI_TEMPORARYGROUP)	// temporary group
		type = VIEW_TEMP;
	else {
		NSLog(@"View Scope Error");
		return;
	}
	if (type != _index.viewtype || type == VIEW_GROUP)	// if want new type (or group)
		[self setViewType:type name:(ttype == TB_VIEWALL ? nil : [sender title])];
}
- (IBAction)changeViewFormat:(id)sender {
	NSInteger format = [sender tag];
	int mode;

	if ([sender isKindOfClass:[NSSegmentedControl class]])	// need this because before 10.13 no direct access to segment tag
		format += ((NSSegmentedControl*)sender).selectedSegment+1;
	if (format == MI_FULLFORMAT || format == TB_FULLFORMAT)		// full format
		mode = VM_FULL;
	else if (format == MI_DRAFTFORMAT || format == TB_DRAFTFORMAT)	// draft format
		mode = VM_DRAFT;
	else if (format == MI_SUMMARYFORMAT)	// summary
		mode = VM_SUMMARY;
	else if (format == MI_UNFORMATTED)	// unformatted
		mode = VM_NONE;
	else {
		NSLog(@"View Format Error");
		return;
	}
	if (mode != _index.head.privpars.vmode)	// if changed
		[self setViewFormat:mode];
}
- (IBAction)showNumbers:(id)sender {
	_index.head.privpars.shownum ^= 1;
	[self redisplay:0 mode:VD_CUR];
}
- (IBAction)viewDepth:(id)sender {
	_index.head.privpars.hidebelow = [sender tag];
	[self redisplay:0 mode:VD_CUR];
}
- (IBAction)wrapLines:(id)sender {
	_index.head.privpars.wrap ^= 1;
	[self redisplay:0 mode:VD_CUR];
}
- (IBAction)changeSort:(id)sender {
	_index.head.sortpars.ison ^= 1;
	[self redisplay:0 mode:VD_RESET];
}
- (IBAction)newRecord:(id)sender {
	[self openRecord:0];
}
- (IBAction)editRecord:(id)sender {
	[self openRecord:[self selectedRecords].location];
}
- (IBAction)duplicate:(id)sender {
	NSRange rrange = [self selectionMaxRange];
	COUNTPARAMS cs;
	RECN tot;
	
	memset(&cs,0,sizeof(cs));
	cs.smode = _index.head.sortpars.ison;		/* sort is as the view */
	cs.firstrec = rrange.location;
	cs.lastrec = rrange.length;
	tot = search_count(&_index, &cs,SF_OFF);

	if (_index.head.privpars.hidedelete)	/* if won't duplicate deleted */
		tot -= cs.deleted;				/* adjust required count */
	if (tot) 	{		/* if have any records */
		if (index_setworkingsize(&_index,tot+MAPMARGIN))	{	// if can extend file for new records
			RECORD * trptr;
			RECN rnum, fgnum;
			
			for (rnum = _index.head.rtot, trptr = rec_getrec(&_index,rrange.location); trptr && trptr->num != cs.lastrec; trptr = sort_skip(&_index,trptr,1))	{
				if (!rec_makenew(&_index,trptr->rtext,++rnum))	/* if error making new record */
					break;
			}
			fgnum = _index.head.rtot+1;		/* save first new record # in case make group */
			while (_index.head.rtot < rnum)	/* for new records */
				sort_makenode(&_index,++_index.head.rtot);		/* sort */
			[self flush];			/* force update on file */
			if (tot > 1)	{		/* if more than one record duplicated */
				GROUPHANDLE gh = grp_startgroup(&_index);
				grp_buildfromrange(&_index,&gh,fgnum,_index.head.rtot,GF_RANGE);	/* build group from range */
				grp_installtemp(&_index,gh);
				[self setViewType:VIEW_TEMP name:nil];
			}
			else if (trptr = rec_getrec(&_index,_index.head.rtot))	{	/* if can get record */
				short propstate = g_prefs.gen.propagate;	/* save prop state */
				g_prefs.gen.propagate = FALSE;	/* set off */
				[_mainWindowController setSelectedRecords:NSMakeRange(trptr->num,trptr->num)];	// specify selection in advance
				[self openRecord:trptr->num];
				g_prefs.gen.propagate = propstate;	/* restore */
			}
		}
	}
}
- (IBAction)demote:(id)sender {
	NSRange rrange = [self selectionMaxRange];
	RECORD * trptr;
	
	if (trptr = rec_getrec(&_index,rrange.location))	{	// check record lengths, depths for fit
		int maxlength = 0;
		int maxfields = 0;
		char placeholder[60];
		int pgap = sprintf(placeholder, "__%s__", time_stringFromTime(time(NULL), TRUE))+1; // get heading and gap
		do {
			int length = str_xlen(trptr->rtext);
			if (length > maxlength)
				maxlength = length;
			int fcount = str_xcount(trptr->rtext);
			if (fcount > maxfields)
				maxfields = fcount;
		} while ((trptr = sort_skip(&_index,trptr,1)) && trptr->num != rrange.length);
		if (maxfields > _index.head.indexpars.maxfields)	{	/* if need to increase field limit */
			if (sendwarning(DEMOTEFIELDNUMWARN, maxfields))	{
				int oldmaxfieldcount = _index.head.indexpars.maxfields;
				_index.head.indexpars.maxfields = maxfields;
				adjustsortfieldorder(_index.head.sortpars.fieldorder, oldmaxfieldcount, _index.head.indexpars.maxfields);
			}
			else
				return;
		}
		maxlength = maxlength + pgap + 10;
		maxlength -= maxlength % 10;		// rounded up to nearest 10 above original maxlength + gap
		if (maxlength > _index.head.indexpars.recsize)	{	/* if need record enlargement */
			if (!sendwarning(DEMOTEENLARGEWARN,maxlength-_index.head.indexpars.recsize) ||	![self resizeIndex:maxlength])	// if don't want or can't do
				return;
		}
		struct numstruct * slptr = sort_setuplist(&_index);
		trptr = rec_getrec(&_index,rrange.location);
		do {
			memmove(trptr->rtext+pgap,trptr->rtext,str_xlen(trptr->rtext)+1);	// create space for heading
			strcpy(trptr->rtext, placeholder);
			sort_addtolist(slptr, trptr->num);
			rec_stamp(&_index,trptr);
		} while ((trptr = sort_skip(&_index,trptr,1)) && trptr->num != rrange.length);
		sort_resortlist(&_index,slptr);
		[self updateDisplay];
		[self openRecord:rrange.location];
		[_recordWindowController setDemoting];
	}
}
- (IBAction)deleted:(id)sender {
	NSRange rrange = [self selectionMaxRange];
	RECORD * trptr;
	
	if (trptr = rec_getrec(&_index,rrange.location))	{/* get first record */
		BOOL delflag = !trptr->isdel;
		
		do {
			trptr->isdel = delflag;
			rec_stamp(&_index,trptr);
		} while ((trptr = sort_skip(&_index,trptr,1)) && trptr->num != rrange.length);
//		if (_index.head.privpars.hidedelete)	// if hiding deleted
//			[_mainWindowController selectRecord:0 range:NSMakeRange(0,0)];	// remove selection
		[self updateDisplay];
	}
}
- (IBAction)labeled:(id)sender {
	NSRange rrange = [self selectionMaxRange];
	RECORD * trptr;
	
	if (trptr = rec_getrec(&_index,rrange.location))	{	// get first record
		int newlabel = sender ? [sender tag]-MI_LABEL0 : 1;
		BOOL apply = trptr->label != newlabel && newlabel;
		
		do {	/* for all records in range */
			if (apply)	// if want to label
				trptr->label = newlabel;	// apply it
			else if (trptr->label && (trptr->label == newlabel || !newlabel))	// if has label to be removed
				trptr->label = 0;
			else			// don't touch this one
				continue;
			if (g_prefs.gen.labelsetsdate)
				rec_stamp(&_index,trptr);
		} while ((trptr = sort_skip(&_index,trptr,1)) && trptr->num != rrange.length);
		[self updateDisplay];
	}
}
- (IBAction)removeMark:(id)sender {
	NSRange rrange = [self selectionMaxRange];
	RECORD * trptr;
	
	if (trptr = rec_getrec(&_index,rrange.location))	{/* get first record */
		do {
			if (trptr->ismark) {
				trptr->ismark = NO;
				index_markdirty(&_index);
			}
		} while ((trptr = sort_skip(&_index,trptr,1)) && trptr->num != rrange.length);
		[self updateDisplay];
	}
}
- (void)openRecord:(RECN)record {
	if (!_index.readonly)	{
		if (!_recordWindowController)	{
			_recordWindowController = [[IRIndexRecordWController alloc] init];
			[self addWindowController: _recordWindowController];
			[_mainWindowController setDisplayForEditing:YES adding:record == 0];
			[[_mainWindowController window] addChildWindow:[_recordWindowController window] ordered:NSWindowAbove];
		}
		[_recordWindowController openRecord:record];
		[_recordWindowController showWindow:self];
	}
}
- (BOOL)canCloseActiveRecord {
	return !_recordWindowController || [_recordWindowController windowShouldClose:[_recordWindowController window]];
}
- (IBAction)toolbarAction:(id)sender {
	NSInteger tag = [sender tag];
	
	if ([sender isKindOfClass:[NSSegmentedControl class]])	// need this because before 10.13 no direct access to segment tag
		tag += ((NSSegmentedControl*)sender).selectedSegment+1;
	if (tag == TB_INDENTED || tag == TB_RUNIN) {
		_index.head.formpars.ef.runlevel = tag == TB_INDENTED ? 0 : 1;
		[self redisplay:0 mode:VD_CUR];
	}
	else if (tag == TB_NOSORT) {
		[self changeSort:sender];
	}
	else if (tag == TB_ALPHASORT || tag == TB_PAGESORT) {
		SORTPARAMS *sg = _index.curfile ? &_index.curfile->sg : &_index.head.sortpars;
		int count;

		for (count = 0; count < _index.head.indexpars.maxfields; count++)	{	/* for all fields */
			if (tag == TB_ALPHASORT)
				sg->fieldorder[count] = count == _index.head.indexpars.maxfields-1 ? PAGEINDEX : count;
			else
				sg->fieldorder[count] = !count ? PAGEINDEX : count-1;
		}
		if (_index.curfile)
			sort_sortgroup(&_index);
		else
			sort_resort(&_index);
		[self redisplay:0 mode:VD_RESET];
	}
}
- (void)setViewType:(int)type name:(NSString *)name{
	grp_closecurrent(&_index);
	if (type == VIEW_GROUP) {		// named group
		if (grp_install(&_index,(char *)[name UTF8String]))	// if can't install group
			type = VIEW_ALL;
	}
	else if (type == VIEW_TEMP)	// temporary group
		_index.curfile = _index.lastfile;
	_index.viewtype = type;
	[self redisplay:0 mode:VD_RESET];
}
- (int)viewType{
	return _index.viewtype;
}
- (void)setViewFormat:(int)format {
	int mode = VD_CUR;		// redisplay same records
	
	[self closeSummary];
	_index.head.privpars.vmode = format;
	sort_setfilter(&_index,SF_VIEWDEFAULT);
	if (format == VM_SUMMARY)
		self.sumsource = [self _buildSummary];
	[self redisplay:0 mode:mode];
}
- (int)viewFormat {
	return _index.head.privpars.vmode;
}
- (INDEX *)iIndex {
	return &_index;
}
- (void)configurePrintInfo {
	NSPrintInfo * pinfo = [self printInfo];
	
	[pinfo setTopMargin:_index.head.formpars.pf.mc.top];
	[pinfo setLeftMargin:_index.head.formpars.pf.mc.left];
	[pinfo setBottomMargin:_index.head.formpars.pf.mc.bottom];
	[pinfo setRightMargin:_index.head.formpars.pf.mc.right];
	[pinfo setOrientation:_index.head.formpars.pf.orientation];
}
- (void)buildStyledStrings {
	_index.stylecount = str_xparse(_index.head.stylestrings,_index.slist);
}
- (void)showText:(NSMutableAttributedString *)astring title:(NSString *)title {
	[astring addAttribute:NSForegroundColorAttributeName value:NSColor.textColor range:NSMakeRange(0, astring.length)];
    if (!_textWindowController)	{
        _textWindowController = [[IRIndexTextWController alloc] initWithAttributedString:astring];
        [self addWindowController: _textWindowController];
    }
	else
		[_textWindowController setAttributedString:astring];
	[_textWindowController setTitle:title];
    [_textWindowController showWindow:self];
}
- (void)closeText {
	[_textWindowController close];
}
- (void)updateDisplay {
	[_mainWindowController updateDisplay];
}
- (void)reformat {
	[self redisplay:0 mode:VD_CUR];
}
- (void)redisplay:(RECN)record mode:(int)flags {
	NSMutableDictionary * dic = [NSMutableDictionary dictionaryWithCapacity:2];
	NSNumber * mode = [NSNumber numberWithUnsignedInt:flags];
	NSNumber * recnum = [NSNumber numberWithUnsignedInt:record];
	
	[dic setObject:recnum forKey:RecordNumberKey];
	[dic setObject:mode forKey:ViewModeKey];
	[[NSNotificationCenter defaultCenter] postNotificationName:NOTE_REDISPLAYDOC object:self userInfo:dic];
}
- (BOOL)formPageImages {
	return [[_mainWindowController printView] buildPageStatistics];
}
- (RECORD *)skip:(int)size from:(RECORD *)record {
	if (record)	{
		if (_index.head.privpars.vmode == VM_FULL)
			return form_skip(&_index,record,size);
		else
			return draft_skip(&_index,record,size);
	}
	return NULL;
}
- (RECN)normalizeRecord:(RECN)record {
	if (_index.head.privpars.vmode == VM_FULL)
		record = rec_number(form_getrec(&_index,record));
	return record;
}
- (NSRange)selectedRecords {
	return [_mainWindowController selectedRecords];
}
- (NSRange)selectionMaxRange {
	NSRange mrange = [_mainWindowController selectedRecords];
	RECORD * recptr = rec_getrec(&_index,mrange.length);
	
	if (recptr = [self skip:1 from:recptr])
		mrange.length = recptr->num;
	else
		mrange.length = UINT_MAX;
	return mrange;
}
- (void)selectRecord:(RECN)record range:(NSRange)range{
	[_mainWindowController selectRecord:[self normalizeRecord:record] range:range];
}
- (void)installGroupMenu {	
	if (!_groupmenu)				// if don't have group menu
		[self setGroupMenu:[self groupMenu:NO]];		// build and retain
	if (_groupmenu) {	// if we have menu
		NSMenuItem * mitem = findmenuitem(MI_GROUPMENU);	// groups
		[mitem setEnabled:YES];
		if ([mitem submenu] != _groupmenu)  // if ours isn't installed menu
			[mitem setSubmenu:_groupmenu];
	}
}
- (void)setGroupMenu:menu {
	_groupmenu = menu;
}
- (NSMenu *)groupMenu:(BOOL)enabled {
	return grp_buildmenu(&_index,enabled);
}
- (void)installFieldMenu {	
	if (!_fieldmenu)				// if don't have group menu
		[self setFieldMenu:[self fieldMenu]];		// build and retain
	if (_fieldmenu) {	// if we have menu
		NSMenuItem * mitem = findmenuitem(MI_VIEWDEPTHMENU);	// view depth
		if ([mitem submenu] != _fieldmenu)  // if ours isn't installed menu
			[mitem setSubmenu:_fieldmenu];
	}
}
- (void)setFieldMenu:menu {
	_fieldmenu = menu;
}
- (NSMenu *)fieldMenu {
	NSMenu * fmenu = [[NSMenu alloc] init];
	int count;
	
	for (count = 0; count < _index.head.indexpars.maxfields; count++)	{
		NSMenuItem * mitem;
		int fieldindex;
		
		fieldindex = count < _index.head.indexpars.maxfields-1 ? count : PAGEINDEX;
		mitem = (NSMenuItem *)[fmenu addItemWithTitle:[NSString stringWithUTF8String:_index.head.indexpars.field[fieldindex].name] action:@selector(viewDepth:) keyEquivalent:@""];
		[mitem setTag: fieldindex < PAGEINDEX ? count+1 : ALLFIELDS];
	}
	return fmenu;
}
- (void)checkEditItems:(NSMenu *)tmenu {
	NSRange trange = [self selectedRecords];
	RECORD * recptr;
	BOOL delstate, labelstate;
	
	if (recptr = rec_getrec(&_index, trange.location)) {
		delstate = recptr->isdel ? TRUE: FALSE;
		labelstate = recptr->label ? TRUE : FALSE;
	}
	else
		delstate = labelstate = FALSE;
	[[tmenu itemWithTag:MI_DELETED] setState:delstate];
	[[tmenu itemWithTag:MI_LABELED] setState:labelstate];
	[[tmenu itemWithTag:MI_LABELED] setEnabled:[self selectedRecords].location > 0 || [[_recordWindowController window] isMainWindow]];
}
- (void)checkViewItems:(NSMenu *)tmenu {
	[[tmenu itemWithTag:MI_VIEWALL] setState:_index.viewtype == VIEW_ALL];
	[[tmenu itemWithTag:MI_NEWRECORDS] setState:_index.viewtype == VIEW_NEW];
	[[tmenu itemWithTag:MI_GROUPMENU] setEnabled:[_groupmenu numberOfItems] > 0 && _recordWindowController == nil];
	[[tmenu itemWithTag:MI_TEMPORARYGROUP] setState:_index.viewtype == VIEW_TEMP];
	
	[[tmenu itemWithTag:MI_FULLFORMAT] setState:_index.head.privpars.vmode == VM_FULL];
	[[tmenu itemWithTag:MI_DRAFTFORMAT] setState:_index.head.privpars.vmode == VM_DRAFT];
	[[tmenu itemWithTag:MI_SUMMARYFORMAT] setState:_index.head.privpars.vmode == VM_SUMMARY];
	[[tmenu itemWithTag:MI_UNFORMATTED] setState:_index.head.privpars.vmode == VM_NONE];
		
	[[tmenu itemWithTag:MI_SHOWNUMBERS] setState:_index.head.privpars.shownum && _index.head.privpars.vmode != VM_FULL];
	[[tmenu itemWithTag:MI_VIEWDEPTHMENU] setEnabled:_index.head.privpars.vmode < VM_FULL && ![[_textWindowController window] isMainWindow] && !_recordWindowController];	// excludes full and summary && text
	for (NSMenuItem * mi in [[[tmenu itemWithTag:MI_VIEWDEPTHMENU] submenu] itemArray])
		[mi setState: [mi tag] == _index.head.privpars.hidebelow];
	[[tmenu itemWithTag:MI_WRAPLINES] setState:_index.head.privpars.wrap && _index.head.privpars.vmode == VM_NONE];
	[[tmenu itemWithTag:MI_SHOWSORTED] setState:_index.head.sortpars.ison && _index.viewtype != VIEW_NEW || _index.curfile];
}
- (void)checkFormatItems:(NSMenu *)menu {
	[[menu itemWithTag:MI_ALIGNMENT] setEnabled:[[_mainWindowController window] isMainWindow]];
	[_recordWindowController checkFormatItems:menu];
}
- (BOOL)flush {
//	NSLog(@"flushing");
	BOOL flushok = index_flush(&_index);
	
	if (flushok)	{
		[self updateChangeCount:NSChangeCleared];	// clear change count
		[self setFileModificationDate:[NSDate date]];
	}
	return flushok;
}
- (BOOL)resizeIndex:(int)newrecsize{
	RECN count;
	RECORD * recptr;
	
	newrecsize = (newrecsize+3)&~3; // round up to nearest multiple of 4
	if (newrecsize == _index.head.indexpars.recsize)	/* if no change needed */
		return (TRUE);		/* do nothing */
	if (newrecsize < _index.head.indexpars.recsize || index_setsize(&_index,_index.head.rtot,newrecsize,MAPMARGIN))	{	/* if enough space */
		size_t newwholerec = newrecsize+RECSIZE;
		if (_index.curfile)		/* if viewing a group */
			[self setViewType:VIEW_ALL name:nil];		/* set to show all records */
		if (newrecsize < _index.head.indexpars.recsize)	{	/* if reducing size */
			for (count = 1; count <= _index.head.rtot; count++)	{
#if 0
				if (recptr = rec_getrec(&_index,count))
#else
				if (recptr = getaddress(&_index,count))	// 7/24/18 bypass rec_getrec() in case old record pointer misaligned
#endif
					memmove(_index.mf.base+HEADSIZE+(count-1)*newwholerec,recptr,newwholerec);
			}
		}
		else {		/* enlarging size */
			for (count = _index.head.rtot; count > 0; count--)	{
#if 0
				if (recptr = rec_getrec(&_index,count))
#else
				if (recptr = getaddress(&_index,count))	// 7/24/18 bypass rec_getrec() in case old record pointer misaligned
#endif
					memmove(_index.mf.base+HEADSIZE+(count-1)*newwholerec,recptr,_index.wholerec);
			}
		}
		_index.head.indexpars.recsize = newrecsize;
		_index.wholerec = newwholerec;
		return (TRUE);
	}
	else
		senderr(DISKFULLERR,WARN);
	return (FALSE);
}
- (BOOL)closeIndex {
	[[_recordWindowController window] performClose:nil];	// handle any active record
	if (!_recordWindowController) {	// if OK on record window
		[self setAutosave:0];		// kill save timer
		[[NSNotificationCenter defaultCenter] postNotificationName:NOTE_INDEXWILLCLOSE object:self];	// flush sort stacks
		if ([self flush])	{	/* flush records, write header */
			[[NSNotificationCenter defaultCenter] removeObserver:_mainWindowController];	// prevents any window resizing nonsense causing trouble after index closes
			index_setworkingsize(&_index,0);
			if (!_index.head.dirty && !_index.wasdirty)	{	/* if not dirty and never has been */
				NSString * path = [[self fileURL] path];
				NSDictionary * attr = [[NSFileManager defaultManager] attributesOfItemAtPath:path error:nil];
				NSMutableDictionary * sattr = [NSMutableDictionary dictionaryWithDictionary:attr];
				
				[sattr setObject:self.modtime forKey:NSFileModificationDate];	// set original open date
				[[NSFileManager defaultManager] setAttributes:sattr ofItemAtPath:path error:nil];
			}
			return mfile_close(&_index.mf);
		}
		NSLog(@"Close error %d",errno);
	}
	return NO;
}
- (EXPORTPARAMS *)exportParameters {
	return &_eparams;
}
- (IRIndexDocWController *)mainWindowController {
	return _mainWindowController;
}
- (IRIndexRecordWController *)recordWindowController {
	return _recordWindowController;
}
- (IRIndexTextWController *)textWindowController {
	return _textWindowController;
}
- (void)hideWindows {		// hides all doc windows
	[[_mainWindowController window] orderOut:self];
	[[_textWindowController window] orderOut:self];
	[[_recordWindowController window] orderOut:self];
}
- (IRIndexDocument *)_buildSummary {
	NSString * td = NSTemporaryDirectory();
	NSString * path = [td stringByAppendingPathComponent:[[self fileURL] lastPathComponent]];
	IRIndexDocument * doc = [[IRIndexDocument alloc] initWithName:path template:nil hideExtension:NO error:NULL];

	if (doc) {
		INDEX * XF = [doc iIndex];
		VERIFYGROUP vg;
		GROUPHANDLE curgroup;
		short curview;
		int count, crosscount;
		RECORD * recptr, *newptr;
		char * sptr;
	
		XF->head.sortpars.type = RAWSORT;
		memset(&vg,0,sizeof(vg));		/* clear verify info */
		vg.lowlim = 1;
		if (vg.t1 = calloc(1,_index.head.indexpars.recsize))		{
			curview = _index.viewtype;		/* save these cause always build summary for whole index */
			curgroup = _index.curfile;
			_index.viewtype =  VIEW_ALL;	/* set temp values */
			_index.curfile = NULL;
			for (recptr = sort_top(&_index); recptr ; recptr = sort_skip(&_index,recptr,1)) {	   /* for all records */
//				showprogress("Building Summary View…",FF->head.rtot,rcount++);
				if (crosscount = search_verify(&_index,recptr->rtext,&vg))	{	/* if have cross-ref */
					for (count = 0; count < crosscount; count++)	{
						if (vg.cr[count].num)	{	/* if the target existed */
							if (!(newptr = rec_writenew(XF, g_nullrec)))	/* if can't get new record */
								break;
							sptr = newptr->rtext;
							sptr += sprintf(sptr,"%u$",vg.cr[count].num)+1;	/* target number */
							sptr += sprintf(sptr,"%u",recptr->num)+1;			/* source number */
							sptr += sprintf(sptr,"%d%c",vg.eoffset, vg.cr[count].matchlevel+'A')+1;	/* length of source body + level in target of match */
							*sptr = EOCS;
							newptr->ismark = vg.cr[count].error || vg.eflags ? TRUE :FALSE;		/* mark if bad ref */
							sort_makenode(XF,newptr->num);		/* make nodes */
						}
					}
				}
			}
			_index.viewtype = curview;	/* restore old view settings */
			_index.curfile = curgroup;
			[XF->owner flush];		/* unconditional write */
//			showprogress(g_nullstr,0,0);
			XF->ishidden = TRUE;
			free(vg.t1);
			return (doc);
		}
	}
	return NULL;
}
- (void)closeSummary {
	if (self.sumsource) {
		NSString * path = [[self.sumsource fileURL] path];	// hold because we're disposing of the index
		[self.sumsource closeIndex];
		[[NSFileManager defaultManager] removeItemAtPath:path error:NULL];
		self.sumsource = nil;
	}
}
- (void)_checkFixes {	// does minor version fixups
	if (_index.head.version < CINVERSION) {		// if not current
		if (_index.head.version == 300 && _index.head.formpars.ef.lf.sortrefs)	// if sorted refs enabled
			_index.head.formpars.ef.lf.noduplicates = TRUE;			// suppress duplicates
		_index.head.version = CINVERSION;		// mark it as current version
		_index.needsresort = TRUE;		// force resort
	}
	if (_index.head.sortpars.sversion != SORTVERSION)	{
		LANGDESCRIPTOR * locale = col_fixLocaleInfo(&_index.head.sortpars);	// always check/fix collation params
			
		if (!locale) {	// must be opening index from higher version with more locales
			strcpy(_index.head.sortpars.language, "en");	// default to english
			strcpy(_index.head.sortpars.localeID, "en");
			_index.head.sortpars.nativescriptfirst = TRUE;
		}
		grp_checkparams(&_index);	// check/fix params for any groups
		_index.head.sortpars.sversion = SORTVERSION;
		_index.needsresort = TRUE;		// force resort
	}
	if (!*_index.head.sortpars.substitutes)	// if empty substitutes (from version 3)
		*_index.head.sortpars.substitutes = EOCS;	// set as empty xstring
	_index.head.formpars.fsize = sizeof(FORMATPARAMS);	// these two lines to cover error in v3 before 3.0.2
	_index.head.formpars.version = FORMVERSION;
}
@end

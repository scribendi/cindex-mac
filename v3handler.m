//
//  v2handler.m
//  Cindex
//
//  Created by Peter Lennie on 1/17/11.
//  Copyright 2011 Peter Lennie. All rights reserved.
//

#import "v1handler.h"
#import "v2headers.h"
#import "v3handler.h"
#import "strings_c.h"
#import "type.h"
#import "records.h"
#import "mfile.h"
#import "swap.h"
#import "commandutils.h"
#import "group.h"
#import "index.h"
#import "collate.h"

#define RES_GROUP 'Cgrp'

#define MAXUTF8STRING 9
typedef struct {
	char * message;
	BOOL error;
	char converted[MAXUTF8STRING];
	char output;
} V3CCONVERT;

V3CCONVERT v3cv[] = {
	{"Reference Syntax: Cross-reference Separator"},
	{"Reference Syntax: Page Reference Separator"},
	{"Reference Syntax: Page Reference Connector"},
};
#define V3NUMWARNINGS (sizeof(v3cv)/sizeof(V3CCONVERT))

static iconv_t converter;

static void extractgroups(INDEX * FF, NSString * path, char endian);		// extracts groups; removes resources
static int Uconvertheader (HEAD * hp);		// converts header
static void Uconvertfontmap(FONTMAP * fm);	// removes symbol font from map
static unichar Uconvertspecialcharacter(char * font, unsigned char schar);	// return unichar value of font character
static void Uconvertformatparams(FORMATPARAMS * fp);		// converts format params
static void Uconvertheader_footer(HEADERFOOTER * hfp);
static BOOL Uconvertchar(V3CCONVERT * v3cvp,char *source, char defchar);	// does in place conversion of single char
static BOOL Uconvertstring(char *source, int capacity);	// does in place conversion
static BOOL Uconvertxstring(char *source, int capacity);	// does in place conversion
static BOOL isoldfontcodeptr(char *cc);	// tests if code represents font
static BOOL isoldstylecodeptr(char *cc);	// tests if code represents old style

static void convertV2header(HEAD * hp, V2HEAD * v2hp);	// converts v2 header
static void convertV2indexpars(INDEXPARAMS *ip, V2INDEXPARAMS * v2ip);	// converts v2 index params
static void convertV2privpars(PRIVATEPARAMS *pp, V2PRIVATEPARAMS * v2pp);	// converts v2 private params
static void convertV2sortpars(SORTPARAMS *sp, V2SORTPARAMS * v2sp);	// converts v2 sort params
static void convertV2refpars(REFPARAMS *rp, V2REFPARAMS * v2rp);	// converts v2 ref params
static void convertV2formpars(FORMATPARAMS *fp, V2FORMATPARAMS * v2fp);	// converts v2 format params
static void convertV2headerfooter(HEADERFOOTER *hfp, V2HEADERFOOTER * v2hfp);	// converts v2 head/foot params
static void convertV2cstyle(CSTYLE *cp, V2CSTYLE * v2cp);	// converts v2 cstyle params
static void convertV2fontmap(FONTMAP *fmp, V2FONTMAP * v2fmp);	// converts v2 fontmap
static void convertV2listgroup(LISTGROUP *lgp, V2LISTGROUP * v2lgp);	// converts v2 listgroup
static void convertV2list(LIST *lgp, V2LIST * v2lgp);	// converts v2 list
static void convertV2group(GROUP *gp, V2GROUP * v2gp);	// converts v2 group

/****************************************************************************/
char * v3_warnings(char * warnstring)	// forms warning message

{
	char * sptr = warnstring;
	unsigned int index;
	
	for (*sptr = '\0', index = 0; index < V3NUMWARNINGS; index++)	{
		if (v3cv[index].error)
			sptr += sprintf(sptr,"\n%s %s was replaced by %c", v3cv[index].message, v3cv[index].converted,v3cv[index].output);
	}
	return *warnstring ? warnstring : NULL;
}
/****************************************************************************/
BOOL v3_convertstylesheet(NSString * path, NSString * oType)	// converts style sheet

{
	BOOL ok = FALSE;
	BOOL validsource = FALSE;
	MFILE mf;

	if (mfile_open(&mf,(char *)[path UTF8String],O_RDWR|O_EXLOCK|O_NONBLOCK,0))	{
		V2STYLESHEET v2ss;
		
		if ([oType isEqualToString:CINV1StyleSheetType] && mf.size == sizeof(V1STYLESHEET))	{	// if V1 stylesheet
			v1_convertstylesheet(&v2ss,(V1STYLESHEET *)mf.base);		// convert from V1 to V2
			validsource = TRUE;
		}
		else if (mf.size == sizeof(V2STYLESHEET))	{		// if v2 stylesheet
			memcpy(&v2ss,mf.base,sizeof(V2STYLESHEET));	// copy V2 stylesheet from map
			validsource = TRUE;
		}
		if (validsource && mfile_resize(&mf,sizeof(STYLESHEET)))	{	// resize to accommodate new sheet size
			STYLESHEET * ssp = (STYLESHEET *)mf.base;
			
			ssp->endian = v2ss.endian;
			convertV2fontmap(&ssp->fm,&v2ss.fm);
			convertV2formpars(&ssp->fg,&v2ss.fg);
			ssp->fontsize = v2ss.fontsize;
			swap_StyleSheet(ssp);	// swap as necessary
			v3_openconverter(NULL);
			Uconvertformatparams(&ssp->fg);
			ok = TRUE;
		}
		mfile_close(&mf);
	}
	return ok;
}
/****************************************************************************/
BOOL v3_convertindex(NSString * path, NSString * oType)

{
	IRIndexDocument * newndx = [[IRIndexDocument alloc] init];		// set up new index
	INDEX * FF = [newndx iIndex];
	BOOL ok = FALSE;
	
	if (mfile_open(&FF->mf,(char *)[path UTF8String],O_RDWR|O_EXLOCK|O_NONBLOCK,0))	{
		uint32_t hsize;
		off_t bodysize;
		V2HEAD v2h;
		
		@try	{
			v3_openconverter(NULL);
			if ([oType isEqualToString:CINV1IndexType] || [oType isEqualToString:CINV1StationeryType])		{	// deal with v1 header
				hsize = V1HEADSIZE;
				if (v1_convertheader(&v2h,(V1HEAD *)FF->mf.base))	// convert v1 to v2 structure
					ok = TRUE;
			}
			else {		// deal with v2 header as necessary
				uint32_t v2hsize;
				
				hsize = V2HEADSIZE;			// correct header size
				memcpy(&v2h,FF->mf.base,hsize);	// copy header from map
				v2hsize = v2h.headsize;
				if (!v2h.endian)			// if written on ppc
					v2hsize = CFSwapInt32(v2hsize);
				if (v2hsize == hsize)		// if convertable
					ok = TRUE;
			}
			if (ok)	{
				convertV2header(&FF->head,&v2h);	// convert v2 to v3 structure
				swap_Header(&FF->head);		// swap header if necessary
				FF->head.headsize = HEADSIZE;	// set size of V3 header
				// other v2 to v3 special settings ??
				
				bodysize = FF->mf.size-hsize;	// size of everything above header
				if (mfile_resize(&FF->mf,HEADSIZE+bodysize))	{	// resize to accommodate new header
					int maxlength = 0;
					unsigned int index;
									
					memmove(FF->mf.base+HEADSIZE, FF->mf.base+hsize,bodysize);	// shift everything above header to beyond new header
					FF->wholerec = RECSIZE+FF->head.indexpars.recsize;
					swap_Records(FF);	// swap records if necessary
					FF->head.endian = TARGET_RT_LITTLE_ENDIAN;	// set byte order after all swapping
					
					if ([oType isEqualToString:CINV1StationeryType] || [oType isEqualToString:CINV2StationeryType])	// if converting stationery
						FF->head.rtot = 0;		// no records
					if (FF->head.version < 200)	{	// if created by 1.6 or lower [do this here because need swapped header]					
						for (index = 1; index <= FF->head.rtot; index++) {
							RECORD * recptr = rec_getrec(FF,index);
							recptr->time = mw_to_unix_time(recptr->time);
						}
						FF->head.createtime = mw_to_unix_time(FF->head.createtime);
						FF->head.squeezetime = mw_to_unix_time(FF->head.squeezetime);
						if (FF->head.formpars.ef.collapselevel > FF->head.indexpars.maxfields-2)
							FF->head.formpars.ef.collapselevel = FF->head.indexpars.maxfields-2;
						if (FF->head.formpars.ef.runlevel > FF->head.indexpars.maxfields-2)
							FF->head.formpars.ef.runlevel = FF->head.indexpars.maxfields-2;
					}
					// make sure we have Windows-compatible paper params
					FF->head.formpars.pf.pi.porien = DMORIENT_PORTRAIT;
					FF->head.formpars.pf.pi.pwidthactual = 612;
					FF->head.formpars.pf.pi.pheightactual = 792;
					// now all unicode stuff
					for (index = 1; index < FONTLIMIT; index++) {
						if (type_ispecialfont(FF->head.fm[index].pname))
							FF->head.fm[index].flags = CHARSETSYMBOLS;
						else
							FF->head.fm[index].flags = 0;
					}
					// scan for length needed for UTF-8 conversion
					for (index = 1; index <= FF->head.rtot; index++) {
						RECORD * recptr = rec_getrec(FF,index);
						int reclength = v3_convertrecord(recptr->rtext, FF->head.fm, FALSE);
						
						if (reclength > maxlength)
							maxlength = reclength;
					}
					// resize index as necessary
					if (maxlength >= FF->head.indexpars.recsize)
						[FF->owner resizeIndex:maxlength];
					// do UTF-8 conversion
					for (index = 1; index <= FF->head.rtot; index++) {
						RECORD * recptr = rec_getrec(FF,index);
						
						v3_convertrecord(recptr->rtext, FF->head.fm, TRUE);
					}
					ok = Uconvertheader(&FF->head);	// do this after record conversion (need original font map for conversion)
					strcpy(FF->head.flipwords,FF->head.sortpars.ignore);	// copy old ignore list as flip list
					FF->head.sortpars.ignoreparenphrase = FF->head.sortpars.type > RAWSORT ? TRUE : FALSE;
					strcpy(FF->head.sortpars.language,"en");		// set default language
					FF->head.version = BASEVERSION;			// always below current version; triggers resort
					if ([oType isEqualToString:CINV2IndexType])	// if potentially usable groups
						extractgroups(FF,path, v2h.endian);		// extract any
					memcpy(FF->mf.base,&FF->head,HEADSIZE);	// copy header to map
				}
			}
		}
		@catch (NSException * exception)	{
			ok = FALSE;
		}
		@finally {
			mfile_close(&FF->mf);	// close file
		}
	}
	return ok;
}
/****************************************************************************/
static void extractgroups(INDEX * FF, NSString * path, char endian)		// extracts groups; removes resources

{
#if !defined __LP64__		// FSpOpenResFile not available on 64 bit
	
	FSRef fsref;
	FSSpec fspec;
	OSErr err;
	
	if (!(err = FSPathMakeRef((unsigned char *)[path UTF8String],&fsref,NULL)))		{// make ref for resource management
		if (!(err = FSGetCatalogInfo(&fsref,kFSCatInfoNone,NULL,NULL,&fspec,NULL)))	{
			SInt16 fid;
			
			if ((fid = FSpOpenResFile(&fspec,fsRdWrPerm)) < 0)
				err = ResError();
			if (fid >= 0)	{
				int gtot = Count1Resources(RES_GROUP);
				int count;
				
				index_setworkingsize(FF, 0);
				for (count = gtot; count >= 1; count--)	{
					Handle rh = Get1IndResource(RES_GROUP,count);
					V2GROUPHANDLE gh = (V2GROUPHANDLE)*rh;
					GROUPHANDLE ngh = grp_startgroup(FF);	// establish new group
					
					if (endian != TARGET_RT_LITTLE_ENDIAN)	{	// if mismatched type
						gh->rectot = CFSwapInt32(gh->rectot);	// swap size param so we can use it
						swap_Group(ngh);		// swap basic group settings to match V2 group
					}
					convertV2group(ngh,gh);		// load data from old group
					if (endian != TARGET_RT_LITTLE_ENDIAN)	{	// if mismatched type
						ngh->rectot = CFSwapInt32(ngh->rectot);	// swap back size param to V2 format
						swap_Group(ngh);	// convert group finally
					}
					grp_make(FF,ngh,ngh->gname,TRUE);		// add it to file
					grp_dispose(ngh);
					RemoveResource(rh);
					DisposeHandle(rh);
				}
				CloseResFile(fid);
			}
		}
	}
#endif
}
/****************************************************************************/
static int Uconvertheader(HEAD * hp)		// converts header

{
	BOOL ok;
	// indexparams
	for (int pindex = 0; pindex < FIELDLIM; pindex++)	{
		Uconvertstring(hp->indexpars.field[pindex].name,FNAMELEN);
		Uconvertstring(hp->indexpars.field[pindex].matchtext,PATTERNLEN);
	}
	// sortparams
	Uconvertstring(hp->sortpars.ignore,STSTRING);
	// refparams
	Uconvertstring(hp->refpars.crosstart,STSTRING);
	Uconvertstring(hp->refpars.crossexclude,FTSTRING);
	Uconvertstring(hp->refpars.maxvalue,FTSTRING);		// this one shouldn't be necessary
	ok = Uconvertchar(&v3cv[0],&hp->refpars.csep,g_prefs.refpars.csep) && Uconvertchar(&v3cv[1],&hp->refpars.psep,g_prefs.refpars.psep) && Uconvertchar(&v3cv[2],&hp->refpars.rsep,g_prefs.refpars.rsep);		// catch character errors
	// formatparams - pageformat
	Uconvertformatparams(&hp->formpars);
	// styled strings
	for (char *ptr = hp->stylestrings; *ptr != EOCS; ptr += strlen(ptr)+1)
		*ptr = (*ptr&FX_STYLEMASK)|FX_OFF;	// convert old FX_OFF to FX_OFF bit
	Uconvertxstring(hp->stylestrings,STYLESTRINGLEN);
	// convert font map
	Uconvertfontmap(hp->fm);
	return ok;
}
/******************************************************************************/
static void Uconvertfontmap(FONTMAP * fm)	// removes symbol font from map

{
	int index;
	for (index = 1; *fm[index].pname; index++)	// for all fonts above default
		fm[index] = fm[index+1];		// step down one position (over symbol position)
	memset(&fm[index],0,sizeof(FONTMAP));	// clear last entry
	for (int pindex = 0; *fm[pindex].pname; pindex++)	{
		Uconvertstring(fm[pindex].name,FONTNAMELEN);
		Uconvertstring(fm[pindex].pname,FONTNAMELEN);
	}
}
/***************************************************************************/
int v3_convertrecord(char * xstring, FONTMAP * fm, BOOL replace)	// converts xstring to UTF-8
// symbol charset to unicode; other non roman chars to replacement character

{
	static char buff[MAXREC*4];	// room for full length record at 4 bytes per char
	char *sptr, *dptr, *mark;
	char lastfontcode = 0;

//	if (!converter)
//		converter = openconverter();
	// NB will never convert an old color code. Did we ever use?
	for (sptr = xstring, dptr = buff; *sptr != EOCS;)		{
		if (isoldfontcodeptr(sptr))	{	// if font code
			char fontcode = *(sptr+1)&~FX_FONT;
			if (fm[fontcode].flags&CHARSETSYMBOLS)	{	// if the font needs char conversion
				sptr += 2;		// skip font change codes
				while (!isoldfontcodeptr(sptr) && *(sptr+1)) {	// while in range of font
					if (iscodechar(*sptr))	{	// copy any non font codes as is
						*dptr++ = *sptr++;
						*dptr++ = *sptr++;
					}
					else {	// encode characters
						UErrorCode error = U_ZERO_ERROR;
						unichar uc;
						int charlength;
						
#if 0
						if (fontcode == 1)	// symbol
							uc = symbolcharfromroman(*sptr);
						else 
							uc = REPLACECHAR;	// unknown (replacement) character
#else
						uc = Uconvertspecialcharacter(fm[fontcode].pname,*sptr);	// get converted character
#endif
						u_strToUTF8(dptr,10,&charlength,&uc,1,&error);
						sptr++;
						dptr += charlength;
					}
				}
				if (*(sptr+1) == lastfontcode)	// if got here by encountering code for prev font
					sptr += 2;		// skip reversion to it
				continue;	// round again until finished
			}
			else {		//  code for normal font; copy it & save its id
				*dptr++ = FONTCHR;	// install new font code
				sptr++;		// discard old code chr
				lastfontcode = *sptr++;		// save it as last active font
				*dptr++ = lastfontcode == FX_FONT ? FX_FONT : lastfontcode-1;	// reduce font above default by 1 only if not default
			}
		}
		else {
			char * source;
			char * dest;
			size_t sourcecount;
			size_t destcount;

			// if we ever had color codes in old records, would need to convert here
			while (isoldstylecodeptr(sptr))	{	// while style codes to change
				*dptr++ = *sptr++;
				if (*sptr&FX_OLDOFF)	// if off style code
					*dptr++ = (*sptr++&FX_STYLEMASK)|FX_OFF;	// convert off code to new form
				else		// must be on code
					*dptr++ = *sptr++;
			}
			for (mark = sptr; *mark != CODECHR && *mark != EOCS; mark++)	// acumulate non code chars
				;
			source = sptr;
			dest = dptr;
			sourcecount = mark-sptr;
			destcount = MAXREC*4-(dptr-buff);
			do {
				size_t length = iconv(converter,&source,&sourcecount,&dest,&destcount);
			
				if ((int)length < 0)	{	// if error (some char unconvertable)
					dest = u8_appendU(dest,REPLACECHAR);	// unknown char
					source++;
					sourcecount--;
					destcount -= 3;
				}
			} while (sourcecount);
			sptr = mark;
			dptr = dest;
		}
	}
	*dptr++ = EOCS;
	if (replace)
		str_xcpy(xstring, buff);
	return dptr-buff;
}
/*******************************************************************************/
static unichar Uconvertspecialcharacter(char * font, unsigned char schar)	// return unichar value of font character

{
	unichar uc = 0;
	int index;
	
	for (index = 0; t_specialfonts[index].name; index++)	{	// for all special fonts
		if (!strcmp(t_specialfonts[index].name,font))	{	// if this is one
			uc = t_specialfonts[index].ucode[schar];
			break;
		}
	}
	if (!uc)
		uc = REPLACECHAR;	// unknown
	return uc;
}
/****************************************************************************/
iconv_t v3_openconverter(char * ctype)	// opens converter

{
	if (converter)	{
		iconv_close(converter);
		converter = NULL;
	}
	if (ctype)
		converter = iconv_open("UTF-8",ctype);		// do specified conversion
	else {
#if defined CIN_MAC_OS
		converter = iconv_open("UTF-8",V2_CHARSET);		// do mac OS
#else
		char cp[100];

		sprintf(cp,"CP%d",GetACP());	// name of code page
		converter = iconv_open("UTF-8",cp);	// try current code page
		if (!converter)	// if don't have it
			converter = iconv_open("UTF-8",V2_CHARSET);		// do windows latin
#endif
	}
	return converter;
}
/****************************************************************************/
static void Uconvertformatparams(FORMATPARAMS * fp)		// converts format params

{
	int pindex;
	
	// formatparams - pageformat
	Uconvertstring(fp->pf.mc.continued,FSSTRING);
	Uconvertheader_footer(&fp->pf.lefthead);
	Uconvertheader_footer(&fp->pf.leftfoot);
	Uconvertheader_footer(&fp->pf.righthead);
	Uconvertheader_footer(&fp->pf.rightfoot);
	// formatparams - entry format
	// groupformat
	Uconvertstring(fp->ef.eg.gfont,FSSTRING);
	Uconvertstring(fp->ef.eg.title,FSSTRING);
	// cross refs
	for (pindex = 0; pindex < 2; pindex++)	{
		Uconvertstring(fp->ef.cf.level[pindex].cleada,FMSTRING);
		Uconvertstring(fp->ef.cf.level[pindex].cenda,FMSTRING);
		Uconvertstring(fp->ef.cf.level[pindex].cleadb,FMSTRING);
		Uconvertstring(fp->ef.cf.level[pindex].cendb,FMSTRING);
	}
	// locator format
	Uconvertstring(fp->ef.lf.llead1,FMSTRING);
	Uconvertstring(fp->ef.lf.lleadm,FMSTRING);
	Uconvertstring(fp->ef.lf.trail,FMSTRING);
	Uconvertstring(fp->ef.lf.connect,FMSTRING);
	Uconvertstring(fp->ef.lf.suppress,FMSTRING);
	Uconvertstring(fp->ef.lf.concatenate,FMSTRING);
	// field format
	for (pindex = 0; pindex < FIELDLIM-1; pindex++)	{
		Uconvertstring(fp->ef.field[pindex].font,FSSTRING);
		Uconvertstring(fp->ef.field[pindex].trailtext,FMSTRING);
		Uconvertstring(fp->ef.field[pindex].leadtext,FMSTRING);
	}
}
/****************************************************************************/
static void Uconvertheader_footer(HEADERFOOTER * hfp)

{
	Uconvertstring(hfp->left,FTSTRING);
	Uconvertstring(hfp->center,FTSTRING);
	Uconvertstring(hfp->right,FTSTRING);
	Uconvertstring(hfp->hffont,FSSTRING);	// shouldn't be necessary
}
#if 0
/****************************************************************************/
static BOOL Uconvertchar(char *source)	// does in place conversion of single char
{
	char dest[1];
	char * sptr = source;
	char * dptr = dest;
	size_t sourcecount = 1;
	size_t destcount = 1;
	size_t length;
	
//	if (!converter)
//		converter = openconverter();
	length = iconv(converter,&sptr,&sourcecount,&dptr,&destcount);
	if ((int)length < 0)	// if error
		NSLog(@"Could not convert %s (%d)", source,errno);
	else
		*source = dest[0];
	return (int)length >= 0;
}
#else
/****************************************************************************/
static BOOL Uconvertchar(V3CCONVERT * v3cvp,char *source, char defchar)	// does in place conversion of single char
{
	char * sptr = source;
	char * dptr = v3cvp->converted;
	size_t sourcecount = 1;
	size_t destcount = MAXUTF8STRING;
	size_t length;
	
	memset(v3cvp->converted,0,MAXUTF8STRING);
	length = iconv(converter,&sptr,&sourcecount,&dptr,&destcount);
	if ((int)length < 0)	// if error
		NSLog(@"Could not convert %s (%d)", source,errno);
	else {
		if (strlen(v3cvp->converted) == 1)	{	// if converted to single byte char
			*source = v3cvp->converted[0];
			v3cvp->error = FALSE;
		}
		else {
			*source = defchar;
			v3cvp->error = TRUE;
		}
		v3cvp->output = *source;
	}
	return ((int)length == 0);
}
#endif
/****************************************************************************/
static BOOL Uconvertstring(char *source, int capacity)	// does in place conversion
{
	size_t limitlength = strlen(source);
	char * dest = malloc(capacity*6);	// allocate bigger than could need
	char * sptr, * dptr;
	size_t sourcecount, destcount,convertedlength;
	
//	if (!converter)
//		converter = openconverter();
	do {
		sptr = source;
		dptr = dest;
		sourcecount = limitlength;
		destcount = capacity*6;
		convertedlength = iconv(converter,&sptr,&sourcecount,&dptr,&destcount);
	} while (capacity*6-destcount > capacity-1 && --limitlength);	// while utf-8 string would be too long
	if ((int)convertedlength < 0) 	// if error
		NSLog(@"Could not convert %s (%d)", source,errno);
	else	{
		*dptr = '\0';	// terminate string
		strcpy(source,dest);
	}
	free(dest);
	return (int)convertedlength >= 0;
}
/****************************************************************************/
static BOOL Uconvertxstring(char *source, int capacity)	// does in place conversion
{
	char * dest = malloc(capacity*6);	// allocate bigger than could need
	size_t limitlength = str_xlen(source);
	char * sptr, * dptr;
	size_t sourcecount, destcount,convertedlength;
	
//	if (!converter)
//		converter = openconverter();
	do {
		sptr = source;
		dptr = dest;
		sourcecount = limitlength;
		destcount = capacity*6;
		convertedlength = iconv(converter,&sptr,&sourcecount,&dptr,&destcount);
		if (capacity*6-destcount <= capacity-1)		// if ok
			break;
		while (limitlength > 0 && source[--limitlength])	// step back one string while utf-8 string would be too long
				;
	} while (limitlength);	// limitlength now terminating 0 of current string
	if ((int)convertedlength < 0) 	// if error
		NSLog(@"Could not convert %s (%d)", source,errno);
	else	{
		*dptr = EOCS;	// terminate string
		str_xcpy(source,dest);
	}
	free(dest);
	return (int)convertedlength >= 0;
}
/***************************************************************************/
static BOOL isoldfontcodeptr(char *cc)	// tests if code represents font

{
	if (*cc++ == CODECHR && *cc&FX_FONT && !(*cc&FX_COLOR))
		return TRUE;
	return FALSE;
}
/***************************************************************************/
static BOOL isoldstylecodeptr(char *cc)	// tests if code represents old style

{
	if (*cc++ == CODECHR && !(*cc&FX_FONT))
		return TRUE;
	return FALSE;
}
/***************************************************************************/
static void convertV2header(HEAD * hp, V2HEAD * v2hp)	// converts v2 header

{
	int pindex;
	
	hp->endian = v2hp->endian;
//	hp->headsize = CFSwapInt32HostToBig(HEADSIZE);	// set current header size in big endian
	hp->version = v2hp->version;
	hp->rtot = v2hp->rtot;
	hp->elapsed = v2hp->elapsed;
	hp->createtime = v2hp->createtime;
	hp->resized = v2hp->resized;
	hp->squeezetime = v2hp->squeezetime;
	convertV2indexpars(&hp->indexpars,&v2hp->indexpars);
	convertV2sortpars(&hp->sortpars,&v2hp->sortpars);
	convertV2refpars(&hp->refpars,&v2hp->refpars);
	convertV2privpars(&hp->privpars,&v2hp->privpars);
	convertV2formpars(&hp->formpars,&v2hp->formpars);
	memcpy(hp->stylestrings,v2hp->stylestrings,sizeof(v2hp->stylestrings));
	for (pindex = 0; pindex < FONTLIMIT; pindex++)
		convertV2fontmap(&hp->fm[pindex],&v2hp->fm[pindex]);
	hp->root = v2hp->root;
	hp->dirty = v2hp->dirty;
	hp->mainviewrect = v2hp->mainviewrect;
	hp->recordviewrect = v2hp->recordviewrect;
}
/***************************************************************************/
static void convertV2indexpars(INDEXPARAMS *ip, V2INDEXPARAMS * v2ip)	// converts v2 index params

{
	int index;
	
	ip->recsize = v2ip->recsize;
	ip->minfields = v2ip->minfields;
	ip->maxfields = v2ip->maxfields;
	ip->required = v2ip->required;
	for (index = 0; index < FIELDLIM; index++)	{
		strcpy(ip->field[index].name,v2ip->field[index].name);
		ip->field[index].minlength = v2ip->field[index].minlength;
		ip->field[index].maxlength = v2ip->field[index].maxlength;
		strcpy(ip->field[index].matchtext,v2ip->field[index].matchtext);
	}
}
/***************************************************************************/
static void convertV2privpars(PRIVATEPARAMS *pp, V2PRIVATEPARAMS * v2pp)	// converts v2 private params

{
	pp->vmode = v2pp->vmode;
	pp->wrap = v2pp->wrap;
	pp->shownum = v2pp->shownum;
	pp->hidedelete =v2pp->hidedelete;
	pp->hidebelow =v2pp->hidebelow;
	pp->size = v2pp->size;
	pp->eunit = v2pp->eunit;
	pp->filterenabled = v2pp->filterenabled;
	memcpy(&pp->filter.label,&v2pp->filter.label,sizeof(v2pp->filter.label));
}
/***************************************************************************/
static void convertV2sortpars(SORTPARAMS *sp, V2SORTPARAMS * v2sp)	// converts v2 sort params

{	
	sp->type = v2sp->type;
	memcpy(&sp->fieldorder,&v2sp->fieldorder,sizeof(v2sp->fieldorder));
	memcpy(&sp->charpri,&v2sp->charpri,sizeof(v2sp->charpri));
	sp->ignorepunct = v2sp->ignorepunct;
	sp->ignoreslash = v2sp->ignoreslash;
	sp->ignoreparen = v2sp->ignoreparen;
	sp->evalnums = v2sp->evalnums;
	memcpy(sp->ignore,v2sp->ignore,sizeof(v2sp->ignore));
	sp->skiplast = v2sp->skiplast;
	sp->ordered = v2sp->ordered;
	sp->ascendingorder = v2sp->ascendingorder;
	sp->ison = v2sp->ison;
	memcpy(&sp->refpri,&v2sp->refpri,sizeof(v2sp->refpri));
	memcpy(&sp->partorder,&v2sp->partorder,sizeof(v2sp->partorder));
	memcpy(&sp->styleorder,&v2sp->styleorder,sizeof(v2sp->styleorder));
	memcpy(&sp->reftab,&v2sp->reftab,sizeof(v2sp->reftab));
	memcpy(&sp->styletab,&v2sp->styletab,sizeof(v2sp->styletab));
}
/***************************************************************************/
static void convertV2refpars(REFPARAMS *rp, V2REFPARAMS * v2rp)	// converts v2 ref params

{
	strcpy(rp->crosstart,v2rp->crosstart);
	strcpy(rp->crossexclude,v2rp->crossexclude);
	strcpy(rp->maxvalue,v2rp->maxvalue);
	rp->csep = v2rp->csep;
	rp->psep = v2rp->psep;
	rp->rsep = v2rp->rsep;
	rp->clocatoronly = v2rp->clocatoronly;
	rp->maxspan = v2rp->maxspan;
}
/***************************************************************************/
static void convertV2formpars(FORMATPARAMS *fp, V2FORMATPARAMS * v2fp)	// converts v2 format params

{
	int index;
	
	fp->version = FORMVERSION;
	fp->fsize = sizeof(FORMATPARAMS);
	// PAGE FORMAT
	// margins and columns
	fp->pf.mc.top = v2fp->pf.mc.top;
	fp->pf.mc.bottom = v2fp->pf.mc.bottom;
	fp->pf.mc.left = v2fp->pf.mc.left;
	fp->pf.mc.right = v2fp->pf.mc.right;
	fp->pf.mc.ncols = v2fp->pf.mc.ncols;
	fp->pf.mc.gutter = v2fp->pf.mc.gutter;
	fp->pf.mc.reflect = v2fp->pf.mc.reflect;
	fp->pf.mc.pgcont = v2fp->pf.mc.pgcont;
	strcpy(fp->pf.mc.continued,v2fp->pf.mc.continued);
	convertV2cstyle(&fp->pf.mc.cstyle,&v2fp->pf.mc.cstyle);
	fp->pf.mc.clevel = v2fp->pf.mc.clevel;
	// headers and footers
	convertV2headerfooter(&fp->pf.lefthead,&v2fp->pf.lefthead);
	convertV2headerfooter(&fp->pf.leftfoot,&v2fp->pf.leftfoot);
	convertV2headerfooter(&fp->pf.righthead,&v2fp->pf.righthead);
	convertV2headerfooter(&fp->pf.rightfoot,&v2fp->pf.rightfoot);
	// misc
	fp->pf.linespace = v2fp->pf.linespace;
	fp->pf.firstpage = v2fp->pf.firstpage;
	fp->pf.lineheight = v2fp->pf.lineheight;
	fp->pf.entryspace = v2fp->pf.entryspace;
	fp->pf.above = v2fp->pf.above;
	fp->pf.lineunit = v2fp->pf.lineunit;
	fp->pf.autospace = v2fp->pf.autospace;
	fp->pf.dateformat = v2fp->pf.dateformat;
	fp->pf.timeflag = v2fp->pf.timeflag;
	fp->pf.pi.porien = v2fp->pf.pi.porien;
	fp->pf.pi.psize = v2fp->pf.pi.psize;
	fp->pf.pi.pwidth = v2fp->pf.pi.pwidth;
	fp->pf.pi.pheight = v2fp->pf.pi.pheight;
	fp->pf.pi.pwidthactual = v2fp->pf.pi.pwidthactual;
	fp->pf.pi.pheightactual = v2fp->pf.pi.pheightactual;
	fp->pf.pi.xoffset = v2fp->pf.pi.xoffset;
	fp->pf.pi.yoffset = v2fp->pf.pi.yoffset;
	fp->pf.numformat = v2fp->pf.numformat;
	fp->pf.orientation = v2fp->pf.orientation;
	
	// ENTRY FORMAT
	fp->ef.runlevel = v2fp->ef.runlevel;
	fp->ef.collapselevel = v2fp->ef.collapselevel;
	fp->ef.style = v2fp->ef.style;
	fp->ef.itype = v2fp->ef.itype;
	fp->ef.adjustpunct = v2fp->ef.adjustpunct;
	fp->ef.adjstyles = v2fp->ef.adjstyles;
	fp->ef.fixedunit = v2fp->ef.fixedunit;
	fp->ef.autounit = v2fp->ef.autounit;
	fp->ef.autolead = v2fp->ef.autolead;
	fp->ef.autorun = v2fp->ef.autorun;
	// group
	fp->ef.eg.method = v2fp->ef.eg.method;
	strcpy(fp->ef.eg.gfont,v2fp->ef.eg.gfont);
	strcpy(fp->ef.eg.title,v2fp->ef.eg.title);
	convertV2cstyle(&fp->ef.eg.gstyle,&v2fp->ef.eg.gstyle);
	fp->ef.eg.gsize = v2fp->ef.eg.gsize;
	// crossref
	for (index = 0; index < 2; index++)	{
		strcpy(fp->ef.cf.level[index].cleada,v2fp->ef.cf.level[index].cleada);
		strcpy(fp->ef.cf.level[index].cenda,v2fp->ef.cf.level[index].cenda);
		strcpy(fp->ef.cf.level[index].cleadb,v2fp->ef.cf.level[index].cleadb);
		strcpy(fp->ef.cf.level[index].cendb,v2fp->ef.cf.level[index].cendb);
	}
	convertV2cstyle(&fp->ef.cf.leadstyle,&v2fp->ef.cf.leadstyle);
	convertV2cstyle(&fp->ef.cf.bodystyle,&v2fp->ef.cf.bodystyle);
	fp->ef.cf.subposition = v2fp->ef.cf.subposition;
	fp->ef.cf.mainposition = v2fp->ef.cf.mainposition;
	fp->ef.cf.sortcross = v2fp->ef.cf.sortcross;
	fp->ef.cf.suppressall = v2fp->ef.cf.suppressall;
	fp->ef.cf.subseeposition = v2fp->ef.cf.subseeposition;
	fp->ef.cf.mainseeposition = v2fp->ef.cf.mainseeposition;
	// locator
	fp->ef.lf.sortrefs = v2fp->ef.lf.sortrefs;
	fp->ef.lf.rjust = v2fp->ef.lf.rjust;
	fp->ef.lf.suppressall = v2fp->ef.lf.suppressall;
	fp->ef.lf.suppressparts = v2fp->ef.lf.suppressparts;
	strcpy(fp->ef.lf.llead1,v2fp->ef.lf.llead1);
	strcpy(fp->ef.lf.lleadm,v2fp->ef.lf.lleadm);
	strcpy(fp->ef.lf.trail,v2fp->ef.lf.trail);
	strcpy(fp->ef.lf.connect,v2fp->ef.lf.connect);
	fp->ef.lf.conflate = v2fp->ef.lf.conflate;
	fp->ef.lf.abbrevrule = v2fp->ef.lf.abbrevrule;
	strcpy(fp->ef.lf.suppress,v2fp->ef.lf.suppress);
	strcpy(fp->ef.lf.concatenate,v2fp->ef.lf.concatenate);
	for (index = 0; index < V2COMPMAX; index++)	{
		convertV2cstyle(&fp->ef.lf.lstyle[index].loc,&v2fp->ef.lf.lstyle[index].loc);
		convertV2cstyle(&fp->ef.lf.lstyle[index].punct,&v2fp->ef.lf.lstyle[index].punct);
	}
	fp->ef.lf.leader = v2fp->ef.lf.leader;
	// fields
	for (index = 0; index < FIELDLIM-1; index++)	{
		strcpy(fp->ef.field[index].font,v2fp->ef.field[index].font);
		fp->ef.field[index].size = v2fp->ef.field[index].size;
		convertV2cstyle(&fp->ef.field[index].style,&v2fp->ef.field[index].style);
		fp->ef.field[index].leadindent = v2fp->ef.field[index].leadindent;
		fp->ef.field[index].runindent = v2fp->ef.field[index].runindent;
		strcpy(fp->ef.field[index].trailtext,v2fp->ef.field[index].trailtext);
		fp->ef.field[index].flags = v2fp->ef.field[index].flags;
		strcpy(fp->ef.field[index].leadtext,v2fp->ef.field[index].leadtext);
	}
}
/***************************************************************************/
static void convertV2headerfooter(HEADERFOOTER *hfp, V2HEADERFOOTER * v2hfp)	// converts v2 head/foot params

{
	strcpy(hfp->left,v2hfp->left);
	strcpy(hfp->center,v2hfp->center);
	strcpy(hfp->right,v2hfp->right);
	convertV2cstyle(&hfp->hfstyle,&v2hfp->hfstyle);
	strcpy(hfp->hffont,v2hfp->hffont);
	hfp->size = v2hfp->size;
}
/***************************************************************************/
static void convertV2cstyle(CSTYLE *cp, V2CSTYLE * v2cp)	// converts v2 cstyle params

{
	cp->style = v2cp->style;
	cp->cap = v2cp->cap;
//	cp->allowauto = v2cp->allowauto;
}
/***************************************************************************/
static void convertV2fontmap(FONTMAP *fmp, V2FONTMAP * v2fmp)	// converts v2 fontmap

{
	strcpy(fmp->pname, v2fmp->pname);
	strcpy(fmp->name, v2fmp->name);
}
/***************************************************************************/
static void convertV2listgroup(LISTGROUP *lgp, V2LISTGROUP * v2lgp)	// converts v2 listgroup

{
	int index;
	
	strcpy(lgp->userid, v2lgp->userid);
	lgp->lflags = v2lgp->lflags;
	lgp->size = v2lgp->size;
	lgp->revflag = v2lgp->revflag;
	lgp->excludeflag = v2lgp->excludeflag;
	lgp->newflag = v2lgp->newflag;
	lgp->modflag = v2lgp->modflag;
	lgp->markflag = v2lgp->markflag;
	lgp->delflag = v2lgp->delflag;
	lgp->genflag = v2lgp->genflag;
	lgp->sortmode = v2lgp->sortmode;
	lgp->tagflag = v2lgp->tagflag;
	lgp->tagvalue = v2lgp->tagvalue;
	lgp->firstr = v2lgp->firstr;
	lgp->lastr = v2lgp->lastr;
	lgp->firstdate = v2lgp->firstdate;
	lgp->lastdate = v2lgp->lastdate;
	for (index = 0; index < MAXLISTS; index++)
		convertV2list(&lgp->lsarray[index],&v2lgp->lsarray[index]);
}
/***************************************************************************/
static void convertV2list(LIST *lgp, V2LIST * v2lgp)	// converts v2 list

{
	strcpy(lgp->string, v2lgp->string);
	lgp->field = v2lgp->field;
	lgp->patflag = v2lgp->patflag;
	lgp->caseflag = v2lgp->caseflag;
	lgp->notflag = v2lgp->notflag;
	lgp->andflag = v2lgp->andflag;
	lgp->evalrefflag = v2lgp->evalrefflag;
	lgp->wordflag = v2lgp->wordflag;
	lgp->style = v2lgp->style;
	lgp->font = v2lgp->font;
}
/***************************************************************************/
static void convertV2group(GROUP *gp, V2GROUP * v2gp)	// converts v2 group

{
	gp->tstamp = v2gp->tstamp;
	gp->indextime = v2gp->indextime;
	strcpy(gp->gname, v2gp->gname);
	strcpy(gp->comment, v2gp->comment);
	gp->gflags = v2gp->gflags;
	convertV2listgroup(&gp->lg,&v2gp->lg);
	convertV2sortpars(&gp->sg,&v2gp->sg);
	gp->rectot = v2gp->rectot;
	memcpy(gp->recbase, v2gp->recbase,v2gp->rectot*sizeof(RECN));
}

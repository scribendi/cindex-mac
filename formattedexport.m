//
//  formattedexport.m
//  Cindex
//
//  Created by Peter Lennie on 1/29/11.
//  Copyright 2011 Peter Lennie. All rights reserved.
//

#import "formattedexport.h"
#import "formattedtext.h"
#import "type.h"
#import "group.h"
#import "attributedstrings.h"
#import "tags.h"
#import "xmlwriter.h"
#import "rtfwriter.h"

enum {		/* style code indexes for file production */
	EX_BOLDON = 0,
	EX_BOLDOFF,
	EX_ITALON,
	EX_ITALOFF,
	EX_ULINEON,
	EX_ULINEOFF,
	EX_SMALLON,
	EX_SMALLOFF,
	EX_SUPERON,
	EX_SUPEROFF,
	EX_SUBON,
	EX_SUBOFF,
	EX_BOLDITALON,
	EX_BOLDITALOFF
};

static char * f_mac = "\r";		/* mac newline */
static char * f_dos = "\r\n";	/* unix newline */

static int lastlevel;
static BOOL bodyended;

static char * writeline(FCONTROLX * exp,char * source, ATTRIBUTES * as);   // emit field
static void closeline(FCONTROLX * exp,ATTRIBUTES * ast, char *estring);	/* flushes dangling codes, emits end tag, terminates line */
static void writetext(FCONTROLX * exp,char * base, int length);	/* emits text string */
static void writeattributes(FCONTROLX * exp,ATTRIBUTES * as, char codes);	/* set up attributes from code byte */
static void writecode(FCONTROLX * exp,short code);	/* emits style code */
static void writestring(FCONTROLX * exp,char * string);	/* emits style code */
static void endfont(FCONTROLX * exp,ATTRIBUTES * as);	/* emits style code */
static void flushattributes(FCONTROLX * exp,ATTRIBUTES * ast);	// flushes dangling codes

/******************************************************************************/
NSData * formexport_write(INDEX * FF, EXPORTPARAMS * exp, FCONTROLX * xptr)	/* opens & writes formatted export file */

{
	NSMutableData * edata = [NSMutableData dataWithLength:FF->head.rtot*FF->wholerec*2+3000];
	
	xptr->newlinestring = exp->newlinetype ? f_dos: f_mac;	/* set newline string */
	xptr->usetabs = exp->usetabs;		/* set leader tab control */
	if (FF->head.privpars.vmode != VM_FULL)		/* if not in full format view */
		[FF->owner setViewFormat:VM_FULL];			/* set to full */
	
	if (exp->firstpage || exp->lastpage)	{		// if wanted page range
		FF->pf.firstrec = exp->first;
		FF->pf.lastrec = exp->last;
		FF->pf.first = exp->firstpage;
		FF->pf.last = exp->lastpage;
		[FF->owner formPageImages];
		exp->first = FF->pf.rnum;
		exp->last = FF->pf.lastrnum;
		memset(&FF->pf,0,sizeof(PRINTFORMAT));
	}
	if (edata)	{ // if have buffer
		GROUPHANDLE gh = NULL;
		GROUPHANDLE currentGroup;
		char * baseptr = [edata mutableBytes];
		xptr->esptr = baseptr;
		xptr->filetype = exp->type;
		FF->typesetter = xptr;
		
		if (exp->last != UINT_MAX)	{	// if have set some range, handle it as group
			gh = grp_startgroup(FF);
			grp_buildfromrange(FF,&gh,exp->first,exp->last,GF_SELECT);	// build group (always handle as ending at record beyond range)
			currentGroup = FF->curfile;		// install as current
			FF->curfile = gh;
		}
		formexport_stylenames(xptr,FF);	// load style names
		if ((xptr->efstart)(FF,xptr))	{
			RECORD * curptr = sort_top(FF);	/* get start record */
			
			for (lastlevel = 0; curptr; curptr = form_skip(FF,curptr,1))	 {	/* for all records */
//				NSLog(@"%ld",curptr->num);
				formexport_buildentry(FF, curptr);
			}
			if (FF->pf.entries)	{	// if have written entries
				if (xptr->nested)	{
					while (lastlevel >= 0)
						closeline(xptr,NULL,xptr->structtags[STR_MAINEND+lastlevel--]);	// insert end tag
				}
				closeline(xptr,NULL,xptr->structtags[STR_GROUPEND]);	// close last group
			}
			(xptr->efend)(FF,xptr);	/* build end string */
			[edata setLength:xptr->esptr-baseptr];		// set correct length of data
		}
		if (gh)	{		// dispose of any group
			FF->curfile = currentGroup;
			grp_dispose(gh);
		}
		FF->typesetter = NULL;
	}
	return (edata);
}
/******************************************************************************/
void formexport_buildentry(INDEX * FF, RECORD * recptr)	/* builds entry of right type; appends to data */

{
	FCONTROLX * xptr = FF->typesetter;
	int textlines = 0;
	char * cptr;
	ENTRYINFO es;
	ATTRIBUTES ast;
	
	form_buildentry(FF, recptr, &es);
	memset(&ast,0,sizeof(ast));		/* clear attribute struct */
	cptr = FF->formBuffer;
	
	if (xptr->nested && !es.firstrec)	{
		if (xptr->nested && es.ulevel > lastlevel)	// if emitting lower level than last
			writestring(xptr,xptr->newpara);	// break without end tag
		else {
			while (lastlevel >= es.ulevel && lastlevel >= 0)
				closeline(xptr,NULL,xptr->structtags[STR_MAINEND+lastlevel--]);	// insert end tag
		}
		lastlevel = es.ulevel >= 0 ? es.ulevel : 0;
	}
	if (es.leadchange || es.firstrec)	{	// if starting a group (could be without lead change, if no visible lead to first group)
		if (!es.firstrec && *xptr->structtags[STR_GROUPEND])		{		// if not first record and there's an end tag
			closeline(xptr,NULL,xptr->structtags[STR_GROUPEND]);	// close preceding group
			textlines++;
		}
		if (*xptr->structtags[STR_GROUP])	// if there's a group start tag
			closeline(xptr,NULL,xptr->structtags[STR_GROUP]);	// open group
		if (es.ahead)	{	// if have header text to emit
			writestring(xptr,xptr->structtags[STR_AHEAD]);
			cptr = writeline(xptr,cptr,&ast);
			closeline(xptr,&ast,xptr->structtags[STR_AHEADEND]);
			textlines++;
		}
		es.ulevel = 0;
	}
	while (*cptr) {
		if (xptr->nested && es.ulevel > lastlevel)	// if emitting lower level than last
			writestring(xptr,xptr->newpara);	// break without end tag
		if (es.ulevel > 0 && es.ulevel == es.llevel && FF->head.formpars.ef.itype == FI_SPECIAL)	// if want special last tag
			es.ulevel = FF->head.indexpars.maxfields-2;	// set lowest level heading
		writestring(xptr,xptr->structtags[STR_MAIN+es.ulevel]);	/* put in tag */
		writestring(xptr, xptr->auxtags[OT_STARTTEXT]);		// emit any body start tag
		bodyended = FALSE;
		cptr = writeline(xptr,cptr,&ast);
		if (!bodyended)		// if haven't emitted body end
			writestring(xptr, xptr->auxtags[OT_ENDTEXT]);		// do it
		if (xptr->nested)
			flushattributes(xptr,&ast);
		else
			closeline(xptr,&ast, xptr->structtags[STR_MAINEND+es.ulevel]);
		textlines++;
		lastlevel = es.ulevel;
		es.ulevel++;
	}
	FF->pf.prefs += es.prefs;
	FF->pf.crefs += es.crefs;
	FF->pf.entries += es.drecs;
	FF->pf.lines += textlines;
}
/******************************************************************************/
void formexport_makefield(FCONTROLX * xptr, INDEX * FF, char * source)     // formats field to output for embedding

{
	char *scan, *cbase;
	int count;
	ATTRIBUTES ast;
	
	FF->typesetter = xptr;	// make static pointer to file struct
	memset(&ast,0,sizeof(ast));				/* clear attribute struct */
	ast.nsize = FF->head.privpars.size;		/* temp standard font size */
	ast.fmp = FF->head.fm;

	form_stripcopy(FF->formBuffer,source);	/* strip and clean up string */
	cbase = scan = FF->formBuffer;
	while ((*scan)) {       /* while not at end */
		switch (*scan++) {
			case CODECHR:
				writetext(xptr,cbase,scan-cbase-1);
				writeattributes(xptr,&ast,*scan++);
				break;
			case FONTCHR:
				writetext(xptr,cbase,scan-cbase-1);
				writeattributes(xptr,&ast,(*scan++)|FX_AUTOFONT);
				break;
			case ESCCHR:			/* if escape sequence */
			case KEEPCHR:			/* if keep marker */
				writetext(xptr,cbase,scan-cbase-1);
				cbase = scan++;		/* next char tested is one after protected one */
				continue;
			default:
				continue;
		}
		cbase = scan;
	}
	writetext(xptr,cbase,scan-cbase);
	for (count = 0; count < FX_XTOT; count++)	{	/* for all attributes */
		if (ast.attcount[count] > 0)	{		/* if outstanding attribute is on */
			writecode(xptr,(count<<1) +1);		/* send off code */
			ast.attcount[count] = 0;
		}
	}
	while (ast.findex >0)		/* while fonts on stack */
		endfont(xptr,&ast);
}
/**********************************************************************************/
void formexport_gettypeindents(INDEX * FF, int level, int tabmode, int scale, int * firstindent, int * baseindent, char * tabcontrol, char * tabstops, char * tabset)	/* gets typesetting indents, appropriately scaled */

{
	int mwidth = type_getfontmetrics(FF->head.formpars.ef.field[level].font,FF->head.formpars.ef.field[level].size,FF).width;
	int tcount;
	char * tsptr;
	float first, base;

	if (FF->head.formpars.ef.itype == FI_NONE)
		base = first = 0;
//	else if (FF->head.formpars.ef.itype == FI_AUTO || FF->head.formpars.ef.itype == FI_SPECIAL && level < L_SPECIAL)	{
	else if (FF->head.formpars.ef.itype == FI_AUTO || FF->head.formpars.ef.itype == FI_SPECIAL && level < FF->head.indexpars.maxfields-2)	{
		base = FF->head.formpars.ef.autolead*level+FF->head.formpars.ef.autorun;
		first = -FF->head.formpars.ef.autorun;	/* is neg offset from base */
		if (!FF->head.formpars.ef.autounit)	{	/* if em spacing */
			base *= mwidth;
			first *= mwidth;
		}
	}
	else	{	/* fixed indentation (points) */
		if (FF->head.formpars.ef.itype == FI_SPECIAL && level == FF->head.indexpars.maxfields-2)	// if special last
			level = L_SPECIAL;		// get for level 15 heading
		base = FF->head.formpars.ef.field[level].runindent;	/* is absolute indent */
		first = -(base-FF->head.formpars.ef.field[level].leadindent);	/* is neg offset from base */
		if (!FF->head.formpars.ef.fixedunit)	{	/* if em spacing */
			base *= mwidth;
			first *= mwidth;
		}
	}
	*baseindent = scale*base;
	*firstindent = scale*first;
	*tabstops = '\0';		/* assume no tab indents */
	memset(tabset,0,FIELDLIM);	/* clear all tabs */
	if (tabmode && FF->head.formpars.ef.itype != FI_NONE)	{		/* if want lead indents defined by tabs */
		if (tabmode == '\t')	{
			for (tcount = 1, tsptr = tabstops; tcount <= level; tcount++)
				tsptr += sprintf(tsptr, tabcontrol, tcount*mwidth*scale);
			memset(tabset,'\t',level);	/* set tabs */
		}
		else
			memset(tabset,tabmode,level);	/* set arbitrary character */
		*firstindent = scale*-base;
	}	
}
/******************************************************************************/
void formexport_stylenames(FCONTROLX * xptr, INDEX * FF)	// installs names to use for styles

{
	NSDictionary * styleDic = [[NSUserDefaults standardUserDefaults] dictionaryForKey:[NSString stringWithFormat:@"exportStyles%d",xptr->filetype]];
	
	if (styleDic && [[styleDic objectForKey:kStyleUseExplicitNames] boolValue]) {
		NSArray * sArray = [styleDic objectForKey:kStyleStyleNames];
		// element at index FIELDLIM-1 is alpha header
		for (int fcount = 0; fcount < FIELDLIM; fcount++)
			strcpy(xptr->stylenames[fcount],[[sArray objectAtIndex:fcount] UTF8String]);
	}
	else {
		strcpy(xptr->stylenames[FIELDLIM-1],xptr->filetype == E_RTF ? "ahead" : "Ahead");	// deal with legacy version 3
		for (int fcount = 0; fcount < FF->head.indexpars.maxfields; fcount++)
			strcpy(xptr->stylenames[fcount],FF->head.indexpars.field[fcount].name);
	}
}
/******************************************************************************/
static char * writeline(FCONTROLX * exp,char * source, ATTRIBUTES * as)   // emit field

{
	char cc, *scan, *cbase;
	
	cbase = scan = source;
	while ((cc = *scan)) {       /* while not at end   */
		switch (*scan++) {
			case CODECHR:
				writetext(exp,cbase,scan-cbase-1);
				writeattributes(exp,as,*scan++);
				break;
			case FONTCHR:
				writetext(exp,cbase,scan-cbase-1);
				writeattributes(exp,as,(*scan++)|FX_AUTOFONT);
				break;
			case ESCCHR:			/* if escape sequence */
			case KEEPCHR:			/* if keep marker */
				writetext(exp,cbase,scan-cbase-1);
				cbase = scan++;		/* next char tested is one after protected one */
				continue;
			case FO_RPADCHAR:
				writetext(exp,cbase,scan-cbase-1);
				writestring(exp,exp->tab);	/* emit tab sequence */
				break;
			case FO_LEVELBREAK:
			case FO_NEWLEVEL:
				writetext(exp,cbase,scan-cbase-1);
				return scan;
			case FO_PAGE:
			case FO_CROSS:
				writetext(exp,cbase,scan-cbase-1);
				if (!bodyended) {
					writestring(exp, exp->auxtags[OT_ENDTEXT]);		// emit any body end tag
					bodyended = TRUE;
				}
				writestring(exp,exp->structtags[cc == FO_PAGE ? STR_PAGE : STR_CROSS]);
				break;
			case FO_EPAGE:
			case FO_ECROSS:
				writetext(exp,cbase,scan-cbase-1);
				writestring(exp,exp->structtags[cc == FO_EPAGE ? STR_PAGEND : STR_CROSSEND]);
				break;
			default:
				continue;
		}
		cbase = scan;
	}
	writetext(exp,cbase,scan-cbase);
	return scan;
}
/******************************************************************************/
static void flushattributes(FCONTROLX * exp,ATTRIBUTES * ast)	// flushes dangling codes

{
	if (ast)	{
		int count;
		
		for (count = 0; count < FX_XTOT; count++)	{	/* for all attributes */
			if (ast->attcount[count] > 0)	{		/* if outstanding attribute is on */
				writecode(exp,(count << 1) +1);		/* send off code */
				ast->attcount[count] = 0;
			}
		}
		while (ast->findex >0)		/* while fonts on stack */
			endfont(exp,ast);
	}
}
/******************************************************************************/
static void closeline(FCONTROLX * exp,ATTRIBUTES * ast, char *estring)	/* flushes dangling codes, emits end tag, terminates line */

{
	if (ast)	{
		int count;

		for (count = 0; count < FX_XTOT; count++)	{	/* for all attributes */
			if (ast->attcount[count] > 0)	{		/* if outstanding attribute is on */
				writecode(exp,(count << 1) +1);		/* send off code */
				ast->attcount[count] = 0;
			}
		}
		while (ast->findex >0)		/* while fonts on stack */
			endfont(exp,ast);
	}
	if (*estring)		/* if want end tag */
		writestring(exp,estring);	/* emit end tag  */
	writestring(exp,exp->newpara);
}
/**********************************************************************/
static void writetext(FCONTROLX * exp,char * base, int length)	/* emits text string */

{
	char *bptr = base;
	unichar uc;
	char *iptr;
	
#if 0
	while (bptr-base < length)	{	/* while chars to emit */
		uc = u8_nextU(&bptr);
		if (uc == '\t')		/* if tab */
			writestring(exp,exp->tab);
		else if (iptr = memchr(exp->protected,uc,MAXTSTRINGS))	/* if in protected list */
			writestring(exp,exp->pstrings[iptr-exp->protected]);	/* insert string at index */
		else {
			if (uc >= 0x80)	// if not ASCII
				(exp->efwriter)(exp,uc);	// encode it
			else
				*exp->esptr++ = uc;
		}
	}
#else
	while (bptr-base < length)	{	/* while chars to emit */
		if (*bptr == '\t')		/* if tab */
			writestring(exp,exp->tab);
		else if (iptr = memchr(exp->protected,*bptr,MAXTSTRINGS))	/* if in protected list */
			writestring(exp,exp->pstrings[iptr-exp->protected]);	/* insert string at index */
		else if ((unsigned char)*bptr >= 0x80 && exp->efwriter)	{	// if need unicode conversion
			uc = u8_nextU(&bptr);
			(exp->efwriter)(exp,uc);	// encode it
			continue;
		}
		else
			*exp->esptr++ = *bptr;
		bptr++;
	}
#endif
}
#if 0
/**********************************************************************/
static void writeattributes(FCONTROLX * exp,ATTRIBUTES * as, char codes)	/* set up attributes from code byte */

{
	if (codes&FX_AUTOFONT)	{	/* if a font */
		codes &= ~FX_AUTOFONT;		// clear autofont flag
		if (codes&FX_FONT)	{
			int newbase = codes&FX_AUTOFONT;	/* flags change of base font */
			int fcode;
			
			codes &= FX_FONTMASK;
			if (codes < T_NUMFONTS)	{	/* if have a potential code to produce */
				if (!codes)	{					/* if want current base */
					while (!atbasefont(as))	{	/* while not at base font */
						fcode = popfont(as);
						if (*exp->fontset[(fcode <<1)+1])	/* if the current format uses off codes */
							writestring(exp,exp->fontset[(fcode <<1)+1]);	/* send string */
						else if (atbasefont(as))	/* no off codes ; if reached base */
							writestring(exp,exp->fontset[(currentfont(as) <<1)]);	/* emit it */
					}
				}
				else if (codes == secondfont(as))	/* if reverting to last font */
					endfont(exp,as);
				else	{							/* must be new one */
					fcode = pushfont(as,codes);
					writestring(exp,exp->fontset[fcode<<1]);
				}
				if (newbase)
					setbasefont(as);	/* set new base font */
			}
		}
	}
	else {				/* a style code */
		if (codes&FX_OFF)	{	/* if turning off */
			if (codes&FX_SUB)	{		/* do in reverse order from turn on */
				writecode(exp,EX_SUBOFF);
				as->base = 0;
			}
			if (codes&FX_SUPER)	{
				writecode(exp,EX_SUPEROFF);
				as->base = 0;
			}
			if (codes&FX_SMALL && as->attcount[FX_SMALLX] && !--as->attcount[FX_SMALLX])	{
				as->attr &= ~FX_SMALL;
				writecode(exp,EX_SMALLOFF);
			}
			if (codes&FX_ULINE && as->attcount[FX_ULINEX] && !--as->attcount[FX_ULINEX])	{
				as->attr &= ~FX_ULINE;
				writecode(exp,EX_ULINEOFF);
			}
			if ((codes&FX_BOLDITAL) == FX_BOLDITAL && *exp->styleset[EX_BOLDITALON] && as->attcount[FX_BOLDITALX]&& !--as->attcount[FX_BOLDITALX])	{
				as->attr &= ~FX_BOLDITAL;
				writecode(exp,EX_BOLDITALOFF);
			}
			else {
				if (codes&FX_ITAL)	{
					if (as->attcount[FX_ITALX] && !--as->attcount[FX_ITALX])	{	/* if ordinary ital off */
						as->attr &= ~FX_ITAL;
						writecode(exp,EX_ITALOFF);
					}
					else if (!as->attcount[FX_ITALX] && *exp->styleset[EX_BOLDITALON] && as->attcount[FX_BOLDITALX] && !--as->attcount[FX_BOLDITALX])	{/* bold ital is active */
						as->attr &= ~FX_ITAL;
						writecode(exp,EX_BOLDITALOFF);
						if (!as->attcount[FX_BOLDX]++)
							writecode(exp,EX_BOLDON);
					}
				}
				if (codes&FX_BOLD)	{
					if (as->attcount[FX_BOLDX] && !--as->attcount[FX_BOLDX])	{	/* if ordinary bold off */
						as->attr &= ~FX_BOLD;
						writecode(exp,EX_BOLDOFF);
					}
					else if (!as->attcount[FX_BOLDX] && *exp->styleset[EX_BOLDITALON] && as->attcount[FX_BOLDITALX] && !--as->attcount[FX_BOLDITALX])	{/* bold ital is active */
						as->attr &= ~FX_BOLD;
						writecode(exp,EX_BOLDITALOFF);
						if (!as->attcount[FX_ITALX]++)
							writecode(exp,EX_ITALON);
					}
				}
			}
		}
		else {					/* turning on */
			if ((codes&FX_BOLDITAL) == FX_BOLDITAL && *exp->styleset[EX_BOLDITALON] && !as->attcount[FX_BOLDITALX]++)	{
				as->attr |= FX_BOLDITAL;
				writecode(exp,EX_BOLDITALON);
			}
			else {
				if (codes&FX_BOLD)	{	/* if want bold on */
					if (as->attcount[FX_ITALX] && *exp->styleset[EX_BOLDITALON] && !as->attcount[FX_BOLDITALX]++)	{	/* if already have ital on and can do bold ital */
						if (!--as->attcount[FX_ITALX])
							writecode(exp,EX_ITALOFF);
						as->attr |= FX_BOLDITAL;
						writecode(exp,EX_BOLDITALON);	
					}
					else if (!as->attcount[FX_BOLDX]++)	{	/* just do plain */
						as->attr |= FX_BOLD;
						writecode(exp,EX_BOLDON);
					}
				}
				if (codes&FX_ITAL)	{	/* if want ital on */
					if (as->attcount[FX_BOLDX] && *exp->styleset[EX_BOLDITALON] && !as->attcount[FX_BOLDITALX]++)	{	/* if already have bold on and can do bold ital */
						if (!--as->attcount[FX_BOLDX])
							writecode(exp,EX_BOLDOFF);
						as->attr |= FX_BOLDITAL;
						writecode(exp,EX_BOLDITALON);	
					}
					else if (!as->attcount[FX_ITALX]++)	{	/* just do plain */
						as->attr |= FX_ITAL;
						writecode(exp,EX_ITALON);
					}
				}
			}
			if (codes&FX_ULINE && !as->attcount[FX_ULINEX]++)	{
				as->attr |= FX_ULINE;
				writecode(exp,EX_ULINEON);
			}
			if (codes&FX_SMALL && !as->attcount[FX_SMALLX]++)	{
				as->attr |= FX_SMALL;
				writecode(exp,EX_SMALLON);
			}
			if (codes&FX_SUPER && as->base <= 0)	{	/* if not already in super position */
				writecode(exp,EX_SUPERON);
				as->base = SUPSUBSTEP;
			}
			if (codes&FX_SUB && as->base >= 0)	{	/* if not already in sub position */
				writecode(exp,EX_SUBON);
				as->base = -SUPSUBSTEP;
			}
		}
	}
}
#else
/**********************************************************************/
static void writeattributes(FCONTROLX * exp,ATTRIBUTES * as, char codes)	/* set up attributes from code byte */

{
	if (codes&FX_AUTOFONT)	{	/* if a font */
		codes &= ~FX_AUTOFONT;		// clear autofont flag
		if (codes&FX_FONT)	{
			int newbase = codes&FX_AUTOFONT;	/* flags change of base font */
			int fcode;
			
			codes &= FX_FONTMASK;
			if (codes < T_NUMFONTS)	{	/* if have a potential code to produce */
				if (!codes)	{					/* if want current base */
					while (!atbasefont(as))	{	/* while not at base font */
						fcode = popfont(as);
						if (*exp->fontset[(fcode <<1)+1])	/* if the current format uses off codes */
							writestring(exp,exp->fontset[(fcode <<1)+1]);	/* send string */
						else if (atbasefont(as))	/* no off codes ; if reached base */
							writestring(exp,exp->fontset[(currentfont(as) <<1)]);	/* emit it */
					}
				}
				else if (codes == secondfont(as))	/* if reverting to last font */
					endfont(exp,as);
				else	{							/* must be new one */
					fcode = pushfont(as,codes);
					writestring(exp,exp->fontset[fcode<<1]);
				}
				if (newbase)
					setbasefont(as);	/* set new base font */
			}
		}
	}
	else {				/* a style code */
		if (codes&FX_OFF)	{	/* if turning off */
			if (codes&FX_SUB && as->soffset)	{		/* do in reverse order from turn on */
				writecode(exp,EX_SUBOFF);
				as->soffset = 0;
			}
			if (codes&FX_SUPER && as->soffset)	{
				writecode(exp,EX_SUPEROFF);
				as->soffset = 0;
			}
			if (codes&FX_SMALL && as->attcount[FX_SMALLX] && !--as->attcount[FX_SMALLX])	{
				as->attr &= ~FX_SMALL;
				writecode(exp,EX_SMALLOFF);
			}
			if (codes&FX_ULINE && as->attcount[FX_ULINEX] && !--as->attcount[FX_ULINEX])	{
				as->attr &= ~FX_ULINE;
				writecode(exp,EX_ULINEOFF);
			}
			if ((codes&FX_BOLDITAL) == FX_BOLDITAL && *exp->styleset[EX_BOLDITALON] && as->attcount[FX_BOLDITALX]&& !--as->attcount[FX_BOLDITALX])	{
				as->attr &= ~FX_BOLDITAL;
				writecode(exp,EX_BOLDITALOFF);
			}
			else {
				if (codes&FX_ITAL)	{
					if (as->attcount[FX_ITALX] && !--as->attcount[FX_ITALX])	{	/* if ordinary ital off */
						as->attr &= ~FX_ITAL;
						writecode(exp,EX_ITALOFF);
					}
					else if (!as->attcount[FX_ITALX] && *exp->styleset[EX_BOLDITALON] && as->attcount[FX_BOLDITALX] && !--as->attcount[FX_BOLDITALX])	{/* bold ital is active */
						as->attr &= ~FX_ITAL;
						writecode(exp,EX_BOLDITALOFF);
						if (!as->attcount[FX_BOLDX]++)
							writecode(exp,EX_BOLDON);
					}
				}
				if (codes&FX_BOLD)	{
					if (as->attcount[FX_BOLDX] && !--as->attcount[FX_BOLDX])	{	/* if ordinary bold off */
						as->attr &= ~FX_BOLD;
						writecode(exp,EX_BOLDOFF);
					}
					else if (!as->attcount[FX_BOLDX] && *exp->styleset[EX_BOLDITALON] && as->attcount[FX_BOLDITALX] && !--as->attcount[FX_BOLDITALX])	{/* bold ital is active */
						as->attr &= ~FX_BOLD;
						writecode(exp,EX_BOLDITALOFF);
						if (!as->attcount[FX_ITALX]++)
							writecode(exp,EX_ITALON);
					}
				}
			}
		}
		else {					/* turning on */
			if ((codes&FX_BOLDITAL) == FX_BOLDITAL && *exp->styleset[EX_BOLDITALON] && !as->attcount[FX_BOLDITALX]++)	{
				as->attr |= FX_BOLDITAL;
				writecode(exp,EX_BOLDITALON);
			}
			else {
				if (codes&FX_BOLD)	{	/* if want bold on */
					if (as->attcount[FX_ITALX] && *exp->styleset[EX_BOLDITALON] && !as->attcount[FX_BOLDITALX]++)	{	/* if already have ital on and can do bold ital */
						if (!--as->attcount[FX_ITALX])
							writecode(exp,EX_ITALOFF);
						as->attr |= FX_BOLDITAL;
						writecode(exp,EX_BOLDITALON);	
					}
					else if (!as->attcount[FX_BOLDX]++)	{	/* just do plain */
						as->attr |= FX_BOLD;
						writecode(exp,EX_BOLDON);
					}
				}
				if (codes&FX_ITAL)	{	/* if want ital on */
					if (as->attcount[FX_BOLDX] && *exp->styleset[EX_BOLDITALON] && !as->attcount[FX_BOLDITALX]++)	{	/* if already have bold on and can do bold ital */
						if (!--as->attcount[FX_BOLDX])
							writecode(exp,EX_BOLDOFF);
						as->attr |= FX_BOLDITAL;
						writecode(exp,EX_BOLDITALON);	
					}
					else if (!as->attcount[FX_ITALX]++)	{	/* just do plain */
						as->attr |= FX_ITAL;
						writecode(exp,EX_ITALON);
					}
				}
			}
			if (codes&FX_ULINE && !as->attcount[FX_ULINEX]++)	{
				as->attr |= FX_ULINE;
				writecode(exp,EX_ULINEON);
			}
			if (codes&FX_SMALL && !as->attcount[FX_SMALLX]++)	{
				as->attr |= FX_SMALL;
				writecode(exp,EX_SMALLON);
			}
			if (codes&FX_SUPER && as->soffset <= 0)	{	/* if not already in super position */
				writecode(exp,EX_SUPERON);
				as->soffset = 1;
			}
			if (codes&FX_SUB && as->soffset >= 0)	{	/* if not already in sub position */
				writecode(exp,EX_SUBON);
				as->soffset = -1;
			}
		}
	}
}
#endif
/**********************************************************************/
static void writecode(FCONTROLX * exp,short code)	/* emits style code */

{
	writestring(exp,exp->styleset[code]);
}
/**********************************************************************/
static void writestring(FCONTROLX * exp,char * string)	/* emits style code */

{
	strcpy(exp->esptr,string);
	exp->esptr += strlen(string);
}
/**********************************************************************/
static void endfont(FCONTROLX * exp,ATTRIBUTES * as)	/* emits style code */

{
	int fcode;

	if (*exp->fontset[(currentfont(as) << 1)+1])	{	/* if the current format uses off codes */
		fcode = popfont(as);		/* get off code for current font, and pop it */
		writestring(exp,exp->fontset[(fcode << 1)+1]);	/* send string */
	}
	else {		/* don't use off codes */
		fcode = getprevfont(as);	/* discard current font, get previous font off the stack */
		writestring(exp,exp->fontset[(fcode << 1)]);	/* emit it */
	}
}

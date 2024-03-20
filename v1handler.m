//
//  v1handler.m
//  Cindex
//
//  Created by PL on 1/8/05.
//  Copyright 2005 Peter Lennie. All rights reserved.
//

#import "v2headers.h"
#import "v1handler.h"
#import "collate.h"

static void convertformparams(V2FORMATPARAMS * fp, V2FORMATPARAMS * v1fp, int version);		// converts format parameters
static void convertsortparams(V2HEAD * hp, V1HEAD * v1hp);		// converts sort parameters

/*******************************************/
BOOL v1_convertheader(V2HEAD * hp, V1HEAD * v1hp)		// converts header parameters

{
	int sourceversion = CFSwapInt16BigToHost(v1hp->version);
	
	if (sourceversion >= 110)	{	// can't convert anything below 110
		hp->endian = 0;		// big endian
		hp->headsize = CFSwapInt32HostToBig(HEADSIZE);	// set current header size in big endian
		hp->version = v1hp->version;
		hp->rtot = v1hp->rtot;
		hp->elapsed = v1hp->elapsed;
		hp->createtime = v1hp->createtime;
		hp->resized = v1hp->resized;
		hp->squeezetime = v1hp->squeezetime;
		hp->indexpars = v1hp->indexpars;
		convertsortparams(hp,v1hp);
		hp->refpars = v1hp->refpars;
		hp->privpars = v1hp->privpars;
		convertformparams(&hp->formpars,&v1hp->formpars,sourceversion);
		memcpy(hp->stylestrings,v1hp->stylestrings,STYLESTRINGLEN);
		memcpy(hp->fm,v1hp->fm,sizeof(v1hp->fm));
		hp->root = v1hp->root;
		hp->dirty = v1hp->dirty;
		hp->mainviewrect = v1hp->mainviewrect;
		hp->recordviewrect = v1hp->recordviewrect;
		return YES;
	}
	return NO;
}
/*******************************************/
void v1_convertstylesheet(V2STYLESHEET * sp, V1STYLESHEET * v1sp)		// converts format parameters

{
	sp->endian = 0;		// big endian
	convertformparams(&sp->fg,&v1sp->fg,CFSwapInt16BigToHost(v1sp->fg.version) < 120 ? 150 : 160);
	sp->fontsize = v1sp->fontsize;
	memcpy(&sp->fm,&v1sp->fm,sizeof(v1sp->fm));	// copy font map
}
/*******************************************/
static void convertformparams(V2FORMATPARAMS * fp, V2FORMATPARAMS * v1fp, int version)		// converts format parameters

{
	*fp = *v1fp;		// do basic conversion by copy
	// endianness is safe here: all addressing is by byte or clearing to zero
	if (fp->pf.dateformat == 0)	// fix date format index
		fp->pf.dateformat = 2;
	else if (fp->pf.dateformat == 2)
		fp->pf.dateformat = 0;
	fp->pf.dateformat++;
	if (version < 160) {		// if created by 1.5 or lower
		int hindex;
		if (version < 150)		{	/* if < 1.5, adjust cross-ref position code for new option */
			if (fp->ef.cf.mainposition)
				fp->ef.cf.mainposition++;		/* step any subhead position */
		}
		for (hindex = 0; hindex < FIELDLIM-1; hindex++)	// clear heading size fields
			fp->ef.field[hindex].size = 0;
		fp->ef.eg.gsize = 0;		// clear group size
	}
}
/*******************************************/
static void convertsortparams(V2HEAD * hp, V1HEAD * v1hp)		// converts sort parameters

{
	int index;
	
	hp->sortpars.type = v1hp->sortpars.type;
	hp->sortpars.ignorepunct = v1hp->sortpars.ignorepunct;
	hp->sortpars.ignoreslash = v1hp->sortpars.ignoreslash;
	hp->sortpars.ignoreparen = v1hp->sortpars.ignoreparen;
	hp->sortpars.evalnums = v1hp->sortpars.evalnums;
	hp->sortpars.skiplast = v1hp->sortpars.skiplast;
	hp->sortpars.ordered = v1hp->sortpars.ordered;
	hp->sortpars.ascendingorder = v1hp->sortpars.ascendingorder;
	hp->sortpars.ison = v1hp->sortpars.ison;
	
	memcpy(&hp->sortpars.fieldorder,&v1hp->sortpars.fieldorder,sizeof(v1hp->sortpars.fieldorder));
	memcpy(&hp->sortpars.charpri,&v1hp->sortpars.charpri,sizeof(v1hp->sortpars.charpri));
	memcpy(&hp->sortpars.ignore,&v1hp->sortpars.ignore,sizeof(v1hp->sortpars.ignore));
	memcpy(&hp->sortpars.refpri,&v1hp->sortpars.refpri,sizeof(v1hp->sortpars.refpri));
	memcpy(&hp->sortpars.partorder,&v1hp->sortpars.partorder,sizeof(v1hp->sortpars.partorder));
//	memcpy(&hp->sortpars.chartab,&v1hp->sortpars.chartab,sizeof(v1hp->sortpars.chartab));	// not needed for v3
	memcpy(&hp->sortpars.reftab,&v1hp->sortpars.reftab,sizeof(v1hp->sortpars.reftab));
	for (index = 0; index < STYLETYPES; index++)		// set default locator style precedence
		hp->sortpars.styleorder[index] = CFSwapInt16HostToBig(index);
	hp->sortpars.styleorder[index] = CFSwapInt16HostToBig(-1);
	index = CFSwapInt16BigToHost(hp->sortpars.type);
	if (index == 1)			// old word sort
		hp->sortpars.type = CFSwapInt16HostToBig(WORDSORT);
	else if (index == 2)	// old letter sort
		hp->sortpars.type = CFSwapInt16HostToBig(LETTERSORT);
}
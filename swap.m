//
//  swap.m
//  Cindex
//
//  Created by Peter Lennie on 5/30/08.
//  Copyright 2008 Indexing Research. All rights reserved.
//

#import "swap.h"
#import "records.h"
#import "group.h"

//static void swapgroup(GROUP * gptr);	// swaps group as necessary for host
static float swapfloat(void * dptr);	/* swaps bytes of float */
/***************************************************************************/
void swap_Header(HEAD * hp)	// swaps bytes as necessary for host
{
	if (hp->endian != TARGET_RT_LITTLE_ENDIAN)	{	// if written on different architecture
		unsigned int index;
		
		hp->headsize = CFSwapInt32(hp->headsize);
		hp->version = CFSwapInt16(hp->version);
		hp->rtot = CFSwapInt32(hp->rtot);
		hp->elapsed = CFSwapInt32(hp->elapsed);
		hp->createtime = CFSwapInt32(hp->createtime);
		hp->resized = CFSwapInt16(hp->resized);
		hp->squeezetime = CFSwapInt32(hp->squeezetime);
		// index params
		hp->indexpars.recsize = CFSwapInt16(hp->indexpars.recsize);
		hp->indexpars.minfields = CFSwapInt16(hp->indexpars.minfields);
		hp->indexpars.maxfields = CFSwapInt16(hp->indexpars.maxfields);
		for (index = 0; index < FIELDLIM; index++)	{
			hp->indexpars.field[index].minlength = CFSwapInt16(hp->indexpars.field[index].minlength);
			hp->indexpars.field[index].maxlength = CFSwapInt16(hp->indexpars.field[index].maxlength);
		}
		hp->indexpars.required = CFSwapInt16(hp->indexpars.required);
		// sort params
		swap_SortParams(&hp->sortpars);
		// refparams
		hp->refpars.maxspan = CFSwapInt32(hp->refpars.maxspan);
		// private params
		hp->privpars.hidebelow = CFSwapInt16(hp->privpars.hidebelow);
		hp->privpars.size = CFSwapInt16(hp->privpars.size);
		// format params
		swap_FormatParams(&hp->formpars);
		hp->root = CFSwapInt32(hp->root);
		hp->dirty = CFSwapInt16(hp->dirty);
		hp->mainviewrect.origin.x = swapfloat(&hp->mainviewrect.origin.x);
		hp->mainviewrect.origin.y = swapfloat(&hp->mainviewrect.origin.y);
		hp->mainviewrect.size.width = swapfloat(&hp->mainviewrect.size.width);
		hp->mainviewrect.size.height = swapfloat(&hp->mainviewrect.size.height);
		hp->recordviewrect.origin.x = swapfloat(&hp->recordviewrect.origin.x);
		hp->recordviewrect.origin.y = swapfloat(&hp->recordviewrect.origin.y);
		hp->recordviewrect.size.width = swapfloat(&hp->recordviewrect.size.width);
		hp->recordviewrect.size.height = swapfloat(&hp->recordviewrect.size.height);
		// convert records
	}
}
/***************************************************************************/
void swap_FormatParams(FORMATPARAMS *fg)		// swaps bytes
{
	int index;
	// PAGE FORMAT
	// margin & column
	fg->fsize = CFSwapInt32(fg->fsize);
	fg->version = CFSwapInt16(fg->version);
	fg->pf.mc.top = CFSwapInt16(fg->pf.mc.top);
	fg->pf.mc.bottom = CFSwapInt16(fg->pf.mc.bottom);
	fg->pf.mc.left = CFSwapInt16(fg->pf.mc.left);
	fg->pf.mc.right = CFSwapInt16(fg->pf.mc.right);
	fg->pf.mc.ncols = CFSwapInt16(fg->pf.mc.ncols);
	fg->pf.mc.gutter = CFSwapInt16(fg->pf.mc.gutter);
	fg->pf.mc.reflect = CFSwapInt16(fg->pf.mc.reflect);
	fg->pf.mc.pgcont = CFSwapInt16(fg->pf.mc.pgcont);
	fg->pf.mc.cstyle.style = CFSwapInt16(fg->pf.mc.cstyle.style);
	fg->pf.mc.cstyle.cap  = CFSwapInt16(fg->pf.mc.cstyle.cap);
	fg->pf.mc.clevel = CFSwapInt16(fg->pf.mc.clevel);
	// headers and footers
	fg->pf.lefthead.hfstyle.style = CFSwapInt16(fg->pf.lefthead.hfstyle.style);
	fg->pf.lefthead.hfstyle.cap = CFSwapInt16(fg->pf.lefthead.hfstyle.cap);
	fg->pf.lefthead.size = CFSwapInt16(fg->pf.lefthead.size);
	fg->pf.leftfoot.hfstyle.style = CFSwapInt16(fg->pf.leftfoot.hfstyle.style);
	fg->pf.leftfoot.hfstyle.cap = CFSwapInt16(fg->pf.leftfoot.hfstyle.cap);
	fg->pf.leftfoot.size = CFSwapInt16(fg->pf.leftfoot.size);
	fg->pf.righthead.hfstyle.style = CFSwapInt16(fg->pf.righthead.hfstyle.style);
	fg->pf.righthead.hfstyle.cap = CFSwapInt16(fg->pf.righthead.hfstyle.cap);
	fg->pf.righthead.size = CFSwapInt16(fg->pf.righthead.size);
	fg->pf.rightfoot.hfstyle.style = CFSwapInt16(fg->pf.rightfoot.hfstyle.style);
	fg->pf.rightfoot.hfstyle.cap = CFSwapInt16(fg->pf.rightfoot.hfstyle.cap);
	fg->pf.rightfoot.size = CFSwapInt16(fg->pf.rightfoot.size);
	
	fg->pf.linespace = CFSwapInt16(fg->pf.linespace);
	fg->pf.firstpage = CFSwapInt16(fg->pf.firstpage);
	fg->pf.lineheight = CFSwapInt16(fg->pf.lineheight);
	fg->pf.entryspace = CFSwapInt16(fg->pf.entryspace);
	fg->pf.above = CFSwapInt16(fg->pf.above);
	fg->pf.pi.porien = CFSwapInt16(fg->pf.pi.porien);
	fg->pf.pi.psize = CFSwapInt16(fg->pf.pi.psize);
	fg->pf.pi.pwidth = CFSwapInt16(fg->pf.pi.pwidth);
	fg->pf.pi.pheight = CFSwapInt16(fg->pf.pi.pheight);
	fg->pf.pi.pwidthactual = CFSwapInt16(fg->pf.pi.pwidthactual);
	fg->pf.pi.pheightactual = CFSwapInt16(fg->pf.pi.pheightactual);
	fg->pf.pi.xoffset = CFSwapInt16(fg->pf.pi.xoffset);
	fg->pf.pi.yoffset = CFSwapInt16(fg->pf.pi.yoffset);
	// ENTRY FORMAT
	fg->ef.runlevel = CFSwapInt16(fg->ef.runlevel);
	fg->ef.collapselevel = CFSwapInt16(fg->ef.collapselevel);
	fg->ef.autolead = swapfloat(&fg->ef.autolead);
	fg->ef.autorun = swapfloat(&fg->ef.autorun);
	// group format
	fg->ef.eg.method = CFSwapInt16(fg->ef.eg.method);
	fg->ef.eg.gstyle.style = CFSwapInt16(fg->ef.eg.gstyle.style);
	fg->ef.eg.gstyle.cap = CFSwapInt16(fg->ef.eg.gstyle.cap);
	fg->ef.eg.gsize = CFSwapInt16(fg->ef.eg.gsize);
	// crossref format
	fg->ef.cf.leadstyle.style = CFSwapInt16(fg->ef.cf.leadstyle.style);
	fg->ef.cf.leadstyle.cap = CFSwapInt16(fg->ef.cf.leadstyle.cap);
	fg->ef.cf.bodystyle.style = CFSwapInt16(fg->ef.cf.bodystyle.style);
	fg->ef.cf.bodystyle.cap = CFSwapInt16(fg->ef.cf.bodystyle.cap);
	// locator format
	fg->ef.lf.conflate = CFSwapInt16(fg->ef.lf.conflate);
	fg->ef.lf.abbrevrule = CFSwapInt16(fg->ef.lf.abbrevrule);
	for (index = 0; index < COMPMAX; index++)	{
		fg->ef.lf.lstyle[index].loc.style = CFSwapInt16(fg->ef.lf.lstyle[index].loc.style);
		fg->ef.lf.lstyle[index].loc.cap = CFSwapInt16(fg->ef.lf.lstyle[index].loc.cap);
		fg->ef.lf.lstyle[index].punct.style = CFSwapInt16(fg->ef.lf.lstyle[index].punct.style);
		fg->ef.lf.lstyle[index].punct.cap = CFSwapInt16(fg->ef.lf.lstyle[index].punct.cap);
	}
	// field format
	for (index = 0; index < FIELDLIM-1; index++)	{
		fg->ef.field[index].size = CFSwapInt16(fg->ef.field[index].size);
		fg->ef.field[index].style.style = CFSwapInt16(fg->ef.field[index].style.style);
		fg->ef.field[index].style.cap = CFSwapInt16(fg->ef.field[index].style.cap);
		fg->ef.field[index].leadindent = swapfloat(&fg->ef.field[index].leadindent);
		fg->ef.field[index].runindent = swapfloat(&fg->ef.field[index].runindent);
	}
}
/***************************************************************************/
void swap_SortParams(SORTPARAMS *sp)		// swaps bytes
{
	int index;
	
	for (index = 0; index < FIELDLIM+1; index++)
		sp->fieldorder[index] = CFSwapInt16(sp->fieldorder[index]);
	for (index = 0; index < CHARPRI+1; index++)
		sp->charpri[index] = CFSwapInt16(sp->charpri[index]);
	for (index = 0; index < REFTYPES+1; index++)
		sp->refpri[index] = CFSwapInt16(sp->refpri[index]);
	for (index = 0; index < COMPMAX+1; index++)
		sp->partorder[index] = CFSwapInt16(sp->partorder[index]);
	for (index = 0; index < STYLETYPES+1; index++)
		sp->styleorder[index] = CFSwapInt16(sp->styleorder[index]);
}
/***************************************************************************/
void swap_SearchParams(LISTGROUP *lg)		// swaps bytes
{
	int count;
	
	lg->lflags = CFSwapInt16(lg->lflags);
	lg->size = CFSwapInt16(lg->size);
	lg->tagvalue = CFSwapInt32(lg->tagvalue);
	lg->firstr = CFSwapInt32(lg->firstr);
	lg->lastr = CFSwapInt32(lg->lastr);
	lg->firstdate = CFSwapInt32(lg->firstdate);
	lg->lastdate = CFSwapInt32(lg->lastdate);
	for (count = 0; count < MAXLISTS; count++)	{
		lg->lsarray[count].field = CFSwapInt16(lg->lsarray[count].field);
//		lg->lsarray[count].expcount = CFSwapInt16(lg->lsarray[count].expcount);
	}
}
/***************************************************************************/
void swap_Records(INDEX * FF) // swaps bytes as necessary for host
{
	enum btol {		// bitfields are byte swapped in short word, and also left-right reversed
#if TARGET_RT_LITTLE_ENDIAN		// if intel target
		B_ISDEL = 0x40,
		B_ISMARK = 0x20,
		B_ISGEN = 0x1,
		B_ISLABEL = 0xe000,
#else
		B_ISDEL = 0x200,
		B_ISMARK = 0x400,
		B_ISGEN = 0x4000,
		B_ISLABEL = 0x7,
#endif
	};
	if (FF->head.endian != TARGET_RT_LITTLE_ENDIAN)	{	// if written on different architecture
		RECN index;
		for (index = 1; index <= FF->head.rtot; index++)	{
			RECORD * rp = getaddress(FF,index);
			short *bfptr = (void*)rp->user+4;
			short bitfields = *bfptr;	// get bitfields as word
			
			rp->num = CFSwapInt32(rp->num);
			rp->parent = CFSwapInt32(rp->parent);
			rp->lchild = CFSwapInt32(rp->lchild);
			rp->rchild = CFSwapInt32(rp->rchild);
			rp->time = CFSwapInt32(rp->time);
			*bfptr = 0;		// clear bit fields of destination
			if (bitfields&B_ISDEL)
				rp->isdel = TRUE;
			if (bitfields&B_ISMARK)
				rp->ismark = TRUE;
			if (bitfields&B_ISGEN)
				rp->isgen = TRUE;
			if (bitfields&B_ISLABEL)
#if TARGET_RT_LITTLE_ENDIAN		// if intel target
				rp->label = (bitfields&B_ISLABEL)>>13;	// shift masked bits into range
#else
				rp->label = (bitfields&B_ISLABEL);	// shift masked bits into range
#endif
		}
	}
}
/***************************************************************************/
void swap_StyleSheet(STYLESHEET * ssp) // swaps stylesheet as necessary for host
{
	if (ssp->endian != TARGET_RT_LITTLE_ENDIAN)	{	// if endianness not right
		swap_FormatParams(&ssp->fg);	// swap format params as necessary
		ssp->fontsize = CFSwapInt16(ssp->fontsize);	// swap font size
		ssp->endian = TARGET_RT_LITTLE_ENDIAN;	// set current endianness
	}
}
/***************************************************************************/
void swap_Groups(INDEX * FF) // swaps groups as necessary for host
{
	if (FF->head.endian != TARGET_RT_LITTLE_ENDIAN)	{	// if written on different architecture
		GROUPHANDLE gh;
		
		for (gh = FF->gbase; (char *)gh < (char *)FF->gbase+FF->head.groupsize; gh = nextgroup(gh))	{	// for all valid groups
			swap_Group(gh);
		}
	}
}
/*******************************************************************************/
void swap_Group(GROUP * gptr)	// swaps group as necessary for host

{
	unsigned int count;
	
	gptr->size = CFSwapInt32(gptr->size);
	gptr->tstamp = CFSwapInt32(gptr->tstamp);
	gptr->indextime = CFSwapInt32(gptr->indextime);
	gptr->limit = CFSwapInt32(gptr->limit);
	gptr->gflags = CFSwapInt16(gptr->gflags);
	swap_SearchParams(&gptr->lg);
	swap_SortParams(&gptr->sg);
	gptr->rectot = CFSwapInt32(gptr->rectot);
	for (count = 0; count < gptr->rectot; count++)
		gptr->recbase[count] = CFSwapInt32(gptr->recbase[count]);
}
/*******************************************************************************/
static float swapfloat(void * dptr)	/* swaps bytes of float */

{
	union {
		Float32 dd;
		uint32_t ii;
	} ds;
	ds.ii = CFSwapInt32(*(uint32_t *)dptr);
	return ds.dd;
}

//
//  group.m
//  Cindex
//
//  Created by PL on 1/15/05.
//  Copyright 2005 Indexing Research. All rights reserved.
//

#import "group.h"
#import "sort.h"
#import "collate.h"
#import "refs.h"
#import "records.h"
#import "strings_c.h"
#import "search.h"
#import "index.h"
#import "commandutils.h"
#import "cindexmenuitems.h"
#import "collate.h"

static GROUPHANDLE gfind(INDEX * FF, char * name);	/* returns pointer to group */
static void gremove(INDEX * FF, char * name);	/* removes group */
static BOOL gresize(GROUPHANDLE *gp,RECN newrecs);	/* changes size or reports error */
static BOOL gisvalid(INDEX * FF, GROUPHANDLE gh); // checks valid group
static short makerange(INDEX * FF, short scope, char * lptr, char * hptr, RECN * first, RECN * last);		/* finds start and stop recs */

/******************************************************************************/
void grp_checkparams(INDEX * FF)	// checks/fixes group parameters

{
	GROUPHANDLE fgp;
	for (fgp = FF->gbase; gisvalid(FF,fgp); fgp = nextgroup(fgp))	{	// for all groups
		SORTPARAMS *spars = &fgp->sg;
		LANGDESCRIPTOR * locale = col_fixLocaleInfo(spars);	// do fixes on sort params
		
		if (!locale) {	// must be group from higher version with more locales
			strcpy(spars->language, "en");	// default to english
			strcpy(spars->localeID, "en");
			spars->nativescriptfirst = TRUE;
		}
		// following needed because for group written by v3 these fields (now in different posn in struct) might not be clear
		// if regex not clear, search_clearauxbuff() would crash trying to close old regex
		for (int lcount = 0; lcount < MAXLISTS; lcount++) {
			fgp->lg.lsarray[lcount].regex = NULL;
			fgp->lg.lsarray[lcount].auxptr = NULL;
		}
	}
}
/******************************************************************************/
NSMenu * grp_buildmenu(INDEX * FF, BOOL enabled)	/* builds and checks group menu */

{
	NSMenu * gmenu = [[NSMenu alloc] init];
	GROUPHANDLE fgp;
	
	[gmenu setAutoenablesItems:NO];
	for (fgp = FF->gbase; gisvalid(FF,fgp); fgp = nextgroup(fgp))	{	/* for all groups */
		NSMenuItem * mitem = (NSMenuItem *)[gmenu addItemWithTitle:[NSString stringWithUTF8String:fgp->gname] action:@selector(changeView:) keyEquivalent:@""];
		if (!enabled && FF->head.squeezetime >= fgp->tstamp)	// if to disable invalid
			[mitem setEnabled:NO];	// disable item
		[mitem setTag:MI_GROUP];
	}
	return gmenu;
}
//******************************************************************************/
BOOL grp_checkintegrity(INDEX * FF)	// checks integrity of groups

{
	GROUPHANDLE fgp;

	for (fgp = FF->gbase; gisvalid(FF,fgp); fgp = nextgroup(fgp))	// for all valid groups
		;
	return (char *)fgp-(char *)FF->gbase == FF->head.groupsize;
}
/******************************************************************************/
BOOL grp_repair(INDEX * FF)	// repairs groups as far as possible

{
	GROUPHANDLE fgp;

	for (fgp = FF->gbase; gisvalid(FF,fgp); fgp = nextgroup(fgp))	// for all valid groups
		;
	return index_sizeforgroups(FF,(char *)fgp-(char *)FF->gbase);
}
/******************************************************************************/
GROUPHANDLE grp_startgroup(INDEX * FF)		/* initializes group */

{
	GROUPHANDLE gh;

	if (gh = calloc(MAXGSIZE,1))	{		/* if can get new one */
		gh->size = sizeof(GROUP);
		gh->indextime = FF->head.createtime;
		gh->limit = GROUPMAXSIZE;		/* max number of records we can start with */
		gh->tstamp = time(NULL);
		gh->sg = FF->head.sortpars;
	}
	return (gh);
}
/******************************************************************************/
void grp_installtemp(INDEX * FF, GROUPHANDLE gh)	/* installs temporary group */

{
	if (FF->lastfile == FF->curfile)	/* make sure no current group */
		FF->curfile = NULL;
	if (FF->lastfile)
		grp_dispose(FF->lastfile);
	FF->lastfile = gh;
}
/******************************************************************************/
BOOL grp_make(INDEX * FF, GROUPHANDLE gh, char *name, short oflag)	// adds group to file

{
	int baseoffset;
	if (gfind(FF, name))	{	/* if can find existing group */
		if (oflag || sendwarning(DUPGROUPWARNING, name))
			gremove(FF,name);	/* remove it */
		else
			return(FALSE);
	}
	baseoffset = FF->head.groupsize;	// remember offset of current end point
	// group is always added to end of mapped region
	if (index_sizeforgroups(FF,FF->head.groupsize+groupsize(gh)))	{	// if can extend to accommodate group
//		strcpy(gh->gname,name);		/* install name */
		memmove(gh->gname,name,strlen(name)+1);	// memmove rather than strcpy, because ptrs could be to same string
		memcpy((char *)FF->gbase+baseoffset,gh,groupsize(gh));	// appended to file
		return(TRUE);
	}
	senderr(GROUPCREATEERR, WARN, name);
	return (FALSE);
}
/******************************************************************************/
BOOL grp_install(INDEX * FF, char *name)	/* opens & installs group  */

{
	GROUPHANDLE gh;
	
	if (gh = grp_open(FF,name))	{	/* if can open it */
		grp_closecurrent(FF);		/* discard any active group */
		FF->curfile = gh;	/* set current file */
		return (FALSE);
	}
	return (TRUE);
}
/******************************************************************************/
void grp_closecurrent(INDEX * FF)		/* closes current group */

{
	if (FF->curfile && FF->curfile != FF->lastfile)	/* if using a group */
		grp_dispose(FF->curfile);	/* get rid of it */
	FF->curfilepos = 0;			/* make sure we invalidate file pos */
	FF->curfile = NULL;
}
/******************************************************************************/
void grp_dispose(GROUPHANDLE gh)		/* discards group  */

{
	free(gh);
}
/******************************************************************************/
RECN grp_getstats(INDEX * FF, GROUPHANDLE gh, COUNTPARAMS * csptr)		/* gets stats on group */

{
	GROUPHANDLE oldcfile;
	RECN oldcfilepos;
	
	memset(csptr,0, sizeof(COUNTPARAMS));
	if (gh->rectot)	{
		oldcfile = FF->curfile;		/* save any active group */
		oldcfilepos = FF->curfilepos;	/* and its current position */
		FF->curfile = gh;			/* set our group in temporarily */
		FF->curfilepos = 0;			/* and zero index */
		csptr->firstrec = gh->recbase[0];
		search_count(FF,csptr,SF_OFF);
		FF->curfile = oldcfile;		/* restore any old group */
		FF->curfilepos = oldcfilepos;	/* and its position */
	}
	return gh->rectot;
}
/******************************************************************************/
RECN grp_buildfromcheck(INDEX * FF, GROUPHANDLE * gh)	// builds group for syntax errors

{
	RECORD * recptr;
	GROUPHANDLE gp = *gh;
	
	gp->rectot = 0;
	gp->gflags = GF_SEARCH;
	
	for (recptr = sort_top(FF); recptr; recptr = sort_skip(FF,recptr,1))	{	/* for all records */
		if (rec_checkfields(FF,recptr))	{	// if errors
			if (gp->rectot < gp->limit || gresize(&gp,GROUPMAXSIZE))
				gp->recbase[gp->rectot++] = recptr->num;	/* write record number */
		}
	}
	*gh = gp;
	return (gp->rectot);
}
#if 1
/******************************************************************************/
RECN grp_buildfromsearch(INDEX * FF, GROUPHANDLE * gh)	/* adds search hits to group file  */

{
	RECORD * recptr;
	char *sptr, tsort;
	short mlength;
	GROUPHANDLE gp = *gh;
//	HCURSOR ocurs;

	gp->rectot = 0;
	gp->gflags = GF_SEARCH;
	tsort = FF->head.sortpars.ison;
	FF->head.sortpars.ison = gp->lg.sortmode;		/* set sort mode as appropriate */
//	ocurs = SetCursor(g_waitcurs);
	if (recptr = search_findfirst(FF, &gp->lg, TRUE, &sptr, &mlength))	{	/* if any hit */
		do {		/* add records */
			gp->recbase[gp->rectot++] = recptr->num;	/* write record number */
		} while ((recptr = search_findfirst(FF, &gp->lg, FALSE, &sptr, &mlength)) && (gp->rectot < gp->limit || gresize(&gp,GROUPMAXSIZE)));	/* while more to come */
	}
//	SetCursor(ocurs);
	search_clearauxbuff(&gp->lg);		/* free any aux buffers */
	FF->head.sortpars.ison = tsort;
	if (FF->curfile)	/* if already in group */
		gp->gflags |= GF_COMBINE;		/* made from more than 1 group */
	gresize(&gp,0);		/*truncate */
	*gh = gp;
	return (gp->rectot);
}
/******************************************************************************/
RECN grp_buildfromrange(INDEX * FF, GROUPHANDLE *gh, RECN first, RECN last, short stype)	/* makes group from selection or numerical range */

{
	RECORD * recptr;
	RECN rnum;
	GROUPHANDLE gp = *gh;

	gp->rectot = 0;
	gp->gflags = stype&(GF_SELECT|GF_RANGE);
	gp->lg.firstr = first;	/* save for any revision */
	gp->lg.lastr = last;
	gp->lg.sortmode = FF->head.sortpars.ison;
	if (stype == GF_SELECT)	{	/* build from current selection (excludes terminal record) */
		for (recptr = rec_getrec(FF,first); recptr && (gp->rectot < gp->limit || gresize(&gp,GROUPMAXSIZE)) && recptr->num != last; recptr = sort_skip(FF,recptr,1))	/* for all in sel range */
			gp->recbase[gp->rectot++] = recptr->num;	/* write record number */
	}
	else {		/* build from inclusive numerical range */
		for (rnum = first; rnum <= last && (recptr = rec_getrec(FF,rnum)) && (gp->rectot < gp->limit || gresize(&gp,GROUPMAXSIZE)); rnum++)	/* for all in range */
			gp->recbase[gp->rectot++] = recptr->num;	/* write record number */
	}
	if (FF->curfile)	/* if already in group */
		gp->gflags |= GF_COMBINE;		/* made from more than 1 group */
	gresize(&gp,0);		/*truncate */
	*gh = gp;
	return (gp->rectot);
}
/******************************************************************************/
void grp_revise(INDEX * FF, GROUPHANDLE *gh)	/* rebuilds group  */

{
	short field;
	GROUPHANDLE gp;
	GROUPHANDLE tcfile;
	
	gp = *gh;
	tcfile = FF->curfile;		/* hold group if we're using one */
	if (!(gp->gflags&GF_COMBINE))	/* if original wasn't made from search through a group */
		FF->curfile = NULL;		/* enable whole index search */
	if (gp->gflags & GF_SEARCH)	{	/* if from search */
		if (!makerange(FF,gp->lg.lflags,gp->lg.range0,gp->lg.range1,&gp->lg.firstr, &gp->lg.lastr))	{	// get revised start and end records
			if (search_setupfind(FF, &gp->lg, &field))		/* set up search parameters */
				grp_buildfromsearch(FF,&gp);
		}
	}
	else	/* from selection or range */
		grp_buildfromrange(FF,&gp,gp->lg.firstr,gp->lg.lastr,gp->gflags);
	gp->tstamp = time(NULL);
	gp->gflags |= GF_REVISED;
	FF->curfile = gp;
	sort_sortgroup(FF);		/* sort and save it */
	FF->curfile = tcfile;	/* restore any active group */
	*gh = gp;		/* set revised handle */
}
#else
/******************************************************************************/
RECN grp_buildfromsearch(INDEX * FF, GROUPHANDLE * gh)	/* adds search hits to group file  */

{
	RECORD * recptr;
	char *sptr, tsort;
	short mlength;
	GROUPHANDLE gp = *gh;
	LISTGROUP alg;			// properly aligned LISTGROUP; make 64 bit compatible with 32 bit
//	HCURSOR ocurs;
	
	gp->rectot = 0;
	gp->gflags = GF_SEARCH;
	tsort = FF->head.sortpars.ison;
	alg = gp->lg;			// load the aligned working copy
	FF->head.sortpars.ison = alg.sortmode;		/* set sort mode as appropriate */
//	ocurs = SetCursor(g_waitcurs);
	if (recptr = search_findfirst(FF, &alg, TRUE, &sptr, &mlength))	{	/* if any hit */
		do {		/* add records */
			gp->recbase[gp->rectot++] = recptr->num;	/* write record number */
		} while ((recptr = search_findfirst(FF, &alg, FALSE, &sptr, &mlength)) && (gp->rectot < gp->limit || gresize(&gp,GROUPMAXSIZE)));	/* while more to come */
	}
//	SetCursor(ocurs);
	search_clearauxbuff(&alg);		/* free any aux buffers */
	gp->lg = alg;		// restore LISTGROUP from aligned working copy
	FF->head.sortpars.ison = tsort;
	if (FF->curfile)	/* if already in group */
		gp->gflags |= GF_COMBINE;		/* made from more than 1 group */
	gresize(&gp,0);		/*truncate */
	*gh = gp;
	return (gp->rectot);
}
/******************************************************************************/
RECN grp_buildfromrange(INDEX * FF, GROUPHANDLE *gh, RECN first, RECN last, short stype)	/* makes group from selection or numerical range */

{
	RECORD * recptr;
	RECN rnum;
	GROUPHANDLE gp = *gh;
	LISTGROUP alg;			// properly aligned LISTGROUP; make 64 bit compatible with 32 bit
	
	gp->rectot = 0;
	gp->gflags = stype&(GF_SELECT|GF_RANGE);
	alg = gp->lg;			// load the aligned working copy
	alg.firstr = first;	/* save for any revision */
	alg.lastr = last;
	alg.sortmode = FF->head.sortpars.ison;
	if (stype == GF_SELECT)	{	/* build from current selection (excludes terminal record) */
		for (recptr = rec_getrec(FF,first); recptr && (gp->rectot < gp->limit || gresize(&gp,GROUPMAXSIZE)) && recptr->num != last; recptr = sort_skip(FF,recptr,1))	/* for all in sel range */
			gp->recbase[gp->rectot++] = recptr->num;	/* write record number */
	}
	else {		/* build from inclusive numerical range */
		for (rnum = first; rnum <= last && (recptr = rec_getrec(FF,rnum)) && (gp->rectot < gp->limit || gresize(&gp,GROUPMAXSIZE)); rnum++)	/* for all in range */
			gp->recbase[gp->rectot++] = recptr->num;	/* write record number */
	}
	gp->lg = alg;		// restore LISTGROUP from aligned working copy
	if (FF->curfile)	/* if already in group */
		gp->gflags |= GF_COMBINE;		/* made from more than 1 group */
	gresize(&gp,0);		/*truncate */
	*gh = gp;
	return (gp->rectot);
}
/******************************************************************************/
void grp_revise(INDEX * FF, GROUPHANDLE *gh)	/* rebuilds group  */

{
	short field;
	GROUPHANDLE gp;
	GROUPHANDLE tcfile;
	LISTGROUP alg;			// properly aligned LISTGROUP; make 64 bit compatible with 32 bit
	
	gp = *gh;
	tcfile = FF->curfile;		/* hold group if we're using one */
	if (!(gp->gflags&GF_COMBINE))	/* if original wasn't made from search through a group */
		FF->curfile = NULL;		/* enable whole index search */
	alg = gp->lg;			// load the aligned working copy
	if (gp->gflags & GF_SEARCH)	{	/* if from search */
		if (!makerange(FF,alg.lflags,alg.range0,alg.range1,&alg.firstr, &alg.lastr))	{	// get revised start and end records
			if (search_setupfind(FF, &alg, &field))		/* set up search parameters */
				grp_buildfromsearch(FF,&gp);
		}
	}
	else	/* from selection or range */
		grp_buildfromrange(FF,&gp,alg.firstr,alg.lastr,gp->gflags);
	gp->lg = alg;		// restore LISTGROUP from aligned working copy
	gp->tstamp = time(NULL);
	gp->gflags |= GF_REVISED;
	FF->curfile = gp;
	sort_sortgroup(FF);		/* sort and save it */
	FF->curfile = tcfile;	/* restore any active group */
	*gh = gp;		/* set revised handle */
}
#endif
/******************************************************************************/
GROUPHANDLE grp_open(INDEX * FF, char *name)	/* opens group  */

{
	GROUPHANDLE fgp, gp;

	gp = NULL;
	if (fgp = gfind(FF, name))	{	/* find existing group */
		if (gp = calloc(groupsize(fgp),1))	{
			memcpy(gp,fgp,groupsize(fgp));
			gp->limit = gp->rectot;		/* for pre 1.0.6 groups */
		}
	}
	return (gp);
}
/******************************************************************************/
short grp_link(INDEX * FF, GROUPHANDLE *gh)	/* add cross-refs to group */

{
	VERIFYGROUP vst;
	unsigned short refcount, grcount, count;
	RECN curtot,temptot;
	RECORD * recptr, *srptr;
	GROUPHANDLE th, gp;
	short tview;
	char tsort;

	gp = *gh;
	memset(&vst,0, sizeof(VERIFYGROUP));
	vst.lowlim = 1;
	vst.locatoronly = FF->head.refpars.clocatoronly;	// set as necess for locator field only
	th = FF->curfile;
	FF->curfile = NULL;
	tview = FF->viewtype;
	FF->viewtype = VIEW_ALL;		/* need this to force search of whole index even if group on display */
	tsort = FF->head.sortpars.ison;
	FF->head.sortpars.ison = TRUE;	/* need sort on, and needs to be alpha */
	if (vst.t1 = calloc(FF->head.indexpars.recsize,1))	{
		for (temptot = curtot = gp->rectot, recptr = sort_top(FF); recptr && (temptot < gp->limit || gresize(&gp,GROUPMAXSIZE)); recptr = sort_skip(FF,recptr,1)) {	   /* for all records */
			if (!recptr->isdel && (refcount = search_verify(FF,recptr->rtext,&vst)))	{	/* if have cross-ref */
				for (count = 0; count < refcount; count++)	{	/* for each ref from record */
					if (vst.cr[count].num)	{			/* if valid target */
						if (srptr = rec_getrec(FF,vst.cr[count].num))	{	/* if can get target */
							if (grp_lookup(FF,gp, srptr->rtext, FALSE))	{	/* if target is in group */
								for (grcount = 0; grcount < curtot; grcount++)	{	/* for all records in group */
									if (gp->recbase[grcount] == recptr->num)		/* if ours already in group */
										goto breakout;
								}
								gp->recbase[temptot++] = recptr->num;	/* write record number */
								break;
							}
						}
					}
				}
			}
			breakout:
				;
		}
		gp->rectot = temptot;	/* (rectot has to stay constant through scan for grp_lookup) */
		free(vst.t1);
	}
	FF->head.sortpars.ison = tsort;
	FF->viewtype = tview;		/* restore original view, etc */
	FF->curfile = th;
	gp->gflags |= GF_LINKED;
	gresize(&gp,0);		/*truncate */
	*gh = gp;
	return (FALSE);
}
/******************************************************************************/
void grp_delete(INDEX * FF, char * name)	/* delete group by name */

{
	gremove(FF,name);	/* remove it */
}
/******************************************************************************/
RECORD * grp_lookup(INDEX * FF,GROUPHANDLE gh, char * string, int subflag)	/* does bsearch for group entry */

{
	short m;
	RECN slimit, sbase;
	char * pptr, *rptr;
	RECORD *curptr, *matchptr;
	
	sbase = 0;
	slimit = gh->rectot-1;
	matchptr = NULL;
	while (curptr = rec_getrec(FF, gh->recbase[sbase+slimit])) {      /* while records to check */
		if (gh->sg.fieldorder[0] == PAGEINDEX)	{	/* if in page order */
		
		/* NB: for some later fix: page ordering functions don't respect group sort params */
			pptr = str_xlast(curptr->rtext);
			if (str_crosscheck(FF,pptr))			/* if a cross ref */
				m = -1;		/* cross ref always follows page ref */
			else {
				rptr = ref_sortfirst(FF,pptr);		/* get ref ptr */
				m = ref_match(FF, string, rptr, gh->sg.partorder, PMSENSE);
			}
		}
		else
			m = col_match(FF, &gh->sg, string, curptr->rtext, MATCH_LOOKUP|MATCH_IGNOREACCENTS|MATCH_IGNORECODES);		/* if new string == old */
		if (!m /* && !sort_isignored(FF, curptr) */)	// if a hit and not ignored
			matchptr = curptr;
		if (!slimit)			/* checked all */
			break;
		if (m <= 0)				/* in part we searched */
			slimit >>= 1;		/* halve the array span */
		else 					/* in half we skipped */
			sbase += slimit;	/* adjust base */
		if (sbase+slimit >= gh->rectot)	/* if next pick would be beyond end */
			break;
	}
	return (matchptr && subflag? search_linsearch(FF,matchptr,string) : matchptr);
}
/******************************************************************************/
static BOOL gresize(GROUPHANDLE *gp,RECN newrecs)	/* changes size or reports error */

{
	GROUPHANDLE tgp = realloc(*gp,groupsize(*gp)+newrecs*sizeof(RECN));
	if (tgp)	{	/* if successful */
		if (newrecs)	/* if adding */
			tgp->limit += newrecs;		/* increase limit */
		else		/* truncating */
			tgp->limit = tgp->rectot;	/* limit is current size */
		*gp = tgp;
		return (TRUE);
	}
	else
		sendinfo(INFO_FULLGROUP);
	return (FALSE);
}
/******************************************************************************/
static GROUPHANDLE gfind(INDEX * FF, char * name)	/* returns pointer to group */

{
	GROUPHANDLE fgp;

	for (fgp = FF->gbase; gisvalid(FF,fgp); fgp = nextgroup(fgp))	{	/* for all groups */
		if (!strcmp(fgp->gname,name))
			return(fgp);
	}
	return (NULL);
}
/******************************************************************************/
static void gremove(INDEX * FF, char * name)	/* removes group from file */

{
	GROUPHANDLE gbase;

	if (gbase = gfind(FF,name))	{
		int gsize = groupsize(gbase);
		char * gend = (char *)gbase+gsize;

		memmove(gbase,gend,FF->head.groupsize-(gend-(char *)FF->gbase));
		index_sizeforgroups(FF,FF->head.groupsize-gsize);
	}
}
/******************************************************************************/
static BOOL gisvalid(INDEX * FF, GROUPHANDLE gh) // checks valid group

{
	if (gh && (char *)gh < (char *)FF->gbase+FF->head.groupsize && gh->size == sizeof(GROUP))
		return TRUE;
	return FALSE;
}
/******************************************************************************/
static short makerange(INDEX * FF, short scope, char * lptr, char * hptr, RECN * first, RECN * last)		/* finds start and stop recs */

{
	RECORD * recptr, *curptr;
	
	*first = 0;			/* default first we'll never start at */
	*last = UINT_MAX;			/* default one we'll never stop at */
	
	if (scope == COMR_RANGE)   {	  /* if setting range */
		if (*lptr)	{			/* if specifying start */
			if (!(*first = com_findrecord(FF,lptr,FALSE,WARN)))	/* bad low limit */
				return (-1);
		}
		if (*hptr)	{		/* want specifying last */
			if (recptr = rec_getrec(FF,com_findrecord(FF,hptr, TRUE,WARN))) 	{	/* if can get last matching record */
				if (curptr = [FF->owner skip:1 from:recptr])	{	/* if can get beyond */
					*last = curptr->num; 	/* set it */
					if (*first && sort_relpos(FF,*first,*last) >= 0)	/* if last not after first */
						return (senderr(RECRANGERR,WARN));
				}
			}
			else
				return (1);		/* bad record spec (message already sent) */
		}
	}
	if (!*first && (recptr = sort_top(FF)))	/* if no first spec, and rec exists */
		*first = recptr->num;   	/* set it */
	return (0);		/* ok */
}

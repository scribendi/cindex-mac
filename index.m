//
//  index.m
//  Cindex
//
//  Created by PL on 1/15/05.
//  Copyright 2005 Indexing Research. All rights reserved.
//

#import "index.h"
#import "records.h"

/*******************************************************************************/
void index_cleartags(INDEX * FF)	// clears tags, etc
{
	RECN n;

	for (n = 1; n <= FF->head.rtot; n++) 	{	/* for all records, fetch in turn */
		RECORD * p = getaddress(FF,n);

		p->isttag = FALSE;	// clear tag
//		p->ismark = FALSE;	// clear mark
	}
}
/*******************************************************************************/
int index_checkintegrity(INDEX * FF, RECN rtot)	// checks integrity of index

{
	RECN n, total;

	total = FF->head.rtot > rtot ? rtot : FF->head.rtot;	// # of records expected in file
	if (FF->head.indexpars.minfields < 2 || FF->head.indexpars.minfields > FF->head.indexpars.maxfields
		|| FF->head.indexpars.maxfields < 2 || FF->head.indexpars.maxfields > FIELDLIM
		|| FF->head.indexpars.recsize > MAXREC)
		return -1;	// fatal error
	for (n = 1; n <= total; n++) 	{	/* for all records, fetch in turn */
		RECORD * p = getaddress(FF,n);
		int index, fcount;
		@try {
			if (p->num != n)
				return 1;	// error
			for (index = 0, fcount = 0; index < FF->head.indexpars.recsize && fcount <= FF->head.indexpars.maxfields; index++)	{
//				if (n == 95 && (!index || !p->rtext[index-1]))
//					NSLog(@"Field %d: %s",fcount,&p->rtext[index]);
				if (iscodechar(p->rtext[index]))	{
					if (index < FF->head.indexpars.recsize-1) {
						if (!p->rtext[index+1] || p->rtext[index+1]== EOCS || (p->rtext[index] == FONTCHR && p->rtext[index+1]&FX_COLOR))	// if bad code or font
							return 1;
						index++;		// skip code
					}
					continue;
				}
				if (p->rtext[index] == '\0')	{
					fcount++;
					continue;
				}
				if (p->rtext[index] == EOCS && index && p->rtext[index-1] == '\0')	// if preceded by field end
					break;
			}
			if (index == FF->head.indexpars.recsize || fcount > FF->head.indexpars.maxfields || fcount < FF->head.indexpars.minfields)
				return 1;
		}
		@catch (NSException * exception) {
			return -1;	// fatal error
		}
		@finally {
		}
	}
	return 0; // OK
}
/*******************************************************************************/
int index_repair(INDEX * FF)	// repairs index

{
	RECN n, markcount;

	markcount = 0;
	for (n = 1; n <= FF->head.rtot; n++) 	{	/* for all records, fetch in turn */
		RECORD * p = getaddress(FF,n);
		int index, fcount, change;
		int strindex[FIELDLIM];

		change = 0;
		strindex[0] = 0;
		@try {
			if (p->num != n)	{
				p->num = n;	// repair number
				change = TRUE;
			}
			for (index = 0, fcount = 0; index < FF->head.indexpars.recsize && fcount <= FF->head.indexpars.maxfields; index++)	{
				if (iscodechar(p->rtext[index]))	{
					if (index < FF->head.indexpars.recsize-1) {
						if (!p->rtext[index+1] || p->rtext[index+1] == EOCS || (p->rtext[index] == FONTCHR && p->rtext[index+1]&FX_COLOR))	{// if bad code or font
							p->rtext[index+1] = FX_FONT;	// font 0 if font; off if style
							change = TRUE;
						}
						index++;		// skip code
					}
					continue;
				}
				if (p->rtext[index] == EOCS)	{	// end
					if (index >= FF->head.indexpars.minfields) {	// if at or above min fields
						if (p->rtext[index-1] != '\0')	{	// if locator is badly terminated
							p->rtext[index-1] = '\0';		// terminate locator
							fcount++;					// count the field
							strindex[fcount] = index;	// note EOCS as base of string
							change = TRUE;
						}
						break;
					}
					else
						p->rtext[index] = '@';		// replace bad EOCS with token
					change = TRUE;
					continue;
				}
				if (p->rtext[index] == '\0')	{
					fcount++;
					strindex[fcount] = index+1;	// save base of string for field at index fcount
					continue;
				}
				if ((unsigned char)p->rtext[index] < SPACE)	{	// if bad char
					p->rtext[index] = '@';
					change = TRUE;
				}
			}
			if (index == FF->head.indexpars.recsize || fcount > FF->head.indexpars.maxfields)	{	// if run out to max record size
				if (fcount > FF->head.indexpars.maxfields)		// if too many fields
					index = strindex[FF->head.indexpars.maxfields];	// index is char beyond end of last legal field
				else if (!p->rtext[--index])	// else  run off end -- if last char is field end
					fcount--;		// will lose a field
				p->rtext[index] = EOCS;	// force EOCS
				if (p->rtext[--index])	{	// if preceding character isn't null
					p->rtext[index] = '\0';	// force it
					fcount++;
					while (fcount > FF->head.indexpars.maxfields && index--)	{	// work towards start of record
						if (p->rtext[index])	{// if not a field break
							p->rtext[index] = '\0';		// make one
							fcount--;
						}
					}
				}
				while (fcount < FF->head.indexpars.minfields && index > 0)	{	// while don't have enough fields
					if (p->rtext[--index] != '\0')		{// if not end of field
						p->rtext[index] = '\0';		// make one
						fcount++;
					}
				}
				change = TRUE;
			}
			else if (fcount < FF->head.indexpars.minfields) {	// too few fields
				int need = FF->head.indexpars.minfields-fcount;
				if (need+index < FF->head.indexpars.recsize) {	// if room to add fields
					while (need--)		// append fields
						p->rtext[index++] = '\0';
					p->rtext[index]	= EOCS;
				}
				else {		// no room; must create new fields from within current space
					while (index-- && need)	{// work towards start of record text
						if (p->rtext[index])	{	// if not a field break
							p->rtext[index] = '\0';		// make one
							need--;
						}
					}
				}
				change = TRUE;
			}
			if (change)	{
				rec_strip(FF,p->rtext);
				p->ismark = TRUE;
				markcount++;
			}
		}
		@catch (NSException * exception) {
			return 0;	// error
		}
		@finally {
		}
	}
	return markcount;	// OK
}
/*******************************************************************************/
BOOL index_setworkingsize(INDEX * FF, RECN extrarecords)	// sets working size with margin

{
	if (FF->mf.readonly)
		extrarecords = 0;
	return index_setsize(FF,FF->head.rtot,FF->head.indexpars.recsize,extrarecords);
}
/******************************************************************************/
BOOL index_setsize(INDEX * FF, RECN total,int recsize, RECN margin)	// sets specified size with margin

{
	size_t oldmapsize = FF->mf.size-FF->head.groupsize;
	size_t mapsize = HEADSIZE+((total+margin)*(RECSIZE+recsize));

	if (oldmapsize > mapsize)	// if shrinking record map
		memmove(FF->mf.base+mapsize,FF->mf.base+oldmapsize,FF->head.groupsize);	// shift groups down
	if (mfile_resize(&FF->mf,mapsize+FF->head.groupsize))	{
		FF->recordlimit = total+margin;
		if (mapsize > oldmapsize)		// if enlarging record map
			memmove(FF->mf.base+mapsize,FF->mf.base+oldmapsize,FF->head.groupsize);	// shift groups up
		FF->gbase = (GROUP *)(FF->mf.base+mapsize);
		return TRUE;
	}
	return FALSE;
}
/******************************************************************************/
BOOL index_sizeforgroups(INDEX * FF, unsigned int groupsize)	// extends group collection

{
	size_t mapsize = HEADSIZE+(FF->recordlimit*(RECSIZE+FF->head.indexpars.recsize));

	if (mfile_resize(&FF->mf,mapsize+groupsize))	{	// extend current size
		FF->gbase = (GROUP *)(FF->mf.base+mapsize);	// base is file size minus new groupsize
		FF->head.groupsize = groupsize;
		return TRUE;
	}
	return FALSE;
}
/*******************************************************************************/
void index_markdirty(INDEX * FF)		// marks index as dirty

{
	if (FF && !FF->head.dirty && !FF->mf.readonly)	{	/* if haven't marked index as dirty */
		FF->head.dirty = TRUE;	/* index is dirty */
		index_writehead(FF);	/* write header marked as dirty */
	}
}
/*******************************************************************************/
BOOL index_writehead(INDEX * FF)		// writes header

{
	memcpy(FF->mf.base,&FF->head,HEADSIZE);	// write header
	return mfile_flush(&FF->mf);	// flush
}
/*******************************************************************************/
BOOL index_flush(INDEX * FF)		/* flushes all records & header */

{	
	if (!FF->readonly)	{		// if not readonly
		time_t curtime = time(NULL);		/* get current time */
		FF->head.elapsed += curtime-FF->lastflush;	 /* add to total time */
		FF->lastflush = curtime;
		if (FF->head.dirty)		{	/* if was dirty */
			FF->head.dirty = FALSE;
			FF->wasdirty = TRUE;
		}
		return (index_writehead(FF));	// write header and flush
	}
	return (TRUE);	// ok
}



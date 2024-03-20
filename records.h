//
//  records.h
//  Cindex
//
//  Created by PL on 1/12/05.
//  Copyright 2005 Indexing Research. All rights reserved.
//

#import "sort.h"
#import "IRIndexDocument.h"

#define getaddress(FF,NN) ((RECORD *)((FF)->mf.base+HEADSIZE+((NN)-1)*(FF)->wholerec))

inline RECN rec_number(RECORD * recptr) { if (recptr) return recptr->num; return 0; }

RECORD * rec_getrec(INDEX * FF, RECN n);	 /* returns pointer to record */
RECN rec_findlastrec(INDEX * FF);	/* finds last record in file */
void rec_stamp(INDEX * FF, RECORD * recptr);   /* stamps record with date, initials, mod */
int rec_writerec(INDEX * FF, RECORD * p);		/* writes record */
RECORD *rec_writenew(INDEX * FF, char * rtext);	 // forms & writes new rec to index
RECORD * rec_makenew(INDEX * FF, char * rtext, RECN num);   /* forms new record */
unsigned short rec_propagate (INDEX * FF, RECORD * recptr, char * origptr, struct numstruct * nptr);		/* propagates changes to identical lower records */
short rec_strip(INDEX * FF, char * pos);	  /* strips empty strings from record; to min */
void rec_pad(INDEX *FF, char *string);	  /* expands xstring to min fields */
short rec_compress(INDEX * FF, RECORD * curptr, char jchar);	  /* compresses excess fields to maxfields, by combining from lowest */
char * rec_uniquelevel(INDEX * FF, RECORD * recptr, short *hlevel, short * sprlevel, short *hidelevel, short * clevel);   /* finds level at which heading is unique */
void rec_getprevnext(INDEX * FF, RECORD * recptr, RECN * prevptr, RECN * nextptr, RECORD * (*skip)(INDEX *, RECORD *, short));   /* finds next & prev records */
int rec_checkfields(INDEX * FF, RECORD * recptr);	// checks syntax of fields

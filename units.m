//
//  units.m
//  Cindex
//
//  Created by PL on 1/10/05.
//  Copyright 2005 Indexing Research. All rights reserved.
//

#import "units.h"

static float PIXELSTOEMS;

/*******************************************************************************/
short env_tobase(short unit, float eval)	/* converts from expression to base */

{
	float tval = 0;
	
	switch (unit)	{
		case U_INCH:
			tval = eval*PIXELSTOINCH;	/* inches to pixels */
			break;
		case U_CM:
			tval = eval*PIXELSTOMM;
			break;
		case U_POINT:
			tval = eval*PIXELSTOPOINT;
			break;
		case U_PICA:
			tval = eval*PIXELSTOPICA;
			break;
		case U_EMS:
			tval = eval*PIXELSTOEMS;
			break;
	}
#if 0
	if ((short)(tval+0.5) > (short)tval)	/* if nearer higher value */
		tval++;
#endif
	return (tval);
}
/*******************************************************************************/
float env_toexpress(short unit, short bval)	/* converts from base to unit of expression */

{
//	NSLog(@"(%d)toexpress: %f, %f, %f, %f,%f",bval, bval/PIXELSTOINCH, bval/PIXELSTOMM, bval/PIXELSTOPOINT,bval/PIXELSTOPICA, bval/PIXELSTOEMS);
	switch (unit)	{
		case U_INCH:
			return ((float)bval/PIXELSTOINCH);	/* pixels to inches */
		case U_CM:
			return ((float)bval/PIXELSTOMM);
		case U_POINT:
			return ((float)bval/PIXELSTOPOINT);
		case U_PICA:
			return ((float)bval/PIXELSTOPICA);
		case U_EMS:
			return ((float)bval/PIXELSTOEMS);
	}
	return (0);
}
/*******************************************************************************/
void env_setemspace(float points)	// sets # points in em space

{
	PIXELSTOEMS = points/PIXELSTOPOINT;
}
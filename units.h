//
//  units.h
//  Cindex
//
//  Created by PL on 1/10/05.
//  Copyright 2005 Indexing Research. All rights reserved.
//

#define	PIXELSTOPOINT 1.
#define	PIXELSTOPICA (PIXELSTOPOINT*12.)
#define	PIXELSTOINCH 72.
#define	PIXELSTOMM (PIXELSTOINCH/25.4)

short env_tobase(short unit, float eval);	/* converts from expression to base */
float env_toexpress(short unit, short bval);	/* converts from base to unit of expression */
void env_setemspace(float points);	// sets # points in em space

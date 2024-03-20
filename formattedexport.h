//
//  formattedexport.h
//  Cindex
//
//  Created by Peter Lennie on 1/29/11.
//  Copyright 2011 Peter Lennie. All rights reserved.
//

#import "indexdocument.h"
#import "export.h"

#define kStyleUseExplicitNames @"useExplicitNames"
#define kStyleStyleNames @"styleNames"

NSData * formexport_write(INDEX * FF, EXPORTPARAMS * exp, FCONTROLX * xptr);	/* opens & writes formatted export file */
void formexport_buildentry(INDEX * FF, RECORD * recptr);	/* builds entry of right type; appends to data */
void formexport_makefield(FCONTROLX * xptr, INDEX * FF, char * source);     // formats field to output for embedding
void formexport_gettypeindents(INDEX * FF, int level, int tabmode, int scale, int * firstindent, int * baseindent, char * tabcontrol, char * tabstops, char * tabset);	/* gets typesetting indents, appropriately scaled */
void formexport_stylenames(FCONTROLX * xptr, INDEX * FF);	// returns names to use for styles

//
//  swap.h
//  Cindex
//
//  Created by Peter Lennie on 5/30/08.
//  Copyright 2008 Indexing Research. All rights reserved.
//

#import "indexdocument.h"

void swap_Header(HEAD * hp);	// swaps bytes as necessary for host
void swap_FormatParams(FORMATPARAMS *fg);		// swaps bytes
void swap_SortParams(SORTPARAMS *sp);		// swaps bytes
void swap_SearchParams(LISTGROUP *lg);		// swaps bytes
void swap_Records(INDEX * FF); // swaps bytes as necessary for host
void swap_StyleSheet(STYLESHEET * ssp); // swaps stylesheet as necessary for host
void swap_Groups(INDEX * FF); // swaps groups as necessary for host
void swap_Group(GROUP * gptr);	// swaps group as necessary for host

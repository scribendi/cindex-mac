/*
 *  hspelladditions.cpp
 *  Cindex
 *
 *  Created by Peter Lennie on 1/6/11.
 *  Copyright 2011 Peter Lennie. All rights reserved.
 *
 */

#import "hunspell.hxx"
#import "hunspell.h"
#import "hspelladditions.h"

int Hunspell_add_dic(Hunhandle *hh,const char * dpath, const char * key) {
	return ((Hunspell *)hh)->add_dic(dpath, key);
}
int Hunspell_spell_extended(Hunhandle *hh, const char * word, int * info, char ** root) {
	return ((Hunspell *)hh)->spell(word, info, root);
}

/*
 *  hspelladditions.h
 *  Cindex
 *
 *  Created by Peter Lennie on 1/6/11.
 *  Copyright 2011 Peter Lennie. All rights reserved.
 *
 */
#define  SPELL_COMPOUND  (1 << 0)
#define  SPELL_FORBIDDEN (1 << 1)
#define  SPELL_ALLCAP    (1 << 2)
#define  SPELL_NOCAP     (1 << 3)
#define  SPELL_INITCAP   (1 << 4)


#ifdef __cplusplus
extern "C" {
#endif
int Hunspell_add_dic(Hunhandle *hh,const char * dpath, const char * key);
int Hunspell_spell_extended(Hunhandle *hh, const char * word, int * info, char ** root);

#ifdef __cplusplus
}
#endif


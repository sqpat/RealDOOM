//
// Copyright (C) 1993-1996 Id Software, Inc.
// Copyright (C) 2016-2017 Alexey Khokholov (Nuke.YKT)
//
// This program is free software; you can redistribute it and/or
// modify it under the terms of the GNU General Public License
// as published by the Free Software Foundation; either version 2
// of the License, or (at your option) any later version.
//
// This program is distributed in the hope that it will be useful,
// but WITHOUT ANY WARRANTY; without even the implied warranty of
// MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
// GNU General Public License for more details.
//
// DESCRIPTION:
//	Created by the sound utility written by Dave Taylor.
//	Kept as a sample, DOOM2  sounds. Frozen.
//

#ifndef __SOUNDS__
#define __SOUNDS__

#include "doomtype.h"

//
// SoundFX struct.
//


// typedef struct sfxinfo_struct	sfxinfo_t;
// struct sfxinfo_struct {
    // up to 6-character name
    //int8_t*	name;

    // Sfx singularity (only one at a time)
    // boolean		singularity;

    // Sfx priority
    // uint8_t		priority;

    // sound data
    //void __far*	data;

    // this is checked every second to see if sound
    // can be thrown out (if 0, then decrement, if -1,
    // then throw out, if > 0, then it is in use)
    // note - we dont use this anymore and just do LRU and in use in the sfx cache.
    //int8_t		usefulness;

    // lump number of sfx
    // only for PCM. put it in another struct specific to that driver.
    //int16_t		lumpnum;		
// };




//
// MusicInfo struct.
//
// typedef struct {
    // up to 6-character name
    // int8_t*	name;
        // 
// } musicinfo_t;




//
// Identifiers for all music in game.
//

#define mus_None    0 
#define mus_e1m1    1 
#define mus_e1m2    2 
#define mus_e1m3    3 
#define mus_e1m4    4 
#define mus_e1m5    5 
#define mus_e1m6    6 
#define mus_e1m7    7 
#define mus_e1m8    8 
#define mus_e1m9    9 
#define mus_e2m1    10
#define mus_e2m2    11
#define mus_e2m3    12
#define mus_e2m4    13
#define mus_e2m5    14
#define mus_e2m6    15
#define mus_e2m7    16
#define mus_e2m8    17
#define mus_e2m9    18
#define mus_e3m1    19
#define mus_e3m2    20
#define mus_e3m3    21
#define mus_e3m4    22
#define mus_e3m5    23
#define mus_e3m6    24
#define mus_e3m7    25
#define mus_e3m8    26
#define mus_e3m9    27
#define mus_inter   28
#define mus_intro   29
#define mus_bunny   30
#define mus_victor  31
#define mus_introa  32
#define mus_runnin  33
#define mus_stalks  34
#define mus_countd  35
#define mus_betwee  36
#define mus_doom    37
#define mus_the_da  38
#define mus_shawn   39
#define mus_ddtblu  40
#define mus_in_cit  41
#define mus_dead    42
#define mus_stlks2  43
#define mus_theda2  44
#define mus_doom2   45
#define mus_ddtbl2  46
#define mus_runni2  47
#define mus_dead2   48
#define mus_stlks3  49
#define mus_romero  50
#define mus_shawn2  51
#define mus_messag  52
#define mus_count2  53
#define mus_ddtbl3  54
#define mus_ampie   55
#define mus_theda3  56
#define mus_adrian  57
#define mus_messg2  58
#define mus_romer2  59
#define mus_tense   60
#define mus_shawn3  61
#define mus_openin  62
#define mus_evil    63
#define mus_ultima  64
#define mus_read_m  65
#define mus_dm2ttl  66
#define mus_dm2int  67
#define NUMMUSIC    68
	
typedef uint8_t  musicenum_t;


//
// Identifiers for all sfx in game.
//

#define sfx_None    0  
#define sfx_pistol  1  
#define sfx_shotgn  2  
#define sfx_sgcock  3  
#define sfx_dshtgn  4  
#define sfx_dbopn   5  
#define sfx_dbcls   6  
#define sfx_dbload  7  
#define sfx_plasma  8  
#define sfx_bfg     9  
#define sfx_sawup   10 
#define sfx_sawidl  11 
#define sfx_sawful  12 
#define sfx_sawhit  13 
#define sfx_rlaunc  14 
#define sfx_rxplod  15 
#define sfx_firsht  16 
#define sfx_firxpl  17 
#define sfx_pstart  18 
#define sfx_pstop   19 
#define sfx_doropn  20 
#define sfx_dorcls  21 
#define sfx_stnmov  22 
#define sfx_swtchn  23 
#define sfx_swtchx  24 
#define sfx_plpain  25 
#define sfx_dmpain  26 
#define sfx_popain  27 
#define sfx_vipain  28 
#define sfx_mnpain  29 
#define sfx_pepain  30 
#define sfx_slop    31 
#define sfx_itemup  32 
#define sfx_wpnup   33 
#define sfx_oof     34 
#define sfx_telept  35 
#define sfx_posit1  36 
#define sfx_posit2  37 
#define sfx_posit3  38 
#define sfx_bgsit1  39 
#define sfx_bgsit2  40 
#define sfx_sgtsit  41 
#define sfx_cacsit  42 
#define sfx_brssit  43 
#define sfx_cybsit  44 
#define sfx_spisit  45 
#define sfx_bspsit  46 
#define sfx_kntsit  47 
#define sfx_vilsit  48 
#define sfx_mansit  49 
#define sfx_pesit   50 
#define sfx_sklatk  51 
#define sfx_sgtatk  52 
#define sfx_skepch  53 
#define sfx_vilatk  54 
#define sfx_claw    55 
#define sfx_skeswg  56 
#define sfx_pldeth  57 
#define sfx_pdiehi  58 
#define sfx_podth1  59 
#define sfx_podth2  60 
#define sfx_podth3  61 
#define sfx_bgdth1  62 
#define sfx_bgdth2  63 
#define sfx_sgtdth  64 
#define sfx_cacdth  65 
#define sfx_skldth  66 
#define sfx_brsdth  67 
#define sfx_cybdth  68 
#define sfx_spidth  69 
#define sfx_bspdth  70 
#define sfx_vildth  71 
#define sfx_kntdth  72 
#define sfx_pedth   73 
#define sfx_skedth  74 
#define sfx_posact  75 
#define sfx_bgact   76 
#define sfx_dmact   77 
#define sfx_bspact  78 
#define sfx_bspwlk  79 
#define sfx_vilact  80 
#define sfx_noway   81 
#define sfx_barexp  82 
#define sfx_punch   83 
#define sfx_hoof    84 
#define sfx_metal   85 
#define sfx_chgun   86 
#define sfx_tink    87 
#define sfx_bdopn   88 
#define sfx_bdcls   89 
#define sfx_itmbk   90 
#define sfx_flame   91 
#define sfx_flamst  92 
#define sfx_getpow  93 
#define sfx_bospit  94 
#define sfx_boscub  95 
#define sfx_bossit  96 
#define sfx_bospn   97 
#define sfx_bosdth  98 
#define sfx_manatk  99 
#define sfx_mandth  100
#define sfx_sssit   101
#define sfx_ssdth   102
#define sfx_keenpn  103
#define sfx_keendt  104
#define sfx_skeact  105
#define sfx_skesit  106
#define sfx_skeatk  107
#define sfx_radio   108
#define NUMSFX      109
//#define NUMSFX      1

typedef uint8_t sfxenum_t;

#endif

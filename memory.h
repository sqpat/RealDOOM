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
//  hardcoded memory locations
//

#include "r_data.h"

#ifndef __MEMORY_H__
#define __MEMORY_H__

/*
 LAYOUT OF FILE
  1. Upper Memory Allocations
  2. Lower Memory Allocations
  3. Physics allocations
  4. Intermission allocations
  5. FWipe Allocations


  6. Render Allocations


*/

// round up a segment if necessary. convert size to segments
#define MAKE_FULL_SEGMENT(a, b)  ((int32_t)a + ((((int32_t)b + 0x0F) >> 4) << 16))

// ALLOCATION DEFINITIONS: UPPER MEMORY

// 0xE000 Block

// may swap with EMS/0xD000 ?
#define uppermemoryblock    0xE0000000

#define size_sectors            (MAX_SECTORS_SIZE)
#define size_vertexes           (MAX_VERTEXES_SIZE)
#define size_sides              (MAX_SIDES_SIZE)
#define size_lines              (MAX_LINES_SIZE)
#define size_seenlines          (MAX_SEENLINES_SIZE)
#define size_subsectors         (MAX_SUBSECTORS_SIZE)
#define size_nodes              (MAX_NODES_SIZE)
#define size_segs               (MAX_SEGS_SIZE)




#define sectors           ((sector_t __far*)    MAKE_FULL_SEGMENT(uppermemoryblock , 0))
#define vertexes          ((vertex_t __far*)    MAKE_FULL_SEGMENT(sectors          , size_sectors))
#define sides             ((side_t __far*)      MAKE_FULL_SEGMENT(vertexes         , size_vertexes))
#define lines             ((line_t __far*)      MAKE_FULL_SEGMENT(sides            , size_sides))
#define seenlines         ((uint8_t __far*)     MAKE_FULL_SEGMENT(lines            , size_lines))
#define subsectors        ((subsector_t __far*) MAKE_FULL_SEGMENT(seenlines        , size_seenlines))
#define nodes             ((node_t __far*)      MAKE_FULL_SEGMENT(subsectors       , size_subsectors))
#define segs              ((seg_t __far*)       MAKE_FULL_SEGMENT(nodes            , size_nodes))

//0xE000
/*
size_vertexes             E000:0000
size_sectors              E172:0000
size_sides                E309:0000
size_lines                E817:0000
size_seenlines            EA3F:0000
size_subsectors           EA4D:0000
size_nodes                EB5F:0000
size_segs                 EDEF:0000
[empty]                   EFFF:0000


// 16-32 bytes free?
            
//



*/


// 0xB000 BLOCK



#define B000BlockOffset 0x14B0
#define B000Block 0xB14B0000


//#define SIZE_D_SETUP            0x122A
 


// 2a6c

// 0xCC00 BLOCK
// going to leave c800 free for xt-ide, etc bios

#define CC00Block 0xC000C000

/*

CC00 block (16k)

colormaps          CC00:0000
scalelightfixed    CE16:0000
scalelight         CE16:0000
[empty]            CE76:0000

// 10080 used so far

*/

/*
#define colormapssegment  0xCC00

#define size_colormapbytes                ((33 * 256)                      + 0)
#define size_scalelightfixed              (sizeof(uint16_t) * (MAXLIGHTSCALE))
#define size_scalelight                   (sizeof(uint16_t) * (LIGHTLEVELS * MAXLIGHTSCALE))


#define colormaps                   ((lighttable_t  __far*) MAKE_FULL_SEGMENT(0xCC000000      , 0))
#define colormapbytes               ((byte __far*)          MAKE_FULL_SEGMENT(0xCC000000      , 0))
#define scalelightfixed             ((uint16_t __far*)      MAKE_FULL_SEGMENT(colormaps       , size_colormapbytes))
#define scalelight                  ((uint16_t __far*)      MAKE_FULL_SEGMENT(scalelightfixed , size_scalelightfixed))
*/
// 1632 bytes of scalelight to move


 // ALLOCATION DEFINITIONS: LOWER MEMORY BLOCKS 
 // still far memory but 'common' to all tasks because its outside of paginated area


// size_texturecolumnlumps_bytes

// 1264u doom2
// 402 shareware

// size_texturecolumnofs_bytes
// 80480  doom2 
// 21552u shareware

// size_texturedefs_bytes
// 3767u shareware
// 8756u doom2


#define size_finesine            (10240u * sizeof(int32_t))
#define size_finetangent         (2048u * sizeof(int32_t))
#define size_states              (sizeof(state_t) * NUMSTATES)
#define size_events              (sizeof(event_t) * MAXEVENTS)
#define size_flattranslation     (MAX_FLATS * sizeof(uint8_t))
#define size_texturetranslation  (MAX_TEXTURES * sizeof(uint16_t))
#define size_textureheights      (MAX_TEXTURES * sizeof(uint8_t))

#define size_spritecache_nodes   sizeof(cache_node_t) * (NUM_SPRITE_CACHE_PAGES)
#define size_flatcache_nodes     sizeof(cache_node_t) * (NUM_FLAT_CACHE_PAGES)
#define size_patchcache_nodes    sizeof(cache_node_t) * (NUM_PATCH_CACHE_PAGES)
#define size_texturecache_nodes  sizeof(cache_node_t) * (NUM_TEXTURE_PAGES)






#define size_tantoangle    size_finetangent +  2049u * sizeof(int32_t)

// 

//#define baselowermemoryaddresssegment 0x3007
//#define baselowermemoryaddress (0x30070000)
#define baselowermemoryaddresssegment 0x31F0
#define baselowermemoryaddress (0x31F00000)


#define finesine           ((int32_t __far*)  MAKE_FULL_SEGMENT(baselowermemoryaddress, 0))  // 10240
#define finecosine         ((int32_t __far*)  (baselowermemoryaddress + 0x2000))  // 10240
#define finetangentinner   ((int32_t __far*)  MAKE_FULL_SEGMENT(finesine, size_finesine))
#define states             ((state_t __far*)  MAKE_FULL_SEGMENT(finetangentinner, size_finetangent))
#define events             ((event_t __far*)  MAKE_FULL_SEGMENT(states, size_states))
#define flattranslation    ((uint8_t __far*)  MAKE_FULL_SEGMENT(events, size_events))
#define texturetranslation ((uint16_t __far*) MAKE_FULL_SEGMENT(flattranslation, size_flattranslation))
#define textureheights     ((uint8_t __far*)  MAKE_FULL_SEGMENT(texturetranslation, size_texturetranslation))
#define spritecache_nodes  ((cache_node_t __far*)    MAKE_FULL_SEGMENT(textureheights , size_textureheights))
#define flatcache_nodes    ((cache_node_t __far*)    (((int32_t)spritecache_nodes)+ size_spritecache_nodes))
#define patchcache_nodes   ((cache_node_t __far*)    (((int32_t)flatcache_nodes)  + size_flatcache_nodes))
#define texturecache_nodes ((cache_node_t __far*)    (((int32_t)patchcache_nodes) + size_patchcache_nodes))
//MAKE_FULL_SEGMENT(spritecache_nodes , (((int32_t)texturecache_nodes) & 0xFFFF)+ size_texturecache_nodes))

#define baselowermemoryaddresssegment 0x31F0
#define baselowermemoryaddress (0x31F00000)



// finesine             31F0:0000
// finecosine           31F0:2000
// finetangentinner     3BF0:0000
// states               3DF0:0000
// events               3F5B:0000
// flattranslation      3F8F:0000
// texturetranslation   3F99:0000
// textureheights       3FCF:0000
// spritecache_nodes    3FEA:0000
// flatcache_nodes      3FEA:003C
// patchcache_nodes     3FEA:004E
// texturecache_nodes   3FEA:007E


// [done]               3007:FF1E
//                        0x3FF1E
// 226 bytes to 0x4000







// ALLOCATION DEFINITIONS: PHYSICS


// 0x9000 BLOCK PHYSICS

// note: 0x9400-0x9FFF is for lumpinfo...

#define size_segs_physics     (MAX_SEGS_PHYSICS_SIZE)
#define size_diskgraphicbytes (392)
#define segs_physics          ((seg_physics_t __far*)    (0x90000000))
#define diskgraphicbytes      ((byte __far*) (MAKE_FULL_SEGMENT(segs_physics, size_segs_physics)))

// 0x92D90000
#define PSightFuncLoadAddr      ((byte __far*) (MAKE_FULL_SEGMENT(diskgraphicbytes, size_diskgraphicbytes)))
#define P_CheckSightAddr        ((boolean (__far *)(mobj_t __far* ,mobj_t __far* ,mobj_pos_t __far* ,mobj_pos_t __far* ))  (PSightFuncLoadAddr))
#define SIZE_PSight             0x0A70

// end at 0x9380

 // or 9380:0000
#define InfoFuncLoadAddr      ((byte __far *)  (0x93800000))
// note: entry point to the function is not necessarily the first byte of the compiled binary.
#define getPainChanceAddr     ((int16_t    (__far *)(uint8_t))  (InfoFuncLoadAddr + 0x0034))
#define getRaiseStateAddr     ((statenum_t (__far *)(uint8_t))  (InfoFuncLoadAddr + 0x00B2))
#define getXDeathStateAddr    ((statenum_t (__far *)(uint8_t))  (InfoFuncLoadAddr + 0x010A))
#define getMeleeStateAddr     ((statenum_t (__far *)(uint8_t))  (InfoFuncLoadAddr + 0x015A))
#define getMobjMassAddr       ((int32_t    (__far *)(uint8_t))  (InfoFuncLoadAddr + 0x01B8))
#define getActiveSoundAddr    ((sfxenum_t  (__far *)(uint8_t))  (InfoFuncLoadAddr + 0x0222))
#define getPainSoundAddr      ((sfxenum_t  (__far *)(uint8_t))  (InfoFuncLoadAddr + 0x0284))
#define getAttackSoundAddr    ((sfxenum_t  (__far *)(uint8_t))  (InfoFuncLoadAddr + 0x02B8))
#define getDamageAddr         ((uint8_t    (__far *)(uint8_t))  (InfoFuncLoadAddr + 0x02DA))
#define getSeeStateAddr       ((statenum_t (__far *)(uint8_t))  (InfoFuncLoadAddr + 0x0350))
#define getMissileStateAddr   ((statenum_t (__far *)(uint8_t))  (InfoFuncLoadAddr + 0x03F4))
#define getDeathStateAddr     ((statenum_t (__far *)(uint8_t))  (InfoFuncLoadAddr + 0x04A8))
#define getPainStateAddr      ((statenum_t (__far *)(uint8_t))  (InfoFuncLoadAddr + 0x0586))
#define getSpawnHealthAddr    ((int16_t    (__far *)(uint8_t))  (InfoFuncLoadAddr + 0x063C))

#define SIZE_D_INFO            0x069C
// 0x93E9




// segs_physics   9000:0000
// [empty]        9000:2BFC


/*
#define getPainChance(a)      ((getPainChanceAddr)(a) )
#define getRaiseState(a)      ((getRaiseStateAddr)(a) )
#define getXDeathState(a)     ((getXDeathStateAddr)(a) )
#define getMeleeState(a)      ((getMeleeStateAddr)(a) )
#define getMobjMass(a)        ((getMobjMassAddr)(a) )
#define getActiveSound(a)     ((getActiveSoundAddr)(a) )
#define getPainSound(a)       ((getPainSoundAddr)(a) )
#define getAttackSound(a)     ((getAttackSoundAddr)(a) )
#define getDamage(a)          ((getDamageAddr)(a) )
#define getSeeState(a)        ((getSeeStateAddr)(a) )
#define getMissileState(a)    ((getMissileStateAddr)(a) )
#define getDeathState(a)      ((getDeathStateAddr)(a) )
#define getPainState(a)       ((getPainStateAddr)(a) )
#define getSpawnHealth(a)     ((getSpawnHealthAddr)(a) )
*/

/*

92C0:0034      getPainChance2_
92C0:00b2      getRaiseState_
92C0:010a      getXDeathState_
92C0:015a      getMeleeState_
92C0:01b8      getMobjMass_
92C0:0222      getActiveSound_
92C0:0284      getPainSound_
92C0:02b8      getAttackSound_
92C0:02da      getDamage_
92C0:0350      getSeeState_
92C0:03f4      getMissileState_
92C0:04a8      getDeathState_
92C0:0586      getPainState_
92C0:063c      getSpawnHealth_
92C0:069c*     [empty] ??
*/
// 0x9323C done
// 0x9324  empty


// B14B0 + FE0

 


#define PSetupFuncLoadAddr      ((byte __far *)  (0xB14B0000))
#define PSetupFuncFromAddr      ((byte __far *) ((int32_t)PSetupEndFunc &0xFFFF0000))
//#define SIZE_PSetup             ((int16_t)(((int32_t)PSetupEndFunc) & 0xFFFF))
#define SIZE_PSetup             0xFE0

// 4064
//#define SIZE_PSetup             0xFE0
#define P_SetupLevelAddr        ((void     (__far *)(int8_t, int8_t, skill_t)) (0xB14B0000))

 

// 3428 bytes free

// 0x4000 BLOCK PHYSICS



#define NUMMOBJTYPES 137

#define MAXEVENTS           64
#define MAXINTERCEPTS       128

#define size_thinkerlist         (sizeof(thinker_t) * MAX_THINKERS)
#define size_linebuffer          (MAX_LINEBUFFER_SIZE)
#define size_sectors_physics     (MAX_SECTORS_PHYSICS_SIZE)
#define size_mobjinfo            (sizeof(mobjinfo_t) * NUMMOBJTYPES)
#define size_intercepts          (sizeof(intercept_t) * MAXINTERCEPTS)
#define size_ammnumpatchbytes    (524)
#define size_ammnumpatchoffsets  ((sizeof(uint16_t) * 10))
#define size_doomednum           ((sizeof(int16_t) * NUMMOBJTYPES))
#define size_linespeciallist     ((sizeof(int16_t) * MAXLINEANIMS))

#define thinkerlist        ((thinker_t __far*)          MAKE_FULL_SEGMENT(0x40000000, 0))
#define mobjinfo           ((mobjinfo_t __far *)        MAKE_FULL_SEGMENT(thinkerlist, size_thinkerlist))
#define linebuffer         ((int16_t __far*)            MAKE_FULL_SEGMENT(mobjinfo, size_mobjinfo ))
#define sectors_physics    ((sector_physics_t __far* )  MAKE_FULL_SEGMENT(linebuffer, size_linebuffer ))
#define intercepts         ((intercept_t __far*)        MAKE_FULL_SEGMENT(sectors_physics, size_sectors_physics ))
#define ammnumpatchbytes   ((byte __far *)              MAKE_FULL_SEGMENT(intercepts, size_intercepts ))
#define ammnumpatchoffsets ((uint16_t __far*)           (((int32_t)ammnumpatchbytes) + 0x020C))
#define doomednum          ((int16_t __far*)            MAKE_FULL_SEGMENT(ammnumpatchbytes, (size_ammnumpatchbytes+size_ammnumpatchoffsets )))
#define linespeciallist    ((int16_t __far*)            MAKE_FULL_SEGMENT(doomednum, size_doomednum ))
  
 



// 4000:0000  thinkerlist
// 493B:0000  mobjinfo
// 499A:0000  linebuffer
// 4AD8:0000  sectors_physics
// 4CA1:0000  intercepts
// 4CD9:0000  ammnumpatchbytes
// 4CD9:020C  ammnumpatchoffsets
// 4CFB:0000  doomednum
// 4D0D:0000  linespeciallist
// 4CFF:03B1  [empty]


// 4000:0000  thinkerlist
// 4000:93A8  linebuffer
// 4000:A784  sectors_physics
// 4000:C2B4  mobjinfo
// 4000:C897  intercepts
// 4000:CC17  ammnumpatchbytes
// 4000:CE23  ammnumpatchoffsets
// 4000:CE37    doomednum
// 4000:CF49  linespeciallist
// 4000:CFC9  [empty]

// over 8k bytes free?

// PHYSICS 0x6000 - 0x7FFF DATA
// note: strings in 0x6000-6400 region

//0x8000 BLOCK PHYSICS


#define screen0 ((byte __far*) 0x80000000)
#define size_screen0        (64000u)
#define size_gammatable     (size_screen0     + 256 * 5)
#define size_menuoffsets    (size_gammatable  + (sizeof(uint16_t) * NUM_MENU_ITEMS))

#define gammatable          ((byte __far*)      (0x8FA00000 ))
#define menuoffsets         ((uint16_t __far*)  (0x8FF00000 ))

/*

this area used in many tasks including physics but not including render

8000:0000  screen0
8000:FA00  gammatable
8000:FF00  lnodex
8000:FF36  lnodey
8000:FF6C  [empty]


//
*/

//0x7000 BLOCK PHYSICS

#define size_lines_physics    (MAX_LINES_PHYSICS_SIZE)
#define size_blockmaplump     ( MAX_BLOCKMAP_LUMPSIZE)

//3f8a, runs up close to 6800 which has mobjposlist, etc


#define lines_physics       ((line_physics_t __far*)  MAKE_FULL_SEGMENT(0x70000000, 0))
#define blockmaplump        ((int16_t __far*)         MAKE_FULL_SEGMENT(lines_physics, size_lines_physics))
#define blockmaplump_plus4  ((int16_t __far*)        (((int32_t)blockmaplump) + 0x08))

/*
lines_physics       7000:0000
blockmaplump        76E4:0000
blockmaplump_plus4  76E4:0008
[empty]             7000:D736
 10442 bytes free!
*/



// 0x6800 BLOCK PHYSICS

// begin stuff that is paged out in sprite code
// this is used boht in physics and part of render code


#define size_mobjposlist       (MAX_THINKERS * sizeof(mobj_pos_t))
#define size_xtoviewangle      (sizeof(fineangle_t) * (SCREENWIDTH + 1))
#define size_scantokey         128
#define size_rndtable          256
#define size_colormaps         ((33 * 256)                      + 0)
#define size_scalelightfixed   (sizeof(uint16_t) * (MAXLIGHTSCALE))
#define size_scalelight        (sizeof(uint16_t) * (LIGHTLEVELS * MAXLIGHTSCALE))


#define mobjposlist           ((mobj_pos_t __far*)     MAKE_FULL_SEGMENT(0x68000000, 0))
#define xtoviewangle          ((fineangle_t __far*)    MAKE_FULL_SEGMENT(mobjposlist, size_mobjposlist))
#define scantokey             ((byte __far*)           MAKE_FULL_SEGMENT(xtoviewangle, size_xtoviewangle))
#define rndtable              ((uint8_t __far*)        MAKE_FULL_SEGMENT(scantokey, size_scantokey))



#define colormaps             ((lighttable_t  __far*) MAKE_FULL_SEGMENT(rndtable        , size_rndtable))
#define scalelightfixed       ((uint16_t __far*)      MAKE_FULL_SEGMENT(colormaps       , size_colormaps))
#define scalelight            ((uint16_t __far*)      MAKE_FULL_SEGMENT(scalelightfixed , size_scalelightfixed))

//6D2D
#define colormapssegment      ((uint16_t) ((int32_t)colormaps >> 16))

// used in sprite render, this has been remapped to 8400 page
// 852D
#define colormapssegment_high  ((uint16_t)             (colormapssegment           - 0x6C00 + 0x8C00))
#define colormaps_high         ((lighttable_t  __far*) (((int32_t)colormaps)       - 0x6C000000 + 0x8C000000))
#define scalelightfixed_high   ((uint16_t __far*)      (((int32_t)scalelightfixed) - 0x6C000000 + 0x8C000000))
#define scalelight_high        ((uint16_t __far*)      (((int32_t)scalelight)      - 0x6C000000 + 0x8C000000))
//#define colormapssegment_high  0xCC00
//#define colormaps_high         ((lighttable_t  __far*) (0xCC000000))



// 11568 free

// 6080 bytes of plane only...
// can it fit with skytex?

// planes change the 6800 page and remove 

/*
// todo reverse order of colormaps and mobjpos list? 

//? draw code under colormaps in 6800 segment during drawcol?
mobjposlist     6800:0000
xtoviewangle    6CEC:0000
scantokey       6D15:0000
rndtable        6D1D:0000
colormaps       6D2D:0000
scalelightfixed 6F3D:0000
scalelight      6F43:0000
[empty]         6FA3:0000





1488 bytes free if colormaps etc here otherwise 11568

*/

 

//6800:6a82

//1748:6ef4 

//4284 bytes or 0x10BC



 //0x6400 BLOCK PHYSICS
#define size_blocklinks       (0 + MAX_BLOCKLINKS_SIZE)
#define size_nightmarespawns  (size_blocklinks    + NIGHTMARE_SPAWN_SIZE)

#define blocklinks          ((THINKERREF __far*)    MAKE_FULL_SEGMENT(0x64000000, 0))
#define nightmarespawns     ((mapthing_t __far *)   MAKE_FULL_SEGMENT(blocklinks, size_blocklinks))

//blocklinks       6400:0000
//nightmarespanws  65EC:0000
//[empty]          6000:7f8a
// 118 bytes free


// 0x5C00 BLOCK PHYSICS

#define SAVESTRINGSIZE        24u
#define MAX_REJECT_SIZE        15138u

#define size_rejectmatrix    (MAX_REJECT_SIZE)
#define size_savegamestrings (size_rejectmatrix + (10 * SAVESTRINGSIZE))

#define rejectmatrix         ((byte __far *)      MAKE_FULL_SEGMENT(0x5C000000, 0))
#define savegamestrings      ((int8_t __far *)    MAKE_FULL_SEGMENT(rejectmatrix, size_rejectmatrix))


/*
rejectmatrix       5C00:0000
savegamestrings    5FB3:0000
[empty]        5000:FC12
1006 bytes free
*/




// ALLOCATION DEFINITIONS: INTERMISSION




// Screen 0 is the screen updated by I_Update screen.
// Screen 1 is an extra buffer.

#define screen0 ((byte __far*) 0x80000000)
#define screen1 ((byte __far*) 0x90000000)
#define screen2 ((byte __far*) 0x70000000)
#define screen3 ((byte __far*) 0x60000000)
#define screen4 ((byte __far*) 0x90000000)

// screen1 is used during wi_stuff/intermission code, we can stick this anim data there
#define size_screen1          (64000u)
#define size_lnodex           ((sizeof(int16_t) * (9*3)))
#define size_lnodey           ((sizeof(int16_t) * (9*3)))
#define size_epsd0animinfo    (16 * 10)
#define size_epsd1animinfo    (16 * 9)
#define size_epsd2animinfo    (16 * 6)
#define size_wigraphics       (NUM_WI_ITEMS * 9)
#define size_pars             ((sizeof(int16_t) * (4*10)))
#define size_cpars            ((sizeof(int16_t) * (32)))

#define screen1          ((byte __far*)      0x90000000)
#define lnodex           ((int16_t __far*)   MAKE_FULL_SEGMENT(screen1, size_screen1))
#define lnodey           ((int16_t __far*)   (((int32_t)lnodex) + size_lnodex))
#define epsd0animinfo    ((wianim_t __far*)  (((int32_t)lnodey) + size_lnodey))
#define epsd1animinfo    ((wianim_t __far*)  (((int32_t)epsd0animinfo)+ size_epsd0animinfo))
#define epsd2animinfo    ((wianim_t __far*)  (((int32_t)epsd1animinfo)+ size_epsd1animinfo))
#define wigraphics       ((int8_t __far*)    (((int32_t)epsd2animinfo)+ size_epsd2animinfo))
#define pars             ((int16_t __far*)   MAKE_FULL_SEGMENT(lnodex, (((int32_t)wigraphics) & 0xFFFF)+size_wigraphics))
#define cpars            ((int16_t __far*)   MAKE_FULL_SEGMENT(pars, size_pars))



/*

This area used during intermission task

9000:0000  screen1
9FA0:0000  lnodex
9FA0:0036  lnodey
9FA0:006c  epsd0animinfo
9FA0:010c  epsd1animinfo
9FA0:019c  epsd2animinfo
9FA0:01FC  wigraphics
9FD0:0000  pars
9FD0:0050  cpars
9FD7:0000  [empty]

776 bytes free
*/

 

#define DEMO_SEGMENT 0x5000


#define demobuffer ((byte __far*) 0x50000000)

#define stringdata ((byte __far*)0x60000000)
#define stringoffsets ((uint16_t __far*)0x63C40000)

// ST_STUFF
#define ST_GRAPHICS_SEGMENT 0x7000u

// tall % sign
#define tallpercent  61304u
#define tallpercent_patch  ((byte __far *) 0x7000EF78)

//extern byte __far* palettebytes;
#define palettebytes_size  10752
#define palettebytes ((byte __far*) 0x90000000)
// 10752 bytes / 16 = 672 or 2A0 for offset

// 38677


// 6800 plane only... combine with skytex...


#define size_yslope            (sizeof(fixed_t) * SCREENHEIGHT)
#define size_distscale         (sizeof(fixed_t) * SCREENWIDTH)
#define size_cachedheight      (sizeof(fixed_t) * SCREENHEIGHT)
#define size_cacheddistance    (sizeof(fixed_t) * SCREENHEIGHT)
#define size_cachedxstep       (sizeof(fixed_t) * SCREENHEIGHT)
#define size_cachedystep       (sizeof(fixed_t) * SCREENHEIGHT)
#define size_spanstart         (sizeof(fixed_t) * SCREENHEIGHT)

// start plane only
#define yslope                ((fixed_t __far*)        MAKE_FULL_SEGMENT(0x90000000, 0))
#define distscale             ((fixed_t __far*)        MAKE_FULL_SEGMENT(yslope, size_yslope))
#define cachedheight          ((fixed_t __far*)        MAKE_FULL_SEGMENT(distscale, size_distscale))
#define cacheddistance        ((fixed_t __far*)        MAKE_FULL_SEGMENT(cachedheight, size_cachedheight))
#define cachedxstep           ((fixed_t __far*)        MAKE_FULL_SEGMENT(cacheddistance, size_cacheddistance))
#define cachedystep           ((fixed_t __far*)        MAKE_FULL_SEGMENT(cachedxstep, size_cachedxstep))
#define spanstart             ((int16_t __far*)        MAKE_FULL_SEGMENT(cachedystep, size_cachedystep))
// end plane only

/*
yslope         9000:0000
distscale      9032:0000
cachedheight   9082:0000
cacheddistance 90B4:0000
cachedxstep    90E6:0000
cachedystep    9118:0000
spanstart      914A:0000
skytexture     917C:0000
[empty]        9A0D:0000

*/

// 35080 bytes
#define skytexture_bytes ((byte __far*) MAKE_FULL_SEGMENT(spanstart, size_spanstart))
// 917c:0000
#define skytexture_segment ((uint16_t) ((int32_t)skytexture_bytes >> 16))

// note drawspan code could fit here and colormap in 0x9c00...

// main bar left
#define sbar  44024u
#define sbar_patch   ((byte __far *) 0x7000ABF8)

#define faceback  57152u
#define faceback_patch  ((byte __far *) 0x7000DF40)

#define armsbg_patch ((byte __far *)0x7000E668u)

#define armsbg  58984u




#define menugraphicspage0   (byte __far* )0x70000000
#define menugraphicspage4   (byte __far* )0x64000000

#define wigraphicspage0     (byte __far* )0x70000000
#define wigraphicslevelname (byte __far* )0x78000000
#define wianimspage         (byte __far* )0x60000000


#define NUM_WI_ITEMS 28
#define NUM_WI_ANIM_ITEMS 30

// maximum size for level complete graphic, times two
#define MAX_LEVEL_COMPLETE_GRAPHIC_SIZE 0x1240
#define size_level_finished_graphic (MAX_LEVEL_COMPLETE_GRAPHIC_SIZE * 2)

#define size_wioffsets              (sizeof(uint16_t) * NUM_WI_ITEMS)
#define size_wianimoffsets          (sizeof(uint16_t) * NUM_WI_ANIM_ITEMS)

#define wioffsets                   ((uint16_t __far*)   MAKE_FULL_SEGMENT(0x78000000, size_level_finished_graphic))
#define wianimoffsets               ((uint16_t __far*)   MAKE_FULL_SEGMENT(wioffsets, size_wioffsets))

/*
wioffsets      7800:2480
wianimoffsets  7800:24b8
[empty]        7800:24f4
// 6924 free? but intermission memory usage isnt common...









// ALLOCATION DEFINITIONS: RENDER

// RENDER 0x9000
// textures










// RENDER 0x8000


// openings are A000 in size. 0x7800 can be just that. Note that 0x2000 carries over to 8000

/*
openings                 7800:0000
negonearray_offset       7800:a000  or 8000:2000
screenheightarray_offset 7800:A500  or 8000:2500
[done]                   7800:AA00  or 8000:2A00
*/
// LEAVE ALL THESE in 0x7800 SEGMENT 
#define openings_segment 0x7800

#define size_openings      sizeof(int16_t) * MAXOPENINGS
#define size_negonearray          size_openings             + sizeof(int16_t) * (SCREENWIDTH)
#define size_screenheightarray    size_negonearray          + sizeof(int16_t) * (SCREENWIDTH)
#define size_floorclip            size_screenheightarray    + (sizeof(int16_t) * SCREENWIDTH)
#define size_ceilingclip          size_floorclip            + (sizeof(int16_t) * SCREENWIDTH)

#define openings             ((uint16_t __far*)         (0x78000000))
#define negonearray          ((int16_t __far*)          (0x78000000 + size_openings))
#define screenheightarray    ((int16_t __far*)          (0x78000000 + size_negonearray))
#define floorclip            ((int16_t __far*)          (0x78000000 + size_screenheightarray))
#define ceilingclip          ((int16_t __far*)          (0x78000000 + size_floorclip))

#define negonearray_offset        size_openings
#define screenheightarray_offset  size_negonearray

// LEAVE ALL THESE in 0x7800 SEGMENT 


#define FUZZTABLE		50 

#define size_leftover_openings_arrays     0x2A00

#define size_texturewidthmasks  MAX_TEXTURES * sizeof(uint8_t)
#define size_zlight             sizeof(uint16_t) * (LIGHTLEVELS * MAXLIGHTZ)
#define size_patchpage          MAX_PATCHES * sizeof(uint8_t)
#define size_patchoffset        MAX_PATCHES * sizeof(uint8_t)


#define texturewidthmasks       ((uint8_t  __far*)        MAKE_FULL_SEGMENT(0x80000000 , size_leftover_openings_arrays))
#define zlight                  ((uint16_t far*)          MAKE_FULL_SEGMENT(texturewidthmasks , size_texturewidthmasks))
#define patchpage               ((uint8_t __far*)         MAKE_FULL_SEGMENT(zlight , size_zlight))
#define patchoffset             ((uint8_t __far*)         (((int32_t)patchpage) + size_patchpage))
//#define patchoffset             ((uint8_t __far*)         MAKE_FULL_SEGMENT(patchpage, size_patchpage))

#define visplanes_8400          ((visplane_t __far*)      (0x84000000 ))
#define visplanes_8800          ((visplane_t __far*)      (0x88000000 ))
#define visplanes_8C00          ((visplane_t __far*)      (0x8C000000 ))

/*
  
spritecache_nodes           82A0:0000
flatcache_nodes             82A0:003C
patchcache_nodes            82A0:004E
texturecache_nodes          82A0:0073

texturewidthmasks           82A0:0000
zlight                      82BB:0000
patchpage                   83BB:0000
patchoffset                 83BB:01DC
[empty]                     8000:3F73



// 152 bytes free
*/




// RENDER REMAPPING

// RENDER 0x7800 - 0x7FFF DATA NOT USED IN PLANES

//            bsp    plane    sprite
// 9C00-9FFF     -- no changes --
// 9000-9BFF  DATA sky texture DATA
// 8000-8FFF     -- no changes --
// 7800-7FFF  DATA  flatcache  DATA
// 7000-77FF  DATA  flatcache  sprcache
// 6800-6FFF  DATA  DATA       sprcache
// 4000-67FF     -- no changes --



// RENDER 0x7000-0x77FF DATA - USED ONLY IN BSP ... 13k + 8k ... 10592 free
#define size_nodes_render      MAX_NODES_RENDER_SIZE
#define size_spritedefs        16114u
#define size_spritewidths      (sizeof(uint8_t) * MAX_SPRITE_LUMPS)

//30462
#define nodes_render          ((node_render_t __far*)  MAKE_FULL_SEGMENT(0x70000000, 0))
#define spritedefs_bytes      ((byte __far*)           MAKE_FULL_SEGMENT(nodes_render, size_nodes_render))
#define spritewidths          ((uint8_t __far*)        MAKE_FULL_SEGMENT(spritedefs_bytes, size_spritedefs))




/*

nodes_render        7000:0000
spritedefs_bytes    7000:36A0
spritewidths        7000:7592
[empty]             7000:7AF7

1289 bytes free
*/


// RENDER 0x6800-0x6FFF DATA - USED ONLY IN PLANE/BSP... PAGED OUT IN SPRITE REGION
// same as physics 6800-6fff


// carried over from below - mostly visplanes


// RENDER 0x5000-0x67FF DATA     

// size_texturecolumnofs_bytes is technically 80480. Takes up whole 0x5000 region, 14944 left over in 0x6000...
#define size_texturecolumnofs_bytes    14944u
#define size_texturecolumnlumps_bytes  (1264u * sizeof(int16_t))
#define size_texturedefs_bytes         8756u
#define size_spriteoffsets             (sizeof(uint8_t) * MAX_SPRITE_LUMPS)
#define size_spritetopoffsets          (sizeof(int8_t) * MAX_SPRITE_LUMPS)
#define size_texturedefs_offset        (MAX_TEXTURES * sizeof(uint16_t))
#define size_spritepage                (MAX_SPRITE_LUMPS * sizeof(uint8_t))
#define size_spriteoffset              (MAX_SPRITE_LUMPS * sizeof(uint8_t))



// size_texturedefs_bytes 0x6184... 0x6674

// dont change texturecolumnofs_bytes_2 segment as it carries into the 6000
#define texturecolumnofs_bytes_1  ((byte __far*)     (0x50000000 ))
#define texturecolumnofs_bytes_2  ((byte __far*)     (0x58000000 ))
#define texturecolumnlumps_bytes  ((int16_t __far*)  MAKE_FULL_SEGMENT(0x60000000,               size_texturecolumnofs_bytes))
#define texturedefs_bytes         ((byte __far*)     MAKE_FULL_SEGMENT(texturecolumnlumps_bytes, size_texturecolumnlumps_bytes))
#define spriteoffsets             ((uint8_t __far*)  MAKE_FULL_SEGMENT(texturedefs_bytes,        size_texturedefs_bytes))
#define spritetopoffsets          ((int8_t __far*)   MAKE_FULL_SEGMENT(spriteoffsets,            size_spriteoffsets))
#define texturedefs_offset        ((uint16_t  __far*)MAKE_FULL_SEGMENT(spritetopoffsets,         size_spritetopoffsets))
#define spritepage                ((uint8_t __far*)  MAKE_FULL_SEGMENT(texturedefs_offset,                size_texturedefs_offset))
#define spriteoffset              ((uint8_t __far*)  (((int32_t)spritepage)                      + size_spritepage))


// texturecolumnlumps_bytes   63A6:0000
// texturedefs_bytes          6444:0000
// spriteoffsets              6668:0000
// spritetopoffsets           66BF:0000
// spritepage                 6716:0000
// spriteoffset               6716:0565
// flatindex                  67C3:0000
// [empty]                    67C3:7CC7

// zlight could be here...


// 825 bytes free till 6000:8000 

// 0x4000 BLOCK RENDER

#define size_segs_render              MAX_SEGS_RENDER_SIZE
#define size_sides_render             MAX_SIDES_RENDER_SIZE
#define size_vissprites               (sizeof(vissprite_t) * (MAXVISSPRITES))
#define size_player_vissprites        (sizeof(vissprite_t) * 2)
#define size_texturepatchlump_offset  (MAX_TEXTURES * sizeof(uint16_t))
#define size_texturecolumn_offset     (MAX_TEXTURES * sizeof(uint16_t))
#define size_visplaneheaders          (sizeof(visplaneheader_t) * MAXEMSVISPLANES)
#define size_fuzzofset                FUZZTABLE
#define size_viewangletox             (sizeof(int16_t) * (FINEANGLES / 2))
#define size_drawsegs                 (sizeof(drawseg_t) * (MAXDRAWSEGS+1))
#define size_texturecompositesizes    (MAX_TEXTURES * sizeof(uint16_t))
#define size_compositetexturepage     (MAX_TEXTURES * sizeof(uint8_t))
#define size_compositetextureoffset   (MAX_TEXTURES * sizeof(uint8_t))
#define size_flatindex                (sizeof(uint8_t) * MAX_FLATS)


#define segs_render             ((seg_render_t  __far*)      MAKE_FULL_SEGMENT(0x40000000              , 0))
#define sides_render            ((side_render_t __far*)      MAKE_FULL_SEGMENT(segs_render             , size_segs_render))
#define vissprites              ((vissprite_t __far*)        MAKE_FULL_SEGMENT(sides_render            , size_sides_render))
#define player_vissprites       ((vissprite_t __far*)        MAKE_FULL_SEGMENT(vissprites              , size_vissprites))
#define texturepatchlump_offset ((uint16_t __far*)           MAKE_FULL_SEGMENT(player_vissprites       , size_player_vissprites))
#define texturecolumn_offset    ((uint16_t __far*)           MAKE_FULL_SEGMENT(texturepatchlump_offset , size_texturepatchlump_offset))
#define visplaneheaders         ((visplaneheader_t __far*)   MAKE_FULL_SEGMENT(texturecolumn_offset    , size_texturecolumn_offset))
#define fuzzoffset              ((int8_t __far*)             MAKE_FULL_SEGMENT(visplaneheaders         , size_visplaneheaders))
#define viewangletox            ((int16_t __far*)            MAKE_FULL_SEGMENT(fuzzoffset              , size_fuzzofset))
// offset of a drawseg so we can subtract drawseg from drawsegs for a certain potential loop condition...
#define drawsegs                ((drawseg_t __far*)          (MAKE_FULL_SEGMENT(viewangletox           , size_viewangletox) + sizeof(drawseg_t)))
#define flatindex                 ((uint8_t __far*)  MAKE_FULL_SEGMENT(drawsegs,         size_drawsegs))
#define texturecompositesizes   ((uint16_t __far*)           MAKE_FULL_SEGMENT(flatindex      , size_flatindex))
#define compositetexturepage    ((uint8_t __far*)            MAKE_FULL_SEGMENT(texturecompositesizes   , size_texturecompositesizes))
#define compositetextureoffset  ((uint8_t __far*)            (((int32_t)compositetexturepage)          + size_compositetexturepage))
//0x4FBEE

// used during p_setup
#define segs_render_9000     ((seg_render_t __far*)       (0x90000000 + 0))
#define sides_render_9000    ((side_render_t __far*)      MAKE_FULL_SEGMENT(segs_render_9000, size_segs_render))


/*

segs_render             4000:0000
sides_render            46E0:0000
vissprites              4967:0000
player_vissprites       4ACF:0000
texturepatchlump_offset 4AD5:0000
texturecolumn_offset    4B0B:0000
texturecompositesizes   4B41:0000
visplaneheaders         4B77:0000
fuzzoffset              4BC6:0000
viewangletox            4BCA:0000
drawsegs                4DCA:0000
texturedefs_offset      4F7A:0000

compositetexturepage    4FB2:0000
compositetextureoffset  4FB2:01AC
[near range over]       

[done]                  4000:FE78


392 bytes free

*/




 

#endif

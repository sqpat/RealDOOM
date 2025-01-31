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
#include "r_defs.h"
#include "m_offset.h"

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
#define MAXLINEANIMS    64

// round up a segment if necessary. convert size to segments
#define MAKE_FULL_SEGMENT(a, b)  ((int32_t)a + ((((int32_t)b + 0x0F) >> 4) << 16))

#define FIXED_DS_SEGMENT  0x3C00

// ALLOCATION DEFINITIONS: UPPER MEMORY

// 0xE000 Block

// may swap with EMS/0xD000 ?
#ifdef __USED000
#define uppermemoryblock    0xD0000000
#else
#define uppermemoryblock    0xE0000000
#endif

#define size_sectors            (MAX_SECTORS_SIZE)
#define size_vertexes           (MAX_VERTEXES_SIZE)
#define size_sides              (MAX_SIDES_SIZE)
#define size_lines              (MAX_LINES_SIZE)
#define size_lineflagslist      (MAX_LINEFLAGS_SIZE)
#define size_subsectors         (MAX_SUBSECTORS_SIZE)
#define size_nodes              (MAX_NODES_SIZE)
#define size_node_children      (MAX_NODE_CHILDREN_SIZE)
#define size_seg_linedefs       (MAX_SEGS * sizeof(int16_t))
#define size_seg_sides          (MAX_SEGS * sizeof(uint8_t))
#define size_scantokey           128



#define sectors           ((sector_t __far*)        MAKE_FULL_SEGMENT(uppermemoryblock , 0))
#define vertexes          ((vertex_t __far*)        MAKE_FULL_SEGMENT(sectors          , size_sectors))
#define sides             ((side_t __far*)          MAKE_FULL_SEGMENT(vertexes         , size_vertexes))
#define lines             ((line_t __far*)          MAKE_FULL_SEGMENT(sides            , size_sides))
#define lineflagslist     ((uint8_t __far*)         MAKE_FULL_SEGMENT(lines            , size_lines))
#define subsectors        ((subsector_t __far*)     MAKE_FULL_SEGMENT(lineflagslist    , size_lineflagslist))
#define nodes             ((node_t __far*)          MAKE_FULL_SEGMENT(subsectors       , size_subsectors))
#define node_children     ((node_children_t __far*) MAKE_FULL_SEGMENT(nodes            , size_nodes))
#define seg_linedefs      ((int16_t __far*)         MAKE_FULL_SEGMENT(node_children    , size_node_children))
#define seg_sides         ((uint8_t __far*)         MAKE_FULL_SEGMENT(seg_linedefs     , size_seg_linedefs))
#define scantokey         ((byte __far*)            MAKE_FULL_SEGMENT(seg_sides        , size_seg_sides))




#define sectors_segment              ((segment_t) ((int32_t)sectors >> 16))
#define vertexes_segment             ((segment_t) ((int32_t)vertexes >> 16))
#define sides_segment                ((segment_t) ((int32_t)sides >> 16))
#define lines_segment                ((segment_t) ((int32_t)lines >> 16))
#define lineflagslist_segment        ((segment_t) ((int32_t)lineflagslist >> 16))
#define subsectors_segment           ((segment_t) ((int32_t)subsectors >> 16))
#define nodes_segment                ((segment_t) ((int32_t)nodes >> 16))
#define node_children_segment        ((segment_t) ((int32_t)node_children >> 16))
#define seg_linedefs_segment         ((segment_t) ((int32_t)seg_linedefs >> 16))
#define seg_sides_segment            ((segment_t) ((int32_t)seg_sides >> 16))
#define seg_sides_offset_in_seglines ((uint16_t)(((seg_sides_segment - seg_linedefs_segment) << 4)))
#define scantokey_segment            ((segment_t) ((int32_t)scantokey >> 16))




//0xE000
/*
sectors              E000:0000
vertexes             E15C:0000
sides                E2F3:0000
lines                E801:0000
lineflagslist        E9BA:0000
subsectors           EA29:0000
nodes                EB18:0000
node_children        ECF6:0000
segs_linedefs        EDE5:0000
segs_sides           EF45:0000 
scantokey            EFF5:0000
[empty]              EFFD:0000
              

48 bytes left

SUBSECTORS_SEGMENT= 0EA37h
SUBSECTOR_LINES_SEGMENT = 0EB26h
NODES_SEGMENT = 0EB62h
NODE_CHILDREN_SEGMENT = 0ED40h
SEG_LINEDEFS_SEGMENT = 0EE2Fh
SEG_SIDES_SEGMENT = 0EF8Fh


            
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


//CC00 block (16k)
 
  


 // ALLOCATION DEFINITIONS: LOWER MEMORY BLOCKS 
 // still far memory but 'common' to all tasks because its outside of paginated area


// size_texturecolumnlumps_bytes

// 1264u doom2 now 1424
// 402 shareware

// size_texturecolumnofs_bytes
// 80480  doom2 
// 21552u shareware

// size_texturedefs_bytes
// 3767u shareware
// 8756u doom2

#define SAVESTRINGSIZE        24u

#define baselowermemoryaddress    (0x31160000)
#define base_lower_memory_segment ((segment_t) ((int32_t)baselowermemoryaddress >> 16))

#define size_finesine            (10240u * sizeof(int32_t))
#define size_events              (sizeof(event_t) * MAXEVENTS)
#define size_flattranslation     (MAX_FLATS * sizeof(uint8_t))
#define size_texturetranslation  (MAX_TEXTURES * sizeof(uint16_t))
#define size_textureheights      (MAX_TEXTURES * sizeof(uint8_t))
#define size_rndtable            256
#define size_subsector_lines     (MAX_SUBSECTOR_LINES_SIZE)
#define size_savegamestrings     (10 * SAVESTRINGSIZE)


#define FINE_SINE_ARGUMENT  base_lower_memory_segment
#define FINE_COSINE_ARGUMENT FINE_SINE_ARGUMENT + 0x200



#define finesine           ((int32_t __far*)            MAKE_FULL_SEGMENT(baselowermemoryaddress, 0))  // 10240
#define finecosine         ((int32_t __far*)            (baselowermemoryaddress + 0x2000))  // 10240
#define events             ((event_t __far*)            MAKE_FULL_SEGMENT(finesine, size_finesine))
#define flattranslation    ((uint8_t __far*)            MAKE_FULL_SEGMENT(events, size_events))
#define texturetranslation ((uint16_t __far*)           MAKE_FULL_SEGMENT(flattranslation, size_flattranslation))
#define textureheights     ((uint8_t __far*)            MAKE_FULL_SEGMENT(texturetranslation, size_texturetranslation))
#define rndtable           ((uint8_t __far*)            MAKE_FULL_SEGMENT(textureheights , size_textureheights)) 
#define subsector_lines    ((uint8_t __far*)            MAKE_FULL_SEGMENT(rndtable, size_rndtable))
#define savegamestrings    ((int8_t __far *)            MAKE_FULL_SEGMENT(subsector_lines , size_subsector_lines))
#define base_lower_end     ((uint8_t __far*)            MAKE_FULL_SEGMENT(savegamestrings , size_savegamestrings))


#define finesine_segment              ((segment_t) ((int32_t)finesine >> 16))
// todo clean this and finecosine up
#define finecosine_segment            ((segment_t) (finesine_segment + 0x200))
#define events_segment                ((segment_t) ((int32_t)events >> 16))
#define flattranslation_segment       ((segment_t) ((int32_t)flattranslation >> 16))
#define texturetranslation_segment    ((segment_t) ((int32_t)texturetranslation >> 16))
#define textureheights_segment        ((segment_t) ((int32_t)textureheights >> 16))
#define rndtable_segment              ((segment_t) ((int32_t)rndtable >> 16))
#define subsector_lines_segment       ((segment_t) ((int32_t)subsector_lines >> 16))
#define savegamestrings_segment       ((segment_t) ((int32_t)savegamestrings >> 16))
#define base_lower_end_segment        ((segment_t) ((int32_t)base_lower_end >> 16))

//todo recalculate after moving stuff around...


// finesine             3116:0000
// finecosine           3116:2000
// events               3B16:0000
// flattranslation      3B4A:0000
// texturetranslation   3B53:0000
// textureheights       3B8A:0000
// rndtable             3BA5:0000
// subsector_lines      3BB5:0000
// savegamestrings      3BF1:0000
// base_lower_end       3C00:0000
//03BACh
// done                 3C00:0000







// ALLOCATION DEFINITIONS: PHYSICS


// 0x9000 BLOCK PHYSICS

// note: 0x9400-0x9FFF is for lumpinfo...

#define size_segs_physics     (MAX_SEGS_PHYSICS_SIZE)
#define size_diskgraphicbytes (392)

#define segs_physics          ((seg_physics_t __far*)    (0x90000000))
#define diskgraphicbytes      ((byte __far*)             MAKE_FULL_SEGMENT(segs_physics,     size_segs_physics))


#define segs_physics_segment              ((segment_t) ((int32_t)segs_physics >> 16))
#define diskgraphicbytes_segment          ((segment_t) ((int32_t)diskgraphicbytes >> 16))


//todo get rid of this.
#ifdef MOVE_P_SIGHT
// 0x92E80000
#define PSightFuncLoadAddr      ((byte __far*) (MAKE_FULL_SEGMENT(diskgraphicbytes, size_diskgraphicbytes)))
#define P_CheckSightAddr        ((boolean (__far *)(mobj_t __near* ,mobj_t __near* ,mobj_pos_t __far* ,mobj_pos_t __far* ))  (PSightFuncLoadAddr))
#define SIZE_PSight             0x0A70*/
#endif

// end at 0x9380

 // or 9380:0000
#define InfoFuncLoadAddr      ((byte __far *) MAKE_FULL_SEGMENT(diskgraphicbytes, size_diskgraphicbytes))
// note: entry point to the function is not necessarily the first byte of the compiled binary. (jump tables and stuff for switch cases)
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

#define InfoFuncLoadSegment              ((segment_t) ((int32_t)InfoFuncLoadAddr >> 16))

//#define SIZE_D_INFO          0x0698
#define SIZE_D_INFO            0x069C
// 0x93E9




// segs_physics     9000:0000
// diskgraphicbytes 92C0:0000
// D_INFO           92D9:0000
// [empty]          9343:0000
// FREEBYTES 2784 bytes free


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
//todo update
92D9:0034      getPainChance_
92D9:00b2      getRaiseState_
92D9:010a      getXDeathState_
92D9:015a      getMeleeState_
92D9:01b8      getMobjMass_
92D9:0222      getActiveSound_
92D9:0284      getPainSound_
92D9:02b8      getAttackSound_
92D9:02da      getDamage_
92D9:0350      getSeeState_
92D9:03f4      getMissileState_
92D9:04a8      getDeathState_
92D9:0586      getPainState_
92D9:063c      getSpawnHealth_
92D9:069c*     [empty] ??
*/

 


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

#define size_thinkerlist           (sizeof(thinker_t) * MAX_THINKERS)
#define size_linebuffer            (MAX_LINEBUFFER_SIZE)
#define size_sectors_physics       (MAX_SECTORS_PHYSICS_SIZE)
#define size_sectors_soundorgs     (MAX_SECTORS_SOUNDORGS_SIZE)
#define size_sector_soundtraversed (MAX_SECTORS_SOUNDTRAVERSED_SIZE)
#define size_mobjinfo              (sizeof(mobjinfo_t) * NUMMOBJTYPES)
#define size_intercepts            (sizeof(intercept_t) * MAXINTERCEPTS)
#define size_ammnumpatchbytes      (524)
#define size_ammnumpatchoffsets    ((sizeof(uint16_t) * 10))
#define size_doomednum             ((sizeof(int16_t) * NUMMOBJTYPES))
#define size_linespeciallist       ((sizeof(int16_t) * MAXLINEANIMS))
#define size_font_widths           (HU_FONTSIZE * sizeof(int8_t))



#define thinkerlist_far        ((thinker_t __far*)            MAKE_FULL_SEGMENT(0x40000000, 0))
#define mobjinfo_far           ((mobjinfo_t __far *)          MAKE_FULL_SEGMENT(thinkerlist_far, size_thinkerlist))
#define linebuffer_far         ((int16_t __far*)              MAKE_FULL_SEGMENT(mobjinfo_far, size_mobjinfo ))
#define sectors_physics_far    ((sector_physics_t __far* )    MAKE_FULL_SEGMENT(linebuffer_far, size_linebuffer ))
#define sectors_soundorgs      ((sector_soundorg_t __far* )   MAKE_FULL_SEGMENT(sectors_physics_far, size_sectors_physics ))
#define sector_soundtraversed  ((int8_t __far*)               MAKE_FULL_SEGMENT(sectors_soundorgs, size_sectors_soundorgs ))

#define intercepts             ((intercept_t __far*)          MAKE_FULL_SEGMENT(sector_soundtraversed, size_sector_soundtraversed ))
#define ammnumpatchbytes       ((byte __far *)                MAKE_FULL_SEGMENT(intercepts, size_intercepts ))
#define ammnumpatchoffsets     ((uint16_t __far*)             (((int32_t)ammnumpatchbytes) + 0x020C))
#define doomednum              ((int16_t __far*)              MAKE_FULL_SEGMENT(ammnumpatchbytes, (size_ammnumpatchbytes+size_ammnumpatchoffsets )))
#define linespeciallist        ((int16_t __far*)              MAKE_FULL_SEGMENT(doomednum, size_doomednum ))
#define font_widths            ((int8_t __far*)               MAKE_FULL_SEGMENT(linespeciallist, size_linespeciallist))
#define code_overlay_start     ((byte __far*)                 MAKE_FULL_SEGMENT(font_widths, size_font_widths))
#define code_overlay_end       ((byte __far*)                 MAKE_FULL_SEGMENT(code_overlay_start, FinaleCodeSize))
// WipeCodeSize

#define thinkerlist_segment           ((segment_t) ((int32_t)thinkerlist_far >> 16))
#define mobjinfo_segment              ((segment_t) ((int32_t)mobjinfo_far >> 16))
#define linebuffer_segment            ((segment_t) ((int32_t)linebuffer_far >> 16))
#define sectors_physics_segment       ((segment_t) ((int32_t)sectors_physics_far >> 16))
#define sectors_soundorgs_segment     ((segment_t) ((int32_t)sectors_soundorgs >> 16))
#define sector_soundtraversed_segment ((segment_t) ((int32_t)sector_soundtraversed >> 16))

#define intercepts_segment            ((segment_t) ((int32_t)intercepts >> 16))
#define ammnumpatchbytes_segment      ((segment_t) ((int32_t)ammnumpatchbytes >> 16))
#define ammnumpatchoffsets_segment    ((segment_t) ((int32_t)ammnumpatchoffsets >> 16))
#define doomednum_segment             ((segment_t) ((int32_t)doomednum >> 16))
#define linespeciallist_segment       ((segment_t) ((int32_t)linespeciallist >> 16))
#define font_widths_segment           ((segment_t) ((int32_t)font_widths >> 16))
#define code_overlay_segment          ((segment_t) ((int32_t)code_overlay_start >> 16))
#define code_overlay_end_segment      ((segment_t) ((int32_t)code_overlay_end >> 16))
// 4CE0h

 // 3C00:4000
#define thinkerlist        ((thinker_t __near*)          0x4000)
#define mobjinfo           ((mobjinfo_t  __near*)       (0x4000 + ((mobjinfo_segment        - thinkerlist_segment)<<4)))
#define linebuffer         ((int16_t __near*)           (0x4000 + ((linebuffer_segment      - thinkerlist_segment)<<4)))
#define sectors_physics    ((sector_physics_t __near* ) (0x4000 + ((sectors_physics_segment - thinkerlist_segment)<<4)))



// 4000:0000  4000 thinkerlist
// 4906:0000  D060 mobjinfo
// 4965:0000  D650 linebuffer
// 4AA3:0000  EA30 sectors_physics
// 4BFF:0000  xxxx sectors_soundorgs
// 4C56:0000  xxxx sectors_soundstraversed
// 4C6c:0000  xxxx intercepts
// 4CA4:0000  xxxx ammnumpatchbytes
// 4CA4:020C  xxxx ammnumpatchoffsets
// 4CC6:0000  xxxx doomednum
// 4CD8:0000  xxxx linespeciallist
// 4CE0:0000  xxxx font_widths
// 4CE4:0000  xxxx code_overlay_segment
// 4D16:0000  xxxx [empty]


// 12000 bytes free?

// PHYSICS 0x6000 - 0x7FFF DATA
// note: strings in 0x6000-6400 region

//0x8000 BLOCK PHYSICS


#define screen0 ((byte __far*) 0x80000000)
#define size_screen0        (64000u)
#define size_gammatable     (256 * 5)


#define gammatable          ((byte __far*)      (0x8FA00000 ))



#define screen0_segment           ((segment_t) ((int32_t)screen0 >> 16))
#define gammatable_segment        ((segment_t) ((int32_t)gammatable >> 16))


/*

this area used in many tasks including physics but not including render

8000:0000  screen0
8FA0:0000  gammatable
8FF0:0000  [empty]
//FREEBYTES 256 ?


//
*/

//0x7000 BLOCK PHYSICS

#define size_lines_physics    (MAX_LINES_PHYSICS_SIZE)
#define size_blockmaplump     ( MAX_BLOCKMAP_LUMPSIZE)

//3f8a, runs up close to 6800 which has mobjposlist, etc
#define size_states              (sizeof(state_t) * NUMSTATES)


#define lines_physics       ((line_physics_t __far*)  MAKE_FULL_SEGMENT(0x70000000, 0))
#define blockmaplump        ((int16_t __far*)         MAKE_FULL_SEGMENT(lines_physics, size_lines_physics))
#define blockmaplump_plus4  ((int16_t __far*)         (((int32_t)blockmaplump) + 0x08))



#define states             ((state_t __far*)          MAKE_FULL_SEGMENT(blockmaplump, size_blockmaplump+0x08))  

#define physics_7000_end    ((uint8_t __far*)         MAKE_FULL_SEGMENT(states, size_states+0x08))

#define lines_physics_segment       ((segment_t) ((int32_t)lines_physics >> 16))
#define blockmaplump_segment        ((segment_t) ((int32_t)blockmaplump >> 16))
#define states_segment                ((segment_t) ((int32_t)states >> 16))
#define physics_7000_end_segment    ((segment_t) ((int32_t)physics_7000_end >> 16))

/*
lines_physics       7000:0000
blockmaplump        76E4:0000
blockmaplump_plus4  76E4:0008
states              7D74:0000
FREEBYTES           7EE0:0000
 4608 bytes free!
*/



// 0x6800 BLOCK PHYSICS

// begin stuff that is paged out in sprite code
// this is used boht in physics and part of render code


#define size_mobjposlist           (MAX_THINKERS * sizeof(mobj_pos_t))
#define size_colfunc_jump_lookup   (sizeof(uint16_t) * SCREENHEIGHT)
#define size_dc_yl_lookup          (sizeof(uint16_t) * SCREENHEIGHT)
#define size_colfunc_function_area R_DrawColumnCodeSize

// currently using:  2962
// can stick lookup tables (800 bytes) in
// plus the extra setup code - should fit



#define size_colormaps        ((33 * 256))
#define size_seenlines          (MAX_SEENLINES_SIZE)


#define colormaps             ((lighttable_t  __far*)     MAKE_FULL_SEGMENT(0x98000000            , 0))
#define colfunc_jump_lookup   ((uint16_t  __far*)         MAKE_FULL_SEGMENT(colormaps             , size_colormaps))
#define dc_yl_lookup          ((uint16_t  __far*)         MAKE_FULL_SEGMENT(colfunc_jump_lookup   , size_colfunc_jump_lookup))
#define colfunc_function_area ((byte  __far*)             MAKE_FULL_SEGMENT(dc_yl_lookup          , size_dc_yl_lookup))
#define mobjposlist           ((mobj_pos_t __far*)        MAKE_FULL_SEGMENT(colfunc_function_area , size_colfunc_function_area))
#define seenlines             ((uint8_t __far*)           MAKE_FULL_SEGMENT(mobjposlist           , size_mobjposlist))
#define empty_render_9800     ((uint16_t  __far*)         MAKE_FULL_SEGMENT(seenlines             , size_seenlines))
//6D8A

#define colormaps_segment               ((segment_t) ((int32_t)colormaps >> 16))
#define colfunc_jump_lookup_segment     ((segment_t) ((int32_t)colfunc_jump_lookup >> 16))
#define dc_yl_lookup_segment            ((segment_t) ((int32_t)dc_yl_lookup >> 16))
#define colfunc_function_area_segment   ((segment_t) ((int32_t)colfunc_function_area >> 16))
#define mobjposlist_segment             ((segment_t) ((int32_t)mobjposlist >> 16))
#define seenlines_segment               ((segment_t) ((int32_t)seenlines >> 16))
#define empty_render_9800_segment       ((segment_t) ((int32_t)empty_render_9800 >> 16))

//physics addresses. if wads ever move out of EMS, use the 9800 mapping again.
#define colormaps_6800             ((lighttable_t  __far*)     MAKE_FULL_SEGMENT(0x68000000                 , 0))
#define colfunc_jump_lookup_6800   ((uint16_t  __far*)         MAKE_FULL_SEGMENT(colormaps_6800             , size_colormaps))
#define dc_yl_lookup_6800          ((uint16_t  __far*)         MAKE_FULL_SEGMENT(colfunc_jump_lookup_6800   , size_colfunc_jump_lookup))
#define colfunc_function_area_6800 ((byte  __far*)             MAKE_FULL_SEGMENT(dc_yl_lookup_6800          , size_dc_yl_lookup))
#define mobjposlist_6800           ((mobj_pos_t __far*)        MAKE_FULL_SEGMENT(colfunc_function_area_6800 , size_colfunc_function_area))
#define seenlines_6800             ((uint8_t __far*)           MAKE_FULL_SEGMENT(mobjposlist_6800           , size_mobjposlist))
#define empty_render_6800          ((byte __far*)              MAKE_FULL_SEGMENT(seenlines_6800             , size_seenlines))

#define colormaps_6800_segment               ((segment_t) ((int32_t)colormaps_6800 >> 16))
#define colfunc_jump_lookup_6800_segment     ((segment_t) ((int32_t)colfunc_jump_lookup_6800 >> 16))
#define dc_yl_lookup_6800_segment            ((segment_t) ((int32_t)dc_yl_lookup_6800 >> 16))
#define colfunc_function_area_6800_segment   ((segment_t) ((int32_t)colfunc_function_area_6800 >> 16))
#define mobjposlist_6800_segment             ((segment_t) ((int32_t)mobjposlist_6800 >> 16))
#define seenlines_6800_segment               ((segment_t) ((int32_t)seenlines_6800 >> 16))
#define empty_render_6800_segment       ((segment_t) ((int32_t)empty_render_6800 >> 16))



// seenlines_segment:  6FE8:0000
// empty:              6FF6:0000
// FREEBYTES 160 bytes free

// 8C60
#define colormaps_maskedmapping_seg_diff  ((segment_t)0x8C00 - colormaps_segment)

// used in sprite render, this has been remapped to 8C00 page
#define colormaps_maskedmapping         ((lighttable_t  __far*) 0x8C000000)
// 852D
#define colormaps_segment_maskedmapping  ((segment_t) ((int32_t)colormaps_maskedmapping >> 16))


//6F2E
#define colfunc_segment                 ((segment_t) ((int32_t)colfunc_function_area >> 16))
#define colfunc_segment_maskedmapping   ((segment_t) (colfunc_segment           - colormaps_segment + colormaps_segment_maskedmapping))


#define colfunc_jump_lookup_maskedmapping ((uint16_t __far*)  (((int32_t)colfuncjump_lookup) - (int32_t)colormaps + (int32_t)colormaps_maskedmapping))
#define dc_yl_lookup_maskedmapping        ((uint16_t  __far*) (((int32_t)dc_yl_lookup)       - (int32_t)colormaps + (int32_t)colormaps_maskedmapping))

#define dc_yl_lookup_maskedmapping_segment ((segment_t) ((int32_t)dc_yl_lookup_maskedmapping >> 16))


#define colormaps_colfunc_seg_difference (colfunc_segment - colormaps_segment)
#define colormaps_colfunc_off_difference (colormaps_colfunc_seg_difference << 4)
//6f59




// EXTRA SPRITE/RENDER_MASKED DATA

#define size_maskedpostdata             12238u
#define size_drawfuzzcol_area           R_DrawFuzzColumnCodeSize

#define size_spritepostdatasizes        (MAX_SPRITE_LUMPS * sizeof(uint16_t))
#define size_spritetotaldatasizes       (MAX_SPRITE_LUMPS * sizeof(uint16_t))
#define size_maskedpostdataofs          size_maskedpixeldataofs
#define size_maskedpixeldataofs         3456u
#define size_maskedconstants_funcarea   R_MaskedConstantsCodeSize

#define maskedpostdata             ((byte __far*)              (0x84000000 ))
#define drawfuzzcol_area           ((byte __far*)              MAKE_FULL_SEGMENT(maskedpostdata,             size_maskedpostdata))
#define render_8400_end              ((byte __far*)            MAKE_FULL_SEGMENT(drawfuzzcol_area,           size_drawfuzzcol_area)) 
// 87FBh

#define spritepostdatasizes        ((uint16_t __far*)          MAKE_FULL_SEGMENT(drawfuzzcol_area,           size_drawfuzzcol_area)) 
#define spritetotaldatasizes       ((uint16_t __far*)          MAKE_FULL_SEGMENT(spritepostdatasizes,        size_spritepostdatasizes))
#define maskedpostdataofs          ((uint16_t __far*)          MAKE_FULL_SEGMENT(spritetotaldatasizes,       size_spritetotaldatasizes))
#define maskedpixeldataofs         ((byte __far*)              MAKE_FULL_SEGMENT(maskedpostdataofs,          size_maskedpostdataofs))
#define maskedconstants_funcarea   ((byte __far*)              MAKE_FULL_SEGMENT(maskedpixeldataofs,         size_maskedpixeldataofs))
#define render_8800_end            ((byte __far*)              MAKE_FULL_SEGMENT(maskedconstants_funcarea,   size_maskedconstants_funcarea))
// 8B10


#define spritepostdatasizes_segment        ((segment_t) ((int32_t)spritepostdatasizes >> 16))
#define spritetotaldatasizes_segment       ((segment_t) ((int32_t)spritetotaldatasizes >> 16))
#define maskedpostdataofs_segment          ((segment_t) ((int32_t)maskedpostdataofs >> 16))
#define maskedpixeldataofs_segment         ((segment_t) ((int32_t)maskedpixeldataofs >> 16))
#define maskedconstants_funcarea_segment   ((segment_t) ((int32_t)maskedconstants_funcarea >> 16))
#define render_8800_end_segment            ((segment_t) ((int32_t)render_8800_end >> 16))


#define maskedpostdata_segment             ((segment_t) ((int32_t)maskedpostdata >> 16))
#define drawfuzzcol_area_segment           ((segment_t) ((int32_t)drawfuzzcol_area >> 16))
#define render_8400_end_segment            ((segment_t) ((int32_t)render_8400_end >> 16))

 /*

TODO UPDATE
maskedpostdata              8400:0000
drawmaskedfuncarea_sprite?  86FD:0000
empty                       8721:0000 
FREEBYTES 3568 free
// MOVE SOME OTHER RENDER CODE HERE?


 spritepostdatasizes              87FE:0000
 spritetotaldatasizes             88AB:0000
 maskedpostdataofs                8958:0000
 maskedpixeldataofs               8A30:0000
 maskedconstants_funcarea_segment 8B08:0000
 render_8800_end_segment          8B17:0000 

FREEBYTES 3728 free (!). move some here
 */







//#define spanfunc_function_offset  0x1000
//#define size_spanfunc_jump_lookup 400
#define size_spanfunc_jump_lookup         (80 * sizeof(uint16_t)) 
#define size_spanfunc_funcation_area      R_DrawSpanCodeSize

// spanfunc offset
#define spanfunc_jump_lookup              ((uint16_t  __far*)               MAKE_FULL_SEGMENT(0x9C000000              , palettebytes_size))
//#define spanfunc_function_area            ((byte  __far*)                   MAKE_FULL_SEGMENT(spanfunc_jump_lookup, size_spanfunc_jump_lookup))
#define render_9C00_end                   ((uint8_t __far*)                 MAKE_FULL_SEGMENT(spanfunc_jump_lookup,   R_DrawSpanCodeSize))

// used for loading into memory - not the actual call
#define spanfunc_jump_lookup_9000         ((byte  __far*)                   (((uint32_t)spanfunc_jump_lookup)   - 0x9C000000 + 0x90000000))
//#define spanfunc_function_area_9000       ((uint16_t  __far*)               (((uint32_t)spanfunc_function_area) - 0x9C000000 + 0x90000000))

#define spanfunc_jump_lookup_segment      ((segment_t) ((int32_t)spanfunc_jump_lookup >> 16))
//#define spanfunc_function_area_segment    ((segment_t) ((int32_t)spanfunc_function_area >> 16))
#define render_9C00_end_segment           ((segment_t) ((int32_t)render_9C00_end >> 16))


//#define colormaps_spanfunc_seg_difference (spanfunc_function_area_segment - colormaps_segment)
//#define colormaps_spanfunc_off_difference (colormaps_spanfunc_seg_difference << 4)



/*
[palettebytes]         6C00:0000
spanfunc_jump_lookup   6EA0:0000
spanfunc_function_area 6EAA:0000
empty (?)              6F6D:0000

// FREEBYTES: 2352 (?)
// a lot of this will be lost to the updated drawspan func!

// R_DrawSpanCodeSize  :0xC2E


 planes change the 6800 page and remove 

 todo reverse order of colormaps and mobjpos list? 

draw code can be paged into 6800 area in plane or sprite code because mobjposlist no longer needed


colormaps             6800:0000
colfunc_jump_lookup   6A10:0000
dc_yl_lookup          6A29:0000
colfunc_function_area 6A42:0000
mobjposlist           6B14:0000  // 6AFC?? todo
[empty]               7000:0000


// FREEBYTES (?)
1488 bytes for colfunc
 we would prefer to have about 3400...   scalelight is 1632, xtoview is 660ish... free those 2 probably

*/

 


 //0x6400 BLOCK PHYSICS
#define size_blocklinks       (0 + MAX_BLOCKLINKS_SIZE)
#define size_nightmarespawns  (NIGHTMARE_SPAWN_SIZE)

#define blocklinks          ((THINKERREF __far*)    MAKE_FULL_SEGMENT(0x64000000, 0))
#define nightmarespawns     ((mapthing_t __far *)   MAKE_FULL_SEGMENT(blocklinks, size_blocklinks))

#define blocklinks_segment      ((segment_t) ((int32_t)blocklinks >> 16))
#define nightmarespawns_segment ((segment_t) ((int32_t)nightmarespawns >> 16))


//blocklinks       6400:0000
//nightmarespanws  65EC:0000
//[empty]          6000:7f8a
// 118 bytes free

// 5000-5c00 unused in physics, so menu using NPR pages for graphics. some free room in 5800.

// 0x5C00 BLOCK PHYSICS

#define MAX_REJECT_SIZE        15138u

#define size_rejectmatrix    (MAX_REJECT_SIZE)

#define rejectmatrix         ((byte __far *)      MAKE_FULL_SEGMENT(0x5C000000, 0))


/*
rejectmatrix       5C00:0000
[empty]            5FB3:0000
//FREEBYTES
1232 bytes free
*/




// ALLOCATION DEFINITIONS: INTERMISSION




// Screen 0 is the screen updated by I_Update screen.
// Screen 1 is an extra buffer.

#define screen0 ((byte __far*) 0x80000000)
#define screen1 ((byte __far*) 0x90000000)
#define screen2 ((byte __far*) 0x70000000)
#define screen3 ((byte __far*) 0x60000000)
#define screen4 ((byte __far*) 0x9C000000)


#define screen0_segment           ((segment_t) ((int32_t)screen0 >> 16))
#define screen1_segment           ((segment_t) ((int32_t)screen1 >> 16))
#define screen2_segment           ((segment_t) ((int32_t)screen2 >> 16))
#define screen3_segment           ((segment_t) ((int32_t)screen3 >> 16))
#define screen4_segment           ((segment_t) ((int32_t)screen4 >> 16))

#define fwipe_ycolumns_segment         (segment_t)0x7FA0
#define fwipe_mul160lookup_segment     (segment_t)0x7FE0

// dont put stuff in screen1 - it gets used by sprite cache

// screen1 is used during wi_stuff/intermission code, we can stick this anim data there
#define size_screen1          (64000u)

 

#define DEMO_SEGMENT 0x5000


#define demobuffer ((byte __far*) 0x50000000)

#define stringdata ((byte __far*)0x60000000)
#define stringoffsets ((uint16_t __far*)0x63C40000)

// ST_STUFF
#define ST_GRAPHICS_SEGMENT 0x7000u

// tall % sign
#define tallpercent  61304u
#define tallpercent_patch  ((byte __far *) 0x7000EF78)

#define palettebytes_size  10752
#define palettebytes ((byte __far*) 0x90000000)
// 10752 bytes / 16 = 672 or 2A0 for offset
// 5632 bytes free for something else here. can combine a page somehow somewhere later

// 38677


// 6800 plane only... combine with skytex...


#define size_cachedheight      (sizeof(fixed_t) * SCREENHEIGHT)
#define size_yslope            (sizeof(fixed_t) * SCREENHEIGHT)
#define size_cacheddistance    (sizeof(fixed_t) * SCREENHEIGHT)
#define size_cachedxstep       (sizeof(fixed_t) * SCREENHEIGHT)
#define size_cachedystep       (sizeof(fixed_t) * SCREENHEIGHT)
#define size_spanstart         (sizeof(int16_t) * SCREENHEIGHT)
#define size_distscale         (sizeof(fixed_t) * SCREENWIDTH)

// start plane only
#define cachedheight          ((fixed_t __far*)        MAKE_FULL_SEGMENT(0x50000000, 0))
#define yslope                ((fixed_t __far*)        MAKE_FULL_SEGMENT(cachedheight, size_cachedheight))
#define cacheddistance        ((fixed_t __far*)        MAKE_FULL_SEGMENT(yslope, size_yslope))
#define cachedxstep           ((fixed_t __far*)        MAKE_FULL_SEGMENT(cacheddistance, size_cacheddistance))
#define cachedystep           ((fixed_t __far*)        MAKE_FULL_SEGMENT(cachedxstep, size_cachedxstep))
#define spanstart             ((int16_t __far*)        MAKE_FULL_SEGMENT(cachedystep, size_cachedystep))
#define distscale             ((fixed_t __far*)        MAKE_FULL_SEGMENT(spanstart, size_spanstart))


#define cachedheight_segment          ((segment_t) ((int32_t)cachedheight >> 16))
#define yslope_segment                ((segment_t) ((int32_t)yslope >> 16))
#define cacheddistance_segment        ((segment_t) ((int32_t)cacheddistance >> 16))
#define cachedxstep_segment           ((segment_t) ((int32_t)cachedxstep >> 16))
#define cachedystep_segment           ((segment_t) ((int32_t)cachedystep >> 16))
#define spanstart_segment             ((segment_t) ((int32_t)spanstart >> 16))
#define distscale_segment             ((segment_t) ((int32_t)distscale >> 16))

// end plane only

//todo
#define size_drawskyplane_area        R_DrawSkyColumnCodeSize

#define drawskyplane_area             ((byte __far*) MAKE_FULL_SEGMENT(distscale, size_distscale))
#define drawskyplane_area_segment     ((segment_t) ((int32_t)drawskyplane_area >> 16))


//FREE AREA
// 5163:0000
//#define skytexture_post_bytes ((byte __far*) MAKE_FULL_SEGMENT(distscale, size_distscale))
//#define skytexture_post_segment    ((uint16_t) ((int32_t)skytexture_post_bytes >> 16))
// FREEBYTES ~ 8k free in drawskyplane still?

// 32768 bytes
//  5400:0000



// 35080 for the wad but 32k pixel data actually. 
// todo theres that one with the weird double column. confirm on that...
#define size_skytexture   32768
#define skytexture_texture_bytes ((byte __far*) MAKE_FULL_SEGMENT(0x54000000, 0))
#define skytexture_texture_segment ((segment_t) ((int32_t)skytexture_texture_bytes >> 16))



/*
cachedheight   5000:0000
yslope         5032:0000
cacheddistance 5064:0000
cachedxstep    5096:0000
cachedystep    50C8:0000
spanstart      50FA:0000
distscale      5113:0000
drawskyplane_area  5163:0000

//FREEBYTES
// 8000+ bytes free? PLANES ONLY. could be fast unrolled draw sky code, 
// and fast unrolled drawspan no tex code.


skytexture         5400:0000


*/


// note drawspan code could fit here and colormap in 0x9c00...

// main bar left
#define sbar  44024u
#define sbar_patch   ((byte __far *) 0x7000ABF8)

//#define faceback  57152u
#define faceback_patch  ((byte __far *) 0x7000DF40)

#define armsbg_patch ((byte __far *)0x7000E668u)

#define armsbg  58984u


#define size_menugraphics      0x0000
#define size_menugraphcispage4 0xAC64
#define size_menuoffsets    ((sizeof(uint16_t) * NUM_MENU_ITEMS))

#define menugraphicspage0   (byte __far* )0x50000000
#define menugraphicspage4   (byte __far* )0x64000000
#define menuoffsets         ((uint16_t __far*)  MAKE_FULL_SEGMENT(menugraphicspage4, size_menugraphcispage4 ))

#define menuoffsets_segment  ((segment_t) ((int32_t)menuoffsets >> 16))


// menugraphicspage0  5000:0000
// [empty]            ????      todo
// menugraphicspage4  6400:0000
// menuoffsets        6EC7:0000
// [empty]            6ECD:0000 ?
//FREEBYTES 4992 in menu page 4. Eventually move menu code here?
// ends at AC64. are there other spare graphics to drop here?


#define NUM_WI_ITEMS 28
#define NUM_WI_ANIM_ITEMS 30

#define MAX_LEVEL_COMPLETE_GRAPHIC_SIZE 0x1278
#define size_level_finished_graphic (MAX_LEVEL_COMPLETE_GRAPHIC_SIZE * 2)

#define size_wigraphicspage0      0x4CF0
#define size_wigraphicslevelname  size_level_finished_graphic

// 4CF0 in size?
// 4220 doom2



#define wigraphicslevelname  ((byte __far* )0x78000000)
#define wianimspage          ((byte __far* )0x60000000)


// maximum size for level complete graphic, times two. in theory could be measured smaller? we have enough space though...
// largest level complete graphic in ultimate doom somewhere..



#define size_wioffsets        (sizeof(uint16_t) * NUM_WI_ITEMS)
#define size_wianimoffsets    (sizeof(uint16_t) * NUM_WI_ANIM_ITEMS)


#define wigraphicspage0  ((byte __far* )     0x70000000) 
#define wianim_codespace ((byte __far*)      MAKE_FULL_SEGMENT(wigraphicspage0, size_wigraphicspage0))
#define wianim_7000_end  ((byte __far*)      MAKE_FULL_SEGMENT(wianim_codespace, WI_StuffCodeSize))


#define wioffsets        ((uint16_t __far*)   MAKE_FULL_SEGMENT(0x78000000, size_level_finished_graphic))
#define wianimoffsets    ((uint16_t __far*)   MAKE_FULL_SEGMENT(wioffsets, size_wioffsets))


#define wioffsets_segment            ((segment_t) ((int32_t)wioffsets >> 16))
#define wianimoffsets_segment        ((segment_t) ((int32_t)wianimoffsets >> 16))
#define wigraphicspage0_segment      ((segment_t) ((int32_t)wigraphicspage0 >> 16))
#define wigraphicslevelname_segment  ((segment_t) ((int32_t)wigraphicslevelname >> 16))
#define wianimspage_segment          ((segment_t) ((int32_t)wianimspage >> 16))
#define wianim_codespace_segment     ((segment_t) ((int32_t)wianim_codespace >> 16))
#define wianim_7000_end_segment      ((segment_t) ((int32_t)wianim_7000_end >> 16))


// todo make this work
/*
#define lnodex           ((int16_t __far*)   MAKE_FULL_SEGMENT(0x77000000, 0))
#define lnodey           ((int16_t __far*)   MAKE_FULL_SEGMENT(lnodex,          size_lnodex))
#define epsd0animinfo    ((wianim_t __far*)  MAKE_FULL_SEGMENT(lnodey,          size_lnodey))
#define epsd1animinfo    ((wianim_t __far*)  MAKE_FULL_SEGMENT(epsd0animinfo,   size_epsd0animinfo))
#define epsd2animinfo    ((wianim_t __far*)  MAKE_FULL_SEGMENT(epsd1animinfo,   size_epsd1animinfo))
#define wigraphics       ((int8_t __far*)    MAKE_FULL_SEGMENT(epsd2animinfo,   size_epsd2animinfo))
#define pars             ((int16_t __far*)   MAKE_FULL_SEGMENT(wigraphics,      size_wigraphics))
#define cpars            ((int16_t __far*)   MAKE_FULL_SEGMENT(pars,            size_pars))
*/


/*

This area used during intermission task

7000:0000  wigraphicspage0
74CF0:0000  lnodex
74D3:0000  lnodey
74D7:0000  epsd0animinfo
74E1:0000  epsd1animinfo
74EA:0000  epsd2animinfo
74F0:01FC  wigraphics
7500:0000  pars
7505:0000  cpars
7509:0000  wianim_codespace
75D9?:0000  [empty]
// still 8816 bytes free. not much to use it on?


*/




// ALLOCATION DEFINITIONS: RENDER




// RENDER 0x7800 - 0x8000 - 0x8FFF


// openings are A000 in size. 0x7800 can be just that. Note that 0x2000 carries over to 8000


/*
openings                 7800:0000
negonearray_offset       7800:a000  or 8000:2000
screenheightarray_offset 7800:A500  or 8000:2500
[done]                   7800:AA00  or 8000:2A00

//aa00
*/
// LEAVE ALL THESE in 0x7800 SEGMENT 

#define size_openings               sizeof(int16_t) * MAXOPENINGS
//8200
#define offset_openings             0
#define offset_negonearray          size_openings               
//8228
#define offset_screenheightarray    offset_negonearray          + (sizeof(int16_t) * SCREENWIDTH)
//8250
#define offset_floorclip            offset_screenheightarray    + (sizeof(int16_t) * SCREENWIDTH)
#define offset_ceilingclip          offset_floorclip            + (sizeof(int16_t) * SCREENWIDTH)

// todo use this to connect below
// #define offset_                                     + (sizeof(int16_t) * SCREENWIDTH)

#define openings             ((uint16_t __far*)         (0x78000000 + offset_openings))
#define negonearray          ((int16_t __far*)          (0x78000000 + offset_negonearray))
#define screenheightarray    ((int16_t __far*)          (0x78000000 + offset_screenheightarray))
#define floorclip            ((int16_t __far*)          (0x78000000 + offset_floorclip))
#define ceilingclip          ((int16_t __far*)          (0x78000000 + offset_ceilingclip))

#define floorclip_paragraph_aligned       ((int16_t __far*)          MAKE_FULL_SEGMENT(openings, offset_floorclip))

// todo these are wrong i guess.
#define openings_segment             ((segment_t) ((int32_t)openings >> 16))
#define negonearray_segment          ((segment_t) ((int32_t)negonearray >> 16))
#define screenheightarray_segment    ((segment_t) ((int32_t)screenheightarray >> 16))
#define floorclip_segment            ((segment_t) ((int32_t)floorclip >> 16))
#define ceilingclip_segment          ((segment_t) ((int32_t)ceilingclip >> 16))
#define floorclip_paragraph_aligned_segment       ((segment_t) ((int32_t)floorclip_paragraph_aligned >> 16))


//negonearray       = 7800:A000 or 8202
//screenheightarray = 7800:A280 or 822A
//floorclip         = 7800:A500 or 8252
//ceilingclip       = 7800:A780 or 827A


// LEAVE ALL THESE in 0x7800 SEGMENT 


#define FUZZTABLE                         50 

//todo programmattically do this
#define size_leftover_openings_arrays     (0x2A00 + 0x20)

#define size_texturewidthmasks  MAX_TEXTURES * sizeof(uint8_t)
#define size_zlight             sizeof(uint8_t) * (LIGHTLEVELS * MAXLIGHTZ)
#define size_xtoviewangle       (sizeof(fineangle_t) * (SCREENWIDTH + 1))
#define size_spriteoffsets      (sizeof(uint8_t) * MAX_SPRITE_LUMPS)
#define size_patchpage          MAX_PATCHES * sizeof(uint8_t)
#define size_patchoffset        MAX_PATCHES * sizeof(uint8_t)

#define texturewidthmasks       ((uint8_t  __far*)        MAKE_FULL_SEGMENT(0x80000000 , size_leftover_openings_arrays))
#define zlight                  ((uint8_t far*)           MAKE_FULL_SEGMENT(texturewidthmasks , size_texturewidthmasks))
#define xtoviewangle            ((fineangle_t __far*)     MAKE_FULL_SEGMENT(zlight , size_zlight))
#define spriteoffsets           ((uint8_t __far*)         MAKE_FULL_SEGMENT(xtoviewangle , size_xtoviewangle))
#define patchpage               ((uint8_t __far*)         MAKE_FULL_SEGMENT(spriteoffsets, size_spriteoffsets)) 
#define patchoffset             ((uint8_t __far*)         (((int32_t)patchpage) + size_patchpage))

#define texturewidthmasks_segment       ((segment_t) ((int32_t)texturewidthmasks >> 16))
#define zlight_segment                  ((segment_t) ((int32_t)zlight >> 16))
#define xtoviewangle_segment            ((segment_t) ((int32_t)xtoviewangle >> 16))
#define spriteoffsets_segment           ((segment_t) ((int32_t)spriteoffsets >> 16))
#define patchpage_segment               ((segment_t) ((int32_t)patchpage >> 16))
#define patchoffset_segment             ((segment_t) ((int32_t)patchoffset >> 16))


//#define patchoffset             ((uint8_t __far*)         MAKE_FULL_SEGMENT(patchpage, size_patchpage))

#define visplanes_8400          ((visplane_t __far*)      (0x84000000 ))
#define visplanes_8800          ((visplane_t __far*)      (0x88000000 ))
#define visplanes_8C00          ((visplane_t __far*)      (0x8C000000 ))
/*
  
texturewidthmasks           82A2:0000
zlight                      82BD:0000
xtoviewangle                833D:0000
spriteoffsets               8366:0000
patchpage                   83BD:0000
patchoffset                 83BD:01DC
[empty]                     83F9:0000



// 112 bytes free
*/




// RENDER REMAPPING

// RENDER 0x7800 - 0x7FFF DATA NOT USED IN PLANES


//NOW

// todo: also extend flatcache down to 6000?
// also extend 

//              bsp     plane     sprite
// 9800-9FFF      COLORMAPS       sprcache
// 9000-97FF    DATA1    DATA1    sprcache
// 8000-8FFF    VISPLANES_DATA    COLORMAPS_DATA
// 7800-7FFF    DATA2 flatcache   DATA2
// 7000-77FF    DATA3 flatcache   DATA1   
// 6000-6FFF  TEXTURE   -----     TEXTURE
// 5000-5FFF  TEXTURE sky texture TEXTURE
// 4000-4FFF        -- no changes --


//WAS

//              bsp     plane     sprite
// 9000-9FFF  TEXTURE sky texture TEXTURE
// 8000-8FFF    VISPLANES_DATA    COLORMAPS_DATA
// 7800-7FFF    DATA  flatcache   DATA
// 7000-77FF    DATA  flatcache   sprcache
// 6800-6FFF    COLORMAPS_DATA    sprcache
// 4000-67FF        -- no changes --



// RENDER 0x7000-0x77FF DATA - USED ONLY IN BSP ... 13k + 8k ... 10592 free

// complicated... 
// nodes_render is larger for ultimate doom but sprites are smaller.
// in doom2, etc - sprites etc are larger but nodes are smaller.
// they can always fit in the 32k at 0x7000-7800, but you cant
// lazily assign worst case and make it always fit.
// It fails filling in the allotted space by only 32 bytes.
// so shift the middle element (spritewidths)  by 32 bytes at runtime.
// this means spritewidths is a variable and not a constant, 
// but it also means the ultimate doom version will work with either wad


#define size_nodes_render      MAX_NODES_RENDER_SIZE
#define size_spritedefs        16114u
#define size_spritewidths      (sizeof(uint8_t) * MAX_SPRITE_LUMPS)

// first element
#define nodes_render          ((node_render_t __far*)  MAKE_FULL_SEGMENT(0x70000000, 0))

//middle element
#define spritewidths_ult          ((uint8_t __far*)        MAKE_FULL_SEGMENT(nodes_render, size_nodes_render))
#define spritewidths_normal       ((uint8_t __far*)        MAKE_FULL_SEGMENT(nodes_render, size_nodes_render - 0x20))

//last element
#define sprites               ((spritedef_t __far*)    MAKE_FULL_SEGMENT(0x74100000, 0))
#define spritedefs_bytes      ((byte __far*)           sprites)


#define spritewidths_ult_segment    ((segment_t)     ((int32_t)spritewidths_ult >> 16))
#define spritewidths_normal_segment ((segment_t)     ((int32_t)spritewidths_normal >> 16))
#define sprites_segment             ((segment_t)     ((int32_t)sprites >> 16))

#define nodes_render_segment 0x7000



/*

nodes_render        7000:0000
spritewidths_ult    73BB:0000
spritewidths_normal 73B9:0000
spritedefs_bytes    7410:0000
[empty]             7800:0000 

0 bytes free
*/


// RENDER 0x6800-0x6FFF DATA - USED ONLY IN PLANE/BSP... PAGED OUT IN SPRITE REGION
// same as physics 6800-6fff


// carried over from below - mostly visplanes


// RENDER 0x5000-0x67FF DATA     


// size_texturecolumnofs_bytes is technically 80480. Takes up whole 0x5000 region, 14944 left over in 0x6000...



// all of these masked sizes are their maximums in doom1.
#define MAX_MASKED_TEXTURES 12


// todo this is actually smaller than 1424 again? like 12xx.
#define size_texturecolumnlumps_bytes  (1424u * sizeof(int16_t))
#define size_texturedefs_bytes         8756u
#define size_spritetopoffsets          (sizeof(int8_t) * MAX_SPRITE_LUMPS)
#define size_texturedefs_offset        (MAX_TEXTURES * sizeof(uint16_t))
#define size_masked_lookup             (MAX_TEXTURES * sizeof(uint8_t))
#define size_patchwidths               (MAX_PATCHES * sizeof(uint16_t))
#define size_patchheights              (MAX_PATCHES * sizeof(uint8_t))
#define size_finetangentinner          2048u * sizeof(int32_t)
#define size_drawsegs                  (sizeof(drawseg_t) * (MAXDRAWSEGS+1))
#define size_drawsegs_PLUS_EXTRA       (sizeof(drawseg_t) * (MAXDRAWSEGS+2))


// size_texturedefs_bytes 0x6184... 0x6674

// this is 9000-9800 for bsp/plane
//. then   7000-7800 for sprite.

#define texturecolumnlumps_bytes   ((int16_t_union __far*)     (0x90000000 ))
#define texturedefs_bytes          ((byte __far*)              MAKE_FULL_SEGMENT(texturecolumnlumps_bytes, size_texturecolumnlumps_bytes))
#define spritetopoffsets           ((int8_t __far*)            MAKE_FULL_SEGMENT(texturedefs_bytes,        size_texturedefs_bytes))
#define texturedefs_offset         ((uint16_t  __far*)         MAKE_FULL_SEGMENT(spritetopoffsets,         size_spritetopoffsets))
#define masked_lookup              ((uint8_t __far*)           MAKE_FULL_SEGMENT(texturedefs_offset,       size_texturedefs_offset))
#define patchwidths                ((uint16_t  __far*)         MAKE_FULL_SEGMENT(masked_lookup,            size_masked_lookup))
#define patchheights               ((uint8_t   __far*)         MAKE_FULL_SEGMENT(patchwidths,              size_patchwidths))
#define drawsegs_BASE              ((drawseg_t __far*)         MAKE_FULL_SEGMENT(patchheights,             size_patchheights))
#define drawsegs_PLUSONE           ((drawseg_t __far*)         (drawsegs_BASE          + 1))
#define finetangentinner           ((int32_t __far*)           MAKE_FULL_SEGMENT(drawsegs_BASE   ,         size_drawsegs_PLUS_EXTRA))
#define render_9800_end            ((uint8_t __far*)           MAKE_FULL_SEGMENT(finetangentinner,         size_finetangentinner))


#define texturecolumnlumps_bytes_segment ((segment_t) ((int32_t)texturecolumnlumps_bytes >> 16))
#define texturedefs_bytes_segment        ((segment_t) ((int32_t)texturedefs_bytes >> 16))
#define spritetopoffsets_segment         ((segment_t) ((int32_t)spritetopoffsets >> 16))
#define texturedefs_offset_segment       ((segment_t) ((int32_t)texturedefs_offset >> 16))
#define masked_lookup_segment            ((segment_t) ((int32_t)masked_lookup >> 16))
#define patchwidths_segment              ((segment_t) ((int32_t)patchwidths >> 16))
#define patchheights_segment             ((segment_t) ((int32_t)patchheights >> 16))
#define drawsegs_BASE_segment            ((segment_t) ((int32_t)drawsegs_BASE >> 16))
#define finetangentinner_segment         ((segment_t) ((int32_t)finetangentinner >> 16))
#define render_9800_end_segment          ((segment_t) ((int32_t)render_9800_end >> 16))


#define texturecolumnlumps_bytes_7000   ((int16_t_union __far*)     (0x70000000 ))
#define texturedefs_bytes_7000          ((byte __far*)              MAKE_FULL_SEGMENT(texturecolumnlumps_bytes_7000, size_texturecolumnlumps_bytes))
#define spritetopoffsets_7000           ((int8_t __far*)            MAKE_FULL_SEGMENT(texturedefs_bytes_7000,        size_texturedefs_bytes))
#define texturedefs_offset_7000         ((uint16_t  __far*)         MAKE_FULL_SEGMENT(spritetopoffsets_7000,         size_spritetopoffsets))
#define masked_lookup_7000              ((uint8_t __far*)           MAKE_FULL_SEGMENT(texturedefs_offset_7000,       size_texturedefs_offset))
#define patchwidths_7000                ((uint16_t  __far*)         MAKE_FULL_SEGMENT(masked_lookup_7000,            size_masked_lookup))
#define patchheights_7000               ((uint8_t   __far*)         MAKE_FULL_SEGMENT(patchwidths_7000,              size_patchwidths))
#define drawsegs_BASE_7000              ((drawseg_t __far*)         MAKE_FULL_SEGMENT(patchheights_7000,             size_patchheights))
#define drawsegs_PLUSONE_7000           ((drawseg_t __far*)         (drawsegs_BASE_7000          + 1))
#define finetangentinner_7000           ((int32_t __far*)           MAKE_FULL_SEGMENT(drawsegs_BASE_7000   ,         size_drawsegs_PLUS_EXTRA))
#define render_9800_end_7000            ((uint8_t __far*)           MAKE_FULL_SEGMENT(finetangentinner_7000,         size_finetangentinner))

#define texturecolumnlumps_bytes_6000   ((int16_t_union __far*)     (0x60000000 ))
#define texturedefs_bytes_6000          ((byte __far*)              MAKE_FULL_SEGMENT(texturecolumnlumps_bytes_6000, size_texturecolumnlumps_bytes))
#define spritetopoffsets_6000           ((int8_t __far*)            MAKE_FULL_SEGMENT(texturedefs_bytes_6000,        size_texturedefs_bytes))
#define texturedefs_offset_6000         ((uint16_t  __far*)         MAKE_FULL_SEGMENT(spritetopoffsets_6000,         size_spritetopoffsets))
#define masked_lookup_6000              ((uint8_t __far*)           MAKE_FULL_SEGMENT(texturedefs_offset_6000,       size_texturedefs_offset))
#define patchwidths_6000                ((uint16_t  __far*)         MAKE_FULL_SEGMENT(masked_lookup_6000,            size_masked_lookup))
#define patchheights_6000               ((uint8_t   __far*)         MAKE_FULL_SEGMENT(patchwidths_6000,              size_patchwidths))
#define drawsegs_BASE_6000              ((drawseg_t __far*)         MAKE_FULL_SEGMENT(patchheights_6000,             size_patchheights))
#define drawsegs_PLUSONE_6000           ((drawseg_t __far*)         (drawsegs_BASE_6000          + 1))
#define finetangentinner_6000           ((int32_t __far*)           MAKE_FULL_SEGMENT(drawsegs_BASE_6000   ,         size_drawsegs_PLUS_EXTRA))
#define render_9800_end_6000            ((uint8_t __far*)           MAKE_FULL_SEGMENT(finetangentinner_6000,         size_finetangentinner))

#define drawsegs_BASE_segment_7000      ((segment_t) ((int32_t)drawsegs_BASE_7000 >> 16))
#define masked_lookup_segment_7000      ((segment_t) ((int32_t)masked_lookup_7000 >> 16))
// texturecolumnlumps_bytes   9000:0000
// texturedefs_bytes          90B2:0000
// spritetopoffsets           92A6:0000
// texturedefs_offset         932D:0000
// masked_lookup              9363:0000
// masked_headers             937E:0000
// patchwidths                9384:0000
// patchheights               93AC:0000

// drawsegs_BASE              93DE:0000
// drawsegs_PLUSONE           93DE:0020
// finetangentinner           95DC:0000

// [empty]                    97DC:0000


//FREEBYTES
// 576 bytes free till 6000:8000
// or 900-1000 ish if we reshrink texturecolumnlumps_bytes
// some masked code can easily go here? Maybe more if drawsegs maxsegs goes back to 128 from 256?





// 0x4000 BLOCK RENDER
#define FUZZ_LOOP_LENGTH              16

#define size_segs_render              MAX_SEGS_RENDER_SIZE
#define size_seg_normalangles         (MAX_SEGS * (sizeof(fineangle_t)))
#define size_sides_render             MAX_SIDES_RENDER_SIZE
// plus one to make room for overflow vissprite
#define size_vissprites               (sizeof(vissprite_t) * (MAXVISSPRITES+1))
#define size_player_vissprites        (sizeof(vissprite_t) * 2)
#define size_texturepatchlump_offset  (MAX_TEXTURES * sizeof(uint16_t))
#define size_visplaneheaders          (sizeof(visplaneheader_t) * MAXEMSVISPLANES)
#define size_visplanepiclights        (sizeof(visplanepiclight_t) * MAXEMSVISPLANES)
#define size_fuzzoffset               ((FUZZTABLE + (FUZZ_LOOP_LENGTH - 1)) * sizeof(int16_t))
#define size_scalelightfixed          (sizeof(uint8_t) * (MAXLIGHTSCALE))
#define size_scalelight               (sizeof(uint8_t) * (LIGHTLEVELS * MAXLIGHTSCALE))
#define size_patch_sizes              (MAX_PATCHES * sizeof(uint16_t))
#define size_viewangletox             (sizeof(int16_t) * (FINEANGLES / 2))

#define size_states_render            (sizeof(state_render_t) * NUMSTATES)
#define size_flatindex                (sizeof(uint8_t) * MAX_FLATS)
#define size_spritepage               (MAX_SPRITE_LUMPS * sizeof(uint8_t))
#define size_spriteoffset             (MAX_SPRITE_LUMPS * sizeof(uint8_t))
#define size_texturecollength         (MAX_TEXTURES * sizeof(uint8_t))

#define size_texturecompositesizes    (MAX_TEXTURES * sizeof(uint16_t))
#define size_compositetexturepage     (MAX_TEXTURES * sizeof(uint8_t))
#define size_compositetextureoffset   (MAX_TEXTURES * sizeof(uint8_t))


#define segs_render_far             ((seg_render_t  __far*)      MAKE_FULL_SEGMENT(0x40000000                  , 0))
#define seg_normalangles_far        ((fineangle_t  __far*)       MAKE_FULL_SEGMENT(segs_render_far             , size_segs_render))
#define sides_render_far            ((side_render_t __far*)      MAKE_FULL_SEGMENT(seg_normalangles_far        , size_seg_normalangles))
#define vissprites_far              ((vissprite_t __far*)        MAKE_FULL_SEGMENT(sides_render_far            , size_sides_render))
#define player_vissprites_far       ((vissprite_t __far*)        MAKE_FULL_SEGMENT(vissprites_far              , size_vissprites))
#define texturepatchlump_offset_far ((uint16_t __far*)           MAKE_FULL_SEGMENT(player_vissprites_far       , size_player_vissprites))
#define visplaneheaders_far         ((visplaneheader_t __far*)   MAKE_FULL_SEGMENT(texturepatchlump_offset_far , size_texturepatchlump_offset))
#define visplanepiclights_far       ((visplanepiclight_t __far*) MAKE_FULL_SEGMENT(visplaneheaders_far         , size_visplaneheaders))
#define scalelightfixed_far         ((uint8_t __far*)            MAKE_FULL_SEGMENT(visplanepiclights_far       , size_visplanepiclights))
#define scalelight_far              ((uint8_t __far*)            MAKE_FULL_SEGMENT(scalelightfixed_far         , size_scalelightfixed))
#define patch_sizes_far             ((uint16_t __far*)           MAKE_FULL_SEGMENT(scalelight_far              , size_scalelight))
#define viewangletox                ((int16_t __far*)            MAKE_FULL_SEGMENT(patch_sizes_far             , size_patch_sizes))
// offset of a drawseg so we can subtract drawseg from drawsegs for a certain potential loop condition...
#define states_render               ((state_render_t __far*)     MAKE_FULL_SEGMENT(viewangletox            , size_viewangletox))
#define flatindex                   ((uint8_t __far*)            MAKE_FULL_SEGMENT(states_render           , size_states_render))
#define spritepage                  ((uint8_t __far*)            MAKE_FULL_SEGMENT(flatindex               , size_flatindex))
#define spriteoffset                ((uint8_t __far*)            (((int32_t)spritepage)                    + size_spritepage))

#define texturecollength            ((uint8_t __far*)            MAKE_FULL_SEGMENT(spritepage,               (size_spriteoffset + size_spritetopoffsets)))

#define texturecompositesizes   ((uint16_t __far*)               MAKE_FULL_SEGMENT(texturecollength,         size_texturecollength))
#define compositetexturepage    ((uint8_t __far*)                MAKE_FULL_SEGMENT(texturecompositesizes   , size_texturecompositesizes))
#define compositetextureoffset  ((uint8_t __far*)                (((int32_t)compositetexturepage)          + size_compositetexturepage))



#define segs_render_segment               ((segment_t) ((int32_t)segs_render_far >> 16))
#define seg_normalangles_segment          ((segment_t) ((int32_t)seg_normalangles_far >> 16))
#define sides_render_segment              ((segment_t) ((int32_t)sides_render_far >> 16))
#define vissprites_segment                ((segment_t) ((int32_t)vissprites_far >> 16))
#define player_vissprites_segment         ((segment_t) ((int32_t)player_vissprites_far >> 16))
#define texturepatchlump_offset_segment   ((segment_t) ((int32_t)texturepatchlump_offset_far >> 16))
#define visplaneheaders_segment           ((segment_t) ((int32_t)visplaneheaders_far >> 16))
#define visplanepiclights_segment         ((segment_t) ((int32_t)visplanepiclights_far >> 16))
#define scalelightfixed_segment           ((segment_t) ((int32_t)scalelightfixed_far >> 16))
#define scalelight_segment                ((segment_t) ((int32_t)scalelight_far >> 16))
#define patch_sizes_segment               ((segment_t) ((int32_t)patch_sizes_far >> 16))
#define viewangletox_segment              ((segment_t) ((int32_t)viewangletox >> 16))
#define states_render_segment             ((segment_t) ((int32_t)states_render >> 16))
#define flatindex_segment                 ((segment_t) ((int32_t)flatindex >> 16))
#define spritepage_segment                ((segment_t) ((int32_t)spritepage >> 16))
#define texturecollength_segment          ((segment_t) ((int32_t)texturecollength >> 16))
#define texturecompositesizes_segment     ((segment_t) ((int32_t)texturecompositesizes >> 16))
#define compositetexturepage_segment      ((segment_t) ((int32_t)compositetexturepage >> 16))


#define segs_render             ((seg_render_t  __near*)      0x4000)
#define seg_normalangles        ((fineangle_t  __near*)       (0x4000 + ((seg_normalangles_segment        - segs_render_segment)<<4)))
#define sides_render            ((side_render_t __near*)      (0x4000 + ((sides_render_segment            - segs_render_segment)<<4)))
#define vissprites              ((vissprite_t __near*)        (0x4000 + ((vissprites_segment              - segs_render_segment)<<4)))
#define player_vissprites       ((vissprite_t __near*)        (0x4000 + ((player_vissprites_segment       - segs_render_segment)<<4)))
#define texturepatchlump_offset ((uint16_t __near*)           (0x4000 + ((texturepatchlump_offset_segment - segs_render_segment)<<4)))
#define visplaneheaders         ((visplaneheader_t __near*)   (0x4000 + ((visplaneheaders_segment         - segs_render_segment)<<4)))
#define visplanepiclights       ((visplanepiclight_t __near*) (0x4000 + ((visplanepiclights_segment       - segs_render_segment)<<4)))
#define scalelightfixed         ((uint8_t __near*)            (0x4000 + ((scalelightfixed_segment         - segs_render_segment)<<4)))
#define scalelight              ((uint8_t __near*)            (0x4000 + ((scalelight_segment              - segs_render_segment)<<4)))
#define patch_sizes             ((uint16_t __near*)           (0x4000 + ((patch_sizes_segment             - segs_render_segment)<<4)))


#define SCALE_LIGHT_OFFSET_IN_FIXED_SCALELIGHT (16 * (scalelight_segment - scalelightfixed_segment))

// need to undo prior drawseg_t shenanigans
//0x4FBEE

// used during p_setup
#define segs_render_9000      ((seg_render_t __far*)       (0x90000000 + 0))
#define seg_normalangles_9000 ((fineangle_t  __far*)       MAKE_FULL_SEGMENT(segs_render_9000             , size_segs_render))
#define sides_render_9000     ((side_render_t __far*)      MAKE_FULL_SEGMENT(seg_normalangles_9000        , size_seg_normalangles))

#define segs_render_9000_segment      ((segment_t) ((int32_t)segs_render_9000 >> 16))
#define seg_normalangles_9000_segment ((segment_t) ((int32_t)seg_normalangles_9000 >> 16))
#define sides_render_9000_segment     ((segment_t) ((int32_t)sides_render_9000 >> 16))


/*

segs_render             4000:0000   4000
seg_normalangles        4580:0000   9800
sides_render            46E0:0000   AE00
vissprites              4967:0000   D670
player_vissprites       4AAA:0000   EAA0
texturepatchlump_offset 4AAF:0000   EAF0
visplaneheaders         4AE5:0000   EE50
visplanepiclights       4B24:0000   F240
fuzzoffset              4B34:0000   F340    ; todo removed update
scalelightfixed         4B3D:0000   F3D0
scalelight              4B40:0000   F400
patch_sizes             4B70:0000   F700
viewangletox            4BAC:0000   FAC0
// 1392 bytes here?
[near range over]       

states_render           4DAC:0000
flatindex               4E25:0000
spritepage              4E2F:0000
spriteoffset            4E2F:0565
texturecollength        4EDC:0000
texturecompositesizes   4EF7:0000
compositetexturepage    4F2C:0000
compositetextureoffset  4F2C:01AC
[done]                  4F64:0000
//FREEBYTES
2496 bytes free


*/


#define lumpinfo5000 ((lumpinfo_t __far*) 0x54000000)
#define lumpinfo9000 ((lumpinfo_t __far*) 0x94000000)
#define lumpinfoinit ((lumpinfo_t __far*) uppermemoryblock)


#define ANIMS_DOOMDATA_SIZE     0x1B5
#define SPLIST_DOOMDATA_SIZE    0x2B2
#define SWITCH_DOOMDATA_SIZE    0x334
#define MENUDATA_DOOMDATA_SIZE  0x19E
#define TANTOA_DOOMDATA_SIZE    0x2004

// 0
#define ANIMS_DOOMDATA_OFFSET 0
// 0x1B5
#define SPLIST_DOOMDATA_OFFSET ANIMS_DOOMDATA_OFFSET + ANIMS_DOOMDATA_SIZE
// 0x467
#define SWITCH_DOOMDATA_OFFSET SPLIST_DOOMDATA_OFFSET + SPLIST_DOOMDATA_SIZE
// 0x79b
#define MENUDATA_DOOMDATA_OFFSET SWITCH_DOOMDATA_OFFSET + SWITCH_DOOMDATA_SIZE
// 0x939
#define TANTOA_DOOMDATA_OFFSET MENUDATA_DOOMDATA_OFFSET + MENUDATA_DOOMDATA_SIZE
// 0x293D
#define DATA_DOOMDATA_OFFSET   TANTOA_DOOMDATA_OFFSET + TANTOA_DOOMDATA_SIZE


 

#endif

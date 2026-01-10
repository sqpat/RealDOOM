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
//      Zone Memory Allocation, perhaps NeXT ObjectiveC inspired.
//      Remark: this was the only stuff that, according
//       to John Carmack, might have been useful for
//       Quake.
//


#ifndef __Z_ZONE__
#define __Z_ZONE__

#include <stdio.h>
#include "doomtype.h"
#include "doomdef.h"
 
  
 
// Note: a memref of 0 refers to the empty (size = 0) 'head' of doubly linked list
// managing the pages, and this index can never be handed out, so it's safe to use
// as a 'null' or unused memref.
#define NULL_THINKERREF 0

 



// These are WAD maxes and corresponds to doom2 max values
#define MAX_TEXTURES 428
#define MAX_PATCHES 476
#define MAX_FLATS 151

// These are WAD maxes and corresponds to doom2/tnt/plutonia max values
//#define MAX_TEXTURES 585
//#define MAX_PATCHES 664
//#define MAX_FLATS 151


// textures     585 for tnt   550 for plutonia
// patches      664 for tnt   546 for plutonia
// flats        147 for tnt   147 for plutonia

#define MAX_SPRITE_LUMPS 1381

// sprites 1381 for tnt       1381 for plutonia

#define MAX_THINKERS 840
#define SPRITE_ALLOCATION_LIST_SIZE 150

#define TEXTURE_CACHE_OVERHEAD_SIZE NUM_TEXTURE_PAGES + (numtextures * 2)
#define SPRITE_CACHE_OVERHEAD_SIZE NUM_SPRITE_CACHE_PAGES + (numspritelumps * 2)
#define PATCH_CACHE_OVERHEAD_SIZE NUM_PATCH_CACHE_PAGES + (numpatches * 2)
#define FLAT_CACHE_OVERHEAD_SIZE numflats
#define CACHE_OVERHEAD_SIZE (TEXTURE_CACHE_OVERHEAD_SIZE + SPRITE_CACHE_OVERHEAD_SIZE + PATCH_CACHE_OVERHEAD_SIZE + FLAT_CACHE_OVERHEAD_SIZE)



#define PAGE_9000_OFFSET + 0
#define PAGE_9400_OFFSET + 1
#define PAGE_9800_OFFSET + 2
#define PAGE_9C00_OFFSET + 3

#define PAGE_8000_OFFSET - 4
#define PAGE_8400_OFFSET - 3
#define PAGE_8800_OFFSET - 2
#define PAGE_8C00_OFFSET - 1

#define PAGE_7000_OFFSET - 8
#define PAGE_7400_OFFSET - 7
#define PAGE_7800_OFFSET - 6
#define PAGE_7C00_OFFSET - 5

#define PAGE_6000_OFFSET - 12
#define PAGE_6400_OFFSET - 11
#define PAGE_6800_OFFSET - 10
#define PAGE_6C00_OFFSET - 9

#define PAGE_5000_OFFSET - 16
#define PAGE_5400_OFFSET - 15
#define PAGE_5800_OFFSET - 14
#define PAGE_5C00_OFFSET - 13

#define PAGE_4000_OFFSET - 20
#define PAGE_4400_OFFSET - 19
#define PAGE_4800_OFFSET - 18
#define PAGE_4C00_OFFSET - 17

#define INDEXED_PAGE_FRAME_OFFSET (0)


// Null page register. Represents 'map this to its original conventional page"
// This should be -1 per EMS spec, but in the case of hardcoded
// chipset code - we can make the asm faster by preprocessing the expected values in there
// because the chipsets don't necessarily expect -1

// Unindexed means it doesnt have the +pagenum9000 at the start included...

#ifdef __SCAMP_BUILD
#define EMS_MEMORY_PAGE_OFFSET  0x0050
#define SCAMP_PAGE_9000_OFFSET   0x20
#define _NPR(a)            a + SCAMP_PAGE_9000_OFFSET + 4
// todo should this be minus?
#define _EPR(a)            a + EMS_MEMORY_PAGE_OFFSET
#define CHIPSET_PAGE_9000 0x20
#define EMS_AUTOINCREMENT_FLAG 0x40
#elif defined(__SCAT_BUILD)
// includes turn high bit on
#define EMS_MEMORY_PAGE_OFFSET 0x8080
#define _NPR(a)           0x03FF
#define _EPR(a)           a + EMS_MEMORY_PAGE_OFFSET
#define CHIPSET_PAGE_9000 0x14
#define EMS_AUTOINCREMENT_FLAG 0x80
#elif defined(__HT18_BUILD)
#define EMS_MEMORY_PAGE_OFFSET 0x0280
#define _NPR(a)           0x0000
#define _EPR(a)           a + EMS_MEMORY_PAGE_OFFSET
#define CHIPSET_PAGE_9000 0x14
#define EMS_AUTOINCREMENT_FLAG 0x80

#else
#define EMS_MEMORY_PAGE_OFFSET 0x0000
#define _NPR(a) 0xFFFF

// EMS page register. 0-n per EMS spec, but in the case of hardcoded
// chipset code - we preadd the EMS memory boundary into this value so we dont have to add in asm
#define _EPR(a) a
#endif


void __near Z_InitEMS(void);
//void Z_InitUMB(void);
void __near Z_QuickMapUnmapAll();
void __far Z_SetOverlay(int8_t wipeId);

 
#if defined(__CH_BLD)

    #define pagenum9000 CHIPSET_PAGE_9000

    #define INDEXED_PAGE_9000_OFFSET (PAGE_9000_OFFSET + CHIPSET_PAGE_9000)
    #define INDEXED_PAGE_9400_OFFSET (PAGE_9400_OFFSET + CHIPSET_PAGE_9000)
    #define INDEXED_PAGE_9800_OFFSET (PAGE_9800_OFFSET + CHIPSET_PAGE_9000)
    #define INDEXED_PAGE_9C00_OFFSET (PAGE_9C00_OFFSET + CHIPSET_PAGE_9000)

    #define INDEXED_PAGE_8000_OFFSET (PAGE_8000_OFFSET + CHIPSET_PAGE_9000)
    #define INDEXED_PAGE_8400_OFFSET (PAGE_8400_OFFSET + CHIPSET_PAGE_9000)
    #define INDEXED_PAGE_8800_OFFSET (PAGE_8800_OFFSET + CHIPSET_PAGE_9000)
    #define INDEXED_PAGE_8C00_OFFSET (PAGE_8C00_OFFSET + CHIPSET_PAGE_9000)

    #define INDEXED_PAGE_7000_OFFSET (PAGE_7000_OFFSET + CHIPSET_PAGE_9000)
    #define INDEXED_PAGE_7400_OFFSET (PAGE_7400_OFFSET + CHIPSET_PAGE_9000)
    #define INDEXED_PAGE_7800_OFFSET (PAGE_7800_OFFSET + CHIPSET_PAGE_9000)
    #define INDEXED_PAGE_7C00_OFFSET (PAGE_7C00_OFFSET + CHIPSET_PAGE_9000)

    #define INDEXED_PAGE_6000_OFFSET (PAGE_6000_OFFSET + CHIPSET_PAGE_9000)
    #define INDEXED_PAGE_6400_OFFSET (PAGE_6400_OFFSET + CHIPSET_PAGE_9000)
    #define INDEXED_PAGE_6800_OFFSET (PAGE_6800_OFFSET + CHIPSET_PAGE_9000)
    #define INDEXED_PAGE_6C00_OFFSET (PAGE_6C00_OFFSET + CHIPSET_PAGE_9000)

    #define INDEXED_PAGE_5000_OFFSET (PAGE_5000_OFFSET + CHIPSET_PAGE_9000)
    #define INDEXED_PAGE_5400_OFFSET (PAGE_5400_OFFSET + CHIPSET_PAGE_9000)
    #define INDEXED_PAGE_5800_OFFSET (PAGE_5800_OFFSET + CHIPSET_PAGE_9000)
    #define INDEXED_PAGE_5C00_OFFSET (PAGE_5C00_OFFSET + CHIPSET_PAGE_9000)

    #define INDEXED_PAGE_4000_OFFSET (PAGE_4000_OFFSET + CHIPSET_PAGE_9000)
    #define INDEXED_PAGE_4400_OFFSET (PAGE_4400_OFFSET + CHIPSET_PAGE_9000)
    #define INDEXED_PAGE_4800_OFFSET (PAGE_4800_OFFSET + CHIPSET_PAGE_9000)
    #define INDEXED_PAGE_4C00_OFFSET (PAGE_4C00_OFFSET + CHIPSET_PAGE_9000)



    void __near Z_QuickMap24AIC(uint16_t __near *offset);
    void __near Z_QuickMap16AIC(uint16_t __near *offset, int16_t page);
    void __near Z_QuickMap8AIC(uint16_t __near *offset, int16_t page);
    void __near Z_QuickMap7AIC(uint16_t __near *offset, int16_t page);
    void __near Z_QuickMap6AIC(uint16_t __near *offset, int16_t page);
    void __near Z_QuickMap5AIC(uint16_t __near *offset, int16_t page);
    void __near Z_QuickMap4AIC(uint16_t __near *offset, int16_t page);
    void __near Z_QuickMap3AIC(uint16_t __near *offset, int16_t page);
    void __near Z_QuickMap2AIC(uint16_t __near *offset, int16_t page);
    void __near Z_QuickMap1AIC(uint16_t __near *offset, int16_t page);

    #define PAGE_SWAP_ARG_MULT 1

    #define Z_QuickMap24AI(a)   Z_QuickMap24AIC(&pageswapargs[(a)*PAGE_SWAP_ARG_MULT])
    #define Z_QuickMap16AI(a,b) Z_QuickMap16AIC(&pageswapargs[(a)*PAGE_SWAP_ARG_MULT],b | EMS_AUTOINCREMENT_FLAG)
    #define Z_QuickMap8AI(a,b)  Z_QuickMap8AIC (&pageswapargs[(a)*PAGE_SWAP_ARG_MULT], b | EMS_AUTOINCREMENT_FLAG)
    #define Z_QuickMap7AI(a,b)  Z_QuickMap7AIC (&pageswapargs[(a)*PAGE_SWAP_ARG_MULT], b | EMS_AUTOINCREMENT_FLAG)
    #define Z_QuickMap6AI(a,b)  Z_QuickMap6AIC (&pageswapargs[(a)*PAGE_SWAP_ARG_MULT], b | EMS_AUTOINCREMENT_FLAG)
    #define Z_QuickMap5AI(a,b)  Z_QuickMap5AIC (&pageswapargs[(a)*PAGE_SWAP_ARG_MULT], b | EMS_AUTOINCREMENT_FLAG)
    #define Z_QuickMap4AI(a,b)  Z_QuickMap4AIC (&pageswapargs[(a)*PAGE_SWAP_ARG_MULT], b | EMS_AUTOINCREMENT_FLAG)
    #define Z_QuickMap3AI(a,b)  Z_QuickMap3AIC (&pageswapargs[(a)*PAGE_SWAP_ARG_MULT], b | EMS_AUTOINCREMENT_FLAG)
    #define Z_QuickMap2AI(a,b)  Z_QuickMap2AIC (&pageswapargs[(a)*PAGE_SWAP_ARG_MULT], b | EMS_AUTOINCREMENT_FLAG)
    #define Z_QuickMap1AI(a,b)  Z_QuickMap1AIC (&pageswapargs[(a)*PAGE_SWAP_ARG_MULT], b | EMS_AUTOINCREMENT_FLAG)


#else
 

    #define Z_QuickMap24AI(a)   Z_QuickMap(&pageswapargs[(a)*PAGE_SWAP_ARG_MULT],24)
    #define Z_QuickMap16AI(a,b) Z_QuickMap(&pageswapargs[(a)*PAGE_SWAP_ARG_MULT],16)
    #define Z_QuickMap8AI(a,b) Z_QuickMap(&pageswapargs[(a)*PAGE_SWAP_ARG_MULT], 8)
    #define Z_QuickMap7AI(a,b) Z_QuickMap(&pageswapargs[(a)*PAGE_SWAP_ARG_MULT], 7)
    #define Z_QuickMap6AI(a,b) Z_QuickMap(&pageswapargs[(a)*PAGE_SWAP_ARG_MULT], 6)
    #define Z_QuickMap5AI(a,b) Z_QuickMap(&pageswapargs[(a)*PAGE_SWAP_ARG_MULT], 5)
    #define Z_QuickMap4AI(a,b) Z_QuickMap(&pageswapargs[(a)*PAGE_SWAP_ARG_MULT], 4)
    #define Z_QuickMap3AI(a,b) Z_QuickMap(&pageswapargs[(a)*PAGE_SWAP_ARG_MULT], 3)
    #define Z_QuickMap2AI(a,b) Z_QuickMap(&pageswapargs[(a)*PAGE_SWAP_ARG_MULT], 2)
    #define Z_QuickMap1AI(a,b) Z_QuickMap(&pageswapargs[(a)*PAGE_SWAP_ARG_MULT], 1)

    // unused dummy args

    #define INDEXED_PAGE_9000_OFFSET (0)
    #define INDEXED_PAGE_9400_OFFSET (0)
    #define INDEXED_PAGE_9800_OFFSET (0)
    #define INDEXED_PAGE_9C00_OFFSET (0)

    #define INDEXED_PAGE_8000_OFFSET (0)
    #define INDEXED_PAGE_8400_OFFSET (0)
    #define INDEXED_PAGE_8800_OFFSET (0)
    #define INDEXED_PAGE_8C00_OFFSET (0)

    #define INDEXED_PAGE_7000_OFFSET (0)
    #define INDEXED_PAGE_7400_OFFSET (0)
    #define INDEXED_PAGE_7800_OFFSET (0)
    #define INDEXED_PAGE_7C00_OFFSET (0)

    #define INDEXED_PAGE_6000_OFFSET (0)
    #define INDEXED_PAGE_6400_OFFSET (0)
    #define INDEXED_PAGE_6800_OFFSET (0)
    #define INDEXED_PAGE_6C00_OFFSET (0)

    #define INDEXED_PAGE_5000_OFFSET (0)
    #define INDEXED_PAGE_5400_OFFSET (0)
    #define INDEXED_PAGE_5800_OFFSET (0)
    #define INDEXED_PAGE_5C00_OFFSET (0)

    #define INDEXED_PAGE_4000_OFFSET (0)
    #define INDEXED_PAGE_4400_OFFSET (0)
    #define INDEXED_PAGE_4800_OFFSET (0)
    #define INDEXED_PAGE_4C00_OFFSET (0)

    void  __near Z_QuickMap(uint16_t __near * offset, int8_t count);

    #define PAGE_SWAP_ARG_MULT 2


    
#endif

#define AMTSIO16 (PAGE_SWAP_ARG_MULT * sizeof(int16_t))

#define EMS_2_MB_BUILD_SETTING                      1
#define EMS_4_MB_BUILD_SETTING                      2

#define EMS_BUILD_SETTING                           EMS_2_MB_BUILD_SETTING
// #define EMS_BUILD_SETTING                           EMS_4_MB_BUILD_SETTING



#if EMS_BUILD_SETTING == EMS_2_MB_BUILD_SETTING  
#define NUM_FLAT_CACHE_PAGES                        6
#define NUM_SPRITE_CACHE_PAGES                      20
// dont do more than 63 pages. used as an index in a 4 byte thing. asm assumes one byte index
// todo get this to 29, maybe 30...
#define NUM_TEXTURE_PAGES                           29
#define NUM_MUSIC_PAGES                             4
#define NUM_SFX_PAGES                               7
#elif EMS_BUILD_SETTING == EMS_4_MB_BUILD_SETTING  
// TODO
#define NUM_FLAT_CACHE_PAGES                        16
#define NUM_SPRITE_CACHE_PAGES                      64
#define NUM_TEXTURE_PAGES                           64
#define NUM_MUSIC_PAGES                             4
#define NUM_SFX_PAGES                               32
#endif

#define NUM_WAD_PAGES                               3
#define MUS_PAGE_FRAME_INDEX                        0
#define SFX_PAGE_FRAME_INDEX                        1
#define WAD_PAGE_FRAME_INDEX                        2


// arg mult times size of int16

#define SCRATCH_SEGMENT_5000 0x5000
#define SCRATCH_ADDRESS_4000 (byte __far* )0x40000000
#define SCRATCH_ADDRESS_5000 (byte __far* )0x50000000
#define SCRATCH_ADDRESS_7000 (byte __far* )0x70000000
#define SCRATCH_ADDRESS_8000 (byte __far* )0x80000000

#define SCREEN4_LOGICAL_PAGE                        -1

#define SCREEN0_LOGICAL_PAGE                        -1
#define STRINGS_LOGICAL_PAGE                        -1
//#define FIRST_RENDER_LOGICAL_PAGE                   20

#define RENDER_7800_PAGE                            9
#define RENDER_7C00_PAGE                            10
#define PHYSICS_RENDER_9800_PAGE                    13
//#define PHYSICS_RENDER_6C00_PAGE                    15
//#define EMS_VISPLANE_EXTRA_PAGE                     SCREEN3_LOGICAL_PAGE + 1
#define FIRST_VISPLANE_PAGE							5

#define LAST_RENDER_OR_PHYSICS_LOGICAL_PAGE         14

//#define EMS_VISPLANE_EXTRA_PAGE                     NUM_EMS4_SWAP_PAGES + 1
// 14
#define LAST_RENDER_OR_PHYSICS_LOGICAL_PAGE         14
// 15
#define FIRST_STATUS_LOGICAL_PAGE                   LAST_RENDER_OR_PHYSICS_LOGICAL_PAGE + 1
// 19
#define PALETTE_LOGICAL_PAGE                        FIRST_STATUS_LOGICAL_PAGE + 4
// todo almost 6k free here..
// 20
#define FIRST_MENU_GRAPHICS_LOGICAL_PAGE            PALETTE_LOGICAL_PAGE + 1
// 22
#define FIRST_SCRATCH_LOGICAL_PAGE                  FIRST_MENU_GRAPHICS_LOGICAL_PAGE + 2
// 26
#define FIRST_LUMPINFO_LOGICAL_PAGE                 FIRST_SCRATCH_LOGICAL_PAGE + 4
// 29
#define FIRST_FLAT_CACHE_LOGICAL_PAGE               FIRST_LUMPINFO_LOGICAL_PAGE + 3
// 35
#define FIRST_TEXTURE_LOGICAL_PAGE                  FIRST_FLAT_CACHE_LOGICAL_PAGE + NUM_FLAT_CACHE_PAGES
// 56  overlap
#define FIRST_INTERMISSION_GRAPHICS_LOGICAL_PAGE    FIRST_TEXTURE_LOGICAL_PAGE + (NUM_TEXTURE_PAGES - 8)
// 64
#define FIRST_EXTRA_MASKED_DATA_PAGE                FIRST_TEXTURE_LOGICAL_PAGE + NUM_TEXTURE_PAGES
// 66
#define FIRST_SPRITE_CACHE_LOGICAL_PAGE             FIRST_EXTRA_MASKED_DATA_PAGE + 2

// 74
#define SCREEN1_LOGICAL_PAGE                        FIRST_SPRITE_CACHE_LOGICAL_PAGE + 8
// 78
#define SCREEN2_LOGICAL_PAGE                        FIRST_SPRITE_CACHE_LOGICAL_PAGE + 12
// 82
#define SCREEN3_LOGICAL_PAGE                        FIRST_SPRITE_CACHE_LOGICAL_PAGE + 16

// 86
#define FLAT_DATA_PAGES                             (FIRST_SPRITE_CACHE_LOGICAL_PAGE + NUM_SPRITE_CACHE_PAGES)
// 89  // todo get this for free elsewhere? 3 pages just for backup visplanes now...
#define EMS_VISPLANE_EXTRA_PAGE                     FLAT_DATA_PAGES + 3

// 92
#define MUS_DATA_PAGES                              EMS_VISPLANE_EXTRA_PAGE + 3

// 96
#define SFX_DATA_PAGES                              (MUS_DATA_PAGES + NUM_MUSIC_PAGES)

// 103
#define BSP_CODE_PAGE                               SFX_DATA_PAGES + NUM_SFX_PAGES


// 104 (103 because of 0 index)
#define NUM_EMS4_SWAP_PAGES                         (int16_t) BSP_CODE_PAGE + 1



// NUM_EMS4_SWAP_PAGES needs to be 104 to fit in 256 k + (2 MB EMS - 384k)

// 32
#define FIRST_DEMO_LOGICAL_PAGE                     FIRST_INTERMISSION_GRAPHICS_LOGICAL_PAGE + 4

#define OVERLAY_ID_UNMAPPED 0
#define OVERLAY_ID_WIPE 1
#define OVERLAY_ID_FINALE 2
#define OVERLAY_ID_SAVELOADGAME 3
#define OVERLAY_ID_MUS_LOADER 4
#define OVERLAY_ID_SOUND_INIT 5
#define OVERLAY_ID_P_SETUP 6


#define NUM_OVERLAYS 6


#define TASK_PHYSICS 0
#define TASK_RENDER 1
#define TASK_STATUS 2
#define TASK_DEMO 3
#define TASK_PHYSICS9000 4
#define TASK_RENDER_SPRITE 5
#define TASK_SCRATCH_STACK 7
#define TASK_PALETTE 8
#define TASK_MENU 9
#define TASK_WIPE 10
#define TASK_INTERMISSION 11
#define TASK_STATUS_NO_SCREEN4 12

#define SCRATCH_PAGE_SEGMENT 0x5000u
#define SCRATCH_PAGE_SEGMENT_7000 0x7000u

#define num_phys_params 24
// extra 4 for the remapping for page 4000 to 9000 
#define num_rend_params 28
#define num_stat_params 6
#define num_demo_params 4
#define num_textinfo_params 4
#define num_scratch5000_params 4
#define num_scratch8000_params 4
#define num_scratch7000_params 4
#define num_scratch4000_params 4
#define num_renderplane_params 4
#define num_flatcache_params 4
#define num_spritecache_params 4
#define num_flatcache_undo_params 4
#define num_maskeddata_params 3
#define num_renderto6000_params 2
#define num_palette_params 5
#define num_7000to6000_params 4
#define num_menu_params 8
#define num_intermission_params 12
#define num_wipe_params 12
#define num_visplanepage_params 1
#define num_render_4000_to_8000_params 4

//#define pageswapargoff_demo pageswapargseg +

// used for segment offset for params
// needs to be added to pageswapargoff




#define pageswapargs_phys_offset_size                0
#define pageswapargs_screen0_offset_size             (16)
#define pageswapargs_physics_code_offset_size        20
#define pageswapargs_physics_code_offset             (pageswapargs_physics_code_offset_size * PAGE_SWAP_ARG_MULT)
#define pageswapargs_rend_offset_size                (num_phys_params)

#define pageswapargs_rend_texture_size                (pageswapargs_rend_offset_size + 4)
#define pageswapargs_rend_8000_size                   (pageswapargs_rend_offset_size + 16)
#define pageswapargs_rend_9000_size                   (pageswapargs_rend_offset_size + 20)
#define pageswapargs_rend_other9000_size              (pageswapargs_rend_offset_size + 24)

#define pageswapargs_stat_offset_size                (pageswapargs_rend_offset_size           + num_rend_params)
#define pageswapargs_demo_offset_size                (pageswapargs_stat_offset_size           + num_stat_params)
#define pageswapargs_scratch5000_offset_size         (pageswapargs_demo_offset_size           + num_demo_params)
#define pageswapargs_scratch8000_offset_size         (pageswapargs_scratch5000_offset_size    + num_scratch5000_params)
#define pageswapargs_scratch7000_offset_size         (pageswapargs_scratch8000_offset_size    + num_scratch8000_params)
#define pageswapargs_scratch4000_offset_size         (pageswapargs_scratch7000_offset_size    + num_scratch7000_params)
#define pageswapargs_renderplane_offset_size         (pageswapargs_scratch4000_offset_size    + num_scratch4000_params)
#define pageswapargs_flatcache_offset_size           (pageswapargs_renderplane_offset_size    + num_renderplane_params)
#define pageswapargs_spritecache_offset_size         (pageswapargs_flatcache_offset_size      + num_flatcache_params)
#define pageswapargs_flatcache_undo_offset_size      (pageswapargs_spritecache_offset_size    + num_spritecache_params)
#define pageswapargs_maskeddata_offset_size          (pageswapargs_flatcache_undo_offset_size + num_flatcache_undo_params)
#define pageswapargs_render_to_6000_size             (pageswapargs_maskeddata_offset_size     + num_maskeddata_params)
#define pageswapargs_palette_offset_size             (pageswapargs_render_to_6000_size        + num_renderto6000_params)
#define pageswapargs_menu_offset_size                (pageswapargs_palette_offset_size        + num_palette_params)
#define pageswapargs_intermission_offset_size        (pageswapargs_menu_offset_size           + num_menu_params)
#define pageswapargs_wipe_offset_size                (pageswapargs_intermission_offset_size   + num_intermission_params)
#define pageswapargs_visplanepage_offset_size        (pageswapargs_wipe_offset_size           + num_wipe_params)
#define pageswapargs_rend_other8000_offset_size      (pageswapargs_visplanepage_offset_size   + num_visplanepage_params)
#define total_pages_size                             (pageswapargs_rend_other8000_offset_size + num_render_4000_to_8000_params)
 
// used for array indices
#define pageswapargs_rend_offset            (num_phys_params*PAGE_SWAP_ARG_MULT)
#define pageswapargs_stat_offset            (pageswapargs_rend_offset               + (num_rend_params*PAGE_SWAP_ARG_MULT))
#define pageswapargs_demo_offset            (pageswapargs_stat_offset               + (num_stat_params*PAGE_SWAP_ARG_MULT))
#define pageswapargs_scratch5000_offset     (pageswapargs_demo_offset               + (num_demo_params*PAGE_SWAP_ARG_MULT))
#define pageswapargs_scratch8000_offset     (pageswapargs_scratch5000_offset        + (num_scratch5000_params*PAGE_SWAP_ARG_MULT))
#define pageswapargs_scratch7000_offset     (pageswapargs_scratch8000_offset        + (num_scratch8000_params*PAGE_SWAP_ARG_MULT))
#define pageswapargs_scratch4000_offset     (pageswapargs_scratch7000_offset        + (num_scratch7000_params*PAGE_SWAP_ARG_MULT))
#define pageswapargs_renderplane_offset     (pageswapargs_scratch4000_offset        + (num_scratch4000_params*PAGE_SWAP_ARG_MULT))
#define pageswapargs_flatcache_offset       (pageswapargs_renderplane_offset        + (num_renderplane_params*PAGE_SWAP_ARG_MULT))
#define pageswapargs_spritecache_offset     (pageswapargs_flatcache_offset          + (num_flatcache_params*PAGE_SWAP_ARG_MULT))
#define pageswapargs_flatcache_undo_offset  (pageswapargs_spritecache_offset        + (num_spritecache_params*PAGE_SWAP_ARG_MULT))
#define pageswapargs_maskeddata_offset      (pageswapargs_flatcache_undo_offset     + (num_flatcache_undo_params*PAGE_SWAP_ARG_MULT))
#define pageswapargs_render_to_6000_offset  (pageswapargs_maskeddata_offset         + (num_maskeddata_params*PAGE_SWAP_ARG_MULT))
#define pageswapargs_palette_offset         (pageswapargs_render_to_6000_offset     + (num_renderto6000_params*PAGE_SWAP_ARG_MULT))
#define pageswapargs_menu_offset            (pageswapargs_palette_offset            + (num_palette_params*PAGE_SWAP_ARG_MULT))
#define pageswapargs_intermission_offset    (pageswapargs_menu_offset               + (num_menu_params*PAGE_SWAP_ARG_MULT))
#define pageswapargs_wipe_offset            (pageswapargs_intermission_offset       + (num_intermission_params*PAGE_SWAP_ARG_MULT))
#define pageswapargs_visplanepage_offset    (pageswapargs_wipe_offset               + (num_wipe_params*PAGE_SWAP_ARG_MULT))
#define pageswapargs_rend_other8000_size    (pageswapargs_visplanepage_offset       + (num_visplanepage_params*PAGE_SWAP_ARG_MULT))
#define total_pages                         (pageswapargs_rend_other8000_size       + (num_render_4000_to_8000_params*PAGE_SWAP_ARG_MULT))

#define pageswapargs_rend_texture_offset                (pageswapargs_rend_offset + 4*PAGE_SWAP_ARG_MULT)
#define pageswapargs_rend_other9000_offset              (pageswapargs_rend_offset + 24*PAGE_SWAP_ARG_MULT)


//#define pageswapargs_textcache ((int16_t*)&pageswapargs_rend[40])

// EMS page frame stuff
void __far Z_QuickMapMusicPageFrame(uint8_t pagenumber);
void __far Z_QuickMapSFXPageFrame(uint8_t pagenumber);
void __far Z_QuickMapWADPageFrame(int16_t pagenumber);

void __far Z_SavePageFrameState();
void __far Z_RestorePageFrameState();
// #define Z_QuickMapSFXPageFrame(page)  Z_QuickMapMusicPageFrame(1, page + NUM_MUSIC_PAGES)

// EMS 4.0 stuff

void __far Z_QuickMapPhysics();
void __far Z_QuickMapRender();
void __far Z_QuickMapRender_4000To9000();
void __far Z_QuickMapRender_9000To7000();
void __near Z_QuickMapRender_9000To6000();

void __far Z_QuickMapStatus();
void __far Z_QuickMapStatusNoScreen4();

void __far Z_QuickMapDemo();
void __far Z_QuickMapRender4000();
void __far Z_QuickMapRender5000();
void __far Z_QuickMapByTaskNum(int8_t task);
void __near Z_QuickMapRenderTexture();
//void __far Z_QuickMapRenderTexture(uint8_t offset, uint8_t count);
void __far Z_QuickMapScratch_4000();
void __far Z_QuickMapScratch_5000();
void __far Z_QuickMapScratch_8000();
void __far Z_QuickMapScratch_7000();
void __far Z_PushScratchFrame();
void __far Z_PopScratchFrame();
void __far Z_QuickMapFlatPage(int16_t page, int16_t offset);
void __far Z_QuickMapUndoFlatCache();
void __far Z_QuickMapMaskedExtraData();
void __near Z_QuickMapSpritePage();

    //void __far Z_QuickMapTextureInfoPage();
void __far Z_QuickMapPalette();
void __far Z_QuickMapMenu();
void __far Z_QuickMapIntermission();
void __far Z_QuickMapScreen0();
void __far Z_QuickMapWipe();
void __far Z_QuickMapPhysicsRender5000();
void __far Z_QuickMapRender7000();

void __near Z_GetEMSPageMap();
//void Z_LinkConventionalVariables();
void __near Z_LoadBinaries();

void __far Z_QuickMapVisplanePage(int8_t virtualpage, int8_t physicalpage);
void __far Z_QuickMapVisplaneRevert();
void __far Z_QuickMapRenderPlanes();



//void DUMP_4000_TO_FILE();
//void DUMP_MEMORY_TO_FILE();


#endif



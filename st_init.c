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
//      Status bar code.
//      Does the face/direction indicator animatin.
//      Does palette indicators as well (red pain/berserk, bright pickup)
//


#include <stdio.h>

#include "i_system.h"
#include "z_zone.h"
#include "m_misc.h"
#include "w_wad.h"

#include "doomdef.h"

#include "g_game.h"

#include "st_stuff.h"
#include "st_lib.h"
#include "r_local.h"

#include "p_local.h"
#include "p_inter.h"

#include "am_map.h"
#include "dutils.h"

#include "s_sound.h"

// Needs access to LFB.
#include "v_video.h"

// State.
#include "doomstat.h"

// Data.
#include "dstrings.h"
#include "sounds.h"
#include <dos.h>
#include "m_memory.h"
#include "m_near.h"


//
// STATUS BAR DATA
//



#define ST_NUMPAINFACES         5
#define ST_NUMSTRAIGHTFACES     3
#define ST_NUMTURNFACES         2
#define ST_NUMSPECIALFACES              3
#define ST_NUMEXTRAFACES                2

#define ST_FACESTRIDE \
          (ST_NUMSTRAIGHTFACES+ST_NUMTURNFACES+ST_NUMSPECIALFACES)
#define ST_NUMFACES \
          (ST_FACESTRIDE*ST_NUMPAINFACES+ST_NUMEXTRAFACES)

 


void __near ST_loadGraphics(void) {

	int8_t         i;
	int8_t         j;
	int16_t         facenum;

	int8_t        namebuf[9] = "STTNUM0";
	int8_t        namebuf2[9] = "STYSNUM0";
	int8_t        namebuf3[9] = "STKEYS0";
	int8_t        namebuf4[9] = "STGNUM2";
	int8_t        namebuf5[9] = "STFST00";
	
	int8_t        namebuf10[9] = "STFTR00";
	int8_t        namebuf11[9] = "STFTL00";
	int8_t        namebuf12[9] = "STFOUCH0";
	int8_t        namebuf13[9] = "STFEVL0";
	int8_t        namebuf14[9] = "STFKILL0";

	// sprints to do increasing digits create big code
	// we'll just add the digit/char by 1 in a loop.

		

	// Load the numbers, tall and short
	for (i = 0; i < 10; i++) {
		W_CacheLumpNameDirect(namebuf, (byte __far *)MK_FP(ST_GRAPHICS_SEGMENT, tallnum[i]));
		W_CacheLumpNameDirect(namebuf2, (byte __far *)MK_FP(ST_GRAPHICS_SEGMENT, shortnum[i]));
		namebuf[6]++;
		namebuf2[7]++;
	}

	// 44608 total... fits with screen4

	 // tallnum shortnum
	// 320 68
	// 244 64
	// 336 76
	// 336 72
	// 316 60
	// 348 72
	// 340 72
	// 276 72
	// 348 76
	// 336 72

	//328 tallpercent

	// Load percent key.
	//Note: why not load STMINUS here, too?
	 W_CacheLumpNameDirect("STTPRCNT", tallpercent_patch);

	// key cards
	for (i = 0; i < NUMCARDS; i++)
	{
		W_CacheLumpNameDirect(namebuf3, (byte __far *)MK_FP(ST_GRAPHICS_SEGMENT, keys[i]));
		namebuf3[6]++;
	}

	//keysref
	// 104
	// 104
	// 104
	// 120
	// 120
	// 120

	// arms background
	W_CacheLumpNameDirect("STARMS", armsbg_patch);

	// 1648 armsbgref

	// arms ownership widgets
	for (i = 0; i < 6; i++)
	{

		// gray #
		 W_CacheLumpNameDirect(namebuf4, (byte __far *)MK_FP(ST_GRAPHICS_SEGMENT, arms[i][0]));


		namebuf4[6]++;

		// yellow #
		arms[i][1] = shortnum[i + 2];
	}




	// face backgrounds for different color players
	W_CacheLumpNameDirect("STFB0", faceback_patch);
	// 1408 facebakref

	// status bar background bits
	W_CacheLumpNameDirect("STBAR", sbar_patch);
	// 13128 sbarref

	// face states
	facenum = 0;
	for (i = 0; i < ST_NUMPAINFACES; i++)
	{
		for (j = 0; j < ST_NUMSTRAIGHTFACES; j++)
		{
			W_CacheLumpNameDirect(namebuf5, (byte __far *)MK_FP(ST_GRAPHICS_SEGMENT, faces[facenum++]));
			namebuf5[6]++;
		}
		namebuf5[6] = '0';
		namebuf5[5]++;
	
	

		W_CacheLumpNameDirect(namebuf10, (byte __far *)MK_FP(ST_GRAPHICS_SEGMENT, faces[facenum++]));
		W_CacheLumpNameDirect(namebuf11, (byte __far *)MK_FP(ST_GRAPHICS_SEGMENT, faces[facenum++]));
		W_CacheLumpNameDirect(namebuf12, (byte __far *)MK_FP(ST_GRAPHICS_SEGMENT, faces[facenum++]));
		W_CacheLumpNameDirect(namebuf13, (byte __far *)MK_FP(ST_GRAPHICS_SEGMENT, faces[facenum++]));
		W_CacheLumpNameDirect(namebuf14, (byte __far *)MK_FP(ST_GRAPHICS_SEGMENT, faces[facenum++]));

		namebuf10[5]++;
		namebuf11[5]++;
		namebuf12[7]++;
		namebuf13[6]++;
		namebuf14[7]++;

	}
	W_CacheLumpNameDirect("STFGOD0", (byte __far *) MK_FP(ST_GRAPHICS_SEGMENT, faces[facenum++]));
	W_CacheLumpNameDirect("STFDEAD0", (byte __far *) MK_FP(ST_GRAPHICS_SEGMENT, faces[facenum++]));
	// 808 808 808
	// 880 884 844 816 824
	// 808 808 800
	// 888 884 844 816 824
	// 824 828 824
	// 896 896 844 816 824
	// 840 836 832
	// 908 944 844 816 824
	// 844 836 844
	// 908 944 844 816 824
	// 808 836
	// 23096 total
}

void __near ST_loadData(void) {
	//todo move this too
	int16_t lu_palette = W_GetNumForName("PLAYPAL");
	Z_QuickMapPalette();
	W_CacheLumpNumDirect(lu_palette, palettebytes);
	Z_QuickMapStatus();
	ST_loadGraphics();
}

void __near ST_Init(void) {
	ST_loadData();
	Z_QuickMapPhysics();


}

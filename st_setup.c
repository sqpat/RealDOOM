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
#include "st_stuff.h"
#include "m_memory.h"
#include "m_near.h"



// ?
void __near STlib_initNum (st_number_t __near*  n,int16_t   x,uint8_t   y,uint16_t __near*  pl,int16_t   width){
    n->x = x;
    n->y = y;
    n->oldnum = 0;
    n->width = width;
    n->patch_offset = pl;
}


//
void __near STlib_initPercent (st_percent_t __near*  p,int16_t   x,uint8_t   y,uint16_t __near*  pl,uint16_t  percent) {
    STlib_initNum(&p->num, x, y, pl, 3);
    p->patch_offset = percent;
}



void __near STlib_initMultIcon (st_multicon_t __near* i,int16_t   x,uint8_t   y,uint16_t __near*  il) {
    i->x = x;
    i->y = y;
    i->oldinum = -1;
    i->patch_offset = il;

}


void __near ST_createWidgets(void){

    int8_t i;
    uint8_t ST_MAXAMMOY[4] = {ST_MAXAMMO0Y,ST_MAXAMMO1Y,ST_MAXAMMO2Y,ST_MAXAMMO3Y};
    // ready weapon ammo
    STlib_initNum(&w_ready, ST_AMMOX, ST_AMMOY, tallnum, ST_AMMOWIDTH);

    // health percentage
    STlib_initPercent(&w_health,ST_HEALTHX,ST_HEALTHY,tallnum,tallpercent);
    // arms background
    STlib_initMultIcon(&w_armsbg, ST_ARMSBGX, ST_ARMSBGY, armsbgarray); 
  
     w_armsbg.oldinum = 0; // hack to make it work as multicon instead of binicon

    // weapons owned
    for (i = 0; i < 6; i++) {
        STlib_initMultIcon(&w_arms[i], ST_ARMSX + (i % 3)*ST_ARMSXSPACE, ST_ARMSY + (i / 3)*ST_ARMSYSPACE, arms[i]);
    }



    // faces
    STlib_initMultIcon(&w_faces, ST_FACESX, ST_FACESY, faces);

    // armor percentage - should be colored later
    STlib_initPercent(&w_armor, ST_ARMORX, ST_ARMORY, tallnum, tallpercent);

    // keyboxes 0-2
    STlib_initMultIcon(&w_keyboxes[0],  ST_KEY0X,  ST_KEY0Y,  keys);
    STlib_initMultIcon(&w_keyboxes[1],  ST_KEY1X,  ST_KEY1Y,  keys);
    STlib_initMultIcon(&w_keyboxes[2],  ST_KEY2X,  ST_KEY2Y,  keys);


    for (i = 0; i < 4; i++){

        // ammo count (all four kinds)
        STlib_initNum(&w_ammo[i],  ST_AMMO0X,  ST_MAXAMMOY[i],  shortnum,  ST_AMMO0WIDTH);
        // max ammo count (all four kinds)
        STlib_initNum(&w_maxammo[i],  ST_MAXAMMO0X,  ST_MAXAMMOY[i],  shortnum,  ST_MAXAMMO0WIDTH);
    }
    

}



void __near ST_Stop(void){
 if (st_stopped){
     return;
 }
 I_SetPalette(0);
 st_stopped = true;

}


void __far ST_Start(void) {
    int8_t         i;

    if (!st_stopped){
        ST_Stop();
    }

    st_firsttime = true;
    st_gamestate = FirstPersonState;
    st_statusbaron = true;

    st_faceindex = 0;
    st_palette = -1;
    st_oldhealth = -1;

    for (i = 0; i < NUMWEAPONS; i++){
        oldweaponsowned[i] = player.weaponowned[i];
    }

    for (i = 0; i < 3; i++){
        keyboxes[i] = -1;
    }


    ST_createWidgets();
    st_stopped = false;

}

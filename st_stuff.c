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
#include <dos.h>
#include "m_memory.h"
#include "m_near.h"


void __far locallib_printhex (uint32_t number, boolean islong, int8_t __near* outputtarget);


//
// STATUS BAR CODE
//

void __near ST_refreshBackground(void) {

    if (st_statusbaron) {
        V_DrawPatch(ST_X, 0, BG, (patch_t __far*)sbar_patch);
        V_MarkRect (ST_X, ST_Y, ST_WIDTH, ST_HEIGHT); 
        V_CopyRect(ST_X, ST_Y*SCREENWIDTH+ST_X, ST_WIDTH, ST_HEIGHT);
    }

}


// Respond to keyboard input events,
//  intercept cheats.
boolean __near ST_Responder (event_t __far* ev) {
    int8_t           i;
    

  // if a user keypress...
  if (ev->type == ev_keydown) {
    if (gameskill != sk_nightmare) {
      // 'dqd' cheat for toggleable god mode
      if (cht_CheckCheat(&cheat_god, ev->data1)) {
          player.cheats ^= CF_GODMODE;
        if (player.cheats & CF_GODMODE) {
            playerMobj->health = 100;
          
          player.health = 100;
          player.message = STSTR_DQDON;
        }
        else 
            player.message = STSTR_DQDOFF;
      }
      // 'fa' cheat for killer fucking arsenal
      else if (cht_CheckCheat(&cheat_ammonokey, ev->data1)) {
          player.armorpoints = 200;
          player.armortype = 2;
        
        for (i=0;i<NUMWEAPONS;i++)
            player.weaponowned[i] = true;
        
        for (i=0;i<NUMAMMO;i++)
            player.ammo[i] = player.maxammo[i];
        
        player.message = STSTR_FAADDED;
      }
      // 'kfa' cheat for key full ammo
      else if (cht_CheckCheat(&cheat_ammo, ev->data1)) {
          player.armorpoints = 200;
          player.armortype = 2;
        
        for (i=0;i<NUMWEAPONS;i++)
            player.weaponowned[i] = true;
        
        for (i=0;i<NUMAMMO;i++)
            player.ammo[i] = player.maxammo[i];
        
        for (i=0;i<NUMCARDS;i++)
            player.cards[i] = true;
        
        player.message = STSTR_KFAADDED;
      }
      // 'mus' cheat for changing music
      else if (cht_CheckCheat(&cheat_mus, ev->data1)) {
        
          int8_t    buf[3];
          int16_t             musnum;
        
          player.message = STSTR_MUS;
        cht_GetParam(&cheat_mus, buf);
#if (EXE_VERSION < EXE_VERSION_ULTIMATE)
        musnum = mus_runnin + (buf[0]-'0')*10 + buf[1]-'0' - 1;
          
        if (((buf[0]-'0')*10 + buf[1]-'0') > 35)
            player.message = STSTR_NOMUS;
        else
          S_ChangeMusic(musnum, 1);
#else
        if (commercial)
        {
          musnum = mus_runnin + (buf[0]-'0')*10 + buf[1]-'0' - 1;
          
          if (((buf[0]-'0')*10 + buf[1]-'0') > 35)
              players.message = STSTR_NOMUS;
          else
            S_ChangeMusic(musnum, 1);
        }
        else
        {
          musnum = mus_e1m1 + (buf[0]-'1')*9 + (buf[1]-'1');
          
          if (((buf[0]-'1')*9 + buf[1]-'1') > 31)
              players.message = STSTR_NOMUS;
          else
            S_ChangeMusic(musnum, 1);
        }
#endif
      } else if(!commercial && cht_CheckCheat(&cheat_noclip, ev->data1)) { 
          player.cheats ^= CF_NOCLIP;
        
        if (player.cheats & CF_NOCLIP)
            player.message = STSTR_NCON;
        else
            player.message = STSTR_NCOFF;
      } else if (commercial && cht_CheckCheat(&cheat_commercial_noclip, ev->data1)) {
          player.cheats ^= CF_NOCLIP;
        
        if (player.cheats & CF_NOCLIP)
            player.message = STSTR_NCON;
        else
            player.message = STSTR_NCOFF;
      }
      // 'behold?' power-up cheats
      for (i=0;i<6;i++) {
        if (cht_CheckCheat(&cheat_powerup[i], ev->data1)) {
          if (!player.powers[i]){
            P_GivePower( i);
          } else if (i!=pw_strength){
              player.powers[i] = 1;
          }else{
              player.powers[i] = 0;
          }
          player.message = STSTR_BEHOLDX;
        }
      }
      
      // 'behold' power-up menu
      if (cht_CheckCheat(&cheat_powerup[6], ev->data1)) {
          player.message = STSTR_BEHOLD;
      } else if (cht_CheckCheat(&cheat_choppers, ev->data1)) {
          // 'choppers' invulnerability & chainsaw
          player.weaponowned[wp_chainsaw] = true;
          player.powers[pw_invulnerability] = true;
          player.message = STSTR_CHOPPERS;
      } else if (cht_CheckCheat(&cheat_mypos, ev->data1)) {
          // 'mypos' for player position

//todo: this      player pos  
        int8_t hexnumber_string[10];
        locallib_printhex(playerMobj_pos->angle.wu, true, hexnumber_string);
        combine_strings(st_stuff_buf,"ang=0x", hexnumber_string);
        combine_strings(st_stuff_buf,st_stuff_buf, ";x,y=(0x");
        
        locallib_printhex(playerMobj_pos->x.w, true, hexnumber_string);
        combine_strings(st_stuff_buf,st_stuff_buf, hexnumber_string);
        combine_strings(st_stuff_buf,st_stuff_buf, ",0x");

        locallib_printhex(playerMobj_pos->y.w, true, hexnumber_string);
        combine_strings(st_stuff_buf,st_stuff_buf, hexnumber_string);
        combine_strings(st_stuff_buf,st_stuff_buf, ")");
        
        
        player.messagestring = st_stuff_buf;
      }
    }
    
    // 'clev' change-level cheat
    if (cht_CheckCheat(&cheat_clev, ev->data1)) {
        int8_t              buf[3];
        int8_t               epsd;
        int8_t               map;
      
      cht_GetParam(&cheat_clev, buf);
      
      if (commercial) {
        epsd = 0;
        map = (buf[0] - '0')*10 + buf[1] - '0';
      } else {
        epsd = buf[0] - '0';
        map = buf[1] - '0';
      }

      // Catch invalid maps.
#if (EXE_VERSION < EXE_VERSION_ULTIMATE)
      if ((!commercial && epsd > 0 && epsd < 4 && map > 0 && map < 10) || (commercial && map > 0 && map <= 40)) {
          // So be it.
          player.message = STSTR_CLEV;
          G_DeferedInitNew(gameskill, epsd, map);
      }
#else
      if ((!commercial && epsd > 0 && epsd < 5 && map > 0 && map < 10) || (commercial && map > 0 && map <= 40)) {
          // So be it.
          players.message = STSTR_CLEV;
          G_DeferedInitNew(gameskill, epsd, map);
      }
#endif
    }    
  }
  return false;
}



int16_t __near ST_calcPainOffset(void) {
    int16_t         health;
    
    health = player.health > 100 ? 100 : player.health;

    if (health != st_calc_oldhealth) {
        st_calc_lastcalc = ST_FACESTRIDE * (((100 - health) * ST_NUMPAINFACES) / 101);
        st_calc_oldhealth = health;
    }
    return st_calc_lastcalc;
}


//
// This is a not-very-pretty routine which handles
//  the face states and their timing.
// the precedence of expressions is:
//  dead > evil grin > turned head > straight ahead
//
void __near ST_updateFaceWidget(void) {
    int8_t         i;
    angle_t     badguyangle;
    angle_t     diffang;
    boolean     doevilgrin;
    mobj_pos_t __far* plyrattacker_pos;

    if (st_face_priority < 10) {
        // dead
        if (!player.health) {
            st_face_priority = 9;
            st_faceindex = ST_DEADFACE;
            st_facecount = 1;
        }
    }

    if (st_face_priority < 9) {
        if (player.bonuscount) {
            // picking up bonus
            doevilgrin = false;

            for (i=0;i<NUMWEAPONS;i++) {
                if (oldweaponsowned[i] != player.weaponowned[i]) {
                    doevilgrin = true;
                    oldweaponsowned[i] = player.weaponowned[i];
                }
            }
            if (doevilgrin)  {
                // evil grin if just picked up weapon
                st_face_priority = 8;
                st_facecount = ST_EVILGRINCOUNT;
                st_faceindex = ST_calcPainOffset() + ST_EVILGRINOFFSET;
            }
        }

    }
  
    if (st_face_priority < 8) {
        if (player.damagecount
            && player.attackerRef
            && player.attackerRef != playerMobjRef) {
            // being attacked
            st_face_priority = 7;
            
            if (player.health - st_oldhealth > ST_MUCHPAIN) {
                st_facecount = ST_TURNCOUNT;
                st_faceindex = ST_calcPainOffset() + ST_OUCHOFFSET;
            } else {
                 
                plyrattacker_pos = &mobjposlist[player.attackerRef];
                badguyangle.wu = R_PointToAngle2(playerMobj_pos->x,
                                                playerMobj_pos->y,
                                              plyrattacker_pos->x,
                                              plyrattacker_pos->y);
                
                if (badguyangle.wu > playerMobj_pos->angle.wu) {
                    //TODO optimize. Shouldnt need to do a 32 bit subtract to figure this out?

                    // whether right or left
                    diffang.wu = badguyangle.wu - playerMobj_pos->angle.wu;
                    i = diffang.wu > ANG180; 
                } else {
                    // whether left or right
                    diffang.wu = playerMobj_pos->angle.wu - badguyangle.wu;
                    i = diffang.wu <= ANG180; 
                } // confusing, aint it?

                
                st_facecount = ST_TURNCOUNT;
                st_faceindex = ST_calcPainOffset();
                
                if (diffang.hu.intbits < ANG45_HIGHBITS) {
                    // head-on    
                    st_faceindex += ST_RAMPAGEOFFSET;
                } else if (i) {
                    // turn face right
                    st_faceindex += ST_TURNOFFSET;
                } else {
                    // turn face left
                    st_faceindex += ST_TURNOFFSET+1;
                }
            }
        }
    }
  
    if (st_face_priority < 7) {
        // getting hurt because of your own damn stupidity
        if (player.damagecount) {
            if (player.health - st_oldhealth > ST_MUCHPAIN) {
                st_face_priority = 7;
                st_facecount = ST_TURNCOUNT;
                st_faceindex = ST_calcPainOffset() + ST_OUCHOFFSET;
            } else {
                st_face_priority = 6;
                st_facecount = ST_TURNCOUNT;
                st_faceindex = ST_calcPainOffset() + ST_RAMPAGEOFFSET;
            }

        }

    }
  
    if (st_face_priority < 6) {
        // rapid firing
        if (player.attackdown) {
            if (st_face_lastattackdown == -1) {
                st_face_lastattackdown = ST_RAMPAGEDELAY;
            } else if (!--st_face_lastattackdown) {
                st_face_priority = 5;
                st_faceindex = ST_calcPainOffset() + ST_RAMPAGEOFFSET;
                st_facecount = 1;
                st_face_lastattackdown = 1;
            }
        } else {
            st_face_lastattackdown = -1;
        }
    }
  
    if (st_face_priority < 5) {
        // invulnerability
        if ((player.cheats & CF_GODMODE)
            || player.powers[pw_invulnerability]) {
            st_face_priority = 4;

            st_faceindex = ST_GODFACE;
            st_facecount = 1;

        }

    }

    // look left or look right if the facecount has timed out
    if (!st_facecount) {
        st_faceindex = ST_calcPainOffset() + (st_randomnumber % 3);
        st_facecount = ST_STRAIGHTFACECOUNT;
        st_face_priority = 0;
    }

    st_facecount--;

}

void __near ST_updateWidgets(void) {
    int8_t i;

 
    // update keycard multiple widgets
    for (i = 0; i < 3; i++)
    {
        keyboxes[i] = player.cards[i] ? i : -1;

        if (player.cards[i + 3])
            keyboxes[i] = i + 3;
    }

    // refresh everything if this is him coming back to life
    ST_updateFaceWidget();


}

void __near ST_Ticker (void) {

    st_randomnumber = M_Random();
    ST_updateWidgets();
    st_oldhealth = player.health;

}


void __near ST_doPaletteStuff(void){

    int8_t         palette;
    int16_t         cnt;
    int16_t         bzc;

    cnt = player.damagecount;

    if (player.powers[pw_strength])
    {
        // slowly fade the berzerk out
        bzc = 12 - (player.powers[pw_strength]>>6);

        if (bzc > cnt)
            cnt = bzc;
    }
        
    if (cnt)
    {
        palette = (cnt+7)>>3;
        
        if (palette >= NUMREDPALS)
            palette = NUMREDPALS-1;

        palette += STARTREDPALS;
    }

    else if (player.bonuscount)
    {
        palette = (player.bonuscount+7)>>3;

        if (palette >= NUMBONUSPALS)
            palette = NUMBONUSPALS-1;

        palette += STARTBONUSPALS;
    }

    else if (player.powers[pw_ironfeet] > 4*32
              || player.powers[pw_ironfeet]&8)
        palette = RADIATIONPAL;
    else
        palette = 0;

    if (palette != st_palette)
    {
        st_palette = palette;
        I_SetPalette (palette);
    }

}




void __near STlib_updateflag() {
	if (!updatedthisframe) {
		Z_QuickMapStatus();
		updatedthisframe = true;
	}
}


void __near STlib_updateMultIcon ( st_multicon_t __near* mi, int16_t inum, boolean        is_binicon) {
    int16_t            w;
    int16_t            h;
    int16_t            x;
    int16_t            y;
    patch_t __far*    old;
    uint16_t offset;

    if ((mi->oldinum != inum || do_st_refresh) && (inum != -1)) {
        STlib_updateflag();
        if (!is_binicon && mi->oldinum != -1) {
            old = (patch_t __far*)(MK_FP(ST_GRAPHICS_SEGMENT, mi->patch_offset[mi->oldinum]));
            x = mi->x - (old->leftoffset);
            y = mi->y - (old->topoffset);
            w = (old->width);
            h = (old->height);

#ifdef CHECK_FOR_ERRORS
            if (y - ST_Y < 0) {
                I_Error("updateMultIcon: y - ST_Y < 0");
            }
#endif

            V_MarkRect (x, y, w, h); 
            offset = x+y*SCREENWIDTH;
            V_CopyRect(offset - (ST_Y*SCREENWIDTH), offset,  w, h);
        } 
            
        // binicon only has an array length zero and inum is always 1; this inum-is_binicon
        // to work on the same line of code.
        V_DrawPatch(mi->x, mi->y, FG, (patch_t __far*)(MK_FP(ST_GRAPHICS_SEGMENT, mi->patch_offset[inum-is_binicon])));

        mi->oldinum = inum;
    }
}


void __near STlib_drawNum ( st_number_t __near*	number, int16_t num) {
    uint8_t	numdigits = number->width;
    uint8_t	digitwidth;
	patch_t __far* p0;
	int16_t w;
	int16_t h;
	int16_t x = number->x;
    
    int16_t	neg;

	// [crispy] redraw only if necessary
	if (number->oldnum == num && !do_st_refresh) {
		return;
	}
	
	STlib_updateflag();

	p0 = (patch_t __far*)(MK_FP(ST_GRAPHICS_SEGMENT, number->patch_offset[0]));
	w = (p0->width);
	h = (p0->height);


	number->oldnum = num;

    neg = num < 0;

    if (neg)
    {
	if (numdigits == 2 && num < -9)
	    num = -9;
	else if (numdigits == 3 && num < -99)
	    num = -99;
	
	num = -num;
    }

    // clear the area
    //digitwidth = FastMul8u8u(w,numdigits);
    digitwidth = w * numdigits;
    x = number->x - digitwidth;

    V_MarkRect (x, number->y, digitwidth, h); 
    V_CopyRect (x + SCREENWIDTH*(number->y - ST_Y), x + SCREENWIDTH*number->y, digitwidth, h);

    // if non-number, do not draw it
    if (num == 1994)
		return;

    x = number->x;

	// in the special case of 0, you draw 0
	if (!num) {
		V_DrawPatch(x - w, number->y, FG, (patch_t __far*)(MK_FP(ST_GRAPHICS_SEGMENT, number->patch_offset[0])));
	}
    // draw the new number
    while (num && numdigits--) {
		x -= w;
		V_DrawPatch(x, number->y, FG, (patch_t __far*)(MK_FP(ST_GRAPHICS_SEGMENT, number->patch_offset[ num % 10 ])));
		num /= 10;
    }
 
}



void __near STlib_updatePercent ( st_percent_t __near* per, int16_t value) {
    if (do_st_refresh) {
        STlib_updateflag();
        V_DrawPatch(per->num.x, per->num.y, FG, (patch_t __far*)(MK_FP(ST_GRAPHICS_SEGMENT, per->patch_offset)));
    }
    STlib_drawNum(&per->num, value);
}

void __near ST_drawWidgets() {
    int8_t i;

    // used by w_arms[] widgets

    if (st_statusbaron) {
        for (i = 0; i < 4; i++) {
            STlib_drawNum(&w_ammo[i], player.ammo[i]);
            STlib_drawNum(&w_maxammo[i], player.maxammo[i]);
        }

        STlib_drawNum(&w_ready, player.ammo[weaponinfo[player.readyweapon].ammo]);

        STlib_updatePercent(&w_health, player.health);
        STlib_updatePercent(&w_armor, player.armorpoints);
        STlib_updateMultIcon(&w_armsbg, true, true);
 
        for (i = 0; i < 6; i++) {
            STlib_updateMultIcon(&w_arms[i], player.weaponowned[i + 1], false);
        }
        STlib_updateMultIcon(&w_faces, st_faceindex, false);

        for (i = 0; i < 3; i++) {
            STlib_updateMultIcon(&w_keyboxes[i], keyboxes[i], false);
        }
    }
}

void __near ST_Drawer(boolean fullscreen, boolean refresh) {
    st_statusbaron = (!fullscreen) || automapactive;
    st_firsttime = st_firsttime || refresh;
    updatedthisframe = false;
    // Do red-/gold-shifts from damage/items
    ST_doPaletteStuff();

    // If just after ST_Start(), refresh all
    if (st_firsttime) {
        st_firsttime = false;
        updatedthisframe = true;
        Z_QuickMapStatus();

        // draw status bar background to off-screen buff
        ST_refreshBackground();

        // and refresh all widgets
        do_st_refresh = true;
        ST_drawWidgets();
    } else {
        // Otherwise, update as little as possible
        do_st_refresh = false;
        ST_drawWidgets();
    }

    if (updatedthisframe) {
        Z_QuickMapPhysics();
    }
}



 


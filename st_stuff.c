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


            
// ST_Start() has just been called
boolean          st_firsttime;
boolean          updatedthisframe;

// used to execute ST_Init() only once

// lump number for PLAYPAL
//int16_t              lu_palette;
//byte __far*  palettebytes;

// used for timing


// whether in automap or first-person
st_stateenum_t   st_gamestate;

// whether left-side main status bar is active
boolean          st_statusbaron;

// main bar left
//uint16_t         sbar;

// 0-9, tall numbers
uint16_t         tallnum[10] = { 65216u, 64972u, 64636u, 64300u, 63984u, 63636u, 63296u, 63020u, 62672u, 62336u };


// 0-9, short, yellow (,different!) numbers
uint16_t         shortnum[10] = { 62268u, 62204u, 62128u, 62056u, 61996u, 61924u, 61852u, 61780u, 61704u, 61632u};


// 3 key-cards, 3 skulls
uint16_t         keys[NUMCARDS] = { 61200u, 61096u, 60992u, 60872u, 60752u, 60632u };


// face status patches
uint16_t         faces[ST_NUMFACES] = { 43216u,
        42408u, 41600u, 40720u, 39836u, 38992u,
        38176u, 37352u, 36544u, 35736u, 34936u,
        34048u, 33164u, 32320u, 31504u, 30680u,
        29856u, 29028u, 28204u, 27308u, 26412u,
        25568u, 24752u, 23928u, 23088u, 22252u,
        21420u, 20512u, 19568u, 18724u, 17908u,
        17084u, 16240u, 15404u, 14560u, 13652u,
        12668u, 11824u, 11008u, 10184u, 9376u,
        8540u

};

// weapon ownership patches
uint16_t arms[6][2] = { {58908u, 0}, {58836u, 0}, {58776u, 0}, {58704u, 0}, {58632u, 0}, {58560u, 0} };


// ready-weapon widget
st_number_t      w_ready;


// health widget
st_percent_t     w_health;

// arms background
st_multicon_t     w_armsbg;
//st_binicon_t     w_armsbg;


// weapon ownership widgets
st_multicon_t    w_arms[6];

// face status widget
st_multicon_t    w_faces; 

// keycard widgets
st_multicon_t    w_keyboxes[3];

// armor widget
st_percent_t     w_armor;

// ammo widgets
st_number_t      w_ammo[4];

// max ammo widgets
st_number_t      w_maxammo[4]; 




// used to use appopriately pained face
int16_t      st_oldhealth = -1;

// used for evil grin
boolean  oldweaponsowned[NUMWEAPONS]; 

 // count until face changes
int16_t      st_facecount = 0;

// current face index, used by w_faces
int16_t      st_faceindex = 0;

// holds key-type for each key box on bar
int16_t      keyboxes[3];

// a random number per tick
uint8_t      st_randomnumber;



// Massive bunches of cheat shit
//  to keep it from being easy to figure them out.
// Yeah, right...
uint8_t   cheat_mus_seq[] = {
    'i', 'd', 'm', 'u', 's', 1, 0, 0, 0xff
};

uint8_t   cheat_choppers_seq[] = {
    'i', 'd', 'c', 'h', 'o', 'p', 'p', 'e', 'r', 's', 0xff // idchoppers
};

uint8_t   cheat_god_seq[] = {
    'i', 'd', 'd', 'q', 'd', 0xff // iddqd
};

uint8_t   cheat_ammo_seq[] = {
    'i', 'd', 'k', 'f', 'a', 0xff // idkfa
};

uint8_t   cheat_ammonokey_seq[] = {
    'i', 'd', 'f', 'a', 0xff // idfa
};


// Smashing Pumpkins Into Samml Piles Of Putried Debris. 
uint8_t   cheat_noclip_seq[] = {
    'i', 'd', 's', 'p', 'i', // idspispopd
    's', 'p', 'o', 'p', 'd', 0xff
};

//
uint8_t   cheat_commercial_noclip_seq[] = {
    'i', 'd', 'c', 'l', 'i', 'p', 0xff // idclip
}; 



uint8_t   cheat_powerup_seq[7][10] = {
    {'i', 'd', 'b', 'e', 'h', 'o', 'l', 'd', 'v', 0xff}, // beholdv
    {'i', 'd', 'b', 'e', 'h', 'o', 'l', 'd', 's', 0xff}, // beholds
    {'i', 'd', 'b', 'e', 'h', 'o', 'l', 'd', 'i', 0xff}, // beholdi
    {'i', 'd', 'b', 'e', 'h', 'o', 'l', 'd', 'r', 0xff}, // beholdr
    {'i', 'd', 'b', 'e', 'h', 'o', 'l', 'd', 'a', 0xff}, // beholda
    {'i', 'd', 'b', 'e', 'h', 'o', 'l', 'd', 'l', 0xff}, // beholdl
    {'i', 'd', 'b', 'e', 'h', 'o', 'l', 'd', 0xff}     // behold
};


uint8_t   cheat_clev_seq[] = {
    'i', 'd', 'c', 'l', 'e', 'v', 1, 0, 0, 0xff // idclev
};


// my position cheat
uint8_t   cheat_mypos_seq[] = {
    'i', 'd', 'm', 'y', 'p', 'o', 's', 0xff // idmypos   
}; 


// Now what?
cheatseq_t      cheat_mus = { cheat_mus_seq, 0 };
cheatseq_t      cheat_god = { cheat_god_seq, 0 };
cheatseq_t      cheat_ammo = { cheat_ammo_seq, 0 };
cheatseq_t      cheat_ammonokey = { cheat_ammonokey_seq, 0 };
cheatseq_t      cheat_noclip = { cheat_noclip_seq, 0 };
cheatseq_t      cheat_commercial_noclip = { cheat_commercial_noclip_seq, 0 };

cheatseq_t      cheat_powerup[7] = {
    { cheat_powerup_seq[0], 0 },
    { cheat_powerup_seq[1], 0 },
    { cheat_powerup_seq[2], 0 },
    { cheat_powerup_seq[3], 0 },
    { cheat_powerup_seq[4], 0 },
    { cheat_powerup_seq[5], 0 },
    { cheat_powerup_seq[6], 0 }
};

cheatseq_t      cheat_choppers = { cheat_choppers_seq, 0 };
cheatseq_t      cheat_clev = { cheat_clev_seq, 0 };
cheatseq_t      cheat_mypos = { cheat_mypos_seq, 0 };


// 
extern int8_t*    mapnames[];

boolean do_st_refresh;

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
    
  // Filter automap on/off.
  if (ev->type == ev_keyup
      && ((ev->data1 & 0xffff0000) == AM_MSGHEADER))
  {
    switch(ev->data1)
    {
      case AM_MSGENTERED:
        st_gamestate = AutomapState;
        st_firsttime = true;
        break;
        
      case AM_MSGEXITED:
        st_gamestate = FirstPersonState;
        break;
    }
  }

  // if a user keypress...
  else if (ev->type == ev_keydown) {
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
          static int8_t     buf[ST_MSGWIDTH];

//todo: this      player pos  
        /*
        sprintf(buf, "ang=0x%lx;x,y=(0x%lx,0x%lx)",
                playerMobj_pos->angle,
                playerMobj_pos->x,
                playerMobj_pos->y);
                */
        //memcpy(player.messagestring, buf, 40);
        player.messagestring = buf;
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
    static int16_t  lastcalc;
    static int16_t  oldhealth = -1;
    
    health = player.health > 100 ? 100 : player.health;

    if (health != oldhealth) {
        lastcalc = ST_FACESTRIDE * (((100 - health) * ST_NUMPAINFACES) / 101);
        oldhealth = health;
    }
    return lastcalc;
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
    static int8_t  lastattackdown = -1;
    static int8_t  priority = 0;
    boolean     doevilgrin;
    mobj_pos_t __far* plyrattacker_pos;

    if (priority < 10) {
        // dead
        if (!player.health) {
            priority = 9;
            st_faceindex = ST_DEADFACE;
            st_facecount = 1;
        }
    }

    if (priority < 9) {
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
                priority = 8;
                st_facecount = ST_EVILGRINCOUNT;
                st_faceindex = ST_calcPainOffset() + ST_EVILGRINOFFSET;
            }
        }

    }
  
    if (priority < 8) {
        if (player.damagecount
            && player.attackerRef
            && player.attackerRef != playerMobjRef) {
            // being attacked
            priority = 7;
            
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
  
    if (priority < 7) {
        // getting hurt because of your own damn stupidity
        if (player.damagecount) {
            if (player.health - st_oldhealth > ST_MUCHPAIN) {
                priority = 7;
                st_facecount = ST_TURNCOUNT;
                st_faceindex = ST_calcPainOffset() + ST_OUCHOFFSET;
            } else {
                priority = 6;
                st_facecount = ST_TURNCOUNT;
                st_faceindex = ST_calcPainOffset() + ST_RAMPAGEOFFSET;
            }

        }

    }
  
    if (priority < 6) {
        // rapid firing
        if (player.attackdown) {
            if (lastattackdown == -1) {
                lastattackdown = ST_RAMPAGEDELAY;
            } else if (!--lastattackdown) {
                priority = 5;
                st_faceindex = ST_calcPainOffset() + ST_RAMPAGEOFFSET;
                st_facecount = 1;
                lastattackdown = 1;
            }
        } else {
            lastattackdown = -1;
        }
    }
  
    if (priority < 5) {
        // invulnerability
        if ((player.cheats & CF_GODMODE)
            || player.powers[pw_invulnerability]) {
            priority = 4;

            st_faceindex = ST_GODFACE;
            st_facecount = 1;

        }

    }

    // look left or look right if the facecount has timed out
    if (!st_facecount) {
        st_faceindex = ST_calcPainOffset() + (st_randomnumber % 3);
        st_facecount = ST_STRAIGHTFACECOUNT;
        priority = 0;
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

int8_t st_palette = 0;

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



 


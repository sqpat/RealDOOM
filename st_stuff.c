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

//
// STATUS BAR DATA
//


// Palette indices.
// For damage/bonus red-/gold-shifts
#define STARTREDPALS            1
#define STARTBONUSPALS          9
#define NUMREDPALS                      8
#define NUMBONUSPALS            4
// Radiation suit, green shift.
#define RADIATIONPAL            13

// N/256*100% probability
//  that the normal face state will change
#define ST_FACEPROBABILITY              96


// Location of status bar
#define ST_X                            0
#define ST_X2                           104

#define ST_FX                   143
#define ST_FY                   169

// Should be set to patch width
//  for tall numbers later on

// Number of status faces.
#define ST_NUMPAINFACES         5
#define ST_NUMSTRAIGHTFACES     3
#define ST_NUMTURNFACES         2
#define ST_NUMSPECIALFACES              3

#define ST_FACESTRIDE \
          (ST_NUMSTRAIGHTFACES+ST_NUMTURNFACES+ST_NUMSPECIALFACES)

#define ST_NUMEXTRAFACES                2

#define ST_NUMFACES \
          (ST_FACESTRIDE*ST_NUMPAINFACES+ST_NUMEXTRAFACES)

#define ST_TURNOFFSET           (ST_NUMSTRAIGHTFACES)
#define ST_OUCHOFFSET           (ST_TURNOFFSET + ST_NUMTURNFACES)
#define ST_EVILGRINOFFSET               (ST_OUCHOFFSET + 1)
#define ST_RAMPAGEOFFSET                (ST_EVILGRINOFFSET + 1)
#define ST_GODFACE                      (ST_NUMPAINFACES*ST_FACESTRIDE)
#define ST_DEADFACE                     (ST_GODFACE+1)

#define ST_FACESX                       143
#define ST_FACESY                       168

#define ST_EVILGRINCOUNT                (2*TICRATE)
#define ST_STRAIGHTFACECOUNT    (TICRATE/2)
#define ST_TURNCOUNT            (1*TICRATE)
#define ST_OUCHCOUNT            (1*TICRATE)
#define ST_RAMPAGEDELAY         (2*TICRATE)

#define ST_MUCHPAIN                     20


// Location and size of statistics,
//  justified according to widget type.
// Problem is, within which space? STbar? Screen?
// Note: this could be read in by a lump.
//       Problem is, is the stuff rendered
//       into a buffer,
//       or into the frame buffer?

// AMMO number pos.
#define ST_AMMOWIDTH            3       
#define ST_AMMOX                        44
#define ST_AMMOY                        171

// HEALTH number pos.
#define ST_HEALTHWIDTH          3       
#define ST_HEALTHX                      90
#define ST_HEALTHY                      171

// Weapon pos.
#define ST_ARMSX                        111
#define ST_ARMSY                        172
#define ST_ARMSBGX                      104
#define ST_ARMSBGY                      168
#define ST_ARMSXSPACE           12
#define ST_ARMSYSPACE           10


// ARMOR number pos.
#define ST_ARMORWIDTH           3
#define ST_ARMORX                       221
#define ST_ARMORY                       171

// Key icon positions.
#define ST_KEY0WIDTH            8
#define ST_KEY0HEIGHT           5
#define ST_KEY0X                        239
#define ST_KEY0Y                        171
#define ST_KEY1WIDTH            ST_KEY0WIDTH
#define ST_KEY1X                        239
#define ST_KEY1Y                        181
#define ST_KEY2WIDTH            ST_KEY0WIDTH
#define ST_KEY2X                        239
#define ST_KEY2Y                        191

// Ammunition counter.
#define ST_AMMO0WIDTH           3
#define ST_AMMO0HEIGHT          6
#define ST_AMMO0X                       288
#define ST_AMMO0Y                       173
#define ST_AMMO1WIDTH           ST_AMMO0WIDTH
#define ST_AMMO1X                       288
#define ST_AMMO1Y                       179
#define ST_AMMO2WIDTH           ST_AMMO0WIDTH
#define ST_AMMO2X                       288
#define ST_AMMO2Y                       191
#define ST_AMMO3WIDTH           ST_AMMO0WIDTH
#define ST_AMMO3X                       288
#define ST_AMMO3Y                       185

// Indicate maximum ammunition.
// Only needed because backpack exists.
#define ST_MAXAMMO0WIDTH                3
#define ST_MAXAMMO0HEIGHT               5
#define ST_MAXAMMO0X            314
#define ST_MAXAMMO0Y            173
#define ST_MAXAMMO1WIDTH                ST_MAXAMMO0WIDTH
#define ST_MAXAMMO1X            314
#define ST_MAXAMMO1Y            179
#define ST_MAXAMMO2WIDTH                ST_MAXAMMO0WIDTH
#define ST_MAXAMMO2X            314
#define ST_MAXAMMO2Y            191
#define ST_MAXAMMO3WIDTH                ST_MAXAMMO0WIDTH
#define ST_MAXAMMO3X            314
#define ST_MAXAMMO3Y            185

// pistol
#define ST_WEAPON0X                     110 
#define ST_WEAPON0Y                     172

// shotgun
#define ST_WEAPON1X                     122 
#define ST_WEAPON1Y                     172

// chain gun
#define ST_WEAPON2X                     134 
#define ST_WEAPON2Y                     172

// missile launcher
#define ST_WEAPON3X                     110 
#define ST_WEAPON3Y                     181

// plasma gun
#define ST_WEAPON4X                     122 
#define ST_WEAPON4Y                     181

 // bfg
#define ST_WEAPON5X                     134
#define ST_WEAPON5Y                     181

// WPNS title
#define ST_WPNSX                        109 
#define ST_WPNSY                        191

 // DETH title
#define ST_DETHX                        109
#define ST_DETHY                        191

//Incoming messages window location
#define ST_MSGTEXTX                     0
#define ST_MSGTEXTY                     0
// Dimensions given in characters.
#define ST_MSGWIDTH                     52
// Or shall I say, in lines?
#define ST_MSGHEIGHT            1

#define ST_OUTTEXTX                     0
#define ST_OUTTEXTY                     6

// Width, in characters again.
#define ST_OUTWIDTH                     52 
 // Height, in lines. 
#define ST_OUTHEIGHT            1

#define ST_MAPWIDTH     \
    (strlen(mapnames[(gameepisode-1)*9+(gamemap-1)]))

#define ST_MAPTITLEX \
    (SCREENWIDTH - ST_MAPWIDTH * ST_CHATFONTWIDTH)

#define ST_MAPTITLEY            0
#define ST_MAPHEIGHT            1

            
// ST_Start() has just been called
static boolean          st_firsttime;

// used to execute ST_Init() only once

// lump number for PLAYPAL
static int16_t              lu_palette;

// used for timing


// whether in automap or first-person
static st_stateenum_t   st_gamestate;

// whether left-side main status bar is active
static boolean          st_statusbaron;

// main bar left
static MEMREF         sbarRef;

// 0-9, tall numbers
static MEMREF         tallnumRef[10];

// tall % sign
static MEMREF         tallpercentRef;

// 0-9, short, yellow (,different!) numbers
static MEMREF         shortnumRef[10];

// 3 key-cards, 3 skulls
static MEMREF         keysRef[NUMCARDS];

// face status patches
static MEMREF         facesRef[ST_NUMFACES];

// face background
static MEMREF         facebackRef;

 // main bar right
static MEMREF         armsbgRef[1];

// weapon ownership patches
static MEMREF	armsRef[6][2]; 

// ready-weapon widget
static st_number_t      w_ready;


// health widget
static st_percent_t     w_health;

// arms background
static st_multicon_t     w_armsbg;
//static st_binicon_t     w_armsbg;


// weapon ownership widgets
static st_multicon_t    w_arms[6];

// face status widget
static st_multicon_t    w_faces; 

// keycard widgets
static st_multicon_t    w_keyboxes[3];

// armor widget
static st_percent_t     w_armor;

// ammo widgets
static st_number_t      w_ammo[4];

// max ammo widgets
static st_number_t      w_maxammo[4]; 




// used to use appopriately pained face
static int16_t      st_oldhealth = -1;

// used for evil grin
static boolean  oldweaponsowned[NUMWEAPONS]; 

 // count until face changes
static int16_t      st_facecount = 0;

// current face index, used by w_faces
static int16_t      st_faceindex = 0;

// holds key-type for each key box on bar
static int16_t      keyboxes[3];

// a random number per tick
static uint8_t      st_randomnumber;



// Massive bunches of cheat shit
//  to keep it from being easy to figure them out.
// Yeah, right...
uint8_t   cheat_mus_seq[] =
{
	'i', 'd', 'm', 'u', 's', 1, 0, 0, 0xff
};

uint8_t   cheat_choppers_seq[] =
{
    'i', 'd', 'c', 'h', 'o', 'p', 'p', 'e', 'r', 's', 0xff // idchoppers
};

uint8_t   cheat_god_seq[] =
{
    'i', 'd', 'd', 'q', 'd', 0xff // iddqd
};

uint8_t   cheat_ammo_seq[] =
{
    'i', 'd', 'k', 'f', 'a', 0xff // idkfa
};

uint8_t   cheat_ammonokey_seq[] =
{
    'i', 'd', 'f', 'a', 0xff // idfa
};


// Smashing Pumpkins Into Samml Piles Of Putried Debris. 
uint8_t   cheat_noclip_seq[] =
{
    'i', 'd', 's', 'p', 'i', // idspispopd
    's', 'p', 'o', 'p', 'd', 0xff
};

//
uint8_t   cheat_commercial_noclip_seq[] =
{
    'i', 'd', 'c', 'l', 'i', 'p', 0xff // idclip
}; 



uint8_t   cheat_powerup_seq[7][10] =
{
    {'i', 'd', 'b', 'e', 'h', 'o', 'l', 'd', 'v', 0xff}, // beholdv
    {'i', 'd', 'b', 'e', 'h', 'o', 'l', 'd', 's', 0xff}, // beholds
    {'i', 'd', 'b', 'e', 'h', 'o', 'l', 'd', 'i', 0xff}, // beholdi
    {'i', 'd', 'b', 'e', 'h', 'o', 'l', 'd', 'r', 0xff}, // beholdr
    {'i', 'd', 'b', 'e', 'h', 'o', 'l', 'd', 'a', 0xff}, // beholda
    {'i', 'd', 'b', 'e', 'h', 'o', 'l', 'd', 'l', 0xff}, // beholdl
    {'i', 'd', 'b', 'e', 'h', 'o', 'l', 'd', 0xff}	 // behold
};


uint8_t   cheat_clev_seq[] =
{
    'i', 'd', 'c', 'l', 'e', 'v', 1, 0, 0, 0xff // idclev
};


// my position cheat
uint8_t   cheat_mypos_seq[] =
{
    'i', 'd', 'm', 'y', 'p', 'o', 's', 0xff // idmypos   
}; 


// Now what?
cheatseq_t      cheat_mus = { cheat_mus_seq, 0 };
cheatseq_t      cheat_god = { cheat_god_seq, 0 };
cheatseq_t      cheat_ammo = { cheat_ammo_seq, 0 };
cheatseq_t      cheat_ammonokey = { cheat_ammonokey_seq, 0 };
cheatseq_t      cheat_noclip = { cheat_noclip_seq, 0 };
cheatseq_t      cheat_commercial_noclip = { cheat_commercial_noclip_seq, 0 };

cheatseq_t      cheat_powerup[7] =
{
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


//
// STATUS BAR CODE
//
void ST_Stop(void);

void ST_refreshBackground(void)
{

    if (st_statusbaron) {
        V_DrawPatch(ST_X, 0, BG, (patch_t*)Z_LoadBytesFromEMS(sbarRef));
        V_CopyRect(ST_X, 0, ST_WIDTH, ST_HEIGHT, ST_X, ST_Y);
    }

}


// Respond to keyboard input events,
//  intercept cheats.
boolean
ST_Responder (event_t* ev)
{
	int8_t           i;
  mobj_t* plyrmo;
    
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
        //      fprintf(stderr, "AM exited\n");
        st_gamestate = FirstPersonState;
        break;
    }
  }

  // if a user keypress...
  else if (ev->type == ev_keydown)
  {
    if (gameskill != sk_nightmare)
    {
      // 'dqd' cheat for toggleable god mode
      if (cht_CheckCheat(&cheat_god, ev->data1))
      {
		  player.cheats ^= CF_GODMODE;
        if (player.cheats & CF_GODMODE)
        {
			plyrmo = (mobj_t*) Z_LoadBytesFromEMS(playermoRef);
          if (plyrmo)
            plyrmo->health = 100;
          
		  player.health = 100;
		  player.message = STSTR_DQDON;
        }
        else 
			player.message = STSTR_DQDOFF;
      }
      // 'fa' cheat for killer fucking arsenal
      else if (cht_CheckCheat(&cheat_ammonokey, ev->data1))
      {
		  player.armorpoints = 200;
		  player.armortype = 2;
        
        for (i=0;i<NUMWEAPONS;i++)
			player.weaponowned[i] = true;
        
        for (i=0;i<NUMAMMO;i++)
			player.ammo[i] = player.maxammo[i];
        
		player.message = STSTR_FAADDED;
      }
      // 'kfa' cheat for key full ammo
      else if (cht_CheckCheat(&cheat_ammo, ev->data1))
      {
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
      else if (cht_CheckCheat(&cheat_mus, ev->data1))
      {
        
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
      }
      else if(!commercial && cht_CheckCheat(&cheat_noclip, ev->data1))
      { 
		  player.cheats ^= CF_NOCLIP;
        
        if (player.cheats & CF_NOCLIP)
			player.message = STSTR_NCON;
        else
			player.message = STSTR_NCOFF;
      }
      else if (commercial
          && cht_CheckCheat(&cheat_commercial_noclip, ev->data1))
      {
		  player.cheats ^= CF_NOCLIP;
        
        if (player.cheats & CF_NOCLIP)
			player.message = STSTR_NCON;
        else
			player.message = STSTR_NCOFF;
      }
      // 'behold?' power-up cheats
      for (i=0;i<6;i++)
      {
        if (cht_CheckCheat(&cheat_powerup[i], ev->data1))
        {
          if (!player.powers[i])
            P_GivePower( i);
          else if (i!=pw_strength)
			  player.powers[i] = 1;
          else
			  player.powers[i] = 0;
          
		  player.message = STSTR_BEHOLDX;
        }
      }
      
      // 'behold' power-up menu
      if (cht_CheckCheat(&cheat_powerup[6], ev->data1))
      {
		  player.message = STSTR_BEHOLD;
      }
      // 'choppers' invulnerability & chainsaw
      else if (cht_CheckCheat(&cheat_choppers, ev->data1))
      {
		  player.weaponowned[wp_chainsaw] = true;
		  player.powers[pw_invulnerability] = true;
		  player.message = STSTR_CHOPPERS;
      }
      // 'mypos' for player position
      else if (cht_CheckCheat(&cheat_mypos, ev->data1))
      {
        static int8_t     buf[ST_MSGWIDTH];
		plyrmo = Z_LoadBytesFromEMS(playermoRef);
		sprintf(buf, "ang=0x%x;x,y=(0x%x,0x%x)",
                plyrmo->angle,
			plyrmo->x,
			plyrmo->y);
		player.messagestring = buf;
      }
    }
    
    // 'clev' change-level cheat
    if (cht_CheckCheat(&cheat_clev, ev->data1))
    {
		int8_t              buf[3];
		int8_t               epsd;
		int8_t               map;
      
      cht_GetParam(&cheat_clev, buf);
      
      if (commercial)
      {
        epsd = 0;
        map = (buf[0] - '0')*10 + buf[1] - '0';
      }
      else
      {
        epsd = buf[0] - '0';
        map = buf[1] - '0';
      }

      // Catch invalid maps.
#if (EXE_VERSION < EXE_VERSION_ULTIMATE)
      if ((!commercial && epsd > 0 && epsd < 4 && map > 0 && map < 10)
       || (commercial && map > 0 && map <= 40))
      {
          // So be it.
		  player.message = STSTR_CLEV;
          G_DeferedInitNew(gameskill, epsd, map);
      }
#else
      if ((!commercial && epsd > 0 && epsd < 5 && map > 0 && map < 10)
       || (commercial && map > 0 && map <= 40))
      {
          // So be it.
		  players.message = STSTR_CLEV;
          G_DeferedInitNew(gameskill, epsd, map);
      }
#endif
    }    
  }
  return false;
}



int16_t ST_calcPainOffset(void)
{
	int16_t         health;
    static int16_t  lastcalc;
    static int16_t  oldhealth = -1;
    
    health = player.health > 100 ? 100 : player.health;

    if (health != oldhealth)
    {
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
void ST_updateFaceWidget(void)
{
	int8_t         i;
    angle_t     badguyangle;
    angle_t     diffang;
    static int8_t  lastattackdown = -1;
    static int8_t  priority = 0;
    boolean     doevilgrin;
	mobj_t* plyrmo;
	mobj_t* plyrattacker;

    if (priority < 10)
    {
        // dead
        if (!player.health)
        {
            priority = 9;
            st_faceindex = ST_DEADFACE;
            st_facecount = 1;
        }
    }

    if (priority < 9)
    {
        if (player.bonuscount)
        {
            // picking up bonus
            doevilgrin = false;

            for (i=0;i<NUMWEAPONS;i++)
            {
                if (oldweaponsowned[i] != player.weaponowned[i])
                {
                    doevilgrin = true;
                    oldweaponsowned[i] = player.weaponowned[i];
                }
            }
            if (doevilgrin) 
            {
                // evil grin if just picked up weapon
                priority = 8;
                st_facecount = ST_EVILGRINCOUNT;
                st_faceindex = ST_calcPainOffset() + ST_EVILGRINOFFSET;
            }
        }

    }
  
    if (priority < 8)
    {
        if (player.damagecount
            && player.attackerRef
            && player.attackerRef != playermoRef)
        {
            // being attacked
            priority = 7;
            
            if (player.health - st_oldhealth > ST_MUCHPAIN)
            {
                st_facecount = ST_TURNCOUNT;
                st_faceindex = ST_calcPainOffset() + ST_OUCHOFFSET;
            }
            else
            {
				plyrmo = (mobj_t*) Z_LoadBytesFromEMS(playermoRef);
				plyrattacker = (mobj_t*)Z_LoadBytesFromEMS(player.attackerRef);
				badguyangle = R_PointToAngle2(plyrmo->x,
                                              plyrmo->y,
                                              plyrattacker->x,
                                              plyrattacker->y);
                
                if (badguyangle > plyrmo->angle)
                {
                    // whether right or left
                    diffang = badguyangle - plyrmo->angle;
                    i = diffang > ANG180; 
                } else {
                    // whether left or right
                    diffang = plyrmo->angle - badguyangle;
                    i = diffang <= ANG180; 
                } // confusing, aint it?

                
                st_facecount = ST_TURNCOUNT;
                st_faceindex = ST_calcPainOffset();
                
                if (diffang < ANG45)
                {
                    // head-on    
                    st_faceindex += ST_RAMPAGEOFFSET;
                }
                else if (i)
                {
                    // turn face right
                    st_faceindex += ST_TURNOFFSET;
                }
                else
                {
                    // turn face left
                    st_faceindex += ST_TURNOFFSET+1;
                }
            }
        }
    }
  
    if (priority < 7)
    {
        // getting hurt because of your own damn stupidity
        if (player.damagecount)
        {
            if (player.health - st_oldhealth > ST_MUCHPAIN)
            {
                priority = 7;
                st_facecount = ST_TURNCOUNT;
                st_faceindex = ST_calcPainOffset() + ST_OUCHOFFSET;
            }
            else
            {
                priority = 6;
                st_facecount = ST_TURNCOUNT;
                st_faceindex = ST_calcPainOffset() + ST_RAMPAGEOFFSET;
            }

        }

    }
  
    if (priority < 6)
    {
        // rapid firing
        if (player.attackdown)
        {
            if (lastattackdown==-1)
                lastattackdown = ST_RAMPAGEDELAY;
            else if (!--lastattackdown)
            {
                priority = 5;
                st_faceindex = ST_calcPainOffset() + ST_RAMPAGEOFFSET;
                st_facecount = 1;
                lastattackdown = 1;
            }
        }
        else
            lastattackdown = -1;

    }
  
    if (priority < 5)
    {
        // invulnerability
        if ((player.cheats & CF_GODMODE)
            || player.powers[pw_invulnerability])
        {
            priority = 4;

            st_faceindex = ST_GODFACE;
            st_facecount = 1;

        }

    }

    // look left or look right if the facecount has timed out
    if (!st_facecount)
    {
        st_faceindex = ST_calcPainOffset() + (st_randomnumber % 3);
        st_facecount = ST_STRAIGHTFACECOUNT;
        priority = 0;
    }

    st_facecount--;

}

void ST_updateWidgets(void)
{
	static int16_t largeammo = 1994; // means "n/a"
	int8_t i;

	/*
	if (weaponinfo[player.readyweapon].ammo == am_noammo)
		w_ready.num = &largeammo;
	else
		w_ready.num = &player.ammo[weaponinfo[player.readyweapon].ammo];
		*/

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

void ST_Ticker (void)
{

    st_randomnumber = M_Random();
    ST_updateWidgets();
    st_oldhealth = player.health;

}

static int16_t st_palette = 0;

void ST_doPaletteStuff(void)
{

	int16_t         palette;
    byte*       pal;
	int16_t         cnt;
	int16_t         bzc;
	MEMREF		palRef;

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
        palRef =  W_CacheLumpNumEMS (lu_palette, PU_CACHE);
		pal = (byte*)Z_LoadBytesFromEMS(palRef) + palette * 768;

		//pal = (byte*)W_CacheLumpNum(lu_palette, PU_CACHE) + palette * 768;
        I_SetPalette (pal);
    }

}

void ST_drawWidgets(boolean refresh)
{
	int8_t i;

	// used by w_arms[] widgets

	if (st_statusbaron) {
		for (i = 0; i < 4; i++) {
			STlib_drawNum(&w_ammo[i], refresh, player.ammo[i]);
			STlib_drawNum(&w_maxammo[i], refresh, player.maxammo[i]);
		}
		
		STlib_drawNum(&w_ready, refresh, player.ammo[weaponinfo[player.readyweapon].ammo]);

		STlib_updatePercent(&w_health, refresh, player.health);
		STlib_updatePercent(&w_armor, refresh, player.armorpoints);
		STlib_updateMultIcon(&w_armsbg, refresh, true, true);
		//STlib_updateBinIcon(&w_armsbg, refresh);

		for (i = 0; i < 6; i++) {
			STlib_updateMultIcon(&w_arms[i], refresh, player.weaponowned[i + 1], false);
		}
		STlib_updateMultIcon(&w_faces, refresh, st_faceindex, false);

		for (i = 0; i < 3; i++) {
			STlib_updateMultIcon(&w_keyboxes[i], refresh, keyboxes[i], false);
		}
	}
}
  

/*
void ST_Drawer (boolean fullscreen, boolean refresh)
{

    st_statusbaron = (!fullscreen) || automapactive;
    st_firsttime = st_firsttime || refresh;

    // Do red-/gold-shifts from damage/items
    ST_doPaletteStuff();

    // If just after ST_Start(), refresh all
    if (st_firsttime) ST_doRefresh();
    // Otherwise, update as little as possible
    else ST_diffDraw();
}

*/
void ST_Drawer(boolean fullscreen, boolean refresh)
{
	screen4 = (byte *)Z_LoadBytesFromEMSWithOptions(screen4Ref, true);
	st_statusbaron = (!fullscreen) || automapactive;
	st_firsttime = st_firsttime || refresh;

	// Do red-/gold-shifts from damage/items
	ST_doPaletteStuff();

	// If just after ST_Start(), refresh all
	if (st_firsttime) {
		st_firsttime = false;

		// draw status bar background to off-screen buff
		ST_refreshBackground();

		// and refresh all widgets
		ST_drawWidgets(true);
	} else {
	// Otherwise, update as little as possible
		ST_drawWidgets(false);
	}

	Z_SetUnlocked(screen4Ref);

	screen4 = NULL;

}


void ST_loadGraphics(void)
{

	int8_t         i;
	int8_t         j;
	int16_t         facenum;
    
	int8_t        namebuf[9];

    // Load the numbers, tall and short
    for (i=0;i<10;i++)
    {
        sprintf(namebuf, "STTNUM%d", i);
        tallnumRef[i] = W_CacheLumpNameEMS(namebuf, PU_STATIC);

        sprintf(namebuf, "STYSNUM%d", i);
        shortnumRef[i] = W_CacheLumpNameEMS(namebuf, PU_STATIC);
    }

    // Load percent key.
    //Note: why not load STMINUS here, too?
    tallpercentRef = W_CacheLumpNameEMS("STTPRCNT", PU_STATIC);

    // key cards
    for (i=0;i<NUMCARDS;i++)
    {
        sprintf(namebuf, "STKEYS%d", i);
        keysRef[i] = W_CacheLumpNameEMS(namebuf, PU_STATIC);
    }

    // arms background
    armsbgRef[0] = W_CacheLumpNameEMS("STARMS", PU_STATIC);

    // arms ownership widgets
    for (i=0;i<6;i++)
    {
        sprintf(namebuf, "STGNUM%d", i+2);

        // gray #
        armsRef[i][0] =  W_CacheLumpNameEMS(namebuf, PU_STATIC);

        // yellow #
        armsRef[i][1] = shortnumRef[i+2]; 
    }

    // face backgrounds for different color players
    sprintf(namebuf, "STFB0");
    facebackRef =  W_CacheLumpNameEMS(namebuf, PU_STATIC);

    // status bar background bits
    sbarRef = W_CacheLumpNameEMS("STBAR", PU_STATIC);

    // face states
    facenum = 0;
    for (i=0;i<ST_NUMPAINFACES;i++)
    {
        for (j=0;j<ST_NUMSTRAIGHTFACES;j++)
        {
            sprintf(namebuf, "STFST%d%d", i, j);
            facesRef[facenum++] = W_CacheLumpNameEMS(namebuf, PU_STATIC);
        }
        sprintf(namebuf, "STFTR%d0", i);        // turn right
        facesRef[facenum++] = W_CacheLumpNameEMS(namebuf, PU_STATIC);
        sprintf(namebuf, "STFTL%d0", i);        // turn left
        facesRef[facenum++] = W_CacheLumpNameEMS(namebuf, PU_STATIC);
        sprintf(namebuf, "STFOUCH%d", i);       // ouch!
        facesRef[facenum++] = W_CacheLumpNameEMS(namebuf, PU_STATIC);
        sprintf(namebuf, "STFEVL%d", i);        // evil grin ;)
        facesRef[facenum++] = W_CacheLumpNameEMS(namebuf, PU_STATIC);
        sprintf(namebuf, "STFKILL%d", i);       // pissed off
        facesRef[facenum++] = W_CacheLumpNameEMS(namebuf, PU_STATIC);
    }
    facesRef[facenum++] = W_CacheLumpNameEMS("STFGOD0", PU_STATIC);
    facesRef[facenum++] = W_CacheLumpNameEMS("STFDEAD0", PU_STATIC);

}

void ST_loadData(void)
{
    lu_palette = W_GetNumForName ("PLAYPAL");
    ST_loadGraphics();
}

void ST_unloadGraphics(void)
{

	int16_t i;

    // unload the numbers, tall and short
    for (i=0;i<10;i++)
    {
        Z_ChangeTagEMSNew(tallnumRef[i], PU_CACHE);
		Z_ChangeTagEMSNew(shortnumRef[i], PU_CACHE);
    }
    // unload tall percent
	Z_ChangeTagEMSNew(tallpercentRef, PU_CACHE);

    // unload arms background
    Z_ChangeTagEMSNew(armsbgRef[0], PU_CACHE); 

    // unload gray #'s
    for (i=0;i<6;i++)
		Z_ChangeTagEMSNew(armsRef[i][0], PU_CACHE);
    
    // unload the key cards
    for (i=0;i<NUMCARDS;i++)
		Z_ChangeTagEMSNew(keysRef[i], PU_CACHE);

	Z_ChangeTagEMSNew(sbarRef, PU_CACHE);
	Z_ChangeTagEMSNew(facebackRef, PU_CACHE);

    for (i=0;i<ST_NUMFACES;i++)
		Z_ChangeTagEMSNew(facesRef[i], PU_CACHE);

    // Note: nobody ain't seen no unloading
    //   of stminus yet. Dude.

}
  


void ST_createWidgets(void)
{

	int8_t i;

    // ready weapon ammo
	STlib_initNum(&w_ready,
                  ST_AMMOX,
                  ST_AMMOY,
                  tallnumRef,
                  ST_AMMOWIDTH );

    

    // health percentage
    STlib_initPercent(&w_health,
                      ST_HEALTHX,
                      ST_HEALTHY,
                      tallnumRef,
                      tallpercentRef);

    // arms background
	STlib_initMultIcon(&w_armsbg,
                      ST_ARMSBGX,
                      ST_ARMSBGY,
                      armsbgRef);
	w_armsbg.oldinum = 0; // hack to make it work as multicon instead of binicon

    // weapons owned
	for(i=0;i<6;i++)
    {
        STlib_initMultIcon(&w_arms[i],
                           ST_ARMSX+(i%3)*ST_ARMSXSPACE,
                           ST_ARMSY+(i/3)*ST_ARMSYSPACE,
                           armsRef[i]);

		


    }

  

    // faces
    STlib_initMultIcon(&w_faces,
                       ST_FACESX,
                       ST_FACESY,
                       facesRef);

    // armor percentage - should be colored later
    STlib_initPercent(&w_armor,
                      ST_ARMORX,
                      ST_ARMORY,
                      tallnumRef,
					tallpercentRef);

    // keyboxes 0-2
    STlib_initMultIcon(&w_keyboxes[0],
                       ST_KEY0X,
                       ST_KEY0Y,
                       keysRef);
    
    STlib_initMultIcon(&w_keyboxes[1],
                       ST_KEY1X,
                       ST_KEY1Y,
                       keysRef);

    STlib_initMultIcon(&w_keyboxes[2],
                       ST_KEY2X,
                       ST_KEY2Y,
                       keysRef);

    // ammo count (all four kinds)
    STlib_initNum(&w_ammo[0],
                  ST_AMMO0X,
                  ST_AMMO0Y,
                  shortnumRef,
                  ST_AMMO0WIDTH);

    STlib_initNum(&w_ammo[1],
                  ST_AMMO1X,
                  ST_AMMO1Y,
                  shortnumRef,
                  ST_AMMO1WIDTH);

    STlib_initNum(&w_ammo[2],
                  ST_AMMO2X,
                  ST_AMMO2Y,
                  shortnumRef,
                  ST_AMMO2WIDTH);
    
    STlib_initNum(&w_ammo[3],
                  ST_AMMO3X,
                  ST_AMMO3Y,
                  shortnumRef,
                  ST_AMMO3WIDTH);

    // max ammo count (all four kinds)
    STlib_initNum(&w_maxammo[0],
                  ST_MAXAMMO0X,
                  ST_MAXAMMO0Y,
                  shortnumRef,
                  ST_MAXAMMO0WIDTH);

    STlib_initNum(&w_maxammo[1],
                  ST_MAXAMMO1X,
                  ST_MAXAMMO1Y,
                  shortnumRef,
                  ST_MAXAMMO1WIDTH);

    STlib_initNum(&w_maxammo[2],
                  ST_MAXAMMO2X,
                  ST_MAXAMMO2Y,
                  shortnumRef,
                  ST_MAXAMMO2WIDTH);
    
    STlib_initNum(&w_maxammo[3],
                  ST_MAXAMMO3X,
                  ST_MAXAMMO3Y,
                  shortnumRef,
                  ST_MAXAMMO3WIDTH);

}

static boolean  st_stopped = true;


void ST_Start (void)
{
	int8_t         i;

    if (!st_stopped)
        ST_Stop();

	st_firsttime = true;
	st_gamestate = FirstPersonState;
	st_statusbaron = true;

	st_faceindex = 0;
	st_palette = -1;
	st_oldhealth = -1;

	for (i = 0; i < NUMWEAPONS; i++)
		oldweaponsowned[i] = player.weaponowned[i];

	for (i = 0; i < 3; i++)
		keyboxes[i] = -1;


    ST_createWidgets();
    st_stopped = false;

}

void ST_Stop (void)
{
	MEMREF palRef;
	byte*       pal;
	if (st_stopped)
        return;

	palRef = W_CacheLumpNumEMS(lu_palette, PU_CACHE);
	pal = (byte*)Z_LoadBytesFromEMS(palRef);
	I_SetPalette (pal);

//	I_SetPalette(W_CacheLumpNum(lu_palette, PU_CACHE));

    st_stopped = true;
}

void ST_Init (void)
{
    ST_loadData();
	screen4Ref = Z_MallocEMSNew (ST_WIDTH*ST_HEIGHT, PU_STATIC, 0, ALLOC_TYPE_SCREEN);
    
}

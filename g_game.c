//
// Copyright (C) 1993-1996 Id Software, Inc.
// Copyright (C) 1993-2008 Raven Software
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
// DESCRIPTION:  none
//

#include <string.h>
#include <stdlib.h>

#include "doomdef.h" 
#include "doomstat.h"

#include "z_zone.h"
#include "f_finale.h"
#include "m_misc.h"
#include "m_menu.h"
#include "i_system.h"

#include "p_setup.h"
#include "p_saveg.h"
#include "p_tick.h"

#include "d_main.h"

#include "wi_stuff.h"
#include "hu_stuff.h"
#include "st_stuff.h"
#include "am_map.h"

// Needs access to LFB.
#include "v_video.h"

#include "w_wad.h"

#include "p_local.h" 

#include "s_sound.h"

// Data.
#include "dstrings.h"
#include "sounds.h"

// SKY handling - still the wrong place.
#include "r_data.h"



#include "g_game.h"


#define SAVEGAMESIZE    0x2c000
#define SAVESTRINGSIZE  24
// lets keep this comfortably 16 bit. otherwise how do we fit in ems without big rewrite?
#define DEMO_MAX_SIZE 0xF800


boolean G_CheckDemoStatus (void); 
void    G_ReadDemoTiccmd (ticcmd_t* cmd); 
void    G_WriteDemoTiccmd (ticcmd_t* cmd); 
void    G_PlayerReborn (); 
void    G_InitNew (skill_t skill, int8_t episode, int8_t map);
 
  
void    G_DoLoadLevel (void); 
void    G_DoNewGame (void); 
void    G_DoLoadGame (void); 
void    G_DoPlayDemo (void); 
void    G_DoCompleted (void); 
void    G_DoWorldDone (void); 
void    G_DoSaveGame (void); 
 
 
gameaction_t    gameaction; 
gamestate_t     gamestate; 
skill_t         gameskill; 
boolean         respawnmonsters;
int8_t             gameepisode; 
int8_t             gamemap;
 
boolean         paused; 
boolean         sendpause;              // send a pause event next tic 
boolean         sendsave;               // send a save event next tic 
boolean         usergame;               // ok to save / end game 
 
boolean         timingdemo;             // if true, exit with report on completion 
boolean         nodrawers;              // for comparative timing purposes 
boolean         noblit;                 // for comparative timing purposes 
ticcount_t             starttime;              // for comparative timing purposes       
 
boolean         viewactive; 
 
player_t        player;
MEMREF			playermoRef;
 
ticcount_t          gametic;
int16_t             totalkills, totalitems, totalsecret;    // for intermission 
 
int8_t            demoname[32];
boolean         demorecording; 
boolean         demoplayback; 
boolean         netdemo; 
MEMREF           demobufferRef;

uint16_t           demo_p;				// buffer
//byte*           demoend; 
boolean         singledemo;             // quit after playing a demo from cmdline 
 
boolean         precache = true;        // if true, load all graphics at start 
 
wbstartstruct_t wminfo;                 // parms for world map / intermission 
 
MEMREF           savebufferRef;
 
 
// 
// controls (have defaults) 
// 
uint8_t             key_right;
uint8_t             key_left;

uint8_t             key_up;
uint8_t             key_down;
uint8_t             key_strafeleft;
uint8_t             key_straferight;
uint8_t             key_fire;
uint8_t             key_use;
uint8_t             key_strafe;
uint8_t             key_speed;
 
uint8_t             mousebfire;
uint8_t             mousebstrafe;
uint8_t             mousebforward;
 
 
 
#define MAXPLMOVE               (forwardmove[1]) 
 
#define TURBOTHRESHOLD  0x32

fixed_t         forwardmove[2] = {0x19, 0x32}; 
fixed_t         sidemove[2] = {0x18, 0x28}; 
fixed_t         angleturn[3] = {640, 1280, 320};        // + slow turn 

#define SLOWTURNTICS    6 
 
#define NUMKEYS         256 

boolean			gamekeydown[NUMKEYS];
int8_t             turnheld;                               // for accelerative turning 
 
boolean         mousearray[4]; 
// note: i think the -1 array thing  might be causing 16 bit binary to act up - not 100% sure - sq
boolean*        mousebuttons = &mousearray[1];          // allow [-1]

// mouse values are used once 
int32_t             mousex;
int32_t             mousey;

int32_t             dclicktime;
int32_t             dclickstate;
int32_t             dclicks;
int32_t             dclicktime2;
int32_t             dclickstate2;
int32_t             dclicks2;

 
int8_t             savegameslot;
int8_t            savedescription[32];
 
 
#define BODYQUESIZE     32

MEMREF          bodyque[BODYQUESIZE]; 
int8_t             bodyqueslot;
ticcmd_t localcmds[BACKUPTICS];


//
// G_BuildTiccmd
// Builds a ticcmd from all of the available inputs
// or reads it from the demo buffer. 
// If recording a demo, write it out 
// 
//ticcmd_t emptycmd;
void G_BuildTiccmd (int8_t index)
{ 
	int8_t         i;
	int8_t     strafe;
    boolean     bstrafe; 
	int8_t         speed;
	int8_t         tspeed;
	fixed_t         forward;
	fixed_t         side;
    
    //ticcmd_t*   base;
	ticcmd_t* cmd = &localcmds[index];

	//base = &emptycmd;
	//memcpy(cmd, base, sizeof(*cmd));


	// 2e276460 (2c7e:6460) gamekeydown
	// 75414af2 (7398:36a0) mousebuttons
	// 75414af0 (7398:4af0) mousearray
	// 1aa25a0  (0000:25a0) G_BuildTiccmd



	memset(cmd, 0, sizeof(ticcmd_t));

	strafe = gamekeydown[key_strafe] || mousebuttons[mousebstrafe]  ;
	speed = gamekeydown[key_speed] ;
    forward = side = 0;

    // use two stage accelerative turning
    // on the keyboard 
    if (
         gamekeydown[key_right]
        || gamekeydown[key_left]) 
        turnheld += 1; 
    else 
        turnheld = 0; 

    if (turnheld < SLOWTURNTICS) 
        tspeed = 2;             // slow turn 
    else 
        tspeed = speed;

    // let movement keys cancel each other out
    if (strafe) 
    { 
        if (gamekeydown[key_right]) 
        {
            // fprintf(stderr, "strafe right\n");
            side += sidemove[speed]; 
        }
        if (gamekeydown[key_left]) 
        {
            //  fprintf(stderr, "strafe left\n");
            side -= sidemove[speed]; 
        }
 
    } 
    else 
    { 
        if (gamekeydown[key_right]) 
            cmd->angleturn -= angleturn[tspeed]; 
        if (gamekeydown[key_left]) 
            cmd->angleturn += angleturn[tspeed]; 
    } 

    if (gamekeydown[key_up]) 
    {
        // fprintf(stderr, "up\n");
        forward += forwardmove[speed]; 
    }
    if (gamekeydown[key_down]) 
    {
        // fprintf(stderr, "down\n");
        forward -= forwardmove[speed]; 
    }
    if (gamekeydown[key_straferight]) 
        side += sidemove[speed]; 
    if (gamekeydown[key_strafeleft]) 
        side -= sidemove[speed];
 
    // buttons
    
    if (gamekeydown[key_fire] || mousebuttons[mousebfire]
        ) 
        cmd->buttons |= BT_ATTACK; 
 
    if (gamekeydown[key_use] ) 
    { 
        cmd->buttons |= BT_USE;
        // clear double clicks if hit use button 
        dclicks = 0;                   
    } 

    // chainsaw overrides 
    for (i=0 ; i<NUMWEAPONS-1 ; i++)        
        if (gamekeydown['1'+i]) 
        { 
            cmd->buttons |= BT_CHANGE; 
            cmd->buttons |= i<<BT_WEAPONSHIFT; 
            break; 
        }
    
    // mouse
    if (mousebuttons[mousebforward])
        forward += forwardmove[speed];
    
    // forward double click
    if (mousebuttons[mousebforward] != dclickstate && dclicktime > 1 )
    { 
        dclickstate = mousebuttons[mousebforward];
        if (dclickstate) 
            dclicks++; 
        if (dclicks == 2) 
        { 
            cmd->buttons |= BT_USE; 
            dclicks = 0; 
        } 
        else 
            dclicktime = 0; 
    } 
    else 
    { 
        dclicktime += 1; 
        if (dclicktime > 20) 
        { 
            dclicks = 0; 
            dclickstate = 0; 
        } 
    }
    
    // strafe double click
    bstrafe =
		mousebuttons[mousebstrafe]  ;
    if (bstrafe != dclickstate2 && dclicktime2 > 1 ) 
    { 
        dclickstate2 = bstrafe; 
        if (dclickstate2) 
            dclicks2++; 
        if (dclicks2 == 2) 
        { 
            cmd->buttons |= BT_USE; 
            dclicks2 = 0; 
        } 
        else 
            dclicktime2 = 0; 
    } 
    else 
    { 
        dclicktime2 += 1; 
        if (dclicktime2 > 20) 
        { 
            dclicks2 = 0; 
            dclickstate2 = 0; 
        } 
    } 
 
    forward += mousey; 
    if (strafe) 
        side += mousex*2; 
    else 
        cmd->angleturn -= mousex*0x8; 

    mousex = mousey = 0; 
         
    if (forward > MAXPLMOVE) 
        forward = MAXPLMOVE; 
    else if (forward < -MAXPLMOVE) 
        forward = -MAXPLMOVE; 
    if (side > MAXPLMOVE) 
        side = MAXPLMOVE; 
    else if (side < -MAXPLMOVE) 
        side = -MAXPLMOVE; 
 
    cmd->forwardmove += forward; 
    cmd->sidemove += side;
    
    // special buttons
    if (sendpause) 
    { 
        sendpause = false; 
        cmd->buttons = BT_SPECIAL | BTS_PAUSE; 
    } 
 
    if (sendsave) 
    { 
        sendsave = false; 
        cmd->buttons = BT_SPECIAL | BTS_SAVEGAME | (savegameslot<<BTS_SAVESHIFT); 
    } 
} 
 

//
// G_DoLoadLevel 
//
extern  gamestate_t     wipegamestate; 
extern uint8_t		skytexture;

void G_DoLoadLevel (void) 
{ 
#if (EXE_GAME_VERSION >= EXE_VERSION_FINAL2)
    // DOOM determines the sky texture to be used
    // depending on the current episode, and the game version.
    if ( commercial )
    {
        skytexture = R_TextureNumForName ("SKY3");
        if (gamemap < 12)
            skytexture = R_TextureNumForName ("SKY1");
        else
            if (gamemap < 21)
                skytexture = R_TextureNumForName ("SKY2");
    }
#endif


    if (wipegamestate == GS_LEVEL) 
        wipegamestate = -1;             // force a wipe 

    gamestate = GS_LEVEL; 


	if (player.playerstate == PST_DEAD)
		player.playerstate = PST_REBORN;

	TEXT_MODE_DEBUG_PRINT("\ncalling P_SetupLevel");
	P_SetupLevel (gameepisode, gamemap, gameskill);
	starttime = ticcount;
    gameaction = ga_nothing; 
    //Z_CheckHeap ();

    // clear cmd building stuff
    memset (gamekeydown, 0, sizeof(gamekeydown)); 
    mousex = mousey = 0; 
    sendpause = sendsave = paused = false; 
    memset (mousebuttons, 0, sizeof(mousebuttons));


} 
 
 
//
// G_Responder  
// Get info needed to make ticcmd_ts for the players.
// 
boolean G_Responder (event_t* ev) 
{   // any other key pops up menu if in demos
	if (gameaction == ga_nothing && !singledemo &&
		(demoplayback || gamestate == GS_DEMOSCREEN))
	{
		if (ev->type == ev_keydown ||
			(ev->type == ev_mouse && ev->data1)
			)
		{
			M_StartControlPanel();
			return true;
		}
		return false;
	}

	if (gamestate == GS_LEVEL)
	{
		if (HU_Responder(ev))
			return true; // chat ate the event
		if (ST_Responder(ev))
			return true; // status window ate it
		if (AM_Responder(ev))
			return true; // automap ate it
	}

	if (gamestate == GS_FINALE)
	{
		if (F_Responder(ev))
			return true; // finale ate the event
	}

	switch (ev->type)
	{
	case ev_keydown:
		if (ev->data1 == KEY_PAUSE)
		{
			sendpause = true;
			return true;
		}
		if (ev->data1 < NUMKEYS)
			gamekeydown[ev->data1] = true;
		return true; // eat key down events

	case ev_keyup:
		if (ev->data1 < NUMKEYS)
			gamekeydown[ev->data1] = false;
		return false; // always let key up events filter down

	case ev_mouse:
		mousearray[0] = ev->data1 & 1;
		mousearray[1] = ev->data1 & 2;
		mousearray[2] = ev->data1 & 4;
		mousex = ev->data2 * (mouseSensitivity + 5) / 10;
		mousey = ev->data3 * (mouseSensitivity + 5) / 10;
		return true; // eat events

 

	default:
		break;
	}

	return false;
} 
 
 
 
//
// G_Ticker
// Make ticcmd_ts for the players.
//
void G_Ticker (void) 
{ 
	int8_t         buf;
    ticcmd_t*   cmd;
    // do player reborns if needed
 
    // do things to change the game state
    while (gameaction != ga_nothing) 
    { 
		TEXT_MODE_DEBUG_PRINT("\n carrying out gameaction %i", gameaction);
        switch (gameaction) 
        { 
          case ga_loadlevel: 
            G_DoLoadLevel (); 
            break; 
          case ga_newgame: 
            G_DoNewGame (); 
            break; 
          case ga_loadgame: 
            G_DoLoadGame (); 
            break; 
          case ga_savegame: 
            G_DoSaveGame (); 
            break; 
          case ga_playdemo: 
            G_DoPlayDemo (); 
			break;
          case ga_completed: 
            G_DoCompleted (); 
            break; 
          case ga_victory: 
            F_StartFinale (); 
            break; 
          case ga_worlddone: 
            G_DoWorldDone (); 
            break; 
          

          case ga_nothing: 
            break; 
        } 
    }

	// get commands, check consistancy,
	 // and build new consistancy check
	buf = (gametic) % BACKUPTICS;

	cmd = &player.cmd;

	memcpy(cmd, &localcmds[buf], sizeof(ticcmd_t));

	if (demoplayback) {
		G_ReadDemoTiccmd(cmd);
		TEXT_MODE_DEBUG_PRINT("\ndemo command demo_p %i ANG %i BUTN %x FWD %i SIDE %i ", demo_p, cmd->angleturn, cmd->buttons, cmd->forwardmove, cmd->sidemove);
		 

	}
	if (demorecording) {
		G_WriteDemoTiccmd(cmd);
	}

    // check for special buttons
	if (player.cmd.buttons & BT_SPECIAL)
	{
		switch (player.cmd.buttons & BT_SPECIALMASK)
		{
		case BTS_PAUSE:
			paused ^= 1;
			if (paused)
				S_PauseSound();
			else
				S_ResumeSound();
			break;

		case BTS_SAVEGAME:
//			if (!savedescription[0])
//				strcpy(savedescription, "NET GAME");
			savegameslot =
				(player.cmd.buttons & BTS_SAVEMASK) >> BTS_SAVESHIFT;
			gameaction = ga_savegame;
			break;
		}
	}

	TEXT_MODE_DEBUG_PRINT("\n checking gamestate %i", gamestate);

    // do main actions
    switch (gamestate) 
    { 
	case GS_LEVEL:

		TEXT_MODE_DEBUG_PRINT("\n GS_LEVEL");
		P_Ticker();
		TEXT_MODE_DEBUG_PRINT("\n  GS_LEVEL: P_Ticker done");
		ST_Ticker();
		TEXT_MODE_DEBUG_PRINT("\n  GS_LEVEL: ST_Ticker done");
		AM_Ticker ();
		TEXT_MODE_DEBUG_PRINT("\n  GS_LEVEL: AM_Ticker done");
		HU_Ticker ();
		TEXT_MODE_DEBUG_PRINT("\n  GS_LEVEL: HU_Ticker done");
		break;
         
      case GS_INTERMISSION: 
        WI_Ticker (); 
		TEXT_MODE_DEBUG_PRINT("\n GS_INTERMISSION: WI_Ticker done");
		break;
                         
      case GS_FINALE: 
        F_Ticker (); 
		TEXT_MODE_DEBUG_PRINT("\n GS_FINALE: F_Ticker done");
		break;
 
      case GS_DEMOSCREEN: 
        D_PageTicker (); 
		TEXT_MODE_DEBUG_PRINT("\n GS_DEMOSCREEN: D_PageTicker done");
		break;
    }        

} 
 
 
 

//
// G_PlayerFinishLevel
// Can when a player completes a level.
//
void G_PlayerFinishLevel () 
{ 
	mobj_t* playerMo = Z_LoadBytesFromEMS(playermoRef);

          
    memset (player.powers, 0, sizeof (player.powers));
    memset (player.cards, 0, sizeof (player.cards));
    playerMo->flags &= ~MF_SHADOW;         // cancel invisibility 
	player.extralight = 0;                  // cancel gun flashes 
	player.fixedcolormap = 0;               // cancel ir gogles 
	player.damagecount = 0;                 // no palette changes 
	player.bonuscount = 0;
} 
 

//
// G_PlayerReborn
// Called after a player dies 
// almost everything is cleared and initialized 
//
void G_PlayerReborn () 
{ 
 	int8_t         i;
	int16_t         killcount;
	int16_t         itemcount;
	int16_t         secretcount;
         
    killcount = player.killcount; 
    itemcount = player.itemcount; 
    secretcount = player.secretcount; 
         
    memset (&player, 0, sizeof(player));
 
    player.killcount = killcount; 
    player.itemcount = itemcount; 
    player.secretcount = secretcount; 
 
	player.usedown = player.attackdown = true;  // don't do anything immediately 
	player.playerstate = PST_LIVE;
	player.health = MAXHEALTH;
	player.readyweapon = player.pendingweapon = wp_pistol;
	player.weaponowned[wp_fist] = true;
	player.weaponowned[wp_pistol] = true;
	player.ammo[am_clip] = 50;
         
    for (i=0 ; i<NUMAMMO ; i++) 
		player.maxammo[i] = maxammo[i];
                 
}

//
// G_CheckSpot  
// Returns false if the player cannot be respawned
// at the given mapthing_t spot  
// because something is occupying it 
//
void P_SpawnPlayer (mapthing_t* mthing); 
 
boolean
G_CheckSpot
(int16_t           playernum,
  mapthing_t*   mthing ) 
{ 
	angle_t            an;
	mobj_t*				playerMo;
	MEMREF				moRef;
	subsector_t* subsectors;
	int16_t subsecnum;
	int16_t secnum;
	sector_t* sectors;
    fixed_t_union tempx;
    fixed_t_union tempy;
    fixed_t_union tempz;
        
    tempx.h.fracbits = 0;
    tempy.h.fracbits = 0;
    tempx.h.intbits = mthing->x; 
    tempy.h.intbits = mthing->y; 

    if (!playermoRef)
    {
        // first spawn of level, before corpses
		playerMo = (mobj_t*)Z_LoadBytesFromEMS(playermoRef);
		if (playerMo->x == tempx.w && playerMo->y == tempy.w)
			return false;
        return true;
    }
         
    if (!P_CheckPosition (playermoRef, tempx.w, tempy.w) ) 
        return false; 
 
    // flush an old corpse if needed 
    if (bodyqueslot >= BODYQUESIZE) 
        P_RemoveMobj (bodyque[bodyqueslot%BODYQUESIZE]); 
    bodyque[bodyqueslot%BODYQUESIZE] = playermoRef; 
    bodyqueslot++; 
        
    // spawn a teleport fog 
    subsecnum = R_PointInSubsector (tempx.w,tempy.w); 
	subsectors = (subsector_t*) Z_LoadBytesFromEMS(subsectorsRef);

	secnum = subsectors[subsecnum].secnum;
	sectors = (sector_t*)Z_LoadBytesFromConventional(sectorsRef);

    an = ( ANG45 * (mthing->angle/45) ) >> ANGLETOFINESHIFT; 
    tempz.h.fracbits = 0;
    // tempz.h.intbits = sectors[secnum].floorheight >> SHORTFLOORBITS;
    SET_FIXED_UNION_FROM_SHORT_HEIGHT(tempz, sectors[secnum].floorheight);
    moRef = P_SpawnMobj (tempx.w+20*finecosine(an), tempy.w+20*finesine(an)
                      , tempz.w
                      , MT_TFOG); 
         
	if (player.viewz != 1) {
		S_StartSoundFromRef(moRef, sfx_telept);  // don't start sound on first frame 
	}
    return true; 
} 

 
 
 

//todo make int_8 and divide by 5

// DOOM Par Times
int16_t pars[4][10] = 
{ 
    {0}, 
    {0,30,75,120,90,165,180,180,30,165}, 
    {0,90,90,90,120,90,360,240,30,170}, 
    {0,90,45,90,150,90,90,165,30,135} 
}; 

// DOOM II Par Times
int16_t cpars[32] =
{
    30,90,120,120,90,150,120,120,270,90,        //  1-10
    210,150,150,150,210,150,420,150,210,150,    // 11-20
    240,150,180,150,150,300,330,420,300,180,    // 21-30
    120,30                                      // 31-32
};
 

//
// G_DoCompleted 
//
boolean         secretexit; 
extern int8_t*    pagename; 
 
void G_ExitLevel (void) 
{ 
    secretexit = false; 
    gameaction = ga_completed; 
} 

// Here's for the german edition.
void G_SecretExitLevel (void) 
{ 
    // IF NO WOLF3D LEVELS, NO SECRET EXIT!
    if ( (commercial)
      && (W_CheckNumForName("map31")<0))
        secretexit = false;
    else
        secretexit = true; 
    gameaction = ga_completed; 
} 
 
void G_DoCompleted (void) 
{ 
         
    gameaction = ga_nothing; 
 
	G_PlayerFinishLevel(0); // take away cards and stuff

    if (automapactive) 
        AM_Stop (); 
        
    if (!commercial)
        switch(gamemap)
        {
          case 8:
            gameaction = ga_victory;
            return;
          case 9: 
            player.didsecret = true; 
            break;
        }
                
 
    
         
    wminfo.didsecret = player.didsecret; 
    wminfo.epsd = gameepisode -1; 
    wminfo.last = gamemap -1;
    
    // wminfo.next is 0 biased, unlike gamemap
    if (commercial)
    {
        if (secretexit)
            switch(gamemap)
            {
              case 15: wminfo.next = 30; break;
              case 31: wminfo.next = 31; break;
            }
        else
            switch(gamemap)
            {
              case 31:
              case 32: wminfo.next = 15; break;
              default: wminfo.next = gamemap;
            }
    }
    else
    {
        if (secretexit) 
            wminfo.next = 8;    // go to secret level 
        else if (gamemap == 9) 
        {
            // returning from secret level 
            switch (gameepisode) 
            { 
              case 1: 
                wminfo.next = 3; 
                break; 
              case 2: 
                wminfo.next = 5; 
                break; 
              case 3: 
                wminfo.next = 6; 
                break; 
              case 4:
                wminfo.next = 2;
                break;
            }                
        } 
        else 
            wminfo.next = gamemap;          // go to next level 
    }
                 
    wminfo.maxkills = totalkills; 
    wminfo.maxitems = totalitems; 
    wminfo.maxsecret = totalsecret; 

	if ( commercial )
        wminfo.partime = 35*cpars[gamemap-1]; 
    else
        wminfo.partime = 35*pars[gameepisode][gamemap]; 
    wminfo.pnum = 0; 
 
	wminfo.plyr.in = true;
    wminfo.plyr.skills = player.killcount; 
    wminfo.plyr.sitems = player.itemcount; 
    wminfo.plyr.ssecret = player.secretcount; 
    wminfo.plyr.stime = (leveltime.w / TICRATE); 
 
    gamestate = GS_INTERMISSION; 
    viewactive = false; 
    automapactive = false; 
 
        
    WI_Start (&wminfo); 
} 


//
// G_WorldDone 
//
void G_WorldDone (void) 
{ 
    gameaction = ga_worlddone; 

    if (secretexit) 
        player.didsecret = true; 

    if ( commercial )
    {
        switch (gamemap)
        {
          case 15:
          case 31:
            if (!secretexit)
                break;
          case 6:
          case 11:
          case 20:
          case 30:
            F_StartFinale ();
            break;
        }
    }
} 
 
void G_DoWorldDone (void) 
{        
    gamestate = GS_LEVEL; 
    gamemap = wminfo.next+1; 
    G_DoLoadLevel (); 
	gameaction = ga_nothing;
    viewactive = true; 
} 
 


//
// G_InitFromSavegame
// Can be called by the startup code or the menu task. 
//
extern boolean setsizeneeded;
void R_ExecuteSetViewSize (void);

//int8_t    savename[256];

void G_LoadGame (int8_t* name) 
{ 
    //strcpy (savename, name); 
    //gameaction = ga_loadgame; 
} 
 
#define VERSIONSIZE             16 


void G_DoLoadGame (void) 
{ 
	/*
	filelength_t         length;
	byte         a,b,c;
	int8_t        vcheck[VERSIONSIZE];
	byte*           savebuffer;
    gameaction = ga_nothing; 
    
    length = M_ReadFile (savename, &savebufferRef); 
	savebuffer = Z_LoadBytesFromEMS(savebufferRef);
    save_p = savebuffer + SAVESTRINGSIZE;
    
    // skip the description field 
    memset (vcheck,0,sizeof(vcheck)); 
    sprintf (vcheck,"version %i",VERSION); 
    if (strcmp ((int8_t*)save_p, vcheck)) 
        return;                         // bad version 
    save_p += VERSIONSIZE; 
                         
    gameskill = *save_p++; 
    gameepisode = *save_p++; 
    gamemap = *save_p++; 
    *save_p++;  // playeringam,e
	*save_p++; *save_p++; *save_p++;

    // load a base level 
    G_InitNew (gameskill, gameepisode, gamemap); 
 
    // get the times 
    a = *save_p++; 
    b = *save_p++; 
    c = *save_p++; 
	leveltime.b.intbytelow = a;
	leveltime.b.fracbytehigh = b;
	leveltime.b.fracbytelow = c;
         
    // dearchive all the modifications
    P_UnArchivePlayers (); 
    P_UnArchiveWorld (); 
    P_UnArchiveThinkers (); 
    P_UnArchiveSpecials (); 
#ifdef CHECK_FOR_ERRORS

    if (*save_p != 0x1d) 
        I_Error ("Bad savegame");
#endif
   
    Z_FreeEMSNew (savebufferRef); 
 
    if (setsizeneeded)
        R_ExecuteSetViewSize ();
    
    // draw the pattern into the back screen
	R_FillBackScreen ();   

	*/
} 
 

//
// G_SaveGame
// Called by the menu task.
// Description is a 24 byte text string 
//
void
G_SaveGame
(int8_t   slot,
  int8_t* description ) 
{ 
    savegameslot = slot; 
    strcpy (savedescription, description); 
    sendsave = true; 
} 
 
void G_DoSaveGame (void) 
{ 
	/*
	int8_t        name[100];
	int8_t        name2[VERSIONSIZE];
    int8_t*       description; 
	filelength_t         length;
	byte*       savebuffer;

    if (M_CheckParm("-cdrom"))
        sprintf(name,"c:\\doomdata\\"SAVEGAMENAME"%d.dsg",savegameslot);
    else
        sprintf (name,SAVEGAMENAME"%d.dsg",savegameslot); 
    description = savedescription; 

	savebuffer = (byte*)Z_LoadBytesFromEMS(savebufferRef);
    save_p = savebuffer = screen0+0x4000; 
         
    memcpy (save_p, description, SAVESTRINGSIZE); 
    save_p += SAVESTRINGSIZE; 
    memset (name2,0,sizeof(name2)); 
    sprintf (name2,"version %i",VERSION); 
    memcpy (save_p, name2, VERSIONSIZE); 
    save_p += VERSIONSIZE; 
         
	*save_p++ = gameskill;
	*save_p++ = gameepisode;
	*save_p++ = gamemap;
	*save_p++ = true;
	*save_p++ = false;
	*save_p++ = false;
	*save_p++ = false;
	*save_p++ = leveltime.b.intbytelow;
	*save_p++ = leveltime.b.fracbytehigh;
	*save_p++ = leveltime.b.fracbytelow;
 
    P_ArchivePlayers (); 
    P_ArchiveWorld (); 
    P_ArchiveThinkers (); 
    P_ArchiveSpecials (); 
         
    *save_p++ = 0x1d;           // consistancy marker 
         
    length = save_p - savebuffer; 
#ifdef CHECK_FOR_ERRORS
	if (length > SAVEGAMESIZE)
        I_Error ("Savegame buffer overrun"); 
#endif
    M_WriteFile (name, savebuffer, length); 
    gameaction = ga_nothing; 
    savedescription[0] = 0;              
         
    players.message = GGSAVED; 

    // draw the pattern into the back screen
    R_FillBackScreen ();        
	*/
} 
 

//
// G_InitNew
// Can be called by the startup code or the menu task,
// consoleplayer, displayplayer, playeringame[] should be set. 
//
skill_t d_skill; 
int8_t     d_episode;
int8_t     d_map;
 
void
G_DeferedInitNew
( skill_t       skill,
	int8_t           episode,
	int8_t           map)
{ 
    d_skill = skill; 
    d_episode = episode; 
    d_map = map; 
    gameaction = ga_newgame; 
} 


void G_DoNewGame (void) 
{
    demoplayback = false; 
    netdemo = false;
    //playeringame[1] = playeringame[2] = playeringame[3] = 0;
    respawnparm = false;
    fastparm = false;
    nomonsters = false;
    G_InitNew (d_skill, d_episode, d_map); 
    gameaction = ga_nothing; 
} 

// The sky texture to be used instead of the F_SKY1 dummy.
extern  uint8_t     skytexture;


void
G_InitNew
( skill_t       skill,
	int8_t           episode,
	int8_t           map )
{ 
	int16_t             i;
         
    if (paused) 
    { 
        paused = false; 
        S_ResumeSound (); 
    } 
        

    if (skill > sk_nightmare) 
        skill = sk_nightmare;

#if (EXE_VERSION < EXE_VERSION_ULTIMATE)
    if (episode < 1)
    {
        episode = 1;
    }
    if (episode > 3)
    {
        episode = 3;
    }
#else
    if (episode == 0)
    {
        episode = 4;
    }
#endif

    if (episode > 1 && shareware)
    {
        episode = 1;
    }

    if (map < 1) 
        map = 1;
    
    if ( (map > 9)
         && (!commercial) )
      map = 9; 
                 
    M_ClearRandom (); 
         
    if (skill == sk_nightmare || respawnparm )
        respawnmonsters = true;
    else
        respawnmonsters = false;
                
    if (fastparm || (skill == sk_nightmare && gameskill != sk_nightmare) )
    { 
        for (i=S_SARG_RUN1 ; i<=S_SARG_PAIN2 ; i++) 
            states[i].tics >>= 1; 
        mobjinfo[MT_BRUISERSHOT].speed = 20+HIGHBIT; 
        mobjinfo[MT_HEADSHOT].speed = 20+HIGHBIT; 
        mobjinfo[MT_TROOPSHOT].speed = 20+HIGHBIT; 
    } 
    else if (skill != sk_nightmare && gameskill == sk_nightmare) 
    { 
        for (i=S_SARG_RUN1 ; i<=S_SARG_PAIN2 ; i++) 
            states[i].tics <<= 1; 
        mobjinfo[MT_BRUISERSHOT].speed = 15+HIGHBIT; 
        mobjinfo[MT_HEADSHOT].speed = 10+HIGHBIT; 
        mobjinfo[MT_TROOPSHOT].speed = 10+HIGHBIT; 
    } 
         
                         
    // force players to be initialized upon first level load         
    player.playerstate = PST_REBORN; 
 
    usergame = true;                // will be set false if a demo 
    paused = false; 
    demoplayback = false; 
    automapactive = false; 
    viewactive = true; 
    gameepisode = episode; 
    gamemap = map; 
    gameskill = skill; 
 
    viewactive = true;

	
    // set the sky map for the episode
    if (commercial)
    {
        skytexture = R_TextureNumForName ("SKY3");
        if (gamemap < 12)
            skytexture = R_TextureNumForName ("SKY1");
        else
            if (gamemap < 21)
                skytexture = R_TextureNumForName ("SKY2");
    }
    else
        switch (episode) 
        { 
          case 1: 
            skytexture = R_TextureNumForName ("SKY1"); 
            break; 
          case 2: 
            skytexture = R_TextureNumForName ("SKY2"); 
            break; 
          case 3: 
            skytexture = R_TextureNumForName ("SKY3"); 
            break; 
          case 4:       // Special Edition sky
            skytexture = R_TextureNumForName ("SKY4");
            break;
        } 


	TEXT_MODE_DEBUG_PRINT("\nloading level");
	G_DoLoadLevel ();
} 
 

//
// DEMO RECORDING 
// 
#define DEMOMARKER              0x80


void G_ReadDemoTiccmd (ticcmd_t* cmd) 
{ 
    // this is just used as an offset so lets just store as int;
	int32_t demobuffer = (int32_t) Z_LoadBytesFromEMS(demobufferRef);
	byte* demo_addr = (byte*)(demo_p + demobuffer);
	
	if (*demo_addr == DEMOMARKER)  {
        // end of demo data stream 
        G_CheckDemoStatus (); 
        return; 
    } 


	cmd->forwardmove = ((int8_t)*demo_addr++);
    cmd->sidemove = ((int8_t)*demo_addr++);
    cmd->angleturn = ((uint8_t)*demo_addr++)<<8;
    cmd->buttons = (uint8_t)*demo_addr++;
	demo_p = (uint16_t)(demo_addr - demobuffer);
}


void G_WriteDemoTiccmd (ticcmd_t* cmd) 
{ 
	int32_t demobuffer = (int32_t) Z_LoadBytesFromEMS(demobufferRef);
	byte* demo_addr = (byte*)(demo_p + demobuffer);
 	if (gamekeydown['q'])           // press q to end demo recording 
        G_CheckDemoStatus (); 

	

	*demo_addr++ = cmd->forwardmove;
    *demo_addr++ = cmd->sidemove;
    *demo_addr++ = (cmd->angleturn+128)>>8;
    *demo_addr++ = cmd->buttons;
	demo_addr -= 4;
	
    if (demo_p > (DEMO_MAX_SIZE - 16))
    {
        // no more space 
        G_CheckDemoStatus (); 
        return; 
    } 
        
    G_ReadDemoTiccmd (cmd);         // make SURE it is exactly the same 
	demo_p = (uint16_t)(demo_addr - demobuffer);

} 
 
 
 
//
// G_RecordDemo 
// 
void G_RecordDemo (int8_t* name) 
{ 
	int32_t                         maxsize;
    int16_t i;    
    usergame = false; 
    strcpy (demoname, name); 
    strcat (demoname, ".lmp"); 
    maxsize = DEMO_MAX_SIZE;
    i = M_CheckParm ("-maxdemo");
    if (i && i<myargc-1) 
            maxsize = atoi(myargv[i+1])*1024;
    demobufferRef = Z_MallocEMSNew (maxsize,PU_STATIC,0, ALLOC_TYPE_DEMO_BUFFER); 
    //demoend = demobuffer + maxsize;
        
    demorecording = true; 
} 
 
 
void G_BeginRecording (void) 
{ 
	byte* demobuffer = Z_LoadBytesFromEMS(demobufferRef);
	byte* demo_addr = (byte*)(demobuffer);

    demo_p = 0;
        
    *demo_addr++ = VERSION;
    *demo_addr++ = gameskill;
    *demo_addr++ = gameepisode;
    *demo_addr++ = gamemap;
    *demo_addr++ = false;
    *demo_addr++ = respawnparm;
    *demo_addr++ = fastparm;
    *demo_addr++ = nomonsters;
    *demo_addr++ = 0;

	*demo_addr++ = true;
	*demo_addr++ = false;
	*demo_addr++ = false;
	*demo_addr++ = false;
	
	demo_p = (demo_addr - demobuffer);

} 
 

//
// G_PlayDemo 
//

int8_t*   defdemoname; 
 
void G_DeferedPlayDemo (int8_t* name) 
{ 
    defdemoname = name; 
    gameaction = ga_playdemo; 
} 
 
void G_DoPlayDemo (void) 
{ 
    skill_t skill; 
	int8_t             episode, map;
	byte* demobuffer;
	byte* demo_addr;

	gameaction = ga_nothing;
    demobufferRef = W_CacheLumpNameEMS (defdemoname, PU_STATIC); 
	demobuffer = (byte*) Z_LoadBytesFromEMS(demobufferRef);
	demo_addr = (byte*)(demobuffer);
	demo_p = 0;


	if ( *demo_addr++ != VERSION)
    {
#ifdef CHECK_FOR_ERRORS
		I_Error("Demo is from a different game version!");
#endif
}

    skill = *demo_addr++;
    episode = *demo_addr++;
    map = *demo_addr++;
     *demo_addr++; // deathmatch
    respawnparm = *demo_addr++;
    fastparm = *demo_addr++;
    nomonsters = *demo_addr++;
    *demo_addr++; // consoleplayer

	*demo_addr++; // playeringame
	*demo_addr++;
	*demo_addr++;
	*demo_addr++;
	
    // don't spend a lot of time in loadlevel 
    precache = false;
	TEXT_MODE_DEBUG_PRINT("\ndemo loaded, initializing game/world");
	G_InitNew (skill, episode, map);
	precache = true;

    usergame = false; 
    demoplayback = true; 

	demo_p = (demo_addr - demobuffer);

} 

//
// G_TimeDemo 
//
void G_TimeDemo (int8_t* name) 
{        
    nodrawers = M_CheckParm ("-nodraw"); 
    noblit = M_CheckParm ("-noblit"); 
    timingdemo = true; 
    singletics = true; 

    defdemoname = name; 
    gameaction = ga_playdemo; 
} 
 
 
/* 
=================== 
= 
= G_CheckDemoStatus 
= 
= Called after a death or level completion to allow demos to be cleaned up 
= Returns true if a new demo loop action will take place 
=================== 
*/ 

#ifdef PROFILE_PAGE_COUNT
extern int32_t pagecount[40];
#endif

boolean G_CheckDemoStatus (void) 
{ 
	ticcount_t             endtime;
	byte* demobuffer;
	byte* demo_addr;
	// NOTE: WHENEVER WE ENTER THIS FUNCTION demo_p IS ALREADY INCREMENTED BY demobuffer OFFSET;

	if (timingdemo)
	{
		endtime = ticcount;
#ifdef PROFILE_PAGE_COUNT

		I_Error("\n%i %i %i %i %i\n%i %i %i %i %i\n%i %i %i %i %i\n%i %i %i %i %i\n%i %i %i %i %i\n%i %i %i %i %i\n%i %i %i %i %i\n%i %i %i %i %i",
			pagecount[0], pagecount[1], pagecount[2], pagecount[3], pagecount[4], pagecount[5], pagecount[6], pagecount[7], pagecount[8], pagecount[9],
			pagecount[10], pagecount[11], pagecount[12], pagecount[13], pagecount[14], pagecount[15], pagecount[16], pagecount[17], pagecount[18], pagecount[19],
			pagecount[20], pagecount[21], pagecount[22], pagecount[23], pagecount[24], pagecount[25], pagecount[26], pagecount[27], pagecount[28], pagecount[29],
			pagecount[30], pagecount[31], pagecount[32], pagecount[33], pagecount[34], pagecount[35], pagecount[36], pagecount[37], pagecount[38], pagecount[39]

		);
#else
        I_Error ("\ntimed %li gametics in %li realtics %li %li %li prnd %i",gametic 
                 , endtime-starttime, numreads, pageins, pageouts, prndindex); 
#endif
    } 
         
    if (demoplayback) 
    { 
        if (singledemo) 
            I_Quit (); 
                         
        Z_ChangeTagEMSNew (demobufferRef, PU_CACHE); 
        demoplayback = false; 
        netdemo = false;
        respawnparm = false;
        fastparm = false;
        nomonsters = false;
        D_AdvanceDemo (); 
        return true; 
    } 
 
    if (demorecording) 
    { 
		demobuffer = Z_LoadBytesFromEMS(demobufferRef);
		demo_addr = (byte*)(demo_p + demobuffer);

		*demo_addr++ = DEMOMARKER;
		demo_p++;
        M_WriteFile (demoname, demobuffer, demo_p);
        Z_FreeEMSNew (demobufferRef); 
        demorecording = false; 
        I_Error ("Demo %s recorded",demoname); 
    } 
         
    return false; 
} 
 
 
 

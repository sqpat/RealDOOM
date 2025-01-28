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

#include "m_memory.h"
#include "m_near.h"

#include <dos.h>

#include "g_game.h"




boolean __far G_CheckDemoStatus (void); 
void    __near G_ReadDemoTiccmd (ticcmd_t __near* cmd); 
void    __near G_WriteDemoTiccmd (ticcmd_t __near* cmd); 
void    __far G_PlayerReborn (); 
void    __far G_InitNew (skill_t skill, int8_t episode, int8_t map);
 
  
void   __near G_DoLoadLevel (void); 
void   __near G_DoNewGame (void); 
void   __near G_DoLoadGame (void); 
void   __near G_DoPlayDemo (void); 
void   __near G_DoCompleted (void); 
void   __near G_DoSaveGame (void); 

// Called by main loop.
boolean __far AM_Responder (event_t __far* ev);

 
#define MAXPLMOVE               (forwardmove[1]) 
 
#define TURBOTHRESHOLD  0x32


 




//
// R_FlatNumForName
// Retrieval, get a flat number for a flat name.
//
uint8_t __far R_FlatNumForName(int8_t* name) {
	int16_t         i;
#ifdef CHECK_FOR_ERRORS
	int8_t        namet[9];
#endif

	i = W_CheckNumForName(name);

#ifdef CHECK_FOR_ERRORS
	if (i == -1)
	{
		namet[8] = 0;
		memcpy(namet, name, 8);
		I_Error("\nR_FlatNumForName: %s not found", namet);
	}

	if (i - firstflat > 255) {
		I_Error("Flat too big %i %i", i, firstflat);
	}
#endif

	return (uint8_t)(i - firstflat);
}




//
// G_BuildTiccmd
// Builds a ticcmd from all of the available inputs
// or reads it from the demo buffer. 
// If recording a demo, write it out 
// 
/*
void __near G_BuildTiccmd (int8_t index) { 
	int8_t         i;
	int8_t     strafe;
    boolean     bstrafe; 
	int8_t         speed;
	int8_t         tspeed;
	int32_t         forward;
	int32_t         side;
    
	ticcmd_t __near* cmd = &localcmds[index];

	memset(cmd, 0, sizeof(ticcmd_t));

	strafe = gamekeydown[key_strafe] || mousebuttons[mousebstrafe]  ;
	speed = gamekeydown[key_speed] ;
    forward = side = 0;

    // use two stage accelerative turning
    // on the keyboard 
    if ( gamekeydown[key_right] || gamekeydown[key_left]) {
        turnheld += 1; 
    } else {
        turnheld = 0; 
    }

    if (turnheld < SLOWTURNTICS) {
        tspeed = 2;             // slow turn 
    } else {
        tspeed = speed;
    }

    // let movement keys cancel each other out
    if (strafe)  { 
        if (gamekeydown[key_right])  {
            side += sidemove[speed]; 
        }
        if (gamekeydown[key_left])  {
            side -= sidemove[speed]; 
        }
 
    } else { 
        if (gamekeydown[key_right]) {
            cmd->angleturn -= angleturn[tspeed]; 
        }
        if (gamekeydown[key_left]) {
            cmd->angleturn += angleturn[tspeed]; 
        }
    } 

    if (gamekeydown[key_up])  {
        forward += forwardmove[speed]; 
    }
    if (gamekeydown[key_down])  {
        forward -= forwardmove[speed]; 
    }
    if (gamekeydown[key_straferight]) {
        side += sidemove[speed]; 
    }
    if (gamekeydown[key_strafeleft]) {
        side -= sidemove[speed];
    }
 
    // buttons
    
    if (gamekeydown[key_fire] || mousebuttons[mousebfire]) {
        cmd->buttons |= BT_ATTACK; 
    }
 
    if (gamekeydown[key_use] ) { 
        cmd->buttons |= BT_USE;
        // clear double clicks if hit use button 
        dclicks = 0;                   
    } 

    // chainsaw overrides 
    for (i=0 ; i<NUMWEAPONS-1 ; i++)        
        if (gamekeydown['1'+i])  { 
            cmd->buttons |= BT_CHANGE; 
            cmd->buttons |= i<<BT_WEAPONSHIFT; 
            break; 
        }
    
    // mouse
    if (mousebuttons[mousebforward])
        forward += forwardmove[speed];
    

    
    // strafe double click
    bstrafe = mousebuttons[mousebstrafe]  ;
    if (bstrafe != dclickstate2 && dclicktime2 > 1 )  { 
        dclickstate2 = bstrafe; 
        if (dclickstate2) {
            dclicks2++; 
        }
        if (dclicks2 == 2) { 
            cmd->buttons |= BT_USE; 
            dclicks2 = 0; 
        } 
        else 
            dclicktime2 = 0; 
    } else { 
        dclicktime2 += 1; 
        if (dclicktime2 > 20) { 
            dclicks2 = 0; 
            dclickstate2 = 0; 
        } 
    } 
 
    if (strafe) {
        side += mousex*2;
    } else {
        cmd->angleturn -= mousex*0x8; 
    }
    mousex =  0; 
         
    if (forward > MAXPLMOVE) {
        forward = MAXPLMOVE; 
    } else if (forward < -MAXPLMOVE) {
        forward = -MAXPLMOVE; 
    }
    if (side > MAXPLMOVE) {
        side = MAXPLMOVE; 
    } else if (side < -MAXPLMOVE) {
        side = -MAXPLMOVE; 
    }
    cmd->forwardmove += forward; 
    cmd->sidemove += side;
    
    // special buttons
    if (sendpause) { 
        sendpause = false; 
        cmd->buttons = BT_SPECIAL | BTS_PAUSE; 
    } 
 
    if (sendsave) { 
        sendsave = false; 
        cmd->buttons = BT_SPECIAL | BTS_SAVEGAME | (savegameslot<<BTS_SAVESHIFT); 
    } 
} 
 

 */
 
void __near G_SetGameKeyDown(int8_t key);
void __near G_SetGameKeyUp(int8_t key);
boolean __near G_GetGameKey(int8_t keyr);

//
// G_Responder  
// Get info needed to make ticcmd_ts for the players.
// 
boolean __near G_Responder (event_t __far* ev)  {   // any other key pops up menu if in demos
	if (gameaction == ga_nothing && !singledemo &&
		(demoplayback || gamestate == GS_DEMOSCREEN)) {
		if (ev->type == ev_keydown || (ev->type == ev_mouse && ev->data1)) {
			M_StartControlPanel();
			return true;
		}
		return false;
	}

	if (gamestate == GS_LEVEL) {
		if (HU_Responder(ev)) {
			return true; // chat ate the event
		}
		if (ST_Responder(ev)) {
			return true; // status window ate it
		}
		if (AM_Responder(ev)) {
			return true; // automap ate it
		}
	}

	if (gamestate == GS_FINALE) {
        Z_SetOverlay(OVERLAY_ID_FINALE);
        if (F_Responder(ev)) {
			return true; // finale ate the event
		}
	}

	switch (ev->type) {
		case ev_keydown:
			//I_Error("keydown: %li %hhi", ev->data1, ev->type);
			if (ev->data1 == KEY_PAUSE) {
				sendpause = true;
				return true;
			}
			if (ev->data1 < NUMKEYS) {
                G_SetGameKeyDown(ev->data1);
            }
            

			return true; // eat key down events

		case ev_keyup:
			if (ev->data1 < NUMKEYS) {
                G_SetGameKeyUp(ev->data1);
            }
			return false; // always let key up events filter down

		case ev_mouse:
			mousebuttons[0] = ev->data1 & 1;
			mousebuttons[1] = ev->data1 & 2;
			mousebuttons[2] = ev->data1 & 4;
			mousex = FastDiv3216u(FastMul1616((mouseSensitivity + 5), ev->data2), 10);
			return true; // eat events

 

		default:
			break;
	}

	return false;
} 
 
void __near G_DoWorldDone(void) {
	gamestate = GS_LEVEL;
	gamemap = wminfo.next + 1;
	G_DoLoadLevel();
	gameaction = ga_nothing;
	viewactive = true;

}


void __near G_DoNewGame(void) {
	demoplayback = false;
	netdemo = false;
	//playeringame[1] = playeringame[2] = playeringame[3] = 0;
	respawnparm = false;
	fastparm = false;
	nomonsters = false;
	G_InitNew(d_skill, d_episode, d_map);
	gameaction = ga_nothing;
}


void __near G_CopyCmd(ticcmd_t __near * destcmd, int8_t srcindex);
 
// G_Ticker
// Make ticcmd_ts for the players.
//
void __near G_Ticker (void)  { 
	int8_t         buf;
    ticcmd_t __near*   cmd;
    // do player reborns if needed

    // do player reborn if needed
	if (player.playerstate == PST_REBORN) {
        gameaction = ga_loadlevel;  
    }


	// do things to change the game state
    while (gameaction != ga_nothing)  { 
		switch (gameaction) { 
		  case ga_loadlevel: 
            G_DoLoadLevel (); 
            break; 
          case ga_newgame: 
            G_DoNewGame (); 
            break; 
          case ga_loadgame: 
            Z_SetOverlay(OVERLAY_ID_SAVELOADGAME);
            G_DoLoadGame (); 
            break; 
          case ga_savegame: 
            Z_SetOverlay(OVERLAY_ID_SAVELOADGAME);
            G_DoSaveGame (); 
            break; 
          case ga_playdemo: 
            G_DoPlayDemo (); 
			break;
          case ga_completed: 
            G_DoCompleted (); 
            break; 
          case ga_victory: 
            Z_SetOverlay(OVERLAY_ID_FINALE);
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
    G_CopyCmd(cmd, buf);   // get rid of this once this func in asm
	

	if (demoplayback) {
		G_ReadDemoTiccmd(cmd);
	}
	if (demorecording) {
		G_WriteDemoTiccmd(cmd);
	}

    // check for special buttons
	if (player.cmd.buttons & BT_SPECIAL) {
		switch (player.cmd.buttons & BT_SPECIALMASK) {
			case BTS_PAUSE:
				paused ^= 1;
				if (paused) {
					S_PauseSound();
				} else {
					S_ResumeSound();
				}
				break;

			case BTS_SAVEGAME:
				savegameslot = (player.cmd.buttons & BTS_SAVEMASK) >> BTS_SAVESHIFT;
				gameaction = ga_savegame;
				break;
		}
	}


    // do main actions
    switch (gamestate)  { 
		case GS_LEVEL:

			P_Ticker();

			ST_Ticker();
			if (automapactive) {
				AM_Ticker();
			}
			HU_Ticker ();
			break;
         
        case GS_INTERMISSION: 
            Z_QuickMapIntermission();
            WI_Ticker ();
            Z_QuickMapPhysics();

            break;
                         
        case GS_FINALE: 
            Z_SetOverlay(OVERLAY_ID_FINALE);
			F_Ticker();
			break;
 
        case GS_DEMOSCREEN: 
			D_PageTicker (); 
			break;
    }        

} 
 
 
 

//
// G_PlayerFinishLevel
// Can when a player completes a level.
//
void __near G_PlayerFinishLevel ()  { 

          
    memset (player.powers, 0, sizeof (player.powers));
    memset (player.cards, 0, sizeof (player.cards));
    playerMobj_pos->flags2 &= ~MF_SHADOW;   // cancel invisibility 
	player.extralightvalue = 0;                  // cancel gun flashes 
	player.fixedcolormapvalue = 0;               // cancel ir gogles 
	player.damagecount = 0;                 // no palette changes 
	player.bonuscount = 0;
} 
 

//
// G_PlayerReborn
// Called after a player dies 
// almost everything is cleared and initialized 
//
void __far G_PlayerReborn () { 
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
// G_DoCompleted 
//
  
void __far G_ExitLevel (void)  { 
    secretexit = false; 
    gameaction = ga_completed; 
} 

// Here's for the german edition.
void __far G_SecretExitLevel (void) { 
    // IF NO WOLF3D LEVELS, NO SECRET EXIT!
    if ( (commercial) && (W_CheckNumForName("map31")<0)){
        secretexit = false;
    } else {
        secretexit = true; 
    }
    gameaction = ga_completed; 
} 
 
void __near G_DoCompleted (void)  { 
         
    gameaction = ga_nothing; 
	G_PlayerFinishLevel(0); // take away cards and stuff

    if (automapactive) {
        AM_Stop (); 
    }
    if (!commercial){
        switch(gamemap) {
            case 8:
                gameaction = ga_victory;
                return;
            case 9: 
                player.didsecret = true; 
                break;
        }
    }

    
         
    wminfo.didsecret = player.didsecret; 
    wminfo.epsd = gameepisode -1; 
    wminfo.last = gamemap -1;
    
    // wminfo.next is 0 biased, unlike gamemap
    if (commercial) {
        if (secretexit) {
            switch(gamemap) {
                case 15: 
                    wminfo.next = 30; 
                    break;
                case 31: 
                    wminfo.next = 31; 
                    break;
            }
        } else {
            switch(gamemap) {
                case 31:
                case 32: 
                    wminfo.next = 15; 
                    break;
                default: 
                    wminfo.next = gamemap;
            }
        }
    } else {
        if (secretexit) {
            wminfo.next = 8;    // go to secret level 
        } else if (gamemap == 9) {
            // returning from secret level 
            switch (gameepisode)  { 
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
        } else {
            wminfo.next = gamemap;          // go to next level 
        }
    }
                 
    wminfo.maxkills = totalkills; 
    wminfo.maxitems = totalitems; 
    wminfo.maxsecret = totalsecret; 


 
	wminfo.plyr.in = true;
    wminfo.plyr.skills = player.killcount; 
    wminfo.plyr.sitems = player.itemcount; 
    wminfo.plyr.ssecret = player.secretcount; 
    wminfo.plyr.stime = FastDiv32u16u(leveltime.w, 35); 
 
    gamestate = GS_INTERMISSION; 
    viewactive = false; 
    automapactive = false; 

    // pars need intermission data mapped in.
    Z_QuickMapIntermission();
    

    WI_Start (&wminfo, secretexit); 

    Z_QuickMapPhysics();
} 

/*
 void __far dolog(int16_t a){

	FILE* fp = fopen("log2.txt", "ab");
    
    fputc('0'+a / 10000, fp);
    fputc('0'+(a%10000) / 1000 , fp);
    fputc('0'+(a%1000) / 100  , fp);
    fputc('0'+(a%100) / 10   , fp);
    fputc('0'+ a % 10  , fp);
    fputc('\n'         , fp);
    fclose(fp);

}
/*
 void __near dologbig(int32_t a){
    int8_t  hexdigits[17] = "0123456789ABCDEF";
	FILE* fp = fopen("log.txt", "ab");
    
    fputc(hexdigits[a>>28]   , fp);
    fputc(hexdigits[(a&0xFFFFFFF)>>24]   , fp);
    fputc(hexdigits[(a&0xFFFFFF)>>20]   , fp);
    fputc(hexdigits[(a&0xFFFFF)>>16]   , fp);
    fputc(hexdigits[(a&0xFFFF)>>12]   , fp);
    fputc(hexdigits[(a&0xFFF)>>8]   , fp);
    fputc(hexdigits[(a&0xFF)>>4]   , fp);
    fputc(hexdigits[a%16]   , fp);
    fputc('\n'         , fp);
    fclose(fp);

}
*/


//
// G_InitFromSavegame
// Can be called by the startup code or the menu task. 
//

// todo make larger?


void __far G_LoadGame (int8_t* name)  { 
    strcpy (savename, name); 
    gameaction = ga_loadgame; 
} 
 
#define VERSIONSIZE             16 

void __near R_ExecuteSetViewSize (void);
void Z_QuickMapRender_4000To9000_9000Only();

void __near G_DoLoadGame (void)  { 
	
	filelength_t         length;
//	FILE* fp = fopen("log2.txt", "wb");
	
	byte __far*           savebuffer = MK_FP(0x5000, 0);
    gameaction = ga_nothing; 
    
    Z_QuickMapScratch_5000();

    length = M_ReadFile (savename, savebuffer); 
    save_p = savebuffer + SAVESTRINGSIZE;
    
    // skip the description field 
    if (locallib_strcmp ((int8_t __far*)save_p, versionstring)) {
        //I_Error("%Fs %Fs", save_p, versionstring);
        return;                         // bad version 
    }
    save_p += VERSIONSIZE; 
                         
    gameskill = *save_p++; 
    gameepisode = *save_p++; 
    gamemap = *save_p++; 
    *save_p++;  // playeringam,e
	*save_p++; *save_p++; *save_p++;

    // load a base level 
    G_InitNew (gameskill, gameepisode, gamemap);    // runs p_setup, sets fwipe, etc.

    // reload the file, re-set memory because G_InitNew ran a million things.
	Z_QuickMapPhysics();        // may be unnecessary, G_InitNew runs it?
    Z_QuickMapScratch_5000();

    length = M_ReadFile (savename, savebuffer); 

 
    // get the times 
    leveltime.b.intbytelow   = *save_p++; 
    leveltime.b.fracbytehigh = *save_p++; 
    leveltime.b.fracbytelow  = *save_p++; 


    // dearchive all the modifications
    //dolog(save_p-savebuffer);
    P_UnArchivePlayers (); 
	Z_QuickMapRender_4000To9000_9000Only();
    P_UnArchiveWorld (); 
    P_UnArchiveThinkers (); 

    P_UnArchiveSpecials (); 
#ifdef CHECK_FOR_ERRORS

    if (*save_p != 0x1d) 
        I_Error ("Bad savegame");
#endif
   
    Z_QuickMapPhysics();
 
    if (setsizeneeded){
        R_ExecuteSetViewSize ();
    }
    
    // draw the pattern into the back screen
	R_FillBackScreen ();   




} 
 

//
// G_SaveGame
// Called by the menu task.
// Description is a 24 byte text string 
//
void __far G_SaveGame(int8_t   slot, int8_t __far* description ) { 
    int8_t i;
    savegameslot = slot; 
    

    // todo: memcpy, locallib_strcpy not working
    //FAR_memcpy((int8_t __far*)savedescription, description, SAVESTRINGSIZE); 
    
    for (i = 0; i < SAVESTRINGSIZE; i++){
        savedescription[i] = description[i];
    }
    
    
    sendsave = true; 
} 


void __near G_DoSaveGame (void)  { 
	
    int8_t name[13] = "doomsav0.dsg";
    int8_t i;

	filelength_t         length;
	byte __far*       savebuffer; 
    name[7] = '0' + savegameslot;


    Z_QuickMapScratch_5000();

	
    save_p = savebuffer = MK_FP(0x5000, 0);
         

    // todo: memcpy, locallib_strcpy not working
    //FAR_memcpy (save_p, savedescription, SAVESTRINGSIZE); 
    for (i = 0; i < SAVESTRINGSIZE; i++){
        save_p[i] = savedescription[i];
    }
    save_p += SAVESTRINGSIZE; 


    FAR_memcpy (save_p, versionstring, 12);
    
    //FAR_memcpy (save_p, versionstring, VERSIONSIZE); 
    save_p += 12; 
    *save_p++ = 0; // last 4 bytes of versionsize...
    *save_p++ = 0;
    *save_p++ = 0;
    *save_p++ = 0;
    //save_p += VERSIONSIZE; 
         
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
	// page in si_render_9000
	Z_QuickMapRender_4000To9000_9000Only();

    P_ArchivePlayers (); 
    P_ArchiveWorld (); 
    // mobjposlist back in 9000
    //Z_QuickMapPhysics();
    //Z_QuickMapScratch_5000();
    P_ArchiveThinkers (); 
    P_ArchiveSpecials (); 
         
    *save_p++ = 0x1d;           // consistancy marker 
         
    length = save_p - savebuffer; 

	if (length > SAVEGAMESIZE){
        I_Error ("Savegame buffer overrun"); 
    }
    M_WriteFile (name, savebuffer, length); 
    gameaction = ga_nothing; 
    savedescription[0] = 0;              
         
    player.message = GGSAVED; 
    //hudneedsupdate = 6;
	Z_QuickMapPhysics();

    // draw the pattern into the back screen
    R_FillBackScreen ();        
	
} 
 

//
// G_InitNew
// Can be called by the startup code or the menu task,
// consoleplayer, displayplayer, playeringame[] should be set. 
//
 
void __near G_DeferedInitNew ( skill_t skill, int8_t episode, int8_t map) { 
    d_skill = skill; 
    d_episode = episode; 
    d_map = map; 
    gameaction = ga_newgame; 
} 

void __far G_InitNew(skill_t skill, int8_t episode, int8_t map);





//
// DEMO RECORDING 
// 
#define DEMOMARKER              0x80

void __near G_ReadDemoTiccmd (ticcmd_t __near* cmd)  { 
    // this is just used as an offset so lets just store as int;
	byte __far* demo_addr = (byte __far*)MK_FP(DEMO_SEGMENT, demo_p);
	Z_QuickMapDemo();

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
	Z_QuickMapPhysics();

}

boolean __near G_GetGameKey(int8_t keyr);

void __near G_WriteDemoTiccmd (ticcmd_t __near* cmd)  { 
	byte __far* demo_addr = (byte __far*)MK_FP(DEMO_SEGMENT, demo_p);

	Z_QuickMapDemo();
	if (G_GetGameKey('q')){           // press q to end demo recording 
        G_CheckDemoStatus (); 
    }
	

	*demo_addr++ = cmd->forwardmove;
    *demo_addr++ = cmd->sidemove;
    *demo_addr++ = (cmd->angleturn+128)>>8;
    *demo_addr++ = cmd->buttons;
	demo_addr -= 4;
	
    if (demo_p > (DEMO_MAX_SIZE - 16)) {
        // no more space 
        G_CheckDemoStatus (); 
		Z_QuickMapPhysics();
		return;
    } 

    // i hate this call. why is it here? get rid of it? - sq
    G_ReadDemoTiccmd (cmd);         // make SURE it is exactly the same 
    // G_ReadDemoTiccmd updates demo_p and calls Z_QuickMapPhysics already..


} 
 
 
 
 

 

//
// G_PlayDemo 
//

 
void __far G_DeferedPlayDemo (int8_t* name)  { 
    defdemoname = name; 
    gameaction = ga_playdemo; 
} 
 
void __near G_DoPlayDemo (void)  { 
    skill_t skill; 
	int8_t episode, map;
	byte __far* demo_addr;
	Z_QuickMapDemo();

	gameaction = ga_nothing;

	W_CacheLumpNameDirect(defdemoname, demobuffer);
	demo_addr = (byte __far*)(demobuffer);
	demo_p = 0;


	if ( *demo_addr++ != VERSION) {
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
	G_InitNew (skill, episode, map);
	precache = true;

    usergame = false; 
    demoplayback = true; 

	demo_p = (demo_addr - demobuffer);
	Z_QuickMapPhysics();

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

boolean __far G_CheckDemoStatus (void)  { 
	ticcount_t             endtime;
#ifdef DETAILED_BENCH_STATS
	uint32_t fps, fps2;
#endif
	//byte* demobuffer;
	byte __far* demo_addr;
	if (timingdemo) {
		endtime = ticcount;

#ifdef DETAILED_BENCH_STATS
		fps = (35000u * (uint32_t)(gametic) / (uint32_t)(endtime - starttime));
		fps2 = (35000u * (uint32_t)(gametic) / (uint32_t)(endtime - starttime - wipeduration));

        I_Error ("\ntimed %li gametics in %li realtics (%li without %i fwipe)\n FPS: %lu.%.3lu fps, %lu.%.3lu fps without fwipe \nCache Evictions: Sprites: %i, Flats: %i, Patches: %i, Composites: %i \nPhysics Tics %u\n Render Tics %u\n   Render Setup Tics %u\n   Render PlayerView Tics %u\n    Render InPlayerView Setup Tics %u\n    Render InPlayerView BSP Tics %u\n    Render InPlayerView Plane Tics %u\n    Render InPlayerView Masked Tics %u\n   Render Post PlayerView Tics %u\n Other Tics %u \n Task Switches: %li\n  Texture Cache Switches: %li (%li, %li, %li Patch/Composite/Sprite)\n  Flat Cache Switches: %li\n  Scratch Cache Switches: %li  \n Lump info Pushes to 0x9000: %li  To 0x5000: %li\n prnd index %i ",
			gametic  , endtime-starttime , endtime-starttime- wipeduration, wipeduration, 
			fps / 1000, fps % 1000, fps2 / 1000, fps2%1000,
            spritecacheevictcount, flatcacheevictcount, patchcacheevictcount, compositecacheevictcount,
			physicstics, rendertics, rendersetuptics, renderplayerviewtics, 
			renderplayersetuptics, renderplayerbsptics, renderplayerplanetics, renderplayermaskedtics,
			renderpostplayerviewtics, 
			othertics, 
			taskswitchcount, texturepageswitchcount , patchpageswitchcount, compositepageswitchcount, spritepageswitchcount,flatpageswitchcount, scratchpageswitchcount ,
			lumpinfo9000switchcount, lumpinfo5000switchcount,
			prndindex);

 
#else

		I_Error("\ntimed %li gametics in %li realtics \n prnd index %i ", gametic, endtime - starttime,  prndindex );

/*

		I_Error("\ntimed %li gametics in %li realtics \n prnd index %i ", gametic , endtime - starttime,  prndindex,
            
                        spritecacheevictcount, flatcacheevictcount, patchcacheevictcount, compositecacheevictcount

            );
*/

#endif

	} 
         
    if (demoplayback)  { 
        if (singledemo) {
            I_Quit (); 
        }
                         
        demoplayback = false; 
        netdemo = false;
        respawnparm = false;
        fastparm = false;
        nomonsters = false;
        advancedemo = true;
        return true; 
    } 
 
    if (demorecording)  { 
		Z_QuickMapDemo();
		demo_addr = (byte __far*)MK_FP(DEMO_SEGMENT, demo_p);
		*demo_addr++ = DEMOMARKER;
		demo_p++;
        M_WriteFile (demoname, demobuffer, demo_p);
        demorecording = false; 
        I_Error ("Demo %s recorded",demoname); 
	}
         
    return false; 
} 
 
 
 

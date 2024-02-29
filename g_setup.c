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
#define NUMKEYS         256 
extern uint16_t     R_TextureNumForName(int8_t* name);
//
// G_DoLoadLevel 
//
extern  gamestate_t     wipegamestate;
extern uint16_t		skytexture;
extern ticcount_t             starttime;              // for comparative timing purposes       
extern boolean			gamekeydown[NUMKEYS];


// mouse values are used once 
extern int8_t             mousex;
extern int8_t             mousey;

extern boolean         sendpause;              // send a pause event next tic 
extern boolean         sendsave;               // send a save event next tic 

extern boolean*        mousebuttons;
extern boolean         mousearray[4];

   
extern int16_t             numtextures;


// R_CheckTextureNumForName
// Check whether texture is available.
// Filter out NoTexture indicator.
//
uint16_t     R_CheckTextureNumForName(int8_t *name)
{
	uint16_t         i;
	texture_t __far* texture;
	int8_t texturename[8];
	// "NoTexture" marker.
	if (name[0] == '-')
		return 0;

	for (i = 0; i < numtextures; i++) {
		texture = (texture_t __far*)&(texturedefs_bytes[texturedefs_offset[i]]);

		FAR_strncpy(texturename, texture->name, 8);
		//DEBUG_PRINT("\n %.8Fs %8s %8s %i %Fp", texture->name, texturename, name, texture->name);

		if (!strncasecmp(texturename, name, 8)) {
			//DEBUG_PRINT("\n FOUND %i %s %s %s", i, texture->name, texturename, name);
			return i;
		}
	}
	/*
	for (i = 0; i < 5; i++) {
		texture = (texture_t __far*)&(texturedefs_bytes[texturedefs_offset[i]]);
		FAR_strncpy(texturename, texture->name, 8);
		DEBUG_PRINT("\n %i %s %s", i, texture->name, texturename);
	}
	I_Error("\n%s", name);
	*/
	return BAD_TEXTURE;
}



//
 


void G_DoLoadLevel(void)
{
	
#if (EXE_GAME_VERSION >= EXE_VERSION_FINAL2)
	Z_QuickmapRender();
	// DOOM determines the sky texture to be used
	// depending on the current episode, and the game version.
	if (commercial)
	{
		skytexture = R_TextureNumForName("SKY3");
		if (gamemap < 12)
			skytexture = R_TextureNumForName("SKY1");
		else
			if (gamemap < 21)
				skytexture = R_TextureNumForName("SKY2");
	}
#endif

	Z_QuickmapPhysics();

	if (wipegamestate == GS_LEVEL)
		wipegamestate = -1;             // force a wipe 

	gamestate = GS_LEVEL;


	if (player.playerstate == PST_DEAD)
		player.playerstate = PST_REBORN;

	P_SetupLevel(gameepisode, gamemap, gameskill);
	starttime = ticcount;
	gameaction = ga_nothing;
	//Z_CheckHeap ();

	// clear cmd building stuff
	memset(gamekeydown, 0, sizeof(gamekeydown));
	mousex = mousey = 0;
	sendpause = sendsave = paused = false;
	memset(mousebuttons, 0, sizeof(mousebuttons));


}




void
G_InitNew
(skill_t       skill,
	int8_t           episode,
	int8_t           map)
{
	int16_t             i;

	if (paused)
	{
		paused = false;
		S_ResumeSound();
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

	if ((map > 9)
		&& (!commercial))
		map = 9;

	M_ClearRandom();

	if (skill == sk_nightmare || respawnparm)
		respawnmonsters = true;
	else
		respawnmonsters = false;

	if (fastparm || (skill == sk_nightmare && gameskill != sk_nightmare))
	{
		for (i = S_SARG_RUN1; i <= S_SARG_PAIN2; i++)
			states[i].tics >>= 1;
		mobjinfo[MT_BRUISERSHOT].speed = 20 + HIGHBIT;
		mobjinfo[MT_HEADSHOT].speed = 20 + HIGHBIT;
		mobjinfo[MT_TROOPSHOT].speed = 20 + HIGHBIT;
	}
	else if (skill != sk_nightmare && gameskill == sk_nightmare)
	{
		for (i = S_SARG_RUN1; i <= S_SARG_PAIN2; i++)
			states[i].tics <<= 1;
		mobjinfo[MT_BRUISERSHOT].speed = 15 + HIGHBIT;
		mobjinfo[MT_HEADSHOT].speed = 10 + HIGHBIT;
		mobjinfo[MT_TROOPSHOT].speed = 10 + HIGHBIT;
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
	Z_QuickmapRender();
	//Z_QuickmapTextureInfoPage();


	// set the sky map for the episode
	if (commercial)
	{
		skytexture = R_TextureNumForName("SKY3");
		if (gamemap < 12)
			skytexture = R_TextureNumForName("SKY1");
		else
			if (gamemap < 21)
				skytexture = R_TextureNumForName("SKY2");
	}
	else
		switch (episode)
		{
		case 1:
			skytexture = R_TextureNumForName("SKY1");
			break;
		case 2:
			skytexture = R_TextureNumForName("SKY2");
			break;
		case 3:
			skytexture = R_TextureNumForName("SKY3");
			break;
		case 4:       // Special Edition sky
			skytexture = R_TextureNumForName("SKY4");
			break;
		}

	Z_QuickmapPhysics();

	G_DoLoadLevel();

}

extern boolean         netdemo;
extern skill_t d_skill;
extern int8_t     d_episode;
extern int8_t     d_map;




void G_DoNewGame(void)
{
	demoplayback = false;
	netdemo = false;
	//playeringame[1] = playeringame[2] = playeringame[3] = 0;
	respawnparm = false;
	fastparm = false;
	nomonsters = false;
	G_InitNew(d_skill, d_episode, d_map);
	gameaction = ga_nothing;
}



void G_DoWorldDone(void)
{
	gamestate = GS_LEVEL;
	gamemap = wminfo.next + 1;
	G_DoLoadLevel();
	gameaction = ga_nothing;
	viewactive = true;

}

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
#include <dos.h>

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
#include "g_game.h"

#define NUMKEYS         256 
uint16_t   __far  R_TextureNumForName(int8_t* name);



// R_CheckTextureNumForName
// Check whether texture is available.
// Filter out NoTexture indicator.
//
// this is always called in a situation where the texture defs must be mapped down to 6000
// first, so we just use 6000 in here for texturedefs etc.
uint16_t   __far  R_CheckTextureNumForName(int8_t *name) {
	uint16_t         i;
	texture_t __far* texture;
	int8_t texturename[8];

	for (i = 0; i < numtextures; i++) {
		texture = (texture_t __far*)&(texturedefs_bytes_6000[texturedefs_offset_6000[i]]);

		copystr8(texturename, texture->name);
		//DEBUG_PRINT("\n %.8Fs %8s %8s %i %Fp", texture->name, texturename, name, texture->name);

		if (!locallib_strncasecmp(texturename, name, 8)) {
			//DEBUG_PRINT("\n FOUND %i %s %s %s", i, texture->name, texturename, name);
			return i;
		}
	}


	return BAD_TEXTURE;
}


//
// R_TextureNumForName
// Calls R_CheckTextureNumForName,
//  aborts with error message.
//
uint16_t     __far R_TextureNumForName(int8_t* name) {
	uint16_t i;
	FILE* fp;
	// "NoTexture" marker.
	if (name[0] == '-'){
		return 0;
	}

	i = R_CheckTextureNumForName(name);
	/*
	fp = fopen ("texes.txt", "ab");
	fprintf (fp, "%i %s\n",i, name );
	fclose(fp);
	*/

	if (i == BAD_TEXTURE) {
		I_Error("\n96 %s", name); // \nR_TextureNumForName: %s not found
	}
	return i;
}


//
 
void __near G_ResetGameKeys();

void __near G_DoLoadLevel(void) {
	#ifdef MOVE_P_SETUP
	void (__far  * P_SetupLevel)(int8_t, int8_t, skill_t) = P_SetupLevelAddr;
	#endif

#if (EXE_GAME_VERSION >= EXE_VERSION_FINAL2)
	Z_QuickMapRender();
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

	Z_QuickMapPhysics();

	if (wipegamestate == GS_LEVEL){
		wipegamestate = -1;             // force a wipe 
	}

	gamestate = GS_LEVEL;


	if (player.playerstate == PST_DEAD){
		player.playerstate = PST_REBORN;
	}

	P_SetupLevel(gameepisode, gamemap, gameskill);
	starttime = ticcount;
	gameaction = ga_nothing;
	//Z_CheckHeap ();

	// clear cmd building stuff
	G_ResetGameKeys();
	mousex = 0;
	sendpause = sendsave = paused = false;
	memset(mousebuttons, 0, sizeof(mousebuttons));


}




void __far G_InitNew (skill_t skill, int8_t episode, int8_t map) {
	int16_t             i;

	if (paused) {
		paused = false;
		S_ResumeSound();
	}


	if (skill > sk_nightmare){
		skill = sk_nightmare;
	}

	if (!is_ultimate){
		if (episode < 1) {
			episode = 1;
		}
		if (episode > 3) {
			episode = 3;
		}
	} else {
		if (episode == 0) {
			episode = 4;
		}
	}

	if (episode > 1 && shareware) {
		episode = 1;
	}

	if (map < 1){
		map = 1;
	}

	if ((map > 9) && (!commercial)){
		map = 9;
	}

	//M_ClearRandom();
    rndindex = prndindex = 0;


	if (skill == sk_nightmare || respawnparm){
		respawnmonsters = true;
	} else {
		respawnmonsters = false;
	}

	if (fastparm || (skill == sk_nightmare && gameskill != sk_nightmare)){
		for (i = S_SARG_RUN1; i <= S_SARG_PAIN2; i++){
			states[i].tics >>= 1;
		}
		mobjinfo[MT_BRUISERSHOT].speed = 20 + HIGHBIT;
		mobjinfo[MT_HEADSHOT].speed = 20 + HIGHBIT;
		mobjinfo[MT_TROOPSHOT].speed = 20 + HIGHBIT;
	}
	else if (skill != sk_nightmare && gameskill == sk_nightmare) {
		for (i = S_SARG_RUN1; i <= S_SARG_PAIN2; i++){
			states[i].tics <<= 1;
		}
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
	Z_QuickMapRender();
	Z_QuickMapRender_9000To6000();//for R_TextureNumForName


	// set the sky map for the episode
	if (commercial) {
		skytexture = R_TextureNumForName("SKY3");
		if (gamemap < 12){
			skytexture = R_TextureNumForName("SKY1");
		} else{
			if (gamemap < 21) {
				//skytexture = R_TextureNumForName("ASHWALL2");  // for debugging skytexture issues...
				skytexture = R_TextureNumForName("SKY2");
			}
		}
	} else {
		switch (episode) {
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
	}
	
	Z_QuickMapPhysics();

	G_DoLoadLevel();

}





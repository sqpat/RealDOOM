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
//      Do all the WAD I/O, get map description,
//      set up initial state and misc. LUTs.
//


#include <math.h>
#include "z_zone.h"

#include "m_misc.h"

#include "g_game.h"

#include "i_system.h"
#include "w_wad.h"

#include "doomdef.h"
#include "p_local.h"
#include "p_setup.h"

#include "s_sound.h"

#include "doomstat.h"
#include "memory.h"

extern uint16_t		switchlist[MAXSWITCHES * 2];
extern int16_t		numswitches;
extern button_t        buttonlist[MAXBUTTONS];

 
//todo move this data into functions so it's pulled into overlay space and paged out to free memory



//extern byte __far* texturedefs_bytes; 
extern int16_t             numtextures;
 

// R_CheckTextureNumForName
// Check whether texture is available.
// Filter out NoTexture indicator.
//
extern uint16_t  __far   R_TextureNumForName(int8_t* name);
extern uint16_t  __far   R_CheckTextureNumForName(int8_t *name);
  




#define NUMSWITCHDEFS 41

//
// P_InitSwitchList
// Only called at game initialization.
//
void __near P_InitSwitchList(void)
{
	int8_t		i;
	int8_t		index;
	int8_t		episode;
	//
// CHANGE THE TEXTURE OF A WALL SWITCH TO ITS OPPOSITE
//
	switchlist_t alphSwitchList[NUMSWITCHDEFS];

	FILE *fp = fopen("D_SWITCH.BIN", "rb"); // clear old file
	fread(alphSwitchList, sizeof(switchlist_t), NUMSWITCHDEFS, fp);
	fclose(fp);
	//I_Error("\nval %s %s %s", alphSwitchList[0].name1, alphSwitchList[1].name1, alphSwitchList[2].name1);


	/*

	switchlist_t alphSwitchList[] =
	{
		// Doom shareware episode 1 switches
		{"SW1BRCOM",	"SW2BRCOM",	1},
		{"SW1BRN1",	"SW2BRN1",	1},
		{"SW1BRN2",	"SW2BRN2",	1},
		{"SW1BRNGN",	"SW2BRNGN",	1},
		{"SW1BROWN",	"SW2BROWN",	1},
		{"SW1COMM",	"SW2COMM",	1},
		{"SW1COMP",	"SW2COMP",	1},
		{"SW1DIRT",	"SW2DIRT",	1},
		{"SW1EXIT",	"SW2EXIT",	1},
		{"SW1GRAY",	"SW2GRAY",	1},
		{"SW1GRAY1",	"SW2GRAY1",	1},
		{"SW1METAL",	"SW2METAL",	1},
		{"SW1PIPE",	"SW2PIPE",	1},
		{"SW1SLAD",	"SW2SLAD",	1},
		{"SW1STARG",	"SW2STARG",	1},
		{"SW1STON1",	"SW2STON1",	1},
		{"SW1STON2",	"SW2STON2",	1},
		{"SW1STONE",	"SW2STONE",	1},
		{"SW1STRTN",	"SW2STRTN",	1},

		// Doom registered episodes 2&3 switches
		{"SW1BLUE",	"SW2BLUE",	2},
		{"SW1CMT",		"SW2CMT",	2},
		{"SW1GARG",	"SW2GARG",	2},
		{"SW1GSTON",	"SW2GSTON",	2},
		{"SW1HOT",		"SW2HOT",	2},
		{"SW1LION",	"SW2LION",	2},
		{"SW1SATYR",	"SW2SATYR",	2},
		{"SW1SKIN",	"SW2SKIN",	2},
		{"SW1VINE",	"SW2VINE",	2},
		{"SW1WOOD",	"SW2WOOD",	2},

		// Doom II switches
		{"SW1PANEL",	"SW2PANEL",	3},
		{"SW1ROCK",	"SW2ROCK",	3},
		{"SW1MET2",	"SW2MET2",	3},
		{"SW1WDMET",	"SW2WDMET",	3},
		{"SW1BRIK",	"SW2BRIK",	3},
		{"SW1MOD1",	"SW2MOD1",	3},
		{"SW1ZIM",		"SW2ZIM",	3},
		{"SW1STON6",	"SW2STON6",	3},
		{"SW1TEK",		"SW2TEK",	3},
		{"SW1MARB",	"SW2MARB",	3},
		{"SW1SKULL",	"SW2SKULL",	3},

		{"\0",		"\0",		0}
	};

	*/

	episode = 1;

	if (registered)
		episode = 2;
	else if (commercial)
		episode = 3;

	for (index = 0, i = 0; i < MAXSWITCHES; i++) {
		if (!alphSwitchList[i].episode) {
			numswitches = index / 2;
			switchlist[index] = BAD_TEXTURE;
			break;
		}

		if (alphSwitchList[i].episode <= episode) {

			switchlist[index++] = R_TextureNumForName(alphSwitchList[i].name1);
			switchlist[index++] = R_TextureNumForName(alphSwitchList[i].name2);
		}
	}

}

//
// Animating textures and planes
// There is another anim_t used in wi_stuff, unrelated.
//
typedef struct
{
	boolean	istexture;
	uint16_t		picnum;
	uint16_t		basepic;
	uint8_t		numpics;

} anim_t;
#define MAXANIMS                32

extern anim_t		anims[MAXANIMS];
extern anim_t __near*		lastanim;

typedef struct
{
	boolean	istexture;	// if false, it is a flat
	int8_t	endname[9];
	int8_t	startname[9];
} animdef_t;
//
// P_InitPicAnims
//



extern uint8_t __far R_FlatNumForName(int8_t* name);




#define NUMANIMDEFS 23
void __near P_InitPicAnims(void)
{
	int16_t		i;
	// Floor/ceiling animation sequences,
//  defined by first and last frame,
//  i.e. the flat (64x64 tile) name to
//  be used.
// The full animation sequence is given
//  using all the flats between the start
//  and end entry, in the order found in
//  the WAD file.
//
	animdef_t animdefs[NUMANIMDEFS];
	FILE *fp = fopen("D_ANIMS.BIN", "rb"); // clear old file
	fread(animdefs, sizeof(animdef_t), NUMANIMDEFS, fp);
	fclose(fp);
	//I_Error("\nvalanim %s %s %s", animdefs[0].startname, animdefs[1].startname, animdefs[2].startname);

	/*

	animdef_t		animdefs[] =
	{
		{false,	"NUKAGE3",	"NUKAGE1"},
		{false,	"FWATER4",	"FWATER1"},
		{false,	"SWATER4",	"SWATER1"},
		{false,	"LAVA4",	"LAVA1"},
		{false,	"BLOOD3",	"BLOOD1"},

		// DOOM II flat animations.
		{false,	"RROCK08",	"RROCK05"},
		{false,	"SLIME04",	"SLIME01"},
		{false,	"SLIME08",	"SLIME05"},
		{false,	"SLIME12",	"SLIME09"},

		{true,	"BLODGR4",	"BLODGR1"},
		{true,	"SLADRIP3",	"SLADRIP1"},

		{true,	"BLODRIP4",	"BLODRIP1"},
		{true,	"FIREWALL",	"FIREWALA"},
		{true,	"GSTFONT3",	"GSTFONT1"},
		{true,	"FIRELAVA",	"FIRELAV3"},
		{true,	"FIREMAG3",	"FIREMAG1"},
		{true,	"FIREBLU2",	"FIREBLU1"},
		{true,	"ROCKRED3",	"ROCKRED1"},

		{true,	"BFALL4",	"BFALL1"},
		{true,	"SFALL4",	"SFALL1"},
		{true,	"WFALL4",	"WFALL1"},
		{true,	"DBRAIN4",	"DBRAIN1"},

		{-1}
	};
	*/

	//	Init animation
	lastanim = anims;
	//for (i = 0; animdefs[i].istexture != -1; i++) {
	for (i = 0; i < NUMANIMDEFS; i++) {
		
		if (animdefs[i].istexture)
		{
			// different episode ?
			if (R_CheckTextureNumForName(animdefs[i].startname) == BAD_TEXTURE)
				continue;

			lastanim->picnum = R_TextureNumForName(animdefs[i].endname);
			lastanim->basepic = R_TextureNumForName(animdefs[i].startname);
		}
		else
		{
			if (W_CheckNumForName(animdefs[i].startname) == -1)
				continue;

			lastanim->picnum = R_FlatNumForName(animdefs[i].endname);
			lastanim->basepic = R_FlatNumForName(animdefs[i].startname);
		}

		lastanim->istexture = animdefs[i].istexture;
		lastanim->numpics = lastanim->picnum - lastanim->basepic + 1;
#ifdef CHECK_FOR_ERRORS
		if (lastanim->numpics < 2)
			I_Error("P_InitPicAnims: bad cycle from %s to %s",
				animdefs[i].startname,
				animdefs[i].endname);
#endif

		lastanim++;
	}
	//DUMP_MEMORY_TO_FILE();

}

spriteframe_t __far* sprtemp;
int16_t             maxframe;

//
// R_InstallSpriteLump
// Local function for R_InitSprites.
//
void
__near R_InstallSpriteLump
(int16_t           lump,
	uint16_t      frame,
	uint16_t      rotation,
	boolean       flipped)
{
	int16_t         r;

#ifdef CHECK_FOR_ERRORS
	if (frame >= 29 || rotation > 8)
		I_Error("\nR_InstallSpriteLump: "
			"Bad frame characters in lump %i", lump);
#endif

	if ((int16_t)frame > maxframe)
		maxframe = frame;

	if (rotation == 0)
	{
		// the lump should be used for all rotations
#ifdef CHECK_FOR_ERRORS
		if (sprtemp[frame].rotate == false)
			I_Error("R_InitSprites: Sprite %s frame %c has "
				"multip rot=0 lump", spritename, 'A' + frame);

		if (sprtemp[frame].rotate == true)
			I_Error("R_InitSprites: Sprite %s frame %c has rotations "
				"and a rot=0 lump", spritename, 'A' + frame);
#endif

		sprtemp[frame].rotate = false;
		for (r = 0; r < 8; r++)
		{
			sprtemp[frame].lump[r] = lump - firstspritelump;
			sprtemp[frame].flip[r] = (byte)flipped;
		}
		return;
	}

	// the lump is only used for one rotation
#ifdef CHECK_FOR_ERRORS
	if (sprtemp[frame].rotate == false)
		I_Error("R_InitSprites: Sprite %s frame %c has rotations "
			"and a rot=0 lump", spritename, 'A' + frame);
#endif            
	sprtemp[frame].rotate = true;

	// make 0 based
	rotation--;
#ifdef CHECK_FOR_ERRORS
	if (sprtemp[frame].lump[rotation] != -1)
		I_Error("R_InitSprites: Sprite %s : %c : %c "
			"has two lumps mapped to it",
			spritename, 'A' + frame, '1' + rotation);
#endif            
	sprtemp[frame].lump[rotation] = lump - firstspritelump;
	sprtemp[frame].flip[rotation] = (byte)flipped;
}

 


 extern spritedef_t __far* sprites;

extern int16_t             numsprites;

extern int16_t             maxframe;

//
// R_InitSpriteDefs
// Pass a null terminated list of sprite names
//  (4 chars exactly) to be used.
// Builds the sprite rotation matrixes to account
//  for horizontally flipped sprites.
// Will report an error if the lumps are inconsistant. 
// Only called at startup.
//
// Sprite lump names are 4 characters for the actor,
//  a letter for the frame, and a number for the rotation.
// A sprite that is flippable will have an additional
//  letter/number appended.
// The rotation character can be 0 to signify no rotations.
//


void __near R_InitSpriteDefs()
{
	int16_t         i;
	int16_t         l;
	int32_t         intname;
	int16_t         frame;
	int16_t         rotation;
	int16_t         start;
	int16_t         end;
	int16_t         patched;
	spriteframe_t __far* spriteframes;
	uint16_t		currentspritememoryoffset;
	//int32_t totalsize = 0;
	byte sprtempbytes[29 * sizeof(spriteframe_t)];
	int8_t localname[8];
	/*

	int8_t *namelist[NUMSPRITES] = {
		"TROO","SHTG","PUNG","PISG","PISF","SHTF","SHT2","CHGG","CHGF","MISG",
		"MISF","SAWG","PLSG","PLSF","BFGG","BFGF","BLUD","PUFF","BAL1","BAL2",
		"PLSS","PLSE","MISL","BFS1","BFE1","BFE2","TFOG","IFOG","PLAY","POSS",
		"SPOS","VILE","FIRE","FATB","FBXP","SKEL","MANF","FATT","CPOS","SARG",
		"HEAD","BAL7","BOSS","BOS2","SKUL","SPID","BSPI","APLS","APBX","CYBR",
		"PAIN","SSWV","KEEN","BBRN","BOSF","ARM1","ARM2","BAR1","BEXP","FCAN",
		"BON1","BON2","BKEY","RKEY","YKEY","BSKU","RSKU","YSKU","STIM","MEDI",
		"SOUL","PINV","PSTR","PINS","MEGA","SUIT","PMAP","PVIS","CLIP","AMMO",
		"ROCK","BROK","CELL","CELP","SHEL","SBOX","BPAK","BFUG","MGUN","CSAW",
		"LAUN","PLAS","SHOT","SGN2","COLU","SMT2","GOR1","POL2","POL5","POL4",
		"POL3","POL1","POL6","GOR2","GOR3","GOR4","GOR5","SMIT","COL1","COL2",
		"COL3","COL4","CAND","CBRA","COL6","TRE1","TRE2","ELEC","CEYE","FSKU",
		"COL5","TBLU","TGRN","TRED","SMBT","SMGT","SMRT","HDB1","HDB2","HDB3",
		"HDB4","HDB5","HDB6","POB1","POB2","BRS1","TLMP","TLP2"
	};
	*/
	int8_t namelist[NUMSPRITES][5];
	FILE * fp = fopen("D_SPLIST.BIN", "rb"); // clear old file
	fread(namelist,  5, NUMSPRITES, fp);
	fclose(fp);
	//I_Error("\nvalanim %s %s %s", namelist[0], namelist[1], namelist[2]);

	// count the number of sprite names


 
	sprtemp = (spriteframe_t __far *) &sprtempbytes;
	numsprites = NUMSPRITES;

	if (!numsprites)
		return;

	
	sprites = (spritedef_t __far*)spritedefs_bytes;
	currentspritememoryoffset = sprites[0].spriteframesOffset = numsprites * sizeof(spritedef_t);
	//sprites[0].spriteframesOffset = numsprites * sizeof(*sprites);
	//totalsize = numsprites * sizeof(spritedef_t);

	start = firstspritelump - 1;
	end = lastspritelump + 1;

	// scan all the lump names for each of the names,
	//  noting the highest frame letter.
	// Just compare 4 characters as ints
	for (i = 0; i < numsprites; i++)
	{
#ifdef CHECK_FOR_ERRORS
		spritename = namelist[i];
#endif
		FAR_memset(sprtemp, -1, sizeof(sprtemp));

		maxframe = -1;
		intname = *(int32_t __far *)namelist[i];

		// scan the lumps,
		//  filling in the frames for whatever is found
		for (l = start + 1; l < end; l++)
		{
			if (*(int32_t  __far*)lumpinfo9000[l].name == intname)
			{
				frame = lumpinfo9000[l].name[4] - 'A';
				rotation = lumpinfo9000[l].name[5] - '0';

				if (modifiedgame) {
					copystr8(localname, lumpinfo9000[l].name);
					patched = W_GetNumForName(localname);
				}
				else
					patched = l;

				R_InstallSpriteLump(patched, frame, rotation, false);

				if (lumpinfo9000[l].name[6])
				{
					frame = lumpinfo9000[l].name[6] - 'A';
					rotation = lumpinfo9000[l].name[7] - '0';
					R_InstallSpriteLump(l, frame, rotation, true);
				}
			}
		}

		// check the frames that were found for completeness
		if (maxframe == -1)
		{
			sprites[i].numframes = 0;
			continue;
		}



		maxframe++;

		for (frame = 0; frame < maxframe; frame++)
		{
			switch ((int16_t)sprtemp[frame].rotate)
			{
			case -1:
				// no rotations were found for that frame at all
#ifdef CHECK_FOR_ERRORS
				I_Error("R_InitSprites: No patches found "
					"for %s frame %c", namelist[i], frame + 'A');
				break;
#endif

			case 0:
				// only the first rotation is needed
				break;

			case 1:
				// must have all 8 frames
				for (rotation = 0; rotation < 8; rotation++)
					if (sprtemp[frame].lump[rotation] == -1) {
#ifdef CHECK_FOR_ERRORS
						I_Error("R_InitSprites: Sprite %s frame %c "
							"is missing rotations",
							namelist[i], frame + 'A');
						break;
#endif
					}
			}
		}

		// allocate space for the frames present and copy sprtemp to it
		sprites[i].numframes = maxframe; // this  isnever used outside of here and r_setup...
		sprites[i].spriteframesOffset = currentspritememoryoffset;
		currentspritememoryoffset += (maxframe * sizeof(spriteframe_t));


		spriteframes = (spriteframe_t __far*)&(spritedefs_bytes[sprites[i].spriteframesOffset]);
		FAR_memcpy(spriteframes, sprtemp, maxframe * sizeof(spriteframe_t));

	}
	//I_Error("\n%u %x", currentspritememoryoffset, currentspritememoryoffset)
}



//
// R_InitSprites
// Called at program start.
//
void __near R_InitSprites()
{
	
	int		i;

	for (i = 0; i < SCREENWIDTH; i++)
	{
		negonearray[i] = -1;
	}

	R_InitSpriteDefs();
}

//
// P_Init
//
void __near P_Init(void) {

	Z_QuickMapRender();
	Z_QuickMapLumpInfo();
	P_InitSwitchList();
	P_InitPicAnims();
	R_InitSprites();

	Z_QuickMapPhysics();


}



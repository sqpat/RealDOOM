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
//	Rendering main loop and setup functions,
//	 utility functions (BSP, geometry, trigonometry).
//	See tables.c, too.
//



#include <stdlib.h>
#include <math.h>
#include "w_wad.h"


#include "doomdef.h"
#include "d_net.h"

#include "m_misc.h"

#include "r_local.h"


#include "i_system.h"
#include "doomstat.h"
#include  <alloca.h>



extern uint8_t			skyflatnum;



//
// R_FlatNumForName
// Retrieval, get a flat number for a flat name.
//
// note this function got duped across different overlays, but this ends up reducing overall conventional memory use
uint8_t R_FlatNumForNameB(int8_t* name)
{
	int16_t         i;
 
	i = W_CheckNumForName(name);

 

	return (uint8_t)(i - firstflat);
}



//
// R_InitSkyMap
// Called whenever the view size changes.
//
void R_InitSkyMap(void)
{
	skyflatnum = R_FlatNumForNameB("F_SKY1");
}


extern visplaneheader_t	*visplaneheaders;// [MAXEMSVISPLANES];
extern MEMREF 				visplanebytesRef[NUM_VISPLANE_PAGES];


//
// R_InitPlanes
// Only at game startup.
//
void R_InitPlanes(void) {
	// Doh!

	  // idea: create a single allocations with the arrays of the non-byte fields. this is only 10 bytes per visplane, 
	  // and that's the only thing that is ever iterated on. the big byte arrays are sort of used one at a time - those
	  // can be in a separately indexed set of data, that can in turn also be separately paged in and out as necessary.
	  // In theory this also makes it easier to dynamically allocate space to visplanes.

	  // byte fields per visplane is 644, we can fit 25 of those per 16k page. we can, instead of one big fat allocation 
	  // do those in individual 16k allocations and use the individual memref we need based on index. that should greatly
	  // reduce the paging involved?

	int16_t i;
	int16_t j;
	Z_QuickmapRender();

	for (i = 0; i < NUM_VISPLANE_PAGES; i++) {
		visplanebytesRef[i] = Z_MallocEMS(VISPLANE_BYTE_SIZE * VISPLANES_PER_EMS_PAGE, PU_STATIC, 0);

		for (j = 0; j < VISPLANES_PER_EMS_PAGE; j++) {
			visplaneheaders[i * VISPLANES_PER_EMS_PAGE + j].visplanepage = i;
			visplaneheaders[i * VISPLANES_PER_EMS_PAGE + j].visplaneoffset = j;
		}

	}

	Z_QuickmapPhysics();




}



//
// R_InitLightTables
// Only inits the zlight table,
//  because the scalelight table changes with view size.
//
#define DISTMAP		2

void R_InitLightTables(void)
{
	int16_t		i;
	int16_t		j;
	int16_t		level;
	int16_t		startmap;
	fixed_t		scale;
	fixed_t_union		temp, temp2;

	Z_QuickmapRender();
	
	// Calculate the light levels to use
	//  for each level / distance combination.
	temp.h.fracbits = 0;
	temp2.h.fracbits = 0;
	temp2.h.intbits = SCREENWIDTH / 2;
	for (i = 0; i < LIGHTLEVELS; i++)
	{
		startmap = ((LIGHTLEVELS - 1 - i) * 2) * 2; // *NUMCOLORMAPS/LIGHTLEVELS;
		temp.h.intbits = 1;
		for (j = 0; j < MAXLIGHTZ; j++)
		{
			temp.h.intbits += 16;

			scale = FixedDivWholeAB(temp2.w, temp.w);
			scale >>= LIGHTSCALESHIFT;
			level = startmap - scale / DISTMAP;

			if (level < 0)
				level = 0;

			if (level >= NUMCOLORMAPS)
				level = NUMCOLORMAPS - 1;

			zlight[i][j] = colormaps + (level * 256);
		}
	}
	Z_QuickmapPhysics();

}

extern byte         	*colormapbytes;// [(33 * 256) + 255];
extern lighttable_t    *colormaps;
extern int16_t             firstflat;
extern int16_t             lastflat;
extern int16_t             numflats;
//
// R_InitData
// Locates all the lumps
//  that will be used by all views
// Must be called after W_Init.
//




//
// R_InitSpriteLumps
// Finds the width and hoffset of all sprites in the wad,
//  so the sprite does not need to be cached completely
//  just for having the header info ready during rendering.
//
void R_InitSpriteLumps(void)
{
	int16_t         i;

	patch_t     *patch;
	MEMREF		patchRef;
	int16_t		patchwidth;
	int16_t		patchleftoffset;
	int16_t		patchtopoffset;

	firstspritelump = W_GetNumForName("S_START") + 1;
	lastspritelump = W_GetNumForName("S_END") - 1;

	numspritelumps = lastspritelump - firstspritelump + 1;

	for (i = 0; i < numspritelumps; i++)
	{

#ifdef DEBUG_PRINTING
		if (!(i & 63))
			printf(".");
#endif


		W_CacheLumpNumCheck(firstspritelump + i, 13);
		patchRef = W_CacheLumpNumEMS(firstspritelump + i, PU_CACHE);
		patch = (patch_t*)Z_LoadBytesFromEMS(patchRef);
		patchwidth = (patch->width);
		patchleftoffset = (patch->leftoffset);
		patchtopoffset = (patch->topoffset);

		spritewidths[i] = patchwidth;
		spriteoffsets[i] = patchleftoffset;
		spritetopoffsets[i] = patchtopoffset;

	}
}


//
// Texture definition.
// Each texture is composed of one or more patches,
// with patches being lumps stored in the WAD.
// The lumps are referenced by number, and patched
// into the rectangular texture space using origin
// and possibly other attributes.
//
typedef struct
{
	int16_t       originx;
	int16_t       originy;
	int16_t       patch;
	int16_t       stepdir;
	int16_t       colormap;
} mappatch_t;


 

//
// Texture definition.
// A DOOM wall texture is a list of patches
// which are to be combined in a predefined order.
//
typedef struct
{
	int8_t                name[8];  // 8
	byte				unusedA[4];        // 12  defining this in bytes to avoid 16/32 bit compiler differences
	int16_t               width;    // 14
	int16_t               height;   // 16
	byte                unusedB[4];      // 20 defining this in bytes to avoid 16/32 bit compiler differences
	int16_t               patchcount;// 22
	mappatch_t  patches[1];			 // 32
} maptexture_t;




extern int16_t             numtextures;

extern MEMREF textures[NUM_TEXTURE_CACHE];  // lists of MEMREFs kind of suck, this takes up relatively little memory and prevents lots of allocations;
extern MEMREF texturecomposite[NUM_TEXTURE_CACHE];  // see above


extern MEMREF texturecolumnlumpRefs[NUM_TEXTURE_CACHE];
extern MEMREF texturecolumnofsRefs[NUM_TEXTURE_CACHE];



extern uint8_t  texturewidthmasks[NUM_TEXTURE_CACHE];
// needed for texture pegging
extern uint8_t  textureheights[NUM_TEXTURE_CACHE];		    // uint8_t must be converted by fracbits when used*
extern uint16_t  texturecompositesizes[NUM_TEXTURE_CACHE];	// uint16_t*




//
// R_GenerateLookup
//
void R_GenerateLookup(uint8_t texnum)
{
	texture_t*          texture;
	byte*               patchcount;     // patchcount[texture->width]
	texpatch_t*         patch;
	patch_t*            realpatch;
	int16_t                 x;
	int16_t                 x1;
	int16_t                 x2;
	int16_t                 i;
	int16_t					patchpatch;
	int16_t*              collump;
	uint16_t*     		colofs;
	MEMREF				realpatchRef;
	uint8_t				texturepatchcount;
	int16_t				texturewidth;
	int16_t				textureheight;
	int8_t				texturename[8];
	int16_t				temp;

	MEMREF textureRef = textures[texnum];

	MEMREF texturecolumnlump = texturecolumnlumpRefs[texnum];
	MEMREF texturecolumnofs = texturecolumnofsRefs[texnum];

	texturecomposite[texnum] = NULL_MEMREF;
	texturecompositesizes[texnum] = 0;




	// Composited texture not created yet.

	texture = (texture_t*)Z_LoadTextureInfoFromConventional(textureRef);
	texturewidth = texture->width + 1;
	textureheight = texture->height + 1;
	memcpy(texturename, texture->name, 8);
	// Now count the number of columns
	//  that are covered by more than one patch.
	// Fill in the lump / offset, so columns
	//  with only a single patch are all done.

	// todo examine alloca use...
	patchcount = (byte *)alloca(texture->width + 1);
	memset(patchcount, 0, texture->width + 1);
	patch = texture->patches;
	texturepatchcount = texture->patchcount;
//	printf("\n%i %hu", texnum, texturepatchcount);
	// 19 11
	// 20 24
	for (i = 0; i < texturepatchcount; i++) {
//		printf(" %i", i);

		texture = (texture_t*)Z_LoadTextureInfoFromConventional(textureRef);
		patch = &texture->patches[i];
		x1 = patch->originx * (patch->patch & ORIGINX_SIGN_FLAG ? -1 : 1);
		patchpatch = patch->patch & PATCHMASK;
		W_CacheLumpNumCheck(patch->patch, 11);
		realpatchRef = W_CacheLumpNumEMS(patch->patch, PU_CACHE);
		realpatch = (patch_t*)Z_LoadBytesFromEMS(realpatchRef);

		x2 = x1 + (realpatch->width);

		if (x1 < 0) {
			x = 0;
		}
		else {
			x = x1;
		}

		if (x2 > texturewidth) {
			x2 = texturewidth;
		}


		for (; x < x2; x++) {
			patchcount[x]++;
			collump = (int16_t*)Z_LoadTextureInfoFromConventional(texturecolumnlump);
			collump[x] = patchpatch;
			realpatch = (patch_t*)Z_LoadBytesFromEMS(realpatchRef);
			temp = (realpatch->columnofs[x - x1]) + 3;
			colofs = (uint16_t*)Z_LoadTextureInfoFromConventional(texturecolumnofs);
			colofs[x] = temp;
		}
	}


	colofs = (uint16_t*)Z_LoadTextureInfoFromConventional(texturecolumnofs);
	collump = (int16_t*)Z_LoadTextureInfoFromConventional(texturecolumnlump);

	//Z_RefIsActive(texturecolumnofs);
	//Z_RefIsActive(texturecolumnlump);
	for (x = 0; x < texturewidth; x++) {

		// 122 TEKWALL3
		// 124 TEKWALL5
		if (!patchcount[x]) {
			DEBUG_PRINT("R_GenerateLookup: column without a patch (%s), %i %i %hhu %hhu\n", texturename, x, texturewidth, texnum, patchcount[x]);
			return;
		}

		if (patchcount[x] > 1) {
			// Use the cached block.
			collump[x] = -1;
			colofs[x] = texturecompositesizes[texnum];

			texturecompositesizes[texnum] += textureheight;
		}
	}
}



//
// R_InitTextures
// Initializes the texture list
//  with the textures from the world map.
//
void R_InitTextures(void)
{
	maptexture_t*       mtexture;
	int16_t				textureRef;
	texture_t*          texture;
	mappatch_t*         mpatch;
	texpatch_t*         patch;

	int16_t                 i;
	int16_t                 j;

	// memory addresses, must stay int_32...
	int32_t*                maptex;
	int32_t*                maptex2;
	int32_t*                maptex1;
	int32_t*                directory;

	int8_t                name[9];
	int8_t*               names;
	int8_t*               name_p;

	int16_t*                patchlookup;

	int16_t                 nummappatches;
	int16_t                 offset;
	int16_t                 maxoff;
	int16_t                 maxoff2;
	int16_t                 numtextures1;
	int16_t                 numtextures2;


	int16_t                 temp1;
	int16_t                 temp2;
	int16_t                 temp3;

	// needed for texture pegging
	//uint8_t*            textureheight;
	MEMREF				namesRef;
	MEMREF				maptexRef;
	MEMREF				maptex2Ref;
	int16_t				texturewidth;
	uint8_t				textureheightval;

	// Load the patch names from pnames.lmp.
	name[8] = 0;
	namesRef = W_CacheLumpNameEMS("PNAMES", PU_STATIC);
	names = Z_LoadBytesFromEMS(namesRef);
	nummappatches = (*((int32_t *)names));
	name_p = names + 4;
	patchlookup = alloca(nummappatches * sizeof(*patchlookup));
	for (i = 0; i < nummappatches; i++)
	{
		strncpy(name, name_p + i * 8, 8);
		patchlookup[i] = W_CheckNumForName(name);
	}
	Z_FreeEMS(namesRef);

	// Load the map texture definitions from textures.lmp.
	// The data is contained in one or two lumps,
	//  TEXTURE1 for shareware, plus TEXTURE2 for commercial.
	maptexRef = W_CacheLumpNameEMS("TEXTURE1", PU_STATIC);
	maptex = maptex1 = Z_LoadBytesFromEMS(maptexRef);
	numtextures1 = (*maptex);

	maxoff = W_LumpLength(W_GetNumForName("TEXTURE1"));
	directory = maptex + 1;


	if (W_CheckNumForName("TEXTURE2") != -1)
	{
		maptex2Ref = W_CacheLumpNameEMS("TEXTURE2", PU_STATIC);
		maptex2 = Z_LoadBytesFromEMS(maptex2Ref);
		numtextures2 = (*maptex2);
		maxoff2 = W_LumpLength(W_GetNumForName("TEXTURE2"));
	}
	else
	{
		maptex2 = NULL;
		numtextures2 = 0;
		maxoff2 = 0;
	}
	numtextures = numtextures1 + numtextures2;
	// 125

	// these are all the very first allocations that occur on level setup and they end up in the same page, 
	// so there is data locality with EMS paging which is nice.



	//  Really complex printing shit...
	temp1 = W_GetNumForName("S_START");  // P_???????
	temp2 = W_GetNumForName("S_END") - 1;
	temp3 = ((temp2 - temp1 + 63) / 64) + ((numtextures + 63) / 64);
#ifdef DEBUG_PRINTING
	printf("[");
	for (i = 0; i < temp3; i++)
		printf(" ");
	printf("         ]");
	for (i = 0; i < temp3; i++)
		printf("\x8");
	printf("\x8\x8\x8\x8\x8\x8\x8\x8\x8\x8");
#endif

	for (i = 0; i < numtextures; i++, directory++)
	{
#ifdef DEBUG_PRINTING
		if (!(i & 63))
			printf(".");
#endif

		if (i == numtextures1)
		{
			// Start looking in second texture file.
			maptex = maptex2;
			maxoff = maxoff2;
			directory = maptex + 1;
		}

		offset = (*directory);


		mtexture = (maptexture_t *)((byte *)maptex + offset);

		textureRef = Z_MallocConventional(sizeof(texture_t)
			+ sizeof(texpatch_t)*((mtexture->patchcount) - 1),
			PU_STATIC, CA_TYPE_TEXTURE_INFO, 0);

		textures[i] = textureRef;

		texture = (texture_t*)Z_LoadTextureInfoFromConventional(textureRef);
		texture->width = (mtexture->width) - 1;
		texture->height = (mtexture->height) - 1;
		texture->patchcount = (mtexture->patchcount);
		texturewidth = texture->width + 1;
		textureheightval = texture->height;

		memcpy(texture->name, mtexture->name, sizeof(texture->name));
		mpatch = &mtexture->patches[0];
		patch = &texture->patches[0];

		for (j = 0; j < texture->patchcount; j++, mpatch++, patch++) {
 
			patch->originx = abs(mpatch->originx);
			patch->originy = (mpatch->originy);
			patch->patch = patchlookup[(mpatch->patch)] + (mpatch->originx < 0 ? 0x8000 : 0);
 

		}


		//printf("name %s", texture->name);
		texturecolumnlumpRefs[i] = Z_MallocConventional(texturewidth * 2, PU_STATIC, CA_TYPE_TEXTURE_INFO, 0);
		texturecolumnofsRefs[i] = Z_MallocConventional(texturewidth * 2, PU_STATIC, CA_TYPE_TEXTURE_INFO, 0);

		j = 1;
		while (j * 2 <= texturewidth)
			j <<= 1;

		texturewidthmasks[i] = j - 1;
		textureheights[i] = textureheightval;


	}


	Z_FreeEMS(maptexRef);
	if (maptex2) {
		Z_FreeEMS(maptex2Ref);
	}
	// Precalculate whatever possible.  
	for (i = 0; i < numtextures; i++)
		R_GenerateLookup(i);

	// Create translation table for global animation.
	

	for (i = 0; i < numtextures; i++)
		texturetranslation[i] = i;

}




void R_InitData(void) {
	uint8_t         i;
	int16_t lump;

	R_InitTextures();
	DEBUG_PRINT(".");

	// R_InitFlats();

	firstflat = W_GetNumForName("F_START") + 1;
	lastflat = W_GetNumForName("F_END") - 1;
	numflats = lastflat - firstflat + 1;

	// Create translation table for global animation.

	for (i = 0; i < numflats; i++)
		flattranslation[i] = i;


	DEBUG_PRINT(".");
	R_InitSpriteLumps();
	DEBUG_PRINT(".");

	// R_InitColormaps();

		// Load in the light tables, 
		//  256 byte align tables.

	Z_QuickmapRender();

	lump = W_GetNumForName("COLORMAP");
	//length = W_LumpLength(lump) + 255;
	colormaps = (byte*)colormapbytes;
	colormaps = (byte *)(((int32_t)colormaps + 255)&~0xff);
	W_ReadLumpStatic(lump, colormaps);

	Z_QuickmapPhysics();

}


extern uint8_t                     detailLevel;
extern uint8_t                     screenblocks;

void R_Init(void)
{
	R_InitData();
	DEBUG_PRINT("..");
	// viewwidth / viewheight / detailLevel are set by the defaults

	R_SetViewSize(screenblocks, detailLevel);
	R_InitPlanes();
	DEBUG_PRINT(".");
	R_InitLightTables();
	DEBUG_PRINT(".");
	R_InitSkyMap();
	DEBUG_PRINT(".");

	}

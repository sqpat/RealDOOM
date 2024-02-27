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
#include "r_state.h"


#include "i_system.h"
#include "doomstat.h"
#include <dos.h>




extern uint8_t			skyflatnum;

 


extern uint8_t R_FlatNumForName(int8_t* name);
//
// R_InitSkyMap
// Called whenever the view size changes.
//
void R_InitSkyMap(void)
{
	skyflatnum = R_FlatNumForName("F_SKY1");
}


//extern MEMREF 				visplanebytesRef[NUM_VISPLANE_PAGES];


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
	/*
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
*/


	//Z_QuickmapPhysics();




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
	Z_QuickmapLumpInfo();

	// Calculate the light levels to use
	//  for each level / distance combination.
	temp.h.fracbits = 0;
	temp2.h.fracbits = 0;
	temp2.h.intbits = SCREENWIDTH / 2;
	for (i = 0; i < LIGHTLEVELS; i++) {
		//DEBUG_PRINT("\n%i ", i);
		startmap = ((LIGHTLEVELS - 1 - i) * 2) * 2; // *NUMCOLORMAPS/LIGHTLEVELS;
		temp.h.intbits = 1;
		for (j = 0; j < MAXLIGHTZ; j++) {
			//DEBUG_PRINT("\n a ");
			temp.h.intbits += 16;

			scale = FixedDivWholeAB(temp2.w, temp.w);
			scale >>= LIGHTSCALESHIFT;
			level = startmap - (scale / DISTMAP);

			if (level < 0) {
				level = 0;
			}

			if (level >= NUMCOLORMAPS) {
				level = NUMCOLORMAPS - 1;
			}

			//DEBUG_PRINT("%i %i %Fp %Fp", i, j, zlight[i *MAXLIGHTZ + j], (colormaps + (level * 256)));

			// << 7 is same as * MAXLIGHTZ
			zlight[i *MAXLIGHTZ + j] = (colormaps + (level * 256));
			//zlight[i * MAXLIGHTZ + j] = (uint16_t)((uint32_t)(colormaps + (level * 256)) & 0xFFFFu);


		}
	}
	Z_QuickmapPhysics();

}



//
// R_InitSpriteLumps
// Finds the width and hoffset of all sprites in the wad,
//  so the sprite does not need to be cached completely
//  just for having the header info ready during rendering.
//
void R_InitSpriteLumps(void)
{
	int16_t         i;

	patch_t      __far*patch;
 	int16_t		patchwidth;
	int16_t		patchleftoffset;
	int16_t		patchtopoffset;

	for (i = 0; i < numspritelumps; i++)
	{
		
#ifdef DEBUG_PRINTING
		if (!(i & 63))
			DEBUG_PRINT(".");
#endif
		Z_QuickmapScratch_5000();

		W_CacheLumpNumDirect(firstspritelump + i, SCRATCH_ADDRESS_5000);
		
		patch = (patch_t __far*)SCRATCH_ADDRESS_5000;
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



static int16_t                 currentlumpindex = 0;
//int16_t texcollump[256];
//
// R_GenerateLookup
//
//todo pull down below?


// complicated memory situation... creating render data at 0x5000-0x6000... lump info will be in 0x4000 range...
// use scratch at 0x7000 which is usually level data. level data is not used during init, only during setup,
// so its technically a free area here. (init is game init, setup is level setup)
void R_GenerateLookup(uint16_t texnum)
{
 

	texture_t __far*          texture;
	texpatch_t __far*         patch;
	patch_t __far*            realpatch;
	int16_t                 x;
	int16_t                 x1;
	int16_t                 x2;
	int16_t                 i;
	int16_t					patchpatch;
	int16_t					lastusedpatch = -1;
	uint8_t				texturepatchcount;
	int16_t				texturewidth;
	int16_t				textureheight;
	
	int16_t				currentcollump;
	int16_t				currentcollumpRLEStart;
	uint16_t __far* addr1;
	//byte patchcountbytes[256];	// 256 enough for doom shareware. maybe 512 for doom ii
	//byte __near *patchcount = patchcountbytes;

	//byte patchcount[256];	// 256 enough for doom shareware. maybe 512 for doom ii


	//byte patchcount[256];

	// rather than alloca or whatever, lets use the scratch page since its already allocated for us...
	// this is startup code so who cares if its slow
	byte __far*					 columnpatchcount = MK_FP(SCRATCH_PAGE_SEGMENT_7000, 0xFB00);
	int16_t __far*               texcollump = MK_FP(SCRATCH_PAGE_SEGMENT_7000, 0xF000);
	// piggyback these local arrays off scratch data...
	int16_t __far*  collump = texturecolumnlumps_bytes;
	uint16_t __far* colofs;
	
	// check which 64k page this lives in
	if (texturecolumn_offset[texnum] >= 0x0800) {
		colofs = (uint16_t __far*)&(texturecolumnofs_bytes_2[(texturecolumn_offset[texnum]-0x0800) << 4]);
	}
	else {
		colofs = (uint16_t __far*)&(texturecolumnofs_bytes_1[texturecolumn_offset[texnum] << 4]);
	}
	
	
	texturepatchlump_offset[texnum] = currentlumpindex;

	//uint8_t currentpatchpage = 0;

	texturecompositesizes[texnum] = 0;

	// Composited texture not created yet.

	texture = (texture_t __far*)&(texturedefs_bytes[texturedefs_offset[texnum]]);
	texturewidth = texture->width + 1;
	textureheight = texture->height + 1;
	// Now count the number of columns
	//  that are covered by more than one patch.
	// Fill in the lump / offset, so columns
	//  with only a single patch are all done.


	// far memset seems to be unreliable... let's just do this
	for (i = 0; i <= texture->width + 1; i++) {
		columnpatchcount[i] = 0;
		texcollump[i] = 0;
	}

	patch = texture->patches;
	texturepatchcount = texture->patchcount;
	realpatch = (patch_t __far*) MK_FP(SCRATCH_PAGE_SEGMENT_7000, 0);
 

	for (i = 0; i < texturepatchcount; i++) {

		patch = &texture->patches[i];
		x1 = patch->originx * (patch->patch & ORIGINX_SIGN_FLAG ? -1 : 1);
		patchpatch = patch->patch & PATCHMASK;
		if (lastusedpatch != patchpatch)
			W_CacheLumpNumDirect(patchpatch, (byte __far*)realpatch);

		lastusedpatch = patchpatch;

		x2 = x1 + (realpatch->width);

		if (x1 < 0) {
			x = 0;
		} else {
			x = x1;
		}

		if (x2 > texturewidth) {
			x2 = texturewidth;
		}

		for (; x < x2; x++) {
			columnpatchcount[x]++;
			texcollump[x] = patchpatch;
			
			// might be an optimization bug? I cant just get the int32_t directly, something gets mangled and suddenly
			// the pointer looks write but the array lookup evaluates wrong. previously working code,  couldn't figure 
			// it out, but broke it down to an explicit pointer calculation and fetched the data and all was good

			addr1 = (uint16_t __far*)&(realpatch->columnofs[x - x1]);
			colofs[x] = *addr1 + 3;
			
		}


	}

	for (x = 0; x < texturewidth; x++) {
 
		if (!columnpatchcount[x]) {
			I_Error("R_GenerateLookup: column without a patch (%Fs), %i %i %hhu %hhu %Fp\n", texture->name, x, texturewidth, texnum, columnpatchcount[x], columnpatchcount);
			return;
		}

		//todo start/stop 
		if (columnpatchcount[x] > 1) {
			// two patches in this column!

			texcollump[x] = -1;
			colofs[x] = texturecompositesizes[texnum];

			texturecompositesizes[texnum] += textureheight;
		}
	}
 

	// Now we generate collump RLE runs

	currentcollump = texcollump[0];
	currentcollumpRLEStart = 0;

	// write collumps data. Needs to be done here, so that we've accounted for multiple-patch cases with patchcount[x] > 1
	for (x = 1; x < texturewidth; x++) {
		if (currentcollump != texcollump[x]) {
			collump[currentlumpindex] = currentcollump;
			collump[currentlumpindex + 1] = x - currentcollumpRLEStart;

			currentcollumpRLEStart = x;
			currentcollump = texcollump[x];
			currentlumpindex += 2;
				

		}
	}
	collump[currentlumpindex] = currentcollump;
	collump[currentlumpindex + 1] = texturewidth - currentcollumpRLEStart;
	currentlumpindex += 2;

}

#define TEX_LOAD_ADDRESS (byte __far*) (0x70000000)

//
// R_InitTextures
// Initializes the texture list
//  with the textures from the world map.
//
void R_InitTextures(void)
{
	maptexture_t __far*       mtexture;
	texture_t __far*          texture;
	mappatch_t __far*         mpatch;
	texpatch_t __far*         patch;

	int16_t                 i;
	int16_t                 j;

	// memory addresses, must stay int_32...
	int32_t __far*                maptex;
	int32_t __far*                maptex2;
	int32_t __far*                maptex1;
	int32_t __far*                directory;

	int8_t                name[9];
 	int8_t __far*               name_p;

	int16_t                 nummappatches;
	int16_t                 offset;
	int16_t                 numtextures1;
	int16_t                 numtextures2;


	int16_t                 temp1;
	int16_t                 temp2;
	int16_t                 temp3;

	// needed for texture pegging
	//uint8_t*            textureheight;
 	int16_t				texturewidth;
	uint8_t				textureheightval;
	int16_t                patchlookup[470]; // 350 for doom shareware/doom1. 459 for doom2

 	texturedefs_offset[0] = 0;
	texturecolumn_offset[0] = 0;


	firstpatch = W_GetNumForName("P_START") + 1;
	lastpatch = W_GetNumForName("P_END") - 1;
	numpatches = lastpatch - firstpatch + 1;

	firstflat = W_GetNumForName("F_START") + 1;
	lastflat = W_GetNumForName("F_END") - 1;
	numflats = lastflat - firstflat + 1;

	firstspritelump = W_GetNumForName("S_START") + 1;
	lastspritelump = W_GetNumForName("S_END") - 1;
	numspritelumps = lastspritelump - firstspritelump + 1;



	// Load the patch names from pnames.lmp.
	name[8] = 0;
 	W_CacheLumpNameDirect("PNAMES", (byte __far*)TEX_LOAD_ADDRESS);
	nummappatches = (*((int32_t  __far*)TEX_LOAD_ADDRESS));
	name_p = (int8_t __far*)(TEX_LOAD_ADDRESS + 4);
	for (i = 0; i < nummappatches; i++)
	{
		FAR_strncpy(name, name_p + i * 8, 8);
		patchlookup[i] = W_CheckNumForName(name);
	}

	// Load the map texture definitions from textures.lmp.
	// The data is contained in one or two lumps,
	//  TEXTURE1 for shareware, plus TEXTURE2 for commercial.
	maptex = maptex1 = (int32_t __far*)TEX_LOAD_ADDRESS;
	W_CacheLumpNameDirect("TEXTURE1", (byte __far*)maptex);

	numtextures1 = (*maptex);
	directory = maptex + 1;


	if (W_CheckNumForName("TEXTURE2") != -1)
	{
		maptex2 = ((int32_t __far*)TEX_LOAD_ADDRESS) + 0x8000u;
		W_CacheLumpNameDirect("TEXTURE2", (byte __far*)maptex2);
		numtextures2 = (*maptex2);
	}
	else
	{
		maptex2 = NULL;
		numtextures2 = 0;
	}
	numtextures = numtextures1 + numtextures2;



	//  Really complex printing shit...
	temp1 = W_GetNumForName("S_START");  // P_???????
	temp2 = W_GetNumForName("S_END") - 1;
	temp3 = ((temp2 - temp1 + 63) / 64) + ((numtextures + 63) / 64);
	DEBUG_PRINT("[");
	for (i = 0; i < temp3; i++)
		DEBUG_PRINT(" ");
	DEBUG_PRINT("         ]");
	for (i = 0; i < temp3; i++)
		DEBUG_PRINT("\x8");
	DEBUG_PRINT("\x8\x8\x8\x8\x8\x8\x8\x8\x8\x8");
	
	for (i = 0; i < numtextures; i++, directory++) {
		if (!(i & 63))
			DEBUG_PRINT(".");

		if (i == numtextures1) {
			// Start looking in second texture file.
			maptex = maptex2;
			directory = maptex + 1;
		}

		offset = (*directory);


		//mtexture = (maptexture_t  __far*)((byte  __far*)(maptex + offset));
		mtexture = (maptexture_t  __far*)((byte  __far*)maptex + offset);

		if ((i + 1) < numtextures) {
			texturedefs_offset[i + 1] = texturedefs_offset[i] + (sizeof(texture_t) + sizeof(texpatch_t)*((mtexture->patchcount) - 1));
		}


		texture = (texture_t __far*)&(texturedefs_bytes[texturedefs_offset[i]]);
		texture->width = (mtexture->width) - 1;
		texture->height = (mtexture->height) - 1;
		texture->patchcount = (mtexture->patchcount);
		texturewidth = texture->width + 1;
		textureheightval = texture->height; 

		FAR_memcpy(texture->name, mtexture->name, sizeof(texture->name));
		//FAR_strncpy(name, mtexture->name, 8);

		//if ((i % 4) == 0)DEBUG_PRINT("\n");
		//DEBUG_PRINT(" %i %lx %lx", i, texture, mtexture);

		//DEBUG_PRINT("\n %.8Fs %.8Fs %i %Fp %Fp", texture->name, mtexture->name, sizeof(texture->name), texture->name, mtexture->name);
		mpatch = &mtexture->patches[0];
		patch = &texture->patches[0];

		for (j = 0; j < texture->patchcount; j++, mpatch++, patch++) {

			patch->originx = abs(mpatch->originx);
			patch->originy = (mpatch->originy);
			patch->patch = patchlookup[(mpatch->patch)] + (mpatch->originx < 0 ? 0x8000 : 0);
 

		}

		//DEBUG_PRINT("name %Fs", texture->name);

		if ((i + 1) < numtextures) {
			// we store by paragraphs to fit this in 2 bytes per entry for doom2 
			// (which goes into 80kish size for this struct) and because all 
			// the offsets are multiples of a word in size anyway due to texturewidth
			// being multiples of 8 and multiplied by sizeof(int16_t) which is 2
 
			texturecolumn_offset[i + 1] = texturecolumn_offset[i] + ((texturewidth * sizeof(int16_t)) >> 4 ) ;
 		}

		j = 1;
		while (j * 2 <= texturewidth)
			j <<= 1;

		texturewidthmasks[i] = j - 1;
		textureheights[i] = textureheightval;


	}
	//DUMP_MEMORY_TO_FILE();

	// Create translation table for global animation.
	for (i = 0; i < numtextures; i++)
		texturetranslation[i] = i;
	 
	// Precalculate whatever possible.  
	// done using 7000 above ?
	Z_QuickmapScratch_7000();
	for (i = 0; i < numtextures; i++){
		R_GenerateLookup(i);
	}

	// Reset this since 0x7000 scratch page is active
	Z_QuickmapRender();

	//I_Error("final size: %i", currentlumpindex);

}

/*
// Preload all patches - i dont think we actually need this...
void R_InitPatches() {


	int16_t temp1 = W_GetNumForName("P1_START");  // P_???????
	int16_t temp2 = W_GetNumForName("P_END") - 1;
	int16_t i, j;
		
	int16_t currentpatchpage = 0;
	uint16_t size;
	uint8_t newpage = 0;
	uint8_t oldpage = 0;
	fixed_t_union totalsize;
	totalsize.wu = 0;
	// todo set dynamically..
	//NUM_PATCH_LUMPS = temp2 - temp1;


	Z_PushScratchFrame();

	for (i = 0; i < NUM_PATCH_LUMPS; i++) {
		int16_t lumpnum = i + FIRST_PATCH;
		size = W_LumpLength(lumpnum);

		patchpage[i] = oldpage = newpage;
		patchoffset[i] = totalsize.hu.intbits & 16383;
		totalsize.wu += size;
		newpage = totalsize.wu >> 14;
		// do we need to re-set the offset?
		if (newpage - oldpage > 3 ) {
			// re-base on oldpage

			Z_RemapScratchFrame(FIRST_PATCH_CACHE_LOGICAL_PAGE + oldpage)
			currentpatchpage = oldpage;
		}
		
		W_CacheLumpNumDirect(lumpnum, MK_FP(SCRATCH_PAGE_SEGMENT, pageoffsets[oldpage] + patchoffset[i] ));
		// todo bounds check?
	}

	Z_PopScratchFrame();



}
*/

void R_InitData(void) {
	uint8_t         i;
	int16_t lump;

	//R_InitPatches();

	R_InitTextures();
	DEBUG_PRINT(".");


	// Create translation table for global animation.

	for (i = 0; i < numflats; i++)
		flattranslation[i] = i;



	// R_InitColormaps();

		// Load in the light tables, 
		//  256 byte align tables.


	DEBUG_PRINT(".");
	R_InitSpriteLumps();
	DEBUG_PRINT(".");

	lump = W_GetNumForName("COLORMAP");
	//length = W_LumpLength(lump) + 255;
	//colormaps = (byte __far*)colormapbytes;
	//colormaps = (byte  __far*)(((int32_t)colormaps + 255)&~0xff);
	W_CacheLumpNumDirect(lump, colormaps);

 
}


extern uint8_t                     detailLevel;
extern uint8_t                     screenblocks;

void R_Init(void)
{
	Z_QuickmapRender();
	Z_QuickmapLumpInfo();
	//Z_QuickmapTextureInfoPage();
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

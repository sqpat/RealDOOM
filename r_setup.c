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


#include "doomdef.h"
#include "d_net.h"

#include "m_misc.h"

#include "r_local.h"
#include "p_local.h"


#include "i_system.h"
#include "doomstat.h"
#include "tables.h"
#include "w_wad.h"
#include <alloca.h>
#include <dos.h>

#define DISTMAP		2
#define FIELDOFVIEW		2048	


// ?
#define MAXWIDTH			320
#define MAXHEIGHT			200

// status bar height at bottom of screen
#define SBARHEIGHT		32

extern int16_t		columnofs[MAXWIDTH];
extern boolean setsizeneeded;
extern uint8_t		setblocks;
extern uint8_t		setdetail;

//
// R_InitBuffer 
// Creats lookup tables that avoid
//  multiplies and other hazzles
//  for getting the framebuffer address
//  of a pixel to draw.
//
void
R_InitBuffer
(int16_t		width,
	int16_t		height)
{
	int16_t		i;

	// Handle resize,
	//  e.g. smaller view windows
	//  with border and/or status bar.
	viewwindowx = (SCREENWIDTH - width) >> 1;

	// Column offset. For windows.
	for (i = 0; i < width; i++)
		columnofs[i] = viewwindowx + i;

	// Samw with base row offset.
	if (width == SCREENWIDTH)
		viewwindowy = 0;
	else
		viewwindowy = (SCREENHEIGHT - SBARHEIGHT - height) >> 1;

	viewwindowoffset = (viewwindowy*SCREENWIDTH / 4) + (viewwindowx >> 2);
}



//
// R_InitTextureMapping
//
void R_InitTextureMapping(void)
{
	int16_t			x;
	fixed_t_union	t;
	fixed_t		focallength;
	fixed_t_union		temp;
	fixed_t	cosadj;
	fineangle_t	an;
	int8_t		level;
	fixed_t	dy;
	int16_t		i;
	int16_t		j;
	Z_QuickmapRender();

	// Use tangent table to generate viewangletox:
	//  viewangletox will give the next greatest x
	//  after the view angle.
	//
	// Calc focallength
	//  so FIELDOFVIEW angles covers SCREENWIDTH.
	focallength = FixedDivWholeA(centerxfrac.w,
		finetangent(FINEANGLES / 4 + FIELDOFVIEW / 2));

	for (i = 0; i < FINEANGLES / 2; i++) {
		if (finetangent(i) > FRACUNIT * 2)
			t.h.intbits = -1;
		else if (finetangent(i) < -FRACUNIT * 2)
			t.h.intbits = viewwidth + 1;
		else {
			t.w = FixedMul(finetangent(i), focallength);
			//todo optimize given centerxfrac low bits are 0
			t.w = (centerxfrac.w - t.w + 0xFFFFu);

			if (t.h.intbits < -1)
				t.h.intbits = -1;
			else if (t.h.intbits > viewwidth + 1)
				t.h.intbits = viewwidth + 1;
		}
		viewangletox[i] = t.h.intbits;
	}

	// Scan viewangletox[] to generate xtoviewangle[]:
	//  xtoviewangle will give the smallest view angle
	//  that maps to x.	
	for (x = 0; x <= viewwidth; x++) {
		i = 0;
		while (viewangletox[i] > x)
			i++;
		xtoviewangle[x] = MOD_FINE_ANGLE((i)-FINE_ANG90);
	}

	// Take out the fencepost cases from viewangletox.
	for (i = 0; i < FINEANGLES / 2; i++)
	{
		// am i blind or is t unused here?
		t.w = FixedMul(finetangent(i), focallength);
		t.w = centerx - t.w;

		if (viewangletox[i] == -1)
			viewangletox[i] = 0;
		else if (viewangletox[i] == viewwidth + 1)
			viewangletox[i] = viewwidth;
	}

	clipangle.hu.intbits = xtoviewangle[0] << 3;
	fieldofview.hu.intbits = 2 * clipangle.hu.intbits;


	// psprite scales
	if (viewwidth == SCREENWIDTH) {
		// will be specialcased as 1 later;
		pspritescale = 0;
		pspriteiscale = FRACUNIT;
	}
	else {
		// max of FRACUNIT, we set it to 0 in that case
		pspritescale = (FRACUNIT * viewwidth / SCREENWIDTH);
		pspriteiscale = (FRACUNIT * SCREENWIDTH / viewwidth);
	}

	// thing clipping
	for (i = 0; i < viewwidth; i++) {
		screenheightarray[i] = viewheight;
	}

	// 168 viewheight
	// planes


	for (i = 0; i < viewheight; i++) {
		temp.h.intbits = (i - viewheight / 2);
		dy = (temp.w) + 0x8000u;
		dy = labs(dy);
		temp.h.intbits = (viewwidth << detailshift) / 2;
		yslope[i] = FixedDivWholeA(temp.w, dy);

	}
	// 320 viewwidth

	for (i = 0; i < viewwidth; i++) {
		an = xtoviewangle[i];
		cosadj = labs(finecosine[an]);
		distscale[i] = FixedDivWholeA(FRACUNIT, cosadj);
	}



	// Calculate the light levels to use
	//  for each level / scale combination.
	for (i = 0; i < LIGHTLEVELS; i++) {
		startmap = ((LIGHTLEVELS - 1 - i) * 2)*NUMCOLORMAPS / LIGHTLEVELS;
		for (j = 0; j < MAXLIGHTSCALE; j++) {
			level = startmap - j * SCREENWIDTH / (viewwidth << detailshift) / DISTMAP;

			if (level < 0) {
				level = 0;
			}

			if (level >= NUMCOLORMAPS) {
				level = NUMCOLORMAPS - 1;
			}

			scalelight[i*MAXLIGHTSCALE+j] = colormaps + level * 256;
		}
	}

	Z_QuickmapPhysics();

}



//
// R_ExecuteSetViewSize
//
void R_ExecuteSetViewSize(void)
{

	int8_t		startmap;
	fixed_t_union temp;
	temp.h.fracbits = 0;
	setsizeneeded = false;

	if (setblocks == 11) {
		scaledviewwidth = SCREENWIDTH;
		viewheight = SCREENHEIGHT;
	}
	else {
		scaledviewwidth = setblocks * 32;
		viewheight = (setblocks * 168 / 10)&~7;
	}

	detailshift = setdetail;
	viewwidth = scaledviewwidth >> detailshift;

	centery = viewheight >> 1;
	centerx = viewwidth >> 1;
	temp.h.intbits = centerx;
	projection = centerxfrac = temp; // todo: calculate (or fetch) magic number from stored cache, to be used in R_ProjectSprite
	temp.h.intbits = centery;
	centeryfrac = temp;
	centeryfrac_shiftright4.w = temp.w >> 4;

	if (!detailshift) {
		colfunc = basecolfunc = R_DrawColumn;
		fuzzcolfunc = R_DrawFuzzColumn;
		spanfunc = R_DrawSpan;
	}
	else {
		colfunc = basecolfunc = R_DrawColumnLow;
		fuzzcolfunc = R_DrawFuzzColumn;
		spanfunc = R_DrawSpanLow;
	}

	R_InitBuffer(scaledviewwidth, viewheight);

	R_InitTextureMapping();


 
}

 


//
// R_PrecacheLevel
// Preloads all relevant graphics for the level.
//
//int32_t             flatmemory;
//int32_t             texturememory;
//int32_t             spritememory;


extern uint8_t firstunusedflat;
extern int32_t totalpatchsize;
 
extern int8_t textureLRU[4];
extern int16_t activetexturepages[4];
extern byte*	 spritedefs_bytes;


void R_PrecacheLevel(void)
{
	int8_t*               flatpresent;
	int8_t*               texturepresent;
	int8_t*               spritepresent;

	int16_t                 i;
	int16_t                 j;
	int16_t                 k;
	int16_t                 lump;

	texture_t*          texture;
	THINKERREF          th;
	spriteframe_t*      sf;
	spriteframe_t*		spriteframes;
	int32_t flatsize = 0;
	int32_t spritesize = 0;
	uint16_t size;
	uint8_t currentpageoffset = 0;
	int16_t lumpnum;
	int16_t currentpatchpage = 0;
	uint8_t newpage = 0;
	uint8_t oldpage = 0;
	int16_t index;

	if (demoplayback)
		return;
	return;
	Z_QuickmapRender();
	


	// Precache flats.
	flatpresent = alloca(numflats);
	memset(flatpresent, 0, numflats);
	// numflats 56	

	for (i = 0; i < numsectors; i++)
	{
		flatpresent[sectors[i].floorpic] = 1;
		flatpresent[sectors[i].ceilingpic] = 1;
	}

	//flatmemory = 0;
	Z_PushScratchFrame();


	Z_RemapScratchFrame(FIRST_FLAT_CACHE_LOGICAL_PAGE);
	
  	for (i = 0; i < numflats; i++)
	{
 
		if (flatpresent[i]) {
			lump = firstflat + i;
			//size = 4096; // W_LumpLength(lump);

			flatindex[i] = firstunusedflat;
			//totalsize += size;

			if (firstunusedflat && (firstunusedflat % 16) == 0) {
				// remap page
				Z_RemapScratchFrame(FIRST_FLAT_CACHE_LOGICAL_PAGE + firstunusedflat / 16);
			}

			W_CacheLumpNumDirect(lump, MK_FP(SCRATCH_PAGE_SEGMENT, pageoffsets[(firstunusedflat % 16) >> 2] + MULT_4096[firstunusedflat & 0x03]));
			firstunusedflat++;
			if (firstunusedflat > MAX_FLATS_LOADED) {
				I_Error("Too many flats!");
			}

		}
	}
	Z_PopScratchFrame();

	flatsize = 4096 * firstunusedflat;
	oldpage = newpage = 0;

	// Precache textures.
	texturepresent = alloca(numtextures);
	memset(texturepresent, 0, numtextures);
	for (i = 0; i < numsides; i++)
	{

		texturepresent[sides[i].toptexture] = 1;
		texturepresent[sides[i].midtexture] = 1;
		texturepresent[sides[i].bottomtexture] = 1;
	}

	// Sky texture is always present.
	// Note that F_SKY1 is the name used to
	//  indicate a sky floor/ceiling as a flat,
	//  while the sky texture is stored like
	//  a wall texture, with an episode dependend
	//  name.
	texturepresent[skytexture] = 1;

	// texturememory = 0;
 
	// this caches all used patches but not textures
	for (i = 0; i < numtextures; i++) {

		if (!texturepresent[i])
			continue;

		gettexture(i, TEXTURE_TYPE_COMPOSITE);
		for (j = 0; j < texture->patchcount; j++) {
			lump = texture->patches[j].patch;
			gettexture(lump, TEXTURE_TYPE_LUMP);
		}

		/*
		// todo does this have to be done here?
		//R_GenerateComposite();

		texture = (texture_t*)Z_LoadTextureInfoFromConventional(textures[i]);
		for (j = 0; j < texture->patchcount; j++) {

			lump = texture->patches[j].patch;
			index = lump - FIRST_PATCH;

			// check for lump presence...
			if (patchpage[index] == 0xFF) {
				size = W_LumpLength(lump);
				totalsize += size;

				patchpage[index] = oldpage = newpage;
				patchoffset[index] = totalsize & 16383;
				newpage = totalsize >> 14;


				// do we need to re-set the offset?
				if (newpage - oldpage > 3) {
					// re-base on oldpage
					Z_RemapScratchFrame(FIRST_PATCH_CACHE_LOGICAL_PAGE + oldpage);
					currentpatchpage = oldpage;
				}
				W_CacheLumpNumDirect(lump, MK_FP(SCRATCH_PAGE_SEGMENT, pageoffsets[oldpage] + patchoffset[index]));

			}


		}
		*/
	}


	// Precache sprites.
	spritepresent = alloca(numsprites);
	memset(spritepresent, 0, numsprites);

	for (th = thinkerlist[0].next; th != 0; th = thinkerlist[th].next)
	{
		if ((thinkerlist[th].prevFunctype & TF_FUNCBITS) == TF_MOBJTHINKER_HIGHBITS) {
			spritepresent[ states[mobjposlist[th].stateNum].sprite ] = 1;
		}
	}
	Z_QuickmapPhysics();


	for (i = 0; i < numsprites; i++) {
		if (!spritepresent[i])
			continue;

 		spriteframes = (spriteframe_t*)&(spritedefs_bytes[sprites[i].spriteframesOffset]);

		for (j = 0; j < sprites[i].numframes; j++) {
			sf = &spriteframes[j];
			for (k = 0; k < 8; k++) {
				lump = firstspritelump + sf->lump[k];
				//spritesize += W_LumpLength(lump);
				getspritetexture(lump);
			}
		}
	}

	/*
	for (i = 0; i < NUM_TEXTURE_PAGES; i++) 
		if (usedcompositetexturepagemem[i] == 0)
			break;
	I_Error("\ntotal tex size %li\n flat size %li \nspritesize %li", i * 16384L, flatsize, spritesize);
		*/
	
	



	//       TEX    FLAT    SPRITE
	// E1M1 492064  86016
	//      163840
	// E1M2 869332 110592
	//      229376 
	// E1M3			90112
	//      294912
	// E1M4 
	//      229376  106496
	// E1M5         114688
	//      245760  
	// E1M6 587136 110592
	//      180224
	// E1M7 545544 86016
	//      163840
	// E1M8		   81920
	//      262144
	// E1M9 245392 57344



}


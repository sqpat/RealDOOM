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
//      Preparation of data for rendering,
//      generation of lookups, caching, retrieval by name.
//

#include "i_system.h"
#include "z_zone.h"

#include "w_wad.h"

#include "doomdef.h"
#include "r_local.h"
#include "p_local.h"

#include "doomstat.h"
#include "r_data.h"

//
// Graphics.
// DOOM graphics for walls and sprites
// is stored in vertical runs of opaque pixels (posts).
// A column is composed of zero or more posts,
// a patch or sprite is composed of zero or more columns.
// 





// A single patch from a texture definition,
//  basically a rectangular area within
//  the texture rectangle.
typedef struct
{
	// Block origin (allways UL),
	// which has allready accounted
	// for the internal origin of the patch.
	int16_t         originx;
	int16_t         originy;
	int16_t         patch; // lump num
} texpatch_t;


// A maptexturedef_t describes a rectangular texture,
//  which is composed of one or more mappatch_t structures
//  that arrange graphic patches.
typedef struct
{
	// Keep name for switch changing, etc.
	int8_t        name[8];
	// width and height max out at 256 and are never 0. we store as real size -  1 and add 1 whenever we readd it
	uint8_t       width;
	uint8_t       height;

	// All the patches[patchcount]
	//  are drawn back to front into the cached texture.
	uint8_t       patchcount;
	texpatch_t  patches[1];

} texture_t;


MEMREF lockedRef;

int16_t             firstflat;
int16_t             lastflat;
int16_t             numflats;

int16_t             firstpatch;
int16_t             lastpatch;
int16_t             numpatches;

int16_t             firstspritelump;
int16_t             lastspritelump;
int16_t             numspritelumps;

int16_t             numtextures;
//texture_t**   textures;



MEMREF textures[NUM_TEXTURE_CACHE];  // lists of MEMREFs kind of suck, this takes up relatively little memory and prevents lots of allocations;
MEMREF texturecomposite[NUM_TEXTURE_CACHE];  // see above


MEMREF texturecolumnlumpRefs[NUM_TEXTURE_CACHE];
MEMREF texturecolumnofsRefs[NUM_TEXTURE_CACHE];


uint8_t  texturewidthmasks[NUM_TEXTURE_CACHE];
// needed for texture pegging
uint8_t  textureheights[NUM_TEXTURE_CACHE];		    // uint8_t must be converted by fracbits when used*
uint16_t  texturecompositesizes[NUM_TEXTURE_CACHE];	// uint16_t*


 


// for global animation
uint8_t			flattranslation[NUM_TEXTURE_CACHE]; // can almost certainly be smaller
uint8_t			texturetranslation[NUM_TEXTURE_CACHE];

// needed for pre rendering
int16_t        spritewidths[NUM_SPRITE_LUMPS_CACHE];
int16_t        spriteoffsets[NUM_SPRITE_LUMPS_CACHE];
int16_t        spritetopoffsets[NUM_SPRITE_LUMPS_CACHE];

byte         	colormapbytes[(33 * 256) + 255];
lighttable_t    *colormaps;


//
// MAPTEXTURE_T CACHING
// When a texture is first needed,
//  it counts the number of composite columns
//  required in the texture and allocates space
//  for a column directory and any new columns.
// The directory will simply point inside other patches
//  if there is only one patch in a given column,
//  but any columns with multiple patches
//  will have new column_ts generated.
//



//
// R_DrawColumnInCache
// Clip and draw a column
//  from a patch into a cached post.
//
void
R_DrawColumnInCache
(column_t*     patch,
	byte*       cache,
	int16_t     originy,
	int16_t     cacheheight)
{
	int16_t     count;
	int16_t     position;
	byte*       source;
	byte*       dest;
	dest = (byte *)cache + 3;

	while (patch->topdelta != 0xff)
	{ 

		source = (byte *)patch + 3;
		count = patch->length;
		position = originy + patch->topdelta;

		if (position < 0)
		{
			count += position;
			position = 0;
		}

		if (position + count > cacheheight)
			count = cacheheight - position;

		if (count > 0)
			memcpy(cache + position, source, count);

		patch = (column_t *)((byte *)patch + patch->length + 4);
	}
}



//
// R_GenerateComposite
// Using the texture definition,
//  the composite texture is created from the patches,
//  and each column is cached.
//
void R_GenerateComposite(uint8_t texnum)
{
	byte*               block;
	texpatch_t*         patch;
	patch_t*            realpatch;
	int16_t             x;
	int16_t             x1;
	int16_t             x2;
	int16_t             i;
	column_t*           patchcol;
	int16_t*            collump;
	uint16_t*			colofs;
	MEMREF				realpatchRef;
	int16_t				textureheight;
	int16_t				texturewidth;
	uint8_t				texturepatchcount;
	int16_t				patchpatch;
	int16_t				patchoriginx;
	int16_t				patchoriginy;
	texture_t* texture;
	int16_t				colofsx;



	MEMREF texturecolumnlumptexnum = texturecolumnlumpRefs[texnum];
	MEMREF texturecolumnofstexnum = texturecolumnofsRefs[texnum];
	MEMREF texturecompositetexnum;
	uint16_t texturecompositesize = texturecompositesizes[texnum];

	MEMREF texturememref = textures[texnum];


	texturecomposite[texnum] = Z_MallocEMSWithBackRef(texturecompositesize,
		PU_STATIC,
		0xff, ALLOC_TYPE_TEXTURE + 160, texnum+1);
	texturecompositetexnum = texturecomposite[texnum];

#if NUM_EMS_PAGES >= 8
	texture = (texture_t*)Z_LoadBytesFromConventionalWithOptions(texturememref, PAGE_LOCKED, CA_TYPE_TEXTURE_INFO);
	block = (byte*)Z_LoadBytesFromEMSWithOptions(texturecompositetexnum, PAGE_LOCKED);
	collump = (int16_t*)Z_LoadBytesFromConventionalWithOptions(texturecolumnlumptexnum, PAGE_LOCKED, CA_TYPE_TEXTURE_INFO);
	colofs = (uint16_t*)Z_LoadBytesFromConventionalWithOptions(texturecolumnofstexnum, PAGE_LOCKED, CA_TYPE_TEXTURE_INFO);
#else
	texture = (texture_t*)Z_LoadTextureInfoFromConventional(texturememref);

#endif



	texturewidth = texture->width + 1;
	textureheight = texture->height + 1;
	texturepatchcount = texture->patchcount;

	// Composite the columns together.

	for (i = 0; i < texturepatchcount; i++) {


#if NUM_EMS_PAGES < 8
		texture = (texture_t*)Z_LoadTextureInfoFromConventional(texturememref);
#endif
		patch = &texture->patches[i];
		patchpatch = patch->patch;
		patchoriginx = patch->originx;
		patchoriginy = patch->originy;

		W_CacheLumpNumCheck(patchpatch, 10);
		realpatchRef = W_CacheLumpNumEMS(patchpatch, PU_CACHE);

#if NUM_EMS_PAGES >= 8
		realpatch = (patch_t*)Z_LoadBytesFromEMSWithOptions(realpatchRef, PAGE_LOCKED);
#else
		realpatch = (patch_t*)Z_LoadBytesFromEMS(realpatchRef);

#endif


		x1 = patchoriginx;
		x2 = x1 + (realpatch->width);

		if (x1 < 0)
			x = 0;
		else
			x = x1;

		if (x2 > texturewidth)
			x2 = texturewidth;




		for (; x < x2; x++) {
			// seems ok. if this ever barks up, we can bring the above Z_LoadBytesFromEMS calls down into one of these loops

#if NUM_EMS_PAGES < 8
			collump = (int16_t*)Z_LoadTextureInfoFromConventional(texturecolumnlumptexnum);
#endif
			// Column does not have multiple patches?
			if (collump[x] >= 0)
				continue;
#if NUM_EMS_PAGES < 8

			colofs = (uint16_t*)Z_LoadTextureInfoFromConventional(texturecolumnofstexnum);
			colofsx = colofs[x];

			realpatch = (patch_t*)Z_LoadBytesFromEMSWithOptions(realpatchRef, PAGE_LOCKED);
			patchcol = (column_t *)((byte *)realpatch + (realpatch->columnofs[x - x1]));
			block = (byte*)Z_LoadBytesFromEMS(texturecompositetexnum);
			R_DrawColumnInCache(patchcol,
				block + colofsx,
				patchoriginy,
				textureheight);
			Z_SetUnlocked(realpatchRef);

#else 
			patchcol = (column_t *)((byte *)realpatch + (realpatch->columnofs[x - x1]));
			R_DrawColumnInCache(patchcol,
				block + colofs[x],
				patchoriginy,
				textureheight);
#endif





		}


#if NUM_EMS_PAGES >= 8
		Z_SetUnlocked(realpatchRef);

#endif	


	}

#if NUM_EMS_PAGES >= 8

	Z_SetUnlocked(texturecolumnofstexnum);
	Z_SetUnlocked(texturecompositetexnum);
	Z_SetUnlocked(texturememref);
	Z_SetUnlocked(texturecolumnlumptexnum);

#else

#endif


	// Now that the texture has been built in column cache,
	//  it is purgable from zone memory.

	// TODO: if we free this and the texture handle is still active that's bad?
	Z_ChangeTagEMS(texturecompositetexnum, PU_CACHE);
}




//
// R_GetColumn
//
// USUALLY PAGE 0 IS locked
byte*
R_GetColumn
(int16_t           tex,
	int16_t           col)
{
	int16_t         lump; 
	uint16_t         ofs; 
	int16_t* texturecolumnlump; 
	uint16_t* texturecolumnofs;
	MEMREF columnRef;

	byte* texturecompositebytes;
	byte* returnval;

	// reordered to require fewer things in memory at same time
	col &= texturewidthmasks[tex];

	texturecolumnofs = (uint16_t*)Z_LoadTextureInfoFromConventional(texturecolumnofsRefs[tex]);
	ofs = texturecolumnofs[col];
	

	texturecolumnlump = (int16_t*)Z_LoadTextureInfoFromConventional(texturecolumnlumpRefs[tex]);
	lump = texturecolumnlump[col];

	if (lump > 0) {
		W_CacheLumpNumCheck(lump, 12);
		//return (byte *)W_CacheLumpNum(lump, PU_CACHE) + ofs;
		columnRef = W_CacheLumpNumEMS(lump, PU_CACHE);
		lockedRef = columnRef;
		returnval = (byte*)Z_LoadBytesFromEMS(columnRef) + ofs;
		//Z_SetUnlocked(lockedRef);
		return returnval;

	}


	if (texturecomposite[tex] == NULL_MEMREF) {
		R_GenerateComposite(tex);
	}

	texturecompositebytes = (byte*)Z_LoadBytesFromEMS(texturecomposite[tex]);
	lockedRef = texturecomposite[tex];
	//Z_SetUnlocked(lockedRef);
	return texturecompositebytes + ofs;
}





//





void R_EraseCompositeCache(uint8_t texnum) {

	// todo are we calling this with 0 all the time?

	texturecomposite[texnum] = NULL_MEMREF;
}


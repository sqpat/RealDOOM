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
#include "r_sky.h"

#include  <alloca.h>


#include "r_data.h"

//
// Graphics.
// DOOM graphics for walls and sprites
// is stored in vertical runs of opaque pixels (posts).
// A column is composed of zero or more posts,
// a patch or sprite is composed of zero or more columns.
// 



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
	int8_t                name[8];
	boolean             masked;
	int16_t               width;
	int16_t               height;
	void                **columndirectory;      // OBSOLETE
	int16_t               patchcount;
	mappatch_t  patches[1];
} maptexture_t;


// A single patch from a texture definition,
//  basically a rectangular area within
//  the texture rectangle.
typedef struct
{
	// Block origin (allways UL),
	// which has allready accounted
	// for the internal origin of the patch.
	int32_t         originx;
	int32_t         originy;
	int32_t         patch;
} texpatch_t;


// A maptexturedef_t describes a rectangular texture,
//  which is composed of one or more mappatch_t structures
//  that arrange graphic patches.
typedef struct
{
	// Keep name for switch changing, etc.
	int8_t        name[8];
	int16_t       width;
	int16_t       height;

	// All the patches[patchcount]
	//  are drawn back to front into the cached texture.
	int16_t       patchcount;
	texpatch_t  patches[1];

} texture_t;



int32_t             firstflat;
int32_t             lastflat;
int32_t             numflats;

int32_t             firstpatch;
int32_t             lastpatch;
int32_t             numpatches;

int32_t             firstspritelump;
int32_t             lastspritelump;
int32_t             numspritelumps;

int32_t             numtextures;
//texture_t**   textures;

MEMREF  texturesRef;				// texture_t**

MEMREF  texturewidthmaskRef;		// int32_t*
// needed for texture pegging
MEMREF  textureheightRef;		    // fixed_t*
MEMREF  texturecompositesizeRef;	// int32_t*
MEMREF  texturecolumnlumpRef;		// int16_t**
MEMREF	texturecolumnofsRef;		// uint16_t **
MEMREF  texturecompositeRef;        // byte**



/*
int32_t*                    texturewidthmask;
// needed for texture pegging
fixed_t*                textureheight;
int32_t*                    texturecompositesize;
int16_t**                 texturecolumnlump;
uint16_t**        texturecolumnofs;
byte**                  texturecomposite;
*/





// for global animation
MEMREF            flattranslationRef;
MEMREF            texturetranslationRef;

// needed for pre rendering
MEMREF        spritewidthRef;
MEMREF        spriteoffsetRef;
MEMREF        spritetopoffsetRef;

byte*         colormapbytes[8959];
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
	byte*         cache,
	int32_t           originy,
	int32_t           cacheheight)
{
	int32_t         count;
	int32_t         position;
	byte*       source;
	byte*       dest;
	int32_t i = 0;
	dest = (byte *)cache + 3;

	while (patch->topdelta != 0xff)
	{
		i++;
		if (i > 1000) {
			I_Error("too big?");
		}

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
void R_GenerateComposite(int32_t texnum)
{
	byte*               block;
	texpatch_t*         patch;
	patch_t*            realpatch;
	int32_t                 x;
	int32_t                 x1;
	int32_t                 x2;
	int32_t                 i;
	column_t*           patchcol;
	int16_t*              collump;
	uint16_t*		colofs;
	MEMREF				realpatchRef;
	int16_t				textureheight;
	int16_t				texturewidth;
	int16_t				texturepatchcount;
	int16_t				patchpatch;
	int16_t				patchoriginx;
	int16_t				patchoriginy;
	texture_t* texture;



	MEMREF texturecolumnlumptexnum = ((MEMREF*)Z_LoadBytesFromEMS(texturecolumnlumpRef))[texnum];
	MEMREF texturecolumnofstexnum = ((MEMREF*)Z_LoadBytesFromEMS(texturecolumnofsRef))[texnum];
	MEMREF texturecompositetexnum;
	int32_t texturecompositesize = ((int32_t*)Z_LoadBytesFromEMS(texturecompositesizeRef))[texnum];

	MEMREF texturememref = ((MEMREF*)Z_LoadBytesFromEMS(texturesRef))[texnum];
	MEMREF* texturecomposite = (MEMREF*)Z_LoadBytesFromEMS(texturecompositeRef);


	texturecomposite[texnum] = Z_MallocEMSNewWithBackRef(texturecompositesize,
		PU_STATIC,
		0xff, ALLOC_TYPE_TEXTURE, texnum+1);
	texturecompositetexnum = texturecomposite[texnum];


	texture = (texture_t*)Z_LoadBytesFromEMS(texturememref);
	texturewidth = texture->width;
	textureheight = texture->height;
	texturepatchcount = texture->patchcount;
	// Composite the columns together.

	for (i = 0;
		i < texturepatchcount;
		i++)
	{
#ifdef LOOPCHECK
		if (i > 1000) {
			I_Error("too big? texpatch");
		}
#endif	

		texture = (texture_t*)Z_LoadBytesFromEMS(texturememref);
		patch = &texture->patches[i];
		patchpatch = patch->patch;
		patchoriginx = patch->originx;
		patchoriginy = patch->originy;

		W_CacheLumpNumCheck(patchpatch);
		realpatchRef = W_CacheLumpNumEMS(patchpatch, PU_CACHE);
		realpatch = (patch_t*)Z_LoadBytesFromEMS(realpatchRef);
		x1 = patchoriginx;
		x2 = x1 + (realpatch->width);

		if (x1 < 0)
			x = 0;
		else
			x = x1;

		if (x2 > texturewidth)
			x2 = texturewidth;
		collump = (int16_t*)Z_LoadBytesFromEMS(texturecolumnlumptexnum);

		for (; x < x2; x++)
		{
			// seems ok. if this ever barks up, we can bring the above Z_LoadBytesFromEMS calls down into one of these loops


			// Column does not have multiple patches?
			if (collump[x] >= 0)
				continue;
			block = (byte*)Z_LoadBytesFromEMS(texturecompositetexnum);
			colofs = (uint16_t*)Z_LoadBytesFromEMS(texturecolumnofstexnum);
			realpatch = (patch_t*)Z_LoadBytesFromEMS(realpatchRef);

			patchcol = (column_t *)((byte *)realpatch
				+ (realpatch->columnofs[x - x1]));
			R_DrawColumnInCache(patchcol,
				block + colofs[x],
				patchoriginy,
				textureheight);
			Z_RefIsActive(texturecompositetexnum);
			Z_RefIsActive(texturecolumnofstexnum);
			Z_RefIsActive(realpatchRef);
			collump = (int16_t*)Z_LoadBytesFromEMS(texturecolumnlumptexnum);

		}

	}

	// Now that the texture has been built in column cache,
	//  it is purgable from zone memory.

	// TODO: if we free this and the texture handle is still active that's bad?
	Z_ChangeTagEMSNew(texturecompositetexnum, PU_CACHE);
}



//
// R_GenerateLookup
//
void R_GenerateLookup(int32_t texnum)
{
	texture_t*          texture;
	byte*               patchcount;     // patchcount[texture->width]
	texpatch_t*         patch;
	patch_t*            realpatch;
	int32_t                 x;
	int32_t                 x1;
	int32_t                 x2;
	int32_t                 i;
	int32_t					patchpatch;
	int16_t*              collump;
	uint16_t*     colofs;
	MEMREF				realpatchRef;
	int16_t				texturepatchcount;
	int16_t				texturewidth;
	int16_t				textureheight;
	int8_t				texturename[8];

	MEMREF* textures = (MEMREF*)Z_LoadBytesFromEMS(texturesRef);
	MEMREF textureRef = textures[texnum];

	MEMREF texturecolumnlump = ((MEMREF*)Z_LoadBytesFromEMS(texturecolumnlumpRef))[texnum];
	MEMREF texturecolumnofs = ((MEMREF*)Z_LoadBytesFromEMS(texturecolumnofsRef))[texnum];

	int32_t* texturecompositesize = (int32_t*)Z_LoadBytesFromEMS(texturecompositesizeRef);
	MEMREF* texturecomposite = (MEMREF*)Z_LoadBytesFromEMS(texturecompositeRef);
	texturecomposite[texnum] = NULL_MEMREF;
	texturecompositesize[texnum] = 0;




	// Composited texture not created yet.

	texture = (texture_t*)Z_LoadBytesFromEMS(textureRef);
	texturewidth = texture->width;
	textureheight = texture->height;
	memcpy(texturename, texture->name, 8);
	// Now count the number of columns
	//  that are covered by more than one patch.
	// Fill in the lump / offset, so columns
	//  with only a single patch are all done.
	patchcount = (byte *)alloca(texture->width);
	memset(patchcount, 0, texture->width);
	patch = texture->patches;
	texturepatchcount = texture->patchcount;
	for (i = 0;
		i < texturepatchcount;
		i++)
	{
		texture = (texture_t*)Z_LoadBytesFromEMS(textureRef);
		patch = &texture->patches[i];
		x1 = patch->originx;
		patchpatch = patch->patch;
		W_CacheLumpNumCheck(patch->patch);
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
		collump = (int16_t*)Z_LoadBytesFromEMS(texturecolumnlump);
		colofs = (uint16_t*)Z_LoadBytesFromEMS(texturecolumnofs);
		realpatch = (patch_t*)Z_LoadBytesFromEMS(realpatchRef);
		for (; x < x2; x++)
		{
			Z_RefIsActive(realpatchRef);
			Z_RefIsActive(texturecolumnlump);
			Z_RefIsActive(texturecolumnofs);
			patchcount[x]++;
			collump[x] = patchpatch;
			colofs[x] = (realpatch->columnofs[x - x1]) + 3;
		}
	}

	texturecompositesize = (int32_t*)Z_LoadBytesFromEMS(texturecompositesizeRef);
	colofs = (uint16_t*)Z_LoadBytesFromEMS(texturecolumnofs);
	collump = (int16_t*)Z_LoadBytesFromEMS(texturecolumnlump);

	Z_RefIsActive(texturecompositesizeRef);
	Z_RefIsActive(texturecolumnofsRef);
	Z_RefIsActive(texturecolumnofs);
	Z_RefIsActive(texturecolumnlump);
	for (x = 0; x < texturewidth; x++) {

		if (!patchcount[x]) {
			printf("R_GenerateLookup: column without a patch (%s)\n", texturename);
			return;
		}
		// I_Error ("R_GenerateLookup: column without a patch");

		if (patchcount[x] > 1) {
			// Use the cached block.
			collump[x] = -1;
			colofs[x] = texturecompositesize[texnum];

			if (texturecompositesize[texnum] > 0x10000 - textureheight) {
				I_Error("R_GenerateLookup: texture %i is >64k", texnum);
			}

			texturecompositesize[texnum] += textureheight;
		}
	}
}




//
// R_GetColumn
//
byte*
R_GetColumn
(int32_t           tex,
	int32_t           col)
{
	int32_t         lump; int32_t         ofs; MEMREF* texturecolumnlumpTex; MEMREF* texturecolumnofsTex; int16_t* texturecolumnlump; uint16_t* texturecolumnofs; MEMREF* texturecomposite;
	MEMREF columnRef;

	byte* texturecompositebytes;

	// reordered to require fewer things in memory at same time
	int32_t* texturewidthmask = (int32_t*)Z_LoadBytesFromEMS(texturewidthmaskRef);
	col &= texturewidthmask[tex];


	texturecolumnofsTex = (MEMREF*)Z_LoadBytesFromEMS(texturecolumnofsRef);
	texturecolumnofs = (uint16_t*)Z_LoadBytesFromEMS(texturecolumnofsTex[tex]);
	ofs = texturecolumnofs[col];

	texturecolumnlumpTex = (MEMREF*)Z_LoadBytesFromEMS(texturecolumnlumpRef);

	texturecolumnlump = (int16_t*)Z_LoadBytesFromEMS(texturecolumnlumpTex[tex]);
	lump = texturecolumnlump[col];

	if (lump > 0) {
		W_CacheLumpNumCheck(lump);
		//return (byte *)W_CacheLumpNum(lump, PU_CACHE) + ofs;
		columnRef = W_CacheLumpNumEMS(lump, PU_CACHE);
		return (byte*)Z_LoadBytesFromEMS(columnRef) + ofs;
	}

	texturecomposite = (MEMREF*)Z_LoadBytesFromEMS(texturecompositeRef);

	if (texturecomposite[tex] == NULL_MEMREF) {
		R_GenerateComposite(tex);
	}

	texturecomposite = (MEMREF*)Z_LoadBytesFromEMS(texturecompositeRef);
	texturecompositebytes = (byte*)Z_LoadBytesFromEMS(texturecomposite[tex]);

	return texturecompositebytes + ofs;
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

	int32_t                 i;
	int32_t                 j;

	int32_t*                maptex;
	int32_t*                maptex2;
	int32_t*                maptex1;

	int8_t                name[9];
	int8_t*               names;
	int8_t*               name_p;

	int32_t*                patchlookup;

	int32_t                 totalwidth;
	int32_t                 nummappatches;
	int32_t                 offset;
	int32_t                 maxoff;
	int32_t                 maxoff2;
	int32_t                 numtextures1;
	int32_t                 numtextures2;

	int32_t*                directory;

	int32_t                 temp1;
	int32_t                 temp2;
	int32_t                 temp3;

	int32_t*                texturewidthmask;
	// needed for texture pegging
	fixed_t*            textureheight;
	MEMREF *            texturecolumnlump;
	MEMREF *			texturecolumnofs;
	MEMREF*				textures;
	int32_t *				texturetranslation;
	MEMREF				namesRef;
	MEMREF				maptexRef;
	MEMREF				maptex2Ref;
	int16_t				texturewidth;
	int16_t				textureheightval;



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
	Z_FreeEMSNew(namesRef);

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
	texturesRef = Z_MallocEMSNew(numtextures * 4, PU_STATIC, 0, ALLOC_TYPE_TEXTURE);
	texturecolumnlumpRef = Z_MallocEMSNew(numtextures * 4, PU_STATIC, 0, ALLOC_TYPE_TEXTURE);
	texturecolumnofsRef = Z_MallocEMSNew(numtextures * 4, PU_STATIC, 0, ALLOC_TYPE_TEXTURE);
	texturecompositeRef = Z_MallocEMSNew(numtextures * 4, PU_STATIC, 0, ALLOC_TYPE_TEXTURE);
	texturecompositesizeRef = Z_MallocEMSNew(numtextures * 4, PU_STATIC, 0, ALLOC_TYPE_TEXTURE);
	texturewidthmaskRef = Z_MallocEMSNew(numtextures * 4, PU_STATIC, 0, ALLOC_TYPE_TEXTURE);
	textureheightRef = Z_MallocEMSNew(numtextures * 4, PU_STATIC, 0, ALLOC_TYPE_TEXTURE);

	//texturecomposite	 = (MEMREF*)  Z_LoadBytesFromEMS(texturecompositeRef);
	//texturecompositesize = (int32_t*)			  Z_LoadBytesFromEMS(texturecompositesizeRef);
	texturewidthmask = (int32_t*)Z_LoadBytesFromEMS(texturewidthmaskRef);
	textureheight = (fixed_t*)Z_LoadBytesFromEMS(textureheightRef);


	totalwidth = 0;

	//  Really complex printing shit...
	temp1 = W_GetNumForName("S_START");  // P_???????
	temp2 = W_GetNumForName("S_END") - 1;
	temp3 = ((temp2 - temp1 + 63) / 64) + ((numtextures + 63) / 64);
	printf("[");
	for (i = 0; i < temp3; i++)
		printf(" ");
	printf("         ]");
	for (i = 0; i < temp3; i++)
		printf("\x8");
	printf("\x8\x8\x8\x8\x8\x8\x8\x8\x8\x8");

	for (i = 0; i < numtextures; i++, directory++)
	{
		if (!(i & 63))
			printf(".");

		if (i == numtextures1)
		{
			// Start looking in second texture file.
			maptex = maptex2;
			maxoff = maxoff2;
			directory = maptex + 1;
		}

		offset = (*directory);

		if (offset > maxoff)
			I_Error("R_InitTextures: bad texture directory");

		mtexture = (maptexture_t *)((byte *)maptex + offset);


		textureRef = Z_MallocEMSNew(sizeof(texture_t)
			+ sizeof(texpatch_t)*((mtexture->patchcount) - 1),
			PU_STATIC, 0, ALLOC_TYPE_TEXTURE);

		textures = (MEMREF*)Z_LoadBytesFromEMS(texturesRef);
		textures[i] = textureRef;

		texture = (texture_t*)Z_LoadBytesFromEMS(textureRef);

		texture->width = (mtexture->width);
		texture->height = (mtexture->height);
		texture->patchcount = (mtexture->patchcount);
		texturewidth = texture->width;
		textureheightval = texture->height;

		memcpy(texture->name, mtexture->name, sizeof(texture->name));
		mpatch = &mtexture->patches[0];
		patch = &texture->patches[0];

		for (j = 0; j < texture->patchcount; j++, mpatch++, patch++)
		{
			patch->originx = (mpatch->originx);
			patch->originy = (mpatch->originy);
			patch->patch = patchlookup[(mpatch->patch)];
			if (patch->patch == -1)
			{
				I_Error("R_InitTextures: Missing patch in texture %s %i",
					texture->name, textureRef);
			}
		}
		//printf("name %s", texture->name);
		texturecolumnlump = (MEMREF*)Z_LoadBytesFromEMS(texturecolumnlumpRef);
		texturecolumnlump[i] = Z_MallocEMSNew(texture->width * 2, PU_STATIC, 0, ALLOC_TYPE_TEXTURE);
		texturecolumnofs = (MEMREF*)Z_LoadBytesFromEMS(texturecolumnofsRef);
		texturecolumnofs[i] = Z_MallocEMSNew(texture->width * 2, PU_STATIC, 0, ALLOC_TYPE_TEXTURE);
		

		j = 1;
		while (j * 2 <= texturewidth)
			j <<= 1;

		texturewidthmask = (int32_t*)Z_LoadBytesFromEMS(texturewidthmaskRef);
		textureheight = (fixed_t*)Z_LoadBytesFromEMS(textureheightRef);

		Z_RefIsActive(texturewidthmaskRef);
		Z_RefIsActive(textureheightRef);
		texturewidthmask[i] = j - 1;
		textureheight[i] = textureheightval << FRACBITS;

		totalwidth += texturewidth;
	}

	Z_FreeEMSNew(maptexRef);
	if (maptex2) {
		Z_FreeEMSNew(maptex2Ref);
	}
	// Precalculate whatever possible.  
	for (i = 0; i < numtextures; i++)
		R_GenerateLookup(i);

	// Create translation table for global animation.

	// ref 385 ... page 3
	texturetranslationRef = Z_MallocEMSNew((numtextures + 1) * 4, PU_STATIC, 0, ALLOC_TYPE_TEXTURE_TRANSLATION);

	texturetranslation = (int32_t*)Z_LoadBytesFromEMS(texturetranslationRef);

	for (i = 0; i < numtextures; i++)
		texturetranslation[i] = i;

}



//
// R_InitFlats
//
void R_InitFlats(void)
{
	int32_t         i;
	int32_t * flattranslation;

	firstflat = W_GetNumForName("F_START") + 1;
	lastflat = W_GetNumForName("F_END") - 1;
	numflats = lastflat - firstflat + 1;

	// Create translation table for global animation.
	flattranslationRef = Z_MallocEMSNew((numflats + 1) * 4, PU_STATIC, 0, ALLOC_TYPE_FLAT_TRANSLATION);
	flattranslation = (int32_t*)Z_LoadBytesFromEMS(flattranslationRef);

	for (i = 0; i < numflats; i++)
		flattranslation[i] = i;
}


//
// R_InitSpriteLumps
// Finds the width and hoffset of all sprites in the wad,
//  so the sprite does not need to be cached completely
//  just for having the header info ready during rendering.
//
void R_InitSpriteLumps(void)
{
	int32_t         i;

	patch_t     *patch;
	fixed_t     *spritewidth;
	fixed_t     *spriteoffset;
	fixed_t     *spritetopoffset;
	MEMREF		patchRef;
	int16_t		patchwidth;
	int16_t		patchleftoffset;
	int16_t		patchtopoffset;

	firstspritelump = W_GetNumForName("S_START") + 1;
	lastspritelump = W_GetNumForName("S_END") - 1;

	numspritelumps = lastspritelump - firstspritelump + 1;
	spritewidthRef = Z_MallocEMSNew(numspritelumps * 4, PU_STATIC, 0, ALLOC_TYPE_SPRITE);
	spriteoffsetRef = Z_MallocEMSNew(numspritelumps * 4, PU_STATIC, 0, ALLOC_TYPE_SPRITE);
	spritetopoffsetRef = Z_MallocEMSNew(numspritelumps * 4, PU_STATIC, 0, ALLOC_TYPE_SPRITE);


	for (i = 0; i < numspritelumps; i++)
	{
		if (!(i & 63))
			printf(".");
		Z_RefIsActive(spritewidthRef);
		Z_RefIsActive(spriteoffsetRef);
		Z_RefIsActive(spritetopoffsetRef);


		W_CacheLumpNumCheck(firstspritelump + i);
		patchRef = W_CacheLumpNumEMS(firstspritelump + i, PU_CACHE);
		patch = (patch_t*)Z_LoadBytesFromEMS(patchRef);
		patchwidth = (patch->width) ;
		patchleftoffset = (patch->leftoffset);
		patchtopoffset = (patch->topoffset) ;

		spritewidth = (fixed_t*)Z_LoadBytesFromEMS(spritewidthRef);
		spriteoffset = (fixed_t*)Z_LoadBytesFromEMS(spriteoffsetRef);
		spritetopoffset = (fixed_t*)Z_LoadBytesFromEMS(spritetopoffsetRef);


		spritewidth[i] = patchwidth << FRACBITS;
		spriteoffset[i] = patchleftoffset << FRACBITS;
		spritetopoffset[i] = patchtopoffset << FRACBITS;

	}
}
 

//
// R_InitColormaps
//
void R_InitColormaps(void)
{
	int32_t lump, length;

	// Load in the light tables, 
	//  256 byte align tables.
	lump = W_GetNumForName("COLORMAP");
	length = W_LumpLength(lump) + 255;

	// todo: big hack.. Making colormaps work in EMS is a major pain. tons of pointers being passed back and forth.
	// you can convert these to offsets, working off the base pointer of the original allocation which i have done..
	// but ultimately the light values are used in 386-style asm in planar.obj (see dc_source and ds_source and
	// _ds_colormap) so until that asm is redone im not sure how to make colormaps work off the heap. For performance
	// reasons it may even be best to keep it in a static allocation...
	colormaps = (byte*)colormapbytes;
	colormaps = (byte *)(((int32_t)colormaps + 255)&~0xff);

	//printf("Size %i", length);
	//I_Error("size %i", length);

	W_ReadLump(lump, colormaps);
}



//
// R_InitData
// Locates all the lumps
//  that will be used by all views
// Must be called after W_Init.
//
void R_InitData(void)
{
	R_InitTextures();
	printf(".");
	R_InitFlats();
	printf(".");
	R_InitSpriteLumps();
	printf(".");
	R_InitColormaps();
}



//
// R_FlatNumForName
// Retrieval, get a flat number for a flat name.
//
int32_t R_FlatNumForName(int8_t* name)
{
	int32_t         i;
	int8_t        namet[9];

	i = W_CheckNumForName(name);

	if (i == -1)
	{
		namet[8] = 0;
		memcpy(namet, name, 8);
		I_Error("R_FlatNumForName: %s not found", namet);
	}
	return i - firstflat;
}



//
// R_CheckTextureNumForName
// Check whether texture is available.
// Filter out NoTexture indicator.
//
int32_t     R_CheckTextureNumForName(int8_t *name)
{
	int32_t         i;
	MEMREF* textures;
	texture_t* texture;
	// "NoTexture" marker.
	if (name[0] == '-')
		return 0;



	for (i = 0; i < numtextures; i++) {
		textures = (MEMREF*)Z_LoadBytesFromEMS(texturesRef);
		texture = (texture_t*)Z_LoadBytesFromEMS(textures[i]);
		//printf("texname %s", texture->name);
				//I_Error("found it? %i %i %s", i, textures[i], texture->name);



		if (!strncasecmp(texture->name, name, 8))
			return i;
	}
	return -1;
}



//
// R_TextureNumForName
// Calls R_CheckTextureNumForName,
//  aborts with error message.
//
int16_t     R_TextureNumForName(int8_t* name)
{
	int16_t         i;
	i = R_CheckTextureNumForName(name);

	if (i == -1) {
		I_Error("R_TextureNumForName: %s not found %i %i %i",
			name, numreads, pageins, pageouts);
	}
	return i;
}




//
// R_PrecacheLevel
// Preloads all relevant graphics for the level.
//
//int32_t             flatmemory;
//int32_t             texturememory;
//int32_t             spritememory;

void R_PrecacheLevel(void)
{
	int8_t*               flatpresent;
	int8_t*               texturepresent;
	int8_t*               spritepresent;

	int32_t                 i;
	int32_t                 j;
	int32_t                 k;
	int32_t                 lump;

	texture_t*          texture;
	THINKERREF          th;
	spriteframe_t*      sf;
	spritedef_t*		sprites;
	spriteframe_t*		spriteframes;
	side_t* sides;
	MEMREF* textures;


	sector_t* sectors = (sector_t*) Z_LoadBytesFromEMS(sectorsRef);

	if (demoplayback)
		return;

	// Precache flats.
	flatpresent = alloca(numflats);
	memset(flatpresent, 0, numflats);
	
	for (i = 0; i < numsectors; i++)
	{
		flatpresent[sectors[i].floorpic] = 1;
		flatpresent[sectors[i].ceilingpic] = 1;
	}

	//flatmemory = 0;

	for (i = 0; i < numflats; i++)
	{
		if (flatpresent[i])
		{
			lump = firstflat + i;
			//flatmemory += lumpinfo[lump].size;
			W_CacheLumpNumCheck(lump);
			W_CacheLumpNumEMS(lump, PU_CACHE);
		}
	}

	// Precache textures.
	texturepresent = alloca(numtextures);
	memset(texturepresent, 0, numtextures);
	sides = (side_t*)Z_LoadBytesFromEMS(sidesRef);
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
	for (i = 0; i < numtextures; i++)
	{
		if (!texturepresent[i])
			continue;

		textures = (MEMREF*)Z_LoadBytesFromEMS(texturesRef);
		texture = (texture_t*)Z_LoadBytesFromEMS(textures[i]);

		for (j = 0; j < texture->patchcount; j++)
		{
			lump = texture->patches[j].patch;
			//texturememory += lumpinfo[lump].size;
			if (W_CacheLumpNumCheck(lump)) {
				printf("Crash %i %i %i", j, lump, texture->patchcount);
				I_Error("Crash %i %i %i", j, lump, texture->patchcount);
			}
			W_CacheLumpNumEMS(lump, PU_CACHE);
		}
	}

	// Precache sprites.
	spritepresent = alloca(numsprites);
	memset(spritepresent, 0, numsprites);

	for (th = thinkerlist[0].next; th != 0; th = thinkerlist[th].next)
	{
		if (thinkerlist[th].functionType == TF_MOBJTHINKER) {
			spritepresent[((mobj_t *)Z_LoadBytesFromEMS(thinkerlist[th].memref))->sprite] = 1;
		}
	}
	//I_Error("blah 1 %i %i %i", numreads, pageins, pageouts);

	//spritememory = 0;
	//todo does this have to be pulled into the for loop
	sprites = (spritedef_t*)Z_LoadBytesFromEMS(spritesRef);
	for (i = 0; i < numsprites; i++)
	{
		if (!spritepresent[i])
			continue;
		spriteframes = (spriteframe_t*)Z_LoadBytesFromEMS(sprites[i].spriteframesRef);

		for (j = 0; j < sprites[i].numframes; j++)
		{
			sf = &spriteframes[j];
			for (k = 0; k < 8; k++)
			{
				lump = firstspritelump + sf->lump[k];
				//spritememory += lumpinfo[lump].size;
				W_CacheLumpNumCheck(lump);
				W_CacheLumpNumEMS(lump, PU_CACHE);
			}
		}
	}

}


void R_EraseCompositeCache(int16_t texnum) {

	// todo are we calling this with 0 all the time?

	MEMREF* texturecomposite = (MEMREF*)Z_LoadBytesFromEMS(texturecompositeRef);
	texturecomposite[texnum] = NULL_MEMREF;
}


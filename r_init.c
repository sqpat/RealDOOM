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
#include "m_memory.h"




extern uint8_t			skyflatnum;

 


extern uint8_t R_FlatNumForName(int8_t* name);


#define DISTMAP		2

 


//
// R_InitSpriteLumps
// Finds the width and hoffset of all sprites in the wad,
//  so the sprite does not need to be cached completely
//  just for having the header info ready during rendering.
//
void R_InitSpriteLumps(void)
{
	int16_t         i;

	for (i = 0; i < numspritelumps; i++) {
		patch_t     __far*patch;
		int16_t		patchwidth;
		int16_t		patchleftoffset;
		int16_t		patchtopoffset;
		uint16_t    postdatasize = 0;
		int16_t     col;
		uint16_t    startoffset;
		column_t    __far * column;
		uint16_t    pixelsize = 0;
		
#ifdef DEBUG_PRINTING
		if (!(i & 63))
			DEBUG_PRINT(".");
#endif
		Z_QuickMapScratch_5000();

		W_CacheLumpNumDirect(firstspritelump + i, SCRATCH_ADDRESS_5000);
		
		patch = (patch_t __far*)SCRATCH_ADDRESS_5000;
		patchwidth = (patch->width);
		patchleftoffset = (patch->leftoffset);
		patchtopoffset = (patch->topoffset);

		// patchwidth in practice between 0 and 257.
		// no patchwidth 1s ever exist, nor does 256.
		// we will hack in the case that 1 == 257 in the engine and store in uint8_t (gross but saves 1300 bytes)

		if (patchwidth == 257)
			spritewidths[i] = 1;
		else
			spritewidths[i] = patchwidth;

		// left offset between -151 and 130 in practice. 
		//  negatives are only ever used for psprites, and psprites are always negative so we encode positve and change
		// the subtraction operation to an addition and we are good.
		spriteoffsets[i] = abs(patchleftoffset);


		// top offset between -127 and 129 in practice. 128/-128 never actually happens so we hack in that case
		if (patchtopoffset == 129)
			spritetopoffsets[i] = -128;
		else
			spritetopoffsets[i] = patchtopoffset;

		// calculate sizes for this
		for (col = 0; col < patchwidth; col++){

			column = (column_t __far *)(SCRATCH_ADDRESS_5000 + patch->columnofs[col]);
			while (column->topdelta != 0xFF){
				
				uint16_t runsize = column->length;
				pixelsize += runsize;
				pixelsize += (16 - ((runsize &0xF)) &0xF); // round up to next paragraph
				postdatasize += 2;

				column = (column_t __far *)(  (byte  __far*)column + column->length + 4 );
			}
			// one more for 0xFFFF to end the column of posts
			postdatasize += 2;

		}

		// calculate where the pixel data starts. add the patch header, colofs and post data. note postofs will sit
		// in the extra bytes alongside colofs.
		startoffset = 8 + (patchwidth << 2) + postdatasize;
		startoffset += (16 - ((startoffset &0xF)) &0xF); // round up so first pixel data starts aligned of course.
		
		// sigh can we do this better? it's init  code so i dont really care but..
		Z_QuickMapUndoFlatCache();
		spritepostdatasizes[i] = postdatasize;
		spritetotaldatasizes[i] = pixelsize + startoffset;
		Z_QuickMapRender();



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
//
// R_GenerateLookup
//
//todo pull down below?

uint16_t maskedcount = 0;

// global post offset for masked texture posts
static uint16_t currentpostoffset = 0;
static uint16_t currentpostdataoffset = 0;
// global colof offset for masked texture colofs
static uint16_t currentpixeloffset = 0;

// complicated memory situation... creating render data at 0x5000-0x6000... lump info will be in 0x4000 range...
// use scratch at 0x7000 which is usually level data. level data is not used during init, only during setup,
// so its technically a free area here. (init is game init, setup is level setup)
void R_GenerateLookup(uint16_t texnum)
{
 

	texture_t __far*          texture;
	patch_t __far*            realpatch;
	int16_t                 x;
	int16_t                 i;
	int16_t                 j;
	uint16_t				eraseoffset;
	int16_t					patchpatch;
	int16_t  patchusedheight;

	int16_t					lastusedpatch = -1;
	uint8_t				texturepatchcount;
	int16_t				texturewidth;
	int16_t				textureheight;
	int16_t 			usedtextureheight;
	
	int16_t				currentcollump;
	int16_t				currentcollumpRLEStart;
	uint16_t            currentheight;  // use int16 so shifting is less of a hassle in here
	uint16_t            texsize;
	int8_t				ismaskedtexture = 0;


	// rather than alloca or whatever, lets use the scratch page since its already allocated for us...
	// this is startup code so who cares if its slow
	uint16_t __far*              texmaskedpostdata    = MK_FP(SCRATCH_PAGE_SEGMENT_7000, 0xE000);
	int16_t __far*               texcollump           = MK_FP(SCRATCH_PAGE_SEGMENT_7000, 0xF800);
	uint16_t __far*              maskedtexpostdataofs = MK_FP(SCRATCH_PAGE_SEGMENT_7000, 0xFA00);
	uint16_t __far*              maskedpixlofs        = MK_FP(SCRATCH_PAGE_SEGMENT_7000, 0xFC00);
	int8_t __far*                texpatchheights      = MK_FP(SCRATCH_PAGE_SEGMENT_7000, 0xFE00);
	byte __far*					 columnpatchcount     = MK_FP(SCRATCH_PAGE_SEGMENT_7000, 0xFF00);

	// put colofs in here. copy to colofs if texture is masked

	// piggyback these local arrays off scratch data...
	int16_t_union __far*  collump = texturecolumnlumps_bytes;
	uint16_t currenttexturepixelbytecount = 0;
	uint16_t currenttexturepostoffset = 0;
	column_t __far * column;

	
	// check which 64k page this lives in
	
	
	texturepatchlump_offset[texnum] = currentlumpindex;

	//uint8_t currentpatchpage = 0;


	// Composited texture not created yet.

	texture = (texture_t __far*)&(texturedefs_bytes[texturedefs_offset[texnum]]);
	texturewidth = texture->width + 1;
	textureheight = texture->height + 1;
	usedtextureheight = textureheight + ((16 - (textureheight &0xF) ) & 0xF);


	// Now count the number of columns
	//  that are covered by more than one patch.
	// Fill in the lump / offset, so columns
	//  with only a single patch are all done.


	// far memset seems to be unreliable... maybe stack overflow
	// let's just do this to zero out the necessary data.
	// most of these structures don't need a zero default, they are written before read.
	for (eraseoffset = 0xFF00; eraseoffset != 0; eraseoffset+=2) {
		*((uint16_t __far *) MK_FP(SCRATCH_PAGE_SEGMENT_7000, eraseoffset)) = 0;
	}
	
	//patch = texture->patches;
	texturepatchcount = texture->patchcount;
	realpatch = (patch_t __far*) MK_FP(SCRATCH_PAGE_SEGMENT_7000, 0);
 
	// about masked textures
	
	//  In the vanilla engine, composite columns with masked pixels does not seem
	// to be supported, and furthermore - in doom shareware, 1, 2 -  all masked
	// textures are single patch in practice. As a result, we can throw out multi
	// patch textures as non masked. 
	// so we can do two loops on a single patch texture to determine if its masked
	// and we arent thrashing the cached lump away
	

	for (i = 0; i < texturepatchcount; i++) {
			
		int16_t columntotalsize = 0;
		texpatch_t __far*         patch = &texture->patches[i];
		int16_t                 x2;
		int16_t                 x1 = patch->originx * (patch->patch & ORIGINX_SIGN_FLAG ? -1 : 1);
		patchpatch = patch->patch & PATCHMASK;

		if (lastusedpatch != patchpatch){
			W_CacheLumpNumDirect(patchpatch, (byte __far*)realpatch);
			patchusedheight = realpatch->height;
			patchusedheight += (16 - ((patchusedheight &0xF)) &0xF); // round up to next paragraph
		}
		patch_sizes[patchpatch-firstpatch] = patchusedheight * realpatch->width; // used for non masked sizes. doesnt include colofs, headers.
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
		
		column = (column_t __far*) MK_FP(SCRATCH_PAGE_SEGMENT_7000, realpatch->columnofs[x]);

		for (; x < x2; x++) {
			columnpatchcount[x]++;
			texcollump[x] = patchpatch;
			texpatchheights[x] = patchusedheight;
			
			// this may be a masked texture, so lets store it's data in temporary region
			if (texturepatchcount == 1){	
				// openwatcom messes up if column is dfined here...
				//column_t __far * column = (column_t __far*) MK_FP(SCRATCH_PAGE_SEGMENT_7000, realpatch->columnofs[x]);
				
				int8_t colpatchcount = 0;
				int16_t columntotalsize = 0;
				// i dont think we need x1 for texturepatchcount 1 stuff.
				// i think in practice, all masked textures are same size as the single patch etc
				// calculate proper addr, paragraph align				
				column = (column_t __far*) MK_FP(SCRATCH_PAGE_SEGMENT_7000, realpatch->columnofs[x]);
				
				maskedpixlofs[x] = currenttexturepixelbytecount; 
				maskedtexpostdataofs[x] = (currentpostdataoffset)+ (currenttexturepostoffset << 1);
	 
				for ( ; (column->topdelta != 0xff)  ; )  {
					uint16_t runsize = column->length;
					columntotalsize += runsize;
					runsize += (16 - ((runsize &0xF)) &0xF); // round up to next paragraph
					currenttexturepixelbytecount += runsize;


					// copy both topdelta and length at once
					texmaskedpostdata[currenttexturepostoffset] = *((uint16_t __far *)column);
					currenttexturepostoffset ++;


						// 97 97 
						// 3700
						
						// 209 (thus 208)
						// 0
/*
					if (texnum == 4 && x == 45) {
						I_Error("\ntexture stuff %u %u %u %x %x %x %x %u %u", texnum, x, 
							currenttexturepixelbytecount, 
							*((uint16_t __far *)( (byte  __far*)column + 3)),
							*((uint16_t __far *)( (byte  __far*)column + 5)),
							*column,
							texmaskedpostdata[currenttexturepostoffset-1],
							currenttexturepostoffset,
							currentpostoffset
						 );
					}
						 */

					column = (column_t  __far*)(  (byte  __far*)column + column->length + 4);
					colpatchcount++;
				}
				texmaskedpostdata[currenttexturepostoffset] = 0xFFFF; // end the post.
				currenttexturepostoffset ++;


				// all masked textures (NOT SPRITES) have at least one col with multiple columns
				// which adds up to less than texture height; seems to be an accurate enough check...
				if (colpatchcount > 1 && columntotalsize < textureheight ){
					
					// most masked textures are not 256 wide. (the ones that are have tons of col patches.)
					// but theres a couple bugged doom2 256x128 textures that have a pixel gap but arent masked. 
					// However doom1 has some masked textures that have tons of gaps... We kind of hack around this bad data.
					
					if (texturewidth != 256 || colpatchcount > 3){
						ismaskedtexture = 1;
					}
				}
			} 	
		}
	}


	// we determined up above we have a masked texture....
	// need to run thru colofs again?
	masked_lookup[texnum] = 0xFF;	// initialized value - no pointer to colofs
	if (ismaskedtexture){
		uint16_t __far* pixelofs   =  MK_FP(maskedpixeldataofs_segment, currentpixeloffset);
		uint16_t __far* postofs    =  MK_FP(maskedpostdataofs_segment, currentpostoffset);
		uint16_t __far* postdata   =  MK_FP(maskedpostdata_segment, currentpostdataoffset);
		
		masked_lookup[texnum] = maskedcount;	// index to lookup of struct...

		masked_headers[maskedcount].texturesize = currenttexturepixelbytecount;
		masked_headers[maskedcount].pixelofsoffset = currentpixeloffset;
		masked_headers[maskedcount].postofsoffset = currentpostoffset;
		
		// copy the offset data...
		for (i = 0; i < texturewidth; i++){
			pixelofs[i] = maskedpixlofs[i] >> 4;
			postofs[i] = maskedtexpostdataofs[i];
		}

		// copy the actual post data
		for (i = 0; i < currenttexturepostoffset; i++){
			postdata[i] = texmaskedpostdata[i];

/*
			if (texnum == 4 && i == 45) {
				I_Error("\ntexture stuff %u %u %u %x %x %x %x", texnum, x, 
					currenttexturepixelbytecount, 
					*((uint16_t __far *)( (byte  __far*)column + 3)),
					*((uint16_t __far *)( (byte  __far*)column + 5)),
					*column,
					texmaskedpostdata[usedpostoffset-1]
					);
			}*/


		}


		// times 2 for word offset to byte offset
		currentpostoffset += (texturewidth*2);
		currentpixeloffset += (texturewidth*2);
		currentpostdataoffset += (currenttexturepostoffset*2);
		//DEBUG_PRINT("\n Found masked: %i %i", texnum, maskedcount);
		maskedcount++;

	}


	for (x = 0; x < texturewidth; x++) {
 
		if (!columnpatchcount[x]) {
			// R_GenerateLookup: column without a patch
			//I_Error("R_GenerateLookup: column without a patch (%Fs), %i %i %hhu %hhu %Fp\n", texture->name, x, texturewidth, texnum, columnpatchcount[x], columnpatchcount);
			I_Error("91");
			return;
		}

		//todo start/stop 
		if (columnpatchcount[x] > 1) {
			// two patches in this column!

			texcollump[x] = -1;
			texturecompositesizes[texnum] += usedtextureheight;
		}
	}

 

	// Now we generate collump RLE runs
	// this is a map of the final composite texture's columns to a patch's columns.
	// since they are generally repetitive, we use RLE compression to store these runs in way less space.


	currentcollump = texcollump[0];
	currentheight = texpatchheights[0];
	currentcollumpRLEStart = 0;

	// write collumps data. Needs to be done here, so that we've accounted for multiple-patch cases with patchcount[x] > 1
	for (x = 1; x < texturewidth; x++) {
		if (currentcollump != texcollump[x]) {
			collump[currentlumpindex].h = currentcollump;
			// this is never above 128 in doom shareware, 1, 2. 
			collump[currentlumpindex + 1].bu.bytelow = x - currentcollumpRLEStart; 
			// thus, the high byte is free to store another useful byte - the texture patch offset y.

			
			// height is a value (number of bytes) between 16 and 144 in practice. it is 00010000 to 10010000 binary.
			// so we only use the top 4 bits. We often shift this right 4 to get segment count from number of bytes.
			// So we store two values here and do an AND to avoid 4x shifts (slow on x86-16)
			collump[currentlumpindex + 1].bu.bytehigh = currentheight | (currentheight >> 4); 





			currentcollumpRLEStart = x;
			currentcollump = texcollump[x];
			currentheight = texpatchheights[x];
			currentlumpindex += 2;
				

		}
	}
	collump[currentlumpindex].h = currentcollump;
	collump[currentlumpindex + 1].bu.bytelow = (texturewidth - currentcollumpRLEStart);
	collump[currentlumpindex + 1].bu.bytehigh = currentheight | (currentheight >> 4); 

	currentlumpindex += 2;

}

#define TEX_LOAD_ADDRESS (byte __far*) (0x70000000)
#define TEX_LOAD_ADDRESS_2 (byte __far*) (0x70008000)

//
// R_InitTextures
// Initializes the texture list
//  with the textures from the world map.
//
void R_InitTextures(void) {
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
	int16_t					lastpatch;
	int16_t					lastflat;
	int16_t					lastspritelump;

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
		copystr8(name, name_p + (i << 3 ));
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
		maptex2 = ((int32_t __far*)TEX_LOAD_ADDRESS_2);
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
			// texturedefs sizes are variable and dependent on texture size/texture patch count.
			texturedefs_offset[i + 1] = texturedefs_offset[i] + (sizeof(texture_t) + sizeof(texpatch_t)*((mtexture->patchcount) - 1));
		}


		texture = (texture_t __far*)&(texturedefs_bytes[texturedefs_offset[i]]);
		texture->width = (mtexture->width) - 1;
		texture->height = (mtexture->height) - 1;
		texture->patchcount = (mtexture->patchcount);
		texturewidth = texture->width + 1;
		textureheightval = texture->height; 

		FAR_memcpy(texture->name, mtexture->name, sizeof(texture->name));
		
//		if (i == 210)
//			DEBUG_PRINT("\n %.8Fs %.8Fs %i %Fp %Fp", texture->name, mtexture->name, sizeof(texture->name), texture->name, mtexture->name);
//			FAR_strncpy(name, mtexture->name, 8);

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

		j = 1;
		while ((j << 1) <= texturewidth){
			j <<= 1;
		}

		texturewidthmasks[i] = j - 1;
		textureheights[i] = textureheightval;


	}
	//DUMP_MEMORY_TO_FILE();


}

// openwatcom really struggles on the one huge function, causing memory bugs. i've lost a lot of time collectively there.
// lets just split this into two.
void R_InitTextures2(){
	int16_t i;

	Z_QuickMapMaskedExtraData();
	Z_QuickMapScratch_7000();
	// Create translation table for global animation.
	// Precalculate whatever possible.  
	// done using 7000 above ?

	for (i = 0; i < numtextures; i++){
		texturecompositesizes[i] = 0;
		texturetranslation[i] = i;
		R_GenerateLookup(i);
	}
	 
	
	//              pixelofs        postofs
	//    				  masked count
    //DOOM Shareware:	896    8     3170
	//DOOM 1: 			2304   12    12238
	//DOOM 2:		 	1408   11    4772
	//I_Error("currentpixeloffset is %u %u %u", currentpixeloffset, maskedcount, currentpostoffset);


	// Reset this since 0x7000 scratch page is active
	Z_QuickMapRender();
	Z_QuickMapLumpInfo();

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


void __near R_InitPatches(){
	int i = 0;
	patch_t __far* realpatch = (patch_t __far*) MK_FP(SCRATCH_PAGE_SEGMENT_7000, 0);
	for (i = 0; i < numpatches; i++){
		int16_t patchindex = firstpatch+i;
		W_CacheLumpNumDirect(patchindex, (byte __far*)realpatch);
		patchwidths[i] = realpatch->width;
	}
		


}

void __near R_InitData(void) {
	uint8_t         i;

	//R_InitPatches();

	R_InitTextures();
	R_InitTextures2();
	DEBUG_PRINT("..");
	R_InitPatches();

	// Create translation table for global animation.

	for (i = 0; i < numflats; i++)
		flattranslation[i] = i;



	// R_InitColormaps();

		// Load in the light tables, 
		//  256 byte align tables.


	R_InitSpriteLumps();
	DEBUG_PRINT(".");

	//lump = W_GetNumForName("COLORMAP");
	
	//length = W_LumpLength(lump) + 255;
	//colormaps = (byte __far*)colormapbytes;
	//colormaps = (byte  __far*)(((int32_t)colormaps + 255)&~0xff);
	W_CacheLumpNumDirect(1, colormaps);
	//W_CacheLumpNumDirect(1, (byte __far*) 0xCC000000);

 
}


extern uint8_t                     detailLevel;
extern uint8_t                     screenblocks;

void __near R_Init(void)
{
	Z_QuickMapRender();
	Z_QuickMapLumpInfo();

	R_InitData();
	DEBUG_PRINT("..");
	// viewwidth / viewheight / detailLevel are set by the defaults

	R_SetViewSize(screenblocks, detailLevel);
	DEBUG_PRINT("...");
	//R_InitLightTables();

	Z_QuickMapPhysics();
	
	skyflatnum = R_FlatNumForName("F_SKY1");

	DEBUG_PRINT(".");

	}

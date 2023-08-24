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
    short       originx;
    short       originy;
    short       patch;
    short       stepdir;
    short       colormap;
} mappatch_t;


//
// Texture definition.
// A DOOM wall texture is a list of patches
// which are to be combined in a predefined order.
//
typedef struct
{
    char                name[8];
    boolean             masked; 
    short               width;
    short               height;
    void                **columndirectory;      // OBSOLETE
    short               patchcount;
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
    int         originx;        
    int         originy;
    int         patch;
} texpatch_t;


// A maptexturedef_t describes a rectangular texture,
//  which is composed of one or more mappatch_t structures
//  that arrange graphic patches.
typedef struct
{
    // Keep name for switch changing, etc.
    char        name[8];                
    short       width;
    short       height;
    
    // All the patches[patchcount]
    //  are drawn back to front into the cached texture.
    short       patchcount;
    texpatch_t  patches[1];             
    
} texture_t;



int             firstflat;
int             lastflat;
int             numflats;

int             firstpatch;
int             lastpatch;
int             numpatches;

int             firstspritelump;
int             lastspritelump;
int             numspritelumps;

int             numtextures;
//texture_t**   textures;

MEMREF  texturesRef;				// texture_t**

MEMREF  texturewidthmaskRef;		// int*
// needed for texture pegging
MEMREF  textureheightRef;		    // fixed_t*
MEMREF  texturecompositesizeRef;	// int*
MEMREF  texturecolumnlumpRef;		// short**
MEMREF	texturecolumnofsRef;		// unsigned short **
MEMREF  texturecompositeRef;        // byte**



/*
int*                    texturewidthmask;
// needed for texture pegging
fixed_t*                textureheight;          
int*                    texturecompositesize;
short**                 texturecolumnlump;
unsigned short**        texturecolumnofs;
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
( column_t*     patch,
  byte*         cache,
  int           originy,
  int           cacheheight )
{
    int         count;
    int         position;
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
            memcpy (cache + position, source, count);
                
        patch = (column_t *)(  (byte *)patch + patch->length + 4); 
    }
}



//
// R_GenerateComposite
// Using the texture definition,
//  the composite texture is created from the patches,
//  and each column is cached.
//
void R_GenerateComposite(int texnum)
{
	byte*               block;
	texpatch_t*         patch;
	patch_t*            realpatch;
	int                 x;
	int                 x1;
	int                 x2;
	int                 i;
	column_t*           patchcol;
	short*              collump;
	unsigned short*		colofs;
	

	MEMREF* textures =				(MEMREF*)	Z_LoadBytesFromEMS(texturesRef);

	MEMREF* texturecolumnlump =		(MEMREF*)	Z_LoadBytesFromEMS(texturecolumnlumpRef);
	MEMREF*	texturecolumnofs =		(MEMREF*)	Z_LoadBytesFromEMS(texturecolumnofsRef);
	MEMREF* texturecomposite =		(MEMREF*)Z_LoadBytesFromEMS(texturecompositeRef);

	int* texturecompositesize =		(int*)		Z_LoadBytesFromEMS(texturecompositesizeRef);

	texture_t* texture =			(texture_t*)Z_LoadBytesFromEMS(textures[texnum]);

	
	texturecomposite[texnum] = Z_MallocEMSNew(texturecompositesize[texnum],
		PU_STATIC,
		0xff, ALLOC_TYPE_TEXTURE);

	

	block =		(byte*) Z_LoadBytesFromEMS(texturecomposite[texnum]);

	collump =   (short*)		 Z_LoadBytesFromEMS(texturecolumnlump[texnum]);
	colofs =	(unsigned short*)Z_LoadBytesFromEMS(texturecolumnofs[texnum]);

	// Composite the columns together.
	patch = texture->patches;

                
    for (i=0 , patch = texture->patches;
         i<texture->patchcount;
         i++, patch++)
    {
		W_CacheLumpNumCheck(patch->patch, 13);
		realpatch = W_CacheLumpNum (patch->patch, PU_CACHE);
        x1 = patch->originx;
        x2 = x1 + SHORT(realpatch->width);

        if (x1<0)
            x = 0;
        else
            x = x1;
        
        if (x2 > texture->width)
            x2 = texture->width;

        for ( ; x<x2 ; x++)
        {
            // Column does not have multiple patches?
            if (collump[x] >= 0)
                continue;
            
            patchcol = (column_t *)((byte *)realpatch
                                    + LONG(realpatch->columnofs[x-x1]));
            R_DrawColumnInCache (patchcol,
                                 block + colofs[x],
                                 patch->originy,
                                 texture->height);
        }
                                                
    }

    // Now that the texture has been built in column cache,
    //  it is purgable from zone memory.

	// TODO: if we free this and the texture handle is still active that's bad?
	Z_ChangeTagEMSNew(texturecomposite[texnum], PU_CACHE);
}



//
// R_GenerateLookup
//
void R_GenerateLookup (int texnum)
{
    texture_t*          texture;
	short				textureRef;
    byte*               patchcount;     // patchcount[texture->width]
    texpatch_t*         patch;  
    patch_t*            realpatch;
    int                 x;
    int                 x1;
    int                 x2;
    int                 i;
    short*              collump;
    unsigned short*     colofs;



	MEMREF* textures =					(MEMREF*) Z_LoadBytesFromEMS(texturesRef);
	MEMREF* texturecolumnlump =			(MEMREF*) Z_LoadBytesFromEMS(texturecolumnlumpRef);

	MEMREF* texturecolumnofs =			(MEMREF*) Z_LoadBytesFromEMS(texturecolumnofsRef);
	MEMREF* texturecomposite =			(MEMREF*) Z_LoadBytesFromEMS(texturecompositeRef);

	int* texturecompositesize =			(int*)    Z_LoadBytesFromEMS(texturecompositesizeRef);


	fixed_t* textureheight = (fixed_t*)Z_LoadBytesFromEMS(textureheightRef);

	textureRef = textures[texnum];
	texture = (texture_t*)Z_LoadBytesFromEMS(textureRef);
	 

    // Composited texture not created yet.
    texturecomposite[texnum] = 65535; // ugly hack, but what else can i do here ...?
    texturecompositesize[texnum] = 0;

    collump = (short*) Z_LoadBytesFromEMS(texturecolumnlump[texnum]);
    colofs =  (unsigned short*)Z_LoadBytesFromEMS(texturecolumnofs[texnum]);
    
    // Now count the number of columns
    //  that are covered by more than one patch.
    // Fill in the lump / offset, so columns
    //  with only a single patch are all done.
    patchcount = (byte *)alloca (texture->width);
    memset (patchcount, 0, texture->width);
    patch = texture->patches;
                
    for (i=0 , patch = texture->patches;
         i<texture->patchcount;
         i++, patch++)
    {
		W_CacheLumpNumCheck(patch->patch, 14);
		realpatch = W_CacheLumpNum (patch->patch, PU_CACHE);
        x1 = patch->originx;
        x2 = x1 + SHORT(realpatch->width);
        
        if (x1 < 0)
            x = 0;
        else
            x = x1;

        if (x2 > texture->width)
            x2 = texture->width;
        for ( ; x<x2 ; x++)
        {
            patchcount[x]++;
            collump[x] = patch->patch;
            colofs[x] = LONG(realpatch->columnofs[x-x1])+3;
        }
    }
        
    for (x=0 ; x<texture->width ; x++)
    {
        if (!patchcount[x])
        {
            printf ("R_GenerateLookup: column without a patch (%s)\n",
                    texture->name);
            return;
        }
        // I_Error ("R_GenerateLookup: column without a patch");
        
        if (patchcount[x] > 1)
        {
            // Use the cached block.
            collump[x] = -1;    
            colofs[x] = texturecompositesize[texnum];
            
            if (texturecompositesize[texnum] > 0x10000-texture->height)
            {
                I_Error ("R_GenerateLookup: texture %i is >64k",
                         texnum);
            }
            
            texturecompositesize[texnum] += texture->height;
        }
    }   
}




//
// R_GetColumn
//
byte*
R_GetColumn
( int           tex,
  int           col )
{
    int         lump;
    int         ofs;
        
	int* texturewidthmask =				(int*)Z_LoadBytesFromEMS(texturewidthmaskRef);

	MEMREF* texturecolumnlumpTex =		(MEMREF*)Z_LoadBytesFromEMS(texturecolumnlumpRef);
	MEMREF* texturecolumnofsTex =		(MEMREF*)Z_LoadBytesFromEMS(texturecolumnofsRef);

	short* texturecolumnlump =			(short*)Z_LoadBytesFromEMS(texturecolumnlumpTex[tex]);
	unsigned short* texturecolumnofs =	(unsigned short*)Z_LoadBytesFromEMS(texturecolumnofsTex[tex]);
	MEMREF* texturecomposite =			(MEMREF*)Z_LoadBytesFromEMS(texturecompositeRef);

	byte* texturecompositebytes;
	col &= texturewidthmask[tex];
    lump = texturecolumnlump[col];
    ofs = texturecolumnofs[col];

	// note: this currently mixes W_CacheLumpNum method and EMS memory method...  might be bad
    
	if (lump > 0) {
		W_CacheLumpNumCheck(lump, 15);
		return (byte *)W_CacheLumpNum(lump, PU_CACHE) + ofs;
	}

	if (texturecomposite[tex] == 65535) {
		R_GenerateComposite(tex);
	}
	texturecompositebytes = (byte*)Z_LoadBytesFromEMS(texturecomposite[tex]);

    return texturecompositebytes + ofs;
}




//
// R_InitTextures
// Initializes the texture list
//  with the textures from the world map.
//
void R_InitTextures (void)
{
    maptexture_t*       mtexture;
	short				textureRef;
    texture_t*          texture;
    mappatch_t*         mpatch;
    texpatch_t*         patch;

    int                 i;
    int                 j;

    int*                maptex;
    int*                maptex2;
    int*                maptex1;
    
    char                name[9];
    char*               names;
    char*               name_p;
    
    int*                patchlookup;
    
    int                 totalwidth;
    int                 nummappatches;
    int                 offset;
    int                 maxoff;
    int                 maxoff2;
    int                 numtextures1;
    int                 numtextures2;

    int*                directory;
    
    int                 temp1;
    int                 temp2;
    int                 temp3;

	int*                    texturewidthmask;
	// needed for texture pegging
	fixed_t*                textureheight;
	int*                    texturecompositesize;
	MEMREF *                 texturecolumnlump;
	MEMREF *        texturecolumnofs;
	MEMREF *        texturecomposite;
	MEMREF*				textures;
	int * texturetranslation;



    
    // Load the patch names from pnames.lmp.
    name[8] = 0;        
    names = W_CacheLumpName ("PNAMES", PU_STATIC);
    nummappatches = LONG ( *((int *)names) );
    name_p = names+4;
    patchlookup = alloca (nummappatches*sizeof(*patchlookup));

    for (i=0 ; i<nummappatches ; i++)
    {
        strncpy (name,name_p+i*8, 8);
        patchlookup[i] = W_CheckNumForName (name);
    }
    Z_Free (names);
    
    // Load the map texture definitions from textures.lmp.
    // The data is contained in one or two lumps,
    //  TEXTURE1 for shareware, plus TEXTURE2 for commercial.
    maptex = maptex1 = W_CacheLumpName ("TEXTURE1", PU_STATIC);
    numtextures1 = LONG(*maptex);
    maxoff = W_LumpLength (W_GetNumForName ("TEXTURE1"));
    directory = maptex+1;

        
    if (W_CheckNumForName ("TEXTURE2") != -1)
    {
        maptex2 = W_CacheLumpName ("TEXTURE2", PU_STATIC);
        numtextures2 = LONG(*maptex2);
        maxoff2 = W_LumpLength (W_GetNumForName ("TEXTURE2"));
    }
    else
    {
        maptex2 = NULL;
        numtextures2 = 0;
        maxoff2 = 0;
    }
    numtextures = numtextures1 + numtextures2;
        
    texturesRef				= Z_MallocEMSNew(numtextures * 4, PU_STATIC, 0, ALLOC_TYPE_TEXTURE);
	texturecolumnlumpRef	= Z_MallocEMSNew(numtextures * 4, PU_STATIC, 0, ALLOC_TYPE_TEXTURE);
    texturecolumnofsRef		= Z_MallocEMSNew(numtextures * 4, PU_STATIC, 0, ALLOC_TYPE_TEXTURE);
    texturecompositeRef		= Z_MallocEMSNew(numtextures * 4, PU_STATIC, 0, ALLOC_TYPE_TEXTURE);
    texturecompositesizeRef = Z_MallocEMSNew(numtextures * 4, PU_STATIC, 0, ALLOC_TYPE_TEXTURE);
    texturewidthmaskRef		= Z_MallocEMSNew(numtextures * 4, PU_STATIC, 0, ALLOC_TYPE_TEXTURE);
    textureheightRef		= Z_MallocEMSNew(numtextures * 4, PU_STATIC, 0, ALLOC_TYPE_TEXTURE);

	textures			 = (MEMREF*)  Z_LoadBytesFromEMS(texturesRef);
	texturecolumnlump	 = (MEMREF*)  Z_LoadBytesFromEMS(texturecolumnlumpRef);
	texturecolumnofs	 = (MEMREF*)  Z_LoadBytesFromEMS(texturecolumnofsRef);
	texturecomposite	 = (MEMREF*)  Z_LoadBytesFromEMS(texturecompositeRef);
	texturecompositesize = (int*)			  Z_LoadBytesFromEMS(texturecompositesizeRef);
	texturewidthmask	 = (int*)			  Z_LoadBytesFromEMS(texturewidthmaskRef);
	textureheight		 = (fixed_t*)		  Z_LoadBytesFromEMS(textureheightRef);
 

    totalwidth = 0;
    
    //  Really complex printing shit...
    temp1 = W_GetNumForName ("S_START");  // P_???????
    temp2 = W_GetNumForName ("S_END") - 1;
    temp3 = ((temp2-temp1+63)/64) + ((numtextures+63)/64);
    printf("[");
    for (i = 0; i < temp3; i++)
        printf(" ");
    printf("         ]");
    for (i = 0; i < temp3; i++)
        printf("\x8");
    printf("\x8\x8\x8\x8\x8\x8\x8\x8\x8\x8");   
        
    for (i=0 ; i<numtextures ; i++, directory++)
    {
        if (!(i&63))
            printf (".");

        if (i == numtextures1)
        {
            // Start looking in second texture file.
            maptex = maptex2;
            maxoff = maxoff2;
            directory = maptex+1;
        }
                
        offset = LONG(*directory);

        if (offset > maxoff)
            I_Error ("R_InitTextures: bad texture directory");
        
        mtexture = (maptexture_t *) ( (byte *)maptex + offset);

		
		textureRef = Z_MallocEMSNew(sizeof(texture_t)
				+ sizeof(texpatch_t)*(SHORT(mtexture->patchcount) - 1),
				PU_STATIC, 0, ALLOC_TYPE_TEXTURE);
            
		textures[i] = textureRef;
		texture = (texture_t*) Z_LoadBytesFromEMS(textureRef);
        
        texture->width = SHORT(mtexture->width);
        texture->height = SHORT(mtexture->height);
        texture->patchcount = SHORT(mtexture->patchcount);

        memcpy (texture->name, mtexture->name, sizeof(texture->name));
        mpatch = &mtexture->patches[0];
        patch = &texture->patches[0];

        for (j=0 ; j<texture->patchcount ; j++, mpatch++, patch++)
        {
            patch->originx = SHORT(mpatch->originx);
            patch->originy = SHORT(mpatch->originy);
            patch->patch = patchlookup[SHORT(mpatch->patch)];
            if (patch->patch == -1)
            {
                I_Error ("R_InitTextures: Missing patch in texture %s",
                         texture->name);
            }
        }    

        texturecolumnlump[i] = Z_MallocEMSNew (texture->width*2, PU_STATIC,0, ALLOC_TYPE_TEXTURE);
        texturecolumnofs[i]  = Z_MallocEMSNew (texture->width*2, PU_STATIC,0, ALLOC_TYPE_TEXTURE);

        j = 1;
        while (j*2 <= texture->width)
            j<<=1;

        texturewidthmask[i] = j-1;
        textureheight[i] = texture->height<<FRACBITS;
                
        totalwidth += texture->width;
    }

    Z_Free (maptex1);
    if (maptex2)
        Z_Free (maptex2);
    
    // Precalculate whatever possible.  
    for (i=0 ; i<numtextures ; i++)
        R_GenerateLookup (i);
    
    // Create translation table for global animation.
    texturetranslationRef = Z_MallocEMSNew ((numtextures+1)*4, PU_STATIC, 0, ALLOC_TYPE_TEXTURE_TRANSLATION);
	texturetranslation = (int*) Z_LoadBytesFromEMS(texturetranslationRef);

    for (i=0 ; i<numtextures ; i++)
        texturetranslation[i] = i;
}



//
// R_InitFlats
//
void R_InitFlats (void)
{
    int         i;
	int * flattranslation;

    firstflat = W_GetNumForName ("F_START") + 1;
    lastflat = W_GetNumForName ("F_END") - 1;
    numflats = lastflat - firstflat + 1;
        
    // Create translation table for global animation.
    flattranslationRef = Z_MallocEMSNew((numflats+1)*4, PU_STATIC, 0, ALLOC_TYPE_FLAT_TRANSLATION);
	flattranslation = (int*)Z_LoadBytesFromEMS(flattranslationRef);
    
    for (i=0 ; i<numflats ; i++)
        flattranslation[i] = i;
}


//
// R_InitSpriteLumps
// Finds the width and hoffset of all sprites in the wad,
//  so the sprite does not need to be cached completely
//  just for having the header info ready during rendering.
//
void R_InitSpriteLumps (void)
{
    int         i;
    patch_t     *patch;
	fixed_t     *spritewidth;
	fixed_t     *spriteoffset;
	fixed_t     *spritetopoffset;

        
    firstspritelump = W_GetNumForName ("S_START") + 1;
    lastspritelump = W_GetNumForName ("S_END") - 1;
    
    numspritelumps = lastspritelump - firstspritelump + 1;
    spritewidthRef = Z_MallocEMSNew (numspritelumps*4, PU_STATIC, 0, ALLOC_TYPE_SPRITE);
    spriteoffsetRef = Z_MallocEMSNew (numspritelumps*4, PU_STATIC, 0, ALLOC_TYPE_SPRITE);
    spritetopoffsetRef = Z_MallocEMSNew (numspritelumps*4, PU_STATIC, 0, ALLOC_TYPE_SPRITE);
        
	spritewidth = (fixed_t*)Z_LoadBytesFromEMS(spritewidthRef);
	spriteoffset = (fixed_t*)Z_LoadBytesFromEMS(spriteoffsetRef);
	spritetopoffset = (fixed_t*)Z_LoadBytesFromEMS(spritetopoffsetRef);

    for (i=0 ; i< numspritelumps ; i++)
    {
        if (!(i&63))
            printf (".");

		W_CacheLumpNumCheck(firstspritelump + i, 16);
		patch = W_CacheLumpNum (firstspritelump+i, PU_CACHE);
        spritewidth[i] = SHORT(patch->width)<<FRACBITS;
        spriteoffset[i] = SHORT(patch->leftoffset)<<FRACBITS;
        spritetopoffset[i] = SHORT(patch->topoffset)<<FRACBITS;
    }
}



//
// R_InitColormaps
//
void R_InitColormaps (void)
{
    int lump, length;
    
    // Load in the light tables, 
    //  256 byte align tables.
    lump = W_GetNumForName("COLORMAP"); 
    length = W_LumpLength (lump) + 255; 

	// todo: big hack.. Making colormaps work in EMS is a major pain. tons of pointers being passed back and forth.
	// you can convert these to offsets, working off the base pointer of the original allocation which i have done..
	// but ultimately the light values are used in 386-style asm in planar.obj (see dc_source and ds_source and
	// _ds_colormap) so until that asm is redone im not sure how to make colormaps work off the heap. For performance
	// reasons it may even be best to keep it in a static allocation...
	colormaps = (byte*)colormapbytes;  
    colormaps = (byte *)( ((int)colormaps + 255)&~0xff); 

	//printf("Size %i", length);
	//I_Error("size %i", length);

    W_ReadLump (lump,colormaps); 
}



//
// R_InitData
// Locates all the lumps
//  that will be used by all views
// Must be called after W_Init.
//
void R_InitData (void)
{
    R_InitTextures ();
    printf (".");
    R_InitFlats ();
    printf (".");
    R_InitSpriteLumps ();
    printf (".");
    R_InitColormaps ();
}



//
// R_FlatNumForName
// Retrieval, get a flat number for a flat name.
//
int R_FlatNumForName (char* name)
{
    int         i;
    char        namet[9];

    i = W_CheckNumForName (name);

    if (i == -1)
    {
        namet[8] = 0;
        memcpy (namet, name,8);
        I_Error ("R_FlatNumForName: %s not found",namet);
    }
    return i - firstflat;
}




//
// R_CheckTextureNumForName
// Check whether texture is available.
// Filter out NoTexture indicator.
//
int     R_CheckTextureNumForName (char *name)
{
    int         i;
	short* textures = (short*)Z_LoadBytesFromEMS(texturesRef);
	texture_t* texture;
    // "NoTexture" marker.
    if (name[0] == '-')         
        return 0;
                


	for (i = 0; i < numtextures; i++) {
		texture = (texture_t*)Z_LoadBytesFromEMS(textures[i]);
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
int     R_TextureNumForName (char* name)
{
    int         i;
        
    i = R_CheckTextureNumForName (name);

    if (i==-1)
    {
        I_Error ("R_TextureNumForName: %s not found",
                 name);
    }
    return i;
}




//
// R_PrecacheLevel
// Preloads all relevant graphics for the level.
//
int             flatmemory;
int             texturememory;
int             spritememory;

void R_PrecacheLevel (void)
{
    char*               flatpresent;
    char*               texturepresent;
    char*               spritepresent;

    int                 i;
    int                 j;
    int                 k;
    int                 lump;
    
    texture_t*          texture;
    thinker_t*          th;
    spriteframe_t*      sf;
	spritedef_t*		sprites;
	spriteframe_t*		spriteframes;

	MEMREF* textures = (MEMREF*)Z_LoadBytesFromEMS(texturesRef);




    if (demoplayback)
        return;
    
    // Precache flats.
    flatpresent = alloca(numflats);
    memset (flatpresent,0,numflats);    

    for (i=0 ; i<numsectors ; i++)
    {
        flatpresent[sectors[i].floorpic] = 1;
        flatpresent[sectors[i].ceilingpic] = 1;
    }
        
    flatmemory = 0;

    for (i=0 ; i<numflats ; i++)
    {
        if (flatpresent[i])
        {
            lump = firstflat + i;
            flatmemory += lumpinfo[lump].size;
			W_CacheLumpNumCheck(lump, 17);
			W_CacheLumpNum(lump, PU_CACHE);
        }
    }
    
    // Precache textures.
    texturepresent = alloca(numtextures);
    memset (texturepresent,0, numtextures);
        
    for (i=0 ; i<numsides ; i++)
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
        
    texturememory = 0;
    for (i=0 ; i<numtextures ; i++)
    {
        if (!texturepresent[i])
            continue;

		texture = (texture_t*)Z_LoadBytesFromEMS(textures[i]);
        
        for (j=0 ; j<texture->patchcount ; j++)
        {
            lump = texture->patches[j].patch;
            texturememory += lumpinfo[lump].size;
			if (W_CacheLumpNumCheck(lump, 18)) {
				printf("Crash %i %i %i", j, lump, texture->patchcount);
				I_Error("Crash %i %i %i", j, lump, texture->patchcount);
			}
			W_CacheLumpNum(lump , PU_CACHE);
        }
    }
    
    // Precache sprites.
    spritepresent = alloca(numsprites);
    memset (spritepresent,0, numsprites);
        
    for (th = thinkercap.next ; th != &thinkercap ; th=th->next)
    {
        if (th->function.acp1 == (actionf_p1)P_MobjThinker)
            spritepresent[((mobj_t *)th)->sprite] = 1;
    }

    spritememory = 0;
	//todo does this have to be pulled into the for loop
	sprites = Z_LoadBytesFromEMS(spritesRef);
    for (i=0 ; i<numsprites ; i++)
    {
        if (!spritepresent[i])
            continue;
		spriteframes = (spriteframe_t*) Z_LoadBytesFromEMS(sprites[i].spriteframesRef);

        for (j=0 ; j<sprites[i].numframes ; j++)
        {
            sf = &spriteframes[j];
            for (k=0 ; k<8 ; k++)
            {
                lump = firstspritelump + sf->lump[k];
                spritememory += lumpinfo[lump].size;
				W_CacheLumpNumCheck(lump, 19);
				W_CacheLumpNum(lump , PU_CACHE);
            }
        }
    }
}





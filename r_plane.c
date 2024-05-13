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
//	Here is a core component: drawing the floors and ceilings,
//	 while maintaining a per column clipping list only.
//	Moreover, the sky areas have to be determined.
//

#include <stdlib.h>

#include "i_system.h"
#include "z_zone.h"
#include "w_wad.h"

#include "doomdef.h"
#include "doomstat.h"

#include "r_local.h"
#include <dos.h>
#include "memory.h"





//
// opening
//

// Here comes the obnoxious "visplane".



int16_t				lastvisplane;
int16_t				floorplaneindex;
int16_t				ceilingplaneindex;


// ?
 uint16_t 		lastopening;


//
// Clip values are the solid pixel bounding the range.
//  floorclip starts out SCREENHEIGHT
//  ceilingclip starts out -1
//
//int16_t			*floorclip;// [SCREENWIDTH];
//int16_t			*ceilingclip;// [SCREENWIDTH];

//
// spanstart holds the start of a plane span
// initialized to 0 at start
//
//int16_t			*spanstart;// [SCREENHEIGHT];
//int32_t			spanstop[SCREENHEIGHT];

//
// texture mapping
//
uint16_t __far*	planezlight;
fixed_t			planeheight;

fixed_t			basexscale;
fixed_t			baseyscale;

int8_t currentemsvisplanepage = 0; 



//
// R_MapPlane
//
// Uses global vars:
//  planeheight
//  ds_source
//  basexscale
//  baseyscale
//  viewx
//  viewy
//
// BASIC PRIMITIVE
//


/*
void checkoffset(void __far* ptr, int16_t check){
	uint16_t seg = FP_SEG(ptr);
	uint16_t off = FP_OFF(ptr);
	uint32_t total = seg << 4 + off;
	if (total > 0x90000){
		I_Error("ptr too big %x:%x %i", seg, off, check);
	}

}
*/

void
R_MapPlane
( byte		y,
  int16_t		x1,
  int16_t		x2 ) {
    fineangle_t	angle;
    fixed_t	distance;
    fixed_t	length;
	uint8_t	index;
 

    if (planeheight != cachedheight[y]) {
		cachedheight[y] = planeheight;
		distance = cacheddistance[y] = FixedMul (planeheight, yslope[y]);
		ds_xstep = cachedxstep[y] = FixedMul (distance,basexscale);
		ds_ystep = cachedystep[y] = FixedMul (distance,baseyscale);
    } else {
		distance = cacheddistance[y];
		ds_xstep = cachedxstep[y];
		ds_ystep = cachedystep[y];
    }
	
    length = FixedMul (distance,distscale[x1]);
	angle = MOD_FINE_ANGLE(viewangle_shiftright3+ xtoviewangle[x1]);

	ds_xfrac = viewx.w + FixedMulTrig(finecosine[angle], length );
    ds_yfrac = -viewy.w - FixedMulTrig(finesine[angle], length );

	if (fixedcolormap) {
		dc_colormap = MK_FP(colormapssegment, fixedcolormap);

	}
	else {
		index = distance >> LIGHTZSHIFT;

		if (index >= MAXLIGHTZ) {
			index = MAXLIGHTZ - 1;
		}

		ds_colormap = MK_FP(colormapssegment, planezlight[index]);
	}

	ds_y = y;
	ds_x1 = x1;
	ds_x2 = x2;

	// high or low detail
	spanfunc();
}



//
// R_ClearPlanes
// At begining of frame.
//
void R_ClearPlanes (void)
{
    int16_t		i;
    fineangle_t	angle;
    
    // opening / clipping determination
    for (i=0 ; i<viewwidth ; i++) {
		floorclip[i] = viewheight;
		ceilingclip[i] = -1;
    }

    lastvisplane = 0;
    lastopening = 0;

    // texture calculation
    FAR_memset (cachedheight, 0, sizeof(fixed_t) * SCREENHEIGHT);

    // left to right mapping
	angle = MOD_FINE_ANGLE(viewangle_shiftright3 - FINE_ANG90) ;

    // scale will be unit scale at SCREENWIDTH/2 distance
    basexscale = FixedDivWholeB(finecosine[angle],centerxfrac.w);
    baseyscale = -FixedDivWholeB(finesine[angle],centerxfrac.w);

}


//
// R_FindPlane
//

//todo can we change height to 16 bit? the only tricky part is when viewz is involved, but maybe
// view z can be 16 too. -sq
int16_t 
R_FindPlane
( fixed_t   	height,
  uint8_t		picnum,
  uint8_t		lightlevel )
{
    visplane_t __far*	check;
    visplaneheader_t __far *checkheader;
	int16_t i;
    if (picnum == skyflatnum) {
		height = 0;			// all skys map together
		lightlevel = 0;
    }
	
    for (i = 0; i<=lastvisplane; i++) {
		
		checkheader = &visplaneheaders[i];
	
	
		// we do this to avoid having to re-set check below, which is extra code.
		if (i == lastvisplane){
			break;
		}
		

		if (height == checkheader->height
			&& picnum == checkheader->picnum
			&& lightlevel == checkheader->lightlevel) {
				break;
		}

    }
    
			
    if (i < lastvisplane){
		return i;
	}


	// didnt find it, make a new visplane

    lastvisplane++;

    checkheader->height = height;
    checkheader->picnum = picnum;
    checkheader->lightlevel = lightlevel;
    checkheader->minx = SCREENWIDTH;
    checkheader->maxx = -1;
	check = &visplanes_8400[i];

    if (i >= MAX_8400_VISPLANES){
		//check = &visplanes_4C00[i-MAX_8400_VISPLANES];
			//todo page
		I_Error("98");
	}
	FAR_memset (check->top,0xff,sizeof(check->top));

    return i;

}


//
// R_CheckPlane
//
int16_t
R_CheckPlane
( int16_t		index,
  int16_t		start,
  int16_t		stop )
{
    int16_t		intrl;
    int16_t		intrh;
    int16_t		unionl;
    int16_t		unionh;
    int16_t		x;
	visplane_t __far*	pl;
	visplaneheader_t __far* plheader;
	FILE *fp;

	plheader = &visplaneheaders[index];
	pl = &visplanes_8400[index];
    if (index >= MAX_8400_VISPLANES){
		//pl = &visplanes_4C00[index-MAX_8400_VISPLANES];
			//todo page
		I_Error("97");

	}


	
    if (start < plheader->minx) {
		intrl = plheader->minx;
		unionl = start;
    } else {
		unionl = plheader->minx;
		intrl = start;
    }
	
    if (stop > plheader->maxx) {
		intrh = plheader->maxx;
		unionh = stop;
    } else {
		unionh = plheader->maxx;
		intrh = stop;
    }


	for (x=intrl ; x<= intrh && pl->top[x]==0xff ; x++)
		;

    if (x > intrh) {
		plheader->minx = unionl;
		plheader->maxx = unionh;

		// use the same one
		return index;		
    }

    // make a new visplane

	// todo clean up this pl thing
	visplaneheaders[lastvisplane].height = plheader->height;
	visplaneheaders[lastvisplane].picnum = plheader->picnum;
	visplaneheaders[lastvisplane].lightlevel = plheader->lightlevel;
	
	plheader = &visplaneheaders[lastvisplane];
	pl = &visplanes_8400[lastvisplane];
    if (lastvisplane >= MAX_8400_VISPLANES){
		//pl = &visplanes_4C00[lastvisplane-MAX_8400_VISPLANES];
			//todo page
		I_Error("96");

	}

	plheader->minx = start;
	plheader->maxx = stop;
	FAR_memset (pl->top,0xff,sizeof(pl->top));

	return lastvisplane++;
}

int16_t currentflatpage[4] = { -1, -1, -1, -1 };
// there can be 4 flats (4k each) per ems page (16k each). Keep track of how many are allocated here.
int8_t allocatedflatsperpage[NUM_FLAT_CACHE_PAGES];
 //
// R_DrawPlanes
// At the end of each frame.
//
void R_DrawPlanes (void)
{
    visplane_t __far*		pl;
    uint8_t			light;
    int16_t			x;
    int16_t			stop;
    fineangle_t			angle;
	byte t1, b1, t2, b2;
	int16_t			i;
	int8_t			j;

    visplaneheader_t __far*	plheader;
	

	int16_t effectivepagenumber = 0;
	uint8_t usedflatindex;
	boolean flatunloaded = false;
	byte __far* src;
	int16_t flatcacheindex = 0;
	int16_t lastflatcacheindicesused[3] = {3, 2, 1}; // initialized so that allocation order is 0 1 2

    for (i = 0; i < lastvisplane ; i++) {
		plheader = &visplaneheaders[i];
		pl = &visplanes_8400[i];
		if (i >= MAX_8400_VISPLANES){
			//pl = &visplanes_4C00[i-MAX_8400_VISPLANES];
			//todo page
			I_Error("95");

		}

		if (plheader->minx > plheader->maxx)
			continue;

		// sky flat
		if (plheader->picnum == skyflatnum) {
			dc_iscale = pspriteiscale>>detailshift;
			
			// Sky is allways drawn full bright,
			//  i.e. colormaps[0] is used.
			// Because of this hack, sky is not affected
			//  by INVUL inverse mapping.
			dc_colormap = colormaps;
			dc_texturemid.h.intbits = 100;
			dc_texturemid.h.fracbits = 0;

			for (x=plheader->minx ; x <= plheader->maxx ; x++) {
				dc_yl = pl->top[x];
				dc_yh = pl->bottom[x];				

				if (dc_yl <= dc_yh) {
				 
					angle = MOD_FINE_ANGLE(viewangle_shiftright3 + xtoviewangle[x]) >> 3;
					dc_x = x;
					dc_source = R_GetColumn(skytexture, angle);
					colfunc();

				}
			}
			continue;
		}
		
		usedflatindex = flatindex[flattranslation[plheader->picnum]];
		if (usedflatindex == 0xFF) {
			// load if not loaded

			for (j=0; j < (NUM_FLAT_CACHE_PAGES);j++){
				if (allocatedflatsperpage[j]<4){
					usedflatindex = 4*j + allocatedflatsperpage[j];
					allocatedflatsperpage[j]++;
					goto foundflat;
				}
			}
			// todo figure out what to do with firstunused flat etc
			usedflatindex = R_EvictCacheEMSPage(0, CACHETYPE_FLAT);
			// mult by 4, going from flat index to page index first index of the flat in the evicted page.
			usedflatindex = usedflatindex << 2;

			foundflat:

			flatindex[flattranslation[plheader->picnum]] = usedflatindex;
			flatunloaded = true;
		}

		effectivepagenumber = (usedflatindex >> 2) + FIRST_FLAT_CACHE_LOGICAL_PAGE;
 
		if (currentflatpage[0] == effectivepagenumber) {
			flatcacheindex = 0;
		} else if (currentflatpage[1] == effectivepagenumber) {
			flatcacheindex = 1;
		} else if (currentflatpage[2] == effectivepagenumber) {
			flatcacheindex = 2;
		} else if (currentflatpage[3] == effectivepagenumber) {
			flatcacheindex = 3;
		} else {
			/*
			// LRU on evicition.. not doing this above as we should though
			for (i = 0; i < 3; i++) {
				if (lastflatcacheindicesused[0] != i && lastflatcacheindicesused[1] != i) {
				//if (lastflatcacheindicesused[0] != i && lastflatcacheindicesused[1] != i && lastflatcacheindicesused[2] != i) {
					flatcacheindex = i;
					break;
				}
			}
			*/


			if (lastflatcacheindicesused[0] != 0 && lastflatcacheindicesused[1] != 0) {
				flatcacheindex = 0;
			} else if (lastflatcacheindicesused[0] != 1 && lastflatcacheindicesused[1] != 1) {
				flatcacheindex = 1;
			} else if (lastflatcacheindicesused[0] != 2 && lastflatcacheindicesused[1] != 2) {
				flatcacheindex = 2;
			} else {
				flatcacheindex = 3;
			}

			currentflatpage[flatcacheindex] = effectivepagenumber;
			Z_QuickMapFlatPage(effectivepagenumber, flatcacheindex);
		}

		if (lastflatcacheindicesused[0] != flatcacheindex) {
			if (lastflatcacheindicesused[1] != flatcacheindex) {
				lastflatcacheindicesused[2] = lastflatcacheindicesused[1];
			}
			lastflatcacheindicesused[1] = lastflatcacheindicesused[0];
			lastflatcacheindicesused[0] = flatcacheindex;
		}

		R_MarkCacheLRU(usedflatindex >> 2, 0, CACHETYPE_FLAT);
		
		src = MK_FP(FLAT_CACHE_PAGE[flatcacheindex], MULT_4096[usedflatindex & 0x03]);

		// load if necessary
		if (flatunloaded){
#ifdef CHECK_FOR_ERRORS
			int16_t lump = firstflat + flattranslation[plheader->picnum];
			if (lump < firstflat || lump > firstflat + numflats) {
				I_Error("bad flat? %i", lump);
			}
#endif
		 
			W_CacheLumpNumDirect(firstflat + flattranslation[plheader->picnum], src);
		}
		
		// regular flat
		ds_source = src;

		// works but slow?
		//ds_source = R_GetFlat(firstflat + flattranslation[plheader->picnum]);
		
		planeheight = labs(plheader->height - viewz.w);
		light = (plheader->lightlevel >> LIGHTSEGSHIFT)+extralight;

		if (light >= LIGHTLEVELS){
			light = LIGHTLEVELS-1;
		}

		// quicker shift 7..
		planezlight = &zlight[lightshift7lookup[light]];
 
		pl->top[plheader->maxx+1] = 0xff;
		pl->top[plheader->minx-1] = 0xff;

		stop = plheader->maxx + 1;
		for (x=plheader->minx ; x<= stop ; x++) {
			t1 = pl->top[x - 1];
			b1 = pl->bottom[x - 1];
			t2 = pl->top[x];
			b2 = pl->bottom[x];

			while (t1 < t2 && t1 <= b1) {
				R_MapPlane(t1, spanstart[t1], x - 1);
				t1++;
			}
			while (b1 > b2 && b1 >= t1) {
				R_MapPlane(b1, spanstart[b1], x - 1);
				b1--;
			}

			while (t2 < t1 && t2 <= b2) {
				spanstart[t2] = x;
				t2++;
			}
			while (b2 > b1 && b2 >= t2) {
				spanstart[b2] = x;
				b2--;
			}

		}
		
    }

	

}



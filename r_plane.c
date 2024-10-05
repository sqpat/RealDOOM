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
#include "d_math.h"
#include <conio.h>
#include <dos.h>
#include "m_memory.h"
#include "m_near.h"





//
// opening
//

// Here comes the obnoxious "visplane".




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


//void __far R_MapPlane ( byte y, int16_t x1, int16_t x2 );


//
// R_MapPlane
//
// Uses global vars:
//  planeheight
//  basexscale
//  baseyscale
//  viewx
//  viewy
//
// BASIC PRIMITIVE
//
/*

fixed_t32	R_FixedMulLocalWrapper (fixed_t32 a, fixed_t32 b);

void __far R_MapPlane ( byte y, int16_t x1, int16_t x2 ) {
    fineangle_t	angle;
    fixed_t	distance;
    fixed_t	length;
	uint8_t	index;
	void (__far* R_DrawSpanPrepCall)(void)  =   ((void    (__far *)(void))  (MK_FP(spanfunc_function_area_segment, R_DrawSpanPrepOffset)));

    if (planeheight != cachedheight[y]) {
		cachedheight[y] = planeheight;
		distance = cacheddistance[y] = R_FixedMulLocalWrapper (planeheight, yslope[y]);
		ds_xstep = cachedxstep[y] = (R_FixedMulLocalWrapper (distance,basexscale));
		ds_ystep = cachedystep[y] = (R_FixedMulLocalWrapper (distance,baseyscale));
    } else {
		distance = cacheddistance[y];
		ds_xstep = cachedxstep[y] ;
		ds_ystep = cachedystep[y] ;
    }
	//ds_xstep <<=  detailshift;
	//ds_ystep <<=  detailshift;
	
    length = R_FixedMulLocalWrapper (distance,distscale[x1]);
	angle = MOD_FINE_ANGLE(viewangle_shiftright3+ xtoviewangle[x1]);

	ds_xfrac = viewx.w + R_FixedMulLocalWrapper(finecosine[angle], length );
    ds_yfrac = -viewy.w - R_FixedMulLocalWrapper(finesine[angle], length );

	if (fixedcolormap) {
		ds_colormap_segment = colormaps_segment;
		ds_colormap_index = fixedcolormap;

	}
	else {
		index = distance >> LIGHTZSHIFT;

		if (index >= MAXLIGHTZ) {
			index = MAXLIGHTZ - 1;
		}

		ds_colormap_segment = colormaps_segment;
		ds_colormap_index = planezlight[index];

	}

	ds_y = y;
	ds_x1 = x1;
	ds_x2 = x2;

	// high or low detail
 
    // seg diff 05b4
	// offset dicc 5b40
	// spanfunc  6aa0
	// colormaps 6cec


	// 6EA0:0000

	// need to remap this? spanfunc should be after colormaps or we cant push IP forward to the func.
	// colormaps will be 6c00 page
	// span will be 6800 page

	//spanfunc();
	R_DrawSpanPrepCall();

}
*/


//
// R_ClearPlanes
// At begining of frame.
//
void __near R_ClearPlanes (void) {
    int16_t		i;
    fineangle_t	angle;
    fixed_t_union temp;
	temp.h.fracbits = 0;
	temp.h.intbits = centerx;
    // opening / clipping determination
    for (i=0 ; i<viewwidth ; i++) {
		floorclip[i] = viewheight;
		ceilingclip[i] = -1;
    }

    lastvisplane = 0;
    lastopening = 0;


    // left to right mapping
	angle = MOD_FINE_ANGLE(viewangle_shiftright3 - FINE_ANG90) ;

    // scale will be unit scale at SCREENWIDTH/2 distance
    basexscale = FixedDivWholeB(finecosine[angle],temp.w);
    baseyscale = -FixedDivWholeB(finesine[angle],temp.w);

}



// we want to cache the variables/logic based around which plane indices are mapped..



// requires pagination and juggling of floor/ceil planes...
visplane_t __far * __near R_HandleEMSPagination(int8_t index, int8_t isceil){

	int8_t usedphyspage;
	int8_t usedvirtualpage = 0;
	uint8_t usedsubindex = index;
	visplane_t __far * pl;


	// mult + modulo
	while (usedsubindex >= VISPLANES_PER_EMS_PAGE){
		usedvirtualpage++;
		usedsubindex -= VISPLANES_PER_EMS_PAGE;
	}

	usedphyspage = usedvirtualpage;

	// check if we need to bother at all with complicated logic (more than 75 visplanes in use)
	if (visplanedirty || (index >= MAX_CONVENTIONAL_VISPLANES)){

		// is this virtual page already in a physical page?
		if (active_visplanes[usedvirtualpage]){
			usedphyspage = active_visplanes[usedvirtualpage]-1;
		} else {
			// need to page it in. lets determine physical page to use.
			// we will page it into phys page 2 if its not already in use by the other page.

			if (isceil){
				if (floorphyspage == 2){
					usedphyspage = 1;
				} else {
					usedphyspage = 2;
				}
			} else {
				if (ceilphyspage == 2){
					usedphyspage = 1;
				} else {
					usedphyspage = 2;
				}
			}

			//I_Error("B");

			Z_QuickMapVisplanePage(usedvirtualpage, usedphyspage);

		}
	}
	pl = (visplane_t __far *) MK_FP(visplanelookupsegments[usedphyspage], visplane_offset[usedsubindex]); 
	
	if (isceil){
		ceilphyspage = usedphyspage;
		ceiltop = pl->top;

	} else {
		floorphyspage = usedphyspage;
		floortop = pl->top;
	}

	 return pl;
}

//
// R_FindPlane
//

//todo can we change height to 16 bit? the only tricky part is when viewz is involved, but maybe
// view z can be 16 too. -sq
int16_t  __near R_FindPlane ( fixed_t   height, uint8_t picnum, uint8_t lightlevel, int8_t isceil ) {
    visplane_t __far*	check;
    visplaneheader_t __far *checkheader;
	int16_t i;
	int16_t_union piclight;
    if (picnum == skyflatnum) {
		height = 0;			// all skys map together
		lightlevel = 0;
    }
	piclight.bu.bytelow = picnum;
	piclight.bu.bytehigh = lightlevel;
	
	
    for (i = 0; i<=lastvisplane; i++) {
		
		checkheader = &visplaneheaders[i];
	
	
		// we do this to avoid having to re-set check below, which is extra code.
		if (i == lastvisplane){
			break;
		}
		

		if (height == checkheader->height
			&& piclight.hu == visplanepiclights[i].pic_and_light) {
				break;
		}

    }
    
			
    if (i < lastvisplane){
		R_HandleEMSPagination(i, isceil);
		return i;
	}


	// didnt find it, make a new visplane. i == lastvisplane currently

    lastvisplane++;

    checkheader->height = height;
    checkheader->minx = SCREENWIDTH;
    checkheader->maxx = -1;
	// using this ugly MK_FP because c compiler seems confused when we use the define array to set...
	visplanepiclights[i].pic_and_light = piclight.hu;


	check = R_HandleEMSPagination(i, isceil);

	FAR_memset (check->top,0xff,SCREENWIDTH);
	FAR_memset (check->bottom,0x00,SCREENWIDTH);
	//todo these bottom memsets cover up for some other infrequent bug
	// where plbot ends up wrong. this is fine, but might be cleaner to
	// fix the actual bug that results from a bottom not being written

//	FAR_memset (check->bottom,0xff,SCREENWIDTH);

    return i;

}


//
// R_CheckPlane
//
int16_t __near R_CheckPlane ( int16_t index, int16_t start, int16_t stop, int8_t isceil ) {
    int16_t		intrl;
    int16_t		intrh;
    int16_t		unionl;
    int16_t		unionh;
    int16_t		x;
	byte  __far*	pltop;
	visplaneheader_t __far* plheader = &visplaneheaders[index];

	// should be active and have already have been paged in...
	if (isceil){
		pltop = ceiltop;
	} else {
		pltop = floortop;
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


	for (x=intrl ; x<= intrh && pltop[x]==0xff ; x++)
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

	visplanepiclights[lastvisplane].pic_and_light = visplanepiclights[index].pic_and_light;

	plheader = &visplaneheaders[lastvisplane];
	plheader->minx = start;
	plheader->maxx = stop;

	pltop = R_HandleEMSPagination(lastvisplane, isceil)->top;
	FAR_memset (pltop,	  0xff,SCREENWIDTH);
	FAR_memset (pltop+322,0x00,SCREENWIDTH);
	//todo these bottom memsets cover up for some other infrequent bug
	// where plbot ends up wrong. this is fine, but might be cleaner to
	// fix the actual bug that results from a bottom not being written
	//FAR_memset (pltop+322,0xff,SCREENWIDTH);

	return lastvisplane++;
}


#define SC_INDEX			0x3C4

void __far R_DrawSkyColumn(int16_t arg_dc_yh, int16_t arg_dc_yl);

/**/
#pragma aux abcdcall parm caller \
                    modify [ax bx cx dx es];

#pragma aux (abcdcall)  R_DrawSkyPlane;
void __far R_DrawSkyPlane(int16_t minx, int16_t maxx, visplane_t __far*		pl);

/*
void __near R_DrawSkyPlane2(int16_t minx, int16_t maxx, visplane_t __far*		pl){
    
	int16_t xoffset;
	int16_t minxbase4 = minx & 0xFFFC;	// knock out the low 2 bits
	for (xoffset = 0; xoffset < 4; xoffset++ ){
		int16_t x = minxbase4 + xoffset;
		if (x < minx)
			x+=4;	// dont underdraw

		outp (SC_INDEX+1,1<<(xoffset));


		for (; x <= maxx ; x+=4) {
			dc_yl = pl->top[x];
			dc_yh = pl->bottom[x];				

			if (dc_yl <= dc_yh) {
				// all sky textures are 256 wide, just need the 0xFF and
				uint16_t texture_x  = ((viewangle_shiftright3 + xtoviewangle[x])) & 0x7F8;
				dc_x = x;

				// here we have inlined special-case R_GetColumn with precalculated fields for this texture.
				// as a result, we also avoid a 34k texture mucking up the texture cache region...


				dc_source_segment = skytexture_texture_segment + texture_x;
				R_DrawSkyColumn(dc_yh, dc_yl);
					

			}
		}
	}

}
*/

//
// R_DrawPlanes
// At the end of each frame.
//
void __near R_DrawPlanes (void) {
    visplane_t __far*		pl;
    uint8_t			light;
    int16_t			x;
    int16_t			stop;
	byte t1, b1, t2, b2;
	int8_t			i;
	int8_t			j;
	int8_t			physindex = 0;

	int16_t effectivepagenumber = 0;
	uint8_t usedflatindex;
	boolean flatunloaded = false;
	int16_t flatcacheindex = 0;
	int16_t lastflatcacheindicesused[3] = {3, 2, 1}; // initialized so that allocation order is 0 1 2
	segment_t visplanesegment = 0x8400;
	uint16_t visplaneoffset = 0;
	visplanepiclight_t piclight;

    for (i = 0; i < lastvisplane ; i++, visplaneoffset+= VISPLANE_BYTE_SIZE) {
		visplaneheader_t __far*	plheader = &visplaneheaders[i];

		if (plheader->minx > plheader->maxx)
			continue;

		while (visplaneoffset >= (VISPLANES_PER_EMS_PAGE * VISPLANE_BYTE_SIZE)){
		// umm... what if we hit this after 100 iters of continue above and overflow? probably should never happen...
			
			physindex++;
			visplaneoffset -= (VISPLANES_PER_EMS_PAGE * VISPLANE_BYTE_SIZE);
			if (physindex == 3){
				//I_Error("A");
				// todo eventually page these into 9000 region?
	
				//I_Error("Here: %i %Fp", 3+visplanedirty, MK_FP(visplanelookupsegments[2], visplaneoffset) );
				
				Z_QuickMapVisplanePage(3+visplanedirty, 2); // will be 3 the first time, 4 the second time.
				physindex = 2;

			}
			visplanesegment = visplanelookupsegments[physindex];
		} 
		pl = (visplane_t __far *) MK_FP(visplanesegment, visplaneoffset); 
		// sky flat
		piclight.pic_and_light = visplanepiclights[i].pic_and_light;
		if (piclight.bytes.picnum == skyflatnum) {
			R_DrawSkyPlaneCallHigh(plheader->minx, plheader->maxx, pl);
			continue;
		}

		// calculate light early while some of these vars (like i) can be in registers..

		light = (piclight.bytes.lightlevel >> LIGHTSEGSHIFT)+extralight;

		if (light >= LIGHTLEVELS){
			light = LIGHTLEVELS-1;
		}
		planezlight = MK_FP(zlight_segment, lightshift7lookup[light]);

		
		usedflatindex = flatindex[flattranslation[piclight.bytes.picnum]];
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

			flatindex[flattranslation[piclight.bytes.picnum]] = usedflatindex;
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
		

		// load if necessary
		if (flatunloaded){
#ifdef CHECK_FOR_ERRORS
			int16_t lump = firstflat + flattranslation[piclight.bytes.picnum];
			if (lump < firstflat || lump > firstflat + numflats) {
				I_Error("bad flat? %i", lump);
			}
#endif
		 
			W_CacheLumpNumDirect(firstflat + flattranslation[piclight.bytes.picnum], MK_FP(FLAT_CACHE_PAGE[flatcacheindex], MULT_4096[usedflatindex & 0x03]));
		}
		
		// regular flat
		ds_source_segment = FLAT_CACHE_PAGE[flatcacheindex] + MULT_256[usedflatindex & 0x03];

		// works but slow?
		//ds_source = R_GetFlat(firstflat + flattranslation[piclight.bytes.picnum]);
		
		planeheight = labs(plheader->height - viewz.w);
				// quicker shift 7.. (? test)
	
		//pl = (visplane_t __far *) MK_FP(visplanesegment, visplaneoffset); 
	 
		pl->top[plheader->maxx+1] = 0xff;
		pl->top[plheader->minx-1] = 0xff;

		stop = plheader->maxx + 1;
		
		// start  asm  by pulling this out 
		for (x=plheader->minx ; x<= stop ; x++) {
			t1 = pl->top[x - 1];
			b1 = pl->bottom[x - 1];
			t2 = pl->top[x];
			b2 = pl->bottom[x];

			//todo make a single pixel  inlined mapplane for when its just one pix? rare but would save a lot of jank
			while (t1 < t2 && t1 <= b1) {
				R_MapPlaneCall(t1, spanstart[t1], x - 1);
				t1++;
			}
			while (b1 > b2 && b1 >= t1) {
				R_MapPlaneCall(b1, spanstart[b1], x - 1);
				b1--;
			}


			// sq note: make more sense of this logic
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



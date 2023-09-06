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
#include "r_sky.h"




//
// opening
//

// Here comes the obnoxious "visplane".

#ifdef EMS_VISPLANES

// visplane_t		visplanes[MAXVISPLANES];
visplaneheader_t		visplaneheaders[MAXVISPLANES];
int16_t		lastvisplaneheader;
int16_t		floorplaneindex;
int16_t		ceilingplaneindex;
MEMREF visplanebytesRef[NUM_VISPLANE_PAGES]; 

#else
visplane_t		visplanes[MAXVISPLANES];
int16_t		lastvisplane;
int16_t		floorplaneindex;
int16_t		ceilingplaneindex;

#endif

// ?
#define MAXOPENINGS	SCREENWIDTH*64
int16_t			openings[MAXOPENINGS];
int16_t*			lastopening;


//
// Clip values are the solid pixel bounding the range.
//  floorclip starts out SCREENHEIGHT
//  ceilingclip starts out -1
//
int16_t			floorclip[SCREENWIDTH];
int16_t			ceilingclip[SCREENWIDTH];

//
// spanstart holds the start of a plane span
// initialized to 0 at start
//
int16_t			spanstart[SCREENHEIGHT];
//int32_t			spanstop[SCREENHEIGHT];

//
// texture mapping
//
lighttable_t**		planezlight;
fixed_t			planeheight;

fixed_t			yslope[SCREENHEIGHT];
fixed_t			distscale[SCREENWIDTH];
fixed_t			basexscale;
fixed_t			baseyscale;

fixed_t			cachedheight[SCREENHEIGHT];
fixed_t			cacheddistance[SCREENHEIGHT];
fixed_t			cachedxstep[SCREENHEIGHT];
fixed_t			cachedystep[SCREENHEIGHT];



//
// R_InitPlanes
// Only at game startup.
//
void R_InitPlanes (void) {
  // Doh!

	// idea: create a single allocations with the arrays of the non-byte fields. this is only 10 bytes per visplane, 
	// and that's the only thing that is ever iterated on. the big byte arrays are sort of used one at a time - those
	// can be in a separately indexed set of data, that can in turn also be separately paged in and out as necessary.
	// In theory this also makes it easier to dynamically allocate space to visplanes.

	// byte fields per visplane is 644, we can fit 25 of those per 16k page. we can, instead of one big fat allocation 
	// do those in individual 16k allocations and use the individual memref we need based on index. that should greatly
	// reduce the paging involved?
	
#ifdef EMS_VISPLANES
	int16_t i;
	int16_t j;

	for (i = 0; i < NUM_VISPLANE_PAGES; i++){
		visplanebytesRef[i] = Z_MallocEMSNew(VISPLANE_BYTE_SIZE * VISPLANES_PER_EMS_PAGE, PU_STATIC, 0, ALLOC_TYPE_VISPLANE);

		for (j = 0; j < VISPLANES_PER_EMS_PAGE; j++){
			visplaneheaders[i * VISPLANES_PER_EMS_PAGE + j].visplanepage = i;
			visplaneheaders[i * VISPLANES_PER_EMS_PAGE + j].visplaneoffset = j;
		}

	}
	// 1136 1138 1140 1142 1144 1146


#endif


}


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
void
R_MapPlane
( byte		y,
  int16_t		x1,
  int16_t		x2 )
{
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
	angle = MOD_FINE_ANGLE((viewangle >>ANGLETOFINESHIFT)+ xtoviewangle[x1]);

    ds_xfrac = viewx.w + FixedMul(finecosine(angle), length);
    ds_yfrac = -viewy.w - FixedMul(finesine(angle), length);

if (fixedcolormap) {
	ds_colormap = fixedcolormap;
}
else {
	index = distance >> LIGHTZSHIFT;

	if (index >= MAXLIGHTZ) {
		index = MAXLIGHTZ - 1;
	}

	ds_colormap = planezlight[index];
}

ds_y = y;
ds_x1 = x1;
ds_x2 = x2;

// high or low detail
// NOTE: ds_sourceRef must be active at this point. it's loaded up in R_DrawPlanes
	spanfunc();
}


#ifdef EMS_VISPLANES
//
// R_ClearPlanes
// At begining of frame.
//
void R_ClearPlanes(void)
{
	int16_t		i;
	fineangle_t	angle;

	// opening / clipping determination
	for (i = 0; i < viewwidth; i++) {
		floorclip[i] = viewheight;
		ceilingclip[i] = -1;
	}

	lastvisplaneheader = 0;
	lastopening = openings;

	// texture calculation
	memset(cachedheight, 0, sizeof(cachedheight));

	// left to right mapping
	angle = (viewangle - ANG90) >> ANGLETOFINESHIFT;

	// scale will be unit scale at SCREENWIDTH/2 distance
	basexscale = FixedDiv(finecosine(angle), centerxfrac);
	baseyscale = -FixedDiv(finesine(angle), centerxfrac);
}




//
// R_FindPlane
int16_t 
R_FindPlane
(fixed_t	height,
	uint8_t		picnum,
	uint8_t		lightlevel) {
	visplaneheader_t*	check;
	visplanebytes_t* checkbytes;
	int16_t			i;

	if (picnum == skyflatnum) {
		height = 0;			// all skys map together
		lightlevel = 0;
	}

	for (i = 0; i < lastvisplaneheader; i++) {
		check = &visplaneheaders[i];
		if (height == check->height
			&& picnum == check->picnum
			&& lightlevel == check->lightlevel) {
			break;
		}
	}

	if (i < lastvisplaneheader) {
		return i;
	}

	if (lastvisplaneheader == MAXVISPLANES) {
		I_Error("R_FindPlane: no more visplanes");
	}

	lastvisplaneheader++;
	check = &visplaneheaders[i];

	check->height = height;
	check->picnum = picnum;
	check->lightlevel = lightlevel;
	check->minx = SCREENWIDTH;
	check->maxx = -1;

	checkbytes = &(((visplanebytes_t*)Z_LoadBytesFromEMS(visplanebytesRef[check->visplanepage]))[check->visplaneoffset]);

	memset(checkbytes->top, 0xff, sizeof(checkbytes->top));

    return i;
}


//
// R_CheckPlane
//
int16_t
R_CheckPlane
(int16_t	plindex,
  int16_t		start,
  int16_t		stop )
{
    int16_t		intrl;
    int16_t		intrh;
    int16_t		unionl;
    int16_t		unionh;
    int16_t		x;
	visplanebytes_t* plbytes;
	visplaneheader_t* pl = &visplaneheaders[plindex];
	
    if (start < pl->minx) {
		intrl = pl->minx;
		unionl = start;
    } else {
		unionl = pl->minx;
		intrl = start;
    }
	
    if (stop > pl->maxx) {
		intrh = pl->maxx;
		unionh = stop;
    } else {
		unionh = pl->maxx;
		intrh = stop;
    }

	plbytes = &(((visplanebytes_t*)Z_LoadBytesFromEMS(visplanebytesRef[pl->visplanepage]))[pl->visplaneoffset]);

    for (x=intrl ; x<= intrh ; x++)
		if (plbytes->top[x] != 0xff)
		    break;

    if (x > intrh) {
		pl->minx = unionl;
		pl->maxx = unionh;

		// use the same one
		return plindex;
    }
	
    // make a new visplane
	visplaneheaders[lastvisplaneheader].height = pl->height;
	visplaneheaders[lastvisplaneheader].picnum = pl->picnum;
	visplaneheaders[lastvisplaneheader].lightlevel = pl->lightlevel;

	pl = &visplaneheaders[lastvisplaneheader];
    pl->minx = start;
    pl->maxx = stop;
	
	//todo dont z_load if same page frame
	plbytes = &(((visplanebytes_t*)Z_LoadBytesFromEMS(visplanebytesRef[pl->visplanepage]))[pl->visplaneoffset]);
    memset (plbytes->top,0xff,sizeof(plbytes->top));
		
    return lastvisplaneheader++;
}




//
// R_DrawPlanes
// At the end of each frame.
//
void R_DrawPlanes (void)
{
    visplaneheader_t*		pl;
	visplanebytes_t*		plbytes;
    uint8_t			light;
    int16_t			x;
    int16_t			stop;
    fineangle_t			angle;
	uint8_t * flattranslation;
	byte t1, b1, t2, b2;
	visplanebytes_t* base;
	int8_t currentplanebyteRef;
	int16_t i;
	fixed_t_union temp;

	currentplanebyteRef = 0; // visplaneheaders->visplanepage is always 0;
	base = &(((visplanebytes_t*)Z_LoadBytesFromEMSWithOptions(visplanebytesRef[currentplanebyteRef], PAGE_LOCKED))[0]); // load into locked page

    for (i = 0 ; i < lastvisplaneheader ; i++) {
		pl = &visplaneheaders[i];
		if (pl->minx > pl->maxx)
			continue;

		if (currentplanebyteRef != pl->visplanepage) { // new page to set locked..
			Z_SetUnlocked(visplanebytesRef[currentplanebyteRef]);
			currentplanebyteRef = pl->visplanepage;
//			base = &(((visplanebytes_t*)Z_LoadBytesFromEMS(visplanebytesRef[currentplanebyteRef]))[0]);
			base = &(((visplanebytes_t*)Z_LoadBytesFromEMSWithOptions(visplanebytesRef[currentplanebyteRef], PAGE_LOCKED))[0]); // load into locked page

		}
		plbytes = &(base[pl->visplaneoffset]);

	
		// sky flat
		if (pl->picnum == skyflatnum) {
			dc_iscale = pspriteiscale>>detailshift;
	    
			// Sky is allways drawn full bright,
			//  i.e. colormaps[0] is used.
			// Because of this hack, sky is not affected
			//  by INVUL inverse mapping.
			dc_colormap = colormaps;
			dc_texturemid = 100*FRACUNIT; // this was hardcoded as the only use of skytexturemid..
			//copy = (((visplanebytes_t*)Z_LoadBytesFromEMS(visplanebytesRef[pl->visplanepage]))[pl->visplaneoffset]);
			for (x=pl->minx ; x <= pl->maxx ; x++) {
				//plbytes = &;
				dc_yl = plbytes->top[x];
				dc_yh = plbytes->bottom[x];

				if (dc_yl <= dc_yh) {

					// feel like this can be done with less shifting because its ultimately modded to a fine angle. -sq

					temp.h.fracbits = 0;
					temp.h.intbits = (xtoviewangle[x]);
					temp.h.intbits <<= 3;
					temp.w += viewangle;
					temp.h.intbits >>= 6;
					//temp.w >>= ANGLETOSKYSHIFT;
					angle = MOD_FINE_ANGLE(temp.h.intbits) ;

					dc_x = x;

					dc_source = R_GetColumn(skytexture, angle);
					colfunc ();
					//Z_SetUnlocked(lockedRef);

				}
			}
			continue;
		}
	
		flattranslation = Z_LoadBytesFromEMS(flattranslationRef);
		// regular flat
		ds_sourceRef = W_CacheLumpNumEMS(firstflat +
			flattranslation[pl->picnum],
			PU_STATIC);
		ds_source = Z_LoadBytesFromEMS(ds_sourceRef);
		//Z_SetUnlocked(ds_sourceRef, PAGE_LOCKED);
		planeheight = abs(pl->height-viewz.w);
		light = (pl->lightlevel >> LIGHTSEGSHIFT)+extralight;

		if (light >= LIGHTLEVELS)
			light = LIGHTLEVELS-1;
 

		planezlight = zlight[light];

		plbytes->top[pl->maxx+1] = 0xff;
		plbytes->top[pl->minx-1] = 0xff;
		
		stop = pl->maxx + 1;

		for (x=pl->minx ; x<= stop ; x++) {

			t1 = plbytes->top[x - 1];
			b1 = plbytes->bottom[x - 1];
			t2 = plbytes->top[x];
			b2 = plbytes->bottom[x];


			while (t1 < t2 && t1 <= b1) {
				// ds_sourceRef used in here
				R_MapPlane(t1, spanstart[t1], x - 1);
				t1++;
			}
			while (b1 > b2 && b1 >= t1) {
				// ds_sourceRef used in here
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
		//Z_SetUnlocked(ds_sourceRef);
		Z_ChangeTagEMSNew (ds_sourceRef, PU_CACHE);
    }

	Z_SetUnlocked(visplanebytesRef[currentplanebyteRef]);

}

#else
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
    lastopening = openings;
    
    // texture calculation
    memset (cachedheight, 0, sizeof(cachedheight));

    // left to right mapping
    angle = (viewangle-ANG90)>>ANGLETOFINESHIFT;
	
    // scale will be unit scale at SCREENWIDTH/2 distance
    basexscale = FixedDiv (finecosine(angle),centerxfrac);
    baseyscale = -FixedDiv (finesine(angle),centerxfrac);
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
    visplane_t*	check;
	int i;
		
    if (picnum == skyflatnum) {
		height = 0;			// all skys map together
		lightlevel = 0;
    }
	
    for (i = 0; i<lastvisplane; i++)
    {
		check = &visplanes[i];

	if (height == check->height
	    && picnum == check->picnum
	    && lightlevel == check->lightlevel)
	{
	    break;
	}
    }
    
			
    if (i < lastvisplane)
		return i;
		
    if (lastvisplane == MAXVISPLANES)
		I_Error ("R_FindPlane: no more visplanes");
		
    lastvisplane++;
	check = &visplanes[i];

    check->height = height;
    check->picnum = picnum;
    check->lightlevel = lightlevel;
    check->minx = SCREENWIDTH;
    check->maxx = -1;
    
    memset (check->top,0xff,sizeof(check->top));
		
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
	visplane_t*	pl = &visplanes[index];
	
    if (start < pl->minx)
    {
	intrl = pl->minx;
	unionl = start;
    }
    else
    {
	unionl = pl->minx;
	intrl = start;
    }
	
    if (stop > pl->maxx)
    {
	intrh = pl->maxx;
	unionh = stop;
    }
    else
    {
	unionh = pl->maxx;
	intrh = stop;
    }

    for (x=intrl ; x<= intrh ; x++)
	if (pl->top[x] != 0xff)
	    break;

    if (x > intrh)
    {
	pl->minx = unionl;
	pl->maxx = unionh;

	// use the same one
	return index;		
    }

    // make a new visplane
	visplanes[lastvisplane].height = pl->height;
	visplanes[lastvisplane].picnum = pl->picnum;
	visplanes[lastvisplane].lightlevel = pl->lightlevel;
    
	pl = &visplanes[lastvisplane];
    pl->minx = start;
    pl->maxx = stop;

    memset (pl->top,0xff,sizeof(pl->top));
	
	return lastvisplane++;
}




//
// R_DrawPlanes
// At the end of each frame.
//
void R_DrawPlanes (void)
{
    visplane_t*		pl;
    uint8_t			light;
    int16_t			x;
    int16_t			stop;
    fineangle_t			angle;
	uint8_t * flattranslation;
	byte t1, b1, t2, b2;
	int16_t			i;
	fixed_t_union	temp;

 
    for (i = 0; i < lastvisplane ; i++)
    {
		pl = &visplanes[i];
	if (pl->minx > pl->maxx)
	    continue;

	
	// sky flat
	if (pl->picnum == skyflatnum)
	{
	    dc_iscale = pspriteiscale>>detailshift;
	    
	    // Sky is allways drawn full bright,
	    //  i.e. colormaps[0] is used.
	    // Because of this hack, sky is not affected
	    //  by INVUL inverse mapping.
	    dc_colormap = colormaps;
	    dc_texturemid = 100*FRACUNIT; // this was hardcoded as the only use of skytexturemid..
	    for (x=pl->minx ; x <= pl->maxx ; x++)
	    {
		dc_yl = pl->top[x];
		dc_yh = pl->bottom[x];

		if (dc_yl <= dc_yh)
		{
			// feel like this can be done with less shifting because its ultimately modded to a fine angle. -sq

			temp.h.fracbits = 0;
			temp.h.intbits = (xtoviewangle[x]);
			temp.h.intbits <<= 3;
			temp.w += viewangle;
			temp.h.intbits >>= 6;
			//temp.w >>= ANGLETOSKYSHIFT;
			angle = MOD_FINE_ANGLE(temp.h.intbits);
			dc_x = x;

			dc_source = R_GetColumn(skytexture, angle);
		    colfunc ();
			

		}
	    }
	    continue;
	}
	
	flattranslation = Z_LoadBytesFromEMS(flattranslationRef);
	// regular flat
	ds_sourceRef = W_CacheLumpNumEMS(firstflat +
		flattranslation[pl->picnum],
		PU_STATIC);
	ds_source = Z_LoadBytesFromEMS(ds_sourceRef);
	
	planeheight = abs(pl->height - viewz.w);
	light = (pl->lightlevel >> LIGHTSEGSHIFT)+extralight;

	if (light >= LIGHTLEVELS)
	    light = LIGHTLEVELS-1;
 

	planezlight = zlight[light];

	pl->top[pl->maxx+1] = 0xff;
	pl->top[pl->minx-1] = 0xff;
		
	stop = pl->maxx + 1;

	for (x=pl->minx ; x<= stop ; x++)
	{
			t1 = pl->top[x - 1];
			b1 = pl->bottom[x - 1];
			t2 = pl->top[x];
			b2 = pl->bottom[x];


		while (t1 < t2 && t1 <= b1)
		{
			R_MapPlane(t1, spanstart[t1], x - 1);
			t1++;
		}
		while (b1 > b2 && b1 >= t1)
		{
			R_MapPlane(b1, spanstart[b1], x - 1);
			b1--;
		}

		while (t2 < t1 && t2 <= b2)
		{
			spanstart[t2] = x;
			t2++;
		}
		while (b2 > b1 && b2 >= t2)
		{
			spanstart[b2] = x;
			b2--;
		}

	}
	
	Z_ChangeTagEMSNew (ds_sourceRef, PU_CACHE);
    }
}

#endif


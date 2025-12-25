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



#include "doomdef.h"

#include <stdlib.h>
#include <math.h>


#include "d_net.h"

#include "m_misc.h"

#include "r_local.h"
#include "p_local.h"


#include "i_system.h"
#include "doomstat.h"
#include "tables.h"
#include "w_wad.h"
#include <dos.h>
#include "m_memory.h"
#include "m_near.h"


#define DISTMAP		2
#define FIELDOFVIEW		2048	


// ?
#define MAXWIDTH			320
#define MAXHEIGHT			200

// status bar height at bottom of screen
#define SBARHEIGHT		32

 

// finetangent(FINEANGLES / 4 + FIELDOFVIEW / 2)
#define FIXED_FINE_TAN 0x10032L

//
// R_InitTextureMapping
//
void __near R_InitAngles(void);	
void __near R_InitTextureMapping(void) {
	int16_t			x;
	fixed_t_union	t;
	fixed_t		focallength;
	fixed_t_union		temp;
	fineangle_t	an;
	fixed_t     cosadj;
	int16_t		level;
	fixed_t	dy;
	int16_t		i;
	uint8_t		i2;
	uint8_t		j;
	fixed_t_union finetan_i;
	temp.h.fracbits = 0;

	// Use tangent table to generate viewangletox:
	//  viewangletox will give the next greatest x
	//  after the view angle.
	//
	// Calc focallength
	//  so FIELDOFVIEW angles covers SCREENWIDTH.
	
	R_InitAngles();
	
	focallength = FixedDivWholeA(centerx, FIXED_FINE_TAN);

/*
	for (i = 0; i < FINEANGLES / 2; i++) {
		finetan_i.w = finetangent(i);
		if (finetan_i.w > FRACUNIT * 2){
			t.h.intbits = -1;
		} else if (finetan_i.w < -FRACUNIT * 2){
			t.h.intbits = viewwidth + 1;
		} else {
			fixed_t_union temp;
			temp.h.intbits = centerx;
			temp.h.fracbits = 0;
			t.w = FixedMul(finetan_i.w, focallength);
			//todo optimize given centerxfrac low bits are 0
			t.w = (temp.w - t.w + 0xFFFFu);

			if (t.h.intbits < -1){
				t.h.intbits = -1;
			} else if (t.h.intbits > viewwidth + 1){
				t.h.intbits = viewwidth + 1;
			}
		}
		viewangletox[i] = t.h.intbits;

		// if (viewangletox[i] != t.h.intbits){
		// 	I_Error("issue %i %i %i %li %i %li %i", i, viewangletox[i], t.h.intbits, FixedMul(finetan_i.w, focallength), centerx,
		// 	(temp.w - FixedMul(finetan_i.w, focallength) + 0xFFFFu), viewwidth
		// 	);
		// }


	}

	// Scan viewangletox[] to generate xtoviewangle[]:
	//  xtoviewangle will give the smallest view angle
	//  that maps to x.	
	for (x = 0; x <= viewwidth; x++) {
		i = 0;
		while (viewangletox[i] > x){
			i++;
		}
		xtoviewangle[x] = MOD_FINE_ANGLE((i)-FINE_ANG90);
	}

	// Take out the fencepost cases from viewangletox.
	for (i = 0; i < FINEANGLES / 2; i++) {

		if (viewangletox[i] == -1){
			viewangletox[i] = 0;
		} else if (viewangletox[i] == viewwidth + 1){
			viewangletox[i] = viewwidth;
		}
	}


	clipangle = xtoviewangle[0] << 3;
	fieldofview = clipangle << 1;


	// psprite scales
	if (viewwidth == SCREENWIDTH) {
		// will be specialcased as 1 later;
		pspritescale = 0;
		pspriteiscale = FRACUNIT;
	}
	else {
		// max of FRACUNIT, we set it to 0 in that case
		// todo we can make this a lookuplookup
		
		pspritescale = FastDiv32u16u(FRACUNIT * viewwidth, SCREENWIDTH);
		pspriteiscale = FastDiv32u16u(FRACUNIT * SCREENWIDTH, viewwidth);
		// 			10000	11C71	14000	16DB6	1AAAA	20000	28000	35555	50000	A0000 
		//detail    10-11,   9		 8		 7		 6		 5		 4		 3		 2		 1
		
	}

	// thing clipping
	for (i = 0; i < viewwidth; i++) {
		screenheightarray[i] = viewheight;
	}

	// 168 viewheight
	// planes

	Z_QuickMapRenderPlanes();
	for (i = 0; i < viewheight; i++) {
		temp.h.intbits = (i - (viewheight >> 1));
		dy = (temp.w) + 0x8000u;
		dy = labs(dy);
		temp.h.intbits = (viewwidth << detailshift.b.bytelow) >> 1;
		yslope[i] = FixedDivWholeA(temp.h.intbits, dy);
	}

	// 320 viewwidth

	for (i = 0; i < viewwidth; i++) {
		an = xtoviewangle[i];
		// cosine is 17 bit in a 32 bit storage... we can probably figure out a way to do this without labs.
		cosadj = labs(finecosine[an]);
		distscale[i] = FixedDivWholeA(1, cosadj);
	}

	Z_QuickMapRender();
	*/

	// Calculate the light levels to use
	//  for each level / scale combination.
	for (i2 = 0; i2 < LIGHTLEVELS; i2++) {
		//startmap = ((LIGHTLEVELS - 1 - i2) << 1)*NUMCOLORMAPS / LIGHTLEVELS;
		startmap = ((LIGHTLEVELS - 1 - i2) << 2);
		for (j = 0; j < MAXLIGHTSCALE; j++) {
			level = startmap - ((j * SCREENWIDTH / (viewwidth << detailshift.b.bytelow)) >> 1);

			if (level < 0) {
				level = 0;
			}

			if (level >= NUMCOLORMAPS) {
				level = NUMCOLORMAPS - 1;
			}
			
			// pre shift by 2 here, since its ultimately shifted by 2 for the colfunc lookup addr..
			scalelight[i2*MAXLIGHTSCALE+j] =  level << 2;// * 256;
		}
	}


}


//
// R_ExecuteSetViewSize
//
void __near  R_ExecuteSetViewSize(void) ;
/*
void __near  R_ExecuteSetViewSize(void) {

	fixed_t_union temp;
	temp.h.fracbits = 0;
	setsizeneeded = false;
	// i think the first draw or two dont write to the correct framebuffer? needs six
	hudneedsupdate = 6;

	if (setblocks == 11) {
		scaledviewwidth = SCREENWIDTH;
		viewheight = SCREENHEIGHT;
	}
	else {
		scaledviewwidth = setblocks << 5;
		viewheight = (setblocks * 168 / 10)&~7;
	}

	detailshift.b.bytelow = pendingdetail;
	detailshift.b.bytehigh = (pendingdetail << 2); // high bit contains preshifted by four pendingdetail

	detailshift2minus =  (2-pendingdetail);
	detailshiftitercount = 1 << (detailshift2minus);
	detailshiftandval = 0 - detailshiftitercount;
	
	viewwidth = scaledviewwidth >> detailshift.b.bytelow;

	centery = viewheight >> 1;
	centerx = viewwidth >> 1;

	temp.h.intbits = centery;
	centeryfrac_shiftright4.w = temp.w >> 4;


	// Handle resize,
	//  e.g. smaller view windows
	//  with border and/or status bar.
	
	// multiple of 16 guaranteed.. can be a segment instead of offset
	viewwindowx = (SCREENWIDTH - scaledviewwidth) >> 1;

	// Same with base row offset.
	if (scaledviewwidth == SCREENWIDTH){
		viewwindowy = 0;
	} else {
		viewwindowy = (SCREENHEIGHT - SBARHEIGHT - viewheight) >> 1;
	}
	
	viewwindowoffset = (viewwindowy*(SCREENWIDTH / 4)) + (viewwindowx >> 2);

	Z_QuickMapRender();
	R_InitTextureMapping();
	R_WriteBackViewConstants();

	Z_QuickMapRenderPlanes();
	R_WriteBackViewConstantsSpanCall();

	// Set Masked Mapping
	Z_QuickMapUndoFlatCache();
	R_WriteBackViewConstantsMaskedCall();
	Z_QuickMapPhysics();


	// set render 'constants' related to detaillevel. 
	spanfunc_outp[0] = 1;
	spanfunc_outp[1] = 2;
	spanfunc_outp[2] = 4;
	spanfunc_outp[3] = 8;
	if (detailshift.b.bytelow == 1){
		spanfunc_outp[0] = 3;
		spanfunc_outp[1] = 12;
	}
	if (detailshift.b.bytelow == 2){
		spanfunc_outp[0] = 15;
	}


	
 
}

 
*/

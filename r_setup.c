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
#include <dos.h>
#include "memory.h"


#define DISTMAP		2
#define FIELDOFVIEW		2048	


// ?
#define MAXWIDTH			320
#define MAXHEIGHT			200

// status bar height at bottom of screen
#define SBARHEIGHT		32

extern boolean setsizeneeded;
extern uint8_t		setblocks;
extern uint8_t		setdetail;
 

// finetangent(FINEANGLES / 4 + FIELDOFVIEW / 2)
#define FIXED_FINE_TAN 0x10032L

//
// R_InitTextureMapping
//
void __near R_InitTextureMapping(void) {
	int16_t			x;
	fixed_t_union	t;
	fixed_t		focallength;
	fixed_t_union		temp;
	fixed_t	cosadj;
	fineangle_t	an;
	int16_t		level;
	fixed_t	dy;
	int16_t		i;
	uint8_t		i2;
	uint8_t		j;
	fixed_t_union finetan_i;
	Z_QuickMapRender();
	temp.h.fracbits = 0;

	// Use tangent table to generate viewangletox:
	//  viewangletox will give the next greatest x
	//  after the view angle.
	//
	// Calc focallength
	//  so FIELDOFVIEW angles covers SCREENWIDTH.
	focallength = FixedDivWholeA(centerxfrac.w, FIXED_FINE_TAN);


	for (i = 0; i < FINEANGLES / 2; i++) {
		finetan_i.w = finetangent(i);
		if (finetan_i.w > FRACUNIT * 2)
			t.h.intbits = -1;
		else if (finetan_i.w < -FRACUNIT * 2)
			t.h.intbits = viewwidth + 1;
		else {
			t.w = FixedMul(finetan_i.w, focallength);
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

	Z_QuickMapRenderPlanes();
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
	Z_QuickMapRender();

	// Calculate the light levels to use
	//  for each level / scale combination.
	for (i2 = 0; i2 < LIGHTLEVELS; i2++) {
		startmap = ((LIGHTLEVELS - 1 - i2) * 2)*NUMCOLORMAPS / LIGHTLEVELS;
		for (j = 0; j < MAXLIGHTSCALE; j++) {
			level = startmap - j * SCREENWIDTH / (viewwidth << detailshift) / DISTMAP;

			if (level < 0) {
				level = 0;
			}

			if (level >= NUMCOLORMAPS) {
				level = NUMCOLORMAPS - 1;
			}

			scalelight[i2*MAXLIGHTSCALE+j] =  level;// * 256;
		}
	}

	Z_QuickMapPhysics();

}



//
// R_ExecuteSetViewSize
//
void __near  R_ExecuteSetViewSize(void) {

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
		//void (__far* dynamic_callfunc)(void)  =      R_DrawColumnAddr;
		//colfunc = basecolfunc = dynamic_callfunc;
		fuzzcolfunc = R_DrawFuzzColumn;
		spanfunc = R_DrawSpan;
	}
	else {
		colfunc = basecolfunc = R_DrawColumnLow;
		fuzzcolfunc = R_DrawFuzzColumn;
		spanfunc = R_DrawSpanLow;
	}



	// Handle resize,
	//  e.g. smaller view windows
	//  with border and/or status bar.
	viewwindowx = (SCREENWIDTH - scaledviewwidth) >> 1;


	// Samw with base row offset.
	if (scaledviewwidth == SCREENWIDTH)
		viewwindowy = 0;
	else
		viewwindowy = (SCREENHEIGHT - SBARHEIGHT - viewheight) >> 1;

	viewwindowoffset = (viewwindowy*SCREENWIDTH / 4) + (viewwindowx >> 2);


	R_InitTextureMapping();


 
}

 


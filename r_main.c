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
#include "p_local.h"
#include "d_net.h"

#include "m_misc.h"

#include "r_local.h"

#include "w_wad.h"
#include "z_zone.h"

#include "i_system.h"
#include "doomstat.h"
#include "m_memory.h"
#include "m_near.h"
#include <dos.h>


// Fineangles in the SCREENWIDTH wide window.
#define FIELDOFVIEW		2048	



//
// R_PointOnSide
// Traverse BSP (sub) tree,
//  check point against partition plane.
// Returns side 0 (front) or 1 (back).
//


/*
int16_t __near R_PointOnSegSide2 ( fixed_t_union	x, fixed_t_union	y, int16_t segindex) {
    int16_t	lx = vertexes[segs_render[segindex].v1Offset].x;
    int16_t	ly = vertexes[segs_render[segindex].v1Offset].y;
    int16_t	ldx = vertexes[segs_render[segindex].v2Offset].x;
    int16_t	ldy = vertexes[segs_render[segindex].v2Offset].y;
    fixed_t_union	dx;
    fixed_t_union	dy;
    fixed_t_union	left;
    fixed_t_union	right;

	
    fixed_t_union temp;
	
	temp.h.fracbits = 0;

    if (ldx == lx) {
	    temp.h.intbits = lx;
        if (x.w <= temp.w)
            return ldy > ly;
        
        return ldy < ly;
    }
    if (ldy == ly) {
	    temp.h.intbits = ly;
        if (y.w <= temp.w)
            return ldx < lx;
        
        return ldx > lx;
    }

	ldx -= lx;
    ldy -= ly;

	// store 
	temp.h.intbits = lx;
    dx.w = (x.w - temp.w);
	temp.h.intbits = ly;
    dy.w = (y.w - temp.w);
	
    // Try to quickly decide by looking at sign bits.
    if ( (ldy ^ ldx ^ dx.h.intbits ^ dy.h.intbits)&0x8000 )  // returns 1
		// (left is negative)
		return  ((ldy ^ dx.h.intbits) & 0x8000);  // returns 1
    

    left.w = FixedMul1632 ( ldy , dx.w );
    right.w = FixedMul1632 (ldx, dy.w );
	
	// front side if true, back side if false
	return right.w >= left.w;

} 


int16_t __near R_PointOnSegSide ( fixed_t_union	x, fixed_t_union	y, int16_t segindex) {
	int16_t a = R_PointOnSegSide2(x, y, segindex);
	int16_t b = R_PointOnSegSide3(x, y, segindex);
	if (x.w == 0xf843c383 && y.wu == 0xf445e856 && segindex == 813){
		//b = R_PointOnSegSide4(x, y, segindex)
	}
	if (a != b){
		int16_t	lx = vertexes[segs_render[segindex].v1Offset].x;
		int16_t	ly = vertexes[segs_render[segindex].v1Offset].y;
		int16_t	ldx = vertexes[segs_render[segindex].v2Offset].x;
		int16_t	ldy = vertexes[segs_render[segindex].v2Offset].y;

		I_Error("bad! %lx %lx %i %x %i %x %i \n%i %i %i %i\n%x %x %x %x", 
		x.wu, y.wu, segindex, b, b, a, a,
		lx, ldx, ly, ldy,
		lx, ldx, ly, ldy
		);
	}
	return a;
}
*/


//
// R_PointToAngle
// To get a global angle from cartesian coordinates,
//  the coordinates are flipped until they are in
//  the first octant of the coordinate system, then
//  the y (<=x) is scaled and divided by x to get a
//  tangent (slope) value which is looked up in the
//  tantoangle[] table.

//
angle_t __far* tantoangle;

uint32_t __near R_PointToAngle16 (int16_t	x,int16_t	y) {

	fixed_t_union xfp, yfp;
	xfp.h.intbits = x;
	yfp.h.intbits = y;
	xfp.h.fracbits = 0;
	yfp.h.fracbits = 0;

	return R_PointToAngle(xfp, yfp);
}
/*

int16_t divtest(fixed_t_union x, fixed_t_union y){
	fixed_t_union a;
	uint16_t b;
	a.w = (x.w << 3) / (y.w >> 8);
	b = FastDiv3232_shift_3_8(x.w, y.w);
	if (a.wu != b){
		if (a.wu <2048 || b < 2048){
			I_Error("bad! %li %lx %li %lx %li %lx %u %x",
			x.w, x.w, y.w, y.w, a.w, a.w, b, b);
		}
	}

	return b;
}
*/


/*
uint32_t __far R_PointToAngle( fixed_t_union	x, fixed_t_union	y ) {	
	uint32_t a = R_PointToAngle10(x, y);
	uint32_t b = R_PointToAngle11(x, y);
	if (a != b){
		I_Error("bad! %lx %lx %lx %lx %li %li %li\n %lx %li", x.wu, y.wu, b, a, b, a, b - a,
		x.w - viewx.w, x.w - viewx.w);
	}
	

	return a;
}

uint32_t __far R_PointToAngle10( fixed_t_union	x, fixed_t_union	y ) {	
	uint16_t tempDivision;

	x.w -= viewx.w;
	y.w -= viewy.w;

	// todo make a fast slope division for this function that internally does the shifts, etc.

	if ((!x.w) && (!y.w))
		return 0;

	if (x.w >= 0)
	{
		// x >=0
		if (y.w >= 0)
		{
			// y>= 0
			if (x.w > y.w)
			{
				// octant 0
				if (x.w < 512)
					// 0x20000000 or ANG45
					return 536870912L;
				else
				{
					//tempDivision.w = (y.w << 3) / (x.w >> 8);
					tempDivision = FastDiv3232_shift_3_8(y.w, x.w);
					if (tempDivision < SLOPERANGE)
						return tantoangle[tempDivision].wu;
					else
						// 0x20000000 or ANG45
						return 536870912L;
				}
			}
			else
			{
				// octant 1
				if (y.w < 512)
					return ANG90 - 1 - 536870912L;
				else
				{
					//tempDivision.w = (x.w << 3) / (y.w >> 8);
					tempDivision = FastDiv3232_shift_3_8(x.w, y.w);

					if (tempDivision < SLOPERANGE)
						return ANG90 - 1 - tantoangle[tempDivision].wu;
					else
						return ANG90 - 1 - 536870912L;
				}
			}
		}
		else
		{
			// y<0
			y.w = -y.w;

			if (x.w > y.w)
			{
				// octant 7
				if (x.w < 512)
					return -536870912L;
				else
				{
					//tempDivision.w = (y.w << 3) / (x.w >> 8);
					tempDivision = FastDiv3232_shift_3_8(y.w, x.w);

					if (tempDivision < SLOPERANGE)
						return -(tantoangle[tempDivision].wu);
					else
						return -536870912L;
				}
			}
			else
			{
				// octant 6
				if (y.w < 512)
					return ANG270 + 536870912L;
				else
				{
					//tempDivision.w = (x.w << 3) / (y.w >> 8);
					tempDivision = FastDiv3232_shift_3_8(x.w, y.w);

					if (tempDivision < SLOPERANGE)
						return ANG270 + tantoangle[tempDivision].wu;
					else
						return ANG270 + 536870912L;
				}
			}
		}
	}
	else
	{
		// x<0
		x.w = -x.w;

		if (y.w >= 0)
		{
			// y>= 0
			if (x.w > y.w)
			{
				// octant 3
				if (x.w < 512)
					return ANG180 - 1 - 536870912L;
				else
				{
					//tempDivision.w = (y.w << 3) / (x.w >> 8);
					tempDivision = FastDiv3232_shift_3_8(y.w, x.w);

					if (tempDivision < SLOPERANGE)
						return ANG180 - 1 - tantoangle[tempDivision].wu;
					else
						return ANG180 - 1 - 536870912L;
				}
			}
			else
			{
				// octant 2
				if (y.w < 512)
					return ANG90 + 536870912L;
				else
				{
					//tempDivision.w = (x.w << 3) / (y.w >> 8);
					tempDivision = FastDiv3232_shift_3_8(x.w, y.w);

					if (tempDivision < SLOPERANGE)
						return ANG90 + tantoangle[tempDivision].wu;
					else
						return ANG90 + 536870912L;
				};
			}
		}
		else
		{
			// y<0
			y.w = -y.w;

			if (x.w > y.w)
			{
				// octant 4
				if (x.w < 512)
					return ANG180 + 536870912L;
				else
				{
					//tempDivision.w = (y.w << 3) / (x.w >> 8);
					tempDivision = FastDiv3232_shift_3_8(y.w, x.w);

					if (tempDivision < SLOPERANGE)
						return ANG180 + tantoangle[tempDivision].wu;
					else
						return ANG180 + 536870912L;
				}
			}
			else
			{
				// octant 5
				if (y.w < 512)
					return ANG270 - 1 - 536870912L;
				else
				{
					//tempDivision.w = (x.w << 3) / (y.w >> 8);
					tempDivision = FastDiv3232_shift_3_8(x.w, y.w);

					if (tempDivision < SLOPERANGE)
						return ANG270 - 1 - tantoangle[tempDivision].wu;
					else
						return ANG270 - 1 - 536870912L;
				}
			}
		}
	}
	return 0;
}
*/

uint32_t __far R_PointToAngle2 ( fixed_t_union	x1, fixed_t_union	y1, fixed_t_union	x2, fixed_t_union	y2 ) {	
    viewx.w = x1.w;
    viewy.w = y1.w;
    
    return R_PointToAngle (x2, y2);
}


uint32_t __far R_PointToAngle2_16 (  int16_t	x2, int16_t	y2 ) {	
	// this could be very optimized but is called rarely.
	fixed_t_union x2fp, y2fp;
    viewx.w = 0; // called with 0, this is fine
    viewy.w = 0;
	x2fp.h.intbits = x2;
	y2fp.h.intbits = y2;
	x2fp.h.fracbits = 0;
	y2fp.h.fracbits = 0;

    return R_PointToAngle (x2fp, y2fp);
}

/*
fixed_t __near R_PointToDist2 ( int16_t	xarg, int16_t	yarg ){
    fineangle_t		angle;
    fixed_t	dx;
    fixed_t	dy;
    fixed_t	temp;
    fixed_t	dist;
	fixed_t_union x;
	fixed_t_union y;
    x.h.fracbits = 0;
    y.h.fracbits = 0;
    x.h.intbits = xarg;
    y.h.intbits = yarg;


    dx = labs(x.w - viewx.w);
    dy = labs(y.w - viewy.w);

    if (dy>dx) {
        temp = dx;
        dx = dy;
        dy = temp;
    }
	
	angle = (tantoangle[ FixedDiv(dy,dx)>>DBITS ].hu.intbits+ANG90_HIGHBITS) >> SHORTTOFINESHIFT;

    // use as cosine
	// todo this is 32 bits over 17? probably dont need 2nd divide inside the fixed divetc...
    dist = FixedDiv (dx, finesine[angle] );	
	
    return dist;
}

fixed_t __near R_PointToDist3 ( int16_t	xarg, int16_t	yarg );

fixed_t __near R_PointToDist ( int16_t	xarg, int16_t	yarg ){
	fixed_t a =  R_PointToDist2 ( 	xarg,	yarg );
	fixed_t b =  R_PointToDist3 ( 	xarg,	yarg );
	if (a != b){
		I_Error("bad! %i %i %li %lx %li %lx", xarg, yarg, a, a, b, b);
	}

	return a;
}
*/
 

//
// R_ScaleFromGlobalAngle
// Returns the texture mapping scale
//  for the current line (horizontal span)
//  at the given angle.
// rw_distance must be calculated first.
//

/*
fixed_t __near R_ScaleFromGlobalAngle2 (fineangle_t visangle_shift3)
{
    fixed_t_union		scale;
    fineangle_t			anglea;
    fineangle_t			angleb;
    fixed_t_union		    num;
    fixed_t			den;

    anglea = MOD_FINE_ANGLE(FINE_ANG90 + (visangle_shift3 - viewangle_shiftright3));
    angleb = MOD_FINE_ANGLE(FINE_ANG90 + (visangle_shift3) - rw_normalangle);



    // both sines are allways positive
    num.w = FixedMulTrig(FINE_SINE_ARGUMENT, angleb, projection.w)<<detailshift.b.bytelow;
    den = FixedMulTrig(FINE_SINE_ARGUMENT, anglea, rw_distance);

	//TODO fast check 256/0x400000L just with bit shifts..

    if (den > num.h.intbits) {
		// todo make a custom unsigned fixeddiv that does bounds check to 0x400000L and 256. can quick-out in those cases.
		// eventualy it will be inlined, eventually the fixedmultrig will be inlined and this function will get fast.
        scale.w = FixedDiv (num.w, den);

        if (scale.h.intbits > 64){
            return 0x400000L;
            //scale.h.fracbits = 0;
		} else if (scale.w < 256) {
			return 256;
		}
		return scale.w;
    } else{
        return 0x400000L;
    }
    
}

fixed_t __near R_ScaleFromGlobalAngle (fineangle_t visangle_shift3)
{
    fixed_t a = R_ScaleFromGlobalAngle2(visangle_shift3);
    fixed_t b = R_ScaleFromGlobalAngle3(visangle_shift3);

	if (a!=b){
		I_Error("bad %i %li %li %lx", visangle_shift3, a, b, b);
	}
	return a;
	
    
}
*/






//
// R_SetViewSize
// Do not really change anything here,
//  because it might be in the middle of a refresh.
// The change will take effect next refresh.
//


void __far R_SetViewSize ( uint8_t		blocks, uint8_t		detail ) {
    setsizeneeded = true;
    setblocks = blocks;
    setdetail = detail;
}

#define DISTMAP		2


 


//
// sky mapping
//





//
// R_SetupFrame
//
void R_SetupFrame () {		
    int8_t		i;

    extralight = player.extralight;

    viewz = player.viewz;
	viewz_shortheight = viewz.w >> (16 - SHORTFLOORBITS);

    //viewsin = finesine[viewangle_shiftright3];
    //viewcos = finecosine[viewangle_shiftright3];
	
    if (player.fixedcolormap) {
		fixedcolormap =  player.fixedcolormap;
		
		walllights = scalelightfixed;

		for (i=0 ; i<MAXLIGHTSCALE ; i++){
			scalelightfixed[i] = fixedcolormap;
		}
    } else{
		fixedcolormap = 0;
	}
    validcount++;
	// i think this sets the view within the border for when screen size is increased/shrunk
    
	destview = (byte __far*)(destscreen.w + viewwindowoffset);
 


}

//
// R_RenderView
//
//void filelog2(int16_t a, int16_t b, int16_t c, int16_t d, int16_t e, int16_t f);
//int8_t tempbuf[5];
//extern int8_t lastvisplane;

#ifdef FPS_DISPLAY
int8_t fps_buf[14];
int32_t fps_rendered_frames_since_last_measure = 0;
ticcount_t fps_last_measure_start_tic = 0;
#endif 

void __far R_RenderPlayerView ()
{	

	#ifdef FPS_DISPLAY
	int32_t fps_num;
	int32_t fps_denom;
	int32_t fps;
	#endif

#ifdef DETAILED_BENCH_STATS
	cachedrenderplayertics = ticcount;
#endif

	r_cachedplayerMobjsecnum = playerMobj->secnum;
	viewx = playerMobj_pos->x;
	viewy = playerMobj_pos->y;
	viewangle = playerMobj_pos->angle;
	viewangle_shiftright1 = (viewangle.hu.intbits >> 1) & 0xFFFC;
	viewangle_shiftright3 = viewangle.hu.intbits >> 3;

	// reset last used segment cache
	lastvisspritepatch = -1;        
    cachedlump = -1;
    cachedtex = -1;
    cachedlump2 = -1;
    cachedtex2 = -1;


	if (player.psprites[0].state) {
		r_cachedstatecopy[0] = *(player.psprites[0].state);
	}
	if (player.psprites[1].state) {
		r_cachedstatecopy[1] = *(player.psprites[1].state);
	}

	Z_QuickMapRender();
	R_SetupFrame ();


    // Clear buffers.
    R_ClearClipSegs ();
    // Clear Drawsegs
	ds_p = drawsegs_PLUSONE;
    R_ClearPlanes ();

	// R_ClearSprites
	vissprite_p = vissprites;

    // check for new console commands.
	NetUpdate ();

#ifdef DETAILED_BENCH_STATS
	renderplayersetuptics += ticcount - cachedrenderplayertics;
	cachedrenderplayertics = ticcount;
#endif

	// The head node is the last node output.
	R_RenderBSPNode (numnodes-1);

#ifdef DETAILED_BENCH_STATS
	renderplayerbsptics += ticcount - cachedrenderplayertics;
	cachedrenderplayertics = ticcount;
#endif

    // Check for new console commands.
    NetUpdate ();

	// We add this here to prepare the vissprites for psprites while certain variables are in memory and not paged-out yet
	R_PrepareMaskedPSprites();

	// replace render level data with flat cache

	Z_QuickMapRenderPlanes();
    
	// cant do this in clearplanes, this field isnt in memory yet..
    FAR_memset (cachedheight, 0, sizeof(fixed_t) * SCREENHEIGHT);

	// put visplanes 0-75 back in memory (if necessary)
	if (visplanedirty){
		Z_QuickMapVisplaneRevert();
	}
    
	R_DrawPlanes ();
	// put away flat cache, put back level data
	Z_QuickMapUndoFlatCache();
 	Z_QuickMapRenderTexture();
	//Z_QuickMapSpritePage(); //todo combine somehow with above?


#ifdef DETAILED_BENCH_STATS
	renderplayerplanetics += ticcount - cachedrenderplayertics;
	cachedrenderplayertics = ticcount;
#endif

    // Check for new console commands.
    // 0x5c00 currently used in R_DrawPlanes as flat cache, but also needed in netupdate for events
	// either one extra page swap per frame or comment this out
	// todo reenable...?
	//NetUpdate ();

	R_DrawMasked ();
#ifdef DETAILED_BENCH_STATS
	renderplayermaskedtics += ticcount - cachedrenderplayertics;
#endif
	//filelog2(4, 0, 0, 0, 0, 0);

	// Check for new console commands.
	Z_QuickMapPhysics();


	// visplane hud stuff
	//sprintf(tempbuf, "%i", lastvisplane);
	//player.messagestring=tempbuf;

#ifdef FPS_DISPLAY
	// three digit decimal
	// should we instead do gametic diff > 100?
	if (fps_rendered_frames_since_last_measure > 100){
		fps_num = 35000 * fps_rendered_frames_since_last_measure; // or just global and ++ 350?
		fps_denom = ticcount - fps_last_measure_start_tic;
		fps = fps_num / fps_denom;

		sprintf(fps_buf, "FPS: %li.%li", fps / 1000, fps % 1000);
		player.messagestring=fps_buf;
		fps_rendered_frames_since_last_measure = 0;
		fps_last_measure_start_tic = ticcount;
	}

#endif

	NetUpdate ();

	/*
	if (lastvisplane > visplanemax){
		visplanemax = lastvisplane;
	}
	*/



}

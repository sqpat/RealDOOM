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
//	BSP traversal, handling of LineSegs for rendering.
//


#include "doomdef.h"

#include "m_misc.h"

#include "i_system.h"

#include "r_main.h"
#include "r_plane.h"
#include "r_things.h"

// State.
#include "doomstat.h"
#include "r_state.h"
#include "m_memory.h"
#include "m_near.h"
#include <dos.h>
#include <stdlib.h>

//#include "r_local.h"

void __near R_StoreWallRange ( int16_t start, int16_t stop );



//
// R_ClipSolidWallSegment
// Does handle solid walls,
//  e.g. single sided LineDefs (middle texture)
//  that entirely block the view.
// 
void __near R_ClipSolidWallSegment ( int16_t first, int16_t last ) {
    cliprange_t __near*	next;
    cliprange_t __near*	start;

    // Find the first range that touches the range
    //  (adjacent pixels are touching).
    start = solidsegs;
    while (start->last < first-1)
	start++;

    if (first < start->first)
    {
		if (last < start->first-1) {
			// Post is entirely visible (above start),
			//  so insert a new clippost.
			R_StoreWallRange (first, last);
			next = newend;
			newend++;

#ifdef CHECK_FOR_ERRORS
			if (newend - solidsegs > MAX_SEGS){
				I_Error("segs1"); 
			}
#endif
			// 1/11/98 killough: performance tuning using fast memmove
			memmove(start + 1, start, (++newend - start) * sizeof(*start));
			start->first = first;
			start->last = last;
			return;
		}
		
		// There is a fragment above *start.
		R_StoreWallRange (first, start->first - 1);
		// Now adjust the clip size.
		start->first = first;	
    }

    // Bottom contained in start?
	if (last <= start->last) {
		return;
	}

    next = start;
    while (last >= (next+1)->first-1) {
		// There is a fragment between two posts.
		R_StoreWallRange (next->last + 1, (next+1)->first - 1);
		next++;
	
		if (last <= next->last) {
			// Bottom is contained in next.
			// Adjust the clip size.
			start->last = next->last;	
			goto crunch;
		}
    }
	
    // There is a fragment after *next.
    R_StoreWallRange (next->last + 1, last);
    // Adjust the clip size.
    start->last = last;
	
    // Remove start+1 to next from the clip list,
    // because start now covers their area.
  crunch:
    if (next == start) {
		// Post just extended past the bottom of one post.
		return;
    }
    

    while (next++ != newend) {
	// Remove a post
		start++;
		*start = *next;

    }

    newend = start+1;
#ifdef CHECK_FOR_ERRORS
	if (newend - solidsegs > MAX_SEGS){
		I_Error("segs2"); //todo remove
	}
#endif
}



//
// R_ClipPassWallSegment
// Clips the given range of columns,
//  but does not includes it in the clip list.
// Does handle windows,
//  e.g. LineDefs with upper and lower texture.
//
void __near R_ClipPassWallSegment ( int16_t first, int16_t last ) {
    cliprange_t __near*	start;
    // Find the first range that touches the range
    //  (adjacent pixels are touching).
    start = solidsegs;
	while (start->last < first - 1) {
		start++;

	}
    if (first < start->first) {
		if (last < start->first-1) {
			// Post is entirely visible (above start).
			R_StoreWallRange (first, last);
			return;
		}
		
		// There is a fragment above *start.
		R_StoreWallRange (first, start->first - 1);
    }

    // Bottom contained in start?
	if (last <= start->last) {
		return;			
	}
    while (last >= (start+1)->first-1) {
		// There is a fragment between two posts.
		R_StoreWallRange (start->last + 1, (start+1)->first - 1);
		start++;
		if (last <= start->last) {
			return;
		}
    }
	
    // There is a fragment after *next.
    R_StoreWallRange (start->last + 1, last);
}



//
// R_ClearClipSegs
//
void __near R_ClearClipSegs (void) {
    solidsegs[0].first = -0x7fff;
    solidsegs[0].last = -1;
    solidsegs[1].first = viewwidth;
    solidsegs[1].last = 0x7fff;
    newend = solidsegs+2;
}


//
// R_AddLine
// Clips the given segment
// and adds any visible pieces to the line list.
//
void __near R_AddLine (int16_t curlineNum) {
    int16_t			x1;
    int16_t			x2;
    angle_t		angle1;
	angle_t		angle2;
    angle_t		span;
    angle_t		tspan;
	seg_render_t __near*		curline_render = &segs_render[curlineNum];

	uint8_t curlineside = *((uint8_t __far *)MK_FP(seg_linedefs_segment, curlineNum + seg_sides_offset_in_seglines));//seg_sides[curseg];
	int16_t curseglinedef =  *((int16_t __far *)MK_FP(seg_linedefs_segment, 2*curlineNum)); // seg_linedefs[curseg];


	line_t __far* curlinelinedef = &lines[curseglinedef];

	int16_t linebacksecnum;

	side_t __far* curlinesidedef = &sides[curline_render->sidedefOffset];
	vertex_t v1 = vertexes[curline_render->v1Offset];
	vertex_t v2 = vertexes[curline_render->v2Offset];
     curseg = curlineNum;
	 curseg_render = curline_render;


#ifdef CHECK_FOR_ERRORS
	if (segs[curlinenum].linedefOffset > numlines) {
		I_Error("R_Addline Error! lines out of bounds! %li %i %i %i", gametic, numlines, segs[curlinenum].linedefOffset, curlinenum);
	}
#endif

	// using span and angle2 as temporary vars to reduce local var count
    // OPTIMIZE: quickly reject orthogonal back sides.
    angle1.wu = R_PointToAngle16 (v1.x, v1.y);
    angle2.wu = R_PointToAngle16 (v2.x, v2.y);
    


    // Clip to view edges.
    // OPTIMIZE: make constant out of 2*clipangle (FIELDOFVIEW).
    span.wu = angle1.wu - angle2.wu;
	 

    // Back side? I.e. backface culling?
	if (span.hu.intbits >= ANG180_HIGHBITS) {
		return;
	}

    // Global angle needed by segcalc.
	//rw_angle1_fine = angle1.hu.intbits >> SHORTTOFINESHIFT;
	rw_angle1 = angle1;
	angle1.wu -= viewangle.wu;
    angle2.wu -= viewangle.wu;
	
    tspan.wu = angle1.wu;
	tspan.hu.intbits += clipangle;

	if (tspan.hu.intbits > fieldofview) {
		tspan.hu.intbits -= fieldofview;

		// Totally off the left edge?
		if (tspan.wu >= span.wu) {
			return;
		}
	
		angle1.hu.intbits = clipangle;
		angle1.hu.fracbits = 0; //fracbits arent used beyond this.
    }
	tspan.hu.intbits = clipangle;
	tspan.hu.fracbits = 0;

    tspan.wu -= angle2.wu;
	if (tspan.hu.intbits > fieldofview) {
		tspan.hu.intbits -= fieldofview;
	
		// Totally off the left edge?
			if (tspan.wu >= span.wu) {
				return;
			}
		angle2.hu.intbits = -clipangle;
		//angle2.hu.fracbits = 0;  fracbits arent used beyond this.
    }
    
    // The seg is in the view range,
    // but not necessarily visible.

	angle1.hu.intbits += ANG90_HIGHBITS;
	angle1.hu.intbits >>= SHORTTOFINESHIFT;
	x1 = viewangletox[angle1.hu.intbits];

	angle2.hu.intbits += ANG90_HIGHBITS;
	angle2.hu.intbits >>= SHORTTOFINESHIFT;
	x2 = viewangletox[angle2.hu.intbits];

    // Does not cross a pixel?
	if (x1 == x2) {
		return;
	}
 
	
	// todo clean up the ternary, if else instead
	//linebacksecnum = curlinelinedef->backsecnum;
		


    // Single sided line?
	if (!(lineflagslist[curseglinedef] & ML_TWOSIDED)) {
		backsector_offset = SECNUM_NULL;
		goto clipsolid;
	}

	linebacksecnum =  sides_render[curlinelinedef->sidenum[curlineside ^ 1]].secnum;	
	backsector = &sectors[linebacksecnum];

    // Closed door.
	if (backsector->ceilingheight <= frontsector->floorheight
		|| backsector->floorheight >= frontsector->ceilingheight) {
		goto clipsolid;
	}
    // Window.
    if (backsector->ceilingheight != frontsector->ceilingheight
	|| backsector->floorheight != frontsector->floorheight)
		goto clippass;	
		
    // Reject empty lines used for triggers
    //  and special events.
    // Identical floor and ceiling on both sides,
    // identical light levels on both sides,
    // and no middle texture.
    

	if (backsector->ceilingpic == frontsector->ceilingpic
		&& backsector->floorpic == frontsector->floorpic
		&& backsector->lightlevel == frontsector->lightlevel
		&& curlinesidedef->midtexture == 0) {
		return;
    }
    


  clippass:
    R_ClipPassWallSegment (x1, x2-1);	
	return;
		
  clipsolid:
	R_ClipSolidWallSegment (x1, x2-1);

}


//
// R_CheckBBox
// Checks BSP node/subtree bounding box.
// Returns true
//  if some part of the bbox might be visible.
//

boolean __near R_CheckBBox(int16_t __far *bspcoord) {
	byte boxx;
	byte boxy;
	byte boxpos;

	int16_t x1;
	int16_t y1;
	int16_t x2;
	int16_t y2;

	angle_t angle1;
	angle_t angle2;
	angle_t span;
	angle_t tspan;

	cliprange_t __near*start;

	int16_t sx1;
	int16_t sx2;

	// Find the corners of the box
	// that define the edges from current viewpoint.

	boxx = (viewx.h.intbits < bspcoord[BOXLEFT] || (viewx.h.fracbits == 0 && viewx.h.intbits == bspcoord[BOXLEFT])) 
	    ? 0 : viewx.h.intbits < bspcoord[BOXRIGHT] ? 1 : 
		2;
	boxy = viewy.h.intbits >= bspcoord[BOXTOP] ? 0 : 
	    (viewy.h.intbits > bspcoord[BOXBOTTOM] || (viewy.h.fracbits > 0 && viewy.h.intbits == bspcoord[BOXBOTTOM]  )) ? 1 : 
		 2;

	boxpos = (boxy << 2) + boxx;
	if (boxpos == 5){
		return true;
	}

	switch (boxpos) {
		case 0:
			x1 = bspcoord[BOXRIGHT];
			y1 = bspcoord[BOXTOP];
			x2 = bspcoord[BOXLEFT];
			y2 = bspcoord[BOXBOTTOM];
			break;
		case 1:
			x1 = bspcoord[BOXRIGHT];
			y1 = y2 = bspcoord[BOXTOP];
			x2 = bspcoord[BOXLEFT];
			break;
		case 2:
			x1 = bspcoord[BOXRIGHT];
			y1 = bspcoord[BOXBOTTOM];
			x2 = bspcoord[BOXLEFT];
			y2 = bspcoord[BOXTOP];
			break;
		case 3:
		case 7:
		// todo optimize since angle1 = angle 2? how common is this.
		// span would be 0
			x1 = x2 = y1 = y2 = bspcoord[BOXTOP];
			break;
		case 4:
			x1 = x2 = bspcoord[BOXLEFT];
			y1 = bspcoord[BOXTOP];
			y2 = bspcoord[BOXBOTTOM];
			break;
		case 6:
			x1 = x2 = bspcoord[BOXRIGHT];
			y1 = bspcoord[BOXBOTTOM];
			y2 = bspcoord[BOXTOP];
			break;
		case 8:
			x1 = bspcoord[BOXLEFT];
			y1 = bspcoord[BOXTOP];
			x2 = bspcoord[BOXRIGHT];
			y2 = bspcoord[BOXBOTTOM];
			break;
		case 9:
			x1 = bspcoord[BOXLEFT];
			y1 = y2 = bspcoord[BOXBOTTOM];
			x2 = bspcoord[BOXRIGHT];
			break;
		case 10:
			x1 = bspcoord[BOXLEFT];
			y1 = bspcoord[BOXBOTTOM];
			x2 = bspcoord[BOXRIGHT];
			y2 = bspcoord[BOXTOP];
			break;
	}

	// check clip list for an open space
	angle1.wu = R_PointToAngle16(x1, y1) - viewangle.wu;
	angle2.wu = R_PointToAngle16(x2, y2) - viewangle.wu;

	span.wu = angle1.wu - angle2.wu;

	// Sitting on a line?
	if (span.hu.intbits >= ANG180_HIGHBITS){
		return true;
	}

	tspan.wu = angle1.wu;
	tspan.hu.intbits += clipangle;

	if (tspan.hu.intbits > fieldofview) {
		tspan.hu.intbits -= fieldofview;

		// Totally off the left edge?
		if (tspan.wu >= span.wu){
			return false;
		}

		angle1.hu.intbits = clipangle;
		angle1.hu.fracbits = 0;
	}
	tspan.hu.intbits = clipangle;
	tspan.hu.fracbits= 0;
	tspan.wu -= angle2.wu;

	if (tspan.hu.intbits > fieldofview) {
		tspan.hu.intbits -= fieldofview;

		// Totally off the left edge?
		if (tspan.wu >= span.wu){
			return false;
		}

		angle2.hu.intbits = -clipangle;
	}

	// Find the first clippost
	//  that touches the source post
	//  (adjacent pixels are touching).
	sx1 = (angle1.hu.intbits + ANG90_HIGHBITS) >> SHORTTOFINESHIFT;
	sx2 = (angle2.hu.intbits + ANG90_HIGHBITS) >> SHORTTOFINESHIFT;
	sx1 = viewangletox[sx1];
	sx2 = viewangletox[sx2]; 
 

	// Does not cross a pixel.
	if (sx1 == sx2){
		return false;
	}
	sx2--;

	start = solidsegs;
	while (start->last < sx2){
		start++;
	}

	if (sx1 >= start->first && sx2 <= start->last) {
		// The clippost contains the new span.
		return false;
	}

	return true;
}

//
// R_Subsector
// Determine floor/ceiling planes.
// Add sprites of things in sector.
// Draw one or more line segments.
//
void __near R_Subsector(int16_t subsecnum);
/*
void __near R_Subsector(int16_t subsecnum) {
	int16_t count = subsector_lines[subsecnum];
	subsector_t __far* sub = &subsectors[subsecnum];
	int16_t firstline = sub->firstline;
	fixed_t_union temp;
    frontsector = &sectors[sub->secnum];
	temp.h.fracbits = 0;
	

	if (visplanedirty){
		Z_QuickMapVisplaneRevert();
	}

	ceilphyspage = 0;
	floorphyspage = 0;
	ceiltop = NULL;
	floortop = NULL;

	// clean these indices before we start this subsector...

	SET_FIXED_UNION_FROM_SHORT_HEIGHT(temp, frontsector->floorheight);

	if (temp.w < viewz.w) {
		visplanepiclight_t picandlight;
		picandlight.bytes.lightlevel = frontsector->lightlevel;
		picandlight.bytes.picnum = frontsector->floorpic;
		floorplaneindex = R_FindPlane(temp.w, IS_FLOOR_PLANE, picandlight);
	} else {
		floorplaneindex = -1;
	}

	SET_FIXED_UNION_FROM_SHORT_HEIGHT(temp, frontsector->ceilingheight);
	// todo: see if frontsector->ceilingheight > viewz.h.intbits would work. same above -sq
	
	if (temp.w > viewz.w || frontsector->ceilingpic == skyflatnum) {
		visplanepiclight_t picandlight;
		picandlight.bytes.lightlevel = frontsector->lightlevel;
		picandlight.bytes.picnum = frontsector->ceilingpic;
		ceilingplaneindex = R_FindPlane(temp.w, IS_CEILING_PLANE, picandlight);
	} else {
		ceilingplaneindex = -1;
	}

	R_AddSprites(frontsector);

	while (count--)	{
		R_AddLine(firstline);
		firstline++;
	}
}

*/

// put these functions here because it runs in this code section with this memory mapping. no masked-like 7000 remap
#define BASEYCENTER                     100L
#define MINZ_HIGHBITS					4

//
// R_DrawPSprite
//
//todo pass in frame and sprite only.
void __near R_DrawPSprite (pspdef_t __near* psp, spritenum_t sprite, spriteframenum_t frame,  vissprite_t __near* vis){
    fixed_t_union           tx;
	int16_t                 x1;
	int16_t                 x2;
	int16_t                 spriteindex;
	int16_t                 usedwidth;
    boolean             flip;
	spriteframe_t __far*		spriteframes;
    fixed_t_union temp;


	// decide which patch to use
	spriteframes = (spriteframe_t __far*)&(spritedefs_bytes[sprites[sprite].spriteframesOffset]);


    spriteindex = spriteframes[frame & FF_FRAMEMASK].lump[0];
    flip = (boolean)spriteframes[frame & FF_FRAMEMASK].flip[0];
    
    // calculate edges of the shape
	tx.w = psp->sx;// -160 * FRACUNIT;

    // spriteoffsets are only ever negative for psprite - we store as a uint and subtract in that case.
	tx.h.intbits += spriteoffsets[spriteindex];
	tx.h.intbits -= 160;

	temp.h.fracbits = 0;
	temp.h.intbits = centerx;
	if (pspritescale) {
		temp.w += FixedMul16u32(pspritescale, tx.w);
	}
	else {
		temp.w += tx.w;
	}

    x1 = temp.h.intbits;


 	temp.h.fracbits = 0;
    usedwidth =  *((uint8_t __far *)MK_FP(spritewidths_segment, spriteindex));
    if (usedwidth == 1){
        usedwidth = 257;
    }

    tx.h.intbits += usedwidth;

	temp.h.intbits = centerx;
	if (pspritescale) {
		temp.w += FixedMul16u32(pspritescale, tx.w);
	} else {
		temp.w += tx.w;
	}
    x2 = temp.h.intbits - 1;

    
    // store information in a vissprite
    temp.h.fracbits = 0;
    temp.h.intbits = spritetopoffsets[spriteindex];
        // hack to make this fit in 8 bits, check r_init.c
    if (temp.h.intbits == -128){
        temp.h.intbits = 129;
    }

	vis->texturemid = (BASEYCENTER<<FRACBITS)+FRACUNIT/2-(psp->sy-temp.w);
    vis->x1 = x1 < 0 ? 0 : x1;
    vis->x2 = x2 >= viewwidth ? viewwidth-1 : x2;       
	if (pspritescale) {
		vis->scale = (int32_t)pspritescale << detailshift.b.bytelow;
	} else {
		vis->scale = FRACUNIT << detailshift.b.bytelow;
	}
    
    if (flip) {
        vis->xiscale = -pspriteiscale;
        temp.h.intbits = usedwidth;
		vis->startfrac = temp.w - 1;
    } else {
        vis->xiscale = pspriteiscale;
        vis->startfrac = 0;
    }
    
    if (vis->x1 > x1)
        vis->startfrac += FastMul16u32u((vis->x1-x1),  vis->xiscale);

    vis->patch = spriteindex;

    if (player.powers[pw_invisibility] > 4*32
        || player.powers[pw_invisibility] & 8) {
        // shadow draw
        vis->colormap = COLORMAP_SHADOW;
    } else if (fixedcolormap) {
        // fixed color
        vis->colormap = fixedcolormap;
    } else if (frame & FF_FULLBRIGHT) {
        // full bright
        vis->colormap = 0;
    } else {
        // local light
        vis->colormap = *((int8_t __far*)MK_FP(scalelightfixed_segment, spritelights+MAXLIGHTSCALE-1));
    }

}

void __near R_PrepareMaskedPSprites(void) {
	uint8_t         i;
	uint8_t         lightnum;
	statenum_t      pspstatenum;
	// get light level
	lightnum = (sectors[r_cachedplayerMobjsecnum].lightlevel >> LIGHTSEGSHIFT) +extralight;

	//    if (lightnum < 0)          
	// not sure if this hack is necessary.. since its unsigned we loop around if its below 0 
	if (lightnum > 240) {
		spritelights = 0;
	} else if (lightnum >= LIGHTLEVELS) {
		spritelights = lightmult48lookup[LIGHTLEVELS - 1];
	} else {
		spritelights = lightmult48lookup[lightnum];
	}

    for (i = 0; i < NUMPSPRITES; i++){
        statenum_t pspstatenum = psprites[i].statenum;
        if (pspstatenum != STATENUM_NULL) {
            R_DrawPSprite(&psprites[i], states_render[pspstatenum].sprite, states_render[pspstatenum].frame, &player_vissprites[i]);
        }
    }


}

//
// R_ProjectSprite
// Generates a vissprite for a thing
//  if it might be visible.
//
void __near R_ProjectSprite (mobj_pos_t __far* thing){
    fixed_t_union             tr_x;
    fixed_t_union             tr_y;
    
    fixed_t_union             gxt;
    fixed_t_union             gyt;
    
    fixed_t_union             tx;
    fixed_t_union             tz;

    fixed_t_union             xscale;
    
	int16_t                 x1;
	int16_t                 x2;

	int16_t                 spriteindex;
    int16_t                 usedwidth;
    
	uint8_t            rot = 0;
    boolean             flip;
    
	int16_t                 index;

    vissprite_t __near*        vis;
    
    angle_t             ang;
    fixed_t             iscale;
	spriteframe_t __far*		spriteframes;
	
	spritenum_t thingsprite     = states_render[thing->stateNum].sprite;
	spriteframenum_t thingframe = states_render[thing->stateNum].frame;

	vissprite_t     overflowsprite;

	fixed_t_union thingx = thing->x;
	fixed_t_union thingy = thing->y;
	fixed_t_union thingz = thing->z;
	int16_t thingflags2 = thing->flags2;
	angle_t thingangle = thing->angle;
    fixed_t_union temp;
		
	// transform the origin point
    tr_x.w = thingx.w - viewx.w;
    tr_y.w = thingy.w - viewy.w;
        
    gxt.w = FixedMulTrigNoShift(FINE_COSINE_ARGUMENT, viewangle_shiftright1 ,tr_x.w);
    gyt.w = -FixedMulTrigNoShift(FINE_SINE_ARGUMENT, viewangle_shiftright1 ,tr_y.w);
    
    tz.w = gxt.w-gyt.w; 

    // thing is behind view plane?
    if (tz.h.intbits < MINZ_HIGHBITS){ // (- sq: where does this come from)
        return;
    }

        
    xscale.w = FixedDivWholeA(centerx, tz.w);
        
    gxt.w = -FixedMulTrigNoShift(FINE_SINE_ARGUMENT, viewangle_shiftright1 ,tr_x.w);
    gyt.w = FixedMulTrigNoShift(FINE_COSINE_ARGUMENT, viewangle_shiftright1 ,tr_y.w);
    tx.w = -(gyt.w+gxt.w); 

    // too far off the side?
    if (labs(tx.w)>(tz.w<<2)) // check just high 16 bits?
        return;

    // decide which patch to use for sprite relative to player
	spriteframes = (spriteframe_t __far*)&(spritedefs_bytes[sprites[thingsprite].spriteframesOffset]);

    if (spriteframes[thingframe & FF_FRAMEMASK].rotate) {
        // choose a different rotation based on player view
		ang.wu = R_PointToAngle (thingx, thingy);
		rot = _rotl(ang.hu.intbits - thingangle.hu.intbits + 0x9000u, 3) & 0x07;

    }

    spriteindex = spriteframes[thingframe & FF_FRAMEMASK].lump[rot];
    flip = (boolean)spriteframes[thingframe & FF_FRAMEMASK].flip[rot];

    // calculate edges of the shape
    temp.h.fracbits = 0;
    temp.h.intbits = spriteoffsets[spriteindex];
	tx.w -= temp.w;
	temp.h.intbits = centerx;
    temp.w +=  FixedMul (tx.w,xscale.w);
    x1 = temp.h.intbits;

    // off the right side?
    if (x1 > viewwidth){
        return;
    }
    
    usedwidth =  *((uint8_t __far*) MK_FP(spritewidths_segment, spriteindex));

    if (usedwidth == 1){
        usedwidth = 257;
    }

    temp.h.fracbits = 0;
    temp.h.intbits = usedwidth;
    // hack to make this fit in 8 bits, check r_init.c

    tx.w +=  temp.w;
	temp.h.intbits = centerx;
	temp.w += FixedMul (tx.w,xscale.w);
    x2 = temp.h.intbits - 1;

	

    // off the left side
    if (x2 < 0)
        return;
    // store information in a vissprite

	if (vissprite_p == MAXVISSPRITES) {
		vis = &overflowsprite;
	}
	vissprite_p++;
	vis = &vissprites[vissprite_p - 1];

    vis->scale = xscale.w<<detailshift.b.bytelow;
    vis->gx = thingx;
    vis->gy = thingy;
    vis->gz = thingz;
    temp.h.fracbits = 0;
    temp.h.intbits = spritetopoffsets[spriteindex];
    
    // hack to make this fit in 8 bits, check r_init.c
    if (temp.h.intbits == -128){
        temp.h.intbits = 129;
    }

	vis->gzt.w = vis->gz.w + temp.w;
//	vis->gzt = thingz + spritetopoffset[lump];
    vis->texturemid = vis->gzt.w - viewz.w;
    vis->x1 = x1 < 0 ? 0 : x1;
    vis->x2 = x2 >= viewwidth ? viewwidth-1 : x2;       
    
	// todo does a quick  inverse function exist? considering this is fixed point
	iscale = FixedDivWholeA (1, xscale.w);

    if (flip) {
        temp.h.fracbits = 0;
        temp.h.intbits = usedwidth;
		vis->startfrac = temp.w-1;
        vis->xiscale = -iscale;
    } else {
        vis->startfrac = 0;
        vis->xiscale = iscale;
    }

    if (vis->x1 > x1)
        vis->startfrac += FastMul16u32u((vis->x1-x1),vis->xiscale);

    vis->patch = spriteindex;
    
    // get light level
    if (thingflags2 & MF_SHADOW) {
        // shadow draw
        vis->colormap = COLORMAP_SHADOW;
    } else if (fixedcolormap) {
        // fixed map
        vis->colormap = fixedcolormap;
    } else if (thingframe & FF_FULLBRIGHT) {
        // full bright
        vis->colormap = 0;
    } else {
        // diminished light
        index = xscale.w>>(LIGHTSCALESHIFT-detailshift.b.bytelow);

        if (index >= MAXLIGHTSCALE) {
            index = MAXLIGHTSCALE-1;
        }

        vis->colormap = *((int8_t __far*)MK_FP(scalelightfixed_segment, spritelights+index));
    }

	
}




//
// R_AddSprites
// During BSP traversal, this adds sprites by sector.
//

void __near R_AddSprites (sector_t __far* sec) {
	THINKERREF				thingRef;
	int16_t                 lightnum;

    // BSP is traversed by subsector.
    // A sector might have been split into several
    //  subsectors during BSP building.
    // Thus we check whether its already added.
    

	if (sec->validcount == validcount){
        return;         
	}
    // Well, now it will be done.
	sec->validcount = validcount;
        
    lightnum = (sec->lightlevel >> LIGHTSEGSHIFT)+extralight;

	if (lightnum < 0) {
		spritelights = 0;
	} else if (lightnum >= LIGHTLEVELS) {
		spritelights = lightmult48lookup[LIGHTLEVELS - 1];
	} else {
		spritelights = lightmult48lookup[lightnum];
	}


    // Handle all things in sector.
	if (sec->thinglistRef) {
		mobj_pos_t __far*             thing;

		for (thingRef = sec->thinglistRef; thingRef; thingRef = thing->snextRef) {
			thing = (mobj_pos_t __far*)&mobjposlist[thingRef];
			R_ProjectSprite(thing);
		}

	}





}


//
// RenderBSPNode
// Renders all subsectors below a given node,
//  traversing subtree recursively.
// Just call with BSP root.


#define MAX_BSP_DEPTH 64

void __far R_RenderBSPNode() {
	int16_t stack_bsp[MAX_BSP_DEPTH];
	byte stack_side[MAX_BSP_DEPTH];
	int16_t sp = 0;
	int16_t bspnum = numnodes - 1;
	byte side;
	

	while (true) {
		//Front sides.
		while ((bspnum & NF_SUBSECTOR) == 0) {
			// get rid of this?
			//if (sp == MAX_BSP_DEPTH)
			//	break;
			node_t  __far* bsp = &nodes[bspnum];
			int16_t dx = viewx.h.intbits - bsp->x;
			int16_t dy = viewy.h.intbits - bsp->y;
			int16_t intermediate = bsp->dy ^ dx;

			//decide which side the view point is on
			// todo try and use just the high 16 bits (dont subtract w's, they may not even be used below?)

			// is a*b > c*d?
			// i have a feeling there might be a clever fast way to determine this?

			// check signs... if one side is positive and the other negative, then we dont need to multiply to 
			// figure out which is larger
			if ((intermediate ^ dy ^ bsp->dx) & 0x8000){
				side = ROLAND1(intermediate);
			} else {

				// in asm grab the fields to dx:ax, cx:bx and xchg after first mul, then compare after 2nd.
				// side calculation should fit in ax thru dx.

				fixed_t left =	FastMul1616(bsp->dy, dx);
				fixed_t right = FastMul1616(bsp->dx, dy);

				side = right > left;

			}

			stack_bsp[sp] = bspnum;
			stack_side[sp] = side;

			sp++;

			bspnum = node_children[bspnum].children[side];
		}
		 
		if (bspnum == -1){
			R_Subsector(0);
		} else {
			R_Subsector(bspnum & (~NF_SUBSECTOR));
		}
		if (sp == 0) {
			//back at root node and not visible. All done!
			return;
		}

		//Back sides.

		sp--;

		bspnum = stack_bsp[sp];
		side = stack_side[sp];

		// Possibly divide back space.
		//Walk back up the tree until we find
		//a node that has a visible backspace.



		while (!R_CheckBBox(((node_render_t __far *)MK_FP(NODES_RENDER_SEGMENT+ bspnum, 0))->bbox[side ^ 1]))  // - todo only used once, is it better to inline this? - sq
		{
			if (sp == 0) {
				//back at root node and not visible. All done!
				return;
			}

			//Back side next.

			sp--;

			bspnum = stack_bsp[sp];
			side = stack_side[sp];

		}

		bspnum = node_children[bspnum].children[side ^ 1];
	}
}




/*

void __far R_RenderBSPNode(int16_t bspnum) {

	int16_t side;
	node_t __far *bsp_node;

	if (bspnum & NF_SUBSECTOR) {
		if (bspnum == -1) {
			R_Subsector(0);
		} else {
			R_Subsector(bspnum&(~NF_SUBSECTOR));
		}
		return;
    }
	bsp_node = &nodes[bspnum];

	
	side = FastMul1616(bsp_node->dx, viewy.h.intbits-bsp_node->y) > 
		   FastMul1616(bsp_node->dy, viewx.h.intbits-bsp_node->x);

	// do both
	if (R_CheckBBox(&nodes_render[bspnum].bbox[side ^ 1])){
		int16_t childa, childb;
		childa = node_children[bspnum].children[side];
		childb = node_children[bspnum].children[side^1];
		R_RenderBSPNode (childa); 
		R_RenderBSPNode (childb);
		
	} else {
		R_RenderBSPNode (node_children[bspnum].children[side]); 
	}

}
*/



 

//386     42712 vs 40728 recursive way way slower (?)
//pentium 4416 v s 4403  recursive faster (?)

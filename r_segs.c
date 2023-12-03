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
//	All the clipping: columns, horizontal spans, sky columns.
//


#include <stdlib.h>

#include "i_system.h"

#include "doomdef.h"
#include "doomstat.h"

#include "r_local.h"
#include "z_zone.h"

// OPTIMIZE: closed two sided lines as single sided

// True if any of the segs textures might be visible.
boolean		segtextured;	

// False if the back side is the same plane.
boolean		markfloor;	
boolean		markceiling;

boolean		maskedtexture;
uint8_t		toptexture;
uint8_t		bottomtexture;
uint8_t		midtexture;


fineangle_t	rw_normalangle;
// angle to line origin
angle_t		rw_angle1;	

//
// regular wall
//
int16_t		rw_x;
int16_t		rw_stopx;
fineangle_t		rw_centerangle;
fixed_t		rw_offset;
fixed_t		rw_distance;
fixed_t_union		rw_scale;
int16_t		rw_scalestep;
fixed_t		rw_midtexturemid;
fixed_t		rw_toptexturemid;
fixed_t		rw_bottomtexturemid;

fixed_t		worldtop;
fixed_t		worldbottom;
fixed_t		worldhigh;
fixed_t		worldlow;

fixed_t		pixhigh;
fixed_t		pixlow;
fixed_t		pixhighstep;
fixed_t		pixlowstep;

fixed_t		topfrac;
fixed_t		topstep;

fixed_t		bottomfrac;
fixed_t		bottomstep;


lighttable_t**	walllights;

int16_t*		maskedtexturecol;



//
// R_RenderMaskedSegRange
//
void
R_RenderMaskedSegRange
(drawseg_t*	ds,
	int16_t		x1,
	int16_t		x2)
{
	uint16_t	index;
	column_t*	col;
	int16_t		lightnum;
	fixed_t_union temp;


	
	sector_t frontsector;
	sector_t backsector;
	int16_t temp2;
	seg_t curline = segs[ds->curlinenum];
	side_t side = sides[curline.sidedefOffset];
	int16_t curlineside = curline.v2Offset & SEG_V2_SIDE_1_HIGHBIT ? 1 : 0;
	vertex_t v1 = vertexes[curline.v1Offset];
	vertex_t v2 = vertexes[curline.v2Offset & SEG_V2_OFFSET_MASK];
	line_t sideline = lines[curline.linedefOffset];
	int16_t		texnum = texturetranslation[side.midtexture];
	// Calculate light table.
	// Use different light tables
	//   for horizontal / vertical / diagonal. Diagonal?
	// OPTIMIZE: get rid of LIGHTSEGSHIFT globally
	curlinenum = ds->curlinenum;
	


	frontsecnum = sides[sideline.sidenum[curlineside]].secnum;
	backsecnum =
		sideline.flags & ML_TWOSIDED ?
		sides[sideline.sidenum[curlineside ^ 1]].secnum
		: SECNUM_NULL;


	frontsector = sectors[frontsecnum];
	backsector = sectors[backsecnum];

	lightnum = (frontsector.lightlevel >> LIGHTSEGSHIFT) + extralight;
	
	if (v1.y == v2.y) {
		lightnum--;
	}
	else if (v1.x == v2.x) {
		lightnum++;
	}
	if (lightnum < 0){
		walllights = scalelight[0];
	} else if (lightnum >= LIGHTLEVELS) {
		walllights = scalelight[LIGHTLEVELS - 1];
	} else {
		walllights = scalelight[lightnum];
	}
    maskedtexturecol = ds->maskedtexturecol;

    rw_scalestep = ds->scalestep;		
    spryscale.w = ds->scale1 + (x1 - ds->x1)*rw_scalestep;
    mfloorclip = ds->sprbottomclip;
    mceilingclip = ds->sprtopclip;
    
    // find positioning
    if (sideline.flags & ML_DONTPEGBOTTOM) {
		// temp.h.intbits = (frontsector.floorheight > backsector.floorheight ? frontsector.floorheight : backsector.floorheight) >> SHORTFLOORBITS;
		 //temp.b.intbytelow = textureheight >> (8 - SHORTFLOORBITS);
		 //temp.b.fracbytehigh = textureheight << (SHORTFLOORBITS);
		// temp.h.intbits += textureheight[texnum];
		temp2 = (frontsector.floorheight > backsector.floorheight ? frontsector.floorheight : backsector.floorheight)  + (textureheights[texnum]<<(SHORTFLOORBITS + 8));
		SET_FIXED_UNION_FROM_SHORT_HEIGHT(temp, temp2);
		dc_texturemid =  temp.w - viewz.w;
    } else {
		// temp.h.intbits = (frontsector.ceilingheight< backsector.ceilingheight ? frontsector.ceilingheight : backsector.ceilingheight) >> SHORTFLOORBITS;
		temp2 = (frontsector.ceilingheight< backsector.ceilingheight ? frontsector.ceilingheight : backsector.ceilingheight) ;
		SET_FIXED_UNION_FROM_SHORT_HEIGHT(temp, temp2);
		dc_texturemid = temp.w - viewz.w;
    }
	temp.h.intbits = side.rowoffset;
	temp.h.fracbits = 0;
    dc_texturemid += temp.w;
			
    if (fixedcolormap)
	dc_colormap = fixedcolormap;
    
    // draw the columns
    for (dc_x = x1 ; dc_x <= x2 ; dc_x++)
    {
	// calculate lighting
	if (maskedtexturecol[dc_x] != MAXSHORT) {
	    if (!fixedcolormap) {

			// prevents a 12 bit shift in many cases. 
			// Rather than checking if (rw_scale >> 12) > 48, we check if rw_scale high bit > (12 << 4)
			if (spryscale.h.intbits >= 3) {
				index = MAXLIGHTSCALE - 1;
			}
			else {
				index = spryscale.w >> LIGHTSCALESHIFT;
			}

		dc_colormap = walllights[index];
	    }
			
	    sprtopscreen = centeryfrac.w - FixedMul(dc_texturemid, spryscale.w);
	    dc_iscale = 0xffffffffu / (uint32_t)spryscale.w;
	    
	    // draw the texture
	    col = (column_t *)((byte *)R_GetColumn(texnum,maskedtexturecol[dc_x]) -3);
	    R_DrawMaskedColumn (col);
		//Z_SetUnlocked(lockedRef);
		maskedtexturecol[dc_x] = MAXSHORT;
	}
	spryscale.w += rw_scalestep;
    }
	
}




//
// R_RenderSegLoop
// Draws zero, one, or two textures (and possibly a masked
//  texture) for walls.
// Can draw or mark the starting pixel of floor and ceiling
//  textures.
// CALLED: CORE LOOPING ROUTINE.
//
#define HEIGHTBITS		12
#define HEIGHTUNIT		(1<<HEIGHTBITS)

void R_RenderSegLoop (void)
{
    fineangle_t		angle;
	uint16_t		index;
    int16_t			yl;
    int16_t			yh;
    int16_t			mid;
    int16_t		texturecolumn;
    int16_t			top;
    int16_t			bottom;
	fixed_t_union temp;
	

	for ( ; rw_x < rw_stopx ; rw_x++) {
		// mark floor / ceiling areas
		yl = (topfrac+HEIGHTUNIT-1)>>HEIGHTBITS;

		// no space above wall?
		if (yl < ceilingclip[rw_x]+1){
			yl = ceilingclip[rw_x]+1;
		}

		if (markceiling) {
			top = ceilingclip[rw_x]+1;
			bottom = yl-1;

			if (bottom >= floorclip[rw_x])
			bottom = floorclip[rw_x]-1;

			if (top <= bottom) {
				if (ceilingplaneindex < MAXCONVENTIONALVISPLANES){
					visplanes[ceilingplaneindex].top[rw_x] = top;
					visplanes[ceilingplaneindex].bottom[rw_x] = bottom;
				} else {
					visplanebytes_t* ceilingplanebytes = &(((visplanebytes_t*)Z_LoadBytesFromEMS(visplanebytesRef[visplaneheaders[ceilingplaneindex-MAXCONVENTIONALVISPLANES].visplanepage]))[visplaneheaders[ceilingplaneindex-MAXCONVENTIONALVISPLANES].visplaneoffset]);
					ceilingplanebytes->top[rw_x] = top;
					ceilingplanebytes->bottom[rw_x] = bottom;
				}
			}
		}
		
			
		yh = bottomfrac>>HEIGHTBITS;

		if (yh >= floorclip[rw_x]){
			yh = floorclip[rw_x]-1;
		}

		if (markfloor) {
			top = yh+1;
			bottom = floorclip[rw_x]-1;
			if (top <= ceilingclip[rw_x]){
				top = ceilingclip[rw_x]+1;
			}
			if (top <= bottom) {
				if (floorplaneindex < MAXCONVENTIONALVISPLANES){
					visplanes[floorplaneindex].top[rw_x] = top;
					visplanes[floorplaneindex].bottom[rw_x] = bottom;
				} else {
					visplanebytes_t* floorplanebytes = &(((visplanebytes_t*)Z_LoadBytesFromEMS(visplanebytesRef[visplaneheaders[floorplaneindex-MAXCONVENTIONALVISPLANES].visplanepage]))[visplaneheaders[floorplaneindex-MAXCONVENTIONALVISPLANES].visplaneoffset]);
					floorplanebytes->top[rw_x] = top;
					floorplanebytes->bottom[rw_x] = bottom;
				}
			}
		}




		// texturecolumn and lighting are independent of wall tiers
		if (segtextured) {
			// calculate texture offset
			angle = MOD_FINE_ANGLE (rw_centerangle + xtoviewangle[rw_x]);
			temp.w = rw_offset-FixedMul(finetangent(angle),rw_distance);
			texturecolumn = temp.h.intbits;
	    
			// calculate lighting

			// prevents a 12 bit shift in many cases. 
			// Rather than checking if (rw_scale >> 12) > 48, we check if rw_scale high bit > (12 << 4)
			if (rw_scale.h.intbits >= 3) {
				index = MAXLIGHTSCALE - 1;
			} else {
				index = rw_scale.w >> LIGHTSCALESHIFT;
			}


			dc_colormap = walllights[index];
			dc_x = rw_x;
			dc_iscale = 0xffffffffu / (uint32_t)rw_scale.w;
		}

		// draw the wall tiers
		if (midtexture) {
			// single sided line
			dc_yl = yl;
			dc_yh = yh;
			dc_texturemid = rw_midtexturemid;

			dc_source = R_GetColumn(midtexture,texturecolumn);
			colfunc();
			//Z_SetUnlocked(lockedRef);
			ceilingclip[rw_x] = viewheight;
			floorclip[rw_x] = -1;
		} else {
	    
		
			// two sided line
			if (toptexture) {
				// top wall
				mid = pixhigh>>HEIGHTBITS;
				pixhigh += pixhighstep;

				if (mid >= floorclip[rw_x])
					mid = floorclip[rw_x]-1;

				if (mid >= yl) {
					dc_yl = yl;
					dc_yh = mid;
					dc_texturemid = rw_toptexturemid;

					dc_source = R_GetColumn(toptexture,texturecolumn);
					colfunc();
					//Z_SetUnlocked(lockedRef);
					ceilingclip[rw_x] = mid;
				} else {
					ceilingclip[rw_x] = yl - 1;
				}
			} else {
				// no top wall
				if (markceiling) {
					ceilingclip[rw_x] = yl - 1;
				}
			}
			
			if (bottomtexture) {
				// bottom wall
				mid = (pixlow + HEIGHTUNIT - 1) >> HEIGHTBITS;
				pixlow += pixlowstep;

				// no space above wall?
				if (mid <= ceilingclip[rw_x]) {
					mid = ceilingclip[rw_x] + 1;
				}
				if (mid <= yh) {
					dc_yl = mid;
					dc_yh = yh;
					dc_texturemid = rw_bottomtexturemid;

					dc_source = R_GetColumn(bottomtexture, texturecolumn);
					colfunc();
					//Z_SetUnlocked(lockedRef);
					floorclip[rw_x] = mid;
				}
				else {
					floorclip[rw_x] = yh + 1;
				}
			} else {
				// no bottom wall
				if (markfloor) {
					floorclip[rw_x] = yh + 1;
				}
			}
			
			if (maskedtexture) {
				// save texturecol
				//  for backdrawing of masked mid texture
				maskedtexturecol[rw_x] = texturecolumn;
			}
			
		}
		
		rw_scale.w += rw_scalestep;
		topfrac += topstep;
		bottomfrac += bottomstep;
	}

}



//
// R_StoreWallRange
// A wall segment will be drawn
//  between start and stop pixels (inclusive).
//
// Note: Start/stop refer to x coordinate pixels

// sq note: temp and temp angle have become confusing here, but basically angles are uint32_t
// while normal fixed_t is int32_t, and you have to make sure you use angles and fixed_t in the
// correct spots or you end up doing things like comparisons between uint32_t and int32_t.
void
R_StoreWallRange
( int16_t	start,
  int16_t	stop )
{
    fixed_t		hyp;
    fixed_t		sineval;
    fineangle_t	distangle, offsetangle;
    fixed_t		vtop;
    int16_t			lightnum;

	// needs to be refreshed...
	seg_t curline = segs[curlinenum];
	side_t side = sides[curline.sidedefOffset];
	vertex_t curlinev1 = vertexes[curline.v1Offset];
	vertex_t curlinev2 = vertexes[curline.v2Offset&SEG_V2_OFFSET_MASK];
	texsize_t sidetextureoffset;
	int16_t lineflags;
	sector_t frontsector;
	sector_t backsector;
	fixed_t_union temp;
	angle_t tempangle;
	int16_t temp2;
	int16_t animateoffset = 0;
	temp.h.fracbits = 0;
	tempangle.h.fracbits = 0;

	if (ds_p == &drawsegs[MAXDRAWSEGS])
		return;		
		 
	linedefOffset = curline.linedefOffset;


#ifdef CHECK_FOR_ERRORS
	if (linedefOffset > numlines) {
		I_Error("R_StoreWallRange Error! lines out of bounds! %i %i %i %i", gametic, numlines, linedefOffset, curlinenum);
	}
#endif

    // mark the segment as visible for auto map

	seenlines[linedefOffset/8] |= (0x01 << (linedefOffset % 8));

	lineflags = lines[linedefOffset].flags;

	// if this is an animated line and offset 0 then set texture offset
	if (lines[linedefOffset].special == 48 && lines[linedefOffset].sidenum[0] == curline.sidedefOffset){
		animateoffset = gametic;
	}
    
    // calculate rw_distance for scale calculation
    rw_normalangle = MOD_FINE_ANGLE(curline.fineangle + FINE_ANG90);

/*
	tempangle.h.intbits = rw_normalangle;
	tempangle.h.intbits <<= 3;
	tempangle.w -= rw_angle1.w;
	tempangle.w = labs(tempangle.w);
	tempangle.h.intbits >>= 3;

	offsetangle = tempangle.h.intbits;
	tempangle.h.fracbits = 0;
	*/
	offsetangle = abs((rw_normalangle << 3)- (rw_angle1.h.intbits)) >> 3;
    
    if (offsetangle > FINE_ANG90)
		offsetangle = 	FINE_ANG90;

    distangle = FINE_ANG90 - offsetangle;

	hyp = R_PointToDist (curlinev1.x, curlinev1.y);
    sineval = finesine(distangle);
    rw_distance = FixedMulTrig(hyp, sineval);
		
	
    ds_p->x1 = rw_x = start;
    ds_p->x2 = stop;
    ds_p->curlinenum = curlinenum;
    rw_stopx = stop+1;


	tempangle.h.intbits = xtoviewangle[start];
	tempangle.h.intbits <<= 3;
	tempangle.w += viewangle.w;

    // calculate scale at both ends and step
    ds_p->scale1 = rw_scale.w =  R_ScaleFromGlobalAngle (tempangle);
	tempangle.h.fracbits = 0;

    if (stop > start ) {
		fixed_t_union rw_scalestep_extraprecision = { 0L };
		tempangle.h.intbits = xtoviewangle[stop];
		tempangle.h.intbits <<= 3;
		tempangle.w += viewangle.w;
	
		ds_p->scale2 = R_ScaleFromGlobalAngle (tempangle);

		// this is jank (using 32 bits for rw_scalestep) but the precision is actually
		// necessary for rare situations, generally when screen size is greatly lowered
		// and something is being drawn at a near 90 degree angle. In those cases the
		// precision needed is too great.
		rw_scalestep_extraprecision.w =  (ds_p->scale2 - rw_scale.w) / (stop-start);

		if (rw_scalestep_extraprecision.w == rw_scalestep_extraprecision.h.fracbits) {
			rw_scalestep = rw_scalestep_extraprecision.h.fracbits;
			//rw_scalestep_extraprecision.h.fracbits = 0;
		} else {
			// Clip to max. When i do this happens i don't see any visual artifacts personally...
			rw_scalestep = 32767;
			//rw_scalestep_extraprecision.h.fracbits = 0;

		}
		
		ds_p->scalestep = rw_scalestep;

		tempangle.h.fracbits = 0;

    } else {
		ds_p->scale2 = ds_p->scale1;
    }
    
	frontsector = sectors[frontsecnum];


    // calculate texture boundaries
    //  and decide if floor / ceiling marks are needed
    // temp.h.intbits = frontsector.ceilingheight >> SHORTFLOORBITS;
	SET_FIXED_UNION_FROM_SHORT_HEIGHT(temp, frontsector.ceilingheight);
	worldtop = temp.w - viewz.w;
    // temp.h.intbits = frontsector.floorheight >> SHORTFLOORBITS;
	SET_FIXED_UNION_FROM_SHORT_HEIGHT(temp, frontsector.floorheight);
    worldbottom = temp.w - viewz.w;
	
    midtexture = toptexture = bottomtexture = maskedtexture = 0;
    ds_p->maskedtexturecol = NULL;
	

	sidetextureoffset = side.textureoffset + animateoffset;
	
 

	if (backsecnum == SECNUM_NULL) {
	// single sided line
		midtexture = texturetranslation[side.midtexture];
		// a single sided line is terminal, so it must mark ends
		markfloor = markceiling = true;
		if (lineflags & ML_DONTPEGBOTTOM) {
			// temp.h.intbits = textureheight[side.midtexture]+(frontsector.floorheight >> SHORTFLOORBITS);
			temp2 = (textureheights[side.midtexture] << SHORTFLOORBITS)  + (frontsector.floorheight);
			SET_FIXED_UNION_FROM_SHORT_HEIGHT(temp, temp2);
			vtop = temp.w;
			// bottom of texture at bottom
			rw_midtexturemid = vtop - viewz.w;	
		} else {
			// top of texture at top
			rw_midtexturemid = worldtop;
		}

		temp.h.intbits = side.rowoffset;
		temp.h.fracbits = 0;
		rw_midtexturemid += temp.w;

		ds_p->silhouette = SIL_BOTH;
		ds_p->sprtopclip = screenheightarray;
		ds_p->sprbottomclip = negonearray;
		ds_p->bsilheight = MAXSHORT;
		ds_p->tsilheight = MINSHORT;
    } else {
		// two sided line
		backsector = sectors[backsecnum];
		ds_p->sprtopclip = ds_p->sprbottomclip = NULL;
		ds_p->silhouette = 0;
		// temp.h.intbits = backsector.floorheight >> SHORTFLOORBITS;
		SET_FIXED_UNION_FROM_SHORT_HEIGHT(temp, backsector.floorheight);

		if (frontsector.floorheight > backsector.floorheight) {
			ds_p->silhouette = SIL_BOTTOM;
			ds_p->bsilheight = frontsector.floorheight;
		} else if (temp.w > viewz.w) {
			ds_p->silhouette = SIL_BOTTOM;
			ds_p->bsilheight = MAXSHORT;
			// ds_p->sprbottomclip = negonearray;
		}
	
		// temp.h.intbits = backsector.ceilingheight >> SHORTFLOORBITS;
		SET_FIXED_UNION_FROM_SHORT_HEIGHT(temp, backsector.ceilingheight);
		if (frontsector.ceilingheight < backsector.ceilingheight) {
			ds_p->silhouette |= SIL_TOP;
			// temp.h.intbits = frontsector.ceilingheight >> SHORTFLOORBITS;
			SET_FIXED_UNION_FROM_SHORT_HEIGHT(temp, frontsector.ceilingheight);
			ds_p->tsilheight = temp.w;
		} else if (temp.w < viewz.w) {
			ds_p->silhouette |= SIL_TOP;
			ds_p->tsilheight = MINSHORT;
			// ds_p->sprtopclip = screenheightarray;
		}
		
		if (backsector.ceilingheight <= frontsector.floorheight) {
			ds_p->sprbottomclip = negonearray;
			ds_p->bsilheight = MAXSHORT;
			ds_p->silhouette |= SIL_BOTTOM;
		}
	
		if (backsector.floorheight >= frontsector.ceilingheight) {
			ds_p->sprtopclip = screenheightarray;
			ds_p->tsilheight = MINSHORT;
			ds_p->silhouette |= SIL_TOP;
		}
	
		SET_FIXED_UNION_FROM_SHORT_HEIGHT(temp, backsector.ceilingheight);
		worldhigh = temp.w - viewz.w;
		
		SET_FIXED_UNION_FROM_SHORT_HEIGHT(temp, backsector.floorheight);
		worldlow = temp.w - viewz.w;
		
		// hack to allow height changes in outdoor areas
		if (frontsector.ceilingpic == skyflatnum && backsector.ceilingpic == skyflatnum) {
			worldtop = worldhigh;
		}
	
			
		if (worldlow != worldbottom  || backsector.floorpic != frontsector.floorpic || backsector.lightlevel != frontsector.lightlevel) {
			markfloor = true;
		} else {
			// same plane on both sides
			markfloor = false;
		}
	
			
		if (worldhigh != worldtop 
			|| backsector.ceilingpic != frontsector.ceilingpic
			|| backsector.lightlevel != frontsector.lightlevel) {
			markceiling = true;
		} else {
			// same plane on both sides
			markceiling = false;
		}
	
		if (backsector.ceilingheight <= frontsector.floorheight
			|| backsector.floorheight >= frontsector.ceilingheight) {
			// closed door
			markceiling = markfloor = true;
		}
	

		if (worldhigh < worldtop) {
			toptexture = texturetranslation[side.toptexture];
		
			if (lineflags & ML_DONTPEGTOP) {
				// top of texture at top
				rw_toptexturemid = worldtop;
			} else {
				// temp.h.intbits = textureheight[side.toptexture] + (backsector.ceilingheight >> SHORTFLOORBITS);
				temp2 = (textureheights[side.toptexture] << (8+SHORTFLOORBITS)) + (backsector.ceilingheight);
				SET_FIXED_UNION_FROM_SHORT_HEIGHT(temp, temp2);
				vtop = temp.w;
		
				// bottom of texture
				rw_toptexturemid = vtop - viewz.w;	
			}
		}
		if (worldlow > worldbottom) {
			// bottom texture
			bottomtexture = texturetranslation[side.bottomtexture];

			if (lineflags & ML_DONTPEGBOTTOM ) {
				// bottom of texture at bottom
				// top of texture at top
				rw_bottomtexturemid = worldtop;
			}
			else {	// top of texture at top
				rw_bottomtexturemid = worldlow;
			}
		}
			temp.h.intbits = side.rowoffset;
			temp.h.fracbits = 0;
			rw_toptexturemid += temp.w;
			rw_bottomtexturemid += temp.w;
	
		// allocate space for masked texture tables
		if (side.midtexture) {
			// masked midtexture
			maskedtexture = true;
			ds_p->maskedtexturecol = maskedtexturecol = lastopening - rw_x;
			lastopening += rw_stopx - rw_x;
		}
    }
    
    // calculate rw_offset (only needed for textured lines)
    segtextured = midtexture | toptexture | bottomtexture | maskedtexture;

    if (segtextured) {
		/*
		tempangle.h.intbits = rw_normalangle;
		tempangle.h.intbits <<= 3;
		tempangle.w -= rw_angle1.w;
		tempangle.h.fracbits = tempangle.h.intbits;
		tempangle.h.fracbits >>= 3;


		offsetangle = tempangle.h.fracbits;
		tempangle.h.fracbits = 0;
		*/
		
		offsetangle = ((rw_normalangle << 3) - (rw_angle1.h.intbits)) >> 3;


		if (offsetangle > FINE_ANG180) {
			offsetangle = MOD_FINE_ANGLE(-offsetangle);
		}

		if (offsetangle > FINE_ANG90) {
			offsetangle = FINE_ANG90;
		}
		sineval = finesine(offsetangle);
		rw_offset = FixedMulTrig(hyp, sineval);

		// todo: we are subtracting then checking vs 0x8000 (or 0x80000000). 
		// Is this equivalent to a simpler operation?

		tempangle.h.intbits = rw_normalangle;
		tempangle.h.intbits <<= 3;
		tempangle.w -= rw_angle1.w;

		if (tempangle.h.intbits < ANG180_HIGHBITS) {

			rw_offset = -rw_offset;
		}
		temp.h.fracbits = 0;
		temp.h.intbits = sidetextureoffset+curline.offset;
		rw_offset += temp.w;
		
		rw_centerangle = MOD_FINE_ANGLE(FINE_ANG90 + (viewangle.h.intbits >> SHORTTOFINESHIFT) - (rw_normalangle));

		// calculate light table
		//  use different light tables
		//  for horizontal / vertical / diagonal
		// OPTIMIZE: get rid of LIGHTSEGSHIFT globally
		if (!fixedcolormap){
			lightnum = (frontsector.lightlevel >> LIGHTSEGSHIFT)+extralight;

			if (curlinev1.y == curlinev2.y) {
				lightnum--;
			} else if (curlinev1.x == curlinev2.x) {
				lightnum++;
			}

			if (lightnum < 0) {
				walllights = scalelight[0];
			} else if (lightnum >= LIGHTLEVELS) {
				walllights = scalelight[LIGHTLEVELS - 1];
			} else {
				walllights = scalelight[lightnum];
			}
		}
    }
    
    // if a floor / ceiling plane is on the wrong side
    //  of the view plane, it is definitely invisible
    //  and doesn't need to be marked.
    
	temp.h.fracbits = 0;
	SET_FIXED_UNION_FROM_SHORT_HEIGHT(temp, frontsector.floorheight);
    if (temp.w >= viewz.w) {
		// above view plane
		markfloor = false;
    }
	SET_FIXED_UNION_FROM_SHORT_HEIGHT(temp, frontsector.ceilingheight);
    if (temp.w <= viewz.w  && frontsector.ceilingpic != skyflatnum) {
		// below view plane
		markceiling = false;
    }

    
    // calculate incremental stepping values for texture edges
    worldtop >>= 4;
    worldbottom >>= 4;
	
    topfrac = (centeryfrac.w >>4) - FixedMul (worldtop, rw_scale.w);
    bottomfrac = (centeryfrac.w >>4) - FixedMul (worldbottom, rw_scale.w);
//	if (rw_scalestep) {
		topstep = -FixedMul1632(rw_scalestep, worldtop);
		bottomstep = -FixedMul1632(rw_scalestep, worldbottom);
/*	}
	else {
		topstep = -FixedMul(rw_scalestep_extraprecision.w, worldtop);
		bottomstep = -FixedMul(rw_scalestep_extraprecision.w, worldbottom);
	}*/
	
    if (backsecnum != SECNUM_NULL) {	
		worldhigh >>= 4;
		worldlow >>= 4;
		if (worldhigh < worldtop) {
			pixhigh = (centeryfrac.w >>4) - FixedMul (worldhigh, rw_scale.w);
//			if (rw_scalestep) {
				pixhighstep = -FixedMul1632(rw_scalestep, worldhigh);
//			} else {
//				pixhighstep = -FixedMul(rw_scalestep_extraprecision.w, worldhigh);
//			}
		}
	
		if (worldlow > worldbottom) {
			pixlow = (centeryfrac.w >>4) - FixedMul (worldlow, rw_scale.w);
//			if (rw_scalestep) {
				pixlowstep = -FixedMul1632(rw_scalestep, worldlow);
//			}
//			else {
//				pixlowstep = -FixedMul(rw_scalestep_extraprecision.w, worldlow);
//			}

		}
    }

    // render it
	if (markceiling) {
		ceilingplaneindex = R_CheckPlane(ceilingplaneindex, rw_x, rw_stopx - 1);
	}
    
	if (markfloor) {
		floorplaneindex = R_CheckPlane(floorplaneindex, rw_x, rw_stopx - 1);
	}
	
	R_RenderSegLoop ();
    
    // save sprite clipping info
    if ( ((ds_p->silhouette & SIL_TOP) || maskedtexture)
	 && !ds_p->sprtopclip)
    {
	memcpy (lastopening, ceilingclip+start, 2*(rw_stopx-start));
	ds_p->sprtopclip = lastopening - start;
	lastopening += rw_stopx - start;
    }
    
    if ( ((ds_p->silhouette & SIL_BOTTOM) || maskedtexture)
	 && !ds_p->sprbottomclip)
    {
	memcpy (lastopening, floorclip+start, 2*(rw_stopx-start));
	ds_p->sprbottomclip = lastopening - start;
	lastopening += rw_stopx - start;	
    }

    if (maskedtexture && !(ds_p->silhouette&SIL_TOP))
    {
	ds_p->silhouette |= SIL_TOP;
	ds_p->tsilheight = MINSHORT;
    }
    if (maskedtexture && !(ds_p->silhouette&SIL_BOTTOM))
    {
	ds_p->silhouette |= SIL_BOTTOM;
	ds_p->bsilheight = MAXSHORT;
    }
    ds_p++;
}


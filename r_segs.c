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
#include "m_memory.h"
#include "m_near.h"
#include <dos.h>
#include <conio.h>


// OPTIMIZE: closed two sided lines as single sided



#define SC_INDEX			0x3C4

//
// R_RenderMaskedSegRange
//
void __near R_RenderMaskedSegRange (drawseg_t __far* ds, int16_t x1, int16_t x2) {
	uint8_t	index;
	uint16_t	spryscale_shift12;
	int16_t		lightnum;
	int16_t		frontsecnum;

	side_t __far* side;
	side_render_t __far* side_render;
	int16_t curlineside;
	vertex_t v1;
	vertex_t v2;
	line_t __far* curlinelinedef;
	int16_t		texnum;
	curseg = ds->curseg;
	curseg_render = &segs_render[curseg];

	side = &sides[curseg_render->sidedefOffset];
	side_render = &sides_render[curseg_render->sidedefOffset];

	texnum = texturetranslation[side->midtexture];

	curlineside = segs[curseg].side;
	curlinelinedef = &lines[segs[curseg].linedefOffset];

	v1 = vertexes[curseg_render->v1Offset];
	v2 = vertexes[curseg_render->v2Offset];
	// Calculate light table.
	// Use different light tables
	//   for horizontal / vertical / diagonal. Diagonal?
	// OPTIMIZE: get rid of LIGHTSEGSHIFT globally

	frontsecnum = side_render->secnum;
	backsector =
		curlinelinedef->flags & ML_TWOSIDED ?
		&sectors[sides_render[curlinelinedef->sidenum[curlineside ^ 1]].secnum]
		: NULL;
	frontsector = &sectors[frontsecnum];

	lightnum = (frontsector->lightlevel >> LIGHTSEGSHIFT) + extralight;

	if (v1.y == v2.y) {
		lightnum--;
	} else if (v1.x == v2.x) {
		lightnum++;
	}
	if (lightnum < 0){
		walllights = &scalelight[0];
	} else if (lightnum >= LIGHTLEVELS) {
		walllights = &scalelight[lightmult48lookup[LIGHTLEVELS - 1]];
	} else {
		walllights = &scalelight[lightmult48lookup[lightnum]];
	}
    maskedtexturecol = &openings[ds->maskedtexturecol];

    rw_scalestep = ds->scalestep;
    //spryscale.w = ds->scale1 + FastMul16u32u(x1 - ds->x1,(int32_t)rw_scalestep); // this cast is necessary or some masked textures render wrong behind some sprites
    spryscale.w = ds->scale1 + FastMul1616(x1 - ds->x1,rw_scalestep); // actually 1616 seems ok
	
	spryscale_shift12 = spryscale.w >> LIGHTSCALESHIFT;
    mfloorclip = MK_FP(openings_segment, ds->sprbottomclip_offset);
    mceilingclip = MK_FP(openings_segment, ds->sprtopclip_offset);
    
    // find positioning
    if (curlinelinedef->flags & ML_DONTPEGBOTTOM) {

#ifdef USE_SHORTHEIGHT_VIEWZ	
		SET_FIXED_UNION_FROM_SHORT_HEIGHT(dc_texturemid, 
				(frontsector->floorheight > backsector->floorheight ? frontsector->floorheight : backsector->floorheight) - viewz_shortheight);
		dc_texturemid.h.intbits += (textureheights[texnum] + 1);
#else
		SET_FIXED_UNION_FROM_SHORT_HEIGHT(dc_texturemid,
			frontsector->floorheight > backsector->floorheight ? frontsector->floorheight : backsector->floorheight);
		dc_texturemid.h.intbits += textureheights[texnum] + 1;
		dc_texturemid.w -= viewz.w;
#endif
    } else {
#ifdef USE_SHORTHEIGHT_VIEWZ	
		SET_FIXED_UNION_FROM_SHORT_HEIGHT(dc_texturemid,
			(frontsector->ceilingheight < backsector->ceilingheight ? frontsector->ceilingheight : backsector->ceilingheight) - viewz_shortheight);
#else
		SET_FIXED_UNION_FROM_SHORT_HEIGHT(dc_texturemid,
			(frontsector->ceilingheight < backsector->ceilingheight ? frontsector->ceilingheight : backsector->ceilingheight));
		dc_texturemid.w -= viewz.w;
#endif
    }
    dc_texturemid.h.intbits += side_render->rowoffset;
			
	if (fixedcolormap) {
		// todo if this is 0 maybe skip the if?
		dc_colormap_segment = colormapssegment_high;
		dc_colormap_index = fixedcolormap;
	}



	{
		
		int16_t dc_x_base4 = x1 & (detailshiftandval);	
		int16_t base4diff = x1 - dc_x_base4;
		fixed_t basespryscale = spryscale.w;
		int16_t xoffset;
		fixed_t rw_scalestep_shift = ((int32_t)rw_scalestep) << detailshift2minus;
		fixed_t sprtopscreen_step = FixedMul(dc_texturemid.w, rw_scalestep_shift);

		while (base4diff){
			basespryscale -= rw_scalestep;
			base4diff--;
		}

		for (xoffset = 0 ; xoffset < detailshiftitercount ; 
			xoffset++, 
			basespryscale+=rw_scalestep) {

			outp(SC_INDEX+1, quality_port_lookup[xoffset+detailshift.b.bytehigh]);

			spryscale.w = basespryscale;
			dc_x        = dc_x_base4 + xoffset;
			
			if (dc_x < x1){
				dc_x        += detailshiftitercount;
				spryscale.w += rw_scalestep_shift;

			}
			sprtopscreen = centeryfrac.w - FixedMul(dc_texturemid.w, spryscale.w);

			// draw the columns
			for (; dc_x <= x2 ; 
				dc_x+=detailshiftitercount,
				spryscale.w += rw_scalestep_shift,
				sprtopscreen -= sprtopscreen_step

			){
				// calculate lighting
				if (maskedtexturecol[dc_x] != MAXSHORT) {
					if (!fixedcolormap) {

						// prevents a 12 bit shift in many cases. 
						// Rather than checking if (rw_scale >> 12) > 48, we check if rw_scale high bit > (12 << 4) which is 0x30000
						if (spryscale.h.intbits >= 3) {
							index = MAXLIGHTSCALE - 1;
						} else {
							index = spryscale_shift12;
						}

						dc_colormap_segment = colormapssegment_high;
						dc_colormap_index = walllights[index];

						// todo does it have to be reset after this?
					}
					
					// todo optimize to an add approach instead of a fixedmul every timeapproach...
					// add by dc_texturemid.w * rw_scalestep_shift

					// todo there's got to be a faster way
					//dc_iscale = 0xffffffffu / spryscale.w;
					dc_iscale = FastDiv3232(0xffffffffu, spryscale.w);

/*
					if (FastDiv3232(0xffffffffu, spryscale.w) != (0xffffffffu / spryscale.w)){
						I_Error ("caught a %li %li %li %li",
						0xffffffffu, spryscale.w,
						FastDiv3232(0xffffffffu, spryscale.w),
						0xffffffffu / spryscale.w);						
					}
*/

					// the below doesnt work because sometimes < FRACUNIT
					//dc_iscale = 0xffffu / spryscale.hu.intbits;  // this might be ok? 
				
					// draw the texture
					{
						segment_t pixelsegment = R_GetColumnSegment(texnum,maskedtexturecol[dc_x]);
						
						uint8_t lookup = masked_lookup[texnum];
						if (lookup != 0xFF){
							masked_header_t __far * maskedheader = &masked_headers[lookup];
							uint16_t __far * postoffsets  =  MK_FP(maskedpostdataofs_segment, maskedheader->postofsoffset);
							uint16_t 		 postoffset = postoffsets[cachedcol];
							column_t __far * postsdata = (column_t __far *)(MK_FP(maskedpostdata_segment, postoffset)) ;

							R_DrawMaskedColumn (pixelsegment, postsdata);
						} else {
							R_DrawSingleMaskedColumn(pixelsegment, cachedbyteheight);
						}

					}			
					maskedtexturecol[dc_x] = MAXSHORT;
				}
			}
		}
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

//extern int setval;


void __near R_RenderSegLoop (void)
{
    fineangle_t		angle;
	uint16_t		index;
    int16_t			yl;
    int16_t			yh;
    int16_t			mid;
    int16_t		    texturecolumn;
    int16_t			top;
    int16_t			bottom;
	fixed_t_union 	temp;
	int8_t          xoffset;
	int16_t        	start_rw_x = rw_x;
	int16_t 		rw_x_base4 = rw_x & detailshiftandval;	// knock out the low 2 bits. 



	// its fine to do 2 bits even in low/potato because this is becing called word/dword aligned anyway so nothing changes.

	//todo check for overflow?
	
	// need to subtract detailshift mod 4 for base too

	fixed_t			topstepshift    = topstep      << detailshift2minus;
	fixed_t			bottomstepshift = bottomstep   << detailshift2minus;
	int16_t			rwscaleshift    = rw_scalestep << detailshift2minus;

	fixed_t			pixhighstepshift = pixhighstep << detailshift2minus;
	fixed_t			pixlowstepshift  = pixlowstep  << detailshift2minus;

	fixed_t base_rw_scale   = rw_scale.w;
	fixed_t base_topfrac    = topfrac;
	fixed_t base_bottomfrac = bottomfrac;
	fixed_t base_pixlow     = pixlow;
	fixed_t base_pixhigh    = pixhigh;

  	int16_t base4diff = rw_x - rw_x_base4;



	while (base4diff){
		base_rw_scale   -= rw_scalestep;
		base_topfrac    -= topstep;
		base_bottomfrac -= bottomstep;
		pixlow		    -= pixlowstep;
		pixhigh		    -= pixhighstep;
		base4diff--;
	}

 

	for (xoffset = 0 ; xoffset < detailshiftitercount ; 
			xoffset++,
			base_topfrac    += topstep, 
			base_bottomfrac += bottomstep, 
			base_rw_scale   += rw_scalestep,
			base_pixlow	    += pixlowstep,
		    base_pixhigh    += pixhighstep
		) {

		outp(SC_INDEX+1, quality_port_lookup[xoffset+detailshift.b.bytehigh]);
		
		//frac.w = basespryscale;
		topfrac    = base_topfrac;
		bottomfrac = base_bottomfrac;
		rw_scale.w = base_rw_scale;
		pixlow     = base_pixlow;
		pixhigh    = base_pixhigh;




		rw_x = rw_x_base4 + xoffset;
		if (rw_x < start_rw_x){
			rw_x       += detailshiftitercount;
			topfrac    += topstepshift;
			bottomfrac += bottomstepshift;
			rw_scale.w += rwscaleshift;
			pixlow     += pixlowstepshift;
			pixhigh    += pixhighstepshift;

		}


// todo:
 
			//rw_scale.w += rw_scalestep;
			//topfrac += topstep;
			//bottomfrac += bottomstep;



		for ( ; rw_x < rw_stopx ; 
			rw_x		+= detailshiftitercount,
			topfrac 	+= topstepshift,
			bottomfrac  += bottomstepshift,
			rw_scale.w  += rwscaleshift
		) {

			// mark floor / ceiling areas

			// todo optimize out and make a 16 bit add not 32.
			yl = (topfrac+(HEIGHTUNIT-1))>>HEIGHTBITS;

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
					ceiltop[rw_x] = top & 0xFF;
					// top[322] is the start of bot[]
					ceiltop[rw_x+322] = bottom & 0xFF;
	
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
					floortop[rw_x] = top & 0xFF;
					// top[322] is the start of bot[]
					floortop[rw_x+322] = bottom & 0xFF;
				}
			}

			// texturecolumn and lighting are independent of wall tiers
			if (segtextured) {
				// calculate texture offset
				angle = MOD_FINE_ANGLE (rw_centerangle + xtoviewangle[rw_x]);
				temp.w = rw_offset.w-FixedMul(finetangent(angle),rw_distance);
				texturecolumn = temp.h.intbits;
			
				// calculate lighting

				// prevents a 12 bit shift in many cases. 
				// Rather than checking if (rw_scale >> 12) > 48, we check if rw_scale high bit > (12 << 4)
				if (rw_scale.h.intbits >= 3) {
					index = MAXLIGHTSCALE - 1;
				} else {
					index = rw_scale.w >> LIGHTSCALESHIFT;
				}


				dc_colormap_segment = colormapssegment;
				dc_colormap_index = walllights[index];
				dc_x = rw_x;
				//dc_iscale = 0xffffffffu / rw_scale.w;
				dc_iscale = FastDiv3232(0xffffffffu, rw_scale.w);
/*
					if (FastDiv3232(0xffffffffu, rw_scale.w) != (0xffffffffu / rw_scale.w)){
						I_Error ("caught b %li %li %li %li",
						0xffffffffu, rw_scale.w,
						FastDiv3232(0xffffffffu, rw_scale.w),
						0xffffffffu / rw_scale.w);
					}
*/
				// the below doesnt work because sometimes < FRACUNIT
				//dc_iscale = 0xffffu / rw_scale.hu.intbits;  // this might be ok? 
			}

			// draw the wall tiers
			if (midtexture) {
				// single sided line
				if (yh >= yl){

					dc_yl = yl;
					dc_yh = yh;
					dc_texturemid = rw_midtexturemid;

					dc_source_segment = R_GetColumnSegment(midtexture,texturecolumn);

					//I_Error("A %Fp  %Fp %Fp", R_DrawColumnPrepCall, R_DrawColumn, R_DrawColumnPrep);
					// 6A42:0B6A
					// 1CA4:19d2 
					// 1CA4:253C
					R_DrawColumnPrepCall(0);				



				}
				ceilingclip[rw_x] = viewheight;
				floorclip[rw_x] = -1;
			} else {
			
			
				// two sided line
				if (toptexture) {
					// top wall
					mid = pixhigh>>HEIGHTBITS;
					pixhigh += pixhighstepshift;

					if (mid >= floorclip[rw_x])
						mid = floorclip[rw_x]-1;

					if (mid >= yl) {
						if (yh > yl){
							dc_yl = yl;
							dc_yh = mid;
							dc_texturemid = rw_toptexturemid;

							dc_source_segment = R_GetColumnSegment(toptexture,texturecolumn);
							R_DrawColumnPrepCall(0);				
						}
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
					pixlow += pixlowstepshift;

					// no space above wall?
					if (mid <= ceilingclip[rw_x]) {
						mid = ceilingclip[rw_x] + 1;
					}
					if (mid <= yh) {
						if (yh > yl){
							dc_yl = mid;
							dc_yh = yh;
							dc_texturemid = rw_bottomtexturemid;

							dc_source_segment = R_GetColumnSegment(bottomtexture, texturecolumn);
							R_DrawColumnPrepCall(0);
							

						}
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
			

		}
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
void __near R_StoreWallRange ( int16_t start, int16_t stop ) {
    fixed_t		hyp;
    fineangle_t	distangle, offsetangle;
    int16_t			lightnum;

	// needs to be refreshed...
	side_t __far* side = &sides[curseg_render->sidedefOffset];
	side_render_t __far* side_render = &sides_render[curseg_render->sidedefOffset];
	vertex_t curlinev1 = vertexes[curseg_render->v1Offset];
	vertex_t curlinev2 = vertexes[curseg_render->v2Offset];
	int16_t sidetextureoffset;
	int16_t lineflags;
	angle_t tempangle;
	short_height_t frontsectorfloorheight;
	short_height_t frontsectorceilingheight;
	uint16_t frontsectorceilingpic;
	uint16_t frontsectorfloorpic;
	uint8_t frontsectorlightlevel;
	line_t __far* linedef;
	int16_t linedefOffset;
	uint16_t rw_normalangle_shiftleft3;

	if (ds_p == &drawsegs_BASE[MAXDRAWSEGS])
		return;		

	frontsectorfloorheight = frontsector->floorheight;
	frontsectorceilingheight = frontsector->ceilingheight;
	frontsectorceilingpic = frontsector->ceilingpic;
	frontsectorfloorpic = frontsector->floorpic;
	frontsectorlightlevel = frontsector->lightlevel;
		 
	//linedef = &lines[curseg->linedefOffset];
	linedefOffset = segs[curseg].linedefOffset;
	linedef = &lines[linedefOffset];

#ifdef CHECK_FOR_ERRORS
	if (linedefOffset > numlines) {
		I_Error("R_StoreWallRange Error! lines out of bounds! %i %i %i %i", gametic, numlines, linedefOffset, curlinenum);
	}
#endif

    // mark the segment as visible for auto map
	// todo might actually be faster on average to check the bit... these shifts may suck
	seenlines[linedefOffset/8] |= (0x01 << (linedefOffset % 8));

	lineflags = linedef->flags;

    // calculate rw_distance for scale calculation
    rw_normalangle = MOD_FINE_ANGLE(curseg_render->fineangle + FINE_ANG90);
	rw_normalangle_shiftleft3 = rw_normalangle << SHORTTOFINESHIFT;


	offsetangle = abs((rw_normalangle_shiftleft3) - (rw_angle1.hu.intbits)) >> SHORTTOFINESHIFT;

    if (offsetangle > FINE_ANG90)
		offsetangle = 	FINE_ANG90;

    distangle = FINE_ANG90 - offsetangle;

	hyp = R_PointToDist (curlinev1.x, curlinev1.y);
    rw_distance = FixedMulTrig(FINE_SINE_ARGUMENT, distangle, hyp);
	
    ds_p->x1 = rw_x = start;
    ds_p->x2 = stop;
    ds_p->curseg = curseg;
    rw_stopx = stop+1;

 

    // calculate scale at both ends and step
    ds_p->scale1 = rw_scale.w =  R_ScaleFromGlobalAngle (viewangle_shiftright3+xtoviewangle[start]); // internally fineangle modded

    if (stop > start ) {

		ds_p->scale2 = R_ScaleFromGlobalAngle (viewangle_shiftright3 + xtoviewangle[stop]);

		// basically a specialized 32 bit divided by 16 bit function that returns 16 bit and clips to short max/min
		
		// todo inline R_CalculateScaleStep when doing asm
		rw_scalestep = R_CalculateScaleStep((ds_p->scale2 - rw_scale.w), (stop-start));
		
		ds_p->scalestep = rw_scalestep;


    } else {
		ds_p->scale2 = ds_p->scale1;
    }
    
 

    // calculate texture boundaries
    //  and decide if floor / ceiling marks are needed
	
	
#ifdef USE_SHORTHEIGHT_VIEWZ	

	SET_FIXED_UNION_FROM_SHORT_HEIGHT(worldtop, frontsectorceilingheight - viewz_shortheight);
	SET_FIXED_UNION_FROM_SHORT_HEIGHT(worldbottom, frontsectorfloorheight - viewz_shortheight);
#else
	SET_FIXED_UNION_FROM_SHORT_HEIGHT(worldtop, frontsectorceilingheight);
	worldtop.w -= viewz.w;
	SET_FIXED_UNION_FROM_SHORT_HEIGHT(worldbottom, frontsectorfloorheight);
	worldbottom.w -= viewz.w;
#endif
    midtexture = toptexture = bottomtexture = maskedtexture = 0;
    ds_p->maskedtexturecol = NULL_TEX_COL;
	

	sidetextureoffset = side->textureoffset;
	
 

	if (!backsector) {
	// single sided line
		midtexture = texturetranslation[side->midtexture];
		// a single sided line is terminal, so it must mark ends
		markfloor = markceiling = true;
		if (lineflags & ML_DONTPEGBOTTOM) {
			SET_FIXED_UNION_FROM_SHORT_HEIGHT(rw_midtexturemid, frontsectorfloorheight-viewz_shortheight);
			rw_midtexturemid.h.intbits += (textureheights[side->midtexture] + 1);
			// bottom of texture at bottom
			//rw_midtexturemid.w -= viewz.w;	
		} else {
			// top of texture at top
			rw_midtexturemid = worldtop;
		}

		rw_midtexturemid.h.intbits += side_render->rowoffset;

		ds_p->silhouette = SIL_BOTH;
		ds_p->sprtopclip_offset = screenheightarray_offset;
		ds_p->sprbottomclip_offset = negonearray_offset;
		ds_p->bsilheight = MAXSHORT;
		ds_p->tsilheight = MINSHORT;
    } else {
		// two sided line
		short_height_t backsectorfloorheight = backsector->floorheight;
		short_height_t backsectorceilingheight = backsector->ceilingheight;
		uint8_t backsectorceilingpic = backsector->ceilingpic;
		uint8_t backsectorfloorpic = backsector->floorpic;
		uint8_t backsectorlightlevel = backsector->lightlevel;
		ds_p->sprtopclip_offset = ds_p->sprbottomclip_offset = 0;
		ds_p->silhouette = 0;

		if (frontsectorfloorheight > backsectorfloorheight) {
			ds_p->silhouette = SIL_BOTTOM;
			ds_p->bsilheight = frontsectorfloorheight;
		} else if (backsectorfloorheight > viewz_shortheight) {
			ds_p->silhouette = SIL_BOTTOM;
			ds_p->bsilheight = MAXSHORT;
		}
	
		if (frontsectorceilingheight < backsectorceilingheight) {
			ds_p->silhouette |= SIL_TOP;
			ds_p->tsilheight = frontsectorceilingheight;
		} else if (backsectorceilingheight < viewz_shortheight) {
			ds_p->silhouette |= SIL_TOP;
			ds_p->tsilheight = MINSHORT;
		}
		
		if (backsectorceilingheight <= frontsectorfloorheight) {
			ds_p->sprbottomclip_offset = negonearray_offset;
			ds_p->bsilheight = MAXSHORT;
			ds_p->silhouette |= SIL_BOTTOM;
		}
	
		if (backsectorfloorheight >= frontsectorceilingheight) {
			ds_p->sprtopclip_offset = screenheightarray_offset;
			ds_p->tsilheight = MINSHORT;
			ds_p->silhouette |= SIL_TOP;
		}
#ifdef USE_SHORTHEIGHT_VIEWZ	
		SET_FIXED_UNION_FROM_SHORT_HEIGHT(worldhigh, backsectorceilingheight - viewz_shortheight);
		SET_FIXED_UNION_FROM_SHORT_HEIGHT(worldlow, backsectorfloorheight - viewz_shortheight);
#else
		SET_FIXED_UNION_FROM_SHORT_HEIGHT(worldhigh, backsectorceilingheight);
		worldhigh.w -= viewz.w;
		SET_FIXED_UNION_FROM_SHORT_HEIGHT(worldlow, backsectorfloorheight);
		worldlow.w -= viewz.w;
#endif
		
		// hack to allow height changes in outdoor areas
		if (frontsectorceilingpic == skyflatnum && backsectorceilingpic == skyflatnum) {
			worldtop = worldhigh;
		}
	
			
		if (worldlow.w != worldbottom .w || backsectorfloorpic != frontsectorfloorpic || backsectorlightlevel != frontsectorlightlevel) {
			markfloor = true;
		} else {
			// same plane on both sides
			markfloor = false;
		}
	
			
		if (worldhigh.w != worldtop.w
			|| backsectorceilingpic != frontsectorceilingpic
			|| backsectorlightlevel != frontsectorlightlevel) {
			markceiling = true;
		} else {
			// same plane on both sides
			markceiling = false;
		}
	
		if (backsectorceilingheight <= frontsectorfloorheight
			|| backsectorfloorheight >= frontsectorceilingheight) {
			// closed door
			markceiling = markfloor = true;
		}
	

		if (worldhigh.w < worldtop.w) {
			toptexture = texturetranslation[side->toptexture];
		
			if (lineflags & ML_DONTPEGTOP) {
				// top of texture at top
				rw_toptexturemid = worldtop;
			} else {
#ifdef USE_SHORTHEIGHT_VIEWZ	
				SET_FIXED_UNION_FROM_SHORT_HEIGHT(rw_toptexturemid, backsectorceilingheight-viewz_shortheight);
				rw_toptexturemid.h.intbits += textureheights[side->toptexture] + 1;
#else
				SET_FIXED_UNION_FROM_SHORT_HEIGHT(rw_toptexturemid, backsectorceilingheight);
				rw_toptexturemid.h.intbits += textureheights[side->toptexture] + 1;
				// bottom of texture

				rw_toptexturemid.w -= viewz.w;
#endif
				
			}
		}
		if (worldlow.w > worldbottom.w) {
			// bottom texture
			bottomtexture = texturetranslation[side->bottomtexture];

			if (lineflags & ML_DONTPEGBOTTOM ) {
				// bottom of texture at bottom
				// top of texture at top
				rw_bottomtexturemid = worldtop;
			}
			else {	// top of texture at top
				rw_bottomtexturemid = worldlow;
			}
		}

		rw_toptexturemid.h.intbits += side_render->rowoffset;
		rw_bottomtexturemid.h.intbits += side_render->rowoffset;

		// allocate space for masked texture tables
		if (side->midtexture) {
			// masked midtexture
			maskedtexture = true;
			ds_p->maskedtexturecol = lastopening - rw_x;
    		maskedtexturecol = &openings[ds_p->maskedtexturecol];
			lastopening += rw_stopx - rw_x;
		}
    }
    
    // calculate rw_offset (only needed for textured lines)
    segtextured = midtexture | toptexture | bottomtexture | maskedtexture;

    if (segtextured) {
 
		
		offsetangle = ((rw_normalangle_shiftleft3) - (rw_angle1.hu.intbits)) >> SHORTTOFINESHIFT;


		if (offsetangle > FINE_ANG180) {
			offsetangle = MOD_FINE_ANGLE(-offsetangle);
		}

		if (offsetangle > FINE_ANG90) {
			offsetangle = FINE_ANG90;
		}

 		rw_offset.w = FixedMulTrig(FINE_SINE_ARGUMENT, offsetangle, hyp);
	
		// todo: we are subtracting then checking vs 0x8000 (or 0x80000000). 
		// Is this equivalent to a simpler operation?

		tempangle.hu.fracbits = 0;
		tempangle.hu.intbits = rw_normalangle_shiftleft3;
		tempangle.wu -= rw_angle1.wu;

		if (tempangle.hu.intbits < ANG180_HIGHBITS) {	
			rw_offset.w = -rw_offset.w;
		}
		rw_offset.h.intbits += (sidetextureoffset + curseg_render->offset);
		
		rw_centerangle = MOD_FINE_ANGLE(FINE_ANG90 + (viewangle_shiftright3) - (rw_normalangle));

		// calculate light table
		//  use different light tables
		//  for horizontal / vertical / diagonal
		// OPTIMIZE: get rid of LIGHTSEGSHIFT globally
		if (!fixedcolormap){
			lightnum = (frontsectorlightlevel >> LIGHTSEGSHIFT)+extralight;

			if (curlinev1.y == curlinev2.y) {
				lightnum--;
			} else if (curlinev1.x == curlinev2.x) {
				lightnum++;
			}

			if (lightnum < 0) {
				walllights = &scalelight[0];
			} else if (lightnum >= LIGHTLEVELS) {
				walllights = &scalelight[lightmult48lookup[LIGHTLEVELS - 1]];
			} else {
				walllights = &scalelight[lightmult48lookup[lightnum]];
			}
		}
    }
    
    // if a floor / ceiling plane is on the wrong side
    //  of the view plane, it is definitely invisible
    //  and doesn't need to be marked.
    
	//SET_FIXED_UNION_FROM_SHORT_HEIGHT(temp, frontsectorfloorheight);
	if (frontsectorfloorheight >= viewz_shortheight) {
		// above view plane
		markfloor = false;
    }
	//SET_FIXED_UNION_FROM_SHORT_HEIGHT(temp, frontsectorceilingheight);
    if (frontsectorceilingheight <= viewz_shortheight  && frontsectorceilingpic != skyflatnum) {
		// below view plane
		markceiling = false;
    }

    
    // calculate incremental stepping values for texture edges
    worldtop.w >>= 4;
    worldbottom.w >>= 4;
	
    topfrac = (centeryfrac_shiftright4.w) - FixedMul (worldtop.w, rw_scale.w);
    bottomfrac = (centeryfrac_shiftright4.w) - FixedMul (worldbottom.w, rw_scale.w);
//	if (rw_scalestep) {
		topstep = -FixedMul1632(rw_scalestep, worldtop.w);
		bottomstep = -FixedMul1632(rw_scalestep, worldbottom.w);
/*	}
	else {
		topstep = -FixedMul(rw_scalestep_extraprecision.w, worldtop);
		bottomstep = -FixedMul(rw_scalestep_extraprecision.w, worldbottom);
	}*/
	
    if (backsector) {	
		worldhigh.w >>= 4;
		worldlow.w >>= 4;
		if (worldhigh.w < worldtop.w) {

			pixhigh = (centeryfrac_shiftright4.w) - FixedMul (worldhigh.w, rw_scale.w);
//			if (rw_scalestep) {
				pixhighstep = -FixedMul1632(rw_scalestep, worldhigh.w);
//			} else {
//				pixhighstep = -FixedMul(rw_scalestep_extraprecision.w, worldhigh);
//			}
		}
	
		if (worldlow.w > worldbottom.w) {
			pixlow = (centeryfrac_shiftright4.w) - FixedMul (worldlow.w, rw_scale.w);
//			if (rw_scalestep) {
				pixlowstep = -FixedMul1632(rw_scalestep, worldlow.w);
//			}
//			else {
//				pixlowstep = -FixedMul(rw_scalestep_extraprecision.w, worldlow);
//			}

		}
    }

    // render it
	if (markceiling) {
		ceilingplaneindex = R_CheckPlane(ceilingplaneindex, rw_x, rw_stopx - 1, IS_CEILING_PLANE);
	}
    
	if (markfloor) {
		floorplaneindex = R_CheckPlane(floorplaneindex, rw_x, rw_stopx - 1, IS_FLOOR_PLANE);
	}
	
	R_RenderSegLoop ();
    
    // save sprite clipping info
    if ( ((ds_p->silhouette & SIL_TOP) || maskedtexture) && !ds_p->sprtopclip_offset) {
		FAR_memcpy(&openings[lastopening], ceilingclip+start, ((rw_stopx-start)<<1));
		ds_p->sprtopclip_offset = 2*(lastopening-start); // multiply by 2 to get the offset rather than array index
		lastopening += rw_stopx - start;
    }
    
    if ( ((ds_p->silhouette & SIL_BOTTOM) || maskedtexture) && !ds_p->sprbottomclip_offset) {
		FAR_memcpy (&openings[lastopening], floorclip+start, ((rw_stopx-start)<<1));
		ds_p->sprbottomclip_offset = 2*(lastopening - start) ;// multiply by 2 to get the offset rather than array index
		lastopening += rw_stopx - start;	
    }

    if (maskedtexture && !(ds_p->silhouette&SIL_TOP)) {
		ds_p->silhouette |= SIL_TOP;
		ds_p->tsilheight = MINSHORT;
    }
    if (maskedtexture && !(ds_p->silhouette&SIL_BOTTOM)) {
		ds_p->silhouette |= SIL_BOTTOM;
		ds_p->bsilheight = MAXSHORT;
    }
    ds_p++;
}


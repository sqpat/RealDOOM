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
/*
void __near R_RenderMaskedSegRange2 (drawseg_t __far* ds, int16_t x1, int16_t x2) {
	uint8_t	index;
	int16_t		lightnum;
	int16_t		frontsecnum;
	fixed_t_union rw_scalestep;

	side_t __far* side;
	side_render_t __near* side_render;
	uint8_t curlineside;
	int16_t cursegline;
	vertex_t v1;
	vertex_t v2;
	line_t __far* curlinelinedef;
	int16_t		texnum;
	uint8_t lineflags;
	uint8_t lookup;
	uint16_t maskedpostsofs = 0xFFFF;
	uint16_t base;
	int16_t adder = 0;
	curseg = ds->cursegvalue;
	curseg_render = &segs_render[curseg];

	side = &sides[curseg_render->sidedefOffset];
	side_render = &sides_render[curseg_render->sidedefOffset];

	texnum = texturetranslation[side->midtexture];
	lookup = masked_lookup_7000[texnum];
	
	//todo split function's inner loop based off lookup 0xFF or not ? could also have a separate specialized getcolumnsegment function
	if (lookup != 0xFF){
		masked_header_t __near * maskedheader = &masked_headers[lookup];
		maskedpostsofs = maskedheader->postofsoffset;
	}
	
	
	curlineside = *((uint8_t __far *)MK_FP(seg_linedefs_segment, curseg + (seg_sides_offset_in_seglines)));//seg_sides[curseg];
	cursegline =  *((int16_t __far *)MK_FP(seg_linedefs_segment, 2*curseg)); // seg_linedefs[curseg];
	curlinelinedef = &lines[cursegline];
	lineflags = lineflagslist[cursegline];

	v1 = vertexes[curseg_render->v1Offset];
	v2 = vertexes[curseg_render->v2Offset];
	// Calculate light table.
	// Use different light tables
	//   for horizontal / vertical / diagonal. Diagonal?
	// OPTIMIZE: get rid of LIGHTSEGSHIFT globally

	frontsecnum = side_render->secnum;
	
	
	// revision post asm - this cant be not two-sided. masked always has a sector behind it i guess.
	backsector =
		lineflags & ML_TWOSIDED ?
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
		walllights = 0;
	} else if (lightnum >= LIGHTLEVELS) {
		walllights = lightmult48lookup[LIGHTLEVELS - 1];
	} else {
		walllights = lightmult48lookup[lightnum];
	}
	walllights+=SCALE_LIGHT_OFFSET_IN_FIXED_SCALELIGHT;

    maskedtexturecol = &openings[ds->maskedtexturecol_val];

    rw_scalestep.w = ds->scalestep;

	// can we use 16 bits? most of the time the answer is yes...
	// but need to handle obscure 16th bit case
	
	//todo bench if its faster to just to the one. probably is.
	//if ((rw_scalestep.h.intbits == 0x0000 && !(rw_scalestep.h.fracbits & 0x8000) ) || 
	//	(rw_scalestep.h.intbits == 0xFFFF &&  (rw_scalestep.h.fracbits & 0x8000) )){
	//    spryscale.w = ds->scale1 + FastMul1616(x1 - ds->x1,rw_scalestep.h.fracbits); // actually 1616 seems ok
	//} else {
		spryscale.w = ds->scale1 + FastMul16u32u(x1 - ds->x1,rw_scalestep.w); // actually 1616 seems ok
	//}
	
	
    //spryscale.w = ds->scale1 + FastMul16u32u(x1 - ds->x1,(int32_t)rw_scalestep); // this cast is necessary or some masked textures render wrong behind some sprites
	
    mfloorclip_offset = ds->sprbottomclip_offset;
    mceilingclip_offset = ds->sprtopclip_offset;
    
    // find positioning
    if (lineflags & ML_DONTPEGBOTTOM) {
		base = frontsector->floorheight > backsector->floorheight ? frontsector->floorheight : backsector->floorheight;
		adder = textureheights[texnum] + 1;
    } else {
		base =  frontsector->ceilingheight < backsector->ceilingheight ? frontsector->ceilingheight : backsector->ceilingheight;
    }

    SET_FIXED_UNION_FROM_SHORT_HEIGHT(dc_texturemid, base);
    
    dc_texturemid.w -= viewz.w;
	dc_texturemid.h.intbits += adder;		

    dc_texturemid.h.intbits += side_render->rowoffset; 
			
	if (fixedcolormap) {
		// todo if this is 0 maybe skip the if?
		dc_colormap_segment = colormaps_segment_maskedmapping;
		dc_colormap_index = fixedcolormap;
	}

	//if (x2 > x1) 
		// multiple pixel case. extra logic around calculating scale shifts and vga plane stuff
	{
		int16_t dc_x_base4 = x1 & (detailshiftandval);	
		int16_t base4diff = x1 - dc_x_base4;
		fixed_t basespryscale = spryscale.w;
		int16_t xoffset;
		fixed_t rw_scalestep_shift = rw_scalestep.w << detailshift2minus;
		fixed_t sprtopscreen_step = FixedMul(dc_texturemid.w, rw_scalestep_shift);
		int16_t texturecolumn;

		while (base4diff){
			basespryscale -= rw_scalestep.w;
			base4diff--;
		}

		for (xoffset = 0 ; xoffset < detailshiftitercount ; 
			xoffset++, 
			basespryscale+=rw_scalestep.w) {

			outp(SC_INDEX+1, quality_port_lookup[xoffset+detailshift.b.bytehigh]);

			spryscale.w = basespryscale;
			dc_x        = dc_x_base4 + xoffset;
			
			if (dc_x < x1){
				dc_x        += detailshiftitercount;
				spryscale.w += rw_scalestep_shift;

			}

			// todo optimize to an add approach instead of a fixedmul every timeapproach...
			// add by dc_texturemid.w * rw_scalestep_shift
			
			sprtopscreen.h.intbits = centery;
			sprtopscreen.h.fracbits = 0;
			sprtopscreen.w -= FixedMul(dc_texturemid.w,spryscale.w);

			// draw the columns
			for (; dc_x <= x2 ; 
				dc_x+=detailshiftitercount,
				spryscale.w += rw_scalestep_shift,
				sprtopscreen.w -= sprtopscreen_step

			){
				texturecolumn = maskedtexturecol[dc_x];
				// calculate lighting
				if (texturecolumn != MAXSHORT) {
					if (!fixedcolormap) {

						// prevents a 12 bit shift in many cases. 
						// Rather than checking if (rw_scale >> 12) > 48, we check if rw_scale high bit > (12 << 4) which is 0x30000
						if (spryscale.h.intbits >= 3) {
							index = MAXLIGHTSCALE - 1;
						} else {
							// todo precalc the shift somehow. maybe precalc shift 4 and do byte swaps after 
							index = spryscale.w >> LIGHTSCALESHIFT;
						}

						dc_colormap_segment = colormaps_segment_maskedmapping;
				        dc_colormap_index = *((int8_t __far*)MK_FP(scalelightfixed_segment, walllights+index));


						// todo does it have to be reset after this?
					}
					

					// todo there's got to be a faster algorithm to calculcate this?
					//dc_iscale = 0xffffffffu / spryscale.w;
					dc_iscale = FastDiv3232(0xffffffffu, spryscale.w);


					// the below doesnt work because sometimes < FRACUNIT
					//dc_iscale = 0xffffu / spryscale.hu.intbits;  // this might be ok? 
				
					// draw the texture
						

					if (maskedtexrepeat){
						// if we know its a single repeating texture we just repeat with previously loaded params
						segment_t pixelsegment;
						int16_t usetexturecolumn = texturecolumn;
						
						// texturecolumn already masked...
						// todo double check..

						if (maskedtexmodulo){
							// power of 2. just modulo to get the column value
							usetexturecolumn  &= maskedtexmodulo;
						} else {
							// not power of 2. manual modulo process
							while (usetexturecolumn < (maskedcachedbasecol)){
								maskedcachedbasecol -= maskedtexrepeat;
							}
							//while (usetexturecolumn >= (maskedtexrepeat + maskedcachedbasecol)){
							//	maskedcachedbasecol += maskedtexrepeat;
							//}
							
							while (maskedcachedbasecol <= usetexturecolumn){
								maskedcachedbasecol += maskedtexrepeat;
							}
							maskedcachedbasecol -= maskedtexrepeat;

							usetexturecolumn -= maskedcachedbasecol;
						}

						if (lookup != 0xFF){

							
							if (maskedheaderpixeolfs != 0xFFFF){
								uint16_t __far* pixelofs   =  MK_FP(maskedpixeldataofs_segment, maskedheaderpixeolfs);
								uint16_t ofs  = pixelofs[usetexturecolumn]; // precached as segment value.
								pixelsegment = maskedcachedsegment + ofs;
							} else {
								pixelsegment = maskedcachedsegment 
									+ FastMul8u8u((uint8_t) usetexturecolumn, 
										maskedheightvalcache);
							}
 
							{
								uint16_t __far * postoffsets  =  MK_FP(maskedpostdataofs_segment, maskedpostsofs);
								uint16_t 		 postoffset = postoffsets[usetexturecolumn];
								R_DrawMaskedColumnCallHigh (pixelsegment, (column_t __far *)(MK_FP(maskedpostdata_segment, postoffset)));
							}



						} else {
							// e1m1 case thing
							pixelsegment = maskedcachedsegment 
									+ FastMul8u8u((uint8_t) usetexturecolumn, 
										maskedheightvalcache);
							
							R_DrawSingleMaskedColumnCallHigh(pixelsegment, cachedbyteheight);
						}
							
					} else {

						if (lookup != 0xFF){

							segment_t pixelsegment;

							if ((texturecolumn >= maskednextlookup) ||
								(texturecolumn < maskedprevlookup) ){
								pixelsegment = R_GetMaskedColumnSegment(texnum,texturecolumn);
								//todo: use self modifying code in ASM to change these maskedcachedbasecol values around here. then reset on function exit.
							} else {

								if (maskedheaderpixeolfs != 0xFFFF){
									uint16_t __far* pixelofs   =  MK_FP(maskedpixeldataofs_segment, maskedheaderpixeolfs);
									uint16_t ofs  = pixelofs[texturecolumn - maskedcachedbasecol]; // precached as segment value.
									pixelsegment = maskedcachedsegment + ofs;
								} else {

									pixelsegment = maskedcachedsegment 
										+ FastMul8u8u((uint8_t) (texturecolumn - maskedcachedbasecol) , 
													maskedheightvalcache);
								}


							}
							

							{
								uint16_t __far * postoffsets  =  MK_FP(maskedpostdataofs_segment, maskedpostsofs);
								uint16_t 		 postoffset = postoffsets[texturecolumn-maskedcachedbasecol];
								R_DrawMaskedColumnCallHigh (pixelsegment, (column_t __far *)(MK_FP(maskedpostdata_segment, postoffset)));
							}
						} else {
							segment_t pixelsegment;

							if (texturecolumn >= maskednextlookup ||
								texturecolumn < maskedprevlookup ){
								pixelsegment = R_GetMaskedColumnSegment(texnum,texturecolumn);
								//todo: use self modifying code in ASM to change these maskedcachedbasecol values around here. then reset on function exit.
							} else {
								pixelsegment = maskedcachedsegment 
										+ FastMul8u8u((uint8_t) (texturecolumn - maskedcachedbasecol) , 
													maskedheightvalcache);
							}

							R_DrawSingleMaskedColumnCallHigh(pixelsegment, cachedbyteheight);
						}
					}

					maskedtexturecol[dc_x] = MAXSHORT;
				}
			}
		}
	}
	
	maskednextlookup = NULL_TEX_COL;
	maskedtexrepeat = 0;
	// idea: store a "last used tex". reuse maskedtexrepeat?

}
*/


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

// cant have a MID and also a TOP/BOT. so 2 texes per wall at most
#define MID_TEXTURE_SEGLOOP_CACHE 		0
#define TOP_TEXTURE_SEGLOOP_CACHE 		0
#define BOT_TEXTURE_SEGLOOP_CACHE 		1

/*

void __near R_GetSourceSegment(int16_t texturecolumn, int16_t texture, int8_t segloopcachetype){

	if (seglooptexrepeat[segloopcachetype]){
		// if we know its a single repeating texture we just repeat with previously loaded params
		if (seglooptexmodulo[segloopcachetype]){
			// power of 2. just modulo to get the column value
			dc_source_segment = segloopcachedsegment[segloopcachetype] 
				+ FastMul8u8u((uint8_t) texturecolumn & seglooptexmodulo[segloopcachetype], 
							segloopheightvalcache[segloopcachetype]);

		} else {
			int16_t loopwidth = seglooptexrepeat[segloopcachetype];
			// not power of 2. manual modulo process
			while (texturecolumn < (segloopcachedbasecol[segloopcachetype])){
				segloopcachedbasecol[segloopcachetype] -= loopwidth;
			}
			while (texturecolumn >= (loopwidth + segloopcachedbasecol[segloopcachetype])){
				segloopcachedbasecol[segloopcachetype] += loopwidth;
			}
	
			dc_source_segment = segloopcachedsegment[segloopcachetype] 
				+ FastMul8u8u((uint8_t) (texturecolumn - segloopcachedbasecol[segloopcachetype]) , 
							segloopheightvalcache[segloopcachetype]);
		}
				
	} else {


		// note: column iteration can go in either dir, have to check for underflow and overflow
		if (texturecolumn >= segloopnextlookup[segloopcachetype] ||
			texturecolumn < segloopprevlookup[segloopcachetype] ){
			dc_source_segment = R_GetColumnSegment(texture, texturecolumn, segloopcachetype);
			//todo: use self modifying code in ASM to change these segloopcachedbasecol values around here. then reset on function exit.


		} else {
			dc_source_segment = segloopcachedsegment[segloopcachetype] 
				+ FastMul8u8u((uint8_t) (texturecolumn - segloopcachedbasecol[segloopcachetype]) , 
							segloopheightvalcache[segloopcachetype]);

		}
	}

	R_DrawColumnPrepCall(0);				


}

*/

void __near R_RenderSegLoop (fixed_t rw_scalestep);

/*

void __near R_RenderSegLoop (fixed_t rw_scalestep) {
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

	fixed_t			rwscaleshift    = rw_scalestep << detailshift2minus;
	fixed_t			topstepshift    = topstep      << detailshift2minus;
	fixed_t			bottomstepshift = bottomstep   << detailshift2minus;

	fixed_t			pixhighstepshift = pixhighstep << detailshift2minus;
	fixed_t			pixlowstepshift  = pixlowstep  << detailshift2minus;

	fixed_t base_rw_scale;
	fixed_t base_topfrac;
	fixed_t base_bottomfrac;
	fixed_t base_pixlow;
	fixed_t base_pixhigh;

  	int16_t base4diff = rw_x - rw_x_base4;


	while (base4diff){
		rw_scale.w      -= rw_scalestep;
		topfrac         -= topstep;
		bottomfrac      -= bottomstep;
		pixlow		    -= pixlowstep;
		pixhigh		    -= pixhighstep;
		base4diff--;
	}


	base_rw_scale   = rw_scale.w;
	base_topfrac    = topfrac;
	base_bottomfrac = bottomfrac;
	base_pixlow     = pixlow;
	base_pixhigh    = pixhigh;

 
	// per vga plane loop

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



		// if below minimum pixel, jump to next pixel in the plane
		rw_x = rw_x_base4 + xoffset;
		if (rw_x < start_rw_x){
			rw_x       += detailshiftitercount;
			topfrac    += topstepshift;
			bottomfrac += bottomstepshift;
			rw_scale.w += rwscaleshift;
			pixlow     += pixlowstepshift;
			pixhigh    += pixhighstepshift;

		}


		// per pixel loop. each iteration moves to next pixel in the plane
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
				
				//todo can we calculate this fast? fixedmul high 16? maybe not,  need precision of the low one...?
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


				dc_colormap_segment = colormaps_segment;
				dc_colormap_index = *((int8_t __far*)MK_FP(scalelightfixed_segment, walllights+index));
				dc_x = rw_x;
				//dc_iscale = 0xffffffffu / rw_scale.w;
				dc_iscale = FastDiv3232(0xffffffffu, rw_scale.w);
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

					dc_source_segment = R_GetSourceSegment(texturecolumn, midtexture, MID_TEXTURE_SEGLOOP_CACHE);

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

							dc_source_segment = R_GetSourceSegment(texturecolumn, toptexture, TOP_TEXTURE_SEGLOOP_CACHE);

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
					// todo: should (pixlow + heightunit - 1) be baked into the loop?

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

							dc_source_segment = R_GetSourceSegment(texturecolumn, bottomtexture, BOT_TEXTURE_SEGLOOP_CACHE);
							
							
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

	// force lookups on next cal
	segloopnextlookup[TOP_TEXTURE_SEGLOOP_CACHE] = -1;
	segloopnextlookup[BOT_TEXTURE_SEGLOOP_CACHE] = -1;
	seglooptexrepeat[TOP_TEXTURE_SEGLOOP_CACHE] = 0;
	seglooptexrepeat[BOT_TEXTURE_SEGLOOP_CACHE] = 0;


}

*/

// dont need to do step-related math for one seg
// dont need to do modulo vga plane stuff in a loop either
// not a big improvement, but an improvement. lots of extra code though. But it should eventually be loaded high into ems regions.
/*
void __near R_RenderOneSeg () {
    fineangle_t		angle;
	uint16_t		index;
    int16_t			yl;
    int16_t			yh;
    int16_t			mid;
    int16_t		    texturecolumn;
    int16_t			top;
    int16_t			bottom;
	fixed_t_union 	temp;
	int16_t 		rw_x_base4 = rw_x & detailshiftandval;	// knock out the low 2 bits. 
  	int16_t 		base4diff = rw_x - rw_x_base4;


	outp(SC_INDEX+1, quality_port_lookup[base4diff+detailshift.b.bytehigh]);
		


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
		temp.w = rw_offset.w - FixedMul(finetangent(angle),rw_distance);
		texturecolumn = temp.h.intbits;
		
	
		// calculate lighting

		// prevents a 12 bit shift in many cases. 
		// Rather than checking if (rw_scale >> 12) > 48, we check if rw_scale high bit > (12 << 4)
		if (rw_scale.h.intbits >= 3) {
			index = MAXLIGHTSCALE - 1;
		} else {
			index = rw_scale.w >> LIGHTSCALESHIFT;
		}
 

		dc_colormap_segment = colormaps_segment;
		dc_colormap_index = *((int8_t __far*)MK_FP(scalelightfixed_segment, walllights+index));

		dc_x = rw_x;
		//dc_iscale = 0xffffffffu / rw_scale.w;
		dc_iscale = FastDiv3232(0xffffffffu, rw_scale.w);
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

			dc_source_segment = R_GetColumnSegment(midtexture,texturecolumn, MID_TEXTURE_SEGLOOP_CACHE);

			R_DrawColumnPrepCall(0);				

		}
		ceilingclip[rw_x] = viewheight;
		floorclip[rw_x] = -1;
	} else {
	
	
		// two sided line
		if (toptexture) {
			// top wall
			mid = pixhigh>>HEIGHTBITS;

			if (mid >= floorclip[rw_x])
				mid = floorclip[rw_x]-1;

			if (mid >= yl) {
				if (yh > yl){
					dc_yl = yl;
					dc_yh = mid;
					dc_texturemid = rw_toptexturemid;

					dc_source_segment = R_GetColumnSegment(toptexture,texturecolumn, TOP_TEXTURE_SEGLOOP_CACHE);
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
			// todo: should (pixlow + heightunit - 1) be baked into the loop?

			mid = (pixlow + HEIGHTUNIT - 1) >> HEIGHTBITS;

			// no space above wall?
			if (mid <= ceilingclip[rw_x]) {
				mid = ceilingclip[rw_x] + 1;
			}
			if (mid <= yh) {
				if (yh > yl){
					dc_yl = mid;
					dc_yh = yh;
					dc_texturemid = rw_bottomtexturemid;

					dc_source_segment = R_GetColumnSegment(bottomtexture, texturecolumn, BOT_TEXTURE_SEGLOOP_CACHE);
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
			
	segloopnextlookup[TOP_TEXTURE_SEGLOOP_CACHE] = -1;
	segloopnextlookup[BOT_TEXTURE_SEGLOOP_CACHE] = -1;


}

*/

//
// R_StoreWallRange
// A wall segment will be drawn
//  between start and stop pixels (inclusive).
//
// Note: Start/stop refer to x coordinate pixels

// sq note: temp and temp angle have become confusing here, but basically angles are uint32_t
// while normal fixed_t is int32_t, and you have to make sure you use angles and fixed_t in the
// correct spots or you end up doing things like comparisons between uint32_t and int32_t.
/*
void __near R_StoreWallRange ( int16_t start, int16_t stop ) {
    fixed_t		hyp = 0;
    uint16_t	distangle = 0;
	uint16_t offsetangle;
    int16_t			lightnum;
	fixed_t_union rw_scalestep;

	// needs to be refreshed...
	side_t __far* side = &sides[curseg_render->sidedefOffset];
	side_render_t __near* side_render = &sides_render[curseg_render->sidedefOffset];
	vertex_t curlinev1 = vertexes[curseg_render->v1Offset];
	vertex_t curlinev2 = vertexes[curseg_render->v2Offset];
	int16_t sidetextureoffset;
	int16_t lineflags;
	angle_t tempangle;
	short_height_t frontsectorfloorheight;
	short_height_t frontsectorceilingheight;
	uint8_t frontsectorceilingpic;
	uint8_t frontsectorfloorpic;
	uint8_t frontsectorlightlevel;
	line_t __far* linedef;
	int16_t linedefOffset;
	uint16_t rw_normalangle_shiftleft3;
	fixed_t_union		worldtop;
	fixed_t_union		worldbottom;
	fixed_t_union		worldhigh;
	fixed_t_union		worldlow;

	if (ds_p == &drawsegs_BASE[MAXDRAWSEGS]){
		return;		
	}

		 
	//linedef = &lines[curseg->linedefOffset];
	linedefOffset = seg_linedefs[curseg];
	linedef = &lines[linedefOffset];
	lineflags = lineflagslist[linedefOffset];

#ifdef CHECK_FOR_ERRORS
	if (linedefOffset > numlines) {
		I_Error("R_StoreWallRange Error! lines out of bounds! %i %i %i %i", gametic, numlines, linedefOffset, curlinenum);
	}
#endif

    // mark the segment as visible for auto map
	// todo might actually be faster on average to check the bit... these shifts may suck
	seenlines[linedefOffset/8] |= (0x01 << (linedefOffset % 8));


    // calculate rw_distance for scale calculation
    rw_normalangle = seg_normalangles[curseg];
	rw_normalangle_shiftleft3 = rw_normalangle << SHORTTOFINESHIFT;


	offsetangle = (abs((rw_normalangle_shiftleft3) - (rw_angle1.hu.intbits)) >> 1) & 0xFFFC;

    if (offsetangle < FINE_ANG90_NOSHIFT){
		hyp = R_PointToDist (curlinev1.x, curlinev1.y);
	    distangle = FINE_ANG90_NOSHIFT - offsetangle;
	    rw_distance = FixedMulTrigNoShift(FINE_SINE_ARGUMENT, distangle, hyp);
	} else {
		// optimized from the above where distangle is FINE_ANG90 - FINE_ANG90 (or 0) then 
		// rw_distance is hyp multiplied by sine 0 (which is 0).
		rw_distance = 0;
	}


	// todo inline r_pointtodist when doing asm
	
    ds_p->x1 = rw_x = start;
    ds_p->x2 = stop;
    ds_p->cursegvalue = curseg;
    rw_stopx = stop+1;

 

    // calculate scale at both ends and step
    ds_p->scale1 = rw_scale.w =  R_ScaleFromGlobalAngle (viewangle_shiftright3+xtoviewangle[start]); // internally fineangle modded

    if (stop > start ) {
		ds_p->scale2 = R_ScaleFromGlobalAngle (viewangle_shiftright3 + xtoviewangle[stop]);

		rw_scalestep.w = FastDiv3216u((ds_p->scale2 - rw_scale.w), (stop-start));
		ds_p->scalestep = rw_scalestep.w;

    } else {
		ds_p->scale2 = ds_p->scale1;
    }
    



    // calculate texture boundaries
    //  and decide if floor / ceiling marks are needed
	
	

	
	frontsectorfloorheight = frontsector->floorheight;
	frontsectorceilingheight = frontsector->ceilingheight;
	frontsectorfloorpic = frontsector->floorpic;
	frontsectorceilingpic = frontsector->ceilingpic;
	frontsectorlightlevel = frontsector->lightlevel;

	SET_FIXED_UNION_FROM_SHORT_HEIGHT(worldtop, frontsectorceilingheight);
	worldtop.w -= viewz.w;
	SET_FIXED_UNION_FROM_SHORT_HEIGHT(worldbottom, frontsectorfloorheight);
	worldbottom.w -= viewz.w;
    midtexture = toptexture = bottomtexture = maskedtexture = 0;
    ds_p->maskedtexturecol_val = NULL_TEX_COL;
	

	sidetextureoffset = side->textureoffset;
	
	if (backsector_offset  == SECNUM_NULL) {
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
		ds_p->sprtopclip_offset = offset_screenheightarray;
		ds_p->sprbottomclip_offset = offset_negonearray;
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
			ds_p->sprbottomclip_offset = offset_negonearray;
			ds_p->bsilheight = MAXSHORT;
			ds_p->silhouette |= SIL_BOTTOM;
		}
	
		if (backsectorfloorheight >= frontsectorceilingheight) {
			ds_p->sprtopclip_offset = offset_screenheightarray;
			ds_p->tsilheight = MINSHORT;
			ds_p->silhouette |= SIL_TOP;
		}
		SET_FIXED_UNION_FROM_SHORT_HEIGHT(worldhigh, backsectorceilingheight);
		worldhigh.w -= viewz.w;
		SET_FIXED_UNION_FROM_SHORT_HEIGHT(worldlow, backsectorfloorheight);
		worldlow.w -= viewz.w;
		
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
				SET_FIXED_UNION_FROM_SHORT_HEIGHT(rw_toptexturemid, backsectorceilingheight);
				rw_toptexturemid.h.intbits += textureheights[side->toptexture] + 1;
				// bottom of texture

				rw_toptexturemid.w -= viewz.w;
				
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
			ds_p->maskedtexturecol_val = lastopening - rw_x;
    		maskedtexturecol_offset = (ds_p->maskedtexturecol_val) << 1;
			lastopening += rw_stopx - rw_x;
		}
    }
    
    // calculate rw_offset (only needed for textured lines)
    segtextured = midtexture | toptexture | bottomtexture | maskedtexture;

    if (segtextured) {
 
		
		//offsetangle = ((rw_normalangle_shiftleft3) - (rw_angle1.hu.intbits)) >> SHORTTOFINESHIFT;


		if (offsetangle > FINE_ANG180_NOSHIFT) {
			offsetangle = MOD_FINE_ANGLE_NOSHIFT(-offsetangle);
		}

		if (!hyp){
			hyp = R_PointToDist (curlinev1.x, curlinev1.y);
		}

		if (offsetangle > FINE_ANG90_NOSHIFT) {
			//optimized from setting it to fine_ang90 then multiplying hyp by sine of 90
			rw_offset.w = hyp;
		} else {
	 		rw_offset.w = FixedMulTrigNoShift(FINE_SINE_ARGUMENT, offsetangle, hyp);
		}

	
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
				walllights = 0;
			} else if (lightnum >= LIGHTLEVELS) {
				walllights = lightmult48lookup[LIGHTLEVELS - 1];
			} else {
				walllights = lightmult48lookup[lightnum];
			}
			walllights+=SCALE_LIGHT_OFFSET_IN_FIXED_SCALELIGHT;
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
	
    topfrac    = (centeryfrac_shiftright4.w) - FixedMul (worldtop.w, rw_scale.w);
    bottomfrac = (centeryfrac_shiftright4.w) - FixedMul (worldbottom.w, rw_scale.w);

	
   
    // render it
	if (markceiling) {
		ceilingplaneindex = R_CheckPlane(ceilingplaneindex, rw_x, rw_stopx - 1, IS_CEILING_PLANE);
	}
    
	if (markfloor) {
		floorplaneindex = R_CheckPlane(floorplaneindex, rw_x, rw_stopx - 1, IS_FLOOR_PLANE);
	}
	
    //if (stop > start ) {
    if (stop >= start ) {

		topstep =    -FixedMul    (rw_scalestep.w,          worldtop.w);
		bottomstep = -FixedMul    (rw_scalestep.w,          worldbottom.w);

 		if (backsector_offset  != SECNUM_NULL) {
 		//if (backsector  != NULL) {
			// todo dont shift 4 twice, instead borrow old value somehow and do byte shift... rare case though


			worldhigh.w >>= 4;
			worldlow.w >>= 4;
			if (worldhigh.w < worldtop.w) {

				pixhigh = (centeryfrac_shiftright4.w) - FixedMul (worldhigh.w, rw_scale.w);
				pixhighstep = -FixedMul    (rw_scalestep.w,          worldhigh.w);

			}
		
			if (worldlow.w > worldbottom.w) {
				pixlow = (centeryfrac_shiftright4.w) - FixedMul (worldlow.w, rw_scale.w);
				pixlowstep = -FixedMul    (rw_scalestep.w,          worldlow.w);

			}

		}


		R_RenderSegLoop (rw_scalestep.w);


	}
    
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

*/


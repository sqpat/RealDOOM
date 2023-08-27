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
#include "r_sky.h"
#include "z_zone.h"

// OPTIMIZE: closed two sided lines as single sided

// True if any of the segs textures might be visible.
boolean		segtextured;	

// False if the back side is the same plane.
boolean		markfloor;	
boolean		markceiling;

boolean		maskedtexture;
int16_t		toptexture;
int16_t		bottomtexture;
int16_t		midtexture;


angle_t		rw_normalangle;
// angle to line origin
int32_t		rw_angle1;	

//
// regular wall
//
int16_t		rw_x;
int16_t		rw_stopx;
angle_t		rw_centerangle;
fixed_t		rw_offset;
fixed_t		rw_distance;
fixed_t		rw_scale;
fixed_t		rw_scalestep;
fixed_t		rw_midtexturemid;
fixed_t		rw_toptexturemid;
fixed_t		rw_bottomtexturemid;

int32_t		worldtop;
int32_t		worldbottom;
int32_t		worldhigh;
int32_t		worldlow;

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
	int32_t		x1,
	int32_t		x2)
{
	uint32_t	index;
	column_t*	col;
	int16_t		lightnum;
	int16_t		texnum;
	fixed_t* textureheight;
	int16_t* texturetranslation;
	fixed_t siderowoffset;
	line_t* lines;
	seg_t* segs = (seg_t*)Z_LoadBytesFromEMS(segsRef);
	int16_t curlinev1Offset; int16_t curlinev2Offset; int16_t curlinefrontsecnum; int16_t curlinebacksecnum; int16_t curlinesidedefOffset; int16_t curlinelinedefOffset;
	side_t* sides;
	int16_t sidemidtexture;
	vertex_t* vertexes; 
	sector_t* sectors;
	sector_t frontsector;
	sector_t backsector;

	// Calculate light table.
	// Use different light tables
	//   for horizontal / vertical / diagonal. Diagonal?
	// OPTIMIZE: get rid of LIGHTSEGSHIFT globally
	curlinenum = ds->curlinenum;
	curlinev1Offset = segs[curlinenum].v1Offset;
	curlinev2Offset = segs[curlinenum].v1Offset;
	curlinefrontsecnum = segs[curlinenum].frontsecnum;
	curlinebacksecnum = segs[curlinenum].backsecnum;
	curlinesidedefOffset = segs[curlinenum].sidedefOffset;
	curlinelinedefOffset = segs[curlinenum].linedefOffset;
	sides = (side_t*)Z_LoadBytesFromEMS(sidesRef);
	siderowoffset = sides[curlinesidedefOffset].rowoffset;
	sidemidtexture = sides[curlinesidedefOffset].midtexture;


	frontsecnum = curlinefrontsecnum;
	backsecnum = curlinebacksecnum;
	texturetranslation = Z_LoadBytesFromEMS(texturetranslationRef);
	texnum = texturetranslation[sidemidtexture];

	sectors = (sector_t*)Z_LoadBytesFromEMS(sectorsRef);
	frontsector = sectors[frontsecnum];
	backsector = sectors[backsecnum];

	lightnum = (frontsector.lightlevel >> LIGHTSEGSHIFT) + extralight;
	
	vertexes = (vertex_t*)Z_LoadBytesFromEMS(vertexesRef);
	if (vertexes[curlinev1Offset].y == vertexes[curlinev2Offset].y) {
		lightnum--;
	}
	else if (vertexes[curlinev1Offset].x == vertexes[curlinev2Offset].x) {
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
    spryscale = ds->scale1 + (x1 - ds->x1)*rw_scalestep;
    mfloorclip = ds->sprbottomclip;
    mceilingclip = ds->sprtopclip;
    
    // find positioning
	lines = (line_t*)Z_LoadBytesFromEMS(linesRef);
    if (lines[curlinelinedefOffset].flags & ML_DONTPEGBOTTOM) {
		dc_texturemid = frontsector.floorheight > backsector.floorheight ? frontsector.floorheight : backsector.floorheight;
		textureheight = Z_LoadBytesFromEMS(textureheightRef);
		dc_texturemid = dc_texturemid + textureheight[texnum] - viewz;
    } else {
		dc_texturemid = frontsector.ceilingheight< backsector.ceilingheight ? frontsector.ceilingheight : backsector.ceilingheight;
		dc_texturemid = dc_texturemid - viewz;
    }
    dc_texturemid += siderowoffset;
			
    if (fixedcolormap)
	dc_colormap = fixedcolormap;
    
    // draw the columns
    for (dc_x = x1 ; dc_x <= x2 ; dc_x++)
    {
	// calculate lighting
	if (maskedtexturecol[dc_x] != MAXSHORT)
	{
	    if (!fixedcolormap)
	    {
		index = spryscale>>LIGHTSCALESHIFT;

		if (index >=  MAXLIGHTSCALE )
		    index = MAXLIGHTSCALE-1;

		dc_colormap = walllights[index];
	    }
			
	    sprtopscreen = centeryfrac - FixedMul(dc_texturemid, spryscale);
	    dc_iscale = 0xffffffffu / (uint32_t)spryscale;
	    
	    // draw the texture
	    col = (column_t *)((byte *)R_GetColumn(texnum,maskedtexturecol[dc_x]) -3);
			
	    R_DrawMaskedColumn (col);
	    maskedtexturecol[dc_x] = MAXSHORT;
	}
	spryscale += rw_scalestep;
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
    angle_t		angle;
	uint32_t		index;
    int32_t			yl;
    int32_t			yh;
    int32_t			mid;
    fixed_t		texturecolumn;
    int16_t			top;
    int16_t			bottom;
    //texturecolumn = 0;				// shut up compiler warning


    for ( ; rw_x < rw_stopx ; rw_x++)
    {
	// mark floor / ceiling areas
	yl = (topfrac+HEIGHTUNIT-1)>>HEIGHTBITS;

	// no space above wall?
	if (yl < ceilingclip[rw_x]+1)
	    yl = ceilingclip[rw_x]+1;
	
	if (markceiling)
	{
	    top = ceilingclip[rw_x]+1;
	    bottom = yl-1;

	    if (bottom >= floorclip[rw_x])
		bottom = floorclip[rw_x]-1;

	    if (top <= bottom)
	    {
		ceilingplane->top[rw_x] = top;
		ceilingplane->bottom[rw_x] = bottom;
	    }
	}
		
	yh = bottomfrac>>HEIGHTBITS;

	if (yh >= floorclip[rw_x])
	    yh = floorclip[rw_x]-1;

	if (markfloor)
	{
	    top = yh+1;
	    bottom = floorclip[rw_x]-1;
	    if (top <= ceilingclip[rw_x])
		top = ceilingclip[rw_x]+1;
	    if (top <= bottom)
	    {
		floorplane->top[rw_x] = top;
		floorplane->bottom[rw_x] = bottom;
	    }
	}
	
	// texturecolumn and lighting are independent of wall tiers
	if (segtextured)
	{
	    // calculate texture offset
	    angle = (rw_centerangle + xtoviewangle[rw_x])>>ANGLETOFINESHIFT;
	    texturecolumn = rw_offset-FixedMul(finetangent(angle),rw_distance);
	    texturecolumn >>= FRACBITS;
	    // calculate lighting
	    index = rw_scale>>LIGHTSCALESHIFT;

	    if (index >=  MAXLIGHTSCALE )
		index = MAXLIGHTSCALE-1;

	    dc_colormap = walllights[index];
	    dc_x = rw_x;
	    dc_iscale = 0xffffffffu / (uint32_t)rw_scale;
	}

	// draw the wall tiers
	if (midtexture)
	{
		// single sided line
	    dc_yl = yl;
	    dc_yh = yh;
	    dc_texturemid = rw_midtexturemid;


		dc_source = R_GetColumn(midtexture,texturecolumn);
		colfunc ();
		ceilingclip[rw_x] = viewheight;
	    floorclip[rw_x] = -1;
	}
	else
	{
	    
		
		// two sided line
	    if (toptexture)
	    {
		// top wall
		mid = pixhigh>>HEIGHTBITS;
		pixhigh += pixhighstep;

		if (mid >= floorclip[rw_x])
		    mid = floorclip[rw_x]-1;

		if (mid >= yl)
		{
		    dc_yl = yl;
		    dc_yh = mid;
		    dc_texturemid = rw_toptexturemid;

		    dc_source = R_GetColumn(toptexture,texturecolumn);
		    colfunc ();
		    ceilingclip[rw_x] = mid;
		}
		else
		    ceilingclip[rw_x] = yl-1;
	    }
	    else
	    {
		// no top wall
		if (markceiling)
		    ceilingclip[rw_x] = yl-1;
	    }
			
	    if (bottomtexture)
	    {
		// bottom wall
		mid = (pixlow+HEIGHTUNIT-1)>>HEIGHTBITS;
		pixlow += pixlowstep;

		// no space above wall?
		if (mid <= ceilingclip[rw_x])
		    mid = ceilingclip[rw_x]+1;
		
		if (mid <= yh)
		{
		    dc_yl = mid;
		    dc_yh = yh;
		    dc_texturemid = rw_bottomtexturemid;

			dc_source = R_GetColumn(bottomtexture,
					    texturecolumn);
		    colfunc ();
		    floorclip[rw_x] = mid;
		}
		else
		    floorclip[rw_x] = yh+1;
	    }
	    else
	    {
		// no bottom wall
		if (markfloor)
		    floorclip[rw_x] = yh+1;
	    }
			
	    if (maskedtexture)
	    {
		// save texturecol
		//  for backdrawing of masked mid texture
		maskedtexturecol[rw_x] = texturecolumn;
	    }
	}
		
	rw_scale += rw_scalestep;
	topfrac += topstep;
	bottomfrac += bottomstep;
    }
}




//
// R_StoreWallRange
// A wall segment will be drawn
//  between start and stop pixels (inclusive).
//
void
R_StoreWallRange
( int16_t	start,
  int16_t	stop )
{
    fixed_t		hyp;
    fixed_t		sineval;
    angle_t		distangle, offsetangle;
    fixed_t		vtop;
    int16_t			lightnum;
	fixed_t *	textureheight;
	int16_t* 	texturetranslation;
	vertex_t* vertexes;

	// needs to be refreshed...
	seg_t* segs = (seg_t*)Z_LoadBytesFromEMS(segsRef);
	int16_t curlinelinedefOffset = segs[curlinenum].linedefOffset;
	angle_t curlineangle = segs[curlinenum].angle;
	int16_t curlinev1Offset = segs[curlinenum].v1Offset;
	int16_t curlinev2Offset = segs[curlinenum].v2Offset;
	int16_t curlinesidedefOffset = segs[curlinenum].sidedefOffset;
	fixed_t curlineOffset = segs[curlinenum].offset;
	side_t* sides;
	fixed_t siderowoffset;
	int16_t sidemidtexture;
	int16_t sidetoptexture;
	int16_t sidebottomtexture;
	fixed_t sidetextureoffset;
	line_t* lines;
	int16_t lineflags;
	sector_t* sectors;
	sector_t frontsector;
	sector_t backsector;

	if (ds_p == &drawsegs[MAXDRAWSEGS])
		return;		
		 

	linedefOffset = curlinelinedefOffset;

	if (linedefOffset > numlines) {
		I_Error("R_StoreWallRange Error! lines out of bounds! %i %i %i %i", gametic, numlines, linedefOffset, curlinenum);
	}

    // mark the segment as visible for auto map
	lines = (line_t*)Z_LoadBytesFromEMS(linesRef);

	(&lines[linedefOffset])->flags |= ML_MAPPED;
//	linedef->flags |= ML_MAPPED;

	lineflags = (&lines[linedefOffset])->flags;
    
    // calculate rw_distance for scale calculation
    rw_normalangle = curlineangle + ANG90;
    offsetangle = abs(rw_normalangle-rw_angle1);
    
    if (offsetangle > ANG90)
	offsetangle = ANG90;

    distangle = ANG90 - offsetangle;
	distangle = distangle >> ANGLETOFINESHIFT;

	vertexes = (vertex_t*)Z_LoadBytesFromEMS(vertexesRef);
	hyp = R_PointToDist (vertexes[curlinev1Offset].x, vertexes[curlinev1Offset].y);
    sineval = finesine(distangle);
    rw_distance = FixedMul (hyp, sineval);
		
	
    ds_p->x1 = rw_x = start;
    ds_p->x2 = stop;
    ds_p->curlinenum = curlinenum;
    rw_stopx = stop+1;


    
    // calculate scale at both ends and step
    ds_p->scale1 = rw_scale = 
	R_ScaleFromGlobalAngle (viewangle + xtoviewangle[start]);
    
    if (stop > start ) {
		ds_p->scale2 = R_ScaleFromGlobalAngle (viewangle + xtoviewangle[stop]);
		ds_p->scalestep = rw_scalestep =  (ds_p->scale2 - rw_scale) / (stop-start);
    } else {
		ds_p->scale2 = ds_p->scale1;
    }
    
	sectors = (sector_t*)Z_LoadBytesFromEMS(sectorsRef);
	frontsector = sectors[frontsecnum];
	backsector = sectors[backsecnum];


    // calculate texture boundaries
    //  and decide if floor / ceiling marks are needed
    worldtop = frontsector.ceilingheight - viewz;
    worldbottom = frontsector.floorheight - viewz;
	
    midtexture = toptexture = bottomtexture = maskedtexture = 0;
    ds_p->maskedtexturecol = NULL;
	
	if (curlinesidedefOffset > numsides) {
		I_Error("Error! sides out of bounds! %i %i %i %i", gametic, numsides, curlinesidedefOffset, curlinenum);
	}

	sides = (side_t*)Z_LoadBytesFromEMS(sidesRef);
	siderowoffset = sides[curlinesidedefOffset].rowoffset;
	sidemidtexture = sides[curlinesidedefOffset].midtexture;
	sidetoptexture = sides[curlinesidedefOffset].toptexture;
	sidebottomtexture = sides[curlinesidedefOffset].bottomtexture;
	sidetextureoffset = sides[curlinesidedefOffset].textureoffset;
	
	if (backsecnum == SECNUM_NULL) {
	// single sided line
		texturetranslation = Z_LoadBytesFromEMS(texturetranslationRef);
		midtexture = texturetranslation[sidemidtexture];
		// a single sided line is terminal, so it must mark ends
		markfloor = markceiling = true;
		if (lineflags & ML_DONTPEGBOTTOM) {
			textureheight = Z_LoadBytesFromEMS(textureheightRef);
			vtop = frontsector.floorheight +
			textureheight[sidemidtexture];
			// bottom of texture at bottom
			rw_midtexturemid = vtop - viewz;	
		} else {
			// top of texture at top
			rw_midtexturemid = worldtop;
		}
		rw_midtexturemid += siderowoffset;

		ds_p->silhouette = SIL_BOTH;
		ds_p->sprtopclip = screenheightarray;
		ds_p->sprbottomclip = negonearray;
		ds_p->bsilheight = MAXLONG;
		ds_p->tsilheight = MINLONG;
    } else {
		// two sided line
		ds_p->sprtopclip = ds_p->sprbottomclip = NULL;
		ds_p->silhouette = 0;
	
		if (frontsector.floorheight > backsector.floorheight) {
			ds_p->silhouette = SIL_BOTTOM;
			ds_p->bsilheight = frontsector.floorheight;
		} else if (backsector.floorheight > viewz) {
			ds_p->silhouette = SIL_BOTTOM;
			ds_p->bsilheight = MAXLONG;
			// ds_p->sprbottomclip = negonearray;
		}
	
		if (frontsector.ceilingheight < backsector.ceilingheight) {
			ds_p->silhouette |= SIL_TOP;
			ds_p->tsilheight = frontsector.ceilingheight;
		} else if (backsector.ceilingheight < viewz) {
			ds_p->silhouette |= SIL_TOP;
			ds_p->tsilheight = MINLONG;
			// ds_p->sprtopclip = screenheightarray;
		}
		
		if (backsector.ceilingheight <= frontsector.floorheight) {
			ds_p->sprbottomclip = negonearray;
			ds_p->bsilheight = MAXLONG;
			ds_p->silhouette |= SIL_BOTTOM;
		}
	
		if (backsector.floorheight >= frontsector.ceilingheight) {
			ds_p->sprtopclip = screenheightarray;
			ds_p->tsilheight = MINLONG;
			ds_p->silhouette |= SIL_TOP;
		}
	
		worldhigh = backsector.ceilingheight - viewz;
		worldlow = backsector.floorheight - viewz;
		
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
			 
			texturetranslation = Z_LoadBytesFromEMS(texturetranslationRef);
			toptexture = texturetranslation[sidetoptexture];
		
		
			if (lineflags & ML_DONTPEGTOP) {
				// top of texture at top
				rw_toptexturemid = worldtop;
			} else {
				textureheight = Z_LoadBytesFromEMS(textureheightRef);
				vtop = backsector.ceilingheight + textureheight[sidetoptexture];
		
				// bottom of texture
				rw_toptexturemid = vtop - viewz;	
			}
		}
		if (worldlow > worldbottom) {
			// bottom texture
			texturetranslation = Z_LoadBytesFromEMS(texturetranslationRef);
			bottomtexture = texturetranslation[sidebottomtexture];

			if (lineflags & ML_DONTPEGBOTTOM ) {
				// bottom of texture at bottom
				// top of texture at top
				rw_bottomtexturemid = worldtop;
			}
			else {	// top of texture at top
				rw_bottomtexturemid = worldlow;
			}
		}
			rw_toptexturemid += siderowoffset;
			rw_bottomtexturemid += siderowoffset;
	
		// allocate space for masked texture tables
		if (sidemidtexture) {
			// masked midtexture
			maskedtexture = true;
			ds_p->maskedtexturecol = maskedtexturecol = lastopening - rw_x;
			lastopening += rw_stopx - rw_x;
		}
    }
    
    // calculate rw_offset (only needed for textured lines)
    segtextured = midtexture | toptexture | bottomtexture | maskedtexture;

    if (segtextured) {
		offsetangle = rw_normalangle-rw_angle1;
	
		if (offsetangle > ANG180) {
			offsetangle = -offsetangle;
		}

		if (offsetangle > ANG90) {
			offsetangle = ANG90;
		}
		offsetangle = offsetangle >> ANGLETOFINESHIFT;
		sineval = finesine(offsetangle);
		rw_offset = FixedMul (hyp, sineval);

		if (rw_normalangle - rw_angle1 < ANG180) {
			rw_offset = -rw_offset;
		}

		rw_offset += sidetextureoffset + curlineOffset;
		rw_centerangle = ANG90 + viewangle - rw_normalangle;
	
		// calculate light table
		//  use different light tables
		//  for horizontal / vertical / diagonal
		// OPTIMIZE: get rid of LIGHTSEGSHIFT globally
		if (!fixedcolormap){
			lightnum = (frontsector.lightlevel >> LIGHTSEGSHIFT)+extralight;
			vertexes = (vertex_t*)Z_LoadBytesFromEMS(vertexesRef);

			if (vertexes[curlinev1Offset].y == vertexes[curlinev2Offset].y) {
				lightnum--;
			} else if (vertexes[curlinev1Offset].x == vertexes[curlinev2Offset].x) {
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
    
  
    if (frontsector.floorheight >= viewz) {
		// above view plane
		markfloor = false;
    }
    
    if (frontsector.ceilingheight <= viewz  && frontsector.ceilingpic != skyflatnum) {
		// below view plane
		markceiling = false;
    }

    
    // calculate incremental stepping values for texture edges
    worldtop >>= 4;
    worldbottom >>= 4;
	
    topstep = -FixedMul (rw_scalestep, worldtop);
    topfrac = (centeryfrac>>4) - FixedMul (worldtop, rw_scale);

    bottomstep = -FixedMul (rw_scalestep,worldbottom);
    bottomfrac = (centeryfrac>>4) - FixedMul (worldbottom, rw_scale);
	
    if (backsecnum != SECNUM_NULL) {	
		worldhigh >>= 4;
		worldlow >>= 4;

		if (worldhigh < worldtop) {
			pixhigh = (centeryfrac>>4) - FixedMul (worldhigh, rw_scale);
			pixhighstep = -FixedMul (rw_scalestep,worldhigh);
		}
	
		if (worldlow > worldbottom) {
			pixlow = (centeryfrac>>4) - FixedMul (worldlow, rw_scale);
			pixlowstep = -FixedMul (rw_scalestep,worldlow);
		}
    }

    // render it
	if (markceiling) {
		ceilingplane = R_CheckPlane(ceilingplane, rw_x, rw_stopx - 1);
	}
    
	if (markfloor) {
		floorplane = R_CheckPlane(floorplane, rw_x, rw_stopx - 1);
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
	ds_p->tsilheight = MINLONG;
    }
    if (maskedtexture && !(ds_p->silhouette&SIL_BOTTOM))
    {
	ds_p->silhouette |= SIL_BOTTOM;
	ds_p->bsilheight = MAXLONG;
    }
    ds_p++;
}


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
//      Refresh of things, i.e. objects represented by sprites.
//


#include <stdio.h>
#include <stdlib.h>


#include "doomdef.h"

#include "i_system.h"
#include "z_zone.h"
#include "w_wad.h"

#include "r_local.h"

#include "doomstat.h"
#include "m_misc.h"
#include "p_local.h"
#include "m_memory.h"
#include "m_near.h"
#include <dos.h>
#include <conio.h>




#define MINZ_HIGHBITS					4
#define BASEYCENTER                     100L
#define SC_INDEX                0x3C4







//
// GAME FUNCTIONS
//


 #define GC_INDEX                0x3CE
#define GC_READMAP              4

 

 



//
// R_DrawMaskedColumn
// Used for sprites and masked mid textures.
// Masked means: partly transparent, i.e. stored
//  in posts/runs of opaque pixels.
//



void __near R_DrawMaskedSpriteShadow (segment_t pixelsegment, column_t __far* column) {
	
    fixed_t_union     topscreen;
	fixed_t_union     bottomscreen;
	fixed_t_union     basetexturemid;
    
    uint16_t currentoffset = 0;
    basetexturemid = dc_texturemid;
    
    // if its mot a masked texture, we determine length and topdelta from the real values in the texture?

    while (column->topdelta != 0xFF)  {
        // calculate unclipped screen coordinates
        //  for post

        //todo: this is fastmul 8 by 32. maybe even faster.
        topscreen.w = sprtopscreen.w + FastMul8u32u(column->topdelta, spryscale.w);
        bottomscreen.w = topscreen.w + FastMul8u32u(column->length,   spryscale.w);

		dc_yl = topscreen.h.intbits; 
		dc_yh = bottomscreen.h.intbits;
		if (!bottomscreen.h.fracbits)
			dc_yh--;
		if (topscreen.h.fracbits)
			dc_yl++;

        if (dc_yh >= mfloorclip[dc_x])
            dc_yh = mfloorclip[dc_x]-1;
        if (dc_yl <= mceilingclip[dc_x])
            dc_yl = mceilingclip[dc_x]+1;

        if (dc_yl <= dc_yh) {
            int16_t count;  // todo uint8_t?
            //dc_source_segment = pixelsegment+ (currentoffset >> 4);
			dc_texturemid = basetexturemid;
			dc_texturemid.h.intbits -= column->topdelta;


            // Adjust borders. Low... 
            if (!dc_yl) 
                dc_yl = 1;

            // .. and high.
            if (dc_yh == viewheight-1) 
                dc_yh = viewheight - 2; 
                
            count = dc_yh - dc_yl; 
            

            // Zero length.
            if (count >= 0){
            	uint8_t lookup = detailshift.b.bytehigh + (dc_x&3);
                
                byte __far * dest = destview + dc_yl_lookup_high[dc_yl] + (dc_x>>detailshift2minus);
                outp  (SC_INDEX + 1, quality_port_lookup[lookup]); 
                outpw (GC_INDEX,     vga_read_port_lookup[lookup] );

                R_DrawFuzzColumnCallHigh(count, dest);
            } 
                 
        
            


                
        }
        // these column definittions are just contiguous in memory
        currentoffset += column->length;
        currentoffset += (16 - ((column->length &0xF)) &0xF);
        
        column++;

    }
    // if we dont update above we dont need to rest it
    //dc_colormap = MK_FP(colormaps_segment_high, old_dc_colormap);
        
    dc_texturemid = basetexturemid;

}
/*
void __near R_DrawMaskedColumn2 (segment_t pixelsegment, column_t __far* column) {
	
	fixed_t_union     topscreen;
	fixed_t_union     bottomscreen;
	fixed_t_union     basetexturemid;
    
    uint16_t currentoffset = 0;
    basetexturemid = dc_texturemid;
    
    // if its mot a masked texture, we determine length and topdelta from the real values in the texture?

    while (column->topdelta != 0xFF)  {
        // calculate unclipped screen coordinates
        //  for post
        topscreen.w = sprtopscreen + FastMul16u32u(column->topdelta, spryscale.w);
        bottomscreen.w = topscreen.w + FastMul16u32u(column->length, spryscale.w);

		dc_yl = topscreen.h.intbits; 
		dc_yh = bottomscreen.h.intbits;
		if (!bottomscreen.h.fracbits)
			dc_yh--;
		if (topscreen.h.fracbits)
			dc_yl++;

        if (dc_yh >= mfloorclip[dc_x])
            dc_yh = mfloorclip[dc_x]-1;
        if (dc_yl <= mceilingclip[dc_x])
            dc_yl = mceilingclip[dc_x]+1;

        if (dc_yl <= dc_yh) {

            dc_source_segment = pixelsegment+ (currentoffset >> 4);
			dc_texturemid = basetexturemid;
			dc_texturemid.h.intbits -= column->topdelta;

            R_DrawColumnPrepCallHigh(colormaps_high_seg_diff);

                
        }
        // these column definittions are just contiguous in memory
        currentoffset += column->length;
        currentoffset += (16 - ((column->length &0xF)) &0xF);
        
        column++;

    }
    // if we dont update above we dont need to rest it
    //dc_colormap = MK_FP(colormaps_segment_high, old_dc_colormap);
        
    dc_texturemid = basetexturemid;
}
*/

// this is called for things like reverse sides of columns and openings where the underlying texture is not actually masked
// only a single column is actually drawn

/*
void __near R_DrawSingleMaskedColumn2 (segment_t pixeldatasegment, byte length) {
	
	fixed_t_union     topscreen;
	fixed_t_union     bottomscreen;
	fixed_t_union     basetexturemid;
    
    basetexturemid = dc_texturemid;
    
    // if its mot a masked texture, we determine length and topdelta from the real values in the texture?

    // calculate unclipped screen coordinates
    //  for post
    topscreen.w = sprtopscreen;
    bottomscreen.w = topscreen.w + FastMul16u32u(length, spryscale.w);

    dc_yl = topscreen.h.intbits; 
    dc_yh = bottomscreen.h.intbits;
    if (!bottomscreen.h.fracbits)
        dc_yh--;
    if (topscreen.h.fracbits)
        dc_yl++;

    if (dc_yh >= mfloorclip[dc_x])
        dc_yh = mfloorclip[dc_x]-1;
    if (dc_yl <= mceilingclip[dc_x])
        dc_yl = mceilingclip[dc_x]+1;

    if (dc_yl <= dc_yh) {

        dc_source_segment = pixeldatasegment;
        dc_texturemid = basetexturemid;

        R_DrawColumnPrepCallHigh(colormaps_high_seg_diff);

            
    }

    
    // if we dont update above we dont need to rest it
    //dc_colormap = MK_FP(colormaps_segment_high, old_dc_colormap);
        
    dc_texturemid = basetexturemid;
}

*/

//
// R_DrawVisSprite
//  mfloorclip and mceilingclip should also be set.
//


void __near R_DrawVisSprite ( vissprite_t __near* vis ) {
    
    fixed_t_union       frac;
    segment_t      patch_segment;
    patch_t __far * patch;


    dc_colormap_segment = colormaps_segment_high;
    dc_colormap_index = vis->colormap;
    
    dc_iscale = labs(vis->xiscale)>>detailshift.b.bytelow;
    dc_texturemid.w = vis->texturemid;
    frac.w = vis->startfrac;
    spryscale.w = vis->scale;
    // note: bottom 16 bits of centeryfrac are 0. optimizable?
    sprtopscreen.h.intbits = centery;
    sprtopscreen.h.fracbits = 0;
    // todo: maybe do a check for spryscale fracbits = 0; common case.
    sprtopscreen.w -= FixedMul(dc_texturemid.w,spryscale.w);
         
    if (vis->patch == lastvisspritepatch){
        patch_segment = lastvisspritesegment;
    } else {
        if (vis->patch ==  lastvisspritepatch2){
            // swap MRU order..
            patch_segment = lastvisspritesegment2;
            lastvisspritesegment2 = lastvisspritesegment;
            lastvisspritesegment = patch_segment;
            lastvisspritepatch2 = lastvisspritepatch;
            lastvisspritepatch = vis->patch;
        } else {
            lastvisspritepatch2 = lastvisspritepatch;
            lastvisspritesegment2 = lastvisspritesegment;
        	patch_segment = lastvisspritesegment = getspritetexture(vis->patch);            
            lastvisspritepatch = vis->patch;
        }
    }

    patch = MK_FP(patch_segment, 0);


	{
		int16_t dc_x_base4 = vis->x1 & (detailshiftandval);	// knock out the low 2 bits

        int16_t base4diff = vis->x1 - dc_x_base4;

		fixed_t basespryscale = frac.w;
		int16_t xoffset;
        fixed_t xiscalestep_shift = vis->xiscale << detailshift2minus;



        // offset scale by the number of pixels that will be added back to it later..
        // essentiall the &0xFFFC of the scale
        while (base4diff){
            basespryscale-=vis->xiscale; 
            base4diff--;
        }




        // draw the columns
        // todo eventually combine these, use a function pointer.

        if ((vis->colormap != COLORMAP_SHADOW)){
            for (xoffset = 0 ; xoffset < detailshiftitercount ;
                xoffset++, 
                basespryscale+=vis->xiscale) {

                outp(SC_INDEX+1, quality_port_lookup[xoffset+detailshift.b.bytehigh]);


                frac.w = basespryscale;
                dc_x = dc_x_base4 + xoffset;
                if (dc_x < vis->x1){
                    dc_x   += detailshiftitercount;
                    frac.w += xiscalestep_shift;
                    

                }
                // todo double check...  is xiscalestep_shift ever nonzero?
                for ( ; dc_x<=vis->x2 ; 
                    dc_x+=detailshiftitercount, 
                    frac.w += xiscalestep_shift) {
                    uint16_t __far * columndata = (uint16_t __far *)(&(patch->columnofs[frac.h.intbits]));
                    column_t __far * postdata   = (column_t __far *)(((byte __far *) patch) + columndata[1]);
                    R_DrawMaskedColumnCallSpriteHigh(patch_segment + (columndata[0] >> 4), postdata);
                }
            }
        
        } else {

            for (xoffset = 0 ; xoffset < detailshiftitercount ; 
                xoffset++, 
                basespryscale+=vis->xiscale) {

                frac.w = basespryscale;
                dc_x = dc_x_base4 + xoffset;
                if (dc_x < vis->x1){
                    dc_x+=detailshiftitercount;
                    frac.w += xiscalestep_shift;
                }

                outp(SC_INDEX+1, quality_port_lookup[xoffset+detailshift.b.bytehigh]);

                for ( ; dc_x<=vis->x2 ; 
                    dc_x+=detailshiftitercount, 
                    frac.w += xiscalestep_shift) {

                    uint16_t __far * columndata = (uint16_t __far *)(&(patch->columnofs[frac.h.intbits]));
                    column_t __far * postdata   = (column_t __far *)(((byte __far *) patch) + columndata[1]);
                    R_DrawMaskedSpriteShadow(patch_segment + (columndata[0] >> 4), postdata);
                }
            }
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
	
	spritenum_t thingsprite = states[thing->stateNum].sprite;
	spriteframenum_t thingframe = states[thing->stateNum].frame;
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
    if (tz.h.intbits < MINZ_HIGHBITS) // (- sq: where does this come from)
        return;

        
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
    if (x1 > viewwidth)
        return;
    
    usedwidth = spritewidths[spriteindex];
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
//	vis->gzt = thing->z + spritetopoffset[lump];
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

        if (index >= MAXLIGHTSCALE) 
            index = MAXLIGHTSCALE-1;

        vis->colormap = *((int8_t __far*)MK_FP(scalelightfixed_segment, spritelights+index));
    }

	
}




//
// R_AddSprites
// During BSP traversal, this adds sprites by sector.
//

void __near R_AddSprites (sector_t __far* sec)
{
	THINKERREF				thingRef;
	int16_t                 lightnum;
 

    // BSP is traversed by subsector.
    // A sector might have been split into several
    //  subsectors during BSP building.
    // Thus we check whether its already added.
    

	if (sec->validcount == validcount)
        return;         
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
// R_DrawPSprite
//
void __near R_DrawPSprite (pspdef_t __near* psp, state_t statecopy, vissprite_t __near* vis){
    fixed_t_union           tx;
	int16_t                 x1;
	int16_t                 x2;
	int16_t                 spriteindex;
	int16_t                 usedwidth;
    boolean             flip;
	spriteframe_t __far*		spriteframes;
    fixed_t_union temp;


	// decide which patch to use
	spriteframes = (spriteframe_t __far*)&(spritedefs_bytes[sprites[statecopy.sprite].spriteframesOffset]);


    spriteindex = spriteframes[statecopy.frame & FF_FRAMEMASK].lump[0];
    flip = (boolean)spriteframes[statecopy.frame & FF_FRAMEMASK].flip[0];
    
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
    usedwidth = spritewidths[spriteindex];
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
    } else if (statecopy.frame & FF_FULLBRIGHT) {
        // full bright
        vis->colormap = 0;
    } else {
        // local light
        vis->colormap = *((int8_t __far*)MK_FP(scalelightfixed_segment, spritelights+MAXLIGHTSCALE-1));
    }

}

//
// R_DrawPlayerSprites
//
void __near R_DrawPlayerSprites (void){
	uint8_t i;
	pspdef_t __near*   psp;
	// clip to screen bounds
	mfloorclip = screenheightarray;
	mceilingclip = negonearray;

	for (i = 0, psp = player.psprites;
		i < NUMPSPRITES;
		i++, psp++) {

		if (psp->state) {
			R_DrawVisSprite(&player_vissprites[i]);
		}
	}
}

void __near R_PrepareMaskedPSprites(void) {
	uint8_t         i;
	uint8_t         lightnum;
	pspdef_t __near*   psp;
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

	// add all active psprites
	for (i = 0, psp = player.psprites;
		i < NUMPSPRITES;
		i++, psp++) {

		if (psp->state) {
			R_DrawPSprite(psp, r_cachedstatecopy[i], &player_vissprites[i]);
		}
	}
}

//
// R_SortVisSprites
//

#define VISSPRITE_UNSORTED_INDEX 255
#define VISSPRITE_SORTED_HEAD_INDEX 254

void __near R_SortVisSprites (void)
{
	int16_t                 i;
	int16_t                 count;
    uint8_t        ds;
    uint8_t        bestindex;
    vissprite_t __near*        best;
    vissprite_t         unsorted;
    fixed_t             bestscale;
    uint8_t     vsprsortedheadprev;

	memset(&unsorted, 0, sizeof(vissprite_t));

    count = vissprite_p;
        

    if (!count)
        return;
          
    for (ds=0 ; ds<count ; ds++) {
        vissprites[ds].next = ds+1;
    }

    unsorted.next = 0;
    (vissprites[vissprite_p-1]).next = VISSPRITE_UNSORTED_INDEX;
    
    // pull the vissprites out by scale
    vsprsortedheadfirst = vsprsortedheadprev = VISSPRITE_SORTED_HEAD_INDEX;
    for (i=0 ; i<count ; i++) {
        bestscale = MAXLONG;
        for (ds=unsorted.next ; ds!= VISSPRITE_UNSORTED_INDEX ; ds=vissprites[ds].next) {
           if (vissprites[ds].scale < bestscale) {
                bestscale = vissprites[ds].scale;
                bestindex = ds;
                best = &vissprites[ds];
            }
        }

        if (unsorted.next == bestindex){
            unsorted.next = best->next;
        } else {
            for (ds=unsorted.next ; ; ds=vissprites[ds].next) {
                if (vissprites[ds].next == bestindex) {
                    vissprites[ds].next = best->next;
                    break;
                }
            }
        }
       

        if (vsprsortedheadfirst == VISSPRITE_SORTED_HEAD_INDEX){
            // only on first iteration
            vsprsortedheadfirst = bestindex;
        } else {
            // dont set on first iteration
            vissprites[vsprsortedheadprev].next = bestindex;
        }

        best->next = VISSPRITE_SORTED_HEAD_INDEX;
        vsprsortedheadprev = bestindex;
    }
}





//
// R_DrawSprite
//

void __near R_DrawSprite (vissprite_t __near* spr)
{
    drawseg_t __far*          ds;
    int16_t               clipbot[SCREENWIDTH]; // could be uint8_t, need to change -2 special case
    int16_t               cliptop[SCREENWIDTH];
	int16_t                 x;
	int16_t                 r1;
	int16_t                 r2;
	int16_t                 silhouette;
	boolean				scalecheckpass, lowscalecheckpass;
    fixed_t_union temp;

	for (x = spr->x1; x <= spr->x2; x++) {
		clipbot[x] = cliptop[x] = -2;
	}

    // Scan drawsegs from end to start for obscuring segs.
    // The first drawseg that has a greater scale
    //  is the clip seg.
    for (ds=ds_p-1 ; ds > drawsegs_BASE ; ds--) {



		// determine if the drawseg obscures the sprite
		if ((ds->x1 > spr->x2)
            || (ds->x2 < spr->x1)
            || (!ds->silhouette
                && ds->maskedtexturecol == NULL_TEX_COL) ) {
			// this drawseg's x vals (cols) dont overlap the sprite at all can't cover
			continue;
        }
                        
        // checking relative scales - is this drawseg's wall approaching player as it goes to left or right?
		// i believe this is a check that can also tell if the wall is in front. 
		//   - scale is relative to distance to player.
		//   - if both sides of drawseg are further from to player than sprite (i.e. both wall's edge's scales are smaller than sprite scale)
		//
		if (ds->scale1 > ds->scale2) {
			scalecheckpass = ds->scale1 < spr->scale;
			lowscalecheckpass = ds->scale2 < spr->scale;
        } else {
			scalecheckpass = ds->scale2 < spr->scale;
			lowscalecheckpass = ds->scale1 < spr->scale;
        }

		if (scalecheckpass
            || ( lowscalecheckpass
		    // worst case scenario one side of wall is closer, have to manually check if sprite on the closer side of wall
            && !R_PointOnSegSide (spr->gx, spr->gy, ds->curseg) ) ) {
            
			// if drawseg is that of a masked texture then... 

			if (ds->maskedtexturecol != NULL_TEX_COL) {
				r1 = ds->x1 < spr->x1 ? spr->x1 : ds->x1;
				r2 = ds->x2 > spr->x2 ? spr->x2 : ds->x2;
				R_RenderMaskedSegRange(ds, r1, r2); // draws what is in front of the sprite (??)
			} 

			// seg is behind sprite, move on to next drawseg
            continue;                   
        }
		r1 = ds->x1 < spr->x1 ? spr->x1 : ds->x1;
		r2 = ds->x2 > spr->x2 ? spr->x2 : ds->x2;

        
        // clip this piece of the sprite
        silhouette = ds->silhouette;
        
    	SET_FIXED_UNION_FROM_SHORT_HEIGHT(temp, ds->bsilheight);
		if (ds->bsilheight < 0) {
		}
		if (spr->gz.w >= temp.w) {
			silhouette &= ~SIL_BOTTOM;
		}
    	SET_FIXED_UNION_FROM_SHORT_HEIGHT(temp, ds->tsilheight);
        
		if (spr->gzt.w <= temp.w) {
			silhouette &= ~SIL_TOP;
		}
        if (silhouette == 1) {
            // bottom sil
            for (x=r1 ; x<=r2 ; x++)
                if (clipbot[x] == -2)
                    clipbot[x] = *((int16_t __far *)MK_FP(openings_segment, ds->sprbottomclip_offset+(x*2))); 
        } else if (silhouette == 2) {
            // top sil
            for (x=r1 ; x<=r2 ; x++)
                if (cliptop[x] == -2)
                    cliptop[x] = *((int16_t __far *)MK_FP(openings_segment, ds->sprtopclip_offset+(x*2))); 
        } else if (silhouette == 3) {
            // both
            for (x=r1 ; x<=r2 ; x++) {
                if (clipbot[x] == -2)
                    clipbot[x] = *((int16_t __far *)MK_FP(openings_segment, ds->sprbottomclip_offset+(x*2))); 
                if (cliptop[x] == -2)
                    cliptop[x] = *((int16_t __far *)MK_FP(openings_segment, ds->sprtopclip_offset+(x*2))); 
            }
        }
                
    }
    
    // all clipping has been performed, so draw the sprite

    // check for unclipped columns
	for (x = spr->x1 ; x<=spr->x2 ; x++)
    {
		if (clipbot[x] == -2) {
			clipbot[x] = viewheight;
		}
		if (cliptop[x] == -2) {
			cliptop[x] = -1;
		}
    }
    
	mfloorclip = clipbot;
    mceilingclip = cliptop;
    R_DrawVisSprite (spr);
}




//
// R_DrawMasked
//
void __near R_DrawMasked (void) {
    uint8_t         spr;
    drawseg_t __far*          ds;
    
	R_SortVisSprites ();

    if (vissprite_p > 0) {
        // draw all vissprites back to front
        for (spr = vsprsortedheadfirst ;
             spr != VISSPRITE_SORTED_HEAD_INDEX ;
             spr=vissprites[spr].next) {
            R_DrawSprite (&vissprites[spr]);
        }
    }

    // render any remaining masked mid textures

	for (ds = ds_p - 1; ds > drawsegs_BASE; ds--) {
		if (ds->maskedtexturecol != NULL_TEX_COL) {
			R_RenderMaskedSegRange(ds, ds->x1, ds->x2);  // draws what is behind the sprites
		}
	}
    // draw the psprites on top of everything
    //  but does not draw on side views
	R_DrawPlayerSprites ();
}




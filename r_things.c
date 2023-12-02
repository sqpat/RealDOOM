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



#define MINZ                            (FRACUNIT*4)
#define BASEYCENTER                     100L



//
// Sprite rotation 0 is facing the viewer,
//  rotation 1 is one angle turn CLOCKWISE around the axis.
// This is not the same as the angle,
//  which increases counter clockwise (protractor).
// There was a lot of stuff grabbed wrong, so I changed it...
//
fixed_t         pspritescale;
fixed_t         pspriteiscale;

lighttable_t**  spritelights;

// constant arrays
//  used for psprite clipping and initializing clipping
int16_t           negonearray[SCREENWIDTH];
int16_t           screenheightarray[SCREENWIDTH];


//
// INITIALIZATION FUNCTIONS
//

// variables used to look up
//  and range check thing_t sprites patches
spritedef_t*	sprites;
int16_t             numsprites;


int8_t*           spritename;






//
// GAME FUNCTIONS
//
vissprite_t     vissprites[MAXVISSPRITES];
vissprite_t*    vissprite_p;


 
//
// R_ClearSprites
// Called at frame start.
//
void R_ClearSprites (void)
{
    vissprite_p = vissprites;
}
 
vissprite_t     overflowsprite;

 



//
// R_DrawMaskedColumn
// Used for sprites and masked mid textures.
// Masked means: partly transparent, i.e. stored
//  in posts/runs of opaque pixels.
//
int16_t*          mfloorclip;
int16_t*          mceilingclip;

fixed_t         spryscale;
fixed_t         sprtopscreen;

void R_DrawMaskedColumn (column_t* column) {
	
	fixed_t         topscreen;
	fixed_t         bottomscreen;
	fixed_t     basetexturemid;
	fixed_t_union     temp;
	temp.h.fracbits = 0;
    basetexturemid = dc_texturemid;
        
    for ( ; column->topdelta != 0xff ; )  {
        // calculate unclipped screen coordinates
        //  for post
        topscreen = sprtopscreen + spryscale*column->topdelta;
        bottomscreen = topscreen + spryscale*column->length;

		// todo add by 65535  ? dc_yl = topscreen.fracbits == 0 ? intbits : intbits+1
        dc_yl = (topscreen+FRACUNIT-1)>>FRACBITS;
        dc_yh = (bottomscreen-1)>>FRACBITS;
                
        if (dc_yh >= mfloorclip[dc_x])
            dc_yh = mfloorclip[dc_x]-1;
        if (dc_yl <= mceilingclip[dc_x])
            dc_yl = mceilingclip[dc_x]+1;

        if (dc_yl <= dc_yh) {
            dc_source = (byte *)column + 3;
			temp.h.intbits = column->topdelta;
            dc_texturemid = basetexturemid - temp.w;

			// dc_source = (byte *)column + 3 - column->topdelta;

            // Drawn by either R_DrawColumn
            //  or (SHADOW) R_DrawFuzzColumn.
			colfunc();
        }
        column = (column_t *)(  (byte *)column + column->length + 4);
    }
        
    dc_texturemid = basetexturemid;
}



//
// R_DrawVisSprite
//  mfloorclip and mceilingclip should also be set.
//
// NO LOCKED PAGES GOING IN
void
R_DrawVisSprite
( vissprite_t*          vis,
	int16_t                   x1,
	int16_t                   x2 )
{
    column_t*           column;
	int16_t             texturecolumn;
    fixed_t_union             frac;
    patch_t*            patch;
	MEMREF				patchRef;
        

    patchRef = W_CacheLumpNumEMS (vis->patch+firstspritelump, PU_CACHE);

    dc_colormap = vis->colormap;
    
    if (!dc_colormap) {
        // NULL colormap = shadow draw
        colfunc = fuzzcolfunc;
    }
        
    dc_iscale = labs(vis->xiscale)>>detailshift;
    dc_texturemid = vis->texturemid;
    frac.w = vis->startfrac;
    spryscale = vis->scale;
    sprtopscreen = centeryfrac - FixedMul(dc_texturemid,spryscale);
         
	patch = (patch_t*)Z_LoadBytesFromEMSWithOptions(patchRef, PAGE_LOCKED);
	for (dc_x=vis->x1 ; dc_x<=vis->x2 ; dc_x++, frac.w += vis->xiscale) {
		texturecolumn = (frac.h.intbits);
		column = (column_t *) ((byte *)patch + (patch->columnofs[texturecolumn]));
        R_DrawMaskedColumn (column);
		Z_RefIsActive(patchRef);
    }
	Z_SetUnlocked(patchRef);
    colfunc = basecolfunc;
}



//
// R_ProjectSprite
// Generates a vissprite for a thing
//  if it might be visible.
//
void R_ProjectSprite (mobj_t* thing)
{
    fixed_t             tr_x;
    fixed_t             tr_y;
    
    fixed_t             gxt;
    fixed_t             gyt;
    
    fixed_t             tx;
    fixed_t             tz;

    fixed_t             xscale;
    
	int16_t                 x1;
	int16_t                 x2;

	int16_t                 lump;
    
	uint8_t            rot;
    boolean             flip;
    
	int16_t                 index;

    vissprite_t*        vis;
    
    angle_t             ang;
    fixed_t             iscale;
	spriteframe_t*		spriteframes;
	
	spritenum_t thingsprite = states[thing->stateNum].sprite;
	spriteframenum_t thingframe = states[thing->stateNum].frame;

	fixed_t thingx = thing->x;
	fixed_t thingy = thing->y;
	fixed_t thingz = thing->z;
	int32_t thingflags = thing->flags;
	angle_t thingangle = thing->angle;
	MEMREF spritespriteframeRef;
	int8_t spritenumframes;
    fixed_t_union temp;
		
	// transform the origin point
    tr_x = thingx - viewx.w;
    tr_y = thingy - viewy.w;
        
    gxt = FixedMul(tr_x,viewcos); 
    gyt = -FixedMul(tr_y,viewsin);
    
    tz = gxt-gyt; 

    // thing is behind view plane?
    if (tz < MINZ)
        return;
    
    xscale = FixedDiv(projection, tz);
        
    gxt = -FixedMul(tr_x,viewsin); 
    gyt = FixedMul(tr_y,viewcos); 
    tx = -(gyt+gxt); 

    // too far off the side?
    if (labs(tx)>(tz<<2))
        return;

    // decide which patch to use for sprite relative to player
	spritespriteframeRef = sprites[thingsprite].spriteframesRef;
	spritenumframes = sprites[thingsprite].numframes;
	spriteframes = (spriteframe_t*)Z_LoadSpriteFromConventional(spritespriteframeRef);

    if (spriteframes[thingframe & FF_FRAMEMASK].rotate) {
        // choose a different rotation based on player view
		ang.w = R_PointToAngle (thingx, thingy);
		//todo make this not shift 29
        rot = (ang.w-thingangle.w+ (uint32_t)(ANG45/2)*9)>>29;
        lump = spriteframes[thingframe & FF_FRAMEMASK].lump[rot];
        flip = (boolean)spriteframes[thingframe & FF_FRAMEMASK].flip[rot];
    }
    else
    {
        // use single rotation for all views
        lump = spriteframes[thingframe & FF_FRAMEMASK].lump[0];
        flip = (boolean)spriteframes[thingframe & FF_FRAMEMASK].flip[0];
    }
    
    // calculate edges of the shape
    temp.h.fracbits = 0;
    temp.h.intbits = spriteoffsets[lump];
	tx -= temp.w;
    temp.w = (centerxfrac + FixedMul (tx,xscale) );
    x1 = temp.h.intbits;

    // off the right side?
    if (x1 > viewwidth)
        return;
    
    temp.h.fracbits = 0;
    temp.h.intbits = spritewidths[lump];

    tx +=  temp.w;
    temp.w = ((centerxfrac + FixedMul (tx,xscale) ));
    x2 = temp.h.intbits - 1;

	

    // off the left side
    if (x2 < 0)
        return;
    // store information in a vissprite

	if (vissprite_p == &vissprites[MAXVISSPRITES]) {
		vis = &overflowsprite;
	}
	vissprite_p++;
	vis = vissprite_p - 1;

	vis->mobjflags = thingflags;
    vis->scale = xscale<<detailshift;
    vis->gx = thingx;
    vis->gy = thingy;
    vis->gz = thingz;
    temp.h.fracbits = 0;
    temp.h.intbits = spritetopoffsets[lump];
	vis->gzt = vis->gz + temp.w;
//	vis->gzt = thing->z + spritetopoffset[lump];
    vis->texturemid = vis->gzt - viewz.w;
    vis->x1 = x1 < 0 ? 0 : x1;
    vis->x2 = x2 >= viewwidth ? viewwidth-1 : x2;       
    
	// todo does a quick  inverse function exist? considering this is fixed point
	iscale = FixedDiv (FRACUNIT, xscale);

    if (flip)
    {
        temp.h.fracbits = 0;
        temp.h.intbits = spritewidths[lump];
		vis->startfrac = temp.w-1;
        vis->xiscale = -iscale;
    }
    else
    {
        vis->startfrac = 0;
        vis->xiscale = iscale;
    }

    if (vis->x1 > x1)
        vis->startfrac += vis->xiscale*(vis->x1-x1);
    vis->patch = lump;
    
    // get light level
    if (thingflags & MF_SHADOW)
    {
        // shadow draw
        vis->colormap = NULL;
    }
    else if (fixedcolormap)
    {
        // fixed map
        vis->colormap = fixedcolormap;
    }
    else if (thingframe & FF_FULLBRIGHT)
    {
        // full bright
        vis->colormap = colormaps;
    }
    
    else
    {
        // diminished light
        index = xscale>>(LIGHTSCALESHIFT-detailshift);

        if (index >= MAXLIGHTSCALE) 
            index = MAXLIGHTSCALE-1;

        vis->colormap = spritelights[index];
    }

	
}




//
// R_AddSprites
// During BSP traversal, this adds sprites by sector.
//

void R_AddSprites (int16_t secnum)
{
    mobj_t*             thing;
	THINKERREF				thingRef;
	int32_t                 lightnum;
 

    // BSP is traversed by subsector.
    // A sector might have been split into several
    //  subsectors during BSP building.
    // Thus we check whether its already added.
    

	if (sectors[secnum].validcount == validcount)
        return;         
    // Well, now it will be done.
	(&sectors[secnum])->validcount = validcount;
        
    lightnum = (sectors[secnum].lightlevel >> LIGHTSEGSHIFT)+extralight;

	if (lightnum < 0) {
		spritelights = scalelight[0];
	} else if (lightnum >= LIGHTLEVELS) {
		spritelights = scalelight[LIGHTLEVELS - 1];
	} else {
		spritelights = scalelight[lightnum];
	}


    // Handle all things in sector.
	// todo, should we quit out early of drawing player sprite? matters for netplay maybe? if its self, shouldnt render and its a lot of extra traversal?
	for (thingRef = sectors[secnum].thinglistRef; thingRef; thingRef = thing->snextRef) {
		thing = (mobj_t*)&thinkerlist[thingRef].data;
		R_ProjectSprite(thing);
		 
	
	}





}

//
// R_DrawPSprite
//
void R_DrawPSprite (pspdef_t* psp)
{
    fixed_t             tx;
	int16_t                 x1;
	int16_t                 x2;
	int16_t                 lump;
    boolean             flip;
    vissprite_t*        vis;
    vissprite_t         avis;
	spriteframe_t*		spriteframes;
    fixed_t_union temp;

	// decide which patch to use

	spriteframes = (spriteframe_t*)Z_LoadSpriteFromConventional(sprites[psp->state->sprite].spriteframesRef);


    lump = spriteframes[psp->state->frame & FF_FRAMEMASK].lump[0];
    flip = (boolean)spriteframes[psp->state->frame & FF_FRAMEMASK].flip[0];
    
    // calculate edges of the shape
    tx = psp->sx-160*FRACUNIT;
        
    temp.h.fracbits = 0;
    temp.h.intbits = spriteoffsets[lump];
	tx -= temp.w;
    temp.w= (centerxfrac + FixedMul (tx,pspritescale) );
    x1 = temp.h.intbits;

    // off the right side
    if (x1 > viewwidth)
        return;         

    temp.h.fracbits = 0;
    temp.h.intbits = spritewidths[lump];
	tx +=  temp.w;
    temp.w = ((centerxfrac + FixedMul (tx, pspritescale) ) ) ;
    x2 = temp.h.intbits - 1;

    // off the left side
    if (x2 < 0)
        return;
    
    // store information in a vissprite
    vis = &avis;
    vis->mobjflags = 0;
    temp.h.fracbits = 0;
    temp.h.intbits = spritetopoffsets[lump];
	vis->texturemid = (BASEYCENTER<<FRACBITS)+FRACUNIT/2-(psp->sy-temp.w);
    vis->x1 = x1 < 0 ? 0 : x1;
    vis->x2 = x2 >= viewwidth ? viewwidth-1 : x2;       
    vis->scale = pspritescale<<detailshift;
    
    if (flip)
    {
        vis->xiscale = -pspriteiscale;
        temp.h.fracbits = 0;
        temp.h.intbits = spritewidths[lump];
		vis->startfrac = temp.w - 1;
    }
    else
    {
        vis->xiscale = pspriteiscale;
        vis->startfrac = 0;
    }
    
    if (vis->x1 > x1)
        vis->startfrac += vis->xiscale*(vis->x1-x1);

    vis->patch = lump;

    if (player.powers[pw_invisibility] > 4*32
        || player.powers[pw_invisibility] & 8)
    {
        // shadow draw
        vis->colormap = NULL;
    }
    else if (fixedcolormap)
    {
        // fixed color
        vis->colormap = fixedcolormap;
    }
    else if (psp->state->frame & FF_FULLBRIGHT)
    {
        // full bright
        vis->colormap = colormaps;
    }
    else
    {
        // local light
        vis->colormap = spritelights[MAXLIGHTSCALE-1];
    }

    R_DrawVisSprite (vis, vis->x1, vis->x2);
}



//
// R_DrawPlayerSprites
//
void R_DrawPlayerSprites (void)
{
	uint8_t         i;
	uint8_t         lightnum;
    pspdef_t*   psp;
    // get light level
    lightnum = (sectors[playerMobj->secnum].lightlevel >> LIGHTSEGSHIFT) +extralight;


//    if (lightnum < 0)          
// not sure if this hack is necessary.. since its unsigned we loop around if its below 0 
    if (lightnum > 240)          
        spritelights = scalelight[0];
    else if (lightnum >= LIGHTLEVELS)
        spritelights = scalelight[LIGHTLEVELS-1];
    else
        spritelights = scalelight[lightnum];
    
    // clip to screen bounds
    mfloorclip = screenheightarray;
    mceilingclip = negonearray;
    
    // add all active psprites
    for (i=0, psp= player.psprites;
         i<NUMPSPRITES;
         i++,psp++)
    {
        if (psp->state)
            R_DrawPSprite (psp);
    }
}




//
// R_SortVisSprites
//
vissprite_t     vsprsortedhead;


void R_SortVisSprites (void)
{
	int16_t                 i;
	int16_t                 count;
    vissprite_t*        ds;
    vissprite_t*        best;
    vissprite_t         unsorted;
    fixed_t             bestscale;

    count = vissprite_p - vissprites;
        

    if (!count)
        return;
          
	unsorted.next = unsorted.prev = &unsorted;

    for (ds=vissprites ; ds<vissprite_p ; ds++)
    {
        ds->next = ds+1;
        ds->prev = ds-1;
    }
    
    vissprites[0].prev = &unsorted;
    unsorted.next = &vissprites[0];
    (vissprite_p-1)->next = &unsorted;
    unsorted.prev = vissprite_p-1;
    
    // pull the vissprites out by scale
    //best = 0;         // shut up the compiler warning
    vsprsortedhead.next = vsprsortedhead.prev = &vsprsortedhead;
    for (i=0 ; i<count ; i++)
    {
        bestscale = MAXLONG;
        for (ds=unsorted.next ; ds!= &unsorted ; ds=ds->next)
        {
            if (ds->scale < bestscale)
            {
                bestscale = ds->scale;
                best = ds;
            }
        }
        best->next->prev = best->prev;
        best->prev->next = best->next;
        best->next = &vsprsortedhead;
        best->prev = vsprsortedhead.prev;
        vsprsortedhead.prev->next = best;
        vsprsortedhead.prev = best;
    }
}



//
// R_DrawSprite
//
// NO LOCKED PAGES GOING IN
void R_DrawSprite (vissprite_t* spr)
{
    drawseg_t*          ds;
    int16_t               clipbot[SCREENWIDTH];
    int16_t               cliptop[SCREENWIDTH];
	int16_t                 x;
	int16_t                 r1;
	int16_t                 r2;
    fixed_t             scale;
    fixed_t             lowscale;
	int16_t                 silhouette;
    fixed_t_union temp;

    for (x = spr->x1 ; x<=spr->x2 ; x++)
        clipbot[x] = cliptop[x] = -2;
    
    // Scan drawsegs from end to start for obscuring segs.
    // The first drawseg that has a greater scale
    //  is the clip seg.
    for (ds=ds_p-1 ; ds >= drawsegs ; ds--)
    {
        // determine if the drawseg obscures the sprite
        if (ds->x1 > spr->x2
            || ds->x2 < spr->x1
            || (!ds->silhouette
                && !ds->maskedtexturecol) )
        {
            // does not cover sprite
            continue;
        }
                        
        r1 = ds->x1 < spr->x1 ? spr->x1 : ds->x1;
        r2 = ds->x2 > spr->x2 ? spr->x2 : ds->x2;

        if (ds->scale1 > ds->scale2)
        {
            lowscale = ds->scale2;
            scale = ds->scale1;
        }
        else
        {
            lowscale = ds->scale1;
            scale = ds->scale2;
        }
                
		if (scale < spr->scale
            || ( lowscale < spr->scale
                 && !R_PointOnSegSide (spr->gx, spr->gy, segs[ds->curlinenum].v1Offset, segs[ds->curlinenum].v2Offset&SEG_V2_OFFSET_MASK) ) )
        {
            // masked mid texture?
            if (ds->maskedtexturecol)   
                R_RenderMaskedSegRange (ds, r1, r2);
            // seg is behind sprite
            continue;                   
        }

        
        // clip this piece of the sprite
        silhouette = ds->silhouette;
        
        // todo in the MIN_SHORT case do we have to extend the FFFF?
        temp.h.fracbits = 0;
        // temp.h.intbits =  ds->bsilheight >> SHORTFLOORBITS;
    	SET_FIXED_UNION_FROM_SHORT_HEIGHT(temp, ds->bsilheight);
        if (spr->gz >= temp.w)
            silhouette &= ~SIL_BOTTOM;

        // temp.h.intbits =  ds->tsilheight >> SHORTFLOORBITS;
    	SET_FIXED_UNION_FROM_SHORT_HEIGHT(temp, ds->tsilheight);
        
        if (spr->gzt <= temp.w)
            silhouette &= ~SIL_TOP;
                        
        if (silhouette == 1)
        {
            // bottom sil
            for (x=r1 ; x<=r2 ; x++)
                if (clipbot[x] == -2)
                    clipbot[x] = ds->sprbottomclip[x];
        }
        else if (silhouette == 2)
        {
            // top sil
            for (x=r1 ; x<=r2 ; x++)
                if (cliptop[x] == -2)
                    cliptop[x] = ds->sprtopclip[x];
        }
        else if (silhouette == 3)
        {
            // both
            for (x=r1 ; x<=r2 ; x++)
            {
                if (clipbot[x] == -2)
                    clipbot[x] = ds->sprbottomclip[x];
                if (cliptop[x] == -2)
                    cliptop[x] = ds->sprtopclip[x];
            }
        }
                
    }
    
    // all clipping has been performed, so draw the sprite

    // check for unclipped columns
    for (x = spr->x1 ; x<=spr->x2 ; x++)
    {
        if (clipbot[x] == -2)           
            clipbot[x] = viewheight;

        if (cliptop[x] == -2)
            cliptop[x] = -1;
    }
                
    mfloorclip = clipbot;
    mceilingclip = cliptop;
    R_DrawVisSprite (spr, spr->x1, spr->x2);
}




//
// R_DrawMasked
//
// NO LOCKED PAGES GOING IN
void R_DrawMasked (void)
{
    vissprite_t*        spr;
    drawseg_t*          ds;
        
    R_SortVisSprites ();

    if (vissprite_p > vissprites)
    {
        // draw all vissprites back to front
        for (spr = vsprsortedhead.next ;
             spr != &vsprsortedhead ;
             spr=spr->next)
        {
            
            R_DrawSprite (spr);
        }
    }
    
    // render any remaining masked mid textures

	for (ds=ds_p-1 ; ds >= drawsegs ; ds--)
        if (ds->maskedtexturecol)
            R_RenderMaskedSegRange (ds, ds->x1, ds->x2);
    
    // draw the psprites on top of everything
    //  but does not draw on side views
    R_DrawPlayerSprites ();
}




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

// eventually, DS will be fixed to 0x3C00 or so. Then, these will all 
// become casted #define variable locations rather than linked variables.
// this will make it easier to build collections of function binaries, 
// export them to file and load them at runtime into EMS memory locations

#ifndef __M_NEAR_H__
#define __M_NEAR_H__


#include "dutils.h"

#include "am_map.h"
#include "m_memory.h"
#include "m_misc.h"
#include "d_event.h"
#include "d_ticcmd.h"
#include "st_lib.h"
#include "st_stuff.h"
#include "hu_lib.h"
#include "dmx.h"
#include "m_menu.h"
#include "wi_stuff.h"
#include "p_spec.h"
#include "p_local.h"
#include "z_zone.h"
#include "d_englsh.h"
#include "sounds.h"
#include "s_sound.h"

#define SAVESTRINGSIZE        24u



#define NUM_CACHE_LUMPS 4

#define NUM_TEXTURE_L1_CACHE_PAGES 8
#define NUM_SPRITE_L1_CACHE_PAGES 4
#define NUM_FLAT_L1_CACHE_PAGES 4



#define NUMEPISODES_FOR_ANIMS	3
#define NUMMAPS		9

#define NUM_QUITMESSAGES   8
 
//
// Globally visible constants.
//
#define HU_FONTSTART	'!'	// the first font characters
#define HU_FONTEND	'_'	// the last font characters

// Calculate # of glyphs in font.
#define HU_FONTSIZE	(HU_FONTEND - HU_FONTSTART + 1)	

#define ST_NUMPAINFACES         5
#define ST_NUMSTRAIGHTFACES     3
#define ST_NUMTURNFACES         2
#define ST_NUMSPECIALFACES              3
#define ST_NUMEXTRAFACES                2

#define ST_FACESTRIDE \
          (ST_NUMSTRAIGHTFACES+ST_NUMTURNFACES+ST_NUMSPECIALFACES)
#define ST_NUMFACES \
          (ST_FACESTRIDE*ST_NUMPAINFACES+ST_NUMEXTRAFACES)

#define NEAR_SEGMENT 0x3C00
#define _NULL_OFFSET 0x30
 

#define segloopnextlookup				  (((int16_t __near*)                (_NULL_OFFSET + 0x0000)))
#define seglooptexrepeat				  (((uint8_t __near*)                (_NULL_OFFSET + 0x0004)))
#define maskedtexrepeat                   (*((int16_t __near*)               (_NULL_OFFSET + 0x0006)))
#define segloopcachedsegment			  (((segment_t __near*)              (_NULL_OFFSET + 0x0008)))
#define segloopheightvalcache			  (((uint8_t __near*)                (_NULL_OFFSET + 0x000C)))



// 0E-0F free


//spanfunc_prt[4]
#define spanfunc_prt                    ((int16_t __near *)                  (_NULL_OFFSET + 0x0010))
//spanfunc_destview_offset[4]
#define spanfunc_destview_offset        ((uint16_t __near *)                 (_NULL_OFFSET + 0x0018))
//spanfunc_inner_loop_count[4]
#define spanfunc_inner_loop_count       ((int8_t __near *)                   (_NULL_OFFSET + 0x0020))
//spanfunc_outp[4]
#define spanfunc_outp                   ((uint8_t __near *)                  (_NULL_OFFSET + 0x0024))

// 28 to 30 unused

#define quality_port_lookup             ((uint8_t __near *)                  (_NULL_OFFSET + 0x0030))
// 3C to 47 free
#define jump_mult_table_3               ((uint8_t __near *)                  (_NULL_OFFSET + 0x0048))


#define dc_x                            (*((int16_t __near*)                 (_NULL_OFFSET + 0x0050)))

// end of stuff that can be used effectively in bx+xx addressing
#define lastopening                     (*((uint16_t    __near*)             (_NULL_OFFSET + 0x0052)))

#define planezlight                     (*(uint8_t __far * __near *)         (_NULL_OFFSET + 0x0054))
#define caststate                       (*((state_t __far* __near*)          (_NULL_OFFSET + 0x0058)))
#define basexscale                      (*((fixed_t __near *)                (_NULL_OFFSET + 0x005C)))
#define baseyscale                      (*((fixed_t __near *)                (_NULL_OFFSET + 0x0060)))
#define viewx                           (*((fixed_t_union __near *)          (_NULL_OFFSET + 0x0064)))
#define viewy                           (*((fixed_t_union __near *)          (_NULL_OFFSET + 0x0068)))
#define viewz                           (*((fixed_t_union __near *)          (_NULL_OFFSET + 0x006C)))
#define centerx                         (*((int16_t __near *)                (_NULL_OFFSET + 0x0070)))
#define centery                         (*((int16_t __near *)                (_NULL_OFFSET + 0x0072)))
#define centeryfrac_shiftright4         (*((fixed_t_union __near *)          (_NULL_OFFSET + 0x0074)))
#define viewangle                       (*((angle_t __near *)                (_NULL_OFFSET + 0x0078)))
#define viewz_shortheight               (*((short_height_t __near *)         (_NULL_OFFSET + 0x007C)))
#define screen_segments                 ((segment_t __near *)                (_NULL_OFFSET + 0x007E))


#define maskedtexture                   (*((boolean __near*)                 (_NULL_OFFSET + 0x0088)))
//#define MAXSPECIALCROSS		8
//extern int16_t		spechit[MAXSPECIALCROSS];
#define spechit                         (((int16_t  __near*)                 (_NULL_OFFSET + 0x008A)))
#define bombsource                      (*((mobj_t  __near* __near*)         (_NULL_OFFSET + 0x009A)))
#define bombspot                        (*((mobj_t  __near* __near*)         (_NULL_OFFSET + 0x009C)))
#define bombdamage                      (*((int16_t  __near*)                (_NULL_OFFSET + 0x009E)))
#define bombspot_pos                    (*((mobj_pos_t  __far* __near*)      (_NULL_OFFSET + 0x00A0)))

#define spryscale                       (*((fixed_t_union __near *)          (_NULL_OFFSET + 0x00A4)))
#define sprtopscreen                    (*((fixed_t_union __near *)          (_NULL_OFFSET + 0x00A8)))
#define player_ptr                      (*((player_t __near* _near*)         (_NULL_OFFSET + 0x00AC)))
#define pendingmusicenum                (*((musicenum_t _near*)              (_NULL_OFFSET + 0x00AE)))
#define pendingmusicenumlooping         (*((boolean _near*)              	 (_NULL_OFFSET + 0x00AF)))
#define dc_yl                           (*((int16_t __near*)                 (_NULL_OFFSET + 0x00B0)))
#define dc_yh                           (*((int16_t __near*)                 (_NULL_OFFSET + 0x00B2)))
#define snd_MusicDevice				    (*((uint8_t __near*)                 (_NULL_OFFSET + 0x00B4)))
#define is_ultimate                     (*(boolean __near *)                 (_NULL_OFFSET + 0x00B5))
#define firstspritelump                 (*(int16_t  __near *)                (_NULL_OFFSET + 0x00B6))
#define finaletext                      (*((int16_t __near*)                 (_NULL_OFFSET + 0x00B8)))
#define finalecount                     (*((int16_t __near*)                 (_NULL_OFFSET + 0x00BA)))
#define finalestage                     (*((int16_t __near*)                 (_NULL_OFFSET + 0x00BC)))
#define finale_laststage                (*((int8_t __near*)                  (_NULL_OFFSET + 0x00BE)))
#define playingstate	                (*((uint8_t __near*)                 (_NULL_OFFSET + 0x00BF)))
#define mfloorclip                      (*(int16_t __far * __near *)         (_NULL_OFFSET + 0x00C0))
#define mfloorclip_offset               (*(int16_t __near *)                 (_NULL_OFFSET + 0x00C0))
#define mfloorclip_segment              (*(segment_t __near *)               (_NULL_OFFSET + 0x00C2))
#define mceilingclip                    (*(int16_t __far * __near *)         (_NULL_OFFSET + 0x00C4))
#define mceilingclip_offset             (*(int16_t __near *)                 (_NULL_OFFSET + 0x00C4))
#define mceilingclip_segment            (*(segment_t __near *)               (_NULL_OFFSET + 0x00C6))

#define viletryx                        (*((fixed_t_union __near*)           (_NULL_OFFSET + 0x00CC)))
#define viletryy                        (*((fixed_t_union __near*)           (_NULL_OFFSET + 0x00D0)))
#define viewangle_shiftright1           (*((uint16_t __near *)               (_NULL_OFFSET + 0x00D4)))
#define skipdirectdraws                 (*(uint8_t __near *)                 (_NULL_OFFSET + 0x00D6))
#define snd_SfxDevice                   (*(uint8_t __near *)                 (_NULL_OFFSET + 0x00D7))
#define ds_source_segment               (*((byte __far* __near*)             (_NULL_OFFSET + 0x00D8)))

#define currentscreen                   (*(byte __far * __near *)            (_NULL_OFFSET + 0x00DC))
#define destview                        (*(byte __far * __near *)            (_NULL_OFFSET + 0x00E0))
#define destscreen                      (*((fixed_t_union __near *)          (_NULL_OFFSET + 0x00E4)))
#define tantoangle_segment              (*((segment_t  __near*)              (_NULL_OFFSET + 0x00E8)))
#define spanfunc_jump_segment_storage   (*((segment_t __near*)               (_NULL_OFFSET + 0x00EA)))


#define validcount_global	            (*(int16_t __near *)                 (_NULL_OFFSET + 0x00F4))
#define firstpatch                      (*(int16_t  __near *)                (_NULL_OFFSET + 0x00F6))
#define numbraintargets                 (*(int16_t __near *)                 (_NULL_OFFSET + 0x00F8))
#define braintargeton                   (*(int16_t __near *)                 (_NULL_OFFSET + 0x00FA))
#define brainspit_easy                  (*(boolean __near *)                 (_NULL_OFFSET + 0x00FC))
// If "floatok" true, move would be ok
// if within "tmfloorz - tmceilingz".
#define floatok                         (*(boolean __near *)                 (_NULL_OFFSET + 0x00FD))
#define corpsehitRef                    (*(THINKERREF __near *)              (_NULL_OFFSET + 0x00FE))
// unused apparently
//#define vileobj                         (*(mobj_t __near * __near *)         (_NULL_OFFSET + 0x0100))

#define EMS_PAGE                 	    (*((segment_t __near*)               (_NULL_OFFSET + 0x0102)))
#define viewangle_shiftright3           (*((fineangle_t __near*)             (_NULL_OFFSET + 0x0104)))
// 108 is constant
#define dc_source_segment               (*((segment_t __near*)               (_NULL_OFFSET + 0x010A)))
#define ds_y                            (*((int16_t __near*)                 (_NULL_OFFSET + 0x010C)))
// 10E is constant
#define stored_ds                       (*((uint16_t __near*)                (_NULL_OFFSET + 0x0110)))

#define cachedheight_segment_storage    (*((segment_t __near*)               (_NULL_OFFSET + 0x0112)))
#define distscale_segment_storage       (*((segment_t __near*)               (_NULL_OFFSET + 0x0114)))
#define cacheddistance_segment_storage  (*((segment_t __near*)               (_NULL_OFFSET + 0x0116)))
#define cachedxstep_segment_storage     (*((segment_t __near*)               (_NULL_OFFSET + 0x0118)))
#define cachedystep_segment_storage     (*((segment_t __near*)               (_NULL_OFFSET + 0x011A)))
#define pspriteiscale                   (*((fixed_t   __near*)               (_NULL_OFFSET + 0x011C)))

//#define MULT_256                        (((uint16_t   __near*)               (_NULL_OFFSET + 0x0120)))

#define tmflags1                        (*((int16_t __near*)                 (_NULL_OFFSET + 0x0120)))
#define tmfloorz                        (*((short_height_t __near*)          (_NULL_OFFSET + 0x0122)))
#define tmceilingz                      (*((short_height_t __near*)          (_NULL_OFFSET + 0x0124)))
#define tmdropoffz                      (*((short_height_t __near*)          (_NULL_OFFSET + 0x0126)))

#define MULT_4096                       (((uint16_t   __near*)               (_NULL_OFFSET + 0x0128)))
// todo unused i think
//#define FLAT_CACHE_PAGE                 (((uint16_t   __near*)               (_NULL_OFFSET + 0x0130)))
#define visplanelookupsegments          (((segment_t   __near*)              (_NULL_OFFSET + 0x0138)))

#define firstflat                       (*((int16_t    __near*)              (_NULL_OFFSET + 0x013E)))


#define castattacking                   (*((int8_t __near*)                  (_NULL_OFFSET + 0x0140)))
#define castdeath                       (*((int8_t __near*)                  (_NULL_OFFSET + 0x0141)))
#define castonmelee                     (*((int8_t __near*)                  (_NULL_OFFSET + 0x0142)))
#define castframes                      (*((int8_t __near*)                  (_NULL_OFFSET + 0x0143)))
#define casttics                        (*((int8_t __near*)                  (_NULL_OFFSET + 0x0144)))
#define castnum                         (*((int8_t __near*)                  (_NULL_OFFSET + 0x0145)))
#define finaleflat                      (*((int16_t __near*)                 (_NULL_OFFSET + 0x0146)))
// 147 free
#define FixedMul2432_addr               (*((uint32_t  __near*)               (_NULL_OFFSET + 0x0148)))
#define tmthing_pos                     (*((mobj_pos_t  __far __near*)       (_NULL_OFFSET + 0x014C)))
#define trace                           (*((divline_t __near*)               (_NULL_OFFSET + 0x0150)))

#define currentflatpage                 (((int8_t    __near*)                (_NULL_OFFSET + 0x0160)))
#define lastflatcacheindicesused        (((int8_t    __near*)                (_NULL_OFFSET + 0x0164)))
#define skyflatnum                      (*((uint8_t    __near*)              (_NULL_OFFSET + 0x0168)))
#define extralight                      (*((uint8_t    __near*)              (_NULL_OFFSET + 0x0169)))
#define visplanedirty                   (*((int8_t    __near*)               (_NULL_OFFSET + 0x016A)))
#define screenblocks                    (*((uint8_t    __near*)              (_NULL_OFFSET + 0x016B)))
#define lastvisplane                    (*((int16_t    __near*)              (_NULL_OFFSET + 0x016C)))
#define hudneedsupdate                  (*((uint8_t    __near*)              (_NULL_OFFSET + 0x016E)))
#define gamestate                       (*((gamestate_t __near*)             (_NULL_OFFSET + 0x016F)))


// 6-16 bytes... space it out in case of size growth


#define tmx                             (*((fixed_t_union __near*)           (_NULL_OFFSET + 0x0170)))
#define tmy                             (*((fixed_t_union __near*)           (_NULL_OFFSET + 0x0174)))
#define tmxmove                         (*((fixed_t_union __near*)           (_NULL_OFFSET + 0x0178)))
#define tmymove                         (*((fixed_t_union __near*)           (_NULL_OFFSET + 0x017C)))



// these are far pointers to functions..
#define Z_QuickMapVisplanePage_addr     (*((uint32_t  __near*)               (_NULL_OFFSET + 0x0180)))
//#define R_EvictFlatCacheEMSPage_addr    (*((uint32_t  __near*)               (_NULL_OFFSET + 0x0184)))
#define Z_QuickMapFlatPage_addr         (*((uint32_t  __near*)               (_NULL_OFFSET + 0x0188)))
#define R_GetPatchTexture_addr   		(*((uint32_t  __near*)               (_NULL_OFFSET + 0x018C)))
#define W_CacheLumpNumDirect_addr       (*((uint32_t  __near*)               (_NULL_OFFSET + 0x0190)))
#define floorplaneindex                 (*((int16_t    __near*)              (_NULL_OFFSET + 0x0194)))

#define viewwidth                       (*((int16_t    __near*)              (_NULL_OFFSET + 0x0198)))
#define viewheight                      (*((int16_t    __near*)              (_NULL_OFFSET + 0x019A)))
#define ceiltop                         (*((byte  __far* __near*)            (_NULL_OFFSET + 0x019C)))
#define floortop                        (*((byte  __far* __near*)            (_NULL_OFFSET + 0x01A0)))

#define frontsector                     (*((sector_t __far*  __near*)        (_NULL_OFFSET + 0x01A4)))
#define backsector                      (*((sector_t __far*  __near*)        (_NULL_OFFSET + 0x01A8)))
#define backsector_offset               (*((int16_t  __near*)                (_NULL_OFFSET + 0x01A8)))
#define playingtime		                (*((uint32_t  __near*)               (_NULL_OFFSET + 0x01AC)))

#define active_visplanes                (((int8_t    __near*)                (_NULL_OFFSET + 0x01B0)))
#define wipegamestate                   (*((gamestate_t __near*)             (_NULL_OFFSET + 0x01B5)))
#define visplane_offset                 (((uint16_t    __near*)              (_NULL_OFFSET + 0x01B6)))


#define dirtybox                        (((int16_t    __near*)               (_NULL_OFFSET + 0x01E8)))
#define ticcount                        (*((volatile uint32_t  __near*)      (_NULL_OFFSET + 0x01F0)))

#define Z_QuickMapPhysics_addr          (*((uint32_t  __near*)               (_NULL_OFFSET + 0x01F4)))
#define Z_QuickMapWipe_addr             (*((uint32_t  __near*)               (_NULL_OFFSET + 0x01F8)))
#define Z_QuickMapScratch_5000_addr     (*((uint32_t  __near*)               (_NULL_OFFSET + 0x01FC)))
#define M_Random_addr                   (*((uint32_t  __near*)               (_NULL_OFFSET + 0x0200)))
#define I_UpdateNoBlit_addr             (*((uint32_t  __near*)               (_NULL_OFFSET + 0x0204)))
#define I_FinishUpdate_addr             (*((uint32_t  __near*)               (_NULL_OFFSET + 0x0208)))
#define V_MarkRect_addr                 (*((uint32_t  __near*)               (_NULL_OFFSET + 0x020C)))
#define M_Drawer_addr                   (*((uint32_t  __near*)               (_NULL_OFFSET + 0x0210)))

#define wipeduration                    (*((uint16_t  __near*)               (_NULL_OFFSET + 0x0214)))
// uses high byte for quick 0
#define detailshift2minus               (*((uint8_t __near*)                 (_NULL_OFFSET + 0x0216)))
// uses high word for quick segment read
#define maskedheaderpixeolfs            (*((int16_t  __near*)                (_NULL_OFFSET + 0x0218)))

#define maskedtexturecol                (*((uint16_t  __far* __near*)        (_NULL_OFFSET + 0x021C)))
#define maskedtexturecol_offset         (*((int16_t  __near*)                (_NULL_OFFSET + 0x021C)))
#define masked_headers                  (((masked_header_t  __near*)         (_NULL_OFFSET + 0x0220)))
#define curseg                          (*((int16_t  __near*)                (_NULL_OFFSET + 0x0280)))
#define curseg_render                   (*((seg_render_t  __near* __near*)   (_NULL_OFFSET + 0x0282)))
#define save_p                          (*((byte  __far* __near*)            (_NULL_OFFSET + 0x0284)))

#define maskednextlookup                (*((int16_t __near*)                 (_NULL_OFFSET + 0x0288)))
#define maskedprevlookup                (*((int16_t __near*)                 (_NULL_OFFSET + 0x028A)))
#define tmthing                         (*((mobj_t __near*)                  (_NULL_OFFSET + 0x028C)))
#define maskedcachedbasecol             (*((int16_t __near*)                 (_NULL_OFFSET + 0x028E)))
#define maskedcachedsegment             (*((segment_t __near*)               (_NULL_OFFSET + 0x0290)))
#define maskedheightvalcache            (*((uint8_t __near*)                 (_NULL_OFFSET + 0x0292)))
#define vsprsortedheadfirst             (*((uint8_t __near*)                 (_NULL_OFFSET + 0x0293)))
#define lastvisspritesegment            (*((segment_t __near*)               (_NULL_OFFSET + 0x0294)))
#define lastvisspritesegment2           (*((segment_t __near*)               (_NULL_OFFSET + 0x0296)))
#define lastvisspritepatch              (*((int16_t __near*)                 (_NULL_OFFSET + 0x0298)))
#define lastvisspritepatch2             (*((int16_t __near*)                 (_NULL_OFFSET + 0x029A)))
#define ds_p                            (*((drawseg_t __far* __near*)        (_NULL_OFFSET + 0x029C)))
// 0x10 in length
#define olddb                           ((int16_t __near *)                  (_NULL_OFFSET + 0x02A0))
// 0 = high, 1 = low, = 2 potato
#define detailshift                     (*((int16_t_union __near*)           (_NULL_OFFSET + 0x02B0)))
#define detailshiftitercount            (*((uint8_t __near*)                 (_NULL_OFFSET + 0x02B2)))
#define detailshiftandval               (*((uint16_t __near*)                (_NULL_OFFSET + 0x02B4)))

#define ceilphyspage                    (*((int8_t __near*)                  (_NULL_OFFSET + 0x02B6)))
#define floorphyspage                   (*((int8_t __near*)                  (_NULL_OFFSET + 0x02B7)))
#define gameaction                      (*((gameaction_t __near*)            (_NULL_OFFSET + 0x02B8)))
#define viewactive                      (*((boolean __near*)                 (_NULL_OFFSET + 0x02B9)))
#define automapactive                   (*((boolean __near*)                 (_NULL_OFFSET + 0x02BA)))
#define commercial                      (*((boolean __near*)                 (_NULL_OFFSET + 0x02BB)))
#define registered                      (*((boolean __near*)                 (_NULL_OFFSET + 0x02BC)))
#define shareware                       (*((boolean __near*)                 (_NULL_OFFSET + 0x02BD)))
#define ds_colormap_index               (*((uint8_t __near*)                 (_NULL_OFFSET + 0x02BE)))
#define fixedcolormap                   (*((uint8_t __near*)                 (_NULL_OFFSET + 0x02BF)))

// more far pointers to functions... once they are in ASM-fixed locations, they should be callable normally
#define FixedMul_addr                   (*((uint32_t  __near*)               (_NULL_OFFSET + 0x02C0)))
#define FixedDiv_addr	                (*((uint32_t  __near*)               (_NULL_OFFSET + 0x02C4)))
#define FastDiv3232_addr                (*((uint32_t  __near*)               (_NULL_OFFSET + 0x02C8)))
#define R_GetCompositeTexture_addr   (*((uint32_t  __near*)               (_NULL_OFFSET + 0x02CC)))

#define colfunc_call_lookup             (((uint32_t  __near*)                (_NULL_OFFSET + 0x02D0)))
#define R_GetSpriteTexture_addr           (*((uint32_t  __near*)               (_NULL_OFFSET + 0x0354)))
// 12 bytes each. two for 24.
#define psprites                        (((pspdef_t __near*)                 (_NULL_OFFSET + 0x0358))) 
#define vga_read_port_lookup            (((uint16_t __near*)                 (_NULL_OFFSET + 0x0370)))

#define vissprite_p                     (*((int16_t __near*)                 (_NULL_OFFSET + 0x0388)))
#define cachedbyteheight                (*((uint8_t __near*)                 (_NULL_OFFSET + 0x038A)))
// dont use this byte!!! its always 0 on purpose.
#define currentMusPage					(*((uint8_t __near*)                 (_NULL_OFFSET + 0x038C)))
#define snd_MusicVolume                 (*((uint8_t __near*)                 (_NULL_OFFSET + 0x038D)))
#define gameepisode                     (*((int8_t __near*)                  (_NULL_OFFSET + 0x038E)))
#define gamemap                         (*((int8_t __near*)                  (_NULL_OFFSET + 0x038F)))
#define savedescription                 (((int8_t    __near*)                (_NULL_OFFSET + 0x0390)))
#define demoname                        (((int8_t    __near*)                (_NULL_OFFSET + 0x03B0)))




#define colfunc_masked_call_lookup      (((uint32_t  __near*)                (_NULL_OFFSET + 0x03D0)))

#define ems_backfill_page_order         (((int8_t    __near*)                (_NULL_OFFSET + 0x0454)))
#define movedirangles                   (((uint16_t  __near*)                (_NULL_OFFSET + 0x0470)))
#define braintargets                    (((THINKERREF __near*)               (_NULL_OFFSET + 0x0480)))


#define tmbbox                          (((fixed_t_union __near*)            (_NULL_OFFSET + 0x04C0)))



#define spanfunc_call_table             (((uint32_t  __near*)                (_NULL_OFFSET + 0x04D0)))

#define V_DrawPatch_addr                  (*((uint32_t  __near*)             (_NULL_OFFSET + 0x0554)))
#define locallib_toupper_addr             (*((uint32_t  __near*)             (_NULL_OFFSET + 0x0558)))
#define S_ChangeMusic_addr                (*((uint32_t  __near*)             (_NULL_OFFSET + 0x055C)))
#define V_DrawFullscreenPatch_addr        (*((uint32_t  __near*)             (_NULL_OFFSET + 0x0560)))
#define getStringByIndex_addr             (*((uint32_t  __near*)             (_NULL_OFFSET + 0x0564)))
#define locallib_strlen_addr              (*((uint32_t  __near*)             (_NULL_OFFSET + 0x0568)))
#define Z_QuickMapStatusNoScreen4_addr    (*((uint32_t  __near*)             (_NULL_OFFSET + 0x056C)))
#define Z_QuickMapRender7000_addr         (*((uint32_t  __near*)             (_NULL_OFFSET + 0x0570)))
#define Z_QuickMapScreen0_addr            (*((uint32_t  __near*)             (_NULL_OFFSET + 0x0574)))
#define W_CacheLumpNameDirect_addr        (*((uint32_t  __near*)             (_NULL_OFFSET + 0x0578)))
#define W_CacheLumpNumDirectFragment_addr (*((uint32_t  __near*)             (_NULL_OFFSET + 0x057C)))
#define W_GetNumForName_addr              (*((uint32_t  __near*)             (_NULL_OFFSET + 0x0580)))
#define S_StartSound_addr                 (*((uint32_t  __near*)             (_NULL_OFFSET + 0x0584)))
#define S_StartMusic_addr                 (*((uint32_t  __near*)             (_NULL_OFFSET + 0x0588)))
// 13 bytes (12345678.123) fileame format incl . and null term
#define filename_argument                 ((int8_t __near *)                 (_NULL_OFFSET + 0x058C))

#define rndindex                          (*(uint8_t __near *)               (_NULL_OFFSET + 0x0599))
#define fopen_r_argument                  ((int8_t __near *)                 (_NULL_OFFSET + 0x059A))
#define fopen_w_argument                  ((int8_t __near *)                 (_NULL_OFFSET + 0x059C))

#define numsectors                        (*(int16_t __near *)               (_NULL_OFFSET + 0x059E))
#define numlines                          (*(int16_t __near *)               (_NULL_OFFSET + 0x05A0))
#define numvertexes                       (*(int16_t __near *)               (_NULL_OFFSET + 0x05A2))
#define numsegs                           (*(int16_t __near *)               (_NULL_OFFSET + 0x05A4))
#define numsubsectors                     (*(int16_t __near *)               (_NULL_OFFSET + 0x05A6))
#define numnodes                          (*(int16_t __near *)               (_NULL_OFFSET + 0x05A8))
#define numsides                          (*(int16_t __near *)               (_NULL_OFFSET + 0x05AA))
#define bmapwidth                         (*(int16_t __near *)               (_NULL_OFFSET + 0x05AC))
#define bmapheight                        (*(int16_t __near *)               (_NULL_OFFSET + 0x05AE))
#define bmaporgx                          (*(int16_t __near *)               (_NULL_OFFSET + 0x05B0))
#define bmaporgy                          (*(int16_t __near *)               (_NULL_OFFSET + 0x05B2))

#define I_Error_addr                      (*((uint32_t __near*)              (_NULL_OFFSET + 0x05B4)))
#define P_InitThinkers_addr               (*((uint32_t __near*)              (_NULL_OFFSET + 0x05B8)))
#define P_CreateThinker_addr              (*((uint32_t __near*)              (_NULL_OFFSET + 0x05BC)))
#define P_SetThingPosition_addr           (*((uint32_t __near*)              (_NULL_OFFSET + 0x05C0)))
#define P_RemoveMobj_addr                 (*((uint32_t __near*)              (_NULL_OFFSET + 0x05C4)))
#define P_AddActiveCeiling_addr           (*((uint32_t __near*)              (_NULL_OFFSET + 0x05C8)))
#define P_AddActivePlat_addr              (*((uint32_t __near*)              (_NULL_OFFSET + 0x05CC)))

#define activeceilings                    ((THINKERREF __near *)             (_NULL_OFFSET + 0x05D0))

//0x60C
#define Z_SetOverlay_addr                 (*((uint32_t __near*)              (_NULL_OFFSET + 0x060C)))
#define W_LumpLength_addr                 (*((uint32_t __near*)              (_NULL_OFFSET + 0x0610)))
#define playingdriver                     (*((driverBlock __far* __near *)   (_NULL_OFFSET + 0x0614)))
#define currentsong_start_offset          (*((uint16_t __near*)              (_NULL_OFFSET + 0x0618)))
#define currentsong_playing_offset        (*((uint16_t __near*)              (_NULL_OFFSET + 0x061A)))
#define currentsong_ticks_to_process      (*((int16_t __near*)               (_NULL_OFFSET + 0x061C)))
#define loops_enabled    			      (*((int8_t __near*)                (_NULL_OFFSET + 0x061E)))
#define mus_playing    			      	  (*((int8_t __near*)                (_NULL_OFFSET + 0x061F)))
#define Z_QuickMapMusicPageFrame_addr     (*((uint32_t __near*)              (_NULL_OFFSET + 0x0620)))

#define sightzstart					      (*((fixed_t __near*)         		 (_NULL_OFFSET + 0x0624)))
#define topslope					      (*((fixed_t __near*)         		 (_NULL_OFFSET + 0x0628)))
#define bottomslope					      (*((fixed_t __near*)         		 (_NULL_OFFSET + 0x062C)))
#define cachedt2x					      (*((fixed_t_union __near*)         (_NULL_OFFSET + 0x0630)))
#define cachedt2y					      (*((fixed_t_union __near*)         (_NULL_OFFSET + 0x0634)))
#define strace					          (*((divline_t __near*)             (_NULL_OFFSET + 0x0638)))

// free bytes per EMS page. Allocated in 256k chunks, so defaults to 64.. 
// leave what, 40 bytes just in case?
// todo move this to mottom and make it growable...
#define sfx_free_bytes					  (((uint8_t __near*)                (_NULL_OFFSET + 0x0648)))


// 0x670

#define activespritepages				  (((uint8_t __near*)                (_NULL_OFFSET + 0x0670)))
#define activespritenumpages			  (((uint8_t __near*)                (_NULL_OFFSET + 0x0674)))
#define spriteL1LRU						  (((uint8_t __near*)                (_NULL_OFFSET + 0x0678)))
#define spritecache_l2_head				  (*((uint8_t __near*)               (_NULL_OFFSET + 0x067C)))
#define spritecache_l2_tail				  (*((uint8_t __near*)               (_NULL_OFFSET + 0x067D)))
#define texturecache_l2_head			  (*((uint8_t __near*)               (_NULL_OFFSET + 0x067E)))
#define texturecache_l2_tail			  (*((uint8_t __near*)               (_NULL_OFFSET + 0x067F)))
#define activetexturepages				  (((uint8_t __near*)                (_NULL_OFFSET + 0x0680)))
#define activenumpages					  (((uint8_t __near*)                (_NULL_OFFSET + 0x0688)))
#define textureL1LRU					  (((uint8_t __near*)                (_NULL_OFFSET + 0x0690)))
#define cachedsegmentlumps				  (((segment_t __near*)              (_NULL_OFFSET + 0x0698)))
#define cachedlumps					 	  (((int16_t __near*)                (_NULL_OFFSET + 0x06A0)))
#define cachedtex				  		  (((int16_t __near*)                (_NULL_OFFSET + 0x06A8)))
#define cachedcollength				      (((uint8_t __near*)                (_NULL_OFFSET + 0x06AC)))
#define flatcache_l2_head				  (*((uint8_t __near*)               (_NULL_OFFSET + 0x06AE)))
#define flatcache_l2_tail				  (*((uint8_t __near*)               (_NULL_OFFSET + 0x06AF)))
#define segloopprevlookup				  (((int16_t __near*)                (_NULL_OFFSET + 0x06B0)))
#define segloopcachedbasecol			  (((int16_t __near*)                (_NULL_OFFSET + 0x06B4)))
#define cachedsegmenttex				  (((segment_t __near*)              (_NULL_OFFSET + 0x06B8)))
// unused
// #define cachedcollength				      (((uint8_t __near*)                (_NULL_OFFSET + 0x06BC)))
#define ceilinglinenum				      (*((int16_t __near*)               (_NULL_OFFSET + 0x06BE)))

#define lineopening  				      (*((lineopening_t __near*)         (_NULL_OFFSET + 0x06C0)))
// unused
// #define ???				      (*((int16_t __near*)               (_NULL_OFFSET + 0x06C6)))
#define intercept_p  				      (*((intercept_t __far* __near*)    (_NULL_OFFSET + 0x06C8)))
#define aimslope     				      (*((fixed_t_union  __near*)   	 (_NULL_OFFSET + 0x06CC)))
#define bestslidefrac     				  (*((fixed_t_union  __near*)   	 (_NULL_OFFSET + 0x06D0)))
#define bestslidelinenum		          (*((int16_t __near*)               (_NULL_OFFSET + 0x06D4)))
#define numspechit		   			      (*((int16_t __near*)               (_NULL_OFFSET + 0x06D6)))
#define lastcalculatedsector		      (*((int16_t __near*)               (_NULL_OFFSET + 0x06D8)))

#define shootthing	     				  (*((mobj_t __near*  __near*)       (_NULL_OFFSET + 0x06DA)))
#define shootz     				  		  (*((fixed_t_union  __near*)   	 (_NULL_OFFSET + 0x06DC)))

#define la_damage		   			      (*((int16_t __near*)               (_NULL_OFFSET + 0x06E0)))

#define linetarget	     				  (*((mobj_t  __near* __near*)       (_NULL_OFFSET + 0x06E2)))
#define linetarget_pos  			      (*((mobj_pos_t __far* __near*)     (_NULL_OFFSET + 0x06E4)))
#define attackrange16		   		      (*((int16_t __near*)               (_NULL_OFFSET + 0x06E8)))
#define nofit		   		              (*((boolean __near*)               (_NULL_OFFSET + 0x06EA)))
#define crushchange		   		          (*((boolean __near*)               (_NULL_OFFSET + 0x06EB)))
#define leveltime     				      (*((fixed_t_union  __near*)   	 (_NULL_OFFSET + 0x06EC)))

#define flatcache_nodes				      (((cache_node_t __near*)           (_NULL_OFFSET + 0x06F0)))
// based on size of NUM_FLAT_CACHE_PAGES, this will move back...
#define CURRENT_POSITION_1  			  (((uint16_t) flatcache_nodes) + (sizeof(cache_node_t) * NUM_FLAT_CACHE_PAGES))
#define spritecache_nodes				  (((cache_node_page_count_t __near*) (CURRENT_POSITION_1)))
#define CURRENT_POSITION_2   			  (((uint16_t) spritecache_nodes) + (sizeof(cache_node_page_count_t) * NUM_SPRITE_CACHE_PAGES))
#define texturecache_nodes				  (((cache_node_page_count_t __near*) (CURRENT_POSITION_2)))
#define CURRENT_POSITION_3  			  (((uint16_t) texturecache_nodes) + (sizeof(cache_node_page_count_t) * NUM_TEXTURE_PAGES))

#define allocatedflatsperpage             (((uint8_t __near*) (CURRENT_POSITION_3)))
#define CURRENT_POSITION_4   			  (((uint16_t) allocatedflatsperpage) + (sizeof(uint8_t) * NUM_FLAT_CACHE_PAGES))
#define usedspritepagemem				  (((uint8_t __near*) (CURRENT_POSITION_4)))
#define CURRENT_POSITION_5  			  (((uint16_t) usedspritepagemem) + (sizeof(uint8_t) * NUM_SPRITE_CACHE_PAGES))
#define usedtexturepagemem				  (((uint8_t __near*) (CURRENT_POSITION_5)))
#define CURRENT_POSITION_6  			  (((uint16_t) usedtexturepagemem) + (sizeof(uint8_t) * NUM_TEXTURE_PAGES))


// extern int16_t 					segloopprevlookup[2];
// extern int16_t 					segloopnextlookup[2];

// extern uint8_t 					seglooptexrepeat[2]; 
// extern segment_t 				segloopcachedsegment[2];
// extern int16_t 					segloopcachedbasecol[2];
// extern uint8_t 					segloopheightvalcache[2];

// biggest MUS in doom1/2 is 64808... divided by 4 this 
// gives us 128 free bytes of overlap per page and fits the 64808 barely.
#define MUS_SIZE_PER_PAGE 16256




extern uint8_t              snd_SBirq; // sound blaster variables
extern uint8_t              snd_SBdma;

extern uint8_t              snd_SfxVolume; // maximum volume for sound

extern uint8_t              snd_DesiredSfxDevice;
extern uint8_t              snd_DesiredMusicDevice;
extern uint16_t             snd_SBport;
extern uint16_t             snd_Mport;


// wipegamestate can be set to -1 to force a wipe on the next draw


#define MAXWADFILES             3



extern boolean              nomonsters;     // checkparm of -nomonsters
extern boolean              respawnparm;    // checkparm of -respawn
extern boolean              fastparm;       // checkparm of -fast

extern boolean              singletics;


extern skill_t              startskill;
extern int8_t               startepisode;
extern int8_t               startmap;
extern boolean              autostart;


extern boolean              advancedemo;

extern boolean              modifiedgame;


extern int8_t               demosequence;

extern int16_t              pagetic;
extern int8_t               *pagename;


#ifdef DETAILED_BENCH_STATS
extern uint16_t             rendertics;
extern uint16_t             physicstics;
extern uint16_t             othertics;
extern uint16_t             cachedtics;
extern uint16_t             cachedrendertics;
extern uint16_t             rendersetuptics;
extern uint16_t             renderplayerviewtics;
extern uint16_t             renderpostplayerviewtics;

extern uint16_t             renderplayersetuptics;
extern uint16_t             renderplayerbsptics;
extern uint16_t             renderplayerplanetics;
extern uint16_t             renderplayermaskedtics;
extern uint16_t             cachedrenderplayertics;
#endif

extern int8_t		        eventhead;
extern int8_t		        eventtail;

extern uint8_t              mouseSensitivity;       
extern uint8_t              showMessages;
extern uint8_t              sfxVolume;
extern uint8_t              musicVolume;
extern uint8_t              detailLevel;
extern uint8_t              screenSize;
extern int8_t               quickSaveSlot;
extern boolean              inhelpscreens;
extern boolean              menuactive;

extern int16_t		        scaledviewwidth;
extern int16_t		        viewwindowx;
extern int16_t		        viewwindowy; 
extern int16_t		        viewwindowoffset;

extern int8_t               skytextureloaded;
extern int16_t              r_cachedplayerMobjsecnum;

extern int16_t 			    pendingdetail;
extern uint16_t			    clipangle;
extern uint16_t			    fieldofview;
extern boolean		        setsizeneeded;
extern uint8_t		        setblocks;
extern uint16_t			    skytexture;

extern uint16_t             pspritescale;
extern int16_t              numflats;
extern int16_t              numpatches;
extern int16_t              numspritelumps;
extern int16_t              numtextures;
 
//extern int16_t              ;

extern int8_t               am_cheating;
extern int8_t 	            am_grid;
extern mpoint_t             m_paninc; 
extern int16_t 	            mtof_zoommul; 
extern int16_t 	            ftom_zoommul; 
extern int16_t 	            screen_botleft_x;
extern int16_t              screen_botleft_y;
extern int16_t 	            screen_topright_x;
extern int16_t              screen_topright_y;
extern int16_t	            screen_viewport_width;
extern int16_t	            screen_viewport_height;
extern int16_t              am_min_level_x;
extern int16_t	            am_min_level_y;
extern int16_t              am_max_level_x;
extern int16_t	            am_max_level_y;
extern uint16_t 	        am_min_scale_mtof;
extern fixed_t_union 	    am_max_scale_mtof;
extern int16_t              old_screen_viewport_width;
extern int16_t              old_screen_viewport_height;
extern int16_t              old_screen_botleft_x;
extern int16_t              old_screen_botleft_y;
extern mpoint_t             screen_oldloc;
extern fixed_t_union        am_scale_mtof;
extern fixed_t_union        am_scale_ftom;
extern mpoint_t             markpoints[AM_NUMMARKPOINTS];
extern int8_t               markpointnum;
extern int8_t               followplayer;
extern boolean              am_stopped;
extern boolean              am_bigstate;
extern int8_t               am_buffer[20];
extern fline_t              am_fl;
extern mline_t              am_ml;
extern mline_t              am_l;
extern int8_t               am_lastlevel; 
extern int8_t               am_lastepisode;
extern mline_t              am_lc;
extern mline_t              player_arrow[7];
extern mline_t              cheat_player_arrow[16]; 
/*
extern mline_t              triangle_guy[3];
*/
extern mline_t              thintriangle_guy[3];


extern void                 (__far* R_DrawPlanesCall)();
extern void                 (__far* R_WriteBackViewConstantsSpanCall)();
extern void                 (__far* R_DrawMaskedCall)();




extern void                 (__far* wipe_StartScreenCall)();
extern void                 (__far* wipe_WipeLoopCall)();
extern void                 (__far* R_WriteBackMaskedFrameConstantsCall)();
extern void                 (__far* R_WriteBackViewConstantsMaskedCall)();

extern void                 (__far* F_StartFinale)();
extern void                 (__far* F_Ticker)();
extern void                 (__far* F_Drawer)();
extern boolean              (__far* F_Responder)(event_t  __far*event);

extern void (__far* WI_Start)(wbstartstruct_t __near*, boolean);
extern void (__far* WI_Ticker)();
extern void (__far* WI_Drawer)();


extern void                 (__far* P_UnArchivePlayers)();
extern void                 (__far* P_UnArchiveWorld)();
extern void                 (__far* P_UnArchiveThinkers)();
extern void                 (__far* P_UnArchiveSpecials)();

extern void                 (__far* P_ArchivePlayers)();
extern void                 (__far* P_ArchiveWorld)();
extern void                 (__far* P_ArchiveThinkers)();
extern void                 (__far* P_ArchiveSpecials)();

extern void                 (__far* S_ActuallyChangeMusic)();
extern void 				(__far* LoadSFXWadLumps)();
extern boolean 				(__far* P_CheckSight)(mobj_t __near* m1, mobj_t __near* m2, uint16_t m3, uint16_t m4);




extern int16_t              currentlumpindex;
extern uint16_t             maskedcount;
extern uint16_t             currentpostoffset;
extern uint16_t             currentpostdataoffset;
extern uint16_t             currentpixeloffset;

extern spriteframe_t __far* p_init_sprtemp;
extern int16_t              p_init_maxframe;

#define SC_UPARROW              0x48
#define SC_DOWNARROW            0x50
#define SC_LEFTARROW            0x4b
#define SC_RIGHTARROW           0x4d
#define SC_RCTRL                0x1d
#define SC_RALT                 0x38
#define SC_RSHIFT               0x36
#define SC_SPACE                0x39
#define SC_COMMA                0x33
#define SC_PERIOD               0x34
#define SC_PAGEUP               0x49
#define SC_INSERT               0x52
#define SC_HOME                 0x47
#define SC_PAGEDOWN             0x51
#define SC_DELETE               0x53
#define SC_END                  0x4f
#define SC_ENTER                0x1c

#define SC_KEY_A                0x1e
#define SC_KEY_B                0x30
#define SC_KEY_C                0x2e
#define SC_KEY_D                0x20
#define SC_KEY_E                0x12
#define SC_KEY_F                0x21
#define SC_KEY_G                0x22
#define SC_KEY_H                0x23
#define SC_KEY_I                0x17
#define SC_KEY_J                0x24
#define SC_KEY_K                0x25
#define SC_KEY_L                0x26
#define SC_KEY_M                0x32
#define SC_KEY_N                0x31
#define SC_KEY_O                0x18
#define SC_KEY_P                0x19
#define SC_KEY_Q                0x10
#define SC_KEY_R                0x13
#define SC_KEY_S                0x1f
#define SC_KEY_T                0x14
#define SC_KEY_U                0x16
#define SC_KEY_V                0x2f
#define SC_KEY_W                0x11
#define SC_KEY_X                0x2d
#define SC_KEY_Y                0x15
#define SC_KEY_Z                0x2c
#define SC_BACKSPACE            0x0e



#define KEY_LSHIFT      0xfe

#define KEY_INS         (0x80+0x52)
#define KEY_DEL         (0x80+0x53)
#define KEY_PGUP        (0x80+0x49)
#define KEY_PGDN        (0x80+0x51)
#define KEY_HOME        (0x80+0x47)
#define KEY_END         (0x80+0x4f)

#define SC_RSHIFT       0x36
#define SC_LSHIFT       0x2a

extern boolean grmode;
extern boolean mousepresent;
// REGS stuff used for int calls

extern boolean novideo; // if true, stay in text mode for debugging
#define KBDQUESIZE 32

extern void (__interrupt __far_func *oldkeyboardisr) (void);
extern boolean             viewactivestate;
extern boolean             menuactivestate;
extern boolean             inhelpscreensstate;
extern boolean             fullscreen;
extern gamestate_t         oldgamestate;
extern uint8_t                 borderdrawcount;
extern ticcount_t maketic;
extern ticcount_t gametime;

extern uint8_t			numChannels;	
extern uint8_t	usegamma;

#define BACKUPTICS		16
#define NUMKEYS         256 


 

extern skill_t            gameskill; 
extern boolean            respawnmonsters;
extern boolean            paused; 
extern boolean            sendpause;              // send a pause event next tic 
extern boolean            sendsave;               // send a save event next tic 
extern boolean         	  usergame;               // ok to save / end game 
extern boolean         	  timingdemo;             // if true, exit with report on completion 
extern boolean         	  noblit;                 // for comparative timing purposes 
extern ticcount_t         starttime;              // for comparative timing purposes       
extern player_t        	  player;
extern THINKERREF      	  playerMobjRef;
extern mobj_t __near *    playerMobj;
extern mobj_pos_t __far * playerMobj_pos;


extern ticcount_t          gametic;
extern int16_t             totalkills; 
extern int16_t             totalitems;
extern int16_t             totalsecret;    // for intermission 
extern boolean         demorecording; 
extern boolean         demoplayback; 
extern boolean         netdemo; 
extern uint16_t           demo_p;				// buffer
extern boolean         singledemo;             // quit after playing a demo from cmdline 
extern boolean         precache;        // if true, load all graphics at start 
extern wbstartstruct_t wminfo;                 // parms for world map / intermission 
 
  
 
// 
// controls (have defaults) 
// 
extern uint8_t             key_right;
extern uint8_t             key_left;
extern uint8_t             key_up;
extern uint8_t             key_down;
extern uint8_t             key_strafeleft;
extern uint8_t             key_straferight;
extern uint8_t             key_fire;
extern uint8_t             key_use;
extern uint8_t             key_strafe;
extern uint8_t             key_speed;
extern uint8_t             mousebfire;
extern uint8_t             mousebstrafe;
extern uint8_t             mousebforward;
extern fixed_t             forwardmove[2];
extern fixed_t             sidemove[2];

extern int8_t             turnheld;
extern boolean         mousearray[4]; 
extern boolean*        mousebuttons;
extern int16_t             mousex;
extern int16_t             dclicktime;
extern int16_t             dclickstate;
extern int16_t             dclicks;
extern int16_t             dclicktime2;
extern int16_t             dclickstate2;
extern int16_t             dclicks2;
extern int8_t             savegameslot;

extern skill_t d_skill; 
extern int8_t     d_episode;
extern int8_t     d_map;


extern int16_t		myargc;
extern int8_t**		myargv;
extern int16_t	prndindex;
extern uint8_t		usemouse;


extern int8_t*   defdemoname; 
extern boolean         secretexit; 

extern boolean          st_firsttime;
extern boolean          updatedthisframe;
extern st_stateenum_t   st_gamestate;
extern boolean          st_statusbaron;
extern uint16_t         tallnum[10];
extern uint16_t         shortnum[10];
extern uint16_t 		tallpercent;
extern uint16_t			faceback;
extern uint16_t			sbar;
extern uint16_t			armsbg;
extern uint16_t         keys[NUMCARDS];
extern uint16_t         faces[ST_NUMFACES];
extern uint16_t 		arms[6][2];
extern st_number_t      w_ready;
extern st_percent_t     w_health;
extern st_multicon_t     w_armsbg;
extern st_multicon_t    w_arms[6];
extern st_multicon_t    w_faces; 
extern st_multicon_t    w_keyboxes[3];
extern st_percent_t     w_armor;
extern st_number_t      w_ammo[4];
extern st_number_t      w_maxammo[4]; 
extern int16_t      st_oldhealth;
extern boolean  oldweaponsowned[NUMWEAPONS]; 
extern int16_t      st_facecount;
extern int16_t      st_faceindex;
extern int16_t      keyboxes[3];
extern uint8_t      st_randomnumber;


// Now what?
#define NUM_CHEATS 17

// these get shifted by 2 in the functions, so pass them in pre-shifted.
#define CHEATID_BEHOLDV         0
#define CHEATID_BEHOLDS         4
#define CHEATID_BEHOLDI         8
#define CHEATID_BEHOLDR         12
#define CHEATID_BEHOLDA         16
#define CHEATID_BEHOLDL         20
#define CHEATID_BEHOLD          24
#define CHEATID_AUTOMAP         28
#define CHEATID_MUSIC           32
#define CHEATID_GODMODE         36
#define CHEATID_AMMOANDKEYS     40
#define CHEATID_AMMONOKEYS      44
#define CHEATID_NOCLIP          48
#define CHEATID_NOCLIPDOOM2     52
#define CHEATID_CHOPPERS        56
#define CHEATID_CHANGE_LEVEL    60
#define CHEATID_MAPPOS          64


extern boolean do_st_refresh;
 
extern int8_t st_palette;

extern int16_t  st_calc_lastcalc;
extern int16_t  st_calc_oldhealth;
extern int8_t  st_face_lastattackdown;
extern int8_t  st_face_priority;
extern int8_t     st_stuff_buf[ST_MSGWIDTH];



extern hu_textline_t	w_title;
extern boolean		message_on;
extern boolean			message_dontfuckwithme;
extern boolean		message_nottobefuckedwith;
extern hu_stext_t	w_message;
extern uint8_t		message_counter;



// offsets within segment stored
extern uint16_t hu_font[HU_FONTSIZE];





 

#if (EXE_VERSION >= EXE_VERSION_FINAL)
extern int16_t	p1text;
extern int16_t	p2text;
extern int16_t	p3text;
extern int16_t	p4text;
extern int16_t	p5text;
extern int16_t	p6text;

extern int16_t	t1text;
extern int16_t	t2text;
extern int16_t	t3text;
extern int16_t	t4text;
extern int16_t	t5text;
extern int16_t	t6text;
#endif


extern uint8_t  messageToPrint;
extern int8_t   menu_messageString[105];
extern int16_t  messageLastMenuActive;
extern boolean  messageNeedsInput;
extern void     (__near *messageRoutine)(int16_t response);
extern int16_t  saveStringEnter;
extern int16_t  saveSlot;       // which slot to save in
extern int16_t  saveCharIndex;  // which char we're editing
extern int8_t   saveOldString[SAVESTRINGSIZE];
extern int16_t  itemOn;                 // menu item skull is on
extern int16_t  skullAnimCounter;       // skull animation counter
extern int16_t  whichSkull;             // which skull to draw
extern int16_t  skullName[2];
extern menu_t   __near* currentMenu;      






extern menuitem_t MainMenu[6];
extern menu_t  MainDef;



extern menuitem_t EpisodeMenu[4];

extern menu_t  EpiDef;
//
// NEW GAME
//

extern menuitem_t NewGameMenu[5];
extern menu_t  NewDef;


extern menuitem_t OptionsMenu[8];
extern menu_t  OptionsDef;

//
// Read This! MENU 1 & 2
//

extern menuitem_t ReadMenu1[1];
extern menu_t  ReadDef1;


extern menuitem_t ReadMenu2[1];
extern menu_t  ReadDef2;

//
// SOUND VOLUME MENU
//

extern menuitem_t SoundMenu[4];
extern menu_t  SoundDef;
extern menuitem_t LoadMenu[6];
extern menu_t  LoadDef;
extern menuitem_t SaveMenu[6];
extern menu_t  SaveDef;
extern int8_t     menu_epi;


extern int8_t    detailNames[2];
extern int8_t    msgNames[2];




extern task HeadTask;
extern task MUSTask;

extern void( __interrupt __far_func *OldInt8)(void);
extern volatile fixed_t_union TaskServiceCount;

extern volatile int8_t TS_TimesInInterrupt;
extern int8_t TS_Installed;
extern volatile int8_t TS_InInterrupt;




#define castorderoffset CC_ZOMBIE
 

 

extern boolean  st_stopped;
extern uint16_t armsbgarray[1];



extern THINKERREF	activeplats[MAXPLATS];
extern weaponinfo_t	weaponinfo[NUMWEAPONS];
extern fixed_t		bulletslope;
extern uint16_t		switchlist[MAXSWITCHES * 2];
extern int16_t		numswitches;
extern button_t        buttonlist[MAXBUTTONS];
extern int16_t	maxammo[NUMAMMO];
extern int8_t	clipammo[NUMAMMO];
extern boolean		onground;


extern int16_t currentThinkerListHead;
extern mobj_t __near* setStateReturn;
extern mobj_pos_t __far* setStateReturn_pos;
extern uint16_t oldentertics;

   


#define    DI_EAST 0
#define    DI_NORTHEAST 1
#define    DI_NORTH 2
#define    DI_NORTHWEST 3
#define    DI_WEST 4
#define    DI_SOUTHWEST 5
#define    DI_SOUTH 6
#define    DI_SOUTHEAST 7
#define    DI_NODIR 8
#define    NUMDIRS 9
 
typedef int8_t dirtype_t;
extern dirtype_t opposite[9];
extern dirtype_t diags[4];



 



typedef struct {

    boolean	istexture;
	uint16_t		picnum;
	uint16_t		basepic;
    uint8_t		numpics;
    
} p_spec_anim_t;




#define MAXANIMS                32


extern p_spec_anim_t	anims[MAXANIMS];
extern p_spec_anim_t __near*		lastanim;
extern boolean		levelTimer;
extern ticcount_t		levelTimeCount;
extern int16_t		numlinespecials;








//
// ClipWallSegment
// Clips the given range of columns
// and includes it in the new clip list.
//
typedef	struct {

    int16_t	first;
	int16_t last;
    
} cliprange_t;


#define MAXSEGS		32
#define MAX_WADFILES 4


// newend is one past the last valid seg
extern cliprange_t __near*	newend;
extern cliprange_t	solidsegs[MAXSEGS];
extern uint16_t                     numlumps;
extern FILE*               		    wadfiles[MAX_WADFILES];
extern int16_t                	    filetolumpindex[MAX_WADFILES-1];
extern int32_t                		filetolumpsize[MAX_WADFILES-1];
extern int8_t                       currentloadedfileindex;
  







#if defined(__CHIPSET_BUILD)

// these are prepared for calls to outsw with autoincrementing ems register on
extern uint16_t pageswapargs[total_pages];

#else

extern int16_t emshandle;
extern int16_t pagenum9000;

extern uint16_t pageswapargs[total_pages];

#endif

  





#ifdef DETAILED_BENCH_STATS
extern int32_t taskswitchcount;
extern int32_t texturepageswitchcount;
extern int32_t patchpageswitchcount;
extern int32_t compositepageswitchcount;
extern int32_t spritepageswitchcount;
extern int16_t benchtexturetype;
extern int32_t flatpageswitchcount;
extern int32_t scratchpageswitchcount;
extern int16_t spritecacheevictcount;
extern int16_t flatcacheevictcount;
extern int16_t patchcacheevictcount;
extern int16_t compositecacheevictcount;
extern int32_t visplaneswitchcount;

#endif

extern int8_t currenttask;


extern segment_t			    spritewidths_segment;  // gross hack? todo revisit...


extern int8_t    savename[16];
extern int8_t versionstring[12];

extern int8_t  currentoverlay;
extern int32_t codestartposition[NUM_OVERLAYS];

#if (EXE_VERSION >= EXE_VERSION_FINAL)
extern boolean    				plutonia;
extern boolean    				tnt;
#endif




#define MAX_MUSIC_CHANNELS	16		// total channels 0..CHANNELS-1
#define PERCUSSION	15		// percussion channel
#define MAX_INSTRUMENTS 175
#define MAX_INSTRUMENTS_PER_TRACK 0x1C // largest in doom1 or doom2
#define DEFAULT_PITCH_BEND 0x80
#define DEFAULT_VOLUME  256
#define MUTE_VOLUME  0


#define ADLIBPORT	0x388
#define SBPORT		0x228
#define SBPROPORT	0x220
#define OPL2PORT	0x388		/* universal port number */
#define OPL3PORT	0x388

#define OPL2CHANNELS	9
#define OPL3CHANNELS	18

/* DP_SINGLE_VOICE: param1 codes */
#define DPP_SINGLE_VOICE_OFF	0	/* default: off */
#define DPP_SINGLE_VOICE_ON	1


#define DRV_OPL2    0x01
#define DRV_OPL3	0x02

#define ST_EMPTY	0		// music block is empty
#define ST_STOPPED	1		// music block is used but not playing
#define ST_PLAYING	2		// music block is used and playing
#define ST_PAUSED	3		// music block is used and paused
					// any number >= 3 means `paused'
#define NUM_CONTROLLERS 10

 
#define DRV_SBMIDI	0x0005
#define SBMIDIPORT	0x220
#define MPU401PORT	0x330
#define DRV_MPU401	0x0004

/* Internal variables */
typedef struct {
	uint8_t	channelInstr[MAX_MUSIC_CHANNELS];		// instrument #
	uint8_t	channelVolume[MAX_MUSIC_CHANNELS];	// volume
	uint8_t	channelLastVolume[MAX_MUSIC_CHANNELS];	// last volume
	int8_t	channelPan[MAX_MUSIC_CHANNELS];		// pan, 0=normal
	int8_t	channelPitch[MAX_MUSIC_CHANNELS];		// pitch wheel, 0=normal
	uint8_t	channelSustain[MAX_MUSIC_CHANNELS];	// sustain pedal value
	uint8_t	channelModulation[MAX_MUSIC_CHANNELS];	// modulation pot value
} OPLdata;


typedef struct  {
	int8_t	(*initDriver)(void);    
	int8_t	(*detectHardware)(uint16_t port, uint8_t irq, uint8_t dma);
	int8_t	(*initHardware)(uint16_t port, uint8_t irq, uint8_t dma);
	int8_t	(*deinitHardware)(void);
	void	(*playNote)(uint8_t channel, uint8_t note, int8_t noteVolume);
	void	(*releaseNote)(uint8_t channel, uint8_t note);
	void	(*pitchWheel)(uint8_t channel, uint8_t pitch);
	void	(*changeControl)(uint8_t channel, uint8_t controller, uint8_t value);
	void	(*playMusic)();
	void	(*stopMusic)();
	void	(*pauseMusic)();
	void	(*resumeMusic)();
	void	(*changeSystemVolume)(uint8_t volume);
	int8_t	driverId;
	int8_t	unused;
	byte*   driverdata;

} driverBlock;


/* OPL2 instrument */
typedef struct{
/*00*/	uint8_t    trem_vibr_1;	/* OP 1: tremolo/vibrato/sustain/KSR/multi */
/*01*/	uint8_t	att_dec_1;	/* OP 1: attack rate/decay rate */
/*02*/	uint8_t	sust_rel_1;	/* OP 1: sustain level/release rate */
/*03*/	uint8_t	wave_1;		/* OP 1: waveform select */
/*04*/	uint8_t	scale_1;	/* OP 1: key scale lesvel */
/*05*/	uint8_t	level_1;	/* OP 1: output level */
/*06*/	uint8_t	feedback;	/* feedback/AM-FM (both operators) */
/*07*/	uint8_t trem_vibr_2;	/* OP 2: tremolo/vibrato/sustain/KSR/multi */
/*08*/	uint8_t	att_dec_2;	/* OP 2: attack rate/decay rate */
/*09*/	uint8_t	sust_rel_2;	/* OP 2: sustain level/release rate */
/*0A*/	uint8_t	wave_2;		/* OP 2: waveform select */
/*0B*/	uint8_t	scale_2;	/* OP 2: key scale level */
/*0C*/	uint8_t	level_2;	/* OP 2: output level */
/*0D*/	uint8_t	unused;
/*0E*/	int16_t	basenote;	/* base note offset */
} OPL2instrument;

/* OP2 instrument file entry */
typedef struct  {
/*00*/	uint16_t	    flags;			// see FL_xxx below
/*02*/	uint8_t	        finetune;		// finetune value for 2-voice sounds
/*03*/	uint8_t	        note;			// note # for fixed instruments
/*04*/	OPL2instrument  instr[2];	// instruments
} OP2instrEntry;

typedef struct  {
	// 00
	uint8_t	controllers[NUM_CONTROLLERS][MAX_MUSIC_CHANNELS]; // MUS controllers
	// a0
	uint8_t	channelLastVolume[MAX_MUSIC_CHANNELS];	// last volume
	// b0
	uint8_t	pitchWheel[MAX_MUSIC_CHANNELS];		// pitch wheel value
	// c0
	int8_t	realChannels[MAX_MUSIC_CHANNELS];		// real MIDI output channels
	// d0
	uint8_t	percussions[128/8];		// bit-map of used percussions
} MIDIdata;

/* OPL channel (voice) data */
typedef struct {
	uint8_t	channel;		/* MUS channel number */
	uint8_t	note;			/* note number */
	uint8_t	flags;			/* see CH_xxx below */
	uint8_t	realnote;		/* adjusted note number */
	uint8_t	pitchwheel;		/* pitch-wheel value */
	int8_t	finetune;		/* frequency fine-tune */
	int8_t  noteVolume;		/* note volume */
	int8_t	realvolume;		/* adjusted note volume */
	OPL2instrument _near * instr;	    /* current instrument */
	uint32_t time;			/* note start time */
}  AdlibChannelEntry;





// the complete set of sound effects
extern uint8_t sfx_priority[];

// the complete set of music



extern channel_t	channels[MAX_SFX_CHANNELS];
extern boolean		mus_paused;	

//extern uint16_t shift4lookup[256];

//extern      driverBlock OPL3driver;






void	OPLplayNote(uint8_t channel, uint8_t note, int8_t noteVolume);
void	OPLreleaseNote(uint8_t channel, uint8_t note);
void    OPLpitchWheel(uint8_t channel, uint8_t pitch);
void	OPLchangeControl(uint8_t channel, uint8_t controller, uint8_t value);
void	OPLplayMusic();
void	OPLstopMusic();
void	OPLpauseMusic();
void	OPLresumeMusic();
void	OPLchangeSystemVolume(uint8_t systemVolume);
int8_t 	OPLsendMIDI(uint8_t command, uint8_t par1, uint8_t par2);

int8_t	OPLinitDriver(void);
int8_t	OPL2detectHardware(uint16_t port, uint8_t irq, uint8_t dma);
int8_t	OPL2initHardware(uint16_t port, uint8_t irq, uint8_t dma);
int8_t	OPL2deinitHardware(void);
int8_t	OPL3detectHardware(uint16_t port, uint8_t irq, uint8_t dma);
int8_t	OPL3initHardware(uint16_t port, uint8_t irq, uint8_t dma);
int8_t	OPL3deinitHardware(void);

void	MIDIplayNote_MPU401(uint8_t channel, uint8_t note, int8_t noteVolume);
void	MIDIreleaseNote_MPU401(uint8_t channel, uint8_t note);
void	MIDIpitchWheel_MPU401(uint8_t channel, uint8_t pitch);
void	MIDIchangeControl_MPU401(uint8_t channel, uint8_t controller, uint8_t value);
void	MIDIplayMusic_MPU401();
void	MIDIstopMusic_MPU401();
void	MIDIpauseMusic_MPU401();
void	MIDIresumeMusic_MPU401();
void	MIDIchangeSystemVolume_MPU401(uint8_t noteVolume);
int8_t  MIDIinitDriver_MPU401(void);
int8_t 	MPU401initHardware(uint16_t port, uint8_t irq, uint8_t dma);
int8_t 	MPU401detectHardware(uint16_t port, uint8_t irq, uint8_t dma);
int8_t  MPU401deinitHardware(void);
int8_t SBMIDIdetectHardware(uint16_t port, uint8_t irq, uint8_t dma);
int8_t SBMIDIinitHardware(uint16_t port, uint8_t irq, uint8_t dma);
int8_t SBMIDIdeinitHardware(void);


#define  MUS_DRIVER_TYPE_NONE   0
#define  MUS_DRIVER_TYPE_OPL2 	1
#define  MUS_DRIVER_TYPE_OPL3 	2
#define  MUS_DRIVER_TYPE_MPU401 3
#define  MUS_DRIVER_TYPE_SBMIDI 4
#define  MUS_DRIVER_COUNT 5
extern int32_t musdriverstartposition[MUS_DRIVER_COUNT-1];

#define NUMSFX      109


extern uint16_t pcspeaker_currentoffset;
extern uint16_t pcspeaker_endoffset;

extern boolean useDeadAttackerRef;
extern fixed_t_union deadAttackerX;
extern fixed_t_union deadAttackerY;


extern boolean FORCE_5000_LUMP_LOAD;
extern uint8_t currentpageframes[4];


// in order to keep this 8 bytes, not 9 -> we put plauing as a flag on sfx_id which maxes at under 127.
// sfx_id = 0 means not playing anyway so it works out.


typedef struct {

    sfxenum_t          	sfx_id;
	int8_t				samplerate;         // could be figured out from sfxlumpinfo in theory
	uint16_t			length;             // could be figured out from sfxlumpinfo in theory
	uint16_t			currentsample;      // in bytes. could be multiples of 128 or 256 and stored in one byte though.
	int8_t 	 			volume;				// 16-127. 0-15 is mute. 128+ should be undefined?
    //todo eventually implement stereo and sep?
	uint8_t 	 		sep;				// stereo l/r mod
} SB_VoiceInfo ;
#define NUM_SFX_TO_MIX 8
extern SB_VoiceInfo sb_voicelist[NUM_SFX_TO_MIX];

#endif

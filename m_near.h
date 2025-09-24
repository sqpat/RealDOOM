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

// eventually, DS will be fixed to 0x3D00 or so. Then, these will all 
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

#define _NULL_OFFSET 0x30
 

#define segloopnextlookup				  (((int16_t __near*)                (_NULL_OFFSET + 0x0000)))
#define seglooptexrepeat				  (((uint8_t __near*)                (_NULL_OFFSET + 0x0004)))
#define maskedtexrepeat                   (*((int16_t __near*)               (_NULL_OFFSET + 0x0006)))
#define segloopcachedsegment			  (((segment_t __near*)              (_NULL_OFFSET + 0x0008)))
#define segloopheightvalcache			  (((uint8_t __near*)                (_NULL_OFFSET + 0x000C)))
#define eventtail						  (*((int8_t __near*)                (_NULL_OFFSET + 0x000E)))
#define eventhead						  (*((int8_t __near*)                (_NULL_OFFSET + 0x000F)))





//spanfunc_prt[4]
#define spanfunc_prt                    ((int16_t __near *)                  (_NULL_OFFSET + 0x0010))
//spanfunc_destview_offset[4]
#define spanfunc_destview_offset        ((uint16_t __near *)                 (_NULL_OFFSET + 0x0018))
//spanfunc_inner_loop_count[4]
#define spanfunc_inner_loop_count       ((int8_t __near *)                   (_NULL_OFFSET + 0x0020))
//spanfunc_outp[4]
#define spanfunc_outp                   ((uint8_t __near *)                  (_NULL_OFFSET + 0x0024))
#define maxammo                         ((int16_t __near *)                  (_NULL_OFFSET + 0x0028))

#define quality_port_lookup             ((uint8_t __near *)                  (_NULL_OFFSET + 0x0030))
// 3C to 47 free 12 bytes
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
#define map31_exists                    (*((boolean __near*)                 (_NULL_OFFSET + 0x0089)))

//#define MAXSPECIALCROSS		8
//extern int16_t		spechit[MAXSPECIALCROSS];
#define spechit                         (((int16_t  __near*)                 (_NULL_OFFSET + 0x008A)))
#define bombsource                      (*((mobj_t  __near* __near*)         (_NULL_OFFSET + 0x009A)))
#define bombspot                        (*((mobj_t  __near* __near*)         (_NULL_OFFSET + 0x009C)))
#define bombdamage                      (*((int16_t  __near*)                (_NULL_OFFSET + 0x009E)))
#define bombspot_pos                    (*((mobj_pos_t  __far* __near*)      (_NULL_OFFSET + 0x00A0)))

#define spryscale                       (*((fixed_t_union __near *)          (_NULL_OFFSET + 0x00A4)))
#define sprtopscreen                    (*((fixed_t_union __near *)          (_NULL_OFFSET + 0x00A8)))
// todo dont need?
#define nomonsters                      (*((boolean __near*)                 (_NULL_OFFSET + 0x00AC)))
#define respawnmonsters                 (*((boolean __near*)                 (_NULL_OFFSET + 0x00AD)))



#define pendingmusicenum                (*((musicenum_t _near*)              (_NULL_OFFSET + 0x00AE)))
#define pendingmusicenumlooping         (*((boolean _near*)              	 (_NULL_OFFSET + 0x00AF)))
#define skipdirectdraws                 (*(uint8_t __near *)                 (_NULL_OFFSET + 0x00B0))
#define is_ultimate                     (*(boolean __near *)                 (_NULL_OFFSET + 0x00B1))
#define dc_yl                           (*((int16_t __near*)                 (_NULL_OFFSET + 0x00B2)))
#define dc_yh                           (*((int16_t __near*)                 (_NULL_OFFSET + 0x00B4)))
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
#define snd_SfxDevice                   (*(uint8_t __near *)                 (_NULL_OFFSET + 0x00D6))
#define snd_MusicDevice				    (*((uint8_t __near*)                 (_NULL_OFFSET + 0x00D7)))
#define ds_source_segment               (*((byte __far* __near*)             (_NULL_OFFSET + 0x00D8)))
#define ds_source_offset                (*((int16_t __near*)                 (_NULL_OFFSET + 0x00D8)))

#define currentscreen                   (*(byte __far * __near *)            (_NULL_OFFSET + 0x00DC))
#define destview                        (*(byte __far * __near *)            (_NULL_OFFSET + 0x00E0))
#define destscreen                      (*((fixed_t_union __near *)          (_NULL_OFFSET + 0x00E4)))
#define tantoangle_segment              (*((segment_t  __near*)              (_NULL_OFFSET + 0x00E8)))
#define spanfunc_jump_segment_storage   (*((segment_t __near*)               (_NULL_OFFSET + 0x00EA)))

#define totalkills 			            (*(int16_t __near *)                 (_NULL_OFFSET + 0x00EC))
#define totalitems 			            (*(int16_t __near *)                 (_NULL_OFFSET + 0x00EC))
#define totalsecret 		            (*(int16_t __near *)                 (_NULL_OFFSET + 0x00F0))
//f2 unused

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

#define fastparm	                    (*((boolean __near*)                 (_NULL_OFFSET + 0x0100)))
#define gameskill	                    (*((skill_t __near*)                 (_NULL_OFFSET + 0x0101)))

// #define EMS_PAGE                 	    (*((segment_t __near*)               (_NULL_OFFSET + 0x0102)))
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

#define tmflags1                        (*((int16_t __near*)                 (_NULL_OFFSET + 0x0120)))
#define tmfloorz                        (*((short_height_t __near*)          (_NULL_OFFSET + 0x0122)))
#define tmceilingz                      (*((short_height_t __near*)          (_NULL_OFFSET + 0x0124)))
#define tmdropoffz                      (*((short_height_t __near*)          (_NULL_OFFSET + 0x0126)))

#define MULT_4096                       (((uint16_t   __near*)               (_NULL_OFFSET + 0x0128)))
#define FLAT_CACHE_PAGE                 (((uint16_t   __near*)               (_NULL_OFFSET + 0x0130)))
#define visplanelookupsegments          (((segment_t   __near*)              (_NULL_OFFSET + 0x0138)))

#define firstflat                       (*((int16_t    __near*)              (_NULL_OFFSET + 0x013E)))


#define castattacking                   (*((int8_t __near*)                  (_NULL_OFFSET + 0x0140)))
#define castdeath                       (*((int8_t __near*)                  (_NULL_OFFSET + 0x0141)))
#define castonmelee                     (*((int8_t __near*)                  (_NULL_OFFSET + 0x0142)))
#define castframes                      (*((int8_t __near*)                  (_NULL_OFFSET + 0x0143)))
#define casttics                        (*((int8_t __near*)                  (_NULL_OFFSET + 0x0144)))
#define castnum                         (*((int8_t __near*)                  (_NULL_OFFSET + 0x0145)))
#define finaleflat                      (*((int16_t __near*)                 (_NULL_OFFSET + 0x0146)))
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

#define tmx                             (*((fixed_t_union __near*)           (_NULL_OFFSET + 0x0170)))
#define tmy                             (*((fixed_t_union __near*)           (_NULL_OFFSET + 0x0174)))
#define tmxmove                         (*((fixed_t_union __near*)           (_NULL_OFFSET + 0x0178)))
#define tmymove                         (*((fixed_t_union __near*)           (_NULL_OFFSET + 0x017C)))



#define currentpageframes               (((uint8_t    __near*)               (_NULL_OFFSET + 0x0180)))

#if defined(__CH_BLD)
#else
#define emshandle                       (*((int16_t    __near*)              (_NULL_OFFSET + 0x0184)))
#define pagenum9000                     (*((int16_t    __near*)              (_NULL_OFFSET + 0x0186)))
#endif

#define prndindex                       (*((uint8_t    __near*)              (_NULL_OFFSET + 0x0188)))
#define spanquality                     (*((uint8_t __near*)                 (_NULL_OFFSET + 0x0189)))
#define setStateReturn                  (*((mobj_t __near*  __near*)         (_NULL_OFFSET + 0x018A)))
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


#define V_DrawPatchDirect_addr          (*((uint32_t  __near*)               (_NULL_OFFSET + 0x01F4)))
#define deadAttackerX     		  	    (*((fixed_t_union  __near*)   	     (_NULL_OFFSET + 0x01F8)))
#define deadAttackerY     				(*((fixed_t_union  __near*)   	     (_NULL_OFFSET + 0x01FC)))

#define am_scale_mtof     		  	    (*((fixed_t_union  __near*)   	     (_NULL_OFFSET + 0x0200)))
#define am_scale_ftom     				(*((fixed_t_union  __near*)   	     (_NULL_OFFSET + 0x0204)))

#define I_SetPalette_addr               (*((uint32_t  __near*)               (_NULL_OFFSET + 0x0208)))



#define V_MarkRect_addr                 (*((uint32_t  __near*)               (_NULL_OFFSET + 0x020C)))
#define R_SetViewSize_addr    		    (*((uint32_t  __near*)               (_NULL_OFFSET + 0x0210)))

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
#define am_bigstate                     (*((boolean __near*)                 (_NULL_OFFSET + 0x02BA)))
#define commercial                      (*((boolean __near*)                 (_NULL_OFFSET + 0x02BB)))
#define registered                      (*((boolean __near*)                 (_NULL_OFFSET + 0x02BC)))
#define shareware                       (*((boolean __near*)                 (_NULL_OFFSET + 0x02BD)))
#define ds_colormap_index               (*((uint8_t __near*)                 (_NULL_OFFSET + 0x02BE)))
#define fixedcolormap                   (*((uint8_t __near*)                 (_NULL_OFFSET + 0x02BF)))

// more far pointers to functions... once they are in ASM-fixed locations, they should be callable normally
#define FixedMul_addr                   (*((uint32_t  __near*)               (_NULL_OFFSET + 0x02C0)))
#define FixedDiv_addr	                (*((uint32_t  __near*)               (_NULL_OFFSET + 0x02C4)))

#define mus_playing    			      	  (*((int8_t __near*)                (_NULL_OFFSET + 0x02C8)))
#define mus_paused    			      	  (*((int8_t __near*)                (_NULL_OFFSET + 0x02C9)))
#define sendpause    			      	  (*((int8_t __near*)                (_NULL_OFFSET + 0x02CA)))
#define sendsave    			      	  (*((int8_t __near*)                (_NULL_OFFSET + 0x02CB)))



#define R_GetCompositeTexture_addr 	    (*((uint32_t  __near*)               (_NULL_OFFSET + 0x02CC)))

#define sb_voicelist   			      	  ((SB_VoiceInfo __near *)           (_NULL_OFFSET + 0x02D0))
#define savename                          ((int8_t __near *)                 (_NULL_OFFSET + 0x0310))

#define fopen_addr     			          (*((uint32_t  __near*)             (_NULL_OFFSET + 0x0320)))
#define fseek_addr     			          (*((uint32_t  __near*)             (_NULL_OFFSET + 0x0324)))
#define fread_addr     			          (*((uint32_t  __near*)             (_NULL_OFFSET + 0x0328)))
#define fclose_addr    			          (*((uint32_t  __near*)             (_NULL_OFFSET + 0x032C)))
#define locallib_far_fread_addr    		  (*((uint32_t  __near*)             (_NULL_OFFSET + 0x0330)))
#define S_InitSFXCache_addr     		  (*((uint32_t  __near*)             (_NULL_OFFSET + 0x0334)))


#define demoplayback					(*((boolean __near*)                 (_NULL_OFFSET + 0x0338)))
#define columnquality                   (*((uint8_t __near*)                 (_NULL_OFFSET + 0x0339)))
#define useDeadAttackerRef				(*((boolean __near*)                 (_NULL_OFFSET + 0x033A)))
#define paused							(*((boolean __near*)                 (_NULL_OFFSET + 0x033B)))
#define menuactive						(*((boolean __near*)                 (_NULL_OFFSET + 0x033C)))
#define followplayer					(*((boolean __near*)                 (_NULL_OFFSET + 0x033D)))
#define am_cheating						(*((boolean __near*)                 (_NULL_OFFSET + 0x033E)))
#define am_grid 						(*((boolean __near*)                 (_NULL_OFFSET + 0x033F)))



// 33d to 33F free



// 12 bytes each. two for 24.
#define psprites                        (((pspdef_t __near*)                 (_NULL_OFFSET + 0x0340))) 
#define vga_read_port_lookup            (((uint16_t __near*)                 (_NULL_OFFSET + 0x0358)))

#define vissprite_p                     (*((int16_t __near*)                 (_NULL_OFFSET + 0x0370)))
#define cachedbyteheight                (*((uint8_t __near*)                 (_NULL_OFFSET + 0x0372)))
// dont use this byte!!! its always 0 on purpose.
#define currentMusPage					(*((uint8_t __near*)                 (_NULL_OFFSET + 0x0374)))
#define snd_MusicVolume                 (*((uint8_t __near*)                 (_NULL_OFFSET + 0x0375)))
#define gameepisode                     (*((int8_t __near*)                  (_NULL_OFFSET + 0x0376)))
#define gamemap                         (*((int8_t __near*)                  (_NULL_OFFSET + 0x0377)))
#define savedescription                 (((int8_t    __near*)                (_NULL_OFFSET + 0x0378)))
//todo this is big???
#define demoname                        (((int8_t    __near*)                (_NULL_OFFSET + 0x0398)))

// #define ems_backfill_page_order         (((int8_t    __near*)                (_NULL_OFFSET + 0x03B8)))

#define skytexture 						(*((uint16_t __near*)                (_NULL_OFFSET + 0x03B8)))
#define numflats  						(*((int16_t __near*)                 (_NULL_OFFSET + 0x03BA)))
#define numpatches  					(*((int16_t __near*)                 (_NULL_OFFSET + 0x03BC)))
#define numspritelumps  				(*((int16_t __near*)                 (_NULL_OFFSET + 0x03BE)))
#define numtextures  					(*((int16_t __near*)                 (_NULL_OFFSET + 0x03C0)))

#define pcspeaker_currentoffset         (*((uint16_t __near*)                (_NULL_OFFSET + 0x03C2)))
#define pcspeaker_endoffset       	    (*((uint16_t __near*)                (_NULL_OFFSET + 0x03C4)))
#define SKY_String       	            (((int8_t    __near*)                (_NULL_OFFSET + 0x03C6)))
#define numChannels  					(*((uint8_t __near*)                 (_NULL_OFFSET + 0x03CB)))

// #define MainLogger_addr       	        (*((uint32_t  __near*)               (_NULL_OFFSET + 0x03CC)))

//33B to 3cf free

#define am_stopped						(*((boolean __near*)                 (_NULL_OFFSET + 0x03D0)))
#define automapactive					(*((boolean __near*)                 (_NULL_OFFSET + 0x03D1)))


#define currentThinkerListHead  		(*((int16_t __near*)                 (_NULL_OFFSET + 0x03D2)))

#define FixedMulTrigSpeed_addr	 	    (*((uint32_t  __near*)               (_NULL_OFFSET + 0x03D4)))
#define demo_p					 	    (*((uint32_t  __near*)               (_NULL_OFFSET + 0x03D8)))

#define I_WaitVBL_addr                  (*((uint32_t  __near*)               (_NULL_OFFSET + 0x03DC)))




#define braintargets                    (((THINKERREF __near*)               (_NULL_OFFSET + 0x03E0)))
#define tmbbox                          (((fixed_t_union __near*)            (_NULL_OFFSET + 0x0420)))

#define SECTORS_SEGMENT_PTR				  (*((segment_t __near*)             (_NULL_OFFSET + 0x0430)))
#define LINES_PHYSICS_SEGMENT_PTR	      (*((segment_t __near*)             (_NULL_OFFSET + 0x0432)))
#define VERTEXES_SEGMENT_PTR	          (*((segment_t __near*)             (_NULL_OFFSET + 0x0434)))
#define LINEFLAGSLIST_SEGMENT_PTR	  	  (*((segment_t __near*)             (_NULL_OFFSET + 0x0436)))
#define SEENLINES_6000_SEGMENT_PTR	      (*((segment_t __near*)             (_NULL_OFFSET + 0x0438)))
#define SIDES_SEGMENT_PTR		          (*((segment_t __near*)             (_NULL_OFFSET + 0x043A)))
// #define LUMPINFO_SEGMENT_PTR		      (*((segment_t __near*)             (_NULL_OFFSET + 0x043C)))
// 43e free
// todo order all these for stosw chain
#define EMS_PAGE                 	      (*((segment_t __near*)             (_NULL_OFFSET + 0x0440)))
#define MUSIC_PAGE_SEGMENT_PTR            (*((segment_t __near*)             (_NULL_OFFSET + 0x0440)))
#define SFX_PAGE_SEGMENT_PTR		      (*((segment_t __near*)             (_NULL_OFFSET + 0x0442)))
#define PC_SPEAKER_OFFSETS_SEGMENT_PTR    (*((segment_t __near*)             (_NULL_OFFSET + 0x0444)))
#define PC_SPEAKER_SFX_DATA_SEGMENT_PTR   (*((segment_t __near*)             (_NULL_OFFSET + 0x0446)))
#define WAD_PAGE_FRAME_PTR		          (*((segment_t __near*)             (_NULL_OFFSET + 0x0448)))
#define BSP_CODE_SEGMENT_PTR		      (*((segment_t __near*)             (_NULL_OFFSET + 0x044A)))


#define FixedMulTrig_addr 				  (*((uint32_t __near*)              (_NULL_OFFSET + 0x044C)))
// #define G_DeferedInitNew_addr			  (*((uint32_t __near*)              (_NULL_OFFSET + 0x0450)))

#define d_skill                           (*(skill_t __near *)                (_NULL_OFFSET + 0x0450))
#define d_episode                         (*(int8_t  __near *)                (_NULL_OFFSET + 0x0451))
#define d_map                             (*(int8_t  __near *)                (_NULL_OFFSET + 0x0452))
#define secretexit                        (*(boolean __near *)                (_NULL_OFFSET + 0x0453))


#define V_DrawPatch_addr                  (*((uint32_t  __near*)             (_NULL_OFFSET + 0x0454)))
#define m_paninc                          (*((mpoint_t __near*)              (_NULL_OFFSET + 0x0458)))

#define FixedMulTrigSpeedNoShift_addr	  (*((uint32_t __near*)              (_NULL_OFFSET + 0x045C)))
#define V_DrawFullscreenPatch_addr        (*((uint32_t  __near*)             (_NULL_OFFSET + 0x0460)))
#define getStringByIndex_addr             (*((uint32_t  __near*)             (_NULL_OFFSET + 0x0464)))
#define ST_Start_addr 				      (*((uint32_t __near*)              (_NULL_OFFSET + 0x0468)))

#define FixedMulTrigNoShift_addr	      (*((uint32_t  __near*)             (_NULL_OFFSET + 0x046C)))
#define R_PointToAngle2_16_addr           (*((uint32_t  __near*)             (_NULL_OFFSET + 0x0470)))
#define R_PointToAngle2_addr              (*((uint32_t  __near*)             (_NULL_OFFSET + 0x0474)))
#define W_CacheLumpNameDirect_addr        (*((uint32_t  __near*)             (_NULL_OFFSET + 0x0478)))
#define W_CacheLumpNumDirectFragment_addr (*((uint32_t  __near*)             (_NULL_OFFSET + 0x047C)))
#define W_GetNumForName_addr              (*((uint32_t  __near*)             (_NULL_OFFSET + 0x0480)))
#define SFX_PlayPatch_addr  			  (*((uint32_t __near*)              (_NULL_OFFSET + 0x0484)))
#define S_DecreaseRefCountFar_addr  	  (*((uint32_t __near*)              (_NULL_OFFSET + 0x0488)))
// 13 bytes (12345678.123) fileame format incl . and null term
#define filename_argument                 ((int8_t __near *)                 (_NULL_OFFSET + 0x048C))
#define rndindex                          (*(uint8_t __near *)               (_NULL_OFFSET + 0x0499))
#define fopen_r_argument                  ((int8_t __near *)                 (_NULL_OFFSET + 0x049A))
#define fopen_w_argument                  ((int8_t __near *)                 (_NULL_OFFSET + 0x049C))
#define numsectors                        (*(int16_t __near *)               (_NULL_OFFSET + 0x049E))
#define numlines                          (*(int16_t __near *)               (_NULL_OFFSET + 0x04A0))
#define numvertexes                       (*(int16_t __near *)               (_NULL_OFFSET + 0x04A2))
#define numsegs                           (*(int16_t __near *)               (_NULL_OFFSET + 0x04A4))
#define numsubsectors                     (*(int16_t __near *)               (_NULL_OFFSET + 0x04A6))
#define numnodes                          (*(int16_t __near *)               (_NULL_OFFSET + 0x04A8))
#define numsides                          (*(int16_t __near *)               (_NULL_OFFSET + 0x04AA))
#define bmapwidth                         (*(int16_t __near *)               (_NULL_OFFSET + 0x04AC))
#define bmapheight                        (*(int16_t __near *)               (_NULL_OFFSET + 0x04AE))
#define bmaporgx                          (*(int16_t __near *)               (_NULL_OFFSET + 0x04B0))
#define bmaporgy                          (*(int16_t __near *)               (_NULL_OFFSET + 0x04B2))
#define I_Error_addr                      (*((uint32_t __near*)              (_NULL_OFFSET + 0x04B4)))
#define P_InitThinkers_addr               (*((uint32_t __near*)              (_NULL_OFFSET + 0x04B8)))

#define snd_DesiredSfxDevice     		  (*((uint8_t __near*)               (_NULL_OFFSET + 0x04BC)))
#define snd_DesiredMusicDevice     		  (*((uint8_t __near*)               (_NULL_OFFSET + 0x04BD)))
#define snd_SBirq		        		  (*((uint8_t __near*)               (_NULL_OFFSET + 0x04BE)))
#define snd_SBdma		        		  (*((uint8_t __near*)               (_NULL_OFFSET + 0x04BF)))

#define R_DrawSkyPlaneDynamic_addr_Offset (*((int16_t __near*)               (_NULL_OFFSET + 0x04C4)))
#define R_DrawSkyPlaneDynamic_addr    	  (*((uint32_t __near*)              (_NULL_OFFSET + 0x04C4)))

#define snd_SBport						  (*((uint16_t __near*)              (_NULL_OFFSET + 0x04C8)))
#define snd_Mport						  (*((uint16_t __near*)              (_NULL_OFFSET + 0x04CA)))

#define I_Quit_addr						  (*((uint32_t __near*)              (_NULL_OFFSET + 0x04CC)))

// 52 bytes
#define player_message_string             ((int8_t __near *)                 (_NULL_OFFSET + 0x04D0))


#define screen_botleft_x				  (*((int16_t __near*)               (_NULL_OFFSET + 0x0504)))
#define screen_botleft_y				  (*((int16_t __near*)               (_NULL_OFFSET + 0x0506)))
#define screen_topright_x				  (*((int16_t __near*)               (_NULL_OFFSET + 0x0508)))
#define screen_topright_y				  (*((int16_t __near*)               (_NULL_OFFSET + 0x050A)))
#define Z_SetOverlay_addr                 (*((uint32_t __near*)              (_NULL_OFFSET + 0x050C)))
#define W_LumpLength_addr                 (*((uint32_t __near*)              (_NULL_OFFSET + 0x0510)))
#define playingdriver                     (*((driverBlock __far* __near *)   (_NULL_OFFSET + 0x0514)))
#define currentsong_start_offset          (*((uint16_t __near*)              (_NULL_OFFSET + 0x0518)))
#define currentsong_playing_offset        (*((uint16_t __near*)              (_NULL_OFFSET + 0x051A)))
#define currentsong_ticks_to_process      (*((int16_t __near*)               (_NULL_OFFSET + 0x051C)))
#define loops_enabled    			      (*((int8_t __near*)                (_NULL_OFFSET + 0x051E)))
#define inhelpscreens    			      (*((boolean __near*)               (_NULL_OFFSET + 0x051F)))


#define Z_QuickMapMusicPageFrame_addr     (*((uint32_t __near*)              (_NULL_OFFSET + 0x0520)))

#define sightzstart					      (*((fixed_t __near*)         		 (_NULL_OFFSET + 0x0524)))
#define topslope					      (*((fixed_t __near*)         		 (_NULL_OFFSET + 0x0528)))
#define bottomslope					      (*((fixed_t __near*)         		 (_NULL_OFFSET + 0x052C)))
#define cachedt2x					      (*((fixed_t_union __near*)         (_NULL_OFFSET + 0x0530)))
#define cachedt2y					      (*((fixed_t_union __near*)         (_NULL_OFFSET + 0x0534)))
#define strace					          (*((divline_t __near*)             (_NULL_OFFSET + 0x0538)))

// free bytes per EMS page. Allocated in 256k chunks, so defaults to 64.. 
// leave what, 40 bytes just in case?
// todo move this to bottom and make it growable...
#define sfx_free_bytes					  (((uint8_t __near*)                (_NULL_OFFSET + 0x0548)))


// 0x570

#define activespritepages				  (((uint8_t __near*)                (_NULL_OFFSET + 0x0570)))
#define activespritenumpages			  (((uint8_t __near*)                (_NULL_OFFSET + 0x0574)))
#define spriteL1LRU						  (((uint8_t __near*)                (_NULL_OFFSET + 0x0578)))
#define spritecache_l2_head				  (*((uint8_t __near*)               (_NULL_OFFSET + 0x057C)))
#define spritecache_l2_tail				  (*((uint8_t __near*)               (_NULL_OFFSET + 0x057D)))
#define texturecache_l2_head			  (*((uint8_t __near*)               (_NULL_OFFSET + 0x057E)))
#define texturecache_l2_tail			  (*((uint8_t __near*)               (_NULL_OFFSET + 0x057F)))
#define activetexturepages				  (((uint8_t __near*)                (_NULL_OFFSET + 0x0580)))
#define activenumpages					  (((uint8_t __near*)                (_NULL_OFFSET + 0x0588)))
#define textureL1LRU					  (((uint8_t __near*)                (_NULL_OFFSET + 0x0590)))
#define cachedsegmentlumps				  (((segment_t __near*)              (_NULL_OFFSET + 0x0598)))
#define cachedlumps					 	  (((int16_t __near*)                (_NULL_OFFSET + 0x05A0)))
#define cachedtex				  		  (((int16_t __near*)                (_NULL_OFFSET + 0x05A8)))
#define cachedcollength				      (((uint8_t __near*)                (_NULL_OFFSET + 0x05AC)))
#define flatcache_l2_head				  (*((uint8_t __near*)               (_NULL_OFFSET + 0x05AE)))
#define flatcache_l2_tail				  (*((uint8_t __near*)               (_NULL_OFFSET + 0x05AF)))
#define segloopprevlookup				  (((int16_t __near*)                (_NULL_OFFSET + 0x05B0)))
#define segloopcachedbasecol			  (((int16_t __near*)                (_NULL_OFFSET + 0x05B4)))
#define cachedsegmenttex				  (((segment_t __near*)              (_NULL_OFFSET + 0x05B8)))

#define playerMobj	     				  (*((mobj_t __near*  __near*)       (_NULL_OFFSET + 0x05BC)))

#define ceilinglinenum				      (*((int16_t __near*)               (_NULL_OFFSET + 0x05BE)))

#define lineopening  				      (*((lineopening_t __near*)         (_NULL_OFFSET + 0x05C0)))
#define playerMobjRef  				      (*((THINKERREF __near*)         	 (_NULL_OFFSET + 0x05C6)))


#define intercept_p  				      (*((intercept_t __far* __near*)    (_NULL_OFFSET + 0x05C8)))
#define aimslope     				      (*((fixed_t_union  __near*)   	 (_NULL_OFFSET + 0x05CC)))
#define bestslidefrac     				  (*((fixed_t_union  __near*)   	 (_NULL_OFFSET + 0x05D0)))
#define bestslidelinenum		          (*((int16_t __near*)               (_NULL_OFFSET + 0x05D4)))
#define numspechit		   			      (*((int16_t __near*)               (_NULL_OFFSET + 0x05D6)))
#define lastcalculatedsector		      (*((int16_t __near*)               (_NULL_OFFSET + 0x05D8)))

#define shootthing	     				  (*((mobj_t __near*  __near*)       (_NULL_OFFSET + 0x05DA)))
#define shootz     				  		  (*((fixed_t_union  __near*)   	 (_NULL_OFFSET + 0x05DC)))

#define la_damage		   			      (*((int16_t __near*)               (_NULL_OFFSET + 0x05E0)))

#define linetarget	     				  (*((mobj_t  __near* __near*)       (_NULL_OFFSET + 0x05E2)))
#define linetarget_pos  			      (*((mobj_pos_t __far* __near*)     (_NULL_OFFSET + 0x05E4)))
#define attackrange16		   		      (*((int16_t __near*)               (_NULL_OFFSET + 0x05E8)))


#define usergame		   		          (*((boolean __near*)               (_NULL_OFFSET + 0x05EA)))
#define crushchange		   		          (*((boolean __near*)               (_NULL_OFFSET + 0x05EB)))
#define leveltime     				      (*((fixed_t_union  __near*)   	 (_NULL_OFFSET + 0x05EC)))
#define fopen_rb_argument                 ((int8_t __near *)                 (_NULL_OFFSET + 0x05F0))
#define currenttask                       (*(int8_t __near *)                (_NULL_OFFSET + 0x05F3))

#define R_DrawSkyPlane_addr_Offset        (*((int16_t __near*)               (_NULL_OFFSET + 0x05F4)))
#define R_DrawSkyPlane_addr    			  (*((uint32_t __near*)              (_NULL_OFFSET + 0x05F4)))
#define OutOfThinkers_addr 				  (*((uint32_t __near*)              (_NULL_OFFSET + 0x05F8)))
#define FastDiv32u16u_addr 				  (*((uint32_t __near*)              (_NULL_OFFSET + 0x05FC)))

#define playerMobj_pos   		     	  (*((mobj_pos_t __far* __near*)     (_NULL_OFFSET + 0x0600)))
#define setStateReturn_pos	 	    	  (*((mobj_pos_t __far* __near*)     (_NULL_OFFSET + 0x0604)))
#define gametic						      (*((ticcount_t __near*)   	   	 (_NULL_OFFSET + 0x0608)))

#define clipangle       			      (*((uint16_t __near*)              (_NULL_OFFSET + 0x060C)))
#define fieldofview       			      (*((uint16_t __near*)              (_NULL_OFFSET + 0x060E)))
#define solidsegs                 		  ((cliprange_t __near *)            (_NULL_OFFSET + 0x0610))
#define newend	     		    		  (*((cliprange_t  __near* __near*)  (_NULL_OFFSET + 0x0690)))
#define pspritescale       		  	      (*((uint16_t __near*)              (_NULL_OFFSET + 0x0692)))
// #define SPRITEWIDTHS_SEGMENT_PTR   		  (*((segment_t __near*)             (_NULL_OFFSET + 0x0694)))
#define r_cachedplayerMobjsecnum 		  (*((int16_t __near*)               (_NULL_OFFSET + 0x0696)))
#define scaledviewwidth 		 		  (*((int16_t __near*)               (_NULL_OFFSET + 0x0698)))
#define viewwindowoffset 		 		  (*((int16_t __near*)               (_NULL_OFFSET + 0x069A)))
#define pendingdetail 		 			  (*((int16_t __near*)               (_NULL_OFFSET + 0x069C)))
#define setsizeneeded                     (*((uint8_t    __near*)            (_NULL_OFFSET + 0x069E)))
#define setblocks                   	  (*((uint8_t    __near*)            (_NULL_OFFSET + 0x069F)))
//99 bytes
#define player 		 					  (*((player_t __near*)              (_NULL_OFFSET + 0x06A0)))

#define skyquality  					  (*(int8_t __near *)                (_NULL_OFFSET + 0x0703))
#define viewwindowx 		 			  (*((int16_t __near*)               (_NULL_OFFSET + 0x0704)))
#define viewwindowy 		 			  (*((int16_t __near*)               (_NULL_OFFSET + 0x0706)))
#define R_DrawPlanesCall 		 		  (*((uint32_t __near*)              (_NULL_OFFSET + 0x0708)))
#define R_DrawPlanesCallOffset 			  (*((int16_t __near*)               (_NULL_OFFSET + 0x0708)))
#define R_DrawMaskedCall 		 		  (*((uint32_t __near*)              (_NULL_OFFSET + 0x070C)))
#define R_DrawMaskedCallOffset 		      (*((int16_t __near*)               (_NULL_OFFSET + 0x070C)))
#define R_WriteBackMaskedFrameConstantsCall  (*((uint32_t __near*)           (_NULL_OFFSET + 0x0710)))
#define R_WriteBackMaskedFrameConstantsCallOffset (*((int16_t __near*)       (_NULL_OFFSET + 0x0710)))
#define NetUpdate_addr					  (*((uint32_t __near*)              (_NULL_OFFSET + 0x0714)))


#define mtof_zoommul        			  (*((int16_t __near*)               (_NULL_OFFSET + 0x0718)))
#define ftom_zoommul        			  (*((int16_t __near*)               (_NULL_OFFSET + 0x071A)))
#define am_max_scale_mtof       		  (*((int16_t __near*)               (_NULL_OFFSET + 0x071C)))



#define FastDiv3216u_addr				  (*((uint32_t __near*)              (_NULL_OFFSET + 0x0720)))

#define bulletslope     				  (*((fixed_t_union  __near*)   	 (_NULL_OFFSET + 0x0724)))
#define weaponinfo 						  ((weaponinfo_t __near *)           (_NULL_OFFSET + 0x0728))
// #define G_ExitLevel_addr 				  (*((uint32_t __near*)              (_NULL_OFFSET + 0x078C)))


#define gametime 						  (*((ticcount_t __near*)            (_NULL_OFFSET + 0x0790)))
#define maketic 						  (*((ticcount_t __near*)            (_NULL_OFFSET + 0x0794)))
#define starttime 						  (*((ticcount_t __near*)            (_NULL_OFFSET + 0x0798)))
#define oldentertics					  (*((uint16_t __near*)              (_NULL_OFFSET + 0x079C)))
#define inhelpscreensstate				  (*((boolean __near*)               (_NULL_OFFSET + 0x079E)))
#define fullscreen						  (*((boolean __near*)               (_NULL_OFFSET + 0x079F)))

// todo put wad fields somewhere with roof to grow should the constant grow?
#define wadfiles 						  ((FILE* __near *)           	 (_NULL_OFFSET + 0x07A0))
#define filetolumpindex 				  ((int16_t __near *)           	 (_NULL_OFFSET + 0x07A8))
#define numlumps						  (*((uint16_t __near*)              (_NULL_OFFSET + 0x07AE)))
#define filetolumpsize 					  ((int32_t __near *)            	 (_NULL_OFFSET + 0x07B0))
#define currentloadedfileindex     		  (*((int8_t __near*)                (_NULL_OFFSET + 0x07BC)))
#define mousepresent     				  (*((boolean __near*)               (_NULL_OFFSET + 0x07BD)))
#define respawnparm       				  (*((boolean __near*)               (_NULL_OFFSET + 0x07BE)))
#define demorecording     				  (*((boolean __near*)               (_NULL_OFFSET + 0x07BF)))
#define doomsav0_string                   ((uint8_t __near *)                (_NULL_OFFSET + 0x07C0))



// 7CD to 7DF empty
#define screen_oldloc					  (*((mpoint_t __near*)              (_NULL_OFFSET + 0x07E0)))
#define old_screen_botleft_x			  (*((int16_t __near*)               (_NULL_OFFSET + 0x07E4)))
#define old_screen_botleft_y			  (*((int16_t __near*)               (_NULL_OFFSET + 0x07E6)))



#define message_counter					  (*((uint8_t    __near*)            (_NULL_OFFSET + 0x07E8)))

#define levelTimer                   	  (*((boolean    __near*)            (_NULL_OFFSET + 0x07E9)))
#define numlinespecials     			  (*((int16_t __near*)               (_NULL_OFFSET + 0x07EA)))

#define activeceilings                    ((THINKERREF __near *)             (_NULL_OFFSET + 0x07EC))
#define activeplats                       ((THINKERREF __near *)             (_NULL_OFFSET + 0x0828))
#define buttonlist                        ((button_t __near *)               (_NULL_OFFSET + 0x0864))
#define levelTimeCount                    (*((ticcount_t __near *)           (_NULL_OFFSET + 0x0888)))
#define lastanim                          (*((p_spec_anim_t __near* __near*) (_NULL_OFFSET + 0x088C)))
#define numswitches     			      (*((int16_t __near*)               (_NULL_OFFSET + 0x088E)))
#define anims                             ((p_spec_anim_t __near *)          (_NULL_OFFSET + 0x0890))

#define switchlist				          (((uint16_t __near*)           	 (_NULL_OFFSET + 0x0950)))

#define skullAnimCounter   			      (*((int16_t __near*)               (_NULL_OFFSET + 0x0A18)))
#define whichSkull       			      (*((int16_t __near*)               (_NULL_OFFSET + 0x0A1A)))
#define borderdrawcount       		      (*((boolean __near*)               (_NULL_OFFSET + 0x0A1C)))
#define message_dontfuckwithme     	      (*((boolean __near*)               (_NULL_OFFSET + 0x0A1D)))
#define message_on     				      (*((boolean __near*)               (_NULL_OFFSET + 0x0A1E)))
#define message_nottobefuckedwith         (*((boolean __near*)               (_NULL_OFFSET + 0x0A1F)))


// #define STRING_HELP1                      ((int8_t __near *)                 (_NULL_OFFSET + 0x0A20))
// #define STRING_HELP2                      ((int8_t __near *)                 (_NULL_OFFSET + 0x0A26))
// #define STRING_HELP                       ((int8_t __near *)                 (_NULL_OFFSET + 0x0A2C))

#define demosequence	       		      (*((boolean __near*)               (_NULL_OFFSET + 0x0A31)))

#define STRING_newline                    ((int8_t __near *)                 (_NULL_OFFSET + 0x0A32))

#define advancedemo	       			      (*((boolean __near*)               (_NULL_OFFSET + 0x0A34)))
#define usegamma	       			      (*((boolean __near*)               (_NULL_OFFSET + 0x0A35)))
#define sfxVolume	       			      (*((boolean __near*)               (_NULL_OFFSET + 0x0A36)))
#define musicVolume	       			      (*((boolean __near*)               (_NULL_OFFSET + 0x0A37)))
#define snd_SfxVolume      			      (*((boolean __near*)               (_NULL_OFFSET + 0x0A38)))
#define detailLevel	       			      (*((boolean __near*)               (_NULL_OFFSET + 0x0A39)))
#define screenSize	       			      (*((boolean __near*)               (_NULL_OFFSET + 0x0A3A)))
#define mouseSensitivity   			      (*((boolean __near*)               (_NULL_OFFSET + 0x0A3B)))
#define showMessages       			      (*((boolean __near*)               (_NULL_OFFSET + 0x0A3C)))
#define quickSaveSlot      			      (*((boolean __near*)               (_NULL_OFFSET + 0x0A3D)))
#define savegameslot       			      (*((boolean __near*)               (_NULL_OFFSET + 0x0A3E)))
#define modifiedgame       			      (*((boolean __near*)               (_NULL_OFFSET + 0x0A3F)))
#define hu_font                           ((uint16_t __near *)               (_NULL_OFFSET + 0x0A40))

#define viewactivestate   			      (*((boolean __near*)               (_NULL_OFFSET + 0x0ABE)))
#define menuactivestate   			      (*((boolean __near*)               (_NULL_OFFSET + 0x0ABF)))
#define fopen_wb_argument                 ((int8_t __near *)                 (_NULL_OFFSET + 0x0AC0))
#define domapcheatthisframe 		      (*((boolean __near*)               (_NULL_OFFSET + 0x0AC3)))
#define st_gamestate 		      		  (*((st_stateenum_t __near*)        (_NULL_OFFSET + 0x0AC4)))
#define st_firsttime 		      		  (*((boolean __near*)        		 (_NULL_OFFSET + 0x0AC5)))
#define am_min_scale_mtof       	      (*((int16_t __near*)               (_NULL_OFFSET + 0x0AC6)))
#define screen_viewport_width 		      (*((int16_t __near*)        		 (_NULL_OFFSET + 0x0AC8)))
#define screen_viewport_height 		      (*((int16_t __near*)        		 (_NULL_OFFSET + 0x0ACA)))
#define old_screen_viewport_width 		  (*((int16_t __near*)        		 (_NULL_OFFSET + 0x0ACC)))
#define old_screen_viewport_height 		  (*((int16_t __near*)        		 (_NULL_OFFSET + 0x0ACE)))
#define FixedDivWholeA_addr	  		      (*((uint32_t __near*)              (_NULL_OFFSET + 0x0AD0)))
#define cht_CheckCheat_Far_addr	 	      (*((uint32_t __near*)              (_NULL_OFFSET + 0x0AD4)))

// ad8, adc unused



#define flatcache_nodes				      (((cache_node_t __near*)           (_NULL_OFFSET + 0x0AE0)))

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
#define pageswapargs				  	  (((uint16_t __near*) (CURRENT_POSITION_6)))
#define CURRENT_POSITION_7  			  (((uint16_t) pageswapargs) + (sizeof(uint16_t) * total_pages))
#define END_OF_FIXED_DATA  			 	  (((uint16_t __near*) (CURRENT_POSITION_7)))

#define MUS_SIZE_PER_PAGE 16256

// wipegamestate can be set to -1 to force a wipe on the next draw


#define MAXWADFILES             3

extern boolean              singletics;


extern skill_t              startskill;
extern int8_t               startepisode;
extern int8_t               startmap;
extern boolean              autostart;


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





extern void (__far* R_RenderPlayerView)();
extern void (__far* R_WriteBackViewConstantsMaskedCall)();
extern void (__far* R_WriteBackViewConstants)();
extern void 				(__far* R_WriteBackViewConstantsSpanCall)();
extern void 				(__far* P_SpawnMapThing)();
extern void					(__far* P_SpawnSpecials)();
extern void					(__far* P_GivePower)();

extern void (__far* AM_Drawer)();

extern void (__far* S_Start	)();
extern void (__far* S_StartSound)();
extern void (__far* M_Init)();



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
// REGS stuff used for int calls

extern boolean novideo; // if true, stay in text mode for debugging
#define KBDQUESIZE 32

extern void (__interrupt __far_func *oldkeyboardisr) (void);
extern gamestate_t         oldgamestate;



#define BACKUPTICS		16
#define NUMKEYS         256 


 

extern boolean         	  timingdemo;             // if true, exit with report on completion 
extern boolean         	  noblit;                 // for comparative timing purposes 





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

extern int8_t             turnheld;
extern boolean         mousearray[4]; 
extern boolean*        mousebuttons;




extern int16_t		myargc;
extern int8_t**		myargv;
extern uint8_t		usemouse;


extern int8_t __far*   defdemoname; 


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



extern int8_t     st_stuff_buf[ST_MSGWIDTH];


extern task HeadTask;
extern task MUSTask;

extern void( __interrupt __far_func *OldInt8)(void);
extern volatile uint16_t TaskServiceCount;

extern volatile int8_t TS_TimesInInterrupt;
extern int8_t TS_Installed;
extern volatile int8_t TS_InInterrupt;

#define castorderoffset CC_ZOMBIE
 

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

typedef struct {

    boolean	istexture;
    uint8_t		numpics;
	uint16_t		picnum;
	uint16_t		basepic;
    
} p_spec_anim_t;



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
extern int32_t musdriverstartposition;

#define NUMSFX      109







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

#endif

extern uint16_t lastpcspeakernotevalue;

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


#define NUM_CACHE_LUMPS 4

#define NUM_TEXTURE_L1_CACHE_PAGES 8
#define NUM_SPRITE_L1_CACHE_PAGES 4



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

#define currentscreen                   (*(byte __far * __near *)            (_NULL_OFFSET + 0x0000))
#define destview                        (*(byte __far * __near *)            (_NULL_OFFSET + 0x0004))
#define destscreen                      (*((fixed_t_union __near *)          (_NULL_OFFSET + 0x0008)))
#define tantoangle                      (*((segment_t  __near*)              (_NULL_OFFSET + 0x000C)))
#define spanfunc_jump_segment_storage   (*((segment_t __near*)               (_NULL_OFFSET + 0x000E)))
#define olddb                           ((int16_t __near *)                  (_NULL_OFFSET + 0x0010))
// 0 = high, 1 = low, = 2 potato
#define detailshift                     (*((int16_t_union __near*)           (_NULL_OFFSET + 0x0020)))
#define detailshiftitercount            (*((uint8_t __near*)                 (_NULL_OFFSET + 0x0022)))
#define detailshiftandval               (*((uint16_t __near*)                (_NULL_OFFSET + 0x0024)))

#define ceilphyspage                    (*((int8_t __near*)                  (_NULL_OFFSET + 0x0026)))
#define floorphyspage                   (*((int8_t __near*)                  (_NULL_OFFSET + 0x0027)))
#define gameaction                      (*((gameaction_t __near*)            (_NULL_OFFSET + 0x0028)))
#define viewactive                      (*((boolean __near*)                 (_NULL_OFFSET + 0x0029)))
#define automapactive                   (*((boolean __near*)                 (_NULL_OFFSET + 0x002A)))
#define commercial                      (*((boolean __near*)                 (_NULL_OFFSET + 0x002B)))
#define registered                      (*((boolean __near*)                 (_NULL_OFFSET + 0x002C)))
#define shareware                       (*((boolean __near*)                 (_NULL_OFFSET + 0x002D)))
#define ds_colormap_index               (*((uint8_t __near*)                 (_NULL_OFFSET + 0x002E)))
#define fixedcolormap                   (*((uint8_t __near*)                 (_NULL_OFFSET + 0x002F)))
#define quality_port_lookup             ((uint8_t __near *)                  (_NULL_OFFSET + 0x0030))
#define ds_source_segment               (*((byte __far* __near*)             (_NULL_OFFSET + 0x003C)))
#define gameepisode                     (*((int8_t __near*)                  (_NULL_OFFSET + 0x0040)))
#define gamemap                         (*((int8_t __near*)                  (_NULL_OFFSET + 0x0041)))
#define dc_colormap_index               (*((uint8_t __near*)                 (_NULL_OFFSET + 0x0042)))
#define fuzzpos                         (*((int8_t __near*)                  (_NULL_OFFSET + 0x0043)))
#define dc_yl                           (*((int16_t __near*)                 (_NULL_OFFSET + 0x0044)))
#define dc_yh                           (*((int16_t __near*)                 (_NULL_OFFSET + 0x0046)))
#define castattacking                   (*((int8_t __near*)                  (_NULL_OFFSET + 0x0048)))
#define castdeath                       (*((int8_t __near*)                  (_NULL_OFFSET + 0x0049)))
#define castonmelee                     (*((int8_t __near*)                  (_NULL_OFFSET + 0x004A)))
#define castframes                      (*((int8_t __near*)                  (_NULL_OFFSET + 0x004B)))
#define casttics                        (*((int8_t __near*)                  (_NULL_OFFSET + 0x004C)))
#define castnum                         (*((int8_t __near*)                  (_NULL_OFFSET + 0x004D)))
#define finaleflat                      (*((int16_t __near*)                 (_NULL_OFFSET + 0x004E)))

#define dc_x                            (*((int16_t __near*)                 (_NULL_OFFSET + 0x0050)))
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
#define viewangle_shiftright1           (*((uint16_t __near *)               (_NULL_OFFSET + 0x007E)))
#define viletryx                        (*((fixed_t_union __near*)           (_NULL_OFFSET + 0x0080)))
#define viletryy                        (*((fixed_t_union __near*)           (_NULL_OFFSET + 0x0084)))

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
//#define filename_argument               ((int8_t __near *)                   (_NULL_OFFSET + 0x00AC))
#define is_ultimate                     (*(boolean __near *)                 (_NULL_OFFSET + 0x00B5))
#define firstspritelump                 (*(int16_t  __near *)                (_NULL_OFFSET + 0x00B6))
#define finaletext                      (*((int16_t __near*)                 (_NULL_OFFSET + 0x00B8)))
#define finalecount                     (*((int16_t __near*)                 (_NULL_OFFSET + 0x00BA)))
#define finalestage                     (*((int16_t __near*)                 (_NULL_OFFSET + 0x00BC)))
#define finale_laststage                (*((int8_t __near*)                  (_NULL_OFFSET + 0x00BE)))
// BF free
#define mfloorclip                      (*(int16_t __far * __near *)         (_NULL_OFFSET + 0x00C0))
#define mfloorclip_offset               (*(int16_t __near *)                 (_NULL_OFFSET + 0x00C0))
#define mfloorclip_segment              (*(segment_t __near *)               (_NULL_OFFSET + 0x00C2))
#define mceilingclip                    (*(int16_t __far * __near *)         (_NULL_OFFSET + 0x00C4))
#define mceilingclip_offset             (*(int16_t __near *)                 (_NULL_OFFSET + 0x00C4))
#define mceilingclip_segment            (*(segment_t __near *)               (_NULL_OFFSET + 0x00C6))
//spanfunc_prt[4]
#define spanfunc_prt                    ((int16_t __near *)                  (_NULL_OFFSET + 0x00CC))
//spanfunc_destview_offset[4]
#define spanfunc_destview_offset        ((uint16_t __near *)                 (_NULL_OFFSET + 0x00D4))
//spanfunc_inner_loop_count[4]
#define spanfunc_inner_loop_count       ((int8_t __near *)                   (_NULL_OFFSET + 0x00DC))
//spanfunc_outp[4]
#define spanfunc_outp                   ((uint8_t __near *)                  (_NULL_OFFSET + 0x00E0))
//#define spanfunc_main_loop_count        (*(uint8_t __near *)                 (_NULL_OFFSET + 0x00E4))
#define skipdirectdraws                 (*(uint8_t __near *)                 (_NULL_OFFSET + 0x00E5))
#define jump_mult_table_3               ((uint8_t __near *)                  (_NULL_OFFSET + 0x00E6))
#define screen_segments                 ((segment_t __near *)                (_NULL_OFFSET + 0x00EE))
#define numbraintargets                 (*(int16_t __near *)                 (_NULL_OFFSET + 0x00F8))
#define braintargeton                   (*(int16_t __near *)                 (_NULL_OFFSET + 0x00FA))
#define brainspit_easy                  (*(boolean __near *)                 (_NULL_OFFSET + 0x00FC))
// If "floatok" true, move would be ok
// if within "tmfloorz - tmceilingz".
#define floatok                         (*(boolean __near *)                 (_NULL_OFFSET + 0x00FD))
#define corpsehitRef                    (*(THINKERREF __near *)              (_NULL_OFFSET + 0x00FE))
//todo test
#define vileobj                         (*(mobj_t __near * __near *)         (_NULL_OFFSET + 0x0100))

//  102 unused
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

#define MULT_256                        (((uint16_t   __near*)               (_NULL_OFFSET + 0x0120)))
#define MULT_4096                       (((uint16_t   __near*)               (_NULL_OFFSET + 0x0128)))
#define FLAT_CACHE_PAGE                 (((uint16_t   __near*)               (_NULL_OFFSET + 0x0130)))
#define visplanelookupsegments          (((segment_t   __near*)              (_NULL_OFFSET + 0x0138)))

#define firstflat                       (*((int16_t    __near*)              (_NULL_OFFSET + 0x013E)))
#define lightshift7lookup               (*((int16_t    __near*)              (_NULL_OFFSET + 0x0140)))

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
#define allocatedflatsperpage           (((int8_t    __near*)                (_NULL_OFFSET + 0x0170)))


// these are far pointers to functions..
#define Z_QuickMapVisplanePage_addr     (*((uint32_t  __near*)               (_NULL_OFFSET + 0x0180)))
#define R_EvictFlatCacheEMSPage_addr    (*((uint32_t  __near*)               (_NULL_OFFSET + 0x0184)))
#define Z_QuickMapFlatPage_addr         (*((uint32_t  __near*)               (_NULL_OFFSET + 0x0188)))
#define R_MarkL2FlatCacheLRU_addr       (*((uint32_t  __near*)               (_NULL_OFFSET + 0x018C)))
#define W_CacheLumpNumDirect_addr       (*((uint32_t  __near*)               (_NULL_OFFSET + 0x0190)))
#define floorplaneindex                 (*((int16_t    __near*)              (_NULL_OFFSET + 0x0194)))

#define viewwidth                       (*((int16_t    __near*)              (_NULL_OFFSET + 0x0198)))
#define viewheight                      (*((int16_t    __near*)              (_NULL_OFFSET + 0x019A)))
#define ceiltop                         (*((byte  __far* __near*)            (_NULL_OFFSET + 0x019C)))
#define floortop                        (*((byte  __far* __near*)            (_NULL_OFFSET + 0x01A0)))

#define frontsector                     (*((sector_t __far*  __near*)        (_NULL_OFFSET + 0x01A4)))
#define backsector                      (*((sector_t __far*  __near*)        (_NULL_OFFSET + 0x01A8)))
#define backsector_offset               (*((int16_t  __near*)                (_NULL_OFFSET + 0x01A8)))
// 1AC free

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
// 220
#define masked_headers                  (((masked_header_t  __near*)         (_NULL_OFFSET + 0x0220)))
#define curseg                          (*((int16_t  __near*)                (_NULL_OFFSET + 0x0280)))
#define curseg_render                   (*((seg_render_t  __near* __near*)   (_NULL_OFFSET + 0x0282)))
#define save_p                          (*((byte  __far* __near*)            (_NULL_OFFSET + 0x0284)))

#define maskednextlookup                (*((int16_t __near*)                 (_NULL_OFFSET + 0x0288)))
#define maskedprevlookup                (*((int16_t __near*)                 (_NULL_OFFSET + 0x028A)))
#define maskedtexrepeat                 (*((int16_t __near*)                 (_NULL_OFFSET + 0x028C)))
#define maskedcachedbasecol             (*((int16_t __near*)                 (_NULL_OFFSET + 0x028E)))
#define maskedcachedsegment             (*((segment_t __near*)               (_NULL_OFFSET + 0x0290)))
#define maskedheightvalcache            (*((uint8_t __near*)                 (_NULL_OFFSET + 0x0292)))
#define vsprsortedheadfirst             (*((uint8_t __near*)                 (_NULL_OFFSET + 0x0293)))
#define lastvisspritesegment            (*((segment_t __near*)               (_NULL_OFFSET + 0x0294)))
#define lastvisspritesegment2           (*((segment_t __near*)               (_NULL_OFFSET + 0x0296)))
#define lastvisspritepatch              (*((int16_t __near*)                 (_NULL_OFFSET + 0x0298)))
#define lastvisspritepatch2             (*((int16_t __near*)                 (_NULL_OFFSET + 0x029A)))
#define ds_p                            (*((drawseg_t __far* __near*)        (_NULL_OFFSET + 0x029C)))
#define lightmult48lookup               (((int16_t __near*)                  (_NULL_OFFSET + 0x02A0)))
// more far pointers to functions... once they are in ASM-fixed locations, they should be callable normally
#define FixedMul_addr                   (*((uint32_t  __near*)               (_NULL_OFFSET + 0x02C0)))
//#define FixedMul1632_addr               (*((uint32_t  __near*)               (_NULL_OFFSET + 0x02C4)))
#define FastDiv3232_addr                (*((uint32_t  __near*)               (_NULL_OFFSET + 0x02C8)))
#define R_GetMaskedColumnSegment_addr   (*((uint32_t  __near*)               (_NULL_OFFSET + 0x02CC)))

#define colfunc_call_lookup             (((uint32_t  __near*)                (_NULL_OFFSET + 0x02D0)))
#define getspritetexture_addr           (*((uint32_t  __near*)               (_NULL_OFFSET + 0x0354)))
#define psprites                        (((pspdef_t __near*)                 (_NULL_OFFSET + 0x0358)))
// lookup for what to write to the vga port for read  for fuzzcolumn
#define vga_read_port_lookup            (((uint16_t __near*)                 (_NULL_OFFSET + 0x0370)))

#define vissprite_p                     (*((int16_t __near*)                 (_NULL_OFFSET + 0x0388)))
#define cachedbyteheight                (*((uint8_t __near*)                 (_NULL_OFFSET + 0x038A)))
// todo fill this up
#define savedescription                 (((int8_t    __near*)                (_NULL_OFFSET + 0x0390)))
#define demoname                        (((int8_t    __near*)                (_NULL_OFFSET + 0x03B0)))




#define colfunc_masked_call_lookup      (((uint32_t  __near*)                (_NULL_OFFSET + 0x03D0)))

#define ems_backfill_page_order         (((int8_t    __near*)                (_NULL_OFFSET + 0x0454)))
#define movedirangles                   (((uint16_t  __near*)                (_NULL_OFFSET + 0x0470)))
#define braintargets                    (((THINKERREF __near*)               (_NULL_OFFSET + 0x0480)))


#define tmbbox                          (((fixed_t_union __near*)            (_NULL_OFFSET + 0x04C0)))



#define spanfunc_call_table             (((uint32_t  __near*)                (_NULL_OFFSET + 0x04D0)))

#define V_DrawPatch_addr                  (*((uint32_t  __near*)              (_NULL_OFFSET + 0x0554)))
#define locallib_toupper_addr             (*((uint32_t  __near*)              (_NULL_OFFSET + 0x0558)))
#define S_ChangeMusic_addr                (*((uint32_t  __near*)              (_NULL_OFFSET + 0x055C)))
#define V_DrawFullscreenPatch_addr        (*((uint32_t  __near*)              (_NULL_OFFSET + 0x0560)))
#define getStringByIndex_addr             (*((uint32_t  __near*)              (_NULL_OFFSET + 0x0564)))
#define locallib_strlen_addr              (*((uint32_t  __near*)              (_NULL_OFFSET + 0x0568)))
#define Z_QuickMapStatusNoScreen4_addr    (*((uint32_t  __near*)              (_NULL_OFFSET + 0x056C)))
#define Z_QuickMapRender7000_addr         (*((uint32_t  __near*)              (_NULL_OFFSET + 0x0570)))
#define Z_QuickMapScreen0_addr            (*((uint32_t  __near*)              (_NULL_OFFSET + 0x0574)))
#define W_CacheLumpNameDirect_addr        (*((uint32_t  __near*)              (_NULL_OFFSET + 0x0578)))
#define W_CacheLumpNumDirectFragment_addr (*((uint32_t  __near*)              (_NULL_OFFSET + 0x057C)))
#define W_GetNumForName_addr              (*((uint32_t  __near*)              (_NULL_OFFSET + 0x0580)))
#define S_StartSound_addr                 (*((uint32_t  __near*)              (_NULL_OFFSET + 0x0584)))
#define S_StartMusic_addr                 (*((uint32_t  __near*)              (_NULL_OFFSET + 0x0588)))
// 13 bytes
#define filename_argument                 ((int8_t __near *)                 (_NULL_OFFSET + 0x058C))
// 599h free
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









extern const int8_t         snd_prefixen[];
extern int16_t              snd_SBport;
extern uint8_t              snd_SBirq, snd_SBdma; // sound blaster variables
extern int16_t              snd_Mport; // midi variables

extern uint8_t              snd_MusicVolume; // maximum volume for music
extern uint8_t              snd_SfxVolume; // maximum volume for sound

extern uint8_t              snd_SfxDevice; // current sfx card # (index to dmxCodes)
extern uint8_t              snd_MusicDevice; // current music card # (index to dmxCodes)
extern uint8_t              snd_DesiredSfxDevice;
extern uint8_t              snd_DesiredMusicDevice;
extern uint8_t              snd_SBport8bit;
extern uint8_t              snd_Mport8bit;


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
extern int16_t			    validcount;

extern int16_t 			    pendingdetail;
extern uint16_t			    clipangle;
extern uint16_t			    fieldofview;
extern boolean		        setsizeneeded;
extern uint8_t		        setblocks;
extern uint16_t			    skytexture;

extern uint16_t             pspritescale;
extern int16_t              spritelights;
extern int16_t              numflats;
extern int16_t              firstpatch;
extern int16_t              numpatches;
extern int16_t              numspritelumps;
extern int16_t              numtextures;
extern int16_t              activetexturepages[NUM_TEXTURE_L1_CACHE_PAGES];
extern uint8_t              activenumpages[NUM_TEXTURE_L1_CACHE_PAGES];
extern int16_t              textureL1LRU[NUM_TEXTURE_L1_CACHE_PAGES];
extern int16_t              activespritepages[NUM_SPRITE_L1_CACHE_PAGES];
extern uint8_t              activespritenumpages[NUM_SPRITE_L1_CACHE_PAGES];
extern int16_t              spriteL1LRU[NUM_SPRITE_L1_CACHE_PAGES];
extern int8_t               spritecache_l2_head;
extern int8_t               spritecache_l2_tail;
extern int8_t               flatcache_l2_head;
extern int8_t               flatcache_l2_tail;
extern int8_t               texturecache_l2_head;
extern int8_t               texturecache_l2_tail;
extern int16_t              cachedlumps[NUM_CACHE_LUMPS];
extern segment_t            cachedsegmentlumps[NUM_CACHE_LUMPS];
//extern segment_t            cachedsegmentlump;
extern segment_t            cachedsegmenttex;
//extern int16_t              cachedlump;
extern int16_t              cachedtex;
//extern segment_t            cachedsegmentlump2;
extern segment_t            cachedsegmenttex2;
//extern int16_t              cachedlump2;
extern int16_t              cachedtex2;
extern uint8_t              cachedcollength;
extern uint8_t              cachedcollength2;

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
extern segment_t            pagesegments[NUM_TEXTURE_L1_CACHE_PAGES];


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

extern void                 (__far* P_UnArchivePlayers)();
extern void                 (__far* P_UnArchiveWorld)();
extern void                 (__far* P_UnArchiveThinkers)();
extern void                 (__far* P_UnArchiveSpecials)();

extern void                 (__far* P_ArchivePlayers)();
extern void                 (__far* P_ArchiveWorld)();
extern void                 (__far* P_ArchiveThinkers)();
extern void                 (__far* P_ArchiveSpecials)();


extern int16_t              currentlumpindex;
extern uint16_t             maskedcount;
extern uint16_t             currentpostoffset;
extern uint16_t             currentpostdataoffset;
extern uint16_t             currentpixeloffset;

extern segment_t            EMS_PAGE;

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
extern union REGS regs;
extern struct SREGS segregs;

extern boolean novideo; // if true, stay in text mode for debugging
#define KBDQUESIZE 32

extern union REGS in;
extern union REGS out;
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


 

extern skill_t         gameskill; 
extern boolean         respawnmonsters;
extern boolean         paused; 
extern boolean         sendpause;              // send a pause event next tic 
extern boolean         sendsave;               // send a save event next tic 
extern boolean         usergame;               // ok to save / end game 
extern boolean         timingdemo;             // if true, exit with report on completion 
extern boolean         noblit;                 // for comparative timing purposes 
extern ticcount_t             starttime;              // for comparative timing purposes       
extern player_t        player;
extern THINKERREF      playerMobjRef;

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
extern int16_t	rndindex;
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

extern uint16_t         keys[NUMCARDS];
extern uint16_t         faces[ST_NUMFACES];
extern uint16_t arms[6][2];
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
extern void( __interrupt __far_func *OldInt8)(void);
extern volatile int32_t TaskServiceRate;
extern volatile fixed_t_union TaskServiceCount;

extern volatile int16_t TS_TimesInInterrupt;
extern int8_t TS_Installed;
extern volatile int8_t TS_InInterrupt;

extern int8_t NUMANIMS[NUMEPISODES_FOR_ANIMS];
extern wianim_t __far*wianims[NUMEPISODES_FOR_ANIMS];
extern int16_t		acceleratestage;
extern stateenum_t	state;
extern wbstartstruct_t __near*	wbs;
extern wbplayerstruct_t plrs;  // wbs->plyr[]
extern uint16_t 		cnt;
extern uint16_t 		bcnt;
extern int16_t		cnt_kills;
extern int16_t		cnt_items;
extern int16_t		cnt_secret;
extern int16_t		cnt_time;
extern int16_t		cnt_par;
extern int16_t		cnt_pause;
extern boolean unloaded;
extern uint8_t		yahRef[2];
extern uint8_t		splatRef;
extern uint8_t		numRef[10];
extern boolean		snl_pointeron;
extern int16_t	sp_state;


#define castorderoffset CC_ZOMBIE
//
// Final DOOM 2 animation
// Casting by id Software.
//   in order of appearance
//
typedef struct {

	uint8_t		nameindex;
    mobjtype_t	type;
} castinfo_t;

 

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


extern fixed_t_union	leveltime;
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




extern mobj_t __near*		tmthing;
extern mobj_pos_t __far*		tmthing_pos;
extern int16_t		tmflags1;
extern fixed_t_union		tmx;
extern fixed_t_union		tmy;


// If "floatok" true, move would be ok
// if within "tmfloorz - tmceilingz".

extern short_height_t		tmfloorz;
extern short_height_t		tmceilingz;
extern short_height_t		tmdropoffz;

// keep track of the line that lowers the ceiling,
// so missiles don't explode against sky hack walls
extern int16_t		ceilinglinenum;

// keep track of special lines as they are hit,
// but don't process them until the move is proven valid
extern int16_t		numspechit;

extern int16_t lastcalculatedsector;
extern fixed_t_union		bestslidefrac;
extern int16_t		bestslidelinenum;
extern fixed_t_union		tmxmove;
extern fixed_t_union		tmymove;
//
extern mobj_t __near*		linetarget;	// who got hit (or NULL)
extern mobj_pos_t __far*	linetarget_pos;	// who got hit (or NULL)
extern mobj_t __near*		shootthing;

// Height if not aiming up or down
// ???: use slope for monsters?
extern fixed_t_union		shootz;	

extern int16_t		la_damage;
extern int16_t		attackrange16;

extern fixed_t		aimslope;
extern fixed_t		sightzstart;		// eye z of looker
extern fixed_t		topslope;
extern fixed_t		bottomslope;		// slopes to top and bottom of target

extern divline_t	strace;			// from t1 to t2
extern fixed_t_union		cachedt2x;
extern fixed_t_union		cachedt2y;
extern boolean		crushchange;
extern boolean		nofit;
extern intercept_t __far*	intercept_p;

extern divline_t 	trace;
extern boolean 	earlyout;
extern lineopening_t lineopening;
extern divline_t		dl;

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
extern uint8_t usedtexturepagemem[NUM_TEXTURE_PAGES];
extern uint8_t usedspritepagemem[NUM_SPRITE_CACHE_PAGES];
extern uint16_t                     numlumps;
extern FILE*               		    wadfiles[MAX_WADFILES];
extern int16_t                	    filetolumpindex[MAX_WADFILES-1];
extern int32_t                		filetolumpsize[MAX_WADFILES-1];
extern int8_t                       currentloadedfileindex;
  



#ifdef PRECALCULATE_OPENINGS
extern lineopening_t __far*	lineopenings;
#endif




#if defined(__CHIPSET_BUILD)

// these are prepared for calls to outsw with autoincrementing ems register on
extern uint16_t pageswapargs[total_pages];

#else

extern int16_t emshandle;
extern int16_t pagenum9000;

extern uint16_t pageswapargs[total_pages];

#endif

  



extern int8_t current5000State;
extern int8_t last5000State;
extern int8_t current9000State;
extern int8_t last9000State;


#ifdef DETAILED_BENCH_STATS
extern int32_t taskswitchcount;
extern int32_t texturepageswitchcount;
extern int32_t patchpageswitchcount;
extern int32_t compositepageswitchcount;
extern int32_t spritepageswitchcount;
extern int16_t benchtexturetype;
extern int32_t flatpageswitchcount;
extern int32_t scratchpageswitchcount;
extern int32_t lumpinfo5000switchcount;
extern int32_t lumpinfo9000switchcount;
extern int16_t spritecacheevictcount;
extern int16_t flatcacheevictcount;
extern int16_t patchcacheevictcount;
extern int16_t compositecacheevictcount;
extern int32_t visplaneswitchcount;

#endif

extern int8_t currenttask;

extern cache_node_page_count_t  spritecache_nodes[NUM_SPRITE_CACHE_PAGES];
extern cache_node_page_count_t	texturecache_nodes[NUM_TEXTURE_PAGES];
extern cache_node_t 			flatcache_nodes[NUM_FLAT_CACHE_PAGES];

extern segment_t			    spritewidths_segment;

//extern uint8_t 					seglooptexmodulo[2]; // 0 would be fine too...
extern uint8_t  				seglooptexrepeat[2]; // 0 would be fine too...
extern int16_t 					segloopnextlookup[2];
extern int16_t 					segloopprevlookup[2];
extern segment_t 				segloopcachedsegment[2];
extern int16_t 					segloopcachedbasecol[2];
extern uint8_t 					segloopheightvalcache[2];

extern int8_t    savename[16];
extern int8_t versionstring[12];

extern int8_t  currentoverlay;
extern int32_t codestartposition[NUM_OVERLAYS];

#if (EXE_VERSION >= EXE_VERSION_FINAL)
extern boolean    				plutonia;
extern boolean    				tnt;
#endif

// the complete set of sound effects
extern sfxinfo_t	S_sfx[];

// the complete set of music
extern musicinfo_t	S_music[];



extern channel_t	channels[MAX_CHANNELS];
extern boolean		mus_paused;	
extern musicinfo_t*	mus_playing;
extern ticcount_t		nextcleanup;

//extern uint16_t shift4lookup[256];

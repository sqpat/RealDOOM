;
; Copyright (C) 1993-1996 Id Software, Inc.
; Copyright (C) 1993-2008 Raven Software
; Copyright (C) 2016-2017 Alexey Khokholov (Nuke.YKT)
;
; This program is free software; you can redistribute it and/or
; modify it under the terms of the GNU General Public License
; as published by the Free Software Foundation; either version 2
; of the License, or (at your option) any later version.
;
; This program is distributed in the hope that it will be useful,
; but WITHOUT ANY WARRANTY; without even the implied warranty of
; MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
; GNU General Public License for more details.
;

INCLUDE constant.inc


SCREENWIDTH			=   320
SCREENWIDTHOVER2	=   160
SCREENHEIGHT		=	200

PEL_WRITE_ADR		=	03c8h
PEL_DATA			=	03c9h

SC_INDEX			=	03C4h
SC_MAPMASK			=	2

SC_DATA 			=   03C5h

GC_INDEX        	=   03CEh
GC_READMAP      	=   4


_NULL_OFFSET = 0030h


_segloopnextlookup    = 			_NULL_OFFSET + 00000h
_seglooptexrepeat    = 				_NULL_OFFSET + 00004h
_maskedtexrepeat =                  _NULL_OFFSET + 00006h
_segloopcachedsegment  = 			_NULL_OFFSET + 00008h
_segloopheightvalcache = 			_NULL_OFFSET + 0000Ch
;// 0E-0F free
;_currentscreen    = 				_NULL_OFFSET + 00000h
;_destview    = 						_NULL_OFFSET + 00004h
;_destscreen = (_NULL_OFFSET + 0008h)
;_tantoangle_segment  = 						_NULL_OFFSET + 0000Ch
;_spanfunc_jump_segment_storage = 	_NULL_OFFSET + 0000Eh


; 010 to 030 unused

_spanfunc_prt = 					_NULL_OFFSET + 00010h
_spanfunc_destview_offset = 		_NULL_OFFSET + 00018h
_spanfunc_inner_loop_count =		_NULL_OFFSET + 00020h
_spanfunc_outp = 					_NULL_OFFSET + 00024h
; 28 -2F unused

_quality_port_lookup = 				_NULL_OFFSET + 00030h


; todo move to cs
_jump_mult_table_3 = 				_NULL_OFFSET + 00048h

 
_dc_x = 							_NULL_OFFSET + 00050h
_lastopening =                   	_NULL_OFFSET + 00052h
_planezlight = 						_NULL_OFFSET + 00054h
_caststate =                        _NULL_OFFSET + 00058h
_basexscale = 						_NULL_OFFSET + 0005Ch
_baseyscale = 						_NULL_OFFSET + 00060h
_viewx = 							_NULL_OFFSET + 00064h
_viewy = 							_NULL_OFFSET + 00068h
_viewz = 							_NULL_OFFSET + 0006Ch
_centerx = 							_NULL_OFFSET + 00070h
_centery = 							_NULL_OFFSET + 00072h
_centeryfrac_shiftright4 = 			_NULL_OFFSET + 00074h
_viewangle =                		_NULL_OFFSET + 00078h
_viewz_shortheight = 				_NULL_OFFSET + 0007Ch
_screen_segments = 					_NULL_OFFSET + 0007Eh

_maskedtexture = 					_NULL_OFFSET + 00088h
; 89 free
_spechit =       					_NULL_OFFSET + 0008Ah
_bombsource =       				_NULL_OFFSET + 0009Ah
_bombspot =       					_NULL_OFFSET + 0009Ch
_bombdamage =       				_NULL_OFFSET + 0009Eh
_bombspot_pos = 					_NULL_OFFSET + 000A0h

_spryscale = 						_NULL_OFFSET + 000A4h
_sprtopscreen =	 					_NULL_OFFSET + 000A8h
_player_ptr = 						_NULL_OFFSET + 000ACh
_pendingmusicenum =                 _NULL_OFFSET + 000AEh
_pendingmusicenumlooping =          _NULL_OFFSET + 000AFh


_snd_MusicDevice =				    _NULL_OFFSET + 000B0h
_dc_yl = 							_NULL_OFFSET + 000B2h
_dc_yh = 							_NULL_OFFSET + 000B4h

_is_ultimate = 						_NULL_OFFSET + 000B5h
_firstspritelump = 					_NULL_OFFSET + 000B6h

_finaletext =                    	_NULL_OFFSET + 000B8h
_finalecount =                   	_NULL_OFFSET + 000BAh
_finalestage =                   	_NULL_OFFSET + 000BCh
_finale_laststage =              	_NULL_OFFSET + 000BEh
_playingstate = 	                _NULL_OFFSET + 000BFh

_mfloorclip = 						_NULL_OFFSET + 000C0h
_mceilingclip = 					_NULL_OFFSET + 000C4h

_viletryx =                         _NULL_OFFSET + 000CCh
_viletryy =                         _NULL_OFFSET + 000D0h
_viewangle_shiftright1 = 			_NULL_OFFSET + 000D4h
_skipdirectdraws = 					_NULL_OFFSET + 000D6h

_snd_SfxDevice = 					_NULL_OFFSET + 000D7h

_ds_source_segment = 				_NULL_OFFSET + 000D8h

_currentscreen    = 				_NULL_OFFSET + 000DCh
_destview    = 						_NULL_OFFSET + 000E0h
_destscreen    = 					_NULL_OFFSET + 000E4h
_tantoangle_segment  = 				_NULL_OFFSET + 000E8h
_spanfunc_jump_segment_storage = 	_NULL_OFFSET + 000EAh

; ec-f4 free


_validcount_global =				_NULL_OFFSET + 000F4h

_firstpatch =                       _NULL_OFFSET + 000F6h

_numbraintargets = 					_NULL_OFFSET + 000F8h
_braintargeton = 					_NULL_OFFSET + 000FAh
_brainspit_easy = 					_NULL_OFFSET + 000FCh
_floatok = 							_NULL_OFFSET + 000FDh
_corpsehitRef = 					_NULL_OFFSET + 000FEh
_vileobj = 							_NULL_OFFSET + 00100h


_EMS_PAGE =                 	    _NULL_OFFSET + 00102h
_viewangle_shiftright3 = 			_NULL_OFFSET + 00104h
_dc_source_segment =	 			_NULL_OFFSET + 0010Ah
_ds_y = 				    		_NULL_OFFSET + 0010Ch
_stored_ds = 				    	_NULL_OFFSET + 00110h


_cachedheight_segment_storage =    	_NULL_OFFSET + 00112h
_distscale_segment_storage =    	_NULL_OFFSET + 00114h
_cacheddistance_segment_storage =   _NULL_OFFSET + 00116h
_cachedxstep_segment_storage =    	_NULL_OFFSET + 00118h
_cachedystep_segment_storage =    	_NULL_OFFSET + 0011Ah

_pspriteiscale =                    _NULL_OFFSET + 0011Ch

; 120h

_tmflags1 =                         _NULL_OFFSET + 00120h
_tmfloorz =                         _NULL_OFFSET + 00122h
_tmceilingz =                       _NULL_OFFSET + 00124h
_tmdropoffz =                       _NULL_OFFSET + 00126h


_MULT_4096 =                    	_NULL_OFFSET + 00128h
; todo unused
_FLAT_CACHE_PAGE =                  _NULL_OFFSET + 00130h
_visplanelookupsegments =           _NULL_OFFSET + 00138h
_firstflat =                  		_NULL_OFFSET + 0013Eh
; 140h
_castattacking =                 	_NULL_OFFSET + 00140h
_castdeath =                     	_NULL_OFFSET + 00141h
_castonmelee =                   	_NULL_OFFSET + 00142h
_castframes =                    	_NULL_OFFSET + 00143h
_casttics =                      	_NULL_OFFSET + 00144h
_castnum =                       	_NULL_OFFSET + 00145h
_finaleflat =                   	_NULL_OFFSET + 00146h
; 147 free
_FixedMul2432_addr =                _NULL_OFFSET + 00148h
_tmthing_pos =                      _NULL_OFFSET + 0014Ch

_trace =                            _NULL_OFFSET + 00150h

; 160h
_currentflatpage =            		_NULL_OFFSET + 00160h
_lastflatcacheindicesused =         _NULL_OFFSET + 00164h
_skyflatnum =            			_NULL_OFFSET + 00168h
_extralight =            			_NULL_OFFSET + 00169h
_visplanedirty =            		_NULL_OFFSET + 0016Ah
_screenblocks =            			_NULL_OFFSET + 0016Bh
_lastvisplane =            			_NULL_OFFSET + 0016Ch
_hudneedsupdate =                   _NULL_OFFSET + 0016Eh
_gamestate =                        _NULL_OFFSET + 0016Fh


; 170h
_tmx =                             _NULL_OFFSET + 00170h
_tmy =                             _NULL_OFFSET + 00174h
_tmxmove =                         _NULL_OFFSET + 00178h
_tmymove =                         _NULL_OFFSET + 0017Ch




; 180h
_Z_QuickMapVisplanePage_addr =      _NULL_OFFSET + 00180h
;_R_EvictFlatCacheEMSPage_addr =     _NULL_OFFSET + 00184h
_Z_QuickMapFlatPage_addr =        	_NULL_OFFSET + 00188h
;_R_MarkL2FlatCacheMRU_addr =        _NULL_OFFSET + 0018Ch
; 190h
_W_CacheLumpNumDirect_addr =        _NULL_OFFSET + 00190h



_floorplaneindex =               	_NULL_OFFSET + 00194h
_ceilingplaneindex =             	_NULL_OFFSET + 00196h
_viewwidth =                     	_NULL_OFFSET + 00198h
_viewheight =	                    _NULL_OFFSET + 0019Ah

_ceiltop =      	                _NULL_OFFSET + 0019Ch
_floortop =         	            _NULL_OFFSET + 001A0h

_frontsector =          	        _NULL_OFFSET + 001A4h
_backsector =               	    _NULL_OFFSET + 001A8h
_playingtime =		                _NULL_OFFSET + 001ACh
_active_visplanes =             	_NULL_OFFSET + 001B0h
_wipegamestate =                    _NULL_OFFSET + 001B5h
_visplane_offset =              	_NULL_OFFSET + 001B6h
_dirtybox =              			_NULL_OFFSET + 001E8h
_ticcount =			              	_NULL_OFFSET + 001F0h

_Z_QuickMapPhysics_addr =            _NULL_OFFSET + 001F4h
_Z_QuickMapWipe_addr =               _NULL_OFFSET + 001F8h
_Z_QuickMapScratch_5000_addr =       _NULL_OFFSET + 001FCh
_M_Random_addr =                     _NULL_OFFSET + 00200h
_I_UpdateNoBlit_addr =               _NULL_OFFSET + 00204h
_I_FinishUpdate_addr =               _NULL_OFFSET + 00208h
_V_MarkRect_addr =                   _NULL_OFFSET + 0020Ch
_M_Drawer_addr =                     _NULL_OFFSET + 00210h

_wipeduration =                      _NULL_OFFSET + 00214h
_detailshift2minus =  		 		 _NULL_OFFSET + 00216h
_maskedheaderpixeolfs =				 _NULL_OFFSET + 00218h
_maskedtexturecol =					 _NULL_OFFSET + 0021Ch
; 0220h
_masked_headers =                    _NULL_OFFSET + 00220h
_curseg =                          	 _NULL_OFFSET + 00280h
_curseg_render =                     _NULL_OFFSET + 00282h
_save_p =                            _NULL_OFFSET + 00284h
_maskednextlookup =                  _NULL_OFFSET + 00288h
_maskedprevlookup =                  _NULL_OFFSET + 0028Ah
_tmthing =                           _NULL_OFFSET + 0028Ch
_maskedcachedbasecol =               _NULL_OFFSET + 0028Eh
_maskedcachedsegment =               _NULL_OFFSET + 00290h
_maskedheightvalcache =              _NULL_OFFSET + 00292h
_vsprsortedheadfirst =               _NULL_OFFSET + 00293h
_lastvisspritesegment =              _NULL_OFFSET + 00294h
_lastvisspritesegment2 =             _NULL_OFFSET + 00296h
_lastvisspritepatch =                _NULL_OFFSET + 00298h
_lastvisspritepatch2 =               _NULL_OFFSET + 0029Ah
_ds_p =               				 _NULL_OFFSET + 0029Ch

_olddb =							_NULL_OFFSET + 002A0h
_detailshift = 						_NULL_OFFSET + 002B0h
_detailshiftitercount = 			_NULL_OFFSET + 002B2h
_detailshiftandval = 				_NULL_OFFSET + 002B4h
_ceilphyspage =                  	_NULL_OFFSET + 002B6h
_floorphyspage =                 	_NULL_OFFSET + 002B7h
_gameaction =                 		_NULL_OFFSET + 002B8h
_viewactive =                 		_NULL_OFFSET + 002B9h
_automapactive =                 	_NULL_OFFSET + 002BAh
_commercial =                 		_NULL_OFFSET + 002BBh
_registered =                 		_NULL_OFFSET + 002BCh
_shareware =                 		_NULL_OFFSET + 002BDh
_ds_colormap_index = 				_NULL_OFFSET + 002BEh
_fixedcolormap = 					_NULL_OFFSET + 002BFh



_FixedMul_addr =               		 _NULL_OFFSET + 002C0h
_FixedDiv_addr =                     _NULL_OFFSET + 002C4h
_FastDiv3232_addr =                  _NULL_OFFSET + 002C8h
_R_GetMaskedColumnSegment_addr =     _NULL_OFFSET + 002CCh

 
_colfunc_call_lookup =               _NULL_OFFSET + 002D0h

; 354
_R_GetSpriteTexture_addr =             _NULL_OFFSET + 00354h
_psprites =              			 _NULL_OFFSET + 00358h
; this is full... _psprites is two 0Ch sized structs... 
_vga_read_port_lookup =              _NULL_OFFSET + 00370h
_vissprite_p =                       _NULL_OFFSET + 00388h
; high byte always 0
_cachedbyteheight =                  _NULL_OFFSET + 0038Ah
_currentMusPage = 					 _NULL_OFFSET + 0038Ch
_snd_MusicVolume =                   _NULL_OFFSET + 0038Dh
_gameepisode = 						 _NULL_OFFSET + 0038Eh
_gamemap = 							 _NULL_OFFSET + 0038Fh
_savedescription =                   _NULL_OFFSET + 00390h
_demoname =                          _NULL_OFFSET + 003B0h

_colfunc_masked_call_lookup =        _NULL_OFFSET + 003D0h

_ems_backfill_page_order =           _NULL_OFFSET + 00454h
_movedirangles =                     _NULL_OFFSET + 00470h
_braintargets =                      _NULL_OFFSET + 00480h
_tmbbox =                            _NULL_OFFSET + 004C0h
_spanfunc_call_lookup =              _NULL_OFFSET + 004D0h



_V_DrawPatch_addr =              	 _NULL_OFFSET + 00554h
_locallib_toupper_addr =             _NULL_OFFSET + 00558h
_S_ChangeMusic_addr =              	 _NULL_OFFSET + 0055Ch
_V_DrawFullscreenPatch_addr =        _NULL_OFFSET + 00560h
_getStringByIndex_addr =             _NULL_OFFSET + 00564h
_locallib_strlen_addr =              _NULL_OFFSET + 00568h
_Z_QuickMapStatusNoScreen4_addr =    _NULL_OFFSET + 0056Ch
_Z_QuickMapRender7000_addr =         _NULL_OFFSET + 00570h
_Z_QuickMapScreen0_addr =            _NULL_OFFSET + 00574h
_W_CacheLumpNameDirect_addr =        _NULL_OFFSET + 00578h
_W_CacheLumpNumDirectFragment_addr = _NULL_OFFSET + 0057Ch
_W_GetNumForName_addr =              _NULL_OFFSET + 00580h
_S_StartSound_addr =                 _NULL_OFFSET + 00584h
_S_StartMusic_addr =             	 _NULL_OFFSET + 00588h

; 13 bytes in length
_filename_argument = 				 _NULL_OFFSET + 0058Ch

_rndindex = 						 _NULL_OFFSET + 00599h
_fopen_r_argument = 				 _NULL_OFFSET + 0059Ah
_fopen_w_argument = 				 _NULL_OFFSET + 0059Ch

_numsectors =						 _NULL_OFFSET + 0059Eh
_numlines =						     _NULL_OFFSET + 005A0h
_numvertexes =						 _NULL_OFFSET + 005A2h
_numsegs =						     _NULL_OFFSET + 005A4h
_numsubsectors =				     _NULL_OFFSET + 005A6h
_numnodes =						 	 _NULL_OFFSET + 005A8h
_numsides =						 	 _NULL_OFFSET + 005AAh
_bmapwidth =						 _NULL_OFFSET + 005ACh
_bmapheight =						 _NULL_OFFSET + 005AEh
_bmaporgx =						 	 _NULL_OFFSET + 005B0h
_bmaporgy =				             _NULL_OFFSET + 005B2h

_I_Error_addr =                      _NULL_OFFSET + 005B4h
_P_InitThinkers_addr =               _NULL_OFFSET + 005B8h
_P_CreateThinker_addr =              _NULL_OFFSET + 005BCh
_P_SetThingPosition_addr =           _NULL_OFFSET + 005C0h
_P_RemoveMobj_addr =                 _NULL_OFFSET + 005C4h
_P_AddActiveCeiling_addr =           _NULL_OFFSET + 005C8h
_P_AddActivePlat_addr =              _NULL_OFFSET + 005CCh
_activeceilings =                    _NULL_OFFSET + 005D0h

_Z_SetOverlay_addr =                 _NULL_OFFSET + 0060Ch
_W_LumpLength_addr =                 _NULL_OFFSET + 00610h

_playingdriver =                     _NULL_OFFSET + 00614h
_currentsong_start_offset =          _NULL_OFFSET + 00618h
_currentsong_playing_offset =        _NULL_OFFSET + 0061Ah
_currentsong_ticks_to_process =      _NULL_OFFSET + 0061Ch
_loops_enabled =    			     _NULL_OFFSET + 0061Eh
_mus_playing =    			      	 _NULL_OFFSET + 0061Fh
_Z_QuickMapMusicPageFrame_addr = 	 _NULL_OFFSET + 00620h

_sightzstart =				         _NULL_OFFSET + 00624h
_topslope =				         	 _NULL_OFFSET + 00628h
_bottomslope =					     _NULL_OFFSET + 0062Ch
_cachedt2x =				         _NULL_OFFSET + 00630h
_cachedt2y =					     _NULL_OFFSET + 00634h
_strace =					         _NULL_OFFSET + 00638h
_sfx_free_bytes = 					 _NULL_OFFSET + 00648h


_activespritepages =                 _NULL_OFFSET + 00670h
_activespritenumpages =              _NULL_OFFSET + 00674h
_spriteL1LRU =                 		 _NULL_OFFSET + 00678h
_spritecache_l2_head =               _NULL_OFFSET + 0067Ch
_spritecache_l2_tail =               _NULL_OFFSET + 0067Dh
_texturecache_l2_head =              _NULL_OFFSET + 0067Eh
_texturecache_l2_tail =              _NULL_OFFSET + 0067Fh
_activetexturepages =                _NULL_OFFSET + 00680h
_activenumpages =                 	 _NULL_OFFSET + 00688h
_textureL1LRU =                 	 _NULL_OFFSET + 00690h
_cachedsegmentlumps =                _NULL_OFFSET + 00698h
_cachedlumps =                 	     _NULL_OFFSET + 006A0h
_cachedtex =                 		 _NULL_OFFSET + 006A8h
;_cachedcollength =                   _NULL_OFFSET + 006ACh
_flatcache_l2_head =                 _NULL_OFFSET + 006ADh
_flatcache_l2_tail =                 _NULL_OFFSET + 006AEh
_segloopprevlookup =                 _NULL_OFFSET + 006B0h
_segloopcachedbasecol =              _NULL_OFFSET + 006B4h
_cachedsegmenttex =                  _NULL_OFFSET + 006B8h
_cachedcollength =                   _NULL_OFFSET + 006BCh
_ceilinglinenum =                    _NULL_OFFSET + 006BEh

_lineopening =				         _NULL_OFFSET + 006C0h

; 6c6
_intercept_p =				         _NULL_OFFSET + 006C8h
_aimslope = 				         _NULL_OFFSET + 006CCh
_bestslidefrac =				     _NULL_OFFSET + 006D0h
_bestslidelinenum =				     _NULL_OFFSET + 006D4h
_numspechit =				         _NULL_OFFSET + 006D6h
_lastcalculatedsector =				 _NULL_OFFSET + 006D8h

_shootthing =				 		 _NULL_OFFSET + 006DAh
_shootz =				 			 _NULL_OFFSET + 006DCh
_la_damage = 		   			     _NULL_OFFSET + 006E0h

_linetarget = 		   			     _NULL_OFFSET + 006E2h
_linetarget_pos = 		   			 _NULL_OFFSET + 006E4h
_attackrange16 = 		   			 _NULL_OFFSET + 006E8h
_nofit = 		   			 		 _NULL_OFFSET + 006EAh
_crushchange = 		   			 	 _NULL_OFFSET + 006EBh
_leveltime =     		   			 _NULL_OFFSET + 006ECh

; 6c6

_flatcache_nodes =				     _NULL_OFFSET + 006F0h

CURRENT_POSITION_1 =  			      (_flatcache_nodes    + (SIZEOF_CACHE_NODE_T * NUM_FLAT_CACHE_PAGES))
_spritecache_nodes =				  CURRENT_POSITION_1
CURRENT_POSITION_2 =   			      (_spritecache_nodes  + (SIZEOF_CACHE_NODE_PAGE_COUNT_T * NUM_SPRITE_CACHE_PAGES))
_texturecache_nodes =				  CURRENT_POSITION_2
CURRENT_POSITION_3 =   			      (_texturecache_nodes + (SIZEOF_CACHE_NODE_PAGE_COUNT_T * NUM_TEXTURE_PAGES))

_allocatedflatsperpage =		      CURRENT_POSITION_3
CURRENT_POSITION_4 =   			      (_allocatedflatsperpage  + (1 * NUM_FLAT_CACHE_PAGES))
_usedspritepagemem =				  CURRENT_POSITION_4
CURRENT_POSITION_5 =   			      (_usedspritepagemem  + (1 * NUM_SPRITE_CACHE_PAGES))
_usedtexturepagemem =				  CURRENT_POSITION_5
CURRENT_POSITION_6 =   			   	  (_usedtexturepagemem + (1 * NUM_TEXTURE_PAGES))







;06CAh





; EXTERNAL CODE OFFSETS FOR SELF MODIFYING CODE
; We use a 2 step build process. Some code is exported to a binary in the first build,
; then the 2nd build includes less code in the final exe. The exe loads code from the
; the first binary at runtime. The issue is some code from the build 2 exe wishes to
; modify code offsets from the binary, but that 2nd build has no visibility into the
; locations of things in the first build. So we must HARDCODE (ugh) some instruction
; offsets in here. Oh well - it's pretty minimal.

; todo this sucks.
SELFMODIFY_COLFUNC_subtract_centery =                   0
SELFMODIFY_COLFUNC_set_destview_segment =               0+3+2+2+1+2+2+2+2+2+2+2+2+2+2+2+2+2+2+2
SELFMODIFY_COLFUNC_jump_offset =                        SELFMODIFY_COLFUNC_set_destview_segment+3+2+2+5+2



STATENUM_NULL = -1




; todo what is this magic number again? (??) r_draw.c alludes to it as desired bx offset
DRAWSPAN_BX_OFFSET             = 0FC0h
DRAWSPAN_CALL_OFFSET           = (16 * (SPANFUNC_JUMP_LOOKUP_SEGMENT - COLORMAPS_SEGMENT)) + DRAWSPAN_BX_OFFSET

DRAWCOL_OFFSET                 = (COLFUNC_FUNCTION_AREA_SEGMENT - COLORMAPS_SEGMENT) * 16

; todo copy this from C via script
VISPLANES_PER_EMS_PAGE         = 25
MAX_CONVENTIONAL_VISPLANES     = 75
VISPLANE_BYTE_SIZE             = (6 + (2 * SCREENWIDTH))

LIGHTLEVELS					   = 16
LIGHTSEGSHIFT				   = 4

VISPLANE_BYTES_PER_PAGE        = (VISPLANE_BYTE_SIZE * VISPLANES_PER_EMS_PAGE)
FIRST_VISPLANE_PAGE_SEGMENT    = 08400h

SCRATCH_PAGE_SEGMENT_5000      = 05000h;
LIGHTSCALESHIFT                = 0Ch
MAXSHORT					   = 07FFFh
MINSHORT					   = 08000h

COLORMAP_SHADOW     		   = 0FFh

; todo generate this from c
DRAWSEG_SIZE				   = 020h
NULL_TEX_COL				   = 0FEBFh  ;  65535 - SCREENWIDTH
SECNUM_NULL					   = 0FFFFh

COMPILE_386  = 3
COMPILE_286  = 2
COMPILE_186  = 1
COMPILE_8086 = 0

CHIPSET_NONE  = 0
CHIPSET_SCAMP = 1
CHIPSET_SCAT  = 2
CHIPSET_HT18  = 3


; should be in build params but if not...
IFNDEF COMPILE_INSTRUCTIONSET
	COMPILE_INSTRUCTIONSET = COMPILE_8086
ENDIF
 

LEAVE_MACRO MACRO 

IF COMPILE_INSTRUCTIONSET GE COMPILE_186
	leave
ELSE
	mov sp, bp
	pop bp 
ENDIF

ENDM

PUSHA_NO_AX_MACRO MACRO

IF COMPILE_INSTRUCTIONSET GE COMPILE_186
	pusha
ELSE	
	push  bx
	push  cx
	push  dx
	push  bp
	push  si
	push  di
ENDIF

ENDM

POPA_NO_AX_MACRO MACRO

IF COMPILE_INSTRUCTIONSET GE COMPILE_186
	popa
ELSE	
	pop   di
	pop   si
    pop   bp
	pop   dx
	pop   cx
	pop   bx
ENDIF

ENDM


MUL_SIZEOF_THINKER_T MACRO dest, source

	mov  &dest, &source
	SHIFT_MACRO SAL &dest 3
	add  &dest, &source
	add  &dest, &source
	add  &dest, &source
	SHIFT_MACRO SAL &dest 2

ENDM

SHIFT_MACRO MACRO instruction, register, count


IF COMPILE_INSTRUCTIONSET GE COMPILE_386
	&instruction &register, &count

ELSEIF COMPILE_INSTRUCTIONSET GE COMPILE_186
	IF COUNT GE 4
		&instruction &register, &count
	ELSE
		REPT &count
			&instruction &register, 1
		ENDM
	ENDIF
ELSE
	REPT &count
		&instruction &register, 1
	ENDM
ENDIF

ENDM



INSTRUCTION_SET_MACRO MACRO 

	.MODEL medium

IF COMPILE_INSTRUCTIONSET EQ COMPILE_386
	.386
ELSEIF COMPILE_INSTRUCTIONSET EQ COMPILE_286
	.286
ELSEIF COMPILE_INSTRUCTIONSET EQ COMPILE_186
	.186
ELSE
	.8086
	;NOSMART
ENDIF

ENDM
;
; EMS DEFINITIONS 
;
SCAMP_PAGE_9000_OFFSET  =   020h

IFDEF COMPILE_CHIPSET

	PAGE_SWAP_ARG_MULT = 1


	IF COMPILE_CHIPSET EQ CHIPSET_SCAT
		EMS_MEMORY_PAGE_OFFSET  = 08080h
		EMS_AUTOINCREMENT_FLAG  =   080h
		CHIPSET_PAGE_9000       =   014h
	ELSEIF COMPILE_CHIPSET EQ CHIPSET_SCAMP
		EMS_MEMORY_PAGE_OFFSET  = 00050h
		SCAMP_PAGE_9000_OFFSET  =   020h
		EMS_AUTOINCREMENT_FLAG  =   040h
		CHIPSET_PAGE_9000       =   020h
	ELSEIF COMPILE_CHIPSET EQ CHIPSET_HT18
		EMS_MEMORY_PAGE_OFFSET  = 00050h
		EMS_AUTOINCREMENT_FLAG  =   080h
		CHIPSET_PAGE_9000       =   014h
	ENDIF

	EPR_MACRO MACRO var
		add &var, EMS_MEMORY_PAGE_OFFSET
	ENDM

	NPR_MACRO MACRO amount
	IF COMPILE_CHIPSET EQ CHIPSET_SCAT
		003FFh
	ELSEIF COMPILE_CHIPSET EQ CHIPSET_SCAMP
		&amount + SCAMP_PAGE_9000_OFFSET + 4
	ELSEIF COMPILE_CHIPSET EQ CHIPSET_HT18
		00000h
	ENDIF
	ENDM

ELSE
    PAGE_SWAP_ARG_MULT = 2


	EMS_MEMORY_PAGE_OFFSET  = 00280h
	EPR_MACRO MACRO var

	ENDM

	NPR_MACRO MACRO amount
		0FFFFh
	ENDM

ENDIF

; called with reg in var
; reg may need to be shifted one
; "constant_offset" is on stack. will be added. pre-shifted at build time

SHIFT_PAGESWAP_ARGS MACRO var
	IF PAGE_SWAP_ARG_MULT EQ 1
	ELSE
		sal &var, 1
	ENDIF
	
ENDM









INCLUDE asmtypes.inc

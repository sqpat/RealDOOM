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
_currentscreen    = 				_NULL_OFFSET + 00000h
_destview    = 						_NULL_OFFSET + 00004h
_tantoangle  = 						_NULL_OFFSET + 0000Ch
_spanfunc_jump_segment_storage = 	_NULL_OFFSET + 0000Eh

_detailshift = 						_NULL_OFFSET + 00020h
_detailshiftitercount = 			_NULL_OFFSET + 00022h
_detailshiftandval = 				_NULL_OFFSET + 00024h
_ceilphyspage =                  	_NULL_OFFSET + 00026h
_floorphyspage =                 	_NULL_OFFSET + 00027h

_ds_x1 = 							_NULL_OFFSET + 00028h
_ds_x2 = 							_NULL_OFFSET + 0002Ah
; UNUSED 02Ch
_ds_colormap_index = 				_NULL_OFFSET + 0002Eh
_fixedcolormap = 					_NULL_OFFSET + 0002Fh
_quality_port_lookup = 				_NULL_OFFSET + 00030h
_ds_source_segment = 				_NULL_OFFSET + 0003Eh
; UNUSED 040
_dc_colormap_index = 				_NULL_OFFSET + 00042h
_fuzzpos =							_NULL_OFFSET + 00043h
_dc_yl = 							_NULL_OFFSET + 00044h
_dc_yh = 							_NULL_OFFSET + 00046h
_dc_iscale = 						_NULL_OFFSET + 00048h
_dc_texturemid = 					_NULL_OFFSET + 0004Ch
_dc_x = 							_NULL_OFFSET + 00050h
_lastopening =                   	_NULL_OFFSET + 00052h
_planezlight = 						_NULL_OFFSET + 00054h
_planeheight = 						_NULL_OFFSET + 00058h
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
_viewangle_shiftright1 = 			_NULL_OFFSET + 0007Eh
_rw_x = 							_NULL_OFFSET + 00080h
_rw_stopx = 						_NULL_OFFSET + 00082h 
_rw_offset = 						_NULL_OFFSET + 00084h
_maskedtexture = 					_NULL_OFFSET + 00088h
_segtextured = 						_NULL_OFFSET + 00089h
_markfloor = 						_NULL_OFFSET + 0008Ah
_markceiling = 						_NULL_OFFSET + 0008Bh
_rw_scale =		 					_NULL_OFFSET + 0008Ch
_topfrac =						    _NULL_OFFSET + 00090h
_bottomfrac =					    _NULL_OFFSET + 00094h
_pixlow =					 	    _NULL_OFFSET + 00098h
_pixhigh =					 	    _NULL_OFFSET + 0009Ch
_rw_angle1 =                        _NULL_OFFSET + 000A0h
_spryscale = 						_NULL_OFFSET + 000A4h
_sprtopscreen =	 					_NULL_OFFSET + 000A8h
_ss_variable_space = 				_NULL_OFFSET + 000ACh
_mfloorclip = 						_NULL_OFFSET + 000C0h
_mceilingclip = 					_NULL_OFFSET + 000C4h
_spanfunc_prt = 					_NULL_OFFSET + 000CCh
_spanfunc_destview_offset = 		_NULL_OFFSET + 000D4h
_spanfunc_inner_loop_count =		_NULL_OFFSET + 000DCh
_spanfunc_outp = 					_NULL_OFFSET + 000E0h
_spanfunc_main_loop_count = 		_NULL_OFFSET + 000E4h
_skipdirectdraws = 					_NULL_OFFSET + 000E5h
_jump_mult_table_3 = 				_NULL_OFFSET + 000E6h
_screen_segments = 					_NULL_OFFSET + 000EEh
; F8 FA unused
_func_farcall_scratch_addr =		_NULL_OFFSET + 000FCh
; 0100 0102 unused
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

_MULT_256 =                    		_NULL_OFFSET + 00120h
_MULT_4096 =                    	_NULL_OFFSET + 00128h
_FLAT_CACHE_PAGE =                  _NULL_OFFSET + 00130h
_visplanelookupsegments =           _NULL_OFFSET + 00138h
_firstflat =                  		_NULL_OFFSET + 0013Eh
; 140h
_lightshift7lookup =            	_NULL_OFFSET + 00140h
; 160h
_currentflatpage =            		_NULL_OFFSET + 00160h
_lastflatcacheindicesused =         _NULL_OFFSET + 00164h
_skyflatnum =            			_NULL_OFFSET + 00168h
_extralight =            			_NULL_OFFSET + 00169h
_visplanedirty =            		_NULL_OFFSET + 0016Ah
_screenblocks =            			_NULL_OFFSET + 0016Bh
_lastvisplane =            			_NULL_OFFSET + 0016Ch
_hudneedsupdate =                   _NULL_OFFSET + 0016Eh


; 170h
; 6-16 bytes...
_allocatedflatsperpage =           	_NULL_OFFSET + 00170h

; 180h
_Z_QuickMapVisplanePage_addr =      _NULL_OFFSET + 00180h
_R_EvictFlatCacheEMSPage_addr =     _NULL_OFFSET + 00184h
_Z_QuickMapFlatPage_addr =        	_NULL_OFFSET + 00188h
_R_MarkL2FlatCacheLRU_addr =        _NULL_OFFSET + 0018Ch
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
; 1AC free
_active_visplanes =             	_NULL_OFFSET + 001B0h
; 1B5 free
_visplane_offset =              	_NULL_OFFSET + 001B6h
; up to 1E8
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
_walllights =                        _NULL_OFFSET + 00284h
_maskedtexmodulo =                   _NULL_OFFSET + 00286h
_maskednextlookup =                  _NULL_OFFSET + 00288h
_maskedprevlookup =                  _NULL_OFFSET + 0028Ah
_maskedtexrepeat =                   _NULL_OFFSET + 0028Ch
_maskedcachedbasecol =               _NULL_OFFSET + 0028Eh
_maskedcachedsegment =               _NULL_OFFSET + 00290h
_maskedheightvalcache =              _NULL_OFFSET + 00292h
_vsprsortedheadfirst =               _NULL_OFFSET + 00293h
_lastvisspritesegment =              _NULL_OFFSET + 00294h
_lastvisspritesegment2 =             _NULL_OFFSET + 00296h
_lastvisspritepatch =                _NULL_OFFSET + 00298h
_lastvisspritepatch2 =               _NULL_OFFSET + 0029Ah
_ds_p =               				 _NULL_OFFSET + 0029Ch
_lightmult48lookup =                 _NULL_OFFSET + 002A0h

_FixedMul_addr =               		 _NULL_OFFSET + 002C0h
_FixedMul1632_addr =                 _NULL_OFFSET + 002C4h
_FastDiv3232_addr =                  _NULL_OFFSET + 002C8h
_R_GetMaskedColumnSegment_addr =     _NULL_OFFSET + 002CCh


_colfunc_call_lookup =               _NULL_OFFSET + 002D0h

; 354
_getspritetexture_addr =             _NULL_OFFSET + 00354h
_psprites =              			 _NULL_OFFSET + 00358h
_vga_read_port_lookup =              _NULL_OFFSET + 00370h
_vissprite_p =                       _NULL_OFFSET + 00388h
; high byte always 0
_cachedbyteheight =                  _NULL_OFFSET + 0038Ah


; 38Ch



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








; todo what is this magic number again? (??) r_draw.c alludes to it as desired bx offset
DRAWSPAN_BX_OFFSET             = 0FC0h
DRAWSPAN_CALL_OFFSET           = (16 * (SPANFUNC_FUNCTION_AREA_SEGMENT - COLORMAPS_SEGMENT)) + DRAWSPAN_BX_OFFSET

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


INSTRUCTION_SET_MACRO MACRO 

;IF COMPILE_INSTRUCTIONSET EQ COMPILE_386
;	.386
;ELSEIF COMPILE_INSTRUCTIONSET EQ COMPILE_286
IF COMPILE_INSTRUCTIONSET GE COMPILE_286
	.286
ELSEIF COMPILE_INSTRUCTIONSET EQ COMPILE_186
	.186
ELSE
	.8086
ENDIF


ENDM

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



SCREENWIDTH     =   320
SCREENHEIGHT	=	200

PEL_WRITE_ADR	=	03c8h
PEL_DATA		=	03c9h

SC_INDEX		=	03C4h
SC_MAPMASK		=	2


_NULL_OFFSET = 0030h
_destview    = 						_NULL_OFFSET + 00004h
_tantoangle  = 						_NULL_OFFSET + 0000Ch
_spanfunc_jump_segment_storage = 	_NULL_OFFSET + 0000Eh

_detailshift = 						_NULL_OFFSET + 00020h
_detailshiftitercount = 			_NULL_OFFSET + 00022h
_detailshift2minus = 				_NULL_OFFSET + 00023h
_detailshiftandval = 				_NULL_OFFSET + 00024h

_ds_x1 = 							_NULL_OFFSET + 00028h
_ds_x2 = 							_NULL_OFFSET + 0002Ah
_ds_colormap_segment = 				_NULL_OFFSET + 0002Ch
_ds_colormap_index = 				_NULL_OFFSET + 0002Eh
_fixedcolormap = 					_NULL_OFFSET + 0002Fh
_quality_port_lookup = 				_NULL_OFFSET + 00030h
_ds_source_segment = 				_NULL_OFFSET + 0003Eh
_dc_colormap_segment = 				_NULL_OFFSET + 00040h
_dc_colormap_index = 				_NULL_OFFSET + 00042h
_fuzzpos =							_NULL_OFFSET + 00043h
_dc_yl = 							_NULL_OFFSET + 00044h
_dc_yh = 							_NULL_OFFSET + 00046h
_dc_iscale = 						_NULL_OFFSET + 00048h
_dc_texturemid = 					_NULL_OFFSET + 0004Ch
_dc_x = 							_NULL_OFFSET + 00050h

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
_rw_centerangle = 					_NULL_OFFSET + 00084h
_rw_normalangle =	    	   		_NULL_OFFSET + 00086h
_rw_offset = 						_NULL_OFFSET + 00088h
_rw_distance = 						_NULL_OFFSET + 0008Ch
_rw_scale =		 					_NULL_OFFSET + 00090h
_rw_midtexturemid = 				_NULL_OFFSET + 00094h
_rw_toptexturemid = 				_NULL_OFFSET + 00098h
_rw_bottomtexturemid = 				_NULL_OFFSET + 0009Ch
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
_spanfunc_farcall_addr_1 =      	_NULL_OFFSET + 000F8h
_func_farcall_scratch_addr =		_NULL_OFFSET + 000FCh
_colfunc_farcall_addr_1   =    		_NULL_OFFSET + 00100h
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

DRAWSPAN_BX_OFFSET             = 0FC0h
DRAWSPAN_CALL_OFFSET           = (16 * (SPANFUNC_FUNCTION_AREA_SEGMENT - 06800h)) + DRAWSPAN_BX_OFFSET

DRAWCOL_OFFSET                 = (COLFUNC_FUNCTION_AREA_SEGMENT - 06800h) * 16

; todo copy this from C via script
VISPLANES_PER_EMS_PAGE         = 25
MAX_CONVENTIONAL_VISPLANES     = 75
VISPLANE_BYTE_SIZE             = (6 + (2 * SCREENWIDTH))

LIGHTLEVELS					   = 16
LIGHTSEGSHIFT				   = 4
NUM_FLAT_CACHE_PAGES           = 6

VISPLANE_BYTES_PER_PAGE        = (VISPLANE_BYTE_SIZE * VISPLANES_PER_EMS_PAGE)
FIRST_VISPLANE_PAGE_SEGMENT    = 08400h

EXTRN	_pageswapargs:WORD

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

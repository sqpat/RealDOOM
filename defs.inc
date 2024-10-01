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
_destview    = 				_NULL_OFFSET + 00004h
_tantoangle  = 				_NULL_OFFSET + 0000Ch
_detailshift = 				_NULL_OFFSET + 00020h
_detailshiftitercount = 	_NULL_OFFSET + 00022h
_detailshift2minus = 		_NULL_OFFSET + 00023h
_detailshiftandval = 		_NULL_OFFSET + 00024h

_ds_y = 					_NULL_OFFSET + 00026h
_ds_x1 = 					_NULL_OFFSET + 00028h
_ds_x2 = 					_NULL_OFFSET + 0002Ah
_ds_colormap_segment = 		_NULL_OFFSET + 0002Ch
_ds_colormap_index = 		_NULL_OFFSET + 0002Eh


_quality_port_lookup = 		_NULL_OFFSET + 00030h

_ds_source_segment = 		_NULL_OFFSET + 0003Ch

EXTRN _viewangle_shiftright3:WORD

EXTRN	_dc_x:WORD
EXTRN	_dc_yl:WORD
EXTRN	_dc_yh:WORD
EXTRN	_dc_colormap_segment:WORD
EXTRN	_dc_source_segment:WORD
EXTRN	_dc_iscale:DWORD
EXTRN	_dc_texturemid:DWORD


EXTRN _basexscale:WORD
EXTRN _planezlight:WORD
EXTRN _fixedcolormap:BYTE
EXTRN _viewx:WORD
EXTRN _viewy:WORD
EXTRN _baseyscale:WORD
EXTRN _basexscale:WORD
EXTRN _viewangle_shiftright3:WORD
EXTRN _centeryfrac_shiftright4:WORD
EXTRN _planeheight:WORD


EXTRN   _sp_bp_safe_space:WORD
EXTRN   _ss_variable_space:WORD

EXTRN _spanfunc_main_loop_count:BYTE
EXTRN _spanfunc_inner_loop_count:BYTE
EXTRN _spanfunc_outp:BYTE
EXTRN _spanfunc_prt:WORD
EXTRN _spanfunc_destview_offset:WORD



EXTRN _viewangle_shiftright3:WORD
EXTRN _centerx:WORD
EXTRN _rw_distance:WORD
EXTRN _rw_normalangle:WORD


EXTRN   _spryscale:DWORD
EXTRN   _sprtopscreen:WORD
EXTRN   _mfloorclip:WORD
EXTRN   _mceilingclip:WORD
EXTRN  _fuzzpos:BYTE
EXTRN  _R_DrawColumnPrepCallHigh:WORD


EXTRN	_centery:WORD


EXTRN	_dc_colormap_index:BYTE
EXTRN	_dc_colormap_segment:WORD

EXTRN   _sp_bp_safe_space:WORD
EXTRN   _ss_variable_space:WORD

EXTRN	_skipdirectdraws:BYTE

EXTRN   _screen_segments:WORD
EXTRN   _jump_mult_table_3:BYTE

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

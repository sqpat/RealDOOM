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
_destview    = _NULL_OFFSET + 00004h

EXTRN	_dc_x:WORD
EXTRN	_dc_yl:WORD
EXTRN	_dc_yh:WORD
EXTRN	_dc_colormap_segment:WORD
EXTRN	_dc_source_segment:WORD
EXTRN	_dc_iscale:DWORD
EXTRN	_dc_texturemid:DWORD


EXTRN	_ds_y:WORD
EXTRN	_ds_x1:WORD
EXTRN	_ds_x2:WORD


EXTRN   _ds_source_segment:WORD

EXTRN   _ds_colormap_index:BYTE
EXTRN   _ds_colormap_segment:WORD
EXTRN   _detailshift:BYTE
EXTRN   _detailshiftitercount:BYTE
EXTRN   _detailshift2minus:BYTE
EXTRN   _quality_port_lookup:BYTE
EXTRN   _detailshiftandval:WORD


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

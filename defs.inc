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
SKIPPRIMITIVES	=  0			; set to 1 to skip unwound drawing


SCREEN  =       0a0000h
SCREENWIDTH     =   320
SCREENHEIGHT	=	200
PLANEWIDTH		=	80
PLANESIZE		=	80*200

PEL_WRITE_ADR	=	03c8h
PEL_DATA		=	03c9h

SC_INDEX		=	03C4h
SC_MAPMASK		=	2

OP_RET		=	0c3h
OP_MOVAL	= 	08ah
OP_MOVDEST	= 	088h

COLFUNC_JUMP_LOOKUP_SEGMENT    = 6A10h
DC_YL_LOOKUP_SEGMENT           = 6A29h


	.DATA

EXTRN	_dc_x:WORD
EXTRN	_dc_yl:WORD
EXTRN	_dc_yh:WORD
EXTRN	_dc_colormap_segment:WORD
EXTRN	_dc_source_segment:WORD
EXTRN	_dc_iscale:DWORD
EXTRN	_dc_texturemid:DWORD

;EXTRN	_ylookup:DWORD
;EXTRN	_columnofs:DWORD


EXTRN	_ds_y:WORD
EXTRN	_ds_x1:WORD
EXTRN	_ds_x2:WORD
EXTRN	_ds_xfrac:DWORD
EXTRN	_ds_yfrac:DWORD
EXTRN	_ds_xstep:DWORD
EXTRN	_ds_ystep:DWORD
EXTRN   _ds_source_segment:WORD

EXTRN   _ds_colormap_index:BYTE
EXTRN   _ds_colormap_segment:WORD
EXTRN	_destview:DWORD
EXTRN   _detailshift:BYTE
EXTRN   _quality_port_lookup:BYTE


PUSHR	MACRO
	pushad
ENDM

POPR	MACRO
	popad
ENDM

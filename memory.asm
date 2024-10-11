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
; DESCRIPTION:
;
INCLUDE defs.inc

INSTRUCTION_SET_MACRO
	.MODEL  medium


SEGMENT _FIXEDDATA  USE16 PARA PUBLIC 'DATA'
db 0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0
; spanfunc_segment_storage 0Eh
dw SPANFUNC_JUMP_LOOKUP_SEGMENT
; 010h
db 0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0
db 0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0
; _quality_port_lookup 0x30
db 1,  2,  4,  8,  3, 12,  3, 12, 15, 15, 15, 15
; _ds_source_segment  0x3E (and _ds_source_segment -2 = 0x3C)
dw                                       DRAWSPAN_BX_OFFSET, 0000h

db 0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0
db 0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0
db 0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0
db 0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0
db 0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0
db 0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0
db 0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0
db 0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0
db 0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0
db 0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0
; E6h jump_mult_table_3[8]
; EEh screen_segments[5]
db 0,  0,  0,  0,  0,  0, 21, 18, 15, 12,  9,  6,  3,  0
dw                                                         8000h
;  spanfunc_farcall_addr_1   0x00F8
;  func_farcall_scratch_addr   0x00FC
dw 8000h,  7000h,  6000h,  9C00h,    DRAWSPAN_CALL_OFFSET,     00,     00,    00
; 0x100:
;  colfunc_farcall_addr_1   0x0100
; _viewangle_shiftright3 0x104
; _dc_source_segment  0x10A
dw DRAWCOL_OFFSET, 00, 00h, XTOVIEWANGLE_SEGMENT,  004Fh, 00h, 00h, DC_YL_LOOKUP_SEGMENT
dw 00, CACHEDHEIGHT_SEGMENT, DISTSCALE_SEGMENT, CACHEDDISTANCE_SEGMENT, CACHEDXSTEP_SEGMENT, CACHEDYSTEP_SEGMENT




    

ENDS _FIXEDDATA

GROUP DGROUP _FIXEDDATA



END
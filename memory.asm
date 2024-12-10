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


;0x40
db 0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0
;0x50   0x54 = _planezlight (dword, so segment in 56)
dw 0,  0,  0,  ZLIGHT_SEGMENT,  0,  0,  0,  0
db 0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0
db 0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0
db 0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0
db 0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0
db 0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0
db 0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0
; _mfloorclip segment = c2, _mceilingclip segment = c6
dw 0,  OPENINGS_SEGMENT,  0,  OPENINGS_SEGMENT,  0,  0,  0,  0
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
dw 00, CACHEDHEIGHT_SEGMENT, DISTSCALE_SEGMENT, CACHEDDISTANCE_SEGMENT, CACHEDXSTEP_SEGMENT, CACHEDYSTEP_SEGMENT, 0, 0
; MULT_256 0x120
dw 00, 0100h, 0200h, 0300h
; MULT_4096 0x128
dw 00, 01000h, 02000h, 03000h
; FLAT_CACHE_PAGE 0x130
dw 07000h, 07400h, 07800h, 07C00h
; visplanelookupsegments  0x138
dw 08400h, 08800h, 08C00h
; firstflat 0x13E
dw 00h


; lightshift7lookup 0x140
dw  0,  128,  256, 384, 512,  640,  768, 896
dw 1024, 1152, 1280, 1408, 1536, 1664, 1792, 1920

; 0x160
; currentflatpage 0x160, lastflatcacheindicesused 0x164
db 0, 1, 2, 3, 0, 1, 2, 3
; 0x168
dw  00, 00, 00, 00
; 0x170 
dw  00, 00, 00, 00, 00, 00, 00, 00
; 0x180
dw  00, 00, 00, 00, 00, 00, 00, 00
; 0x190
dw  00, 00, 00, 00, 00, 00, 00, 00
; 0x1A0  _frontsector backsector 1a4 1a8, set their segments


dw  00, 00, 00, SECTORS_SEGMENT, 00, SECTORS_SEGMENT, 00, 00
; 0x1B0
; _active_visplanes[5]... one byte free
db  1, 2, 3, 0, 0, 0
; 0x1B6  _visplane_offset[25]
dw 	0, 646 ,1292, 1938, 2584
dw	3230,  3876, 4522, 5168, 5814 
dw	6460,  7106, 7752, 8398, 9044
dw	9690,  10336, 10982, 11628, 12274 
dw	12920,  13566, 14212, 14858, 15504
; 1E8 dirtybox
dw  00, 00, 00, 00
; 1F0 ticcount...
dw  00, 00, 00, 00, 00, 00, 00, 00
dw  00, 00, 00, 00, 00, 00, 00, 00
dw  00, 00, 00, 00

; 218
; 
dw 0FFFFh, MASKEDPIXELDATAOFS_SEGMENT



    

ENDS _FIXEDDATA

GROUP DGROUP _FIXEDDATA



END
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
INCLUDE states.inc

INSTRUCTION_SET_MACRO
	.MODEL  medium


SEGMENT _FIXEDDATA  USE16 PARA PUBLIC 'DATA'
; 000   _segloopnextlookup 00
dw  -1, -1, 00, 00, 00, 00, 00, 00




; 010  
dw  00, 00, 00, 00, 00, 00, 00, 00
; 020   28 = maxammo  
dw  00, 00, 00, 00, 200, 50, 300, 50
; _quality_port_lookup 0x30
db 1,  2,  4,  8,  3, 12,  3, 12, 15, 15, 15, 15

;0x3C
dw                                       00, 00
;0x40   
dw  00, 00, 00, 00, 00, 00, 00, 00
;0x50   0x54 = _planezlight (dword, so segment in 56)	 0x58 caststate (0x5A is STATES_SEGMENT) 
dw 0,  0,  0,  ZLIGHT_SEGMENT,  0,  STATES_SEGMENT,  0,  0
;0x60
dw 0, 0, 0, 0, 0, 0, 0, 0
;0x70  7E = screen_segments
dw 00, 00, 00, 00, 00, 00, 00, 8000h
; 0x80
dw 8000h,  7000h,  6000h,  9C00h,    00, 00,     00,    00
; 0x90
dw 0, 0, 0, 0, 0, 0, 0, 0
;0xA0
dw 0, 0, 0, 0, 0, 0, 0, 0
;0xB0
dw 0, 0, 0, 0, 0, 0, 0, 0
; _mfloorclip segment = c2, _mceilingclip segment = c6
; 0xC0
dw 0,  OPENINGS_SEGMENT,  0,  OPENINGS_SEGMENT,  0,  0,  0,  0
; 0xD0
; _ds_source_segment  0xDA
dw 00, 00, 00, 00, 00, 00, 00, 00
; 0xE0    spanfunc_segment_storage EAh
dw 0, 0, 0, 0, 0, SPANFUNC_JUMP_LOOKUP_SEGMENT, 0, 0


; 0xF0   validcount (0xF4)= 1
dw 0, 0, 1, 0, 0, 0, 0, 0
; 0x100:
;  unused   0x0100
; _viewangle_shiftright3 0x104
; _dc_source_segment  0x10A
dw 00, 00, 00h, XTOVIEWANGLE_SEGMENT,  004Fh, 00h, 00h, DC_YL_LOOKUP_SEGMENT
dw 00, CACHEDHEIGHT_SEGMENT, DISTSCALE_SEGMENT, CACHEDDISTANCE_SEGMENT, CACHEDXSTEP_SEGMENT, CACHEDYSTEP_SEGMENT, 0, 0
; todo unused
; 0x120
dw 00, 00h, 00h, 00h
; MULT_4096 0x128
dw 00, 01000h, 02000h, 03000h
; 0x130
dw  00, 00, 00, 00
; visplanelookupsegments  0x138
dw 08400h, 08800h, 08C00h
; firstflat 0x13E
dw 00h

; 0x140
dw  00, 00, 00, 00, 00, 00, 00, 00
; 0x150
dw  00, 00, 00, 00, 00, 00, 00, 00

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
db  1, 2, 3, 0, 0
; 0x1B5 wipegamestate
db  GS_DEMOSCREEN
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

; 21C
; _maskedtexturecol and its segment
dw 00, OPENINGS_SEGMENT
; 220 masked_headers 12 * 8 bytes
dw  00, 00, 00, 00, 00, 00, 00, 00
dw  00, 00, 00, 00, 00, 00, 00, 00
dw  00, 00, 00, 00, 00, 00, 00, 00
dw  00, 00, 00, 00, 00, 00, 00, 00
dw  00, 00, 00, 00, 00, 00, 00, 00
dw  00, 00, 00, 00, 00, 00, 00, 00
; 280 ; 284 save_p, 286 segment
dw  00, 00, 00, DEMO_SEGMENT, 00, NULL_TEX_COL, 00, NULL_TEX_COL
dw  00, 00, 0FFFFh, 0FFFFh, 0FFFFh, 0FFFFh, 00, DRAWSEGS_BASE_SEGMENT
; 2A0
dw  00, 00, 00, 00, 00, 00, 00, 00
; 2B0
dw  00, 00, 00, 00, 00, 00, 00, 00
; 2C0
dw  00, 00, 00, 00, 00, 00, 00, 00

; 2D0 
dw  00, 00, 00, 00, 00, 00, 00, 00
; 2E0 
dw  00, 00, 00, 00, 00, 00, 00, 00
; 2F0 
dw  00, 00, 00, 00, 00, 00, 00, 00
; 300 
dw  00, 00, 00, 00, 00, 00, 00, 00
; 310 
dw  00, 00, 00, 00, 00, 00, 00, 00
; 320 
dw  00, 00, 00, 00, 00, 00, 00, 00
; 330
dw  00, 00, 00, 00, 00, 00

; 33C (33D = follow player, default to 1)
db 0, 1, 0, 0
; 340
dw  00, 00, 00, 00, 00, 00, 00, 00
; 350
dw  00, 00, 00, 00
; 358 _vga_read_port_lookup
dw   4, 260, 516, 772,  4, 516, 4, 516
dw 	 4, 4, 4, 4
; 370
dw  00, 00, 00, 00, 00, 00, 00, 00
; 380
dw  00, 00, 00, 00, 00, 00, 00, 00
; 390
dw  00, 00, 00, 00, 00, 00, 00, 00
; 3A0
dw  00, 00, 00, 00, 00, 00, 00, 00
; 3B0
dw  00, 00, 00, 00, 00, 00, 00, 00


; 3C0 ems_backfill_page_order[24] 
dw  00, 00, 00
; 3C6 _SKY_String
db "SKY1", 0
; 3CB 
db 00, 00, 00, 00, 00

; 3D0  ; 3d8 = demo_p, so 3da is its segment
dw  00, 00, 00, 00, 00, DEMO_SEGMENT, 00, 00

; 3E0 braintargets[32]
dw  00, 00, 00, 00, 00, 00, 00, 00
; 3F0 braintargets
dw  00, 00, 00, 00, 00, 00, 00, 00
; 400 braintargets
dw  00, 00, 00, 00, 00, 00, 00, 00
; 410 braintargets
dw  00, 00, 00, 00, 00, 00, 00, 00
; 420
dw  00, 00, 00, 00, 00, 00, 00, 00



; 430
dw  SECTORS_SEGMENT, LINES_PHYSICS_SEGMENT, VERTEXES_SEGMENT, LINEFLAGSLIST_SEGMENT, SEENLINES_6800_SEGMENT, SIDES_SEGMENT, 00, 00
; 440
dw  00, 00, 00, 00, 00, 00, 00, 00
; UNUSED NOW
; 450
dw  00, 00



; 454
dw         0, 0, 0, 0, 0, 0
; 460
dw  00, 00, 00, 00, 00, 00, 00, 00
; 470
dw  00, 00, 00, 00, 00, 00, 00, 00
; 480
dw  00, 00, 00, 00, 00, 00, 00, 00
; 490
dw  00, 00, 00, 00, 00
; 49A
db 0, 0, 0, 0
; 49E
dw 0
; 4A0
dw  00, 00, 00, 00, 00, 00, 00, 00
; 4B0
dw  00, 00, 00, 00, 00, 00, 00, 00
; 4C0
dw  00, 00, R_DRAWSKYPLANE_DYNAMIC_OFFSET, DRAWSKYPLANE_AREA_SEGMENT, 00, 00, 00, 00
; 4D0
dw  00, 00, 00, 00, 00, 00, 00, 00
; 4E0
dw  00, 00, 00, 00, 00, 00, 00, 00
; 4F0
dw  00, 00, 00, 00, 00, 00, 00, 00
; 500
dw  00, 00, 00, 00, 00, 00, 00, 00
; 510 ; _playingdriver here, should default 0..
dw  00, 00, 00, 00, 00, 00, 00, 00
; 520
dw  00, 00, 00, 00, 00, 00, 00, 00
; 530
dw  00, 00, 00, 00, 00, 00, 00, 00
; 540	; 548 is sfx_free_bytes. give it 40 pages just in case for 4 MB build..
dw  00, 00, 00, 00, 00, 00, 00, 00
; 550
dw  00, 00, 00, 00, 00, 00, 00, 00
; 560
dw  00, 00, 00, 00, 00, 00, 00, 00
; 570
dw  00, 00, 00, 00, 00, 00, -1, -1
; 580
dw  00, 00, 00, 00, 00, 00, 00, 00
; 590
dw  00, 00, 00, 00, 00, 00, 00, 00
; 5A0
dw  00, 00, 00, 00, -1, -1, 0
db 0, NUM_FLAT_CACHE_PAGES-1
; 5B0
dw  00, 00, 00, 00, -1, -1, 00, 00
; 5C0
dw  00, 00, 00, 00, 00, 00, 00, 00
; 5D0
dw  00, 00, 00, 00, 00, 00, 00, 00
; 5E0
dw  00, 00, 00, 00, 00, 00, 00, 00
; 5F0 
db 0, 0, 0
; 5F3 currenttask
db -1
; 5F4
dw          R_DRAWSKYPLANE_OFFSET, DRAWSKYPLANE_AREA_SEGMENT, 00, 00, 00, 00

; 600
dw  00, MOBJPOSLIST_6800_SEGMENT, 00, MOBJPOSLIST_6800_SEGMENT, 00, 00,  00, 00

; 610 solidsegs
dw  00, 00, 00, 00, 00, 00, 00, 00
dw  00, 00, 00, 00, 00, 00, 00, 00
dw  00, 00, 00, 00, 00, 00, 00, 00
dw  00, 00, 00, 00, 00, 00, 00, 00
dw  00, 00, 00, 00, 00, 00, 00, 00
dw  00, 00, 00, 00, 00, 00, 00, 00
dw  00, 00, 00, 00, 00, 00, 00, 00
dw  00, 00, 00, 00, 00, 00, 00, 00
; 690  
dw  00, 00, 00, 00, 00, 00, 00, 00
; 6A0 
dw  00, 00, 00, 00, 00, 00, 00, 00
; 6B0 
dw  00, 00, 00, 00, 00, 00, 00, 00
; 6C0 
dw  00, 00, 00, 00, 00, 00, 00, 00
; 6D0 
dw  00, 00, 00, 00, 00, 00, 00, 00
; 6E0 
dw  00, 00, 00, 00, 00, 00, 00, 00
; 6F0 
dw  00, 00, 00, 00, 00, 00, 00, 00
; 700
dw  00, 00, 00, 00
; 708 R_DrawPlanesCall
dw R_DrawPlanes24Offset, spanfunc_jump_lookup_segment
; 70C R_DrawMaskedCall
dw R_DrawMasked24Offset, drawfuzzcol_area_segment

; 710 R_WriteBackMaskedFrameConstants
dw R_WriteBackMaskedFrameConstants24Offset, maskedconstants_funcarea_segment
; 714 R_WriteBackViewConstantsSpan
;dw R_WriteBackViewConstantsSpan24Offset, spanfunc_jump_lookup_segment

; 714
dw  00, 00, 00, 00, 00, 00

; 720
dw  00, 00, 00, 00

; 728 _weaponinfo
; fist
db AM_NOAMMO
dw S_PUNCHUP, S_PUNCHDOWN, S_PUNCH, S_PUNCH1, S_NULL
; pistol
db AM_CLIP
dw S_PISTOLUP, S_PISTOLDOWN, S_PISTOL, S_PISTOL1, S_PISTOLFLASH
; shotgun
db AM_SHELL
dw S_SGUNUP, S_SGUNDOWN, S_SGUN, S_SGUN1, S_SGUNFLASH1
; chaingun
db AM_CLIP
dw S_CHAINUP, S_CHAINDOWN, S_CHAIN, S_CHAIN1, S_CHAINFLASH1
; missile launcher
db AM_MISL
dw S_MISSILEUP, S_MISSILEDOWN, S_MISSILE, S_MISSILE1, S_MISSILEFLASH1
; plasma rifle
db AM_CELL
dw S_PLASMAUP, S_PLASMADOWN, S_PLASMA, S_PLASMA1, S_PLASMAFLASH1
; bfg 9000
db AM_CELL
dw S_BFGUP, S_BFGDOWN, S_BFG, S_BFG1, S_BFGFLASH1
; chainsaw
db AM_NOAMMO
dw S_SAWUP, S_SAWDOWN, S_SAW, S_SAW1, S_NULL
; super shotgun
db AM_SHELL
dw S_DSGUNUP, S_DSGUNDOWN, S_DSGUN, S_DSGUN1, S_DSGUNFLASH1

; 78B

db 0, 0, 0, 0, 0

; 790 w_title 89 bytes...
dw  00, 00, 00, 00, 00, 00, 00, 00
; 7A0
dw  00, 00, 00, 00, 00, 00, 00, 00
; 7B0
dw  00, 00, 00, 00, 00, 00, 00, 00
; 7C0  
db  "doomsav0.dsg", 0
; 7CD
db  0, 0, 0
; 7D0
dw  00, 00, 00, 00, 00, 00, 00, 00
; 7E0 
dw  00, 00, 00, 00, 00, 00, 00, 00
; 7F0
dw  00, 00, 00, 00, 00, 00, 00, 00
; 800
dw  00, 00, 00, 00, 00, 00, 00, 00
; 810
dw  00, 00, 00, 00, 00, 00, 00, 00
; 820
dw  00, 00, 00, 00, 00, 00, 00, 00
; 830
dw  00, 00, 00, 00, 00, 00, 00, 00
; 840
dw  00, 00, 00, 00, 00, 00, 00, 00
; 850
dw  00, 00, 00, 00, 00, 00, 00, 00
; 860
dw  00, 00, 00, 00, 00, 00, 00, 00
; 870
dw  00, 00, 00, 00, 00, 00, 00, 00
; 880
dw  00, 00, 00, 00, 00, 00, 00, 00
; 890
dw  00, 00, 00, 00, 00, 00, 00, 00
; 8A0
dw  00, 00, 00, 00, 00, 00, 00, 00
; 8B0
dw  00, 00, 00, 00, 00, 00, 00, 00
; 8C0
dw  00, 00, 00, 00, 00, 00, 00, 00
; 8D0
dw  00, 00, 00, 00, 00, 00, 00, 00
; 8E0
dw  00, 00, 00, 00, 00, 00, 00, 00
; 8F0
dw  00, 00, 00, 00, 00, 00, 00, 00
; 900
dw  00, 00, 00, 00, 00, 00, 00, 00
; 910
dw  00, 00, 00, 00, 00, 00, 00, 00
; 920
dw  00, 00, 00, 00, 00, 00, 00, 00
; 930
dw  00, 00, 00, 00, 00, 00, 00, 00
; 940
dw  00, 00, 00, 00, 00, 00, 00, 00
; 950
dw  00, 00, 00, 00, 00, 00, 00, 00
; 960
dw  00, 00, 00, 00, 00, 00, 00, 00
; 970
dw  00, 00, 00, 00, 00, 00, 00, 00
; 980
dw  00, 00, 00, 00, 00, 00, 00, 00
; 990
dw  00, 00, 00, 00, 00, 00, 00, 00
; 9A0
dw  00, 00, 00, 00, 00, 00, 00, 00
; 9B0
dw  00, 00, 00, 00, 00, 00, 00, 00
; 9C0
dw  00, 00, 00, 00, 00, 00, 00, 00
; 9D0
dw  00, 00, 00, 00, 00, 00, 00, 00
; 9E0
dw  00, 00, 00, 00, 00, 00, 00, 00
; 9F0
dw  00, 00, 00, 00, 00, 00, 00, 00
; A00
dw  00, 00, 00, 00, 00, 00, 00, 00
; A10  
dw  00, 00, 00, 00, 00, 00, 00, 00
; A20
dw  00, 00, 00, 00, 00, 00, 00, 00
; A30
db 0
; A31
db 0
; A32
db 10, 0
; A34
dw      00, 00, 00, 00, 00, 00
; A40 hu_font
dw  00, 00, 00, 00, 00, 00, 00, 00
; A50 hu_font
dw  00, 00, 00, 00, 00, 00, 00, 00
; A60 hu_font
dw  00, 00, 00, 00, 00, 00, 00, 00
; A70 hu_font
dw  00, 00, 00, 00, 00, 00, 00, 00
; A80 hu_font
dw  00, 00, 00, 00, 00, 00, 00, 00
; A90 hu_font
dw  00, 00, 00, 00, 00, 00, 00, 00
; AA0 hu_font
dw  00, 00, 00, 00, 00, 00, 00, 00
; AB0 hu_font
dw  00, 00, 00, 00, 00, 00, 00, 00
; AC0  
dw  00, 00, 00, 00, 00, 00, 00, 00
; AD0 
dw  00, 00, 00, 00, 00, 00



; ADC ; file 0
dw 00, 00, 00, 00, 00 ; file 0
dw 00, 00, 00, 00, 00 ; file 1
dw 00, 00, 00, 00, 00 ; file 2
dw 00, 00, 00, 00, 00 ; file 3
dw 00, 00, 00, 00, 00 ; file 4
dw 00, 00, 00, 00, 00 ; file 5


; command line copy
; B18
dw  00, 00, 00, 00
; B20
dw  00, 00, 00, 00, 00, 00, 00, 00
; B30
dw  00, 00, 00, 00, 00, 00, 00, 00
; B40 ; file buffer
FILE_BUFFER_SIZE = 512

REPT FILE_BUFFER_SIZE
	db  0
ENDM
; D40
REPT FILE_BUFFER_SIZE
	db  0
ENDM
; F40

REPT NUM_FLAT_CACHE_PAGES
	dw  00
ENDM

REPT NUM_SPRITE_CACHE_PAGES
	dw  00, 00
ENDM

REPT NUM_TEXTURE_PAGES
	dw  00, 00
ENDM

REPT NUM_FLAT_CACHE_PAGES
	db  00
ENDM

REPT NUM_SPRITE_CACHE_PAGES
	db  00
ENDM

REPT NUM_TEXTURE_PAGES
	db  00
ENDM

REPT NUM_SFX_PAGES
	db  00
ENDM

REPT NUM_SFX_PAGES
	dw  00, 00
ENDM


;pageswapargs


	; physics
	_NPR PAGE_4000_OFFSET		 			 		PAGE_4000_OFFSET	;pageswapargs_phys_offset_size
	_NPR PAGE_4400_OFFSET		 			 		PAGE_4400_OFFSET 
	_NPR PAGE_4800_OFFSET		 			 		PAGE_4800_OFFSET 
	_NPR PAGE_4C00_OFFSET		 			 		PAGE_4C00_OFFSET
	_NPR PAGE_5000_OFFSET 		 			 		PAGE_5000_OFFSET
	_NPR PAGE_5400_OFFSET		 			 		PAGE_5400_OFFSET
	_NPR PAGE_5800_OFFSET		 			 		PAGE_5800_OFFSET
	_NPR PAGE_5C00_OFFSET		 			 		PAGE_5C00_OFFSET
	_NPR PAGE_6000_OFFSET	 			 		 	PAGE_6000_OFFSET
	_NPR PAGE_6400_OFFSET							PAGE_6400_OFFSET
	_EPR 13		 			 		            	PAGE_6800_OFFSET
	_EPR 14 	 				    	 			PAGE_6C00_OFFSET
	_NPR PAGE_7000_OFFSET				 			PAGE_7000_OFFSET
	_NPR PAGE_7400_OFFSET	 						PAGE_7400_OFFSET
	_NPR PAGE_7800_OFFSET				 			PAGE_7800_OFFSET 
	_NPR PAGE_7C00_OFFSET	 						PAGE_7C00_OFFSET
	_NPR PAGE_8000_OFFSET					 		PAGE_8000_OFFSET ;pageswapargs_screen0_offset_size
	_NPR PAGE_8400_OFFSET					 		PAGE_8400_OFFSET
	_NPR PAGE_8800_OFFSET					 		PAGE_8800_OFFSET
	_NPR PAGE_8C00_OFFSET		 					PAGE_8C00_OFFSET
	_NPR PAGE_9000_OFFSET 		 					PAGE_9000_OFFSET ;pageswapargs_physics_code_offset_size
	_NPR PAGE_9400_OFFSET 							PAGE_9400_OFFSET ;
	_NPR PAGE_9800_OFFSET 							PAGE_9800_OFFSET
	_EPR FIRST_LUMPINFO_LOGICAL_PAGE+2 		 		PAGE_9C00_OFFSET
		
	_EPR 0		 									PAGE_4000_OFFSET ;pageswapargs_rend_offset_size   ; render
	_EPR 1					 						PAGE_4400_OFFSET
	_EPR 2								 			PAGE_4800_OFFSET
	_EPR 3									 		PAGE_4C00_OFFSET
	_EPR FIRST_TEXTURE_LOGICAL_PAGE+0		 		PAGE_5000_OFFSET ;pageswapargs_rend_texture_size
	_EPR FIRST_TEXTURE_LOGICAL_PAGE+1		 		PAGE_5400_OFFSET
	_EPR FIRST_TEXTURE_LOGICAL_PAGE+2		 		PAGE_5800_OFFSET
	_EPR FIRST_TEXTURE_LOGICAL_PAGE+3		 		PAGE_5C00_OFFSET
	; texture cache area
	_EPR FIRST_TEXTURE_LOGICAL_PAGE+4		 		PAGE_6000_OFFSET ;texture cache area
	_EPR FIRST_TEXTURE_LOGICAL_PAGE+5		 		PAGE_6400_OFFSET
	_EPR FIRST_TEXTURE_LOGICAL_PAGE+6		 		PAGE_6800_OFFSET
	_EPR FIRST_TEXTURE_LOGICAL_PAGE+7		 		PAGE_6C00_OFFSET  
	_EPR 7									 		PAGE_7000_OFFSET
	_EPR 8								 			PAGE_7400_OFFSET
	_EPR 9					 						PAGE_7800_OFFSET
	_EPR 10		 									PAGE_7C00_OFFSET
	_EPR 4									 		PAGE_8000_OFFSET
	_EPR 5						 					PAGE_8400_OFFSET
	_EPR 6			 								PAGE_8800_OFFSET
	_EPR EMS_VISPLANE_EXTRA_PAGE			 		PAGE_8C00_OFFSET
		; this 9000 unused; todo: move 6000-8000 to 7000-9000
		; todo are all these used...?

	_EPR 11 					 					PAGE_9000_OFFSET ;pageswapargs_rend_9000_size
	_EPR 12 				 						PAGE_9400_OFFSET
	_EPR 13 					 					PAGE_9800_OFFSET
	_EPR 14 				 						PAGE_9C00_OFFSET
		; render 4000 to 9000
	_EPR 0					 						PAGE_9000_OFFSET ;pageswapargs_rend_other9000_size
	_EPR 1					 						PAGE_9400_OFFSET 
	_EPR 2					 						PAGE_9800_OFFSET 
	_EPR 3				 							PAGE_9C00_OFFSET	
		; status/hud
	_NPR PAGE_9C00_OFFSET 			 				PAGE_9C00_OFFSET ;pageswapargs_stat_offset_size ;SCREEN4_LOGICAL_PAGE
	_EPR FIRST_STATUS_LOGICAL_PAGE+0 	 			PAGE_7000_OFFSET
	_EPR FIRST_STATUS_LOGICAL_PAGE+1 	 			PAGE_7400_OFFSET
	_EPR FIRST_STATUS_LOGICAL_PAGE+2 	 			PAGE_7800_OFFSET
	_EPR FIRST_STATUS_LOGICAL_PAGE+3 	 			PAGE_7C00_OFFSET
	_NPR PAGE_6000_OFFSET 		 		 			PAGE_6000_OFFSET ; STRINGS_LOGICAL_PAGE
		; demo
	_EPR FIRST_DEMO_LOGICAL_PAGE+0 		 			PAGE_5000_OFFSET ;pageswapargs_demo_offset_size
	_EPR FIRST_DEMO_LOGICAL_PAGE+1 		 			PAGE_5400_OFFSET
	_EPR FIRST_DEMO_LOGICAL_PAGE+2 	 				PAGE_5800_OFFSET
	_EPR FIRST_DEMO_LOGICAL_PAGE+3 		 			PAGE_5C00_OFFSET
	; we use 0x5000 as a  'scratch' page frame for certain things
	; scratch 5000
	_EPR FIRST_SCRATCH_LOGICAL_PAGE+0 		 		PAGE_5000_OFFSET ;pageswapargs_scratch5000_offset_size
	_EPR FIRST_SCRATCH_LOGICAL_PAGE+1 		 		PAGE_5400_OFFSET
	_EPR FIRST_SCRATCH_LOGICAL_PAGE+2 		 		PAGE_5800_OFFSET
	_EPR FIRST_SCRATCH_LOGICAL_PAGE+3 		 		PAGE_5C00_OFFSET
	; but sometimes we need that in the 0x8000 segment..
	; scratch 8000
	_EPR FIRST_SCRATCH_LOGICAL_PAGE+0 				PAGE_8000_OFFSET ;pageswapargs_scratch8000_offset_size
	_EPR FIRST_SCRATCH_LOGICAL_PAGE+1 				PAGE_8400_OFFSET
	_EPR FIRST_SCRATCH_LOGICAL_PAGE+2 				PAGE_8800_OFFSET
	_EPR FIRST_SCRATCH_LOGICAL_PAGE+3		 		PAGE_8C00_OFFSET
			; and sometimes we need that in the 0x7000 segment..
		; scratch 7000
	_EPR FIRST_SCRATCH_LOGICAL_PAGE+0 				PAGE_7000_OFFSET ;pageswapargs_scratch7000_offset_size
	_EPR FIRST_SCRATCH_LOGICAL_PAGE+1 				PAGE_7400_OFFSET
	_EPR FIRST_SCRATCH_LOGICAL_PAGE+2 				PAGE_7800_OFFSET
	_EPR FIRST_SCRATCH_LOGICAL_PAGE+3 				PAGE_7C00_OFFSET
			; and sometimes we need that in the 0x4000 segment..
		; scratch 4000
	_EPR FIRST_SCRATCH_LOGICAL_PAGE+0 				PAGE_4000_OFFSET ;pageswapargs_scratch4000_offset_size
	_EPR FIRST_SCRATCH_LOGICAL_PAGE+1 				PAGE_4400_OFFSET
	_EPR FIRST_SCRATCH_LOGICAL_PAGE+2 				PAGE_4800_OFFSET
	_EPR FIRST_SCRATCH_LOGICAL_PAGE+3 				PAGE_4C00_OFFSET

		; puts sky_texture in the right place adjacent to flat cache for planes
		;  RenderPlane
	_EPR FLAT_DATA_PAGES 							PAGE_5000_OFFSET ;pageswapargs_renderplane_offset_size
	_EPR FLAT_DATA_PAGES+1 							PAGE_5400_OFFSET
	_EPR FLAT_DATA_PAGES+2 							PAGE_5800_OFFSET
	_EPR PALETTE_LOGICAL_PAGE 						PAGE_9C00_OFFSET      ; SPAN CODE SHOVED IN HERE. used to be mobjposlist but thats unused during planes														
		; flat cache
	_EPR FIRST_FLAT_CACHE_LOGICAL_PAGE+0 			PAGE_7000_OFFSET ;pageswapargs_flatcache_offset_size
	_EPR FIRST_FLAT_CACHE_LOGICAL_PAGE+1 			PAGE_7400_OFFSET
	_EPR FIRST_FLAT_CACHE_LOGICAL_PAGE+2 			PAGE_7800_OFFSET
	_EPR FIRST_FLAT_CACHE_LOGICAL_PAGE+3 			PAGE_7C00_OFFSET
		; flat cache undo   NOTE: we just call it with seven params to set everything up for sprites
		; sprite cache
	_EPR FIRST_SPRITE_CACHE_LOGICAL_PAGE+0 			PAGE_9000_OFFSET ;pageswapargs_spritecache_offset_size
	_EPR FIRST_SPRITE_CACHE_LOGICAL_PAGE+1 			PAGE_9400_OFFSET
	_EPR FIRST_SPRITE_CACHE_LOGICAL_PAGE+2 			PAGE_9800_OFFSET
	_EPR FIRST_SPRITE_CACHE_LOGICAL_PAGE+3 			PAGE_9C00_OFFSET
	
	_EPR 11 										PAGE_7000_OFFSET ;pageswapargs_flatcache_undo_offset_size
	_EPR 12 										PAGE_7400_OFFSET
	_EPR RENDER_7800_PAGE 							PAGE_7800_OFFSET
	_EPR RENDER_7C00_PAGE 							PAGE_7C00_OFFSET
		;masked
	_EPR FIRST_EXTRA_MASKED_DATA_PAGE		 		PAGE_8400_OFFSET ;pageswapargs_maskeddata_offset_size
	_EPR FIRST_EXTRA_MASKED_DATA_PAGE+1 			PAGE_8800_OFFSET
	_EPR PHYSICS_RENDER_9800_PAGE PAGE_8C00_OFFSET  ; put colormaps where vissprites used to be?
		;render 9000 to 6000
	_EPR 11 										PAGE_6000_OFFSET ;pageswapargs_render_to_6000_size
	_EPR 12 										PAGE_6400_OFFSET
		; palette
	_NPR PAGE_8000_OFFSET 							PAGE_8000_OFFSET ;pageswapargs_palette_offset_size
	_NPR PAGE_8400_OFFSET 							PAGE_8400_OFFSET
	_NPR PAGE_8800_OFFSET 							PAGE_8800_OFFSET
	_NPR PAGE_8C00_OFFSET 							PAGE_8C00_OFFSET ; SCREEN0_LOGICAL_PAGE
	_EPR PALETTE_LOGICAL_PAGE 						PAGE_9000_OFFSET
	; menu 
	_NPR PAGE_5000_OFFSET 							PAGE_5000_OFFSET ;pageswapargs_menu_offset_size
	_NPR PAGE_5400_OFFSET 							PAGE_5400_OFFSET
	_NPR PAGE_5800_OFFSET 							PAGE_5800_OFFSET
	_EPR FIRST_MENU_GRAPHICS_LOGICAL_PAGE+0 		PAGE_5C00_OFFSET
	_NPR PAGE_6000_OFFSET 				    		PAGE_6000_OFFSET  ; STRINGS_LOGICAL_PAGE
	_EPR FIRST_MENU_GRAPHICS_LOGICAL_PAGE+1 		PAGE_6400_OFFSET
	_NPR PAGE_6800_OFFSET  				    		PAGE_6800_OFFSET
	_NPR PAGE_6C00_OFFSET				    		PAGE_6C00_OFFSET
	; intermission 
	_EPR FIRST_INTERMISSION_GRAPHICS_LOGICAL_PAGE+4 PAGE_6000_OFFSET ;pageswapargs_intermission_offset_size
	_EPR FIRST_INTERMISSION_GRAPHICS_LOGICAL_PAGE+5 PAGE_6400_OFFSET
	_EPR FIRST_INTERMISSION_GRAPHICS_LOGICAL_PAGE+6 PAGE_6800_OFFSET
	_EPR FIRST_INTERMISSION_GRAPHICS_LOGICAL_PAGE+7 PAGE_6C00_OFFSET
	_EPR FIRST_INTERMISSION_GRAPHICS_LOGICAL_PAGE+0 PAGE_7000_OFFSET
	_EPR FIRST_INTERMISSION_GRAPHICS_LOGICAL_PAGE+1 PAGE_7400_OFFSET
	_EPR FIRST_INTERMISSION_GRAPHICS_LOGICAL_PAGE+2 PAGE_7800_OFFSET
	_EPR FIRST_INTERMISSION_GRAPHICS_LOGICAL_PAGE+3 PAGE_7C00_OFFSET
	; wipe/intermission shared pages
	_NPR PAGE_8000_OFFSET 							PAGE_8000_OFFSET ;SCREEN0_LOGICAL_PAGE
	_NPR PAGE_8400_OFFSET 							PAGE_8400_OFFSET
	_NPR PAGE_8800_OFFSET 							PAGE_8800_OFFSET
	_NPR PAGE_8C00_OFFSET 							PAGE_8C00_OFFSET ; also has rndtable
		; wipe start
	_EPR SCREEN1_LOGICAL_PAGE+0 					PAGE_9000_OFFSET ;pageswapargs_wipe_offset_size 
	_EPR SCREEN1_LOGICAL_PAGE+1 					PAGE_9400_OFFSET 
	_EPR SCREEN1_LOGICAL_PAGE+2 					PAGE_9800_OFFSET
	_EPR SCREEN1_LOGICAL_PAGE+3 					PAGE_9C00_OFFSET
	_EPR SCREEN3_LOGICAL_PAGE+0 					PAGE_6000_OFFSET
	_EPR SCREEN3_LOGICAL_PAGE+1 					PAGE_6400_OFFSET ; shared with visplanes. TODO: this works because no level starting screen ever goes beyond 50 visplanes. However savegames might be problematic...
	_EPR SCREEN3_LOGICAL_PAGE+2 					PAGE_6800_OFFSET ; shared with visplanes
	_EPR SCREEN3_LOGICAL_PAGE+3 					PAGE_6C00_OFFSET ; shared with visplanes
	_EPR SCREEN2_LOGICAL_PAGE+0 					PAGE_7000_OFFSET
	_EPR SCREEN2_LOGICAL_PAGE+1 					PAGE_7400_OFFSET
	_EPR SCREEN2_LOGICAL_PAGE+2 					PAGE_7800_OFFSET
	_EPR SCREEN2_LOGICAL_PAGE+3 					PAGE_7C00_OFFSET 	; fwipe_ycolumns_segment here fwipe_mul160lookup_segment too
	
	_EPR EMS_VISPLANE_EXTRA_PAGE 				    PAGE_8400_OFFSET ;pageswapargs_visplanepage_offset_size
	; other 8000? render 4000 to 8000
	_EPR 0					 						PAGE_8000_OFFSET ;pageswapargs_rend_other8000_size
	_EPR 1					 						PAGE_8400_OFFSET 
	_EPR 2					 						PAGE_8800_OFFSET 
	_EPR 3				 							PAGE_8C00_OFFSET	



ENDS _FIXEDDATA

GROUP DGROUP _FIXEDDATA



END
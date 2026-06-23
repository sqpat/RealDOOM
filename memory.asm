; Copyright (C) 1993-1996 Id Software, Inc.
; Copyright (C) 1993-2008 Raven Software
; Copyright (C) 2016-2017 Alexey Khokholov (Nuke.YKT)
; Copyright (C) 2023-2026 Patrick Goncalves (sqpat17)
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
dw  00, 00, 00, 00, 00, MOBJPOSLIST_SEGMENT, 00, 00




; 010  
dw  00, MOBJPOSLIST_SEGMENT, 00, MOBJPOSLIST_SEGMENT, 00, 00,  00, 00
; 020   
dw  00, 00, 00, 00, 00
db 10, 0 ; 2A = newline
dw  00, 00
; _quality_port_lookup 0x30
db 1,  2,  4,  8,  3, 12,  3, 12, 15, 15, 15, 15

;0x3C
dw                                       00, 00
;0x40   
dw  00, 00, 00, 00, 00, 00, 00, 00
;0x50   0x54 = _planezlight (dword, so segment in 56)	
dw 0, 0, 0, 0, 0, 0, 0, 0
;0x60
; visplanelookupsegments
dw 08400h, 08800h, 08C00h
; 0x66
dw  0, 0, 0
; 0x6c 
db  "doomsav0.dsg", 0
; 0x79
db 0
;0x7A  7E = screen_segments
dw 00, 00, 8000h
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
dw 0, 0, 0, 0, 0, SPANFUNC_SEGMENT, 0, 0


; 0xF0   validcount (0xF4)= 1
dw 0, 0, 1, 0, 0, 0, 0, 0
; 0x100:
dw 00, 00, 00h, XTOVIEWANGLE_SEGMENT, 00h, 00h, 00h, BSP_LOCAL_DC_YL_LOOKUP_TABLE_OFFSET SHR 4
; 0x110

; 0x100 R_DrawPlanesCall
dw R_DrawPlanes24Offset, SPANFUNC_SEGMENT
; 0x104 R_DrawMaskedCall
dw R_DrawMasked24Offset, drawfuzzcol_area_segment

; 0x108 R_WriteBackMaskedFrameConstants
dw R_WriteBackMaskedFrameConstants24Offset, maskedconstants_funcarea_segment
; 0x10c _NetUpdate_addr
dw 00, 00

; 0x120
dw  00, 00, 00, 00, 00, 00, 00, 00
; 0x130
dw  00, 00, 00, 00, 00, 00, 00, 00
; 0x140
dw  00, 00, 00, 00, 00, 00, R_DRAWSKYPLANE_DYNAMIC_OFFSET, DRAWSKYPLANE_AREA_SEGMENT
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
dw  R_DRAWSKYPLANEOFFSET, DRAWSKYPLANE_AREA_SEGMENT, 00, 00, 00, 00, 00, 00

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

; 3E0 
dw  00, 00, 00, 00, 00, 00, 00, 00
; 3F0 
dw  00, 00, 00, 00, 00, 00, 00, 00
; 400 
dw  00, 00, 00, 00, 00, 00, 00, 00
; 410 
dw  00, 00, 00, 00, 00, 00, 00, 00
; 420
dw  00, 00, 00, 00, 00, 00, 00, 00
; 430
dw  SECTORS_SEGMENT, LINES_PHYSICS_SEGMENT, VERTEXES_SEGMENT, LINEFLAGSLIST_SEGMENT, SEENLINES_6800_SEGMENT, SIDES_SEGMENT, LINES_SEGMENT, 00
; 440
dw  00, 00, 00, 00, 00, 00, 00, 00
; 450
dw  00, 00, 00, 00, 00, 00, 00, 00
; 460
dw  00, 00, 00, 00, 00, 00, 00, 00
; 470
dw  00, 00, 00, 00, 00, 00, 00, 00
; 480
dw  00, 00, 00, 00, 00, 00, 00, 00
; 490
dw  00, 00, 00, 00, 00, 00, 00, 00
; 4A0
dw  00, 00, 00, 00, 00, 00, 00, 00
; 4B0
dw  00, 00, 00, 00, 00, 00, 00, 00
; 4C0
dw  00, 00, 00, 00, 00, 00, 00, 00
; 4D0
dw  00, 00, 00, 00, 00, 00, 00, 00
; 4E0
dw  00, 00, 00, 00, 00, 00, 00, 00
; 4F0
dw  00, 00, 00, 00, 00, 00, 00, 00
; 500
dw  00, 00, 00, 00, 00, 00, 00, ZLIGHT_SEGMENT
; 510 ; _playingdriver here, should default 0..
dw  00, STATES_SEGMENT, 00, 00, 00, 00, 00, 00
; 520
dw  00, 00, 00, 00, 00, 00, 00, 00
; 530
dw  00, 00, 00, 00, 00, 00, 00, 00
; 540
dw  00, 00, 00, 00, 00, 00, 00, 00
; 550
dw  00, 00, 00, 00, 00, 00, 00, 00
; 560
dw  00, 00, 00, 00, 00, 00, 00, 00
; 570
dw  00, 00, 00, 00, 00, 00, 00, 00
; 580
dw  00, 00, 00, 00, 00, 00, 00, 00
; 590
dw  00, 00, 00, 00, 00, 00, 00, 00
; 5A0
dw  00, 00, 00, 00, 00, 00, 00, 00
; 5B0
dw  00, 00, 00, 00, 00, 00, 00, 00
; 5C0
dw  00, 00, 00, 00, 00, 00, 00, 00
; 5D0
dw  00, 00, 00, 00, 00, 00, 00, 00
; 5E0
dw  00, 00, 00, 00, 00, 00, 00, 00
; 5F0 
dw  00, 00, 00, 00, 00, 00, 00, 00
; 600
dw  00, 00, 00, 00, 00, 00, 00, 00
; 610
dw  00, 00, 00, 00, 00, 00, 00, 00
; 620
dw  00, 00, 00, 00, 00, 00, 00, 00
; 630
dw  00, 00, 00, 00, 00, 00, 00, 00
; 640
dw  00, 00, 00, 00, 00, 00, 00, 00
; 650
dw  00, 00, 00, 00, 00, 00, 00, 00
; 660
dw  00, 00, 00, 00, 00, 00, 00, 00
; 670
dw  00, 00, 00, 00, 00, 00, 00, 00
; 680
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
dw  00, 00, 00, 00, 00, 00, 00, 00
; 710
dw  00, 00, 00, 00, 00, 00, 00, 00
; 720
dw  00, 00, 00, 00, 00, 00, 00, 00
; 730
dw  00, 00, 00, 00, 00, 00, 00, 00
; 740
dw  00, 00, 00, 00, 00, 00, 00, 00
; 750
dw  00, -1, 00, 00, 00, 00, 00, 00 ; sfx cache head/tail
; 760
dw  -1, -1  ; cache head/tails
db 0, NUM_FLAT_CACHE_PAGES-1 
dw  00, 00, 00, 00, 00 
; 770
dw  00, 00, 00, 00, 00, 00, 00, 00
; 780
dw  00, 00, 00, 00, 00, 00, 00, 00
; 790 
dw  00, 00, 00, 00, 00, 00, 00, 00
; 7A0
dw  00, 00, 00, 00, 00, 00, 00, 00
; 7B0
dw  00, 00, 00, 00, 00, 00, 00, 00
; 7C0  


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
	_EPR PHYSICS_RENDER_9800_PAGE		 			PAGE_6800_OFFSET ; colormaps 
	_EPR PHYSICS_RENDER_9C00_PAGE 	 				PAGE_6C00_OFFSET ; colormaps_f_dupe
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
	_EPR FIRST_LUMPINFO_LOGICAL_PAGE+2 		 		PAGE_9C00_OFFSET  ; todo why lumpinfo here...
		
	_EPR RENDER_4000_PAGE+0	 						PAGE_4000_OFFSET ;pageswapargs_rend_offset_size   ; render
	_EPR RENDER_4000_PAGE+1					 		PAGE_4400_OFFSET
	_EPR RENDER_4000_PAGE+2							PAGE_4800_OFFSET
	_EPR RENDER_4000_PAGE+3							PAGE_4C00_OFFSET
	_EPR FIRST_TEXTURE_LOGICAL_PAGE+0		 		PAGE_5000_OFFSET ;pageswapargs_rend_texture_size
	_EPR FIRST_TEXTURE_LOGICAL_PAGE+1		 		PAGE_5400_OFFSET
	_EPR FIRST_TEXTURE_LOGICAL_PAGE+2		 		PAGE_5800_OFFSET
	_EPR FIRST_TEXTURE_LOGICAL_PAGE+3		 		PAGE_5C00_OFFSET
	; texture cache area
	_EPR FIRST_TEXTURE_LOGICAL_PAGE+4		 		PAGE_6000_OFFSET ;texture cache area
	_EPR FIRST_TEXTURE_LOGICAL_PAGE+5		 		PAGE_6400_OFFSET
	_EPR FIRST_TEXTURE_LOGICAL_PAGE+6		 		PAGE_6800_OFFSET
	_EPR FIRST_TEXTURE_LOGICAL_PAGE+7		 		PAGE_6C00_OFFSET  
	_EPR FIRST_TEXTURE_LOGICAL_PAGE+8				PAGE_7000_OFFSET
	_EPR FIRST_TEXTURE_LOGICAL_PAGE+9				PAGE_7400_OFFSET
	_EPR RENDER_4000_PAGE+9					 		PAGE_7800_OFFSET
	_EPR RENDER_4000_PAGE+10		 				PAGE_7C00_OFFSET
	_EPR RENDER_4000_PAGE+4							PAGE_8000_OFFSET
	_EPR FIRST_VISPLANE_PAGE						PAGE_8400_OFFSET
	_EPR FIRST_VISPLANE_PAGE+1			 			PAGE_8800_OFFSET
	_EPR EMS_VISPLANE_EXTRA_PAGE			 		PAGE_8C00_OFFSET
		; this 9000 unused; todo: move 6000-8000 to 7000-9000
		; todo are all these used...?

	_EPR RENDER_4000_PAGE+7	 					 	PAGE_9000_OFFSET ;pageswapargs_rend_9000_size
	_EPR RENDER_4000_PAGE+8	 				 		PAGE_9400_OFFSET
	_EPR PHYSICS_RENDER_9800_PAGE 					PAGE_9800_OFFSET
	_EPR PHYSICS_RENDER_9C00_PAGE 				 	PAGE_9C00_OFFSET
		; render 4000 to 9000
	_EPR RENDER_4000_PAGE+0					 		PAGE_9000_OFFSET ;pageswapargs_rend_other9000_size
	_EPR RENDER_4000_PAGE+1					 		PAGE_9400_OFFSET 
	_EPR RENDER_4000_PAGE+2					 		PAGE_9800_OFFSET 
	_EPR RENDER_4000_PAGE+3				 			PAGE_9C00_OFFSET	

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

		; puts all visplanes active
	_EPR EMS_VISPLANE_EXTRA_PAGE			 		PAGE_8C00_OFFSET
	_EPR EMS_VISPLANE_EXTRA_PAGE+1			 		PAGE_9000_OFFSET
	_EPR EMS_VISPLANE_EXTRA_PAGE+2			 		PAGE_9400_OFFSET

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
	
	_EPR FIRST_TEXTURE_LOGICAL_PAGE+8				PAGE_7000_OFFSET
	_EPR FIRST_TEXTURE_LOGICAL_PAGE+9				PAGE_7400_OFFSET
	_EPR RENDER_7800_PAGE 							PAGE_7800_OFFSET
	_EPR RENDER_7C00_PAGE 							PAGE_7C00_OFFSET
		;masked
	_EPR FIRST_EXTRA_MASKED_DATA_PAGE		 		PAGE_8400_OFFSET ;pageswapargs_maskeddata_offset_size
	_EPR FIRST_EXTRA_MASKED_DATA_PAGE+1 			PAGE_8800_OFFSET
	_EPR PHYSICS_RENDER_9800_PAGE 					PAGE_8C00_OFFSET  ; put colormaps where vissprites used to be?
		;render 9000 to 6000
	_EPR RENDER_4000_PAGE+7						 	PAGE_6000_OFFSET ;pageswapargs_render_to_6000_size
	_EPR RENDER_4000_PAGE+8	 						PAGE_6400_OFFSET
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
	_EPR FIRST_INTERMISSION_GRAPHICS_LOGICAL_PAGE+1 PAGE_7000_OFFSET
	_EPR FIRST_INTERMISSION_GRAPHICS_LOGICAL_PAGE+0 PAGE_7400_OFFSET
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
	_EPR RENDER_4000_PAGE+0					 		PAGE_8000_OFFSET ;pageswapargs_rend_other8000_size
	_EPR RENDER_4000_PAGE+1					 		PAGE_8400_OFFSET 
	_EPR RENDER_4000_PAGE+2					 		PAGE_8800_OFFSET 
	_EPR RENDER_4000_PAGE+3				 			PAGE_8C00_OFFSET	



ENDS _FIXEDDATA

GROUP DGROUP _FIXEDDATA



END
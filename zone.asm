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
INCLUDE CONSTANT.INC
INCLUDE defs.inc
INSTRUCTION_SET_MACRO

 
EXTRN locallib_int86_67_:FAR

.DATA

EXTRN _currenttask:BYTE
EXTRN _emshandle:WORD
EXTRN _currentpageframes:BYTE
.CODE

; todo get rid of tasks
TASK_PHYSICS = 0
TASK_RENDER = 1
TASK_STATUS = 2
TASK_DEMO = 3
TASK_PHYSICS9000 = 4
TASK_RENDER_SPRITE = 5
TASK_SCRATCH_STACK = 7
TASK_PALETTE = 8
TASK_MENU = 9
TASK_WIPE = 10
TASK_INTERMISSION = 11
TASK_STATUS_NO_SCREEN4 = 12



PROC Z_QuickMapMusicPageFrame_ FAR
PUBLIC Z_QuickMapMusicPageFrame_

cmp   al, byte ptr ds:[_currentpageframes + MUS_PAGE_FRAME_INDEX]
jne   actually_changing_music_page_frame
retf  
actually_changing_music_page_frame:
push  bx
push  dx
mov   byte ptr ds:[_currentpageframes + MUS_PAGE_FRAME_INDEX], al

xor   ah, ah
mov   dx, word ptr ds:[_emshandle]  ; todo hardcode
mov   bx, ax

mov   ax, 04400h + MUS_PAGE_FRAME_INDEX
add   bx, MUS_DATA_PAGES
int   067h
;call  locallib_int86_67_
pop   dx
pop   bx
retf  


ENDP

PROC Z_QuickMapSFXPageFrame_ FAR
PUBLIC Z_QuickMapSFXPageFrame_

cmp   al, byte ptr ds:[_currentpageframes + SFX_PAGE_FRAME_INDEX]
jne   actually_changing_sfx_page_frame
retf  
actually_changing_sfx_page_frame:
push  bx
push  dx
mov   byte ptr ds:[_currentpageframes + SFX_PAGE_FRAME_INDEX], al

xor   ah, ah
mov   dx, word ptr ds:[_emshandle]
mov   bx, ax

mov   ax, 04400h + SFX_PAGE_FRAME_INDEX
add   bx, SFX_DATA_PAGES
int   067h
;call  locallib_int86_67_
pop   dx
pop   bx
retf  


ENDP

PROC Z_QuickMapWADPageFrame_ FAR
PUBLIC Z_QuickMapWADPageFrame_


xor   al, al
and   ah, 0FCh
cmp   ah, byte ptr ds:[_currentpageframes + WAD_PAGE_FRAME_INDEX]
jne   actually_changing_wad_page_frame
retf  

actually_changing_wad_page_frame:
push  bx
push  dx
mov   byte ptr ds:[_currentpageframes + WAD_PAGE_FRAME_INDEX], ah
mov   al, ah
xor   ah, ah
mov   dx, word ptr ds:[_emshandle]
mov   bx, ax
SHIFT_MACRO sar   bx 2
mov   ax, 04400h + WAD_PAGE_FRAME_INDEX
add   bx, FIRST_LUMPINFO_LOGICAL_PAGE
int   067h
;call  locallib_int86_67_
pop   dx
pop   bx
retf  


ENDP

PROC Z_QuickMap_ NEAR
PUBLIC Z_QuickMap_

MAX_COUNT_ITER = 8

push  bx
push  cx
push  si
push  di
mov   di, ax
mov   bl, dl
test  dl, dl
jle   done_with_quickmap_loop_exit
compare_next_quickmap_loop: ; todo move this to end of loop
cmp   bl, MAX_COUNT_ITER
jle   set_max_args_to_less_than_8
mov   dx, MAX_COUNT_ITER
loop_next_quickmap_args:
mov   al, dl
mov   si, di
sub   bl, MAX_COUNT_ITER
cbw
mov   dx, word ptr ds:[_emshandle]
mov   cx, ax
mov   ax, 05000h
add   di, MAX_COUNT_ITER * 2 * PAGE_SWAP_ARG_MULT
int 067h
test  bl, bl
jg    compare_next_quickmap_loop
done_with_quickmap_loop_exit:
pop   di
pop   si
pop   cx
pop   bx
ret   
set_max_args_to_less_than_8:    ; todo dupe the loop contents
mov   al, bl
cbw 
mov   dx, ax
jmp   loop_next_quickmap_args


ENDP

PROC Z_QuickMapPhysicsCode_ FAR
PUBLIC Z_QuickMapPhysicsCode_


;	Z_QuickMap2AI(pageswapargs_physics_code_offset_size, INDEXED_PAGE_9400_OFFSET);


push  dx
;mov   dx, 2
;mov   ax, 0xa32
;call  Z_QuickMap_
Z_QUICKMAPAI 2 pageswapargs_physics_code_offset_size INDEXED_PAGE_9400_OFFSET
pop   dx
retf  


ENDP

PROC Z_QuickMapPhysics_ FAR
PUBLIC Z_QuickMapPhysics_


push  dx
;mov   dx, 0x18
;mov   ax, 0x80e
;call  Z_QuickMap_
Z_QUICKMAPAI 24 pageswapargs_phys_offset_size INDEXED_PAGE_4000_OFFSET
mov   byte ptr ds:[_currenttask], TASK_PHYSICS
pop   dx
retf  


ENDP

PROC Z_QuickMapDemo_ FAR
PUBLIC Z_QuickMapDemo_


push  dx
;mov   dx, 4
;mov   ax, 0x8f6
;call  Z_QuickMap_
Z_QUICKMAPAI 4 pageswapargs_demo_offset_size INDEXED_PAGE_5000_OFFSET
mov   byte ptr ds:[_currenttask], TASK_DEMO
pop   dx
retf  



ENDP

PROC Z_QuickMapRender7000_ FAR
PUBLIC Z_QuickMapRender7000_

push  dx
;mov   dx, 4
;mov   ax, 0x89e
;call  Z_QuickMap_
Z_QUICKMAPAI 4 (pageswapargs_rend_offset_size+12) INDEXED_PAGE_7000_OFFSET

pop   dx
retf  


ENDP

PROC Z_QuickMapRender_ FAR
PUBLIC Z_QuickMapRender_


push  dx
;mov   dx, 0x18
;mov   ax, 0x86e
;call  Z_QuickMap_
Z_QUICKMAPAI 24 pageswapargs_rend_offset_size INDEXED_PAGE_4000_OFFSET
mov   byte ptr ds:[_currenttask], TASK_RENDER
pop   dx
retf  



ENDP

PROC Z_QuickMapRender_4000To9000_9000Only_ FAR
PUBLIC Z_QuickMapRender_4000To9000_9000Only_

push  dx
;mov   dx, 4
;mov   ax, 0x8ce
;call  Z_QuickMap_
Z_QUICKMAPAI 4 pageswapargs_rend_other9000_size INDEXED_PAGE_9000_OFFSET
pop   dx
retf  


ENDP

PROC Z_QuickMapRender_4000To9000_ FAR
PUBLIC Z_QuickMapRender_4000To9000_


push  dx
;mov   dx, 0x10
; should be 87e is 836
;mov   ax, 0x87e
;call  Z_QuickMap_
Z_QUICKMAPAI 16 (pageswapargs_rend_offset_size+4) INDEXED_PAGE_5000_OFFSET

;mov   dx, 4
;mov   ax, 0x8ce
;call  Z_QuickMap_
Z_QUICKMAPAI 4 pageswapargs_rend_other9000_size INDEXED_PAGE_9000_OFFSET

mov   byte ptr ds:[_currenttask], TASK_RENDER
pop   dx
retf  


ENDP

PROC Z_QuickMapRender_9000To7000_ FAR
PUBLIC Z_QuickMapRender_9000To7000_


push  dx
;mov   dx, 2
;mov   ax, 0x976
;call  Z_QuickMap_
Z_QUICKMAPAI 2 (pageswapargs_spritecache_offset_size+4) INDEXED_PAGE_7000_OFFSET
pop   dx
retf  



ENDP

PROC Z_QuickMapRender_9000To6000_ FAR
PUBLIC Z_QuickMapRender_9000To6000_


push  dx
;mov   dx, 2
;mov   ax, 0x992
;call  Z_QuickMap_
Z_QUICKMAPAI 2 pageswapargs_render_to_6000_size INDEXED_PAGE_6000_OFFSET
pop   dx
retf  


ENDP

PROC Z_QuickMapRender4000_ FAR
PUBLIC Z_QuickMapRender4000_


push  dx
;mov   dx, 4
;mov   ax, 0x86e
;call  Z_QuickMap_
Z_QUICKMAPAI 4 pageswapargs_rend_offset_size INDEXED_PAGE_4000_OFFSET
pop   dx
retf  


ENDP

PROC Z_QuickMapRender5000_ FAR
PUBLIC Z_QuickMapRender5000_


push  dx
;mov   dx, 4
;mov   ax, 0x87e
;call  Z_QuickMap_
Z_QUICKMAPAI 4 (pageswapargs_rend_offset_size+4) INDEXED_PAGE_5000_OFFSET
pop   dx
retf  


ENDP

PROC Z_QuickMapRender9000_ FAR
PUBLIC Z_QuickMapRender9000_


push  dx
;mov   dx, 4
;mov   ax, 0x8be
;call  Z_QuickMap_
Z_QUICKMAPAI 4 pageswapargs_rend_9000_size INDEXED_PAGE_9000_OFFSET
pop   dx
retf  


ENDP

PROC Z_QuickMapRenderTexture_ NEAR
PUBLIC Z_QuickMapRenderTexture_


push  dx
;mov   dx, 8
;mov   ax, 0x87e
;call  Z_QuickMap_
Z_QUICKMAPAI 8 pageswapargs_rend_texture_size INDEXED_PAGE_5000_OFFSET
pop   dx
ret
ENDP

;PROC Z_QuickMapStatus_ FAR
;PUBLIC Z_QuickMapStatus_

;ENDP

END
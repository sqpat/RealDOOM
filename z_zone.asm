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

 
EXTRN fread_:PROC
EXTRN fopen_:PROC
EXTRN fclose_:PROC
EXTRN fseek_:PROC
EXTRN locallib_far_fread_:PROC
.DATA

EXTRN _currentoverlay:BYTE
EXTRN _currentpageframes:BYTE
EXTRN _codestartposition:DWORD
EXTRN _hu_font:WORD
EXTRN _playerMobjRef:WORD


IFDEF COMPILE_CHIPSET
    EXTRN Z_QuickMap1AIC_:NEAR
    EXTRN Z_QuickMap2AIC_:NEAR
    EXTRN Z_QuickMap3AIC_:NEAR
    EXTRN Z_QuickMap4AIC_:NEAR
    EXTRN Z_QuickMap5AIC_:NEAR
    EXTRN Z_QuickMap6AIC_:NEAR

    EXTRN Z_QuickMap8AIC_:NEAR
    EXTRN Z_QuickMap16AIC_:NEAR
    EXTRN Z_QuickMap24AIC_:NEAR
ELSE
ENDIF

.CODE

; todo get rid of tasks
; todo put in constants?


IFDEF COMPILE_CHIPSET
ELSE

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
    pop   dx
    pop   bx
    retf  


    ENDP

COMMENT @

    PROC Z_QuickMap_ NEAR
    PUBLIC Z_QuickMap_

    MAX_COUNT_ITER = 8

    push  bx
    push  cx
    push  si
    mov   si, ax
    mov   bl, dl
    test  dl, dl
    jle   done_with_quickmap_loop_exit
    compare_next_quickmap_loop: ; todo move this to end of loop
    mov   dx, word ptr ds:[_emshandle]
    mov   ax, 05000h
    cmp   bl, MAX_COUNT_ITER
    jle   set_max_args_to_less_than_8
    mov   cx, MAX_COUNT_ITER
    loop_next_quickmap_args:
    sub   bl, MAX_COUNT_ITER
    int   067h
    add   si, MAX_COUNT_ITER * 2 * PAGE_SWAP_ARG_MULT
    test  bl, bl
    jg    compare_next_quickmap_loop
    done_with_quickmap_loop_exit:
    pop   si
    pop   cx
    pop   bx
    ret   
    set_max_args_to_less_than_8:    ; todo dupe the loop contents
    mov   cl, bl
    xor   ch, ch
    int   067h
    pop   si
    pop   cx
    pop   bx
    ret 

    ENDP

@

ENDIF


PROC Z_QuickMapPhysicsCode_ FAR
PUBLIC Z_QuickMapPhysicsCode_


;	Z_QUICKMAPAI2(pageswapargs_physics_code_offset_size, INDEXED_PAGE_9400_OFFSET);


push  dx
push  cx
push  si

;Z_QUICKMAPAI2 pageswapargs_physics_code_offset_size INDEXED_PAGE_9400_OFFSET

mov     dx, word ptr ds:[_emshandle]
mov     ax, 05000h
mov     cx, 2
mov     si, pageswapargs_physics_code_offset_size * 2 * PAGE_SWAP_ARG_MULT + OFFSET _pageswapargs
int     067h

pop   si
pop   cx
pop   dx
retf  

ENDP

PROC Z_QuickMapPhysics_ FAR
PUBLIC Z_QuickMapPhysics_

push  dx
push  cx
push  si

;Z_QUICKMAPAI24 pageswapargs_phys_offset_size INDEXED_PAGE_4000_OFFSET

mov     dx, word ptr ds:[_emshandle]
mov     ax, 05000h
mov     cx, 8
mov     si, pageswapargs_phys_offset_size * 2 * PAGE_SWAP_ARG_MULT + OFFSET _pageswapargs
int     067h

mov     ax, 05000h
add     si, 8 * 2 * PAGE_SWAP_ARG_MULT
int     067h

mov     ax, 05000h
add     si, 8 * 2 * PAGE_SWAP_ARG_MULT
int     067h



mov   byte ptr ds:[_currenttask], TASK_PHYSICS
pop   si
pop   cx
pop   dx
retf  

ENDP

PROC Z_QuickMapDemo_ FAR
PUBLIC Z_QuickMapDemo_

push  dx
push  cx
push  si
;Z_QUICKMAPAI4 pageswapargs_demo_offset_size INDEXED_PAGE_5000_OFFSET

mov     dx, word ptr ds:[_emshandle]
mov     ax, 05000h
mov     cx, 4
mov     si, pageswapargs_demo_offset_size * 2 * PAGE_SWAP_ARG_MULT + OFFSET _pageswapargs
int     067h

mov   byte ptr ds:[_currenttask], TASK_DEMO
pop   si
pop   cx
pop   dx
retf  

ENDP


PROC Z_QuickMapRender_ FAR
PUBLIC Z_QuickMapRender_


push  dx
push  cx
push  si
;Z_QUICKMAPAI24 pageswapargs_rend_offset_size INDEXED_PAGE_4000_OFFSET

mov     dx, word ptr ds:[_emshandle]
mov     ax, 05000h
mov     cx, 8
mov     si, (pageswapargs_rend_offset_size) * 2 * PAGE_SWAP_ARG_MULT + OFFSET _pageswapargs
int     067h

mov     ax, 05000h
add     si, 8 * 2 * PAGE_SWAP_ARG_MULT
int     067h

mov     ax, 05000h
add     si, 8 * 2 * PAGE_SWAP_ARG_MULT
int     067h
mov   byte ptr ds:[_currenttask], TASK_RENDER

pop   si
pop   cx
pop   dx
retf  

ENDP

PROC Z_QuickMapRender_4000To9000_9000Only_ FAR
PUBLIC Z_QuickMapRender_4000To9000_9000Only_

push  dx
push  cx
push  si
;Z_QUICKMAPAI4 pageswapargs_rend_other9000_size INDEXED_PAGE_9000_OFFSET

mov     dx, word ptr ds:[_emshandle]
mov     ax, 05000h
mov     cx, 4
mov     si, pageswapargs_rend_other9000_size * 2 * PAGE_SWAP_ARG_MULT + OFFSET _pageswapargs
int     067h

pop   si
pop   cx
pop   dx
retf  

ENDP

PROC Z_QuickMapRender_4000To9000_ FAR
PUBLIC Z_QuickMapRender_4000To9000_


push  dx
push  cx
push  si
;Z_QUICKMAPAI16 (pageswapargs_rend_offset_size+4) INDEXED_PAGE_5000_OFFSET

mov     dx, word ptr ds:[_emshandle]
mov     ax, 05000h
mov     cx, 8
mov     si, (pageswapargs_rend_offset_size+4) * 2 * PAGE_SWAP_ARG_MULT + OFFSET _pageswapargs
int     067h

mov     ax, 05000h
add     si, 8 * 2 * PAGE_SWAP_ARG_MULT
int     067h


;Z_QUICKMAPAI4 pageswapargs_rend_other9000_size INDEXED_PAGE_9000_OFFSET
mov     ax, 05000h
mov     cx, 4
mov     si, pageswapargs_rend_other9000_size * 2 * PAGE_SWAP_ARG_MULT + OFFSET _pageswapargs
int     067h


mov   byte ptr ds:[_currenttask], TASK_RENDER
pop   si
pop   cx
pop   dx
retf  

ENDP

PROC Z_QuickMapRender_9000To7000_ FAR
PUBLIC Z_QuickMapRender_9000To7000_




push  dx
push  cx
push  si
;Z_QUICKMAPAI2 (pageswapargs_spritecache_offset_size+4) INDEXED_PAGE_7000_OFFSET

mov     dx, word ptr ds:[_emshandle]
mov     ax, 05000h
mov     cx, 2
mov     si, (pageswapargs_spritecache_offset_size+4) * 2 * PAGE_SWAP_ARG_MULT + OFFSET _pageswapargs
int     067h


pop   si
pop   cx
pop   dx
retf  

ENDP

PROC Z_QuickMapRender_9000To6000_ FAR
PUBLIC Z_QuickMapRender_9000To6000_


push  dx
push  cx
push  si
;Z_QUICKMAPAI2 pageswapargs_render_to_6000_size INDEXED_PAGE_6000_OFFSET

mov     dx, word ptr ds:[_emshandle]
mov     ax, 05000h
mov     cx, 2
mov     si, (pageswapargs_render_to_6000_size) * 2 * PAGE_SWAP_ARG_MULT + OFFSET _pageswapargs
int     067h


pop   si
pop   cx
pop   dx
retf  

ENDP

PROC Z_QuickMapRender4000_ FAR
PUBLIC Z_QuickMapRender4000_


push  dx
push  cx
push  si
;Z_QUICKMAPAI4 pageswapargs_rend_offset_size INDEXED_PAGE_4000_OFFSET
mov     dx, word ptr ds:[_emshandle]
mov     ax, 05000h
mov     cx, 4
mov     si, pageswapargs_rend_offset_size * 2 * PAGE_SWAP_ARG_MULT + OFFSET _pageswapargs
int     067h
pop   si
pop   cx
pop   dx
retf  

ENDP

PROC Z_QuickMapRender5000_ FAR
PUBLIC Z_QuickMapRender5000_


push  dx
push  cx
push  si
;Z_QUICKMAPAI4 (pageswapargs_rend_offset_size+4) INDEXED_PAGE_5000_OFFSET
mov     dx, word ptr ds:[_emshandle]
mov     ax, 05000h
mov     cx, 4
mov     si, (pageswapargs_rend_offset_size+4) * 2 * PAGE_SWAP_ARG_MULT + OFFSET _pageswapargs
int     067h

pop   si
pop   cx
pop   dx
retf  

ENDP

PROC Z_QuickMapRender9000_ FAR
PUBLIC Z_QuickMapRender9000_


push  dx
push  cx
push  si
;Z_QUICKMAPAI4 pageswapargs_rend_9000_size INDEXED_PAGE_9000_OFFSET
mov     dx, word ptr ds:[_emshandle]
mov     ax, 05000h
mov     cx, 4
mov     si, (pageswapargs_rend_9000_size) * 2 * PAGE_SWAP_ARG_MULT + OFFSET _pageswapargs
int     067h

pop   si
pop   cx
pop   dx
retf  

ENDP

PROC Z_QuickMapRenderTexture_ NEAR
PUBLIC Z_QuickMapRenderTexture_


push  dx
push  cx
push  si   
;Z_QUICKMAPAI8 pageswapargs_rend_texture_size INDEXED_PAGE_5000_OFFSET


mov     dx, word ptr ds:[_emshandle]
mov     ax, 05000h
mov     cx, 8
mov     si, (pageswapargs_rend_texture_size) * 2 * PAGE_SWAP_ARG_MULT + OFFSET _pageswapargs
int     067h

pop   si
pop   cx
pop   dx
ret

ENDP

PROC Z_QuickMapStatus_ FAR
PUBLIC Z_QuickMapStatus_

push  dx
push  cx
push  si

;Z_QUICKMAPAI1 pageswapargs_stat_offset_size INDEXED_PAGE_9C00_OFFSET

mov     dx, word ptr ds:[_emshandle]
mov     ax, 05000h
mov     cx, 1
mov     si, (pageswapargs_stat_offset_size) * 2 * PAGE_SWAP_ARG_MULT + OFFSET _pageswapargs
int     067h


;Z_QUICKMAPAI4 (pageswapargs_stat_offset_size+1) INDEXED_PAGE_7000_OFFSET

mov     ax, 05000h
mov     cx, 4
add     si, 1 * 2 * PAGE_SWAP_ARG_MULT
int     067h


;Z_QUICKMAPAI1 (pageswapargs_stat_offset_size+5) INDEXED_PAGE_6000_OFFSET

mov     ax, 05000h
mov     cx, 1
add     si, 4 * 2 * PAGE_SWAP_ARG_MULT
int     067h

mov   byte ptr ds:[_currenttask], TASK_STATUS
pop   si
pop   cx
pop   dx
retf  

ENDP


PROC Z_QuickMapScratch_5000_ FAR
PUBLIC Z_QuickMapScratch_5000_

push  dx
push  cx
push  si
;Z_QUICKMAPAI4 pageswapargs_scratch5000_offset_size INDEXED_PAGE_5000_OFFSET

mov     dx, word ptr ds:[_emshandle]
mov     ax, 05000h
mov     cx, 4
mov     si, (pageswapargs_scratch5000_offset_size) * 2 * PAGE_SWAP_ARG_MULT + OFFSET _pageswapargs
int     067h

pop   si
pop   cx
pop   dx
retf  

ENDP

PROC Z_QuickMapScratch_8000_ FAR
PUBLIC Z_QuickMapScratch_8000_


push  dx
push  cx
push  si
;Z_QUICKMAPAI4 pageswapargs_scratch8000_offset_size INDEXED_PAGE_8000_OFFSET


mov     dx, word ptr ds:[_emshandle]
mov     ax, 05000h
mov     cx, 4
mov     si, (pageswapargs_scratch8000_offset_size) * 2 * PAGE_SWAP_ARG_MULT + OFFSET _pageswapargs
int     067h


pop   si
pop   cx
pop   dx
retf  

ENDP

PROC Z_QuickMapScratch_7000_ FAR
PUBLIC Z_QuickMapScratch_7000_

push  dx
push  cx
push  si
;Z_QUICKMAPAI4 pageswapargs_scratch7000_offset_size INDEXED_PAGE_7000_OFFSET


mov     dx, word ptr ds:[_emshandle]
mov     ax, 05000h
mov     cx, 4
mov     si, (pageswapargs_scratch7000_offset_size) * 2 * PAGE_SWAP_ARG_MULT + OFFSET _pageswapargs
int     067h

pop   si
pop   cx
pop   dx
retf  

ENDP

PROC Z_QuickMapScratch_4000_ FAR
PUBLIC Z_QuickMapScratch_4000_

push  dx
push  cx
push  si
;Z_QUICKMAPAI4 pageswapargs_scratch4000_offset_size INDEXED_PAGE_4000_OFFSET


mov     dx, word ptr ds:[_emshandle]
mov     ax, 05000h
mov     cx, 4
mov     si, (pageswapargs_scratch4000_offset_size) * 2 * PAGE_SWAP_ARG_MULT + OFFSET _pageswapargs
int     067h

pop   si
pop   cx
pop   dx
retf  

ENDP

PROC Z_QuickMapScreen0_ FAR
PUBLIC Z_QuickMapScreen0_

push  dx
push  cx
push  si
;Z_QUICKMAPAI4 pageswapargs_screen0_offset_size INDEXED_PAGE_8000_OFFSET


mov     dx, word ptr ds:[_emshandle]
mov     ax, 05000h
mov     cx, 4
mov     si, (pageswapargs_screen0_offset_size) * 2 * PAGE_SWAP_ARG_MULT + OFFSET _pageswapargs
int     067h

pop   si
pop   cx
pop   dx
retf  

ENDP

PROC Z_QuickMapRenderPlanes9000only_ FAR
PUBLIC Z_QuickMapRenderPlanes9000only_

push  dx
push  cx
push  si
call  Z_QuickMapRender9000_
;Z_QUICKMAPAI4 (pageswapargs_renderplane_offset_size+3) INDEXED_PAGE_9C00_OFFSET

mov     dx, word ptr ds:[_emshandle]
mov     ax, 05000h
mov     cx, 4
mov     si, (pageswapargs_renderplane_offset_size+3) * 2 * PAGE_SWAP_ARG_MULT + OFFSET _pageswapargs
int     067h

pop   si
pop   cx
pop   dx
retf  

ENDP

PROC Z_QuickMapRenderPlanes_ FAR
PUBLIC Z_QuickMapRenderPlanes_

push  dx
push  cx

; todo can be done all as one for non chipset
push  si
;Z_QUICKMAPAI3 pageswapargs_renderplane_offset_size INDEXED_PAGE_5000_OFFSET

mov     dx, word ptr ds:[_emshandle]
mov     ax, 05000h
mov     cx, 3
mov     si, (pageswapargs_renderplane_offset_size) * 2 * PAGE_SWAP_ARG_MULT + OFFSET _pageswapargs
int     067h

;Z_QUICKMAPAI1 (pageswapargs_renderplane_offset_size+3) INDEXED_PAGE_9C00_OFFSET


mov     ax, 05000h
mov     cx, 1
add     si, 3 * 2 * PAGE_SWAP_ARG_MULT
int     067h

;Z_QUICKMAPAI4 (pageswapargs_renderplane_offset_size+4) INDEXED_PAGE_7000_OFFSET

mov     ax, 05000h
mov     cx, 4
add     si, 1 * 2 * PAGE_SWAP_ARG_MULT
int     067h


pop   si
pop   cx
pop   dx
retf  

ENDP

PROC Z_QuickMapRenderPlanesBack_ FAR
PUBLIC Z_QuickMapRenderPlanesBack_

push  dx
push  cx
push  si
;Z_QUICKMAPAI3 pageswapargs_renderplane_offset_size INDEXED_PAGE_5000_OFFSET

mov     dx, word ptr ds:[_emshandle]
mov     ax, 05000h
mov     cx, 3
mov     si, (pageswapargs_renderplane_offset_size) * 2 * PAGE_SWAP_ARG_MULT + OFFSET _pageswapargs
int     067h

pop   si
pop   cx
pop   dx
retf  

ENDP


PROC Z_QuickMapFlatPage_ FAR
PUBLIC Z_QuickMapFlatPage_

push  cx
push  si
mov   si, dx
shl   si, 1

SHIFT_PAGESWAP_ARGS si

mov   word ptr ds:[_pageswapargs + (pageswapargs_flatcache_offset * PAGE_SWAP_ARG_MULT) + si], ax
;	pageswapargs[pageswapargs_flatcache_offset + offset * PAGE_SWAP_ARG_MULT] = _EPR(page);

;Z_QUICKMAPAI4 pageswapargs_flatcache_offset_size INDEXED_PAGE_7000_OFFSET

mov     dx, word ptr ds:[_emshandle]
mov     ax, 05000h
mov     cx, 4
mov     si, (pageswapargs_flatcache_offset_size) * 2 * PAGE_SWAP_ARG_MULT + OFFSET _pageswapargs
int     067h

pop   si
pop   cx
retf  

ENDP

PROC Z_QuickMapUndoFlatCache_ FAR
PUBLIC Z_QuickMapUndoFlatCache_

push  dx
push  cx
push  si

;Z_QUICKMAPAI8 pageswapargs_rend_texture_size           INDEXED_PAGE_5000_OFFSET

mov     dx, word ptr ds:[_emshandle]
mov     ax, 05000h
mov     cx, 8
mov     si, pageswapargs_rend_texture_size * 2 * PAGE_SWAP_ARG_MULT + OFFSET _pageswapargs
int     067h

; todo in  non chipset these can run 8 at once.
;Z_QUICKMAPAI4 pageswapargs_spritecache_offset_size     INDEXED_PAGE_9000_OFFSET

mov     ax, 05000h
mov     cx, 4
mov     si, pageswapargs_spritecache_offset_size * 2 * PAGE_SWAP_ARG_MULT + OFFSET _pageswapargs
int     067h

;Z_QUICKMAPAI4 (pageswapargs_spritecache_offset_size+4)   INDEXED_PAGE_7000_OFFSET

mov     ax, 05000h
;mov     cx, 4
add     si, 4 * 2 * PAGE_SWAP_ARG_MULT
int     067h


;Z_QUICKMAPAI3 pageswapargs_maskeddata_offset_size   	INDEXED_PAGE_8400_OFFSET

mov     ax, 05000h
mov     cx, 3
mov     si, pageswapargs_maskeddata_offset_size * 2 * PAGE_SWAP_ARG_MULT + OFFSET _pageswapargs
int     067h

pop   si
pop   cx
pop   dx
retf  

ENDP

PROC Z_QuickMapMaskedExtraData_ FAR
PUBLIC Z_QuickMapMaskedExtraData_

push  dx
push  cx
push  si
;Z_QUICKMAPAI2 pageswapargs_maskeddata_offset_size INDEXED_PAGE_8400_OFFSET

mov     dx, word ptr ds:[_emshandle]
mov     ax, 05000h
mov     cx, 2
mov     si, pageswapargs_maskeddata_offset_size * 2 * PAGE_SWAP_ARG_MULT + OFFSET _pageswapargs
int     067h


pop   si
pop   cx
pop   dx
retf  

ENDP

PROC Z_QuickMapSpritePage_ NEAR
PUBLIC Z_QuickMapSpritePage_

push  dx
push  cx
push  si
;Z_QUICKMAPAI4 pageswapargs_spritecache_offset_size INDEXED_PAGE_9000_OFFSET

mov     dx, word ptr ds:[_emshandle]
mov     ax, 05000h
mov     cx, 4
mov     si, pageswapargs_spritecache_offset_size * 2 * PAGE_SWAP_ARG_MULT + OFFSET _pageswapargs
int     067h


pop   si
pop   cx
pop   dx
ret   

ENDP

PROC Z_QuickMapPhysics5000_ FAR
PUBLIC Z_QuickMapPhysics5000_

push  dx
push  cx
push  si
;Z_QUICKMAPAI4 (pageswapargs_phys_offset_size+4) INDEXED_PAGE_5000_OFFSET

mov     dx, word ptr ds:[_emshandle]
mov     ax, 05000h
mov     cx, 4
mov     si, (pageswapargs_phys_offset_size+4) * 2 * PAGE_SWAP_ARG_MULT + OFFSET _pageswapargs
int     067h


pop   si
pop   cx
pop   dx
retf  

ENDP

PROC Z_QuickMapScreen1_ FAR
PUBLIC Z_QuickMapScreen1_

push  dx
push  cx
push  si
;Z_QUICKMAPAI4 (pageswapargs_intermission_offset_size+12) INDEXED_PAGE_9000_OFFSET

mov     dx, word ptr ds:[_emshandle]
mov     ax, 05000h
mov     cx, 4
mov     si, (pageswapargs_intermission_offset_size+12) * 2 * PAGE_SWAP_ARG_MULT + OFFSET _pageswapargs
int     067h


pop   si
pop   cx
pop   dx
retf  

ENDP

PROC Z_QuickMapPalette_ FAR
PUBLIC Z_QuickMapPalette_

push  dx
push  cx
push  si
;Z_QUICKMAPAI5 pageswapargs_palette_offset_size INDEXED_PAGE_8000_OFFSET

mov     dx, word ptr ds:[_emshandle]
mov     ax, 05000h
mov     cx, 5
mov     si, (pageswapargs_palette_offset_size) * 2 * PAGE_SWAP_ARG_MULT + OFFSET _pageswapargs
int     067h

mov   byte ptr ds:[_currenttask], TASK_PALETTE
pop   si
pop   cx
pop   dx
retf  

ENDP

PROC Z_QuickMapMenu_ FAR
PUBLIC Z_QuickMapMenu_

push  dx
push  cx
push  si
;Z_QUICKMAPAI8 pageswapargs_menu_offset_size INDEXED_PAGE_5000_OFFSET

mov     dx, word ptr ds:[_emshandle]
mov     ax, 05000h
mov     cx, 8
mov     si, (pageswapargs_menu_offset_size) * 2 * PAGE_SWAP_ARG_MULT + OFFSET _pageswapargs
int     067h

mov   byte ptr ds:[_currenttask], TASK_MENU
pop   si
pop   cx
pop   dx
retf  

ENDP

PROC Z_QuickMapIntermission_ FAR
PUBLIC Z_QuickMapIntermission_

push  dx
push  cx
push  si
;Z_QUICKMAPAI16 pageswapargs_intermission_offset_size INDEXED_PAGE_6000_OFFSET

mov     dx, word ptr ds:[_emshandle]
mov     ax, 05000h
mov     cx, 8
mov     si, (pageswapargs_intermission_offset_size) * 2 * PAGE_SWAP_ARG_MULT + OFFSET _pageswapargs
int     067h

mov     ax, 05000h
add     si, 8 * 2 * PAGE_SWAP_ARG_MULT
int     067h


mov   byte ptr ds:[_currenttask], TASK_INTERMISSION
pop   si
pop   cx
pop   dx
retf  

ENDP

PROC Z_QuickMapWipe_ FAR
PUBLIC Z_QuickMapWipe_

push  dx
push  cx
push  si
;Z_QUICKMAPAI4 pageswapargs_wipe_offset_size    INDEXED_PAGE_9000_OFFSET

mov     dx, word ptr ds:[_emshandle]
mov     ax, 05000h
mov     cx, 4
mov     si, (pageswapargs_wipe_offset_size) * 2 * PAGE_SWAP_ARG_MULT + OFFSET _pageswapargs
int     067h

;Z_QUICKMAPAI8 (pageswapargs_wipe_offset_size+4)  INDEXED_PAGE_6000_OFFSET


mov     dx, word ptr ds:[_emshandle]
mov     ax, 05000h
mov     cx, 8
add     si, 4 * 2 * PAGE_SWAP_ARG_MULT
int     067h


mov   byte ptr ds:[_currenttask], TASK_WIPE
pop   si
pop   cx
pop   dx
retf  

ENDP

quickmap_by_taskjump_jump_table:
dw task_num_0_jump
dw task_num_1_jump
dw task_num_2_jump
dw task_num_3_jump
dw task_num_4_jump
dw task_num_5_jump
dw task_num_6_jump
dw task_num_7_jump
dw task_num_8_jump
dw task_num_9_jump
dw task_num_10_jump
dw task_num_11_jump



PROC Z_QuickMapByTaskNum_ FAR
PUBLIC Z_QuickMapByTaskNum_

push  bx
push  dx

xor   ah, ah
mov   bx, ax
sal   bx, 1
jmp   word ptr cs:[bx + quickmap_by_taskjump_jump_table]
task_num_0_jump:

;Z_QUICKMAPAI24 pageswapargs_phys_offset_size INDEXED_PAGE_4000_OFFSET
mov     dx, word ptr ds:[_emshandle]
mov     ax, 05000h
mov     cx, 8
mov     si, pageswapargs_phys_offset_size * 2 * PAGE_SWAP_ARG_MULT + OFFSET _pageswapargs
int     067h

mov     ax, 05000h
add     si, 8 * 2 * PAGE_SWAP_ARG_MULT
int     067h

mov     ax, 05000h
add     si, 8 * 2 * PAGE_SWAP_ARG_MULT
int     067h

mov   byte ptr ds:[_currenttask], TASK_PHYSICS
task_num_3_jump:
task_num_4_jump:
task_num_5_jump:
task_num_6_jump:
task_num_7_jump:
task_num_8_jump:
task_num_10_jump:
pop   dx
pop   bx
retf  
task_num_1_jump:
;Z_QUICKMAPAI24 pageswapargs_rend_offset_size INDEXED_PAGE_4000_OFFSET

mov     dx, word ptr ds:[_emshandle]
mov     ax, 05000h
mov     cx, 8
mov     si, (pageswapargs_rend_offset_size) * 2 * PAGE_SWAP_ARG_MULT + OFFSET _pageswapargs
int     067h

mov     ax, 05000h
add     si, 8 * 2 * PAGE_SWAP_ARG_MULT
int     067h

mov     ax, 05000h
add     si, 8 * 2 * PAGE_SWAP_ARG_MULT
int     067h

mov   byte ptr ds:[_currenttask], TASK_RENDER
pop   dx
pop   bx
retf  
task_num_2_jump:
;Z_QUICKMAPAI1 pageswapargs_stat_offset_size INDEXED_PAGE_9C00_OFFSET

mov     dx, word ptr ds:[_emshandle]
mov     ax, 05000h
mov     cx, 1
mov     si, (pageswapargs_stat_offset_size) * 2 * PAGE_SWAP_ARG_MULT + OFFSET _pageswapargs
int     067h

;Z_QUICKMAPAI4 (pageswapargs_stat_offset_size+1) INDEXED_PAGE_7000_OFFSET

mov     ax, 05000h
mov     cx, 4
add     si, 1 * 2 * PAGE_SWAP_ARG_MULT
int     067h

;Z_QUICKMAPAI1 (pageswapargs_stat_offset_size+5) INDEXED_PAGE_6000_OFFSET

mov     ax, 05000h
mov     cx, 1
add     si, 4 * 2 * PAGE_SWAP_ARG_MULT
int     067h
mov   byte ptr ds:[_currenttask], TASK_STATUS
pop   dx
pop   bx
retf  

task_num_9_jump:
;Z_QUICKMAPAI8 pageswapargs_menu_offset_size INDEXED_PAGE_5000_OFFSET

mov     dx, word ptr ds:[_emshandle]
mov     ax, 05000h
mov     cx, 8
mov     si, (pageswapargs_menu_offset_size) * 2 * PAGE_SWAP_ARG_MULT + OFFSET _pageswapargs
int     067h

mov   byte ptr ds:[_currenttask], TASK_MENU
pop   dx
pop   bx
retf  
task_num_11_jump:
;Z_QUICKMAPAI16 pageswapargs_intermission_offset_size INDEXED_PAGE_6000_OFFSET
mov     dx, word ptr ds:[_emshandle]
mov     ax, 05000h
mov     cx, 8
mov     si, (pageswapargs_intermission_offset_size) * 2 * PAGE_SWAP_ARG_MULT + OFFSET _pageswapargs
int     067h

mov     ax, 05000h
add     si, 8 * 2 * PAGE_SWAP_ARG_MULT
int     067h

mov   byte ptr ds:[_currenttask], TASK_INTERMISSION
pop   dx
pop   bx
retf  

ENDP


PROC Z_QuickMapVisplanePage_ FAR
PUBLIC Z_QuickMapVisplanePage_



;	int16_t usedpageindex = pagenum9000 + PAGE_8400_OFFSET + physicalpage;
;	int16_t usedpagevalue;
;	int8_t i;
;	if (virtualpage < 2){
;		usedpagevalue = FIRST_VISPLANE_PAGE + virtualpage;
;	} else {
;		usedpagevalue = EMS_VISPLANE_EXTRA_PAGE + (virtualpage-2);
;	}

push  bx
push  cx
push  si
mov   cl, al
mov   dh, dl
mov   si, word ptr ds:[_pagenum9000]
mov   al, dl
add   si, PAGE_8400_OFFSET ; sub 3
cbw  
add   si, ax
mov   al, cl
cbw  
cmp   al, 2
jge   visplane_page_above_2
add   ax, FIRST_VISPLANE_PAGE
used_pagevalue_ready:

;		pageswapargs[pageswapargs_visplanepage_offset] = _EPR(usedpagevalue);

; _EPR here
IFDEF COMPILE_CHIPSET
    add  ax, EMS_MEMORY_PAGE_OFFSET
ELSE
ENDIF
mov   word ptr ds:[_pageswapargs + (pageswapargs_visplanepage_offset * PAGE_SWAP_ARG_MULT)], ax


;pageswapargs[pageswapargs_visplanepage_offset+1] = usedpageindex;
IFDEF COMPILE_CHIPSET
ELSE
    mov   word ptr ds:[_pageswapargs + ((pageswapargs_visplanepage_offset+1) * PAGE_SWAP_ARG_MULT)], si
ENDIF

;	physicalpage++;
inc   dh
mov   dl, 4

;	for (i = 4; i > 0; i --){
;		if (active_visplanes[i] == physicalpage){
;			active_visplanes[i] = 0;
;			break;
;		}
;	}

loop_next_visplane_page:
mov   al, dl
cbw  
mov   bx, ax
cmp   dh, byte ptr ds:[bx + _active_visplanes]
je    set_zero_and_break
dec   dl
test  dl, dl
jg    loop_next_visplane_page

done_with_visplane_loop:
mov   al, cl
cbw  
mov   bx, ax

mov   byte ptr ds:[bx + _active_visplanes], dh

; todo this call doesnt work

IFDEF COMPILE_CHIPSET
    mov     dx, si
    or      dx, EMS_AUTOINCREMENT_FLAG
    mov     ax,  pageswapargs_visplanepage_offset_size * 2 * PAGE_SWAP_ARG_MULT + _pageswapargs
    call    Z_QuickMap1AIC_ 
ELSE


    mov     dx, word ptr ds:[_emshandle]
    mov     ax, 05000h
    mov     cx, 1
    mov     si, (pageswapargs_visplanepage_offset_size) * 2 * PAGE_SWAP_ARG_MULT + OFFSET _pageswapargs
    int     067h


ENDIF


mov   byte ptr ds:[_visplanedirty], 1
pop   si
pop   cx
pop   bx
retf  
visplane_page_above_2:
;		usedpagevalue = EMS_VISPLANE_EXTRA_PAGE + (virtualpage-2);
add   ax, (EMS_VISPLANE_EXTRA_PAGE - 2)
jmp   used_pagevalue_ready

set_zero_and_break:
mov   byte ptr ds:[bx + _active_visplanes], 0
jmp   done_with_visplane_loop

ENDP

PROC Z_QuickMapVisplaneRevert_ FAR
PUBLIC Z_QuickMapVisplaneRevert_

push  dx
mov   dx, 1
mov   ax, dx
call  Z_QuickMapVisplanePage_
mov   dx, 2
mov   ax, dx
call  Z_QuickMapVisplanePage_
mov   byte ptr ds:[_visplanedirty], 0
pop   dx
retf  

ENDP




IFDEF COMPILE_CHIPSET
    PROC Z_QuickMapUnmapAll_ FAR
    PUBLIC Z_QuickMapUnmapAll_

    push  dx
    push  bx
    xor   ax, ax
    mov   bx, bx
    loop_next_page_to_unmap:
    mov   word ptr ds:[bx + _pageswapargs], -1
    inc   ax
    inc   bx
    inc   bx
    cmp   ax, 24
    jl    loop_next_page_to_unmap

    Z_QUICKMAPAI24 pageswapargs_phys_offset_size INDEXED_PAGE_4000_OFFSET
    pop   bx
    pop   dx
    retf  
ELSE
    PROC Z_QuickMapUnmapAll_ FAR
    PUBLIC Z_QuickMapUnmapAll_

    push  bx
    push  cx
    push  dx
    push  si
    mov   cx, word ptr ds:[_pagenum9000]
    xor   si, si
    xor   bx, bx

    loop_next_page_to_unmap:
    mov   word ptr ds:[bx + _pageswapargs], -1
    mov   al, byte ptr ds:[si + _ems_backfill_page_order]
    cbw  
    add   ax, cx
    inc   si
    mov   word ptr [bx + _pageswapargs+2], ax
    add   bx, 4  ; includes pageswap
    cmp   si, 24
    jl    loop_next_page_to_unmap

;    Z_QUICKMAPAI24 pageswapargs_phys_offset_size INDEXED_PAGE_4000_OFFSET

    mov     dx, word ptr ds:[_emshandle]
    mov     ax, 05000h
    mov     cx, 8
    mov     si, pageswapargs_phys_offset_size * 2 * PAGE_SWAP_ARG_MULT + OFFSET _pageswapargs
    int     067h

    mov     ax, 05000h
    add     si, 8 * 2 * PAGE_SWAP_ARG_MULT
    int     067h

    mov     ax, 05000h
    add     si, 8 * 2 * PAGE_SWAP_ARG_MULT
    int     067h

    pop   si
    pop   dx
    pop   cx
    pop   bx
    retf  
ENDIF



ENDP

_doomcode_filename:
db "DOOMCODE.BIN", 0

set_overlay_jump_table:

dw    exit_set_overlay
dw    finale_overlay_jump_target
dw    load_save_game_overlay_jump_target
dw    exit_set_overlay
dw    exit_set_overlay



PROC Z_SetOverlay_ FAR
PUBLIC Z_SetOverlay_
cmp   al, byte ptr ds:[_currentoverlay]
jne   do_overlay_change
retf  
do_overlay_change:

push  bx
push  cx
push  dx
push  si
push  bp
mov   bp, sp
push  ax
sub   sp, 2

mov   byte ptr ds:[_currentoverlay], al
cbw
mov   si, ax
mov   dx, _fopen_rb_argument
shl   si, 2

mov   ax, OFFSET _doomcode_filename
call  CopyString13_Zonelocal_
; todo les
mov   bx, word ptr ds:[si + _codestartposition-4]
mov   cx, word ptr ds:[si + _codestartposition-2]
call  fopen_
xor   dx, dx
mov   si, ax
call  fseek_
mov   bx, 1
mov   dx, 2
lea   ax, [bp - 4]
mov   cx, si
call  fread_
mov   cx, 1
mov   bx, word ptr [bp - 4]
mov   dx, CODE_OVERLAY_SEGMENT
push  si
xor   ax, ax

call  locallib_far_fread_
mov   ax, si
call  fclose_
mov   al, byte ptr [bp - 2]
dec   al
cmp   al, 4
ja    exit_set_overlay
xor   ah, ah
mov   bx, ax
sal   bx, 1
jmp   word ptr cs:[bx + set_overlay_jump_table]
load_save_game_overlay_jump_target:
mov   ax, CODE_OVERLAY_SEGMENT
mov   es, ax
mov   word ptr es:[0], OFFSET _playerMobjRef
LEAVE_MACRO 
pop   si
pop   dx
pop   cx
pop   bx
retf 

finale_overlay_jump_target:
mov   ax, CODE_OVERLAY_SEGMENT
mov   es, ax
mov   word ptr es:[0], OFFSET _hu_font
exit_set_overlay:
LEAVE_MACRO 
pop   si
pop   dx
pop   cx
pop   bx
retf
ENDP


; copy string from cs:ax to ds:_filename_argument
; return _filename_argument in ax

PROC CopyString13_Zonelocal_ NEAR
PUBLIC CopyString13_Zonelocal_

push  si
push  di
push  cx

mov   di, OFFSET _filename_argument

push  ds
pop   es    ; es = ds

push  cs
pop   ds    ; ds = cs

mov   si, ax

mov   ax, 0
stosw       ; zero out
stosw
stosw
stosw
stosw
stosw
stosb

mov  cx, 13
sub  di, cx

do_next_char:
lodsb
stosb
test  al, al
je    done_writing
loop do_next_char


done_writing:

mov   ax, OFFSET _filename_argument   ; ax now points to the near string

push  ss
pop   ds    ; restore ds

pop   cx
pop   di
pop   si

ret

ENDP


END
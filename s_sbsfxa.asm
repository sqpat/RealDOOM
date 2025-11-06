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
.MODEL  medium
INCLUDE defs.inc
INSTRUCTION_SET_MACRO



EXTRN W_LumpLength_:FAR
EXTRN W_CheckNumForNameFarString_:NEAR
EXTRN W_CacheLumpNameDirectFarString_:FAR
EXTRN Z_QuickMapPhysics_:FAR
EXTRN Z_QuickMapPalette_:FAR
EXTRN Z_QuickMapStatus_:FAR





.DATA

EXTRN _sfxcache_nodes:CACHE_NODE_PAGE_COUNT_T
EXTRN _sfx_page_reference_count:BYTE

.CODE




PROC    S_SBFX_STARTMARKER_ NEAR
PUBLIC  S_SBFX_STARTMARKER_
ENDP

PROC    S_IncreaseRefCount_ NEAR
PUBLIC  S_IncreaseRefCount_

    push  bx
    push  dx
    mov   bx, ax
    ; dword lookup
    SHIFT_MACRO sal   bx 2
    mov   dx, word ptr ds:[_sfxcache_nodes + bx + CACHE_NODE_PAGE_COUNT_T.cachenodecount_pagecount]
    test  dh, dh
    jne   increaserefcount_multipage

    increaserefcount_singlepage:
    xchg  ax, bx ; restore byte ptr
    inc   byte ptr ds:[_sfx_page_reference_count + bx]
    pop   dx
    pop   bx
    ret

    increaserefcount_multipage:
    cmp   dl, 1
    je    done_with_increaseref_multipage_loop
    loop_next_increaserefcount_multipage:
    mov   al, byte ptr ds:[_sfxcache_nodes + bx + CACHE_NODE_PAGE_COUNT_T.cachenodecount_prev]
    mov   bl, al
    SHIFT_MACRO sal   bx 2
    mov   dl, byte ptr ds:[_sfxcache_nodes + bx + CACHE_NODE_PAGE_COUNT_T.cachenodecount_pagecount]
    cmp   dl, 1
    jne   loop_next_increaserefcount_multipage

    ; dl = pagecount
    ; dh = numpages
    ; bx is currentpage (sal 2)
    ; al is unshifted currentpage

    done_with_increaseref_multipage_loop:
    cbw   ; clear ah

    loop_increase_next_ref:
    xchg  ax, bx ; restore byte ptr
    inc   byte ptr ds:[_sfx_page_reference_count + bx]
    xchg  ax, bx ; restore dword ptr
    mov   al, byte ptr ds:[_sfxcache_nodes + bx + CACHE_NODE_PAGE_COUNT_T.cachenodecount_next]
    mov   bl, al
    SHIFT_MACRO sal   bx 2
    dec   dh
    jnz   loop_increase_next_ref

    pop   dx
    pop   bx
    ret


ENDP




PROC    S_SBFX_ENDMARKER_ NEAR
PUBLIC  S_SBFX_ENDMARKER_
ENDP

END
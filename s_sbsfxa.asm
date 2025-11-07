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



EXTRN I_Error_:FAR





.DATA

EXTRN _sfxcache_nodes:CACHE_NODE_PAGE_COUNT_T
EXTRN _sfx_page_reference_count:BYTE



.CODE




PROC    S_SBFX_STARTMARKER_ NEAR
PUBLIC  S_SBFX_STARTMARKER_
ENDP

str_bad_sfx_refcount:
db "Bad sfx ref count", 0

PROC    S_IncreaseRefCount_ NEAR
PUBLIC  S_IncreaseRefCount_

    push  bx
    cbw   ; clear ah

    mov   bx, ax
    ; dword lookup
    SHIFT_MACRO sal   bx 2
    cmp   byte ptr ds:[_sfxcache_nodes + bx + CACHE_NODE_PAGE_COUNT_T.cachenodecount_numpages], ah ; known 0
    jne   increaserefcount_multipage

    increaserefcount_singlepage:
    xchg  ax, bx ; restore byte ptr
    inc   byte ptr ds:[_sfx_page_reference_count + bx]
    pop   bx
    ret

    increaserefcount_multipage:
    push  dx
    mov   dx, word ptr ds:[_sfxcache_nodes + bx + CACHE_NODE_PAGE_COUNT_T.cachenodecount_pagecount]
    ; dh stores numpages
    ; dl has page count. which should be linearly stored so we just decrease towards 1 as we go up the list.
    loop_next_increaserefcount_multipage:
    cmp   dl, 1
    je    done_with_increaseref_multipage_loop
    mov   al, byte ptr ds:[_sfxcache_nodes + bx + CACHE_NODE_PAGE_COUNT_T.cachenodecount_prev]
    mov   bl, al
    SHIFT_MACRO sal   bx 2
    dec   dx   ; dl go towards 1
    jmp   loop_next_increaserefcount_multipage

    ; dl = pagecount
    ; dh = numpages
    ; bx is currentpage (sal 2)
    ; al is unshifted currentpage

    done_with_increaseref_multipage_loop:

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

; todo put in constants
SFX_ID_MASK = 07Fh

PROC    S_DecreaseRefCount_ NEAR
PUBLIC  S_DecreaseRefCount_

    push  bx
    cbw   ; clear ah
    ; note! al is voice index, not cachepage!

    ;uint8_t cachepage = sfx_data[sb_voicelist[voice_index].sfx_id & SFX_ID_MASK].cache_position.bu.bytehigh; // if this is ever FF then something is wrong?

    SHIFT_MACRO    sal ax  3
    xchg   ax, bx
    mov    ax, SFX_DATA_SEGMENT
    mov    es, ax

    mov    al, byte ptr ds:[_sb_voicelist + bx + SB_VOICEINFO_T.sbvi_sfx_id]
    and    ax, SFX_ID_MASK
    sal    ax, 1   ; x 2
    mov    bx, ax
    sal    bx, 1   ; x 4
    add    bx, ax  ; x 6 (x4 + x2)
    mov    al, byte ptr es:[bx + SFXINFO_T.sfxinfo_cache_position + 1] ; cachepage lookup. byte high!
    cbw
    mov    bx, ax
    ; bl finally cachepage.
    ; dword lookup
    ;uint8_t numpages =  sfxcache_nodes[cachepage].numpages; // number of pages of this allocation, or the page it is a part of

    SHIFT_MACRO sal   bx 2
    cmp   byte ptr ds:[_sfxcache_nodes + bx + CACHE_NODE_PAGE_COUNT_T.cachenodecount_numpages], ah ; known 0
    jne   decreaserefcount_multipage

    decreaserefcount_singlepage:
    xchg  ax, bx ; restore byte ptr
    dec   byte ptr ds:[_sfx_page_reference_count + bx]
    js    error_bad_ref_count

    pop   bx
    ret

    decreaserefcount_multipage:
    push  dx
    mov   dx, word ptr ds:[_sfxcache_nodes + bx + CACHE_NODE_PAGE_COUNT_T.cachenodecount_pagecount]
    ; dh stores numpages
    ; dl has page count. which should be linearly stored so we just decrease towards 1 as we go up the list.
    loop_next_decreaserefcount_multipage:
    cmp   dl, 1
    je    done_with_decreaseref_multipage_loop
    mov   al, byte ptr ds:[_sfxcache_nodes + bx + CACHE_NODE_PAGE_COUNT_T.cachenodecount_prev]
    mov   bl, al
    SHIFT_MACRO sal   bx 2
    dec   dx   ; dl go towards 1
    jmp   loop_next_decreaserefcount_multipage

    ; dl = pagecount
    ; dh = numpages
    ; bx is currentpage (sal 2)
    ; al is unshifted currentpage

    done_with_decreaseref_multipage_loop:

    loop_decrease_next_ref:
    xchg  ax, bx ; restore byte ptr
    dec   byte ptr ds:[_sfx_page_reference_count + bx]
    js    error_bad_ref_count
    xchg  ax, bx ; restore dword ptr
    mov   al, byte ptr ds:[_sfxcache_nodes + bx + CACHE_NODE_PAGE_COUNT_T.cachenodecount_next]
    mov   bl, al
    SHIFT_MACRO sal   bx 2
    dec   dh
    jnz   loop_decrease_next_ref

    pop   dx
    pop   bx
    ret

    error_bad_ref_count:
    push    cs
    mov     ax, OFFSET str_bad_sfx_refcount
    push    ax
    call    I_Error_


ENDP



; todo move to a sound asm file
;void S_NormalizeSfxVolume(uint16_t offset, uint16_t length){

PROC S_NormalizeSfxVolume_ NEAR
PUBLIC S_NormalizeSfxVolume_

push si
push cx
mov  cl, byte ptr ds:[_snd_SfxVolume]
mov  ch, 080h
add  dx, ax       ; length+offset. end condition
mov  si, ax       ; si gets offset
mov  ds, word ptr ds:[_SFX_PAGE_SEGMENT_PTR]   ; segment
do_next_byte:
lodsb
sub  al, ch
imul cl
sal  ax, 1
add  ah, ch
mov  byte ptr ds:[si-1], ah
cmp  si, dx
jb   do_next_byte
exit_loop:
mov  ax, FIXED_DS_SEGMENT
mov  ds, ax ; restore ds
pop  cx
pop  si
ret

ENDP


PROC    S_SBFX_ENDMARKER_ NEAR
PUBLIC  S_SBFX_ENDMARKER_
ENDP

END
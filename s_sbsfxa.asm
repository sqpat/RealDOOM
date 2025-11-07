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
EXTRN _sfxcache_head:BYTE
EXTRN _sfxcache_tail:BYTE


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

    ;    while (sfxcache_nodes[prev_startpoint].pagecount != 1){
    ;        prev_startpoint = sfxcache_nodes[prev_startpoint].prev;
    ;    }


find_prev_startpoint:
    mov   cl, byte ptr ds:[_sfxcache_nodes + si + CACHE_NODE_PAGE_COUNT_T.cachenodecount_pagecount]
    dec   cx
    jz    done_with_prevstartpoint_loop
    
        loop_find_prev_startpoint:
        mov   al, byte ptr ds:[_sfxcache_nodes + si + CACHE_NODE_PAGE_COUNT_T.cachenodecount_prev]
        mov   si, ax
        SHIFT_MACRO sal   si 2
        loop  loop_find_prev_startpoint    
    mov   bx, ax  ; bx gets prev_startpoint unshifted
    jmp done_with_prevstartpoint_loop


PROC S_MoveCacheItemBackOne_ NEAR
PUBLIC S_MoveCacheItemBackOne_


PUSHA_NO_AX_MACRO
mov   dx, ax  ; dl stores non dword ptr of next_startpoint (and zero dh)
mov   bx, ax  ; bx gets prev_startpoint unshifted
SHIFT_MACRO sal   ax 2
mov   si, ax  ; si gets prev_startpoint
mov   bp, ax  ; bp gets next_startpoint
xor   cx, cx  ; zero cx


    ; we are iterating from head to tail, going prev each step.
    ; so we have an index that must be moved next towards head.
    ; but we must move the contiguous pages in the allocations, so iterate prev until we find it's end.

    ;if (sfxcache_nodes[prev_startpoint].numpages){

    cmp   byte ptr ds:[_sfxcache_nodes + si + CACHE_NODE_PAGE_COUNT_T.cachenodecount_numpages],  ch ; known 0
    jne   find_prev_startpoint

    use_existing_prevstartpoint:
    done_with_prevstartpoint_loop:


;        int8_t swap_tail = sfxcache_nodes[next_startpoint].next; // D
;        int8_t swap_head = swap_tail;

    mov   al, byte ptr ds:[_sfxcache_nodes + bp + CACHE_NODE_PAGE_COUNT_T.cachenodecount_next]
    mov   di, ax 
    SHIFT_MACRO sal   di 2  
    mov   cl, al    ; cl stores swaptail
    mov   ch, dl    ; now ch gets next_startpoint (unshifted)
    mov   dl, al    ; dl stores swaphead

;        int8_t prev = sfxcache_nodes[prev_startpoint].prev; // A

    mov   ah, byte ptr ds:[_sfxcache_nodes + si + CACHE_NODE_PAGE_COUNT_T.cachenodecount_prev]

    ; ah is prev                (unshifted)
    ; cl is swap_tail           (unshifted)        
    ; bl is prev_startpoint     (unshifted)
    ; si is prev_startpoint     (dword shift)
    ; ch is next_startpoint     (unshifted)
    ; bp is next_startpoint     (dword shift)
    ; dl is swap_head           (unshifted)
    ; di is swap_head           (dword shift)


;        if (sfxcache_nodes[swap_head].numpages){
;        }

    mov   al, byte ptr ds:[_sfxcache_nodes + di + CACHE_NODE_PAGE_COUNT_T.cachenodecount_numpages]
    test  al, al
    jne   find_swap_head 
    use_existing_swaphead:
    found_swaphead:

;    nextnext = sfxcache_nodes[swap_head].next;    // E
    mov   al, byte ptr ds:[_sfxcache_nodes + di + CACHE_NODE_PAGE_COUNT_T.cachenodecount_next]

    mov   dh, bl ; now dh stores prev_startpoint

    ; al is nextnext            (unshifted)
    ; ah is prev                (unshifted)
    ; cl is swap_tail           (unshifted)
    ; ch is next_startpoint     (unshifted)
    ; bp is next_startpoint     (dword shift)
    ; dh is prev_startpoint     (unshifted)
    ; si is prev_startpoint     (dword shift)
    ; dl is swap_head           (unshifted)
    ; di is swap_head           (dword shift)


;        // update cache head if its been updated.
;        if (nextnext != -1){
;            sfxcache_nodes[nextnext].prev    = next_startpoint;
;        } else {
;            sfxcache_head = next_startpoint;
;        }

test  al, al
js    update_cache_head

mov   bl, al
SHIFT_MACRO sal   bx 2  
mov   byte ptr ds:[_sfxcache_nodes + bx + CACHE_NODE_PAGE_COUNT_T.cachenodecount_prev], ch
jmp   done_setting_nextstartpoint

update_cache_head:
mov   byte ptr ds:[_sfxcache_head], ch

done_setting_nextstartpoint:


    ; ah is prev                (unshifted)
    ; al is nextnext            (unshifted)
    ; cl is swaptail            (unshifted)
    ; ch free
    ; bx is free, bh is 0
    ; dl is swaphead            (unshifted)
    ; dh is prev_startpoint     (unshifted)
    ; si is prev_startpoint     (dword shift)
    ; bp is next_startpoint     (dword shift)
    ; di is swap_head ptr       (dword shift)

;        if (prev != -1){
;            sfxcache_nodes[prev].next    = swap_tail;
;        } else {
;            // change tail?
;            // presumably sfxcache_tail WAS prev_startpoint.
;            sfxcache_tail = swap_tail;
;        }

test  ah, ah
js    update_cache_tail
mov   bl, ah
SHIFT_MACRO sal   bx 2  
mov   byte ptr ds:[_sfxcache_nodes + bx + CACHE_NODE_PAGE_COUNT_T.cachenodecount_next], cl
jmp   done_setting_swaptail

update_cache_tail:
mov   byte ptr ds:[_sfxcache_tail], cl

done_setting_swaptail:

;        sfxcache_nodes[swap_head].next   = prev_startpoint;
mov   byte ptr ds:[_sfxcache_nodes + di + CACHE_NODE_PAGE_COUNT_T.cachenodecount_next], dh
;        sfxcache_nodes[swap_tail].prev        = prev;
mov   bl, cl
SHIFT_MACRO sal   bx 2  
mov   byte ptr ds:[_sfxcache_nodes + bx + CACHE_NODE_PAGE_COUNT_T.cachenodecount_prev], ah


;        sfxcache_nodes[next_startpoint].next = nextnext;
;        sfxcache_nodes[prev_startpoint].prev = swap_head;

mov   byte ptr ds:[_sfxcache_nodes + bp + CACHE_NODE_PAGE_COUNT_T.cachenodecount_next], al
mov   byte ptr ds:[_sfxcache_nodes + si + CACHE_NODE_PAGE_COUNT_T.cachenodecount_prev], dl

POPA_NO_AX_MACRO
ret   
;            while (sfxcache_nodes[swap_head].pagecount != sfxcache_nodes[swap_head].numpages){
;                swap_head = sfxcache_nodes[swap_head].next;
;            }

find_swap_head:

    loop_check_next_swaphead:
    cmp   al, byte ptr ds:[_sfxcache_nodes + di + CACHE_NODE_PAGE_COUNT_T.cachenodecount_pagecount]
    je    found_swaphead
    mov   dl, byte ptr ds:[_sfxcache_nodes + di + CACHE_NODE_PAGE_COUNT_T.cachenodecount_next]
    mov   di, dx 
    SHIFT_MACRO sal   di 2  
    jmp   loop_check_next_swaphead

ENDP

PROC   S_UpdateLRUCache_ NEAR
PUBLIC S_UpdateLRUCache_

push  dx
push  si

mov   al, byte ptr ds:[_sfxcache_head]
cbw
cwd 

; al =  currentpage
; dh =  known zero
; dl =  found_evictable

loop_update_next:
mov   si, ax   ; si =  currentpage lookup

test  dl, dl
je    do_found_evictable
cmp   byte ptr ds:[_sfx_page_reference_count + si], dh
je    dont_move_cache_back
call  S_MoveCacheItemBackOne_


jmp   done_moving_cache_back

do_found_evictable:

cmp   byte ptr ds:[_sfx_page_reference_count + si], dh
jne   not_found_evictable
inc   dx           ; found_evictable = true;

not_found_evictable:
dont_move_cache_back:
done_moving_cache_back:

SHIFT_MACRO  sal si  2

;        if (sfxcache_nodes[currentpage].numpages){
;            // get to the last page
;            while (sfxcache_nodes[currentpage].pagecount != 1){
;                currentpage = sfxcache_nodes[currentpage].prev;
;            }
;        }
mov   ax, dx  ; zero ah

cmp   byte ptr ds:[_sfxcache_nodes + si + CACHE_NODE_PAGE_COUNT_T.cachenodecount_numpages], dh ; known zero
jne   find_last_page

found_last_page:
mov   al, byte ptr ds:[_sfxcache_nodes + si + CACHE_NODE_PAGE_COUNT_T.cachenodecount_prev] ; currentpage = sfxcache_nodes[currentpage].prev;


test  al, al
jns   loop_update_next

pop   si
pop   dx

ret

find_last_page:
cmp   byte ptr ds:[_sfxcache_nodes + si + CACHE_NODE_PAGE_COUNT_T.cachenodecount_pagecount], 1
je    found_last_page
mov   al, byte ptr ds:[_sfxcache_nodes + si + CACHE_NODE_PAGE_COUNT_T.cachenodecount_prev] ; currentpage = sfxcache_nodes[currentpage].prev;
xchg  ax, si
SHIFT_MACRO  sal si  2

jmp   find_last_page


ENDP

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
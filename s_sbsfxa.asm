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

; todo... constants 64
BUFFERS_PER_EMS_PAGE = 16384 / 256

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

PROC   S_MarkSFXPageMRU_ NEAR
PUBLIC S_MarkSFXPageMRU_

;	if (index == sfxcache_head) {
;		return;
;	}


cmp    al, byte ptr ds:[_sfxcache_head]
jne    continue_markmru
ret
continue_markmru:
;	numpages = sfxcache_nodes[index].numpages;
cbw
push   bx
mov    bx, ax
SHIFT_MACRO   sal bx 2
mov    ah, byte ptr ds:[_sfxcache_nodes + bx + CACHE_NODE_PAGE_COUNT_T.cachenodecount_numpages]

;	if (numpages){

test   ah, ah
jne    search_for_page_start_mru


do_single_page_mru_update:



push   dx

mov    dx, word ptr ds:[_sfxcache_nodes + bx + CACHE_NODE_PAGE_COUNT_T.cachenodecount_prev]
mov    ah, dl  ; prev copied into ah..
; dl, ah prev
; dh next
;    if (index == sfxcache_tail) {

cmp    al, byte ptr ds:[_sfxcache_tail]
je     single_index_is_tail

;   sfxcache_nodes[prev].next = next; 

xchg   bl, dl
SHIFT_MACRO   sal bx 2
mov    byte ptr ds:[_sfxcache_nodes + bx + CACHE_NODE_PAGE_COUNT_T.cachenodecount_next], dh
mov    bl, dl ; restore index
jmp    done_setting_next_mru

;      sfxcache_tail = next;
single_index_is_tail:
mov    byte ptr ds:[_sfxcache_tail], dh

done_setting_next_mru:

;		sfxcache_nodes[next].prev = prev;  // works in either of the above cases. prev is -1 if tail.

xchg   bl, dh
SHIFT_MACRO   sal bx 2
mov    byte ptr ds:[_sfxcache_nodes + bx + CACHE_NODE_PAGE_COUNT_T.cachenodecount_prev], ah
mov    bl, dh  ; restore bl

mov    dl, al  ; back up index

;		sfxcache_head = index;
xchg   al, byte ptr ds:[_sfxcache_head]   ; 

;      al is (previous) _sfx_cachehead
;      dl is index

;		sfxcache_nodes[index].next = -1;
;		sfxcache_nodes[index].prev = sfxcache_head;
mov    ah, -1
mov    word ptr ds:[_sfxcache_nodes + bx + CACHE_NODE_PAGE_COUNT_T.cachenodecount_prev], ax  ; write both at once

;		sfxcache_nodes[sfxcache_head].next = index;


mov    bl, al
SHIFT_MACRO   sal bx 2
;    sfxcache_nodes[sfxcache_head].next = index;
mov    byte ptr ds:[_sfxcache_nodes + bx + CACHE_NODE_PAGE_COUNT_T.cachenodecount_next], dl

mov    byte ptr ds:[_sfxcache_head], dl  ; backed up old index

pop    dx
return_no_change:
pop    bx
ret


search_for_page_start_mru:
;	 	while (sfxcache_nodes[index].pagecount != numpages){
;			index = sfxcache_nodes[index].next;
;		}


loop_find_allocation_start:
cmp    ah, byte ptr ds:[_sfxcache_nodes + bx + CACHE_NODE_PAGE_COUNT_T.cachenodecount_pagecount]
je     found_allocation_start
mov    al, byte ptr ds:[_sfxcache_nodes + bx + CACHE_NODE_PAGE_COUNT_T.cachenodecount_next]
mov    bl, al
SHIFT_MACRO   sal bx 2
jmp    loop_find_allocation_start

;		if (index == sfxcache_head) {
;			return;
;		}

found_allocation_start:
cmp    al, byte ptr ds:[_sfxcache_head]
je     return_no_change

; al is index
; bx is index dword lookup
; bh is 0
; ah is numpages

; at this point we know its multipage..


push   dx
push   si
push   cx
mov    si, bx  ; si carries index now.. bx is lastindex

mov    dx, ax  ; dl carries lastindex.. al is index

; al is index
; si is index dword lookup
; dl is lastindex
; bx is lastindex dword lookup
; bh is 0
; ah/dh/cx is garbage


;		while (sfxcache_nodes[lastindex].pagecount != 1){
;			lastindex = sfxcache_nodes[lastindex].prev;
;		}

loop_find_lastindex:
cmp    byte ptr ds:[_sfxcache_nodes + bx + CACHE_NODE_PAGE_COUNT_T.cachenodecount_pagecount], 1
je     found_lastindex
mov    dl, byte ptr ds:[_sfxcache_nodes + bx + CACHE_NODE_PAGE_COUNT_T.cachenodecount_prev]
mov    bl, dl
SHIFT_MACRO   sal bx 2
jmp    loop_find_lastindex

found_lastindex:

;		index_next = sfxcache_nodes[index].next;
mov    ch, byte ptr ds:[_sfxcache_nodes + si + CACHE_NODE_PAGE_COUNT_T.cachenodecount_next]
mov    dh, ch
SHIFT_MACRO   sal dh 2


; al is index
; si is index dword lookup
; dl is lastindex
; bx is lastindex dword lookup
; bh is 0
; ch is index_next
; dh is index_next lookup sword

;		if (sfxcache_tail == lastindex){
cmp    dl, byte ptr ds:[_sfxcache_tail]
je     tail_is_lastindex

;		lastindex_prev = sfxcache_nodes[lastindex].prev;
mov    cl, byte ptr ds:[_sfxcache_nodes + bx + CACHE_NODE_PAGE_COUNT_T.cachenodecount_prev]
mov    ah, cl    ; ah backs up lastindex_prev
xchg   cl, bl
SHIFT_MACRO   sal bl 2
;			sfxcache_nodes[lastindex_prev].next = index_next;
mov    byte ptr ds:[_sfxcache_nodes + bx + CACHE_NODE_PAGE_COUNT_T.cachenodecount_next], ch
xchg   dh, bl
;			sfxcache_nodes[index_next].prev = lastindex_prev;
mov    byte ptr ds:[_sfxcache_nodes + bx + CACHE_NODE_PAGE_COUNT_T.cachenodecount_prev], ah
xchg   cl, bl   ; restore bl to lastindex lookup
jmp    done_with_tail_check


tail_is_lastindex:
;			sfxcache_tail = index_next;
;			sfxcache_nodes[index_next].prev = -1;
mov    byte ptr ds:[_sfxcache_tail], ch
xchg   dh, bl
mov    byte ptr ds:[_sfxcache_nodes + bx + CACHE_NODE_PAGE_COUNT_T.cachenodecount_prev], -1
mov    bl, dh   ; restore bl to lastindex lookup

done_with_tail_check:

;		sfxcache_nodes[lastindex].prev = sfxcache_head;
mov    cl, byte ptr ds:[_sfxcache_head]
mov    byte ptr ds:[_sfxcache_nodes + bx + CACHE_NODE_PAGE_COUNT_T.cachenodecount_prev], cl

;		sfxcache_nodes[sfxcache_head].next = lastindex;
xchg   cl, bl
SHIFT_MACRO   sal bl 2
mov    byte ptr ds:[_sfxcache_nodes + bx + CACHE_NODE_PAGE_COUNT_T.cachenodecount_next], dl

;		sfxcache_nodes[index].next = -1;
mov    byte ptr ds:[_sfxcache_nodes + si + CACHE_NODE_PAGE_COUNT_T.cachenodecount_next], -1
;		sfxcache_head = index;
mov    byte ptr ds:[_sfxcache_head], al


pop    cx
pop    si
pop    dx
pop    bx
ret



ENDP

;for (i = 0; i < numpages-1; i++){
;    currentpage = sfxcache_nodes[currentpage].next;
;}


loop_find_more_pages:
mov    dh, byte ptr ds:[_sfxcache_nodes + bx + CACHE_NODE_PAGE_COUNT_T.cachenodecount_next]
mov    bl, dh
SHIFT_MACRO  sal bl 2
dec    ax
jnz    loop_find_more_pages
jmp    done_finding_nextmost
pages_in_use_exit:
POPA_NO_AX_MACRO
mov    ax, -1
ret
PROC   S_EvictSFXPage_ NEAR
PUBLIC S_EvictSFXPage_

PUSHA_NO_AX_MACRO

cbw    ; zero ah...

;	currentpage = sfxcache_tail;
mov    dl, byte ptr ds:[_sfxcache_tail]   ; dl holds tail
mov    dh, dl                             ; dh holds currentpage
xor    bx, bx
mov    bl, dh
SHIFT_MACRO  sal bl 2  ; bx holds currentpage/tail
mov    di, bx
  
dec    ax      ; numpages - 1
jnz    loop_find_more_pages



done_finding_nextmost:


;	evictedpage = currentpage;
mov    cl, dh   
mov    ah, bl   ; evictedpage lookup

; al is 0
; ah is currentpage lookup
; dl holds sfx_cache_tail
; cl is evictedpage
; di holds sfx_cache_tail lookup
; dh holds currentpage
; bx holds evictedpage lookup (same as ah currently)

loop_check_next_evictedpage:
;	while (sfxcache_nodes[evictedpage].numpages != sfxcache_nodes[evictedpage].pagecount){
;		evictedpage = sfxcache_nodes[evictedpage].next;
;	}

mov    al, byte ptr ds:[_sfxcache_nodes + bx + CACHE_NODE_PAGE_COUNT_T.cachenodecount_numpages]
cmp    al, byte ptr ds:[_sfxcache_nodes + bx + CACHE_NODE_PAGE_COUNT_T.cachenodecount_pagecount]
je     done_finding_evictedpage

mov    cl, byte ptr ds:[_sfxcache_nodes + bx + CACHE_NODE_PAGE_COUNT_T.cachenodecount_next]
mov    bl, cl
SHIFT_MACRO  sal bl 2
jmp    loop_check_next_evictedpage

done_finding_evictedpage:

xchg   bl, ah   ; reverse evictedpage/currentpage again

; al is garbage
; ah is evictedpage lookup
; dl holds sfx_cache_tail
; cl is evictedpage
; di holds sfx_cache_tail lookup
; dh holds currentpage
; bx holds currentpage lookup





;		int8_t checkpage = evictedpage;
;    	while (checkpage != -1){
;            if (sfx_page_reference_count[checkpage]){
;                // the minimum required pages to evict overlapped with an in use page!
;                // fail gracefully.
;                return -1;
;            }
;            checkpage = sfxcache_nodes[checkpage].prev;
;        }
;    }

mov    al, cl   ; checkpage
check_next_page_in_use:
test   al, al
js     done_with_checkpage_loop
xchg   al, bl
cmp    byte ptr ds:[_sfx_page_reference_count + bx], bh ; known zero
jne    pages_in_use_exit
SHIFT_MACRO  sal bl 2
mov    bl, byte ptr ds:[_sfxcache_nodes + bx + CACHE_NODE_PAGE_COUNT_T.cachenodecount_prev]
xchg   al, bl ; juggle these back
jmp    check_next_page_in_use

done_with_checkpage_loop:







xchg   ah, bl
mov    al, cl  ; copy over evictedpage

; al is evictedpage
; ah is currentpage lookup
; dl holds sfx_cache_tail
; dh holds currentpage
; bx holds evictedpage lookup
; di holds sfx_cache_tail lookup


;	while (evictedpage != -1){
test   al, al
js     done_with_evictedpageloop

mov    bp, SIZE SFXINFO_T; for adding to si

evict_next_page:
;		sfxcache_nodes[evictedpage].pagecount = 0;
;		sfxcache_nodes[evictedpage].numpages = 0;
mov    word ptr ds:[_sfxcache_nodes + bx + CACHE_NODE_PAGE_COUNT_T.cachenodecount_pagecount], 0

;		for (i = 0; i < NUMSFX; i++){
;			if ((sfx_data[i].cache_position.bu.bytehigh) == evictedpage){
;				sfx_data[i].cache_position.bu.bytehigh = SOUND_NOT_IN_CACHE;
;			}
;		}


mov   cx, SFX_DATA_SEGMENT
mov   ds, cx
mov   si, SFXINFO_T.sfxinfo_cache_position + 1   ; 3
mov   cx, NUMSFX

loop_check_next_cache_position:

cmp   byte ptr ds:[si], al
je    erase_this_sfx
done_erasing_this_sfx:
add   si, bp   ; 4
loop  loop_check_next_cache_position

mov   cx, ss
mov   ds, cx

;		sfx_free_bytes[evictedpage] = BUFFERS_PER_EMS_PAGE;
xchg   al, bl
mov    byte ptr ds:[_sfx_free_bytes + bx], BUFFERS_PER_EMS_PAGE
xchg   al, bl

;		evictedpage = sfxcache_nodes[evictedpage].prev;
mov    al, byte ptr ds:[_sfxcache_nodes + bx + CACHE_NODE_PAGE_COUNT_T.cachenodecount_prev]
mov    bl, al
SHIFT_MACRO  sal bl 2
test   al, al
jns    evict_next_page

done_with_evictedpageloop:

; al is garbage
; ah is currentpage lookup
; dl holds sfx_cache_tail
; dh holds currentpage
; bx garbage
; di holds sfx_cache_tail lookup
; cx garbage
mov cl, -1

;	// connect old tail and old head.
;	sfxcache_nodes[sfxcache_tail].prev = sfxcache_head;
mov    al, byte ptr ds:[_sfxcache_head]
mov    byte ptr ds:[_sfxcache_nodes + di + CACHE_NODE_PAGE_COUNT_T.cachenodecount_prev], al


;	sfxcache_nodes[sfxcache_head].next = sfxcache_tail;
mov    bl, al
SHIFT_MACRO sal bl 2
mov    byte ptr ds:[_sfxcache_nodes + bx + CACHE_NODE_PAGE_COUNT_T.cachenodecount_next], dl

;	previous_next = sfxcache_nodes[currentpage].next;

mov    bl, ah
mov    al, byte ptr ds:[_sfxcache_nodes + bx + CACHE_NODE_PAGE_COUNT_T.cachenodecount_next]

; al is previousnext
; bx currentpagelookup

;	sfxcache_head = currentpage;
;	sfxcache_nodes[currentpage].next = -1;
mov    byte ptr ds:[_sfxcache_head], dh
mov    byte ptr ds:[_sfxcache_nodes + bx + CACHE_NODE_PAGE_COUNT_T.cachenodecount_next], cl ; -1



;	sfxcache_nodes[previous_next].prev = -1;
mov    bl, al
SHIFT_MACRO sal bl 2
mov    byte ptr ds:[_sfxcache_nodes + bx + CACHE_NODE_PAGE_COUNT_T.cachenodecount_prev], cl ; -1
;	sfxcache_tail = previous_next;
mov    byte ptr ds:[_sfxcache_tail], al

;	return currentpage; // sfxcache_head

mov    al, dh
cbw
mov    es, ax
POPA_NO_AX_MACRO
mov    ax, es

ret



erase_this_sfx:
mov   byte ptr ds:[si], -1
jmp   done_erasing_this_sfx


ENDP

;void S_NormalizeSfxVolume(uint16_t offset, uint16_t length){

PROC   S_NormalizeSfxVolume_ NEAR
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
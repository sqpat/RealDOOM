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

 
EXTRN P_MobjThinker_:NEAR
EXTRN OutOfThinkers_:NEAR
EXTRN P_PlayerThink_:NEAR
EXTRN P_UpdateSpecials_:NEAR
EXTRN Z_QuickMapRenderTexture_:NEAR
EXTRN Z_QuickMapSpritePage_:NEAR


.DATA

EXTRN _spriteL1LRU:BYTE
EXTRN _textureL1LRU:BYTE
EXTRN _spritecache_nodes:BYTE
EXTRN _spritecache_l2_head:BYTE
EXTRN _spritecache_l2_tail:BYTE
EXTRN _texturecache_nodes:BYTE
EXTRN _texturecache_l2_head:BYTE
EXTRN _texturecache_l2_tail:BYTE
EXTRN _flatcache_nodes:BYTE
EXTRN _flatcache_l2_head:BYTE
EXTRN _flatcache_l2_tail:BYTE

EXTRN _usedtexturepagemem:BYTE
EXTRN _usedspritepagemem:BYTE
EXTRN _pageswapargs:WORD
EXTRN _cachedtex:WORD
EXTRN _cachedtex2:WORD
EXTRN _cachedlumps:WORD
EXTRN _activenumpages:WORD
EXTRN _activetexturepages:WORD
EXTRN _activespritenumpages:WORD
EXTRN _activespritepages:WORD
EXTRN _segloopnextlookup:WORD
EXTRN _seglooptexrepeat:WORD
.CODE




 



PROC R_MarkL1SpriteCacheMRU_ NEAR
PUBLIC R_MarkL1SpriteCacheMRU_


mov  ah, byte ptr ds:[_spriteL1LRU+0]
cmp  al, ah
je   exit_markl1spritecachemru
mov  byte ptr ds:[_spriteL1LRU+0], al
xchg byte ptr ds:[_spriteL1LRU+1], ah
cmp  al, ah
je   exit_markl1spritecachemru
xchg byte ptr ds:[_spriteL1LRU+2], ah
cmp  al, ah
je   exit_markl1spritecachemru
xchg byte ptr ds:[_spriteL1LRU+3], ah
exit_markl1spritecachemru:
ret  


ENDP



PROC R_MarkL1SpriteCacheMRU3_ NEAR
PUBLIC R_MarkL1SpriteCacheMRU3_

push word ptr ds:[_spriteL1LRU+1]     ; grab [1] and [2]
pop  word ptr ds:[_spriteL1LRU+2]     ; put in [2] and [3]
xchg al, byte ptr ds:[_spriteL1LRU+0] ; swap index for [0]
mov  byte ptr ds:[_spriteL1LRU+1], al ; put [0] in [1]

ret  

ENDP



PROC R_MarkL1TextureCacheMRU_ NEAR
PUBLIC R_MarkL1TextureCacheMRU_


mov  ah, byte ptr ds:[_textureL1LRU+0]
cmp  al, ah
je   exit_markl1texturecachemru
mov  byte ptr ds:[_textureL1LRU+0], al
xchg byte ptr ds:[_textureL1LRU+1], ah
cmp  al, ah
je   exit_markl1texturecachemru
xchg byte ptr ds:[_textureL1LRU+2], ah
cmp  al, ah
je   exit_markl1texturecachemru
xchg byte ptr ds:[_textureL1LRU+3], ah
cmp  al, ah
je   exit_markl1texturecachemru
xchg byte ptr ds:[_textureL1LRU+4], ah
cmp  al, ah
je   exit_markl1texturecachemru
xchg byte ptr ds:[_textureL1LRU+5], ah
cmp  al, ah
je   exit_markl1texturecachemru
xchg byte ptr ds:[_textureL1LRU+6], ah
cmp  al, ah
je   exit_markl1texturecachemru
xchg byte ptr ds:[_textureL1LRU+7], ah

exit_markl1texturecachemru:
ret  

ENDP



PROC R_MarkL1TextureCacheMRU7_ NEAR
PUBLIC R_MarkL1TextureCacheMRU7_


push word ptr ds:[_textureL1LRU+5]     ; grab [5] and [6]
pop  word ptr ds:[_textureL1LRU+6]     ; put in [6] and [7]

push word ptr ds:[_textureL1LRU+3]     ; grab [3] and [4]
pop  word ptr ds:[_textureL1LRU+4]     ; put in [4] and [5]

push word ptr ds:[_textureL1LRU+1]     ; grab [1] and [2]
pop  word ptr ds:[_textureL1LRU+2]     ; put in [2] and [3]

xchg al, byte ptr ds:[_textureL1LRU+0] ; swap index for [0]
mov  byte ptr ds:[_textureL1LRU+1], al ; put [0] in [1]

ret

ENDP

; assumes ah 0
PROC R_MarkL2CompositeTextureCacheMRU_ NEAR
PUBLIC R_MarkL2CompositeTextureCacheMRU_


cmp  al, byte ptr ds:[_texturecache_l2_head]
jne  dont_early_out_composite
ret

dont_early_out_composite:
PUSHA_NO_AX_MACRO
mov  si, OFFSET _texturecache_nodes
mov  di, OFFSET _texturecache_l2_tail
mov  es, di
mov  di, OFFSET _texturecache_l2_head

jmp  do_markl2func

ENDP

PROC R_MarkL2SpriteCacheMRU_ NEAR
PUBLIC R_MarkL2SpriteCacheMRU_

;	if (index == spritecache_l2_head) {
;		return;
;	}

cmp  al, byte ptr ds:[_spritecache_l2_head]
jne  dont_early_out
ret



dont_early_out:
PUSHA_NO_AX_MACRO
mov  si, OFFSET _spritecache_nodes
mov  di, OFFSET _spritecache_l2_tail
mov  es, di
mov  di, OFFSET _spritecache_l2_head

do_markl2func:

mov  cl, byte ptr ds:[di]
mov  dl, al
mov  bx, ax

;	pagecount = spritecache_nodes[index].pagecount;
;	if (pagecount){

SHIFT_MACRO shl  bx 2
mov  al, byte ptr ds:[bx + si + 2]
test al, al
je   sprite_pagecount_zero

;	 	while (spritecache_nodes[index].numpages != spritecache_nodes[index].pagecount){
;			index = spritecache_nodes[index].next;
;		}

sprite_check_next_cache_node:
mov  bl, dl   ; bh always zero here...
SHIFT_MACRO shl  bx 2
mov  ax, word ptr ds:[bx + si + 2]
cmp  al, ah
je   sprite_found_first_index
mov  dl, byte ptr ds:[bx + si + 1]
jmp  sprite_check_next_cache_node

sprite_found_first_index:

;		if (index == spritecache_l2_head) {
;			return;
;		}

cmp  dl, cl             ; dh is free, use dh instead here?
je   mark_sprite_lru_exit
sprite_pagecount_zero:


; bx should already be set...

;	if (spritecache_nodes[index].numpages){

cmp  byte ptr ds:[bx + si + 3], 0
je   selected_sprite_page_single_page

; multi page case...

;		lastindex = index;
;		while (spritecache_nodes[lastindex].pagecount != 1){
;			lastindex = spritecache_nodes[lastindex].prev;
;		}


mov  dh, dl         ; dh = last index
sprite_check_next_cache_node_pagecount:

mov  bl, dh         ; bh always 0 here...
SHIFT_MACRO  shl  bx 2
cmp  byte ptr ds:[bx + si + 2], 1
je   found_sprite_multipage_last_page
mov  dh, byte ptr ds:[bx + si + 0]
jmp  sprite_check_next_cache_node_pagecount

found_sprite_multipage_last_page:

; dl = index
; dh = lastindex

;		lastindex_prev = spritecache_nodes[lastindex].prev;
;		index_next = spritecache_nodes[index].next;


mov  ch, byte ptr ds:[bx + si + 0]    ; lastindex_prev
mov  bl, dl
SHIFT_MACRO   shl  bx 2

mov  cl, byte ptr ds:[bx + si + 1]    ; index_next

;		if (spritecache_l2_tail == lastindex){
mov  bx, es  ; tail
cmp  dh, byte ptr ds:[bx]
jne  spritecache_l2_tail_not_equal_to_lastindex

;			spritecache_l2_tail = index_next;
;			spritecache_nodes[index_next].prev = -1;

mov  byte ptr ds:[bx], cl
xor  bx, bx
mov  bl, cl
SHIFT_MACRO   shl  bx 2
mov  byte ptr ds:[bx + si + 0], -1
jmp  sprite_done_with_multi_tail_update

spritecache_l2_tail_not_equal_to_lastindex:

;			spritecache_nodes[lastindex_prev].next = index_next;
;			spritecache_nodes[index_next].prev = lastindex_prev;

xor  bx, bx
mov  bl, ch
SHIFT_MACRO shl  bx 2
mov  byte ptr ds:[bx + si + 1], cl

mov  bl, cl
SHIFT_MACRO shl  bx 2
mov  byte ptr ds:[bx + si + 0], ch

sprite_done_with_multi_tail_update:

;		spritecache_nodes[lastindex].prev = spritecache_l2_head;
;		spritecache_nodes[spritecache_l2_head].next = lastindex;

mov  bl, dh
SHIFT_MACRO    shl  bx 2
mov  al, byte ptr ds:[di]
mov  byte ptr ds:[bx + si + 0], al  ; spritecache_l2_head
mov  bl, al
SHIFT_MACRO    shl  bx 2
mov  byte ptr ds:[bx + si + 1], dh  ; lastindex

mov  bl, dl
SHIFT_MACRO    shl  bx 2

;		spritecache_nodes[index].next = -1;
;		spritecache_l2_head = index;


mov  byte ptr ds:[di], dl
mov  byte ptr ds:[bx + si + 1], -1
mark_sprite_lru_exit:
POPA_NO_AX_MACRO
ret  

selected_sprite_page_single_page:

;		// handle the simple one page case.
;		prev = spritecache_nodes[index].prev;
;		next = spritecache_nodes[index].next;

mov  dh, byte ptr ds:[bx + si + 1]
mov  ch, byte ptr ds:[bx + si + 0] ; todo get whole word and swap regs

;		if (index == spritecache_l2_tail) {
;			spritecache_l2_tail = next;
;		} else {
;			spritecache_nodes[prev].next = next; 
;		}


mov  bx, es  ; tail
cmp  dl, byte ptr ds:[bx]
jne  spritecache_tail_not_equal_to_index
mov  byte ptr ds:[bx], dh
xor  bx, bx
jmp  done_with_spritecache_tail_handling

spritecache_tail_not_equal_to_index:
xor  bx, bx
mov  bl, ch
SHIFT_MACRO shl  bx 2
mov  byte ptr ds:[bx + si + 1], dh

done_with_spritecache_tail_handling:

; spritecache_nodes[next].prev = prev;  // works in either of the above cases. prev is -1 if tail.

mov  bl, dh
SHIFT_MACRO shl  bx 2
mov  byte ptr ds:[bx + si + 0], ch

;	spritecache_nodes[index].prev = spritecache_l2_head;
;	spritecache_nodes[index].next = -1;

mov  bl, dl
SHIFT_MACRO shl  bx 2
mov  ch, -1
mov  word ptr ds:[bx + si + 0], cx

; spritecache_nodes[spritecache_l2_head].next = index;

mov  bl, cl
SHIFT_MACRO shl  bx 2
mov  byte ptr ds:[bx + si + 1], dl

;	spritecache_l2_head = index;

mov  byte ptr ds:[di], dl

POPA_NO_AX_MACRO
ret  


ENDP




PROC R_EvictL2CacheEMSPage_ NEAR
PUBLIC R_EvictL2CacheEMSPage_

; bp - 2    nodehead
; bp - 4    used for ds first, used for es first
; bp - 6    second offset used for si
; bp - 8    used for ds second
; bp - 0Ah  secondarymaxitersize
; bp - 0Ch  usedcacherefpage 
; bp - 0Eh  nodetail
; bp - 010h currentpage



push      bx
push      cx
push      si
push      di
push      bp
mov       bp, sp
mov       dh, al


cmp       dl, CACHETYPE_COMPOSITE
jne       not_composite
push      OFFSET _texturecache_l2_head      ; bp - 2
push      COMPOSITETEXTUREPAGE_SEGMENT      ; bp - 4
push      MAX_PATCHES                       ; bp - 6
push      PATCHOFFSET_SEGMENT               ; bp - 8
push      MAX_PATCHES                       ; bp - 0Ah
push      OFFSET _usedtexturepagemem        ; bp - 0Ch
mov       bx, OFFSET _texturecache_l2_tail
mov       di, OFFSET _texturecache_nodes


jmp       done_with_switchblock
not_composite:
cmp       dl, CACHETYPE_PATCH
jne       is_sprite

is_patch:
push      OFFSET _texturecache_l2_head      ; bp - 2
push      PATCHPAGE_SEGMENT                 ; bp - 4   
push      MAX_PATCHES                       ; bp - 6
push      COMPOSITETEXTUREOFFSET_SEGMENT    ; bp - 8
push      MAX_TEXTURES                      ; bp - 0Ah
push      OFFSET _usedtexturepagemem        ; bp - 0Ch
mov       bx, OFFSET _texturecache_l2_tail
mov       di, OFFSET _texturecache_nodes


jmp       done_with_switchblock

is_sprite:
push      OFFSET _spritecache_l2_head ; bp - 2
push      SPRITEPAGE_SEGMENT          ; bp - 4
push      MAX_SPRITE_LUMPS            ; bp - 6
push      0                           ; bp - 8
push      0                           ; bp - 0Ah
push      OFFSET _usedspritepagemem   ; bp - 0Ch;
mov       bx, OFFSET _spritecache_l2_tail
mov       di, OFFSET _spritecache_nodes


done_with_switchblock:

;	currentpage = *nodetail;

push      bx        ; bp - 0Eh
mov       al, byte ptr [bx]
cbw      
xor       dl, dl

;	// go back enough pages to allocate them all.
;	for (j = 0; j < numpages-1; j++){
;		currentpage = nodelist[currentpage].next;
;	}


; dh has numpages
; dl has j
dec       dh  ; numpages - 1

go_back_next_page:
cmp       dl, dh
jge       found_enough_pages
mov       bx, ax
SHIFT_MACRO shl       bx, 2
mov       al, byte ptr [bx + di + 1]  ; get next
inc       dl
jmp       go_back_next_page


found_enough_pages:

push ax   ; bp - 010h store currentpage

;	evictedpage = currentpage;

mov       cx, ax

;	while (nodelist[evictedpage].numpages != nodelist[evictedpage].pagecount){
;		evictedpage = nodelist[evictedpage].next;
;	}


find_first_evictable_page:
mov       bx, cx
SHIFT_MACRO shl       bx, 2
mov       ax, word ptr [bx + di + 2]
cmp       al, ah
je        found_first_evictable_page
mov       al, byte ptr [bx + di + 1]
cbw      
mov       cx, ax
jmp       find_first_evictable_page

found_first_evictable_page:





;	while (evictedpage != -1){
mov       dx, 000FFh      ; dh gets 0, dl gets ff

check_next_evicted_page:
cmp       cl, dl
je        cleared_all_cache_data


do_next_evicted_page:


; loop setup
mov       bx, cx
SHIFT_MACRO shl       bx 2

xor       ax, ax


;		nodelist[evictedpage].pagecount = 0;
;		nodelist[evictedpage].numpages = 0;

mov       word ptr ss:[bx + di + 2], ax    ; set both at once
mov       si, ax                   ; zero

lds       bx, dword ptr [bp - 6] ; both an index and a loop limit

;    for (k = 0; k < maxitersize; k++){
;			if ((cacherefpage[k] >> 2) == evictedpage){
;				cacherefpage[k] = 0xFF;
;				cacherefoffset[k] = 0xFF;
;			}
;		}
dec       bx   ; lodsw makes this off by one so we offset here...

continue_first_cache_erase_loop:
lodsb     ; increments si...
SHIFT_MACRO shr       ax, 2
cmp       al, cl
je        erase_this_page
done_erasing_page:
cmp       si, bx
jle       continue_first_cache_erase_loop   ; jle, not jl because bx is decced

done_with_first_cache_erase_loop:


;	for (k = 0; k < secondarymaxitersize; k++){
;        if ((secondarycacherefpage[k]) >> 2 == evictedpage){
;            secondarycacherefpage[k] = 0xFF;
;            secondarycacherefoffset[k] = 0xFF;
;        }
;    }

lds       bx, dword ptr [bp - 0Ah] 
cmp       bx, 0 
jle       skip_secondary_loop


xor       si, si                     ; offset and loop ctr
dec       bx
continue_second_cache_erase_loop:
lodsb

SHIFT_MACRO sar       ax 2
cmp       al, cl
je        erase_second_page
done_erasing_second_page:
cmp       si, bx
jle       continue_second_cache_erase_loop    ; jle, not jl because bx is decced

skip_secondary_loop:

;		usedcacherefpage[evictedpage] = 0;




mov       si, word ptr [bp - 0Ch] ; usedcacherefpage
mov       bx, cx
mov       byte ptr ss:[bx + si], dh    ; 0

;		evictedpage = nodelist[evictedpage].prev;

SHIFT_MACRO shl       bx 2
mov       cl, byte ptr ss:[bx + di]     ; get prev
cmp       cl, dl                   ; dl is -1
jne       do_next_evicted_page


cleared_all_cache_data:

;	// connect old tail and old head.
;	nodelist[*nodetail].prev = *nodehead;

mov      ax, ss
mov      ds, ax


mov       si, word ptr [bp - 0Eh]
lodsb
cbw      
mov       cx, ax            ; cx stores nodetail

SHIFT_MACRO shl       ax 2
xchg      ax, bx            ; bx has nodelist nodetail lookup

mov       si, word ptr [bp - 2]
mov       al, byte ptr [si]
mov       byte ptr [bx + di], al
mov       bl, al


;	nodelist[*nodehead].next = *nodetail;

SHIFT_MACRO shl       bx 2


mov       byte ptr [bx + di + 1], cl  ; write nodetail to next

;	previous_next = nodelist[currentpage].next;

;	*nodehead = currentpage;

mov       bx, word ptr [bp - 010h]
mov       byte ptr [si], bl
SHIFT_MACRO shl       bx 2
mov       al, byte ptr [bx + di + 1]    ; previous_next
cbw


;	nodelist[currentpage].next = -1;

mov       byte ptr [bx + di + 1], dl   ; still 0FFh

;	*nodetail = previous_next;


mov       bx, word ptr [bp - 0Eh]
mov       byte ptr [bx], al


;	// new tail
;	nodelist[previous_next].prev = -1;
mov       bx, ax
SHIFT_MACRO shl       bx 2
mov       byte ptr [bx + di], dl    ; still 0FFh

;	return *nodehead;

lodsb       

LEAVE_MACRO     
pop       di
pop       si
pop       cx
pop       bx
ret       
erase_this_page:
mov       byte ptr ds:[si-1], dl     ; 0FFh
mov       byte ptr ds:[si+bx], dl    ; 0FFh
jmp       done_erasing_page

erase_second_page:
mov       byte ptr ds:[si-1], dl      ; 0FFh
mov       byte ptr ds:[si+bx], dl     ; 0FFh
jmp       done_erasing_second_page



ENDP

PROC R_MarkL2FlatCacheMRU_ FAR
PUBLIC R_MarkL2FlatCacheMRU_

;	if (index == flatcache_l2_head) {
;		return;
;	}

cmp       al, byte ptr ds:[_flatcache_l2_head]
jne       continue_flatcachemru
retf
continue_flatcachemru:
push      bx
push      dx
push      si


;	cache_node_t far* nodelist  = flatcache_nodes;

mov       dl, al
mov       bx, OFFSET _flatcache_nodes


;	prev = nodelist[index].prev;
;	next = nodelist[index].next;


cbw      

add       ax, ax
mov       si, ax
mov       ax, word ptr [si + bx]

mov       dh, al ; back up

;	if (index == flatcache_l2_tail) {
;		flatcache_l2_tail = next;	
;	} else {
;		nodelist[prev].next = next;
;	}

cmp       dl, byte ptr ds:[_flatcache_l2_tail]
jne       index_not_tail

mov       byte ptr ds:[_flatcache_l2_tail], ah
jmp       flat_tail_check_done

index_not_tail:

mov       si, ax
and       si, 000FFh      ; blegh
sal       si, 1
mov       byte ptr [si + bx + 1], ah

flat_tail_check_done:

;	// guaranteed to have a next. if we didnt have one, it'd be head but we already returned from that case.
;	nodelist[next].prev = prev;

mov       al, ah
cbw      

mov       si, ax
sal       si, 1

mov       byte ptr ds:[si + bx], dh
mov       al, dl

mov       si, ax
sal       si, 1

;	nodelist[index].prev = flatcache_l2_head;
;	nodelist[index].next = -1;

mov       al, byte ptr ds:[_flatcache_l2_head]
mov       byte ptr ds:[si + bx], al
mov       byte ptr ds:[si + bx + 1], 0FFh

mov       si, ax
sal       si, 1

;	nodelist[flatcache_l2_head].next = index;

mov       byte ptr ds:[si + bx + 1], dl

;	flatcache_l2_head = index;
mov       byte ptr ds:[_flatcache_l2_head], dl
exit_flatcachemru:
pop       si
pop       dx
pop       bx
retf      


ENDP

PROC R_EvictFlatCacheEMSPage_ FAR
PUBLIC R_EvictFlatCacheEMSPage_


push      bx
push      dx
push      si
mov       al, byte ptr ds:[_flatcache_l2_tail]
mov       dh, al
cbw      

;	evictedpage = flatcache_l2_tail;
mov       bx, OFFSET _flatcache_nodes
mov       si, ax        ; si gets evictedpage.

;	// all the other flats in this are cleared.
;	allocatedflatsperpage[evictedpage] = 1;
mov       byte ptr ds:[si + _allocatedflatsperpage], 1
sal       si, 1  ; now word lookup.

;	flatcache_l2_tail = flatcache_nodes[evictedpage].next;	// tail is nextmost

mov       dl, byte ptr ds:[si + bx + 1]         ; dl has flatcache_l2_tail
mov       byte ptr ds:[_flatcache_l2_tail], dl

;	flatcache_nodes[evictedpage].next = -1;
mov       byte ptr ds:[si + bx + 1], 0FFh

;	flatcache_nodes[evictedpage].prev = flatcache_l2_head;

mov       al, byte ptr ds:[_flatcache_l2_head]
mov       byte ptr ds:[si + bx + 0], al

;	flatcache_nodes[flatcache_l2_head].next = evictedpage;
mov       si, ax
sal       si, 1
mov       byte ptr ds:[si + bx + 1], dh

;	flatcache_nodes[flatcache_l2_tail].prev = -1;

mov       al, dl
mov       si, ax
sal       si, 1
mov       byte ptr [si + bx + 0], 0FFh


;	flatcache_l2_head = evictedpage;


mov       byte ptr ds:[_flatcache_l2_head], dh


mov       bx, FLATINDEX_SEGMENT
mov       ds, bx
mov       ah, dh
xor       si, si
mov       bx, -1
mov       dx, MAX_FLATS


;   for (i = 0; i < MAX_FLATS; i++){
;	   if ((flatindex[i] >> 2) == evictedpage){
;         flatindex[i] = 0xFF;
;   	}
;  	}
check_next_flat:
lodsb       ; si is always one in front because of lodsb...

SHIFT_MACRO shr       al 2
cmp       al, ah
je        erase_flat
continue_erasing_flats:
cmp       si, dx
jb        check_next_flat
mov       al, ah
mov       bx, ss
mov       ds, bx
pop       si
pop       dx
pop       bx
retf   

erase_flat:
mov       byte ptr ds:[si+bx], bl   ; bx is -1. this both writes FF and subtracts the 1 from si
jmp       continue_erasing_flats

ENDP


COLUMN_IN_CACHE_WAD_LUMP_SEGMENT = 07000h

;void __near R_DrawColumnInCache (uint16_t patchcol_offset, segment_t currentdestsegment, int16_t patchoriginy, int16_t textureheight) {
; todo merge into generate composite
PROC R_DrawColumnInCache_ NEAR
PUBLIC R_DrawColumnInCache_

push      si
push      di
push      bp

mov       es, dx
mov       dx, COLUMN_IN_CACHE_WAD_LUMP_SEGMENT
mov       ds, dx

xchg      ax, bx  ; bx has patchcol offset
xchg      ax, dx  ; dx stores patchoriginy
mov       bp, cx  ; bp stores textureheight

;	while (patchcol->topdelta != 0xff) { 

cmp       byte ptr ds:[bx], 0FFh
je        exit_drawcolumn_in_cache
do_next_column_patch:

;		uint16_t     count = patchcol->length;

mov       ax, word ptr ds:[bx]  ; al topdelta

xor       cx, cx
xchg      cl, ah                ; length to cl, 0 to ah

; cx is count
; ax is topdelta for now

;		int16_t     position = patchoriginy + patchcol->topdelta;

xchg      ax, di
add       di, dx  ; patchoriginy + topdelta


;		byte __far * source = (byte __far *)patchcol + 3;
lea       si, [bx + 3] ; for memcpy

;		patchcol = (column_t __far*)((byte  __far*)patchcol + count + 4);

add       bx, cx
add       bx, 4


; count is cx
; position is di

;		if (position < 0) {
;			count += position;
;			position = 0;
;		}

test      di, di
jl        position_under_zero
done_with_position_check:

;		if (position + count > textureheight){
;			count = textureheight - position;
;		}


mov       ax, di
add       ax, cx
cmp       ax, bp
jbe       done_with_count_adjustment
mov       cx, bp
sub       cx, di
done_with_count_adjustment:

;			FAR_memcpy(MK_FP(currentdestsegment, position), source, count);




shr       cx, 1
rep movsw 
adc       cx, cx
rep movsb 




cmp       byte ptr ds:[bx], 0FFh
jne       do_next_column_patch
exit_drawcolumn_in_cache:
mov       ax, ss
mov       ds, ax 

pop       bp
pop       di
pop       si
ret
position_under_zero:
add       cx, di
xor       di, di
jmp       done_with_position_check

ENDP



PROC R_GetNextSpriteBlock_ NEAR
PUBLIC R_GetNextSpriteBlock_

; todo: get size

;	uint16_t size = spritetotaldatasizes[lump-firstspritelump];



PUSHA_NO_AX_MACRO
push      bp
mov       bp, sp

push      CACHETYPE_SPRITE ; todo 8086
sub       ax, word ptr ds:[_firstspritelump]
mov       dx, SPRITETOTALDATASIZES_SEGMENT
mov       es, dx
mov       bx, ax
sal       bx, 1
mov       dx, word ptr es:[bx] ; dx = size
mov       bl, dh
push      bx  ; bp - 4  only bl technically
push      NUM_SPRITE_CACHE_PAGES
push      ax  ; bp - 6  store for later
mov       di, OFFSET _spritecache_nodes
mov       si, OFFSET _usedspritepagemem

jmp       get_next_block_variables_ready

ENDP


PROC R_GetNextTextureBlock_ NEAR
PUBLIC R_GetNextTextureBlock_

; bp - 2  cachetype
; bp - 4  blocksize
; bp - 6  NUM_[thing]_PAGES for iter
; bp - 8  tex_index

PUSHA_NO_AX_MACRO
push      bp
mov       bp, sp

push      bx  ; only bl technically   ; cachetype
mov       bl, dh
push      bx  ; only bl technically
push      NUM_TEXTURE_PAGES
push      ax  ; bp - 6  store for later
mov       di, OFFSET _texturecache_nodes
mov       si, OFFSET _usedtexturepagemem

get_next_block_variables_ready:
xchg      ax, bx


;	if (size & 0xFF) {
;		blocksize++;
;	}

test      dl, 0FFh
je        dont_increment_blocksize
inc       al
mov       byte ptr [bp - 4], al
dont_increment_blocksize:
;	numpages = blocksize >> 6; // num EMS pages needed

xor       ah, ah
SHIFT_MACRO rol       al 2
and       al, 3

;	if (blocksize & 0x3F) {
;		numpages++;
;	}

mov       ch, al
test      byte ptr [bp - 4], 03Fh
je        dont_increment_numpages
inc       ch
dont_increment_numpages:

;	if (numpages == 1) {

xor       bx, bx
cmp       ch, 1
jne       multipage_textureblock
;		uint8_t freethreshold = 64 - blocksize;
mov       dh, 040h   ;todo
sub       dh, byte ptr [bp - 4]
xor       dl, dl

;		for (i = 0; i < NUM_TEXTURE_PAGES; i++) {
;			if (freethreshold >= usedtexturepagemem[i]) {
;				goto foundonepage;
;			}
;		}

check_next_texture_page_for_space:
mov       bl, dl
cmp       dh, byte ptr ds:[bx + si]
jnb       foundonepage

;		i = R_EvictL2CacheEMSPage(1, cachetype);

inc       dl
cmp       dl, [bp - 6]
jl        check_next_texture_page_for_space
mov       al, byte ptr [bp - 2]
cbw      
mov       dx, ax
mov       al, 1
call      R_EvictL2CacheEMSPage_
mov       dl, al

foundonepage:

;		texpage = i << 2;
;		texoffset = usedtexturepagemem[i];
;		usedtexturepagemem[i] += blocksize;

mov       dh, dl
SHIFT_MACRO shl       dh 2
mov       bl, dl
mov       al, byte ptr [bx + si]
mov       ah, byte ptr [bp - 4]
add       ah, al
mov       byte ptr ds:[bx + si], ah

done_finding_open_page:
pop       si ; was bp - 6
cmp       byte ptr [bp - 2], CACHETYPE_PATCH
jne       set_non_patch_pages
set_patch_pages:
mov       bx, PATCHOFFSET_SEGMENT
mov       es, bx
mov       byte ptr es:[si], dh
mov       byte ptr es:[si + PATCHOFFSET_OFFSET], al
LEAVE_MACRO     
POPA_NO_AX_MACRO
ret       
set_non_patch_pages:
jb        set_sprite_pages
set_tex_pages:
mov       bx, COMPOSITETEXTUREOFFSET_SEGMENT
mov       es, bx
mov       byte ptr es:[si], dh
mov       byte ptr es:[si + COMPOSITETEXTUREOFFSET_OFFSET], al
LEAVE_MACRO     
POPA_NO_AX_MACRO
ret       
set_sprite_pages:
mov       bx, SPRITEPAGE_SEGMENT
mov       es, bx
mov       byte ptr es:[si], dh
mov       byte ptr es:[si + SPRITEOFFSETS_OFFSET], al
LEAVE_MACRO     
POPA_NO_AX_MACRO
ret       


multipage_textureblock:

;		uint8_t numpagesminus1 = numpages - 1;

mov       dh, byte ptr ds:[_texturecache_l2_head]
mov       ah, 0FFh
mov       cl, 040h
; al is free, in use a lot
; ah is 0FFh
; bh is 000h
; bl is active offset
; ch is numpages
; cl is 040h
; dh is head
; dl is nextpage


;		for (i = texturecache_l2_head;
;				i != -1; 
;				i = texturecache_nodes[i].prev
;				) {
;			if (!usedtexturepagemem[i]) {
;				// need to check following pages for emptiness, or else after evictions weird stuff can happen
;				int8_t nextpage = texturecache_nodes[i].prev;
;				if ((nextpage != -1 &&!usedtexturepagemem[nextpage])) {
;					nextpage = texturecache_nodes[nextpage].prev;

;				}
;			}
;		}

cmp       dh, ah  ; dh is texturecache_l2_head
je        done_with_textureblock_multipage_loop

do_texture_multipage_loop:
mov       bl, dh
cmp       byte ptr ds:[bx + si], bh
jne       do_next_texture_multipage_loop_iter

page_has_space:
SHIFT_MACRO shl       bl 2
mov       al, byte ptr ds:[bx + di]
cmp       al, ah
je        do_next_texture_multipage_loop_iter
; has next page
mov       bl, al
cmp       byte ptr ds:[bx + si], bh
jne       do_next_texture_multipage_loop_iter
SHIFT_MACRO shl       bl 2
mov       dl, byte ptr ds:[bx + di]

;					if (numpagesminus1 < 2 || (nextpage != -1 && (!usedtexturepagemem[nextpage]))) {


cmp       ch, 3   ; use numpages instead of numpagesminus1
jb        less_than_2_pages_or_next_page_good
not_less_than_2_pages_check_next_page_good:
cmp       dl, ah
je        do_next_texture_multipage_loop_iter
mov       bl, dl
cmp       byte ptr ds:[bx + si], bh
jne       do_next_texture_multipage_loop_iter

less_than_2_pages_or_next_page_good:

;						nextpage = texturecache_nodes[nextpage].prev;

mov       bl, dl
SHIFT_MACRO shl       bl 2
mov       dl, byte ptr ds:[bx + di]

;						if (numpagesminus1 < 3 || (nextpage != -1 &&(!usedtexturepagemem[nextpage]))) {
;							goto foundmultipage;
;						}

cmp       ch, 4  ; use numpages instead of numpagesminus1
jb        found_multipage


check_for_next_multipage_loop_iter:

; (nextpage != -1 &&(!usedtexturepagemem[nextpage])
cmp       dl, ah
je        do_next_texture_multipage_loop_iter
mov       bl, dl
cmp       byte ptr ds:[bx + si], bh
jne       do_next_texture_multipage_loop_iter

do_next_texture_multipage_loop_iter:
mov       bl, dh
SHIFT_MACRO shl       bl 2
mov       dh, byte ptr ds:[bx + di]
cmp       dh, ah
jne       do_texture_multipage_loop

done_with_textureblock_multipage_loop:

;		i = R_EvictL2CacheEMSPage(numpages, cachetype);

mov       al, byte ptr [bp - 2]
cbw      
mov       dx, ax
mov       al, ch
call      R_EvictL2CacheEMSPage_
mov       dh, al

less_than_3_pages_or_next_page_good:
found_multipage:
;		foundmultipage:
;        usedtexturepagemem[i] = 64;

mov       bl, dh
mov       byte ptr ds:[bx + si], cl

;		texturecache_nodes[i].numpages = numpages;
;		texturecache_nodes[i].pagecount = numpages;

SHIFT_MACRO shl       bl 2
mov       byte ptr ds:[bx + di + 3], ch
mov       byte ptr ds:[bx + di + 2], ch
mov       dl, dh
;		if (numpages >= 3) {
cmp       ch, 3
jl        numpages_not_3_or_more
mov       dl, byte ptr ds:[bx + di]
mov       bl, dl
mov       al, ch
dec       al
mov       byte ptr ds:[bx + si], cl
SHIFT_MACRO shl       bl 2
mov       byte ptr ds:[bx + di + 3], ch
mov       byte ptr ds:[bx + di + 2], al
numpages_not_3_or_more:
mov       bl, dl
SHIFT_MACRO shl       bl 2
mov       al, byte ptr ds:[bx + di]
mov       bl, al
SHIFT_MACRO shl       bl 2

;		texturecache_nodes[j].numpages = numpages;
;		texturecache_nodes[j].pagecount = 1;

mov       byte ptr ds:[bx + di + 2], 1
mov       byte ptr ds:[bx + di + 3], ch
mov       bl, al

mov       al, byte ptr [bp - 4]

;	if (blocksize & 0x3F) {

test      al, 03Fh
jne        dont_set_used_all_memory_for_page
;			usedtexturepagemem[j] = blocksize & 0x3F;
set_used_all_memory_for_page:

;			usedtexturepagemem[j] = 64;


;		texpage = (i << 2) + (numpagesminus1);
;		texoffset = 0; // if multipage then its always aligned to start of its block


mov       byte ptr ds:[bx + si], cl
SHIFT_MACRO shl       dh 2
xor       al, al
add       dh, ch  ; use numpages instead of numpagesminus1
dec       dh 
jmp       done_finding_open_page
dont_set_used_all_memory_for_page:
and       al, 03Fh
mov       byte ptr ds:[bx + si], al

;		texpage = (i << 2) + (numpagesminus1);
;		texoffset = 0; // if multipage then its always aligned to start of its block

SHIFT_MACRO shl       dh 2
xor       al, al
add       dh, ch    ; use numpages instead of numpagesminus1. need the dec
dec       dh
jmp       done_finding_open_page



ENDP



spritepage_data:

; todo modify on outisde
PROC R_GetSpritePage2_ NEAR
PUBLIC R_GetSpritePage2_

PUSHA_NO_AX_MACRO
push  bp
mov   bp, sp

IF COMPILE_INSTRUCTIONSET GE COMPILE_186
    push  OFFSET R_MarkL1SpriteCacheMRU_
    push  OFFSET R_MarkL2SpriteCacheMRU_
    push  OFFSET Z_QuickMapSpritePage_
    push  OFFSET R_MarkL1SpriteCacheMRU3_
ELSE
    mov   si, OFFSET R_MarkL1SpriteCacheMRU_
    push  si
    mov   si, OFFSET R_MarkL2SpriteCacheMRU_
    push  si
    mov   si, OFFSET Z_QuickMapSpritePage_
    push  si
    mov   si, OFFSET R_MarkL1SpriteCacheMRU3_
    push  si

ENDIF
mov   dx, 0 ; pageoffset 0
mov   si, OFFSET _activespritepages
mov   di, OFFSET _activespritenumpages
mov   cx, NUM_SPRITE_L1_CACHE_PAGES
jmp continue_get_page

ENDP


; part of R_GetTexturePage_

found_active_single_page:

;    R_MarkL1TextureCacheMRU(i);
; bl holds i * 2 (word offset)
; al holds realtexpage

shr   bx, 1
xchg  ax, dx            ; dx gets realtexpage
mov   ax, bx            ; ax gets i
call  word ptr [bp - 2]

;    R_MarkL2CompositeTextureCacheMRU(realtexpage);

xchg  ax, dx            ; realtexpage
call  word ptr [bp - 4]

;    return i;

mov   es, bx
LEAVE_MACRO 
POPA_NO_AX_MACRO
mov   ax, es
ret   



PROC R_GetTexturePage_ NEAR
PUBLIC R_GetTexturePage_
;uint8_t __near R_GetTexturePage(uint8_t texpage, uint8_t pageoffset){
; al texpage
; dl pageoffset


; bp - 2 markcachel1mru
; bp - 4 markl2cache
; bp - 6 z_quickmap
; bp - 8 markcachel1mru(max)
; bp - 0Ah NUM_TEXTURE_L1_CACHE_PAGES or NUM_SPRITE_L1_CACHE_PAGES
; bp - 0Ch pageoffset
; bp - 0Eh realtexpage
; bp - 10h startpage in multi-area

PUSHA_NO_AX_MACRO
push  bp
mov   bp, sp
IF COMPILE_INSTRUCTIONSET GE COMPILE_186
    push  OFFSET R_MarkL1TextureCacheMRU_
    push  OFFSET R_MarkL2CompositeTextureCacheMRU_
    push  OFFSET Z_QuickMapRenderTexture_
    push  OFFSET R_MarkL1TextureCacheMRU7_
ELSE
    mov   si, OFFSET R_MarkL1TextureCacheMRU_
    push  si
    mov   si, OFFSET R_MarkL2CompositeTextureCacheMRU_
    push  si
    mov   si, OFFSET Z_QuickMapRenderTexture_
    push  si
    mov   si, OFFSET R_MarkL1TextureCacheMRU7_
    push  si

ENDIF

mov   si, OFFSET _activetexturepages
mov   di, OFFSET _activenumpages
mov   cx, NUM_TEXTURE_L1_CACHE_PAGES
continue_get_page:

push  cx        ; bp - 0Ah
xor   dh, dh
push  dx        ; bp - 0Ch   dh 0 
xor   ah, ah    ; feels gross, clean up. need in multipage
;	uint8_t realtexpage = texpage >> 2;
mov   dx, ax
SHIFT_MACRO sar   dx 2
push  dx        ; bp - 0Eh   dh 0

;	uint8_t numpages = (texpage& 0x03);


xchg  ax, dx   ; ax has realtexpage
and   dl, 3
;	if (!numpages) {
jne   get_multipage

;		// one page, most common case - lets write faster code here...
;		for (i = 0; i < NUM_TEXTURE_L1_CACHE_PAGES; i++) {
;			if (activetexturepages[i] == realtexpage ) {
;				R_MarkL1TextureCacheMRU(i);
;				R_MarkL2CompositeTextureCacheMRU(realtexpage);
;				return i;
;			}
;		}
;     dl known zero..

xor   bx, bx
mov   dx, cx ; loop compare, shifted once since we double inc bx
shl   dx, 1

; dl is i??
; al is realtexpage
; bx is i

loop_next_active_page_single:
cmp   ax, word ptr ds:[bx + si]
je    found_active_single_page
inc   bx
inc   bx  ; todo remove once si is byte not word..
cmp   bx, dx
jb    loop_next_active_page_single

; cache miss...

;		startpage = textureL1LRU[NUM_TEXTURE_L1_CACHE_PAGES-1];
;		R_MarkL1TextureCacheMRU7(startpage);

xor   ax, ax
cwd
dec   dx ; dx = -1, ah is 0
mov   bx, cx
dec   bx        ; NUM_TEXTURE_L1_CACHE_PAGES - 1
mov   al, byte ptr ds:[_textureL1LRU + bx]   ; textureL1LRU[NUM_TEXTURE_L1_CACHE_PAGES-1]
mov   bx, ax
mov   cx, ax
call  word ptr [bp - 8]

;		// if the deallocated page was a multipage allocation then we want to invalidate the other pages.
;		if (activenumpages[startpage]) {
;			for (i = 1; i <= activenumpages[startpage]; i++) {
;				activetexturepages[startpage+i]  = -1; // unpaged
;				//this is unmapping the page, so we don't need to use pagenum/nodelist
;				pageswapargs[pageswapargs_rend_texture_offset+( startpage+i)*PAGE_SWAP_ARG_MULT] = 
;					_NPR(PAGE_5000_OFFSET+startpage+i);
;				activenumpages[startpage+i] = 0;
;			}
;		}

cmp   byte ptr ds:[bx + di], 0
je    found_start_page_single

mov   ax, 1 ; al/ax is i
; cl/cx is start page.
; bx is start page or startpage + i offset
; dx is ??
; 
deallocate_next_startpage_single:

cmp   al, byte ptr ds:[bx + di]
ja    found_start_page_single

add   bx, ax
mov   byte ptr ds:[bx + di], dh
sal   bx, 1
mov   word ptr ds:[bx + si], dx   ; dx is -1

inc   al
shl   bx, 1   ; todo optional put in block

; BIG TODO FOR THESE: shift or not based on build?
SET_PAGESWAP_ARGS bx PAGESWAPARGS_REND_TEXTURE_OFFSET dx  ; dx is -1
mov   bx, cx
jmp   deallocate_next_startpage_single

get_multipage:

; ah already zero

mov   bx, ax ; zero bh
; cx already the number
sub   cx, dx
;  al/ax already realtexpage

; dl is numpages
; cl is NUM_TEXTURE_L1_CACHE_PAGES-numpages
; ch is 0
; dh will be i (starts as 0)
; for (i = 0; i < NUM_TEXTURE_L1_CACHE_PAGES-numpages; i++) {
; al is realtexpage


dec   dh  ; offset once

grab_next_page_loop_multi_continue:

inc   dh  ; 0 for 1st iteration after dec

cmp   dh, cl ; loop compare

jnl   evict_and_find_startpage_multi

;    if (activetexturepages[i] != realtexpage){
;        continue;
;    }

mov   bl, dh
sal   bx, 1
cmp   ax, word ptr ds:[bx + si]
jne   grab_next_page_loop_multi_continue

mov   bl, dh

;    // all pages for this texture are in the cache, unevicted.
;    for (j = 0; j <= numpages; j++) {
;        R_MarkL1TextureCacheMRU(i+j);
;    }

; dh is i
; bl/bx will be i+j   
; dl is numpages but we dec it till < 0

mark_all_pages_mru_loop:
mov   ax, bx

call  word ptr [bp - 2]
inc   bl
dec   dl
jns   mark_all_pages_mru_loop
 


;    R_MarkL2CompositeTextureCacheMRU(realtexpage);
;    return i;

pop   ax;   word ptr [bp - 0Eh]
call  word ptr [bp - 4]  ; R_MarkL2CompositeTextureCacheMRU_
mov   al, dh
mov   es, ax
LEAVE_MACRO 
POPA_NO_AX_MACRO
mov   ax, es
ret   
 


;		// figure out startpage based on LRU
;		startpage = NUM_TEXTURE_L1_CACHE_PAGES-1; // num EMS pages in conventional memory - 1

evict_and_find_startpage_multi:
xor   ax, ax ; set ah to 0. todo necessary?
mov   bx, word ptr [bp - 0Ah]
dec   bx
mov   cx, bx
sub   cl, dl
; dl is numpages
; bx is startpage
; cx is ((NUM_TEXTURE_L1_CACHE_PAGES-1)-numpages)

find_start_page_loop_multi:

;		while (textureL1LRU[startpage] > ((NUM_TEXTURE_L1_CACHE_PAGES-1)-numpages)){
;			startpage--;
;		}

mov   al, byte ptr ds:[bx + _textureL1LRU]
cmp   al, cl
jle   found_startpage_multi
dec   bx
jmp   find_start_page_loop_multi

found_start_page_single:

;		activetexturepages[startpage] = realtexpage; // FIRST_TEXTURE_LOGICAL_PAGE + pagenum;		
;  cl/cx is startpage
;  bl/bx is startpage 

pop   dx  ; bp - 0Eh, get realtexpage
; dx has realtexpage
; bx already ok

mov   byte ptr ds:[bx + di], bh  ; zero
shl   bx, 1
mov   word ptr ds:[bx + si], dx
pop   ax  ; mov   ax, word ptr [bp - 0Ch]
shl   bx, 1    ; TODO optional thing
add   ax, dx

; BIG TODO FOR THESE: shift or not based on build?
; mov word ptr ds:[ _pageswapargs + $register + $offset], $value
SET_PAGESWAP_ARGS bx PAGESWAPARGS_REND_TEXTURE_OFFSET ax

; dx should be realtexpage???
xchg  ax, dx

call  word ptr [bp - 4]  ; R_MarkL2CompositeTextureCacheMRU_
call  word ptr [bp - 6]  ; Z_QuickMapRenderTexture_
mov   ax, 0FFFFh
; todo put these next to each other and stosw?
mov   word ptr ds:[_cachedtex], ax
mov   word ptr ds:[_cachedtex2], ax
push  ds
pop   es
mov   di, OFFSET _cachedlumps
stosw
stosw
stosw
stosw

mov   es, cx ; cl/cx is start page
LEAVE_MACRO 
POPA_NO_AX_MACRO
mov   ax, es
ret

found_startpage_multi:
;		startpage = textureL1LRU[startpage];

;mov   al, byte ptr ds:[bx + _textureL1LRU]
; al already set to startpage
mov   bl, al
push  ax  ; bp - 10h
mov   dh, al ; dh gets startpage..
mov   cx, -1

;		// if the deallocated page was a multipage allocation then we want to invalidate the other pages.
;		if (activenumpages[startpage] > numpages) {
;			for (i = numpages; i <= activenumpages[startpage]; i++) {
;				activetexturepages[startpage + i] = -1;
;				// unmapping the page, so we dont need pagenum
;				pageswapargs[pageswapargs_rend_texture_offset+(startpage + i)*PAGE_SWAP_ARG_MULT] 
;					= _NPR(PAGE_5000_OFFSET+startpage+i); // unpaged
;				activenumpages[startpage + i] = 0;
;			}
;		}


cmp   dl, byte ptr ds:[bx + di]
jae   done_invalidating_pages_multi
mov   al, dl

; dl is numpages
; dh is startpage
; al is i
; bx is startpage lookup

loop_next_invalidate_page_multi:
mov   bl, dh   ; set bl to startpage

cmp   al, byte ptr ds:[bx + di]
ja    done_invalidating_pages_multi

add   bx, ax                     ; startpage + i
mov   byte ptr ds:[bx + di], ah  ; ah is 0
sal   bx, 1
mov   word ptr ds:[bx + si], cx  ; -1
inc   al
shl   bx, 1    ; todo optional


; todo cx is _NPR(PAGE_5000_OFFSET+startpage+i);
SET_PAGESWAP_ARGS bx PAGESWAPARGS_REND_TEXTURE_OFFSET cx ; -1
xor   bh, bh
jmp   loop_next_invalidate_page_multi


done_invalidating_pages_multi:

;	int8_t currentpage = realtexpage; // pagenum - pageoffset
;	for (i = 0; i <= numpages; i++) {

mov   cl, dh  ; startpage
xor   dh, dh
mov   ch, dl

; ch is numpages - i
; cl has startpage + i
; bl has currentpage, swaps with ax for preservation
; dl still has numpages
; dh has i
;	for (i = 0; i <= numpages; i++) {
; es gets currentpage
mov   es, word ptr [bp - 0Eh]

loop_mark_next_page_mru_multi:

;	R_MarkL1TextureCacheMRU(startpage+i);

mov   al, cl

call  [bp - 2]

;	activetexturepages[startpage + i]  = currentpage;
;   activenumpages[startpage + i] = numpages-i;

mov   ax, es ; currentpage in ax

mov   bl, cl
mov   byte ptr ds:[bx + di], ch
sal   bx, 1             ; word lookup
mov   word ptr ds:[bx + si], ax  
add   ax, word ptr [bp - 0Ch]  ; pageoffset

;	pageswapargs[pageswapargs_rend_texture_offset+(startpage + i)*PAGE_SWAP_ARG_MULT]  = _EPR(currentpage+pageoffset);




shl   bx, 1 ; todo optional?

; bh is very likely nonzero here. ES resets it later..

; currentpage+pageoffset
SET_PAGESWAP_ARGS bx PAGESWAPARGS_REND_TEXTURE_OFFSET ax

dec   ch    ; dec numpages - i
inc   cl    ; inc i
inc   dh

;    currentpage = texturecache_nodes[currentpage].prev;
mov   bx, es ; currentpage
mov   bl, byte ptr ds:[bx + di]
mov   es, bx
cmp   dh, dl
jbe   loop_mark_next_page_mru_multi




;    R_MarkL2CompositeTextureCacheMRU(realtexpage);
;    Z_QuickMapRenderTexture();

		

mov   ax, word ptr [bp - 0Eh]
call  word ptr [bp - 4]  ; R_MarkL2CompositeTextureCacheMRU_
call  word ptr [bp - 6]  ; Z_QuickMapRenderTexture_

;	//todo: only -1 if its in the knocked out page? pretty infrequent though.
;    cachedtex = -1;
;    cachedtex2 = -1;

mov   di, OFFSET _cachedlumps
mov   ax, ds
mov   es, ax

mov   ax, 0FFFFh
mov   word ptr ds:[_maskednextlookup], NULL_TEX_COL
mov   word ptr ds:[_cachedtex], ax
mov   word ptr ds:[_cachedtex2], ax

;    cachedlumps[0] = -1;
;    cachedlumps[1] = -1;
;    cachedlumps[2] = -1;
;    cachedlumps[3] = -1;
   
;    segloopnextlookup[0] = -1;
;    segloopnextlookup[1] = -1;
;    seglooptexrepeat[0] = 0;
;    seglooptexrepeat[1] = 0;

stosw
stosw
stosw
stosw
mov   word ptr ds:[_segloopnextlookup+0], ax ; todo put this all adjacent..
mov   word ptr ds:[_segloopnextlookup+2], ax
inc   ax    ; ax is 0
mov   word ptr ds:[_maskedtexrepeat], ax
mov   word ptr ds:[_seglooptexrepeat+0], ax ; word gets both..

pop   es ;  [bp - 010h]
LEAVE_MACRO 
POPA_NO_AX_MACRO
mov   ax, es
ret   

ENDP

COMMENT @


PROC R_GetSpritePage_ NEAR
PUBLIC R_GetSpritePage_


0x0000000000000224:  53                   push  bx
0x0000000000000225:  51                   push  cx
0x0000000000000226:  52                   push  dx
0x0000000000000227:  56                   push  si
0x0000000000000228:  57                   push  di
0x0000000000000229:  55                   push  bp
0x000000000000022a:  89 E5                mov   bp, sp
0x000000000000022c:  83 EC 06             sub   sp, 6
0x000000000000022f:  88 C2                mov   dl, al
0x0000000000000231:  30 F6                xor   dh, dh
0x0000000000000233:  C1 FA 02             sar   dx, 2
0x0000000000000236:  88 56 FC             mov   byte ptr [bp - 4], dl
0x0000000000000239:  88 C2                mov   dl, al
0x000000000000023b:  80 E2 03             and   dl, 3
0x000000000000023e:  75 5C                jne   0x29c
0x0000000000000240:  88 D0                mov   al, dl
0x0000000000000242:  30 E4                xor   ah, ah
0x0000000000000244:  89 C3                mov   bx, ax
0x0000000000000246:  01 C3                add   bx, ax
0x0000000000000248:  8A 46 FC             mov   al, byte ptr [bp - 4]
0x000000000000024b:  3B 87 28 1C          cmp   ax, word ptr ds:[bx + _activespritepages]
0x000000000000024f:  74 4D                je    0x29e
0x0000000000000251:  FE C2                inc   dl
0x0000000000000253:  80 FA 04             cmp   dl, 4
0x0000000000000256:  72 E8                jb    0x240
0x0000000000000258:  8A 0E 47 1E          mov   cl, byte ptr [0x1e47]
0x000000000000025c:  88 C8                mov   al, cl
0x000000000000025e:  88 CB                mov   bl, cl
0x0000000000000260:  98                   cbw  
0x0000000000000261:  30 FF                xor   bh, bh
0x0000000000000263:  E8 E8 0B             call  0xe4e
0x0000000000000266:  80 BF 48 1E 00       cmp   byte ptr ds:[bx + _activespritenumpages], 0
0x000000000000026b:  74 47                je    0x2b4
0x000000000000026d:  B0 01                mov   al, 1
0x000000000000026f:  88 CB                mov   bl, cl
0x0000000000000271:  30 FF                xor   bh, bh
0x0000000000000273:  3A 87 48 1E          cmp   al, byte ptr ds:[bx + _activespritenumpages]
0x0000000000000277:  77 3B                ja    0x2b4
0x0000000000000279:  88 C2                mov   dl, al
0x000000000000027b:  30 F6                xor   dh, dh
0x000000000000027d:  01 D3                add   bx, dx
0x000000000000027f:  89 DE                mov   si, bx
0x0000000000000281:  01 DE                add   si, bx
0x0000000000000283:  C7 84 28 1C FF FF    mov   word ptr ds:[si + _activespritepages], 0FFFFh
0x0000000000000289:  89 DE                mov   si, bx
0x000000000000028b:  FE C0                inc   al
0x000000000000028d:  C1 E6 02             shl   si, 2
0x0000000000000290:  88 B7 48 1E          mov   byte ptr ds:[bx + _activespritenumpages], dh

SET_PAGESWAP_ARGS si PAGESWAPARGS_SPRITECACHE_OFFSET 0FFFFh

0x0000000000000294:  C7 84 62 0B FF FF    mov   word ptr [si + 0xb62], 0FFFFh
0x000000000000029a:  EB D3                jmp   0x26f
0x000000000000029c:  EB 53                jmp   0x2f1
0x000000000000029e:  88 D0                mov   al, dl
0x00000000000002a0:  98                   cbw  
0x00000000000002a1:  E8 8A 0B             call  0xe2e
0x00000000000002a4:  8A 46 FC             mov   al, byte ptr [bp - 4]
0x00000000000002a7:  98                   cbw  
0x00000000000002a8:  E8 28 0C             call  0xed3
0x00000000000002ab:  88 D0                mov   al, dl
0x00000000000002ad:  C9                   LEAVE_MACRO 
0x00000000000002ae:  5F                   pop   di
0x00000000000002af:  5E                   pop   si
0x00000000000002b0:  5A                   pop   dx
0x00000000000002b1:  59                   pop   cx
0x00000000000002b2:  5B                   pop   bx
0x00000000000002b3:  C3                   ret   
0x00000000000002b4:  88 CB                mov   bl, cl
0x00000000000002b6:  8A 46 FC             mov   al, byte ptr [bp - 4]
0x00000000000002b9:  30 FF                xor   bh, bh
0x00000000000002bb:  30 E4                xor   ah, ah
0x00000000000002bd:  89 DE                mov   si, bx
0x00000000000002bf:  88 BF 48 1E          mov   byte ptr ds:[bx + _activespritenumpages], bh
0x00000000000002c3:  01 DE                add   si, bx
0x00000000000002c5:  C1 E3 02             shl   bx, 2
0x00000000000002c8:  89 84 28 1C          mov   word ptr ds:[si + _activespritepages], ax
0x00000000000002cc:  05 46 00             add   ax, 0x46

SET_PAGESWAP_ARGS bx PAGESWAPARGS_SPRITECACHE_OFFSET ax

0x00000000000002cf:  89 87 62 0B          mov   word ptr [bx + 0xb62], ax
0x00000000000002d3:  0E                   push  cs
0x00000000000002d4:  3E E8 A0 46          call  0x4978
0x00000000000002d8:  8A 46 FC             mov   al, byte ptr [bp - 4]
0x00000000000002db:  98                   cbw  
0x00000000000002dc:  BB C8 02             mov   bx, 0x2c8
0x00000000000002df:  E8 F1 0B             call  0xed3
0x00000000000002e2:  C7 07 FF FF          mov   word ptr [bx], 0FFFFh
0x00000000000002e6:  BB CA 02             mov   bx, 0x2ca
0x00000000000002e9:  88 C8                mov   al, cl
0x00000000000002eb:  C7 07 FF FF          mov   word ptr [bx], 0FFFFh
0x00000000000002ef:  EB BC                jmp   0x2ad
0x00000000000002f1:  30 DB                xor   bl, bl
0x00000000000002f3:  88 D0                mov   al, dl
0x00000000000002f5:  B9 04 00             mov   cx, 4
0x00000000000002f8:  30 E4                xor   ah, ah
0x00000000000002fa:  29 C1                sub   cx, ax
0x00000000000002fc:  88 D8                mov   al, bl
0x00000000000002fe:  39 C8                cmp   ax, cx
0x0000000000000300:  7C 1D                jl    0x31f
0x0000000000000302:  B6 03                mov   dh, 3
0x0000000000000304:  88 F3                mov   bl, dh
0x0000000000000306:  30 FF                xor   bh, bh
0x0000000000000308:  8A 87 44 1E          mov   al, byte ptr [bx + 0x1e44]
0x000000000000030c:  30 E4                xor   ah, ah
0x000000000000030e:  BE 03 00             mov   si, 3
0x0000000000000311:  89 C1                mov   cx, ax
0x0000000000000313:  88 D0                mov   al, dl
0x0000000000000315:  29 C6                sub   si, ax
0x0000000000000317:  39 F1                cmp   cx, si
0x0000000000000319:  7E 45                jle   0x360
0x000000000000031b:  FE CE                dec   dh
0x000000000000031d:  EB E5                jmp   0x304
0x000000000000031f:  89 C6                mov   si, ax
0x0000000000000321:  01 C6                add   si, ax
0x0000000000000323:  8A 46 FC             mov   al, byte ptr [bp - 4]
0x0000000000000326:  3B 84 28 1C          cmp   ax, word ptr ds:[si + _activespritepages]
0x000000000000032a:  74 04                je    0x330
0x000000000000032c:  FE C3                inc   bl
0x000000000000032e:  EB C3                jmp   0x2f3
0x0000000000000330:  30 C0                xor   al, al
0x0000000000000332:  89 46 FA             mov   word ptr [bp - 6], ax
0x0000000000000335:  8A 76 FA             mov   dh, byte ptr [bp - 6]
0x0000000000000338:  00 DE                add   dh, bl
0x000000000000033a:  88 D0                mov   al, dl
0x000000000000033c:  30 E4                xor   ah, ah
0x000000000000033e:  3B 46 FA             cmp   ax, word ptr [bp - 6]
0x0000000000000341:  7C 0D                jl    0x350
0x0000000000000343:  88 F0                mov   al, dh
0x0000000000000345:  98                   cbw  
0x0000000000000346:  FF 46 FA             inc   word ptr [bp - 6]
0x0000000000000349:  E8 E2 0A             call  0xe2e
0x000000000000034c:  FE C6                inc   dh
0x000000000000034e:  EB EA                jmp   0x33a
0x0000000000000350:  8A 46 FC             mov   al, byte ptr [bp - 4]
0x0000000000000353:  98                   cbw  
0x0000000000000354:  E8 7C 0B             call  0xed3
0x0000000000000357:  88 D8                mov   al, bl
0x0000000000000359:  C9                   LEAVE_MACRO 
0x000000000000035a:  5F                   pop   di
0x000000000000035b:  5E                   pop   si
0x000000000000035c:  5A                   pop   dx
0x000000000000035d:  59                   pop   cx
0x000000000000035e:  5B                   pop   bx
0x000000000000035f:  C3                   ret   
0x0000000000000360:  88 C8                mov   al, cl
0x0000000000000362:  88 C3                mov   bl, al
0x0000000000000364:  88 46 FE             mov   byte ptr [bp - 2], al
0x0000000000000367:  3A 97 48 1E          cmp   dl, byte ptr ds:[bx + _activespritenumpages]
0x000000000000036b:  73 31                jae   0x39e
0x000000000000036d:  88 D0                mov   al, dl
0x000000000000036f:  8A 5E FE             mov   bl, byte ptr [bp - 2]
0x0000000000000372:  30 FF                xor   bh, bh
0x0000000000000374:  89 DE                mov   si, bx
0x0000000000000376:  3A 87 48 1E          cmp   al, byte ptr ds:[bx + _activespritenumpages]
0x000000000000037a:  77 22                ja    0x39e
0x000000000000037c:  88 C3                mov   bl, al
0x000000000000037e:  01 F3                add   bx, si
0x0000000000000380:  89 DE                mov   si, bx
0x0000000000000382:  01 DE                add   si, bx
0x0000000000000384:  C7 84 28 1C FF FF    mov   word ptr ds:[si + _activespritepages], 0FFFFh
0x000000000000038a:  89 DE                mov   si, bx
0x000000000000038c:  FE C0                inc   al
0x000000000000038e:  C1 E6 02             shl   si, 2
0x0000000000000391:  C6 87 48 1E 00       mov   byte ptr ds:[bx + _activespritenumpages], 0

SET_PAGESWAP_ARGS si PAGESWAPARGS_SPRITECACHE_OFFSET 0FFFFh

0x0000000000000396:  C7 84 62 0B FF FF    mov   word ptr [si + 0xb62], 0FFFFh
0x000000000000039c:  EB D1                jmp   0x36f
0x000000000000039e:  30 F6                xor   dh, dh
0x00000000000003a0:  8A 5E FC             mov   bl, byte ptr [bp - 4]
0x00000000000003a3:  88 D5                mov   ch, dl
0x00000000000003a5:  8A 4E FE             mov   cl, byte ptr [bp - 2]
0x00000000000003a8:  88 C8                mov   al, cl
0x00000000000003aa:  98                   cbw  
0x00000000000003ab:  E8 80 0A             call  0xe2e
0x00000000000003ae:  88 D8                mov   al, bl
0x00000000000003b0:  8A 5E FE             mov   bl, byte ptr [bp - 2]
0x00000000000003b3:  98                   cbw  
0x00000000000003b4:  30 FF                xor   bh, bh
0x00000000000003b6:  89 C7                mov   di, ax
0x00000000000003b8:  89 DE                mov   si, bx
0x00000000000003ba:  88 F3                mov   bl, dh
0x00000000000003bc:  83 C7 46             add   di, 0x46
0x00000000000003bf:  01 F3                add   bx, si
0x00000000000003c1:  FE C6                inc   dh
0x00000000000003c3:  89 DE                mov   si, bx
0x00000000000003c5:  88 AF 48 1E          mov   byte ptr ds:[bx + _activespritenumpages], ch
0x00000000000003c9:  FE CD                dec   ch
0x00000000000003cb:  01 DE                add   si, bx
0x00000000000003cd:  FE C1                inc   cl
0x00000000000003cf:  89 84 28 1C          mov   word ptr ds:[si + _activespritepages], ax
0x00000000000003d3:  89 DE                mov   si, bx
0x00000000000003d5:  89 C3                mov   bx, ax
0x00000000000003d7:  C1 E6 02             shl   si, 2
0x00000000000003da:  C1 E3 02             shl   bx, 2

SET_PAGESWAP_ARGS si PAGESWAPARGS_SPRITECACHE_OFFSET di

0x00000000000003dd:  89 BC 62 0B          mov   word ptr [si + 0xb62], di
0x00000000000003e1:  8A 9F 68 18          mov   bl, byte ptr ds:[bx + _spritecache_nodes]
0x00000000000003e5:  38 D6                cmp   dh, dl
0x00000000000003e7:  76 BF                jbe   0x3a8
0x00000000000003e9:  BB C8 02             mov   bx, 0x2c8
0x00000000000003ec:  C7 07 FF FF          mov   word ptr [bx], 0FFFFh
0x00000000000003f0:  BB CA 02             mov   bx, 0x2ca
0x00000000000003f3:  C7 07 FF FF          mov   word ptr [bx], 0FFFFh
0x00000000000003f7:  0E                   push  cs
0x00000000000003f8:  3E E8 7C 45          call  0x4978
0x00000000000003fc:  8A 46 FC             mov   al, byte ptr [bp - 4]
0x00000000000003ff:  98                   cbw  
0x0000000000000400:  E8 D0 0A             call  0xed3
0x0000000000000403:  8A 46 FE             mov   al, byte ptr [bp - 2]
0x0000000000000406:  C9                   LEAVE_MACRO 
0x0000000000000407:  5F                   pop   di
0x0000000000000408:  5E                   pop   si
0x0000000000000409:  5A                   pop   dx
0x000000000000040a:  59                   pop   cx
0x000000000000040b:  5B                   pop   bx
0x000000000000040c:  C3                   ret   

ENDP


PROC R_GetPatchTexture_ NEAR
PUBLIC R_GetPatchTexture_

0x000000000000040e:  53                   push  bx
0x000000000000040f:  51                   push  cx
0x0000000000000410:  56                   push  si
0x0000000000000411:  55                   push  bp
0x0000000000000412:  89 E5                mov   bp, sp
0x0000000000000414:  83 EC 06             sub   sp, 6
0x0000000000000417:  89 C1                mov   cx, ax
0x0000000000000419:  89 C6                mov   si, ax
0x000000000000041b:  B8 BD 83             mov   ax, 0x83bd
0x000000000000041e:  2B 36 7E 1F          sub   si, word ptr [0x1f7e]
0x0000000000000422:  8E C0                mov   es, ax
0x0000000000000424:  8D 9C DC 01          lea   bx, [si + 0x1dc]
0x0000000000000428:  26 8A 24             mov   ah, byte ptr es:[si]
0x000000000000042b:  26 8A 07             mov   al, byte ptr es:[bx]
0x000000000000042e:  88 46 FC             mov   byte ptr [bp - 4], al
0x0000000000000431:  80 FA FF             cmp   dl, 0xff
0x0000000000000434:  74 6F                je    0x4a5
0x0000000000000436:  B0 01                mov   al, 1
0x0000000000000438:  88 46 FA             mov   byte ptr [bp - 6], al
0x000000000000043b:  80 FC FF             cmp   ah, 0xff
0x000000000000043e:  75 69                jne   0x4a9
0x0000000000000440:  84 C0                test  al, al
0x0000000000000442:  74 67                je    0x4ab
0x0000000000000444:  30 F6                xor   dh, dh
0x0000000000000446:  89 D3                mov   bx, dx
0x0000000000000448:  C1 E3 03             shl   bx, 3
0x000000000000044b:  8B 97 54 02          mov   dx, word ptr [bx + 0x254]
0x000000000000044f:  89 C8                mov   ax, cx
0x0000000000000451:  BB 02 00             mov   bx, 2
0x0000000000000454:  2B 06 7E 1F          sub   ax, word ptr [0x1f7e]
0x0000000000000458:  E8 B6 0D             call  0x1211
0x000000000000045b:  B8 BD 83             mov   ax, 0x83bd
0x000000000000045e:  8E C0                mov   es, ax
0x0000000000000460:  26 8A 04             mov   al, byte ptr es:[si]
0x0000000000000463:  BB 02 00             mov   bx, 2
0x0000000000000466:  26 8A A4 DC 01       mov   ah, byte ptr es:[si + 0x1dc]
0x000000000000046b:  BA 2C 00             mov   dx, 0x2c
0x000000000000046e:  88 66 FE             mov   byte ptr [bp - 2], ah
0x0000000000000471:  30 E4                xor   ah, ah
0x0000000000000473:  E8 8A FB             call  0
0x0000000000000476:  30 E4                xor   ah, ah
0x0000000000000478:  89 C3                mov   bx, ax
0x000000000000047a:  01 C3                add   bx, ax
0x000000000000047c:  81 C6 DC 01          add   si, 0x1dc
0x0000000000000480:  8B B7 8E 07          mov   si, word ptr [bx + 0x78e]
0x0000000000000484:  8A 46 FE             mov   al, byte ptr [bp - 2]
0x0000000000000487:  81 C6 00 50          add   si, 0x5000
0x000000000000048b:  C1 E0 04             shl   ax, 4
0x000000000000048e:  01 C6                add   si, ax
0x0000000000000490:  8A 46 FA             mov   al, byte ptr [bp - 6]
0x0000000000000493:  98                   cbw  
0x0000000000000494:  89 F2                mov   dx, si
0x0000000000000496:  89 C3                mov   bx, ax
0x0000000000000498:  89 C8                mov   ax, cx
0x000000000000049a:  0E                   push  cs
0x000000000000049b:  E8 10 07             call  0xbae
0x000000000000049e:  89 F0                mov   ax, si
0x00000000000004a0:  C9                   LEAVE_MACRO 
0x00000000000004a1:  5E                   pop   si
0x00000000000004a2:  59                   pop   cx
0x00000000000004a3:  5B                   pop   bx
0x00000000000004a4:  C3                   ret   
0x00000000000004a5:  30 C0                xor   al, al
0x00000000000004a7:  EB 8F                jmp   0x438
0x00000000000004a9:  EB 10                jmp   0x4bb
0x00000000000004ab:  89 F0                mov   ax, si
0x00000000000004ad:  01 F0                add   ax, si
0x00000000000004af:  89 C3                mov   bx, ax
0x00000000000004b1:  8B 97 70 F6          mov   dx, word ptr [bx - 0x990]
0x00000000000004b5:  81 C3 70 F6          add   bx, 0xf670
0x00000000000004b9:  EB 94                jmp   0x44f
0x00000000000004bb:  BB 02 00             mov   bx, 2
0x00000000000004be:  88 E0                mov   al, ah
0x00000000000004c0:  BA 2C 00             mov   dx, 0x2c
0x00000000000004c3:  30 E4                xor   ah, ah
0x00000000000004c5:  E8 38 FB             call  0
0x00000000000004c8:  30 E4                xor   ah, ah
0x00000000000004ca:  89 C3                mov   bx, ax
0x00000000000004cc:  01 C3                add   bx, ax
0x00000000000004ce:  8B 97 8E 07          mov   dx, word ptr [bx + 0x78e]
0x00000000000004d2:  8A 46 FC             mov   al, byte ptr [bp - 4]
0x00000000000004d5:  80 C6 50             add   dh, 0x50
0x00000000000004d8:  C1 E0 04             shl   ax, 4
0x00000000000004db:  01 D0                add   ax, dx
0x00000000000004dd:  C9                   LEAVE_MACRO 
0x00000000000004de:  5E                   pop   si
0x00000000000004df:  59                   pop   cx
0x00000000000004e0:  5B                   pop   bx
0x00000000000004e1:  C3                   ret   


ENDP


PROC R_GetCompositeTexture_ NEAR
PUBLIC R_GetCompositeTexture_

0x00000000000004e2:  53                   push  bx
0x00000000000004e3:  51                   push  cx
0x00000000000004e4:  52                   push  dx
0x00000000000004e5:  56                   push  si
0x00000000000004e6:  57                   push  di
0x00000000000004e7:  55                   push  bp
0x00000000000004e8:  89 E5                mov   bp, sp
0x00000000000004ea:  83 EC 04             sub   sp, 4
0x00000000000004ed:  89 C6                mov   si, ax
0x00000000000004ef:  B8 81 4F             mov   ax, 0x4f81
0x00000000000004f2:  8D BC AC 01          lea   di, [si + 0x1ac]
0x00000000000004f6:  8E C0                mov   es, ax
0x00000000000004f8:  89 46 FE             mov   word ptr [bp - 2], ax
0x00000000000004fb:  8C 46 FC             mov   word ptr [bp - 4], es
0x00000000000004fe:  26 8A 04             mov   al, byte ptr es:[si]
0x0000000000000501:  26 8A 0D             mov   cl, byte ptr es:[di]
0x0000000000000504:  3C FF                cmp   al, 0xff
0x0000000000000506:  75 4F                jne   0x557
0x0000000000000508:  B8 4B 4F             mov   ax, 0x4f4b
0x000000000000050b:  89 F3                mov   bx, si
0x000000000000050d:  8E C0                mov   es, ax
0x000000000000050f:  01 DB                add   bx, bx
0x0000000000000511:  89 F0                mov   ax, si
0x0000000000000513:  26 8B 17             mov   dx, word ptr es:[bx]
0x0000000000000516:  BB 03 00             mov   bx, 3
0x0000000000000519:  E8 F5 0C             call  0x1211
0x000000000000051c:  8E 46 FE             mov   es, word ptr [bp - 2]
0x000000000000051f:  BB 03 00             mov   bx, 3
0x0000000000000522:  BA 2C 00             mov   dx, 0x2c
0x0000000000000525:  26 8A 04             mov   al, byte ptr es:[si]
0x0000000000000528:  8E 46 FC             mov   es, word ptr [bp - 4]
0x000000000000052b:  30 E4                xor   ah, ah
0x000000000000052d:  26 8A 0D             mov   cl, byte ptr es:[di]
0x0000000000000530:  E8 CD FA             call  0
0x0000000000000533:  30 E4                xor   ah, ah
0x0000000000000535:  89 C3                mov   bx, ax
0x0000000000000537:  01 C3                add   bx, ax
0x0000000000000539:  8B 9F 8E 07          mov   bx, word ptr [bx + 0x78e]
0x000000000000053d:  88 C8                mov   al, cl
0x000000000000053f:  80 C7 50             add   bh, 0x50
0x0000000000000542:  C1 E0 04             shl   ax, 4
0x0000000000000545:  01 C3                add   bx, ax
0x0000000000000547:  89 DA                mov   dx, bx
0x0000000000000549:  89 F0                mov   ax, si
0x000000000000054b:  E8 74 F8             call  0xfdc2
0x000000000000054e:  89 D8                mov   ax, bx
0x0000000000000550:  C9                   LEAVE_MACRO 
0x0000000000000551:  5F                   pop   di
0x0000000000000552:  5E                   pop   si
0x0000000000000553:  5A                   pop   dx
0x0000000000000554:  59                   pop   cx
0x0000000000000555:  5B                   pop   bx
0x0000000000000556:  CB                   retf  
0x0000000000000557:  BB 03 00             mov   bx, 3
0x000000000000055a:  BA 2C 00             mov   dx, 0x2c
0x000000000000055d:  30 E4                xor   ah, ah
0x000000000000055f:  E8 9E FA             call  0
0x0000000000000562:  30 E4                xor   ah, ah
0x0000000000000564:  89 C3                mov   bx, ax
0x0000000000000566:  01 C3                add   bx, ax
0x0000000000000568:  8B 97 8E 07          mov   dx, word ptr [bx + 0x78e]
0x000000000000056c:  88 C8                mov   al, cl
0x000000000000056e:  80 C6 50             add   dh, 0x50
0x0000000000000571:  C1 E0 04             shl   ax, 4
0x0000000000000574:  01 D0                add   ax, dx
0x0000000000000576:  C9                   LEAVE_MACRO 
0x0000000000000577:  5F                   pop   di
0x0000000000000578:  5E                   pop   si
0x0000000000000579:  5A                   pop   dx
0x000000000000057a:  59                   pop   cx
0x000000000000057b:  5B                   pop   bx
0x000000000000057c:  CB                   retf  

ENDP


PROC R_GetSpriteTexture_ NEAR
PUBLIC R_GetSpriteTexture_

0x000000000000057e:  53                   push  bx
0x000000000000057f:  51                   push  cx
0x0000000000000580:  52                   push  dx
0x0000000000000581:  56                   push  si
0x0000000000000582:  57                   push  di
0x0000000000000583:  89 C3                mov   bx, ax
0x0000000000000585:  BF 83 4E             mov   di, 0x4e83
0x0000000000000588:  BE E6 00             mov   si, 0xe6
0x000000000000058b:  8B 0C                mov   cx, word ptr [si]
0x000000000000058d:  8E C7                mov   es, di
0x000000000000058f:  8D B7 65 05          lea   si, [bx + 0x565]
0x0000000000000593:  01 C1                add   cx, ax
0x0000000000000595:  26 8A 07             mov   al, byte ptr es:[bx]
0x0000000000000598:  26 8A 14             mov   dl, byte ptr es:[si]
0x000000000000059b:  3C FF                cmp   al, 0xff
0x000000000000059d:  75 36                jne   0x5d5
0x000000000000059f:  89 C8                mov   ax, cx
0x00000000000005a1:  E8 49 0C             call  0x11ed
0x00000000000005a4:  8E C7                mov   es, di
0x00000000000005a6:  26 8A 07             mov   al, byte ptr es:[bx]
0x00000000000005a9:  30 E4                xor   ah, ah
0x00000000000005ab:  26 8A 14             mov   dl, byte ptr es:[si]
0x00000000000005ae:  E8 73 FC             call  0x224
0x00000000000005b1:  30 E4                xor   ah, ah
0x00000000000005b3:  89 C3                mov   bx, ax
0x00000000000005b5:  01 C3                add   bx, ax
0x00000000000005b7:  8B 9F 8E 07          mov   bx, word ptr [bx + 0x78e]
0x00000000000005bb:  88 D0                mov   al, dl
0x00000000000005bd:  80 C7 90             add   bh, 0x90
0x00000000000005c0:  C1 E0 04             shl   ax, 4
0x00000000000005c3:  01 C3                add   bx, ax
0x00000000000005c5:  89 DA                mov   dx, bx
0x00000000000005c7:  89 C8                mov   ax, cx
0x00000000000005c9:  0E                   push  cs
0x00000000000005ca:  E8 D3 06             call  0xca0
0x00000000000005cd:  89 D8                mov   ax, bx
0x00000000000005cf:  5F                   pop   di
0x00000000000005d0:  5E                   pop   si
0x00000000000005d1:  5A                   pop   dx
0x00000000000005d2:  59                   pop   cx
0x00000000000005d3:  5B                   pop   bx
0x00000000000005d4:  CB                   retf  
0x00000000000005d5:  30 E4                xor   ah, ah
0x00000000000005d7:  E8 4A FC             call  0x224
0x00000000000005da:  30 E4                xor   ah, ah
0x00000000000005dc:  89 C3                mov   bx, ax
0x00000000000005de:  01 C3                add   bx, ax
0x00000000000005e0:  8B 9F 8E 07          mov   bx, word ptr [bx + 0x78e]
0x00000000000005e4:  88 D0                mov   al, dl
0x00000000000005e6:  80 C7 90             add   bh, 0x90
0x00000000000005e9:  C1 E0 04             shl   ax, 4
0x00000000000005ec:  01 D8                add   ax, bx
0x00000000000005ee:  5F                   pop   di
0x00000000000005ef:  5E                   pop   si
0x00000000000005f0:  5A                   pop   dx
0x00000000000005f1:  59                   pop   cx
0x00000000000005f2:  5B                   pop   bx
0x00000000000005f3:  CB                   retf  

ENDP



PROC R_GetNextTextureBlock_ NEAR
PUBLIC R_GetNextTextureBlock_

ENDP



@

END
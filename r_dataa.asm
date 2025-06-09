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
EXTRN R_GenerateComposite_:NEAR
EXTRN R_LoadSpriteColumns_:FAR  ; todo
EXTRN Z_QuickMapScratch_4000_:FAR ; todo
EXTRN W_CacheLumpNumDirect_:FAR
EXTRN Z_QuickMapRender4000_:FAR

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
EXTRN _firstpatch:WORD
EXTRN _pagesegments:WORD
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
PROC R_MarkL2TextureCacheMRU_ NEAR
PUBLIC R_MarkL2TextureCacheMRU_


cmp  al, byte ptr ds:[_texturecache_l2_head]
jne  dont_early_out_texture
ret

dont_early_out_texture:
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




PROC R_GetSpritePage_ NEAR
PUBLIC R_GetSpritePage_

PUSHA_NO_AX_MACRO
push  bp
mov   bp, sp

IF COMPILE_INSTRUCTIONSET GE COMPILE_186
    push  OFFSET R_MarkL1SpriteCacheMRU_
    push  OFFSET R_MarkL2SpriteCacheMRU_
    push  OFFSET Z_QuickMapSpritePage_
    push  OFFSET R_MarkL1SpriteCacheMRU3_
    push  (OFFSET _pageswapargs) + (PAGESWAPARGS_SPRITECACHE_OFFSET * PAGE_SWAP_ARG_MULT)
    push  OFFSET _spritecache_nodes
    push  OFFSET _spriteL1LRU
ELSE
    mov   si, OFFSET R_MarkL1SpriteCacheMRU_
    push  si
    mov   si, OFFSET R_MarkL2SpriteCacheMRU_
    push  si
    mov   si, OFFSET Z_QuickMapSpritePage_
    push  si
    mov   si, OFFSET R_MarkL1SpriteCacheMRU3_
    push  si
    mov   si, (OFFSET _pageswapargs) + (PAGESWAPARGS_SPRITECACHE_OFFSET * PAGE_SWAP_ARG_MULT)
    push  si
    mov   si, OFFSET _spritecache_nodes
    push  si
    mov   si, OFFSET _spriteL1LRU
    push  si
ENDIF
mov   si, OFFSET _activespritepages
mov   di, OFFSET _activespritenumpages
mov   cx, NUM_SPRITE_L1_CACHE_PAGES
mov   dx, FIRST_SPRITE_CACHE_LOGICAL_PAGE ; pageoffset
jmp continue_get_page

ENDP


; part of R_GetTexturePage_

found_active_single_page:

;    R_MarkL1TextureCacheMRU(i);
; bl holds i * 2 (word offset)
; al holds realtexpage

shr   bx, 1             ; undo word shift
xchg  ax, dx            ; dx gets realtexpage
mov   ax, bx            ; ax gets i
call  word ptr [bp - 2]

;    R_MarkL2TextureCacheMRU(realtexpage);

xchg  ax, dx            ; realtexpage into ax. 
call  word ptr [bp - 4]

;    return i;

mov   es, bx            ; return i
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
; bp - 0Ah pageswapargs offset
; bp - 0Ch cachenodes
; bp - 0Eh l1lru array offset

; bp - 010h NUM_TEXTURE_L1_CACHE_PAGES or NUM_SPRITE_L1_CACHE_PAGES
; bp - 012h pageoffset
; bp - 014h realtexpage
; bp - 016h startpage in multi-area

PUSHA_NO_AX_MACRO
push  bp
mov   bp, sp

IF COMPILE_INSTRUCTIONSET GE COMPILE_186
    push  OFFSET R_MarkL1TextureCacheMRU_
    push  OFFSET R_MarkL2TextureCacheMRU_
    push  OFFSET Z_QuickMapRenderTexture_
    push  OFFSET R_MarkL1TextureCacheMRU7_
    push  (OFFSET _pageswapargs) + (PAGESWAPARGS_REND_TEXTURE_OFFSET * PAGE_SWAP_ARG_MULT)
    push  OFFSET _texturecache_nodes
    push  OFFSET _textureL1LRU
ELSE
    mov   si, OFFSET R_MarkL1TextureCacheMRU_
    push  si
    mov   si, OFFSET R_MarkL2TextureCacheMRU_
    push  si
    mov   si, OFFSET Z_QuickMapRenderTexture_
    push  si
    mov   si, OFFSET R_MarkL1TextureCacheMRU7_
    push  si
    mov   si, (OFFSET _pageswapargs) + (PAGESWAPARGS_REND_TEXTURE_OFFSET * PAGE_SWAP_ARG_MULT)
    push  si
    mov   si, OFFSET _texturecache_nodes
    push  si
    mov   si, OFFSET _textureL1LRU
    push  si

ENDIF

mov   si, OFFSET _activetexturepages
mov   di, OFFSET _activenumpages
mov   cx, NUM_TEXTURE_L1_CACHE_PAGES
xor   dh, dh
continue_get_page:

push  cx        ; bp - 010h         max   (loop counter etc). ch 0
push  dx        ; bp - 012h   dh 0 pageoffset

;	uint8_t realtexpage = texpage >> 2;
mov   dl, al
SHIFT_MACRO sar   dx 2
push  dx        ; bp - 014h   dh 0 realtexpage

;	uint8_t numpages = (texpage& 0x03);


xchg  ax, dx   ; ax has realtexpage
and   dx, 3    ; zero dh here
;	if (!numpages) {                ; todo push less stuff if we get the zero case?
jne   get_multipage

; single page

;		// one page, most common case - lets write faster code here...
;		for (i = 0; i < NUM_TEXTURE_L1_CACHE_PAGES; i++) {
;			if (activetexturepages[i] == realtexpage ) {
;				R_MarkL1TextureCacheMRU(i);
;				R_MarkL2TextureCacheMRU(realtexpage);
;				return i;
;			}
;		}
;     dl/dx known zero because we jumped otherwise.

mov   bx, dx
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

;   ah is 0. al is dirty but gets fixed...
cwd
dec   dx ; dx = -1, ah is 0
mov   bx, cx    ; NUM_TEXTURE_L1_CACHE_PAGES
dec   bx        ; NUM_TEXTURE_L1_CACHE_PAGES - 1
add   bx, word ptr [bp - 0Eh] ; _textureL1LRU
mov   al, byte ptr ds:[bx]   ; textureL1LRU[NUM_TEXTURE_L1_CACHE_PAGES-1]
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

cmp   byte ptr ds:[bx + di], ah  ; ah is still 0 after MRU7/MRU3 func 0
je    found_start_page_single

mov   al, 1 ; al/ax is i
; cl/cx is start page.
; bx is start page or startpage + i offset
; dx is ??
; 
deallocate_next_startpage_single:

cmp   al, byte ptr ds:[bx + di]
ja    found_start_page_single

add   bl, al
mov   byte ptr ds:[bx + di], dh   ; dl/dh is -1
sal   bx, 1
mov   word ptr ds:[bx + si], dx   ; dx is -1

inc   al

SHIFT_PAGESWAP_ARGS bx            ; *PAGE_SWAP_ARG_MULT
add   bx, word ptr [bp - 0Ah]     ; pageswapargs[pageswapargs_rend_texture_offset
mov   word ptr ds:[bx], dx  ; dx is -1  TODO NPR or whatever
mov   bx, cx    ; zero out bh
jmp   deallocate_next_startpage_single

get_multipage:

; ah already zero

mov   bx, 0FFFEh ; -2, offset for the initial inc 2
; cx already the number
sub   cx, dx
;  al/ax already realtexpage

; dl is numpages
; cl is NUM_TEXTURE_L1_CACHE_PAGES-numpages (shifted for word)
; ch is 0
; bl will be i (starts as -2, incrementing to 0 first loop)
; for (i = 0; i < NUM_TEXTURE_L1_CACHE_PAGES-numpages; i++) {
; al is realtexpage

sal   cl, 1  ; word offset...

grab_next_page_loop_multi_continue:

inc   bx  ; 0 for 1st iteration after dec
inc   bx  ; 0 for 1st iteration after dec

cmp   bl, cl ; loop compare

jnl   evict_and_find_startpage_multi

;    if (activetexturepages[i] != realtexpage){
;        continue;
;    }

cmp   ax, word ptr ds:[bx + si]
jne   grab_next_page_loop_multi_continue

sar   bl, 1  ; undo word 

;    // all pages for this texture are in the cache, unevicted.
;    for (j = 0; j <= numpages; j++) {
;        R_MarkL1TextureCacheMRU(i+j);
;    }
mov   dh, bl
; bl is i
; bl/bx will be i+j   
; dl is numpages but we dec it till < 0

mark_all_pages_mru_loop:
mov   ax, bx

call  word ptr [bp - 2]
inc   bl
dec   dl
jns   mark_all_pages_mru_loop
 


;    R_MarkL2TextureCacheMRU(realtexpage);
;    return i;

pop   ax;   word ptr [bp - 014h]
call  word ptr [bp - 4]  ; R_MarkL2TextureCacheMRU_
mov   al, dh
mov   es, ax
LEAVE_MACRO 
POPA_NO_AX_MACRO
mov   ax, es
ret   
 


;		// figure out startpage based on LRU
;		startpage = NUM_TEXTURE_L1_CACHE_PAGES-1; // num EMS pages in conventional memory - 1

evict_and_find_startpage_multi:
xor   ax, ax ; set ah to 0. 
mov   bx, word ptr [bp - 010h]
dec   bx
mov   cx, bx
sub   cl, dl
; dl is numpages
; bx is startpage
; cx is ((NUM_TEXTURE_L1_CACHE_PAGES-1)-numpages)

add   bx, word ptr [bp - 0Eh] ; _textureL1LRU

find_start_page_loop_multi:

;		while (textureL1LRU[startpage] > ((NUM_TEXTURE_L1_CACHE_PAGES-1)-numpages)){
;			startpage--;
;		}

mov   al, byte ptr ds:[bx]
cmp   al, cl
jle   found_startpage_multi
dec   bx
jmp   find_start_page_loop_multi

found_start_page_single:

;		activetexturepages[startpage] = realtexpage; // FIRST_TEXTURE_LOGICAL_PAGE + pagenum;		
;  cl/cx is startpage
;  bl/bx is startpage 

pop   dx  ; bp - 014h, get realtexpage
; dx has realtexpage
; bx already ok

mov   byte ptr ds:[bx + di], bh  ; zero
shl   bx, 1                      ; startpage word offset.
mov   word ptr ds:[bx + si], dx
pop   ax                         ; mov   ax, word ptr [bp - 012h]

; TODO apply EPR
add   ax, dx                     ; _EPR(pageoffset + realtexpage);

; pageswapargs[pageswapargs_rend_texture_offset+(startpage)*PAGE_SWAP_ARG_MULT]

SHIFT_PAGESWAP_ARGS bx            ; *PAGE_SWAP_ARG_MULT
add   bx, word ptr [bp - 0Ah]     ; pageswapargs[pageswapargs_rend_texture_offset
mov   word ptr ds:[bx], ax        ; = _EPR(pageoffset + realtexpage);

; dx should be realtexpage???
xchg  ax, dx

call  word ptr [bp - 4]  ; R_MarkL2TextureCacheMRU_
call  word ptr [bp - 6]  ; Z_QuickMapRenderTexture_


mov   ax, 0FFFFh

cmp   byte ptr [bp - 010h], NUM_SPRITE_L1_CACHE_PAGES
je    do_sprite_eviction
do_tex_eviction:
; todo put these next to each other and stosw?
mov   di, ds
mov   es, di
mov   di, OFFSET _cachedlumps
; todo: investigate if the cache was really emptied?
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

mov   es, cx ; cl/cx is start page
LEAVE_MACRO 
POPA_NO_AX_MACRO
mov   ax, es
ret


found_startpage_multi:
;		startpage = textureL1LRU[startpage];


; al already set to startpage
mov   bx, ax    ; bh is 0
push  ax  ; bp - 016h
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
sal   bx, 1                      ; startpage word offset.
mov   word ptr ds:[bx + si], cx  ; -1
inc   al



; todo cx is _NPR(PAGE_5000_OFFSET+startpage+i);
SHIFT_PAGESWAP_ARGS bx            ; *PAGE_SWAP_ARG_MULT
add   bx, word ptr [bp - 0Ah]     ; pageswapargs[pageswapargs_rend_texture_offset
mov   word ptr ds:[bx], cx  ; cx is -1  TODO NPR or whatever

xor   bh, bh
jmp   loop_next_invalidate_page_multi

do_sprite_eviction:

mov   word ptr ds:[_lastvisspritepatch], ax
mov   word ptr ds:[_lastvisspritepatch2], ax

mov   es, cx ; cl/cx is start page
LEAVE_MACRO 
POPA_NO_AX_MACRO
mov   ax, es
ret

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
mov   es, word ptr [bp - 014h]

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

; TODO apply EPR
add   ax, word ptr [bp - 012h]  ; pageoffset


;	pageswapargs[pageswapargs_rend_texture_offset+(startpage + i)*PAGE_SWAP_ARG_MULT]  = _EPR(currentpage+pageoffset);





; bh is very likely nonzero here. ES resets it later..

; currentpage+pageoffset


SHIFT_PAGESWAP_ARGS bx            ; *PAGE_SWAP_ARG_MULT
add   bx, word ptr [bp - 0Ah]     ; pageswapargs[pageswapargs_rend_texture_offset
mov   word ptr ds:[bx], ax ; todo epr


dec   ch    ; dec numpages - i
inc   cl    ; inc i
inc   dh

;    currentpage = texturecache_nodes[currentpage].prev;
mov   bx, es ; currentpage
sal   bx, 1
sal   bx, 1
add   bx, word ptr [bp - 0Ch]   ; _texturecache_nodes
mov   bl, byte ptr ds:[bx]
xor   bh, bh
mov   es, bx
cmp   dh, dl
jbe   loop_mark_next_page_mru_multi




;    R_MarkL2TextureCacheMRU(realtexpage);
;    Z_QuickMapRenderTexture();

		

mov   ax, word ptr [bp - 014h]
call  word ptr [bp - 4]  ; R_MarkL2TextureCacheMRU_
call  word ptr [bp - 6]  ; Z_QuickMapRenderTexture_

;	//todo: only -1 if its in the knocked out page? pretty infrequent though.
;    cachedtex = -1;
;    cachedtex2 = -1;


mov   ax, 0FFFFh

pop   cx ;  [bp - 016h]
cmp   byte ptr [bp - 010h], NUM_SPRITE_L1_CACHE_PAGES
je    do_sprite_eviction
jmp   do_tex_eviction


ENDP

PATCH_TEXTURE_SEGMENT = 05000h
COMPOSITE_TEXTURE_SEGMENT = 05000h
SPRITE_COLUMN_SEGMENT = 09000h

PROC R_GetPatchTexture_ NEAR
PUBLIC R_GetPatchTexture_

;segment_t __near R_GetPatchTexture(int16_t lump, uint8_t maskedlookup) ;

; bp - 2 = texoffset

push  si


;	int16_t index = lump - firstpatch;
;	uint8_t texpage = patchpage[index];
;	uint8_t texoffset = patchoffset[index];


mov   si, PATCHPAGE_SEGMENT
mov   es, si
mov   si, ax
sub   si, word ptr ds:[_firstpatch]  ; si is index
mov   dh, byte ptr es:[si]                      ; texpage 
cmp   dh, 0FFh
je    patch_not_in_l1_cache

patch_in_l1_cache:
mov   al, dh
mov   dl, byte ptr es:[si + PATCHOFFSET_OFFSET] ; texoffset
xor   dh, dh
mov   si, dx   ; back up texpage
mov   dl, FIRST_TEXTURE_LOGICAL_PAGE
call  R_GetTexturePage_
SHIFT_MACRO shl   si 4  ; shift texpage 4. 
cbw
xchg  ax, si
sal   si, 1
add   ax, word ptr [si + _pagesegments]
add   ah, (PATCH_TEXTURE_SEGMENT SHR 8)
pop   si
ret   

patch_not_in_l1_cache:
; we use bx/cx in here..
push  bx
push  ax  ; bp - 2 store lump

mov   al, dh
cmp   dl, al
jne   set_masked_true
set_masked_false:
xor   ax, ax
push  ax  ; bp - 4
mov   bx, si
mov   dx, word ptr ds:[bx + si + _patch_sizes]

done_doing_lookup:
mov   bx, CACHETYPE_PATCH
mov   ax, si
call  R_GetNextTextureBlock_
mov   ax, PATCHPAGE_SEGMENT
mov   es, ax
xor   ah, ah
mov   al, byte ptr es:[si + PATCHOFFSET_OFFSET]
push  ax     ; bp - 6
mov   al, byte ptr es:[si]
mov   dx, FIRST_TEXTURE_LOGICAL_PAGE
call  R_GetTexturePage_
cbw
mov   si, ax
sal   si, 1
mov   si, word ptr [si + _pagesegments]
pop   ax     ; bp - 6
SHIFT_MACRO   shl ax 4
add   si, PATCH_TEXTURE_SEGMENT
add   si, ax
pop   bx     ; bp - 4
mov   dx, si
pop   ax     ; bp - 2
call  R_LoadPatchColumns_
xchg  ax, si
pop   bx
pop   si
ret   

set_masked_true:
mov   ax, 1
push  ax
xor   dh, dh
mov   bx, dx
SHIFT_MACRO shl   bx 3
mov   dx, word ptr ds:[bx + _masked_headers + 4] ; texturesize field is + 4
jmp   done_doing_lookup



ENDP





PROC R_GetCompositeTexture_ NEAR
PUBLIC R_GetCompositeTexture_

; segment_t R_GetCompositeTexture(int16_t tex_index) ;

; todo clean up reg use, should be much fewer push/pop

push  dx
push  si


mov   si, COMPOSITETEXTUREPAGE_SEGMENT
mov   es, si
mov   si, ax
mov   al, byte ptr es:[si]
cmp   al, 0FFh
je    composite_not_in_cache
mov   dl, byte ptr es:[si + COMPOSITETEXTUREOFFSET_OFFSET]
xor   dh, dh
mov   si, dx

mov   dl, FIRST_TEXTURE_LOGICAL_PAGE

call  R_GetTexturePage_
SHIFT_MACRO shl   si 4
xor   ah, ah
mov   bx, ax
sal   bx, 1

mov   ax, si
add   ax, word ptr ds:[bx + _pagesegments]
add   ah, (COMPOSITE_TEXTURE_SEGMENT SHR 8)

pop   si
pop   dx
ret 

composite_not_in_cache:
push  bx
push  es
mov   dx, TEXTURECOMPOSITESIZES_SEGMENT
mov   es, dx
mov   bx, si
mov   ax, si
mov   dx, word ptr es:[si + bx]
mov   bx, CACHETYPE_COMPOSITE
call  R_GetNextTextureBlock_
pop   es
mov   dx, FIRST_TEXTURE_LOGICAL_PAGE
mov   al, byte ptr es:[si]
mov   bl, byte ptr es:[si + COMPOSITETEXTUREOFFSET_OFFSET]
call  R_GetTexturePage_
xor   ah, ah
xchg  ax, bx   ; bx stores page. ax gets offset
xor   ah, ah
SHIFT_MACRO shl   ax 4
sal   bx, 1
mov   bx, word ptr ds:[bx + _pagesegments]

add   bh, (COMPOSITE_TEXTURE_SEGMENT SHR 8)
add   bx, ax
mov   dx, bx
mov   ax, si
call  R_GenerateComposite_
xchg  ax, bx
pop   bx
pop   si
pop   dx
ret  

ENDP


PROC R_GetSpriteTexture_ FAR
PUBLIC R_GetSpriteTexture_

push  dx
push  si
mov   si, SPRITEPAGE_SEGMENT
mov   es, si

xchg  ax, si    ; si gets index

mov   al, byte ptr es:[si]
cmp   al, 0FFh
je    sprite_not_in_cache

mov   dl, byte ptr es:[si + SPRITEOFFSETS_OFFSET]

call  R_GetSpritePage_
xor   ah, ah
mov   si, ax
mov   al, dl
SHIFT_MACRO shl   ax 4
sal   si, 1
mov   dx, word ptr ds:[si + _pagesegments]
add   dh, (SPRITE_COLUMN_SEGMENT SHR 8)
add   ax, dx
pop   si
pop   dx
retf  

sprite_not_in_cache:

mov   ax, word ptr ds:[_firstspritelump]
add   ax, si
push  ax    ; bp - 2, index
push  es    ; bp - 4, segment
call  R_GetNextSpriteBlock_

pop   es    ; bp - 4, segment
mov   al, byte ptr es:[si]

mov   dl, byte ptr es:[si + SPRITEOFFSETS_OFFSET]

call  R_GetSpritePage_
xor   ah, ah
mov   si, ax
mov   al, dl
SHIFT_MACRO shl   ax 4
sal   si, 1
mov   dx, word ptr ds:[si + _pagesegments]
add   dh, (SPRITE_COLUMN_SEGMENT SHR 8) 
add   dx, ax
mov   si, dx ; back this up
pop   ax     ; bp - 2, index

call  R_LoadSpriteColumns_

mov   ax, si
pop   si
pop   dx
retf  


ENDP

COMMENT @


PROC R_GenerateComposite_ NEAR
PUBLIC R_GenerateComposite_


0x0000000000000000:  53                push      bx
0x0000000000000001:  51                push      cx
0x0000000000000002:  56                push      si
0x0000000000000003:  57                push      di
0x0000000000000004:  55                push      bp
0x0000000000000005:  89 E5             mov       bp, sp
0x0000000000000007:  83 EC 32          sub       sp, 0x32
0x000000000000000a:  52                push      dx
0x000000000000000b:  89 C3             mov       bx, ax
0x000000000000000d:  01 C3             add       bx, ax
0x000000000000000f:  B8 2D 93          mov       ax, 0x932d
0x0000000000000012:  BA B2 90          mov       dx, 0x90b2
0x0000000000000015:  8E C0             mov       es, ax
0x0000000000000017:  89 5E CE          mov       word ptr [bp - 0x32], bx
0x000000000000001a:  26 8B 1F          mov       bx, word ptr es:[bx]
0x000000000000001d:  8E C2             mov       es, dx
0x000000000000001f:  26 8A 47 08       mov       al, byte ptr es:[bx + 8]
0x0000000000000023:  30 E4             xor       ah, ah
0x0000000000000025:  40                inc       ax
0x0000000000000026:  89 46 E0          mov       word ptr [bp - 0x20], ax
0x0000000000000029:  26 8A 47 09       mov       al, byte ptr es:[bx + 9]
0x000000000000002d:  FE C0             inc       al
0x000000000000002f:  C7 46 E8 FF FF    mov       word ptr [bp - 0x18], 0xffff
0x0000000000000034:  88 46 F6          mov       byte ptr [bp - 0xa], al
0x0000000000000037:  24 0F             and       al, 0xf
0x0000000000000039:  C7 46 D0 00 00    mov       word ptr [bp - 0x30], 0
0x000000000000003e:  B4 10             mov       ah, 0x10
0x0000000000000040:  C7 46 EC 00 90    mov       word ptr [bp - 0x14], 0x9000
0x0000000000000045:  28 C4             sub       ah, al
0x0000000000000047:  C7 46 E2 00 00    mov       word ptr [bp - 0x1e], 0
0x000000000000004c:  88 E0             mov       al, ah
0x000000000000004e:  89 56 DE          mov       word ptr [bp - 0x22], dx
0x0000000000000051:  24 0F             and       al, 0xf
0x0000000000000053:  8B 76 CE          mov       si, word ptr [bp - 0x32]
0x0000000000000056:  8A 66 F6          mov       ah, byte ptr [bp - 0xa]
0x0000000000000059:  81 C6 F0 EA       add       si, 0xeaf0
0x000000000000005d:  00 C4             add       ah, al
0x000000000000005f:  83 C3 0B          add       bx, 0xb
0x0000000000000062:  88 66 FA          mov       byte ptr [bp - 6], ah
0x0000000000000065:  88 E0             mov       al, ah
0x0000000000000067:  89 5E E6          mov       word ptr [bp - 0x1a], bx
0x000000000000006a:  30 E4             xor       ah, ah
0x000000000000006c:  8B 34             mov       si, word ptr [si]
0x000000000000006e:  C1 F8 04          sar       ax, 4
0x0000000000000071:  01 F6             add       si, si
0x0000000000000073:  88 46 FA          mov       byte ptr [bp - 6], al
0x0000000000000076:  26 8A 47 FF       mov       al, byte ptr es:[bx - 1]
0x000000000000007a:  89 76 EA          mov       word ptr [bp - 0x16], si
0x000000000000007d:  88 46 FE          mov       byte ptr [bp - 2], al
0x0000000000000080:  0E                push      cs
0x0000000000000081:  E8 B4 47          call      0x4838
0x0000000000000084:  90                nop       
0x0000000000000085:  8A 46 FE          mov       al, byte ptr [bp - 2]
0x0000000000000088:  30 E4             xor       ah, ah
0x000000000000008a:  3B 46 E2          cmp       ax, word ptr [bp - 0x1e]
0x000000000000008d:  7F 03             jg        0x92
0x000000000000008f:  E9 A0 01          jmp       0x232
0x0000000000000092:  8B 76 E6          mov       si, word ptr [bp - 0x1a]
0x0000000000000095:  8B 46 DE          mov       ax, word ptr [bp - 0x22]
0x0000000000000098:  8E 46 DE          mov       es, word ptr [bp - 0x22]
0x000000000000009b:  89 F3             mov       bx, si
0x000000000000009d:  31 FF             xor       di, di
0x000000000000009f:  26 8B 57 02       mov       dx, word ptr es:[bx + 2]
0x00000000000000a3:  89 46 E4          mov       word ptr [bp - 0x1c], ax
0x00000000000000a6:  80 E6 7F          and       dh, 0x7f
0x00000000000000a9:  8B 46 E8          mov       ax, word ptr [bp - 0x18]
0x00000000000000ac:  89 56 E8          mov       word ptr [bp - 0x18], dx
0x00000000000000af:  39 D0             cmp       ax, dx
0x00000000000000b1:  74 0C             je        0xbf
0x00000000000000b3:  B9 00 70          mov       cx, 0x7000
0x00000000000000b6:  89 D0             mov       ax, dx
0x00000000000000b8:  31 F3             xor       bx, si
0x00000000000000ba:  0E                push      cs
0x00000000000000bb:  E8 66 3E          call      W_CacheLumpNumDirect_
0x00000000000000be:  90                nop       
0x00000000000000bf:  8E 46 E4          mov       es, word ptr [bp - 0x1c]
0x00000000000000c2:  26 F6 44 03 80    test      byte ptr es:[si + 3], 0x80
0x00000000000000c7:  75 03             jne       label_6
0x00000000000000c9:  E9 A1 00          jmp       0x16d
label_6:
0x00000000000000cc:  BB FF FF          mov       bx, 0xffff
0x00000000000000cf:  8E 46 E4          mov       es, word ptr [bp - 0x1c]
0x00000000000000d2:  26 8A 04          mov       al, byte ptr es:[si]
0x00000000000000d5:  30 E4             xor       ah, ah
0x00000000000000d7:  F7 EB             imul      bx
0x00000000000000d9:  BB 00 70          mov       bx, 0x7000
0x00000000000000dc:  26 8A 54 01       mov       dl, byte ptr es:[si + 1]
0x00000000000000e0:  8E C3             mov       es, bx
0x00000000000000e2:  31 DB             xor       bx, bx
0x00000000000000e4:  26 8B 1F          mov       bx, word ptr es:[bx]
0x00000000000000e7:  88 56 FC          mov       byte ptr [bp - 4], dl
0x00000000000000ea:  01 C3             add       bx, ax
0x00000000000000ec:  89 C2             mov       dx, ax
0x00000000000000ee:  89 5E D2          mov       word ptr [bp - 0x2e], bx
0x00000000000000f1:  85 C0             test      ax, ax
0x00000000000000f3:  7D 03             jge       0xf8
0x00000000000000f5:  E9 7B 00          jmp       0x173
0x00000000000000f8:  89 46 D8          mov       word ptr [bp - 0x28], ax
0x00000000000000fb:  8B 46 D2          mov       ax, word ptr [bp - 0x2e]
0x00000000000000fe:  3B 46 E0          cmp       ax, word ptr [bp - 0x20]
0x0000000000000101:  7E 06             jle       0x109
0x0000000000000103:  8B 46 E0          mov       ax, word ptr [bp - 0x20]
0x0000000000000106:  89 46 D2          mov       word ptr [bp - 0x2e], ax
0x0000000000000109:  89 FB             mov       bx, di
0x000000000000010b:  01 FB             add       bx, di
0x000000000000010d:  8E 46 EC          mov       es, word ptr [bp - 0x14]
0x0000000000000110:  03 5E EA          add       bx, word ptr [bp - 0x16]
0x0000000000000113:  26 8B 07          mov       ax, word ptr es:[bx]
0x0000000000000116:  89 46 DC          mov       word ptr [bp - 0x24], ax
0x0000000000000119:  26 8A 47 02       mov       al, byte ptr es:[bx + 2]
0x000000000000011d:  30 E4             xor       ah, ah
0x000000000000011f:  89 C6             mov       si, ax
0x0000000000000121:  8B 46 CC          mov       ax, word ptr [bp - 0x34]
0x0000000000000124:  46                inc       si
0x0000000000000125:  89 46 F2          mov       word ptr [bp - 0xe], ax
0x0000000000000128:  83 7E D8 00       cmp       word ptr [bp - 0x28], 0
0x000000000000012c:  74 6B             je        0x199
0x000000000000012e:  8B 5E EA          mov       bx, word ptr [bp - 0x16]
0x0000000000000131:  26 8B 07          mov       ax, word ptr es:[bx]
0x0000000000000134:  89 46 F0          mov       word ptr [bp - 0x10], ax
0x0000000000000137:  26 8A 47 02       mov       al, byte ptr es:[bx + 2]
0x000000000000013b:  C6 46 F4 00       mov       byte ptr [bp - 0xc], 0
0x000000000000013f:  30 E4             xor       ah, ah
0x0000000000000141:  C6 46 F8 00       mov       byte ptr [bp - 8], 0
0x0000000000000145:  40                inc       ax
0x0000000000000146:  8A 4E F4          mov       cl, byte ptr [bp - 0xc]
0x0000000000000149:  30 ED             xor       ch, ch
0x000000000000014b:  01 C1             add       cx, ax
0x000000000000014d:  3B 4E D8          cmp       cx, word ptr [bp - 0x28]
0x0000000000000150:  7D 2D             jge       0x17f
0x0000000000000152:  83 7E F0 FF       cmp       word ptr [bp - 0x10], -1
0x0000000000000156:  74 22             je        0x17a
0x0000000000000158:  00 46 F4          add       byte ptr [bp - 0xc], al
0x000000000000015b:  26 8B 47 04       mov       ax, word ptr es:[bx + 4]
0x000000000000015f:  89 46 F0          mov       word ptr [bp - 0x10], ax
0x0000000000000162:  26 8A 47 06       mov       al, byte ptr es:[bx + 6]
0x0000000000000166:  30 E4             xor       ah, ah
0x0000000000000168:  83 C3 04          add       bx, 4
0x000000000000016b:  EB D8             jmp       0x145
0x000000000000016d:  BB 01 00          mov       bx, 1
0x0000000000000170:  E9 5C FF          jmp       0xcf
0x0000000000000173:  C7 46 D8 00 00    mov       word ptr [bp - 0x28], 0
0x0000000000000178:  EB 81             jmp       0xfb
0x000000000000017a:  00 46 F8          add       byte ptr [bp - 8], al
0x000000000000017d:  EB D9             jmp       0x158
0x000000000000017f:  83 7E F0 FF       cmp       word ptr [bp - 0x10], -1
0x0000000000000183:  75 09             jne       0x18e
0x0000000000000185:  8A 46 D8          mov       al, byte ptr [bp - 0x28]
0x0000000000000188:  2A 46 F4          sub       al, byte ptr [bp - 0xc]
0x000000000000018b:  00 46 F8          add       byte ptr [bp - 8], al
0x000000000000018e:  8A 66 F8          mov       ah, byte ptr [bp - 8]
0x0000000000000191:  8A 46 FA          mov       al, byte ptr [bp - 6]
0x0000000000000194:  F6 E4             mul       ah
0x0000000000000196:  01 46 F2          add       word ptr [bp - 0xe], ax
0x0000000000000199:  89 D3             mov       bx, dx
0x000000000000019b:  8B 46 D8          mov       ax, word ptr [bp - 0x28]
0x000000000000019e:  C1 E3 02          shl       bx, 2
0x00000000000001a1:  C1 E0 02          shl       ax, 2
0x00000000000001a4:  F7 DB             neg       bx
0x00000000000001a6:  01 D8             add       ax, bx
0x00000000000001a8:  8B 5E EA          mov       bx, word ptr [bp - 0x16]
0x00000000000001ab:  89 46 D6          mov       word ptr [bp - 0x2a], ax
0x00000000000001ae:  8B 46 EC          mov       ax, word ptr [bp - 0x14]
0x00000000000001b1:  89 5E DA          mov       word ptr [bp - 0x26], bx
0x00000000000001b4:  89 46 EE          mov       word ptr [bp - 0x12], ax
0x00000000000001b7:  8B 46 D8          mov       ax, word ptr [bp - 0x28]
0x00000000000001ba:  3B 46 D2          cmp       ax, word ptr [bp - 0x2e]
0x00000000000001bd:  7D 69             jge       0x228
0x00000000000001bf:  8B 5E DA          mov       bx, word ptr [bp - 0x26]
0x00000000000001c2:  89 F8             mov       ax, di
0x00000000000001c4:  8B 56 EE          mov       dx, word ptr [bp - 0x12]
0x00000000000001c7:  01 F8             add       ax, di
0x00000000000001c9:  8E C2             mov       es, dx
0x00000000000001cb:  01 C3             add       bx, ax
0x00000000000001cd:  3B 76 D8          cmp       si, word ptr [bp - 0x28]
0x00000000000001d0:  7F 18             jg        0x1ea
0x00000000000001d2:  26 8B 47 04       mov       ax, word ptr es:[bx + 4]
0x00000000000001d6:  89 46 DC          mov       word ptr [bp - 0x24], ax
0x00000000000001d9:  26 8A 47 06       mov       al, byte ptr es:[bx + 6]
0x00000000000001dd:  30 E4             xor       ah, ah
0x00000000000001df:  83 C3 04          add       bx, 4
0x00000000000001e2:  40                inc       ax
0x00000000000001e3:  83 C7 02          add       di, 2
0x00000000000001e6:  01 C6             add       si, ax
0x00000000000001e8:  EB E3             jmp       0x1cd
0x00000000000001ea:  83 7E DC 00       cmp       word ptr [bp - 0x24], 0
0x00000000000001ee:  7C 09             jl        0x1f9
0x00000000000001f0:  83 46 D6 04       add       word ptr [bp - 0x2a], 4
0x00000000000001f4:  FF 46 D8          inc       word ptr [bp - 0x28]
0x00000000000001f7:  EB BE             jmp       0x1b7
0x00000000000001f9:  8A 4E F6          mov       cl, byte ptr [bp - 0xa]
0x00000000000001fc:  8A 46 FC          mov       al, byte ptr [bp - 4]
0x00000000000001ff:  BA 00 70          mov       dx, 0x7000
0x0000000000000202:  8B 5E D6          mov       bx, word ptr [bp - 0x2a]
0x0000000000000205:  8E C2             mov       es, dx
0x0000000000000207:  83 C3 08          add       bx, 8
0x000000000000020a:  98                cwde      
0x000000000000020b:  26 8B 17          mov       dx, word ptr es:[bx]
0x000000000000020e:  30 ED             xor       ch, ch
0x0000000000000210:  89 56 D4          mov       word ptr [bp - 0x2c], dx
0x0000000000000213:  89 C3             mov       bx, ax
0x0000000000000215:  8B 56 F2          mov       dx, word ptr [bp - 0xe]
0x0000000000000218:  8B 46 D4          mov       ax, word ptr [bp - 0x2c]
0x000000000000021b:  E8 C8 0B          call      0xde6
0x000000000000021e:  8A 46 FA          mov       al, byte ptr [bp - 6]
0x0000000000000221:  30 E4             xor       ah, ah
0x0000000000000223:  01 46 F2          add       word ptr [bp - 0xe], ax
0x0000000000000226:  EB C8             jmp       0x1f0
0x0000000000000228:  83 46 E6 04       add       word ptr [bp - 0x1a], 4
0x000000000000022c:  FF 46 E2          inc       word ptr [bp - 0x1e]
0x000000000000022f:  E9 53 FE          jmp       0x85
0x0000000000000232:  0E                push      cs
0x0000000000000233:  E8 20 45          call      0x4756
0x0000000000000236:  90                nop       
0x0000000000000237:  C9                LEAVE_MACRO     
0x0000000000000238:  5F                pop       di
0x0000000000000239:  5E                pop       si
0x000000000000023a:  59                pop       cx
0x000000000000023b:  5B                pop       bx
0x000000000000023c:  C3                ret       

ENDP


PROC R_GetColumnSegment_ NEAR
PUBLIC R_GetColumnSegment_



0x000000000000023e:  51                push      cx
0x000000000000023f:  56                push      si
0x0000000000000240:  57                push      di
0x0000000000000241:  55                push      bp
0x0000000000000242:  89 E5             mov       bp, sp
0x0000000000000244:  83 EC 14          sub       sp, 0x14
0x0000000000000247:  50                push      ax
0x0000000000000248:  89 D1             mov       cx, dx
0x000000000000024a:  88 5E FE          mov       byte ptr [bp - 2], bl
0x000000000000024d:  B8 A2 82          mov       ax, 0x82a2
0x0000000000000250:  8B 5E EA          mov       bx, word ptr [bp - 0x16]
0x0000000000000253:  8E C0             mov       es, ax
0x0000000000000255:  30 F5             xor       ch, dh
0x0000000000000257:  26 8A 07          mov       al, byte ptr es:[bx]
0x000000000000025a:  20 C1             and       cl, al
0x000000000000025c:  89 D8             mov       ax, bx
0x000000000000025e:  01 D8             add       ax, bx
0x0000000000000260:  89 56 F4          mov       word ptr [bp - 0xc], dx
0x0000000000000263:  89 C3             mov       bx, ax
0x0000000000000265:  81 C3 F0 EA       add       bx, 0xeaf0
0x0000000000000269:  B8 00 90          mov       ax, 0x9000
0x000000000000026c:  8B 1F             mov       bx, word ptr [bx]
0x000000000000026e:  8E C0             mov       es, ax
0x0000000000000270:  01 DB             add       bx, bx
0x0000000000000272:  29 4E F4          sub       word ptr [bp - 0xc], cx
0x0000000000000275:  26 8A 47 03       mov       al, byte ptr es:[bx + 3]
0x0000000000000279:  88 4E F8          mov       byte ptr [bp - 8], cl
0x000000000000027c:  88 46 FC          mov       byte ptr [bp - 4], al
0x000000000000027f:  84 C0             test      al, al
0x0000000000000281:  74 03             je        0x286
0x0000000000000283:  E9 DD 00          jmp       0x363
0x0000000000000286:  8B 56 F4          mov       dx, word ptr [bp - 0xc]
0x0000000000000289:  8C 46 F6          mov       word ptr [bp - 0xa], es
0x000000000000028c:  31 FF             xor       di, di
0x000000000000028e:  85 C9             test      cx, cx
0x0000000000000290:  7C 28             jl        0x2ba
0x0000000000000292:  8E 46 F6          mov       es, word ptr [bp - 0xa]
0x0000000000000295:  26 8A 47 02       mov       al, byte ptr es:[bx + 2]
0x0000000000000299:  30 E4             xor       ah, ah
0x000000000000029b:  40                inc       ax
0x000000000000029c:  26 8B 37          mov       si, word ptr es:[bx]
0x000000000000029f:  89 46 F0          mov       word ptr [bp - 0x10], ax
0x00000000000002a2:  01 C2             add       dx, ax
0x00000000000002a4:  29 C1             sub       cx, ax
0x00000000000002a6:  85 F6             test      si, si
0x00000000000002a8:  7D 03             jge       0x2ad
0x00000000000002aa:  E9 D4 00          jmp       0x381
0x00000000000002ad:  8A 46 F0          mov       al, byte ptr [bp - 0x10]
0x00000000000002b0:  28 46 F8          sub       byte ptr [bp - 8], al
0x00000000000002b3:  83 C3 04          add       bx, 4
0x00000000000002b6:  85 C9             test      cx, cx
0x00000000000002b8:  7D DB             jge       0x295
0x00000000000002ba:  8E 46 F6          mov       es, word ptr [bp - 0xa]
0x00000000000002bd:  26 8A 47 FF       mov       al, byte ptr es:[bx - 1]
0x00000000000002c1:  85 F6             test      si, si
0x00000000000002c3:  7F 03             jg        0x2c8
0x00000000000002c5:  E9 BE 00          jmp       0x386
0x00000000000002c8:  8B 7E F4          mov       di, word ptr [bp - 0xc]
0x00000000000002cb:  30 E4             xor       ah, ah
0x00000000000002cd:  01 C7             add       di, ax
0x00000000000002cf:  8A 46 FE          mov       al, byte ptr [bp - 2]
0x00000000000002d2:  98                cwde      
0x00000000000002d3:  89 C3             mov       bx, ax
0x00000000000002d5:  01 C3             add       bx, ax
0x00000000000002d7:  89 BF 64 1C       mov       word ptr [bx + 0x1c64], di
0x00000000000002db:  89 D0             mov       ax, dx
0x00000000000002dd:  2B 46 F0          sub       ax, word ptr [bp - 0x10]
0x00000000000002e0:  89 46 EC          mov       word ptr [bp - 0x14], ax
0x00000000000002e3:  8A 46 FE          mov       al, byte ptr [bp - 2]
0x00000000000002e6:  98                cwde      
0x00000000000002e7:  89 C3             mov       bx, ax
0x00000000000002e9:  89 C7             mov       di, ax
0x00000000000002eb:  C6 87 37 0C 00    mov       byte ptr [bx + 0xc37], 0
0x00000000000002f0:  01 C7             add       di, ax
0x00000000000002f2:  8B 46 EC          mov       ax, word ptr [bp - 0x14]
0x00000000000002f5:  89 95 3A 0C       mov       word ptr [di + 0xc3a], dx
0x00000000000002f9:  89 85 68 1C       mov       word ptr [di + 0x1c68], ax
0x00000000000002fd:  85 F6             test      si, si
0x00000000000002ff:  7E 5F             jle       0x360
0x0000000000000301:  89 F3             mov       bx, si
0x0000000000000303:  B8 BA 93          mov       ax, 0x93ba
0x0000000000000306:  2B 1E 7E 1F       sub       bx, word ptr [0x1f7e]
0x000000000000030a:  8E C0             mov       es, ax
0x000000000000030c:  26 8A 07          mov       al, byte ptr es:[bx]
0x000000000000030f:  88 46 FA          mov       byte ptr [bp - 6], al
0x0000000000000312:  31 DB             xor       bx, bx
0x0000000000000314:  80 66 FA 0F       and       byte ptr [bp - 6], 0xf
0x0000000000000318:  31 C0             xor       ax, ax
0x000000000000031a:  3B 36 18 1C       cmp       si, word ptr [0x1c18]
0x000000000000031e:  74 0F             je        0x32f
0x0000000000000320:  40                inc       ax
0x0000000000000321:  83 C3 02          add       bx, 2
0x0000000000000324:  3D 04 00          cmp       ax, 4
0x0000000000000327:  7D 66             jge       0x38f
0x0000000000000329:  3B B7 18 1C       cmp       si, word ptr [bx + 0x1c18]
0x000000000000032d:  75 F1             jne       0x320
0x000000000000032f:  85 C0             test      ax, ax
0x0000000000000331:  75 64             jne       0x397
0x0000000000000333:  85 C9             test      cx, cx
0x0000000000000335:  7D 5A             jge       0x391
0x0000000000000337:  89 F3             mov       bx, si
0x0000000000000339:  B8 7E 93          mov       ax, 0x937e
0x000000000000033c:  2B 1E 7E 1F       sub       bx, word ptr [0x1f7e]
0x0000000000000340:  8E C0             mov       es, ax
0x0000000000000342:  01 DB             add       bx, bx
0x0000000000000344:  BA A2 82          mov       dx, 0x82a2
0x0000000000000347:  26 8B 07          mov       ax, word ptr es:[bx]
0x000000000000034a:  8B 5E EA          mov       bx, word ptr [bp - 0x16]
0x000000000000034d:  8E C2             mov       es, dx
0x000000000000034f:  26 8A 17          mov       dl, byte ptr es:[bx]
0x0000000000000352:  30 F6             xor       dh, dh
0x0000000000000354:  39 D0             cmp       ax, dx
0x0000000000000356:  77 3C             ja        0x394
0x0000000000000358:  85 C9             test      cx, cx
0x000000000000035a:  7D 35             jge       0x391
0x000000000000035c:  01 C1             add       cx, ax
0x000000000000035e:  EB F8             jmp       0x358
0x0000000000000360:  E9 ED 00          jmp       0x450
0x0000000000000363:  8A 46 FE          mov       al, byte ptr [bp - 2]
0x0000000000000366:  98                cwde      
0x0000000000000367:  26 8B 37          mov       si, word ptr es:[bx]
0x000000000000036a:  89 C7             mov       di, ax
0x000000000000036c:  89 C3             mov       bx, ax
0x000000000000036e:  01 C7             add       di, ax
0x0000000000000370:  8B 46 F4          mov       ax, word ptr [bp - 0xc]
0x0000000000000373:  89 85 64 1C       mov       word ptr [di + 0x1c64], ax
0x0000000000000377:  8A 46 FC          mov       al, byte ptr [bp - 4]
0x000000000000037a:  88 87 37 0C       mov       byte ptr [bx + 0xc37], al
0x000000000000037e:  E9 7C FF          jmp       0x2fd
0x0000000000000381:  01 C7             add       di, ax
0x0000000000000383:  E9 2D FF          jmp       0x2b3
0x0000000000000386:  89 D0             mov       ax, dx
0x0000000000000388:  29 F8             sub       ax, di
0x000000000000038a:  89 C7             mov       di, ax
0x000000000000038c:  E9 40 FF          jmp       0x2cf
0x000000000000038f:  EB 3E             jmp       0x3cf
0x0000000000000391:  E9 96 00          jmp       0x42a
0x0000000000000394:  E9 8D 00          jmp       0x424
0x0000000000000397:  8B 97 18 1C       mov       dx, word ptr [bx + 0x1c18]
0x000000000000039b:  8B BF 10 1C       mov       di, word ptr [bx + 0x1c10]
0x000000000000039f:  89 56 F2          mov       word ptr [bp - 0xe], dx
0x00000000000003a2:  89 C2             mov       dx, ax
0x00000000000003a4:  7E 1C             jle       0x3c2
0x00000000000003a6:  89 C3             mov       bx, ax
0x00000000000003a8:  01 C3             add       bx, ax
0x00000000000003aa:  83 EB 02          sub       bx, 2
0x00000000000003ad:  8B 87 10 1C       mov       ax, word ptr [bx + 0x1c10]
0x00000000000003b1:  89 87 12 1C       mov       word ptr [bx + 0x1c12], ax
0x00000000000003b5:  8B 87 18 1C       mov       ax, word ptr [bx + 0x1c18]
0x00000000000003b9:  4A                dec       dx
0x00000000000003ba:  89 87 1A 1C       mov       word ptr [bx + 0x1c1a], ax
0x00000000000003be:  85 D2             test      dx, dx
0x00000000000003c0:  7F E8             jg        0x3aa
0x00000000000003c2:  8B 46 F2          mov       ax, word ptr [bp - 0xe]
0x00000000000003c5:  89 3E 10 1C       mov       word ptr [0x1c10], di
0x00000000000003c9:  A3 18 1C          mov       word ptr [0x1c18], ax
0x00000000000003cc:  E9 64 FF          jmp       0x333
0x00000000000003cf:  A1 14 1C          mov       ax, word ptr [0x1c14]
0x00000000000003d2:  A3 16 1C          mov       word ptr [0x1c16], ax
0x00000000000003d5:  A1 12 1C          mov       ax, word ptr [0x1c12]
0x00000000000003d8:  A3 14 1C          mov       word ptr [0x1c14], ax
0x00000000000003db:  A1 10 1C          mov       ax, word ptr [0x1c10]
0x00000000000003de:  A3 12 1C          mov       word ptr [0x1c12], ax
0x00000000000003e1:  A1 1C 1C          mov       ax, word ptr [0x1c1c]
0x00000000000003e4:  A3 1E 1C          mov       word ptr [0x1c1e], ax
0x00000000000003e7:  A1 1A 1C          mov       ax, word ptr [0x1c1a]
0x00000000000003ea:  A3 1C 1C          mov       word ptr [0x1c1c], ax
0x00000000000003ed:  A1 18 1C          mov       ax, word ptr [0x1c18]
0x00000000000003f0:  A3 1A 1C          mov       word ptr [0x1c1a], ax
0x00000000000003f3:  8A 46 FE          mov       al, byte ptr [bp - 2]
0x00000000000003f6:  98                cwde      
0x00000000000003f7:  89 C7             mov       di, ax
0x00000000000003f9:  01 C7             add       di, ax
0x00000000000003fb:  89 C3             mov       bx, ax
0x00000000000003fd:  8B 85 3A 0C       mov       ax, word ptr [di + 0xc3a]
0x0000000000000401:  BA FF 00          mov       dx, 0xff
0x0000000000000404:  89 46 EE          mov       word ptr [bp - 0x12], ax
0x0000000000000407:  89 F0             mov       ax, si
0x0000000000000409:  E8 7E 0D          call      0x118a
0x000000000000040c:  A3 10 1C          mov       word ptr [0x1c10], ax
0x000000000000040f:  8B 46 EE          mov       ax, word ptr [bp - 0x12]
0x0000000000000412:  89 85 3A 0C       mov       word ptr [di + 0xc3a], ax
0x0000000000000416:  8A 46 FC          mov       al, byte ptr [bp - 4]
0x0000000000000419:  89 36 18 1C       mov       word ptr [0x1c18], si
0x000000000000041d:  88 87 37 0C       mov       byte ptr [bx + 0xc37], al
0x0000000000000421:  E9 0F FF          jmp       0x333
0x0000000000000424:  89 D0             mov       ax, dx
0x0000000000000426:  40                inc       ax
0x0000000000000427:  E9 2E FF          jmp       0x358
0x000000000000042a:  8A 46 FE          mov       al, byte ptr [bp - 2]
0x000000000000042d:  98                cwde      
0x000000000000042e:  89 C3             mov       bx, ax
0x0000000000000430:  8A 46 FA          mov       al, byte ptr [bp - 6]
0x0000000000000433:  88 87 E6 1E       mov       byte ptr [bx + 0x1ee6], al
0x0000000000000437:  01 DB             add       bx, bx
0x0000000000000439:  A1 10 1C          mov       ax, word ptr [0x1c10]
0x000000000000043c:  89 87 60 1C       mov       word ptr [bx + 0x1c60], ax
0x0000000000000440:  8A 66 FA          mov       ah, byte ptr [bp - 6]
0x0000000000000443:  88 C8             mov       al, cl
0x0000000000000445:  F6 E4             mul       ah
0x0000000000000447:  03 06 10 1C       add       ax, word ptr [0x1c10]
0x000000000000044b:  C9                LEAVE_MACRO     
0x000000000000044c:  5F                pop       di
0x000000000000044d:  5E                pop       si
0x000000000000044e:  59                pop       cx
0x000000000000044f:  C3                ret       
0x0000000000000450:  B8 30 4F          mov       ax, 0x4f30
0x0000000000000453:  8B 5E EA          mov       bx, word ptr [bp - 0x16]
0x0000000000000456:  8E C0             mov       es, ax
0x0000000000000458:  A1 AC 06          mov       ax, word ptr [0x6ac]
0x000000000000045b:  26 8A 17          mov       dl, byte ptr es:[bx]
0x000000000000045e:  39 D8             cmp       ax, bx
0x0000000000000460:  74 45             je        0x4a7
0x0000000000000462:  A1 B2 06          mov       ax, word ptr [0x6b2]
0x0000000000000465:  39 D8             cmp       ax, bx
0x0000000000000467:  74 62             je        0x4cb
0x0000000000000469:  8A 46 FE          mov       al, byte ptr [bp - 2]
0x000000000000046c:  98                cwde      
0x000000000000046d:  89 C6             mov       si, ax
0x000000000000046f:  89 C3             mov       bx, ax
0x0000000000000471:  01 C6             add       si, ax
0x0000000000000473:  A1 AC 06          mov       ax, word ptr [0x6ac]
0x0000000000000476:  A3 B2 06          mov       word ptr [0x6b2], ax
0x0000000000000479:  A1 AE 06          mov       ax, word ptr [0x6ae]
0x000000000000047c:  8B 7E EA          mov       di, word ptr [bp - 0x16]
0x000000000000047f:  A3 B0 06          mov       word ptr [0x6b0], ax
0x0000000000000482:  A0 B4 06          mov       al, byte ptr [0x6b4]
0x0000000000000485:  8B 8C 3A 0C       mov       cx, word ptr [si + 0xc3a]
0x0000000000000489:  A2 B5 06          mov       byte ptr [0x6b5], al
0x000000000000048c:  89 F8             mov       ax, di
0x000000000000048e:  89 3E AC 06       mov       word ptr [0x6ac], di
0x0000000000000492:  E8 8A 0D          call      0x121f
0x0000000000000495:  A3 AE 06          mov       word ptr [0x6ae], ax
0x0000000000000498:  88 16 B4 06       mov       byte ptr [0x6b4], dl
0x000000000000049c:  8A 46 FC          mov       al, byte ptr [bp - 4]
0x000000000000049f:  89 8C 3A 0C       mov       word ptr [si + 0xc3a], cx
0x00000000000004a3:  88 87 37 0C       mov       byte ptr [bx + 0xc37], al
0x00000000000004a7:  8A 46 FE          mov       al, byte ptr [bp - 2]
0x00000000000004aa:  98                cwde      
0x00000000000004ab:  89 C3             mov       bx, ax
0x00000000000004ad:  88 97 E6 1E       mov       byte ptr [bx + 0x1ee6], dl
0x00000000000004b1:  01 C3             add       bx, ax
0x00000000000004b3:  A1 AE 06          mov       ax, word ptr [0x6ae]
0x00000000000004b6:  89 87 60 1C       mov       word ptr [bx + 0x1c60], ax
0x00000000000004ba:  A0 B4 06          mov       al, byte ptr [0x6b4]
0x00000000000004bd:  8A 66 F8          mov       ah, byte ptr [bp - 8]
0x00000000000004c0:  F6 E4             mul       ah
0x00000000000004c2:  03 06 AE 06       add       ax, word ptr [0x6ae]
0x00000000000004c6:  C9                LEAVE_MACRO     
0x00000000000004c7:  5F                pop       di
0x00000000000004c8:  5E                pop       si
0x00000000000004c9:  59                pop       cx
0x00000000000004ca:  C3                ret       
0x00000000000004cb:  8B 1E AC 06       mov       bx, word ptr [0x6ac]
0x00000000000004cf:  A1 B2 06          mov       ax, word ptr [0x6b2]
0x00000000000004d2:  89 5E EA          mov       word ptr [bp - 0x16], bx
0x00000000000004d5:  A3 AC 06          mov       word ptr [0x6ac], ax
0x00000000000004d8:  89 1E B2 06       mov       word ptr [0x6b2], bx
0x00000000000004dc:  8B 1E AE 06       mov       bx, word ptr [0x6ae]
0x00000000000004e0:  A1 B0 06          mov       ax, word ptr [0x6b0]
0x00000000000004e3:  89 5E EA          mov       word ptr [bp - 0x16], bx
0x00000000000004e6:  89 1E B0 06       mov       word ptr [0x6b0], bx
0x00000000000004ea:  8A 1E B4 06       mov       bl, byte ptr [0x6b4]
0x00000000000004ee:  A3 AE 06          mov       word ptr [0x6ae], ax
0x00000000000004f1:  30 FF             xor       bh, bh
0x00000000000004f3:  A0 B5 06          mov       al, byte ptr [0x6b5]
0x00000000000004f6:  89 5E EA          mov       word ptr [bp - 0x16], bx
0x00000000000004f9:  A2 B4 06          mov       byte ptr [0x6b4], al
0x00000000000004fc:  8A 46 EA          mov       al, byte ptr [bp - 0x16]
0x00000000000004ff:  A2 B5 06          mov       byte ptr [0x6b5], al
0x0000000000000502:  EB A3             jmp       0x4a7

ENDP


PROC R_GetMaskedColumnSegment_ NEAR
PUBLIC R_GetMaskedColumnSegment_



0x0000000000000504:  53                push      bx
0x0000000000000505:  51                push      cx
0x0000000000000506:  56                push      si
0x0000000000000507:  57                push      di
0x0000000000000508:  55                push      bp
0x0000000000000509:  89 E5             mov       bp, sp
0x000000000000050b:  83 EC 10          sub       sp, 0x10
0x000000000000050e:  50                push      ax
0x000000000000050f:  89 D3             mov       bx, dx
0x0000000000000511:  BE 48 02          mov       si, 0x248
0x0000000000000514:  B8 A2 82          mov       ax, 0x82a2
0x0000000000000517:  C7 04 FF FF       mov       word ptr [si], 0xffff
0x000000000000051b:  8B 76 EE          mov       si, word ptr [bp - 0x12]
0x000000000000051e:  8E C0             mov       es, ax
0x0000000000000520:  30 F7             xor       bh, dh
0x0000000000000522:  26 8A 04          mov       al, byte ptr es:[si]
0x0000000000000525:  20 C3             and       bl, al
0x0000000000000527:  89 F0             mov       ax, si
0x0000000000000529:  01 F0             add       ax, si
0x000000000000052b:  89 56 F6          mov       word ptr [bp - 0xa], dx
0x000000000000052e:  89 C6             mov       si, ax
0x0000000000000530:  B8 00 70          mov       ax, 0x7000
0x0000000000000533:  8B 94 F0 EA       mov       dx, word ptr [si - 0x1510]
0x0000000000000537:  81 C6 F0 EA       add       si, 0xeaf0
0x000000000000053b:  01 D2             add       dx, dx
0x000000000000053d:  8E C0             mov       es, ax
0x000000000000053f:  89 D6             mov       si, dx
0x0000000000000541:  29 5E F6          sub       word ptr [bp - 0xa], bx
0x0000000000000544:  26 8A 44 03       mov       al, byte ptr es:[si + 3]
0x0000000000000548:  88 5E FA          mov       byte ptr [bp - 6], bl
0x000000000000054b:  88 46 FC          mov       byte ptr [bp - 4], al
0x000000000000054e:  84 C0             test      al, al
0x0000000000000550:  74 03             je        0x555
0x0000000000000552:  E9 F3 00          jmp       0x648
0x0000000000000555:  30 E4             xor       ah, ah
0x0000000000000557:  8C C2             mov       dx, es
0x0000000000000559:  89 46 F2          mov       word ptr [bp - 0xe], ax
0x000000000000055c:  8B 46 F6          mov       ax, word ptr [bp - 0xa]
0x000000000000055f:  85 DB             test      bx, bx
0x0000000000000561:  7C 21             jl        0x584
0x0000000000000563:  8E C2             mov       es, dx
0x0000000000000565:  26 8A 4C 02       mov       cl, byte ptr es:[si + 2]
0x0000000000000569:  30 ED             xor       ch, ch
0x000000000000056b:  41                inc       cx
0x000000000000056c:  26 8B 3C          mov       di, word ptr es:[si]
0x000000000000056f:  01 C8             add       ax, cx
0x0000000000000571:  29 CB             sub       bx, cx
0x0000000000000573:  85 FF             test      di, di
0x0000000000000575:  7D 03             jge       0x57a
0x0000000000000577:  E9 E8 00          jmp       0x662
0x000000000000057a:  28 4E FA          sub       byte ptr [bp - 6], cl
0x000000000000057d:  83 C6 04          add       si, 4
0x0000000000000580:  85 DB             test      bx, bx
0x0000000000000582:  7D E1             jge       0x565
0x0000000000000584:  8E C2             mov       es, dx
0x0000000000000586:  26 8A 54 FF       mov       dl, byte ptr es:[si - 1]
0x000000000000058a:  85 FF             test      di, di
0x000000000000058c:  7F 03             jg        0x591
0x000000000000058e:  E9 D9 00          jmp       0x66a
0x0000000000000591:  C6 46 F1 00       mov       byte ptr [bp - 0xf], 0
0x0000000000000595:  88 56 F0          mov       byte ptr [bp - 0x10], dl
0x0000000000000598:  8B 56 F6          mov       dx, word ptr [bp - 0xa]
0x000000000000059b:  BE BE 02          mov       si, 0x2be
0x000000000000059e:  03 56 F0          add       dx, word ptr [bp - 0x10]
0x00000000000005a1:  89 14             mov       word ptr [si], dx
0x00000000000005a3:  89 C2             mov       dx, ax
0x00000000000005a5:  BE BA 02          mov       si, 0x2ba
0x00000000000005a8:  29 CA             sub       dx, cx
0x00000000000005aa:  89 14             mov       word ptr [si], dx
0x00000000000005ac:  BE B8 02          mov       si, 0x2b8
0x00000000000005af:  89 04             mov       word ptr [si], ax
0x00000000000005b1:  BE BC 02          mov       si, 0x2bc
0x00000000000005b4:  C7 04 00 00       mov       word ptr [si], 0
0x00000000000005b8:  85 FF             test      di, di
0x00000000000005ba:  7F 03             jg        0x5bf
0x00000000000005bc:  E9 89 01          jmp       0x748
0x00000000000005bf:  B8 63 73          mov       ax, 0x7363
0x00000000000005c2:  8B 76 EE          mov       si, word ptr [bp - 0x12]
0x00000000000005c5:  8E C0             mov       es, ax
0x00000000000005c7:  26 8A 04          mov       al, byte ptr es:[si]
0x00000000000005ca:  88 46 FE          mov       byte ptr [bp - 2], al
0x00000000000005cd:  89 FE             mov       si, di
0x00000000000005cf:  B8 BA 73          mov       ax, 0x73ba
0x00000000000005d2:  2B 36 7E 1F       sub       si, word ptr [0x1f7e]
0x00000000000005d6:  8E C0             mov       es, ax
0x00000000000005d8:  31 C9             xor       cx, cx
0x00000000000005da:  26 8A 04          mov       al, byte ptr es:[si]
0x00000000000005dd:  BE BA 03          mov       si, 0x3ba
0x00000000000005e0:  88 46 F8          mov       byte ptr [bp - 8], al
0x00000000000005e3:  24 F0             and       al, 0xf0
0x00000000000005e5:  80 66 F8 0F       and       byte ptr [bp - 8], 0xf
0x00000000000005e9:  88 04             mov       byte ptr [si], al
0x00000000000005eb:  31 C0             xor       ax, ax
0x00000000000005ed:  3B 3E 18 1C       cmp       di, word ptr [0x1c18]
0x00000000000005f1:  74 11             je        0x604
0x00000000000005f3:  40                inc       ax
0x00000000000005f4:  83 C1 02          add       cx, 2
0x00000000000005f7:  3D 04 00          cmp       ax, 4
0x00000000000005fa:  7D 6C             jge       0x668
0x00000000000005fc:  89 CE             mov       si, cx
0x00000000000005fe:  3B BC 18 1C       cmp       di, word ptr [si + 0x1c18]
0x0000000000000602:  75 EF             jne       0x5f3
0x0000000000000604:  85 C0             test      ax, ax
0x0000000000000606:  75 73             jne       0x67b
0x0000000000000608:  85 DB             test      bx, bx
0x000000000000060a:  7C 69             jl        0x675
0x000000000000060c:  BE C0 02          mov       si, 0x2c0
0x000000000000060f:  A1 10 1C          mov       ax, word ptr [0x1c10]
0x0000000000000612:  89 04             mov       word ptr [si], ax
0x0000000000000614:  8A 46 FE          mov       al, byte ptr [bp - 2]
0x0000000000000617:  3C FF             cmp       al, 0xff
0x0000000000000619:  74 5D             je        0x678
0x000000000000061b:  30 E4             xor       ah, ah
0x000000000000061d:  89 C6             mov       si, ax
0x000000000000061f:  BA 2F 8A          mov       dx, 0x8a2f
0x0000000000000622:  C1 E6 03          shl       si, 3
0x0000000000000625:  01 DB             add       bx, bx
0x0000000000000627:  8B 84 50 02       mov       ax, word ptr [si + 0x250]
0x000000000000062b:  8E C2             mov       es, dx
0x000000000000062d:  01 C3             add       bx, ax
0x000000000000062f:  26 8B 17          mov       dx, word ptr es:[bx]
0x0000000000000632:  BB 48 02          mov       bx, 0x248
0x0000000000000635:  89 07             mov       word ptr [bx], ax
0x0000000000000637:  BB C0 02          mov       bx, 0x2c0
0x000000000000063a:  8B 07             mov       ax, word ptr [bx]
0x000000000000063c:  81 C6 50 02       add       si, 0x250
0x0000000000000640:  01 D0             add       ax, dx
0x0000000000000642:  C9                LEAVE_MACRO     
0x0000000000000643:  5F                pop       di
0x0000000000000644:  5E                pop       si
0x0000000000000645:  59                pop       cx
0x0000000000000646:  5B                pop       bx
0x0000000000000647:  CB                retf      
0x0000000000000648:  BE BE 02          mov       si, 0x2be
0x000000000000064b:  89 D7             mov       di, dx
0x000000000000064d:  8B 46 F6          mov       ax, word ptr [bp - 0xa]
0x0000000000000650:  26 8B 3D          mov       di, word ptr es:[di]
0x0000000000000653:  89 04             mov       word ptr [si], ax
0x0000000000000655:  8A 46 FC          mov       al, byte ptr [bp - 4]
0x0000000000000658:  BE BC 02          mov       si, 0x2bc
0x000000000000065b:  30 E4             xor       ah, ah
0x000000000000065d:  89 04             mov       word ptr [si], ax
0x000000000000065f:  E9 56 FF          jmp       0x5b8
0x0000000000000662:  01 4E F2          add       word ptr [bp - 0xe], cx
0x0000000000000665:  E9 15 FF          jmp       0x57d
0x0000000000000668:  EB 4B             jmp       0x6b5
0x000000000000066a:  89 C2             mov       dx, ax
0x000000000000066c:  BE BE 02          mov       si, 0x2be
0x000000000000066f:  2B 56 F2          sub       dx, word ptr [bp - 0xe]
0x0000000000000672:  E9 2C FF          jmp       0x5a1
0x0000000000000675:  E9 86 00          jmp       0x6fe
0x0000000000000678:  E9 B4 00          jmp       0x72f
0x000000000000067b:  89 CE             mov       si, cx
0x000000000000067d:  8B 94 10 1C       mov       dx, word ptr [si + 0x1c10]
0x0000000000000681:  89 C1             mov       cx, ax
0x0000000000000683:  89 56 F4          mov       word ptr [bp - 0xc], dx
0x0000000000000686:  8B 94 18 1C       mov       dx, word ptr [si + 0x1c18]
0x000000000000068a:  7E 1C             jle       0x6a8
0x000000000000068c:  89 C6             mov       si, ax
0x000000000000068e:  01 C6             add       si, ax
0x0000000000000690:  83 EE 02          sub       si, 2
0x0000000000000693:  8B 84 10 1C       mov       ax, word ptr [si + 0x1c10]
0x0000000000000697:  89 84 12 1C       mov       word ptr [si + 0x1c12], ax
0x000000000000069b:  8B 84 18 1C       mov       ax, word ptr [si + 0x1c18]
0x000000000000069f:  49                dec       cx
0x00000000000006a0:  89 84 1A 1C       mov       word ptr [si + 0x1c1a], ax
0x00000000000006a4:  85 C9             test      cx, cx
0x00000000000006a6:  7F E8             jg        0x690
0x00000000000006a8:  8B 46 F4          mov       ax, word ptr [bp - 0xc]
0x00000000000006ab:  89 16 18 1C       mov       word ptr [0x1c18], dx
0x00000000000006af:  A3 10 1C          mov       word ptr [0x1c10], ax
0x00000000000006b2:  E9 53 FF          jmp       0x608
0x00000000000006b5:  A1 14 1C          mov       ax, word ptr [0x1c14]
0x00000000000006b8:  A3 16 1C          mov       word ptr [0x1c16], ax
0x00000000000006bb:  A1 12 1C          mov       ax, word ptr [0x1c12]
0x00000000000006be:  A3 14 1C          mov       word ptr [0x1c14], ax
0x00000000000006c1:  A1 10 1C          mov       ax, word ptr [0x1c10]
0x00000000000006c4:  A3 12 1C          mov       word ptr [0x1c12], ax
0x00000000000006c7:  A1 1C 1C          mov       ax, word ptr [0x1c1c]
0x00000000000006ca:  BE B8 02          mov       si, 0x2b8
0x00000000000006cd:  A3 1E 1C          mov       word ptr [0x1c1e], ax
0x00000000000006d0:  A1 1A 1C          mov       ax, word ptr [0x1c1a]
0x00000000000006d3:  8A 56 FE          mov       dl, byte ptr [bp - 2]
0x00000000000006d6:  A3 1C 1C          mov       word ptr [0x1c1c], ax
0x00000000000006d9:  A1 18 1C          mov       ax, word ptr [0x1c18]
0x00000000000006dc:  30 F6             xor       dh, dh
0x00000000000006de:  A3 1A 1C          mov       word ptr [0x1c1a], ax
0x00000000000006e1:  89 F8             mov       ax, di
0x00000000000006e3:  8B 0C             mov       cx, word ptr [si]
0x00000000000006e5:  E8 A2 0A          call      0x118a
0x00000000000006e8:  A3 10 1C          mov       word ptr [0x1c10], ax
0x00000000000006eb:  89 3E 18 1C       mov       word ptr [0x1c18], di
0x00000000000006ef:  8A 46 FC          mov       al, byte ptr [bp - 4]
0x00000000000006f2:  89 0C             mov       word ptr [si], cx
0x00000000000006f4:  BE BC 02          mov       si, 0x2bc
0x00000000000006f7:  30 E4             xor       ah, ah
0x00000000000006f9:  89 04             mov       word ptr [si], ax
0x00000000000006fb:  E9 0A FF          jmp       0x608
0x00000000000006fe:  89 FE             mov       si, di
0x0000000000000700:  B8 7E 73          mov       ax, 0x737e
0x0000000000000703:  2B 36 7E 1F       sub       si, word ptr [0x1f7e]
0x0000000000000707:  8E C0             mov       es, ax
0x0000000000000709:  01 F6             add       si, si
0x000000000000070b:  BA A2 82          mov       dx, 0x82a2
0x000000000000070e:  26 8B 04          mov       ax, word ptr es:[si]
0x0000000000000711:  8B 76 EE          mov       si, word ptr [bp - 0x12]
0x0000000000000714:  8E C2             mov       es, dx
0x0000000000000716:  26 8A 0C          mov       cl, byte ptr es:[si]
0x0000000000000719:  30 ED             xor       ch, ch
0x000000000000071b:  39 C8             cmp       ax, cx
0x000000000000071d:  77 0B             ja        0x72a
0x000000000000071f:  85 DB             test      bx, bx
0x0000000000000721:  7C 03             jl        0x726
0x0000000000000723:  E9 E6 FE          jmp       0x60c
0x0000000000000726:  01 C3             add       bx, ax
0x0000000000000728:  EB F5             jmp       0x71f
0x000000000000072a:  89 C8             mov       ax, cx
0x000000000000072c:  40                inc       ax
0x000000000000072d:  EB F0             jmp       0x71f
0x000000000000072f:  BE C2 02          mov       si, 0x2c2
0x0000000000000732:  8A 46 F8          mov       al, byte ptr [bp - 8]
0x0000000000000735:  88 04             mov       byte ptr [si], al
0x0000000000000737:  88 C4             mov       ah, al
0x0000000000000739:  88 D8             mov       al, bl
0x000000000000073b:  BB C0 02          mov       bx, 0x2c0
0x000000000000073e:  F6 E4             mul       ah
0x0000000000000740:  03 07             add       ax, word ptr [bx]
0x0000000000000742:  C9                LEAVE_MACRO     
0x0000000000000743:  5F                pop       di
0x0000000000000744:  5E                pop       si
0x0000000000000745:  59                pop       cx
0x0000000000000746:  5B                pop       bx
0x0000000000000747:  CB                retf      
0x0000000000000748:  B8 30 4F          mov       ax, 0x4f30
0x000000000000074b:  8B 5E EE          mov       bx, word ptr [bp - 0x12]
0x000000000000074e:  8E C0             mov       es, ax
0x0000000000000750:  A1 AC 06          mov       ax, word ptr [0x6ac]
0x0000000000000753:  26 8A 17          mov       dl, byte ptr es:[bx]
0x0000000000000756:  39 D8             cmp       ax, bx
0x0000000000000758:  74 40             je        0x79a
0x000000000000075a:  A1 B2 06          mov       ax, word ptr [0x6b2]
0x000000000000075d:  39 D8             cmp       ax, bx
0x000000000000075f:  74 5B             je        0x7bc
0x0000000000000761:  A1 AC 06          mov       ax, word ptr [0x6ac]
0x0000000000000764:  BB B8 02          mov       bx, 0x2b8
0x0000000000000767:  A3 B2 06          mov       word ptr [0x6b2], ax
0x000000000000076a:  A1 AE 06          mov       ax, word ptr [0x6ae]
0x000000000000076d:  8B 0F             mov       cx, word ptr [bx]
0x000000000000076f:  A3 B0 06          mov       word ptr [0x6b0], ax
0x0000000000000772:  A0 B4 06          mov       al, byte ptr [0x6b4]
0x0000000000000775:  8B 5E EE          mov       bx, word ptr [bp - 0x12]
0x0000000000000778:  A2 B5 06          mov       byte ptr [0x6b5], al
0x000000000000077b:  89 D8             mov       ax, bx
0x000000000000077d:  89 1E AC 06       mov       word ptr [0x6ac], bx
0x0000000000000781:  E8 9B 0A          call      0x121f
0x0000000000000784:  BB B8 02          mov       bx, 0x2b8
0x0000000000000787:  A3 AE 06          mov       word ptr [0x6ae], ax
0x000000000000078a:  8A 46 FC          mov       al, byte ptr [bp - 4]
0x000000000000078d:  89 0F             mov       word ptr [bx], cx
0x000000000000078f:  BB BC 02          mov       bx, 0x2bc
0x0000000000000792:  30 E4             xor       ah, ah
0x0000000000000794:  88 16 B4 06       mov       byte ptr [0x6b4], dl
0x0000000000000798:  89 07             mov       word ptr [bx], ax
0x000000000000079a:  BB BA 03          mov       bx, 0x3ba
0x000000000000079d:  88 17             mov       byte ptr [bx], dl
0x000000000000079f:  BB C2 02          mov       bx, 0x2c2
0x00000000000007a2:  88 17             mov       byte ptr [bx], dl
0x00000000000007a4:  BB C0 02          mov       bx, 0x2c0
0x00000000000007a7:  A1 AE 06          mov       ax, word ptr [0x6ae]
0x00000000000007aa:  89 07             mov       word ptr [bx], ax
0x00000000000007ac:  A0 B4 06          mov       al, byte ptr [0x6b4]
0x00000000000007af:  8A 66 FA          mov       ah, byte ptr [bp - 6]
0x00000000000007b2:  F6 E4             mul       ah
0x00000000000007b4:  03 07             add       ax, word ptr [bx]
0x00000000000007b6:  C9                LEAVE_MACRO     
0x00000000000007b7:  5F                pop       di
0x00000000000007b8:  5E                pop       si
0x00000000000007b9:  59                pop       cx
0x00000000000007ba:  5B                pop       bx
0x00000000000007bb:  CB                retf      
0x00000000000007bc:  8B 1E AC 06       mov       bx, word ptr [0x6ac]
0x00000000000007c0:  A1 B2 06          mov       ax, word ptr [0x6b2]
0x00000000000007c3:  89 5E EE          mov       word ptr [bp - 0x12], bx
0x00000000000007c6:  A3 AC 06          mov       word ptr [0x6ac], ax
0x00000000000007c9:  89 1E B2 06       mov       word ptr [0x6b2], bx
0x00000000000007cd:  8B 1E AE 06       mov       bx, word ptr [0x6ae]
0x00000000000007d1:  A1 B0 06          mov       ax, word ptr [0x6b0]
0x00000000000007d4:  89 5E EE          mov       word ptr [bp - 0x12], bx
0x00000000000007d7:  89 1E B0 06       mov       word ptr [0x6b0], bx
0x00000000000007db:  8A 1E B4 06       mov       bl, byte ptr [0x6b4]
0x00000000000007df:  A3 AE 06          mov       word ptr [0x6ae], ax
0x00000000000007e2:  30 FF             xor       bh, bh
0x00000000000007e4:  A0 B5 06          mov       al, byte ptr [0x6b5]
0x00000000000007e7:  89 5E EE          mov       word ptr [bp - 0x12], bx
0x00000000000007ea:  A2 B4 06          mov       byte ptr [0x6b4], al
0x00000000000007ed:  8A 46 EE          mov       al, byte ptr [bp - 0x12]
0x00000000000007f0:  A2 B5 06          mov       byte ptr [0x6b5], al
0x00000000000007f3:  EB A5             jmp       0x79a

ENDP

@

SCRATCH_ADDRESS_4000_SEGMENT = 04000h

PROC R_LoadPatchColumns_ NEAR
PUBLIC R_LoadPatchColumns_


push      cx
push      si
push      di
push      bp
mov       bp, sp
sub       sp, 012h
mov       si, ax
push      dx   ; bp - 12;
mov       byte ptr [bp - 2], bl
call      Z_QuickMapScratch_4000_
mov       cx, SCRATCH_ADDRESS_4000_SEGMENT
mov       ax, si
xor       bx, bx
mov       word ptr [bp - 0Ch], SCRATCH_ADDRESS_4000_SEGMENT
call      W_CacheLumpNumDirect_
xor       di, di
mov       ds, word ptr [bp - 0Ch]
xor       dx, dx
mov       ax, word ptr ds:[di]
mov       word ptr [bp - 6], di ; loop counter
mov       word ptr [bp - 8], ax
test      ax, ax
jng       label_5
mov       word ptr [bp - 0Ah], di
mov       es, word ptr [bp - 014h]

label_7:


mov       bx, word ptr [bp - 0Ah]
mov       bx, word ptr ds:[bx + 8]
cmp       byte ptr ds:[bx], 0FFh
je        label_3
do_next_post_in_column:
; es always same as bp - 0Eh at this pt...
lea       si, [bx + 3]
mov       di, dx
mov       al, byte ptr ds:[bx + 1]
xor       ah, ah  ; todo cbw?

mov       cx, ax
add       dx, cx
shr       cx, 1
rep movsw 
adc       cx, cx
rep movsb 
mov       cx, ax  ; restore length in cx
cmp       byte ptr [bp - 2], 0
je        skip_segment_alignment_1

; adjust col offset
mov       ah, cl
and       ah, 0Fh 
mov       al, 16
sub       al, ah
and       ax, 0Fh
add       dx, ax
skip_segment_alignment_1:
add       bx, cx
add       bx, 4
cmp       byte ptr ds:[bx], 0FFh
jne       do_next_post_in_column
label_3:
cmp       byte ptr [bp - 2], 0
jne       skip_segment_alignment_2
; adjust col offset
mov       ah, dl
and       ah, 0Fh 
mov       al, 16
sub       al, ah
and       ax, 0Fh
add       dx, ax

skip_segment_alignment_2:
inc       word ptr [bp - 6]
mov       ax, word ptr [bp - 6]
add       word ptr [bp - 0Ah], 4
cmp       ax, word ptr [bp - 8]
jnge       label_7
; restore ds
label_5:
push      ss
pop       ds
call      Z_QuickMapRender4000_
LEAVE_MACRO     
pop       di
pop       si
pop       cx
ret       


ENDP

COMMENT @



PROC R_LoadSpriteColumns_ NEAR
PUBLIC R_LoadSpriteColumns_


0x00000000000008e8:  53                push      bx
0x00000000000008e9:  51                push      cx
0x00000000000008ea:  56                push      si
0x00000000000008eb:  57                push      di
0x00000000000008ec:  55                push      bp
0x00000000000008ed:  89 E5             mov       bp, sp
0x00000000000008ef:  83 EC 1C          sub       sp, 0x1c
0x00000000000008f2:  50                push      ax
0x00000000000008f3:  0E                push      cs
0x00000000000008f4:  3E E8 28 3F       call      0x4820
0x00000000000008f8:  B9 00 50          mov       cx, 0x5000
0x00000000000008fb:  8B 46 E2          mov       ax, word ptr [bp - 0x1e]
0x00000000000008fe:  31 DB             xor       bx, bx
0x0000000000000900:  C7 46 EC 00 50    mov       word ptr [bp - 0x14], 0x5000
0x0000000000000905:  0E                push      cs
0x0000000000000906:  3E E8 1A 36       call      W_CacheLumpNumDirect_
0x000000000000090a:  31 FF             xor       di, di
0x000000000000090c:  8E 46 EC          mov       es, word ptr [bp - 0x14]
0x000000000000090f:  31 F6             xor       si, si
0x0000000000000911:  26 8B 05          mov       ax, word ptr es:[di]
0x0000000000000914:  8E C2             mov       es, dx
0x0000000000000916:  26 89 04          mov       word ptr es:[si], ax
0x0000000000000919:  8E 46 EC          mov       es, word ptr [bp - 0x14]
0x000000000000091c:  89 46 EE          mov       word ptr [bp - 0x12], ax
0x000000000000091f:  26 8B 45 02       mov       ax, word ptr es:[di + 2]
0x0000000000000923:  8E C2             mov       es, dx
0x0000000000000925:  26 89 44 02       mov       word ptr es:[si + 2], ax
0x0000000000000929:  8E 46 EC          mov       es, word ptr [bp - 0x14]
0x000000000000092c:  26 8B 45 04       mov       ax, word ptr es:[di + 4]
0x0000000000000930:  8E C2             mov       es, dx
0x0000000000000932:  26 89 44 04       mov       word ptr es:[si + 4], ax
0x0000000000000936:  8E 46 EC          mov       es, word ptr [bp - 0x14]
0x0000000000000939:  26 8B 45 06       mov       ax, word ptr es:[di + 6]
0x000000000000093d:  8E C2             mov       es, dx
0x000000000000093f:  26 89 44 06       mov       word ptr es:[si + 6], ax
0x0000000000000943:  BE E6 00          mov       si, 0xe6
0x0000000000000946:  8B 46 E2          mov       ax, word ptr [bp - 0x1e]
0x0000000000000949:  8B 5E EE          mov       bx, word ptr [bp - 0x12]
0x000000000000094c:  2B 04             sub       ax, word ptr [si]
0x000000000000094e:  C1 E3 02          shl       bx, 2
0x0000000000000951:  89 C6             mov       si, ax
0x0000000000000953:  83 C3 08          add       bx, 8
0x0000000000000956:  01 C6             add       si, ax
0x0000000000000958:  B8 FD 87          mov       ax, 0x87fd
0x000000000000095b:  89 5E FC          mov       word ptr [bp - 4], bx
0x000000000000095e:  8E C0             mov       es, ax
0x0000000000000960:  89 5E E6          mov       word ptr [bp - 0x1a], bx
0x0000000000000963:  26 03 1C          add       bx, word ptr es:[si]
0x0000000000000966:  89 D8             mov       ax, bx
0x0000000000000968:  30 FC             xor       ah, bh
0x000000000000096a:  BE 10 00          mov       si, 0x10
0x000000000000096d:  24 0F             and       al, 0xf
0x000000000000096f:  29 C6             sub       si, ax
0x0000000000000971:  C7 46 F6 08 00    mov       word ptr [bp - 0xa], 8
0x0000000000000976:  89 F0             mov       ax, si
0x0000000000000978:  30 E4             xor       ah, ah
0x000000000000097a:  89 56 EA          mov       word ptr [bp - 0x16], dx
0x000000000000097d:  24 0F             and       al, 0xf
0x000000000000097f:  89 56 FA          mov       word ptr [bp - 6], dx
0x0000000000000982:  01 C3             add       bx, ax
0x0000000000000984:  89 56 F8          mov       word ptr [bp - 8], dx
0x0000000000000987:  89 5E E8          mov       word ptr [bp - 0x18], bx
0x000000000000098a:  30 C0             xor       al, al
0x000000000000098c:  89 5E FE          mov       word ptr [bp - 2], bx
0x000000000000098f:  89 46 F4          mov       word ptr [bp - 0Ch], ax
0x0000000000000992:  83 7E EE 00       cmp       word ptr [bp - 0x12], 0
0x0000000000000996:  7F 03             jg        0x99b
0x0000000000000998:  E9 D0 00          jmp       0xa6b
0x000000000000099b:  C7 46 E4 00 50    mov       word ptr [bp - 0x1c], 0x5000
0x00000000000009a0:  89 7E F2          mov       word ptr [bp - 0xe], di
0x00000000000009a3:  8E 46 E4          mov       es, word ptr [bp - 0x1c]
0x00000000000009a6:  8B 76 F2          mov       si, word ptr [bp - 0xe]
0x00000000000009a9:  BA 00 50          mov       dx, 0x5000
0x00000000000009ac:  8B 46 E8          mov       ax, word ptr [bp - 0x18]
0x00000000000009af:  8B 7E F6          mov       di, word ptr [bp - 0xa]
0x00000000000009b2:  83 46 F6 02       add       word ptr [bp - 0xa], 2
0x00000000000009b6:  C1 E8 04          shr       ax, 4
0x00000000000009b9:  26 8B 74 08       mov       si, word ptr es:[si + 8]
0x00000000000009bd:  8E 46 EA          mov       es, word ptr [bp - 0x16]
0x00000000000009c0:  89 56 F0          mov       word ptr [bp - 0x10], dx
0x00000000000009c3:  26 89 05          mov       word ptr es:[di], ax
0x00000000000009c6:  8B 46 FC          mov       ax, word ptr [bp - 4]
0x00000000000009c9:  8B 7E F6          mov       di, word ptr [bp - 0xa]
0x00000000000009cc:  89 F3             mov       bx, si
0x00000000000009ce:  26 89 05          mov       word ptr es:[di], ax
0x00000000000009d1:  8E C2             mov       es, dx
0x00000000000009d3:  83 46 F6 02       add       word ptr [bp - 0xa], 2
0x00000000000009d7:  26 80 3C FF       cmp       byte ptr es:[si], 0xff
0x00000000000009db:  74 69             je        0xa46
0x00000000000009dd:  8E 46 F0          mov       es, word ptr [bp - 0x10]
0x00000000000009e0:  B9 00 50          mov       cx, 0x5000
0x00000000000009e3:  8B 7E FE          mov       di, word ptr [bp - 2]
0x00000000000009e6:  26 8A 57 01       mov       dl, byte ptr es:[bx + 1]
0x00000000000009ea:  89 DE             mov       si, bx
0x00000000000009ec:  88 D0             mov       al, dl
0x00000000000009ee:  8E 46 F8          mov       es, word ptr [bp - 8]
0x00000000000009f1:  30 E4             xor       ah, ah
0x00000000000009f3:  83 C6 03          add       si, 3
0x00000000000009f6:  1E                push      ds
0x00000000000009f7:  57                push      di
0x00000000000009f8:  91                xchg      ax, cx
0x00000000000009f9:  8E D8             mov       ds, ax
0x00000000000009fb:  D1 E9             shr       cx, 1
0x00000000000009fd:  F3 A5             rep movsw word ptr es:[di], word ptr [si]
0x00000000000009ff:  13 C9             adc       cx, cx
0x0000000000000a01:  F3 A4             rep movsb byte ptr es:[di], byte ptr [si]
0x0000000000000a03:  5F                pop       di
0x0000000000000a04:  1F                pop       ds
0x0000000000000a05:  88 D0             mov       al, dl
0x0000000000000a07:  24 0F             and       al, 0xf
0x0000000000000a09:  B4 10             mov       ah, 0x10
0x0000000000000a0b:  28 C4             sub       ah, al
0x0000000000000a0d:  88 E0             mov       al, ah
0x0000000000000a0f:  24 0F             and       al, 0xf
0x0000000000000a11:  00 D0             add       al, dl
0x0000000000000a13:  8E 46 F0          mov       es, word ptr [bp - 0x10]
0x0000000000000a16:  30 E4             xor       ah, ah
0x0000000000000a18:  8B 76 E6          mov       si, word ptr [bp - 0x1a]
0x0000000000000a1b:  01 46 E8          add       word ptr [bp - 0x18], ax
0x0000000000000a1e:  01 46 FE          add       word ptr [bp - 2], ax
0x0000000000000a21:  26 8B 07          mov       ax, word ptr es:[bx]
0x0000000000000a24:  8E 46 FA          mov       es, word ptr [bp - 6]
0x0000000000000a27:  26 89 04          mov       word ptr es:[si], ax
0x0000000000000a2a:  8E 46 F0          mov       es, word ptr [bp - 0x10]
0x0000000000000a2d:  26 8A 47 01       mov       al, byte ptr es:[bx + 1]
0x0000000000000a31:  30 E4             xor       ah, ah
0x0000000000000a33:  01 C3             add       bx, ax
0x0000000000000a35:  83 46 FC 02       add       word ptr [bp - 4], 2
0x0000000000000a39:  83 C3 04          add       bx, 4
0x0000000000000a3c:  83 46 E6 02       add       word ptr [bp - 0x1a], 2
0x0000000000000a40:  26 80 3F FF       cmp       byte ptr es:[bx], 0xff
0x0000000000000a44:  75 97             jne       0x9dd
0x0000000000000a46:  8E 46 FA          mov       es, word ptr [bp - 6]
0x0000000000000a49:  8B 5E E6          mov       bx, word ptr [bp - 0x1a]
0x0000000000000a4c:  83 46 FC 02       add       word ptr [bp - 4], 2
0x0000000000000a50:  83 46 F2 04       add       word ptr [bp - 0xe], 4
0x0000000000000a54:  FF 46 F4          inc       word ptr [bp - 0Ch]
0x0000000000000a57:  83 46 E6 02       add       word ptr [bp - 0x1a], 2
0x0000000000000a5b:  8B 46 F4          mov       ax, word ptr [bp - 0Ch]
0x0000000000000a5e:  26 C7 07 FF FF    mov       word ptr es:[bx], 0xffff
0x0000000000000a63:  3B 46 EE          cmp       ax, word ptr [bp - 0x12]
0x0000000000000a66:  7D 03             jge       0xa6b
0x0000000000000a68:  E9 38 FF          jmp       0x9a3
0x0000000000000a6b:  0E                push      cs
0x0000000000000a6c:  3E E8 4E 3D       call      0x47be
0x0000000000000a70:  C9                LEAVE_MACRO     
0x0000000000000a71:  5F                pop       di
0x0000000000000a72:  5E                pop       si
0x0000000000000a73:  59                pop       cx
0x0000000000000a74:  5B                pop       bx
0x0000000000000a75:  CB                retf      
0x0000000000000a76:  8A 26 44 1E       mov       ah, byte ptr [0x1e44]
0x0000000000000a7a:  3A C4             cmp       al, ah
0x0000000000000a7c:  74 17             je        0xa95
0x0000000000000a7e:  A2 44 1E          mov       byte ptr [0x1e44], al
0x0000000000000a81:  86 26 45 1E       xchg      byte ptr [0x1e45], ah
0x0000000000000a85:  3A C4             cmp       al, ah
0x0000000000000a87:  74 0C             je        0xa95
0x0000000000000a89:  86 26 46 1E       xchg      byte ptr [0x1e46], ah
0x0000000000000a8d:  3A C4             cmp       al, ah
0x0000000000000a8f:  74 04             je        0xa95
0x0000000000000a91:  86 26 47 1E       xchg      byte ptr [0x1e47], ah
0x0000000000000a95:  C3                ret       
0x0000000000000a96:  FF 36 45 1E       push      word ptr [0x1e45]
0x0000000000000a9a:  8F 06 46 1E       pop       word ptr [0x1e46]
0x0000000000000a9e:  86 06 44 1E       xchg      byte ptr [0x1e44], al
0x0000000000000aa2:  A2 45 1E          mov       byte ptr [0x1e45], al
0x0000000000000aa5:  C3                ret       
0x0000000000000aa6:  8A 26 30 1C       mov       ah, byte ptr [0x1c30]
0x0000000000000aaa:  3A C4             cmp       al, ah
0x0000000000000aac:  74 37             je        0xae5
0x0000000000000aae:  A2 30 1C          mov       byte ptr [0x1c30], al
0x0000000000000ab1:  86 26 31 1C       xchg      byte ptr [0x1c31], ah
0x0000000000000ab5:  3A C4             cmp       al, ah
0x0000000000000ab7:  74 2C             je        0xae5
0x0000000000000ab9:  86 26 32 1C       xchg      byte ptr [0x1c32], ah
0x0000000000000abd:  3A C4             cmp       al, ah
0x0000000000000abf:  74 24             je        0xae5
0x0000000000000ac1:  86 26 33 1C       xchg      byte ptr [0x1c33], ah
0x0000000000000ac5:  3A C4             cmp       al, ah
0x0000000000000ac7:  74 1C             je        0xae5
0x0000000000000ac9:  86 26 34 1C       xchg      byte ptr [0x1c34], ah
0x0000000000000acd:  3A C4             cmp       al, ah
0x0000000000000acf:  74 14             je        0xae5
0x0000000000000ad1:  86 26 35 1C       xchg      byte ptr [0x1c35], ah
0x0000000000000ad5:  3A C4             cmp       al, ah
0x0000000000000ad7:  74 0C             je        0xae5
0x0000000000000ad9:  86 26 36 1C       xchg      byte ptr [0x1c36], ah
0x0000000000000add:  3A C4             cmp       al, ah
0x0000000000000adf:  74 04             je        0xae5
0x0000000000000ae1:  86 26 37 1C       xchg      byte ptr [0x1c37], ah
0x0000000000000ae5:  C3                ret       
0x0000000000000ae6:  FF 36 35 1C       push      word ptr [0x1c35]
0x0000000000000aea:  8F 06 36 1C       pop       word ptr [0x1c36]
0x0000000000000aee:  FF 36 33 1C       push      word ptr [0x1c33]
0x0000000000000af2:  8F 06 34 1C       pop       word ptr [0x1c34]
0x0000000000000af6:  FF 36 31 1C       push      word ptr [0x1c31]
0x0000000000000afa:  8F 06 32 1C       pop       word ptr [0x1c32]
0x0000000000000afe:  86 06 30 1C       xchg      byte ptr [0x1c30], al
0x0000000000000b02:  A2 31 1C          mov       byte ptr [0x1c31], al
0x0000000000000b05:  C3                ret       
0x0000000000000b06:  3A 06 AA 06       cmp       al, byte ptr [0x6aa]
0x0000000000000b0a:  75 01             jne       0xb0d
0x0000000000000b0c:  C3                ret       
0x0000000000000b0d:  60                pushaw    
0x0000000000000b0e:  BE 08 18          mov       si, 0x1808
0x0000000000000b11:  BF AB 06          mov       di, 0x6ab
0x0000000000000b14:  8E C7             mov       es, di
0x0000000000000b16:  BF AA 06          mov       di, 0x6aa
0x0000000000000b19:  EB 13             jmp       0xb2e
0x0000000000000b1b:  3A 06 A6 06       cmp       al, byte ptr [0x6a6]
0x0000000000000b1f:  75 01             jne       0xb22
0x0000000000000b21:  C3                ret       
0x0000000000000b22:  60                pushaw    
0x0000000000000b23:  BE 68 18          mov       si, 0x1868
0x0000000000000b26:  BF A7 06          mov       di, 0x6a7
0x0000000000000b29:  8E C7             mov       es, di
0x0000000000000b2b:  BF A6 06          mov       di, 0x6a6
0x0000000000000b2e:  8A 0D             mov       cl, byte ptr [di]
0x0000000000000b30:  8A D0             mov       dl, al
0x0000000000000b32:  8B D8             mov       bx, ax
0x0000000000000b34:  D1 E3             shl       bx, 1
0x0000000000000b36:  D1 E3             shl       bx, 1
0x0000000000000b38:  8A 40 02          mov       al, byte ptr [bx + si + 2]
0x0000000000000b3b:  84 C0             test      al, al
0x0000000000000b3d:  74 16             je        0xb55
0x0000000000000b3f:  8A DA             mov       bl, dl
0x0000000000000b41:  D1 E3             shl       bx, 1
0x0000000000000b43:  D1 E3             shl       bx, 1
0x0000000000000b45:  8B 40 02          mov       ax, word ptr [bx + si + 2]
0x0000000000000b48:  3A C4             cmp       al, ah
0x0000000000000b4a:  74 05             je        0xb51
0x0000000000000b4c:  8A 50 01          mov       dl, byte ptr [bx + si + 1]
0x0000000000000b4f:  EB EE             jmp       0xb3f
0x0000000000000b51:  3A D1             cmp       dl, cl
0x0000000000000b53:  74 6A             je        0xbbf
0x0000000000000b55:  80 78 03 00       cmp       byte ptr [bx + si + 3], 0
0x0000000000000b59:  74 66             je        0xbc1
0x0000000000000b5b:  8A F2             mov       dh, dl
0x0000000000000b5d:  8A DE             mov       bl, dh
0x0000000000000b5f:  D1 E3             shl       bx, 1
0x0000000000000b61:  D1 E3             shl       bx, 1
0x0000000000000b63:  80 78 02 01       cmp       byte ptr [bx + si + 2], 1
0x0000000000000b67:  74 04             je        0xb6d
0x0000000000000b69:  8A 30             mov       dh, byte ptr [bx + si]
0x0000000000000b6b:  EB F0             jmp       0xb5d
0x0000000000000b6d:  8A 28             mov       ch, byte ptr [bx + si]
0x0000000000000b6f:  8A DA             mov       bl, dl
0x0000000000000b71:  D1 E3             shl       bx, 1
0x0000000000000b73:  D1 E3             shl       bx, 1
0x0000000000000b75:  8A 48 01          mov       cl, byte ptr [bx + si + 1]
0x0000000000000b78:  8C C3             mov       bx, es
0x0000000000000b7a:  3A 37             cmp       dh, byte ptr [bx]
0x0000000000000b7c:  75 0F             jne       0xb8d
0x0000000000000b7e:  88 0F             mov       byte ptr [bx], cl
0x0000000000000b80:  33 DB             xor       bx, bx
0x0000000000000b82:  8A D9             mov       bl, cl
0x0000000000000b84:  D1 E3             shl       bx, 1
0x0000000000000b86:  D1 E3             shl       bx, 1
0x0000000000000b88:  C6 00 FF          mov       byte ptr [bx + si], 0xff
0x0000000000000b8b:  EB 13             jmp       0xba0
0x0000000000000b8d:  33 DB             xor       bx, bx
0x0000000000000b8f:  8A DD             mov       bl, ch
0x0000000000000b91:  D1 E3             shl       bx, 1
0x0000000000000b93:  D1 E3             shl       bx, 1
0x0000000000000b95:  88 48 01          mov       byte ptr [bx + si + 1], cl
0x0000000000000b98:  8A D9             mov       bl, cl
0x0000000000000b9a:  D1 E3             shl       bx, 1
0x0000000000000b9c:  D1 E3             shl       bx, 1
0x0000000000000b9e:  88 28             mov       byte ptr [bx + si], ch
0x0000000000000ba0:  8A DE             mov       bl, dh
0x0000000000000ba2:  D1 E3             shl       bx, 1
0x0000000000000ba4:  D1 E3             shl       bx, 1
0x0000000000000ba6:  8A 05             mov       al, byte ptr [di]
0x0000000000000ba8:  88 00             mov       byte ptr [bx + si], al
0x0000000000000baa:  8A D8             mov       bl, al
0x0000000000000bac:  D1 E3             shl       bx, 1
0x0000000000000bae:  D1 E3             shl       bx, 1
0x0000000000000bb0:  88 70 01          mov       byte ptr [bx + si + 1], dh
0x0000000000000bb3:  8A DA             mov       bl, dl
0x0000000000000bb5:  D1 E3             shl       bx, 1
0x0000000000000bb7:  D1 E3             shl       bx, 1
0x0000000000000bb9:  88 15             mov       byte ptr [di], dl
0x0000000000000bbb:  C6 40 01 FF       mov       byte ptr [bx + si + 1], 0xff
0x0000000000000bbf:  61                popaw     
0x0000000000000bc0:  C3                ret       
0x0000000000000bc1:  8A 70 01          mov       dh, byte ptr [bx + si + 1]
0x0000000000000bc4:  8A 28             mov       ch, byte ptr [bx + si]
0x0000000000000bc6:  8C C3             mov       bx, es
0x0000000000000bc8:  3A 17             cmp       dl, byte ptr [bx]
0x0000000000000bca:  75 06             jne       0xbd2
0x0000000000000bcc:  88 37             mov       byte ptr [bx], dh
0x0000000000000bce:  33 DB             xor       bx, bx
0x0000000000000bd0:  EB 0B             jmp       0xbdd
0x0000000000000bd2:  33 DB             xor       bx, bx
0x0000000000000bd4:  8A DD             mov       bl, ch
0x0000000000000bd6:  D1 E3             shl       bx, 1
0x0000000000000bd8:  D1 E3             shl       bx, 1
0x0000000000000bda:  88 70 01          mov       byte ptr [bx + si + 1], dh
0x0000000000000bdd:  8A DE             mov       bl, dh
0x0000000000000bdf:  D1 E3             shl       bx, 1
0x0000000000000be1:  D1 E3             shl       bx, 1
0x0000000000000be3:  88 28             mov       byte ptr [bx + si], ch
0x0000000000000be5:  8A DA             mov       bl, dl
0x0000000000000be7:  D1 E3             shl       bx, 1
0x0000000000000be9:  D1 E3             shl       bx, 1
0x0000000000000beb:  B5 FF             mov       ch, 0xff
0x0000000000000bed:  89 08             mov       word ptr [bx + si], cx
0x0000000000000bef:  8A D9             mov       bl, cl
0x0000000000000bf1:  D1 E3             shl       bx, 1
0x0000000000000bf3:  D1 E3             shl       bx, 1
0x0000000000000bf5:  88 50 01          mov       byte ptr [bx + si + 1], dl
0x0000000000000bf8:  88 15             mov       byte ptr [di], dl
0x0000000000000bfa:  61                popaw    

ENDP

@

END
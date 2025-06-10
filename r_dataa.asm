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
EXTRN Z_QuickMapScratch_4000_:FAR ; todo
EXTRN Z_QuickMapScratch_5000_:FAR
EXTRN W_CacheLumpNumDirect_:FAR
EXTRN Z_QuickMapRender4000_:FAR
EXTRN Z_QuickMapRender5000_:FAR

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


EXTRN _cachedcollength:WORD
EXTRN _cachedcollength2:WORD
EXTRN _cachedsegmenttex:WORD
EXTRN _cachedsegmenttex2:WORD
EXTRN _segloopnextlookup:WORD
EXTRN _segloopprevlookup:WORD
EXTRN _segloopcachedsegment:WORD
EXTRN _segloopcachedbasecol:WORD
EXTRN _segloopheightvalcache:WORD
EXTRN _cachedsegmentlumps:WORD

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
0x0000000000000007:  83 EC 32          sub       sp, 032h
0x000000000000000a:  52                push      dx
0x000000000000000b:  89 C3             mov       bx, ax
0x000000000000000d:  01 C3             add       bx, ax
0x000000000000000f:  B8 2D 93          mov       ax, TEXTUREDEFS_OFFSET_SEGMENT
0x0000000000000012:  BA B2 90          mov       dx, TEXTUREDEFS_BYTES_SEGMENT
0x0000000000000015:  8E C0             mov       es, ax
0x0000000000000017:  89 5E CE          mov       word ptr [bp - 032h], bx
0x000000000000001a:  26 8B 1F          mov       bx, word ptr es:[bx]
0x000000000000001d:  8E C2             mov       es, dx
0x000000000000001f:  26 8A 47 08       mov       al, byte ptr es:[bx + 8]
0x0000000000000023:  30 E4             xor       ah, ah
0x0000000000000025:  40                inc       ax
0x0000000000000026:  89 46 E0          mov       word ptr [bp - 020h], ax
0x0000000000000029:  26 8A 47 09       mov       al, byte ptr es:[bx + 9]
0x000000000000002d:  FE C0             inc       al
0x000000000000002f:  C7 46 E8 FF FF    mov       word ptr [bp - 018h], 0xffff
0x0000000000000034:  88 46 F6          mov       byte ptr [bp - 0Ah], al
0x0000000000000037:  24 0F             and       al, 0Fh
0x0000000000000039:  C7 46 D0 00 00    mov       word ptr [bp - 030h], 0
0x000000000000003e:  B4 10             mov       ah, 0x10
0x0000000000000040:  C7 46 EC 00 90    mov       word ptr [bp - 014h], 0x9000
0x0000000000000045:  28 C4             sub       ah, al
0x0000000000000047:  C7 46 E2 00 00    mov       word ptr [bp - 01Eh], 0
0x000000000000004c:  88 E0             mov       al, ah
0x000000000000004e:  89 56 DE          mov       word ptr [bp - 022h], dx
0x0000000000000051:  24 0F             and       al, 0Fh
0x0000000000000053:  8B 76 CE          mov       si, word ptr [bp - 032h]
0x0000000000000056:  8A 66 F6          mov       ah, byte ptr [bp - 0Ah]
0x0000000000000059:  81 C6 F0 EA       add       si, _texturepatchlump_offset
0x000000000000005d:  00 C4             add       ah, al
0x000000000000005f:  83 C3 0B          add       bx, 0xb
0x0000000000000062:  88 66 FA          mov       byte ptr [bp - 6], ah
0x0000000000000065:  88 E0             mov       al, ah
0x0000000000000067:  89 5E E6          mov       word ptr [bp - 01Ah], bx
0x000000000000006a:  30 E4             xor       ah, ah
0x000000000000006c:  8B 34             mov       si, word ptr [si]
0x000000000000006e:  C1 F8 04          sar       ax, 4
0x0000000000000071:  01 F6             add       si, si
0x0000000000000073:  88 46 FA          mov       byte ptr [bp - 6], al
0x0000000000000076:  26 8A 47 FF       mov       al, byte ptr es:[bx - 1]
0x000000000000007a:  89 76 EA          mov       word ptr [bp - 016h], si
0x000000000000007d:  88 46 FE          mov       byte ptr [bp - 2], al
0x0000000000000080:  0E                push      cs
0x0000000000000081:  E8 B4 47          call      0x4838
0x0000000000000084:  90                nop       
0x0000000000000085:  8A 46 FE          mov       al, byte ptr [bp - 2]
0x0000000000000088:  30 E4             xor       ah, ah
0x000000000000008a:  3B 46 E2          cmp       ax, word ptr [bp - 01Eh]
0x000000000000008d:  7F 03             jg        0x92
0x000000000000008f:  E9 A0 01          jmp       0x232
0x0000000000000092:  8B 76 E6          mov       si, word ptr [bp - 01Ah]
0x0000000000000095:  8B 46 DE          mov       ax, word ptr [bp - 022h]
0x0000000000000098:  8E 46 DE          mov       es, word ptr [bp - 022h]
0x000000000000009b:  89 F3             mov       bx, si
0x000000000000009d:  31 FF             xor       di, di
0x000000000000009f:  26 8B 57 02       mov       dx, word ptr es:[bx + 2]
0x00000000000000a3:  89 46 E4          mov       word ptr [bp - 01Ch], ax
0x00000000000000a6:  80 E6 7F          and       dh, 0x7f
0x00000000000000a9:  8B 46 E8          mov       ax, word ptr [bp - 018h]
0x00000000000000ac:  89 56 E8          mov       word ptr [bp - 018h], dx
0x00000000000000af:  39 D0             cmp       ax, dx
0x00000000000000b1:  74 0C             je        0xbf
0x00000000000000b3:  B9 00 70          mov       cx, 0x7000
0x00000000000000b6:  89 D0             mov       ax, dx
0x00000000000000b8:  31 F3             xor       bx, si
0x00000000000000ba:  0E                push      cs
0x00000000000000bb:  E8 66 3E          call      W_CacheLumpNumDirect_
0x00000000000000be:  90                nop       
0x00000000000000bf:  8E 46 E4          mov       es, word ptr [bp - 01Ch]
0x00000000000000c2:  26 F6 44 03 80    test      byte ptr es:[si + 3], 0x80
0x00000000000000c7:  75 03             jne       label_60
0x00000000000000c9:  E9 A1 00          jmp       0x16d
label_60:
0x00000000000000cc:  BB FF FF          mov       bx, 0xffff
0x00000000000000cf:  8E 46 E4          mov       es, word ptr [bp - 01Ch]
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
0x00000000000000ee:  89 5E D2          mov       word ptr [bp - 02Eh], bx
0x00000000000000f1:  85 C0             test      ax, ax
0x00000000000000f3:  7D 03             jge       0xf8
0x00000000000000f5:  E9 7B 00          jmp       0x173
0x00000000000000f8:  89 46 D8          mov       word ptr [bp - 028h], ax
0x00000000000000fb:  8B 46 D2          mov       ax, word ptr [bp - 02Eh]
0x00000000000000fe:  3B 46 E0          cmp       ax, word ptr [bp - 020h]
0x0000000000000101:  7E 06             jle       0x109
0x0000000000000103:  8B 46 E0          mov       ax, word ptr [bp - 020h]
0x0000000000000106:  89 46 D2          mov       word ptr [bp - 02Eh], ax
0x0000000000000109:  89 FB             mov       bx, di
0x000000000000010b:  01 FB             add       bx, di
0x000000000000010d:  8E 46 EC          mov       es, word ptr [bp - 014h]
0x0000000000000110:  03 5E EA          add       bx, word ptr [bp - 016h]
0x0000000000000113:  26 8B 07          mov       ax, word ptr es:[bx]
0x0000000000000116:  89 46 DC          mov       word ptr [bp - 024h], ax
0x0000000000000119:  26 8A 47 02       mov       al, byte ptr es:[bx + 2]
0x000000000000011d:  30 E4             xor       ah, ah
0x000000000000011f:  89 C6             mov       si, ax
0x0000000000000121:  8B 46 CC          mov       ax, word ptr [bp - 034h]
0x0000000000000124:  46                inc       si
0x0000000000000125:  89 46 F2          mov       word ptr [bp - 0Eh], ax
0x0000000000000128:  83 7E D8 00       cmp       word ptr [bp - 028h], 0
0x000000000000012c:  74 6B             je        0x199
0x000000000000012e:  8B 5E EA          mov       bx, word ptr [bp - 016h]
0x0000000000000131:  26 8B 07          mov       ax, word ptr es:[bx]
0x0000000000000134:  89 46 F0          mov       word ptr [bp - 010h], ax
0x0000000000000137:  26 8A 47 02       mov       al, byte ptr es:[bx + 2]
0x000000000000013b:  C6 46 F4 00       mov       byte ptr [bp - 0Ch], 0
0x000000000000013f:  30 E4             xor       ah, ah
0x0000000000000141:  C6 46 F8 00       mov       byte ptr [bp - 8], 0
0x0000000000000145:  40                inc       ax
0x0000000000000146:  8A 4E F4          mov       cl, byte ptr [bp - 0Ch]
0x0000000000000149:  30 ED             xor       ch, ch
0x000000000000014b:  01 C1             add       cx, ax
0x000000000000014d:  3B 4E D8          cmp       cx, word ptr [bp - 028h]
0x0000000000000150:  7D 2D             jge       0x17f
0x0000000000000152:  83 7E F0 FF       cmp       word ptr [bp - 010h], -1
0x0000000000000156:  74 22             je        0x17a
0x0000000000000158:  00 46 F4          add       byte ptr [bp - 0Ch], al
0x000000000000015b:  26 8B 47 04       mov       ax, word ptr es:[bx + 4]
0x000000000000015f:  89 46 F0          mov       word ptr [bp - 010h], ax
0x0000000000000162:  26 8A 47 06       mov       al, byte ptr es:[bx + 6]
0x0000000000000166:  30 E4             xor       ah, ah
0x0000000000000168:  83 C3 04          add       bx, 4
0x000000000000016b:  EB D8             jmp       0x145
0x000000000000016d:  BB 01 00          mov       bx, 1
0x0000000000000170:  E9 5C FF          jmp       0xcf
0x0000000000000173:  C7 46 D8 00 00    mov       word ptr [bp - 028h], 0
0x0000000000000178:  EB 81             jmp       0xfb
0x000000000000017a:  00 46 F8          add       byte ptr [bp - 8], al
0x000000000000017d:  EB D9             jmp       0x158
0x000000000000017f:  83 7E F0 FF       cmp       word ptr [bp - 010h], -1
0x0000000000000183:  75 09             jne       0x18e
0x0000000000000185:  8A 46 D8          mov       al, byte ptr [bp - 028h]
0x0000000000000188:  2A 46 F4          sub       al, byte ptr [bp - 0Ch]
0x000000000000018b:  00 46 F8          add       byte ptr [bp - 8], al
0x000000000000018e:  8A 66 F8          mov       ah, byte ptr [bp - 8]
0x0000000000000191:  8A 46 FA          mov       al, byte ptr [bp - 6]
0x0000000000000194:  F6 E4             mul       ah
0x0000000000000196:  01 46 F2          add       word ptr [bp - 0Eh], ax
0x0000000000000199:  89 D3             mov       bx, dx
0x000000000000019b:  8B 46 D8          mov       ax, word ptr [bp - 028h]
0x000000000000019e:  C1 E3 02          shl       bx, 2
0x00000000000001a1:  C1 E0 02          shl       ax, 2
0x00000000000001a4:  F7 DB             neg       bx
0x00000000000001a6:  01 D8             add       ax, bx
0x00000000000001a8:  8B 5E EA          mov       bx, word ptr [bp - 016h]
0x00000000000001ab:  89 46 D6          mov       word ptr [bp - 02Ah], ax
0x00000000000001ae:  8B 46 EC          mov       ax, word ptr [bp - 014h]
0x00000000000001b1:  89 5E DA          mov       word ptr [bp - 026h], bx
0x00000000000001b4:  89 46 EE          mov       word ptr [bp - 012h], ax
0x00000000000001b7:  8B 46 D8          mov       ax, word ptr [bp - 028h]
0x00000000000001ba:  3B 46 D2          cmp       ax, word ptr [bp - 02Eh]
0x00000000000001bd:  7D 69             jge       0x228
0x00000000000001bf:  8B 5E DA          mov       bx, word ptr [bp - 026h]
0x00000000000001c2:  89 F8             mov       ax, di
0x00000000000001c4:  8B 56 EE          mov       dx, word ptr [bp - 012h]
0x00000000000001c7:  01 F8             add       ax, di
0x00000000000001c9:  8E C2             mov       es, dx
0x00000000000001cb:  01 C3             add       bx, ax
0x00000000000001cd:  3B 76 D8          cmp       si, word ptr [bp - 028h]
0x00000000000001d0:  7F 18             jg        0x1ea
0x00000000000001d2:  26 8B 47 04       mov       ax, word ptr es:[bx + 4]
0x00000000000001d6:  89 46 DC          mov       word ptr [bp - 024h], ax
0x00000000000001d9:  26 8A 47 06       mov       al, byte ptr es:[bx + 6]
0x00000000000001dd:  30 E4             xor       ah, ah
0x00000000000001df:  83 C3 04          add       bx, 4
0x00000000000001e2:  40                inc       ax
0x00000000000001e3:  83 C7 02          add       di, 2
0x00000000000001e6:  01 C6             add       si, ax
0x00000000000001e8:  EB E3             jmp       0x1cd
0x00000000000001ea:  83 7E DC 00       cmp       word ptr [bp - 024h], 0
0x00000000000001ee:  7C 09             jl        0x1f9
0x00000000000001f0:  83 46 D6 04       add       word ptr [bp - 02Ah], 4
0x00000000000001f4:  FF 46 D8          inc       word ptr [bp - 028h]
0x00000000000001f7:  EB BE             jmp       0x1b7
0x00000000000001f9:  8A 4E F6          mov       cl, byte ptr [bp - 0Ah]
0x00000000000001fc:  8A 46 FC          mov       al, byte ptr [bp - 4]
0x00000000000001ff:  BA 00 70          mov       dx, 0x7000
0x0000000000000202:  8B 5E D6          mov       bx, word ptr [bp - 02Ah]
0x0000000000000205:  8E C2             mov       es, dx
0x0000000000000207:  83 C3 08          add       bx, 8
0x000000000000020a:  98                cbw      
0x000000000000020b:  26 8B 17          mov       dx, word ptr es:[bx]
0x000000000000020e:  30 ED             xor       ch, ch
0x0000000000000210:  89 56 D4          mov       word ptr [bp - 02Ch], dx
0x0000000000000213:  89 C3             mov       bx, ax
0x0000000000000215:  8B 56 F2          mov       dx, word ptr [bp - 0Eh]
0x0000000000000218:  8B 46 D4          mov       ax, word ptr [bp - 02Ch]
0x000000000000021b:  E8 C8 0B          call      0xde6
0x000000000000021e:  8A 46 FA          mov       al, byte ptr [bp - 6]
0x0000000000000221:  30 E4             xor       ah, ah
0x0000000000000223:  01 46 F2          add       word ptr [bp - 0Eh], ax
0x0000000000000226:  EB C8             jmp       0x1f0
0x0000000000000228:  83 46 E6 04       add       word ptr [bp - 01Ah], 4
0x000000000000022c:  FF 46 E2          inc       word ptr [bp - 01Eh]
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

@



;segment_t __near R_GetColumnSegment (int16_t tex, int16_t col, int8_t segloopcachetype) 

PROC R_GetColumnSegment_ NEAR
PUBLIC R_GetColumnSegment_


; bp - 2      segloopcachetype
; bp - 4      loopwidth?
; bp - 6      
; bp - 8      texcol
; bp - 0Ah    TEXTURECOLUMNLUMPS_BYTES_SEGMENT ?
; bp - 0Ch    basecol ?
; bp - 0Eh    
; bp - 010h   subtractor
; bp - 012h   unused
; bp - 014h   unused
; bp - 016h   ax/tex

push      cx
push      si
push      di
push      bp
mov       bp, sp
push      bx        ; bh always zero
sub       sp, 012h
push      ax


;	col &= texturewidthmasks[tex];
;	basecol -= col;
;	texcol = col;


mov       cx, dx
xor       ch, ch  ; todo necessary?
mov       di, ax
mov       ax, TEXTUREWIDTHMASKS_SEGMENT
mov       es, ax
mov       al, byte ptr es:[di]
and       cl, al
sal       di, 1
mov       word ptr [bp - 0Ch], dx
mov       bx, word ptr ds:[_texturepatchlump_offset + di]

;	texturecolumnlump = &(texturecolumnlumps_bytes[texturepatchlump_offset[tex]]);
;	loopwidth = texturecolumnlump[1].bu.bytehigh;

mov       ax, TEXTURECOLUMNLUMPS_BYTES_SEGMENT
mov       es, ax
sal       bx, 1
sub       word ptr [bp - 0Ch], cx
mov       al, byte ptr es:[bx + 3]  ; [1].bu.bytehight
mov       byte ptr [bp - 8], cl     ; texcol
mov       byte ptr [bp - 4], al     ; loopwidth?
test      al, al
je        loopwidth_zero

loopwidth_nonzero:

;		lump = texturecolumnlump[0].h;
;		segloopcachedbasecol[segloopcachetype]  = basecol;
;		seglooptexrepeat[segloopcachetype] 		= loopwidth; // might be 256 and we need the modulo..

mov       si, word ptr es:[bx]
mov       di, word ptr [bp - 2]
mov       bx, di
sal       di, 1
mov       ax, word ptr [bp - 0Ch]
mov       word ptr ds:[di + _segloopcachedbasecol], ax
mov       al, byte ptr [bp - 4]
mov       byte ptr ds:[bx + _seglooptexrepeat], al
jmp       done_with_loopwidth

loopwidth_zero:

;		uint8_t startpixel;
;		int16_t subtractor;
;		int16_t textotal = 0;
;		int16_t runningbasetotal = basecol;
;		int16_t n = 0;


mov       dx, word ptr [bp - 0Ch]   ; get basecol

xor       di, di
test      cx, cx
jl        done_finding_col_lookup


;		while (col >= 0) {
;			//todo: gross. clean this up in asm; there is a 256 byte case that gets stored as 0.
;			// should we change this to be 256 - the number? we dont want a branch.
;			// anyway, fix it in asm
;			subtractor = texturecolumnlump[n+1].bu.bytelow + 1;
;			runningbasetotal += subtractor;
;			lump = texturecolumnlump[n].h;
;			col -= subtractor;
;			if (lump >= 0){ // should be equiv to == -1?
;				texcol -= subtractor; // is this correct or does it have to be bytelow direct?
;			} else {
;				textotal += subtractor; // add the last's total.
;			}
;			n += 2;
;		}

loop_next_col_subtractor:
mov       al, byte ptr es:[bx + 2]      ; subtractor
xor       ah, ah                        ; todo cbw probably safe
inc       ax
mov       si, word ptr es:[bx]          ; lump = texturecolumnlump[n].h;
mov       word ptr [bp - 010h], ax      ; store subtractor
add       dx, ax                        ; dx is runningbasetotal
sub       cx, ax                        ; cx is col
test      si, si
jge       lump_greater_than_zero
add       di, ax                        ; di is textotal
jmp       done_with_lump_check
lump_greater_than_zero:
;				texcol -= subtractor; // is this correct or does it have to be bytelow direct?
sub       byte ptr [bp - 8], al         ; al still subtractor
done_with_lump_check:
add       bx, 4                     ; n+= 2
test      cx, cx
jge       loop_next_col_subtractor

done_finding_col_lookup:

;		startpixel = texturecolumnlump[n-1].bu.bytehigh;

;		if (lump > 0){
test      si, si
jg        lump_greater_than_zero_add_startpixel

;			segloopcachedbasecol[segloopcachetype] = runningbasetotal - textotal;
mov       ax, dx
sub       ax, di
mov       di, ax
jmp       segloopcachedbasecol_set
jump_to_label_7:
jmp       label_7

lump_greater_than_zero_add_startpixel:
;			segloopcachedbasecol[segloopcachetype] = basecol + startpixel;

mov       ax, TEXTURECOLUMNLUMPS_BYTES_SEGMENT ; todo cacheable above?
mov       es, ax
mov       al, byte ptr es:[bx - 1]
xor       ah, ah

mov       di, word ptr [bp - 0Ch]
add       di, ax
segloopcachedbasecol_set:

; write the segloopcachedbasecol[segloopcachetype] calculated above!



mov       bx, word ptr [bp - 2]  ; segloopcachetype
sal       bx, 1
mov       word ptr ds:[bx + _segloopcachedbasecol], di

;		// prev RLE boundary. Hit this function again to load next texture if we hit this.
;		segloopprevlookup[segloopcachetype]     = runningbasetotal - subtractor;
;		// next RLE boundary. see above
;		segloopnextlookup[segloopcachetype]     = runningbasetotal; 
;		// this is not a single repeating texture 
;		seglooptexrepeat[segloopcachetype] 		= 0;

mov       word ptr ds:[bx + _segloopnextlookup], dx
sub       dx, word ptr [bp - 010h]
mov       byte ptr ds:[bx + _seglooptexrepeat], 0
mov       word ptr ds:[bx + _segloopprevlookup], dx


;	if (lump > 0){

done_with_loopwidth:
test      si, si
jle       jump_to_label_7
; nonzero lump

;		int16_t  cachelumpindex;
;		int16_t  cached_nextlookup;
;		uint8_t heightval = patchheights[lump-firstpatch];
;		heightval &= 0x0F;

mov       bx, si
sub       bx, word ptr ds:[_firstpatch]  ; hardcode? selfmodifying?
mov       ax, PATCHHEIGHTS_SEGMENT
mov       es, ax

mov       al, byte ptr es:[bx]
and       ax, 0Fh
mov       word ptr [bp - 6], ax
xor       ax, ax
mov       bx, ax

;		for (cachelumpindex = 0; cachelumpindex < NUM_CACHE_LUMPS; cachelumpindex++){
;			if (lump == cachedlumps[cachelumpindex]){

cmp       si, word ptr ds:[_cachedlumps]
je        cachedlumphit



label_18:
inc       ax
add       bx, 2
cmp       ax, NUM_CACHE_LUMPS
jge       jump_to_move_all_cache_back
cmp       si, word ptr ds:[bx + _cachedlumps]
jne       label_18
cachedlumphit:
test      ax, ax
jne       not_cache_0
found_cached_lump:

;		if (col < 0){
;			uint16_t patchwidth = patchwidths_7000[lump-firstpatch];
;			if (patchwidth > texturewidthmasks[tex]){
;				patchwidth = texturewidthmasks[tex];
;				patchwidth++;
;			}
;		}

test      cx, cx
jge       col_not_under_zero
mov       bx, si
sub       bx, word ptr ds:[_firstpatch]
mov       ax, PATCHWIDTHS_SEGMENT
mov       es, ax
sal       bx, 1
mov       ax, word ptr es:[bx]
mov       bx, word ptr [bp - 016h]      ; tex
mov       dx, TEXTUREWIDTHMASKS_SEGMENT
mov       es, dx
mov       dl, byte ptr es:[bx]
xor       dh, dh
cmp       ax, dx
;			if (patchwidth > texturewidthmasks[tex]){
jna       negative_modulo_thing
;				patchwidth = texturewidthmasks[tex];
mov       ax, dx

;			while (col < 0){
;				col+= patchwidth;
;			}
; todo just and patchwidth -1

negative_modulo_thing:
test      cx, cx
jge       col_not_under_zero
and       cx, ax                ; modulo by power of 2 
col_not_under_zero:
mov       bx, word ptr [bp - 2]

mov       dl, byte ptr [bp - 6]
mov       byte ptr ds:[bx + _segloopheightvalcache], dl
sal       bx, 1
mov       ax, word ptr ds:[_cachedsegmentlumps]
mov       word ptr ds:[bx + _segloopcachedsegment], ax

xchg      ax, cx
mul       dl
add       ax, cx
LEAVE_MACRO     
pop       di
pop       si
pop       cx
ret    


jump_to_move_all_cache_back:
jmp       move_all_cache_back


not_cache_0:
; todo clean this up a lot. something with si/di looping? or hard code with no loop?

;    segment_t usedsegment = cachedsegmentlumps[cachelumpindex];
;    int16_t cachedlump = cachedlumps[cachelumpindex];
;    int16_t i;

mov       dx, word ptr ds:[bx + _cachedlumps]
mov       di, word ptr ds:[bx + _cachedsegmentlumps]

;    for (i = cachelumpindex; i > 0; i--){
;        cachedsegmentlumps[i] = cachedsegmentlumps[i-1];
;        cachedlumps[i] = cachedlumps[i-1];
;    }

; todo stretch this loop out.
jle       done_moving_cachelumps
mov       bx, ax
sal       bx, 1
loop_move_cachelump:
sub       bx, 2
mov       ax, word ptr ds:[bx + _cachedsegmentlumps]
mov       word ptr ds:[bx + _cachedsegmentlumps+2], ax
mov       ax, word ptr ds:[bx + _cachedlumps]
mov       word ptr ds:[bx + _cachedlumps+2], ax
jg        loop_move_cachelump
done_moving_cachelumps:

mov       word ptr ds:[_cachedsegmentlumps], di
mov       word ptr ds:[_cachedlumps], dx
jmp       found_cached_lump

;		// not found, set cache.
;		cachedsegmentlumps[3] = cachedsegmentlumps[2];
;		cachedsegmentlumps[2] = cachedsegmentlumps[1];
;		cachedsegmentlumps[1] = cachedsegmentlumps[0];
;		cachedlumps[3] = cachedlumps[2];
;		cachedlumps[2] = cachedlumps[1];
;		cachedlumps[1] = cachedlumps[0];
move_all_cache_back:
mov       ax, ds
mov       es, ax
mov       ax, OFFSET _cachedsegmentlumps
mov       di, OFFSET _cachedsegmentlumps + 2
xchg      ax, si
movsw
movsw
movsw
mov       si, OFFSET _cachedlumps
mov       di, OFFSET _cachedlumps + 2   ; todo make these adjacent...
movsw
movsw
movsw
xchg      ax, si    ; restore lump
mov       di, word ptr [bp - 2]
mov       bx, di
mov       bx, word ptr ds:[bx + di + _segloopnextlookup]
mov       dx, 0FFh
mov       ax, si
call      R_GetPatchTexture_
mov       word ptr ds:[_cachedsegmentlumps], ax
mov       word ptr ds:[di + _segloopnextlookup], bx
sar       di, 1
mov       al, byte ptr [bp - 4]
mov       word ptr ds:[_cachedlumps], si
mov       byte ptr ds:[di + _seglooptexrepeat], al
jmp       found_cached_lump
   
label_7:
mov       ax, TEXTURECOLLENGTH_SEGMENT
mov       bx, word ptr [bp - 016h]
mov       es, ax
mov       ax, word ptr ds:[_cachedtex]
mov       dl, byte ptr es:[bx]
cmp       ax, bx
je        label_20
mov       ax, word ptr ds:[_cachedtex2]
cmp       ax, bx
je        label_21
mov       si, word ptr [bp - 2]
mov       bx, si
mov       ax, word ptr ds:[_cachedtex]
mov       word ptr ds:[_cachedtex2], ax
mov       ax, word ptr ds:[_cachedsegmenttex]
mov       di, word ptr [bp - 016h]
mov       word ptr ds:[_cachedsegmenttex2], ax
mov       al, byte ptr ds:[_cachedcollength]
mov       cx, word ptr ds:[si + _segloopnextlookup]
mov       byte ptr ds:[_cachedcollength2], al
mov       ax, di
mov       word ptr ds:[_cachedtex], di
call      R_GetCompositeTexture_
mov       word ptr ds:[_cachedsegmenttex], ax
mov       byte ptr ds:[_cachedcollength], dl
mov       al, byte ptr [bp - 4]
mov       word ptr ds:[si + _segloopnextlookup], cx
mov       byte ptr ds:[bx + _seglooptexrepeat], al
label_20:
mov       bx, word ptr [bp - 2]
mov       byte ptr ds:[bx + _segloopheightvalcache], dl
sal       bx, 1
mov       ax, word ptr ds:[_cachedsegmenttex]
mov       word ptr ds:[bx + _segloopcachedsegment], ax
mov       al, byte ptr ds:[_cachedcollength]
mul       byte ptr [bp - 8]
add       ax, word ptr ds:[_cachedsegmenttex]
LEAVE_MACRO     
pop       di
pop       si
pop       cx
ret       
label_21:
mov       bx, word ptr ds:[_cachedtex]
mov       ax, word ptr ds:[_cachedtex2]
mov       word ptr [bp - 016h], bx
mov       word ptr ds:[_cachedtex], ax
mov       word ptr ds:[_cachedtex2], bx
mov       bx, word ptr ds:[_cachedsegmenttex]
mov       ax, word ptr ds:[_cachedsegmenttex2]
mov       word ptr [bp - 016h], bx
mov       word ptr ds:[_cachedsegmenttex2], bx
mov       bl, byte ptr ds:[_cachedcollength]
mov       word ptr ds:[_cachedsegmenttex], ax
xor       bh, bh
mov       al, byte ptr ds:[_cachedcollength2]
mov       word ptr [bp - 016h], bx
mov       byte ptr ds:[_cachedcollength], al
mov       al, byte ptr [bp - 016h]
mov       byte ptr ds:[_cachedcollength2], al
jmp       label_20

ENDP

COMMENT @

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
0x0000000000000514:  B8 A2 82          mov       ax, TEXTUREWIDTHMASKS_SEGMENT
0x0000000000000517:  C7 04 FF FF       mov       word ptr [si], 0FFFFh
0x000000000000051b:  8B 76 EE          mov       si, word ptr [bp - 012h]
0x000000000000051e:  8E C0             mov       es, ax
0x0000000000000520:  30 F7             xor       bh, dh
0x0000000000000522:  26 8A 04          mov       al, byte ptr es:[si]
0x0000000000000525:  20 C3             and       bl, al
0x0000000000000527:  89 F0             mov       ax, si
0x0000000000000529:  01 F0             add       ax, si
0x000000000000052b:  89 56 F6          mov       word ptr [bp - 0Ah], dx
0x000000000000052e:  89 C6             mov       si, ax
0x0000000000000530:  B8 00 70          mov       ax, 0x7000
0x0000000000000533:  8B 94 F0 EA       mov       dx, word ptr [si - 0x1510]
0x0000000000000537:  81 C6 F0 EA       add       si, _texturepatchlump_offset
0x000000000000053b:  01 D2             add       dx, dx
0x000000000000053d:  8E C0             mov       es, ax
0x000000000000053f:  89 D6             mov       si, dx
0x0000000000000541:  29 5E F6          sub       word ptr [bp - 0Ah], bx
0x0000000000000544:  26 8A 44 03       mov       al, byte ptr es:[si + 3]
0x0000000000000548:  88 5E FA          mov       byte ptr [bp - 6], bl
0x000000000000054b:  88 46 FC          mov       byte ptr [bp - 4], al
0x000000000000054e:  84 C0             test      al, al
0x0000000000000550:  74 03             je        0x555
0x0000000000000552:  E9 F3 00          jmp       0x648
0x0000000000000555:  30 E4             xor       ah, ah
0x0000000000000557:  8C C2             mov       dx, es
0x0000000000000559:  89 46 F2          mov       word ptr [bp - 0Eh], ax
0x000000000000055c:  8B 46 F6          mov       ax, word ptr [bp - 0Ah]
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
0x0000000000000591:  C6 46 F1 00       mov       byte ptr [bp - 0Fh], 0
0x0000000000000595:  88 56 F0          mov       byte ptr [bp - 010h], dl
0x0000000000000598:  8B 56 F6          mov       dx, word ptr [bp - 0Ah]
0x000000000000059b:  BE BE 02          mov       si, OFFSET _maskedcachedbasecol
0x000000000000059e:  03 56 F0          add       dx, word ptr [bp - 010h]
0x00000000000005a1:  89 14             mov       word ptr [si], dx
0x00000000000005a3:  89 C2             mov       dx, ax
0x00000000000005a5:  BE BA 02          mov       si, OFFSET _maskedprevlookup
0x00000000000005a8:  29 CA             sub       dx, cx
0x00000000000005aa:  89 14             mov       word ptr [si], dx
0x00000000000005ac:  BE B8 02          mov       si, OFFSET _maskednextlookup
0x00000000000005af:  89 04             mov       word ptr [si], ax
0x00000000000005b1:  BE BC 02          mov       si, OFFSET _maskedtexrepeat
0x00000000000005b4:  C7 04 00 00       mov       word ptr [si], 0
0x00000000000005b8:  85 FF             test      di, di
0x00000000000005ba:  7F 03             jg        0x5bf
0x00000000000005bc:  E9 89 01          jmp       0x748
0x00000000000005bf:  B8 63 73          mov       ax, MASKED_LOOKUP_SEGMENT_7000
0x00000000000005c2:  8B 76 EE          mov       si, word ptr [bp - 012h]
0x00000000000005c5:  8E C0             mov       es, ax
0x00000000000005c7:  26 8A 04          mov       al, byte ptr es:[si]
0x00000000000005ca:  88 46 FE          mov       byte ptr [bp - 2], al
0x00000000000005cd:  89 FE             mov       si, di
0x00000000000005cf:  B8 BA 73          mov       ax, 0x73ba
0x00000000000005d2:  2B 36 7E 1F       sub       si, word ptr ds:[_firstpatch]
0x00000000000005d6:  8E C0             mov       es, ax
0x00000000000005d8:  31 C9             xor       cx, cx
0x00000000000005da:  26 8A 04          mov       al, byte ptr es:[si]
0x00000000000005dd:  BE BA 03          mov       si, 0x3ba
0x00000000000005e0:  88 46 F8          mov       byte ptr [bp - 8], al
0x00000000000005e3:  24 F0             and       al, 0xf0
0x00000000000005e5:  80 66 F8 0F       and       byte ptr [bp - 8], 0xf
0x00000000000005e9:  88 04             mov       byte ptr [si], al
0x00000000000005eb:  31 C0             xor       ax, ax
0x00000000000005ed:  3B 3E 18 1C       cmp       di, word ptr ds:[_cachedlumps]
0x00000000000005f1:  74 11             je        0x604
0x00000000000005f3:  40                inc       ax
0x00000000000005f4:  83 C1 02          add       cx, 2
0x00000000000005f7:  3D 04 00          cmp       ax, NUM_CACHE_LUMPS
0x00000000000005fa:  7D 6C             jge       0x668
0x00000000000005fc:  89 CE             mov       si, cx
0x00000000000005fe:  3B BC 18 1C       cmp       di, word ptr ds:[si + _cachedlumps]
0x0000000000000602:  75 EF             jne       0x5f3
0x0000000000000604:  85 C0             test      ax, ax
0x0000000000000606:  75 73             jne       0x67b
0x0000000000000608:  85 DB             test      bx, bx
0x000000000000060a:  7C 69             jl        0x675
0x000000000000060c:  BE C0 02          mov       si, OFFSET _maskedcachedsegment
0x000000000000060f:  A1 10 1C          mov       ax, word ptr ds:[_cachedsegmentlumps]
0x0000000000000612:  89 04             mov       word ptr [si], ax
0x0000000000000614:  8A 46 FE          mov       al, byte ptr [bp - 2]
0x0000000000000617:  3C FF             cmp       al, 0FFh
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
0x0000000000000637:  BB C0 02          mov       bx, OFFSET _maskedcachedsegment
0x000000000000063a:  8B 07             mov       ax, word ptr [bx]
0x000000000000063c:  81 C6 50 02       add       si, 0x250
0x0000000000000640:  01 D0             add       ax, dx
0x0000000000000642:  C9                LEAVE_MACRO     
0x0000000000000643:  5F                pop       di
0x0000000000000644:  5E                pop       si
0x0000000000000645:  59                pop       cx
0x0000000000000646:  5B                pop       bx
0x0000000000000647:  CB                retf      
0x0000000000000648:  BE BE 02          mov       si, OFFSET _maskedcachedbasecol
0x000000000000064b:  89 D7             mov       di, dx
0x000000000000064d:  8B 46 F6          mov       ax, word ptr [bp - 0Ah]
0x0000000000000650:  26 8B 3D          mov       di, word ptr es:[di]
0x0000000000000653:  89 04             mov       word ptr [si], ax
0x0000000000000655:  8A 46 FC          mov       al, byte ptr [bp - 4]
0x0000000000000658:  BE BC 02          mov       si, OFFSET _maskedtexrepeat
0x000000000000065b:  30 E4             xor       ah, ah
0x000000000000065d:  89 04             mov       word ptr [si], ax
0x000000000000065f:  E9 56 FF          jmp       0x5b8
0x0000000000000662:  01 4E F2          add       word ptr [bp - 0Eh], cx
0x0000000000000665:  E9 15 FF          jmp       0x57d
0x0000000000000668:  EB 4B             jmp       0x6b5
0x000000000000066a:  89 C2             mov       dx, ax
0x000000000000066c:  BE BE 02          mov       si, OFFSET _maskedcachedbasecol
0x000000000000066f:  2B 56 F2          sub       dx, word ptr [bp - 0Eh]
0x0000000000000672:  E9 2C FF          jmp       0x5a1
0x0000000000000675:  E9 86 00          jmp       0x6fe
0x0000000000000678:  E9 B4 00          jmp       0x72f
0x000000000000067b:  89 CE             mov       si, cx
0x000000000000067d:  8B 94 10 1C       mov       dx, word ptr [si ds:+ _cachedsegmentlumps]
0x0000000000000681:  89 C1             mov       cx, ax
0x0000000000000683:  89 56 F4          mov       word ptr [bp - 0Ch], dx
0x0000000000000686:  8B 94 18 1C       mov       dx, word ptr ds:[si + _cachedlumps]
0x000000000000068a:  7E 1C             jle       0x6a8
0x000000000000068c:  89 C6             mov       si, ax
0x000000000000068e:  01 C6             add       si, ax
0x0000000000000690:  83 EE 02          sub       si, 2
0x0000000000000693:  8B 84 10 1C       mov       ax, word ptr ds:[si + _cachedsegmentlumps]
0x0000000000000697:  89 84 12 1C       mov       word ptr ds:[si + _cachedsegmentlumps + 2], ax
0x000000000000069b:  8B 84 18 1C       mov       ax, word ptr ds:[si + _cachedlumps]
0x000000000000069f:  49                dec       cx
0x00000000000006a0:  89 84 1A 1C       mov       word ptr ds:[si + _cachedlumps+2], ax
0x00000000000006a4:  85 C9             test      cx, cx
0x00000000000006a6:  7F E8             jg        0x690
0x00000000000006a8:  8B 46 F4          mov       ax, word ptr [bp - 0Ch]
0x00000000000006ab:  89 16 18 1C       mov       word ptr ds:[_cachedlumps], dx
0x00000000000006af:  A3 10 1C          mov       word ptr ds:[_cachedsegmentlumps], ax
0x00000000000006b2:  E9 53 FF          jmp       0x608
0x00000000000006b5:  A1 14 1C          mov       ax, word ptr ds:[_cachedsegmentlumps+4]
0x00000000000006b8:  A3 16 1C          mov       word ptr ds:[_cachedsegmentlumps+6], ax
0x00000000000006bb:  A1 12 1C          mov       ax, word ptr ds:[_cachedsegmentlumps+2]
0x00000000000006be:  A3 14 1C          mov       word ptr ds:[_cachedsegmentlumps+4], ax
0x00000000000006c1:  A1 10 1C          mov       ax, word ptr ds:[_cachedsegmentlumps]
0x00000000000006c4:  A3 12 1C          mov       word ptr ds:[_cachedsegmentlumps+2], ax
0x00000000000006c7:  A1 1C 1C          mov       ax, word ptr ds:[_cachedlumps+4]
0x00000000000006ca:  BE B8 02          mov       si, OFFSET _maskednextlookup
0x00000000000006cd:  A3 1E 1C          mov       word ptr ds:[_cachedlumps+6], ax
0x00000000000006d0:  A1 1A 1C          mov       ax, word ptr ds:[_cachedlumps+2]
0x00000000000006d3:  8A 56 FE          mov       dl, byte ptr [bp - 2]
0x00000000000006d6:  A3 1C 1C          mov       word ptr ds:[_cachedlumps+4], ax
0x00000000000006d9:  A1 18 1C          mov       ax, word ptr ds:[_cachedlumps]
0x00000000000006dc:  30 F6             xor       dh, dh
0x00000000000006de:  A3 1A 1C          mov       word ptr ds:[_cachedlumps+2], ax
0x00000000000006e1:  89 F8             mov       ax, di
0x00000000000006e3:  8B 0C             mov       cx, word ptr [si]
0x00000000000006e5:  E8 A2 0A          call      0x118a
0x00000000000006e8:  A3 10 1C          mov       word ptr ds:[_cachedsegmentlumps], ax
0x00000000000006eb:  89 3E 18 1C       mov       word ptr ds:[_cachedlumps], di
0x00000000000006ef:  8A 46 FC          mov       al, byte ptr [bp - 4]
0x00000000000006f2:  89 0C             mov       word ptr [si], cx
0x00000000000006f4:  BE BC 02          mov       si, OFFSET _maskedtexrepeat
0x00000000000006f7:  30 E4             xor       ah, ah
0x00000000000006f9:  89 04             mov       word ptr [si], ax
0x00000000000006fb:  E9 0A FF          jmp       0x608
0x00000000000006fe:  89 FE             mov       si, di
0x0000000000000700:  B8 7E 73          mov       ax, 0x737e
0x0000000000000703:  2B 36 7E 1F       sub       si, word ptr ds:[_firstpatch]
0x0000000000000707:  8E C0             mov       es, ax
0x0000000000000709:  01 F6             add       si, si
0x000000000000070b:  BA A2 82          mov       dx, TEXTUREWIDTHMASKS_SEGMENT
0x000000000000070e:  26 8B 04          mov       ax, word ptr es:[si]
0x0000000000000711:  8B 76 EE          mov       si, word ptr [bp - 012h]
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
0x000000000000073b:  BB C0 02          mov       bx, OFFSET _maskedcachedsegment
0x000000000000073e:  F6 E4             mul       ah
0x0000000000000740:  03 07             add       ax, word ptr [bx]
0x0000000000000742:  C9                LEAVE_MACRO     
0x0000000000000743:  5F                pop       di
0x0000000000000744:  5E                pop       si
0x0000000000000745:  59                pop       cx
0x0000000000000746:  5B                pop       bx
0x0000000000000747:  CB                retf      
0x0000000000000748:  B8 30 4F          mov       ax, TEXTURECOLLENGTH_SEGMENT
0x000000000000074b:  8B 5E EE          mov       bx, word ptr [bp - 012h]
0x000000000000074e:  8E C0             mov       es, ax
0x0000000000000750:  A1 AC 06          mov       ax, word ptr ds:[_cachedtex]
0x0000000000000753:  26 8A 17          mov       dl, byte ptr es:[bx]
0x0000000000000756:  39 D8             cmp       ax, bx
0x0000000000000758:  74 40             je        0x79a
0x000000000000075a:  A1 B2 06          mov       ax, word ptr ds:[_cachedtex2]
0x000000000000075d:  39 D8             cmp       ax, bx
0x000000000000075f:  74 5B             je        0x7bc
0x0000000000000761:  A1 AC 06          mov       ax, word ptr ds:[_cachedtex]
0x0000000000000764:  BB B8 02          mov       bx, OFFSET _maskednextlookup
0x0000000000000767:  A3 B2 06          mov       word ptr ds:[_cachedtex2], ax
0x000000000000076a:  A1 AE 06          mov       ax, word ptr ds:[_cachedsegmenttex]
0x000000000000076d:  8B 0F             mov       cx, word ptr [bx]
0x000000000000076f:  A3 B0 06          mov       word ptr ds:[_cachedsegmenttex2], ax
0x0000000000000772:  A0 B4 06          mov       al, byte ptr ds:[_cachedcollength]
0x0000000000000775:  8B 5E EE          mov       bx, word ptr [bp - 012h]
0x0000000000000778:  A2 B5 06          mov       byte ptr ds:[_cachedcollength2], al
0x000000000000077b:  89 D8             mov       ax, bx
0x000000000000077d:  89 1E AC 06       mov       word ptr ds:[_cachedtex], bx
0x0000000000000781:  E8 9B 0A          call      R_GetCompositeTexture_
0x0000000000000784:  BB B8 02          mov       bx, OFFSET _maskednextlookup
0x0000000000000787:  A3 AE 06          mov       word ptr ds:[_cachedsegmenttex], ax
0x000000000000078a:  8A 46 FC          mov       al, byte ptr [bp - 4]
0x000000000000078d:  89 0F             mov       word ptr [bx], cx
0x000000000000078f:  BB BC 02          mov       bx, OFFSET _maskedtexrepeat
0x0000000000000792:  30 E4             xor       ah, ah
0x0000000000000794:  88 16 B4 06       mov       byte ptr ds:[_cachedcollength], dl
0x0000000000000798:  89 07             mov       word ptr [bx], ax
0x000000000000079a:  BB BA 03          mov       bx, 0x3ba
0x000000000000079d:  88 17             mov       byte ptr [bx], dl
0x000000000000079f:  BB C2 02          mov       bx, 0x2c2
0x00000000000007a2:  88 17             mov       byte ptr [bx], dl
0x00000000000007a4:  BB C0 02          mov       bx, OFFSET _maskedcachedsegment
0x00000000000007a7:  A1 AE 06          mov       ax, word ptr ds:[_cachedsegmenttex]
0x00000000000007aa:  89 07             mov       word ptr [bx], ax
0x00000000000007ac:  A0 B4 06          mov       al, byte ptr ds:[_cachedcollength]
0x00000000000007af:  8A 66 FA          mov       ah, byte ptr [bp - 6]
0x00000000000007b2:  F6 E4             mul       ah
0x00000000000007b4:  03 07             add       ax, word ptr [bx]
0x00000000000007b6:  C9                LEAVE_MACRO     
0x00000000000007b7:  5F                pop       di
0x00000000000007b8:  5E                pop       si
0x00000000000007b9:  59                pop       cx
0x00000000000007ba:  5B                pop       bx
0x00000000000007bb:  CB                retf      
0x00000000000007bc:  8B 1E AC 06       mov       bx, word ptr ds:[_cachedtex]
0x00000000000007c0:  A1 B2 06          mov       ax, word ptr ds:[_cachedtex2]
0x00000000000007c3:  89 5E EE          mov       word ptr [bp - 012h], bx
0x00000000000007c6:  A3 AC 06          mov       word ptr ds:[_cachedtex], ax
0x00000000000007c9:  89 1E B2 06       mov       word ptr ds:[_cachedtex2], bx
0x00000000000007cd:  8B 1E AE 06       mov       bx, word ptr ds:[_cachedsegmenttex]
0x00000000000007d1:  A1 B0 06          mov       ax, word ptr ds:[_cachedsegmenttex2]]
0x00000000000007d4:  89 5E EE          mov       word ptr [bp - 012h], bx
0x00000000000007d7:  89 1E B0 06       mov       word ptr ds:[_cachedsegmenttex2], bx
0x00000000000007db:  8A 1E B4 06       mov       bl, byte ptr ds:[_cachedcollength]
0x00000000000007df:  A3 AE 06          mov       word ptr ds:[_cachedsegmenttex], ax
0x00000000000007e2:  30 FF             xor       bh, bh
0x00000000000007e4:  A0 B5 06          mov       al, byte ptr ds:[_cachedcollength2]
0x00000000000007e7:  89 5E EE          mov       word ptr [bp - 012h], bx
0x00000000000007ea:  A2 B4 06          mov       byte ptr ds:[_cachedcollength], al
0x00000000000007ed:  8A 46 EE          mov       al, byte ptr [bp - 012h]
0x00000000000007f0:  A2 B5 06          mov       byte ptr ds:[_cachedcollength2], al
0x00000000000007f3:  EB A5             jmp       0x79a

ENDP

@

SCRATCH_ADDRESS_4000_SEGMENT = 04000h
SCRATCH_ADDRESS_5000_SEGMENT = 05000h

do_masked_jump:
mov       ax, 0c089h   ; 2 byte nop
mov       di, ((SELFMODIFY_loadpatchcolumn_masked_check2_TARGET - SELFMODIFY_loadpatchcolumn_masked_check2_AFTER) SHL 8) + 0EBh
jmp       ready_selfmodify_loadpatch

PROC R_LoadPatchColumns_ NEAR
PUBLIC R_LoadPatchColumns_


push      cx
push      si
push      di
push      bp

mov       si, ax

test      bl, bl
jne       do_masked_jump
mov       ax, ((SELFMODIFY_loadpatchcolumn_masked_check1_TARGET - SELFMODIFY_loadpatchcolumn_masked_check1_AFTER) SHL 8) + 0EBh
mov       di, 0c089h   ; 2 byte nop
ready_selfmodify_loadpatch:

mov       word ptr cs:[SELFMODIFY_loadpatchcolumn_masked_check1], ax;
mov       word ptr cs:[SELFMODIFY_loadpatchcolumn_masked_check2], di;

push      dx       ; store future es
call      Z_QuickMapScratch_4000_
mov       cx, SCRATCH_ADDRESS_4000_SEGMENT
push      cx
mov       ax, si
xor       bx, bx  ; zero seg offset
mov       di, bx  ; zero
call      W_CacheLumpNumDirect_

pop       ds      ; get 4000 segment
pop       es      ; get dest segment

mov       bp, word ptr ds:[di]  ; patchwidth
dec       bp; dec loop needs to start one off to trigger jns/js

mov       ax, di ; zero
cwd              ; zero


; di is destoffset
; ds:[bx] is patch data (in scratch segment)
; ds:[si] is column data

; es is dest segment
mov       bx, 8
mov       dx, 0FFF0h

do_next_column:


mov       si, word ptr ds:[bx]
lodsb     ; get topdelta
cmp       al, dh
je        done_with_column
do_next_post_in_column:

lodsb      ; get length
inc       si   ; si + 3
; ah known zero, thus ch known zero
mov       cx, ax
shr       cx, 1
rep movsw 
adc       cx, cx
rep movsb 

mov       cx, ax  ; restore length in cx
inc       si

;cmp       byte ptr [bp - 2], 0
SELFMODIFY_loadpatchcolumn_masked_check1:
jmp       SHORT       skip_segment_alignment_1
SELFMODIFY_loadpatchcolumn_masked_check1_AFTER:
; ah is 0
; adjust col offset

sub       di, dx
dec       di
and       di, dx

SELFMODIFY_loadpatchcolumn_masked_check1_TARGET:
skip_segment_alignment_1:
lodsb
cmp       al, dh
jne       do_next_post_in_column
done_with_column:
;cmp       byte ptr [bp - 2], 0
SELFMODIFY_loadpatchcolumn_masked_check2:
jmp       SHORT       skip_segment_alignment_2
SELFMODIFY_loadpatchcolumn_masked_check2_AFTER:
; adjust col offset

sub       di, dx
dec       di
and       di, dx

SELFMODIFY_loadpatchcolumn_masked_check2_TARGET:
skip_segment_alignment_2:
add       bx, 4
dec       bp
jns       do_next_column
; restore ds
done_drawing_texture:
mov       ax, ss
mov       ds, ax
pop       bp
call      Z_QuickMapRender4000_

pop       di
pop       si
pop       cx
ret       


ENDP



;void R_LoadSpriteColumns(uint16_t lump, segment_t destpatch_segment);
; ax = lump
; dx = segment

PROC R_LoadSpriteColumns_ FAR  ; todo near?
PUBLIC R_LoadSpriteColumns_



PUSHA_NO_AX_MACRO
push      bp
mov       bp, sp
mov       si, ax

call      Z_QuickMapScratch_5000_

;	patch_t __far *wadpatch = (patch_t __far *)SCRATCH_ADDRESS_5000;
;	uint16_t __far * columnofs = (uint16_t __far *)&(destpatch->columnofs[0]);   // will be updated in place..


mov       di, SCRATCH_ADDRESS_5000_SEGMENT
mov       cx, di
mov       ax, si
xor       bx, bx


;	W_CacheLumpNumDirect(lump, SCRATCH_ADDRESS_5000);

call      W_CacheLumpNumDirect_
; wadpatch  is 0x5000 seg
; destpatch is dx
;	patchwidth = wadpatch->width;
;	destpatch->width = wadpatch->width;
;	destpatch->height = wadpatch->height;
;	destpatch->leftoffset = wadpatch->leftoffset;
;	destpatch->topoffset = wadpatch->topoffset;

sub       si, word ptr ds:[_firstspritelump] ; get this before we clobber ds
mov       cx, si ; store in cx

mov       ds, di

xor       di, di
mov       si, di

mov       es, dx
lodsw
mov       word ptr cs:[SELFMODIFY_loadspritecolumn_width_check+1],  ax  ; patchwidth   todo write selfmodify ahead
stosw
movsw
movsw
movsw
mov       bx, ax ; patchwidth
mov       bp, di   ; bp gets 8


; 	destoffset = 8 + ( patchwidth << 2);
;	currentpostbyte = destoffset;
;	postdata = (uint16_t __far *)(((byte __far*)destpatch) + currentpostbyte);


SHIFT_MACRO shl       bx 2
mov       si, cx
shl       si, 1
add       bx, 8
;	destoffset += spritepostdatasizes[lump-firstspritelump];
mov       ax, SPRITEPOSTDATASIZES_SEGMENT
mov       es, ax

mov       di, bx
add       di, word ptr es:[si]
mov       es, dx  ; restore es
mov       dx, bp  ; dx starts as 8 for loop too

;	destoffset += (16 - ((destoffset &0xF)) &0xF); // round up so first pixel data starts aligned of course.
;	currentpixelbyte = destoffset;
;	pixeldataoffset = (byte __far *)MK_FP(destpatch_segment, currentpixelbyte);



add       di, 15
and       di, 0FFF0h




start_sprite_column_loop:
xor       cx, cx
do_next_sprite_column:
dec       word ptr cs:[SELFMODIFY_loadspritecolumn_width_check+1]

mov       ax, di

SHIFT_MACRO shr       ax 4
mov       si, dx
mov       si, word ptr ds:[si]


mov       word ptr es:[bp], ax
mov       word ptr es:[bp+2], bx
add       bp, 4


lodsw
cmp       al, 0FFh
je        done_with_sprite_column
do_next_sprite_post:


mov       word ptr es:[bx], ax


mov       cl, ah
mov       ax, cx
inc       si



shr       cx, 1
rep movsw 
adc       cx, cx
rep movsb 



add       di, 15
and       di, 0FFF0h  ; round up to next segment destination

; column = (column_t __far *)(  ((byte  __far*)column) + column->length + 4 );

inc       si
inc       bx
inc       bx

lodsw
cmp       al, 0FFh
jne       do_next_sprite_post
done_with_sprite_column:

mov       word ptr es:[bx], 0FFFFh
add       dx, 4
inc       bx
inc       bx


SELFMODIFY_loadspritecolumn_width_check:
mov       ax, 01000h
test      ax, ax
jne       do_next_sprite_column


done_with_sprite_column_loop:

mov       ax, ss  ; restore ds
mov       ds, ax
pop       bp 

call      Z_QuickMapRender5000_

POPA_NO_AX_MACRO
retf      


ENDP


END
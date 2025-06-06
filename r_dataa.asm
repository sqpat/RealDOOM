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


.DATA

EXTRN _spriteL1LRU:BYTE
EXTRN _textureL1LRU:BYTE
EXTRN _spritecache_nodes:BYTE
EXTRN _spritecache_l2_head:BYTE
EXTRN _spritecache_l2_tail:BYTE
EXTRN _texturecache_nodes:BYTE
EXTRN _texturecache_l2_head:BYTE
EXTRN _texturecache_l2_tail:BYTE

EXTRN _usedtexturepagemem:BYTE
EXTRN _usedspritepagemem:BYTE
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

; bp - 2    secondarymaxitersize
; bp - 4    nodehead
; bp - 6    used for ds first, used for es first
; bp - 8    second offset used for si
; bp - 0Ah  used for ds second
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
push      MAX_PATCHES                       ; bp - 2
push      OFFSET _texturecache_l2_head      ; bp - 4
push      COMPOSITETEXTUREPAGE_SEGMENT      ; bp - 6
push      MAX_PATCHES                       ; bp - 8
push      PATCHOFFSET_SEGMENT               ; bp - 0Ah
push      OFFSET _usedtexturepagemem        ; bp - 0Ch
mov       bx, OFFSET _texturecache_l2_tail
mov       di, OFFSET _texturecache_nodes


jmp       done_with_switchblock
not_composite:
cmp       dl, CACHETYPE_PATCH
jne       is_sprite

is_patch:
push      MAX_TEXTURES                      ; bp - 2
push      OFFSET _texturecache_l2_head      ; bp - 4
push      PATCHPAGE_SEGMENT                 ; bp - 6   
push      MAX_PATCHES                       ; bp - 8
push      COMPOSITETEXTUREOFFSET_SEGMENT    ; bp - 0Ah
push      OFFSET _usedtexturepagemem        ; bp - 0Ch
mov       bx, OFFSET _texturecache_l2_tail
mov       di, OFFSET _texturecache_nodes


jmp       done_with_switchblock

is_sprite:
push      0                           ; bp - 2
push      OFFSET _spritecache_l2_head ; bp - 4
push      SPRITEPAGE_SEGMENT          ; bp - 6
push      MAX_SPRITE_LUMPS            ; bp - 6
sub       sp, 4
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
shl       bx, 2
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

mov       word ptr [bx + di + 2], ax    ; set both at once
mov       bx, ax                   ; zero

lds       si, dword ptr [bp - 8] ; both an index and a loop limit

;    for (k = 0; k < maxitersize; k++){
;			if ((cacherefpage[k] >> 2) == evictedpage){
;				cacherefpage[k] = 0xFF;
;				cacherefoffset[k] = 0xFF;
;			}
;		}

continue_first_cache_erase_loop:
mov       al, byte ptr ds:[bx]  ; todo maybe lodsb
shr       ax, 2
cmp       al, cl
je        erase_this_page
done_erasing_page:
inc       bx
cmp       bx, si 
jl        continue_first_cache_erase_loop

done_with_first_cache_erase_loop:


;	for (k = 0; k < secondarymaxitersize; k++){
;        if ((secondarycacherefpage[k]) >> 2 == evictedpage){
;            secondarycacherefpage[k] = 0xFF;
;            secondarycacherefoffset[k] = 0xFF;
;        }
;    }

mov       si, word ptr [bp - 2] 
cmp       si, 0 
jle       skip_secondary_loop

mov       ds, word ptr [bp - 0Ah]  ; todo change?
xor       bx, bx                     ; offset and loop ctr

continue_second_cache_erase_loop:
mov       al, byte ptr ds:[bx]   ; todo maybe lodsb

SHIFT_MACRO sar       ax 2
cmp       al, cl
je        erase_second_page
done_erasing_second_page:
inc       bx
cmp       bx, si 
jl        continue_second_cache_erase_loop

skip_secondary_loop:

;		usedcacherefpage[evictedpage] = 0;


push      ss
pop       ds  ; todo change later. just use ss twice instead?


mov       si, word ptr [bp - 0Ch] ; usedcacherefpage
mov       bx, cx
mov       byte ptr [bx + si], dh    ; 0

;		evictedpage = nodelist[evictedpage].prev;

SHIFT_MACRO shl       bx 2
mov       cl, byte ptr [bx + di]     ; get prev
cmp       cl, dl                   ; dl is -1
jne       do_next_evicted_page
jmp       cleared_all_cache_data   ; todo remove...


cleared_all_cache_data:

;	// connect old tail and old head.
;	nodelist[*nodetail].prev = *nodehead;


mov       si, word ptr [bp - 0Eh]
lodsb
cbw      
mov       cx, ax            ; cx stores nodetail

SHIFT_MACRO shl       ax 2
xchg      ax, bx            ; bx has nodelist nodetail lookup

mov       si, word ptr [bp - 4]
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
mov       byte ptr ds:[bx], dl      ; 0FFh
mov       byte ptr ds:[bx+si], dl   ; 0FFh
jmp       done_erasing_page

erase_second_page:
mov       byte ptr ds:[bx], dl      ; 0FFh
mov       byte ptr ds:[bx+si], dl   ; 0FFh
jmp       done_erasing_second_page



ENDP
COMMENT @

PROC R_EvictL2CacheEMSPage_ NEAR
PUBLIC R_EvictL2CacheEMSPage_


0x0000000000000224:  53                push      bx
0x0000000000000225:  51                push      cx
0x0000000000000226:  52                push      dx
0x0000000000000227:  56                push      si
0x0000000000000228:  55                push      bp
0x0000000000000229:  89 E5             mov       bp, sp
0x000000000000022b:  83 EC 02          sub       sp, 2
0x000000000000022e:  88 C2             mov       dl, al
0x0000000000000230:  B9 54 1C          mov       cx, 0x1c54
0x0000000000000233:  8C DB             mov       bx, ds
0x0000000000000235:  3A 06 A8 06       cmp       al, byte ptr [0x6a8]
0x0000000000000239:  74 53             je        0x28e
0x000000000000023b:  98                cbw      
0x000000000000023c:  89 CE             mov       si, cx
0x000000000000023e:  01 C0             add       ax, ax
0x0000000000000240:  01 C6             add       si, ax
0x0000000000000242:  8A 04             mov       al, byte ptr [si]
0x0000000000000244:  8A 74 01          mov       dh, byte ptr [si + 1]
0x0000000000000247:  88 46 FE          mov       byte ptr [bp - 2], al
0x000000000000024a:  3A 16 A9 06       cmp       dl, byte ptr [0x6a9]
0x000000000000024e:  74 44             je        0x294
0x0000000000000250:  98                cbw      
0x0000000000000251:  89 CE             mov       si, cx
0x0000000000000253:  01 C0             add       ax, ax
0x0000000000000255:  01 C6             add       si, ax
0x0000000000000257:  88 74 01          mov       byte ptr [si + 1], dh
0x000000000000025a:  88 F0             mov       al, dh
0x000000000000025c:  98                cbw      
0x000000000000025d:  89 CE             mov       si, cx
0x000000000000025f:  01 C0             add       ax, ax
0x0000000000000261:  8E C3             mov       es, bx
0x0000000000000263:  01 C6             add       si, ax
0x0000000000000265:  8A 46 FE          mov       al, byte ptr [bp - 2]
0x0000000000000268:  26 88 04          mov       byte ptr es:[si], al
0x000000000000026b:  88 D0             mov       al, dl
0x000000000000026d:  98                cbw      
0x000000000000026e:  89 CE             mov       si, cx
0x0000000000000270:  01 C0             add       ax, ax
0x0000000000000272:  01 C6             add       si, ax
0x0000000000000274:  A0 A8 06          mov       al, byte ptr [0x6a8]
0x0000000000000277:  26 88 04          mov       byte ptr es:[si], al
0x000000000000027a:  98                cbw      
0x000000000000027b:  89 CB             mov       bx, cx
0x000000000000027d:  01 C0             add       ax, ax
0x000000000000027f:  26 C6 44 01 FF    mov       byte ptr es:[si + 1], 0xff
0x0000000000000284:  01 C3             add       bx, ax
0x0000000000000286:  88 16 A8 06       mov       byte ptr [0x6a8], dl
0x000000000000028a:  26 88 57 01       mov       byte ptr es:[bx + 1], dl
0x000000000000028e:  C9                LEAVE_MACRO     
0x000000000000028f:  5E                pop       si
0x0000000000000290:  5A                pop       dx
0x0000000000000291:  59                pop       cx
0x0000000000000292:  5B                pop       bx
0x0000000000000293:  CB                retf      
0x0000000000000294:  88 36 A9 06       mov       byte ptr [0x6a9], dh
0x0000000000000298:  EB C0             jmp       0x25a


ENDP

PROC R_EvictL2CacheEMSPage_ NEAR
PUBLIC R_EvictL2CacheEMSPage_


0x000000000000029a:  53                push      bx
0x000000000000029b:  51                push      cx
0x000000000000029c:  52                push      dx
0x000000000000029d:  56                push      si
0x000000000000029e:  57                push      di
0x000000000000029f:  8A 36 A9 06       mov       dh, byte ptr [0x6a9]
0x00000000000002a3:  88 F0             mov       al, dh
0x00000000000002a5:  98                cbw      
0x00000000000002a6:  89 C3             mov       bx, ax
0x00000000000002a8:  01 C3             add       bx, ax
0x00000000000002aa:  89 C6             mov       si, ax
0x00000000000002ac:  8A 87 55 1C       mov       al, byte ptr [bx + 0x1c55]
0x00000000000002b0:  A2 A9 06          mov       byte ptr [0x6a9], al
0x00000000000002b3:  98                cbw      
0x00000000000002b4:  89 C7             mov       di, ax
0x00000000000002b6:  01 C7             add       di, ax
0x00000000000002b8:  A0 A8 06          mov       al, byte ptr [0x6a8]
0x00000000000002bb:  98                cbw      
0x00000000000002bc:  C6 85 54 1C FF    mov       byte ptr [di + 0x1c54], 0xff
0x00000000000002c1:  89 C7             mov       di, ax
0x00000000000002c3:  01 C7             add       di, ax
0x00000000000002c5:  88 B5 55 1C       mov       byte ptr [di + 0x1c55], dh
0x00000000000002c9:  A0 A8 06          mov       al, byte ptr [0x6a8]
0x00000000000002cc:  C6 87 55 1C FF    mov       byte ptr [bx + 0x1c55], 0xff
0x00000000000002d1:  88 87 54 1C       mov       byte ptr [bx + 0x1c54], al
0x00000000000002d5:  88 36 A8 06       mov       byte ptr [0x6a8], dh
0x00000000000002d9:  C6 84 A0 01 01    mov       byte ptr [si + 0x1a0], 1
0x00000000000002de:  30 D2             xor       dl, dl
0x00000000000002e0:  B8 79 4E          mov       ax, 0x4e79
0x00000000000002e3:  88 D3             mov       bl, dl
0x00000000000002e5:  8E C0             mov       es, ax
0x00000000000002e7:  30 FF             xor       bh, bh
0x00000000000002e9:  26 8A 07          mov       al, byte ptr es:[bx]
0x00000000000002ec:  30 E4             xor       ah, ah
0x00000000000002ee:  89 C1             mov       cx, ax
0x00000000000002f0:  88 F0             mov       al, dh
0x00000000000002f2:  C1 F9 02          sar       cx, 2
0x00000000000002f5:  98                cbw      
0x00000000000002f6:  39 C1             cmp       cx, ax
0x00000000000002f8:  74 0F             je        0x309
0x00000000000002fa:  FE C2             inc       dl
0x00000000000002fc:  80 FA 97          cmp       dl, 0x97
0x00000000000002ff:  72 DF             jb        0x2e0
0x0000000000000301:  88 F0             mov       al, dh
0x0000000000000303:  5F                pop       di
0x0000000000000304:  5E                pop       si
0x0000000000000305:  5A                pop       dx
0x0000000000000306:  59                pop       cx
0x0000000000000307:  5B                pop       bx
0x0000000000000308:  CB                retf      
0x0000000000000309:  26 C6 07 FF       mov       byte ptr es:[bx], 0xff
0x000000000000030d:  EB EB             jmp       0x2fa

ENDP

PROC R_EvictL2CacheEMSPage_ NEAR
PUBLIC R_EvictL2CacheEMSPage_

0x0000000000000310:  56                push      si
0x0000000000000311:  57                push      di
0x0000000000000312:  55                push      bp
0x0000000000000313:  89 E5             mov       bp, sp
0x0000000000000315:  83 EC 02          sub       sp, 2
0x0000000000000318:  50                push      ax
0x0000000000000319:  52                push      dx
0x000000000000031a:  53                push      bx
0x000000000000031b:  8E C2             mov       es, dx
0x000000000000031d:  89 C3             mov       bx, ax
0x000000000000031f:  89 4E FE          mov       word ptr [bp - 2], cx
0x0000000000000322:  26 80 3F FF       cmp       byte ptr es:[bx], 0xff
0x0000000000000326:  74 5F             je        0x387
0x0000000000000328:  8B 4E FA          mov       cx, word ptr [bp - 6]
0x000000000000032b:  8B 5E FC          mov       bx, word ptr [bp - 4]
0x000000000000032e:  8E C1             mov       es, cx
0x0000000000000330:  26 8A 57 01       mov       dl, byte ptr es:[bx + 1]
0x0000000000000334:  26 8A 1F          mov       bl, byte ptr es:[bx]
0x0000000000000337:  8B 7E FE          mov       di, word ptr [bp - 2]
0x000000000000033a:  30 FF             xor       bh, bh
0x000000000000033c:  30 F6             xor       dh, dh
0x000000000000033e:  01 DF             add       di, bx
0x0000000000000340:  8B 5E FC          mov       bx, word ptr [bp - 4]
0x0000000000000343:  8B 76 FC          mov       si, word ptr [bp - 4]
0x0000000000000346:  01 D3             add       bx, dx
0x0000000000000348:  83 C6 03          add       si, 3
0x000000000000034b:  83 C3 04          add       bx, 4
0x000000000000034e:  89 D0             mov       ax, dx
0x0000000000000350:  89 5E FC          mov       word ptr [bp - 4], bx
0x0000000000000353:  85 FF             test      di, di
0x0000000000000355:  7C 36             jl        0x38d
0x0000000000000357:  89 FA             mov       dx, di
0x0000000000000359:  01 C2             add       dx, ax
0x000000000000035b:  3B 56 08          cmp       dx, word ptr [bp + 8]
0x000000000000035e:  76 05             jbe       0x365
0x0000000000000360:  8B 46 08          mov       ax, word ptr [bp + 8]
0x0000000000000363:  29 F8             sub       ax, di
0x0000000000000365:  85 C0             test      ax, ax
0x0000000000000367:  76 12             jbe       0x37b
0x0000000000000369:  8E 46 F8          mov       es, word ptr [bp - 8]
0x000000000000036c:  1E                push      ds
0x000000000000036d:  57                push      di
0x000000000000036e:  91                xchg      ax, cx
0x000000000000036f:  8E D8             mov       ds, ax
0x0000000000000371:  D1 E9             shr       cx, 1
0x0000000000000373:  F3 A5             rep movsw word ptr es:[di], word ptr [si]
0x0000000000000375:  13 C9             adc       cx, cx
0x0000000000000377:  F3 A4             rep movsb byte ptr es:[di], byte ptr [si]
0x0000000000000379:  5F                pop       di
0x000000000000037a:  1F                pop       ds
0x000000000000037b:  8E 46 FA          mov       es, word ptr [bp - 6]
0x000000000000037e:  8B 5E FC          mov       bx, word ptr [bp - 4]
0x0000000000000381:  26 80 3F FF       cmp       byte ptr es:[bx], 0xff
0x0000000000000385:  75 A1             jne       0x328
0x0000000000000387:  C9                LEAVE_MACRO     
0x0000000000000388:  5F                pop       di
0x0000000000000389:  5E                pop       si
0x000000000000038a:  C2 02 00          ret       2
0x000000000000038d:  01 F8             add       ax, di
0x000000000000038f:  31 FF             xor       di, di
0x0000000000000391:  EB C4             jmp       0x357
0x0000000000000393:  FC                cld       
0x0000000000000394:  51                push      cx
0x0000000000000395:  56                push      si
0x0000000000000396:  57                push      di
0x0000000000000397:  55                push      bp
0x0000000000000398:  89 E5             mov       bp, sp
0x000000000000039a:  83 EC 04          sub       sp, 4
0x000000000000039d:  89 C6             mov       si, ax
0x000000000000039f:  88 5E FC          mov       byte ptr [bp - 4], bl
0x00000000000003a2:  89 D0             mov       ax, dx
0x00000000000003a4:  C1 E8 08          shr       ax, 8
0x00000000000003a7:  88 46 FE          mov       byte ptr [bp - 2], al
0x00000000000003aa:  F6 C2 FF          test      dl, 0xff
0x00000000000003ad:  74 05             je        0x3b4
0x00000000000003af:  FE C0             inc       al
0x00000000000003b1:  88 46 FE          mov       byte ptr [bp - 2], al
0x00000000000003b4:  8A 46 FE          mov       al, byte ptr [bp - 2]
0x00000000000003b7:  30 E4             xor       ah, ah
0x00000000000003b9:  C1 F8 06          sar       ax, 6
0x00000000000003bc:  88 C5             mov       ch, al
0x00000000000003be:  F6 46 FE 3F       test      byte ptr [bp - 2], 0x3f
0x00000000000003c2:  74 02             je        0x3c6
0x00000000000003c4:  FE C5             inc       ch
0x00000000000003c6:  80 FD 01          cmp       ch, 1
0x00000000000003c9:  75 5F             jne       0x42a
0x00000000000003cb:  B6 40             mov       dh, 0x40
0x00000000000003cd:  2A 76 FE          sub       dh, byte ptr [bp - 2]
0x00000000000003d0:  30 D2             xor       dl, dl
0x00000000000003d2:  88 D0             mov       al, dl
0x00000000000003d4:  98                cbw      
0x00000000000003d5:  89 C3             mov       bx, ax
0x00000000000003d7:  3A B7 78 19       cmp       dh, byte ptr [bx + _usedtexturepagemem]
0x00000000000003db:  72 33             jb        0x410
0x00000000000003dd:  88 D6             mov       dh, dl
0x00000000000003df:  C0 E6 02          shl       dh, 2
0x00000000000003e2:  88 D0             mov       al, dl
0x00000000000003e4:  98                cbw      
0x00000000000003e5:  89 C3             mov       bx, ax
0x00000000000003e7:  8A 87 78 19       mov       al, byte ptr [bx + _usedtexturepagemem]
0x00000000000003eb:  8A 66 FE          mov       ah, byte ptr [bp - 2]
0x00000000000003ee:  00 C4             add       ah, al
0x00000000000003f0:  88 A7 78 19       mov       byte ptr [bx + _usedtexturepagemem], ah
0x00000000000003f4:  80 7E FC 02       cmp       byte ptr [bp - 4], 2
0x00000000000003f8:  75 2D             jne       0x427
0x00000000000003fa:  BB BD 83          mov       bx, PATCHOFFSET_SEGMENT
0x00000000000003fd:  81 C6 DC 01       add       si, PATCHOFFSET_OFFSET
0x0000000000000401:  8E C3             mov       es, bx
0x0000000000000403:  26 88 B4 24 FE    mov       byte ptr es:[si - PATCHOFFSET_OFFSET], dh
0x0000000000000408:  26 88 04          mov       byte ptr es:[si], al
0x000000000000040b:  C9                LEAVE_MACRO     
0x000000000000040c:  5F                pop       di
0x000000000000040d:  5E                pop       si
0x000000000000040e:  59                pop       cx
0x000000000000040f:  C3                ret       
0x0000000000000410:  FE C2             inc       dl
0x0000000000000412:  80 FA 18          cmp       dl, 0x18
0x0000000000000415:  7C BB             jl        0x3d2
0x0000000000000417:  8A 46 FC          mov       al, byte ptr [bp - 4]
0x000000000000041a:  98                cbw      
0x000000000000041b:  89 C2             mov       dx, ax
0x000000000000041d:  B8 01 00          mov       ax, 1
0x0000000000000420:  E8 DD FB          call      0
0x0000000000000423:  88 C2             mov       dl, al
0x0000000000000425:  EB B6             jmp       0x3dd
0x0000000000000427:  E9 1E 01          jmp       0x548
0x000000000000042a:  88 E9             mov       cl, ch
0x000000000000042c:  8A 36 AA 06       mov       dh, byte ptr ds:[_texturecache_l2_head]
0x0000000000000430:  FE C9             dec       cl
0x0000000000000432:  80 FE FF          cmp       dh, 0xff
0x0000000000000435:  75 03             jne       0x43a
0x0000000000000437:  E9 EE 00          jmp       0x528
0x000000000000043a:  88 F0             mov       al, dh
0x000000000000043c:  98                cbw      
0x000000000000043d:  89 C3             mov       bx, ax
0x000000000000043f:  80 BF 78 19 00    cmp       byte ptr [bx + _usedtexturepagemem], 0
0x0000000000000444:  74 03             je        0x449
0x0000000000000446:  E9 CB 00          jmp       0x514
0x0000000000000449:  C1 E3 02          shl       bx, 2
0x000000000000044c:  8A 87 08 18       mov       al, byte ptr [bx + 0x1808]
0x0000000000000450:  3C FF             cmp       al, 0xff
0x0000000000000452:  74 F2             je        0x446
0x0000000000000454:  98                cbw      
0x0000000000000455:  89 C3             mov       bx, ax
0x0000000000000457:  80 BF 78 19 00    cmp       byte ptr [bx + _usedtexturepagemem], 0
0x000000000000045c:  75 E8             jne       0x446
0x000000000000045e:  C1 E3 02          shl       bx, 2
0x0000000000000461:  8A 97 08 18       mov       dl, byte ptr [bx + 0x1808]
0x0000000000000465:  80 F9 02          cmp       cl, 2
0x0000000000000468:  72 03             jb        0x46d
0x000000000000046a:  E9 93 00          jmp       0x500
0x000000000000046d:  88 D0             mov       al, dl
0x000000000000046f:  98                cbw      
0x0000000000000470:  89 C3             mov       bx, ax
0x0000000000000472:  C1 E3 02          shl       bx, 2
0x0000000000000475:  8A 97 08 18       mov       dl, byte ptr [bx + 0x1808]
0x0000000000000479:  80 F9 03          cmp       cl, 3
0x000000000000047c:  73 6F             jae       0x4ed
0x000000000000047e:  88 F0             mov       al, dh
0x0000000000000480:  98                cbw      
0x0000000000000481:  89 C3             mov       bx, ax
0x0000000000000483:  C6 87 78 19 40    mov       byte ptr [bx + _usedtexturepagemem], 0x40
0x0000000000000488:  C1 E3 02          shl       bx, 2
0x000000000000048b:  88 AF 0B 18       mov       byte ptr [bx + 0x180b], ch
0x000000000000048f:  88 F2             mov       dl, dh
0x0000000000000491:  88 AF 0A 18       mov       byte ptr [bx + 0x180a], ch
0x0000000000000495:  80 FD 03          cmp       ch, 3
0x0000000000000498:  7C 1F             jl        0x4b9
0x000000000000049a:  8A 97 08 18       mov       dl, byte ptr [bx + 0x1808]
0x000000000000049e:  88 D0             mov       al, dl
0x00000000000004a0:  98                cbw      
0x00000000000004a1:  89 C3             mov       bx, ax
0x00000000000004a3:  89 C7             mov       di, ax
0x00000000000004a5:  88 E8             mov       al, ch
0x00000000000004a7:  C1 E7 02          shl       di, 2
0x00000000000004aa:  FE C8             dec       al
0x00000000000004ac:  88 AD 0B 18       mov       byte ptr [di + 0x180b], ch
0x00000000000004b0:  C6 87 78 19 40    mov       byte ptr [bx + _usedtexturepagemem], 0x40
0x00000000000004b5:  88 85 0A 18       mov       byte ptr [di + 0x180a], al
0x00000000000004b9:  88 D0             mov       al, dl
0x00000000000004bb:  98                cbw      
0x00000000000004bc:  89 C3             mov       bx, ax
0x00000000000004be:  C1 E3 02          shl       bx, 2
0x00000000000004c1:  8A 87 08 18       mov       al, byte ptr [bx + 0x1808]
0x00000000000004c5:  98                cbw      
0x00000000000004c6:  89 C7             mov       di, ax
0x00000000000004c8:  C1 E7 02          shl       di, 2
0x00000000000004cb:  89 C3             mov       bx, ax
0x00000000000004cd:  C6 85 0A 18 01    mov       byte ptr [di + 0x180a], 1
0x00000000000004d2:  8A 46 FE          mov       al, byte ptr [bp - 2]
0x00000000000004d5:  88 AD 0B 18       mov       byte ptr [di + 0x180b], ch
0x00000000000004d9:  A8 3F             test      al, 0x3f
0x00000000000004db:  74 5C             je        0x539
0x00000000000004dd:  24 3F             and       al, 0x3f
0x00000000000004df:  88 87 78 19       mov       byte ptr [bx + _usedtexturepagemem], al
0x00000000000004e3:  C0 E6 02          shl       dh, 2
0x00000000000004e6:  30 C0             xor       al, al
0x00000000000004e8:  00 CE             add       dh, cl
0x00000000000004ea:  E9 07 FF          jmp       0x3f4
0x00000000000004ed:  80 FA FF          cmp       dl, 0xff
0x00000000000004f0:  74 22             je        0x514
0x00000000000004f2:  88 D0             mov       al, dl
0x00000000000004f4:  98                cbw      
0x00000000000004f5:  89 C3             mov       bx, ax
0x00000000000004f7:  80 BF 78 19 00    cmp       byte ptr [bx + _usedtexturepagemem], 0
0x00000000000004fc:  74 80             je        0x47e
0x00000000000004fe:  EB 14             jmp       0x514
0x0000000000000500:  80 FA FF          cmp       dl, 0xff
0x0000000000000503:  74 0F             je        0x514
0x0000000000000505:  88 D0             mov       al, dl
0x0000000000000507:  98                cbw      
0x0000000000000508:  89 C3             mov       bx, ax
0x000000000000050a:  80 BF 78 19 00    cmp       byte ptr [bx + _usedtexturepagemem], 0
0x000000000000050f:  75 03             jne       0x514
0x0000000000000511:  E9 59 FF          jmp       0x46d
0x0000000000000514:  88 F0             mov       al, dh
0x0000000000000516:  98                cbw      
0x0000000000000517:  89 C3             mov       bx, ax
0x0000000000000519:  C1 E3 02          shl       bx, 2
0x000000000000051c:  8A B7 08 18       mov       dh, byte ptr [bx + 0x1808]
0x0000000000000520:  80 FE FF          cmp       dh, 0xff
0x0000000000000523:  74 03             je        0x528
0x0000000000000525:  E9 12 FF          jmp       0x43a
0x0000000000000528:  8A 46 FC          mov       al, byte ptr [bp - 4]
0x000000000000052b:  98                cbw      
0x000000000000052c:  89 C2             mov       dx, ax
0x000000000000052e:  88 E8             mov       al, ch
0x0000000000000530:  98                cbw      
0x0000000000000531:  E8 CC FA          call      0
0x0000000000000534:  88 C6             mov       dh, al
0x0000000000000536:  E9 45 FF          jmp       0x47e
0x0000000000000539:  C6 87 78 19 40    mov       byte ptr [bx + _usedtexturepagemem], 0x40
0x000000000000053e:  C0 E6 02          shl       dh, 2
0x0000000000000541:  30 C0             xor       al, al
0x0000000000000543:  00 CE             add       dh, cl
0x0000000000000545:  E9 AC FE          jmp       0x3f4
0x0000000000000548:  BB 81 4F          mov       bx, COMPOSITETEXTUREOFFSET_SEGMENT
0x000000000000054b:  81 C6 AC 01       add       si, COMPOSITETEXTUREOFFSET_OFFSET
0x000000000000054f:  8E C3             mov       es, bx
0x0000000000000551:  26 88 B4 54 FE    mov       byte ptr es:[si - 0x1ac], dh
0x0000000000000556:  26 88 04          mov       byte ptr es:[si], al
0x0000000000000559:  C9                LEAVE_MACRO     
0x000000000000055a:  5F                pop       di
0x000000000000055b:  5E                pop       si
0x000000000000055c:  59                pop       cx
0x000000000000055d:  C3                ret       


ENDP

PROC R_EvictL2CacheEMSPage_ NEAR
PUBLIC R_EvictL2CacheEMSPage_


0x000000000000055e:  53                push      bx
0x000000000000055f:  51                push      cx
0x0000000000000560:  52                push      dx
0x0000000000000561:  56                push      si
0x0000000000000562:  57                push      di
0x0000000000000563:  55                push      bp
0x0000000000000564:  89 E5             mov       bp, sp
0x0000000000000566:  83 EC 02          sub       sp, 2
0x0000000000000569:  89 C6             mov       si, ax
0x000000000000056b:  BB E6 00          mov       bx, 0xe6
0x000000000000056e:  2B 07             sub       ax, word ptr [bx]
0x0000000000000570:  89 C3             mov       bx, ax
0x0000000000000572:  01 C3             add       bx, ax
0x0000000000000574:  B8 AA 88          mov       ax, 0x88aa
0x0000000000000577:  8E C0             mov       es, ax
0x0000000000000579:  26 8B 07          mov       ax, word ptr es:[bx]
0x000000000000057c:  89 C2             mov       dx, ax
0x000000000000057e:  C1 EA 08          shr       dx, 8
0x0000000000000581:  88 56 FE          mov       byte ptr [bp - 2], dl
0x0000000000000584:  A8 FF             test      al, 0xff
0x0000000000000586:  74 05             je        0x58d
0x0000000000000588:  FE C2             inc       dl
0x000000000000058a:  88 56 FE          mov       byte ptr [bp - 2], dl
0x000000000000058d:  8A 46 FE          mov       al, byte ptr [bp - 2]
0x0000000000000590:  30 E4             xor       ah, ah
0x0000000000000592:  C1 F8 06          sar       ax, 6
0x0000000000000595:  88 C5             mov       ch, al
0x0000000000000597:  F6 46 FE 3F       test      byte ptr [bp - 2], 0x3f
0x000000000000059b:  74 02             je        0x59f
0x000000000000059d:  FE C5             inc       ch
0x000000000000059f:  80 FD 01          cmp       ch, 1
0x00000000000005a2:  75 5E             jne       0x602
0x00000000000005a4:  B6 40             mov       dh, 0x40
0x00000000000005a6:  2A 76 FE          sub       dh, byte ptr [bp - 2]
0x00000000000005a9:  30 D2             xor       dl, dl
0x00000000000005ab:  88 D0             mov       al, dl
0x00000000000005ad:  98                cbw      
0x00000000000005ae:  89 C3             mov       bx, ax
0x00000000000005b0:  3A B7 70 1C       cmp       dh, byte ptr [bx + 0x1c70]
0x00000000000005b4:  73 11             jae       0x5c7
0x00000000000005b6:  FE C2             inc       dl
0x00000000000005b8:  80 FA 14          cmp       dl, 0x14
0x00000000000005bb:  7C EE             jl        0x5ab
0x00000000000005bd:  B8 01 00          mov       ax, 1
0x00000000000005c0:  31 D2             xor       dx, dx
0x00000000000005c2:  E8 3B FA          call      0
0x00000000000005c5:  88 C2             mov       dl, al
0x00000000000005c7:  88 D6             mov       dh, dl
0x00000000000005c9:  C0 E6 02          shl       dh, 2
0x00000000000005cc:  88 D0             mov       al, dl
0x00000000000005ce:  98                cbw      
0x00000000000005cf:  89 C3             mov       bx, ax
0x00000000000005d1:  8A 87 70 1C       mov       al, byte ptr [bx + 0x1c70]
0x00000000000005d5:  8A 66 FE          mov       ah, byte ptr [bp - 2]
0x00000000000005d8:  00 C4             add       ah, al
0x00000000000005da:  88 A7 70 1C       mov       byte ptr [bx + 0x1c70], ah
0x00000000000005de:  BB E6 00          mov       bx, 0xe6
0x00000000000005e1:  89 F1             mov       cx, si
0x00000000000005e3:  2B 0F             sub       cx, word ptr [bx]
0x00000000000005e5:  89 CB             mov       bx, cx
0x00000000000005e7:  B9 83 4E          mov       cx, 0x4e83
0x00000000000005ea:  8E C1             mov       es, cx
0x00000000000005ec:  26 88 37          mov       byte ptr es:[bx], dh
0x00000000000005ef:  BB E6 00          mov       bx, 0xe6
0x00000000000005f2:  2B 37             sub       si, word ptr [bx]
0x00000000000005f4:  8D 9C 65 05       lea       bx, [si + 0x565]
0x00000000000005f8:  26 88 07          mov       byte ptr es:[bx], al
0x00000000000005fb:  C9                LEAVE_MACRO     
0x00000000000005fc:  5F                pop       di
0x00000000000005fd:  5E                pop       si
0x00000000000005fe:  5A                pop       dx
0x00000000000005ff:  59                pop       cx
0x0000000000000600:  5B                pop       bx
0x0000000000000601:  C3                ret       
0x0000000000000602:  88 E9             mov       cl, ch
0x0000000000000604:  8A 36 A6 06       mov       dh, byte ptr [0x6a6]
0x0000000000000608:  FE C9             dec       cl
0x000000000000060a:  80 FE FF          cmp       dh, 0xff
0x000000000000060d:  75 03             jne       0x612
0x000000000000060f:  E9 A7 00          jmp       0x6b9
0x0000000000000612:  88 F0             mov       al, dh
0x0000000000000614:  98                cbw      
0x0000000000000615:  89 C3             mov       bx, ax
0x0000000000000617:  80 BF 70 1C 00    cmp       byte ptr [bx + 0x1c70], 0
0x000000000000061c:  74 03             je        0x621
0x000000000000061e:  E9 84 00          jmp       0x6a5
0x0000000000000621:  C1 E3 02          shl       bx, 2
0x0000000000000624:  8A 87 68 18       mov       al, byte ptr [bx + 0x1868]
0x0000000000000628:  3C FF             cmp       al, 0xff
0x000000000000062a:  74 F2             je        0x61e
0x000000000000062c:  98                cbw      
0x000000000000062d:  89 C3             mov       bx, ax
0x000000000000062f:  80 BF 70 1C 00    cmp       byte ptr [bx + 0x1c70], 0
0x0000000000000634:  75 E8             jne       0x61e
0x0000000000000636:  C1 E3 02          shl       bx, 2
0x0000000000000639:  8A 97 68 18       mov       dl, byte ptr [bx + 0x1868]
0x000000000000063d:  80 F9 02          cmp       cl, 2
0x0000000000000640:  73 52             jae       0x694
0x0000000000000642:  88 D0             mov       al, dl
0x0000000000000644:  98                cbw      
0x0000000000000645:  89 C3             mov       bx, ax
0x0000000000000647:  C1 E3 02          shl       bx, 2
0x000000000000064a:  8A 97 68 18       mov       dl, byte ptr [bx + 0x1868]
0x000000000000064e:  80 F9 03          cmp       cl, 3
0x0000000000000651:  73 72             jae       0x6c5
0x0000000000000653:  88 F0             mov       al, dh
0x0000000000000655:  98                cbw      
0x0000000000000656:  89 C3             mov       bx, ax
0x0000000000000658:  C6 87 70 1C 40    mov       byte ptr [bx + 0x1c70], 0x40
0x000000000000065d:  C1 E3 02          shl       bx, 2
0x0000000000000660:  8A 87 68 18       mov       al, byte ptr [bx + 0x1868]
0x0000000000000664:  98                cbw      
0x0000000000000665:  88 AF 6B 18       mov       byte ptr [bx + 0x186b], ch
0x0000000000000669:  89 C7             mov       di, ax
0x000000000000066b:  88 AF 6A 18       mov       byte ptr [bx + 0x186a], ch
0x000000000000066f:  C1 E7 02          shl       di, 2
0x0000000000000672:  89 C3             mov       bx, ax
0x0000000000000674:  C6 85 6A 18 01    mov       byte ptr [di + 0x186a], 1
0x0000000000000679:  8A 46 FE          mov       al, byte ptr [bp - 2]
0x000000000000067c:  88 AD 6B 18       mov       byte ptr [di + 0x186b], ch
0x0000000000000680:  A8 3F             test      al, 0x3f
0x0000000000000682:  74 55             je        0x6d9
0x0000000000000684:  24 3F             and       al, 0x3f
0x0000000000000686:  88 87 70 1C       mov       byte ptr [bx + 0x1c70], al
0x000000000000068a:  C0 E6 02          shl       dh, 2
0x000000000000068d:  30 C0             xor       al, al
0x000000000000068f:  00 CE             add       dh, cl
0x0000000000000691:  E9 4A FF          jmp       0x5de
0x0000000000000694:  80 FA FF          cmp       dl, 0xff
0x0000000000000697:  74 0C             je        0x6a5
0x0000000000000699:  88 D0             mov       al, dl
0x000000000000069b:  98                cbw      
0x000000000000069c:  89 C3             mov       bx, ax
0x000000000000069e:  80 BF 70 1C 00    cmp       byte ptr [bx + 0x1c70], 0
0x00000000000006a3:  74 9D             je        0x642
0x00000000000006a5:  88 F0             mov       al, dh
0x00000000000006a7:  98                cbw      
0x00000000000006a8:  89 C3             mov       bx, ax
0x00000000000006aa:  C1 E3 02          shl       bx, 2
0x00000000000006ad:  8A B7 68 18       mov       dh, byte ptr [bx + 0x1868]
0x00000000000006b1:  80 FE FF          cmp       dh, 0xff
0x00000000000006b4:  74 03             je        0x6b9
0x00000000000006b6:  E9 59 FF          jmp       0x612
0x00000000000006b9:  88 E8             mov       al, ch
0x00000000000006bb:  31 D2             xor       dx, dx
0x00000000000006bd:  98                cbw      
0x00000000000006be:  E8 3F F9          call      0
0x00000000000006c1:  88 C6             mov       dh, al
0x00000000000006c3:  EB 8E             jmp       0x653
0x00000000000006c5:  80 FA FF          cmp       dl, 0xff
0x00000000000006c8:  74 DB             je        0x6a5
0x00000000000006ca:  88 D0             mov       al, dl
0x00000000000006cc:  98                cbw      
0x00000000000006cd:  89 C3             mov       bx, ax
0x00000000000006cf:  80 BF 70 1C 00    cmp       byte ptr [bx + 0x1c70], 0
0x00000000000006d4:  75 CF             jne       0x6a5
0x00000000000006d6:  E9 7A FF          jmp       0x653
0x00000000000006d9:  C6 87 70 1C 40    mov       byte ptr [bx + 0x1c70], 0x40
0x00000000000006de:  C0 E6 02          shl       dh, 2
0x00000000000006e1:  30 C0             xor       al, al
0x00000000000006e3:  00 CE             add       dh, cl
0x00000000000006e5:  E9 F6 FE          jmp       0x5de

ENDP


@

END
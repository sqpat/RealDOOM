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

push bx
push cx
push dx
push si
mov  cl, byte ptr ds:[_texturecache_l2_head]
mov  dl, al
cmp  al, cl
je   jump_to_label_1
cbw 
mov  bx, ax
SHIFT_MACRO shl  bx 2
mov  al, byte ptr ds:[bx + _texturecache_nodes+2]
test al, al
je   label_2
label_4:
mov  al, dl
cbw 
mov  bx, ax
SHIFT_MACRO shl  bx 2
mov  al, byte ptr ds:[bx + _texturecache_nodes+3]
cmp  al, byte ptr ds:[bx + _texturecache_nodes+2]
je   label_3
mov  dl, byte ptr ds:[bx + _texturecache_nodes+1]
jmp  label_4
label_3:
cmp  dl, cl
je   jump_to_label_1
label_2:
mov  al, dl
cbw 
mov  bx, ax
SHIFT_MACRO shl  bx 2
cmp  byte ptr ds:[bx + _texturecache_nodes+3], 0
je   jump_to_label_5
mov  dh, dl
label_11:
mov  al, dh
cbw 
mov  bx, ax
SHIFT_MACRO shl  bx 2
cmp  byte ptr ds:[bx + _texturecache_nodes+2], 1
je   label_12
mov  dh, byte ptr ds:[bx + _texturecache_nodes+0]
jmp  label_11
jump_to_label_1:
jmp  label_1
label_12:
mov  al, dl
cbw 
mov  si, ax
shl  si, 2
mov  bh, byte ptr ds:[bx + _texturecache_nodes+0]
mov  bl, byte ptr ds:[si + _texturecache_nodes+1]
cmp  dh, byte ptr ds:[_texturecache_l2_tail]
jne  label_8
mov  al, bl
cbw 
mov  byte ptr ds:[_texturecache_l2_tail], bl
mov  bx, ax
SHIFT_MACRO shl  bx 2
mov  byte ptr ds:[bx + _texturecache_nodes+0], -1
label_7:
mov  al, dh
cbw 
mov  bx, ax
mov  al, cl
SHIFT_MACRO shl  bx 2
cbw 
mov  byte ptr ds:[bx + _texturecache_nodes+0], cl
mov  bx, ax
mov  al, dl
SHIFT_MACRO shl  bx 2
cbw 
mov  byte ptr ds:[bx + _texturecache_nodes+1], dh
mov  bx, ax
SHIFT_MACRO shl  bx 2
mov  cl, dl
mov  byte ptr ds:[bx + _texturecache_nodes+1], -1
label_1:
mov  byte ptr ds:[_texturecache_l2_head], cl
pop  si
pop  dx
pop  cx
pop  bx
ret  
jump_to_label_5:
jmp  label_6
label_8:
mov  al, bh
cbw 
mov  si, ax
mov  al, bl
shl  si, 2
cbw 
mov  byte ptr ds:[si + _texturecache_nodes+1], bl
mov  si, ax
shl  si, 2
mov  byte ptr ds:[si + _texturecache_nodes+0], bh
jmp  label_7
label_6:
mov  dh, byte ptr ds:[bx + _texturecache_nodes+1]
mov  ch, byte ptr ds:[bx + _texturecache_nodes+0]
cmp  dl, byte ptr ds:[_texturecache_l2_tail]
jne  label_10
mov  byte ptr ds:[_texturecache_l2_tail], dh
label_9:
mov  al, dh
cbw 
mov  bx, ax
mov  al, dl
SHIFT_MACRO shl  bx 2
cbw 
mov  byte ptr ds:[bx + _texturecache_nodes+0], ch
mov  bx, ax
SHIFT_MACRO shl  bx 2
mov  al, cl
mov  byte ptr ds:[bx + _texturecache_nodes+1], -1
cbw 
mov  byte ptr ds:[bx + _texturecache_nodes+0], cl
mov  bx, ax
SHIFT_MACRO shl  bx 2
mov  cl, dl
mov  byte ptr ds:[bx + _texturecache_nodes+1], dl
mov  byte ptr ds:[_texturecache_l2_head], cl
pop  si
pop  dx
pop  cx
pop  bx
ret  
label_10:
mov  al, ch
cbw 
mov  bx, ax
SHIFT_MACRO shl  bx 2
mov  byte ptr ds:[bx + _texturecache_nodes+1], dh
jmp  label_9


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
push bx
push cx
push dx
push si
mov  si, OFFSET _spritecache_nodes
mov  cl, byte ptr ds:[_spritecache_l2_head]
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

;mov  al, dl
;cbw 
;mov  bx, ax
;shl  bx, 2

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

cmp  dh, byte ptr ds:[_spritecache_l2_tail]
jne  spritecache_l2_tail_not_equal_to_lastindex

;			spritecache_l2_tail = index_next;
;			spritecache_nodes[index_next].prev = -1;

mov  byte ptr ds:[_spritecache_l2_tail], cl
mov  bl, cl
SHIFT_MACRO   shl  bx 2
mov  byte ptr ds:[bx + si + 0], -1
jmp  sprite_done_with_multi_tail_update

spritecache_l2_tail_not_equal_to_lastindex:

;			spritecache_nodes[lastindex_prev].next = index_next;
;			spritecache_nodes[index_next].prev = lastindex_prev;

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
mov  al, byte ptr ds:[_spritecache_l2_head]
mov  byte ptr ds:[bx + si + 0], al  ; spritecache_l2_head
mov  bl, al
SHIFT_MACRO    shl  bx 2
mov  byte ptr ds:[bx + si + 1], dh  ; lastindex

mov  bl, dl
SHIFT_MACRO    shl  bx 2

;		spritecache_nodes[index].next = -1;
;		spritecache_l2_head = index;


mov  byte ptr ds:[_spritecache_l2_head], dl
mov  byte ptr ds:[bx + si + 1], -1
mark_sprite_lru_exit:
pop  si
pop  dx
pop  cx
pop  bx
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


cmp  dl, byte ptr ds:[_spritecache_l2_tail]
jne  spritecache_tail_not_equal_to_index
mov  byte ptr ds:[_spritecache_l2_tail], dh
jmp  done_with_spritecache_tail_handling

spritecache_tail_not_equal_to_index:
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

mov  byte ptr ds:[_spritecache_l2_head], dl

pop  si
pop  dx
pop  cx
pop  bx
ret  


ENDP

COMMENT @



PROC R_EvictL2CacheEMSPage_ NEAR
PUBLIC R_EvictL2CacheEMSPage_


ENDP


@

END
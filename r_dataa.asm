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
shl  bx, 2
mov  al, byte ptr ds:[bx + _texturecache_nodes+2]
test al, al
je   label_2
label_4:
mov  al, dl
cbw 
mov  bx, ax
shl  bx, 2
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
shl  bx, 2
cmp  byte ptr ds:[bx + _texturecache_nodes+3], 0
je   jump_to_label_5
mov  dh, dl
label_11:
mov  al, dh
cbw 
mov  bx, ax
shl  bx, 2
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
shl  bx, 2
mov  byte ptr ds:[bx + _texturecache_nodes+0], -1
label_7:
mov  al, dh
cbw 
mov  bx, ax
mov  al, cl
shl  bx, 2
cbw 
mov  byte ptr ds:[bx + _texturecache_nodes+0], cl
mov  bx, ax
mov  al, dl
shl  bx, 2
cbw 
mov  byte ptr ds:[bx + _texturecache_nodes+1], dh
mov  bx, ax
shl  bx, 2
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
shl  bx, 2
cbw 
mov  byte ptr ds:[bx + _texturecache_nodes+0], ch
mov  bx, ax
shl  bx, 2
mov  al, cl
mov  byte ptr ds:[bx + _texturecache_nodes+1], -1
cbw 
mov  byte ptr ds:[bx + _texturecache_nodes+0], cl
mov  bx, ax
shl  bx, 2
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
shl  bx, 2
mov  byte ptr ds:[bx + _texturecache_nodes+1], dh
jmp  label_9


ENDP



PROC R_MarkL2SpriteCacheMRU_ NEAR
PUBLIC R_MarkL2SpriteCacheMRU_

push bx
push cx
push dx
push si
mov  cl, byte ptr ds:[_spritecache_l2_head]
mov  dl, al
cmp  al, cl
je   jump_to_label_13
cbw 
mov  bx, ax
shl  bx, 2
mov  al, byte ptr ds:[bx + _spritecache_nodes+2]
test al, al
je   label_14
label_16:
mov  al, dl
cbw 
mov  bx, ax
shl  bx, 2
mov  al, byte ptr ds:[bx + _spritecache_nodes+2]
cmp  al, byte ptr ds:[bx + _spritecache_nodes+2]
je   label_15
mov  dl, byte ptr ds:[bx + _spritecache_nodes+1]
jmp  label_16
label_15:
cmp  dl, cl
je   jump_to_label_13
label_14:
mov  al, dl
cbw 
mov  bx, ax
shl  bx, 2
cmp  byte ptr ds:[bx + _spritecache_nodes+3], 0
je   jump_to_label_17
mov  dh, dl
label_19:
mov  al, dh
cbw 
mov  bx, ax
shl  bx, 2
cmp  byte ptr ds:[bx + _spritecache_nodes+2], 1
je   label_18
mov  dh, byte ptr ds:[bx + _spritecache_nodes+0]
jmp  label_19
jump_to_label_13:
jmp  label_13
label_18:
mov  al, dl
cbw 
mov  si, ax
shl  si, 2
mov  bh, byte ptr ds:[bx + _spritecache_nodes+0]
mov  bl, byte ptr ds:[si + _spritecache_nodes+1]
cmp  dh, byte ptr ds:[_spritecache_l2_tail]
jne  label_20
mov  al, bl
cbw 
mov  byte ptr ds:[_spritecache_l2_tail], bl
mov  bx, ax
shl  bx, 2
mov  byte ptr ds:[bx + _spritecache_nodes+0], -1
label_21:
mov  al, dh
cbw 
mov  bx, ax
mov  al, cl
shl  bx, 2
cbw 
mov  byte ptr ds:[bx + _spritecache_nodes+0], cl
mov  bx, ax
mov  al, dl
shl  bx, 2
cbw 
mov  byte ptr ds:[bx + _spritecache_nodes+1], dh
mov  bx, ax
shl  bx, 2
mov  cl, dl
mov  byte ptr ds:[bx + _spritecache_nodes+1], -1
label_13:
mov  byte ptr ds:[_spritecache_l2_head], cl
pop  si
pop  dx
pop  cx
pop  bx
ret  
jump_to_label_17:
jmp  label_17
label_20:
mov  al, bh
cbw 
mov  si, ax
mov  al, bl
shl  si, 2
cbw 
mov  byte ptr ds:[si + _spritecache_nodes+1], bl
mov  si, ax
shl  si, 2
mov  byte ptr ds:[si + _spritecache_nodes+0], bh
jmp  label_21
label_17:
mov  dh, byte ptr ds:[bx + _spritecache_nodes+1]
mov  ch, byte ptr ds:[bx + _spritecache_nodes+0]
cmp  dl, byte ptr ds:[_spritecache_l2_tail]
jne  label_22
mov  byte ptr ds:[_spritecache_l2_tail], dh
label_23:
mov  al, dh
cbw 
mov  bx, ax
mov  al, dl
shl  bx, 2
cbw 
mov  byte ptr ds:[bx + _spritecache_nodes+0], ch
mov  bx, ax
shl  bx, 2
mov  al, cl
mov  byte ptr ds:[bx + _spritecache_nodes+1], -1
cbw 
mov  byte ptr ds:[bx + _spritecache_nodes+0], cl
mov  bx, ax
shl  bx, 2
mov  cl, dl
mov  byte ptr ds:[bx + _spritecache_nodes+1], dl
mov  byte ptr ds:[_spritecache_l2_head], cl
pop  si
pop  dx
pop  cx
pop  bx
ret  
label_22:
mov  al, ch
cbw 
mov  bx, ax
shl  bx, 2
mov  byte ptr ds:[bx + _spritecache_nodes+1], dh
jmp  label_23

ENDP

COMMENT @



PROC R_EvictL2CacheEMSPage_ NEAR
PUBLIC R_EvictL2CacheEMSPage_


ENDP


@

END
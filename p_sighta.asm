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


EXTRN FixedMul1632_:FAR
EXTRN P_CrossBSPNode_:NEAR

INCLUDE CONSTANT.INC
INCLUDE defs.inc
INSTRUCTION_SET_MACRO

.DATA



.CODE

; boolean __far P_CheckSight (  mobj_t __near* t1, mobj_t __near* t2, mobj_pos_t __far* t1_pos, mobj_pos_t __far* t2_pos ) {

; ax = t1 (near ptr)
; dx = t2 (near ptr)
; bx = t1_pos (far offset)
; cx = t2_pos (far offset)

PROC    P_CheckSight_
PUBLIC  P_CheckSight_

push  si
push  di

push dx			; bp - 2

mov   si, cx    ; si gets t2_pos

; todo clean up this di shuffling
mov   es, ax    ; es holds t1
mov   di, dx    ; di gets t2
mov   ax, word ptr [di + 4]
cwd   

xchg  ax, cx  ; back up low
mov   di, es    ; di gets t1 
mov   ax, word ptr [di + 4]
mov   di, dx  ; back up high	di:cx holds first result

mul   word ptr ds:[_numsectors]
add   ax, cx
adc   dx, di

; generate reject bitmap lookup
mov   cx, ax	; cx is preshifted	
and   cl, 7		; will shift by this amount for bit count

; divide by 8 for 8 bits per byte..
shr   dx, 1
rcr   ax, 1
shr   dx, 1
rcr   ax, 1
shr   dx, 1
rcr   ax, 1

xchg  di, ax 			; di gets post-shifted.

mov   al, 1
shl   al, cl			; dl stores bit for bit test

mov   cx, es			; store t1 again

mov   dx, REJECTMATRIX_SEGMENT
mov   es, dx

test  al, byte ptr es:[di]	; bit test the byte

je    not_in_reject_table
xor   ax, ax				; return 0

pop   dx	; clean out the push earlier...
pop   di
pop   si
retf 

not_in_reject_table:
inc   word ptr ds:[_validcount_global]


mov   ax, MOBJPOSLIST_6800_SEGMENT
mov   es, ax
push  si  					; store for now

; todo is lds worth it for these dword reads..
mov   di, cx				; grab t1 again

;    sightzstart = t1_pos->z.w + t1->height.w - (t1->height.w>>2);

mov   cx, word ptr es:[bx + 8]
mov   si, word ptr es:[bx + 0Ah]
mov   ax, word ptr [di + 0Ah]
mov   dx, word ptr [di + 0Ch]
add   cx, ax
adc   si, dx			; si:cx result

sar   dx, 1
rcr   ax, 1
sar   dx, 1
rcr   ax, 1
sub   cx, ax
sbb   si, dx
mov   word ptr ds:[_sightzstart], cx	; cx has sightzstart
mov   word ptr ds:[_sightzstart + 2], si

xchg  ax, si				; ax gets sightzstart+2
pop   si					; recover si
pop   di 					; grab t2 again
push  bx					; store this... we dont need it for a while
xchg  ax, bx				; bx gets sightzstart+2

;    topslope = (t2_pos->z.w+t2->height.w) - sightzstart;

mov   ax, word ptr es:[si + 8]
mov   dx, word ptr es:[si + 0Ah]
add   ax, word ptr ds:[di + 0Ah]
adc   dx, word ptr ds:[di + 0Ch]	; last di use...
sub   ax, cx			; subtract sightzstart	
sbb   dx, bx

; swap es and ds...
push  ds
push  es
pop   ds
pop   es

mov   di, OFFSET _topslope

; write topslope
stosw
xchg  ax, dx
stosw

; cx:bx has sightzstart still..

mov   ax, word ptr ds:[si + 8]
mov   dx, word ptr ds:[si + 0Ah]
sub   ax, cx			; subtract sightzstart
sbb   dx, bx
; write bottomslope
stosw
xchg  ax, dx
stosw

; carried over address from above
;mov   di, OFFSET _cachedt2x
lodsw
stosw
xchg  ax, dx
lodsw
stosw
xchg  ax, cx	; cx:dx has si, si

; carried over address from above
;mov   di, OFFSET _cachedt2y	; todo remove once adjacent...
lodsw
stosw
xchg  ax, bx
lodsw
stosw			; ax:bx has si+4, si+6

pop   si		; restore old bx (t1 pos?)

; carried over address from above
;mov   di, OFFSET _strace

movsw
movsw
movsw
movsw

; writing _strace + 8 now.

xchg   ax, dx
sub    ax, word ptr ds:[si - 8]
sbb    cx, word ptr ds:[si - 6]
stosw
xchg   ax, cx
stosw

xchg   ax, bx
sub    ax, word ptr ds:[si - 4]
sbb    dx, word ptr ds:[si - 2]
stosw
xchg   ax, dx
stosw

mov  ax, ss
mov  ds, ax	; restore ds..

mov   ax, word ptr ds:[_numnodes]
dec   ax
call  P_CrossBSPNode_


pop   di
pop   si
retf 

ENDP

;int16_t __near P_DivlineSide ( fixed_t_union	x, fixed_t_union	y, divline_t __near*	node ) {

; node si
; dx:ax x
; cx:bx y

; todo make this take argument as si or something

PROC    P_DivlineSide_ NEAR
PUBLIC  P_DivlineSide_

	push di


;    if (!node->dx.w) {
;		if (x.w==node->x.w){
;			return 2;
;		}
;		
;		if (x.w <= node->x.w){
;			return node->dy.w > 0;
;		}
;
;		return node->dy.w < 0;
 ;   }
	; todo reduce register juggling...

	mov  di, bx
	mov  bx, ax

	mov  ax, dx
	mov  dx, cx
	mov  cx, word ptr [si + 0Ah]	; if (!node->dx.w) {
	or   cx, word ptr [si + 8]
	jne  node_dx_nonzero
	cmp  ax, word ptr [si + 2]
	jne  node_dx_not_x
	cmp  bx, word ptr [si]
	je   return_2
	node_dx_not_x:
	cmp  ax, word ptr [si + 2]
	jl   x_less_than_nodex
	jne  x_more_than_nodex
	cmp  bx, word ptr [si]
	ja   x_more_than_nodex
	x_less_than_nodex:
	mov  ax, word ptr [si + 0Eh]
	test ax, ax
	jg   divline_side_return_1
	jne  return_0
	cmp  word ptr [si + 0Ch], 0
	jbe  return_0
	divline_side_return_1:
	mov  ax, 1
	pop  di
	ret

	return_2:
	mov  ax, 2
	pop  di
	ret
	return_0:
	xor  ax, ax
	pop  di
	ret
	x_more_than_nodex:
	mov  ax, word ptr [si + 0Eh]
	test ax, ax
	jl   divline_side_return_1
	xor  ax, ax
	pop  di
	ret
	node_dx_nonzero:
	mov  cx, word ptr [si + 0Eh]
	or   cx, word ptr [si + 0Ch]
	jne  node_dy_nonzero
	cmp  ax, word ptr [si + 6]
	jne  node_dy_not_y
	cmp  bx, word ptr [si + 4]
	je   return_2
	node_dy_not_y:
	mov  ax, word ptr [si + 6]
	cmp  dx, ax
	jl   y_less_than_nodey
	jne  y_more_than_nodey
	cmp  di, word ptr [si + 4]
	ja   y_more_than_nodey
	y_less_than_nodey:
	mov  ax, word ptr [si + 0Ah]
	test ax, ax
	jl   divline_side_return_1
	xor  ax, ax
	pop  di
	ret
	y_more_than_nodey:
	mov  ax, word ptr [si + 0Ah]
	test ax, ax
	jg   divline_side_return_1
	jne  return_0_2
	cmp  word ptr [si + 8], 0
	ja   divline_side_return_1
	return_0_2:
	xor  ax, ax
	pop  di
	ret
	node_dy_nonzero:
	mov  cx, ax
	sub  bx, word ptr [si]
	mov  ax, word ptr [si + 0Eh]
	sbb  cx, word ptr [si + 2]
	sub  di, word ptr [si + 4]
	mov  di, dx
	mov  dx, cx
	sbb  di, word ptr [si + 6]
	imul dx
	mov  cx, ax
	mov  bx, dx
	mov  ax, di
	mov  dx, word ptr [si + 0Ah]
	imul dx
	cmp  dx, bx
	jl   return_0_2
	jne  compare_leftright
	cmp  ax, cx
	jb   return_0_2
	compare_leftright:
	cmp  bx, dx
	je   compare_leftright_low
	return_1_2:
	mov  ax, 1
	pop  di
	ret
	compare_leftright_low:
	cmp  cx, ax
	jne  return_1_2
	mov  ax, 2
	pop  di
	ret


ENDP

PROC    P_DivlineSide2_
PUBLIC  P_DivlineSide2_
ENDP

END
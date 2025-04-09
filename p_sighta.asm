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

; todo make this take argument as si or something

PROC    P_DivlineSide_ NEAR
PUBLIC  P_DivlineSide_

	push si
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

	mov  di, bx
	mov  bx, si
	mov  si, ax
	;mov  bx, word ptr [bp + 8]
	mov  ax, dx
	mov  dx, cx
	mov  cx, word ptr [bx + 0Ah]	; if (!node->dx.w) {
	or   cx, word ptr [bx + 8]
	jne  label_1
	cmp  ax, word ptr [bx + 2]
	jne  label_2
	cmp  si, word ptr [bx]
	je   label_3
	label_2:
	cmp  ax, word ptr [bx + 2]
	jl   label_4
	jne  label_5
	cmp  si, word ptr [bx]
	ja   label_5
	label_4:
	mov  ax, word ptr [bx + 0Eh]
	test ax, ax
	jg   divline_side_return_1
	jne  label_13
	cmp  word ptr [bx + 0Ch], 0
	jbe  label_13
	divline_side_return_1:
	mov  ax, 1
	divline_side_return:
	pop  di
	pop  si
	ret

	label_3:
	mov  ax, 2
	jmp  divline_side_return
	label_13:
	xor  ax, ax
	jmp  divline_side_return
	label_5:
	mov  ax, word ptr [bx + 0Eh]
	test ax, ax
	jl   divline_side_return_1
	xor  ax, ax
	jmp  divline_side_return
	label_1:
	mov  cx, word ptr [bx + 0Eh]
	or   cx, word ptr [bx + 0Ch]
	jne  label_15
	cmp  ax, word ptr [bx + 6]
	jne  label_16
	cmp  si, word ptr [bx + 4]
	je   label_3
	label_16:
	mov  ax, word ptr [bx + 6]
	cmp  dx, ax
	jl   label_11
	jne  label_10
	cmp  di, word ptr [bx + 4]
	ja   label_10
	label_11:
	mov  ax, word ptr [bx + 0Ah]
	test ax, ax
	jl   divline_side_return_1
	xor  ax, ax
	pop  di
	pop  si
	ret
	label_10:
	mov  ax, word ptr [bx + 0Ah]
	test ax, ax
	jg   divline_side_return_1
	jne  label_9
	cmp  word ptr [bx + 8], 0
	ja   divline_side_return_1
	label_9:
	xor  ax, ax
	pop  di
	pop  si
	ret
	label_15:
	mov  cx, ax
	sub  si, word ptr [bx]
	mov  ax, word ptr [bx + 0Eh]
	sbb  cx, word ptr [bx + 2]
	sub  di, word ptr [bx + 4]
	mov  di, dx
	mov  dx, cx
	sbb  di, word ptr [bx + 6]
	imul dx
	mov  cx, ax
	mov  si, dx
	mov  ax, di
	mov  dx, word ptr [bx + 0Ah]
	imul dx
	cmp  dx, si
	jl   label_9
	jne  label_14
	cmp  ax, cx
	jb   label_9
	label_14:
	cmp  si, dx
	je   label_8
	label_7:
	jmp  divline_side_return_1
	label_8:
	cmp  cx, ax
	jne  label_7
	mov  ax, 2
	pop  di
	pop  si
	ret


ENDP

PROC    P_DivlineSide2_
PUBLIC  P_DivlineSide2_
ENDP

END
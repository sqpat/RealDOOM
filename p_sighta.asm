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


EXTRN FixedMul2432_:PROC

; todo: move fixedmul2432 into this file? along with map stuff.

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
	; todo seems to be some repeated logic in here...
	jne  node_dx_nonzero
	cmp  ax, word ptr [si + 2]
	jne  node_dx_not_x
	cmp  bx, word ptr [si]
	je   return_2
	cmp  ax, word ptr [si + 2]
	node_dx_not_x:
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
	sub  bx, word ptr [si]
	sbb  ax, word ptr [si + 2]

	sub  di, word ptr [si + 4]
	sbb  dx, word ptr [si + 6]
	mov  di, dx

	imul word ptr [si + 0Eh]

	mov  bx, dx
	xchg ax, di	; bx:di gets result..
	imul word ptr [si + 0Ah]
	cmp  dx, bx
	jl   return_0_2
	jne  compare_leftright
	cmp  ax, di
	jb   return_0_2
	compare_leftright:
	cmp  bx, dx
	je   compare_leftright_low
	return_1_2:
	mov  ax, 1
	pop  di
	ret
	compare_leftright_low:
	cmp  di, ax
	jne  return_1_2
	mov  ax, 2
	pop  di
	ret


ENDP

; bx is always equal to strace
PROC    P_DivlineSide16_ NEAR
PUBLIC  P_DivlineSide16_

	push cx
	mov  cx, ax
	mov  ax, word ptr [bx + 0Ah]
	or   ax, word ptr [bx + 8]
	jne  node_dx_nonzero_16
	cmp  cx, word ptr [bx + 2]
	je   return_2_16
	mov  ax, word ptr [bx + 0Eh]
	jg   test_x_highbits_16
	test ax, ax
	jg   return_1_16
	jne  return_0_divlineside_16
	cmp  word ptr [bx + 0Ch], 0
	jbe  return_0_divlineside_16
	return_1_16:
	mov  ax, 1
	pop  cx
	ret  
	return_2_16:
	mov  ax, 2
	pop  cx
	ret  
	return_0_divlineside_16:
	xor  ax, ax
	pop  cx
	ret  
	test_x_highbits_16:
	test ax, ax
	jl   return_1_16
	xor  ax, ax
	pop  cx
	ret  
	node_dx_nonzero_16:
	mov  ax, word ptr [bx + 0Eh]
	or   ax, word ptr [bx + 0Ch]
	jne  node_dy_nonzero_16
	mov  ax, word ptr [bx + 6]
	cmp  cx, ax
	je   return_2_16
	cmp  dx, ax
	jg   test_y_highbits_16
	mov  ax, word ptr [bx + 0Ah]
	test ax, ax
	jl   return_1_16
	xor  ax, ax
	pop  cx
	ret

	test_y_highbits_16:
	mov  ax, word ptr [bx + 0Ah]
	test ax, ax
	jg   return_1_16
	jne  return_0_divlineside_16_2
	cmp  word ptr [bx + 8], 0
	ja   return_1_16
	return_0_divlineside_16_2:
	xor  ax, ax
	pop  cx
	ret  
	node_dy_nonzero_16:
	
	push di	; need this extra register
	; todo just mov and neg?	
	xor  ax, ax
	sub  ax, word ptr [bx]
	sbb  cx, word ptr [bx + 2]

	mov  di, dx

	xor  ax, ax
	sub  ax, word ptr [bx + 4]
	sbb  di, word ptr [bx + 6]

	xchg ax, cx		
	imul word ptr [bx + 0Eh]
	xchg ax, di		; cx:di gets result
	mov  cx, dx
	
	imul word ptr [bx + 0Ah]
	cmp  dx, cx
	jl   return_0_divlineside_16_3
	jne  test_right_left_16
	cmp  ax, di
	jb   return_0_divlineside_16_3
	test_right_left_16:
	cmp  cx, dx
	je   test_right_left_highbits_16
	return_1_2_16:
	mov  ax, 1
	pop  di
	pop  cx
	ret  

	return_0_divlineside_16_3:
	xor  ax, ax
	pop  di
	pop  cx
	ret  

	test_right_left_highbits_16:
	cmp  di, ax
	jne  return_1_2_16
	mov  ax, 2
	pop  di
	pop  cx
	ret  

ENDP

PROC    P_DivlineSideNode_ NEAR
PUBLIC  P_DivlineSideNode_


SHIFT_MACRO shl si 3

; es is NODES_SEGMENT
cmp   word ptr es:[si + 4], 0
jne   node_dx_nonzero_node

;		temp.h.intbits = node->x;
;		temp.h.fracbits = 0;
;
;		if (x.w==temp.w){
;			return 2;
;		}
;		
;		if (x.w <= temp.w){
;			return node->dy > 0;
;		}
;
;		return node->dy < 0;


cmp   dx, word ptr es:[si]
jne   node_dx_compare_1
test  ax, ax
je    return_2_node
cmp   dx, word ptr es:[si]
node_dx_compare_1:
jl    node_dx_compare_2
jne   node_dx_compare_3
test  ax, ax
jbe   node_dx_compare_2
node_dx_compare_3:
cmp   word ptr es:[si + 6], 0
jl    return_1_node
return_0_node:
xor   ax, ax
ret   
return_2_node:
mov   ax, 2
ret   
node_dx_compare_2:
cmp   word ptr es:[si + 6], 0
jle   return_0_node
return_1_node:
mov   ax, 1
ret   

node_dx_nonzero_node:
cmp   word ptr es:[si + 6], 0
jne   node_dy_nonzero_node
cmp   dx, word ptr es:[si + 2]
jne   node_dy_compare_1
test  ax, ax
je    return_2_node
node_dy_compare_1:
cmp   cx, word ptr es:[si + 2]
jl    node_dy_compare_2
jne   node_dy_compare_3
cmp   bx, 0
jbe   node_dy_compare_2
node_dy_compare_3:
cmp   word ptr es:[si + 4], 0
jle   return_0_node
mov   ax, 1
ret   
node_dy_compare_2:
cmp   word ptr es:[si + 4], 0
jge   return_0_node
return_1_node_2:
mov   ax, 1
ret   

node_dy_nonzero_node:
sub   dx, word ptr es:[si]
sub   cx, word ptr es:[si + 2]
xchg  ax, dx
imul  word ptr es:[si + 6]

xchg  ax, cx
mov   bx, dx				; result to bx:cx
imul  word ptr es:[si + 4]
cmp   dx, bx
jl    return_0_node
jne   compare_leftright_node
cmp   ax, cx
jae   compare_leftright_node
xor   ax, ax
ret
compare_leftright_node:
cmp   bx, dx
jne   return_1_node_2
cmp   cx, ax
jne   return_1_node_2
mov   ax, 2
ret   

ENDP


PROC    P_InterceptVector2_ NEAR
PUBLIC  P_InterceptVector2_


push  bp
mov   bp, sp
sub   sp, 8

mov   si, dx
mov   bx, word ptr [di + 8]
mov   cx, word ptr [di + 0Ah]
mov   ax, word ptr [si + 0Ch]
mov   dx, word ptr [si + 0Eh]

db 0FFh  ; lcall[addr]
db 01Eh  ;
dw _FixedMul2432_addr

mov   word ptr [bp - 8], ax
mov   word ptr [bp - 6], dx
mov   bx, word ptr [di + 0Ch]
mov   cx, word ptr [di + 0Eh]
mov   ax, word ptr [si + 8]
mov   dx, word ptr [si + 0Ah]

db 0FFh  ; lcall[addr]
db 01Eh  ;
dw _FixedMul2432_addr

mov   bx, word ptr [bp - 8]
sub   bx, ax
mov   ax, word ptr [bp - 6]
sbb   ax, dx
mov   word ptr [bp - 4], bx
mov   word ptr [bp - 2], ax
or    ax, bx
je    denominator_0
mov   bx, word ptr [si + 0Ch]
mov   cx, word ptr [si + 0Eh]
mov   ax, word ptr [si]
mov   dx, word ptr [si + 2]
sub   ax, word ptr [di]
sbb   dx, word ptr [di + 2]

db 0FFh  ; lcall[addr]
db 01Eh  ;
dw _FixedMul2432_addr

mov   word ptr [bp - 8], ax
mov   word ptr [bp - 6], dx
mov   bx, word ptr [si + 8]
mov   cx, word ptr [si + 0Ah]
mov   ax, word ptr [di + 4]
mov   dx, word ptr [di + 6]
sub   ax, word ptr [si + 4]
sbb   dx, word ptr [si + 6]

db 0FFh  ; lcall[addr]
db 01Eh  ;
dw _FixedMul2432_addr

mov   bx, word ptr [bp - 4]
mov   cx, word ptr [bp - 2]
add   ax, word ptr [bp - 8]
adc   dx, word ptr [bp - 6]

db 0FFh  ; lcall[addr]
db 01Eh  ;
dw _FixedDiv_addr

LEAVE_MACRO
ret   
denominator_0:
xor   dx, dx
LEAVE_MACRO 
ret   


ENDP


PROC    P_CrossSubsector_ NEAR
PUBLIC  P_CrossSubsector_

; bp - 2	lineflags
; bp - 4	unused (sectors segment)
; bp - 6	unused (sectors segment)
; bp - 8
; bp - 0A   4x segnum
; bp - 0C   2x segnum
; bp - 0E    count
; bp - 010   v2x
; bp - 012	segnum
; bp - 014   frac hibits
; bp - 016   frac lonits
; bp - 018
; bp - 01A   s1
; bp - 01C
; bp - 01E  
; bp - 020  (divl)  
; bp - 022
; bp - 024
; bp - 026
; bp - 028  
; bp - 02A
; bp - 02C
; bp - 02E  divl


push  bx
push  cx
push  dx
push  si
push  di
push  bp
mov   bp, sp
sub   sp, 02Eh
mov   bx, ax		; todo swap this argument order
mov   ax, SUBSECTOR_LINES_SEGMENT
mov   es, ax
mov   dx, SUBSECTORS_SEGMENT
mov   al, byte ptr es:[bx]			; count todo selfmodify this
SHIFT_MACRO shl bx 2
xor   ah, ah
mov   es, dx
mov   word ptr [bp - 0Eh], ax
mov   dx, word ptr es:[bx + 2]		; get segnum/firstline
mov   word ptr [bp - 012h], dx
test  ax, ax
je    cross_subsector_return_1
mov   ax, dx
sal   ax, 1
mov   word ptr [bp - 0Ch], ax		; store segnum x2?
shl   ax, 1
mov   word ptr [bp - 0Ah], ax		; store segnum x4?

cross_subsector_mainloop:
mov   ax, SEG_LINEDEFS_SEGMENT
mov   bx, word ptr [bp - 0Ch]
mov   es, ax
mov   ax, word ptr es:[bx]
mov   si, ax
SHIFT_MACRO shl si 4
mov   cx, LINES_PHYSICS_SEGMENT
mov   es, cx
mov   dx, word ptr es:[si + 8]
cmp   dx, word ptr ds:[_validcount_global]
jne   do_full_loop_iteration
cross_subsector_mainloop_increment:
add   word ptr [bp - 0Ch], 2
add   word ptr [bp - 0Ah], 4
inc   word ptr [bp - 012h]
dec   word ptr [bp - 0Eh]
jne   cross_subsector_mainloop	
cross_subsector_return_1:
mov   al, 1
LEAVE_MACRO 
pop   di
pop   si
pop   dx
pop   cx
pop   bx
ret   
do_full_loop_iteration:
mov   dx, LINEFLAGSLIST_SEGMENT
mov   es, dx
mov   bx, ax
mov   al, byte ptr es:[bx]
mov   byte ptr [bp - 2], al
mov   ax, word ptr ds:[_validcount_global]
mov   es, cx
mov   word ptr es:[si + 8], ax
les   di, dword ptr es:[si]		; linev1Offset
mov   bx, es					; linev2Offset
SHIFT_MACRO shl   di 2
and   bh, (VERTEX_OFFSET_MASK SHR 8)
SHIFT_MACRO shl   bx 2
mov   ax, VERTEXES_SEGMENT
mov   es, ax
mov   si, word ptr es:[di]		; v1.x
mov   dx, word ptr es:[di + 2]  ; v1.y into dx
les   ax, dword ptr es:[bx]		; v2.x

mov   cx, ax					; back up v2.x (es backs up v2.y)

sub   ax, si
mov   word ptr [bp - 024h], ax   ;	divl.dx.h.intbits = v2.x - v1.x;
mov   ax, es					; v2.y
sub   ax, dx

mov   word ptr [bp - 020h], ax  ;	divl.dy.h.intbits = v2.y - v1.y;
mov   word ptr [bp - 028h], dx

xchg  ax, si					; ax gets v1.x
mov   word ptr [bp - 02Ch], ax

mov   bx, OFFSET _strace

call  P_DivlineSide16_
; bx still _strace
xchg  di, ax	; store s1 result
mov   dx, es				; backed up v2.y
mov   ax, cx				; backed up v2.x
call  P_DivlineSide16_
cmp   ax, di
je    cross_subsector_mainloop_increment
; set up divl
xor   ax, ax
mov   word ptr [bp - 02Eh], ax
mov   word ptr [bp - 02Ah], ax
mov   word ptr [bp - 026h], ax
mov   word ptr [bp - 022h], ax

les   bx, dword ptr ds:[_strace + 4] 
mov   cx, es
les   ax, dword ptr ds:[_strace] 
mov   dx, es
lea   si, [bp - 02Eh]
call  P_DivlineSide_
mov   di, ax
les   bx, dword ptr ds:[_cachedt2y] 
mov   cx, es
les   ax, dword ptr ds:[_cachedt2x] 
mov   dx, es
; si still divl from above
call  P_DivlineSide_
cmp   di, ax
je   side_crossed

test  byte ptr [bp - 2], ML_TWOSIDED		; test flag
jne   two_sided
jump_to_cross_bsp_node_return_0:
jmp   cross_bsp_node_return_0	; todo optim out fallthru
side_crossed:
jump_to_cross_subsector_mainloop_increment:
jmp   cross_subsector_mainloop_increment

two_sided:
mov   ax, SEGS_PHYSICS_SEGMENT
mov   es, ax
mov   bx, word ptr [bp - 0Ah]
les   di, word ptr es:[bx]
mov   si, es

mov   ax, SECTORS_SEGMENT
mov   es, ax

SHIFT_MACRO shl   di 4
SHIFT_MACRO shl   si 4

mov   ax, word ptr es:[di]

add   bx, 2
cmp   ax, word ptr es:[si]
jne   label_6
mov   ax, word ptr es:[di + 2]
cmp   ax, word ptr es:[si + 2]
je    jump_to_cross_subsector_mainloop_increment
label_6:
mov   ax, word ptr es:[di + 2]
cmp   ax, word ptr es:[si + 2]
jl    label_7
mov   ax, word ptr es:[si + 2]
jmp   label_8
label_7:
mov   ax, word ptr es:[di + 2]
label_8:
mov   word ptr [bp - 8], ax
mov   ax, word ptr es:[di]
cmp   ax, word ptr es:[si]
jg    label_9
mov   bx, word ptr es:[si]
jmp   label_10
jump_to_cross_bsp_node_return_0_2:
jmp   cross_bsp_node_return_0	; todo optim out fallthru
label_9:
mov   bx, word ptr es:[di]
label_10:
cmp   bx, word ptr [bp - 8]
jge   jump_to_cross_bsp_node_return_0_2
lea   dx, [bp - 02Eh]
push  di
push  bx
push  si
mov   di, OFFSET _strace
call  P_InterceptVector2_		; todo inline ?
pop   si
pop   bx
pop   di
mov   word ptr [bp - 016h], ax
mov   word ptr [bp - 014h], dx
mov   cx, SECTORS_SEGMENT
mov   es, cx
mov   cx, word ptr es:[di]
cmp   cx, word ptr es:[si]
je    label_11
mov   cx, bx
and   bx, 7
SHIFT_MACRO sar   cx 3
SHIFT_MACRO shl   bx 0Dh
mov   word ptr [bp - 01Eh], cx
mov   word ptr [bp - 01Ch], bx
mov   cx, bx
mov   bx, OFFSET _sightzstart
mov   word ptr [bp - 01Ah], OFFSET _sightzstart
sub   cx, word ptr [bx]
mov   bx, word ptr [bp - 01Ah]
mov   word ptr [bp - 01Ah], cx
mov   cx, word ptr [bp - 01Eh]
sbb   cx, word ptr [bx + 2]
mov   word ptr [bp - 018h], cx
mov   bx, ax
mov   ax, word ptr [bp - 01Ah]
mov   cx, dx
mov   dx, word ptr [bp - 018h]

db 0FFh  ; lcall[addr]
db 01Eh  ;
dw _FixedDiv_addr


mov   bx, OFFSET _bottomslope
cmp   dx, word ptr [bx + 2]
jg    label_12
jne   label_11
cmp   ax, word ptr [bx]
jbe   label_11
label_12:
mov   word ptr [bx], ax
mov   word ptr [bx + 2], dx
label_11:
mov   ax, SECTORS_SEGMENT
mov   es, ax
mov   ax, word ptr es:[di + 2]
cmp   ax, word ptr es:[si + 2]
je    label_13
mov   ax, word ptr [bp - 8]
SHIFT_MACRO sar   ax 3
mov   word ptr [bp - 01Eh], ax
mov   ax, word ptr [bp - 8]
and   ax, 7
mov   bx, OFFSET _sightzstart
SHIFT_MACRO shl   ax 0Dh		; todo macro? whats this
mov   cx, word ptr [bp - 014h]
mov   word ptr [bp - 01Ch], ax
sub   ax, word ptr [bx]
mov   dx, word ptr [bp - 01Eh]
sbb   dx, word ptr [bx + 2]
mov   bx, word ptr [bp - 016h]

db 0FFh  ; lcall[addr]
db 01Eh  ;
dw _FixedDiv_addr

mov   bx, OFFSET _topslope
cmp   dx, word ptr [bx + 2]
jl    label_14
jne   label_13
cmp   ax, word ptr [bx]
jae   label_13
label_14:
mov   word ptr [bx], ax
mov   word ptr [bx + 2], dx
label_13:
mov   bx, OFFSET _topslope
mov   dx, word ptr [bx]
mov   ax, word ptr [bx + 2]
mov   bx, OFFSET _bottomslope
cmp   ax, word ptr [bx + 2]
jl    cross_bsp_node_return_0
je    label_15
jump_to_cross_subsector_mainloop_increment_2:
jmp   cross_subsector_mainloop_increment
label_15:
cmp   dx, word ptr [bx]
ja    jump_to_cross_subsector_mainloop_increment_2
cross_bsp_node_return_0:
xor   al, al
LEAVE_MACRO
pop   di
pop   si
pop   dx
pop   cx
pop   bx
ret   

ENDP




; what the heck?
; openwatcom turned this from a recursive to iterative function??? hello?? 

PROC    P_CrossBSPNode_ NEAR
PUBLIC  P_CrossBSPNode_

push  bx
push  cx
push  dx
push  si
push  di
push  bp
mov   bp, sp
sub   sp, 4
push  ax				; bp - 6
test  ah, (NF_SUBSECTOR SHR 8)
jne    is_subsector

iterate_bsp_recursion:
mov   si, OFFSET _strace
les   bx, dword ptr [si + 4]
mov   cx, es
les   ax, dword ptr [si]
mov   dx, es

mov   si, NODES_SEGMENT		; todo move this out?
mov   es, si
mov   si, word ptr [bp - 6]

call  P_DivlineSideNode_
and   al, 1
mov   byte ptr [bp - 2], al
mov   ax, word ptr [bp - 6]
SHIFT_MACRO shl ax 2
mov   word ptr [bp - 4], ax
mov   al, byte ptr [bp - 2]
cbw  
mov   bx, ax
mov   di, ax
add   bx, ax
mov   ax, NODE_CHILDREN_SEGMENT
mov   es, ax
add   bx, word ptr [bp - 4]
mov   ax, word ptr es:[bx]
call  P_CrossBSPNode_
test  al, al
je    exit_crossbspnode
mov   si, OFFSET _cachedt2x
les   bx, dword ptr [si + 4]	; cachedt2y
mov   cx, es
les   ax, dword ptr [si] 
mov   dx, es

mov   si, NODES_SEGMENT
mov   es, si
mov   si, word ptr [bp - 6]
call  P_DivlineSideNode_
cmp   di, ax
je    cross_bsp_node_return_1
mov   ax, NODE_CHILDREN_SEGMENT
mov   es, ax
mov   al, byte ptr [bp - 2]
xor   al, 1
cbw
mov   bx, word ptr [bp - 4]
sal   ax, 1		
add   bx, ax ; add side offset

; this right here!!! inlined function call to itself.

mov   ax, word ptr es:[bx]
mov   word ptr [bp - 6], ax
test  ah, (NF_SUBSECTOR SHR 8)
je    iterate_bsp_recursion

; this fallthru should be impossible????
is_subsector:
mov   ax, word ptr [bp - 6]
cmp   ax, 0FFFFh
jne   do_subsector_flag
; call with 0
xor   ax, ax
do_cross_subsector_call:
call  P_CrossSubsector_
exit_crossbspnode:
LEAVE_MACRO 
pop   di
pop   si
pop   dx
pop   cx
pop   bx
ret   
do_subsector_flag:
and   ah, (NOT_NF_SUBSECTOR SHR 8)
jmp   do_cross_subsector_call
cross_bsp_node_return_1:
mov   al, 1
LEAVE_MACRO
pop   di
pop   si
pop   dx
pop   cx
pop   bx
ret   

ENDP

PROC    P_DivlineSide2_
PUBLIC  P_DivlineSide2_
ENDP

END
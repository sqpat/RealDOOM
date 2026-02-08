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


; todo: move fixedmul2432 into this file? along with map stuff.

INCLUDE CONSTANT.INC
INCLUDE defs.inc
INSTRUCTION_SET_MACRO_NO_MEDIUM
;.CODE PARA
EXTRN FixedDiv_MapLocal_:NEAR
EXTRN FixedMul2432_MapLocal_:NEAR


SEGMENT P_SIGHT_TEXT USE16 PARA PUBLIC 'CODE'
ASSUME  CS:P_SIGHT_TEXT

PROC    P_SIGHT_STARTMARKER_ 
PUBLIC  P_SIGHT_STARTMARKER_
ENDP

_rndtable_9000:

 db 0,   8, 109, 220, 222, 241, 149, 107,  75, 248, 254, 140,  16,  66  
 db 74,  21, 211,  47,  80, 242, 154,  27, 205, 128, 161,  89,  77,  36 
 db 95, 110,  85,  48, 212, 140, 211, 249,  22,  79, 200,  50,  28, 188 
 db 52, 140, 202, 120,  68, 145,  62,  70, 184, 190,  91, 197, 152, 224 
 db 149, 104,  25, 178, 252, 182, 202, 182, 141, 197,   4,  81, 181, 242
 db 145,  42,  39, 227, 156, 198, 225, 193, 219,  93, 122, 175, 249,   0
 db 175, 143,  70, 239,  46, 246, 163,  53, 163, 109, 168, 135,   2, 235
 db 25,  92,  20, 145, 138,  77,  69, 166,  78, 176, 173, 212, 166, 113 
 db 94, 161,  41,  50, 239,  49, 111, 164,  70,  60,   2,  37, 171,  75 
 db 136, 156,  11,  56,  42, 146, 138, 229,  73, 146,  77,  61,  98, 196
 db 135, 106,  63, 197, 195,  86,  96, 203, 113, 101, 170, 247, 181, 113
 db 80, 250, 108,   7, 255, 237, 129, 226,  79, 107, 112, 166, 103, 241 
 db 24, 223, 239, 120, 198,  58,  60,  82, 128,   3, 184,  66, 143, 224 
 db 145, 224,  81, 206, 163,  45,  63,  90, 168, 114,  59,  33, 159,  95
 db 28, 139, 123,  98, 125, 196,  15,  70, 194, 253,  54,  14, 109, 226 
 db 71,  17, 161,  93, 186,  87, 244, 138,  20,  52, 123, 251,  26,  36 
 db 17,  46,  52, 231, 232,  76,  31, 221,  84,  37, 216, 165, 212, 106 
 db 197, 242,  98,  43,  39, 175, 254, 145, 190,  84, 118, 222, 187, 136
 db 120, 163, 236, 249


; boolean __far P_CheckSight (  mobj_t __near* t1, mobj_t __near* t2, mobj_pos_t __far* t1_pos, mobj_pos_t __far* t2_pos ) {

; ax = t1 (near ptr)
; dx = t2 (near ptr)
; bx = t1_pos (far offset)
; cx = t2_pos (far offset)
; return in carry
PROC    P_CheckSight_ NEAR
PUBLIC  P_CheckSight_

push  si
push  di

push  dx		; bp - 2

mov   si, cx    ; si gets t2_pos

; todo clean up this di shuffling
mov   es, ax    ; es holds t1
mov   di, dx    ; di gets t2
mov   ax, word ptr ds:[di + MOBJ_T.m_secnum]
cwd   

xchg  ax, cx  ; back up low
mov   di, es    ; di gets t1 
mov   ax, word ptr ds:[di + MOBJ_T.m_secnum]
mov   di, dx  ; back up high	di:cx holds first result

mul   word ptr ds:[_numsectors]
add   ax, cx
adc   dx, di

; generate reject bitmap lookup
mov   cx, ax	; cx is preshifted	
and   cl, 7		; will shift by this amount for bit count

; divide by 8 for 8 bits per byte..
SHIFT32_MACRO_RIGHT dx ax 3

xchg  di, ax 			; di gets post-shifted.

mov   al, 1
shl   al, cl			; dl stores bit for bit test

mov   cx, es			; store t1 again

mov   dx, REJECTMATRIX_SEGMENT
mov   es, dx

test  al, byte ptr es:[di]	; bit test the byte

je    not_in_reject_table
clc

pop   dx	; clean out the push earlier...
pop   di
pop   si
ret 

not_in_reject_table:
inc   word ptr ds:[_validcount_global]


mov   ax, MOBJPOSLIST_SEGMENT
mov   es, ax
push  si  					; store for now

; todo is lds worth it for these dword reads..
mov   di, cx				; grab t1 again

;    sightzstart = t1_pos->z.w + t1->height.w - (t1->height.w>>2);

mov   cx, word ptr es:[bx + MOBJ_POS_T.mp_z + 0]
mov   si, word ptr es:[bx + MOBJ_POS_T.mp_z + 2]
mov   ax, word ptr ds:[di + MOBJ_T.m_height + 0]
mov   dx, word ptr ds:[di + MOBJ_T.m_height + 2]
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

mov   ax, word ptr es:[si + MOBJ_POS_T.mp_z + 0]
mov   dx, word ptr es:[si + MOBJ_POS_T.mp_z + 2]
add   ax, word ptr ds:[di + MOBJ_T.m_height + 0]
adc   dx, word ptr ds:[di + MOBJ_T.m_height + 2]	; last di use...
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

mov   ax, word ptr ds:[si + MOBJ_POS_T.mp_z + 0]
mov   dx, word ptr ds:[si + MOBJ_POS_T.mp_z + 2]
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
call  P_CrossBSPNode_ ; return carry thru 


pop   di
pop   si
ret 

ENDP

;int16_t __near P_DivlineSide ( fixed_t_union	x, fixed_t_union	y, divline_t __near*	node ) {

; node si
; dx:ax x
; cx:bx y

; todo make this take argument as si or something

PROC    P_DivlineSide_ NEAR
PUBLIC  P_DivlineSide_



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
	mov  cx, word ptr ds:[si + 0Ah]	; if (!node->dx.w) {
	or   cx, word ptr ds:[si + 8]
	; todo seems to be some repeated logic in here...
	jne  node_dx_nonzero
	cmp  ax, word ptr ds:[si + 2]
	jne  node_dx_not_x
	cmp  bx, word ptr ds:[si]
	je   return_2
	cmp  ax, word ptr ds:[si + 2]
	node_dx_not_x:
	jl   x_less_than_nodex
	jne  x_more_than_nodex
	cmp  bx, word ptr ds:[si]
	ja   x_more_than_nodex
	x_less_than_nodex:
	mov  ax, word ptr ds:[si + 0Eh]
	test ax, ax
	jg   divline_side_return_1
	jne  return_0
	cmp  word ptr ds:[si + 0Ch], 0
	jbe  return_0
	divline_side_return_1:
	mov  ax, 1
	ret

	return_2:
	mov  ax, 2
	ret
	return_0:
	xor  ax, ax
	ret
	x_more_than_nodex:
	mov  ax, word ptr ds:[si + 0Eh]
	test ax, ax
	jl   divline_side_return_1
	xor  ax, ax
	ret
	node_dx_nonzero:
	mov  cx, word ptr ds:[si + 0Eh]
	or   cx, word ptr ds:[si + 0Ch]
	jne  node_dy_nonzero
	cmp  ax, word ptr ds:[si + 6]
	jne  node_dy_not_y
	cmp  bx, word ptr ds:[si + 4]
	je   return_2
	node_dy_not_y:
	mov  ax, word ptr ds:[si + 6]
	cmp  dx, ax
	jl   y_less_than_nodey
	jne  y_more_than_nodey
	cmp  di, word ptr ds:[si + 4]
	ja   y_more_than_nodey
	y_less_than_nodey:
	mov  ax, word ptr ds:[si + 0Ah]
	test ax, ax
	jl   divline_side_return_1
	xor  ax, ax
	ret
	y_more_than_nodey:
	mov  ax, word ptr ds:[si + 0Ah]
	test ax, ax
	jg   divline_side_return_1
	jne  return_0_2
	cmp  word ptr ds:[si + 8], 0
	ja   divline_side_return_1
	return_0_2:
	xor  ax, ax
	ret
	node_dy_nonzero:
	sub  bx, word ptr ds:[si]
	sbb  ax, word ptr ds:[si + 2]

	sub  di, word ptr ds:[si + 4]
	sbb  dx, word ptr ds:[si + 6]
	mov  di, dx

	imul word ptr ds:[si + 0Eh]

	mov  bx, dx
	xchg ax, di	; bx:di gets result..
	imul word ptr ds:[si + 0Ah]
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
	ret
	compare_leftright_low:
	cmp  di, ax
	jne  return_1_2
	mov  ax, 2
	ret


ENDP

; bx is always equal to strace
PROC    P_DivlineSide16_ NEAR
PUBLIC  P_DivlineSide16_

	push cx
	mov  cx, ax
	mov  ax, word ptr ds:[bx + 0Ah]
	or   ax, word ptr ds:[bx + 8]
	jne  node_dx_nonzero_16
	cmp  cx, word ptr ds:[bx + 2]
	je   return_2_16
	mov  ax, word ptr ds:[bx + 0Eh]
	jg   test_x_highbits_16
	test ax, ax
	jg   return_1_16
	jne  return_0_divlineside_16
	cmp  word ptr ds:[bx + 0Ch], 0
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
	mov  ax, word ptr ds:[bx + 0Eh]
	or   ax, word ptr ds:[bx + 0Ch]
	jne  node_dy_nonzero_16
	mov  ax, word ptr ds:[bx + 6]
	cmp  cx, ax
	je   return_2_16
	cmp  dx, ax
	jg   test_y_highbits_16
	mov  ax, word ptr ds:[bx + 0Ah]
	test ax, ax
	jl   return_1_16
	xor  ax, ax
	pop  cx
	ret

	test_y_highbits_16:
	mov  ax, word ptr ds:[bx + 0Ah]
	test ax, ax
	jg   return_1_16
	jne  return_0_divlineside_16_2
	cmp  word ptr ds:[bx + 8], 0
	ja   return_1_16
	return_0_divlineside_16_2:
	xor  ax, ax
	pop  cx
	ret  
	node_dy_nonzero_16:
	
	push di	; need this extra register
	; todo just mov and neg?	
	xor  ax, ax
	sub  ax, word ptr ds:[bx]
	sbb  cx, word ptr ds:[bx + 2]

	mov  di, dx

	xor  ax, ax
	sub  ax, word ptr ds:[bx + 4]
	sbb  di, word ptr ds:[bx + 6]

	xchg ax, cx		
	imul word ptr ds:[bx + 0Eh]			; lots of cycles spent here!
	xchg ax, di		; cx:di gets result
	mov  cx, dx
	
	imul word ptr ds:[bx + 0Ah]
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

; returns 0 1 or 2?
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


; return in carry
PROC    P_CrossSubsector_ NEAR
PUBLIC  P_CrossSubsector_

; bp - 2	lineflags
; bp - 4    2x segnum
; bp - 6	frac hibits
; bp - 8    frac lonits
; bp - 0A   count
; bp - 0C 	(divl end)  
; bp - 0E   (divl)
; bp - 010  (divl)
; bp - 012	(divl)
; bp - 014  (divl)
; bp - 016  (divl)
; bp - 018  (divl)
; bp - 01A  divl start
; bp - 01Ch   [used by inlined P_InterceptVector2_ ]
; bp - 01Eh   [used by inlined P_InterceptVector2_ ]
; bp - 020h	  [used by inlined P_InterceptVector2_ ]
; bp - 022h   [used by inlined P_InterceptVector2_ ]



PUSHA_NO_AX_OR_BP_MACRO
push  bp
mov   bp, sp
sub   sp, 022h
mov   bx, ax		; todo swap this argument order
mov   ax, SUBSECTOR_LINES_SEGMENT
mov   es, ax
mov   dx, SUBSECTORS_SEGMENT
mov   al, byte ptr es:[bx]			; count todo selfmodify this
SHIFT_MACRO shl bx 2
xor   ah, ah
mov   es, dx
mov   word ptr [bp - 0Ah], ax
mov   dx, word ptr es:[bx + SUBSECTOR_T.ss_firstline]		; get segnum/firstline   ; todo move after test?
test  ax, ax
je    cross_subsector_return_1
mov   ax, dx
sal   ax, 1
mov   word ptr [bp - 4], ax		; store segnum x2?


cross_subsector_mainloop:
mov   ax, SEG_LINEDEFS_SEGMENT
mov   es, ax
mov   bx, word ptr [bp - 4]
mov   ax, word ptr es:[bx]
mov   si, ax
SHIFT_MACRO shl si 4
mov   cx, LINES_PHYSICS_SEGMENT
mov   es, cx
mov   dx, word ptr es:[si + LINE_PHYSICS_T.lp_validcount]
cmp   dx, word ptr ds:[_validcount_global]
jne   do_full_loop_iteration
cross_subsector_mainloop_increment:
add   word ptr [bp - 4], 2
dec   word ptr [bp - 0Ah]
jne   cross_subsector_mainloop	
cross_subsector_return_1:
stc
LEAVE_MACRO 
POPA_NO_AX_OR_BP_MACRO
ret   
do_full_loop_iteration:
mov   dx, LINEFLAGSLIST_SEGMENT
mov   es, dx
mov   bx, ax
mov   al, byte ptr es:[bx]
mov   byte ptr [bp - 2], al				; todo selfmodify ahead
mov   ax, word ptr ds:[_validcount_global]
mov   es, cx
mov   word ptr es:[si + LINE_PHYSICS_T.lp_validcount], ax
les   di, dword ptr es:[si]		; linev1Offset
mov   bx, es					; linev2Offset
SHIFT_MACRO shl   di 2
and   bh, (VERTEX_OFFSET_MASK SHR 8)
SHIFT_MACRO shl   bx 2
mov   es, word ptr ds:[_VERTEXES_SEGMENT_PTR]
mov   si, word ptr es:[di]		; v1.x
mov   dx, word ptr es:[di + 2]  ; v1.y into dx
les   ax, dword ptr es:[bx]		; v2.x
mov   cx, ax					; back up v2.x (es backs up v2.y)

sub   ax, si
mov   word ptr [bp - 010h], ax   ;	divl.dx.h.intbits = v2.x - v1.x;
mov   ax, es					; v2.y
sub   ax, dx

mov   word ptr [bp - 0Ch], ax  ;	divl.dy.h.intbits = v2.y - v1.y;
mov   word ptr [bp - 014h], dx	;   v1.y

xchg  ax, si					; ax gets v1.x
mov   word ptr [bp - 018h], ax  ;   v1.x

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
mov   word ptr [bp - 01Ah], ax
mov   word ptr [bp - 016h], ax
mov   word ptr [bp - 012h], ax
mov   word ptr [bp - 00Eh], ax

les   bx, dword ptr ds:[_strace + 4] 
mov   cx, es
les   ax, dword ptr ds:[_strace] 
mov   dx, es
lea   si, [bp - 01Ah]
call  P_DivlineSide_
mov   di, ax
les   bx, dword ptr ds:[_cachedt2y] 
mov   cx, es
les   ax, dword ptr ds:[_cachedt2x] 
mov   dx, es
; si still divl from above
push  di
call  P_DivlineSide_
pop   di
cmp   di, ax
je   side_crossed

test  byte ptr [bp - 2], ML_TWOSIDED		; test flag
je    jump_to_cross_bsp_node_return_0_2	; todo optim out fallthru

two_sided:

mov   ax, SEG_LINEDEFS_SEGMENT
mov   es, ax
mov   bx, word ptr [bp - 4]
mov   si, word ptr es:[bx]
SHIFT_MACRO shl si 4
mov   ax, LINES_PHYSICS_SEGMENT
mov   es, ax
les   di, dword ptr es:[si + LINE_PHYSICS_T.lp_frontsecnum]
mov   si, es

SHIFT_MACRO shl di 4
SHIFT_MACRO shl si 4


; di/si not preshfited

mov   ax, SECTORS_SEGMENT
mov   es, ax


mov   ax, word ptr es:[di + SECTOR_T.sec_floorheight]

cmp   ax, word ptr es:[si + SECTOR_T.sec_floorheight]
mov   ax, word ptr es:[di + SECTOR_T.sec_ceilingheight]
jne   floor_ceiling_heights_dont_match
cmp   ax, word ptr es:[si + SECTOR_T.sec_ceilingheight]
je    jump_to_cross_subsector_mainloop_increment
floor_ceiling_heights_dont_match:
cmp   ax, word ptr es:[si + SECTOR_T.sec_ceilingheight]
jl    set_opentop_to_frontsector
mov   ax, word ptr es:[si + SECTOR_T.sec_ceilingheight]
jmp   opentop_set
side_crossed:
jump_to_cross_subsector_mainloop_increment:
jmp   cross_subsector_mainloop_increment

set_opentop_to_frontsector:
mov   ax, word ptr es:[di + SECTOR_T.sec_ceilingheight]

opentop_set:
mov   cx, ax	; store opentop
mov   word ptr cs:[SELFMODIFY_PSIGHT_setopentop + 1 - P_SIGHT_STARTMARKER_], ax
mov   ax, word ptr es:[di + SECTOR_T.sec_floorheight]
cmp   ax, word ptr es:[si + SECTOR_T.sec_floorheight]
jg    set_openbottom_to_frontsector
mov   bx, word ptr es:[si + SECTOR_T.sec_floorheight]
jmp   openbottom_set
jump_to_cross_bsp_node_return_0_2:
jmp   cross_bsp_node_return_0	; todo optim out fallthru
set_openbottom_to_frontsector:
mov   bx, word ptr es:[di + SECTOR_T.sec_floorheight]
openbottom_set:
cmp   bx, cx
jge   jump_to_cross_bsp_node_return_0_2
push  di
push  bx
push  si
mov   di, OFFSET _strace

; inlined P_InterceptVector2_

lea   si, [bp - 01Ah]
mov   bx, word ptr ds:[di + 8]
mov   cx, word ptr ds:[di + 0Ah]
mov   ax, word ptr ds:[si + 0Ch]
mov   dx, word ptr ds:[si + 0Eh]

call  FixedMul2432_MapLocal_

mov   word ptr [bp - 022h], ax
mov   word ptr [bp - 020h], dx
mov   bx, word ptr ds:[di + 0Ch]
mov   cx, word ptr ds:[di + 0Eh]
mov   ax, word ptr ds:[si + 8]
mov   dx, word ptr ds:[si + 0Ah]

call  FixedMul2432_MapLocal_

mov   bx, word ptr [bp - 022h]
sub   bx, ax
mov   ax, word ptr [bp - 020h]
sbb   ax, dx
mov   word ptr [bp - 01Eh], bx
mov   word ptr [bp - 01Ch], ax
or    ax, bx
je    denominator_0
mov   bx, word ptr ds:[si + 0Ch]
mov   cx, word ptr ds:[si + 0Eh]
mov   ax, word ptr ds:[si]
mov   dx, word ptr ds:[si + 2]
sub   ax, word ptr ds:[di]
sbb   dx, word ptr ds:[di + 2]

call  FixedMul2432_MapLocal_

mov   word ptr [bp - 022h], ax
mov   word ptr [bp - 020h], dx
mov   bx, word ptr ds:[si + 8]
mov   cx, word ptr ds:[si + 0Ah]
mov   ax, word ptr ds:[di + 4]
mov   dx, word ptr ds:[di + 6]
sub   ax, word ptr ds:[si + 4]
sbb   dx, word ptr ds:[si + 6]

call  FixedMul2432_MapLocal_

mov   bx, word ptr [bp - 01Eh]
mov   cx, word ptr [bp - 01Ch]
add   ax, word ptr [bp - 022h]
adc   dx, word ptr [bp - 020h]

call  FixedDiv_MapLocal_


jmp done_with_intercept_vector

denominator_0:
xor   dx, dx

done_with_intercept_vector:

pop   si
pop   bx
pop   di

mov   word ptr [bp - 8], ax	; store frac
mov   word ptr [bp - 6], dx
mov   cx, SECTORS_SEGMENT
mov   es, cx
mov   cx, word ptr es:[di + SECTOR_T.sec_floorheight]
cmp   cx, word ptr es:[si + SECTOR_T.sec_floorheight]
je    done_setting_bottomslope

; fixed height from shortheight

xor   cx, cx
sar   bx, 1
rcr   cx, 1
sar   bx, 1
rcr   cx, 1
sar   bx, 1
rcr   cx, 1

; BX:CX has what should become dx:ax
; dx:ax has what should become cx:bx...

xchg ax, cx
sub   ax, word ptr ds:[_sightzstart]
xchg dx, bx
sbb   dx, word ptr ds:[_sightzstart + 2]
xchg cx, bx			;  frac into cx:bx

call  FixedDiv_MapLocal_



mov   bx, OFFSET _bottomslope
cmp   dx, word ptr ds:[bx + 2]
jg    update_bottom_slope
jne   done_setting_bottomslope
cmp   ax, word ptr ds:[bx]
jbe   done_setting_bottomslope
update_bottom_slope:
mov   word ptr ds:[bx], ax
mov   word ptr ds:[bx + 2], dx
done_setting_bottomslope:
mov   ax, SECTORS_SEGMENT
mov   es, ax
mov   ax, word ptr es:[di + 2]
cmp   ax, word ptr es:[si + 2]
je    done_setting_topslope

; fixed height from shortheight
xor   ax, ax
SELFMODIFY_PSIGHT_setopentop:
mov   dx, 01000h		; opentop
sar   dx, 1
rcr   ax, 1
sar   dx, 1
rcr   ax, 1
sar   dx, 1
rcr   ax, 1

sub   ax, word ptr ds:[_sightzstart]
sbb   dx, word ptr ds:[_sightzstart + 2]

les   bx, dword ptr [bp - 8]	; load frac into cx:bx
mov   cx, es

call  FixedDiv_MapLocal_


mov   bx, OFFSET _topslope
cmp   dx, word ptr ds:[bx + 2]
jl    update_topslope
jne   done_setting_topslope
cmp   ax, word ptr ds:[bx]
jae   done_setting_topslope
update_topslope:
mov   word ptr ds:[bx], ax
mov   word ptr ds:[bx + 2], dx
done_setting_topslope:
les   dx, dword ptr ds:[_topslope]
mov   ax, es
cmp   ax, word ptr ds:[_bottomslope + 2]
jl    cross_bsp_node_return_0
jne   jump_to_cross_subsector_mainloop_increment_2
cmp   dx, word ptr ds:[_bottomslope]
ja    jump_to_cross_subsector_mainloop_increment_2
cross_bsp_node_return_0:
clc
LEAVE_MACRO
POPA_NO_AX_OR_BP_MACRO
ret   
jump_to_cross_subsector_mainloop_increment_2:
jmp   cross_subsector_mainloop_increment

ENDP




; what the heck?
; openwatcom turned this from a recursive to iterative function??? hello?? 


; todo update to new bsp traversal method?

;return carry
PROC    P_CrossBSPNode_ NEAR
PUBLIC  P_CrossBSPNode_

PUSHA_NO_AX_OR_BP_MACRO
push  bp
mov   bp, sp
sub   sp, 4
push  ax				; bp - 6
test  ah, (NF_SUBSECTOR SHR 8)
jne    is_subsector

iterate_bsp_recursion:
mov   si, OFFSET _strace
les   bx, dword ptr ds:[si + 4]
mov   cx, es
les   ax, dword ptr ds:[si]
mov   dx, es

mov   si, NODES_SEGMENT		; todo move this out?
mov   es, si
mov   si, word ptr [bp - 6]

call  P_DivlineSideNode_
and   ax, 1
mov   word ptr [bp - 2], ax
mov   ax, word ptr [bp - 6]
SHIFT_MACRO shl ax 2
mov   word ptr [bp - 4], ax
mov   ax, word ptr [bp - 2]
mov   bx, ax
mov   di, ax
add   bx, ax
mov   ax, NODE_CHILDREN_SEGMENT
mov   es, ax
add   bx, word ptr [bp - 4]
mov   ax, word ptr es:[bx]
call  P_CrossBSPNode_
jnc   exit_crossbspnode
mov   si, OFFSET _cachedt2x
les   bx, dword ptr ds:[si + 4]	; cachedt2y
mov   cx, es
les   ax, dword ptr ds:[si] 
mov   dx, es

mov   si, NODES_SEGMENT
mov   es, si
mov   si, word ptr [bp - 6]
call  P_DivlineSideNode_
cmp   di, ax
je    cross_bsp_node_return_1
mov   ax, NODE_CHILDREN_SEGMENT
mov   es, ax
mov   ax, word ptr [bp - 2]
xor   al, 1
mov   bx, word ptr [bp - 4]
sal   ax, 1		
add   bx, ax ; add side offset

; this right here!!! inlined function call to itself.

mov   ax, word ptr es:[bx]
mov   word ptr [bp - 6], ax
test  ah, (NF_SUBSECTOR SHR 8)
je    iterate_bsp_recursion

; this fallthru should be impossible???? not sure
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
POPA_NO_AX_OR_BP_MACRO
ret   
do_subsector_flag:
and   ah, (NOT_NF_SUBSECTOR SHR 8)
jmp   do_cross_subsector_call
cross_bsp_node_return_1:
stc
LEAVE_MACRO
POPA_NO_AX_OR_BP_MACRO
ret   

ENDP

PROC    P_SIGHT_ENDMARKER_
PUBLIC  P_SIGHT_ENDMARKER_
ENDP

ENDS

END
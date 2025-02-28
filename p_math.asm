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
INCLUDE CONSTANT.INC
INCLUDE defs.inc
INSTRUCTION_SET_MACRO

.DATA
.CODE



;R_PointOnSide_

PROC R_PointOnSide_ NEAR
PUBLIC R_PointOnSide_ 

push  di
push  bp
mov   bp, sp
push  bx
push  ax

; DX:AX = x
; CX:BX = y
; segindex = si


; node_t
;    int16_t	x;
;    int16_t	y;
;    int16_t	dx;
;    int16_t	dy;
;    uint16_t   children[2];

; nodes are 8 bytes each. node children are 4 each.

; todo eventually return child value instead of node

SHIFT_MACRO shl si 2

mov   ax, NODE_CHILDREN_SEGMENT
mov   es, ax



; todo lds?
mov   ds, word ptr es:[si + 00h]   ; child 0
mov   di, word ptr es:[si + 02h]   ; child 1

push  di ; child 1 to go into es later...

shl   si, 1     ; 8 indexed
mov   ax, NODES_SEGMENT
mov   es, ax  ; ES for nodes lookup


;  get lx, ly, ldx, ldy

les   bx, dword ptr es:[si + 0]   ; lx
mov   di, es   					  ; ly
mov   es, ax

les   ax, dword ptr es:[si + 4]   ; ldx
mov   si, es                      ; ldy



pop   es ; shove child 1 in es..




; ax = ldx
; si = ldy
; bx = lx
; di = ly
; dx = x highbits
; cx = y highbits
; bp -4h = x lowbits
; bp -2h = y lowbits
; ds = child 0
; es = child 1

;    if (!node->dx) 

test  ax, ax
jne   node_dx_nonequal

;        if (x <= (node->x shift 16) )
;  compare high bits
cmp   dx, bx
jl    return_node_dy_greater_than_0
jne   return_node_dy_less_than_0

; compare low bits

cmp   word ptr [bp - 04h], 0
jbe   return_node_dy_greater_than_0

 
return_node_dy_less_than_0:
;        return node->dy < 0;
cmp   si, 0
jl    return_true

return_false:
mov   ax, ds
mov   di, ss ;  restore ds
mov   ds, di
LEAVE_MACRO
pop   di
ret   

;            return node->dy > 0;

return_node_dy_greater_than_0:
cmp  si, 0
jle  return_false

return_true:


mov   ax, es
mov   di, ss ;  restore ds
mov   ds, di
LEAVE_MACRO
pop   di
ret   

node_dx_nonequal:


;    if (!node->dy) {
test  si, si

jne   node_dy_nonzero

;        if (y.w <= (node_y shift 16))
;  compare high bits

cmp   cx, di
jl    ret_node_dx_less_than_0
jne   ret_ldx_greater_than_0
;  compare low bits
cmp   word ptr [bp - 02h], 0
jbe   ret_node_dx_less_than_0
ret_ldx_greater_than_0:
;        return node->dx > 0
cmp   ax, 0
jg    return_true

; return false
mov   ax, ds

mov   di, ss ;  restore ds
mov   ds, di

LEAVE_MACRO
pop   di
ret    
ret_node_dx_less_than_0:

;            return node->dx < 0;

cmp    ax, 0
jl    return_true

; return false
mov   ax, ds

mov   di, ss ;  restore ds
mov   ds, di

LEAVE_MACRO
pop   di
ret   

node_dy_nonzero:



;    dx.w = (x.w - (lx shift 16));
;    dy.w = (y.w - (ly shift 16));



sub   dx, bx
sub   cx, di




;    Try to quickly decide by looking at sign bits.
;    if ( (ldy ^ ldx ^ dx.h.intbits ^ dy.h.intbits)&0x8000 )  // returns 1


mov   bx, ax
xor   bx, si
xor   bx, dx
xor   bx, cx
test  bh, 080h
jne   do_sign_bit_return

xchg si, ax

; gross - we must do a lot of work in this case. 
mov   di, cx  ; store cx.. 
pop bx
mov   cx, dx
push  es ; note - fixedmul clobbers ES. need to store that.


call FixedMul1632_

; set up params..
xchg  si, ax
pop   es
pop   bx
mov   cx, di

mov   di, dx
push  es ; note - fixedmul clobbers ES. need to store that.
call FixedMul1632_
pop  es
cmp   dx, di
jg    return_true_2
je    check_lowbits

return_false_2:
mov   ax, ds
mov   di, ss ;  restore ds
mov   ds, di
pop   bp
pop   di
ret   

check_lowbits:
cmp   ax, si
jb    return_false_2
return_true_2:
mov   ax, es

mov   di, ss ;  restore ds
mov   ds, di

LEAVE_MACRO
pop   di
ret   
do_sign_bit_return:

;		// (left is negative)
;		return  ((ldy ^ dx.h.intbits) & 0x8000);  // returns 1

xor   si, dx
jl    return_true_2

mov   ax, ds


mov   di, ss ;  restore ds
mov   ds, di

LEAVE_MACRO
pop   di
ret   


endp

END

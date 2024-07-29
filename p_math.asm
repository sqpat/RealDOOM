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


NODES_SEGMENT        = 0EB5Fh   
EXTRN FixedMul1632_:PROC 

.DATA
.CODE



;R_PointOnSide3_

PROC R_PointOnSide3_ NEAR
PUBLIC R_PointOnSide3_ 

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

; nodes are 12 bytes each. need to get the index..

; todo eventually return child value instead of node

shl   si, 1     ; 2
shl   si, 1     ; 4
mov   ax, si    ; set 4
shl   si, 1     ; 8
add   si, ax    ; 8 + 4

mov   ax, NODES_SEGMENT

mov   es, ax  ; ES for nodes lookup



;  get lx, ly, ldx, ldy

mov   bx, word ptr es:[si + 0];   lx
mov   di, word ptr es:[si + 2];   ly

mov   es, ax  ; juggle ax around isntead of putting on stack...

mov   ax, word ptr es:[si + 4]   ; ldx
mov   si, word ptr es:[si + 6]   ; ldy


xchg  ax, si     ; optimize and remove later..


; si = ldx
; ax = ldy
; bx = lx
; di = ly
; dx = x highbits
; cx = y highbits
; bp -4h = x lowbits
; bp -2h = y lowbits


;    if (!node->dx) 

test  si, si
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
cmp   ax, 0
jl    return_true

return_false:
xor   ax, ax
mov   di, ss ;  restore ds
mov   ds, di
mov   sp, bp
pop   bp 
pop   di
ret   

;            return node->dy > 0;

return_node_dy_greater_than_0:
cmp  ax, 0
jle  return_false

return_true:

; getting here?

mov   ax, 1
mov   di, ss ;  restore ds
mov   ds, di
mov   sp, bp
pop   bp 
pop   di
ret   

node_dx_nonequal:


;    if (!node->dy) {
test  ax, ax

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
cmp   si, 0
; todo double check jge vs jg
jg    return_true

; return false
xor   ax, ax

mov   di, ss ;  restore ds
mov   ds, di

mov   sp, bp
pop   bp 
pop   di
ret   
ret_node_dx_less_than_0:

;            return node->dx < 0;

cmp    si, 0
jl    return_true

; return false
xor   ax, ax

mov   di, ss ;  restore ds
mov   ds, di

mov   sp, bp
pop   bp 
pop   di
ret   

node_dy_nonzero:



;    dx.w = (x.w - (lx shift 16));
;    dy.w = (y.w - (ly shift 16));



sub   dx, bx
sub   cx, di


; lx  bx f4c0
; ly  di fca0
; ldx si 0010
; ldy ax 0010
; xhi dx f4f0 ...  0030
; yhi cx fcb0 ...  0010



;    Try to quickly decide by looking at sign bits.
;    if ( (ldy ^ ldx ^ dx.h.intbits ^ dy.h.intbits)&0x8000 )  // returns 1


mov   bx, ax
xor   bx, si
xor   bx, dx
xor   bx, cx
test  bh, 080h
jne   do_sign_bit_return

; gross - we must do a lot of work in this case. 
mov   di, cx  ; store cx.. 
pop bx
mov   cx, dx
call FixedMul1632_

; 0x3000000 ?

; set up params..
pop bx
mov   cx, di
mov   ds, ax
mov   ax, si
mov   di, dx
call FixedMul1632_
cmp   dx, di
jg    return_true_2
je    check_lowbits
return_false_2:
xor   ax, ax
mov   di, ss ;  restore ds
mov   ds, di
pop   bp
pop   di
ret   

check_lowbits:
mov   cx, ds
cmp   ax, cx
jb    return_false_2
return_true_2:
mov   ax, 1

mov   di, ss ;  restore ds
mov   ds, di

mov   sp, bp
pop   bp 
pop   di
ret   
do_sign_bit_return:

;		// (left is negative)
;		return  ((ldy ^ dx.h.intbits) & 0x8000);  // returns 1

xor   ax, dx
xor   al, al
and   ah, 080h
rol   ax, 1

mov   di, ss ;  restore ds
mov   ds, di

mov   sp, bp
pop   bp 
pop   di
ret   


endp

END

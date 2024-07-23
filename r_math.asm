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
    .286
	.MODEL  medium

EXTRN _tantoangle:DWORD
EXTRN _viewx:DWORD
EXTRN _viewy:DWORD
EXTRN FastDiv3232_shift_3_8_:PROC

INCLUDE defs.inc

.CODE

;R_PointToAngle_

PROC R_PointToAngle_
PUBLIC R_PointToAngle_

; inputs:
; DX:AX = x  (32 bit fixed pt 16:16)
; CX:BX = y  (32 bit fixed pt 16:16)

push  si
push  di
mov   di, ax
mov   si, dx
mov   ax, bx
mov   dx, cx

;	x.w -= viewx.w;
;	y.w -= viewy.w;


; si:di = x
; dx:ax = y



sub   di, word ptr [_viewx]
sbb   si, word ptr [_viewx+2]
mov   bx, si
sub   ax, word ptr [_viewy]
sbb   dx, word ptr [_viewy+2]

; 	if ((!x.w) && (!y.w))
;		return 0;

or    bx, di
jne   inputs_not_zero   ; todo rearrange this. rare case
mov   bx, dx
or    bx, ax
je    return_0


inputs_not_zero:
test  si, si
jg    x_is_positive
jne   x_is_negative_1

x_is_positive:
test  dx, dx
jg    y_is_positive
jne   y_is_negative_1
y_is_positive:

cmp   si, dx
jg    octant_0

jne   octant_1
cmp   di, ax
jbe   octant_1


octant_0:
test  si, si    ; todo unnecessary...

;	if (x.w < 512)

jl    octant_0_out_of_bounds
jne   octant_0_do_divide
cmp   di, 0200h
jae   octant_0_do_divide
octant_0_out_of_bounds:
mov   dx, 02000h
xor   ax, ax
pop   di
pop   si
retf  

return_0:

xor   ax, ax
xor   dx, dx
pop   di
pop   si
retf  

octant_0_do_divide:
mov   bx, di
mov   cx, si
call FastDiv3232_shift_3_8_
cmp   ax, 0800h
jae   octant_0_out_of_bounds

mov   si, word ptr [_tantoangle]
shl   ax, 2
mov   es, word ptr [_tantoangle+2]
add   si, ax
mov   ax, word ptr es:[si]
mov   dx, word ptr es:[si + 2]
pop   di
pop   si
retf  

x_is_negative_1:

jmp   x_is_negative
y_is_negative_1:
jmp   y_is_negative

octant_1:
test  dx, dx
jl    octant_1_out_of_bounds
jne   octant_1_do_divide
cmp   ax, 0200h
jae   octant_1_do_divide
octant_1_out_of_bounds:
mov   ax, 0ffffh
mov   dx, 01fffh
pop   di
pop   si
retf  
octant_1_do_divide:
mov   bx, ax
mov   cx, dx
mov   ax, di
mov   dx, si
call FastDiv3232_shift_3_8_
cmp   ax, 0800h
jae   octant_1_out_of_bounds
mov   si, word ptr [_tantoangle]
shl   ax, 2
mov   es, word ptr [_tantoangle+2]
add   si, ax
mov   ax, 0ffffh
sub   ax, word ptr es:[si]
mov   dx, 03fffh
sbb   dx, word ptr es:[si + 2]
pop   di
pop   si
retf  

y_is_negative:
;			y.w = -y.w;

neg   dx
neg   ax
sbb   dx, 0

cmp   si, dx
jg    octant_4
jne   octant_5
cmp   di, ax
jbe   octant_5
octant_4:
test  si, si
jl    octant_4_out_of_bounds
jne   octant_4_do_divide
cmp   di, 0200h
jae   octant_4_do_divide
octant_4_out_of_bounds:
mov   dx, 0e000h
xor   ax, ax
pop   di
pop   si
retf  
octant_4_do_divide:
mov   cx, si
mov   bx, di
call FastDiv3232_shift_3_8_
cmp   ax, 0800h
jae   octant_4_out_of_bounds
mov   si, word ptr [_tantoangle]
shl   ax, 2
mov   es, word ptr [_tantoangle+2]
add   si, ax
mov   dx, word ptr es:[si + 2]
mov   ax, word ptr es:[si]
neg   dx
neg   ax
sbb   dx, 0
pop   di
pop   si
retf  
octant_5:
test  dx, dx
jl    octant_5_out_of_bounds
jne   octant_5_do_divide
cmp   ax, 0200h
jae   octant_5_do_divide
octant_5_out_of_bounds:
mov   dx, 0e000h
xor   ax, ax
pop   di
pop   si
retf  
octant_5_do_divide:
mov   bx, ax
mov   cx, dx
mov   ax, di
mov   dx, si
call FastDiv3232_shift_3_8_
cmp   ax, 0800h
jae   octant_5_out_of_bounds
mov   si, word ptr [_tantoangle]
shl   ax, 2
mov   es, word ptr [_tantoangle+2]
add   si, ax
mov   ax, word ptr es:[si]
add   ax, 0
mov   dx, word ptr es:[si + 2]
adc   dx, 0c000h
pop   di
pop   si
retf  

x_is_negative:

;		x.w = -x.w;

neg   si
neg   di
sbb   si, 0

test  dx, dx
jg    y_is_positive_x_neg
jne   y_is_negative_x_neg_1
y_is_positive_x_neg:
cmp   si, dx
jg    octant_3
jne   octant_2
cmp   di, ax
jbe   octant_2

octant_3:
test  si, si
jl    octant_3_out_of_bounds
jne   octant_3_do_divide
cmp   di, 0200h
jae   octant_3_do_divide
octant_3_out_of_bounds:
mov   ax, 0ffffh
mov   dx, 05fffh
pop   di
pop   si
retf  
octant_3_do_divide:
mov   bx, di
mov   cx, si
call FastDiv3232_shift_3_8_
cmp   ax, 0800h
jae   octant_3_out_of_bounds
mov   si, word ptr [_tantoangle]
shl   ax, 2
mov   es, word ptr [_tantoangle+2]
add   si, ax
mov   ax, 0ffffh
sub   ax, word ptr es:[si]
mov   dx, 07fffh
sbb   dx, word ptr es:[si + 2]
pop   di
pop   si
retf  
octant_2:
test  dx, dx
jl    octant_2_out_of_bounds
jne   octant_2_do_divide
cmp   ax, 0200h
jae   octant_2_do_divide
octant_2_out_of_bounds:
mov   dx, 06000h
xor   ax, ax
pop   di
pop   si
retf  
y_is_negative_x_neg_1:
jmp   y_is_negative_x_neg
octant_2_do_divide:
mov   bx, ax
mov   cx, dx
mov   ax, di
mov   dx, si
call FastDiv3232_shift_3_8_
cmp   ax, 0800h
jae   octant_2_out_of_bounds
mov   si, word ptr [_tantoangle]
shl   ax, 2
mov   es, word ptr [_tantoangle+2]
add   si, ax
mov   ax, word ptr es:[si]
add   ax, 0
mov   dx, word ptr es:[si + 2]
adc   dx, 04000h
pop   di
pop   si
retf  
y_is_negative_x_neg:

;			y.w = -y.w;

neg   dx
neg   ax
sbb   dx, 0
cmp   si, dx
jg    octant_7
jne   octant_6
cmp   di, ax
jbe   octant_6
octant_7:
test  si, si
jl    octant_7_out_of_bounds
jne   octant_7_do_divide
cmp   di, 0200h
jae   octant_7_do_divide
octant_7_out_of_bounds:
mov   dx, 0a000h
xor   ax, ax
pop   di
pop   si
retf  
octant_7_do_divide:
mov   bx, di
mov   cx, si
call FastDiv3232_shift_3_8_
cmp   ax, 0800h
jae   octant_7_out_of_bounds
mov   si, word ptr [_tantoangle]
shl   ax, 2
mov   es, word ptr [_tantoangle+2]
add   si, ax
mov   ax, word ptr es:[si]
add   ax, 0
mov   dx, word ptr es:[si + 2]
adc   dx, 08000h
pop   di
pop   si
retf  
octant_6:
test  dx, dx
jl    octant_6_out_of_bounds
jne   octant_6_do_divide
cmp   ax, 0200h
jae   octant_6_do_divide
octant_6_out_of_bounds:
mov   ax, 0ffffh
mov   dx, 09fffh
pop   di
pop   si
retf  
octant_6_do_divide:
mov   bx, ax
mov   cx, dx
mov   ax, di
mov   dx, si
call FastDiv3232_shift_3_8_
cmp   ax, 0800h
jae   octant_6_out_of_bounds
mov   si, word ptr [_tantoangle]
shl   ax, 2
mov   es, word ptr [_tantoangle+2]
add   si, ax
mov   ax, 0ffffh
sub   ax, word ptr es:[si]
mov   dx, 0bfffh
sbb   dx, word ptr es:[si + 2]
pop   di
pop   si
retf  
endp

END

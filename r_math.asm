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


FINESINE_SEGMENT               = 31e4h

EXTRN _tantoangle:DWORD
EXTRN _viewx:DWORD
EXTRN _viewy:DWORD
EXTRN _viewangle_shiftright3:WORD
EXTRN _projection:WORD
EXTRN _rw_distance:WORD
EXTRN _rw_normalangle:WORD

EXTRN FastDiv3232_shift_3_8_:PROC
EXTRN FixedMulTrig_:PROC
;EXTRN FixedDiv_:PROC

INCLUDE defs.inc

.CODE


octant_6:
test  cx, cx

jne   octant_6_do_divide
cmp   bx, 0200h
jae   octant_6_do_divide
octant_6_out_of_bounds:
mov   dx, 0e000h
xor   ax, ax

retf  
octant_6_do_divide:
call FastDiv3232_shift_3_8_
cmp   ax, 0800h
jae   octant_6_out_of_bounds
mov   bx, word ptr [_tantoangle]
shl   ax, 2
mov   es, word ptr [_tantoangle+2]
add   bx, ax
mov   ax, word ptr es:[bx]
mov   dx, word ptr es:[bx + 2]
add   dx, 0c000h

retf  

y_is_negative:
;			y.w = -y.w;

neg   cx
neg   bx
sbb   cx, 0

cmp   dx, cx
jg    octant_7
jne   octant_6
cmp   ax, bx
jbe   octant_6
octant_7:
test  dx, dx
jne   octant_7_do_divide
cmp   ax, 0200h
jae   octant_7_do_divide
octant_7_out_of_bounds:
mov   dx, 0e000h
xor   ax, ax

retf  
; result 16f01520
; 7ffd1a dx:ax
; 3077f6 cx:bx
; 5400000 -> 0x2A000000
; d400000  > 0xD4000    32B 811

;mov dx, cx
;mov ax, bx


octant_7_do_divide:

; swap params. y over x not x over y
xchg dx, cx
xchg ax, bx

call FastDiv3232_shift_3_8_

; 16f0  1520 instead of 32b

cmp   ax, 0800h
jae   octant_7_out_of_bounds
mov   bx, word ptr [_tantoangle]
shl   ax, 2
mov   es, word ptr [_tantoangle+2]
add   bx, ax
mov   ax, word ptr es:[bx]
mov   dx, word ptr es:[bx + 2]
neg   dx
neg   ax
sbb   dx, 0

retf  

;R_PointToAngle_

PROC R_PointToAngle_
PUBLIC R_PointToAngle_

; inputs:
; DX:AX = x  (32 bit fixed pt 16:16)
; CX:BX = y  (32 bit fixed pt 16:16)

; places to improve -
; 1.default branches taken. count branches taken and modify to optimize

;	x.w -= viewx.w;
;	y.w -= viewy.w;



sub   ax, word ptr [_viewx]
sbb   dx, word ptr [_viewx+2]

sub   bx, word ptr [_viewy]
sbb   cx, word ptr [_viewy+2]

; 	if ((!x.w) && (!y.w))
;		return 0;

test  dx, dx
jne   inputs_not_zero   ; todo rearrange this. rare case
test  cx, cx
jne   inputs_not_zero   ; todo rearrange this. rare case
test  ax, ax
jne   inputs_not_zero   ; todo rearrange this. rare case
test  bx, bx
jne   inputs_not_zero   ; todo rearrange this. rare case
return_0:

xor   ax, ax
cwd

retf  


inputs_not_zero:

test  dx, dx
jl   x_is_negative

x_is_positive:
test  cx, cx

jl   y_is_negative
y_is_positive:

cmp   dx, cx
jg    octant_0

jne   octant_1
cmp   ax, bx
jbe   octant_1


octant_0:
test  dx, dx

;	if (x.w < 512)

jne   octant_0_do_divide
cmp   ax, 0200h
jae   octant_0_do_divide
octant_0_out_of_bounds:
mov   dx, 02000h
xor   ax, ax

retf  


octant_0_do_divide:
;x_is_negative
xchg dx, cx
xchg ax, bx
call FastDiv3232_shift_3_8_
cmp   ax, 0800h
jae   octant_0_out_of_bounds

mov   bx, word ptr [_tantoangle]
shl   ax, 2
mov   es, word ptr [_tantoangle+2]
add   bx, ax
mov   ax, word ptr es:[bx]
mov   dx, word ptr es:[bx + 2]

retf  


octant_1:
test  cx, cx

jne   octant_1_do_divide
cmp   bx, 0200h
jae   octant_1_do_divide
octant_1_out_of_bounds:
mov   ax, 0ffffh
mov   dx, 01fffh

retf  
octant_1_do_divide:
call FastDiv3232_shift_3_8_
cmp   ax, 0800h
jae   octant_1_out_of_bounds
mov   bx, word ptr [_tantoangle]
shl   ax, 2
mov   es, word ptr [_tantoangle+2]
add   bx, ax
mov   ax, 0ffffh
sub   ax, word ptr es:[bx]
mov   dx, 03fffh
sbb   dx, word ptr es:[bx + 2]

retf  



x_is_negative:

;		x.w = -x.w;

neg   dx
neg   ax
sbb   dx, 0

test  cx, cx

jg    y_is_positive_x_neg
jne   y_is_negative_x_neg
y_is_positive_x_neg:
cmp   dx, cx
jg    octant_3
jne   octant_2
cmp   ax, bx
jbe   octant_2

octant_3:
test  dx, dx
jne   octant_3_do_divide
cmp   ax, 0200h
jae   octant_3_do_divide
octant_3_out_of_bounds:
mov   ax, 0ffffh
mov   dx, 05fffh

retf  
octant_3_do_divide:
xchg dx, cx
xchg ax, bx
call FastDiv3232_shift_3_8_
cmp   ax, 0800h
jae   octant_3_out_of_bounds
mov   bx, word ptr [_tantoangle]
shl   ax, 2
mov   es, word ptr [_tantoangle+2]
add   bx, ax
mov   ax, 0ffffh
sub   ax, word ptr es:[bx]
mov   dx, 07fffh
sbb   dx, word ptr es:[bx + 2]

retf  
octant_2:
test  cx, cx

jne   octant_2_do_divide
cmp   ax, 0200h
jae   octant_2_do_divide
octant_2_out_of_bounds:
mov   dx, 06000h
xor   ax, ax
retf  
octant_2_do_divide:

call FastDiv3232_shift_3_8_
cmp   ax, 0800h
jae   octant_2_out_of_bounds
mov   bx, word ptr [_tantoangle]
shl   ax, 2
mov   es, word ptr [_tantoangle+2]
add   bx, ax
mov   ax, word ptr es:[bx]
mov   dx, word ptr es:[bx + 2]
add   dx, 04000h

retf  
y_is_negative_x_neg:

;			y.w = -y.w;

neg   cx
neg   bx
sbb   cx, 0
cmp   dx, cx
jg    octant_4
jne   octant_5
cmp   ax, bx
jbe   octant_5
octant_4:
test  dx, dx
jne   octant_4_do_divide
cmp   ax, 0200h
jae   octant_4_do_divide
octant_4_out_of_bounds:
mov   dx, 0a000h
xor   ax, ax

retf  
octant_4_do_divide:
xchg dx, cx
xchg ax, bx
call FastDiv3232_shift_3_8_
cmp   ax, 0800h
jae   octant_4_out_of_bounds

mov   bx, word ptr [_tantoangle]
shl   ax, 2
mov   es, word ptr [_tantoangle+2]
add   bx, ax
mov   ax, word ptr es:[bx]
mov   dx, word ptr es:[bx + 2]
add   dx, 08000h

retf  
octant_5:
test  cx, cx

jne   octant_5_do_divide
cmp   ax, 0200h
jae   octant_5_do_divide
octant_5_out_of_bounds:
mov   ax, 0ffffh
mov   dx, 09fffh

retf  
octant_5_do_divide:

call FastDiv3232_shift_3_8_
cmp   ax, 0800h
jae   octant_5_out_of_bounds
mov   bx, word ptr [_tantoangle]
shl   ax, 2
mov   es, word ptr [_tantoangle+2]
add   bx, ax
mov   ax, 0ffffh
sub   ax, word ptr es:[bx]
mov   dx, 0bfffh
sbb   dx, word ptr es:[bx + 2]

retf  
endp



;R_ScaleFromGlobalAngle_

PROC R_ScaleFromGlobalAngle3_
PUBLIC R_ScaleFromGlobalAngle3_


push  bx
push  cx
push  si
push  di
push  bp
mov   bp, sp
sub   sp, 2
mov   dx, ax
sub   dx, word ptr [_viewangle_shiftright3]
add   dh, 8
mov   bx, word ptr [_projection]
and   dh, 01Fh
add   ah, 8
mov   word ptr [bp - 2], dx
mov   dx, ax
mov   cx, word ptr [_projection+2]
sub   dx, word ptr [_rw_normalangle]
mov   ax, FINESINE_SEGMENT
and   dh, 01Fh
call FixedMulTrig_
mov   si, ax
mov   al, byte ptr [_detailshift]
mov   bx, word ptr [_rw_distance]
cbw
mov   di, dx
mov   cx, ax
mov   dx, word ptr [bp - 2]
jcxz  label_1
label_loop:
shl   si, 1
rcl   di, 1
loop  label_loop
label_1:
mov   ax, FINESINE_SEGMENT
mov   cx, word ptr [_rw_distance+2]
call FixedMulTrig_
mov   bx, ax
mov   ax, di
mov   cx, dx
cwd   
cmp   cx, dx
jg    do_divide
jne   return_maxvalue
cmp   bx, ax
ja    do_divide
return_maxvalue:
mov   dx, 040h
xor   ax, ax
normal_return:
mov   sp, bp
pop   bp
pop   di
pop   si
pop   cx
pop   bx
ret
do_divide:
mov   ax, si
mov   dx, di

call FixedDivR_

cmp   dx, 040h
jg    return_maxvalue
test  dx, dx
jl    return_minvalue
jne   normal_return
cmp   ax, 0100h
jae   normal_return
return_minvalue:
mov   ax, 0100h
xor   dx, dx
mov   sp, bp
pop   bp
pop   di
pop   si
pop   cx
pop   bx
ret

endp







shift_word:
mov si, dx
mov dx, ax
xor ax, ax
mov cx, bx
xor bx, bx

jmp shift_bits

;   
; basically, shift numerator left 16 and divide
; DX:AX:00 / CX:BX

PROC div48_32R_
PUBLIC div48_32R_


; di:si get shifted cx:bx

push  si
push  bp
mov   bp, sp


XOR SI, SI ; zero this out to get high bits of numhi


test cx, cx
je  shift_word
; default branch taken 314358 vs 126885


test ch, ch
jne shift_bits
; shift a whole byte immediately

mov ch, cl
mov cl, bh
mov bh, bl
xor bl, bl


xchg dh, dl
mov  si, dx
and si, 00FFh  ; todo make this better

mov dl, ah
mov ah, al
xor al, al

shift_bits:



; less than a byte to shift
; shift until MSB is 1

SAL BX, 1
RCL CX, 1
JC done_shifting  
SAL AX, 1
RCL DX, 1
RCL SI, 1

SAL BX, 1
RCL CX, 1
JC done_shifting  
SAL AX, 1
RCL DX, 1
RCL SI, 1

SAL BX, 1
RCL CX, 1
JC done_shifting  
SAL AX, 1
RCL DX, 1
RCL SI, 1

SAL BX, 1
RCL CX, 1
JC done_shifting  
SAL AX, 1
RCL DX, 1
RCL SI, 1

SAL BX, 1
RCL CX, 1
JC done_shifting  
SAL AX, 1
RCL DX, 1
RCL SI, 1

SAL BX, 1
RCL CX, 1
JC done_shifting  
SAL AX, 1
RCL DX, 1
RCL SI, 1

SAL BX, 1
RCL CX, 1
JC done_shifting  
SAL AX, 1
RCL DX, 1
RCL SI, 1

SAL BX, 1
RCL CX, 1






; store this
done_shifting:

; we overshifted by one and caught it in the carry bit. lets shift back right one.

RCR CX, 1
RCR BX, 1


; SI:DX:AX holds divisor...
; CX:BX holds dividend...
; numhi = SI:DX
; numlo = AX:00...


; save numlo word in sp.
; avoid going to memory... lets do interrupt magic
cli
mov sp, ax


; set up first div. 
; dx:ax becomes numhi
mov   ax, dx
mov   dx, si    

; store these two long term...
mov   di, cx
mov   si, bx

mov   ds, ax                    ; store copy of numhi.low?



;	divresult.wu = DIV3216RESULTREMAINDER(numhi.wu, den1);
; DX:AX = numhi.wu


div   di

; rhat = dx
; qhat = ax
;    c1 = FastMul16u16u(qhat , den0);

mov   bx, dx					; bx stores rhat
mov   es, ax     ; store qhat

mul   si   						; DX:AX = c1

;  c2 = rhat:num1



;    if (c1 > c2.wu)
;         qhat -= (c1 - c2.wu > den.wu) ? 2 : 1;
; 


; c1 hi = dx, c2 lo = bx
cmp   dx, bx



ja    check_c1_c2_diff
jne   q1_ready
cmp   ax, sp
jbe   q1_ready
check_c1_c2_diff:

; (c1 - c2.wu > den.wu)

sub   ax, sp
sbb   dx, bx
cmp   dx, di
ja    qhat_subtract_2
je    compare_low_word
jmp   qhat_subtract_1

compare_low_word:
cmp   ax, si
jbe   qhat_subtract_1

; ugly but rare occurrence i think?
qhat_subtract_2:
mov ax, es
dec ax
mov es, ax
qhat_subtract_1:
mov ax, es
dec ax
mov es, ax



;    q1 = (uint16_t)qhat;

q1_ready:

mov  ax, es
;	rem.hu.intbits = numhi.hu.fracbits;
;	rem.hu.fracbits = num1;
;	rem.wu -= FastMul16u32u(q1, den.wu);


mov   cx, ax

; multiplying by DI:SI basically. inline SI in as BX.

;inlined FastMul16u32u_

MUL  DI        ; AX * CX
XCHG CX, AX    ; store low product to be high result. Retrieve orig AX
MUL  SI        ; AX * BX
ADD  DX, CX    ; add 

; actual 2nd division...


sub   sp, ax
mov   cx, ds
sbb   cx, dx
mov   dx, cx
mov   ax, sp

cmp   dx, di

; check for adjustment

;    if (rem.hu.intbits < den1){

jnb    adjust_for_overflow


; 441240 branch not taken vs 3 taken

;  bff9bffa cx:bx


div   di





mov   bx, ax
mov   cx, dx

mul   si
cmp   dx, cx



ja    continue_c1_c2_test
je    continue_check



do_return_2:


; HEREHERE


mov   dx, es      ; retrieve q1
mov   ax, bx

mov   cx, ss      ; restore ds
mov   ds, cx      
mov   sp, bp
sti
pop   bp
pop   si
ret  

continue_check:
cmp   ax, 0
jbe   do_return_2
continue_c1_c2_test:
sbb   dx, cx
cmp   dx, di
ja    do_qhat_subtraction_by_2
jne   do_qhat_subtraction_by_1
cmp   si, ax

jae   do_qhat_subtraction_by_1
do_qhat_subtraction_by_2:
dec   bx
do_qhat_subtraction_by_1:
dec   bx

jmp do_return_2;




adjust_for_overflow:
xor   dx, dx
sub   ax, di
sbb   cx, dx

cmp   cx, di

; check for overflow param

jae   adjust_for_overflow_again

mov   dx, cx



div   di
mov   bx, ax
mov   cx, dx

mul   si
cmp   dx, cx
ja    continue_c1_c2_test_2
jne   dont_decrement_qhat_and_return
cmp   ax, 0
jbe   dont_decrement_qhat_and_return
continue_c1_c2_test_2:

sub   dx, cx
cmp   dx, di
ja    decrement_qhat_and_return
jne   dont_decrement_qhat_and_return
cmp   si, ax
jae   dont_decrement_qhat_and_return
decrement_qhat_and_return:
dec   bx
dont_decrement_qhat_and_return:
mov   ax, bx
mov   dx, es   ;retrieve q1
mov   cx, ss
mov   ds, cx
mov   sp, bp
sti
pop   bp
pop   si
ret  

; the divide would have overflowed. subtract values
adjust_for_overflow_again:

sub   ax, di
sbb   cx, dx
mov   dx, cx
div   di


; ax has its result...

mov   dx, es
mov   cx, ss
mov   ds, cx
mov   sp, bp
sti
pop   bp
pop   si
ret 





endp









PROC FixedDivR_
PUBLIC FixedDivR_


;fixed_t32 FixedDivinner(fixed_t32	a, fixed_t32 b int8_t* file, int32_t line)
; fixed_t32 FixedDiv(fixed_t32	a, fixed_t32	b) {
; 	if ((labs(a) >> 14) >= labs(b))
; 		return (a^b) < 0 ? MINLONG : MAXLONG;
; 	return FixedDiv2(a, b);
; }

;    abs(x) = (x XOR y) - y
;      where y = x's sign bit extended.


; DX:AX   /   CX:BX
 
push  si
push  di
push  bp
mov   bp, sp


mov   si, dx ; 	si will store sign bit 
xor   si, cx  ; si now stores signedness via test operator...



; here we abs the numbers before unsigned division algo

or    cx, cx
jge   b_is_positive
neg   bx
adc   cx, 0
neg   cx


b_is_positive:

or    dx, dx			; sign check
jge   a_is_positive
neg   ax
adc   dx, 0
neg   dx


a_is_positive:

;  dx:ax  is  labs(dx:ax) now (unshifted)
;  cx:bx  is  labs(cx:bx) now
test cx, 0FFFCh


je continue_bounds_test

; main division algo

do_full_divide:

; DX:AX 682d40
; CX:BX 





call div48_32R_

mov   sp, bp
pop   bp

pop   di
pop   si
ret

; set negative if need be...

test  si, si

jl do_negative

mov   sp, bp
pop   bp

pop   di
pop   si
ret

do_negative:

neg   ax
adc   dx, 0
neg   dx

mov   sp, bp
pop   bp

pop   di
pop   si
ret

continue_bounds_test:




; if high 2 bits of dh arent present at all, and any bits of cx are present
; then we can quit out quickly.


test dh, 0C0h     ; dx AND 0xC000
jne do_shift_and_full_compare
test cx, cx
jne do_full_divide  ; dx >> 14 is zero, cx is nonzero.


do_shift_and_full_compare:

; store backup dx:ax in ds:es
mov ds, dx
mov es, ax

rol dx, 1
rol ax, 1
rol dx, 1
rol ax, 1

mov di, dx
and ax, 03h
and di, 0FFFCh  ; cx, 0FFFCh
or  ax, di
and dx, 03h


; do comparison  di:bx vs dx:ax
; 	if ((labs(a) >> 14) >= labs(b))

cmp   dx, cx
jg    do_quick_return
jne   restore_reg_then_do_full_divide ; below
cmp   ax, bx
jb    restore_reg_then_do_full_divide

do_quick_return: 
; return (a^b) < 0 ? MINLONG : MAXLONG;
test  si, si   ; just need to do the high word due to sign?
jl    return_MAXLONG

return_MINLONG:
mov   ax, ss
mov   ds, ax

mov   ax, 0ffffh
mov   dx, 07fffh

exit_and_return_early:

; restore ds...

mov   sp, bp

pop   bp
pop   di
pop   si
ret

return_MAXLONG:
mov   ax, ss
mov   ds, ax

mov   dx, 08000h
xor   ax, ax
jmp   exit_and_return_early

restore_reg_then_do_full_divide:

; restore dx
mov dx, ds

; restore ds
mov ax, ss
mov ds, ax 

; restore ax
mov ax, es
jmp do_full_divide

ENDP






END

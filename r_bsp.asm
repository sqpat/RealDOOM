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
INCLUDE defs.inc
INSTRUCTION_SET_MACRO

; todo move these all out once BSP code moved out of binary




.CODE


ANG90_HIGHBITS =		04000h
ANG180_HIGHBITS =    08000h


MID_ONLY_DRAW_TYPE = 1
BOT_TOP_DRAW_TYPE = 2


;R_ScaleFromGlobalAngle_

PROC R_ScaleFromGlobalAngle_ NEAR
PUBLIC R_ScaleFromGlobalAngle_ 


push  bx
push  cx
push  si
push  di

; input ax = visangle_shift3

;    anglea = MOD_FINE_ANGLE(FINE_ANG90 + (visangle_shift3 - viewangle_shiftright3));
;    angleb = MOD_FINE_ANGLE(FINE_ANG90 + (visangle_shift3) - rw_normalangle);

add   ah, 8      
mov   dx, ax      ; copy input
SELFMODIFY_set_viewanglesr3_5:
sub   dx, 01000h  ; 
SELFMODIFY_sub_rw_normal_angle_1:
sub   ax, 01000h

and   dh, 01Fh
and   ah, 01Fh

mov   di, ax

; dx = anglea
; di = angleb

mov   ax, FINESINE_SEGMENT
mov   si, ax
SELFMODIFY_get_rw_distance_lo_1:
mov   bx, 01000h
SELFMODIFY_get_rw_distance_hi_1:
mov   cx, 01000h

; todo is rw_distance = 0 a common case...?

;    den = FixedMulTrig(FINE_SINE_ARGUMENT, anglea, rw_distance);
 
call FixedMulTrig_BSPLocal_


;    num.w = FixedMulTrig(FINE_SINE_ARGUMENT, angleb, projection.w)<<detailshift.b.bytelow;
 
;call FixedMulTrig16_
; inlined  16 bit times sine value

mov es, si
SHIFT_MACRO sal di 2
les si, dword ptr es:[di]
mov di, es
xchg dx, di
xchg ax, si

;  dx now has anglea
;  ax has finesine_segment
;  di:si is den

SELFMODIFY_BSP_centerx_1:
mov   cx, 01000h


AND  DX, CX    ; DX*CX
NEG  DX
MOV  BX, DX    ; store high result

MUL  CX       ; AX*CX
ADD  DX, BX   


; di:si had den
; dx:ax has num

SELFMODIFY_BSP_detailshift2minus_1:


; fall thru do twice
shl   ax, 1
rcl   dx, 1
do_once:
shl   ax, 1
rcl   dx, 1
shift_done:


; di:si had den
; dx:ax has num



;    if (den > num.h.intbits) {

; annoying - we have to account for sign!
; is there a cleaner way?

 
xchg   cx, ax  ; temp storage
mov    ax, dx
cwd            ; sign extend

cmp   di, dx
mov   dx, ax
mov   bx, si 

jg    do_divide  ; compare sign bits..




jne   return_maxvalue   ; less than case - result is greater than 0x1,0000,0000

; todo we can bitshift and catch more cases here...


; shift to account for 0x400000 compare

; so this does work but it triggers once every [many] frames, so wasting 8 ticks to save a hundred or two
; isn't worth it when the hit rate is < 1%
;mov ah, al
;xor al, al
;sal ah, 1
;sal ah, 1

cmp   si, ax    
ja    do_divide


return_maxvalue:
; rare occurence
mov   dx, 040h
xor   ax, ax
jmp normal_return

do_divide:

; set up params
mov   ax, cx  ; mov back..
mov   cx, di 

; we actually already bounds check more aggressively than fixeddiv
;  and guarantee positives here so the fixeddiv wrapper is unnecessary

; NOTE: a high word bounds triggered early return on the first divide result 
;   is super rare due to the outer checks...
;   doesnt occur even every frame. lets avoid the "optimized" dupe function.


call div48_32_BSPLocal_

cmp   dx, 040h
jg    return_maxvalue
test  dx, dx
; dont need to check for negative result, this was unsigned.
je   continue_check 

normal_return:

pop   di
pop   si
pop   cx
pop   bx
ret

continue_check:
cmp   ax, 0100h
jnae   return_minvalue

; also normal return
pop   di
pop   si
pop   cx
pop   bx
ret

return_minvalue:
; super duper rare case. actually never caught it happening.
mov   ax, 0100h
xor   dx, dx

pop   di
pop   si
pop   cx
pop   bx
ret

endp



octant_6:
test  cx, cx

jne   octant_6_do_divide
cmp   bx, 0200h
jae   octant_6_do_divide
octant_6_out_of_bounds:
mov   dx, 0e000h
xor   ax, ax

ret  
octant_6_do_divide:
call FastDiv3232_shift_3_8_
cmp   ax, 0800h
jae   octant_6_out_of_bounds

mov   es, word ptr ds:[_tantoangle_segment]
SHIFT_MACRO shl ax 2
mov   bx, ax
les   ax, dword ptr es:[bx]
mov   dx, es
add   dx, 0c000h

ret  

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

ret  
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
mov   es, word ptr ds:[_tantoangle_segment]
SHIFT_MACRO shl ax 2
mov   bx, ax
les   ax, dword ptr es:[bx]
mov   dx, es
neg   dx
neg   ax
sbb   dx, 0

ret  

;R_PointToAngle_

PROC R_PointToAngle_ NEAR
PUBLIC R_PointToAngle_

; inputs:
; DX:AX = x  (32 bit fixed pt 16:16)
; CX:BX = y  (32 bit fixed pt 16:16)

; places to improve -
; 1.default branches taken. count branches taken and modify to optimize

;	x.w -= viewx.w;
;	y.w -= viewy.w;

; idea: self modify code, change this to constants per frame.



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

ret  


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

ret  


octant_0_do_divide:
;x_is_negative
xchg dx, cx
xchg ax, bx
call FastDiv3232_shift_3_8_
cmp   ax, 0800h
jae   octant_0_out_of_bounds

mov   es, word ptr ds:[_tantoangle_segment]
SHIFT_MACRO shl ax 2
mov   bx, ax
les   ax, dword ptr es:[bx]
mov   dx, es
ret  


octant_1:
test  cx, cx

jne   octant_1_do_divide
cmp   bx, 0200h
jae   octant_1_do_divide
octant_1_out_of_bounds:
mov   ax, 0ffffh
mov   dx, 01fffh

ret  
octant_1_do_divide:
call FastDiv3232_shift_3_8_
cmp   ax, 0800h
jae   octant_1_out_of_bounds
mov   es, word ptr ds:[_tantoangle_segment]
SHIFT_MACRO shl ax 2
mov   bx, ax
mov   ax, 0ffffh
sub   ax, word ptr es:[bx]
mov   dx, 03fffh
sbb   dx, word ptr es:[bx + 2]

ret  



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

ret  
octant_3_do_divide:
xchg dx, cx
xchg ax, bx
call FastDiv3232_shift_3_8_
cmp   ax, 0800h
jae   octant_3_out_of_bounds
mov   es, word ptr ds:[_tantoangle_segment]
SHIFT_MACRO shl ax 2
mov   bx, ax
mov   ax, 0ffffh
sub   ax, word ptr es:[bx]
mov   dx, 07fffh
sbb   dx, word ptr es:[bx + 2]

ret  
octant_2:
test  cx, cx

jne   octant_2_do_divide
cmp   ax, 0200h
jae   octant_2_do_divide
octant_2_out_of_bounds:
mov   dx, 06000h
xor   ax, ax
ret  
octant_2_do_divide:

call FastDiv3232_shift_3_8_
cmp   ax, 0800h
jae   octant_2_out_of_bounds
mov   es, word ptr ds:[_tantoangle_segment]
SHIFT_MACRO shl ax 2
mov   bx, ax
les   ax, dword ptr es:[bx]
mov   dx, es
add   dx, 04000h

ret  
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

ret  
octant_4_do_divide:
xchg dx, cx
xchg ax, bx
call FastDiv3232_shift_3_8_
cmp   ax, 0800h
jae   octant_4_out_of_bounds

mov   es, word ptr ds:[_tantoangle_segment]
SHIFT_MACRO shl ax 2
mov   bx, ax
les   ax, dword ptr es:[bx]
mov   dx, es
add   dx, 08000h

ret  
octant_5:
test  cx, cx

jne   octant_5_do_divide
cmp   ax, 0200h
jae   octant_5_do_divide
octant_5_out_of_bounds:
mov   ax, 0ffffh
mov   dx, 09fffh

ret  
octant_5_do_divide:

call FastDiv3232_shift_3_8_
cmp   ax, 0800h
jae   octant_5_out_of_bounds
mov   es, word ptr ds:[_tantoangle_segment]
SHIFT_MACRO shl ax 2
mov   bx, ax
mov   ax, 0ffffh
sub   ax, word ptr es:[bx]
mov   dx, 0bfffh
sbb   dx, word ptr es:[bx + 2]

ret  
ENDP


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

PROC div48_32_BSPLocal_
PUBLIC div48_32_BSPLocal_


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


div   di

mov   bx, ax
mov   cx, dx

mul   si
cmp   dx, cx

ja    continue_c1_c2_test
je    continue_check2

; default 440124 vs branch 105492 times
do_return_2:
mov   dx, es      ; retrieve q1
mov   ax, bx

mov   cx, ss      ; restore ds
mov   ds, cx      
LEAVE_MACRO
sti
pop   si
ret  

continue_check2:
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
LEAVE_MACRO
sti
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
LEAVE_MACRO
sti
pop   si
ret 





ENDP




PROC FixedDivWholeA_BSPLocal_ NEAR
PUBLIC FixedDivWholeA_BSPLocal_


; AX:00 / CX:BX
; return in DX:AX

; this is fixeddiv so we must do the whole labs14 check and word shift adjustment


mov   dx, ax  ; dx will store sign bit 
xor   dx, cx  ; dx now stores signedness via test operator...



; here we abs the numbers before unsigned division algo

or    cx, cx
jge   b_is_positive_whole
neg   bx
adc   cx, 0
neg   cx


b_is_positive_whole:

or    ax, ax			; sign check
jge   a_is_positive_whole
neg   ax

a_is_positive_whole:

;  ax:00  is  labs(ax:00) now (unshifted)
;  cx:bx  is  labs(cx:bx) now
mov   es, dx   ; store sign bit for now
xor   dx, dx
sal   ax, 1
rcl   dx, 1
sal   ax, 1
rcl   dx, 1
cmp   dx ,cx   ; compare high bit
jg    do_quick_return_whole                 ; greater
jne   restore_reg_then_do_full_divide_whole ; smaller
cmp   ax ,bx
jb    restore_reg_then_do_full_divide_whole
do_quick_return_whole: 
; return (a^b) < 0 ? MINLONG : MAXLONG;


mov   dx, es   ; restore sign bit

test  dx, dx   ; just need to do the high word due to sign?
jl    return_MAXLONG_whole

return_MINLONG_whole:

mov   ax, 0ffffh
mov   dx, 07fffh


ret

restore_reg_then_do_full_divide_whole:


sar   dx, 1
rcr   ax, 1
sar   dx, 1
rcr   ax, 1   ; restore ax
mov   dx, es  ; restore sign bit

; main division algo

do_full_divide_whole:


; set negative if need be...

test  dx, dx
jl do_negative_whole



call div48_32_whole_BSPLocal_



ret

do_negative_whole:



call div48_32_whole_BSPLocal_



neg   ax
adc   dx, 0
neg   dx


ret

return_MAXLONG_whole:

mov   dx, 08000h
xor   ax, ax
ret



endp



shift_word_whole:
mov dx, ax
xor ax, ax
mov cx, bx
xor bx, bx

jmp shift_bits_whole

;div48_32_whole_
; basically, shift numerator left 16 and divide
; AX:00:00 / CX:BX

PROC div48_32_whole_BSPLocal_
PUBLIC div48_32_whole_BSPLocal_

; di:si get shifted cx:bx



xor dx, dx


push  si
push  di
push  bp
mov   bp, sp




test cx, cx
je  shift_word_whole
; default branch taken 314358 vs 126885


test ch, ch
jne shift_bits_whole
; shift a whole byte immediately

mov ch, cl
mov cl, bh
mov bh, bl
xor bl, bl


mov  dh, dl
mov dl, ah
mov ah, al
xor al, al

shift_bits_whole:



; less than a byte to shift
; shift until MSB is 1

SAL BX, 1
RCL CX, 1
JC done_shifting_whole
SAL AX, 1
RCL DX, 1

SAL BX, 1
RCL CX, 1
JC done_shifting_whole  
SAL AX, 1
RCL DX, 1

SAL BX, 1
RCL CX, 1
JC done_shifting_whole  
SAL AX, 1
RCL DX, 1

SAL BX, 1
RCL CX, 1
JC done_shifting_whole  
SAL AX, 1
RCL DX, 1

SAL BX, 1
RCL CX, 1
JC done_shifting_whole  
SAL AX, 1
RCL DX, 1

SAL BX, 1
RCL CX, 1
JC done_shifting_whole  
SAL AX, 1
RCL DX, 1

SAL BX, 1
RCL CX, 1
JC done_shifting_whole  
SAL AX, 1
RCL DX, 1

SAL BX, 1
RCL CX, 1






; store this
done_shifting_whole:

; we overshifted by one and caught it in the carry bit. lets shift back right one.

RCR CX, 1
RCR BX, 1





; DX:AX holds divisor...
; CX:BX holds dividend...
; numhi = DX:AX
; numlo = 00:00...





; store these two long term...
; todo i think cx can be filtered out...
mov   di, cx
mov   si, bx

mov   ds, ax                    ; store copy of numhi.low




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



ja    check_c1_c2_diff_whole
jne   q1_ready_whole
cmp   ax, 0
jbe   q1_ready_whole
check_c1_c2_diff_whole:

; (c1 - c2.wu > den.wu)

sub   dx, bx
cmp   dx, di
ja    qhat_subtract_2_whole
je    compare_low_word_whole
jmp   qhat_subtract_1_whole

compare_low_word_whole:
cmp   ax, si
jbe   qhat_subtract_1_whole

; ugly but rare occurrence i think?
qhat_subtract_2_whole:
mov ax, es
dec ax
mov es, ax
qhat_subtract_1_whole:
mov ax, es
dec ax
mov es, ax



;    q1 = (uint16_t)qhat;

q1_ready_whole:

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


neg   ax
mov   cx, ds
sbb   cx, dx
mov   dx, cx

cmp   dx, di

; check for adjustment

;    if (rem.hu.intbits < den1){

jnb    adjust_for_overflow_whole




div   di

mov   bx, ax
mov   cx, dx

mul   si
cmp   dx, cx

ja    continue_c1_c2_test_whole
je    continue_check_whole

do_return_2_whole:
mov   dx, es      ; retrieve q1
mov   ax, bx

mov   cx, ss      ; restore ds
mov   ds, cx      
LEAVE_MACRO
pop   di
pop   si
ret  

continue_check_whole:
cmp   ax, 0
jbe   do_return_2_whole
continue_c1_c2_test_whole:
sbb   dx, cx
cmp   dx, di
ja    do_qhat_subtraction_by_2_whole
jne   do_qhat_subtraction_by_1_whole
cmp   si, ax

jae   do_qhat_subtraction_by_1_whole
do_qhat_subtraction_by_2_whole:
dec   bx
do_qhat_subtraction_by_1_whole:
dec   bx

jmp do_return_2_whole




adjust_for_overflow_whole:
xor   dx, dx
sub   ax, di
sbb   cx, dx

cmp   cx, di

; check for overflow param

jae   adjust_for_overflow_again_whole

mov   dx, cx



div   di
mov   bx, ax
mov   cx, dx

mul   si
cmp   dx, cx
ja    continue_c1_c2_test_2_whole
jne   dont_decrement_qhat_and_return_whole
cmp   ax, 0
jbe   dont_decrement_qhat_and_return_whole
continue_c1_c2_test_2_whole:

sub   dx, cx
cmp   dx, di
ja    decrement_qhat_and_return_whole
jne   dont_decrement_qhat_and_return_whole
cmp   si, ax
jae   dont_decrement_qhat_and_return_whole
decrement_qhat_and_return_whole:
dec   bx
dont_decrement_qhat_and_return_whole:
mov   ax, bx
mov   dx, es   ;retrieve q1
mov   cx, ss
mov   ds, cx
LEAVE_MACRO
pop   di
pop   si
ret  

; the divide would have overflowed. subtract values
adjust_for_overflow_again_whole:

sub   ax, di
sbb   cx, dx
mov   dx, cx
div   di

; ax has its result...

mov   dx, es
mov   cx, ss
mov   ds, cx
LEAVE_MACRO
pop   di
pop   si
ret 





ENDP



IF COMPISA GE COMPILE_386

    PROC FixedMulTrig_BSPLocal_
    PUBLIC FixedMulTrig_BSPLocal_
    sal dx, 1
    sal dx, 1   ; DWORD lookup index
    ENDP

    PROC FixedMulTrigNoShift_BSPLocal_
    PUBLIC FixedMulTrigNoShift_BSPLocal_
    ; pass in the index already shifted to be a dword lookup..


    ; lookup the fine angle

    mov es, ax
    db  066h, 081h, 0E2h, 0FFh, 0FFh, 0, 0  ;  and edx, 0x0000FFFF   

    db  026h, 067h, 066h, 08bh, 002h     ; mov  eax, dword ptr es:[edx]


    db  066h, 0C1h, 0E3h, 010h           ; shl  ebx, 0x10
    db  066h, 00Fh, 0ACh, 0CBh, 010h     ; shrd ebx, ecx, 0x10
    db  066h, 0F7h, 0EBh                 ; imul ebx
    db  066h, 0C1h, 0E8h, 010h           ; shr  eax, 0x10


    ret

    ENDP


ELSE

    PROC FixedMulTrig_BSPLocal_
    PUBLIC FixedMulTrig_BSPLocal_

    

    sal dx, 1
    sal dx, 1   ; DWORD lookup index
    ENDP

    PROC FixedMulTrigNoShift_BSPLocal_
    PUBLIC FixedMulTrigNoShift_BSPLocal_
    ; pass in the index already shifted to be a dword lookup..

    push  si

    ; lookup the fine angle


    mov si, dx
    mov ds, ax  ; put segment in ES
    lodsw
    mov es, ax
    lodsw

    mov   DX, AX    ; store sign bits in DX
    AND   AX, BX	; S0*BX
    NEG   AX
    mov   SI, AX	; SI stores hi word return

    mov   AX, DX    ; restore sign bits from DX

    AND  AX, CX    ; DX*CX
    NEG  AX
    add  SI, AX    ; low word result into high word return

    ; DX already has sign bits..

    ; NEED TO ALSO EXTEND SIGN MULTIPLY TO HIGH WORD. if sign is FFFF then result is BX - 1. Otherwise 0.
    ; UNLESS BX is 0. then its also 0!

    ; the algorithm for high sign bit mult:   IF FFFF result is (BX - 1). If 0000 then 0.
    MOV  AX, BX    ; create BX copy
    SUB  AX, 1     ; DEC DOES NOT AFFECT CARRY FLAG! BOO! 3 byte instruction, can we improve?
    ADC  AX, 0     ; if bx is 0 then restore to 0 after the dex  

    AND  AX, DX    ; 0 or BX - 1
    ADD  SI, AX    ; add DX * BX high word. 


    AND  DX, BX    ; DX * BX low bits
    NEG  DX
    XCHG BX, DX    ; BX will hold low word return. store BX in DX for last mul 

    mov  AX, ES    ; grab AX from ES
    mul  DX        ; BX*AX  
    add  BX, DX    ; high word result into low word return
    ADC  SI, 0

    mov  AX, CX   ; AX holds CX

    CWD           ; S1 in DX

    mov  CX, ES   ; AX from ES
    AND  DX, CX   ; S1*AX
    NEG  DX
    ADD  SI, DX   ; result into high word return

    MUL  CX       ; AX*CX

    ADD  AX, BX	  ; set up final return value
    ADC  DX, SI
    
    MOV CX, SS
    MOV DS, CX    ; put DS back from SS

    pop   si
    ret



    ENDP
ENDIF



fast_div_32_16:

mov bl, bh
mov bh, cl

sal ax, 1
rcl dx ,1
sal ax, 1
rcl dx ,1
sal ax, 1
rcl dx ,1


div bx        ; after this dx stores remainder, ax stores q1

ret          ; dx will be garbage, but who cares , return 16 bits.

return_2048:


mov ax, 0800h
ret


PROC FastDiv3232_shift_3_8_ NEAR
PUBLIC FastDiv3232_shift_3_8_

; used by R_PointToAngle.
; DX:AX << 3 / CX:BX >> 8
; signed, but comes in positive. so high bit is never on
; if result is > 2048, a branch is taken and result is not used, 
; so this is designed around quickly detecting results greater than that



test ch, ch
je fast_div_32_16


; we have not shifted yet...


;TODO: checks are done outside this function, may be okay to remove this. test?
; we want to know if  (DX:AX << 3)  / (CX:BX >> 8)  >= 2048 for a quick out
; but that is just "is dx:ax greater than cx:bx"


cmp dx, cx
ja  return_2048
jb full_32_32
cmp ax, bx
jae return_2048


full_32_32:




call FastDiv3232_RPTA_

ret

endp


; todo optimize around fact ch is always 0...
; we are moving a byte back and forth

fast_div_32_16_RPTA:

mov bl, bh
mov bh, cl
mov cl, ch
xor ch, ch
sal ax, 1
rcl dx ,1
sal ax, 1
rcl dx ,1
sal ax, 1
rcl dx ,1


xchg dx, cx   ; cx was 0, dx is FFFF
div bx        ; after this dx stores remainder, ax stores q1
xchg cx, ax   ; q1 to cx, ffff to ax  so div remaidner:ffff 
div bx
mov dx, cx   ; q1:q0 is dx:ax
ret 


; NOTE: this is used for R_PointToAngle and has a fast out when the high byte is detected to be above the threshhold

;FastDiv3232_RPTA_
; DX:AX / CX:BX

PROC FastDiv3232_RPTA_
PUBLIC FastDiv3232_RPTA_

; we shift dx:ax by 11 into si... 




; if top 16 bits missing just do a 32 / 16

test ch, ch
je fast_div_32_16_RPTA

main_3232RPTA_div:

push  si
push  di

; shift left 11 in si:dx:ax


;si: 
;00000111 11111111
;dx:
;11111222 22222222
;ax:
;22222000 00000000

mov si, dx
mov dx, ax
xor ax, ax

; creating si:dx:ax

shr si, 1
rcr dx, 1
rcr ax, 1
shr si, 1
rcr dx, 1
rcr ax, 1
shr si, 1
rcr dx, 1
rcr ax, 1
shr si, 1
rcr dx, 1
rcr ax, 1
shr si, 1
rcr dx, 1
rcr ax, 1





; now lets shift CX:BX to max...




test ch, ch
jne shift_bits_3232RPTA
; shift a whole byte immediately

mov ch, cl
mov cl, bh
mov bh, bl
xor bl, bl


xchg ax, si
mov  ah, al
mov  al, dh
mov  dh, dl
xchg ax, si
mov  dl, ah
xor  al, al


shift_bits_3232RPTA:

; less than a byte to shift
; shift until MSB is 1

SAL BX, 1
RCL CX, 1
JC done_shifting_3232RPTA  
SAL AX, 1
RCL DX, 1
RCL SI, 1

SAL BX, 1
RCL CX, 1
JC done_shifting_3232RPTA
SAL AX, 1
RCL DX, 1
RCL SI, 1

SAL BX, 1
RCL CX, 1
JC done_shifting_3232RPTA
SAL AX, 1
RCL DX, 1
RCL SI, 1

SAL BX, 1
RCL CX, 1
JC done_shifting_3232RPTA
SAL AX, 1
RCL DX, 1
RCL SI, 1

SAL BX, 1
RCL CX, 1
JC done_shifting_3232RPTA
SAL AX, 1
RCL DX, 1
RCL SI, 1

SAL BX, 1
RCL CX, 1
JC done_shifting_3232RPTA
SAL AX, 1
RCL DX, 1
RCL SI, 1

SAL BX, 1
RCL CX, 1
JC done_shifting_3232RPTA
SAL AX, 1
RCL DX, 1
RCL SI, 1

SAL BX, 1
RCL CX, 1



; store this
done_shifting_3232RPTA:

; we overshifted by one and caught it in the carry bit. lets shift back right one.

RCR CX, 1
RCR BX, 1


; SI:DX:AX holds divisor...
; CX:BX holds dividend...
; numhi = SI:DX
; numlo = AX:00...


; save numlo word in sp.
; avoid going to memory... lets do interrupt magic
mov di, ax


; set up first div. 
; dx:ax becomes numhi
mov   ax, dx
mov   dx, si    

; store these two long term...
mov   si, bx



; numhi is 00:SI in this case?

;	divresult.wu = DIV3216RESULTREMAINDER(numhi.wu, den1);
; DX:AX = numhi.wu


div   cx

; qhat is at most 2 greater than the real answer.
; we are capping results at 2048 or 0x800 so quick return in that case.

cmp  ax, 0802h
ja   return_2048_2


; rhat = dx
; qhat = ax
;    c1 = FastMul16u16u(qhat , den0);

mov   bx, dx					; bx stores rhat
mov   es, ax     ; store qhat




mul   si   						; DX:AX = c1


; c1 hi = dx, c2 lo = bx
cmp   dx, bx

ja    check_c1_c2_diff_3232RPTA
jne   q1_ready_3232RPTA
cmp   ax, di
jbe   q1_ready_3232RPTA
check_c1_c2_diff_3232RPTA:

; (c1 - c2.wu > den.wu)

sub   ax, di
sbb   dx, bx
cmp   dx, cx
ja    qhat_subtract_2_3232RPTA
je    compare_low_word_3232RPTA
jmp   qhat_subtract_1_3232RPTA

compare_low_word_3232RPTA:
cmp   ax, si
jbe   qhat_subtract_1_3232RPTA

; ugly but rare occurrence i think?
qhat_subtract_2_3232RPTA:
mov ax, es
dec ax
dec ax

pop   di
pop   si
ret  

return_2048_2:
; bigger than 2048.. just return it
pop   di
pop   si
ret


qhat_subtract_1_3232RPTA:
mov ax, es
dec ax

pop   di
pop   si
ret  




q1_ready_3232RPTA:

mov  ax, es

pop   di
pop   si
ret  


ENDP




IF COMPISA GE COMPILE_386

PROC FixedMulBSPLocal_ NEAR
PUBLIC FixedMulBSPLocal_

; DX:AX  *  CX:BX
;  0  1      2  3

; set up ecx
db 066h, 0C1h, 0E3h, 010h        ; shl  ebx, 0x10
db 066h, 00Fh, 0A4h, 0D9h, 010h  ; shld ecx, ebx, 0x10

; set up eax
db 066h, 0C1h, 0E0h, 010h        ; shl  eax, 0x10
db 066h, 00Fh, 0ACh, 0D0h, 010h  ; shrd eax, edx, 0x10

; actual mul
db 066h, 0F7h, 0E9h              ; imul ecx
; set up return
db 066h, 0C1h, 0E8h, 010h        ; shr  eax, 0x10
db 0C3h                          ; ret



ENDP
ELSE


PROC FixedMulBSPLocal_ NEAR
PUBLIC FixedMulBSPLocal_

; DX:AX  *  CX:BX
;  0  1      2  3

; with sign extend for byte 3:
; S0:DX:AX    *   S1:CX:BX
; S0 = DX sign extend
; S1 = CX sign extend

;
; 
;BYTE
; RETURN VALUE
;                3       2       1		0
;                DONTUSE USE     USE    DONTUSE


;                               AXBXhi	 AXBXlo
;                       DXBXhi  DXBXlo          
;               S0BXhi  S0BXlo                          
;
;                       AXCXhi  AXCXlo
;               DXCXhi  DXCXlo  
;                       
;               AXS1hi  AXS1lo
;                               
;                       
;       




; need to get the sign-extends for DX and CX

push  si

mov   es, ax	; store ax in es
mov   ds, dx    ; store dx in ds
mov   ax, dx	; ax holds dx
CWD				; S0 in DX

AND   DX, BX	; S0*BX
NEG   DX
mov   SI, DX	; DI stores hi word return

; AX still stores DX
MUL  CX         ; DX*CX
add  SI, AX    ; low word result into high word return

mov  AX, DS    ; restore DX from ds
MUL  BX         ; DX*BX
XCHG BX, AX    ; BX will hold low word return. store bx in ax
add  SI, DX    ; add high word to result

mov  DX, ES    ; restore AX from ES
mul  DX        ; BX*AX  
add  BX, DX    ; high word result into low word return
ADC  SI, 0

mov  AX, CX   ; AX holds CX
CWD           ; S1 in DX

mov  CX, ES   ; AX from ES
AND  DX, CX   ; S1*AX
NEG  DX
ADD  SI, DX   ; result into high word return

MUL  CX       ; AX*CX

ADD  AX, BX	  ; set up final return value
ADC  DX, SI

mov  CX, SS   ; restore DS
mov  DS, CX

pop   si
ret



ENDP
ENDIF


PROC FixedDivBSPLocal_
PUBLIC FixedDivBSPLocal_


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


mov   si, dx ; 	si will store sign bit 
xor   si, cx  ; si now stores signedness via test operator...



; here we abs the numbers before unsigned division algo

or    cx, cx
jge   b_is_positive
neg   cx
neg   bx
sbb   cx, 0


b_is_positive:

or    dx, dx			; sign check
jge   a_is_positive
neg   dx
neg   ax
sbb   dx, 0


a_is_positive:

;  dx:ax  is  labs(dx:ax) now (unshifted)
;  cx:bx  is  labs(cx:bx) now



; labs check

do_shift_and_full_compare:

; store backup dx:ax in ds:es

SHIFT_MACRO rol dx 2

mov di, dx
and di, 03h


; do comparison  di:bx vs dx:ax
; 	if ((labs(a) >> 14) >= labs(b))

cmp   di, cx
jg    do_quick_return
jne   restore_reg_then_do_full_divide ; below
mov   di, dx      ; recover this
mov   es, ax      ; back this up
SHIFT_MACRO rol ax 2
and   ax, 03h
and   di, 0FFFCh  ; cx, 0FFFCh
or    ax, di
cmp   ax, bx
jb    restore_reg_then_do_full_divide_2

do_quick_return: 
; return (a^b) < 0 ? MINLONG : MAXLONG;
test  si, si   ; just need to do the high word due to sign?
jl    return_MAXLONG

return_MINLONG:

mov   ax, 0ffffh
mov   dx, 07fffh

exit_and_return_early:

; restore ds...


pop   di
pop   si
ret

return_MAXLONG:

mov   dx, 08000h
xor   ax, ax
jmp   exit_and_return_early

; main division algo









restore_reg_then_do_full_divide_2:


; restore ax
mov ax, es
restore_reg_then_do_full_divide:

; restore dx
SHIFT_MACRO ror dx 2


do_full_divide:

call div48_32_BSPLocal_

; set negative if need be...

test  si, si

jl do_negative


pop   di
pop   si
ret

do_negative:

neg   dx
neg   ax
sbb   dx, 0


pop   di
pop   si
ret

ENDP

PROC FixedMulTrigNoShiftBSPLocal_
PUBLIC FixedMulTrigNoShiftBSPLocal_
; pass in the index already shifted to be a dword lookup..

push  si

; lookup the fine angle

mov si, dx
mov ds, ax  ; put segment in ES
lodsw
mov es, ax
lodsw

mov   DX, AX    ; store sign bits in DX
AND   AX, BX	; S0*BX
NEG   AX
mov   SI, AX	; SI stores hi word return

mov   AX, DX    ; restore sign bits from DX

AND  AX, CX    ; DX*CX
NEG  AX
add  SI, AX    ; low word result into high word return

; DX already has sign bits..

; NEED TO ALSO EXTEND SIGN MULTIPLY TO HIGH WORD. if sign is FFFF then result is BX - 1. Otherwise 0.
; UNLESS BX is 0. then its also 0!

; the algorithm for high sign bit mult:   IF FFFF result is (BX - 1). If 0000 then 0.
MOV  AX, BX    ; create BX copy
SUB  AX, 1     ; DEC DOES NOT AFFECT CARRY FLAG! BOO! 3 byte instruction, can we improve?
ADC  AX, 0     ; if bx is 0 then restore to 0 after the dex  

AND  AX, DX    ; 0 or BX - 1
ADD  SI, AX    ; add DX * BX high word. 


AND  DX, BX    ; DX * BX low bits
NEG  DX
XCHG BX, DX    ; BX will hold low word return. store BX in DX for last mul 

mov  AX, ES    ; grab AX from ES
mul  DX        ; BX*AX  
add  BX, DX    ; high word result into low word return
ADC  SI, 0

mov  AX, CX   ; AX holds CX

CWD           ; S1 in DX

mov  CX, ES   ; AX from ES
AND  DX, CX   ; S1*AX
NEG  DX
ADD  SI, DX   ; result into high word return

MUL  CX       ; AX*CX

ADD  AX, BX	  ; set up final return value
ADC  DX, SI
 
MOV CX, SS
MOV DS, CX    ; put DS back from SS

pop   si
ret



ENDP




;R_PointToDist_

PROC R_PointToDist_ NEAR
PUBLIC R_PointToDist_ 


;push  bx      ; these arent used after the call. no need to push/pop..
;push  cx
push  si
push  di

;    dx = labs(x.w - viewx.w);
;  x = ax register
;  y = dx

xor   bx, bx
mov   cx, ax
xor   ax, ax
; DX:AX = y
; CX:BX = x
SELFMODIFY_BSP_viewx_lo_2:
sub   bx, 01000h
SELFMODIFY_BSP_viewx_hi_2:
sbb   cx, 01000h

SELFMODIFY_BSP_viewy_lo_2:
sub   ax, 01000h
SELFMODIFY_BSP_viewy_hi_2:
sbb   dx, 01000h


or    cx, cx
jge   skip_x_abs
neg   bx
adc   cx, 0
neg   cx
skip_x_abs:

or    dx, dx
jge   skip_y_abs
neg   ax
adc   dx, 0
neg   dx
skip_y_abs:




;    if (dy>dx) {

cmp   dx, cx
jg    swap_x_y
jne   skip_swap_x_y
cmp   ax, bx
jbe   skip_swap_x_y

swap_x_y:
xchg  dx, cx
xchg  ax, bx
skip_swap_x_y:

;	angle = (tantoangle[ FixedDiv(dy,dx)>>DBITS ].hu.intbits+ANG90_HIGHBITS) >> SHORTTOFINESHIFT;

; save dx (var not register)

mov   si, bx
mov   di, cx



; dx:ax ffa0fd1a


call  FixedDivBSPLocal_

; shift 5. since we do a tantoangle lookup... this maxes at 2048
sar   dx, 1
rcr   ax, 1
sar   dx, 1
rcr   ax, 1
sar   dx, 1
rcr   ax, 1
and   al, 0FCh
mov   dx, di ; move di to dx early to free up di for les + di + bx combo


mov   bx, ax
mov   es, word ptr ds:[_tantoangle_segment] 
mov   bx, word ptr es:[bx + 2] ; get just intbits..

;    dist = FixedDiv (dx, finesine[angle] );	

add   bh, 040h ; ang90 highbits
mov   ax, FINESINE_SEGMENT
shr   bx, 1
and   bl, 0FCh
mov   es, ax
mov   ax, si
les   bx, dword ptr es:[bx]
mov   cx, es
call  FixedDivBSPLocal_

pop   di
pop   si
;pop   cx
;pop   bx
ret   

ENDP


PROC R_ClearClipSegs_ NEAR
PUBLIC R_ClearClipSegs_
; todo lea

mov  word ptr ds:[_solidsegs+0], 08001h
mov  word ptr ds:[_solidsegs+2], 0FFFFh
; todo push pop
mov  ax, word ptr ds:[_viewwidth]
mov  word ptr ds:[_solidsegs+4], ax
mov  word ptr ds:[_solidsegs+6], 07FFFh
mov  word ptr ds:[_newend], OFFSET _solidsegs + 2 * SIZEOF_CLIPRANGE_T
ret  



ENDP


;R_ClearPlanes

PROC R_ClearPlanes_ NEAR
PUBLIC R_ClearPlanes_ 


push  bx
push  cx
push  dx
push  di


SELFMODIFY_BSP_viewwidth_1:
mov   cx, 01000h
mov   dx, cx

xor   di, di
SELFMODIFY_BSP_setviewheight_2:
mov   ax, 01000h
mov bx, FLOORCLIP_PARAGRAPH_ALIGNED_SEGMENT; 
mov es, bx

rep stosw  ; write vieweight to es:di

mov ax, 0FFFFh
mov di, 0280h  ; offset of ceilingclip within floorclip
mov cx, dx
rep stosw  ; write vieweight to es:di

inc ax   ; zeroed
mov   word ptr ds:[_lastvisplane], ax
mov   word ptr ds:[_lastopening], ax
SELFMODIFY_set_viewanglesr3_4:
mov   ax, 01000h
sub   ah, 08h   ; FINE_ANG90
and   ah, 01Fh    ; MOD_FINE_ANGLE

SHIFT_MACRO shl ax 2
 
SELFMODIFY_BSP_centerx_2:
mov   cx, 01000h
mov   di, ax

mov   ax, FINECOSINE_SEGMENT

mov   es, ax


les   ax, dword ptr es:[di]
mov   dx, es
xor   bx, bx

call FixedDivBSPLocal_  ; TODO! FixedDivWholeB? Optimize?
mov   word ptr ds:[_basexscale], ax
mov   word ptr ds:[_basexscale + 2], dx
mov   ax, FINESINE_SEGMENT

mov   es, ax
SELFMODIFY_BSP_centerx_3:
mov   cx, 01000h
les   ax, dword ptr es:[di]
mov   dx, es
xor   bx, bx
call FixedDivBSPLocal_  ; TODO! FixedDivWholeB? Optimize?
neg   dx
neg   ax
sbb   dx, 0
mov   word ptr ds:[_baseyscale], ax
mov   word ptr ds:[_baseyscale + 2], dx


pop   di
pop   dx
pop   cx
pop   bx
ret   

endp





;R_HandleEMSVisplanePagination

PROC R_HandleEMSVisplanePagination_ NEAR
PUBLIC R_HandleEMSVisplanePagination_ 

; input: 
; al is index, dl is isceil

; in func:
; ah stores 0  (copied to and from dx/bx)
; al stores various things
; dl stores usedvirtualpage
; dh stores 0 (copied to and from ax/bx)
; bl stores usedphyspage
; bh stores 0 (bx indexed a lot, copied to/from ax/dx )
; cl stores isceil
; ch stores usedsubindex

push  bx
;push  cx

mov   cl, dl        ; copy is_ceil to cl
mov   ch, al
xor   dx, dx
cmp   al, VISPLANES_PER_EMS_PAGE
jae   loop_cycle_visplane_ems_page
visplane_ems_page_ready:
cmp   byte ptr ds:[_visplanedirty], 0
je    visplane_not_dirty
visplane_dirty_or_index_over_max_conventional_visplanes:
mov   bx, dx


mov   al, byte ptr ds:[bx + _active_visplanes]
test  al, al
xchg  ax, dx
je    do_quickmap_ems_visplaes
; found active visplane page 
mov   bl, dl
dec   bl
return_visplane:

test  cl, cl    ; check isceil
je    is_floor_2

mov   byte ptr ds:[_ceilphyspage], bl
sal   bx, 1
mov   dx, word ptr ds:[bx + _visplanelookupsegments] ; return value for ax

mov   bl, ch
sal   bx, 1

mov   ax, word ptr ds:[bx + _visplane_offset]
add   ax, 2

mov   word ptr ds:[_ceiltop], ax
sub   ax, 2
mov   word ptr ds:[_ceiltop+2], dx


;pop   cx
pop   bx
ret   
is_floor_2:
mov   byte ptr ds:[_floorphyspage], bl   
sal   bx, 1
mov   dx, word ptr ds:[bx + _visplanelookupsegments] ; return value for ax

mov   bl, ch
sal   bx, 1

mov   ax, word ptr ds:[bx + _visplane_offset]
add   ax, 2

mov   word ptr ds:[_floortop], ax
sub   ax, 2
mov   word ptr ds:[_floortop+2], dx

;pop   cx
pop   bx
ret
loop_cycle_visplane_ems_page:  ; move this above func
sub   ch, VISPLANES_PER_EMS_PAGE
inc   dl
cmp   ch, VISPLANES_PER_EMS_PAGE
jae   loop_cycle_visplane_ems_page
jmp   visplane_ems_page_ready
visplane_not_dirty:
cmp   al, MAX_CONVENTIONAL_VISPLANES  
jge   visplane_dirty_or_index_over_max_conventional_visplanes
mov   bx, dx
jmp   return_visplane
do_quickmap_ems_visplaes:
test  cl, cl    ; check isceil
je    is_floor
; is ceil
cmp   byte ptr ds:[_floorphyspage], 2  
jne   use_phys_page_2
use_phys_page_1:
mov   bl, 1

mov   dl, bl


call  Z_QuickMapVisplanePage_BSPLocal_
jmp   return_visplane
use_phys_page_2:
mov   bl, 2
mov   dl, bl


call  Z_QuickMapVisplanePage_BSPLocal_
jmp   return_visplane
is_floor:
cmp   byte ptr ds:[_ceilphyspage], 2
je    use_phys_page_1
mov   bl, 2
mov   dl, bl

call  Z_QuickMapVisplanePage_BSPLocal_
jmp   return_visplane



ENDP

PROC Z_QuickMapVisplanePage_BSPLocal_ NEAR
PUBLIC Z_QuickMapVisplanePage_BSPLocal_



;	int16_t usedpageindex = pagenum9000 + PAGE_8400_OFFSET + physicalpage;
;	int16_t usedpagevalue;
;	int8_t i;
;	if (virtualpage < 2){
;		usedpagevalue = FIRST_VISPLANE_PAGE + virtualpage;
;	} else {
;		usedpagevalue = EMS_VISPLANE_EXTRA_PAGE + (virtualpage-2);
;	}

push  bx
push  cx
push  si
mov   cl, al
mov   dh, dl
mov   al, dl
cbw  
IFDEF COMP_CH
mov   si, CHIPSET_PAGE_9000
ELSE
mov   si, word ptr ds:[_pagenum9000]
ENDIF
add   si, PAGE_8400_OFFSET ; sub 3
add   si, ax
mov   al, cl
cbw  
cmp   al, 2
jge   visplane_page_above_2
add   ax, FIRST_VISPLANE_PAGE
used_pagevalue_ready:

;		pageswapargs[pageswapargs_visplanepage_offset] = _EPR(usedpagevalue);

; _EPR here
IFDEF COMP_CH
    add  ax, EMS_MEMORY_PAGE_OFFSET
ELSE
ENDIF
mov   word ptr ds:[_pageswapargs + (pageswapargs_visplanepage_offset * PAGE_SWAP_ARG_MULT)], ax


;pageswapargs[pageswapargs_visplanepage_offset+1] = usedpageindex;
IFDEF COMP_CH
ELSE
    mov   word ptr ds:[_pageswapargs + ((pageswapargs_visplanepage_offset+1) * PAGE_SWAP_ARG_MULT)], si
ENDIF

;	physicalpage++;
inc   dh
mov   dl, 4

;	for (i = 4; i > 0; i --){
;		if (active_visplanes[i] == physicalpage){
;			active_visplanes[i] = 0;
;			break;
;		}
;	}

loop_next_visplane_page:
mov   al, dl
cbw  
mov   bx, ax
cmp   dh, byte ptr ds:[bx + _active_visplanes]
je    set_zero_and_break
dec   dl
test  dl, dl
jg    loop_next_visplane_page

done_with_visplane_loop:
mov   al, cl
cbw  
mov   bx, ax

mov   byte ptr ds:[bx + _active_visplanes], dh


IFDEF COMP_CH
	IF COMP_CH EQ CHIPSET_SCAT

        mov  	dx, SCAT_PAGE_SELECT_REGISTER
        xchg    ax, si
        ; not necessary?
        ;or      al, EMS_AUTOINCREMENT_FLAG  
        out  	dx, al
        mov     si,  pageswapargs_visplanepage_offset_size * 2 * PAGE_SWAP_ARG_MULT + _pageswapargs
        mov  	dx, SCAT_PAGE_SET_REGISTER
        lodsw
        out 	dx, ax

	ELSEIF COMP_CH EQ CHIPSET_SCAMP

        xchg    ax, si
        ; not necessary?
        ;or      al, EMS_AUTOINCREMENT_FLAG  
        out     SCAMP_PAGE_SELECT_REGISTER, al
        mov     si,  &pageswapindex * 2 * PAGE_SWAP_ARG_MULT + _pageswapargs
        lodsw
        out 	SCAMP_PAGE_SET_REGISTER, ax


	ELSEIF COMP_CH EQ CHIPSET_HT18

        mov  	dx, HT18_PAGE_SELECT_REGISTER
        xchg    ax, si
        ; not necessary?
        ;or      al, EMS_AUTOINCREMENT_FLAG  
        out  	dx, al
        mov     si,  pageswapargs_visplanepage_offset_size * 2 * PAGE_SWAP_ARG_MULT + _pageswapargs
        mov  	dx, HT18_PAGE_SET_REGISTER
        lodsw
        out 	dx, ax

    ENDIF

ELSE


    Z_QUICKMAPAI1 pageswapargs_visplanepage_offset_size unused_param



ENDIF


mov   byte ptr ds:[_visplanedirty], 1
pop   si
pop   cx
pop   bx
ret  
visplane_page_above_2:
;		usedpagevalue = EMS_VISPLANE_EXTRA_PAGE + (virtualpage-2);
add   ax, (EMS_VISPLANE_EXTRA_PAGE - 2)
jmp   used_pagevalue_ready

set_zero_and_break:
mov   byte ptr ds:[bx + _active_visplanes], 0
jmp   done_with_visplane_loop

ENDP

PROC Z_QuickMapVisplaneRevert_BSPLocal_ NEAR
PUBLIC Z_QuickMapVisplaneRevert_BSPLocal_

push  dx
mov   dx, 1
mov   ax, dx
call  Z_QuickMapVisplanePage_BSPLocal_
mov   dx, 2
mov   ax, dx
call  Z_QuickMapVisplanePage_BSPLocal_
mov   byte ptr ds:[_visplanedirty], 0
pop   dx
ret  

ENDP


;R_FindPlane_

PROC R_FindPlane_ NEAR
PUBLIC R_FindPlane_ 



; dx:ax is height
; cx is picandlight
; bl is icceil

;push      si
;push      di

cmp       cl, byte ptr ds:[_skyflatnum]
jne       not_skyflat

;		height = 0;			// all skys map together
;		lightlevel = 0;

xor       ax, ax
cwd
xor       ch, ch
not_skyflat:


; loop vars

; al = i
; ah = lastvisplane
; dx is height high precision
; di is height low precision
; bx is .. checkheader
; cx is pic_and_light
; si is visplanepiclights[i] (used for visplanelights lookups)


; set up find visplane loop
mov       di, ax  
push      bx  ; push isceil

; init loop vars
xor       ax, ax
mov       si, _visplanepiclights    ; initial offset
mov       ah, byte ptr ds:[_lastvisplane]

cmp       ah, 0
jl        break_loop   ; else break

; do loop setup

mov       al, 0
mov       bx, _visplaneheaders   ; set bx to header 0


next_loop_iteration:

cmp       al, ah
jne       check_for_visplane_match

break_loop:
;         al is i, ah is lastvisplane
cmp       al, ah
jge       break_loop_visplane_not_found

; found visplane match. return it
cbw       ; clear lastvisplane out of ah
pop       dx  ; get isceil
mov       bx, ax        ; store i
call      R_HandleEMSVisplanePagination_
; fetch and return i
mov       ax, bx


;pop       di
;pop       si
ret       


;		if (height == checkheader->height
;			&& piclight.hu == visplanepiclights[i].pic_and_light) {
;				break;
;		}

check_for_visplane_match:
cmp       di, word ptr ds:[bx]     ; compare height low word
jne       loop_iter_step_variables
cmp       dx, word ptr ds:[bx + 2] ; compare height high word
jne       loop_iter_step_variables
cmp       cx, word ptr ds:[si] ; compare picandlight
je        break_loop

loop_iter_step_variables:
inc       al
add       si, 2
add       bx, 8

cmp       al, ah
jle       next_loop_iteration
sub       bx, 8  ; use last checkheader index
jmp       break_loop


break_loop_visplane_not_found:
; not found, create new visplane

cbw       ; no longer need lastvisplane, zero out ah


; set up new visplaneheader
mov       word ptr ds:[bx], di
mov       word ptr ds:[bx + 2], dx
mov       word ptr ds:[bx + 4], SCREENWIDTH
mov       word ptr ds:[bx + 6], 0FFFFh

;si already has  word lookup for piclights


mov       word ptr ds:[si], cx 

pop       dx  ; get isceil
inc       word ptr ds:[_lastvisplane]

mov       si, ax     ; store i      

call      R_HandleEMSVisplanePagination_

;; ff out pl top
mov       di, ax
mov       es, dx

mov       cx, (SCREENWIDTH / 2) + 1    ; one extra word for pad
mov       ax, 0FFFFh
rep stosw 


; zero out pl bot
; di is already set
;inc       ax   ; zeroed
;mov       cx, (SCREENWIDTH / 2) + 1  ; one extra word for pad
;rep stosw 


mov       ax, si


;pop       di
;pop       si
ret       

ENDP



;R_AddLine_

PROC R_AddLine_ NEAR
PUBLIC R_AddLine_ 

; ax = curlineNum

; bp - 2       curlineside
; bp - 4       curseglinedef
; bp - 6     curlinesidedef ?
; bp - 8       span   lo bits ?
; bp - 0Ah     _rw_scale hi
; bp - 0Ch    _rw_scale lo
; bp - 0Eh       angle1 lo bits ?

;todo reorder stack and do push
push  ax
push  cx
push  bp
mov   bp, sp

mov   si, ax
mov   dx, SEG_LINEDEFS_SEGMENT
mov   es, dx
mov   bx, ax
shl   bx, 1
mov   dl, byte ptr es:[si + SEG_SIDES_OFFSET_IN_SEGLINES]
mov   si, bx
SHIFT_MACRO shl bx 2
add   bh, (_segs_render SHR 8)
push  dx                    ; bp - 2
push  word ptr es:[si]      ; bp - 4
push  word ptr ds:[bx + 6]  ; bp - 6

les   si, dword ptr ds:[bx]       ;v1
mov   di, es                   ;v2
mov   word ptr cs:[SELFMODIFY_get_curseg_2 + 1], ax
sal   ax, 1
mov   word ptr cs:[SELFMODIFY_get_curseg_1 + 1], ax ; preshift
mov   ax, VERTEXES_SEGMENT
mov   es, ax
SHIFT_MACRO shl si 2
SHIFT_MACRO shl di 2
les   dx, dword ptr es:[si]
mov   cx, es
mov   es, ax
les   si, dword ptr es:[di]       ; v2.x
mov   di, es   ; v2.y
mov   word ptr cs:[SELFMODIFY_get_curseg_render_1 + 1], bx
add   bx, 4
mov   word ptr cs:[SELFMODIFY_get_curseg_render_2 + 2], bx ; todo can we store ahead the lookup instead of the ptr

call  R_PointToAngle16_    ; todo debug why this doesnt work with the other one. stack corruption?

xchg  ax, di
xchg  ax, cx
xchg  si, dx      ; SI: BX stores angle1


call  R_PointToAngle16_    ; todo debug why this doesnt work with the other one. stack corruption?

xchg  ax, di
mov   bx, ax
sub   ax, di
mov   cx, si
sbb   cx, dx
cmp   cx, ANG180_HIGHBITS
jb    dont_backface_cull
LEAVE_MACRO 
pop   cx
pop   ax
ret   
dont_backface_cull:
push  ax ; bp - 8

; store rw_angle1 on stack
push  si ; bp - 0Ah
push  bx ; bp - 0Ch

SELFMODIFY_BSP_viewangle_lo_1:
sub   bx, 01000h
push  bx  ; bp - 0Eh
mov   bx, si
SELFMODIFY_BSP_viewangle_hi_1:
sbb   bx, 01000h

SELFMODIFY_BSP_clipangle_4:
lea   ax, [bx + 01000h]
SELFMODIFY_BSP_viewangle_lo_2:
sub   di, 01000h
SELFMODIFY_BSP_viewangle_hi_2:
sbb   dx, 01000h
SELFMODIFY_BSP_fieldofview_1:
cmp   ax, 01000h
jbe   done_checking_left
SELFMODIFY_BSP_fieldofview_2:
sub   ax, 01000h
cmp   ax, cx
ja    exit_addline
jne   not_off_left_side
mov   ax, word ptr [bp - 0Eh]  ; todo carry from above
cmp   ax, word ptr [bp - 8]
jae   exit_addline
not_off_left_side:
SELFMODIFY_BSP_clipangle_1:
mov   bx, 01000h
done_checking_left:
xor   si, si
SELFMODIFY_BSP_clipangle_2:
mov   ax, 01000h
sub   si, di
sbb   ax, dx
mov   di, si
SELFMODIFY_BSP_fieldofview_3:
cmp   ax, 01000h
jbe   done_checking_right
SELFMODIFY_BSP_fieldofview_4:
sub   ax, 01000h
cmp   ax, cx
ja    exit_addline
jne   not_off_left_side_2
cmp   si, word ptr [bp - 8]
jae   exit_addline
not_off_left_side_2:
SELFMODIFY_BSP_clipangle_3:
mov   dx, 01000h
neg   dx
done_checking_right:

; seg in view angle but not necessarily visible
add   bh, (ANG90_HIGHBITS SHR 8)
mov   ax, VIEWANGLETOX_SEGMENT

SHIFT_MACRO shr bx 3



mov   es, ax
add   bx, bx
add   dh, (ANG90_HIGHBITS SHR 8)
mov   ax, word ptr es:[bx]
mov   bx, dx
SHIFT_MACRO shr bx 3


add   bx, bx
mov   dx, word ptr es:[bx]
cmp   ax, dx
je    exit_addline
;	if (!(lineflagslist[curseglinedef] & ML_TWOSIDED)) {
dec   dx       ; x2 -1 for calls later.

mov   bx, LINEFLAGSLIST_SEGMENT
mov   es, bx
mov   bx, word ptr [bp - 4]
test  byte ptr es:[bx], ML_TWOSIDED
jne   not_single_sided_line
mov   word ptr ds:[_backsector], SECNUM_NULL   ; does this ever get properly used or checked? can we just ignore?
clipsolid:
call  R_ClipSolidWallSegment_
exit_addline:
LEAVE_MACRO 
pop   cx
pop   ax
ret   
not_single_sided_line:
mov   bl, byte ptr [bp - 2]
xor   bl, 1
xor   bh, bh
add   bx, bx
mov   si, LINES_SEGMENT
mov   es, si
mov   si, word ptr [bp - 4]
SHIFT_MACRO  shl si 2
mov   bx, word ptr es:[bx + si]

SHIFT_MACRO shl bx 2


    ; secnum field in this side_render_t
mov   si, word ptr ds:[bx + _sides_render + 2]
SHIFT_MACRO shl si 4

mov   word ptr ds:[_backsector], si


les   di, dword ptr ds:[_frontsector]
;es:si backsector
;es:di frontsector.

; todo do in order with lodsw and compare ax?

;    // Closed door.
;	if (backsector->ceilingheight <= frontsector->floorheight
;		|| backsector->floorheight >= frontsector->ceilingheight) 



; weird. this kills performance on pentium by 3%.
xchg  ax, bx   ; store x1 in bx

lods  word ptr es:[si]        ; backsector  floor
cmp   ax, word ptr es:[di+2]  ; frontsector ceiling
jge   clipsolid_ax_swap
xchg  ax, cx                  ; cx has old si+0 (backsector floor)
lods  word ptr es:[si]        ; backsector  ceiling
cmp   ax, word ptr es:[di]    ; frontsector floor
jle   clipsolid_ax_swap

;    // Window.
;    if (backsector->ceilingheight != frontsector->ceilingheight
;	|| backsector->floorheight != frontsector->floorheight)

cmp   ax, word ptr es:[di + 2]      ; backsector ceiling vs frontsector ceiling
jne   clippass
cmp   cx, word ptr es:[di]          ; backsector floor vs frontsector floor
jne   clippass

; if (backsector->ceilingpic == frontsector->ceilingpic
;		&& backsector->floorpic == frontsector->floorpic
;		&& backsector->lightlevel == frontsector->lightlevel
;		&& curlinesidedef->midtexture == 0) {
;		return;
;    }

lods  word ptr es:[si]           ; al floorpic   ah ceilingpic
cmp   ax, word ptr es:[di + 4]
jne   clippass

mov   al, byte ptr es:[si + 08h] ; 0E is lightlevels. offset by 6..
cmp   al, byte ptr es:[di + 0Eh]
jne   clippass

;    fall thru and return if midtexture doesnt match.
mov   ax, SIDES_SEGMENT
mov   es, ax
mov   si, word ptr [bp - 6]    ; presumably curlinesidedef.
SHIFT_MACRO shl si 3
cmp   word ptr es:[si + 4], 0
je    exit_addline

clippass:
xchg  ax, bx                   ; grab cached x1
call  R_ClipPassWallSegment_
LEAVE_MACRO
pop   cx
pop   ax
ret   
clipsolid_ax_swap:
xchg  ax, bx                   ; grab cached x1
call  R_ClipSolidWallSegment_
LEAVE_MACRO 
pop   cx
pop   ax
ret   


ENDP


SUBSECTOR_OFFSET_IN_SECTORS       = (SUBSECTORS_SEGMENT - SECTORS_SEGMENT) * 16
;SUBSECTOR_LINES_OFFSET_IN_SECTORS = (SUBSECTOR_LINES_SEGMENT - SECTORS_SEGMENT) * 16

;R_Subsector_

PROC R_Subsector_ NEAR
PUBLIC R_Subsector_ 


;ax is subsecnum

push  cx
push  dx

push  si   ; used by inner function in a loop. push/pop once at outer layer.
push  di


mov   bx, ax
mov   ax, SUBSECTOR_LINES_SEGMENT
mov   es, ax
mov   al, byte ptr es:[bx]
xor   ah, ah
mov   word ptr cs:[SELFMODIFY_countvalue+1], ax    ; di stores count for later

mov   ax, SECTORS_SEGMENT
mov   es, ax

SHIFT_MACRO shl bx 2

mov   ax, word ptr es:[bx+SUBSECTOR_OFFSET_IN_SECTORS] ; get subsec secnum

SHIFT_MACRO shl ax 4



mov   word ptr ds:[_frontsector], ax
;mov   word ptr ds:[_frontsector+2], es   ; es holds sectors_segment..
mov   bx, word ptr es:[bx+SUBSECTOR_OFFSET_IN_SECTORS + 2]   ; get subsec firstline
xchg  bx, ax
mov   word ptr cs:[SELFMODIFY_firstlinevalue+1], ax    ; di stores count for later


cmp   byte ptr ds:[_visplanedirty], 0
jne   revert_visplane

prepare_fields:

;	ceilphyspage = 0;
;	floorphyspage = 0;
;	ceiltop = NULL;
;	floortop = NULL;

xor   ax, ax
; idea: put these variables all next to each other, then knock them out
; with movsw
mov   byte ptr ds:[_ceilphyspage], al
mov   byte ptr ds:[_floorphyspage], al

;  es:bx holds frontsector
mov   word ptr ds:[_ceiltop], ax

mov   word ptr ds:[_floortop], ax



mov   dx, word ptr es:[bx]
; ax is already 0

;	SET_FIXED_UNION_FROM_SHORT_HEIGHT

sar   dx, 1
rcr   ax, 1
sar   dx, 1
rcr   ax, 1
sar   dx, 1
rcr   ax, 1

SELFMODIFY_BSP_viewz_hi_6:
cmp   dx, 01000h
jl    find_floor_plane_index
je    check_viewz_lowbits_floor

set_floor_plane_minus_one:
mov   word ptr cs:[SELFMODIFY_set_floorplaneindex+1], 0FFFFh

jmp   floor_plane_set
revert_visplane:
call  Z_QuickMapVisplaneRevert_BSPLocal_
jmp   prepare_fields


set_ceiling_plane_minus_one:

; es:bx is still frontsector
mov   cl, byte ptr es:[bx + 5]
cmp   cl, byte ptr ds:[_skyflatnum]
je    find_ceiling_plane_index
mov   word ptr cs:[SELFMODIFY_set_ceilingplaneindex+1], 0FFFFh
jmp   do_addsprites

check_viewz_lowbits_floor:

SELFMODIFY_BSP_viewz_lo_6:
cmp   ax, 01000h
jae   set_floor_plane_minus_one    ; todo move to the other label
find_floor_plane_index:

; set up picandlight
mov   ch, byte ptr es:[bx + 0Eh]
mov   cl, byte ptr es:[bx + 4]
xor   bx, bx ; isceil = 0
call  R_FindPlane_
mov   word ptr cs:[SELFMODIFY_set_floorplaneindex+1], ax

floor_plane_set:
les   bx, dword ptr ds:[_frontsector]
mov   dx, word ptr es:[bx + 2]
xor   ax, ax
;	SET_FIXED_UNION_FROM_SHORT_HEIGHT

sar   dx, 1
rcr   ax, 1
sar   dx, 1
rcr   ax, 1
sar   dx, 1
rcr   ax, 1


SELFMODIFY_BSP_viewz_hi_5:
cmp   dx, 01000h
jg    find_ceiling_plane_index
jne   set_ceiling_plane_minus_one
SELFMODIFY_BSP_viewz_lo_5:
cmp   ax, 01000h
jbe   set_ceiling_plane_minus_one
find_ceiling_plane_index:
les   bx, dword ptr ds:[_frontsector]

; set up picandlight
mov   ch, byte ptr es:[bx + 0Eh]
mov   cl, byte ptr es:[bx + 5]
mov   bx, 1

call  R_FindPlane_
mov   word ptr cs:[SELFMODIFY_set_ceilingplaneindex+1], ax
do_addsprites:
mov   ax, word ptr ds:[_frontsector]
mov   dx, SECTORS_SEGMENT
; todo make this not a function argument if its always frontsector?
call  R_AddSprites_

SELFMODIFY_countvalue:
mov   cx, 0FFFFh
SELFMODIFY_firstlinevalue:
mov   ax, 0FFFFh

loop_addline:

; what if we inlined AddLine? or unrolled this?
; whats realistic maximum of numlines? a few hundred? might be 1800ish bytes... save about 10 cycles per call to addline maybe?


call  R_AddLine_
inc   ax

loop   loop_addline




pop   di
pop   si

pop   dx
pop   cx
ret   

ENDP

;R_CheckPlane_

PROC R_CheckPlane_ NEAR
PUBLIC R_CheckPlane_ 

; ax: index
; cl: isceil?



; di holds visplaneheaders lookup. maybe should be si

push      si
push      di

mov       word ptr cs:[SELFMODIFY_setindex+1], ax
mov       si, dx    ; si holds start



mov       di, ax





SHIFT_MACRO shl di 3




add       di, _visplaneheaders  ; _di is plheader
mov       byte ptr cs:[SELFMODIFY_setisceil + 1], cl  ; write cl value
test      cl, cl

mov       cx, bx    ; cx holds stop

je        check_plane_is_floor
;dec       cx
check_plane_is_ceil:
les       bx, dword ptr ds:[_ceiltop]
loaded_floor_or_ceiling:
; bx holds offset..

mov       ax, si  ; fetch start
cmp       ax, word ptr ds:[di + 4]    ; compare to minx
jge       start_greater_than_min
mov       word ptr cs:[SELFMODIFY_setminx+3], ax
mov       dx, word ptr ds:[di + 4]    ; fetch minx into intrl
checked_start:
; now checkmax
mov       ax, word ptr ds:[di + 6]   ; fetch maxx, ax = intrh = plheader->max
cmp       cx, ax                  ; compare stop to maxx
jle       stop_smaller_than_max
mov       word ptr cs:[SELFMODIFY_setmax+3], cx
done_checking_max:

; begin loop checks

; x = intrl to intrh
; so use intrl as x
; dx = intrl
; ax = intrh


cmp       dx, ax        ; x<= intrh 
jg        breakloop

add       bx, dx
loop_increment_x:

;	pltop[x]==0xff

cmp       byte ptr es:[bx], 0FFh
jne       breakloop
; x++
inc       dx            
inc       bx
cmp       dx, ax
jle       loop_increment_x

breakloop:


;    if (x > intrh) {

cmp       dx, ax
jle       make_new_visplane
SELFMODIFY_setminx:
mov       word ptr ds:[di + 4], 0FFFFh
SELFMODIFY_setmax:
mov       word ptr ds:[di + 6], 0FFFFh

SELFMODIFY_setindex:
mov       ax, 0ffffh


pop       di
pop       si
ret       


check_plane_is_floor:
;dec       cx
les       bx, dword ptr ds:[_floortop]
jmp       loaded_floor_or_ceiling
start_greater_than_min:
mov       ax, word ptr ds:[di + 4]

;mov       dx, si                ; put start into intrl (dx was already si)
mov       word ptr cs:[SELFMODIFY_setminx+3], ax
jmp       checked_start
stop_smaller_than_max:
mov       word ptr cs:[SELFMODIFY_setmax+3], ax     ; unionh = plheader->max
mov       ax, cx                                    ; intrh = stop
jmp       done_checking_max

make_new_visplane:
mov       bx, word ptr ds:[_lastvisplane] 
mov       es, bx    ; store in es
sal       bx, 1   ; bx is 2 per index

; dx/ax is plheader->height
; done with old plheader..
; es is in use..
mov       ax, word ptr ds:[di]
mov       dx, word ptr ds:[di + 2]

;	visplanepiclights[lastvisplane].pic_and_light = visplanepiclights[index].pic_and_light;

; generate index from di again. 
sub       di, _visplaneheaders
SHIFT_MACRO sar di 2
mov       di, word ptr ds:[di + _visplanepiclights]

mov       word ptr ds:[bx + _visplanepiclights], di
SHIFT_MACRO sal bx 2
; now bx is 8 per

; set all plheader fields for lastvisplane...
mov       word ptr ds:[bx + _visplaneheaders], ax
mov       word ptr ds:[bx + _visplaneheaders+2], dx
mov       word ptr ds:[bx + _visplaneheaders+4], si ; looks weird
mov       word ptr ds:[bx + _visplaneheaders+6], cx  ; looks weird




SELFMODIFY_setisceil:
mov       dx, 0000h     ; set isceil argument

mov       ax, es 
mov       si, ax 
cbw      

call      R_HandleEMSVisplanePagination_
mov       di, ax
mov       es, dx
mov       ax, 0FFFFh

mov       cx, (SCREENWIDTH / 2) + 1   ; plus one for the padding
rep stosw 


mov       ax, si
inc       word ptr ds:[_lastvisplane]


pop       di
pop       si
ret       

ENDP

MINZ_HIGHBITS = 4
;R_ProjectSprite_

PROC R_ProjectSprite_ NEAR
PUBLIC R_ProjectSprite_ 

; es:si is sprite.
; es is a constant..



; bp - 2:	 	thingframe (byte, with SIZEOF_SPRITEFRAME_T high)
; bp - 4:    	
; bp - 6:    	
; bp - 8:    	tr_y hi
; bp - 0Ah:    tr_y low
; bp - 0Ch:    tr_x hi
; bp - 0Eh:    tr_x lo
; bp - 010h:	thingz hi
; bp - 012h:	thingz lo
; bp - 014h:	thingy hi
; bp - 016h:   thingy lo
; bp - 018h:	thingx hi
; bp - 01Ah:	thingx lo
; bp - 01Ch:	xscale hi
; bp - 01Eh:	xscale lo
; bp - 020h:   spriteindex. used for spriteframes and spritetopindex?


push  si
push  es
push  bp
mov   bp, sp
mov   dx, es					   ; back this up...
mov   bx, word ptr es:[si + 012h]  ; thing->stateNum
mov   ax, STATES_RENDER_SEGMENT
mov   es, ax
add   bx, bx

; todo clean all this up. do we need local copy?
; otherwise use ds and rep movsw
mov   al, byte ptr es:[bx]		   ; states_render[thing->stateNum].sprite
mov   byte ptr cs:[SELFMODIFY_set_ax_to_spriteframe+1], al		   
mov   al, byte ptr es:[bx + 1]	; states_render[thing->stateNum].frame
mov   ah, SIZEOF_SPRITEFRAME_T
push   ax    ; bp - 2
sub   sp, 01Eh



mov   cx, 6
mov   bx, ss
mov   es, bx					; es is SS i.e. destination segment
mov   ds, dx					; ds is movsw source segment
mov   ax, word ptr ds:[si+010h]		; 010h
mov   word ptr cs:[SELFMODIFY_set_ax_to_angle_highword+1], ax
mov   al, byte ptr ds:[si+016h]	; 016h  flags2
mov   byte ptr cs:[SELFMODIFY_set_al_to_flags2+1], al

lea   di, [bp - 01Ah]			; di is the stack area to copy to..

rep   movsw

;si is [si + 0xC] now...


mov   ds, bx					; restore ds to 3C00
lea   si, [bp - 01Ah]

lodsw
SELFMODIFY_BSP_viewx_lo_1:
sub   ax, 01000h
stosw
xchg   bx, ax
lodsw
SELFMODIFY_BSP_viewx_hi_1:
sbb   ax, 01000h
stosw
xchg   cx, ax						

; todo:
; sub [bp - 016h], 01000h
; sbb [bp - 014h], 01000h

lodsw
SELFMODIFY_BSP_viewy_lo_1:
sub   ax, 01000h
stosw
lodsw
SELFMODIFY_BSP_viewy_hi_1:
sbb   ax, 01000h
stosw

;    gxt.w = FixedMulTrigNoShift(FINE_COSINE_ARGUMENT, viewangle_shiftright1 ,tr_x.w);

mov   ax, FINECOSINE_SEGMENT
SELFMODIFY_set_viewanglesr1_3:
mov   dx, 01000h
mov   di, dx
call  FixedMulTrigNoShiftBSPLocal_




mov   si, ax		; store gxt
xchg  di, dx		; get viewangle_shiftright1 into dx

; cx:bx = tr_y
les   bx, dword ptr [bp - 0Ah]
mov   cx, es


; di:si has gxt


;    gyt.w = -FixedMulTrigNoShift(FINE_SINE_ARGUMENT, viewangle_shiftright1 ,tr_y.w);

mov   ax, FINESINE_SEGMENT

call FixedMulTrigNoShiftBSPLocal_

; todo clean this up. less register swapping.


neg   dx
neg   ax
sbb   dx, 0

;    tz.w = gxt.w-gyt.w; 
mov   bx, si
mov   cx, di
sub   bx, ax
sbb   cx, dx


mov   word ptr cs:[SELFMODIFY_get_tz_lobits+1], bx
mov   word ptr cs:[SELFMODIFY_get_tz_hibits+1], cx

cmp   cx, MINZ_HIGHBITS

;    // thing is behind view plane?
;    if (tz.h.intbits < MINZ_HIGHBITS){ // (- sq: where does this come from)
;        return;
;    }

jl   exit_project_sprite


;    xscale.w = FixedDivWholeA(centerx, tz.w);

SELFMODIFY_BSP_centerx_4:
mov   ax, 01000h

call  FixedDivWholeA_BSPLocal_
mov   word ptr [bp - 01Eh], ax
mov   word ptr [bp - 01Ch], dx

lea   si, [bp - 0Eh]
lodsw
xchg  ax, bx
lodsw
xchg  ax, cx

mov   ax, FINESINE_SEGMENT
SELFMODIFY_set_viewanglesr1_2:
mov   dx, 01000h

call  FixedMulTrigNoShiftBSPLocal_
neg dx
neg ax
sbb dx, 0
; results from DX:AX to DI:SI... eventually
mov   di, dx
xchg  ax, dx


lodsw
xchg  ax, bx
lodsw
xchg  ax, cx

mov   si, dx  ; SI can now move 
mov   ax, FINECOSINE_SEGMENT
SELFMODIFY_set_viewanglesr1_1:
mov   dx, 01000h

call FixedMulTrigNoShiftBSPLocal_

;    tx.w = -(gyt.w+gxt.w); 

add   ax, si		; add gxt
adc   dx, di
neg   dx
neg   ax
sbb   dx, 0
mov   word ptr cs:[SELFMODIFY_get_temp_lowbits+1], ax
mov   si, dx						; si stores temp highbits
or    dx, dx

; si stores tx highbits?

;    // too far off the side?
;    if (labs(tx.w)>(tz.w<<2)){ // check just high 16 bits?

jge   tx_already_positive				; labs sign check
neg   ax
adc   dx, 0
neg   dx
tx_already_positive:

;        return;
;	}


mov   cx, ax
SELFMODIFY_get_tz_lobits:
mov   ax, 01234h
SELFMODIFY_get_tz_hibits:
mov   di, 01234h
add   ax, ax
adc   di, di
add   ax, ax
adc   di, di
cmp   dx, di
jle   not_too_far_off_side_highbits
exit_project_sprite:
LEAVE_MACRO 
pop   es
pop   si
ret   
not_too_far_off_side_highbits:
jne   not_too_far_off_side_lowbits
cmp   ax, cx
jb    exit_project_sprite
not_too_far_off_side_lowbits:
SELFMODIFY_set_ax_to_spriteframe:
mov   ax, 00012h  ; leave high byte 0
mov   di, ax
SHIFT_MACRO shl di 2
sub   di, ax
mov   ax, SPRITES_SEGMENT
mov   es, ax
mov   ax, word ptr [bp - 2]
and   al, FF_FRAMEMASK
mul   ah
mov   di, word ptr es:[di]
mov   bx, di
add   bx, ax
cmp   byte ptr es:[bx + 018h], 0
mov   bx, 0				; rot 0 on jmp
je    skip_sprite_rotation


les   ax, dword ptr [bp - 01Ah]
mov   dx, es
les   bx, dword ptr [bp - 016h]
mov   cx, es


SELFMODIFY_BSP_viewx_lo_3:
sub   ax, 01000h
SELFMODIFY_BSP_viewx_hi_3:
sbb   dx, 01000h

SELFMODIFY_BSP_viewy_lo_3:
sub   bx, 01000h
SELFMODIFY_BSP_viewy_hi_3:
sbb   cx, 01000h

call  R_PointToAngle_
mov   ax, dx
;rot = _rotl(ang.hu.intbits - thingangle.hu.intbits + 0x9000u, 3) & 0x07;

SELFMODIFY_set_ax_to_angle_highword:
sub   ax, 01212h

add   ah, 090h
SHIFT_MACRO rol ax 3
and   ax, 7
mov   bx, ax				; rot result
skip_sprite_rotation:
mov   ax, word ptr [bp - 2]
and   al, FF_FRAMEMASK
mul   ah
add   di, ax					; add frame offset

add   di, bx					; add rot lookup
mov   cx, SPRITES_SEGMENT
mov   es, cx

mov   bx, word ptr es:[bx+di]	; 2x rot lookup?
mov   word ptr [bp - 020h], bx
xchg  bx, di

mov   al, byte ptr es:[bx + 010h]
mov   byte ptr cs:[SELFMODIFY_set_flip+1], al
mov   ax, SPRITEOFFSETS_SEGMENT

mov   es, ax
mov   al, byte ptr es:[di]
les   bx, dword ptr [bp - 01Eh]
mov   cx, es
xor   ah, ah

sub   si, ax						; no need for sbb?
SELFMODIFY_get_temp_lowbits:
mov   ax, 01234h
mov   di, ax
mov   dx, si
call FixedMulBSPLocal_
xchg  ax, dx

SELFMODIFY_BSP_centerx_5:
add   ax, 01000h

;    // off the right side?
;    if (x1 > viewwidth){
;        return;
;    }
    

mov   word ptr cs:[SELFMODIFY_set_vis_x1+1], ax
mov   word ptr cs:[SELFMODIFY_sub_x1+1], ax
SELFMODIFY_BSP_viewwidth_2:
cmp   ax, 01000h
jle   not_too_far_off_right_side_highbits
jump_to_exit_project_sprite_2:
jmp   exit_project_sprite
not_too_far_off_right_side_highbits:
mov   bx, word ptr [bp - 020h]
mov   es, word ptr ds:[_spritewidths_segment]
mov   al, byte ptr es:[bx]
xor   ah, ah


;    if (usedwidth == 1){
;        usedwidth = 257;
;    }


cmp   ax, 1
jne   usedwidth_not_1
mov   ax, 257   
usedwidth_not_1:

;   temp.h.fracbits = 0;
;    temp.h.intbits = usedwidth;
;    // hack to make this fit in 8 bits, check r_init.c
;    tx.w +=  temp.w;
;	temp.h.intbits = centerx;
;	temp.w += FixedMul (tx.w,xscale.w);

mov   word ptr cs:[SELFMODIFY_set_ax_to_usedwidth+1], ax


les   bx, dword ptr [bp - 01Eh]
mov   cx, es
mov   dx, si

add   dx, ax					; no need for adc
mov   ax, di

call FixedMulBSPLocal_

;    x2 = temp.h.intbits - 1;

SELFMODIFY_BSP_centerx_6:
add   dx, 01000h
dec   dx
mov   word ptr cs:[SELFMODIFY_set_ax_to_x2+1], dx

;    // off the left side
;    if (x2 < 0)
;        return;

test  dx, dx
jl    jump_to_exit_project_sprite_2  ; 06Ah ish out of range

mov   si, word ptr ds:[_vissprite_p]
cmp  si, MAXVISSPRITES
je   got_vissprite
; don't increment vissprite if its the max index. reuse this index.
inc   word ptr ds:[_vissprite_p]
got_vissprite:
; mul by 28h or 40. SIZEOF_VISSPRITE_T

SHIFT_MACRO shl si 3


mov   bx, si

SHIFT_MACRO sal si 2
; x32 20h
lea   si, [bx + si + OFFSET _vissprites] ; x40  28h


les   ax, dword ptr [bp - 01Eh]
mov   di, es


SELFMODIFY_BSP_detailshift2minus_2:
; fall thru do twice
shl   ax, 1
rcl   di, 1
do_visscale_shift_once:
shl   ax, 1
rcl   di, 1
visscale_shift_done:

; si is vis
; todo clean this up too...

mov   word ptr ds:[si  + 01Ah], ax
mov   word ptr ds:[si  + 01Ch], di

mov   cx, 6
lea   di, [si  + 006h]
lea   si, [bp - 01Ah]

mov   ax, ss
mov   es, ax

; copy thing x y z to new vissprite x y z
rep movsw

lea   si, [di - 012h]			; restore si

mov   bx, word ptr [bp - 020h]
mov   ax, SPRITETOPOFFSETS_SEGMENT
mov   es, ax
mov   al, byte ptr es:[bx]
xor   dx, dx
cbw  

; todo maybe vis = &vissprites[vissprite_p - 1];

;    // hack to make this fit in 8 bits, check r_init.c
;    if (temp.h.intbits == -128){
;        temp.h.intbits = 129;
;    }


cmp   ax, 0FF80h				; -128
je   set_intbits_to_129
intbits_ready:
;	vis->gzt.w = vis->gz.w + temp.w;
mov   bx, word ptr ds:[si + 0Eh]
add   ax, word ptr ds:[si + 010h]
mov   word ptr ds:[si + 012h], bx
mov   word ptr ds:[si + 014h], ax

;    vis->texturemid = vis->gzt.w - viewz.w;

SELFMODIFY_BSP_viewz_lo_4:
sub       bx, 01000h
SELFMODIFY_BSP_viewz_hi_4:
sbb       ax, 01000h
mov   word ptr ds:[si + 022h], bx
mov   word ptr ds:[si + 024h], ax
SELFMODIFY_set_vis_x1:
mov   ax, 01234h

;    vis->x1 = x1 < 0 ? 0 : x1;

test  ax, ax
jge   x1_positive
xor   ax, ax

x1_positive:
mov   word ptr ds:[si + 2], ax

;    vis->x2 = x2 >= viewwidth ? viewwidth-1 : x2;       

SELFMODIFY_set_ax_to_x2:
mov   ax, 00012h			; get x2

SELFMODIFY_BSP_viewwidth_3:
mov   bx, 01000h
cmp   ax, bx
jl    x2_smaller_than_viewwidth
mov   ax, bx
dec   ax
x2_smaller_than_viewwidth:
les   bx, dword ptr [bp - 01Eh]
mov   cx, es
mov   word ptr ds:[si + 4], ax
mov   ax, 1
call FixedDivWholeA_BSPLocal_
mov   bx, ax
SELFMODIFY_set_flip:
mov   al, 00h
cmp   al, 0
jne   flip_not_zero
jmp   flip_zero
set_intbits_to_129:
mov   ax, 129
jmp intbits_ready

flip_not_zero:
mov   word ptr ds:[si + 016h], -1
SELFMODIFY_set_ax_to_usedwidth:
mov   ax, 01234h 
dec   ax
mov   word ptr ds:[si + 018h], ax

neg   dx
neg   bx
sbb   dx, 0

mov   word ptr ds:[si + 01Eh], bx
mov   word ptr ds:[si + 020h], dx

flip_stuff_done:


;    if (vis->x1 > x1)
;        vis->startfrac += FastMul16u32u((vis->x1-x1),vis->xiscale);

mov   ax, word ptr ds:[si + 2]
SELFMODIFY_sub_x1:
sub   ax, 01234h
jle   vis_x1_greater_than_x1
les   bx, dword ptr ds:[si + 01Eh]
mov   cx, es
; inlined FastMul16u32u

IF COMPISA GE COMPILE_386


   ; set up ecx
   db 066h, 0C1h, 0E3h, 010h        ; shl  ebx, 0x10
   db 066h, 00Fh, 0A4h, 0D9h, 010h  ; shld ecx, ebx, 0x10

   ; set up eax
   db 066h, 098h                    ; cwde (prepare AX)

   ; actual mul
   db 066h, 0F7h, 0E1h              ; mul ecx
   ; set up return
   db 066h, 00Fh, 0A4h, 0C2h, 010h  ; shld edx, eax, 0x10
   

ELSE

   XCHG CX, AX    ; AX stored in CX
   MUL  CX        ; AX * CX
   XCHG CX, AX    ; store low product to be high result. Retrieve orig AX
   MUL  BX        ; AX * BX
   ADD  DX, CX    ; add 
ENDIF

add   word ptr ds:[si + 016h], ax
adc   word ptr ds:[si + 018h], dx

vis_x1_greater_than_x1:
mov   bx, word ptr [bp - 020h]
mov   word ptr ds:[si + 026h], bx

;    if (thingflags2 & MF_SHADOW) {

SELFMODIFY_set_al_to_flags2:
mov   al, 00h
test  al, MF_SHADOW
jne   exit_set_shadow
SELFMODIFY_BSP_fixedcolormap_2:
jmp SHORT   exit_set_fixed_colormap
SELFMODIFY_BSP_fixedcolormap_2_AFTER:
test  byte ptr [bp - 2], FF_FULLBRIGHT
jne   exit_set_fullbright_colormap


;        index = xscale.w>>(LIGHTSCALESHIFT-detailshift.b.bytelow);

; shift 32 bit value by (12 - detailshift) right.
; but final result is capped at 48. so we dont have to do as much with the high word...
mov   ax, word ptr [bp - 01Dh] ; shift 8 by loading a byte higher.
; shift 2 more guaranteed
SHIFT_MACRO sar ax 2

; test for detailshift portion
SELFMODIFY_BSP_detailshift_7:
sar   ax, 1
shift_xscale_once:
sar   ax, 1
done_shifting_xscale:
mov   di, ax

;        if (index >= MAXLIGHTSCALE) {
;            index = MAXLIGHTSCALE-1;
;        }


cmp   ax, MAXLIGHTSCALE
jl    index_below_maxlightscale
mov   di, MAXLIGHTSCALE - 1
index_below_maxlightscale:
SELFMODIFY_set_spritelights_1:
mov   bx, 01000h
mov   al, byte ptr ds:[_scalelightfixed+bx+di]
mov   byte ptr ds:[si + 1], al
LEAVE_MACRO
pop   es
pop   si
ret   

exit_set_fullbright_colormap:
mov   byte ptr ds:[si + 1], 0
LEAVE_MACRO
pop   es
pop   si
ret   

SELFMODIFY_BSP_fixedcolormap_2_TARGET:
SELFMODIFY_BSP_fixedcolormap_1:
exit_set_fixed_colormap:
mov   byte ptr ds:[si + 1], 0
LEAVE_MACRO
pop   es
pop   si
ret   


flip_zero:
mov   word ptr ds:[si + 016h], 0
mov   word ptr ds:[si + 018h], 0
mov   word ptr ds:[si + 01Eh], bx
mov   word ptr ds:[si + 020h], dx
jmp   flip_stuff_done
exit_set_shadow:
mov   byte ptr ds:[si + 1], COLORMAP_SHADOW
LEAVE_MACRO
pop   es
pop   si
ret   

ENDP





;R_AddSprites_

PROC R_AddSprites_ NEAR
PUBLIC R_AddSprites_ 

; DX:AX = sector_t __far* sec

mov   bx, ax
mov   es, dx
mov   ax, word ptr es:[bx + 6]		; sec->validcount
mov   dx, word ptr ds:[_validcount_global]
cmp   ax, dx
je    exit_add_sprites_quick

mov   word ptr es:[bx + 6], dx
mov   al, byte ptr es:[bx + 0Eh]		; sec->lightlevel
xor   ah, ah
mov   dx, ax

SHIFT_MACRO sar dx 4



SELFMODIFY_BSP_extralight1:
mov   al, 0
add   ax, dx
test  ax, ax
jl    set_spritelights_to_zero
cmp   ax, LIGHTLEVELS
jge   set_spritelights_to_max
mov   ah, 48
mul   ah
spritelights_set:
mov   word ptr cs:[SELFMODIFY_set_spritelights_1 + 1], ax 
mov   ax, word ptr es:[bx + 8]
test  ax, ax
je    exit_add_sprites
mov   si, MOBJPOSLIST_SEGMENT
mov   es, si

loop_things_in_thinglist:
; multiply by 18h (SIZEOF_MOBJ_POS_T), AX maxes at MAX_THINKERS - 1 (839), cant 8 bit mul
; tested, imul si, ax, SIZEOF_MOBJ_POS_T  still slower


SHIFT_MACRO sal ax 3


mov   si, ax
sal   si, 1
add   si, ax
call  R_ProjectSprite_
mov   ax, word ptr es:[si + 0Ch]
test  ax, ax
jne   loop_things_in_thinglist

exit_add_sprites:
exit_add_sprites_quick:
ret   
set_spritelights_to_zero:
xor   ax, ax
jmp   spritelights_set
set_spritelights_to_max:
; _NULL_OFFSET + 02A0h + 16 - 1 ... (0x2ee)
mov    ax, 720   ; hardcoded (lightmult48lookup[LIGHTLEVELS - 1])
jmp   spritelights_set


endp

COLFUNC_JUMP_AND_DC_YL_OFFSET_DIFF   = ((DC_YL_LOOKUP_SEGMENT - COLFUNC_JUMP_LOOKUP_SEGMENT) * 16)
COLFUNC_JUMP_AND_FUNCTION_AREA_OFFSET_DIFF = ((COLFUNC_FUNCTION_AREA_SEGMENT - COLFUNC_JUMP_LOOKUP_SEGMENT) * 16)






out_of_drawsegs:
LEAVE_MACRO
pop       di
pop       si
pop       cx
pop       bx
ret       



; 1 SHR 12
HEIGHTUNIT = 01000h
HEIGHTBITS = 12
FINE_ANGLE_HIGH_BYTE = 01Fh
FINE_TANGENT_MAX = 2048







SHORTTOFINESHIFT = 3
SIL_NONE =   0
SIL_BOTTOM = 1
SIL_TOP =    2
SIL_BOTH =   3
FINE_ANG90_NOSHIFT = 02000h
FINE_ANG180_NOSHIFT = 04000h
ANG180_HIGHBITS = 08000h
MOD_FINE_ANGLE_NOSHIFT_HIGHBITS = 07Fh
ML_DONTPEGBOTTOM = 010h
ML_DONTPEGTOP = 8
SCALE_LIGHT_OFFSET_IN_FIXED_SCALELIGHT = 030h
MAXDRAWSEGS = 256


;R_StoreWallRange_

PROC R_StoreWallRange_ NEAR
PUBLIC R_StoreWallRange_ 

; bp - 2  ; ax arg
; bp - 4  ; dx arg
; bp - 6     ; hyp lo
; bp - 8     ; hyp hi
; bp - 0Ah   ; side toptexture
; bp - 0Ch   ; side bottomtexture
; bp - 0Eh   ; side midtexture
; bp - 010h  ; v1.x
; bp - 012h  ; v1.y
; bp - 014h  ; lineflags
; bp - 016h  ; offsetangle
; bp - 018h  ; _rw_x
; bp - 01Ah  ; _rw_stopx
; bp - 01Bh  ; markceiling
; bp - 01Ch  ; markfloor
; bp - 01Eh  ; UNUSED?
; bp - 020h  ; pixhigh hi
; bp - 022h  ; pixhigh lo
; bp - 024h  ; pixlow hi
; bp - 026h  ; pixlow lo
; bp - 028h  ; bottomfrac hi
; bp - 02Ah  ; bottomfrac lo
; bp - 02Ch  ; topfrac hi
; bp - 02Eh  ; topfrac lo
; bp - 030h  ; rw_scale hi
; bp - 032h  ; rw_scale lo
; bp - 034h  ; frontsectorfloorheight
; bp - 036h  ; frontsectorceilingheight
; bp - 037h  ; frontsectorceilingpic
; bp - 038h  ; backsectorceilingpic
; bp - 039h  ; frontsectorfloorpic
; bp - 03Ah  ; backsectorfloorpic
; bp - 03Bh  ; frontsectorlightlevel
; bp - 03Ch  ; backsectorlightlevel
; bp - 03Eh  ; worldtop hi
; bp - 040h  ; worldtop lo
; bp - 042h  ; worldbottom hi
; bp - 044h  ; worldbottom lo
; bp - 046h  ; backsectorfloorheight
; bp - 048h  ; backsectorceilingheight


; bp + 010h   ; rw_angle lo from R_AddLine
; bp + 012h   ; rw_angle hi from R_AddLine

             
push      bx ; +8
push      cx ; +6
push      si ; +4
push      di ; +2
push      bp ; +0
mov       bp, sp
push      ax ; bp - 2
push      dx ; bp - 4
xor       ax, ax


SELFMODIFY_get_curseg_render_1:
mov       bx, 01000h 

push      ax ; bp - 6
push      ax ; bp - 8

mov       si, word ptr ds:[bx + 6]
SHIFT_MACRO shl si 2
mov       di, si
shl       si, 1

mov       cx, ds  ; store for later.
mov       ax, SIDES_SEGMENT
mov       ds, ax

; read all the sides fields now. ;preshift them as they are word lookups

lodsw
push ax   ; bp - 0Ah
lodsw
sal       ax, 1               ; preshift
push ax   ; bp - 0Ch
lodsw
push ax   ; bp - 0Eh
lodsw     ; textureoffset todo can be 8 bit


les        si, dword ptr ss:[bx]   ; vertexes


mov       word ptr cs:[SELFMODIFY_BSP_sidetextureoffset+1], ax

; todo pull this out into outer func?
mov       ax, word ptr ss:[di+_sides_render]
mov       word ptr cs:[SELFMODIFY_BSP_siderenderrowoffset_1+1], ax
mov       word ptr cs:[SELFMODIFY_BSP_siderenderrowoffset_2+1], ax

mov       ax, VERTEXES_SEGMENT 
mov       ds, ax	; if put into ds we could lodsw a bit... worth?
SHIFT_MACRO shl si 2
lodsw
push      ax       ; bp - 010h
lodsw
push      ax       ; bp - 012h


mov       si, es ; les earlier
SHIFT_MACRO shl si 2

lodsw
mov       word ptr cs:[SELFMODIFY_BSP_v2x+1], ax
lodsw
mov       word ptr cs:[SELFMODIFY_BSP_v2y+1], ax

mov       ds, cx  ; restore ds..

mov       bx, word ptr ds:[_ds_p]
cmp       bx, (MAXDRAWSEGS * SIZEOF_DRAWSEG_T)
je        out_of_drawsegs

mov       ax, LINEFLAGSLIST_SEGMENT ; we will also index seg_linedefs off this.
mov       es, ax
SELFMODIFY_get_curseg_1:
mov       bx, 01000h
mov       si, word ptr es:[bx + (16 * (SEG_LINEDEFS_SEGMENT - LINEFLAGSLIST_SEGMENT))]
mov       al, byte ptr es:[si]
xor       ah, ah
push      ax      ; bp - 014h


;	seenlines[linedefOffset/8] |= (0x01 << (linedefOffset % 8));
; si is linedefOffset

mov       cx, si


SHIFT_MACRO sar si 3



mov       ax, SEENLINES_SEGMENT
mov       es, ax
mov       al, 1
and       cl, 7
shl       al, cl
or        byte ptr es:[si], al

; bx still curseg word lookup

mov       ax, word ptr ds:[bx+_seg_normalangles]

mov       word ptr cs:[SELFMODIFY_sub_rw_normal_angle_1+1], ax
xchg      ax, si


SELFMODIFY_set_viewanglesr3_1:
mov       ax, 01000h
;add       ah, 8  ; preadded
sub       ax, si
and       ah, FINE_ANGLE_HIGH_BYTE

; set centerangle in rendersegloop
mov       word ptr cs:[SELFMODIFY_set_rw_center_angle+1], ax


xchg      ax, si


SHIFT_MACRO shl ax SHORTTOFINESHIFT



mov       word ptr cs:[SELFMODIFY_set_rw_normal_angle_shift3+1], ax


;	offsetangle = (abs((rw_normalangle_shiftleft3) - (rw_angle1.hu.intbits)) >> 1) & 0xFFFC;
sub       ax, word ptr [bp + 012h]   ; rw_angle hi from R_AddLine
cwd       
xor       ax, dx		; what's this about. is it an abs() thing?
sub       ax, dx
sar       ax, 1

and       al, 0FCh
push      ax  ; bp - 016h
mov       si, FINE_ANG90_NOSHIFT
cmp       ax, si
jnb        offsetangle_above_ang_90

offsetangle_below_ang_90:
les       dx, dword ptr [bp - 012h]
mov       ax, es
call      R_PointToDist_
mov       word ptr [bp - 6], ax
mov       word ptr [bp - 8], dx
sub       si, word ptr [bp - 016h]
mov       bx, ax
mov       cx, dx
mov       ax, FINESINE_SEGMENT
mov       dx, si
call     FixedMulTrigNoShiftBSPLocal_

jmp       do_set_rw_distance
offsetangle_above_ang_90:
xor       ax, ax
mov       dx, ax



do_set_rw_distance:

; self modifying code for rw_distance
mov   word ptr cs:[SELFMODIFY_set_bx_rw_distance_lo+1], ax
mov   word ptr cs:[SELFMODIFY_set_cx_rw_distance_hi+1], dx
mov   word ptr cs:[SELFMODIFY_get_rw_distance_lo_1+1], ax
mov   word ptr cs:[SELFMODIFY_get_rw_distance_hi_1+1], dx

done_setting_rw_distance:
les       di, dword ptr ds:[_ds_p]
SELFMODIFY_get_curseg_2:
mov       ax, 01000h
stosw              ; +0


mov       ax, word ptr [bp - 2]
push      ax   ; bp - 018h r  w_x
stosw              ; +2

mov       ax, word ptr [bp - 4]
stosw              ; +4

inc       ax
push      ax   ; bp - 01Ah  rw_stopx
sub       sp, 014h   ; ;30h now

mov       ax, XTOVIEWANGLE_SEGMENT
mov       bx, word ptr [bp - 2]
mov       cx, es  ; store ds_p+2 segment
mov       es, ax
add       bx, bx
SELFMODIFY_set_viewanglesr3_3:
mov       ax, 01000h
add       ax, word ptr es:[bx]
call      R_ScaleFromGlobalAngle_
mov       es, cx ; restore es as ds_p+2 segment
push      dx  ; bp - 030h
push      ax  ; bp - 032h
stosw             ; +6
xchg      ax, dx
stosw             ; +8
xchg      ax, dx                       ; put DX back; need it later.
mov       si, word ptr [bp - 4]
cmp       si, word ptr [bp - 2]

jg        stop_greater_than_start

; ds_p is es:di
;		ds_p->scale2 = ds_p->scale1;

stosw      ; +0Ah
xchg      ax, dx
stosw      ; +0Ch
xchg      ax, dx
jmp       scales_set
handle_negative_3216:

neg ax
adc dx, 0
neg dx


cmp dx, bx
jge two_part_divide_3216
one_part_divide_3216:
div bx
xor dx, dx

neg ax
adc dx, 0
neg dx
jmp div_done

two_part_divide_3216:
mov es, ax
mov ax, dx
xor dx, dx
div bx     ; div high
mov ds, ax ; store q1
mov ax, es
; DX:AX contains remainder + ax...
div bx
mov dx, ds  ; retrieve q1
            ; q0 already in ax
neg ax
adc dx, 0
neg dx


mov bx, ss
mov ds, bx  ; restored ds
jmp div_done
one_part_divide:
div bx
xor dx, dx
jmp div_done

stop_greater_than_start:

sal       si, 1
mov       ax, XTOVIEWANGLE_SEGMENT
mov       es, ax
SELFMODIFY_set_viewanglesr3_2:
mov       ax, 01000h
add       ax, word ptr es:[si]
call      R_ScaleFromGlobalAngle_
mov       es, cx ; restore es as ds_p+2
mov       bx, word ptr [bp - 4]
stos      word ptr es:[di]             ; +0Ah
xchg      ax, dx
sub       bx, word ptr [bp - 2]
stos      word ptr es:[di]             ; +0Ch
xchg      ax, dx
sub       ax, word ptr [bp - 032h]
sbb       dx, word ptr [bp - 030h]

; inlined FastDiv3216u_    (only use in the codebase, might as well.)
test dx, dx
js   handle_negative_3216

cmp dx, bx
jl one_part_divide

two_part_divide:
mov es, ax
mov ax, dx
xor dx, dx
div bx     ; div high
mov ds, ax ; store q1
mov ax, es
; DX:AX contains remainder + ax...
div bx
mov dx, ds  ; retrieve q1
            ; q0 already in ax
mov bx, ss
mov ds, bx  ; restored ds



div_done:





mov       es, cx ; restore es as ds_p+2
stos      word ptr es:[di]             ; +0Eh
xchg      ax, dx
stos      word ptr es:[di]             ; +10h
xchg      ax, dx

mov       si, cs
mov       ds, si
ASSUME DS:R_BSP_TEXT
; rw_scalestep is ready. write it forward as selfmodifying code here

mov       word ptr ds:[SELFMODIFY_get_rwscalestep_lo_1+1], ax
mov       word ptr ds:[SELFMODIFY_get_rwscalestep_lo_2+1], ax
mov       word ptr ds:[SELFMODIFY_get_rwscalestep_lo_3+1], ax
mov       word ptr ds:[SELFMODIFY_get_rwscalestep_lo_4+1], ax
mov       word ptr ds:[SELFMODIFY_add_rwscale_lo+4], ax
mov       word ptr ds:[SELFMODIFY_sub_rwscale_lo+3], ax

xchg      ax, dx
mov       word ptr ds:[SELFMODIFY_get_rwscalestep_hi_1+1], ax
mov       word ptr ds:[SELFMODIFY_get_rwscalestep_hi_2+1], ax
mov       word ptr ds:[SELFMODIFY_get_rwscalestep_hi_3+1], ax
mov       word ptr ds:[SELFMODIFY_get_rwscalestep_hi_4+1], ax


mov       word ptr ds:[SELFMODIFY_add_rwscale_hi+4], ax
mov       word ptr ds:[SELFMODIFY_sub_rwscale_hi+3], ax



; todo change these in 386 mode to shld?
SELFMODIFY_BSP_detailshift_1:
shl   dx, 1
rcl   ax, 1
shift_rw_scale_once:
shl   dx, 1
rcl   ax, 1
finished_shifting_rw_scale:

mov       word ptr ds:[SELFMODIFY_add_to_rwscale_hi_1+3], ax
mov       word ptr ds:[SELFMODIFY_add_to_rwscale_hi_2+3], ax
xchg      ax, dx
mov       word ptr ds:[SELFMODIFY_add_to_rwscale_lo_1+3], ax
mov       word ptr ds:[SELFMODIFY_add_to_rwscale_lo_2+3], ax

mov       si, ss   ; restore DS
mov       ds, si
ASSUME DS:DGROUP  ; lods coming up



scales_set:


; si = frontsector
les       si, dword ptr ds:[_frontsector]
lods      word ptr es:[si]
push      ax   ; bp - 034h
xchg      ax, bx
lods      word ptr es:[si]
push      ax   ; bp - 036h
xchg      ax, cx
lods      word ptr es:[si]
push      ax   ; bp - 038; bp - 037h gets ah
xchg      ah, al
push      ax   ; bp - 03A; bp - 037h gets ah


; BIG TODO: make this di used some other way
; (di:si is worldtop)

;	SET_FIXED_UNION_FROM_SHORT_HEIGHT(worldtop, frontsectorceilingheight);
;	worldtop.w -= viewz.w;

push      word ptr es:[si + 07h]  ; + 6 from lodsw/lodsb = 0eh
                                  ; bp - 03C; bp - 03Bh gets ah

xchg      ax, cx  ; ax has frontsectorceilingheight
; todo can this cwd
xor       dx, dx
sar       ax, 1
rcr       dx, 1
sar       ax, 1
rcr       dx, 1
sar       ax, 1
rcr       dx, 1


SELFMODIFY_BSP_viewz_lo_7:
sub       dx, 01000h
SELFMODIFY_BSP_viewz_hi_7:
sbb       ax, 01000h
; storeworldtop

push      ax  ; bp - 03Eh
push      dx  ; bp - 040h


xchg      ax, bx    ; restore from before

xor       cx, cx
sar       ax, 1
rcr       cx, 1
sar       ax, 1
rcr       cx, 1
sar       ax, 1
rcr       cx, 1
SELFMODIFY_BSP_viewz_lo_8:
sub       cx, 01000h
SELFMODIFY_BSP_viewz_hi_8:
sbb       ax, 01000h
push      ax ; bp - 042h
push      cx ; bp - 044h


xor       ax, ax

; zero out maskedtexture 
mov       byte ptr ds:[_maskedtexture], al
; default to 0
mov       byte ptr cs:[SELFMODIFY_check_for_any_tex+1], al

les       bx, dword ptr ds:[_ds_p]
mov       word ptr es:[bx + 01ah], NULL_TEX_COL
cmp       word ptr ds:[_backsector], SECNUM_NULL

mov       ax, cs
mov       ds, ax


je        handle_single_sided_line
jmp       handle_two_sided_line

handle_single_sided_line:

ASSUME DS:R_BSP_TEXT

SELFMODIFY_BSP_drawtype_1:
SELFMODIFY_BSP_drawtype_1_AFTER = SELFMODIFY_BSP_drawtype_1 + 2


mov       ax, ((SELFMODIFY_BSP_midtextureonly_skip_pixhighlow_1_TARGET - SELFMODIFY_BSP_midtextureonly_skip_pixhighlow_1_AFTER) SHL 8) + 0EBh
mov       word ptr ds:[SELFMODIFY_BSP_midtextureonly_skip_pixhighlow_1], ax
mov       ah, SELFMODIFY_BSP_midtextureonly_skip_pixhighlow_2_TARGET - SELFMODIFY_BSP_midtextureonly_skip_pixhighlow_2_AFTER
mov       word ptr ds:[SELFMODIFY_BSP_midtextureonly_skip_pixhighlow_2], ax
mov       ah, SELFMODIFY_BSP_midtextureonly_skip_pixhighlow_3_TARGET - SELFMODIFY_BSP_midtextureonly_skip_pixhighlow_3_AFTER
mov       word ptr ds:[SELFMODIFY_BSP_midtextureonly_skip_pixhighlow_3], ax
mov       ah, SELFMODIFY_BSP_midtextureonly_skip_pixhighlow_5_TARGET - SELFMODIFY_BSP_midtextureonly_skip_pixhighlow_5_AFTER
mov       word ptr ds:[SELFMODIFY_BSP_midtextureonly_skip_pixhighlow_5], ax

;mov       ax, ((SELFMODIFY_BSP_midtextureonly_skip_pixhighlow_4_TARGET - SELFMODIFY_BSP_midtextureonly_skip_pixhighlow_4_AFTER) SHL 8) + 0E2h  ; LOOP instruction
;mov       word ptr ds:[SELFMODIFY_BSP_midtextureonly_skip_pixhighlow_4], ax


 
mov       word ptr ds:[SELFMODIFY_BSP_drawtype_2], 089B8h   ; mov ax, xx89
mov       word ptr ds:[SELFMODIFY_BSP_drawtype_1], ((SELFMODIFY_BSP_drawtype_1_TARGET - SELFMODIFY_BSP_drawtype_1_AFTER) SHL 8) + 0EBh

mov       byte ptr ds:[SELFMODIFY_BSP_midtexture_return_jmp+0], 026h    ; es:
mov       word ptr ds:[SELFMODIFY_BSP_midtexture_return_jmp+1], 087C7h  ; next 2 bytes of following instr (mov   word ptr es:[bx + OFFSET_CEILINGCLIP], 01000h)

mov       byte ptr ds:[SELFMODIFY_BSP_midtexture], 039h     ; cmp di,
mov       word ptr ds:[SELFMODIFY_BSP_midtexture+1], 07CF7h   ; (cmp di,) si, jl


SELFMODIFY_BSP_drawtype_1_TARGET:

;es:bx still side
mov       ax, TEXTURETRANSLATION_SEGMENT
mov       bx, [bp - 0Eh]
mov       es, ax
add       bx, bx
mov       ax, word ptr es:[bx]

; write the high byte of the word.
; prev two bytes will be a jump or mov cx with the low byte



mov       word ptr ds:[SELFMODIFY_BSP_set_midtexture+1], ax
; are any bits set?
or        al, ah
or        byte ptr ds:[SELFMODIFY_check_for_any_tex+1], al



mov       ax, 0101h
mov       word ptr [bp - 01Ch], ax ; set markfloor and markceiling
test      byte ptr [bp - 014h], ML_DONTPEGBOTTOM
jne       do_peg_bottom
dont_peg_bottom:
mov       ax, word ptr [bp - 040h]
mov       word ptr ds:[SELFMODIFY_set_midtexturemid_lo+1], ax
mov       ax, word ptr [bp - 03Eh]
; ax has rw_midtexturemid+2
jmp       done_with_bottom_peg



do_peg_bottom:
mov       ax, word ptr [bp - 034h]
SELFMODIFY_BSP_viewz_shortheight_5:
sub       ax, 01000h
xor       cx, cx
sar       ax, 1
rcr       cx, 1
sar       ax, 1
rcr       cx, 1
sar       ax, 1
rcr       cx, 1
mov       word ptr ds:[SELFMODIFY_set_midtexturemid_lo+1], cx


mov       bx, word ptr [bp - 0Eh]
mov       cx, TEXTUREHEIGHTS_SEGMENT
mov       es, cx
xor       cx, cx
mov       cl, byte ptr es:[bx]
inc       cx
add       ax, cx
done_with_bottom_peg:
; cx:ax has rw_midtexturemid



SELFMODIFY_BSP_siderenderrowoffset_1:
add       ax, 01000h

mov       word ptr ds:[SELFMODIFY_set_midtexturemid_hi+1], ax

mov       bx, ss   ; restore DS
mov       ds, bx
ASSUME DS:DGROUP


les       bx, dword ptr ds:[_ds_p]
mov       word ptr es:[bx + 012h], MAXSHORT
mov       word ptr es:[bx + 014h], MINSHORT
mov       word ptr es:[bx + 016h], OFFSET_SCREENHEIGHTARRAY
mov       word ptr es:[bx + 018h], OFFSET_NEGONEARRAY
mov       byte ptr es:[bx + 01Ch], SIL_BOTH
xor       ax, ax
; here
done_with_sector_sided_check:
; coming into here, AL is equal to maskedtexture.
; if backsector is not null, then di/si are worldlow
; and 2 words on top of stack are worldhigh.

; set maskedtexture in rendersegloop

; NOTE: Dont selfmodify these branches into nop/jump. tested to be slower?
; though thats with [nop to a long jmp]. could try straight long jmp. 
; modify the word addr but not the long jmp instruction for a single word.
mov       byte ptr cs:[SELFMODIFY_get_maskedtexture_1+1], al
mov       byte ptr cs:[SELFMODIFY_get_maskedtexture_2+1], al

; create segtextured value
SELFMODIFY_check_for_any_tex:
or   	  al, 0

; set segtextured in rendersegloop



jne       do_seg_textured_stuff
mov       word ptr cs:[SELFMODIFY_BSP_get_segtextured], ((SELFMODIFY_BSP_get_segtextured_TARGET - SELFMODIFY_BSP_get_segtextured_AFTER) SHL 8) + 0EBh

jmp       seg_textured_check_done
do_seg_textured_stuff:
mov       word ptr cs:[SELFMODIFY_BSP_get_segtextured], 0C089h ; nop
mov       ax, word ptr [bp - 016h]
cmp       ax, FINE_ANG180_NOSHIFT
jbe       offsetangle_greater_than_fineang180
neg       ax
and       ah, MOD_FINE_ANGLE_NOSHIFT_HIGHBITS
mov       word ptr [bp - 016h], ax
offsetangle_greater_than_fineang180:
mov       ax, word ptr [bp - 8]
or        ax, word ptr [bp - 6]
jne       hyp_already_set   		; todo what is hyp about
les       dx, dword ptr [bp - 012h]
mov       ax, es
call      R_PointToDist_
mov       word ptr [bp - 6], ax
mov       word ptr [bp - 8], dx
hyp_already_set:
mov       dx, word ptr [bp - 016h]
cmp       dx, FINE_ANG90_NOSHIFT
ja        offsetangle_greater_than_fineang90
les       cx, dword ptr [bp - 8]
mov       bx, es
mov       ax, FINESINE_SEGMENT
call      FixedMulTrigNoShiftBSPLocal_
; used later, dont change?
; dx:ax is rw_offset
xchg      ax, dx
jmp       done_with_offsetangle_stuff
offsetangle_greater_than_fineang90:
les       dx, dword ptr [bp - 8]
mov       ax, es  ; bp - 6



done_with_offsetangle_stuff:
; ax:dx is rw_offset

xor       cx, cx
SELFMODIFY_set_rw_normal_angle_shift3:

mov       bx, 01000h
sub       cx, word ptr [bp + 010h]   ; rw_angle lo from R_AddLine
sbb       bx, word ptr [bp + 012h]   ; rw_angle hi from R_AddLine

; ANG180_HIGHBITS is 08000h. can we get this for free without cmp with a sign thing?
cmp       bx, ANG180_HIGHBITS
jae       tempangle_not_smaller_than_fineang180
; bx is already _rw_offset
neg       ax
neg       dx
sbb       ax, 0
tempangle_not_smaller_than_fineang180:




SELFMODIFY_BSP_sidetextureoffset:
add       ax, 01000h
SELFMODIFY_get_curseg_render_2:
add       ax, word ptr ds:[01000h]
; rw_offset ready to be written to rendersegloop:
mov   word ptr cs:[SELFMODIFY_set_cx_rw_offset_lo+1], dx
mov   word ptr cs:[SELFMODIFY_set_ax_rw_offset_hi+1], ax







SELFMODIFY_BSP_fixedcolormap_3:
jmp SHORT seg_textured_check_done    ; dont check walllights if fixedcolormap
SELFMODIFY_BSP_fixedcolormap_3_AFTER:
mov       al, byte ptr [bp - 03Bh]
xor       ah, ah
SELFMODIFY_BSP_extralight2:
mov       dl, 0

SHIFT_MACRO sar ax 4



xor       dh, dh
add       dx, ax
mov       ax, word ptr [bp - 012h]
SELFMODIFY_BSP_v2y:
cmp       ax, 01000h
je        v1y_equals_v2y

mov       ax, word ptr [bp - 010h]
SELFMODIFY_BSP_v2x:
cmp       ax, 01000h
jne       v1x_equals_v2x

inc       dx
jge       lightnum_greater_than_0
mov       ax, _scalelightfixed + SCALE_LIGHT_OFFSET_IN_FIXED_SCALELIGHT
jmp       done_setting_ax_to_wallights


v1y_equals_v2y:
dec       dx
jge       lightnum_greater_than_0
mov       ax, _scalelightfixed + SCALE_LIGHT_OFFSET_IN_FIXED_SCALELIGHT
jmp       done_setting_ax_to_wallights

v1x_equals_v2x:
test      dx, dx

jge       lightnum_greater_than_0
mov       ax, _scalelightfixed + SCALE_LIGHT_OFFSET_IN_FIXED_SCALELIGHT
jmp       done_setting_ax_to_wallights
lightnum_max:
mov      ax, 720 + _scalelightfixed + SCALE_LIGHT_OFFSET_IN_FIXED_SCALELIGHT
jmp      done_setting_ax_to_wallights
lightnum_greater_than_0:
cmp       dx, LIGHTLEVELS
jnl       lightnum_max

lightnum_less_than_lightlevels:
mov       al, 48
mul       dl
add       ax, _scalelightfixed + SCALE_LIGHT_OFFSET_IN_FIXED_SCALELIGHT
done_setting_ax_to_wallights:


; write walllights to rendersegloop
mov   word ptr cs:[SELFMODIFY_add_wallights+2], ax
; ? do math here and write this ahead to drawcolumn colormapsindex?

SELFMODIFY_BSP_fixedcolormap_3_TARGET:
seg_textured_check_done:
mov       ax, word ptr [bp - 034h]
SELFMODIFY_BSP_viewz_shortheight_4:
cmp       ax, 01000h
jl        not_above_viewplane
mov       byte ptr [bp - 01Ch], 0
not_above_viewplane:
mov       ax, word ptr [bp - 036h]
SELFMODIFY_BSP_viewz_shortheight_3:
cmp       ax, 01000h
jg        not_below_viewplane
mov       al, byte ptr [bp - 037h]
cmp       al, byte ptr ds:[_skyflatnum]
je        not_below_viewplane
mov       byte ptr [bp - 01Bh], 0  ;markceiling
not_below_viewplane:

les       ax, dword ptr [bp - 040h]
mov       dx, es


sar       dx, 1
rcr       ax, 1
sar       dx, 1
rcr       ax, 1
sar       dx, 1
rcr       ax, 1
sar       dx, 1
rcr       ax, 1

mov       word ptr [bp - 03Eh], dx
mov       word ptr [bp - 040h], ax

; les to load two words
les       bx, dword ptr [bp - 032h]
mov       cx, es

;start inlined FixedMulBSPLocal_



IF COMPISA GE COMPILE_386

   ; set up ecx
   db 066h, 0C1h, 0E3h, 010h        ; shl  ebx, 0x10
   db 066h, 00Fh, 0A4h, 0D9h, 010h  ; shld ecx, ebx, 0x10

   ; set up eax
   db 066h, 0C1h, 0E0h, 010h        ; shl  eax, 0x10
   db 066h, 00Fh, 0ACh, 0D0h, 010h  ; shrd eax, edx, 0x10

   ; actual mul
   db 066h, 0F7h, 0E9h              ; imul ecx
   ; set up return
   db 066h, 0C1h, 0E8h, 010h        ; shr  eax, 0x10


ELSE
   push  si
   mov   es, ax	; store ax in es
   mov   ds, dx    ; store dx in ds
   mov   ax, dx	; ax holds dx
   CWD				; S0 in DX

   AND   DX, BX	; S0*BX
   NEG   DX
   mov   SI, DX	; DI stores hi word return

   ; AX still stores DX
   MUL  CX         ; DX*CX
   add  SI, AX    ; low word result into high word return

   mov  AX, DS    ; restore DX from ds
   MUL  BX         ; DX*BX
   XCHG BX, AX    ; BX will hold low word return. store bx in ax
   add  SI, DX    ; add high word to result

   mov  DX, ES    ; restore AX from ES
   mul  DX        ; BX*AX  
   add  BX, DX    ; high word result into low word return
   ADC  SI, 0

   mov  AX, CX   ; AX holds CX
   CWD           ; S1 in DX

   mov  CX, ES   ; AX from ES
   AND  DX, CX   ; S1*AX
   NEG  DX
   ADD  SI, DX   ; result into high word return

   MUL  CX       ; AX*CX

   ADD  AX, BX	  ; set up final return value
   ADC  DX, SI

   ;mov  CX, SS   ; dont restore DS 
   ;mov  DS, CX
ENDIF

;end inlined FixedMulBSPLocal_


SELFMODIFY_sub__centeryfrac_shiftright4_lo_4:
mov       cx, 01000h
sub       cx, ax
SELFMODIFY_sub__centeryfrac_shiftright4_hi_4:
mov       ax, 01000h
sbb       ax, dx
mov       word ptr [bp - 02Eh], cx
mov       word ptr [bp - 02Ch], ax
; les to load two words
les       ax, dword ptr [bp - 044h]
mov       dx, es
sar       dx, 1
rcr       ax, 1
sar       dx, 1
rcr       ax, 1
sar       dx, 1
rcr       ax, 1
sar       dx, 1
rcr       ax, 1

mov       word ptr [bp - 042h], dx
mov       word ptr [bp - 044h], ax



les       bx, dword ptr [bp - 032h]
mov       cx, es

;start inlined FixedMulBSPLocal_

IF COMPISA GE COMPILE_386

   ; set up ecx
   db 066h, 0C1h, 0E3h, 010h        ; shl  ebx, 0x10
   db 066h, 00Fh, 0A4h, 0D9h, 010h  ; shld ecx, ebx, 0x10

   ; set up eax
   db 066h, 0C1h, 0E0h, 010h        ; shl  eax, 0x10
   db 066h, 00Fh, 0ACh, 0D0h, 010h  ; shrd eax, edx, 0x10

   ; actual mul
   db 066h, 0F7h, 0E9h              ; imul ecx
   ; set up return
   db 066h, 0C1h, 0E8h, 010h        ; shr  eax, 0x10


ELSE
   mov   es, ax	; store ax in es
   mov   ds, dx    ; store dx in ds
   mov   ax, dx	; ax holds dx
   CWD				; S0 in DX

   AND   DX, BX	; S0*BX
   NEG   DX
   mov   SI, DX	; DI stores hi word return

   ; AX still stores DX
   MUL  CX         ; DX*CX
   add  SI, AX    ; low word result into high word return

   mov  AX, DS    ; restore DX from ds
   MUL  BX         ; DX*BX
   XCHG BX, AX    ; BX will hold low word return. store bx in ax
   add  SI, DX    ; add high word to result

   mov  DX, ES    ; restore AX from ES
   mul  DX        ; BX*AX  
   add  BX, DX    ; high word result into low word return
   ADC  SI, 0

   mov  AX, CX   ; AX holds CX
   CWD           ; S1 in DX

   mov  CX, ES   ; AX from ES
   AND  DX, CX   ; S1*AX
   NEG  DX
   ADD  SI, DX   ; result into high word return

   MUL  CX       ; AX*CX

   ADD  AX, BX	  ; set up final return value
   ADC  DX, SI

   mov  CX, SS   ; restore DS
   mov  DS, CX
ENDIF

;end inlined FixedMulBSPLocal_


SELFMODIFY_sub__centeryfrac_shiftright4_lo_3:
mov       cx, 01000h
sub       cx, ax
SELFMODIFY_sub__centeryfrac_shiftright4_hi_3:
mov       ax, 01000h
sbb       ax, dx
mov       word ptr [bp - 02Ah], cx
mov       word ptr [bp - 028h], ax

cmp       byte ptr [bp - 01Bh], 0  ;markceiling
je        dont_mark_ceiling
mov       cx, 1
SELFMODIFY_set_ceilingplaneindex:
mov       ax, 0FFFFh
les       bx, dword ptr [bp - 01Ah]
mov       dx, es
dec       bx
call      R_CheckPlane_
mov       word ptr cs:[SELFMODIFY_set_ceilingplaneindex+1], ax
dont_mark_ceiling:

cmp       byte ptr [bp - 01Ch], 0 ; markfloor
je        dont_mark_floor
xor       cx, cx
SELFMODIFY_set_floorplaneindex:
mov       ax, 0FFFFh
les       bx, dword ptr [bp - 01Ah]
mov       dx, es
dec       bx
call      R_CheckPlane_
mov       word ptr cs:[SELFMODIFY_set_floorplaneindex+1], ax
dont_mark_floor:
mov       ax, word ptr [bp - 4]
cmp       ax, word ptr [bp - 2]
jge       at_least_one_column_to_draw
jmp       check_spr_top_clip
at_least_one_column_to_draw:

; todo better use DS as a scratch var for mults etc ahead.

ASSUME DS:R_BSP_TEXT
; make ds equal to cs for self modifying codes
mov       ax, cs
mov       ds, ax


SELFMODIFY_get_rwscalestep_lo_1:
mov       ax, 01000h
SELFMODIFY_get_rwscalestep_hi_1:
mov       dx, 01000h
les       bx, dword ptr [bp - 040h]
mov       cx, es

;start inlined FixedMulBSPLocal_


IF COMPISA GE COMPILE_386

   ; set up ecx
   db 066h, 0C1h, 0E3h, 010h        ; shl  ebx, 0x10
   db 066h, 00Fh, 0A4h, 0D9h, 010h  ; shld ecx, ebx, 0x10

   ; set up eax
   db 066h, 0C1h, 0E0h, 010h        ; shl  eax, 0x10
   db 066h, 00Fh, 0ACh, 0D0h, 010h  ; shrd eax, edx, 0x10

   ; actual mul
   db 066h, 0F7h, 0E9h              ; imul ecx
   ; set up return
   db 066h, 0C1h, 0E8h, 010h        ; shr  eax, 0x10


ELSE

   mov   es, ax	; store ax in es
   push  dx       ; store dx in stack
   mov   ax, dx	; ax holds dx
   CWD				; S0 in DX

   AND   DX, BX	; S0*BX
   NEG   DX
   mov   SI, DX	; DI stores hi word return

   ; AX still stores DX
   MUL  CX        ; DX*CX
   add  SI, AX    ; low word result into high word return

   pop  AX        ; restore old DX from stack
   MUL  BX        ; DX*BX
   XCHG BX, AX    ; BX will hold low word return. store bx in ax
   add  SI, DX    ; add high word to result

   mov  DX, ES    ; restore AX from ES
   mul  DX        ; BX*AX  
   add  BX, DX    ; high word result into low word return
   ADC  SI, 0

   mov  AX, CX   ; AX holds CX
   CWD           ; S1 in DX

   mov  CX, ES   ; AX from ES
   AND  DX, CX   ; S1*AX
   NEG  DX
   ADD  SI, DX   ; result into high word return

   MUL  CX       ; AX*CX

   ADD  AX, BX	  ; set up final return value
   ADC  DX, SI

ENDIF

;end inlined FixedMulBSPLocal_

neg       dx
neg       ax
sbb       dx, 0

; dx:ax are topstep

mov       word ptr ds:[SELFMODIFY_sub_topstep_lo+3], ax
mov       word ptr ds:[SELFMODIFY_add_topstep_lo+4], ax
xchg      ax, dx
mov       word ptr ds:[SELFMODIFY_sub_topstep_hi+3], ax
mov       word ptr ds:[SELFMODIFY_add_topstep_hi+4], ax


SELFMODIFY_BSP_detailshift_2:
shl       dx, 1
rcl       ax, 1
shift_topstep_once:
shl       dx, 1
rcl       ax, 1

finished_shifting_topstep:

mov       word ptr ds:[SELFMODIFY_add_to_topfrac_hi_1+3], ax
mov       word ptr ds:[SELFMODIFY_add_to_topfrac_hi_2+3], ax
xchg      ax, dx
mov       word ptr ds:[SELFMODIFY_add_to_topfrac_lo_1+3], ax
mov       word ptr ds:[SELFMODIFY_add_to_topfrac_lo_2+3], ax


les       bx, dword ptr [bp - 044h]
mov       cx, es
SELFMODIFY_get_rwscalestep_lo_2:
mov       ax, 01000h
SELFMODIFY_get_rwscalestep_hi_2:
mov       dx, 01000h

;start inlined FixedMulBSPLocal_

IF COMPISA GE COMPILE_386

   ; set up ecx
   db 066h, 0C1h, 0E3h, 010h        ; shl  ebx, 0x10
   db 066h, 00Fh, 0A4h, 0D9h, 010h  ; shld ecx, ebx, 0x10

   ; set up eax
   db 066h, 0C1h, 0E0h, 010h        ; shl  eax, 0x10
   db 066h, 00Fh, 0ACh, 0D0h, 010h  ; shrd eax, edx, 0x10

   ; actual mul
   db 066h, 0F7h, 0E9h              ; imul ecx
   ; set up return
   db 066h, 0C1h, 0E8h, 010h        ; shr  eax, 0x10


ELSE

   mov   es, ax	; store ax in es
   push  dx       ; store dx in stack
   mov   ax, dx	; ax holds dx
   CWD				; S0 in DX

   AND   DX, BX	; S0*BX
   NEG   DX
   mov   SI, DX	; DI stores hi word return

   ; AX still stores DX
   MUL  CX        ; DX*CX
   add  SI, AX    ; low word result into high word return

   pop  AX        ; restore old DX from stack
   MUL  BX        ; DX*BX
   XCHG BX, AX    ; BX will hold low word return. store bx in ax
   add  SI, DX    ; add high word to result

   mov  DX, ES    ; restore AX from ES
   mul  DX        ; BX*AX  
   add  BX, DX    ; high word result into low word return
   ADC  SI, 0

   mov  AX, CX   ; AX holds CX
   CWD           ; S1 in DX

   mov  CX, ES   ; AX from ES
   AND  DX, CX   ; S1*AX
   NEG  DX
   ADD  SI, DX   ; result into high word return

   MUL  CX       ; AX*CX

   ADD  AX, BX	  ; set up final return value
   ADC  DX, SI

   pop  si       ; restore si after these several mults
ENDIF

;end inlined FixedMulBSPLocal_

neg       dx
neg       ax
sbb       dx, 0

; dx:ax are bottomstep

mov       word ptr ds:[SELFMODIFY_sub_botstep_lo+3], ax
mov       word ptr ds:[SELFMODIFY_add_botstep_lo+4], ax
xchg      ax, dx
mov       word ptr ds:[SELFMODIFY_sub_botstep_hi+3], ax
mov       word ptr ds:[SELFMODIFY_add_botstep_hi+4], ax

SELFMODIFY_BSP_detailshift_3:
shl       dx, 1
rcl       ax, 1
shift_botstep_once:
shl       dx, 1
rcl       ax, 1

finished_shifting_botstep:

mov       word ptr ds:[SELFMODIFY_add_to_bottomfrac_hi_1+3], ax
mov       word ptr ds:[SELFMODIFY_add_to_bottomfrac_hi_2+3], ax
xchg      ax, dx
mov       word ptr ds:[SELFMODIFY_add_to_bottomfrac_lo_1+3], ax
mov       word ptr ds:[SELFMODIFY_add_to_bottomfrac_lo_2+3], ax




cmp       word ptr ss:[_backsector], SECNUM_NULL
jne       backsector_not_null
jmp       skip_pixlow_step
jmp_to_skip_pixhigh_step:
jmp skip_pixhigh_step
backsector_not_null:
; here we modify worldhigh/low then do not write them back to memory
; (except push/pop in one situation)

; worldhigh.w >>= 4;
; worldlow.w >>= 4;


; worldlow is di:si
sar       di, 1
rcr       si, 1
sar       di, 1
rcr       si, 1
sar       di, 1
rcr       si, 1
sar       di, 1
rcr       si, 1

; worldlow to dx:ax
mov       dx, di
xchg      ax, si

pop       si
pop       di

; worldhi to di:si
sar       di, 1
rcr       si, 1
sar       di, 1
rcr       si, 1
sar       di, 1
rcr       si, 1
sar       di, 1
rcr       si, 1


; if (worldhigh.w < worldtop.w) {

cmp       word ptr [bp - 03Eh], di
jg        do_pixhigh_step
jne       jmp_to_skip_pixhigh_step
cmp       word ptr [bp - 040h], si

jbe       jmp_to_skip_pixhigh_step
do_pixhigh_step:

; pixhigh = (centeryfrac_shiftright4.w) - FixedMul (worldhigh.w, rw_scale.w);
; pixhighstep = -FixedMul    (rw_scalestep.w,          worldhigh.w);

; store these
xchg       dx, di
xchg       ax, si

les       bx, dword ptr [bp - 032h]
mov       cx, es
push      dx
push      ax

;start inlined FixedMulBSPLocal_

IF COMPISA GE COMPILE_386

   ; set up ecx
   db 066h, 0C1h, 0E3h, 010h        ; shl  ebx, 0x10
   db 066h, 00Fh, 0A4h, 0D9h, 010h  ; shld ecx, ebx, 0x10

   ; set up eax
   db 066h, 0C1h, 0E0h, 010h        ; shl  eax, 0x10
   db 066h, 00Fh, 0ACh, 0D0h, 010h  ; shrd eax, edx, 0x10

   ; actual mul
   db 066h, 0F7h, 0E9h              ; imul ecx
   ; set up return
   db 066h, 0C1h, 0E8h, 010h        ; shr  eax, 0x10


ELSE

   push  si

   mov   es, ax	; store ax in es
   push  dx       ; store dx in stack
   mov   ax, dx	; ax holds dx
   CWD				; S0 in DX

   AND   DX, BX	; S0*BX
   NEG   DX
   mov   SI, DX	; DI stores hi word return

   ; AX still stores DX
   MUL  CX         ; DX*CX
   add  SI, AX     ; low word result into high word return

   pop  AX        ; restore old DX from stack
   MUL  BX        ; DX*BX
   XCHG BX, AX    ; BX will hold low word return. store bx in ax
   add  SI, DX    ; add high word to result

   mov  DX, ES    ; restore AX from ES
   mul  DX        ; BX*AX  
   add  BX, DX    ; high word result into low word return
   ADC  SI, 0

   mov  AX, CX   ; AX holds CX
   CWD           ; S1 in DX

   mov  CX, ES   ; AX from ES
   AND  DX, CX   ; S1*AX
   NEG  DX
   ADD  SI, DX   ; result into high word return

   MUL  CX       ; AX*CX

   ADD  AX, BX	  ; set up final return value
   ADC  DX, SI

   
   pop   si

ENDIF

;end inlined FixedMulBSPLocal_


; mov cx, low word
; mov bx, high word
SELFMODIFY_sub__centeryfrac_shiftright4_lo_2:
mov       cx, 01000h
sub       cx, ax
SELFMODIFY_sub__centeryfrac_shiftright4_hi_2:
mov       ax, 01000h
sbb       ax, dx


mov       word ptr [bp - 022h], cx
mov       word ptr [bp - 020h], ax
pop       bx
pop       cx
SELFMODIFY_get_rwscalestep_lo_3:
mov       ax, 01000h
SELFMODIFY_get_rwscalestep_hi_3:
mov       dx, 01000h

;start inlined FixedMulBSPLocal_


IF COMPISA GE COMPILE_386

   ; set up ecx
   db 066h, 0C1h, 0E3h, 010h        ; shl  ebx, 0x10
   db 066h, 00Fh, 0A4h, 0D9h, 010h  ; shld ecx, ebx, 0x10

   ; set up eax
   db 066h, 0C1h, 0E0h, 010h        ; shl  eax, 0x10
   db 066h, 00Fh, 0ACh, 0D0h, 010h  ; shrd eax, edx, 0x10

   ; actual mul
   db 066h, 0F7h, 0E9h              ; imul ecx
   ; set up return
   db 066h, 0C1h, 0E8h, 010h        ; shr  eax, 0x10


ELSE
   push  si

   mov   es, ax	; store ax in es
   push  dx       ; store dx in stack
   mov   ax, dx	; ax holds dx
   CWD				; S0 in DX

   AND   DX, BX	; S0*BX
   NEG   DX
   mov   SI, DX	; DI stores hi word return

   ; AX still stores DX
   MUL  CX        ; DX*CX
   add  SI, AX    ; low word result into high word return

   pop  AX        ; restore DX from stack
   MUL  BX        ; DX*BX
   XCHG BX, AX    ; BX will hold low word return. store bx in ax
   add  SI, DX    ; add high word to result

   mov  DX, ES    ; restore AX from ES
   mul  DX        ; BX*AX  
   add  BX, DX    ; high word result into low word return
   ADC  SI, 0

   mov  AX, CX   ; AX holds CX
   CWD           ; S1 in DX

   mov  CX, ES   ; AX from ES
   AND  DX, CX   ; S1*AX
   NEG  DX
   ADD  SI, DX   ; result into high word return

   MUL  CX       ; AX*CX

   ADD  AX, BX	  ; set up final return value
   ADC  DX, SI


   pop   si
ENDIF

;end inlined FixedMulBSPLocal_


neg       dx
neg       ax
sbb       dx, 0


; dx:ax is pixhighstep.
; self modifying code to write to pixlowstep usages.


mov       word ptr ds:[SELFMODIFY_sub_pixhigh_lo+3], ax
mov       word ptr ds:[SELFMODIFY_add_pixhighstep_lo+4], ax
xchg      ax, dx
mov       word ptr ds:[SELFMODIFY_sub_pixhigh_hi+3], ax
mov       word ptr ds:[SELFMODIFY_add_pixhighstep_hi+4], ax

SELFMODIFY_BSP_detailshift_4:
shl       dx, 1
rcl       ax, 1
shift_pixhighstep_once:
shl       dx, 1
rcl       ax, 1
done_shifting_pixhighstep:
mov       word ptr ds:[SELFMODIFY_add_to_pixhigh_hi_1+3], ax
mov       word ptr ds:[SELFMODIFY_add_to_pixhigh_hi_2+3], ax
xchg      ax, dx
mov       word ptr ds:[SELFMODIFY_add_to_pixhigh_lo_1+3], ax
mov       word ptr ds:[SELFMODIFY_add_to_pixhigh_lo_2+3], ax


; put these back where they need to be.
xchg      dx, di
xchg      ax, si
skip_pixhigh_step:

; dx:ax are now worldlow

; if (worldlow.w > worldbottom.w) {

cmp       dx, word ptr [bp - 042h]
jg        do_pixlow_step
jne       jmp_to_skip_pixlow_step
cmp       ax, word ptr [bp - 044h]
ja        do_pixlow_step

jmp_to_skip_pixlow_step:
jmp       skip_pixlow_step
do_pixlow_step:

; pixlow = (centeryfrac_shiftright4.w) - FixedMul (worldlow.w, rw_scale.w);
; pixlowstep = -FixedMul    (rw_scalestep.w,          worldlow.w);


mov       di, dx	; store for later
mov       si, ax	; store for later
les       bx, dword ptr [bp - 032h]
mov       cx, es

;start inlined FixedMulBSPLocal_

IF COMPISA GE COMPILE_386

   ; set up ecx
   db 066h, 0C1h, 0E3h, 010h        ; shl  ebx, 0x10
   db 066h, 00Fh, 0A4h, 0D9h, 010h  ; shld ecx, ebx, 0x10

   ; set up eax
   db 066h, 0C1h, 0E0h, 010h        ; shl  eax, 0x10
   db 066h, 00Fh, 0ACh, 0D0h, 010h  ; shrd eax, edx, 0x10

   ; actual mul
   db 066h, 0F7h, 0E9h              ; imul ecx
   ; set up return
   db 066h, 0C1h, 0E8h, 010h        ; shr  eax, 0x10


ELSE

   push  si

   mov   es, ax	; store ax in es
   push  dx       ; store dx in stack
   mov   ax, dx	; ax holds dx
   CWD				; S0 in DX

   AND   DX, BX	; S0*BX
   NEG   DX
   mov   SI, DX	; DI stores hi word return

   ; AX still stores DX
   MUL  CX        ; DX*CX
   add  SI, AX    ; low word result into high word return

   pop  AX        ; restore old DX from stack
   MUL  BX        ; DX*BX
   XCHG BX, AX    ; BX will hold low word return. store bx in ax
   add  SI, DX    ; add high word to result

   mov  DX, ES    ; restore AX from ES
   mul  DX        ; BX*AX  
   add  BX, DX    ; high word result into low word return
   ADC  SI, 0

   mov  AX, CX   ; AX holds CX
   CWD           ; S1 in DX

   mov  CX, ES   ; AX from ES
   AND  DX, CX   ; S1*AX
   NEG  DX
   ADD  SI, DX   ; result into high word return

   MUL  CX       ; AX*CX

   ADD  AX, BX	  ; set up final return value
   ADC  DX, SI


   pop   si

ENDIF

;end inlined FixedMulBSPLocal_


SELFMODIFY_sub__centeryfrac_shiftright4_lo_1:
mov       cx, 01000h
sub       cx, ax
SELFMODIFY_sub__centeryfrac_shiftright4_hi_1:
mov       ax, 01000h
sbb       ax, dx


mov       word ptr [bp - 026h], cx
mov       word ptr [bp - 024h], ax
SELFMODIFY_get_rwscalestep_lo_4:
mov       ax, 01000h
SELFMODIFY_get_rwscalestep_hi_4:
mov       dx, 01000h

;start inlined FixedMulBSPLocal_

IF COMPISA GE COMPILE_386

mov       cx, di	; cached values
mov       bx, si	; cached values

   ; set up ecx
   db 066h, 0C1h, 0E3h, 010h        ; shl  ebx, 0x10
   db 066h, 00Fh, 0A4h, 0D9h, 010h  ; shld ecx, ebx, 0x10

   ; set up eax
   db 066h, 0C1h, 0E0h, 010h        ; shl  eax, 0x10
   db 066h, 00Fh, 0ACh, 0D0h, 010h  ; shrd eax, edx, 0x10

   ; actual mul
   db 066h, 0F7h, 0E9h              ; imul ecx
   ; set up return
   db 066h, 0C1h, 0E8h, 010h        ; shr  eax, 0x10


ELSE

   xchg  ax, cx	; store ax in cx
   mov   es, dx   ; store dx in es
   xchg  ax, dx	; ax holds dx
   CWD				; S0 in DX

   AND   DX, SI	; S0*BX   ; si has bx's value
   NEG   DX
   mov   BX, DX   ; stores hi word return

   ; AX still stores DX
   MUL  DI        ; DX*CX  ; di has cx's value
   add  BX, AX    ; low word result into high word return

   mov  AX, ES    ; restore old DX from stack
   MUL  SI        ; DX*BX   ; si has bx's value
   XCHG SI, AX    ; BX will hold low word return. store bx in ax
   add  BX, DX    ; add high word to result

   mul  CX        ; BX*AX   ; cx has original ax
   add  SI, DX    ; high word result into low word return
   ADC  BX, 0

   mov  AX, DI   ; AX holds CX  ; di has cx's value
   CWD           ; S1 in DX

   AND  DX, CX   ; S1*AX   ; cx has old ax
   NEG  DX
   ADD  BX, DX   ; result into high word return

   MUL  CX       ; AX*CX

   ADD  AX, SI	  ; set up final return value
   ADC  DX, BX


ENDIF

;end inlined FixedMulBSPLocal_

neg       dx
neg       ax
sbb       dx, 0

; dx:ax is pixlowstep.
; self modifying code to write to pixlowstep usages.


mov       word ptr ds:[SELFMODIFY_sub_pixlow_lo+3], ax
mov       word ptr ds:[SELFMODIFY_add_pixlowstep_lo+4], ax
xchg      ax, dx
mov       word ptr ds:[SELFMODIFY_sub_pixlow_hi+3], ax
mov       word ptr ds:[SELFMODIFY_add_pixlowstep_hi+4], ax

SELFMODIFY_BSP_detailshift_5:
shl       dx, 1
rcl       ax, 1
shift_pixlowstep_once:
shl       dx, 1
rcl       ax, 1
done_shifting_pixlowstep:
mov       word ptr ds:[SELFMODIFY_add_to_pixlow_hi_1+3], ax
mov       word ptr ds:[SELFMODIFY_add_to_pixlow_hi_2+3], ax
xchg      ax, dx
mov       word ptr ds:[SELFMODIFY_add_to_pixlow_lo_1+3], ax
mov       word ptr ds:[SELFMODIFY_add_to_pixlow_lo_2+3], ax



skip_pixlow_step:


;   BEGIN INLINED R_RenderSegLoop_
;   BEGIN INLINED R_RenderSegLoop_
;   BEGIN INLINED R_RenderSegLoop_
;   BEGIN INLINED R_RenderSegLoop_



xchg  ax, cx
mov   bx, word ptr [bp - 018h]    ; rw_x
mov   di, bx
SELFMODIFY_detailshift_and_1:

and   bx, 01000h
mov   word ptr ds:[SELFMODIFY_add_rw_x_base4_to_ax+1], bx
mov   word ptr ds:[SELFMODIFY_compare_ax_to_start_rw_x+1], di

; self modify code in the function to set constants rather than
; repeatedly reading loop-constant or function-constant variables.

mov   byte ptr ds:[SELFMODIFY_set_al_to_xoffset+1], 0



mov   ax, word ptr [bp - 01Ah]
mov   word ptr ds:[SELFMODIFY_cmp_di_to_rw_stopx_1+1], ax
mov   word ptr ds:[SELFMODIFY_cmp_di_to_rw_stopx_2+1], ax
mov   word ptr ds:[SELFMODIFY_cmp_di_to_rw_stopx_3+1], ax


cmp   byte ptr [bp - 01Ch], 0 ;markfloor

je    do_markfloor_selfmodify_jumps
mov   ax, 04940h     ; inc ax dec cx
mov   si, 02647h     ; inc di, es:
jmp do_markfloor_selfmodify
do_markfloor_selfmodify_jumps:
mov   ax, ((SELFMODIFY_BSP_markfloor_1_TARGET - SELFMODIFY_BSP_markfloor_1_AFTER) SHL 8) + 0EBh
mov   si, ((SELFMODIFY_BSP_markfloor_2_TARGET - SELFMODIFY_BSP_markfloor_2_AFTER) SHL 8) + 0EBh
do_markfloor_selfmodify:

mov   word ptr ds:[SELFMODIFY_BSP_markfloor_1], ax
mov   word ptr ds:[SELFMODIFY_BSP_markfloor_2], si

mov   ah, byte ptr [bp - 01Bh] ;markceiling
cmp   ah, 0   

je    do_markceiling_selfmodify_jumps
mov   al, 0B2h  ;      mov dl, [ah value]
;mov   si, 0448Dh     ; lea   ax, [si - 1]
mov   si, 0c089h    ; nop

jmp do_markceiling_selfmodify
do_markceiling_selfmodify_jumps:
mov   ax, ((SELFMODIFY_BSP_markceiling_1_TARGET - SELFMODIFY_BSP_markceiling_1_AFTER) SHL 8) + 0EBh
mov   si, ((SELFMODIFY_BSP_markceiling_2_TARGET - SELFMODIFY_BSP_markceiling_2_AFTER) SHL 8) + 0EBh
do_markceiling_selfmodify:

mov   word ptr ds:[SELFMODIFY_BSP_markceiling_1], ax
mov   word ptr ds:[SELFMODIFY_BSP_markceiling_2], si

xchg  ax, cx



;  	int16_t base4diff = rw_x - rw_x_base4;
mov   cx, di

sub   cx, bx

;	while (base4diff){
;		rw_scale.w      -= rw_scalestep;
;		topfrac         -= topstep;
;		bottomfrac      -= bottomstep;
;		pixlow		    -= pixlowstep;
;		pixhigh		    -= pixhighstep;
;		base4diff--;
;	}
je    skip_sub_base4diff
SELFMODIFY_BSP_midtextureonly_skip_pixhighlow_4_TARGET:
sub_base4diff:


SELFMODIFY_sub_rwscale_lo:
sub   word ptr [bp - 032h], 01000h
SELFMODIFY_sub_rwscale_hi:
sbb   word ptr [bp - 030h], 01000h
SELFMODIFY_sub_topstep_lo:
sub   word ptr [bp - 02Eh], 01000h
SELFMODIFY_sub_topstep_hi:
sbb   word ptr [bp - 02Ch], 01000h
SELFMODIFY_sub_botstep_lo:
sub   word ptr [bp - 02Ah], 01000h
SELFMODIFY_sub_botstep_hi:
sbb   word ptr [bp - 028h], 01000h

; THIS IS COMPLICATED because of the fall through after loop. 
; could do a 2nd modded instruction worth jump? is that worth it?
; i dont really think so.
SELFMODIFY_BSP_midtextureonly_skip_pixhighlow_4:
; loop SELFMODIFY_BSP_midtextureonly_skip_pixhighlow_4_TARGET
; todo: why does this equal +1 instead of +2???
SELFMODIFY_BSP_midtextureonly_skip_pixhighlow_4_AFTER = SELFMODIFY_BSP_midtextureonly_skip_pixhighlow_4 + 2
SELFMODIFY_sub_pixlow_lo:
sub   word ptr [bp - 026h], 01000h
SELFMODIFY_sub_pixlow_hi:
sbb   word ptr [bp - 024h], 01000h
SELFMODIFY_sub_pixhigh_lo:
sub   word ptr [bp - 022h], 01000h
SELFMODIFY_sub_pixhigh_hi:
sbb   word ptr [bp - 020h], 01000h

loop   sub_base4diff
skip_sub_base4diff:

;	base_rw_scale   = rw_scale.w;
;	base_topfrac    = topfrac;
;	base_bottomfrac = bottomfrac;
;	base_pixlow     = pixlow;
;	base_pixhigh    = pixhigh;


lea   si, [bp - 032h]


lods  word ptr ss:[si]
mov   word ptr ds:[SELFMODIFY_set_rw_scale_lo+1], ax
lods  word ptr ss:[si]
mov   word ptr ds:[SELFMODIFY_set_rw_scale_hi+1], ax
lods  word ptr ss:[si] ; topfrac lo
mov   word ptr ds:[SELFMODIFY_set_topfrac_lo+1], ax
lods  word ptr ss:[si] ; topfrac hi
mov   word ptr ds:[SELFMODIFY_set_topfrac_hi+1], ax
lods  word ptr ss:[si] ; bottomfrac lo
mov   word ptr ds:[SELFMODIFY_set_botfrac_lo+1], ax
lods  word ptr ss:[si] ; bottomfrac hi
mov   word ptr ds:[SELFMODIFY_set_botfrac_hi+1], ax
SELFMODIFY_BSP_midtextureonly_skip_pixhighlow_3:
jmp SELFMODIFY_BSP_midtextureonly_skip_pixhighlow_3_TARGET
SELFMODIFY_BSP_midtextureonly_skip_pixhighlow_3_AFTER = SELFMODIFY_BSP_midtextureonly_skip_pixhighlow_3 + 2
lods  word ptr ss:[si] ; pixlow lo
mov   word ptr ds:[SELFMODIFY_set_pixlow_lo+1], ax
lods  word ptr ss:[si] ; pixlow hi
mov   word ptr ds:[SELFMODIFY_set_pixlow_hi+1], ax
lods  word ptr ss:[si] ; pixhigh lo
mov   word ptr ds:[SELFMODIFY_set_pixhigh_lo+1], ax
lods  word ptr ss:[si] ; pixhigh hi
mov   word ptr ds:[SELFMODIFY_set_pixhigh_hi+1], ax

SELFMODIFY_BSP_midtextureonly_skip_pixhighlow_3_TARGET:
mov   al, 0 ; xoffset is 0
mov   dx, SC_DATA  ; cheat this out of the loop..


continue_outer_rendersegloop:

SELFMODIFY_BSP_midtextureonly_skip_pixhighlow_2_TARGET:
cbw  
xchg  ax, bx	; xoffset to bx

inc   byte ptr ds:[SELFMODIFY_set_al_to_xoffset+1]

SELFMODIFY_detailshift_plus1_1:
mov   al, byte ptr ss:[bx + OFFSET _quality_port_lookup]	
out   dx, al

; pre inner loop.
; reset everything to base;


; topfrac    = base_topfrac;
; bottomfrac = base_bottomfrac;
; rw_scale.w = base_rw_scale;
; pixlow     = base_pixlow;
; pixhigh    = base_pixhigh;

mov   dx, ss
mov   es, dx
lea   di, [bp - 032h]

SELFMODIFY_set_rw_scale_lo:
mov   ax, 01000h
stosw
SELFMODIFY_set_rw_scale_hi:
mov   ax, 01000h
stosw
SELFMODIFY_set_topfrac_lo:
mov   ax, 01000h
stosw
SELFMODIFY_set_topfrac_hi:
mov   ax, 01000h
stosw
SELFMODIFY_set_botfrac_lo:
mov   ax, 01000h
stosw
SELFMODIFY_set_botfrac_hi:
mov   ax, 01000h
stosw

SELFMODIFY_BSP_midtextureonly_skip_pixhighlow_5:
jmp   SELFMODIFY_BSP_midtextureonly_skip_pixhighlow_5_TARGET
SELFMODIFY_BSP_midtextureonly_skip_pixhighlow_5_AFTER = SELFMODIFY_BSP_midtextureonly_skip_pixhighlow_5 + 2

SELFMODIFY_set_pixlow_lo:
mov   ax, 01000h
stosw
SELFMODIFY_set_pixlow_hi:
mov   ax, 01000h
stosw
SELFMODIFY_set_pixhigh_lo:
mov   ax, 01000h
stosw
SELFMODIFY_set_pixhigh_hi:
mov   ax, 01000h
stosw

SELFMODIFY_BSP_midtextureonly_skip_pixhighlow_5_TARGET:
xchg  ax, bx	; get xoffset  back
SELFMODIFY_add_rw_x_base4_to_ax:
add   ax, 1000h
mov   word ptr [bp - 018h], ax    ; rw_x
SELFMODIFY_compare_ax_to_start_rw_x:
cmp   ax, 1000h
jl    pre_increment_values

SELFMODIFY_cmp_di_to_rw_stopx_3:
cmp   ax, 01000h   ; cmp   di, word ptr [bp - 01Ah]
jl    jump_to_start_per_column_inner_loop  ; 026hish out of range

finish_outer_loop:
; self modifying code for step values.



; xoffset++,
; base_topfrac    += topstep, 
; base_bottomfrac += bottomstep, 
; base_rw_scale   += rw_scalestep,
; base_pixlow	  += pixlowstep,
; base_pixhigh    += pixhighstep

check_outer_loop_conditions:

SELFMODIFY_set_al_to_xoffset:
mov   al, 0
SELFMODIFY_cmp_al_to_detailshiftitercount:
cmp   al, 0

jge   exit_rendersegloop ; exit before adding the other loop vars.
SELFMODIFY_add_topstep_lo:
add   word ptr ds:[SELFMODIFY_set_topfrac_lo+1], 01000h
SELFMODIFY_add_topstep_hi:
adc   word ptr ds:[SELFMODIFY_set_topfrac_hi+1], 01000h

SELFMODIFY_add_botstep_lo:
add   word ptr ds:[SELFMODIFY_set_botfrac_lo+1], 01000h
SELFMODIFY_add_botstep_hi:
adc   word ptr ds:[SELFMODIFY_set_botfrac_hi+1], 01000h

SELFMODIFY_add_rwscale_lo:
add   word ptr ds:[SELFMODIFY_set_rw_scale_lo+1], 01000h
SELFMODIFY_add_rwscale_hi:
adc   word ptr ds:[SELFMODIFY_set_rw_scale_hi+1], 01000h

SELFMODIFY_BSP_midtextureonly_skip_pixhighlow_2:
jmp SHORT   SELFMODIFY_BSP_midtextureonly_skip_pixhighlow_2_TARGET
SELFMODIFY_BSP_midtextureonly_skip_pixhighlow_2_AFTER = SELFMODIFY_BSP_midtextureonly_skip_pixhighlow_2 + 2

SELFMODIFY_add_pixlowstep_lo:
add   word ptr ds:[SELFMODIFY_set_pixlow_lo+1], 01000h
SELFMODIFY_add_pixlowstep_hi:
adc   word ptr ds:[SELFMODIFY_set_pixlow_hi+1], 01000h

SELFMODIFY_add_pixhighstep_lo:
add   word ptr ds:[SELFMODIFY_set_pixhigh_lo+1], 01000h
SELFMODIFY_add_pixhighstep_hi:
adc   word ptr ds:[SELFMODIFY_set_pixhigh_hi+1], 01000h


jmp   continue_outer_rendersegloop


exit_rendersegloop:
; zero out local caches.

ASSUME DS:DGROUP
mov   ax, ss
mov   ds, ax
mov   es, ax
mov   ax, 0FFFFh
mov   di, OFFSET _segloopnextlookup
stosw ; mov   word ptr ds:[_segloopnextlookup], ax
stosw ; mov   word ptr ds:[_segloopnextlookup+2], ax
inc   ax
; zero both 
stosw ; mov   word ptr ds:[_seglooptexrepeat], ax


jmp   R_RenderSegLoop_exit   



jump_to_start_per_column_inner_loop:
jmp   start_per_column_inner_loop
jump_to_finish_outer_loop_2:
mov   dx, SC_DATA  ; cheat this out of the loop..
jmp   finish_outer_loop
pre_increment_values:


;		rw_x = rw_x_base4 + xoffset;
;		if (rw_x < start_rw_x){
;			rw_x       += detailshiftitercount;
;			topfrac    += topstepshift;
;			bottomfrac += bottomstepshift;
;			rw_scale.w += rwscaleshift;
;			pixlow     += pixlowstepshift;
;			pixhigh    += pixhighstepshift;
;		}


SELFMODIFY_add_iter_to_rw_x:
; ax was already up-to-date rw_x
add   ax, 1
mov   word ptr [bp - 018h], ax     ; rw_x
SELFMODIFY_add_to_rwscale_lo_2:
add   word ptr [bp - 032h], 01000h
SELFMODIFY_add_to_rwscale_hi_2:
adc   word ptr [bp - 030h], 01000h
SELFMODIFY_add_to_topfrac_lo_2:
add   word ptr [bp - 02Eh], 01000h
SELFMODIFY_add_to_topfrac_hi_2:
adc   word ptr [bp - 02Ch], 01000h
SELFMODIFY_add_to_bottomfrac_lo_2:
add   word ptr [bp - 02Ah], 01000h
SELFMODIFY_add_to_bottomfrac_hi_2:
adc   word ptr [bp - 028h], 01000h

SELFMODIFY_BSP_midtextureonly_skip_pixhighlow_1:
jmp SHORT SELFMODIFY_BSP_midtextureonly_skip_pixhighlow_1_TARGET
SELFMODIFY_BSP_midtextureonly_skip_pixhighlow_1_AFTER = SELFMODIFY_BSP_midtextureonly_skip_pixhighlow_1 + 2
SELFMODIFY_add_to_pixlow_lo_2:
add   word ptr [bp - 026h], 01000h
SELFMODIFY_add_to_pixlow_hi_2:
adc   word ptr [bp - 024h], 01000h
SELFMODIFY_add_to_pixhigh_lo_2:
add   word ptr [bp - 022h], 01000h
SELFMODIFY_add_to_pixhigh_hi_2:
adc   word ptr [bp - 020h], 01000h

SELFMODIFY_BSP_midtextureonly_skip_pixhighlow_1_TARGET:
; this is right before inner loop start
SELFMODIFY_cmp_di_to_rw_stopx_1:
cmp   ax, 01000h   ; cmp   ax, word ptr [bp - 01Ah]
jge   jump_to_finish_outer_loop_2

start_per_column_inner_loop:
; ax was rw_x
; now di is rw_x


xchg  ax, di   ; ax was still rw_x
; NOTE DS IS BAD HERE (cs)
mov   ax, ss
mov   ds, ax

mov   ax, OPENINGS_SEGMENT
mov   es, ax
mov   bx, di                                     ; di = rw_x
mov   cx, word ptr es:[bx+di+OFFSET_FLOORCLIP]	 ; cx = floor
mov   si, word ptr es:[bx+di+OFFSET_CEILINGCLIP] ; dx = ceiling
inc   si

mov   ax, word ptr [bp - 02Eh]
add   ax, ((HEIGHTUNIT)-1)
mov   dx, word ptr [bp - 02Ch]
adc   dx, 0

mov   al, ah
mov   ah, dl

; we dont have to shift DH's stuff in at all.
; if DH was even 1, we'd have triggered the above cmp

; is dh ever actually ever non zero??? would be nice to remove them.

sar   dh, 1
rcr   ax, 1
sar   dh, 1
rcr   ax, 1
sar   dh, 1
rcr   ax, 1
sar   dh, 1
rcr   ax, 1

cmp   ax, si
jge   skip_yl_ceil_clip
do_yl_ceil_clip:
mov   ax, si
skip_yl_ceil_clip:
push  ax 				; store yl
SELFMODIFY_BSP_markceiling_1:
jmp SHORT    markceiling_done
SELFMODIFY_BSP_markceiling_1_AFTER = SELFMODIFY_BSP_markceiling_1+2

;                       si = top = ceilingclip[rw_x]+1;
dec   ax				; bottom = yl-1;
; cx is floor, 
cmp   ax, cx
jl    skip_bottom_floorclip
mov   ax, cx
dec   ax
skip_bottom_floorclip:
cmp   si, ax
jg    markceiling_done
les   bx, dword ptr ds:[_ceiltop] 
mov   byte ptr es:[bx+di + 0142h], al		; in a visplane_t, add 322 (0x142) to get bottom from top pointer
mov   ax, si						    		   ; dl is 0, si is < screensize (and thus under 255)
mov   byte ptr es:[bx+di], al
SELFMODIFY_BSP_markceiling_1_TARGET:
markceiling_done:

; yh = bottomfrac>>HEIGHTBITS;

; any of these bits being set means yh > 320 and clips
cmp   byte ptr [bp - 027h], 0
jne	  do_yh_floorclip

mov   ax, word ptr [bp - 029h] ; get bytes 2 and 3..

; screenheight << HEIGHTBITS 
; if AH > 20 , then we know yh cannot be smaller than floor clip which maxes out at screenheight+1
; (20 is (SCREENHEIGHT+1) >> 4, or rather, (((SCREENHEIGHT+1) << HEIGHTBITS) >> 16))
; we dont have to shift in that case. because 320 is the highest possible value for floorclip.

cmp   ah, ((SCREENHEIGHT+1) SHR 4)
jg    do_yh_floorclip

; finish the shift 12
; todo: we are assuming this cant be negative. If it can be,
; we must do the full sar rcr with the 4th byte. seems fine so far?


SHIFT_MACRO shr ax 4




; cx is still floor
cmp   ax, cx
jl    skip_yh_floorclip
do_yh_floorclip:
mov   ax, cx
dec   ax
skip_yh_floorclip:
push  ax  ; store yh
SELFMODIFY_BSP_markfloor_1:
;je    markfloor_done
SELFMODIFY_BSP_markfloor_1_AFTER = SELFMODIFY_BSP_markfloor_1 + 2
; ax is already yh
inc   ax			; top = yh + 1...
; cx is already  floor
dec   cx			; bottom = floorclip[rw_x]-1;

;	if (top <= ceilingclip[rw_x]){
;		top = ceilingclip[rw_x]+1;
;	}

; si is ceil
cmp   ax, si
jge   skip_top_ceilingclip
mov   ax, si	 ; ax = ceiling clip di + 1
skip_top_ceilingclip:

;	if (top <= bottom) {
;		floortop[rw_x] = top & 0xFF;
;		floortop[rw_x+322] = bottom & 0xFF;
;	}

cmp   ax, cx
jg    markfloor_done
les   bx, dword ptr ds:[_floortop]
mov   byte ptr es:[bx+di], al
mov   byte ptr es:[bx+di + 0142h], cl
SELFMODIFY_BSP_markfloor_1_TARGET:
markfloor_done:
SELFMODIFY_BSP_get_segtextured:
jmp SHORT    jump_to_seg_non_textured
SELFMODIFY_BSP_get_segtextured_AFTER:
seg_is_textured:

; angle = MOD_FINE_ANGLE (rw_centerangle + xtoviewangle[rw_x]);

mov   ax, XTOVIEWANGLE_SEGMENT
mov   es, ax
SELFMODIFY_set_rw_center_angle:
mov   ax, 01000h
mov   bx, di
add   ax, word ptr es:[bx+di]
and   ah, FINE_ANGLE_HIGH_BYTE				; MOD_FINE_ANGLE = and 0x1FFF

; temp.w = rw_offset.w - FixedMul(finetangent(angle),rw_distance);

mov   bx, FINETANGENTINNER_SEGMENT
mov   es, bx
cmp   ax, FINE_TANGENT_MAX
mov   bx, ax
jb    non_subtracted_finetangent
; mirrored values in lookup table
neg   bx
add   bx, 4095
SHIFT_MACRO shl bx 2
les   ax, dword ptr es:[bx]
mov   dx, es
neg   dx
neg   ax
sbb   dx, 0
jmp   finetangent_ready
SELFMODIFY_BSP_get_segtextured_TARGET:
jump_to_seg_non_textured:
xor   dx, dx
jmp   seg_non_textured
non_subtracted_finetangent:
SHIFT_MACRO shl bx 2
les   ax, dword ptr es:[bx]
mov   dx, es
finetangent_ready:
; calculate texture column
SELFMODIFY_set_bx_rw_distance_lo:
mov   bx, 01000h
SELFMODIFY_set_cx_rw_distance_hi:
mov   cx, 01000h


mov   es, ax	; store ax in es
mov   ds, dx    ; store dx in ds
mov   ax, dx	; ax holds dx
CWD				; S0 in DX

; todo inlined fixedmul do 386

AND   DX, BX	; S0*BX
NEG   DX
mov   SI, DX	; SI stores hi word return

; AX still stores DX
MUL  CX         ; DX*CX
add  SI, AX    ; low word result into high word return

mov  AX, DS    ; restore DX from ds

mov  DX, SS   ; restore DS here using the previous mul's prefetch..
mov  DS, DX
; NOTE1 DS RESTORED here//. but it doesnt have to be?

MUL  BX         ; DX*BX
XCHG BX, AX    ; BX will hold low word return. store bx in ax
add  SI, DX    ; add high word to result

mov  DX, ES    ; restore AX from ES
mul  DX        ; BX*AX  
add  BX, DX    ; high word result into low word return
ADC  SI, 0

mov  AX, CX   ; AX holds CX
CWD           ; S1 in DX

mov  CX, ES   ; AX from ES
AND  DX, CX   ; S1*AX
NEG  DX
ADD  SI, DX   ; result into high word return

MUL  CX       ; AX*CX

ADD  AX, BX	  ; set up final return value
ADC  DX, SI


;	    texturecolumn = rw_offset-FixedMul(finetangent[angle],rw_distance);

; todo self modify the neg of this in somehow?
SELFMODIFY_set_cx_rw_offset_lo:	
mov   cx, 01000h
sub   cx, ax   ; cx is soon clobbered. so we only need AX?
SELFMODIFY_set_ax_rw_offset_hi:
mov   ax, 01000h
sbb   ax, dx

; texturecolumn = ax:cx...  or just ax (whole number)

;	if (rw_scale.h.intbits >= 3) {
;		index = MAXLIGHTSCALE - 1;
;	} else {
;		index = rw_scale.w >> LIGHTSCALESHIFT;
;	}

; CX:BX rw_scale
; todo bp/stack candidate
les   bx, dword ptr [bp - 032h]
mov   cx, es

; store texturecolumn
push  ax       ; later popped into dx

cmp   cl, 3
jae   use_max_light
do_lightscaleshift:

mov   al, bh
mov   ah, cl
mov   si, ax

SHIFT_MACRO shr si 4



; todo investigate selfmodify lookup here, write ahead byte value directly ahead.... also dont need to push pop si.
;(talking about SELFMODIFY_add_wallights).
; tricky due to fixedcolormap??
; alternatively just add si's value here to it.

do_light_write:
SELFMODIFY_add_wallights:
; si is scalelight
; scalelight is pre-shifted 4 to save on the double sal every column.
mov   al, byte ptr ds:[si+01000h]         ; 8a 84 00 10 
;        set drawcolumn colormap function address
mov   byte ptr cs:[SELFMODIFY_COLFUNC_set_colormap_index_jump], al


jmp   light_set


; begin fast_div_32_16_FFFF

IF COMPISA GE COMPILE_386
   ; unused portion of code for 386. 
ELSE

   fast_div_32_16_FFFF:

   xchg dx, cx   ; cx was 0, dx is FFFF
   div bx        ; after this dx stores remainder, ax stores q1
   xchg cx, ax   ; q1 to cx, ffff to ax  so div remaidner:ffff 
   div bx
   mov dx, cx   ; q1:q0 is dx:ax
   jmp FastDiv3232FFFF_done 
ENDIF


use_max_light:
; ugly 
mov   si, MAXLIGHTSCALE - 1
jmp   do_light_write
light_set:

; INLINED FASTDIV3232FFF_ algo. only used here.

; set ax:dx ffffffff

; if top 16 bits missing just do a 32 / 16
mov  ax, -1

; continue fast_div_32_16_FFFF


IF COMPISA GE COMPILE_386
   ; set up eax
   db 066h, 098h                    ; cwde (prepare EAX)
   ; set up edx
   db 066h, 031h, 0D2h              ; xor edx, edx (must be 0, not FFFF FFFF)

   ; set up ecx
   db 066h, 0C1h, 0E3h, 010h        ; shl  ebx, 0x10
   db 066h, 00Fh, 0A4h, 0D9h, 010h  ; shld ecx, ebx, 0x10

   ; divide
   db 066h, 0F7h, 0F1h              ; div ecx

   ; set up return
   db 066h, 00Fh, 0A4h, 0C2h, 010h  ; shld edx, eax, 0x10

   jmp FastDiv3232FFFF_done 

ELSE
   cwd

   test cx, cx
   je fast_div_32_16_FFFF

   main_3232_div:

   push  di



   XOR SI, SI ; zero this out to get high bits of numhi




   test ch, ch
   jne shift_bits_3232
   ; shift a whole byte immediately

   mov ch, cl
   mov cl, bh
   mov bh, bl
   xor bl, bl

   ; dont need a full shift 8 because we know everything is FF
   mov  si, 000FFh
   xor al, al

   shift_bits_3232:

   ; less than a byte to shift
   ; shift until MSB is 1
   ; DX gets 1s so we can skip it.

   SAL BX, 1
   RCL CX, 1
   JC done_shifting_3232  
   SAL AX, 1
   RCL SI, 1

   SAL BX, 1
   RCL CX, 1
   JC done_shifting_3232
   SAL AX, 1
   RCL SI, 1

   SAL BX, 1
   RCL CX, 1
   JC done_shifting_3232
   SAL AX, 1
   RCL SI, 1

   SAL BX, 1
   RCL CX, 1
   JC done_shifting_3232
   SAL AX, 1
   RCL SI, 1

   SAL BX, 1
   RCL CX, 1
   JC done_shifting_3232
   SAL AX, 1
   RCL SI, 1

   SAL BX, 1
   RCL CX, 1
   JC done_shifting_3232
   SAL AX, 1
   RCL SI, 1

   SAL BX, 1
   RCL CX, 1
   JC done_shifting_3232
   SAL AX, 1
   RCL SI, 1

   SAL BX, 1
   RCL CX, 1



   ; store this
   done_shifting_3232:

   ; we overshifted by one and caught it in the carry bit. lets shift back right one.

   RCR CX, 1
   RCR BX, 1


   ; SI:DX:AX holds divisor...
   ; CX:BX holds dividend...
   ; numhi = SI:DX
   ; numlo = AX:00...


   ; save numlo word in sp.
   ; avoid going to memory... lets do interrupt magic
   mov di, ax


   ; set up first div. 
   ; dx:ax becomes numhi
   mov   ax, dx
   mov   dx, si    

   ; store these two long term...
   mov   si, bx



   ; numhi is 00:SI in this case?

   ;	divresult.wu = DIV3216RESULTREMAINDER(numhi.wu, den1);
   ; DX:AX = numhi.wu


   div   cx

   ; rhat = dx
   ; qhat = ax
   ;    c1 = FastMul16u16u(qhat , den0);

   mov   bx, dx					; bx stores rhat
   mov   es, ax     ; store qhat

   mul   si   						; DX:AX = c1


   ; c1 hi = dx, c2 lo = bx
   cmp   dx, bx

   ja    check_c1_c2_diff_3232
   jne   q1_ready_3232
   cmp   ax, di
   jbe   q1_ready_3232
   check_c1_c2_diff_3232:

   ; (c1 - c2.wu > den.wu)

   sub   ax, di
   sbb   dx, bx
   cmp   dx, cx
   ja    qhat_subtract_2_3232
   je    compare_low_word_3232

   qhat_subtract_1_3232:
   mov ax, es
   dec ax
   xor dx, dx

   jmp FastDiv3232FFFF_done_di_si

   compare_low_word_3232:
   cmp   ax, si
   jbe   qhat_subtract_1_3232

   ; ugly but rare occurrence i think?
   qhat_subtract_2_3232:
   mov ax, es
   dec ax
   dec ax

   jmp FastDiv3232FFFF_done_di_si  
ENDIF


; do jmp. highest priority, overwrite previously written thing.
seglooptexrepeat0_is_jmp:
; NOTE1 next CS here
mov   word ptr cs:[SELFMODIFY_BSP_set_seglooptexrepeat0], ((SELFMODIFY_BSP_set_seglooptexrepeat0_TARGET - SELFMODIFY_BSP_set_seglooptexrepeat0_AFTER) SHL 8) + 0EBh
jmp   just_do_draw0
in_texture_bounds0:
xchg  ax, dx
sub   al, byte ptr ds:[_segloopcachedbasecol]
mul   byte ptr ds:[_segloopheightvalcache]
jmp   add_base_segment_and_draw0
SELFMODIFY_BSP_set_seglooptexrepeat0_TARGET:
non_repeating_texture0:
cmp   dx, word ptr ds:[_segloopnextlookup]
jge   out_of_texture_bounds0
cmp   dx, word ptr ds:[_segloopprevlookup]
jge   in_texture_bounds0
out_of_texture_bounds0:
push  bx
xor   bx, bx

SELFMODIFY_BSP_set_toptexture:
SELFMODIFY_BSP_set_midtexture:
mov   ax, 01000h
call  R_GetColumnSegment_
pop   bx

mov   dx, word ptr ds:[_segloopcachedsegment]
mov   word ptr cs:[SELFMODIFY_add_cached_segment0+1], dx

         COMMENT @ REDO THIS AREA IF WE RE-ADD NON PO2 TEXTURES
         ; see above, but all textures in vanilla are po2 so this is not necessary for now.
         mov   dh, byte ptr ds:[_seglooptexmodulo]
         mov   byte ptr cs:[SELFMODIFY_BSP_set_seglooptexmodulo0+1], dh

         cmp   dh, 0
         je    seglooptexmodulo0_is_jmp

         mov   dl, 0B2h   ;  (mov dl, xx)
         mov   word ptr cs:[SELFMODIFY_BSP_check_seglooptexmodulo0], dx
         jmp   check_seglooptexrepeat0
         seglooptexmodulo0_is_jmp:
         mov   word ptr cs:[SELFMODIFY_BSP_check_seglooptexmodulo0], ((SELFMODIFY_BSP_check_seglooptexmodulo0_TARGET - SELFMODIFY_BSP_check_seglooptexmodulo0_AFTER) SHL 8) + 0EBh
         check_seglooptexrepeat0:
         @

; todohigh get this dh and dl in same read?
mov   dh, byte ptr ds:[_seglooptexrepeat]
cmp   dh, 0
je    seglooptexrepeat0_is_jmp
; modulo is seglooptexrepeat - 1
mov   dl, byte ptr ds:[_segloopheightvalcache]
mov   byte ptr cs:[SELFMODIFY_BSP_check_seglooptexmodulo0],   0B8h   ; mov ax, xxxx
mov   word ptr cs:[SELFMODIFY_BSP_check_seglooptexmodulo0+1], dx

jmp   just_do_draw0


; continue fast_div_32_16_FFFF

IF COMPISA GE COMPILE_386
ELSE
   q1_ready_3232:

   mov  ax, es
   xor  dx, dx

   FastDiv3232FFFF_done_di_si:
   pop   di
ENDIF

; end fast_div_32_16_FFFF


FastDiv3232FFFF_done:

; do the bit shuffling etc when writing direct to drawcol.

mov   dh, dl
mov   dl, ah
mov   word ptr cs:[SELFMODIFY_BSP_set_dc_iscale_lo+1], ax
mov   word ptr cs:[SELFMODIFY_BSP_set_dc_iscale_hi+1], dx  


; store dc_x directly in code
mov   word ptr cs:[SELFMODIFY_COLFUNC_get_dc_x+1], di

; get texturecolumn     in dx
pop   dx

seg_non_textured:
; si/di are yh/yl
;if (yh >= yl){
mov   bx, di 			; store rw_x
add   bx, bx
mov   ax, OPENINGS_SEGMENT ; todo is this necessary? just gets pushed later.
mov   es, ax

; dx holds texturecolumn
; get yl/yh in di/si
pop   di
pop   si
SELFMODIFY_BSP_midtexture:
SELFMODIFY_BSP_midtexture_AFTER = SELFMODIFY_BSP_midtexture + 3

cmp   di, si               ; todo should we check this earlier...?
jl    mid_no_pixels_to_draw

; si:di are dc_yl, dc_yh
; dx holds texturecolumn


; inlined function. 
R_GetSourceSegment0_START:
push  es
push  dx


; okay. we modify the first instruction in this argument. 
 ; if no texture is yet cached for this rendersegloop, jmp to non_repeating_texture
  ; if one is set, then the result of the predetermined value of seglooptexmodulo might it into a jump
   ; if its a repeating texture  then we modify it to mov ah, segloopheightvalcache

SELFMODIFY_BSP_check_seglooptexmodulo0:
SELFMODIFY_BSP_set_seglooptexrepeat0:
; 3 bytes. May become one of two jumps (two bytes) or mov ax, imm16 (three bytes)
jmp    non_repeating_texture0
SELFMODIFY_BSP_set_seglooptexrepeat0_AFTER:
SELFMODIFY_BSP_check_seglooptexmodulo0_AFTER:
xchg  ax, ax                    ; one byte nop placeholder. this gets the ah value in mov ax, xxxx (byte 3)
and   dl, ah   ; ah has loopwidth-1 (modulo )
mul   dl       ; al has heightval
add_base_segment_and_draw0:
SELFMODIFY_add_cached_segment0:
add   ax, 01000h
just_do_draw0:
mov   word ptr ds:[_dc_source_segment], ax ; what if this was push then pop es later. hard because we get a 2nd value with lds.

push  bp
SELFMODIFY_set_midtexturemid_hi:
SELFMODIFY_set_toptexturemid_hi:
mov   dx, 01000h
SELFMODIFY_set_midtexturemid_lo:
SELFMODIFY_set_toptexturemid_lo:
mov   bp, 01000h

ENDP

; fall thru in the case of top/bot column.
PROC  R_DrawColumnPrep_ NEAR
PUBLIC  R_DrawColumnPrep_ 


push  bx
push  si
push  di


mov   ax, COLFUNC_JUMP_LOOKUP_SEGMENT        ; compute segment now, clear AX dependency
mov   ds, ax ; store this segment for now, with offset pre-added

SELFMODIFY_COLFUNC_get_dc_x:
mov   ax, 01000h

; shift ax by (2 - detailshift.)
; todo: are we benefitted by moving this out into rendersegrange..?
SELFMODIFY_BSP_detailshift2minus:
sar   ax, 1
sar   ax, 1

; dest = destview + dc_yl*80 + (dc_x>>2); 
; frac.w = dc_texturemid.w + (dc_yl-centery)*dc_iscale

; si is dc_yl 
mov   bx, si
add   ax, word ptr ds:[bx+si+COLFUNC_JUMP_AND_DC_YL_OFFSET_DIFF]                  ; set up destview 
SELFMODIFY_BSP_add_destview_offset:
add   ax, 01000h

; di is dc_yh
sub   di, bx                                 ;
sal   di, 1                                 ; double diff (dc_yh - dc_yl) to get a word offset
mov   di, word ptr ds:[di]                   ; get the jump value
xchg  ax, di								 ; di gets screen dest offset, ax gets jump value
mov   word ptr ds:[((SELFMODIFY_COLFUNC_jump_offset+1))+COLFUNC_JUMP_AND_FUNCTION_AREA_OFFSET_DIFF], ax  ; overwrite the jump relative call for however many iterations in unrolled loop we need


xchg  ax, bx            ; dc_yl in ax
mov   si, dx            ; dc_texturemid+2 to si

; We don't have easy access into the drawcolumn code segment.
; so instead of cli -> push bp after call, we do it right before,
; so that we have register space to use bp now instead of a bit later.
; (for carrying dc_texturemid)



; dc_iscale loaded here..
SELFMODIFY_BSP_set_dc_iscale_lo:
mov   bx, 01000h        ; dc_iscale +0
SELFMODIFY_BSP_set_dc_iscale_hi:
mov   cx, 01000h        ; dc_iscale +1



; dynamic call lookuptable based on used colormaps address being CS:00

db 036h   ; ss: (prefix because we set ds instead of es above to save bytes..)
db 0FFh  ; lcall[addr]
db 01Eh  ;
SELFMODIFY_COLFUNC_set_colormap_index_jump:
dw 0300h
; addr 0300 + first byte (4x colormap.)



pop   di 
pop   si
pop   bx

SELFMODIFY_BSP_R_DrawColumnPrep_ret:

; the pop dx gets replaced with ret if bottom is calling
pop   bp
pop   dx
pop   es

; this runs as a jmp for a top call, otherwise NOP for mid call
SELFMODIFY_BSP_midtexture_return_jmp:
; JMP back runs for a TOP call
; we overwrite the next instruction with a jmp if toptexture call. otherwise we restore it.
SELFMODIFY_BSP_midtexture_return_jmp_AFTER = SELFMODIFY_BSP_midtexture_return_jmp+3


mid_no_pixels_to_draw:
; bx is already _rw_x << 1
SELFMODIFY_BSP_setviewheight_1:
mov   word ptr es:[bx + OFFSET_CEILINGCLIP], 01000h   ; 26 c7 87 80 a7 00 10  (this instruction that gets selfmodified)
mov   word ptr es:[bx + OFFSET_FLOORCLIP], 0FFFFh
finished_inner_loop_iter:

;		for ( ; rw_x < rw_stopx ; 
;			rw_x		+= detailshiftitercount,
;			topfrac 	+= topstepshift,
;			bottomfrac  += bottomstepshift,
;			rw_scale.w  += rwscaleshift

SELFMODIFY_add_detailshiftitercount:
add   word ptr [bp - 018h], 0   ; rw_x
mov   ax, word ptr [bp - 018h]  ; rw_x
SELFMODIFY_cmp_di_to_rw_stopx_2:
cmp   ax, 01000h   ; cmp   di, word ptr [bp - 01Ah]
jge   jump_to_finish_outer_loop  ; exit before adding the other loop vars.


SELFMODIFY_add_to_rwscale_lo_1:
add   word ptr [bp - 032h], 01000h
SELFMODIFY_add_to_rwscale_hi_1:
adc   word ptr [bp - 030h], 01000h
SELFMODIFY_add_to_topfrac_lo_1:
add   word ptr [bp - 02Eh], 01000h
SELFMODIFY_add_to_topfrac_hi_1:
adc   word ptr [bp - 02Ch], 01000h
SELFMODIFY_add_to_bottomfrac_lo_1:
add   word ptr [bp - 02Ah], 01000h
SELFMODIFY_add_to_bottomfrac_hi_1:
adc   word ptr [bp - 028h], 01000h
jmp   start_per_column_inner_loop
jump_to_finish_outer_loop:
mov   dx, cs
mov   ds, dx
mov   dx, SC_DATA  ; cheat this out of the loop..
jmp   finish_outer_loop

SELFMODIFY_BSP_toptexture_TARGET:
no_top_texture_draw:
; bx is already rw_x << 1
SELFMODIFY_BSP_markceiling_2:
jmp SHORT   check_bottom_texture
SELFMODIFY_BSP_markceiling_2_AFTER:
; bx is already rw_x << 1
mark_ceiling_si:
; bx is already rw_x << 1
lea   ax, [si - 1]
mov   word ptr es:[bx + OFFSET_CEILINGCLIP], ax
jmp   check_bottom_texture

SELFMODIFY_BSP_midtexture_TARGET:
no_mid_texture_draw:

SELFMODIFY_BSP_toptexture:
SELFMODIFY_BSP_toptexture_AFTER = SELFMODIFY_BSP_toptexture + 2

do_top_texture_draw:
mov   ax, word ptr [bp - 021h]
mov   cl, byte ptr [bp - 01Fh]
sar   cl, 1
rcr   ax, 1
sar   cl, 1
rcr   ax, 1
sar   cl, 1
rcr   ax, 1
sar   cl, 1
rcr   ax, 1
SELFMODIFY_add_to_pixhigh_lo_1:
add   word ptr [bp - 022h], 01000h
SELFMODIFY_add_to_pixhigh_hi_1:
adc   word ptr [bp - 020h], 01000h
; bx is rw_x << 1
mov   cx, ax
mov   ax, word ptr es:[bx + OFFSET_FLOORCLIP]
cmp   cx, ax
jl    dont_clip_top_floor
mov   cx, ax
dec   cx
dont_clip_top_floor:
cmp   cx, si
jl    mark_ceiling_si
cmp   di, si
jle   mark_ceiling_cx

xchg   cx, di
; si:di are dc_yl, dc_yh
push   cx ; note: midtexture doesnt need/use cx and doesnt do this.


; si:di are dc_yl, dc_yh
; dx holds texturecolumn

jmp R_GetSourceSegment0_START
SELFMODIFY_BSP_midtexture_return_jmp_TARGET:
R_GetSourceSegment0_DONE_TOP:

pop    cx
xchg   cx, di



mark_ceiling_cx:
mov   word ptr es:[bx  + OFFSET_CEILINGCLIP], cx
SELFMODIFY_BSP_markceiling_2_TARGET:
check_bottom_texture:
; bx is already rw_x << 1

SELFMODIFY_BSP_bottexture:
SELFMODIFY_BSP_bottexture_AFTER = SELFMODIFY_BSP_bottexture + 2

do_bottom_texture_draw:
SELFMODIFY_get_pixlow_lo:
mov   ax, word ptr [bp - 026h]
add   ax, ((HEIGHTUNIT)-1)
SELFMODIFY_get_pixlow_hi:
mov   cx, word ptr [bp - 024h]
adc   cx, 0
mov   al, ah
mov   ah, cl
sar   ch, 1
rcr   ax, 1
sar   ch, 1
rcr   ax, 1
sar   ch, 1
rcr   ax, 1
sar   ch, 1
rcr   ax, 1
SELFMODIFY_add_to_pixlow_lo_1:
add   word ptr [bp - 026h], 01000h
SELFMODIFY_add_to_pixlow_hi_1:
adc   word ptr [bp - 024h], 01000h

mov   cx, ax
mov   ax, word ptr es:[bx+OFFSET_CEILINGCLIP]
cmp   cx, ax
jg    dont_clip_bot_ceil
inc   ax
xchg  cx, ax
dont_clip_bot_ceil:
cmp   cx, di
jg    mark_floor_di
cmp   di, si
jle   mark_floor_cx

xchg   cx, si
; dont push/pop cx because we don't need to preserve si, and si preserves cx
; si:di are dc_yl, dc_yh

; si:di are dc_yl, dc_yh
; dx holds texturecolumn

; BEGIN INLINED R_GetSourceSegment1_

push  es
push  dx


SELFMODIFY_BSP_check_seglooptexmodulo1:
SELFMODIFY_BSP_set_seglooptexrepeat1:
; 3 bytes. May become one of two jumps (two bytes) or mov ax, imm16 (three bytes)
jmp SHORT non_repeating_texture1

SELFMODIFY_BSP_set_seglooptexrepeat1_AFTER:
SELFMODIFY_BSP_check_seglooptexmodulo1_AFTER:
xchg  ax, ax                    ; one byte nop placeholder. this gets the ah value in mov ax, xxxx (byte 3)
and   dl, ah   ; ah has loopwidth-1 (modulo )
mul   dl       ; al has heightval
add_base_segment_and_draw1:
SELFMODIFY_add_cached_segment1:
add   ax, 01000h
just_do_draw1:
mov   word ptr ds:[_dc_source_segment], ax

push  bp

SELFMODIFY_set_bottexturemid_hi:
mov   dx, 01000h
SELFMODIFY_set_bottexturemid_lo:
mov   bp, 01000h

; small idea: make these each three NOPs if its gonna be a bot only draw?
SELFMODIFY_bottomtexonly_1:
mov   byte ptr cs:[SELFMODIFY_BSP_R_DrawColumnPrep_ret], 0C3h  ; ret
call  R_DrawColumnPrep_

pop bp
SELFMODIFY_bottomtexonly_2:
mov   byte ptr cs:[SELFMODIFY_BSP_R_DrawColumnPrep_ret], 05Dh  ; pop bp

pop   dx
pop   es



;END INLINED R_GetSourceSegment1_

xchg   cx, si

mark_floor_cx:
mov   word ptr es:[bx+OFFSET_FLOORCLIP], cx
SELFMODIFY_BSP_markfloor_2_TARGET:
done_marking_floor:
SELFMODIFY_get_maskedtexture_1:
mov   al, 0
test  al, al
jne   record_masked
jmp   finished_inner_loop_iter
SELFMODIFY_BSP_bottexture_TARGET:
no_bottom_texture_draw:
SELFMODIFY_BSP_markfloor_2:
;je    done_marking_floor
SELFMODIFY_BSP_markfloor_2_AFTER = SELFMODIFY_BSP_markfloor_2+2
;floorclip[rw_x] = yh + 1;
mark_floor_di:
inc   di
mov   word ptr es:[bx+OFFSET_FLOORCLIP], di
SELFMODIFY_get_maskedtexture_2:
mov   al, 0
test  al, al
jne   record_masked
jmp   finished_inner_loop_iter
;BEGIN INLINED R_GetSourceSegment1_ AGAIN
; this was only called in one place. this runs often, so inline it.

         COMMENT @ REDO THIS AREA IF WE RE-ADD NON PO2 TEXTURES
         non_po2_texture_mod1:
         ; cx stores tex repeat
         SELFMODIFY_BSP_check_seglooptexmodulo1_TARGET:
         SELFMODIFY_BSP_set_seglooptexmodulo1:
         mov   cx, 0
         mov   dx, word ptr ds:[2 + _segloopcachedbasecol]
         cmp   ax, dx
         jge   done_subbing_modulo1
         sub   dx, cx
         continue_subbing_modulo1:
         cmp   ax, dx
         jge   record_subbed_modulo1
         sub   dx, cx
         jmp   continue_subbing_modulo1
         record_subbed_modulo1:
         ; at least one write was done. write back.
         mov   word ptr ds:[2 + _segloopcachedbasecol], dx

         done_subbing_modulo1:

         add   dx, cx
         cmp   ax, dx
         jl    done_adding_modulo1
         continue_adding_modulo1:
         add   dx, cx
         cmp   ax, dx
         jl    record_added_modulo1
         jmp   continue_adding_modulo1
         record_added_modulo1:
         sub   dx, cx
         mov   word ptr ds:[2 + _segloopcachedbasecol], dx
         add   dx, cx

         done_adding_modulo1:
         sub   dx, cx
         sub   al, dl
         mul   ah  byte ptr ds:[1 + _segloopheightvalcache]
         jmp   add_base_segment_and_draw1

         @ REDO THIS AREA IF WE RE-ADD NON PO2 TEXTURES

SELFMODIFY_BSP_set_seglooptexrepeat1_TARGET:
non_repeating_texture1:
cmp   dx, word ptr ds:[2 + _segloopnextlookup]
jge   out_of_texture_bounds1
cmp   dx, word ptr ds:[2 + _segloopprevlookup]
jge   in_texture_bounds1  ; todo change the default case.
out_of_texture_bounds1:
push  bx
mov   bx, 1

SELFMODIFY_BSP_set_bottomtexture:
mov   ax, 01000h
call  R_GetColumnSegment_
pop   bx

mov   dx, word ptr ds:[2 + _segloopcachedsegment]
mov   word ptr cs:[SELFMODIFY_add_cached_segment1+1], dx




         COMMENT @ REDO THIS AREA IF WE RE-ADD NON PO2 TEXTURES
         mov   dh, byte ptr ds:[1 + _seglooptexmodulo]
         mov   byte ptr cs:[SELFMODIFY_BSP_set_seglooptexmodulo1+1], dh

         cmp   dh, 0
         je    seglooptexmodulo1_is_jmp

         mov   dl, 0B2h   ;  (mov dl, xx)
         mov   word ptr cs:[SELFMODIFY_BSP_check_seglooptexmodulo1], dx
         jmp   check_seglooptexrepeat1
         seglooptexmodulo1_is_jmp:
         mov   word ptr cs:[SELFMODIFY_BSP_check_seglooptexmodulo1], ((SELFMODIFY_BSP_check_seglooptexmodulo1_TARGET - SELFMODIFY_BSP_check_seglooptexmodulo1_AFTER) SHL 8) + 0EBh
         check_seglooptexrepeat1:
         @


; todo get this dh and dl in same read
mov   dh, byte ptr ds:[1 + _seglooptexrepeat]
cmp   dh, 0
je    seglooptexrepeat1_is_jmp
; modulo is seglooptexrepeat - 1
mov   dl, byte ptr ds:[1 + _segloopheightvalcache]
mov   byte ptr cs:[SELFMODIFY_BSP_check_seglooptexmodulo1],   0B8h   ; mov ax, xxxx
mov   word ptr cs:[SELFMODIFY_BSP_check_seglooptexmodulo1+1], dx

jmp   just_do_draw1
; do jmp. highest priority, overwrite previously written thing.
seglooptexrepeat1_is_jmp:
mov   word ptr cs:[SELFMODIFY_BSP_set_seglooptexrepeat1], ((SELFMODIFY_BSP_set_seglooptexrepeat1_TARGET - SELFMODIFY_BSP_set_seglooptexrepeat1_AFTER) SHL 8) + 0EBh
jmp   just_do_draw1
in_texture_bounds1:
xchg  ax, dx  ; put texturecol in ax
sub   al, byte ptr ds:[2 + _segloopcachedbasecol]
mul   byte ptr ds:[1 + _segloopheightvalcache]
jmp   add_base_segment_and_draw1

;END INLINED R_GetSourceSegment1_ AGAIN




record_masked:

;if (maskedtexture) {
;	// save texturecol
;	//  for backdrawing of masked mid texture			
;	maskedtexturecol[rw_x] = texturecolumn;
;}

les   si, dword ptr ds:[_maskedtexturecol]
mov   word ptr es:[bx+si], dx
jmp   finished_inner_loop_iter

R_RenderSegLoop_exit:
;   END INLINED R_RenderSegLoop_
;   END INLINED R_RenderSegLoop_
;   END INLINED R_RenderSegLoop_
   



; clean up the self modified code of renderseg loop. 
mov   word ptr cs:[SELFMODIFY_BSP_set_seglooptexrepeat0], ((SELFMODIFY_BSP_set_seglooptexrepeat0_TARGET - SELFMODIFY_BSP_set_seglooptexrepeat0_AFTER) SHL 8) + 0EBh
mov   word ptr cs:[SELFMODIFY_BSP_set_seglooptexrepeat1], ((SELFMODIFY_BSP_set_seglooptexrepeat1_TARGET - SELFMODIFY_BSP_set_seglooptexrepeat1_AFTER) SHL 8) + 0EBh


check_spr_top_clip:
les       bx, dword ptr ds:[_ds_p]
test      byte ptr es:[bx + 01ch], SIL_TOP
jne       continue_checking_spr_top_clip
cmp       byte ptr ds:[_maskedtexture], 0
je        check_spr_bottom_clip



continue_checking_spr_top_clip:

cmp       word ptr es:[bx + 016h], 0
jne       check_spr_bottom_clip
mov       si, word ptr [bp - 2]
add       si, si
add       si, OFFSET_CEILINGCLIP
mov       di, word ptr ds:[_lastopening]
mov       cx, word ptr [bp - 01Ah]
sub       cx, word ptr [bp - 2]
mov       ax, OPENINGS_SEGMENT
mov       es, ax
mov       ds, ax
add       di, di

rep movsw

mov       ax, ss
mov       ds, ax
mov       ax, word ptr ds:[_lastopening]
sub       ax, word ptr [bp - 2]
mov       es, word ptr ds:[_ds_p+2]   ; bx is ds_p offset above
add       ax, ax
mov       word ptr es:[bx + 016h], ax
mov       ax, word ptr [bp - 01Ah]
sub       ax, word ptr [bp - 2]
add       word ptr ds:[_lastopening], ax
check_spr_bottom_clip:
; es:si is ds_p
test      byte ptr es:[bx + 01ch], SIL_BOTTOM
jne       continue_checking_spr_bottom_clip
cmp       byte ptr ds:[_maskedtexture], 0
je        check_silhouettes_then_exit
jmp       continue_checking_spr_bottom_clip
continue_checking_spr_bottom_clip:
cmp       word ptr es:[bx + 018h], 0
jne       check_silhouettes_then_exit
mov       si, word ptr [bp - 2]
add       si, si
add       si, OFFSET_FLOORCLIP
mov       ax, OPENINGS_SEGMENT
mov       di, word ptr ds:[_lastopening]
add       di, di
mov       cx, word ptr [bp - 01Ah]
sub       cx, word ptr [bp - 2]
mov       es, ax
mov       ds, ax
rep movsw 

mov       ax, ss
mov       ds, ax

mov       ax, word ptr ds:[_lastopening]
sub       ax, word ptr [bp - 2]
mov       es, word ptr ds:[_ds_p+2]   ; bx is ds_p offset above
add       ax, ax
mov       word ptr es:[bx + 018h], ax
mov       ax, word ptr [bp - 01Ah]
sub       ax, word ptr [bp - 2]
add       word ptr ds:[_lastopening], ax
check_silhouettes_then_exit:
cmp       byte ptr ds:[_maskedtexture], 0
je        skip_top_silhouette
test      byte ptr es:[bx + 01ch], SIL_TOP
jne       skip_top_silhouette
or        byte ptr es:[bx + 01ch], SIL_TOP
mov       word ptr es:[bx + 014h], MINSHORT
skip_top_silhouette:

cmp       byte ptr ds:[_maskedtexture], 0
je        skip_bot_silhouette
test      byte ptr es:[bx + 01ch], SIL_BOTTOM
jne       skip_bot_silhouette
or        byte ptr es:[bx + 01ch], SIL_BOTTOM
mov       word ptr es:[bx + 012h], MAXSHORT
skip_bot_silhouette:
add       word ptr ds:[_ds_p], SIZEOF_DRAWSEG_T
LEAVE_MACRO
pop       di
pop       si
pop       cx
pop       bx
ret       

handle_two_sided_line:

; jumped to with ds as cs


; nop 

SELFMODIFY_BSP_drawtype_2:
SELFMODIFY_BSP_drawtype_2_AFTER = SELFMODIFY_BSP_drawtype_2+2

mov       ax, 0c089h 

ASSUME DS:R_BSP_TEXT
mov       word ptr ds:[SELFMODIFY_BSP_midtextureonly_skip_pixhighlow_1], ax
mov       word ptr ds:[SELFMODIFY_BSP_midtextureonly_skip_pixhighlow_2], ax
mov       word ptr ds:[SELFMODIFY_BSP_midtextureonly_skip_pixhighlow_3], ax
;mov       word ptr ds:[SELFMODIFY_BSP_midtextureonly_skip_pixhighlow_4], ax
mov       word ptr ds:[SELFMODIFY_BSP_midtextureonly_skip_pixhighlow_5], ax


mov       word ptr ds:[SELFMODIFY_BSP_drawtype_1], 0EBB8h   ; mov ax, xxeB
mov       word ptr ds:[SELFMODIFY_BSP_drawtype_2], ((SELFMODIFY_BSP_drawtype_2_TARGET - SELFMODIFY_BSP_drawtype_2_AFTER) SHL 8) + 0EBh

mov       word ptr ds:[SELFMODIFY_BSP_midtexture], 0E9h
mov       word ptr ds:[SELFMODIFY_BSP_midtexture+1], (SELFMODIFY_BSP_midtexture_TARGET - SELFMODIFY_BSP_midtexture_AFTER) 

mov       byte ptr ds:[SELFMODIFY_BSP_midtexture_return_jmp+0], 0E9h ; jmp short rel16
mov       word ptr ds:[SELFMODIFY_BSP_midtexture_return_jmp+1], SELFMODIFY_BSP_midtexture_return_jmp_TARGET - SELFMODIFY_BSP_midtexture_return_jmp_AFTER



SELFMODIFY_BSP_drawtype_2_TARGET:
; nomidtexture. this will be checked before top/bot, have to set it to 0.


mov       si, ss   ; restore DS
mov       ds, si
ASSUME DS:DGROUP


; short_height_t backsectorfloorheight = backsector->floorheight;
; short_height_t backsectorceilingheight = backsector->ceilingheight;
; uint8_t backsectorceilingpic = backsector->ceilingpic;
; uint8_t backsectorfloorpic = backsector->floorpic;
; uint8_t backsectorlightlevel = backsector->lightlevel;

les       si, dword ptr ds:[_backsector]
lods      word ptr es:[si]
push      ax  ; bp - 046h
xchg      ax, cx
lods      word ptr es:[si]
push      ax  ; bp - 048h
xchg      ax, bx   ; store for later
lods      word ptr es:[si]
mov       byte ptr [bp - 03Ah], al
mov       byte ptr [bp - 038h], ah
mov       al, byte ptr es:[si + 08h]  ; 0eh with the 6 from lodsw.
mov       byte ptr [bp - 03Ch], al
xchg      ax, cx

;		ds_p->sprtopclip_offset = ds_p->sprbottomclip_offset = 0;
;		ds_p->silhouette = 0;

les       si, dword ptr ds:[_ds_p]
xor       cx, cx
mov       word ptr es:[si + 018h], cx
mov       word ptr es:[si + 016h], cx
mov       byte ptr es:[si + 01ch], cl ; SIL_NONE


; es:si is ds_p
;		if (frontsectorfloorheight > backsectorfloorheight) {

cmp       ax, word ptr [bp - 034h]
jl        set_bsilheight_to_frontsectorfloorheight
SELFMODIFY_BSP_viewz_shortheight_2:
cmp       ax, 01000h
jle       bsilheight_set
set_bsilheight_to_maxshort:
mov       byte ptr es:[si + 01Ch], SIL_BOTTOM
mov       word ptr es:[si + 012h], MAXSHORT
jmp       bsilheight_set
set_bsilheight_to_frontsectorfloorheight:
mov       byte ptr es:[si + 01Ch], SIL_BOTTOM
mov       cx, word ptr [bp - 034h]
mov       word ptr es:[si + 012h], cx
bsilheight_set:

xchg      ax, bx   ; retrieved from before
cmp       ax, word ptr [bp - 036h]
jg        set_tsilheight_to_frontsectorceilingheight
SELFMODIFY_BSP_viewz_shortheight_1:
cmp       ax, 01000h
jge       tsilheight_set
set_tsilheight_to_minshort:
or        byte ptr es:[si + 01ch], SIL_TOP
mov       word ptr es:[si + 014h], MINSHORT
jmp       tsilheight_set
set_tsilheight_to_frontsectorceilingheight:
or        byte ptr es:[si + 01ch], SIL_TOP
mov       cx, word ptr [bp - 036h]
mov       word ptr es:[si + 014h], cx
tsilheight_set:
; es:si is still ds_p

; if (backsectorceilingheight <= frontsectorfloorheight) {

cmp       ax, word ptr [bp - 034h]
jg        back_ceiling_greater_than_front_floor

; ds_p->sprbottomclip_offset = offset_negonearray;
; ds_p->bsilheight = MAXSHORT;
; ds_p->silhouette |= SIL_BOTTOM;

mov       word ptr es:[si + 018h], OFFSET_NEGONEARRAY
mov       word ptr es:[si + 012h], MAXSHORT
or        byte ptr es:[si + 01ch], SIL_BOTTOM
back_ceiling_greater_than_front_floor:
; es:si is still ds_p
; if (backsectorfloorheight >= frontsectorceilingheight) {
; ax is backsectorfloorheight
mov       ax, word ptr [bp - 046h]
cmp       ax, word ptr [bp - 036h]
jl        back_floor_less_than_front_ceiling

; ds_p->sprtopclip_offset = offset_screenheightarray;
; ds_p->tsilheight = MINSHORT;
; ds_p->silhouette |= SIL_TOP;
mov       word ptr es:[si + 016h], OFFSET_SCREENHEIGHTARRAY
mov       word ptr es:[si + 014h], MINSHORT
or        byte ptr es:[si + 01ch], SIL_TOP
back_floor_less_than_front_ceiling:

; SET_FIXED_UNION_FROM_SHORT_HEIGHT(worldhigh, backsectorceilingheight);
; worldhigh.w -= viewz.w;
; SET_FIXED_UNION_FROM_SHORT_HEIGHT(worldlow, backsectorfloorheight);
; worldlow.w -= viewz.w;

mov       di, word ptr [bp - 048h]
xor       si, si
sar       di, 1
rcr       si, 1
sar       di, 1  ; todo 386 shrd type stuff
rcr       si, 1
sar       di, 1
rcr       si, 1
SELFMODIFY_BSP_viewz_lo_3:
sub       si, 01000h
SELFMODIFY_BSP_viewz_hi_3:
sbb       di, 01000h

;di:si will store worldhigh
; what if we store bx/cx here as well, and finally push it once it's too onerous to hold onto?
mov       cx, word ptr [bp - 046h] ; can be ax?
xor       bx, bx
sar       cx, 1
rcr       bx, 1
sar       cx, 1
rcr       bx, 1
sar       cx, 1
rcr       bx, 1

SELFMODIFY_BSP_viewz_lo_2:
sub       bx, 01000h
SELFMODIFY_BSP_viewz_hi_2:
sbb       cx, 01000h

; cx:bx hold on to worldlow for now


; // hack to allow height changes in outdoor areas
; if (frontsectorceilingpic == skyflatnum && backsectorceilingpic == skyflatnum) {
; 	worldtop = worldhigh;
; }

; todohigh skyflatnum should be a per level constant??
mov       al, byte ptr ds:[_skyflatnum]
cmp       al, byte ptr [bp - 037h]
jne       not_a_skyflat
cmp       al, byte ptr [bp - 038h]
jne       not_a_skyflat
;di/si are worldhigh..

mov       word ptr [bp - 040h], si
mov       word ptr [bp - 03Eh], di

not_a_skyflat:

			
;	if (worldlow.w != worldbottom .w || backsectorfloorpic != frontsectorfloorpic || backsectorlightlevel != frontsectorlightlevel) {
;		markfloor = true;
;	} else {
;		// same plane on both sides
;		markfloor = false;
;	}

cmp       cx, word ptr [bp - 042h]
jne       set_markfloor_true
cmp       bx, word ptr [bp - 044h]
jne       set_markfloor_true
mov       ax, word ptr [bp - 03Ah]
cmp       al, ah
jne       set_markfloor_true
mov       ax, word ptr [bp - 03Ch]
cmp       al, ah
jne       set_markfloor_true
set_markfloor_false:
mov       byte ptr [bp - 01Ch], 0  ; markfloor
jmp       markfloor_set
set_markfloor_true:
mov       byte ptr [bp - 01Ch], 1  ; markfloor
markfloor_set:
; di/si are already worldhigh..
cmp       word ptr [bp - 03Eh], di
jne       set_markceiling_true
cmp       word ptr [bp - 040h], si
jne       set_markceiling_true

mov       ax, word ptr [bp - 038h]
cmp       al, ah
jne       set_markceiling_true

mov       ax, word ptr [bp - 03Ch]
cmp       al, ah
jne       set_markceiling_true
set_markceiling_false:
mov       byte ptr [bp - 01Bh], 0   ;markceiling
jmp       markceiling_set
set_markceiling_true:
mov       byte ptr [bp - 01Bh], 1   ;markceiling
markceiling_set:

; TOOO: improve this area. write to markceiling/floor once not twice. use al/ah to store their values.
; write one word at the end. or write directly to the code.

;		if (backsectorceilingheight <= frontsectorfloorheight
;			|| backsectorfloorheight >= frontsectorceilingheight) {
;			// closed door
;			markceiling = markfloor = true;
;		}

mov       dx, word ptr [bp - 048h]
cmp       dx, word ptr [bp - 034h]
jle       closed_door_detected
mov       ax, word ptr [bp - 046h]
cmp       ax, word ptr [bp - 036h]
jl        not_closed_door 
closed_door_detected:
mov       ax, 0101h
mov       word ptr [bp - 01Ch], ax  ; markfloor, ceiling
not_closed_door:
; ax free at last!
;		if (worldhigh.w < worldtop.w) {

; store worldhigh on stack..
push      di
push      si
xchg      di, cx
xchg      si, bx

; worldhigh check one past time
cmp       word ptr [bp - 03Eh], cx
jg        setup_toptexture
jne       toptexture_zero
cmp       word ptr [bp - 040h], bx
jbe       toptexture_zero
setup_toptexture:

;cx and bx (currently worldhigh) are clobbered but are on stack

; toptexture = texturetranslation[side->toptexture];

mov       ax, TEXTURETRANSLATION_SEGMENT
mov       bx, word ptr [bp - 0Ah]
mov       es, ax
add       bx, bx
mov       ax, word ptr es:[bx]

; write the high byte of the word.
; prev two bytes will be a jump or mov cx with the low byte
; todo midtexture some stuff set here

mov       word ptr cs:[SELFMODIFY_BSP_set_toptexture+1], ax
mov       bx, ax     ; backup
test      ax, ax
jne       toptexture_not_zero
toptexture_zero:
mov       word ptr cs:[SELFMODIFY_BSP_toptexture], ((SELFMODIFY_BSP_toptexture_TARGET - SELFMODIFY_BSP_toptexture_AFTER) SHL 8) + 0EBh
jmp       toptexture_stuff_done
set_toptexture_to_worldtop:
les       ax, dword ptr [bp - 040h]
mov       dx, es
jmp       do_selfmodify_toptexture

toptexture_not_zero:
mov       word ptr cs:[SELFMODIFY_BSP_toptexture], 0468Bh ; mov   ax, word ptr [bp - 02Dh] first two bytes
; are any bits set?
or        bl, bh
or        byte ptr cs:[SELFMODIFY_check_for_any_tex+1], bl


test      byte ptr [bp - 014h], ML_DONTPEGTOP
jne       set_toptexture_to_worldtop
calculate_toptexturemid:
; SET_FIXED_UNION_FROM_SHORT_HEIGHT(rw_toptexturemid, backsectorceilingheight);
; rw_toptexturemid.h.intbits += textureheights[side->toptexture] + 1;
; // bottom of texture
; rw_toptexturemid.w -= viewz.w;

; dx holding on to backsectorceilingheight from above.

xor       ax, ax
sar       dx, 1
rcr       ax, 1
sar       dx, 1
rcr       ax, 1
sar       dx, 1
rcr       ax, 1
;dx:ax are toptexturemid for now..
mov       bx, TEXTUREHEIGHTS_SEGMENT
mov       es, bx
mov       bx, word ptr [bp - 0Ah]

add       dl, byte ptr es:[bx]
adc       dh, 0
inc       dx

SELFMODIFY_BSP_viewz_lo_1:
sub       ax, 01000h
SELFMODIFY_BSP_viewz_hi_1:
sbb       dx, 01000h


do_selfmodify_toptexture:
; set _rw_toptexturemid in rendersegloop

mov   word ptr cs:[SELFMODIFY_set_toptexturemid_lo+1], ax
mov   word ptr cs:[SELFMODIFY_set_toptexturemid_hi+1], dx


toptexture_stuff_done:



cmp       di, word ptr [bp - 042h]
jg        setup_bottexture
jne       bottexture_zero
cmp       si, word ptr [bp - 044h]
jbe       bottexture_zero
setup_bottexture:
mov       ax, TEXTURETRANSLATION_SEGMENT
mov       bx, word ptr [bp - 0Ch]
; preshifted
mov       es, ax
mov       ax, word ptr es:[bx]

; write the high byte of the word.
; prev two bytes will be a jump or mov cx with the low byte
mov       word ptr cs:[SELFMODIFY_BSP_set_bottomtexture+1], ax
mov       bx, ax     ; backup
test      ax, ax

jne       bottexture_not_zero

bottexture_zero:
mov       word ptr cs:[SELFMODIFY_BSP_bottexture], ((SELFMODIFY_BSP_bottexture_TARGET - SELFMODIFY_BSP_bottexture_AFTER) SHL 8) + 0EBh
jmp       bottexture_stuff_done
bottexture_not_zero:
mov       word ptr cs:[SELFMODIFY_BSP_bottexture], 0468Bh   ; mov   ax, word ptr [bp - 02Dh] first two bytes
; are any bits set?
or        bl, bh
or        byte ptr cs:[SELFMODIFY_check_for_any_tex+1], bl



test      byte ptr [bp - 014h], ML_DONTPEGBOTTOM
je        calculate_bottexturemid
; todo cs write here
les       ax, dword ptr [bp - 040h]
mov       dx, es
do_selfmodify_bottexture:

; set _rw_toptexturemid in rendersegloop

mov   word ptr cs:[SELFMODIFY_set_bottexturemid_lo+1], ax
mov   word ptr cs:[SELFMODIFY_set_bottexturemid_hi+1], dx


bottexture_stuff_done:
SELFMODIFY_BSP_siderenderrowoffset_2:
mov       ax, 01000h

;  extra selfmodify? or hold in vars till this pt and finally write the high bits
; 	rw_toptexturemid.h.intbits += side_render->rowoffset;
;	rw_bottomtexturemid.h.intbits += side_render->rowoffset;


add       word ptr cs:[SELFMODIFY_set_toptexturemid_hi+1], ax
add       word ptr cs:[SELFMODIFY_set_bottexturemid_hi+1], ax
cmp       word ptr [bp - 0Eh], 0

; // allocate space for masked texture tables
; if (side->midtexture) {


; check midtexture on 2 sided line (e1m1 case)
jne       side_has_midtexture
xor       ax, ax
jmp       done_with_sector_sided_check
side_has_midtexture:

; // masked midtexture
; maskedtexture = true;
; ds_p->maskedtexturecol_val = lastopening - rw_x;
; maskedtexturecol_offset = (ds_p->maskedtexturecol_val) << 1;
; lastopening += rw_stopx - rw_x;

mov       ax, word ptr ds:[_lastopening]
sub       ax, word ptr [bp - 018h]    ; rw_x
les       bx, dword ptr ds:[_ds_p]
mov       word ptr es:[bx + 01ah], ax
mov       ax, word ptr es:[bx + 01ah]
add       ax, ax
mov       word ptr ds:[_maskedtexturecol], ax
mov       ax, word ptr [bp - 01Ah]
sub       ax, word ptr [bp - 018h]    ; rw_x
add       word ptr ds:[_lastopening], ax
mov       al, 1
mov       byte ptr ds:[_maskedtexture], al
jmp       done_with_sector_sided_check
calculate_bottexturemid:
; todo cs write here

mov       ax, si
mov       dx, di
jmp do_selfmodify_bottexture


ENDP



;R_ClipSolidWallSegment_

PROC R_ClipSolidWallSegment_ NEAR
PUBLIC R_ClipSolidWallSegment_ 



mov   cx, ax                  ; backup first in cx for most of the function.
mov   di, dx
dec   ax
mov   si, OFFSET _solidsegs
cmp   ax, word ptr ds:[si+2]

;  while (start->last < first-1)
;  	start++;

jle   found_start_solid
increment_start:
add   si, 4
cmp   ax, word ptr ds:[si + 2]
jg    increment_start
found_start_solid:
mov   ax, cx
cmp   ax, word ptr ds:[si]

;    if (first < start->first)

jge   first_greater_than_startfirst ;		if (last < start->first-1) {
mov   dx, word ptr ds:[si]
dec   dx
cmp   di, dx
jl    last_smaller_than_startfirst;
call  R_StoreWallRange_             ;		R_StoreWallRange (first, start->first - 1);
mov   ax, cx                        ;		start->first = first;	
mov   word ptr ds:[si], ax
first_greater_than_startfirst:
;	if (last <= start->last) {

cmp   di, word ptr ds:[si + 2]
jle   write_back_newend_and_return
;    next = start;
mov   bx, si                        ; si is start, bx is next
;    while (last >= (next+1)->first-1) {
check_between_posts:
mov   dx, word ptr ds:[bx + 4]
dec   dx
cmp   di, dx
jl    do_final_fragment
mov   ax, word ptr ds:[bx + 2]
inc   ax
;		// There is a fragment between two posts.
;		R_StoreWallRange (next->last + 1, (next+1)->first - 1);
call  R_StoreWallRange_
mov   ax, word ptr ds:[bx + 6]
add   bx, 4
cmp   di, ax
jg    check_between_posts
mov   word ptr ds:[si + 2], ax
crunch:
;    if (next == start) {
cmp   bx, si
je    write_back_newend_and_return
;    while (next++ != newend) {

mov   cx, word ptr ds:[_newend] ; cache old newend

check_to_remove_posts:
mov   ax, bx
lea   di, [si + 4]
add   bx, 4
cmp   ax, cx
je    done_removing_posts
les   ax, dword ptr ds:[bx]
mov   dx, es
mov   word ptr ds:[di], ax
mov   si, di
mov   word ptr ds:[di + 2], dx
jmp   check_to_remove_posts
last_smaller_than_startfirst:
mov   dx, di
;// Post is entirely visible (above start),  so insert a new clippost.
call  R_StoreWallRange_          ; 			R_StoreWallRange (first, last);
mov   ax, cx                     ;        backup first
mov   cx, word ptr ds:[_newend]     
add   cx, 8
mov   word ptr ds:[_newend], cx

; rep movsw setup
mov   bx, ds
mov   es, bx         ; set es
mov   bx, si         ; backup si
mov   dx, di         ; backup di

; must copy from end to start!

std
mov   di, cx         ; set dest
sub   cx, si         ; count
lea   si, [di - 4]   ; set source
sar   cx, 1          ; set count in words
rep   movsw
cld

; ax = dest, dx = source, bx = count?

mov   word ptr ds:[bx + 2], dx
mov   word ptr ds:[bx], ax
write_back_newend_and_return:

ret   

do_final_fragment:
;    // There is a fragment after *next.
mov   ax, word ptr ds:[bx + 2]
mov   dx, di
inc   ax
call  R_StoreWallRange_
mov   word ptr ds:[si + 2], di
jmp   crunch

done_removing_posts:
    
mov   word ptr ds:[_newend], di   ; newend = start+1;

ret   

ENDP

;R_ClipPassWallSegment_

PROC R_ClipPassWallSegment_ NEAR
PUBLIC R_ClipPassWallSegment_ 

; input: ax = first (transferred to si)
;        dx = last (transferred to cx)

mov  si, ax
mov  cx, dx
dec  ax
;    start = solidsegs;
 
mov  bx, OFFSET _solidsegs
cmp  ax, word ptr ds:[bx + 2]

;while (start->last < first - 1) {
;   start++;
;}


jle  found_start
keep_searching_for_start:
add  bx, 4
cmp  ax, word ptr ds:[bx + 2]
jg   keep_searching_for_start

found_start:
;    if (first < start->first) {

mov  ax, word ptr ds:[bx]  ; ax = start->first
cmp  si, ax
jge  check_last

;		if (last < start->first-1) {
mov  dx, ax
dec  dx
cmp  cx, dx
jl   post_entirely_visible

; There is a fragment above *start.
mov  ax, si
call R_StoreWallRange_

check_last:

;   // Bottom contained in start?
;	if (last <= start->last) {
;		return;			
;	}


cmp  cx, word ptr ds:[bx + 2]
jle  do_clippass_exit
check_next_fragment:
mov  dx, word ptr ds:[bx + 4]
dec  dx
cmp  cx, dx
mov  ax, word ptr ds:[bx + 2]
jl   fragment_after_next
inc  ax
add  bx, 4
;  There is a fragment between two posts.

call R_StoreWallRange_
cmp  cx, word ptr ds:[bx + 2]
jg   check_next_fragment
do_clippass_exit:
ret  
post_entirely_visible:
mov  dx, cx
mov  ax, si
call R_StoreWallRange_
ret  

fragment_after_next:

mov  dx, cx
inc  ax
call R_StoreWallRange_
ret  


ENDP



;segment_t __near R_GetColumnSegment (int16_t tex, int16_t col, int8_t segloopcachetype) 

update_both_cache_texes:
; bx is 6E8
; _cachedtex is bx - 010h
; _cachedcollength is bx - 0Ch

;			if (cachedtex2 != tex){
;				int16_t  cached_nextlookup = segloopnextlookup[segloopcachetype]; 
;				cachedtex2 = cachedtex;
;				cachedsegmenttex2 = cachedsegmenttex;
;				cachedcollength2 = cachedcollength;
;				cachedtex = tex;
;				cachedsegmenttex = R_GetCompositeTexture(cachedtex);
;				cachedcollength = collength;
;				// restore these if composite texture is unloaded...
;				segloopnextlookup[segloopcachetype]     = cached_nextlookup; 
;				seglooptexrepeat[segloopcachetype] 		= loopwidth;

; ax already cached tex 1
; di already bp - 2 (segloopcachetype) shifted left once
mov       word ptr ds:[bx - 010h+2], ax

mov       ax, word ptr ds:[bx]
mov       word ptr ds:[bx+2], ax
mov       dx, word ptr ds:[di + _segloopnextlookup]   ; cached_next_lookup.
mov       al, byte ptr ds:[bx - 0Ch]        ; _cachedcollength
mov       byte ptr ds:[bx - 0Ch+1], al
mov       byte ptr ds:[bx - 0Ch], cl
xchg      ax, si                    ; was word ptr bp - 4/tex
mov       word ptr ds:[bx - 010h], ax
;call      R_GetCompositeTexture_
db 0FFh  ; lcall[addr]
db 01Eh  ;
dw _R_GetCompositeTexture_addr

mov       word ptr ds:[bx], ax   ; write back cachedsegmenttex and store in ax

mov       word ptr ds:[di + _segloopnextlookup], dx
mov       word ptr ds:[di + _segloopcachedsegment], ax  ; write this here now while duped.. skip the write later
shr       di, 1
pop       dx ;  , byte ptr [bp - 0Ah]             ; loopwidth
mov       byte ptr ds:[di + _seglooptexrepeat], dl

jmp       done_setting_cached_tex_skip_cachedsegwrite

lump_greater_than_zero_add_startpixel:
;			segloopcachedbasecol[segloopcachetype] = basecol + startpixel;

mov       di, TEXTURECOLUMNLUMPS_BYTES_SEGMENT ; todo cacheable above?
mov       es, di
mov       bl, byte ptr es:[bx - 1]
xor       bh, bh

add       bx, word ptr [bp - 6]
segloopcachedbasecol_set:

; write the segloopcachedbasecol[segloopcachetype] calculated above!



mov       di, word ptr [bp - 2]  ; segloopcachetype
mov       byte ptr ds:[di + _seglooptexrepeat], 0    ; todo any known 0? maybe ah from subtractor
sal       di, 1
mov       word ptr ds:[di + _segloopcachedbasecol], bx

;		// prev RLE boundary. Hit this function again to load next texture if we hit this.
;		segloopprevlookup[segloopcachetype]     = runningbasetotal - subtractor;
;		// next RLE boundary. see above
;		segloopnextlookup[segloopcachetype]     = runningbasetotal; 
;		// this is not a single repeating texture 
;		seglooptexrepeat[segloopcachetype] 		= 0;

mov       word ptr ds:[di + _segloopnextlookup], dx
sub       dx, ax  ; subtractor
mov       word ptr ds:[di + _segloopprevlookup], dx


;	if (lump > 0){
jmp       done_with_loopwidth
do_cache_tex_miss:
; bx is _cachedsegmenttex (6E8)
; _cachedtex is 6D8 (bp - 010h)
; 

; ax is cachedtex
mov       dx, word ptr ds:[bx - 010h +2]  ; _cachedtex+2
cmp       dx, si
jne       update_both_cache_texes   ; takes in di as bp - 2 shifted

swap_tex1_tex2:
; ax  is cachedtex
; dx  is cachedtex2

;	// cycle cache so 2 = 1
;    tex = cachedtex;
;    cachedtex = cachedtex2;
;    cachedtex2 = tex;

mov       word ptr ds:[bx - 010h ],  dx     ; _cachedtex
mov       word ptr ds:[bx - 010h +2], ax    ; _cachedtex + 2

;    tex = cachedsegmenttex;
;    cachedsegmenttex = cachedsegmenttex2;
;    cachedsegmenttex2 = tex;

mov       ax, word ptr ds:[bx - 0Ch]  ; _cachedcollength
xchg      al, ah        ; swap byte 1 and 2
mov       word ptr ds:[bx - 0Ch], ax

;    tex = cachedcollength;
;    cachedcollength = cachedcollength2;
;    cachedcollength2 = tex;

mov      ax, word ptr ds:[bx]
xchg     ax, word ptr ds:[bx+2]
mov      word ptr ds:[bx], ax

jmp       done_setting_cached_tex
lump_greater_than_zero:
;				texcol -= subtractor; // is this correct or does it have to be bytelow direct?
sub       byte ptr [bp - 8], al         ; al still subtractor
done_with_lump_check:
add       bx, 4                     ; n+= 2
test      cx, cx
jge       loop_next_col_subtractor

done_finding_col_lookup:

;		startpixel = texturecolumnlump[n-1].bu.bytehigh;

;		if (lump > 0){
test      si, si
jg        lump_greater_than_zero_add_startpixel

;			segloopcachedbasecol[segloopcachetype] = runningbasetotal - textotal;
mov       bx, dx
sub       bx, di

jmp       segloopcachedbasecol_set
loopwidth_zero:

;		uint8_t startpixel;
;		int16_t subtractor;
;		int16_t textotal = 0;
;		int16_t runningbasetotal = basecol;
;		int16_t n = 0;


; dx still basecol
xor       di, di
test      cx, cx
jl        done_finding_col_lookup


;		while (col >= 0) {
;			//todo: gross. clean this up in asm; there is a 256 byte case that gets stored as 0.
;			// should we change this to be 256 - the number? we dont want a branch.
;			// anyway, fix it in asm
;			subtractor = texturecolumnlump[n+1].bu.bytelow + 1;
;			runningbasetotal += subtractor;
;			lump = texturecolumnlump[n].h;
;			col -= subtractor;
;			if (lump >= 0){ // should be equiv to == -1?
;				texcol -= subtractor; // is this correct or does it have to be bytelow direct?
;			} else {
;				textotal += subtractor; // add the last's total.
;			}
;			n += 2;
;		}

loop_next_col_subtractor:
mov       al, byte ptr es:[bx + 2]      ; subtractor
xor       ah, ah                        ; todo cbw probably safe
inc       ax
mov       si, word ptr es:[bx]          ; lump = texturecolumnlump[n].h;
; ax is subtractor..
add       dx, ax                        ; dx is runningbasetotal
sub       cx, ax                        ; cx is col
test      si, si
jge       lump_greater_than_zero
add       di, ax                        ; di is textotal
jmp       done_with_lump_check
update_tex_caches_and_return:
; not a lump
; di is bp - 2 shifted onces
mov       si, word ptr [bp - 4]        ; si = tex
mov       bx, OFFSET _cachedsegmenttex ; used a lot in the branches.
mov       ax, TEXTURECOLLENGTH_SEGMENT
mov       es, ax
mov       ax, word ptr ds:[_cachedtex]          ; probably dont LES. it makes the most common case slower.
mov       cl, byte ptr es:[si]                  ; cl stores texturecollength
cmp       ax, si
jne       do_cache_tex_miss

mov       ax, word ptr ds:[bx]

done_setting_cached_tex:
; di is index (shifted left one)
;	segloopcachedsegment[segloopcachetype]  = cachedsegmenttex;
;	return cachedsegmenttex + (FastMul8u8u(cachedcollength , texcol));

; ax is ds:[bx]
mov       word ptr ds:[di + _segloopcachedsegment], ax
sar       di, 1
done_setting_cached_tex_skip_cachedsegwrite:
mov       byte ptr ds:[di + _segloopheightvalcache], cl ; write now

xchg      ax, dx
mov       al, byte ptr ds:[bx - 0Ch] ; _cachedcollenght
mul       byte ptr [bp - 8]
add       ax, dx
LEAVE_MACRO     
pop       di
pop       si
pop       cx
ret  

PROC R_GetColumnSegment_ NEAR
PUBLIC R_GetColumnSegment_


; bp - 2      segloopcachetype
; bp - 4      ax/tex
; bp - 6      basecol
; bp - 8      texcol
; bp - 0Ah    loopwidth


push      cx
push      si
push      di
push      bp
mov       bp, sp
push      bx        ; bh always zero
push      ax


;	col &= texturewidthmasks[tex];
;	basecol -= col;
;	texcol = col;


mov       cx, dx
xor       ch, ch  ; todo necessary
mov       di, ax
mov       ax, TEXTUREWIDTHMASKS_SEGMENT
mov       es, ax
and       cl, byte ptr es:[di]
sal       di, 1
mov       bx, word ptr ds:[_texturepatchlump_offset + di]

;	texturecolumnlump = &(texturecolumnlumps_bytes[texturepatchlump_offset[tex]]);
;	loopwidth = texturecolumnlump[1].bu.bytehigh;

mov       ax, TEXTURECOLUMNLUMPS_BYTES_SEGMENT
mov       es, ax
sal       bx, 1
sub       dx, cx
push      dx     ; bp - 6   basecol
mov       al, byte ptr es:[bx + 3]  ; [1].bu.bytehight
push      cx     ; bp - 8   texcol
push      ax     ; bp - 0Ah loopwidth?
test      al, al
je        loopwidth_zero

loopwidth_nonzero:

;		lump = texturecolumnlump[0].h;
;		segloopcachedbasecol[segloopcachetype]  = basecol;
;		seglooptexrepeat[segloopcachetype] 		= loopwidth; // might be 256 and we need the modulo..

mov       si, word ptr es:[bx]    ; lump
mov       di, word ptr [bp - 2]
mov       byte ptr ds:[di + _seglooptexrepeat], al      ; al still loopwidth
sal       di, 1
mov       word ptr ds:[di + _segloopcachedbasecol], dx  ; dx still basecol

done_with_loopwidth:
test      si, si
jle       update_tex_caches_and_return
; nonzero lump

;		int16_t  cachelumpindex;
;		int16_t  cached_nextlookup;
;		uint8_t heightval = patchheights[lump-firstpatch];
;		heightval &= 0x0F;


xor       bx, bx  ; todo mov cachedlumps

;		for (cachelumpindex = 0; cachelumpindex < NUM_CACHE_LUMPS; cachelumpindex++){

cmp       si, word ptr ds:[_cachedlumps]
je        cachedlumphit



loop_check_next_cached_lump:
add       bx, 2
cmp       bx, (2 * NUM_CACHE_LUMPS)
jge       cache_miss_move_all_cache_back
;			if (lump == cachedlumps[cachelumpindex]){
cmp       si, word ptr ds:[bx + _cachedlumps]
jne       loop_check_next_cached_lump
cachedlumphit:
test      bx, bx
jne       not_cache_0
found_cached_lump:

;		if (col < 0){
;			uint16_t patchwidth = patchwidths[lump-firstpatch];
;			if (patchwidth > texturewidthmasks[tex]){
;				patchwidth = texturewidthmasks[tex];
;				patchwidth++;
;			}
;		}
sub       si, word ptr ds:[_firstpatch] ; si now is lump - firstpatch

test      cx, cx
jge       col_not_under_zero
mov       bx, PATCHWIDTHS_SEGMENT
mov       es, bx
xor       ax, ax
cwd                                     ; zero dh
mov       al, byte ptr es:[si]
cmp       al, 1                         ; set carry if al is 0
adc       ah, ah                        ; if width is zero that encoded 0x100. now ah is 1.
mov       bx, TEXTUREWIDTHMASKS_SEGMENT
mov       es, bx
mov       bx, word ptr [bp - 4]      ; tex
mov       dl, byte ptr es:[bx]
cmp       ax, dx    ; dh zeroed earlier
;			if (patchwidth > texturewidthmasks[tex]){
jna       negative_modulo_thing
;				patchwidth = texturewidthmasks[tex];
xchg      ax, dx
inc       ax

;			while (col < 0){
;				col+= patchwidth;
;			}
; todo just and patchwidth -1

negative_modulo_thing:
add       cx, ax        
jl      negative_modulo_thing
col_not_under_zero:


mov       dx, PATCHHEIGHTS_SEGMENT
mov       es, dx

mov       dl, byte ptr es:[si]
and       dl, 0Fh

mov       bx, word ptr [bp - 2]

mov       byte ptr ds:[bx + _segloopheightvalcache], dl
sal       bx, 1
mov       ax, word ptr ds:[_cachedsegmentlumps]
mov       word ptr ds:[bx + _segloopcachedsegment], ax

xchg      ax, cx
mul       dl
add       ax, cx
LEAVE_MACRO     
pop       di
pop       si
pop       cx
ret    










not_cache_0:

;    segment_t usedsegment = cachedsegmentlumps[cachelumpindex];
;    int16_t cachedlump = cachedlumps[cachelumpindex];
;    int16_t i;
xchg      ax, si
mov       di, OFFSET _cachedsegmentlumps
mov       si, OFFSET _cachedlumps
push      word ptr ds:[bx + si]
push      word ptr ds:[bx + di]

;    for (i = cachelumpindex; i > 0; i--){
;        cachedsegmentlumps[i] = cachedsegmentlumps[i-1];
;        cachedlumps[i] = cachedlumps[i-1];
;    }


jle       done_moving_cachelumps

loop_move_cachelump:
sub       bx, 2
push      word ptr ds:[bx + di]
push      word ptr ds:[bx + si]
pop       word ptr ds:[bx + si + 2]
pop       word ptr ds:[bx + di + 2]
jg        loop_move_cachelump
done_moving_cachelumps:

pop       word ptr ds:[di]
pop       word ptr ds:[si]
xchg      ax, si ; restore lump

jmp       found_cached_lump


;		// not found, set cache.
;		cachedsegmentlumps[3] = cachedsegmentlumps[2];
;		cachedsegmentlumps[2] = cachedsegmentlumps[1];
;		cachedsegmentlumps[1] = cachedsegmentlumps[0];
;		cachedlumps[3] = cachedlumps[2];
;		cachedlumps[2] = cachedlumps[1];
;		cachedlumps[1] = cachedlumps[0];
cache_miss_move_all_cache_back:
mov       ax, ds
mov       es, ax
xchg      ax, si
mov       si, OFFSET _cachedsegmentlumps
lea       di, [si + 2]
; _cachedsegmentlumps and _cachedlumps are adjacent. we hit both with 7 word copies.
;_cachedsegmentlumps =                   _NULL_OFFSET + 00698h
;_cachedlumps =                 	     _NULL_OFFSET + 006A0h
; doing 7 movsw breaks things
movsw
movsw
movsw
mov       si, di
lea       di, [si + 2]
movsw
movsw
movsw
mov       si, ax    ; restore lump
mov       di, word ptr [bp - 2]
sal       di, 1
mov       bx, word ptr ds:[di + _segloopnextlookup]
mov       dx, 0FFh
; ax is lump
;call      R_GetPatchTexture_
db 0FFh  ; lcall[addr]
db 01Eh  ;
dw _R_GetPatchTexture_addr
mov       word ptr ds:[_cachedsegmentlumps], ax
mov       word ptr ds:[di + _segloopnextlookup], bx
sar       di, 1
mov       al, byte ptr [bp - 0Ah]
mov       word ptr ds:[_cachedlumps], si
mov       byte ptr ds:[di + _seglooptexrepeat], al
jmp       found_cached_lump
   
    
ENDP


FRACUNIT_OVER_2 = 08000h
BASEYCENTER  = 100

;R_DrawPSprite_


;void __near R_DrawPSprite (pspdef_t __near* psp, 

; BX is pointer to pspdef_t
; AX is spritenum
; CX is frame
; SI is vissprite_t ptr

PROC R_DrawPSprite_ NEAR
PUBLIC R_DrawPSprite_ 


; bp - 2      frame (arg)
; bp - 4      tx    fracbits
; bp - 6      tx    intbits
; bp - 8      psp
; bp - 0Ah    flip
; bp - 0Ch    spriteindex
; bp - 0Eh    temp  intbits
; bp - 010h   usedwidth

push  bp
mov   bp, sp
push  cx   ; bp - 2

xor   ah, ah
mov   di, ax
sal   ax, 1
add   di, ax  ; shifted 3

push  word ptr ds:[bx + 4]         ; bp - 4  tx fracbits
push  word ptr ds:[bx + 6]         ; bp - 6  tx intbits
push  bx                        ; bp - 8


mov   ax, SPRITES_SEGMENT
mov   es, ax

and   cx, FF_FRAMEMASK

; spriteframe_t is 25 bytes in size. get offset...




IF COMPISA GE COMPILE_186
imul  bx, cx, SIZEOF_SPRITEFRAME_T
mov   di, word ptr es:[di]       ; get spriteframesOffset from spritedef_t
push  word ptr es:[bx + di + 010h]    ; 0Ah
mov   bx, word ptr es:[di + bx]       ; get spriteindex

ELSE
mov   al, SIZEOF_SPRITEFRAME_T
mul   cl
mov   di, word ptr es:[di]       ; get spriteframesOffset from spritedef_t
add   di, ax
push  word ptr es:[di + 010h]    ; 0Ah
mov   bx, word ptr es:[di]       ; get spriteindex
ENDIF



;	spriteframes = (spriteframe_t __far*)&(spritedefs_bytes[sprites[sprite].spriteframesOffset]);

push  bx                         ; 0Ch
sub   sp, 4

mov   ax, SPRITEOFFSETS_SEGMENT
mov   es, ax
mov   al, byte ptr es:[bx] ; spriteoffsets[spriteindex]
xor   ah, ah
SELFMODIFY_BSP_centerx_7:
mov   di, 01000h

;	tx.h.intbits += spriteoffsets[spriteindex];
sub   ax, 160;  -160 * fracunit
add   word ptr [bp - 6], ax

SELFMODIFY_BSP_pspritescale_1:
mov   bx, 01000h
SELFMODIFY_BSP_pspritescale_1_AFTER = SELFMODIFY_BSP_pspritescale_1+2
pspritescale_nonzero_1:
mov   ax, word ptr [bp - 4]

; inlined FixedMul16u32_

MUL  BX        ; AX * BX

mov   ax, word ptr [bp - 6]

MOV  CX, DX    ; CX stores low word
CWD            ; S1 in DX
AND  DX, BX    ; S1 * AX
NEG  DX        ; 
XCHG DX, BX    ; AX into DX, high word into BX
MUL  DX        ; AX*CX
ADD AX, CX     ; add low word
ADC DX, BX     ; add high word

adc   di, dx
jmp   x1_calculcated
SELFMODIFY_BSP_pspritescale_1_TARGET:
pspritescale_zero_1:
mov   ax, word ptr [bp - 4]
add   di, word ptr [bp - 6]
x1_calculcated:
mov   bx, word ptr [bp - 0Ch]
mov   es, word ptr ds:[_spritewidths_segment]
mov   al, byte ptr es:[bx]
xor   ah, ah
mov   word ptr [bp - 0Eh], di
cmp   ax, 1
jne   usedwidth_not_1_2
mov   ax, 256     ; hardcoded special case value..  todo make constant

usedwidth_not_1_2:
mov   word ptr [bp - 010h], ax
add   word ptr [bp - 6], ax
SELFMODIFY_BSP_centerx_8:
mov   di, 01000h

SELFMODIFY_BSP_pspritescale_2:
mov   bx, 01000h
SELFMODIFY_BSP_pspritescale_2_AFTER = SELFMODIFY_BSP_pspritescale_2 + 2

pspritescale_nonzero_2:
mov   ax, word ptr [bp - 4]

; inlined FixedMul16u32_ ; todo 386 bit version

MUL  BX        ; AX * BX

mov  AX, word ptr [bp - 6] ; load cx into ax directly...

MOV  CX, DX    ; CX stores low word
CWD            ; S1 in DX
AND  DX, BX    ; S1 * AX
NEG  DX        ; 
XCHG DX, BX    ; AX into DX, high word into BX
MUL  DX        ; AX*CX
ADD AX, CX     ; add low word
ADC DX, BX     ; add high word

add   di, dx
jmp   x2_calculcated

SELFMODIFY_BSP_pspritescale_2_TARGET:
pspritescale_zero_2:
mov   ax, word ptr [bp - 4]
add   di, word ptr [bp - 6]


x2_calculcated:
mov   ax, SPRITETOPOFFSETS_SEGMENT
mov   bx, word ptr [bp - 0Ch]
mov   es, ax
mov   al, byte ptr es:[bx]
lea   dx, [di - 1]
cbw  
mov   di, ax

;        // hack to make this fit in 8 bits, check r_init.c
;    if (temp.h.intbits == -128){
;        temp.h.intbits = 129;
;    }

cmp   ax, -128  ; hack to fit data in 8 bits
jne   tempbits_not_minus128
mov   di, 129   ; hack to fit data in 8 bits

tempbits_not_minus128:
mov   bx, word ptr [bp - 8]
les   ax, dword ptr ds:[bx + 8]
mov   cx, es
mov   bx, FRACUNIT_OVER_2
sbb   cx, di
sub   bx, ax
mov   ax, BASEYCENTER
sbb   ax, cx
mov   word ptr ds:[si + 024h], ax
mov   ax, word ptr [bp - 0Eh]
mov   word ptr ds:[si + 022h], bx
test  ax, ax

;    vis->x1 = x1 < 0 ? 0 : x1;
;    vis->x2 = x2 >= viewwidth ? viewwidth-1 : x2;       


jge   x1_positive_2
xor   ax, ax

x1_positive_2:
mov   word ptr ds:[si + 2], ax

SELFMODIFY_BSP_viewwidth_4:
mov   ax, 01000h
cmp   dx, ax
jge   x2_smaller_than_viewwidth_2

mov   ax, dx
jmp   vis_x2_set

x2_smaller_than_viewwidth_2:
dec   ax
vis_x2_set:
mov   word ptr ds:[si + 4], ax
SELFMODIFY_BSP_pspritescale_3:
mov   ax, 01000h
SELFMODIFY_BSP_pspritescale_3_AFTER = SELFMODIFY_BSP_pspritescale_3 + 2
pspritescale_nonzero_3:
xor   dx, dx

jmp   shift_visscale

SELFMODIFY_BSP_pspritescale_3_TARGET:
pspritescale_zero_3:
mov   dx, 1
xor   ax, ax

shift_visscale:

SELFMODIFY_BSP_detailshift_6:
shl   ax, 1
rcl   dx, 1
shl   ax, 1
rcl   dx, 1

mov   word ptr ds:[si + 01Ah], ax
mov   word ptr ds:[si + 01Ch], dx

SELFMODIFY_BSP_pspriteiscale_lo_1:
mov   bx, 01000h
SELFMODIFY_BSP_pspriteiscale_hi_1:
mov   cx, 01000h

cmp   byte ptr [bp - 0Ah], 0       ; check flip
jne   flip_on

flip_off:

mov   word ptr ds:[si + 016h], 0
mov   word ptr ds:[si + 018h], 0
jmp   vis_startfrac_set

flip_on:

neg   cx
neg   bx
sbb   cx, 0


; mov ax, 0; add ax, -1; adc di, -1 optimized 

mov   ax, word ptr [bp - 010h]
dec   ax
mov   word ptr ds:[si + 016h], -1
mov   word ptr ds:[si + 018h], ax

vis_startfrac_set:
mov   word ptr ds:[si + 01Eh], bx
mov   word ptr ds:[si + 020h], cx

mov   ax, word ptr ds:[si + 2]
cmp   ax, word ptr [bp - 0Eh]
jle   vis_x1_greater_than_x1_2
sub   ax, word ptr [bp - 0Eh]

; inlined FastMul16u32u_

IF COMPISA GE COMPILE_386


   ; set up ecx
   db 066h, 0C1h, 0E3h, 010h        ; shl  ebx, 0x10
   db 066h, 00Fh, 0A4h, 0D9h, 010h  ; shld ecx, ebx, 0x10

   ; set up eax
   db 066h, 098h                    ; cwde (prepare AX)

   ; actual mul
   db 066h, 0F7h, 0E1h              ; mul ecx
   ; set up return
   db 066h, 00Fh, 0A4h, 0C2h, 010h  ; shld edx, eax, 0x10
   

ELSE

   XCHG CX, AX    ; AX stored in CX
   MUL  CX        ; AX * CX
   XCHG CX, AX    ; store low product to be high result. Retrieve orig AX
   MUL  BX        ; AX * BX
   ADD  DX, CX    ; add 
ENDIF

add   word ptr ds:[si + 016h], ax
adc   word ptr ds:[si + 018h], dx
vis_x1_greater_than_x1_2:
mov   bx, word ptr [bp - 0Ch]
mov   word ptr ds:[si + 026h], bx

;    if (player.powers[pw_invisibility] > 4*32

cmp   word ptr ds:[_player + 01Eh + 2 * PW_INVISIBILITY], (4*32)
jg    mark_shadow_draw
test  byte ptr ds:[_player + 01Eh + 2 * PW_INVISIBILITY], 8
jne   mark_shadow_draw

SELFMODIFY_BSP_fixedcolormap_4:
jmp   use_fixedcolormap
SELFMODIFY_BSP_fixedcolormap_4_AFTER:
test  byte ptr [bp - 2], FF_FULLBRIGHT
je    set_vis_colormap
SELFMODIFY_BSP_fixedcolormap_4_TARGET:
use_fixedcolormap:
SELFMODIFY_BSP_fixedcolormap_5:
mov   byte ptr ds:[si + 1], 00h

LEAVE_MACRO
ret   



mark_shadow_draw:
; do shadow draw
mov   byte ptr ds:[si + 1], COLORMAP_SHADOW
LEAVE_MACRO
ret   


set_vis_colormap:
mov   ax, SCALELIGHTFIXED_SEGMENT   ; todo dont use segment
SELFMODIFY_set_spritelights_2:
mov   bx, 01000h
mov   es, ax
mov   al, byte ptr es:[bx + (MAXLIGHTSCALE-1)]
mov   byte ptr ds:[si + 1], al
LEAVE_MACRO
ret   


ENDP

;R_PrepareMaskedPSprites_

PROC R_PrepareMaskedPSprites_ NEAR
PUBLIC R_PrepareMaskedPSprites_ 

push  bx
push  cx
push  dx
push  si ; used in inner functions.
push  di

mov   bx, word ptr ds:[_r_cachedplayerMobjsecnum]
mov   ax, SECTORS_SEGMENT


SHIFT_MACRO shl bx 4



mov   es, ax
mov   al, byte ptr es:[bx + 0Eh]  ; sector lightlevel byte offset
xor   ah, ah
mov   dx, ax


SHIFT_MACRO sar dx 4


SELFMODIFY_BSP_extralight3:
mov   al, 0
add   ax, dx
cmp   al, 240   ; checking if its < 0, by checking if its above max possible
ja    use_spritelights_zero
cmp   al, LIGHTLEVELS
jb    calculate_spritelights
; use max spritelight
mov    ax, 720   ; hardcoded (lightmult48lookup[LIGHTLEVELS - 1])
player_spritelights_set:
mov   word ptr cs:[SELFMODIFY_set_spritelights_2 + 1], ax 



first_iter:

mov   bx, word ptr ds:[_psprites]
cmp   bx, STATENUM_NULL
je    sprite_1_null
sal   bx, 1
mov   ax, STATES_RENDER_SEGMENT
mov   es, ax
mov   si, OFFSET _player_vissprites
mov   ax, word ptr es:[bx]
mov   cl, ah
mov   bx, OFFSET _psprites
call  R_DrawPSprite_
sprite_1_null:

second_iter:

mov   bx, word ptr ds:[_psprites + 0Ch]
cmp   bx, -1
je    sprite_2_null
sal   bx, 1
mov   ax, STATES_RENDER_SEGMENT
mov   es, ax
mov   si, OFFSET _player_vissprites + 028h
mov   ax, word ptr es:[bx]
mov   cl, ah
mov   bx, OFFSET _psprites + 0Ch
call  R_DrawPSprite_
sprite_2_null:

pop   di
pop   si
pop   dx
pop   cx
pop   bx
ret  

use_spritelights_zero:
xor   ax, ax
jmp   player_spritelights_set
calculate_spritelights:
mov   ah, 48
mul   ah
mov   word ptr cs:[SELFMODIFY_set_spritelights_2 + 1], ax 
jmp   first_iter


ENDP

;R_PointToAngle16_


; params cx, dx. ax/bx get zeroed/clobbered.
PROC R_PointToAngle16_ NEAR
PUBLIC R_PointToAngle16_ 


xor  ax, ax
mov  bx, ax
SELFMODIFY_BSP_viewx_lo_5:
sub  ax, 01000h
SELFMODIFY_BSP_viewx_hi_5:
sbb  dx, 01000h
SELFMODIFY_BSP_viewy_lo_5:
sub  bx, 01000h
SELFMODIFY_BSP_viewy_hi_5:
sbb  cx, 01000h


call R_PointToAngle_


ret  

ENDP

R_CHECKBBOX_SWITCH_JMP_TABLE:

dw R_CBB_SWITCH_CASE_00, R_CBB_SWITCH_CASE_01, R_CBB_SWITCH_CASE_02, R_CBB_SWITCH_CASE_03
dw R_CBB_SWITCH_CASE_04, R_CBB_SWITCH_CASE_05, R_CBB_SWITCH_CASE_06, R_CBB_SWITCH_CASE_07
dw R_CBB_SWITCH_CASE_08, R_CBB_SWITCH_CASE_09, R_CBB_SWITCH_CASE_10

;R_CheckBBox_

PROC R_CheckBBox_ NEAR
PUBLIC R_CheckBBox_ 

; todo should this inline in R_RenderBSPNode_? used once...

; jmp table for switch block.... 


; es:bx is bsp lookup

push  bx
push  cx
push  si
push  di
mov   bx, ax

;es:[bx] is bspcoord
;	// Find the corners of the box
;	// that define the edges from current viewpoint.

SELFMODIFY_BSP_viewx_hi_4:
mov   ax, 01000h
cmp   ax, word ptr es:[bx + 4]         ; bspcoord[BOXLEFT]

SELFMODIFY_BSP_viewx_lo_4:
jge   viewx_greater_than_left    ; 7d xx
SELFMODIFY_BSP_viewx_lo_4_AFTER:
set_boxx_0:
mov   dl, 0
check_boxy:

SELFMODIFY_BSP_viewy_hi_4:
mov   ax, 01000h
cmp   ax, word ptr es:[bx]         ; bspcoord[BOXTOP]
jl    viewy_less_than_top
xor   ax, ax
boxy_calculated:
SHIFT_MACRO shl al 2
add   al, dl
cmp   al, 5
je    return_1
xor   ah, ah
mov   di, ax
add   di, ax
; switch block jump
jmp   word ptr cs:[di + R_CHECKBBOX_SWITCH_JMP_TABLE]
SELFMODIFY_BSP_viewx_lo_4_TARGET_2:
; jmp here if viewx lobits are 0.
viewx_greater_than_left:
cmp   ax, word ptr es:[bx + 4]         ; bspcoord[BOXLEFT]
jne   boxx_check_2nd_expression
jmp   set_boxx_0
; jmp here if viewx lobits are nonzero.
SELFMODIFY_BSP_viewx_lo_4_TARGET_1:
boxx_check_2nd_expression:
; ax is already viewx hi
cmp   ax, word ptr es:[bx + 6]         ; bspcoord[BOXRIGHT]
jge   set_boxx_2
set_boxx_1:
mov   dl, 1
jmp   check_boxy
set_boxx_2:
mov   dl, 2
jmp   check_boxy
viewy_less_than_top:
cmp   ax, word ptr es:[bx + 2]         ; bspcoord[BOXBOTTOM]
SELFMODIFY_BSP_viewy_lo_4:
jle   boxy_check_2nd_expression
SELFMODIFY_BSP_viewy_lo_4_AFTER:
set_boxy_1:
mov   ax, 1
jmp   boxy_calculated
boxy_check_2nd_expression:
;cmp   word ptr ds:[_viewy], 0
;jle   set_boxy_2
; ax still viewy highbits
SELFMODIFY_BSP_viewy_lo_4_TARGET_2:
cmp   ax, word ptr es:[bx + 2]         ; bspcoord[BOXBOTTOM]
je    set_boxy_1
SELFMODIFY_BSP_viewy_lo_4_TARGET_1:
set_boxy_2:
mov   ax, 2
jmp   boxy_calculated
return_1:
mov   al, 1
pop   di
pop   si
pop   cx
pop   bx
ret   
R_CBB_SWITCH_CASE_00:
; cx
; di
; si
; dx
mov   ax, es

les   cx, dword ptr es:[bx]
mov   di, es

mov   es, ax
les   si, dword ptr es:[bx + 4]
mov   dx, es


R_CBB_SWITCH_CASE_05:  ; unused
boxpos_switchblock_done:
;	angle1.wu = R_PointToAngle16(x1, y1) - viewangle.wu;

; di holds 
call  R_PointToAngle16_
SELFMODIFY_BSP_viewangle_lo_3:
sub   ax, 01000h
SELFMODIFY_BSP_viewangle_hi_3:
sbb   dx, 01000h
;di:si stores angle1

; todo swap di/si order and do this in fewer ops
xchg  ax, si
xchg  dx, di      ; cache dx/angle1 intbits. retrieve old cx
mov   cx, dx
mov   dx, ax
;	angle2.wu = R_PointToAngle16(x2, y2) - viewangle.wu;

call  R_PointToAngle16_
;cx:si stores angle2
; di:si is angle1 currently
; ax:dx will be dspan

; todo/swap cx/dx roles. this mov doesnt have to happen.
mov   cx, dx
mov   dx, si

SELFMODIFY_BSP_viewangle_lo_4:
sub   ax, 01000h
SELFMODIFY_BSP_viewangle_hi_4:
sbb   cx, 01000h

mov   word ptr cs:[SELFMODIFY_BSP_forward_angle2_lobits+1], ax



;	span.wu = angle1.wu - angle2.wu;
; bx:si becomes span

sub   si, ax
mov   bx, di      ; angle1 intbits
sbb   bx, cx


;	// Sitting on a line?
;	if (span.hu.intbits >= ANG180_HIGHBITS){
;		return true;
;	}

; span low bits are in si
cmp   bx, ANG180_HIGHBITS
jae   return_1

;	tspan.wu = angle1.wu;
;	tspan.hu.intbits += clipangle;


SELFMODIFY_BSP_clipangle_7:
lea   ax, [di + 01000h]


; ax:dx is tspan.

;	if (tspan.hu.intbits > fieldofview) {
;		tspan.hu.intbits -= fieldofview;


SELFMODIFY_BSP_fieldofview_7:
cmp   ax, 01000h
jbe   done_with_first_tspan_adjustment
SELFMODIFY_BSP_fieldofview_8:
sub   ax, 01000h


;		// Totally off the left edge?
;		if (tspan.wu >= span.wu){
;			return false;
;		}


cmp   ax, bx
jb    tspan_smaller_than_span
je    check_tspan_vs_span_lobits

also_return_0:
xor   al, al
pop   di
pop   si
pop   cx
pop   bx
ret   

also_return_1:
mov   al, 1
pop   di
pop   si
pop   cx
pop   bx
ret   

check_tspan_vs_span_lobits:
cmp   dx, si  ; angle1 fracbits compare 
jae   also_return_0
tspan_smaller_than_span:

;		angle1.hu.intbits = clipangle;

SELFMODIFY_BSP_clipangle_5:
mov   di, 01000h
done_with_first_tspan_adjustment:

;	tspan.hu.intbits = clipangle
;	tspan.hu.fracbits= 0;
;	tspan.wu -= angle2.wu;
; cx:si was angle2

SELFMODIFY_BSP_clipangle_6:
mov   ax, 01000h
SELFMODIFY_BSP_forward_angle2_lobits:
;todo see if we can get away without needing this using enough register juggling?
mov   dx, 01000h
neg   dx
sbb   ax, cx

;	if (tspan.hu.intbits > fieldofview) {

SELFMODIFY_BSP_fieldofview_5:
cmp   ax, 01000h
jbe   done_with_second_tspan_adjustment

;		tspan.hu.intbits -= fieldofview;

SELFMODIFY_BSP_fieldofview_6:
sub   ax, 01000h

;		// Totally off the left edge?
;		if (tspan.wu >= span.wu){
;			return false;
;		}

cmp   ax, bx
ja    also_return_0
jne   tspan_smaller_than_span_2
; tspan fracbits are 0 - angle2 lobits. span lobits are [bp - 2]
cmp   dx, si
jbe   also_return_0           ; inverse check since si is inversed
tspan_smaller_than_span_2:

;		angle2.hu.intbits = -clipangle;

SELFMODIFY_BSP_clipangle_8:
mov   cx, 01000h
neg   cx

done_with_second_tspan_adjustment:

mov   dx, VIEWANGLETOX_SEGMENT
mov   es, dx
lea   si, [di + ANG90_HIGHBITS]
add   ch, (ANG90_HIGHBITS SHR 8)
SHIFT_MACRO shr si 2
mov   bx, cx
SHIFT_MACRO shr bx 2
and   si, 0FFFEh  ; need to and out the last bit. (is there a faster way?)
and   bl, 0FEh    ; need to and out the last bit. (is there a faster way?)
mov   si, word ptr es:[si]
mov   ax, word ptr es:[bx]
cmp   si, ax
je    also_return_0
dec   ax
mov   bx, OFFSET _solidsegs
cmp   ax, word ptr ds:[bx + 2]
jle   found_solidsegs
loop_find_solidsegs:
add   bx, 4
cmp   ax, word ptr ds:[bx + 2]
jg    loop_find_solidsegs
found_solidsegs:
cmp   si, word ptr ds:[bx]
jl    also_return_1
cmp   ax, word ptr ds:[bx + 2]
jg    also_return_1
return_0_2:
xor   al, al
pop   di
pop   si
pop   cx
pop   bx
ret   


R_CBB_SWITCH_CASE_01:
; di cx
; 
; si
; dx
mov   di, word ptr es:[bx]
mov   cx, di

les   si, dword ptr es:[bx+4]
mov   dx, es


jmp   boxpos_switchblock_done
R_CBB_SWITCH_CASE_02:

; di 
; cx
; si
; dx
mov   dx, es
les   di, dword ptr es:[bx]
mov   cx, es
mov   es, dx
les   si, dword ptr es:[bx+4]
mov   dx, es

jmp   boxpos_switchblock_done
R_CBB_SWITCH_CASE_03:
R_CBB_SWITCH_CASE_07:
; di cx si dx
mov   di, word ptr es:[bx]
mov   cx, di
mov   si, di
mov   dx, di
jmp   boxpos_switchblock_done
R_CBB_SWITCH_CASE_04:
; di 
; cx
; si dx
;
mov   si, word ptr es:[bx + 4]
mov   dx, si
les   cx, dword ptr es:[bx]
mov   di, es
jmp   boxpos_switchblock_done
R_CBB_SWITCH_CASE_06:
; di
; cx
;
; si dx
mov   si, word ptr es:[bx + 6]
mov   dx, si
les   di, dword ptr es:[bx]
mov   cx, es
jmp   boxpos_switchblock_done
R_CBB_SWITCH_CASE_08:
; cx
; di
; dx
; si
mov   dx, es
les   cx, dword ptr es:[bx]
mov   di, es
mov   es, dx
les   dx, dword ptr es:[bx+4]
mov   si, es

jmp   boxpos_switchblock_done
R_CBB_SWITCH_CASE_09:
;
; di cx
; dx
; si
mov   di, word ptr es:[bx + 2]
mov   cx, di
les   dx, dword ptr es:[bx+4]
mov   si, es

jmp   boxpos_switchblock_done
R_CBB_SWITCH_CASE_10:
; di
; cx
; dx
; si
mov   dx, es
les   di, dword ptr es:[bx]
mov   cx, es
mov   es, dx
les   dx, dword ptr es:[bx+4]
mov   si, es

jmp   boxpos_switchblock_done

ENDP

MAX_BSP_DEPTH = 64
NF_SUBSECTOR  = 08000h
NOT_NF_SUBSECTOR  = 07FFFh

;R_RenderBSPNode_

PROC R_RenderBSPNode_ NEAR
PUBLIC R_RenderBSPNode_ 


push  bx
push  cx
push  dx
push  si
push  di
push  bp
mov   bp, sp
sub   sp, ((MAX_BSP_DEPTH * 2) + (MAX_BSP_DEPTH * 1))
mov   bx, word ptr ds:[_numnodes]
xor   si, si      ; sp = 0
dec   bx          ; bx is bspnum = numnodes - 1

main_bsp_loop:
test  bh, (NF_SUBSECTOR SHR 8)
jne   after_inner_loop

; inner loop
mov   ax, NODES_SEGMENT
mov   es, ax
SELFMODIFY_BSP_viewx_hi_6:
mov   dx, 01000h
SELFMODIFY_BSP_viewy_hi_6:
mov   cx, 01000h


SHIFT_MACRO shl bx 3



;        int16_t dx = viewx.h.intbits - bsp->x;
;			int16_t dy = viewy.h.intbits - bsp->y;
;			int16_t intermediate = bsp->dy ^ dx;

sub   dx, word ptr es:[bx]
sub   cx, word ptr es:[bx + 2]
mov   ax, word ptr es:[bx + 6]
mov   di, cx

;			// check signs... if one side is positive and the other negative, then we dont need to multiply to 
;			// figure out which is larger
;			if ((intermediate ^ dy ^ bsp->dx) & 0x8000){

xor   di, dx
xor   di, ax
xor   di, word ptr es:[bx + 4]
test  di, 08000h ; sign check



je    calculate_larger_side

;				side = ROLAND1(intermediate);
xor   ax, dx   ; recalc intermediate
rol   ax, 1    ; ROLAND1
and   ax, 1
calculate_next_bspnum:

;		bspnum = node_children[bspnum].children[side ^ 1];
; side is ax (ah is 0)

mov   byte ptr [bp + si - 040h], al       ; stack_side
shr   bx, 1    ; bx is now bspnum * 4
sal   si, 1    ; shift for lookup
; stored preshifted.
mov   word ptr [bp + si - 0C0h], bx       ; stack_bsp lookup

sal   ax, 1
add   bx, ax   ; add side lookup
sar   si, 1    ; unshift
inc   si       ; 
mov   dx, NODE_CHILDREN_SEGMENT
mov   es, dx

mov   bx, word ptr es:[bx]   ; new bspnum lookup
jmp   main_bsp_loop
after_inner_loop:


cmp   bx, -1
jne   call_rsubsector_bspnum
xor   ax, ax
call_rsubsector:
call  R_Subsector_

;		if (sp == 0) {
;			//back at root node and not visible. All done!
;			return;
;		}

test  si, si
je    exit_renderbspnode

;		sp--;
;		bspnum = stack_bsp[sp];
;		side = stack_side[sp];

dec   si
mov   di, si
add   di, si   ; make di the word lookup
mov   bl, byte ptr [bp + si - 040h]  ; stack_side



;		// Possibly divide back space.
;		//Walk back up the tree until we find
;		//a node that has a visible backspace.

loop_check_bbox:
mov   cx, word ptr [bp + di - 0C0h]  ; stack_bsp lookup
xor   bl, 1       ; side ^ 1
xor   bh, bh
mov   dx, cx
; stack_bsp was stored preshifted..
SHIFT_MACRO sar dx 2
add   dh, (NODES_RENDER_SEGMENT SHR 8)
shl   bx, 1
mov   ax, bx   ; todo get rid of this. go to ax directly.
SHIFT_MACRO shl ax 2
mov   es, dx
call  R_CheckBBox_
test  al, al
je    exit_check_bbox_loop

mov   dx, NODE_CHILDREN_SEGMENT
mov   es, dx
add   bx, cx   ; cx preshifted 2
mov   bx, word ptr es:[bx]
jmp   main_bsp_loop


calculate_larger_side:
;				fixed_t left =	FastMul1616(bsp->dy, dx);
;				fixed_t right = FastMul1616(bsp->dx, dy);
;				side = right > left;

; dx is dx
; di is dy

; ax is already bsp->dy
imul  dx          ; dx is dx (ha)
mov   di, NODES_SEGMENT
mov   es, di

xchg  ax, cx              ; cx had dy. gets lobits.
mov   di, dx              ; store hibits. DI:CX is left
imul  word ptr es:[bx + 4]
cmp   dx, di
jg    right_is_greater
jne   left_is_greater
cmp   ax, cx
jbe   left_is_greater
right_is_greater:
mov   ax, 1
jmp   calculate_next_bspnum
left_is_greater:
xor   ax, ax
jmp   calculate_next_bspnum




call_rsubsector_bspnum:
mov   ax, bx
and   ah, (NOT_NF_SUBSECTOR SHR 8)  ; unnecessary, the shift killed this anyway.
jmp   call_rsubsector
exit_check_bbox_loop:
test  si, si
je    exit_renderbspnode
dec   di       ; di is the word lookup
dec   di
dec   si
mov   bl, byte ptr [bp + si - 040h]   ; stack_side lookup, following dec not included yet
jmp   loop_check_bbox
exit_renderbspnode:
LEAVE_MACRO
pop   di
pop   si
pop   dx
pop   cx
pop   bx
ret

ENDP


;R_RenderPlayerView_

PROC R_RenderPlayerView_ FAR
PUBLIC R_RenderPlayerView_ 



PUSHA_NO_AX_OR_BP_MACRO

;	r_cachedplayerMobjsecnum = playerMobj->secnum;
mov       bx, word ptr ds:[_playerMobj]
push      word ptr ds:[bx + 4]  ; playerMobj->secnum
pop       word ptr ds:[_r_cachedplayerMobjsecnum]

lds       si, dword ptr ds:[_playerMobj_pos]
mov       dx, ss
mov       es, dx
mov       di, OFFSET _viewx

mov       cx, 4
rep       movsw ; viewx, viewy

add       si, 6
mov       di, OFFSET _viewangle
movsw
lodsw     ; ax has viewangle hi
stosw

; cx is 0. write to something that is 0?


mov       ds, dx ; dx already had ds
shr       ax, 1
;	viewangle_shiftright1 = (viewangle.hu.intbits >> 1) & 0xFFFC;
and       al, 0FCh
mov       word ptr ds:[_viewangle_shiftright1], ax
mov       ax, word ptr ds:[_viewangle + 2]
SHIFT_MACRO shr       ax 3
mov       word ptr ds:[_viewangle_shiftright3], ax

;call      Z_QuickMapRender_
Z_QUICKMAPAI24 pageswapargs_rend_offset_size INDEXED_PAGE_4000_OFFSET
mov   byte ptr ds:[_currenttask], TASK_RENDER

; call      R_SetupFrame_
; INLINED setupframe



;    extralight = player.extralightvalue;
mov       al, byte ptr ds:[_player + 05Eh]  ; player.extralightvalue
mov       byte ptr ds:[_extralight], al

;    viewz = player.viewzvalue;
les       ax, dword ptr ds:[_player + 8] ; player.viewzvalue
mov       word ptr ds:[_viewz], ax
mov       word ptr ds:[_viewz + 2], es
mov       dx, es
;	viewz_shortheight = viewz.w >> (16 - SHORTFLOORBITS);

sal       ax, 1
rcl       dx, 1
sal       ax, 1
rcl       dx, 1
sal       ax, 1
rcl       dx, 1


mov       word ptr ds:[_viewz_shortheight], dx

;    if (player.fixedcolormapvalue) {

mov       al, byte ptr ds:[_player + 05Fh]
test      al, al
je        set_fixed_colormap_zero
jmp       set_fixed_colormap_nonzero
set_fixed_colormap_zero:
;		fixedcolormap = 0;
mov       byte ptr ds:[_fixedcolormap], al   ; al is zero

done_setting_colormap:

;    validcount_global++;
inc       word ptr ds:[_validcount_global]

;	destview = (byte __far*)(destscreen.w + viewwindowoffset);
les       ax, dword ptr ds:[_destscreen]
add       ax, word ptr ds:[_viewwindowoffset]
mov       word ptr ds:[_destview], ax
mov       word ptr ds:[_destview + 2], es



call      R_WriteBackFrameConstants_
call      R_ClearClipSegs_

mov       word ptr ds:[_ds_p],     SIZEOF_DRAWSEG_T             ; drawsegs_PLUSONE
mov       word ptr ds:[_ds_p + 2], DRAWSEGS_BASE_SEGMENT        ; nseed to be written because masked subs 02000h from it due to remapping...
call      R_ClearPlanes_
xor       ax, ax
mov       word ptr ds:[_vissprite_p], ax  ;

;    FAR_memset (cachedheight, 0, sizeof(fixed_t) * SCREENHEIGHT);

;call      NetUpdate_
db 0FFh  ; lcall[addr]
db 01Eh  ;
dw _NetUpdate_addr


mov       ax, word ptr ds:[_numnodes]
dec       ax

call      R_RenderBSPNode_
;call      NetUpdate_
db 0FFh  ; lcall[addr]
db 01Eh  ;
dw _NetUpdate_addr
call      R_PrepareMaskedPSprites_

;call      Z_QuickMapRenderPlanes_
Z_QUICKMAPAI3 pageswapargs_renderplane_offset_size INDEXED_PAGE_5000_OFFSET
Z_QUICKMAPAI1_NO_DX (pageswapargs_renderplane_offset_size+3) INDEXED_PAGE_9C00_OFFSET
Z_QUICKMAPAI4_NO_DX (pageswapargs_renderplane_offset_size+4) INDEXED_PAGE_7000_OFFSET


mov       ax, CACHEDHEIGHT_SEGMENT
mov       es, ax
xor       ax, ax
mov       di, ax  ; 0
mov       ax, ax  ; 0
mov       cx, 400

rep stosw 

cmp       byte ptr ds:[_visplanedirty], al   ; 0
jne       visplane_dirty_do_revert
done_with_visplane_revert:
call      dword ptr ds:[_R_DrawPlanesCall]
;call      Z_QuickMapUndoFlatCache_
Z_QUICKMAPAI8 pageswapargs_rend_texture_size           INDEXED_PAGE_5000_OFFSET
Z_QUICKMAPAI4_NO_DX pageswapargs_spritecache_offset_size     INDEXED_PAGE_9000_OFFSET
Z_QUICKMAPAI4_NO_DX (pageswapargs_spritecache_offset_size+4)   INDEXED_PAGE_7000_OFFSET
Z_QUICKMAPAI3_NO_DX pageswapargs_maskeddata_offset_size   	INDEXED_PAGE_8400_OFFSET


call      dword ptr ds:[_R_WriteBackMaskedFrameConstantsCall]
call      dword ptr ds:[_R_DrawMaskedCall]

;call      Z_QuickMapPhysics_
Z_QUICKMAPAI24 pageswapargs_phys_offset_size INDEXED_PAGE_4000_OFFSET
mov   byte ptr ds:[_currenttask], TASK_PHYSICS

;call      NetUpdate_
db 0FFh  ; lcall[addr]
db 01Eh  ;
dw _NetUpdate_addr

POPA_NO_AX_OR_BP_MACRO
retf      
set_fixed_colormap_nonzero:

;		fixedcolormap =  player.fixedcolormapvalue << 2; 
SHIFT_MACRO shl       al 2
mov       byte ptr ds:[_fixedcolormap], al

;		for (i=0 ; i<MAXLIGHTSCALE ; i++){
;			scalelightfixed[i] = fixedcolormap;
;		}

mov       ah, al


mov       cx, ds
mov       es, cx
mov       cx, MAXLIGHTSCALE / 2
mov       di, OFFSET _scalelightfixed
rep       stosw
;		for (i=0 ; i<MAXLIGHTSCALE ; i++){
;			scalelightfixed[i] = fixedcolormap;
;		}

jmp       done_setting_colormap

visplane_dirty_do_revert:
call      Z_QuickMapVisplaneRevert_BSPLocal_

jmp       done_with_visplane_revert

ENDP


; TODO: externalize this and R_ExecuteSetViewSize and its children to asm, load from binary
; todo: calculate the values here and dont store to variables.

;R_WriteBackViewConstants_

PROC R_WriteBackViewConstants_ FAR
PUBLIC R_WriteBackViewConstants_ 


; set ds to cs to make code smaller?
mov      ax, cs
mov      ds, ax


ASSUME DS:R_BSP_TEXT


mov      ax,  word ptr ss:[_detailshift]
add      ah, OFFSET _quality_port_lookup
mov      byte ptr ds:[SELFMODIFY_detailshift_plus1_1+3], ah

; for 16 bit shifts, modify jump to jump 4 for 0 shifts, 2 for 1 shifts, 0 for 0 shifts.

cmp      al, 1
jb       jump_to_set_to_zero ; 19h bytesish out of range.
je       set_to_one
jmp      set_to_two
jump_to_set_to_zero:
jmp      set_to_zero
set_to_two:
; detailshift 2 case. usually involves no shift. in this case - we just jump past the shift code.

; nop 
mov      ax, 0c089h 

mov      word ptr ds:[SELFMODIFY_BSP_detailshift_7+0], ax
mov      word ptr ds:[SELFMODIFY_BSP_detailshift_7+2], ax

; write to colfunc segment
mov      word ptr ds:[SELFMODIFY_BSP_detailshift2minus+0], ax
mov      word ptr ds:[SELFMODIFY_BSP_detailshift2minus+2], ax




; for 32 bit shifts, modify jump to jump 8 for 0 shifts, 4 for 1 shifts, 0 for 0 shifts.
; 0EBh, 006h = jmp 6

mov      ax, 006EBh
mov      word ptr ds:[SELFMODIFY_BSP_detailshift_1], ax
mov      word ptr ds:[SELFMODIFY_BSP_detailshift_2], ax
mov      word ptr ds:[SELFMODIFY_BSP_detailshift_3], ax
mov      word ptr ds:[SELFMODIFY_BSP_detailshift_4], ax
mov      word ptr ds:[SELFMODIFY_BSP_detailshift_5], ax


mov      al,  0
mov      word ptr ds:[SELFMODIFY_BSP_detailshift2minus_1+0], ax
mov      word ptr ds:[SELFMODIFY_BSP_detailshift2minus_1+2], ax
mov      word ptr ds:[SELFMODIFY_BSP_detailshift2minus_2+0], ax
mov      word ptr ds:[SELFMODIFY_BSP_detailshift2minus_2+2], ax

; inverse. do shifts
; d1 e0 d1 d2  = shl ax, 1; rcl dx, 1
; d1 e0 d1 d7  = shl ax, 1; rcl di, 1
; d1 e2 d1 d0  = shl dx, 1; rcl ax, 1

mov      ax, 0e0d1h 
mov      word ptr ds:[SELFMODIFY_BSP_detailshift2minus_1+0], ax
mov      word ptr ds:[SELFMODIFY_BSP_detailshift2minus_2+0], ax
mov      word ptr ds:[SELFMODIFY_BSP_detailshift_6+0], ax
mov      ax, 0d2d1h 
mov      word ptr ds:[SELFMODIFY_BSP_detailshift2minus_1+2], ax
mov      word ptr ds:[SELFMODIFY_BSP_detailshift_6+2], ax
mov      ax, 0d7d1h 
mov      word ptr ds:[SELFMODIFY_BSP_detailshift2minus_2+2], ax




jmp      done_modding_shift_detail_code
set_to_one:

; detailshift 1 case. usually involves one shift pair.
; in this case - we insert nops (nopish?) code to replace the first shift pair

; for 32 bit shifts, modify jump to jump 8 for 0 shifts, 4 for 1 shifts, 0 for 0 shifts.

; d1 f8  = sar ax, 1
mov      ax, 0f8d1h 
mov      word ptr ds:[SELFMODIFY_BSP_detailshift_7+0], ax

; write to colfunc segment
mov      word ptr ds:[SELFMODIFY_BSP_detailshift2minus+0], ax

; nop 
mov      ax, 0c089h 
mov      word ptr ds:[SELFMODIFY_BSP_detailshift_7+2], ax
; write to colfunc segment
mov      word ptr ds:[SELFMODIFY_BSP_detailshift2minus+2], ax



; 81 c3 00 00 = add bx, 0000. Not technically a nop, but probably better than two mov ax, ax?
; 89 c0       = mov ax, ax. two byte nop.

mov      ax, 0c089h

mov      word ptr ds:[SELFMODIFY_BSP_detailshift_1+0], ax
mov      word ptr ds:[SELFMODIFY_BSP_detailshift_1+2], ax
mov      word ptr ds:[SELFMODIFY_BSP_detailshift_2+0], ax
mov      word ptr ds:[SELFMODIFY_BSP_detailshift_2+2], ax
mov      word ptr ds:[SELFMODIFY_BSP_detailshift_3+0], ax
mov      word ptr ds:[SELFMODIFY_BSP_detailshift_3+2], ax
mov      word ptr ds:[SELFMODIFY_BSP_detailshift_4+0], ax
mov      word ptr ds:[SELFMODIFY_BSP_detailshift_4+2], ax
mov      word ptr ds:[SELFMODIFY_BSP_detailshift_5+0], ax
mov      word ptr ds:[SELFMODIFY_BSP_detailshift_5+2], ax

mov      word ptr ds:[SELFMODIFY_BSP_detailshift2minus_1+0], ax
mov      word ptr ds:[SELFMODIFY_BSP_detailshift2minus_1+2], ax
mov      word ptr ds:[SELFMODIFY_BSP_detailshift2minus_2+0], ax
mov      word ptr ds:[SELFMODIFY_BSP_detailshift2minus_2+2], ax
mov      word ptr ds:[SELFMODIFY_BSP_detailshift_6+0], ax
mov      word ptr ds:[SELFMODIFY_BSP_detailshift_6+2], ax

jmp      done_modding_shift_detail_code
set_to_zero:

; detailshift 0 case. usually involves two shift pairs.
; in this case - we make that first shift a proper shift

; d1 f8  = sar ax, 1
mov      ax, 0f8d1h 
mov      word ptr ds:[SELFMODIFY_BSP_detailshift_7+0], ax
mov      word ptr ds:[SELFMODIFY_BSP_detailshift_7+2], ax

; write to colfunc segment
mov      word ptr ds:[SELFMODIFY_BSP_detailshift2minus+0], ax
mov      word ptr ds:[SELFMODIFY_BSP_detailshift2minus+2], ax


; for 32 bit shifts, modify jump to jump 8 for 0 shifts, 4 for 1 shifts, 0 for 0 shifts.

; d1 e0 d1 d2   =  shl ax, 1; rcl dx, 1.
; d1 e2 d1 d0   = shl dx, 1; rcl ax, 1

mov      ax, 0E2D1h
mov      word ptr ds:[SELFMODIFY_BSP_detailshift_1+0], ax
mov      word ptr ds:[SELFMODIFY_BSP_detailshift_2+0], ax
mov      word ptr ds:[SELFMODIFY_BSP_detailshift_3+0], ax
mov      word ptr ds:[SELFMODIFY_BSP_detailshift_4+0], ax
mov      word ptr ds:[SELFMODIFY_BSP_detailshift_5+0], ax
mov      ax, 0D0D1h
mov      word ptr ds:[SELFMODIFY_BSP_detailshift_1+2], ax
mov      word ptr ds:[SELFMODIFY_BSP_detailshift_2+2], ax
mov      word ptr ds:[SELFMODIFY_BSP_detailshift_3+2], ax
mov      word ptr ds:[SELFMODIFY_BSP_detailshift_4+2], ax
mov      word ptr ds:[SELFMODIFY_BSP_detailshift_5+2], ax

; 0EBh, 006h = jmp 6
mov      ax, 006EBh
mov      word ptr ds:[SELFMODIFY_BSP_detailshift2minus_1+0], ax
mov      word ptr ds:[SELFMODIFY_BSP_detailshift2minus_2+0], ax
mov      word ptr ds:[SELFMODIFY_BSP_detailshift_6+0], ax


; fall thru
done_modding_shift_detail_code:






mov      al, byte ptr ss:[_detailshiftitercount]
mov      byte ptr ds:[SELFMODIFY_cmp_al_to_detailshiftitercount+1], al
mov      byte ptr ds:[SELFMODIFY_add_iter_to_rw_x+1], al
mov      byte ptr ds:[SELFMODIFY_add_detailshiftitercount+3], al

mov      ax, word ptr ss:[_detailshiftandval]
mov      word ptr ds:[SELFMODIFY_detailshift_and_1+2], ax

mov      ax, word ptr ss:[_centeryfrac_shiftright4]
mov      word ptr ds:[SELFMODIFY_sub__centeryfrac_shiftright4_lo_1+1], ax
mov      word ptr ds:[SELFMODIFY_sub__centeryfrac_shiftright4_lo_2+1], ax
mov      word ptr ds:[SELFMODIFY_sub__centeryfrac_shiftright4_lo_3+1], ax
mov      word ptr ds:[SELFMODIFY_sub__centeryfrac_shiftright4_lo_4+1], ax
mov      ax, word ptr ss:[_centeryfrac_shiftright4+2]
mov      word ptr ds:[SELFMODIFY_sub__centeryfrac_shiftright4_hi_1+1], ax
mov      word ptr ds:[SELFMODIFY_sub__centeryfrac_shiftright4_hi_2+1], ax
mov      word ptr ds:[SELFMODIFY_sub__centeryfrac_shiftright4_hi_3+1], ax
mov      word ptr ds:[SELFMODIFY_sub__centeryfrac_shiftright4_hi_4+1], ax

; ah is definitely 0... optimizable?
mov      ax, word ptr ss:[_centerx]
mov      word ptr ds:[SELFMODIFY_BSP_centerx_1+1], ax
mov      word ptr ds:[SELFMODIFY_BSP_centerx_2+1], ax
mov      word ptr ds:[SELFMODIFY_BSP_centerx_3+1], ax
mov      word ptr ds:[SELFMODIFY_BSP_centerx_4+1], ax
mov      word ptr ds:[SELFMODIFY_BSP_centerx_5+1], ax
mov      word ptr ds:[SELFMODIFY_BSP_centerx_6+2], ax
mov      word ptr ds:[SELFMODIFY_BSP_centerx_7+1], ax
mov      word ptr ds:[SELFMODIFY_BSP_centerx_8+1], ax



mov      ax, COLFUNC_FUNCTION_AREA_SEGMENT
mov      es, ax

; ah is definitely 0... optimizable?
mov      ax, word ptr ss:[_centery]
mov      word ptr es:[SELFMODIFY_COLFUNC_subtract_centery+1], ax
 
mov      ax, word ptr ss:[_viewwidth]
mov      word ptr ds:[SELFMODIFY_BSP_viewwidth_1+1], ax
mov      word ptr ds:[SELFMODIFY_BSP_viewwidth_2+1], ax
mov      word ptr ds:[SELFMODIFY_BSP_viewwidth_3+1], ax
mov      word ptr ds:[SELFMODIFY_BSP_viewwidth_4+1], ax

mov      ax, word ptr ss:[_viewheight]
mov      word ptr ds:[SELFMODIFY_BSP_setviewheight_1+5], ax
mov      word ptr ds:[SELFMODIFY_BSP_setviewheight_2+1], ax

mov      ax,  word ptr ss:[_pspritescale]
test     ax, ax
je       pspritescale_zero_selfmodifies

mov      word ptr ds:[SELFMODIFY_BSP_pspritescale_1+1], ax
mov      word ptr ds:[SELFMODIFY_BSP_pspritescale_2+1], ax
mov      word ptr ds:[SELFMODIFY_BSP_pspritescale_3+1], ax
mov      al, 0BBh  ; mov bx, imm16
mov      byte ptr ds:[SELFMODIFY_BSP_pspritescale_1], al
mov      byte ptr ds:[SELFMODIFY_BSP_pspritescale_2], al
mov      byte ptr ds:[SELFMODIFY_BSP_pspritescale_3], 0B8h
jmp      done_with_pspritescale_zero_selfmodifies
pspritescale_zero_selfmodifies:

mov      al, 0EBh
mov      ah, (SELFMODIFY_BSP_pspritescale_1_TARGET - SELFMODIFY_BSP_pspritescale_1_AFTER)
mov      word ptr ds:[SELFMODIFY_BSP_pspritescale_1], ax
mov      ah, (SELFMODIFY_BSP_pspritescale_2_TARGET - SELFMODIFY_BSP_pspritescale_2_AFTER)
mov      word ptr ds:[SELFMODIFY_BSP_pspritescale_2], ax
mov      ah, (SELFMODIFY_BSP_pspritescale_3_TARGET - SELFMODIFY_BSP_pspritescale_3_AFTER)
mov      word ptr ds:[SELFMODIFY_BSP_pspritescale_3], ax

done_with_pspritescale_zero_selfmodifies:






mov      ax,  word ptr ss:[_pspriteiscale]
mov      word ptr ds:[SELFMODIFY_BSP_pspriteiscale_lo_1+1], ax
mov      ax,  word ptr ss:[_pspriteiscale+2]
mov      word ptr ds:[SELFMODIFY_BSP_pspriteiscale_hi_1+1], ax



mov      ax, ss
mov      ds, ax

ASSUME DS:DGROUP



retf



ENDP



;R_WriteBackFrameConstants_

PROC R_WriteBackFrameConstants_ NEAR
PUBLIC R_WriteBackFrameConstants_ 

; todo: calculate the values here and dont store to variables. (combine with setupframe etc)

; set ds to cs to make code smaller?
mov      ax, cs
mov      ds, ax

mov      ax, DRAWFUZZCOL_AREA_SEGMENT
mov      es, ax

ASSUME DS:R_BSP_TEXT





mov      ax, word ptr ss:[_viewz]
mov      word ptr ds:[SELFMODIFY_BSP_viewz_lo_1+1], ax
mov      word ptr ds:[SELFMODIFY_BSP_viewz_lo_2+2], ax
mov      word ptr ds:[SELFMODIFY_BSP_viewz_lo_3+2], ax
mov      word ptr ds:[SELFMODIFY_BSP_viewz_lo_4+2], ax
mov      word ptr ds:[SELFMODIFY_BSP_viewz_lo_5+1], ax
mov      word ptr ds:[SELFMODIFY_BSP_viewz_lo_6+1], ax
mov      word ptr ds:[SELFMODIFY_BSP_viewz_lo_7+2], ax
mov      word ptr ds:[SELFMODIFY_BSP_viewz_lo_8+2], ax


mov      ax, word ptr ss:[_viewz+2]
mov      word ptr ds:[SELFMODIFY_BSP_viewz_hi_1+2], ax
mov      word ptr ds:[SELFMODIFY_BSP_viewz_hi_2+2], ax
mov      word ptr ds:[SELFMODIFY_BSP_viewz_hi_3+2], ax
mov      word ptr ds:[SELFMODIFY_BSP_viewz_hi_4+1], ax
mov      word ptr ds:[SELFMODIFY_BSP_viewz_hi_5+2], ax
mov      word ptr ds:[SELFMODIFY_BSP_viewz_hi_6+2], ax
mov      word ptr ds:[SELFMODIFY_BSP_viewz_hi_7+1], ax
mov      word ptr ds:[SELFMODIFY_BSP_viewz_hi_8+1], ax

mov      ax, word ptr ss:[_viewz_shortheight]
mov      word ptr ds:[SELFMODIFY_BSP_viewz_shortheight_1+1], ax
mov      word ptr ds:[SELFMODIFY_BSP_viewz_shortheight_2+1], ax
mov      word ptr ds:[SELFMODIFY_BSP_viewz_shortheight_3+1], ax
mov      word ptr ds:[SELFMODIFY_BSP_viewz_shortheight_4+1], ax
mov      word ptr ds:[SELFMODIFY_BSP_viewz_shortheight_5+1], ax

mov      al, byte ptr ss:[_extralight]
mov      byte ptr ds:[SELFMODIFY_BSP_extralight1+1], al
mov      byte ptr ds:[SELFMODIFY_BSP_extralight2+1], al
mov      byte ptr ds:[SELFMODIFY_BSP_extralight3+1], al

mov      al, byte ptr ss:[_fixedcolormap]
cmp      al, 0
jne      do_bsp_fixedcolormap_selfmodify
do_no_bsp_fixedcolormap_selfmodify:


mov      ax, 0c089h 
mov      word ptr ds:[SELFMODIFY_BSP_fixedcolormap_2], ax
mov      word ptr ds:[SELFMODIFY_BSP_fixedcolormap_3], ax
mov      word ptr ds:[SELFMODIFY_BSP_fixedcolormap_4], ax
;mov      word ptr cs:[SELFMODIFY_add_wallights], 0848ah       ; mov al, byte ptr... 

jmp      done_with_bsp_fixedcolormap_selfmodify
do_bsp_fixedcolormap_selfmodify:

mov      byte ptr ds:[SELFMODIFY_BSP_fixedcolormap_1+3], al
mov      byte ptr ds:[SELFMODIFY_BSP_fixedcolormap_5+3], al

;mov   ah, al
;mov   al, 0b0h
;mov   word ptr cs:[SELFMODIFY_add_wallights], ax       ; mov al, FIXEDCOLORMAP
;mov   word ptr cs:[SELFMODIFY_add_wallights+2], 0c089h ; nop

; zero out the value in the walllights read which wont be updated again.
; It'll get a fixedcolormap value by default. We could alternately get rid of the loop that sets scalelightfixed to fixedcolormap and modify the instructions like above.
mov   word ptr cs:[SELFMODIFY_add_wallights+2], OFFSET _scalelightfixed 

mov   ax, ((SELFMODIFY_BSP_fixedcolormap_2_TARGET - SELFMODIFY_BSP_fixedcolormap_2_AFTER) SHL 8) + 0EBh
mov   word ptr ds:[SELFMODIFY_BSP_fixedcolormap_2], ax
mov   ah, (SELFMODIFY_BSP_fixedcolormap_3_TARGET - SELFMODIFY_BSP_fixedcolormap_3_AFTER)
mov   word ptr ds:[SELFMODIFY_BSP_fixedcolormap_3], ax
mov   ah, (SELFMODIFY_BSP_fixedcolormap_4_TARGET - SELFMODIFY_BSP_fixedcolormap_4_AFTER)
mov   word ptr ds:[SELFMODIFY_BSP_fixedcolormap_4], ax


; fall thru
done_with_bsp_fixedcolormap_selfmodify:




mov      ax, word ptr ss:[_viewx]
mov      word ptr ds:[SELFMODIFY_BSP_viewx_lo_1+1], ax
mov      word ptr ds:[SELFMODIFY_BSP_viewx_lo_2+2], ax
mov      word ptr ds:[SELFMODIFY_BSP_viewx_lo_3+1], ax
mov      word ptr ds:[SELFMODIFY_BSP_viewx_lo_5+1], ax

test     ax, ax
jne      selfmodify_viewx_lo_nonzero
mov      ax, ((SELFMODIFY_BSP_viewx_lo_4_TARGET_2 - SELFMODIFY_BSP_viewx_lo_4_AFTER) SHL 8) + 07Dh

jmp      selfmodify_viewx_done
selfmodify_viewx_lo_nonzero:
mov      ax, ((SELFMODIFY_BSP_viewx_lo_4_TARGET_1 - SELFMODIFY_BSP_viewx_lo_4_AFTER) SHL 8) + 07Dh
selfmodify_viewx_done:
mov      word ptr ds:[SELFMODIFY_BSP_viewx_lo_4], ax

mov      ax, word ptr ss:[_viewx+2]
mov      word ptr ds:[SELFMODIFY_BSP_viewx_hi_1+1], ax
mov      word ptr ds:[SELFMODIFY_BSP_viewx_hi_2+2], ax
mov      word ptr ds:[SELFMODIFY_BSP_viewx_hi_3+2], ax
mov      word ptr ds:[SELFMODIFY_BSP_viewx_hi_4+1], ax
mov      word ptr ds:[SELFMODIFY_BSP_viewx_hi_5+2], ax
mov      word ptr ds:[SELFMODIFY_BSP_viewx_hi_6+1], ax

mov      ax, word ptr ss:[_viewy]
mov      word ptr ds:[SELFMODIFY_BSP_viewy_lo_1+1], ax
mov      word ptr ds:[SELFMODIFY_BSP_viewy_lo_2+1], ax
mov      word ptr ds:[SELFMODIFY_BSP_viewy_lo_3+2], ax
mov      word ptr ds:[SELFMODIFY_BSP_viewy_lo_5+2], ax

cmp      ax, 0
jle      selfmodify_viewy_lo_lessthanequaltozero
mov      ax, ((SELFMODIFY_BSP_viewy_lo_4_TARGET_2 - SELFMODIFY_BSP_viewy_lo_4_AFTER) SHL 8) + 07Eh ;jle

jmp      selfmodify_viewy_done
selfmodify_viewy_lo_lessthanequaltozero:
mov      ax, ((SELFMODIFY_BSP_viewy_lo_4_TARGET_1 - SELFMODIFY_BSP_viewy_lo_4_AFTER) SHL 8) + 07Eh ;jle
selfmodify_viewy_done:
mov      word ptr ds:[SELFMODIFY_BSP_viewy_lo_4], ax



mov      ax, word ptr ss:[_viewy+2]
mov      word ptr ds:[SELFMODIFY_BSP_viewy_hi_1+1], ax
mov      word ptr ds:[SELFMODIFY_BSP_viewy_hi_2+2], ax
mov      word ptr ds:[SELFMODIFY_BSP_viewy_hi_3+2], ax
mov      word ptr ds:[SELFMODIFY_BSP_viewy_hi_4+1], ax
mov      word ptr ds:[SELFMODIFY_BSP_viewy_hi_5+2], ax
mov      word ptr ds:[SELFMODIFY_BSP_viewy_hi_6+1], ax


mov      ax, word ptr ss:[_viewangle_shiftright3]
mov      word ptr ds:[SELFMODIFY_set_viewanglesr3_2+1], ax
mov      word ptr ds:[SELFMODIFY_set_viewanglesr3_3+1], ax
mov      word ptr ds:[SELFMODIFY_set_viewanglesr3_4+1], ax
mov      word ptr ds:[SELFMODIFY_set_viewanglesr3_5+2], ax

add      ah, 8
mov      word ptr ds:[SELFMODIFY_set_viewanglesr3_1+1], ax


mov      ax, word ptr ss:[_viewangle_shiftright1]
mov      word ptr ds:[SELFMODIFY_set_viewanglesr1_1+1], ax
mov      word ptr ds:[SELFMODIFY_set_viewanglesr1_2+1], ax
mov      word ptr ds:[SELFMODIFY_set_viewanglesr1_3+1], ax

mov      ax, word ptr ss:[_viewangle]
mov      word ptr ds:[SELFMODIFY_BSP_viewangle_lo_1+2], ax
mov      word ptr ds:[SELFMODIFY_BSP_viewangle_lo_2+2], ax
mov      word ptr ds:[SELFMODIFY_BSP_viewangle_lo_3+1], ax
mov      word ptr ds:[SELFMODIFY_BSP_viewangle_lo_4+1], ax
mov      ax, word ptr ss:[_viewangle+2]
mov      word ptr ds:[SELFMODIFY_BSP_viewangle_hi_1+2], ax
mov      word ptr ds:[SELFMODIFY_BSP_viewangle_hi_2+2], ax
mov      word ptr ds:[SELFMODIFY_BSP_viewangle_hi_3+2], ax
mov      word ptr ds:[SELFMODIFY_BSP_viewangle_hi_4+2], ax

mov      ax, word ptr ss:[_fieldofview]
mov      word ptr ds:[SELFMODIFY_BSP_fieldofview_1+1], ax
mov      word ptr ds:[SELFMODIFY_BSP_fieldofview_2+1], ax
mov      word ptr ds:[SELFMODIFY_BSP_fieldofview_3+1], ax
mov      word ptr ds:[SELFMODIFY_BSP_fieldofview_4+1], ax
mov      word ptr ds:[SELFMODIFY_BSP_fieldofview_5+1], ax
mov      word ptr ds:[SELFMODIFY_BSP_fieldofview_6+1], ax
mov      word ptr ds:[SELFMODIFY_BSP_fieldofview_7+1], ax
mov      word ptr ds:[SELFMODIFY_BSP_fieldofview_8+1], ax

mov      ax, word ptr ss:[_clipangle]
mov      word ptr ds:[SELFMODIFY_BSP_clipangle_1+1], ax
mov      word ptr ds:[SELFMODIFY_BSP_clipangle_2+1], ax
mov      word ptr ds:[SELFMODIFY_BSP_clipangle_3+1], ax
mov      word ptr ds:[SELFMODIFY_BSP_clipangle_4+2], ax
mov      word ptr ds:[SELFMODIFY_BSP_clipangle_5+1], ax
mov      word ptr ds:[SELFMODIFY_BSP_clipangle_6+1], ax
mov      word ptr ds:[SELFMODIFY_BSP_clipangle_7+2], ax
mov      word ptr ds:[SELFMODIFY_BSP_clipangle_8+1], ax




; get whole dword at the end here.
mov      ax, word ptr ss:[_destview]
mov      word ptr ds:[SELFMODIFY_BSP_add_destview_offset+1], ax

mov      ax, ss
mov      ds, ax
ASSUME DS:DGROUP

mov      ax, COLFUNC_FUNCTION_AREA_SEGMENT
mov      es, ax
mov      ax, word ptr ds:[_destview+2]
mov      word ptr es:[SELFMODIFY_COLFUNC_set_destview_segment+1], ax



ret

ENDP







END
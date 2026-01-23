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
INCLUDE defs.inc
INSTRUCTION_SET_MACRO_NO_MEDIUM

; todo move these all out once BSP code moved out of binary




SEGMENT R_BSP_24_TEXT USE16 PARA PUBLIC 'CODE'
ASSUME  CS:R_BSP_24_TEXT

PROC   R_BSP24_STARTMARKER_
PUBLIC R_BSP24_STARTMARKER_
ENDP

ANG90_HIGHBITS =		04000h
ANG180_HIGHBITS =    08000h


MID_ONLY_DRAW_TYPE = 1
BOT_TOP_DRAW_TYPE = 2

dw DRAWCOL_OFFSET - 00000h,  COLORMAPS_SEGMENT + 0000h
dw DRAWCOL_OFFSET - 00100h,  COLORMAPS_SEGMENT + 0010h
dw DRAWCOL_OFFSET - 00200h,  COLORMAPS_SEGMENT + 0020h
dw DRAWCOL_OFFSET - 00300h,  COLORMAPS_SEGMENT + 0030h
dw DRAWCOL_OFFSET - 00400h,  COLORMAPS_SEGMENT + 0040h
dw DRAWCOL_OFFSET - 00500h,  COLORMAPS_SEGMENT + 0050h
dw DRAWCOL_OFFSET - 00600h,  COLORMAPS_SEGMENT + 0060h
dw DRAWCOL_OFFSET - 00700h,  COLORMAPS_SEGMENT + 0070h
dw DRAWCOL_OFFSET - 00800h,  COLORMAPS_SEGMENT + 0080h
dw DRAWCOL_OFFSET - 00900h,  COLORMAPS_SEGMENT + 0090h
dw DRAWCOL_OFFSET - 00A00h,  COLORMAPS_SEGMENT + 00A0h
dw DRAWCOL_OFFSET - 00B00h,  COLORMAPS_SEGMENT + 00B0h
dw DRAWCOL_OFFSET - 00C00h,  COLORMAPS_SEGMENT + 00C0h
dw DRAWCOL_OFFSET - 00D00h,  COLORMAPS_SEGMENT + 00D0h
dw DRAWCOL_OFFSET - 00E00h,  COLORMAPS_SEGMENT + 00E0h
dw DRAWCOL_OFFSET - 00F00h,  COLORMAPS_SEGMENT + 00F0h
dw DRAWCOL_OFFSET - 01000h,  COLORMAPS_SEGMENT + 0100h
dw DRAWCOL_OFFSET - 01100h,  COLORMAPS_SEGMENT + 0110h
dw DRAWCOL_OFFSET - 01200h,  COLORMAPS_SEGMENT + 0120h
dw DRAWCOL_OFFSET - 01300h,  COLORMAPS_SEGMENT + 0130h
dw DRAWCOL_OFFSET - 01400h,  COLORMAPS_SEGMENT + 0140h
dw DRAWCOL_OFFSET - 01500h,  COLORMAPS_SEGMENT + 0150h
dw DRAWCOL_OFFSET - 01600h,  COLORMAPS_SEGMENT + 0160h
dw DRAWCOL_OFFSET - 01700h,  COLORMAPS_SEGMENT + 0170h
dw DRAWCOL_OFFSET - 01800h,  COLORMAPS_SEGMENT + 0180h
dw DRAWCOL_OFFSET - 01900h,  COLORMAPS_SEGMENT + 0190h
dw DRAWCOL_OFFSET - 01A00h,  COLORMAPS_SEGMENT + 01A0h
dw DRAWCOL_OFFSET - 01B00h,  COLORMAPS_SEGMENT + 01B0h
dw DRAWCOL_OFFSET - 01C00h,  COLORMAPS_SEGMENT + 01C0h
dw DRAWCOL_OFFSET - 01D00h,  COLORMAPS_SEGMENT + 01D0h
dw DRAWCOL_OFFSET - 01E00h,  COLORMAPS_SEGMENT + 01E0h
dw DRAWCOL_OFFSET - 01F00h,  COLORMAPS_SEGMENT + 01F0h
dw DRAWCOL_OFFSET - 02000h,  COLORMAPS_SEGMENT + 0200h


;R_ScaleFromGlobalAngle_

PROC R_ScaleFromGlobalAngle_ NEAR


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

xchg  ax, di

; dx = anglea
; di = angleb

mov   ax, FINESINE_SEGMENT
mov   si, ax
SELFMODIFY_get_rw_distance_lo_1:
mov   bx, 01000h
SELFMODIFY_get_rw_distance_hi_1:
mov   cx, 01000h



;    den = FixedMulTrig(FINE_SINE_ARGUMENT, anglea, rw_distance);
 
call FixedMulTrig_BSPLocal_


;    num.w = FixedMulTrig(FINE_SINE_ARGUMENT, angleb, projection.w)<<detailshift.b.bytelow;
 
;call FixedMulTrig16_
; inlined  16 bit times sine value

mov es, si
SHIFT_MACRO sal di 2
les bx, dword ptr es:[di]
mov cx, es
xchg dx, cx
xchg ax, bx

;  dx now has anglea
;  ax has finesine_segment
;  cx:bx is den

SELFMODIFY_BSP_centerx_1:
mov   si, 01000h


AND  DX, SI    ; DX*CX

MOV  DI, DX    ; store high result

MUL  SI       ; AX*CX
sub  DX, DI   


; cx:bx had den
; dx:ax has num

SELFMODIFY_BSP_detailshift2minus_1:


; fall thru do twice
shl   ax, 1
rcl   dx, 1
do_once:
shl   ax, 1
rcl   dx, 1
shift_done:


; cx:bx had den
; dx:ax has num

;    if (den > num >> 16)
;    if (den > num.h.intbits) {

; annoying - we have to account for sign!
; is there a cleaner way?

mov    di, dx
xor    di, cx   ; different signs?
js     figure_out_sign_return  ; different bit 15s

test   dx, dx
jns    two_positives

two_negatives:
neg    cx
neg    bx
adc    cx, 0
neg    dx
neg    ax
adc    dx, 0

two_positives:


test  cx, cx
jne   do_divide ; definitely larger than dx if nonzero..
cmp   bx, dx
jg    do_divide


return_maxvalue:
; rare occurence
mov   dx, 040h
xor   ax, ax
pop   di
pop   si
pop   cx
pop   bx
ret

figure_out_sign_return:
test  cx, cx
js    return_maxvalue
return_minvalue:
; super duper rare case. actually never caught it happening.
mov   ax, 0100h
cwd
pop   di
pop   si
pop   cx
pop   bx
ret

do_divide:

; set up params
;cx/bx already set

; we actually already bounds check more aggressively than fixeddiv
;  and guarantee positives here so the fixeddiv wrapper is unnecessary

; NOTE: a high word bounds triggered early return on the first divide result 
;   is super rare due to the outer checks...
;   doesnt occur even every frame. lets avoid the "optimized" dupe function.



; destroys si/di internally, but we dont care here.

call  div48_32_BSPLocal_ ; internally does push pop of di/bp but not si


mov   dx, es      ; retrieve q1

; set negative if need be...
cmp   dx, 040h
jg    return_maxvalue
test  dx, dx
; dont need to check for negative result, this was unsigned.
jne   normal_return 

cmp   ax, 0100h
jnae  return_minvalue
normal_return:

pop   di
pop   si
pop   cx
pop   bx
ret


ENDP



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

; return 0
ret  


inputs_not_zero:

; todo: come up with a way to branchlessly determine octant via xors, shifts, etc.
; octant ends up in si or something. then do a jmp table.


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




;   
; basically, shift numerator left 16 and divide
; DX:AX:00 / CX:BX

; destroys si/di internally, outer scope must push/pop

PROC   div48_32_BSPLocal_ NEAR
PUBLIC div48_32_BSPLocal_ 


; di:si get shifted cx:bx
push  di

XOR SI, SI ; zero this out to get high bits of numhi

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


; todo reeaxmine this register juggle. cx/di swap may not be necessary in particular

; save numlo word in cx.
; avoid going to memory...

; store these two long term...


xchg  ax, di   ; di gets numlo


; set up first div. 
; dx:ax becomes numhi
xchg  ax, dx
mov   dx, si    


mov   word ptr cs:[_SELFMODIFY_restore_numhi_low+1], ax ; store copy of numhi.low?



;	divresult.wu = DIV3216RESULTREMAINDER(numhi.wu, den1);
; DX:AX = numhi.wu


div   cx

; rhat = dx
; qhat = ax
;    c1 = FastMul16u16u(qhat , den0);

mov   si, dx					; si stores rhat
mov   es, ax     ; store qhat

mul   bx   						; DX:AX = c1

;  c2 = rhat:num1



;    if (c1 > c2.wu)
;         qhat -= (c1 - c2.wu > den.wu) ? 2 : 1;
; 


; c1 hi = dx, c2 lo = si
; 0xE455 vx 0x1E iters

cmp   dx, si



jae   continue_checking_q1
; most common case fallthru: branches about 2000:1 cases
q1_ready:

mov  ax, es
;	rem.hu.intbits = numhi.hu.fracbits;
;	rem.hu.fracbits = num1;
;	rem.wu -= FastMul16u32u(q1, den.wu);



; multiplying by cx:bx basically. inline bx in as si.

;inlined FastMul16u32u_

MUL  cx        ; AX * CX
mov  si, ax    ; store low product to be high result. 
mov  ax, es    ; Retrieve orig AX
MUL  bx        ; AX * si
ADD  dx, si    ; add 

; actual 2nd division...


sub   di, ax
_SELFMODIFY_restore_numhi_low: ; store copy of numhi.low?
mov   si, 01000h
sbb   si, dx

; todo can we invert logic ahead instead of reversing sign, avoixxng si swap above?


xchg  ax, di
mov   dx, si
; todo use as is?


cmp   dx, cx

; check for adjustment

;    if (rem.hu.intbits < den1){

jnb    adjust_for_overflow  ; fall thru at about about 2000:1 rate

div   cx

mov   si, ax
mov   di, dx

mul   bx
sub   dx, di

jae   continue_c1_c2_test  ; happens about 25% of the time
; happens about 75% of the time


; default 440124 vs branch 105492 times
do_return_2:
mov   ax, si
pop   di
ret  

continue_check2:
test  ax, ax
jz    do_return_2
continue_c1_c2_test:
je    continue_check2      ; happens almost never
; happens about 25% of the time

cmp   dx, cx
jae   check_for_extra_qhat_subtraction

do_qhat_subtraction_by_1:
dec   si

mov   ax, si
pop   di
ret  

check_for_extra_qhat_subtraction:
; very rare, basically never happens, dual jump is fine
ja    do_qhat_subtraction_by_2
; very rare, basically never happens, dual jump is fine


cmp   bx, ax

jae   do_qhat_subtraction_by_1

do_qhat_subtraction_by_2:
; very rare, basically never happens, dual jump is fine
dec   si
jmp   do_qhat_subtraction_by_1




continue_checking_q1:
ja    check_c1_c2_diff
; rare codepath! 

cmp   ax, di
jbe   q1_ready

check_c1_c2_diff:
sub   ax, di
sbb   dx, si
cmp   dx, cx
; these branches havent been tested but this is a super rare codepath
ja    qhat_subtract_2  
je    compare_low_word

qhat_subtract_1:
mov ax, es
dec ax
mov es, ax
jmp q1_ready

; very rare case!
adjust_for_overflow:
xor   di, di
sub   ax, cx
sbb   dx, di

cmp   dx, cx

; check for overflow param

jae   adjust_for_overflow_again


div   cx
mov   si, ax
mov   di, dx

mul   bx
sub   dx, di
; these branches havent been tested but this is a super super super rare codepath
ja    continue_c1_c2_test_2
jne   dont_decrement_qhat_and_return
test  ax, ax
jz   dont_decrement_qhat_and_return
continue_c1_c2_test_2:


cmp   dx, cx
ja    decrement_qhat_and_return
; these branches havent been tested but this is a super super super super super rare codepath
jne   dont_decrement_qhat_and_return
cmp   bx, ax
jae   dont_decrement_qhat_and_return
decrement_qhat_and_return:
dec   si
dont_decrement_qhat_and_return:
mov   ax, si


pop   di
ret  

compare_low_word:
; extremely rare codepath! double jump is fine.
cmp   ax, bx
jbe   qhat_subtract_1

qhat_subtract_2:

mov ax, es
dec ax
mov es, ax
jmp qhat_subtract_1

; the divide would have overflowed. subtract values
adjust_for_overflow_again:

sub   ax, cx
sbb   dx, di

div   cx
; ax has its result...

pop   di
ret 

ENDP



do_quick_return_whole:
  xor   ax, ax
  mov   dx, 08000h

  RET
PROC   FixedDivWholeA_BSPLocal_   NEAR
PUBLIC FixedDivWholeA_BSPLocal_

; big improvements to branchless fixeddiv 'preamble' by zero318
; both numbers positive. no signs!

; note: AX is always a fairly low number in this call and will never shift 2 into high bits


   jcxz do_simple_div_whole  ; if cx is nonzero then the bounds check definitely failed and does not need to be done
  restore_reg_then_do_full_divide_whole:


do_full_divide_whole:

  
push si
push di

; todo inline i guess.
call div48_32_whole_BSPLocal_ ; internally does push pop of di/bp but not si

; set negative if need be...

mov   dx, es      ; retrieve q1
pop   di
pop   si



ret

do_simple_div_whole:
; AX:0000 div 0000:BX
; high word is AX:0000 / BX
; low word: divide remainder << 16 / BX

   mov  dx, ax  ; for division of AX:0000
   shl  ax, 1
   shl  ax, 1
   cmp  ax, bx
   jae  do_quick_return_whole   ; fixeddiv shift 14 
   xchg ax, cx  ; zero ax for div. cx is known zero since we jcxzed here.

   div  bx       ; get high result
   mov  cx, ax   ; store high result
   xor  ax, ax   ; prep to divide remainder
   div  bx       ; divide by remainder, get low word
   mov  dx, cx   ; restore high result
   ret


ENDP





;div48_32_whole_
; basically, shift numerator left 16 and divide
; AX:00:00 / CX:BX

PROC div48_32_whole_BSPLocal_ NEAR

; di:si get shifted cx:bx
xor dx, dx
; cx known nonzero.

test ch, ch
jne shift_bits_whole
; shift a whole byte immediately

mov ch, cl
mov cl, bh
mov bh, bl
xor bl, bl

mov dh, dl
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



mov   di, ax      ; store copy of numhi.low


;	divresult.wu = DIV3216RESULTREMAINDER(numhi.wu, den1);
; DX:AX = numhi.wu

div   cx

; rhat = dx
; qhat = ax
;    c1 = FastMul16u16u(qhat , den0);

mov   si, dx					; si stores rhat
mov   es, ax     ; store qhat
mul   bx   						; DX:AX = c1

;  c2 = rhat:num1

;    if (c1 > c2.wu)
;         qhat -= (c1 - c2.wu > den.wu) ? 2 : 1;
; 

; c1 hi = dx, c2 lo = si
cmp   dx, si

jae   continue_checking_q1_whole

q1_ready_whole:

mov  ax, es
;	rem.hu.intbits = numhi.hu.fracbits;
;	rem.hu.fracbits = num1;
;	rem.wu -= FastMul16u32u(q1, den.wu);



; multiplying by cx:bx basically. inline bx in as si.

;inlined FastMul16u32u_

MUL  cx        ; AX * CX
mov  si, AX    ; store low product to be high result. Retrieve orig AX
mov  ax, es
MUL  bx        ; AX * si
ADD  DX, si    ; add 

; actual 2nd division...


neg   ax
sbb   di, dx
mov   dx, di

cmp   dx, cx

; check for adjustment

;    if (rem.hu.intbits < den1){

jnb    adjust_for_overflow_whole

div   cx

mov   si, ax
mov   di, dx

mul   bx
sub   dx, di

jae   continue_c1_c2_test_whole

do_return_2_whole:
mov   ax, si

ret  

continue_check2_whole:
test  ax, ax
jz    do_return_2_whole
continue_c1_c2_test_whole:
je    continue_check2_whole
; happens about 25% of the time

cmp   dx, cx
jae   check_for_extra_qhat_subtraction_whole

do_qhat_subtraction_by_1_whole:
dec   si

mov   ax, si

ret  

check_for_extra_qhat_subtraction_whole:
ja    do_qhat_subtraction_by_2_whole
cmp   bx, ax

jae   do_qhat_subtraction_by_1_whole
do_qhat_subtraction_by_2_whole:

dec   si
jmp   do_qhat_subtraction_by_1_whole

continue_checking_q1_whole:
ja    check_c1_c2_diff_whole
; rare codepath! 
cmp   ax, di
jbe   q1_ready_whole

check_c1_c2_diff_whole:
sub   ax, di
sbb   dx, si
cmp   dx, cx
; these branches havent been tested but this is a super rare codepath
ja    qhat_subtract_2_whole 
je    compare_low_word_whole

qhat_subtract_1_whole:
mov ax, es
dec ax
mov es, ax
jmp q1_ready_whole

; very rare case!
adjust_for_overflow_whole:
xor   di, di
sub   ax, cx
sbb   dx, di

cmp   dx, cx

; check for overflow param

jae   adjust_for_overflow_again_whole


div   cx
mov   si, ax
mov   di, dx

mul   bx
sub   dx, di
; these branches havent been tested but this is a super super super rare codepath
ja    continue_c1_c2_test_2_whole
jne   dont_decrement_qhat_and_return_whole
test  ax, ax
jz   dont_decrement_qhat_and_return_whole
continue_c1_c2_test_2_whole:


cmp   dx, cx
ja    decrement_qhat_and_return_whole
; these branches havent been tested but this is a super super super super super rare codepath
jne   dont_decrement_qhat_and_return_whole
cmp   bx, ax
jae   dont_decrement_qhat_and_return_whole
decrement_qhat_and_return_whole:
dec   si
dont_decrement_qhat_and_return_whole:
mov   ax, si
ret  

compare_low_word_whole:
cmp   ax, bx
jbe   qhat_subtract_1_whole

qhat_subtract_2_whole:
mov ax, es
dec ax
mov es, ax
jmp qhat_subtract_1_whole

; the divide would have overflowed. subtract values
adjust_for_overflow_again_whole:

sub   ax, cx
sbb   dx, di

div   cx

; ax has its result...

ret 


ENDP



IF COMPISA GE COMPILE_386

    PROC FixedMulTrig_BSPLocal_ NEAR
    sal dx, 1
    sal dx, 1   ; DWORD lookup index
    ENDP

    PROC FixedMulTrigNoShift_BSPLocal_ NEAR
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

   PROC FixedMulTrig_BSPLocal_  NEAR

    

    sal dx, 1
    sal dx, 1   ; DWORD lookup index
    ENDP

    PROC FixedMulTrigNoShift_BSPLocal_  NEAR
    push  si

    ; lookup the fine angle

; todo swap arg order so cx:bx is seg/lookup
; allowing for mov es, cx -> les es:[bx]


    mov  si, dx
    mov  es, ax  ; put segment in es
    les  ax, dword ptr es:[si]

    mov  dx, es
    mov  es, ax
    mov  ax, dx  ; gross juggle... revisit. for consistency with old algo


    AND   AX, BX	; S0*BX
    NEG   AX
    XCHG  AX, SI	; SI stores hi word return

    MOV   AX, DX    ; restore sign bits from DX

    AND   AX, CX     ; DX*CX
    SUB   SI, AX     ; low word result into high word return

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
    ADC  SI, 0    ; would be cool if we had a known zero reg

    xchg AX, CX   ; AX gets CX

    CWD           ; S1 in DX

    mov  CX, ES   ; AX from ES
    AND  DX, CX   ; S1*AX
    SUB  SI, DX   ; result into high word return

    MUL  CX       ; AX*CX

    ADD  AX, BX	  ; set up final return value
    ADC  DX, SI

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

ENDP


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

PROC FastDiv3232_RPTA_ NEAR

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
jne   qhat_subtract_1_3232RPTA

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
; thanks zero318 from discord for improved algorithm  

; DX:AX  *  CX:BX
;  0  1      2  3

  shl  ecx, 16
  mov  cx, bx
  xchg ax, dx
  shl  eax, 16
  xchg ax, dx
  imul  ecx
  shr  eax, 16
  ret



ENDP
ELSE


PROC FixedMulBSPLocal_ NEAR

; DX:AX  *  CX:BX
;  0  1      2  3

; thanks zero318 from discord for improved algorithm  

MOV  ES, SI
MOV  SI, DX
PUSH AX
MUL  BX
MOV  word ptr cs:[_selfmodify_restore_dx+1], DX
MOV  AX, SI
MUL  CX
XCHG AX, SI
CWD
AND  DX, BX
SUB  SI, DX
MUL  BX
_selfmodify_restore_dx:
ADD  AX, 01000h
ADC  SI, DX
XCHG AX, CX
CWD
POP  BX
AND  DX, BX
SUB  SI, DX
MUL  BX
ADD  AX, CX
ADC  DX, SI
MOV  SI, ES

ret

ENDP
ENDIF

do_simple_div:
; high word is DX:AX / BX
; low word: divide remainder << 16 / BX

  ; bounds check
  ; todo compare vs sal jc
   test dh, 0C0h ; are high bits non zero (known cx shift 14 )   
   jne  do_quick_return
   mov  cx, dx  ; copy of dx
   mov  es, ax
   sal  ax, 1
   rcl  cx, 1
   sal  ax, 1
   rcl  cx, 1
   cmp  cx, bx
   jae  do_quick_return

   mov  ax, es  

   div  bx       ; get high result
   mov  cx, ax   ; store high result
   xor  ax, ax   ; prep to divide remainder
   div  bx       ; divide by remainder, get low word
   mov  dx, cx   ; restore high result

   XOR  AX, SI
   XOR  DX, SI  ; apply sign  
   SUB  AX, SI  
   SBB  DX, SI
 

   POP   SI

   ret

do_quick_return:
  MOV   AX, SI
  NEG   AX
  DEC   AX
  CWD
  RCR   DX, 1

  POP   SI
  RET

PROC   FixedDivBSPLocal_ NEAR
PUBLIC FixedDivBSPLocal_

; big improvements to branchless fixeddiv 'preamble' by zero318


  PUSH  SI

  xor   si, si  ; start with no sign adjust
  test  dx, dx
  jns   skip_sign_adjust_dx
  neg   dx
  neg   ax
  sbb   dx, si  ; zero
  dec   si      ; toggle sign bit

skip_sign_adjust_dx:
  test  cx, cx
  jns   skip_sign_adjust_cx
  neg   cx
  neg   bx
  sbb   cx, 0
  not   si     ; toggle sign bit

skip_sign_adjust_cx:

  jcxz  do_simple_div


; cx is non zero, and sign bit is known zero afrer abs 
; so for shift 14 compare, its a compare of cx to bit 14 of dx for high work
; if cx is greater than 1, the shift 14 check fails and we fo fixed div

  dec   cx
  jz    do_cx_equals_1_case  ; cx was 1, further comparison needed
  
  do_full_divide:
  inc   cx
  mov  word ptr cs:[_SELFMODIFY_store_fixeddiv_sign_ahead+1], si

call div48_32_BSPLocal_ 

mov   dx, es      ; retrieve q1

; set negative if need be...

_SELFMODIFY_store_fixeddiv_sign_ahead:
mov  si, 01000h

XOR  AX, SI
XOR  DX, SI  
SUB  AX, SI  
SBB  DX, SI  ; dx:ax now labs. sign bits in si


pop   si
ret
; pretty rare case, but does need to be handled for shift 14 fixeddiv bounds check
  do_cx_equals_1_case:
  ; cx was equal to 1. (needs to be re-incremented )
  ; the fixeddiv shift 14 check still has to be done.
  
  ; todo  if cx is known to be 1, 
  ; does that make this a simple/faster division algorithm that can be inlined?
  
  ; bounds check... 
  mov   cx, dx
  mov   es, ax  ; store ax
  sal   ax, 1
  rcl   cx, 1
  sal   ax, 1
  rcl   cx, 1
  jc    restore_ax_do_full_divide   ; determined bit 14 was off
  cmp   cx, bx
  jae   do_quick_return
  restore_ax_do_full_divide:
  xor   cx, cx
  mov   ax, es  ; restore ax
  jmp   do_full_divide

ENDP

PROC FixedMulTrigNoShiftBSPLocal_ NEAR
; pass in the index already shifted to be a dword lookup..

    push  si

    ; lookup the fine angle

; todo swap arg order so cx:bx is seg/lookup
; allowing for mov es, cx -> les es:[bx]


    mov  si, dx
    mov  es, ax  ; put segment in es
    les  ax, dword ptr es:[si]

    mov  dx, es
    mov  es, ax
    mov  ax, dx  ; gross juggle... revisit. for consistency with old algo


    AND   AX, BX	; S0*BX
    NEG   AX
    XCHG  AX, SI	; SI stores hi word return

    MOV   AX, DX    ; restore sign bits from DX

    AND   AX, CX     ; DX*CX
    SUB   SI, AX     ; low word result into high word return

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
    ADC  SI, 0    ; would be cool if we had a known zero reg

    xchg AX, CX   ; AX gets CX

    CWD           ; S1 in DX

    mov  CX, ES   ; AX from ES
    AND  DX, CX   ; S1*AX
    SUB  SI, DX   ; result into high word return

    MUL  CX       ; AX*CX

    ADD  AX, BX	  ; set up final return value
    ADC  DX, SI

    pop   si
    ret



ENDP


PROC R_ClearClipSegs_ NEAR
; todo lea

mov  word ptr ds:[_solidsegs+0], 08001h
mov  word ptr ds:[_solidsegs+2], 0FFFFh
; todo push pop
mov  ax, word ptr ds:[_viewwidth]
mov  word ptr ds:[_solidsegs+4], ax
mov  word ptr ds:[_solidsegs+6], 07FFFh
mov  word ptr ds:[_newend], OFFSET _solidsegs + 2 * (SIZE CLIPRANGE_T)
ret  



ENDP

COSINE_OFFSET_IN_SINE = ((FINECOSINE_SEGMENT - FINESINE_SEGMENT) SHL 4)

;R_ClearPlanes

PROC   R_ClearPlanes_ NEAR

; dont need to preserve registers here


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

mov   bx, FINESINE_SEGMENT
mov   es, bx


les   ax, dword ptr es:[di + COSINE_OFFSET_IN_SINE]
mov   si, es

; note: range is -65535 to 65535. High word is already sign bits

; sine/cosine max at +/- 65536 so they wont overflow.

xor   ax, si
sub   ax, si   ; absolute value
xor   dx, dx

div   cx

mov   es, bx ; restore es for next LES

xor   ax, si ; apply sign
sub   ax, si

mov   word ptr ds:[_basexscale], ax
mov   word ptr ds:[_basexscale + 2], si

les   ax, dword ptr es:[di]
mov   si, es

xor   ax, si
sub   ax, si   ; absolute value
xor   dx, dx

div   cx
not   si  ; we want a negative result so neg the sign


xor   ax, si ; apply sign
sub   ax, si

jnz   dont_zero_si  ; weird case where we try to take negative of zero and it was leaving FFFF sign bits...
mov   si, ax
dont_zero_si:  

mov   word ptr ds:[_baseyscale], ax
mov   word ptr ds:[_baseyscale + 2], si


ret   

endp





;R_HandleEMSVisplanePagination

PROC R_HandleEMSVisplanePagination_ NEAR

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
mov   word ptr ds:[_pageswapargs + (pageswapargs_visplanepage_offset * 2)], ax


;pageswapargs[pageswapargs_visplanepage_offset+1] = usedpageindex;
IFDEF COMP_CH
ELSE
    mov   word ptr ds:[_pageswapargs + ((pageswapargs_visplanepage_offset+1) * 2)], si
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
        cli
        out  	dx, al
        mov    ax,  ds:[(pageswapargs_visplanepage_offset * 2) + _pageswapargs]
        mov  	dx, SCAT_PAGE_SET_REGISTER
        out 	dx, ax
        sti

	ELSEIF COMP_CH EQ CHIPSET_SCAMP

        xchg    ax, si
        ; not necessary?
        ;or      al, EMS_AUTOINCREMENT_FLAG  
        cli
        out     SCAMP_PAGE_SELECT_REGISTER, al
        mov     ax, ds:[_pageswapargs + (2 * pageswapargs_visplanepage_offset)]
        out 	 SCAMP_PAGE_SET_REGISTER, ax
        sti

	ELSEIF COMP_CH EQ CHIPSET_HT18

        mov  	dx, HT18_PAGE_SELECT_REGISTER
        xchg    ax, si
        ; not necessary?
        ;or      al, EMS_AUTOINCREMENT_FLAG  
        cli
        out  	dx, al
        mov    ax,  ds:[(pageswapargs_visplanepage_offset * 2) + _pageswapargs]
        mov  	dx, HT18_PAGE_SET_REGISTER
        out 	dx, ax
        sti

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



; dx is 13:3 height
; cx is picandlight
; bl is icceil

;push      si
;push      di

xor       ax, ax

cmp       cl, byte ptr ds:[_skyflatnum]
jne       not_skyflat

;		height = 0;			// all skys map together
;		lightlevel = 0;

cwd         ; ax already 0
xor       ch, ch
not_skyflat:


; loop vars

; al = i
; ah = lastvisplane
; dx is height high precision
; di is unused now
; bx is .. checkheader
; cx is pic_and_light
; si is visplanepiclights[i] (used for visplanelights lookups)


; set up find visplane loop

; di unused... 

push      bx  ; push isceil

; init loop vars
; ax already xored.
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

call      R_HandleEMSVisplanePagination_
; fetch and return i * 8 ptr
lea       ax, [bx - _visplaneheaders]


;pop       di
;pop       si
ret       


;		if (height == checkheader->height
;			&& piclight.hu == visplanepiclights[i].pic_and_light) {
;				break;
;		}

check_for_visplane_match:
cmp       dx, word ptr ds:[bx + VISPLANEHEADER_T.visplaneheader_height] ; compare height high word
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
; mov       word ptr ds:[bx + VISPLANEHEADER_T.visplaneheader_UNSUED], di
mov       word ptr ds:[bx + VISPLANEHEADER_T.visplaneheader_height], dx
mov       word ptr ds:[bx + VISPLANEHEADER_T.visplaneheader_minx], SCREENWIDTH
mov       word ptr ds:[bx + VISPLANEHEADER_T.visplaneheader_maxx], 0FFFFh

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


lea       ax, [bx - _visplaneheaders]


;pop       di
;pop       si
ret       

ENDP



SUBSECTOR_OFFSET_IN_SECTORS       = (SUBSECTORS_SEGMENT - SECTORS_SEGMENT) * 16
;SUBSECTOR_LINES_OFFSET_IN_SECTORS = (SUBSECTOR_LINES_SEGMENT - SECTORS_SEGMENT) * 16

;R_Subsector_

revert_visplane:
call  Z_QuickMapVisplaneRevert_BSPLocal_ ;  todo inline i guess
les   bx, dword ptr ds:[_frontsector]  ; retrieve frontsector? 
jmp   prepare_fields


PROC R_Subsector_ NEAR


;ax is subsecnum



mov   bx, ax
mov   ax, SUBSECTOR_LINES_SEGMENT
mov   es, ax

xor   ax, ax
xlat  byte ptr es:[bx]

push  ax  ; store count

mov   ax, SECTORS_SEGMENT
mov   es, ax

SHIFT_MACRO shl bx 2

push word ptr es:[bx+SUBSECTOR_OFFSET_IN_SECTORS + SUBSECTOR_T.ss_firstline]   ; get subsec firstline

mov   bx, word ptr es:[bx+SUBSECTOR_OFFSET_IN_SECTORS + SUBSECTOR_T.ss_secnum] ; get subsec secnum
; todo should this sector be preshifted...
SHIFT_MACRO shl bx 4
mov   word ptr ds:[_frontsector], bx


cmp   byte ptr ds:[_visplanedirty], 0
jne   revert_visplane      ; todo branch test

prepare_fields:

;	ceilphyspage = 0;
;	floorphyspage = 0;
;	ceiltop = NULL;
;	floortop = NULL;

xor   ax, ax

mov   word ptr ds:[_ceilphyspage], ax  ; also writes _floorphyspage
mov   word ptr ds:[_ceiltop], ax 
;mov   word ptr ds:[_ceiltop+2], ax     ; seemed to be working fine without this?
mov   word ptr ds:[_floortop], ax
;mov   word ptr ds:[_floortop+2], ax    ; seemed to be working fine without this?

;  es:bx holds frontsector

; OPTIMIZATION:  we compare as 13:3 instead of as 16:16

dec   ax  ; was 0, becomes 0FFFFh ; -1 case


mov   dx, word ptr es:[bx + SECTOR_T.sec_floorheight]
SELFMODIFY_BSP_viewz_13_3_1:
cmp   dx, 01000h
jg    set_floor_plane       ; todo test branch?

find_floor_plane_index:

; set up picandlight
mov   ch, byte ptr es:[bx + SECTOR_T.sec_lightlevel]
mov   cl, byte ptr es:[bx + SECTOR_T.sec_floorpic]
xor   bx, bx ; isceil = 0
call  R_FindPlane_
les   bx, dword ptr ds:[_frontsector]  ; retrieve frontsector
set_floor_plane:
mov   word ptr cs:[SELFMODIFY_set_floorplaneindex+1 - OFFSET R_BSP24_STARTMARKER_], ax

floor_plane_set:
mov   ax, 0FFFFh  ; -1 case
mov   dx, word ptr es:[bx + SECTOR_T.sec_ceilingheight]

check_for_sky:
; es:bx is still frontsector
mov   cl, byte ptr es:[bx + SECTOR_T.sec_ceilingpic] 
cmp   cl, byte ptr ds:[_skyflatnum]  ; todo single instruction cmp with constant
je    find_ceiling_plane_index

SELFMODIFY_BSP_viewz_13_3_2:
cmp   dx, 01000h
jl    set_ceiling_plane      ; TODO test branch

find_ceiling_plane_index:
; es:bx is frontsector

; set up picandlight
mov   ch, byte ptr es:[bx + SECTOR_T.sec_lightlevel]
mov   cl, byte ptr es:[bx + SECTOR_T.sec_ceilingpic]
mov   bx, 1
call  R_FindPlane_
les   bx, dword ptr ds:[_frontsector]    ; retrieve frontsector
set_ceiling_plane:
mov   word ptr cs:[SELFMODIFY_set_ceilingplaneindex+1 - OFFSET R_BSP24_STARTMARKER_], ax

do_addsprites:

; todo: make single stack frame here
; push frontsector values onto stack so its never again looked up 

; es:bx already frontsector

call  R_AddSprites_   ; todo inline?

; if we create the stack frame here, ax/cx would be on stack and accessible without necessarily having to go back to register every time.

pop   ax ; firstline
pop   cx ; count

loop_addline:

; what if we inlined AddLine? or unrolled this?
; whats realistic maximum of numlines? a few hundred? might be 1800ish bytes... save about 10 cycles per call to addline maybe?


call  R_AddLine_
inc   ax

loop   loop_addline




ret   

ENDP

;R_CheckPlane_

PROC R_CheckPlane_ NEAR

; ax: index
; cl: isceil?



; di holds visplaneheaders lookup. maybe should be si

push      si
push      di

mov       si, dx    ; si holds start
mov       di, ax


; already preshifted 3
mov       word ptr cs:[SELFMODIFY_setindex+1 - OFFSET R_BSP24_STARTMARKER_], di


add       di, _visplaneheaders  ; _di is plheader
mov       byte ptr cs:[SELFMODIFY_setisceil + 1 - OFFSET R_BSP24_STARTMARKER_], cl  ; write cl value
test      cl, cl

mov       cx, bx    ; cx holds stop

je        check_plane_is_floor
;dec       cx
check_plane_is_ceil:
les       bx, dword ptr ds:[_ceiltop]
loaded_floor_or_ceiling:
; bx holds offset..

mov       ax, si  ; fetch start
cmp       ax, word ptr ds:[di + VISPLANEHEADER_T.visplaneheader_minx]    ; compare to minx
jge       start_greater_than_min
mov       word ptr cs:[SELFMODIFY_setminx+3 - OFFSET R_BSP24_STARTMARKER_], ax
mov       dx, word ptr ds:[di + VISPLANEHEADER_T.visplaneheader_minx]    ; fetch minx into intrl
checked_start:
; now checkmax
mov       ax, word ptr ds:[di + VISPLANEHEADER_T.visplaneheader_maxx]   ; fetch maxx, ax = intrh = plheader->max
cmp       cx, ax                  ; compare stop to maxx
jle       stop_smaller_than_max
mov       word ptr cs:[SELFMODIFY_setmax+3 - OFFSET R_BSP24_STARTMARKER_], cx
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
mov       word ptr ds:[di + VISPLANEHEADER_T.visplaneheader_minx], 0FFFFh
SELFMODIFY_setmax:
mov       word ptr ds:[di + VISPLANEHEADER_T.visplaneheader_maxx], 0FFFFh

SELFMODIFY_setindex:
mov       ax, 0ffffh


pop       di
pop       si
ret       


check_plane_is_floor:

les       bx, dword ptr ds:[_floortop]
jmp       loaded_floor_or_ceiling
start_greater_than_min:
mov       ax, word ptr ds:[di + VISPLANEHEADER_T.visplaneheader_minx]


mov       word ptr cs:[SELFMODIFY_setminx+3 - OFFSET R_BSP24_STARTMARKER_], ax
jmp       checked_start
stop_smaller_than_max:
mov       word ptr cs:[SELFMODIFY_setmax+3 - OFFSET R_BSP24_STARTMARKER_], ax     ; unionh = plheader->max
mov       ax, cx                                    ; intrh = stop
jmp       done_checking_max

make_new_visplane:
mov       bx, word ptr ds:[_lastvisplane] 
mov       es, bx    ; store in es
sal       bx, 1   ; bx is 2 per index

; dx/ax is plheader->height
; done with old plheader..
; es is in use..

mov       dx, word ptr ds:[di + VISPLANEHEADER_T.visplaneheader_height]

;	visplanepiclights[lastvisplane].pic_and_light = visplanepiclights[index].pic_and_light;

; generate index from di again. 
sub       di, _visplaneheaders
SHIFT_MACRO sar di 2
mov       di, word ptr ds:[di + _visplanepiclights]

mov       word ptr ds:[bx + _visplanepiclights], di
SHIFT_MACRO sal bx 2
; now bx is 8 per
add       bx, _visplaneheaders
; set all plheader fields for lastvisplane...
;mov       word ptr ds:[bx + VISPLANEHEADER_T.visplaneheader_UNSUED], ax
mov       word ptr ds:[bx + VISPLANEHEADER_T.visplaneheader_height], dx
mov       word ptr ds:[bx + VISPLANEHEADER_T.visplaneheader_minx], si ; looks weird
mov       word ptr ds:[bx + VISPLANEHEADER_T.visplaneheader_maxx], cx  ; looks weird




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


lea       ax, [bx - _visplaneheaders]
inc       word ptr ds:[_lastvisplane]


pop       di
pop       si
ret       

ENDP

MINZ_HIGHBITS = 4
;R_ProjectSprite_

PROC R_ProjectSprite_ NEAR

; es:si is sprite.
; es is a constant..



; bp - 2:	 	thingframe (byte, with (SIZE SPRITEFRAME_T) high)
; bp - 4:    	; now unused?
; bp - 6:    	; now unused?
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
mov   bx, word ptr es:[si + MOBJ_POS_T.mp_statenum]  ; thing->stateNum
sal   bx, 1

; todo clean all this up. do we need local copy?
; otherwise use ds and rep movsw
mov   ax, word ptr ds:[bx + STATE_T.state_sprite + _states_render]		   ; states_render[thing->stateNum].sprite
mov   byte ptr cs:[SELFMODIFY_set_ax_to_spriteframe+1 - OFFSET R_BSP24_STARTMARKER_], al		   
mov   al, ah
mov   ah, (SIZE SPRITEFRAME_T)
push  ax    ; bp - 2
sub   sp, 01Eh



mov   cx, 6
mov   bx, ss
mov   es, bx					; es is SS i.e. destination segment
mov   ds, dx					; ds is movsw source segment
mov   ax, word ptr ds:[si + MOBJ_POS_T.mp_angle + 2]
mov   word ptr cs:[SELFMODIFY_set_ax_to_angle_highword+1 - OFFSET R_BSP24_STARTMARKER_], ax
mov   al, byte ptr ds:[si + MOBJ_POS_T.mp_flags2]	; 016h  flags2
mov   byte ptr cs:[SELFMODIFY_set_al_to_flags2+1 - OFFSET R_BSP24_STARTMARKER_], al

lea   di, [bp - 01Ah]			; di is the stack area to copy to..

rep   movsw

;si is [si + 0xC] now...


mov   ds, bx					; restore ds to FIXED_DS_SEGMENT
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


mov   word ptr cs:[SELFMODIFY_get_tz_lobits+1 - OFFSET R_BSP24_STARTMARKER_], bx
mov   word ptr cs:[SELFMODIFY_get_tz_hibits+1 - OFFSET R_BSP24_STARTMARKER_], cx

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
mov   word ptr cs:[SELFMODIFY_get_temp_lowbits+1 - OFFSET R_BSP24_STARTMARKER_], ax
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
mov   byte ptr cs:[SELFMODIFY_set_flip+1 - OFFSET R_BSP24_STARTMARKER_], al
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
    

mov   word ptr cs:[SELFMODIFY_set_vis_x1+1 - OFFSET R_BSP24_STARTMARKER_], ax
mov   word ptr cs:[SELFMODIFY_sub_x1+1 - OFFSET R_BSP24_STARTMARKER_], ax
SELFMODIFY_BSP_viewwidth_2:
cmp   ax, 01000h
jle   not_too_far_off_right_side_highbits
jump_to_exit_project_sprite_2:
jmp   exit_project_sprite
not_too_far_off_right_side_highbits:
mov   bx, word ptr [bp - 020h]
xor   ax, ax
mov   al, byte ptr cs:[bx + (SPRITEWIDTHS_OFFSET)]

;    if (usedwidth == 1){
;        usedwidth = 257;
;    }


cmp   al, 1
jne   usedwidth_not_1
mov   ah, al
usedwidth_not_1:

;   temp.h.fracbits = 0;
;    temp.h.intbits = usedwidth;
;    // hack to make this fit in 8 bits, check r_init.c
;    tx.w +=  temp.w;
;	temp.h.intbits = centerx;
;	temp.w += FixedMul (tx.w,xscale.w);

mov   word ptr cs:[SELFMODIFY_set_ax_to_usedwidth+1 - OFFSET R_BSP24_STARTMARKER_], ax


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
mov   word ptr cs:[SELFMODIFY_set_ax_to_x2+1 - OFFSET R_BSP24_STARTMARKER_], dx

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
; mul by 28h or 40. (SIZE VISSPRITE_T)

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

mov   word ptr ds:[si + VISSPRITE_T.vs_scale + 0], ax
mov   word ptr ds:[si + VISSPRITE_T.vs_scale + 2], di

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
mov   bx, word ptr ds:[si + VISSPRITE_T.vs_gz + 0]
add   ax, word ptr ds:[si + VISSPRITE_T.vs_gz + 2]
mov   word ptr ds:[si + VISSPRITE_T.vs_gzt + 0], bx
mov   word ptr ds:[si + VISSPRITE_T.vs_gzt + 2], ax

;    vis->texturemid = vis->gzt.w - viewz.w;

SELFMODIFY_BSP_viewz_lo_4:
sub       bx, 01000h
SELFMODIFY_BSP_viewz_hi_4:
sbb       ax, 01000h
mov   word ptr ds:[si + VISSPRITE_T.vs_texturemid + 0], bx
mov   word ptr ds:[si + VISSPRITE_T.vs_texturemid + 2], ax
SELFMODIFY_set_vis_x1:
mov   ax, 01234h

;    vis->x1 = x1 < 0 ? 0 : x1;

test  ax, ax
jge   x1_positive
xor   ax, ax

x1_positive:
mov   word ptr ds:[si + VISSPRITE_T.vs_x1], ax

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
mov   word ptr ds:[si + VISSPRITE_T.vs_x2], ax
mov   ax, 1
; todo: make a "div65536" function which does a shift strategy rather than needing the full thing
call FixedDivWholeA_BSPLocal_
mov   bx, ax
SELFMODIFY_set_flip:
mov   al, 00h
cmp   al, 0
jne   flip_not_zero

flip_zero: ; zero case
cbw 
mov   word ptr ds:[si + VISSPRITE_T.vs_startfrac + 0], ax ; 0
mov   word ptr ds:[si + VISSPRITE_T.vs_startfrac + 2], ax ; 0
mov   word ptr ds:[si + VISSPRITE_T.vs_xiscale + 0], bx
mov   word ptr ds:[si + VISSPRITE_T.vs_xiscale + 2], dx
jmp   flip_stuff_done

set_intbits_to_129:
mov   ax, 129
jmp intbits_ready

flip_not_zero:
mov   word ptr ds:[si + VISSPRITE_T.vs_startfrac + 0], -1
SELFMODIFY_set_ax_to_usedwidth:
mov   ax, 01234h 
dec   ax
mov   word ptr ds:[si + VISSPRITE_T.vs_startfrac + 2], ax

neg   dx
neg   bx
sbb   dx, 0

mov   word ptr ds:[si + VISSPRITE_T.vs_xiscale + 0], bx
mov   word ptr ds:[si + VISSPRITE_T.vs_xiscale + 2], dx

flip_stuff_done:


;    if (vis->x1 > x1)
;        vis->startfrac += FastMul16u32u((vis->x1-x1),vis->xiscale);

mov   ax, word ptr ds:[si + VISSPRITE_T.vs_x1]
SELFMODIFY_sub_x1:
sub   ax, 01234h
jle   vis_x1_greater_than_x1
les   bx, dword ptr ds:[si + VISSPRITE_T.vs_xiscale + 0]
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

add   word ptr ds:[si + VISSPRITE_T.vs_startfrac + 0], ax
adc   word ptr ds:[si + VISSPRITE_T.vs_startfrac + 2], dx

vis_x1_greater_than_x1:
mov   bx, word ptr [bp - 020h]
mov   word ptr ds:[si + VISSPRITE_T.vs_patch], bx

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
mov   al, byte ptr ds:[_scalelight+bx+di]
mov   byte ptr ds:[si + VISSPRITE_T.vs_colormap], al
LEAVE_MACRO
pop   es
pop   si
ret   

exit_set_fullbright_colormap:
mov   byte ptr ds:[si + VISSPRITE_T.vs_colormap], 0
LEAVE_MACRO
pop   es
pop   si
ret   

SELFMODIFY_BSP_fixedcolormap_2_TARGET:
SELFMODIFY_BSP_fixedcolormap_1:
exit_set_fixed_colormap:
mov   byte ptr ds:[si + VISSPRITE_T.vs_colormap], 0
LEAVE_MACRO
pop   es
pop   si
ret   



exit_set_shadow:
mov   byte ptr ds:[si + VISSPRITE_T.vs_colormap], COLORMAP_SHADOW
LEAVE_MACRO
pop   es
pop   si
ret   

ENDP





;R_AddSprites_

PROC R_AddSprites_ NEAR

; es:bx = sector_t __far* sec

mov   ax, word ptr es:[bx + SECTOR_T.sec_validcount]		; sec->validcount
mov   dx, word ptr ds:[_validcount_global]
cmp   ax, dx
je    exit_add_sprites_quick

mov   word ptr es:[bx + SECTOR_T.sec_validcount], dx
mov   al, byte ptr es:[bx + SECTOR_T.sec_lightlevel]		; sec->lightlevel
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
mov   word ptr cs:[SELFMODIFY_set_spritelights_1 + 1 - OFFSET R_BSP24_STARTMARKER_], ax 
mov   ax, word ptr es:[bx + SECTOR_T.sec_thinglistref]
test  ax, ax
je    exit_add_sprites
mov   si, MOBJPOSLIST_SEGMENT
mov   es, si

loop_things_in_thinglist:
; multiply by 18h ((SIZE MOBJ_POS_T)), AX maxes at MAX_THINKERS - 1 (839), cant 8 bit mul
; tested, imul si, ax, (SIZE MOBJ_POS_T)  still slower


SHIFT_MACRO sal ax 3


mov   si, ax
sal   si, 1
add   si, ax
call  R_ProjectSprite_
mov   ax, word ptr es:[si + MOBJ_POS_T.mp_snextRef]
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




TEXTUREHEIGHTS_OFFSET_IN_TEXTURE_TRANSLATION = (TEXTUREHEIGHTS_SEGMENT - TEXTURETRANSLATION_SEGMENT) SHL 4


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
MAXDRAWSEGS = 256


;R_StoreWallRange_

PROC   R_StoreWallRange_ NEAR
PUBLIC R_StoreWallRange_ 

; bp - 2  ; ax arg
; bp - 4  ; dx arg
; bp - 6     ; hyp lo               ; UNUSED
; bp - 8     ; hyp hi               ; UNUSED
; bp - 0Ah   ; side toptexture      ; UNUSED
; bp - 0Ch   ; side bottomtexture   ; UNUSED
; bp - 0Eh   ; side midtexture      ; UNUSED
; bp - 010h  ; v1.x                 ; UNUSED
; bp - 012h  ; v1.y                 ; UNUSED
; bp - 014h  ; lineflags            ; UNUSED (now bp + 018h)
; bp - 016h  ; offsetangle          ; UNUSED
; bp - 018h  ; _rw_x
; bp - 01Ah  ; _rw_stopx
; bp - 01Bh  ; markceiling
; bp - 01Ch  ; markfloor
; bp - 01Eh  ; UNUSED?              ; UNUSED
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


; bp + 0Ch    ; rw_angle lo from R_AddLine
; bp + 0Eh    ; rw_angle hi from R_AddLine
; bp + 010h   ; curseg_render
; bp + 014h   ; curseglinedef
; bp + 018h   ; lineflags
; bp + 01Eh   ; ax passed into R_AddLine_

             
push      bx ; +8
push      cx ; +6
push      si ; +4
push      di ; +2
push      bp ; +0
mov       bp, sp
push      ax ; bp - 2
push      dx ; bp - 4

sub       sp, 18 ; unused bytes

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;;; START LINE BASED SELF MODIFY BLOCK ;;;;;;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

; note - line jumps past sector, but falls thru to sector check
; sector can not change without line changing.

; todo also skip sector selfmodifies lazily

SELFMODIFY_skip_curseg_based_selfmodify:
mov       bx, (SELFMODIFY_skip_curseg_based_selfmodify_TARGET - SELFMODIFY_skip_curseg_based_selfmodify_AFTER)  ;  selfmodifies into mov bx, imm
SELFMODIFY_skip_curseg_based_selfmodify_AFTER:

mov       bx, word ptr [bp + 010h]  ; curseg_render     ; turns into a jump past selfmodifying code once this next code block runs. 

xor       ax, ax
mov       si, word ptr ds:[bx + 6]  ; todo what's this again? lineside?

SHIFT_MACRO shl si 2

; todo pull this out into outer func?
mov       ax, word ptr ds:[si+_sides_render]
mov       word ptr cs:[SELFMODIFY_BSP_siderenderrowoffset_1+1 - OFFSET R_BSP24_STARTMARKER_], ax
mov       word ptr cs:[SELFMODIFY_BSP_siderenderrowoffset_2+1 - OFFSET R_BSP24_STARTMARKER_], ax
shl       si, 1

mov       cx, ds  ; store for later.
les       bx, dword ptr ds:[bx]   ; vertexes
mov       di, es ; v2

mov   ds, word ptr ds:[_VERTEXES_SEGMENT_PTR]
SHIFT_MACRO shl bx 2
SHIFT_MACRO shl di 2


les       bx, dword ptr ds:[bx] ;v1.x
mov       ax, es

mov       word ptr cs:[SELFMODIFY_BSP_v1x+1 - OFFSET R_BSP24_STARTMARKER_], bx
mov       word ptr cs:[SELFMODIFY_BSP_v1y+1 - OFFSET R_BSP24_STARTMARKER_], ax

sub       ax, word ptr ds:[di + VERTEX_T.v_y]
mov       dl, 04Ah  ; dec dx
je        v2_y_equals_v1_y
sub       bx, word ptr ds:[di + VERTEX_T.v_x]
mov       dl, 090h  ; nop
jne       v2_y_not_equals_v1_y
mov       dl, 042h  ; inc dx
v2_y_not_equals_v1_y:
v2_y_equals_v1_y:

mov       byte ptr cs:[SELFMODIFY_addlightnum_delta - OFFSET R_BSP24_STARTMARKER_], dl
; check for backsector and load side texture data
; bx, dx, di free...

   mov       ax, TEXTURETRANSLATION_SEGMENT
   mov       es, ax

   ; default jump locations for backsecnum == null
   xor       dx, dx  ; jump zero
   mov       bx, ((SELFMODIFY_do_backsector_work_or_not_TARGET_NULL - SELFMODIFY_do_backsector_work_or_not_AFTER) )
   cmp       word ptr ss:[_backsector], SECNUM_NULL

   mov       ds, word ptr ss:[_SIDES_SEGMENT_PTR]
   ; ds:si is a SIDE_T

   je        selfmodify_mid_only

   ; overwrite jump locations for backsecnum!=null
   mov       dx, ((SELFMODIFY_jmp_two_sided_or_not_TARGET - SELFMODIFY_jmp_two_sided_or_not_AFTER) )
   mov       bx, ((SELFMODIFY_do_backsector_work_or_not_TARGET_NOTNULL - SELFMODIFY_do_backsector_work_or_not_AFTER) )
   ; two sides wall may have bottom and top textures


   ; read all the sides fields now. ;preshift them as they are word lookups

   lodsw     ; side toptexture
   test      ax, ax
   jz        skip_toptex_selfmodify
   xchg      ax, di
   xor       ax, ax
   mov       al, byte ptr es:[di + TEXTUREHEIGHTS_OFFSET_IN_TEXTURE_TRANSLATION]
   inc       ax
   mov       word ptr cs:[SELFMODIFY_add_texturetopheight_plus_one+2- OFFSET R_BSP24_STARTMARKER_], ax
   sal       di, 1
   mov       ax, word ptr es:[di]
   mov       word ptr cs:[SELFMODIFY_settoptexturetranslation_lookup+1- OFFSET R_BSP24_STARTMARKER_], ax

   skip_toptex_selfmodify:
   lodsw     ; side bottexture  ; faster to just do it than branch?
   xchg      ax, di
   sal       di, 1
   mov       ax, word ptr es:[di]
   mov       word ptr cs:[SELFMODIFY_setbottexturetranslation_lookup+1- OFFSET R_BSP24_STARTMARKER_], ax

   sub       si, 4

selfmodify_mid_only:
   ; twosided textures can still have a mid texture (invisible walls like E1M1)

   add       si, 4
   lodsw     ; side midtexture
   test      ax, ax
   jz        skip_midptex_selfmodify
   xchg      ax, di
   xor       ax, ax
   mov       al, byte ptr es:[di + TEXTUREHEIGHTS_OFFSET_IN_TEXTURE_TRANSLATION]
   inc       ax
   mov       word ptr cs:[SELFMODIFY_add_texturemidheight_plus_one+1- OFFSET R_BSP24_STARTMARKER_], ax
   sal       di, 1
   mov       ax, word ptr es:[di]
   mov       word ptr cs:[SELFMODIFY_setmidtexturetranslation_lookup+1- OFFSET R_BSP24_STARTMARKER_], ax

   ; create jmp instruction
   mov       ax, ((SELFMODIFY_has_midtexture_or_not_TARGET - SELFMODIFY_has_midtexture_or_not_AFTER) SHL 8) + 0EBh

   jmp       finish_midtex_selfmodify
skip_midptex_selfmodify:
   mov       ax, 0c031h  ; xor ax, ax
finish_midtex_selfmodify:

   ; set some jumps and instructions based on secnumnull, midtexture
   mov       word ptr cs:[SELFMODIFY_has_midtexture_or_not - OFFSET R_BSP24_STARTMARKER_], ax
   mov       word ptr cs:[SELFMODIFY_jmp_two_sided_or_not + 1 - OFFSET R_BSP24_STARTMARKER_], dx
   mov       word ptr cs:[SELFMODIFY_do_backsector_work_or_not + 1 - OFFSET R_BSP24_STARTMARKER_], bx


   lodsw     ; textureoffset todo can be 8 bit
   mov       word ptr cs:[SELFMODIFY_BSP_sidetextureoffset+1 - OFFSET R_BSP24_STARTMARKER_], ax

   mov       ds, cx  ; restore ds..

   mov       si, word ptr [bp + 014h]
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

  mov       bx, word ptr [bp + 01Eh]
   sal       bx, 1       ;  curseg word lookup

   mov       ax, word ptr ds:[bx+_seg_normalangles]
   mov       word ptr cs:[SELFMODIFY_sub_rw_normal_angle_1+1 - OFFSET R_BSP24_STARTMARKER_], ax
   xchg      ax, si

   SELFMODIFY_set_viewanglesr3_1:
   mov       ax, 01000h
   ;add       ah, 8  ; preadded
   sub       ax, si
   and       ah, FINE_ANGLE_HIGH_BYTE

   ; set centerangle in rendersegloop
   mov       word ptr cs:[SELFMODIFY_set_rw_center_angle+1 - OFFSET R_BSP24_STARTMARKER_], ax
   xchg      ax, si
   SHIFT_MACRO shl ax SHORTTOFINESHIFT
   mov       word ptr cs:[SELFMODIFY_set_rw_normal_angle_shift3+1 - OFFSET R_BSP24_STARTMARKER_], ax


   ;	offsetangle = (abs((rw_normalangle_shiftleft3) - (rw_angle1.hu.intbits)) >> 1) & 0xFFFC;
   sub       ax, word ptr [bp + 0Eh]   ; rw_angle hi from R_AddLine
   cwd       
   xor       ax, dx		; abs by sign bits
   sub       ax, dx
   sar       ax, 1

   and       al, 0FCh
   mov       word ptr cs:[SELFMODIFY_set_offsetangle+1], ax
   mov       si, FINE_ANG90_NOSHIFT
   sub       si, ax 

; calculate hyp inlined

      push  si

      ;    dx = labs(x.w - viewx.w);
      ;  x = ax register
      ;  y = dx

      SELFMODIFY_BSP_v1x:
      mov       cx, 01000h
      SELFMODIFY_BSP_v1y:
      mov       dx, 01000h

      xor   bx, bx
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

      call  FixedDivBSPLocal_

      ; shift 5. since we do a tantoangle lookup... this maxes at 2048
      ; todo 386
      sar   dx, 1
      rcr   ax, 1
      sar   dx, 1
      rcr   ax, 1
      sar   dx, 1
      rcr   ax, 1
      and   al, 0FCh
      mov   dx, di ; move di to dx early to free up di for les + di + bx combo


      xchg  ax, bx
      mov   es, word ptr ds:[_tantoangle_segment] 
      mov   bx, word ptr es:[bx + 2] ; get just intbits..

      ;    dist = FixedDiv (dx, finesine[angle] );	

      add   bh, 040h ; ang90 highbits
      mov   ax, FINESINE_SEGMENT
      mov   es, ax
      shr   bx, 1
      and   bl, 0FCh
      mov   ax, si
      les   bx, dword ptr es:[bx]
      mov   cx, es
      call  FixedDivBSPLocal_

      xchg  ax, bx  ; result in cx:bx
      mov   cx, dx


      ; store result
      mov   word ptr cs:[SELFMODIFY_set_PointToDist_result_lo+1], bx
      mov   word ptr cs:[SELFMODIFY_set_PointToDist_result_hi+1], cx

; end calculate hyp inlined

   ; hyp in cx:bx.

   mov       ax, FINESINE_SEGMENT
   pop       dx  ; angle calculated prior

   call      FixedMulTrigNoShiftBSPLocal_


   do_set_rw_distance:

   ; self modifying code for rw_distance
   mov   word ptr cs:[SELFMODIFY_set_bx_rw_distance_lo+1 - OFFSET R_BSP24_STARTMARKER_], ax
   mov   word ptr cs:[SELFMODIFY_set_cx_rw_distance_hi+1 - OFFSET R_BSP24_STARTMARKER_], dx
   mov   word ptr cs:[SELFMODIFY_get_rw_distance_lo_1+1 - OFFSET R_BSP24_STARTMARKER_], ax
   mov   word ptr cs:[SELFMODIFY_get_rw_distance_hi_1+1 - OFFSET R_BSP24_STARTMARKER_], dx




mov       byte ptr cs:[SELFMODIFY_skip_curseg_based_selfmodify], 0E9h  ; jmp here

SELFMODIFY_skip_curseg_based_selfmodify_TARGET:
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;;; END LINE BASED SELF MODIFY BLOCK ;;;;;;;;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

 

done_setting_rw_distance:
les       di, dword ptr ds:[_ds_p]
mov       ax, word ptr [bp + 01Eh]  ; R_AddLine line num

stosw              ; +0


mov       ax, word ptr [bp - 2]
push      ax   ; bp - 018h r  w_x
stosw              ; +2
xchg      ax, bx ; bx gets bp - 2
mov       ax, word ptr [bp - 4]
stosw              ; +4

inc       ax
push      ax   ; bp - 01Ah  rw_stopx
sub       sp, 014h   ; ;30h now

mov       ax, XTOVIEWANGLE_SEGMENT   ; todo selfmodify all these?
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
ASSUME DS:R_BSP_24_TEXT
; rw_scalestep is ready. write it forward as selfmodifying code here

mov       word ptr ds:[SELFMODIFY_get_rwscalestep_lo_1+1 - OFFSET R_BSP24_STARTMARKER_], ax
mov       word ptr ds:[SELFMODIFY_get_rwscalestep_lo_2+1 - OFFSET R_BSP24_STARTMARKER_], ax
mov       word ptr ds:[SELFMODIFY_get_rwscalestep_lo_3+1 - OFFSET R_BSP24_STARTMARKER_], ax
mov       word ptr ds:[SELFMODIFY_get_rwscalestep_lo_4+1 - OFFSET R_BSP24_STARTMARKER_], ax
mov       word ptr ds:[SELFMODIFY_add_rwscale_lo+4 - OFFSET R_BSP24_STARTMARKER_], ax
mov       word ptr ds:[SELFMODIFY_sub_rwscale_lo+3 - OFFSET R_BSP24_STARTMARKER_], ax

xchg      ax, dx
mov       word ptr ds:[SELFMODIFY_get_rwscalestep_hi_1+1 - OFFSET R_BSP24_STARTMARKER_], ax
mov       word ptr ds:[SELFMODIFY_get_rwscalestep_hi_2+1 - OFFSET R_BSP24_STARTMARKER_], ax
mov       word ptr ds:[SELFMODIFY_get_rwscalestep_hi_3+1 - OFFSET R_BSP24_STARTMARKER_], ax
mov       word ptr ds:[SELFMODIFY_get_rwscalestep_hi_4+1 - OFFSET R_BSP24_STARTMARKER_], ax


mov       word ptr ds:[SELFMODIFY_add_rwscale_hi+4 - OFFSET R_BSP24_STARTMARKER_], ax
mov       word ptr ds:[SELFMODIFY_sub_rwscale_hi+3 - OFFSET R_BSP24_STARTMARKER_], ax



; todo change these in 386 mode to shld?
SELFMODIFY_BSP_detailshift_1:
shl   dx, 1
rcl   ax, 1
shift_rw_scale_once:
shl   dx, 1
rcl   ax, 1
finished_shifting_rw_scale:

mov       word ptr ds:[SELFMODIFY_add_to_rwscale_hi_1+3 - OFFSET R_BSP24_STARTMARKER_], ax
mov       word ptr ds:[SELFMODIFY_add_to_rwscale_hi_2+3 - OFFSET R_BSP24_STARTMARKER_], ax
xchg      ax, dx
mov       word ptr ds:[SELFMODIFY_add_to_rwscale_lo_1+3 - OFFSET R_BSP24_STARTMARKER_], ax
mov       word ptr ds:[SELFMODIFY_add_to_rwscale_lo_2+3 - OFFSET R_BSP24_STARTMARKER_], ax

mov       si, ss   ; restore DS
mov       ds, si
;ASSUME DS:DGROUP  ; lods coming up



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
mov       byte ptr cs:[SELFMODIFY_check_for_any_tex+1 - OFFSET R_BSP24_STARTMARKER_], al

les       bx, dword ptr ds:[_ds_p]
mov       word ptr es:[bx + DRAWSEG_T.drawseg_maskedtexturecol_val], NULL_TEX_COL

mov       ax, cs
mov       ds, ax


SELFMODIFY_jmp_two_sided_or_not:
jmp       handle_two_sided_line  ; might turn into a jmp 0 to go to handle_single_sided_line
SELFMODIFY_jmp_two_sided_or_not_AFTER:
handle_single_sided_line:

ASSUME DS:R_BSP_24_TEXT

SELFMODIFY_BSP_drawtype_1:
SELFMODIFY_BSP_drawtype_1_AFTER = SELFMODIFY_BSP_drawtype_1 + 2


mov       ax, ((SELFMODIFY_BSP_midtextureonly_skip_pixhighlow_1_TARGET - SELFMODIFY_BSP_midtextureonly_skip_pixhighlow_1_AFTER) SHL 8) + 0EBh
mov       word ptr ds:[SELFMODIFY_BSP_midtextureonly_skip_pixhighlow_1 - OFFSET R_BSP24_STARTMARKER_], ax
mov       ah, SELFMODIFY_BSP_midtextureonly_skip_pixhighlow_2_TARGET - SELFMODIFY_BSP_midtextureonly_skip_pixhighlow_2_AFTER
mov       word ptr ds:[SELFMODIFY_BSP_midtextureonly_skip_pixhighlow_2 - OFFSET R_BSP24_STARTMARKER_], ax
mov       ah, SELFMODIFY_BSP_midtextureonly_skip_pixhighlow_3_TARGET - SELFMODIFY_BSP_midtextureonly_skip_pixhighlow_3_AFTER
mov       word ptr ds:[SELFMODIFY_BSP_midtextureonly_skip_pixhighlow_3 - OFFSET R_BSP24_STARTMARKER_], ax
mov       ah, SELFMODIFY_BSP_midtextureonly_skip_pixhighlow_5_TARGET - SELFMODIFY_BSP_midtextureonly_skip_pixhighlow_5_AFTER
mov       word ptr ds:[SELFMODIFY_BSP_midtextureonly_skip_pixhighlow_5 - OFFSET R_BSP24_STARTMARKER_], ax

;mov       ax, ((SELFMODIFY_BSP_midtextureonly_skip_pixhighlow_4_TARGET - SELFMODIFY_BSP_midtextureonly_skip_pixhighlow_4_AFTER) SHL 8) + 0E2h  ; LOOP instruction
;mov       word ptr ds:[SELFMODIFY_BSP_midtextureonly_skip_pixhighlow_4 - OFFSET R_BSP24_STARTMARKER_], ax


 
mov       word ptr ds:[SELFMODIFY_BSP_drawtype_2 - OFFSET R_BSP24_STARTMARKER_], 089B8h   ; mov ax, xx89
mov       word ptr ds:[SELFMODIFY_BSP_drawtype_1 - OFFSET R_BSP24_STARTMARKER_], ((SELFMODIFY_BSP_drawtype_1_TARGET - SELFMODIFY_BSP_drawtype_1_AFTER) SHL 8) + 0EBh

mov       byte ptr ds:[SELFMODIFY_BSP_midtexture_return_jmp+0 - OFFSET R_BSP24_STARTMARKER_], 026h    ; es:
mov       word ptr ds:[SELFMODIFY_BSP_midtexture_return_jmp+1 - OFFSET R_BSP24_STARTMARKER_], 087C7h  ; next 2 bytes of following instr (mov   word ptr es:[bx + OFFSET_CEILINGCLIP], 01000h)

mov       byte ptr ds:[SELFMODIFY_BSP_midtexture - OFFSET R_BSP24_STARTMARKER_], 039h     ; cmp di,
mov       word ptr ds:[SELFMODIFY_BSP_midtexture+1 - OFFSET R_BSP24_STARTMARKER_], 07CF7h   ; (cmp di,) si, jl


SELFMODIFY_BSP_drawtype_1_TARGET:

;es:bx still side
SELFMODIFY_setmidtexturetranslation_lookup:
mov       ax, 01000h

; write the high byte of the word.
; prev two bytes will be a jump or mov cx with the low byte



mov       word ptr ds:[SELFMODIFY_BSP_set_midtexture+1 - OFFSET R_BSP24_STARTMARKER_], ax
; are any bits set?
or        al, ah
or        byte ptr ds:[SELFMODIFY_check_for_any_tex+1 - OFFSET R_BSP24_STARTMARKER_], al



mov       word ptr [bp - 01Ch], 0101h ; set markfloor and markceiling
test      byte ptr [bp + 018h], ML_DONTPEGBOTTOM
jne       do_peg_bottom
dont_peg_bottom:
mov       ax, word ptr [bp - 040h]
mov       word ptr ds:[SELFMODIFY_set_midtexturemid_lo+1 - OFFSET R_BSP24_STARTMARKER_], ax
mov       ax, word ptr [bp - 03Eh]
; ax has rw_midtexturemid+2
jmp       done_with_bottom_peg



do_peg_bottom:
mov       ax, word ptr [bp - 034h]
SELFMODIFY_BSP_viewz_shortheight_5:
sub       ax, 01000h
xor       cx, cx
; todo 386
sar       ax, 1
rcr       cx, 1
sar       ax, 1
rcr       cx, 1
sar       ax, 1
rcr       cx, 1
mov       word ptr ds:[SELFMODIFY_set_midtexturemid_lo+1 - OFFSET R_BSP24_STARTMARKER_], cx


; add textureheight+1

SELFMODIFY_add_texturemidheight_plus_one:
add       ax, 01000h
done_with_bottom_peg:
; ax:cx has rw_midtexturemid



SELFMODIFY_BSP_siderenderrowoffset_1:
add       ax, 01000h

mov       word ptr ds:[SELFMODIFY_set_midtexturemid_hi+1 - OFFSET R_BSP24_STARTMARKER_], ax

mov       bx, ss   ; restore DS
mov       ds, bx
;ASSUME DS:DGROUP


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
mov       byte ptr cs:[SELFMODIFY_get_maskedtexture_1+1 - OFFSET R_BSP24_STARTMARKER_], al
mov       byte ptr cs:[SELFMODIFY_get_maskedtexture_2+1 - OFFSET R_BSP24_STARTMARKER_], al

; create segtextured value
SELFMODIFY_check_for_any_tex:
or   	  al, 0

; set segtextured in rendersegloop



jne       do_seg_textured_stuff
mov       word ptr cs:[SELFMODIFY_BSP_get_segtextured - OFFSET R_BSP24_STARTMARKER_], ((SELFMODIFY_BSP_get_segtextured_TARGET - SELFMODIFY_BSP_get_segtextured_AFTER) SHL 8) + 0EBh

jmp       seg_textured_check_done
do_seg_textured_stuff:
mov       word ptr cs:[SELFMODIFY_BSP_get_segtextured - OFFSET R_BSP24_STARTMARKER_], 0C089h ; nop
SELFMODIFY_set_offsetangle:
mov       dx, 01000h
cmp       dx, FINE_ANG180_NOSHIFT ; 04000h
jbe       offsetangle_greater_than_fineang180
neg       dx
and       dh, MOD_FINE_ANGLE_NOSHIFT_HIGHBITS

offsetangle_greater_than_fineang180:

SELFMODIFY_set_PointToDist_result_hi:
mov       cx, 01000h
SELFMODIFY_set_PointToDist_result_lo:
mov       bx, 01000h

; dx is offsetangle

cmp       dx, FINE_ANG90_NOSHIFT ; 02000h
ja        offsetangle_greater_than_fineang90

mov       ax, FINESINE_SEGMENT
call      FixedMulTrigNoShiftBSPLocal_
; used later, dont change?
; dx:ax is rw_offset
xchg      ax, dx
jmp       done_with_offsetangle_stuff
offsetangle_greater_than_fineang90:
xchg      ax, cx
mov       dx, bx



done_with_offsetangle_stuff:
; ax:dx is rw_offset

xor       cx, cx

SELFMODIFY_set_rw_normal_angle_shift3:
mov       bx, 01000h
sub       cx, word ptr [bp + 0Ch]   ; rw_angle lo from R_AddLine
sbb       bx, word ptr [bp + 0Eh]   ; rw_angle hi from R_AddLine

;cmp       bx, ANG180_HIGHBITS
;jae       tempangle_not_smaller_than_fineang180
; bx is already _rw_offset
js        tempangle_not_smaller_than_fineang180
neg       ax
neg       dx
sbb       ax, 0
tempangle_not_smaller_than_fineang180:




SELFMODIFY_BSP_sidetextureoffset:
add       ax, 01000h

add       ax, word ptr [bp + 010h]
add       ax, 4
; rw_offset ready to be written to rendersegloop:
mov   word ptr cs:[SELFMODIFY_set_cx_rw_offset_lo+1 - OFFSET R_BSP24_STARTMARKER_], dx
mov   word ptr cs:[SELFMODIFY_set_ax_rw_offset_hi+1 - OFFSET R_BSP24_STARTMARKER_], ax




;	    lightnum = (frontsector->lightlevel >> LIGHTSEGSHIFT)+extralight;


SELFMODIFY_BSP_fixedcolormap_3:
jmp SHORT seg_textured_check_done    ; dont check walllights if fixedcolormap
SELFMODIFY_BSP_fixedcolormap_3_AFTER:
mov       al, byte ptr [bp - 03Bh]
xor       ah, ah
cwd
mov       bx, dx
SELFMODIFY_BSP_extralight2:
mov       dl, 0

; todo instead of shifting back and forth just use mults of 16
SHIFT_MACRO shr ax 4



add       dl, al

SELFMODIFY_addlightnum_delta:
dec       dx  ; nop carries flags from add dl, al. dec and inc will set signed accordingly

js      done_setting_ax_to_wallights ; ax is 0, set to scalelights[0]

lightnum_greater_than_0:
cmp       dl, LIGHTLEVELS
mov       bx, 720 + OFFSET _scalelight  ; lightnum_max
jnl       done_setting_ax_to_wallights_with_offset


mov       al, 48
mul       dl
xchg      ax, bx
done_setting_ax_to_wallights:
add       bx, OFFSET _scalelight
done_setting_ax_to_wallights_with_offset:


; write walllights to rendersegloop
mov   word ptr cs:[SELFMODIFY_add_wallights+2 - OFFSET R_BSP24_STARTMARKER_], bx
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

   shl  ecx, 16
   mov  cx, bx
   xchg ax, dx
   shl  eax, 16
   xchg ax, dx
   imul  ecx
   shr  eax, 16



ELSE
   mov  word ptr cs:[_SELFMODIFY_restore_si_after_mults+1], si
   MOV  SI, DX
   PUSH AX
   MUL  BX
   MOV  word ptr cs:[_selfmodify_restore_dx_2+1], DX
   MOV  AX, SI
   MUL  CX
   XCHG AX, SI
   CWD
   AND  DX, BX
   SUB  SI, DX
   MUL  BX
   _selfmodify_restore_dx_2:
   ADD  AX, 01000h
   ADC  SI, DX
   XCHG AX, CX
   CWD
   POP  BX
   AND  DX, BX
   SUB  SI, DX
   MUL  BX
   ADD  AX, CX
   ADC  DX, SI

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

   shl  ecx, 16
   mov  cx, bx
   xchg ax, dx
   shl  eax, 16
   xchg ax, dx
   imul  ecx
   shr  eax, 16



ELSE
; si not preserved
   MOV  SI, DX
   PUSH AX
   MUL  BX
   MOV  word ptr cs:[_selfmodify_restore_dx_3+1], DX
   MOV  AX, SI
   MUL  CX
   XCHG AX, SI
   CWD
   AND  DX, BX
   SUB  SI, DX
   MUL  BX
   _selfmodify_restore_dx_3:
   ADD  AX, 01000h
   ADC  SI, DX
   XCHG AX, CX
   CWD
   POP  BX
   AND  DX, BX
   SUB  SI, DX
   MUL  BX
   ADD  AX, CX
   ADC  DX, SI

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
mov       word ptr cs:[SELFMODIFY_set_ceilingplaneindex+1 - OFFSET R_BSP24_STARTMARKER_], ax
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
mov       word ptr cs:[SELFMODIFY_set_floorplaneindex+1 - OFFSET R_BSP24_STARTMARKER_], ax
dont_mark_floor:
mov       ax, word ptr [bp - 4]
cmp       ax, word ptr [bp - 2]
jge       at_least_one_column_to_draw
jmp       check_spr_top_clip
at_least_one_column_to_draw:

; todo better use DS as a scratch var for mults etc ahead.

ASSUME DS:R_BSP_24_TEXT
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

   shl  ecx, 16
   mov  cx, bx
   xchg ax, dx
   shl  eax, 16
   xchg ax, dx
   imul  ecx
   shr  eax, 16



ELSE
; si not preserved
   MOV  SI, DX
   PUSH AX
   MUL  BX
   MOV  word ptr cs:[_selfmodify_restore_dx_4+1], DX
   MOV  AX, SI
   MUL  CX
   XCHG AX, SI
   CWD
   AND  DX, BX
   SUB  SI, DX
   MUL  BX
   _selfmodify_restore_dx_4:
   ADD  AX, 01000h
   ADC  SI, DX
   XCHG AX, CX
   CWD
   POP  BX
   AND  DX, BX
   SUB  SI, DX
   MUL  BX
   ADD  AX, CX
   ADC  DX, SI

ENDIF

;end inlined FixedMulBSPLocal_

neg       dx
neg       ax
sbb       dx, 0

; dx:ax are topstep

mov       word ptr ds:[SELFMODIFY_sub_topstep_lo+3 - OFFSET R_BSP24_STARTMARKER_], ax
mov       word ptr ds:[SELFMODIFY_add_topstep_lo+4 - OFFSET R_BSP24_STARTMARKER_], ax
xchg      ax, dx
mov       word ptr ds:[SELFMODIFY_sub_topstep_hi+3 - OFFSET R_BSP24_STARTMARKER_], ax
mov       word ptr ds:[SELFMODIFY_add_topstep_hi+4 - OFFSET R_BSP24_STARTMARKER_], ax


SELFMODIFY_BSP_detailshift_2:
shl       dx, 1
rcl       ax, 1
shift_topstep_once:
shl       dx, 1
rcl       ax, 1

finished_shifting_topstep:

mov       word ptr ds:[SELFMODIFY_add_to_topfrac_hi_1+3 - OFFSET R_BSP24_STARTMARKER_], ax
mov       word ptr ds:[SELFMODIFY_add_to_topfrac_hi_2+3 - OFFSET R_BSP24_STARTMARKER_], ax
xchg      ax, dx
mov       word ptr ds:[SELFMODIFY_add_to_topfrac_lo_1+3 - OFFSET R_BSP24_STARTMARKER_], ax
mov       word ptr ds:[SELFMODIFY_add_to_topfrac_lo_2+3 - OFFSET R_BSP24_STARTMARKER_], ax


les       bx, dword ptr [bp - 044h]
mov       cx, es
SELFMODIFY_get_rwscalestep_lo_2:
mov       ax, 01000h
SELFMODIFY_get_rwscalestep_hi_2:
mov       dx, 01000h

;start inlined FixedMulBSPLocal_

IF COMPISA GE COMPILE_386

   shl  ecx, 16
   mov  cx, bx
   xchg ax, dx
   shl  eax, 16
   xchg ax, dx
   imul  ecx
   shr  eax, 16



ELSE

   MOV  SI, DX
   PUSH AX
   MUL  BX
   MOV  word ptr cs:[_selfmodify_restore_dx_5+1], DX
   MOV  AX, SI
   MUL  CX
   XCHG AX, SI
   CWD
   AND  DX, BX
   SUB  SI, DX
   MUL  BX
   _selfmodify_restore_dx_5:
   ADD  AX, 01000h
   ADC  SI, DX
   XCHG AX, CX
   CWD
   POP  BX
   AND  DX, BX
   SUB  SI, DX
   MUL  BX
   ADD  AX, CX
   ADC  DX, SI
_SELFMODIFY_restore_si_after_mults:
   mov  si, 01000h       ; restore si after these several mults

ENDIF
;end inlined FixedMulBSPLocal_

neg       dx
neg       ax
sbb       dx, 0

; dx:ax are bottomstep

mov       word ptr ds:[SELFMODIFY_sub_botstep_lo+3 - OFFSET R_BSP24_STARTMARKER_], ax
mov       word ptr ds:[SELFMODIFY_add_botstep_lo+4 - OFFSET R_BSP24_STARTMARKER_], ax
xchg      ax, dx
mov       word ptr ds:[SELFMODIFY_sub_botstep_hi+3 - OFFSET R_BSP24_STARTMARKER_], ax
mov       word ptr ds:[SELFMODIFY_add_botstep_hi+4 - OFFSET R_BSP24_STARTMARKER_], ax

SELFMODIFY_BSP_detailshift_3:
shl       dx, 1
rcl       ax, 1
shift_botstep_once:
shl       dx, 1
rcl       ax, 1

finished_shifting_botstep:

mov       word ptr ds:[SELFMODIFY_add_to_bottomfrac_hi_1+3 - OFFSET R_BSP24_STARTMARKER_], ax
mov       word ptr ds:[SELFMODIFY_add_to_bottomfrac_hi_2+3 - OFFSET R_BSP24_STARTMARKER_], ax
xchg      ax, dx
mov       word ptr ds:[SELFMODIFY_add_to_bottomfrac_lo_1+3 - OFFSET R_BSP24_STARTMARKER_], ax
mov       word ptr ds:[SELFMODIFY_add_to_bottomfrac_lo_2+3 - OFFSET R_BSP24_STARTMARKER_], ax




SELFMODIFY_do_backsector_work_or_not:
jmp       skip_pixlow_step
SELFMODIFY_do_backsector_work_or_not_AFTER:
jmp_to_skip_pixhigh_step:
jmp skip_pixhigh_step
SELFMODIFY_do_backsector_work_or_not_TARGET_NOTNULL:
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

   shl  ecx, 16
   mov  cx, bx
   xchg ax, dx
   shl  eax, 16
   xchg ax, dx
   imul  ecx
   shr  eax, 16



ELSE
   MOV  ES, SI
   MOV  SI, DX
   PUSH AX
   MUL  BX
   MOV  word ptr cs:[_selfmodify_restore_dx_6+1], DX
   MOV  AX, SI
   MUL  CX
   XCHG AX, SI
   CWD
   AND  DX, BX
   SUB  SI, DX
   MUL  BX
   _selfmodify_restore_dx_6:
   ADD  AX, 01000h
   ADC  SI, DX
   XCHG AX, CX
   CWD
   POP  BX
   AND  DX, BX
   SUB  SI, DX
   MUL  BX
   ADD  AX, CX
   ADC  DX, SI
   MOV  SI, ES
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

   shl  ecx, 16
   mov  cx, bx
   xchg ax, dx
   shl  eax, 16
   xchg ax, dx
   imul  ecx
   shr  eax, 16



ELSE
   MOV  ES, SI
   MOV  SI, DX
   PUSH AX
   MUL  BX
   MOV  word ptr cs:[_selfmodify_restore_dx_7+1], DX
   MOV  AX, SI
   MUL  CX
   XCHG AX, SI
   CWD
   AND  DX, BX
   SUB  SI, DX
   MUL  BX
   _selfmodify_restore_dx_7:
   ADD  AX, 01000h
   ADC  SI, DX
   XCHG AX, CX
   CWD
   POP  BX
   AND  DX, BX
   SUB  SI, DX
   MUL  BX
   ADD  AX, CX
   ADC  DX, SI
   MOV  SI, ES
ENDIF

;end inlined FixedMulBSPLocal_


neg       dx
neg       ax
sbb       dx, 0


; dx:ax is pixhighstep.
; self modifying code to write to pixlowstep usages.


mov       word ptr ds:[SELFMODIFY_sub_pixhigh_lo+3 - OFFSET R_BSP24_STARTMARKER_], ax
mov       word ptr ds:[SELFMODIFY_add_pixhighstep_lo+4 - OFFSET R_BSP24_STARTMARKER_], ax
xchg      ax, dx
mov       word ptr ds:[SELFMODIFY_sub_pixhigh_hi+3 - OFFSET R_BSP24_STARTMARKER_], ax
mov       word ptr ds:[SELFMODIFY_add_pixhighstep_hi+4 - OFFSET R_BSP24_STARTMARKER_], ax

SELFMODIFY_BSP_detailshift_4:
shl       dx, 1
rcl       ax, 1
shift_pixhighstep_once:
shl       dx, 1
rcl       ax, 1
done_shifting_pixhighstep:
mov       word ptr ds:[SELFMODIFY_add_to_pixhigh_hi_1+3 - OFFSET R_BSP24_STARTMARKER_], ax
mov       word ptr ds:[SELFMODIFY_add_to_pixhigh_hi_2+3 - OFFSET R_BSP24_STARTMARKER_], ax
xchg      ax, dx
mov       word ptr ds:[SELFMODIFY_add_to_pixhigh_lo_1+3 - OFFSET R_BSP24_STARTMARKER_], ax
mov       word ptr ds:[SELFMODIFY_add_to_pixhigh_lo_2+3 - OFFSET R_BSP24_STARTMARKER_], ax


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

   shl  ecx, 16
   mov  cx, bx
   xchg ax, dx
   shl  eax, 16
   xchg ax, dx
   imul  ecx
   shr  eax, 16



ELSE
   MOV  ES, SI
   MOV  SI, DX
   PUSH AX
   MUL  BX
   MOV  word ptr cs:[_selfmodify_restore_dx_8+1], DX
   MOV  AX, SI
   MUL  CX
   XCHG AX, SI
   CWD
   AND  DX, BX
   SUB  SI, DX
   MUL  BX
   _selfmodify_restore_dx_8:
   ADD  AX, 01000h
   ADC  SI, DX
   XCHG AX, CX
   CWD
   POP  BX
   AND  DX, BX
   SUB  SI, DX
   MUL  BX
   ADD  AX, CX
   ADC  DX, SI
   MOV  SI, ES
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

   shl  ecx, 16
   mov  cx, bx
   xchg ax, dx
   shl  eax, 16
   xchg ax, dx
   imul  ecx
   shr  eax, 16



ELSE
; si, di not preserved
; note: mul by di:si not cx:bx! roles reversed.

   MOV  CX, DX
   MOV  ES, AX
   MUL  SI
   MOV  BX, DX
   MOV  AX, CX
   MUL  DI
   XCHG AX, CX
   CWD
   AND  DX, SI
   SUB  CX, DX
   MUL  SI

   ADD  AX, BX
   ADC  CX, DX
   XCHG AX, DI
   CWD
   MOV  SI, ES
   AND  DX, SI
   SUB  CX, DX
   MUL  SI
   ADD  AX, DI
   ADC  DX, CX

ENDIF

;end inlined FixedMulBSPLocal_

neg       dx
neg       ax
sbb       dx, 0

; dx:ax is pixlowstep.
; self modifying code to write to pixlowstep usages.


mov       word ptr ds:[SELFMODIFY_sub_pixlow_lo+3 - OFFSET R_BSP24_STARTMARKER_], ax
mov       word ptr ds:[SELFMODIFY_add_pixlowstep_lo+4 - OFFSET R_BSP24_STARTMARKER_], ax
xchg      ax, dx
mov       word ptr ds:[SELFMODIFY_sub_pixlow_hi+3 - OFFSET R_BSP24_STARTMARKER_], ax
mov       word ptr ds:[SELFMODIFY_add_pixlowstep_hi+4 - OFFSET R_BSP24_STARTMARKER_], ax

; todo 386
SELFMODIFY_BSP_detailshift_5:
shl       dx, 1
rcl       ax, 1
shift_pixlowstep_once:
shl       dx, 1
rcl       ax, 1
done_shifting_pixlowstep:
mov       word ptr ds:[SELFMODIFY_add_to_pixlow_hi_1+3 - OFFSET R_BSP24_STARTMARKER_], ax
mov       word ptr ds:[SELFMODIFY_add_to_pixlow_hi_2+3 - OFFSET R_BSP24_STARTMARKER_], ax
xchg      ax, dx
mov       word ptr ds:[SELFMODIFY_add_to_pixlow_lo_1+3 - OFFSET R_BSP24_STARTMARKER_], ax
mov       word ptr ds:[SELFMODIFY_add_to_pixlow_lo_2+3 - OFFSET R_BSP24_STARTMARKER_], ax


SELFMODIFY_do_backsector_work_or_not_TARGET_NULL:
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
mov   word ptr ds:[SELFMODIFY_add_rw_x_base4_to_ax+1 - OFFSET R_BSP24_STARTMARKER_], bx
mov   word ptr ds:[SELFMODIFY_compare_ax_to_start_rw_x+1 - OFFSET R_BSP24_STARTMARKER_], di

; self modify code in the function to set constants rather than
; repeatedly reading loop-constant or function-constant variables.

mov   byte ptr ds:[SELFMODIFY_set_al_to_xoffset+1 - OFFSET R_BSP24_STARTMARKER_], 0



mov   ax, word ptr [bp - 01Ah]
mov   word ptr ds:[SELFMODIFY_cmp_di_to_rw_stopx_1+1 - OFFSET R_BSP24_STARTMARKER_], ax
mov   word ptr ds:[SELFMODIFY_cmp_di_to_rw_stopx_2+1 - OFFSET R_BSP24_STARTMARKER_], ax
mov   word ptr ds:[SELFMODIFY_cmp_di_to_rw_stopx_3+1 - OFFSET R_BSP24_STARTMARKER_], ax


cmp   byte ptr [bp - 01Ch], 0 ;markfloor

je    do_markfloor_selfmodify_jumps
mov   ax, 04940h     ; inc ax dec cx
mov   si, 02647h     ; inc di, es:
jmp do_markfloor_selfmodify
do_markfloor_selfmodify_jumps:
mov   ax, ((SELFMODIFY_BSP_markfloor_1_TARGET - SELFMODIFY_BSP_markfloor_1_AFTER) SHL 8) + 0EBh
mov   si, ((SELFMODIFY_BSP_markfloor_2_TARGET - SELFMODIFY_BSP_markfloor_2_AFTER) SHL 8) + 0EBh
do_markfloor_selfmodify:

mov   word ptr ds:[SELFMODIFY_BSP_markfloor_1 - OFFSET R_BSP24_STARTMARKER_], ax
mov   word ptr ds:[SELFMODIFY_BSP_markfloor_2 - OFFSET R_BSP24_STARTMARKER_], si

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

mov   word ptr ds:[SELFMODIFY_BSP_markceiling_1 - OFFSET R_BSP24_STARTMARKER_], ax
mov   word ptr ds:[SELFMODIFY_BSP_markceiling_2 - OFFSET R_BSP24_STARTMARKER_], si

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
mov   word ptr ds:[SELFMODIFY_set_rw_scale_lo+1 - OFFSET R_BSP24_STARTMARKER_], ax
lods  word ptr ss:[si]
mov   word ptr ds:[SELFMODIFY_set_rw_scale_hi+1 - OFFSET R_BSP24_STARTMARKER_], ax
lods  word ptr ss:[si] ; topfrac lo
mov   word ptr ds:[SELFMODIFY_set_topfrac_lo+1 - OFFSET R_BSP24_STARTMARKER_], ax
lods  word ptr ss:[si] ; topfrac hi
mov   word ptr ds:[SELFMODIFY_set_topfrac_hi+1 - OFFSET R_BSP24_STARTMARKER_], ax
lods  word ptr ss:[si] ; bottomfrac lo
mov   word ptr ds:[SELFMODIFY_set_botfrac_lo+1 - OFFSET R_BSP24_STARTMARKER_], ax
lods  word ptr ss:[si] ; bottomfrac hi
mov   word ptr ds:[SELFMODIFY_set_botfrac_hi+1 - OFFSET R_BSP24_STARTMARKER_], ax
SELFMODIFY_BSP_midtextureonly_skip_pixhighlow_3:
jmp SELFMODIFY_BSP_midtextureonly_skip_pixhighlow_3_TARGET
SELFMODIFY_BSP_midtextureonly_skip_pixhighlow_3_AFTER = SELFMODIFY_BSP_midtextureonly_skip_pixhighlow_3 + 2
lods  word ptr ss:[si] ; pixlow lo
mov   word ptr ds:[SELFMODIFY_set_pixlow_lo+1 - OFFSET R_BSP24_STARTMARKER_], ax
lods  word ptr ss:[si] ; pixlow hi
mov   word ptr ds:[SELFMODIFY_set_pixlow_hi+1 - OFFSET R_BSP24_STARTMARKER_], ax
lods  word ptr ss:[si] ; pixhigh lo
mov   word ptr ds:[SELFMODIFY_set_pixhigh_lo+1 - OFFSET R_BSP24_STARTMARKER_], ax
lods  word ptr ss:[si] ; pixhigh hi
mov   word ptr ds:[SELFMODIFY_set_pixhigh_hi+1 - OFFSET R_BSP24_STARTMARKER_], ax

SELFMODIFY_BSP_midtextureonly_skip_pixhighlow_3_TARGET:
mov   al, 0 ; xoffset is 0
mov   dx, SC_DATA  ; cheat this out of the loop..


continue_outer_rendersegloop:

SELFMODIFY_BSP_midtextureonly_skip_pixhighlow_2_TARGET:
cbw  
xchg  ax, bx	; xoffset to bx

inc   byte ptr ds:[SELFMODIFY_set_al_to_xoffset+1 - OFFSET R_BSP24_STARTMARKER_]

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
add   word ptr ds:[SELFMODIFY_set_topfrac_lo+1 - OFFSET R_BSP24_STARTMARKER_], 01000h
SELFMODIFY_add_topstep_hi:
adc   word ptr ds:[SELFMODIFY_set_topfrac_hi+1 - OFFSET R_BSP24_STARTMARKER_], 01000h

SELFMODIFY_add_botstep_lo:
add   word ptr ds:[SELFMODIFY_set_botfrac_lo+1 - OFFSET R_BSP24_STARTMARKER_], 01000h
SELFMODIFY_add_botstep_hi:
adc   word ptr ds:[SELFMODIFY_set_botfrac_hi+1 - OFFSET R_BSP24_STARTMARKER_], 01000h

SELFMODIFY_add_rwscale_lo:
add   word ptr ds:[SELFMODIFY_set_rw_scale_lo+1 - OFFSET R_BSP24_STARTMARKER_], 01000h
SELFMODIFY_add_rwscale_hi:
adc   word ptr ds:[SELFMODIFY_set_rw_scale_hi+1 - OFFSET R_BSP24_STARTMARKER_], 01000h

SELFMODIFY_BSP_midtextureonly_skip_pixhighlow_2:
jmp SHORT   SELFMODIFY_BSP_midtextureonly_skip_pixhighlow_2_TARGET
SELFMODIFY_BSP_midtextureonly_skip_pixhighlow_2_AFTER = SELFMODIFY_BSP_midtextureonly_skip_pixhighlow_2 + 2

SELFMODIFY_add_pixlowstep_lo:
add   word ptr ds:[SELFMODIFY_set_pixlow_lo+1 - OFFSET R_BSP24_STARTMARKER_], 01000h
SELFMODIFY_add_pixlowstep_hi:
adc   word ptr ds:[SELFMODIFY_set_pixlow_hi+1 - OFFSET R_BSP24_STARTMARKER_], 01000h

SELFMODIFY_add_pixhighstep_lo:
add   word ptr ds:[SELFMODIFY_set_pixhigh_lo+1 - OFFSET R_BSP24_STARTMARKER_], 01000h
SELFMODIFY_add_pixhighstep_hi:
adc   word ptr ds:[SELFMODIFY_set_pixhigh_hi+1 - OFFSET R_BSP24_STARTMARKER_], 01000h


jmp   continue_outer_rendersegloop


exit_rendersegloop:
; zero out local caches.

;ASSUME DS:DGROUP
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

; begin inlined FixedMul_

IF COMPISA GE COMPILE_386

  shl  ecx, 16
  mov  cx, bx
  xchg ax, dx
  shl  eax, 16
  xchg ax, dx
  imul  ecx
  shr  eax, 16

ELSE

 ; si not preserved
  MOV  SI, DX
  PUSH AX
  MUL  BX
  MOV  word ptr cs:[_selfmodify_restore_dx_10+1], DX
  MOV  AX, SI
  MUL  CX
  XCHG AX, SI
  CWD
  AND  DX, BX
  SUB  SI, DX
  MUL  BX
_selfmodify_restore_dx_10:
  ADD  AX, 01000h
  ADC  SI, DX
  XCHG AX, CX
  CWD
  POP  BX
  AND  DX, BX
  SUB  SI, DX
  MUL  BX
  ADD  AX, CX
  ADC  DX, SI



ENDIF



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
mov   byte ptr cs:[SELFMODIFY_COLFUNC_set_colormap_index_jump - OFFSET R_BSP24_STARTMARKER_], al


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
mov   word ptr cs:[SELFMODIFY_BSP_set_seglooptexrepeat0 - OFFSET R_BSP24_STARTMARKER_], ((SELFMODIFY_BSP_set_seglooptexrepeat0_TARGET - SELFMODIFY_BSP_set_seglooptexrepeat0_AFTER) SHL 8) + 0EBh
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
mov   word ptr cs:[SELFMODIFY_add_cached_segment0+1 - OFFSET R_BSP24_STARTMARKER_], dx

         COMMENT @ REDO THIS AREA IF WE RE-ADD NON PO2 TEXTURES
         ; see above, but all textures in vanilla are po2 so this is not necessary for now.
         mov   dh, byte ptr ds:[_seglooptexmodulo]
         mov   byte ptr cs:[SELFMODIFY_BSP_set_seglooptexmodulo0+1 - OFFSET R_BSP24_STARTMARKER_], dh

         cmp   dh, 0
         je    seglooptexmodulo0_is_jmp

         mov   dl, 0B2h   ;  (mov dl, xx)
         mov   word ptr cs:[SELFMODIFY_BSP_check_seglooptexmodulo0 - OFFSET R_BSP24_STARTMARKER_], dx
         jmp   check_seglooptexrepeat0
         seglooptexmodulo0_is_jmp:
         mov   word ptr cs:[SELFMODIFY_BSP_check_seglooptexmodulo0 - OFFSET R_BSP24_STARTMARKER_], ((SELFMODIFY_BSP_check_seglooptexmodulo0_TARGET - SELFMODIFY_BSP_check_seglooptexmodulo0_AFTER) SHL 8) + 0EBh
         check_seglooptexrepeat0:
         @

; todohigh get this dh and dl in same read?
mov   dh, byte ptr ds:[_seglooptexrepeat]
cmp   dh, 0
je    seglooptexrepeat0_is_jmp
; modulo is seglooptexrepeat - 1
mov   dl, byte ptr ds:[_segloopheightvalcache]
mov   byte ptr cs:[SELFMODIFY_BSP_check_seglooptexmodulo0 - OFFSET R_BSP24_STARTMARKER_],   0B8h   ; mov ax, xxxx
mov   word ptr cs:[SELFMODIFY_BSP_check_seglooptexmodulo0+1 - OFFSET R_BSP24_STARTMARKER_], dx

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
mov   word ptr cs:[SELFMODIFY_BSP_set_dc_iscale_lo+1 - OFFSET R_BSP24_STARTMARKER_], ax
mov   word ptr cs:[SELFMODIFY_BSP_set_dc_iscale_hi+1 - OFFSET R_BSP24_STARTMARKER_], dx  


; store dc_x directly in code
mov   word ptr cs:[SELFMODIFY_COLFUNC_get_dc_x+1 - OFFSET R_BSP24_STARTMARKER_], di

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
mov   word ptr ds:[(SELFMODIFY_COLFUNC_JUMP_OFFSET24_OFFSET+1)], ax  ; overwrite the jump relative call for however many iterations in unrolled loop we need


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

db 02Eh  ; cs segment override
db 0FFh  ; lcall[addr]
db 01Eh  ;
SELFMODIFY_COLFUNC_set_colormap_index_jump:
dw 0000h
; addr 0000 + first byte (4x colormap.)



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
mov   byte ptr cs:[SELFMODIFY_BSP_R_DrawColumnPrep_ret - OFFSET R_BSP24_STARTMARKER_], 0C3h  ; ret
call  R_DrawColumnPrep_

pop bp
mov   byte ptr cs:[SELFMODIFY_BSP_R_DrawColumnPrep_ret - OFFSET R_BSP24_STARTMARKER_], 05Dh  ; pop bp

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
mov   word ptr cs:[SELFMODIFY_add_cached_segment1+1 - OFFSET R_BSP24_STARTMARKER_], dx




         COMMENT @ REDO THIS AREA IF WE RE-ADD NON PO2 TEXTURES
         mov   dh, byte ptr ds:[1 + _seglooptexmodulo]
         mov   byte ptr cs:[SELFMODIFY_BSP_set_seglooptexmodulo1+1 - OFFSET R_BSP24_STARTMARKER_], dh

         cmp   dh, 0
         je    seglooptexmodulo1_is_jmp

         mov   dl, 0B2h   ;  (mov dl, xx)
         mov   word ptr cs:[SELFMODIFY_BSP_check_seglooptexmodulo1 - OFFSET R_BSP24_STARTMARKER_], dx
         jmp   check_seglooptexrepeat1
         seglooptexmodulo1_is_jmp:
         mov   word ptr cs:[SELFMODIFY_BSP_check_seglooptexmodulo1 - OFFSET R_BSP24_STARTMARKER_], ((SELFMODIFY_BSP_check_seglooptexmodulo1_TARGET - SELFMODIFY_BSP_check_seglooptexmodulo1_AFTER) SHL 8) + 0EBh
         check_seglooptexrepeat1:
         @


; todo get this dh and dl in same read
mov   dh, byte ptr ds:[1 + _seglooptexrepeat]
cmp   dh, 0
je    seglooptexrepeat1_is_jmp
; modulo is seglooptexrepeat - 1
mov   dl, byte ptr ds:[1 + _segloopheightvalcache]
mov   byte ptr cs:[SELFMODIFY_BSP_check_seglooptexmodulo1 - OFFSET R_BSP24_STARTMARKER_],   0B8h   ; mov ax, xxxx
mov   word ptr cs:[SELFMODIFY_BSP_check_seglooptexmodulo1+1 - OFFSET R_BSP24_STARTMARKER_], dx

jmp   just_do_draw1
; do jmp. highest priority, overwrite previously written thing.
seglooptexrepeat1_is_jmp:
mov   word ptr cs:[SELFMODIFY_BSP_set_seglooptexrepeat1 - OFFSET R_BSP24_STARTMARKER_], ((SELFMODIFY_BSP_set_seglooptexrepeat1_TARGET - SELFMODIFY_BSP_set_seglooptexrepeat1_AFTER) SHL 8) + 0EBh
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
mov   word ptr cs:[SELFMODIFY_BSP_set_seglooptexrepeat0 - OFFSET R_BSP24_STARTMARKER_], ((SELFMODIFY_BSP_set_seglooptexrepeat0_TARGET - SELFMODIFY_BSP_set_seglooptexrepeat0_AFTER) SHL 8) + 0EBh
mov   word ptr cs:[SELFMODIFY_BSP_set_seglooptexrepeat1 - OFFSET R_BSP24_STARTMARKER_], ((SELFMODIFY_BSP_set_seglooptexrepeat1_TARGET - SELFMODIFY_BSP_set_seglooptexrepeat1_AFTER) SHL 8) + 0EBh


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
add       word ptr ds:[_ds_p], (SIZE DRAWSEG_T)
LEAVE_MACRO
pop       di
pop       si
pop       cx
pop       bx
ret       

handle_two_sided_line:
SELFMODIFY_jmp_two_sided_or_not_TARGET:
; jumped to with ds as cs


; nop 

SELFMODIFY_BSP_drawtype_2:
SELFMODIFY_BSP_drawtype_2_AFTER = SELFMODIFY_BSP_drawtype_2+2

mov       ax, 0c089h 

ASSUME DS:R_BSP_24_TEXT
mov       word ptr ds:[SELFMODIFY_BSP_midtextureonly_skip_pixhighlow_1 - OFFSET R_BSP24_STARTMARKER_], ax
mov       word ptr ds:[SELFMODIFY_BSP_midtextureonly_skip_pixhighlow_2 - OFFSET R_BSP24_STARTMARKER_], ax
mov       word ptr ds:[SELFMODIFY_BSP_midtextureonly_skip_pixhighlow_3 - OFFSET R_BSP24_STARTMARKER_], ax
;mov       word ptr ds:[SELFMODIFY_BSP_midtextureonly_skip_pixhighlow_4 - OFFSET R_BSP24_STARTMARKER_], ax
mov       word ptr ds:[SELFMODIFY_BSP_midtextureonly_skip_pixhighlow_5 - OFFSET R_BSP24_STARTMARKER_], ax


mov       word ptr ds:[SELFMODIFY_BSP_drawtype_1 - OFFSET R_BSP24_STARTMARKER_], 0EBB8h   ; mov ax, xxeB
mov       word ptr ds:[SELFMODIFY_BSP_drawtype_2 - OFFSET R_BSP24_STARTMARKER_], ((SELFMODIFY_BSP_drawtype_2_TARGET - SELFMODIFY_BSP_drawtype_2_AFTER) SHL 8) + 0EBh

mov       word ptr ds:[SELFMODIFY_BSP_midtexture - OFFSET R_BSP24_STARTMARKER_], 0E9h
mov       word ptr ds:[SELFMODIFY_BSP_midtexture+1 - OFFSET R_BSP24_STARTMARKER_], (SELFMODIFY_BSP_midtexture_TARGET - SELFMODIFY_BSP_midtexture_AFTER) 

mov       byte ptr ds:[SELFMODIFY_BSP_midtexture_return_jmp+0 - OFFSET R_BSP24_STARTMARKER_], 0E9h ; jmp short rel16
mov       word ptr ds:[SELFMODIFY_BSP_midtexture_return_jmp+1 - OFFSET R_BSP24_STARTMARKER_], SELFMODIFY_BSP_midtexture_return_jmp_TARGET - SELFMODIFY_BSP_midtexture_return_jmp_AFTER



SELFMODIFY_BSP_drawtype_2_TARGET:
; nomidtexture. this will be checked before top/bot, have to set it to 0.


mov       si, ss   ; restore DS
mov       ds, si
;ASSUME DS:DGROUP


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

SELFMODIFY_settoptexturetranslation_lookup:
mov       ax, 01000h

; write the high byte of the word.
; prev two bytes will be a jump or mov cx with the low byte
; todo midtexture some stuff set here

mov       word ptr cs:[SELFMODIFY_BSP_set_toptexture+1 - OFFSET R_BSP24_STARTMARKER_], ax
mov       bx, ax     ; backup
test      ax, ax
jne       toptexture_not_zero
toptexture_zero:
mov       word ptr cs:[SELFMODIFY_BSP_toptexture - OFFSET R_BSP24_STARTMARKER_], ((SELFMODIFY_BSP_toptexture_TARGET - SELFMODIFY_BSP_toptexture_AFTER) SHL 8) + 0EBh
jmp       toptexture_stuff_done
set_toptexture_to_worldtop:
les       ax, dword ptr [bp - 040h]
mov       dx, es
jmp       do_selfmodify_toptexture

toptexture_not_zero:
mov       word ptr cs:[SELFMODIFY_BSP_toptexture - OFFSET R_BSP24_STARTMARKER_], 0468Bh ; mov   ax, word ptr [bp - 02Dh] first two bytes
; are any bits set?
or        bl, bh
or        byte ptr cs:[SELFMODIFY_check_for_any_tex+1 - OFFSET R_BSP24_STARTMARKER_], bl


test      byte ptr [bp + 018h], ML_DONTPEGTOP
jne       set_toptexture_to_worldtop
calculate_toptexturemid:
; SET_FIXED_UNION_FROM_SHORT_HEIGHT(rw_toptexturemid, backsectorceilingheight);
; rw_toptexturemid.h.intbits += textureheights[side->toptexture] + 1;
; // bottom of texture
; rw_toptexturemid.w -= viewz.w;

; dx holding on to backsectorceilingheight from above.

;todo 386
xor       ax, ax
sar       dx, 1
rcr       ax, 1
sar       dx, 1
rcr       ax, 1
sar       dx, 1
rcr       ax, 1
;dx:ax are toptexturemid for now..

; add textureheight+1

SELFMODIFY_add_texturetopheight_plus_one:
add       dx, 01000h

SELFMODIFY_BSP_viewz_lo_1:
sub       ax, 01000h
SELFMODIFY_BSP_viewz_hi_1:
sbb       dx, 01000h


do_selfmodify_toptexture:
; set _rw_toptexturemid in rendersegloop

mov   word ptr cs:[SELFMODIFY_set_toptexturemid_lo+1 - OFFSET R_BSP24_STARTMARKER_], ax
mov   word ptr cs:[SELFMODIFY_set_toptexturemid_hi+1 - OFFSET R_BSP24_STARTMARKER_], dx


toptexture_stuff_done:



cmp       di, word ptr [bp - 042h]
jg        setup_bottexture
jne       bottexture_zero
cmp       si, word ptr [bp - 044h]
jbe       bottexture_zero
setup_bottexture:
SELFMODIFY_setbottexturetranslation_lookup:
mov       ax, 01000h

; write the high byte of the word.
; prev two bytes will be a jump or mov cx with the low byte
mov       word ptr cs:[SELFMODIFY_BSP_set_bottomtexture+1 - OFFSET R_BSP24_STARTMARKER_], ax
mov       bx, ax     ; backup
test      ax, ax

jne       bottexture_not_zero

bottexture_zero:
mov       word ptr cs:[SELFMODIFY_BSP_bottexture - OFFSET R_BSP24_STARTMARKER_], ((SELFMODIFY_BSP_bottexture_TARGET - SELFMODIFY_BSP_bottexture_AFTER) SHL 8) + 0EBh
jmp       bottexture_stuff_done
bottexture_not_zero:
mov       word ptr cs:[SELFMODIFY_BSP_bottexture - OFFSET R_BSP24_STARTMARKER_], 0468Bh   ; mov   ax, word ptr [bp - 02Dh] first two bytes
; are any bits set?
or        bl, bh
or        byte ptr cs:[SELFMODIFY_check_for_any_tex+1 - OFFSET R_BSP24_STARTMARKER_], bl



test      byte ptr [bp + 018h], ML_DONTPEGBOTTOM
je        calculate_bottexturemid
; todo cs write here
les       ax, dword ptr [bp - 040h]
mov       dx, es
do_selfmodify_bottexture:

; set _rw_toptexturemid in rendersegloop

mov   word ptr cs:[SELFMODIFY_set_bottexturemid_lo+1 - OFFSET R_BSP24_STARTMARKER_], ax
mov   word ptr cs:[SELFMODIFY_set_bottexturemid_hi+1 - OFFSET R_BSP24_STARTMARKER_], dx


bottexture_stuff_done:
SELFMODIFY_BSP_siderenderrowoffset_2:
mov       ax, 01000h

;  extra selfmodify? or hold in vars till this pt and finally write the high bits
; 	rw_toptexturemid.h.intbits += side_render->rowoffset;
;	rw_bottomtexturemid.h.intbits += side_render->rowoffset;


add       word ptr cs:[SELFMODIFY_set_toptexturemid_hi+1 - OFFSET R_BSP24_STARTMARKER_], ax
add       word ptr cs:[SELFMODIFY_set_bottexturemid_hi+1 - OFFSET R_BSP24_STARTMARKER_], ax


; // allocate space for masked texture tables
; if (side->midtexture) {


; check midtexture on 2 sided line (e1m1 case)
SELFMODIFY_has_midtexture_or_not:
jne       side_has_midtexture   ; become xor ax, ax if nomidtex ,or jmp.
SELFMODIFY_has_midtexture_or_not_AFTER:
jmp       done_with_sector_sided_check
SELFMODIFY_has_midtexture_or_not_TARGET:
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





SEG_LINEDEFS_OFFSET_IN_LINEFLAGSLIST =  ((SEG_LINEDEFS_SEGMENT - LINEFLAGSLIST_SEGMENT) SHL 4)

SEG_SIDES_OFFSET_IN_LINEFLAGSLIST    = ((SEG_SIDES_SEGMENT - LINEFLAGSLIST_SEGMENT) SHL 4)


;R_AddLine_

PROC   R_AddLine_ NEAR
PUBLIC R_AddLine_ 

; ax = curlineNum

; bp - 2       lineflags       ; bp + 018h in R_StoreWallRange
; bp - 4       curlineside     ; bp + 016h in R_StoreWallRange
; bp - 6       curseglinedef   ; bp + 014h in R_StoreWallRange
; bp - 8       curlinesidedef  ; shifted pointer to side
; bp - 0Ah     curseg_render   ; bp + 010h in R_StoreWallRange
; bp - 0Ch     _rw_scale hi    ; bp + 0Eh in R_StoreWallRange
; bp - 0Eh     _rw_scale lo    ; bp + 0Ch in R_StoreWallRange


;todo reorder stack? pushes and LES synergy?
push  ax     ; bp + 4  ; bp + 01Eh in R_StoreWallRange
push  cx     ; bp + 2  ; bp + 01Ch in R_StoreWallRange
push  bp     ; bp + 0  ; bp + 01Ah in R_StoreWallRange
mov   bp, sp

mov   cx, ds
mov   dx, LINEFLAGSLIST_SEGMENT
mov   ds, dx
cwd   ; never will have 32k lines... clear dh
xchg  ax, bx
mov   dl, byte ptr ds:[bx + SEG_SIDES_OFFSET_IN_LINEFLAGSLIST]
shl   bx, 1
mov   di, word ptr ds:[bx + SEG_LINEDEFS_OFFSET_IN_LINEFLAGSLIST] 
push  word ptr ds:[di]             ; bp - 2  ; lineflags
push  dx                           ; bp - 4  ; line pointer
push  di                           ; bp - 6  ; seg_sides
SHIFT_MACRO shl bx 2
add   bh, (_segs_render SHR 8)
mov   ds, cx
push  word ptr ds:[bx + SEG_RENDER_T.sr_sidedefOffset]  ; bp - 8  ; SIDE_T index. used once. 
push  bx   ; bp - 0Ah

; todo move way later?
les   si, dword ptr ds:[bx]       ;sr_v1Offset
mov   di, es                      ;sr_v2Offset
mov   ax, VERTEXES_SEGMENT
mov   ds, ax
SHIFT_MACRO shl si 2
SHIFT_MACRO shl di 2
les   dx, dword ptr ds:[si]
mov   ax, es


les   si, dword ptr ds:[di]       ; v2.x
mov   di, es                      ; v2.y
mov   ds, cx
xchg  ax, cx



call  R_PointToAngle16_    ; todo debug why this doesnt work with the other one. stack corruption?

xchg  ax, di
xchg  ax, cx
xchg  si, dx      ; SI: BX stores angle1


call  R_PointToAngle16_    ; todo debug why this doesnt work with the other one. stack corruption?

; backup before sub
mov   bx, di
sub   di, ax
mov   cx, si
sbb   cx, dx
jns   dont_backface_cull
exit_addline:   ; todo branch measure

LEAVE_MACRO 
pop   cx
pop   ax
ret   
dont_backface_cull:
; cx:ax is span
; dx:di is angle2
; sx:bi is angle1


xchg  ax, di  ; todo eliminate this juggle? 
mov   es, ax

; store rw_angle1 on stack
push  si ; bp - 0Ch
push  bx ; bp - 0Eh

; si:bx is rw_angle1

SELFMODIFY_BSP_viewangle_lo_1:
sub   bx, 01000h

SELFMODIFY_BSP_viewangle_hi_1:
sbb   si, 01000h


SELFMODIFY_BSP_clipangle_4:
lea   ax, [si + 01000h]
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
mov   ax, es
cmp   bx, ax      ; last use of angle1 lobits
jae   exit_addline
not_off_left_side:
SELFMODIFY_BSP_clipangle_1:
mov   si, 01000h

done_checking_left:

mov   bx, si  ; todo eliminate the juggle. angle1 currently bx:00 instead of si:bx

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
cmp   si, word ptr [bp - 0Ch]
jae   exit_addline
not_off_left_side_2:
SELFMODIFY_BSP_clipangle_3:
mov   dx, 01000h
neg   dx
done_checking_right:

; seg in view angle but not necessarily visible
add   bh, (ANG90_HIGHBITS SHR 8)

SHIFT_MACRO shr bx 2

and   bl, 0FEh  ; low bit removal
add   dh, (ANG90_HIGHBITS SHR 8)
mov   ax, word ptr ds:[bx + _viewangletox]
mov   bx, dx
SHIFT_MACRO shr bx 2


and   bl, 0FEh  ; low bit removal
mov   dx, word ptr ds:[bx + _viewangletox]
cmp   ax, dx
je    exit_addline
;	if (!(lineflagslist[curseglinedef] & ML_TWOSIDED)) {
dec   dx       ; x2 -1 for calls later.

test  byte ptr [bp - 2], ML_TWOSIDED
je    clip_solid_with_null_backsec
not_single_sided_line:
mov   bx, word ptr [bp - 4]
xor   bl, 1
sal   bx, 1
mov   es, word ptr ds:[_LINES_SEGMENT_PTR]
mov   si, word ptr [bp - 6]
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
cmp   ax, word ptr es:[di + SECTOR_T.sec_ceilingheight]  ; frontsector ceiling
jge   clipsolid_ax_swap
xchg  ax, cx                  ; cx has old si+0 (backsector floor)
lods  word ptr es:[si]        ; backsector  ceiling
cmp   ax, word ptr es:[di + SECTOR_T.sec_floorheight]    ; frontsector floor
jle   clipsolid_ax_swap

;    // Window.
;    if (backsector->ceilingheight != frontsector->ceilingheight
;	|| backsector->floorheight != frontsector->floorheight)

cmp   ax, word ptr es:[di + SECTOR_T.sec_ceilingheight]      ; backsector ceiling vs frontsector ceiling
jne   clippass
cmp   cx, word ptr es:[di + SECTOR_T.sec_floorheight]          ; backsector floor vs frontsector floor
jne   clippass

; if (backsector->ceilingpic == frontsector->ceilingpic
;		&& backsector->floorpic == frontsector->floorpic
;		&& backsector->lightlevel == frontsector->lightlevel
;		&& curlinesidedef->midtexture == 0) {
;		return;
;    }

lods  word ptr es:[si]           ; al floorpic   ah ceilingpic
cmp   ax, word ptr es:[di + SECTOR_T.sec_floorpic]
jne   clippass

mov   al, byte ptr es:[si + (SECTOR_T.sec_lightlevel - SECTOR_T.sec_validcount)] ; 0E is lightlevels. currently offset by 6..
cmp   al, byte ptr es:[di + SECTOR_T.sec_lightlevel]
jne   clippass

;    fall thru and return if midtexture doesnt match.
mov   es, word ptr ds:[_SIDES_SEGMENT_PTR]
mov   si, word ptr [bp - 8]    ; presumably curlinesidedef.
SHIFT_MACRO shl si 3
cmp   word ptr es:[si + SIDE_T.s_midtexture], 0  ; todo investigate branch rate
je    exit_addline_2

clippass:
xchg  ax, bx                   ; grab cached x1
jmp   R_ClipPassWallSegment_
exit_addline_2:
LEAVE_MACRO 
pop   cx
pop   ax
ret   

clip_solid_with_null_backsec:
xchg  ax, bx                   ; dont grab uncached x1 - reverse
mov   word ptr ds:[_backsector], SECNUM_NULL   ; does this ever get properly used or checked? can we just ignore?


clipsolid_ax_swap:
xchg  ax, bx                   ; grab cached x1

; single code path so we have a single return path to clear selfmodified line fields

; fall thru
;jmp   R_ClipSolidWallSegment_

ENDP


;R_ClipSolidWallSegment_

PROC R_ClipSolidWallSegment_ NEAR



mov   cx, ax                  ; backup first in cx for most of the function.
mov   di, dx
dec   ax
mov   si, OFFSET _solidsegs
cmp   ax, word ptr ds:[si + CLIPRANGE_T.cliprange_last]
 
;  while (start->last < first-1)
;  	start++;

jle   found_start_solid
increment_start:
add   si, SIZE CLIPRANGE_T
cmp   ax, word ptr ds:[si + CLIPRANGE_T.cliprange_last]
jg    increment_start
found_start_solid:
mov   ax, cx
cmp   ax, word ptr ds:[si + CLIPRANGE_T.cliprange_first]

;    if (first < start->first)

jge   first_greater_than_startfirst ;		if (last < start->first-1) {
mov   dx, word ptr ds:[si + CLIPRANGE_T.cliprange_first]
dec   dx
cmp   di, dx
jl    last_smaller_than_startfirst;
call  R_StoreWallRange_             ;		R_StoreWallRange (first, start->first - 1);
mov   ax, cx                        ;		start->first = first;	
mov   word ptr ds:[si + CLIPRANGE_T.cliprange_first], ax
first_greater_than_startfirst:
;	if (last <= start->last) {

cmp   di, word ptr ds:[si  + CLIPRANGE_T.cliprange_last]
jle   write_back_newend_and_return
;    next = start;
mov   bx, si                        ; si is start, bx is next
;    while (last >= (next+1)->first-1) {
check_between_posts:
mov   dx, word ptr ds:[bx + SIZE CLIPRANGE_T +  + CLIPRANGE_T.cliprange_first]
dec   dx
cmp   di, dx
jl    do_final_fragment
mov   ax, word ptr ds:[bx +  + CLIPRANGE_T.cliprange_last]
inc   ax
;		// There is a fragment between two posts.
;		R_StoreWallRange (next->last + 1, (next+1)->first - 1);
call  R_StoreWallRange_
mov   ax, word ptr ds:[bx + SIZE CLIPRANGE_T + CLIPRANGE_T.cliprange_last]
add   bx, 4
cmp   di, ax
jg    check_between_posts
mov   word ptr ds:[si + CLIPRANGE_T.cliprange_last], ax
crunch:
;    if (next == start) {
cmp   bx, si
je    write_back_newend_and_return
;    while (next++ != newend) {

mov   cx, word ptr ds:[_newend] ; cache old newend

check_to_remove_posts:
mov   ax, bx
lea   di, [si + SIZE CLIPRANGE_T]
add   bx, SIZE CLIPRANGE_T
cmp   ax, cx
je    done_removing_posts
les   ax, dword ptr ds:[bx]
mov   dx, es
mov   word ptr ds:[di + CLIPRANGE_T.cliprange_first], ax
mov   si, di
mov   word ptr ds:[di + CLIPRANGE_T.cliprange_last], dx
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
lea   si, [di - SIZE CLIPRANGE_T]   ; set source
sar   cx, 1          ; set count in words
rep   movsw
cld

; ax = dest, dx = source, bx = count?

mov   word ptr ds:[bx + CLIPRANGE_T.cliprange_last], dx
mov   word ptr ds:[bx + CLIPRANGE_T.cliprange_first], ax
write_back_newend_and_return:

mov   byte ptr cs:[SELFMODIFY_skip_curseg_based_selfmodify], 0BBh ; mov bx, imm16 (fallthru)
LEAVE_MACRO
pop   cx
pop   ax

ret   

do_final_fragment:
;    // There is a fragment after *next.
mov   ax, word ptr ds:[bx + CLIPRANGE_T.cliprange_last]
mov   dx, di
inc   ax
call  R_StoreWallRange_
mov   word ptr ds:[si + CLIPRANGE_T.cliprange_last], di
jmp   crunch

done_removing_posts:
    
mov   word ptr ds:[_newend], di   ; newend = start+1;

mov   byte ptr cs:[SELFMODIFY_skip_curseg_based_selfmodify], 0BBh ; mov bx, imm16 (fallthru)
LEAVE_MACRO
pop   cx
pop   ax

ret   

ENDP

;R_ClipPassWallSegment_

PROC R_ClipPassWallSegment_ NEAR

; input: ax = first (transferred to si)
;        dx = last (transferred to cx)

mov  si, ax
mov  cx, dx
dec  ax
;    start = solidsegs;
 
mov  bx, OFFSET _solidsegs
cmp  ax, word ptr ds:[bx + CLIPRANGE_T.cliprange_last]


jle  found_start
; todo: try unrolling as optimization?
keep_searching_for_start:
add  bx, SIZE CLIPRANGE_T
cmp  ax, word ptr ds:[bx + CLIPRANGE_T.cliprange_last]
jg   keep_searching_for_start

found_start:
;    if (first < start->first) {

mov  ax, word ptr ds:[bx + CLIPRANGE_T.cliprange_first]  ; ax = start->first
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


cmp  cx, word ptr ds:[bx + CLIPRANGE_T.cliprange_last]
jle  do_clippass_exit
check_next_fragment:
mov  dx, word ptr ds:[bx + SIZE CLIPRANGE_T + CLIPRANGE_T.cliprange_first]
dec  dx
cmp  cx, dx
mov  ax, word ptr ds:[bx + CLIPRANGE_T.cliprange_last]
jl   fragment_after_next
inc  ax
add  bx, SIZE CLIPRANGE_T
;  There is a fragment between two posts.

call R_StoreWallRange_
cmp  cx, word ptr ds:[bx + CLIPRANGE_T.cliprange_last]
jg   check_next_fragment
do_clippass_exit:
mov   byte ptr cs:[SELFMODIFY_skip_curseg_based_selfmodify], 0BBh ; mov bx, imm16 (fallthru)
LEAVE_MACRO
pop   cx
pop   ax
ret  
post_entirely_visible:
mov  dx, cx
mov  ax, si
call R_StoreWallRange_
mov   byte ptr cs:[SELFMODIFY_skip_curseg_based_selfmodify], 0BBh ; mov bx, imm16 (fallthru)
LEAVE_MACRO
pop   cx
pop   ax
ret  

fragment_after_next:

mov  dx, cx
inc  ax
call R_StoreWallRange_
mov   byte ptr cs:[SELFMODIFY_skip_curseg_based_selfmodify], 0BBh ; mov bx, imm16 (fallthru)
LEAVE_MACRO
pop   cx
pop   ax
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
call      R_GetCompositeTexture_

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
call      R_GetPatchTexture_

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
imul  bx, cx, (SIZE SPRITEFRAME_T)
mov   di, word ptr es:[di]       ; get spriteframesOffset from spritedef_t
push  word ptr es:[bx + di + 010h]    ; 0Ah
mov   bx, word ptr es:[di + bx]       ; get spriteindex

ELSE
mov   al, (SIZE SPRITEFRAME_T)
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
;mov   al, byte ptr es:[bx] ; spriteoffsets[spriteindex]
;xor   ah, ah
xor   ax, ax
xlat  byte ptr es:[bx]

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

; TODO INLINE
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
xor   ax, ax
mov   al, byte ptr cs:[bx + (SPRITEWIDTHS_OFFSET)]

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

; TODO INLINE
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
mov   word ptr ds:[si + VISSPRITE_T.vs_texturemid + 2], ax
mov   ax, word ptr [bp - 0Eh]
mov   word ptr ds:[si + VISSPRITE_T.vs_texturemid + 0], bx
test  ax, ax

;    vis->x1 = x1 < 0 ? 0 : x1;
;    vis->x2 = x2 >= viewwidth ? viewwidth-1 : x2;       


jge   x1_positive_2
xor   ax, ax

x1_positive_2:
mov   word ptr ds:[si + VISSPRITE_T.vs_x1], ax

SELFMODIFY_BSP_viewwidth_4:
mov   ax, 01000h
cmp   dx, ax
jge   x2_smaller_than_viewwidth_2

mov   ax, dx
jmp   vis_x2_set

x2_smaller_than_viewwidth_2:
dec   ax
vis_x2_set:
mov   word ptr ds:[si + VISSPRITE_T.vs_x2], ax
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

mov   word ptr ds:[si + VISSPRITE_T.vs_scale + 0], ax
mov   word ptr ds:[si + VISSPRITE_T.vs_scale + 2], dx

SELFMODIFY_BSP_pspriteiscale_lo_1:
mov   bx, 01000h
SELFMODIFY_BSP_pspriteiscale_hi_1:
mov   cx, 01000h

cmp   byte ptr [bp - 0Ah], 0       ; check flip
jne   flip_on

flip_off:
xor   ax, ax
mov   word ptr ds:[si + VISSPRITE_T.vs_startfrac + 0], ax
mov   word ptr ds:[si + VISSPRITE_T.vs_startfrac + 2], ax
jmp   vis_startfrac_set

flip_on:

neg   cx
neg   bx
sbb   cx, 0


; mov ax, 0; add ax, -1; adc di, -1 optimized 

mov   ax, word ptr [bp - 010h]
dec   ax
mov   word ptr ds:[si + VISSPRITE_T.vs_startfrac + 0], -1
mov   word ptr ds:[si + VISSPRITE_T.vs_startfrac + 2], ax

vis_startfrac_set:
mov   word ptr ds:[si + VISSPRITE_T.vs_xiscale + 0], bx
mov   word ptr ds:[si + VISSPRITE_T.vs_xiscale + 2], cx

mov   ax, word ptr ds:[si + VISSPRITE_T.vs_x1]
cmp   ax, word ptr [bp - 0Eh]
jle   vis_x1_greater_than_x1_2
sub   ax, word ptr [bp - 0Eh]
; TODO INLINE
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

add   word ptr ds:[si + VISSPRITE_T.vs_startfrac + 0], ax
adc   word ptr ds:[si + VISSPRITE_T.vs_startfrac + 2], dx
vis_x1_greater_than_x1_2:
mov   bx, word ptr [bp - 0Ch]
mov   word ptr ds:[si + VISSPRITE_T.vs_patch], bx

;    if (player.powers[pw_invisibility] > 4*32

cmp   word ptr ds:[_player + PLAYER_T.player_powers + 2 * PW_INVISIBILITY], (4*32)
jg    mark_shadow_draw
test  byte ptr ds:[_player + PLAYER_T.player_powers + 2 * PW_INVISIBILITY], 8
jne   mark_shadow_draw

SELFMODIFY_BSP_fixedcolormap_4:
jmp   use_fixedcolormap
SELFMODIFY_BSP_fixedcolormap_4_AFTER:
test  byte ptr [bp - 2], FF_FULLBRIGHT
je    set_vis_colormap
SELFMODIFY_BSP_fixedcolormap_4_TARGET:
use_fixedcolormap:
SELFMODIFY_BSP_fixedcolormap_5:
mov   byte ptr ds:[si + VISSPRITE_T.vs_colormap], 00h

LEAVE_MACRO
ret   



mark_shadow_draw:
; do shadow draw
mov   byte ptr ds:[si + VISSPRITE_T.vs_colormap], COLORMAP_SHADOW
LEAVE_MACRO
ret   


set_vis_colormap:
SELFMODIFY_set_spritelights_2:
mov   bx, 01000h
mov   al, byte ptr ds:[bx + (MAXLIGHTSCALE-1) + _scalelight]  ;todo or is this supposed to be scalelightfixed...?
mov   byte ptr ds:[si + VISSPRITE_T.vs_colormap], al
LEAVE_MACRO
ret   


ENDP

;R_PrepareMaskedPSprites_

PROC R_PrepareMaskedPSprites_ NEAR

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
mov   word ptr cs:[SELFMODIFY_set_spritelights_2 + 1 - OFFSET R_BSP24_STARTMARKER_], ax 



first_iter:

mov   bx, word ptr ds:[_psprites]
cmp   bx, STATENUM_NULL
je    sprite_1_null
sal   bx, 1
mov   si, OFFSET _player_vissprites
mov   ax, word ptr ds:[bx + _states_render]
mov   cl, ah
mov   bx, OFFSET _psprites
call  R_DrawPSprite_
sprite_1_null:

second_iter:

mov   bx, word ptr ds:[_psprites + 0Ch]
cmp   bx, -1
je    sprite_2_null
sal   bx, 1
mov   si, OFFSET _player_vissprites + 028h
mov   ax, word ptr ds:[bx + _states_render]
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
mov   word ptr cs:[SELFMODIFY_set_spritelights_2 + 1 - OFFSET R_BSP24_STARTMARKER_], ax 
jmp   first_iter


ENDP

;R_PointToAngle16_


; params cx, dx. ax/bx get zeroed/clobbered.
PROC R_PointToAngle16_ NEAR


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
; jmp table for switch block.... 

dw R_CBB_SWITCH_CASE_00 - OFFSET R_BSP24_STARTMARKER_, R_CBB_SWITCH_CASE_01 - OFFSET R_BSP24_STARTMARKER_, R_CBB_SWITCH_CASE_02 - OFFSET R_BSP24_STARTMARKER_, R_CBB_SWITCH_CASE_03 - OFFSET R_BSP24_STARTMARKER_
dw R_CBB_SWITCH_CASE_04 - OFFSET R_BSP24_STARTMARKER_, R_CBB_SWITCH_CASE_05 - OFFSET R_BSP24_STARTMARKER_, R_CBB_SWITCH_CASE_06 - OFFSET R_BSP24_STARTMARKER_, R_CBB_SWITCH_CASE_07 - OFFSET R_BSP24_STARTMARKER_
dw R_CBB_SWITCH_CASE_08 - OFFSET R_BSP24_STARTMARKER_, R_CBB_SWITCH_CASE_09 - OFFSET R_BSP24_STARTMARKER_, R_CBB_SWITCH_CASE_10 - OFFSET R_BSP24_STARTMARKER_

;R_CheckBBox_


boxy_check_2nd_expression:
; ax still viewy highbits
SELFMODIFY_BSP_viewy_lo_4_TARGET_2:
je    set_boxy_1
SELFMODIFY_BSP_viewy_lo_4_TARGET_1:
set_boxy_2:
mov   al, 2
jmp   boxy_calculated

return_1_early:
stc
ret   

PROC R_CheckBBox_ NEAR




; ds:bx is bsp lookup


;	// Find the corners of the box
;	// that define the edges from current viewpoint.

SELFMODIFY_BSP_viewx_hi_4:
mov   ax, 01000h
cmp   ax, word ptr ds:[bx + 4]         ; bspcoord[BOXLEFT]

SELFMODIFY_BSP_viewx_lo_4:
jge   viewx_greater_than_left    ; 7d xx
SELFMODIFY_BSP_viewx_lo_4_AFTER:
set_boxx_0:
mov   dl, 0
check_boxy:

SELFMODIFY_BSP_viewy_hi_4:
mov   ax, 01000h
cmp   ax, word ptr ds:[bx]         ; bspcoord[BOXTOP]
jl    viewy_less_than_top
xor   ax, ax
boxy_calculated:
SHIFT_MACRO shl al 2
add   al, dl
cmp   al, 5
je    return_1_early
cbw
mov   di, ax
shl   di, 1
; switch block jump
jmp   word ptr cs:[di + R_CHECKBBOX_SWITCH_JMP_TABLE - OFFSET R_BSP24_STARTMARKER_]
SELFMODIFY_BSP_viewx_lo_4_TARGET_2:
; jmp here if viewx lobits are 0.
viewx_greater_than_left:
jne   boxx_check_2nd_expression
jmp   set_boxx_0
; jmp here if viewx lobits are nonzero.
SELFMODIFY_BSP_viewx_lo_4_TARGET_1:
boxx_check_2nd_expression:
; ax is already viewx hi
cmp   ax, word ptr ds:[bx + 6]         ; bspcoord[BOXRIGHT]
jge   set_boxx_2
set_boxx_1:
mov   dl, 1
jmp   check_boxy
set_boxx_2:
mov   dl, 2
jmp   check_boxy
viewy_less_than_top:
cmp   ax, word ptr ds:[bx + 2]         ; bspcoord[BOXBOTTOM]
SELFMODIFY_BSP_viewy_lo_4:
jle   boxy_check_2nd_expression
SELFMODIFY_BSP_viewy_lo_4_AFTER:
set_boxy_1:
mov   al, 1
jmp   boxy_calculated

R_CBB_SWITCH_CASE_01:
; di cx si dx
mov   di, word ptr ds:[bx]
mov   cx, di
les   si, dword ptr ds:[bx+4]
mov   dx, es
jmp   boxpos_switchblock_done
R_CBB_SWITCH_CASE_02:
; di cx si dx
les   di, dword ptr ds:[bx]
mov   cx, es
les   si, dword ptr ds:[bx+4]
mov   dx, es
jmp   boxpos_switchblock_done
R_CBB_SWITCH_CASE_03:
R_CBB_SWITCH_CASE_07:
; dicxsidx
mov   di, word ptr ds:[bx]
mov   cx, di
mov   si, di
mov   dx, di
jmp   boxpos_switchblock_done
R_CBB_SWITCH_CASE_04:
; sidx cx di
mov   si, word ptr ds:[bx + 4]
mov   dx, si
les   cx, dword ptr ds:[bx]
mov   di, es
jmp   boxpos_switchblock_done
R_CBB_SWITCH_CASE_06:
; sidx di cx
mov   si, word ptr ds:[bx+6]
mov   dx, si
les   di, dword ptr ds:[bx]
mov   cx, es
jmp   boxpos_switchblock_done
R_CBB_SWITCH_CASE_08:
; cx di dx si
les   cx, dword ptr ds:[bx]
mov   di, es
les   dx, dword ptr ds:[bx+4]
mov   si, es
jmp   boxpos_switchblock_done
R_CBB_SWITCH_CASE_09:
; dicx dx si
mov   di, word ptr ds:[bx+2]
mov   cx, di
les   dx, dword ptr ds:[bx+4]
mov   si, es
jmp   boxpos_switchblock_done
R_CBB_SWITCH_CASE_10:
; di cx dx si
les   di, dword ptr ds:[bx]
mov   cx, es
les   dx, dword ptr ds:[bx+4]
mov   si, es
jmp   boxpos_switchblock_done

R_CBB_SWITCH_CASE_00:
; cx di si dx
les   cx, dword ptr ds:[bx]
mov   di, es
les   si, dword ptr ds:[bx + 4]
mov   dx, es


R_CBB_SWITCH_CASE_05:  ; unused
boxpos_switchblock_done:
;	angle1.wu = R_PointToAngle16(x1, y1) - viewangle.wu;

push  ss
pop   ds

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

mov   word ptr cs:[SELFMODIFY_BSP_forward_angle2_lobits+1 - OFFSET R_BSP24_STARTMARKER_], ax



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
js     return_1

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
clc

ret   

return_1:
stc
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
mov   cx, 01000h   ; already negative froms elfmodify


done_with_second_tspan_adjustment:

lea   si, [di + ANG90_HIGHBITS]
add   ch, (ANG90_HIGHBITS SHR 8)
SHIFT_MACRO shr si 2
mov   bx, cx
SHIFT_MACRO shr bx 2
mov   ax, ss
mov   ds, ax
and   si, 0FFFEh  ; need to and out the last bit. (is there a faster way?)
and   bl, 0FEh    ; need to and out the last bit. (is there a faster way?)
mov   si, word ptr ds:[si + _viewangletox]
mov   ax, word ptr ds:[bx + _viewangletox]
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
jl    return_1
cmp   ax, word ptr ds:[bx + 2]
jg    return_1
return_0_2:
clc

ret   




ENDP

MAX_BSP_DEPTH = 64
NF_SUBSECTOR  = 08000h
NOT_NF_SUBSECTOR  = 07FFFh

;R_RenderBSPNode_

PROC R_RenderBSPNode_ NEAR
 
 ; improvements to stack usage/general algorithm thanks to zero318
 
 PUSHA_NO_AX_MACRO
 mov   bp, sp             ; Max SP difference of (MAX_BSP_DEPTH * 2)
 mov   bx, word ptr ds:[_numnodes]
 dec   bx
 mov   ax, NODES_SEGMENT
 mov   ds, ax
 mov   ax, NODE_CHILDREN_SEGMENT
 mov   es, ax
 jmp   bsp_loop_start

calculate_larger_side:

; note: dx and cx are negative from their expected values,
; so comparative logic has reversed as the imul results will inverse

 imul  dx
 xchg  ax, cx
 mov   si, dx
 imul  di
COMMENT @
; what's wrong with this?
 cmp   cx, ax
 sbb   si, dx
 clc
 jl    calculate_next_bspnum
 cmc
 jmp   calculate_next_bspnum
 @

 cmp   si, dx
 clc                        
 jg    calculate_next_bspnum ; carry flag = !sign, sign on
 stc
 jne   calculate_next_bspnum ; carry flag = !sign, sign off
; equals fall thru, check low bits
 cmp   cx, ax                ; sets carry flag as same as unsigned compare
 jmp   calculate_next_bspnum
bsp_inner_loop:         

; bx = bspnum * 2

 shl   bx, 1  ; bx = bspnum * 2
 mov   si, bx ; bx = bspnum * 4
 shl   si, 1  ; si = bspnum * 8

 lodsw                         ; NODE_T.n_x
SELFMODIFY_BSP_viewx_hi_6:
 sub   ax, 01000h
 xchg  ax, dx     ; 
 lodsw                         ; NODE_T.n_y
SELFMODIFY_BSP_viewy_hi_6:
 sub   ax, 01000h
 xchg  ax, cx
 lodsw                         ; NODE_T.n_dx
 xchg  ax, di
 lodsw                         ; NODE_T.n_dy


 ; todo bench if this is actually faster

; dx and cx are inverse. this is fine for the sign check (two negatives cancel out)
; in the mul case, we neg at that time.

 mov   si, cx          ; copy for sign check
 xor   si, dx
 xor   si, ax
 xor   si, di
 jns   calculate_larger_side
 xor   dh, ah         ; dh sign is backwards
 shl   dh, 1          ; carry = !sign
calculate_next_bspnum:
 sbb   si, si         ; -1 when unsigned, carry = !sign
 mov   cx, bx
 rcr   cx, 1          ; cx = bspnum * 2 with !side bit in sign
 push  cx
 inc   si             ; switching -1/0 to 0/1 inverts sign
 shl   si, 1
bsp_outer_loop:
 mov   bx, es:[bx+si] ; add side lookup
bsp_loop_start:
 shl   bx, 1          ; Tests sign bit with one less instruction per inner loop
 jnc   bsp_inner_loop
 shr   bx, 1          ; unshift
 cmp   bx, -1         ; sets carry for any values that aren't 0x7FFF
 sbb   ax, ax
 and   ax, bx         ; ax = (bx == 0x7FFF) ? 0 : bx

 mov   dx, ss ; Restore DS
 mov   ds, dx
 call  R_Subsector_

loop_check_bbox:
 cmp   sp, bp ; Compare with original SP value
 je    exit_renderbspnode 
 pop   ax
 xor   bx, bx

; calculate node_render address.
; NODE_RENDER_T are 16 bytes long
; two sides of 8 bytes each
; bx gets 0 or 8, the render address is packed into the segment (ES) by shifting right 4 basically
 shl   ax, 1   ; bx = bspnum * 4 and extract side bit into carry
 rcl   bx, 1   ; side was already stored inverted
 shl   bx, 1   ; side * 2
 
 add   ax, bx
 mov   word ptr cs:[_SELFMODIFY_set_next_child_node+3], ax

 shr   ax, 1
 shr   ax, 1
 add   ax, NODES_RENDER_SEGMENT
 mov   ds, ax
  
 shl   bx, 1   ; bx = side * 4
 shl   bx, 1   ; bx = side * 8
 

 call  R_CheckBBox_     ; bx and cx values are clobbered. 
 jnc   loop_check_bbox
 mov   ax, NODES_SEGMENT
 mov   ds, ax
 mov   ax, NODE_CHILDREN_SEGMENT
 mov   es, ax
_SELFMODIFY_set_next_child_node:
 mov    bx, es:[01000h]
 jmp   bsp_loop_start
exit_renderbspnode:
 POPA_NO_AX_MACRO
 ret
ENDP



_pagesegments:

dw 00000h, 00400h, 00800h, 00C00h
dw 01000h, 01400h, 01800h, 01C00h




; todo pass in si to be _textureL1LRU ptr. put that in < 0x80

PROC R_MarkL1TextureCacheMRU_ NEAR


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




; assumes ah 0
PROC R_MarkL2TextureCacheMRU_ NEAR


cmp  al, byte ptr ds:[_texturecache_l2_head]
jne  dont_early_out_texture
ret

dont_early_out_texture:
PUSHA_NO_AX_MACRO
mov  si, OFFSET _texturecache_nodes
mov  di, OFFSET _texturecache_l2_tail
mov  es, di
mov  di, OFFSET _texturecache_l2_head
;dec  di  ; OFFSET _texturecache_l2_head
; todo just use di - 1 instead of es


do_markl2func:

mov  cl, byte ptr ds:[di]
mov  dl, al
mov  bx, ax

;	pagecount = spritecache_nodes[index].pagecount;
;	if (pagecount){

SHIFT_MACRO shl  bx 2
mov  al, byte ptr ds:[bx + si + 2]
test al, al
je   sprite_pagecount_zero

;	 	while (spritecache_nodes[index].numpages != spritecache_nodes[index].pagecount){
;			index = spritecache_nodes[index].next;
;		}

sprite_check_next_cache_node:
mov  bl, dl   ; bh always zero here...
SHIFT_MACRO shl  bx 2
mov  ax, word ptr ds:[bx + si + 2]
cmp  al, ah
je   sprite_found_first_index
mov  dl, byte ptr ds:[bx + si + 1]
jmp  sprite_check_next_cache_node

sprite_found_first_index:

;		if (index == spritecache_l2_head) {
;			return;
;		}

cmp  dl, cl             ; dh is free, use dh instead here?
je   mark_sprite_lru_exit
sprite_pagecount_zero:


; bx should already be set...

;	if (spritecache_nodes[index].numpages){

cmp  byte ptr ds:[bx + si + 3], 0
je   selected_sprite_page_single_page

; multi page case...

;		lastindex = index;
;		while (spritecache_nodes[lastindex].pagecount != 1){
;			lastindex = spritecache_nodes[lastindex].prev;
;		}


mov  dh, dl         ; dh = last index
sprite_check_next_cache_node_pagecount:

mov  bl, dh         ; bh always 0 here...
SHIFT_MACRO  shl  bx 2
cmp  byte ptr ds:[bx + si + 2], 1
je   found_sprite_multipage_last_page
mov  dh, byte ptr ds:[bx + si + 0]
jmp  sprite_check_next_cache_node_pagecount

found_sprite_multipage_last_page:

; dl = index
; dh = lastindex

;		lastindex_prev = spritecache_nodes[lastindex].prev;
;		index_next = spritecache_nodes[index].next;


mov  ch, byte ptr ds:[bx + si + 0]    ; lastindex_prev
mov  bl, dl
SHIFT_MACRO   shl  bx 2

mov  cl, byte ptr ds:[bx + si + 1]    ; index_next

;		if (spritecache_l2_tail == lastindex){
mov  bx, es  ; tail
cmp  dh, byte ptr ds:[bx]
jne  spritecache_l2_tail_not_equal_to_lastindex

;			spritecache_l2_tail = index_next;
;			spritecache_nodes[index_next].prev = -1;

mov  byte ptr ds:[bx], cl
xor  bx, bx
mov  bl, cl
SHIFT_MACRO   shl  bx 2
mov  byte ptr ds:[bx + si + 0], -1
jmp  sprite_done_with_multi_tail_update

spritecache_l2_tail_not_equal_to_lastindex:

;			spritecache_nodes[lastindex_prev].next = index_next;
;			spritecache_nodes[index_next].prev = lastindex_prev;

xor  bx, bx
mov  bl, ch
SHIFT_MACRO shl  bx 2
mov  byte ptr ds:[bx + si + 1], cl

mov  bl, cl
SHIFT_MACRO shl  bx 2
mov  byte ptr ds:[bx + si + 0], ch

sprite_done_with_multi_tail_update:

;		spritecache_nodes[lastindex].prev = spritecache_l2_head;
;		spritecache_nodes[spritecache_l2_head].next = lastindex;

mov  bl, dh
SHIFT_MACRO    shl  bx 2
mov  al, byte ptr ds:[di]
mov  byte ptr ds:[bx + si + 0], al  ; spritecache_l2_head
mov  bl, al
SHIFT_MACRO    shl  bx 2
mov  byte ptr ds:[bx + si + 1], dh  ; lastindex

mov  bl, dl
SHIFT_MACRO    shl  bx 2

;		spritecache_nodes[index].next = -1;
;		spritecache_l2_head = index;


mov  byte ptr ds:[di], dl
mov  byte ptr ds:[bx + si + 1], -1
mark_sprite_lru_exit:
POPA_NO_AX_MACRO
ret  

selected_sprite_page_single_page:

;		// handle the simple one page case.
;		prev = spritecache_nodes[index].prev;
;		next = spritecache_nodes[index].next;

mov  dh, byte ptr ds:[bx + si + 1]
mov  ch, byte ptr ds:[bx + si + 0]

;		if (index == spritecache_l2_tail) {
;			spritecache_l2_tail = next;
;		} else {
;			spritecache_nodes[prev].next = next; 
;		}


mov  bx, es  ; tail
cmp  dl, byte ptr ds:[bx]
jne  spritecache_tail_not_equal_to_index
mov  byte ptr ds:[bx], dh
xor  bx, bx
jmp  done_with_spritecache_tail_handling

spritecache_tail_not_equal_to_index:
xor  bx, bx
mov  bl, ch
SHIFT_MACRO shl  bx 2
mov  byte ptr ds:[bx + si + 1], dh

done_with_spritecache_tail_handling:

; spritecache_nodes[next].prev = prev;  // works in either of the above cases. prev is -1 if tail.

mov  bl, dh
SHIFT_MACRO shl  bx 2
mov  byte ptr ds:[bx + si + 0], ch

;	spritecache_nodes[index].prev = spritecache_l2_head;
;	spritecache_nodes[index].next = -1;

mov  bl, dl
SHIFT_MACRO shl  bx 2
mov  ch, -1
mov  word ptr ds:[bx + si + 0], cx

; spritecache_nodes[spritecache_l2_head].next = index;

mov  bl, cl
SHIFT_MACRO shl  bx 2
mov  byte ptr ds:[bx + si + 1], dl

;	spritecache_l2_head = index;

mov  byte ptr ds:[di], dl

POPA_NO_AX_MACRO
ret  


ENDP




PROC R_EvictL2CacheEMSPage_ NEAR

; bp - 2    used for ds first, used for es first
; bp - 4    second offset used for si
; bp - 6    used for ds second
; bp - 8    secondarymaxitersize
; bp - 0Ch currentpage

push      bx
push      cx
push      si
push      di
push      bp
mov       bp, sp
mov       dh, al


cmp       dl, CACHETYPE_COMPOSITE
jne       not_composite

IF COMPISA GE COMPILE_186
    push      COMPOSITETEXTUREPAGE_SEGMENT      ; bp - 2
    push      MAX_TEXTURES                      ; bp - 4
    push      PATCHOFFSET_SEGMENT               ; bp - 6
    push      MAX_PATCHES                       ; bp - 8
ELSE
    mov       ax, COMPOSITETEXTUREPAGE_SEGMENT      ; bp - 2
    push      ax
    mov       ax, MAX_PATCHES                       ; bp - 4
    push      ax
    mov       ax, PATCHOFFSET_SEGMENT               ; bp - 6
    push      ax
    mov       ax, MAX_PATCHES                       ; bp - 8
    push      ax

ENDIF
mov       bx, OFFSET _texturecache_l2_tail
mov       di, OFFSET _texturecache_nodes


jmp       done_with_switchblock
not_composite:


is_patch:
IF COMPISA GE COMPILE_186
    push      PATCHPAGE_SEGMENT                 ; bp - 2
    push      MAX_PATCHES                       ; bp - 4
    push      COMPOSITETEXTUREOFFSET_SEGMENT    ; bp - 6
    push      MAX_TEXTURES                      ; bp - 8
ELSE
    mov       ax, PATCHPAGE_SEGMENT                 ; bp - 2
    push      ax
    mov       ax, MAX_PATCHES                       ; bp - 4
    push      ax
    mov       ax, COMPOSITETEXTUREOFFSET_SEGMENT    ; bp - 6
    push      ax
    mov       ax, MAX_TEXTURES                      ; bp - 8
    push      ax

ENDIF
mov       bx, OFFSET _texturecache_l2_tail
mov       di, OFFSET _texturecache_nodes




done_with_switchblock:

;	currentpage = *nodetail;

mov       al, byte ptr ds:[bx]
cbw      
xor       dl, dl

;	// go back enough pages to allocate them all.
;	for (j = 0; j < numpages-1; j++){
;		currentpage = nodelist[currentpage].next;
;	}


; dh has numpages
; dl has j
dec       dh  ; numpages - 1

go_back_next_page:
cmp       dl, dh
jge       found_enough_pages
mov       bx, ax
SHIFT_MACRO shl       bx, 2
mov       al, byte ptr ds:[bx + di + 1]  ; get next
inc       dl
jmp       go_back_next_page


found_enough_pages:

push ax   ; bp - 0Ah store currentpage

;	evictedpage = currentpage;

mov       cx, ax

;	while (nodelist[evictedpage].numpages != nodelist[evictedpage].pagecount){
;		evictedpage = nodelist[evictedpage].next;
;	}


find_first_evictable_page:
mov       bx, cx
SHIFT_MACRO shl       bx, 2
mov       ax, word ptr ds:[bx + di + 2]
cmp       al, ah
je        found_first_evictable_page
mov       al, byte ptr ds:[bx + di + 1]
cbw      
mov       cx, ax
jmp       find_first_evictable_page

found_first_evictable_page:





;	while (evictedpage != -1){
mov       dx, 000FFh      ; dh gets 0, dl gets ff

check_next_evicted_page:
cmp       cl, dl
je        cleared_all_cache_data


do_next_evicted_page:


; loop setup
mov       bx, cx
SHIFT_MACRO shl       bx 2

xor       ax, ax


;		nodelist[evictedpage].pagecount = 0;
;		nodelist[evictedpage].numpages = 0;

mov       word ptr ss:[bx + di + 2], ax    ; set both at once
mov       si, ax                   ; zero
; ds!
lds       bx, dword ptr [bp - 4] ; both an index and a loop limit

;    for (k = 0; k < maxitersize; k++){
;			if ((cacherefpage[k] >> 2) == evictedpage){
;				cacherefpage[k] = 0xFF;
;				cacherefoffset[k] = 0xFF;
;			}
;		}
dec       bx   ; lodsw makes this off by one so we offset here...

continue_first_cache_erase_loop:
lodsb     ; increments si...
SHIFT_MACRO shr       ax, 2
cmp       al, cl
je        erase_this_page
done_erasing_page:
cmp       si, bx
jle       continue_first_cache_erase_loop   ; jle, not jl because bx is decced

done_with_first_cache_erase_loop:


;	for (k = 0; k < secondarymaxitersize; k++){
;        if ((secondarycacherefpage[k]) >> 2 == evictedpage){
;            secondarycacherefpage[k] = 0xFF;
;            secondarycacherefoffset[k] = 0xFF;
;        }
;    }

lds       bx, dword ptr [bp - 8] 
cmp       bx, 0 
jle       skip_secondary_loop


xor       si, si                     ; offset and loop ctr
dec       bx
continue_second_cache_erase_loop:
lodsb

SHIFT_MACRO sar       ax 2
cmp       al, cl
je        erase_second_page
done_erasing_second_page:
cmp       si, bx
jle       continue_second_cache_erase_loop    ; jle, not jl because bx is decced

skip_secondary_loop:

;		usedcacherefpage[evictedpage] = 0;




mov       si, OFFSET _usedtexturepagemem
mov       bx, cx
mov       byte ptr ss:[bx + si], dh    ; 0

;		evictedpage = nodelist[evictedpage].prev;

SHIFT_MACRO shl       bx 2
mov       cl, byte ptr ss:[bx + di]     ; get prev
cmp       cl, dl                   ; dl is -1
jne       do_next_evicted_page


cleared_all_cache_data:

;	// connect old tail and old head.
;	nodelist[*nodetail].prev = *nodehead;



mov      ax, ss
mov      ds, ax


mov       si, OFFSET _texturecache_l2_tail
lodsb
cbw      
mov       cx, ax            ; cx stores nodetail

SHIFT_MACRO shl       ax 2
xchg      ax, bx            ; bx has nodelist nodetail lookup

mov       si, OFFSET _texturecache_l2_head
mov       al, byte ptr ds:[si]
mov       byte ptr ds:[bx + di], al
mov       bl, al


;	nodelist[*nodehead].next = *nodetail;

SHIFT_MACRO shl       bx 2


mov       byte ptr ds:[bx + di + 1], cl  ; write nodetail to next

;	previous_next = nodelist[currentpage].next;

;	*nodehead = currentpage;

mov       bx, word ptr [bp - 0Ah]
mov       byte ptr ds:[si], bl
SHIFT_MACRO shl       bx 2
mov       al, byte ptr ds:[bx + di + 1]    ; previous_next
cbw


;	nodelist[currentpage].next = -1;

mov       byte ptr ds:[bx + di + 1], dl   ; still 0FFh

;	*nodetail = previous_next;


mov       bx, OFFSET _texturecache_l2_tail
mov       byte ptr ds:[bx], al


;	// new tail
;	nodelist[previous_next].prev = -1;
mov       bx, ax
SHIFT_MACRO shl       bx 2
mov       byte ptr ds:[bx + di], dl    ; still 0FFh

;	return *nodehead;

lodsb       

LEAVE_MACRO     
pop       di
pop       si
pop       cx
pop       bx
ret       
erase_this_page:
mov       byte ptr ds:[si-1], dl     ; 0FFh
mov       byte ptr ds:[si+bx], dl    ; 0FFh
jmp       done_erasing_page

erase_second_page:
mov       byte ptr ds:[si-1], dl      ; 0FFh
mov       byte ptr ds:[si+bx], dl     ; 0FFh
jmp       done_erasing_second_page



ENDP




COLUMN_IN_CACHE_WAD_LUMP_SEGMENT = 07000h





PROC R_GetNextTextureBlock_ NEAR

; bp - 2  cachetype
; bp - 4  blocksize
; bp - 6  NUM_[thing]_PAGES for iter
; bp - 8  tex_index

PUSHA_NO_AX_MACRO
push      bp
mov       bp, sp

push      bx  ; only bl technically   ; cachetype
mov       bl, dh
push      bx  ; only bl technically
IF COMPISA GE COMPILE_186
    push      NUM_TEXTURE_PAGES
ELSE
    mov   di, NUM_TEXTURE_PAGES 
    push  di
ENDIF

push      ax  ; bp - 6  store for later
mov       di, OFFSET _texturecache_nodes
mov       si, OFFSET _usedtexturepagemem

get_next_block_variables_ready:
xchg      ax, bx


;	if (size & 0xFF) {
;		blocksize++;
;	}

test      dl, 0FFh
je        dont_increment_blocksize
inc       al
mov       byte ptr [bp - 4], al
dont_increment_blocksize:
;	numpages = blocksize >> 6; // num EMS pages needed

xor       ah, ah
SHIFT_MACRO rol       al 2
and       al, 3

;	if (blocksize & 0x3F) {
;		numpages++;
;	}

mov       ch, al
test      byte ptr [bp - 4], 03Fh
je        dont_increment_numpages
inc       ch
dont_increment_numpages:

;	if (numpages == 1) {

xor       bx, bx
cmp       ch, 1
jne       multipage_textureblock
;		uint8_t freethreshold = 64 - blocksize;
mov       dx, 04000h
sub       dh, byte ptr [bp - 4]
; dl zeroed 

;		for (i = 0; i < NUM_TEXTURE_PAGES; i++) {
;			if (freethreshold >= usedtexturepagemem[i]) {
;				goto foundonepage;
;			}
;		}

check_next_texture_page_for_space:
mov       bl, dl
cmp       dh, byte ptr ds:[bx + si]
jnb       foundonepage

;		i = R_EvictL2CacheEMSPage(1, cachetype);

inc       dl
cmp       dl, [bp - 6]
jl        check_next_texture_page_for_space
mov       al, byte ptr [bp - 2]
cbw      
mov       dx, ax
mov       al, 1
call      R_EvictL2CacheEMSPage_
mov       dl, al

foundonepage:

;		texpage = i << 2;
;		texoffset = usedtexturepagemem[i];
;		usedtexturepagemem[i] += blocksize;

mov       dh, dl
SHIFT_MACRO shl       dh 2
mov       bl, dl
mov       al, byte ptr ds:[bx + si]
mov       ah, byte ptr [bp - 4]
add       ah, al
mov       byte ptr ds:[bx + si], ah

done_finding_open_page:
pop       si ; was bp - 6
cmp       byte ptr [bp - 2], CACHETYPE_PATCH
jne       set_non_patch_pages
set_patch_pages:
mov       bx, PATCHOFFSET_SEGMENT
mov       es, bx
mov       byte ptr es:[si], dh
mov       byte ptr es:[si + PATCHOFFSET_OFFSET], al
LEAVE_MACRO     
POPA_NO_AX_MACRO
ret       
set_non_patch_pages:

set_tex_pages:
mov       bx, COMPOSITETEXTUREOFFSET_SEGMENT
mov       es, bx
mov       byte ptr es:[si], dh
mov       byte ptr es:[si + COMPOSITETEXTUREOFFSET_OFFSET], al
LEAVE_MACRO     
POPA_NO_AX_MACRO
ret       


multipage_textureblock:

;		uint8_t numpagesminus1 = numpages - 1;

mov       dh, byte ptr ds:[_texturecache_l2_head]
mov       ah, 0FFh
mov       cl, 040h
; al is free, in use a lot
; ah is 0FFh
; bh is 000h
; bl is active offset
; ch is numpages
; cl is 040h
; dh is head
; dl is nextpage


;		for (i = texturecache_l2_head;
;				i != -1; 
;				i = texturecache_nodes[i].prev
;				) {
;			if (!usedtexturepagemem[i]) {
;				// need to check following pages for emptiness, or else after evictions weird stuff can happen
;				int8_t nextpage = texturecache_nodes[i].prev;
;				if ((nextpage != -1 &&!usedtexturepagemem[nextpage])) {
;					nextpage = texturecache_nodes[nextpage].prev;

;				}
;			}
;		}

cmp       dh, ah  ; dh is texturecache_l2_head
je        done_with_textureblock_multipage_loop

do_texture_multipage_loop:
mov       bl, dh
cmp       byte ptr ds:[bx + si], bh
jne       do_next_texture_multipage_loop_iter

page_has_space:
SHIFT_MACRO shl       bl 2
mov       al, byte ptr ds:[bx + di]
cmp       al, ah
je        do_next_texture_multipage_loop_iter
; has next page
mov       bl, al
cmp       byte ptr ds:[bx + si], bh
jne       do_next_texture_multipage_loop_iter
SHIFT_MACRO shl       bl 2
mov       dl, byte ptr ds:[bx + di]

;					if (numpagesminus1 < 2 || (nextpage != -1 && (!usedtexturepagemem[nextpage]))) {


cmp       ch, 3   ; use numpages instead of numpagesminus1
jb        less_than_2_pages_or_next_page_good
not_less_than_2_pages_check_next_page_good:
cmp       dl, ah
je        do_next_texture_multipage_loop_iter
mov       bl, dl
cmp       byte ptr ds:[bx + si], bh
jne       do_next_texture_multipage_loop_iter

less_than_2_pages_or_next_page_good:

;						nextpage = texturecache_nodes[nextpage].prev;

mov       bl, dl
SHIFT_MACRO shl       bl 2
mov       dl, byte ptr ds:[bx + di]

;						if (numpagesminus1 < 3 || (nextpage != -1 &&(!usedtexturepagemem[nextpage]))) {
;							goto foundmultipage;
;						}

cmp       ch, 4  ; use numpages instead of numpagesminus1
jb        found_multipage


check_for_next_multipage_loop_iter:

; (nextpage != -1 &&(!usedtexturepagemem[nextpage])
cmp       dl, ah
je        do_next_texture_multipage_loop_iter
mov       bl, dl
cmp       byte ptr ds:[bx + si], bh
jne       do_next_texture_multipage_loop_iter

do_next_texture_multipage_loop_iter:
mov       bl, dh
SHIFT_MACRO shl       bl 2
mov       dh, byte ptr ds:[bx + di]
cmp       dh, ah
jne       do_texture_multipage_loop

done_with_textureblock_multipage_loop:

;		i = R_EvictL2CacheEMSPage(numpages, cachetype);

mov       al, byte ptr [bp - 2]
cbw      
mov       dx, ax
mov       al, ch
call      R_EvictL2CacheEMSPage_
mov       dh, al

less_than_3_pages_or_next_page_good:
found_multipage:
;		foundmultipage:
;        usedtexturepagemem[i] = 64;

mov       bl, dh
mov       byte ptr ds:[bx + si], cl

;		texturecache_nodes[i].numpages = numpages;
;		texturecache_nodes[i].pagecount = numpages;

SHIFT_MACRO shl       bl 2
mov       byte ptr ds:[bx + di + 3], ch
mov       byte ptr ds:[bx + di + 2], ch
mov       dl, dh
;		if (numpages >= 3) {
cmp       ch, 3
jl        numpages_not_3_or_more
mov       dl, byte ptr ds:[bx + di]
mov       bl, dl
mov       al, ch
dec       al
mov       byte ptr ds:[bx + si], cl
SHIFT_MACRO shl       bl 2
mov       byte ptr ds:[bx + di + 3], ch
mov       byte ptr ds:[bx + di + 2], al
numpages_not_3_or_more:
mov       bl, dl
SHIFT_MACRO shl       bl 2
mov       al, byte ptr ds:[bx + di]
mov       bl, al
SHIFT_MACRO shl       bl 2

;		texturecache_nodes[j].numpages = numpages;
;		texturecache_nodes[j].pagecount = 1;

mov       byte ptr ds:[bx + di + 2], 1
mov       byte ptr ds:[bx + di + 3], ch
mov       bl, al

mov       al, byte ptr [bp - 4]

;	if (blocksize & 0x3F) {

test      al, 03Fh
jne        dont_set_used_all_memory_for_page
;			usedtexturepagemem[j] = blocksize & 0x3F;
set_used_all_memory_for_page:

;			usedtexturepagemem[j] = 64;


;		texpage = (i << 2) + (numpagesminus1);
;		texoffset = 0; // if multipage then its always aligned to start of its block


mov       byte ptr ds:[bx + si], cl
SHIFT_MACRO shl       dh 2
xor       al, al
add       dh, ch  ; use numpages instead of numpagesminus1
dec       dh 
jmp       done_finding_open_page
dont_set_used_all_memory_for_page:
and       al, 03Fh
mov       byte ptr ds:[bx + si], al

;		texpage = (i << 2) + (numpagesminus1);
;		texoffset = 0; // if multipage then its always aligned to start of its block

SHIFT_MACRO shl       dh 2
xor       al, al
add       dh, ch    ; use numpages instead of numpagesminus1. need the dec
dec       dh
jmp       done_finding_open_page



ENDP





; part of R_GetTexturePage_

found_active_single_page:

;    R_MarkL1TextureCacheMRU(i);
; bl holds i
; al holds realtexpage

xchg  ax, dx            ; dx gets realtexpage
mov   ax, bx            ; ax gets i
call  R_MarkL1TextureCacheMRU_

;    R_MarkL2TextureCacheMRU(realtexpage);

xchg  ax, dx            ; realtexpage into ax. 
call  R_MarkL2TextureCacheMRU_

;    return i;

mov   es, bx            ; return i
LEAVE_MACRO 
POPA_NO_AX_MACRO
mov   ax, es
ret   



PROC R_GetTexturePage_ NEAR

;uint8_t __near R_GetTexturePage(uint8_t texpage, uint8_t pageoffset){
; al texpage
; dl pageoffset




; bp - 2 pageoffset
; bp - 4 realtexpage
; bp - 6 startpage in multi-area

; todo todo remove

PUSHA_NO_AX_MACRO
push  bp
mov   bp, sp



mov   si, OFFSET _activetexturepages
mov   di, OFFSET _activenumpages
mov   cx, NUM_TEXTURE_L1_CACHE_PAGES
xor   dh, dh
continue_get_page:

push  dx        ; bp - 2   dh 0 pageoffset

;	uint8_t realtexpage = texpage >> 2;
mov   dl, al
SHIFT_MACRO sar   dx 2
push  dx        ; bp - 4   dh 0 realtexpage

;	uint8_t numpages = (texpage& 0x03);


xchg  ax, dx   ; ax has realtexpage
and   dx, 3    ; zero dh here
;	if (!numpages) {                ; todo push less stuff if we get the zero case?
jne   get_multipage

; single page

;		// one page, most common case - lets write faster code here...
;		for (i = 0; i < NUM_TEXTURE_L1_CACHE_PAGES; i++) {
;			if (activetexturepages[i] == realtexpage ) {
;				R_MarkL1TextureCacheMRU(i);
;				R_MarkL2TextureCacheMRU(realtexpage);
;				return i;
;			}
;		}

;     dl/dx known zero because we jumped otherwise.
mov   bx, dx ; zero

; al is realtexpage
; bx is i

loop_next_active_page_single:
cmp   al, byte ptr ds:[bx + si]
je    found_active_single_page
inc   bx
cmp   bx, cx
jb    loop_next_active_page_single

; cache miss...

;		startpage = textureL1LRU[NUM_TEXTURE_L1_CACHE_PAGES-1];
;		R_MarkL1TextureCacheMRU7(startpage);

;   ah is 0. al is dirty but gets fixed...
cwd
dec   dx ; dx = -1, ah is 0
mov   bx, cx    ; NUM_TEXTURE_L1_CACHE_PAGES
dec   bx        ; NUM_TEXTURE_L1_CACHE_PAGES - 1
mov   al, byte ptr ds:[bx + _textureL1LRU]   ; textureL1LRU[NUM_TEXTURE_L1_CACHE_PAGES-1]
mov   cx, ax
;call  R_MarkL1TextureCacheMRU7_ ; todo inline?
mov   bx, OFFSET _textureL1LRU+1

push word ptr ds:[bx+4]     ; grab [5] and [6]
pop  word ptr ds:[bx+5]     ; put in [6] and [7]

push word ptr ds:[bx+2]     ; grab [3] and [4]
pop  word ptr ds:[bx+3]     ; put in [4] and [5]

push word ptr ds:[bx+0]     ; grab [1] and [2]
pop  word ptr ds:[bx+1]     ; put in [2] and [3]

xchg al, byte ptr ds:[bx-1] ; swap index for [0]
mov  byte ptr ds:[bx], al ; put [0] in [1]

mov   bx, cx


;		// if the deallocated page was a multipage allocation then we want to invalidate the other pages.
;		if (activenumpages[startpage]) {
;			for (i = 1; i <= activenumpages[startpage]; i++) {
;				activetexturepages[startpage+i]  = -1; // unpaged
;				//this is unmapping the page, so we don't need to use pagenum/nodelist
;				pageswapargs[pageswapargs_rend_texture_offset+( startpage+i)*PAGE_SWAP_ARG_MULT] = 
;					_NPR(PAGE_5000_OFFSET+startpage+i);
;				activenumpages[startpage+i] = 0;
;			}
;		}

cmp   byte ptr ds:[bx + di], ah  ; ah is still 0 after MRU7/MRU3 func 0
je    found_start_page_single

mov   al, 1 ; al/ax is i
; cl/cx is start page.
; bx is start page or startpage + i offset
; dl was numpages but we know its zero. so use dx for -1 for small code reasons

deallocate_next_startpage_single:

cmp   al, byte ptr ds:[bx + di]
ja    found_start_page_single

add   bl, al
mov   byte ptr ds:[bx + di], 0


; bx is currently startpage+i as a byte lookup

; _NPR(PAGE_5000_OFFSET+startpage+i);


IFDEF COMP_CH
    IF COMP_CH EQ CHIPSET_SCAT
        mov   byte ptr ds:[bx + si], dl   ; dl is -1
        sal   bx, 1
        SHIFT_PAGESWAP_ARGS bx
        mov   word ptr ds:[bx + _pageswapargs + (PAGESWAPARGS_REND_TEXTURE_OFFSET * 2)], 03FFh
    ELSEIF COMP_CH EQ CHIPSET_SCAMP
        mov   byte ptr ds:[bx + si], dl   ; dl is -1
        mov   dx, bx
        sal   bx, 1
        add   dx, ((SCAMP_PAGE_9000_OFFSET + 4) - (010000h - PAGE_5000_OFFSET)) 
        SHIFT_PAGESWAP_ARGS bx
        mov   word ptr ds:[bx + _pageswapargs + (PAGESWAPARGS_REND_TEXTURE_OFFSET * 2)], dx
        mov   dx, -1
    ELSEIF COMP_CH EQ CHIPSET_HT18
        mov   byte ptr ds:[bx + si], dl   ; dl is -1
        sal   bx, 1
        SHIFT_PAGESWAP_ARGS bx
        mov   word ptr ds:[bx + _pageswapargs + (PAGESWAPARGS_REND_TEXTURE_OFFSET * 2)], 0
    ENDIF
ELSE
    mov   byte ptr ds:[bx + si], dl   ; dl is -1
    sal   bx, 1
        SHIFT_PAGESWAP_ARGS bx
    mov   word ptr ds:[bx + _pageswapargs + (PAGESWAPARGS_REND_TEXTURE_OFFSET * 2)], dx  ; dx is -1

ENDIF

inc   al


mov   bx, cx    ; zero out bh
jmp   deallocate_next_startpage_single

get_multipage:

; ah already zero

mov   bx, 0FFFFh ; -1, offset for the initial inc
; cx already the number
sub   cx, dx
;  al/ax already realtexpage

; dl is numpages
; cl is NUM_TEXTURE_L1_CACHE_PAGES-numpages
; ch is 0
; bl will be i (starts as -2, incrementing to 0 first loop)
; for (i = 0; i < NUM_TEXTURE_L1_CACHE_PAGES-numpages; i++) {
; al is realtexpage


grab_next_page_loop_multi_continue:

inc   bx  ; 0 for 1st iteration after dec

cmp   bl, cl ; loop compare

jnl   evict_and_find_startpage_multi

;    if (activetexturepages[i] != realtexpage){
;        continue;
;    }

cmp   al, byte ptr ds:[bx + si]
jne   grab_next_page_loop_multi_continue


;    // all pages for this texture are in the cache, unevicted.
;    for (j = 0; j <= numpages; j++) {
;        R_MarkL1TextureCacheMRU(i+j);
;    }
mov   dh, bl
; bl is i
; bl/bx will be i+j   
; dl is numpages but we dec it till < 0

mark_all_pages_mru_loop:
mov   ax, bx

call  R_MarkL1TextureCacheMRU_
inc   bl
dec   dl
jns   mark_all_pages_mru_loop
 


;    R_MarkL2TextureCacheMRU(realtexpage);
;    return i;

pop   ax;   word ptr [bp - 4]
call  R_MarkL2TextureCacheMRU_
mov   al, dh
mov   es, ax
LEAVE_MACRO 
POPA_NO_AX_MACRO
mov   ax, es
ret   
 


;		// figure out startpage based on LRU
;		startpage = NUM_TEXTURE_L1_CACHE_PAGES-1; // num EMS pages in conventional memory - 1

evict_and_find_startpage_multi:
xor   ax, ax ; set ah to 0. 
mov   bx, NUM_TEXTURE_L1_CACHE_PAGES
dec   bx
mov   cx, bx
sub   cl, dl
; dl is numpages
; bx is startpage
; cx is ((NUM_TEXTURE_L1_CACHE_PAGES-1)-numpages)

add   bx, OFFSET _textureL1LRU

find_start_page_loop_multi:

;		while (textureL1LRU[startpage] > ((NUM_TEXTURE_L1_CACHE_PAGES-1)-numpages)){
;			startpage--;
;		}

mov   al, byte ptr ds:[bx]
cmp   al, cl
jle   found_startpage_multi
dec   bx
jmp   find_start_page_loop_multi

found_start_page_single:

;		activetexturepages[startpage] = realtexpage; // FIRST_TEXTURE_LOGICAL_PAGE + pagenum;		
;  cl/cx is startpage
;  bl/bx is startpage 

pop   dx  ; bp - 4, get realtexpage
; dx has realtexpage
; bx already ok

mov   byte ptr ds:[bx + di], bh  ; zero
mov   byte ptr ds:[bx + si], dl
shl   bx, 1                      ; startpage word offset.
pop   ax                         ; mov   ax, word ptr [bp - 2]

add   ax, dx                     ; _EPR(pageoffset + realtexpage);
EPR_MACRO ax

; pageswapargs[pageswapargs_rend_texture_offset+(startpage)*PAGE_SWAP_ARG_MULT]

SHIFT_PAGESWAP_ARGS bx
mov   word ptr ds:[bx + _pageswapargs + (PAGESWAPARGS_REND_TEXTURE_OFFSET * 2)], ax        ; = _EPR(pageoffset + realtexpage);

; dx should be realtexpage???
xchg  ax, dx

call  R_MarkL2TextureCacheMRU_
call  Z_QuickMapRenderTexture_BSPLocal_


mov   ax, 0FFFFh

mov   dx, cx
do_tex_eviction:
mov   di, ds
mov   es, di
mov   di, OFFSET _cachedlumps
mov   word ptr ds:[_maskednextlookup], NULL_TEX_COL


;_cachedlumps =                	     _NULL_OFFSET + 006A0h
;_cachedtex =                		 _NULL_OFFSET + 006A8h
;_segloopnextlookup    = 	 		 _NULL_OFFSET + 00000h
;_seglooptexrepeat    = 			 _NULL_OFFSET + 00004h
;_maskedtexrepeat =                  _NULL_OFFSET + 00006h

mov  cx, 6
rep stosw

mov   di, OFFSET  _segloopnextlookup
stosw ; segloopnextlookup[0] = -1; 030
stosw ; segloopnextlookup[1] = -1; 032
inc   ax    ; ax is 0
stosw ; seglooptexrepeat[0] = 0; seglooptexrepeat[1] = 0 ; 034
stosw ; maskedtexrepeat = 0;                             ; 036




mov   es, dx ; dl/dx is start page
LEAVE_MACRO 
POPA_NO_AX_MACRO
mov   ax, es
ret


found_startpage_multi:
;		startpage = textureL1LRU[startpage];


; al already set to startpage
mov   bx, ax    ; ah/bh is 0
push  ax  ; bp - 6
mov   dh, al ; dh gets startpage..
mov   cx, -1

;		// if the deallocated page was a multipage allocation then we want to invalidate the other pages.
;		if (activenumpages[startpage] > numpages) {
;			for (i = numpages; i <= activenumpages[startpage]; i++) {
;				activetexturepages[startpage + i] = -1;
;				// unmapping the page, so we dont need pagenum
;				pageswapargs[pageswapargs_rend_texture_offset+(startpage + i)*PAGE_SWAP_ARG_MULT] 
;					= _NPR(PAGE_5000_OFFSET+startpage+i); // unpaged
;				activenumpages[startpage + i] = 0;
;			}
;		}


cmp   dl, byte ptr ds:[bx + di]
jae   done_invalidating_pages_multi
mov   al, dl

; dl is numpages
; dh is startpage
; al is i
; ah is 0
; bx is startpage lookup

loop_next_invalidate_page_multi:
mov   bl, dh   ; set bl to startpage

cmp   al, byte ptr ds:[bx + di]
ja    done_invalidating_pages_multi

add   bx, ax                     ; startpage + i
mov   byte ptr ds:[bx + di], ah  ; ah is 0



; bx is currently startpage+i as a byte lookup
; _NPR(PAGE_5000_OFFSET+startpage+i);

; complicated because _NPR for scamp requires a calculation,
; for other chipsets its various constants.

IFDEF COMP_CH
    IF COMP_CH EQ CHIPSET_SCAT
        mov   byte ptr ds:[bx + si], cl  ; -1
        sal   bx, 1                      ; startpage word offset.
        SHIFT_PAGESWAP_ARGS bx
        mov   word ptr ds:[bx + _pageswapargs + (PAGESWAPARGS_REND_TEXTURE_OFFSET * 2)], 03FFh
    ELSEIF COMP_CH EQ CHIPSET_SCAMP
        mov   byte ptr ds:[bx + si], cl  ; -1
        mov   cx, bx
        sal   bx, 1                      ; startpage word offset.
        add   cx, ((SCAMP_PAGE_9000_OFFSET + 4) - (010000h - PAGE_5000_OFFSET))  ; page offset
        SHIFT_PAGESWAP_ARGS bx
        mov   word ptr ds:[bx + _pageswapargs + (PAGESWAPARGS_REND_TEXTURE_OFFSET * 2)], cx
        mov   cx, -1
    ELSEIF COMP_CH EQ CHIPSET_HT18
        mov   byte ptr ds:[bx + si], cl  ; -1
        sal   bx, 1                      ; startpage word offset.
        SHIFT_PAGESWAP_ARGS bx
        mov   word ptr ds:[bx + _pageswapargs + (PAGESWAPARGS_REND_TEXTURE_OFFSET * 2)], 0
    ENDIF
ELSE
    mov   byte ptr ds:[bx + si], cl  ; -1
    sal   bx, 1                      ; startpage word offset.
    SHIFT_PAGESWAP_ARGS bx
    mov   word ptr ds:[bx + _pageswapargs + (PAGESWAPARGS_REND_TEXTURE_OFFSET * 2)], cx  ; cx is -1  TODO NPR or whatever

ENDIF

inc   al

xor   bh, bh
jmp   loop_next_invalidate_page_multi


done_invalidating_pages_multi:

;	int8_t currentpage = realtexpage; // pagenum - pageoffset
;	for (i = 0; i <= numpages; i++) {

mov   cl, dh  ; startpage
mov   ch, dl

; ch is numpages - i    (todo could be dl)
; cl has startpage + i

; dl still has numpages, decremented for loop
; dh has startpage


;	for (i = 0; i <= numpages; i++) {
; es gets currentpage
mov   es, word ptr [bp - 4]

;    for (i = 0; i <= numpages; i++) {
;        R_MarkL1TextureCacheMRU(startpage+i);
;        activetexturepages[startpage + i]  = currentpage;
;        activenumpages[startpage + i] = numpages-i;
;        pageswapargs[pageswapargs_rend_texture_offset+(startpage + i)*PAGE_SWAP_ARG_MULT]  = _EPR(currentpage+pageoffset);
;        currentpage = texturecache_nodes[currentpage].prev;
;    }


loop_mark_next_page_mru_multi:

;	R_MarkL1TextureCacheMRU(startpage+i);

mov   al, cl

call  R_MarkL1TextureCacheMRU_


mov   ax, es ; currentpage in ax

mov   bl, cl
mov   byte ptr ds:[bx + di], ch   ;   activenumpages[startpage + i] = numpages-i;
mov   byte ptr ds:[bx + si], al   ;	activetexturepages[startpage + i]  = currentpage;
sal   bx, 1             ; word lookup

add   ax, word ptr [bp - 2]  ; pageoffset
EPR_MACRO ax


;	pageswapargs[pageswapargs_rend_texture_offset+(startpage + i)*PAGE_SWAP_ARG_MULT]  = _EPR(currentpage+pageoffset);

SHIFT_PAGESWAP_ARGS bx
mov   word ptr ds:[bx + _pageswapargs + (PAGESWAPARGS_REND_TEXTURE_OFFSET * 2)], ax


dec   ch    ; dec numpages - i
inc   cl    ; inc startpage + i

;    currentpage = texturecache_nodes[currentpage].prev;
mov   bx, es ; currentpage
SHIFT_MACRO sal   bx 2
mov   bl, byte ptr ds:[bx + _texturecache_nodes]
xor   bh, bh
mov   es, bx
dec   dl
jns   loop_mark_next_page_mru_multi




;    R_MarkL2TextureCacheMRU(realtexpage);
;    Z_QuickMapRenderTexture();

		

mov   ax, word ptr [bp - 4]
call  R_MarkL2TextureCacheMRU_
call  Z_QuickMapRenderTexture_BSPLocal_

;	//todo: detected and only do -1 if its in the knocked out page? pretty infrequent though.
;    cachedtex = -1;
;    cachedtex2 = -1;


mov   ax, 0FFFFh

mov   dl, dh  ; numpages in cl
jmp   do_tex_eviction


ENDP

PATCH_TEXTURE_SEGMENT = 05000h
COMPOSITE_TEXTURE_SEGMENT = 05000h


PROC R_GetPatchTexture_Far24_ FAR
PUBLIC R_GetPatchTexture_Far24_

call R_GetPatchTexture_
retf
ENDP

PROC R_GetPatchTexture_ NEAR
;segment_t __near R_GetPatchTexture(int16_t lump, uint8_t maskedlookup) ;

; bp - 2 = texoffset

push  si


;	int16_t index = lump - firstpatch;
;	uint8_t texpage = patchpage[index];
;	uint8_t texoffset = patchoffset[index];


mov   si, PATCHPAGE_SEGMENT
mov   es, si
mov   si, ax
sub   si, word ptr ds:[_firstpatch]  ; si is index
mov   dh, byte ptr es:[si]                      ; texpage 
cmp   dh, 0FFh
je    patch_not_in_l1_cache

patch_in_l1_cache:
mov   al, dh
mov   dl, byte ptr es:[si + PATCHOFFSET_OFFSET] ; texoffset
xor   dh, dh
mov   si, dx   ; back up texpage
mov   dl, FIRST_TEXTURE_LOGICAL_PAGE
call  R_GetTexturePage_
SHIFT_MACRO shl   si 4  ; shift texpage 4. 
cbw
xchg  ax, si
sal   si, 1
add   ax, word ptr cs:[si + _pagesegments - OFFSET R_BSP24_STARTMARKER_]
add   ah, (PATCH_TEXTURE_SEGMENT SHR 8)
pop   si
ret   

patch_not_in_l1_cache:
; we use bx/cx in here..
push  bx
push  ax  ; bp - 2 store lump

mov   al, dh
cmp   dl, al
jne   set_masked_true
set_masked_false:
xor   ax, ax
push  ax  ; bp - 4
mov   bx, si
mov   dx, word ptr ds:[bx + si + _patch_sizes]

done_doing_lookup:
mov   bx, CACHETYPE_PATCH
mov   ax, si
call  R_GetNextTextureBlock_
mov   ax, PATCHPAGE_SEGMENT
mov   es, ax
xor   ah, ah
mov   al, byte ptr es:[si + PATCHOFFSET_OFFSET]
push  ax     ; bp - 6
mov   al, byte ptr es:[si]
mov   dx, FIRST_TEXTURE_LOGICAL_PAGE
call  R_GetTexturePage_
cbw
mov   si, ax
sal   si, 1
mov   si, word ptr cs:[si + _pagesegments - OFFSET R_BSP24_STARTMARKER_]
pop   ax     ; bp - 6
SHIFT_MACRO   shl ax 4
add   si, PATCH_TEXTURE_SEGMENT
add   si, ax
pop   bx     ; bp - 4
mov   dx, si
pop   ax     ; bp - 2
call  R_LoadPatchColumns_
xchg  ax, si
pop   bx
pop   si
ret   

set_masked_true:
mov   ax, 1
push  ax
xor   dh, dh
mov   bx, dx
SHIFT_MACRO shl   bx 3
mov   dx, word ptr ds:[bx + _masked_headers + 4] ; texturesize field is + 4
jmp   done_doing_lookup



ENDP

PROC R_GetCompositeTexture_Far24_ FAR
PUBLIC R_GetCompositeTexture_Far24_ 

call R_GetCompositeTexture_
retf
ENDP

PROC R_GetCompositeTexture_ NEAR

; segment_t R_GetCompositeTexture(int16_t tex_index) ;

; todo clean up reg use, should be much fewer push/pop

push  dx
push  si


mov   si, COMPOSITETEXTUREPAGE_SEGMENT
mov   es, si
mov   si, ax
mov   al, byte ptr es:[si]
cmp   al, 0FFh
je    composite_not_in_cache
mov   dl, byte ptr es:[si + COMPOSITETEXTUREOFFSET_OFFSET]
xor   dh, dh
mov   si, dx

mov   dl, FIRST_TEXTURE_LOGICAL_PAGE

call  R_GetTexturePage_
SHIFT_MACRO shl   si 4
xor   ah, ah
xchg  ax, si
sal   si, 1

add   ax, word ptr cs:[si + _pagesegments - OFFSET R_BSP24_STARTMARKER_]
add   ah, (COMPOSITE_TEXTURE_SEGMENT SHR 8)

pop   si
pop   dx
ret 

composite_not_in_cache:
push  bx
push  es
mov   dx, TEXTURECOMPOSITESIZES_SEGMENT
mov   es, dx
mov   bx, si
mov   ax, si
mov   dx, word ptr es:[si + bx]
mov   bx, CACHETYPE_COMPOSITE
call  R_GetNextTextureBlock_
pop   es
mov   dx, FIRST_TEXTURE_LOGICAL_PAGE
mov   al, byte ptr es:[si]
mov   bl, byte ptr es:[si + COMPOSITETEXTUREOFFSET_OFFSET]
call  R_GetTexturePage_
xor   ah, ah
xchg  ax, bx   ; bx stores page. ax gets offset
xor   ah, ah
SHIFT_MACRO shl   ax 4
sal   bx, 1
mov   bx, word ptr cs:[bx + _pagesegments - OFFSET R_BSP24_STARTMARKER_]

add   bh, (COMPOSITE_TEXTURE_SEGMENT SHR 8)
add   bx, ax
mov   dx, bx
mov   ax, si
call  R_GenerateComposite_
xchg  ax, bx
pop   bx
pop   si
pop   dx
ret  

ENDP



WAD_PATCH_7000_SEGMENT = 07000h






PROC R_GenerateComposite_ NEAR

; void __near R_GenerateComposite(uint16_t texnum, segment_t block_segment) {

; bp - 2  texnum * 2 (word lookup)
; bp - 4  block_segment
; bp - 6  i (loop counter)
; bp - 8  lastusedpatch/patchpatch starts as -1
; bp - 0Ah  texture width
; bp - 0Ch  texture height
; bp - 0Eh  usetextureheight
; bp - 010h  TEXTUREDEFS_BYTES_SEGMENT
; bp - 012h  texture->patches
; bp - 014h  collump offset?
; bp - 016h  texturepatchcount
; bp - 018h  (innerloop) x
; bp - 01Ah  (innerloop) currentlump
; bp - 01Ch  (innerloop) currentdestsegment
; bp - 01Eh  (innerloop) columnofs[x - x1] 

PUSHA_NO_AX_MACRO
push      bp
mov       bp, sp
; ah should already be 0
mov       bx, ax
sal       bx, 1
push      bx  ; bp - 2
mov       si, bx

push      dx  ; bp - 4
mov       ax, TEXTUREDEFS_OFFSET_SEGMENT
mov       es, ax
mov       bx, word ptr es:[bx]          ; 	texture = (texture_t __far*)&(texturedefs_bytes[texturedefs_offset[texnum]]);
mov       dx, TEXTUREDEFS_BYTES_SEGMENT
mov       es, dx

; todo get both in one read..
xor       ax, ax
cwd       ; zero dx
push      ax ; bp - 6 ; zero
dec       dx
push      dx ; bp - 8 ; -1 now


mov       al, byte ptr es:[bx + 8]      ; texturewidth = texture->width + 1;
inc       ax
push      ax  ; bp - 0Ah 
mov       al, byte ptr es:[bx + 9]      ; textureheight = texture->height + 1;
inc       al
xor       ah, ah
push      ax  ; bp - 0Ch

;	usetextureheight = textureheight + ((16 - (textureheight &0xF)) &0xF);

mov       dx, ax  ; store bp - 0Ch
and       al, 0Fh
mov       ah, 010h
sub       ah, al
mov       al, ah
and       ax, 0Fh




add       al, dl   ; textureheight copy
;	usetextureheight = usetextureheight >> 4;
SHIFT_MACRO sar       ax 4
; ah already known zero


push      ax ; bp - 0Eh
push      es ; bp - 010h

add       bx, 0Bh    ; patches pointer todo?
push      bx ; bp - 012h

;	// Composite the columns together.
;	collump = &(texturecolumnlumps_bytes[texturepatchlump_offset[texnum]]);
; si is bp - 2
mov       si, word ptr ds:[si + _texturepatchlump_offset]
sal       si, 1
push      si ; bp - 014h

;call      Z_QuickMapScratch_7000_

Z_QUICKMAPAI4 pageswapargs_scratch7000_offset_size INDEXED_PAGE_7000_OFFSET

mov       al, byte ptr es:[bx - 1] ; texturepatchcount = texture->patchcount;
xor       ah, ah
push      ax ; bp - 016h texturepatchcount

;	for (i = 0; i < texturepatchcount; i++) {
loop_texture_patch:
; ax is bp - 016h
; todo move this check to the end with selfmodify.
cmp       ax, word ptr [bp - 6]
jng       done_with_composite_loop

les       si, dword ptr [bp - 012h]
xor       bx, bx ; 
mov       di, word ptr [bp - 014h] ; di is collump[currentRLEIndex]

mov       dx, word ptr es:[si + 2]
and       dh, (PATCHMASK SHR 8)
mov       ax, word ptr [bp - 8]
mov       word ptr [bp - 8], dx
cmp       ax, dx
je        use_same_patch
mov       cx, SCRATCH_PAGE_SEGMENT_7000 
mov       ax, dx
;call      W_CacheLumpNumDirect_
call  dword ptr ds:[_W_CacheLumpNumDirect_addr]

mov       es, word ptr [bp - 010h]
use_same_patch:
mov       ax, word ptr es:[si]
mov       dl, ah
xor       ah, ah
;	patchoriginx = patch->originx *  (patch->patch & ORIGINX_SIGN_FLAG ? -1 : 1);

test      byte ptr es:[si + 3], (ORIGINX_SIGN_FLAG SHR 8) 
je       done_with_sign_mul
neg       ax
done_with_sign_mul:

; dl is patchoriginy
mov       bx, WAD_PATCH_7000_SEGMENT
mov       es, bx

;		x1 = patchoriginx;
;		x2 = x1 + (wadpatch7000->width);


mov       bx, word ptr es:[0] ;wadpatch7000->width
add       bx, ax            ;		x2 = x1 + (wadpatch7000->width);
xchg      ax, dx            ;       x1
cbw
mov       word ptr cs:[SELFMODIFY_add_patchoriginy + 1 - OFFSET R_BSP24_STARTMARKER_], ax



;		if (x1 < 0){
;			x = 0;
;		} else {
;			x = x1;
;		}

test      dx, dx
jge       set_x_to_x1

xor       cx, cx
push      cx  ; bp - 018h
jmp       done_setting_x
done_with_composite_loop:
;call      Z_QuickMapRender7000_
Z_QUICKMAPAI4 (pageswapargs_rend_offset_size+12) INDEXED_PAGE_7000_OFFSET


LEAVE_MACRO     
POPA_NO_AX_MACRO
ret       
set_x_to_x1:
push      dx  ; bp - 018h
done_setting_x:

;    if (x2 > texturewidth){
;        x2 = texturewidth;
;    }


cmp       bx, word ptr [bp - 0Ah]
jle       x2_smaller_than_texture_width
mov       bx, word ptr [bp - 0Ah]
x2_smaller_than_texture_width:
mov       word ptr cs:[SELFMODIFY_x2_check+2 - OFFSET R_BSP24_STARTMARKER_], bx

mov       bx, TEXTURECOLUMNLUMPS_BYTES_SEGMENT
mov       es, bx

; es:di is collump

;    currentlump = collump[currentRLEIndex].h;
;    nextcollumpRLE = collump[currentRLEIndex + 1].bu.bytelow + 1;


push      word ptr es:[di]  ; bp - 01Ah  currentlump

mov       al, byte ptr es:[di + 2]
xor       ah, ah
mov       si, ax   ; si is nextcollumpRLE

;		currentdestsegment = block_segment;

push      word ptr [bp - 4] ; ; bp - 01Ch  currentdestsegment from blocksegment
inc       si


; determine dest segment by iterating over x/patches
;    // skip if x is 0, otherwise evaluate till break
;    if (x){

; si/di/dx all currently unusable?
; 

cmp       word ptr [bp - 018h], 0
je        x_is_zero_skip_inner_calc


; loop setup

;    int16_t innercurrentRLEIndex = 0;
;    int16_t innercurrentlump = collump[0].h;
;    int16_t innernextcollumpRLE = collump[1].bu.bytelow + 1;
;    uint8_t currentx = 0;
;    uint8_t diffpixels = 0;

push      dx  ; store dx. we will use it as currentx and diffpixels
push      di  ; to be used as innercurrentRLEIndex
mov       bx, word ptr [bp - 014h]
mov       ax, word ptr es:[bx]
mov       di, ax  ; innercurrentlump todo push/pop solution.
mov       al, byte ptr es:[bx + 2]  ; innernextcollumpRLE
xor       ah, ah
cwd       ; zero dx
; dh is currentx
; dl is diffpixels
continue_inner_loop:


;	if ((currentx + innernextcollumpRLE) < x){

inc       ax
mov       cl, dh
xor       ch, ch
add       cx, ax
cmp       cx, word ptr [bp - 018h]
jge       break_inner_loop

;    if (innercurrentlump == -1){
;        diffpixels += (innernextcollumpRLE);
;    }
;    currentx += innernextcollumpRLE;
;    innercurrentRLEIndex += 2;
;    innercurrentlump = collump[innercurrentRLEIndex].h;
;    innernextcollumpRLE = collump[innercurrentRLEIndex + 1].bu.bytelow + 1;
;    continue;

cmp       di, -1
jne       dont_add_to_diffpixels
add       dl, al
dont_add_to_diffpixels:
add       dh, al
mov       ax, word ptr es:[bx + 4]
mov       di, ax
mov       al, byte ptr es:[bx + 6]
xor       ah, ah
add       bx, 4     ; innercurrentRLEIndex += 2
jmp       continue_inner_loop ; continue
break_inner_loop:

;    if (innercurrentlump == -1){
;        diffpixels += ((x - currentx));
;    }
;    break;

cmp       di, -1
jne       dont_add_final_diffpixels
mov       al, byte ptr [bp - 018h]
sub       al, dh
add       dl, al
dont_add_final_diffpixels:

; currentdestsegment += FastMul8u8u(usetextureheight, diffpixels);

mov       al, byte ptr [bp - 0Eh]
mul       dl
add       word ptr [bp - 01Ch], ax

pop       di ; restore di
pop       dx ; restore dx

x_is_zero_skip_inner_calc:

;    for (; x < x2; x++) {
;    while (x >= nextcollumpRLE) {
;        currentRLEIndex += 2;
;        currentlump = collump[currentRLEIndex].h;
;        nextcollumpRLE += (collump[currentRLEIndex + 1].bu.bytelow + 1);
;    }


; dx is x1

; precalculation for offset of x - x1 word offset.
;			R_DrawColumnInCache(wadpatch7000->columnofs[x - x1],


mov       ax, word ptr [bp - 018h]  ; x
SHIFT_MACRO shl       dx 2  ; x1 << 2
SHIFT_MACRO shl       ax 2  ; x << 2
neg       dx
add       ax, dx                    ; (x - x1 ) << 2
; todo probably store in si/di...
add       ax, 8  ; prestore offset

push      ax  ; bp - 01Eh columnofs[x - x1] 

mov       dx, word ptr [bp - 0Ch] ; dx gets this for the whole inner loop

mov       ax, COLUMN_IN_CACHE_WAD_LUMP_SEGMENT
mov       ds, ax
; todo can we pop this
mov       cx, word ptr [bp - 018h] ; cx is x for this loop


continue_x_x2_loop:
SELFMODIFY_x2_check:
cmp       cx, 01000h  ; x2

; for (; x < x2; x++) {

jge       do_next_composite_loop_iter

mov       ax, TEXTURECOLUMNLUMPS_BYTES_SEGMENT
mov       es, ax


;    while (x >= nextcollumpRLE) {
;        currentRLEIndex += 2;
;        currentlump = collump[currentRLEIndex].h;
;        nextcollumpRLE += (collump[currentRLEIndex + 1].bu.bytelow + 1);
;    }

; es:di is collumn[currentRLEIndex]
; si is nextcollumpRLE

loop_x_nextcollumpRLE:
cmp       si, cx
jg        skip_loop_x_nextcollumpRLE
mov       ax, word ptr es:[di + 4]
mov       word ptr [bp - 01Ah], ax
mov       al, byte ptr es:[di + 6]
xor       ah, ah
inc       ax
add       di, 4
add       si, ax
cmp       si, cx
jng       loop_x_nextcollumpRLE

skip_loop_x_nextcollumpRLE:

;    if (currentlump >= 0) {
;        continue;
;    }

cmp       word ptr [bp - 01Ah], 0
jnl       increment_x_x2_loop



mov       bx, word ptr [bp - 01Eh]
mov       bx, word ptr ds:[bx]
mov       es, word ptr [bp - 01Ch]  ; write straight to seg instead of dx

;    R_DrawColumnInCache(wadpatch7000->columnofs[x - x1],
;        currentdestsegment,
;        patchoriginy,
;        textureheight);

; INLINED!
; call      R_DrawColumnInCache_       ; todo inline segments

push      cx
push      si
push      di

; es already set.
; bx has patchcol_offset
; ds already COLUMN_IN_CACHE_WAD_LUMP_SEGMENT


;	while (patchcol->topdelta != 0xff) { 

cmp       byte ptr ds:[bx], 0FFh
je        exit_drawcolumn_in_cache
do_next_column_patch:

;		uint16_t     count = patchcol->length;

mov       ax, word ptr ds:[bx]  ; al topdelta

xor       cx, cx
xchg      cl, ah                ; length to cl, 0 to ah

; cx is count
; ax is topdelta for now

;		int16_t     position = patchoriginy + patchcol->topdelta;

SELFMODIFY_add_patchoriginy:
add       ax, 01000h ; patchoriginy + topdelta
xchg      ax, di



;		byte __far * source = (byte __far *)patchcol + 3;
lea       si, [bx + 3] ; for memcpy

;		patchcol = (column_t __far*)((byte  __far*)patchcol + count + 4);

add       bx, cx
add       bx, 4


; count is cx
; position is di



;		if (position < 0) {
;			count += position;
;			position = 0;
;		}

test      di, di
jl        position_under_zero
done_with_position_check:

;		if (position + count > textureheight){
;			count = textureheight - position;
;		}

mov       ax, di
add       ax, cx
cmp       ax, dx
jbe       done_with_count_adjustment


;  cx - di is underflowing. perhaps patchoriginy too high?
mov       cx, dx
sub       cx, di
done_with_count_adjustment:
;			FAR_memcpy(MK_FP(currentdestsegment, position), source, count);

shr       cx, 1
rep movsw 
adc       cx, cx
rep movsb 

cmp       byte ptr ds:[bx], 0FFh
jne       do_next_column_patch
exit_drawcolumn_in_cache:

pop       di
pop       si
pop       cx

mov       ax, word ptr [bp - 0Eh]
add       word ptr [bp - 01Ch], ax   ; currentdestsegment += usetextureheight;
increment_x_x2_loop:
add       word ptr [bp - 01Eh], 4
inc       cx
jmp       continue_x_x2_loop

do_next_composite_loop_iter:
mov       ax, ss
mov       ds, ax  ; restore ds
add       word ptr [bp - 012h], 4
inc       word ptr [bp - 6]
mov       ax, word ptr [bp - 016h]
add       sp, 8 ; back to 46?
jmp       loop_texture_patch

position_under_zero:
add       cx, di
xor       di, di
jmp       done_with_position_check

ENDP




SCRATCH_ADDRESS_4000_SEGMENT = 04000h
SCRATCH_ADDRESS_5000_SEGMENT = 05000h

do_masked_jump:
mov       ax, 0c089h   ; 2 byte nop
mov       di, ((SELFMODIFY_loadpatchcolumn_masked_check2_TARGET - SELFMODIFY_loadpatchcolumn_masked_check2_AFTER) SHL 8) + 0EBh
jmp       ready_selfmodify_loadpatch

PROC R_LoadPatchColumns_ NEAR


push      cx
push      si
push      di
push      bp

mov       si, ax

test      bl, bl
jne       do_masked_jump
mov       ax, ((SELFMODIFY_loadpatchcolumn_masked_check1_TARGET - SELFMODIFY_loadpatchcolumn_masked_check1_AFTER) SHL 8) + 0EBh
mov       di, 0c089h   ; 2 byte nop
ready_selfmodify_loadpatch:

mov       word ptr cs:[SELFMODIFY_loadpatchcolumn_masked_check1 - OFFSET R_BSP24_STARTMARKER_], ax;
mov       word ptr cs:[SELFMODIFY_loadpatchcolumn_masked_check2 - OFFSET R_BSP24_STARTMARKER_], di;

push      dx       ; store future es

mov       bx, si

;call      Z_QuickMapScratch_4000_
Z_QUICKMAPAI4 pageswapargs_scratch4000_offset_size INDEXED_PAGE_4000_OFFSET


mov       cx, SCRATCH_ADDRESS_4000_SEGMENT
push      cx
mov       ax, bx
xor       bx, bx  ; zero seg offset
mov       di, bx  ; zero
;call      W_CacheLumpNumDirect_
call  dword ptr ds:[_W_CacheLumpNumDirect_addr]

pop       ds      ; get 4000 segment
pop       es      ; get dest segment

mov       bp, word ptr ds:[di]  ; patchwidth
dec       bp; dec loop needs to start one off to trigger jns/js

mov       ax, di ; zero
cwd              ; zero


; di is destoffset
; ds:[bx] is patch data (in scratch segment)
; ds:[si] is column data

; es is dest segment
mov       bx, 8
mov       dx, 0FFF0h

do_next_column:


mov       si, word ptr ds:[bx]
lodsb     ; get topdelta
cmp       al, dh
je        done_with_column
do_next_post_in_column:

lodsb      ; get length
inc       si   ; si + 3
; ah known zero, thus ch known zero
mov       cx, ax
shr       cx, 1
rep movsw 
adc       cx, cx
rep movsb 

mov       cx, ax  ; restore length in cx
inc       si

;cmp       byte ptr [bp - 2], 0
SELFMODIFY_loadpatchcolumn_masked_check1:
jmp       SHORT       skip_segment_alignment_1
SELFMODIFY_loadpatchcolumn_masked_check1_AFTER:
; ah is 0
; adjust col offset

sub       di, dx
dec       di
and       di, dx

SELFMODIFY_loadpatchcolumn_masked_check1_TARGET:
skip_segment_alignment_1:
lodsb
cmp       al, dh
jne       do_next_post_in_column
done_with_column:
;cmp       byte ptr [bp - 2], 0
SELFMODIFY_loadpatchcolumn_masked_check2:
jmp       SHORT       skip_segment_alignment_2
SELFMODIFY_loadpatchcolumn_masked_check2_AFTER:
; adjust col offset

sub       di, dx
dec       di
and       di, dx

SELFMODIFY_loadpatchcolumn_masked_check2_TARGET:
skip_segment_alignment_2:
add       bx, 4
dec       bp
jns       do_next_column
; restore ds
done_drawing_texture:
mov       ax, ss
mov       ds, ax
pop       bp
;call      Z_QuickMapRender4000_
Z_QUICKMAPAI4 pageswapargs_rend_offset_size INDEXED_PAGE_4000_OFFSET


pop       di
pop       si
pop       cx
ret       


ENDP

; todo inline
PROC Z_QuickMapRenderTexture_BSPLocal_ NEAR


push  dx
push  cx
push  si   

Z_QUICKMAPAI8 pageswapargs_rend_texture_size INDEXED_PAGE_5000_OFFSET

pop   si
pop   cx
pop   dx
ret

ENDP


;R_RenderPlayerView_

PROC R_RenderPlayerView24_ FAR
PUBLIC R_RenderPlayerView24_ 



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

; call      R_SetupFrame_
; INLINED setupframe



;    extralight = player.extralightvalue;
mov       al, byte ptr ds:[_player + 05Eh]  ; player.extralightvalue
mov       byte ptr ds:[_extralight], al



;    if (player.fixedcolormapvalue) {

mov       al, byte ptr ds:[_player + 05Fh]
mov       byte ptr ds:[_fixedcolormap], al   ; al is zero
;		fixedcolormap = 0;
test      al, al
je        done_setting_colormap

set_fixed_colormap_nonzero:

;		fixedcolormap =  player.fixedcolormapvalue << 2; 
SHIFT_MACRO shl       al 2
mov       byte ptr ds:[_fixedcolormap], al

mov       ah, al
mov       cx, MAXLIGHTSCALE / 2        ;        scalelightfixed[i] = fixedcolormap;
mov       di, OFFSET _scalelightfixed  ;     }
rep       stosw


done_setting_colormap:

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

;    validcount_global++;
inc       word ptr ds:[_validcount_global]

;	destview = (byte __far*)(destscreen.w + viewwindowoffset);
les       ax, dword ptr ds:[_destscreen]
add       ax, word ptr ds:[_viewwindowoffset]
mov       word ptr ds:[_destview], ax
mov       word ptr ds:[_destview + 2], es



call      R_WriteBackFrameConstants_
call      R_ClearClipSegs_

mov       word ptr ds:[_ds_p],     (SIZE DRAWSEG_T)             ; drawsegs_PLUSONE
mov       word ptr ds:[_ds_p + 2], DRAWSEGS_BASE_SEGMENT        ; nseed to be written because masked subs 02000h from it due to remapping...
call      R_ClearPlanes_
xor       ax, ax
mov       word ptr ds:[_vissprite_p], ax  ;

;    FAR_memset (cachedheight, 0, sizeof(fixed_t) * SCREENHEIGHT);

call      dword ptr ds:[_NetUpdate_addr]

mov       ax, word ptr ds:[_numnodes]
dec       ax

call      R_RenderBSPNode_
call      dword ptr ds:[_NetUpdate_addr]
call      R_PrepareMaskedPSprites_  ; todo inline

;call      Z_QuickMapRenderPlanes_
Z_QUICKMAPAI3 pageswapargs_renderplane_offset_size INDEXED_PAGE_5000_OFFSET
Z_QUICKMAPAI1_NO_DX (pageswapargs_renderplane_offset_size+3) INDEXED_PAGE_9C00_OFFSET
Z_QUICKMAPAI4_NO_DX (pageswapargs_renderplane_offset_size+4) INDEXED_PAGE_7000_OFFSET


mov       ax, CACHEDHEIGHT_SEGMENT
mov       es, ax
xor       ax, ax
mov       di, ax  ; 0
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
; call netupdate on return.

POPA_NO_AX_OR_BP_MACRO
retf      

visplane_dirty_do_revert:
call      Z_QuickMapVisplaneRevert_BSPLocal_
jmp       done_with_visplane_revert



ENDP


; TODO: externalize this and R_ExecuteSetViewSize and its children to asm, load from binary
; todo: calculate the values here and dont store to variables.

;R_WriteBackViewConstants24_

PROC R_WriteBackViewConstants24_ FAR
PUBLIC R_WriteBackViewConstants24_ 


; set ds to cs to make code smaller?
mov      ax, cs
mov      ds, ax


ASSUME DS:R_BSP_24_TEXT


mov      ax,  word ptr ss:[_detailshift]
add      ah, OFFSET _quality_port_lookup
mov      byte ptr ds:[SELFMODIFY_detailshift_plus1_1+3 - OFFSET R_BSP24_STARTMARKER_], ah

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

mov      word ptr ds:[SELFMODIFY_BSP_detailshift_7+0 - OFFSET R_BSP24_STARTMARKER_], ax
mov      word ptr ds:[SELFMODIFY_BSP_detailshift_7+2 - OFFSET R_BSP24_STARTMARKER_], ax

; write to colfunc segment
mov      word ptr ds:[SELFMODIFY_BSP_detailshift2minus+0 - OFFSET R_BSP24_STARTMARKER_], ax
mov      word ptr ds:[SELFMODIFY_BSP_detailshift2minus+2 - OFFSET R_BSP24_STARTMARKER_], ax




; for 32 bit shifts, modify jump to jump 8 for 0 shifts, 4 for 1 shifts, 0 for 0 shifts.
; 0EBh, 006h = jmp 6

mov      ax, 006EBh
mov      word ptr ds:[SELFMODIFY_BSP_detailshift_1 - OFFSET R_BSP24_STARTMARKER_], ax
mov      word ptr ds:[SELFMODIFY_BSP_detailshift_2 - OFFSET R_BSP24_STARTMARKER_], ax
mov      word ptr ds:[SELFMODIFY_BSP_detailshift_3 - OFFSET R_BSP24_STARTMARKER_], ax
mov      word ptr ds:[SELFMODIFY_BSP_detailshift_4 - OFFSET R_BSP24_STARTMARKER_], ax
mov      word ptr ds:[SELFMODIFY_BSP_detailshift_5 - OFFSET R_BSP24_STARTMARKER_], ax


mov      al,  0
mov      word ptr ds:[SELFMODIFY_BSP_detailshift2minus_1+0 - OFFSET R_BSP24_STARTMARKER_], ax
mov      word ptr ds:[SELFMODIFY_BSP_detailshift2minus_1+2 - OFFSET R_BSP24_STARTMARKER_], ax
mov      word ptr ds:[SELFMODIFY_BSP_detailshift2minus_2+0 - OFFSET R_BSP24_STARTMARKER_], ax
mov      word ptr ds:[SELFMODIFY_BSP_detailshift2minus_2+2 - OFFSET R_BSP24_STARTMARKER_], ax

; inverse. do shifts
; d1 e0 d1 d2  = shl ax, 1; rcl dx, 1
; d1 e0 d1 d7  = shl ax, 1; rcl di, 1
; d1 e2 d1 d0  = shl dx, 1; rcl ax, 1

mov      ax, 0e0d1h 
mov      word ptr ds:[SELFMODIFY_BSP_detailshift2minus_1+0 - OFFSET R_BSP24_STARTMARKER_], ax
mov      word ptr ds:[SELFMODIFY_BSP_detailshift2minus_2+0 - OFFSET R_BSP24_STARTMARKER_], ax
mov      word ptr ds:[SELFMODIFY_BSP_detailshift_6+0 - OFFSET R_BSP24_STARTMARKER_], ax
mov      ax, 0d2d1h 
mov      word ptr ds:[SELFMODIFY_BSP_detailshift2minus_1+2 - OFFSET R_BSP24_STARTMARKER_], ax
mov      word ptr ds:[SELFMODIFY_BSP_detailshift_6+2 - OFFSET R_BSP24_STARTMARKER_], ax
mov      ax, 0d7d1h 
mov      word ptr ds:[SELFMODIFY_BSP_detailshift2minus_2+2 - OFFSET R_BSP24_STARTMARKER_], ax




jmp      done_modding_shift_detail_code
set_to_one:

; detailshift 1 case. usually involves one shift pair.
; in this case - we insert nops (nopish?) code to replace the first shift pair

; for 32 bit shifts, modify jump to jump 8 for 0 shifts, 4 for 1 shifts, 0 for 0 shifts.

; d1 f8  = sar ax, 1
mov      ax, 0f8d1h 
mov      word ptr ds:[SELFMODIFY_BSP_detailshift_7+0 - OFFSET R_BSP24_STARTMARKER_], ax

; write to colfunc segment
mov      word ptr ds:[SELFMODIFY_BSP_detailshift2minus+0 - OFFSET R_BSP24_STARTMARKER_], ax

; nop 
mov      ax, 0c089h 
mov      word ptr ds:[SELFMODIFY_BSP_detailshift_7+2 - OFFSET R_BSP24_STARTMARKER_], ax
; write to colfunc segment
mov      word ptr ds:[SELFMODIFY_BSP_detailshift2minus+2 - OFFSET R_BSP24_STARTMARKER_], ax



; 81 c3 00 00 = add bx, 0000. Not technically a nop, but probably better than two mov ax, ax?
; 89 c0       = mov ax, ax. two byte nop.

mov      ax, 0c089h

mov      word ptr ds:[SELFMODIFY_BSP_detailshift_1+0 - OFFSET R_BSP24_STARTMARKER_], ax
mov      word ptr ds:[SELFMODIFY_BSP_detailshift_1+2 - OFFSET R_BSP24_STARTMARKER_], ax
mov      word ptr ds:[SELFMODIFY_BSP_detailshift_2+0 - OFFSET R_BSP24_STARTMARKER_], ax
mov      word ptr ds:[SELFMODIFY_BSP_detailshift_2+2 - OFFSET R_BSP24_STARTMARKER_], ax
mov      word ptr ds:[SELFMODIFY_BSP_detailshift_3+0 - OFFSET R_BSP24_STARTMARKER_], ax
mov      word ptr ds:[SELFMODIFY_BSP_detailshift_3+2 - OFFSET R_BSP24_STARTMARKER_], ax
mov      word ptr ds:[SELFMODIFY_BSP_detailshift_4+0 - OFFSET R_BSP24_STARTMARKER_], ax
mov      word ptr ds:[SELFMODIFY_BSP_detailshift_4+2 - OFFSET R_BSP24_STARTMARKER_], ax
mov      word ptr ds:[SELFMODIFY_BSP_detailshift_5+0 - OFFSET R_BSP24_STARTMARKER_], ax
mov      word ptr ds:[SELFMODIFY_BSP_detailshift_5+2 - OFFSET R_BSP24_STARTMARKER_], ax

mov      word ptr ds:[SELFMODIFY_BSP_detailshift2minus_1+0 - OFFSET R_BSP24_STARTMARKER_], ax
mov      word ptr ds:[SELFMODIFY_BSP_detailshift2minus_1+2 - OFFSET R_BSP24_STARTMARKER_], ax
mov      word ptr ds:[SELFMODIFY_BSP_detailshift2minus_2+0 - OFFSET R_BSP24_STARTMARKER_], ax
mov      word ptr ds:[SELFMODIFY_BSP_detailshift2minus_2+2 - OFFSET R_BSP24_STARTMARKER_], ax
mov      word ptr ds:[SELFMODIFY_BSP_detailshift_6+0 - OFFSET R_BSP24_STARTMARKER_], ax
mov      word ptr ds:[SELFMODIFY_BSP_detailshift_6+2 - OFFSET R_BSP24_STARTMARKER_], ax

jmp      done_modding_shift_detail_code
set_to_zero:

; detailshift 0 case. usually involves two shift pairs.
; in this case - we make that first shift a proper shift

; d1 f8  = sar ax, 1
mov      ax, 0f8d1h 
mov      word ptr ds:[SELFMODIFY_BSP_detailshift_7+0 - OFFSET R_BSP24_STARTMARKER_], ax
mov      word ptr ds:[SELFMODIFY_BSP_detailshift_7+2 - OFFSET R_BSP24_STARTMARKER_], ax

; write to colfunc segment
mov      word ptr ds:[SELFMODIFY_BSP_detailshift2minus+0 - OFFSET R_BSP24_STARTMARKER_], ax
mov      word ptr ds:[SELFMODIFY_BSP_detailshift2minus+2 - OFFSET R_BSP24_STARTMARKER_], ax


; for 32 bit shifts, modify jump to jump 8 for 0 shifts, 4 for 1 shifts, 0 for 0 shifts.

; d1 e0 d1 d2   =  shl ax, 1; rcl dx, 1.
; d1 e2 d1 d0   = shl dx, 1; rcl ax, 1

mov      ax, 0E2D1h
mov      word ptr ds:[SELFMODIFY_BSP_detailshift_1+0 - OFFSET R_BSP24_STARTMARKER_], ax
mov      word ptr ds:[SELFMODIFY_BSP_detailshift_2+0 - OFFSET R_BSP24_STARTMARKER_], ax
mov      word ptr ds:[SELFMODIFY_BSP_detailshift_3+0 - OFFSET R_BSP24_STARTMARKER_], ax
mov      word ptr ds:[SELFMODIFY_BSP_detailshift_4+0 - OFFSET R_BSP24_STARTMARKER_], ax
mov      word ptr ds:[SELFMODIFY_BSP_detailshift_5+0 - OFFSET R_BSP24_STARTMARKER_], ax
mov      ax, 0D0D1h
mov      word ptr ds:[SELFMODIFY_BSP_detailshift_1+2 - OFFSET R_BSP24_STARTMARKER_], ax
mov      word ptr ds:[SELFMODIFY_BSP_detailshift_2+2 - OFFSET R_BSP24_STARTMARKER_], ax
mov      word ptr ds:[SELFMODIFY_BSP_detailshift_3+2 - OFFSET R_BSP24_STARTMARKER_], ax
mov      word ptr ds:[SELFMODIFY_BSP_detailshift_4+2 - OFFSET R_BSP24_STARTMARKER_], ax
mov      word ptr ds:[SELFMODIFY_BSP_detailshift_5+2 - OFFSET R_BSP24_STARTMARKER_], ax

; 0EBh, 006h = jmp 6
mov      ax, 006EBh
mov      word ptr ds:[SELFMODIFY_BSP_detailshift2minus_1+0 - OFFSET R_BSP24_STARTMARKER_], ax
mov      word ptr ds:[SELFMODIFY_BSP_detailshift2minus_2+0 - OFFSET R_BSP24_STARTMARKER_], ax
mov      word ptr ds:[SELFMODIFY_BSP_detailshift_6+0 - OFFSET R_BSP24_STARTMARKER_], ax


; fall thru
done_modding_shift_detail_code:






mov      al, byte ptr ss:[_detailshiftitercount]
mov      byte ptr ds:[SELFMODIFY_cmp_al_to_detailshiftitercount+1 - OFFSET R_BSP24_STARTMARKER_], al
mov      byte ptr ds:[SELFMODIFY_add_iter_to_rw_x+1 - OFFSET R_BSP24_STARTMARKER_], al
mov      byte ptr ds:[SELFMODIFY_add_detailshiftitercount+3 - OFFSET R_BSP24_STARTMARKER_], al

mov      ax, word ptr ss:[_detailshiftandval]
mov      word ptr ds:[SELFMODIFY_detailshift_and_1+2 - OFFSET R_BSP24_STARTMARKER_], ax

mov      ax, word ptr ss:[_centeryfrac_shiftright4]
mov      word ptr ds:[SELFMODIFY_sub__centeryfrac_shiftright4_lo_1+1 - OFFSET R_BSP24_STARTMARKER_], ax
mov      word ptr ds:[SELFMODIFY_sub__centeryfrac_shiftright4_lo_2+1 - OFFSET R_BSP24_STARTMARKER_], ax
mov      word ptr ds:[SELFMODIFY_sub__centeryfrac_shiftright4_lo_3+1 - OFFSET R_BSP24_STARTMARKER_], ax
mov      word ptr ds:[SELFMODIFY_sub__centeryfrac_shiftright4_lo_4+1 - OFFSET R_BSP24_STARTMARKER_], ax
mov      ax, word ptr ss:[_centeryfrac_shiftright4+2]
mov      word ptr ds:[SELFMODIFY_sub__centeryfrac_shiftright4_hi_1+1 - OFFSET R_BSP24_STARTMARKER_], ax
mov      word ptr ds:[SELFMODIFY_sub__centeryfrac_shiftright4_hi_2+1 - OFFSET R_BSP24_STARTMARKER_], ax
mov      word ptr ds:[SELFMODIFY_sub__centeryfrac_shiftright4_hi_3+1 - OFFSET R_BSP24_STARTMARKER_], ax
mov      word ptr ds:[SELFMODIFY_sub__centeryfrac_shiftright4_hi_4+1 - OFFSET R_BSP24_STARTMARKER_], ax

; ah is definitely 0... optimizable?
mov      ax, word ptr ss:[_centerx]
mov      word ptr ds:[SELFMODIFY_BSP_centerx_1+1 - OFFSET R_BSP24_STARTMARKER_], ax
mov      word ptr ds:[SELFMODIFY_BSP_centerx_2+1 - OFFSET R_BSP24_STARTMARKER_], ax

mov      word ptr ds:[SELFMODIFY_BSP_centerx_4+1 - OFFSET R_BSP24_STARTMARKER_], ax
mov      word ptr ds:[SELFMODIFY_BSP_centerx_5+1 - OFFSET R_BSP24_STARTMARKER_], ax
mov      word ptr ds:[SELFMODIFY_BSP_centerx_6+2 - OFFSET R_BSP24_STARTMARKER_], ax
mov      word ptr ds:[SELFMODIFY_BSP_centerx_7+1 - OFFSET R_BSP24_STARTMARKER_], ax
mov      word ptr ds:[SELFMODIFY_BSP_centerx_8+1 - OFFSET R_BSP24_STARTMARKER_], ax



mov      ax, COLFUNC_FUNCTION_AREA_SEGMENT
mov      es, ax

; ah is definitely 0... optimizable?
mov      ax, word ptr ss:[_centery]

mov      word ptr es:[SELFMODIFY_COLFUNC_SUBTRACT_CENTERY24_OFFSET+1 - COLFUNC_JUMPTABLE_SIZE_OFFSET], ax
 
mov      ax, word ptr ss:[_viewwidth]
mov      word ptr ds:[SELFMODIFY_BSP_viewwidth_1+1 - OFFSET R_BSP24_STARTMARKER_], ax
mov      word ptr ds:[SELFMODIFY_BSP_viewwidth_2+1 - OFFSET R_BSP24_STARTMARKER_], ax
mov      word ptr ds:[SELFMODIFY_BSP_viewwidth_3+1 - OFFSET R_BSP24_STARTMARKER_], ax
mov      word ptr ds:[SELFMODIFY_BSP_viewwidth_4+1 - OFFSET R_BSP24_STARTMARKER_], ax

mov      ax, word ptr ss:[_viewheight]
mov      word ptr ds:[SELFMODIFY_BSP_setviewheight_1+5 - OFFSET R_BSP24_STARTMARKER_], ax
mov      word ptr ds:[SELFMODIFY_BSP_setviewheight_2+1 - OFFSET R_BSP24_STARTMARKER_], ax

mov      ax,  word ptr ss:[_pspritescale]
test     ax, ax
je       pspritescale_zero_selfmodifies

mov      word ptr ds:[SELFMODIFY_BSP_pspritescale_1+1 - OFFSET R_BSP24_STARTMARKER_], ax
mov      word ptr ds:[SELFMODIFY_BSP_pspritescale_2+1 - OFFSET R_BSP24_STARTMARKER_], ax
mov      word ptr ds:[SELFMODIFY_BSP_pspritescale_3+1 - OFFSET R_BSP24_STARTMARKER_], ax
mov      al, 0BBh  ; mov bx, imm16
mov      byte ptr ds:[SELFMODIFY_BSP_pspritescale_1 - OFFSET R_BSP24_STARTMARKER_], al
mov      byte ptr ds:[SELFMODIFY_BSP_pspritescale_2 - OFFSET R_BSP24_STARTMARKER_], al
mov      byte ptr ds:[SELFMODIFY_BSP_pspritescale_3 - OFFSET R_BSP24_STARTMARKER_], 0B8h
jmp      done_with_pspritescale_zero_selfmodifies
pspritescale_zero_selfmodifies:

mov      al, 0EBh
mov      ah, (SELFMODIFY_BSP_pspritescale_1_TARGET - SELFMODIFY_BSP_pspritescale_1_AFTER)
mov      word ptr ds:[SELFMODIFY_BSP_pspritescale_1 - OFFSET R_BSP24_STARTMARKER_], ax
mov      ah, (SELFMODIFY_BSP_pspritescale_2_TARGET - SELFMODIFY_BSP_pspritescale_2_AFTER)
mov      word ptr ds:[SELFMODIFY_BSP_pspritescale_2 - OFFSET R_BSP24_STARTMARKER_], ax
mov      ah, (SELFMODIFY_BSP_pspritescale_3_TARGET - SELFMODIFY_BSP_pspritescale_3_AFTER)
mov      word ptr ds:[SELFMODIFY_BSP_pspritescale_3 - OFFSET R_BSP24_STARTMARKER_], ax

done_with_pspritescale_zero_selfmodifies:






mov      ax,  word ptr ss:[_pspriteiscale]
mov      word ptr ds:[SELFMODIFY_BSP_pspriteiscale_lo_1+1 - OFFSET R_BSP24_STARTMARKER_], ax
mov      ax,  word ptr ss:[_pspriteiscale+2]
mov      word ptr ds:[SELFMODIFY_BSP_pspriteiscale_hi_1+1 - OFFSET R_BSP24_STARTMARKER_], ax



mov      ax, ss
mov      ds, ax

;ASSUME DS:DGROUP



retf



ENDP



;R_WriteBackFrameConstants_

PROC   R_WriteBackFrameConstants_ NEAR
PUBLIC R_WriteBackFrameConstants_ 

; todo: calculate the values here and dont store to variables. (combine with setupframe etc)

; set ds to cs to make code smaller?
mov      ax, cs
mov      ds, ax

mov      ax, DRAWFUZZCOL_AREA_SEGMENT
mov      es, ax

ASSUME DS:R_BSP_24_TEXT





mov      ax, word ptr ss:[_viewz]
mov      word ptr ds:[SELFMODIFY_BSP_viewz_lo_1+1 - OFFSET R_BSP24_STARTMARKER_], ax
mov      word ptr ds:[SELFMODIFY_BSP_viewz_lo_2+2 - OFFSET R_BSP24_STARTMARKER_], ax
mov      word ptr ds:[SELFMODIFY_BSP_viewz_lo_3+2 - OFFSET R_BSP24_STARTMARKER_], ax
mov      word ptr ds:[SELFMODIFY_BSP_viewz_lo_4+2 - OFFSET R_BSP24_STARTMARKER_], ax
mov      word ptr ds:[SELFMODIFY_BSP_viewz_lo_7+2 - OFFSET R_BSP24_STARTMARKER_], ax
mov      word ptr ds:[SELFMODIFY_BSP_viewz_lo_8+2 - OFFSET R_BSP24_STARTMARKER_], ax

xchg     ax, dx  ; dx has viewz lo

mov      ax, word ptr ss:[_viewz+2]
mov      word ptr ds:[SELFMODIFY_BSP_viewz_hi_1+2 - OFFSET R_BSP24_STARTMARKER_], ax
mov      word ptr ds:[SELFMODIFY_BSP_viewz_hi_2+2 - OFFSET R_BSP24_STARTMARKER_], ax
mov      word ptr ds:[SELFMODIFY_BSP_viewz_hi_3+2 - OFFSET R_BSP24_STARTMARKER_], ax
mov      word ptr ds:[SELFMODIFY_BSP_viewz_hi_4+1 - OFFSET R_BSP24_STARTMARKER_], ax
mov      word ptr ds:[SELFMODIFY_BSP_viewz_hi_7+1 - OFFSET R_BSP24_STARTMARKER_], ax
mov      word ptr ds:[SELFMODIFY_BSP_viewz_hi_8+1 - OFFSET R_BSP24_STARTMARKER_], ax

; create 13:3 fixed point for comparison in ax

SHIFT32_MACRO_LEFT ax dx 3

mov      word ptr ds:[SELFMODIFY_BSP_viewz_13_3_1+2 - OFFSET R_BSP24_STARTMARKER_], ax
mov      word ptr ds:[SELFMODIFY_BSP_viewz_13_3_2+2 - OFFSET R_BSP24_STARTMARKER_], ax


mov      ax, word ptr ss:[_viewz_shortheight]
mov      word ptr ds:[SELFMODIFY_BSP_viewz_shortheight_1+1 - OFFSET R_BSP24_STARTMARKER_], ax
mov      word ptr ds:[SELFMODIFY_BSP_viewz_shortheight_2+1 - OFFSET R_BSP24_STARTMARKER_], ax
mov      word ptr ds:[SELFMODIFY_BSP_viewz_shortheight_3+1 - OFFSET R_BSP24_STARTMARKER_], ax
mov      word ptr ds:[SELFMODIFY_BSP_viewz_shortheight_4+1 - OFFSET R_BSP24_STARTMARKER_], ax
mov      word ptr ds:[SELFMODIFY_BSP_viewz_shortheight_5+1 - OFFSET R_BSP24_STARTMARKER_], ax

mov      al, byte ptr ss:[_extralight]
mov      byte ptr ds:[SELFMODIFY_BSP_extralight1+1 - OFFSET R_BSP24_STARTMARKER_], al
mov      byte ptr ds:[SELFMODIFY_BSP_extralight2+1 - OFFSET R_BSP24_STARTMARKER_], al
mov      byte ptr ds:[SELFMODIFY_BSP_extralight3+1 - OFFSET R_BSP24_STARTMARKER_], al

mov      al, byte ptr ss:[_fixedcolormap]

; zero these in either case.
mov      byte ptr ds:[SELFMODIFY_BSP_fixedcolormap_1+3 - OFFSET R_BSP24_STARTMARKER_], al
mov      byte ptr ds:[SELFMODIFY_BSP_fixedcolormap_5+3 - OFFSET R_BSP24_STARTMARKER_], al

cmp      al, 0
jne      do_bsp_fixedcolormap_selfmodify
do_no_bsp_fixedcolormap_selfmodify:


mov      ax, 0c089h 
mov      word ptr ds:[SELFMODIFY_BSP_fixedcolormap_2 - OFFSET R_BSP24_STARTMARKER_], ax
mov      word ptr ds:[SELFMODIFY_BSP_fixedcolormap_3 - OFFSET R_BSP24_STARTMARKER_], ax
mov      word ptr ds:[SELFMODIFY_BSP_fixedcolormap_4 - OFFSET R_BSP24_STARTMARKER_], ax
;mov      word ptr cs:[SELFMODIFY_add_wallights - OFFSET R_BSP24_STARTMARKER_], 0848ah       ; mov al, byte ptr... 

jmp      done_with_bsp_fixedcolormap_selfmodify
do_bsp_fixedcolormap_selfmodify:


;mov   ah, al
;mov   al, 0b0h
;mov   word ptr cs:[SELFMODIFY_add_wallights - OFFSET R_BSP24_STARTMARKER_], ax       ; mov al, FIXEDCOLORMAP
;mov   word ptr cs:[SELFMODIFY_add_wallights+2 - OFFSET R_BSP24_STARTMARKER_], 0c089h ; nop

; zero out the value in the walllights read which wont be updated again.
; It'll get a fixedcolormap value by default. We could alternately get rid of the loop that sets scalelightfixed to fixedcolormap and modify the instructions like above.
mov   word ptr cs:[SELFMODIFY_add_wallights+2 - OFFSET R_BSP24_STARTMARKER_], OFFSET _scalelightfixed 

mov   ax, ((SELFMODIFY_BSP_fixedcolormap_2_TARGET - SELFMODIFY_BSP_fixedcolormap_2_AFTER) SHL 8) + 0EBh
mov   word ptr ds:[SELFMODIFY_BSP_fixedcolormap_2 - OFFSET R_BSP24_STARTMARKER_], ax
mov   ah, (SELFMODIFY_BSP_fixedcolormap_3_TARGET - SELFMODIFY_BSP_fixedcolormap_3_AFTER)
mov   word ptr ds:[SELFMODIFY_BSP_fixedcolormap_3 - OFFSET R_BSP24_STARTMARKER_], ax
mov   ah, (SELFMODIFY_BSP_fixedcolormap_4_TARGET - SELFMODIFY_BSP_fixedcolormap_4_AFTER)
mov   word ptr ds:[SELFMODIFY_BSP_fixedcolormap_4 - OFFSET R_BSP24_STARTMARKER_], ax


; fall thru
done_with_bsp_fixedcolormap_selfmodify:




mov      ax, word ptr ss:[_viewx]
mov      word ptr ds:[SELFMODIFY_BSP_viewx_lo_1+1 - OFFSET R_BSP24_STARTMARKER_], ax
mov      word ptr ds:[SELFMODIFY_BSP_viewx_lo_2+2 - OFFSET R_BSP24_STARTMARKER_], ax
mov      word ptr ds:[SELFMODIFY_BSP_viewx_lo_3+1 - OFFSET R_BSP24_STARTMARKER_], ax
mov      word ptr ds:[SELFMODIFY_BSP_viewx_lo_5+1 - OFFSET R_BSP24_STARTMARKER_], ax

test     ax, ax
jne      selfmodify_viewx_lo_nonzero
mov      ax, ((SELFMODIFY_BSP_viewx_lo_4_TARGET_2 - SELFMODIFY_BSP_viewx_lo_4_AFTER) SHL 8) + 07Dh

jmp      selfmodify_viewx_done
selfmodify_viewx_lo_nonzero:
mov      ax, ((SELFMODIFY_BSP_viewx_lo_4_TARGET_1 - SELFMODIFY_BSP_viewx_lo_4_AFTER) SHL 8) + 07Dh
selfmodify_viewx_done:
mov      word ptr ds:[SELFMODIFY_BSP_viewx_lo_4 - OFFSET R_BSP24_STARTMARKER_], ax

mov      ax, word ptr ss:[_viewx+2]
mov      word ptr ds:[SELFMODIFY_BSP_viewx_hi_1+1 - OFFSET R_BSP24_STARTMARKER_], ax
mov      word ptr ds:[SELFMODIFY_BSP_viewx_hi_2+2 - OFFSET R_BSP24_STARTMARKER_], ax
mov      word ptr ds:[SELFMODIFY_BSP_viewx_hi_3+2 - OFFSET R_BSP24_STARTMARKER_], ax
mov      word ptr ds:[SELFMODIFY_BSP_viewx_hi_4+1 - OFFSET R_BSP24_STARTMARKER_], ax
mov      word ptr ds:[SELFMODIFY_BSP_viewx_hi_5+2 - OFFSET R_BSP24_STARTMARKER_], ax
mov      word ptr ds:[SELFMODIFY_BSP_viewx_hi_6+1 - OFFSET R_BSP24_STARTMARKER_], ax

mov      ax, word ptr ss:[_viewy]
mov      word ptr ds:[SELFMODIFY_BSP_viewy_lo_1+1 - OFFSET R_BSP24_STARTMARKER_], ax
mov      word ptr ds:[SELFMODIFY_BSP_viewy_lo_2+1 - OFFSET R_BSP24_STARTMARKER_], ax
mov      word ptr ds:[SELFMODIFY_BSP_viewy_lo_3+2 - OFFSET R_BSP24_STARTMARKER_], ax
mov      word ptr ds:[SELFMODIFY_BSP_viewy_lo_5+2 - OFFSET R_BSP24_STARTMARKER_], ax

cmp      ax, 0
jle      selfmodify_viewy_lo_lessthanequaltozero
mov      ax, ((SELFMODIFY_BSP_viewy_lo_4_TARGET_2 - SELFMODIFY_BSP_viewy_lo_4_AFTER) SHL 8) + 07Eh ;jle

jmp      selfmodify_viewy_done
selfmodify_viewy_lo_lessthanequaltozero:
mov      ax, ((SELFMODIFY_BSP_viewy_lo_4_TARGET_1 - SELFMODIFY_BSP_viewy_lo_4_AFTER) SHL 8) + 07Eh ;jle
selfmodify_viewy_done:
mov      word ptr ds:[SELFMODIFY_BSP_viewy_lo_4 - OFFSET R_BSP24_STARTMARKER_], ax



mov      ax, word ptr ss:[_viewy+2]
mov      word ptr ds:[SELFMODIFY_BSP_viewy_hi_1+1 - OFFSET R_BSP24_STARTMARKER_], ax
mov      word ptr ds:[SELFMODIFY_BSP_viewy_hi_2+2 - OFFSET R_BSP24_STARTMARKER_], ax
mov      word ptr ds:[SELFMODIFY_BSP_viewy_hi_3+2 - OFFSET R_BSP24_STARTMARKER_], ax
mov      word ptr ds:[SELFMODIFY_BSP_viewy_hi_4+1 - OFFSET R_BSP24_STARTMARKER_], ax
mov      word ptr ds:[SELFMODIFY_BSP_viewy_hi_5+2 - OFFSET R_BSP24_STARTMARKER_], ax
mov      word ptr ds:[SELFMODIFY_BSP_viewy_hi_6+1 - OFFSET R_BSP24_STARTMARKER_], ax


mov      ax, word ptr ss:[_viewangle_shiftright3]
mov      word ptr ds:[SELFMODIFY_set_viewanglesr3_2+1 - OFFSET R_BSP24_STARTMARKER_], ax
mov      word ptr ds:[SELFMODIFY_set_viewanglesr3_3+1 - OFFSET R_BSP24_STARTMARKER_], ax
mov      word ptr ds:[SELFMODIFY_set_viewanglesr3_4+1 - OFFSET R_BSP24_STARTMARKER_], ax
mov      word ptr ds:[SELFMODIFY_set_viewanglesr3_5+2 - OFFSET R_BSP24_STARTMARKER_], ax

add      ah, 8
mov      word ptr ds:[SELFMODIFY_set_viewanglesr3_1+1 - OFFSET R_BSP24_STARTMARKER_], ax


mov      ax, word ptr ss:[_viewangle_shiftright1]
mov      word ptr ds:[SELFMODIFY_set_viewanglesr1_1+1 - OFFSET R_BSP24_STARTMARKER_], ax
mov      word ptr ds:[SELFMODIFY_set_viewanglesr1_2+1 - OFFSET R_BSP24_STARTMARKER_], ax
mov      word ptr ds:[SELFMODIFY_set_viewanglesr1_3+1 - OFFSET R_BSP24_STARTMARKER_], ax

mov      ax, word ptr ss:[_viewangle]
mov      word ptr ds:[SELFMODIFY_BSP_viewangle_lo_1+2 - OFFSET R_BSP24_STARTMARKER_], ax
mov      word ptr ds:[SELFMODIFY_BSP_viewangle_lo_2+2 - OFFSET R_BSP24_STARTMARKER_], ax
mov      word ptr ds:[SELFMODIFY_BSP_viewangle_lo_3+1 - OFFSET R_BSP24_STARTMARKER_], ax
mov      word ptr ds:[SELFMODIFY_BSP_viewangle_lo_4+1 - OFFSET R_BSP24_STARTMARKER_], ax
mov      ax, word ptr ss:[_viewangle+2]
mov      word ptr ds:[SELFMODIFY_BSP_viewangle_hi_1+2 - OFFSET R_BSP24_STARTMARKER_], ax
mov      word ptr ds:[SELFMODIFY_BSP_viewangle_hi_2+2 - OFFSET R_BSP24_STARTMARKER_], ax
mov      word ptr ds:[SELFMODIFY_BSP_viewangle_hi_3+2 - OFFSET R_BSP24_STARTMARKER_], ax
mov      word ptr ds:[SELFMODIFY_BSP_viewangle_hi_4+2 - OFFSET R_BSP24_STARTMARKER_], ax

mov      ax, word ptr ss:[_fieldofview]
mov      word ptr ds:[SELFMODIFY_BSP_fieldofview_1+1 - OFFSET R_BSP24_STARTMARKER_], ax
mov      word ptr ds:[SELFMODIFY_BSP_fieldofview_2+1 - OFFSET R_BSP24_STARTMARKER_], ax
mov      word ptr ds:[SELFMODIFY_BSP_fieldofview_3+1 - OFFSET R_BSP24_STARTMARKER_], ax
mov      word ptr ds:[SELFMODIFY_BSP_fieldofview_4+1 - OFFSET R_BSP24_STARTMARKER_], ax
mov      word ptr ds:[SELFMODIFY_BSP_fieldofview_5+1 - OFFSET R_BSP24_STARTMARKER_], ax
mov      word ptr ds:[SELFMODIFY_BSP_fieldofview_6+1 - OFFSET R_BSP24_STARTMARKER_], ax
mov      word ptr ds:[SELFMODIFY_BSP_fieldofview_7+1 - OFFSET R_BSP24_STARTMARKER_], ax
mov      word ptr ds:[SELFMODIFY_BSP_fieldofview_8+1 - OFFSET R_BSP24_STARTMARKER_], ax

mov      ax, word ptr ss:[_clipangle]
mov      word ptr ds:[SELFMODIFY_BSP_clipangle_1+1 - OFFSET R_BSP24_STARTMARKER_], ax
mov      word ptr ds:[SELFMODIFY_BSP_clipangle_2+1 - OFFSET R_BSP24_STARTMARKER_], ax
mov      word ptr ds:[SELFMODIFY_BSP_clipangle_3+1 - OFFSET R_BSP24_STARTMARKER_], ax
mov      word ptr ds:[SELFMODIFY_BSP_clipangle_4+2 - OFFSET R_BSP24_STARTMARKER_], ax
mov      word ptr ds:[SELFMODIFY_BSP_clipangle_5+1 - OFFSET R_BSP24_STARTMARKER_], ax
mov      word ptr ds:[SELFMODIFY_BSP_clipangle_6+1 - OFFSET R_BSP24_STARTMARKER_], ax
mov      word ptr ds:[SELFMODIFY_BSP_clipangle_7+2 - OFFSET R_BSP24_STARTMARKER_], ax
neg      ax
mov      word ptr ds:[SELFMODIFY_BSP_clipangle_8+1 - OFFSET R_BSP24_STARTMARKER_], ax




; get whole dword at the end here.
mov      ax, word ptr ss:[_destview]
mov      word ptr ds:[SELFMODIFY_BSP_add_destview_offset+1 - OFFSET R_BSP24_STARTMARKER_], ax

mov      ax, ss
mov      ds, ax
;ASSUME DS:DGROUP

mov      ax, COLFUNC_FUNCTION_AREA_SEGMENT
mov      es, ax
mov      ax, word ptr ds:[_destview+2]
mov      word ptr es:[SELFMODIFY_COLFUNC_SET_DESTVIEW_SEGMENT24_OFFSET+1-COLFUNC_JUMPTABLE_SIZE_OFFSET], ax



ret

ENDP


PROC R_BSP24_ENDMARKER_
PUBLIC R_BSP24_ENDMARKER_
ENDP

ENDS



END
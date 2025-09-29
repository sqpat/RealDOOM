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



.DATA




.CODE



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


return_0:

xor   ax, ax
cwd

ret  


inputs_not_zero:

test  dx, dx
js   x_is_negative

x_is_positive:
test  cx, cx

js   y_is_negative
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

PROC FastDiv3232_RPTA_

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


;R_PointToAngle2_

PROC R_PointToAngle2_ FAR
PUBLIC R_PointToAngle2_ 


;uint32_t __far R_PointToAngle2 ( fixed_t_union	x1, fixed_t_union	y1, fixed_t_union	x2, fixed_t_union	y2 ) {	
;    return R_PointToAngle (x2, y2);
;	x2.w -= x1.w;
;	y2.w -= y1.w;

; todo swap param order?

push      si
push      bp
mov       bp, sp
les       si, dword ptr [bp + 8]
xchg      ax, si
sub       ax, si
mov       si, es
sbb       si, dx
mov       dx, si
les       si, dword ptr [bp + 0Ch]
sub       si, bx
mov       bx, si
mov       si, es
sbb       si, cx
mov       cx, si

call      R_PointToAngle_
pop       bp
pop       si
retf      8

ENDP



;R_PointToAngle2_16_

PROC R_PointToAngle2_16_ FAR
PUBLIC R_PointToAngle2_16_ 

;uint32_t __far R_PointToAngle2_16 (  int16_t	x2, int16_t	y2 ) {	
;	fixed_t_union x2fp, y2fp;
;	x2fp.h.intbits = x2;
;	y2fp.h.intbits = y2;
;	x2fp.h.fracbits = 0;
;	y2fp.h.fracbits = 0;
;    return R_PointToAngle (x2fp, y2fp);

push      bx
push      cx
mov       cx, dx
xchg      ax, dx
xor       ax, ax
mov       bx, ax
call      R_PointToAngle_
pop       cx
pop       bx
retf      
ENDP

;R_SetViewSize_

PROC R_SetViewSize_ FAR
PUBLIC R_SetViewSize_ 


;void __far R_SetViewSize ( uint8_t		blocks, uint8_t		detail ) {
;    setsizeneeded = true;
;    setblocks = blocks;
;    pendingdetail = detail;
;}

; todo inline and move vars to fixeddata

mov       byte ptr ds:[_setblocks], al
xor       dh, dh
mov       byte ptr ds:[_setsizeneeded], 1
mov       word ptr ds:[_pendingdetail], dx
retf      

ENDP



;void __far R_VideoErase (uint16_t ofs, int16_t count ) 
;R_VideoErase_

PROC R_VideoErase_ NEAR
PUBLIC R_VideoErase_ 



PUSHA_NO_AX_OR_BP_MACRO
SHIFT_MACRO shr   ax 2 ; ofs >> 2
SHIFT_MACRO shr   dx 2 ; count = count / 4
;dec   dx          ; offset/di/si by one starting
;add   ax, dx      ; for backwards iteration starting from count
;inc   dx
xchg  ax, si
mov   cx, dx

;	outp(SC_INDEX, SC_MAPMASK);
mov   dx, SC_INDEX
mov   al, SC_MAPMASK
out   dx, al

;    outp(SC_INDEX + 1, 15);
inc   dx
mov   al, 00Fh
out   dx, al

;    outp(GC_INDEX, GC_MODE);
mov   dx, GC_INDEX
mov   al, GC_MODE
out   dx, al

;    outp(GC_INDEX + 1, inp(GC_INDEX + 1) | 1);
inc   dx
in    al, dx
or    al, 1
out   dx, al

;    dest = (byte __far*)(destscreen.w + (ofs >> 2));
;	source = (byte __far*)0xac000000 + (ofs >> 2);


les   di, dword ptr ds:[_destscreen]
add   di, si    ; es:di = destscreen + ofs>>2

;    while (--countp >= 0) {
;		dest[countp] = source[countp];
;    }


mov   ax, 0AC00h;
mov   ds, ax        ; ds:si is AC00:ofs>>2
; es set above

; movsw does not seem to work
;shr   cx, 1
;rep movsw 
;adc   cx, cx
rep movsb 

mov   ax, ss
mov   ds, ax

;	outp(GC_INDEX, GC_MODE);
mov   dx, GC_INDEX
mov   al, GC_MODE
out   dx, al

;    outp(GC_INDEX + 1, inp(GC_INDEX + 1)&~1);
inc   dx
in    al, dx
and   al, 0FEh
out   dx, al

POPA_NO_AX_OR_BP_MACRO
ret  

ENDP


;R_DrawViewBorder_

; could probably be improved a small amount wrt screenwidth constants and viewheight
; but dont care much

PROC R_DrawViewBorder_ NEAR
PUBLIC R_DrawViewBorder_ 


cmp   word ptr ds:[_scaledviewwidth], SCREENWIDTH
jne   view_border_exists
ret  
view_border_exists:
PUSHA_NO_AX_OR_BP_MACRO
mov   ax, word ptr ds:[_scaledviewwidth]

mov   bx, SCREENHEIGHT - SBARHEIGHT
sub   bx, word ptr ds:[_viewheight]
shr   bx, 1


mov   di, SCREENWIDTH
sub   di, ax
mov   al, SCREENWIDTHOVER2
mul   bl
sal   ax, 1
mov   si, ax

sar   di, 1
mov   cx, si
add   cx, di
xor   ax, ax
mov   dx, cx
;    // copy top and one line of left side 

call  R_VideoErase_
mov   ax, word ptr ds:[_viewheight]
add   ax, bx

mov   ah, SCREENWIDTHOVER2
mul   ah
sal   ax, 1

mov   bx, SCREENWIDTH

mov   dx, cx
add   si, bx
mov   cx, word ptr ds:[_viewheight]

sub   ax, di
sub   si, di

;    // copy one line of right side and bottom 

call  R_VideoErase_


;    // copy sides using wraparound 

sal   di, 1

loop_erase_border:
mov   dx, di
mov   ax, si
call  R_VideoErase_
add   si, bx
loop  loop_erase_border
POPA_NO_AX_OR_BP_MACRO
ret



ENDP


END

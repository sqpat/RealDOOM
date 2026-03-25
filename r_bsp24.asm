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




SEGMENT R_BSP_24_TEXT USE16 PARA PUBLIC 'CODE'
ASSUME  CS:R_BSP_24_TEXT

PROC   R_BSP24_STARTMARKER_
PUBLIC R_BSP24_STARTMARKER_
ENDP

ANG90_HIGHBITS =		04000h
ANG180_HIGHBITS =    08000h

MAX_VISSPRITES_ADDRESS = ((SIZE VISSPRITE_T) * MAXVISSPRITES) + _vissprites ; 0BE70h

MOV_AX_IMM16_OPCODE = 0B8h
MOV_AL_IMM8_OPCODE = 0B0h
MOV_CL_IMM8_OPCODE = 0B1h
DS_PREFIX_OPCODE = 03Eh
JMP_SHORT_REL8_OPCODE = 0EBh

; COLFUNC TYPES (work in progress)
; 0 = regular draw, texture can loop
; 1 = texture cannot loop, no AND 7Fh per texel coord calcualtion

; cs:0n00h contains call table for that colfunc type
; _colfunc_jump_lookup_segments[n] is jump table for that colfunct type
; _colfunc_lookup_segments


; entries at 0, 4, 0x80, 0x84.

; 0x80 on means noloop
;  0x6 on means stretch

_COLFUNC_SELFMODIFY_LOOKUPTABLE:
public _COLFUNC_SELFMODIFY_LOOKUPTABLE
; normal ; 12 bytes per
dw DRAWCOL_NORMAL_STRETCH_OFFSET_BSP, DRAWCOL_OFFSET_BSP
_COLFUNC_JUMP_LOOKUP_INSTR:
db 001h, 0D6h, 0D1h, 0E6h  ; 12 
_COLFUNC_JUMP_LOOKUP_INSTR_TOPBOT:
db 001h, 0F2h, 0D1h, 0E2h ; 12



R_CHECKBBOX_SWITCH_JMP_TABLE:
; jmp table for switch block.... 

dw R_CBB_SWITCH_CASE_00, R_CBB_SWITCH_CASE_01, R_CBB_SWITCH_CASE_02, R_CBB_SWITCH_CASE_03
dw R_CBB_SWITCH_CASE_04, R_CBB_SWITCH_CASE_05, R_CBB_SWITCH_CASE_06, R_CBB_SWITCH_CASE_07
dw R_CBB_SWITCH_CASE_08, R_CBB_SWITCH_CASE_09, R_CBB_SWITCH_CASE_10


_pagesegments:

dw 00000h, 00400h, 00800h, 00C00h
dw 01000h, 01400h, 01800h, 01C00h
;dw 02000h, 02400h

_selfmodify_lookup_markfloor:
dw ((SELFMODIFY_BSP_markfloor_1_TARGET_TWOSIDED - SELFMODIFY_BSP_markfloor_1_AFTER_TWOSIDED) SHL 8) + 0EBh
dw ((SELFMODIFY_BSP_markfloor_2_TARGET_TWOSIDED - SELFMODIFY_BSP_markfloor_2_AFTER_TWOSIDED) SHL 8) + 0EBh
dw 04940h
dw 04097h 
_selfmodify_lookup_markceiling:
db 0E9h, 0 ; jmp 
dw ((SELFMODIFY_BSP_markceiling_1_TARGET_TWOSIDED - SELFMODIFY_BSP_markceiling_1_AFTER_TWOSIDED) SHL 8) + 0EBh
db 0B8h, 0   ; mov ax, imm16
dw 001B2h


; todo 256 entry table with shift 4 and min/max etc logic baked in
base_product = OFFSET _scalelight


_mul48lookup_with_scalelight_with_minusone_offset:
   dw base_product
_mul48lookup_with_scalelight:
REPT 16
   dw base_product
   base_product = base_product + 48
ENDM
   base_product = base_product - 48
   dw base_product ; for overflow cases...
   dw base_product ; for overflow cases...
   dw base_product ; for overflow cases...

; todo default valuess

_segloopheightvalcache:
db 0, 0
_segloopprevlookup:
dw 0, 0
_segloopnextlookup:
dw 0, 0
_seglooptexrepeat:
db 0, 0

; 12 bytes...

;_segloopcachedbasecol =             _NULL_OFFSET + 00058h
;_cachedsegmenttex =                 _NULL_OFFSET + 0005Ch


; todo use
dw 0, 0, 0, 0, 0


BEOFRE_COLFUNC_LOOKUP:
public  BEOFRE_COLFUNC_LOOKUP
; 080h here

; segment aligned
ALIGN 128
_COLFUNC_SELFMODIFY_LOOKUPTABLE_SECOND_HALF:
public _COLFUNC_SELFMODIFY_LOOKUPTABLE_SECOND_HALF
; noloop ; 10 bytes per
; noloopstretch ; 10 bytes per
dw DRAWCOL_NOLOOP_STRETCH_OFFSET_BSP, DRAWCOL_NOLOOP_OFFSET_BSP

db 0D1h, 0E6h, 001h, 0D6h  ; 10
db 0D1h, 0E2h, 001h, 0F2h ; 10

ALIGN_MACRO
COLFUNC_shiftmul_selfmodify_target_lookup_mid:
dw OFFSET SELFMODIFY_set_pixel_count_shift_mul,      0  ; overwritten with BSP_CODE_SEGMENT
COLFUNC_shiftmul_selfmodify_target_lookup_top:
dw OFFSET SELFMODIFY_set_pixel_count_shift_mul_top,  0  ; overwritten with BSP_CODE_SEGMENT
COLFUNC_shiftmul_selfmodify_target_lookup_bot:
dw OFFSET SELFMODIFY_set_pixel_count_shift_mul_bot,  0  ; overwritten with BSP_CODE_SEGMENT


_lastbasexscale:
public _lastbasexscale ; IF THIS MOVES, UPDATE _BASEXSCALE_OFFSET_R_BSP in DEFS.INC
_basexscale:
PUBLIC _basexscale  ; todo this has to be constant across variants?
dw 0F0F0h, 0F0F0h
_lastbaseyscale:
dw 0F0F0h, 0F0F0h
_lastviewx:
dw 0F0F0h, 0F0F0h
_lastviewy:
dw 0F0F0h, 0F0F0h
_lastviewz_shortangle:
dw 0F0F0h  ; 16 bit?
_lastviewz:
dw 0F0F0h, 0F0F0h

_lastviewangle:
dw 0F0F0h, 0F0F0h

_lastfixedcolormap:
db 0F0h  ; force selfmodify frame one
_lastskyflatnum:
db 0F0h  ; force selfmodify frame one
_lastextralight:
db 0F0h

ALIGN 16

OFFSET_FLOORCLIP:
public OFFSET_FLOORCLIP
_floorclip:
REPT SCREENWIDTH ; 320
    db 0
ENDM

OFFSET_CEILINGCLIP:
public OFFSET_CEILINGCLIP
_ceilingclip:
public _ceilingclip
REPT SCREENWIDTH ; 320
    db 0
ENDM


; keep these two in order
_ceilingplaneindex:
dw 0FFFFh
_floorplaneindex:
dw 0FFFFh

_frontsector:
dw 0FFFFh, SECTORS_SEGMENT
_backsector:
dw 0FFFFh, SECTORS_SEGMENT

_ceiltop:
dw 0FFFFh, SECTORS_SEGMENT
_floortop:
dw 0FFFFh, SECTORS_SEGMENT

_ceilphyspage:
db 00
_floorphyspage:
db 00

ALIGN_MACRO
DEFAULT_DRAWSEG_T:
dw MAXSHORT, MINSHORT, OFFSET_SCREENHEIGHTARRAY, OFFSET_NEGONEARRAY, NULL_TEX_COL
db SIL_BOTH

_visplanedirty:
db 1

_maskedtexture_bsp:
db 0

ALIGN_MACRO

_lastopening:
dw 0

_maskedtexturecol_bsp:
dw 0, OPENINGS_SEGMENT

_ds_p_bsp:
dw 0, DRAWSEGS_BASE_SEGMENT

_cs_pixhigh:
dw 0
_cs_pixlow:
dw 0
_cs_topfrac_lo:
dw 0
_cs_botfrac_lo:
dw 0

; 0AAh

; shoving some small functions in here since w ehave to pad to 0100h for the next jump table



PUSHA_BSP_BOTTOP_MACRO MACRO

IF COMPISA GE COMPILE_186
	pusha
ELSE	
   push   ax
   push   dx
   push   si
   push   di
   push   bx
ENDIF
ENDM



POPA_BSP_BOTTOP_MACRO MACRO

IF COMPISA GE COMPILE_186
	popa
   xchg   ax, di
ELSE	
   pop    bx
   pop    ax
   pop    si
   pop    dx
   pop    di

ENDIF
ENDM




;R_ScaleFromGlobalAngle_
ALIGN_MACRO
PROC   R_ScaleFromGlobalAngle_ NEAR ; todo needs another look for sure
PUBLIC R_ScaleFromGlobalAngle_ 


push  di

; input ax = visangle_shift3

;    anglea = MOD_FINE_ANGLE(FINE_ANG90 + (visangle_shift3 - viewangle_shiftright3));
;    angleb = MOD_FINE_ANGLE(FINE_ANG90 + (visangle_shift3) - rw_normalangle);

add   ah, (FINE_ANG90 SHR 8)   ; 9 
mov   bx, ax      ; copy input
SELFMODIFY_sub_rw_normal_angle_1:
sub   ax, 01000h
SELFMODIFY_set_viewanglesr3_5:
sub   bx, 01000h  ; 


and   bh, 01Fh
and   ah, 01Fh

xchg  ax, si   ; si holds angleB

; bx = anglea
; si = angleb



;    den = FixedMulTrig(FINE_SINE_ARGUMENT, anglea, rw_distance);
 
; call FixedMulTrigSine_BSPLocal_

; inlined FixedMulTrigNoShiftSine_BSPLocal_

SHL  BX, 1

MOV  DX, FINESINE_SEGMENT
MOV  ES, DX
MOV  BX, WORD PTR ES:[BX]

SELFMODIFY_get_rw_distance_lo_1:
mov   ax, 01000h

MUL  BX        ; AX * BX

SELFMODIFY_get_rw_distance_hi_1:
public SELFMODIFY_get_rw_distance_hi_1
mov  AX, 01000h
MOV  CX, DX    ; CX stores high result as low word
MUL  BX        ; AX*CX
ADD  AX, CX    ; add low word
ADC  DX, 0    ; add high word



;    num.w = FixedMulTrig(FINE_SINE_ARGUMENT, angleb, projection.w)<<detailshift.b.bytelow;
 
;call FixedMulTrig16_
; inlined  16 bit times sine value
xchg ax, bx  ; 
mov  cx, dx  ; result to cx:bx


sal  si, 1   ; word lookup 0-3FFFh

; ES still FINESINE_SEGMENT
lods word ptr es:[si]   ;mov  ax, word ptr es:[di] ; lookup SINE


;  dx:ax holds sine lookup
;  cx:bx is den

SELFMODIFY_BSP_centerx_1:
mov   si, 01000h  ; note high byte always 0

MUL  SI       ; AX*CX


; cx:bx had den
; dx:ax has num

SELFMODIFY_BSP_detailshift2minus_1:
shl   ax, 1
rcl   dx, 1
shl   ax, 1
rcl   dx, 1



; cx:bx had den
; dx:ax has num

;    if (den > num >> 16)
;    if (den > num.h.intbits) {

; annoying - we have to account for sign!
; is there a cleaner way?

mov    di, dx
xor    di, cx   ; different signs?
js     figure_out_sign_return  ; different bit 15s

test   cx, cx
jns    two_positives

two_negatives:
neg    dx
neg    ax
adc    dx, 0
neg    cx
neg    bx
adc    cx, 0

two_positives:


;test  cx, cx
jnz   do_divide ; definitely larger than dx if nonzero..

; cx is zero... do fast divide.

cmp   dx, bx
jae   return_maxvalue

div   bx
cmp   ax, 040h
jae   return_maxvalue
xchg  ax, cx ; cx, known zero into ax, store high
div   bx
mov   dx, cx ; restore high.
pop   di
ret


ALIGN_MACRO
return_maxvalue:
; rare occurence
mov   dx, 040h
xor   ax, ax
pop   di
ret

ALIGN_MACRO
figure_out_sign_return:
test  cx, cx
js    return_maxvalue
return_minvalue:
; super duper rare case. actually never caught it happening.
mov   ax, 0100h
cwd
pop   di
ret
ALIGN_MACRO

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
ret


ENDP



ALIGN_MACRO
octant_6:
jcxz  continue_check_octant_6
octant_6_do_divide:
call FastDiv3232_shift_3_8_
jnc   octant_6_out_of_bounds

mov   es, word ptr ds:[_tantoangle_segment]
SHIFT_MACRO shl ax 2
xchg  ax, bx
les   ax, dword ptr es:[bx]
mov   dx, es
add   dx, 0c000h

ret  



ALIGN_MACRO
continue_check_octant_6:
cmp   bx, 0200h
jae   octant_6_do_divide
octant_6_out_of_bounds:
mov   dx, 0e000h
xor   ax, ax

ret  

ALIGN_MACRO
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
jz    continue_check_octant_7


octant_7_do_divide:

; swap params. y over x not x over y
xchg ax, bx
xchg dx, cx

call FastDiv3232_shift_3_8_

jnc   octant_7_out_of_bounds
mov   es, word ptr ds:[_tantoangle_segment]
SHIFT_MACRO shl ax 2
xchg  ax, bx
les   ax, dword ptr es:[bx]
mov   dx, es
neg   dx
neg   ax
sbb   dx, 0

ret  
ALIGN_MACRO
continue_check_octant_7:
cmp   ax, 0200h
jae   octant_7_do_divide
octant_7_out_of_bounds:
mov   dx, 0e000h
xor   ax, ax

ret  

ALIGN_MACRO

; params cx, dx. ax/bx get zeroed/clobbered.
PROC R_PointToAngle16_ NEAR


; ax pre negged, dx pre carried
; bx pre negged, cx pre carried

SELFMODIFY_BSP_viewy_lo_5:
mov  bx, 01000h
SELFMODIFY_BSP_viewy_hi_5:
sub  cx, 01000h
SELFMODIFY_BSP_viewx_lo_5:
mov  ax, 01000h
SELFMODIFY_BSP_viewx_hi_5:
sub  dx, 01000h

; FALL THROUGH
;call R_PointToAngle_
;ret  

ENDP


;R_PointToAngle_



ALIGN_MACRO
PROC R_PointToAngle_ NEAR  ;todo needs another look

; inputs:
; DX:AX = x  (32 bit fixed pt 16:16)
; CX:BX = y  (32 bit fixed pt 16:16)

; places to improve -
; 1.default branches taken. count branches taken and modify to optimize

;	x.w -= viewx.w;
;	y.w -= viewy.w;

; idea: self modify code, change this to constants per frame.

; ignore zero inputs case



; todo: come up with a way to branchlessly determine octant via xors, shifts, etc.
; octant ends up in si or something. then do a jmp table.

; carry dx op from before call
;test  dx, dx 
js   x_is_negative

x_is_positive:
test  cx, cx

js   y_is_negative
x_and_y_positive:

cmp   dx, cx
jg    octant_0

jne   octant_1
cmp   ax, bx
jbe   octant_1


octant_0:
test  dx, dx

;	if (x.w < 512)

jz    continue_check_octant_0
octant_0_do_divide:
;x_is_negative
xchg ax, bx
xchg dx, cx
call FastDiv3232_shift_3_8_
jnc   octant_0_out_of_bounds

mov   es, word ptr ds:[_tantoangle_segment]
SHIFT_MACRO shl ax 2
xchg  ax, bx
les   ax, dword ptr es:[bx]
mov   dx, es
ret  

ALIGN_MACRO
continue_check_octant_0:
cmp   ax, 0200h
jae   octant_0_do_divide
octant_0_out_of_bounds:
mov   dx, 02000h
xor   ax, ax

ret  


ALIGN_MACRO
octant_1:
jcxz   continue_check_octant_1
octant_1_do_divide:
call FastDiv3232_shift_3_8_
jnc   octant_1_out_of_bounds
mov   es, word ptr ds:[_tantoangle_segment]
SHIFT_MACRO shl ax 2
xchg  ax, bx
mov   ax, 0ffffh
les   bx, dword ptr es:[bx]
sub   ax, bx
mov   dx, 03fffh
mov   bx, es
sbb   dx, bx

ret  

ALIGN_MACRO
continue_check_octant_1:

cmp   bx, 0200h
jae   octant_1_do_divide
octant_1_out_of_bounds:
mov   ax, 0ffffh
mov   dx, 01fffh
ret  





ALIGN_MACRO
x_is_negative:

;		x.w = -x.w;


test  cx, cx
jns   y_is_positive_x_neg
js    y_is_negative_x_neg
y_is_positive_x_neg:
neg   dx
neg   ax
sbb   dx, 0

cmp   dx, cx
jg    octant_3
jne   octant_2
cmp   ax, bx
jbe   octant_2

octant_3:
test  dx, dx
jz    continue_check_octant_3
octant_3_do_divide:
xchg dx, cx
xchg ax, bx
call FastDiv3232_shift_3_8_
jnc   octant_3_out_of_bounds
mov   es, word ptr ds:[_tantoangle_segment]
SHIFT_MACRO shl ax 2
xchg  ax, bx
mov   ax, 0ffffh
les   bx, dword ptr es:[bx]
sub   ax, bx
mov   dx, 07fffh
mov   bx, es
sbb   dx, bx

ret  
ALIGN_MACRO
continue_check_octant_3:
cmp   ax, 0200h
jae   octant_3_do_divide
octant_3_out_of_bounds:
mov   ax, 0ffffh
mov   dx, 05fffh
ret  

ALIGN_MACRO
octant_2:

jcxz  continue_check_octant_2
octant_2_do_divide:

call FastDiv3232_shift_3_8_
jnc   octant_2_out_of_bounds
mov   es, word ptr ds:[_tantoangle_segment]
SHIFT_MACRO shl ax 2
xchg  ax, bx
les   ax, dword ptr es:[bx]
mov   dx, es
add   dx, 04000h

ret  

ALIGN_MACRO
continue_check_octant_2:
cmp   ax, 0200h
jae   octant_2_do_divide
octant_2_out_of_bounds:
mov   dx, 06000h
xor   ax, ax
ret  

ALIGN_MACRO
y_is_negative_x_neg:

neg   dx
neg   ax
sbb   dx, 0

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
jz    continue_check_octant_4

octant_4_do_divide:
xchg dx, cx
xchg ax, bx
call FastDiv3232_shift_3_8_
jnc   octant_4_out_of_bounds

mov   es, word ptr ds:[_tantoangle_segment]
SHIFT_MACRO shl ax 2
xchg  ax, bx
les   ax, dword ptr es:[bx]
mov   dx, es
add   dx, 08000h

ret  
ALIGN_MACRO
continue_check_octant_4:
cmp   ax, 0200h
jae   octant_4_do_divide
octant_4_out_of_bounds:
mov   dx, 0a000h
xor   ax, ax

ret  



ALIGN_MACRO
octant_5:
jcxz  continue_check_octant_5
octant_5_do_divide:

call FastDiv3232_shift_3_8_
jnc   octant_5_out_of_bounds
mov   es, word ptr ds:[_tantoangle_segment]
SHIFT_MACRO shl ax 2
xchg  ax, bx
mov   ax, 0ffffh
les   bx, dword ptr es:[bx]
sub   ax, bx
mov   dx, 0BFFFh
mov   bx, es
sbb   dx, bx

ret  
ALIGN_MACRO

continue_check_octant_5:
cmp   ax, 0200h
jae   octant_5_do_divide
octant_5_out_of_bounds:
mov   ax, 0ffffh
mov   dx, 09fffh
ret  ; this was a bad return?


ENDP




;   
; basically, shift numerator left 16 and divide
; DX:AX:00 / CX:BX

; destroys si/di internally, outer scope must push/pop

ALIGN_MACRO
PROC   div48_32_BSPLocal_ NEAR ; fairly optimized i think
PUBLIC div48_32_BSPLocal_ 


; di:si get shifted cx:bx
push  di

XOR SI, SI ; zero this out to get high bits of numhi

; default branch taken 314358 vs 126885


test ch, ch
jnz shift_bits
; shift a whole byte immediately

xchg  dh, cl  ; ch was 0
mov   si, cx  ; si low got dh. cl value unneeded

mov   cl, bh
mov   bh, bl
mov   bl, ch  ; bx is set. bl is 0
add   ch, dh  ; cx is set. set signed with ch + old cl

mov   dh, dl  ; 
mov   dl, ah  ; dx set.
mov   ah, al  
mov   al, bl  ; ax set. al is set as 0

shift_bits:


JS  skip_shifting

; less than a byte to shift
; shift until MSB is 1

SAL BX, 1
RCL CX, 1
JO done_shifting  
SAL AX, 1
RCL DX, 1
RCL SI, 1

SAL BX, 1
RCL CX, 1
JO done_shifting  
SAL AX, 1
RCL DX, 1
RCL SI, 1

SAL BX, 1
RCL CX, 1
JO done_shifting  
SAL AX, 1
RCL DX, 1
RCL SI, 1

SAL BX, 1
RCL CX, 1
JO done_shifting  
SAL AX, 1
RCL DX, 1
RCL SI, 1

SAL BX, 1
RCL CX, 1
JO done_shifting  
SAL AX, 1
RCL DX, 1
RCL SI, 1

SAL BX, 1
RCL CX, 1
JO done_shifting  
SAL AX, 1
RCL DX, 1
RCL SI, 1

SAL BX, 1
RCL CX, 1

done_shifting:
SAL AX, 1
RCL DX, 1
RCL SI, 1






; store this

; we overshifted by one and caught it in the carry bit. lets shift back right one.

skip_shifting:
; bx is not 0 often enough here to optimize with bx check (unless we get bx zero flag check for free)


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

test  dx, dx
jnz   do_normal_div
; dx is zero, not too uncommon.
;  first div result is trivial to calculate. result is 0 or 1 
; and we can inline the next half of the function in those cases

; note: i implemented a bx = 0 case checker and it was not faster, 
; because bx being 0 is fairly rare and the branch check itself
;  didnt make up for the fast div

xchg  ax, dx   
cmp   dx, cx
jae   div_1_result_1
div_1_result_0:
; todo: inline the whole rest of the function here.

mov   es, ax ; zero
mov   si, dx
xchg  ax, di

; qhat = 0
; c1   = 0
; rhat = si


jmp   continue_to_second_div


ALIGN_MACRO
div_1_result_1:
; qhat = 1
; rhat = si
; c1 = bx
; c2 = rhat:num1

; i dont think the estimate can be wrong here. no need to check rhat etc.
; if rhat nonzero then estimate is good


inc   ax
sub   dx, cx
mov   si, dx					; si stores rhat
mov   es, ax ; one
xchg  ax, di
;jz    further_check_c1_c2


jmp   continue_to_second_div



;	divresult.wu = DIV3216RESULTREMAINDER(numhi.wu, den1);
; DX:AX = numhi.wu

ALIGN_MACRO
do_normal_div:

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

continue_to_second_div:

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

ALIGN_MACRO
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

ALIGN_MACRO
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




ALIGN_MACRO
continue_checking_q1:

test  ax, ax
jz    q1_ready

;ja    check_c1_c2_diff
;; rare codepath! 

cmp   ax, di
jbe   q1_ready

check_c1_c2_diff:
;sub   ax, di
sub   dx, si
cmp   dx, cx
; these branches havent been tested but this is a super rare codepath
ja    qhat_subtract_2  
je    compare_low_word

qhat_subtract_1:
mov ax, es
dec ax
mov es, ax
jmp q1_ready

ALIGN_MACRO
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

ALIGN_MACRO
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
ALIGN_MACRO
adjust_for_overflow_again:

sub   ax, cx
sbb   dx, di

div   cx
; ax has its result...

pop   di
ret 

ENDP



ALIGN_MACRO
do_quick_return_whole:
  xor   ax, ax
  mov   dx, 08000h

  ret

ALIGN_MACRO
PROC   FixedDivWholeA_BSPLocal_   NEAR ; fairly optimized i think TODO make 386 version
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

ALIGN_MACRO
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

ALIGN_MACRO
PROC div48_32_whole_BSPLocal_ NEAR ; fairly optimized i think

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

; todo unsure if this is worth it
;test bx, bx                ; rcr does not set zero flag, lame!
;jz  do_simple_div_after_all_whole  ; we can divide by 16 bits after all?





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

ALIGN_MACRO
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

ALIGN_MACRO
check_for_extra_qhat_subtraction_whole:
ja    do_qhat_subtraction_by_2_whole
cmp   bx, ax

jae   do_qhat_subtraction_by_1_whole
do_qhat_subtraction_by_2_whole:

dec   si
jmp   do_qhat_subtraction_by_1_whole

ALIGN_MACRO
do_simple_div_after_all_whole:

; zero high word just calculate low word.
div  cx       ; get low result
mov  es, ax
mov  ax, bx   ; known zero
div  cx
ret


ALIGN_MACRO
continue_checking_q1_whole:
ja    check_c1_c2_diff_whole

test  ax, ax
jz    q1_ready_whole

; rare codepath! 
;cmp   ax, di
;jbe   q1_ready_whole

check_c1_c2_diff_whole:
;sub   ax, di
sub   dx, si
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
ALIGN_MACRO
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

ALIGN_MACRO
compare_low_word_whole:
cmp   ax, bx
jbe   qhat_subtract_1_whole

qhat_subtract_2_whole:
mov ax, es
dec ax
mov es, ax
jmp qhat_subtract_1_whole

; the divide would have overflowed. subtract values
ALIGN_MACRO
adjust_for_overflow_again_whole:

sub   ax, cx
sbb   dx, di

div   cx

; ax has its result...

ret 


ENDP


; TODO 386 version

ALIGN_MACRO
PROC FastDiv3232_shift_3_8_ NEAR ; todo needs another look

; used by R_PointToAngle.
; DX:AX << 3 / CX:BX >> 8
; signed, but comes in positive. so high bit is never on
; if result is > 2048, a branch is taken and result is not used, 
; so this is designed around quickly detecting results greater than that



test ch, ch
jne not_fast_div_32_16

; shift right 8, and ch is already 0. so 16 bit.

; 32:16

mov bl, bh
mov bh, cl

SHIFT32_MACRO_LEFT dx ax 3


div  bx        ; after this dx stores remainder, ax stores q1
cmp  ax, 0801h ; nocarry if over 08000h
ret          ; dx will be garbage, but who cares , return 16 bits.

;ALIGN_MACRO
;return_2048:
;stc
;ret


ALIGN_MACRO
not_fast_div_32_16:


; we have not shifted yet...


;TODO: checks are done outside this function, may be okay to remove this. test?

; seems to work. seems faster. i dont see bugs?

;cmp dx, cx
;ja  return_2048
;jb full_32_32
;cmp ax, bx
;jae return_2048


full_32_32:



main_3232RPTA_div:

push  si


; shift left 11 in si:dx:ax


;si: 
;00000111 11111111
;dx:
;11111222 22222222
;ax:
;22222000 00000000

mov si, cx ; .. backup
xor ch, ch

mov cl, dh
mov dh, dl
mov dl, ah
mov al, ah
mov al, ch



; creating si:dx:ax
; todo swap cx/si usage or something.
; then 

REPT 3

shl ax, 1
rcl dx, 1
rcl cx, 1


ENDM






; now lets shift SI:BX to max...



; ch known nonero in this path.



; less than a byte to shift
; shift until MSB is 1

TEST SI, SI
JS  skip_shift_3232RPTA

SAL BX, 1
RCL SI, 1
JO done_shifting_3232RPTA  
SAL AX, 1
RCL DX, 1
RCL CX, 1

SAL BX, 1
RCL SI, 1
JO done_shifting_3232RPTA  
SAL AX, 1
RCL DX, 1
RCL CX, 1

SAL BX, 1
RCL SI, 1
JO done_shifting_3232RPTA  
SAL AX, 1
RCL DX, 1
RCL CX, 1

SAL BX, 1
RCL SI, 1
JO done_shifting_3232RPTA  
SAL AX, 1
RCL DX, 1
RCL CX, 1

SAL BX, 1
RCL SI, 1
JO done_shifting_3232RPTA  
SAL AX, 1
RCL DX, 1
RCL CX, 1

SAL BX, 1
RCL SI, 1
JO done_shifting_3232RPTA  
SAL AX, 1
RCL DX, 1
RCL CX, 1

SAL BX, 1
RCL SI, 1

ALIGN_MACRO
done_shifting_3232RPTA:
SAL AX, 1
RCL DX, 1
RCL CX, 1

skip_shift_3232RPTA:


; CX:DX:AX holds divisor...
; SI:BX holds dividend...
; numhi = CX:DX
; numlo = AX:00...




; save numlo word in sp.


; set up first div. 
; dx:ax becomes numhi
xchg  ax, dx ; ax gets dx
xchg  dx, cx ; dx gets cx, cx has old ax...

; store these two long term...



; numhi is 00:cx in this case?

;	divresult.wu = DIV3216RESULTREMAINDER(numhi.wu, den1);
; DX:AX = numhi.wu


div   si

; qhat is at most 2 greater than the real answer.
; we are capping results at 2048 or 0x800 so quick return in that case.

cmp  ax, 0802h
ja   return_2048_2

mov  word ptr cs:[SELFMODIFY_fastdiv_restore_original_ax+1], cx
; rhat = dx
; qhat = ax
;    c1 = FastMul16u16u(qhat , den0);



mov   cx, dx					; cx stores rhat
mov   es, ax     ; store qhat




mul   bx   						; DX:AX = c1


; c1 hi = dx, c2 lo = cx
sub   dx, cx


jae    continue_c1_c2_check   ; todo default branch here?
; quickly fall to common fast exit.
q1_ready_3232RPTA:

mov   ax, es
cmp   ax, 0801h ; nocarry if over 08000h

pop   si
ret  

ALIGN_MACRO
NOP ; force align selfmodify bwlow
continue_c1_c2_check:
SELFMODIFY_fastdiv_restore_original_ax:
mov   cx, 01000h   
ja    check_c1_c2_diff_3232RPTA
cmp   ax, cx
jbe   q1_ready_3232RPTA
check_c1_c2_diff_3232RPTA:

; (c1 - c2.wu > den.wu)

sub   ax, cx
sbb   dx, si  ; this is a sbb 0 (we did sub dx, cx above and now sbb from sub ax,cx) and a cmp dx, si combined.
ja    qhat_subtract_2_3232RPTA
jne   qhat_subtract_1_3232RPTA
compare_low_word_3232RPTA:
cmp   ax, bx
jbe   qhat_subtract_1_3232RPTA

; ugly but rare occurrence i think?
qhat_subtract_2_3232RPTA:
mov   ax, es
dec   ax
dec   ax


cmp   ax, 0801h ; nocarry if over 08000h ; todo i think this one cant happen..?
pop   si
ret  

ALIGN_MACRO
return_2048_2:
; bigger than 2048.. just return it
pop   si
clc
ret


ALIGN_MACRO
qhat_subtract_1_3232RPTA:
mov   ax, es
dec   ax
cmp   ax, 0801h ; nocarry if over 08000h
pop   si
ret  




ALIGN_MACRO


ENDP




ALIGN_MACRO
do_simple_div:
; high word is DX:AX / BX
; low word: divide remainder << 16 / BX

  ; bounds check
  ; todo compare vs sal jc
   test dh, 0C0h ; are high bits non zero (known cx shift 14 )   
   jne  do_quick_return
   mov  cx, dx  ; copy of dx
   mov  es, ax
   
   SHIFT32_MACRO_LEFT cx ax 2
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

ALIGN_MACRO
do_quick_return:
  MOV   AX, SI
  NEG   AX
  DEC   AX
  CWD
  RCR   DX, 1

  POP   SI
  RET

ALIGN_MACRO
PROC   FixedDivBSPLocal_ NEAR ; fairly optimized
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
ALIGN_MACRO
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

IF COMPISA GE COMPILE_386

ALIGN_MACRO



    ENDP

    PROC   FixedMulTrigNoShiftSine_BSPLocal_ NEAR ; fairly optimized
    PUBLIC FixedMulTrigNoShiftSine_BSPLocal_
    ; pass in the index already shifted to be a dword lookup..


    shl   ecx, 16
    xchg  ax, cx

    mov   ax, FINESINE_SEGMENT
    mov   es, ax                ; put segment in es

    mov   ax, bx
    shl   ax, 1
    cwde                        ; eax high gets sign

    shr   bx, 1                 ; dword to word lookup
    mov   ax, word ptr es:[bx] ; ax gets low word
    imul  ecx
    shr   eax, 16


    ret

    ENDP

ALIGN_MACRO



    ENDP

    PROC   FixedMulTrigNoShiftCosine_BSPLocal_ NEAR ; fairly optimized
    PUBLIC FixedMulTrigNoShiftCosine_BSPLocal_
    ; pass in the index already shifted to be a dword lookup..

    shl   ecx, 16
    xchg  ax, cx

    mov   ax, FINECOSINE_SEGMENT
    mov   es, ax                ; put segment in es

    lea   eax, [ebx*2 + 04000h]
    cwde                        ; eax high gets sign

    shr   bx, 1                 ; dword to word lookup
    mov   ax, word ptr es:[bx] ; ax gets low word
    imul  ecx
    shr   eax, 16


    ret



    ENDP


ELSE

ALIGN_MACRO




    PROC   FixedMulTrigNoShiftSine_BSPLocal_ NEAR 
    PUBLIC FixedMulTrigNoShiftSine_BSPLocal_
    ; pass in the index already shifted to be a dword lookup..

 
   SHR  BX, 1
   test bh, 020h

   MOV  DX, FINESINE_SEGMENT
   MOV  ES, DX
   MOV  BX, WORD PTR ES:[BX]
   je   skip_invert_sin
   NEG  CX
   NEG  AX
   SBB  CX, 0
   skip_invert_sin:

   MUL  BX        ; AX * BX
   MOV  AX, CX    ; CX to AX
   MOV  CX, DX    ; CX stores high result as low word
   CWD            ; S1 in DX
   AND  DX, BX    ; S1 * AX
   NEG  DX        ; 
   XCHG DX, BX    ; AX into DX, high word into BX
   MUL  DX        ; AX*CX
   ADD  AX, CX    ; add low word
   ADC  DX, BX    ; add high word
   RET



    ENDP
    ENDP


ALIGN_MACRO
    


    PROC   FixedMulTrigNoShiftCosine_BSPLocal_ NEAR ; fairly optimized
    PUBLIC FixedMulTrigNoShiftCosine_BSPLocal_
    ; pass in the index already shifted to be a dword lookup..


   SHR  BX, 1
   test bh, 030h
   MOV  DX, FINECOSINE_SEGMENT
   MOV  ES, DX
   MOV  BX, WORD PTR ES:[BX]

   jpe  skip_invert_cos
   NEG  CX
   NEG  AX
   SBB  CX, 0
   skip_invert_cos:
   
   MUL  BX        ; AX * BX
   MOV  AX, CX    ; CX to AX
   MOV  CX, DX    ; CX stores high result as low word
   CWD            ; S1 in DX
   AND  DX, BX    ; S1 * AX
   NEG  DX        ; 
   XCHG DX, BX    ; AX into DX, high word into BX
   MUL  DX        ; AX*CX
   ADD  AX, CX    ; add low word
   ADC  DX, BX    ; add high word
   RET



    ENDP
    ENDP
ENDIF





COSINE_OFFSET_IN_SINE = ((FINECOSINE_SEGMENT - FINESINE_SEGMENT) SHL 4)

;R_ClearPlanes

ALIGN_MACRO
PROC   R_ClearPlanes_ NEAR ; TODO could be better if we only clear up to lastvisplane and then dont clear visplanes when we create new ones.
PUBLIC R_ClearPlanes_ 

; dont need to preserve registers here


SELFMODIFY_BSP_viewwidth_1:
mov   cx, 01000h  ; preshifted right
mov   dx, cx


mov   ax, cs
mov   di, OFFSET OFFSET_FLOORCLIP
SHIFT_MACRO shr di 4
add   ax, di      ; TODO tasm does not let me do  ((OFFSET_FLOORCLIP) SHR 4). once this is pretty set in stone hardcode it?
mov   es, ax
xor   di, di

; viewheight plus one.

SELFMODIFY_BSP_setviewheight_2:
mov   ax, 01010h


rep   stosw  ; write vieweight to es:di


xor   ax, ax

mov   di, SCREENWIDTH  ; offset of ceilingclip within floorclip
mov   cx, dx
rep   stosw  ; write 0 to es:di

mov   word ptr ds:[_lastvisplane], cx ; 0  ; todo cs var?
mov   word ptr cs:[_lastopening], cx ; 0
SELFMODIFY_set_viewanglesr3_4:
mov   bx, 01000h
sub   bh, 08h   ; FINE_ANG90
and   bh, 01Fh    ; MOD_FINE_ANGLE

shl   bx, 1  ; word lookup

 
SELFMODIFY_BSP_centerx_2:
mov   cx, 01000h

mov   di, FINESINE_SEGMENT
mov   es, di


xor   dx, dx
xor   si, si
mov   ax, word ptr es:[bx + COSINE_OFFSET_IN_SINE]





; note: range is -65535 to 65535. High word is already sign bits

; sine/cosine max at +/- 65536 so they wont overflow.


div   cx

;    basexscale = FixedDivWholeB(finecosine[angle],temp.w);


test  bh, 030h
jpe   skip_cosine_invert_clearplanes
neg   ax
dec   si
skip_cosine_invert_clearplanes:


mov   word ptr cs:[_lastbasexscale], ax
mov   word ptr cs:[_lastbasexscale + 2], si

mov   ax, word ptr es:[bx]
xor   dx, dx
xor   si, si

test  bh, 020h
je    skip_sine_invert_clearplanes
dec   si
skip_sine_invert_clearplanes:




div   cx
not   si  ; we want a negative result so neg the sign


xor   ax, si ; apply sign
sub   ax, si

jnz   dont_zero_si  ; weird case where we try to take negative of zero and it was leaving FFFF sign bits...
mov   si, ax
dont_zero_si:  

mov   word ptr cs:[_lastbaseyscale], ax
mov   word ptr cs:[_lastbaseyscale + 2], si


ret   

endp





;R_HandleEMSVisplanePagination
ALIGN_MACRO

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
cmp   byte ptr cs:[_visplanedirty], 0
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

mov   byte ptr cs:[_ceilphyspage], bl
sal   bx, 1
mov   dx, word ptr ds:[bx + _visplanelookupsegments] ; return value for ax

mov   bl, ch
sal   bx, 1

mov   ax, word ptr ds:[bx + _visplane_offset]
add   ax, OFFSET VISPLANE_T.vp_top

mov   word ptr cs:[_ceiltop], ax
sub   ax, OFFSET VISPLANE_T.vp_top
mov   word ptr cs:[_ceiltop+2], dx


;pop   cx
pop   bx
ret   
ALIGN_MACRO
is_floor_2:
mov   byte ptr cs:[_floorphyspage], bl   
sal   bx, 1
mov   dx, word ptr ds:[bx + _visplanelookupsegments] ; return value for ax

mov   bl, ch
sal   bx, 1

mov   ax, word ptr ds:[bx + _visplane_offset]
add   ax, OFFSET VISPLANE_T.vp_top

mov   word ptr cs:[_floortop], ax
sub   ax, OFFSET VISPLANE_T.vp_top
mov   word ptr cs:[_floortop+2], dx

;pop   cx
pop   bx
ret
ALIGN_MACRO
loop_cycle_visplane_ems_page:  ; move this above func
sub   ch, VISPLANES_PER_EMS_PAGE
inc   dl
cmp   ch, VISPLANES_PER_EMS_PAGE
jae   loop_cycle_visplane_ems_page
jmp   visplane_ems_page_ready
ALIGN_MACRO
visplane_not_dirty:
cmp   al, MAX_CONVENTIONAL_VISPLANES  
jge   visplane_dirty_or_index_over_max_conventional_visplanes
mov   bx, dx
jmp   return_visplane
ALIGN_MACRO
do_quickmap_ems_visplaes:
test  cl, cl    ; check isceil
je    is_floor
; is ceil
cmp   byte ptr cs:[_floorphyspage], 2  
jne   use_phys_page_2
;ja    out_of_visplanes
use_phys_page_1:
mov   bl, 1

mov   dl, bl


call  Z_QuickMapVisplanePage_BSPLocal_
jmp   return_visplane
ALIGN_MACRO
use_phys_page_2:
mov   bl, 2
mov   dl, bl


call  Z_QuickMapVisplanePage_BSPLocal_
jmp   return_visplane
ALIGN_MACRO
is_floor:
cmp   byte ptr cs:[_ceilphyspage], 2
;ja    out_of_visplanes
je    use_phys_page_1
mov   bl, 2
mov   dl, bl

call  Z_QuickMapVisplanePage_BSPLocal_
jmp   return_visplane

COMMENT @
out_of_visplanes:
push    cs
mov     ax, OFFSET str_outofvisplanes
push    ax
call    dword ptr ds:[_I_Error_addr]



str_outofvisplanes:
db "Out of Visplanes!", 0
@
ENDP

ALIGN_MACRO
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


mov   byte ptr cs:[_visplanedirty], 1
pop   si
pop   cx
pop   bx
ret  
ALIGN_MACRO
visplane_page_above_2:
;		usedpagevalue = EMS_VISPLANE_EXTRA_PAGE + (virtualpage-2);
add   ax, (EMS_VISPLANE_EXTRA_PAGE - 2)
jmp   used_pagevalue_ready

ALIGN_MACRO
set_zero_and_break:
mov   byte ptr ds:[bx + _active_visplanes], 0
jmp   done_with_visplane_loop

ENDP

ALIGN_MACRO
PROC Z_QuickMapVisplaneRevert_BSPLocal_ NEAR

push  dx
mov   dx, 1
mov   ax, dx
call  Z_QuickMapVisplanePage_BSPLocal_
mov   dx, 2
mov   ax, dx
call  Z_QuickMapVisplanePage_BSPLocal_
mov   byte ptr cs:[_visplanedirty], 0
pop   dx
ret  

ENDP


;R_FindPlane_

ALIGN_MACRO
PROC   R_FindPlane_ NEAR ; could use another look
PUBLIC R_FindPlane_


; dx is 13:3 height
; cx is picandlight
; bl is icceil

xor       ax, ax

SELFMODIFY_BSP_set_skyflatnum_3:
cmp       cl, 010h
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

push      bx  ; push isceil  ; todo store elsewhere maybe di

; init loop vars
; ax already xored.

mov       ah, byte ptr ds:[_lastvisplane]

; not possible?
;test      ah, ah
;js        break_loop   ; else break

; do loop setup

mov       al, 0
mov       bx, _visplaneheaders   ; set bx to header 0


next_loop_iteration:
ENSUREALIGN_320:

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


ret       


;		if (height == checkheader->height
;			&& piclight.hu == visplanepiclights[i].pic_and_light) {
;				break;
;		}

ALIGN_MACRO
check_for_visplane_match:
cmp       dx, word ptr ds:[bx + VISPLANEHEADER_T.visplaneheader_height] ; compare height high word
jne       loop_iter_step_variables
cmp       cx, word ptr ds:[bx + VISPLANEHEADER_T.visplaneheader_piclight] ; compare picandlight
je        break_loop

loop_iter_step_variables:
inc       al
add       bx, SIZE VISPLANEHEADER_T

cmp       al, ah
jle       next_loop_iteration
sub       bx, SIZE VISPLANEHEADER_T  ; use last checkheader index
jmp       break_loop

ALIGN_MACRO

break_loop_visplane_not_found:
; not found, create new visplane

cbw       ; no longer need lastvisplane, zero out ah


; set up new visplaneheader
mov       word ptr ds:[bx + VISPLANEHEADER_T.visplaneheader_piclight], cx 
mov       word ptr ds:[bx + VISPLANEHEADER_T.visplaneheader_height], dx
mov       word ptr ds:[bx + VISPLANEHEADER_T.visplaneheader_minx], SCREENWIDTH
mov       word ptr ds:[bx + VISPLANEHEADER_T.visplaneheader_maxx], 0FFFFh
mov       byte ptr ds:[bx + VISPLANEHEADER_T.visplaneheader_dirty], ah ; 0

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

;  es:di currently points to 0142h or vp_pad2



lea       ax, [bx - _visplaneheaders]

ret       

ENDP

ALIGN_MACRO
PROC R_CheckPlaneSetCeil_ NEAR

mov       byte ptr ds:[SELFMODIFY_setisceil + 1], 1

;R_CheckPlane_


PROC R_CheckPlane_ NEAR ; needs another look 

; ax: index
; cl: isceil?

; ds is cs at call time

; di holds visplaneheaders lookup. maybe should be si


mov       si, dx    ; si holds start


; already mult 9'd
mov       word ptr ds:[SELFMODIFY_setindex+1], ax

xchg      ax, di
add       di, _visplaneheaders  ; _di is plheader


mov       ax, ss   ;  restore DS for now due to visplane headers use. try to make this not happen though?
mov       ds, ax


; di holds offset..

mov       ax, si  ; fetch start
cmp       ax, word ptr ds:[di + VISPLANEHEADER_T.visplaneheader_minx]    ; compare to minx
jge       start_greater_than_min
mov       word ptr cs:[SELFMODIFY_setminx+3], ax
mov       dx, word ptr ds:[di + VISPLANEHEADER_T.visplaneheader_minx]    ; fetch minx into intrl
checked_start:
; now checkmax
mov       ax, word ptr ds:[di + VISPLANEHEADER_T.visplaneheader_maxx]   ; fetch maxx, ax = intrh = plheader->max
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

;	pltop[x]==0xff ; todo rep scasb or scasw

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
ENSUREALIGN_053:
SELFMODIFY_setmax:
mov       word ptr ds:[di + VISPLANEHEADER_T.visplaneheader_maxx], 0FFFFh
ENSUREALIGN_054:

SELFMODIFY_setindex:
mov       ax, 0ffffh
ENSUREALIGN_052:

mov       di, cs   ;  restore DS for now, try to make this not happen though.
mov       ds, di

ret       

ALIGN_MACRO
start_greater_than_min:
mov       ax, word ptr ds:[di + VISPLANEHEADER_T.visplaneheader_minx]


mov       word ptr cs:[SELFMODIFY_setminx+3], ax
jmp       checked_start
ALIGN_MACRO
stop_smaller_than_max:
mov       word ptr cs:[SELFMODIFY_setmax+3], ax     ; unionh = plheader->max
mov       ax, cx                                    ; intrh = stop
jmp       done_checking_max

ALIGN_MACRO
make_new_visplane:
mov       bx, word ptr ds:[_lastvisplane]  ;todo move to cs, pass into r_span as arg.
mov       es, bx    ; store in es
mov       dx, bx
SHIFT_MACRO shl bx 3
add       bx, dx  ; * 9  ; SIZE VISPLANEHEADER_T

; dx/ax is plheader->height
; done with old plheader..
; es is in use..

add       bx, _visplaneheaders

mov       dx, word ptr ds:[di + VISPLANEHEADER_T.visplaneheader_height]
mov       di, word ptr ds:[di + VISPLANEHEADER_T.visplaneheader_piclight]

;	visplanepiclights[lastvisplane].pic_and_light = visplanepiclights[index].pic_and_light;


; set all plheader fields for lastvisplane...
mov       word ptr ds:[bx + VISPLANEHEADER_T.visplaneheader_piclight], di
mov       word ptr ds:[bx + VISPLANEHEADER_T.visplaneheader_height], dx
mov       word ptr ds:[bx + VISPLANEHEADER_T.visplaneheader_minx], si 
mov       word ptr ds:[bx + VISPLANEHEADER_T.visplaneheader_maxx], cx 




SELFMODIFY_setisceil:
mov       dx, 0000h     ; set isceil argument

mov       byte ptr ds:[bx + VISPLANEHEADER_T.visplaneheader_dirty], dh  ; should be 0

mov       ax, es 
mov       si, ax 
cbw      

call      R_HandleEMSVisplanePagination_
mov       di, ax
mov       es, dx
; jumped here?
mov       ax, 0FFFFh

mov       cx, (SCREENWIDTH / 2) + 1   ; plus one for the padding
rep stosw 


lea       ax, [bx - _visplaneheaders]
inc       word ptr ds:[_lastvisplane] ; todo add SIZE VISPLANEHEADER_T?

mov       di, cs   ;  restore DS for now, try to make this not happen though.
mov       ds, di


ret       

ENDP

MINZ_HIGHBITS = 4
;R_ProjectSprite_

ALIGN_MACRO
PROC R_ProjectSprite_ NEAR  ; somewhatoptimized... maybe re-examine. 
public R_ProjectSprite_
; es:si is sprite.
; es is a constant..

; use parent stackframe

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
; bp - 01Ch:   temp lowbits
; bp - 01Eh:	xscale hi
; bp - 020h:	xscale lo
; bp - 022h:   spriteindex. used for spriteframes and spritetopindex?
; bp - 024h:   flip
; bp - 026h:   vis->x1
; bp - 028h:   vis->x2


mov   dx, es					   ; back this up...
mov   bx, word ptr es:[si + MOBJ_POS_T.mp_statenum]  ; thing->stateNum
sal   bx, 1

; todo clean all this up. do we need local copy?
; otherwise use ds and rep movsw
mov   ax, word ptr ds:[bx + STATE_T.state_sprite + _states_render]		   ; states_render[thing->stateNum].sprite
mov   byte ptr cs:[SELFMODIFY_set_ax_to_spriteframe+1], al		   
mov   al, ah
mov   ah, (SIZE SPRITEFRAME_T)
push  ax    ; bp - 2
sub   sp, 018h


mov   cx, 6
mov   bx, ss
mov   es, bx					; es is SS i.e. destination segment
mov   ds, dx					; ds is movsw source segment
mov   ax, word ptr ds:[si + MOBJ_POS_T.mp_angle + 2]
mov   word ptr cs:[SELFMODIFY_set_ax_to_angle_highword+1], ax
mov   al, byte ptr ds:[si + MOBJ_POS_T.mp_flags2]	; 016h  flags2
mov   byte ptr cs:[SELFMODIFY_set_al_to_flags2+1], al

lea   di, [bp - 01Ah]			; di is the stack area to copy to..

rep   movsw

;si is [si + 0xC] now...


mov   ds, bx					; restore ds to FIXED_DS_SEGMENT
lea   si, [bp - 01Ah]

lodsw
SELFMODIFY_BSP_viewx_lo_1:
sub   ax, 01000h
stosw                ; tr_x lo
xchg   bx, ax
lodsw
SELFMODIFY_BSP_viewx_hi_1:
sbb   ax, 01000h
stosw                ; tr_x hi
xchg   cx, ax						


lodsw
SELFMODIFY_BSP_viewy_lo_1:
sub   ax, 01000h
stosw
lodsw
SELFMODIFY_BSP_viewy_hi_1:
sbb   ax, 01000h
stosw

;    gxt.w = FixedMulTrigNoShift(FINE_COSINE_ARGUMENT, viewangle_shiftright1 ,tr_x.w);
xchg  ax, bx  ; get low back into ax

SELFMODIFY_set_viewanglesr1_3:
mov   bx, 01000h

call  FixedMulTrigNoShiftCosine_BSPLocal_




xchg  ax, si      ; store gxt lo
mov   di, dx      ; store gxt hi


; cx:bx = tr_y
les   ax, dword ptr [bp - 0Ah]
mov   cx, es


; di:si has gxt

SELFMODIFY_set_viewanglesr1_4:
mov   bx, 01000h

;    gyt.w = -FixedMulTrigNoShift(FINE_SINE_ARGUMENT, viewangle_shiftright1 ,tr_y.w);


call FixedMulTrigNoShiftSine_BSPLocal_

; todo clean this up. less register swapping.


neg   dx
neg   ax
sbb   dx, 0

;    tz.w = gxt.w-gyt.w; 
sub   si, ax
sbb   di, dx



cmp   di, MINZ_HIGHBITS

;    // thing is behind view plane?
;    if (tz.h.intbits < MINZ_HIGHBITS){ // (- sq: where does this come from)
;        return;
;    }

jl   exit_project_sprite





les   ax, [bp - 0Eh]
mov   cx, es

SELFMODIFY_set_viewanglesr1_2:
mov   bx, 01000h

call  FixedMulTrigNoShiftSine_BSPLocal_
neg dx
neg ax
sbb dx, 0
; results from DX:AX to DI:SI... eventually

push  si  ; tz_lobits
push  di  ; tz_hibits

mov   di, dx
xchg  ax, si

les   ax, [bp - 0Ah]
mov   cx, es



SELFMODIFY_set_viewanglesr1_1:
mov   bx, 01000h

call FixedMulTrigNoShiftCosine_BSPLocal_

;    tx.w = -(gyt.w+gxt.w); 

add   ax, si		; add gxt
adc   dx, di
neg   dx
neg   ax
sbb   dx, 0

pop   di ; tz_hibits
pop   bx ; tz_lobits
mov   es, bx ; dupe lobits

push  ax ; store temp lowbtis ; bp - 01Ch

; todo terrible register usage! put this on stack.
mov   si, dx						; si stores temp highbits


; si stores tx highbits?

;    // too far off the side?
;    if (labs(tx.w)>(tz.w<<2)){ // check just high 16 bits?

jge   tx_already_positive				; labs sign check
neg   ax
neg   dx
sbb   dx, 0
tx_already_positive:
public tx_already_positive

;        return;
;	}


xchg  ax, cx  ; cx gets low

mov   ax, di   ; di:bx backup in es:ax

SHIFT32_MACRO_LEFT di bx 2

cmp   dx, di
jl    not_too_far_off_side
jne   exit_project_sprite
cmp   bx, cx
jnb   not_too_far_off_side

exit_project_sprite: ; todo bench branch

jmp   done_with_r_projectsprite
ALIGN_MACRO

not_too_far_off_side:

; now do the fixeddiv.

xchg  ax, cx                    ; cx: tz_hibits restore
mov   bx, es                    ; bx: tz_lobits restore

SELFMODIFY_BSP_centerx_4:
mov   ax, 01000h

call  FixedDivWholeA_BSPLocal_ ; todo delay until needed? 
   ; todo make this not suck
pop   cx
push  dx ; bp - 01Ch
push  ax ; bp - 01Eh
push  cx ; bp - 020h

SELFMODIFY_set_ax_to_spriteframe:
mov   ax, 00012h  ; leave high byte 0
mov   di, ax
add   di, ax   ; * 2
add   di, ax   ; * 3 , SIZE SPRITEDEF_T
mov   ax, SPRITES_SEGMENT
mov   es, ax
mov   ax, word ptr [bp - 2]  ; thingframe in al, SIZE SPRITEFRAME_T hih)
and   al, FF_FRAMEMASK
mul   ah
mov   di, word ptr es:[di + SPRITEDEF_T.spritedef_spriteframesOffset] 
xor   bx, bx ; default 0 rotation for lookup
add   di, ax
cmp   byte ptr es:[di + SPRITEFRAME_T.spriteframe_rotate], 0

je    skip_sprite_rotation

les   ax, dword ptr [bp - 01Ah]
mov   dx, es
les   bx, dword ptr [bp - 016h]
mov   cx, es


SELFMODIFY_BSP_viewy_lo_3:
sub   bx, 01000h
SELFMODIFY_BSP_viewy_hi_3:
sbb   cx, 01000h

SELFMODIFY_BSP_viewx_lo_3:
sub   ax, 01000h
SELFMODIFY_BSP_viewx_hi_3:
sbb   dx, 01000h

call  R_PointToAngle_
mov   ax, dx
;xchg ax, dx  ; toggle for ENSUREALIGN_319
;rot = _rotl(ang.hu.intbits - thingangle.hu.intbits + 0x9000u, 3) & 0x07;

SELFMODIFY_set_ax_to_angle_highword:
sub   ax, 01000h
ENSUREALIGN_319:
add   ah, 090h
SHIFT_MACRO rol ax 3
and   ax, 7
add   di, ax					; add rot lookup (byte)
xchg  ax, bx               ; bx gets 2nd byte for word lookup

mov   cx, SPRITES_SEGMENT
mov   es, cx

skip_sprite_rotation:


mov   bx, word ptr es:[di+bx + SPRITEFRAME_T.spriteframe_lump]	; word lookup based on rot
push  bx  ; bp - 022h
xchg  bx, di

push word ptr es:[bx + SPRITEFRAME_T.spriteframe_flip] ; bp - 024h  ; byte lookup based on flip
mov   ax, SPRITEOFFSETS_SEGMENT

mov   es, ax
mov   al, byte ptr es:[di]  ; lump for sprite.
les   bx, dword ptr [bp - 01Eh]
mov   cx, es
xor   ah, ah

sub   si, ax						; no need for sbb?
mov   ax, word ptr [bp - 020h]

push  si

; inlined FixedMulBSPLocal_

IF COMPISA GE COMPILE_386

  mov  dx, si

  shl  ecx, 16
  mov  cx, bx
  xchg ax, dx
  shl  eax, 16
  xchg ax, dx
  imul  ecx
  shr  eax, 16



ENDP
ELSE



   ; MOV  SI, DX we just retrieved this
   MOV  ES, AX
   MUL  BX
   MOV  DI, DX
   MOV  AX, SI
   MUL  CX
   XCHG AX, SI
   CWD
   AND  DX, BX
   SUB  SI, DX
   MUL  BX
   ADD  AX, DI
   ADC  SI, DX
   XCHG AX, CX
   CWD
   MOV  BX, ES
   AND  DX, BX
   SUB  SI, DX
   MUL  BX
   ADD  AX, CX
   ADC  DX, SI



ENDIF


pop   si  ; restore sp alignment.
xchg  ax, dx

SELFMODIFY_BSP_centerx_5:
add   ax, 01000h

;    // off the right side?
;    if (x1 > viewwidth){
;        return;
;    }
    


SELFMODIFY_BSP_viewwidth_2:
cmp   ax, 01000h
jle   not_too_far_off_right_side_highbits
jump_to_exit_project_sprite_2:
jmp   exit_project_sprite
ALIGN_MACRO
not_too_far_off_right_side_highbits:
push  ax ; bp - 026h
les   bx, dword ptr [bp - 022h]   ; es holds bp - 020h to go into the next mul.
xor   ax, ax
mov   al, byte ptr cs:[bx + (SPRITEWIDTHS_OFFSET)]

;    if (usedwidth == 1){
;        usedwidth = 257;
;    }


cmp   al, 1
jne   usedwidth_not_1
mov   ah, al      ; encodes 257, hack..
usedwidth_not_1:

;   temp.h.fracbits = 0;
;    temp.h.intbits = usedwidth;
;    // hack to make this fit in 8 bits, check r_init.c
;    tx.w +=  temp.w;
;	temp.h.intbits = centerx;
;	temp.w += FixedMul (tx.w,xscale.w);

dec   ax
mov   word ptr cs:[SELFMODIFY_set_usedwidth + 3], ax




; inlined FixedMulBSPLocal_

IF COMPISA GE COMPILE_386

   mov   dx, si
   add   ax, dx					; no need for adc
   shl  eax, 16
   mov   ax, es  ; bp - 020h from LES above

   mov   ecx, dword ptr [bp - 01Eh]


  imul  ecx
  shr  eax, 16



ENDP
ELSE


   add   si, ax					; no need for adc
   mov   ax, es  ; bp - 020h from LES above

   les   bx, dword ptr [bp - 01Eh]
   mov   cx, es



   mov  ES, AX
   MUL  BX
   MOV  DI, DX
   MOV  AX, SI
   MUL  CX
   XCHG AX, SI
   CWD
   AND  DX, BX
   SUB  SI, DX
   MUL  BX
   ADD  AX, DI
   ADC  SI, DX
   XCHG AX, CX
   CWD
   MOV  BX, ES
   AND  DX, BX
   SUB  SI, DX
   MUL  BX
   ADD  AX, CX
   ADC  DX, SI



ENDIF

;    x2 = temp.h.intbits - 1;

SELFMODIFY_BSP_centerx_6:
add   dx, 01000h
dec   dx
push  dx ; bp - 028h

;    // off the left side
;    if (x2 < 0)
;        return;

test  dx, dx
js    jump_to_exit_project_sprite_2  ; 06Ah ish out of range

mov   si, word ptr ds:[_vissprite_p]
cmp   si, MAX_VISSPRITES_ADDRESS
je   got_vissprite
; don't increment vissprite if its the max index. reuse this index.
add   word ptr ds:[_vissprite_p], SIZE VISSPRITE_T
got_vissprite:


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
lea   di, [si  + VISSPRITE_T.vs_gx]
lea   si, [bp - 01Ah]

mov   ax, ss
mov   es, ax

; copy thing x y z to new vissprite x y z
rep movsw

lea   si, [di - VISSPRITE_T.vs_gzt]			; restore si

mov   bx, word ptr [bp - 022h]
mov   word ptr ds:[si + VISSPRITE_T.vs_patch], bx

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
je   set_intbits_to_129    ; hacky special case.
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

mov   ax, word ptr [bp - 026h]

;    vis->x1 = x1 < 0 ? 0 : x1;

test  ax, ax
jge   x1_positive
xor   ax, ax

x1_positive:
mov   word ptr ds:[si + VISSPRITE_T.vs_x1], ax

;    vis->x2 = x2 >= viewwidth ? viewwidth-1 : x2;       


mov   ax, word ptr [bp - 028h]  ; get x2

SELFMODIFY_BSP_viewwidth_3:
mov   bx, 01000h
cmp   ax, bx
jl    x2_smaller_than_viewwidth
lea   ax, [bx - 1]
x2_smaller_than_viewwidth:
les   bx, dword ptr [bp - 01Eh]
mov   cx, es
mov   word ptr ds:[si + VISSPRITE_T.vs_x2], ax
mov   ax, 1
; todo: make a "div65536" function which does a shift strategy rather than needing the full thing?
call FixedDivWholeA_BSPLocal_
xchg  ax, bx
mov   cx, dx
xor   ax, ax
cmp   byte ptr [bp - 024h], al
jne   flip_not_zero

flip_zero: ; zero case

mov   word ptr ds:[si + VISSPRITE_T.vs_startfrac + 0], ax ; 0
mov   word ptr ds:[si + VISSPRITE_T.vs_startfrac + 2], ax ; 0
jmp   flip_stuff_done
ALIGN_MACRO

set_intbits_to_129:
mov   ax, 129
jmp intbits_ready

ALIGN_MACRO

flip_not_zero:
dec   ax
mov   word ptr ds:[si + VISSPRITE_T.vs_startfrac + 0], ax ; -1

SELFMODIFY_set_usedwidth:
mov   word ptr ds:[si + VISSPRITE_T.vs_startfrac + 2], 01000h

neg   cx
neg   bx
sbb   cx, 0

flip_stuff_done:

mov   word ptr ds:[si + VISSPRITE_T.vs_xiscale + 0], bx
mov   word ptr ds:[si + VISSPRITE_T.vs_xiscale + 2], cx


;    if (vis->x1 > x1)
;        vis->startfrac += FastMul16u32u((vis->x1-x1),vis->xiscale);

mov   ax, word ptr ds:[si + VISSPRITE_T.vs_x1]

sub   ax, word ptr [bp - 026h]
jle   vis_x1_greater_than_x1

; cx:bx already vs_xiscale 

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


;    if (thingflags2 & MF_SHADOW) {

SELFMODIFY_set_al_to_flags2:
mov   al, 00h
test  al, MF_SHADOW
jne   exit_set_shadow
SELFMODIFY_BSP_fixedcolormap_2:
jmp SHORT   exit_set_fixed_colormap
ALIGN_MACRO
SELFMODIFY_BSP_fixedcolormap_2_AFTER:
test  byte ptr [bp - 2], FF_FULLBRIGHT
jne   exit_set_fullbright_colormap


;        index = xscale.w>>(LIGHTSCALESHIFT-detailshift.b.bytelow);

; shift 32 bit value by (12 - detailshift) right.
; but final result is capped at 48. so we dont have to do as much with the high word...
mov   ax, word ptr [bp - 01Dh] ; shift 8 by loading a byte higher.


; cl should be 2-4
SELFMODIFY_BSP_detailshift_7:
mov   cl, 2

sar   ax, cl

;        if (index >= MAXLIGHTSCALE) {
;            index = MAXLIGHTSCALE-1;
;        }

mov   di, MAXLIGHTSCALE - 1
cmp   ax, di
jg    index_above_maxlightscale
xchg  ax, di
index_above_maxlightscale:
SELFMODIFY_set_spritelights_1:
mov   al, byte ptr ds:[di+01000h]
mov   byte ptr ds:[si + VISSPRITE_T.vs_colormap], al

jmp   done_with_r_projectsprite
ALIGN_MACRO

exit_set_fullbright_colormap:
mov   byte ptr ds:[si + VISSPRITE_T.vs_colormap], 0

jmp   done_with_r_projectsprite
ALIGN_MACRO


SELFMODIFY_BSP_fixedcolormap_2_TARGET:
SELFMODIFY_BSP_fixedcolormap_1:
exit_set_fixed_colormap:
mov   byte ptr ds:[si + VISSPRITE_T.vs_colormap], 0

jmp   done_with_r_projectsprite
ALIGN_MACRO


exit_set_shadow:
mov   byte ptr ds:[si + VISSPRITE_T.vs_colormap], COLORMAP_SHADOW

jmp   done_with_r_projectsprite

ENDP






COMMENT @
out_of_drawsegs:
LEAVE_MACRO
pop       di
pop       si
pop       cx
pop       bx
ret       

@

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

ALIGN_MACRO
adjust_row_offset:
public adjust_row_offset
cbw      ; maxes at 127, ah is 0
SHIFT_MACRO shl ax 3
neg       ax  ; subtract this from the real number
add       ax, ((080h SHL 3) - 1) ; 0400h - 1 for equals case
mov       word ptr [bp - 0Ch], ax   ;  TODO make this a push. probably change the bp addr.

jmp       done_adjusting_row_offset



;R_StoreWallRangeNoBackSector_

STOREWALLRANGE_INNER_STACK_SIZE_BOTTOP = 06h
STOREWALLRANGE_INNER_STACK_SIZE_MID = 02h

ALIGN_MACRO
PROC   R_StoreWallRangeNoBackSector_ NEAR ; needs another look and reconciliation with outer stack frames.
PUBLIC R_StoreWallRangeNoBackSector_ 


; todo shift 4/segsrender thing here
;below are lazily populated in sector block

; todo cache floor - ceil?

; bp + 0Fh   ; backsectorlightlevel     - backsector items set by line code
; bp + 0Eh   ; frontsectorlightlevel
; bp + 0Dh   ; backsectorfloorpic       - backsector items set by line code
; bp + 0Ch   ; frontsectorfloorpic
; bp + 0Bh   ; backsectorceilingpic     - backsector items set by line code
; bp + 0Ah   ; frontsectorceilingpic
; bp + 8     ; frontsectorceilingheight
; bp + 6     ; frontsectorfloorheight

;below are pushed in R_AddLine_
; bp + 4     ; linenum for R_AddLine_
; bp + 2     ; loop counter for R_AddLine_
; bp - 0     ; bp pushed from R_AddLine
; bp - 2     ; lineflags
; bp - 4     ; curlineside
; bp - 6     ; curseglinedef
; bp - 8     ; curlinesidedef
; bp - 0Ah   ; curseg_render
; bp - 0Ch   ; lazily calculated 128 - siderowoffset (nonloop draw height threshhold)
; bp - 0Eh   ; unused for now? push something else
; bp - 010h  ; rw_angle hi from R_AddLine
; bp - 012h  ; rw_angle lo from R_AddLine

; func return and preserved vars. TODO pusha/popa support with constant for 8088 
; bp - 016h  ; unused pushed reg precall
; bp - 018h  ; unused pushed reg precall
; bp - 01Ah  ; unused pushed reg precall
; bp - 01Ch  ; unused pushed reg precall
; bp - 01Ch  ; return address from R_StoreWallRange_
; bp - 01Eh  ; dx arg (no need to pop), then unpopped
; bp - 020h  ; ax arg (no need to pop), then unpopped

; pushed stuff
; bp - 022h  ; stop - start, then unpopped


; bp - 024h  ; worldtop hi, then unpopped
; bp - 026h  ; worldtop lo, then unpopped
; bp - 028h  ; worldbottom hi, then unpopped
; bp - 02Ah  ; worldbottom lo, then unpopped

; bp - 02Ch  ; rw_scale hi, then unpopped
; bp - 02Eh  ; rw_scale lo, then unpopped




push      dx ; bp - 01Eh
push      ax ; bp - 020h

sub       dx, ax
push      dx ; bp - 022h   stop - start. used often. ; todo: maybe we get this for free elsewhere without this sub?

mov       cx, cs  ; ends these blocks with cs

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;; START SECTOR BASED SELF MODIFY BLOCK ;;;;;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

SELFMODIFY_skip_frontsector_based_selfmodify:
mov       bl, (SELFMODIFY_skip_frontsector_based_selfmodify_TARGET - SELFMODIFY_skip_frontsector_based_selfmodify_AFTER)  ;  selfmodifies into mov bl, imm8
SELFMODIFY_skip_frontsector_based_selfmodify_AFTER:

; here we lazily set all front sector fields.
; backsector fields must be set afterwards.

; bp + 6   ; frontsectorfloorheight
; bp + 8   ; frontsectorceilingheight
; bp + 0Ah   ; frontsectorceilingpic
; bp + 0Bh   ; backsectorceilingpic     - backsector items set by line code
; bp + 0Ch     ; frontsectorfloorpic
; bp + 0Dh     ; backsectorfloorpic       - backsector items set by line code
; bp + 0Eh     ; frontsectorlightlevel
; bp + 0Fh     ; backsectorlightlevel     - backsector items set by line code

lea       di, [bp + 6]
mov       dx, ss
mov       es, dx
lds       si, dword ptr cs:[_frontsector]

; si = frontsector
movsw     ; bp + 6 frontsectorfloorheight
movsw     ; bp + 8 frontsectorceilingheight
lodsw
xchg       al, ah
stosw     ; bp + 0Ah  gets frontsectorceilingpic
mov       al, ah
stosw     ; bp + 0Ch gets frontsectorceilingheight
mov       al, byte ptr ds:[si + (SECTOR_T.sec_lightlevel - SECTOR_T.sec_validcount)]
stosb     ; bp + 0Eh frontsectorlightlevel  ; todo test prestoring sal 4?


mov       ds, dx
mov       al, 0EBh
mov       byte ptr cs:[SELFMODIFY_skip_frontsector_based_selfmodify], al  ; jmp here
mov       byte ptr cs:[SELFMODIFY_skip_frontsector_based_selfmodify_TWOSIDED], al  ; jmp here
; cx still cs
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;;; END SECTOR BASED SELF MODIFY BLOCK ;;;;;;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
SELFMODIFY_skip_frontsector_based_selfmodify_TARGET:

; todo modify the sector skip to skip both?
; or jump out and back to do inits instead of jump past?
; bench!


;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;;; START LINE BASED SELF MODIFY BLOCK ;;;;;;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

; note - line jumps past sector, but falls thru to sector check
; sector can not change without line changing.

; todo also skip sector selfmodifies lazily

SELFMODIFY_skip_curseg_based_selfmodify:
mov       bx, (SELFMODIFY_skip_curseg_based_selfmodify_TARGET - SELFMODIFY_skip_curseg_based_selfmodify_AFTER)  ;  selfmodifies into mov bx, imm
SELFMODIFY_skip_curseg_based_selfmodify_AFTER:
public  SELFMODIFY_skip_curseg_based_selfmodify_AFTER
mov       bx, word ptr [bp - 0Ah]  ; curseg_render     ; turns into a jump past selfmodifying code once this next code block runs. 
mov       ax, word ptr ds:[bx + SEG_RENDER_T.sr_offset]  ; can be up to 512 i think.
mov       word ptr cs:[SELFMODIFY_BSP_sidesegoffset+1], ax


mov       si, word ptr [bp - 8]  ; SEG_RENDER_T.sr_sidedefOffset preshifted 2

; NOTE: when we want to detect looping textures, we are checking for textures of size < 128 (the looping boundary)

; this is a little awkward - we need to combine row (texel v) offset with a sector height 
; but sector height is stored 13:3 and thus this must be shiftd 3...

mov       al, byte ptr ds:[si + _sides_render + SIDE_RENDER_T.sr_rowoffset]
mov       byte ptr cs:[SELFMODIFY_BSP_siderenderrowoffset_1+1], al


test      al, al
jnz       adjust_row_offset
; todo calculate this in upper frame.
mov       word ptr [bp - 0Ch], (080h SHL 3) - 1 ; 0400h - 1 for equals case   ;  TODO make this a push. probably change the bp addr.
done_adjusting_row_offset:



shl       si, 1


les       bx, dword ptr ss:[bx + SEG_RENDER_T.sr_v1Offset]   ; v1
mov       di, es                                             ; v2

mov       ds, word ptr ss:[_VERTEXES_SEGMENT_PTR]


les       bx, dword ptr ds:[bx] ;v1.x
mov       ax, es

mov       word ptr cs:[SELFMODIFY_BSP_v1x+1], bx
mov       word ptr cs:[SELFMODIFY_BSP_v1y+1], ax

sub       ax, word ptr ds:[di + VERTEX_T.v_y]
mov       dl, 048h  ; dec ax
je        v2_y_equals_v1_y      ; todo branch test
sub       bx, word ptr ds:[di + VERTEX_T.v_x]
mov       dl, 090h  ; nop
jne       v2_y_not_equals_v1_y  ; todo branch test
mov       dl, 040h  ; inc ax
v2_y_not_equals_v1_y:
v2_y_equals_v1_y:

mov       byte ptr cs:[SELFMODIFY_addlightnum_delta], dl
; check for backsector and load side texture data
; bx, dx, di free...

   mov       ax, TEXTURETRANSLATION_SEGMENT
   mov       es, ax

   ; default jump locations for backsecnum == null


   ; note: BX free now

   mov       ax, SIDES_SEGMENT
   mov       ds, ax


   cmp       word ptr cs:[_backsector], SECNUM_NULL

   jne       handle_closed_door     ; if this was called with a backsector then its a closed door, go fetch top or bot tex instead of mid


selfmodify_mid_only:
   ; twosided textures can still have a mid texture (invisible walls like E1M1)

   xor       dx, dx
   add       si, 4   ; skip top/bot
   lodsw     ; side midtexture
   test      ax, ax
   jz        skip_midtex_selfmodify
got_texture:
   ; si pts to textureheight now
   xchg      ax, di

   mov       byte ptr cs:[SELFMODIFY_BSP_midtexture_type+1], dl
   mov       al, byte ptr es:[di + TEXTUREHEIGHTS_OFFSET_IN_TEXTURE_TRANSLATION]
   cbw
   sal       di, 1  ; word lookup
   inc       ax
   mov       word ptr cs:[SELFMODIFY_add_texturemidheight_plus_one+1], ax
   push      word ptr es:[di]
   pop       word ptr cs:[SELFMODIFY_BSP_set_midtexture+1]

   jmp       skip_midtex_selfmodify
ALIGN_MACRO

; todo find a way to fit this elsewhere w/o a jump
handle_closed_door:  
; note: a closed door can also be a raised elevator and thus a bot texture.
   lodsw             ; toptex
   inc       dx  ; dl = 1, top wall
   test      ax, ax
   jz        use_bot_tex_for_closed_door
   add       si, 4   ; skip bot, midtex.
   ; top texture for closed door needs to be pegged to bottom instead of from top.
   jmp       got_texture
   use_bot_tex_for_closed_door:
   lodsw
   add       si, 2  ; skip midtex.
   inc       dx    ; dl = 2, botwall
   jmp       got_texture

   ; create jmp instruction
ALIGN_MACRO
   skip_midtex_selfmodify:


   lodsw     ; textureoffset
   mov       word ptr cs:[SELFMODIFY_BSP_sidetextureoffset+1], ax
   mov       si, ss
   mov       ds, si  ; restore ds..   ; todo dont switch ds?

   mov       si, word ptr [bp - 6]
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

   mov       bx, word ptr [bp + 4]
   sal       bx, 1       ;  curseg word lookup

   mov       ax, word ptr ds:[bx+_seg_normalangles]
   mov       word ptr cs:[SELFMODIFY_sub_rw_normal_angle_1+1], ax
   xchg      ax, si

   SELFMODIFY_set_viewanglesr3_1:
   mov       ax, 01000h
   ;add       ah, 8  ; preadded
   sub       ax, si
   and       ah, FINE_ANGLE_HIGH_BYTE

   ; set centerangle in rendersegloop
   mov       word ptr cs:[SELFMODIFY_set_rw_center_angle+2], ax
   xchg      ax, si
   SHIFT_MACRO shl ax SHORTTOFINESHIFT
   mov       word ptr cs:[SELFMODIFY_set_rw_normal_angle_shift3+1], ax


   ;	offsetangle = (abs((rw_normalangle_shiftleft3) - (rw_angle1.hu.intbits)) >> 1) & 0xFFFC;
   sub       ax, word ptr [bp - 010h]   ; rw_angle hi from R_AddLine
   cwd       
   xor       ax, dx		; abs by sign bits
   sub       ax, dx
   sar       ax, 1

   and       al, 0FCh
   mov       word ptr cs:[SELFMODIFY_set_offsetangle+1], ax
   mov       si, FINE_ANG90_NOSHIFT
   sub       si, ax 

; calculate hyp inlined

      SELFMODIFY_BSP_v1x:
      mov       cx, 01000h
      ENSUREALIGN_300:
      
      push  si

      ;    dx = labs(x.w - viewx.w);
      ;  x = ax register
      ;  y = dx

      SELFMODIFY_BSP_v1y:
      mov       dx, 01000h
      ENSUREALIGN_301:

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
      ENSUREALIGN_316:

      ; shift 5. since we do a tantoangle lookup... this maxes at 2048
      SHIFT32_MACRO_RIGHT dx ax 3
      and   al, 0FCh



      xchg  ax, bx
      mov   es, word ptr ds:[_tantoangle_segment] 
      mov   bx, word ptr es:[bx + 2] ; get just intbits..

      ;    dist = FixedDiv (dx, finesine[angle] );	

      add   bh, (ANG90_HIGHBITS SHR 8)

      mov   ax, FINESINE_SEGMENT 
      mov   es, ax
      mov   ax, bx   
      cwd                        ; dx gets sine sign
      mov   cx, dx               ; sine sign

      SHIFT_MACRO shr bx 2       ; from FFFFh to 3FFFh
      and   bl, 0FEh             ; word lookup clean low dirty bit

      mov   ax, si               ; dx:ax now becomes di:si's earlier dx
      mov   dx, di 
      mov   bx, word ptr es:[bx] ; sine low word
      ; cx set from cwd above

      call  FixedDivBSPLocal_
      ENSUREALIGN_317:

      mov       cx, cs
      mov       ds, cx
      ; store result
      mov   word ptr ds:[SELFMODIFY_set_PointToDist_result_lo+1], ax
      mov   word ptr ds:[SELFMODIFY_set_PointToDist_result_hi+1], dx

      mov   di, dx


; end calculate hyp inlined

   ; hyp in di:bx.

   pop       bx  ; angle calculated prior

   ; inlined FixedMulTrigNoShiftSine_BSPLocal_

   SHR  BX, 1

   MOV  DX, FINESINE_SEGMENT
   MOV  ES, DX
   MOV  BX, WORD PTR ES:[BX]

   MUL  BX        ; AX * BX
   MOV  AX, DI    ; DI to AX
   MOV  DI, DX    ; DI stores high result as low word
   MUL  BX        ; AX*DI
   ADD  AX, DI    ; add low word
   ; delay adc 0 carry until result in ax


   ; self modifying code for rw_distance
   mov   word ptr ds:[SELFMODIFY_set_rw_distance_lo+1], ax
   mov   word ptr ds:[SELFMODIFY_get_rw_distance_lo_1+1], ax

IF COMPISA GE COMPILE_386
ELSE
   mov   word ptr ds:[SELFMODIFY_set_rw_distance_lo_2+1], ax
   mov   word ptr ds:[SELFMODIFY_set_rw_distance_lo_2_TWOSIDED+1], ax
ENDIF
   xchg  ax, dx
   ADC   AX, 0  ; finally add carry.

   mov   word ptr ds:[SELFMODIFY_set_rw_distance_hi+1], ax
   mov   word ptr ds:[SELFMODIFY_get_rw_distance_hi_1+1], ax

   ; this can be done once per line as BP will not change.
   mov   word ptr ds:[SELFMODIFY_restore_bp_after_draw_mid+1], bp

   mov   byte ptr ds:[SELFMODIFY_skip_curseg_based_selfmodify], 0E9h  ; jmp here


SELFMODIFY_skip_curseg_based_selfmodify_TARGET:
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;;; END LINE BASED SELF MODIFY BLOCK ;;;;;;;;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

 

les       di, dword ptr cs:[_ds_p_bsp]  ; todo is DS = CS?
mov       ax, word ptr [bp + 4]  ; R_AddLine line num

stosw              ; DRAWSEG_T.drawseg_cursegvalue

lds       ax, dword ptr [bp - 020h]  ; x1 arg

stosw                            ; DRAWSEG_T.drawseg_x1
xchg      ax, bx                 ; bx gets bp - 020h
mov       ax, ds;  word ptr [bp - 01Eh]  ; x2 arg
stosw                            ; DRAWSEG_T.drawseg_x2

inc       ax

mov       ds, cx  ; restore ds = cs


mov   word ptr ds:[SELFMODIFY_cmp_di_to_rw_stopx_1+2], ax

; sp at bp - 024h

; do worldtop/worldbot calculation now
; todo selfmodify this as it's being done?
mov       dx, word ptr [bp + 8] ; frontsector ceiling
; bx floorheight
xor       ax, ax


; make dx:ax our value
SHIFT32_MACRO_RIGHT dx ax 3

SELFMODIFY_BSP_viewz_lo_7:
sub       ax, 01000h
SELFMODIFY_BSP_viewz_hi_7:
sbb       dx, 01000h
; storeworldtop

push      dx  ; bp - 024h
push      ax  ; bp - 026h

SELFMODIFY_BSP_midtexture_type:
public    SELFMODIFY_BSP_midtexture_type
mov       cl, 010h   ; need to handle top/bot texturemid cases for closed doors
dec       cl
jz        handle_topwall_mid
jns       handle_botwall_mid  ; todo

test      byte ptr [bp - 2], ML_DONTPEGBOTTOM
jne       do_peg_bottom  ; todo branch test.
dont_peg_bottom:
use_worldttop:
; dx:ax already worldtop
mov       word ptr ds:[SELFMODIFY_set_midtexturemid_lo+1], ax
mov       word ptr ds:[SELFMODIFY_set_midtexturemid_lo_stretch+1], ax

xchg      ax, dx   ; word ptr [bp - 024h]
; ax has rw_midtexturemid+2
jmp       done_with_bottom_peg

ALIGN_MACRO
handle_topwall_mid:
test      byte ptr [bp - 2], ML_DONTPEGTOP
jne       use_worldttop

calculate_toptexturemid_for_mid:
;			vtop = frontsector->floorheight +
;				   textureheight[sidedef->midtexture];

les       si, dword ptr ds:[_backsector]
mov       ax, word ptr es:[si + SECTOR_T.sec_ceilingheight]
jmp       continue_calculating_viewz

ALIGN_MACRO
handle_botwall_mid:
test      byte ptr [bp - 2], ML_DONTPEGBOTTOM
jne       use_worldttop
; use worldlow
les       si, dword ptr ds:[_backsector]
mov       ax, word ptr es:[si + SECTOR_T.sec_floorheight]
jmp       continue_calculating_viewz  ; todo is this right...
;		worldlow = backsector->floorheight - viewz;



ALIGN_MACRO
do_peg_bottom:
mov       ax, word ptr [bp + 6]
continue_calculating_viewz:
SELFMODIFY_BSP_viewz_shortheight_5:
sub       ax, 01000h
xor       cx, cx
SHIFT32_MACRO_RIGHT ax cx 3
mov       word ptr ds:[SELFMODIFY_set_midtexturemid_lo+1], cx
mov       word ptr ds:[SELFMODIFY_set_midtexturemid_lo_stretch+1], ax

; add textureheight+1

SELFMODIFY_add_texturemidheight_plus_one:
add       ax, 01000h  ; todo byte
done_with_bottom_peg:
; ax:cx has rw_midtexturemid

SELFMODIFY_BSP_siderenderrowoffset_1:
add       al, 010h

mov       byte ptr ds:[SELFMODIFY_set_midtexturemid_hi+1], al
mov       byte ptr ds:[SELFMODIFY_set_midtexturemid_hi_stretch+1], al


mov       ax, ss
mov       ds, ax

; todo this was calculated right above in a branch... combinable??
mov       dx, word ptr [bp + 6] ; frontsector floor 
xor       ax, ax

;dx:ax as our value

SHIFT32_MACRO_RIGHT dx ax 3
SELFMODIFY_BSP_viewz_lo_8:
sub       ax, 01000h
SELFMODIFY_BSP_viewz_hi_8:
sbb       dx, 01000h
push      dx ; bp - 028h
push      ax ; bp - 02Ah


mov       ax, XTOVIEWANGLE_SEGMENT   ; todo selfmodify all these?
mov       es, ax
sal       bx, 1   ; rw_x word lookup
SELFMODIFY_set_viewanglesr3_3:
mov       ax, 01000h
add       ax, word ptr es:[bx]
call      R_ScaleFromGlobalAngle_
ENSUREALIGN_311:
mov       cx, DRAWSEGS_BASE_SEGMENT
mov       es, cx
push      dx  ; bp - 02Ch
push      ax  ; bp - 02Eh
stosw             ; DRAWSEG_T.drawseg_scale1
xchg      ax, dx
stosw             ; DRAWSEG_T.drawseg_scale2
xchg      ax, dx                       ; put DX back; need it later.
mov       si, word ptr [bp - 01Eh]
cmp       si, word ptr [bp - 020h]

jg        stop_greater_than_start

; ds_p is es:di
;		ds_p->scale2 = ds_p->scale1;

stosw      ; DRAWSEG_T.drawseg_scalestep +0
xchg      ax, dx
stosw      ; DRAWSEG_T.drawseg_scalestep +2
xchg      ax, dx

mov       ax, cs
mov       ds, ax ; set ds to cs before scales_set

jmp       scales_set
ALIGN_MACRO
handle_negative_3216:

neg       ax
adc       dx, 0
neg       dx

; si zero
cmp       dx, bx
jl        one_part_divide_3216

two_part_divide_3216:
mov       es, ax
mov       ax, dx
xor       dx, dx
div       bx     ; div high
mov       si, ax ; store q1
mov       ax, es
; DX:AX contains remainder + ax...


one_part_divide_3216:
div       bx
xor       dx, dx

neg       ax
adc       dx, dx  ; dx = 0...
neg       dx
jmp div_done

ALIGN_MACRO

stop_greater_than_start:

sal       si, 1
mov       ax, XTOVIEWANGLE_SEGMENT
mov       es, ax
lods      word ptr es:[si]
SELFMODIFY_set_viewanglesr3_2:
add       ax, 01000h

call      R_ScaleFromGlobalAngle_
ENSUREALIGN_312:
mov       cx, DRAWSEGS_BASE_SEGMENT
mov       es, cx
stosw             ; +0Ah
xchg      ax, dx
stosw             ; +0Ch
xchg      ax, dx
mov       bx, word ptr [bp - 022h]

mov       si, cs
mov       ds, si ; set ds to cs before eventual scales_set
xor       si, si

sub       ax, word ptr [bp - 02Eh]
sbb       dx, word ptr [bp - 02Ch]


; inlined FastDiv3216u_    (only use in the codebase, might as well.)
; si zero default
js   handle_negative_3216

cmp dx, bx
jl one_part_divide  ; todo branch test?

two_part_divide:
mov es, ax
mov ax, dx
xor dx, dx
div bx     ; div high

mov si, ax  ; si holds this..
mov ax, es
; DX:AX contains remainder + ax...
one_part_divide:
div bx
mov dx, si  ; retrieve q1
            ; q0 already in ax

div_done:

; ds = cs here
mov       es, cx ; restore es as ds_p+2
stosw             ; +0Eh
xchg      ax, dx
stosw             ; +10h
xchg      ax, dx

ASSUME DS:R_BSP_24_TEXT
; rw_scalestep is ready. write it forward as selfmodifying code here

mov       word ptr ds:[SELFMODIFY_get_rwscalestep_lo_1+1], ax
mov       word ptr ds:[SELFMODIFY_get_rwscalestep_lo_2+1], ax
mov       word ptr ds:[SELFMODIFY_add_to_rwscale_lo_2+4], ax
xchg      ax, dx
mov       word ptr ds:[SELFMODIFY_get_rwscalestep_hi_1+1], ax
mov       word ptr ds:[SELFMODIFY_get_rwscalestep_hi_2+1], ax
mov       word ptr ds:[SELFMODIFY_add_to_rwscale_hi_2+4], ax

;ASSUME DS:DGROUP  ; lods coming up

scales_set:
public scales_set

; ds is cs here

ASSUME DS:R_BSP_24_TEXT

les       dx, dword ptr [bp + 6] ; frontsector floor and ceiling
mov       ax, es
sub       ax, dx  ; ceiling - floor
sub       ax, word ptr [bp - 0Ch]  ; subtract sectorheight
mov       al, ah
and       ax, 080h                 ; function type select.

SELFMODIFY_set_colfunc_type_mid:
cmp       al, 010h
jne       do_selfmodify_colfunc_type_mid

done_selfmodifying_colfunc_type_mid:


;		ds_p->silhouette = SIL_BOTH;
;		ds_p->sprtopclip = screenheightarray;
;		ds_p->sprbottomclip = negonearray;
;		ds_p->bsilheight = MAXINT;
;		ds_p->tsilheight = MININT;

;    drawseg_bsilheight            dw ?   ; 012h  ; set
;    drawseg_tsilheight            dw ?   ; 014h  ; set
;    drawseg_sprtopclip_offset     dw ?   ; 016h  ; set
;    drawseg_sprbottomclip_offset  dw ?   ; 018h  ; set
;    drawseg_maskedtexturecol_val  dw ?   ; 01Ah
;    drawseg_silhouette            db ?   ; 01Ch  ; set

; ds already cs

mov       si, OFFSET DEFAULT_DRAWSEG_T 
les       di, dword ptr ds:[_ds_p_bsp]
add       di, OFFSET DRAWSEG_T.drawseg_bsilheight
mov       cx, 5
rep       movsw ; write drawseg_bsilheight thru drawseg_maskedtexturecol_val
movsb           ; write drawseg_silhouette

; DS STILL CS.

do_seg_textured_stuff:

SELFMODIFY_set_offsetangle:
mov       bx, 01000h
cmp       bx, FINE_ANG180_NOSHIFT ; 04000h
jbe       offsetangle_greater_than_fineang180
neg       bx
and       bh, MOD_FINE_ANGLE_NOSHIFT_HIGHBITS

offsetangle_greater_than_fineang180:

SELFMODIFY_set_PointToDist_result_hi:
mov       cx, 01000h
SELFMODIFY_set_PointToDist_result_lo:
mov       ax, 01000h

; dx is offsetangle

cmp       bx, FINE_ANG90_NOSHIFT ; 02000h
ja        offsetangle_greater_than_fineang90

; inlined FixedMulTrigNoShiftSine_BSPLocal_

SHR  BX, 1

MOV  DX, FINESINE_SEGMENT
MOV  ES, DX
MOV  BX, WORD PTR ES:[BX]

MUL  BX        ; AX * BX
MOV  AX, CX    ; CX to AX
MOV  CX, DX    ; CX stores high result as low word
MUL  BX        ; AX*CX
ADD  AX, CX    ; add low word

; used later, dont change?
; dx:ax is rw_offset
xchg      ax, dx
ADC       AX, 0
jmp       done_with_offsetangle_stuff

ALIGN_MACRO
do_selfmodify_colfunc_type_mid:

; using loop/noloop lookup flag, look up the function setter params for stretch/nostretch for this func type and set them.
; also change pixel mul count from 10 to 12 by modifying the shift mul operation

mov       byte ptr ds:[SELFMODIFY_set_colfunc_type_mid+1], al
xchg      ax, si

; cs:0 or cs:80 points to the two configuration tabels.
; _COLFUNC_SELFMODIFY_LOOKUPTABLE
lodsw
mov       word ptr ds:[SELFMODIFY_COLFUNC_set_func_offset_stretch], ax
lodsw
mov       word ptr ds:[SELFMODIFY_COLFUNC_set_func_offset_nostretch], ax
; _COLFUNC_JUMP_LOOKUP_INSTR
; next two words are instruction words to modify
les       di,  dword ptr ds:[COLFUNC_shiftmul_selfmodify_target_lookup_mid]  ; es gets cs
movsw ; write instruction 1
movsw ; write instruction 2
jmp     done_selfmodifying_colfunc_type_mid


ALIGN_MACRO
offsetangle_greater_than_fineang90:
xchg      ax, dx  ; dx gets low
xchg      ax, cx  ; ax gets high

done_with_offsetangle_stuff:
; ax:dx is rw_offset

xor       cx, cx

SELFMODIFY_set_rw_normal_angle_shift3:
mov       bx, 01000h
sub       cx, word ptr [bp - 012h]   ; rw_angle lo from R_AddLine
sbb       bx, word ptr [bp - 010h]   ; rw_angle hi from R_AddLine


;		if (tempangle.hu.intbits < ANG180_HIGHBITS) {	
;			rw_offset.w = -rw_offset.w;
;		}
;		rw_offset.h.intbits += (sidetextureoffset + curseg_render->offset);

; use sbb bx flags to check for < 08000h (ANG180)
js        tempangle_not_smaller_than_fineang180
neg       ax
neg       dx
sbb       ax, 0
tempangle_not_smaller_than_fineang180:


SELFMODIFY_BSP_sidetextureoffset:
add       ax, 01000h
SELFMODIFY_BSP_sidesegoffset:
add       ax, 01000h 
; rw_offset ready to be written to rendersegloop:
mov   word ptr ds:[SELFMODIFY_set_cx_rw_offset_lo+1], dx
mov   word ptr ds:[SELFMODIFY_set_ax_rw_offset_hi+2], ax

;	    lightnum = (frontsector->lightlevel >> LIGHTSEGSHIFT)+extralight;

SELFMODIFY_BSP_fixedcolormap_3:
jmp SHORT seg_textured_check_done    ; dont check walllights if fixedcolormap

SELFMODIFY_BSP_fixedcolormap_3_AFTER:


mov       al, byte ptr [bp + 0Eh]   ; light level
SHIFT_MACRO shr al 4


SELFMODIFY_BSP_extralight2_plusone:
add       al, 0
cbw


SELFMODIFY_addlightnum_delta:
dec       ax  ; nop carries flags from add dl, al. dec and inc will set signed accordingly

shl       ax, 1  ; word lookup
xchg      ax, bx
mov       ax, word ptr ds:[_mul48lookup_with_scalelight_with_minusone_offset + bx]


; write walllights to rendersegloop
mov   word ptr ds:[SELFMODIFY_add_wallights+3], ax
; ? do math here and write this ahead to drawcolumn colormapsindex?

SELFMODIFY_BSP_fixedcolormap_3_TARGET:
seg_textured_check_done:

; dh (worldtop hi) always 0?



;start inlined FixedMulBSPLocal_

IF COMPISA GE COMPILE_386

   les       ax, dword ptr [bp - 026h]
   mov       dx, es
   les       bx, dword ptr [bp - 02Eh]
   mov       cx, es

   shl  ecx, 16
   mov  cx, bx
   xchg ax, dx
   shl  eax, 16
   xchg ax, dx
   imul  ecx
   shr  eax, 16



ELSE

   les       ax, dword ptr [bp - 026h]
   mov       si, es
   les       bx, dword ptr [bp - 02Eh]
   mov       cx, es
   jcxz      do_16_bit_rw_scale_mul_worldtophi_mid

   ; mul dx:ax by cx:bx

   MOV  ES, AX ; todo synergy
   MUL  BX
   MOV  DI, DX
   MOV  AX, SI
   MUL  CX
   XCHG AX, SI
   CWD
   AND  DX, BX
   SUB  SI, DX
   MUL  BX
   ADD  AX, DI
   ADC  SI, DX
   XCHG AX, CX
   CWD
   MOV  BX, ES
   AND  DX, BX
   SUB  SI, DX
   MUL  BX
   ADD  AX, CX
   ADC  DX, SI
   jmp  done_with_rw_scale_mul_worldtophi_mid

   ALIGN_MACRO
   do_16_bit_rw_scale_mul_worldtophi_mid:   

   mov  CX, SI
   mov  SI, BX   ; SI gets rw_scale copy
   
   ; mul cx:bx by --:ax
   ; first instruction was xchg ax/bx, was being done twice so cancelled out

   MUL  BX        ; AX * BX
   MOV  AX, CX    ; CX to AX
   MOV  CX, DX    ; CX stores low word
   CWD            ; S1 in DX
   AND  DX, BX    ; S1 * AX
   NEG  DX        ; 
   XCHG DX, BX    ; AX into DX, high word into BX
   MUL  DX        ; AX*CX
   ADD  AX, CX     ; add low word
   ADC  DX, BX     ; add high word

   neg       ax
   SELFMODIFY_sub__centeryfrac_4_hi_5:
   mov       cx, 01000h
   sbb       cx, dx
   add       ax, ((HEIGHTUNIT)-1) SHL 4 ; bake this in once, instead of doing it every loop.
   adc       cx, 0

   mov       word ptr ds:[SELFMODIFY_set_topfrac_hi_mid+1], cx
   mov       word ptr ds:[_cs_topfrac_lo], ax

   mov       word ptr ds:[SELFMODIFY_set_rwscale_lo_mid+1], si
   mov       word ptr ds:[SELFMODIFY_set_rwscale_hi_mid+1], es ; zero

   les       ax, dword ptr [bp - 02Ah]  ; avoid xchg ax/bx
   mov       cx, es
   ; SI has value that was in bx.

   MUL  SI        ; AX * BX
   MOV  AX, CX    ; CX to AX
   MOV  CX, DX    ; CX stores low word
   add  sp, 4 ; unpop rw_scale
   CWD            ; S1 in DX
   AND  DX, SI    ; S1 * AX
   NEG  DX        ; 
   XCHG DX, SI    ; AX into DX, high word into BX
   MUL  DX        ; AX*CX
   ADD  AX, CX     ; add low word
   ADC  DX, SI     ; add high word

   jmp       done_with_rw_scale_mul_worldbothi_mid


ENDIF

done_with_rw_scale_mul_worldtophi_mid:


;end inlined FixedMulBSPLocal_

neg       ax
SELFMODIFY_sub__centeryfrac_4_hi_4:
mov       cx, 01000h
sbb       cx, dx
add       ax, ((HEIGHTUNIT)-1) SHL 4 ; bake this in once, instead of doing it every loop.
adc       cx, 0

mov       word ptr ds:[SELFMODIFY_set_topfrac_hi_mid+1], cx
mov       word ptr ds:[_cs_topfrac_lo], ax





; this (rw_scale hi) fairly OFTEN 0. 
; ch (worldbot hi) always 0? (but often negative too thus ff)


; todo 24 bit muls?

;start inlined FixedMulBSPLocal_

IF COMPISA GE COMPILE_386

   pop       ax ; bp - 02Eh
   pop       dx ; bp - 02Ch

   mov       word ptr ds:[SELFMODIFY_set_rwscale_lo_mid+1], ax
   mov       word ptr ds:[SELFMODIFY_set_rwscale_hi_mid+1], dx

   mov       ecx, dword ptr [bp - 02Ah]


   xchg ax, dx
   shl  eax, 16
   xchg ax, dx
   imul  ecx
   shr  eax, 16



ELSE
; si not preserved

   pop       ax ; bp - 02Eh
   pop       si ; bp - 02Ch

   mov       word ptr ds:[SELFMODIFY_set_rwscale_lo_mid+1], ax
   mov       word ptr ds:[SELFMODIFY_set_rwscale_hi_mid+1], si

   les       bx, dword ptr [bp - 02Ah]
   mov       cx, es


   MOV  ES, AX ; todo synergy
   MUL  BX
   MOV  DI, DX
   MOV  AX, SI
   MUL  CX
   XCHG AX, SI
   CWD
   AND  DX, BX
   SUB  SI, DX
   MUL  BX
   ADD  AX, DI
   ADC  SI, DX
   XCHG AX, CX
   CWD
   MOV  BX, ES
   AND  DX, BX
   SUB  SI, DX
   MUL  BX
   ADD  AX, CX
   ADC  DX, SI

ENDIF

;end inlined FixedMulBSPLocal_
done_with_rw_scale_mul_worldbothi_mid:
; ds is still cs

neg       ax
mov       word ptr ds:[_cs_botfrac_lo], ax


SELFMODIFY_sub__centeryfrac_4_hi_3: ; preincremented by 1
mov       ax, 01000h ; ah known zero. dh too probably?
sbb       ax, dx
mov       word ptr ds:[SELFMODIFY_set_botfrac_hi_mid+1], ax

; mid markceiling/markfloor are true unless this check passes.
; based on this check, do R_CheckPlane and modify jmp vs fall thru in the 

SELFMODIFY_BSP_set_skyflatnum_4:
public SELFMODIFY_BSP_set_skyflatnum_4
cmp       byte ptr [bp + 0Ah], 010h
jne       continue_mark_ceiling_check


do_mark_ceiling:
; markceiling = true

mov       ax, word ptr ds:[_ceilingplaneindex]
les       dx, dword ptr [bp - 020h]   ; rw_stopx - 1 = stop
mov       cx, es
les       bx, dword ptr ds:[_ceiltop]


call      R_CheckPlaneSetCeil_ ; enters and exits with ds as cs
ENSUREALIGN_314:
mov       word ptr ds:[_ceilingplaneindex], ax

done_marking_ceiling:


SELFMODIFY_BSP_viewz_shortheight_4:
cmp       word ptr [bp + 6], 01000h
jl        do_mark_floor  ; lets force the common jump here - it has to happen somewhere and this makes space for other branches and jmp targets.

skip_mark_floor:
; rare case - we get to skip a couple things up ahead in the function.
mov       word ptr ds:[SELFMODIFY_toggle_skip_floorclip_mid], 0EBh + ((SELFMODIFY_toggle_skip_floorclip_mid_TARGET - SELFMODIFY_toggle_skip_floorclip_mid_AFTER) SHL 8)
mov       word ptr ds:[SELFMODIFY_BSP_markfloor_1],           0EBh + ((SELFMODIFY_BSP_markfloor_1_TARGET - SELFMODIFY_BSP_markfloor_1_AFTER) SHL 8)
cmp       word ptr [bp - 022h], 0
jge       at_least_one_column_to_draw ; todo work this out. also does this ever happen???
jump_to_R_RenderSegLoop_exit:
lea       sp, [bp - 6]
jmp       R_RenderSegLoop_exit   

ALIGN_MACRO
continue_mark_ceiling_check:
SELFMODIFY_BSP_viewz_shortheight_3:
cmp       word ptr [bp + 8], 01000h
jg        do_mark_ceiling
skip_mark_ceiling:
; rare case - we get to skip a couple things up ahead in the function.
mov       word ptr ds:[SELFMODIFY_toggle_skip_ceilingclip_mid], 0EBh + ((SELFMODIFY_toggle_skip_ceilingclip_mid_TARGET - SELFMODIFY_toggle_skip_ceilingclip_mid_AFTER) SHL 8)
mov       word ptr ds:[SELFMODIFY_BSP_markceiling_1],           0EBh + ((SELFMODIFY_BSP_markceiling_1_TARGET - SELFMODIFY_BSP_markceiling_1_AFTER) SHL 8)
jmp       done_marking_ceiling


ALIGN_MACRO
do_mark_floor:
; markfloor = true
mov       ax, word ptr ds:[_floorplaneindex]

les       dx, dword ptr [bp - 020h]   ; rw_stopx - 1 = stop
mov       cx, es
les       bx, dword ptr ds:[_floortop]

mov       byte ptr ds:[SELFMODIFY_setisceil + 1], 0
call      R_CheckPlane_ ; enters and exits with ds as cs
ENSUREALIGN_315:
mov       word ptr ds:[_floorplaneindex], ax

done_marking_floor:


at_least_one_column_to_draw:


ASSUME DS:R_BSP_24_TEXT
; make ds equal to cs for self modifying codes




;start inlined FixedMulBSPLocal_

IF COMPISA GE COMPILE_386
   pop       bx ; bp - 02Ah
   pop       cx ; bp - 028h
   SELFMODIFY_get_rwscalestep_lo_2:
   mov       ax, 01000h
  SELFMODIFY_get_rwscalestep_hi_2:
  mov       dx, 01000h

   shl  ecx, 16
   mov  cx, bx
   xchg ax, dx
   shl  eax, 16
   xchg ax, dx
   imul  ecx
   shr  eax, 16



ELSE
   pop       bx ; bp - 02Ah
   pop       cx ; bp - 028h
   SELFMODIFY_get_rwscalestep_lo_2:
   mov       ax, 01000h

   SELFMODIFY_get_rwscalestep_hi_2:
   mov       si, 01000h

   MOV  ES, AX
   MUL  BX
   MOV  DI, DX
   MOV  AX, SI
   MUL  CX
   XCHG AX, SI
   CWD
   AND  DX, BX
   SUB  SI, DX
   MUL  BX
   ADD  AX, DI
   ADC  SI, DX
   XCHG AX, CX
   CWD
   MOV  BX, ES
   AND  DX, BX
   SUB  SI, DX
   MUL  BX
   ADD  AX, CX
   ADC  DX, SI

ENDIF
;end inlined FixedMulBSPLocal_


; dx:ax are negative bottomstep. instead of adding the neg we sub.



mov       word ptr ds:[SELFMODIFY_add_to_bottomfrac_hi_2+4], dx
mov       word ptr ds:[SELFMODIFY_add_to_bottomfrac_lo_2+4], ax


; todo reverse these orders, so bp - 026h may be popped


;start inlined FixedMulBSPLocal_


IF COMPISA GE COMPILE_386
   pop       bx ; bp - 026h
   pop       cx ; bp - 024h

 ; todo combine
   SELFMODIFY_get_rwscalestep_lo_1:
   mov       ax, 01000h
   SELFMODIFY_get_rwscalestep_hi_1:
   mov       dx, 01000h

   shl  ecx, 16
   mov  cx, bx
   xchg ax, dx
   shl  eax, 16
   xchg ax, dx
   imul  ecx
   shr  eax, 16



ELSE
   pop       bx ; bp - 026h
   
   SELFMODIFY_get_rwscalestep_lo_1:
   mov       ax, 01000h
   ENSUREALIGN_050:
   
   pop       cx ; bp - 024h
   
   SELFMODIFY_get_rwscalestep_hi_1:
   mov  si, 01000h
   ENSUREALIGN_051:

   public ENSUREALIGN_050
   public ENSUREALIGN_051

   MOV  ES, AX
   MUL  BX
   MOV  DI, DX
   MOV  AX, SI
   MUL  CX
   XCHG AX, SI
   CWD
   AND  DX, BX
   SUB  SI, DX
   MUL  BX
   ADD  AX, DI
   ADC  SI, DX
   XCHG AX, CX
   CWD
   MOV  BX, ES
   AND  DX, BX
   SUB  SI, DX
   MUL  BX
   ADD  AX, CX
   ADC  DX, SI

ENDIF

;end inlined FixedMulBSPLocal_

; dx:ax are negative topstep. instead of adding the neg we sub.

; todo can this modify a sub and skip the neg above?

mov       word ptr ds:[SELFMODIFY_add_to_topfrac_hi_2+4], dx
mov       word ptr ds:[SELFMODIFY_add_to_topfrac_lo_2+4], ax

;  di is free up to here

;   BEGIN INLINED R_RenderSegLoop_
;   BEGIN INLINED R_RenderSegLoop_
;   BEGIN INLINED R_RenderSegLoop_
;   BEGIN INLINED R_RenderSegLoop_

R_RenderSegLoop_:
PUBLIC R_RenderSegLoop_

; ds still cs

mov   di, word ptr [bp - 020h]  ; get start_x/dc_x initial value

jmp   start_per_column_inner_loop ; jump into first iter.
ALIGN_MACRO
exit_rendersegloop:
public exit_rendersegloop
; zero out local caches.

;ASSUME DS:DGROUP
; cx, ds already cs

mov   es, cx
mov   ax, 0FFFFh
mov   di, OFFSET _segloopnextlookup
stosw ; mov   word ptr ds:[_segloopnextlookup], ax
stosw ; mov   word ptr ds:[_segloopnextlookup+2], ax
inc   ax
; zero both 
stosw ; mov   word ptr ds:[_seglooptexrepeat], ax

jmp   R_RenderSegLoop_exit     ; todo doesnt quite fit here yet.

IF COMPISA GE COMPILE_386
   ALIGN_MACRO
   jump_to_mid_no_pixels_to_draw:
   mov   cx, cs
   jmp   increment_loop_values  ; restore bp here
   ALIGN_MACRO
ENDIF

  ALIGN_MACRO

  markceildirty_mid:
  or    byte ptr ds:[SELFMODIFY_mark_planes_dirty+1], 2 ; ceiling bit
  mov   byte ptr ds:[SELFMODIFY_skip_markceildirty_mid], MOV_CL_IMM8_OPCODE  
  jmp   SHORT markceiling_done
  ALIGN_MACRO




ALIGN_MACRO

increment_loop_values_full:
pop   di  ; rw_x  always want this back

mov   cx, cs
mov   ds, cx ; cx has cs for exit_rendersegloop

increment_loop_values:       ; ; todo this seems to be rare. maybe does not need to be in a code hot spot and can be far jumped to
public increment_loop_values


;		rw_x = rw_x_base4 + xoffset;
;		if (rw_x < start_rw_x){
;			rw_x       += detailshiftitercount;
;			topfrac    += topstepshift;
;			bottomfrac += bottomstepshift;
;			rw_scale.w += rwscaleshift;
;			pixlow     += pixlowstepshift;
;			pixhigh    += pixhighstepshift;
;		}


inc   di  ; rw_x++

SELFMODIFY_cmp_di_to_rw_stopx_1:
cmp   di, 01000h
jge   exit_rendersegloop

; todo 386 dwords
SELFMODIFY_add_to_bottomfrac_lo_2:
sub   word ptr ds:[_cs_botfrac_lo], 01000h
ENSUREALIGN_060:
SELFMODIFY_add_to_bottomfrac_hi_2:
sbb   word ptr ds:[SELFMODIFY_set_botfrac_hi_mid+1], 01000h
ENSUREALIGN_061:
SELFMODIFY_add_to_topfrac_lo_2:
sub   word ptr ds:[_cs_topfrac_lo], 01000h
ENSUREALIGN_062:
SELFMODIFY_add_to_topfrac_hi_2:
sbb   word ptr ds:[SELFMODIFY_set_topfrac_hi_mid+1], 01000h
ENSUREALIGN_063:
SELFMODIFY_add_to_rwscale_lo_2:
add   word ptr ds:[SELFMODIFY_set_rwscale_lo_mid+1], 01000h
ENSUREALIGN_064:
SELFMODIFY_add_to_rwscale_hi_2:
adc   word ptr ds:[SELFMODIFY_set_rwscale_hi_mid+1], 01000h
ENSUREALIGN_065:


; todo change inner loop to work off constant di not ax?
; or possibly even bp. once we are doing pusha/popa chains, we may not use bp?

; this is right before inner loop start. due to vga plane aligmnent we might not draw pixel 0 for this plane?

start_per_column_inner_loop:
public start_per_column_inner_loop
; di is rw_x


SELFMODIFY_rewrite_bsp_out_dx_code_mid:
; quality 0 version
mov  cx, di
and  cl, 3
mov  ax, 1 ; zero ah
shl  al, cl
mov  dx, SC_DATA
out  dx, al    ; 14 bytes

done_setting_vga_plane:
PUBLIC done_setting_vga_plane


; todo find a way to clean up 8/16 bit logic and compares. 
; store only in ch/cl. possible store same pixel floor/ceiling side by side? one read, word?

                                                 ; di = rw_x
; ah already 0
cwd
mov   al, byte ptr ds:[di+OFFSET_FLOORCLIP]	 ; ax = floor
mov   dl, byte ptr ds:[di+OFFSET_CEILINGCLIP] ; dx = ceiling  = ceilingclip[rw_x]+1;

; ds is cs

dec   ax ; dec ax..

; all these y values - ceil and floorclip, and later dc_yl and dc_yh are 
; increased by one to allow 0 to viewheight+1 range instead of ff to viewheight range.
; when written to visplanes and such this must be considered

inc   dx  ; toggle order for ENSUREALIGN_001/ENSUREALIGN_002 along with inc instruction
SELFMODIFY_set_topfrac_hi_mid:
mov   cx, 01000h
ENSUREALIGN_001:

cmp   cx, dx  ; ax can be negative even if dx is not? but maybe ah is always ff?
jg    skip_yl_ceil_clip    
do_yl_ceil_clip:
mov   cx, dx
skip_yl_ceil_clip:

; at this point cx is clipped and is 1 byte 

mov   si, cx   ; si has yl...

SELFMODIFY_BSP_markceiling_1:
public SELFMODIFY_BSP_markceiling_1
SELFMODIFY_BSP_markceiling_1_AFTER = SELFMODIFY_BSP_markceiling_1 + 2

; cx is yl
; dx = top = ceilingclip[rw_x]+1;
dec   cx				; now cx = bottom = yl-1
; cx is floor, 
; the following is a forced encoding. tasm wants to do a diff one and this needs to agree with selfmodify...
db    038h, 0C1h   ; cmp   cl, al      ;   cx cannot be negative, already was inc-ed before.
jbe   skip_bottom_floorclip  ; todo is this safe? can ax be negative? cx, ax instead?
mov   cl, al ; pre-decced necessary

skip_bottom_floorclip:
cmp   cl, dl
jb    markceiling_done
les   bp, dword ptr ds:[_ceiltop]
dec   cx
mov   byte ptr es:[bp+di + vp_bottom_offset], cl
mov   cx, dx
dec   cx 
mov   byte ptr es:[bp+di], cl
SELFMODIFY_skip_markceildirty_mid:
jmp   SHORT markceildirty_mid  ; THIS_IS_A_SELFMODIFIED_INSTRUCTION_TARGET into mov cl


SELFMODIFY_BSP_markceiling_1_TARGET:

markceiling_done:

; yh = bottomfrac>>HEIGHTBITS;


SELFMODIFY_set_botfrac_hi_mid:
mov   cx, 01000h
ENSUREALIGN_002:

; ax was already decremented above. 
; jle not jl to account for it.

; cx is still floor
cmp   cx, ax
jle   skip_yh_floorclip
do_yh_floorclip:
mov   cx, ax   ; pre decced.

skip_yh_floorclip:

; at this point cx is known 1 byte


mov   bx, si  ; store yl
sub   si, cx   ; yl - yh. technically we want to know if (yh - yl) is positive then we take (200 - (yh - yl)

; cx is yh
; ax is floorclip+1
; dl is ceilingclip+1
SELFMODIFY_BSP_markfloor_1:
public SELFMODIFY_BSP_markfloor_1
SELFMODIFY_BSP_markfloor_1_AFTER = SELFMODIFY_BSP_markfloor_1 + 2
inc   cx			; THIS_IS_A_SELFMODIFIED_INSTRUCTION_TARGET top = yh + 1... + cmp cl, dl    OR  jmp    markfloor_done ; 
db  038h, 0D1h   ; cmp cl, dl with specific encoding for selfmodify

;	if (top <= ceilingclip[rw_x]){
;		top = ceilingclip[rw_x]+1;
;	}

ja    skip_top_ceilingclip
mov   cl, dl	 ; 		top = ceilingclip[rw_x]+1;  ;todo is si ok to knock out via xchg?

skip_top_ceilingclip:

;	if (top <= bottom) {
;		floortop[rw_x] = top & 0xFF;
;		floortop[rw_x+322] = bottom & 0xFF;
;	}

cmp   cl, al
ja    markfloor_done
les   bp, dword ptr ds:[_floortop]
dec   cx
mov   byte ptr es:[bp+di], cl
dec   ax
mov   byte ptr es:[bp+di + vp_bottom_offset], al
SELFMODIFY_skip_markfloordirty_mid:
jmp   SHORT markfloordirty_mid  ; THIS_IS_A_SELFMODIFIED_INSTRUCTION_TARGET into mov al


SELFMODIFY_BSP_markfloor_1_TARGET:

markfloor_done:
public  markfloor_done
; get jns check sort of for free, we need to sal anyway on fall thru
sal   si, 1        ; multiply pixel count by 2. if signed no pixels to draw
jns   jump_to_mid_no_pixels_to_draw ; had to wait until floors/ceils marked to early out.

push  di  ; store dc_x
SELFMODIFY_COLFUNC_sub_centery24_mid:
lea   ax, [bx - 010h]
push  ax

lea   dx, [si+ 398]   ; 199 - (dc_yh - dc_yl) shl 1

lea   si,  [bx + bsp_local_dc_yl_lookup_table_ - 2] ; word offset + lookup
mov   bp, word ptr ds:[si+bx]                       ; add * 80 lookup table value 

mov   ax, XTOVIEWANGLE_SEGMENT
mov   es, ax

mov   bx, di  ; copy dc_x
mov   bx, word ptr es:[bx + di]


SELFMODIFY_BSP_detailshift2minus:
sar   di, 1    ; todo would love to get rid of these. happening for every column even if shift not needed.
sar   di, 1


SELFMODIFY_BSP_add_destview_offset:
public SELFMODIFY_BSP_add_destview_offset
lea   di, [di + bp + 01000h]           ; di has destview offset  ; rare, dont align



mov   si, dx  ; 2, 2   dx already multiplied by 2
shl   si, 1   ; 4, 2
SELFMODIFY_set_pixel_count_shift_mul:
public SELFMODIFY_set_pixel_count_shift_mul
; 12 per is 01 d6 d1 e6 
; 10 per is d1 e6 01 d6 
add   si, dx  ; 6, 2     ; swap these two for 10x - 4, 8, 10 from shl, then add order swap
shl   si, 1   ; 12, 2    ; is there a way to swap just one instruction, while not adding instruction count?


; angle = MOD_FINE_ANGLE (rw_centerangle + xtoviewangle[rw_x]);

; eventually use DS here, once source_segment vars use CS?


mov   ax, FINETANGENTINNER_SEGMENT  ; maybe can be skipped if bsp is moved under here.
mov   es, ax

SELFMODIFY_set_rw_center_angle:
add   bx, 01000h  ; rare, dont align
and   bh, FINE_ANGLE_HIGH_BYTE				; MOD_FINE_ANGLE = and 0x1FFF

; temp.w = rw_offset.w - FixedMul(finetangent(angle),rw_distance);


sub   bx, FINE_TANGENT_MAX        ; bx now -2048 to 2047
sbb   bp, bp
xor   bx, bp          ; bx now 0 to 2048, bp has sign.. but table is 2048 entries.


IF COMPISA GE COMPILE_386
    ; todo or one?
   SHIFT_MACRO shl bx 2
   mov   ebx, dword ptr es:[bx]
   not   bp
   movsx ecx, bp
   sub   ebx, ecx
   xor   ebx, ecx  ;apply sign


  SELFMODIFY_set_rw_distance_hi_386_base:

  SELFMODIFY_set_rw_distance_lo = SELFMODIFY_set_rw_distance_hi_386_base+1
  SELFMODIFY_set_rw_distance_hi = SELFMODIFY_set_rw_distance_hi_386_base+3
  mov   eax, 010000000h

  imul  ebx
  shr   eax, 16
  jmp   done_with_finetanmul  ; todo remove this, once we find a place to put the below...
   ALIGN_MACRO
   markfloordirty_mid:
   or    byte ptr ds:[SELFMODIFY_mark_planes_dirty+1], 1 ; floor bit
   mov   byte ptr ds:[SELFMODIFY_skip_markfloordirty_mid], MOV_AL_IMM8_OPCODE  
   jmp   SHORT markfloor_done




ELSE

   SHIFT_MACRO shl bx 2
   test  bh, 010h

   SELFMODIFY_set_rw_distance_lo:
   public SELFMODIFY_set_rw_distance_lo
   mov   ax, 01000h
   ENSUREALIGN_066:

   les   bx, dword ptr es:[bx]


   SELFMODIFY_set_rw_distance_hi:
   mov   cx, 01000h
   ENSUREALIGN_067:
   jnz   do_32_bit_finetan_mul

   do_16_bit_mul:
   public do_16_bit_mul

   ; BX * CX:AX

   mul  bx        ; AX * BX
   mov  ax, bx    ; for next mul
   mov  bx, dx    ; store hi result
   mul  cx
   add  ax, bx    ; add previous hi into lo
   adc  dx, 0     ; es may be known 0?

   jmp  done_with_16bitmul
   ALIGN_MACRO
   markfloordirty_mid:
   or    byte ptr ds:[SELFMODIFY_mark_planes_dirty+1], 1 ; floor bit
   mov   byte ptr ds:[SELFMODIFY_skip_markfloordirty_mid], MOV_AL_IMM8_OPCODE  
   jmp   SHORT markfloor_done


   ALIGN_MACRO
   jump_to_mid_no_pixels_to_draw:
   mov   cx, cs
   jmp   increment_loop_values  ; restore bp here


   ALIGN_MACRO
   use_max_light:
   ; ugly 
   mov   bx, MAXLIGHTSCALE - 1
   jmp   do_light_write


   do_32_bit_finetan_mul:

  push  si     ; this path pushes si... 
  mov   si, es

  MUL  BX
  MOV  ES, DX


  MOV  AX, cx
  MUL  si
  XCHG AX, cx
  MUL  BX
  MOV  BX, ES
  ADD  AX, BX
  SELFMODIFY_set_rw_distance_lo_2:
  mov   bx, 01000h
  ENSUREALIGN_068:
  
  XCHG AX, si
  ADC  cx, DX

  MUL  BX
  ADD  AX, si
  ADC  DX, cx
  pop  si


   ; around here whats wrong

   ;	    texturecolumn = rw_offset-FixedMul(finetangent[angle],rw_distance);

   done_with_16bitmul:
   not   bp
   SUB   AX, bp
   SBB   DX, bp
   XOR   AX, bp ; no xor ax necessary if we flip order with add below? may require below values negged
   XOR   DX, bp
ENDIF

done_with_finetanmul:

; todo self modify the neg of this in somehow?
SELFMODIFY_set_cx_rw_offset_lo:	
add   ax, 01000h   ; cx is soon clobbered. so we only need AX?
SELFMODIFY_set_ax_rw_offset_hi:
public SELFMODIFY_set_ax_rw_offset_hi
adc   dx, 01000h


; texturecolumn = dx:ax...  or just dx (whole number)


; inlined function. 
R_GetSourceSegment0_START:
PUBLIC  R_GetSourceSegment0_START


; okay. we modify the first instruction in this argument. 
 ; if no texture is yet cached for this rendersegloop, jmp to non_repeating_texture
  ; if one is set, and not repeating, this remains a jmp to fetch the column
   ; if its a repeating texture  then we modify it to mov ax, imm16 with 2 values
   ; AND texturecol (dl) to mask (ah) then mul al to that. then add base segment.


SELFMODIFY_BSP_set_seglooptexrepeat0:
; 3 bytes. May become one of two jumps (three bytes) or mov ax, imm16 (three bytes)
jmp    non_repeating_texture_mid

; al has  heightval
; ah has  seglooptexrepeat mask

SELFMODIFY_BSP_set_seglooptexrepeat0_AFTER:
ENSUREALIGN_323:
xchg  ax, ax  ; TODO: remove: ENSUREALIGN_069 even toggle for now
and   ah, dl   ; ah has loopwidth-1 (modulo )
mul   ah       ; al has heightval

add_base_segment_and_draw_mid:  ; align target?
SELFMODIFY_add_cached_segment0:
add   ax, 01000h
ENSUREALIGN_069:

ENDP

just_do_draw_mid:
ENSUREALIGN_075:

; ds must be reset to cs returning here.

mov   ds, ax   ; set dc_source_segment
; cwd is possible here because source segment is 0x5000-0x6FFF...  clear out dl for later move to bp

cwd
;xor   dx, dx
; toggle for ENSUREALIGN_003


; CX:AX rw_scale

;	if (rw_scale.h.intbits >= 3) {
;		index = MAXLIGHTSCALE - 1;
;	} else {
;		index = rw_scale.w >> LIGHTSCALESHIFT;
;	}

SELFMODIFY_set_rwscale_hi_mid:
mov   cx, 01000h   ; todo ch is always zero...? so mov cl..?
ENSUREALIGN_003:


cmp   cl, 3
SELFMODIFY_set_rwscale_lo_mid:
mov   ax, 01000h 
ENSUREALIGN_004:

jae   use_max_light
do_lightscaleshift:

; shift 8
mov   bl, ah
mov   bh, cl
; shift 12
SHIFT_MACRO shr bx 4


do_light_write:
SELFMODIFY_add_wallights:
; bx is scalelight
; scalelight is pre-shifted 4 to save on the double sal every column.

mov   dh, byte ptr ss:[bx+01000h]         ; 8a 84 00 10 
ENSUREALIGN_070:
; dl 0 from earlier cwd.
xchg  ax, bx  ; cx:bx is proper value again.
;        set colormap offset to high byte


mov   bp, dx
; INLINED FASTDIV3232FFF_ 

; set ax:dx ffffffff

; if top 16 bits missing just do a 32 / 16
mov  ax, -1




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
   db 066h, 00Fh, 0A4h, 0C1h, 010h  ; shld ecx, eax, 0x10

   ; cx:ax is result
   test cl, cl
   mov ch, cl
   SELFMODIFY_set_midtexturemid_hi:
   mov   cl, 010h        ; dc_iscale +2 already in ch

   jz   do_stretch_draw_386_mid
         do_nostretch_draw_386_mid:

         jmp FastDiv3232FFFF_done
   ALIGN_MACRO
   do_stretch_draw_386_mid:
      xchg  ax, bx        ; dc_iscale +0  into bx
      mov   dx, si        ; jump amount into dx
      
      jmp FastDiv3232FFFF_done_stretch_386


   ALIGN_MACRO

ELSE

   test cx, cx
   jne  main_3232_div

   cwd

   xchg dx, cx   ; cx was 0, dx is FFFF
   div  bx        ; after this dx stores remainder, ax stores q1


   xchg  cx, ax   ; q1 to cx, ffff to ax  so div remainder:ffff 

   mov   ch, cl  ; dc_iscale hi 8 bits
   SELFMODIFY_set_midtexturemid_hi:
   mov   cl, 010h        ; dc_iscale +2 already in ch


   div   bx
   ; cx:ax is result 
ENDIF

   FastDiv3232FFFF_done:

; toggle for ENSUREALIGN_011
   xchg  ax, bx        ; dc_iscale +0  into bx
;   mov   bx, ax        ; dc_iscale +0  into bx


; todo what if we inlined the function right here, instead of writing selfmodifies forward to selfmodifies...
; then push return value. far jmp.
   
   ; cl:ax has 24 bits of result. 
   ; dc_iscale loaded here..
   ; di already has screen coord

   mov   dx, si  ; jmp amount

   SELFMODIFY_set_midtexturemid_lo:
   mov   si, 01000h
   ENSUREALIGN_071:

   pop   ax   ; dc_yl



   ; bp passed in
   ; pass in xlat offset for bx via bp


   db 09Ah
   SELFMODIFY_COLFUNC_set_func_offset_nostretch:
   dw DRAWCOL_OFFSET_BSP, COLORMAPS_SEGMENT
ENSUREALIGN_011:

; keep this even aligned.


; the pop bx gets replaced with ret if bottom is calling.
; todo: the bottom caller pops the same stuff. pop here and modify a later instruction instead?



jmp   increment_loop_values_full

   ALIGN_MACRO

IF COMPISA GE COMPILE_386
ELSE


   main_3232_div:
   public main_3232_div


   ; generally cx maxes out at around 5 bits of precision? bias towards shift right instead of left.  

   xor dx, dx

REPT 6
   shr cx, 1
   jz  done_shifting_3232
   rcr bx, 1
   rcr dx, 1
   shr ax, 1

ENDM

   shr cx, 1
   ; todo shouldnt fall thru here? if it does may crash with dxvide overflow down the line.

   ; store this
   ALIGN_MACRO
   done_shifting_3232:

   
   ; continue the last bit
   rcr bx, 1
   rcr dx, 1
    ; todo bench branch
   jnz do_full_div_ffff

   do_single_div_FFFF:
   ; bx has entire dividend, in 16 bits of precision


   shr ax, 1   ; shift the last ax/si


   dec  dx        ; make it 0FFFFh
   xchg ax, dx    ; ax all 1s,  dx 0 leading 1s
   div  bx

   mov  dx, si  ; jump amount
   ; cx is zero already coming in from the first shift so cx:ax is already the result.
ENDIF
   
   FastDiv3232FFFF_done_stretch:

   xchg  ax, bx        ; dc_iscale +0  into bx


   ; di already has screen coord
   
   FastDiv3232FFFF_done_stretch_386:
   pop   ax   ; dc_yl


   push cs   
   PUSH_MACRO_WITH_REG si OFFSET(increment_loop_values_full)
   

   SELFMODIFY_set_midtexturemid_hi_stretch:
   mov   cl, 010h        ; dc_iscale +2 already in ch
   SELFMODIFY_set_midtexturemid_lo_stretch:
   mov   si, 01000h
   ENSUREALIGN_076: ; todo figure out

   ; bp already set.

   ; far JUMP. pass in return addr below

   db 0EAh
   SELFMODIFY_COLFUNC_set_func_offset_stretch:
   dw DRAWCOL_OFFSET_BSP, COLORMAPS_SEGMENT
   
   ALIGN_MACRO

IF COMPISA GE COMPILE_386
ELSE


   do_full_div_ffff:
   push si

   ; cx is 0
   dec  cx      ; cx now 0FFFFh, will go into ax..

   shr  ax, 1
   xchg ax, dx  ; dx gets target value, ax gets desired cx value
   xchg ax, cx  ; ax gets -1, cx gets denominator low
   
   
   mov es, dx   ; save numlo word in es, NEEDS TO BE NOTed



   ; DX:AX:ES holds divisor...
   ; BX:CX holds dividend...

   div   bx
; stretch draw on path


   mov   word ptr ds:[_SELFMODIFY_get_qhat+1], ax     ; store qhat. use div's prefetch to juice this...

   mov   si, dx					; si stores rhat

   mul   cx   						; DX:AX = c1
; stretch draw on path


   ; c1 hi = dx, c2 lo = es (needs NOT)
   sub   dx, si      ; cmp and sub at same time... 


   jb    q1_ready_3232
   mov   si, es   ; si get numlo
   not   si
   jne   check_c1_c2_diff_3232
   cmp   ax, si
   jbe   q1_ready_3232
   check_c1_c2_diff_3232:

   ; (c1 - c2.wu > den.wu)
   sub   ax, si
   sbb   dx, 0    ; already subbed without borrow.
   cmp   dx, bx
   mov   si, 1                
   ja    qhat_subtract_2_3232
   jne   finalize_div


   ; compare low word..
   cmp   ax, cx
   jbe   finalize_div

   ; ugly but rare occurrence i think?
   qhat_subtract_2_3232:
   inc  si
   jmp finalize_div
   ALIGN_MACRO

   
   q1_ready_3232:
   mov  si, 0   ; no sub case. toggle with xor si, si for ENSUREALIGN_077
   finalize_div:
   _SELFMODIFY_get_qhat:
   mov  ax, 01000h
   ENSUREALIGN_077:

   sub  ax, si ; modify qhat by measured amount
   pop  dx ; jump amount
   jmp  FastDiv3232FFFF_done_stretch

ENDIF

ALIGN_MACRO

R_RenderSegLoop_exit:

; cx, ds, es = cs..

; ds is cs.

pop   dx  ; mov   dx, word ptr [bp - 022h]  ; stopx - startx

SELFMODIFY_restore_bp_after_draw_mid:
mov   bp, 01000h
ENSUREALIGN_072:

pop   si  ; mov   si, word ptr [bp - 020h]  ; startx
inc   dx


SELFMODIFY_toggle_skip_ceilingclip_mid:
SELFMODIFY_toggle_skip_ceilingclip_mid_AFTER = SELFMODIFY_toggle_skip_ceilingclip_mid + 2
mov   cx, dx   ; MAY BE SELF MODIFIED INTO JMP (E8) skip_ceiling_clip


; mark all floors viewheight(+1)

lea   di, [OFFSET_CEILINGCLIP + si]
SELFMODIFY_BSP_setviewheight_1:
mov   ax, 01000h
rep   stosb

done_skipping_markceiling_copy_mid:

xor   ax, ax ; ax is 0 from here on out.

SELFMODIFY_toggle_skip_floorclip_mid:
mov   cx, dx   ; MAY BE SELF MODIFIED INTO JMP (E8) skip_floor_clip
SELFMODIFY_toggle_skip_floorclip_mid_AFTER:

; mark all floors -1 (+1)
lea   di, [OFFSET_FLOORCLIP + si]

rep   stosb

; hardcoded!   
   ; SIL_BOTH, markfloor = true, markceil = true
   ;		ds_p->sprtopclip = screenheightarray;
   ;		ds_p->sprbottomclip = negonearray;

done_skipping_markfloor_copy_mid:

; clean up the self modified code of renderseg loop. 
mov   byte ptr ds:[SELFMODIFY_BSP_set_seglooptexrepeat0], 0E9h
mov   word ptr ds:[SELFMODIFY_BSP_set_seglooptexrepeat0+1], (SELFMODIFY_BSP_set_seglooptexrepeat0_TARGET - SELFMODIFY_BSP_set_seglooptexrepeat0_AFTER)

; single wall mid texture has no clipping done...


add       word ptr ds:[_ds_p_bsp], (SIZE DRAWSEG_T)
mov       dx, ss
mov       ds, dx

add       sp, 2  ; undo rest of stack
SELFMODIFY_mark_planes_dirty:
public SELFMODIFY_mark_planes_dirty 
mov       ch, 0
shr       cx, 1
jnz       mark_planes_dirty ; common case is fall thru.  ; todo is this always true for mid?

; pops on outside

ret

ALIGN_MACRO
SELFMODIFY_toggle_skip_ceilingclip_mid_TARGET:
skip_ceiling_clip:
mov       word ptr ds:[SELFMODIFY_toggle_skip_ceilingclip_mid], 0D189h ; mov cx, dx
mov       word ptr ds:[SELFMODIFY_BSP_markceiling_1],           03849h ; dec cx, cmp cl, bl
jmp       done_skipping_markceiling_copy_mid


ALIGN_MACRO
SELFMODIFY_toggle_skip_floorclip_mid_TARGET:
skip_floor_clip:
mov       word ptr ds:[SELFMODIFY_toggle_skip_floorclip_mid], 0D189h ; mov cx, dx
mov       word ptr ds:[SELFMODIFY_BSP_markfloor_1],           03841h ; inc cx; cmp cl, dl
jmp       done_skipping_markfloor_copy_mid


ALIGN_MACRO
seglooptexrepeat_mid_is_jmp:
; ds already cs
; todo make sure the word write is word aligned.
mov   word ptr ds:[SELFMODIFY_BSP_set_seglooptexrepeat0], 0E9h
mov   word ptr ds:[SELFMODIFY_BSP_set_seglooptexrepeat0+1], (SELFMODIFY_BSP_set_seglooptexrepeat0_TARGET - SELFMODIFY_BSP_set_seglooptexrepeat0_AFTER)
jmp   just_do_draw_mid



ALIGN_MACRO
mark_planes_dirty:
public mark_planes_dirty
mov      bl, JMP_SHORT_REL8_OPCODE
mov      byte ptr cs:[SELFMODIFY_skip_markceildirty_mid], bl
mov      byte ptr cs:[SELFMODIFY_skip_markfloordirty_mid], bl
mov      byte ptr cs:[SELFMODIFY_mark_planes_dirty+1], al ; still 0
mov      si, _visplaneheaders + VISPLANEHEADER_T.visplaneheader_dirty
les      bx, dword ptr cs:[_ceilingplaneindex]
or       byte ptr ds:[bx+si], ch
mov      bx, es
or       byte ptr ds:[bx+si], cl
; pops on outside

ret       

ALIGN_MACRO
   SELFMODIFY_BSP_set_seglooptexrepeat0_TARGET:
   ; start of the path.
   non_repeating_texture_mid:
   cmp   dx, word ptr ds:[_segloopnextlookup]
   jge   out_of_texture_bounds_mid
   cmp   dx, word ptr ds:[_segloopprevlookup]
   jnge  out_of_texture_bounds_mid
   xchg  ax, dx
   sub   al, byte ptr ss:[_segloopcachedbasecol]
   mul   byte ptr ds:[_segloopheightvalcache]
   jmp   add_base_segment_and_draw_mid
   ALIGN_MACRO
   out_of_texture_bounds_mid:
   ; branch nonpush with moves etc. 
   mov   ax, ss
   mov   ds, ax
   push  bx

   SELFMODIFY_BSP_set_midtexture:
   mov   ax, 01000h
   ENSUREALIGN_073:
   mov   bx, 0
   call  R_GetColumnSegment_  
   ENSUREALIGN_074:
   mov   dx, word ptr ds:[_segloopcachedsegment]
   mov   bx, cs
   mov   ds, bx
   pop   bx
   mov   word ptr ds:[SELFMODIFY_add_cached_segment0+1], dx


   ; todohigh get this dh and dl in same read?
   mov   dh, byte ptr ds:[_seglooptexrepeat]
   test  dh, dh
   je    seglooptexrepeat_mid_is_jmp
   ; modulo is seglooptexrepeat - 1
   mov   dl, byte ptr ds:[_segloopheightvalcache]
   ; todo make sure the word write is word aligned.
   mov   byte ptr ds:[SELFMODIFY_BSP_set_seglooptexrepeat0],   0B8h   ; mov ax, xxxx
   mov   word ptr ds:[SELFMODIFY_BSP_set_seglooptexrepeat0+1], dx

   jmp   just_do_draw_mid


ENDP
 

;   END INLINED R_RenderSegLoop_
;   END INLINED R_RenderSegLoop_
;   END INLINED R_RenderSegLoop_

;   END R_StoreWallRange_
;   END R_StoreWallRange_
;   END R_StoreWallRange_
;   END R_StoreWallRange_













; TWO SIDED LINE VARIANTS
; TWO SIDED LINE VARIANTS
; TWO SIDED LINE VARIANTS
; TWO SIDED LINE VARIANTS
; TWO SIDED LINE VARIANTS



ALIGN_MACRO
adjust_row_offset_TWOSIDED:
public adjust_row_offset_TWOSIDED
cbw      ; maxes at 127, ah is 0
SHIFT_MACRO shl ax 3
neg       ax  ; subtract this from the real number
add       ax, ((080h SHL 3) - 1) ; 0400h - 1 for equals case
mov       word ptr [bp - 0Ch], ax   ;  TODO make this a push. probably change the bp addr.

jmp       done_adjusting_row_offset_TWOSIDED

; begin all backsector logic
ALIGN_MACRO
PROC   R_StoreWallRangeWithBackSector_
PUBLIC R_StoreWallRangeWithBackSector_



; todo shift 4/segsrender thing here
;below are lazily populated in sector block

; todo cache floor - ceil?

; bp + 0Fh   ; backsectorlightlevel     - backsector items set by line code
; bp + 0Eh   ; frontsectorlightlevel
; bp + 0Dh   ; backsectorfloorpic       - backsector items set by line code
; bp + 0Ch   ; frontsectorfloorpic
; bp + 0Bh   ; backsectorceilingpic     - backsector items set by line code
; bp + 0Ah   ; frontsectorceilingpic
; bp + 8     ; frontsectorceilingheight
; bp + 6     ; frontsectorfloorheight

;below are pushed in R_AddLine_
; bp + 4     ; linenum for R_AddLine_
; bp + 2     ; loop counter for R_AddLine_
; bp - 0     ; bp pushed from R_AddLine
; bp - 2     ; lineflags
; bp - 4     ; curlineside
; bp - 6     ; curseglinedef
; bp - 8     ; curlinesidedef
; bp - 0Ah   ; curseg_render
; bp - 0Ch   ; lazily calculated 128 - siderowoffset (nonloop draw height threshhold)
; bp - 0Eh   ; unused for now? push something else
; bp - 010h  ; rw_angle hi from R_AddLine
; bp - 012h  ; rw_angle lo from R_AddLine

; func return and preserved vars. TODO pusha/popa support with constant for 8088 
; bp - 014h  ; return address from R_StoreWallRange_
; bp - 016h  ; PUSHed bx
; bp - 018h  ; PUSHed cx
; bp - 01Ah  ; PUSHed si
; bp - 01Ch  ; PUSHed di
; bp - 01Eh  ; dx arg (no need to pop)
; bp - 020h  ; ax arg (no need to pop)

; pushed stuff
; bp - 022h  ; stop - start   ; last pushed thing. todo push others.


; bp - 024h  ; worldtop hi , then unpopped
; bp - 026h  ; worldtop lo , then unpopped
; bp - 028h  ; worldbottom hi , then unpopped
; bp - 02Ah  ; worldbottom lo , then unpopped

; bp - 02Ch  ; rw_scale hi , then unpopped
; bp - 02Eh  ; rw_scale lo , then unpopped
; todo revisit order
; bp - 02Fh  ; markceiling, then unpopped
; bp - 030h  ; markfloor, then unpopped




push      dx ; bp - 01Eh
push      ax ; bp - 020h

sub       dx, ax
push      dx ; bp - 022h   stop - start. used often. ; todo: maybe we get this for free elsewhere without this sub?

mov       cx, cs


;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;; START SECTOR BASED SELF MODIFY BLOCK ;;;;;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;


SELFMODIFY_skip_frontsector_based_selfmodify_TWOSIDED:
mov       bl, (SELFMODIFY_skip_frontsector_based_selfmodify_TARGET_TWOSIDED - SELFMODIFY_skip_frontsector_based_selfmodify_AFTER_TWOSIDED)  ;  selfmodifies into mov bl, imm8
SELFMODIFY_skip_frontsector_based_selfmodify_AFTER_TWOSIDED:

; here we lazily set all front sector fields.
; backsector fields must be set afterwards.

; bp + 6   ; frontsectorfloorheight
; bp + 8   ; frontsectorceilingheight
; bp + 0Ah   ; frontsectorceilingpic
; bp + 0Bh   ; backsectorceilingpic     - backsector items set by line code
; bp + 0Ch     ; frontsectorfloorpic
; bp + 0Dh     ; backsectorfloorpic       - backsector items set by line code
; bp + 0Eh     ; frontsectorlightlevel
; bp + 0Fh     ; backsectorlightlevel     - backsector items set by line code

lea       di, [bp + 6]
mov       dx, ss
mov       es, dx
lds       si, dword ptr cs:[_frontsector]

; si = frontsector
movsw     ; bp + 6 frontsectorfloorheight
movsw     ; bp + 8 frontsectorceilingheight
lodsw
xchg       al, ah
stosw     ; bp + 0Ah  gets frontsectorceilingpic
mov       al, ah
stosw     ; bp + 0Ch gets frontsectorceilingheight
mov       al, byte ptr ds:[si + (SECTOR_T.sec_lightlevel - SECTOR_T.sec_validcount)]
stosb     ; bp + 0Eh frontsectorceilingheight


mov       ds, dx

mov       al, 0EBh
mov       byte ptr cs:[SELFMODIFY_skip_frontsector_based_selfmodify], al  ; jmp here
mov       byte ptr cs:[SELFMODIFY_skip_frontsector_based_selfmodify_TWOSIDED], al  ; jmp here

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;;; END SECTOR BASED SELF MODIFY BLOCK ;;;;;;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
SELFMODIFY_skip_frontsector_based_selfmodify_TARGET_TWOSIDED:

; todo modify the sector skip to skip both?
; or jump out and back to do inits instead of jump past?
; bench!


;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;;; START LINE BASED SELF MODIFY BLOCK ;;;;;;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

; note - line jumps past sector, but falls thru to sector check
; sector can not change without line changing.

; todo also skip sector selfmodifies lazily

SELFMODIFY_skip_curseg_based_selfmodify_topbot:
mov       bx, (SELFMODIFY_skip_curseg_based_selfmodify_topbot_TARGET - SELFMODIFY_skip_curseg_based_selfmodify_topbot_AFTER)  ;  selfmodifies into mov bx, imm
SELFMODIFY_skip_curseg_based_selfmodify_topbot_AFTER:
public  SELFMODIFY_skip_curseg_based_selfmodify_topbot_AFTER
mov       bx, word ptr [bp - 0Ah]  ; curseg_render     ; turns into a jump past selfmodifying code once this next code block runs. 
mov       ax, word ptr ds:[bx + SEG_RENDER_T.sr_offset]  ; can be up to 512 i think.
mov       word ptr cs:[SELFMODIFY_BSP_sidesegoffset_TWOSIDED+1], ax


mov       si, word ptr [bp - 8]  ; SEG_RENDER_T.sr_sidedefOffset preshifted 2


mov       al, byte ptr ds:[si + _sides_render + SIDE_RENDER_T.sr_rowoffset]
mov       byte ptr cs:[SELFMODIFY_BSP_siderenderrowoffset_2_TWOSIDED+1], al


test      al, al
jnz       adjust_row_offset_TWOSIDED
; todo calculate this in upper frame.
mov       word ptr [bp - 0Ch], (080h SHL 3) - 1 ; 0400h - 1 for equals case   ;  TODO make this a push. probably change the bp addr.
done_adjusting_row_offset_TWOSIDED:



shl       si, 1


les       bx, dword ptr ds:[bx + SEG_RENDER_T.sr_v1Offset]   ; v1
mov       di, es                                             ; v2

mov       ds, word ptr ds:[_VERTEXES_SEGMENT_PTR]


les       bx, dword ptr ds:[bx] ;v1.x
mov       ax, es

mov       word ptr cs:[SELFMODIFY_BSP_v1x_TWOSIDED+1], bx
mov       word ptr cs:[SELFMODIFY_BSP_v1y_TWOSIDED+1], ax

sub       ax, word ptr ds:[di + VERTEX_T.v_y]
mov       dl, 048h  ; dec ax
je        v2_y_equals_v1_y_TWOSIDED
sub       bx, word ptr ds:[di + VERTEX_T.v_x]
mov       dl, 090h  ; nop
jne       v2_y_not_equals_v1_y_TWOSIDED
mov       dl, 040h  ; inc ax
v2_y_not_equals_v1_y_TWOSIDED:
v2_y_equals_v1_y_TWOSIDED:
public v2_y_equals_v1_y_TWOSIDED

mov       byte ptr cs:[SELFMODIFY_addlightnum_delta_TWOSIDED], dl
; check for backsector and load side texture data
; bx, dx, di free...

   mov       ax, TEXTURETRANSLATION_SEGMENT
   mov       es, ax

   ; default jump locations for backsecnum == null


   ; note: BX free now


   mov       ax, SIDES_SEGMENT
   mov       ds, ax


   ; two sides wall may have bottom and top textures


   ; read all the sides fields now. ;preshift them as they are word lookups

   lodsw     ; side toptexture
   test      ax, ax
   jz        skip_toptex_selfmodify
   xchg      ax, di

   mov       al, byte ptr es:[di + TEXTUREHEIGHTS_OFFSET_IN_TEXTURE_TRANSLATION]
   cbw
   sal       di, 1
   inc       ax
   mov       word ptr cs:[SELFMODIFY_add_texturetopheight_plus_one+2], ax

   push      word ptr es:[di]
   pop       word ptr cs:[SELFMODIFY_settoptexturetranslation_lookup+1]

   
   skip_toptex_selfmodify:
   lodsw     ; side bottexture  ; faster to just do it than branch?
   xchg      ax, di
   sal       di, 1
   push      word ptr es:[di]
   pop       word ptr cs:[SELFMODIFY_setbottexturetranslation_lookup+1]


   lodsw     ; side midtexture
   test      ax, ax

   ; create jmp instruction
   mov       al, 0EBh   ; jmp rel 8
   jz        finish_midtex_selfmodify_TWOSIDED

   mov       al, 0B0h   ; mov al, imm8

finish_midtex_selfmodify_TWOSIDED:

   ; set some jumps and instructions based on secnumnull, midtexture
   mov       byte ptr cs:[SELFMODIFY_has_midtexture_or_not], al  ; todo i think this can be gone


   


   lodsw     ; textureoffset 
   mov       word ptr cs:[SELFMODIFY_BSP_sidetextureoffset_TWOSIDED+1], ax
   mov       cx, FIXED_DS_SEGMENT
   mov       ds, cx  ; restore ds..

   mov       si, word ptr [bp - 6]
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

   mov       bx, word ptr [bp + 4]
   sal       bx, 1       ;  curseg word lookup

   mov       ax, word ptr ds:[bx+_seg_normalangles]
   mov       word ptr cs:[SELFMODIFY_sub_rw_normal_angle_1+1], ax
   xchg      ax, si

   SELFMODIFY_set_viewanglesr3_1_TWOSIDED:
   mov       ax, 01000h
   ;add       ah, 8  ; preadded
   sub       ax, si
   and       ah, FINE_ANGLE_HIGH_BYTE

   ; set centerangle in rendersegloop
   mov       word ptr cs:[SELFMODIFY_set_rw_center_angle_TWOSIDED+2], ax
   xchg      ax, si
   SHIFT_MACRO shl ax SHORTTOFINESHIFT
   mov       word ptr cs:[SELFMODIFY_set_rw_normal_angle_shift3_TWOSIDED+1], ax


   ;	offsetangle = (abs((rw_normalangle_shiftleft3) - (rw_angle1.hu.intbits)) >> 1) & 0xFFFC;
   sub       ax, word ptr [bp - 010h]   ; rw_angle hi from R_AddLine
   cwd       
   xor       ax, dx		; abs by sign bits
   sub       ax, dx
   sar       ax, 1

   and       al, 0FCh
   mov       word ptr cs:[SELFMODIFY_set_offsetangle_TWOSIDED+1], ax
   mov       si, FINE_ANG90_NOSHIFT
   sub       si, ax 

; calculate hyp inlined

      push  si

      ;    dx = labs(x.w - viewx.w);
      ;  x = ax register
      ;  y = dx

      SELFMODIFY_BSP_v1x_TWOSIDED:
      mov       cx, 01000h
      SELFMODIFY_BSP_v1y_TWOSIDED:
      mov       dx, 01000h

      xor   bx, bx
      xor   ax, ax

      ; DX:AX = y
      ; CX:BX = x
      SELFMODIFY_BSP_viewx_lo_2_TWOSIDED:
      sub   bx, 01000h
      SELFMODIFY_BSP_viewx_hi_2_TWOSIDED:
      sbb   cx, 01000h

      SELFMODIFY_BSP_viewy_lo_2_TWOSIDED:
      sub   ax, 01000h
      SELFMODIFY_BSP_viewy_hi_2_TWOSIDED:
      sbb   dx, 01000h


      or    cx, cx
      jge   skip_x_abs_TWOSIDED
      neg   bx
      adc   cx, 0
      neg   cx
      skip_x_abs_TWOSIDED:

      or    dx, dx
      jge   skip_y_abs_TWOSIDED
      neg   ax
      adc   dx, 0
      neg   dx
      skip_y_abs_TWOSIDED:

      ;    if (dy>dx) {

      cmp   dx, cx
      jg    swap_x_y_TWOSIDED
      jne   skip_swap_x_y_TWOSIDED
      cmp   ax, bx
      jbe   skip_swap_x_y_TWOSIDED

      swap_x_y_TWOSIDED:
      xchg  dx, cx
      xchg  ax, bx
      skip_swap_x_y_TWOSIDED:

      ;	angle = (tantoangle[ FixedDiv(dy,dx)>>DBITS ].hu.intbits+ANG90_HIGHBITS) >> SHORTTOFINESHIFT;

      ; save dx (var not register)

      mov   si, bx
      mov   di, cx

      call  FixedDivBSPLocal_
      ENSUREALIGN_302:

      ; shift 5. since we do a tantoangle lookup... this maxes at 2048
      SHIFT32_MACRO_RIGHT dx ax 3
      and   al, 0FCh



      xchg  ax, bx
      mov   es, word ptr ds:[_tantoangle_segment] 
      mov   bx, word ptr es:[bx + 2] ; get just intbits..

      ;    dist = FixedDiv (dx, finesine[angle] );	

      add   bh, (ANG90_HIGHBITS SHR 8)

      mov   ax, FINESINE_SEGMENT 
      mov   es, ax
      mov   ax, bx   
      cwd                        ; dx gets sine sign
      mov   cx, dx               ; sine sign

      SHIFT_MACRO shr bx 2       ; from FFFFh to 3FFFh
      and   bl, 0FEh             ; word lookup clean low dirty bit

      mov   ax, si               ; dx:ax now becomes di:si's earlier dx
      mov   dx, di 
      mov   bx, word ptr es:[bx] ; sine low word
      ; cx set from cwd above

      call  FixedDivBSPLocal_
      ENSUREALIGN_303:


      mov       cx, cs
      mov       ds, cx

      ; store result
      mov   word ptr ds:[SELFMODIFY_set_PointToDist_result_lo_TWOSIDED+1], ax
      mov   word ptr ds:[SELFMODIFY_set_PointToDist_result_hi_TWOSIDED+1], dx

      mov   di, dx


; end calculate hyp inlined

   ; hyp in di:bx.

      pop       bx  ; angle calculated prior
   ; inlined FixedMulTrigNoShiftSine_BSPLocal_

      SHR  BX, 1

      MOV  DX, FINESINE_SEGMENT
      MOV  ES, DX
      MOV  BX, WORD PTR ES:[BX]

      MUL  BX        ; AX * BX
      MOV  AX, DI    ; CX to AX
      MOV  DI, DX    ; CX stores high result as low word
      MUL  BX        ; AX*CX
      ADD  AX, DI    ; add low word
      ; delay adc 0 carry until result in ax





   ; self modifying code for rw_distance
   mov   word ptr ds:[SELFMODIFY_set_rw_distance_lo_topbot+1], ax
   mov   word ptr ds:[SELFMODIFY_get_rw_distance_lo_1+1], ax ; ??
   xchg  ax, dx
   ADC   AX, 0
   mov   word ptr ds:[SELFMODIFY_set_rw_distance_hi_topbot+1], ax
   mov   word ptr ds:[SELFMODIFY_get_rw_distance_hi_1+1], ax ; ?? 


  ; this can be done once per line as BP will not change.
   mov   word ptr ds:[SELFMODIFY_restore_bp_after_draw_topbot+1], bp



   mov   byte ptr ds:[SELFMODIFY_skip_curseg_based_selfmodify_topbot], 0E9h  ; jmp here next run...

SELFMODIFY_skip_curseg_based_selfmodify_topbot_TARGET:
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;;; END LINE BASED SELF MODIFY BLOCK ;;;;;;;;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

 


les       di, dword ptr ds:[_ds_p_bsp]
mov       ax, word ptr [bp + 4]  ; R_AddLine line num

stosw              ; DRAWSEG_T.drawseg_cursegvalue

lds       ax, dword ptr [bp - 020h]  ; x1 arg

stosw                            ; DRAWSEG_T.drawseg_x1
xchg      ax, bx                 ; bx gets bp - 020h
mov       ax, ds;  word ptr [bp - 01Eh]  ; x2 arg
stosw                            ; DRAWSEG_T.drawseg_x2

inc       ax

mov       ds, cx


mov   word ptr ds:[SELFMODIFY_cmp_di_to_rw_stopx_TWOSIDED+2], ax


sub   ax, bx   ; stop - start
shr   ax, 1    ; byte copies not word copies
adc   al, ah    ; round up. ah should be zero.
mov   word ptr ds:[SELFMODIFY_set_cx_to_count_1_TWOSIDED+1], ax
mov   word ptr ds:[SELFMODIFY_set_cx_to_count_2_TWOSIDED+1], ax

; sp at bp - 024h


; do worldtop/worldbot calculation now
; todo selfmodify this as it's being done?
mov       dx, word ptr [bp + 8] ; frontsector ceiling

; bx floorheight

xor       ax, ax

; zero out
mov       byte ptr ds:[SELFMODIFY_check_for_any_tex_TWOSIDED+1], al


; make dx:ax our value
SHIFT32_MACRO_RIGHT dx ax 3


SELFMODIFY_BSP_viewz_lo_7_TWOSIDED:
sub       ax, 01000h
SELFMODIFY_BSP_viewz_hi_7_TWOSIDED:
sbb       dx, 01000h
; storeworldtop

push      dx  ; bp - 024h
push      ax  ; bp - 026h



mov       ax, ss
mov       ds, ax

mov       dx, word ptr [bp + 6] ; frontsector floor 
xor       ax, ax


; zero out maskedtexture 
mov       byte ptr cs:[_maskedtexture_bsp], al  ; todo is it necessary to write up here?
; default to 0



;dx:ax as our value

SHIFT32_MACRO_RIGHT dx ax 3
SELFMODIFY_BSP_viewz_lo_8_TWOSIDED:
sub       ax, 01000h
SELFMODIFY_BSP_viewz_hi_8_TWOSIDED:
sbb       dx, 01000h
push      dx ; bp - 028h
push      ax ; bp - 02Ah



mov       ax, XTOVIEWANGLE_SEGMENT   ; todo selfmodify all these?
mov       cx, es  ; store ds_p+2 segment
mov       es, ax
sal       bx, 1   ; rw_x word lookup
SELFMODIFY_set_viewanglesr3_3_TWOSIDED:
mov       ax, 01000h
add       ax, word ptr es:[bx]
call      R_ScaleFromGlobalAngle_
ENSUREALIGN_305:
mov       cx, DRAWSEGS_BASE_SEGMENT
mov       es, cx
push      dx  ; bp - 02Ch  ; 0000
push      ax  ; bp - 02Eh  ; 60b9
stosw             ; DRAWSEG_T.drawseg_scale1
xchg      ax, dx
stosw             ; DRAWSEG_T.drawseg_scale2
xchg      ax, dx                       ; put DX back; need it later.
mov       si, word ptr [bp - 01Eh]
cmp       si, word ptr [bp - 020h]

jg        stop_greater_than_start_TWOSIDED

; ds_p is es:di
;		ds_p->scale2 = ds_p->scale1;

stosw      ; DRAWSEG_T.drawseg_scalestep +0
xchg      ax, dx
stosw      ; DRAWSEG_T.drawseg_scalestep +2
xchg      ax, dx

mov       ax, cs
mov       ds, ax ; set ds to cs before scales_set

jmp       scales_set_TWOSIDED
ALIGN_MACRO
handle_negative_3216_TWOSIDED:

neg       ax
adc       dx, 0
neg       dx

; si zero
cmp       dx, bx
jl        one_part_divide_3216_TWOSIDED

two_part_divide_3216_TWOSIDED:
mov       es, ax
mov       ax, dx
xor       dx, dx
div       bx     ; div high
mov       si, ax ; store q1
mov       ax, es
; DX:AX contains remainder + ax...


one_part_divide_3216_TWOSIDED:
div       bx
xor       dx, dx

neg       ax
adc       dx, dx  ; dx = 0...
neg       dx

jmp div_done_TWOSIDED
ALIGN_MACRO

stop_greater_than_start_TWOSIDED:

sal       si, 1
mov       ax, XTOVIEWANGLE_SEGMENT
mov       es, ax
lods      word ptr es:[si]
SELFMODIFY_set_viewanglesr3_2_TWOSIDED:
add       ax, 01000h
call      R_ScaleFromGlobalAngle_
ENSUREALIGN_306:
mov       cx, DRAWSEGS_BASE_SEGMENT
mov       es, cx
stosw             ; +0Ah
xchg      ax, dx
stosw             ; +0Ch
xchg      ax, dx
mov       bx, word ptr [bp - 022h]

mov       si, cs
mov       ds, si ; set ds to cs before eventual scales_set
xor       si, si ; si zero by default..

sub       ax, word ptr [bp - 02Eh]
sbb       dx, word ptr [bp - 02Ch]


; inlined FastDiv3216u_    (only use in the codebase, might as well.)

js   handle_negative_3216_TWOSIDED
cmp       dx, bx
jl        one_part_divide_TWOSIDED

two_part_divide_TWOSIDED:
mov       es, ax
mov       ax, dx
xor       dx, dx
div       bx     ; div high

mov       si, ax  ; si holds this..
mov       ax, es
; DX:AX contains remainder + ax...
one_part_divide_TWOSIDED:
div       bx
mov       dx, si  ; retrieve q1
            ; q0 already in ax



div_done_TWOSIDED:

; ds = cs here



mov       es, cx ; restore es as ds_p+2
stosw             ; +0Eh
xchg      ax, dx
stosw             ; +10h
xchg      ax, dx

ASSUME DS:R_BSP_24_TEXT
; rw_scalestep is ready. write it forward as selfmodifying code here

mov       word ptr ds:[SELFMODIFY_get_rwscalestep_lo_1_TWOSIDED+1], ax
mov       word ptr ds:[SELFMODIFY_get_rwscalestep_lo_2_TWOSIDED+1], ax
mov       word ptr ds:[SELFMODIFY_get_rwscalestep_lo_3_TWOSIDED+1], ax
mov       word ptr ds:[SELFMODIFY_get_rwscalestep_lo_4_TWOSIDED+1], ax
mov       word ptr ds:[SELFMODIFY_add_rwscale_lo_TWOSIDED+4], ax


xchg      ax, dx
mov       word ptr ds:[SELFMODIFY_get_rwscalestep_hi_1_TWOSIDED+1], ax
mov       word ptr ds:[SELFMODIFY_get_rwscalestep_hi_2_TWOSIDED+1], ax
mov       word ptr ds:[SELFMODIFY_get_rwscalestep_hi_3_TWOSIDED+1], ax
mov       word ptr ds:[SELFMODIFY_get_rwscalestep_hi_4_TWOSIDED+1], ax


mov       word ptr ds:[SELFMODIFY_add_rwscale_hi_TWOSIDED+4], ax



; todo change these in 386 mode to shld?


;ASSUME DS:DGROUP  ; lods coming up



scales_set_TWOSIDED:
public scales_set_TWOSIDED

; nomidtexture. this will be checked before top/bot, have to set it to 0.


; short_height_t backsectorfloorheight = backsector->floorheight;
; short_height_t backsectorceilingheight = backsector->ceilingheight;
; uint8_t backsectorceilingpic = backsector->ceilingpic;
; uint8_t backsectorfloorpic = backsector->floorpic;
; uint8_t backsectorlightlevel = backsector->lightlevel;


; if two sided:
 ; noloop top if:
  ; wall height < 128. that means fronsector.ceiling - backsector.ceiling < 128

 ; noloop bot if:
  ; wall height < 128. that means backsector.floor - front.floor < 128


lds       si, dword ptr ds:[_backsector]
lodsw     ; floorheight
xchg      ax, cx

lodsw     ; ceilingheight
mov       word ptr cs:[SELFMODIFY_get_backsector_ceilingheight+1], ax
xchg      ax, di   ; store for later

lodsw     ; floor, ceil pics
mov       byte ptr [bp + 0Dh], al
mov       byte ptr [bp + 0Bh], ah
;todo clean this up with struct fields
mov       al, byte ptr ds:[si + (SECTOR_T.sec_lightlevel - SECTOR_T.sec_validcount)]
mov       byte ptr [bp + 0Fh], al


;		ds_p->sprtopclip_offset = ds_p->sprbottomclip_offset = 0;
;		ds_p->silhouette = 0;

les       bx, dword ptr [bp + 6]
mov       dx, es ;      [bp + 8]

; todo les stosw movsw?
lds       si, dword ptr cs:[_ds_p_bsp]
xor       ax, ax
mov       word ptr ds:[si + DRAWSEG_T.drawseg_maskedtexturecol_val], NULL_TEX_COL  ; set here instead of earlier as in c code. may later be updated
mov       word ptr ds:[si + DRAWSEG_T.drawseg_sprbottomclip_offset], ax
mov       word ptr ds:[si + DRAWSEG_T.drawseg_sprtopclip_offset], ax
mov       byte ptr ds:[si + DRAWSEG_T.drawseg_silhouette], al ; SIL_NONE

; bx frontsectorfloorheight
; cx backsectorfloorheight
; dx frontsectorceilingheight
; di backsectorceilingheight
; si ds_p
; 


; ds:si is ds_p
;		if (frontsectorfloorheight > backsectorfloorheight) {


mov       ax, cx  ; working register.
sub       ax, bx
jl        set_bsilheight_to_frontsectorfloorheight

; backsector floor is higher than frontsector floor. so we will see the wall rendered.
; if its less than 128 tall (minus tex top offset etc) then it wont loop
sub       ax, word ptr [bp - 0Ch]
mov       al, ah
and       ax, 080h
SELFMODIFY_set_colfunc_type_bot:
cmp       al, 010h
jne       do_selfmodify_colfunc_type_bot


done_with_selfmodify_colfunc_type_bot:

;		} else if (backsectorfloorheight > viewz_shortheight) {
SELFMODIFY_BSP_viewz_shortheight_2:
cmp       cx, 01000h
jle       bsilheight_set

mov       ax, MAXSHORT
jmp       set_bsilheight

ALIGN_MACRO
do_selfmodify_colfunc_type_bot:
; todo set bot vals here?

push      si  ; todo pushpop si once ?


; using loop/noloop lookup flag, look up the function setter params for stretch/nostretch for this func type and set them.
mov       si, cs
mov       ds, si
mov       byte ptr ds:[SELFMODIFY_set_colfunc_type_bot+1], al

xchg      ax, si

; todo is si and lodsw pattern better?

lodsw
mov       word ptr ds:[SELFMODIFY_set_bot_lookup_offset_setter_withstretch_funcaddr_1+4], ax
IF COMPISA GE COMPILE_386
ELSE
mov       word ptr ds:[SELFMODIFY_set_bot_lookup_offset_setter_withstretch_funcaddr_2+4], ax
ENDIF
lodsw
mov       word ptr ds:[SELFMODIFY_set_bot_lookup_offset_setter_nostretch_funcaddr+4], ax

xchg      ax, di ; backup di in ax
add       si, 4
les       di,  dword ptr ds:[COLFUNC_shiftmul_selfmodify_target_lookup_bot]  ; es gets cs
movsw ; write instruction 1
movsw ; write instruction 2
xchg      ax, di ; restore di from ax

pop       si

mov       ax, DRAWSEGS_BASE_SEGMENT
mov       ds, ax
SELFMODIFY_BSP_viewz_shortheight_6:
cmp       cx, 01000h
jle       bsilheight_set

mov       ax, MAXSHORT
jmp       set_bsilheight
ALIGN_MACRO
do_selfmodify_colfunc_type_top:
push      si  ; todo pushpop si once ?


; using loop/noloop lookup flag, look up the function setter params for stretch/nostretch for this func type and set them.

mov       si, cs
mov       ds, si
mov       byte ptr ds:[SELFMODIFY_set_colfunc_type_top+1], al

xchg      ax, si

lodsw
mov       word ptr ds:[SELFMODIFY_set_top_lookup_offset_setter_withstretch_funcaddr_1+4], ax
IF COMPISA GE COMPILE_386
ELSE
mov       word ptr ds:[SELFMODIFY_set_top_lookup_offset_setter_withstretch_funcaddr_2+4], ax
ENDIF
lodsw
mov       word ptr ds:[SELFMODIFY_set_top_lookup_offset_setter_nostretch_funcaddr+4], ax
; todo is si and lodsw pattern better?
xchg      ax, di ; backup di in ax
add       si, 4
les       di,  dword ptr ds:[COLFUNC_shiftmul_selfmodify_target_lookup_top]  ; es gets cs
movsw ; write instruction 1
movsw ; write instruction 2
xchg      ax, di ; restore di from ax

pop       si

mov       ax, DRAWSEGS_BASE_SEGMENT
mov       ds, ax
SELFMODIFY_BSP_viewz_shortheight_7:
cmp       di, 01000h
jge       tsilheight_set

mov       ax, MINSHORT
jmp       set_tsilheight


ALIGN_MACRO
set_bsilheight_to_frontsectorfloorheight:
mov       ax, bx
set_bsilheight:
mov       byte ptr ds:[si + DRAWSEG_T.drawseg_silhouette], SIL_BOTTOM ; SIL_BOTTOM
mov       word ptr ds:[si + DRAWSEG_T.drawseg_bsilheight], ax

bsilheight_set:

mov       ax, dx  ; working register.

sub       ax, di  ; ceilingheight
jle       set_tsilheight_to_frontsectorceilingheight

sub       ax, word ptr [bp - 0Ch]
mov       al, ah
and       ax, 080h

SELFMODIFY_set_colfunc_type_top:
cmp       al, 010h
jne       do_selfmodify_colfunc_type_top


SELFMODIFY_BSP_viewz_shortheight_1:
cmp       di, 01000h
jge       tsilheight_set
set_tsilheight_to_minshort:
mov       ax, MINSHORT
jmp       set_tsilheight
ALIGN_MACRO
set_tsilheight_to_frontsectorceilingheight:
mov       ax, dx
set_tsilheight:
or        byte ptr ds:[si + DRAWSEG_T.drawseg_silhouette], SIL_TOP
mov       word ptr ds:[si + DRAWSEG_T.drawseg_tsilheight], ax
tsilheight_set:


; if (backsectorceilingheight <= frontsectorfloorheight) {

cmp       di, bx
jg        back_ceiling_greater_than_front_floor

; ds_p->sprbottomclip_offset = offset_negonearray;
; ds_p->bsilheight = MAXSHORT;
; ds_p->silhouette |= SIL_BOTTOM;

mov       word ptr ds:[si + DRAWSEG_T.drawseg_sprbottomclip_offset], OFFSET_NEGONEARRAY
mov       word ptr ds:[si + DRAWSEG_T.drawseg_bsilheight], MAXSHORT
or        byte ptr ds:[si + DRAWSEG_T.drawseg_silhouette], SIL_BOTTOM
back_ceiling_greater_than_front_floor:

; if (backsectorfloorheight >= frontsectorceilingheight) {
; ax is backsectorfloorheight

cmp       cx, dx
jl        back_floor_less_than_front_ceiling

; ds_p->sprtopclip_offset = offset_screenheightarray;
; ds_p->tsilheight = MINSHORT;
; ds_p->silhouette |= SIL_TOP;
mov       word ptr ds:[si + DRAWSEG_T.drawseg_sprtopclip_offset], OFFSET_SCREENHEIGHTARRAY
mov       word ptr ds:[si + DRAWSEG_T.drawseg_tsilheight], MINSHORT
or        byte ptr ds:[si + DRAWSEG_T.drawseg_silhouette], SIL_TOP
back_floor_less_than_front_ceiling:

; SET_FIXED_UNION_FROM_SHORT_HEIGHT(worldhigh, backsectorceilingheight);
; worldhigh.w -= viewz.w;
; SET_FIXED_UNION_FROM_SHORT_HEIGHT(worldlow, backsectorfloorheight);
; worldlow.w -= viewz.w;

mov       si, cs
mov       ds, si   ; set ds to cs.

xor       si, si
; can these shifts be avoided and math propagated accordingly? seems hard
SHIFT32_MACRO_RIGHT di si 3

SELFMODIFY_BSP_viewz_lo_3:
sub       si, 01000h
SELFMODIFY_BSP_viewz_hi_3:
sbb       di, 01000h

;di:si will store worldhigh
; what if we store bx/cx here as well, and finally push it once it's too onerous to hold onto?

xor       bx, bx
; can these shifts be avoided and math propagated accordingly? seems hard
SHIFT32_MACRO_RIGHT cx bx 3


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
SELFMODIFY_BSP_set_skyflatnum_1:
mov       al, 010h
cmp       al, byte ptr [bp + 0Ah]
jne       not_a_skyflat
cmp       al, byte ptr [bp + 0Bh]
jne       not_a_skyflat
;di/si are worldhigh..

mov       word ptr [bp - 026h], si
mov       word ptr [bp - 024h], di

not_a_skyflat:

			
;	if (worldlow.w != worldbottom .w || backsectorfloorpic != frontsectorfloorpic || backsectorlightlevel != frontsectorlightlevel) {
;		markfloor = true;
;	} else {
;		// same plane on both sides
;		markfloor = false;
;	}

; TOOO: consider al flags instead of al and ah as two boolean bytes.
xor       ax, ax  ; ax will store markfloor/markceiling

cmp       cx, word ptr [bp - 028h]
jne       set_markfloor_true
cmp       bx, word ptr [bp - 02Ah]
jne       set_markfloor_true
mov       dx, word ptr [bp + 0Ch]
cmp       dl, dh
jne       set_markfloor_true
mov       dx, word ptr [bp + 0Eh]
cmp       dl, dh
je        markfloor_set
set_markfloor_true:
mov       al, 4     ; markfloor  al = 1

markfloor_set:
; di/si are already worldhigh..
cmp       word ptr [bp - 024h], di
jne       set_markceiling_true
cmp       word ptr [bp - 026h], si
jne       set_markceiling_true

mov       dx, word ptr [bp + 0Ah]
cmp       dl, dh
jne       set_markceiling_true

mov       dx, word ptr [bp + 0Eh]
cmp       dl, dh
je        markceiling_set
set_markceiling_true:
mov       ah, 4    ;markceiling  ah = 1
markceiling_set:


; usually we would do a closed door check here, but closed doors call single sided wall draw.
; finally write this just once.
push      ax  ; bp - 030h   markfloor/ceil for bottom path

; ax free at last!
;		if (worldhigh.w < worldtop.w) {

; store worldhigh on stack..
push      di      ; store here  ; todo in the way!!
push      si      ; store here
xchg      di, cx
xchg      si, bx

; worldhigh check one past time
cmp       word ptr [bp - 024h], cx
jg        setup_toptexture
jne       toptexture_zero
cmp       word ptr [bp - 026h], bx
jbe       toptexture_zero
setup_toptexture:

;cx and bx (currently worldhigh) are clobbered but are on stack

; toptexture = texturetranslation[side->toptexture];

SELFMODIFY_settoptexturetranslation_lookup:
mov       ax, 01000h

; write the high byte of the word.
; prev two bytes will be a jump or mov cx with the low byte
; todo midtexture some stuff set here

mov       word ptr ds:[SELFMODIFY_BSP_set_toptexture+1], ax
mov       bx, ax     ; backup
test      ax, ax
je        toptexture_zero         ; todo branch test

toptexture_not_zero:

; are any bits set?
or        bl, bh
or        byte ptr ds:[SELFMODIFY_check_for_any_tex_TWOSIDED+1], bl

test      byte ptr [bp - 2], ML_DONTPEGTOP
je        calculate_toptexturemid  ; either branche has to jump i guess
set_toptexture_to_worldtop:
les       ax, dword ptr [bp - 026h]
mov       dx, es
jmp       do_selfmodify_toptexture

ALIGN_MACRO

calculate_bottexturemid:
; todo cs write here

mov       ax, si
mov       dx, di
jmp       do_selfmodify_bottexture

ALIGN_MACRO
toptexture_zero:
mov       byte ptr ds:[SELFMODIFY_BSP_toptexture],   0E9h
mov       word ptr ds:[SELFMODIFY_BSP_toptexture+1], (SELFMODIFY_BSP_toptexture_TARGET - SELFMODIFY_BSP_toptexture_AFTER)
jmp       toptexture_stuff_done

ALIGN_MACRO

calculate_toptexturemid:
; SET_FIXED_UNION_FROM_SHORT_HEIGHT(rw_toptexturemid, backsectorceilingheight);
; rw_toptexturemid.h.intbits += textureheights[side->toptexture] + 1;
; // bottom of texture
; rw_toptexturemid.w -= viewz.w;

; dx holding on to backsectorceilingheight from above.
SELFMODIFY_get_backsector_ceilingheight:
mov       dx, 01000h ; carry this forward.

;todo investigate no shift
xor       ax, ax
SHIFT32_MACRO_RIGHT dx ax 3

;dx:ax are toptexturemid for now..

; add textureheight+1

; todo should work as a byte add
SELFMODIFY_add_texturetopheight_plus_one:
add       dx, 01000h




SELFMODIFY_BSP_viewz_lo_1:
sub       ax, 01000h
SELFMODIFY_BSP_viewz_hi_1:
sbb       dx, 01000h


do_selfmodify_toptexture:
; set _rw_toptexturemid in rendersegloop

mov   word ptr ds:[SELFMODIFY_set_toptexturemid_lo+1], ax
mov   byte ptr ds:[SELFMODIFY_set_toptexturemid_hi+1], dl


toptexture_stuff_done:

cmp       di, word ptr [bp - 028h]
jg        setup_bottexture
jne       bottexture_zero
cmp       si, word ptr [bp - 02Ah]
jbe       bottexture_zero
setup_bottexture:

; todo: bottom selfmodifies.
; todo: bench copying here vs setting when mids generated.




SELFMODIFY_setbottexturetranslation_lookup:
mov       ax, 01000h

; write the high byte of the word.
; prev two bytes will be a jump or mov cx with the low byte
mov       word ptr ds:[SELFMODIFY_BSP_set_bottomtexture+1], ax
mov       bx, ax     ; backup
test      ax, ax

jne       bottexture_not_zero

bottexture_zero:
mov       word ptr ds:[SELFMODIFY_BSP_bottexture], ((SELFMODIFY_BSP_bottexture_TARGET - SELFMODIFY_BSP_bottexture_AFTER) SHL 8) + 0EBh
jmp       bottexture_stuff_done
ALIGN_MACRO
bottexture_not_zero:

; are any bits set?
or        bl, bh
or        byte ptr ds:[SELFMODIFY_check_for_any_tex_TWOSIDED+1], bl


test      byte ptr [bp - 2], ML_DONTPEGBOTTOM
je        calculate_bottexturemid
; todo cs write here ??
les       ax, dword ptr [bp - 026h]
mov       dx, es
do_selfmodify_bottexture:

; set _rw_toptexturemid in rendersegloop

mov   word ptr ds:[SELFMODIFY_set_bottexturemid_lo+1], ax
mov   byte ptr ds:[SELFMODIFY_set_bottexturemid_hi+1], dl


bottexture_stuff_done:






SELFMODIFY_BSP_siderenderrowoffset_2_TWOSIDED:
mov   al, 010h ; todo should this just be done above...?  rather than this selfmodify chain

;  extra selfmodify? or hold in vars till this pt and finally write the high bits
; 	rw_toptexturemid.h.intbits += side_render->rowoffset;
;	rw_bottomtexturemid.h.intbits += side_render->rowoffset;


add   byte ptr ds:[SELFMODIFY_set_toptexturemid_hi+1], al
add   byte ptr ds:[SELFMODIFY_set_bottexturemid_hi+1], al


; // allocate space for masked texture tables
; if (side->midtexture) {


; check midtexture on 2 sided line (e1m1 case)
; TODO get rid of this???
SELFMODIFY_has_midtexture_or_not:
jmp       SHORT continue_backsector_not_null   ; may  turn into mov al, garbage (fall thru)
ALIGN_MACRO

side_has_midtexture:
public side_has_midtexture
;	// allocate space for masked texture tables. it will be a word table unlike others.


; // masked midtexture
; maskedtexture = true;
; ds_p->maskedtexturecol_val = lastopening - rw_x;
; maskedtexturecol_offset = (ds_p->maskedtexturecol_val) << 1;
; lastopening += rw_stopx - rw_x;

; note. if this runs and we have no top and no bottom texture then we do not render in bsp. its a masked wall and we skip draws!


; this is offset 'backwards' because the array is indexed by screen x, 
; and so we move the start back to make up for the fact that the start position is not 0 (and is rw_x or whatever)

; this runs fairly rarely. so we can use the messy way to fetch dc_x.

mov       ax, word ptr ds:[_lastopening]

mov       bx, ax
and       ax, 1   ; round up to word boundary since we are storing words not bytes in this case.
add       ax, bx  ; now even
mov       word ptr ds:[_lastopening], ax  ; now even
mov       dx, word ptr [bp - 020h]    ; rw_x
sub       ax, dx ; byte..
sub       ax, dx ; word..

les       bx, dword ptr ds:[_ds_p_bsp]
mov       word ptr es:[bx + DRAWSEG_T.drawseg_maskedtexturecol_val], ax

mov       word ptr ds:[_maskedtexturecol_bsp], ax

mov       ax, word ptr [bp - 022h]
inc       ax  ; rw_stopx would be [bp - 01Eh] + 1
sal       ax, 1   ; word increments, double this diff.
add       word ptr ds:[_lastopening], ax

inc       byte ptr ds:[_maskedtexture_bsp] ; set to 1

continue_backsector_not_null:
public continue_backsector_not_null


; rather than doing two separate is backsector != null checks in R_StoreWallRange_, we put the 2 blocks adjacent.


; ds is cs here..
; here we modify worldhigh/low then do not write them back to memory
; (except push/pop in one situation)


; worldlow to dx:ax
mov       dx, di   ; todo: they actually seem unchanged if this is jumped to?
xchg      ax, si

pop       si  ; restore here
pop       di  ; restore here

; dx:ax worldlow
; di:si worldhi
; bp - 024h  ; worldtop hi
; bp - 026h  ; worldtop lo
; bp - 028h  ; worldbottom hi
; bp - 02Ah  ; worldbottom lo

; bp currently - 030h

; if (worldhigh.w < worldtop.w) {

cmp       word ptr [bp - 024h], di
jg        do_pixhigh_step                    ; todo test branch diff
jne       skip_pixhigh_step
cmp       word ptr [bp - 026h], si
jbe       skip_pixhigh_step

do_pixhigh_step:

; pixhigh = (centeryfrac_4.w) - FixedMul (worldhigh.w, rw_scale.w);
; pixhighstep = -FixedMul    (rw_scalestep.w,          worldhigh.w);


;start inlined FixedMulBSPLocal_

IF COMPISA GE COMPILE_386

   ; store these
   ; todo optim 386 path to not push, mult in place, etc?
   push       dx
   mov        dx, di
   xchg       ax, si

   push      dx
   push      ax

   mov       ecx, dword ptr [bp - 02Eh]


   xchg  ax, dx
   shl   eax, 16
   xchg  ax, dx
   imul  ecx
   shr   eax, 16

ELSE

   ; store these
   ; todo optim 386 path to not push, mult in place, etc?
   push      dx  ; USED TO BE STORED IN DI
   push      di  ; FOR MUL 2
   push      si  ; FOR MUL 2

   les       bx, dword ptr [bp - 02Eh]
   mov       cx, es
   
   mov       es, ax ; old ax

   xchg      ax, di ; grab di
   xchg      ax, si ; di to si, si to ax


   PUSH AX
   MUL  BX
   MOV  DI, DX
   MOV  AX, SI
   MUL  CX
   XCHG AX, SI
   CWD
   AND  DX, BX
   SUB  SI, DX
   MUL  BX
   ADD  AX, DI
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


neg       ax
mov       word ptr ds:[_cs_pixhigh], ax

SELFMODIFY_sub__centeryfrac_4_hi_2:
mov       ax, 01000h ; ah known zero. dh too probably?
sbb       ax, dx
mov       byte ptr ds:[SELFMODIFY_BSP_toptexture], 0B8h ; mov   ax, imm16
mov       word ptr ds:[SELFMODIFY_BSP_toptexture+1], ax

;start inlined FixedMulBSPLocal_


IF COMPISA GE COMPILE_386

   pop       ecx

   SELFMODIFY_get_rwscalestep_3_TWOSIDED_386_base:
   SELFMODIFY_get_rwscalestep_lo_3_TWOSIDED = SELFMODIFY_get_rwscalestep_3_TWOSIDED_386_base+1
   SELFMODIFY_get_rwscalestep_hi_3_TWOSIDED = SELFMODIFY_get_rwscalestep_3_TWOSIDED_386_base+3
   mov       eax, 010000000h


   imul  ecx
   shr  eax, 16



ELSE
   pop       bx ; from mul 1
   pop       cx ; from mul 1
; todo align words using pops 
   SELFMODIFY_get_rwscalestep_lo_3_TWOSIDED:
   mov       ax, 01000h
   SELFMODIFY_get_rwscalestep_hi_3_TWOSIDED:
   mov       si, 01000h

   PUSH AX
   MUL  BX
   MOV  DI, DX
   MOV  AX, SI
   MUL  CX
   XCHG AX, SI
   CWD
   AND  DX, BX
   SUB  SI, DX
   MUL  BX
   ADD  AX, DI
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



; dx:ax is pixhighstep.


mov       word ptr ds:[SELFMODIFY_add_to_pixhigh_lo_1_TWOSIDED+4], ax
mov       word ptr ds:[SELFMODIFY_add_to_pixhigh_hi_1_TWOSIDED+4], dx

; restore dxAX
IF COMPISA GE COMPILE_386
   xchg      ax, si  ; todo i dont love all this swap back and forth.
   pop       dx  ; restore dx
ELSE
   MOV       AX, ES ; es was holding this. we want it back in AX anyway.
   pop       dx  ; restore dx
ENDIF

; put these back where they need to be.
; maybe just use these in place?


skip_pixhigh_step:

; dx:ax are now worldlow

; if (worldlow.w > worldbottom.w) {

cmp       dx, word ptr [bp - 028h]
jg        do_pixlow_step
jne       skip_pixlow_step
continue_worldlow_checks:
cmp       ax, word ptr [bp - 02Ah]
jbe       skip_pixlow_step


do_pixlow_step:

; pixlow = (centeryfrac << 16) - FixedMul (worldlow.w, rw_scale.w);
; pixlowstep = -FixedMul    (rw_scalestep.w,          worldlow.w);



;start inlined FixedMulBSPLocal_

IF COMPISA GE COMPILE_386

   mov       ecx, dword ptr [bp - 02Eh]
   mov       di, dx	; store for later
   mov       si, ax	; store for later

   xchg ax, dx
   shl  eax, 16
   xchg ax, dx
   imul  ecx
   shr  eax, 16



ELSE

   push      dx	; store for later
   les       bx, dword ptr [bp - 02Eh]
   mov       cx, es
   mov       es, ax	; store for later

   MOV  SI, DX

   MUL  BX
   MOV  DI, DX
   MOV  AX, SI
   MUL  CX
   XCHG AX, SI
   CWD
   AND  DX, BX
   SUB  SI, DX
   MUL  BX
   ADD  AX, DI
   ADC  SI, DX
   XCHG AX, CX
   CWD
   MOV  BX, ES  ; bx has old ax value from es now.
   AND  DX, BX
   SUB  SI, DX
   MUL  BX
   ADD  AX, CX
   ADC  DX, SI

   pop  di      ; di/si ready for next fixedmul..
ENDIF

;end inlined FixedMulBSPLocal_

neg       ax     ;  -Fixedmul lowbits
SELFMODIFY_sub__centeryfrac_4_hi_1:  
mov       cx, 01000h ; ah known zero. dh too probably?
sbb       cx, dx ; -FixedMul highbits

; todo: why does this sometimes run without the other code running??
; work backwards...

add       ax, 0FFFFh ; HEIGHTUNIT -1 preshifted 4
adc       cx, 0
; todo should this be here... ? remove from other spot...?
mov       byte ptr ds:[SELFMODIFY_BSP_bottexture], 0B8h   ; mov   ax, imm16
mov       word ptr ds:[SELFMODIFY_BSP_bottexture+1], cx   ; this's presence break things! instructions too big??
mov       word ptr ds:[_cs_pixlow], ax


;start inlined FixedMulBSPLocal_

IF COMPISA GE COMPILE_386


   SELFMODIFY_get_rwscalestep_4_TWOSIDED_386_base:
   SELFMODIFY_get_rwscalestep_lo_4_TWOSIDED = SELFMODIFY_get_rwscalestep_4_TWOSIDED_386_base+1
   SELFMODIFY_get_rwscalestep_hi_4_TWOSIDED = SELFMODIFY_get_rwscalestep_4_TWOSIDED_386_base+3
   mov       eax, 010000000h

   ;mov       cx, di	; cached values
   ;mov       bx, si	; cached values

   shl  edi, 16
   mov   di, si
   imul  edi
   shr   eax, 16



ELSE
; si, di not preserved
; note: mul by di:bx

   SELFMODIFY_get_rwscalestep_lo_4_TWOSIDED:
   mov       ax, 01000h
   SELFMODIFY_get_rwscalestep_hi_4_TWOSIDED:
   mov       cx, 01000h

; multiply by di:bx


   MOV  ES, AX
   MUL  BX
   MOV  SI, DX
   MOV  AX, CX
   MUL  DI
   XCHG AX, CX
   CWD
   AND  DX, BX
   SUB  CX, DX
   MUL  BX

   ADD  AX, SI
   ADC  CX, DX
   XCHG AX, DI
   CWD
   MOV  BX, ES
   AND  DX, BX
   SUB  CX, DX
   MUL  BX
   ADD  AX, DI
   ADC  DX, CX

ENDIF

;end inlined FixedMulBSPLocal_


; dx:ax is pixlowstep.
; self modifying code to write to pixlowstep usages.

mov       word ptr ds:[SELFMODIFY_add_to_pixlow_lo_1_TWOSIDED+4], ax
mov       word ptr ds:[SELFMODIFY_add_to_pixlow_hi_1_TWOSIDED+4], dx


; fallthru

; begin duplicate code for two_sided block

skip_pixlow_step:
done_with_two_sided_sector_setup:

; todo... avoid this var?
mov       al, byte ptr ds:[_maskedtexture_bsp]  ; todo is it necessary to write?



; set maskedtexture in rendersegloop

; would be nice to turn into a jmp or nop, but the lookup is slow and doesnt actually run often.

mov       byte ptr ds:[SELFMODIFY_get_maskedtexture_1_TWOSIDED+1], al

; DS STILL CS.


; create segtextured value
SELFMODIFY_check_for_any_tex_TWOSIDED:
or   	  al, 0

; set segtextured in rendersegloop



jne       do_seg_textured_stuff_TWOSIDED
mov       word ptr ds:[SELFMODIFY_BSP_get_segtextured_TWOSIDED], ((SELFMODIFY_BSP_get_segtextured_TARGET_TWOSIDED - SELFMODIFY_BSP_get_segtextured_AFTER_TWOSIDED) SHL 8) + 0EBh

jmp       seg_textured_check_done_TWOSIDED
ALIGN_MACRO
do_seg_textured_stuff_TWOSIDED:
mov       word ptr ds:[SELFMODIFY_BSP_get_segtextured_TWOSIDED], MOV_AX_IMM16_OPCODE + ((XTOVIEWANGLE_SEGMENT AND 0FFh) SHL 8)
SELFMODIFY_set_offsetangle_TWOSIDED:
mov       bx, 01000h
cmp       bx, FINE_ANG180_NOSHIFT ; 04000h
jbe       offsetangle_greater_than_fineang180_TWOSIDED
neg       bx
and       bh, MOD_FINE_ANGLE_NOSHIFT_HIGHBITS

offsetangle_greater_than_fineang180_TWOSIDED:

SELFMODIFY_set_PointToDist_result_hi_TWOSIDED:
mov       cx, 01000h
SELFMODIFY_set_PointToDist_result_lo_TWOSIDED:
mov       ax, 01000h

; dx is offsetangle

cmp       bx, FINE_ANG90_NOSHIFT ; 02000h
ja        offsetangle_greater_than_fineang90_TWOSIDED

; inlined FixedMulTrigNoShiftSine_BSPLocal_

SHR  BX, 1

MOV  DX, FINESINE_SEGMENT
MOV  ES, DX
MOV  BX, WORD PTR ES:[BX]

MUL  BX        ; AX * BX
MOV  AX, CX    ; CX to AX
MOV  CX, DX    ; CX stores high result as low word
MUL  BX        ; AX*CX
ADD  AX, CX    ; add low word

; used later, dont change?
; dx:ax is rw_offset
xchg      ax, dx
ADC       AX, 0
jmp       done_with_offsetangle_stuff_TWOSIDED
ALIGN_MACRO
offsetangle_greater_than_fineang90_TWOSIDED:
xchg      ax, dx  ; dx gets low
xchg      ax, cx  ; ax gets high



done_with_offsetangle_stuff_TWOSIDED:
; ax:dx is rw_offset

xor       cx, cx ; cx holds 0...

SELFMODIFY_set_rw_normal_angle_shift3_TWOSIDED:
mov       bx, 01000h
cmp       cx, word ptr [bp - 012h]   ; rw_angle lo from R_AddLine
sbb       bx, word ptr [bp - 010h]   ; rw_angle hi from R_AddLine


;		if (tempangle.hu.intbits < ANG180_HIGHBITS) {	
;			rw_offset.w = -rw_offset.w;
;		}
;		rw_offset.h.intbits += (sidetextureoffset + curseg_render->offset);

; use sbb bx flags to check for < 08000h (ANG180)
js        tempangle_not_smaller_than_fineang180_TWOSIDED
neg       ax
neg       dx
sbb       ax, cx  ; 0
tempangle_not_smaller_than_fineang180_TWOSIDED:




SELFMODIFY_BSP_sidetextureoffset_TWOSIDED:
add       ax, 01000h
SELFMODIFY_BSP_sidesegoffset_TWOSIDED:
add       ax, 01000h 
; rw_offset ready to be written to rendersegloop:
mov   word ptr ds:[SELFMODIFY_set_cx_rw_offset_lo_TWOSIDED+1], dx
mov   word ptr ds:[SELFMODIFY_set_ax_rw_offset_hi_TWOSIDED+2], ax




;	    lightnum = (frontsector->lightlevel >> LIGHTSEGSHIFT)+extralight;


SELFMODIFY_BSP_fixedcolormap_3_TWOSIDED:
jmp SHORT seg_textured_check_done_TWOSIDED    ; dont check walllights if fixedcolormap
SELFMODIFY_BSP_fixedcolormap_3_AFTER_TWOSIDED:


mov       al, byte ptr [bp + 0Eh]   ; light level
SHIFT_MACRO shr al 4


SELFMODIFY_BSP_extralight2_plusone_TWOSIDED:
add       al, 0
cbw


SELFMODIFY_addlightnum_delta_TWOSIDED:
dec       ax  ; nop carries flags from add dl, al. dec and inc will set signed accordingly

shl       ax, 1  ; word lookup
xchg      ax, bx
mov       ax, word ptr ds:[_mul48lookup_with_scalelight_with_minusone_offset + bx]




; write walllights to rendersegloop
mov   word ptr ds:[SELFMODIFY_add_wallights_TWOSIDED+3], ax
; ? do math here and write this ahead to drawcolumn colormapsindex?

SELFMODIFY_BSP_fixedcolormap_3_TARGET_TWOSIDED:
seg_textured_check_done_TWOSIDED:

; cant use cl as 0 byte because we might jump/branch here?

SELFMODIFY_BSP_viewz_shortheight_4_TWOSIDED:
cmp       word ptr [bp + 6], 01000h
jl        not_above_viewplane_TWOSIDED   ; todo branch test
mov       byte ptr [bp - 030h], 0  
not_above_viewplane_TWOSIDED:
SELFMODIFY_BSP_viewz_shortheight_3_TWOSIDED:
cmp       word ptr [bp + 8], 01000h
jg        not_below_viewplane_TWOSIDED   ; todo branch test
SELFMODIFY_BSP_set_skyflatnum_4_TWOSIDED:
cmp       byte ptr [bp + 0Ah], 010h
je        not_below_viewplane_TWOSIDED   ; todo branch test
mov       byte ptr [bp - 02Fh], 0  ;markceiling
; ok here
not_below_viewplane_TWOSIDED:


;start inlined FixedMulBSPLocal_



IF COMPISA GE COMPILE_386

   mov       eax, dword ptr [bp - 026h]
   
   imul  dword ptr [bp - 02Eh]  ; todo put in  ECX and reuse for next mul
   shr  eax, 16



ELSE

   les       ax, dword ptr [bp - 026h]
   mov       si, es
   les       bx, dword ptr [bp - 02Eh]
   mov       cx, es
   jcxz      do_16_bit_rw_scale_mul_worldtophi_bottop

   ; mul dx:ax by cx:bx

   MOV  ES, AX ; todo synergy
   MUL  BX
   MOV  DI, DX
   MOV  AX, SI
   MUL  CX
   XCHG AX, SI
   CWD
   AND  DX, BX
   SUB  SI, DX
   MUL  BX
   ADD  AX, DI
   ADC  SI, DX
   XCHG AX, CX
   CWD
   MOV  BX, ES
   AND  DX, BX
   SUB  SI, DX
   MUL  BX
   ADD  AX, CX
   ADC  DX, SI
   jmp  done_with_rw_scale_mul_worldtophi_bottop

   ALIGN_MACRO
   do_16_bit_rw_scale_mul_worldtophi_bottop:   

   mov  CX, SI
   mov  SI, BX   ; SI gets rw_scale copy
   
   ; mul cx:bx by --:ax
   ; first instruction was xchg ax/bx, was being done twice so cancelled out

   MUL  BX        ; AX * BX
   MOV  AX, CX    ; CX to AX
   MOV  CX, DX    ; CX stores low word
   CWD            ; S1 in DX
   AND  DX, BX    ; S1 * AX
   NEG  DX        ; 
   XCHG DX, BX    ; AX into DX, high word into BX
   MUL  DX        ; AX*CX
   ADD  AX, CX     ; add low word
   ADC  DX, BX     ; add high word

   neg       ax
   SELFMODIFY_sub__centeryfrac_4_hi_5_TWOSIDED:
   mov       cx, 01000h
   sbb       cx, dx
   add       ax, ((HEIGHTUNIT)-1) SHL 4 ; bake this in once, instead of doing it every loop.
   adc       cx, 0

   mov       word ptr ds:[SELFMODIFY_set_topfrac_hi_bottop+1], cx
   mov       word ptr ds:[_cs_topfrac_lo], ax

   les       ax, dword ptr [bp - 02Ah]  ; avoid xchg ax/bx
   mov       cx, es
   ; SI has value that was in bx.

   MUL  SI        ; AX * BX
   MOV  AX, CX    ; CX to AX
   MOV  CX, DX    ; CX stores low word
   CWD            ; S1 in DX
   AND  DX, SI    ; S1 * AX
   NEG  DX        ; 
   XCHG DX, SI    ; AX into DX, high word into BX
   MUL  DX        ; AX*CX
   ADD  AX, CX     ; add low word
   ADC  DX, SI     ; add high word

   jmp       done_with_rw_scale_mul_worldbothi_bottop


ENDIF

done_with_rw_scale_mul_worldtophi_bottop:

;end inlined FixedMulBSPLocal_
; not ok
neg       ax
SELFMODIFY_sub__centeryfrac_4_hi_4_TWOSIDED:
mov       cx, 01000h ; ah known zero. dh too probably?
sbb       cx, dx
add       ax, ((HEIGHTUNIT)-1) SHL 4 ; bake this in once, instead of doing it every loop.
mov       word ptr ds:[_cs_topfrac_lo], ax
adc       cx, 0
mov       word ptr ds:[SELFMODIFY_set_topfrac_hi_bottop+1], cx



;start inlined FixedMulBSPLocal_

IF COMPISA GE COMPILE_386

   mov       eax, dword ptr [bp - 02Ah]


   imul  dword ptr [bp - 02Eh]  ; todo reuse from last mul
   shr  eax, 16



ELSE
; si not preserved

   les       ax, dword ptr [bp - 02Ah]
   mov       si, es
   les       bx, dword ptr [bp - 02Eh]
   mov       cx, es

   MOV  ES, AX ; todo synergy
   MUL  BX
   MOV  DI, DX
   MOV  AX, SI
   MUL  CX
   XCHG AX, SI
   CWD
   AND  DX, BX
   SUB  SI, DX
   MUL  BX
   ADD  AX, DI
   ADC  SI, DX
   XCHG AX, CX
   CWD
   MOV  BX, ES
   AND  DX, BX
   SUB  SI, DX
   MUL  BX
   ADD  AX, CX
   ADC  DX, SI

ENDIF

;end inlined FixedMulBSPLocal_

done_with_rw_scale_mul_worldbothi_bottop:

neg       ax
mov       word ptr ds:[_cs_botfrac_lo], ax

SELFMODIFY_sub__centeryfrac_4_hi_3_TWOSIDED: ; preincremented by 1 
mov       ax, 01000h ; ah known zero. dh too probably?
sbb       ax, dx

; todo dont calculate this if we do no columns to draw below.

mov       word ptr ds:[SELFMODIFY_set_botfrac_hi_bottop+1], ax


cmp       byte ptr [bp - 02Fh], 0  ;markceiling
je        dont_mark_ceiling_TWOSIDED ; todo which default braunch?

mov       ax, word ptr ds:[_ceilingplaneindex]
les       dx, dword ptr [bp - 020h]   ; rw_stopx - 1 = stop
mov       cx, es
les       bx, dword ptr ds:[_ceiltop] 

call      R_CheckPlaneSetCeil_ ; enters and exits with ds as cs
ENSUREALIGN_308:
mov       word ptr ds:[_ceilingplaneindex], ax
dont_mark_ceiling_TWOSIDED:

; todo pop markfloor into bp maybe? to reuse

cmp       byte ptr [bp - 030h], 0 ; markfloor
je        dont_mark_floor_TWOSIDED ; todo which default braunch?

mov       ax, word ptr ds:[_floorplaneindex]
les       dx, dword ptr [bp - 020h]   ; rw_stopx - 1 = stop
mov       cx, es
les       bx, dword ptr ds:[_floortop]

mov       byte ptr ds:[SELFMODIFY_setisceil + 1], 0
call      R_CheckPlane_ ; enters and exits with ds as cs
ENSUREALIGN_309:
mov       word ptr ds:[_floorplaneindex], ax
dont_mark_floor_TWOSIDED:

ASSUME DS:R_BSP_24_TEXT
; make ds equal to cs for self modifying codes


xor   bx, bx
; last use, can be popped?
pop   dx ; bp - 030h
; todo move this up?
pop   word ptr ds:[SELFMODIFY_set_rwscale_lo_bottop+1] ; bp - 02Eh
pop   word ptr ds:[SELFMODIFY_set_rwscale_hi_bottop+1] ; bp - 02Ch

; todo improve??

mov   bl, dl
les   ax, dword ptr ds:[bx+_selfmodify_lookup_markfloor]
mov   word ptr ds:[SELFMODIFY_BSP_markfloor_1_TWOSIDED], ax
mov   word ptr ds:[SELFMODIFY_BSP_markfloor_2_TWOSIDED], es

mov   bl, dh ; retrieve high byte
les   ax, dword ptr ds:[bx+_selfmodify_lookup_markceiling]
mov   byte ptr ds:[SELFMODIFY_BSP_markceiling_2_TWOSIDED], al
mov   word ptr ds:[SELFMODIFY_BSP_markceiling_1_TWOSIDED], es



;start inlined FixedMulBSPLocal_

IF COMPISA GE COMPILE_386

   pop       ecx ; bp - 028h

   SELFMODIFY_get_rwscalestep_2_TWOSIDED_386_base:
   SELFMODIFY_get_rwscalestep_lo_2_TWOSIDED = SELFMODIFY_get_rwscalestep_2_TWOSIDED_386_base+1
   SELFMODIFY_get_rwscalestep_hi_2_TWOSIDED = SELFMODIFY_get_rwscalestep_2_TWOSIDED_386_base+3
   mov       eax, 010000000h


   imul  ecx
   shr  eax, 16



ELSE

   pop       bx ; bp - 02Ah
   pop       cx ; bp - 028h
   SELFMODIFY_get_rwscalestep_lo_2_TWOSIDED:
   mov       ax, 01000h
   SELFMODIFY_get_rwscalestep_hi_2_TWOSIDED:
   mov       si, 01000h



   MOV  ES, AX
   MUL  BX
   MOV  DI, DX
   MOV  AX, SI
   MUL  CX
   XCHG AX, SI
   CWD
   AND  DX, BX
   SUB  SI, DX
   MUL  BX
   ADD  AX, DI
   ADC  SI, DX
   XCHG AX, CX
   CWD
   MOV  BX, ES
   AND  DX, BX
   SUB  SI, DX
   MUL  BX
   ADD  AX, CX
   ADC  DX, SI

ENDIF
;end inlined FixedMulBSPLocal_


; dx:ax are bottomstep



mov       word ptr ds:[SELFMODIFY_add_botstep_lo_TWOSIDED+4], ax
mov       word ptr ds:[SELFMODIFY_add_botstep_hi_TWOSIDED+4], dx




;start inlined FixedMulBSPLocal_


IF COMPISA GE COMPILE_386

   SELFMODIFY_get_rwscalestep_1_TWOSIDED_386_base:
   SELFMODIFY_get_rwscalestep_lo_1_TWOSIDED = SELFMODIFY_get_rwscalestep_1_TWOSIDED_386_base+1
   SELFMODIFY_get_rwscalestep_hi_1_TWOSIDED = SELFMODIFY_get_rwscalestep_1_TWOSIDED_386_base+3
   mov       eax, 010000000h
   mov       dx, 01000h
   pop       ecx ; bp - 024h

   imul  ecx
   shr  eax, 16



ELSE

   SELFMODIFY_get_rwscalestep_lo_1_TWOSIDED:
   mov       ax, 01000h
   SELFMODIFY_get_rwscalestep_hi_1_TWOSIDED:
   mov       si, 01000h
   pop       bx ; bp - 026h
   pop       cx ; bp - 024h

   MOV  ES, AX
   MUL  BX
   MOV  DI, DX
   MOV  AX, SI
   MUL  CX
   XCHG AX, SI
   CWD
   AND  DX, BX
   SUB  SI, DX
   MUL  BX
   ADD  AX, DI
   ADC  SI, DX
   XCHG AX, CX
   CWD
   MOV  BX, ES
   AND  DX, BX
   SUB  SI, DX
   MUL  BX
   ADD  AX, CX
   ADC  DX, SI

ENDIF

;end inlined FixedMulBSPLocal_

; dx:ax are topstep


mov       word ptr ds:[SELFMODIFY_add_topstep_lo_TWOSIDED+4], ax
mov       word ptr ds:[SELFMODIFY_add_topstep_hi_TWOSIDED+4], dx





;   BEGIN INLINED R_RenderSegLoop_TWOSIDED_
;   BEGIN INLINED R_RenderSegLoop_TWOSIDED_
;   BEGIN INLINED R_RenderSegLoop_TWOSIDED_
;   BEGIN INLINED R_RenderSegLoop_TWOSIDED_

R_RenderSegLoop_TWOSIDED_:
public R_RenderSegLoop_TWOSIDED_

; made it here




; todo set up cs vars here  properly.

mov   di, word ptr [bp - 020h]  ; startx
 


jmp   start_per_column_inner_loop_TWOSIDED


ALIGN_MACRO


exit_rendersegloop_TWOSIDED:
public exit_rendersegloop_TWOSIDED
; zero out local caches.
; cx has cs
;ASSUME DS:DGROUP
; cx, ds already cs

mov   es, cx
mov   ax, 0FFFFh
mov   di, OFFSET _segloopnextlookup
stosw ; mov   word ptr ds:[_segloopnextlookup], ax
stosw ; mov   word ptr ds:[_segloopnextlookup+2], ax
inc   ax
; zero both 
stosw ; mov   word ptr ds:[_seglooptexrepeat], ax


jmp   R_RenderSegLoop_exit_TWOSIDED



ALIGN_MACRO

finished_inner_loop_iter_TWOSIDED:

mov   di, bx   ; set dc_x... todo skip this step.
mov   cx, cs  ;  cx gets cs... todo is this necessary?
mov   ds, cx

pre_increment_values_TWOSIDED: 
public pre_increment_values_TWOSIDED

; bx = dc_x

inc   di


SELFMODIFY_cmp_di_to_rw_stopx_TWOSIDED:
cmp   di, 01000h
jge   exit_rendersegloop_TWOSIDED  ; exit before adding the other loop vars.


; di has rw_x...

; todo 386 dword instructions
SELFMODIFY_add_topstep_lo_TWOSIDED:
sub   word ptr ds:[_cs_topfrac_lo], 01000h
SELFMODIFY_add_topstep_hi_TWOSIDED:
sbb   word ptr ds:[SELFMODIFY_set_topfrac_hi_bottop+1], 01000h
SELFMODIFY_add_botstep_lo_TWOSIDED:
sub   word ptr ds:[_cs_botfrac_lo], 01000h
SELFMODIFY_add_botstep_hi_TWOSIDED:
sbb   word ptr ds:[SELFMODIFY_set_botfrac_hi_bottop+1], 01000h
SELFMODIFY_add_rwscale_lo_TWOSIDED:
add   word ptr ds:[SELFMODIFY_set_rwscale_lo_bottop+1], 01000h
SELFMODIFY_add_rwscale_hi_TWOSIDED:
adc   word ptr ds:[SELFMODIFY_set_rwscale_hi_bottop+1], 01000h



; this is right before inner loop start

start_per_column_inner_loop_TWOSIDED:
; ax was rw_x
; now di is rw_x

SELFMODIFY_rewrite_bsp_out_dx_code_topbot:
; quality 0 version
mov  cx, di
and  cl, 3
mov  ax, 1 ; zero ah
shl  al, cl
mov  dx, SC_DATA
out  dx, al    ; 14 bytes


done_setting_vga_plane_topbot:
PUBLIC done_setting_vga_plane_topbot




; todo clean up logic. store only in ch/cl. possible store same pixel floor/ceiling side by side? one read, word?
                                                 ; di = rw_x
; ah already 0
mov   al, byte ptr ds:[di+OFFSET_FLOORCLIP]	 ; cx = floor
mov   cx, ax
mov   al, byte ptr ds:[di+OFFSET_CEILINGCLIP] ; si = ceiling  = ceilingclip[rw_x]+1;

xchg  ax, si
;mov   si, ax  ; toggle for ENSUREALIGN_005/ENSUREALIGN_006 along with INC instruciton
inc   si

; ds is cs


; all these y values - ceil and floorclip, and later dc_yl and dc_yh are 
; increased by one to allow 0 to viewheight+1 range instead of ff to viewheight range.
; when written to visplanes and such this must be considered


SELFMODIFY_set_topfrac_hi_bottop:
mov   ax, 01000h
ENSUREALIGN_005:


cmp   ax, si  ; ax can be negative even if si is not? but maybe ah is always ff?
jg    skip_yl_ceil_clip_TWOSIDED    
do_yl_ceil_clip_TWOSIDED:
mov   ax, si
skip_yl_ceil_clip_TWOSIDED:
mov   dx, ax   ; dx has yl...
push  dx       ; todo remove
SELFMODIFY_BSP_markceiling_1_TWOSIDED:
jmp SHORT    markceiling_done_TWOSIDED    ; OR mov dl, [markceiling]

SELFMODIFY_BSP_markceiling_1_AFTER_TWOSIDED = SELFMODIFY_BSP_markceiling_1_TWOSIDED+2

; ax is yl
; si = top = ceilingclip[rw_x]+1;
dec   ax				; now ax = bottom = yl-1
; cx is floor, 
; thie following is a forced encoding. tasm wants to do 3A C1 and this needs to agree with selfmodify...
db    038h, 0C8h   ; cmp   al, cl      ;   ax cannot be negative, already was inc-ed before.
jb    skip_bottom_floorclip_TWOSIDED
mov   al, cl
dec   ax
skip_bottom_floorclip_TWOSIDED:
cmp   si, ax
jg    markceiling_done_TWOSIDED
les   bx, dword ptr ds:[_ceiltop]
dec   ax
mov   byte ptr es:[bx+di + vp_bottom_offset], al
mov   ax, si						    		   ; dl is 0, si is < screensize (and thus under 255)
dec   ax
mov   byte ptr es:[bx+di], al
SELFMODIFY_skip_markceildirty:
jmp   SHORT markceildirty  ; THIS_IS_A_SELFMODIFIED_INSTRUCTION_TARGET into mov al


SELFMODIFY_BSP_markceiling_1_TARGET_TWOSIDED:

markceiling_done_TWOSIDED:

; yh = bottomfrac>>HEIGHTBITS;


SELFMODIFY_set_botfrac_hi_bottop:
mov   ax, 01000h ; already incremented by 1.
ENSUREALIGN_006:
; ah 0 because si < 255



; cx is still floor
cmp   ax, cx
jl    skip_yh_floorclip_TWOSIDED
do_yh_floorclip_TWOSIDED:
mov   ax, cx
dec   ax
skip_yh_floorclip_TWOSIDED:
push  ax   ; todo remove
mov   bp, dx  ; store yl
sub   dx, ax   ; yl - yh. technically we want to know if (yh - yl) is positive then we take (200 - (yh - yl)


; ax is already yh
; cx is already  floor
SELFMODIFY_BSP_markfloor_1_TWOSIDED:
public SELFMODIFY_BSP_markfloor_1_TWOSIDED
SELFMODIFY_BSP_markfloor_1_AFTER_TWOSIDED = SELFMODIFY_BSP_markfloor_1_TWOSIDED + 2
inc   ax			; top = yh + 1...     OR  je    markfloor_done
dec   cx			; bottom = floorclip[rw_x]-1;

;	if (top <= ceilingclip[rw_x]){
;		top = ceilingclip[rw_x]+1;
;	}

; si is ceil
cmp   ax, si
jg    skip_top_ceilingclip_TWOSIDED
mov   ax, si	 ; 		top = ceilingclip[rw_x]+1;  ;todo is si ok to knock out via xchg?

skip_top_ceilingclip_TWOSIDED:

;	if (top <= bottom) {
;		floortop[rw_x] = top & 0xFF;
;		floortop[rw_x+322] = bottom & 0xFF;
;	}

cmp   ax, cx
jg    markfloor_done_TWOSIDED
les   bx, dword ptr ds:[_floortop]
dec   ax
mov   byte ptr es:[bx+di], al
dec   cx
mov   byte ptr es:[bx+di + vp_bottom_offset], cl
SELFMODIFY_skip_markfloordirty:
jmp   SHORT markfloordirty  ; THIS_IS_A_SELFMODIFIED_INSTRUCTION_TARGET into mov al


SELFMODIFY_BSP_markfloor_1_TARGET_TWOSIDED:

markfloor_done_TWOSIDED:

SELFMODIFY_BSP_get_segtextured_TWOSIDED:



SELFMODIFY_BSP_get_segtextured_AFTER_TWOSIDED = SELFMODIFY_BSP_get_segtextured_TWOSIDED + 2

; seg is textured

mov   ax, XTOVIEWANGLE_SEGMENT  ; THIS_IS_A_SELFMODIFIED_INSTRUCTION_TARGET  ; may become jmp SHORT    jump_to_seg_non_textured_TWOSIDED 
mov   es, ax
mov   bx, di

mov   bx, word ptr es:[bx+di] ; word lookup of dc_x

mov   ax, FINETANGENTINNER_SEGMENT  ; maybe can be skipped if bsp is moved under here.
mov   es, ax

SELFMODIFY_set_rw_center_angle_TWOSIDED:
add   bx, 01000h
and   bh, FINE_ANGLE_HIGH_BYTE				; MOD_FINE_ANGLE = and 0x1FFF

; temp.w = rw_offset.w - FixedMul(finetangent(angle),rw_distance);


sub   bx, FINE_TANGENT_MAX        ; bx now -2048 to 2047
sbb   bp, bp
xor   bx, bp          ; bx now 0 to 2048, bp has sign.. but table is 2048 entries.





IF COMPISA GE COMPILE_386
    ; todo or one?
   SHIFT_MACRO shl bx 2
   mov   ebx, dword ptr es:[bx]
   not   bp
   movsx ecx, bp
   sub   ebx, ecx
   xor   ebx, ecx  ;apply sign


  SELFMODIFY_set_rw_distance_hi_386_base_topbot:

  SELFMODIFY_set_rw_distance_lo_topbot = SELFMODIFY_set_rw_distance_hi_386_base_topbot+1
  SELFMODIFY_set_rw_distance_hi_topbot = SELFMODIFY_set_rw_distance_hi_386_base_topbot+3
  mov   eax, 010000000h

  imul  ebx
  shr   eax, 16
  jmp   done_with_finetanmul_TWOSIDED  ; todo this is an empty jump just to make room for these branches
  ALIGN_MACRO
  markceildirty:
  or    byte ptr ds:[SELFMODIFY_mark_planes_dirty_TWOSIDED+1], 2 ; ceiling bit
  mov   byte ptr ds:[SELFMODIFY_skip_markceildirty], MOV_AL_IMM8_OPCODE  
  jmp   SHORT markceiling_done_TWOSIDED
  ALIGN_MACRO
  markfloordirty:
  or    byte ptr ds:[SELFMODIFY_mark_planes_dirty_TWOSIDED+1], 1 ; floor bit
  mov   byte ptr ds:[SELFMODIFY_skip_markfloordirty], MOV_AL_IMM8_OPCODE  
  jmp   SHORT markfloor_done_TWOSIDED


ELSE

   SHIFT_MACRO shl bx 2
   test  bh, 010h
   les   bx, dword ptr es:[bx]

  SELFMODIFY_set_rw_distance_lo_topbot:
  public SELFMODIFY_set_rw_distance_lo_topbot
  mov   ax, 01000h

   SELFMODIFY_set_rw_distance_hi_topbot:
   mov   cx, 01000h
   jnz   do_32_bit_finetan_mul_TWOSIDED

   do_16_bit_mul_TWOSIDED:
   public do_16_bit_mul_TWOSIDED

   ; BX * CX:AX

   mul  bx        ; AX * BX
   mov  ax, bx    ; for next mul
   mov  bx, dx    ; store hi result
   mul  cx
   add  ax, bx    ; add previous hi into lo
   adc  dx, 0     ; es may be known 0?

   jmp  done_with_16bitmul_TWOSIDED
   ALIGN_MACRO
   markceildirty:
   or    byte ptr ds:[SELFMODIFY_mark_planes_dirty_TWOSIDED+1], 2 ; ceiling bit
   mov   byte ptr ds:[SELFMODIFY_skip_markceildirty], MOV_AL_IMM8_OPCODE  
   jmp   SHORT markceiling_done_TWOSIDED
   ALIGN_MACRO
   markfloordirty:
   or    byte ptr ds:[SELFMODIFY_mark_planes_dirty_TWOSIDED+1], 1 ; floor bit
   mov   byte ptr ds:[SELFMODIFY_skip_markfloordirty], MOV_AL_IMM8_OPCODE  
   jmp   SHORT markfloor_done_TWOSIDED


   ALIGN_MACRO
   SELFMODIFY_BSP_get_segtextured_TARGET_TWOSIDED:
   jump_to_seg_non_textured_TWOSIDED:
   xor   dx, dx
   jmp   seg_non_textured_TWOSIDED





; todo: make this faster.

ALIGN_MACRO
do_32_bit_finetan_mul_TWOSIDED:

  mov   si, es

  MUL  BX
  MOV  ES, DX


  MOV  AX, cx
  MUL  si
  XCHG AX, cx
  MUL  BX
  MOV  BX, ES
  ADD  AX, BX
  SELFMODIFY_set_rw_distance_lo_2_TWOSIDED:
  mov   bx, 01000h
  XCHG AX, si
  ADC  cx, DX

  MUL  BX
  ADD  AX, si
  ADC  DX, cx


   ; around here whats wrong

   ;	    texturecolumn = rw_offset-FixedMul(finetangent[angle],rw_distance);

   done_with_16bitmul_TWOSIDED:
   not   bp
   SUB   AX, bp
   SBB   DX, bp
   XOR   AX, bp ; no xor ax necessary if we flip order with add below? may require below values negged
   XOR   DX, bp
ENDIF

done_with_finetanmul_TWOSIDED:


SELFMODIFY_set_cx_rw_offset_lo_TWOSIDED:	
add   ax, 01000h   ; cx is soon clobbered. so we only need AX?
SELFMODIFY_set_ax_rw_offset_hi_TWOSIDED:
public SELFMODIFY_set_ax_rw_offset_hi_TWOSIDED
adc   dx, 01000h

; texturecolumn = dx:ax...  or just dx (whole number)

;	if (rw_scale.h.intbits >= 3) {
;		index = MAXLIGHTSCALE - 1;
;	} else {
;		index = rw_scale.w >> LIGHTSCALESHIFT;
;	}

; CX:BX rw_scale

; store texturecolumn

push  dx       ; later popped into dx  ; todo remove?

; CX:AX rw_scale
SELFMODIFY_set_rwscale_hi_bottop:
mov   cx, 01000h 
ENSUREALIGN_007:

cmp   cl, 3
SELFMODIFY_set_rwscale_lo_bottop:
mov   ax, 01000h 
ENSUREALIGN_008:
jae   use_max_light_TWOSIDED
do_lightscaleshift_TWOSIDED:

; shift 8
mov   bl, ah
mov   bh, cl
; shift 12
SHIFT_MACRO shr bx 4

do_light_write_TWOSIDED:
SELFMODIFY_add_wallights_TWOSIDED:
; bx is scalelight
; scalelight is pre-shifted 4 to save on the double sal every column.

; todo move into dh with zeroed dl. then into bp, and carry forward instead of selfmodify?
; maybe push once?


mov   bl, byte ptr ss:[bx+01000h]         ; 8a 84 00 10 
ENSUREALIGN_021:

xchg  ax, bx  ; cx:bx is proper value again.
;        set colormap offset to high byte



mov   byte ptr ds:[SELFMODIFY_BSP_set_xlat_offset_TWOSIDED+2], al
mov   byte ptr ds:[SELFMODIFY_BSP_set_xlat_offset_bot+2], al

; todo move getseghere... but just for seg


jmp   light_set_TWOSIDED

IF COMPISA GE COMPILE_386
   ALIGN_MACRO
   SELFMODIFY_BSP_get_segtextured_TARGET_TWOSIDED:
   jump_to_seg_non_textured_TWOSIDED:
   xor   dx, dx
   jmp   seg_non_textured_TWOSIDED
ENDIF

ALIGN_MACRO



; up to here now

use_max_light_TWOSIDED:
; ugly 
mov   bx, MAXLIGHTSCALE - 1
jmp   do_light_write_TWOSIDED
ALIGN_MACRO
light_set_TWOSIDED:

; ds is cs here
; INLINED FASTDIV3232FFF_ algo. only used here.

; set ax:dx ffffffff

; if top 16 bits missing just do a 32 / 16



; todo probably broken
IF COMPISA GE COMPILE_386
   ; set up eax
   mov  ax, -1
   db 066h, 098h                    ; cwde (prepare EAX)
   ; set up edx
   db 066h, 031h, 0D2h              ; xor edx, edx (must be 0, not FFFF FFFF)

   ; set up ecx
   db 066h, 0C1h, 0E3h, 010h        ; shl  ebx, 0x10
   db 066h, 00Fh, 0A4h, 0D9h, 010h  ; shld ecx, ebx, 0x10

   ; divide
   db 066h, 0F7h, 0F1h              ; div ecx

   ; set up return
   db 066h, 00Fh, 0A4h, 0C1h, 010h  ; shld ecx, eax, 0x10

   ; cx:ax is result
   test cl, cl
   jz   do_stretch_draw_386_bottop
   do_nostretch_draw_386_bottop:
   
      mov   byte ptr ds:[SELFMODIFY_BSP_set_dc_iscale_hi_top+2], cl
      mov   byte ptr ds:[SELFMODIFY_BSP_set_dc_iscale_hi_bot+2], cl

      SELFMODIFY_set_top_lookup_offset_setter_nostretch_funcaddr:
      mov   word ptr ds:[SELFMODIFY_COLFUNC_set_func_offset_top], 01000h
      ENSUREALIGN_085:
      SELFMODIFY_set_bot_lookup_offset_setter_nostretch_funcaddr:
      mov   word ptr ds:[SELFMODIFY_COLFUNC_set_func_offset_bot], 01000h
      ENSUREALIGN_086:

   jmp  done_setting_386_bottop_draws
   ALIGN_MACRO
   do_stretch_draw_386_bottop:
      SELFMODIFY_set_top_lookup_offset_setter_withstretch_funcaddr_1:
      mov   word ptr ds:[SELFMODIFY_COLFUNC_set_func_offset_top], 01000h
      ENSUREALIGN_087:
      SELFMODIFY_set_bot_lookup_offset_setter_withstretch_funcaddr_1:
      mov   word ptr ds:[SELFMODIFY_COLFUNC_set_func_offset_bot], 01000h
      ENSUREALIGN_088:

   done_setting_386_bottop_draws:



   jmp FastDiv3232FFFF_done_TWOSIDED 
   ALIGN_MACRO

ELSE

   test cx, cx
   jne main_3232_div_TWOSIDED

   ; toggle for ENSUREALIGN_085
   
   ; get FFFF in cx (which is 0) and 0 in dx
   mov  dx, cx
   dec  cx
   mov  ax, cx  ; ax = -1


      ; todo put stuff in reg

   div bx        ; after this dx stores remainder, ax stores q1
; stretch draw off path

   mov   byte ptr ds:[SELFMODIFY_BSP_set_dc_iscale_hi_top+2], al

   mov   byte ptr ds:[SELFMODIFY_BSP_set_dc_iscale_hi_bot+2], al
   xchg  cx, ax   ; q1 to cx, ffff to ax  so div remainder:ffff 

   div bx
   ; cx:ax is result 
   ; ch is known zero.

   SELFMODIFY_set_top_lookup_offset_setter_nostretch_funcaddr:
   mov   word ptr ds:[SELFMODIFY_COLFUNC_set_func_offset_top], 01000h
   ENSUREALIGN_085:
   SELFMODIFY_set_bot_lookup_offset_setter_nostretch_funcaddr:
   mov   word ptr ds:[SELFMODIFY_COLFUNC_set_func_offset_bot], 01000h
   ENSUREALIGN_086:
   ; only write to dc_iscale_hi when nonzero.

   jmp FastDiv3232FFFF_done_TWOSIDED    ; todo branch better 
   ALIGN_MACRO


   main_3232_div_TWOSIDED:


  ; todo dont use di, use dx instead

   mov  ax, -1

   ; generally cx maxes out at around 5 bits of precision? bias towards shift right instead of left.  

   xor dx, dx

REPT 6
   shr cx, 1
   jz  done_shifting_3232_TWOSIDED
   rcr bx, 1
   rcr dx, 1
   shr ax, 1

ENDM



   shr cx, 1
   ; todo shouldnt fall thru here? if it does may crash with dxvide overflow down the line.

   ; store this
   ALIGN_MACRO
   done_shifting_3232_TWOSIDED:

   ; continue the last bit
   rcr bx, 1
   rcr dx, 1
    ; todo bench branch
   jnz do_full_div_ffff_TWOSIDED
   
   ALIGN_MACRO       ; very rare fall thru case and common jump to case
   do_single_div_FFFF_TWOSIDED:
   ENSUREALIGN_091:
   ; bx has entire dividend, in 16 bits of precision. we know cx and di are zero after all.
   ; si contains a bit count of how much to shift result left by...

   shr ax, 1   ; still gotta continue to shift the last ax/si

   ; i want to skip last rcr si but it makes detecting the 0 case hard.
   dec  dx        ; make it 0FFFFh
   xchg ax, dx    ; ax all 1s,  dx 0 leading 1s
   div  bx

   ; cx is zero already coming in from the first shift so cx:ax is already the result.

; stretch draw on path

   SELFMODIFY_set_top_lookup_offset_setter_withstretch_funcaddr_1:
   mov   word ptr ds:[SELFMODIFY_COLFUNC_set_func_offset_top], 01000h
   ENSUREALIGN_087:
   SELFMODIFY_set_bot_lookup_offset_setter_withstretch_funcaddr_1:
   mov   word ptr ds:[SELFMODIFY_COLFUNC_set_func_offset_bot], 01000h
   ENSUREALIGN_088:

   jmp FastDiv3232FFFF_done_TWOSIDED
   ALIGN_MACRO

   do_full_div_ffff_TWOSIDED:
   
   ; cx is 0
   dec  cx      ; cx now 0FFFFh, will go into ax..

   shr  ax, 1
   xchg ax, dx  ; dx gets target value, ax gets desired cx value
   xchg ax, cx  ; ax gets -1, cx gets denominator low
   
   
   mov es, dx   ; save numlo word in es, NEEDS TO BE NOTed


; todo register juggle below 

   ; DX:AX:ES holds divisor...
   ; BX:CX holds dividend...
   ; numhi = DX:AX
   ; numlo = ES:00... (es needs NOT)



   ; set up first div. 
   ; dx:ax becomes numhi


   ; store these two long term...



   ; numhi is 00:cx in this case?

   ;	divresult.wu = DIV3216RESULTREMAINDER(numhi.wu, den1);
   ; DX:AX = numhi.wu

   div   bx
; stretch draw on path
   ; gross. should clean up masively once this is all in cs.

   SELFMODIFY_set_top_lookup_offset_setter_withstretch_funcaddr_2:
   mov   word ptr ds:[SELFMODIFY_COLFUNC_set_func_offset_top], 01000h
   ENSUREALIGN_089:


   ; rhat = dx
   ; qhat = ax
   ;    c1 = FastMul16u16u(qhat , den0);

   mov   word ptr ds:[_SELFMODIFY_get_qhat_TWOSIDED+1], ax     ; store qhat. use div's prefetch to juice this...

   mov   si, dx					; si stores rhat

   mul   cx   						; DX:AX = c1
; stretch draw on path

   SELFMODIFY_set_bot_lookup_offset_setter_withstretch_funcaddr_2:
   mov   word ptr ds:[SELFMODIFY_COLFUNC_set_func_offset_bot], 01000h
   ENSUREALIGN_090: ; todo align

   ; c1 hi = dx, c2 lo = es (needs NOT)
   sub   dx, si      ; cmp and sub at same time... 


   jb    q1_ready_3232_TWOSIDED
   mov   si, es   ; si get numlo
   not   si
   jne   check_c1_c2_diff_3232_TWOSIDED
   cmp   ax, si
   jbe   q1_ready_3232_TWOSIDED
   check_c1_c2_diff_3232_TWOSIDED:

   ; (c1 - c2.wu > den.wu)
   sub   ax, si
   sbb   dx, 0    ; already subbed without borrow.
   cmp   dx, bx
   mov   si, 1                
   ja    qhat_subtract_2_3232_TWOSIDED
   jne   finalize_div_TWOSIDED


   ; compare low word..
   cmp   ax, cx
   jbe   finalize_div_TWOSIDED

   ; ugly but rare occurrence i think?
   qhat_subtract_2_3232_TWOSIDED:
   inc  si
   jmp finalize_div_TWOSIDED
   ALIGN_MACRO

   
   q1_ready_3232_TWOSIDED:
   mov  si, 0   ; no sub case. toggle with xor si, si for ENSUREALIGN_099
   finalize_div_TWOSIDED:
   _SELFMODIFY_get_qhat_TWOSIDED:
   mov  ax, 01000h
   ENSUREALIGN_099:

   sub  ax, si ; modify qhat by measured amount
   jmp  FastDiv3232FFFF_done_TWOSIDED



ENDIF


ALIGN_MACRO


SELFMODIFY_BSP_set_seglooptexrepeat0_TARGET_TWOSIDED:
non_repeating_texture0_top:
cmp   dx, word ptr ds:[_segloopnextlookup]
jge   out_of_texture_bounds0_top
cmp   dx, word ptr ds:[_segloopprevlookup] ; todo ss, ds-> cs etc
jnge   out_of_texture_bounds0_top
xchg  ax, dx
sub   al, byte ptr ss:[_segloopcachedbasecol]
mul   byte ptr ds:[_segloopheightvalcache]
jmp   add_base_segment_and_draw0_top
ALIGN_MACRO
out_of_texture_bounds0_top:
; branch nonpush with moves etc. 
mov   ax, ss
mov   ds, ax
push  bx
SELFMODIFY_BSP_set_toptexture:

mov   ax, 01000h
mov   bx, 0
call  R_GetColumnSegment_ ; todo is di, si used?
ENSUREALIGN_310:

mov   dx, word ptr ds:[_segloopcachedsegment]
mov   bx, cs
mov   ds, bx
pop   bx
mov   word ptr ds:[SELFMODIFY_add_cached_segment0_TWOSIDED+1], dx


; todohigh get this dh and dl in same read?
mov   cl, 0B8h  ; mov ax, xxxx
mov   dh, byte ptr ds:[_seglooptexrepeat]
mov   dl, byte ptr ds:[_segloopheightvalcache]
test  dh, dh
jne   seglooptexrepeat0_is_not_jmp_top
mov   dx, (SELFMODIFY_BSP_set_seglooptexrepeat0_TARGET_TWOSIDED - SELFMODIFY_BSP_set_seglooptexrepeat0_AFTER_TWOSIDED)
mov   cl, 0E9h  ; jmp 

seglooptexrepeat0_is_not_jmp_top:
; modulo is seglooptexrepeat - 1
mov   byte ptr ds:[SELFMODIFY_BSP_check_seglooptexmodulo0_TWOSIDED],   cl
mov   word ptr ds:[SELFMODIFY_BSP_check_seglooptexmodulo0_TWOSIDED+1], dx

jmp   just_do_draw0_top


record_masked:

;if (maskedtexture) {
;	// save texturecol
;	//  for backdrawing of masked mid texture			
;	maskedtexturecol[rw_x] = texturecolumn;
;}

xchg  ax, si  ; backup si
les   si, dword ptr ds:[_maskedtexturecol_bsp]
add   si, bx  ; bx byte ptr
mov   word ptr es:[bx+si], dx  ; add bx again, word ptr
xchg  ax, si ; restore

jmp   finished_recording_masked
ALIGN_MACRO

SELFMODIFY_BSP_toptexture_TARGET:

; ds = cs here.
; bx is already rw_x
mov   cl, byte ptr ds:[bx+OFFSET_CEILINGCLIP]  ; set up ceilclip in this path.
SELFMODIFY_BSP_markceiling_2_TWOSIDED:
jmp  check_bottom_texture_TWOSIDED  ; 3 byte, can become mov ax, imm16
SELFMODIFY_BSP_markceiling_2_AFTER_TWOSIDED:

mark_ceiling_si_TWOSIDED:
; this value comes out bad for al. sometimes.
lea   ax, [si - 1]
skip_set_ax_to_si:
mark_ceiling_ax_TWOSIDED:
mov   cl, byte ptr ds:[bx+OFFSET_CEILINGCLIP]  ; set up ceilclip in this path.
jmp   do_mark_ceiling_and_end_topdraw
ALIGN_MACRO


FastDiv3232FFFF_done_TWOSIDED:
; result is in CX:AX
; do the bit shuffling etc when writing direct to drawcol.

; todo write after a div in the function? in various spots?
mov   word ptr ds:[SELFMODIFY_BSP_set_dc_iscale_lo_top+1], ax
mov   word ptr ds:[SELFMODIFY_BSP_set_dc_iscale_lo_bot+1], ax
; dc_iscale_hi was written ealier if nonzero

; restore ds


; get texturecolumn     in dx
pop   dx

seg_non_textured_TWOSIDED:
; si/di are yh/yl
;if (yh >= yl){
mov   bx, di 			; store rw_x


; dx holds texturecolumn
; get yl/yh in di/cx
pop   di
pop   si


; start toptexture stuff


SELFMODIFY_get_maskedtexture_1_TWOSIDED:
; todo make this not a selfmodify mov and test. 
mov   al, 0
test  al, al
jnz   record_masked

finished_recording_masked:


SELFMODIFY_BSP_toptexture:
SELFMODIFY_BSP_toptexture_AFTER = SELFMODIFY_BSP_toptexture + 3
public SELFMODIFY_BSP_toptexture_AFTER
do_top_texture_draw:  ; not a jump target.
PUBLIC do_top_texture_draw

; TOP DRAW CEIL/FLOOR CHECKS HERE
; todo restore bp from something? to remove bp dependency
SELFMODIFY_BSP_set_pixhigh:
mov   ax, 01000h      ; THIS_IS_A_SELFMODIFIED_INSTRUCTION_TARGET  ; pixhigh
ENSUREALIGN_013:

mov   cl, byte ptr ds:[bx + OFFSET_FLOORCLIP]

SELFMODIFY_add_to_pixhigh_lo_1_TWOSIDED:
sub   word ptr ds:[_cs_pixhigh], 01000h
ENSUREALIGN_094:
SELFMODIFY_add_to_pixhigh_hi_1_TWOSIDED:
sbb   word ptr ds:[SELFMODIFY_BSP_set_pixhigh+1], 01000h
ENSUREALIGN_095:
; bx is rw_x 

; todo reduce 16 bit logic, use 8 bit logic.

xor   ch, ch
cmp   ax, cx
jl    dont_clip_top_floor_TWOSIDED  ; todo branch test
; toggle this for ENSUREALIGN_009
xchg  ax, cx
;mov   ax, cx
dec   ax

dont_clip_top_floor_TWOSIDED:
cmp   ax, si
jl    mark_ceiling_si_TWOSIDED  ; skip drawing ceiling.
cmp   di, si
jle   mark_ceiling_ax_TWOSIDED  ; skip drawing ceiling.

dont_mark_ceiling_ax_TWOSIDED:
xchg   ax, di  ; todo maybe this xchg doesnt need to be here; swap above register logic.
; si:di are dc_yl, dc_yh

; START TOP DRAW??





; si:di are dc_yl, dc_yh   

; todo: pusha is faster but we are only using 5 values.
; any clever way to get CX, BP to also carry something useful?

; store for bottom draw.

COMMENT @
push   ax ; store celip 
push   dx  ; texturecolumn
push   si ; dc_yl
push   di ; dc_yh
push   bx ; rw_x
@

PUSHA_BSP_BOTTOP_MACRO




; note: bx is dc_x...
SELFMODIFY_BSP_detailshift2minus_top:
sar   bx, 1    ; todo would love to get rid of these. happening for every column even if shift not needed.
sar   bx, 1

lea   bp, [si + bsp_local_dc_yl_lookup_table_ - 2]
add   bx, word ptr ds:[si+bp]                   ; add * 80 lookup table value 

; inlined function. 
R_GetSourceSegment0_START_TWOSIDED:
PUBLIC  R_GetSourceSegment0_START_TWOSIDED



; okay. we modify the first instruction in this argument. 
 ; if no texture is yet cached for this rendersegloop, jmp to non_repeating_texture
  ; if one is set, then the result of the predetermined value of seglooptexmodulo might it into a jump
   ; if its a repeating texture  then we modify it to mov ah, segloopheightvalcache

SELFMODIFY_BSP_check_seglooptexmodulo0_TWOSIDED:
SELFMODIFY_BSP_set_seglooptexrepeat0_TWOSIDED:
; 3 bytes. May become one of two jumps (three bytes) or mov ax, imm16 (three bytes)
jmp    non_repeating_texture0_top

SELFMODIFY_BSP_set_seglooptexrepeat0_AFTER_TWOSIDED = SELFMODIFY_BSP_check_seglooptexmodulo0_TWOSIDED + 3

SELFMODIFY_BSP_check_seglooptexmodulo0_AFTER_TWOSIDED:
public SELFMODIFY_BSP_check_seglooptexmodulo0_AFTER_TWOSIDED
xchg  ax, ax                    ; one byte nop placeholder. this gets the ah value in mov ax, xxxx (byte 3)
and   dl, ah   ; ah has loopwidth-1 (modulo )
mul   dl       ; al has heightval

add_base_segment_and_draw0_top:  ; align target?
SELFMODIFY_add_cached_segment0_TWOSIDED:
add   ax, 01000h

ENDP

just_do_draw0_top:
public just_do_draw0_top
ENSUREALIGN_093:


; ax carries _dc_source_segment

mov   ds, ax ; set _dc_source_segment


R_DrawColumnPrepTop:
PUBLIC R_DrawColumnPrepTop


SELFMODIFY_COLFUNC_sub_centery24_top:
lea   ax, [si - 010h] ; dc_yl - centery


sub   si, di  ; ; yl - yh

SELFMODIFY_BSP_add_destview_offset_top:
lea   di, [bx + 01000h] ; rare, doesnt have to align

; dc_iscale loaded here..
SELFMODIFY_BSP_set_dc_iscale_lo_top:
mov   bx, 01000h        ; dc_iscale +0
ENSUREALIGN_015:

shl   si, 1
add   si, 398

mov   dx, si  ; 2, 2   dx already multiplied by 2
shl   dx, 1   ; 4, 2
SELFMODIFY_set_pixel_count_shift_mul_top:
public SELFMODIFY_set_pixel_count_shift_mul_top
add   dx, si  ; 6, 2     ; swap these two for 10x - 4, 8, 10 from shl, then add order swap
shl   dx, 1   ; 12, 2    ; is there a way to swap just one instruction, while not adding instruction count?
ENSUREALIGN_024:  




SELFMODIFY_set_toptexturemid_hi:
SELFMODIFY_BSP_set_dc_iscale_hi_top:
mov   cx, 01000h        ; dc_iscale +2 hi, toptexturemid hi lo. byte writes, doesnt have to align

SELFMODIFY_set_toptexturemid_lo:
mov   si, 01000h          ; once per storewallrange, doesnt have to align
ENSUREALIGN_025:  


SELFMODIFY_BSP_set_xlat_offset_TWOSIDED:
mov   bp, 01000h          ; byte write, doesnt have to align
; pass in xlat offset for bx via bp

SELFMODIFY_BSP_R_DrawColumnPrep_call_top:
db 09Ah
SELFMODIFY_COLFUNC_set_func_offset_top:
dw DRAWCOL_OFFSET_BSP, COLORMAPS_SEGMENT
ENSUREALIGN_009:

mov   dx, cs
mov   ds, dx



; this runs as a jmp for a top call, otherwise NOP for mid call
R_GetSourceSegment0_DONE_TOP:
public R_GetSourceSegment0_DONE_TOP

POPA_BSP_BOTTOP_MACRO

COMMENT @
pop   bx  ; rw_x  always want this back
pop   ax  ; dc_yh
pop   si  ; dc_yl
pop   dx  ; textuecolumn
pop   di  ; todo whats this again. something for floorclip? yl-1?
@

; END TOP DRAW??


; bx is currently rw_x.

do_mark_ceiling_and_end_topdraw:
mov   byte ptr ds:[bx  + OFFSET_CEILINGCLIP], al
xchg  ax, cx   ; cl gets ceilclip
SELFMODIFY_BSP_markceiling_2_TARGET_TWOSIDED:
check_bottom_texture_TWOSIDED:
; bx is already rw_x

SELFMODIFY_BSP_bottexture:
SELFMODIFY_BSP_bottexture_AFTER = SELFMODIFY_BSP_bottexture + 2


; START BOT DRAW??


SELFMODIFY_BSP_set_pixlow:
public SELFMODIFY_BSP_set_pixlow
mov   ax, 01000h   ; ; THIS_IS_A_SELFMODIFIED_INSTRUCTION_TARGET pixlow hi
ENSUREALIGN_012:

SELFMODIFY_add_to_pixlow_lo_1_TWOSIDED:
sub   word ptr ds:[_cs_pixlow], 01000h
ENSUREALIGN_096:
SELFMODIFY_add_to_pixlow_hi_1_TWOSIDED:
sbb   word ptr ds:[SELFMODIFY_BSP_set_pixlow+1], 01000h
ENSUREALIGN_097:
;		if (mid <= ceilingclip[rw_x])
;		    mid = ceilingclip[rw_x]+1;
; cl already has ceilclip

xor   ch, ch

cmp   ax, cx
jg    dont_clip_bot_ceil ; todo branch test
inc   cx
; toggle for ENSUREALIGN_010
;xchg  ax, cx
mov   ax, cx

;		if (mid <= yh)

dont_clip_bot_ceil:
cmp   ax, di
jg    mark_floor_di  ; todo branch test

;		if (markfloor)
;		    floorclip[rw_x] = yh+1;

cmp   di, si  ; todo sub and get this for free?
mov   byte ptr ds:[bx+OFFSET_FLOORCLIP], al
jle   done_marking_floor_TWOSIDED     ; todo branch test

; todo this is messy
xchg   ax, si
; si:di are dc_yl, dc_yh


; todo move the post R_GetSourceSegment1_ logic here. 



push  bx ; dc_x

; note: bx is dc_x...
SELFMODIFY_BSP_detailshift2minus_bot:
sar   bx, 1    ; todo would love to get rid of these. happening for every column even if shift not needed.
sar   bx, 1

lea   bp, [si + bsp_local_dc_yl_lookup_table_ - 2]
add   bx, word ptr ds:[si+bp]                   ; add * 80 lookup table value 


; BEGIN INLINED R_GetSourceSegment1_
R_GetSourceSegment1_:
PUBLIC R_GetSourceSegment1_


SELFMODIFY_BSP_check_seglooptexmodulo1:
SELFMODIFY_BSP_set_seglooptexrepeat1_TWOSIDED:
; 3 bytes. May become one of two jumps (two bytes) or mov ax, imm16 (three bytes)
jmp SHORT non_repeating_texture1

SELFMODIFY_BSP_set_seglooptexrepeat1_AFTER_TWOSIDED:
public SELFMODIFY_BSP_set_seglooptexrepeat1_AFTER_TWOSIDED

;ALIGN_MACRO
xchg  ax, ax                    ; one byte nop placeholder. this gets the ah value in mov ax, xxxx (byte 3)
and   dl, ah   ; ah has loopwidth-1 (modulo )
mul   dl       ; al has heightval
add_base_segment_and_draw1:
SELFMODIFY_add_cached_segment1:
add   ax, 01000h
ENSUREALIGN_098:  

just_do_draw1:
public just_do_draw1
; ax carries _dc_source_segment

mov   ds, ax ; set _dc_source_segment





SELFMODIFY_COLFUNC_sub_centery24_bot:
lea   ax, [si - 010h] ; dc_yl - centery



sub   si, di  ; yl - yh

SELFMODIFY_BSP_add_destview_offset_bot:
lea   di, [bx + 01000h]

SELFMODIFY_BSP_set_dc_iscale_lo_bot:   ; gross but works 
mov   bx, 01000h
ENSUREALIGN_014:  


shl   si, 1
add   si, 398

mov   dx, si  ; 2, 2   dx already multiplied by 2
shl   dx, 1   ; 4, 2
SELFMODIFY_set_pixel_count_shift_mul_bot:
public SELFMODIFY_set_pixel_count_shift_mul_bot
add   dx, si  ; 6, 2     ; swap these two for 10x - 4, 8, 10 from shl, then add order swap
shl   dx, 1   ; 12, 2    ; is there a way to swap just one instruction, while not adding instruction count?
ENSUREALIGN_023:




SELFMODIFY_set_bottexturemid_hi:
SELFMODIFY_BSP_set_dc_iscale_hi_bot:   ; byte writes, dont need to be aligned
mov   cx, 01000h


SELFMODIFY_set_bottexturemid_lo:
mov   si, 01000h ; todo odd
ENSUREALIGN_022:

SELFMODIFY_BSP_set_xlat_offset_bot:
mov   bp, 01000h ; byte write, doesnt need to be aligned


SELFMODIFY_BSP_R_DrawColumnPrep_call_bot:
db 09Ah
SELFMODIFY_COLFUNC_set_func_offset_bot:
dw DRAWCOL_OFFSET_BSP, COLORMAPS_SEGMENT
ENSUREALIGN_010:


; the pop bx gets replaced with ret if bottom is calling.
; todo: the bottom caller pops the same stuff. pop here and modify a later instruction instead?



pop   bx ; restore dc_x


;END INLINED R_GetSourceSegment1_

SELFMODIFY_BSP_markfloor_2_TARGET_TWOSIDED:
done_marking_floor_TWOSIDED:
jmp   finished_inner_loop_iter_TWOSIDED
ALIGN_MACRO
SELFMODIFY_BSP_bottexture_TARGET:

SELFMODIFY_BSP_markfloor_2_TWOSIDED:
SELFMODIFY_BSP_markfloor_2_AFTER_TWOSIDED = SELFMODIFY_BSP_markfloor_2_TWOSIDED+2

mark_floor_di:
public mark_floor_di

   ;floorclip[rw_x] = yh + 1;
xchg  ax, di         ; THIS_IS_A_SELFMODIFIED_INSTRUCTION_TARGET
inc   ax             ; THIS_IS_A_SELFMODIFIED_INSTRUCTION_TARGET
mov   byte ptr ds:[bx+OFFSET_FLOORCLIP], al
jmp   finished_inner_loop_iter_TWOSIDED

ALIGN_MACRO
;BEGIN INLINED R_GetSourceSegment1_ AGAIN
; this was only called in one place. this runs often, so inline it.

SELFMODIFY_BSP_set_seglooptexrepeat1_TARGET_TWOSIDED:
public SELFMODIFY_BSP_set_seglooptexrepeat1_TARGET_TWOSIDED
non_repeating_texture1:
; finally set dx back to texturecolumn in this case

cmp   dx, word ptr ds:[2 + _segloopnextlookup]
jge   out_of_texture_bounds1
cmp   dx, word ptr ds:[2 + _segloopprevlookup]
jnge  out_of_texture_bounds1  

xchg  ax, dx  ; put texturecol in ax
sub   al, byte ptr ss:[2 + _segloopcachedbasecol]
mul   byte ptr ds:[1 + _segloopheightvalcache]
jmp   add_base_segment_and_draw1
ALIGN_MACRO
out_of_texture_bounds1:
push  bx
mov   ax, ss
mov   ds, ax

SELFMODIFY_BSP_set_bottomtexture:
mov   ax, 01000h
ENSUREALIGN_084:
mov   bx, 1
call  R_GetColumnSegment_ ;todo is di, si used?
ENSUREALIGN_083:
mov   dx, word ptr ds:[2 + _segloopcachedsegment]
mov   bx, cs
mov   ds, bx
pop   bx

; todo: ds = cs here
mov   word ptr ds:[SELFMODIFY_add_cached_segment1+1], dx




; todo get this dh and dl in same read
mov   dh, byte ptr ds:[1 + _seglooptexrepeat]
test  dh, dh
je    seglooptexrepeat1_is_jmp
; modulo is seglooptexrepeat - 1
mov   dl, byte ptr ds:[1 + _segloopheightvalcache]
mov   byte ptr ds:[SELFMODIFY_BSP_check_seglooptexmodulo1],   0B8h   ; mov ax, xxxx
mov   word ptr ds:[SELFMODIFY_BSP_check_seglooptexmodulo1+1], dx

jmp   just_do_draw1
ALIGN_MACRO
; do jmp. highest priority, overwrite previously written thing.
seglooptexrepeat1_is_jmp:
mov   word ptr ds:[SELFMODIFY_BSP_set_seglooptexrepeat1_TWOSIDED], ((SELFMODIFY_BSP_set_seglooptexrepeat1_TARGET_TWOSIDED - SELFMODIFY_BSP_set_seglooptexrepeat1_AFTER_TWOSIDED) SHL 8) + 0EBh
jmp   just_do_draw1
;END INLINED R_GetSourceSegment1_ AGAIN



ALIGN_MACRO

R_RenderSegLoop_exit_TWOSIDED:
public R_RenderSegLoop_exit_TWOSIDED

; enter with ds = cs
; bp restore:

SELFMODIFY_restore_bp_after_draw_topbot:
mov   bp, 01000h



; clean up the self modified code of renderseg loop. 
mov   byte ptr ds:[SELFMODIFY_BSP_set_seglooptexrepeat0_TWOSIDED], 0E9h
mov   word ptr ds:[SELFMODIFY_BSP_set_seglooptexrepeat0_TWOSIDED+1], (SELFMODIFY_BSP_set_seglooptexrepeat0_TARGET_TWOSIDED - SELFMODIFY_BSP_set_seglooptexrepeat0_AFTER_TWOSIDED )
mov   word ptr ds:[SELFMODIFY_BSP_set_seglooptexrepeat1_TWOSIDED], ((SELFMODIFY_BSP_set_seglooptexrepeat1_TARGET_TWOSIDED - SELFMODIFY_BSP_set_seglooptexrepeat1_AFTER_TWOSIDED) SHL 8) + 0EBh



; note: we can jump  intot his exit path from far away!!
; sp should be bp - 6

mov       si, word ptr [bp - 020h]

xor       cx, cx ; cx always zero going thru this.

les       bx, dword ptr ds:[_ds_p_bsp]
test      byte ptr es:[bx + DRAWSEG_T.drawseg_silhouette], SIL_TOP
jne       continue_checking_spr_top_clip_TWOSIDED
cmp       byte ptr ds:[_maskedtexture_bsp], cl ; 0
je        check_spr_bottom_clip_TWOSIDED



continue_checking_spr_top_clip_TWOSIDED:

cmp       word ptr es:[bx + DRAWSEG_T.drawseg_sprtopclip_offset], cx ; 0
jne       check_spr_bottom_clip_TWOSIDED


mov       di, word ptr ds:[_lastopening]
mov       dx, di ; backup startx
sub       dx, si
mov       word ptr es:[bx + DRAWSEG_T.drawseg_sprtopclip_offset], dx

mov       dx, si ; backup startx


mov       cx, OPENINGS_SEGMENT
mov       es, cx


SELFMODIFY_set_cx_to_count_1_TWOSIDED:
mov       cx, 01000h


add       si, OFFSET OFFSET_CEILINGCLIP


rep       movsw ; cx 0 again after this

mov       word ptr ds:[_lastopening], di

mov       si, dx ; restore startx

mov       es, word ptr ds:[_ds_p_bsp+2]   ; bx is ds_p offset above

check_spr_bottom_clip_TWOSIDED:
; es:bx is ds_p

; todo is a better branch strategy faster?

test      byte ptr es:[bx + DRAWSEG_T.drawseg_silhouette], SIL_BOTTOM
jne       continue_checking_spr_bottom_clip_TWOSIDED
cmp       byte ptr ds:[_maskedtexture_bsp], cl ; 0
je        check_silhouettes_then_exit_TWOSIDED
jmp       continue_checking_spr_bottom_clip_TWOSIDED
ALIGN_MACRO
continue_checking_spr_bottom_clip_TWOSIDED:
cmp       word ptr es:[bx + DRAWSEG_T.drawseg_sprbottomclip_offset], cx ; 0
jne       check_silhouettes_then_exit_TWOSIDED

; si already startx
mov       di, word ptr ds:[_lastopening]

mov       dx, di
sub       dx, si
mov       word ptr es:[bx + DRAWSEG_T.drawseg_sprbottomclip_offset], dx

mov       cx, OPENINGS_SEGMENT
mov       es, cx

SELFMODIFY_set_cx_to_count_2_TWOSIDED:
mov       cx, 01000h


add       si, OFFSET OFFSET_FLOORCLIP

rep       movsw ; cx 0 again after this


mov       word ptr ds:[_lastopening], di

mov       es, word ptr ds:[_ds_p_bsp+2]   ; bx is ds_p offset above

; todo is a better branch strategy faster?

check_silhouettes_then_exit_TWOSIDED:
cmp       byte ptr ds:[_maskedtexture_bsp], cl ; 0
je        skip_top_silhouette_TWOSIDED
test      byte ptr es:[bx + DRAWSEG_T.drawseg_silhouette], SIL_TOP
jne       skip_top_silhouette_TWOSIDED
or        byte ptr es:[bx + DRAWSEG_T.drawseg_silhouette], SIL_TOP
mov       word ptr es:[bx + DRAWSEG_T.drawseg_tsilheight], MINSHORT
skip_top_silhouette_TWOSIDED:

cmp       byte ptr cs:[_maskedtexture_bsp], cl ; 0
je        skip_bot_silhouette_TWOSIDED
test      byte ptr es:[bx + DRAWSEG_T.drawseg_silhouette], SIL_BOTTOM
jne       skip_bot_silhouette_TWOSIDED
or        byte ptr es:[bx + DRAWSEG_T.drawseg_silhouette], SIL_BOTTOM
mov       word ptr es:[bx + DRAWSEG_T.drawseg_bsilheight], MAXSHORT
skip_bot_silhouette_TWOSIDED:
add       word ptr ds:[_ds_p_bsp], (SIZE DRAWSEG_T)

add       sp, STOREWALLRANGE_INNER_STACK_SIZE_BOTTOP     ; add back fixed SP

mov       si, ss
mov       ds, si

SELFMODIFY_mark_planes_dirty_TWOSIDED:
public SELFMODIFY_mark_planes_dirty_TWOSIDED 
mov       ch, 0
shr       cx, 1
jnz       mark_planes_dirty_TWOSIDED ; common case is fall thru.

; pops on outside

ret       

ALIGN_MACRO
mark_planes_dirty_TWOSIDED:
public mark_planes_dirty_TWOSIDED
mov      byte ptr cs:[SELFMODIFY_mark_planes_dirty_TWOSIDED+1], al ; al still known 0
mov      bl, JMP_SHORT_REL8_OPCODE
mov      byte ptr cs:[SELFMODIFY_skip_markceildirty], bl
mov      byte ptr cs:[SELFMODIFY_skip_markfloordirty], bl

mov      si, _visplaneheaders + VISPLANEHEADER_T.visplaneheader_dirty
; al/ah are zero or nonzero depending on state..
les      bx, dword ptr cs:[_ceilingplaneindex]
or       byte ptr ds:[bx+si], ch
mov      bx, es
or       byte ptr ds:[bx+si], cl

; pops on outside

ret       



ENDP



SEG_LINEDEFS_OFFSET_IN_LINEFLAGSLIST =  ((SEG_LINEDEFS_SEGMENT - LINEFLAGSLIST_SEGMENT) SHL 4)
SEG_SIDES_OFFSET_IN_LINEFLAGSLIST    = ((SEG_SIDES_SEGMENT - LINEFLAGSLIST_SEGMENT) SHL 4)



SUBSECTOR_OFFSET_IN_SECTORS       = (SUBSECTORS_SEGMENT - SECTORS_SEGMENT) * 16
;SUBSECTOR_LINES_OFFSET_IN_SECTORS = (SUBSECTOR_LINES_SEGMENT - SECTORS_SEGMENT) * 16

;R_Subsector_

ALIGN_MACRO
revert_visplane:
call  Z_QuickMapVisplaneRevert_BSPLocal_ ;  doesn't ruin ES i guess
les   bx, dword ptr cs:[_frontsector]  ; retrieve frontsector? 
jmp   prepare_fields

ALIGN_MACRO

PROC   R_Subsector_ NEAR
PUBLIC R_Subsector_ 


;ax is subsecnum



xchg  ax, bx
mov   ax, SUBSECTOR_LINES_SEGMENT
mov   es, ax

xor   ax, ax
xlat  byte ptr es:[bx]


mov   dx, SECTORS_SEGMENT
mov   es, dx

SHIFT_MACRO shl bx 2   ; TODO push this (and sectors_segment?) as frontsectorptr? then les that not _frontsector

sub   sp, 0Ah          ; for sector fields to be lazily added in R_StoreWallRange_


push  word ptr es:[bx+SUBSECTOR_OFFSET_IN_SECTORS + SUBSECTOR_T.ss_firstline]   ; get subsec firstline ; bp + 4
push  ax  ; store count  ; bp + 2

mov   bx, word ptr es:[bx+SUBSECTOR_OFFSET_IN_SECTORS + SUBSECTOR_T.ss_secnum] ; get subsec secnum
mov   word ptr cs:[_frontsector], bx


cmp   byte ptr cs:[_visplanedirty], 0
jne   revert_visplane      ; todo branch test

prepare_fields:

;	ceilphyspage = 0;
;	floorphyspage = 0;
;	ceiltop = NULL;
;	floortop = NULL;

xor   ax, ax

mov   word ptr cs:[_ceilphyspage], ax  ; also writes _floorphyspage
mov   word ptr cs:[_ceiltop], ax 
mov   word ptr cs:[_floortop], ax


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
les   bx, dword ptr cs:[_frontsector]  ; retrieve frontsector
set_floor_plane:
mov   word ptr cs:[_floorplaneindex], ax

floor_plane_set:
mov   ax, 0FFFFh  ; -1 case
mov   dx, word ptr es:[bx + SECTOR_T.sec_ceilingheight]

check_for_sky:
; es:bx is still frontsector
mov   cl, byte ptr es:[bx + SECTOR_T.sec_ceilingpic] 
SELFMODIFY_BSP_set_skyflatnum_2:
cmp   cl, 010h
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
les   bx, dword ptr cs:[_frontsector]    ; retrieve frontsector
set_ceiling_plane:
mov   word ptr cs:[_ceilingplaneindex], ax

do_addsprites:

; todo create stack frame space here. possibly put things on stack, or just lazily do it later.


; R_SUBSECTOR CREATES STACKFRAME HERE
; projectsprite may get called and use it
; addline will use it iteratively
; if we create the stack frame here, ax/cx would be on stack and accessible without necessarily having to go back to register every time.
                        ; bp + 4 is line  
                        ; bp + 2 is count 
push  bp                ; bp + 0          
mov   bp, sp
mov   word ptr cs:[SELFMODIFY_reset_sp+1], sp  ; store stack pointer for loop iter repeats




; es:bx already frontsector



;R_AddSprites_ inlined

; es:bx = sector_t __far* sec
SELFMODIFY_BSP_validcountglobal:
mov   ax, 01000h
cmp   ax, word ptr es:[bx + SECTOR_T.sec_validcount]		 ; sec->validcount

je    exit_add_sprites_quick  ; todo branch test. fall through ret is likely faster.

mov   word ptr es:[bx + SECTOR_T.sec_validcount], ax

mov       al, byte ptr es:[bx + SECTOR_T.sec_lightlevel]		; sec->lightlevel

SHIFT_MACRO shr al 4  ; only 3; got the word lookup for free
cbw

SELFMODIFY_BSP_extralight1:
add       al, 0

shl       ax, 1
xchg      ax, si
mov       ax, word ptr cs:[_mul48lookup_with_scalelight + si]


mov   word ptr cs:[SELFMODIFY_set_spritelights_1 + 2], ax 
mov   si, word ptr es:[bx + SECTOR_T.sec_thinglistref]
test  si, si
je    exit_add_sprites

loop_things_in_thinglist:
ENSUREALIGN_020:
mov   ax, MOBJPOSLIST_SEGMENT
mov   es, ax
mov   ax, word ptr es:[si + MOBJ_POS_T.mp_snextRef]
mov   word ptr cs:[SELFMODIFY_BSP_get_next_thing_in_sector+1], ax
SELFMODIFY_set_playermobjpos:
cmp   si, 01000h
je    skip_this_sprite
; es:si set, R_ProjectSprite doesnt need to push/pop.
jmp   R_ProjectSprite_    ; todo inline
ALIGN_MACRO
done_with_r_projectsprite:

mov   sp, bp  ; restore sp
skip_this_sprite:
public skip_this_sprite



db DS_PREFIX_OPCODE  ; padding
SELFMODIFY_BSP_get_next_thing_in_sector:
mov   si, 01000h
ENSUREALIGN_092:  ; todo align..
test  si, si
jne   loop_things_in_thinglist

exit_add_sprites:
exit_add_sprites_quick:



jmp   R_AddLine_


ALIGN_MACRO

exit_r_addline:

pop   bp
add   sp, 0Eh  ; for the line/count pushed earlier
; todo investigate NOPPing this
mov   al, 0B3h  ; mov bl, imm8 (fallthru)
mov   byte ptr cs:[SELFMODIFY_skip_frontsector_based_selfmodify], al
mov   byte ptr cs:[SELFMODIFY_skip_frontsector_based_selfmodify_TWOSIDED], al
ret   
ALIGN_MACRO

END_R_ADDLINE_AND_SELFMODIFY_LABEL:  
; this is called if we know a call was made to R_StoreWallRange, 
; so we must cachebust it (replace jump with fallthru to refresh
;  selfmodify cache with new line values next R_StoreWallRange)


mov   al, 0BBh ; mov bx, imm16 (fallthru)
mov   byte ptr cs:[SELFMODIFY_skip_curseg_based_selfmodify], al
mov   byte ptr cs:[SELFMODIFY_skip_curseg_based_selfmodify_topbot], al


END_R_ADDLINE_LABEL:

ENSUREALIGN_019:

inc   word ptr [bp + 4]  ; line
SELFMODIFY_reset_sp:
mov   sp, 01000h
ENSUREALIGN_018:
dec   word ptr [bp + 2]  ; count
jz    exit_r_addline

; fall thru

ENDP


;R_AddLine_

PROC   R_AddLine_ NEAR
PUBLIC R_AddLine_ 

; ax = curlineNum

; bp - 2       lineflags      
; bp - 4       curlineside    
; bp - 6       curseglinedef  
; bp - 8       curlinesidedef 
; bp - 0Ah     curseg_render  
; bp - 0Ch     lazily calculated 128 - siderowoffset (in R_StoreWallRange_) (nonloop draw height threshhold)
; bp - 0Eh     UNUSED for now
; bp - 010h    _rw_scale hi   
; bp - 012h    _rw_scale lo   



mov   cx, ds
mov   dx, LINEFLAGSLIST_SEGMENT
mov   ds, dx
xor   dx, dx
mov   bx, word ptr [bp + 4]  ; get linenum todo push an already shl 4e d copy and add 16 in iter?
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

sub   sp, 4   ; room for lazily calculate 128 - siderowoffset later.

; todo move way later?
les   si, dword ptr ds:[bx]       ;sr_v1Offset
; preshifted
mov   di, es                      ;sr_v2Offset
mov   ax, VERTEXES_SEGMENT
mov   ds, ax

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
exit_addline:
jmp   END_R_ADDLINE_LABEL ; quick out
ALIGN_MACRO

dont_backface_cull:
; cx:ax is span
; dx:di is angle2
; sx:bi is angle1


xchg  ax, di  ; todo eliminate this juggle? 
mov   es, ax

; store rw_angle1 on stack
push  si ; bp - 010h
push  bx ; bp - 012h

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
cmp   si, word ptr [bp - 010h]
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
je    exit_addline_2
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
mov   si, word ptr ds:[bx + _sides_render + SIDE_RENDER_T.sr_secnum]
mov   word ptr cs:[_backsector], si


les   di, dword ptr cs:[_frontsector]
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
mov   si, word ptr [bp - 8]    ; preshifted 2
shl   si, 1
cmp   word ptr es:[si + SIDE_T.s_midtexture], 0  ; todo investigate branch rate
je    exit_addline_2

clippass:
; we hit pass here.
xchg  ax, bx                   ; grab cached x1
jmp   R_ClipPassWallSegment_
ALIGN_MACRO
exit_addline_2:
jmp   END_R_ADDLINE_LABEL

ALIGN_MACRO
first_greater_than_startfirst:
; same as first_greater_than_startfirst_already_rendered but
; we know we didnt render yet so if 2nd check fails dont selfmodify R_StoreWallRange_
; stuff back due to no calls.
cmp   di, word ptr ds:[si  + CLIPRANGE_T.cliprange_last]
jnle  check_rest_loop
return_didnt_render:
jmp   END_R_ADDLINE_LABEL


ALIGN_MACRO

clip_solid_with_null_backsec:
xchg  ax, bx                   ; dont grab uncached x1 - reverse
mov   word ptr cs:[_backsector], SECNUM_NULL   ; does this ever get properly used or checked? can we just ignore?


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
push      bx
push      cx
push      si
push      di
call R_StoreWallRangeNoBackSector_
pop       di
pop       si
pop       cx
pop       bx
mov   ax, cx                        ;		start->first = first;	
mov   word ptr ds:[si + CLIPRANGE_T.cliprange_first], ax

first_greater_than_startfirst_already_rendered:
;	if (last <= start->last) {

cmp   di, word ptr ds:[si  + CLIPRANGE_T.cliprange_last]
jle   write_back_newend_and_return

check_rest_loop:
;    next = start;
mov   bx, si                        ; si is start, bx is next
;    while (last >= (next+1)->first-1) {
check_between_posts:
mov   dx, word ptr ds:[bx + SIZE CLIPRANGE_T + CLIPRANGE_T.cliprange_first]
dec   dx
cmp   di, dx
jl    do_final_fragment
mov   ax, word ptr ds:[bx + CLIPRANGE_T.cliprange_last]
inc   ax
;		// There is a fragment between two posts.
;		R_StoreWallRange (next->last + 1, (next+1)->first - 1);
push bx
push cx
push si
push di
call R_StoreWallRangeNoBackSector_
pop  di
pop  si
pop  cx
pop  bx
mov   ax, word ptr ds:[bx + SIZE CLIPRANGE_T + CLIPRANGE_T.cliprange_last]
add   bx, SIZE CLIPRANGE_T
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
add   si, SIZE CLIPRANGE_T

cmp   bx, cx
je    done_removing_posts
add   bx, SIZE CLIPRANGE_T
les   ax, dword ptr ds:[bx]
mov   word ptr ds:[si + CLIPRANGE_T.cliprange_first], ax

mov   word ptr ds:[si + CLIPRANGE_T.cliprange_last], es
jmp   check_to_remove_posts
ALIGN_MACRO
last_smaller_than_startfirst:
mov   dx, di
;// Post is entirely visible (above start),  so insert a new clippost.
push  bx
push  cx
push  si
push  di
call  R_StoreWallRangeNoBackSector_
pop   di
pop   si
pop   cx
pop   bx
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
write_back_newend_and_return:          ;todo misnamed? doesnt actually write back new end
jmp   END_R_ADDLINE_AND_SELFMODIFY_LABEL
ALIGN_MACRO



do_final_fragment:
;    // There is a fragment after *next.
mov   ax, word ptr ds:[bx + CLIPRANGE_T.cliprange_last]
mov   dx, di
inc   ax
push  bx
push  cx
push  si
push  di
call  R_StoreWallRangeNoBackSector_
pop   di
pop   si
pop   cx
pop   bx
mov   word ptr ds:[si + CLIPRANGE_T.cliprange_last], di
jmp   crunch
ALIGN_MACRO

done_removing_posts:
    
mov   word ptr ds:[_newend], si   ; newend = start+1;

jmp   END_R_ADDLINE_AND_SELFMODIFY_LABEL


ENDP

;R_ClipPassWallSegment_
ALIGN_MACRO

PROC   R_ClipPassWallSegment_ NEAR
PUBLIC R_ClipPassWallSegment_ 

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
push bx
push cx
push si
push di
call R_StoreWallRangeWithBackSector_
pop  di
pop  si
pop  cx
pop  bx
; possibly dupe the follwing code with an implicit assumption if R_StoreWallRange already ran or not

check_last_already_rendered:

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

push bx
push cx
push si
push di
call R_StoreWallRangeWithBackSector_
pop  di
pop  si
pop  cx
pop  bx

cmp  cx, word ptr ds:[bx + CLIPRANGE_T.cliprange_last]
jg   check_next_fragment
do_clippass_exit:
jmp   END_R_ADDLINE_AND_SELFMODIFY_LABEL
ALIGN_MACRO

check_last:  
; same as check_last_already_rendered 
; but if we detect two fails we know we didnt render anything and dont selfmodify over the R_StoreWallRangeStuff
cmp    cx, word ptr ds:[bx + CLIPRANGE_T.cliprange_last]
jnle  check_next_fragment
do_clippass_nothing_seen:
jmp   END_R_ADDLINE_LABEL
ALIGN_MACRO

post_entirely_visible:
mov  dx, cx
mov  ax, si
sub  sp, 8
call R_StoreWallRangeWithBackSector_
jmp   END_R_ADDLINE_AND_SELFMODIFY_LABEL
ALIGN_MACRO


fragment_after_next:

mov  dx, cx
inc  ax
sub  sp, 8
call R_StoreWallRangeWithBackSector_

jmp   END_R_ADDLINE_AND_SELFMODIFY_LABEL



ENDP



;segment_t __near R_GetColumnSegment (int16_t tex, int16_t col, int8_t segloopcachetype) 
ALIGN_MACRO

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
mov       dx, word ptr cs:[di + _segloopnextlookup]   ; cached_next_lookup.
mov       al, byte ptr ds:[bx - 0Ch]        ; _cachedcollength
mov       byte ptr ds:[bx - 0Ch+1], al
mov       byte ptr ds:[bx - 0Ch], cl
xchg      ax, si                    ; was word ptr bp - 4/tex
mov       word ptr ds:[bx - 010h], ax
call      R_GetCompositeTexture_

mov       word ptr ds:[bx], ax   ; write back cachedsegmenttex and store in ax

mov       word ptr cs:[di + _segloopnextlookup], dx
mov       word ptr ds:[di + _segloopcachedsegment], ax  ; write this here now while duped.. skip the write later
shr       di, 1
pop       dx ;  , byte ptr [bp - 0Ah]             ; loopwidth
mov       byte ptr cs:[di + _seglooptexrepeat], dl

jmp       done_setting_cached_tex_skip_cachedsegwrite
ALIGN_MACRO

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
mov       byte ptr cs:[di + _seglooptexrepeat], 0    ; todo any known 0? maybe ah from subtractor
sal       di, 1
mov       word ptr ds:[di + _segloopcachedbasecol], bx

;		// prev RLE boundary. Hit this function again to load next texture if we hit this.
;		segloopprevlookup[segloopcachetype]     = runningbasetotal - subtractor;
;		// next RLE boundary. see above
;		segloopnextlookup[segloopcachetype]     = runningbasetotal; 
;		// this is not a single repeating texture 
;		seglooptexrepeat[segloopcachetype] 		= 0;

mov       word ptr cs:[di + _segloopnextlookup], dx
sub       dx, ax  ; subtractor
mov       word ptr cs:[di + _segloopprevlookup], dx


;	if (lump > 0){
jmp       done_with_loopwidth
ALIGN_MACRO
do_cache_tex_miss:
; bx is _cachedsegmenttex (6E8)
; _cachedtex is 6D8 (bp - 00h)
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
ALIGN_MACRO
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
ALIGN_MACRO
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
ALIGN_MACRO
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
mov       byte ptr cs:[di + _segloopheightvalcache], cl ; write now

xchg      ax, dx
mov       al, byte ptr ds:[bx - 0Ch] ; _cachedcollenght
mul       byte ptr [bp - 8]
add       ax, dx
LEAVE_MACRO     
pop       di
pop       si

ret  

ALIGN_MACRO
PROC   R_GetColumnSegment_ NEAR   ; TODO: optimization candidate
PUBLIC R_GetColumnSegment_

; bp - 2      segloopcachetype
; bp - 4      ax/tex
; bp - 6      basecol
; bp - 8      texcol
; bp - 0Ah    loopwidth


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
mov       byte ptr cs:[di + _seglooptexrepeat], al      ; al still loopwidth
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
ENSUREALIGN_081:
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

mov       byte ptr cs:[bx + _segloopheightvalcache], dl
sal       bx, 1
mov       ax, word ptr ds:[_cachedsegmentlumps]
mov       word ptr ds:[bx + _segloopcachedsegment], ax

xchg      ax, cx
mul       dl
add       ax, cx
LEAVE_MACRO     
pop       di
pop       si

ret    


ALIGN_MACRO
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
ENSUREALIGN_082: ; todo fix
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
ALIGN_MACRO


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
mov       bx, word ptr cs:[di + _segloopnextlookup]
mov       dx, 0FFh
; ax is lump
call      R_GetPatchTexture_

mov       word ptr ds:[_cachedsegmentlumps], ax
mov       word ptr cs:[di + _segloopnextlookup], bx
sar       di, 1
mov       al, byte ptr [bp - 0Ah]
mov       word ptr ds:[_cachedlumps], si
mov       byte ptr cs:[di + _seglooptexrepeat], al
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
ALIGN_MACRO

PROC R_DrawPSprite_ NEAR


; bp - 2      frame (arg)
; bp - 4      tx    fracbits
; bp - 6      tx    intbits
; bp - 8      psp
; bp - 0Ah    flip
; bp - 0Ch    spriteindex
; bp - 0Eh    temp  intbits
; bp - 00h   usedwidth

push  bp
mov   bp, sp
push  cx   ; bp - 2

xor   ah, ah
mov   di, ax
sal   ax, 1
add   di, ax  ; shifted 3

push  word ptr ds:[bx + PSPDEF_T.pspdef_sx + 0]         ; bp - 4  tx fracbits
push  word ptr ds:[bx + PSPDEF_T.pspdef_sx + 2]         ; bp - 6  tx intbits
push  bx                        ; bp - 8


mov   ax, SPRITES_SEGMENT
mov   es, ax

and   cx, FF_FRAMEMASK

; spriteframe_t is 25 bytes in size. get offset...




IF COMPISA GE COMPILE_186
   imul  bx, cx, (SIZE SPRITEFRAME_T)  ; todo lookup table? how big can cx be?
   mov   di, word ptr es:[di]       ; get spriteframesOffset from spritedef_t
   push  word ptr es:[bx + di + SPRITEFRAME_T.spriteframe_flip]    ; 0Ah
   mov   bx, word ptr es:[di + bx]       ; get spriteindex

ELSE
   mov   al, (SIZE SPRITEFRAME_T)
   mul   cl
   mov   di, word ptr es:[di]       ; get spriteframesOffset from spritedef_t
   add   di, ax
   push  word ptr es:[di + SPRITEFRAME_T.spriteframe_flip]    ; 0Ah
   mov   bx, word ptr es:[di]       ; get spriteindex
ENDIF



;	spriteframes = (spriteframe_t __far*)&(spritedefs_bytes[sprites[sprite].spriteframesOffset]);

push  bx                         ; 0Ch
sub   sp, 4                      ; 0Eh, 010h

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
ALIGN_MACRO
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
mov   word ptr [bp - 00h], ax
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
ALIGN_MACRO

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
les   ax, dword ptr ds:[bx + PSPDEF_T.pspdef_sy]  ; label
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
ALIGN_MACRO

x2_smaller_than_viewwidth_2:
dec   ax
vis_x2_set:
mov   word ptr ds:[si + VISSPRITE_T.vs_x2], ax

; dont set psprite vs_scale. Its essentially a viewsize constant and is done in masked code.
xor   ax, ax
SELFMODIFY_BSP_pspriteiscale_lo_1:
mov   bx, 01000h
SELFMODIFY_BSP_pspriteiscale_hi_1:
mov   cx, 01000h

cmp   byte ptr [bp - 0Ah], al  ; al = 0     ; check flip
jne   flip_on

flip_off:

mov   word ptr ds:[si + VISSPRITE_T.vs_startfrac + 0], ax

done_with_flip:
mov   word ptr ds:[si + VISSPRITE_T.vs_startfrac + 2], ax

vis_startfrac_set:
mov   word ptr ds:[si + VISSPRITE_T.vs_xiscale + 0], bx
mov   word ptr ds:[si + VISSPRITE_T.vs_xiscale + 2], cx

mov   ax, word ptr ds:[si + VISSPRITE_T.vs_x1]
les   dx, dword ptr [bp - 0Eh]  ; es gets bp - 0Ch
mov   word ptr ds:[si + VISSPRITE_T.vs_patch], es ; [bp - 0Ch] 

sub   ax, dx
jle   vis_x1_greater_than_x1_2

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


;    if (player.powers[pw_invisibility] > 4*32

cmp   word ptr ds:[_player + PLAYER_T.player_powers + 2 * PW_INVISIBILITY], (4*32)
jg    mark_shadow_draw
test  byte ptr ds:[_player + PLAYER_T.player_powers + 2 * PW_INVISIBILITY], 8
jne   mark_shadow_draw

SELFMODIFY_BSP_fixedcolormap_4:
jmp   use_fixedcolormap
SELFMODIFY_BSP_fixedcolormap_4_AFTER:
;ALIGN_MACRO
test  byte ptr [bp - 2], FF_FULLBRIGHT
jne    use_fixedcolormap

set_vis_colormap:
SELFMODIFY_set_spritelights_2:
mov   al, byte ptr ds:[01000h]    
mov   byte ptr ds:[si + VISSPRITE_T.vs_colormap], al ; maybe
LEAVE_MACRO
ret   


ALIGN_MACRO

flip_on:

neg   cx
neg   bx
sbb   cx, ax  ; 0 

;      vis->xiscale = -pspriteiscale;
;      temp.h.intbits = usedwidth;
;		vis->startfrac = temp.w - 1;

dec   ax
mov   word ptr ds:[si + VISSPRITE_T.vs_startfrac + 0], ax ; -1

; mov ax, 0; add ax, -1; adc di, -1 optimized 

add   ax, word ptr [bp - 00h]  ; add - 1 to the value.

jmp   done_with_flip




ALIGN_MACRO
mark_shadow_draw:
; do shadow draw
mov   byte ptr ds:[si + VISSPRITE_T.vs_colormap], COLORMAP_SHADOW
LEAVE_MACRO
ret   


ALIGN_MACRO
SELFMODIFY_BSP_fixedcolormap_4_TARGET:
use_fixedcolormap:
SELFMODIFY_BSP_fixedcolormap_5:
mov   byte ptr ds:[si + VISSPRITE_T.vs_colormap], 00h

LEAVE_MACRO
ret   



ENDP

;R_PrepareMaskedPSprites_

ALIGN_MACRO
PROC R_PrepareMaskedPSprites_ NEAR


SELFMODIFY_BSP_set_playermobjsecnum:
mov   bx, 01000h
SHIFT_MACRO shl bx 4
mov   ax, SECTORS_SEGMENT
mov   es, ax


mov   al, byte ptr es:[bx + SECTOR_T.sec_lightlevel]  ; sector lightlevel byte offset

SHIFT_MACRO shr al 4
cbw

SELFMODIFY_BSP_extralight3:
add       al, 0

shl       ax, 1
xchg      ax, bx
mov       ax, word ptr cs:[_mul48lookup_with_scalelight + bx]
add       ax, MAXLIGHTSCALE-1 ; revisit this logic...? was there before

player_spritelights_set:
mov   word ptr cs:[SELFMODIFY_set_spritelights_2 + 1], ax 



first_iter:

mov   bx, word ptr ds:[_psprites  + PSPDEF_T.pspdef_statenum]
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

mov   bx, word ptr ds:[_psprites + (SIZE PSPDEF_T) + PSPDEF_T.pspdef_statenum]
cmp   bx, -1
je    sprite_2_null
sal   bx, 1
mov   si, OFFSET _player_vissprites + SIZE VISSPRITE_T
mov   ax, word ptr ds:[bx + _states_render]
mov   cl, ah
mov   bx, OFFSET _psprites + SIZE PSPDEF_T
call  R_DrawPSprite_
sprite_2_null:


ret  



ENDP




;R_CheckBBox_


ALIGN_MACRO
boxy_check_2nd_expression:
; ax still viewy highbits
SELFMODIFY_BSP_viewy_lo_4_TARGET_2:
je    set_boxy_1
SELFMODIFY_BSP_viewy_lo_4_TARGET_1:
set_boxy_2:
mov   al, 2
jmp   boxy_calculated
ALIGN_MACRO

return_1_early:
stc
ret   

ALIGN_MACRO
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
jmp   word ptr cs:[di + R_CHECKBBOX_SWITCH_JMP_TABLE]
ALIGN_MACRO
SELFMODIFY_BSP_viewx_lo_4_TARGET_2:
; jmp here if viewx lobits are 0.
viewx_greater_than_left:
jne   boxx_check_2nd_expression
jmp   set_boxx_0
ALIGN_MACRO
; jmp here if viewx lobits are nonzero.
SELFMODIFY_BSP_viewx_lo_4_TARGET_1:
boxx_check_2nd_expression:
; ax is already viewx hi
cmp   ax, word ptr ds:[bx + 6]         ; bspcoord[BOXRIGHT]
jge   set_boxx_2
set_boxx_1:
mov   dl, 1
jmp   check_boxy
ALIGN_MACRO
set_boxx_2:
mov   dl, 2
jmp   check_boxy
ALIGN_MACRO
viewy_less_than_top:
cmp   ax, word ptr ds:[bx + 2]         ; bspcoord[BOXBOTTOM]
SELFMODIFY_BSP_viewy_lo_4:
jle   boxy_check_2nd_expression
SELFMODIFY_BSP_viewy_lo_4_AFTER:
set_boxy_1:
mov   al, 1
jmp   boxy_calculated

ALIGN_MACRO
R_CBB_SWITCH_CASE_01:
; di cx si dx
mov   di, word ptr ds:[bx]
mov   cx, di
les   si, dword ptr ds:[bx+4]
mov   dx, es
jmp   boxpos_switchblock_done
ALIGN_MACRO
R_CBB_SWITCH_CASE_02:
; di cx si dx
les   di, dword ptr ds:[bx]
mov   cx, es
les   si, dword ptr ds:[bx+4]
mov   dx, es
jmp   boxpos_switchblock_done
ALIGN_MACRO
R_CBB_SWITCH_CASE_03:
R_CBB_SWITCH_CASE_07:
; dicxsidx
mov   di, word ptr ds:[bx]
mov   cx, di
mov   si, di
mov   dx, di
jmp   boxpos_switchblock_done
ALIGN_MACRO
R_CBB_SWITCH_CASE_04:
; sidx cx di
mov   si, word ptr ds:[bx + 4]
mov   dx, si
les   cx, dword ptr ds:[bx]
mov   di, es
jmp   boxpos_switchblock_done
ALIGN_MACRO
R_CBB_SWITCH_CASE_06:
; sidx di cx
mov   si, word ptr ds:[bx+6]
mov   dx, si
les   di, dword ptr ds:[bx]
mov   cx, es
jmp   boxpos_switchblock_done
ALIGN_MACRO
R_CBB_SWITCH_CASE_08:
; cx di dx si
les   cx, dword ptr ds:[bx]
mov   di, es
les   dx, dword ptr ds:[bx+4]
mov   si, es
jmp   boxpos_switchblock_done
ALIGN_MACRO
R_CBB_SWITCH_CASE_09:
; dicx dx si
mov   di, word ptr ds:[bx+2]
mov   cx, di
les   dx, dword ptr ds:[bx+4]
mov   si, es
jmp   boxpos_switchblock_done
ALIGN_MACRO
R_CBB_SWITCH_CASE_10:
; di cx dx si
les   di, dword ptr ds:[bx]
mov   cx, es
les   dx, dword ptr ds:[bx+4]
mov   si, es
jmp   boxpos_switchblock_done
ALIGN_MACRO

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

ALIGN_MACRO
return_1:
stc
ret   

ALIGN_MACRO
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

ALIGN_MACRO
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
ALIGN_MACRO

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
ALIGN_MACRO
 @

 cmp   si, dx
 clc                        
 jg    calculate_next_bspnum ; carry flag = !sign, sign on
 stc
 jne   calculate_next_bspnum ; carry flag = !sign, sign off
; equals fall thru, check low bits
 cmp   cx, ax                ; sets carry flag as same as unsigned compare
 jmp   calculate_next_bspnum
ALIGN_MACRO
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
 ENSUREALIGN_016:
 jmp   bsp_loop_start
ALIGN_MACRO
exit_renderbspnode:
 POPA_NO_AX_MACRO
 ret
ENDP






; todo pass in si to be _textureL1LRU ptr. put that in < 0x80

ALIGN_MACRO
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
;cmp  al, ah
;je   exit_markl1texturecachemru
;xchg byte ptr ds:[_textureL1LRU+8], ah
;cmp  al, ah
;je   exit_markl1texturecachemru
;xchg byte ptr ds:[_textureL1LRU+9], ah

exit_markl1texturecachemru:
ret  

ENDP




; assumes ah 0
ALIGN_MACRO
PROC R_MarkL2TextureCacheMRU_ NEAR


cmp  al, byte ptr ds:[_texturecache_l2_head]
jne  dont_early_out_texture
ret

ALIGN_MACRO
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
ALIGN_MACRO

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
ALIGN_MACRO

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
ALIGN_MACRO

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

ALIGN_MACRO
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
ALIGN_MACRO

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




ALIGN_MACRO
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
ALIGN_MACRO
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
ALIGN_MACRO


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
ALIGN_MACRO

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
test      bx, bx
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
ALIGN_MACRO
erase_this_page:
mov       byte ptr ds:[si-1], dl     ; 0FFh
mov       byte ptr ds:[si+bx], dl    ; 0FFh
jmp       done_erasing_page
ALIGN_MACRO

ALIGN_MACRO
erase_second_page:
mov       byte ptr ds:[si-1], dl      ; 0FFh
mov       byte ptr ds:[si+bx], dl     ; 0FFh
jmp       done_erasing_second_page
ALIGN_MACRO



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
ALIGN_MACRO
set_non_patch_pages:

set_tex_pages:
mov       bx, COMPOSITETEXTUREOFFSET_SEGMENT
mov       es, bx
mov       byte ptr es:[si], dh
mov       byte ptr es:[si + COMPOSITETEXTUREOFFSET_OFFSET], al
LEAVE_MACRO     
POPA_NO_AX_MACRO
ret       


ALIGN_MACRO
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
ALIGN_MACRO
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
ALIGN_MACRO



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



ALIGN_MACRO
PROC R_GetTexturePage_ NEAR
PUBLIC R_GetTexturePage_

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


;push word ptr ds:[bx+6]     ; grab [7] and [8]
;pop  word ptr ds:[bx+7]     ; put in [8] and [9]

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
ALIGN_MACRO

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

ALIGN_MACRO
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
ALIGN_MACRO

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

mov   di, cs
mov   es, di


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


ALIGN_MACRO
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
ALIGN_MACRO


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
ALIGN_MACRO


ENDP

PATCH_TEXTURE_SEGMENT = 05000h
COMPOSITE_TEXTURE_SEGMENT = 05000h


PROC R_GetPatchTexture_Far24_ FAR
PUBLIC R_GetPatchTexture_Far24_

call R_GetPatchTexture_
retf
ENDP

ALIGN_MACRO
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
add   ax, word ptr cs:[si + _pagesegments]
add   ah, (PATCH_TEXTURE_SEGMENT SHR 8)
pop   si
ret   

ALIGN_MACRO
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
mov   si, word ptr cs:[si + _pagesegments]
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

ALIGN_MACRO
set_masked_true:
mov   ax, 1
push  ax
xor   dh, dh
mov   bx, dx
SHIFT_MACRO shl   bx 3
mov   dx, word ptr ds:[bx + _masked_headers + 4] ; texturesize field is + 4
jmp   done_doing_lookup
ALIGN_MACRO



ENDP

PROC R_GetCompositeTexture_Far24_ FAR
PUBLIC R_GetCompositeTexture_Far24_ 

call R_GetCompositeTexture_
retf
ENDP

ALIGN_MACRO
PROC R_GetCompositeTexture_ NEAR

; segment_t R_GetCompositeTexture(int16_t tex_index) ;

; todo clean up reg use, should be much fewer push/pop

push  dx
push  si


mov   si, COMPOSITETEXTUREPAGE_SEGMENT
mov   es, si
xchg  ax, si  
mov   al, byte ptr es:[si] ; consider lodsb 
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

add   ax, word ptr cs:[si + _pagesegments]
add   ah, (COMPOSITE_TEXTURE_SEGMENT SHR 8)

pop   si
pop   dx
ret 

ALIGN_MACRO
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
mov   bx, word ptr cs:[bx + _pagesegments]

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






ALIGN_MACRO
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
; todo make this not happen?
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
mov       word ptr cs:[SELFMODIFY_add_patchoriginy + 1], ax



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
ALIGN_MACRO
done_with_composite_loop:
;call      Z_QuickMapRender7000_
Z_QUICKMAPAI4 (pageswapargs_rend_offset_size+12) INDEXED_PAGE_7000_OFFSET


LEAVE_MACRO     
POPA_NO_AX_MACRO
ret       
ALIGN_MACRO
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
mov       word ptr cs:[SELFMODIFY_x2_check+2], bx

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
ALIGN_MACRO
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
ENSUREALIGN_078:

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
ENSUREALIGN_080:

;		uint16_t     count = patchcol->length;

mov       ax, word ptr ds:[bx]  ; al topdelta

xor       cx, cx
xchg      cl, ah                ; length to cl, 0 to ah

; cx is count
; ax is topdelta for now

;		int16_t     position = patchoriginy + patchcol->topdelta;

SELFMODIFY_add_patchoriginy:
add       ax, 01000h ; patchoriginy + topdelta
ENSUREALIGN_079:  ; hard
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
ALIGN_MACRO

do_next_composite_loop_iter:
mov       ax, ss
mov       ds, ax  ; restore ds
add       word ptr [bp - 012h], 4
inc       word ptr [bp - 6]
mov       ax, word ptr [bp - 016h]
add       sp, 8 ; back to 46?
jmp       loop_texture_patch
ALIGN_MACRO

position_under_zero:
add       cx, di
xor       di, di
jmp       done_with_position_check
ALIGN_MACRO

ENDP




SCRATCH_ADDRESS_4000_SEGMENT = 04000h
SCRATCH_ADDRESS_5000_SEGMENT = 05000h

ALIGN_MACRO
do_masked_jump:
mov       ax, 0c089h   ; 2 byte nop
mov       di, ((SELFMODIFY_loadpatchcolumn_masked_check2_TARGET - SELFMODIFY_loadpatchcolumn_masked_check2_AFTER) SHL 8) + 0EBh
jmp       ready_selfmodify_loadpatch
ALIGN_MACRO

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

mov       word ptr cs:[SELFMODIFY_loadpatchcolumn_masked_check1], ax;
mov       word ptr cs:[SELFMODIFY_loadpatchcolumn_masked_check2], di;

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



; di is destoffset
; ds:[bx] is patch data (in scratch segment)
; ds:[si] is column data

; es is dest segment
mov       bx, 8
mov       dx, 0FFF0h

do_next_column:
ENSUREALIGN_321:

mov       si, word ptr ds:[bx]
lodsb     ; get topdelta
cmp       al, dh
je        done_with_column

do_next_post_in_column:
ENSUREALIGN_322: ;odd..

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
;ALIGN_MACRO
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
;ALIGN_MACRO
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
ALIGN_MACRO
PROC Z_QuickMapRenderTexture_BSPLocal_ NEAR ; todo


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

ALIGN_MACRO
PROC R_RenderPlayerView24_ FAR ; probably not optimized, runs rarely
PUBLIC R_RenderPlayerView24_ 



PUSHA_NO_AX_OR_BP_MACRO

;	r_cachedplayerMobjsecnum = playerMobj->secnum;
mov       bx, word ptr ds:[_playerMobj]
push      word ptr ds:[bx + MOBJ_T.m_secnum]  ; playerMobj->secnum
pop       word ptr cs:[SELFMODIFY_BSP_set_playermobjsecnum + 1]


;call      Z_QuickMapRender_
Z_QUICKMAPAI24 pageswapargs_rend_offset_size INDEXED_PAGE_4000_OFFSET

; call      R_SetupFrame_
; INLINED setupframe


; todo only do once per level.
mov      ax, word ptr ds:[_playerMobj_pos]
mov      word ptr cs:[SELFMODIFY_set_playermobjpos+2], ax

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






;    validcount_global++;
inc       word ptr ds:[_validcount_global]
mov       ax, word ptr ds:[_validcount_global]
mov       word ptr cs:[SELFMODIFY_BSP_validcountglobal+1], ax

;	destview = (byte __far*)(destscreen.w + viewwindowoffset);
les       ax, dword ptr ds:[_destscreen]
add       ax, word ptr ds:[_viewwindowoffset]
mov       word ptr ds:[_destview], ax
mov       word ptr ds:[_destview + 2], es



call      R_WriteBackFrameConstants_
;call      R_ClearClipSegs_

; inlined

mov  word ptr ds:[_solidsegs+0], 08001h
mov  word ptr ds:[_solidsegs+2], 0FFFFh
; push pop?
mov  ax, word ptr ds:[_viewwidth]
mov  word ptr ds:[_solidsegs+4], ax
mov  word ptr ds:[_solidsegs+6], 07FFFh
mov  word ptr ds:[_newend], OFFSET _solidsegs + 2 * (SIZE CLIPRANGE_T)


mov       word ptr cs:[_ds_p_bsp],     (SIZE DRAWSEG_T)             ; drawsegs_PLUSONE
call      R_ClearPlanes_
mov       word ptr ds:[_vissprite_p], OFFSET _vissprites


call      dword ptr ds:[_NetUpdate_addr]

mov       dx, SC_DATA
mov       al, 15
out       dx, al  ; for the potato case, which will skip OUTs later

mov       ax, word ptr ds:[_numnodes]
dec       ax

call      R_RenderBSPNode_
call      dword ptr ds:[_NetUpdate_addr]
call      R_PrepareMaskedPSprites_  ; todo inline

;call      Z_QuickMapRenderPlanes_
Z_QUICKMAPAI3       pageswapargs_renderplane_offset_size INDEXED_PAGE_5000_OFFSET
Z_QUICKMAPAI3_NO_DX (pageswapargs_renderplane_offset_size+3) INDEXED_PAGE_8800_OFFSET
Z_QUICKMAPAI1_NO_DX (pageswapargs_renderplane_offset_size+6) INDEXED_PAGE_9C00_OFFSET
Z_QUICKMAPAI4_NO_DX (pageswapargs_renderplane_offset_size+7) INDEXED_PAGE_7000_OFFSET

;    FAR_memset (cachedheight, 0, sizeof(fixed_t) * SCREENHEIGHT);

mov       ax, word ptr cs:[_ds_p_bsp]
mov       word ptr ss:[_ds_p], ax
;mov       word ptr ss:[_ds_p + 2], DRAWSEGS_BASE_SEGMENT        ; nseed to be written because masked subs 02000h from it due to remapping...


mov       ax, CACHEDHEIGHT_SEGMENT
mov       es, ax
xor       ax, ax
mov       di, ax  ; 0
mov       cx, 400

rep stosw 

cmp       byte ptr cs:[_visplanedirty], al   ; 0
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

ALIGN_MACRO
visplane_dirty_do_revert:
call      Z_QuickMapVisplaneRevert_BSPLocal_
jmp       done_with_visplane_revert
ALIGN_MACRO



ENDP



_lookup_bytes:
; quality 0
mov  cx, di
and  cl, 3
mov  ax, 1 ; zero ah
shl  al, cl


; quality 1

mov  ax, di
and  al,  1   ; 1 or 0
dec  ax      ; C or F3
xor  al, 12  ;  or FF
and  ax, 15  ; 3 or 15 ; zero ah

; quality 2
xor ax, ax  ; zero ah
;jmp (done_setting_vga_plane)
db 0ebh, (OFFSET done_setting_vga_plane - OFFSET SELFMODIFY_rewrite_bsp_out_dx_code_mid) - 4

; 10 bytes of garbage is fine.

; TODO: externalize this and R_ExecuteSetViewSize and its children to asm, load from binary
; todo: calculate the values here and dont store to variables.

;R_WriteBackViewConstants24_

PROC R_WriteBackViewConstants24_ FAR ; probably not optimized, runs rarely
PUBLIC R_WriteBackViewConstants24_ 


; set ds to cs to make code smaller?
mov      ax, word ptr ds:[_BSP_CODE_SEGMENT_PTR]
mov      cx, cs
mov      ds, cx
mov      es, cx


ASSUME DS:R_BSP_24_TEXT

mov      word ptr ds:[COLFUNC_shiftmul_selfmodify_target_lookup_mid+2], ax
mov      word ptr ds:[COLFUNC_shiftmul_selfmodify_target_lookup_top+2], ax
mov      word ptr ds:[COLFUNC_shiftmul_selfmodify_target_lookup_bot+2], ax


mov      ax, word ptr ss:[_detailshift]
; todo based on quality change

LENGTH_OF_OUT_CODE_STRING = 10

mov      dx, ax ; backup
mov      cx, LENGTH_OF_OUT_CODE_STRING
mul      cl
add      ax, OFFSET _lookup_bytes
xchg     ax, si
mov      di, OFFSET SELFMODIFY_rewrite_bsp_out_dx_code_mid
xchg     ax, dx ; restore ax.
rep      movsb
mov      cl, LENGTH_OF_OUT_CODE_STRING
sub      si, cx
mov      di, OFFSET SELFMODIFY_rewrite_bsp_out_dx_code_topbot
rep      movsb


; for 16 bit shifts, modify jump to jump 4 for 0 shifts, 2 for 1 shifts, 0 for 0 shifts.

cmp      al, 1
jb       jump_to_set_to_zero ; 19h bytesish out of range.
je       set_to_one
jmp      set_to_two
ALIGN_MACRO
jump_to_set_to_zero:
jmp      set_to_zero
ALIGN_MACRO
set_to_two:

mov      byte ptr ds:[SELFMODIFY_BSP_detailshift_7+1], 2
mov      ax, 0c089h 


mov      word ptr ds:[SELFMODIFY_BSP_detailshift2minus+0], ax
mov      word ptr ds:[SELFMODIFY_BSP_detailshift2minus+2], ax
mov      word ptr ds:[SELFMODIFY_BSP_detailshift2minus_bot+0], ax
mov      word ptr ds:[SELFMODIFY_BSP_detailshift2minus_bot+2], ax
mov      word ptr ds:[SELFMODIFY_BSP_detailshift2minus_top+0], ax
mov      word ptr ds:[SELFMODIFY_BSP_detailshift2minus_top+2], ax


; for 32 bit shifts, modify jump to jump 8 for 0 shifts, 4 for 1 shifts, 0 for 0 shifts.
; 0EBh, 006h = jmp 6







; inverse. do shifts
; d1 e0 d1 d2  = shl ax, 1; rcl dx, 1
; d1 e0 d1 d7  = shl ax, 1; rcl di, 1
; d1 e2 d1 d0  = shl dx, 1; rcl ax, 1

mov      ax, 0e0d1h 
mov      word ptr ds:[SELFMODIFY_BSP_detailshift2minus_1+0], ax
mov      word ptr ds:[SELFMODIFY_BSP_detailshift2minus_2+0], ax
mov      word ptr ds:[SELFMODIFY_BSP_detailshift2minus_1+2], 0d2d1h
mov      word ptr ds:[SELFMODIFY_BSP_detailshift2minus_2+2], 0d7d1h




jmp      done_modding_shift_detail_code
ALIGN_MACRO
set_to_one:

; detailshift 1 case. usually involves one shift pair.
; in this case - we insert nops (nopish?) code to replace the first shift pair

; for 32 bit shifts, modify jump to jump 8 for 0 shifts, 4 for 1 shifts, 0 for 0 shifts.

; d1 ff  = sar di, 1
mov      byte ptr ds:[SELFMODIFY_BSP_detailshift_7+1], 3

; write to colfunc segment
mov      ax, 0ffd1h ; sar di, 1

mov      word ptr ds:[SELFMODIFY_BSP_detailshift2minus+0], ax
mov      ax, 0fbd1h ; sar bx, 1
mov      word ptr ds:[SELFMODIFY_BSP_detailshift2minus_bot+0], ax
mov      word ptr ds:[SELFMODIFY_BSP_detailshift2minus_top+0], ax

; nop 
mov      ax, 0c089h 
; write to colfunc segment
mov      word ptr ds:[SELFMODIFY_BSP_detailshift2minus+2], ax
mov      word ptr ds:[SELFMODIFY_BSP_detailshift2minus_bot+2], ax
mov      word ptr ds:[SELFMODIFY_BSP_detailshift2minus_top+2], ax



; 81 c3 00 00 = add bx, 0000. Not technically a nop, but probably better than two mov ax, ax?
; 89 c0       = mov ax, ax. two byte nop.

;mov      ax, 0c089h  ; continued from above


mov      word ptr ds:[SELFMODIFY_BSP_detailshift2minus_1+0], ax
mov      word ptr ds:[SELFMODIFY_BSP_detailshift2minus_1+2], ax
mov      word ptr ds:[SELFMODIFY_BSP_detailshift2minus_2+0], ax
mov      word ptr ds:[SELFMODIFY_BSP_detailshift2minus_2+2], ax





jmp      done_modding_shift_detail_code
ALIGN_MACRO
set_to_zero:

; detailshift 0 case. usually involves two shift pairs.
; in this case - we make that first shift a proper shift

; d1 fd  = sar bp, 1
mov      byte ptr ds:[SELFMODIFY_BSP_detailshift_7+1], 4
mov      ax, 0ffd1h ; sar di, 1

mov      word ptr ds:[SELFMODIFY_BSP_detailshift2minus+0], ax
mov      word ptr ds:[SELFMODIFY_BSP_detailshift2minus+2], ax
mov      ax, 0fbd1h ; sar bx, 1

; write to colfunc segment
mov      word ptr ds:[SELFMODIFY_BSP_detailshift2minus_bot+0], ax
mov      word ptr ds:[SELFMODIFY_BSP_detailshift2minus_bot+2], ax
mov      word ptr ds:[SELFMODIFY_BSP_detailshift2minus_top+0], ax
mov      word ptr ds:[SELFMODIFY_BSP_detailshift2minus_top+2], ax


; for 32 bit shifts, modify jump to jump 8 for 0 shifts, 4 for 1 shifts, 0 for 0 shifts.

; d1 e0 d1 d2   =  shl ax, 1; rcl dx, 1.
; d1 e2 d1 d0   = shl dx, 1; rcl ax, 1

; 0EBh, 006h = jmp 6
mov      ax, 006EBh
mov      word ptr ds:[SELFMODIFY_BSP_detailshift2minus_1+0], ax
mov      word ptr ds:[SELFMODIFY_BSP_detailshift2minus_2+0], ax


; fall thru
done_modding_shift_detail_code:







mov      ax, word ptr ss:[_detailshiftandval]



not      ax




; ah is definitely 0... optimizable?
mov      ax, word ptr ss:[_centerx]
mov      word ptr ds:[SELFMODIFY_BSP_centerx_1+1], ax
mov      word ptr ds:[SELFMODIFY_BSP_centerx_2+1], ax

mov      word ptr ds:[SELFMODIFY_BSP_centerx_4+1], ax
mov      word ptr ds:[SELFMODIFY_BSP_centerx_5+1], ax
mov      word ptr ds:[SELFMODIFY_BSP_centerx_6+2], ax
mov      word ptr ds:[SELFMODIFY_BSP_centerx_7+1], ax
mov      word ptr ds:[SELFMODIFY_BSP_centerx_8+1], ax



;mov      ax, COLFUNC_FILE_START_SEGMENT
;mov      es, ax

; ah is definitely 0... optimizable?
mov      ax, word ptr ss:[_centery]
inc      ax ; has to do with yl/yh inc by 1 logic
 
mov      word ptr ds:[SELFMODIFY_sub__centeryfrac_4_hi_4+1], ax
mov      word ptr ds:[SELFMODIFY_sub__centeryfrac_4_hi_2+1], ax
mov      word ptr ds:[SELFMODIFY_sub__centeryfrac_4_hi_3+1], ax
mov      word ptr ds:[SELFMODIFY_sub__centeryfrac_4_hi_1+1], ax
mov      word ptr ds:[SELFMODIFY_sub__centeryfrac_4_hi_3_TWOSIDED+1], ax
mov      word ptr ds:[SELFMODIFY_sub__centeryfrac_4_hi_4_TWOSIDED+1], ax

IF COMPISA GE COMPILE_386
ELSE
   mov      word ptr ds:[SELFMODIFY_sub__centeryfrac_4_hi_5+1], ax
   mov      word ptr ds:[SELFMODIFY_sub__centeryfrac_4_hi_5_TWOSIDED+1], ax
ENDIF

neg      ax
mov      byte ptr ds:[SELFMODIFY_COLFUNC_sub_centery24_mid+2], al
mov      byte ptr ds:[SELFMODIFY_COLFUNC_sub_centery24_top+2], al
mov      byte ptr ds:[SELFMODIFY_COLFUNC_sub_centery24_bot+2], al


mov      ax, word ptr ss:[_viewwidth]
mov      word ptr ds:[SELFMODIFY_BSP_viewwidth_2+1], ax
mov      word ptr ds:[SELFMODIFY_BSP_viewwidth_3+1], ax
mov      word ptr ds:[SELFMODIFY_BSP_viewwidth_4+1], ax
shr      ax, 1
mov      word ptr ds:[SELFMODIFY_BSP_viewwidth_1+1], ax

mov      al, byte ptr ss:[_viewheight]
inc      ax

mov      ah, al
mov      word ptr ds:[SELFMODIFY_BSP_setviewheight_1+1], ax
mov      word ptr ds:[SELFMODIFY_BSP_setviewheight_2+1], ax


mov      ax,  word ptr ss:[_pspritescale]
test     ax, ax  ; zero means specialcase as 1.
je       pspritescale_zero_selfmodifies

mov      word ptr ds:[SELFMODIFY_BSP_pspritescale_1+1], ax
mov      word ptr ds:[SELFMODIFY_BSP_pspritescale_2+1], ax
mov      al, 0BBh  ; mov bx, imm16
mov      byte ptr ds:[SELFMODIFY_BSP_pspritescale_1], al
mov      byte ptr ds:[SELFMODIFY_BSP_pspritescale_2], al
jmp      done_with_pspritescale_zero_selfmodifies
ALIGN_MACRO
pspritescale_zero_selfmodifies:

mov      word ptr ds:[SELFMODIFY_BSP_pspritescale_1], (((SELFMODIFY_BSP_pspritescale_1_TARGET - SELFMODIFY_BSP_pspritescale_1_AFTER)) SHL 8) + 0EBh
mov      word ptr ds:[SELFMODIFY_BSP_pspritescale_2], (((SELFMODIFY_BSP_pspritescale_2_TARGET - SELFMODIFY_BSP_pspritescale_2_AFTER)) SHL 8) + 0EBh

done_with_pspritescale_zero_selfmodifies:

les      ax, dword ptr ss:[_pspriteiscale]

mov      word ptr ds:[SELFMODIFY_BSP_pspriteiscale_lo_1+1], ax
mov      word ptr ds:[SELFMODIFY_BSP_pspriteiscale_hi_1+1], es



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
neg      ax
mov      word ptr ds:[SELFMODIFY_BSP_clipangle_8+1], ax




mov      ax, ss
mov      ds, ax

;ASSUME DS:DGROUP



retf



ENDP



;R_WriteBackFrameConstants_

ALIGN_MACRO
PROC   R_WriteBackFrameConstants_ NEAR ; probably not optimized, runs rarely
PUBLIC R_WriteBackFrameConstants_ 

; todo: calculate the values here and dont store to variables. (combine with setupframe etc)

; set ds to cs to make code smaller?
mov      ax, cs
mov      ds, ax

mov      ax, DRAWFUZZCOL_AREA_SEGMENT
mov      es, ax

ASSUME DS:R_BSP_24_TEXT

mov      al, byte ptr ss:[_skyflatnum]  ; todo do once per level ?
cmp      al, byte ptr ds:[_lastskyflatnum]
je       skip_skyflat_selfmodifies_this_frame
mov      byte ptr ds:[_lastskyflatnum], al
mov      byte ptr ds:[SELFMODIFY_BSP_set_skyflatnum_1+1], al
mov      byte ptr ds:[SELFMODIFY_BSP_set_skyflatnum_2+2], al
mov      byte ptr ds:[SELFMODIFY_BSP_set_skyflatnum_3+2], al
mov      byte ptr ds:[SELFMODIFY_BSP_set_skyflatnum_4+3], al
mov      byte ptr ds:[SELFMODIFY_BSP_set_skyflatnum_4_TWOSIDED+3], al
skip_skyflat_selfmodifies_this_frame:

; VIEWZ LO


les      ax, dword ptr ss:[_player + PLAYER_T.player_viewzvalue+0]
cmp      ax, word ptr ds:[_lastviewz+0]
je       skip_viewz_lo_selfmodifies_this_frame
mov      word ptr ds:[_lastviewz+0], ax

mov      word ptr ds:[SELFMODIFY_BSP_viewz_lo_1+1], ax
mov      word ptr ds:[SELFMODIFY_BSP_viewz_lo_2+2], ax
mov      word ptr ds:[SELFMODIFY_BSP_viewz_lo_3+2], ax
mov      word ptr ds:[SELFMODIFY_BSP_viewz_lo_4+2], ax
mov      word ptr ds:[SELFMODIFY_BSP_viewz_lo_7+1], ax
mov      word ptr ds:[SELFMODIFY_BSP_viewz_lo_8+1], ax
mov      word ptr ds:[SELFMODIFY_BSP_viewz_lo_7_TWOSIDED+1], ax
mov      word ptr ds:[SELFMODIFY_BSP_viewz_lo_8_TWOSIDED+1], ax
skip_viewz_lo_selfmodifies_this_frame:

; VIEWZ HI

mov      dx, es
xchg     ax, dx  ; dx has viewz lo
cmp      ax, word ptr ds:[_lastviewz+2]
je       skip_viewz_hi_selfmodifies_this_frame
mov      word ptr ds:[_lastviewz+2], ax

mov      word ptr ds:[SELFMODIFY_BSP_viewz_hi_1+2], ax
mov      word ptr ds:[SELFMODIFY_BSP_viewz_hi_2+2], ax
mov      word ptr ds:[SELFMODIFY_BSP_viewz_hi_3+2], ax
mov      word ptr ds:[SELFMODIFY_BSP_viewz_hi_4+1], ax
mov      word ptr ds:[SELFMODIFY_BSP_viewz_hi_7+2], ax
mov      word ptr ds:[SELFMODIFY_BSP_viewz_hi_8+2], ax
mov      word ptr ds:[SELFMODIFY_BSP_viewz_hi_7_TWOSIDED+2], ax
mov      word ptr ds:[SELFMODIFY_BSP_viewz_hi_8_TWOSIDED+2], ax
; create 13:3 fixed point for comparison in ax

SHIFT32_MACRO_LEFT ax dx 3
mov      word ptr ds:[_lastviewz_shortangle], ax

mov      word ptr ds:[SELFMODIFY_BSP_viewz_13_3_1+2], ax
mov      word ptr ds:[SELFMODIFY_BSP_viewz_13_3_2+2], ax


mov      word ptr ds:[SELFMODIFY_BSP_viewz_shortheight_1+2], ax
mov      word ptr ds:[SELFMODIFY_BSP_viewz_shortheight_2+2], ax
mov      word ptr ds:[SELFMODIFY_BSP_viewz_shortheight_3+3], ax
mov      word ptr ds:[SELFMODIFY_BSP_viewz_shortheight_4+3], ax
mov      word ptr ds:[SELFMODIFY_BSP_viewz_shortheight_5+1], ax
mov      word ptr ds:[SELFMODIFY_BSP_viewz_shortheight_3_TWOSIDED+3], ax
mov      word ptr ds:[SELFMODIFY_BSP_viewz_shortheight_6+2], ax
mov      word ptr ds:[SELFMODIFY_BSP_viewz_shortheight_7+2], ax
mov      word ptr ds:[SELFMODIFY_BSP_viewz_shortheight_4_TWOSIDED+3], ax
skip_viewz_hi_selfmodifies_this_frame:

mov      al, byte ptr ss:[_player + PLAYER_T.player_extralightvalue]
cmp      al, byte ptr ds:[_lastextralight]
je       skip_extralight_selfmodifies_this_frame
mov      byte ptr ds:[_lastextralight], al

mov      byte ptr ds:[SELFMODIFY_BSP_extralight3+1], al
mov      byte ptr ds:[SELFMODIFY_BSP_extralight1+1], al
inc      ax 
mov      byte ptr ds:[SELFMODIFY_BSP_extralight2_plusone+1], al
mov      byte ptr ds:[SELFMODIFY_BSP_extralight2_plusone_TWOSIDED+1], al
skip_extralight_selfmodifies_this_frame:

mov      al, byte ptr ss:[_fixedcolormap]
cmp      al, byte ptr ds:[_lastfixedcolormap]  ; in cs segment
je       skip_fixed_colormap_selfmodify_this_frame
; zero these in either case.
mov      byte ptr ds:[_lastfixedcolormap], al

mov      byte ptr ds:[SELFMODIFY_BSP_fixedcolormap_1+3], al
mov      byte ptr ds:[SELFMODIFY_BSP_fixedcolormap_5+3], al

test     al, al
jne      do_bsp_fixedcolormap_selfmodify
do_no_bsp_fixedcolormap_selfmodify:


mov      ax, 0c089h 
mov      word ptr ds:[SELFMODIFY_BSP_fixedcolormap_2], ax
mov      word ptr ds:[SELFMODIFY_BSP_fixedcolormap_3], ax
mov      word ptr ds:[SELFMODIFY_BSP_fixedcolormap_4], ax
mov      word ptr ds:[SELFMODIFY_BSP_fixedcolormap_3_TWOSIDED], ax


jmp      done_with_bsp_fixedcolormap_selfmodify
ALIGN_MACRO
do_bsp_fixedcolormap_selfmodify:



; zero out the value in the walllights read which wont be updated again.
; It'll get a fixedcolormap value by default. We could alternately get rid of the loop that sets scalelightfixed to fixedcolormap and modify the instructions like above.
mov   word ptr cs:[SELFMODIFY_add_wallights+3], OFFSET _scalelightfixed 
mov   word ptr cs:[SELFMODIFY_add_wallights_TWOSIDED+3], OFFSET _scalelightfixed 

mov   ax, ((SELFMODIFY_BSP_fixedcolormap_2_TARGET - SELFMODIFY_BSP_fixedcolormap_2_AFTER) SHL 8) + 0EBh
mov   word ptr ds:[SELFMODIFY_BSP_fixedcolormap_2], ax
mov   ah, (SELFMODIFY_BSP_fixedcolormap_3_TARGET - SELFMODIFY_BSP_fixedcolormap_3_AFTER)
mov   word ptr ds:[SELFMODIFY_BSP_fixedcolormap_3], ax
mov   ah, (SELFMODIFY_BSP_fixedcolormap_4_TARGET - SELFMODIFY_BSP_fixedcolormap_4_AFTER)
mov   word ptr ds:[SELFMODIFY_BSP_fixedcolormap_4], ax

mov   ah, (SELFMODIFY_BSP_fixedcolormap_3_TARGET_TWOSIDED - SELFMODIFY_BSP_fixedcolormap_3_AFTER_TWOSIDED)
mov   word ptr ds:[SELFMODIFY_BSP_fixedcolormap_3_TWOSIDED], ax


; fall thru
done_with_bsp_fixedcolormap_selfmodify:
skip_fixed_colormap_selfmodify_this_frame:


; VIEWX LO

les      si, dword ptr ss:[_playerMobj_pos]
les      ax, dword ptr es:[si + MOBJ_POS_T.mp_x]
cmp      ax, word ptr ds:[_lastviewx]
je       skip_viewx_lo_selfmodifies_this_frame
mov      word ptr ds:[_lastviewx+0], ax

mov      word ptr ds:[SELFMODIFY_BSP_viewx_lo_1+1], ax
mov      word ptr ds:[SELFMODIFY_BSP_viewx_lo_2+2], ax
mov      word ptr ds:[SELFMODIFY_BSP_viewx_lo_3+1], ax
mov      word ptr ds:[SELFMODIFY_BSP_viewx_lo_2_TWOSIDED+2], ax

neg      ax
mov      word ptr ds:[SELFMODIFY_BSP_viewx_lo_5+1], ax
jnz      selfmodify_viewx_lo_nonzero
mov      ax, ((SELFMODIFY_BSP_viewx_lo_4_TARGET_2 - SELFMODIFY_BSP_viewx_lo_4_AFTER) SHL 8) + 07Dh

jmp      selfmodify_viewx_done
ALIGN_MACRO
selfmodify_viewx_lo_nonzero:
mov      ax, ((SELFMODIFY_BSP_viewx_lo_4_TARGET_1 - SELFMODIFY_BSP_viewx_lo_4_AFTER) SHL 8) + 07Dh
selfmodify_viewx_done:
mov      word ptr ds:[SELFMODIFY_BSP_viewx_lo_4], ax

mov      ax, es
adc      ax, 0  ; carry from previous neg
mov      word ptr ds:[SELFMODIFY_BSP_viewx_hi_5+2], ax


; VIEWX HI

skip_viewx_lo_selfmodifies_this_frame:

mov      ax, es
cmp      ax, word ptr ds:[_lastviewx+2]
je       skip_viewx_hi_selfmodifies_this_frame
mov      word ptr ds:[_lastviewx+2], ax


mov      word ptr ds:[SELFMODIFY_BSP_viewx_hi_1+1], ax
mov      word ptr ds:[SELFMODIFY_BSP_viewx_hi_2+2], ax
mov      word ptr ds:[SELFMODIFY_BSP_viewx_hi_3+2], ax
mov      word ptr ds:[SELFMODIFY_BSP_viewx_hi_4+1], ax

mov      word ptr ds:[SELFMODIFY_BSP_viewx_hi_6+1], ax
mov      word ptr ds:[SELFMODIFY_BSP_viewx_hi_2_TWOSIDED+2], ax

skip_viewx_hi_selfmodifies_this_frame:

; VIEWY LO

les      si, dword ptr ss:[_playerMobj_pos]
les      ax, dword ptr es:[si + MOBJ_POS_T.mp_y]
cmp      ax, word ptr ds:[_lastviewy]
je       skip_viewy_lo_selfmodifies_this_frame
mov      word ptr ds:[_lastviewy+0], ax

mov      word ptr ds:[SELFMODIFY_BSP_viewy_lo_1+1], ax
mov      word ptr ds:[SELFMODIFY_BSP_viewy_lo_2+1], ax
mov      word ptr ds:[SELFMODIFY_BSP_viewy_lo_3+2], ax
mov      word ptr ds:[SELFMODIFY_BSP_viewy_lo_2_TWOSIDED+1], ax

neg      ax
xchg     ax, dx
mov      word ptr ds:[SELFMODIFY_BSP_viewy_lo_5+1], ax
mov      ax, es
adc      ax, 0
mov      word ptr ds:[SELFMODIFY_BSP_viewy_hi_5+2], ax


test     dx, dx
jle      selfmodify_viewy_lo_lessthanequaltozero
mov      ax, ((SELFMODIFY_BSP_viewy_lo_4_TARGET_2 - SELFMODIFY_BSP_viewy_lo_4_AFTER) SHL 8) + 07Eh ;jle

jmp      selfmodify_viewy_done
ALIGN_MACRO
selfmodify_viewy_lo_lessthanequaltozero:
mov      ax, ((SELFMODIFY_BSP_viewy_lo_4_TARGET_1 - SELFMODIFY_BSP_viewy_lo_4_AFTER) SHL 8) + 07Eh ;jle
selfmodify_viewy_done:
mov      word ptr ds:[SELFMODIFY_BSP_viewy_lo_4], ax

; VIEWY HI

skip_viewy_lo_selfmodifies_this_frame:
mov      ax, es
cmp      ax, word ptr ds:[_lastviewy+2]
je       skip_viewy_hi_selfmodifies_this_frame
mov      word ptr ds:[_lastviewy+2], ax

mov      word ptr ds:[SELFMODIFY_BSP_viewy_hi_1+1], ax
mov      word ptr ds:[SELFMODIFY_BSP_viewy_hi_2+2], ax
mov      word ptr ds:[SELFMODIFY_BSP_viewy_hi_3+2], ax
mov      word ptr ds:[SELFMODIFY_BSP_viewy_hi_4+1], ax
mov      word ptr ds:[SELFMODIFY_BSP_viewy_hi_6+1], ax
mov      word ptr ds:[SELFMODIFY_BSP_viewy_hi_2_TWOSIDED+2], ax

skip_viewy_hi_selfmodifies_this_frame:

; VIEWANGLE LO

les      si, dword ptr ss:[_playerMobj_pos]
les      ax, dword ptr es:[si + MOBJ_POS_T.mp_angle]
cmp      ax, word ptr ds:[_lastviewangle+0]
je       skip_viewangle_lo_selfmodifies_this_frame
mov      word ptr ds:[_lastviewangle+0], ax


mov      word ptr ds:[SELFMODIFY_BSP_viewangle_lo_1+2], ax
mov      word ptr ds:[SELFMODIFY_BSP_viewangle_lo_2+2], ax
mov      word ptr ds:[SELFMODIFY_BSP_viewangle_lo_3+1], ax
mov      word ptr ds:[SELFMODIFY_BSP_viewangle_lo_4+1], ax


; VIEWANGLE HI

skip_viewangle_lo_selfmodifies_this_frame:
mov      ax, es  
cmp      ax, word ptr ds:[_lastviewangle+2]
je       skip_viewangle_hi_selfmodifies_this_frame
mov      word ptr ds:[_lastviewangle+2], ax


mov      word ptr ds:[SELFMODIFY_BSP_viewangle_hi_1+2], ax
mov      word ptr ds:[SELFMODIFY_BSP_viewangle_hi_2+2], ax
mov      word ptr ds:[SELFMODIFY_BSP_viewangle_hi_3+2], ax
mov      word ptr ds:[SELFMODIFY_BSP_viewangle_hi_4+2], ax

shr       ax, 1
;	viewangle_shiftright1 = (viewangle.hu.intbits >> 1) & 0xFFFC;
and       al, 0FCh

mov      word ptr ds:[SELFMODIFY_set_viewanglesr1_1+1], ax
mov      word ptr ds:[SELFMODIFY_set_viewanglesr1_2+1], ax
mov      word ptr ds:[SELFMODIFY_set_viewanglesr1_3+1], ax
mov      word ptr ds:[SELFMODIFY_set_viewanglesr1_4+1], ax

mov      ax, es  
SHIFT_MACRO shr ax 3
mov      word ptr ss:[_viewangle_shiftright3], ax


mov      word ptr ds:[SELFMODIFY_set_viewanglesr3_2+1], ax
mov      word ptr ds:[SELFMODIFY_set_viewanglesr3_3+1], ax
mov      word ptr ds:[SELFMODIFY_set_viewanglesr3_4+1], ax
mov      word ptr ds:[SELFMODIFY_set_viewanglesr3_5+2], ax

mov      word ptr ds:[SELFMODIFY_set_viewanglesr3_2_TWOSIDED+1], ax
mov      word ptr ds:[SELFMODIFY_set_viewanglesr3_3_TWOSIDED+1], ax

add      ah, 8
mov      word ptr ds:[SELFMODIFY_set_viewanglesr3_1+1], ax
mov      word ptr ds:[SELFMODIFY_set_viewanglesr3_1_TWOSIDED+1], ax

skip_viewangle_hi_selfmodifies_this_frame:




; get whole dword at the end here.
les      ax, dword ptr ss:[_destview]
mov      word ptr ds:[SELFMODIFY_BSP_add_destview_offset+2], ax
mov      word ptr ds:[SELFMODIFY_BSP_add_destview_offset_bot+2], ax
mov      word ptr ds:[SELFMODIFY_BSP_add_destview_offset_top+2], ax


mov      dx, COLFUNC_FILE_START_SEGMENT
mov      ds, dx
mov      ax, es

mov      word ptr ds:[SELFMODIFY_COLFUNC_SET_DESTVIEW_SEGMENT24_OFFSET+1], ax
mov      word ptr ds:[SELFMODIFY_COLFUNC_SET_DESTVIEW_SEGMENT24_NORMALSTRETCH_OFFSET+1], ax
mov      word ptr ds:[SELFMODIFY_COLFUNC_SET_DESTVIEW_SEGMENT24_NOLOOP_OFFSET+1], ax
mov      word ptr ds:[SELFMODIFY_COLFUNC_SET_DESTVIEW_SEGMENT24_NOLOOPANDSTRETCH_OFFSET+1], ax

mov      ax, ss
mov      ds, ax
;ASSUME DS:DGROUP



ret

ENDP

ALIGN 16
bsp_local_dc_yl_lookup_table_:
PUBLIC bsp_local_dc_yl_lookup_table_


sumof80s = 0
MAX_PIXELS = 200
REPT MAX_PIXELS
    dw sumof80s 
    sumof80s = sumof80s + 80
ENDM

PROC R_BSP24_ENDMARKER_
PUBLIC R_BSP24_ENDMARKER_
ENDP

ENDS

public ENSUREALIGN_001
public ENSUREALIGN_002
public ENSUREALIGN_003
public ENSUREALIGN_004
public ENSUREALIGN_005
public ENSUREALIGN_006
public ENSUREALIGN_007
public ENSUREALIGN_008
public ENSUREALIGN_009
public ENSUREALIGN_010
public ENSUREALIGN_011
public ENSUREALIGN_012
public ENSUREALIGN_013
public ENSUREALIGN_014
public ENSUREALIGN_015
public ENSUREALIGN_016
;public ENSUREALIGN_017
public ENSUREALIGN_018
public ENSUREALIGN_019
public ENSUREALIGN_020
public ENSUREALIGN_021
public ENSUREALIGN_022
public ENSUREALIGN_023
public ENSUREALIGN_024
public ENSUREALIGN_025

; lower priority...


public ENSUREALIGN_060
public ENSUREALIGN_061
public ENSUREALIGN_062
public ENSUREALIGN_063
public ENSUREALIGN_064
public ENSUREALIGN_065
public ENSUREALIGN_069
public ENSUREALIGN_070
public ENSUREALIGN_071
public ENSUREALIGN_072
public ENSUREALIGN_073
public ENSUREALIGN_074
public ENSUREALIGN_075
public ENSUREALIGN_076
public ENSUREALIGN_078
public ENSUREALIGN_079
public ENSUREALIGN_080

public ENSUREALIGN_081
public ENSUREALIGN_082
public ENSUREALIGN_083
public ENSUREALIGN_084
public ENSUREALIGN_085
public ENSUREALIGN_086
public ENSUREALIGN_087
public ENSUREALIGN_088
public ENSUREALIGN_092
public ENSUREALIGN_093
public ENSUREALIGN_094
public ENSUREALIGN_095
public ENSUREALIGN_096
public ENSUREALIGN_097
public ENSUREALIGN_098

; most of these not aligned..

public ENSUREALIGN_300
public ENSUREALIGN_301
public ENSUREALIGN_302
public ENSUREALIGN_303

public ENSUREALIGN_305
public ENSUREALIGN_306
public ENSUREALIGN_308
public ENSUREALIGN_309

public ENSUREALIGN_310
public ENSUREALIGN_311
public ENSUREALIGN_312

public ENSUREALIGN_314
public ENSUREALIGN_315
public ENSUREALIGN_316
public ENSUREALIGN_317

public ENSUREALIGN_319
public ENSUREALIGN_320
public ENSUREALIGN_321
public ENSUREALIGN_322
public ENSUREALIGN_323

IF COMPISA GE COMPILE_386
ELSE
public ENSUREALIGN_051
public ENSUREALIGN_066
public ENSUREALIGN_067
public ENSUREALIGN_068
public ENSUREALIGN_077
public ENSUREALIGN_089
public ENSUREALIGN_090
public ENSUREALIGN_091
public ENSUREALIGN_099
ENDIF



END
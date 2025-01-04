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


EXTRN FixedMulTrig_:PROC
EXTRN div48_32_:PROC

EXTRN Z_QuickMapVisplanePage_:PROC
EXTRN Z_QuickMapVisplaneRevert_:PROC
EXTRN FastMul16u32u_:PROC
EXTRN FixedDivWholeA_:PROC
EXTRN FastDiv3232_shift_3_8_:PROC
EXTRN R_PointToAngle_:PROC
EXTRN R_PointToAngle16_:PROC

EXTRN R_GetColumnSegment_:NEAR

EXTRN _validcount:WORD
EXTRN _spritelights:WORD
EXTRN _spritewidths_segment:WORD


EXTRN _segloopnextlookup:WORD
EXTRN _segloopprevlookup:WORD
EXTRN _seglooptexrepeat:BYTE
;EXTRN _seglooptexmodulo:BYTE
EXTRN _segloopcachedbasecol:WORD
EXTRN _segloopheightvalcache:BYTE
EXTRN _segloopcachedsegment:WORD
EXTRN _solidsegs:WORD
EXTRN _newend:WORD
EXTRN _clipangle:WORD
EXTRN _fieldofview:WORD


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
 
call FixedMulTrig_


;    num.w = FixedMulTrig(FINE_SINE_ARGUMENT, angleb, projection.w)<<detailshift.b.bytelow;
 
;call FixedMulTrig16_
; inlined  16 bit times sine value

mov es, si
sal di, 1
sal di, 1
mov si, word ptr es:[di]
mov di, word ptr es:[di+2]
xchg dx, di
xchg ax, si

;  dx now has anglea
;  ax has finesine_segment
;  di:si is den

SELF_MODIFY_set_centerx_1:
mov   cx, 01000h


AND  DX, CX    ; DX*CX
NEG  DX
MOV  BX, DX    ; store high result

MUL  CX       ; AX*CX
ADD  DX, BX   


; di:si had den
; dx:ax has num

SELFMODIFY_detailshift_2_minus_32_bit_rotate_jump_1:


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


call div48_32_

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

IF COMPILE_INSTRUCTIONSET GE COMPILE_386

PROC FixedMulBSPLocal_ NEAR
PUBLIC FixedMulBSPLocal_

; DX:AX  *  CX:BX
;  0  1      2  3

; cheat since we cant use .386 stuff midfile? todo figure this out...

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

rol dx, 1
rol dx, 1

mov di, dx
and di, 03h


; do comparison  di:bx vs dx:ax
; 	if ((labs(a) >> 14) >= labs(b))

cmp   di, cx
jg    do_quick_return
jne   restore_reg_then_do_full_divide ; below
mov   di, dx      ; recover this
mov   es, ax      ; back this up
rol   ax, 1
rol   ax, 1
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
ror dx, 1
ror dx, 1


do_full_divide:

call div48_32_

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


push  bx
push  cx
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
SELFMODIFY_set_viewx_lo_2:
sub   bx, 01000h
SELFMODIFY_set_viewx_hi_2:
sbb   cx, 01000h

SELFMODIFY_set_viewy_lo_2:
sub   ax, 01000h
SELFMODIFY_set_viewy_hi_2:
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
mov   es, word ptr ds:[_tantoangle] 
mov   bx, word ptr es:[bx + 2] ; get just intbits..

;    dist = FixedDiv (dx, finesine[angle] );	

add   bh, 040h ; ang90 highbits
mov   ax, FINESINE_SEGMENT
shr   bx, 1
and   bl, 0FCh
mov   es, ax
mov   ax, si
mov   cx, word ptr es:[bx + 2]
mov   bx, word ptr es:[bx]
call  FixedDivBSPLocal_

pop   di
pop   si
pop   cx
pop   bx
ret   

endp





;R_ClearPlanes

PROC R_ClearPlanes_ NEAR
PUBLIC R_ClearPlanes_ 


push  bx
push  cx
push  dx
push  di


SELFMODIFY_set_viewwidth_1:
mov   cx, 01000h
mov   dx, cx

xor   di, di
SELFMODIFY_setviewheight_2:
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

 shl   ax, 1
 shl   ax, 1
 
SELF_MODIFY_set_centerx_2:
mov   cx, 01000h
mov   di, ax

mov   ax, FINECOSINE_SEGMENT

mov   es, ax


mov   ax, word ptr es:[di]
mov   dx, word ptr es:[di + 2]
xor   bx, bx

call FixedDivBSPLocal_  ; TODO! FixedDivWholeB? Optimize?
mov   word ptr ds:[_basexscale], ax
mov   word ptr ds:[_basexscale + 2], dx
mov   ax, FINESINE_SEGMENT

mov   es, ax
SELF_MODIFY_set_centerx_3:
mov   cx, 01000h
mov   ax, word ptr es:[di]
mov   dx, word ptr es:[di + 2]
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





;R_HandleEMSPagination

PROC R_HandleEMSPagination_ NEAR
PUBLIC R_HandleEMSPagination_ 

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
push  cx

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


pop   cx
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

pop   cx
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


call  Z_QuickMapVisplanePage_
jmp   return_visplane
use_phys_page_2:
mov   bl, 2
mov   dl, bl


call  Z_QuickMapVisplanePage_
jmp   return_visplane
is_floor:
cmp   byte ptr ds:[_ceilphyspage], 2
je    use_phys_page_1
mov   bl, 2
mov   dl, bl

call  Z_QuickMapVisplanePage_
jmp   return_visplane



ENDP



;R_FindPlane_

PROC R_FindPlane_ NEAR
PUBLIC R_FindPlane_ 



; dx:ax is height
; cx is picandlight
; bl is icceil

push      si
push      di

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
call      R_HandleEMSPagination_
; fetch and return i
mov       ax, bx


pop       di
pop       si
ret       


;		if (height == checkheader->height
;			&& piclight.hu == visplanepiclights[i].pic_and_light) {
;				break;
;		}

check_for_visplane_match:
cmp       di, word ptr [bx]     ; compare height low word
jne       loop_iter_step_variables
cmp       dx, word ptr [bx + 2] ; compare height high word
jne       loop_iter_step_variables
cmp       cx, word ptr [si] ; compare picandlight
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
mov       word ptr [bx], di
mov       word ptr [bx + 2], dx
mov       word ptr [bx + 4], SCREENWIDTH
mov       word ptr [bx + 6], 0FFFFh

;si already has  word lookup for piclights


mov       word ptr ds:[si], cx 

pop       dx  ; get isceil
inc       word ptr ds:[_lastvisplane]

mov       si, ax     ; store i      

call      R_HandleEMSPagination_

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


pop       di
pop       si
ret       

ENDP

;R_AddLine_

PROC R_AddLine_ NEAR
PUBLIC R_AddLine_ 

; ax = curlineNum

; bp - 2       curlineside
; bp - 4       curseglinedef
; bp - 6       UNUSED
; bp - 8       span   lo bits ?
; bp - 0Ah     angle1 lo bits ?
; bp - 0Ch     UNUSED
; bp - 0Eh     UNUSED
; bp - 010h    curlinelinedef ?
; bp - 012h    curlinelinedef ?
; bp - 014h    unused


push  bx
push  cx
push  dx
push  si
push  di
push  bp
mov   bp, sp
sub   sp, 014h
mov   si, ax
mov   dx, SEG_LINEDEFS_SEGMENT
add   si, SEG_SIDES_OFFSET_IN_SEGLINES
mov   es, dx
mov   bx, ax
shl   bx, 1
mov   dl, byte ptr es:[si]
mov   si, bx
shl   bx, 1
shl   bx, 1
add   bh, (_segs_render SHR 8)
mov   byte ptr [bp - 2], dl
mov   dx, word ptr es:[si]
mov   word ptr [bp - 4], dx
mov   si, word ptr [bx + 6]
shl   dx, 1
shl   dx, 1
shl   si, 1
shl   si, 1
shl   si, 1
mov   word ptr [bp - 010h], dx
mov   word ptr [bp - 012h], si
mov   si, word ptr [bx]       ;v1
mov   dx, VERTEXES_SEGMENT
shl   si, 1
shl   si, 1
mov   es, dx
mov   word ptr ds:[_curseg], ax
mov   ax, word ptr es:[si]
mov   dx, word ptr es:[si + 2]
mov   si, word ptr [bx + 2]
shl   si, 1
shl   si, 1
mov   di, word ptr es:[si]       ; v2.x
mov   cx, word ptr es:[si + 2]   ; v2.y
mov   word ptr ds:[_curseg_render], bx
call  R_PointToAngle16_
mov   bx, ax
mov   si, dx      ; SI: BX stores angle1
mov   ax, di      ; move v2 into dx:ax
mov   dx, cx      ; move v2 into dx:ax
call  R_PointToAngle16_
mov   di, ax
mov   ax, bx
sub   ax, di
mov   cx, si
sbb   cx, dx
mov   word ptr [bp - 8], ax
cmp   cx, ANG180_HIGHBITS
jb    label_1
jmp   exit_addline
label_1:
; todo selfmodify _rw_angle1 forward
mov   word ptr ds:[_rw_angle1], bx
mov   word ptr ds:[_rw_angle1 + 2], si
SELFMODIFY_BSP_viewangle_lo_1:
sub   bx, 01000h
mov   word ptr [bp - 0Ah], bx
mov   bx, si
SELFMODIFY_BSP_viewangle_hi_1:
sbb   bx, 01000h

SELFMODIFY_BSP_clipangle_4:
mov   ax, 01000h
SELFMODIFY_BSP_viewangle_lo_2:
sub   di, 01000h
SELFMODIFY_BSP_viewangle_hi_2:
sbb   dx, 01000h
add   ax, bx
SELFMODIFY_BSP_fieldofview_1:
cmp   ax, 01000h
jbe   label_2
SELFMODIFY_BSP_fieldofview_2:
sub   ax, 01000h
cmp   ax, cx
ja    exit_addline
jne   label_3
mov   ax, word ptr [bp - 0Ah]  ; todo carry from above
cmp   ax, word ptr [bp - 8]
jae   exit_addline
label_3:
SELFMODIFY_BSP_clipangle_1:
mov   bx, 01000h
label_2:
xor   si, si
SELFMODIFY_BSP_clipangle_2:
mov   ax, 01000h
sub   si, di
sbb   ax, dx
mov   di, si
SELFMODIFY_BSP_fieldofview_3:
cmp   ax, 01000h
jbe   label_5
SELFMODIFY_BSP_fieldofview_4:
sub   ax, 01000h
cmp   ax, cx
ja    exit_addline
jne   label_4
cmp   si, word ptr [bp - 8]
jae   exit_addline
label_4:
SELFMODIFY_BSP_clipangle_3:
mov   dx, 01000h
neg   dx
label_5:
add   bh, (ANG90_HIGHBITS SHR 8)
mov   ax, VIEWANGLETOX_SEGMENT
IF COMPILE_INSTRUCTIONSET GE COMPILE_186
shr   bx, 3
ELSE
shr   bx, 1
shr   bx, 1
shr   bx, 1
ENDIF
mov   es, ax
add   bx, bx
add   dh, (ANG90_HIGHBITS SHR 8)
mov   ax, word ptr es:[bx]
mov   bx, dx
IF COMPILE_INSTRUCTIONSET GE COMPILE_186
shr   bx, 3
ELSE
shr   bx, 1
shr   bx, 1
shr   bx, 1
ENDIF
add   bx, bx
mov   dx, word ptr es:[bx]
cmp   ax, dx
je    exit_addline
mov   bx, LINEFLAGSLIST_SEGMENT
mov   es, bx
mov   bx, word ptr [bp - 4]
test  byte ptr es:[bx], 4
jne   label_6
mov   word ptr ds:[_backsector], 0FFFFh   ; does this ever get properly used or checked? can we just ignore?
clipsolid:
dec   dx
call  R_ClipSolidWallSegment_
exit_addline:
LEAVE_MACRO 
pop   di
pop   si
pop   dx
pop   cx
pop   bx
ret   
label_6:
mov   bl, byte ptr [bp - 2]
xor   bl, 1
xor   bh, bh
add   bx, bx
mov   si, LINES_SEGMENT
mov   es, si
add   bx, word ptr [bp - 010h]
mov   bx, word ptr es:[bx]
shl   bx, 1
shl   bx, 1
add   bx, _sides_render + 2    ; secnum field in this side_render_t
mov   si, word ptr [bx]
IF COMPILE_INSTRUCTIONSET GE COMPILE_186
shl   si, 4
ELSE
shl   si, 1
shl   si, 1
shl   si, 1
shl   si, 1
ENDIF
mov   word ptr ds:[_backsector], si
mov   es, word ptr ds:[_backsector + 2]

mov   di, word ptr ds:[_frontsector]

; todo do in order with lodsw and compare ax?

;    // Closed door.
;	if (backsector->ceilingheight <= frontsector->floorheight
;		|| backsector->floorheight >= frontsector->ceilingheight) 



; weird. this kills performance on pentium by 3%.
xchg  ax, bx   ; store first in bx

lods  word ptr es:[si]
cmp   ax, word ptr es:[di+2]
jge   clipsolid_ax_swap
xchg  ax, cx                  ; cx has old di+0
lods  word ptr es:[si]
cmp   ax, word ptr es:[di]
jle   clipsolid_ax_swap

;    // Window.
;    if (backsector->ceilingheight != frontsector->ceilingheight
;	|| backsector->floorheight != frontsector->floorheight)

cmp   ax, word ptr es:[di + 2]
jne   clippass
cmp   cx, word ptr es:[di]
jne   clippass

; if (backsector->ceilingpic == frontsector->ceilingpic
;		&& backsector->floorpic == frontsector->floorpic
;		&& backsector->lightlevel == frontsector->lightlevel
;		&& curlinesidedef->midtexture == 0) {
;		return;
;    }

lods  word ptr es:[si]

cmp   ax, word ptr es:[di + 4]
jne   clippass
mov   al, byte ptr es:[si + 08h] ; si offset by 6..
cmp   al, byte ptr es:[di + 0Eh]
jne   clippass
;    fall thru and return.
mov   si, LINES_SEGMENT
mov   es, si
mov   si, word ptr [bp - 012h]
cmp   word ptr es:[si + 4], 0
jne   clippass
jmp   exit_addline
clippass:
dec   dx
xchg  ax, bx                   ; grab cached first
call  R_ClipPassWallSegment_
LEAVE_MACRO
pop   di
pop   si
pop   dx
pop   cx
pop   bx
ret   
clipsolid_ax_swap:
xchg  ax, bx
dec   dx
call  R_ClipSolidWallSegment_
LEAVE_MACRO 
pop   di
pop   si
pop   dx
pop   cx
pop   bx
ret   


ENDP


SUBSECTOR_OFFSET_IN_SECTORS       = (SUBSECTORS_SEGMENT - SECTORS_SEGMENT) * 16
;SUBSECTOR_LINES_OFFSET_IN_SECTORS = (SUBSECTOR_LINES_SEGMENT - SECTORS_SEGMENT) * 16

;R_Subsector_

PROC R_Subsector_ NEAR
PUBLIC R_Subsector_ 


;ax is subsecnum

push  bx
push  cx
push  dx
push  bp
mov   bp, sp ; todo remove when we can?

mov   bx, ax
mov   ax, SUBSECTOR_LINES_SEGMENT
mov   es, ax
mov   al, byte ptr es:[bx]
xor   ah, ah
mov   word ptr cs:[SELFMODIFY_countvalue+1], ax    ; di stores count for later

mov   ax, SECTORS_SEGMENT
mov   es, ax

shl   bx, 1
shl   bx, 1

mov   ax, word ptr es:[bx+SUBSECTOR_OFFSET_IN_SECTORS] ; get subsec secnum


IF COMPILE_INSTRUCTIONSET GE COMPILE_186
 shl   ax, 4
ELSE
 shl   ax, 1
 shl   ax, 1
 shl   ax, 1
 shl   ax, 1
ENDIF


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
mov   word ptr ds:[_ceiltop+2], ax
mov   word ptr ds:[_floortop], ax
mov   word ptr ds:[_floortop+2], ax


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
call  Z_QuickMapVisplaneRevert_
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
mov   bx, 0FFFFh

loop_addline:

; what if we inlined AddLine? or unrolled this?
; whats realistic maximum of numlines? a few hundred? might be 1800ish bytes... save about 10 cycles per call to addline maybe?


mov   ax, bx   ; bx has firstline
call  R_AddLine_
inc   bx

loop   loop_addline




LEAVE_MACRO 

pop   dx
pop   cx
pop   bx
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




shl       di, 1
shl       di, 1
shl       di, 1
add       di, _visplaneheaders  ; _di is plheader
mov       byte ptr cs:[SELFMODIFY_setisceil + 1], cl  ; write cl value
test      cl, cl
;mov       cx, word ptr [bp - 03Ah]
mov       cx, bx    ; cx holds stop

je        check_plane_is_floor
;dec       cx
check_plane_is_ceil:
les       bx, dword ptr ds:[_ceiltop]
loaded_floor_or_ceiling:
; bx holds offset..

mov       ax, si  ; fetch start
cmp       ax, word ptr [di + 4]    ; compare to minx
jge       start_greater_than_min
mov       word ptr cs:[SELFMODIFY_setminx+3], ax
mov       dx, word ptr [di + 4]    ; fetch minx into intrl
checked_start:
; now checkmax
mov       ax, word ptr [di + 6]   ; fetch maxx, ax = intrh = plheader->max
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
mov       word ptr [di + 4], 0FFFFh
SELFMODIFY_setmax:
mov       word ptr [di + 6], 0FFFFh

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
mov       ax, word ptr [di + 4]

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
mov       ax, word ptr ds:[di]
mov       dx, word ptr ds:[di + 2]

;	visplanepiclights[lastvisplane].pic_and_light = visplanepiclights[index].pic_and_light;

; generate index from di again. 
sub       di, _visplaneheaders
sar       di, 1
sar       di, 1
mov       di, word ptr [di + _visplanepiclights]

mov       word ptr [bx + _visplanepiclights], di
sal       bx, 1
sal       bx, 1 ; now bx is 8 per

; set all plheader fields for lastvisplane...
mov       word ptr [bx + _visplaneheaders], ax
mov       word ptr [bx + _visplaneheaders+2], dx
mov       word ptr [bx + _visplaneheaders+4], si ; looks weird
mov       word ptr [bx + _visplaneheaders+6], cx  ; looks weird




SELFMODIFY_setisceil:
mov       dx, 0000h     ; set isceil argument

mov       ax, es 
mov       si, ax 
cbw      

call      R_HandleEMSPagination_
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

FF_FRAMEMASK = 07Fh
FF_FULLBRIGHT = 080h
MINZ_HIGHBITS = 4
;R_ProjectSprite_

PROC R_ProjectSprite_ NEAR
PUBLIC R_ProjectSprite_ 

; es:si is sprite.
; es is a constant..



; bp - 2:	 	xscale hi
; bp - 4:    	xscale lo
; bp - 6:    	thingframe (byte, with SIZEOF_SPRITEFRAME_T high)
; bp - 8:    	tr_y hi
; bp - 0Ah:    	tr_y low
; bp - 0Ch:    	tr_x hi
; bp - 0Eh:    	tr_x lo
; bp - 010h:	thingz hi
; bp - 012h:	thingz lo
; bp - 014h:	thingy hi
; bp - 016h:    thingy lo
; bp - 018h:	thingx hi
; bp - 01Ah:	thingx lo
; bp - 01Ch:	UNUSED
; bp - 01Eh:	UNUSED
; bp - 020h:    spriteindex. used for spriteframes and spritetopindex?


push  si
push  es
push  bp
mov   bp, sp
sub   sp, 020h
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
mov   word ptr [bp - 6], ax		



mov   cx, 6
mov   bx, ss
mov   es, bx					; es is SS i.e. destination segment
mov   ds, dx					; ds is movsw source segment
mov   ax, word ptr [si+010h]		; 010h
mov   word ptr cs:[SELFMODIFY_set_ax_to_angle_highword+1], ax
mov   al, byte ptr [si+016h]	; 016h
mov   byte ptr cs:[SELFMODIFY_set_al_to_flags2+1], al

lea   di, [bp - 01Ah]			; di is the stack area to copy to..

rep   movsw

;si is [si + 0xC] now...


mov   ds, bx					; restore ds to 3C00
lea   si, [bp - 01Ah]

lodsw
SELFMODIFY_set_viewx_lo_1:
sub   ax, 01000h
stosw
xchg   bx, ax
lodsw
SELFMODIFY_set_viewx_hi_1:
sbb   ax, 01000h
stosw
xchg   cx, ax						
lodsw
SELFMODIFY_set_viewy_lo_1:
sub   ax, 01000h
stosw
lodsw
SELFMODIFY_set_viewy_hi_1:
sbb   ax, 01000h
stosw

lea   si, [bp - 0Ah]
;    gxt.w = FixedMulTrigNoShift(FINE_COSINE_ARGUMENT, viewangle_shiftright1 ,tr_x.w);

mov   ax, FINECOSINE_SEGMENT
SELFMODIFY_set_viewanglesr1_3:
mov   dx, 01000h
mov   di, dx
call  FixedMulTrigNoShiftBSPLocal_




mov   cx, ax		; store gxt
xchg  di, dx		; get viewangle_shiftright1 into dx

; cx:bx = tr_y
lodsw
xchg  ax, bx
lodsw
xchg  ax, cx
xchg  ax, si

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

SELF_MODIFY_set_centerx_4:
mov   ax, 01000h

call  FixedDivWholeA_
mov   word ptr [bp - 4], ax
mov   word ptr [bp - 2], dx

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
shl   di, 1
shl   di, 1
sub   di, ax
mov   ax, SPRITES_SEGMENT
mov   es, ax
mov   ax, word ptr [bp - 6]
and   al, FF_FRAMEMASK
mul   ah
mov   di, word ptr es:[di]
mov   bx, di
add   bx, ax
cmp   byte ptr es:[bx + 018h], 0
mov   bx, 0				; rot 0 on jmp
je    skip_sprite_rotation
mov   ax, word ptr [bp - 01Ah]
mov   dx, word ptr [bp - 018h]
mov   bx, word ptr [bp - 016h]
mov   cx, word ptr [bp - 014h]


SELFMODIFY_set_viewx_lo_3:
sub   ax, 01000h
SELFMODIFY_set_viewx_hi_3:
sbb   dx, 01000h

SELFMODIFY_set_viewy_lo_3:
sub   bx, 01000h
SELFMODIFY_set_viewy_hi_3:
sbb   cx, 01000h

call  R_PointToAngle_
mov   ax, dx
;rot = _rotl(ang.hu.intbits - thingangle.hu.intbits + 0x9000u, 3) & 0x07;

SELFMODIFY_set_ax_to_angle_highword:
sub   ax, 01212h

add   ah, 090h
rol   ax, 1
rol   ax, 1
rol   ax, 1
and   ax, 7
mov   bx, ax				; rot result
skip_sprite_rotation:
mov   ax, word ptr [bp - 6]
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
mov   bx, word ptr [bp - 4]
mov   cx, word ptr [bp - 2]
xor   ah, ah

sub   si, ax						; no need for sbb?
SELFMODIFY_get_temp_lowbits:
mov   ax, 01234h
mov   di, ax
mov   dx, si
call FixedMulBSPLocal_
xchg  ax, dx

SELF_MODIFY_set_centerx_5:
add   ax, 01000h

;    // off the right side?
;    if (x1 > viewwidth){
;        return;
;    }
    

mov   word ptr cs:[SELFMODIFY_set_vis_x1+1], ax
mov   word ptr cs:[SELFMODIFY_sub_x1+1], ax
SELFMODIFY_set_viewwidth_2:
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


mov   bx, word ptr [bp - 4]
mov   cx, word ptr [bp - 2]
mov   dx, si

add   dx, ax					; no need for adc
mov   ax, di

call FixedMulBSPLocal_

;    x2 = temp.h.intbits - 1;

SELF_MODIFY_set_centerx_6:
add   dx, 01000h
dec   dx
mov   word ptr cs:[SELFMODIFY_set_ax_to_x2+1], dx

;    // off the left side
;    if (x2 < 0)
;        return;

test  dx, dx
jl    jump_to_exit_project_sprite_2

mov   si, word ptr ds:[_vissprite_p]
cmp  si, MAXVISSPRITES
je   got_vissprite
; don't increment vissprite if its the max index. reuse this index.
inc   word ptr ds:[_vissprite_p]
got_vissprite:
; mul by 28h or 40. SIZEOF_VISSPRITE_T
sal   si, 1   ; x2  02h
sal   si, 1   ; x4  04h
sal   si, 1   ; x8  08h
mov   bx, si
sal   si, 1   ; x16 10h
sal   si, 1   ; x32 20h
lea   si, [bx + si + OFFSET _vissprites] ; x40  28h


mov   ax, word ptr [bp - 4]
mov   di, word ptr [bp - 2]


SELFMODIFY_detailshift_2_minus_32_bit_rotate_jump_2:
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
mov   bx, word ptr [si + 0Eh]
add   ax, word ptr [si + 010h]
mov   word ptr [si + 012h], bx
mov   word ptr [si + 014h], ax

;    vis->texturemid = vis->gzt.w - viewz.w;

SELFMODIFY_BSP_viewz_lo_4:
sub       bx, 01000h
SELFMODIFY_BSP_viewz_hi_4:
sbb       ax, 01000h
mov   word ptr [si + 022h], bx
mov   word ptr [si + 024h], ax
SELFMODIFY_set_vis_x1:
mov   ax, 01234h

;    vis->x1 = x1 < 0 ? 0 : x1;

test  ax, ax
jge   x1_positive
xor   ax, ax

x1_positive:
mov   word ptr [si + 2], ax

;    vis->x2 = x2 >= viewwidth ? viewwidth-1 : x2;       

SELFMODIFY_set_ax_to_x2:
mov   ax, 00012h			; get x2

SELFMODIFY_set_viewwidth_3:
mov   bx, 01000h
cmp   ax, bx
jl    x2_smaller_than_viewwidth
mov   ax, bx
dec   ax
x2_smaller_than_viewwidth:
mov   bx, word ptr [bp - 4]
mov   cx, word ptr [bp - 2]
mov   word ptr [si + 4], ax
mov   ax, 1
call FixedDivWholeA_
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
mov   word ptr [si + 016h], -1
SELFMODIFY_set_ax_to_usedwidth:
mov   ax, 01234h 
dec   ax
mov   word ptr [si + 018h], ax

neg   dx
neg   bx
sbb   dx, 0

mov   word ptr [si + 01Eh], bx
mov   word ptr [si + 020h], dx

flip_stuff_done:


;    if (vis->x1 > x1)
;        vis->startfrac += FastMul16u32u((vis->x1-x1),vis->xiscale);

mov   ax, word ptr [si + 2]
SELFMODIFY_sub_x1:
sub   ax, 01234h
jle   vis_x1_greater_than_x1
mov   bx, word ptr [si + 01Eh]
mov   cx, word ptr [si + 020h]

; inlined FastMul16u32u
XCHG CX, AX    ; AX stored in CX
MUL  CX        ; AX * CX
XCHG CX, AX    ; store low product to be high result. Retrieve orig AX
MUL  BX        ; AX * BX
ADD  DX, CX    ; add 

add   word ptr [si + 016h], ax
adc   word ptr [si + 018h], dx

vis_x1_greater_than_x1:
mov   bx, word ptr [bp - 020h]
mov   word ptr [si + 026h], bx

;    if (thingflags2 & MF_SHADOW) {

SELFMODIFY_set_al_to_flags2:
mov   al, 00h
test  al, 4
jne   exit_set_shadow
SELFMODIFY_BSP_fixedcolormap_2:
jne   exit_set_fixed_colormap
SELFMODIFY_BSP_fixedcolormap_2_AFTER:
test  byte ptr [bp - 6], FF_FULLBRIGHT
jne   exit_set_fullbright_colormap


;        index = xscale.w>>(LIGHTSCALESHIFT-detailshift.b.bytelow);

; shift 32 bit value by (12 - detailshift) right.
; but final result is capped at 48. so we dont have to do as much with the high word...
mov   ax, word ptr [bp - 3] ; shift 8 by loading a byte higher.
; shift 2 more guaranteed
sar   ax, 1
sar   ax, 1

; test for detailshift portion
SELFMODIFY_detailshift_16_bit_jump_1:
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
mov   bx, word ptr ds:[_spritelights]
mov   al, byte ptr ds:[_scalelightfixed+bx+di]
mov   byte ptr [si + 1], al
LEAVE_MACRO
pop   es
pop   si
ret   

exit_set_fullbright_colormap:
mov   byte ptr [si + 1], 0
LEAVE_MACRO
pop   es
pop   si
ret   

SELFMODIFY_BSP_fixedcolormap_2_TARGET:
SELFMODIFY_BSP_fixedcolormap_1:
exit_set_fixed_colormap:
mov   byte ptr [si + 1], 0
LEAVE_MACRO
pop   es
pop   si
ret   


flip_zero:
mov   word ptr [si + 016h], 0
mov   word ptr [si + 018h], 0
mov   word ptr [si + 01Eh], bx
mov   word ptr [si + 020h], dx
jmp   flip_stuff_done
exit_set_shadow:
mov   byte ptr [si + 1], COLORMAP_SHADOW
LEAVE_MACRO
pop   es
pop   si
ret   

ENDP





;R_AddSprites_

PROC R_AddSprites_ NEAR
PUBLIC R_AddSprites_ 

; DX:AX = sector_t __far* sec

push  bx
mov   bx, ax
mov   es, dx
mov   ax, word ptr es:[bx + 6]		; sec->validcount
mov   dx, word ptr ds:[_validcount]
cmp   ax, dx
je    exit_add_sprites_bx_only				; do this without push/pop
push  di
push  si

mov   word ptr es:[bx + 6], dx
mov   al, byte ptr es:[bx + 0Eh]		; sec->lightlevel
xor   ah, ah
mov   dx, ax
IF COMPILE_INSTRUCTIONSET GE COMPILE_186
sar   dx, 4
ELSE
sar   dx, 1
sar   dx, 1
sar   dx, 1
sar   dx, 1
ENDIF
SELFMODIFY_set_extralight_1:
mov   al, 0
add   ax, dx
test  ax, ax
jl    set_spritelights_to_zero
cmp   ax, LIGHTLEVELS
jge   set_spritelights_to_max
mov   si, ax
add   si, ax
mov   ax, word ptr ds:[si + _lightmult48lookup]
spritelights_set:
mov   word ptr ds:[_spritelights], ax
mov   ax, word ptr es:[bx + 8]
test  ax, ax
je    exit_add_sprites
mov   si, MOBJPOSLIST_SEGMENT
mov   es, si

loop_things_in_thinglist:
; multiply by 18h (SIZEOF_MOBJ_POS_T), AX maxes at MAX_THINKERS - 1 (839), cant 8 bit mul
sal   ax, 1
sal   ax, 1
sal   ax, 1
mov   si, ax
sal   si, 1
add   si, ax
call  R_ProjectSprite_
mov   ax, word ptr es:[si + 0Ch]
test  ax, ax
jne   loop_things_in_thinglist

exit_add_sprites:
pop   si
pop   di
exit_add_sprites_bx_only:
pop   bx
ret   
set_spritelights_to_zero:
xor   ax, ax
jmp   spritelights_set
set_spritelights_to_max:
; _NULL_OFFSET + 02A0h + 16 - 1 ... (0x2ee)
mov   ax, word ptr ds:[_lightmult48lookup + (2 * (LIGHTLEVELS - 1))]
jmp   spritelights_set


endp

COLFUNC_JUMP_AND_DC_YL_OFFSET_DIFF   = ((DC_YL_LOOKUP_SEGMENT - COLFUNC_JUMP_LOOKUP_SEGMENT) * 16)
COLFUNC_JUMP_AND_FUNCTION_AREA_OFFSET_DIFF = ((COLFUNC_FUNCTION_AREA_SEGMENT - COLFUNC_JUMP_LOOKUP_SEGMENT) * 16)









; 1 SHR 12
HEIGHTUNIT = 01000h
HEIGHTBITS = 12
FINE_ANGLE_HIGH_BYTE = 01Fh
FINE_TANGENT_MAX = 2048

;R_RenderSegLoop_

PROC R_RenderSegLoop_ NEAR
PUBLIC R_RenderSegLoop_ 


; no arguments..
; no permanent stack allocation
; order all these in memory then movsw


push  bx
push  cx ; todo which of these do we actually need to push and pop?
push  si
push  di

xchg  ax, cx
mov   ax, word ptr [bp - 038h]    ; rw_x
mov   bx, ax
mov   di, ax
SELFMODIFY_detailshift_and_1:

and   bx, 01000h
mov   word ptr cs:[SELFMODIFY_add_rw_x_base4_to_ax+1], bx
mov   word ptr cs:[SELFMODIFY_compare_ax_to_start_rw_x+1], ax	

; self modify code in the function to set constants rather than
; repeatedly reading loop-constant or function-constant variables.

mov   byte ptr cs:[SELFMODIFY_set_al_to_xoffset+1], 0



mov   ax, word ptr [bp - 03Ah]
mov   word ptr cs:[SELFMODIFY_cmp_di_to_rw_stopx_1+1], ax
mov   word ptr cs:[SELFMODIFY_cmp_di_to_rw_stopx_2+1], ax
mov   word ptr cs:[SELFMODIFY_cmp_di_to_rw_stopx_3+1], ax


cmp   byte ptr [bp - 04Ah], 0 ;markfloor

je    do_markfloor_selfmodify_jumps
mov   ax, 04940h     ; inc ax dec cx
mov   si, 02647h     ; inc di, es:
jmp do_markfloor_selfmodify
do_markfloor_selfmodify_jumps:
mov   ax, ((SELFMODIFY_BSP_markfloor_1_TARGET - SELFMODIFY_BSP_markfloor_1_AFTER) SHL 8) + 0EBh
mov   si, ((SELFMODIFY_BSP_markfloor_2_TARGET - SELFMODIFY_BSP_markfloor_2_AFTER) SHL 8) + 0EBh
do_markfloor_selfmodify:

mov   word ptr cs:[SELFMODIFY_BSP_markfloor_1], ax
mov   word ptr cs:[SELFMODIFY_BSP_markfloor_2], si

mov   ah, byte ptr [bp - 049h] ;markceiling
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

mov   word ptr cs:[SELFMODIFY_BSP_markceiling_1], ax
mov   word ptr cs:[SELFMODIFY_BSP_markceiling_2], si

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

lodsw
mov   word ptr cs:[SELFMODIFY_set_rw_scale_lo+1], ax
lodsw
mov   word ptr cs:[SELFMODIFY_set_rw_scale_hi+1], ax
lodsw ; topfrac lo
mov   word ptr cs:[SELFMODIFY_set_topfrac_lo+1], ax
lodsw ; topfrac hi
mov   word ptr cs:[SELFMODIFY_set_topfrac_hi+1], ax
lodsw ; bottomfrac lo
mov   word ptr cs:[SELFMODIFY_set_botfrac_lo+1], ax
lodsw ; bottomfrac hi
mov   word ptr cs:[SELFMODIFY_set_botfrac_hi+1], ax
SELFMODIFY_BSP_midtextureonly_skip_pixhighlow_3:
jmp SELFMODIFY_BSP_midtextureonly_skip_pixhighlow_3_TARGET
SELFMODIFY_BSP_midtextureonly_skip_pixhighlow_3_AFTER = SELFMODIFY_BSP_midtextureonly_skip_pixhighlow_3 + 2
lodsw ; pixlow lo
mov   word ptr cs:[SELFMODIFY_set_pixlow_lo+1], ax
lodsw ; pixlow hi
mov   word ptr cs:[SELFMODIFY_set_pixlow_hi+1], ax
lodsw ; pixhigh lo
mov   word ptr cs:[SELFMODIFY_set_pixhigh_lo+1], ax
lodsw ; pixhigh hi
mov   word ptr cs:[SELFMODIFY_set_pixhigh_hi+1], ax
SELFMODIFY_BSP_midtextureonly_skip_pixhighlow_3_TARGET:
mov   al, 0 ; xoffset is 0
mov   dx, SC_DATA  ; cheat this out of the loop..

continue_outer_rendersegloop:

SELFMODIFY_BSP_midtextureonly_skip_pixhighlow_2_TARGET:
cbw  
mov   bx, ax	; copy xoffset to bx
inc   byte ptr cs:[SELFMODIFY_set_al_to_xoffset+1]

SELFMODIFY_detailshift_plus1_1:
mov   al, byte ptr [bx + OFFSET _quality_port_lookup]	
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
mov   word ptr [bp - 038h], ax    ; rw_x
SELFMODIFY_compare_ax_to_start_rw_x:
cmp   ax, 1000h
jl    pre_increment_values

SELFMODIFY_cmp_di_to_rw_stopx_3:
cmp   ax, 01000h   ; cmp   di, word ptr [bp - 03Ah]
jl    jump_to_start_per_column_inner_loop

finish_outer_loop:
; todo: self modifying code for step values.



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
add   word ptr cs:[SELFMODIFY_set_topfrac_lo+1], 01000h
SELFMODIFY_add_topstep_hi:
adc   word ptr cs:[SELFMODIFY_set_topfrac_hi+1], 01000h

SELFMODIFY_add_botstep_lo:
add   word ptr cs:[SELFMODIFY_set_botfrac_lo+1], 01000h
SELFMODIFY_add_botstep_hi:
adc   word ptr cs:[SELFMODIFY_set_botfrac_hi+1], 01000h

SELFMODIFY_add_rwscale_lo:
add   word ptr cs:[SELFMODIFY_set_rw_scale_lo+1], 01000h
SELFMODIFY_add_rwscale_hi:
adc   word ptr cs:[SELFMODIFY_set_rw_scale_hi+1], 01000h

SELFMODIFY_BSP_midtextureonly_skip_pixhighlow_2:
je   SELFMODIFY_BSP_midtextureonly_skip_pixhighlow_2_TARGET
SELFMODIFY_BSP_midtextureonly_skip_pixhighlow_2_AFTER = SELFMODIFY_BSP_midtextureonly_skip_pixhighlow_2 + 2

SELFMODIFY_add_pixlowstep_lo:
add   word ptr cs:[SELFMODIFY_set_pixlow_lo+1], 01000h
SELFMODIFY_add_pixlowstep_hi:
adc   word ptr cs:[SELFMODIFY_set_pixlow_hi+1], 01000h

SELFMODIFY_add_pixhighstep_lo:
add   word ptr cs:[SELFMODIFY_set_pixhigh_lo+1], 01000h
SELFMODIFY_add_pixhighstep_hi:
adc   word ptr cs:[SELFMODIFY_set_pixhigh_hi+1], 01000h


jmp   continue_outer_rendersegloop


exit_rendersegloop:
; zero out local caches.
mov   ax, 0FFFFh
mov   word ptr ds:[_segloopnextlookup], ax
mov   word ptr ds:[_segloopnextlookup+2], ax
inc   ax
; zero both 
mov   word ptr ds:[_seglooptexrepeat], ax


pop   di
pop   si
pop   cx
pop   bx
ret   



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
mov   word ptr [bp - 038h], ax     ; rw_x
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
jmp SELFMODIFY_BSP_midtextureonly_skip_pixhighlow_1_TARGET
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
cmp   ax, 01000h   ; cmp   ax, word ptr [bp - 03Ah]
jge   jump_to_finish_outer_loop_2

start_per_column_inner_loop:
; ax was rw_x
; now di is rw_x
mov   di, ax   ; ax was still rw_x


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
je    markceiling_done
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
shr   ax, 1
shr   ax, 1
shr   ax, 1
shr   ax, 1

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
je    jump_to_seg_non_textured
SELFMODIFY_BSP_get_segtextured_AFTER:
seg_is_textured:

; angle = MOD_FINE_ANGLE (rw_centerangle + xtoviewangle[rw_x]);

mov   ax, XTOVIEWANGLE_SEGMENT
mov   es, ax
SELFMODIFY_set_rw_center_angle:
mov   ax, 01000h			; mov   ax, word ptr ds:[_rw_centerangle]
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
shl   bx, 1
shl   bx, 1
mov   ax, word ptr es:[bx]
mov   dx, word ptr es:[bx + 2]
neg   dx
neg   ax
sbb   dx, 0
jmp   finetangent_ready
SELFMODIFY_BSP_get_segtextured_TARGET:
jump_to_seg_non_textured:
xor   dx, dx
jmp   seg_non_textured
non_subtracted_finetangent:
shl   bx, 1
shl   bx, 1
mov   ax, word ptr es:[bx]
mov   dx, word ptr es:[bx + 2]
finetangent_ready:
; calculate texture column
SELFMODIFY_set_bx_rw_distance_lo:
mov   bx, 01000h	; mov   bx, word ptr ds:[_rw_distance]
SELFMODIFY_set_cx_rw_distance_hi:
mov   cx, 01000h	; mov   cx, word ptr ds:[_rw_distance+2]


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


SELFMODIFY_set_cx_rw_offset_lo:	;
mov   cx, 01000h			; mov   cx, word ptr ds:[_rw_offset]
sub   cx, ax
SELFMODIFY_set_ax_rw_offset_hi:
mov   ax, 01000h            ; mov   ax, word ptr ds:[_rw_offset + 2]
sbb   ax, dx

;	if (rw_scale.h.intbits >= 3) {
;		index = MAXLIGHTSCALE - 1;
;	} else {
;		index = rw_scale.w >> LIGHTSCALESHIFT;
;	}

; CX:BX rw_scale
; todo bp/stack candidate
les   bx, dword ptr [bp - 032h]
mov   cx, es

; store texture column
push  ax

cmp   cx, 3
jge   use_max_light
do_lightscaleshift:
mov   al, bh
mov   ah, cl
mov   dl, ch
sar   dl, 1
rcr   ax, 1
sar   dl, 1
rcr   ax, 1
sar   dl, 1
rcr   ax, 1
sar   dl, 1
rcr   ax, 1
mov   si, ax
jmp   light_set


fast_div_32_16_FFFF:

xchg dx, cx   ; cx was 0, dx is FFFF
div bx        ; after this dx stores remainder, ax stores q1
xchg cx, ax   ; q1 to cx, ffff to ax  so div remaidner:ffff 
div bx
mov dx, cx   ; q1:q0 is dx:ax
jmp FastDiv3232FFFF_done 


use_max_light:
mov   si, MAXLIGHTSCALE - 1
light_set:

; INLINED FASTDIV3232FFF_ algo. only used here.

; set ax:dx ffffffff

; if top 16 bits missing just do a 32 / 16
mov  ax, -1
cwd

test cx, cx
je fast_div_32_16_FFFF

main_3232_div:

push  si
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

pop   di
pop   si
jmp FastDiv3232FFFF_done

compare_low_word_3232:
cmp   ax, si
jbe   qhat_subtract_1_3232

; ugly but rare occurrence i think?
qhat_subtract_2_3232:
mov ax, es
dec ax
dec ax

pop   di
pop   si
jmp FastDiv3232FFFF_done  


; do jmp. highest priority, overwrite previously written thing.
seglooptexrepeat0_is_jmp:
mov   word ptr cs:[SELFMODIFY_BSP_set_seglooptexrepeat0], ((SELFMODIFY_BSP_set_seglooptexrepeat0_TARGET - SELFMODIFY_BSP_set_seglooptexrepeat0_AFTER) SHL 8) + 0EBh
jmp   just_do_draw0
in_texture_bounds0:
xchg  ax, dx
sub   al, byte ptr [_segloopcachedbasecol]
mul   byte ptr [_segloopheightvalcache]
jmp   add_base_segment_and_draw0
SELFMODIFY_BSP_set_seglooptexrepeat0_TARGET:
non_repeating_texture0:
cmp   dx, word ptr [_segloopnextlookup]
jge   out_of_texture_bounds0
cmp   dx, word ptr [_segloopprevlookup]
jge   in_texture_bounds0
out_of_texture_bounds0:
push  bx
xor   bx, bx

SELFMODIFY_BSP_set_toptexture:
SELFMODIFY_BSP_set_midtexture:
mov   ax, 01000h
call  R_GetColumnSegment_
pop   bx

mov   dx, word ptr [_segloopcachedsegment]
mov   word ptr cs:[SELFMODIFY_add_cached_segment0+1], dx

COMMENT @ REDO THIS AREA IF WE RE-ADD NON PO2 TEXTURES
; see above, but all textures in vanilla are po2 so this is not necessary for now.
mov   dh, byte ptr [_seglooptexmodulo]
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

mov   dh, byte ptr [_seglooptexrepeat]
cmp   dh, 0
je    seglooptexrepeat0_is_jmp
; modulo is seglooptexrepeat - 1
mov   dl, byte ptr [_segloopheightvalcache]
mov   byte ptr cs:[SELFMODIFY_BSP_check_seglooptexmodulo0],   0B8h   ; mov ax, xxxx
mov   word ptr cs:[SELFMODIFY_BSP_check_seglooptexmodulo0+1], dx

jmp   just_do_draw0



q1_ready_3232:

mov  ax, es
xor  dx, dx;

pop   di
pop   si

FastDiv3232FFFF_done:

; do the bit shuffling etc when writing direct to drawcol.

mov   dh, dl
mov   dl, ah
mov   word ptr cs:[SELFMODIFY_BSP_set_dc_iscale_lo+1], ax		; todo: write these to code but masked has to as well..
mov   word ptr cs:[SELFMODIFY_BSP_set_dc_iscale_hi+1], dx  
SELFMODIFY_add_wallights:

; scalelight is pre-shifted 4 to save on the double sal every column.
mov   al, byte ptr ds:[si+01000h]         ; 8a 84 00 10 
;        set drawcolumn colormap function address
mov   byte ptr cs:[SELFMODIFY_COLFUNC_set_colormap_index_jump], al

; store dc_x directly in code
mov   word ptr cs:[SELFMODIFY_COLFUNC_get_dc_x+1], di

; get texturecolumn     in dx
pop   dx

seg_non_textured:
; si/di are yh/yl
;if (yh >= yl){
mov   bx, di 			; store rw_x
add   bx, bx
mov   ax, OPENINGS_SEGMENT
mov   es, ax

; dx holds texturecolumn
; get yl/yh in di/si
pop   di
pop   si
SELFMODIFY_BSP_midtexture:
SELFMODIFY_BSP_midtexture_AFTER = SELFMODIFY_BSP_midtexture + 3

cmp   di, si
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
mov   word ptr ds:[_dc_source_segment], ax ; what if this was push then pop es later.
SELFMODIFY_set_midtexturemid_hi:
SELFMODIFY_set_toptexturemid_hi:
mov   dx, 01000h
SELFMODIFY_set_midtexturemid_lo:
SELFMODIFY_set_toptexturemid_lo:
mov   cx, 01000h

; fall thru in the case of top/bot column.
PROC  R_DrawColumnPrep_ NEAR
PUBLIC  R_DrawColumnPrep_ 


push  bx
push  si
push  di


mov   ax, COLFUNC_JUMP_LOOKUP_SEGMENT        ; compute segment now, clear AX dependency
mov   es, ax ; store this segment for now, with offset pre-added

SELFMODIFY_COLFUNC_get_dc_x:
mov   ax, 01000h

; shift ax by (2 - detailshift.)
; todo: are we benefitted by moving this out into rendersegrange..?
SELFMODIFY_COLFUNC_detailshift_2_minus_16_bit_shift:
sar   ax, 1
sar   ax, 1

; dest = destview + dc_yl*80 + (dc_x>>2); 
; frac.w = dc_texturemid.w + (dc_yl-centery)*dc_iscale

; si is dc_yl 
mov   bx, si
add   ax, word ptr es:[bx+si+COLFUNC_JUMP_AND_DC_YL_OFFSET_DIFF]                  ; set up destview 
SELFMODIFY_COLFUNC_add_destview_offset:
add   ax, 01000h

; di is dc_yh
sub   di, bx                                 ;
add   di, di                                 ; double diff (dc_yh - dc_yl) to get a word offset
mov   di, word ptr es:[di]                   ; get the jump value
xchg  ax, di								 ; di gets screen dest offset, ax gets jump value
mov   word ptr es:[((SELFMODIFY_COLFUNC_jump_offset+1))+COLFUNC_JUMP_AND_FUNCTION_AREA_OFFSET_DIFF], ax  ; overwrite the jump relative call for however many iterations in unrolled loop we need


xchg  ax, bx            ; dc_yl in ax
mov   si, dx            ; dc_texturemid+2 to si

; We don't have easy access into the drawcolumn code segment.
; so instead of cli -> push bp after call, we do it right before,
; so that we have register space to use bp now instead of a bit later.
; (for carrying dc_texturemid)

cli 				    ; disable interrupts
push  bp
mov   bp, cx	        ; dc_texturemid to bp

; dc_iscale loaded here..
SELFMODIFY_BSP_set_dc_iscale_lo:
mov   bx, 01000h        ; dc_iscale +0
SELFMODIFY_BSP_set_dc_iscale_hi:
mov   cx, 01000h        ; dc_iscale +1

; dynamic call lookuptable based on used colormaps address being CS:00

db 0FFh  ; lcall[addr]
db 01Eh  ;
SELFMODIFY_COLFUNC_set_colormap_index_jump:
dw 0300h
; addr 0300 + first byte (4x colormap.)

pop   bp 
sti					; re-enable interrupts

pop   di 
pop   si
pop   bx

SELFMODIFY_BSP_R_DrawColumnPrep_ret:

; the pop dx gets replaced with ret if bottom is calling
pop   dx
pop   es

; this runs as a jmp for a top call, otherwise NOP for mid call
SELFMODIFY_BSP_midtexture_return_jmp:
; JMP back runs for a TOP call
; we overwrite the next instruction with a jmp if toptexture call. otherwise we restore it.
SELFMODIFY_BSP_midtexture_return_jmp_AFTER = SELFMODIFY_BSP_midtexture_return_jmp+3


mid_no_pixels_to_draw:
; bx is already _rw_x << 1
SELFMODIFY_setviewheight_1:
mov   word ptr es:[bx + OFFSET_CEILINGCLIP], 01000h   ; 26 c7 87 80 a7 00 10  (this instruction that gets selfmodified)
mov   word ptr es:[bx + OFFSET_FLOORCLIP], 0FFFFh
finished_inner_loop_iter:

;		for ( ; rw_x < rw_stopx ; 
;			rw_x		+= detailshiftitercount,
;			topfrac 	+= topstepshift,
;			bottomfrac  += bottomstepshift,
;			rw_scale.w  += rwscaleshift

SELFMODIFY_add_detailshiftitercount:
add   word ptr [bp - 038h], 0   ; rw_x
mov   ax, word ptr [bp - 038h]  ; rw_x
SELFMODIFY_cmp_di_to_rw_stopx_2:
cmp   ax, 01000h   ; cmp   di, word ptr [bp - 03Ah]
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
mov   dx, SC_DATA  ; cheat this out of the loop..
jmp   finish_outer_loop

SELFMODIFY_BSP_toptexture_TARGET:
no_top_texture_draw:
; bx is already rw_x << 1
SELFMODIFY_BSP_markceiling_2:
je   check_bottom_texture
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
je    non_repeating_texture1
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

SELFMODIFY_set_bottexturemid_hi:
mov   dx, 01000h
SELFMODIFY_set_bottexturemid_lo:
mov   cx, 01000h

; small idea: make these each three NOPs if its gonna be a bot only draw?
SELFMODIFY_bottomtexonly_1:
mov   byte ptr cs:[SELFMODIFY_BSP_R_DrawColumnPrep_ret], 0C3h  ; ret
call  R_DrawColumnPrep_
SELFMODIFY_bottomtexonly_2:
mov   byte ptr cs:[SELFMODIFY_BSP_R_DrawColumnPrep_ret], 05Ah  ; pop dx

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
mov   dx, word ptr [2 + _segloopcachedbasecol]
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
mov   word ptr [2 + _segloopcachedbasecol], dx

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
mov   word ptr [2 + _segloopcachedbasecol], dx
add   dx, cx

done_adding_modulo1:
sub   dx, cx
mov   ah, byte ptr [1 + _segloopheightvalcache]
sub   al, dl
mul   ah
jmp   add_base_segment_and_draw1

@ REDO THIS AREA IF WE RE-ADD NON PO2 TEXTURES

SELFMODIFY_BSP_set_seglooptexrepeat1_TARGET:
non_repeating_texture1:
cmp   dx, word ptr [2 + _segloopnextlookup]
jge   out_of_texture_bounds1
cmp   dx, word ptr [2 + _segloopprevlookup]
jge   in_texture_bounds1
out_of_texture_bounds1:
push  bx
mov   bx, 1

SELFMODIFY_BSP_set_bottomtexture:
mov   ax, 01000h
call  R_GetColumnSegment_
pop   bx

mov   dx, word ptr [2 + _segloopcachedsegment]
mov   word ptr cs:[SELFMODIFY_add_cached_segment1+1], dx




COMMENT @ REDO THIS AREA IF WE RE-ADD NON PO2 TEXTURES
mov   dh, byte ptr [1 + _seglooptexmodulo]
mov   byte ptr cs:[SELFMODIFY_BSP_set_seglooptexmodulo1+1], dh

cmp   dh, 0
je    seglooptexmodulo1_is_jmp

mov   dl, 0B2h   ;  (mov dl, xx)
mov   word ptr cs:[SELFMODIFY_BSP_check_seglooptexmodulo1], dx
jmp   check_seglooptexrepeat1
seglooptexmodulo1_is_jmp:
mov   word ptr cs:[SELFMODIFY_BSP_check_seglooptexmodulo1], ((SELFMODIFY_BSP_check_seglooptexmodulo1_TARGET - SELFMODIFY_BSP_check_seglooptexmodulo1_AFTER) SHL 8) + 0EBh
@


check_seglooptexrepeat1:
; todo get this dh and dl in same read
mov   dh, byte ptr [1 + _seglooptexrepeat]
cmp   dh, 0
je    seglooptexrepeat1_is_jmp
; modulo is seglooptexrepeat - 1
mov   dl, byte ptr [1 + _segloopheightvalcache]
mov   byte ptr cs:[SELFMODIFY_BSP_check_seglooptexmodulo1],   0B8h   ; mov ax, xxxx
mov   word ptr cs:[SELFMODIFY_BSP_check_seglooptexmodulo1+1], dx

jmp   just_do_draw1
; do jmp. highest priority, overwrite previously written thing.
seglooptexrepeat1_is_jmp:
mov   word ptr cs:[SELFMODIFY_BSP_set_seglooptexrepeat1], ((SELFMODIFY_BSP_set_seglooptexrepeat1_TARGET - SELFMODIFY_BSP_set_seglooptexrepeat1_AFTER) SHL 8) + 0EBh
jmp   just_do_draw1
in_texture_bounds1:
xchg  ax, dx  ; put texturecol in ax
sub   al, byte ptr [2 + _segloopcachedbasecol]
mul   byte ptr [1 + _segloopheightvalcache]
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


   



ENDP

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
; bp - 1     ; frontsectorlightlevel
; bp - 2     ; backsectorlightlevel
; bp - 3     ; frontsectorfloorpic
; bp - 4     ; backsectorfloorpic
; bp - 5     ; frontsectorceilingpic
; bp - 6     ; backsectorceilingpic
; bp - 8     ; UNUSED
; bp - 0Ah   ; UNUSED
; bp - 0Ch   ; UNUSED
; bp - 0Eh   ; offsetangle
; bp - 010h  ; frontsectorfloorheight
; bp - 012h  ; frontsectorceilingheight
; bp - 014h  ; side toptexture
; bp - 016h  ; side bottomtexture
; bp - 018h  ; hyp lo
; bp - 01Ah  ; hyp hi
; bp - 01Ch  ; side midtexture
; bp - 01Eh  ; UNUSED
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
; bp - 034h  ; worldbottom hi
; bp - 036h  ; worldbottom lo
; bp - 038h  ; _rw_x
; bp - 03Ah  ; _rw_stopx
; bp - 03Ch  ; v1.x ; selfmodify forward?
; bp - 03Eh  ; v1.y ; selfmodify forward?
; bp - 040h  ; backsectorfloorheight
; bp - 042h  ; backsectorceilingheight
; bp - 044h  ; worldtop hi
; bp - 046h  ; worldtop lo
; bp - 048h  ; lineflags
; bp - 049h  ; markceiling
; bp - 04Ah  ; markfloor

; bp - 04Ch  ; dx arg
; bp - 04Eh  ; ax arg


push      bx
push      cx
push      si
push      di
push      bp
mov       bp, sp
sub       sp, 04Ah
push      ax
push      dx
xor       ax, ax
mov       word ptr [bp - 018h], ax
mov       word ptr [bp - 01Ah], ax

mov       bx, word ptr ds:[_curseg_render]
mov       si, SIDES_SEGMENT
mov       es, si
mov       si, word ptr ds:[bx + 6]
shl       si, 1
shl       si, 1
mov       di, si
shl       si, 1
; read all the sides fields now

lods      word ptr es:[si]
mov       [bp - 014h], ax
lods      word ptr es:[si]
mov       [bp - 016h], ax
lods      word ptr es:[si]
mov       [bp - 01Ch], ax
lods      word ptr es:[si]
mov       word ptr cs:[SELFMODIFY_BSP_sidetextureoffset+1], ax

mov       ax, word ptr [di+_sides_render]
mov       word ptr cs:[SELFMODIFY_BSP_siderenderrowoffset_1+1], ax
mov       word ptr cs:[SELFMODIFY_BSP_siderenderrowoffset_2+1], ax

mov       si, word ptr ds:[bx]
mov       ax, VERTEXES_SEGMENT 
mov       es, ax	; if put into ds we could lodsw a bit... worth?
shl       si, 1
shl       si, 1
lods 	    word ptr es:[si]
mov       word ptr [bp - 03Ch], ax
lods 	    word ptr es:[si]
mov       word ptr [bp - 03Eh], ax

mov       si, word ptr ds:[bx + 2]
shl       si, 1
shl       si, 1

lods 	    word ptr es:[si]
mov       word ptr cs:[SELFMODIFY_BSP_v2x+1], ax
lods      word ptr es:[si]
mov       word ptr cs:[SELFMODIFY_BSP_v2y+1], ax

mov       bx, word ptr ds:[_ds_p]
cmp       bx, (MAXDRAWSEGS * SIZEOF_DRAWSEG_T)
je        out_of_drawsegs

mov       ax, SEG_LINEDEFS_SEGMENT
mov       es, ax
mov       si, word ptr ds:[_curseg]
add       si, si
mov       ax, LINEFLAGSLIST_SEGMENT
mov       si, word ptr es:[si]
mov       es, ax
mov       al, byte ptr es:[si]
xor       ah, ah
mov       word ptr [bp - 048h], ax

;	seenlines[linedefOffset/8] |= (0x01 << (linedefOffset % 8));
; si is linedefOffset

mov       cx, si
sar       si, 3
mov       ax, SEENLINES_SEGMENT
mov       es, ax
mov       al, 1
and       cl, 7
shl       al, cl
or        byte ptr es:[si], al
mov       bx, word ptr ds:[_curseg]
add       bx, bx

mov       ax, word ptr [bx+_seg_normalangles]

mov       word ptr cs:[SELFMODIFY_sub_rw_normal_angle_1+1], ax
mov       word ptr cs:[SELFMODIFY_sub_rw_normal_angle_2+1], ax



IF COMPILE_INSTRUCTIONSET GE COMPILE_186
shl       ax, SHORTTOFINESHIFT
ELSE
shl       ax, 1
shl       ax, 1
shl       ax, 1
ENDIF
mov       word ptr cs:[SELFMODIFY_set_rw_normal_angle_shift3+1], ax


;	offsetangle = (abs((rw_normalangle_shiftleft3) - (rw_angle1.hu.intbits)) >> 1) & 0xFFFC;
sub       ax, word ptr ds:[_rw_angle1 + 2]
cwd       
xor       ax, dx		; what's this about. is it an abs() thing?
sub       ax, dx
sar       ax, 1

and       al, 0FCh
mov       word ptr [bp - 0Eh], ax
mov       si, FINE_ANG90_NOSHIFT
cmp       ax, si
jb        offsetangle_below_ang_90
offsetangle_above_ang_90:
xor       ax, ax
mov       dx, ax
jmp       do_set_rw_distance
out_of_drawsegs:
LEAVE_MACRO
pop       di
pop       si
pop       cx
pop       bx
ret       

offsetangle_below_ang_90:
mov       dx, word ptr [bp - 03Eh]
mov       ax, word ptr [bp - 03Ch]
call      R_PointToDist_
mov       word ptr [bp - 018h], ax
mov       word ptr [bp - 01ah], dx
sub       si, word ptr [bp - 0Eh]
mov       bx, ax
mov       cx, dx
mov       ax, FINESINE_SEGMENT
mov       dx, si
call     FixedMulTrigNoShiftBSPLocal_

do_set_rw_distance:

; self modifying code for rw_distance
mov   word ptr cs:[SELFMODIFY_set_bx_rw_distance_lo+1], ax
mov   word ptr cs:[SELFMODIFY_set_cx_rw_distance_hi+1], dx
mov   word ptr cs:[SELFMODIFY_get_rw_distance_lo_1+1], ax
mov   word ptr cs:[SELFMODIFY_get_rw_distance_hi_1+1], dx

done_setting_rw_distance:
les       di, dword ptr ds:[_ds_p]
mov       ax, word ptr ds:[_curseg]
stos      word ptr es:[di]             ; +0

mov       ax, word ptr [bp - 04Ch]
mov       word ptr [bp - 038h], ax   ; rw_x
stos      word ptr es:[di]             ; +2

mov       ax, word ptr [bp - 04Eh]
stos      word ptr es:[di]             ; +4

mov       ax, word ptr [bp - 04Eh]
inc       ax
mov       word ptr [bp - 03Ah], ax
mov       ax, XTOVIEWANGLE_SEGMENT
mov       bx, word ptr [bp - 04Ch]
mov       es, ax
add       bx, bx
SELFMODIFY_set_viewanglesr3_3:
mov       ax, 01000h
add       ax, word ptr es:[bx]
call      R_ScaleFromGlobalAngle_
mov       word ptr [bp - 032h], ax
mov       word ptr [bp - 030h], dx
mov       es, word ptr ds:[_ds_p+2]
stos      word ptr es:[di]             ; +6
xchg      ax, dx
stos      word ptr es:[di]             ; +8
xchg      ax, dx                       ; put DX back; need it later.
mov       cx, word ptr [bp - 04Eh]
cmp       cx, word ptr [bp - 04Ch]
jg        stop_greater_than_start

; ds_p is es:di
;		ds_p->scale2 = ds_p->scale1;

stos      word ptr es:[di]      ; +0Ah
xchg      ax, dx
stos      word ptr es:[di]      ; +0Ch
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
mov       si, cx
add       si, cx
mov       ax, XTOVIEWANGLE_SEGMENT
mov       es, ax
SELFMODIFY_set_viewanglesr3_2:
mov       ax, 01000h
add       ax, word ptr es:[si]
call      R_ScaleFromGlobalAngle_
mov       es, word ptr ds:[_ds_p+2]
mov       bx, word ptr [bp - 04Eh]
stos      word ptr es:[di]             ; +0Ah
xchg      ax, dx
sub       bx, word ptr [bp - 04Ch]
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





mov       es, word ptr ds:[_ds_p+2]
stos      word ptr es:[di]             ; +0Eh
xchg      ax, dx
stos      word ptr es:[di]             ; +10h
xchg      ax, dx

; rw_scalestep is ready. write it forward as selfmodifying code here

mov       word ptr cs:[SELFMODIFY_get_rwscalestep_lo_1+1], ax
mov       word ptr cs:[SELFMODIFY_get_rwscalestep_lo_2+1], ax
mov       word ptr cs:[SELFMODIFY_get_rwscalestep_lo_3+1], ax
mov       word ptr cs:[SELFMODIFY_get_rwscalestep_lo_4+1], ax
mov       word ptr cs:[SELFMODIFY_get_rwscalestep_hi_1+1], dx
mov       word ptr cs:[SELFMODIFY_get_rwscalestep_hi_2+1], dx
mov       word ptr cs:[SELFMODIFY_get_rwscalestep_hi_3+1], dx
mov       word ptr cs:[SELFMODIFY_get_rwscalestep_hi_4+1], dx


mov       word ptr cs:[SELFMODIFY_add_rwscale_lo+5], ax
mov       word ptr cs:[SELFMODIFY_add_rwscale_hi+5], dx
mov       word ptr cs:[SELFMODIFY_sub_rwscale_lo+3], ax
mov       word ptr cs:[SELFMODIFY_sub_rwscale_hi+3], dx



SELFMODIFY_detailshift_32_bit_rotate_jump_1:
shl   ax, 1
rcl   dx, 1
shift_rw_scale_once:
shl   ax, 1
rcl   dx, 1
finished_shifting_rw_scale:

mov       word ptr cs:[SELFMODIFY_add_to_rwscale_lo_1+3], ax
mov       word ptr cs:[SELFMODIFY_add_to_rwscale_lo_2+3], ax
mov       word ptr cs:[SELFMODIFY_add_to_rwscale_hi_1+3], dx
mov       word ptr cs:[SELFMODIFY_add_to_rwscale_hi_2+3], dx




scales_set:


; si = frontsector
les       si, dword ptr ds:[_frontsector]
lods      word ptr es:[si]
mov       word ptr [bp - 010h], ax
xchg      ax, bx
lods      word ptr es:[si]
mov       word ptr [bp - 012h], ax
xchg      ax, cx
lods      word ptr es:[si]
mov       byte ptr [bp - 3], al
mov       byte ptr [bp - 5], ah
; BIG TODO: make this di used some other way
; (di:si is worldtop)

;	SET_FIXED_UNION_FROM_SHORT_HEIGHT(worldtop, frontsectorceilingheight);
;	worldtop.w -= viewz.w;

mov       al, byte ptr es:[si + 08h]  ; + 6 from lodsw/lodsb = 0eh
mov       byte ptr [bp - 1], al
xchg      ax, cx  ; ax has frontsectorceilingheight

xor       dx, dx
sar       ax, 1
rcr       dx, 1
sar       ax, 1
rcr       dx, 1
sar       ax, 1
rcr       dx, 1

; todo selfmodify viewz

SELFMODIFY_BSP_viewz_lo_7:
sub       dx, 01000h
SELFMODIFY_BSP_viewz_hi_7:
sbb       ax, 01000h
; storeworldtop
mov       word ptr [bp - 046h], dx
mov       word ptr [bp - 044h], ax

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
mov       word ptr [bp - 036h], cx
mov       word ptr [bp - 034h], ax
xor       ax, ax
; zero out maskedtexture 
mov       byte ptr ds:[_maskedtexture], al
; default to 0
mov       byte ptr cs:[SELFMODIFY_check_for_any_tex+1], al

les       bx, dword ptr ds:[_ds_p]
mov       word ptr es:[bx + 01ah], NULL_TEX_COL
cmp       word ptr ds:[_backsector], SECNUM_NULL
je        handle_single_sided_line
jmp       handle_two_sided_line

handle_single_sided_line:


SELFMODIFY_BSP_drawtype_1:
SELFMODIFY_BSP_drawtype_1_AFTER = SELFMODIFY_BSP_drawtype_1 + 2
mov       ax, ((SELFMODIFY_BSP_midtextureonly_skip_pixhighlow_1_TARGET - SELFMODIFY_BSP_midtextureonly_skip_pixhighlow_1_AFTER) SHL 8) + 0EBh
mov       word ptr cs:[SELFMODIFY_BSP_midtextureonly_skip_pixhighlow_1], ax
mov       ah, SELFMODIFY_BSP_midtextureonly_skip_pixhighlow_2_TARGET - SELFMODIFY_BSP_midtextureonly_skip_pixhighlow_2_AFTER
mov       word ptr cs:[SELFMODIFY_BSP_midtextureonly_skip_pixhighlow_2], ax
mov       ah, SELFMODIFY_BSP_midtextureonly_skip_pixhighlow_3_TARGET - SELFMODIFY_BSP_midtextureonly_skip_pixhighlow_3_AFTER
mov       word ptr cs:[SELFMODIFY_BSP_midtextureonly_skip_pixhighlow_3], ax
mov       ah, SELFMODIFY_BSP_midtextureonly_skip_pixhighlow_5_TARGET - SELFMODIFY_BSP_midtextureonly_skip_pixhighlow_5_AFTER
mov       word ptr cs:[SELFMODIFY_BSP_midtextureonly_skip_pixhighlow_5], ax

;mov       ax, ((SELFMODIFY_BSP_midtextureonly_skip_pixhighlow_4_TARGET - SELFMODIFY_BSP_midtextureonly_skip_pixhighlow_4_AFTER) SHL 8) + 0E2h  ; LOOP instruction
;mov       word ptr cs:[SELFMODIFY_BSP_midtextureonly_skip_pixhighlow_4], ax


 
mov       word ptr cs:[SELFMODIFY_BSP_drawtype_2], 089B8h   ; mov ax, xx89
mov       word ptr cs:[SELFMODIFY_BSP_drawtype_1], ((SELFMODIFY_BSP_drawtype_1_TARGET - SELFMODIFY_BSP_drawtype_1_AFTER) SHL 8) + 0EBh

mov       byte ptr cs:[SELFMODIFY_BSP_midtexture_return_jmp+0], 026h    ; es:
mov       word ptr cs:[SELFMODIFY_BSP_midtexture_return_jmp+1], 087C7h  ; next 2 bytes of following instr (mov   word ptr es:[bx + OFFSET_CEILINGCLIP], 01000h)

mov       byte ptr cs:[SELFMODIFY_BSP_midtexture], 039h     ; cmp di,
mov       word ptr cs:[SELFMODIFY_BSP_midtexture+1], 07CF7h   ; (cmp di,) si, jl


SELFMODIFY_BSP_drawtype_1_TARGET:

;es:bx still side
mov       ax, TEXTURETRANSLATION_SEGMENT
mov       bx, [bp - 01Ch]
mov       es, ax
add       bx, bx
mov       ax, word ptr es:[bx]

; write the high byte of the word.
; prev two bytes will be a jump or mov cx with the low byte



mov       word ptr cs:[SELFMODIFY_BSP_set_midtexture+1], ax
; are any bits set?
or        al, ah
or        byte ptr cs:[SELFMODIFY_check_for_any_tex+1], al



mov       ax, 0101h
mov       word ptr [bp - 04Ah], ax ; set markfloor and markceiling
test      byte ptr [bp - 048h], ML_DONTPEGBOTTOM
jne       do_peg_bottom
dont_peg_bottom:
mov       ax, word ptr [bp - 046h]
mov       word ptr cs:[SELFMODIFY_set_midtexturemid_lo+1], ax
mov       ax, word ptr [bp - 044h]
; ax has rw_midtexturemid+2
jmp       done_with_bottom_peg



do_peg_bottom:
mov       ax, word ptr [bp - 010h]
SELFMODIFY_BSP_viewz_shortheight_5:
sub       ax, 01000h
xor       cx, cx
sar       ax, 1
rcr       cx, 1
sar       ax, 1
rcr       cx, 1
sar       ax, 1
rcr       cx, 1
mov       word ptr cs:[SELFMODIFY_set_midtexturemid_lo+1], cx


mov       bx, word ptr [bp - 01Ch]
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

mov       word ptr cs:[SELFMODIFY_set_midtexturemid_hi+1], ax


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
mov       ax, word ptr [bp - 0Eh]
cmp       ax, FINE_ANG180_NOSHIFT
jbe       offsetangle_greater_than_fineang180
neg       ax
and       ah, MOD_FINE_ANGLE_NOSHIFT_HIGHBITS
mov       word ptr [bp - 0Eh], ax
offsetangle_greater_than_fineang180:
mov       ax, word ptr [bp - 01ah]
or        ax, word ptr [bp - 018h]
jne       hyp_already_set   		; todo what is hyp about
mov       dx, word ptr [bp - 03Eh]
mov       ax, word ptr [bp - 03Ch]
call      R_PointToDist_
mov       word ptr [bp - 018h], ax
mov       word ptr [bp - 01ah], dx
hyp_already_set:
mov       dx, word ptr [bp - 0Eh]
cmp       dx, FINE_ANG90_NOSHIFT
ja        offsetangle_greater_than_fineang90
mov       bx, word ptr [bp - 018h]
mov       cx, word ptr [bp - 01ah]
mov       ax, FINESINE_SEGMENT
call FixedMulTrigNoShiftBSPLocal_
; used later, dont change?
; dx:ax is rw_offset
jmp       done_with_offsetangle_stuff
offsetangle_greater_than_fineang90:
mov       ax, word ptr [bp - 018h]
mov       dx, word ptr [bp - 01ah]



done_with_offsetangle_stuff:
; dx:ax is rw_offset

xor       cx, cx
SELFMODIFY_set_rw_normal_angle_shift3:

mov       bx, 01000h
sub       cx, word ptr ds:[_rw_angle1]
sbb       bx, word ptr ds:[_rw_angle1 + 2]
; ANG180_HIGHBITS is 08000h. can we get this for free without cmp with a sign thing?
cmp       bx, ANG180_HIGHBITS
jae       tempangle_not_smaller_than_fineang180
; bx is already _rw_offset
neg       dx
neg       ax
sbb       dx, 0
tempangle_not_smaller_than_fineang180:




mov       bx, word ptr ds:[_curseg_render]
SELFMODIFY_BSP_sidetextureoffset:
mov       cx, 01000h
add       cx, word ptr [bx + 4]
add       ax, cx
; rw_offset ready to be written to rendersegloop:
mov   word ptr cs:[SELFMODIFY_set_cx_rw_offset_lo+1], ax
mov   word ptr cs:[SELFMODIFY_set_ax_rw_offset_hi+1], dx

SELFMODIFY_set_viewanglesr3_1:
mov       ax, 01000h
add       ah, 8
SELFMODIFY_sub_rw_normal_angle_2:
sub       ax, 01000h
and       ah, FINE_ANGLE_HIGH_BYTE

; set centerangle in rendersegloop
mov       word ptr cs:[SELFMODIFY_set_rw_center_angle+1], ax


SELFMODIFY_BSP_fixedcolormap_3:
jne       seg_textured_check_done    ; dont check walllights if fixedcolormap
SELFMODIFY_BSP_fixedcolormap_3_AFTER:
mov       al, byte ptr [bp - 1]
xor       ah, ah
SELFMODIFY_set_extralight_2:
mov       dl, 0
IF COMPILE_INSTRUCTIONSET GE COMPILE_186
sar       ax, 4
ELSE
sar       ax, 1
sar       ax, 1
sar       ax, 1
sar       ax, 1
ENDIF
xor       dh, dh
add       dx, ax
mov       ax, word ptr [bp - 03Eh]
SELFMODIFY_BSP_v2y:
cmp       ax, 01000h
je        v1y_equals_v2y

mov       ax, word ptr [bp - 03Ch]
SELFMODIFY_BSP_v2x:
cmp       ax, 01000h
jne       v1x_equals_v2x

inc       dx
jmp       v1x_equals_v2x
v1y_equals_v2y:
dec       dx
v1x_equals_v2x:
test      dx, dx
jge       lightnum_greater_than_0
xor		  ax, ax
jmp       done_setting_ax_to_wallights
lightnum_less_than_lightlevels:
mov       bx, dx
add       bx, dx
mov       ax, word ptr ds:[bx + _lightmult48lookup]
jmp       done_setting_ax_to_wallights

lightnum_greater_than_0:
cmp       dx, LIGHTLEVELS
jl        lightnum_less_than_lightlevels
mov       ax, word ptr ds:[_lightmult48lookup + + (2 * (LIGHTLEVELS - 1))]
done_setting_ax_to_wallights:
add       ax, _scalelightfixed + SCALE_LIGHT_OFFSET_IN_FIXED_SCALELIGHT


; write walllights to rendersegloop
mov   word ptr cs:[SELFMODIFY_add_wallights+2], ax
; ? do math here and write this ahead to drawcolumn colormapsindex?

SELFMODIFY_BSP_fixedcolormap_3_TARGET:
seg_textured_check_done:
mov       ax, word ptr [bp - 010h]
SELFMODIFY_BSP_viewz_shortheight_4:
cmp       ax, 01000h
jl        not_above_viewplane
mov       byte ptr [bp - 04Ah], 0
not_above_viewplane:
mov       ax, word ptr [bp - 012h]
SELFMODIFY_BSP_viewz_shortheight_3:
cmp       ax, 01000h
jg        not_below_viewplane
mov       al, byte ptr [bp - 5]
cmp       al, byte ptr ds:[_skyflatnum]
je        not_below_viewplane
mov       byte ptr [bp - 049h], 0  ;markceiling
not_below_viewplane:
mov       cx, 4
mov       dx, word ptr [bp - 044h]
mov       ax, word ptr [bp - 046h]
loop_shift_worldtop:
sar       dx, 1
rcr       ax, 1
loop      loop_shift_worldtop
mov       word ptr [bp - 044h], dx
mov       word ptr [bp - 046h], ax

; les to load two words
les       bx, dword ptr [bp - 032h]
mov       cx, es
call FixedMulBSPLocal_
; todo selfmodify this.
SELFMODIFY_sub__centeryfrac_shiftright4_lo_4:
mov       cx, 01000h
sub       cx, ax
SELFMODIFY_sub__centeryfrac_shiftright4_hi_4:
mov       ax, 01000h
sbb       ax, dx
mov       word ptr [bp - 02Eh], cx
mov       word ptr [bp - 02Ch], ax
; les to load two words
mov       cx, 4
mov       dx, word ptr [bp - 034h]
mov       ax, word ptr [bp - 036h]
loop_shift_worldbot:
sar       dx, 1
rcr       ax, 1
loop      loop_shift_worldbot
mov       word ptr [bp - 034h], dx
mov       word ptr [bp - 036h], ax



les       bx, dword ptr [bp - 032h]
mov       cx, es
call FixedMulBSPLocal_

SELFMODIFY_sub__centeryfrac_shiftright4_lo_3:
mov       cx, 01000h
sub       cx, ax
SELFMODIFY_sub__centeryfrac_shiftright4_hi_3:
mov       ax, 01000h
sbb       ax, dx
mov       word ptr [bp - 02Ah], cx
mov       word ptr [bp - 028h], ax

cmp       byte ptr [bp - 049h], 0  ;markceiling
je        dont_mark_ceiling
mov       cx, 1
SELFMODIFY_set_ceilingplaneindex:
mov       ax, 0FFFFh
mov       bx, word ptr [bp - 03Ah]
dec       bx
mov       dx, word ptr [bp - 038h]    ; rw_x
call      R_CheckPlane_
mov       word ptr cs:[SELFMODIFY_set_ceilingplaneindex+1], ax
dont_mark_ceiling:

cmp       byte ptr ds:[bp - 04Ah], 0 ; markfloor
je        dont_mark_floor
xor       cx, cx
SELFMODIFY_set_floorplaneindex:
mov       ax, 0FFFFh
mov       bx, word ptr [bp - 03Ah]
dec       bx
mov       dx, word ptr [bp - 038h]   ; rw_x
call      R_CheckPlane_
mov       word ptr cs:[SELFMODIFY_set_floorplaneindex+1], ax
dont_mark_floor:
mov       ax, word ptr [bp - 04Eh]
cmp       ax, word ptr [bp - 04Ch]
jge       at_least_one_column_to_draw
jmp       check_spr_top_clip
at_least_one_column_to_draw:

SELFMODIFY_get_rwscalestep_lo_1:
mov       ax, 01000h
SELFMODIFY_get_rwscalestep_hi_1:
mov       dx, 01000h
les       bx, dword ptr [bp - 046h]
mov       cx, es
call FixedMulBSPLocal_
neg       dx
neg       ax
sbb       dx, 0

; dx:ax are topstep

mov       word ptr cs:[SELFMODIFY_sub_topstep_lo+3], ax
mov       word ptr cs:[SELFMODIFY_sub_topstep_hi+3], dx
mov       word ptr cs:[SELFMODIFY_add_topstep_lo+5], ax
mov       word ptr cs:[SELFMODIFY_add_topstep_hi+5], dx


SELFMODIFY_detailshift_32_bit_rotate_jump_2:
shl       ax, 1
rcl       dx, 1
shift_topstep_once:
shl       ax, 1
rcl       dx, 1

finished_shifting_topstep:


mov       word ptr cs:[SELFMODIFY_add_to_topfrac_lo_1+3], ax
mov       word ptr cs:[SELFMODIFY_add_to_topfrac_lo_2+3], ax
mov       word ptr cs:[SELFMODIFY_add_to_topfrac_hi_1+3], dx
mov       word ptr cs:[SELFMODIFY_add_to_topfrac_hi_2+3], dx


mov       cx, word ptr [bp - 034h]
mov       bx, word ptr [bp - 036h]
SELFMODIFY_get_rwscalestep_lo_2:
mov       ax, 01000h
SELFMODIFY_get_rwscalestep_hi_2:
mov       dx, 01000h
call FixedMulBSPLocal_
neg       dx
neg       ax
sbb       dx, 0

; dx:ax are bottomstep

mov       word ptr cs:[SELFMODIFY_sub_botstep_lo+3], ax
mov       word ptr cs:[SELFMODIFY_sub_botstep_hi+3], dx
mov       word ptr cs:[SELFMODIFY_add_botstep_lo+5], ax
mov       word ptr cs:[SELFMODIFY_add_botstep_hi+5], dx

SELFMODIFY_detailshift_32_bit_rotate_jump_3:
shl       ax, 1
rcl       dx, 1
shift_botstep_once:
shl       ax, 1
rcl       dx, 1

finished_shifting_botstep:

mov       word ptr cs:[SELFMODIFY_add_to_bottomfrac_lo_1+3], ax
mov       word ptr cs:[SELFMODIFY_add_to_bottomfrac_lo_2+3], ax
mov       word ptr cs:[SELFMODIFY_add_to_bottomfrac_hi_1+3], dx
mov       word ptr cs:[SELFMODIFY_add_to_bottomfrac_hi_2+3], dx




cmp       word ptr ds:[_backsector], SECNUM_NULL
jne       backsector_not_null
jmp       skip_pixlow_step
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

cmp       word ptr [bp - 044h], di
jg        do_pixhigh_step
jne       skip_pixhigh_step
cmp       word ptr [bp - 046h], si

jbe       skip_pixhigh_step
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
call FixedMulBSPLocal_

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
call FixedMulBSPLocal_
neg       dx
neg       ax
sbb       dx, 0


; dx:ax is pixhighstep.
; self modifying code to write to pixlowstep usages.


mov       word ptr cs:[SELFMODIFY_sub_pixhigh_lo+3], ax
mov       word ptr cs:[SELFMODIFY_sub_pixhigh_hi+3], dx
mov       word ptr cs:[SELFMODIFY_add_pixhighstep_lo+5], ax
mov       word ptr cs:[SELFMODIFY_add_pixhighstep_hi+5], dx

SELFMODIFY_detailshift_32_bit_rotate_jump_4:
shl       ax, 1
rcl       dx, 1
shift_pixhighstep_once:
shl       ax, 1
rcl       dx, 1
done_shifting_pixhighstep:
mov       word ptr cs:[SELFMODIFY_add_to_pixhigh_lo_1+3], ax
mov       word ptr cs:[SELFMODIFY_add_to_pixhigh_lo_2+3], ax
mov       word ptr cs:[SELFMODIFY_add_to_pixhigh_hi_1+3], dx
mov       word ptr cs:[SELFMODIFY_add_to_pixhigh_hi_2+3], dx


; put these back where they need to be.
xchg      dx, di
xchg      ax, si
skip_pixhigh_step:

; dx:ax are now worldlow

; if (worldlow.w > worldbottom.w) {

cmp       dx, word ptr [bp - 034h]
jg        do_pixlow_step
jne       skip_pixlow_step
cmp       ax, word ptr [bp - 036h]
jbe       skip_pixlow_step
do_pixlow_step:

; pixlow = (centeryfrac_shiftright4.w) - FixedMul (worldlow.w, rw_scale.w);
; pixlowstep = -FixedMul    (rw_scalestep.w,          worldlow.w);


mov       di, dx	; store for later
mov       si, ax	; store for later
les       bx, dword ptr [bp - 032h]
mov       cx, es
call FixedMulBSPLocal_

SELFMODIFY_sub__centeryfrac_shiftright4_lo_1:
mov       cx, 01000h
sub       cx, ax
SELFMODIFY_sub__centeryfrac_shiftright4_hi_1:
mov       ax, 01000h
sbb       ax, dx


mov       word ptr [bp - 026h], cx
mov       word ptr [bp - 024h], ax
mov       bx, si	; cached values
mov       cx, di	; cached values
SELFMODIFY_get_rwscalestep_lo_4:
mov       ax, 01000h
SELFMODIFY_get_rwscalestep_hi_4:
mov       dx, 01000h
call FixedMulBSPLocal_
neg       dx
neg       ax
sbb       dx, 0

; dx:ax is pixlowstep.
; self modifying code to write to pixlowstep usages.


mov       word ptr cs:[SELFMODIFY_sub_pixlow_lo+3], ax
mov       word ptr cs:[SELFMODIFY_sub_pixlow_hi+3], dx
mov       word ptr cs:[SELFMODIFY_add_pixlowstep_lo+5], ax
mov       word ptr cs:[SELFMODIFY_add_pixlowstep_hi+5], dx

SELFMODIFY_detailshift_32_bit_rotate_jump_5:
shl       ax, 1
rcl       dx, 1
shift_pixlowstep_once:
shl       ax, 1
rcl       dx, 1
done_shifting_pixlowstep:
mov       word ptr cs:[SELFMODIFY_add_to_pixlow_lo_1+3], ax
mov       word ptr cs:[SELFMODIFY_add_to_pixlow_lo_2+3], ax
mov       word ptr cs:[SELFMODIFY_add_to_pixlow_hi_1+3], dx
mov       word ptr cs:[SELFMODIFY_add_to_pixlow_hi_2+3], dx



skip_pixlow_step:
call      R_RenderSegLoop_

; clean up the self modified code of renderseg loop. 
mov   word ptr cs:[SELFMODIFY_BSP_set_seglooptexrepeat0], ((SELFMODIFY_BSP_set_seglooptexrepeat0_TARGET - SELFMODIFY_BSP_set_seglooptexrepeat0_AFTER) SHL 8) + 0EBh
mov   word ptr cs:[SELFMODIFY_BSP_set_seglooptexrepeat1], ((SELFMODIFY_BSP_set_seglooptexrepeat1_TARGET - SELFMODIFY_BSP_set_seglooptexrepeat1_AFTER) SHL 8) + 0EBh


check_spr_top_clip:
les       bx, dword ptr ds:[_ds_p]
test      byte ptr es:[bx + 01ch], SIL_TOP
jne       continue_checking_spr_top_clip
cmp       byte ptr ds:[_maskedtexture], 0
je        check_spr_bottom_clip
jmp       continue_checking_spr_top_clip


continue_checking_spr_top_clip:

cmp       word ptr es:[bx + 016h], 0
jne       check_spr_bottom_clip
mov       si, word ptr [bp - 04Ch]
add       si, si
add       si, OFFSET_CEILINGCLIP
mov       di, word ptr ds:[_lastopening]
mov       cx, word ptr [bp - 03Ah]
sub       cx, word ptr [bp - 04Ch]
mov       ax, OPENINGS_SEGMENT
mov       es, ax
mov       ds, ax
add       di, di

rep movsw

mov       ax, ss
mov       ds, ax
mov       ax, word ptr ds:[_lastopening]
sub       ax, word ptr [bp - 04Ch]
mov       es, word ptr ds:[_ds_p+2]   ; bx is ds_p offset above
add       ax, ax
mov       word ptr es:[bx + 016h], ax
mov       ax, word ptr [bp - 03Ah]
sub       ax, word ptr [bp - 04Ch]
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
mov       si, word ptr [bp - 04Ch]
add       si, si
add       si, OFFSET_FLOORCLIP
mov       ax, OPENINGS_SEGMENT
mov       di, word ptr ds:[_lastopening]
add       di, di
mov       cx, word ptr [bp - 03Ah]
sub       cx, word ptr [bp - 04Ch]
mov       es, ax
mov       ds, ax
rep movsw 

mov       ax, ss
mov       ds, ax

mov       ax, word ptr ds:[_lastopening]
sub       ax, word ptr [bp - 04Ch]
mov       es, word ptr ds:[_ds_p+2]   ; bx is ds_p offset above
add       ax, ax
mov       word ptr es:[bx + 018h], ax
mov       ax, word ptr [bp - 03Ah]
sub       ax, word ptr [bp - 04Ch]
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


; nop 

SELFMODIFY_BSP_drawtype_2:
SELFMODIFY_BSP_drawtype_2_AFTER = SELFMODIFY_BSP_drawtype_2+2

mov       ax, 0c089h 
mov       word ptr cs:[SELFMODIFY_BSP_midtextureonly_skip_pixhighlow_1], ax
mov       word ptr cs:[SELFMODIFY_BSP_midtextureonly_skip_pixhighlow_2], ax
mov       word ptr cs:[SELFMODIFY_BSP_midtextureonly_skip_pixhighlow_3], ax
;mov       word ptr cs:[SELFMODIFY_BSP_midtextureonly_skip_pixhighlow_4], ax
mov       word ptr cs:[SELFMODIFY_BSP_midtextureonly_skip_pixhighlow_5], ax


mov       word ptr cs:[SELFMODIFY_BSP_drawtype_1], 0EBB8h   ; mov ax, xxeB
mov       word ptr cs:[SELFMODIFY_BSP_drawtype_2], ((SELFMODIFY_BSP_drawtype_2_TARGET - SELFMODIFY_BSP_drawtype_2_AFTER) SHL 8) + 0EBh

mov       word ptr cs:[SELFMODIFY_BSP_midtexture], 0E9h
mov       word ptr cs:[SELFMODIFY_BSP_midtexture+1], (SELFMODIFY_BSP_midtexture_TARGET - SELFMODIFY_BSP_midtexture_AFTER) 

mov       byte ptr cs:[SELFMODIFY_BSP_midtexture_return_jmp+0], 0E9h ; jmp short rel16
mov       word ptr cs:[SELFMODIFY_BSP_midtexture_return_jmp+1], SELFMODIFY_BSP_midtexture_return_jmp_TARGET - SELFMODIFY_BSP_midtexture_return_jmp_AFTER


SELFMODIFY_BSP_drawtype_2_TARGET:
; nomidtexture. this will be checked before top/bot, have to set it to 0.



; short_height_t backsectorfloorheight = backsector->floorheight;
; short_height_t backsectorceilingheight = backsector->ceilingheight;
; uint8_t backsectorceilingpic = backsector->ceilingpic;
; uint8_t backsectorfloorpic = backsector->floorpic;
; uint8_t backsectorlightlevel = backsector->lightlevel;

les       si, dword ptr ds:[_backsector]
lods      word ptr es:[si]
mov       word ptr [bp - 040h], ax
xchg      ax, cx
lods      word ptr es:[si]
mov       word ptr [bp - 042h], ax
xchg      ax, bx   ; store for later
lods      word ptr es:[si]
mov       byte ptr [bp - 4], al
mov       byte ptr [bp - 6], ah
mov       al, byte ptr es:[si + 08h]  ; 0eh with the 6 from lodsw.
mov       byte ptr [bp - 2], al
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

cmp       ax, word ptr [bp - 010h]
jl        set_bsilheight_to_frontsectorfloorheight
SELFMODIFY_BSP_viewz_shortheight_2:
cmp       ax, 01000h
jle       bsilheight_set
set_bsilheight_to_maxshort:
mov       byte ptr es:[si + 01ch], SIL_BOTTOM
mov       word ptr es:[si + 012h], MAXSHORT
jmp       bsilheight_set
set_bsilheight_to_frontsectorfloorheight:
mov       byte ptr es:[si + 01ch], SIL_BOTTOM
mov       cx, word ptr [bp - 010h]
mov       word ptr es:[si + 012h], cx
bsilheight_set:

xchg      ax, bx   ; retrieved from before
cmp       ax, word ptr [bp - 012h]
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
mov       cx, word ptr [bp - 012h]
mov       word ptr es:[si + 014h], cx
tsilheight_set:
; es:si is still ds_p

; if (backsectorceilingheight <= frontsectorfloorheight) {

cmp       ax, word ptr [bp - 010h]
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
mov       ax, word ptr [bp - 040h]
cmp       ax, word ptr [bp - 012h]
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
; TODO! viewz as constants in the function.

mov       di, word ptr [bp - 042h]
xor       si, si
sar       di, 1
rcr       si, 1
sar       di, 1
rcr       si, 1
sar       di, 1
rcr       si, 1
SELFMODIFY_BSP_viewz_lo_3:
sub       si, 01000h
SELFMODIFY_BSP_viewz_hi_3:
sbb       di, 01000h

;di:si will store worldhigh
; what if we store bx/cx here as well, and finally push it once it's too onerous to hold onto?
mov       cx, word ptr [bp - 040h] ; can be ax?
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

mov       al, byte ptr ds:[_skyflatnum]
cmp       al, byte ptr [bp - 5]
jne       not_a_skyflat
cmp       al, byte ptr [bp - 6]
jne       not_a_skyflat
;di/si are worldhigh..

mov       word ptr [bp - 046h], si
mov       word ptr [bp - 044h], di

not_a_skyflat:

			
;	if (worldlow.w != worldbottom .w || backsectorfloorpic != frontsectorfloorpic || backsectorlightlevel != frontsectorlightlevel) {
;		markfloor = true;
;	} else {
;		// same plane on both sides
;		markfloor = false;
;	}

cmp       cx, word ptr [bp - 034h]
jne       set_markfloor_true
cmp       bx, word ptr [bp - 036h]
jne       set_markfloor_true
; todo: use words
mov       ax, word ptr [bp - 4]
cmp       al, ah
jne       set_markfloor_true
mov       ax, word ptr [bp - 2]
cmp       al, ah
jne       set_markfloor_true
set_markfloor_false:
mov       byte ptr [bp - 04Ah], 0  ; markfloor
jmp       markfloor_set
set_markfloor_true:
mov       byte ptr [bp - 04Ah], 1  ; markfloor
markfloor_set:
; di/si are already worldhigh..
cmp       word ptr [bp - 044h], di
jne       set_markceiling_true
cmp       word ptr [bp - 046h], si
jne       set_markceiling_true

mov       ax, word ptr [bp - 6]
cmp       al, ah
jne       set_markceiling_true

mov       ax, word ptr [bp - 2]
cmp       al, ah
jne       set_markceiling_true
set_markceiling_false:
mov       byte ptr [bp - 049h], 0   ;markceiling
jmp       markceiling_set
set_markceiling_true:
mov       byte ptr [bp - 049h], 1   ;markceiling
markceiling_set:

; TOOO: improve this area. write to markceiling/floor once not twice. use al/ah to store their values.
; write one word at the end. or write directly to the code.

;		if (backsectorceilingheight <= frontsectorfloorheight
;			|| backsectorfloorheight >= frontsectorceilingheight) {
;			// closed door
;			markceiling = markfloor = true;
;		}

mov       dx, word ptr [bp - 042h]
cmp       dx, word ptr [bp - 010h]
jle       closed_door_detected
mov       ax, word ptr [bp - 040h]
cmp       ax, word ptr [bp - 012h]
jl        not_closed_door 
closed_door_detected:
mov       ax, 0101h
mov       word ptr [bp - 04Ah], ax  ; markfloor, ceiling
not_closed_door:
; ax free at last!
;		if (worldhigh.w < worldtop.w) {

; store worldhigh on stack..
push      di
push      si
xchg      di, cx
xchg      si, bx

; worldhigh check one past time
cmp       word ptr [bp - 044h], cx
jg        setup_toptexture
jne       toptexture_zero
cmp       word ptr [bp - 046h], bx
jbe       toptexture_zero
setup_toptexture:

;cx and bx (currently worldhigh) are clobbered but are on stack

; toptexture = texturetranslation[side->toptexture];

mov       ax, TEXTURETRANSLATION_SEGMENT
mov       bx, word ptr [bp - 014h]
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
toptexture_not_zero:
mov       word ptr cs:[SELFMODIFY_BSP_toptexture], 0468Bh ; mov   ax, word ptr [bp - 02Dh] first two bytes
; are any bits set?
or        bl, bh
or        byte ptr cs:[SELFMODIFY_check_for_any_tex+1], bl


test      byte ptr [bp - 048h], ML_DONTPEGTOP
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
mov       cx, TEXTUREHEIGHTS_SEGMENT
mov       bx, word ptr [bp - 014h]
mov       es, cx
xor       cx, cx
mov       cl, byte ptr es:[bx]
inc       cx

add       dx, cx
SELFMODIFY_BSP_viewz_lo_1:
sub       ax, 01000h
SELFMODIFY_BSP_viewz_hi_1:
sbb       dx, 01000h

jmp       do_selfmodify_toptexture

set_toptexture_to_worldtop:
mov       ax, word ptr [bp - 046h]
mov       dx, word ptr [bp - 044h]
do_selfmodify_toptexture:
; set _rw_toptexturemid in rendersegloop

mov   word ptr cs:[SELFMODIFY_set_toptexturemid_lo+1], ax
mov   word ptr cs:[SELFMODIFY_set_toptexturemid_hi+1], dx


toptexture_stuff_done:



cmp       di, word ptr [bp - 034h]
jg        setup_bottexture
jne       bottexture_zero
cmp       si, word ptr [bp - 036h]
jbe       bottexture_zero
setup_bottexture:
mov       ax, TEXTURETRANSLATION_SEGMENT
mov       bx, word ptr [bp - 016h]
mov       es, ax
add       bx, bx
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



test      byte ptr [bp - 048h], ML_DONTPEGBOTTOM
je        calculate_bottexturemid
; todo cs write here
mov       ax, word ptr [bp - 046h]
mov       dx, word ptr [bp - 044h]
do_selfmodify_bottexture:

; set _rw_toptexturemid in rendersegloop

mov   word ptr cs:[SELFMODIFY_set_bottexturemid_lo+1], ax
mov   word ptr cs:[SELFMODIFY_set_bottexturemid_hi+1], dx


bottexture_stuff_done:
SELFMODIFY_BSP_siderenderrowoffset_2:
mov       ax, 01000h

;   extraselfmodify? or hold in vars till this pt and finally write the high bits
; 	rw_toptexturemid.h.intbits += side_render->rowoffset;
;	rw_bottomtexturemid.h.intbits += side_render->rowoffset;


add       word ptr cs:[SELFMODIFY_set_toptexturemid_hi+1], ax
add       word ptr cs:[SELFMODIFY_set_bottexturemid_hi+1], ax
cmp       word ptr [bp - 01Ch], 0

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
sub       ax, word ptr [bp - 038h]    ; rw_x
les       bx, dword ptr ds:[_ds_p]
mov       word ptr es:[bx + 01ah], ax
mov       ax, word ptr es:[bx + 01ah]
add       ax, ax
mov       word ptr ds:[_maskedtexturecol], ax
mov       ax, word ptr [bp - 03Ah]
sub       ax, word ptr [bp - 038h]    ; rw_x
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


push  bx
push  cx
push  si
push  di

mov   cx, ax                  ; backup first in cx for most of the function.
mov   di, dx
dec   ax
mov   si, OFFSET _solidsegs
cmp   ax, word ptr [si+2]

;  while (start->last < first-1)
;  	start++;

jle   found_start_solid
increment_start:
add   si, 4
cmp   ax, word ptr [si + 2]
jg    increment_start
found_start_solid:
mov   ax, cx
cmp   ax, word ptr [si]

;    if (first < start->first)

jge   first_greater_than_startfirst ;		if (last < start->first-1) {
mov   dx, word ptr [si]
dec   dx
cmp   di, dx
jl    last_smaller_than_startfirst;
call  R_StoreWallRange_             ;		R_StoreWallRange (first, start->first - 1);
mov   ax, cx                        ;		start->first = first;	
mov   word ptr [si], ax
first_greater_than_startfirst:
;	if (last <= start->last) {

cmp   di, word ptr [si + 2]
jle   write_back_newend_and_return
;    next = start;
mov   bx, si                        ; si is start, bx is next
;    while (last >= (next+1)->first-1) {
check_between_posts:
mov   dx, word ptr [bx + 4]
dec   dx
cmp   di, dx
jl    do_final_fragment
mov   ax, word ptr [bx + 2]
inc   ax
;		// There is a fragment between two posts.
;		R_StoreWallRange (next->last + 1, (next+1)->first - 1);
call  R_StoreWallRange_
mov   ax, word ptr [bx + 6]
add   bx, 4
cmp   di, ax
jg    check_between_posts
mov   word ptr [si + 2], ax
crunch:
;    if (next == start) {
cmp   bx, si
je    write_back_newend_and_return
;    while (next++ != newend) {

mov   cx, word ptr [_newend] ; cache old newend

check_to_remove_posts:
mov   ax, bx
lea   di, [si + 4]
add   bx, 4
cmp   ax, cx
je    done_removing_posts
mov   ax, word ptr [bx]
mov   dx, word ptr [bx + 2]
mov   word ptr [di], ax
mov   si, di
mov   word ptr [di + 2], dx
jmp   check_to_remove_posts
last_smaller_than_startfirst:
mov   dx, di
;// Post is entirely visible (above start),  so insert a new clippost.
call  R_StoreWallRange_          ; 			R_StoreWallRange (first, last);
mov   ax, cx                     ;        backup first
mov   cx, word ptr [_newend]     
add   cx, 8
mov   word ptr [_newend], cx

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

mov   word ptr [bx + 2], dx
mov   word ptr [bx], ax
write_back_newend_and_return:

pop   di
pop   si
pop   cx
pop   bx
ret   

do_final_fragment:
;    // There is a fragment after *next.
mov   ax, word ptr [bx + 2]
mov   dx, di
inc   ax
call  R_StoreWallRange_
mov   word ptr [si + 2], di
jmp   crunch

done_removing_posts:
    
mov   word ptr [_newend], di   ; newend = start+1;

pop   di
pop   si
pop   cx
pop   bx
ret   

ENDP

;R_ClipPassWallSegment_

PROC R_ClipPassWallSegment_ NEAR
PUBLIC R_ClipPassWallSegment_ 

; input: ax = first (transferred to si)
;        dx = last (transferred to cx)

push bx
push cx
push si
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
cmp  ax, word ptr [bx + 2]
jg   keep_searching_for_start

found_start:
;    if (first < start->first) {

mov  ax, word ptr [bx]  ; ax = start->first
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


cmp  cx, word ptr [bx + 2]
jle  do_clippass_exit
check_next_fragment:
mov  dx, word ptr [bx + 4]
dec  dx
cmp  cx, dx
mov  ax, word ptr [bx + 2]
jl   fragment_after_next
inc  ax
add  bx, 4
;  There is a fragment between two posts.

call R_StoreWallRange_
cmp  cx, word ptr [bx + 2]
jg   check_next_fragment
do_clippass_exit:
pop  si
pop  cx
pop  bx
ret  
post_entirely_visible:
mov  dx, cx
mov  ax, si
call R_StoreWallRange_
pop  si
pop  cx
pop  bx
ret  

fragment_after_next:

mov  dx, cx
inc  ax
call R_StoreWallRange_
pop  si
pop  cx
pop  bx
ret  


ENDP

; TODO: externalize this and R_ExecuteSetViewSize and its children to asm, load from binary
; todo: calculate the values here and dont store to variables.

;R_WriteBackViewConstants_

PROC R_WriteBackViewConstants_ FAR
PUBLIC R_WriteBackViewConstants_ 


; set ds to cs to make code smaller?
mov      ax, cs
mov      ds, ax


ASSUME DS:R_MAINHI_TEXT

mov      ax,  word ptr ss:[_detailshift]
add      ah, OFFSET _quality_port_lookup
mov      byte ptr ds:[SELFMODIFY_detailshift_plus1_1+2], ah

; for 16 bit shifts, modify jump to jump 4 for 0 shifts, 2 for 1 shifts, 0 for 0 shifts.

cmp      al, 1
jb       jump_to_set_to_zero
je       set_to_one
jmp      set_to_two
jump_to_set_to_zero:
jmp      set_to_zero
set_to_two:
; detailshift 2 case. usually involves no shift. in this case - we just jump past the shift code.

; nop 
mov      ax, 0c089h 

mov      word ptr ds:[SELFMODIFY_detailshift_16_bit_jump_1+0], ax
mov      word ptr ds:[SELFMODIFY_detailshift_16_bit_jump_1+2], ax

; write to colfunc segment
mov      word ptr ds:[SELFMODIFY_COLFUNC_detailshift_2_minus_16_bit_shift+0], ax
mov      word ptr ds:[SELFMODIFY_COLFUNC_detailshift_2_minus_16_bit_shift+2], ax



; for 32 bit shifts, modify jump to jump 8 for 0 shifts, 4 for 1 shifts, 0 for 0 shifts.
; 0EBh, 006h = jmp 6

mov      ax, 006EBh
mov      word ptr ds:[SELFMODIFY_detailshift_32_bit_rotate_jump_1], ax
mov      word ptr ds:[SELFMODIFY_detailshift_32_bit_rotate_jump_2], ax
mov      word ptr ds:[SELFMODIFY_detailshift_32_bit_rotate_jump_3], ax
mov      word ptr ds:[SELFMODIFY_detailshift_32_bit_rotate_jump_4], ax
mov      word ptr ds:[SELFMODIFY_detailshift_32_bit_rotate_jump_5], ax


; d1 e0 d1 d7  = shl ax, 1 rcl di, 1
mov      al,  0
mov      word ptr ds:[SELFMODIFY_detailshift_2_minus_32_bit_rotate_jump_1+0], ax
mov      word ptr ds:[SELFMODIFY_detailshift_2_minus_32_bit_rotate_jump_1+2], ax
mov      word ptr ds:[SELFMODIFY_detailshift_2_minus_32_bit_rotate_jump_2+0], ax
mov      word ptr ds:[SELFMODIFY_detailshift_2_minus_32_bit_rotate_jump_2+2], ax

; inverse. do shifts
; d1 e0 d1 d2  = shl ax, 1; rcl dx, 1
; d1 e0 d1 d7  = shl ax, 1; rcl di, 1
mov      ax, 0e0d1h 
mov      word ptr ds:[SELFMODIFY_detailshift_2_minus_32_bit_rotate_jump_1+0], ax
mov      word ptr ds:[SELFMODIFY_detailshift_2_minus_32_bit_rotate_jump_2+0], ax
mov      ax, 0d2d1h 
mov      word ptr ds:[SELFMODIFY_detailshift_2_minus_32_bit_rotate_jump_1+2], ax
mov      ax, 0d7d1h 
mov      word ptr ds:[SELFMODIFY_detailshift_2_minus_32_bit_rotate_jump_2+2], ax



jmp      done_modding_shift_detail_code
set_to_one:

; detailshift 1 case. usually involves one shift pair.
; in this case - we insert nops (nopish?) code to replace the first shift pair

; for 32 bit shifts, modify jump to jump 8 for 0 shifts, 4 for 1 shifts, 0 for 0 shifts.

; d1 f8  = sar ax, 1
mov      ax, 0f8d1h 
mov      word ptr ds:[SELFMODIFY_detailshift_16_bit_jump_1+0], ax

; write to colfunc segment
mov      word ptr ds:[SELFMODIFY_COLFUNC_detailshift_2_minus_16_bit_shift+0], ax

; nop 
mov      ax, 0c089h 
mov      word ptr ds:[SELFMODIFY_detailshift_16_bit_jump_1+2], ax
; write to colfunc segment
mov      word ptr ds:[SELFMODIFY_COLFUNC_detailshift_2_minus_16_bit_shift+2], ax



; 81 c3 00 00 = add bx, 0000. Not technically a nop, but probably better than two mov ax, ax?
; 89 c0       = mov ax, ax. two byte nop.

mov      ax, 0c089h

mov      word ptr ds:[SELFMODIFY_detailshift_32_bit_rotate_jump_1+0], ax
mov      word ptr ds:[SELFMODIFY_detailshift_32_bit_rotate_jump_1+2], ax
mov      word ptr ds:[SELFMODIFY_detailshift_32_bit_rotate_jump_2+0], ax
mov      word ptr ds:[SELFMODIFY_detailshift_32_bit_rotate_jump_2+2], ax
mov      word ptr ds:[SELFMODIFY_detailshift_32_bit_rotate_jump_3+0], ax
mov      word ptr ds:[SELFMODIFY_detailshift_32_bit_rotate_jump_3+2], ax
mov      word ptr ds:[SELFMODIFY_detailshift_32_bit_rotate_jump_4+0], ax
mov      word ptr ds:[SELFMODIFY_detailshift_32_bit_rotate_jump_4+2], ax
mov      word ptr ds:[SELFMODIFY_detailshift_32_bit_rotate_jump_5+0], ax
mov      word ptr ds:[SELFMODIFY_detailshift_32_bit_rotate_jump_5+2], ax

mov      word ptr ds:[SELFMODIFY_detailshift_2_minus_32_bit_rotate_jump_1+0], ax
mov      word ptr ds:[SELFMODIFY_detailshift_2_minus_32_bit_rotate_jump_1+2], ax
mov      word ptr ds:[SELFMODIFY_detailshift_2_minus_32_bit_rotate_jump_2+0], ax
mov      word ptr ds:[SELFMODIFY_detailshift_2_minus_32_bit_rotate_jump_2+2], ax

jmp      done_modding_shift_detail_code
set_to_zero:

; detailshift 0 case. usually involves two shift pairs.
; in this case - we make that first shift a proper shift

; d1 f8  = sar ax, 1
mov      ax, 0f8d1h 
mov      word ptr ds:[SELFMODIFY_detailshift_16_bit_jump_1+0], ax
mov      word ptr ds:[SELFMODIFY_detailshift_16_bit_jump_1+2], ax

; write to colfunc segment
mov      word ptr ds:[SELFMODIFY_COLFUNC_detailshift_2_minus_16_bit_shift+0], ax
mov      word ptr ds:[SELFMODIFY_COLFUNC_detailshift_2_minus_16_bit_shift+2], ax


; for 32 bit shifts, modify jump to jump 8 for 0 shifts, 4 for 1 shifts, 0 for 0 shifts.

; d1 e0 d1 d2   =  shl ax, 1; rcl dx, 1.
mov      ax, 0e0d1h
mov      word ptr ds:[SELFMODIFY_detailshift_32_bit_rotate_jump_1+0], ax
mov      word ptr ds:[SELFMODIFY_detailshift_32_bit_rotate_jump_2+0], ax
mov      word ptr ds:[SELFMODIFY_detailshift_32_bit_rotate_jump_3+0], ax
mov      word ptr ds:[SELFMODIFY_detailshift_32_bit_rotate_jump_4+0], ax
mov      word ptr ds:[SELFMODIFY_detailshift_32_bit_rotate_jump_5+0], ax

mov      ax, 0d2d1h
mov      word ptr ds:[SELFMODIFY_detailshift_32_bit_rotate_jump_1+2], ax
mov      word ptr ds:[SELFMODIFY_detailshift_32_bit_rotate_jump_2+2], ax
mov      word ptr ds:[SELFMODIFY_detailshift_32_bit_rotate_jump_3+2], ax
mov      word ptr ds:[SELFMODIFY_detailshift_32_bit_rotate_jump_4+2], ax
mov      word ptr ds:[SELFMODIFY_detailshift_32_bit_rotate_jump_5+2], ax

; 0EBh, 006h = jmp 6
mov      ax, 006EBh
mov      word ptr ds:[SELFMODIFY_detailshift_2_minus_32_bit_rotate_jump_1+0], ax
mov      word ptr ds:[SELFMODIFY_detailshift_2_minus_32_bit_rotate_jump_2+0], ax

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
mov      word ptr ds:[SELF_MODIFY_set_centerx_1+1], ax
mov      word ptr ds:[SELF_MODIFY_set_centerx_2+1], ax
mov      word ptr ds:[SELF_MODIFY_set_centerx_3+1], ax
mov      word ptr ds:[SELF_MODIFY_set_centerx_4+1], ax
mov      word ptr ds:[SELF_MODIFY_set_centerx_5+1], ax
mov      word ptr ds:[SELF_MODIFY_set_centerx_6+2], ax

mov      ax, COLFUNC_FUNCTION_AREA_SEGMENT
mov      es, ax

; ah is definitely 0... optimizable?
mov      ax, word ptr ss:[_centery]
mov      word ptr es:[SELFMODIFY_COLFUNC_subtract_centery+1], ax
 
mov      ax, word ptr ss:[_viewwidth]
mov      word ptr ds:[SELFMODIFY_set_viewwidth_1+1], ax
mov      word ptr ds:[SELFMODIFY_set_viewwidth_2+1], ax
mov      word ptr ds:[SELFMODIFY_set_viewwidth_3+1], ax

mov      ax, word ptr ss:[_viewheight]
mov      word ptr ds:[SELFMODIFY_setviewheight_1+5], ax
mov      word ptr ds:[SELFMODIFY_setviewheight_2+1], ax

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

ASSUME DS:R_MAINHI_TEXT


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
mov      byte ptr ds:[SELFMODIFY_set_extralight_1+1], al
mov      byte ptr ds:[SELFMODIFY_set_extralight_2+1], al

mov      al, byte ptr ss:[_fixedcolormap]
cmp      al, 0
jne      do_bsp_fixedcolormap_selfmodify
do_no_bsp_fixedcolormap_selfmodify:


mov      ax, 0c089h 
mov      word ptr ds:[SELFMODIFY_BSP_fixedcolormap_2], ax
mov      word ptr ds:[SELFMODIFY_BSP_fixedcolormap_3], ax
;mov      word ptr cs:[SELFMODIFY_add_wallights], 0848ah       ; mov al, byte ptr... 

jmp      done_with_bsp_fixedcolormap_selfmodify
do_bsp_fixedcolormap_selfmodify:

mov      byte ptr ds:[SELFMODIFY_BSP_fixedcolormap_1+3], al

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


; fall thru
done_with_bsp_fixedcolormap_selfmodify:




mov      ax, word ptr ss:[_viewx]
mov      word ptr ds:[SELFMODIFY_set_viewx_lo_1+1], ax
mov      word ptr ds:[SELFMODIFY_set_viewx_lo_2+2], ax
mov      word ptr ds:[SELFMODIFY_set_viewx_lo_3+1], ax
mov      ax, word ptr ss:[_viewx+2]
mov      word ptr ds:[SELFMODIFY_set_viewx_hi_1+1], ax
mov      word ptr ds:[SELFMODIFY_set_viewx_hi_2+2], ax
mov      word ptr ds:[SELFMODIFY_set_viewx_hi_3+2], ax

mov      ax, word ptr ss:[_viewy]
mov      word ptr ds:[SELFMODIFY_set_viewy_lo_1+1], ax
mov      word ptr ds:[SELFMODIFY_set_viewy_lo_2+1], ax
mov      word ptr ds:[SELFMODIFY_set_viewy_lo_3+2], ax
mov      ax, word ptr ss:[_viewy+2]
mov      word ptr ds:[SELFMODIFY_set_viewy_hi_1+1], ax
mov      word ptr ds:[SELFMODIFY_set_viewy_hi_2+2], ax
mov      word ptr ds:[SELFMODIFY_set_viewy_hi_3+2], ax

mov      ax, word ptr ss:[_viewangle_shiftright3]
mov      word ptr ds:[SELFMODIFY_set_viewanglesr3_1+1], ax
mov      word ptr ds:[SELFMODIFY_set_viewanglesr3_2+1], ax
mov      word ptr ds:[SELFMODIFY_set_viewanglesr3_3+1], ax
mov      word ptr ds:[SELFMODIFY_set_viewanglesr3_4+1], ax
mov      word ptr ds:[SELFMODIFY_set_viewanglesr3_5+2], ax

mov      ax, word ptr ss:[_viewangle_shiftright1]
mov      word ptr ds:[SELFMODIFY_set_viewanglesr1_1+1], ax
mov      word ptr ds:[SELFMODIFY_set_viewanglesr1_2+1], ax
mov      word ptr ds:[SELFMODIFY_set_viewanglesr1_3+1], ax

mov      ax, word ptr ss:[_viewangle]
mov      word ptr ds:[SELFMODIFY_BSP_viewangle_lo_1+2], ax
mov      word ptr ds:[SELFMODIFY_BSP_viewangle_lo_2+2], ax
mov      ax, word ptr ss:[_viewangle+2]
mov      word ptr ds:[SELFMODIFY_BSP_viewangle_hi_1+2], ax
mov      word ptr ds:[SELFMODIFY_BSP_viewangle_hi_2+2], ax

mov      ax, word ptr ss:[_fieldofview]
mov      word ptr ds:[SELFMODIFY_BSP_fieldofview_1+1], ax
mov      word ptr ds:[SELFMODIFY_BSP_fieldofview_2+1], ax
mov      word ptr ds:[SELFMODIFY_BSP_fieldofview_3+1], ax
mov      word ptr ds:[SELFMODIFY_BSP_fieldofview_4+1], ax

mov      ax, word ptr ss:[_clipangle]
mov      word ptr ds:[SELFMODIFY_BSP_clipangle_1+1], ax
mov      word ptr ds:[SELFMODIFY_BSP_clipangle_2+1], ax
mov      word ptr ds:[SELFMODIFY_BSP_clipangle_3+1], ax
mov      word ptr ds:[SELFMODIFY_BSP_clipangle_4+1], ax




; get whole dword at the end here.
mov      ax, word ptr ss:[_destview]
mov      word ptr ds:[SELFMODIFY_COLFUNC_add_destview_offset+1], ax

mov      ax, ss
mov      ds, ax
ASSUME DS:DGROUP

mov      ax, COLFUNC_FUNCTION_AREA_SEGMENT
mov      es, ax
mov      ax, word ptr ds:[_destview+2]
mov      word ptr es:[SELFMODIFY_COLFUNC_set_destview_segment+1], ax

;call     R_WriteMathFrameConstants_




ret

ENDP







END
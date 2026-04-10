;
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

;=================================




SEGMENT R_SPAN24_TEXT USE16 PARA PUBLIC 'CODE'
ASSUME  CS:R_SPAN24_TEXT

PROC R_SPAN24_STARTMARKER_
PUBLIC R_SPAN24_STARTMARKER_
ENDP 


DRAWSPAN_AH_OFFSET             = 03F00h
DRAWSPAN_CALL_OFFSET           = (16 * (SPANFUNC_JUMP_LOOKUP_SEGMENT - COLORMAPS_SEGMENT)) + DRAWSPAN_AH_OFFSET

; lcall cs:[00xx] here to call R_DrawSpan with the right CS:IP for colormaps to be at cs:3F00




_spanfunc_yfrac:  ; 00 aligned...
dw 0, 0, 0, 0
_spanfunc_outp:
db 1, 2, 4, 8   

_ds_source_offset_span:
dw 0, 0
_spanfunc_xfrac:  ; 010h aligned
dw 0, 0, 0, 0

_viewangle_shiftright3_span:
dw 0, XTOVIEWANGLE_SEGMENT
; TWO UNUSED WORDS
dw 0, 0
_spanfunc_inner_loop_count: ; 020h aligned
dw 0, 0, 0, 0

_spanfunc_destview_offset: ; todo fill this out
dw 0, 0, 0, 0



public _spanfunc_inner_loop_count
public _spanfunc_xfrac
public _spanfunc_yfrac

; -1 jump case
dw  do_span_loop

_spanfunc_jump_target:
public _spanfunc_jump_target
; full quality


BYTES_PER_PIXEL = 14h
MAX_PIXELS = 80
;bytecount = (MAX_PIXELS * BYTES_PER_PIXEL) ; even offset
bytecount = last_span_pixel

REPT MAX_PIXELS
    dw bytecount 
    bytecount = bytecount - BYTES_PER_PIXEL
ENDM


MAXLIGHTZ                      = 0080h
MAXLIGHTZ_UNSHIFTED            = 0800h





; NOTE: cs:offset stuff for self modifying code must be zero-normalized
;  (subtract offset of R_DrawSpan) because this code is being moved to
; segment:0000 at runtime and the cs offset stuff is absolute, not relative.



; core calculation:
;spot = ((yfrac>>(16-6))&(63*64)) + ((xfrac>>16)&63);
;   top stuff ANDED OFF is never needed.
;    bottom stuff is used in adds.
;    so we use in general 22 bits of precision per dimension.
;     must preshift left by two so we have 8 bits high and 14 lo?

;yfrac
; ANDED OFF    KEPT  ANDED OFF     SHIFTED OFF
;01234567 
;        01   234567 
;                      012345      67 
;                                    01234567
;xfrac
; ANDED OFF      KEPT	  SHIFTED OFF
;01234567 
;	     01     234567 
;	
;			              01234567 
;           			     	01234567










; todo optimize this a bit, wasteful...





ALIGN_MACRO	
go_generate_values:
jmp   generate_distance_steps

;
; R_MapPlane24_
; void __far R_MapPlane ( byte y, int16_t x1, int16_t x2 )


;cachedheight   9000:0000
;yslope         9032:0000
;distscale      9064:0000
;cacheddistance 90B4:0000
;cachedxstep    90E6:0000
;cachedystep    9118:0000
; 	rather than changing ES a ton we will just modify offsets by segment distance
;   confirmed to be faster even on 8088 with it's baby prefetch queue - i think on 16 bit busses it is only faster.

ALIGN_MACRO	

SELFMODIFY_SPAN_fixedcolormap_1_TARGET:
SELFMODIFY_SPAN_fixedcolormap_2:
use_fixed_colormap:
mov   byte ptr cs:[SELFMODIFY_SPAN_set_colormap_index_jump+1 - OFFSET R_SPAN24_STARTMARKER_], 00
jmp   do_drawspan
; lcall SPANFUNC_FUNCTION_AREA_SEGME    NT:SPANFUNC_PREP_OFFSET



ALIGN_MACRO	
PROC    R_MapPlane24_ NEAR
PUBLIC  R_MapPlane24_

push es
PUSHA_NO_AX_MACRO

; ax is x1
; di is ds_y

mov  bp, SPANSTART_SEGMENT

shl   ax, 1


mov  si, di ; dc_y
xchg ax, di ; dc_x * 2
; si is dc_y word lookup.
mov   ds, bp


SELFMODIFY_SPAN_plane_height:
mov   ax, 01000h

; CACHEDHEIGHT LOOKUP

mov   bx, si

IF (COMPISA EQ COMPILE_8086) OR (COMPISA GE COMPILE_386)
    CMP AX, WORD PTR DS:[SI + ((CACHEDHEIGHT_SEGMENT - SPANSTART_SEGMENT) * 16)]
ELSE
    MOV DX, AX
    XCHG DX, WORD PTR DS:[SI + ((CACHEDHEIGHT_SEGMENT - SPANSTART_SEGMENT) * 16)]
    CMP AX, DX
ENDIF
    JNE go_generate_values 
    MOV AX, WORD PTR DS:[SI + ((CACHEDYSTEP_SEGMENT - SPANSTART_SEGMENT) * 16)]
    MOV CS:[SELFMODIFY_SPAN_ds_ystep+1 - OFFSET R_SPAN24_STARTMARKER_], AX
    
    SELFMODIFY_SPAN_detailshift_4:
    mov ax, ax
    mov ax, ax

    mov   word ptr cs:[SELFMODIFY_SPAN_ds_ystep + 1 - OFFSET R_SPAN24_STARTMARKER_], ax

    MOV AX, WORD PTR DS:[SI + ((CACHEDXSTEP_SEGMENT - SPANSTART_SEGMENT) * 16)]
    MOV WORD PTR CS:[SELFMODIFY_SPAN_ds_xstep+1 - OFFSET R_SPAN24_STARTMARKER_], AX
    SELFMODIFY_SPAN_detailshift_3:
    mov ax, ax
    mov ax, ax


    mov   word ptr cs:[SELFMODIFY_SPAN_ds_xstep+1 - OFFSET R_SPAN24_STARTMARKER_], ax


; CACHED DISTANCE lookup


    IF COMPISA LE COMPILE_286
        LES AX, DWORD PTR DS:[BX + SI + ((CACHEDDISTANCE_SEGMENT - SPANSTART_SEGMENT) * 16)]
        mov dx, es
    distance_steps_ready:
    ELSE
        MOV EDI, DWORD PTR DS:[SI + ((CACHEDDISTANCE_SEGMENT - SPANSTART_SEGMENT) * 16)]
    distance_steps_ready:
    ENDIF


distance_steps_ready:
public distance_steps_ready




; dx:ax is distance
; di is x1 word lookup
; si is ds_y word lookup
;     length = R_FixedMulLocal (distance,distscale[x1]);


mov   bx, di          ; dword lookup if we add them

push  dx   ; store distance high word in case needed for colormap
les   bp, dword ptr ds:[bx + di + ((DISTSCALE_SEGMENT - SPANSTART_SEGMENT) * 16)]
mov   cx, es                                   	; distscale high word

; inlined R_FixedMulLocal24_
; todo: 386 version
; ARGS
; DX:AX = Value1
; CX:BP = Value2

; PRESERVE
; DS
; SI
; DI
    MOV BX, DX
    PUSH AX
    MUL  BP
    MOV  ES, DX
    MOV  AX, BX
    MUL  CX
    XCHG AX, BX
    CWD
    AND  DX, BP
    SUB  BX, DX
    MUL  BP
    MOV  BP, ES
    ADD  AX, BP
    ADC  BX, DX
    XCHG AX, CX
    CWD
    POP BP
    AND DX, BP
    SUB BX, DX
    MUL BP
    ADD AX, CX
    ADC DX, BX


;	angle = MOD_FINE_ANGLE(viewangle_shiftright3+ xtoviewangle[x1]);
; ds_xfrac = viewx.w + R_FixedMulLocal(finecosine[angle], length );

xchg  bx, ax			; store low word of length (product result)in bx
mov   cx, dx			; store high word of length  (product result) in cx

les   ax, dword ptr cs:[_viewangle_shiftright3_span]
add   ax, word ptr es:[di]		; ax is unmodded fine angle.. di is a word lookup
and   ah, 01Fh			; MOD_FINE_ANGLE mod high bits

xchg  ax, bx			; fineangle in BX, low word into AX


mov   bp, ax	        ; store low word 
    
;call FixedMulTrigCosineLocal_
; todo 386

FAST_SHL1 bx

; sine stuff

    test bh, 020h

    MOV  DX, FINESINE_SEGMENT
    MOV  DS, DX
    PUSH WORD PTR DS:[BX]  ; just two bytes, pretty effcient instruction


    mov  dx, cx
    je   skip_invert_sin
    neg  dx
    NEG  bp
    SBB  dx, 0   ; bp:dx is sin

    skip_invert_sin:
    


    test bh, 030h
    MOV  BX, WORD PTR DS:[BX+((FINECOSINE_SEGMENT - FINESINE_SEGMENT) * 16)]  ; FINECOSINE - FINESINE

    mov   ds, dx			; BP:DS is sin


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


;    ds_yfrac = -viewy.w - R_FixedMulLocal(finesine[angle], length );

SELFMODIFY_SPAN_viewx_lo_1:
add   ax, 01000h
SELFMODIFY_SPAN_viewx_hi_1:
adc   dx, 01000h


; shift 2 left for alignment with byte boundary 
shl ax, 1
rcl dx, 1
shl ax, 1
rcl dx, 1

mov   al, ah
mov   ah, dl

xchg  ax, bp   ; bp stores xfrac, ax retrieves low word
; ds has high word..



;call FixedMulTrigSineLocal_
; todo 386

    POP  BX  ; sine lookup

    MUL  BX        ; AX * BX
    MOV  AX, DS    ; CX to AX
    MOV  CX, DX    ; CX stores high result as low word
    CWD            ; S1 in DX
    AND  DX, BX    ; S1 * AX
    NEG  DX        ; 
    XCHG DX, BX    ; AX into DX, high word into BX
    MUL  DX        ; AX*CX
    ADD  AX, CX    ; add low word
    ADC  DX, BX    ; add high word

;    ds_yfrac = -viewy.w - R_FixedMulLocalWrapper(finesine[angle], length );

; add viewy
SELFMODIFY_SPAN_viewy_lo_1:
add   ax, 01000h
SELFMODIFY_SPAN_viewy_hi_1:
adc   dx, 01000h

neg   dx
neg   ax
sbb   dx, 0

mov   al, ah
mov   ah, dl

start_writes:
public start_writes
mov   CX, SPANSTART_SEGMENT
mov   DS, CX

mov   CX, CS
mov   ES, CX

MOV   DX, WORD PTR DS:[SI + ((CACHEDYSTEP_SEGMENT - SPANSTART_SEGMENT) * 16)]

; AX has yfrac
; DX has ystep
; BP has xfrac


mov   bx, di  ; x1 word lookup   ; backup...


SELFMODIFY_SPAN_and_detailshift_word:
mov   cx, 7

AND   DI, CX
add   CL, 0F0h  ; DI is masked to 0-7, from now on just mask bit 3 over and over

; zero
;add   di, OFFSET _spanfunc_yfrac

; the above offset of 010h, 020h, 030h
; and to 1, 3, 7 still works to loop around. We are just eliminating bit 3.

; i suppose this whole section could be super optimized for potato/low with entire chunks of code replaced.

stosw
SELFMODIFY_SPAN_set_yfrac_lookup_potato:
and   di, cx
SELFMODIFY_SPAN_set_yfrac_lookup_potato_AFTER:
add   ax, dx
stosw
SELFMODIFY_SPAN_set_yfrac_lookup_low:
and   di, cx
SELFMODIFY_SPAN_set_yfrac_lookup_low_AFTER:
add   ax, dx
stosw
and   di, cx
add   ax, dx
stosw
SELFMODIFY_SPAN_set_yfrac_lookup_TARGET:
and   di, cx

xchg  ax, bp  ; now the x vars
MOV   DX, WORD PTR DS:[SI + ((CACHEDXSTEP_SEGMENT - SPANSTART_SEGMENT) * 16)]
add   di, 010h  ; _spanfunc_xfrac


; AX has xfrac
; DX has xstep


stosw
SELFMODIFY_SPAN_set_xfrac_lookup_potato:
and   di, cx
SELFMODIFY_SPAN_set_xfrac_lookup_potato_AFTER:
add   ax, dx
stosw
SELFMODIFY_SPAN_set_xfrac_lookup_low:
and   di, cx
SELFMODIFY_SPAN_set_xfrac_lookup_low_AFTER:
add   ax, dx
stosw
and   di, cx
add   ax, dx
stosw
SELFMODIFY_SPAN_set_xfrac_lookup_TARGET:
public SELFMODIFY_SPAN_set_xfrac_lookup_TARGET
and   di, cx

add   di, 010h  ; _spanfunc_inner_loop_count

;  	uint16_t baseoffset = FP_OFF(destview) + dc_yl_lookup[ds_y];

SELFMODIFY_SET_dc_yl_lookuptable:
public SELFMODIFY_SET_dc_yl_lookuptable
 mov   ax, 01000h
 mov   ds, ax

 lodsw   ; ds:[si]  ; last use of dc_yl

SELFMODIFY_SPAN_destview_lo_1:
 add   ax, 01000h
 xchg  ax, bp               			; store base view offset
 
 shr   bx, 1   ; dc_x 


 
SELFMODIFY_SPAN_ds_x2:
 mov   ax, 01000h

 mov   dl, al ; get x2 plane. 

 sub   ax, bx  ; x2 - x1


 ; nops if potato etc
SELFMODIFY_SPAN_detailshift2minus_1:
 shr   bx, 1							
 shr   bx, 1							; num pixels per plane

 add   bp, bx    ; base offset...


 ; nops if potato etc
SELFMODIFY_SPAN_detailshift2minus_3:
 shr   ax, 1							
 shr   ax, 1							; num pixels per plane
 
 inc   dx     ; plane after x2
 SELFMODIFY_SPAN_detailshift_mainloopcount_2:
 and   dl, 010h ; and by detailshift byte..
 shl   dl, 1  ; for word compare in loop
 mov   dh, 1 
 xor   si, si

; di = current plane target offset
; bp = destplane
; ax = dc_x2 - dx_x1 >> deatilshift
; dx = vga plane iter
; cl = word AND value for di + stosw based on detailshift.
; dl = dc_x2 vga plane
; dh = 1
; si = 0



; UNROLLED LOOP START


 mov   word ptr es:[di+8], bp   ; _spanfunc_destview_offset view offset
 stosw      ; _spanfunc_inner_loop_count
 SELFMODIFY_SPAN_set_loopcount_potato:
 and   di, cx   
 SELFMODIFY_SPAN_set_loopcount_potato_AFTER:
 lea   bx, [di - 020h]  ; OFFSET _spanfunc_inner_loop_count

; ax holds the last rendered plane...

 ; check vga plane of last pixel done vs x2
 mov   bh, bl
 sub   bh, dl ; if equal...
 sub   bh, dh ; sub 1 and get carry
 sbb   ax, si ; sub if carry 
 
; check next vga plane to render vs x0
 sub   bl, dh  ; dh = 1
 adc   bp, si  ; si known zero. add 1 if bl was 0 x1 increased

 
 mov   word ptr es:[di+8], bp   ; _spanfunc_destview_offset view offset
 stosw      ; _spanfunc_inner_loop_count
 SELFMODIFY_SPAN_set_loopcount_low:
 and   di, cx   
 SELFMODIFY_SPAN_set_loopcount_low_AFTER:
 lea   bx, [di - 020h]  ; OFFSET _spanfunc_inner_loop_count

 mov   bh, bl
 sub   bh, dl ; if equal...
 sub   bh, dh ; sub 1 and get carry
 sbb   ax, si ; sub if carry 
 
 sub   bl, dh  ; dh = 1
 adc   bp, si  ; si known zero. add 1 if bl was 0 x1 increased

 mov   word ptr es:[di+8], bp   ; _spanfunc_destview_offset view offset
 stosw      ; _spanfunc_inner_loop_count
 and   di, cx   
 lea   bx, [di - 020h]  ; OFFSET _spanfunc_inner_loop_count

 mov   bh, bl
 sub   bh, dl ; if equal...
 sub   bh, dh ; sub 1 and get carry
 sbb   ax, si ; sub if carry 
 
 sub   bl, dh  ; dh = 1
 adc   bp, si  ; si known zero. add 1 if bl was 0 x1 increased

 mov   word ptr es:[di+8], bp   ; _spanfunc_destview_offset view offset
 stosw      ; _spanfunc_inner_loop_count

 SELFMODIFY_SPAN_set_loopcount_TARGET:
 





; todo do this stuff earlier to avoid the push pop?
pop   ax  ; for stack consistency across branches, this pop is done here. holds distance high word?


; 	if (fixedcolormap) {

SELFMODIFY_SPAN_fixedcolormap_1:
mov   ax, ax
SELFMODIFY_SPAN_fixedcolormap_1_AFTER:
; 		index = distance >> LIGHTZSHIFT;


SHIFT_MACRO sar ax 4


;		if (index >= MAXLIGHTZ) {
;			index = MAXLIGHTZ - 1;
;		}



cmp   al, MAXLIGHTZ
jb    index_set
mov   al, MAXLIGHTZ - 1
index_set:

;		ds_colormap_segment = colormaps_segment;
;		ds_colormap_index = planezlight[index];

les    bx, dword ptr ss:[_planezlight]
xlat  byte ptr es:[bx]
; mov  al, byte ptr cs:[bx + _cs_zlight_offset]
colormap_ready:

mov   byte ptr cs:[SELFMODIFY_SPAN_set_colormap_index_jump+1 - OFFSET R_SPAN24_STARTMARKER_], al



; todo move the below up.
do_drawspan:

; inlined drawspanprep...

SELFMODIFY_SPAN_set_plane_0:
mov   al, 010h
mov   dx, SC_DATA						; outp 1 << i
out   dx, al



 
 
 spanfunc_arg_setup_complete:

 ; use jump table with desired cs:ip for far jump

SELFMODIFY_SPAN_set_colormap_index_jump:
mov  ax, 00000h      ; colormap * 4
SHIFT_MACRO shl ax 2 ; colormap * 16
; target ss segment
add  ax, (COLORMAPS_SEGMENT - (DRAWSPAN_AH_OFFSET SHR 4))
; addr 0000 + first byte (4x colormap.)


; inlined DrawSpan



SELFMODIFY_SPAN_ds_ystep:
mov     bp, 01000h
ENSUREALIGN_401:


mov   es, word ptr ss:[_destview + 2]	; retrieve destview segment

cli 	; disable interrupts because we usesp here
mov   ss, ax  ; pass in ax?
mov   ax, cs
mov   ds, ax

mov   word ptr ds:[((SELFMODIFY_SPAN_sp_storage+1) - R_SPAN24_STARTMARKER_   )], sp

SELFMODIFY_SPAN_ds_xstep:
mov     sp,  01000h
ENSUREALIGN_402:

xor   bx, bx						; zero out bx as loopcount
mov   byte ptr ds:[((SELFMODIFY_SPAN_set_span_counter+1) - OFFSET R_SPAN24_STARTMARKER_   )], bl      ; set loop increment value



; main loop start (i = 0, 1, 2, 3)


ALIGN_MACRO
span_i_loop_repeat:

mov   si, word ptr ds:[_spanfunc_inner_loop_count + bx] ; 

; es is already pre-set..

FAST_SHL1 si


mov   di, word ptr ds:[_spanfunc_destview_offset + bx]  ; destview offset precalculated..
mov   dx, word ptr ds:[_spanfunc_xfrac + bx]  ; destview offset precalculated..
mov   cx, word ptr ds:[_spanfunc_yfrac + bx]  ; destview offset precalculated..
lds   ax, dword ptr ds:[_ds_source_offset_span] 		; ds:si is ds_source. BX is pulled in by lds as a constant (DRAWSPAN_BX_OFFSET)
; ah gets 3F
jmp   word ptr cs:[si + _spanfunc_jump_target - OFFSET R_SPAN24_STARTMARKER_ ]	    ; get unrolled jump count.
; MAKE SURE THIS IS WORD ALIGNED OR ALL WILL BREAK

ALIGN_MACRO
MARKER_SM_SPAN24_AFTER_JUMP_1:
PUBLIC MARKER_SM_SPAN24_AFTER_JUMP_1



REPT MAX_PIXELS - 1
    AND   CH, AH
    MOV   BH, CH
    MOV   BL, DH
    SHR   BX, 1
    SHR   BX, 1
    MOV   AL, byte ptr DS:[BX]
    mov   si, ax
    movs  byte ptr es:[di], byte ptr ss:[si]
    ADD   DX, SP ; DX = XXXXXXxx xxxxxx00
    ADD   CX, BP ; CX = 00YYYYYY yyyyyyyy
    
endm

; final pixel
last_span_pixel:

    AND   CH, AH
    MOV   BH, CH
    MOV   BL, DH
    SHR   BX, 1
    SHR   BX, 1
    MOV   AL, byte ptr DS:[BX]
    mov   si, ax
    movs  byte ptr es:[di], byte ptr ss:[si]
 


do_span_loop:

SELFMODIFY_SPAN_set_span_counter:
mov   bx, 0

; loop if i < loopcount.
SELFMODIFY_SPAN_compare_span_counter:
cmp   bl, 3
jge   span_i_loop_done

mov   ax, cs
mov   ds, ax
inc   bx
mov   byte ptr ds:[((SELFMODIFY_SPAN_set_span_counter+1) -  OFFSET R_SPAN24_STARTMARKER_   )], bl


mov   al, byte ptr ds:[_spanfunc_outp + bx]
mov   dx, SC_DATA						; outp 1 << i
out   dx, al

FAST_SHL1 bx

mov   si, word ptr ds:[_spanfunc_inner_loop_count + bx] ; 
FAST_SHL1 si

mov   di, word ptr ds:[_spanfunc_destview_offset + bx]  ; destview offset precalculated..
mov   dx, word ptr ds:[_spanfunc_xfrac + bx]  ; destview offset precalculated..
mov   cx, word ptr ds:[_spanfunc_yfrac + bx]  ; destview offset precalculated..
lds   ax, dword ptr ds:[_ds_source_offset_span] 		; ds:si is ds_source. BX is pulled in by lds as a constant (DRAWSPAN_BX_OFFSET)
; ah gets 3F
jmp   word ptr cs:[si + _spanfunc_jump_target - OFFSET R_SPAN24_STARTMARKER_ ]	    ; get unrolled jump count.

ALIGN_MACRO	
span_i_loop_done:

mov   ax, FIXED_DS_SEGMENT
mov   ss, ax
mov   ds, ax


; restore sp, bp
SELFMODIFY_SPAN_sp_storage:
mov sp, 01000h
ENSUREALIGN_400:




sti								; reenable interrupts

; todo popa/pusha is not working for some reason


POPA_NO_AX_MACRO
pop es


ret  




ALIGN_MACRO	

generate_distance_steps:
    push  di  ; dc_x * 2

    ; Register state (all not listed are junk/scratch):
    ; SS = FIXED_DS_SEGMENT
    ; BP = SPANSTART_SEGMENT
    ; SI = y << 1

IF (COMPISA EQ COMPILE_8086) OR (COMPISA GE COMPILE_386)
    MOV DS:[SI], AX ; Handled by XCHG for 186/286
ENDIF

IF COMPISA LE COMPILE_286

    ; fastmul1632 with 13:3 value
    MOV CX, AX
    MUL WORD PTR DS:[BX + SI + 2 + ((YSLOPE_SEGMENT - SPANSTART_SEGMENT) * 16)] ; hiword
    XCHG AX, CX
    MUL WORD PTR DS:[BX + SI + ((YSLOPE_SEGMENT - SPANSTART_SEGMENT) * 16)]  ; lo word
    ADD DX, CX
    
    ; NOW lets shift, avoiding a fixedmul.
    SHIFT32_MACRO_RIGHT DX AX 3
    
    MOV WORD PTR DS:[BX + SI + ((CACHEDDISTANCE_SEGMENT - SPANSTART_SEGMENT) * 16)], AX
    MOV WORD PTR DS:[BX + SI + 2 + ((CACHEDDISTANCE_SEGMENT - SPANSTART_SEGMENT) * 16)], DX
    
    MOV DI, AX
    MOV ES, DX
    

SELFMODIFY_SPAN_basexscale_lo_1:
    MOV BP, 01000h
SELFMODIFY_SPAN_basexscale_hi_1:
    MOV CX, 01000h
    
    
    ; ds_xstep = cachedxstep[y] = R_FixedMulLocal(distance, basexscale)
    ;CALL R_FixedMulLocal24_

    MOV BX, DX

    MUL BP
    MOV WORD PTR CS:[_selfmodify_restore_dx_2+1], DX
    MOV AX, BX
    MUL CX
    XCHG AX, BX
    CWD
    AND DX, BP
    SUB BX, DX
    MUL BP
    _selfmodify_restore_dx_2:
    ADD AX, 01000h
    ADC BX, DX
    XCHG AX, CX
    CWD

    AND DX, DI
    SUB BX, DX
    MUL DI
    ADD AX, CX
    ADC DX, BX
    
    ; Convert to 6.10
    SHL AX, 1
    RCL DX, 1
    SHL AX, 1
    RCL DX, 1
    MOV AL, AH
    MOV AH, DL
    
    MOV WORD PTR DS:[SI + ((CACHEDXSTEP_SEGMENT - SPANSTART_SEGMENT) * 16)], AX

    SELFMODIFY_SPAN_detailshift_1:
    mov ax, ax
    mov ax, ax

    MOV WORD PTR CS:[SELFMODIFY_SPAN_ds_xstep+1 - OFFSET R_SPAN24_STARTMARKER_], AX


    MOV AX, DI



SELFMODIFY_SPAN_baseyscale_lo_1:
    MOV BP, 01000h
SELFMODIFY_SPAN_baseyscale_hi_1:
    MOV CX, 01000h
    
    ; ds_ystep = cachedystep[y] = R_FixedMulLocal(distance, baseyscale)
    ;CALL R_FixedMulLocal24_

    MOV BX, ES

    MUL BP
    MOV WORD PTR CS:[_selfmodify_restore_dx_1+1], DX
    MOV AX, BX
    MUL CX
    XCHG AX, BX
    CWD
    AND DX, BP
    SUB BX, DX
    MUL BP
    _selfmodify_restore_dx_1:
    ADD AX, 01000h
    ADC BX, DX
    XCHG AX, CX
    CWD

    AND DX, DI
    SUB BX, DX
    MUL DI
    ADD AX, CX
    ADC DX, BX

    
    ; Convert to 6.8   TODO fix precision issue
    ;SHL AX, 1
    ;RCL DX, 1
    ;SHL AX, 1
    ;RCL DX, 1
    MOV AL, AH
    MOV AH, DL
    
    MOV WORD PTR DS:[SI + ((CACHEDYSTEP_SEGMENT - SPANSTART_SEGMENT) * 16)], AX
    
    ; todo do this write later?

    SELFMODIFY_SPAN_detailshift_2:
    mov ax, ax
    mov ax, ax
    MOV WORD PTR CS:[SELFMODIFY_SPAN_ds_ystep+1 - OFFSET R_SPAN24_STARTMARKER_], AX
    ; restore distance once more
    xchg ax, di
    MOV  DX, ES
    
    pop   di              ; x1 << 1  from push ax at func start..

    

ELSE
    MOVZX EDI, AX
    IMUL EDI, DS:[BX + SI + ((YSLOPE_SEGMENT - SPANSTART_SEGMENT) * 16)]
    SHR EDI, 3
    MOV WORD PTR DS:[BX + SI + ((CACHEDDISTANCE_SEGMENT - SPANSTART_SEGMENT) * 16)], EDI
SELFMODIFY_SPAN_baseyscale_full_1: ; todo implement
    MOV EAX, 010000000h
    IMUL EDI
    SHRD EAX, EDX, 22 ; Convert to 6.10
    MOV WORD PTR DS:[SI + ((CACHEDYSTEP_SEGMENT - SPANSTART_SEGMENT) * 16)], AX
    SELFMODIFY_SPAN_detailshift_1:
    mov ax, ax
    mov ax, ax
    MOV WORD PTR CS:[SELFMODIFY_SPAN_ds_ystep+1 - OFFSET R_SPAN24_STARTMARKER_], AX
SELFMODIFY_SPAN_basexscale_full_1: ; todo implement
    MOV EAX, 010000000h
    IMUL EDI
    SHRD EAX, EDX, 22 ; Convert to 6.10
    MOV WORD PTR DS:[SI + ((CACHEDXSTEP_SEGMENT - SPANSTART_SEGMENT) * 16)], AX
    SELFMODIFY_SPAN_detailshift_2:
    mov ax, ax
    mov ax, ax
    MOV WORD PTR CS:[SELFMODIFY_SPAN_ds_xstep+1 - OFFSET R_SPAN24_STARTMARKER_], AX
ENDIF

    JMP distance_steps_ready
    


   

ENDP

local_visplaneoffset = 0
local_visplanesegment = 2
draw_planes_frame_size = 4

; TODO THIS

; Documentation macro for correcting stack offsets.
; Positive argument is number of PUSH compared to normal frame.
; Negative argument is number of POP compared to normal frame.
PUSH_OFFSETS MACRO count
(&count * 2)
ENDM

; Documentation macro for correcting stack offsets.
; Argument is number of LODSW to subtract from the size
LODSW_OFFSETS MACRO count
(&count * -2)
ENDM
LODSW_OFFSET = 2


;R_DrawPlanes_

ALIGN_MACRO	
PROC   R_DrawPlanes24_ FAR
PUBLIC R_DrawPlanes24_


; ARGS none

; STACK




 ; TODO THIS
; NORMAL STACK (negatives are pushed temps)
; SP - 2 = &_visplaneheaders[i]
; SP + 0 = visplaneoffset
; SP + 2 = visplanesegment
; SP + 4 = Return addr

; OUTER FUNCTION HAS A POPA

; bp equals visplaneoffset
; sp points to visplanesegment



 PUSH_MACRO_WITH_REG DX FIRST_VISPLANE_PAGE_SEGMENT ; SP = this offset.
 XOR BP, BP ; SP + 0 (will be pushed later)

; inline R_WriteBackSpanFrameConstants_
; get whole dword at the end here.


mov      al, byte ptr ds:[_lastvisplane]
mov      ah, SIZE VISPLANEHEADER_T
mul      ah
add      ax, OFFSET _visplaneheaders + VISPLANEHEADER_T.visplaneheader_minx ; compare at lodsw offset
mov      word ptr cs:[SELFMODIFY_SPAN_last_iter_compare+2 - OFFSET R_SPAN24_STARTMARKER_], ax


mov      al, byte ptr ds:[_skyflatnum]  ; todo self modify at a different layer once per level
mov      byte ptr cs:[SELFMODIFY_SPAN_skyflatnum + 2 - OFFSET R_SPAN24_STARTMARKER_], al

mov      ds, word ptr ds:[_BSP_CODE_SEGMENT_PTR]

MOV      SI, CS ; 2 byte, 2 cycle
MOV      ES, SI ; 2 byte, 2 cycle

mov   si, _BASEXSCALE_OFFSET_R_BSP

IF COMPISA LE COMPILE_286
    MOV DI, SELFMODIFY_SPAN_basexscale_lo_1+1 - OFFSET R_SPAN24_STARTMARKER_
    MOVSW
    INC DI ; SELFMODIFY_SPAN_basexscale_hi_1+1 - OFFSET R_SPAN24_STARTMARKER_
    MOVSW
    
    MOV DI, SELFMODIFY_SPAN_baseyscale_lo_1+1 - OFFSET R_SPAN24_STARTMARKER_
    MOVSW
    INC DI ; SELFMODIFY_SPAN_baseyscale_hi_1+1 - OFFSET R_SPAN24_STARTMARKER_
    MOVSW
    
    MOV DI, SELFMODIFY_SPAN_viewx_lo_1+1 - OFFSET R_SPAN24_STARTMARKER_
    MOVSW
    ADD DI, 2 ; SELFMODIFY_SPAN_viewx_hi_1+2 - OFFSET R_SPAN24_STARTMARKER_
    MOVSW
    
    MOV DI, SELFMODIFY_SPAN_viewy_lo_1+1 - OFFSET R_SPAN24_STARTMARKER_
    MOVSW
    ADD DI, 2 ; SELFMODIFY_SPAN_viewy_hi_1+2 - OFFSET R_SPAN24_STARTMARKER_
    MOVSW
ELSE

    ; todo... actually do this.
    MOV DI, SELFMODIFY_SPAN_basexscale_full_1+2 - OFFSET R_SPAN24_STARTMARKER_
    MOVSD ES:[DI], DS:[SI]
    
    MOV DI, SELFMODIFY_SPAN_baseyscale_full_1+2 - OFFSET R_SPAN24_STARTMARKER_
    MOVSD ES:[DI], DS:[SI]
    
    MOV DI, SELFMODIFY_SPAN_viewx_full_1+2 - OFFSET R_SPAN24_STARTMARKER_
    MOVSD ES:[DI], DS:[SI]
    
    MOV DI, SELFMODIFY_SPAN_viewy_full_1+3 - OFFSET R_SPAN24_STARTMARKER_
    MOVSD ES:[DI], DS:[SI]
ENDIF


lodsw  ; viewz_shortheight
mov   word ptr cs:[SELFMODIFY_SPAN_viewz_13_3_1+1 - OFFSET R_SPAN24_STARTMARKER_], ax

lodsw  ; _viewangle_shiftright3
mov   word ptr cs:[_viewangle_shiftright3_span], ax  ; todo is this the same as viewz_shortheight

mov   ax, ss
mov   ds, ax


mov   ax, word ptr ds:[_destview+0]
mov   word ptr cs:[SELFMODIFY_SPAN_destview_lo_1+1 - OFFSET R_SPAN24_STARTMARKER_], ax

mov   al, byte ptr ds:[_player + PLAYER_T.player_extralightvalue]
SHIFT_MACRO shl al 4
mov   byte ptr cs:[SELFMODIFY_SPAN_extralight_1+2 - OFFSET R_SPAN24_STARTMARKER_], al

mov   ax, 0c089h  ; nop

cmp   byte ptr ds:[_fixedcolormap], 0
jne   do_span_fixedcolormap_selfmodify
done_with_span_fixedcolormap_selfmodify:
; modify instruction
mov   word ptr cs:[SELFMODIFY_SPAN_fixedcolormap_1 - OFFSET R_SPAN24_STARTMARKER_], ax
mov   si, OFFSET _visplaneheaders + VISPLANEHEADER_T.visplaneheader_minx ; initial case.
jmp   drawplanes_loop


exit_drawplanes:
public exit_drawplanes
add   sp, 2
retf   

ALIGN_MACRO	
do_span_fixedcolormap_selfmodify:
mov   al, byte ptr ds:[_fixedcolormap]
mov   byte ptr cs:[SELFMODIFY_SPAN_fixedcolormap_2 + 5 - OFFSET R_SPAN24_STARTMARKER_], al
mov   ax, ((SELFMODIFY_SPAN_fixedcolormap_1_TARGET - SELFMODIFY_SPAN_fixedcolormap_1_AFTER) SHL 8) + 0EBh
jmp   done_with_span_fixedcolormap_selfmodify

ALIGN_MACRO	

check_next_visplane_page:
; do next visplane page
sub   bp, VISPLANE_BYTES_PER_PAGE
; di = sp
add   word ptr ss:[di], 0400h  ; si not pushed yet
jmp   loop_visplane_page_check

ALIGN_MACRO	
do_sky_flat_draw:

; di is the correct ptr already
mov   cx, word ptr ss:[di]
mov   bx, bp
; ax already has minx
mov   dx, word ptr ds:[si]  ; maxx

; preserves BP 
;call  [_R_DrawSkyPlaneCallHigh]
SELFMODIFY_SPAN_draw_skyplane_call:
call  dword ptr ds:[_R_DrawSkyPlane_addr]

; fall through

ALIGN_MACRO	

do_next_drawplanes_loop:	

pop   si  ; READ VISPLANE_HEADER

do_next_drawplanes_loop_short:
ADD   SI, SIZE VISPLANEHEADER_T - LODSW_OFFSET   ; add one element minus 2 - si is plus 4 (minx)

SELFMODIFY_SPAN_last_iter_compare:
cmp   si, 01000h   ; todo self modify constant in drawplanes24
jae   exit_drawplanes

add   bp, VISPLANE_BYTE_SIZE


drawplanes_loop:
public drawplanes_loop
; si is _visplaneheaders pointer here.
; write back current one for next iter.

lodsw   ;                             ; grab visplane minx.  si is plus 6 
CMP   AX, WORD PTR DS:[SI]                     ; cmp to visplane maxx
jg    do_next_drawplanes_loop_short
cmp   byte ptr ds:[si + VISPLANEHEADER_T.visplaneheader_dirty - VISPLANEHEADER_T.visplaneheader_maxx], 0
je    do_next_drawplanes_loop_short

mov   di, sp ; di = sp for the loop area...

loop_visplane_page_check:
cmp   bp, VISPLANE_BYTES_PER_PAGE
jnb   check_next_visplane_page

; write +6 offset.

push  si   ; WRITE VISPLANE_HEADER




mov   cx, word ptr ds:[si + VISPLANEHEADER_T.visplaneheader_piclight - VISPLANEHEADER_T.visplaneheader_maxx]
SELFMODIFY_SPAN_skyflatnum:
cmp   cl, 0
je    do_sky_flat_draw

do_nonsky_flat_draw:
push  bp

xchg  ax, cx

mov   byte ptr cs:[SELFMODIFY_SPAN_lookuppicnum+2 - OFFSET R_SPAN24_STARTMARKER_], al






    XOR BX, BX
    
    MOV DX, FLATTRANSLATION_SEGMENT
    MOV ES, DX
    XLAT ES:[BX]
    MOV DX, FLATINDEX_SEGMENT
    MOV ES, DX
    XCHG AL, BL  ; NOTE: Just saves AL for later in BL,
    XLAT ES:[BX] ; doesn't matter for XLAT because BL was 0
    
; al flatindex
; bl flattranslation
; ah visplane light


SELFMODIFY_SPAN_extralight_1:
    ADD AH, 0
    SBB CX, CX
IF COMPISA LE COMPILE_286
    OR CL, AH
    SHL CX, 1
    SHL CX, 1
    SHL CX, 1
    AND CX, 00780h
ELSE
    OR CX, AX
    SHR CX, 12  
    SHL CX, 7
ENDIF
    MOV WORD PTR DS:[_planezlight], CX
    
    MOV CX, 0FF01h
    MOV AH, 0BAh ; MOV DX, imm


    ; Register state (all not listed are junk/scratch):
    ; DS = SS = FIXED_DS_SEGMENT
    ; ES = FLATINDEX_SEGMENT
    ; AL = usedflatindex
    ; AH = self modify instruction constant
    ; CL = 1
    ; CH = -1
    ; DX = FLATINDEX_SEGMENT
    ; BL = FLATINDEX_SEGMENT offset
    ; BH = 0
    ; SI = &_visplaneheaders[i].visplaneheader_maxx
    ; DI = SP    


    CMP AL, CH
    JNE flat_loaded
    MOV BP, SI
    MOV DI, BX
    MOV SI, _allocatedflatsperpage + NUM_FLAT_CACHE_PAGES
    MOV BX, -(NUM_FLAT_CACHE_PAGES)
loop_find_flat: ; LOOP DEPTH: 2
public loop_find_flat
    MOV AX, DS:[BX + SI]
    CMP AL, 4
    JB found_page_with_empty_spaceA
    INC BX
    CMP AH, 4
    JB found_page_with_empty_spaceB
    INC BX
    JNZ loop_find_flat
    ; LOOP DEPTH: 1
    JMP evict_flat

ALIGN_MACRO
update_l1_cache_from_l2:
public update_l1_cache_from_l2
    ; di points to _lastflatcacheindicesused

    ; NOTE: _lastflatcacheindicesused is right after _currentflatpage
    ; so DI will point to it if this branch is taken
    MOV  BP, AX
    ; ES = DS = SS = FIXED_DS_SEGMENT
IF COMPISA GE COMPILE_386
    MOV EBX, DS:[DI]
    ROL EBX, 8
    MOV DS:[DI], EBX
ELSE
    MOV BH, DS:[DI]         ; 03
    MOV CX, DS:[DI + 1]     ; 0200
    MOV BL, DS:[DI + 3]     ; 0301
    MOV DS:[DI], BX
    MOV DS:[DI + 2], CX
ENDIF

    CBW
    MOV BH, AH ; AH should be 0
    MOV DS:[BX + DI - 4], AL   ; 0x10
    MOV CL, BL                 ; 0x01
IF PAGE_SWAP_ARG_MULT EQ 1
    FAST_SHL1 BL
ELSE
    SHIFT_MACRO SHL BL 2
ENDIF

IFDEF COMP_CH
    ADD AX, FIRST_FLAT_CACHE_LOGICAL_PAGE + EMS_MEMORY_PAGE_OFFSET
ELSE
    ADD AX, FIRST_FLAT_CACHE_LOGICAL_PAGE
ENDIF
    MOV DS:[BX + _pageswapargs + (pageswapargs_flatcache_offset * 2)], AX
    MOV BL, CL
    MOV DI, SI


    Z_QUICKMAPAI4 pageswapargs_flatcache_offset_size INDEXED_PAGE_7000_OFFSET
    
    MOV SI, DI
    MOV CL, BL
    XCHG AX, BP
    JMP l1_cache_finished_updating

    ; ==================== HOLE HOLE HOLE ====================
    
found_page_with_empty_spaceB: ; LOOP DEPTH: 1
    MOV AL, AH
found_page_with_empty_spaceA:
    ADD CL, AL
    MOV BYTE PTR DS:[BX + SI], CL
    ADD BL, NUM_FLAT_CACHE_PAGES
    SHIFT_MACRO SHL BL 2
    OR AL, BL
found_flat:
done_with_evict_flatcache_ems_page:
    STOSB
    MOV AH, 0E9h
    MOV SI, BP
flat_loaded:
    ; Register state (all not listed are junk/scratch):
    ; SS = FIXED_DS_SEGMENT
    ; AL = usedflatindex
    ; AH = self modify instruction constant
    ; SI = &_visplaneheaders[i].visplaneheader_maxx
    MOV BYTE PTR CS:[SELFMODIFY_SPAN_flat_unloaded - OFFSET R_SPAN24_STARTMARKER_], AH
    
    MOV AH, AL
    AND AH, 3
    

    SHIFT_MACRO SHR AL 2
    
    MOV CX, SS
    MOV DS, CX ; NOTE: Can be removed if previous flat loop isn't slower with ES:
    MOV ES, CX
    
    MOV CX, 4
    MOV DI, _currentflatpage
    REPNE SCASB ; This should be fast since it takes advantage of CL afterwards
    ; TODO: Branch has a range issue on 286.
    ; Check if target code can fit in a nearby gap
    ; or just put a trampoline JMP in there.
    JNE update_l1_cache_from_l2
    XOR CL, 3 ; Convert 3-0 to 0-3
    ; Correct DI to consistently point to _currentflatpage+1
    ; MOV DI, _lastflatcacheindicesused would remove offsets though...
    SUB DI, CX
    
    MOV DX, WORD PTR DS:[DI + 3]
    CMP DL, CL
    JE in_flat_page_0
    MOV CH, DL
    CMP DH, CL
    JE in_flat_page_1
    MOV BX, WORD PTR DS:[DI + 5]
    CMP BL, CL
    JE in_flat_page_2
    MOV BH, BL
in_flat_page_2:
    MOV BL, DH
    MOV WORD PTR DS:[DI + 5], BX
in_flat_page_1:
    MOV WORD PTR DS:[DI + 3], CX
in_flat_page_0:
    XOR BH, BH

l1_cache_finished_updating:
public l1_cache_finished_updating


    ; Register state (all not listed are junk/scratch):
    ; ES = DS = SS = FIXED_DS_SEGMENT
    ; AL = usedflatindex >> 2
    ; AH = usedflatindex & 3
    ; CL = flatpageindex
    ; BH = 0 !!! wrong
    ; SI = &_visplaneheaders[i].visplaneheader_maxx
    
    ; NOTE: Could pull _flatcache_l2_head constant out of flatcachemruL2
    CMP AL, BYTE PTR DS:[_flatcache_l2_head]
    ; TODO: Branch has a range issue on 286.
    ; Check if target code can fit in a nearby gap
    ; or just put a trampoline JMP in there.
    JNE flatcachemruL2
done_with_mruL2:
public done_with_mruL2
    ; Register state (all not listed are junk/scratch):
    ; DS = SS = FIXED_DS_SEGMENT
    ; AH = usedflatindex & 3
    ; CL = flatpageindex
    ; BH = 0 !!! wrong. usually FF.
    ; SI = &_visplaneheaders[i].visplaneheader_maxx

    SHIFT_MACRO SHL CL 2
    ADD CL, (FLAT_CACHE_BASE_SEGMENT SHR 8)
    MOV CH, CL
    MOV CL, BH
SELFMODIFY_SPAN_flat_unloaded:
public SELFMODIFY_SPAN_flat_unloaded
    MOV DX, OFFSET  flat_is_unloaded - (OFFSET SELFMODIFY_SPAN_flat_unloaded + 3)
    ADD CH, AH
flat_not_unloaded:
    MOV BYTE PTR CS:[_ds_source_offset_span+3], CH
    
    ; Register state (all not listed are junk/scratch):
    ; DS = SS = FIXED_DS_SEGMENT
    ; SI = &_visplaneheaders[i].visplaneheader_maxx
    
    
mov   ax, word ptr ds:[si + VISPLANEHEADER_T.visplaneheader_height - VISPLANEHEADER_T.visplaneheader_maxx]

SELFMODIFY_SPAN_viewz_13_3_1:
public SELFMODIFY_SPAN_viewz_13_3_1
sub   ax, 01000h
; ABS
cwd
xor   ax, dx
sub   ax, dx   

pop   bp
    

mov   word ptr cs:[SELFMODIFY_SPAN_plane_height+1], ax
mov   ax, word ptr ds:[si + VISPLANEHEADER_T.visplaneheader_maxx - VISPLANEHEADER_T.visplaneheader_maxx]
mov   di, ax
mov   bx, sp
mov   es, word ptr ss:[bx+2] ; bp has been popped..
mov   bx, bp


mov   byte ptr es:[bx + di + 3], 0ffh
mov   si, word ptr ds:[si + VISPLANEHEADER_T.visplaneheader_minx - VISPLANEHEADER_T.visplaneheader_maxx]
mov   byte ptr es:[bx + si + 1], 0ffh
inc   ax

mov   word ptr cs:[SELFMODIFY_SPAN_comparestop+2 - OFFSET R_SPAN24_STARTMARKER_], ax ; set count value to be compared against in loop.

cmp   si, ax
jle   start_single_plane_draw_loop
jmp   do_next_drawplanes_loop

ALIGN_MACRO

flatcachemruL2:
public flatcachemruL2

; force bx to 0!
    xor bx, bx
    ; bh was already 0?

    MOV BP, SI
    MOV ES, CX
    MOV SI, OFFSET _flatcache_nodes
    
    ; prev = nodelist[index].prev
    ; next = nodelist[index].next
    MOV BL, AL
    FAST_SHL1 BL
    MOV DX, DS:[BX + SI]
    
    MOV DI, _flatcache_l2_head
    
    MOV CX, DS:[DI] ; CL = head, CH = tail
    ; flatcache_l2_head = index
    MOV DS:[DI], AL ; NOTE: Can't STOSB, CL in ES
    
    ; if (index == flatcache_l2_tail) {
    ;    flatcache_l2_tail = next
    ; } else {
    ;     nodelist[prev].next = next
    ; }
    CMP AL, CH
    ; nodelist[index].prev = flatcache_l2_head
    ; nodelist[index].next = -1
    MOV CH, 0FFh
    MOV DS:[BX + SI], CX
    JE index_is_tail
    MOV BL, DL
    FAST_SHL1 BL
    LEA DI, [BX + SI]
index_is_tail:
    MOV DS:[DI + 1], DH
    
    ; nodelist[next].prev = prev
    MOV BL, DH
    FAST_SHL1 BL
    MOV DS:[BX + SI], DL
    
    ; nodelist[flatcache_l2_head].next = index
    MOV BL, CL
    FAST_SHL1 BL
    MOV DS:[BX + SI + 1], AL
    MOV CX, ES
    MOV SI, BP
    JMP done_with_mruL2


    ; ==================== HOLE HOLE HOLE ====================



ALIGN_MACRO
start_single_plane_draw_loop:
push   bp

; loop setup
single_plane_draw_loop: ; LOOP DEPTH: 2
public single_plane_draw_loop

; si is x, bx is plheader pointer. so adding si gets us plheader->top[x] etc.
mov   bx, sp
mov   es, word ptr ss:[bx+4]
mov   bx, bp


;			t1 = pl->top[x - 1];
;			b1 = pl->bottom[x - 1];
;			t2 = pl->top[x];
;			b2 = pl->bottom[x];



mov   dx, word ptr es:[bx + si + VISPLANE_T.vp_bottom - 1]	; b1&b2
mov   cx, word ptr es:[bx + si + VISPLANE_T.vp_top - 1]		; t1&t2


mov   ax, SPANSTART_SEGMENT
mov   es, ax

; t1/t2 ch/cl
; b1/b2 dh/dl
dec   si	; x - 1  constant
mov   word ptr cs:[SELFMODIFY_SPAN_ds_x2+1], si
inc   si  ; add one back from the previous saved x-1 state

;    while (t1 < t2 && t1 <= b1)

cmp   cl, ch
jae   done_with_first_mapplane_loop
; set up the di parameter to be spanstart lookup index
mov   al, cl
xor   ah, ah
mov   di, ax
add   di, ax


loop_first_mapplane:
cmp   cl, dl
ja    done_with_first_mapplane_loop

mov   ax, word ptr es:[di]

inc   cl

call  R_MapPlane24_

cmp   cl, ch
jae   done_with_first_mapplane_loop
inc   di
inc   di

jmp   loop_first_mapplane
ALIGN_MACRO	

end_single_plane_draw_loop_iteration:

;  todo: di not really in use at all in this loop. could be made to hold something useful
inc   si
SELFMODIFY_SPAN_comparestop:
cmp   si, 1000h
jle   single_plane_draw_loop

pop   bp
jmp   do_next_drawplanes_loop
ALIGN_MACRO	

done_with_first_mapplane_loop:



cmp   dl, dh
jbe   done_with_second_mapplane_loop
; set up the di parameter to be spanstart lookup index
mov   al, dl
xor   ah, ah
mov   di, ax
add   di, ax

loop_second_mapplane:
cmp   cl, dl
ja   done_with_second_mapplane_loop

mov   ax, word ptr es:[di]

dec   dl

call  R_MapPlane24_

cmp   dl, dh
jbe   done_with_second_mapplane_loop

dec   di
dec   di
jmp   loop_second_mapplane
ALIGN_MACRO	

done_with_second_mapplane_loop:

; update spanstarts



; b1 = dl
; b2 = dh
; t1 = cl
; t2 = ch

;			while (t2 < t1 && t2 <= b2) {
;				spanstart[t2] = x;

mov   ax, SPANSTART_SEGMENT
mov   es, ax

mov   bx, cx

sub   cl, ch     ; t2 < t1?
jbe   second_spanstart_update_loop
mov   ax, dx
sub   ah, ch     ; t2 <= b2?
jb    second_spanstart_update_loop

inc   ah		; add one for the >= 
cmp   ah, cl
ja    dont_swap_cx_params_1  ; todo jae and inc inside
mov   cl, ah
dont_swap_cx_params_1:


mov   al, ch  ; get t2 word lookup...
xor   ah, ah
add   ax, ax
mov   di, ax  ; di = offset

xor   ch, ch  ; cx loop count is set
mov   ax, bx
add   bh, cl  ; add the t2 increment

mov   ax, si  ;  ax = x
rep   stosw



second_spanstart_update_loop:


;			while (b2 > b1 && b2 >= t2) {
;				spanstart[b2] = x;
; b1 = dl
; b2 = dh
; t1 = bl
; t2 = bh

mov   ax, dx
sub   ah, al    ; b2 - b1
jbe   end_single_plane_draw_loop_iteration
mov   cl, dh	; store b2 copy for spanstart addr calculation
sub   dh, bh    ; b2 - t2
jb    end_single_plane_draw_loop_iteration

; add one for the >= case 
inc   dh
; ah and ch store the two values... take the smallest one to get loop count
cmp   ah, dh
ja    dont_swap_cx_params_2
mov   dh, ah
dont_swap_cx_params_2:


xor   ch, ch
mov   di, cx  ; cl held copied b2 from above
add   di, di  ; di = offset

mov   cl, dh  ; count


mov   ax, si  ;  ax = x
std   
rep   stosw
cld
jmp   end_single_plane_draw_loop_iteration
ALIGN_MACRO	



    
    ; ==================== HOLE HOLE HOLE ====================


    
    ; ==================== HOLE HOLE HOLE ====================


ALIGN_MACRO
flat_is_unloaded:
public  flat_is_unloaded
    MOV DI, CX
    
    
IF COMPISA LE COMPILE_286
    xor  BX, BX
    MOV  BH, AH
    SHIFT_MACRO SHL BH 4
ELSE
    MOV BL, AH
    SHL BX, 12
ENDIF
    XCHG AX, BP
    
    MOV DX, FLATTRANSLATION_SEGMENT
    MOV ES, DX
    
SELFMODIFY_SPAN_lookuppicnum:
public SELFMODIFY_SPAN_lookuppicnum
    mov   al, byte ptr es:[00]    ; uses picnum from way above.
    XOR AH, AH ; NOTE: Can this be CBW?
    ADD AX, DS:[_firstflat]
    
    CALL DWORD PTR DS:[_W_CacheLumpNumDirect_addr]
    
    LEA CX, [BP + DI]
    JMP flat_not_unloaded
    

evict_flat:
    public evict_flat
    MOV AX, DS:[_flatcache_l2_head] ; AL = head, AH = tail
    ; evictedpage = flatcache_l2_tail
    MOV BL, AH
    ; // all the other flats in this are cleared.
    ; allocatedflatsperpage[evictedpage] = 1
    MOV BYTE PTR DS:[BX + SI - NUM_FLAT_CACHE_PAGES], CL
    MOV CL, AL
    MOV AL, AH
    MOV SI, OFFSET _flatcache_nodes
    FAST_SHL1 BL
    ; flatcache_l2_tail = flatcache_nodes[evictedpage].next
    MOV AH, BYTE PTR DS:[BX + SI + 1]
    ; flatcache_l2_head = evictedpage
    MOV WORD PTR DS:[_flatcache_l2_head], AX
    ; flatcache_nodes[evictedpage].prev = flatcache_l2_head
    ; flatcache_nodes[evictedpage].next = -1
    MOV WORD PTR DS:[BX + SI], CX
    FAST_SHL1 BL
    ; flatcache_nodes[flatcache_l2_tail].prev = -1
    XCHG BL, AH
    FAST_SHL1 BL
    MOV BYTE PTR DS:[BX + SI], CH
    ; flatcache_nodes[flatcache_l2_head].next = evictedpage
    MOV BL, CL
    FAST_SHL1 BL
    MOV BYTE PTR DS:[BX + SI + 1], AL
    
    SHIFT_MACRO SHL AH 2
    XOR SI, SI
    MOV BX, -1
    MOV DS, DX ; NOTE: Can be removed if following flat loop isn't slower with ES:
    MOV DL, 0FCh
    MOV CX, MAX_FLATS
;   for (i = 0; i < MAX_FLATS; i++) {
;       if ((flatindex[i] >> 2) == evictedpage) {
;           flatindex[i] = 0xFF;
;       }
;  	}
ALIGN_MACRO
check_next_flat: ; LOOP DEPTH: 2
    LODSB
    AND AL, DL
    CMP AL, AH
    JE erase_flat
    LOOP check_next_flat
    MOV AL, AH
    JMP done_with_evict_flatcache_ems_page
erase_flat:
    MOV BYTE PTR DS:[BX + SI], BL


    LOOP check_next_flat
    MOV AL, AH
    JMP done_with_evict_flatcache_ems_page

ENDP






;
; The following functions are loaded into a different segment at runtime.
; However, at compile time they have access to the labels in this file.
;


;R_WriteBackViewConstantsSpan

ALIGN_MACRO	
PROC R_WriteBackViewConstantsSpan24_ FAR
PUBLIC R_WriteBackViewConstantsSpan24_ 



mov      ax, SPANFUNC_JUMP_LOOKUP_SEGMENT
mov      ds, ax


ASSUME DS:R_SPAN24_TEXT

les      ax, dword ptr ss:[_ds_source_offset]
mov      word ptr ds:[_ds_source_offset_span+0], ax
mov      word ptr ds:[_ds_source_offset_span+2], es

; todo do just once
mov      ax, word ptr ss:[_BSP_MUL_80_LOOKUP_SEGMENT]
mov      word ptr ds:[SELFMODIFY_SET_dc_yl_lookuptable+1], ax



mov       ax, OFFSET _R_DrawSkyPlane_addr
cmp       byte ptr ss:[_screenblocks], 10
jge       setup_dynamic_skyplane
mov       ax, OFFSET _R_DrawSkyPlaneDynamic_addr
setup_dynamic_skyplane:
mov       word ptr ds:[SELFMODIFY_SPAN_draw_skyplane_call + 2 - OFFSET R_SPAN24_STARTMARKER_], ax



mov      al, byte ptr ss:[_detailshift]
cmp      al, 1
je       do_detail_shift_one
jl       do_detail_shift_zero
jmp      do_detail_shift_two
ALIGN_MACRO	
do_detail_shift_zero:

mov     word ptr ds:[_spanfunc_outp + 0], 00201h 


mov      word ptr ds:[SELFMODIFY_SPAN_and_detailshift_word+1 - OFFSET R_SPAN24_STARTMARKER_], 7


mov      byte ptr ds:[SELFMODIFY_SPAN_set_plane_0+1], 1
mov      byte ptr ds:[SELFMODIFY_SPAN_compare_span_counter+2        - OFFSET R_SPAN24_STARTMARKER_], 3
mov      byte ptr ds:[SELFMODIFY_SPAN_detailshift_mainloopcount_2+2 - OFFSET R_SPAN24_STARTMARKER_], 3

; sal   ax, 1 ; 0E0D1h

mov      ax, 0E0D1h  ; sal ax, 1
mov      word ptr ds:[SELFMODIFY_SPAN_detailshift_1+0 - OFFSET R_SPAN24_STARTMARKER_], ax
mov      word ptr ds:[SELFMODIFY_SPAN_detailshift_1+2 - OFFSET R_SPAN24_STARTMARKER_], ax
mov      word ptr ds:[SELFMODIFY_SPAN_detailshift_2+0 - OFFSET R_SPAN24_STARTMARKER_], ax
mov      word ptr ds:[SELFMODIFY_SPAN_detailshift_2+2 - OFFSET R_SPAN24_STARTMARKER_], ax
mov      word ptr ds:[SELFMODIFY_SPAN_detailshift_3+0 - OFFSET R_SPAN24_STARTMARKER_], ax
mov      word ptr ds:[SELFMODIFY_SPAN_detailshift_3+2 - OFFSET R_SPAN24_STARTMARKER_], ax
mov      word ptr ds:[SELFMODIFY_SPAN_detailshift_4+0 - OFFSET R_SPAN24_STARTMARKER_], ax
mov      word ptr ds:[SELFMODIFY_SPAN_detailshift_4+2 - OFFSET R_SPAN24_STARTMARKER_], ax


mov ax, 0EBD1h  ; shr   bx, 1
mov      word ptr ds:[SELFMODIFY_SPAN_detailshift2minus_1+0 - OFFSET R_SPAN24_STARTMARKER_], ax  
mov      word ptr ds:[SELFMODIFY_SPAN_detailshift2minus_1+2 - OFFSET R_SPAN24_STARTMARKER_], ax
mov ax, 0E8D1h  ; shr   ax, 1
mov      word ptr ds:[SELFMODIFY_SPAN_detailshift2minus_3+0 - OFFSET R_SPAN24_STARTMARKER_], ax  
mov      word ptr ds:[SELFMODIFY_SPAN_detailshift2minus_3+2 - OFFSET R_SPAN24_STARTMARKER_], ax

mov ax, 0CF21h ; and di, ci
mov      word ptr ds:[SELFMODIFY_SPAN_set_yfrac_lookup_potato - OFFSET R_SPAN24_STARTMARKER_], ax 
mov      word ptr ds:[SELFMODIFY_SPAN_set_yfrac_lookup_low - OFFSET R_SPAN24_STARTMARKER_], ax 
mov      word ptr ds:[SELFMODIFY_SPAN_set_xfrac_lookup_potato - OFFSET R_SPAN24_STARTMARKER_], ax 
mov      word ptr ds:[SELFMODIFY_SPAN_set_xfrac_lookup_low - OFFSET R_SPAN24_STARTMARKER_], ax 
mov      word ptr ds:[SELFMODIFY_SPAN_set_loopcount_potato - OFFSET R_SPAN24_STARTMARKER_], ax 
mov      word ptr ds:[SELFMODIFY_SPAN_set_loopcount_low - OFFSET R_SPAN24_STARTMARKER_], ax 




jmp     done_with_detailshift
ALIGN_MACRO	
do_detail_shift_one:
mov     word ptr ds:[_spanfunc_outp + 0],  3 + (12 SHL 8)

mov      word ptr ds:[SELFMODIFY_SPAN_and_detailshift_word+1 - OFFSET R_SPAN24_STARTMARKER_], 3


mov      byte ptr ds:[SELFMODIFY_SPAN_set_plane_0+1], 3

mov      byte ptr ds:[SELFMODIFY_SPAN_compare_span_counter+2        - OFFSET R_SPAN24_STARTMARKER_], 1
mov      byte ptr ds:[SELFMODIFY_SPAN_detailshift_mainloopcount_2+2 - OFFSET R_SPAN24_STARTMARKER_], 1



; sal   ax, 1 ; 0E0D1h
; rcl   dx, 1 ; 0D2D1h


mov      ax, 0E0D1h
mov      word ptr ds:[SELFMODIFY_SPAN_detailshift_1+0 - OFFSET R_SPAN24_STARTMARKER_], ax
mov      word ptr ds:[SELFMODIFY_SPAN_detailshift_2+0 - OFFSET R_SPAN24_STARTMARKER_], ax
mov      word ptr ds:[SELFMODIFY_SPAN_detailshift_3+0 - OFFSET R_SPAN24_STARTMARKER_], ax
mov      word ptr ds:[SELFMODIFY_SPAN_detailshift_4+0 - OFFSET R_SPAN24_STARTMARKER_], ax

mov      ax, 0D2D1h




mov      word ptr ds:[SELFMODIFY_SPAN_detailshift2minus_1+0 - OFFSET R_SPAN24_STARTMARKER_], 0EBD1h  ; shr   bx, 1
mov      word ptr ds:[SELFMODIFY_SPAN_detailshift2minus_3+0 - OFFSET R_SPAN24_STARTMARKER_], 0E8D1h  ; shr   ax, 1
mov      ax, 0E0D1h

mov   ax, 0c089h  ; nop
mov      word ptr ds:[SELFMODIFY_SPAN_detailshift_1+2 - OFFSET R_SPAN24_STARTMARKER_], ax
mov      word ptr ds:[SELFMODIFY_SPAN_detailshift_2+2 - OFFSET R_SPAN24_STARTMARKER_], ax
mov      word ptr ds:[SELFMODIFY_SPAN_detailshift_3+2 - OFFSET R_SPAN24_STARTMARKER_], ax
mov      word ptr ds:[SELFMODIFY_SPAN_detailshift_4+2 - OFFSET R_SPAN24_STARTMARKER_], ax

mov      word ptr ds:[SELFMODIFY_SPAN_detailshift2minus_1+2 - OFFSET R_SPAN24_STARTMARKER_], ax
mov      word ptr ds:[SELFMODIFY_SPAN_detailshift2minus_3+2 - OFFSET R_SPAN24_STARTMARKER_], ax

mov ax, 0CF21h ; and di, cx
mov      word ptr ds:[SELFMODIFY_SPAN_set_xfrac_lookup_potato - OFFSET R_SPAN24_STARTMARKER_], ax 
mov      word ptr ds:[SELFMODIFY_SPAN_set_yfrac_lookup_potato - OFFSET R_SPAN24_STARTMARKER_], ax 
mov      word ptr ds:[SELFMODIFY_SPAN_set_loopcount_potato - OFFSET R_SPAN24_STARTMARKER_], ax 

mov      word ptr ds:[SELFMODIFY_SPAN_set_xfrac_lookup_low - OFFSET R_SPAN24_STARTMARKER_], ((SELFMODIFY_SPAN_set_xfrac_lookup_TARGET - SELFMODIFY_SPAN_set_xfrac_lookup_low_AFTER) SHL 8) + 0EBh
mov      word ptr ds:[SELFMODIFY_SPAN_set_yfrac_lookup_low - OFFSET R_SPAN24_STARTMARKER_], ((SELFMODIFY_SPAN_set_yfrac_lookup_TARGET - SELFMODIFY_SPAN_set_yfrac_lookup_low_AFTER) SHL 8) + 0EBh
mov      word ptr ds:[SELFMODIFY_SPAN_set_loopcount_low - OFFSET R_SPAN24_STARTMARKER_],    ((SELFMODIFY_SPAN_set_loopcount_TARGET -    SELFMODIFY_SPAN_set_loopcount_low_AFTER) SHL 8) + 0EBh


jmp     done_with_detailshift
ALIGN_MACRO	

do_detail_shift_two:


mov      word ptr ds:[SELFMODIFY_SPAN_and_detailshift_word+1 - OFFSET R_SPAN24_STARTMARKER_], 1


mov      byte ptr ds:[_spanfunc_outp + 0], 15 ; technically this never has to be changed 
mov      byte ptr ds:[SELFMODIFY_SPAN_set_plane_0+1], 15

mov      byte ptr ds:[SELFMODIFY_SPAN_compare_span_counter+2        - OFFSET R_SPAN24_STARTMARKER_], 0
mov      byte ptr ds:[SELFMODIFY_SPAN_detailshift_mainloopcount_2+2 - OFFSET R_SPAN24_STARTMARKER_], 0


mov      ax, 0c089h  ; nop


mov      word ptr ds:[SELFMODIFY_SPAN_detailshift_1+0 - OFFSET R_SPAN24_STARTMARKER_], ax
mov      word ptr ds:[SELFMODIFY_SPAN_detailshift_1+2 - OFFSET R_SPAN24_STARTMARKER_], ax
mov      word ptr ds:[SELFMODIFY_SPAN_detailshift_2+0 - OFFSET R_SPAN24_STARTMARKER_], ax
mov      word ptr ds:[SELFMODIFY_SPAN_detailshift_2+2 - OFFSET R_SPAN24_STARTMARKER_], ax
mov      word ptr ds:[SELFMODIFY_SPAN_detailshift_3+0 - OFFSET R_SPAN24_STARTMARKER_], ax
mov      word ptr ds:[SELFMODIFY_SPAN_detailshift_3+2 - OFFSET R_SPAN24_STARTMARKER_], ax
mov      word ptr ds:[SELFMODIFY_SPAN_detailshift_4+0 - OFFSET R_SPAN24_STARTMARKER_], ax
mov      word ptr ds:[SELFMODIFY_SPAN_detailshift_4+2 - OFFSET R_SPAN24_STARTMARKER_], ax


mov      word ptr ds:[SELFMODIFY_SPAN_set_xfrac_lookup_potato - OFFSET R_SPAN24_STARTMARKER_], ((SELFMODIFY_SPAN_set_xfrac_lookup_TARGET - SELFMODIFY_SPAN_set_xfrac_lookup_potato_AFTER) SHL 8) + 0EBh
mov      word ptr ds:[SELFMODIFY_SPAN_set_yfrac_lookup_potato - OFFSET R_SPAN24_STARTMARKER_], ((SELFMODIFY_SPAN_set_yfrac_lookup_TARGET - SELFMODIFY_SPAN_set_yfrac_lookup_potato_AFTER) SHL 8) + 0EBh
mov      word ptr ds:[SELFMODIFY_SPAN_set_loopcount_potato - OFFSET R_SPAN24_STARTMARKER_],    ((SELFMODIFY_SPAN_set_loopcount_TARGET -    SELFMODIFY_SPAN_set_loopcount_potato_AFTER) SHL 8) + 0EBh




; two minus

mov      word ptr ds:[SELFMODIFY_SPAN_detailshift2minus_1+0 - OFFSET R_SPAN24_STARTMARKER_], ax
mov      word ptr ds:[SELFMODIFY_SPAN_detailshift2minus_1+2 - OFFSET R_SPAN24_STARTMARKER_], ax
mov      word ptr ds:[SELFMODIFY_SPAN_detailshift2minus_3+0 - OFFSET R_SPAN24_STARTMARKER_], ax
mov      word ptr ds:[SELFMODIFY_SPAN_detailshift2minus_3+2 - OFFSET R_SPAN24_STARTMARKER_], ax

done_with_detailshift:




mov      ax, ss
mov      ds, ax







retf

ENDP





; end marker for this asm file
PROC R_SPAN24_ENDMARKER_ FAR
PUBLIC R_SPAN24_ENDMARKER_ 
ENDP

ENDS

public ENSUREALIGN_400
public ENSUREALIGN_401
public ENSUREALIGN_402
;public ENSUREALIGN_403

END

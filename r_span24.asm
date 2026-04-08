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

R_DRAWSPANACTUAL_DIFF = (OFFSET R_DrawSpanActual24_ - OFFSET R_SPAN24_STARTMARKER_)
DRAWSPAN_AH_OFFSET             = 03F00h
DRAWSPAN_CALL_OFFSET           = (16 * (SPANFUNC_JUMP_LOOKUP_SEGMENT - COLORMAPS_SEGMENT)) + DRAWSPAN_AH_OFFSET

; lcall cs:[00xx] here to call R_DrawSpan with the right CS:IP for colormaps to be at cs:3F00



_spanfunc_inner_loop_count:
dw 0, 0, 0, 0

_spanfunc_destview_offset:
dw 0, 0, 0, 0

_spanfunc_prt:
dw 0, 0, 0, 0

_spanfunc_outp:
db 1, 2, 4, 8   

_spanfunc_xfrac:
dw 0, 0, 0, 0
_spanfunc_yfrac:
dw 0, 0, 0, 0

_ds_source_offset_span:
dw 0, 0

public _spanfunc_xfrac
public _spanfunc_yfrac

_spanfunc_jump_target:
public _spanfunc_jump_target
; full quality


BYTES_PER_PIXEL = 14h
MAX_PIXELS = 80
bytecount = (MAX_PIXELS * BYTES_PER_PIXEL) ; even offset
REPT MAX_PIXELS
    bytecount = bytecount - BYTES_PER_PIXEL
    dw bytecount 
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


;
; R_DrawSpan
;
PROC    R_DrawSpan24_ NEAR
PUBLIC  R_DrawSpan24_ 
	
; need to include these 2 instructions, and need a function label to include this...

no_pixels:
jmp   do_span_loop

ENDP ; shut up compiler warning

ALIGN_MACRO	
PROC   R_DrawSpanActual24_ NEAR
PUBLIC R_DrawSpanActual24_



; stack vars
push   bp



; todo move all this math out of this layer
    

SELFMODIFY_SPAN_ds_ystep:
mov     bp, 01000h


mov   es, word ptr ds:[_destview + 2]	; retrieve destview segment

cli 	; disable interrupts because we usesp here
mov   ss, ax  ; pass in ax?

mov   word ptr cs:[((SELFMODIFY_SPAN_sp_storage+1) - R_SPAN24_STARTMARKER_   )], sp

SELFMODIFY_SPAN_ds_xstep:
mov     sp,  01000h

xor   bx, bx						; zero out bx as loopcount
mov   byte ptr cs:[((SELFMODIFY_SPAN_set_span_counter+1) - OFFSET R_SPAN24_STARTMARKER_   )], bl      ; set loop increment value



; main loop start (i = 0, 1, 2, 3)



span_i_loop_repeat:

mov   si, word ptr cs:[_spanfunc_inner_loop_count + bx] ; 

; es is already pre-set..


sal   si, 1					; convert index to  a word lookup index

; is count < 0? if so skip this loop iter

jl   no_pixels			; todo this so it doesnt loop in both cases

;       modify the jump for this iteration (self-modifying code)




mov   ax, word ptr cs:[si + _spanfunc_jump_target - OFFSET R_SPAN24_STARTMARKER_ ]	    ; get unrolled jump count.
; write to the unrolled loop jump instruction.
mov   WORD PTR cs:[((SPANFUNC_JUMP_OFFSET+1)- OFFSET R_SPAN24_STARTMARKER_   )], ax;

; 		dest = destview + ds_y * 80 + dsp_x1;
mov   di, word ptr cs:[_spanfunc_destview_offset + bx]  ; destview offset precalculated..
mov   dx, word ptr cs:[_spanfunc_xfrac + bx]  ; destview offset precalculated..

mov   cx, word ptr cs:[_spanfunc_yfrac + bx]  ; destview offset precalculated..






lds   ax, dword ptr cs:[_ds_source_offset_span] 		; ds:si is ds_source. BX is pulled in by lds as a constant (DRAWSPAN_BX_OFFSET)
; ah gets 3F


; todo jmp si 
SPANFUNC_JUMP_OFFSET:
public SPANFUNC_JUMP_OFFSET
jmp span_i_loop_done         ; relative jump to be modified before function is called
; MAKE SURE THIS IS WORD ALIGNED OR ALL WILL BREAK

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

inc   bx
mov   byte ptr cs:[((SELFMODIFY_SPAN_set_span_counter+1) -  OFFSET R_SPAN24_STARTMARKER_   )], bl


mov   al, byte ptr cs:[_spanfunc_outp + bx]
mov   dx, SC_DATA						; outp 1 << i
out   dx, al

sal   bx, 1

jmp   span_i_loop_repeat

ALIGN_MACRO	
span_i_loop_done:

mov   ax, FIXED_DS_SEGMENT
mov   ss, ax
mov   ds, ax


; restore sp, bp
SELFMODIFY_SPAN_sp_storage:
mov sp, 01000h



pop bp

sti								; reenable interrupts

ret  


ENDP




;
; R_DrawSpanPrep
;
ALIGN_MACRO	
PROC  R_DrawSpanPrep24_ NEAR


SELFMODIFY_SPAN_set_plane_0:
mov   al, 010h
mov   dx, SC_DATA						; outp 1 << i
out   dx, al



 
 ;  	uint16_t baseoffset = FP_OFF(destview) + dc_yl_lookup[ds_y];

; predoubles _ds_y for lookup
 les   bx, dword ptr ds:[_ds_y]
 
 mov   ax, word ptr es:[bx]				; get dc_yl_lookup[ds_y]
SELFMODIFY_SPAN_destview_lo_1:
 add   ax, 01000h
 mov   es, word ptr [bp - 0Ah]			; es holds ds_x1
	
 xor   bl, bl							; zero out bl. use it as loop counter/ i
 ; todo carry this forward
 mov   word ptr cs:[SELFMODIFY_SPAN_destview_add+2 - OFFSET R_SPAN24_STARTMARKER_], ax			; store base view offset
 
; todo the following  feels like extraneous register juggling, reexamine

 spanfunc_arg_setup_loop_start:
 mov   al, bl							; al holds loop counter
 mov   dx, es							; get ds_x1
 CBW  									; zero out ah
 
;		int16_t dsp_x1 = (ds_x1 - i) >> shiftamount;
 sub   dx, ax							; subtract i 
 SELFMODIFY_SPAN_detailshift2minus_1:
 sar   dx, 1							; shift
 sar   dx, 1							; shift

; 		int16_t dsp_x2 = (ds_x2 - i) >> shiftamount;

SELFMODIFY_SPAN_ds_x2:
 mov   cx, word ptr [bp - 0Ch]		        ; cx holds ds_x2
 sub   cx, ax							; subtract i
 mov   si, ax							; put i in si
 
 mov   ax, dx							; copy dsp_x1 to ax
 
 SELFMODIFY_SPAN_detailshift2minus_2:
 shl   ax, 1							; shift dsp_x1 left
 shl   ax, 1							; shift dsp_x1 left
 SELFMODIFY_SPAN_detailshift2minus_3:
 sar   cx, 1							; shift ds_x2 right. di = dsp_x2
 sar   cx, 1							; shift ds_x2 right. di = dsp_x2
 
 mov   di, es							; get ds_x1 into di
 
;		if ((dsp_x1 << shiftamount) + i < ds_x1)

 add   ax, si							; ax = (dsp_x1 << shiftamount) + i
 cmp   ax, di			; if si <  (dsp_x1 << shiftamount) + i

 jge   dont_increment_ds_x1     ; signed so carry flag adc 0 doesnt work?
;		ds_x1 ++
 
 inc   dx
 dont_increment_ds_x1:
 mov   al, bl							; al holds loop counter
 CBW  
 mov   si, ax							; store loop counter in si

 ; 		countp = dsp_x2 - dsp_x1;
 
 shl   si, 1
;     cx has dsp_x2
 sub   cx, dx							; cx is countp

 mov   word ptr cs:[si + _spanfunc_inner_loop_count], cx  ; store it. high byte of word always 0
								   ; if negative then loop
 jl    spanfunc_arg_setup_iter_done
 
; 		spanfunc_prt[i] = (dsp_x1 << shiftamount) - ds_x1 + i;
;		spanfunc_destview_offset[i] = baseoffset + dsp_x1;
 shr   si, 1

 
 mov   ax, dx										   ; move dsp_x1 to ax
 SELFMODIFY_SPAN_detailshift2minus_4:
 shl   ax, 1										   ; shift dsp_x1 left
 shl   ax, 1
 sub   ax, di										   ; subtract ds_x1
 add   ax, si										   ; add i, prt is calculated
 add   si, si										   ; double i for word lookup index
 SELFMODIFY_SPAN_destview_add:
 add   dx, 01000h						   ; dsp_x1 + base view offset
 mov   word ptr cs:[si + _spanfunc_prt], ax			   ; store prt
 mov   word ptr cs:[si + _spanfunc_destview_offset], dx   ; store view offset
 
 spanfunc_arg_setup_iter_done:
 
 inc   bl
 
 SELFMODIFY_SPAN_detailshift_mainloopcount_2:
 cmp   bl, 0
 jl    spanfunc_arg_setup_loop_start
 
 spanfunc_arg_setup_complete:

 ; use jump table with desired cs:ip for far jump

SELFMODIFY_SPAN_set_colormap_index_jump:
mov  ax, 00000h      ; colormap * 4
SHIFT_MACRO shl ax 2 ; colormap * 16
; target ss segment
add  ax, (COLORMAPS_SEGMENT - (DRAWSPAN_AH_OFFSET SHR 4))
; addr 0000 + first byte (4x colormap.)
jmp  R_DrawSpanActual24_ ; todo just inline?



ENDP






; todo optimize this a bit, wasteful...



IF COMPISA GE COMPILE_386

    ALIGN_MACRO	
    PROC   FixedMulTrigSineLocal_ NEAR
    PUBLIC FixedMulTrigSineLocal_

    shl   bx, 2



    shl   ecx, 16
    xchg  ax, cx
    


    mov   ax, FINESINE_SEGMENT
    mov   es, ax                ; put segment in es

    mov   ax, bx
    shl   ax, 1
    cwde                        ; eax high gets sign
    shr bx, 1

    mov   ax, word ptr es:[bx] ; ax gets low word
    imul  ecx
    shr   eax, 16


    ret

    ENDP

    ALIGN_MACRO	
    PROC   FixedMulTrigCosineLocal_ NEAR
    PUBLIC FixedMulTrigCosineLocal_

    shl   bx, 2


    shl   ecx, 16
    xchg  ax, cx
    
    mov   ax, FINECOSINE_SEGMENT
    mov   es, ax                ; put segment in es

    lea   eax, [ebx*2 + 04000h]
    cwde                        ; eax high gets sign
    shr bx, 1
    mov   ax, word ptr es:[bx] ; ax gets low word
    imul  ecx
    shr   eax, 16


    ret



    ENDP


ELSE

    ALIGN_MACRO	
    PROC   FixedMulTrigSineLocal_ NEAR
    PUBLIC FixedMulTrigSineLocal_


    SHL  BX, 1
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


    ALIGN_MACRO	
    PROC   FixedMulTrigCosineLocal_ NEAR
    PUBLIC FixedMulTrigCosineLocal_


    SHL  BX, 1
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
ENDIF




ALIGN_MACRO	
PROC R_FixedMulLocal24_ NEAR


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

ALIGN_MACRO	
go_generate_values:
jmp   generate_distance_steps

;
; R_MapPlane24_
; void __far R_MapPlane ( byte y, int16_t x1, int16_t x2 )
; bp - 02h   distance low
; bp - 04h   distance high

;cachedheight   9000:0000
;yslope         9032:0000
;distscale      9064:0000
;cacheddistance 90B4:0000
;cachedxstep    90E6:0000
;cachedystep    9118:0000
; 	rather than changing ES a ton we will just modify offsets by segment distance
;   confirmed to be faster even on 8088 with it's baby prefetch queue - i think on 16 bit busses it is only faster.



ALIGN_MACRO	
PROC    R_MapPlane24_ NEAR
PUBLIC  R_MapPlane24_

push  cx
push  si
push  di
push  es
push  dx

; ax is bp - 0Ah
; di is ds_y



mov  si, di
; si is x * 2
mov   es, ds:[_cachedheight_segment_storage]


mov   ax, word ptr [bp - 0Eh]
; TODO: do this shl outside of the function. borrow from es:di lookup's di
; CACHEDHEIGHT LOOKUP

cmp   ax, word ptr es:[si]
jne   go_generate_values	; comparing high word

mov   bx, si

; CACHED DISTANCE lookup
use_cached_values:

les   ax, dword ptr es:[bx + si + 0 + (( CACHEDDISTANCE_SEGMENT - CACHEDHEIGHT_SEGMENT) * 16)]
mov   dx, es

push  ax
; CACHEDXSTEP lookup. move these into temporary variable space

;todo should these be cached pre-shifted?
; here is where we get xstep/ystep.
; ax:cx


mov   es, ds:[_cachedxstep_segment_storage]
mov   ax, word ptr es:[si] ; todo both steps together and lodsw


SELFMODIFY_SPAN_detailshift_3:
mov ax, ax
mov ax, ax


mov   word ptr cs:[SELFMODIFY_SPAN_ds_xstep+1 - OFFSET R_SPAN24_STARTMARKER_], ax





; CACHEDYSTEP lookup
mov   es, ss:[_cachedystep_segment_storage]
lods  word ptr es:[si]  ; todo both steps together and lodsw



SELFMODIFY_SPAN_detailshift_4:
mov ax, ax
mov ax, ax


mov   word ptr cs:[SELFMODIFY_SPAN_ds_ystep + 1 - OFFSET R_SPAN24_STARTMARKER_], ax



pop ax ; restore distance low word


distance_steps_ready:
;dx:ax is already distance going in

; dx:ax is distance
;     length = R_FixedMulLocal (distance,distscale[x1]);

mov   si, word ptr [bp - 0Ah]		; grab x1 (function input)... todo should be ax earlier.

shl   si, 1						; word lookup
mov   bx, si          ; dword lookup if we add them
mov   es, ds:[_distscale_segment_storage]
;todo bench without bx + si + 2 - sar again later etc.
push  dx   ; store distance high word in case needed for colormap
les   bx, dword ptr es:[bx + si]		; distscale low word
mov   cx, es                                   	; distscale high word

call R_FixedMulLocal24_


;	angle = MOD_FINE_ANGLE(viewangle_shiftright3+ xtoviewangle[x1]);
; ds_xfrac = viewx.w + R_FixedMulLocal(finecosine[angle], length );

xchg  bx, ax			; store low word of length (product result)in bx
mov   cx, dx			; store high word of length  (product result) in cx

les   ax, dword ptr ds:[_viewangle_shiftright3]
add   ax, word ptr es:[si]		; ax is unmodded fine angle.. si is a word lookup
and   ah, 01Fh			; MOD_FINE_ANGLE mod high bits
push  ax            ; store fineangle

xchg  bx, ax			; fineangle in BX, low word into AX

mov   di, ax			; backup low word to DX
mov   si, cx			; backup high word
    
;call FAR PTR FixedMul_ 
call FixedMulTrigCosineLocal_

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



mov   bx, word ptr ds:[_ds_y] ; already doubled for word ops

mov   es, ds:[_cachedxstep_segment_storage]
mov   dx, word ptr es:[bx]          ; xstep

mov   bx, word ptr [bp - 0Ah]      ; x1
shl   bx, 1                        ; word

SELFMODIFY_SPAN_and_detailshift_1:
mov   cx, 00702h 
; ch is detailshift vga plane count mask shifted 1
; cl is 2
xor   bh, bh
and   bl, ch ; vga plane word lookup



; todo stosw?
mov   word ptr cs:[_spanfunc_xfrac + bx - OFFSET R_SPAN24_STARTMARKER_], ax
add   bl, cl
and   bl, ch
add   ax, dx
mov   word ptr cs:[_spanfunc_xfrac + bx - OFFSET R_SPAN24_STARTMARKER_], ax
add   bl, cl
and   bl, ch
add   ax, dx
mov   word ptr cs:[_spanfunc_xfrac + bx - OFFSET R_SPAN24_STARTMARKER_], ax
add   bl, cl
and   bl, ch
add   ax, dx
mov   word ptr cs:[_spanfunc_xfrac + bx - OFFSET R_SPAN24_STARTMARKER_], ax




pop   bx              ; get fineangle
mov   cx, si					; prep length
xchg  ax, di					; prep length. store xfrac in di

;call FAR PTR FixedMul_ 
call FixedMulTrigSineLocal_

;    ds_yfrac = -viewy.w - R_FixedMulLocalWrapper(finesine[angle], length );

; let's instead add then take the negative of the whole

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


mov   bx, word ptr ds:[_ds_y] ; already doubled for word ops

mov   es, ds:[_cachedystep_segment_storage]
mov   dx, word ptr es:[bx]          ; ystep

mov   bx, word ptr [bp - 0Ah]      ; x1
shl   bx, 1                        ; word

SELFMODIFY_SPAN_and_detailshift_2:
mov   cx, 00702h 
; ch is detailshift vga plane count mask shifted 1
; cl is 2
xor   bh, bh
and   bl, ch ; vga plane word lookup



; todo stosw?
mov   word ptr cs:[_spanfunc_yfrac + bx - OFFSET R_SPAN24_STARTMARKER_], ax
add   bl, cl
and   bl, ch
add   ax, dx
mov   word ptr cs:[_spanfunc_yfrac + bx - OFFSET R_SPAN24_STARTMARKER_], ax
add   bl, cl
and   bl, ch
add   ax, dx
mov   word ptr cs:[_spanfunc_yfrac + bx - OFFSET R_SPAN24_STARTMARKER_], ax
add   bl, cl
and   bl, ch
add   ax, dx
mov   word ptr cs:[_spanfunc_yfrac + bx - OFFSET R_SPAN24_STARTMARKER_], ax



pop   ax  ; for stack consistency across branches, this pop is done here.

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

les    bx, dword ptr ds:[_planezlight]
xlat  byte ptr es:[bx]
; mov  al, byte ptr cs:[bx + _cs_zlight_offset]
colormap_ready:

mov   byte ptr cs:[SELFMODIFY_SPAN_set_colormap_index_jump+1 - OFFSET R_SPAN24_STARTMARKER_], al

; lcall SPANFUNC_FUNCTION_AREA_SEGMENT:SPANFUNC_PREP_OFFSET

call  R_DrawSpanPrep24_


pop   dx
pop   es
pop   di
pop   si
pop   cx
ret
ALIGN_MACRO	

SELFMODIFY_SPAN_fixedcolormap_1_TARGET:
SELFMODIFY_SPAN_fixedcolormap_2:
use_fixed_colormap:
mov   byte ptr cs:[SELFMODIFY_SPAN_set_colormap_index_jump+1 - OFFSET R_SPAN24_STARTMARKER_], 00

; lcall SPANFUNC_FUNCTION_AREA_SEGMENT:SPANFUNC_PREP_OFFSET

call  R_DrawSpanPrep24_


pop   dx
pop   es
pop   di
pop   si
pop   cx
ret  
ALIGN_MACRO	

generate_distance_steps:

    ; Register state (all not listed are junk/scratch):
    ; SS = FIXED_DS_SEGMENT
    ; BP = SPANSTART_SEGMENT
    ; SI = y << 1

    mov bx, SPANSTART_SEGMENT
    MOV DS, bx

    mov DS:[SI + ((CACHEDHEIGHT_SEGMENT - SPANSTART_SEGMENT) * 16)], AX
    mov bx, si  ; dword

IF COMPISA LE COMPILE_286
    push bp
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

    
    pop  bp ; restore BP...
    push ss
    pop  ds ; restore DS...

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


;R_DrawPlanes_

ALIGN_MACRO	
PROC   R_DrawPlanes24_ FAR
PUBLIC R_DrawPlanes24_


; ARGS none

; STACK

; bp - 0Eh planeheight hi
; bp - 0Ch ds_x2
; bp - 0Ah ds_x1
; bp - 8 visplaneoffset
; bp - 6 visplanesegment
; bp - 4 usedflatindex
; bp - 3 usedflatindex AND 3
; bp - 2 physindex

push  bx
push  cx
push  dx
push  si
push  di
push  bp
mov   bp, sp
xor   ax, ax
push  ax        ; bp - 2
push  ax        ; bp - 4
mov   dx, FIRST_VISPLANE_PAGE_SEGMENT
push  dx        ; bp - 6
push  ax        ; bp - 8
sub   sp, 6
; inline R_WriteBackSpanFrameConstants_
; get whole dword at the end here.


mov      al, byte ptr ds:[_lastvisplane]
mov      ah, SIZE VISPLANEHEADER_T
mul      ah
add      ax, OFFSET _visplaneheaders
mov      word ptr cs:[SELFMODIFY_SPAN_last_iter_compare+2 - OFFSET R_SPAN24_STARTMARKER_], ax


mov      al, byte ptr ds:[_skyflatnum]  ; todo self modify at a different layer once per level
mov      byte ptr cs:[SELFMODIFY_SPAN_skyflatnum + 2 - OFFSET R_SPAN24_STARTMARKER_], al

mov      ds, word ptr ds:[_BSP_CODE_SEGMENT_PTR]


mov   si, _BASEXSCALE_OFFSET_R_BSP
lodsw
mov   word ptr cs:[SELFMODIFY_SPAN_basexscale_lo_1+1 - OFFSET R_SPAN24_STARTMARKER_], ax
lodsw
mov   word ptr cs:[SELFMODIFY_SPAN_basexscale_hi_1+1 - OFFSET R_SPAN24_STARTMARKER_], ax

lodsw
mov   word ptr cs:[SELFMODIFY_SPAN_baseyscale_lo_1+1 - OFFSET R_SPAN24_STARTMARKER_], ax
lodsw
mov   word ptr cs:[SELFMODIFY_SPAN_baseyscale_hi_1+1 - OFFSET R_SPAN24_STARTMARKER_], ax

lodsw
mov   word ptr cs:[SELFMODIFY_SPAN_viewx_lo_1+1 - OFFSET R_SPAN24_STARTMARKER_], ax
lodsw
mov   word ptr cs:[SELFMODIFY_SPAN_viewx_hi_1+2 - OFFSET R_SPAN24_STARTMARKER_], ax

lodsw
mov   word ptr cs:[SELFMODIFY_SPAN_viewy_lo_1+1 - OFFSET R_SPAN24_STARTMARKER_], ax
lodsw
mov   word ptr cs:[SELFMODIFY_SPAN_viewy_hi_1+2 - OFFSET R_SPAN24_STARTMARKER_], ax

lodsw  ; viewz_shortheight
mov   word ptr cs:[SELFMODIFY_SPAN_viewz_13_3_1+1 - OFFSET R_SPAN24_STARTMARKER_], ax

mov   ax, ss
mov   ds, ax


mov   ax, word ptr ds:[_destview+0]
mov   word ptr cs:[SELFMODIFY_SPAN_destview_lo_1+1 - OFFSET R_SPAN24_STARTMARKER_], ax

mov   al, byte ptr ds:[_player + PLAYER_T.player_extralightvalue]
mov   byte ptr cs:[SELFMODIFY_SPAN_extralight_1+1 - OFFSET R_SPAN24_STARTMARKER_], al


mov   al, byte ptr ds:[_fixedcolormap]
test  al, al 
jne   do_span_fixedcolormap_selfmodify
mov   ax, 0c089h  ; nop
jmp   done_with_span_fixedcolormap_selfmodify
ALIGN_MACRO	

do_next_drawplanes_loop:	

add   word ptr cs:[SELFMODIFY_SPAN_drawplaneiter+1 - OFFSET R_SPAN24_STARTMARKER_], SIZE VISPLANEHEADER_T
add   word ptr [bp - 8], VISPLANE_BYTE_SIZE
jmp   SHORT drawplanes_loop
ALIGN_MACRO	

exit_drawplanes:
LEAVE_MACRO 
pop   di
pop   si
pop   dx
pop   cx
pop   bx
mov   word ptr cs:[(SELFMODIFY_SPAN_drawplaneiter+1) - OFFSET R_SPAN24_STARTMARKER_], OFFSET _visplaneheaders
retf   
ALIGN_MACRO	
do_sky_flat_draw:
; todo revisit params. maybe these can be loaded in R_DrawSkyPlaneCallHigh
les   bx, dword ptr [bp - 8] ; get visplane offset
mov   cx, es ; and segment
les   ax, dword ptr ds:[si + 4]
mov   dx, es
;call  [_R_DrawSkyPlaneCallHigh]
SELFMODIFY_SPAN_draw_skyplane_call:
call  dword ptr ds:[_R_DrawSkyPlane_addr]
add   word ptr cs:[SELFMODIFY_SPAN_drawplaneiter+1 - OFFSET R_SPAN24_STARTMARKER_], SIZE VISPLANEHEADER_T
add   word ptr [bp - 8], VISPLANE_BYTE_SIZE
jmp   SHORT drawplanes_loop

ALIGN_MACRO	
do_span_fixedcolormap_selfmodify:
mov   byte ptr cs:[SELFMODIFY_SPAN_fixedcolormap_2 + 5 - OFFSET R_SPAN24_STARTMARKER_], al
mov   ax, ((SELFMODIFY_SPAN_fixedcolormap_1_TARGET - SELFMODIFY_SPAN_fixedcolormap_1_AFTER) SHL 8) + 0EBh
; fall thru
done_with_span_fixedcolormap_selfmodify:
; modify instruction
mov   word ptr cs:[SELFMODIFY_SPAN_fixedcolormap_1 - OFFSET R_SPAN24_STARTMARKER_], ax

mov       ax, OFFSET _R_DrawSkyPlane_addr
cmp       byte ptr ds:[_screenblocks], 10
jge       setup_dynamic_skyplane
mov       ax, OFFSET _R_DrawSkyPlaneDynamic_addr
setup_dynamic_skyplane:
mov       word ptr cs:[SELFMODIFY_SPAN_draw_skyplane_call + 2 - OFFSET R_SPAN24_STARTMARKER_], ax





drawplanes_loop:
SELFMODIFY_SPAN_drawplaneiter:
mov   si, OFFSET _visplaneheaders ; get i value. this is at the start of the function so its hard to self modify. so we reset to 0 at the end of the function
SELFMODIFY_SPAN_last_iter_compare:
cmp   si, 01000h   ; todo self modify constant in drawplanes24
jae   exit_drawplanes




cmp   byte ptr ds:[si + VISPLANEHEADER_T.visplaneheader_dirty], 0
je    do_next_drawplanes_loop
mov   ax, word ptr ds:[si + VISPLANEHEADER_T.visplaneheader_minx]			; fetch visplane minx
cmp   ax, word ptr ds:[si + VISPLANEHEADER_T.visplaneheader_maxx]			; fetch visplane maxx
jg    do_next_drawplanes_loop

loop_visplane_page_check:
cmp   word ptr [bp - 8], VISPLANE_BYTES_PER_PAGE
jnb   check_next_visplane_page


; todo: DI is (mostly) unused here. Can probably be used to hold something usedful.

mov   bx, word ptr cs:[SELFMODIFY_SPAN_drawplaneiter+1 - OFFSET R_SPAN24_STARTMARKER_]

mov   cx, word ptr ds:[bx + VISPLANEHEADER_T.visplaneheader_piclight]
SELFMODIFY_SPAN_skyflatnum:
cmp   cl, 0
je    do_sky_flat_draw

do_nonsky_flat_draw:

mov   byte ptr cs:[SELFMODIFY_SPAN_lookuppicnum+2 - OFFSET R_SPAN24_STARTMARKER_], cl 
mov   al, ch
xor   ah, ah

SHIFT_MACRO sar ax LIGHTSEGSHIFT


SELFMODIFY_SPAN_extralight_1:
add   al, 0
cmp   al, LIGHTLEVELS
jb    lightlevel_in_range
mov   al, LIGHTLEVELS-1
lightlevel_in_range:
; ah is 0
; shift 7
xchg  al, ah
sar   ax, 1



mov   word ptr ds:[_planezlight], ax
;mov   word ptr ds:[_planezlight + 2], ZLIGHT_SEGMENT  ; this is static and set in memory.asm

mov   ax, FLATTRANSLATION_SEGMENT
mov   es, ax
mov   bl, cl
xor   bh, bh

mov   bl, byte ptr es:[bx]
mov   ax, FLATINDEX_SEGMENT
mov   es, ax

mov   al, byte ptr es:[bx]
; going to use di to hold flatunloaded
xor   di, di
cmp   al, 0ffh
jne   flat_loaded
mov   bx, di
loop_find_flat:
cmp   byte ptr ds:[bx + _allocatedflatsperpage], 4   ; if (allocatedflatsperpage[j]<4){
jl    found_page_with_empty_space
inc   bl
cmp   bl, NUM_FLAT_CACHE_PAGES
jge   found_flat_page_to_evict
jmp   loop_find_flat
ALIGN_MACRO	

check_next_visplane_page:
; do next visplane page
sub   word ptr [bp - 8], VISPLANE_BYTES_PER_PAGE
inc   byte ptr [bp - 2]
add   word ptr [bp - 6], 0400h
jmp   loop_visplane_page_check
ALIGN_MACRO	



found_page_with_empty_space:

mov   al, bl ; bl is usedflatindex
SHIFT_MACRO shl al 2


mov   ah, byte ptr ds:[bx + _allocatedflatsperpage]
add   al, ah
inc   byte ptr ds:[bx + _allocatedflatsperpage]
found_flat:
; al is usedflatindex
mov   di, FLATTRANSLATION_SEGMENT
mov   es, di
mov   bl, cl
xor   bh, bh

mov   bl, byte ptr es:[bx]
mov   di, FLATINDEX_SEGMENT
mov   es, di

; di already nonzero
;mov   di, 1 ; update flat unloaded

mov   byte ptr es:[bx], al	; flatindex[flattranslation[piclight.bytes.picnum]] = usedflatindex;

; check l2 cache next
flat_loaded:
; ah is already set above..
mov   ah, al
and   ah, 3
mov   word ptr [bp - 4], ax     ; store usedflatindex only once, along with AND 3 of it

; al is guaranteed usedflatindex...
; consider cwd mov dl, al
xor    ah, ah
mov    dx, ax

SHIFT_MACRO sar dl 2

; dl = flatcacheL2pagenumber
cmp   dl, byte ptr ds:[_currentflatpage+0]
je    in_flat_page_0

; check if L2 page is in L1 cache

cmp   dl, byte ptr ds:[_currentflatpage+1]
jne   not_in_flat_page_1
mov   cl, 1
jmp   SHORT update_l1_cache
ALIGN_MACRO	
found_flat_page_to_evict:


;call  R_EvictFlatCacheEMSPage_   ; al stores result..
jmp    do_evict_flatcache_ems_page
ALIGN_MACRO	
done_with_evict_flatcache_ems_page:
SHIFT_MACRO shl al 2

jmp   found_flat
ALIGN_MACRO	

not_in_flat_page_1:
cmp   dl, byte ptr ds:[_currentflatpage+2]
jne   not_in_flat_page_2
mov   cl, 2
jmp SHORT  update_l1_cache
ALIGN_MACRO	
not_in_flat_page_2:
cmp   dl, byte ptr ds:[_currentflatpage+3]
jne   not_in_flat_page_3
mov   cl, 3
jmp SHORT  update_l1_cache
ALIGN_MACRO	
not_in_flat_page_3:
; L2 page not in L1 cache. need to EMS remap

; doing word writes/reads instead of byte writes/reads when possible
mov   ch, byte ptr ds:[_lastflatcacheindicesused]
mov   ax, word ptr ds:[_lastflatcacheindicesused+1]
mov   cl, byte ptr ds:[_lastflatcacheindicesused+3]

mov   word ptr ds:[_lastflatcacheindicesused], cx
mov   word ptr ds:[_lastflatcacheindicesused+2], ax

mov   ax, dx

mov   bl, cl
xor   bh, bh   ; ugly... can i do cx above
mov   byte ptr ds:[bx + _currentflatpage], al
add   ax, FIRST_FLAT_CACHE_LOGICAL_PAGE

;call  Z_QuickMapFlatPage_
;	pageswapargs[pageswapargs_flatcache_offset + offset * PAGE_SWAP_ARG_MULT] = _EPR(page);
push  cx
push  si
shl   bx, 1
SHIFT_PAGESWAP_ARGS bx
; _EPR here
IFDEF COMP_CH
    add  ax, EMS_MEMORY_PAGE_OFFSET
ELSE
ENDIF
mov   word ptr ds:[_pageswapargs + (pageswapargs_flatcache_offset * 2) + bx], ax
Z_QUICKMAPAI4 pageswapargs_flatcache_offset_size INDEXED_PAGE_7000_OFFSET

pop   si
pop   cx


jmp  SHORT l1_cache_finished_updating
ALIGN_MACRO	
in_flat_page_0:
mov   cl, 0

update_l1_cache:
mov   ch, byte ptr ds:[_lastflatcacheindicesused]
cmp   ch, cl
je    l1_cache_finished_updating
mov   ah, byte ptr ds:[_lastflatcacheindicesused+1]
cmp   ah, cl
je    in_flat_page_1
mov   al, byte ptr ds:[_lastflatcacheindicesused+2]
cmp   al, cl
je    in_flat_page_2
mov   byte ptr ds:[_lastflatcacheindicesused+3], al
in_flat_page_2:
mov   byte ptr ds:[_lastflatcacheindicesused+2], ah
in_flat_page_1:
mov   word ptr ds:[_lastflatcacheindicesused], cx
l1_cache_finished_updating:
mov   al, byte ptr [bp - 4]
SHIFT_MACRO sar al 2

;cbw  


cmp       al, byte ptr ds:[_flatcache_l2_head]
jne       jump_to_flatcachemruL2
done_with_mruL2:


cmp   di, 0 ; di used to hold flatunlodaed
jnz   flat_is_unloaded
flat_not_unloaded:
; calculate ds_source_segment


;! todo use a single 16 element lookup instead of two four element ones.
; cl is flatcacheL1pagenumber 

; calculate flat page.
; 7000h + 400h * l1 pagenumber + 100h * (usedflatindex &3)
mov   al, cl
SHIFT_MACRO sal   al 2
add   al, byte ptr [bp - 3]
add   al, 070h

mov   byte ptr cs:[_ds_source_offset_span+3], al            ; low byte always zero!

; planeheight = labs(plheader->height - viewz.w);

mov   ax, word ptr ds:[si + VISPLANEHEADER_T.visplaneheader_height]

SELFMODIFY_SPAN_viewz_13_3_1:
sub   ax, 01000h
; ABS
cwd
xor   ax, dx
sub   ax, dx   

mov   word ptr [bp - 0Eh], ax
mov   ax, word ptr ds:[si + VISPLANEHEADER_T.visplaneheader_maxx]
mov   di, ax
les   bx, dword ptr [bp - 8]

mov   byte ptr es:[bx + di + 3], 0ffh
mov   si, word ptr ds:[si + VISPLANEHEADER_T.visplaneheader_minx]
mov   byte ptr es:[bx + si + 1], 0ffh
inc   ax

mov   word ptr cs:[SELFMODIFY_SPAN_comparestop+2 - OFFSET R_SPAN24_STARTMARKER_], ax ; set count value to be compared against in loop.

cmp   si, ax
jle   start_single_plane_draw_loop
jmp   do_next_drawplanes_loop
ALIGN_MACRO	

jump_to_flatcachemruL2:
jmp continue_flatcachemru
ALIGN_MACRO	

; flat is unloaded. load it in
flat_is_unloaded:

; flat cache page is 7000h + 400h * cl

push  cx
mov   ch, cl
xor   cl, cl
xor   bh, bh    ; for later

sal   cx, 1
sal   cx, 1   ; cx = 400h * cl 

add   cx, FLAT_CACHE_BASE_SEGMENT

mov   ax, FLATTRANSLATION_SEGMENT
mov   es, ax

SELFMODIFY_SPAN_lookuppicnum:
mov   al, byte ptr es:[00]    ; uses picnum from way above.

xor   ah, ah
add   ax, word ptr ds:[_firstflat]
mov   bl, byte ptr [bp - 3]     ; usedflatindex AND 3

add   bx, bx
mov   bx, word ptr ds:[bx + _MULT_4096]

call  dword ptr ds:[_W_CacheLumpNumDirect_addr]

;call  W_CacheLumpNumDirect_
pop   cx
jmp   flat_not_unloaded
ALIGN_MACRO	



start_single_plane_draw_loop:
; loop setup

single_plane_draw_loop:
; si is x, bx is plheader pointer. so adding si gets us plheader->top[x] etc.
les    bx, dword ptr [bp - 8]

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
mov   word ptr [bp - 0Ch], si
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
mov   word ptr ds:[_ds_y], di   ; predoubled for lookup
mov   word ptr [bp - 0Ah], ax   ; store ds_x1
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

;jmp exit_drawplanes

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
mov   word ptr ds:[_ds_y], di
mov   word ptr [bp - 0Ah], ax
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



ENDP



;PROC R_MarkL2FlatCacheMRU24_ NEAR


;	if (index == flatcache_l2_head) {
;		return;
;	}

continue_flatcachemru:
push      si




;	cache_node_t far* nodelist  = flatcache_nodes;

mov       dl, al
mov       bx, OFFSET _flatcache_nodes


;	prev = nodelist[index].prev;
;	next = nodelist[index].next;


cbw      

add       ax, ax
mov       si, ax
mov       ax, word ptr ds:[si + bx]

mov       dh, al ; back up

;	if (index == flatcache_l2_tail) {
;		flatcache_l2_tail = next;	
;	} else {
;		nodelist[prev].next = next;
;	}

cmp       dl, byte ptr ds:[_flatcache_l2_tail]
jne       index_not_tail

mov       byte ptr ds:[_flatcache_l2_tail], ah
jmp       flat_tail_check_done
ALIGN_MACRO	

index_not_tail:

mov       si, ax
and       si, 000FFh      ; blegh
sal       si, 1
mov       byte ptr ds:[si + bx + 1], ah

flat_tail_check_done:

;	// guaranteed to have a next. if we didnt have one, it'd be head but we already returned from that case.
;	nodelist[next].prev = prev;

mov       al, ah
cbw      

mov       si, ax
sal       si, 1

mov       byte ptr ds:[si + bx], dh
mov       al, dl

mov       si, ax
sal       si, 1

;	nodelist[index].prev = flatcache_l2_head;
;	nodelist[index].next = -1;

mov       al, byte ptr ds:[_flatcache_l2_head]
mov       byte ptr ds:[si + bx], al
mov       byte ptr ds:[si + bx + 1], 0FFh

mov       si, ax
sal       si, 1

;	nodelist[flatcache_l2_head].next = index;

mov       byte ptr ds:[si + bx + 1], dl

;	flatcache_l2_head = index;
mov       byte ptr ds:[_flatcache_l2_head], dl
exit_flatcachemru:
pop       si
jmp       done_with_mruL2

ENDP


;PROC R_EvictFlatCacheEMSPage24_ NEAR

ALIGN_MACRO	
do_evict_flatcache_ems_page:

push      bx
push      dx
push      si
mov       al, byte ptr ds:[_flatcache_l2_tail]
mov       dh, al
cbw      

;	evictedpage = flatcache_l2_tail;
mov       bx, OFFSET _flatcache_nodes
mov       si, ax        ; si gets evictedpage.

;	// all the other flats in this are cleared.
;	allocatedflatsperpage[evictedpage] = 1;
mov       byte ptr ds:[si + _allocatedflatsperpage], 1
sal       si, 1  ; now word lookup.

;	flatcache_l2_tail = flatcache_nodes[evictedpage].next;	// tail is nextmost

mov       dl, byte ptr ds:[si + bx + 1]         ; dl has flatcache_l2_tail
mov       byte ptr ds:[_flatcache_l2_tail], dl

;	flatcache_nodes[evictedpage].next = -1;
mov       byte ptr ds:[si + bx + 1], 0FFh

;	flatcache_nodes[evictedpage].prev = flatcache_l2_head;

mov       al, byte ptr ds:[_flatcache_l2_head]
mov       byte ptr ds:[si + bx + 0], al

;	flatcache_nodes[flatcache_l2_head].next = evictedpage;
mov       si, ax
sal       si, 1
mov       byte ptr ds:[si + bx + 1], dh

;	flatcache_nodes[flatcache_l2_tail].prev = -1;

mov       al, dl
mov       si, ax
sal       si, 1
mov       byte ptr ds:[si + bx], 0FFh


;	flatcache_l2_head = evictedpage;


mov       byte ptr ds:[_flatcache_l2_head], dh


mov       bx, FLATINDEX_SEGMENT
mov       ds, bx
mov       ah, dh
xor       si, si
mov       bx, -1
mov       dx, MAX_FLATS


;   for (i = 0; i < MAX_FLATS; i++){
;	   if ((flatindex[i] >> 2) == evictedpage){
;         flatindex[i] = 0xFF;
;   	}
;  	}
check_next_flat:
lodsb       ; si is always one in front because of lodsb...

SHIFT_MACRO shr       al 2
cmp       al, ah
je        erase_flat
continue_erasing_flats:
cmp       si, dx
jb        check_next_flat
mov       al, ah
mov       bx, ss
mov       ds, bx
pop       si
pop       dx
pop       bx
jmp       done_with_evict_flatcache_ems_page
ALIGN_MACRO	
;ret   

erase_flat:
mov       byte ptr ds:[si+bx], bl   ; bx is -1. this both writes FF and subtracts the 1 from si
jmp       continue_erasing_flats

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






mov      al, byte ptr ss:[_detailshift]
cmp      al, 1
je       do_detail_shift_one
jl       do_detail_shift_zero
jmp      do_detail_shift_two
ALIGN_MACRO	
do_detail_shift_zero:

mov     word ptr ds:[_spanfunc_outp + 0], 00201h 

mov      word ptr ds:[SELFMODIFY_SPAN_and_detailshift_1+1 - OFFSET R_SPAN24_STARTMARKER_], 00702h 
mov      word ptr ds:[SELFMODIFY_SPAN_and_detailshift_2+1 - OFFSET R_SPAN24_STARTMARKER_], 00702h 

mov      byte ptr ds:[SELFMODIFY_SPAN_set_plane_0+1], 1
mov      byte ptr ds:[SELFMODIFY_SPAN_compare_span_counter+2        - OFFSET R_SPAN24_STARTMARKER_], 3
mov      byte ptr ds:[SELFMODIFY_SPAN_detailshift_mainloopcount_2+2 - OFFSET R_SPAN24_STARTMARKER_], 4

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


mov      word ptr ds:[SELFMODIFY_SPAN_detailshift2minus_2+0 - OFFSET R_SPAN24_STARTMARKER_], ax  
mov      word ptr ds:[SELFMODIFY_SPAN_detailshift2minus_2+2 - OFFSET R_SPAN24_STARTMARKER_], ax  ; shl   ax, 1
mov      word ptr ds:[SELFMODIFY_SPAN_detailshift2minus_4+0 - OFFSET R_SPAN24_STARTMARKER_], ax  ; shl   ax, 1
mov      word ptr ds:[SELFMODIFY_SPAN_detailshift2minus_4+2 - OFFSET R_SPAN24_STARTMARKER_], ax  ; shl   ax, 1
mov ax, 0FAD1h  ; shr   dx, 1
mov      word ptr ds:[SELFMODIFY_SPAN_detailshift2minus_1+0 - OFFSET R_SPAN24_STARTMARKER_], ax  
mov      word ptr ds:[SELFMODIFY_SPAN_detailshift2minus_1+2 - OFFSET R_SPAN24_STARTMARKER_], ax  ; sar   dx, 1
mov ax, 0F9d1h  ; sar   cx, 1
mov      word ptr ds:[SELFMODIFY_SPAN_detailshift2minus_3+0 - OFFSET R_SPAN24_STARTMARKER_], ax  
mov      word ptr ds:[SELFMODIFY_SPAN_detailshift2minus_3+2 - OFFSET R_SPAN24_STARTMARKER_], ax  ; sar   cx, 1



jmp     done_with_detailshift
ALIGN_MACRO	
do_detail_shift_one:
mov     word ptr ds:[_spanfunc_outp + 0],  3 + (12 SHL 8)
mov      word ptr ds:[SELFMODIFY_SPAN_and_detailshift_1+1 - OFFSET R_SPAN24_STARTMARKER_], 00302h 
mov      word ptr ds:[SELFMODIFY_SPAN_and_detailshift_2+1 - OFFSET R_SPAN24_STARTMARKER_], 00302h 

mov      byte ptr ds:[SELFMODIFY_SPAN_set_plane_0+1], 3

mov      byte ptr ds:[SELFMODIFY_SPAN_compare_span_counter+2        - OFFSET R_SPAN24_STARTMARKER_], 1
mov      byte ptr ds:[SELFMODIFY_SPAN_detailshift_mainloopcount_2+2 - OFFSET R_SPAN24_STARTMARKER_], 2



; sal   ax, 1 ; 0E0D1h
; rcl   dx, 1 ; 0D2D1h


mov      ax, 0E0D1h
mov      word ptr ds:[SELFMODIFY_SPAN_detailshift_1+0 - OFFSET R_SPAN24_STARTMARKER_], ax
mov      word ptr ds:[SELFMODIFY_SPAN_detailshift_2+0 - OFFSET R_SPAN24_STARTMARKER_], ax
mov      word ptr ds:[SELFMODIFY_SPAN_detailshift_3+0 - OFFSET R_SPAN24_STARTMARKER_], ax
mov      word ptr ds:[SELFMODIFY_SPAN_detailshift_4+0 - OFFSET R_SPAN24_STARTMARKER_], ax

mov      ax, 0D2D1h





mov      word ptr ds:[SELFMODIFY_SPAN_detailshift2minus_1+0 - OFFSET R_SPAN24_STARTMARKER_], 0FAD1h  ; sar   dx, 1
mov      word ptr ds:[SELFMODIFY_SPAN_detailshift2minus_3+0 - OFFSET R_SPAN24_STARTMARKER_], 0F9D1h  ; sar   cx, 1
mov      ax, 0E0D1h
mov      word ptr ds:[SELFMODIFY_SPAN_detailshift2minus_2+0 - OFFSET R_SPAN24_STARTMARKER_], ax  ; shl   ax, 1
mov      word ptr ds:[SELFMODIFY_SPAN_detailshift2minus_4+0 - OFFSET R_SPAN24_STARTMARKER_], ax  ; shl   ax, 1

mov   ax, 0c089h  ; nop
mov      word ptr ds:[SELFMODIFY_SPAN_detailshift_1+2 - OFFSET R_SPAN24_STARTMARKER_], ax
mov      word ptr ds:[SELFMODIFY_SPAN_detailshift_2+2 - OFFSET R_SPAN24_STARTMARKER_], ax
mov      word ptr ds:[SELFMODIFY_SPAN_detailshift_3+2 - OFFSET R_SPAN24_STARTMARKER_], ax
mov      word ptr ds:[SELFMODIFY_SPAN_detailshift_4+2 - OFFSET R_SPAN24_STARTMARKER_], ax

mov      word ptr ds:[SELFMODIFY_SPAN_detailshift2minus_1+2 - OFFSET R_SPAN24_STARTMARKER_], ax
mov      word ptr ds:[SELFMODIFY_SPAN_detailshift2minus_2+2 - OFFSET R_SPAN24_STARTMARKER_], ax
mov      word ptr ds:[SELFMODIFY_SPAN_detailshift2minus_3+2 - OFFSET R_SPAN24_STARTMARKER_], ax
mov      word ptr ds:[SELFMODIFY_SPAN_detailshift2minus_4+2 - OFFSET R_SPAN24_STARTMARKER_], ax

jmp     done_with_detailshift
ALIGN_MACRO	

do_detail_shift_two:

mov      word ptr ds:[SELFMODIFY_SPAN_and_detailshift_1+1 - OFFSET R_SPAN24_STARTMARKER_], 00102h 
mov      word ptr ds:[SELFMODIFY_SPAN_and_detailshift_2+1 - OFFSET R_SPAN24_STARTMARKER_], 00102h 

mov      byte ptr ds:[_spanfunc_outp + 0], 15 ; technically this never has to be changed 
mov      byte ptr ds:[SELFMODIFY_SPAN_set_plane_0+1], 15

mov      byte ptr ds:[SELFMODIFY_SPAN_compare_span_counter+2        - OFFSET R_SPAN24_STARTMARKER_], 0
mov      byte ptr ds:[SELFMODIFY_SPAN_detailshift_mainloopcount_2+2 - OFFSET R_SPAN24_STARTMARKER_], 1


mov      ax, 0c089h  ; nop


mov      word ptr ds:[SELFMODIFY_SPAN_detailshift_1+0 - OFFSET R_SPAN24_STARTMARKER_], ax
mov      word ptr ds:[SELFMODIFY_SPAN_detailshift_1+2 - OFFSET R_SPAN24_STARTMARKER_], ax
mov      word ptr ds:[SELFMODIFY_SPAN_detailshift_2+0 - OFFSET R_SPAN24_STARTMARKER_], ax
mov      word ptr ds:[SELFMODIFY_SPAN_detailshift_2+2 - OFFSET R_SPAN24_STARTMARKER_], ax
mov      word ptr ds:[SELFMODIFY_SPAN_detailshift_3+0 - OFFSET R_SPAN24_STARTMARKER_], ax
mov      word ptr ds:[SELFMODIFY_SPAN_detailshift_3+2 - OFFSET R_SPAN24_STARTMARKER_], ax
mov      word ptr ds:[SELFMODIFY_SPAN_detailshift_4+0 - OFFSET R_SPAN24_STARTMARKER_], ax
mov      word ptr ds:[SELFMODIFY_SPAN_detailshift_4+2 - OFFSET R_SPAN24_STARTMARKER_], ax





; two minus

mov      word ptr ds:[SELFMODIFY_SPAN_detailshift2minus_1+0 - OFFSET R_SPAN24_STARTMARKER_], ax
mov      word ptr ds:[SELFMODIFY_SPAN_detailshift2minus_1+2 - OFFSET R_SPAN24_STARTMARKER_], ax
mov      word ptr ds:[SELFMODIFY_SPAN_detailshift2minus_2+0 - OFFSET R_SPAN24_STARTMARKER_], ax
mov      word ptr ds:[SELFMODIFY_SPAN_detailshift2minus_2+2 - OFFSET R_SPAN24_STARTMARKER_], ax
mov      word ptr ds:[SELFMODIFY_SPAN_detailshift2minus_3+0 - OFFSET R_SPAN24_STARTMARKER_], ax
mov      word ptr ds:[SELFMODIFY_SPAN_detailshift2minus_3+2 - OFFSET R_SPAN24_STARTMARKER_], ax
mov      word ptr ds:[SELFMODIFY_SPAN_detailshift2minus_4+0 - OFFSET R_SPAN24_STARTMARKER_], ax
mov      word ptr ds:[SELFMODIFY_SPAN_detailshift2minus_4+2 - OFFSET R_SPAN24_STARTMARKER_], ax

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

END

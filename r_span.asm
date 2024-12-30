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
	.MODEL  medium
INCLUDE defs.inc
INSTRUCTION_SET_MACRO

;=================================

.CODE



MAXLIGHTZ                      = 0080h
MAXLIGHTZ_UNSHIFTED            = 0800h



; todo: eventually call these directly... 
;EXTRN R_MarkL2FlatCacheLRU_:PROC
;EXTRN Z_QuickMapFlatPage_:PROC
;EXTRN W_CacheLumpNumDirect_:PROC
;EXTRN Z_QuickMapVisplanePage_:PROC
;EXTRN R_EvictFlatCacheEMSPage_:PROC




DS_XFRAC    = _ss_variable_space+ 004h
DS_YFRAC    = _ss_variable_space+ 008h
DS_XSTEP    = _ss_variable_space+ 00Ch
DS_YSTEP    = _ss_variable_space+ 010h


FIRST_FLAT_CACHE_LOGICAL_PAGE = 026h


; NOTE: cs:offset stuff for self modifying code must be zero-normalized
;  (subtract offset of R_DrawSpan) because this code is being moved to
; segment:0000 at runtime and the cs offset stuff is absolute, not relative.



;
; R_DrawSpan
;
PROC  R_DrawSpan_ 
PUBLIC  R_DrawSpan_ 
	
; nead to include these 2 instructions, and need a function label to include this...

no_pixels:
jmp   do_span_loop

PROC  R_DrawSpanActual_
PUBLIC  R_DrawSpanActual_ 

; stack vars
 
; _ss_variable_space
;
; 00h i (outer loop counter)
; 04h ds_xfrac
; 08h ds_yfrac
; 0Ch ds_xstep
; 10h ds_ystep


; todo move this into before the per-pixel rollout.

cli 									; disable interrupts

; fixed_t x32step = (ds_xstep << 6);

; todo move this logic out into prep function? 
; todo LES something useful?
MOV   ES, ds:[_spanfunc_jump_segment_storage]

mov   al, byte ptr ds:[_spanfunc_main_loop_count]             
;; todo is this smaller with DI/stosb stuff?
mov   byte ptr es:[((SELFMODIFY_SPAN_compare_span_counter+2) -R_DrawSpan_ + ((SPANFUNC_FUNCTION_AREA_SEGMENT - SPANFUNC_JUMP_LOOKUP_SEGMENT) * 16)  )], al     ; set loop end constraint
mov   byte ptr es:[((SELFMODIFY_SPAN_set_span_counter+1)     -R_DrawSpan_ + ((SPANFUNC_FUNCTION_AREA_SEGMENT - SPANFUNC_JUMP_LOOKUP_SEGMENT) * 16)  )], 0      ; set loop increment value





; main loop start (i = 0, 1, 2, 3)

xor   bx, bx						; zero out cx as loopcount

span_i_loop_repeat:

xor   ah, ah

mov   al, byte ptr ds:[_spanfunc_inner_loop_count + bx]
; es is already pre-set..
inc   byte ptr es:[((SELFMODIFY_SPAN_set_span_counter+1)-R_DrawSpan_ + ((SPANFUNC_FUNCTION_AREA_SEGMENT - SPANFUNC_JUMP_LOOKUP_SEGMENT) * 16)  )]					; increment loop counter


test  al, al

; is count < 0? if so skip this loop iter

jl   no_pixels			; todo this so it doesnt loop in both cases

;       modify the jump for this iteration (self-modifying code)
sal   AL, 1					; convert index to  a word lookup index
xchg  ax, SI

; outp to plane only if there was a pixel to draw
mov   al, byte ptr ds:[_spanfunc_outp + bx]
mov   dx, SC_DATA						; outp 1 << i
out   dx, al


lods  WORD PTR ES:[SI]	

mov  WORD PTR es:[((SPANFUNC_JUMP_OFFSET+1)-R_DrawSpan_ + ((SPANFUNC_FUNCTION_AREA_SEGMENT - SPANFUNC_JUMP_LOOKUP_SEGMENT) * 16)  )], ax;

; 		dest = destview + ds_y * 80 + dsp_x1;
sal   bx, 1
mov   ax, word ptr ds:[_spanfunc_prt + bx]
mov   DI, word ptr ds:[_spanfunc_destview_offset + bx]  ; destview offset precalculated..


;		xfrac.w = basex = ds_xfrac + ds_xstep * prt;

CWD   				; extend sign into DX

;  DX:AX contains sign extended prt. 
;  probably dont really need this. can test ax and jge

mov   si, ax						; temporarily store dx:ax into es:si
mov   es, dx						; store sign bits (dx) in es
mov   bx, ax
mov   cx, dx						; also copy sign bits to cx
mov   ax, word ptr ds:[DS_XSTEP]
mov   dx, word ptr ds:[DS_XSTEP + 2]

; inline i4m
; DX:AX * CX:BX,  CX is 0000 or FFFF
 		xchg    ax,bx           ; swap low(M1) and low(M2)
        ; todo get rid of this push/pop..
		push    ax              ; save low(M2)
        xchg    ax,dx           ; exchange low(M2) and high(M1)
        or      ax,ax           ; if high(M1) non-zero
        je skiphigh11
          mul   dx              ; - low(M2) * high(M1)
        skiphigh11:                  ; endif
        xchg        ax,cx           ; save that in cx, get high(M2)
        test 	    ax,ax           ; if high(M2) non-zero
        je  skiphigh12              ; then
          sub   ax,bx              ; - high(M2) * low(M1)

;        xchg    ax,cx           ; save that in cx, get high(M2)
;        or      ax,ax           ; if high(M2) non-zero
;        je skiphigh12              ; then
;          mul   bx              ; - high(M2) * low(M1)
;          add   cx,ax           ; - add to total
        skiphigh12:                  ; endif
        pop     ax              ; restore low(M2)
        mul     bx              ; low(M2) * low(M1)
        add     dx,cx           ; add previously computed high part

;	continuing	xfrac.w = basex = ds_xfrac + ds_xstep * prt;
;	DX:AX contains ds_xstep * prt


add   ax, word ptr ds:[DS_XFRAC]	; load _ds_xfrac
mov   cx, es					; retrieve prt sign bits

adc   dx, word ptr ds:[DS_XFRAC + 2]  ; ; ds_xfrac + ds_xstep * prt high bits

mov   dh, dl
mov   dl, ah
mov   es, dx  ; store mid 16 bits of x_frac.w
mov   bx, si

mov   ax, word ptr ds:[DS_YSTEP]
mov   dx, word ptr ds:[DS_YSTEP + 2]


;		yfrac.w = basey = ds_yfrac + ds_ystep * prt;

; inline i4m
; DX:AX * CX:BX,  CX is 0000 or FFFF

 		xchg    ax,bx           ; swap low(M1) and low(M2)
        push    ax              ; save low(M2)
        xchg    ax,dx           ; exchange low(M2) and high(M1)
        or      ax,ax           ; if high(M1) non-zero
        je skiphigh21              ; then
          mul   dx              ; - low(M2) * high(M1)
        skiphigh21:                  ; endif
        xchg        ax,cx           ; save that in cx, get high(M2)
        test 	    ax,ax           ; if high(M2) non-zero
        je  skiphigh22              ; then
          sub   ax,bx              ; - high(M2) * low(M1)

        skiphigh22:                  ; endif
        pop     ax              ; restore low(M2)
        mul     bx              ; low(M2) * low(M1)
        add     dx,cx           ; add previously computed high part

;	continuing:	yfrac.w = basey = ds_yfrac + ds_ystep * prt;
; dx:ax contains ds_ystep * prt

; add 32 bits of ds_yfrac
mov   bx, ax
add   bx, word ptr ds:[DS_YFRAC]	; load ds_yfrac
adc   dx, word ptr ds:[DS_YFRAC + 2]

;	xfrac16.hu = xfrac.wu >> 8;


;	yfrac16.hu = yfrac.wu >> 10;

mov bl, bh
mov bh, dl   ; shift 8

sar dh, 1    ; shift two more
rcr bx, 1
sar dh, 1
rcr bx, 1    ; yfrac16 in bx


; shift 8, yadder in dh?

mov dx, es   ;  load mid 16 bits of x_frac.w


;	xadder = ds_xstep >> 6; 

mov   ax, word ptr ds:[DS_XSTEP]
mov   cx, word ptr ds:[DS_XSTEP + 2]


; quick shift 6
rol   ax, 1
rcl   cl, 1
rol   ax, 1
rcl   cl, 1

mov   al, ah
mov   ah, cl

; do loop setup here?

mov cl, byte ptr ds:[_detailshift]
shr ax, cl			; shift x_step by pixel shift

mov   word ptr ds:[_ss_variable_space], ax	; store x_adder

;	yadder = ds_ystep >> 8; // lopping off bottom 16 , but multing by 4.

mov   ax, word ptr ds:[DS_YSTEP + 1]



shr   ax, cl			; shift y_step by pixel shift
mov   word ptr ds:[_ss_variable_space + 2], ax	; y_adder



mov   es, word ptr ds:[_destview + 2]	; retrieve destview segment

; stack shenanigans. swap adders and sp/bp
; todo - this has got to be able to be improved somehow?

xchg  ds:[_ss_variable_space], sp             ;  store SP and load x_adder
xchg  ds:[_ss_variable_space+2], bp			  ;   store BP and load y_adder

mov   cx, bx  ; yfrac16
lds   bx, dword ptr ds:[_ds_source_segment-2] 		; ds:si is ds_source. BX is pulled in by lds as a constant 
;mov   bx, DRAWSPAN_BX_OFFSET

; we have a safe memory space declared in near variable space to put sp/bp values
; they meanwhile hold x_adder/y_adder and we juggle the two
; due to openwatcom compilation, SS = DS so we can use SS as if it were DS to address the var safely



xor   ah, ah

 
SPANFUNC_JUMP_OFFSET:
jmp span_i_loop_done         ; relative jump to be modified before function is called




; 89 C8       mov   ax, cx
; 21 D8       and   ax, bx
; 80 E6 3F    and   dh, 0x3f
; 00 F0       add   al, dh
; 97          xchg  ax, di

; alternate idea. one cycle slower and same byte count.
; cant we somehow make use of xchg and al, 3fh at the same time?

DRAW_SINGLE_SPAN_PIXEL MACRO 
mov   al, dh
and   al, 3fh
mov   si, cx
and   si, bx
add   si, ax
lods  BYTE PTR ds:[si]
xlat  BYTE PTR cs:[bx]       ; before calling this function we already set CS to the correct segment..
stos  BYTE PTR es:[di]       ;
add   dx, sp
add   cx, bp

ENDM

REPT 79
    DRAW_SINGLE_SPAN_PIXEL
endm

; final pixel

mov   al, dh
and   al, 3fh
mov   si, cx
and   si, bx
add   si, ax
lods  BYTE PTR ds:[si]
xlat  BYTE PTR cs:[bx]       ; before calling this function we already set CS to the correct segment..
stos  BYTE PTR es:[di]       ;


 
 

; restore stack
mov   ax, ss					;   SS is DS in this watcom memory model so we use that to restore DS
mov   ds, ax
xchg  ds:[_ss_variable_space], sp             ;  store SP and load x_adder
xchg  ds:[_ss_variable_space+2], bp			  ;   store BP and load y_adder

do_span_loop:

SELFMODIFY_SPAN_set_span_counter:
mov   bx, 0

; loop if i < loopcount. note we can overwrite this with self modifying coe
SELFMODIFY_SPAN_compare_span_counter:
cmp   bl, 4
jge    span_i_loop_done

MOV   ES, ds:[_spanfunc_jump_segment_storage]

jmp   span_i_loop_repeat
span_i_loop_done:


sti								; reenable interrupts

retf  


ENDP




;
; R_DrawSpanPrep
;
	
PROC  R_DrawSpanPrep_ NEAR
PUBLIC  R_DrawSpanPrep_ 

 
 ;  	uint16_t baseoffset = FP_OFF(destview) + dc_yl_lookup[ds_y];

; predoubles _ds_y for lookup
 les   bx, dword ptr ds:[_ds_y]
 ;add   bx, bx
 mov   ax, word ptr ds:[_destview]			; get FP_OFF(destview)
 mov   dx, word ptr es:[bx]				; get dc_yl_lookup[ds_y]

 add   dx, ax							; dx is baseoffset
 mov   es, word ptr ds:[_ds_x1]			; es holds ds_x1
	
; int8_t   shiftamount = (2-detailshift);
 mov   bh, byte ptr ds:[_detailshift2minus]		; get shiftamount in bh
 xor   bl, bl							; zero out bl. use it as loop counter/ i
 
 mov   word ptr ds:[_ss_variable_space], dx			; store base view offset
 
; todo the following  feels like extraneous register juggling, reexamine

 spanfunc_arg_setup_loop_start:
 mov   al, bl							; al holds loop counter
 mov   dx, es							; get ds_x1
 CBW  									; zero out ah
 mov   cl, bh							; move shiftamount to cl

;		int16_t dsp_x1 = (ds_x1 - i) >> shiftamount;
 sub   dx, ax							; subtract i 
 sar   dx, cl							; shift

; 		int16_t dsp_x2 = (ds_x2 - i) >> shiftamount;


 mov   di, word ptr ds:[_ds_x2]			; cx holds ds_x2
 sub   di, ax							; subtract i
 mov   si, ax							; put i in si
 
 mov   ax, dx							; copy dsp_x1 to ax
 
 shl   ax, cl							; shift dsp_x1 left
 sar   di, cl							; shift ds_x2 right. di = dsp_x2
 mov   cx, di							; store dsp_x2 in cx
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
 
;     cx has dsp_x2
 sub   cx, dx							; cx is countp

 mov   byte ptr [si + _spanfunc_inner_loop_count], cl  ; store it
 test  cx, cx										   ; if negative then loop
 jl    spanfunc_arg_setup_iter_done
 mov   cl, bh										   ; move shiftamount to cl
 
; 		spanfunc_prt[i] = (dsp_x1 << shiftamount) - ds_x1 + i;
;		spanfunc_destview_offset[i] = baseoffset + dsp_x1;

 
 mov   ax, dx										   ; move dsp_x1 to ax
 shl   ax, cl										   ; shift dsp_x1 left
 sub   ax, di										   ; subtract ds_x1
 add   ax, si										   ; add i, prt is calculated
 add   si, si										   ; double i for word lookup index
 add   dx, word ptr ds:[_ss_variable_space]						   ; dsp_x1 + base view offset
 mov   word ptr [si + _spanfunc_prt], ax			   ; store prt
 mov   word ptr [si + _spanfunc_destview_offset], dx   ; store view offset
 
 spanfunc_arg_setup_iter_done:
 
 inc   bl
 cmp   bl, byte ptr ds:[_spanfunc_main_loop_count]
 jl    spanfunc_arg_setup_loop_start
 
 spanfunc_arg_setup_complete:

 ; calculate desired cs:ip for far jump

 mov   al, byte ptr ds:[_ds_colormap_index]
 test  al, al									; check _ds_colormap_index
 jne    ds_colormap_nonzero


 ; easy address calculation
 
; 		uint16_t cs_base = ds_colormap_segment - cs_source_segment_offset;
;		uint16_t callfunc_offset = colormaps_spanfunc_off_difference + cs_source_offset;
;		dynamic_callfunc  =       ((void    (__far *)(void))  (MK_FP(cs_base, callfunc_offset)));

; call static address with static colormap.

db 09Ah
dw DRAWSPAN_CALL_OFFSET + (R_DrawSpanActual_ - R_DrawSpan_)
dw (COLORMAPS_SEGMENT - 0FCh)

 ret  
 ds_colormap_nonzero:									; if ds_colormap_index is 0
  
 
 ; colormap not zero. need to offset cs etc by its address

 ;		uint16_t ds_colormap_offset = ds_colormap_index << 8;
;		uint16_t ds_colormap_shift4 = ds_colormap_index << 4;
	 	
;		uint16_t cs_base = ds_colormap_segment - cs_source_segment_offset + ds_colormap_shift4;
;		uint16_t callfunc_offset = colormaps_spanfunc_off_difference + cs_source_offset - ds_colormap_offset;
;		dynamic_callfunc  =       ((void    (__far *)(void))  (MK_FP(cs_base, callfunc_offset)));
 
 mov   ah, al
 xor   al, al
 mov   bx, DRAWSPAN_CALL_OFFSET + (R_DrawSpanActual_ - R_DrawSpan_)
 sub   bx, ax
 IF COMPILE_INSTRUCTIONSET GE COMPILE_186
 shr   ax, 4
 ELSE
 shr   ax, 1
 shr   ax, 1
 shr   ax, 1
 shr   ax, 1
 ENDIF
 add   ax, (COLORMAPS_SEGMENT - 0FCh)

 
mov   word ptr ds:[_func_farcall_scratch_addr+0], bx				; setup dynamic call offset
mov   word ptr ds:[_func_farcall_scratch_addr+2], ax				; setup dynamic call segment

db 0FFh  ; lcall[addr]
db 01Eh  ;
dw _func_farcall_scratch_addr


 ret  

ENDP







PROC R_FixedMulTrigLocal_
PUBLIC R_FixedMulTrigLocal_

; DX:AX  *  CX:BX
;  0  1   2  3

; AX * CX:BX
; The difference between FixedMulTrig and FixedMul1632:
; fine sine/cosine lookup tables are -65535 to 65535, so 17 bits. 
; technically, this resembles 16 * 32 with sign extend, except we cannot use CWD to generate the high 16 bits.
; So those sign bits which contain bit 17, sign extended must be stored somewhere cannot be regenerated via CWD
; we basically take the above function and shove sign bits in DS for storage and regenerate DS from SS upon return
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

; AX is param 1 (segment)
; DX is param 2 (fineangle or lookup)
; CX:BX is value 2




push  si

; lookup the fine angle

sal dx, 1
sal dx, 1   ; DWORD lookup index
mov si, dx

mov ds, ax  ; cosine/sine segment in ds
lodsw
mov  es, ax
lodsw
mov  dx, ax ; store sign bits in DX

AND AX, BX  ; S0*BX
NEG AX
MOV SI, AX  ; SI stores hi word return

mov AX, DX  ; restore sign bits from dx

AND  AX, CX    ; DX*CX
NEG  AX
add  SI, AX    ; low word result into high word return
; use DX copy of sign bits later..

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

PROC R_FixedMulLocal_
PUBLIC R_FixedMulLocal_

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

go_generate_values:
jmp   generate_distance_steps

;
; R_MapPlane_
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

PROC  R_MapPlane_ NEAR
PUBLIC  R_MapPlane_ 

push  cx
push  si
push  di
push  es
push  dx
push  bp
mov   bp, sp


; this is all done in R_DrawPlanes before the call now
;xor   ah, ah
;mov   word ptr ds:[_ds_y], ax
;mov   word ptr ds:[_ds_x1], dx
;mov   word ptr ds:[_ds_x2], si

mov  si, di
; si is x * 4
mov   es, ds:[_cachedheight_segment_storage]

mov   ax, word ptr ds:[_planeheight]
mov   dx, word ptr ds:[_planeheight + 2]
; TODO: do this shl outside of the function. borrow from es:di lookup's di
shl   si, 1
; CACHEDHEIGHT LOOKUP

cmp   ax, word ptr es:[si] ; compare low word
jne   go_generate_values
use_cached_values:

cmp   dx, word ptr es:[si+2]
jne   go_generate_values	; comparing high word


; CACHED DISTANCE lookup

mov   ax, word ptr es:[si + (( CACHEDDISTANCE_SEGMENT - CACHEDHEIGHT_SEGMENT) * 16)]
mov   dx, word ptr es:[si + 2 + (( CACHEDDISTANCE_SEGMENT - CACHEDHEIGHT_SEGMENT) * 16)]

; CACHEDXSTEP lookup. move these into temporary variable space

mov   bx, ds
mov   es, bx
mov   ds, ds:[_cachedxstep_segment_storage]
mov   di, DS_XSTEP
movsw       ; DS_XSTEP
movsw       ; DS_XSTEP + 2
sub   si, 4
; CACHEDYSTEP lookup
mov   ds, ss:[_cachedystep_segment_storage]
movsw       ; DS_YSTEP
movsw       ; DS_YSTEP + 2

;restore ds. es, si etc dont materr.
mov   ds, bx

distance_steps_ready:
;dx:ax is already distance going in

; dx:ax is y_step
;     length = R_FixedMulLocal (distance,distscale[x1]);

mov   si, word ptr ds:[_ds_x1]		; grab x2 (function input)

shl   si, 1						; word lookup
mov   bx, si          ; dword lookup if we add them
mov   es, ds:[_distscale_segment_storage]

push  dx   ; store distance high word in case needed for colormap
mov   cx, word ptr es:[bx + si + 2]	; distscale high word
mov   bx, word ptr es:[bx + si]		; distscale low word

;call FAR PTR FixedMul_ 
call R_FixedMulLocal_


;	angle = MOD_FINE_ANGLE(viewangle_shiftright3+ xtoviewangle[x1]);
; ds_xfrac = viewx.w + R_FixedMulLocal(finecosine[angle], length );

xchg  bx, ax			; store low word of length (product result)in bx
mov   cx, dx			; store high word of length  (product result) in cx

les   ax, dword ptr ds:[_viewangle_shiftright3]
add   ax, word ptr es:[si]		; ax is unmodded fine angle.. si is a word lookup
and   ah, 01Fh			; MOD_FINE_ANGLE mod high bits
push  ax            ; store fineangle

xchg  dx, ax			; fineangle in DX
mov   ax, FINECOSINE_SEGMENT

mov   di, bx			; backup low word to DX
mov   si, cx			; backup high word

;call FAR PTR FixedMul_ 
call R_FixedMulTrigLocal_

;    ds_yfrac = -viewy.w - R_FixedMulLocal(finesine[angle], length );

add   ax, word ptr ds:[_viewx]
adc   dx, word ptr ds:[_viewx+2]
mov   word ptr ds:[DS_XFRAC], ax
mov   word ptr ds:[DS_XFRAC+2], dx

mov   ax, FINESINE_SEGMENT
pop   dx              ; get fineangle
mov   cx, si					; prep length
mov   bx, di					; prep length

;call FAR PTR FixedMul_ 
call R_FixedMulTrigLocal_

;    ds_yfrac = -viewy.w - R_FixedMulLocalWrapper(finesine[angle], length );

; let's instead add then take the negative of the whole

; add viewy
add   ax, word ptr ds:[_viewy]
adc   dx, word ptr ds:[_viewy+2]
; take negative of the whole
; apparently this is how you neg a dword. 
neg   dx
neg   ax
; i dont understand why this is here but the compiler did this. it works with or without, 
; probably too tiny an error to be visibly noticable?
sbb   dx, 0

mov   word ptr ds:[DS_YFRAC], ax
mov   word ptr ds:[DS_YFRAC+2], dx


; 	if (fixedcolormap) {

cmp   byte ptr ds:[_fixedcolormap], 0
jne   use_fixed_colormap
; 		index = distance >> LIGHTZSHIFT;
pop   ax
IF COMPILE_INSTRUCTIONSET GE COMPILE_186
sar   ax, 4
ELSE
sar   ax, 1
sar   ax, 1
sar   ax, 1
sar   ax, 1
ENDIF
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
colormap_ready:
;sar al, 1
;sar al, 1
mov   byte ptr ds:[_ds_colormap_index], al

; lcall SPANFUNC_FUNCTION_AREA_SEGMENT:SPANFUNC_PREP_OFFSET

call  R_DrawSpanPrep_

LEAVE_MACRO


pop   dx
pop   es
pop   di
pop   si
pop   cx
ret

use_fixed_colormap:
mov   al, byte ptr ds:[_fixedcolormap]
; todo remove this and use proper colormap...
; has to be shr for 128 case...
shr   al, 1
shr   al, 1
mov   byte ptr ds:[_ds_colormap_index], al

; lcall SPANFUNC_FUNCTION_AREA_SEGMENT:SPANFUNC_PREP_OFFSET

call  R_DrawSpanPrep_

LEAVE_MACRO

pop   dx
pop   es
pop   di
pop   si
pop   cx
ret  

generate_distance_steps:

; es = 5000h  (CACHEDHEIGHT_SEGMENT)
; dx:ax = planeheight segment
; note: es wrecked by function calls to r_fixedmullocal...

mov   word ptr es:[si], ax
mov   word ptr es:[si + 2], dx   ; cachedheight into dx
mov   bx, word ptr es:[si + (( YSLOPE_SEGMENT - CACHEDHEIGHT_SEGMENT) * 16)]
mov   cx, word ptr es:[si + 2 + (( YSLOPE_SEGMENT - CACHEDHEIGHT_SEGMENT) * 16)]


; not worth continuing to LEA because fixedmul destroys ES and then we have to store and restore from SI which is too much extra time
; distance = cacheddistance[y] = R_FixedMulLocal (planeheight, yslope[y]);

;call FAR PTR FixedMul_ 
call R_FixedMulLocal_

; result is distance
mov   es, ds:[_cacheddistance_segment_storage]
mov   bx, word ptr ds:[_basexscale]
mov   cx, word ptr ds:[_basexscale+2]
mov   word ptr es:[si], ax			; store distance
mov   word ptr es:[si + 2], dx		; store distance
mov   di, dx						; store distance high word in di
push  ax  ; distance low word

; 		ds_xstep = cachedxstep[y] = (R_FixedMulLocal (distance,basexscale));

;call FAR PTR FixedMul_ 
call R_FixedMulLocal_

mov   es, ds:[_cachedxstep_segment_storage]
mov   word ptr es:[si], ax
mov   word ptr es:[si + 2], dx
mov   word ptr ds:[DS_XSTEP], ax
mov   word ptr ds:[DS_XSTEP+2], dx
mov   dx, di
mov   bx, word ptr ds:[_baseyscale]
mov   cx, word ptr ds:[_baseyscale+2]
; cant pop - used once more later
mov   ax, word ptr [bp - 02h]	; retrieve distance low word

;		ds_ystep = cachedystep[y] = (R_FixedMulLocal (distance,baseyscale));

;call FAR PTR FixedMul_ 
call R_FixedMulLocal_

mov   es, ds:[_cachedystep_segment_storage]
; todo turn into stosw here and above?
mov   word ptr es:[si], ax
mov   word ptr es:[si + 2], dx
mov   word ptr ds:[DS_YSTEP], ax
mov   word ptr ds:[DS_YSTEP+2], dx

pop   ax
mov   dx, di  				    ; distance high word
jmp   distance_steps_ready

   

ENDP


exit_drawplanes:
LEAVE_MACRO 
pop   di
pop   si
pop   dx
pop   cx
pop   bx
mov   byte ptr cs:[(SELFMODIFY_SPAN_drawplaneiter+1)-OFFSET R_DrawSpan_], 0
retf   

do_next_drawplanes_loop:	

inc   byte ptr cs:[SELFMODIFY_SPAN_drawplaneiter+1-OFFSET R_DrawSpan_]
add   word ptr [bp - 8], VISPLANE_BYTE_SIZE
jmp   SHORT drawplanes_loop
do_sky_flat_draw:
; todo revisit params. maybe these can be loaded in R_DrawSkyPlaneCallHigh
mov   bx, word ptr [bp - 8] ; get visplane offset
mov   cx, word ptr [bp - 6] ; and segment
mov   dx, word ptr [si + 6]
mov   ax, word ptr [si + 4]
;call  [_R_DrawSkyPlaneCallHigh]
SELFMODIFY_SPAN_draw_skyplane_call:
db    09Ah
dw    R_DRAWSKYPLANE_OFFSET
dw    DRAWSKYPLANE_AREA_SEGMENT
inc   byte ptr cs:[SELFMODIFY_SPAN_drawplaneiter+1-OFFSET R_DrawSpan_]
add   word ptr [bp - 8], VISPLANE_BYTE_SIZE
jmp   SHORT drawplanes_loop

;R_DrawPlanes_

PROC R_DrawPlanes_
PUBLIC R_DrawPlanes_ 

;retf

; ARGS none

; STACK
; bp - 8 visplaneoffset
; bp - 6 visplanesegment
; bp - 4 usedflatindex
; bp - 2 physindex


push  bx
push  cx
push  dx
push  si
push  di
push  bp
mov   bp, sp
sub   sp, 08h
xor   ax, ax
mov   word ptr [bp - 8], ax
mov   word ptr [bp - 6], FIRST_VISPLANE_PAGE_SEGMENT   ; todo make constant visplane segment
mov   word ptr [bp - 4], ax
mov   word ptr [bp - 2], ax


mov       ax, R_DRAWSKYPLANE_OFFSET
cmp       byte ptr ds:[_screenblocks], 10
jge       setup_dynamic_skyplane
mov       ax, R_DRAWSKYPLANE_DYNAMIC_OFFSET
setup_dynamic_skyplane:
mov       word ptr cs:[SELFMODIFY_SPAN_draw_skyplane_call + 1-OFFSET R_DrawSpan_], ax



drawplanes_loop:
SELFMODIFY_SPAN_drawplaneiter:
mov   ax, 0 ; get i value. this is at the start of the function so its hard to self modify. so we reset to 0 at the end of the function
cmp   ax, word ptr ds:[_lastvisplane]
jge   exit_drawplanes
IF COMPILE_INSTRUCTIONSET GE COMPILE_186
 shl   ax, 3
ELSE
 shl   ax, 1
 shl   ax, 1
 shl   ax, 1
ENDIF

add   ax, offset _visplaneheaders
mov   si, ax
mov   ax, word ptr [si + 4]			; fetch visplane minx
cmp   ax, word ptr [si + 6]			; fetch visplane maxx
jnle   do_next_drawplanes_loop

loop_visplane_page_check:
cmp   word ptr [bp - 8], VISPLANE_BYTES_PER_PAGE
jnb   check_next_visplane_page


; todo: DI is (mostly) unused here. Can probably be used to hold something usedful.

mov   bx, word ptr cs:[SELFMODIFY_SPAN_drawplaneiter+1-OFFSET R_DrawSpan_]

add   bx, bx
mov   cx, word ptr [bx +  _visplanepiclights]
cmp   cl, byte ptr ds:[_skyflatnum]
je    do_sky_flat_draw

do_nonsky_flat_draw:

mov   byte ptr cs:[SELFMODIFY_SPAN_lookuppicnum+2-OFFSET R_DrawSpan_], cl 
mov   al, ch
xor   ah, ah

IF COMPILE_INSTRUCTIONSET GE COMPILE_186
 sar   ax, LIGHTSEGSHIFT
ELSE
 sar   ax, 1
 sar   ax, 1
 sar   ax, 1
 sar   ax, 1
ENDIF


add   al, byte ptr ds:[_extralight]
cmp   al, LIGHTLEVELS
jb    lightlevel_in_range
mov   al, LIGHTLEVELS-1
lightlevel_in_range:

add   ax, ax
mov   bx, ax
mov   ax, word ptr ds:[bx + _lightshift7lookup]
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
mov   byte ptr [bp - 4], al
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
check_next_visplane_page:
; do next visplane page
sub   word ptr [bp - 8], VISPLANE_BYTES_PER_PAGE
inc   byte ptr [bp - 2]
cmp   byte ptr [bp - 2], 3
je    do_visplane_pagination
lookup_visplane_segment:
mov   bx, word ptr [bp - 2]
add   bx, bx
mov   ax, word ptr ds:[bx + _visplanelookupsegments]
mov   word ptr [bp - 6], ax
jmp   loop_visplane_page_check
do_visplane_pagination:
mov   al, byte ptr ds:[_visplanedirty]
add   al, 3
mov   dx, 2
cbw  
mov   byte ptr [bp - 2], 2


;call  Z_QuickMapVisplanePage_
db 0FFh  ; lcall[addr]
db 01Eh  ;
dw _Z_QuickMapVisplanePage_addr


jmp   lookup_visplane_segment




found_page_with_empty_space:

mov   al, bl ; bl is usedflatindex
IF COMPILE_INSTRUCTIONSET GE COMPILE_186
 shl   al, 2
ELSE
 shl   al, 1
 shl   al, 1
ENDIF

mov   ah, byte ptr ds:[bx + _allocatedflatsperpage]
add   ah, al
inc   byte ptr ds:[bx + _allocatedflatsperpage]
mov   byte ptr [bp - 4], ah
found_flat:
mov   ax, FLATTRANSLATION_SEGMENT
mov   es, ax
mov   bl, cl
xor   bh, bh

mov   bl, byte ptr es:[bx]
mov   ax, FLATINDEX_SEGMENT
mov   es, ax
mov   al, byte ptr [bp - 4]
mov   di, 1 ; update flat unloaded

mov   byte ptr es:[bx], al	; flatindex[flattranslation[piclight.bytes.picnum]] = usedflatindex;

; check l2 cache next
flat_loaded:
mov   dx, word ptr [bp - 4] ; a byte, but read the 0 together

IF COMPILE_INSTRUCTIONSET GE COMPILE_186
 sar   dx, 2
ELSE
 sar   dx, 1
 sar   dx, 1
ENDIF


; dl = flatcacheL2pagenumber
cmp   dl, byte ptr ds:[_currentflatpage+0]
je    in_flat_page_0

; check if L2 page is in L1 cache

cmp   dl, byte ptr ds:[_currentflatpage+1]
jne   not_in_flat_page_1
mov   cl, 1
jmp   SHORT update_l1_cache
found_flat_page_to_evict:

db 0FFh  ; lcall[addr]
db 01Eh  ;
dw _R_EvictFlatCacheEMSPage_addr

;call  R_EvictFlatCacheEMSPage_   ; al stores result..
IF COMPILE_INSTRUCTIONSET GE COMPILE_186
 shl   al, 2
ELSE
 shl   al, 1
 shl   al, 1
ENDIF


mov   byte ptr [bp - 4], al
jmp   found_flat

not_in_flat_page_1:
cmp   dl, byte ptr ds:[_currentflatpage+2]
jne   not_in_flat_page_2
mov   cl, 2
jmp SHORT  update_l1_cache
not_in_flat_page_2:
cmp   dl, byte ptr ds:[_currentflatpage+3]
jne   not_in_flat_page_3
mov   cl, 3
jmp SHORT  update_l1_cache
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
mov   dx, bx
add   ax, FIRST_FLAT_CACHE_LOGICAL_PAGE

db 0FFh  ; lcall[addr]
db 01Eh  ;
dw _Z_QuickMapFlatPage_addr

;call  Z_QuickMapFlatPage_
jmp  SHORT l1_cache_finished_updating
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
mov   ax, word ptr [bp - 4]
IF COMPILE_INSTRUCTIONSET GE COMPILE_186
 sar   ax, 2
ELSE
 sar   ax, 1
 sar   ax, 1
ENDIF
cbw  


db 0FFh  ; lcall[addr]
db 01Eh  ;
dw _R_MarkL2FlatCacheLRU_addr
;call  R_MarkL2FlatCacheLRU_


cmp   di, 0 ; di used to hold flatunlodaed
jnz   flat_is_unloaded
flat_not_unloaded:
; calculate ds_source_segment
mov   bx, word ptr [bp - 4]
and   bx, 3
add   bx, bx
mov   ax, word ptr ds:[bx + _MULT_256]
mov   bl, cl
add   bx, bx
add   ax, word ptr ds:[bx + _FLAT_CACHE_PAGE]

mov   word ptr ds:[_ds_source_segment], ax
mov   ax, word ptr [si]
mov   dx, word ptr [si + 2]
sub   ax, word ptr ds:[_viewz]
sbb   dx, word ptr ds:[_viewz + 2]
or    dx, dx

; planeheight = labs(plheader->height - viewz.w);

jge   planeheight_already_positive	; labs check
neg   ax
adc   dx, 0
neg   dx
planeheight_already_positive:
mov   word ptr ds:[_planeheight], ax
mov   word ptr ds:[_planeheight + 2], dx
mov   ax, word ptr [si + 6]
mov   di, ax
les   bx, dword ptr [bp - 8]

mov   byte ptr es:[bx + di + 3], 0ffh
mov   si, word ptr [si + 4]
mov   byte ptr es:[bx + si + 1], 0ffh
inc   ax

mov   word ptr cs:[SELFMODIFY_SPAN_comparestop+2-OFFSET R_DrawSpan_], ax ; set count value to be compared against in loop.

cmp   si, ax
jle   start_single_plane_draw_loop
jmp   do_next_drawplanes_loop
; flat is unloaded. load it in
flat_is_unloaded:
mov   bl, cl
xor   bh, bh

add   bx, bx

push  cx
mov   cx, word ptr ds:[bx + _FLAT_CACHE_PAGE]

mov   ax, FLATTRANSLATION_SEGMENT
mov   es, ax
SELFMODIFY_SPAN_lookuppicnum:
mov   al, byte ptr es:[00]    ; uses picnum from way above.

xor   ah, ah
add   ax, word ptr ds:[_firstflat]
mov   bl, byte ptr [bp - 4]
and   bl, 3

add   bx, bx
mov   bx, word ptr ds:[bx + _MULT_4096]

db 0FFh  ; lcall[addr]
db 01Eh  ;
dw _W_CacheLumpNumDirect_addr

;call  W_CacheLumpNumDirect_
pop   cx
jmp   flat_not_unloaded



start_single_plane_draw_loop:
; loop setup

single_plane_draw_loop:
; si is x, bx is plheader pointer. so adding si gets us plheader->top[x] etc.
les    bx, dword ptr [bp - 8]

;			t1 = pl->top[x - 1];
;			b1 = pl->bottom[x - 1];
;			t2 = pl->top[x];
;			b2 = pl->bottom[x];



mov   dx, word ptr es:[bx + si + 0143h]	; b1&b2
mov   cx, word ptr es:[bx + si + 1]		; t1&t2


mov   ax, SPANSTART_SEGMENT
mov   es, ax
; todo swap si/di uses in the map plane area. reduces a little bit of register thrashing

; t1/t2 ch/cl
; b1/b2 dh/dl
dec   si	; x - 1  constant
mov   word ptr ds:[_ds_x2], si
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
ja   done_with_first_mapplane_loop

mov   ax, word ptr es:[di]
mov   word ptr ds:[_ds_y], di   ; predoubled for lookup
mov   word ptr ds:[_ds_x1], ax
inc   cl

call  R_MapPlane_

cmp   cl, ch
jae   done_with_first_mapplane_loop
inc   di
inc   di

jmp   loop_first_mapplane

end_single_plane_draw_loop_iteration:

;  todo: di not really in use at all in this loop. could be made to hold something useful
inc   si
SELFMODIFY_SPAN_comparestop:
cmp   si, 1000h
jle   single_plane_draw_loop

;jmp exit_drawplanes

jmp   do_next_drawplanes_loop

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
mov   word ptr ds:[_ds_x1], ax
dec   dl

call  R_MapPlane_

cmp   dl, dh
jbe   done_with_second_mapplane_loop

dec   di
dec   di
jmp   loop_second_mapplane

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



ENDP


END


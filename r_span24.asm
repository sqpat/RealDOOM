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
DRAWSPAN_CALL_OFFSET           = (16 * (SPANFUNC_SEGMENT - COLORMAPS_SEGMENT)) + DRAWSPAN_AH_OFFSET

; lcall cs:[00xx] here to call R_DrawSpan with the right CS:IP for colormaps to be at cs:3F00


; di, si, bp, (sp), bx, dx, cx, ax
; SHOULD BE
; destviewoffset, _spanfunc_inner_loop_count, SS value(?), n/a, xfrac, outport, yfrac, 3f hi port lo

SPANFUNC_ARG_DESTVIEW           = 0
SPANFUNC_ARG_INNER_LOOP_COUNT   = 2
SPANFUNC_ARG_NOTSURE            = 4   ; can use, but would have to write 4 times?
SPANFUNC_ARG_GARBAGE            = 6   ; cant use
SPANFUNC_ARG_XFRAC              = 8
SPANFUNC_ARG_OUTPORT            = 0Ah
SPANFUNC_ARG_YFRAC              = 0Ch
SPANFUNC_ARG_PORT_BYTE          = 0Eh
SPANFUNC_ARG_3F                 = 0Fh
SPANFUNC_ARG_SIZE               = 010h
SPANFUNC_ARG_SIZE_MASK          = 0Fh

; xfrac, yfrac, destviewoffset, _spanfunc_inner_loop_count
_spanfunc_args_386:
_spanfunc_args_1:  ; 000h aligned
dw 0, 0, 0, 0, 0, SC_DATA, 0, 03F01h
_spanfunc_args_2:  ; 010h aligned
dw 0, 0, 0, 0, 0, SC_DATA, 0, 03F02h
_spanfunc_args_3:  ; 020h aligned
dw 0, 0, 0, 0, 0, SC_DATA, 0, 03F04h
_spanfunc_args_4:  ; 030h aligned
dw 0, 0, 0, 0, 0, SC_DATA, 0, 03F08h
; 040h


_spanfunc_outp: ; arg 0 unused
ALIGN 8
db 1, 0  ; _spanfunc_outp[0]

_ds_source_offset_span:
dw 0, 0
ALIGN 8
db  2, 0  ; _spanfunc_outp[1]

_viewangle_shiftright3_span:
PUBLIC _viewangle_shiftright3_span
dw 0, XTOVIEWANGLE_SEGMENT

ALIGN 8
db  4  ; _spanfunc_outp[2]





_planezlight:
dw 0, ZLIGHT_SEGMENT
ALIGN 8
db  8  ; _spanfunc_outp[3]



; -1 jump case
dw  do_span_loop

_spanfunc_jump_target:
public _spanfunc_jump_target
; full quality


IF COMPISA LE COMPILE_286
    BYTES_PER_PIXEL = 014h
ELSE
    BYTES_PER_PIXEL = 011h
ENDIF

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
ALIGN_MACRO
SELFMODIFY_fixed_colormap_toggle_TARGET:
calculate_colormap:
mov   word ptr cs:[SELFMODIFY_compare_colormap_bits+1], ax
SHIFT_MACRO shr ax 4 ; ah now known zero
les   bx, dword ptr cs:[_planezlight]
xlat  byte ptr es:[bx]
SHIFT_MACRO shl ax 2 ; colormap * 16

IF COMPISA LE COMPILE_286
    add   ax, (COLORMAPS_SEGMENT - (DRAWSPAN_AH_OFFSET SHR 4))
    mov   word ptr cs:[SELFMODIFY_set_colormap_segment+1], ax
ELSE
    add    ax, 03F0h + (COLORMAPS_SEGMENT - (DRAWSPAN_AH_OFFSET SHR 4))
    mov    fs, ax
ENDIF

mov   bx, si  ; restore...
jmp   done_updating_colormap


;
; R_MapPlanes24_
; void __far R_MapPlanes ( byte y, int16_t x1, int16_t x2 )

local_loop_count = 2
map_planes_args_size = 2


;cachedheight   9000:0000
;yslope         9032:0000
;distscale      9064:0000
;cacheddistance 90B4:0000
;cachedxstep    90E6:0000
;cachedystep    9118:0000
; 	rather than changing ES a ton we will just modify offsets by segment distance
;   confirmed to be faster even on 8088 with it's baby prefetch queue - i think on 16 bit busses it is only faster.




ALIGN_MACRO	
PROC    R_MapPlanes24_ NEAR
PUBLIC  R_MapPlanes24_


; NORMAL STACK (negatives are pushed temps)
; SP - 2 = y << 1
; SP + 0 = Return addr
; SP + 2 = loop_count

; si is ds_y
FAST_SHL1 SI ; Initial << 1

map_planes_loop:
; si is dc_y word lookup.
mov   ds, bp


SELFMODIFY_SPAN_plane_height:
mov   ax, 01000h
ENSUREALIGN_406:  ; todo odd

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





; CACHED DISTANCE lookup


    IF COMPISA LE COMPILE_286
        LES di, DWORD PTR DS:[BX + SI + ((CACHEDDISTANCE_SEGMENT - SPANSTART_SEGMENT) * 16)]
    distance_steps_ready:
        mov dx, es
    ELSE

        MOV EDI, DWORD PTR DS:[BX + SI + ((CACHEDDISTANCE_SEGMENT - SPANSTART_SEGMENT) * 16)]
    distance_steps_ready:

    ENDIF


public distance_steps_ready

IF COMPISA LE COMPILE_286


    ; dx:di is distance. or todo EDI for 386.

    mov   ax, dx
    and   ax, 07F0h  ; colormap bits.
SELFMODIFY_compare_colormap_bits:
    cmp   ax, 01000h
ENSUREALIGN_408: ; todo odd
SELFMODIFY_fixed_colormap_toggle:  ; becomes nop with fixedcolormap on.
    jne   calculate_colormap
SELFMODIFY_fixed_colormap_toggle_AFTER:

    done_updating_colormap:
    LODSW ; grab x1

    xchg ax, di  ; grab distance, x1 into di
    FAST_SHL1 di
    

    PUSH SI     ; next SI
    mov  si, bx ; restore unlodsw si   ;todo get rid of this just offset si by 2...


    ; dx:ax is distance
    ; di is x1 word lookup
    ; si is ds_y word lookup
    ;     length = R_FixedMulLocal (distance,distscale[x1]);


    mov   bx, di          ; dword lookup if we add them



    les   bp, dword ptr ds:[bx + di + ((DISTSCALE_SEGMENT - SPANSTART_SEGMENT) * 16)]
    mov   cx, es                                   	; distscale high word

    ; inlined R_FixedMulLocal24_


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


    ; todo this ax bx bp juggle can be improved
    ; todo this ax bx bp juggle can be improved

    xchg  bx, ax			; store low word of length (product result)in bx
    mov   cx, dx			; store high word of length  (product result) in cx

    les   ax, dword ptr cs:[_viewangle_shiftright3_span]
    add   ax, word ptr es:[di]		; ax is unmodded fine angle.. di is a word lookup
    and   ah, 01Fh			; MOD_FINE_ANGLE mod high bits

    xchg  ax, bx			; fineangle in BX, low word into AX


    mov   bp, ax	        ; store low word 
        
    ;call FixedMulTrigCosineLocal_


    FAST_SHL1 bx

    ; sine stuff

        test bh, 020h

        MOV  DX, FINESINE_SEGMENT
        MOV  ES, DX
        PUSH WORD PTR ES:[BX]  ; just two bytes, pretty effcient instruction


        mov  dx, cx
        je   skip_invert_sin
        neg  dx
        NEG  bp
        SBB  dx, 0   ; bp:dx is sin

        skip_invert_sin:
        


        test bh, 030h
        MOV  BX, WORD PTR ES:[BX+((FINECOSINE_SEGMENT - FINESINE_SEGMENT) * 16)]  ; FINECOSINE - FINESINE

        mov   ES, dx			; BP:ES is sin


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
    SHIFT32_MACRO_LEFT dx ax 2
    
    ; shift 8, 6 total for 6.10
    mov   al, ah
    mov   ah, dl

    xchg  ax, bp   ; bp stores xfrac, ax retrieves low word
    ; ES has high word..



    ;call FixedMulTrigSineLocal_


        POP  BX  ; sine lookup

        MUL  BX        ; AX * BX
        MOV  AX, ES    ; CX to AX
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

    ; leave as 6.8.2 



    mov   bh, al ; yfrac lo 0.2 in bh
    mov   cl, ah
    mov   ch, dl ; yfrac 6.8 in cx

; cx:bh is yfrac
; bp    is xfrac

; es is free...


start_writes:
public start_writes


MOV   AX, WORD PTR DS:[SI + ((CACHEDYSTEP_SEGMENT - SPANSTART_SEGMENT) * 16)]
mov   dx, ax ; backup


; this is reversed, supposed to be  shift right 2 then shift left n, so instead we shift right 2 - n
SELFMODIFY_SPAN_detailshift_2:
mov ax, ax
mov ax, ax


mov   word ptr cs:[SELFMODIFY_SPAN_ds_ystep + 1 - OFFSET R_SPAN24_STARTMARKER_], ax



; last uses of ds
MOV    ax, WORD PTR DS:[SI + ((CACHEDXSTEP_SEGMENT - SPANSTART_SEGMENT) * 16)] 
mov    es, ax  ; backup

SELFMODIFY_SPAN_detailshift_1:
mov   ax, ax
mov   ax, ax
mov   word ptr cs:[SELFMODIFY_SPAN_ds_xstep+1 - OFFSET R_SPAN24_STARTMARKER_], ax


mov ax, cs
mov ds, ax


mov   ax, word ptr ds:[si + OFFSET SPAN_LOCAL_DC_YL_LOOKUP_TABLE] ; todo try moving to start of file, displacement 1 byte?
; si is free

SELFMODIFY_SPAN_destview_lo_1:
add   ax, 01000h
ENSUREALIGN_409:

shr   di, 1   ; dc_x * 1
mov si, di  

 ; nops if potato etc
SELFMODIFY_SPAN_detailshift2minus_1:
 shr   si, 1							
 shr   si, 1							; num pixels per plane

 add   ax, si    ; base offset...


mov si, es ; es is free

mov  es, di  ; back up...



; todo improve this logic.
; todo cache last value?

SELFMODIFY_SELECT_port_routine:
SELFMODIFY_SELECT_port_routine_AFTER = SELFMODIFY_SELECT_port_routine + 2
public SELFMODIFY_SELECT_port_routine

; HIGH DETAIL ROUTINE
and   di, 3
jz    do_vga_plane_0_start
jpe   do_vga_plane_3_start
dec   di
jz    do_vga_plane_1_start

do_vga_plane_2_start:
mov   byte ptr ds:[SPANFUNC_ARG_PORT_BYTE + 0 * SPANFUNC_ARG_SIZE], 4
mov   byte ptr ds:[SPANFUNC_ARG_PORT_BYTE + 1 * SPANFUNC_ARG_SIZE], 8
mov   byte ptr ds:[SPANFUNC_ARG_PORT_BYTE + 2 * SPANFUNC_ARG_SIZE], 1
mov   byte ptr ds:[SPANFUNC_ARG_PORT_BYTE + 3 * SPANFUNC_ARG_SIZE], 2
jmp   done_with_vga_plane_writes

SELFMODIFY_SELECT_port_routine_TARGET_LO:
do_lo_quality_routine:
and   di, 1
xchg  ax, di
mov   al, 3
jz    use_lo_plane_zero
mov   al, 12
use_lo_plane_zero:
mov   byte ptr ds:[SPANFUNC_ARG_PORT_BYTE + 0 * SPANFUNC_ARG_SIZE], al
xor   al, 15
mov   byte ptr ds:[SPANFUNC_ARG_PORT_BYTE + 1 * SPANFUNC_ARG_SIZE], al
xchg  ax, di  ; restore ax
jmp   done_with_vga_plane_writes


do_vga_plane_1_start:
mov   byte ptr ds:[SPANFUNC_ARG_PORT_BYTE + 0 * SPANFUNC_ARG_SIZE], 2
mov   byte ptr ds:[SPANFUNC_ARG_PORT_BYTE + 1 * SPANFUNC_ARG_SIZE], 4
mov   byte ptr ds:[SPANFUNC_ARG_PORT_BYTE + 2 * SPANFUNC_ARG_SIZE], 8
mov   byte ptr ds:[SPANFUNC_ARG_PORT_BYTE + 3 * SPANFUNC_ARG_SIZE], 1
jmp   done_with_vga_plane_writes

do_vga_plane_3_start:
mov   byte ptr ds:[SPANFUNC_ARG_PORT_BYTE + 0 * SPANFUNC_ARG_SIZE], 8
mov   byte ptr ds:[SPANFUNC_ARG_PORT_BYTE + 1 * SPANFUNC_ARG_SIZE], 1
mov   byte ptr ds:[SPANFUNC_ARG_PORT_BYTE + 2 * SPANFUNC_ARG_SIZE], 2
mov   byte ptr ds:[SPANFUNC_ARG_PORT_BYTE + 3 * SPANFUNC_ARG_SIZE], 4
jmp   done_with_vga_plane_writes

do_vga_plane_0_start:
mov   byte ptr ds:[SPANFUNC_ARG_PORT_BYTE + 0 * SPANFUNC_ARG_SIZE], 1
mov   byte ptr ds:[SPANFUNC_ARG_PORT_BYTE + 1 * SPANFUNC_ARG_SIZE], 2
mov   byte ptr ds:[SPANFUNC_ARG_PORT_BYTE + 2 * SPANFUNC_ARG_SIZE], 4
mov   byte ptr ds:[SPANFUNC_ARG_PORT_BYTE + 3 * SPANFUNC_ARG_SIZE], 8

SELFMODIFY_SELECT_port_routine_TARGET_POTATO:
done_with_vga_plane_writes:


; di free




xchg  ax, bp               			; store base view offset in bp. ax gets xfrac.








; dx: has ystep 6.10 still
; cx:bh has yfrac 6.8.2. bh is okay to and into DI.
; ax has xfrac
; si has xstep
; bp has base view offset
; ds is cs
; di is free! todo use
; es has x1 backup.


; AX has xfrac (6.8)
; SI has xstep (6.8)



; the above offset of 010h, 020h, 030h
; and to 1, 3, 7 still works to loop around. We are just eliminating bit 3.

; i suppose this whole section could be super optimized for potato/low with entire chunks of code replaced.

xor bl ,bl

shr dx, 1
rcr bl, 1
shr dx, 1
rcr bl, 1

; todo just ax writes, swap reg... 

mov   word ptr ds:[SPANFUNC_ARG_XFRAC + 0 * SPANFUNC_ARG_SIZE], ax
SELFMODIFY_SPAN_set_xfrac_lookup_potato:
add   ax, si
SELFMODIFY_SPAN_set_xfrac_lookup_potato_AFTER:
mov   word ptr ds:[SPANFUNC_ARG_XFRAC + 1 * SPANFUNC_ARG_SIZE], ax
SELFMODIFY_SPAN_set_xfrac_lookup_low:
add   ax, si
SELFMODIFY_SPAN_set_xfrac_lookup_low_AFTER:
mov   word ptr ds:[SPANFUNC_ARG_XFRAC + 2 * SPANFUNC_ARG_SIZE], ax
add   ax, si
mov   word ptr ds:[SPANFUNC_ARG_XFRAC + 3 * SPANFUNC_ARG_SIZE], ax


SELFMODIFY_SPAN_set_xfrac_lookup_TARGET:

xchg  ax, cx
mov   word ptr ds:[SPANFUNC_ARG_YFRAC + 0 * SPANFUNC_ARG_SIZE], ax
SELFMODIFY_SPAN_set_yfrac_lookup_potato:
add   bh, bl
SELFMODIFY_SPAN_set_yfrac_lookup_potato_AFTER:
adc   ax, dx
mov   word ptr ds:[SPANFUNC_ARG_YFRAC + 1 * SPANFUNC_ARG_SIZE], ax
SELFMODIFY_SPAN_set_yfrac_lookup_low:
add   bh, bl
SELFMODIFY_SPAN_set_yfrac_lookup_low_AFTER:
adc   ax, dx
mov   word ptr ds:[SPANFUNC_ARG_YFRAC + 2 * SPANFUNC_ARG_SIZE], ax
add   bh, bl
adc   ax, dx
mov   word ptr ds:[SPANFUNC_ARG_YFRAC + 3 * SPANFUNC_ARG_SIZE], ax

SELFMODIFY_SPAN_set_yfrac_lookup_TARGET:

; done with x/y....

 mov   cx, es  ; dc_x * 1

  
SELFMODIFY_SPAN_ds_x2:
 mov   ax, 01000h


 sub   ax, cx  ; x2 - x1
 mov   dx, ax  ; get plane copy


SELFMODIFY_SPAN_and_detailshift_byte:
 and   cx, 3
SELFMODIFY_SPAN_sub_detailshift:
 sub   cx, 4
 neg   ch  ; ch = 1


SELFMODIFY_SPAN_and_detailshift_byte_2:
 and   dx, 3




 ; nops if potato etc
SELFMODIFY_SPAN_detailshift2minus_3:
 shr   ax, 1							
 shr   ax, 1							; num pixels per plane
 
 
 xor   si, si

; di = carrying the starting loop offset
; bx = unused?
; es = unused?
; bp = destplane
; ax = dc_x2 - dx_x1 >> detailshift
; dx = vga plane iter
; ch = 1
; cl = dc_x1 vga plane - detailshift 
; dl = dc_x2-dc_x1 vga plane
; dh = 0
; si = 0



; UNROLLED LOOP START
mov   word ptr ds:[SPANFUNC_ARG_INNER_LOOP_COUNT + 0 * SPANFUNC_ARG_SIZE], ax

SELFMODIFY_SPAN_set_loopcount_potato:
sub   dl, ch
SELFMODIFY_SPAN_set_loopcount_potato_AFTER:
sbb   ax, si
mov   word ptr ds:[SPANFUNC_ARG_INNER_LOOP_COUNT + 1 * SPANFUNC_ARG_SIZE], ax
SELFMODIFY_SPAN_set_loopcount_low:
sub   dl, ch
SELFMODIFY_SPAN_set_loopcount_low_AFTER:
sbb   ax, si
mov   word ptr ds:[SPANFUNC_ARG_INNER_LOOP_COUNT + 2 * SPANFUNC_ARG_SIZE], ax
sub   dl, ch
sbb   ax, si
mov   word ptr ds:[SPANFUNC_ARG_INNER_LOOP_COUNT + 3 * SPANFUNC_ARG_SIZE], ax



SELFMODIFY_SPAN_set_loopcount_TARGET:

 
xchg  ax, bp

mov   word ptr ds:[SPANFUNC_ARG_DESTVIEW + 0 * SPANFUNC_ARG_SIZE], ax
SELFMODIFY_SPAN_set_destview_potato:
add   cl, ch ; ch = 1, incrementing towards 0
SELFMODIFY_SPAN_set_destview_potato_AFTER:
adc   ax, si
mov   word ptr ds:[SPANFUNC_ARG_DESTVIEW + 1 * SPANFUNC_ARG_SIZE], ax
SELFMODIFY_SPAN_set_destview_low:
add   cl, ch ; ch = 1, incrementing towards 0
SELFMODIFY_SPAN_set_destview_low_AFTER:
adc   ax, si
mov   word ptr ds:[SPANFUNC_ARG_DESTVIEW + 2 * SPANFUNC_ARG_SIZE], ax
add   cl, ch ; ch = 1, incrementing towards 0
adc   ax, si
mov   word ptr ds:[SPANFUNC_ARG_DESTVIEW + 3 * SPANFUNC_ARG_SIZE], ax


SELFMODIFY_SPAN_set_destview_TARGET:




; 	if (fixedcolormap) {


SELFMODIFY_SPAN_set_destview_segment:
mov   ax, 01000h
mov   es, ax

cli 	; disable interrupts because we use sp here

mov   ax, cs
mov   ss, ax

mov   word ptr ds:[((SELFMODIFY_SPAN_sp_storage+1) - R_SPAN24_STARTMARKER_   )], sp
mov   ds, word ptr ds:[_ds_source_offset_span+2] 




; inlined DrawSpan

xor   sp, sp


jmp   start_span_loop_first_iter




ALIGN_MACRO

xchg ax, ax ; FORCE ODD ALIGNMENT



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
public  last_span_pixel
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
mov   sp, 0
ENSUREALIGN_410:  ; important

; loop if i < loopcount.
SELFMODIFY_SPAN_compare_span_counter:
cmp   sp, 040h
jae   span_i_loop_done

mov   ax, cs
mov   ss, ax


start_span_loop_first_iter:

; todo use ss/sp instead of ds/si and popa

POPA_MACRO_REAL

out   dx, al                            ; note ah has 3Fh

SELFMODIFY_set_colormap_segment:
mov    bp, 01000h
ENSUREALIGN_407:
mov    ss, bp


mov   dx, bx


FAST_SHL1 si


mov   word ptr cs:[SELFMODIFY_SPAN_set_span_counter+1], sp ; autoincremented

SELFMODIFY_SPAN_ds_ystep:
mov    bp, 01000h
ENSUREALIGN_401:

SELFMODIFY_SPAN_ds_xstep:
mov     sp,  01000h
ENSUREALIGN_402: ; todo odd

jmp   word ptr cs:[si + _spanfunc_jump_target - OFFSET R_SPAN24_STARTMARKER_ ]	    ; get unrolled jump count.

ALIGN_MACRO	
span_i_loop_done:

mov   ax, FIXED_DS_SEGMENT
mov   ss, ax


; restore sp, bp
SELFMODIFY_SPAN_sp_storage:
mov sp, 01000h
ENSUREALIGN_400:




sti								; reenable interrupts

    POP SI ; Retrieve SI for next iter
    
    MOV BP, SP
    DEC BYTE PTR SS:[BP + local_loop_count]
    MOV BP, SPANSTART_SEGMENT

    JNZ do_map_planes_loop
    

    ; LOOP DEPTH: 2
    RET map_planes_args_size
    ; ==================== HOLE HOLE HOLE ====================

ALIGN_MACRO	
do_map_planes_loop:
    JMP map_planes_loop

; todo maybe export to diff file
; END 286 VERSION
; END 286 VERSION
; END 286 VERSION


ELSE

; todo maybe export to diff file
; BEGIN 386 VERSION
; BEGIN 386 VERSION
; BEGIN 386 VERSION



    ; edi is distance

    ; todo shld 12, al logic
    shld  eax, edi, 16
    and   ax, 07F0h  ; colormap bits.
SELFMODIFY_compare_colormap_bits:
    cmp   ax, 01000h
ENSUREALIGN_408: ; todo odd
SELFMODIFY_fixed_colormap_toggle:  ; becomes nop with fixedcolormap on.
    jne   calculate_colormap
SELFMODIFY_fixed_colormap_toggle_AFTER:

    done_updating_colormap:

    LODSW ; grab x1

    xchg eax, edi         ; eax =  distance, x1 into di
    FAST_SHL1 di          ; word lookup

    PUSH SI     ; next SI
    sub  si, 2



    ; eax is distance
    ; di is x1 word lookup
    ; si is ds_y word lookup
    ;     length = R_FixedMulLocal (distance,distscale[x1]);

    mov   bx, di          ; dword lookup if we add them

    ; length = FixedMul (distance,distscale[x1]);

    mul   dword ptr ds:[bx + di + ((DISTSCALE_SEGMENT - SPANSTART_SEGMENT) * 16)]
    SHRD  EAX, EDX, 16


    xchg  eax, ebp              ; ebp holds this for 2 muls

;    angle = (viewangle + xtoviewangle[x1])>>ANGLETOFINESHIFT;

    les   bx, dword ptr cs:[_viewangle_shiftright3_span]
    add   bx, word ptr es:[di]		; ax is unmodded fine angle.. di is a word lookup
    and   bh, 01Fh
    FAST_SHL1 bx


    MOV   DX, FINESINE_SEGMENT
    MOV   ES, DX

    ; fixedmultrig sine
    movzx eax, word ptr es:[bx]
    movzx ecx, WORD PTR ES:[BX+((FINECOSINE_SEGMENT - FINESINE_SEGMENT) * 16)]  ; FINECOSINE - FINESINE
    mov   edx, ebp  ; copy for 2nd mul
    test  bh, 020h
    je    skip_invert_sin
    NEG   edx
    skip_invert_sin:

    test  bh, 030h
    jpe   skip_invert_cos
    NEG   ebp
    skip_invert_cos:


    imul  edx

    SHRD  EAX, EDX, 16
SELFMODIFY_SPAN_viewy_full_1:
    ADD   EAX, 010000000h
    NEG   EAX


    xchg  eax, ecx   ; store xfrac in cx, get cos value  ; todo swap calculation order and avoid ecx juggle
    
    SHR ECX, 8 ; Convert to 6.8.2
    

    imul ebp


    SHRD EAX, EDX, 16

SELFMODIFY_SPAN_viewx_full_1:
    ADD EAX, 010000000h
    SHL EAX, 10 ; Convert to 6.10


; TODO! improve 386 version from here on down

    ; eax high has xfrac

    xchg  eax, ecx  ; ecx hi gets xfrac , ax gets yfrac
    xchg  ax, cx    ; ecx lo gets yfrac



start_writes:
public start_writes


; last uses of ds
MOV    ax, WORD PTR DS:[SI + ((CACHEDXSTEP_SEGMENT - SPANSTART_SEGMENT) * 16)] 
mov    dx, ax
shl    edx, 16 ; x in high bits.


SELFMODIFY_SPAN_detailshift_1:
mov   ax, ax
mov   ax, ax

shl   eax, 16


MOV   AX, WORD PTR DS:[SI + ((CACHEDYSTEP_SEGMENT - SPANSTART_SEGMENT) * 16)]

; todo batch reads with ds in the appropriate seg? batch writes with cs = ds?

mov   bx, cs
mov   ds, bx

mov   dx, ax




; this is reversed, supposed to be  shift right 2 then shift left n, so instead we shift right 2 - n
SELFMODIFY_SPAN_detailshift_2:
mov ax, ax
mov ax, ax

SHL   ax, 2 ; todo back into detailshift...?

; todo push pop?
mov   dword ptr ds:[SELFMODIFY_SPAN_ds_xstepystep + 2 - OFFSET R_SPAN24_STARTMARKER_], eax








mov   ax, word ptr ds:[si + OFFSET SPAN_LOCAL_DC_YL_LOOKUP_TABLE] ; todo try moving to start of file, displacement 1 byte?
; si is free

SELFMODIFY_SPAN_destview_lo_1:
add   ax, 01000h
ENSUREALIGN_409:

shr   di, 1   ; dc_x * 1
mov si, di  

 ; nops if potato etc
SELFMODIFY_SPAN_detailshift2minus_1:
 shr   si, 1							
 shr   si, 1							; num pixels per plane

 add   ax, si    ; base offset...




xchg  ax, bp               			; store base view offset in bp. ax gets xfrac.


mov   esi, edx       ; store here.. add esi into ecx in unrolled loop

mov   bx, di


  
SELFMODIFY_SPAN_ds_x2:
 mov   ax, 01000h


 sub   ax, bx  ; x2 - x1
 mov   dx, ax  ; get plane copy


SELFMODIFY_SPAN_and_detailshift_byte:
 and   bx, 3
SELFMODIFY_SPAN_sub_detailshift:
 sub   bx, 4
 neg   bh   ; bh = 1



SELFMODIFY_SPAN_and_detailshift_byte_2:
 and   dx, 3




 ; nops if potato etc
SELFMODIFY_SPAN_detailshift2minus_3:
 shr   ax, 1							
 shr   ax, 1							; num pixels per plane
 
 
; todo zero register??

xchg  ecx, edi


SELFMODIFY_set_cx_to_vgaplane:
and   cx, 3
mov   ch, 1
shl   ch, cl
mov   cl, ch


mov   ch, 15

; edi = x/yfrac
; esi = x/ystep
; bh = 1
; bl = dc_x1 vga plane - detailshift 
; di = current write index
; dl = dc_x2-dc_x1 vga plane
; dh = 0
; ax = num pixels to draw per plane
; bp = destplane
; cl = current vga port write



; UNROLLED LOOP START

; todo this is necessary to line up the xfrac math. are we losing precision? unsure...
shr   si, 2

; TODO handle detail shift, jmp skip where necessary.

push  edi   ; x/yfrac 
push  ax    ; num pixels
push  bp    ; screen dest offset
push  cx    ; cl = vga plane

SELFMODIFY_SPAN_skip_args_potato_386:
sub   dl, bh
SELFMODIFY_SPAN_skip_args_potato_386_AFTER:

sbb   ax, 0 ; todo zero reg
add   edi, esi

add   bl, bh ; bh = 1, incrementing towards 0
adc   bp, 0 ; todo zero reg


SELFMODIFY_adjust_cx_instruction: 
shl   cl, 1   ; only one that has to be selfmodified. may become xor cl, ch. ch is 15.
cmp   cl, ch
jna   skip_cl_reset_0
mov   cl, 1
skip_cl_reset_0:


; todo still can be very improved.

push  edi   ; x/yfrac 
push  ax    ; num pixels
push  bp    ; screen dest offset
push  cx    ; cl = vga plane

SELFMODIFY_SPAN_skip_args_low_386:
sub   dl, bh
SELFMODIFY_SPAN_skip_args_low_386_AFTER:
sbb   ax, 0 ; todo zero reg
add   edi, esi

add   bl, bh ; bh = 1, incrementing towards 0
adc   bp, 0 ; todo zero reg

shl   cl, 1
cmp   cl, ch
jna   skip_cl_reset_1
mov   cl, 1
skip_cl_reset_1:


push  edi   ; x/yfrac 
push  ax    ; num pixels
push  bp    ; screen dest offset
push  cx    ; cl = vga plane

sub   dl, bh
sbb   ax, 0 ; todo zero reg
add   edi, esi

add   bl, bh ; bh = 1, incrementing towards 0
adc   bp, 0 ; todo zero reg

shl   cl, 1
cmp   cl, ch
jna   skip_cl_reset_2
mov   cl, 1
skip_cl_reset_2:


push  edi
push  ax
push  bp
push  cx

SELFMODIFY_SPAN_skip_args_386_TARGET:




; 	if (fixedcolormap) {


SELFMODIFY_SPAN_set_destview_segment:
mov   ax, 01000h
mov   es, ax



mov   ds, word ptr ds:[_ds_source_offset_span+2] 




; inlined DrawSpan

SELFMODIFY_SPAN_ds_xstepystep:
mov    ebp, 010000000h
ENSUREALIGN_401:
ENSUREALIGN_402: 


mov   cx, 6h  ; cl = shift count ch = modifiedloop count, count up from 0

mov   dx, SC_DATA
jmp   start_span_loop_first_iter




ALIGN_MACRO

xchg ax, ax ; FORCE ODD ALIGNMENT



MARKER_SM_SPAN24_AFTER_JUMP_1:
PUBLIC MARKER_SM_SPAN24_AFTER_JUMP_1    

;y high x low

REPT MAX_PIXELS - 1


    MOV   ESI, EBX ; 3 byte
    SHR   SI,  10 ; 3 byte
    ROL   ESI, CL ; 3 byte
    MOVZX SI,  BYTE PTR DS:[SI] ; 3 byte
    movs  byte ptr es:[di], byte ptr fs:[si]
    ADD   EBX, EBP ; 3 byte

    
endm

; final pixel
last_span_pixel:
public  last_span_pixel

    SHR   BX,  10 ; 3 byte
    ROL   EBX, CL ; 3 byte
    MOVZX SI,  BYTE PTR DS:[BX] ; 3 byte
    movs  byte ptr es:[di], byte ptr fs:[si]

 


do_span_loop:


; loop if i < loopcount.
SELFMODIFY_SPAN_compare_span_counter:

cmp   ch, 3
je    span_i_loop_done

inc    ch


start_span_loop_first_iter:

pop    ax
out    dx, al

pop    di
pop    si
pop    ebx

shl    bx, 2  ; hard to bake into the write?


FAST_SHL1 si





jmp   word ptr cs:[si + _spanfunc_jump_target - OFFSET R_SPAN24_STARTMARKER_ ]	    ; get unrolled jump count.

ALIGN_MACRO	
span_i_loop_done:



; restore sp, bp

ENSUREALIGN_400:




    POP SI ; Retrieve SI for next iter
    
    MOV BP, SP
    DEC BYTE PTR SS:[BP + local_loop_count]
    MOV BP, SPANSTART_SEGMENT

    JNZ do_map_planes_loop
    

    ; LOOP DEPTH: 2
    RET map_planes_args_size
    ; ==================== HOLE HOLE HOLE ====================

ALIGN_MACRO	
do_map_planes_loop:
    JMP map_planes_loop

ENDP

ENDIF








ALIGN_MACRO	

generate_distance_steps:
    
    ; Register state (all not listed are junk/scratch):
    ; SS = FIXED_DS_SEGMENT
    ; BP = SPANSTART_SEGMENT
    ; SI = y << 1

IF (COMPISA EQ COMPILE_8086) OR (COMPISA GE COMPILE_386)
    MOV DS:[SI + ((CACHEDHEIGHT_SEGMENT - SPANSTART_SEGMENT) * 16)], AX ; Handled by XCHG for 186/286
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

    ;SAR dx, 1
    ;RCR ax, 1
    
    MOV WORD PTR DS:[BX + SI + ((CACHEDDISTANCE_SEGMENT - SPANSTART_SEGMENT) * 16)], AX
    MOV WORD PTR DS:[BX + SI + 2 + ((CACHEDDISTANCE_SEGMENT - SPANSTART_SEGMENT) * 16)], DX
    
    MOV DI, AX
    MOV ES, DX
    

SELFMODIFY_SPAN_basexscale_lo_1:
    MOV BP, 01000h
    
    
    ; ds_xstep = cachedxstep[y] = R_FixedMulLocal(distance, basexscale)
    ;CALL R_FixedMulLocal24_

    MOV BX, DX

    MUL BP
    MOV CX, DX
    MOV AX, BX
    SELFMODIFY_SPAN_basexscale_hi_1:
    MOV DX, 01000h
    MUL DX
    XCHG AX, BX
    CWD
    AND DX, BP
    SUB BX, DX
    MUL BP
    ADD CX, AX
    ADC BX, DX

SELFMODIFY_sub_bx_di_or_not_basex:
    SUB BX, DI
SELFMODIFY_SPAN_basexscale_hi_2:
    mov ax, 01000h
    MUL DI
    ADD AX, CX
    ADC DX, BX
    
    ; Convert to 6.10
    SHIFT32_MACRO_LEFT dx ax 2
    MOV AL, AH
    MOV AH, DL
    
    MOV WORD PTR DS:[SI + ((CACHEDXSTEP_SEGMENT - SPANSTART_SEGMENT) * 16)], AX
    ; todo carry forward..



    MOV AX, DI



SELFMODIFY_SPAN_baseyscale_lo_1:
    MOV BP, 01000h
    
    ; ds_ystep = cachedystep[y] = R_FixedMulLocal(distance, baseyscale)
    ;CALL R_FixedMulLocal24_

    MOV BX, ES

    MUL BP
    MOV CX, DX
    MOV AX, BX
SELFMODIFY_SPAN_baseyscale_hi_1:
    MOV DX, 01000h
    MUL DX
    XCHG AX, BX
    CWD
    AND DX, BP
    SUB BX, DX
    MUL BP
    ADD CX, AX

    ADC BX, DX
SELFMODIFY_sub_bx_di_or_not_basey:
    SUB BX, DI
SELFMODIFY_SPAN_baseyscale_hi_2:
    mov ax, 01000h
    MUL DI
    ADD AX, CX
    ADC DX, BX


    ; Convert to 6.10
    SHIFT32_MACRO_LEFT dx ax 2
    MOV AL, AH
    MOV AH, DL
    
    MOV WORD PTR DS:[SI + ((CACHEDYSTEP_SEGMENT - SPANSTART_SEGMENT) * 16)], AX
    


    ; restore distance once more
   ; di has distance lo
    

    mov bx, si ; backup before lodsw.

    

ELSE
    MOVZX EDI, AX
    IMUL  EDI, DWORD PTR DS:[BX + SI + ((YSLOPE_SEGMENT - SPANSTART_SEGMENT) * 16)]
    SHR   EDI, 3
    MOV   DWORD PTR DS:[BX + SI + ((CACHEDDISTANCE_SEGMENT - SPANSTART_SEGMENT) * 16)], EDI
SELFMODIFY_SPAN_baseyscale_full_1: 
    MOV   EAX, 010000000h
    IMUL  EDI
    SHRD  EAX, EDX, 22 ; Convert to 6.10
    MOV   WORD PTR DS:[SI + ((CACHEDYSTEP_SEGMENT - SPANSTART_SEGMENT) * 16)], AX

SELFMODIFY_SPAN_basexscale_full_1:
    MOV   EAX, 010000000h
    IMUL  EDI
    SHRD  EAX, EDX, 22 ; Convert to 6.10
    MOV   WORD PTR DS:[SI + ((CACHEDXSTEP_SEGMENT - SPANSTART_SEGMENT) * 16)], AX

ENDIF
    JMP distance_steps_ready
    


   

ENDP

local_visplaneoffset = 0
local_visplanesegment = 2
draw_planes_frame_size = 4



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

mov      ax, word ptr ds:[_destview + 2]	; retrieve destview segment
mov      word ptr cs:[SELFMODIFY_SPAN_set_destview_segment+1 - OFFSET R_SPAN24_STARTMARKER_], ax

mov      byte ptr cs:[SELFMODIFY_use_cached_vispalne_light_check+2], 0FEh

mov      al, byte ptr ds:[_lastvisplane]
mov      ah, SIZE VISPLANEHEADER_T
mul      ah
add      ax, OFFSET _visplaneheaders + VISPLANEHEADER_T.visplaneheader_minx ; compare at lodsw offset
mov      word ptr cs:[SELFMODIFY_SPAN_last_iter_compare+2 - OFFSET R_SPAN24_STARTMARKER_], ax


mov      al, byte ptr ds:[_skyflatnum]  ; todo self modify at a different layer once per level
mov      byte ptr cs:[SELFMODIFY_SPAN_skyflatnum + 2 - OFFSET R_SPAN24_STARTMARKER_], al

mov      ds, word ptr ds:[_BSP_CODE_SEGMENT_PTR]


mov   si, _BASEXSCALE_OFFSET_R_BSP

IF COMPISA LE COMPILE_286
    LODSW
    MOV  word ptr cs:[SELFMODIFY_SPAN_basexscale_lo_1+1 - OFFSET R_SPAN24_STARTMARKER_], ax
    LODSW
    MOV  word ptr cs:[SELFMODIFY_SPAN_basexscale_hi_1+1 - OFFSET R_SPAN24_STARTMARKER_], ax
    MOV  word ptr cs:[SELFMODIFY_SPAN_basexscale_hi_2+1 - OFFSET R_SPAN24_STARTMARKER_], ax
    test ax, ax
    mov  ax, 0C089h
    jns  dont_do_sub_bx_di_basex
    mov  ax, 0FB29h
    dont_do_sub_bx_di_basex:
    MOV  word ptr cs:[SELFMODIFY_sub_bx_di_or_not_basex - OFFSET R_SPAN24_STARTMARKER_], ax

    LODSW
    MOV  word ptr cs:[SELFMODIFY_SPAN_baseyscale_lo_1+1 - OFFSET R_SPAN24_STARTMARKER_], ax
    LODSW
    MOV  word ptr cs:[SELFMODIFY_SPAN_baseyscale_hi_1+1 - OFFSET R_SPAN24_STARTMARKER_], ax
    MOV  word ptr cs:[SELFMODIFY_SPAN_baseyscale_hi_2+1 - OFFSET R_SPAN24_STARTMARKER_], ax
    test ax, ax
    mov  ax, 0C089h
    jns  dont_do_sub_bx_di_basey
    mov  ax, 0FB29h
    dont_do_sub_bx_di_basey:
    MOV  word ptr cs:[SELFMODIFY_sub_bx_di_or_not_basey - OFFSET R_SPAN24_STARTMARKER_], ax

    LODSW
    MOV word ptr cs:[SELFMODIFY_SPAN_viewx_lo_1+1 - OFFSET R_SPAN24_STARTMARKER_], ax
    LODSW
    MOV word ptr cs:[SELFMODIFY_SPAN_viewx_hi_1+2 - OFFSET R_SPAN24_STARTMARKER_], ax


    LODSW
    MOV word ptr cs:[SELFMODIFY_SPAN_viewy_lo_1+1 - OFFSET R_SPAN24_STARTMARKER_], ax
    LODSW
    MOV word ptr cs:[SELFMODIFY_SPAN_viewy_hi_1+2 - OFFSET R_SPAN24_STARTMARKER_], ax


ELSE
    MOV      ax, CS ; 2 byte, 2 cycle
    MOV      ES, ax ; 2 byte, 2 cycle


    MOV DI, SELFMODIFY_SPAN_basexscale_full_1+2 - OFFSET R_SPAN24_STARTMARKER_
    MOVS DWORD PTR ES:[DI], DS:[SI]
    
    MOV DI, SELFMODIFY_SPAN_baseyscale_full_1+2 - OFFSET R_SPAN24_STARTMARKER_
    MOVS DWORD PTR ES:[DI], DS:[SI]
    

    MOV DI, SELFMODIFY_SPAN_viewx_full_1+2 - OFFSET R_SPAN24_STARTMARKER_
    MOVS DWORD PTR ES:[DI], DS:[SI]
    
    MOV DI, SELFMODIFY_SPAN_viewy_full_1+2 - OFFSET R_SPAN24_STARTMARKER_
    MOVS DWORD PTR ES:[DI], DS:[SI]


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


mov   ax, (((SELFMODIFY_fixed_colormap_toggle_TARGET - SELFMODIFY_fixed_colormap_toggle_AFTER) )SHL 8) + 075h  ; jnew

cmp   byte ptr ds:[_fixedcolormap], 0
jne   do_span_fixedcolormap_selfmodify
done_with_span_fixedcolormap_selfmodify:
; modify instruction
mov   word ptr cs:[SELFMODIFY_fixed_colormap_toggle - OFFSET R_SPAN24_STARTMARKER_], ax
mov   si, OFFSET _visplaneheaders + VISPLANEHEADER_T.visplaneheader_minx ; initial case.
jmp   drawplanes_loop


exit_drawplanes:
public exit_drawplanes
add   sp, 2
retf   

ALIGN_MACRO	
do_span_fixedcolormap_selfmodify:
mov   ax, word ptr ds:[_shiftedfixedcolormap]

IF COMPISA LE COMPILE_286
    add  ax, (COLORMAPS_SEGMENT - (DRAWSPAN_AH_OFFSET SHR 4))
    mov   word ptr cs:[SELFMODIFY_set_colormap_segment + 1 - OFFSET R_SPAN24_STARTMARKER_], ax
ELSE
    add    ax, 03F0h + (COLORMAPS_SEGMENT - (DRAWSPAN_AH_OFFSET SHR 4))
    mov    fs, ax
ENDIF

mov   ax, 0C089h ; nop
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
public do_next_drawplanes_loop

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
    
    SELFMODIFY_use_cached_vispalne_light_check:
    cmp  ah, 0FEh ; FEh lightlevel seems to never be used...?
    je   use_cached_visplane_light
    mov  byte ptr cs:[SELFMODIFY_use_cached_vispalne_light_check+2], ah

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
    MOV WORD PTR CS:[_planezlight], CX
    MOV WORD PTR CS:[SELFMODIFY_compare_colormap_bits+1], CX ; make this dirty compare
    
    use_cached_visplane_light:
    ; todo also update selfmodify colormap? how often does this change.
    
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

ALIGN_MACRO    
jmp_to_flatcachemruL2:
    jmp flatcachemruL2
ALIGN_MACRO    
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
    JNE jmp_to_flatcachemruL2
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
    SUB AX, 01000h
    CWD ; ABS
    XOR AX, DX
    SUB AX, DX
    MOV CS:[SELFMODIFY_SPAN_plane_height+1 - OFFSET R_SPAN24_STARTMARKER_], AX
    
    MOV DI, SP

    ; NOTE: SP relative indexing now needs +2 (except current DI)
    
    ; TODO get rid of this push/pop somehow
    pop   bp
    push  bp   ; unsure if necessary.


    MOV  BX, WORD PTR DS:[SI] ; Already pointing to visplaneheader_maxx
    MOV  SI, WORD PTR DS:[SI + (VISPLANEHEADER_T.visplaneheader_minx - VISPLANEHEADER_T.visplaneheader_maxx)]
    MOV  WORD PTR CS:[SELFMODIFY_SPAN_loop_stop+1 - OFFSET R_SPAN24_STARTMARKER_], BX ; stop = maxx (not +1 because of increment change)
    xchg SI, bp  ; visplane to si
    mov  DS, WORD PTR DS:[DI + 4]
    

    
    ; NOTE: Handling of x2 is a bit of a hack, this section needs work
    
    ; Register state (all not listed are junk/scratch):
    ; SS = FIXED_DS_SEGMENT
    ; DS = visplanesegment
    ; BX = _visplaneheaders[i].visplaneheader_maxx
    ; BP = _visplaneheaders[i].visplaneheader_minx
    ; SI = &visplanes[i]
    
    MOV  BYTE PTR DS:[BX + SI + VISPLANE_T.vp_top + 1], 0FFh ; visplanes[i].vp_top[maxx + 1] = 0FFh

    LEA  CX, [SI + VISPLANE_T.vp_top]
    NOT  CX ; -(&visplanes[i].vp_top[0 + 1])
    MOV  CS:[SELFMODIFY_SPAN_loop_calc_x+2 - OFFSET R_SPAN24_STARTMARKER_], CX


    LEA  SI, [BP + SI + VISPLANE_T.vp_top]               ; include lodsb math of si + 1
    ;MOV  BYTE PTR DS:[SI - 1], CL ; visplanes[i].vp_top[minx - 1] = 0FFh  ; dont need to actually write this.
    

    
    MOV BX, WORD PTR DS:[SI + (VISPLANE_T.vp_bottom - VISPLANE_T.vp_top - 1)] ; b1/b2


    MOV WORD PTR CS:[SELFMODIFY_SPAN_ds_x2+1 - OFFSET R_SPAN24_STARTMARKER_], BP

    ; hardcoded first iter... 
    ; ax is still the number that would be subtracted from SI to get x after first lodsb.

   lodsb        ; first t2 (t1 is FF)
   xchg ax, cx 
   add  ax, si  ; ax is set to x

   ; cl has t2
   ; bx has b1/b2.


    xor  ch, ch   
    mov  di, cx   ; t2 with zero high
    mov  dx, cx   ; t2 low

    xchg bh, cl   ; t2 copy in bh

    mov  dh, cl  ; b2 copy

    
    MOV  BP, SPANSTART_SEGMENT


    ; t1-t2 is NOT t2 (t1 is FF)

    
    ; len is (b2 - t2) + 1 (because t1 is 0FFh. it surely wont be the limiting condition)
    inc  cx     ; +1
    sub  cl, bh ; b2 - t2 + 1
    jb   skip_first_spanstart_t2  ; no iter

    MOV ES, BP  ; for stosw

    ; cx = count
    
    add dl, cl ;  UPDATE T2 locally for next loop. bh continues unmodified for next loop iter.


    
    FAST_SHL1 DI
    REP STOSW
    ; CX = 0
    ; todo di has t2_after << 1. efficient to fetch that here?


    skip_first_spanstart_t2:

    ; register juggle to match mid loop state. TODO cleanup.
    
    ; state:

    ; ch = 0
    ; cl = garbage
    ; bl = b1_after
    ; bh = t2 unmodified
    ; dl = t2
    ; dh = b2
    ; ax = x (to write)

    ; while (b2 > b1 && b2>=t2)

    cmp  dh, bl
    jbe  skip_b2_loop_firstiter
    cmp  dh, dl
    jb   skip_b2_loop_firstiter

    ; lets iter forward, not backward.

    ; di = start = max(b1+1, t2)
    ; count = b2 - start

    mov  cl, dl ; t2
    cmp  cl, bl
    ja   use_b2_as_start_firstiter
    mov  cl, bl
    inc  cx
    use_b2_as_start_firstiter:
    MOV ES, BP  ; for stosw
    
    mov  di, cx  ; di is dest.
    mov  cl, dh
    sub  cx, di  ; cx = count
    inc  cx ; write an extra to inlcude the ending spot.


    FAST_SHL1 DI
    REP STOSW

    ; CX = 0
    skip_b2_loop_firstiter:

    ; hardcoded first iter done.



    jmp   plane_draw_loop_first_iter_entry

    ; todo bench inlining loop here
    

ALIGN_MACRO
    single_plane_draw_loop:
    public single_plane_draw_loop
    
    ; Register state (all not listed are junk/scratch):
    ; SS = FIXED_DS_SEGMENT
    ; AL = t2
    ; DX = t1 (dh = 0)
    ; BL = b1
    ; BH = b2
    ; BP = SPANSTART_SEGMENT
    ; SI = &visplanes[i].vp_top[x + 1]
    
    PUSH SI ; todo bench only push/pop around mapplanes.
    
    
    MOV BP, SPANSTART_SEGMENT
    



    ; these two are branch tested, leave as is

    cmp dl, al  ; (t1 < t2
    jae skip_first_mapplane_loop

    cmp dl, bl  ; t1 <= b1) 
    ja  skip_first_mapplane_loop  
    MOV SI, DX ; si = t1 ; used as t1_after 
    
    push ax
    push bx

    ; now lets calculate iter amount ( min(t2, b1+1)  - t1 )

    ; todo bench min/max algo vs branch
    mov dl, al          ; default ... TODO is ah 0? if so do math in AX.
    cmp dl, bl        ; todo branch test
    jbe use_t1_as_max
    mov dl, bl
    inc dx  ; b1+1
    use_t1_as_max:
    
    ; dx = t1 after. instead of push pop we will recover from si


    ; Register state (all not listed are junk/scratch):
    ; SS = FIXED_DS_SEGMENT
    ; DX = t1_after (will always be >= t1)
    ; BP = SPANSTART_SEGMENT
    ; SI = t1
    
    ; FIRST LOOP
    SUB DX, SI

    PUSH DX ; Count argument
    CALL R_MapPlanes24_


    mov dx, si ; si is t1 after? use that instead of push/pop dx?
    shr dx, 1  ; 
    pop bx  ; old values
    pop ax  ; old values

skip_first_mapplane_loop:

    ; AL = t2
    ; DX = t1_after (bh = 0)
    ; BL = b1
    ; BH = b2 (goes into ah)
    ; BP/SS/CS = same

;    while (b1 > b2 && b1>=t1)

    mov ah, bh   ; PUT B2 IN AH

    ; these two are branch tested, leave as is

    cmp bl, bh  ; todo branch test
    jbe skip_second_mapplane_loop

    cmp bl, dl
    jb  skip_second_mapplane_loop

    push ax
    push dx

    ; b1_end = b1.


    ; todo improve register juggle.
    ; dh is known zero.

    xchg  bl, dl  ; DX = b1_end, bl = t1
    mov   ax, dx  ; AX = b1_end, ah = 0


    ; todo bench min/max algo vs branch
    mov   dl, bl  ; DX = t1
    cmp   dl, bh    
    ja    use_t1_as_max_plane_2   ; b1_start = b2
    mov   dl, bh
    inc   dx      ; b1_start = b2+1
    use_t1_as_max_plane_2:

    mov   si, dx  ; desired start.. 


    dec   dx  ; because of swapping order, adjust for an overshoot by 1. 
    push  dx  ; recover this into b1 after call
    sub   ax, dx  ; count = b1_end - b1_start
    
    ; Register state (all not listed are junk/scratch):
    ; SS = FIXED_DS_SEGMENT
    ; AX = count
    ; BP = SPANSTART_SEGMENT
    
    ; SECOND LOOP
    
    PUSH AX ; Count argument
    CALL R_MapPlanes24_

    pop bx ; b1_start
    pop dx ; old values
    pop ax ; old values

skip_second_mapplane_loop:

    ; bl = b1_after (bh = garbage)
    ; dx = t1_after (dh = 0)
    ; al = t2
    ; ah = b2

    
    POP SI
    ; todo reduce juggle.

    
    xchg  ax, dx       ; dx = t2 lo, b2 hi
    xchg  ax, cx       ; cx = t1 lo, 0  hi
    
; first loop has t1 = 0FFh and cannot match the above checks.
; jump in with desired values

    SELFMODIFY_SPAN_loop_calc_x:
    LEA AX, [SI - 01000h] ; Calculate X from current pointer
    ENSUREALIGN_404:

    mov  bh, dl  ; t2 copy unmodified
    ; cx = t1_after (ch = 0)
    ; bl = b1_after
    ; bh = t2 unmodified
    ; dl = t2
    ; dh = b2
    ; ax = x (to write)


;    while (t2 < t1 && t2<=b2)

    ; these two are branch tested, leave as is


    cmp  dl, cl
    jae  skip_t2_loop
    cmp  dl, dh
    ja   skip_t2_loop

    ; todo feels inefficient below

    ; di needs t2..
    xchg ch, dh   ; zero high
    mov  di, dx   ; t2 with zero high
    xchg ch, dh   ; cx = t1, dx restored.

    cmp cl, dh
    jbe use_t1_for_count
    mov cl, dh
    inc cx
    use_t1_for_count:
    MOV ES, BP  ; for stosw

    ; cx = endpoint
    
    mov dl, cl ;  UPDATE T2 locally for next loop. bh continues unmodified for next loop iter.

    sub cx, di ; cx = count 

    
    FAST_SHL1 DI
    REP STOSW
    ; CX = 0
    ; todo di has t2_after << 1. efficient to fetch that here?


skip_t2_loop:


    ; ch = 0
    ; cl = garbage
    ; bl = b1_after
    ; bh = t2 unmodified
    ; dl = t2
    ; dh = b2
    ; ax = x (to write)

    ; while (b2 > b1 && b2>=t2)

    ; these two are branch tested, leave as is

    cmp  dh, bl
    jbe  skip_b2_loop
    cmp  dh, dl
    jb   skip_b2_loop

    ; lets iter forward, not backward.

    ; di = start = max(b1+1, t2)
    ; count = b2 - start

    mov  cl, dl ; t2
    cmp  cl, bl
    ja   use_b2_as_start
    mov  cl, bl
    inc  cx
    use_b2_as_start:
    MOV ES, BP  ; for stosw
    
    mov  di, cx  ; di is dest.
    mov  cl, dh
    sub  cx, di  ; cx = count
    inc  cx ; write an extra to inlcude the ending spot.


    FAST_SHL1 DI
    REP STOSW

    ; CX = 0
    skip_b2_loop:
plane_draw_loop_first_iter_entry:

    ; Register state (all not listed are junk/scratch):
    ; SS = FIXED_DS_SEGMENT
    ; AX = X
    ; BP = SPANSTART_SEGMENT
    ; ch = 0
    ; bh = t2 unmodified
    ; dh = b2
    ; ax = x
    ; SI = &visplanes[i].vp_top[x] (for next iter)

SELFMODIFY_SPAN_loop_stop:
    cmp AX, 01000h
ENSUREALIGN_403:

    ja  end_draw_loop_iteration
    

    
    
    MOV DI, SP
    MOV DS, WORD PTR SS:[DI + local_visplanesegment + 2]

    xchg ax, di  ; x value in di.


    ;run this loop after one iter, because first iter always uses t1 = 0xFF and would never pass an equality check anyway.
    mov bp, (VISPLANE_T.vp_bottom - VISPLANE_T.vp_top)

    ; this is not a real 'loop'. the last iteration will always stop at final t2 = FF.
    ; so this cannot end the drawspan loop. only the above CMP AX check can do so.


    mov dl, bh
    mov bh, bl
    mov bl, dh  ; old b2
    xor dh, dh  ; word t1


    ALIGN_MACRO
    loop_check_next_pixel:
    public loop_check_next_pixel


; NOT FASTER:
;   elaborate repe scasb checks
;   inline behind single_plane_draw_loop

; heuristic for a different test? big x2 - x1 means a more likely long iteration.
  ; does first run of the plane always map only?
; heurisitc for floor plane assuming b1=b2 is more likely? (screen bottom)
; heuristic for a ceiling plane assumping t1=t2 is more likely? (screen top)
; IDEAS  TO TEST:
; 0 improve general register usage and push/pop fewer?
; 1. write ahead jmp vs mov cx for the rep stosw blocks based on entry into the other blocks
; 2  mark top dirty, or mark bottom dirty. Nondirty means this visplane is screen width along bottom or top of screen.
    ; would allow a specialized loop with fixed values for top or bottom.
; x first iter skip mapplanes check (impossible because t1 = FF)

    MOV  BH, BYTE PTR DS:[SI + BP] ; Get new b2 
    lodsb
    cmp  al, dl
    jne  check_mapplanes
    cmp  bl, bh 
    jne  check_mapplanes
    
    MOV  BH, BYTE PTR DS:[SI + BP] ; Get new b2 
    lodsb
    cmp  al, dl
    jne  check_mapplanes_add_1
    cmp  bl, bh 
    jne  check_mapplanes_add_1
    
    MOV  BH, BYTE PTR DS:[SI + BP] ; Get new b2 
    lodsb
    cmp  al, dl
    jne  check_mapplanes_add_2
    cmp  bl, bh 
    jne  check_mapplanes_add_2
    
    MOV  BH, BYTE PTR DS:[SI + BP] ; Get new b2 
    lodsb
    cmp  al, dl
    jne  check_mapplanes_add_3
    cmp  bl, bh 
    jne  check_mapplanes_add_3
    
    MOV  BH, BYTE PTR DS:[SI + BP] ; Get new b2 
    lodsb
    cmp  al, dl
    jne  check_mapplanes_add_4
    cmp  bl, bh 
    jne  check_mapplanes_add_4
    
    MOV  BH, BYTE PTR DS:[SI + BP] ; Get new b2 
    lodsb
    cmp  al, dl
    jne  check_mapplanes_add_5
    cmp  bl, bh 
    jne  check_mapplanes_add_5
    
    MOV  BH, BYTE PTR DS:[SI + BP] ; Get new b2 
    lodsb
    cmp  al, dl
    jne  check_mapplanes_add_6
    cmp  bl, bh 
    jne  check_mapplanes_add_6

    MOV  BH, BYTE PTR DS:[SI + BP] ; Get new b2 
    lodsb
    cmp  al, dl
    jne  check_mapplanes_add_7
    cmp  bl, bh 
    jne  check_mapplanes_add_7


    add  di, 8
    jmp loop_check_next_pixel  
    
ALIGN_MACRO
end_draw_loop_iteration: ; LOOP DEPTH: 1
    POP BP ; Read visplane offset into a register for use
    MOV AX, SS
    MOV DS, AX ; Finally restore DS = SS

    JMP do_next_drawplanes_loop
ALIGN_MACRO

    check_mapplanes_add_2:
    inc  di
    check_mapplanes_add_1:
    inc  di

    check_mapplanes:
    ; do t1/t2/b1/b2 work


    ; BH = t1 (go to dl)
    ; dh = b1 (go to bl)
    ; bl = b2 (go to bh)
    ; al = t2 (fine)



    MOV WORD PTR CS:[SELFMODIFY_SPAN_ds_x2+1 - OFFSET R_SPAN24_STARTMARKER_], DI ; X value.

    ; DL = t1 DH = 0
    ; AL = t2
    ; BL = b1 BH = b2

    JMP single_plane_draw_loop
    check_mapplanes_add_3:
    add di, 3
    MOV WORD PTR CS:[SELFMODIFY_SPAN_ds_x2+1 - OFFSET R_SPAN24_STARTMARKER_], di ; X value.
    JMP single_plane_draw_loop

    check_mapplanes_add_4:
    add di, 4
    MOV WORD PTR CS:[SELFMODIFY_SPAN_ds_x2+1 - OFFSET R_SPAN24_STARTMARKER_], di ; X value.
    JMP single_plane_draw_loop
    
    check_mapplanes_add_5:
    add di, 5
    MOV WORD PTR CS:[SELFMODIFY_SPAN_ds_x2+1 - OFFSET R_SPAN24_STARTMARKER_], di ; X value.
    JMP single_plane_draw_loop
    
    check_mapplanes_add_6:
    add di, 6
    MOV WORD PTR CS:[SELFMODIFY_SPAN_ds_x2+1 - OFFSET R_SPAN24_STARTMARKER_], di ; X value.
    JMP single_plane_draw_loop
    
    check_mapplanes_add_7:
    add di, 7
    MOV WORD PTR CS:[SELFMODIFY_SPAN_ds_x2+1 - OFFSET R_SPAN24_STARTMARKER_], di ; X value.
    JMP single_plane_draw_loop
    
    ; ==================== HOLE HOLE HOLE ====================



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

plane_setup_hi:

; 83 e1 03 b5 01 d2 e5 88 e9 

and   cx, 3
mov   ch, 1
shl   ch, cl
mov   cl, ch

plane_setup_lo:

; d0 e9 b9 03 0f 72 02 b1 0c 

shr  cl, 1      ; odd detection
mov  cx, 0F0Ch  ; 15 hi for xor/compare.
jc   use_cl_12
mov  cl, 3
use_cl_12:




plane_setup_potato:

mov  cl, 15
jmp  skip_this
plane_setup_potato_end:
skip_this = plane_setup_potato_end + 5





ALIGN_MACRO	
PROC R_WriteBackViewConstantsSpan24_ FAR
PUBLIC R_WriteBackViewConstantsSpan24_ 



mov      ax, SPANFUNC_SEGMENT
mov      ds, ax


ASSUME DS:R_SPAN24_TEXT

les      ax, dword ptr ss:[_ds_source_offset]
mov      word ptr ds:[_ds_source_offset_span+0], ax
mov      word ptr ds:[_ds_source_offset_span+2], es

mov      ax, SPANFUNC_SEGMENT
mov      es, ax




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


mov     byte ptr ds:[_spanfunc_outp + 0], 1
mov     byte ptr ds:[_spanfunc_outp + 8], 2


mov      byte ptr ds:[SELFMODIFY_SPAN_and_detailshift_byte+2 - OFFSET R_SPAN24_STARTMARKER_], 3

mov      byte ptr ds:[SELFMODIFY_SPAN_sub_detailshift+2 - OFFSET R_SPAN24_STARTMARKER_], 4
mov      byte ptr ds:[SELFMODIFY_SPAN_and_detailshift_byte_2+2 - OFFSET R_SPAN24_STARTMARKER_], 3



IF COMPISA LE COMPILE_286
    mov      byte ptr ds:[SELFMODIFY_SPAN_compare_span_counter+2        - OFFSET R_SPAN24_STARTMARKER_], 040h
    mov      word ptr ds:[SELFMODIFY_SELECT_port_routine - OFFSET R_SPAN24_STARTMARKER_], 0E783h ; and di, x
ELSE
    mov      byte ptr ds:[SELFMODIFY_SPAN_compare_span_counter+2        - OFFSET R_SPAN24_STARTMARKER_], 3
    mov      word ptr ds:[SELFMODIFY_SPAN_skip_args_potato_386 - OFFSET R_SPAN24_STARTMARKER_], 0FA28h ; sub dl, bh
    mov      word ptr ds:[SELFMODIFY_SPAN_skip_args_low_386   - OFFSET R_SPAN24_STARTMARKER_], 0FA28h ; sub dl, bh
    mov      word ptr ds:[SELFMODIFY_adjust_cx_instruction    - OFFSET R_SPAN24_STARTMARKER_], 0E1D0h ; shl cl, 1
    
    mov      si, OFFSET plane_setup_hi
    mov      di, OFFSET SELFMODIFY_set_cx_to_vgaplane
    mov      cx, plane_setup_lo - plane_setup_hi
    rep      movsb
ENDIF

; sal   ax, 1 ; 0E0D1h

mov      ax, 0E0D1h  ; sal ax, 1
mov      word ptr ds:[SELFMODIFY_SPAN_detailshift_1+0 - OFFSET R_SPAN24_STARTMARKER_], ax
mov      word ptr ds:[SELFMODIFY_SPAN_detailshift_1+2 - OFFSET R_SPAN24_STARTMARKER_], ax



mov ax, 0EED1h  ; shr   si, 1
mov      word ptr ds:[SELFMODIFY_SPAN_detailshift2minus_1+0 - OFFSET R_SPAN24_STARTMARKER_], ax  
mov      word ptr ds:[SELFMODIFY_SPAN_detailshift2minus_1+2 - OFFSET R_SPAN24_STARTMARKER_], ax
mov ax, 0E8D1h  ; shr   ax, 1
mov      word ptr ds:[SELFMODIFY_SPAN_detailshift2minus_3+0 - OFFSET R_SPAN24_STARTMARKER_], ax  
mov      word ptr ds:[SELFMODIFY_SPAN_detailshift2minus_3+2 - OFFSET R_SPAN24_STARTMARKER_], ax

IF COMPISA LE COMPILE_286
    mov ax, 0F001h ; add ax, si
    mov      word ptr ds:[SELFMODIFY_SPAN_set_xfrac_lookup_potato - OFFSET R_SPAN24_STARTMARKER_], ax 
    mov      word ptr ds:[SELFMODIFY_SPAN_set_xfrac_lookup_low - OFFSET R_SPAN24_STARTMARKER_], ax 
    mov ax, 0EA28h ; sub dl, ch
    mov      word ptr ds:[SELFMODIFY_SPAN_set_loopcount_potato - OFFSET R_SPAN24_STARTMARKER_], ax 
    mov      word ptr ds:[SELFMODIFY_SPAN_set_loopcount_low - OFFSET R_SPAN24_STARTMARKER_], ax 

    mov ax, 0E900h ; add cl, ch
    mov      word ptr ds:[SELFMODIFY_SPAN_set_destview_potato - OFFSET R_SPAN24_STARTMARKER_], ax 
    mov      word ptr ds:[SELFMODIFY_SPAN_set_destview_low - OFFSET R_SPAN24_STARTMARKER_], ax 

    mov ax, 0DF00h ; add bh, bl
    mov      word ptr ds:[SELFMODIFY_SPAN_set_yfrac_lookup_potato - OFFSET R_SPAN24_STARTMARKER_], ax 
    mov      word ptr ds:[SELFMODIFY_SPAN_set_yfrac_lookup_low - OFFSET R_SPAN24_STARTMARKER_], ax 
ENDIF

mov      ax, 0C089h  ; nop
mov      word ptr ds:[SELFMODIFY_SPAN_detailshift_2+0 - OFFSET R_SPAN24_STARTMARKER_], ax
mov      word ptr ds:[SELFMODIFY_SPAN_detailshift_2+2 - OFFSET R_SPAN24_STARTMARKER_], ax


jmp     done_with_detailshift
ALIGN_MACRO	
do_detail_shift_one:

mov     word ptr ds:[_spanfunc_outp + 0],  3
mov     word ptr ds:[_spanfunc_outp + 8],  12





mov      byte ptr ds:[SELFMODIFY_SPAN_and_detailshift_byte+2 - OFFSET R_SPAN24_STARTMARKER_], 1

mov      byte ptr ds:[SELFMODIFY_SPAN_sub_detailshift+2 - OFFSET R_SPAN24_STARTMARKER_], 2
mov      byte ptr ds:[SELFMODIFY_SPAN_and_detailshift_byte_2+2 - OFFSET R_SPAN24_STARTMARKER_], 1




IF COMPISA LE COMPILE_286
    mov      byte ptr ds:[SELFMODIFY_SPAN_compare_span_counter+2        - OFFSET R_SPAN24_STARTMARKER_], 020h
    mov      word ptr ds:[SELFMODIFY_SELECT_port_routine - OFFSET R_SPAN24_STARTMARKER_],  ((SELFMODIFY_SELECT_port_routine_TARGET_LO -    SELFMODIFY_SELECT_port_routine_AFTER) SHL 8) + 0EBh
ELSE
    mov      byte ptr ds:[SELFMODIFY_SPAN_compare_span_counter+2        - OFFSET R_SPAN24_STARTMARKER_], 1
    
    mov      word ptr ds:[SELFMODIFY_SPAN_skip_args_potato_386 - OFFSET R_SPAN24_STARTMARKER_], 0FA28h ; sub dl, bh
    mov      word ptr ds:[SELFMODIFY_SPAN_skip_args_low_386 - OFFSET R_SPAN24_STARTMARKER_], ((SELFMODIFY_SPAN_skip_args_386_TARGET - SELFMODIFY_SPAN_skip_args_low_386_AFTER) SHL 8) + 0EBh
    mov      word ptr ds:[SELFMODIFY_adjust_cx_instruction    - OFFSET R_SPAN24_STARTMARKER_], 0E930h ; xor cl, ch
    mov      si, OFFSET plane_setup_lo
    mov      di, OFFSET SELFMODIFY_set_cx_to_vgaplane
    mov      cx, plane_setup_potato - plane_setup_lo
    rep      movsb

ENDIF







mov      word ptr ds:[SELFMODIFY_SPAN_detailshift_1+0 - OFFSET R_SPAN24_STARTMARKER_], 0E0D1h ; shl ax, 1
mov      word ptr ds:[SELFMODIFY_SPAN_detailshift_2+0 - OFFSET R_SPAN24_STARTMARKER_], 0E8D1h ; shr ax, 1






mov      word ptr ds:[SELFMODIFY_SPAN_detailshift2minus_1+0 - OFFSET R_SPAN24_STARTMARKER_], 0EED1h  ; shr   si, 1
mov      word ptr ds:[SELFMODIFY_SPAN_detailshift2minus_3+0 - OFFSET R_SPAN24_STARTMARKER_], 0E8D1h  ; shr   ax, 1
mov      ax, 0E0D1h

mov   ax, 0c089h  ; nop
mov      word ptr ds:[SELFMODIFY_SPAN_detailshift_1+2 - OFFSET R_SPAN24_STARTMARKER_], ax
mov      word ptr ds:[SELFMODIFY_SPAN_detailshift_2+2 - OFFSET R_SPAN24_STARTMARKER_], ax

mov      word ptr ds:[SELFMODIFY_SPAN_detailshift2minus_1+2 - OFFSET R_SPAN24_STARTMARKER_], ax
mov      word ptr ds:[SELFMODIFY_SPAN_detailshift2minus_3+2 - OFFSET R_SPAN24_STARTMARKER_], ax

IF COMPISA LE COMPILE_286
    mov      word ptr ds:[SELFMODIFY_SPAN_set_xfrac_lookup_potato - OFFSET R_SPAN24_STARTMARKER_], 0F001h ; add ax, si
    mov      word ptr ds:[SELFMODIFY_SPAN_set_yfrac_lookup_potato - OFFSET R_SPAN24_STARTMARKER_], 0DF00h ; add bh, bl
    mov      word ptr ds:[SELFMODIFY_SPAN_set_xfrac_lookup_low - OFFSET R_SPAN24_STARTMARKER_], ((SELFMODIFY_SPAN_set_xfrac_lookup_TARGET - SELFMODIFY_SPAN_set_xfrac_lookup_low_AFTER) SHL 8) + 0EBh
    mov      word ptr ds:[SELFMODIFY_SPAN_set_yfrac_lookup_low - OFFSET R_SPAN24_STARTMARKER_], ((SELFMODIFY_SPAN_set_yfrac_lookup_TARGET - SELFMODIFY_SPAN_set_yfrac_lookup_low_AFTER) SHL 8) + 0EBh
    mov ax, 0E900h ; add cl, ch

    mov      word ptr ds:[SELFMODIFY_SPAN_set_destview_potato - OFFSET R_SPAN24_STARTMARKER_], ax 
    mov ax, 0EA28h ; sub dl, ch
    mov      word ptr ds:[SELFMODIFY_SPAN_set_loopcount_potato - OFFSET R_SPAN24_STARTMARKER_], ax 
    mov      word ptr ds:[SELFMODIFY_SPAN_set_destview_low - OFFSET R_SPAN24_STARTMARKER_],    ((SELFMODIFY_SPAN_set_destview_TARGET -    SELFMODIFY_SPAN_set_destview_low_AFTER) SHL 8) + 0EBh
    mov      word ptr ds:[SELFMODIFY_SPAN_set_loopcount_low - OFFSET R_SPAN24_STARTMARKER_],    ((SELFMODIFY_SPAN_set_loopcount_TARGET -    SELFMODIFY_SPAN_set_loopcount_low_AFTER) SHL 8) + 0EBh

ENDIF



jmp     done_with_detailshift
ALIGN_MACRO	

do_detail_shift_two:





mov      byte ptr ds:[_spanfunc_outp + 0], 15 ; technically this never has to be changed 



IF COMPISA LE COMPILE_286
    mov      byte ptr ds:[SELFMODIFY_SPAN_compare_span_counter+2        - OFFSET R_SPAN24_STARTMARKER_], 0
    mov      word ptr ds:[SELFMODIFY_SELECT_port_routine - OFFSET R_SPAN24_STARTMARKER_],  ((SELFMODIFY_SELECT_port_routine_TARGET_POTATO -    SELFMODIFY_SELECT_port_routine_AFTER) SHL 8) + 0EBh
    mov      byte ptr ds:[SPANFUNC_ARG_PORT_BYTE + 0 * SPANFUNC_ARG_SIZE], 15
ELSE
    mov      byte ptr ds:[SELFMODIFY_SPAN_compare_span_counter+2        - OFFSET R_SPAN24_STARTMARKER_], 0
    
    mov      word ptr ds:[SELFMODIFY_SPAN_skip_args_potato_386 - OFFSET R_SPAN24_STARTMARKER_], ((SELFMODIFY_SPAN_skip_args_386_TARGET - SELFMODIFY_SPAN_skip_args_potato_386_AFTER) SHL 8) + 0EBh
    mov      si, OFFSET plane_setup_potato
    mov      di, OFFSET SELFMODIFY_set_cx_to_vgaplane
    mov      cx, plane_setup_potato_end - plane_setup_potato
    rep      movsb


    
ENDIF

mov      ax, 0E8D1h  ; shr ax, 1

mov      word ptr ds:[SELFMODIFY_SPAN_detailshift_2+0 - OFFSET R_SPAN24_STARTMARKER_], ax
mov      word ptr ds:[SELFMODIFY_SPAN_detailshift_2+2 - OFFSET R_SPAN24_STARTMARKER_], ax

mov      ax, 0c089h  ; nop


mov      word ptr ds:[SELFMODIFY_SPAN_detailshift_1+0 - OFFSET R_SPAN24_STARTMARKER_], ax
mov      word ptr ds:[SELFMODIFY_SPAN_detailshift_1+2 - OFFSET R_SPAN24_STARTMARKER_], ax


IF COMPISA LE COMPILE_286
    mov      word ptr ds:[SELFMODIFY_SPAN_set_xfrac_lookup_potato - OFFSET R_SPAN24_STARTMARKER_], ((SELFMODIFY_SPAN_set_xfrac_lookup_TARGET - SELFMODIFY_SPAN_set_xfrac_lookup_potato_AFTER) SHL 8) + 0EBh
    mov      word ptr ds:[SELFMODIFY_SPAN_set_yfrac_lookup_potato - OFFSET R_SPAN24_STARTMARKER_], ((SELFMODIFY_SPAN_set_yfrac_lookup_TARGET - SELFMODIFY_SPAN_set_yfrac_lookup_potato_AFTER) SHL 8) + 0EBh
    mov      word ptr ds:[SELFMODIFY_SPAN_set_loopcount_potato - OFFSET R_SPAN24_STARTMARKER_],    ((SELFMODIFY_SPAN_set_loopcount_TARGET -    SELFMODIFY_SPAN_set_loopcount_potato_AFTER) SHL 8) + 0EBh
    mov      word ptr ds:[SELFMODIFY_SPAN_set_destview_potato - OFFSET R_SPAN24_STARTMARKER_],    ((SELFMODIFY_SPAN_set_destview_TARGET -    SELFMODIFY_SPAN_set_destview_potato_AFTER) SHL 8) + 0EBh
ENDIF


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


; todo get segment? use in r_sky?

ALIGN 16
SPAN_LOCAL_DC_YL_LOOKUP_TABLE:
PUBLIC SPAN_LOCAL_DC_YL_LOOKUP_TABLE


sumof80s = 0
MAX_PIXELS = 200
REPT MAX_PIXELS
    dw sumof80s 
    sumof80s = sumof80s + 80
ENDM





; end marker for this asm file
PROC R_SPAN24_ENDMARKER_ FAR
PUBLIC R_SPAN24_ENDMARKER_ 
ENDP

ENDS

public ENSUREALIGN_400
public ENSUREALIGN_401
public ENSUREALIGN_402
public ENSUREALIGN_403
public ENSUREALIGN_404
public ENSUREALIGN_406
public ENSUREALIGN_408
public ENSUREALIGN_409


IF COMPISA LE COMPILE_286
    public ENSUREALIGN_407
    public ENSUREALIGN_410
ELSE
ENDIF


END

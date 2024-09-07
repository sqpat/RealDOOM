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

.DATA

EXTRN	_centery:WORD


EXTRN	_dc_colormap_index:BYTE
EXTRN	_dc_colormap_segment:WORD



EXTRN   _sp_bp_safe_space:WORD
EXTRN   _ss_variable_space:WORD



EXTRN FixedMul_:PROC

COLFUNC_JUMP_LOOKUP_SEGMENT    = 6A10h
COLFUNC_FUNCTION_AREA_SEGMENT  = 6A42h
COLFUNC_JUMP_AND_DC_YL_OFFSET_DIFF   = ((DC_YL_LOOKUP_SEGMENT - COLFUNC_JUMP_LOOKUP_SEGMENT) * 16)
COLFUNC_JUMP_AND_FUNCTION_AREA_OFFSET_DIFF = ((COLFUNC_FUNCTION_AREA_SEGMENT - COLFUNC_JUMP_LOOKUP_SEGMENT) * 16)

COLFUNC_JUMP_OFFSET            = 049h

DRAWCOL_OFFSET                 = 2420h


DC_YL_LOOKUP_SPACE             = _ss_variable_space+4





;=================================

.CODE

;
; R_DrawColumn
;
	
PROC  R_DrawColumn_
PUBLIC  R_DrawColumn_

; no need to push anything. outer function just returns and pops

    ; di contains shifted dc_x relative to details
    ; cx contains dc_yl

    cli 									; disable interrupts
    push bp

    mov   ax, cx  ; todo improve
    
	; shift already done earlier
    
	


    mov   bx, word ptr [_dc_iscale + 0]   
    mov   ch, byte ptr [_dc_iscale + 2]      ; 2nd byte of high word not used up ahead...
    mov   cl, bh                             ; construct dc_iscale + 1 word
    mov   bp, cx                             ; cache for later to avoid going to memory

    
    sub   ax, word ptr [_centery]
    mov   es, ax              ; save low(M1)

;  DX:AX * CX:BX

; note this is 8 bit times 32 bit and we want the mid 16


	CWD
	AND DX, BX
	NEG DX



    mul     ch;             ; only the bottom 16 bits are necessary.
    add     dx,ax           ; - add to total
    mov     cx,dx           ; - hold total in cx
    mov     ax,es           ; restore low(M1)
    mul     bx              ; low(M2) * low(M1)
    add     dx,cx           ; add previously computed high part


; multiply completed. 
; dx:ax is the 32 bits of the mul. we want dx to have the mid 16.

;    finishing  dc_texturemid.w + (dc_yl-centery)*fracstep.w


    mov   dh, dl
    mov   dl, ah                          ; mid 16 bits of the 32 bit dx:ax into dx
    
    ; 2 less
    add   dx, word ptr [_dc_texturemid+1]   ; first add dx_texture mid


    
    ; bx still has dc_iscale low word from above. prepare low bits of precision
    mov cl, 5
    shr bl, cl          ; cx is now 0. is that useful? 
    xor bh, bh
    
    mov cx, bp          ; mid 16 bits of fracstep are the mid 16 of dc_iscale, which was prepped above.
    mov bp, bx

    

    ; for fixing jaggies... need extra precision from time to time


   ;  prep our loop variables


   mov     es, word ptr [_destview + 2]    ; ready the viewscreen segment
   xor     bx, bx       ; common bx offset of zero in the xlats ahead

   mov     ds, word ptr [_dc_source_segment]     ; this will be ds..
   mov     si,  4Fh
   mov     ah,  7Fh   ; for ANDing to AX to mod al by 128 and preserve AH


   jmp loop_done         ; relative jump to be modified before function is called


pixel_loop_fast:

   ;; 12 bytes loop iter

; 0xC size
DRAW_SINGLE_PIXEL MACRO 
   ; tried to reorder adds in between xlats and stos, but it didn't make anything faster.

    mov    al,dh
	and    al,ah                  ; ah is 7F
	xlat   BYTE PTR ds:[bx]       ;
	xlat   BYTE PTR cs:[bx]       ; before calling this function we already set CS to the correct segment..
	stos   BYTE PTR es:[di]       ;
	add    dx,cx
	add    di,si                  ; si has 79 (0x4F) and stos added one
ENDM


; 0x10 size
DRAW_SINGLE_PIXEL_WITH_CORRECTION MACRO 
   ;   fix 'jaggies' by overcorrecting a bit

    mov    al,dh
	and    al,ah                  ; ah is 7F

	xlat   BYTE PTR ds:[bx]       ;
	xlat   BYTE PTR cs:[bx]       ; before calling this function we already set CS to the correct segment..
	stos   BYTE PTR es:[di]       ;
    add    dx,bp                  ; low 8 bits of precision times eight being added
	add    dx,cx
	add    di,si                  ; si has 79 (0x4F) and stos added one
ENDM

REPT 24
    REPT 4
        DRAW_SINGLE_PIXEL
    ENDM
    DRAW_SINGLE_PIXEL_WITH_CORRECTION
    REPT 3
        DRAW_SINGLE_PIXEL
    ENDM
ENDM

REPT 4
    DRAW_SINGLE_PIXEL
ENDM
    DRAW_SINGLE_PIXEL_WITH_CORRECTION
REPT 2
    DRAW_SINGLE_PIXEL
ENDM

; draw last pixel, cut off the add

    mov    al,dh
	and    al,ah                  ; ah is 7F
	xlat   BYTE PTR ds:[bx]       ;
	xlat   BYTE PTR cs:[bx]       ; before calling this function we already set CS to the correct segment..
	stos   BYTE PTR es:[di]       ;
	; dont need these in last loop
    ;add    di,si                  ; si has 79 (0x4F) and stos added one
	;add    dx,cx

loop_done:
; clean up

; restore ds without going to memory.

    mov ax, ss
    mov ds, ax

    pop bp
    sti
    retf


ENDP






;
; R_DrawColumnPrep
;
	
PROC  R_DrawColumnPrep_
PUBLIC  R_DrawColumnPrep_ 

; argument AX is diff for various segment lookups

push  bx
push  cx
push  dx
push  si
push  di



add   ax, COLFUNC_JUMP_LOOKUP_SEGMENT        ; compute segment now, clear AX dependency
mov   es, ax                                 ; store this segment for now, with offset pre-added

mov   di, word ptr [_dc_x]
mov   cl, byte ptr [_detailshift2minus] ; todo make this word ptr to get bh 0 for free below, or contain the preshifted by 2 in bh to avoid double sal
shr   di, cl



; dest = destview + dc_yl*80 + (dc_x>>2); 
; frac.w = dc_texturemid.w + (dc_yl-centery)*dc_iscale







mov   si, word ptr [_dc_yh]                  ; grab dc_yh
mov   bx, word ptr [_dc_yl]
mov   cx, bx
sub   si, bx                                 ;
add   bx, bx                                 ; double dc_yl to get a word offset
add   bx, COLFUNC_JUMP_AND_DC_YL_OFFSET_DIFF;
add   di, word ptr es:[bx]                  ; set up destview 
add   di, word ptr [_destview + 0] 		    ; add destview offset


add   si, si                                 ; double diff (dc_yh - dc_yl) to get a word offset
mov   ax, word ptr es:[si]                   ; get the jump value
mov   word ptr es:[COLFUNC_JUMP_OFFSET+COLFUNC_JUMP_AND_FUNCTION_AREA_OFFSET_DIFF], ax  ; overwrite the jump relative call for however many iterations in unrolled loop we need
mov   al, byte ptr [_dc_colormap_index]      ; lookup colormap index
; what follows is compution of desired CS segment and offset to function to allow for colormaps to be CS:BX and match DS:BX column
mov   dx, word ptr [_dc_colormap_segment]    
mov   si, OFFSET _ss_variable_space ; lets use this variable space
test  al, al
jne    skipcolormapzero

mov   word ptr [si], DRAWCOL_OFFSET				; setup dynamic call
mov   word ptr [si+2], dx

db 0FFh  ; lcall[si]
db 01Ch  ;


pop   di 
pop   si
pop   dx
pop   cx
pop   bx
retf  


; if colormap is not zero we must do some segment math
skipcolormapzero:
mov   bx, DRAWCOL_OFFSET

cbw           ; al is like 0-20 so this will zero out ah...
xchg   ah, al ; move it high with 0 al.
sub   bx, ax
shr   ax, 1
shr   ax, 1
shr   ax, 1
shr   ax, 1
add   dx, ax

mov   word ptr [si], bx				; setup dynamic call
mov   word ptr [si+2], dx

db 0FFh  ; lcall[si]
db 01Ch  ;

pop   di ; unused but drawcol clobbers it.
pop   si
pop   dx
pop   cx
pop   bx
retf   

ENDP



END
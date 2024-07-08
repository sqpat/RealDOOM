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
	INCLUDE defs.incs

;=================================
.DATA




.CODE

;
; R_DrawSkyColumn
;

	
PROC  R_DrawSkyColumn_
PUBLIC  R_DrawSkyColumn_
    ; ax contains dc_yh...
    ; dx contails dc_yl
    push bx
    push cx
    push dx
    push si
    push di

    ; 	outp (SC_INDEX+1,1<<(dc_x&3));
    
    mov   si, dx     ; copy dc_yl for later
    
	mov   di, word ptr [_dc_x]
    sub   ax, dx     ; ax now has count?
    mov   cx, 2     ; zero out ch for later
    
    ; GENERATE UNROLLED JUMP CALL
    ; ax is 0 to 127. we want 128 - ax...

 ; NOTE! just doing a xor of 127 leads to a crash when we do draw over 127 (which i think is only possible with idclip?)
 ; regardless, i really want to avoid using a branch to cap the value to 127, so we take this sort of half measure 

    xor   al, 0FFh          
    and   al, 07Fh           
    

    ; get instruction count for ax..
    ; 4 instructions per loop
    sal   ax, cl
    mov   word ptr [OFFSET jump_location + 1], ax   ; modify the jump

    
    mov   ax, di    ; copy di...
    

	mov   bl, byte ptr [_detailshift]
    xor   bh, bh
	sub   cl, bl
    shr   di, cl


    and   al, 3     ; and dc_x by 3
	sal   bl, 1
	sal   bl, 1
	add   bl, al

    mov al, byte ptr [_quality_port_lookup + bx]

    mov   dx, 3c5h
    out   dx, al

    ; dest = destview + dc_yl*80 + (dc_x>>2); 
    ; frac.w = dc_texturemid.w + (dc_yl-centery)*dc_iscale
 
	; shift already done earlier
    ; no texture calc overhead. add one pixel at a time via lodsb
    
    mov   ax, DC_YL_LOOKUP_SEGMENT             ; get segment for mul 80
    mov   es, ax                                 ; 
    mov   bx, si
    add   bx, bx                                 ; dc_yl lookup pointer
    add   di, word ptr [es:bx]                   ; quick mul 80

    add   di, word ptr [_destview + 0] 		 ; add destview offset, dest index set up

   ;  prep our loop variables

   mov     es, word ptr [_destview + 2]    ; ready the viewscreen segment
   mov     ax, word ptr [_dc_source_segment]     ; this will be ds..
   mov     ds, ax                          ; do this last, makes us unable to to ref other vars...
   mov     cl, 4Fh

   ; should be able to easily do a lookup into here with available registers (ax, dx, bx)

jump_location:
    jmp sky_loop_done
sky_pixel_loop_fast:


DRAW_SINGLE_SKY_PIXEL MACRO 
; main loop: no colormaps, add by one texel at a time... skip dx, just do lodsb


    lodsb                         ; BYTE PTR ds:[si]       
	stosb                         ; BYTE PTR es:[di]      
	add    di,cx                  ; cx holds 79, need to add by the sky offset.

ENDM

REPT 127
    DRAW_SINGLE_SKY_PIXEL
endm


; draw last pixel, cut off the add

    lodsb               ; BYTE PTR ds:[si]       
	stosb               ; BYTE PTR es:[di]       


sky_loop_done:
; clean up

; restore ds without going to memory.
    mov ax, ss
    mov ds, ax
    
    
    pop di
    pop si
    pop dx
    pop cx
    pop bx

    retf


ENDP

END


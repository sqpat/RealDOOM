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
.DATA



EXTRN _viewangle_shiftright3:WORD
EXTRN _dc_source_segment:WORD
EXTRN _ds_x1:WORD
EXTRN _dc_x:WORD


.CODE

;
; R_DrawSkyColumn
;

	
PROC  R_DrawSkyColumn_
PUBLIC  R_DrawSkyColumn_
    ; ax contains dc_yh...
    ; dx contails dc_yl...  
    ; bx contains dc_x (don't modify)
    ; NOTE ah may be garbage but dh is 0

    mov   si, dx     ; copy dc_yl for later
    sub   al, dl     ; al now has count. 
    
    ; GENERATE UNROLLED JUMP CALL
    ; ax is 0 to 127. we want 128 - ax...

 ; NOTE! just doing a xor of 127 leads to a crash when we do draw over 127 (which i think is only possible with idclip?)
 ; regardless, i really want to avoid using a branch to cap the value to 127, so we take this sort of half measure 

    xor   al, 0FFh          
    and   al, 07Fh           
    

    ; get instruction count for ax..
    ; 3 instructions per loop
    cbw   ; zero out ah because we anded it to 127 anyway.

    mov   dx, ax    ; dh zero maintained 
    add   ax, dx   
    add   ax, dx   ; ax is tripled..
    mov   word ptr [OFFSET jump_location + 1], ax   ; modify the jump

    ; dest = destview + dc_yl*80 + (dc_x>>2); 

	; shift of dc_x already done outside
    ; no texture calc overhead. add one pixel at a time via lodsb
    
    mov   ax, DC_YL_LOOKUP_SEGMENT             ; get segment for mul 80
    mov   es, ax                                 ; 
    sal   si, 1                                 ; dc_yl mul 80 word lookup pointer
    mov   ax, word ptr es:[si]                  ; quick mul 80
    sar   si, 1                                 ; si back to dc_yl


    ; draw this sky column. let's generate the sky column segment.
    ;  				segment_t texture_x  = ((viewangle_shiftright3 + xtoviewangle[x])) & 0x7F8;
    mov   cx, XTOVIEWANGLE_SEGMENT
    mov   es, cx
    mov   dx, word ptr [_viewangle_shiftright3]
    mov   di, bx    ; grab dc_x
    sal   di, 1
    add   dx, word ptr es:[di]

    ; 	dc_source_segment = skytexture_texture_segment + texture_x;

    
    mov cl, byte ptr [_detailshift2minus]
    inc cl  ; plus 1 to account for sal di 1 above..
    shr di, cl  ; preshift dc_x by detailshift. Plus one for the earlier word offset shift.

    ; move operations beyond the shr to keep prefetch busy...

    and   dx, 07F8h
    add   dx, SKYTEXTURE_TEXTURE_SEGMENT
    ; dx contains dc source segment for the function

    add di, ax
    les ax, dword ptr [_destview]
    add di, ax



   ;  prep our loop variables

   mov     ds, dx                          ; cx contained dc_source_segment
   mov     ax, 004Fh
   cwd     ; zero out dx 
   ; should be able to easily do a lookup into here with available registers (ax, dx, bx)

jump_location:
    jmp sky_loop_done
sky_pixel_loop_fast:


DRAW_SINGLE_SKY_PIXEL MACRO 
; main loop: no colormaps, add by one texel at a time... skip dx, just do lodsb
    movsb
	add    di,ax                  ; dx holds 79, need to add by screenwidth / 4 to get the next dest pixel

ENDM

REPT 127
    DRAW_SINGLE_SKY_PIXEL
endm


; draw last pixel, cut off the add
    movsb


sky_loop_done:
; clean up

; restore ds without going to memory.
    mov ax, ss
    mov ds, ax  ; restore ds
    

    ret


ENDP

 

;
; R_DrawSkyPlane
;

; ax =
; dx
; cx:bx is pl? seems cx/bx can be destroyed freely here

PROC  R_DrawSkyPlane_ NEAR
PUBLIC  R_DrawSkyPlane_

; bp - 2 xoffset
; bp - 4 initial bx (pl )
; bp - 6 initial cx  (pl)
; bp - 8 minx 
; bp - A minxbase4   (minx & 0xFFFC)
; bp - C maxx
; bp - E 4 >> detailshift

push  si
push  di
push  bp
mov   bp, sp

push  0                         ; bp-2 initial xoffset value
push  bx                        ; bp-4
push  cx                        ; bp-6
push  ax                        ; bp-8 minx  
mov   bx, ax
and   al,  0FCh                 ; 
push  ax                        ; bp-A minxbase4
push  dx                        ; bp-c maxx

; todo investigate speedup on 286 of removing this stack var and using the ds one...
mov   al, byte ptr [_detailshiftitercount]
cbw


push  ax                        ; bp-E


start_drawing_next_vga_plane:

; prep some detailshift stuff
mov   ax, word ptr [bp - 2]         ; zero out ah


mov   dx, word ptr [bp - 0Ah]
add   dx, ax

cmp   dx, word ptr [bp - 08h]               ; if below minx then increment by detail step
jge   start_drawing_vga_plane

add   dx, word ptr [bp - 0Eh]

start_drawing_vga_plane:
; out the appropriate plane value

mov   bl, byte ptr [_detailshift+1]       ; grab pre-shifted by 2 detailshift 
add   bl, al                              ; al is the current plane, dc_x & 3
xor   bh, bh
mov al, byte ptr [_quality_port_lookup + bx]


mov   bx, dx   ; copy this value to bx now
mov   dx, 03C5h
out   dx, al

mov   dl, byte ptr [bp - 0Eh]    

cmp   bx, word ptr [bp - 0Ch]  ; compare to maxx
jg    increment_vga_plane

cwd   ; zero out dx, specifically dh. it will remain 0 for the whole vga plane iteration, simplifying some things

mov   ax, bx
mov   si, word ptr [bp - 04h]
add   ax, bx
add   si, bx

draw_next_column:


; si is the x lookup 
;			dc_yl = pl->top[x];
;			dc_yh = pl->bottom[x];				
; note we dont actually store dc_yh dc_yl, they stay in ax/dx

mov   es, word ptr [bp - 06h]
mov   al, byte ptr es:[si + 0144h]  ; dc_yl
mov   dl, byte ptr es:[si + 2]      ; dc_yh

; remember dh is already zeroed.

cmp   dl, al
; dc_yh > dc_yl. unsigned compare because these values are smaller than 255 but high bytes may be garbage.
ja    skip_column_draw              

push si     ; we need scratch space here. push this now instead of in r_drawskycolumn


; function expects 
  ; ax = dc_yh
  ; dx = dc_yl,
  ; bx = dc_x (don't modify)
call  R_DrawSkyColumn_

pop si  ; retrieve si


; note: the above functions zeroes out DH

skip_column_draw:
mov   dl, byte ptr [bp - 0Eh]     ; dh is 0
add   bx, dx     ; increment x/dc_x by step
add   si, dx     ; increment pl->top/bot lookup
cmp   bx, word ptr [bp - 0Ch]
jle   draw_next_column

increment_vga_plane:

inc   word ptr [bp - 2]
cmp   byte ptr [bp - 2], dl
jge   exitfunc
jmp   start_drawing_next_vga_plane
exitfunc:
LEAVE_MACRO
pop   di
pop   si
ret

ENDP

END


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
INSTRUCTION_SET_MACRO

;=================================
.DATA

SKY_TEXTURE_MID = 100



.CODE

PROC R_SKYFL_STARTMARKER_ FAR
PUBLIC R_SKYFL_STARTMARKER_
ENDP


; standard skycolumn call - this happens on larger screensizes where texel coord v is 
; added to by 1 per pixel . I.e. screenblocks >= 10 (full screen in x-coord)

;
; R_DrawSkyColumn
;

	
PROC  R_DrawSkyColumnFL_ NEAR
PUBLIC  R_DrawSkyColumnFL_
    ; ax contains dc_yh...
    ; dx contails dc_yl...  
    ; bx contains dc_x (don't modify)
    ; NOTE ah may be garbage but dh is 0

    mov   si, dx     ; copy dc_yl for later
    sub   al, dl     ; al now has count. 
    
    ; GENERATE UNROLLED JUMP CALL
    ; ax is 0 to 200. we want 200 - ax...

 ; NOTE! just doing a xor of 127 leads to a crash when we do draw over 127 (which i think is only possible with idclip?)
 ; regardless, i really want to avoid using a branch to cap the value to 127, so we take this sort of half measure 

    
    mov   dx, 200
    sub   dl, al          
    

    ; get instruction count for ax..
    ; 3 instructions per loop

    mov   ax, dx    ; dh zero maintained 
    add   ax, dx   ; ax 2x
    add   ax, ax   ; ax 4x
    add   ax, dx   ; ax 5x
    mov   word ptr cs:[((OFFSET SELFMODIFY_SKY_unrolled_jump_location + 1) - R_SKYFL_STARTMARKER_)], ax   ; modify the jump

    ; dest = destview + dc_yl*80 + (dc_x>>2); 

	; shift of dc_x already done outside
    ; no texture calc overhead. add one pixel at a time via lodsb
    
    mov   ax, DC_YL_LOOKUP_SEGMENT             ; get segment for mul 80
    mov   es, ax                                 ; 
    mov   di, bx    ; grab dc_x
    mov   bx, si    ; for double lookup..
    mov   ax, word ptr es:[si+bx]                  ; quick mul 80


    ; draw this sky column. let's generate the sky column segment.
    ;  				segment_t texture_x  = ((viewangle_shiftright3 + xtoviewangle[x])) & 0x7F8;
    les   dx, dword ptr ds:[_viewangle_shiftright3]
    mov   bx, di    ; for double lookup
    add   dx, word ptr es:[bx+di]

    ; 	dc_source_segment = skytexture_texture_segment + texture_x;

    ; cl is unchanged throughout looped calls to this func, already contains detailshift2minus
    shr di, cl  ; preshift dc_x by detailshift. Plus one for the earlier word offset shift.

    ; move operations beyond the shr to keep prefetch busy...

    and   dx, 07F8h
    add   dx, SKYTEXTURE_TEXTURE_SEGMENT
    ; dx contains dc source segment for the function

    add di, ax
    les ax, dword ptr ds:[_destview]
    add di, ax



   ;  prep our loop variables

   ; starting point for sky texture is 100 + (dc_yl - centery), basically.
   add     si, SKY_TEXTURE_MID
   sub     si, word ptr ds:[_centery]
   
    ; OKAY this is a little sad but, we must AND si to 127 each pixel.
    ; because the starting point is not totally static we wouldnt otherwise know where to subtract 128 once.


   mov     ds, dx                          ; dx contained dc_source_segment
   mov     ax, 004Fh
   mov     dx, 127
   ; should be able to easily do a lookup into here with available registers (ax, dx, bx)

   SELFMODIFY_SKY_unrolled_jump_location:
   jmp sky_loop_done


DRAW_SINGLE_SKY_PIXEL MACRO 
; main loop: no colormaps, add by one texel at a time... skip dx, just do lodsb
    movsb
	add    di, ax                  ; ax holds 79, need to add by screenwidth / 4 to get the next dest pixel
    and    si, dx
ENDM

REPT 200
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

PROC  R_DrawSkyPlaneDynamicFL_ FAR
PUBLIC  R_DrawSkyPlaneDynamicFL_

PROC  R_DrawSkyPlaneFL_ FAR
PUBLIC  R_DrawSkyPlaneFL_

; bp - 2 initial bx (pl )
; bp - 4 initial cx  (pl)
; bp - 6 minx 
; bp - 8 minxbase4   (minx & 0xFFFC)
; bp - A maxx
; bp - C 4 >> detailshift

push  si
push  di
push  bp
mov   bp, sp

push  bx                        ; bp-2
push  cx                        ; bp-4
push  ax                        ; bp-6 minx  
mov   bx, ax
and   al, 0FCh                  ; 
push  ax                        ; bp-8 minxbase4
push  dx                        ; bp-A maxx

; todo make this a constant and write it in executesetviewsize
mov   ax, word ptr ds:[_detailshiftitercount]


push  ax                        ; bp-C

mov cx, word ptr ds:[_detailshift2minus]

start_drawing_next_vga_plane:

; prep some detailshift stuff
mov   al, ch
cbw    ; zero out ah

mov   bx, ax
add   ax, word ptr [bp - 08h]


cmp   ax, word ptr [bp - 06h]               ; if below minx then increment by detail step
jge   start_drawing_vga_plane

add   ax, word ptr [bp - 0Ch]

start_drawing_vga_plane:
; out the appropriate plane value

add   bl, byte ptr ds:[_detailshift+1]       ; grab pre-shifted by 2 detailshift 
mov   bl, byte ptr ds:[_quality_port_lookup + bx]


xchg   bx, ax   ; swap these values
mov   dx, SC_DATA
out   dx, al


cmp   bx, word ptr [bp - 0Ah]  ; compare to maxx
jg    increment_vga_plane

cwd   ; zero out dx, specifically dh. it will remain 0 for the whole vga plane iteration, simplifying some things

mov   ax, bx
mov   si, word ptr [bp - 02h]
add   ax, bx
add   si, bx

draw_next_column:


; si is the x lookup 
;			dc_yl = pl->top[x];
;			dc_yh = pl->bottom[x];				
; note we dont actually store dc_yh dc_yl, they stay in ax/dx

mov   es, word ptr [bp - 04h]
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
call  R_DrawSkyColumnFL_

pop si  ; retrieve si


; note: the above functions zeroes out DH

skip_column_draw:
mov   dl, byte ptr [bp - 0Ch]     ; dh is 0
add   bx, dx     ; increment x/dc_x by step
add   si, dx     ; increment pl->top/bot lookup
cmp   bx, word ptr [bp - 0Ah]
jle   draw_next_column

increment_vga_plane:

inc   ch
mov   dl, byte ptr [bp - 0Ch]   ; might happen twice in a row... more rare than not   
cmp   ch, dl
jge   exitfunc
jmp   start_drawing_next_vga_plane
exitfunc:
LEAVE_MACRO
pop   di
pop   si

retf

ENDP

; end marker for this asm file
PROC R_SKYFL_ENDMARKER_ FAR
PUBLIC R_SKYFL_ENDMARKER_
ENDP


END


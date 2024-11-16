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

SKY_TEXTURE_MID = 100



.CODE

; standard skycolumn call - this happens on larger screensizes where texel coord v is 
; added to by 1 per pixel . I.e. screenblocks >= 10 (full screen in x-coord)

;
; R_DrawSkyColumn
;

	
PROC  R_DrawSkyColumn_ NEAR
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
    mov   word ptr cs:[((OFFSET jump_location + 1) - R_DrawSkyColumn_)], ax   ; modify the jump

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

   ; bugfix starting point for sky texture is 100 + (dc_yl - centery), basically.
   add     si, SKY_TEXTURE_MID
   sub     si, word ptr ds:[_centery]
   
   mov     ds, dx                          ; dx contained dc_source_segment
   mov     ax, 004Fh
   cwd     ; zero out dx 
   ; should be able to easily do a lookup into here with available registers (ax, dx, bx)

   jump_location:
   jmp sky_loop_done


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


; this happens on smaller screensizes where texel coord v is not simply 
; added to by 1 per pixel . I.e. screenblocks < 10 (non-full screen in x-coord)

; todo this function can probably be cleaned up a little bit.

;
; R_DrawSkyColumnDynamic
;

	
PROC  R_DrawSkyColumnDynamic_ NEAR
PUBLIC  R_DrawSkyColumnDynamic_
    ; ax contains dc_yh...
    ; dx contails dc_yl...  
    ; bx contains dc_x (don't modify)
    ; NOTE ah may be garbage but dh is 0


    push bx

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

    mov   dx, ax   ; dh zero maintained 
    add   ax, ax   ; ax is 2xed..
    add   ax, ax   ; ax is 4xed..
    add   ax, dx   ; ax is 5xed..
    add   ax, ax   ; ax is 10xed..
    
    mov   word ptr cs:[((OFFSET jump_location_dynamic + 1) - R_DrawSkyColumn_)], ax   ; modify the jump

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

    add   di, ax
    les   ax, dword ptr ds:[_destview]
    add   di, ax

   ;  prep our loop variables

   ; starting point for sky texture is 100 + (dc_yl - centery) * fracstep
   
   
   ; ax = dc_yl - centery
   mov    ax, SKY_TEXTURE_MID

   xchg   ax, si


   sub    ax, word ptr ds:[_centery]
   ; get middle sixteen bits of scale. top 8 are 0. todo: make this 24 somehow? used bp and sp?
   mov    bx, word ptr ds:[_pspriteiscale+1] 
   
   mov    ds, dx                          ; dx contained dc_source_segment
   
   ; 	bx =  dc_iscale = pspriteiscale>>detailshift;
   ; need to shift by 2 - cl... messy but ah well
   sal    bx, cl
   sar    bx, 1
   sar    bx, 1
   
   ; multiply by fracstep and take 16 middle bits?
   mul    bx
   mov    dh, al   ; hold this for a sec...

   mov    al, ah
   mov    ah, dl

   neg   dh
   neg   dh ; ugly... we want carry flag if nonzero, but we want dh unchanged, so do this twice.
   
   adc    si, ax; add by one if low eight bits non zero; i.e. "round up"

   and    si, 127
   
   mov    ax, bx   ; ax holds the sprite scale...
   mov    bx, si   ; bx gets starting point
   mov    bh, bl
   mov    bl, dh   ; get those low 8 bits...

   xor     dx, dx  ; zero out dx (dh specifically)






   ; should be able to easily do a lookup into here with available registers (ax, dx, bx)

   jump_location_dynamic:
   jmp sky_loop_done_dynamic


DRAW_SINGLE_SKY_PIXEL_DYNAMIC MACRO 
; main loop: no colormaps, add by one texel at a time... skip dx, just do lodsb
    movsb
	add    di,79      ; draw in next column 
    add    bx,ax      ; bx is 8:8 fixed point that holds current sky texel (frac), ax holds fracstep 
    mov    dl,bh      ; dh is 0, lets get the fixed point whole # in dl.
    mov    si,dx      ; and set si to the texel v


ENDM

REPT 127
    DRAW_SINGLE_SKY_PIXEL_DYNAMIC
endm


; draw last pixel, cut off the adds
    movsb


sky_loop_done_dynamic:
; clean up

; restore ds without going to memory.
    mov ax, ss
    mov ds, ax  ; restore ds
    
    pop bx
    ret



ENDP

 
 

;
; R_DrawSkyPlaneDynamic
;

; ax =
; dx
; cx:bx is pl? seems cx/bx can be destroyed freely here

PROC  R_DrawSkyPlaneDynamic_ FAR
PUBLIC  R_DrawSkyPlaneDynamic_

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

; todo investigate speedup on 286 of removing this stack var and using the ds one...
mov   al, byte ptr ds:[_detailshiftitercount]
cbw


push  ax                        ; bp-C

mov cl, byte ptr ds:[_detailshift2minus]
mov ch, 0

start_drawing_next_vga_plane_dynamic:

; prep some detailshift stuff
mov   al, ch
cbw    ; zero out ah

mov   bx, ax
add   ax, word ptr [bp - 08h]


cmp   ax, word ptr [bp - 06h]               ; if below minx then increment by detail step
jge   start_drawing_vga_plane_dynamic

add   ax, word ptr [bp - 0Ch]

start_drawing_vga_plane_dynamic:
; out the appropriate plane value

add   bl, byte ptr ds:[_detailshift+1]       ; grab pre-shifted by 2 detailshift 
mov   bl, byte ptr ds:[_quality_port_lookup + bx]


xchg   bx, ax   ; swap these values
mov   dx, 03C5h
out   dx, al


cmp   bx, word ptr [bp - 0Ah]  ; compare to maxx
jg    increment_vga_plane_dynamic

cwd   ; zero out dx, specifically dh. it will remain 0 for the whole vga plane iteration, simplifying some things

mov   ax, bx
mov   si, word ptr [bp - 02h]
add   ax, bx
add   si, bx

draw_next_column_dynamic:


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
ja    skip_column_draw_dynamic       

push si     ; we need scratch space here. push this now instead of in r_drawskycolumn


; function expects 
  ; ax = dc_yh
  ; dx = dc_yl,
  ; bx = dc_x (don't modify)

call  R_DrawSkyColumnDynamic_

pop si  ; retrieve si


; note: the above functions zeroes out DH

skip_column_draw_dynamic:
mov   dl, byte ptr [bp - 0Ch]     ; dh is 0
add   bx, dx     ; increment x/dc_x by step
add   si, dx     ; increment pl->top/bot lookup
cmp   bx, word ptr [bp - 0Ah]
jle   draw_next_column_dynamic

increment_vga_plane_dynamic:

inc   ch
mov   dl, byte ptr [bp - 0Ch]   ; might happen twice in a row... more rare than not   
cmp   ch, dl
jge   exitfunc_dynamic
jmp   start_drawing_next_vga_plane_dynamic
exitfunc_dynamic:
LEAVE_MACRO
pop   di
pop   si

retf

ENDP

;
; R_DrawSkyPlane
;

; ax =
; dx
; cx:bx is pl? seems cx/bx can be destroyed freely here

PROC  R_DrawSkyPlane_ FAR
PUBLIC  R_DrawSkyPlane_

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

; todo investigate speedup on 286 of removing this stack var and using the ds one...
mov   al, byte ptr ds:[_detailshiftitercount]
cbw


push  ax                        ; bp-C

mov cl, byte ptr ds:[_detailshift2minus]
mov ch, 0

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
mov   dx, 03C5h
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
call  R_DrawSkyColumn_

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

END


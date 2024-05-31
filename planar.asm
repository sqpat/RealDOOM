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
	.286
	.MODEL  medium
	INCLUDE defs.inc

.DATA

EXTRN	_destview:DWORD
EXTRN	_centery:WORD
EXTRN   _dc_yl_lookup:WORD


;=================================

.CODE

;
; R_DrawColumn
;
	
PROC  R_DrawColumn_
PUBLIC  R_DrawColumn_
    push  bx
    push  cx
    push  dx
    push  di
    push  bp
    mov   bp, sp

do_draw:
    cli   ; disable interrupts on enter main draw function (so we can use some registers safely)


    ; 	outp (SC_INDEX+1,1<<(dc_x&3));
    mov   cx, word ptr [_dc_x]
    mov   di, cx         ; copy to di
    mov   ax, 1
    and   cl, 3
    mov   dx, 3c5h
    shl   ax, cl
    out   dx, al

    ; dest = destview + dc_yl*80 + (dc_x>>2); 
    ;frac.w = dc_texturemid.w + (dc_yl-centery)*dc_iscale


    mov   ax, word ptr [_dc_yl]
    mov   bx, ax
    sal   bx, 1                                ; word lookup, dont forget to shift.
    mov   bx, word ptr [_dc_yl_lookup+bx]      ; quick mul80

    sar   di, 2
    mov   dx, word ptr [_destview + 0] 
    add   dx, bx
    mov   cx, word ptr [_dc_iscale + 2]

    mov   bx, word ptr [_dc_iscale + 0]   
    add   di, dx
    mov   dx, 0
    ;  NOTE using this flag for the jns later
    sub   ax, word ptr [_centery]


    mov     es,ax              ; save low(M1)

; note this is 8 bit times 32 bit and we want the mid 16

; todo figure out how to do this without a jump

    jns skipsignedmul          ; if low(m1) not signed then high(m1) was 0
; dx is 0. mul by 0xFFFF is dx - ax;
; low (M2) * high (M1) which is 0xFFFF
    sub     dx,bx
skipsignedmul:

    mul     cl;             ; only the bottom 16 bits are necessary.
    add     dx,ax           ; - add to total
    mov     cx,dx           ; - hold total in cx
    mov     ax,es           ; restore low(M1)
    mul     bx              ; low(M2) * low(M1)
    add     dx,cx           ; add previously computed high part


; multiply completed. 
; dx:ax is the 32 bits of the mul. we want dx to have the mid 16.

;    finishing  dc_texturemid.w + (dc_yl-centery)*fracstep.w


    mov   cx, word ptr [_dc_texturemid+1]   ; first add dx_texture mid
    mov   dh, dl
    mov   dl, ah                          ; mid 16 bits of the 32 bit dx:ax into dx
    add   dx, cx
    mov   cx, word ptr [_dc_iscale + 1]   ; mid 16 bits of fracstep are the mid 16 of dc_iscale


   ;  prep our loop variables


   mov     es, word ptr [_destview + 2]    ; ready the viewscreen segment
   push    ds                              ; store ds on stack
   mov     bx, word ptr [_dc_source]       ; common bx offset
   mov     ax, word ptr [_dc_source+2]     ; this will be ds..
   mov     ds, ax                          ; do this last, makes us unable to to ref other vars...
   push    bp
   mov     bp,  4Fh
   mov     ah,  7Fh

   ;; 14 bytes loop iter


   jmp loop_done         ; relative jump to be modified before function is called


pixel_loop_fast:

    mov    al,dh
	and    al,ah                  ; ah has 0x7F (127)
	add    al,bh                  ; bh has the 0 to F offset
	xlat   BYTE PTR ds:[bx]       ;
	xlat   BYTE PTR cs:[bx]       ; before calling this function we already set CS to the correct segment..
	stos   BYTE PTR es:[di]       ;
	add    di,bp                  ; bi has 79 (0x4F) and stos added one
	add    dx,cx

    mov    al,dh
	and    al,ah                  ; ah has 0x7F (127)
	add    al,bh                  ; bh has the 0 to F offset
	xlat   BYTE PTR ds:[bx]       ;
	xlat   BYTE PTR cs:[bx]       ; before calling this function we already set CS to the correct segment..
	stos   BYTE PTR es:[di]       ;
	add    di,bp                  ; bi has 79 (0x4F) and stos added one
	add    dx,cx

    mov    al,dh
	and    al,ah                  ; ah has 0x7F (127)
	add    al,bh                  ; bh has the 0 to F offset
	xlat   BYTE PTR ds:[bx]       ;
	xlat   BYTE PTR cs:[bx]       ; before calling this function we already set CS to the correct segment..
	stos   BYTE PTR es:[di]       ;
	add    di,bp                  ; bi has 79 (0x4F) and stos added one
	add    dx,cx

    mov    al,dh
	and    al,ah                  ; ah has 0x7F (127)
	add    al,bh                  ; bh has the 0 to F offset
	xlat   BYTE PTR ds:[bx]       ;
	xlat   BYTE PTR cs:[bx]       ; before calling this function we already set CS to the correct segment..
	stos   BYTE PTR es:[di]       ;
	add    di,bp                  ; bi has 79 (0x4F) and stos added one
	add    dx,cx

    mov    al,dh
	and    al,ah                  ; ah has 0x7F (127)
	add    al,bh                  ; bh has the 0 to F offset
	xlat   BYTE PTR ds:[bx]       ;
	xlat   BYTE PTR cs:[bx]       ; before calling this function we already set CS to the correct segment..
	stos   BYTE PTR es:[di]       ;
	add    di,bp                  ; bi has 79 (0x4F) and stos added one
	add    dx,cx

    mov    al,dh
	and    al,ah                  ; ah has 0x7F (127)
	add    al,bh                  ; bh has the 0 to F offset
	xlat   BYTE PTR ds:[bx]       ;
	xlat   BYTE PTR cs:[bx]       ; before calling this function we already set CS to the correct segment..
	stos   BYTE PTR es:[di]       ;
	add    di,bp                  ; bi has 79 (0x4F) and stos added one
	add    dx,cx

    mov    al,dh
	and    al,ah                  ; ah has 0x7F (127)
	add    al,bh                  ; bh has the 0 to F offset
	xlat   BYTE PTR ds:[bx]       ;
	xlat   BYTE PTR cs:[bx]       ; before calling this function we already set CS to the correct segment..
	stos   BYTE PTR es:[di]       ;
	add    di,bp                  ; bi has 79 (0x4F) and stos added one
	add    dx,cx

    mov    al,dh
	and    al,ah                  ; ah has 0x7F (127)
	add    al,bh                  ; bh has the 0 to F offset
	xlat   BYTE PTR ds:[bx]       ;
	xlat   BYTE PTR cs:[bx]       ; before calling this function we already set CS to the correct segment..
	stos   BYTE PTR es:[di]       ;
	add    di,bp                  ; bi has 79 (0x4F) and stos added one
	add    dx,cx

    mov    al,dh
	and    al,ah                  ; ah has 0x7F (127)
	add    al,bh                  ; bh has the 0 to F offset
	xlat   BYTE PTR ds:[bx]       ;
	xlat   BYTE PTR cs:[bx]       ; before calling this function we already set CS to the correct segment..
	stos   BYTE PTR es:[di]       ;
	add    di,bp                  ; bi has 79 (0x4F) and stos added one
	add    dx,cx

    mov    al,dh
	and    al,ah                  ; ah has 0x7F (127)
	add    al,bh                  ; bh has the 0 to F offset
	xlat   BYTE PTR ds:[bx]       ;
	xlat   BYTE PTR cs:[bx]       ; before calling this function we already set CS to the correct segment..
	stos   BYTE PTR es:[di]       ;
	add    di,bp                  ; bi has 79 (0x4F) and stos added one
	add    dx,cx

    mov    al,dh
	and    al,ah                  ; ah has 0x7F (127)
	add    al,bh                  ; bh has the 0 to F offset
	xlat   BYTE PTR ds:[bx]       ;
	xlat   BYTE PTR cs:[bx]       ; before calling this function we already set CS to the correct segment..
	stos   BYTE PTR es:[di]       ;
	add    di,bp                  ; bi has 79 (0x4F) and stos added one
	add    dx,cx

    mov    al,dh
	and    al,ah                  ; ah has 0x7F (127)
	add    al,bh                  ; bh has the 0 to F offset
	xlat   BYTE PTR ds:[bx]       ;
	xlat   BYTE PTR cs:[bx]       ; before calling this function we already set CS to the correct segment..
	stos   BYTE PTR es:[di]       ;
	add    di,bp                  ; bi has 79 (0x4F) and stos added one
	add    dx,cx

    mov    al,dh
	and    al,ah                  ; ah has 0x7F (127)
	add    al,bh                  ; bh has the 0 to F offset
	xlat   BYTE PTR ds:[bx]       ;
	xlat   BYTE PTR cs:[bx]       ; before calling this function we already set CS to the correct segment..
	stos   BYTE PTR es:[di]       ;
	add    di,bp                  ; bi has 79 (0x4F) and stos added one
	add    dx,cx

    mov    al,dh
	and    al,ah                  ; ah has 0x7F (127)
	add    al,bh                  ; bh has the 0 to F offset
	xlat   BYTE PTR ds:[bx]       ;
	xlat   BYTE PTR cs:[bx]       ; before calling this function we already set CS to the correct segment..
	stos   BYTE PTR es:[di]       ;
	add    di,bp                  ; bi has 79 (0x4F) and stos added one
	add    dx,cx

    mov    al,dh
	and    al,ah                  ; ah has 0x7F (127)
	add    al,bh                  ; bh has the 0 to F offset
	xlat   BYTE PTR ds:[bx]       ;
	xlat   BYTE PTR cs:[bx]       ; before calling this function we already set CS to the correct segment..
	stos   BYTE PTR es:[di]       ;
	add    di,bp                  ; bi has 79 (0x4F) and stos added one
	add    dx,cx

    mov    al,dh
	and    al,ah                  ; ah has 0x7F (127)
	add    al,bh                  ; bh has the 0 to F offset
	xlat   BYTE PTR ds:[bx]       ;
	xlat   BYTE PTR cs:[bx]       ; before calling this function we already set CS to the correct segment..
	stos   BYTE PTR es:[di]       ;
	add    di,bp                  ; bi has 79 (0x4F) and stos added one
	add    dx,cx

    mov    al,dh
	and    al,ah                  ; ah has 0x7F (127)
	add    al,bh                  ; bh has the 0 to F offset
	xlat   BYTE PTR ds:[bx]       ;
	xlat   BYTE PTR cs:[bx]       ; before calling this function we already set CS to the correct segment..
	stos   BYTE PTR es:[di]       ;
	add    di,bp                  ; bi has 79 (0x4F) and stos added one
	add    dx,cx

    mov    al,dh
	and    al,ah                  ; ah has 0x7F (127)
	add    al,bh                  ; bh has the 0 to F offset
	xlat   BYTE PTR ds:[bx]       ;
	xlat   BYTE PTR cs:[bx]       ; before calling this function we already set CS to the correct segment..
	stos   BYTE PTR es:[di]       ;
	add    di,bp                  ; bi has 79 (0x4F) and stos added one
	add    dx,cx

    mov    al,dh
	and    al,ah                  ; ah has 0x7F (127)
	add    al,bh                  ; bh has the 0 to F offset
	xlat   BYTE PTR ds:[bx]       ;
	xlat   BYTE PTR cs:[bx]       ; before calling this function we already set CS to the correct segment..
	stos   BYTE PTR es:[di]       ;
	add    di,bp                  ; bi has 79 (0x4F) and stos added one
	add    dx,cx

    mov    al,dh
	and    al,ah                  ; ah has 0x7F (127)
	add    al,bh                  ; bh has the 0 to F offset
	xlat   BYTE PTR ds:[bx]       ;
	xlat   BYTE PTR cs:[bx]       ; before calling this function we already set CS to the correct segment..
	stos   BYTE PTR es:[di]       ;
	add    di,bp                  ; bi has 79 (0x4F) and stos added one
	add    dx,cx

    mov    al,dh
	and    al,ah                  ; ah has 0x7F (127)
	add    al,bh                  ; bh has the 0 to F offset
	xlat   BYTE PTR ds:[bx]       ;
	xlat   BYTE PTR cs:[bx]       ; before calling this function we already set CS to the correct segment..
	stos   BYTE PTR es:[di]       ;
	add    di,bp                  ; bi has 79 (0x4F) and stos added one
	add    dx,cx

    mov    al,dh
	and    al,ah                  ; ah has 0x7F (127)
	add    al,bh                  ; bh has the 0 to F offset
	xlat   BYTE PTR ds:[bx]       ;
	xlat   BYTE PTR cs:[bx]       ; before calling this function we already set CS to the correct segment..
	stos   BYTE PTR es:[di]       ;
	add    di,bp                  ; bi has 79 (0x4F) and stos added one
	add    dx,cx

    mov    al,dh
	and    al,ah                  ; ah has 0x7F (127)
	add    al,bh                  ; bh has the 0 to F offset
	xlat   BYTE PTR ds:[bx]       ;
	xlat   BYTE PTR cs:[bx]       ; before calling this function we already set CS to the correct segment..
	stos   BYTE PTR es:[di]       ;
	add    di,bp                  ; bi has 79 (0x4F) and stos added one
	add    dx,cx

    mov    al,dh
	and    al,ah                  ; ah has 0x7F (127)
	add    al,bh                  ; bh has the 0 to F offset
	xlat   BYTE PTR ds:[bx]       ;
	xlat   BYTE PTR cs:[bx]       ; before calling this function we already set CS to the correct segment..
	stos   BYTE PTR es:[di]       ;
	add    di,bp                  ; bi has 79 (0x4F) and stos added one
	add    dx,cx

    mov    al,dh
	and    al,ah                  ; ah has 0x7F (127)
	add    al,bh                  ; bh has the 0 to F offset
	xlat   BYTE PTR ds:[bx]       ;
	xlat   BYTE PTR cs:[bx]       ; before calling this function we already set CS to the correct segment..
	stos   BYTE PTR es:[di]       ;
	add    di,bp                  ; bi has 79 (0x4F) and stos added one
	add    dx,cx

    mov    al,dh
	and    al,ah                  ; ah has 0x7F (127)
	add    al,bh                  ; bh has the 0 to F offset
	xlat   BYTE PTR ds:[bx]       ;
	xlat   BYTE PTR cs:[bx]       ; before calling this function we already set CS to the correct segment..
	stos   BYTE PTR es:[di]       ;
	add    di,bp                  ; bi has 79 (0x4F) and stos added one
	add    dx,cx

    mov    al,dh
	and    al,ah                  ; ah has 0x7F (127)
	add    al,bh                  ; bh has the 0 to F offset
	xlat   BYTE PTR ds:[bx]       ;
	xlat   BYTE PTR cs:[bx]       ; before calling this function we already set CS to the correct segment..
	stos   BYTE PTR es:[di]       ;
	add    di,bp                  ; bi has 79 (0x4F) and stos added one
	add    dx,cx

    mov    al,dh
	and    al,ah                  ; ah has 0x7F (127)
	add    al,bh                  ; bh has the 0 to F offset
	xlat   BYTE PTR ds:[bx]       ;
	xlat   BYTE PTR cs:[bx]       ; before calling this function we already set CS to the correct segment..
	stos   BYTE PTR es:[di]       ;
	add    di,bp                  ; bi has 79 (0x4F) and stos added one
	add    dx,cx

    mov    al,dh
	and    al,ah                  ; ah has 0x7F (127)
	add    al,bh                  ; bh has the 0 to F offset
	xlat   BYTE PTR ds:[bx]       ;
	xlat   BYTE PTR cs:[bx]       ; before calling this function we already set CS to the correct segment..
	stos   BYTE PTR es:[di]       ;
	add    di,bp                  ; bi has 79 (0x4F) and stos added one
	add    dx,cx

    mov    al,dh
	and    al,ah                  ; ah has 0x7F (127)
	add    al,bh                  ; bh has the 0 to F offset
	xlat   BYTE PTR ds:[bx]       ;
	xlat   BYTE PTR cs:[bx]       ; before calling this function we already set CS to the correct segment..
	stos   BYTE PTR es:[di]       ;
	add    di,bp                  ; bi has 79 (0x4F) and stos added one
	add    dx,cx

    mov    al,dh
	and    al,ah                  ; ah has 0x7F (127)
	add    al,bh                  ; bh has the 0 to F offset
	xlat   BYTE PTR ds:[bx]       ;
	xlat   BYTE PTR cs:[bx]       ; before calling this function we already set CS to the correct segment..
	stos   BYTE PTR es:[di]       ;
	add    di,bp                  ; bi has 79 (0x4F) and stos added one
	add    dx,cx

    mov    al,dh
	and    al,ah                  ; ah has 0x7F (127)
	add    al,bh                  ; bh has the 0 to F offset
	xlat   BYTE PTR ds:[bx]       ;
	xlat   BYTE PTR cs:[bx]       ; before calling this function we already set CS to the correct segment..
	stos   BYTE PTR es:[di]       ;
	add    di,bp                  ; bi has 79 (0x4F) and stos added one
	add    dx,cx

    mov    al,dh
	and    al,ah                  ; ah has 0x7F (127)
	add    al,bh                  ; bh has the 0 to F offset
	xlat   BYTE PTR ds:[bx]       ;
	xlat   BYTE PTR cs:[bx]       ; before calling this function we already set CS to the correct segment..
	stos   BYTE PTR es:[di]       ;
	add    di,bp                  ; bi has 79 (0x4F) and stos added one
	add    dx,cx

    mov    al,dh
	and    al,ah                  ; ah has 0x7F (127)
	add    al,bh                  ; bh has the 0 to F offset
	xlat   BYTE PTR ds:[bx]       ;
	xlat   BYTE PTR cs:[bx]       ; before calling this function we already set CS to the correct segment..
	stos   BYTE PTR es:[di]       ;
	add    di,bp                  ; bi has 79 (0x4F) and stos added one
	add    dx,cx

    mov    al,dh
	and    al,ah                  ; ah has 0x7F (127)
	add    al,bh                  ; bh has the 0 to F offset
	xlat   BYTE PTR ds:[bx]       ;
	xlat   BYTE PTR cs:[bx]       ; before calling this function we already set CS to the correct segment..
	stos   BYTE PTR es:[di]       ;
	add    di,bp                  ; bi has 79 (0x4F) and stos added one
	add    dx,cx

    mov    al,dh
	and    al,ah                  ; ah has 0x7F (127)
	add    al,bh                  ; bh has the 0 to F offset
	xlat   BYTE PTR ds:[bx]       ;
	xlat   BYTE PTR cs:[bx]       ; before calling this function we already set CS to the correct segment..
	stos   BYTE PTR es:[di]       ;
	add    di,bp                  ; bi has 79 (0x4F) and stos added one
	add    dx,cx

    mov    al,dh
	and    al,ah                  ; ah has 0x7F (127)
	add    al,bh                  ; bh has the 0 to F offset
	xlat   BYTE PTR ds:[bx]       ;
	xlat   BYTE PTR cs:[bx]       ; before calling this function we already set CS to the correct segment..
	stos   BYTE PTR es:[di]       ;
	add    di,bp                  ; bi has 79 (0x4F) and stos added one
	add    dx,cx

    mov    al,dh
	and    al,ah                  ; ah has 0x7F (127)
	add    al,bh                  ; bh has the 0 to F offset
	xlat   BYTE PTR ds:[bx]       ;
	xlat   BYTE PTR cs:[bx]       ; before calling this function we already set CS to the correct segment..
	stos   BYTE PTR es:[di]       ;
	add    di,bp                  ; bi has 79 (0x4F) and stos added one
	add    dx,cx

    mov    al,dh
	and    al,ah                  ; ah has 0x7F (127)
	add    al,bh                  ; bh has the 0 to F offset
	xlat   BYTE PTR ds:[bx]       ;
	xlat   BYTE PTR cs:[bx]       ; before calling this function we already set CS to the correct segment..
	stos   BYTE PTR es:[di]       ;
	add    di,bp                  ; bi has 79 (0x4F) and stos added one
	add    dx,cx

    mov    al,dh
	and    al,ah                  ; ah has 0x7F (127)
	add    al,bh                  ; bh has the 0 to F offset
	xlat   BYTE PTR ds:[bx]       ;
	xlat   BYTE PTR cs:[bx]       ; before calling this function we already set CS to the correct segment..
	stos   BYTE PTR es:[di]       ;
	add    di,bp                  ; bi has 79 (0x4F) and stos added one
	add    dx,cx

    mov    al,dh
	and    al,ah                  ; ah has 0x7F (127)
	add    al,bh                  ; bh has the 0 to F offset
	xlat   BYTE PTR ds:[bx]       ;
	xlat   BYTE PTR cs:[bx]       ; before calling this function we already set CS to the correct segment..
	stos   BYTE PTR es:[di]       ;
	add    di,bp                  ; bi has 79 (0x4F) and stos added one
	add    dx,cx

    mov    al,dh
	and    al,ah                  ; ah has 0x7F (127)
	add    al,bh                  ; bh has the 0 to F offset
	xlat   BYTE PTR ds:[bx]       ;
	xlat   BYTE PTR cs:[bx]       ; before calling this function we already set CS to the correct segment..
	stos   BYTE PTR es:[di]       ;
	add    di,bp                  ; bi has 79 (0x4F) and stos added one
	add    dx,cx

    mov    al,dh
	and    al,ah                  ; ah has 0x7F (127)
	add    al,bh                  ; bh has the 0 to F offset
	xlat   BYTE PTR ds:[bx]       ;
	xlat   BYTE PTR cs:[bx]       ; before calling this function we already set CS to the correct segment..
	stos   BYTE PTR es:[di]       ;
	add    di,bp                  ; bi has 79 (0x4F) and stos added one
	add    dx,cx

    mov    al,dh
	and    al,ah                  ; ah has 0x7F (127)
	add    al,bh                  ; bh has the 0 to F offset
	xlat   BYTE PTR ds:[bx]       ;
	xlat   BYTE PTR cs:[bx]       ; before calling this function we already set CS to the correct segment..
	stos   BYTE PTR es:[di]       ;
	add    di,bp                  ; bi has 79 (0x4F) and stos added one
	add    dx,cx

    mov    al,dh
	and    al,ah                  ; ah has 0x7F (127)
	add    al,bh                  ; bh has the 0 to F offset
	xlat   BYTE PTR ds:[bx]       ;
	xlat   BYTE PTR cs:[bx]       ; before calling this function we already set CS to the correct segment..
	stos   BYTE PTR es:[di]       ;
	add    di,bp                  ; bi has 79 (0x4F) and stos added one
	add    dx,cx

    mov    al,dh
	and    al,ah                  ; ah has 0x7F (127)
	add    al,bh                  ; bh has the 0 to F offset
	xlat   BYTE PTR ds:[bx]       ;
	xlat   BYTE PTR cs:[bx]       ; before calling this function we already set CS to the correct segment..
	stos   BYTE PTR es:[di]       ;
	add    di,bp                  ; bi has 79 (0x4F) and stos added one
	add    dx,cx

    mov    al,dh
	and    al,ah                  ; ah has 0x7F (127)
	add    al,bh                  ; bh has the 0 to F offset
	xlat   BYTE PTR ds:[bx]       ;
	xlat   BYTE PTR cs:[bx]       ; before calling this function we already set CS to the correct segment..
	stos   BYTE PTR es:[di]       ;
	add    di,bp                  ; bi has 79 (0x4F) and stos added one
	add    dx,cx

    mov    al,dh
	and    al,ah                  ; ah has 0x7F (127)
	add    al,bh                  ; bh has the 0 to F offset
	xlat   BYTE PTR ds:[bx]       ;
	xlat   BYTE PTR cs:[bx]       ; before calling this function we already set CS to the correct segment..
	stos   BYTE PTR es:[di]       ;
	add    di,bp                  ; bi has 79 (0x4F) and stos added one
	add    dx,cx

    mov    al,dh
	and    al,ah                  ; ah has 0x7F (127)
	add    al,bh                  ; bh has the 0 to F offset
	xlat   BYTE PTR ds:[bx]       ;
	xlat   BYTE PTR cs:[bx]       ; before calling this function we already set CS to the correct segment..
	stos   BYTE PTR es:[di]       ;
	add    di,bp                  ; bi has 79 (0x4F) and stos added one
	add    dx,cx

    mov    al,dh
	and    al,ah                  ; ah has 0x7F (127)
	add    al,bh                  ; bh has the 0 to F offset
	xlat   BYTE PTR ds:[bx]       ;
	xlat   BYTE PTR cs:[bx]       ; before calling this function we already set CS to the correct segment..
	stos   BYTE PTR es:[di]       ;
	add    di,bp                  ; bi has 79 (0x4F) and stos added one
	add    dx,cx

    mov    al,dh
	and    al,ah                  ; ah has 0x7F (127)
	add    al,bh                  ; bh has the 0 to F offset
	xlat   BYTE PTR ds:[bx]       ;
	xlat   BYTE PTR cs:[bx]       ; before calling this function we already set CS to the correct segment..
	stos   BYTE PTR es:[di]       ;
	add    di,bp                  ; bi has 79 (0x4F) and stos added one
	add    dx,cx

    mov    al,dh
	and    al,ah                  ; ah has 0x7F (127)
	add    al,bh                  ; bh has the 0 to F offset
	xlat   BYTE PTR ds:[bx]       ;
	xlat   BYTE PTR cs:[bx]       ; before calling this function we already set CS to the correct segment..
	stos   BYTE PTR es:[di]       ;
	add    di,bp                  ; bi has 79 (0x4F) and stos added one
	add    dx,cx

    mov    al,dh
	and    al,ah                  ; ah has 0x7F (127)
	add    al,bh                  ; bh has the 0 to F offset
	xlat   BYTE PTR ds:[bx]       ;
	xlat   BYTE PTR cs:[bx]       ; before calling this function we already set CS to the correct segment..
	stos   BYTE PTR es:[di]       ;
	add    di,bp                  ; bi has 79 (0x4F) and stos added one
	add    dx,cx

    mov    al,dh
	and    al,ah                  ; ah has 0x7F (127)
	add    al,bh                  ; bh has the 0 to F offset
	xlat   BYTE PTR ds:[bx]       ;
	xlat   BYTE PTR cs:[bx]       ; before calling this function we already set CS to the correct segment..
	stos   BYTE PTR es:[di]       ;
	add    di,bp                  ; bi has 79 (0x4F) and stos added one
	add    dx,cx

    mov    al,dh
	and    al,ah                  ; ah has 0x7F (127)
	add    al,bh                  ; bh has the 0 to F offset
	xlat   BYTE PTR ds:[bx]       ;
	xlat   BYTE PTR cs:[bx]       ; before calling this function we already set CS to the correct segment..
	stos   BYTE PTR es:[di]       ;
	add    di,bp                  ; bi has 79 (0x4F) and stos added one
	add    dx,cx

    mov    al,dh
	and    al,ah                  ; ah has 0x7F (127)
	add    al,bh                  ; bh has the 0 to F offset
	xlat   BYTE PTR ds:[bx]       ;
	xlat   BYTE PTR cs:[bx]       ; before calling this function we already set CS to the correct segment..
	stos   BYTE PTR es:[di]       ;
	add    di,bp                  ; bi has 79 (0x4F) and stos added one
	add    dx,cx

    mov    al,dh
	and    al,ah                  ; ah has 0x7F (127)
	add    al,bh                  ; bh has the 0 to F offset
	xlat   BYTE PTR ds:[bx]       ;
	xlat   BYTE PTR cs:[bx]       ; before calling this function we already set CS to the correct segment..
	stos   BYTE PTR es:[di]       ;
	add    di,bp                  ; bi has 79 (0x4F) and stos added one
	add    dx,cx

    mov    al,dh
	and    al,ah                  ; ah has 0x7F (127)
	add    al,bh                  ; bh has the 0 to F offset
	xlat   BYTE PTR ds:[bx]       ;
	xlat   BYTE PTR cs:[bx]       ; before calling this function we already set CS to the correct segment..
	stos   BYTE PTR es:[di]       ;
	add    di,bp                  ; bi has 79 (0x4F) and stos added one
	add    dx,cx

    mov    al,dh
	and    al,ah                  ; ah has 0x7F (127)
	add    al,bh                  ; bh has the 0 to F offset
	xlat   BYTE PTR ds:[bx]       ;
	xlat   BYTE PTR cs:[bx]       ; before calling this function we already set CS to the correct segment..
	stos   BYTE PTR es:[di]       ;
	add    di,bp                  ; bi has 79 (0x4F) and stos added one
	add    dx,cx

    mov    al,dh
	and    al,ah                  ; ah has 0x7F (127)
	add    al,bh                  ; bh has the 0 to F offset
	xlat   BYTE PTR ds:[bx]       ;
	xlat   BYTE PTR cs:[bx]       ; before calling this function we already set CS to the correct segment..
	stos   BYTE PTR es:[di]       ;
	add    di,bp                  ; bi has 79 (0x4F) and stos added one
	add    dx,cx

    mov    al,dh
	and    al,ah                  ; ah has 0x7F (127)
	add    al,bh                  ; bh has the 0 to F offset
	xlat   BYTE PTR ds:[bx]       ;
	xlat   BYTE PTR cs:[bx]       ; before calling this function we already set CS to the correct segment..
	stos   BYTE PTR es:[di]       ;
	add    di,bp                  ; bi has 79 (0x4F) and stos added one
	add    dx,cx

    mov    al,dh
	and    al,ah                  ; ah has 0x7F (127)
	add    al,bh                  ; bh has the 0 to F offset
	xlat   BYTE PTR ds:[bx]       ;
	xlat   BYTE PTR cs:[bx]       ; before calling this function we already set CS to the correct segment..
	stos   BYTE PTR es:[di]       ;
	add    di,bp                  ; bi has 79 (0x4F) and stos added one
	add    dx,cx

    mov    al,dh
	and    al,ah                  ; ah has 0x7F (127)
	add    al,bh                  ; bh has the 0 to F offset
	xlat   BYTE PTR ds:[bx]       ;
	xlat   BYTE PTR cs:[bx]       ; before calling this function we already set CS to the correct segment..
	stos   BYTE PTR es:[di]       ;
	add    di,bp                  ; bi has 79 (0x4F) and stos added one
	add    dx,cx

    mov    al,dh
	and    al,ah                  ; ah has 0x7F (127)
	add    al,bh                  ; bh has the 0 to F offset
	xlat   BYTE PTR ds:[bx]       ;
	xlat   BYTE PTR cs:[bx]       ; before calling this function we already set CS to the correct segment..
	stos   BYTE PTR es:[di]       ;
	add    di,bp                  ; bi has 79 (0x4F) and stos added one
	add    dx,cx

    mov    al,dh
	and    al,ah                  ; ah has 0x7F (127)
	add    al,bh                  ; bh has the 0 to F offset
	xlat   BYTE PTR ds:[bx]       ;
	xlat   BYTE PTR cs:[bx]       ; before calling this function we already set CS to the correct segment..
	stos   BYTE PTR es:[di]       ;
	add    di,bp                  ; bi has 79 (0x4F) and stos added one
	add    dx,cx

    mov    al,dh
	and    al,ah                  ; ah has 0x7F (127)
	add    al,bh                  ; bh has the 0 to F offset
	xlat   BYTE PTR ds:[bx]       ;
	xlat   BYTE PTR cs:[bx]       ; before calling this function we already set CS to the correct segment..
	stos   BYTE PTR es:[di]       ;
	add    di,bp                  ; bi has 79 (0x4F) and stos added one
	add    dx,cx

    mov    al,dh
	and    al,ah                  ; ah has 0x7F (127)
	add    al,bh                  ; bh has the 0 to F offset
	xlat   BYTE PTR ds:[bx]       ;
	xlat   BYTE PTR cs:[bx]       ; before calling this function we already set CS to the correct segment..
	stos   BYTE PTR es:[di]       ;
	add    di,bp                  ; bi has 79 (0x4F) and stos added one
	add    dx,cx

    mov    al,dh
	and    al,ah                  ; ah has 0x7F (127)
	add    al,bh                  ; bh has the 0 to F offset
	xlat   BYTE PTR ds:[bx]       ;
	xlat   BYTE PTR cs:[bx]       ; before calling this function we already set CS to the correct segment..
	stos   BYTE PTR es:[di]       ;
	add    di,bp                  ; bi has 79 (0x4F) and stos added one
	add    dx,cx

    mov    al,dh
	and    al,ah                  ; ah has 0x7F (127)
	add    al,bh                  ; bh has the 0 to F offset
	xlat   BYTE PTR ds:[bx]       ;
	xlat   BYTE PTR cs:[bx]       ; before calling this function we already set CS to the correct segment..
	stos   BYTE PTR es:[di]       ;
	add    di,bp                  ; bi has 79 (0x4F) and stos added one
	add    dx,cx

    mov    al,dh
	and    al,ah                  ; ah has 0x7F (127)
	add    al,bh                  ; bh has the 0 to F offset
	xlat   BYTE PTR ds:[bx]       ;
	xlat   BYTE PTR cs:[bx]       ; before calling this function we already set CS to the correct segment..
	stos   BYTE PTR es:[di]       ;
	add    di,bp                  ; bi has 79 (0x4F) and stos added one
	add    dx,cx

    mov    al,dh
	and    al,ah                  ; ah has 0x7F (127)
	add    al,bh                  ; bh has the 0 to F offset
	xlat   BYTE PTR ds:[bx]       ;
	xlat   BYTE PTR cs:[bx]       ; before calling this function we already set CS to the correct segment..
	stos   BYTE PTR es:[di]       ;
	add    di,bp                  ; bi has 79 (0x4F) and stos added one
	add    dx,cx

    mov    al,dh
	and    al,ah                  ; ah has 0x7F (127)
	add    al,bh                  ; bh has the 0 to F offset
	xlat   BYTE PTR ds:[bx]       ;
	xlat   BYTE PTR cs:[bx]       ; before calling this function we already set CS to the correct segment..
	stos   BYTE PTR es:[di]       ;
	add    di,bp                  ; bi has 79 (0x4F) and stos added one
	add    dx,cx

    mov    al,dh
	and    al,ah                  ; ah has 0x7F (127)
	add    al,bh                  ; bh has the 0 to F offset
	xlat   BYTE PTR ds:[bx]       ;
	xlat   BYTE PTR cs:[bx]       ; before calling this function we already set CS to the correct segment..
	stos   BYTE PTR es:[di]       ;
	add    di,bp                  ; bi has 79 (0x4F) and stos added one
	add    dx,cx

    mov    al,dh
	and    al,ah                  ; ah has 0x7F (127)
	add    al,bh                  ; bh has the 0 to F offset
	xlat   BYTE PTR ds:[bx]       ;
	xlat   BYTE PTR cs:[bx]       ; before calling this function we already set CS to the correct segment..
	stos   BYTE PTR es:[di]       ;
	add    di,bp                  ; bi has 79 (0x4F) and stos added one
	add    dx,cx

    mov    al,dh
	and    al,ah                  ; ah has 0x7F (127)
	add    al,bh                  ; bh has the 0 to F offset
	xlat   BYTE PTR ds:[bx]       ;
	xlat   BYTE PTR cs:[bx]       ; before calling this function we already set CS to the correct segment..
	stos   BYTE PTR es:[di]       ;
	add    di,bp                  ; bi has 79 (0x4F) and stos added one
	add    dx,cx

    mov    al,dh
	and    al,ah                  ; ah has 0x7F (127)
	add    al,bh                  ; bh has the 0 to F offset
	xlat   BYTE PTR ds:[bx]       ;
	xlat   BYTE PTR cs:[bx]       ; before calling this function we already set CS to the correct segment..
	stos   BYTE PTR es:[di]       ;
	add    di,bp                  ; bi has 79 (0x4F) and stos added one
	add    dx,cx

    mov    al,dh
	and    al,ah                  ; ah has 0x7F (127)
	add    al,bh                  ; bh has the 0 to F offset
	xlat   BYTE PTR ds:[bx]       ;
	xlat   BYTE PTR cs:[bx]       ; before calling this function we already set CS to the correct segment..
	stos   BYTE PTR es:[di]       ;
	add    di,bp                  ; bi has 79 (0x4F) and stos added one
	add    dx,cx

    mov    al,dh
	and    al,ah                  ; ah has 0x7F (127)
	add    al,bh                  ; bh has the 0 to F offset
	xlat   BYTE PTR ds:[bx]       ;
	xlat   BYTE PTR cs:[bx]       ; before calling this function we already set CS to the correct segment..
	stos   BYTE PTR es:[di]       ;
	add    di,bp                  ; bi has 79 (0x4F) and stos added one
	add    dx,cx

    mov    al,dh
	and    al,ah                  ; ah has 0x7F (127)
	add    al,bh                  ; bh has the 0 to F offset
	xlat   BYTE PTR ds:[bx]       ;
	xlat   BYTE PTR cs:[bx]       ; before calling this function we already set CS to the correct segment..
	stos   BYTE PTR es:[di]       ;
	add    di,bp                  ; bi has 79 (0x4F) and stos added one
	add    dx,cx

    mov    al,dh
	and    al,ah                  ; ah has 0x7F (127)
	add    al,bh                  ; bh has the 0 to F offset
	xlat   BYTE PTR ds:[bx]       ;
	xlat   BYTE PTR cs:[bx]       ; before calling this function we already set CS to the correct segment..
	stos   BYTE PTR es:[di]       ;
	add    di,bp                  ; bi has 79 (0x4F) and stos added one
	add    dx,cx

    mov    al,dh
	and    al,ah                  ; ah has 0x7F (127)
	add    al,bh                  ; bh has the 0 to F offset
	xlat   BYTE PTR ds:[bx]       ;
	xlat   BYTE PTR cs:[bx]       ; before calling this function we already set CS to the correct segment..
	stos   BYTE PTR es:[di]       ;
	add    di,bp                  ; bi has 79 (0x4F) and stos added one
	add    dx,cx

    mov    al,dh
	and    al,ah                  ; ah has 0x7F (127)
	add    al,bh                  ; bh has the 0 to F offset
	xlat   BYTE PTR ds:[bx]       ;
	xlat   BYTE PTR cs:[bx]       ; before calling this function we already set CS to the correct segment..
	stos   BYTE PTR es:[di]       ;
	add    di,bp                  ; bi has 79 (0x4F) and stos added one
	add    dx,cx

    mov    al,dh
	and    al,ah                  ; ah has 0x7F (127)
	add    al,bh                  ; bh has the 0 to F offset
	xlat   BYTE PTR ds:[bx]       ;
	xlat   BYTE PTR cs:[bx]       ; before calling this function we already set CS to the correct segment..
	stos   BYTE PTR es:[di]       ;
	add    di,bp                  ; bi has 79 (0x4F) and stos added one
	add    dx,cx

    mov    al,dh
	and    al,ah                  ; ah has 0x7F (127)
	add    al,bh                  ; bh has the 0 to F offset
	xlat   BYTE PTR ds:[bx]       ;
	xlat   BYTE PTR cs:[bx]       ; before calling this function we already set CS to the correct segment..
	stos   BYTE PTR es:[di]       ;
	add    di,bp                  ; bi has 79 (0x4F) and stos added one
	add    dx,cx

    mov    al,dh
	and    al,ah                  ; ah has 0x7F (127)
	add    al,bh                  ; bh has the 0 to F offset
	xlat   BYTE PTR ds:[bx]       ;
	xlat   BYTE PTR cs:[bx]       ; before calling this function we already set CS to the correct segment..
	stos   BYTE PTR es:[di]       ;
	add    di,bp                  ; bi has 79 (0x4F) and stos added one
	add    dx,cx

    mov    al,dh
	and    al,ah                  ; ah has 0x7F (127)
	add    al,bh                  ; bh has the 0 to F offset
	xlat   BYTE PTR ds:[bx]       ;
	xlat   BYTE PTR cs:[bx]       ; before calling this function we already set CS to the correct segment..
	stos   BYTE PTR es:[di]       ;
	add    di,bp                  ; bi has 79 (0x4F) and stos added one
	add    dx,cx

    mov    al,dh
	and    al,ah                  ; ah has 0x7F (127)
	add    al,bh                  ; bh has the 0 to F offset
	xlat   BYTE PTR ds:[bx]       ;
	xlat   BYTE PTR cs:[bx]       ; before calling this function we already set CS to the correct segment..
	stos   BYTE PTR es:[di]       ;
	add    di,bp                  ; bi has 79 (0x4F) and stos added one
	add    dx,cx

    mov    al,dh
	and    al,ah                  ; ah has 0x7F (127)
	add    al,bh                  ; bh has the 0 to F offset
	xlat   BYTE PTR ds:[bx]       ;
	xlat   BYTE PTR cs:[bx]       ; before calling this function we already set CS to the correct segment..
	stos   BYTE PTR es:[di]       ;
	add    di,bp                  ; bi has 79 (0x4F) and stos added one
	add    dx,cx

    mov    al,dh
	and    al,ah                  ; ah has 0x7F (127)
	add    al,bh                  ; bh has the 0 to F offset
	xlat   BYTE PTR ds:[bx]       ;
	xlat   BYTE PTR cs:[bx]       ; before calling this function we already set CS to the correct segment..
	stos   BYTE PTR es:[di]       ;
	add    di,bp                  ; bi has 79 (0x4F) and stos added one
	add    dx,cx

    mov    al,dh
	and    al,ah                  ; ah has 0x7F (127)
	add    al,bh                  ; bh has the 0 to F offset
	xlat   BYTE PTR ds:[bx]       ;
	xlat   BYTE PTR cs:[bx]       ; before calling this function we already set CS to the correct segment..
	stos   BYTE PTR es:[di]       ;
	add    di,bp                  ; bi has 79 (0x4F) and stos added one
	add    dx,cx

    mov    al,dh
	and    al,ah                  ; ah has 0x7F (127)
	add    al,bh                  ; bh has the 0 to F offset
	xlat   BYTE PTR ds:[bx]       ;
	xlat   BYTE PTR cs:[bx]       ; before calling this function we already set CS to the correct segment..
	stos   BYTE PTR es:[di]       ;
	add    di,bp                  ; bi has 79 (0x4F) and stos added one
	add    dx,cx

    mov    al,dh
	and    al,ah                  ; ah has 0x7F (127)
	add    al,bh                  ; bh has the 0 to F offset
	xlat   BYTE PTR ds:[bx]       ;
	xlat   BYTE PTR cs:[bx]       ; before calling this function we already set CS to the correct segment..
	stos   BYTE PTR es:[di]       ;
	add    di,bp                  ; bi has 79 (0x4F) and stos added one
	add    dx,cx

    mov    al,dh
	and    al,ah                  ; ah has 0x7F (127)
	add    al,bh                  ; bh has the 0 to F offset
	xlat   BYTE PTR ds:[bx]       ;
	xlat   BYTE PTR cs:[bx]       ; before calling this function we already set CS to the correct segment..
	stos   BYTE PTR es:[di]       ;
	add    di,bp                  ; bi has 79 (0x4F) and stos added one
	add    dx,cx

    mov    al,dh
	and    al,ah                  ; ah has 0x7F (127)
	add    al,bh                  ; bh has the 0 to F offset
	xlat   BYTE PTR ds:[bx]       ;
	xlat   BYTE PTR cs:[bx]       ; before calling this function we already set CS to the correct segment..
	stos   BYTE PTR es:[di]       ;
	add    di,bp                  ; bi has 79 (0x4F) and stos added one
	add    dx,cx

    mov    al,dh
	and    al,ah                  ; ah has 0x7F (127)
	add    al,bh                  ; bh has the 0 to F offset
	xlat   BYTE PTR ds:[bx]       ;
	xlat   BYTE PTR cs:[bx]       ; before calling this function we already set CS to the correct segment..
	stos   BYTE PTR es:[di]       ;
	add    di,bp                  ; bi has 79 (0x4F) and stos added one
	add    dx,cx

    mov    al,dh
	and    al,ah                  ; ah has 0x7F (127)
	add    al,bh                  ; bh has the 0 to F offset
	xlat   BYTE PTR ds:[bx]       ;
	xlat   BYTE PTR cs:[bx]       ; before calling this function we already set CS to the correct segment..
	stos   BYTE PTR es:[di]       ;
	add    di,bp                  ; bi has 79 (0x4F) and stos added one
	add    dx,cx

    mov    al,dh
	and    al,ah                  ; ah has 0x7F (127)
	add    al,bh                  ; bh has the 0 to F offset
	xlat   BYTE PTR ds:[bx]       ;
	xlat   BYTE PTR cs:[bx]       ; before calling this function we already set CS to the correct segment..
	stos   BYTE PTR es:[di]       ;
	add    di,bp                  ; bi has 79 (0x4F) and stos added one
	add    dx,cx

    mov    al,dh
	and    al,ah                  ; ah has 0x7F (127)
	add    al,bh                  ; bh has the 0 to F offset
	xlat   BYTE PTR ds:[bx]       ;
	xlat   BYTE PTR cs:[bx]       ; before calling this function we already set CS to the correct segment..
	stos   BYTE PTR es:[di]       ;
	add    di,bp                  ; bi has 79 (0x4F) and stos added one
	add    dx,cx

    mov    al,dh
	and    al,ah                  ; ah has 0x7F (127)
	add    al,bh                  ; bh has the 0 to F offset
	xlat   BYTE PTR ds:[bx]       ;
	xlat   BYTE PTR cs:[bx]       ; before calling this function we already set CS to the correct segment..
	stos   BYTE PTR es:[di]       ;
	add    di,bp                  ; bi has 79 (0x4F) and stos added one
	add    dx,cx

    mov    al,dh
	and    al,ah                  ; ah has 0x7F (127)
	add    al,bh                  ; bh has the 0 to F offset
	xlat   BYTE PTR ds:[bx]       ;
	xlat   BYTE PTR cs:[bx]       ; before calling this function we already set CS to the correct segment..
	stos   BYTE PTR es:[di]       ;
	add    di,bp                  ; bi has 79 (0x4F) and stos added one
	add    dx,cx

    mov    al,dh
	and    al,ah                  ; ah has 0x7F (127)
	add    al,bh                  ; bh has the 0 to F offset
	xlat   BYTE PTR ds:[bx]       ;
	xlat   BYTE PTR cs:[bx]       ; before calling this function we already set CS to the correct segment..
	stos   BYTE PTR es:[di]       ;
	add    di,bp                  ; bi has 79 (0x4F) and stos added one
	add    dx,cx

    mov    al,dh
	and    al,ah                  ; ah has 0x7F (127)
	add    al,bh                  ; bh has the 0 to F offset
	xlat   BYTE PTR ds:[bx]       ;
	xlat   BYTE PTR cs:[bx]       ; before calling this function we already set CS to the correct segment..
	stos   BYTE PTR es:[di]       ;
	add    di,bp                  ; bi has 79 (0x4F) and stos added one
	add    dx,cx

    mov    al,dh
	and    al,ah                  ; ah has 0x7F (127)
	add    al,bh                  ; bh has the 0 to F offset
	xlat   BYTE PTR ds:[bx]       ;
	xlat   BYTE PTR cs:[bx]       ; before calling this function we already set CS to the correct segment..
	stos   BYTE PTR es:[di]       ;
	add    di,bp                  ; bi has 79 (0x4F) and stos added one
	add    dx,cx

    mov    al,dh
	and    al,ah                  ; ah has 0x7F (127)
	add    al,bh                  ; bh has the 0 to F offset
	xlat   BYTE PTR ds:[bx]       ;
	xlat   BYTE PTR cs:[bx]       ; before calling this function we already set CS to the correct segment..
	stos   BYTE PTR es:[di]       ;
	add    di,bp                  ; bi has 79 (0x4F) and stos added one
	add    dx,cx

    mov    al,dh
	and    al,ah                  ; ah has 0x7F (127)
	add    al,bh                  ; bh has the 0 to F offset
	xlat   BYTE PTR ds:[bx]       ;
	xlat   BYTE PTR cs:[bx]       ; before calling this function we already set CS to the correct segment..
	stos   BYTE PTR es:[di]       ;
	add    di,bp                  ; bi has 79 (0x4F) and stos added one
	add    dx,cx

    mov    al,dh
	and    al,ah                  ; ah has 0x7F (127)
	add    al,bh                  ; bh has the 0 to F offset
	xlat   BYTE PTR ds:[bx]       ;
	xlat   BYTE PTR cs:[bx]       ; before calling this function we already set CS to the correct segment..
	stos   BYTE PTR es:[di]       ;
	add    di,bp                  ; bi has 79 (0x4F) and stos added one
	add    dx,cx

    mov    al,dh
	and    al,ah                  ; ah has 0x7F (127)
	add    al,bh                  ; bh has the 0 to F offset
	xlat   BYTE PTR ds:[bx]       ;
	xlat   BYTE PTR cs:[bx]       ; before calling this function we already set CS to the correct segment..
	stos   BYTE PTR es:[di]       ;
	add    di,bp                  ; bi has 79 (0x4F) and stos added one
	add    dx,cx

    mov    al,dh
	and    al,ah                  ; ah has 0x7F (127)
	add    al,bh                  ; bh has the 0 to F offset
	xlat   BYTE PTR ds:[bx]       ;
	xlat   BYTE PTR cs:[bx]       ; before calling this function we already set CS to the correct segment..
	stos   BYTE PTR es:[di]       ;
	add    di,bp                  ; bi has 79 (0x4F) and stos added one
	add    dx,cx

    mov    al,dh
	and    al,ah                  ; ah has 0x7F (127)
	add    al,bh                  ; bh has the 0 to F offset
	xlat   BYTE PTR ds:[bx]       ;
	xlat   BYTE PTR cs:[bx]       ; before calling this function we already set CS to the correct segment..
	stos   BYTE PTR es:[di]       ;
	add    di,bp                  ; bi has 79 (0x4F) and stos added one
	add    dx,cx

    mov    al,dh
	and    al,ah                  ; ah has 0x7F (127)
	add    al,bh                  ; bh has the 0 to F offset
	xlat   BYTE PTR ds:[bx]       ;
	xlat   BYTE PTR cs:[bx]       ; before calling this function we already set CS to the correct segment..
	stos   BYTE PTR es:[di]       ;
	add    di,bp                  ; bi has 79 (0x4F) and stos added one
	add    dx,cx

    mov    al,dh
	and    al,ah                  ; ah has 0x7F (127)
	add    al,bh                  ; bh has the 0 to F offset
	xlat   BYTE PTR ds:[bx]       ;
	xlat   BYTE PTR cs:[bx]       ; before calling this function we already set CS to the correct segment..
	stos   BYTE PTR es:[di]       ;
	add    di,bp                  ; bi has 79 (0x4F) and stos added one
	add    dx,cx

    mov    al,dh
	and    al,ah                  ; ah has 0x7F (127)
	add    al,bh                  ; bh has the 0 to F offset
	xlat   BYTE PTR ds:[bx]       ;
	xlat   BYTE PTR cs:[bx]       ; before calling this function we already set CS to the correct segment..
	stos   BYTE PTR es:[di]       ;
	add    di,bp                  ; bi has 79 (0x4F) and stos added one
	add    dx,cx

    mov    al,dh
	and    al,ah                  ; ah has 0x7F (127)
	add    al,bh                  ; bh has the 0 to F offset
	xlat   BYTE PTR ds:[bx]       ;
	xlat   BYTE PTR cs:[bx]       ; before calling this function we already set CS to the correct segment..
	stos   BYTE PTR es:[di]       ;
	add    di,bp                  ; bi has 79 (0x4F) and stos added one
	add    dx,cx

    mov    al,dh
	and    al,ah                  ; ah has 0x7F (127)
	add    al,bh                  ; bh has the 0 to F offset
	xlat   BYTE PTR ds:[bx]       ;
	xlat   BYTE PTR cs:[bx]       ; before calling this function we already set CS to the correct segment..
	stos   BYTE PTR es:[di]       ;
	add    di,bp                  ; bi has 79 (0x4F) and stos added one
	add    dx,cx

    mov    al,dh
	and    al,ah                  ; ah has 0x7F (127)
	add    al,bh                  ; bh has the 0 to F offset
	xlat   BYTE PTR ds:[bx]       ;
	xlat   BYTE PTR cs:[bx]       ; before calling this function we already set CS to the correct segment..
	stos   BYTE PTR es:[di]       ;
	add    di,bp                  ; bi has 79 (0x4F) and stos added one
	add    dx,cx

    mov    al,dh
	and    al,ah                  ; ah has 0x7F (127)
	add    al,bh                  ; bh has the 0 to F offset
	xlat   BYTE PTR ds:[bx]       ;
	xlat   BYTE PTR cs:[bx]       ; before calling this function we already set CS to the correct segment..
	stos   BYTE PTR es:[di]       ;
	add    di,bp                  ; bi has 79 (0x4F) and stos added one
	add    dx,cx

    mov    al,dh
	and    al,ah                  ; ah has 0x7F (127)
	add    al,bh                  ; bh has the 0 to F offset
	xlat   BYTE PTR ds:[bx]       ;
	xlat   BYTE PTR cs:[bx]       ; before calling this function we already set CS to the correct segment..
	stos   BYTE PTR es:[di]       ;
	add    di,bp                  ; bi has 79 (0x4F) and stos added one
	add    dx,cx

    mov    al,dh
	and    al,ah                  ; ah has 0x7F (127)
	add    al,bh                  ; bh has the 0 to F offset
	xlat   BYTE PTR ds:[bx]       ;
	xlat   BYTE PTR cs:[bx]       ; before calling this function we already set CS to the correct segment..
	stos   BYTE PTR es:[di]       ;
	add    di,bp                  ; bi has 79 (0x4F) and stos added one
	add    dx,cx

    mov    al,dh
	and    al,ah                  ; ah has 0x7F (127)
	add    al,bh                  ; bh has the 0 to F offset
	xlat   BYTE PTR ds:[bx]       ;
	xlat   BYTE PTR cs:[bx]       ; before calling this function we already set CS to the correct segment..
	stos   BYTE PTR es:[di]       ;
	add    di,bp                  ; bi has 79 (0x4F) and stos added one
	add    dx,cx

    mov    al,dh
	and    al,ah                  ; ah has 0x7F (127)
	add    al,bh                  ; bh has the 0 to F offset
	xlat   BYTE PTR ds:[bx]       ;
	xlat   BYTE PTR cs:[bx]       ; before calling this function we already set CS to the correct segment..
	stos   BYTE PTR es:[di]       ;
	add    di,bp                  ; bi has 79 (0x4F) and stos added one
	add    dx,cx

    mov    al,dh
	and    al,ah                  ; ah has 0x7F (127)
	add    al,bh                  ; bh has the 0 to F offset
	xlat   BYTE PTR ds:[bx]       ;
	xlat   BYTE PTR cs:[bx]       ; before calling this function we already set CS to the correct segment..
	stos   BYTE PTR es:[di]       ;
	add    di,bp                  ; bi has 79 (0x4F) and stos added one
	add    dx,cx

    mov    al,dh
	and    al,ah                  ; ah has 0x7F (127)
	add    al,bh                  ; bh has the 0 to F offset
	xlat   BYTE PTR ds:[bx]       ;
	xlat   BYTE PTR cs:[bx]       ; before calling this function we already set CS to the correct segment..
	stos   BYTE PTR es:[di]       ;
	add    di,bp                  ; bi has 79 (0x4F) and stos added one
	add    dx,cx

    mov    al,dh
	and    al,ah                  ; ah has 0x7F (127)
	add    al,bh                  ; bh has the 0 to F offset
	xlat   BYTE PTR ds:[bx]       ;
	xlat   BYTE PTR cs:[bx]       ; before calling this function we already set CS to the correct segment..
	stos   BYTE PTR es:[di]       ;
	add    di,bp                  ; bi has 79 (0x4F) and stos added one
	add    dx,cx

    mov    al,dh
	and    al,ah                  ; ah has 0x7F (127)
	add    al,bh                  ; bh has the 0 to F offset
	xlat   BYTE PTR ds:[bx]       ;
	xlat   BYTE PTR cs:[bx]       ; before calling this function we already set CS to the correct segment..
	stos   BYTE PTR es:[di]       ;
	add    di,bp                  ; bi has 79 (0x4F) and stos added one
	add    dx,cx

    mov    al,dh
	and    al,ah                  ; ah has 0x7F (127)
	add    al,bh                  ; bh has the 0 to F offset
	xlat   BYTE PTR ds:[bx]       ;
	xlat   BYTE PTR cs:[bx]       ; before calling this function we already set CS to the correct segment..
	stos   BYTE PTR es:[di]       ;
	add    di,bp                  ; bi has 79 (0x4F) and stos added one
	add    dx,cx

    mov    al,dh
	and    al,ah                  ; ah has 0x7F (127)
	add    al,bh                  ; bh has the 0 to F offset
	xlat   BYTE PTR ds:[bx]       ;
	xlat   BYTE PTR cs:[bx]       ; before calling this function we already set CS to the correct segment..
	stos   BYTE PTR es:[di]       ;
	add    di,bp                  ; bi has 79 (0x4F) and stos added one
	add    dx,cx

    mov    al,dh
	and    al,ah                  ; ah has 0x7F (127)
	add    al,bh                  ; bh has the 0 to F offset
	xlat   BYTE PTR ds:[bx]       ;
	xlat   BYTE PTR cs:[bx]       ; before calling this function we already set CS to the correct segment..
	stos   BYTE PTR es:[di]       ;
	add    di,bp                  ; bi has 79 (0x4F) and stos added one
	add    dx,cx

    mov    al,dh
	and    al,ah                  ; ah has 0x7F (127)
	add    al,bh                  ; bh has the 0 to F offset
	xlat   BYTE PTR ds:[bx]       ;
	xlat   BYTE PTR cs:[bx]       ; before calling this function we already set CS to the correct segment..
	stos   BYTE PTR es:[di]       ;
	add    di,bp                  ; bi has 79 (0x4F) and stos added one
	add    dx,cx

    mov    al,dh
	and    al,ah                  ; ah has 0x7F (127)
	add    al,bh                  ; bh has the 0 to F offset
	xlat   BYTE PTR ds:[bx]       ;
	xlat   BYTE PTR cs:[bx]       ; before calling this function we already set CS to the correct segment..
	stos   BYTE PTR es:[di]       ;
	add    di,bp                  ; bi has 79 (0x4F) and stos added one
	add    dx,cx

    mov    al,dh
	and    al,ah                  ; ah has 0x7F (127)
	add    al,bh                  ; bh has the 0 to F offset
	xlat   BYTE PTR ds:[bx]       ;
	xlat   BYTE PTR cs:[bx]       ; before calling this function we already set CS to the correct segment..
	stos   BYTE PTR es:[di]       ;
	add    di,bp                  ; bi has 79 (0x4F) and stos added one
	add    dx,cx

    mov    al,dh
	and    al,ah                  ; ah has 0x7F (127)
	add    al,bh                  ; bh has the 0 to F offset
	xlat   BYTE PTR ds:[bx]       ;
	xlat   BYTE PTR cs:[bx]       ; before calling this function we already set CS to the correct segment..
	stos   BYTE PTR es:[di]       ;
	add    di,bp                  ; bi has 79 (0x4F) and stos added one
	add    dx,cx

    mov    al,dh
	and    al,ah                  ; ah has 0x7F (127)
	add    al,bh                  ; bh has the 0 to F offset
	xlat   BYTE PTR ds:[bx]       ;
	xlat   BYTE PTR cs:[bx]       ; before calling this function we already set CS to the correct segment..
	stos   BYTE PTR es:[di]       ;
	add    di,bp                  ; bi has 79 (0x4F) and stos added one
	add    dx,cx

    mov    al,dh
	and    al,ah                  ; ah has 0x7F (127)
	add    al,bh                  ; bh has the 0 to F offset
	xlat   BYTE PTR ds:[bx]       ;
	xlat   BYTE PTR cs:[bx]       ; before calling this function we already set CS to the correct segment..
	stos   BYTE PTR es:[di]       ;
	add    di,bp                  ; bi has 79 (0x4F) and stos added one
	add    dx,cx

    mov    al,dh
	and    al,ah                  ; ah has 0x7F (127)
	add    al,bh                  ; bh has the 0 to F offset
	xlat   BYTE PTR ds:[bx]       ;
	xlat   BYTE PTR cs:[bx]       ; before calling this function we already set CS to the correct segment..
	stos   BYTE PTR es:[di]       ;
	add    di,bp                  ; bi has 79 (0x4F) and stos added one
	add    dx,cx

    mov    al,dh
	and    al,ah                  ; ah has 0x7F (127)
	add    al,bh                  ; bh has the 0 to F offset
	xlat   BYTE PTR ds:[bx]       ;
	xlat   BYTE PTR cs:[bx]       ; before calling this function we already set CS to the correct segment..
	stos   BYTE PTR es:[di]       ;
	add    di,bp                  ; bi has 79 (0x4F) and stos added one
	add    dx,cx

    mov    al,dh
	and    al,ah                  ; ah has 0x7F (127)
	add    al,bh                  ; bh has the 0 to F offset
	xlat   BYTE PTR ds:[bx]       ;
	xlat   BYTE PTR cs:[bx]       ; before calling this function we already set CS to the correct segment..
	stos   BYTE PTR es:[di]       ;
	add    di,bp                  ; bi has 79 (0x4F) and stos added one
	add    dx,cx

    mov    al,dh
	and    al,ah                  ; ah has 0x7F (127)
	add    al,bh                  ; bh has the 0 to F offset
	xlat   BYTE PTR ds:[bx]       ;
	xlat   BYTE PTR cs:[bx]       ; before calling this function we already set CS to the correct segment..
	stos   BYTE PTR es:[di]       ;
	add    di,bp                  ; bi has 79 (0x4F) and stos added one
	add    dx,cx

    mov    al,dh
	and    al,ah                  ; ah has 0x7F (127)
	add    al,bh                  ; bh has the 0 to F offset
	xlat   BYTE PTR ds:[bx]       ;
	xlat   BYTE PTR cs:[bx]       ; before calling this function we already set CS to the correct segment..
	stos   BYTE PTR es:[di]       ;
	add    di,bp                  ; bi has 79 (0x4F) and stos added one
	add    dx,cx

    mov    al,dh
	and    al,ah                  ; ah has 0x7F (127)
	add    al,bh                  ; bh has the 0 to F offset
	xlat   BYTE PTR ds:[bx]       ;
	xlat   BYTE PTR cs:[bx]       ; before calling this function we already set CS to the correct segment..
	stos   BYTE PTR es:[di]       ;
	add    di,bp                  ; bi has 79 (0x4F) and stos added one
	add    dx,cx

    mov    al,dh
	and    al,ah                  ; ah has 0x7F (127)
	add    al,bh                  ; bh has the 0 to F offset
	xlat   BYTE PTR ds:[bx]       ;
	xlat   BYTE PTR cs:[bx]       ; before calling this function we already set CS to the correct segment..
	stos   BYTE PTR es:[di]       ;
	add    di,bp                  ; bi has 79 (0x4F) and stos added one
	add    dx,cx

    mov    al,dh
	and    al,ah                  ; ah has 0x7F (127)
	add    al,bh                  ; bh has the 0 to F offset
	xlat   BYTE PTR ds:[bx]       ;
	xlat   BYTE PTR cs:[bx]       ; before calling this function we already set CS to the correct segment..
	stos   BYTE PTR es:[di]       ;
	add    di,bp                  ; bi has 79 (0x4F) and stos added one
	add    dx,cx

    mov    al,dh
	and    al,ah                  ; ah has 0x7F (127)
	add    al,bh                  ; bh has the 0 to F offset
	xlat   BYTE PTR ds:[bx]       ;
	xlat   BYTE PTR cs:[bx]       ; before calling this function we already set CS to the correct segment..
	stos   BYTE PTR es:[di]       ;
	add    di,bp                  ; bi has 79 (0x4F) and stos added one
	add    dx,cx

    mov    al,dh
	and    al,ah                  ; ah has 0x7F (127)
	add    al,bh                  ; bh has the 0 to F offset
	xlat   BYTE PTR ds:[bx]       ;
	xlat   BYTE PTR cs:[bx]       ; before calling this function we already set CS to the correct segment..
	stos   BYTE PTR es:[di]       ;
	add    di,bp                  ; bi has 79 (0x4F) and stos added one
	add    dx,cx

    mov    al,dh
	and    al,ah                  ; ah has 0x7F (127)
	add    al,bh                  ; bh has the 0 to F offset
	xlat   BYTE PTR ds:[bx]       ;
	xlat   BYTE PTR cs:[bx]       ; before calling this function we already set CS to the correct segment..
	stos   BYTE PTR es:[di]       ;
	add    di,bp                  ; bi has 79 (0x4F) and stos added one
	add    dx,cx

    mov    al,dh
	and    al,ah                  ; ah has 0x7F (127)
	add    al,bh                  ; bh has the 0 to F offset
	xlat   BYTE PTR ds:[bx]       ;
	xlat   BYTE PTR cs:[bx]       ; before calling this function we already set CS to the correct segment..
	stos   BYTE PTR es:[di]       ;
	add    di,bp                  ; bi has 79 (0x4F) and stos added one
	add    dx,cx

    mov    al,dh
	and    al,ah                  ; ah has 0x7F (127)
	add    al,bh                  ; bh has the 0 to F offset
	xlat   BYTE PTR ds:[bx]       ;
	xlat   BYTE PTR cs:[bx]       ; before calling this function we already set CS to the correct segment..
	stos   BYTE PTR es:[di]       ;
	add    di,bp                  ; bi has 79 (0x4F) and stos added one
	add    dx,cx

    mov    al,dh
	and    al,ah                  ; ah has 0x7F (127)
	add    al,bh                  ; bh has the 0 to F offset
	xlat   BYTE PTR ds:[bx]       ;
	xlat   BYTE PTR cs:[bx]       ; before calling this function we already set CS to the correct segment..
	stos   BYTE PTR es:[di]       ;
	add    di,bp                  ; bi has 79 (0x4F) and stos added one
	add    dx,cx

    mov    al,dh
	and    al,ah                  ; ah has 0x7F (127)
	add    al,bh                  ; bh has the 0 to F offset
	xlat   BYTE PTR ds:[bx]       ;
	xlat   BYTE PTR cs:[bx]       ; before calling this function we already set CS to the correct segment..
	stos   BYTE PTR es:[di]       ;
	add    di,bp                  ; bi has 79 (0x4F) and stos added one
	add    dx,cx

    mov    al,dh
	and    al,ah                  ; ah has 0x7F (127)
	add    al,bh                  ; bh has the 0 to F offset
	xlat   BYTE PTR ds:[bx]       ;
	xlat   BYTE PTR cs:[bx]       ; before calling this function we already set CS to the correct segment..
	stos   BYTE PTR es:[di]       ;
	add    di,bp                  ; bi has 79 (0x4F) and stos added one
	add    dx,cx

    mov    al,dh
	and    al,ah                  ; ah has 0x7F (127)
	add    al,bh                  ; bh has the 0 to F offset
	xlat   BYTE PTR ds:[bx]       ;
	xlat   BYTE PTR cs:[bx]       ; before calling this function we already set CS to the correct segment..
	stos   BYTE PTR es:[di]       ;
	add    di,bp                  ; bi has 79 (0x4F) and stos added one
	add    dx,cx

    mov    al,dh
	and    al,ah                  ; ah has 0x7F (127)
	add    al,bh                  ; bh has the 0 to F offset
	xlat   BYTE PTR ds:[bx]       ;
	xlat   BYTE PTR cs:[bx]       ; before calling this function we already set CS to the correct segment..
	stos   BYTE PTR es:[di]       ;
	add    di,bp                  ; bi has 79 (0x4F) and stos added one
	add    dx,cx

    mov    al,dh
	and    al,ah                  ; ah has 0x7F (127)
	add    al,bh                  ; bh has the 0 to F offset
	xlat   BYTE PTR ds:[bx]       ;
	xlat   BYTE PTR cs:[bx]       ; before calling this function we already set CS to the correct segment..
	stos   BYTE PTR es:[di]       ;
	add    di,bp                  ; bi has 79 (0x4F) and stos added one
	add    dx,cx

    mov    al,dh
	and    al,ah                  ; ah has 0x7F (127)
	add    al,bh                  ; bh has the 0 to F offset
	xlat   BYTE PTR ds:[bx]       ;
	xlat   BYTE PTR cs:[bx]       ; before calling this function we already set CS to the correct segment..
	stos   BYTE PTR es:[di]       ;
	add    di,bp                  ; bi has 79 (0x4F) and stos added one
	add    dx,cx

    mov    al,dh
	and    al,ah                  ; ah has 0x7F (127)
	add    al,bh                  ; bh has the 0 to F offset
	xlat   BYTE PTR ds:[bx]       ;
	xlat   BYTE PTR cs:[bx]       ; before calling this function we already set CS to the correct segment..
	stos   BYTE PTR es:[di]       ;
	add    di,bp                  ; bi has 79 (0x4F) and stos added one
	add    dx,cx

    mov    al,dh
	and    al,ah                  ; ah has 0x7F (127)
	add    al,bh                  ; bh has the 0 to F offset
	xlat   BYTE PTR ds:[bx]       ;
	xlat   BYTE PTR cs:[bx]       ; before calling this function we already set CS to the correct segment..
	stos   BYTE PTR es:[di]       ;
	add    di,bp                  ; bi has 79 (0x4F) and stos added one
	add    dx,cx

    mov    al,dh
	and    al,ah                  ; ah has 0x7F (127)
	add    al,bh                  ; bh has the 0 to F offset
	xlat   BYTE PTR ds:[bx]       ;
	xlat   BYTE PTR cs:[bx]       ; before calling this function we already set CS to the correct segment..
	stos   BYTE PTR es:[di]       ;
	add    di,bp                  ; bi has 79 (0x4F) and stos added one
	add    dx,cx

    mov    al,dh
	and    al,ah                  ; ah has 0x7F (127)
	add    al,bh                  ; bh has the 0 to F offset
	xlat   BYTE PTR ds:[bx]       ;
	xlat   BYTE PTR cs:[bx]       ; before calling this function we already set CS to the correct segment..
	stos   BYTE PTR es:[di]       ;
	add    di,bp                  ; bi has 79 (0x4F) and stos added one
	add    dx,cx

    mov    al,dh
	and    al,ah                  ; ah has 0x7F (127)
	add    al,bh                  ; bh has the 0 to F offset
	xlat   BYTE PTR ds:[bx]       ;
	xlat   BYTE PTR cs:[bx]       ; before calling this function we already set CS to the correct segment..
	stos   BYTE PTR es:[di]       ;
	add    di,bp                  ; bi has 79 (0x4F) and stos added one
	add    dx,cx

    mov    al,dh
	and    al,ah                  ; ah has 0x7F (127)
	add    al,bh                  ; bh has the 0 to F offset
	xlat   BYTE PTR ds:[bx]       ;
	xlat   BYTE PTR cs:[bx]       ; before calling this function we already set CS to the correct segment..
	stos   BYTE PTR es:[di]       ;
	add    di,bp                  ; bi has 79 (0x4F) and stos added one
	add    dx,cx

    mov    al,dh
	and    al,ah                  ; ah has 0x7F (127)
	add    al,bh                  ; bh has the 0 to F offset
	xlat   BYTE PTR ds:[bx]       ;
	xlat   BYTE PTR cs:[bx]       ; before calling this function we already set CS to the correct segment..
	stos   BYTE PTR es:[di]       ;
	add    di,bp                  ; bi has 79 (0x4F) and stos added one
	add    dx,cx

    mov    al,dh
	and    al,ah                  ; ah has 0x7F (127)
	add    al,bh                  ; bh has the 0 to F offset
	xlat   BYTE PTR ds:[bx]       ;
	xlat   BYTE PTR cs:[bx]       ; before calling this function we already set CS to the correct segment..
	stos   BYTE PTR es:[di]       ;
	add    di,bp                  ; bi has 79 (0x4F) and stos added one
	add    dx,cx

    mov    al,dh
	and    al,ah                  ; ah has 0x7F (127)
	add    al,bh                  ; bh has the 0 to F offset
	xlat   BYTE PTR ds:[bx]       ;
	xlat   BYTE PTR cs:[bx]       ; before calling this function we already set CS to the correct segment..
	stos   BYTE PTR es:[di]       ;
	add    di,bp                  ; bi has 79 (0x4F) and stos added one
	add    dx,cx

    mov    al,dh
	and    al,ah                  ; ah has 0x7F (127)
	add    al,bh                  ; bh has the 0 to F offset
	xlat   BYTE PTR ds:[bx]       ;
	xlat   BYTE PTR cs:[bx]       ; before calling this function we already set CS to the correct segment..
	stos   BYTE PTR es:[di]       ;
	add    di,bp                  ; bi has 79 (0x4F) and stos added one
	add    dx,cx

    mov    al,dh
	and    al,ah                  ; ah has 0x7F (127)
	add    al,bh                  ; bh has the 0 to F offset
	xlat   BYTE PTR ds:[bx]       ;
	xlat   BYTE PTR cs:[bx]       ; before calling this function we already set CS to the correct segment..
	stos   BYTE PTR es:[di]       ;
	add    di,bp                  ; bi has 79 (0x4F) and stos added one
	add    dx,cx

    mov    al,dh
	and    al,ah                  ; ah has 0x7F (127)
	add    al,bh                  ; bh has the 0 to F offset
	xlat   BYTE PTR ds:[bx]       ;
	xlat   BYTE PTR cs:[bx]       ; before calling this function we already set CS to the correct segment..
	stos   BYTE PTR es:[di]       ;
	add    di,bp                  ; bi has 79 (0x4F) and stos added one
	add    dx,cx

    mov    al,dh
	and    al,ah                  ; ah has 0x7F (127)
	add    al,bh                  ; bh has the 0 to F offset
	xlat   BYTE PTR ds:[bx]       ;
	xlat   BYTE PTR cs:[bx]       ; before calling this function we already set CS to the correct segment..
	stos   BYTE PTR es:[di]       ;
	add    di,bp                  ; bi has 79 (0x4F) and stos added one
	add    dx,cx

    mov    al,dh
	and    al,ah                  ; ah has 0x7F (127)
	add    al,bh                  ; bh has the 0 to F offset
	xlat   BYTE PTR ds:[bx]       ;
	xlat   BYTE PTR cs:[bx]       ; before calling this function we already set CS to the correct segment..
	stos   BYTE PTR es:[di]       ;
	add    di,bp                  ; bi has 79 (0x4F) and stos added one
	add    dx,cx

    mov    al,dh
	and    al,ah                  ; ah has 0x7F (127)
	add    al,bh                  ; bh has the 0 to F offset
	xlat   BYTE PTR ds:[bx]       ;
	xlat   BYTE PTR cs:[bx]       ; before calling this function we already set CS to the correct segment..
	stos   BYTE PTR es:[di]       ;
	add    di,bp                  ; bi has 79 (0x4F) and stos added one
	add    dx,cx

    mov    al,dh
	and    al,ah                  ; ah has 0x7F (127)
	add    al,bh                  ; bh has the 0 to F offset
	xlat   BYTE PTR ds:[bx]       ;
	xlat   BYTE PTR cs:[bx]       ; before calling this function we already set CS to the correct segment..
	stos   BYTE PTR es:[di]       ;
	add    di,bp                  ; bi has 79 (0x4F) and stos added one
	add    dx,cx

    mov    al,dh
	and    al,ah                  ; ah has 0x7F (127)
	add    al,bh                  ; bh has the 0 to F offset
	xlat   BYTE PTR ds:[bx]       ;
	xlat   BYTE PTR cs:[bx]       ; before calling this function we already set CS to the correct segment..
	stos   BYTE PTR es:[di]       ;
	add    di,bp                  ; bi has 79 (0x4F) and stos added one
	add    dx,cx

    mov    al,dh
	and    al,ah                  ; ah has 0x7F (127)
	add    al,bh                  ; bh has the 0 to F offset
	xlat   BYTE PTR ds:[bx]       ;
	xlat   BYTE PTR cs:[bx]       ; before calling this function we already set CS to the correct segment..
	stos   BYTE PTR es:[di]       ;
	add    di,bp                  ; bi has 79 (0x4F) and stos added one
	add    dx,cx

    mov    al,dh
	and    al,ah                  ; ah has 0x7F (127)
	add    al,bh                  ; bh has the 0 to F offset
	xlat   BYTE PTR ds:[bx]       ;
	xlat   BYTE PTR cs:[bx]       ; before calling this function we already set CS to the correct segment..
	stos   BYTE PTR es:[di]       ;
	add    di,bp                  ; bi has 79 (0x4F) and stos added one
	add    dx,cx

    mov    al,dh
	and    al,ah                  ; ah has 0x7F (127)
	add    al,bh                  ; bh has the 0 to F offset
	xlat   BYTE PTR ds:[bx]       ;
	xlat   BYTE PTR cs:[bx]       ; before calling this function we already set CS to the correct segment..
	stos   BYTE PTR es:[di]       ;
	add    di,bp                  ; bi has 79 (0x4F) and stos added one
	add    dx,cx

    mov    al,dh
	and    al,ah                  ; ah has 0x7F (127)
	add    al,bh                  ; bh has the 0 to F offset
	xlat   BYTE PTR ds:[bx]       ;
	xlat   BYTE PTR cs:[bx]       ; before calling this function we already set CS to the correct segment..
	stos   BYTE PTR es:[di]       ;
	add    di,bp                  ; bi has 79 (0x4F) and stos added one
	add    dx,cx

    mov    al,dh
	and    al,ah                  ; ah has 0x7F (127)
	add    al,bh                  ; bh has the 0 to F offset
	xlat   BYTE PTR ds:[bx]       ;
	xlat   BYTE PTR cs:[bx]       ; before calling this function we already set CS to the correct segment..
	stos   BYTE PTR es:[di]       ;
	add    di,bp                  ; bi has 79 (0x4F) and stos added one
	add    dx,cx

    mov    al,dh
	and    al,ah                  ; ah has 0x7F (127)
	add    al,bh                  ; bh has the 0 to F offset
	xlat   BYTE PTR ds:[bx]       ;
	xlat   BYTE PTR cs:[bx]       ; before calling this function we already set CS to the correct segment..
	stos   BYTE PTR es:[di]       ;
	add    di,bp                  ; bi has 79 (0x4F) and stos added one
	add    dx,cx

    mov    al,dh
	and    al,ah                  ; ah has 0x7F (127)
	add    al,bh                  ; bh has the 0 to F offset
	xlat   BYTE PTR ds:[bx]       ;
	xlat   BYTE PTR cs:[bx]       ; before calling this function we already set CS to the correct segment..
	stos   BYTE PTR es:[di]       ;
	add    di,bp                  ; bi has 79 (0x4F) and stos added one
	add    dx,cx

    mov    al,dh
	and    al,ah                  ; ah has 0x7F (127)
	add    al,bh                  ; bh has the 0 to F offset
	xlat   BYTE PTR ds:[bx]       ;
	xlat   BYTE PTR cs:[bx]       ; before calling this function we already set CS to the correct segment..
	stos   BYTE PTR es:[di]       ;
	add    di,bp                  ; bi has 79 (0x4F) and stos added one
	add    dx,cx

    mov    al,dh
	and    al,ah                  ; ah has 0x7F (127)
	add    al,bh                  ; bh has the 0 to F offset
	xlat   BYTE PTR ds:[bx]       ;
	xlat   BYTE PTR cs:[bx]       ; before calling this function we already set CS to the correct segment..
	stos   BYTE PTR es:[di]       ;
	add    di,bp                  ; bi has 79 (0x4F) and stos added one
	add    dx,cx

    mov    al,dh
	and    al,ah                  ; ah has 0x7F (127)
	add    al,bh                  ; bh has the 0 to F offset
	xlat   BYTE PTR ds:[bx]       ;
	xlat   BYTE PTR cs:[bx]       ; before calling this function we already set CS to the correct segment..
	stos   BYTE PTR es:[di]       ;
	add    di,bp                  ; bi has 79 (0x4F) and stos added one
	add    dx,cx

    mov    al,dh
	and    al,ah                  ; ah has 0x7F (127)
	add    al,bh                  ; bh has the 0 to F offset
	xlat   BYTE PTR ds:[bx]       ;
	xlat   BYTE PTR cs:[bx]       ; before calling this function we already set CS to the correct segment..
	stos   BYTE PTR es:[di]       ;
	add    di,bp                  ; bi has 79 (0x4F) and stos added one
	add    dx,cx

    mov    al,dh
	and    al,ah                  ; ah has 0x7F (127)
	add    al,bh                  ; bh has the 0 to F offset
	xlat   BYTE PTR ds:[bx]       ;
	xlat   BYTE PTR cs:[bx]       ; before calling this function we already set CS to the correct segment..
	stos   BYTE PTR es:[di]       ;
	add    di,bp                  ; bi has 79 (0x4F) and stos added one
	add    dx,cx

    mov    al,dh
	and    al,ah                  ; ah has 0x7F (127)
	add    al,bh                  ; bh has the 0 to F offset
	xlat   BYTE PTR ds:[bx]       ;
	xlat   BYTE PTR cs:[bx]       ; before calling this function we already set CS to the correct segment..
	stos   BYTE PTR es:[di]       ;
	add    di,bp                  ; bi has 79 (0x4F) and stos added one
	add    dx,cx

    mov    al,dh
	and    al,ah                  ; ah has 0x7F (127)
	add    al,bh                  ; bh has the 0 to F offset
	xlat   BYTE PTR ds:[bx]       ;
	xlat   BYTE PTR cs:[bx]       ; before calling this function we already set CS to the correct segment..
	stos   BYTE PTR es:[di]       ;
	add    di,bp                  ; bi has 79 (0x4F) and stos added one
	add    dx,cx

    mov    al,dh
	and    al,ah                  ; ah has 0x7F (127)
	add    al,bh                  ; bh has the 0 to F offset
	xlat   BYTE PTR ds:[bx]       ;
	xlat   BYTE PTR cs:[bx]       ; before calling this function we already set CS to the correct segment..
	stos   BYTE PTR es:[di]       ;
	add    di,bp                  ; bi has 79 (0x4F) and stos added one
	add    dx,cx

    mov    al,dh
	and    al,ah                  ; ah has 0x7F (127)
	add    al,bh                  ; bh has the 0 to F offset
	xlat   BYTE PTR ds:[bx]       ;
	xlat   BYTE PTR cs:[bx]       ; before calling this function we already set CS to the correct segment..
	stos   BYTE PTR es:[di]       ;
	add    di,bp                  ; bi has 79 (0x4F) and stos added one
	add    dx,cx

    mov    al,dh
	and    al,ah                  ; ah has 0x7F (127)
	add    al,bh                  ; bh has the 0 to F offset
	xlat   BYTE PTR ds:[bx]       ;
	xlat   BYTE PTR cs:[bx]       ; before calling this function we already set CS to the correct segment..
	stos   BYTE PTR es:[di]       ;
	add    di,bp                  ; bi has 79 (0x4F) and stos added one
	add    dx,cx

    mov    al,dh
	and    al,ah                  ; ah has 0x7F (127)
	add    al,bh                  ; bh has the 0 to F offset
	xlat   BYTE PTR ds:[bx]       ;
	xlat   BYTE PTR cs:[bx]       ; before calling this function we already set CS to the correct segment..
	stos   BYTE PTR es:[di]       ;
	add    di,bp                  ; bi has 79 (0x4F) and stos added one
	add    dx,cx

    mov    al,dh
	and    al,ah                  ; ah has 0x7F (127)
	add    al,bh                  ; bh has the 0 to F offset
	xlat   BYTE PTR ds:[bx]       ;
	xlat   BYTE PTR cs:[bx]       ; before calling this function we already set CS to the correct segment..
	stos   BYTE PTR es:[di]       ;
	add    di,bp                  ; bi has 79 (0x4F) and stos added one
	add    dx,cx

    mov    al,dh
	and    al,ah                  ; ah has 0x7F (127)
	add    al,bh                  ; bh has the 0 to F offset
	xlat   BYTE PTR ds:[bx]       ;
	xlat   BYTE PTR cs:[bx]       ; before calling this function we already set CS to the correct segment..
	stos   BYTE PTR es:[di]       ;
	add    di,bp                  ; bi has 79 (0x4F) and stos added one
	add    dx,cx

    mov    al,dh
	and    al,ah                  ; ah has 0x7F (127)
	add    al,bh                  ; bh has the 0 to F offset
	xlat   BYTE PTR ds:[bx]       ;
	xlat   BYTE PTR cs:[bx]       ; before calling this function we already set CS to the correct segment..
	stos   BYTE PTR es:[di]       ;
	add    di,bp                  ; bi has 79 (0x4F) and stos added one
	add    dx,cx

    mov    al,dh
	and    al,ah                  ; ah has 0x7F (127)
	add    al,bh                  ; bh has the 0 to F offset
	xlat   BYTE PTR ds:[bx]       ;
	xlat   BYTE PTR cs:[bx]       ; before calling this function we already set CS to the correct segment..
	stos   BYTE PTR es:[di]       ;
	add    di,bp                  ; bi has 79 (0x4F) and stos added one
	add    dx,cx

    mov    al,dh
	and    al,ah                  ; ah has 0x7F (127)
	add    al,bh                  ; bh has the 0 to F offset
	xlat   BYTE PTR ds:[bx]       ;
	xlat   BYTE PTR cs:[bx]       ; before calling this function we already set CS to the correct segment..
	stos   BYTE PTR es:[di]       ;
	add    di,bp                  ; bi has 79 (0x4F) and stos added one
	add    dx,cx

    mov    al,dh
	and    al,ah                  ; ah has 0x7F (127)
	add    al,bh                  ; bh has the 0 to F offset
	xlat   BYTE PTR ds:[bx]       ;
	xlat   BYTE PTR cs:[bx]       ; before calling this function we already set CS to the correct segment..
	stos   BYTE PTR es:[di]       ;
	add    di,bp                  ; bi has 79 (0x4F) and stos added one
	add    dx,cx

    mov    al,dh
	and    al,ah                  ; ah has 0x7F (127)
	add    al,bh                  ; bh has the 0 to F offset
	xlat   BYTE PTR ds:[bx]       ;
	xlat   BYTE PTR cs:[bx]       ; before calling this function we already set CS to the correct segment..
	stos   BYTE PTR es:[di]       ;
	add    di,bp                  ; bi has 79 (0x4F) and stos added one
	add    dx,cx

    mov    al,dh
	and    al,ah                  ; ah has 0x7F (127)
	add    al,bh                  ; bh has the 0 to F offset
	xlat   BYTE PTR ds:[bx]       ;
	xlat   BYTE PTR cs:[bx]       ; before calling this function we already set CS to the correct segment..
	stos   BYTE PTR es:[di]       ;
	add    di,bp                  ; bi has 79 (0x4F) and stos added one
	add    dx,cx

    mov    al,dh
	and    al,ah                  ; ah has 0x7F (127)
	add    al,bh                  ; bh has the 0 to F offset
	xlat   BYTE PTR ds:[bx]       ;
	xlat   BYTE PTR cs:[bx]       ; before calling this function we already set CS to the correct segment..
	stos   BYTE PTR es:[di]       ;
	add    di,bp                  ; bi has 79 (0x4F) and stos added one
	add    dx,cx

    mov    al,dh
	and    al,ah                  ; ah has 0x7F (127)
	add    al,bh                  ; bh has the 0 to F offset
	xlat   BYTE PTR ds:[bx]       ;
	xlat   BYTE PTR cs:[bx]       ; before calling this function we already set CS to the correct segment..
	stos   BYTE PTR es:[di]       ;
	add    di,bp                  ; bi has 79 (0x4F) and stos added one
	add    dx,cx

    mov    al,dh
	and    al,ah                  ; ah has 0x7F (127)
	add    al,bh                  ; bh has the 0 to F offset
	xlat   BYTE PTR ds:[bx]       ;
	xlat   BYTE PTR cs:[bx]       ; before calling this function we already set CS to the correct segment..
	stos   BYTE PTR es:[di]       ;
	add    di,bp                  ; bi has 79 (0x4F) and stos added one
	add    dx,cx

    mov    al,dh
	and    al,ah                  ; ah has 0x7F (127)
	add    al,bh                  ; bh has the 0 to F offset
	xlat   BYTE PTR ds:[bx]       ;
	xlat   BYTE PTR cs:[bx]       ; before calling this function we already set CS to the correct segment..
	stos   BYTE PTR es:[di]       ;
	; dont need these in last loop
    ;add    di,bp                  ; bi has 79 (0x4F) and stos added one
	;add    dx,cx

loop_done:
; clean up
    pop   bp
    pop   ds
    sti         ; enable interrupts before return
    leave 
    pop   di
    pop   dx
    pop   cx
    pop   bx
    retf


ENDP


END
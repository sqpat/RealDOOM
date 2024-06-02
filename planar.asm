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
EXTRN   _dc_yl_lookup_val:WORD

EXTRN	_dc_yl:WORD
EXTRN	_dc_yh:WORD
EXTRN	_dc_source:DWORD

EXTRN	_dc_colormap_index:BYTE
EXTRN	_dc_colormap_segment:WORD

EXTRN   _detailshift:BYTE
EXTRN   _quality_port_lookup:BYTE


EXTRN	_ds_xstep:DWORD
EXTRN	_ds_ystep:DWORD


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
	push  si


do_draw:
    ;cli   ; disable interrupts on enter main draw function (so we can use some registers safely)

    ; 	outp (SC_INDEX+1,1<<(dc_x&3));

	mov   dx, word ptr [_dc_x]
    mov   di, dx         ; copy to di

    mov   cl, 2
	mov   bl, byte ptr [_detailshift]
	sub   cl, bl
    shr   di, cl

    

	xor   bh, bh ; todo figure out a trick to get bh to 0 for free... maybe just make detailshift an int16

    and   dl, 3     ; and dc_x by 3
	sal   bl, 1
	sal   bl, 1
	add   bl, dl

    ;    bl format is now 
	; n:0    a:detailshift   b:dc_x & 3
	;   nnnnaabb

	; use this as lookup to get the al byte

    mov al, byte ptr [_quality_port_lookup + bx]

    mov   dx, 3c5h
    out   dx, al

    ; dest = destview + dc_yl*80 + (dc_x>>2); 
    ; frac.w = dc_texturemid.w + (dc_yl-centery)*dc_iscale


    mov   ax, word ptr [_dc_yl]
	; shift already done earlier
    
	; todo what if we just add directly to di instead of dx
	

    add   di, word ptr [_dc_yl_lookup_val]   ; quick mul 80
    add   di, word ptr [_destview + 0] 
    cwd                         			 ; we know ax is positive, this is a quick clear out of dx
    mov   bx, word ptr [_dc_iscale + 0]   
    mov   cx, word ptr [_dc_iscale + 2]
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
   mov     si,  4Fh
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
	add    di,si                  ; si has 79 (0x4F) and stos added one
	add    dx,cx

    mov    al,dh
	and    al,ah                  ; ah has 0x7F (127)
	add    al,bh                  ; bh has the 0 to F offset
	xlat   BYTE PTR ds:[bx]       ;
	xlat   BYTE PTR cs:[bx]       ; before calling this function we already set CS to the correct segment..
	stos   BYTE PTR es:[di]       ;
	add    di,si                  ; si has 79 (0x4F) and stos added one
	add    dx,cx

    mov    al,dh
	and    al,ah                  ; ah has 0x7F (127)
	add    al,bh                  ; bh has the 0 to F offset
	xlat   BYTE PTR ds:[bx]       ;
	xlat   BYTE PTR cs:[bx]       ; before calling this function we already set CS to the correct segment..
	stos   BYTE PTR es:[di]       ;
	add    di,si                  ; si has 79 (0x4F) and stos added one
	add    dx,cx

    mov    al,dh
	and    al,ah                  ; ah has 0x7F (127)
	add    al,bh                  ; bh has the 0 to F offset
	xlat   BYTE PTR ds:[bx]       ;
	xlat   BYTE PTR cs:[bx]       ; before calling this function we already set CS to the correct segment..
	stos   BYTE PTR es:[di]       ;
	add    di,si                  ; si has 79 (0x4F) and stos added one
	add    dx,cx

    mov    al,dh
	and    al,ah                  ; ah has 0x7F (127)
	add    al,bh                  ; bh has the 0 to F offset
	xlat   BYTE PTR ds:[bx]       ;
	xlat   BYTE PTR cs:[bx]       ; before calling this function we already set CS to the correct segment..
	stos   BYTE PTR es:[di]       ;
	add    di,si                  ; si has 79 (0x4F) and stos added one
	add    dx,cx

    mov    al,dh
	and    al,ah                  ; ah has 0x7F (127)
	add    al,bh                  ; bh has the 0 to F offset
	xlat   BYTE PTR ds:[bx]       ;
	xlat   BYTE PTR cs:[bx]       ; before calling this function we already set CS to the correct segment..
	stos   BYTE PTR es:[di]       ;
	add    di,si                  ; si has 79 (0x4F) and stos added one
	add    dx,cx

    mov    al,dh
	and    al,ah                  ; ah has 0x7F (127)
	add    al,bh                  ; bh has the 0 to F offset
	xlat   BYTE PTR ds:[bx]       ;
	xlat   BYTE PTR cs:[bx]       ; before calling this function we already set CS to the correct segment..
	stos   BYTE PTR es:[di]       ;
	add    di,si                  ; si has 79 (0x4F) and stos added one
	add    dx,cx

    mov    al,dh
	and    al,ah                  ; ah has 0x7F (127)
	add    al,bh                  ; bh has the 0 to F offset
	xlat   BYTE PTR ds:[bx]       ;
	xlat   BYTE PTR cs:[bx]       ; before calling this function we already set CS to the correct segment..
	stos   BYTE PTR es:[di]       ;
	add    di,si                  ; si has 79 (0x4F) and stos added one
	add    dx,cx

    mov    al,dh
	and    al,ah                  ; ah has 0x7F (127)
	add    al,bh                  ; bh has the 0 to F offset
	xlat   BYTE PTR ds:[bx]       ;
	xlat   BYTE PTR cs:[bx]       ; before calling this function we already set CS to the correct segment..
	stos   BYTE PTR es:[di]       ;
	add    di,si                  ; si has 79 (0x4F) and stos added one
	add    dx,cx

    mov    al,dh
	and    al,ah                  ; ah has 0x7F (127)
	add    al,bh                  ; bh has the 0 to F offset
	xlat   BYTE PTR ds:[bx]       ;
	xlat   BYTE PTR cs:[bx]       ; before calling this function we already set CS to the correct segment..
	stos   BYTE PTR es:[di]       ;
	add    di,si                  ; si has 79 (0x4F) and stos added one
	add    dx,cx

    mov    al,dh
	and    al,ah                  ; ah has 0x7F (127)
	add    al,bh                  ; bh has the 0 to F offset
	xlat   BYTE PTR ds:[bx]       ;
	xlat   BYTE PTR cs:[bx]       ; before calling this function we already set CS to the correct segment..
	stos   BYTE PTR es:[di]       ;
	add    di,si                  ; si has 79 (0x4F) and stos added one
	add    dx,cx

    mov    al,dh
	and    al,ah                  ; ah has 0x7F (127)
	add    al,bh                  ; bh has the 0 to F offset
	xlat   BYTE PTR ds:[bx]       ;
	xlat   BYTE PTR cs:[bx]       ; before calling this function we already set CS to the correct segment..
	stos   BYTE PTR es:[di]       ;
	add    di,si                  ; si has 79 (0x4F) and stos added one
	add    dx,cx

    mov    al,dh
	and    al,ah                  ; ah has 0x7F (127)
	add    al,bh                  ; bh has the 0 to F offset
	xlat   BYTE PTR ds:[bx]       ;
	xlat   BYTE PTR cs:[bx]       ; before calling this function we already set CS to the correct segment..
	stos   BYTE PTR es:[di]       ;
	add    di,si                  ; si has 79 (0x4F) and stos added one
	add    dx,cx

    mov    al,dh
	and    al,ah                  ; ah has 0x7F (127)
	add    al,bh                  ; bh has the 0 to F offset
	xlat   BYTE PTR ds:[bx]       ;
	xlat   BYTE PTR cs:[bx]       ; before calling this function we already set CS to the correct segment..
	stos   BYTE PTR es:[di]       ;
	add    di,si                  ; si has 79 (0x4F) and stos added one
	add    dx,cx

    mov    al,dh
	and    al,ah                  ; ah has 0x7F (127)
	add    al,bh                  ; bh has the 0 to F offset
	xlat   BYTE PTR ds:[bx]       ;
	xlat   BYTE PTR cs:[bx]       ; before calling this function we already set CS to the correct segment..
	stos   BYTE PTR es:[di]       ;
	add    di,si                  ; si has 79 (0x4F) and stos added one
	add    dx,cx

    mov    al,dh
	and    al,ah                  ; ah has 0x7F (127)
	add    al,bh                  ; bh has the 0 to F offset
	xlat   BYTE PTR ds:[bx]       ;
	xlat   BYTE PTR cs:[bx]       ; before calling this function we already set CS to the correct segment..
	stos   BYTE PTR es:[di]       ;
	add    di,si                  ; si has 79 (0x4F) and stos added one
	add    dx,cx

    mov    al,dh
	and    al,ah                  ; ah has 0x7F (127)
	add    al,bh                  ; bh has the 0 to F offset
	xlat   BYTE PTR ds:[bx]       ;
	xlat   BYTE PTR cs:[bx]       ; before calling this function we already set CS to the correct segment..
	stos   BYTE PTR es:[di]       ;
	add    di,si                  ; si has 79 (0x4F) and stos added one
	add    dx,cx

    mov    al,dh
	and    al,ah                  ; ah has 0x7F (127)
	add    al,bh                  ; bh has the 0 to F offset
	xlat   BYTE PTR ds:[bx]       ;
	xlat   BYTE PTR cs:[bx]       ; before calling this function we already set CS to the correct segment..
	stos   BYTE PTR es:[di]       ;
	add    di,si                  ; si has 79 (0x4F) and stos added one
	add    dx,cx

    mov    al,dh
	and    al,ah                  ; ah has 0x7F (127)
	add    al,bh                  ; bh has the 0 to F offset
	xlat   BYTE PTR ds:[bx]       ;
	xlat   BYTE PTR cs:[bx]       ; before calling this function we already set CS to the correct segment..
	stos   BYTE PTR es:[di]       ;
	add    di,si                  ; si has 79 (0x4F) and stos added one
	add    dx,cx

    mov    al,dh
	and    al,ah                  ; ah has 0x7F (127)
	add    al,bh                  ; bh has the 0 to F offset
	xlat   BYTE PTR ds:[bx]       ;
	xlat   BYTE PTR cs:[bx]       ; before calling this function we already set CS to the correct segment..
	stos   BYTE PTR es:[di]       ;
	add    di,si                  ; si has 79 (0x4F) and stos added one
	add    dx,cx

    mov    al,dh
	and    al,ah                  ; ah has 0x7F (127)
	add    al,bh                  ; bh has the 0 to F offset
	xlat   BYTE PTR ds:[bx]       ;
	xlat   BYTE PTR cs:[bx]       ; before calling this function we already set CS to the correct segment..
	stos   BYTE PTR es:[di]       ;
	add    di,si                  ; si has 79 (0x4F) and stos added one
	add    dx,cx

    mov    al,dh
	and    al,ah                  ; ah has 0x7F (127)
	add    al,bh                  ; bh has the 0 to F offset
	xlat   BYTE PTR ds:[bx]       ;
	xlat   BYTE PTR cs:[bx]       ; before calling this function we already set CS to the correct segment..
	stos   BYTE PTR es:[di]       ;
	add    di,si                  ; si has 79 (0x4F) and stos added one
	add    dx,cx

    mov    al,dh
	and    al,ah                  ; ah has 0x7F (127)
	add    al,bh                  ; bh has the 0 to F offset
	xlat   BYTE PTR ds:[bx]       ;
	xlat   BYTE PTR cs:[bx]       ; before calling this function we already set CS to the correct segment..
	stos   BYTE PTR es:[di]       ;
	add    di,si                  ; si has 79 (0x4F) and stos added one
	add    dx,cx

    mov    al,dh
	and    al,ah                  ; ah has 0x7F (127)
	add    al,bh                  ; bh has the 0 to F offset
	xlat   BYTE PTR ds:[bx]       ;
	xlat   BYTE PTR cs:[bx]       ; before calling this function we already set CS to the correct segment..
	stos   BYTE PTR es:[di]       ;
	add    di,si                  ; si has 79 (0x4F) and stos added one
	add    dx,cx

    mov    al,dh
	and    al,ah                  ; ah has 0x7F (127)
	add    al,bh                  ; bh has the 0 to F offset
	xlat   BYTE PTR ds:[bx]       ;
	xlat   BYTE PTR cs:[bx]       ; before calling this function we already set CS to the correct segment..
	stos   BYTE PTR es:[di]       ;
	add    di,si                  ; si has 79 (0x4F) and stos added one
	add    dx,cx

    mov    al,dh
	and    al,ah                  ; ah has 0x7F (127)
	add    al,bh                  ; bh has the 0 to F offset
	xlat   BYTE PTR ds:[bx]       ;
	xlat   BYTE PTR cs:[bx]       ; before calling this function we already set CS to the correct segment..
	stos   BYTE PTR es:[di]       ;
	add    di,si                  ; si has 79 (0x4F) and stos added one
	add    dx,cx

    mov    al,dh
	and    al,ah                  ; ah has 0x7F (127)
	add    al,bh                  ; bh has the 0 to F offset
	xlat   BYTE PTR ds:[bx]       ;
	xlat   BYTE PTR cs:[bx]       ; before calling this function we already set CS to the correct segment..
	stos   BYTE PTR es:[di]       ;
	add    di,si                  ; si has 79 (0x4F) and stos added one
	add    dx,cx

    mov    al,dh
	and    al,ah                  ; ah has 0x7F (127)
	add    al,bh                  ; bh has the 0 to F offset
	xlat   BYTE PTR ds:[bx]       ;
	xlat   BYTE PTR cs:[bx]       ; before calling this function we already set CS to the correct segment..
	stos   BYTE PTR es:[di]       ;
	add    di,si                  ; si has 79 (0x4F) and stos added one
	add    dx,cx

    mov    al,dh
	and    al,ah                  ; ah has 0x7F (127)
	add    al,bh                  ; bh has the 0 to F offset
	xlat   BYTE PTR ds:[bx]       ;
	xlat   BYTE PTR cs:[bx]       ; before calling this function we already set CS to the correct segment..
	stos   BYTE PTR es:[di]       ;
	add    di,si                  ; si has 79 (0x4F) and stos added one
	add    dx,cx

    mov    al,dh
	and    al,ah                  ; ah has 0x7F (127)
	add    al,bh                  ; bh has the 0 to F offset
	xlat   BYTE PTR ds:[bx]       ;
	xlat   BYTE PTR cs:[bx]       ; before calling this function we already set CS to the correct segment..
	stos   BYTE PTR es:[di]       ;
	add    di,si                  ; si has 79 (0x4F) and stos added one
	add    dx,cx

    mov    al,dh
	and    al,ah                  ; ah has 0x7F (127)
	add    al,bh                  ; bh has the 0 to F offset
	xlat   BYTE PTR ds:[bx]       ;
	xlat   BYTE PTR cs:[bx]       ; before calling this function we already set CS to the correct segment..
	stos   BYTE PTR es:[di]       ;
	add    di,si                  ; si has 79 (0x4F) and stos added one
	add    dx,cx

    mov    al,dh
	and    al,ah                  ; ah has 0x7F (127)
	add    al,bh                  ; bh has the 0 to F offset
	xlat   BYTE PTR ds:[bx]       ;
	xlat   BYTE PTR cs:[bx]       ; before calling this function we already set CS to the correct segment..
	stos   BYTE PTR es:[di]       ;
	add    di,si                  ; si has 79 (0x4F) and stos added one
	add    dx,cx

    mov    al,dh
	and    al,ah                  ; ah has 0x7F (127)
	add    al,bh                  ; bh has the 0 to F offset
	xlat   BYTE PTR ds:[bx]       ;
	xlat   BYTE PTR cs:[bx]       ; before calling this function we already set CS to the correct segment..
	stos   BYTE PTR es:[di]       ;
	add    di,si                  ; si has 79 (0x4F) and stos added one
	add    dx,cx

    mov    al,dh
	and    al,ah                  ; ah has 0x7F (127)
	add    al,bh                  ; bh has the 0 to F offset
	xlat   BYTE PTR ds:[bx]       ;
	xlat   BYTE PTR cs:[bx]       ; before calling this function we already set CS to the correct segment..
	stos   BYTE PTR es:[di]       ;
	add    di,si                  ; si has 79 (0x4F) and stos added one
	add    dx,cx

    mov    al,dh
	and    al,ah                  ; ah has 0x7F (127)
	add    al,bh                  ; bh has the 0 to F offset
	xlat   BYTE PTR ds:[bx]       ;
	xlat   BYTE PTR cs:[bx]       ; before calling this function we already set CS to the correct segment..
	stos   BYTE PTR es:[di]       ;
	add    di,si                  ; si has 79 (0x4F) and stos added one
	add    dx,cx

    mov    al,dh
	and    al,ah                  ; ah has 0x7F (127)
	add    al,bh                  ; bh has the 0 to F offset
	xlat   BYTE PTR ds:[bx]       ;
	xlat   BYTE PTR cs:[bx]       ; before calling this function we already set CS to the correct segment..
	stos   BYTE PTR es:[di]       ;
	add    di,si                  ; si has 79 (0x4F) and stos added one
	add    dx,cx

    mov    al,dh
	and    al,ah                  ; ah has 0x7F (127)
	add    al,bh                  ; bh has the 0 to F offset
	xlat   BYTE PTR ds:[bx]       ;
	xlat   BYTE PTR cs:[bx]       ; before calling this function we already set CS to the correct segment..
	stos   BYTE PTR es:[di]       ;
	add    di,si                  ; si has 79 (0x4F) and stos added one
	add    dx,cx

    mov    al,dh
	and    al,ah                  ; ah has 0x7F (127)
	add    al,bh                  ; bh has the 0 to F offset
	xlat   BYTE PTR ds:[bx]       ;
	xlat   BYTE PTR cs:[bx]       ; before calling this function we already set CS to the correct segment..
	stos   BYTE PTR es:[di]       ;
	add    di,si                  ; si has 79 (0x4F) and stos added one
	add    dx,cx

    mov    al,dh
	and    al,ah                  ; ah has 0x7F (127)
	add    al,bh                  ; bh has the 0 to F offset
	xlat   BYTE PTR ds:[bx]       ;
	xlat   BYTE PTR cs:[bx]       ; before calling this function we already set CS to the correct segment..
	stos   BYTE PTR es:[di]       ;
	add    di,si                  ; si has 79 (0x4F) and stos added one
	add    dx,cx

    mov    al,dh
	and    al,ah                  ; ah has 0x7F (127)
	add    al,bh                  ; bh has the 0 to F offset
	xlat   BYTE PTR ds:[bx]       ;
	xlat   BYTE PTR cs:[bx]       ; before calling this function we already set CS to the correct segment..
	stos   BYTE PTR es:[di]       ;
	add    di,si                  ; si has 79 (0x4F) and stos added one
	add    dx,cx

    mov    al,dh
	and    al,ah                  ; ah has 0x7F (127)
	add    al,bh                  ; bh has the 0 to F offset
	xlat   BYTE PTR ds:[bx]       ;
	xlat   BYTE PTR cs:[bx]       ; before calling this function we already set CS to the correct segment..
	stos   BYTE PTR es:[di]       ;
	add    di,si                  ; si has 79 (0x4F) and stos added one
	add    dx,cx

    mov    al,dh
	and    al,ah                  ; ah has 0x7F (127)
	add    al,bh                  ; bh has the 0 to F offset
	xlat   BYTE PTR ds:[bx]       ;
	xlat   BYTE PTR cs:[bx]       ; before calling this function we already set CS to the correct segment..
	stos   BYTE PTR es:[di]       ;
	add    di,si                  ; si has 79 (0x4F) and stos added one
	add    dx,cx

    mov    al,dh
	and    al,ah                  ; ah has 0x7F (127)
	add    al,bh                  ; bh has the 0 to F offset
	xlat   BYTE PTR ds:[bx]       ;
	xlat   BYTE PTR cs:[bx]       ; before calling this function we already set CS to the correct segment..
	stos   BYTE PTR es:[di]       ;
	add    di,si                  ; si has 79 (0x4F) and stos added one
	add    dx,cx

    mov    al,dh
	and    al,ah                  ; ah has 0x7F (127)
	add    al,bh                  ; bh has the 0 to F offset
	xlat   BYTE PTR ds:[bx]       ;
	xlat   BYTE PTR cs:[bx]       ; before calling this function we already set CS to the correct segment..
	stos   BYTE PTR es:[di]       ;
	add    di,si                  ; si has 79 (0x4F) and stos added one
	add    dx,cx

    mov    al,dh
	and    al,ah                  ; ah has 0x7F (127)
	add    al,bh                  ; bh has the 0 to F offset
	xlat   BYTE PTR ds:[bx]       ;
	xlat   BYTE PTR cs:[bx]       ; before calling this function we already set CS to the correct segment..
	stos   BYTE PTR es:[di]       ;
	add    di,si                  ; si has 79 (0x4F) and stos added one
	add    dx,cx

    mov    al,dh
	and    al,ah                  ; ah has 0x7F (127)
	add    al,bh                  ; bh has the 0 to F offset
	xlat   BYTE PTR ds:[bx]       ;
	xlat   BYTE PTR cs:[bx]       ; before calling this function we already set CS to the correct segment..
	stos   BYTE PTR es:[di]       ;
	add    di,si                  ; si has 79 (0x4F) and stos added one
	add    dx,cx

    mov    al,dh
	and    al,ah                  ; ah has 0x7F (127)
	add    al,bh                  ; bh has the 0 to F offset
	xlat   BYTE PTR ds:[bx]       ;
	xlat   BYTE PTR cs:[bx]       ; before calling this function we already set CS to the correct segment..
	stos   BYTE PTR es:[di]       ;
	add    di,si                  ; si has 79 (0x4F) and stos added one
	add    dx,cx

    mov    al,dh
	and    al,ah                  ; ah has 0x7F (127)
	add    al,bh                  ; bh has the 0 to F offset
	xlat   BYTE PTR ds:[bx]       ;
	xlat   BYTE PTR cs:[bx]       ; before calling this function we already set CS to the correct segment..
	stos   BYTE PTR es:[di]       ;
	add    di,si                  ; si has 79 (0x4F) and stos added one
	add    dx,cx

    mov    al,dh
	and    al,ah                  ; ah has 0x7F (127)
	add    al,bh                  ; bh has the 0 to F offset
	xlat   BYTE PTR ds:[bx]       ;
	xlat   BYTE PTR cs:[bx]       ; before calling this function we already set CS to the correct segment..
	stos   BYTE PTR es:[di]       ;
	add    di,si                  ; si has 79 (0x4F) and stos added one
	add    dx,cx

    mov    al,dh
	and    al,ah                  ; ah has 0x7F (127)
	add    al,bh                  ; bh has the 0 to F offset
	xlat   BYTE PTR ds:[bx]       ;
	xlat   BYTE PTR cs:[bx]       ; before calling this function we already set CS to the correct segment..
	stos   BYTE PTR es:[di]       ;
	add    di,si                  ; si has 79 (0x4F) and stos added one
	add    dx,cx

    mov    al,dh
	and    al,ah                  ; ah has 0x7F (127)
	add    al,bh                  ; bh has the 0 to F offset
	xlat   BYTE PTR ds:[bx]       ;
	xlat   BYTE PTR cs:[bx]       ; before calling this function we already set CS to the correct segment..
	stos   BYTE PTR es:[di]       ;
	add    di,si                  ; si has 79 (0x4F) and stos added one
	add    dx,cx

    mov    al,dh
	and    al,ah                  ; ah has 0x7F (127)
	add    al,bh                  ; bh has the 0 to F offset
	xlat   BYTE PTR ds:[bx]       ;
	xlat   BYTE PTR cs:[bx]       ; before calling this function we already set CS to the correct segment..
	stos   BYTE PTR es:[di]       ;
	add    di,si                  ; si has 79 (0x4F) and stos added one
	add    dx,cx

    mov    al,dh
	and    al,ah                  ; ah has 0x7F (127)
	add    al,bh                  ; bh has the 0 to F offset
	xlat   BYTE PTR ds:[bx]       ;
	xlat   BYTE PTR cs:[bx]       ; before calling this function we already set CS to the correct segment..
	stos   BYTE PTR es:[di]       ;
	add    di,si                  ; si has 79 (0x4F) and stos added one
	add    dx,cx

    mov    al,dh
	and    al,ah                  ; ah has 0x7F (127)
	add    al,bh                  ; bh has the 0 to F offset
	xlat   BYTE PTR ds:[bx]       ;
	xlat   BYTE PTR cs:[bx]       ; before calling this function we already set CS to the correct segment..
	stos   BYTE PTR es:[di]       ;
	add    di,si                  ; si has 79 (0x4F) and stos added one
	add    dx,cx

    mov    al,dh
	and    al,ah                  ; ah has 0x7F (127)
	add    al,bh                  ; bh has the 0 to F offset
	xlat   BYTE PTR ds:[bx]       ;
	xlat   BYTE PTR cs:[bx]       ; before calling this function we already set CS to the correct segment..
	stos   BYTE PTR es:[di]       ;
	add    di,si                  ; si has 79 (0x4F) and stos added one
	add    dx,cx

    mov    al,dh
	and    al,ah                  ; ah has 0x7F (127)
	add    al,bh                  ; bh has the 0 to F offset
	xlat   BYTE PTR ds:[bx]       ;
	xlat   BYTE PTR cs:[bx]       ; before calling this function we already set CS to the correct segment..
	stos   BYTE PTR es:[di]       ;
	add    di,si                  ; si has 79 (0x4F) and stos added one
	add    dx,cx

    mov    al,dh
	and    al,ah                  ; ah has 0x7F (127)
	add    al,bh                  ; bh has the 0 to F offset
	xlat   BYTE PTR ds:[bx]       ;
	xlat   BYTE PTR cs:[bx]       ; before calling this function we already set CS to the correct segment..
	stos   BYTE PTR es:[di]       ;
	add    di,si                  ; si has 79 (0x4F) and stos added one
	add    dx,cx

    mov    al,dh
	and    al,ah                  ; ah has 0x7F (127)
	add    al,bh                  ; bh has the 0 to F offset
	xlat   BYTE PTR ds:[bx]       ;
	xlat   BYTE PTR cs:[bx]       ; before calling this function we already set CS to the correct segment..
	stos   BYTE PTR es:[di]       ;
	add    di,si                  ; si has 79 (0x4F) and stos added one
	add    dx,cx

    mov    al,dh
	and    al,ah                  ; ah has 0x7F (127)
	add    al,bh                  ; bh has the 0 to F offset
	xlat   BYTE PTR ds:[bx]       ;
	xlat   BYTE PTR cs:[bx]       ; before calling this function we already set CS to the correct segment..
	stos   BYTE PTR es:[di]       ;
	add    di,si                  ; si has 79 (0x4F) and stos added one
	add    dx,cx

    mov    al,dh
	and    al,ah                  ; ah has 0x7F (127)
	add    al,bh                  ; bh has the 0 to F offset
	xlat   BYTE PTR ds:[bx]       ;
	xlat   BYTE PTR cs:[bx]       ; before calling this function we already set CS to the correct segment..
	stos   BYTE PTR es:[di]       ;
	add    di,si                  ; si has 79 (0x4F) and stos added one
	add    dx,cx

    mov    al,dh
	and    al,ah                  ; ah has 0x7F (127)
	add    al,bh                  ; bh has the 0 to F offset
	xlat   BYTE PTR ds:[bx]       ;
	xlat   BYTE PTR cs:[bx]       ; before calling this function we already set CS to the correct segment..
	stos   BYTE PTR es:[di]       ;
	add    di,si                  ; si has 79 (0x4F) and stos added one
	add    dx,cx

    mov    al,dh
	and    al,ah                  ; ah has 0x7F (127)
	add    al,bh                  ; bh has the 0 to F offset
	xlat   BYTE PTR ds:[bx]       ;
	xlat   BYTE PTR cs:[bx]       ; before calling this function we already set CS to the correct segment..
	stos   BYTE PTR es:[di]       ;
	add    di,si                  ; si has 79 (0x4F) and stos added one
	add    dx,cx

    mov    al,dh
	and    al,ah                  ; ah has 0x7F (127)
	add    al,bh                  ; bh has the 0 to F offset
	xlat   BYTE PTR ds:[bx]       ;
	xlat   BYTE PTR cs:[bx]       ; before calling this function we already set CS to the correct segment..
	stos   BYTE PTR es:[di]       ;
	add    di,si                  ; si has 79 (0x4F) and stos added one
	add    dx,cx

    mov    al,dh
	and    al,ah                  ; ah has 0x7F (127)
	add    al,bh                  ; bh has the 0 to F offset
	xlat   BYTE PTR ds:[bx]       ;
	xlat   BYTE PTR cs:[bx]       ; before calling this function we already set CS to the correct segment..
	stos   BYTE PTR es:[di]       ;
	add    di,si                  ; si has 79 (0x4F) and stos added one
	add    dx,cx

    mov    al,dh
	and    al,ah                  ; ah has 0x7F (127)
	add    al,bh                  ; bh has the 0 to F offset
	xlat   BYTE PTR ds:[bx]       ;
	xlat   BYTE PTR cs:[bx]       ; before calling this function we already set CS to the correct segment..
	stos   BYTE PTR es:[di]       ;
	add    di,si                  ; si has 79 (0x4F) and stos added one
	add    dx,cx

    mov    al,dh
	and    al,ah                  ; ah has 0x7F (127)
	add    al,bh                  ; bh has the 0 to F offset
	xlat   BYTE PTR ds:[bx]       ;
	xlat   BYTE PTR cs:[bx]       ; before calling this function we already set CS to the correct segment..
	stos   BYTE PTR es:[di]       ;
	add    di,si                  ; si has 79 (0x4F) and stos added one
	add    dx,cx

    mov    al,dh
	and    al,ah                  ; ah has 0x7F (127)
	add    al,bh                  ; bh has the 0 to F offset
	xlat   BYTE PTR ds:[bx]       ;
	xlat   BYTE PTR cs:[bx]       ; before calling this function we already set CS to the correct segment..
	stos   BYTE PTR es:[di]       ;
	add    di,si                  ; si has 79 (0x4F) and stos added one
	add    dx,cx

    mov    al,dh
	and    al,ah                  ; ah has 0x7F (127)
	add    al,bh                  ; bh has the 0 to F offset
	xlat   BYTE PTR ds:[bx]       ;
	xlat   BYTE PTR cs:[bx]       ; before calling this function we already set CS to the correct segment..
	stos   BYTE PTR es:[di]       ;
	add    di,si                  ; si has 79 (0x4F) and stos added one
	add    dx,cx

    mov    al,dh
	and    al,ah                  ; ah has 0x7F (127)
	add    al,bh                  ; bh has the 0 to F offset
	xlat   BYTE PTR ds:[bx]       ;
	xlat   BYTE PTR cs:[bx]       ; before calling this function we already set CS to the correct segment..
	stos   BYTE PTR es:[di]       ;
	add    di,si                  ; si has 79 (0x4F) and stos added one
	add    dx,cx

    mov    al,dh
	and    al,ah                  ; ah has 0x7F (127)
	add    al,bh                  ; bh has the 0 to F offset
	xlat   BYTE PTR ds:[bx]       ;
	xlat   BYTE PTR cs:[bx]       ; before calling this function we already set CS to the correct segment..
	stos   BYTE PTR es:[di]       ;
	add    di,si                  ; si has 79 (0x4F) and stos added one
	add    dx,cx

    mov    al,dh
	and    al,ah                  ; ah has 0x7F (127)
	add    al,bh                  ; bh has the 0 to F offset
	xlat   BYTE PTR ds:[bx]       ;
	xlat   BYTE PTR cs:[bx]       ; before calling this function we already set CS to the correct segment..
	stos   BYTE PTR es:[di]       ;
	add    di,si                  ; si has 79 (0x4F) and stos added one
	add    dx,cx

    mov    al,dh
	and    al,ah                  ; ah has 0x7F (127)
	add    al,bh                  ; bh has the 0 to F offset
	xlat   BYTE PTR ds:[bx]       ;
	xlat   BYTE PTR cs:[bx]       ; before calling this function we already set CS to the correct segment..
	stos   BYTE PTR es:[di]       ;
	add    di,si                  ; si has 79 (0x4F) and stos added one
	add    dx,cx

    mov    al,dh
	and    al,ah                  ; ah has 0x7F (127)
	add    al,bh                  ; bh has the 0 to F offset
	xlat   BYTE PTR ds:[bx]       ;
	xlat   BYTE PTR cs:[bx]       ; before calling this function we already set CS to the correct segment..
	stos   BYTE PTR es:[di]       ;
	add    di,si                  ; si has 79 (0x4F) and stos added one
	add    dx,cx

    mov    al,dh
	and    al,ah                  ; ah has 0x7F (127)
	add    al,bh                  ; bh has the 0 to F offset
	xlat   BYTE PTR ds:[bx]       ;
	xlat   BYTE PTR cs:[bx]       ; before calling this function we already set CS to the correct segment..
	stos   BYTE PTR es:[di]       ;
	add    di,si                  ; si has 79 (0x4F) and stos added one
	add    dx,cx

    mov    al,dh
	and    al,ah                  ; ah has 0x7F (127)
	add    al,bh                  ; bh has the 0 to F offset
	xlat   BYTE PTR ds:[bx]       ;
	xlat   BYTE PTR cs:[bx]       ; before calling this function we already set CS to the correct segment..
	stos   BYTE PTR es:[di]       ;
	add    di,si                  ; si has 79 (0x4F) and stos added one
	add    dx,cx

    mov    al,dh
	and    al,ah                  ; ah has 0x7F (127)
	add    al,bh                  ; bh has the 0 to F offset
	xlat   BYTE PTR ds:[bx]       ;
	xlat   BYTE PTR cs:[bx]       ; before calling this function we already set CS to the correct segment..
	stos   BYTE PTR es:[di]       ;
	add    di,si                  ; si has 79 (0x4F) and stos added one
	add    dx,cx

    mov    al,dh
	and    al,ah                  ; ah has 0x7F (127)
	add    al,bh                  ; bh has the 0 to F offset
	xlat   BYTE PTR ds:[bx]       ;
	xlat   BYTE PTR cs:[bx]       ; before calling this function we already set CS to the correct segment..
	stos   BYTE PTR es:[di]       ;
	add    di,si                  ; si has 79 (0x4F) and stos added one
	add    dx,cx

    mov    al,dh
	and    al,ah                  ; ah has 0x7F (127)
	add    al,bh                  ; bh has the 0 to F offset
	xlat   BYTE PTR ds:[bx]       ;
	xlat   BYTE PTR cs:[bx]       ; before calling this function we already set CS to the correct segment..
	stos   BYTE PTR es:[di]       ;
	add    di,si                  ; si has 79 (0x4F) and stos added one
	add    dx,cx

    mov    al,dh
	and    al,ah                  ; ah has 0x7F (127)
	add    al,bh                  ; bh has the 0 to F offset
	xlat   BYTE PTR ds:[bx]       ;
	xlat   BYTE PTR cs:[bx]       ; before calling this function we already set CS to the correct segment..
	stos   BYTE PTR es:[di]       ;
	add    di,si                  ; si has 79 (0x4F) and stos added one
	add    dx,cx

    mov    al,dh
	and    al,ah                  ; ah has 0x7F (127)
	add    al,bh                  ; bh has the 0 to F offset
	xlat   BYTE PTR ds:[bx]       ;
	xlat   BYTE PTR cs:[bx]       ; before calling this function we already set CS to the correct segment..
	stos   BYTE PTR es:[di]       ;
	add    di,si                  ; si has 79 (0x4F) and stos added one
	add    dx,cx

    mov    al,dh
	and    al,ah                  ; ah has 0x7F (127)
	add    al,bh                  ; bh has the 0 to F offset
	xlat   BYTE PTR ds:[bx]       ;
	xlat   BYTE PTR cs:[bx]       ; before calling this function we already set CS to the correct segment..
	stos   BYTE PTR es:[di]       ;
	add    di,si                  ; si has 79 (0x4F) and stos added one
	add    dx,cx

    mov    al,dh
	and    al,ah                  ; ah has 0x7F (127)
	add    al,bh                  ; bh has the 0 to F offset
	xlat   BYTE PTR ds:[bx]       ;
	xlat   BYTE PTR cs:[bx]       ; before calling this function we already set CS to the correct segment..
	stos   BYTE PTR es:[di]       ;
	add    di,si                  ; si has 79 (0x4F) and stos added one
	add    dx,cx

    mov    al,dh
	and    al,ah                  ; ah has 0x7F (127)
	add    al,bh                  ; bh has the 0 to F offset
	xlat   BYTE PTR ds:[bx]       ;
	xlat   BYTE PTR cs:[bx]       ; before calling this function we already set CS to the correct segment..
	stos   BYTE PTR es:[di]       ;
	add    di,si                  ; si has 79 (0x4F) and stos added one
	add    dx,cx

    mov    al,dh
	and    al,ah                  ; ah has 0x7F (127)
	add    al,bh                  ; bh has the 0 to F offset
	xlat   BYTE PTR ds:[bx]       ;
	xlat   BYTE PTR cs:[bx]       ; before calling this function we already set CS to the correct segment..
	stos   BYTE PTR es:[di]       ;
	add    di,si                  ; si has 79 (0x4F) and stos added one
	add    dx,cx

    mov    al,dh
	and    al,ah                  ; ah has 0x7F (127)
	add    al,bh                  ; bh has the 0 to F offset
	xlat   BYTE PTR ds:[bx]       ;
	xlat   BYTE PTR cs:[bx]       ; before calling this function we already set CS to the correct segment..
	stos   BYTE PTR es:[di]       ;
	add    di,si                  ; si has 79 (0x4F) and stos added one
	add    dx,cx

    mov    al,dh
	and    al,ah                  ; ah has 0x7F (127)
	add    al,bh                  ; bh has the 0 to F offset
	xlat   BYTE PTR ds:[bx]       ;
	xlat   BYTE PTR cs:[bx]       ; before calling this function we already set CS to the correct segment..
	stos   BYTE PTR es:[di]       ;
	add    di,si                  ; si has 79 (0x4F) and stos added one
	add    dx,cx

    mov    al,dh
	and    al,ah                  ; ah has 0x7F (127)
	add    al,bh                  ; bh has the 0 to F offset
	xlat   BYTE PTR ds:[bx]       ;
	xlat   BYTE PTR cs:[bx]       ; before calling this function we already set CS to the correct segment..
	stos   BYTE PTR es:[di]       ;
	add    di,si                  ; si has 79 (0x4F) and stos added one
	add    dx,cx

    mov    al,dh
	and    al,ah                  ; ah has 0x7F (127)
	add    al,bh                  ; bh has the 0 to F offset
	xlat   BYTE PTR ds:[bx]       ;
	xlat   BYTE PTR cs:[bx]       ; before calling this function we already set CS to the correct segment..
	stos   BYTE PTR es:[di]       ;
	add    di,si                  ; si has 79 (0x4F) and stos added one
	add    dx,cx

    mov    al,dh
	and    al,ah                  ; ah has 0x7F (127)
	add    al,bh                  ; bh has the 0 to F offset
	xlat   BYTE PTR ds:[bx]       ;
	xlat   BYTE PTR cs:[bx]       ; before calling this function we already set CS to the correct segment..
	stos   BYTE PTR es:[di]       ;
	add    di,si                  ; si has 79 (0x4F) and stos added one
	add    dx,cx

    mov    al,dh
	and    al,ah                  ; ah has 0x7F (127)
	add    al,bh                  ; bh has the 0 to F offset
	xlat   BYTE PTR ds:[bx]       ;
	xlat   BYTE PTR cs:[bx]       ; before calling this function we already set CS to the correct segment..
	stos   BYTE PTR es:[di]       ;
	add    di,si                  ; si has 79 (0x4F) and stos added one
	add    dx,cx

    mov    al,dh
	and    al,ah                  ; ah has 0x7F (127)
	add    al,bh                  ; bh has the 0 to F offset
	xlat   BYTE PTR ds:[bx]       ;
	xlat   BYTE PTR cs:[bx]       ; before calling this function we already set CS to the correct segment..
	stos   BYTE PTR es:[di]       ;
	add    di,si                  ; si has 79 (0x4F) and stos added one
	add    dx,cx

    mov    al,dh
	and    al,ah                  ; ah has 0x7F (127)
	add    al,bh                  ; bh has the 0 to F offset
	xlat   BYTE PTR ds:[bx]       ;
	xlat   BYTE PTR cs:[bx]       ; before calling this function we already set CS to the correct segment..
	stos   BYTE PTR es:[di]       ;
	add    di,si                  ; si has 79 (0x4F) and stos added one
	add    dx,cx

    mov    al,dh
	and    al,ah                  ; ah has 0x7F (127)
	add    al,bh                  ; bh has the 0 to F offset
	xlat   BYTE PTR ds:[bx]       ;
	xlat   BYTE PTR cs:[bx]       ; before calling this function we already set CS to the correct segment..
	stos   BYTE PTR es:[di]       ;
	add    di,si                  ; si has 79 (0x4F) and stos added one
	add    dx,cx

    mov    al,dh
	and    al,ah                  ; ah has 0x7F (127)
	add    al,bh                  ; bh has the 0 to F offset
	xlat   BYTE PTR ds:[bx]       ;
	xlat   BYTE PTR cs:[bx]       ; before calling this function we already set CS to the correct segment..
	stos   BYTE PTR es:[di]       ;
	add    di,si                  ; si has 79 (0x4F) and stos added one
	add    dx,cx

    mov    al,dh
	and    al,ah                  ; ah has 0x7F (127)
	add    al,bh                  ; bh has the 0 to F offset
	xlat   BYTE PTR ds:[bx]       ;
	xlat   BYTE PTR cs:[bx]       ; before calling this function we already set CS to the correct segment..
	stos   BYTE PTR es:[di]       ;
	add    di,si                  ; si has 79 (0x4F) and stos added one
	add    dx,cx

    mov    al,dh
	and    al,ah                  ; ah has 0x7F (127)
	add    al,bh                  ; bh has the 0 to F offset
	xlat   BYTE PTR ds:[bx]       ;
	xlat   BYTE PTR cs:[bx]       ; before calling this function we already set CS to the correct segment..
	stos   BYTE PTR es:[di]       ;
	add    di,si                  ; si has 79 (0x4F) and stos added one
	add    dx,cx

    mov    al,dh
	and    al,ah                  ; ah has 0x7F (127)
	add    al,bh                  ; bh has the 0 to F offset
	xlat   BYTE PTR ds:[bx]       ;
	xlat   BYTE PTR cs:[bx]       ; before calling this function we already set CS to the correct segment..
	stos   BYTE PTR es:[di]       ;
	add    di,si                  ; si has 79 (0x4F) and stos added one
	add    dx,cx

    mov    al,dh
	and    al,ah                  ; ah has 0x7F (127)
	add    al,bh                  ; bh has the 0 to F offset
	xlat   BYTE PTR ds:[bx]       ;
	xlat   BYTE PTR cs:[bx]       ; before calling this function we already set CS to the correct segment..
	stos   BYTE PTR es:[di]       ;
	add    di,si                  ; si has 79 (0x4F) and stos added one
	add    dx,cx

    mov    al,dh
	and    al,ah                  ; ah has 0x7F (127)
	add    al,bh                  ; bh has the 0 to F offset
	xlat   BYTE PTR ds:[bx]       ;
	xlat   BYTE PTR cs:[bx]       ; before calling this function we already set CS to the correct segment..
	stos   BYTE PTR es:[di]       ;
	add    di,si                  ; si has 79 (0x4F) and stos added one
	add    dx,cx

    mov    al,dh
	and    al,ah                  ; ah has 0x7F (127)
	add    al,bh                  ; bh has the 0 to F offset
	xlat   BYTE PTR ds:[bx]       ;
	xlat   BYTE PTR cs:[bx]       ; before calling this function we already set CS to the correct segment..
	stos   BYTE PTR es:[di]       ;
	add    di,si                  ; si has 79 (0x4F) and stos added one
	add    dx,cx

    mov    al,dh
	and    al,ah                  ; ah has 0x7F (127)
	add    al,bh                  ; bh has the 0 to F offset
	xlat   BYTE PTR ds:[bx]       ;
	xlat   BYTE PTR cs:[bx]       ; before calling this function we already set CS to the correct segment..
	stos   BYTE PTR es:[di]       ;
	add    di,si                  ; si has 79 (0x4F) and stos added one
	add    dx,cx

    mov    al,dh
	and    al,ah                  ; ah has 0x7F (127)
	add    al,bh                  ; bh has the 0 to F offset
	xlat   BYTE PTR ds:[bx]       ;
	xlat   BYTE PTR cs:[bx]       ; before calling this function we already set CS to the correct segment..
	stos   BYTE PTR es:[di]       ;
	add    di,si                  ; si has 79 (0x4F) and stos added one
	add    dx,cx

    mov    al,dh
	and    al,ah                  ; ah has 0x7F (127)
	add    al,bh                  ; bh has the 0 to F offset
	xlat   BYTE PTR ds:[bx]       ;
	xlat   BYTE PTR cs:[bx]       ; before calling this function we already set CS to the correct segment..
	stos   BYTE PTR es:[di]       ;
	add    di,si                  ; si has 79 (0x4F) and stos added one
	add    dx,cx

    mov    al,dh
	and    al,ah                  ; ah has 0x7F (127)
	add    al,bh                  ; bh has the 0 to F offset
	xlat   BYTE PTR ds:[bx]       ;
	xlat   BYTE PTR cs:[bx]       ; before calling this function we already set CS to the correct segment..
	stos   BYTE PTR es:[di]       ;
	add    di,si                  ; si has 79 (0x4F) and stos added one
	add    dx,cx

    mov    al,dh
	and    al,ah                  ; ah has 0x7F (127)
	add    al,bh                  ; bh has the 0 to F offset
	xlat   BYTE PTR ds:[bx]       ;
	xlat   BYTE PTR cs:[bx]       ; before calling this function we already set CS to the correct segment..
	stos   BYTE PTR es:[di]       ;
	add    di,si                  ; si has 79 (0x4F) and stos added one
	add    dx,cx

    mov    al,dh
	and    al,ah                  ; ah has 0x7F (127)
	add    al,bh                  ; bh has the 0 to F offset
	xlat   BYTE PTR ds:[bx]       ;
	xlat   BYTE PTR cs:[bx]       ; before calling this function we already set CS to the correct segment..
	stos   BYTE PTR es:[di]       ;
	add    di,si                  ; si has 79 (0x4F) and stos added one
	add    dx,cx

    mov    al,dh
	and    al,ah                  ; ah has 0x7F (127)
	add    al,bh                  ; bh has the 0 to F offset
	xlat   BYTE PTR ds:[bx]       ;
	xlat   BYTE PTR cs:[bx]       ; before calling this function we already set CS to the correct segment..
	stos   BYTE PTR es:[di]       ;
	add    di,si                  ; si has 79 (0x4F) and stos added one
	add    dx,cx

    mov    al,dh
	and    al,ah                  ; ah has 0x7F (127)
	add    al,bh                  ; bh has the 0 to F offset
	xlat   BYTE PTR ds:[bx]       ;
	xlat   BYTE PTR cs:[bx]       ; before calling this function we already set CS to the correct segment..
	stos   BYTE PTR es:[di]       ;
	add    di,si                  ; si has 79 (0x4F) and stos added one
	add    dx,cx

    mov    al,dh
	and    al,ah                  ; ah has 0x7F (127)
	add    al,bh                  ; bh has the 0 to F offset
	xlat   BYTE PTR ds:[bx]       ;
	xlat   BYTE PTR cs:[bx]       ; before calling this function we already set CS to the correct segment..
	stos   BYTE PTR es:[di]       ;
	add    di,si                  ; si has 79 (0x4F) and stos added one
	add    dx,cx

    mov    al,dh
	and    al,ah                  ; ah has 0x7F (127)
	add    al,bh                  ; bh has the 0 to F offset
	xlat   BYTE PTR ds:[bx]       ;
	xlat   BYTE PTR cs:[bx]       ; before calling this function we already set CS to the correct segment..
	stos   BYTE PTR es:[di]       ;
	add    di,si                  ; si has 79 (0x4F) and stos added one
	add    dx,cx

    mov    al,dh
	and    al,ah                  ; ah has 0x7F (127)
	add    al,bh                  ; bh has the 0 to F offset
	xlat   BYTE PTR ds:[bx]       ;
	xlat   BYTE PTR cs:[bx]       ; before calling this function we already set CS to the correct segment..
	stos   BYTE PTR es:[di]       ;
	add    di,si                  ; si has 79 (0x4F) and stos added one
	add    dx,cx

    mov    al,dh
	and    al,ah                  ; ah has 0x7F (127)
	add    al,bh                  ; bh has the 0 to F offset
	xlat   BYTE PTR ds:[bx]       ;
	xlat   BYTE PTR cs:[bx]       ; before calling this function we already set CS to the correct segment..
	stos   BYTE PTR es:[di]       ;
	add    di,si                  ; si has 79 (0x4F) and stos added one
	add    dx,cx

    mov    al,dh
	and    al,ah                  ; ah has 0x7F (127)
	add    al,bh                  ; bh has the 0 to F offset
	xlat   BYTE PTR ds:[bx]       ;
	xlat   BYTE PTR cs:[bx]       ; before calling this function we already set CS to the correct segment..
	stos   BYTE PTR es:[di]       ;
	add    di,si                  ; si has 79 (0x4F) and stos added one
	add    dx,cx

    mov    al,dh
	and    al,ah                  ; ah has 0x7F (127)
	add    al,bh                  ; bh has the 0 to F offset
	xlat   BYTE PTR ds:[bx]       ;
	xlat   BYTE PTR cs:[bx]       ; before calling this function we already set CS to the correct segment..
	stos   BYTE PTR es:[di]       ;
	add    di,si                  ; si has 79 (0x4F) and stos added one
	add    dx,cx

    mov    al,dh
	and    al,ah                  ; ah has 0x7F (127)
	add    al,bh                  ; bh has the 0 to F offset
	xlat   BYTE PTR ds:[bx]       ;
	xlat   BYTE PTR cs:[bx]       ; before calling this function we already set CS to the correct segment..
	stos   BYTE PTR es:[di]       ;
	add    di,si                  ; si has 79 (0x4F) and stos added one
	add    dx,cx

    mov    al,dh
	and    al,ah                  ; ah has 0x7F (127)
	add    al,bh                  ; bh has the 0 to F offset
	xlat   BYTE PTR ds:[bx]       ;
	xlat   BYTE PTR cs:[bx]       ; before calling this function we already set CS to the correct segment..
	stos   BYTE PTR es:[di]       ;
	add    di,si                  ; si has 79 (0x4F) and stos added one
	add    dx,cx

    mov    al,dh
	and    al,ah                  ; ah has 0x7F (127)
	add    al,bh                  ; bh has the 0 to F offset
	xlat   BYTE PTR ds:[bx]       ;
	xlat   BYTE PTR cs:[bx]       ; before calling this function we already set CS to the correct segment..
	stos   BYTE PTR es:[di]       ;
	add    di,si                  ; si has 79 (0x4F) and stos added one
	add    dx,cx

    mov    al,dh
	and    al,ah                  ; ah has 0x7F (127)
	add    al,bh                  ; bh has the 0 to F offset
	xlat   BYTE PTR ds:[bx]       ;
	xlat   BYTE PTR cs:[bx]       ; before calling this function we already set CS to the correct segment..
	stos   BYTE PTR es:[di]       ;
	add    di,si                  ; si has 79 (0x4F) and stos added one
	add    dx,cx

    mov    al,dh
	and    al,ah                  ; ah has 0x7F (127)
	add    al,bh                  ; bh has the 0 to F offset
	xlat   BYTE PTR ds:[bx]       ;
	xlat   BYTE PTR cs:[bx]       ; before calling this function we already set CS to the correct segment..
	stos   BYTE PTR es:[di]       ;
	add    di,si                  ; si has 79 (0x4F) and stos added one
	add    dx,cx

    mov    al,dh
	and    al,ah                  ; ah has 0x7F (127)
	add    al,bh                  ; bh has the 0 to F offset
	xlat   BYTE PTR ds:[bx]       ;
	xlat   BYTE PTR cs:[bx]       ; before calling this function we already set CS to the correct segment..
	stos   BYTE PTR es:[di]       ;
	add    di,si                  ; si has 79 (0x4F) and stos added one
	add    dx,cx

    mov    al,dh
	and    al,ah                  ; ah has 0x7F (127)
	add    al,bh                  ; bh has the 0 to F offset
	xlat   BYTE PTR ds:[bx]       ;
	xlat   BYTE PTR cs:[bx]       ; before calling this function we already set CS to the correct segment..
	stos   BYTE PTR es:[di]       ;
	add    di,si                  ; si has 79 (0x4F) and stos added one
	add    dx,cx

    mov    al,dh
	and    al,ah                  ; ah has 0x7F (127)
	add    al,bh                  ; bh has the 0 to F offset
	xlat   BYTE PTR ds:[bx]       ;
	xlat   BYTE PTR cs:[bx]       ; before calling this function we already set CS to the correct segment..
	stos   BYTE PTR es:[di]       ;
	add    di,si                  ; si has 79 (0x4F) and stos added one
	add    dx,cx

    mov    al,dh
	and    al,ah                  ; ah has 0x7F (127)
	add    al,bh                  ; bh has the 0 to F offset
	xlat   BYTE PTR ds:[bx]       ;
	xlat   BYTE PTR cs:[bx]       ; before calling this function we already set CS to the correct segment..
	stos   BYTE PTR es:[di]       ;
	add    di,si                  ; si has 79 (0x4F) and stos added one
	add    dx,cx

    mov    al,dh
	and    al,ah                  ; ah has 0x7F (127)
	add    al,bh                  ; bh has the 0 to F offset
	xlat   BYTE PTR ds:[bx]       ;
	xlat   BYTE PTR cs:[bx]       ; before calling this function we already set CS to the correct segment..
	stos   BYTE PTR es:[di]       ;
	add    di,si                  ; si has 79 (0x4F) and stos added one
	add    dx,cx

    mov    al,dh
	and    al,ah                  ; ah has 0x7F (127)
	add    al,bh                  ; bh has the 0 to F offset
	xlat   BYTE PTR ds:[bx]       ;
	xlat   BYTE PTR cs:[bx]       ; before calling this function we already set CS to the correct segment..
	stos   BYTE PTR es:[di]       ;
	add    di,si                  ; si has 79 (0x4F) and stos added one
	add    dx,cx

    mov    al,dh
	and    al,ah                  ; ah has 0x7F (127)
	add    al,bh                  ; bh has the 0 to F offset
	xlat   BYTE PTR ds:[bx]       ;
	xlat   BYTE PTR cs:[bx]       ; before calling this function we already set CS to the correct segment..
	stos   BYTE PTR es:[di]       ;
	add    di,si                  ; si has 79 (0x4F) and stos added one
	add    dx,cx

    mov    al,dh
	and    al,ah                  ; ah has 0x7F (127)
	add    al,bh                  ; bh has the 0 to F offset
	xlat   BYTE PTR ds:[bx]       ;
	xlat   BYTE PTR cs:[bx]       ; before calling this function we already set CS to the correct segment..
	stos   BYTE PTR es:[di]       ;
	add    di,si                  ; si has 79 (0x4F) and stos added one
	add    dx,cx

    mov    al,dh
	and    al,ah                  ; ah has 0x7F (127)
	add    al,bh                  ; bh has the 0 to F offset
	xlat   BYTE PTR ds:[bx]       ;
	xlat   BYTE PTR cs:[bx]       ; before calling this function we already set CS to the correct segment..
	stos   BYTE PTR es:[di]       ;
	add    di,si                  ; si has 79 (0x4F) and stos added one
	add    dx,cx

    mov    al,dh
	and    al,ah                  ; ah has 0x7F (127)
	add    al,bh                  ; bh has the 0 to F offset
	xlat   BYTE PTR ds:[bx]       ;
	xlat   BYTE PTR cs:[bx]       ; before calling this function we already set CS to the correct segment..
	stos   BYTE PTR es:[di]       ;
	add    di,si                  ; si has 79 (0x4F) and stos added one
	add    dx,cx

    mov    al,dh
	and    al,ah                  ; ah has 0x7F (127)
	add    al,bh                  ; bh has the 0 to F offset
	xlat   BYTE PTR ds:[bx]       ;
	xlat   BYTE PTR cs:[bx]       ; before calling this function we already set CS to the correct segment..
	stos   BYTE PTR es:[di]       ;
	add    di,si                  ; si has 79 (0x4F) and stos added one
	add    dx,cx

    mov    al,dh
	and    al,ah                  ; ah has 0x7F (127)
	add    al,bh                  ; bh has the 0 to F offset
	xlat   BYTE PTR ds:[bx]       ;
	xlat   BYTE PTR cs:[bx]       ; before calling this function we already set CS to the correct segment..
	stos   BYTE PTR es:[di]       ;
	add    di,si                  ; si has 79 (0x4F) and stos added one
	add    dx,cx

    mov    al,dh
	and    al,ah                  ; ah has 0x7F (127)
	add    al,bh                  ; bh has the 0 to F offset
	xlat   BYTE PTR ds:[bx]       ;
	xlat   BYTE PTR cs:[bx]       ; before calling this function we already set CS to the correct segment..
	stos   BYTE PTR es:[di]       ;
	add    di,si                  ; si has 79 (0x4F) and stos added one
	add    dx,cx

    mov    al,dh
	and    al,ah                  ; ah has 0x7F (127)
	add    al,bh                  ; bh has the 0 to F offset
	xlat   BYTE PTR ds:[bx]       ;
	xlat   BYTE PTR cs:[bx]       ; before calling this function we already set CS to the correct segment..
	stos   BYTE PTR es:[di]       ;
	add    di,si                  ; si has 79 (0x4F) and stos added one
	add    dx,cx

    mov    al,dh
	and    al,ah                  ; ah has 0x7F (127)
	add    al,bh                  ; bh has the 0 to F offset
	xlat   BYTE PTR ds:[bx]       ;
	xlat   BYTE PTR cs:[bx]       ; before calling this function we already set CS to the correct segment..
	stos   BYTE PTR es:[di]       ;
	add    di,si                  ; si has 79 (0x4F) and stos added one
	add    dx,cx

    mov    al,dh
	and    al,ah                  ; ah has 0x7F (127)
	add    al,bh                  ; bh has the 0 to F offset
	xlat   BYTE PTR ds:[bx]       ;
	xlat   BYTE PTR cs:[bx]       ; before calling this function we already set CS to the correct segment..
	stos   BYTE PTR es:[di]       ;
	add    di,si                  ; si has 79 (0x4F) and stos added one
	add    dx,cx

    mov    al,dh
	and    al,ah                  ; ah has 0x7F (127)
	add    al,bh                  ; bh has the 0 to F offset
	xlat   BYTE PTR ds:[bx]       ;
	xlat   BYTE PTR cs:[bx]       ; before calling this function we already set CS to the correct segment..
	stos   BYTE PTR es:[di]       ;
	add    di,si                  ; si has 79 (0x4F) and stos added one
	add    dx,cx

    mov    al,dh
	and    al,ah                  ; ah has 0x7F (127)
	add    al,bh                  ; bh has the 0 to F offset
	xlat   BYTE PTR ds:[bx]       ;
	xlat   BYTE PTR cs:[bx]       ; before calling this function we already set CS to the correct segment..
	stos   BYTE PTR es:[di]       ;
	add    di,si                  ; si has 79 (0x4F) and stos added one
	add    dx,cx

    mov    al,dh
	and    al,ah                  ; ah has 0x7F (127)
	add    al,bh                  ; bh has the 0 to F offset
	xlat   BYTE PTR ds:[bx]       ;
	xlat   BYTE PTR cs:[bx]       ; before calling this function we already set CS to the correct segment..
	stos   BYTE PTR es:[di]       ;
	add    di,si                  ; si has 79 (0x4F) and stos added one
	add    dx,cx

    mov    al,dh
	and    al,ah                  ; ah has 0x7F (127)
	add    al,bh                  ; bh has the 0 to F offset
	xlat   BYTE PTR ds:[bx]       ;
	xlat   BYTE PTR cs:[bx]       ; before calling this function we already set CS to the correct segment..
	stos   BYTE PTR es:[di]       ;
	add    di,si                  ; si has 79 (0x4F) and stos added one
	add    dx,cx

    mov    al,dh
	and    al,ah                  ; ah has 0x7F (127)
	add    al,bh                  ; bh has the 0 to F offset
	xlat   BYTE PTR ds:[bx]       ;
	xlat   BYTE PTR cs:[bx]       ; before calling this function we already set CS to the correct segment..
	stos   BYTE PTR es:[di]       ;
	add    di,si                  ; si has 79 (0x4F) and stos added one
	add    dx,cx

    mov    al,dh
	and    al,ah                  ; ah has 0x7F (127)
	add    al,bh                  ; bh has the 0 to F offset
	xlat   BYTE PTR ds:[bx]       ;
	xlat   BYTE PTR cs:[bx]       ; before calling this function we already set CS to the correct segment..
	stos   BYTE PTR es:[di]       ;
	add    di,si                  ; si has 79 (0x4F) and stos added one
	add    dx,cx

    mov    al,dh
	and    al,ah                  ; ah has 0x7F (127)
	add    al,bh                  ; bh has the 0 to F offset
	xlat   BYTE PTR ds:[bx]       ;
	xlat   BYTE PTR cs:[bx]       ; before calling this function we already set CS to the correct segment..
	stos   BYTE PTR es:[di]       ;
	add    di,si                  ; si has 79 (0x4F) and stos added one
	add    dx,cx

    mov    al,dh
	and    al,ah                  ; ah has 0x7F (127)
	add    al,bh                  ; bh has the 0 to F offset
	xlat   BYTE PTR ds:[bx]       ;
	xlat   BYTE PTR cs:[bx]       ; before calling this function we already set CS to the correct segment..
	stos   BYTE PTR es:[di]       ;
	add    di,si                  ; si has 79 (0x4F) and stos added one
	add    dx,cx

    mov    al,dh
	and    al,ah                  ; ah has 0x7F (127)
	add    al,bh                  ; bh has the 0 to F offset
	xlat   BYTE PTR ds:[bx]       ;
	xlat   BYTE PTR cs:[bx]       ; before calling this function we already set CS to the correct segment..
	stos   BYTE PTR es:[di]       ;
	add    di,si                  ; si has 79 (0x4F) and stos added one
	add    dx,cx

    mov    al,dh
	and    al,ah                  ; ah has 0x7F (127)
	add    al,bh                  ; bh has the 0 to F offset
	xlat   BYTE PTR ds:[bx]       ;
	xlat   BYTE PTR cs:[bx]       ; before calling this function we already set CS to the correct segment..
	stos   BYTE PTR es:[di]       ;
	add    di,si                  ; si has 79 (0x4F) and stos added one
	add    dx,cx

    mov    al,dh
	and    al,ah                  ; ah has 0x7F (127)
	add    al,bh                  ; bh has the 0 to F offset
	xlat   BYTE PTR ds:[bx]       ;
	xlat   BYTE PTR cs:[bx]       ; before calling this function we already set CS to the correct segment..
	stos   BYTE PTR es:[di]       ;
	add    di,si                  ; si has 79 (0x4F) and stos added one
	add    dx,cx

    mov    al,dh
	and    al,ah                  ; ah has 0x7F (127)
	add    al,bh                  ; bh has the 0 to F offset
	xlat   BYTE PTR ds:[bx]       ;
	xlat   BYTE PTR cs:[bx]       ; before calling this function we already set CS to the correct segment..
	stos   BYTE PTR es:[di]       ;
	add    di,si                  ; si has 79 (0x4F) and stos added one
	add    dx,cx

    mov    al,dh
	and    al,ah                  ; ah has 0x7F (127)
	add    al,bh                  ; bh has the 0 to F offset
	xlat   BYTE PTR ds:[bx]       ;
	xlat   BYTE PTR cs:[bx]       ; before calling this function we already set CS to the correct segment..
	stos   BYTE PTR es:[di]       ;
	add    di,si                  ; si has 79 (0x4F) and stos added one
	add    dx,cx

    mov    al,dh
	and    al,ah                  ; ah has 0x7F (127)
	add    al,bh                  ; bh has the 0 to F offset
	xlat   BYTE PTR ds:[bx]       ;
	xlat   BYTE PTR cs:[bx]       ; before calling this function we already set CS to the correct segment..
	stos   BYTE PTR es:[di]       ;
	add    di,si                  ; si has 79 (0x4F) and stos added one
	add    dx,cx

    mov    al,dh
	and    al,ah                  ; ah has 0x7F (127)
	add    al,bh                  ; bh has the 0 to F offset
	xlat   BYTE PTR ds:[bx]       ;
	xlat   BYTE PTR cs:[bx]       ; before calling this function we already set CS to the correct segment..
	stos   BYTE PTR es:[di]       ;
	add    di,si                  ; si has 79 (0x4F) and stos added one
	add    dx,cx

    mov    al,dh
	and    al,ah                  ; ah has 0x7F (127)
	add    al,bh                  ; bh has the 0 to F offset
	xlat   BYTE PTR ds:[bx]       ;
	xlat   BYTE PTR cs:[bx]       ; before calling this function we already set CS to the correct segment..
	stos   BYTE PTR es:[di]       ;
	add    di,si                  ; si has 79 (0x4F) and stos added one
	add    dx,cx

    mov    al,dh
	and    al,ah                  ; ah has 0x7F (127)
	add    al,bh                  ; bh has the 0 to F offset
	xlat   BYTE PTR ds:[bx]       ;
	xlat   BYTE PTR cs:[bx]       ; before calling this function we already set CS to the correct segment..
	stos   BYTE PTR es:[di]       ;
	add    di,si                  ; si has 79 (0x4F) and stos added one
	add    dx,cx

    mov    al,dh
	and    al,ah                  ; ah has 0x7F (127)
	add    al,bh                  ; bh has the 0 to F offset
	xlat   BYTE PTR ds:[bx]       ;
	xlat   BYTE PTR cs:[bx]       ; before calling this function we already set CS to the correct segment..
	stos   BYTE PTR es:[di]       ;
	add    di,si                  ; si has 79 (0x4F) and stos added one
	add    dx,cx

    mov    al,dh
	and    al,ah                  ; ah has 0x7F (127)
	add    al,bh                  ; bh has the 0 to F offset
	xlat   BYTE PTR ds:[bx]       ;
	xlat   BYTE PTR cs:[bx]       ; before calling this function we already set CS to the correct segment..
	stos   BYTE PTR es:[di]       ;
	add    di,si                  ; si has 79 (0x4F) and stos added one
	add    dx,cx

    mov    al,dh
	and    al,ah                  ; ah has 0x7F (127)
	add    al,bh                  ; bh has the 0 to F offset
	xlat   BYTE PTR ds:[bx]       ;
	xlat   BYTE PTR cs:[bx]       ; before calling this function we already set CS to the correct segment..
	stos   BYTE PTR es:[di]       ;
	add    di,si                  ; si has 79 (0x4F) and stos added one
	add    dx,cx

    mov    al,dh
	and    al,ah                  ; ah has 0x7F (127)
	add    al,bh                  ; bh has the 0 to F offset
	xlat   BYTE PTR ds:[bx]       ;
	xlat   BYTE PTR cs:[bx]       ; before calling this function we already set CS to the correct segment..
	stos   BYTE PTR es:[di]       ;
	add    di,si                  ; si has 79 (0x4F) and stos added one
	add    dx,cx

    mov    al,dh
	and    al,ah                  ; ah has 0x7F (127)
	add    al,bh                  ; bh has the 0 to F offset
	xlat   BYTE PTR ds:[bx]       ;
	xlat   BYTE PTR cs:[bx]       ; before calling this function we already set CS to the correct segment..
	stos   BYTE PTR es:[di]       ;
	add    di,si                  ; si has 79 (0x4F) and stos added one
	add    dx,cx

    mov    al,dh
	and    al,ah                  ; ah has 0x7F (127)
	add    al,bh                  ; bh has the 0 to F offset
	xlat   BYTE PTR ds:[bx]       ;
	xlat   BYTE PTR cs:[bx]       ; before calling this function we already set CS to the correct segment..
	stos   BYTE PTR es:[di]       ;
	add    di,si                  ; si has 79 (0x4F) and stos added one
	add    dx,cx

    mov    al,dh
	and    al,ah                  ; ah has 0x7F (127)
	add    al,bh                  ; bh has the 0 to F offset
	xlat   BYTE PTR ds:[bx]       ;
	xlat   BYTE PTR cs:[bx]       ; before calling this function we already set CS to the correct segment..
	stos   BYTE PTR es:[di]       ;
	add    di,si                  ; si has 79 (0x4F) and stos added one
	add    dx,cx

    mov    al,dh
	and    al,ah                  ; ah has 0x7F (127)
	add    al,bh                  ; bh has the 0 to F offset
	xlat   BYTE PTR ds:[bx]       ;
	xlat   BYTE PTR cs:[bx]       ; before calling this function we already set CS to the correct segment..
	stos   BYTE PTR es:[di]       ;
	add    di,si                  ; si has 79 (0x4F) and stos added one
	add    dx,cx

    mov    al,dh
	and    al,ah                  ; ah has 0x7F (127)
	add    al,bh                  ; bh has the 0 to F offset
	xlat   BYTE PTR ds:[bx]       ;
	xlat   BYTE PTR cs:[bx]       ; before calling this function we already set CS to the correct segment..
	stos   BYTE PTR es:[di]       ;
	add    di,si                  ; si has 79 (0x4F) and stos added one
	add    dx,cx

    mov    al,dh
	and    al,ah                  ; ah has 0x7F (127)
	add    al,bh                  ; bh has the 0 to F offset
	xlat   BYTE PTR ds:[bx]       ;
	xlat   BYTE PTR cs:[bx]       ; before calling this function we already set CS to the correct segment..
	stos   BYTE PTR es:[di]       ;
	add    di,si                  ; si has 79 (0x4F) and stos added one
	add    dx,cx

    mov    al,dh
	and    al,ah                  ; ah has 0x7F (127)
	add    al,bh                  ; bh has the 0 to F offset
	xlat   BYTE PTR ds:[bx]       ;
	xlat   BYTE PTR cs:[bx]       ; before calling this function we already set CS to the correct segment..
	stos   BYTE PTR es:[di]       ;
	add    di,si                  ; si has 79 (0x4F) and stos added one
	add    dx,cx

    mov    al,dh
	and    al,ah                  ; ah has 0x7F (127)
	add    al,bh                  ; bh has the 0 to F offset
	xlat   BYTE PTR ds:[bx]       ;
	xlat   BYTE PTR cs:[bx]       ; before calling this function we already set CS to the correct segment..
	stos   BYTE PTR es:[di]       ;
	add    di,si                  ; si has 79 (0x4F) and stos added one
	add    dx,cx

    mov    al,dh
	and    al,ah                  ; ah has 0x7F (127)
	add    al,bh                  ; bh has the 0 to F offset
	xlat   BYTE PTR ds:[bx]       ;
	xlat   BYTE PTR cs:[bx]       ; before calling this function we already set CS to the correct segment..
	stos   BYTE PTR es:[di]       ;
	add    di,si                  ; si has 79 (0x4F) and stos added one
	add    dx,cx

    mov    al,dh
	and    al,ah                  ; ah has 0x7F (127)
	add    al,bh                  ; bh has the 0 to F offset
	xlat   BYTE PTR ds:[bx]       ;
	xlat   BYTE PTR cs:[bx]       ; before calling this function we already set CS to the correct segment..
	stos   BYTE PTR es:[di]       ;
	add    di,si                  ; si has 79 (0x4F) and stos added one
	add    dx,cx

    mov    al,dh
	and    al,ah                  ; ah has 0x7F (127)
	add    al,bh                  ; bh has the 0 to F offset
	xlat   BYTE PTR ds:[bx]       ;
	xlat   BYTE PTR cs:[bx]       ; before calling this function we already set CS to the correct segment..
	stos   BYTE PTR es:[di]       ;
	add    di,si                  ; si has 79 (0x4F) and stos added one
	add    dx,cx

    mov    al,dh
	and    al,ah                  ; ah has 0x7F (127)
	add    al,bh                  ; bh has the 0 to F offset
	xlat   BYTE PTR ds:[bx]       ;
	xlat   BYTE PTR cs:[bx]       ; before calling this function we already set CS to the correct segment..
	stos   BYTE PTR es:[di]       ;
	add    di,si                  ; si has 79 (0x4F) and stos added one
	add    dx,cx

    mov    al,dh
	and    al,ah                  ; ah has 0x7F (127)
	add    al,bh                  ; bh has the 0 to F offset
	xlat   BYTE PTR ds:[bx]       ;
	xlat   BYTE PTR cs:[bx]       ; before calling this function we already set CS to the correct segment..
	stos   BYTE PTR es:[di]       ;
	add    di,si                  ; si has 79 (0x4F) and stos added one
	add    dx,cx

    mov    al,dh
	and    al,ah                  ; ah has 0x7F (127)
	add    al,bh                  ; bh has the 0 to F offset
	xlat   BYTE PTR ds:[bx]       ;
	xlat   BYTE PTR cs:[bx]       ; before calling this function we already set CS to the correct segment..
	stos   BYTE PTR es:[di]       ;
	add    di,si                  ; si has 79 (0x4F) and stos added one
	add    dx,cx

    mov    al,dh
	and    al,ah                  ; ah has 0x7F (127)
	add    al,bh                  ; bh has the 0 to F offset
	xlat   BYTE PTR ds:[bx]       ;
	xlat   BYTE PTR cs:[bx]       ; before calling this function we already set CS to the correct segment..
	stos   BYTE PTR es:[di]       ;
	add    di,si                  ; si has 79 (0x4F) and stos added one
	add    dx,cx

    mov    al,dh
	and    al,ah                  ; ah has 0x7F (127)
	add    al,bh                  ; bh has the 0 to F offset
	xlat   BYTE PTR ds:[bx]       ;
	xlat   BYTE PTR cs:[bx]       ; before calling this function we already set CS to the correct segment..
	stos   BYTE PTR es:[di]       ;
	add    di,si                  ; si has 79 (0x4F) and stos added one
	add    dx,cx

    mov    al,dh
	and    al,ah                  ; ah has 0x7F (127)
	add    al,bh                  ; bh has the 0 to F offset
	xlat   BYTE PTR ds:[bx]       ;
	xlat   BYTE PTR cs:[bx]       ; before calling this function we already set CS to the correct segment..
	stos   BYTE PTR es:[di]       ;
	add    di,si                  ; si has 79 (0x4F) and stos added one
	add    dx,cx

    mov    al,dh
	and    al,ah                  ; ah has 0x7F (127)
	add    al,bh                  ; bh has the 0 to F offset
	xlat   BYTE PTR ds:[bx]       ;
	xlat   BYTE PTR cs:[bx]       ; before calling this function we already set CS to the correct segment..
	stos   BYTE PTR es:[di]       ;
	add    di,si                  ; si has 79 (0x4F) and stos added one
	add    dx,cx

    mov    al,dh
	and    al,ah                  ; ah has 0x7F (127)
	add    al,bh                  ; bh has the 0 to F offset
	xlat   BYTE PTR ds:[bx]       ;
	xlat   BYTE PTR cs:[bx]       ; before calling this function we already set CS to the correct segment..
	stos   BYTE PTR es:[di]       ;
	add    di,si                  ; si has 79 (0x4F) and stos added one
	add    dx,cx

    mov    al,dh
	and    al,ah                  ; ah has 0x7F (127)
	add    al,bh                  ; bh has the 0 to F offset
	xlat   BYTE PTR ds:[bx]       ;
	xlat   BYTE PTR cs:[bx]       ; before calling this function we already set CS to the correct segment..
	stos   BYTE PTR es:[di]       ;
	add    di,si                  ; si has 79 (0x4F) and stos added one
	add    dx,cx

    mov    al,dh
	and    al,ah                  ; ah has 0x7F (127)
	add    al,bh                  ; bh has the 0 to F offset
	xlat   BYTE PTR ds:[bx]       ;
	xlat   BYTE PTR cs:[bx]       ; before calling this function we already set CS to the correct segment..
	stos   BYTE PTR es:[di]       ;
	add    di,si                  ; si has 79 (0x4F) and stos added one
	add    dx,cx

    mov    al,dh
	and    al,ah                  ; ah has 0x7F (127)
	add    al,bh                  ; bh has the 0 to F offset
	xlat   BYTE PTR ds:[bx]       ;
	xlat   BYTE PTR cs:[bx]       ; before calling this function we already set CS to the correct segment..
	stos   BYTE PTR es:[di]       ;
	add    di,si                  ; si has 79 (0x4F) and stos added one
	add    dx,cx

    mov    al,dh
	and    al,ah                  ; ah has 0x7F (127)
	add    al,bh                  ; bh has the 0 to F offset
	xlat   BYTE PTR ds:[bx]       ;
	xlat   BYTE PTR cs:[bx]       ; before calling this function we already set CS to the correct segment..
	stos   BYTE PTR es:[di]       ;
	add    di,si                  ; si has 79 (0x4F) and stos added one
	add    dx,cx

    mov    al,dh
	and    al,ah                  ; ah has 0x7F (127)
	add    al,bh                  ; bh has the 0 to F offset
	xlat   BYTE PTR ds:[bx]       ;
	xlat   BYTE PTR cs:[bx]       ; before calling this function we already set CS to the correct segment..
	stos   BYTE PTR es:[di]       ;
	add    di,si                  ; si has 79 (0x4F) and stos added one
	add    dx,cx

    mov    al,dh
	and    al,ah                  ; ah has 0x7F (127)
	add    al,bh                  ; bh has the 0 to F offset
	xlat   BYTE PTR ds:[bx]       ;
	xlat   BYTE PTR cs:[bx]       ; before calling this function we already set CS to the correct segment..
	stos   BYTE PTR es:[di]       ;
	add    di,si                  ; si has 79 (0x4F) and stos added one
	add    dx,cx

    mov    al,dh
	and    al,ah                  ; ah has 0x7F (127)
	add    al,bh                  ; bh has the 0 to F offset
	xlat   BYTE PTR ds:[bx]       ;
	xlat   BYTE PTR cs:[bx]       ; before calling this function we already set CS to the correct segment..
	stos   BYTE PTR es:[di]       ;
	add    di,si                  ; si has 79 (0x4F) and stos added one
	add    dx,cx

    mov    al,dh
	and    al,ah                  ; ah has 0x7F (127)
	add    al,bh                  ; bh has the 0 to F offset
	xlat   BYTE PTR ds:[bx]       ;
	xlat   BYTE PTR cs:[bx]       ; before calling this function we already set CS to the correct segment..
	stos   BYTE PTR es:[di]       ;
	add    di,si                  ; si has 79 (0x4F) and stos added one
	add    dx,cx

    mov    al,dh
	and    al,ah                  ; ah has 0x7F (127)
	add    al,bh                  ; bh has the 0 to F offset
	xlat   BYTE PTR ds:[bx]       ;
	xlat   BYTE PTR cs:[bx]       ; before calling this function we already set CS to the correct segment..
	stos   BYTE PTR es:[di]       ;
	add    di,si                  ; si has 79 (0x4F) and stos added one
	add    dx,cx

    mov    al,dh
	and    al,ah                  ; ah has 0x7F (127)
	add    al,bh                  ; bh has the 0 to F offset
	xlat   BYTE PTR ds:[bx]       ;
	xlat   BYTE PTR cs:[bx]       ; before calling this function we already set CS to the correct segment..
	stos   BYTE PTR es:[di]       ;
	add    di,si                  ; si has 79 (0x4F) and stos added one
	add    dx,cx

    mov    al,dh
	and    al,ah                  ; ah has 0x7F (127)
	add    al,bh                  ; bh has the 0 to F offset
	xlat   BYTE PTR ds:[bx]       ;
	xlat   BYTE PTR cs:[bx]       ; before calling this function we already set CS to the correct segment..
	stos   BYTE PTR es:[di]       ;
	add    di,si                  ; si has 79 (0x4F) and stos added one
	add    dx,cx

    mov    al,dh
	and    al,ah                  ; ah has 0x7F (127)
	add    al,bh                  ; bh has the 0 to F offset
	xlat   BYTE PTR ds:[bx]       ;
	xlat   BYTE PTR cs:[bx]       ; before calling this function we already set CS to the correct segment..
	stos   BYTE PTR es:[di]       ;
	add    di,si                  ; si has 79 (0x4F) and stos added one
	add    dx,cx

    mov    al,dh
	and    al,ah                  ; ah has 0x7F (127)
	add    al,bh                  ; bh has the 0 to F offset
	xlat   BYTE PTR ds:[bx]       ;
	xlat   BYTE PTR cs:[bx]       ; before calling this function we already set CS to the correct segment..
	stos   BYTE PTR es:[di]       ;
	add    di,si                  ; si has 79 (0x4F) and stos added one
	add    dx,cx

    mov    al,dh
	and    al,ah                  ; ah has 0x7F (127)
	add    al,bh                  ; bh has the 0 to F offset
	xlat   BYTE PTR ds:[bx]       ;
	xlat   BYTE PTR cs:[bx]       ; before calling this function we already set CS to the correct segment..
	stos   BYTE PTR es:[di]       ;
	add    di,si                  ; si has 79 (0x4F) and stos added one
	add    dx,cx

    mov    al,dh
	and    al,ah                  ; ah has 0x7F (127)
	add    al,bh                  ; bh has the 0 to F offset
	xlat   BYTE PTR ds:[bx]       ;
	xlat   BYTE PTR cs:[bx]       ; before calling this function we already set CS to the correct segment..
	stos   BYTE PTR es:[di]       ;
	add    di,si                  ; si has 79 (0x4F) and stos added one
	add    dx,cx

    mov    al,dh
	and    al,ah                  ; ah has 0x7F (127)
	add    al,bh                  ; bh has the 0 to F offset
	xlat   BYTE PTR ds:[bx]       ;
	xlat   BYTE PTR cs:[bx]       ; before calling this function we already set CS to the correct segment..
	stos   BYTE PTR es:[di]       ;
	add    di,si                  ; si has 79 (0x4F) and stos added one
	add    dx,cx

    mov    al,dh
	and    al,ah                  ; ah has 0x7F (127)
	add    al,bh                  ; bh has the 0 to F offset
	xlat   BYTE PTR ds:[bx]       ;
	xlat   BYTE PTR cs:[bx]       ; before calling this function we already set CS to the correct segment..
	stos   BYTE PTR es:[di]       ;
	add    di,si                  ; si has 79 (0x4F) and stos added one
	add    dx,cx

    mov    al,dh
	and    al,ah                  ; ah has 0x7F (127)
	add    al,bh                  ; bh has the 0 to F offset
	xlat   BYTE PTR ds:[bx]       ;
	xlat   BYTE PTR cs:[bx]       ; before calling this function we already set CS to the correct segment..
	stos   BYTE PTR es:[di]       ;
	add    di,si                  ; si has 79 (0x4F) and stos added one
	add    dx,cx

    mov    al,dh
	and    al,ah                  ; ah has 0x7F (127)
	add    al,bh                  ; bh has the 0 to F offset
	xlat   BYTE PTR ds:[bx]       ;
	xlat   BYTE PTR cs:[bx]       ; before calling this function we already set CS to the correct segment..
	stos   BYTE PTR es:[di]       ;
	add    di,si                  ; si has 79 (0x4F) and stos added one
	add    dx,cx

    mov    al,dh
	and    al,ah                  ; ah has 0x7F (127)
	add    al,bh                  ; bh has the 0 to F offset
	xlat   BYTE PTR ds:[bx]       ;
	xlat   BYTE PTR cs:[bx]       ; before calling this function we already set CS to the correct segment..
	stos   BYTE PTR es:[di]       ;
	add    di,si                  ; si has 79 (0x4F) and stos added one
	add    dx,cx

    mov    al,dh
	and    al,ah                  ; ah has 0x7F (127)
	add    al,bh                  ; bh has the 0 to F offset
	xlat   BYTE PTR ds:[bx]       ;
	xlat   BYTE PTR cs:[bx]       ; before calling this function we already set CS to the correct segment..
	stos   BYTE PTR es:[di]       ;
	add    di,si                  ; si has 79 (0x4F) and stos added one
	add    dx,cx

    mov    al,dh
	and    al,ah                  ; ah has 0x7F (127)
	add    al,bh                  ; bh has the 0 to F offset
	xlat   BYTE PTR ds:[bx]       ;
	xlat   BYTE PTR cs:[bx]       ; before calling this function we already set CS to the correct segment..
	stos   BYTE PTR es:[di]       ;
	add    di,si                  ; si has 79 (0x4F) and stos added one
	add    dx,cx

    mov    al,dh
	and    al,ah                  ; ah has 0x7F (127)
	add    al,bh                  ; bh has the 0 to F offset
	xlat   BYTE PTR ds:[bx]       ;
	xlat   BYTE PTR cs:[bx]       ; before calling this function we already set CS to the correct segment..
	stos   BYTE PTR es:[di]       ;
	add    di,si                  ; si has 79 (0x4F) and stos added one
	add    dx,cx

    mov    al,dh
	and    al,ah                  ; ah has 0x7F (127)
	add    al,bh                  ; bh has the 0 to F offset
	xlat   BYTE PTR ds:[bx]       ;
	xlat   BYTE PTR cs:[bx]       ; before calling this function we already set CS to the correct segment..
	stos   BYTE PTR es:[di]       ;
	add    di,si                  ; si has 79 (0x4F) and stos added one
	add    dx,cx

    mov    al,dh
	and    al,ah                  ; ah has 0x7F (127)
	add    al,bh                  ; bh has the 0 to F offset
	xlat   BYTE PTR ds:[bx]       ;
	xlat   BYTE PTR cs:[bx]       ; before calling this function we already set CS to the correct segment..
	stos   BYTE PTR es:[di]       ;
	; dont need these in last loop
    ;add    di,si                  ; si has 79 (0x4F) and stos added one
	;add    dx,cx

loop_done:
; clean up
    pop   ds
    pop   si
	sti
    pop   di
    pop   dx
    pop   cx
    pop   bx
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
push  bp
mov   bp, sp                                 ;
sub   sp, 4                                  ; need stack space for dynamic farcall
mov   si, 6f15h                              ; store this segment
add   si, ax                                 ; add the offset to it already
mov   es, si                                 ; store this segment for now, with offset pre-added
mov   di, ax                                 ; store argument (offset)
mov   ax, word ptr [_dc_source]              ; load dc_source offset
mov   dh, al                                 ; shift 8 at once
and   dx, 0f00h                              ; and zero out the other bits to get the last hex digit * 100 bytes for eventual BH value
mov   cx, dx                                 ;
shr   ax, 1                                  ; segment value of offset
shr   ax, 1                                 
shr   ax, 1                                 
shr   ax, 1                                 
mov   word ptr [_dc_source], dx              ; save BX value
shr   cx, 1                                  ; segment value of eventual bh  (bx offset)
shr   cx, 1
shr   cx, 1
shr   cx, 1
mov   bx, word ptr [_dc_source + 2]         ; get dc_source segment
sub   ax, cx                                ; subtract the (bx_offset >> 4) from dc_source offset segment value
add   bx, ax                                ; modify dc_source segment by calculated desired alpha which offsets bx
mov   al, byte ptr [_dc_yh]                 ; grab dc_yh
mov   es, si                                ;
mov   word ptr [_dc_source + 2], bx
xor   ah, ah                                 ;
mov   bx, word ptr [_dc_yl]
sub   al, bl                                 ;
add   bx, bx                                 ; double dc_yl to get a word offset
mov   si, ax                                 ;
mov   bx, word ptr es:[bx]
add   si, ax                                 ; double count (dc_yh - dc_yl) to get a word offset
mov   ax, 6efch                              ; segment of dc_yl_lookup array
add   ax, di                                 ; add argument offset to the ax address
mov   word ptr [_dc_yl_lookup_val], bx       ; store pre-calculated dc_yl * 80
mov   es, ax
mov   bx, 074h                               ; location of jump relative instruction's immediate
mov   ax, word ptr es:[si]                   ; 
add   di, 6f2eh                              ; R_DrawColumn segment with 0 indexed function offset
mov   es, di                                 ; set seg
mov   word ptr es:[bx], ax                   ; overwrite the jump relative call for however many iterations in unrolled loop we need
mov   al, byte ptr [_dc_colormap_index]      ; lookup colormap index
mov   bx, dx                                 ;
; what follows is compution of desired CS segment and offset to function to allow for colormaps to be CS:BX and match DS:BX column
mov   dx, word ptr [_dc_colormap_segment]    
add   bx, 2420h
sub   dx, cx
test  al, al
je    skipcolormapzero
xor   ah, ah
mov   ch, al
xor   cl, cl
shl   ax, 1
shl   ax, 1
shl   ax, 1
shl   ax, 1
sub   bx, cx
add   ax, dx
mov   word ptr [bp - 4], bx
mov   word ptr [bp - 2], ax


db 255  ;FEh   lcall[bp-4]
db 94   ;5Eh
db 252  ;FCh

leave 
pop   di
pop   si
pop   dx
pop   cx
pop   bx
retf  
skipcolormapzero:
mov   word ptr [bp - 4], bx
mov   word ptr [bp - 2], dx

db 255  ;FEh   lcall[bp-4]
db 94   ;5Eh
db 252  ;FCh

leave 
pop   di
pop   si
pop   dx
pop   cx
pop   bx
retf  
cld   

ENDP




;
; R_DrawSpan
;
	
PROC  R_DrawSpan_
PUBLIC  R_DrawSpan_ 

; argument AX is diff for various segment lookups


push  bx
push  cx
push  dx
push  si
push  di
push  bp
mov   bp, sp
sub   sp, 28h                           ; setup stack
mov   ax, word ptr [_ds_xstep]          
mov   dx, word ptr [_ds_xstep + 2]      
mov   cl, 6
shl   dx, cl
rol   ax, cl
xor   dx, ax
and   ax, 0ffc0h
xor   dx, ax
mov   word ptr [bp - 10h], ax
mov   word ptr [bp - 0eh], dx
mov   ax, word ptr [_ds_ystep]
mov   dx, word ptr [_ds_ystep + 2]
mov   cl, 6
shl   dx, cl
rol   ax, cl
xor   dx, ax
and   ax, 0ffc0h
xor   dx, ax
mov   word ptr [bp - 1ch], 0
mov   word ptr [bp - 14h], ax
mov   word ptr [bp - 1eh], dx
label4:
mov   cl, byte ptr [bp - 1ch]
mov   ax, 1
mov   dx, 3c5h
shl   ax, cl
out   dx, al
mov   ax, word ptr [_ds_x1]
sub   ax, word ptr [bp - 1ch]
CWD   
shl   dx, 2
sbb   ax, dx
sar   ax, 2
mov   bx, ax
shl   ax, 2
add   ax, word ptr [bp - 1ch]
cmp   ax, word ptr [_ds_x1]
jge   label5
inc   bx
label5:
mov   ax, word ptr [_ds_x2]
sub   ax, word ptr [bp - 1ch]
CWD   
shl   dx, 2
sbb   ax, dx
sar   ax, 2
sub   ax, bx
mov   word ptr [bp - 4], ax
test  ax, ax
jge   label1
jmp   label2
label1:
imul  dx, word ptr [_ds_y], 50h
mov   ax, word ptr [_destview]
mov   si, word ptr [_destview + 2]
add   ax, dx
mov   word ptr [bp - 12h], si
mov   si, ax
mov   ax, bx
shl   ax, 2
sub   ax, word ptr [_ds_x1]
add   ax, word ptr [bp - 1ch]
CWD   
add   si, bx
mov   word ptr [bp - 28h], dx
mov   di, ax
mov   cx, word ptr [bp - 28h]
mov   ax, word ptr [_ds_xstep]
mov   dx, word ptr [_ds_xstep + 2]
mov   bx, di

; inline i4m

 		xchg    ax,bx           ; swap low(M1) and low(M2)
        push    ax              ; save low(M2)
        xchg    ax,dx           ; exchange low(M2) and high(M1)
        or      ax,ax           ; if high(M1) non-zero
        je skiphigh11
          mul   dx              ; - low(M2) * high(M1)
        skiphigh11:                  ; endif
        xchg    ax,cx           ; save that in cx, get high(M2)
        or      ax,ax           ; if high(M2) non-zero
        je skiphigh12              ; then
          mul   bx              ; - high(M2) * low(M1)
          add   cx,ax           ; - add to total
        skiphigh12:                  ; endif
        pop     ax              ; restore low(M2)
        mul     bx              ; low(M2) * low(M1)
        add     dx,cx           ; add previously computed high part


mov   bx, word ptr [_ds_xfrac]
mov   cx, word ptr [bp - 28h]
add   bx, ax
mov   word ptr [bp - 22h], bx
mov   word ptr [bp - 8], bx
mov   bx, di
mov   ax, word ptr [_ds_xfrac + 2]
adc   ax, dx
mov   dx, word ptr [_ds_ystep + 2]
mov   word ptr [bp - 26h], ax
mov   word ptr [bp - 01ah], ax
mov   ax, word ptr [_ds_ystep]


; inline i4m

 		xchg    ax,bx           ; swap low(M1) and low(M2)
        push    ax              ; save low(M2)
        xchg    ax,dx           ; exchange low(M2) and high(M1)
        or      ax,ax           ; if high(M1) non-zero
        je skiphigh21              ; then
          mul   dx              ; - low(M2) * high(M1)
        skiphigh21:                  ; endif
        xchg    ax,cx           ; save that in cx, get high(M2)
        or      ax,ax           ; if high(M2) non-zero
        je skiphigh22              ; then
          mul   bx              ; - high(M2) * low(M1)
          add   cx,ax           ; - add to total
        skiphigh22:                  ; endif
        pop     ax              ; restore low(M2)
        mul     bx              ; low(M2) * low(M1)
        add     dx,cx           ; add previously computed high part


mov   bx, word ptr [_ds_yfrac]
add   bx, ax
mov   ax, word ptr [bp - 22h]
mov   word ptr [bp - 24h], bx
mov   di, word ptr [_ds_yfrac + 2]
adc   di, dx
mov   dx, word ptr [bp - 26h]
mov   word ptr [bp - 0ah], di
mov   cl, 0ah
shr   bx, cl
ror   di, cl
xor   bx, di
and   di, 003fh
xor   bx, di
mov   cl, 8
shr   ax, cl
ror   dx, cl
xor   ax, dx
and   dx, 00ffh
xor   ax, dx
mov   di, word ptr [_ds_xstep + 2]
mov   dx, ax
mov   ax, word ptr [_ds_xstep]
mov   cx, 6
loop1:
sar   di, 1
rcr   ax, 1
loop  loop1
mov   di, word ptr [_ds_ystep + 2]
mov   word ptr [bp - 6], ax
mov   ax, word ptr [_ds_ystep]
mov   cx, 8
loop2:
sar   di, 1
rcr   ax, 1
loop  loop2
mov   word ptr [bp - 18h], ax
cmp   word ptr [bp - 4], 10h
jge   label6
jmp   label7
label6:
mov   al, dh
mov   di, word ptr [_ds_source]
and   al, 3fh
mov   word ptr [bp - 20h], di
CBW  
mov   di, word ptr [_ds_source + 2]
mov   cx, ax
mov   word ptr [bp - 0ch], di
mov   ax, bx
mov   es, di
and   ax, 0FC0h
mov   di, word ptr [bp - 20h]
add   ax, cx
add   di, ax
mov   ax, word ptr [_ds_colormap]
mov   cl, byte ptr es:[di]
mov   word ptr [bp - 2], ax
xor   ch, ch
mov   ax, word ptr [_ds_colormap + 2]
mov   di, word ptr [bp - 2]
mov   es, ax
add   di, cx
mov   word ptr [bp - 16h], ax
mov   al, byte ptr es:[di]
mov   es, word ptr [bp - 12h]
add   dx, word ptr [bp - 6]
mov   byte ptr es:[si], al
mov   al, dh
and   al, 3fh
CBW  
add   bx, word ptr [bp - 18h]
mov   cx, ax
mov   ax, bx
and   ax, 0FC0h
mov   di, word ptr [bp - 20h]
add   ax, cx
mov   es, word ptr [bp - 0ch]
add   di, ax
mov   al, byte ptr es:[di]
mov   di, word ptr [bp - 2]
xor   ah, ah
mov   es, word ptr [bp - 16h]
add   di, ax
mov   al, byte ptr es:[di]
mov   es, word ptr [bp - 12h]
add   dx, word ptr [bp - 6]
mov   byte ptr es:[si + 1], al
mov   al, dh
and   al, 3fh
CBW  
add   bx, word ptr [bp - 18h]
mov   cx, ax
mov   ax, bx
and   ax, 0FC0h
mov   di, word ptr [bp - 20h]
add   ax, cx
mov   es, word ptr [bp - 0ch]
add   di, ax
mov   al, byte ptr es:[di]
mov   di, word ptr [bp - 2]
xor   ah, ah
mov   es, word ptr [bp - 16h]
add   di, ax
add   dx, word ptr [bp - 6]
mov   al, byte ptr es:[di]
mov   es, word ptr [bp - 12h]
add   bx, word ptr [bp - 18h]
mov   byte ptr es:[si + 2], al
mov   al, dh
mov   di, bx
and   al, 3fh
and   di, 0FC0h
CBW  
add   ax, di
mov   di, word ptr [bp - 20h]
mov   es, word ptr [bp - 0ch]
add   di, ax
mov   al, byte ptr es:[di]
mov   di, word ptr [bp - 2]
xor   ah, ah
mov   es, word ptr [bp - 16h]
add   di, ax
add   bx, word ptr [bp - 18h]
mov   al, byte ptr es:[di]
mov   es, word ptr [bp - 12h]
add   dx, word ptr [bp - 6]
mov   byte ptr es:[si + 3], al
mov   al, dh
mov   di, bx
and   al, 3fh
and   di, 0FC0h
CBW  
add   ax, di
mov   di, word ptr [bp - 20h]
mov   es, word ptr [bp - 0ch]
add   di, ax
mov   al, byte ptr es:[di]
mov   di, word ptr [bp - 2]
xor   ah, ah
mov   es, word ptr [bp - 16h]
add   di, ax
add   bx, word ptr [bp - 18h]
mov   al, byte ptr es:[di]
mov   es, word ptr [bp - 12h]
add   dx, word ptr [bp - 6]
mov   byte ptr es:[si + 4], al
mov   al, dh
mov   di, bx
and   al, 3fh
and   di, 0FC0h
CBW  
add   ax, di
mov   di, word ptr [bp - 20h]
mov   es, word ptr [bp - 0ch]
add   di, ax
mov   al, byte ptr es:[di]
mov   di, word ptr [bp - 2]
xor   ah, ah
mov   es, word ptr [bp - 16h]
add   di, ax
mov   al, byte ptr es:[di]
mov   es, word ptr [bp - 12h]
mov   byte ptr es:[si + 5], al
add   dx, word ptr [bp - 6]
mov   al, dh
and   al, 3fh
CBW  
add   bx, word ptr [bp - 18h]
mov   cx, ax
mov   ax, bx
and   ax, 0FC0h
mov   di, word ptr [bp - 20h]
add   ax, cx
mov   es, word ptr [bp - 0ch]
add   di, ax
mov   al, byte ptr es:[di]
mov   di, word ptr [bp - 2]
xor   ah, ah
mov   es, word ptr [bp - 16h]
add   di, ax
mov   al, byte ptr es:[di]
mov   es, word ptr [bp - 12h]
add   dx, word ptr [bp - 6]
mov   byte ptr es:[si + 6], al
mov   al, dh
and   al, 3fh
CBW  
add   bx, word ptr [bp - 18h]
mov   cx, ax
mov   ax, bx
and   ax, 0FC0h
mov   di, word ptr [bp - 20h]
add   ax, cx
mov   es, word ptr [bp - 0ch]
add   di, ax
mov   al, byte ptr es:[di]
mov   di, word ptr [bp - 2]
xor   ah, ah
mov   es, word ptr [bp - 16h]
add   di, ax
mov   al, byte ptr es:[di]
mov   es, word ptr [bp - 12h]
add   dx, word ptr [bp - 6]
mov   byte ptr es:[si + 7], al
mov   al, dh
and   al, 3fh
CBW  
add   bx, word ptr [bp - 18h]
mov   cx, ax
mov   ax, bx
and   ax, 0FC0h
mov   di, word ptr [bp - 20h]
add   ax, cx
mov   es, word ptr [bp - 0ch]
add   di, ax
mov   al, byte ptr es:[di]
mov   di, word ptr [bp - 2]
xor   ah, ah
mov   es, word ptr [bp - 16h]
add   di, ax
add   dx, word ptr [bp - 6]
mov   al, byte ptr es:[di]
mov   es, word ptr [bp - 12h]
add   bx, word ptr [bp - 18h]
mov   byte ptr es:[si + 8], al
mov   al, dh
mov   di, bx
and   al, 3fh
and   di, 0FC0h
CBW  
add   ax, di
mov   di, word ptr [bp - 20h]
mov   es, word ptr [bp - 0ch]
add   di, ax
mov   al, byte ptr es:[di]
mov   di, word ptr [bp - 2]
xor   ah, ah
mov   es, word ptr [bp - 16h]
add   di, ax
add   bx, word ptr [bp - 18h]
mov   al, byte ptr es:[di]
mov   es, word ptr [bp - 12h]
add   dx, word ptr [bp - 6]
mov   byte ptr es:[si + 9], al
mov   al, dh
mov   di, bx
and   al, 3fh
and   di, 0FC0h
CBW  
add   ax, di
mov   di, word ptr [bp - 20h]
mov   es, word ptr [bp - 0ch]
add   di, ax
mov   al, byte ptr es:[di]
mov   di, word ptr [bp - 2]
xor   ah, ah
mov   es, word ptr [bp - 16h]
add   di, ax
add   bx, word ptr [bp - 18h]
mov   al, byte ptr es:[di]
mov   es, word ptr [bp - 12h]
add   dx, word ptr [bp - 6]
mov   byte ptr es:[si + 0ah], al
mov   al, dh
mov   di, bx
and   al, 3fh
and   di, 0FC0h
CBW  
add   ax, di
mov   di, word ptr [bp - 20h]
mov   es, word ptr [bp - 0ch]
add   di, ax
mov   al, byte ptr es:[di]
mov   di, word ptr [bp - 2]
xor   ah, ah
mov   es, word ptr [bp - 16h]
add   di, ax
mov   al, byte ptr es:[di]
mov   es, word ptr [bp - 12h]
mov   byte ptr es:[si + 0bh], al
add   dx, word ptr [bp - 6]
mov   al, dh
and   al, 3fh
CBW  
add   bx, word ptr [bp - 18h]
mov   cx, ax
mov   ax, bx
and   ax, 0FC0h
mov   di, word ptr [bp - 20h]
add   ax, cx
mov   es, word ptr [bp - 0ch]
add   di, ax
mov   al, byte ptr es:[di]
mov   di, word ptr [bp - 2]
xor   ah, ah
mov   es, word ptr [bp - 16h]
add   di, ax
add   dx, word ptr [bp - 6]
mov   al, byte ptr es:[di]
mov   es, word ptr [bp - 12h]
add   bx, word ptr [bp - 18h]
mov   byte ptr es:[si + 0ch], al
mov   al, dh
mov   di, bx
and   al, 3fh
and   di, 0FC0h
CBW  
add   ax, di
mov   di, word ptr [bp - 20h]
mov   es, word ptr [bp - 0ch]
add   di, ax
mov   al, byte ptr es:[di]
mov   di, word ptr [bp - 2]
xor   ah, ah
mov   es, word ptr [bp - 16h]
add   di, ax
add   bx, word ptr [bp - 18h]
mov   al, byte ptr es:[di]
mov   es, word ptr [bp - 12h]
add   dx, word ptr [bp - 6]
mov   byte ptr es:[si + 0dh], al
mov   al, dh
mov   di, bx
and   al, 3fh
and   di, 0FC0h
CBW  
add   ax, di
mov   di, word ptr [bp - 20h]
mov   es, word ptr [bp - 0ch]
add   di, ax
mov   al, byte ptr es:[di]
mov   di, word ptr [bp - 2]
xor   ah, ah
mov   es, word ptr [bp - 16h]
add   di, ax
mov   al, byte ptr es:[di]
mov   es, word ptr [bp - 12h]
add   dx, word ptr [bp - 6]
mov   byte ptr es:[si + 0eh], al
mov   al, dh
add   bx, word ptr [bp - 18h]
and   al, 3fh
and   bx, 0FC0h
CBW  
add   ax, bx
mov   bx, word ptr [bp - 20h]
mov   es, word ptr [bp - 0ch]
add   bx, ax
mov   al, byte ptr es:[bx]
mov   bx, word ptr [bp - 2]
xor   ah, ah
mov   es, word ptr [bp - 16h]
add   bx, ax
mov   al, byte ptr es:[bx]
mov   es, word ptr [bp - 12h]
sub   word ptr [bp - 4], 10h
mov   byte ptr es:[si + 0fh], al
mov   ax, word ptr [bp - 10h]
add   si, 10h
add   word ptr [bp - 8], ax
mov   ax, word ptr [bp - 0eh]
adc   word ptr [bp - 1ah], ax
mov   ax, word ptr [bp - 14h]
mov   dx, word ptr [bp - 1ah]
add   word ptr [bp - 24h], ax
mov   ax, word ptr [bp - 1eh]
adc   word ptr [bp - 0ah], ax
mov   ax, word ptr [bp - 8]
mov   cl, 8
shr   ax, cl
ror   dx, cl
xor   ax, dx
and   dx, 00ffh
xor   ax, dx
mov   bx, word ptr [bp - 0ah]
mov   dx, ax
mov   ax, word ptr [bp - 24h]
mov   cl, 0ah
shr   ax, cl
ror   bx, cl
xor   ax, bx
and   bx, 3fh
xor   ax, bx
mov   bx, ax
cmp   word ptr [bp - 4], 10h
jl    label7
jmp   label6
label7:
mov   al, dh
mov   di, bx
and   al, 3fh
and   di, 0fc0h
CBW  
dec   word ptr [bp - 4]
add   ax, di
les   di,  [_ds_source]
add   di, ax
inc   si
mov   al, byte ptr es:[di]
mov   di, word ptr [_ds_colormap]
xor   ah, ah
mov   es, word ptr [_ds_colormap + 2]
add   di, ax
add   dx, word ptr [bp - 6]
mov   al, byte ptr es:[di]
mov   es, word ptr [bp - 12h]
add   bx, word ptr [bp - 18h]
mov   byte ptr es:[si - 1], al
cmp   word ptr [bp - 4], -1
jne   label7
label2:
inc   word ptr [bp - 1ch]
cmp   word ptr [bp - 1ch], 4
jge   label3
jmp   label4
label3:
leave 
pop   di
pop   si
pop   dx
pop   cx
pop   bx
retf  
cld   

ENDP

END
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

EXTRN   _ds_colormap_index:BYTE
EXTRN   _ds_colormap_segment:WORD


EXTRN   _detailshift:BYTE
EXTRN   _quality_port_lookup:BYTE


EXTRN	_ds_xstep:DWORD
EXTRN	_ds_ystep:DWORD

EXTRN   _sp_bp_safe_space:WORD
EXTRN   _ss_variable_space:WORD

EXTRN _spanfunc_main_loop_count:BYTE
EXTRN _spanfunc_inner_loop_count:BYTE
EXTRN _spanfunc_outp:BYTE
EXTRN _spanfunc_prt:WORD
EXTRN _spanfunc_destview_offset:WORD

EXTRN FixedMul_:PROC

; jump table is 0 offset at this segment
SPANFUNC_JUMP_LOOKUP_SEGMENT = 6EA0h
; offset of the jmp instruction's immediate from the above segment
SPANFUNC_JUMP_OFFSET     =   1EAh

COLFUNC_JUMP_LOOKUP      =   6A10h
COLFUNC_JUMP_OFFSET      =   075h

DC_YL_LOOKUP_SEGMENT =  6A29h

DISTSCALE_SEGMENT = 9032h
FINESINE_SEGMENT = 31e4h
 
COLFUNC_FUNCTION_AREA_SEGMENT = 6A42h

CACHEDHEIGHT_SEGMENT = 9082h
CACHEDDISTANCE_SEGMENT = 90b4h
CACHEDYSTEP_SEGMENT = 9118h
CACHEDXSTEP_SEGMENT = 90e6h
SPANFUNC_FUNCTION_AREA_SEGMENT = 6eaah
SPANFUNC_PREP_OFFSET = 0717h
BASE_COLORMAP_POINTER = 6800h
XTOVIEWANGLE_SEGMENT = 833bh

EXTRN _basexscale:WORD
EXTRN _planezlight:WORD
EXTRN _fixedcolormap:BYTE
EXTRN _viewx:WORD
EXTRN _viewy:WORD
EXTRN _baseyscale:WORD
EXTRN _basexscale:WORD
EXTRN _viewangle_shiftright3:WORD
EXTRN _centeryfrac_shiftright4:WORD
EXTRN _planeheight:WORD



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
    add   di, word ptr [_destview + 0] 		 ; add destview offset
    cwd                         			 ; we know ax is positive, this is a quick clear out of dx
    mov   bx, word ptr [_dc_iscale + 0]   
    mov   cx, word ptr [_dc_iscale + 2]
    ;  NOTE using this flag for the jns later
    sub   ax, word ptr [_centery]


    mov     es,ax              ; save low(M1)

;  DX:AX * CX:BX

; note this is 8 bit times 32 bit and we want the mid 16

; todo figure out how to do this without a jump


	CWD
	AND DX, BX
	NEG DX



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
mov   si, DC_YL_LOOKUP_SEGMENT               ; store this segment
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
mov   ax, COLFUNC_JUMP_LOOKUP                ; segment of jump offset table
add   ax, di                                 ; add argument offset to the ax address
mov   word ptr [_dc_yl_lookup_val], bx       ; store pre-calculated dc_yl * 80
mov   es, ax
mov   bx, COLFUNC_JUMP_OFFSET                ; location of jump relative instruction's immediate
mov   ax, word ptr es:[si]                   ; 
add   di, COLFUNC_FUNCTION_AREA_SEGMENT      ; R_DrawColumn segment with 0 indexed function offset
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
mov   word ptr [bp - 4], bx				; setup dynamic call
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
mov   word ptr [bp - 4], bx				; setup dynamic call
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

; stack vars
 
; _ss_variable_space
;
; 00h i (outer loop counter)
; 02h count (inner iterator)
; 04h x_frac.w high bits   [ load 05 to get mid 16 bits for "free"]
; 06h x_frac.w low bits
; 08h x32step  high bits
; 0Ah x32step  low bits
; 0Ch y_frac.w high bits
; 0Eh y_frac.w low bits
; 10h y32step high 16 bits
; 12h y32step low  16 bits

push  bx
push  cx
push  dx
push  si
push  di
push  bp
mov   bp, sp
cli 									; disable interrupts

; fixed_t x32step = (ds_xstep << 6);

mov   ax, word ptr [_ds_xstep]          ; dx:ax is ds_xstep
mov   dx, word ptr [_ds_xstep + 2]      

; dx:ax	shift 6 left by shifting right 2 and moving bytes

ror dx, 1
rcr ax, 1
rcr bh, 1   ; spillover into bh
ror dx, 1
rcr ax, 1
rcr bh, 1
mov dh, dl
mov dl, ah
mov ah, al
mov al, bh   ; spillover back into al
and al, 0C0h  ; keep two high bits



mov   word ptr [_ss_variable_space + 08h], ax			;  move x32step low  bits into _ss_variable_space + 08h
mov   word ptr [_ss_variable_space + 0Ah], dx			;  move x32step high bits into _ss_variable_space + 0Ah

;	fixed_t y32step = (ds_ystep << 6);

mov   ax, word ptr [_ds_ystep]			; same process as above
mov   dx, word ptr [_ds_ystep + 2]

; dx:ax	shift 6 left by shifting right 2 and moving bytes

ror dx, 1
rcr ax, 1
rcr bh, 1   ; spillover into bh
ror dx, 1
rcr ax, 1
rcr bh, 1
mov dh, dl
mov dl, ah
mov ah, al
mov al, bh   ; spillover back into al
and al, 0C0h  ; keep two high bits

mov   word ptr [_ss_variable_space + 12h], ax			;  move y32step low  bits into _ss_variable_space + 12h
mov   word ptr [_ss_variable_space + 10h], dx			;  move y32step high bits into _ss_variable_space + 10h

; main loop start (i = 0, 1, 2, 3)

xor   cx, cx						; zero out cx as loopcount
mov   word ptr [_ss_variable_space], 0			;  move 0  into i (outer loop counter)
span_i_loop_repeat:

mov   bx, cx
xor   ah, ah
mov   al, byte ptr [_spanfunc_outp + bx]
mov   dx, 3c5h						; outp 1 << i
out   dx, al

mov   al, byte ptr [_spanfunc_inner_loop_count + bx]



test  al, al					

; is count < 0? if so skip this loop iter

jge   at_least_one_pixel			; todo this so it doesnt loop in both cases
jmp   do_span_loop
at_least_one_pixel:

;       modify the jump for this iteration (self-modifying code)
mov   DX, SPANFUNC_JUMP_LOOKUP_SEGMENT
MOV   ES, DX
sal   AL, 1					; convert index to  a word lookup index
xchg  ax, SI

lods  WORD PTR ES:[SI]		; <--- this doesnt work, becomes ES:SI, tasm doesnt warn you. left as a warning for future generations
;mov  AX, WORD PTR ES:[DI]		; gets the jump amount from the jump lookup

MOV   DI, SPANFUNC_JUMP_OFFSET
stos  WORD PTR es:[di]       ;

; 		dest = destview + ds_y * 80 + dsp_x1;
sal   bx, 1
mov   ax, word ptr [_spanfunc_prt + bx]
mov   DI, word ptr [_spanfunc_destview_offset + bx]  ; destview offset precalculated..


;		xfrac.w = basex = ds_xfrac + ds_xstep * prt;

CWD   				; extend sign into DX

;  DX:AX contains sign extended prt. 
;  probably dont really need this. can test ax and jge

mov   si, ax						; temporarily store dx:ax into es:si
mov   es, dx						; store sign bits (dx) in es
mov   bx, ax
mov   cx, dx						; also copy sign bits to cx
mov   ax, word ptr [_ds_xstep]
mov   dx, word ptr [_ds_xstep + 2]

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



mov   bx, word ptr [_ds_xfrac]	; load _ds_xfrac
mov   cx, es					; retrieve prt sign bits
add   bx, ax					; ds_xfrac + ds_xstep * prt low bits
mov   word ptr [_ss_variable_space + 04h], bx		; store low 16 bits of x_frac.w
mov   bx, si
mov   ax, word ptr [_ds_xfrac + 2]  ; ; ds_xfrac + ds_xstep * prt high bits
adc   ax, dx

mov   dx, word ptr [_ds_ystep + 2]
mov   word ptr [_ss_variable_space + 06h], ax  ; store high 16 bits of x_frac.w
mov   ax, word ptr [_ds_ystep]


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
mov   bx, word ptr [_ds_yfrac]	; load ds_yfrac
add   bx, ax					; create y_frac low bits...
mov   word ptr [_ss_variable_space + 0Eh], bx	; store y_frac low bits
mov   si, word ptr [_ds_yfrac + 2]
adc   si, dx

;	xfrac16.hu = xfrac.wu >> 8;

mov   word ptr [_ss_variable_space + 0Ch], si	;  store high bits of yfrac in _ss_variable_space + 0Ch  
mov   ax, si					;  copy to ax so we can byte manip

;	yfrac16.hu = yfrac.wu >> 10;

mov bl, bh
mov   ax, word ptr [_ss_variable_space + 0Ch]  ; move high 16 bits of yfrac into ax
mov bh, al   ; shift 8

sar ah, 1    ; shift two more
rcr bx, 1
sar ah, 1
rcr bx, 1    ; yfrac16 in bx



; shift 8, yadder in dh?

mov dx, word ptr [_ss_variable_space + 05h]   ;  load high 16 bits of x_frac.w


;	xadder = ds_xstep >> 6; 

mov   cx, word ptr [_ds_xstep + 2]
mov   ax, word ptr [_ds_xstep]


; quick shift 6
rol   ax, 1
rcl   cl, 1
rol   ax, 1
rcl   cl, 1

mov   al, ah
mov   ah, cl

; do loop setup here?

mov cl, byte ptr [_detailshift]
shr ax, cl			; shift x_step by pixel shift
 

mov   word ptr [_sp_bp_safe_space], ax	; store x_adder

;	yadder = ds_ystep >> 8; // lopping off bottom 16 , but multing by 4.

mov   ax, word ptr [_ds_ystep + 1]



shr ax, cl			; shift y_step by pixel shift
mov   word ptr [_sp_bp_safe_space + 2], ax	; y_adder



mov   es, word ptr [_destview + 2]	; retrieve destview segment
mov   si, word ptr ss:[_ds_source_segment] 		; ds:si is ds_source
mov   ds, si
mov   cx, bx

; we have a safe memory space declared in near variable space to put sp/bp values
; they meanwhile hold x_adder/y_adder and we juggle the two
; due to openwatcom compilation, SS = DS so we can use SS as if it were DS to address the var safely


; stack shenanigans. adders in sp/bp
mov   bx, OFFSET _sp_bp_safe_space  ; 
xchg  ss:[bx], sp             ;  store SP and load x_adder
inc   bx
inc   bx
xchg  ss:[bx], bp			  ;   store BP and load y_adder

mov   bx, 0FC0h
xor   ah, ah

 
jmp_addr_2:
jmp span_i_loop_done         ; relative jump to be modified before function is called



 








; 89 C8       mov   ax, cx
; 21 D8       and   ax, bx
; 80 E6 3F    and   dh, 0x3f
; 00 F0       add   al, dh
; 97          xchg  ax, di

; alternate idea. one cycle slower and same byte count.
; cant we somehow make use of xchg and al, 3fh at the same time?

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

mov   al, dh
and   al, 3fh
mov   si, cx
and   si, bx
add   si, ax
lods  BYTE PTR ds:[si]
xlat  BYTE PTR cs:[bx]       ; before calling this function we already set CS to the correct segment..
stos  BYTE PTR es:[di]       ;



;			xfrac.w += x32step;

;mov   ax, word ptr ss:[_ss_variable_space + 08h]   ; load low 16 bits of x32step
;add   word ptr ss:[_ss_variable_space + 04h], ax   ; add low 16 bits of xstep into low 16 bits xfrac
;mov   ax, word ptr ss:[_ss_variable_space + 0Ah]   ; load high 16 bits of x32step into ax
;adc   word ptr ss:[_ss_variable_space + 06h], ax   ; add with carry into high 16 bits of xfrac

;			xfrac16.hu = xfrac.wu >> 8;

;mov   dx, word ptr ss:[_ss_variable_space + 05h]   ; grab middle 16 bits of xfrac to get the shifted 8


; 			yfrac.w += y32step;
; i wonder if its better to order these so reads are sequential (?)

;mov   ax, word ptr ss:[_ss_variable_space + 12h]   ; load low 16 bits of y32step
;add   word ptr ss:[_ss_variable_space + 0Eh], ax	; add low 16 bits of ystep into low 16 bits yfrac
;mov   ax, word ptr ss:[_ss_variable_space + 10h]   ; load high 16 bits of y32step 
;adc   word ptr ss:[_ss_variable_space + 0Ch], ax   ; add with carry into high 16 bits of yfrac



;			yfrac16.hu = yfrac.wu >> 10;

; byte ptr fine?
;mov   bx, word ptr ss:[_ss_variable_space + 0Eh]  ; move low 16 bits of yfrac into bx

;mov bl, bh
;mov   ax, word ptr ss:[_ss_variable_space + 0Ch]  ; move high 16 bits of yfrac into ax
;mov bh, al   ; shift 8

;sar ah, 1    ; shift two more
;rcr bx, 1
;sar ah, 1
;rcr bx, 1    ; yfrac16 in bx

;mov   cx, bx
;mov   bx, 0FC0h
;xor   ah, ah

 

; restore stack
mov   bx, OFFSET _sp_bp_safe_space; 
xchg  ss:[bx], sp             ;  restore sp
inc   bx
inc   bx
xchg  ss:[bx], bp			;   restore BP
mov   ax, ss					;   SS is DS in this watcom memory model so we use that to restore DS
mov   ds, ax

do_span_loop:

xor   cx, cx
mov   cl, byte ptr ss:[_ss_variable_space]
inc   cl						; increment i

; loop if i < loopcount. note we can overwrite this with self modifying coe
cmp   cl, byte ptr ds:[_spanfunc_main_loop_count]	
jge   span_i_loop_done
mov   byte ptr ss:[_ss_variable_space], cl		; ch was 0 or above. store result

jmp   span_i_loop_repeat
span_i_loop_done:


sti								; reenable interrupts
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
; R_DrawSpanPrep
;
	
PROC  R_DrawSpanPrep_
PUBLIC  R_DrawSpanPrep_ 

 push  bx
 push  cx
 push  dx
 push  si
 push  di
 push  bp
 mov   bp, sp
 sub   sp, 6
 
 ;  	uint16_t baseoffset = FP_OFF(destview) + dc_yl_lookup[ds_y];

 mov   ax, DC_YL_LOOKUP_SEGMENT			; calculating base view offset 
 mov   bx, word ptr [_ds_y]
 mov   es, ax
 add   bx, bx
 mov   ax, word ptr [_destview]			; get FP_OFF(destview)
 mov   dx, word ptr es:[bx]				; get dc_yl_lookup[ds_y]
 mov   bh, 2
 add   dx, ax							; dx is baseoffset
 mov   es, word ptr [_ds_x1]			; es holds ds_x1
	
; int8_t   shiftamount = (2-detailshift);
 sub   bh, byte ptr [_detailshift]		; get shiftamount in bh
 mov   word ptr [bp - 2], dx			; store base view offset
 xor   bl, bl							; zero out bl. use it as loop counter/ i
 
 cmp   byte ptr [_spanfunc_main_loop_count], 0		; if shiftamount is equal to zero
 jle   spanfunc_arg_setup_complete
 spanfunc_arg_setup_loop_start:
 mov   al, bl							; al holds loop counter
 mov   dx, es							; get ds_x1
 CBW  									; zero out ah
 mov   cl, bh							; move shiftamount to cl

;		int16_t dsp_x1 = (ds_x1 - i) >> shiftamount;
 sub   dx, ax							; subtract i 
 sar   dx, cl							; shift

; 		int16_t dsp_x2 = (ds_x2 - i) >> shiftamount;

 mov   cx, word ptr [_ds_x2]			; cx holds ds_x2
 sub   cx, ax							; subtract i
 mov   si, ax							; put i in si
 mov   di, cx							; store ds_x2 - i on di
 mov   ax, dx							; copy dsp_x1 to ax
 mov   cl, bh							; move shiftamount to cl
 shl   ax, cl							; shift dsp_x1 left
 sar   di, cl							; shift ds_x2 right. di = dsp_x2
 mov   cx, di							; store dsp_x2 in cx
 mov   di, es							; get ds_x1 into di

;		if ((dsp_x1 << shiftamount) + i < ds_x1)

 add   si, ax							; si = (dsp_x1 << shiftamount) + i
 cmp   si, di			; if si <  (dsp_x1 << shiftamount) + i
 jge   dont_increment_ds_x1
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
 add   dx, word ptr [bp - 2]						   ; dsp_x1 + base view offset
 mov   word ptr [si + _spanfunc_prt], ax			   ; store prt
 mov   word ptr [si + _spanfunc_destview_offset], dx   ; store view offset
 
 spanfunc_arg_setup_iter_done:
 
 inc   bl
 cmp   bl, byte ptr [_spanfunc_main_loop_count]
 jl    spanfunc_arg_setup_loop_start
 
 spanfunc_arg_setup_complete:

 ; calculate desired cs:ip for far jump

 mov   dx, word ptr [_ds_colormap_segment]
 mov   al, byte ptr [_ds_colormap_index]
 sub   dx, 0FCh
 test  al, al									; check _ds_colormap_index
 je    ds_colormap_zero
 
 ; colormap not zero. need to offset cs etc by its address

 ;		uint16_t ds_colormap_offset = ds_colormap_index << 8;
;		uint16_t ds_colormap_shift4 = ds_colormap_index << 4;
	 	
;		uint16_t cs_base = ds_colormap_segment - cs_source_segment_offset + ds_colormap_shift4;
;		uint16_t callfunc_offset = colormaps_spanfunc_off_difference + cs_source_offset - ds_colormap_offset;
;		dynamic_callfunc  =       ((void    (__far *)(void))  (MK_FP(cs_base, callfunc_offset)));

 
 xor   ah, ah
 mov   bx, ax
 shl   ax, 4
 shl   bx, 8
 add   dx, ax
 mov   ax, 07a60h
 sub   ax, bx
 mov   word ptr [bp - 4], dx
 mov   word ptr [bp - 6], ax
 
db 0FFh   ;lcall[bp-6]
db 05Eh
db 0FAh
 
 leave 
 pop   di
 pop   si
 pop   dx
 pop   cx
 pop   bx
 retf  
 ds_colormap_zero:									; if ds_colormap_index is 0
 
 ; easy address calculation
 
; 		uint16_t cs_base = ds_colormap_segment - cs_source_segment_offset;
;		uint16_t callfunc_offset = colormaps_spanfunc_off_difference + cs_source_offset;
;		dynamic_callfunc  =       ((void    (__far *)(void))  (MK_FP(cs_base, callfunc_offset)));

 
 mov   word ptr [bp - 4], dx
 mov   word ptr [bp - 6], 07a60h		; callfunc offset is 0x0FC0+colormaps_spanfunc_off_difference
 
db 0FFh   ;lcall[bp-6]
db 05Eh
db 0FAh
 
 leave 
 pop   di
 pop   si
 pop   dx
 pop   cx
 pop   bx
 retf  

ENDP



PROC R_FixedMulTrigLocal_
PUBLIC R_FixedMulTrigLocal_

; DX:AX  *  CX:BX
;  0  1      2  3

; with sign extend for byte 3:
; S0:DX:AX    *   S1:CX:BX
; S0 = DX sign extend
; S1 = CX sign extend

; DIFFERENT FROM FIXEDMUL - 
; DX is already a sign extend of AX

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
;CWD				; S0 is already equal to dx 

AND   DX, BX	; S0*BX
NEG   DX
mov   SI, DX	; DI stores hi word return

; AX still stores DX
AND  AX, CX    ; DX*CX
NEG  AX
add  SI, AX    ; low word result into high word return

mov  AX, DS    ; restore DX from ds
AND  AX, BX         ; DX*BX
NEG  AX
XCHG BX, AX    ; BX will hold low word return. store bx in ax


mov  DX, ES    ; restore AX from ES
mul  DX        ; BX*AX  
add  BX, DX    ; high word result into low word return
ADC  SI, 0

mov  AX, CX   ; AX holds CX
CWD           ; copy CX into S1

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





;
; R_MapPlane_
; void __far R_MapPlane ( byte y, int16_t x1, int16_t x2 )

	
PROC  R_MapPlane_
PUBLIC  R_MapPlane_ 

push  cx
push  si
push  di
push  bp
mov   bp, sp
sub   sp, 016h
mov   byte ptr [bp - 2], al
mov   word ptr [bp - 8], dx
mov   word ptr [bp - 0eh], bx
mov   word ptr [bp - 016h], SPANFUNC_PREP_OFFSET
mov   word ptr [bp - 014h], SPANFUNC_FUNCTION_AREA_SEGMENT
mov   bx, CACHEDHEIGHT_SEGMENT
xor   ah, ah
mov   dx, word ptr [_planeheight + 2]
mov   si, ax
mov   ax, word ptr [_planeheight]
shl   si, 2
mov   es, bx
mov   di, CACHEDDISTANCE_SEGMENT
cmp   dx, word ptr es:[si + 2]
je    jumpa
jumpe:
jmp   jumpb
jumpa:
cmp   ax, word ptr es:[si]
jne   jumpe
mov   es, di
mov   ax, word ptr es:[si]
mov   word ptr [bp - 0ch], ax
mov   ax, word ptr es:[si + 2]
mov   bx, CACHEDXSTEP_SEGMENT
mov   es, bx
mov   word ptr [bp - 0ah], ax
mov   ax, word ptr es:[si]
mov   dx, word ptr es:[si + 2]
mov   word ptr [_ds_xstep], ax
mov   word ptr [_ds_xstep+2], dx
mov   bx, CACHEDYSTEP_SEGMENT
mov   es, bx
mov   ax, word ptr es:[si]
mov   dx, word ptr es:[si + 2]
mov   word ptr [_ds_ystep], ax
mov   word ptr [_ds_ystep+2], dx
jumpd:
mov   bx, word ptr [bp - 8]
mov   ax, DISTSCALE_SEGMENT
shl   bx, 2
mov   es, ax
mov   dx, word ptr [bp - 0ah]
mov   ax, word ptr es:[bx]
mov   cx, word ptr es:[bx + 2]
mov   bx, ax
mov   ax, word ptr [bp - 0ch]

;call FAR PTR FixedMul_ 
call R_FixedMulLocal_


mov   bx, word ptr [bp - 8]
mov   di, ax
mov   ax, XTOVIEWANGLE_SEGMENT
add   bx, bx
mov   es, ax
mov   ax, word ptr [_viewangle_shiftright3]
add   ax, word ptr es:[bx]
and   ah, 01fh
shl   ax, 2
mov   si, dx
mov   word ptr [bp - 012h], ax
mov   ax, FINESINE_SEGMENT
mov   bx, word ptr [bp - 012h]
mov   es, ax
add   bh, 020h
mov   cx, si
mov   ax, word ptr es:[bx]
mov   dx, word ptr es:[bx + 2]
mov   bx, di

;call FAR PTR FixedMul_ 
call R_FixedMulLocal_

mov   bx, word ptr [_viewx]
mov   word ptr [bp - 010h], bx
mov   bx, word ptr [_viewx+2]
add   ax, word ptr [bp - 010h]
mov   word ptr [_ds_xfrac], ax
adc   dx, bx
mov   ax, FINESINE_SEGMENT
mov   bx, word ptr [bp - 012h]
mov   word ptr [_ds_xfrac+2], dx
mov   es, ax
mov   cx, si
mov   ax, word ptr es:[bx]
mov   dx, word ptr es:[bx + 2]
mov   bx, di

;call FAR PTR FixedMul_ 
call R_FixedMulLocal_

mov   bx, ax
mov   ax, word ptr [_viewy+2]
mov   cx, word ptr [_viewy]
neg   ax
neg   cx
sbb   ax, 0
sub   cx, bx
sbb   ax, dx
mov   word ptr [_ds_yfrac], cx
mov   word ptr [_ds_yfrac+2], ax
cmp   byte ptr [_fixedcolormap], 0
jne   jumpf
mov   ax, word ptr [bp - 0ah]
sar   ax, 4
mov   ah, al
cmp   al, 080h
jb    jumpg
mov   ah, 07fh
jumpg:
mov   word ptr [_ds_colormap_segment], BASE_COLORMAP_POINTER
mov   al, ah
mov   bx, word ptr [_planezlight]
xor   ah, ah
mov   es, word ptr [_planezlight+2]
add   bx, ax
mov   al, byte ptr es:[bx]
jumpc:
mov   byte ptr [_ds_colormap_index], al
mov   al, byte ptr [bp - 2]
xor   ah, ah
mov   word ptr [_ds_y], ax
mov   ax, word ptr [bp - 8]
mov   word ptr [_ds_x1], ax
mov   ax, word ptr [bp - 0eh]
mov   word ptr [_ds_x2], ax
;lcall [bp - 016h]   TODO call direct
db 0FFh   ;lcall[bp-16]
db 05Eh
db 0EAh
; ?? why doesnt this work
; push cs
; lcall 0x6EEA:0x0717 (SPANFUNC_FUNCTION_AREA_SEGMENT:SPANFUNC_PREP_OFFSET)
;db 00Eh
;db 09Ah
;db 017h
;db 007h
;db 0EAh 
;db 06Eh

leave 
pop   di
pop   si
pop   cx
retf  
jumpf:
mov   al, byte ptr [_fixedcolormap]
mov   word ptr [_ds_colormap_index], BASE_COLORMAP_POINTER
jmp   jumpc
jumpb:
mov   word ptr es:[si], ax
mov   bx, 9000h
mov   word ptr es:[si + 2], dx
mov   es, bx
mov   bx, word ptr es:[si]
mov   cx, word ptr es:[si + 2]

;call FAR PTR FixedMul_ 
call R_FixedMulLocal_

mov   es, di
mov   word ptr [bp - 0ah], dx
mov   bx, word ptr [_basexscale]
mov   cx, word ptr [_basexscale+2]
mov   word ptr es:[si], ax
mov   di, dx
mov   ax, word ptr es:[si]
mov   word ptr es:[si + 2], dx
mov   word ptr [bp - 010h], ax
mov   word ptr [bp - 0ch], ax

;call FAR PTR FixedMul_ 
call R_FixedMulLocal_

mov   bx, CACHEDXSTEP_SEGMENT
mov   es, bx
mov   bx, word ptr [_baseyscale]
mov   word ptr es:[si], ax
mov   cx, word ptr [_baseyscale+2]
mov   word ptr es:[si + 2], dx
mov   word ptr [_ds_xstep+2], dx
mov   ax, word ptr es:[si]
mov   dx, di
mov   word ptr [_ds_xstep], ax
mov   ax, word ptr [bp - 010h]

;call FAR PTR FixedMul_ 
call R_FixedMulLocal_

mov   bx, CACHEDYSTEP_SEGMENT
mov   es, bx
mov   word ptr es:[si], ax
mov   word ptr es:[si + 2], dx
mov   dx, word ptr es:[si]
mov   ax, word ptr es:[si + 2]
mov   word ptr [_ds_ystep], dx
mov   word ptr [_ds_ystep+2], ax
jmp   jumpd
cld   

ENDP

END
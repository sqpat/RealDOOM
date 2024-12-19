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

.DATA



; for the 6th colormap (used in fuzz draws. offset by 600h bytes, or 60h segments)

COLORMAPS_6_MASKEDMAPPING_SEG_DIFF_SEGMENT = (COLORMAPS_SEGMENT_MASKEDMAPPING + 060h)
 
; 5472 or 0x1560
COLORMAPS_MASKEDMAPPING_SEG_OFFSET_IN_CS = 16 * (COLORMAPS_6_MASKEDMAPPING_SEG_DIFF_SEGMENT - DRAWFUZZCOL_AREA_SEGMENT)




;=================================

.CODE




;
; R_DrawFuzzColumn
;
	
PROC  R_DrawFuzzColumn_ 
PUBLIC  R_DrawFuzzColumn_ 

; todo:
; could write sp somehwere and use it as 64h for si comps. 

; arguments: 
; bx is equal to destview + 2 (screen segment)... any reason to not do it in here?
; cx is offset to screen segment
; di has count. note that this is an 8 bit value. (screen height max of 240)
; ideally di and cx get swapped...

push si
push di
push es
mov  es, bx
mov  bl, byte ptr ds:[_fuzzpos]	; note this is always the byte offset - no shift conversion necessary
xor  bh, bh
mov  si, bx
;  need to put di in cx
xchg cx, di   ; cx gets count , di gets screen offset
; todo what does this todo mean
; todo dont need segment... use the variable offset and store in di
mov  ax, FUZZOFFSET_SEGMENT
mov  ds, ax
; constant space
mov  dx, 04Fh
mov  ch, 010h

; todo: store count in cx not di?

cli
push bp
mov  bp, COLORMAPS_MASKEDMAPPING_SEG_OFFSET_IN_CS





cmp  cl, ch
jg   draw_16_fuzzpixels
jmp  done_drawing_16_fuzzpixels
draw_16_fuzzpixels:



DRAW_SINGLE_FUZZPIXEL MACRO 



lodsw     						; load fuzz offset...
mov  bx, ax	       				; move offset to bx.
mov  al, byte ptr es:[bx + di]  ; read screen
mov  bx, bp						; set colormaps 6 CS-based offset
xlat byte ptr cs:[bx]		    ; lookup colormaps + al byte
stosb							; write to screen
add  di, dx						; dx contains constant (0x4F) to add to di to get next screen dest.


ENDM

REPT 16
    DRAW_SINGLE_FUZZPIXEL
endm


cmp  si, 064h
jl   fuzzpos_ok
; subtract 50 from fuzzpos
sub  si, 064h
fuzzpos_ok:
sub  cl, ch
cmp  cl, ch
jle  done_drawing_16_fuzzpixels
jmp  draw_16_fuzzpixels
done_drawing_16_fuzzpixels:
test cl, cl
je   finished_drawing_fuzzpixels
xor ch, ch;
draw_one_fuzzpixel:

lodsw     						; load fuzz offset...
mov  bx, ax	       				; move offset to bx.
mov  al, byte ptr es:[bx + di]  ; read screen
mov  bx, bp						; set colormaps 6 CS-based offset
xlat byte ptr cs:[bx]		    ; lookup colormaps + al byte
stosb							; write to screen
add  di, dx						; dx contains constant (0x4F) to add to di to get next screen dest.

cmp  si, 064h
je   zero_out_fuzzpos
finish_one_fuzzpixel_iteration:
loop  draw_one_fuzzpixel
; write back fuzzpos
finished_drawing_fuzzpixels:

pop bp
sti

; restore ds
mov  di, ss
mov  ds, di

; write back fuzzpos
mov  ax, si

mov  byte ptr ds:[_fuzzpos], al

pop  es
pop  di
pop  si
retf 

zero_out_fuzzpos:
xor  si, si
loop  draw_one_fuzzpixel
jmp finished_drawing_fuzzpixels

ENDP



;
; R_DrawSingleMaskedColumn
;
	
PROC  R_DrawSingleMaskedColumn_ 
PUBLIC  R_DrawSingleMaskedColumn_ 

push  bx
push  cx
push  si
push  di
push  bp

mov   word ptr ds:[_dc_source_segment], ax	; set this early. 

mov   cl, dl
xor   ch, ch		; count used once for mul and not again. todo is dh already zero?



;    topscreen.w = sprtopscreen;

mov   di, word ptr ds:[_sprtopscreen]
mov   si, word ptr ds:[_sprtopscreen+2]
mov   bx, word ptr ds:[_spryscale]
mov   ax, word ptr ds:[_spryscale+2]

;   topscreen = si:di 

; CX * AX:BX
; fastmul1632, ax/cx preswapped

; FastMul16u32u(length, spryscale.w)

MUL  CX        ; AX * CX
XCHG CX, AX    ; store low product to be high result. Retrieve orig AX
MUL  BX        ; AX * BX
ADD  DX, CX    ; add 

;    bottomscreen.w = topscreen.w + FastMul16u32u(length, spryscale.w);


add ax, di
adc dx, si

; dx:ax = bottomscreen
; si:di = topscreen (still)

;    dc_yh = bottomscreen.h.intbits;
;    if (!bottomscreen.h.fracbits)
;        dc_yh--;


neg ax          ; if zero, subtract
adc dx, 0FFFFh      ; 

;mov  word ptr ds:[_dc_yh], dx   ; dont actually need to write back.
; dc_yh written back


;		dc_yl = topscreen.h.intbits;
;		if (topscreen.h.fracbits)
;			dc_yl++;



neg  di
adc  si, 0
;mov  word ptr ds:[_dc_yl], si   ; dont actually need to write back.

; dx is dc_yh
; si is dc_yl




;        if (dc_yh >= mfloorclip[dc_x])
;            dc_yh = mfloorclip[dc_x]-1;



mov   bx, word ptr ds:[_dc_x]
sal   bx, 1
les   ax, dword ptr ds:[_mfloorclip]
add   bx, ax
mov   cx, word ptr es:[bx]

cmp   dx, cx
jl    skip_floor_clip_set_single	; todo consider making this jump out and back? whats the better default branch
mov   dx, cx
dec   dx
skip_floor_clip_set_single:



;        if (dc_yl <= mceilingclip[dc_x])
;            dc_yl = mceilingclip[dc_x]+1;


sub   bx, ax

les   ax, dword ptr ds:[_mceilingclip]   
add   bx, ax

mov   cx, word ptr es:[bx]
cmp   si, cx
jg    skip_ceil_clip_set_single   ; todo consider making this jump out and back? whats the better default branch
mov   si, cx
inc   si
skip_ceil_clip_set_single:

cmp   si, dx			
jg    exit_function_single


mov   word ptr ds:[_dc_yh], dx ; todo eventually just pass this in as an arg instead of write it
mov   word ptr ds:[_dc_yl], si ;  dc_x could also be trivially recovered from bx

mov   ax, COLORMAPS_MASKEDMAPPING_SEG_DIFF


db 09Ah
dw R_DRAWCOLUMNPREPCALLOFFSET 
dw COLFUNC_MASKEDMAPPING_SEGMENT 


exit_function_single:


pop   bp
pop   di
pop   si
pop   cx
pop   bx
retf   

ENDP

UNCLIPPED_COLUMN  = 0FFFEh



; 3034 ish bytes
; note remove masked start from here 

jump_to_exit_draw_shadow_sprite:
jmp   exit_draw_shadow_sprite

PROC R_DrawMaskedSpriteShadow_ NEAR
PUBLIC R_DrawMaskedSpriteShadow_

; ax 	 pixelsegment
; cx:bx  column fardata

; bp - 2     topscreen  segment
; bp - 4     basetexturemid segment
; bp - 6   basetexturemid offset

push  dx
push  si
push  di
push  bp
mov   bp, sp
sub   sp, 6
mov   si, bx

mov   es, cx
mov   ax, word ptr ds:[_dc_texturemid]
mov   word ptr [bp - 6], ax
mov   ax, word ptr ds:[_dc_texturemid+2]
; es is already cx
mov   word ptr [bp - 4], ax
cmp   byte ptr es:[si], 0FFh  ; todo cant this check be only at the end? can this be called with 0 posts?
je    jump_to_exit_draw_shadow_sprite
draw_next_shadow_sprite_post:
mov   bx, word ptr ds:[_spryscale]
mov   cx, word ptr ds:[_spryscale + 2]
mov   di, cx
mov   al, byte ptr es:[si]
xor   ah, ah  ; todo can this be cbw

;inlined FastMul16u32u_
XCHG CX, AX    ; AX stored in CX
MUL  CX        ; AX * CX
XCHG CX, AX    ; store low product to be high result. Retrieve orig AX
MUL  BX        ; AX * BX
ADD  DX, CX    ; add 


mov   cx, word ptr ds:[_sprtopscreen]
add   cx, ax
mov   word ptr [bp - 2], cx
mov   cx, word ptr ds:[_sprtopscreen + 2]
adc   cx, dx
; todo cache above values to not grab these again?
; BX IS STILL _spryscale


mov   al, byte ptr es:[si + 1]
xor   ah, ah

;inlined FastMul16u32u_
XCHG DI, AX    ; AX stored in DI
MUL  DI        ; AX * DI
XCHG DI, AX    ; store low product to be high result. Retrieve orig AX
MUL  BX        ; AX * BX
ADD  DX, DI    ; add 


mov   bx, cx   ; bx store _dc_yl
add   ax, word ptr [bp - 2]
adc   dx, cx
test  ax, ax
jne   bottomscreen_not_zero
dec   dx
bottomscreen_not_zero:
cmp   word ptr [bp - 2], 0
je    topscreen_not_zero
inc   bx   				; inc _dc_yl
topscreen_not_zero:
mov   ax, dx  ; store dc_yh in ax...
mov   dx, bx			; dx gets _dc_yl
mov   cx, es    ; cache this
mov   bx, word ptr ds:[_dc_x]
mov   di, word ptr ds:[_mfloorclip]
mov   es, word ptr ds:[_mfloorclip + 2]
add   bx, bx
cmp   ax, word ptr es:[bx + di]   ; ax holds dc_yh
jl    dc_yh_clipped_to_floor
mov   ax, word ptr es:[bx + di]
dec   ax
dc_yh_clipped_to_floor:


mov   di, word ptr ds:[_mceilingclip]
mov   es, word ptr ds:[_mceilingclip + 2]

cmp   dx, word ptr es:[bx + di]  ; _dc_yl compare
jg    dc_yl_clipped_to_ceiling

mov   dx, word ptr es:[bx + di]
inc   dx
dc_yl_clipped_to_ceiling:
; ax still stores dc_yh

;        if (dc_yl <= dc_yh) {
cmp   dx, ax
mov   es, cx
jg   do_next_shadow_sprite_iteration

mov   di, ax  ; finally pass off dc_yh to di
; _dc_texturemid = basetexturemid
mov   ax, word ptr [bp - 6]
mov   word ptr ds:[_dc_texturemid], ax
mov   ax, word ptr [bp - 4]

mov   bl, byte ptr es:[si]

xor   bh, bh
sub   ax, bx
mov   word ptr ds:[_dc_texturemid+2], ax 
cmp   dx, 0			; dx still holds dc_yl
jne   high_border_adjusted
inc   dx 
high_border_adjusted:
mov   ax, word ptr ds:[_viewheight]
dec   ax
cmp   ax, di    ; di still holds _dc_yh
jne   low_border_adjusted
dec   di        ; _dc_yh --
low_border_adjusted:

mov   bx, dx    ; bx gets dc_yl 
sub   di, bx

; di = count
jl    do_next_shadow_sprite_iteration
mov   ax, word ptr ds:[_dc_x]
mov   dx, ax

and   al, 3
add   al, byte ptr ds:[_detailshift + 1]
mov   byte ptr cs:[SELFMODIFY_set_bx_to_lookup+1 - OFFSET R_DrawFuzzColumn_], al
mov   cx, DC_YL_LOOKUP_MASKEDMAPPING_SEGMENT

add   bx, bx
mov   ax, es
mov   es, cx
mov   cl, byte ptr ds:[_detailshift2minus]
sar   dx, cl
SELFMODIFY_set_dx_to_destview_offset:
add   dx, 1000h   ; need the 2 byte constant.
add   dx, word ptr es:[bx]
mov   es, ax

mov   cx, dx

; vga plane stuff.
mov   dx, SC_DATA
SELFMODIFY_set_bx_to_lookup:
mov   bx, 0
mov   al, byte ptr ds:[bx + _quality_port_lookup]

out   dx, al
add   bx, bx
mov   dx, GC_INDEX
mov   ax, word ptr ds:[bx + _vga_read_port_lookup]
out   dx, ax

SELFMODIFY_set_bx_to_destview_segment:
mov   bx, 0

; pass in count via di
; pass in destview via bx
; pass in offset via cx

;call _R_DrawFuzzColumnCallHigh

db 09Ah
dw R_DRAWFUZZCOLUMNOFFSET
dw DRAWFUZZCOL_AREA_SEGMENT


do_next_shadow_sprite_iteration:
add   si, 2
cmp   byte ptr es:[si], 0FFh
je    exit_draw_shadow_sprite
jmp   draw_next_shadow_sprite_post
exit_draw_shadow_sprite:
mov   ax, word ptr [bp - 6]
mov   word ptr ds:[_dc_texturemid], ax
mov   ax, word ptr [bp - 4]
mov   word ptr ds:[_dc_texturemid + 2], ax

LEAVE_MACRO
mov   cx, es
pop   di
pop   si
pop   dx
ret   

endp



;
; R_DrawVisSprite_
;

; todo may not have to push/pop most of these vars.

PROC  R_DrawVisSprite_ NEAR
PUBLIC  R_DrawVisSprite_ 

; ax is vissprite_t near pointer

; bp - 2  	 frac.h.fracbits
; bp - 4  	 frac.h.intbits
; bp - 6     xiscalestep_shift low word
; bp - 8     xiscalestep_shift high word


push  bx
push  cx
push  dx
push  si
push  di
push  bp
mov   bp, sp

mov   si, ax
; todo is this a constant that can be moved out a layer?
mov   word ptr ds:[_dc_colormap_segment], COLORMAPS_SEGMENT_MASKEDMAPPING
mov   al, byte ptr [si + 1]
mov   byte ptr ds:[_dc_colormap_index], al

; todo move this out to a higher level! possibly when executesetviewsize happens.

mov   al, byte ptr ds:[_detailshiftitercount]
mov   byte ptr cs:[SELFMODIFY_detailshiftitercount1+2 - OFFSET R_DrawFuzzColumn_], al
mov   byte ptr cs:[SELFMODIFY_detailshiftitercount2+4 - OFFSET R_DrawFuzzColumn_], al
mov   byte ptr cs:[SELFMODIFY_detailshiftitercount3+1 - OFFSET R_DrawFuzzColumn_], al
mov   byte ptr cs:[SELFMODIFY_detailshiftitercount4+2 - OFFSET R_DrawFuzzColumn_], al
mov   byte ptr cs:[SELFMODIFY_detailshiftitercount5+4 - OFFSET R_DrawFuzzColumn_], al
mov   byte ptr cs:[SELFMODIFY_detailshiftitercount6+1 - OFFSET R_DrawFuzzColumn_], al


mov   ax, word ptr ds:[si + 01Eh]   ; vis->xiscale
mov   dx, word ptr ds:[si + 020h]

; labs
or    dx, dx
jge   xiscale_already_positive
neg   ax
adc   dx, 0
neg   dx
xiscale_already_positive:

cmp byte ptr ds:[_detailshift], 1
jb xiscale_shift_done
je do_xiscale_shift_once
; fall thru do twice
sar   dx, 1
rcr   ax, 1
do_xiscale_shift_once:
sar   dx, 1
rcr   ax, 1
xiscale_shift_done:

mov   word ptr ds:[_dc_iscale], ax
mov   word ptr ds:[_dc_iscale+2], dx

mov   ax, word ptr [si + 022h] ; vis->texturemid
mov   dx, word ptr [si + 024h]

mov   word ptr ds:[_dc_texturemid], ax
mov   word ptr ds:[_dc_texturemid + 2], dx



mov   ax, word ptr ds:[_centery]
lea   di, ds:[_sprtopscreen]
mov   word ptr ds:[di], 0		; di is _sprtopscreen
mov   word ptr ds:[di + 2], ax

mov   ax, word ptr [si + 01Ah]  ; vis->scale
mov   dx, word ptr [si + 01Ch]  

mov   word ptr ds:[_spryscale], ax
mov   word ptr ds:[_spryscale + 2], dx

mov   bx, word ptr ds:[_dc_texturemid]
mov   cx, word ptr ds:[_dc_texturemid + 2]

test  dx, dx
jnz    do_32_bit_mul_vissprite

test ax, 08000h  ; high bit
do_16_bit_mul_after_all_vissprite:
jnz  do_32_bit_mul_after_all_vissprite

;call  FixedMul1632_
db 0FFh  ; lcall[addr]
db 01Eh  ;
dw _FixedMul1632_addr



done_with_mul_vissprite:


; di is _sprtopscreen
sub   word ptr ds:[di], ax
sbb   word ptr ds:[di + 2], dx

mov   ax, word ptr [si + 026h]
cmp   ax, word ptr ds:[_lastvisspritepatch]
jne   sprite_not_first_cachedsegment
mov   es, word ptr ds:[_lastvisspritesegment]
spritesegment_ready:


mov   di, word ptr [si + 016h]  ; frac = vis->startfrac
mov   ax, word ptr [si + 018h]
push  ax;  [bp - 2]
push  di;  [bp - 4]

mov   ax, word ptr [si + 2]
mov   dx, ax
and   ax, word ptr ds:[_detailshiftandval]

mov   word ptr cs:[SELFMODIFY_set_ax_to_dc_x_base4+1 - OFFSET R_DrawFuzzColumn_], ax
mov   word ptr cs:[SELFMODIFY_set_ax_to_dc_x_base4_shadow+1 - OFFSET R_DrawFuzzColumn_], ax

sub   dx, ax
xchg  ax, dx



; xiscalestep_shift = vis->xiscale << detailshift2minus;

mov   bx, word ptr [si + 01Eh] ; DX:BX = vis->xiscale
mov   dx, word ptr [si + 020h]

cmp byte ptr ds:[_detailshift2minus], 1
jb done_shifting_shift_xiscalestep_shift
je do_shift_xiscalestep_shift_once
; fall thru do twice
shl   bx, 1
rcl   dx, 1
do_shift_xiscalestep_shift_once:
shl   bx, 1
rcl   dx, 1


done_shifting_shift_xiscalestep_shift:
push dx;  [bp - 6]
push bx;  [bp - 8]

;        while (base4diff){
;            basespryscale-=vis->xiscale; 
;            base4diff--;
;        }


test  ax, ax
je    base4diff_is_zero
mov   dx, word ptr [si + 01Eh]
mov   bx, word ptr [si + 020h]

decrementbase4loop:
sub   word ptr [bp - 4], dx
sbb   word ptr [bp - 2], bx
dec   ax
jne   decrementbase4loop

base4diff_is_zero:

; zero xoffset loop iter
mov   byte ptr cs:[SELFMODIFY_set_bx_to_xoffset+1 - OFFSET R_DrawFuzzColumn_], 0
mov   byte ptr cs:[SELFMODIFY_set_bx_to_xoffset_shadow+1 - OFFSET R_DrawFuzzColumn_], 0

mov   cx, es


cmp   byte ptr [si + 1], COLORMAP_SHADOW
je    jump_to_draw_shadow_sprite


jmp loop_vga_plane_draw_normal 

do_32_bit_mul_vissprite:
inc   dx
jz    do_16_bit_mul_after_all_vissprite
dec   dx
do_32_bit_mul_after_all_vissprite:

;call FixedMul_
db 0FFh  ; lcall[addr]
db 01Eh  ;
dw _FixedMul_addr

jmp done_with_mul_vissprite

  
sprite_not_first_cachedsegment:
cmp   ax, word ptr ds:[_lastvisspritepatch2]
jne   sprite_not_in_cached_segments
mov   dx, word ptr ds:[_lastvisspritesegment2]
mov   es, dx
mov   dx, word ptr ds:[_lastvisspritesegment]
mov   word ptr ds:[_lastvisspritesegment2], dx

mov   word ptr ds:[_lastvisspritesegment], es
mov   dx, word ptr ds:[_lastvisspritepatch]
mov   word ptr ds:[_lastvisspritepatch2], dx
mov   word ptr ds:[_lastvisspritepatch], ax
jmp   spritesegment_ready
sprite_not_in_cached_segments:
mov   dx, word ptr ds:[_lastvisspritepatch]
mov   word ptr ds:[_lastvisspritepatch2], dx
mov   dx, word ptr ds:[_lastvisspritesegment]
mov   word ptr ds:[_lastvisspritesegment2], dx
;call  getspritetexture_
db 0FFh  ; lcall[addr]
db 01Eh  ;
dw _getspritetexture_addr

mov   word ptr ds:[_lastvisspritesegment], ax
mov   word ptr es, ax
mov   ax, word ptr [si + 026h]
mov   word ptr ds:[_lastvisspritepatch], ax
jmp   spritesegment_ready
jump_to_draw_shadow_sprite:
jmp   draw_shadow_sprite

loop_vga_plane_draw_normal:

SELFMODIFY_set_bx_to_xoffset:
mov   bx, 0 ; zero out bh
SELFMODIFY_detailshiftitercount1:
cmp   bx, 0
jge    exit_draw_vissprites

add   bl, byte ptr ds:[_detailshift+1]

mov   dx, SC_DATA
mov   al, byte ptr ds:[bx + _quality_port_lookup]
out   dx, al
mov   di, word ptr [bp - 4]
mov   dx, word ptr [bp - 2]
SELFMODIFY_set_ax_to_dc_x_base4:
mov   ax, 0
mov   word ptr ds:[_dc_x], ax
cmp   ax, word ptr [si + 2]
jl    increment_by_shift

draw_sprite_normal_innerloop:
mov   ax, word ptr ds:[_dc_x]
cmp   ax, word ptr [si + 4]
jg    end_draw_sprite_normal_innerloop
mov   bx, dx

IF COMPILE_INSTRUCTIONSET GE COMPILE_186
shl   bx, 2
ELSE
shl   bx, 1
shl   bx, 1
ENDIF

mov   ax, word ptr es:[bx + 8]
mov   bx, word ptr es:[bx + 10]

add   ax, cx

; ax pixelsegment
; cx:bx column
; dx unused
; cx is preserved by this call here
; so is ES

; call R_DrawMaskedColumnCallHigh
db 09Ah
dw R_DRAWMASKEDCOLUMNSPRITEOFFSET
dw DRAWMASKEDFUNCAREA_SPRITE_SEGMENT

SELFMODIFY_detailshiftitercount2:
add   word ptr ds:[_dc_x], 0
add   di, word ptr [bp - 8]
adc   dx, word ptr [bp - 6]
jmp   draw_sprite_normal_innerloop
exit_draw_vissprites:
LEAVE_MACRO


pop   di
pop   si
pop   dx
pop   cx
pop   bx
ret 
increment_by_shift:

SELFMODIFY_detailshiftitercount3:
add   ax, 0
mov   word ptr ds:[_dc_x], ax
add   di, word ptr [bp - 8]
adc   dx, word ptr [bp - 6]
jmp   draw_sprite_normal_innerloop

end_draw_sprite_normal_innerloop:
inc   word ptr cs:[SELFMODIFY_set_ax_to_dc_x_base4+1 - OFFSET R_DrawFuzzColumn_]
inc   byte ptr cs:[SELFMODIFY_set_bx_to_xoffset+1 - OFFSET R_DrawFuzzColumn_]
mov   ax, word ptr [si + 01Eh]
add   word ptr [bp - 4], ax
mov   ax, word ptr [si + 020h]
adc   word ptr [bp - 2], ax
jmp   loop_vga_plane_draw_normal
draw_shadow_sprite:
mov   ax, word ptr ds:[_destview]
mov   word ptr cs:[SELFMODIFY_set_dx_to_destview_offset+2 - OFFSET R_DrawFuzzColumn_], ax
mov   ax, word ptr ds:[_destview + 2]
mov   word ptr cs:[SELFMODIFY_set_bx_to_destview_segment+1 - OFFSET R_DrawFuzzColumn_], ax

loop_vga_plane_draw_shadow:
SELFMODIFY_set_bx_to_xoffset_shadow:
mov   bx, 0
SELFMODIFY_detailshiftitercount4:
cmp   bx, 0
jge    exit_draw_vissprites

add   bl, byte ptr ds:[_detailshift+1]

mov   dx, SC_DATA
mov   al, byte ptr ds:[bx + _quality_port_lookup]
out   dx, al
mov   di, word ptr [bp - 4]
mov   dx, word ptr [bp - 2]
SELFMODIFY_set_ax_to_dc_x_base4_shadow:
mov   ax, 0
mov   word ptr ds:[_dc_x], ax

cmp   ax, word ptr [si + 2]
jle   increment_by_shift_shadow

draw_sprite_shadow_innerloop:
mov   ax, word ptr ds:[_dc_x]
cmp   ax, word ptr [si + 4]
jg    end_draw_sprite_shadow_innerloop
mov   bx, dx

IF COMPILE_INSTRUCTIONSET GE COMPILE_186
shl   bx, 2
ELSE
shl   bx, 1
shl   bx, 1
ENDIF
mov   ax, word ptr es:[bx + 8]
mov   bx, word ptr es:[bx + 10]

add   ax, cx

; cx, es preserved in the call

call R_DrawMaskedSpriteShadow_


SELFMODIFY_detailshiftitercount5:

add   word ptr ds:[_dc_x], 0
add   di, word ptr [bp - 8]
adc   dx, word ptr [bp - 6]
jmp   draw_sprite_shadow_innerloop

end_draw_sprite_shadow_innerloop:
inc   word ptr cs:[SELFMODIFY_set_ax_to_dc_x_base4_shadow+1 - OFFSET R_DrawFuzzColumn_]
inc   byte ptr cs:[SELFMODIFY_set_bx_to_xoffset_shadow+1 - OFFSET R_DrawFuzzColumn_]
mov   ax, word ptr [si + 01Eh]
add   word ptr [bp - 4], ax
mov   ax, word ptr [si + 020h]
adc   word ptr [bp - 2], ax
jmp   loop_vga_plane_draw_shadow

increment_by_shift_shadow:
SELFMODIFY_detailshiftitercount6:
add   ax, 0
mov   word ptr ds:[_dc_x], ax
add   di, word ptr [bp - 8]
adc   dx, word ptr [bp - 6]
jmp   draw_sprite_shadow_innerloop

ENDP

PROC R_DrawPlayerSprites_ NEAR
PUBLIC R_DrawPlayerSprites_

mov  word ptr ds:[_mfloorclip], OFFSET_SCREENHEIGHTARRAY 
mov  word ptr ds:[_mceilingclip], OFFSET_NEGONEARRAY 

cmp  word ptr ds:[_psprites], -1  ; STATENUM_NULL
je  check_next_player_sprite
mov  ax, _player_vissprites       ; vissprite 0
call R_DrawVisSprite_

check_next_player_sprite:
cmp  word ptr ds:[_psprites + 0Ch], -1  ; STATENUM_NULL
je  exit_drawplayersprites
mov  ax, _player_vissprites + SIZEOF_VISSPRITE_T
call R_DrawVisSprite_

exit_drawplayersprites:
ret 


ENDP



PROC R_RenderMaskedSegRange_ NEAR
PUBLIC R_RenderMaskedSegRange_

;void __near R_RenderMaskedSegRange (drawseg_t __far* ds, int16_t x1, int16_t x2) {

;es:di is far drawseg pointer
;x1 is ax
;x2 is cx

; bp - 2        side_render
; bp - 4        lineflags
; bp - 6        maskedtexturecolumn todo put in register
; bp - 8        rw_scalestep_shift hi word
; bp - 0Ah      rw_scalestep_shift lo word
; bp - 0Ch      cached xoffset/di
; bp - 0Eh      dc_x_base4
; bp - 010h     sprtopscreen_step hi word
; bp - 012h     sprtopscreen_step lo word
; bp - 014h     basespryscale hi word
; bp - 016h     basespryscale lo word
; bp - 018h     drawseg far segment (this is a constant)
; bp - 01Ah     ds (drawseg, not data segment)
; bp - 01Ch     rw_scalestep hi word
; bp - 01Eh     rw_scalestep lo word

  
push  si
push  di
push  bp
mov   bp, sp
sub   sp, 01Eh

mov   word ptr [bp - 01Ah], di
mov   word ptr [bp - 018h], es

mov   word ptr cs:[SELFMODIFY_x1_field_1+1 - OFFSET R_DrawFuzzColumn_], ax
mov   word ptr cs:[SELFMODIFY_x1_field_2+1 - OFFSET R_DrawFuzzColumn_], ax
mov   word ptr cs:[SELFMODIFY_x1_field_3+1 - OFFSET R_DrawFuzzColumn_], ax

mov   word ptr cs:[SELFMODIFY_cmp_to_x2+1 - OFFSET R_DrawFuzzColumn_], cx

mov   ax, word ptr es:[di]       ; get ds->cursegvalue
mov   word ptr ds:[_curseg], ax  
shl   ax, 1
shl   ax, 1
shl   ax, 1
add   ah, (_segs_render SHR 8 ) 		; segs_render is ds:[0x4000] 
mov   word ptr ds:[_curseg_render], ax
mov   bx, ax
mov   ax, SIDES_SEGMENT
mov   si, word ptr [bx + 6]			; get sidedefOffset
mov   es, ax
shl   si, 1
shl   si, 1
mov   ax, si						; side_render_t is 4 bytes each
shl   si, 1							; side_t is 8 bytes each
add   ah, (_sides_render SHR 8 )		; sides render near addr is ds:[0xAE00]
mov   si, word ptr es:[si + 4]		; lookup side->midtexture
mov   word ptr [bp - 2], ax			; store side_render_t offset for curseg_render
mov   ax, TEXTURETRANSLATION_SEGMENT
add   si, si
mov   es, ax
mov   ax, MASKED_LOOKUP_SEGMENT_7000
mov   si, word ptr es:[si]			; get texnum. si is stored for the whole function. not good revisit.
mov   es, ax
mov   al, byte ptr es:[si]			; translate texnum to lookup

; put texnum where it needs to be
mov   word ptr cs:[SELFMODIFY_texnum_1+1 - OFFSET R_DrawFuzzColumn_], si
mov   word ptr cs:[SELFMODIFY_texnum_2+1 - OFFSET R_DrawFuzzColumn_], si
mov   word ptr cs:[SELFMODIFY_texnum_3+1 - OFFSET R_DrawFuzzColumn_], si

mov   byte ptr cs:[SELFMODIFY_compare_lookup  +1 - OFFSET R_DrawFuzzColumn_], al
mov   byte ptr cs:[SELFMODIFY_compare_lookup_2+1 - OFFSET R_DrawFuzzColumn_], al

;	if (lookup != 0xFF){
cmp   al, 0FFh
je    lookup_not_ff

;		masked_header_t __near * maskedheader = &masked_headers[lookup];
;		maskedpostsofs = maskedheader->postofsoffset;
cbw


IF COMPILE_INSTRUCTIONSET GE COMPILE_186
shl   ax, 3
ELSE
shl   ax, 1
shl   ax, 1
shl   ax, 1
ENDIF


mov   bx, ax
mov   ax, word ptr ds:[bx + _masked_headers + 2]
mov   word ptr cs:[SELFMODIFY_maskedpostofs  +3 - OFFSET R_DrawFuzzColumn_], ax
mov   word ptr cs:[SELFMODIFY_maskedpostofs_2+3 - OFFSET R_DrawFuzzColumn_], ax
lookup_not_ff:

mov   ax, SEG_LINEDEFS_SEGMENT
mov   es, ax
mov   ax, word ptr ds:[_curseg]
mov   bx, ax
add   bh, (seg_sides_offset_in_seglines SHR 8)		; seg_sides_offset_in_seglines high word
mov   dl, byte ptr es:[bx]		; todo... this can be passed forward via self modifying code and no register wasted?
add   ax, ax
mov   bx, ax
mov   di, word ptr es:[bx]		; di holds curlinelinedef

mov   ax, LINEFLAGSLIST_SEGMENT
mov   es, ax
mov   al, byte ptr es:[di]
mov   bx, word ptr ds:[_curseg_render]   ; get curseg 
mov   byte ptr [bp - 4], al
mov   cx, word ptr [bx+2]			; get v2 offset
mov   bx, word ptr [bx]				; get v1 offset
mov   ax, VERTEXES_SEGMENT

IF COMPILE_INSTRUCTIONSET GE COMPILE_186
shl   bx, 2
shl   cx, 2
ELSE
shl   bx, 1
shl   bx, 1
shl   cx, 1
shl   cx, 1
ENDIF

mov   es, ax

; compare v1/v2 fields right now, self modify the lightnum diff that it is used for later.

mov   ax, word ptr es:[bx]	   ; get v1.x
mov   bx, word ptr es:[bx + 2] ; v1.y
xchg  bx, cx				   ; cx has v1.y. ax has v1.x

; todo is there a way to do this with adc/sbb without jumps?
cmp   cx, word ptr es:[bx+2]	; compare v1.y == v2.y
je    ys_equal
cmp   ax, word ptr es:[bx]		; compare v1.x == v2.x
je    xs_equal
mov   al, 090h				    ; nop instruction
done_comparing_vertexes:
mov   byte ptr cs:[SELFMODIFY_add_vertex_field - OFFSET R_DrawFuzzColumn_], al


mov   bx, word ptr [bp - 2]     ; get side_render
mov   cx, word ptr [bx + 2]		; get side_render secnum

test  byte ptr [bp - 4], ML_TWOSIDED
										; todo 2 is this even necessary? do lineflags prevent us from checking for a null backsec

mov   ax, 0FFFFh						; dunno if we need this..
je   backsector_set

; backsector = &sectors[sides_render[curlinelinedef->sidenum[curlineside ^ 1]].secnum]

;curlineside ^ 1

mov   dl, 1
xor   bx, bx
mov   bl, dl

shl   di, 1
shl   di, 1
mov   ax, LINES_SEGMENT
sal   bx, 1
mov   es, ax

mov   bx, word ptr es:[bx + di]		; get secnum
IF COMPILE_INSTRUCTIONSET GE COMPILE_186
shl   bx, 2
ELSE
shl   bx, 1
shl   bx, 1
ENDIF


mov   ax, word ptr ds:[bx + _sides_render + 2]   ; get a field in the sides render area

IF COMPILE_INSTRUCTIONSET GE COMPILE_186
shl   ax, 4
ELSE
shl   ax, 1
shl   ax, 1
shl   ax, 1
shl   ax, 1
ENDIF

backsector_set:
mov   word ptr ds:[_backsector], ax
mov   ax, SECTORS_SEGMENT
mov   es, ax
mov   bx, cx        ; retrieve side_render secnum from above

IF COMPILE_INSTRUCTIONSET GE COMPILE_186
shl   bx, 4
ELSE
shl   bx, 1
shl   bx, 1
shl   bx, 1
shl   bx, 1
ENDIF


mov   word ptr ds:[_frontsector], bx


mov   al, byte ptr es:[bx + 0Eh]
xor   ah, ah
mov   dx, ax

IF COMPILE_INSTRUCTIONSET GE COMPILE_186
sar   dx, 4
ELSE
sar   dx, 1
sar   dx, 1
sar   dx, 1
sar   dx, 1
ENDIF

mov   al, byte ptr ds:[_extralight]
add   ax, dx

SELFMODIFY_add_vertex_field:
nop				; becomes inc ax, dec ax, or nop

;	if (lightnum < 0){
;test  ax, ax			; we get this for free via the above instructions
jl   set_walllights_zero
cmp   ax, LIGHTLEVELS
jge   clip_lights_to_max
mov   bx, ax
add   bx, ax
mov   ax, word ptr ds:[bx + _lightmult48lookup]
jmp   lights_set

ys_equal:
mov   al, 048h  ; dec ax instruction
jmp   done_comparing_vertexes
xs_equal:
mov   al, 040h  ; inc ax instruciton
jmp   done_comparing_vertexes




set_walllights_zero:
xor   ax, ax
jmp   lights_set

clip_lights_to_max:
mov   ax, word ptr ds:[_lightmult48lookup + 2 * (LIGHTLEVELS - 1)]    ;lightmult48lookup[LIGHTLEVELS - 1];

lights_set:
mov   word ptr ds:[_walllights], ax      ; store lights
les   di, dword ptr [bp - 01Ah]          ; get drawseg far ptr

; es:di is input drawseg

;    maskedtexturecol = &openings[ds->maskedtexturecol_val];

mov   ax, word ptr es:[di + 01Ah]		; ds->maskedtexturecol_val
add   ax, ax
mov   word ptr ds:[_maskedtexturecol], ax
;mov   word ptr ds:[_maskedtexturecol+2], OPENINGS_SEGMENT	; this is now hardcoded in data

;    rw_scalestep.w = ds->scalestep;

mov   bx, word ptr es:[di + 0Eh]
mov   word ptr [bp - 01Eh], bx		
mov   cx, word ptr es:[di + 010h]
mov   word ptr [bp - 01Ch], cx

SELFMODIFY_x1_field_1:
mov   ax, 08000h
sub   ax, word ptr es:[di + 2]
add   word ptr ds:[_walllights], 030h

; inlined  FastMul16u32u_

;		spryscale.w = ds->scale1 + FastMul16u32u(x1 - ds->x1,rw_scalestep.w)


XCHG CX, AX    ; AX stored in CX
MUL  CX        ; AX * CX
XCHG CX, AX    ; store low product to be high result. Retrieve orig AX
MUL  BX        ; AX * BX
ADD  DX, CX    ; add 

add   ax, word ptr es:[di + 6]
adc   dx, word ptr es:[di + 8]
mov   word ptr ds:[_spryscale], ax
mov   word ptr ds:[_spryscale + 2], dx

;    mfloorclip_offset = ds->sprbottomclip_offset;
;    mceilingclip_offset = ds->sprtopclip_offset;

mov   ax, word ptr es:[di + 018h]
mov   word ptr ds:[_mfloorclip], ax
mov   ax, word ptr es:[di + 016h]
mov   word ptr ds:[_mceilingclip], ax

;    if (lineflags & ML_DONTPEGBOTTOM) {

les   di, dword ptr ds:[_frontsector]
mov   bx, word ptr  ds:[_backsector]
test  byte ptr [bp - 4], ML_DONTPEGBOTTOM
jne   front_back_floor_case

front_back_ceiling_case:

; frontsector->ceilingheight < backsector->ceilingheight ? frontsector->ceilingheight : backsector->ceilingheight;

mov   ax, word ptr es:[di+2] ; frontsector ceil
mov   cx, word ptr es:[bx+2] ; backsector ceil
cmp   ax, cx
jl    use_frontsector_ceil
mov   ax, cx			    ; use backsector ceil
use_frontsector_ceil:

xor   cx, cx

jmp sector_height_chosen
fixed_colormap:
mov   word ptr ds:[_dc_colormap_segment], COLORMAPS_SEGMENT_MASKEDMAPPING
mov   al, byte ptr ds:[_fixedcolormap]
mov   byte ptr ds:[_dc_colormap_index], al
jmp   colormap_set


front_back_floor_case:

;	base = frontsector->floorheight > backsector->floorheight ? frontsector->floorheight : backsector->floorheight;

mov   ax, word ptr es:[di] ; frontsector floor
mov   cx, word ptr es:[bx] ; backsector floor
cmp   ax, cx
jg    use_frontsector_floor
mov   ax, cx   ; use backsector floor
use_frontsector_floor:



mov   cx, TEXTUREHEIGHTS_SEGMENT
mov   es, cx
xor   cx, cx

SELFMODIFY_texnum_3:
mov   si, 08000h
mov   cl, byte ptr es:[si]
inc   cx

sector_height_chosen:

;ax contains shortheight of chosen sector height
;cx contains word to add to dc_texturemid after shortheight conversion.. 0 for ceil, and textureheight for floor case

; set fixed union from shortheight, i.e. shift 13 left
xor   dx, dx
sar   ax, 1
rcr   dx, 1
sar   ax, 1
rcr   dx, 1
sar   ax, 1
rcr   dx, 1

; ax:dx is textureheight

;    dc_texturemid.h.intbits += adder;		

add   ax, cx

;     dc_texturemid.w -= viewz.w;
sub   dx, word ptr ds:[_viewz]
sbb   ax, word ptr ds:[_viewz+2]



;    dc_texturemid.h.intbits += side_render->rowoffset;

mov   di, word ptr [bp - 2]
add   ax, word ptr [di]


mov   word ptr ds:[_dc_texturemid], dx
mov   word ptr ds:[_dc_texturemid+2], ax

;if (fixedcolormap) {
;		// todo if this is 0 maybe skip the if?
;		dc_colormap_segment = colormaps_segment_maskedmapping;
;		dc_colormap_index = fixedcolormap;
;	}

cmp   byte ptr ds:[_fixedcolormap], 0
jne    fixed_colormap
colormap_set:

; set up main outer loop

;		int16_t dc_x_base4 = x1 & (detailshiftandval);	

SELFMODIFY_x1_field_2:
mov   ax, 08000h
mov   di, ax						; di = x1
and   ax, word ptr ds:[_detailshiftandval]
mov   word ptr [bp - 0Eh], ax

;		int16_t base4diff = x1 - dc_x_base4;

sub   di, ax						; di = base4diff = x1 - dc_x_base4

;		fixed_t basespryscale = spryscale.w;

mov   ax, word ptr ds:[_spryscale]
mov   word ptr [bp - 016h], ax
mov   ax, word ptr ds:[_spryscale + 2]
mov   word ptr [bp - 014h], ax

;		fixed_t rw_scalestep_shift = rw_scalestep.w << detailshift2minus;

mov   ax, word ptr [bp - 01Eh]  ; rw_scalestep
mov   dx, word ptr [bp - 01Ch]	; rw_scalestep


cmp byte ptr ds:[_detailshift2minus], 1
jb done_shifting_spryscale
je do_shift_spryscale_once
; fall thru do twice
shl   ax, 1
rcl   dx, 1
do_shift_spryscale_once:
shl   ax, 1
rcl   dx, 1


done_shifting_spryscale:
mov   word ptr [bp - 0Ah], ax		; rw_scalestep_shift
mov   word ptr [bp - 8], dx			; rw_scalestep_shift

;		fixed_t sprtopscreen_step = FixedMul(dc_texturemid.w, rw_scalestep_shift);


mov   bx, word ptr ds:[_dc_texturemid]
mov   cx, word ptr ds:[_dc_texturemid + 2]
;call  FixedMul_
db 0FFh  ; lcall[addr]
db 01Eh  ;
dw _FixedMul_addr

mov   word ptr [bp - 012h], ax	  ; sprtopscreen_step
mov   word ptr [bp - 010h], dx


;	while (base4diff){
;		basespryscale -= rw_scalestep.w;
;		base4diff--;
;	}

test  di, di
je    base4diff_is_zero_rendermaskedsegrange
mov   ax, word ptr [bp - 01Eh]
mov   dx, word ptr [bp - 01Ch]

loop_dec_base4diff:
;			basespryscale -= rw_scalestep.w;

sub   word ptr [bp - 016h], ax
sbb   word ptr [bp - 014h], dx
dec   di
jne   loop_dec_base4diff
base4diff_is_zero_rendermaskedsegrange:

; di is now free to use for something else..

mov   di, 0		; x_offset. 




; if xoffset < detailshiftitercount exit loop


continue_outer_loop:

;			outp(SC_INDEX+1, quality_port_lookup[xoffset+detailshift.b.bytehigh]);
mov   bx, di  ; copy xoffset
add   bl, byte ptr ds:[_detailshift + 1]

mov   dx, SC_DATA
mov   al, byte ptr [bx + _quality_port_lookup]
out   dx, al


;			spryscale.w = basespryscale;

mov   dx, word ptr [bp - 016h]	; basespryscale
mov   bx, word ptr [bp - 014h]	; basespryscale

; di holds xoffset.
; bx:dx temporarily holds _spryscale
; ax will temporarily store dc_x
;			dc_x        = dc_x_base4 + xoffset;
mov   ax, word ptr [bp - 0Eh]		; dc_x_base4
add   ax, di		; add xoffset to dc_x



;	if (dc_x < x1){
SELFMODIFY_x1_field_3:
cmp   ax, 08000h   ; x1 
jge   calculate_sprtopscreen

; adjust by shiftstep

;	dc_x        += detailshiftitercount;
;	spryscale.w += rw_scalestep_shift;

add   ax, word ptr ds:[_detailshiftitercount]
add   dx, word ptr [bp - 0Ah]   ; rw_scalestep_shift 
adc   bx, word ptr [bp - 8]     ; rw_scalestep_shift

calculate_sprtopscreen:

mov   word ptr ds:[_dc_x], ax
mov   word ptr ds:[_spryscale], dx
mov   word ptr ds:[_spryscale + 2], bx

; bx:dx written back to  _spryscale

;			sprtopscreen.h.intbits = centery;
;			sprtopscreen.h.fracbits = 0;



;			sprtopscreen.w -= FixedMul(dc_texturemid.w,spryscale.w);

mov   ax, dx
mov   dx, bx
mov   bx, word ptr ds:[_dc_texturemid]
mov   cx, word ptr ds:[_dc_texturemid + 2]

test  dx, dx
jnz    do_32_bit_mul

test ax, 08000h  ; high bit
do_16_bit_mul_after_all:
jnz  do_32_bit_mul_after_all

;call  FixedMul1632_
db 0FFh  ; lcall[addr]
db 01Eh  ;
dw _FixedMul1632_addr



done_with_mul:

neg   ax ; no need to subtract from zero...
mov   word ptr ds:[_sprtopscreen], ax
mov   ax, word ptr ds:[_centery]
sbb   ax, dx
mov   word ptr ds:[_sprtopscreen + 2], ax

;push  di ; todo figure out how to put di on stack and use it in the inner loop.
mov   word ptr [bp - 0Ch], di

inner_loop_draw_columns:

mov   ax, word ptr ds:[_dc_x]
SELFMODIFY_cmp_to_x2:
cmp   ax, 02000h
jle   do_inner_loop


;		for (xoffset = 0 ; xoffset < detailshiftitercount ; 
;			xoffset++, 
;			basespryscale+=rw_scalestep.w) {

; end of inner loop, fall back to end of outer loop step

mov   di, word ptr [bp - 0Ch]
;pop   di

inc   di			; xoffset++
;			basespryscale+=rw_scalestep.w
mov   ax, word ptr [bp - 01Eh]
add   word ptr [bp - 016h], ax
mov   ax, word ptr [bp - 01Ch]
adc   word ptr [bp - 014h], ax


mov   ax, word ptr ds:[_detailshiftitercount]
; xoffset < detailshiftitercount
cmp   ax, di
jg    continue_outer_loop		; 6 bytes out of range

exit_render_masked_segrange:
mov   ax, NULL_TEX_COL
mov   word ptr ds:[_maskednextlookup], ax
mov   word ptr ds:[_maskedcachedbasecol], ax
mov   word ptr ds:[_maskedtexrepeat], 0

LEAVE_MACRO 
pop   di
pop   si
ret   

do_32_bit_mul:
inc   dx
jz    do_16_bit_mul_after_all
dec   dx
do_32_bit_mul_after_all:

;call FixedMul_
db 0FFh  ; lcall[addr]
db 01Eh  ;
dw _FixedMul_addr


jmp done_with_mul

do_inner_loop:
;   ax is dc_x
les   bx, dword ptr ds:[_maskedtexturecol]
add   ax, ax
add   bx, ax
;  si caches _texturecolumn in this inner loop
mov   si, word ptr es:[bx]
;  di caches _maskedcachedbasecol in this inner loop
mov   di, word ptr ds:[_maskedcachedbasecol] 

cmp   si, MAXSHORT			; dont render nonmasked columns here.
je   increment_inner_loop
cmp   byte ptr ds:[_fixedcolormap], 0   
jne   got_colormap
; calculate colormap
cmp   word ptr ds:[_spryscale + 2], 3
jge   use_maxlight
; shift this by 12...
; shift 4 by with this lookup
xor   dx, dx
mov   ax, word ptr ds:[_spryscale + 1]
mov   dl, byte ptr ds:[_spryscale + 3]
sar   dx, 1
rcr   ax, 1
sar   dx, 1
rcr   ax, 1
sar   dx, 1
rcr   ax, 1
sar   dx, 1
rcr   ax, 1

jmp   get_colormap


update_maskedtexturecol_finish_loop_iter:
;	maskedtexturecol[dc_x] = MAXSHORT;


les   bx, dword ptr ds:[_maskedtexturecol]
mov   ax, word ptr ds:[_dc_x]
add   ax, ax
add   bx, ax
mov   word ptr es:[bx], MAXSHORT

increment_inner_loop:

mov   ax, word ptr ds:[_detailshiftitercount]
add   word ptr ds:[_dc_x], ax
mov   ax, word ptr [bp - 0Ah]
add   word ptr ds:[_spryscale], ax
mov   ax, word ptr [bp - 8]
adc   word ptr ds:[_spryscale + 2], ax
mov   ax, word ptr [bp - 012h]
sub   word ptr ds:[_sprtopscreen], ax
mov   ax, word ptr [bp - 010h]
sbb   word ptr ds:[_sprtopscreen + 2], ax
jmp   inner_loop_draw_columns

use_maxlight:
mov   al, MAXLIGHTSCALE - 1
get_colormap:
xor   ah, ah
mov   word ptr ds:[_dc_colormap_segment], COLORMAPS_SEGMENT_MASKEDMAPPING
mov   bx, word ptr ds:[_walllights]
add   bx, ax
mov   ax, SCALELIGHTFIXED_SEGMENT
mov   es, ax
mov   al, byte ptr es:[bx]
mov   byte ptr ds:[_dc_colormap_index], al
got_colormap:
mov   ax, 0FFFFh
mov   dx, ax
mov   bx, word ptr ds:[_spryscale]
mov   cx, word ptr ds:[_spryscale + 2]
;call  FastDiv3232_
db 0FFh  ; lcall[addr]
db 01Eh  ;
dw _FastDiv3232_addr

mov   word ptr ds:[_dc_iscale], ax
mov   word ptr ds:[_dc_iscale + 2], dx

mov   bx, si  ; bx gets a copy of texture column?
;  ax stores _maskedtexrepeat for a little bit
mov   ax, word ptr ds:[_maskedtexrepeat] 
test  ax, ax
jz   do_non_repeat
mov   cx, word ptr ds:[_maskedtexmodulo] 
jcxz  do_looped_column_calc

; width is power of 2, just AND
;	usetexturecolumn =  &= maskedtexmodulo;

and   bx, cx

repeat_column_calculated:

; bx is usetexturecolumn
;xor   bh, bh   ;todo necessary?
mov   ax, bx
; now al is usetexturecolumn

;	if (lookup != 0xFF){
SELFMODIFY_compare_lookup_2:  
mov   dl, 0FFh
inc   dl	; if it was ff, this sets zero flag.
jz    lookup_FF_repeat

;if (maskedheaderpixeolfs != 0xFFFF){

; cs gets MASKEDPIXELDATAOFS_SEGMENT
les   cx, dword ptr ds:[_maskedheaderpixeolfs]
cmp   cx, -1

je   calculate_pixelsegment_mul

calculate_maskedheader_pixel_ofs_repeat:

; es:cx previously LESed
add   bx, bx
add   bx, cx

mov   bx, word ptr es:[bx]
xchg  bx, ax  ; bx back, ax gets pixelsegment

; pixelsegment = ofs


go_draw_masked_column_repeat:

; pixelsegment += _maskedcachedsegment

add   ax, word ptr ds:[_maskedcachedsegment]

;    ax is pixelsegment.
;    bx still has usetexturecolumn!

;	uint16_t __far * postoffsets  =  MK_FP(maskedpostdataofs_segment, maskedpostsofs);
;	uint16_t 		 postoffset = postoffsets[texturecolumn-maskedcachedbasecol];
;	R_DrawMaskedColumnCallHigh (pixelsegment, (column_t __far *)(MK_FP(maskedpostdata_segment, postoffset)));


mov   cx, MASKEDPOSTDATAOFS_SEGMENT
mov   es, cx
add   bx, bx
SELFMODIFY_maskedpostofs_2:     ; todo this
mov   bx, word ptr es:[bx+08000h]
mov   cx, MASKEDPOSTDATA_SEGMENT
;call  dword ptr ds:[_R_DrawMaskedColumnCallHigh]

db 09Ah
dw R_DRAWMASKEDCOLUMNOFFSET
dw DRAWFUZZCOL_AREA_SEGMENT

jmp   update_maskedtexturecol_finish_loop_iter


do_looped_column_calc:
; calculate column by looping until 0 < column < width
; but column may be offset by (width * n)
; we iterate such that (width * n) < column < (width * (n+1))
; such that we can subtract column by width * n each iteration.
; di stores maskedcachedbasecol, which is (width * n).



;	while (usetexturecolumn < (maskedcachedbasecol)){
;		maskedcachedbasecol -= maskedtexrepeat;
;	}
cmp bx, di
jge done_subtracting_column
subtract_column_by_modulo:
sub di, ax
cmp bx, di
jl subtract_column_by_modulo 

; we know maskedcachedbasecol is already good. skip the next loop check. 
; but it only saves running one instruction. lets keep it simpler.
;jmp done_calculating_column_modulo

done_subtracting_column:

;	while (usetexturecolumn >= maskedcachedbasecol){
;		maskedcachedbasecol += maskedtexrepeat;
;	}



cmp bx, di
jl done_adding_column 
add_column_by_modulo:
add di, ax
cmp bx, di
jge add_column_by_modulo
done_adding_column:
sub di, ax
done_calculating_column_modulo:

mov ds:[_maskedcachedbasecol], di  ; write the changes back

;	usetexturecolumn -= maskedcachedbasecol;
sub bx, di

jmp repeat_column_calculated

lookup_FF_repeat:

;	if (texturecolumn >= maskednextlookup ||
; 		texturecolumn < maskedprevlookup

mul   byte ptr ds:[_maskedheightvalcache]
add   ax, word ptr ds:[_maskedcachedsegment]

mov   dx, word ptr ds:[_cachedbyteheight]  ; todo optimize this to a full word with 0 high byte in data. then optimize in _R_DrawSingleMaskedColumn_ as well
;call  dword ptr ds:[_R_DrawSingleMaskedColumnCallHigh]  ; todo... do i really want this
db 09Ah
dw R_DRAWSINGLEMASKEDCOLUMNOFFSET
dw DRAWFUZZCOL_AREA_SEGMENT

jmp   update_maskedtexturecol_finish_loop_iter

; pixelsegment = FastMul8u8u((uint8_t) usetexturecolumn, maskedheightvalcache);
calculate_pixelsegment_mul:

mul   byte ptr ds:[_maskedheightvalcache]
jmp   go_draw_masked_column_repeat

do_non_repeat:

mov   dh, ah	; todo why is ah needed
mov   ax, si
mov   ah, dh
sub   ax, di


;	if (lookup != 0xFF){
SELFMODIFY_compare_lookup:  
mov   dl, 0FFh
inc   dl
je    lookup_FF ; todo fine?

; lookup NOT ff.

;	if (texturecolumn >= maskednextlookup ||
; 		texturecolumn < maskedprevlookup


cmp   si, word ptr ds:[_maskednextlookup]
jge   load_masked_column_segment_lookup ; may be negative

cmp   si, word ptr ds:[_maskedprevlookup] ; may be negative
jl    load_masked_column_segment_lookup

; loads MASKEDPIXELDATAOFS_SEGMENT into ES
les   ax, dword ptr ds:[_maskedheaderpixeolfs]

cmp   ax, -1
jne   calculate_maskedheader_pixel_ofs
mul   byte ptr ds:[_maskedheightvalcache]
go_draw_masked_column:
add   ax, word ptr ds:[_maskedcachedsegment]

;	uint16_t __far * postoffsets  =  MK_FP(maskedpostdataofs_segment, maskedpostsofs);
;	uint16_t 		 postoffset = postoffsets[texturecolumn-maskedcachedbasecol];
;	R_DrawMaskedColumnCallHigh (pixelsegment, (column_t __far *)(MK_FP(maskedpostdata_segment, postoffset)));


mov   bx, si
sub   bx, di
mov   cx, MASKEDPOSTDATAOFS_SEGMENT
mov   es, cx
add   bx, bx
SELFMODIFY_maskedpostofs:
mov   bx, word ptr es:[bx+08000h]
mov   cx, MASKEDPOSTDATA_SEGMENT
;call  dword ptr ds:[_R_DrawMaskedColumnCallHigh]
db 09Ah
dw R_DRAWMASKEDCOLUMNOFFSET
dw DRAWFUZZCOL_AREA_SEGMENT


jmp   update_maskedtexturecol_finish_loop_iter

calculate_maskedheader_pixel_ofs:
; es:ax previously LESed
mov   bx, si
sub   bx, di
add   bx, bx
add   bx, ax
mov   ax, word ptr es:[bx]
jmp   go_draw_masked_column

load_masked_column_segment_lookup:
mov   dx, si
SELFMODIFY_texnum_1:
mov   ax, 08000h
;call  R_GetMaskedColumnSegment_  
db 0FFh  ; lcall[addr]
db 01Eh  ;
dw _R_GetMaskedColumnSegment_addr


mov   di, word ptr ds:[_maskedcachedbasecol]
mov   dx, word ptr ds:[_maskedcachedsegment]   ; to offset for above
sub   ax, dx

jmp   go_draw_masked_column


lookup_FF:

;	if (texturecolumn >= maskednextlookup ||
; 		texturecolumn < maskedprevlookup

cmp   si, word ptr ds:[_maskednextlookup] ; may be negative
jge   load_masked_column_segment
cmp   si, word ptr ds:[_maskedprevlookup] ; may be negative
jl    load_masked_column_segment
mul   byte ptr ds:[_maskedheightvalcache]
add   ax, word ptr ds:[_maskedcachedsegment]

mov   dx, word ptr ds:[_cachedbyteheight]  ; todo optimize this to a full word with 0 high byte in data. then optimize in _R_DrawSingleMaskedColumn_ as well
;call  dword ptr ds:[_R_DrawSingleMaskedColumnCallHigh]  ; todo... do i really want this
db 09Ah
dw R_DRAWSINGLEMASKEDCOLUMNOFFSET
dw DRAWFUZZCOL_AREA_SEGMENT
jmp   update_maskedtexturecol_finish_loop_iter

load_masked_column_segment:
mov   dx, si
SELFMODIFY_texnum_2:
mov   ax, 08000h
;call  R_GetMaskedColumnSegment_
db 0FFh  ; lcall[addr]
db 01Eh  ;
dw _R_GetMaskedColumnSegment_addr

mov   di, word ptr ds:[_maskedcachedbasecol]
mov   dx, word ptr ds:[_cachedbyteheight]  ; todo optimize this to a full word with 0 high byte in data. then optimize in _R_DrawSingleMaskedColumn_ as well

; call  dword ptr ds:[_R_DrawSingleMaskedColumnCallHigh]  ; todo... do i really want this
db 09Ah
dw R_DRAWSINGLEMASKEDCOLUMNOFFSET
dw DRAWFUZZCOL_AREA_SEGMENT


jmp   update_maskedtexturecol_finish_loop_iter

endp


;R_PointOnSegSide_

PROC R_PointOnSegSide_ NEAR
PUBLIC R_PointOnSegSide_ 

push  di
push  bp
mov   bp, sp
push  bx
push  ax

; DX:AX = x
; CX:BX = y
; segindex = si

;    int16_t	lx =  vertexes[segs_render[segindex].v1Offset].x;
;    int16_t	ly =  vertexes[segs_render[segindex].v1Offset].y;
;    int16_t	ldx = vertexes[segs_render[segindex].v2Offset].x;
;    int16_t	ldy = vertexes[segs_render[segindex].v2Offset].y;

; segs_render is 8 bytes each. need to get the index..

shl   si, 1
shl   si, 1
shl   si, 1

;mov   ax, SEGS_RENDER_SEGMENT
;mov   es, ax  ; ES for segs_render lookup

mov   di, word ptr ds:[_segs_render + si]
shl   di, 1
shl   di, 1

mov   ax, VERTEXES_SEGMENT
mov   es, ax  ; DS for vertexes lookup


mov   bx, word ptr es:[di]      ; lx
mov   ax, word ptr es:[di + 2]  ; ly


mov   di, word ptr ds:[_segs_render + si + 2]

;mov   es, ax  ; juggle ax around isntead of putting on stack...

shl   di, 1
shl   di, 1

mov   si, word ptr es:[di]      ; ldx
mov   di, word ptr es:[di + 2]  ; ldy

;mov   di, es                    ; ly
xchg   ax, di

;    ldx -= lx;
;    ldy -= ly;

; si = ldx
; ax = ldy
; bx = lx
; di = ly
; dx = x highbits
; cx = y highbits
; bp -4h = x lowbits
; bp -2h = y lowbits

; if ldx == lx then 
;    if (ldx == lx) {

cmp   si, bx
jne   ldx_nonequal

;        if (x.w <= (lx shift 16))
;  compare high bits
cmp   dx, bx
jl    return_ly_below_ldy
jne   ret_ldy_greater_than_ly

; compare low bits

cmp   word ptr [bp - 04h], 0
jbe   return_ly_below_ldy

 
ret_ldy_greater_than_ly:
;            return ldy > ly;
cmp   ax, di
jle    return_true

return_false:
xor   ax, ax
LEAVE_MACRO
pop   di
ret   

;        return ly < ldy;

return_ly_below_ldy:
cmp  di, ax
jge  return_false

return_true:
mov   ax, 1
LEAVE_MACRO
pop   di
ret   

ldx_nonequal:

;    if (ldy == ly) {
cmp  ax, di

jne   ldy_nonzero

;        if (y.w <= (ly shift 16))
;  compare high bits

cmp   cx, di
jl    ret_ldx_less_than_lx
jne   ret_ldx_greater_than_lx
;  compare low bits
cmp   word ptr [bp - 02h], 0
jbe   ret_ldx_less_than_lx
ret_ldx_greater_than_lx:
;            return ldx > lx;

cmp   si, bx

jg    return_true

; return false
xor   ax, ax

LEAVE_MACRO
pop   di
ret   
ret_ldx_less_than_lx:

;            return ldx < lx;

cmp    si, bx

jle    return_true

; return false
xor   ax, ax

LEAVE_MACRO
pop   di
ret   
ldy_nonzero:

;	ldx -= lx;
;    ldy -= ly;

sub   si, bx
sub   ax, di




;    dx.w = (x.w - (lx shift 16));
;    dy.w = (y.w - (ly shift 16));


sub   dx, bx
sub   cx, di

;    Try to quickly decide by looking at sign bits.
;    if ( (ldy ^ ldx ^ dx.h.intbits ^ dy.h.intbits)&0x8000 )  // returns 1


mov   bx, ax
xor   bx, si
xor   bx, dx
xor   bx, cx
test  bh, 080h
jne   do_sign_bit_return

; gross - we must do a lot of work in this case. 
mov   di, cx  ; store cx.. 
pop   bx
mov   cx, dx
;call FixedMul1632_
db 0FFh  ; lcall[addr]
db 01Eh  ;
dw _FixedMul1632_addr


; set up params..
pop   bx
mov   cx, di
push  ax
mov   ax, si
mov   di, dx
;call FixedMul1632_
db 0FFh  ; lcall[addr]
db 01Eh  ;
dw _FixedMul1632_addr

cmp   dx, di
jg    return_true_2
je    check_lowbits
return_false_2:
xor   ax, ax

LEAVE_MACRO
pop   di
ret   

check_lowbits:
pop   cx ;  old AX
cmp   ax, cx
jb    return_false_2
return_true_2:
mov   ax, 1

LEAVE_MACRO
pop   di
ret   
do_sign_bit_return:

;		// (left is negative)
;		return  ((ldy ^ dx.h.intbits) & 0x8000);  // returns 1

xor   ax, dx
xor   al, al
and   ah, 080h


LEAVE_MACRO
pop   di
ret   


ENDP


PROC R_DrawSprite_ NEAR
PUBLIC R_DrawSprite_

; bp - 2	   ds_p segment. TODO always DRAWSEGS_BASE_SEGMENT_7000
; bp - 4       unused
; bp - 6       unused

; bp - 282h    cliptop
; bp - 502h    clipbot
; bp - 504h    vissprite near pointer

push  bx
push  cx
push  dx
push  si
push  di
push  bp
mov   bp, sp
sub   sp, 0502h	; for cliptop/clipbot
push  ax        ; bp - 504h
mov   bx, ax
mov   ax, word ptr [bx + 2]
mov   cx, word ptr [bx + 4]  ; spr->x2
cmp   ax, cx
jg    no_clip  ; todo im not sure if this conditional is possible. spr x2 < spr x1?
mov   di, ax


;	for (x = spr->x1; x <= spr->x2; x++) {
;		clipbot[x] = cliptop[x] = -2;
;	}
    
; init clipbot, cliptop

add   di, ax
mov   si, di
lea   di, [bp + di - 0282h]
mov   dx, ss
mov   es, dx
sub   cx, ax   				 ; minus spr->x1
inc   cx				     ; for the equals case.
mov   dx, cx
mov   ax, UNCLIPPED_COLUMN             ; -2
rep   stosw
lea   di, [bp + si - 0502h]
mov   cx, dx
rep   stosw


no_clip:
; di equals ds_p offset
mov   di, word ptr ds:[_ds_p]
mov   ax, DRAWSEGS_BASE_SEGMENT_7000
sub   di, DRAWSEG_SIZE		; sizeof drawseg
mov   word ptr [bp - 2], ax
jz   done_masking
check_loop_conditions:
mov   es, word ptr [bp - 2]

; compare ds->x1 > spr->x2
mov   ax, word ptr es:[di + 2]
cmp   ax, word ptr [bx + 4]
jg    iterate_next_drawseg_loop
jmp   continue_checking_if_drawseg_obscures_sprite
iterate_next_drawseg_loop:
mov   bx, word ptr [bp - 0504h]  ;todo put this after R_RenderMaskedSegRange_
sub   di, DRAWSEG_SIZE       ; sizeof drawseg
jnz   check_loop_conditions
done_masking:
; check for unclipped columns
mov   dx, bx  ; cache vissprite pointer
mov   cx, word ptr [bx + 4] ;x2
mov   si, word ptr [bx + 2] ;x1
sub   cx, si
jl    draw_the_vissprite
inc   cx
add   si, si
lea   si, [bp + si - 0502h]
mov   bx, (0502h - 0282h)  
mov   ax, word ptr ds:[_viewheight]

; todo optim loop
loop_clipping_columns:
cmp   word ptr ds:[si], UNCLIPPED_COLUMN
jne   dont_clip_bot
mov   word ptr ds:[si], ax
dont_clip_bot:
cmp   word ptr ds:[si+bx], UNCLIPPED_COLUMN
jne   dont_clip_top
mov   word ptr ds:[si+bx], 0FFFFh
dont_clip_top:
add   si, 2
loop loop_clipping_columns

draw_the_vissprite:

lea   ax, [bp - 0502h]
mov   word ptr ds:[_mfloorclip], ax
mov   word ptr ds:[_mfloorclip + 2], ds
add   ax, 0280h   ;  [bp - 0282h]

mov   word ptr ds:[_mceilingclip], ax
mov   word ptr ds:[_mceilingclip + 2], ds
mov   ax, dx    ; vissprite pointer from above
call  R_DrawVisSprite_
mov   word ptr ds:[_mceilingclip + 2], OPENINGS_SEGMENT
mov   word ptr ds:[_mfloorclip + 2], OPENINGS_SEGMENT

LEAVE_MACRO

pop   di
pop   si
pop   dx
pop   cx
pop   bx
ret   
continue_checking_if_drawseg_obscures_sprite:
; compare (ds->x2 < spr->x1)
mov   ax, word ptr es:[di + 4]
cmp   ax, word ptr [bx + 2]
jl    iterate_next_drawseg_loop
;  (!ds->silhouette     && ds->maskedtexturecol_val == NULL_TEX_COL) ) {
cmp   byte ptr es:[di + 01Ch], 0
jne   check_drawseg_scales
cmp   word ptr es:[di + 01Ah], NULL_TEX_COL
jne   check_drawseg_scales
jump_to_iterate_next_drawseg_loop_3:
jmp   iterate_next_drawseg_loop
check_drawseg_scales:

;		if (ds->scale1 > ds->scale2) {

;ax:dx = scale1. we will keep this throughout the scalecheckpass logic.
;cx  = scale2 high word. we will also keep this throughout the scalecheckpass logic.
;si  = spr scale high word. we will also keep this throughout the scalecheckpass logic.
mov   ax, word ptr es:[di + 8]
mov   dx, word ptr es:[di + 6]
mov   cx, word ptr es:[di + 0Ch]
mov   si, word ptr es:[di + 0Ah]
cmp   ax, cx
jg    scale1_highbits_larger_than_scale2
je    scale1_highbits_equal_to_scale2

scale1_smaller_than_scale2:

;lowscalecheckpass = ds->scale1 < spr->scale;
; ax:dx is ds->scale2

cmp   cx, word ptr [bx + 01Ch]
jl    set_r1_r2_and_render_masked_set_range
jne   lowscalecheckpass_set_route2
cmp   si, word ptr [bx + 01Ah]
jae   lowscalecheckpass_set_route2
jmp   set_r1_r2_and_render_masked_set_range


scale1_highbits_equal_to_scale2:
cmp   dx, si
jbe   scale1_smaller_than_scale2
scale1_highbits_larger_than_scale2:
;   bx is vissprite..
;			scalecheckpass = ds->scale1 < spr->scale;

;ax:dx = scale1

; if scalecheckpass is 0, go calculate lowscalecheck pass. 
; if not, the following if/else fails and we skip out early

cmp   ax, word ptr [bx + 01Ch]
jl    set_r1_r2_and_render_masked_set_range
jne   get_lowscalepass_1
cmp   dx, word ptr [bx + 01Ah]
jae   get_lowscalepass_1

;     scalecheckpass 1, fail early

set_r1_r2_and_render_masked_set_range:
;	if (ds->maskedtexturecol_val != NULL_TEX_COL) {
 
cmp   word ptr es:[di + 01Ah], NULL_TEX_COL
; continue
je    jump_to_iterate_next_drawseg_loop_3
;  r1 = ds->x1 < spr->x1 ? spr->x1 : ds->x1;
;  set r1 to the greater of the two.
mov   ax, word ptr es:[di + 2] ; ds->x1
cmp   ax, word ptr [bx + 2]
jge   r1_stays_ds_x1
mov   ax, word ptr [bx + 2]   ; spr->x1
r1_stays_ds_x1:

; r2 = ds->x2 > spr->x2 ? spr->x2 : ds->x2;
; set r2 as the minimum of the two.
mov   cx, word ptr [bx + 4]    ; spr->x2
cmp   cx, word ptr es:[di + 4]
jle   r2_stays_ds_x2

mov   cx, word ptr es:[di + 4] ; ds->x2

r2_stays_ds_x2:


do_render_masked_segrange:


call  R_RenderMaskedSegRange_
jmp   iterate_next_drawseg_loop
get_lowscalepass_1:

;			lowscalecheckpass = ds->scale2 < spr->scale;

;dx:bx = ds->scale2

cmp   cx, word ptr [bx + 01Ch]
jl    do_R_PointOnSegSide_check
jne   failed_check_pass_set_r1_r2
cmp   si, word ptr [bx + 01Ah]
jae   failed_check_pass_set_r1_r2

jmp   do_R_PointOnSegSide_check




lowscalecheckpass_set_route2:
;scalecheckpass = ds->scale2 < spr->scale;
; ax:dx is still ds->scale1


cmp   ax, word ptr [bx + 01Ch]
jl    do_R_PointOnSegSide_check
jne   failed_check_pass_set_r1_r2
cmp   dx, word ptr [bx + 01Ah]
jae   failed_check_pass_set_r1_r2

do_R_PointOnSegSide_check:


mov   si, word ptr es:[di]
mov   cx, word ptr [bx + 0Ch]
mov   ax, word ptr [bx + 6]
mov   dx, word ptr [bx + 8]
mov   bx, word ptr [bx + 0Ah]

; todo this is the only place calling this? make sense to inline?
call  R_PointOnSegSide_
test  ax, ax
mov   bx, word ptr [bp - 0504h]  ; todo remove?
mov   es, word ptr [bp - 2]     			; necessary
jne   failed_check_pass_set_r1_r2
jmp   set_r1_r2_and_render_masked_set_range

failed_check_pass_set_r1_r2:

;		r1 = ds->x1 < spr->x1 ? spr->x1 : ds->x1;


mov   si, word ptr es:[di + 2]  ; spr->x1
cmp   si, word ptr [bx + 2]     ; ds->x1 
jl    spr_x1_smaller_than_ds_x1

jmp   r1_set

spr_x1_smaller_than_ds_x1:
mov   si, word ptr [bx + 2]
r1_set:

;		r2 = ds->x2 > spr->x2 ? spr->x2 : ds->x2;

mov   dx, word ptr es:[di + 4]	; spr->x2
cmp   dx, word ptr [bx + 4]		; ds->x2
jg    spr_x2_greater_than_dx_x2

jmp   r2_set
jump_to_iterate_next_drawseg_loop_2:
jmp   iterate_next_drawseg_loop



spr_x2_greater_than_dx_x2:
mov   dx, word ptr [bx + 4]
r2_set:

; si is r1 and dx is r2
; bx is near vissprite
; es:di is drawseg
; so only ax and cx are free.
; lets precalculate the loop count into cx, freeing up dx.
mov   cx, dx
sub   cx, si
jl    jump_to_iterate_next_drawseg_loop_2 
inc   cx



;        silhouette = ds->silhouette;
;    	SET_FIXED_UNION_FROM_SHORT_HEIGHT(temp, ds->bsilheight);

mov   al, byte ptr es:[di + 01Ch]
mov   byte ptr cs:[SELFMODIFY_set_al_to_silhouette+1 - OFFSET R_DrawFuzzColumn_],  al

mov   ax, word ptr es:[di + 012h]
xor   dx, dx
sar   ax, 1
rcr   dx, 1
sar   ax, 1
rcr   dx, 1
sar   ax, 1
rcr   dx, 1

;ax:dx = temp
cmp   ax, word ptr [bx + 010h]

;		if (spr->gz.w >= temp.w) {
;			silhouette &= ~SIL_BOTTOM;
;		}

jl    remove_bot_silhouette
jg   do_not_remove_bot_silhouette
cmp   dx, word ptr [bx + 0Eh]
ja    do_not_remove_bot_silhouette
remove_bot_silhouette:
and   byte ptr cs:[SELFMODIFY_set_al_to_silhouette+1 - OFFSET R_DrawFuzzColumn_], 0FEh  
do_not_remove_bot_silhouette:

mov   ax, word ptr es:[di + 014h]
xor   dx, dx
sar   ax, 1
rcr   dx, 1
sar   ax, 1
rcr   dx, 1
sar   ax, 1
rcr   dx, 1

;cx:ax = temp

;		if (spr->gzt.w <= temp.w) {
;			silhouette &= ~SIL_TOP;
;		}

cmp   ax, word ptr [bx + 014h]
mov   ah,  0FFh		; for later and
jg    remove_top_silhouette
jl   do_not_remove_top_silhouette
cmp   dx, word ptr [bx + 012h]

jb    do_not_remove_top_silhouette
remove_top_silhouette:

; ok. this is too close to the following instruction to and to 0FD so instead, 
; we put the value to AND into ah.
mov   ah,  0FDh

do_not_remove_top_silhouette:

mov   dx, OPENINGS_SEGMENT
mov   ds, dx

add   si, si

; si is r1 and dx is r2
; bx is near vissprite
; es:di is drawseg


SELFMODIFY_set_al_to_silhouette:
mov   al, 0FFh ; this gets selfmodified
and   al, ah   ; second AND is applied 
cmp   al, 1
jne   silhouette_not_1

do_silhouette_1_loop:


mov   bx, word ptr es:[di + 018h]
silhouette_1_loop:
cmp   word ptr [bp + si - 0502h], UNCLIPPED_COLUMN
jne   increment_silhouette_1_loop

mov   ax, word ptr ds:[bx+si]
mov   word ptr [bp + si - 0502h], ax
increment_silhouette_1_loop:
add   si, 2
loop   silhouette_1_loop
mov   ax, ss
mov   ds, ax
jmp   iterate_next_drawseg_loop  ;todo change the flow to go to the other jump

silhouette_not_1:
cmp   al, 2
jne   silhouette_not_2


mov   bx, word ptr es:[di + 016h]

silhouette_2_loop:
cmp   word ptr [bp + si - 0282h], UNCLIPPED_COLUMN
jne   increment_silhouette_2_loop

mov   ax, word ptr ds:[bx+si]
mov   word ptr [bp + si - 0282h], ax
increment_silhouette_2_loop:
add   si, 2
loop   silhouette_2_loop
mov   cx, ss
mov   ds, cx
jmp   iterate_next_drawseg_loop  ;todo change the flow to go to the other jump
silhouette_not_2:
cmp   al, 3
je    silhouette_is_3
jump_to_iterate_next_drawseg_loop:
mov   cx, ss
mov   ds, cx
jmp   iterate_next_drawseg_loop
silhouette_is_3:

mov   bx, word ptr es:[di + 018h]
mov   dx, word ptr es:[di + 016h]

silhouette_3_loop:

cmp   word ptr [bp + si - 0502h], UNCLIPPED_COLUMN
jne   do_next_silhouette_3_subloop



mov   ax, word ptr ds:[bx+si]
mov   word ptr [bp + si - 0502h], ax
do_next_silhouette_3_subloop:
cmp   word ptr [bp + si - 0282h], UNCLIPPED_COLUMN
jne   increment_silhouette_3_loop

xchg  bx, dx
mov   ax, word ptr ds:[bx+si]
mov   word ptr [bp + si - 0282h], ax
xchg  bx, dx

increment_silhouette_3_loop:

add   si, 2

loop   silhouette_3_loop
mov   cx, ss
mov   ds, cx
jmp   iterate_next_drawseg_loop


ENDP

R_SORTVISSPRITES_OFFSET = OFFSET R_SortVisSprites_ - OFFSET R_DrawMaskedColumn_
VISSPRITE_SORTED_HEAD_INDEX = 0FEh

PROC R_DrawMasked_ FAR
PUBLIC R_DrawMasked_

push bx
push cx
push dx
push si
push di

;call R_SortVisSprites_

db 09Ah
dw R_SORTVISSPRITES_OFFSET 
dw DRAWMASKEDFUNCAREA_SPRITE_SEGMENT 



; adjust ds_p to be 7000 based instead of 9000 based due to different masked task mappings.
sub  word ptr ds:[_ds_p + 2], (DRAWSEGS_BASE_SEGMENT - DRAWSEGS_BASE_SEGMENT_7000)	
;    if (vissprite_p > 0) {
cmp  word ptr ds:[_vissprite_p], 0
jle  done_drawing_sprites

;	for (spr = vsprsortedheadfirst ;
;       spr != VISSPRITE_SORTED_HEAD_INDEX ;
;       spr=vissprites[spr].next) {
;       R_DrawSprite (&vissprites[spr]);
;   }

mov  al, byte ptr ds:[_vsprsortedheadfirst]
cmp  al, VISSPRITE_SORTED_HEAD_INDEX
je   done_drawing_sprites
draw_next_sprite:
mov  ah, SIZEOF_VISSPRITE_T
mul  ah
add  ax, OFFSET _vissprites
mov  bx, ax
call R_DrawSprite_
mov  al, byte ptr ds:[bx]


cmp  al, VISSPRITE_SORTED_HEAD_INDEX
jne  draw_next_sprite
done_drawing_sprites:

les  di, dword ptr ds:[_ds_p]

sub  di, SIZEOF_DRAWSEG_T

jle  done_rendering_masked_segranges
mov  si, es
check_next_seg:
cmp  word ptr es:[di + 01Ah], NULL_TEX_COL
je   not_masked

mov  ax, word ptr es:[di + 2]
mov  cx, word ptr es:[di + 4]

call R_RenderMaskedSegRange_
mov  es, si
not_masked:
sub  di, SIZEOF_DRAWSEG_T

ja   check_next_seg
done_rendering_masked_segranges:
call R_DrawPlayerSprites_
pop  di
pop  si
pop  dx
pop  cx
pop  bx
retf

ENDP




; ax pixelsegment
; cx:bx column
; todo: use es:bx instead of cx.

;
; R_DrawMaskedColumn
;
	
PROC  R_DrawMaskedColumn_ FAR
PUBLIC  R_DrawMaskedColumn_ 

;  bp - 02 cx/maskedcolumn segment
;  bp - 04  ax/pixelsegment cache
;  bp - 06  cached dc_texturemid intbits to restore before function

; todo: synergy with outer function... cx and es

push  dx
push  si
push  di
push  bp
mov   bp, sp
push  cx            ; bp - 2
mov   si, bx        ; si now holds column address.
mov   es, cx
push  ax            ; bp - 4

mov   cx, word ptr ds:[_dc_texturemid+2]
push  cx            ; bp - 6
xor   di, di        ; di used as currentoffset.

cmp   byte ptr es:[si], 0FFh
jne   draw_next_column_patch
jmp   exit_function
draw_next_column_patch:

;        topscreen.w = sprtopscreen + FastMul16u32u(column->topdelta, spryscale.w);

mov   bx, word ptr ds:[_spryscale]
mov   ax, word ptr ds:[_spryscale+2]

mov   cl, byte ptr es:[si]
xor   ch, ch

;inlined fastmul16u32u
MUL  CX        ; AX * CX
XCHG CX, AX    ; store low product to be high result. Retrieve orig AX
MUL  BX        ; AX * BX
ADD  DX, CX    ; add 

; bx was preserved im mul
; DX:AX = fastmult result. 


add   ax, word ptr ds:[_sprtopscreen]
adc   dx, word ptr ds:[_sprtopscreen+2]

; topscreen = DX:AX.

;		dc_yl = topscreen.h.intbits; 
;		if (topscreen.h.fracbits)
;			dc_yl++;


neg  ax
adc  dx, 0
mov  ds:[_dc_yl], dx
neg  ax
sbb  dx, 0

mov  ds, ax    ; store old topscreen
mov  ax, word ptr ss:[_spryscale+2]    ; use ss as ds as a hack...

mov  cl, byte ptr es:[si + 1] ; get length for mult
xor  ch, ch

mov  es, dx   ;  es:ds stores old topscreen result
 

;inlined fastmul16u32u
MUL  CX        ; AX * CX
XCHG CX, AX    ; store low product to be high result. Retrieve orig AX
MUL  BX        ; AX * BX
ADD  DX, CX    ; add 


;        bottomscreen.w = topscreen.w + FastMul16u32u(column->length, spryscale.w);
; add cached topscreen
mov   cx, ds
add   ax, cx
mov   cx, es
adc   dx, cx
mov   cx, ss
mov   ds, cx


;		dc_yh = bottomscreen.h.intbits;
;		if (!bottomscreen.h.fracbits)
;			dc_yh--;

neg ax
sbb dx, 0h


; dx is dc_yh but needs to be written back 

; dc_yh, dc_yl are set



;        if (dc_yh >= mfloorclip[dc_x])
;            dc_yh = mfloorclip[dc_x]-1;


mov   bx, word ptr ds:[_dc_x]
sal   bx, 1
les   ax, dword ptr ds:[_mfloorclip]
add   bx, ax

mov   cx, word ptr es:[bx]
cmp   dx, cx
jl    skip_floor_clip_set
mov   dx, cx
dec   dx
skip_floor_clip_set:
mov   word ptr ds:[_dc_yh], dx


;        if (dc_yl <= mceilingclip[dc_x])
;            dc_yl = mceilingclip[dc_x]+1;

sub   bx, ax
les   ax, dword ptr ds:[_mceilingclip]   
add   bx, ax

mov   ax, word ptr ds:[_dc_yl]
mov   cx, word ptr es:[bx]
cmp   ax, cx
jg    skip_ceil_clip_set
mov   ax, cx
inc   ax
mov   word ptr ds:[_dc_yl], ax
skip_ceil_clip_set:

cmp   ax, word ptr ds:[_dc_yh]
jg    increment_column_and_continue_loop
mov   bx, di

IF COMPILE_INSTRUCTIONSET GE COMPILE_186
shr   bx, 4
ELSE
shr   bx, 1
shr   bx, 1
shr   bx, 1
shr   bx, 1
ENDIF

mov   dx, word ptr [bp - 6]
les   ax, dword ptr [bp - 4]
add   ax, bx
mov   word ptr ds:[_dc_source_segment], ax
mov   al, byte ptr es:[si]
xor   ah, ah
sub   dx, ax
mov   word ptr ds:[_dc_texturemid+2], dx
mov   ax, COLORMAPS_MASKEDMAPPING_SEG_DIFF

db 09Ah
dw R_DRAWCOLUMNPREPCALLOFFSET 
dw COLFUNC_MASKEDMAPPING_SEGMENT 

increment_column_and_continue_loop:
mov   es, word ptr [bp-2]
mov   al, byte ptr es:[si + 1]
xor   ah, ah

add   di, ax

neg   ax
and   ax, 0Fh
add   si, 2
add   di, ax
cmp   byte ptr es:[si], 0FFh
je    exit_function
jmp   draw_next_column_patch ; todo inverse and skip jump
exit_function:

pop   ax; , word ptr [bp - 6]             ; restore dc_texture_mid
mov   word ptr ds:[_dc_texturemid+2], ax
mov   cx, es               ; restore cx
LEAVE_MACRO
pop   di
pop   si
pop   dx
retf


ENDP


VISSPRITE_UNSORTED_INDEX    = 0FFh
VISSPRITE_SORTED_HEAD_INDEX = 0FEh

; note: selfmodifies in this are based off R_DrawMaskedColumn_ as 0

PROC R_SortVisSprites_ FAR
PUBLIC R_SortVisSprites_

; bp - 2     vsprsortedheadfirst ?
; bp - 4     best ?
; bp - 8     UNUSED i (loop counter). todo selfmodify out.
; bp - 0ah   UNUSED vissprite_p pointer/count todo selfmodify out
; bp -034h   unsorted?


mov       ax, word ptr ds:[_vissprite_p]
test      ax, ax
jne       count_not_zero
retf


count_not_zero:
push      bx
push      cx
push      dx
push      si
push      di
push      bp
mov       bp, sp
sub       sp, 034h				; let's set things up finally isnce we're not quick-exiting out

mov       byte ptr cs:[SELFMODIFY_loop_compare_instruction+1 - OFFSET R_DrawMaskedColumn_], al ; store count
mov       dx, ax
mov       cx, 014h
lea       di, [bp - 034h]
mov       ax, ds
mov       es, ax
xor       ax, ax
rep stosw



mov       bx, OFFSET _vissprites
; dl is vissprite count
loop_set_vissprite_next:
; ax already 0

inc       al
mov       byte ptr ds:[bx], al
add       bx, SIZEOF_VISSPRITE_T  
cmp       ax, dx
jl        loop_set_vissprite_next

done_setting_vissprite_next:

sub        bx, SIZEOF_VISSPRITE_T
mov       byte ptr cs:[SELFMODIFY_set_al_to_loop_counter+1 - OFFSET R_DrawMaskedColumn_], 0  ; zero loop counter

mov       al, VISSPRITE_SORTED_HEAD_INDEX

mov       byte ptr [bp - 2], al
mov       byte ptr ds:[_vsprsortedheadfirst], al
mov       byte ptr [bx], VISSPRITE_UNSORTED_INDEX
cmp       dx, 0  ; is this redundant?
jle       exit_sort_vissprites

loop_visplane_sort:

inc       byte ptr cs:[SELFMODIFY_set_al_to_loop_counter+1 - OFFSET R_DrawMaskedColumn_] ; update loop counter

;DI:CX is bestscale
;        bestscale = MAXLONG;

mov       cx, 0FFFFh  ; max long low word
mov       di, 07FFFh  ; max long hi word

;        for (ds=unsorted.next ; ds!= VISSPRITE_UNSORTED_INDEX ; ds=vissprites[ds].next) {

mov       si, OFFSET _vissprites
mov       al, byte ptr [bp - 034h]  ; ds=unsorted.next
cmp       al, VISSPRITE_UNSORTED_INDEX ; ds!= VISSPRITE_UNSORTED_INDEX
je        done_with_sort_subloop
loop_sort_subloop:
mov       ah, SIZEOF_VISSPRITE_T
mov       bx, ax
mul       ah
xchg      ax, bx

mov       word ptr [bp - 06h], 0  ; field in unsorted
mov       word ptr [bp - 08h], bx ; field in unsorted
cmp       di, word ptr [bx + si + + 1Ah + 2]
jg        unsorted_next_is_best_next
jne       prepare_find_best_index_subloop
cmp       cx, word ptr [bx + si + 1Ah]
jbe       prepare_find_best_index_subloop
unsorted_next_is_best_next:
mov       dh, al  ;  store bestindex ( i think)
mov       cx, word ptr [bx + si + 1Ah]
mov       di, word ptr [bx + si + 1Ah + 2]
add       bx, si
mov       word ptr [bp - 4], bx   ; todo dont add vissprites to this?

prepare_find_best_index_subloop:

mul       ah	  ; still 028h (SIZEOF_VISSPRITE_T )
mov       bx, ax

mov       al, byte ptr [bx+si]
cmp       al, VISSPRITE_UNSORTED_INDEX
jne       loop_sort_subloop
done_with_sort_subloop:
mov       di, word ptr [bp - 4]		; retrieve best visprite pointer
mov       al, byte ptr [bp - 034h]

cmp       al, dh
je        done_with_find_best_index_loop
mov       dl, SIZEOF_VISSPRITE_T
loop_find_best_index:
mul       dl
mov       word ptr [bp - 0Ah], 0  ; some unsorted field
mov       bx, ax
mov       word ptr [bp - 0Ch], ax ; some unsorted field
mov       al, byte ptr [bx + si]

cmp       al, dh
jne       loop_find_best_index



; vissprites[ds].next = best->next;
 ;break;

mov       al, byte ptr [di]
mov       byte ptr [bx+si], al
jmp       found_best_index
exit_sort_vissprites:

LEAVE_MACRO

pop       di
pop       si
pop       dx
pop       cx
pop       bx
retf       

done_with_find_best_index_loop:


mov       al, byte ptr [di]
mov       byte ptr [bp - 034h], al
found_best_index:
;        if (vsprsortedheadfirst == VISSPRITE_SORTED_HEAD_INDEX){
cmp       byte ptr ds:[_vsprsortedheadfirst], VISSPRITE_SORTED_HEAD_INDEX
jne       set_next_to_best_index

mov       byte ptr ds:[_vsprsortedheadfirst], dh
increment_visplane_sort_loop_variables:

mov       byte ptr [bp - 2], dh
mov       byte ptr [di], VISSPRITE_SORTED_HEAD_INDEX
SELFMODIFY_set_al_to_loop_counter:
mov       al, 0FFh ; get loop counter
SELFMODIFY_loop_compare_instruction:
cmp       al, 0FFh ; compare
jge       exit_sort_vissprites
jmp       loop_visplane_sort

set_next_to_best_index:
;            vissprites[vsprsortedheadprev].next = bestindex;

mov       al, byte ptr [bp - 2]
mov	      ah, SIZEOF_VISSPRITE_T
mul       ah
mov       bx, ax

mov       byte ptr [bx + _vissprites], dh
jmp       increment_visplane_sort_loop_variables

ENDP



END
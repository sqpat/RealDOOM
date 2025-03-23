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
SCALE_LIGHT_OFFSET_IN_FIXED_SCALELIGHT = 030h




;=================================

.CODE


PROC  R_MASKED_STARTMARKER_
PUBLIC  R_MASKED_STARTMARKER_

ENDP

FUZZTABLE = 50

; extended length of a max run...
_fuzzoffset:
dw  00050h, 0FFB0h, 00050h, 0FFB0h, 00050h, 00050h, 0FFB0h, 00050h, 00050h, 0FFB0h 
dw  00050h, 00050h, 00050h, 0FFB0h, 00050h, 00050h, 00050h, 0FFB0h, 0FFB0h, 0FFB0h
dw  0FFB0h, 00050h, 0FFB0h, 0FFB0h, 00050h, 00050h, 00050h, 00050h, 0FFB0h, 00050h
dw  0FFB0h, 00050h, 00050h, 0FFB0h, 0FFB0h, 00050h, 00050h, 0FFB0h, 0FFB0h, 0FFB0h
dw  0FFB0h, 00050h, 00050h, 00050h, 00050h, 0FFB0h, 00050h, 00050h, 0FFB0h, 00050h
dw  00050h, 0FFB0h, 00050h, 0FFB0h, 00050h, 00050h, 0FFB0h, 00050h, 00050h, 0FFB0h
dw  00050h, 00050h, 00050h, 0FFB0h, 00050h

_fuzzpos:
dw 0

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
mov  si, word ptr cs:[_fuzzpos - OFFSET R_MASKED_STARTMARKER_]	; note this is always the byte offset - no shift conversion necessary

;  need to put di in cx
xchg cx, di   ; cx gets count , di gets screen offset

mov  ax, cs     ; cs:0 is fuzzpos
mov  ds, ax
; constant space
mov  dx, 04Fh
mov  ch, 010h

; todo: store count in cx not di?


push bp
mov  bx, COLORMAPS_MASKEDMAPPING_SEG_OFFSET_IN_CS





cmp  cl, ch
jg   draw_16_fuzzpixels
jmp  done_drawing_16_fuzzpixels
draw_16_fuzzpixels:



DRAW_SINGLE_FUZZPIXEL MACRO 



lodsw     						; load fuzz offset...
xchg ax, bp	       				; move offset to bx.
mov  al, byte ptr es:[bp + di]  ; read screen
xlat byte ptr cs:[bx]		    ; lookup colormaps + al byte
stosb							; write to screen
add  di, dx						; dx contains constant (0x4F) to add to di to get next screen dest.


ENDM

REPT 16
    DRAW_SINGLE_FUZZPIXEL
endm


cmp  si, FUZZTABLE * 2 ; word size
jl   fuzzpos_ok
; subtract 50 from fuzzpos
sub  si, FUZZTABLE * 2 ; word size
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
xchg ax, bp	       				; move offset to bx.
mov  al, byte ptr es:[bp + di]  ; read screen
xlat byte ptr cs:[bx]		    ; lookup colormaps + al byte
stosb							; write to screen
add  di, dx						; dx contains constant (0x4F) to add to di to get next screen dest.

cmp  si, FUZZTABLE * 2
je   zero_out_fuzzpos
finish_one_fuzzpixel_iteration:
loop  draw_one_fuzzpixel
; write back fuzzpos
finished_drawing_fuzzpixels:

pop bp


; restore ds
mov  di, ss
mov  ds, di

; write back fuzzpos

mov  word ptr word ptr cs:[_fuzzpos - OFFSET R_MASKED_STARTMARKER_], si

pop  es
pop  di
pop  si
retf 

zero_out_fuzzpos:
xor  si, si
loop  draw_one_fuzzpixel
jmp finished_drawing_fuzzpixels

ENDP



COLFUNC_JUMP_AND_DC_YL_OFFSET_DIFF   = ((DC_YL_LOOKUP_SEGMENT - COLFUNC_JUMP_LOOKUP_SEGMENT) * 16)
COLFUNC_JUMP_AND_FUNCTION_AREA_OFFSET_DIFF = ((COLFUNC_FUNCTION_AREA_SEGMENT - COLFUNC_JUMP_LOOKUP_SEGMENT) * 16)


; multi/single refer to whether this is drawing masked columns
; that may have multiple segments (real masked textures)
; or are single (false walls like e1m1)
; this function is not actually significantly different but there are
; different codepaths leading here. So its easier to have different variables in
; registers in either case.
; todo: investigate making them the same after all?

;
; R_DrawColumnPrepMaskedMulti
;

; this version called for almost all masked calls	
PROC  R_DrawColumnPrepMaskedMulti_
PUBLIC  R_DrawColumnPrepMaskedMulti_ 

; argument AX is diff for various segment lookups

push  bx
push  cx
push  dx
push  si
push  di

xchg  ax, cx	; cx holds onto dc_texturemid lo. TODO move this out of function along with push/pop cx

mov   ax, (COLORMAPS_MASKEDMAPPING_SEG_DIFF + COLFUNC_JUMP_LOOKUP_SEGMENT) ; shut up assembler warning, this is fine
mov   es, ax                                 ; store this segment for now, with offset pre-added

; todo optimize this read
mov   ax, word ptr ds:[_dc_x]

; shift ax by (2 - detailshift.)
SELFMODIFY_MASKED_multi_detailshift_2_minus_16_bit_shift:
sar   ax, 1
sar   ax, 1

; dest = destview + dc_yl*80 + (dc_x>>2); 
; frac.w = dc_texturemid.w + (dc_yl-centery)*dc_iscale

; todo optimize this read
mov   bx, word ptr ds:[_dc_yl]
mov   si, bx
add   ax, word ptr es:[bx+si+COLFUNC_JUMP_AND_DC_YL_OFFSET_DIFF]                  ; set up destview 
SELFMODIFY_MASKED_destview_lo_3:
add   ax, 01000h

; todo optimize this read
mov   si, word ptr ds:[_dc_yh]                  ; grab dc_yh
sub   si, bx                                 ;

add   si, si                                 ; double diff (dc_yh - dc_yl) to get a word offset
xchg  ax, di
mov   ax, word ptr es:[si]                   ; get the jump value
mov   word ptr es:[((SELFMODIFY_COLFUNC_jump_offset+1))+COLFUNC_JUMP_AND_FUNCTION_AREA_OFFSET_DIFF], ax  ; overwrite the jump relative call for however many iterations in unrolled loop we need

; what follows is compution of desired CS segment and offset to function to allow for colormaps to be CS:BX and match DS:BX column
; or can we do this in an outer func without this instrction?


; if we make a separate drawcol masked we can use a constant here.

xchg  ax, bx    ; dc_yl in ax
mov   si, dx    ; dc_texturemid+2 in si

cli 	        ; disable interrupts
push  bp
mov   bp, cx    ; dc_textutremid in cx

; dynamic call lookuptable based on used colormaps address being CS:00

SELFMODIFY_MASKED_set_dc_iscale_lo:
mov   bx, 01000h ; dc_iscale +0
SELFMODIFY_MASKED_set_dc_iscale_hi:
mov   cx, 01000h ; dc_iscale +1


db 0FFh  ; lcall[addr]
db 01Eh  ;
SELFMODIFY_MASKED_multi_set_colormap_index_jump:
dw 0400h
; addr 0400 + first byte (4x colormap.)

pop   bp
sti             ; re-enable interrupts
pop   di 
pop   si
pop   dx
pop   cx
pop   bx
ret

ENDP





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

; note: this function is called so rarely i don't care if its a little more innefficient.
; it is called for reverse visible walls like in e1m1's slime REALDOOM



mov   word ptr ds:[_dc_source_segment], ax	; set this early. 

; slow and ugly - infer it anohter way later if possible.
mov   al, byte ptr cs:[SELFMODIFY_MASKED_multi_set_colormap_index_jump - OFFSET R_MASKED_STARTMARKER_]
mov   byte ptr cs:[SELFMODIFY_MASKED_set_colormap_index_jump - OFFSET R_MASKED_STARTMARKER_], al


mov   cl, dl
xor   ch, ch		; count used once for mul and not again. todo is dh already zero?



;    topscreen.w = sprtopscreen;

; es in use down below
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
mov   di, bx ; copy dc_x to di...
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


; dx/si contain dc_yh/dc_yl

; todo: this can be a second, local version of the function that is specialized?

; inlined R_DrawColumnPrepMaskedSingle_


mov   ax, (COLORMAPS_MASKEDMAPPING_SEG_DIFF + COLFUNC_JUMP_LOOKUP_SEGMENT) ; shut up assembler warning, this is fine
mov   es, ax                                 ; store this segment for now, with offset pre-added

;dx is dc_yh
;si is dc_yl
;di is dc_x


; grab dc_x..
xchg   ax, di

; shift ax by (2 - detailshift.)
SELFMODIFY_MASKED_detailshift_2_minus_16_bit_shift:
sar   ax, 1
sar   ax, 1

; dest = destview + dc_yl*80 + (dc_x>>2); 
; frac.w = dc_texturemid.w + (dc_yl-centery)*dc_iscale

mov   bx, si
add   ax, word ptr es:[bx+si+COLFUNC_JUMP_AND_DC_YL_OFFSET_DIFF]                  ; set up destview 
SELFMODIFY_MASKED_destview_lo_2:
add   ax, 01000h

mov   si, dx                                 ; grab dc_yh
sub   si, bx                                 ;

add   si, si                                 ; double diff (dc_yh - dc_yl) to get a word offset
xchg  ax, di
mov   ax, word ptr es:[si]                   ; get the jump value
mov   word ptr es:[((SELFMODIFY_COLFUNC_jump_offset+1))+COLFUNC_JUMP_AND_FUNCTION_AREA_OFFSET_DIFF], ax  ; overwrite the jump relative call for however many iterations in unrolled loop we need

; what follows is compution of desired CS segment and offset to function to allow for colormaps to be CS:BX and match DS:BX column
; or can we do this in an outer func without this instrction?
 

; if we make a separate drawcol masked we can use a constant here.

xchg  ax, bx    ; dc_yl in ax
; gross lol. but again - rare function. in exchange the common function is faster.
mov   si, word ptr cs:[SELFMODIFY_MASKED_dc_texturemid_hi_1+1 - OFFSET R_MASKED_STARTMARKER_]
mov   bx, word ptr cs:[SELFMODIFY_MASKED_set_dc_iscale_lo+1 - OFFSET R_MASKED_STARTMARKER_]
mov   cx, word ptr cs:[SELFMODIFY_MASKED_set_dc_iscale_hi+1 - OFFSET R_MASKED_STARTMARKER_]

cli 	        ; disable interrupts
push  bp
mov   bp, word ptr cs:[SELFMODIFY_MASKED_dc_texturemid_lo_1+1 - OFFSET R_MASKED_STARTMARKER_]



; dynamic call lookuptable based on used colormaps address being CS:00

db 0FFh  ; lcall[addr]
db 01Eh  ;
SELFMODIFY_MASKED_set_colormap_index_jump:
dw 0400h
; addr 0400 + first byte (4x colormap.)

pop   bp
sti             ; re-enable interrupts



exit_function_single:


pop   bp
pop   di
pop   si
pop   cx
pop   bx
retf   

ENDP

UNCLIPPED_COLUMN  = 0FFFEh



; note remove masked start from here 

jump_to_exit_draw_shadow_sprite:
jmp   exit_draw_shadow_sprite

PROC R_DrawMaskedSpriteShadow_ NEAR
PUBLIC R_DrawMaskedSpriteShadow_

; ax 	 pixelsegment
; cx:bx  column fardata

; bp - 2     topscreen  segment


push  dx
push  si
push  di
push  bp
mov   bp, sp
sub   sp, 2
mov   si, bx

mov   es, cx


; es is already cx
cmp   byte ptr es:[si], 0FFh  ; todo cant this check be only at the end? can this be called with 0 posts?
je    jump_to_exit_draw_shadow_sprite
draw_next_shadow_sprite_post:
; es is in use
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


add   ax, word ptr ds:[_sprtopscreen]
mov   word ptr [bp - 2], ax
adc   dx, word ptr ds:[_sprtopscreen + 2]
mov   cx, dx

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


mov   bx, cx   ; bx store _sprtopscreen + 2
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
les   di, dword ptr ds:[_mfloorclip]
add   bx, bx
cmp   ax, word ptr es:[bx + di]   ; ax holds dc_yh
jl    dc_yh_clipped_to_floor
mov   ax, word ptr es:[bx + di]
dec   ax
dc_yh_clipped_to_floor:


les   di, dword ptr ds:[_mceilingclip]

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

mov   bl, byte ptr es:[si]

xor   bh, bh
sub   ax, bx
cmp   dx, 0			; dx still holds dc_yl
jne   high_border_adjusted
inc   dx 
high_border_adjusted:
SELFMODIFY_MASKED_viewheight_1:
mov   ax, 01000h
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
SELFMODIFY_MASKED_detailshiftplus1_1:
add   al, 0
mov   byte ptr cs:[SELFMODIFY_MASKED_set_bx_to_lookup+1 - OFFSET R_MASKED_STARTMARKER_], al
mov   cx, DC_YL_LOOKUP_MASKEDMAPPING_SEGMENT

add   bx, bx
mov   ax, es
mov   es, cx

; todo: proper shift jmp thing.
mov   cl, byte ptr ds:[_detailshift2minus]
sar   dx, cl
SELFMODIFY_MASKED_destview_lo_1:
add   dx, 1000h   ; need the 2 byte constant.
add   dx, word ptr es:[bx]
mov   es, ax

mov   cx, dx

; vga plane stuff.
mov   dx, SC_DATA
SELFMODIFY_MASKED_set_bx_to_lookup:
mov   bx, 0
mov   al, byte ptr ds:[bx + _quality_port_lookup]

out   dx, al
add   bx, bx
mov   dx, GC_INDEX
mov   ax, word ptr ds:[bx + _vga_read_port_lookup]
out   dx, ax

SELFMODIFY_MASKED_destview_hi_1:
mov   bx, 0

; pass in count via di
; pass in destview via bx
; pass in offset via cx

; todo - fix cs/colormaps offset data?
call R_DrawFuzzColumn_



do_next_shadow_sprite_iteration:
add   si, 2
cmp   byte ptr es:[si], 0FFh
je    exit_draw_shadow_sprite
jmp   draw_next_shadow_sprite_post
exit_draw_shadow_sprite:

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

; si is vissprite_t near pointer

; bp - 2  	 frac.h.fracbits
; bp - 4  	 frac.h.intbits
; bp - 6     xiscalestep_shift low word
; bp - 8     xiscalestep_shift high word


push  bp
mov   bp, sp


mov   al, byte ptr ds:[si + 1]

; al is colormap. 

mov   byte ptr cs:[SELFMODIFY_MASKED_multi_set_colormap_index_jump - OFFSET R_MASKED_STARTMARKER_], al

; todo move this out to a higher level! possibly when executesetviewsize happens.




les   ax, dword ptr ds:[si + 01Eh]   ; vis->xiscale
mov   dx, es

; labs
or    dx, dx
jge   xiscale_already_positive
neg   ax
adc   dx, 0
neg   dx
xiscale_already_positive:

;; todo proper jump thing
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


mov   dh, dl
mov   dl, ah
mov   word ptr cs:[SELFMODIFY_MASKED_set_dc_iscale_lo+1 - OFFSET R_MASKED_STARTMARKER_], ax
mov   word ptr cs:[SELFMODIFY_MASKED_set_dc_iscale_hi+1 - OFFSET R_MASKED_STARTMARKER_], dx




lea   di, ds:[_sprtopscreen]
mov   word ptr ds:[di], 0		; di is _sprtopscreen
SELFMODIFY_MASKED_centery_1:
mov   word ptr ds:[di + 2], 01000h

les   ax, dword ptr [si + 01Ah]  ; vis->scale
mov   dx, es

mov   word ptr ds:[_spryscale], ax
mov   word ptr ds:[_spryscale + 2], dx

les   bx, dword ptr [si + 022h] ; vis->texturemid
mov   cx, es
; write this ahead
mov   word ptr cs:[SELFMODIFY_MASKED_dc_texturemid_lo_1 + 1 - OFFSET R_MASKED_STARTMARKER_], bx
mov   word ptr cs:[SELFMODIFY_MASKED_dc_texturemid_hi_1 + 1 - OFFSET R_MASKED_STARTMARKER_], cx


test  dx, dx
jnz    do_32_bit_mul_vissprite

test ax, 08000h  ; high bit
do_16_bit_mul_after_all_vissprite:
jnz  do_32_bit_mul_after_all_vissprite

call FixedMul1632MaskedLocal_


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
SELFMODIFY_MASKED_detailshiftandval_1:
and   ax, 01000h

mov   word ptr cs:[SELFMODIFY_MASKED_set_ax_to_dc_x_base4+1 - OFFSET R_MASKED_STARTMARKER_], ax
mov   word ptr cs:[SELFMODIFY_MASKED_set_ax_to_dc_x_base4_shadow+1 - OFFSET R_MASKED_STARTMARKER_], ax

sub   dx, ax
xchg  ax, dx



; xiscalestep_shift = vis->xiscale << detailshift2minus;
; es in use
mov   bx, word ptr [si + 01Eh] ; DX:BX = vis->xiscale
mov   dx, word ptr [si + 020h]

; todo: proper shift jmp thing
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
; es in use
mov   dx, word ptr [si + 01Eh]
mov   bx, word ptr [si + 020h]

decrementbase4loop:
sub   word ptr [bp - 4], dx
sbb   word ptr [bp - 2], bx
dec   ax
jne   decrementbase4loop

base4diff_is_zero:

; zero xoffset loop iter
mov   byte ptr cs:[SELFMODIFY_MASKED_set_bx_to_xoffset+1 - OFFSET R_MASKED_STARTMARKER_], 0
mov   byte ptr cs:[SELFMODIFY_MASKED_set_bx_to_xoffset_shadow+1 - OFFSET R_MASKED_STARTMARKER_], 0

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
mov   es, ax
mov   ax, word ptr [si + 026h]
mov   word ptr ds:[_lastvisspritepatch], ax
jmp   spritesegment_ready
jump_to_draw_shadow_sprite:
jmp   draw_shadow_sprite

loop_vga_plane_draw_normal:

SELFMODIFY_MASKED_set_bx_to_xoffset:
mov   bx, 0 ; zero out bh
SELFMODIFY_MASKED_detailshiftitercount_1:
cmp   bx, 0
jge    exit_draw_vissprites


mov   dx, SC_DATA
SELFMODIFY_MASKED_detailshiftplus1_2:
mov   al, byte ptr ds:[bx + 20]
out   dx, al
; es seems to be in use
mov   di, word ptr [bp - 4]
mov   dx, word ptr [bp - 2]
SELFMODIFY_MASKED_set_ax_to_dc_x_base4:
mov   ax, 0
mov   word ptr ds:[_dc_x], ax
cmp   ax, word ptr [si + 2]
jl    increment_by_shift

draw_sprite_normal_innerloop:
mov   ax, word ptr ds:[_dc_x]
cmp   ax, word ptr [si + 4]
jg    end_draw_sprite_normal_innerloop
mov   bx, dx

SHIFT_MACRO shl bx 2

mov   ax, word ptr es:[bx + 8]
mov   bx, word ptr es:[bx + 10]

add   ax, cx

; ax pixelsegment
; cx:bx column
; dx unused
; cx is preserved by this call here
; so is ES

call R_DrawMaskedColumn_

SELFMODIFY_MASKED_detailshiftitercount_2:
add   word ptr ds:[_dc_x], 0
add   di, word ptr [bp - 8]
adc   dx, word ptr [bp - 6]
jmp   draw_sprite_normal_innerloop
exit_draw_vissprites:
LEAVE_MACRO


ret 
increment_by_shift:

SELFMODIFY_MASKED_detailshiftitercount_3:
add   ax, 0
mov   word ptr ds:[_dc_x], ax
add   di, word ptr [bp - 8]
adc   dx, word ptr [bp - 6]
jmp   draw_sprite_normal_innerloop

end_draw_sprite_normal_innerloop:
inc   word ptr cs:[SELFMODIFY_MASKED_set_ax_to_dc_x_base4+1 - OFFSET R_MASKED_STARTMARKER_]
inc   byte ptr cs:[SELFMODIFY_MASKED_set_bx_to_xoffset+1 - OFFSET R_MASKED_STARTMARKER_]
mov   ax, word ptr [si + 01Eh]
add   word ptr [bp - 4], ax
mov   ax, word ptr [si + 020h]
adc   word ptr [bp - 2], ax
jmp   loop_vga_plane_draw_normal
draw_shadow_sprite:

loop_vga_plane_draw_shadow:
SELFMODIFY_MASKED_set_bx_to_xoffset_shadow:
mov   bx, 0
SELFMODIFY_MASKED_detailshiftitercount_4:
cmp   bx, 0
jge    exit_draw_vissprites


mov   dx, SC_DATA
SELFMODIFY_MASKED_detailshiftplus1_3:
mov   al, byte ptr ds:[bx + 20]
out   dx, al
mov   di, word ptr [bp - 4]
mov   dx, word ptr [bp - 2]
SELFMODIFY_MASKED_set_ax_to_dc_x_base4_shadow:
mov   ax, 0
mov   word ptr ds:[_dc_x], ax

cmp   ax, word ptr [si + 2]
jle   increment_by_shift_shadow

draw_sprite_shadow_innerloop:
mov   ax, word ptr ds:[_dc_x]
cmp   ax, word ptr [si + 4]
jg    end_draw_sprite_shadow_innerloop
mov   bx, dx

SHIFT_MACRO shl bx 2

mov   ax, word ptr es:[bx + 8]
mov   bx, word ptr es:[bx + 10]

add   ax, cx

; cx, es preserved in the call

call R_DrawMaskedSpriteShadow_


SELFMODIFY_MASKED_detailshiftitercount_5:
add   word ptr ds:[_dc_x], 0
add   di, word ptr [bp - 8]
adc   dx, word ptr [bp - 6]
jmp   draw_sprite_shadow_innerloop

end_draw_sprite_shadow_innerloop:
inc   word ptr cs:[SELFMODIFY_MASKED_set_ax_to_dc_x_base4_shadow+1 - OFFSET R_MASKED_STARTMARKER_]
inc   byte ptr cs:[SELFMODIFY_MASKED_set_bx_to_xoffset_shadow+1 - OFFSET R_MASKED_STARTMARKER_]
mov   ax, word ptr [si + 01Eh]
add   word ptr [bp - 4], ax
mov   ax, word ptr [si + 020h]
adc   word ptr [bp - 2], ax
jmp   loop_vga_plane_draw_shadow

increment_by_shift_shadow:
SELFMODIFY_MASKED_detailshiftitercount_6:
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
mov  si, _player_vissprites       ; vissprite 0
call R_DrawVisSprite_

check_next_player_sprite:
cmp  word ptr ds:[_psprites + 0Ch], -1  ; STATENUM_NULL
je  exit_drawplayersprites
mov  si, _player_vissprites + SIZEOF_VISSPRITE_T
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

; no stack frame used..


  
push  si
push  di

; todo selfmodify all this up ahead too.


mov   word ptr cs:[SELFMODIFY_MASKED_x1_field_1+1 - OFFSET R_MASKED_STARTMARKER_], ax
mov   word ptr cs:[SELFMODIFY_MASKED_x1_field_2+1 - OFFSET R_MASKED_STARTMARKER_], ax
mov   word ptr cs:[SELFMODIFY_MASKED_x1_field_3+1 - OFFSET R_MASKED_STARTMARKER_], ax
mov   word ptr cs:[SELFMODIFY_MASKED_cmp_to_x2+1 - OFFSET R_MASKED_STARTMARKER_], cx

; grab a bunch of drawseg values early in the function and write them forward.
mov   si, di
lods  word ptr es:[si]  ; si 2 after

mov   word ptr ds:[_curseg], ax  
SHIFT_MACRO shl ax 3
add   ah, (_segs_render SHR 8 ) 		; segs_render is ds:[0x4000] 
mov   word ptr ds:[_curseg_render], ax
mov   bx, ax

; todo rearrange fields to make this faster?
; this whole charade with the lodsw is ~6-8 bytes smaller overall than just doing displacement.
; It could be better if we arranged adjacent fields i guess.
mov   ax, es
mov   ds, ax
lods  word ptr ds:[si]  ; si 4 after
mov   word ptr cs:[SELFMODIFY_MASKED_dsp_02+1 - OFFSET R_MASKED_STARTMARKER_], ax
inc   si
inc   si
lods  word ptr ds:[si]  ; si 8 after
mov   word ptr cs:[SELFMODIFY_MASKED_dsp_06+1 - OFFSET R_MASKED_STARTMARKER_], ax
lods  word ptr ds:[si]  ; si A after
add   si, 4
mov   word ptr cs:[SELFMODIFY_MASKED_dsp_08+2 - OFFSET R_MASKED_STARTMARKER_], ax
lods  word ptr ds:[si]  ; si 0x10 after
mov   word ptr cs:[SELFMODIFY_MASKED_dsp_0E+1 - OFFSET R_MASKED_STARTMARKER_], ax
lods  word ptr ds:[si]  ; si 0x12 after
mov   word ptr cs:[SELFMODIFY_MASKED_dsp_10+1 - OFFSET R_MASKED_STARTMARKER_], ax
add   si, 4
lods  word ptr ds:[si]  ; si 0x18 after
mov   word ptr cs:[SELFMODIFY_MASKED_dsp_16+4 - OFFSET R_MASKED_STARTMARKER_], ax
lods  word ptr ds:[si]  ; si 0x1A after
mov   word ptr cs:[SELFMODIFY_MASKED_dsp_18+4 - OFFSET R_MASKED_STARTMARKER_], ax
lods  word ptr ds:[si]  ; si 0x1C after
mov   word ptr cs:[SELFMODIFY_MASKED_dsp_1A+1 - OFFSET R_MASKED_STARTMARKER_], ax

mov   ax, ss
mov   ds, ax

mov   ax, SIDES_SEGMENT
mov   si, word ptr [bx + 6]			; get sidedefOffset
mov   es, ax
SHIFT_MACRO shl si 2
mov   bx, si						; side_render_t is 4 bytes each
shl   si, 1							; side_t is 8 bytes each
add   bh, (_sides_render SHR 8 )		; sides render near addr is ds:[0xAE00]
mov   si, word ptr es:[si + 4]		; lookup side->midtexture
mov   ax, word ptr [bx] 
mov   word ptr cs:[SELFMODIFY_MASKED_siderender_00+1 - OFFSET R_MASKED_STARTMARKER_], ax
mov   ax, word ptr [bx+2] 
mov   word ptr cs:[SELFMODIFY_MASKED_siderender_02+1 - OFFSET R_MASKED_STARTMARKER_], ax

mov   ax, TEXTURETRANSLATION_SEGMENT
add   si, si
mov   es, ax
mov   ax, MASKED_LOOKUP_SEGMENT_7000
mov   si, word ptr es:[si]			; get texnum. si is stored for the whole function. not good revisit.
mov   es, ax
mov   al, byte ptr es:[si]			; translate texnum to lookup

; put texnum where it needs to be
mov   word ptr cs:[SELFMODIFY_MASKED_texnum_1+1 - OFFSET R_MASKED_STARTMARKER_], si
mov   word ptr cs:[SELFMODIFY_MASKED_texnum_2+1 - OFFSET R_MASKED_STARTMARKER_], si
mov   word ptr cs:[SELFMODIFY_MASKED_texnum_3+3 - OFFSET R_MASKED_STARTMARKER_], si

cmp   al, 0FFh
jne   lookup_is_ff

mov   ax, ((SELFMODIFY_MASKED_lookup_1_TARGET - SELFMODIFY_MASKED_lookup_1_AFTER) SHL 8) + 0EBh
mov   bx, ((SELFMODIFY_MASKED_lookup_2_TARGET - SELFMODIFY_MASKED_lookup_2_AFTER) SHL 8) + 0EBh

jmp   do_lookup_selfmodifies
; still havent changed flags.

lookup_is_ff:
;		masked_header_t __near * maskedheader = &masked_headers[lookup];
;		maskedpostsofs = maskedheader->postofsoffset;
cbw


SHIFT_MACRO shl ax 3



mov   bx, ax
mov   ax, word ptr ds:[bx + _masked_headers + 2]
mov   word ptr cs:[SELFMODIFY_MASKED_maskedpostofs_1  +3 - OFFSET R_MASKED_STARTMARKER_], ax
mov   word ptr cs:[SELFMODIFY_MASKED_maskedpostofs_2+3 - OFFSET R_MASKED_STARTMARKER_], ax

; nops
mov   ax, 0c089h 
mov   bx, ax

do_lookup_selfmodifies:
; write instructions forward
mov   word ptr cs:[SELFMODIFY_MASKED_lookup_1 - OFFSET R_MASKED_STARTMARKER_], ax
mov   word ptr cs:[SELFMODIFY_MASKED_lookup_2 - OFFSET R_MASKED_STARTMARKER_], bx



mov   ax, SEG_LINEDEFS_SEGMENT
mov   es, ax
mov   ax, word ptr ds:[_curseg]
mov   bx, ax
add   bh, (seg_sides_offset_in_seglines SHR 8)		; seg_sides_offset_in_seglines high word
mov   dl, byte ptr es:[bx]		; ; dl is curlineside here
add   ax, ax
mov   bx, ax
mov   di, word ptr es:[bx]		; di holds curlinelinedef

mov   ax, LINEFLAGSLIST_SEGMENT
mov   es, ax
mov   al, byte ptr es:[di]
mov   bx, word ptr ds:[_curseg_render]   ; get curseg 

; lineflags jmp/nop selfmodify here
test  al, ML_DONTPEGBOTTOM
; nop 
mov   ax, 0c089h 
je    peg_bottom

mov   ax, ((SELFMODIFY_MASKED_lineflags_ml_dontpegbottom_TARGET - SELFMODIFY_MASKED_lineflags_ml_dontpegbottom_AFTER) SHL 8) + 0EBh
peg_bottom:
; write instruction forward
mov   word ptr cs:[SELFMODIFY_MASKED_lineflags_ml_dontpegbottom - OFFSET R_MASKED_STARTMARKER_], ax

mov   cx, word ptr [bx+2]			; get v2 offset
mov   bx, word ptr [bx]				; get v1 offset
mov   ax, VERTEXES_SEGMENT

SHIFT_MACRO shl bx 2
SHIFT_MACRO shl cx 2


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
mov   byte ptr cs:[SELFMODIFY_MASKED_add_vertex_field - OFFSET R_MASKED_STARTMARKER_], al


SELFMODIFY_MASKED_siderender_02:
mov   cx, 01000h		; get side_render secnum


; backsector = &sectors[sides_render[curlinelinedef->sidenum[curlineside ^ 1]].secnum]

;curlineside ^ 1
; (1 or 0)
mov   bx, 1
sub   bl, dl

SHIFT_MACRO shl di 2

mov   ax, LINES_SEGMENT
mov   es, ax
sal   bx, 1


mov   bx, word ptr es:[bx + di] ; get reverse side for the line

SHIFT_MACRO shl bx 2



mov   bx, word ptr ds:[bx + _sides_render + 2]   ; get backsecnum

SHIFT_MACRO shl bx 4




; bx holds backsector

mov   ax, SECTORS_SEGMENT
mov   es, ax
mov   di, cx        ; retrieve side_render secnum from above

SHIFT_MACRO SHL di 4

;mov   word ptr ds:[_frontsector], bx

; bx is backsector ptr
; di is frontsector ptr
; es is sector segment.

SELFMODIFY_MASKED_lineflags_ml_dontpegbottom:
jne   front_back_floor_case
SELFMODIFY_MASKED_lineflags_ml_dontpegbottom_AFTER:
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
ys_equal:
mov   al, 048h  ; dec ax instruction
jmp   done_comparing_vertexes
xs_equal:
mov   al, 040h  ; inc ax instruciton
jmp   done_comparing_vertexes


SELFMODIFY_MASKED_lineflags_ml_dontpegbottom_TARGET:
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

SELFMODIFY_MASKED_texnum_3:
mov   cl, byte ptr es:[01000h]
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

; ax:dx is textureheight (NOT DX:AX!!)
;    dc_texturemid.h.intbits += adder;		

add   ax, cx

;     dc_texturemid.w -= viewz.w;
SELFMODIFY_MASKED_viewz_lo_1:
sub   dx, 01000h
SELFMODIFY_MASKED_viewz_hi_1:
sbb   ax, 01000h



;    dc_texturemid.h.intbits += side_render->rowoffset;

SELFMODIFY_MASKED_siderender_00:
add   ax, 01000h


; dc_texturemid is a function contant. we selfmodify ahead:
mov   word ptr cs:[SELFMODIFY_MASKED_dc_texturemid_lo_1 + 1 - OFFSET R_MASKED_STARTMARKER_], dx
mov   word ptr cs:[SELFMODIFY_MASKED_dc_texturemid_lo_2 + 1 - OFFSET R_MASKED_STARTMARKER_], dx
mov   word ptr cs:[SELFMODIFY_MASKED_dc_texturemid_lo_3 + 1 - OFFSET R_MASKED_STARTMARKER_], dx
mov   word ptr cs:[SELFMODIFY_MASKED_dc_texturemid_hi_1 + 1 - OFFSET R_MASKED_STARTMARKER_], ax
mov   word ptr cs:[SELFMODIFY_MASKED_dc_texturemid_hi_2 + 1 - OFFSET R_MASKED_STARTMARKER_], ax
mov   word ptr cs:[SELFMODIFY_MASKED_dc_texturemid_hi_3 + 1 - OFFSET R_MASKED_STARTMARKER_], ax

mov   ax, SECTORS_SEGMENT
mov   es, ax

; di is frontsector
mov   al, byte ptr es:[di + 0Eh]   ; get sector lightlevel
xor   ah, ah



SHIFT_MACRO sar ax 4


mov   dx, ax
SELFMODIFY_MASKED_extralight_1:
mov   al, 0
add   ax, dx

SELFMODIFY_MASKED_add_vertex_field:
nop				; becomes inc ax, dec ax, or nop

;	if (lightnum < 0){
;test  ax, ax			; we get this for free via the above instructions
jl   set_walllights_zero
cmp   ax, LIGHTLEVELS
jge   clip_lights_to_max
mov   ah, 48
mul   ah
jmp   lights_set





set_walllights_zero:
xor   ax, ax
jmp   lights_set
SELFMODIFY_MASKED_fixedcolormap_2_TARGET:
fixed_colormap:
SELFMODIFY_MASKED_fixedcolormap_3:
mov   byte ptr cs:[SELFMODIFY_MASKED_multi_set_colormap_index_jump - OFFSET R_MASKED_STARTMARKER_], 0
jmp   colormap_set


clip_lights_to_max:
mov    ax, 720   ; hardcoded (lightmult48lookup[LIGHTLEVELS - 1])

lights_set:
add   ax, (SCALE_LIGHT_OFFSET_IN_FIXED_SCALELIGHT + _scalelightfixed)
mov   word ptr cs:[SELFMODIFY_MASKED_set_walllights+2 - OFFSET R_MASKED_STARTMARKER_], ax      ; store lights


;    maskedtexturecol = &openings[ds->maskedtexturecol_val];

SELFMODIFY_MASKED_dsp_1A:
mov   ax, 01000h		; ds->maskedtexturecol_val
add   ax, ax
mov   word ptr ds:[_maskedtexturecol], ax
;mov   word ptr ds:[_maskedtexturecol+2], OPENINGS_SEGMENT	; this is now hardcoded in data

;    rw_scalestep.w = ds->scalestep;

SELFMODIFY_MASKED_dsp_0E:
mov   bx, 01000h
SELFMODIFY_MASKED_dsp_10:
mov   cx, 01000h

mov   word ptr cs:[SELFMODIFY_MASKED_rw_scalestep_lo_1+1 - OFFSET R_MASKED_STARTMARKER_], bx		; rw_scalestep
mov   word ptr cs:[SELFMODIFY_MASKED_rw_scalestep_lo_2+5 - OFFSET R_MASKED_STARTMARKER_], bx		; rw_scalestep
mov   word ptr cs:[SELFMODIFY_MASKED_rw_scalestep_lo_3+5 - OFFSET R_MASKED_STARTMARKER_], bx		; rw_scalestep
mov   word ptr cs:[SELFMODIFY_MASKED_rw_scalestep_hi_1+1 - OFFSET R_MASKED_STARTMARKER_], cx		; rw_scalestep
mov   word ptr cs:[SELFMODIFY_MASKED_rw_scalestep_hi_2+5 - OFFSET R_MASKED_STARTMARKER_], cx		; rw_scalestep
mov   word ptr cs:[SELFMODIFY_MASKED_rw_scalestep_hi_3+5 - OFFSET R_MASKED_STARTMARKER_], cx		; rw_scalestep



SELFMODIFY_MASKED_x1_field_1:
mov   ax, 08000h
SELFMODIFY_MASKED_dsp_02:
sub   ax, 01000h

; inlined  FastMul16u32u_

;		spryscale.w = ds->scale1 + FastMul16u32u(x1 - ds->x1,rw_scalestep.w)


XCHG CX, AX    ; AX stored in CX
MUL  CX        ; AX * CX
XCHG CX, AX    ; store low product to be high result. Retrieve orig AX
MUL  BX        ; AX * BX
ADD  DX, CX    ; add 

SELFMODIFY_MASKED_dsp_06:
add   ax, 01000h
SELFMODIFY_MASKED_dsp_08:
adc   dx, 01000h
mov   word ptr ds:[_spryscale], ax
mov   word ptr ds:[_spryscale + 2], dx

;    mfloorclip_offset = ds->sprbottomclip_offset;
;    mceilingclip_offset = ds->sprtopclip_offset;

SELFMODIFY_MASKED_dsp_18:
mov   word ptr ds:[_mfloorclip], 01000h
SELFMODIFY_MASKED_dsp_16:
mov   word ptr ds:[_mceilingclip], 01000h





; here we used to set the fixedcolormap for the frame. 
; however we do this at frame start now via self modifying code

;if (fixedcolormap) {
;		// todo if this is 0 maybe skip the if?
;		dc_colormap_segment = colormaps_segment_maskedmapping;
;		dc_colormap_index = fixedcolormap;
;	}



SELFMODIFY_MASKED_fixedcolormap_2:
jne fixed_colormap		; jump when fixedcolormap is not 0.
SELFMODIFY_MASKED_fixedcolormap_2_AFTER:
colormap_set:

; set up main outer loop

;		int16_t dc_x_base4 = x1 & (detailshiftandval);	

SELFMODIFY_MASKED_x1_field_2:
mov   ax, 08000h
mov   di, ax						; di = x1
SELFMODIFY_MASKED_detailshiftandval_2:
and   ax, 01000h
mov   word ptr cs:[SELFMODIFY_MASKED_dc_x_base4+1 - OFFSET R_MASKED_STARTMARKER_], ax

;		int16_t base4diff = x1 - dc_x_base4;

sub   di, ax						; di = base4diff = x1 - dc_x_base4

;		fixed_t basespryscale = spryscale.w;

mov   ax, word ptr ds:[_spryscale]
mov   word ptr cs:[SELFMODIFY_MASKED_get_basespryscale_lo+1 - OFFSET R_MASKED_STARTMARKER_], ax
mov   ax, word ptr ds:[_spryscale + 2]
mov   word ptr cs:[SELFMODIFY_MASKED_get_basespryscale_hi+1 - OFFSET R_MASKED_STARTMARKER_], ax

;		fixed_t rw_scalestep_shift = rw_scalestep.w << detailshift2minus;

SELFMODIFY_MASKED_rw_scalestep_lo_1:
mov   ax, 01000h
SELFMODIFY_MASKED_rw_scalestep_hi_1:
mov   dx, 01000h




; todo: proper shift jmp thing
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


mov   word ptr cs:[SELFMODIFY_MASKED_rw_scalestep_shift_lo_1+2 - OFFSET R_MASKED_STARTMARKER_], ax		; rw_scalestep_shift
mov   word ptr cs:[SELFMODIFY_MASKED_rw_scalestep_shift_lo_2+4 - OFFSET R_MASKED_STARTMARKER_], ax		; rw_scalestep_shift
mov   word ptr cs:[SELFMODIFY_MASKED_rw_scalestep_shift_hi_1+2 - OFFSET R_MASKED_STARTMARKER_], dx		; rw_scalestep_shift
mov   word ptr cs:[SELFMODIFY_MASKED_rw_scalestep_shift_hi_2+4 - OFFSET R_MASKED_STARTMARKER_], dx		; rw_scalestep_shift

;		fixed_t sprtopscreen_step = FixedMul(dc_texturemid.w, rw_scalestep_shift);

SELFMODIFY_MASKED_dc_texturemid_lo_2:
mov   bx, 01000h
SELFMODIFY_MASKED_dc_texturemid_hi_2:
mov   cx, 01000h
;call  FixedMul_
db 0FFh  ; lcall[addr]
db 01Eh  ;
dw _FixedMul_addr

mov   word ptr cs:[SELFMODIFY_MASKED_sprtopscreen_lo+4 - OFFSET R_MASKED_STARTMARKER_], ax	  ; sprtopscreen_step
mov   word ptr cs:[SELFMODIFY_MASKED_sprtopscreen_hi+4 - OFFSET R_MASKED_STARTMARKER_], dx	  ; sprtopscreen_step


;	while (base4diff){
;		basespryscale -= rw_scalestep.w;
;		base4diff--;
;	}

test  di, di
je    base4diff_is_zero_rendermaskedsegrange

loop_dec_base4diff:
;			basespryscale -= rw_scalestep.w;

SELFMODIFY_MASKED_rw_scalestep_lo_2:
sub   word ptr cs:[SELFMODIFY_MASKED_get_basespryscale_lo+1 - OFFSET R_MASKED_STARTMARKER_], 01000h
SELFMODIFY_MASKED_rw_scalestep_hi_2:
sbb   word ptr cs:[SELFMODIFY_MASKED_get_basespryscale_hi+1 - OFFSET R_MASKED_STARTMARKER_], 01000h


dec   di
jne   loop_dec_base4diff
base4diff_is_zero_rendermaskedsegrange:


mov   di, 0		; x_offset. 




; if xoffset < detailshiftitercount exit loop


continue_outer_loop:

;			outp(SC_INDEX+1, quality_port_lookup[xoffset+detailshift.b.bytehigh]);

mov   dx, SC_DATA
; di contains xoffset..
SELFMODIFY_MASKED_detailshiftplus1_4:
mov   al, byte ptr [di + 20]
out   dx, al


;			spryscale.w = basespryscale;

SELFMODIFY_MASKED_get_basespryscale_lo:
mov   dx, 01000h
SELFMODIFY_MASKED_get_basespryscale_hi:
mov   bx, 01000h

; di holds xoffset.
; bx:dx temporarily holds _spryscale
; ax will temporarily store dc_x
;			dc_x        = dc_x_base4 + xoffset;
SELFMODIFY_MASKED_dc_x_base4:
mov   ax, 01000h
add   ax, di		; add xoffset to dc_x



;	if (dc_x < x1){
SELFMODIFY_MASKED_x1_field_3:
cmp   ax, 08000h   ; x1 
jge   calculate_sprtopscreen

; adjust by shiftstep

;	dc_x        += detailshiftitercount;
;	spryscale.w += rw_scalestep_shift;

SELFMODIFY_MASKED_detailshiftitercount_9:
add   ax, 0
SELFMODIFY_MASKED_rw_scalestep_shift_lo_1:
add   dx, 01000h
SELFMODIFY_MASKED_rw_scalestep_shift_hi_1:
adc   bx, 01000h

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
SELFMODIFY_MASKED_dc_texturemid_lo_3:
mov   bx, 01000h
SELFMODIFY_MASKED_dc_texturemid_hi_3:
mov   cx, 01000h

test  dx, dx
jnz    do_32_bit_mul

test ax, 08000h  ; high bit
do_16_bit_mul_after_all:
jnz  do_32_bit_mul_after_all

call FixedMul1632MaskedLocal_




done_with_mul:

neg   ax ; no need to subtract from zero...
mov   word ptr ds:[_sprtopscreen], ax
SELFMODIFY_MASKED_centery_2:
mov   ax, 01000h
sbb   ax, dx
mov   word ptr ds:[_sprtopscreen + 2], ax

mov   word ptr cs:[SELF_MODIFY_MASKED_xoffset+1 - OFFSET R_MASKED_STARTMARKER_], di

inner_loop_draw_columns:

mov   ax, word ptr ds:[_dc_x]
SELFMODIFY_MASKED_cmp_to_x2:
cmp   ax, 02000h
jle   do_inner_loop


;		for (xoffset = 0 ; xoffset < detailshiftitercount ; 
;			xoffset++, 
;			basespryscale+=rw_scalestep.w) {

; end of inner loop, fall back to end of outer loop step

SELF_MODIFY_MASKED_xoffset:
mov   di, 01000h
inc   di			; xoffset++
;			basespryscale+=rw_scalestep.w


SELFMODIFY_MASKED_rw_scalestep_lo_3:
add   word ptr cs:[SELFMODIFY_MASKED_get_basespryscale_lo+1 - OFFSET R_MASKED_STARTMARKER_], 01000h
SELFMODIFY_MASKED_rw_scalestep_hi_3:
adc   word ptr cs:[SELFMODIFY_MASKED_get_basespryscale_hi+1 - OFFSET R_MASKED_STARTMARKER_], 01000h


; xoffset < detailshiftitercount
SELFMODIFY_MASKED_detailshiftitercount_8:
cmp   di, 0
jle    continue_outer_loop		; 6 bytes out of range

exit_render_masked_segrange:
mov   ax, NULL_TEX_COL
mov   word ptr ds:[_maskednextlookup], ax
mov   word ptr ds:[_maskedcachedbasecol], ax
mov   word ptr ds:[_maskedtexrepeat], 0

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
SELFMODIFY_MASKED_fixedcolormap_1:
jne   got_colormap ; cmp [_fixedcolormap], 0 -> jne gotcolormap
SELFMODIFY_MASKED_fixedcolormap_1_AFTER:
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

SELFMODIFY_MASKED_detailshiftitercount_7:
add   word ptr ds:[_dc_x], 0

SELFMODIFY_MASKED_rw_scalestep_shift_lo_2:
add   word ptr ds:[_spryscale], 01000h
SELFMODIFY_MASKED_rw_scalestep_shift_hi_2:
adc   word ptr ds:[_spryscale + 2], 01000h

SELFMODIFY_MASKED_sprtopscreen_lo:
sub   word ptr ds:[_sprtopscreen], 01000h
SELFMODIFY_MASKED_sprtopscreen_hi:
sbb   word ptr ds:[_sprtopscreen + 2], 01000h
jmp   inner_loop_draw_columns

use_maxlight:
mov   al, MAXLIGHTSCALE - 1
get_colormap:
xor   ah, ah
mov   bx, ax
SELFMODIFY_MASKED_set_walllights:
mov   al, byte ptr ds:[bx + 01000h]
mov   byte ptr cs:[SELFMODIFY_MASKED_multi_set_colormap_index_jump - OFFSET R_MASKED_STARTMARKER_], al

SELFMODIFY_MASKED_fixedcolormap_1_TARGET:
got_colormap:

mov   bx, word ptr ds:[_spryscale]
mov   cx, word ptr ds:[_spryscale + 2]
;call  FastDiv3232_
db 0FFh  ; lcall[addr]
db 01Eh  ;
dw _FastDiv3232_addr

mov   dh, dl
mov   dl, ah
mov   word ptr cs:[SELFMODIFY_MASKED_set_dc_iscale_lo+1 - OFFSET R_MASKED_STARTMARKER_], ax
mov   word ptr cs:[SELFMODIFY_MASKED_set_dc_iscale_hi+1 - OFFSET R_MASKED_STARTMARKER_], dx


mov   bx, si  ; bx gets a copy of texture column?
;  ax stores _maskedtexrepeat for a little bit

mov   ax, word ptr ds:[_maskedtexrepeat] 
test  ax, ax
jz   do_non_repeat
; no more maskedtexmodulo, just use repeat
;mov   cx, word ptr ds:[_maskedtexmodulo] 
;jcxz  do_looped_column_calc

; width is power of 2, just AND
;	usetexturecolumn =  &= maskedtexmodulo;

and   bx, ax

repeat_column_calculated:

; bx is usetexturecolumn
;xor   bh, bh   ;todo necessary?
mov   ax, bx
; now al is usetexturecolumn

;	if (lookup != 0xFF){
SELFMODIFY_MASKED_lookup_2:
jmp    lookup_FF_repeat
SELFMODIFY_MASKED_lookup_2_AFTER:

;if (maskedheaderpixeolfs != 0xFFFF){

; cx gets MASKEDPIXELDATAOFS_SEGMENT
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
SELFMODIFY_MASKED_maskedpostofs_2:     ; todo this
mov   bx, word ptr es:[bx+08000h]
mov   cx, MASKEDPOSTDATA_SEGMENT
;call  dword ptr ds:[_R_DrawMaskedColumnCallHigh]

call R_DrawMaskedColumn_

jmp   update_maskedtexturecol_finish_loop_iter

COMMENT @
; unused in vanilla, and untested.
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
@

SELFMODIFY_MASKED_lookup_2_TARGET:
lookup_FF_repeat:

;	if (texturecolumn >= maskednextlookup ||
; 		texturecolumn < maskedprevlookup

mul   byte ptr ds:[_maskedheightvalcache]
add   ax, word ptr ds:[_maskedcachedsegment]

mov   dx, word ptr ds:[_cachedbyteheight]  ; todo optimize this to a full word with 0 high byte in data. then optimize in _R_DrawSingleMaskedColumn_ as well

call R_DrawSingleMaskedColumn_

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
SELFMODIFY_MASKED_lookup_1:  
jmp   lookup_FF
SELFMODIFY_MASKED_lookup_1_AFTER:

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
SELFMODIFY_MASKED_maskedpostofs_1:
mov   bx, word ptr es:[bx+08000h]
mov   cx, MASKEDPOSTDATA_SEGMENT

call R_DrawMaskedColumn_

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
SELFMODIFY_MASKED_texnum_1:
mov   ax, 08000h
;call  R_GetMaskedColumnSegment_  
db 0FFh  ; lcall[addr]
db 01Eh  ;
dw _R_GetMaskedColumnSegment_addr


mov   di, word ptr ds:[_maskedcachedbasecol]
mov   dx, word ptr ds:[_maskedcachedsegment]   ; to offset for above
sub   ax, dx

jmp   go_draw_masked_column


SELFMODIFY_MASKED_lookup_1_TARGET:
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

call R_DrawSingleMaskedColumn_
jmp   update_maskedtexturecol_finish_loop_iter

load_masked_column_segment:
mov   dx, si
SELFMODIFY_MASKED_texnum_2:
mov   ax, 08000h
;call  R_GetMaskedColumnSegment_
db 0FFh  ; lcall[addr]
db 01Eh  ;
dw _R_GetMaskedColumnSegment_addr

mov   di, word ptr ds:[_maskedcachedbasecol]
mov   dx, word ptr ds:[_cachedbyteheight]  ; todo optimize this to a full word with 0 high byte in data. then optimize in _R_DrawSingleMaskedColumn_ as well

; call  dword ptr ds:[_R_DrawSingleMaskedColumnCallHigh]  ; todo... do i really want this
call R_DrawSingleMaskedColumn_  ;todo inline here, jump from above case? both jump to same spot after.


jmp   update_maskedtexturecol_finish_loop_iter

endp



PROC FixedMul1632MaskedLocal_ NEAR
PUBLIC FixedMul1632MaskedLocal_

; AX  *  CX:BX
;  0  1   2  3

; AX * CX:BX

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

CWD				; DX/S0

mov   es, ax    ; store ax in es
AND   DX, BX	; S0*BX
NEG   DX
mov   SI, DX	; DI stores hi word return

CWD 

AND  DX, CX    ; DX*CX
NEG  DX
add  SI, DX    ; low word result into high word return

CWD

; NEED TO ALSO EXTEND SIGN MULTIPLY TO HIGH WORD. if sign is FFFF then result is BX - 1. Otherwise 0.
; UNLESS BX is 0. then its also 0!

; the algorithm for high sign bit mult:   IF FFFF result is (BX - 1). If 0000 then 0.
MOV  AX, BX    ; create BX copy
SUB  AX, 1     ; DEC DOES NOT AFFECT CARRY FLAG! BOO! 3 byte instruction, can we improve?
ADC  AX, 0     ; if bx is 0 then restore to 0 after the dex  

AND  AX, DX    ; 0 or BX - 1
ADD  SI, AX    ; add DX * BX high word. 


AND  DX, BX    ; DX * BX low bits
NEG  DX
XCHG BX, DX    ; BX will hold low word return. store BX in DX for last mul 

mov  AX, ES    ; grab AX from ES
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
 

pop   si
ret

ENDP


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

SHIFT_MACRO shl si 3

;mov   ax, SEGS_RENDER_SEGMENT
;mov   es, ax  ; ES for segs_render lookup

mov   di, word ptr ds:[_segs_render + si]
SHIFT_MACRO shl di 2

mov   ax, VERTEXES_SEGMENT
mov   es, ax  ; DS for vertexes lookup


mov   bx, word ptr es:[di]      ; lx
mov   ax, word ptr es:[di + 2]  ; ly


mov   di, word ptr ds:[_segs_render + si + 2]

;mov   es, ax  ; juggle ax around isntead of putting on stack...

SHIFT_MACRO shl di 2

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
call FixedMul1632MaskedLocal_



; set up params..
pop   bx
mov   cx, di
push  ax
mov   ax, si
mov   di, dx

call FixedMul1632MaskedLocal_


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

; note: faster when this is put in the register rather than added in the loop.
SELFMODIFY_MASKED_viewheight_2:
mov   ax, 01000h

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
mov   si, dx    ; vissprite pointer from above
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
les   ax, dword ptr [bx + 6]
mov   dx, es
les   bx, dword ptr [bx + 0Ah]
mov   cx, es

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
mov   byte ptr cs:[SELFMODIFY_MASKED_set_al_to_silhouette+1 - OFFSET R_MASKED_STARTMARKER_],  al

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
and   byte ptr cs:[SELFMODIFY_MASKED_set_al_to_silhouette+1 - OFFSET R_MASKED_STARTMARKER_], 0FEh  
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


SELFMODIFY_MASKED_set_al_to_silhouette:
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

les   dx, dword ptr es:[di + 016h]
mov   bx, es

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

VISSPRITE_SORTED_HEAD_INDEX = 0FEh

PROC R_DrawMasked_ FAR
PUBLIC R_DrawMasked_

push bx
push cx
push dx
push si
push di

call R_SortVisSprites_


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
exit_draw_masked:
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
	
PROC  R_DrawMaskedColumn_ NEAR
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

; dc_texturemid already set pre call.
xor   di, di        ; di used as currentoffset.

cmp   byte ptr es:[si], 0FFh
jne   draw_next_column_patch
jmp   exit_function
draw_next_column_patch:

;        topscreen.w = sprtopscreen + FastMul16u32u(column->topdelta, spryscale.w);
;es in use
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
 

; todo can this be 8 bit mul without the xor ch or not
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

SHIFT_MACRO shr bx 4


SELFMODIFY_MASKED_dc_texturemid_hi_1:
mov   dx, 01000h;  dc_texturemid intbits
les   ax, dword ptr [bp - 4]
add   ax, bx
mov   word ptr ds:[_dc_source_segment], ax
mov   al, byte ptr es:[si]
xor   ah, ah
; dx = dc_texturemid hi. carry this into the call
sub   dx, ax
; cx = dc_texturemid lo. carry this into the call

SELFMODIFY_MASKED_dc_texturemid_lo_1:
mov   ax, 01000h

call  R_DrawColumnPrepMaskedMulti_

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


mov   cx, es               ; restore cx
LEAVE_MACRO
pop   di
pop   si
pop   dx
ret


ENDP



VISSPRITE_UNSORTED_INDEX    = 0FFh
VISSPRITE_SORTED_HEAD_INDEX = 0FEh


PROC R_SortVisSprites_ NEAR
PUBLIC R_SortVisSprites_

; bp - 2     vsprsortedheadfirst ?
; bp - 4     best ?
; bp - 8     UNUSED i (loop counter). todo selfmodify out.
; bp - 0ah   UNUSED vissprite_p pointer/count todo selfmodify out
; bp -034h   unsorted?


mov       ax, word ptr ds:[_vissprite_p]
test      ax, ax
jne       count_not_zero
ret


count_not_zero:
push      bx
push      cx
push      dx
push      si
push      di
push      bp
mov       bp, sp
sub       sp, 034h				; let's set things up finally isnce we're not quick-exiting out

mov       byte ptr cs:[SELFMODIFY_MASKED_loop_compare_instruction+1 - OFFSET R_MASKED_STARTMARKER_], al ; store count
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
mov       byte ptr cs:[SELFMODIFY_MASKED_set_al_to_loop_counter+1 - OFFSET R_MASKED_STARTMARKER_], 0  ; zero loop counter

mov       al, VISSPRITE_SORTED_HEAD_INDEX

mov       byte ptr [bp - 2], al
mov       byte ptr ds:[_vsprsortedheadfirst], al
mov       byte ptr [bx], VISSPRITE_UNSORTED_INDEX
cmp       dx, 0  ; is this redundant?
jle       exit_sort_vissprites

loop_visplane_sort:

inc       byte ptr cs:[SELFMODIFY_MASKED_set_al_to_loop_counter+1 - OFFSET R_MASKED_STARTMARKER_] ; update loop counter

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
les       cx, dword ptr [bx + si + 1Ah]
mov       di, es
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
ret       

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
SELFMODIFY_MASKED_set_al_to_loop_counter:
mov       al, 0FFh ; get loop counter
SELFMODIFY_MASKED_loop_compare_instruction:
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











;
; The following functions are loaded into a different segment at runtime.
; However, at compile time they have access to the labels in this file.
;


;R_WriteBackViewConstantsMasked

PROC R_WriteBackViewConstantsMasked_ FAR
PUBLIC R_WriteBackViewConstantsMasked_ 



mov      ax, DRAWFUZZCOL_AREA_SEGMENT
mov      ds, ax


ASSUME DS:R_MASKED_TEXT

mov      ax,  word ptr ss:[_detailshift]

; todo modify these as loops
;mov   al, byte ptr ss:[_detailshift2minus]
;mov   al, byte ptr ss:[_detailshift]


; for 16 bit shifts, modify jump to jump 4 for 0 shifts, 2 for 1 shifts, 0 for 0 shifts.

cmp      al, 1
jb       set_to_zero_masked
je       set_to_one_masked

; detailshift 2 case. usually involves no shift. in this case - we just jump past the shift code.

; nop 
mov      ax, 0c089h 

; write to colfunc segment
mov      word ptr ds:[SELFMODIFY_MASKED_detailshift_2_minus_16_bit_shift- OFFSET R_MASKED_STARTMARKER_+0], ax
mov      word ptr ds:[SELFMODIFY_MASKED_detailshift_2_minus_16_bit_shift- OFFSET R_MASKED_STARTMARKER_+2], ax
mov      word ptr ds:[SELFMODIFY_MASKED_multi_detailshift_2_minus_16_bit_shift- OFFSET R_MASKED_STARTMARKER_+0], ax
mov      word ptr ds:[SELFMODIFY_MASKED_multi_detailshift_2_minus_16_bit_shift- OFFSET R_MASKED_STARTMARKER_+2], ax




; for 32 bit shifts, modify jump to jump 8 for 0 shifts, 4 for 1 shifts, 0 for 0 shifts.
; 0EBh, 006h = jmp 6



jmp      done_modding_shift_detail_code_masked
set_to_one_masked:

; detailshift 1 case. usually involves one shift pair.
; in this case - we insert nops (nopish?) code to replace the first shift pair

; for 32 bit shifts, modify jump to jump 8 for 0 shifts, 4 for 1 shifts, 0 for 0 shifts.

; d1 f8  = sar ax, 1
mov      ax, 0f8d1h 

; write to colfunc segment
mov      word ptr ds:[SELFMODIFY_MASKED_detailshift_2_minus_16_bit_shift- OFFSET R_MASKED_STARTMARKER_+0], ax
mov      word ptr ds:[SELFMODIFY_MASKED_multi_detailshift_2_minus_16_bit_shift- OFFSET R_MASKED_STARTMARKER_+0], ax

; nop 
mov      ax, 0c089h 
mov      word ptr ds:[SELFMODIFY_MASKED_detailshift_2_minus_16_bit_shift- OFFSET R_MASKED_STARTMARKER_+2], ax
mov      word ptr ds:[SELFMODIFY_MASKED_multi_detailshift_2_minus_16_bit_shift- OFFSET R_MASKED_STARTMARKER_+2], ax



; 81 c3 00 00 = add bx, 0000. Not technically a nop, but probably better than two mov ax, ax?
; 89 c0       = mov ax, ax. two byte nop.

jmp      done_modding_shift_detail_code_masked
set_to_zero_masked:

; detailshift 0 case. usually involves two shift pairs.
; in this case - we make that first shift a proper shift

; d1 f8  = sar ax, 1
mov      ax, 0f8d1h 

; write to colfunc segment
mov      word ptr ds:[SELFMODIFY_MASKED_detailshift_2_minus_16_bit_shift- OFFSET R_MASKED_STARTMARKER_+0], ax
mov      word ptr ds:[SELFMODIFY_MASKED_detailshift_2_minus_16_bit_shift- OFFSET R_MASKED_STARTMARKER_+2], ax
mov      word ptr ds:[SELFMODIFY_MASKED_multi_detailshift_2_minus_16_bit_shift- OFFSET R_MASKED_STARTMARKER_+0], ax
mov      word ptr ds:[SELFMODIFY_MASKED_multi_detailshift_2_minus_16_bit_shift- OFFSET R_MASKED_STARTMARKER_+2], ax


; fall thru
done_modding_shift_detail_code_masked:


; note: examples 3/6/9 overwrite "add ax, 0" which compiles to the opcode where
; you get 16 bit immediate starting at base + 1 instead of a 8 bit immediate starting at base + 2.
mov   al, byte ptr ss:[_detailshiftitercount]
mov   byte ptr ds:[SELFMODIFY_MASKED_detailshiftitercount_1+2 - OFFSET R_MASKED_STARTMARKER_], al
mov   byte ptr ds:[SELFMODIFY_MASKED_detailshiftitercount_2+4 - OFFSET R_MASKED_STARTMARKER_], al
mov   byte ptr ds:[SELFMODIFY_MASKED_detailshiftitercount_3+1 - OFFSET R_MASKED_STARTMARKER_], al
mov   byte ptr ds:[SELFMODIFY_MASKED_detailshiftitercount_4+2 - OFFSET R_MASKED_STARTMARKER_], al
mov   byte ptr ds:[SELFMODIFY_MASKED_detailshiftitercount_5+4 - OFFSET R_MASKED_STARTMARKER_], al
mov   byte ptr ds:[SELFMODIFY_MASKED_detailshiftitercount_6+1 - OFFSET R_MASKED_STARTMARKER_], al
mov   byte ptr ds:[SELFMODIFY_MASKED_detailshiftitercount_7+4 - OFFSET R_MASKED_STARTMARKER_], al
mov   byte ptr ds:[SELFMODIFY_MASKED_detailshiftitercount_8+2 - OFFSET R_MASKED_STARTMARKER_], al
mov   byte ptr ds:[SELFMODIFY_MASKED_detailshiftitercount_9+1 - OFFSET R_MASKED_STARTMARKER_], al


mov   ax, word ptr ss:[_detailshiftandval]
mov   word ptr ds:[SELFMODIFY_MASKED_detailshiftandval_1+1 - OFFSET R_MASKED_STARTMARKER_], ax
mov   word ptr ds:[SELFMODIFY_MASKED_detailshiftandval_2+1 - OFFSET R_MASKED_STARTMARKER_], ax


mov   al, byte ptr ss:[_detailshift+1]
mov   byte ptr ds:[SELFMODIFY_MASKED_detailshiftplus1_1+1 - OFFSET R_MASKED_STARTMARKER_], al
add   al, _quality_port_lookup
mov   byte ptr ds:[SELFMODIFY_MASKED_detailshiftplus1_2+2 - OFFSET R_MASKED_STARTMARKER_], al
mov   byte ptr ds:[SELFMODIFY_MASKED_detailshiftplus1_3+2 - OFFSET R_MASKED_STARTMARKER_], al
mov   byte ptr ds:[SELFMODIFY_MASKED_detailshiftplus1_4+2 - OFFSET R_MASKED_STARTMARKER_], al

mov   ax, word ptr ss:[_viewheight]
mov   word ptr ds:[SELFMODIFY_MASKED_viewheight_1+1 - OFFSET R_MASKED_STARTMARKER_], ax
mov   word ptr ds:[SELFMODIFY_MASKED_viewheight_2+1 - OFFSET R_MASKED_STARTMARKER_], ax



mov      ax, ss
mov      ds, ax

ASSUME DS:DGROUP

retf

endp

;R_WriteBackMaskedFrameConstants

PROC R_WriteBackMaskedFrameConstants_ FAR
PUBLIC R_WriteBackMaskedFrameConstants_ 

; todo: merge this with some other code. maybe R_DrawMasked and use CS

mov      ax, DRAWFUZZCOL_AREA_SEGMENT
mov      ds, ax


ASSUME DS:R_MASKED_TEXT

; get whole dword at the end here.

mov   ax, word ptr ss:[_centery]
mov   word ptr ds:[SELFMODIFY_MASKED_centery_1+3 - OFFSET R_MASKED_STARTMARKER_], ax
mov   word ptr ds:[SELFMODIFY_MASKED_centery_2+1 - OFFSET R_MASKED_STARTMARKER_], ax

mov   ax, word ptr ss:[_viewz+0]
mov   word ptr ds:[SELFMODIFY_MASKED_viewz_lo_1+2 - OFFSET R_MASKED_STARTMARKER_], ax
mov   ax, word ptr ss:[_viewz+2]
mov   word ptr ds:[SELFMODIFY_MASKED_viewz_hi_1+1 - OFFSET R_MASKED_STARTMARKER_], ax

mov   ax, word ptr ss:[_destview+0]
mov   word ptr ds:[SELFMODIFY_MASKED_destview_lo_1+2 - OFFSET R_MASKED_STARTMARKER_], ax
mov   word ptr ds:[SELFMODIFY_MASKED_destview_lo_2+1 - OFFSET R_MASKED_STARTMARKER_], ax
mov   word ptr ds:[SELFMODIFY_MASKED_destview_lo_3+1 - OFFSET R_MASKED_STARTMARKER_], ax

mov   ax, word ptr ss:[_destview+2]
mov   word ptr ds:[SELFMODIFY_MASKED_destview_hi_1+1 - OFFSET R_MASKED_STARTMARKER_], ax

mov   al, byte ptr ss:[_extralight]
mov   byte ptr ds:[SELFMODIFY_MASKED_extralight_1+1 - OFFSET R_MASKED_STARTMARKER_], al

mov   al, byte ptr ss:[_fixedcolormap]
cmp   al, 0
jne   do_fixedcolormap_selfmodify
do_no_fixedcolormap_selfmodify:

; replace with nop.
; nop 
mov      ax, 0c089h 
mov      word ptr ds:[SELFMODIFY_MASKED_fixedcolormap_1 - OFFSET R_MASKED_STARTMARKER_], ax
mov      word ptr ds:[SELFMODIFY_MASKED_fixedcolormap_2 - OFFSET R_MASKED_STARTMARKER_], ax



jmp done_with_fixedcolormap_selfmodify

do_fixedcolormap_selfmodify:
mov   byte ptr ds:[SELFMODIFY_MASKED_fixedcolormap_3+5 - OFFSET R_MASKED_STARTMARKER_], al

; modify jmp in place.
mov   ax, ((SELFMODIFY_MASKED_fixedcolormap_1_TARGET - SELFMODIFY_MASKED_fixedcolormap_1_AFTER) SHL 8) + 0EBh
mov   word ptr ds:[SELFMODIFY_MASKED_fixedcolormap_1 - OFFSET R_MASKED_STARTMARKER_], ax
mov   ah, (SELFMODIFY_MASKED_fixedcolormap_2_TARGET - SELFMODIFY_MASKED_fixedcolormap_2_AFTER)
mov   word ptr ds:[SELFMODIFY_MASKED_fixedcolormap_2 - OFFSET R_MASKED_STARTMARKER_], ax



; fall thru
done_with_fixedcolormap_selfmodify:

mov      ax, ss
mov      ds, ax

ASSUME DS:DGROUP




retf



ENDP

; end marker for this asm file
PROC R_MASKED_END_ FAR
PUBLIC R_MASKED_END_ 
ENDP

END
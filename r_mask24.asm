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
INSTRUCTION_SET_MACRO_NO_MEDIUM

; todo move these all out once BSP code moved out of binary




SEGMENT R_MASK24_TEXT USE16 PARA PUBLIC 'CODE'
ASSUME  CS:R_MASK24_TEXT



; for the 6th colormap (used in fuzz draws. offset by 600h bytes, or 60h segments)

COLORMAPS_6_MASKEDMAPPING_SEG_DIFF_SEGMENT = (COLORMAPS_SEGMENT_MASKEDMAPPING + 060h)
 
; 5472 or 0x1560
COLORMAPS_MASKEDMAPPING_SEG_OFFSET_IN_CS = 16 * (COLORMAPS_6_MASKEDMAPPING_SEG_DIFF_SEGMENT - DRAWFUZZCOL_AREA_SEGMENT)




;=================================




PROC   R_MASK24_STARTMARKER_
PUBLIC R_MASK24_STARTMARKER_

ENDP





_pagesegments:
PUBLIC _pagesegments

dw 00000h, 00400h, 00800h, 00C00h
dw 01000h, 01400h, 01800h, 01C00h







_fuzzpos:

dw  (OFFSET _fuzzoffset) - (OFFSET R_MASK24_STARTMARKER_)



SIZE_FUZZTABLE = 50

; extended length of a max run...
_fuzzoffset:
PUBLIC _fuzzoffset
dw  00050h, 0FFB0h, 00050h, 0FFB0h, 00050h, 00050h, 0FFB0h, 00050h, 00050h, 0FFB0h 
dw  00050h, 00050h, 00050h, 0FFB0h, 00050h, 00050h, 00050h, 0FFB0h, 0FFB0h, 0FFB0h
dw  0FFB0h, 00050h, 0FFB0h, 0FFB0h, 00050h, 00050h, 00050h, 00050h, 0FFB0h, 00050h
dw  0FFB0h, 00050h, 00050h, 0FFB0h, 0FFB0h, 00050h, 00050h, 0FFB0h, 0FFB0h, 0FFB0h
dw  0FFB0h, 00050h, 00050h, 00050h, 00050h, 0FFB0h, 00050h, 00050h, 0FFB0h, 00050h
dw  00050h, 0FFB0h, 00050h, 0FFB0h, 00050h, 00050h, 0FFB0h, 00050h, 00050h, 0FFB0h
dw  00050h, 00050h, 00050h, 0FFB0h, 00050h


IF COMPISA GE COMPILE_386

PROC FixedMulMaskedLocal_ NEAR
; thanks zero318 from discord for improved algorithm  

; DX:AX  *  CX:BX
;  0  1      2  3

  shl  ecx, 16
  mov  cx, bx
  xchg ax, dx
  shl  eax, 16
  xchg ax, dx
  imul  ecx
  shr  eax, 16
  ret



ENDP
ELSE


PROC FixedMulMaskedLocal_ NEAR
PUBLIC FixedMulMaskedLocal_
; DX:AX  *  CX:BX
;  0  1      2  3

; thanks zero318 from discord for improved algorithm  

MOV  ES, SI
MOV  SI, DX
PUSH AX
MUL  BX
MOV  word ptr cs:[_selfmodify_restore_dx+1], DX
MOV  AX, SI
MUL  CX
XCHG AX, SI
CWD
AND  DX, BX
SUB  SI, DX
MUL  BX
_selfmodify_restore_dx:
ADD  AX, 01000h
ADC  SI, DX
XCHG AX, CX
CWD
POP  BX
AND  DX, BX
SUB  SI, DX
MUL  BX
ADD  AX, CX
ADC  DX, SI
MOV  SI, ES
RET

ENDP
ENDIF


;
; R_DrawFuzzColumn
;


	
PROC  R_DrawFuzzColumn_  NEAR
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
mov  si, word ptr cs:[_fuzzpos - OFFSET R_MASK24_STARTMARKER_]	; note this is always the byte offset - no shift conversion necessary

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



cmp  si, ((OFFSET _fuzzoffset) - (OFFSET R_MASK24_STARTMARKER_)) +  (SIZE_FUZZTABLE * 2) ; word size
jl   fuzzpos_ok
; subtract 50 from fuzzpos
sub  si, SIZE_FUZZTABLE * 2 ; word size
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

cmp  si, ((OFFSET _fuzzoffset) - (OFFSET R_MASK24_STARTMARKER_)) +  (SIZE_FUZZTABLE * 2) ; word size
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

mov  word ptr word ptr cs:[_fuzzpos - OFFSET R_MASK24_STARTMARKER_], si

pop  es
pop  di
pop  si
ret 

zero_out_fuzzpos:
mov   si, (OFFSET _fuzzoffset) - (OFFSET R_MASK24_STARTMARKER_)
loop  draw_one_fuzzpixel
jmp finished_drawing_fuzzpixels

ENDP




COLFUNC_JUMP_AND_FUNCTION_AREA_OFFSET_DIFF = ((COLFUNC_FUNCTION_AREA_SEGMENT - COLFUNC_FILE_START_SEGMENT) * 16)


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
PROC    R_DrawColumnPrepMaskedMulti_ NEAR
PUBLIC  R_DrawColumnPrepMaskedMulti_

; argument AX is diff for various segment lookups

; todo some of these such as dx and cx for sure can be modified

push  si
push  di
push  bp

; dl:?? currently has dc_texturemid
mov   si, word ptr ds:[_dc_yl]
mov   di, word ptr ds:[_dc_yh]                  ; grab dc_yh
mov   ax, word ptr ds:[_dc_x]

mov   bx, (COLFUNC_FILE_START_SEGMENT - COLORMAPS_MASKEDMAPPING_SEG_DIFF)
mov   ds, bx                                 ; store this segment for now, with offset pre-added


; shift ax by (2 - detailshift.)
SELFMODIFY_MASKED_multi_detailshift_2_minus_16_bit_shift:
sar   ax, 1
sar   ax, 1


sub   di, si                                 ;
sal   di, 1                                  ; double diff (dc_yh - dc_yl) to get a word offset
mov   di, word ptr ds:[di+DRAWCOL_NOLOOP_JUMP_TABLE_OFFSET]   ; get the jump value. both tables in masked are 10 byte jump tables

mov   bp, si
add   ax, word ptr ds:[si+bp]                   ; add * 80 lookup table value 

SELFMODIFY_MASKED_destview_lo_3:
add   ax, 01000h

xchg  ax, di


SELFMODIFY_masked_set_jump_write_offset:
mov   word ptr ds:[01000h], ax  ; overwrite the jump relative call for however many iterations in unrolled loop we need


; what follows is compution of desired CS segment and offset to function to allow for colormaps to be CS:BX and match DS:BX column
; or can we do this in an outer func without this instrction?


; if we make a separate drawcol masked we can use a constant here.

xchg  ax, si    ; dc_yl in ax



; dynamic call lookuptable based on used colormaps address being CS:00


; CH:BX = dc_iscale
SELFMODIFY_MASKED_set_dc_iscale_lo:
mov   bx, 01000h ; dc_iscale +0
SELFMODIFY_MASKED_set_dc_iscale_hi:
mov   ch, 010h ; dc_iscale +1
SELFMODIFY_MASKED_dc_texturemid_lo_1:
mov   si, 01000h        ; todo can this just go to si in the call?

SELFMODIFY_MASKED_set_xlat_offset:
mov   bp, 01000h          ; dc_iscale +2

; pass in xlat offset for bx via bp

db 09Ah
SELFMODIFY_MASKED_COLFUNC_set_func_offset:
dw DRAWCOL_NOLOOP_OFFSET_MASKED, COLORMAPS_SEGMENT_MASKEDMAPPING



pop   bp
pop   di 
pop   si
ret

ENDP



;
; R_DrawSingleMaskedColumn
;
	
PROC  R_DrawSingleMaskedColumn_ NEAR 
PUBLIC R_DrawSingleMaskedColumn_
push  cx
push  si
push  di
push  bp


; note: this function is called so rarely i don't care if its a little more innefficient.
; it is called for reverse visible walls like in e1m1's slime REALDOOM



mov   word ptr ds:[_dc_source_segment], ax	; set this early. 

; slow and ugly - infer it another way later if possible.
; todo can this go up a layer
mov   ax, word ptr cs:[SELFMODIFY_MASKED_COLFUNC_set_func_offset]
mov   word ptr cs:[SELFMODIFY_MASKED_COLFUNC_set_func_offset_dupe], ax
mov   ax, word ptr cs:[SELFMODIFY_masked_set_jump_write_offset+1]
mov   word ptr cs:[SELFMODIFY_masked_set_jump_write_offset_dupe+1], ax



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

; consider getting rid of this... 




mov   ax, (COLFUNC_FILE_START_SEGMENT - COLORMAPS_MASKEDMAPPING_SEG_DIFF); shut up assembler warning, this is fine
mov   ds, ax                                 ; store this segment for now, with offset pre-added

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

mov   bp, si  ; word lookup
add   ax, word ptr ds:[bp+si]                  ; add dc_yl * 80
SELFMODIFY_MASKED_destview_lo_2:               ; add destview
add   ax, 01000h

mov   di, dx                                 ; grab dc_yh
sub   di, bp                                 ;

sal   di, 1                                 ; double diff (dc_yh - dc_yl) to get a word offset

mov   di, word ptr ds:[di + DRAWCOL_NOLOOP_JUMP_TABLE_OFFSET]                   ; get the jump value
xchg  ax, di
SELFMODIFY_masked_set_jump_write_offset_dupe:
mov   word ptr ds:[01000h], ax  ; overwrite the jump relative call for however many iterations in unrolled loop we need

xchg  ax, si    ; dc_yl in ax

; CL:SI = dc_texturemid
; CH:BX = dc_iscale

; gross lol. but again - rare function. in exchange the common function is faster.
mov   cl, byte ptr cs:[SELFMODIFY_MASKED_dc_texturemid_hi_1+1 - OFFSET R_MASK24_STARTMARKER_]
mov   bx, word ptr cs:[SELFMODIFY_MASKED_set_dc_iscale_lo+1 - OFFSET R_MASK24_STARTMARKER_]
mov   ch, byte ptr cs:[SELFMODIFY_MASKED_set_dc_iscale_hi+1 - OFFSET R_MASK24_STARTMARKER_]
mov   si, word ptr cs:[SELFMODIFY_MASKED_dc_texturemid_lo_1+1 - OFFSET R_MASK24_STARTMARKER_]
mov   bp, word ptr cs:[SELFMODIFY_MASKED_set_xlat_offset+1 - OFFSET R_MASK24_STARTMARKER_]

; pass in xlat offset for bx via bp

db 09Ah
SELFMODIFY_MASKED_COLFUNC_set_func_offset_dupe:
dw DRAWCOL_NOLOOP_OFFSET_MASKED, COLORMAPS_SEGMENT_MASKEDMAPPING




exit_function_single:


pop   bp
pop   di
pop   si
pop   cx
ret   

ENDP

UNCLIPPED_COLUMN  = 0FFFEh



; note remove masked start from here 

jump_to_exit_draw_shadow_sprite:
jmp   exit_draw_shadow_sprite

PROC R_DrawMaskedSpriteShadow_ NEAR

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
mov   byte ptr cs:[SELFMODIFY_MASKED_set_bx_to_lookup+1 - OFFSET R_MASK24_STARTMARKER_], al
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


do_32_bit_mul_vissprite:
inc   dx
jz    do_16_bit_mul_after_all_vissprite
dec   dx
do_32_bit_mul_after_all_vissprite:

call FixedMulMaskedLocal_


jmp done_with_mul_vissprite


PROC  R_DrawVisSprite_ NEAR
PUBLIC R_DrawVisSprite_
; si is vissprite_t near pointer

; bp - 2  	 frac.h.fracbits
; bp - 4  	 frac.h.intbits
; bp - 6     xiscalestep_shift low word
; bp - 8     xiscalestep_shift high word




mov   al, byte ptr ds:[si + VISSPRITE_T.vs_colormap]

; al is colormap. 

mov   byte ptr cs:[SELFMODIFY_MASKED_set_xlat_offset+2 - OFFSET R_MASK24_STARTMARKER_], al

; todo move this out to a higher level! possibly when executesetviewsize happens.




les   ax, dword ptr ds:[si + VISSPRITE_T.vs_xiscale]   ; vis->xiscale
mov   dx, es
xor   cx, cx  ; cx is 0
; labs
or    dx, dx
jge   xiscale_already_positive
neg   ax
adc   dx, cx   ; 0
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


mov   word ptr cs:[SELFMODIFY_MASKED_set_dc_iscale_lo+1 - OFFSET R_MASK24_STARTMARKER_], ax
mov   byte ptr cs:[SELFMODIFY_MASKED_set_dc_iscale_hi+1 - OFFSET R_MASK24_STARTMARKER_], dl
test  dl, dl

mov   ax, SELFMODIFY_COLFUNC_JUMP_OFFSET24_NOLOOP_OFFSET+1
mov   dx, DRAWCOL_NOLOOP_OFFSET_MASKED
jne   not_stretch_draw

mov   ax, SELFMODIFY_COLFUNC_JUMP_OFFSET24_NOLOOPANDSTRETCH_OFFSET+1
mov   dx, DRAWCOL_NOLOOPSTRETCH_OFFSET_MASKED

not_stretch_draw:

mov   word ptr cs:[SELFMODIFY_MASKED_COLFUNC_set_func_offset], dx
mov   word ptr cs:[SELFMODIFY_masked_set_jump_write_offset+1 - OFFSET R_MASK24_STARTMARKER_], ax





mov   di, OFFSET _sprtopscreen
mov   word ptr ds:[di], cx   ; cx is 0
SELFMODIFY_MASKED_centery_1:
mov   word ptr ds:[di + 2], 01000h

les   ax, dword ptr [si + VISSPRITE_T.vs_scale]  ; vis->scale
mov   dx, es

mov   word ptr ds:[_spryscale], ax
mov   word ptr ds:[_spryscale + 2], dx

les   bx, dword ptr [si + VISSPRITE_T.vs_texturemid] ; vis->texturemid
mov   cx, es
; write this ahead
mov   word ptr cs:[SELFMODIFY_MASKED_dc_texturemid_lo_1 + 1 - OFFSET R_MASK24_STARTMARKER_], bx
mov   byte ptr cs:[SELFMODIFY_MASKED_dc_texturemid_hi_1 + 1 - OFFSET R_MASK24_STARTMARKER_], cl


test  dx, dx
jnz   do_32_bit_mul_vissprite

test ax, ax  ; high bit     ; apparently this one needs to be tested for??
js   do_32_bit_mul_after_all_vissprite  ; why?
do_16_bit_mul_after_all_vissprite:

;call FixedMul1632MaskedLocal_
  MOV ES, CX
  MOV CX, AX
  MUL BX
  XCHG AX, DX
  XCHG AX, CX
  CWD
  AND BX, DX
  MOV DX, ES
  IMUL DX
  SUB CX, BX
  SBB BX, BX
  ADD AX, CX
  ADC DX, BX


done_with_mul_vissprite:
push  bp
mov   bp, sp


; di is _sprtopscreen
sub   word ptr ds:[di], ax
sbb   word ptr ds:[di + 2], dx

mov   ax, word ptr ds:[si + VISSPRITE_T.vs_patch]
cmp   ax, word ptr ds:[_lastvisspritepatch]
jne   sprite_not_first_cachedsegment
mov   es, word ptr ds:[_lastvisspritesegment]
spritesegment_ready:


mov   di, word ptr ds:[si + VISSPRITE_T.vs_startfrac + 0]  ; frac = vis->startfrac
mov   ax, word ptr ds:[si + VISSPRITE_T.vs_startfrac + 2]
push  ax;  [bp - 2]
push  di;  [bp - 4]

mov   ax, word ptr ds:[si + VISSPRITE_T.vs_x1]
mov   dx, ax
SELFMODIFY_MASKED_detailshiftandval_1:
and   ax, 01000h

mov   word ptr cs:[SELFMODIFY_MASKED_set_ax_to_dc_x_base4+1 - OFFSET R_MASK24_STARTMARKER_], ax
mov   word ptr cs:[SELFMODIFY_MASKED_set_ax_to_dc_x_base4_shadow+1 - OFFSET R_MASK24_STARTMARKER_], ax

sub   dx, ax
xchg  ax, dx



; xiscalestep_shift = vis->xiscale << detailshift2minus;
; es in use
mov   bx, word ptr ds:[si + VISSPRITE_T.vs_xiscale + 0] ; DX:BX = vis->xiscale
mov   dx, word ptr ds:[si + VISSPRITE_T.vs_xiscale + 2]

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

mov   dx, word ptr ds:[si + VISSPRITE_T.vs_xiscale + 0] ; es in use. no LES
mov   bx, word ptr ds:[si + VISSPRITE_T.vs_xiscale + 2]

decrementbase4loop:
sub   word ptr [bp - 4], dx
sbb   word ptr [bp - 2], bx
dec   ax
jne   decrementbase4loop

base4diff_is_zero:

; zero xoffset loop iter
mov   byte ptr cs:[SELFMODIFY_MASKED_set_bx_to_xoffset+1 - OFFSET R_MASK24_STARTMARKER_], 0
mov   byte ptr cs:[SELFMODIFY_MASKED_set_bx_to_xoffset_shadow+1 - OFFSET R_MASK24_STARTMARKER_], 0

mov   cx, es


cmp   byte ptr ds:[si + VISSPRITE_T.vs_colormap], COLORMAP_SHADOW
je    jump_to_draw_shadow_sprite


jmp loop_vga_plane_draw_normal 


  
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
call  R_GetSpriteTexture_

mov   word ptr ds:[_lastvisspritesegment], ax
mov   es, ax
mov   ax, word ptr ds:[si + VISSPRITE_T.vs_patch]
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
cmp   ax, word ptr ds:[si + VISSPRITE_T.vs_x1]
jl    increment_by_shift

draw_sprite_normal_innerloop:
mov   ax, word ptr ds:[_dc_x]
cmp   ax, word ptr ds:[si + VISSPRITE_T.vs_x2]
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
inc   word ptr cs:[SELFMODIFY_MASKED_set_ax_to_dc_x_base4+1 - OFFSET R_MASK24_STARTMARKER_]
inc   byte ptr cs:[SELFMODIFY_MASKED_set_bx_to_xoffset+1 - OFFSET R_MASK24_STARTMARKER_]
mov   ax, word ptr ds:[si + VISSPRITE_T.vs_xiscale + 0]
add   word ptr [bp - 4], ax
mov   ax, word ptr ds:[si + VISSPRITE_T.vs_xiscale + 2]
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

cmp   ax, word ptr ds:[si + VISSPRITE_T.vs_x1]
jle   increment_by_shift_shadow

draw_sprite_shadow_innerloop:
mov   ax, word ptr ds:[_dc_x]
cmp   ax, word ptr ds:[si + VISSPRITE_T.vs_x2]
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
inc   word ptr cs:[SELFMODIFY_MASKED_set_ax_to_dc_x_base4_shadow+1 - OFFSET R_MASK24_STARTMARKER_]
inc   byte ptr cs:[SELFMODIFY_MASKED_set_bx_to_xoffset_shadow+1 - OFFSET R_MASK24_STARTMARKER_]
mov   ax, word ptr ds:[si + VISSPRITE_T.vs_xiscale + 0]
add   word ptr [bp - 4], ax
mov   ax, word ptr ds:[si + VISSPRITE_T.vs_xiscale + 2]
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

mov  word ptr ds:[_mfloorclip], OFFSET_SCREENHEIGHTARRAY 
mov  word ptr ds:[_mceilingclip], OFFSET_NEGONEARRAY 

cmp  word ptr ds:[_psprites], -1  ; STATENUM_NULL
je  check_next_player_sprite
mov  si, _player_vissprites       ; vissprite 0
call R_DrawVisSprite_

check_next_player_sprite:
cmp  word ptr ds:[_psprites + 0Ch], -1  ; STATENUM_NULL
je  exit_drawplayersprites
mov  si, _player_vissprites + (SIZE VISSPRITE_T)
call R_DrawVisSprite_

exit_drawplayersprites:
ret 


ENDP



PROC R_RenderMaskedSegRange_ NEAR

;void __near R_RenderMaskedSegRange (drawseg_t __far* ds, int16_t x1, int16_t x2) {

;es:di is far drawseg pointer
;x1 is ax
;x2 is cx

; no stack frame used..


  
push  di

; todo selfmodify all this up ahead too.


mov   word ptr cs:[SELFMODIFY_MASKED_x1_field_1+1 - OFFSET R_MASK24_STARTMARKER_], ax
mov   word ptr cs:[SELFMODIFY_MASKED_x1_field_2+1 - OFFSET R_MASK24_STARTMARKER_], ax
mov   word ptr cs:[SELFMODIFY_MASKED_x1_field_3+2 - OFFSET R_MASK24_STARTMARKER_], ax
mov   word ptr cs:[SELFMODIFY_MASKED_cmp_to_x2+1 - OFFSET R_MASK24_STARTMARKER_], cx

; grab a bunch of drawseg values early in the function and write them forward.
mov   si, di
lods  word ptr es:[si]  ; si 2 after

mov   word ptr ds:[_curseg], ax  ; todo only use? put on stack? dont use?
SHIFT_MACRO shl ax 3
add   ah, (_segs_render SHR 8 ) 		; segs_render is ds:[0x4000] 
mov   word ptr ds:[_curseg_render], ax  ; todo only use? put on stack? dont use?
mov   bx, ax

; todo rearrange fields to make this faster?
; this whole charade with the lodsw is ~6-8 bytes smaller overall than just doing displacement.
; It could be better if we arranged adjacent fields i guess.
mov   ax, es
mov   ds, ax
lods  word ptr ds:[si]  ; si 4 after
mov   word ptr cs:[SELFMODIFY_MASKED_dsp_02+1 - OFFSET R_MASK24_STARTMARKER_], ax
inc   si
inc   si
lods  word ptr ds:[si]  ; si 8 after
mov   word ptr cs:[SELFMODIFY_MASKED_dsp_06+1 - OFFSET R_MASK24_STARTMARKER_], ax
lods  word ptr ds:[si]  ; si A after
add   si, 4
mov   word ptr cs:[SELFMODIFY_MASKED_dsp_08+2 - OFFSET R_MASK24_STARTMARKER_], ax
lods  word ptr ds:[si]  ; si 0x10 after
mov   word ptr cs:[SELFMODIFY_MASKED_dsp_0E+1 - OFFSET R_MASK24_STARTMARKER_], ax
lods  word ptr ds:[si]  ; si 0x12 after
mov   word ptr cs:[SELFMODIFY_MASKED_dsp_10+1 - OFFSET R_MASK24_STARTMARKER_], ax
add   si, 4
lods  word ptr ds:[si]  ; si 0x18 after
mov   word ptr cs:[SELFMODIFY_MASKED_dsp_16+4 - OFFSET R_MASK24_STARTMARKER_], ax
lods  word ptr ds:[si]  ; si 0x1A after
mov   word ptr cs:[SELFMODIFY_MASKED_dsp_18+4 - OFFSET R_MASK24_STARTMARKER_], ax
lods  word ptr ds:[si]  ; si 0x1C after
mov   word ptr cs:[SELFMODIFY_MASKED_dsp_1A+1 - OFFSET R_MASK24_STARTMARKER_], ax

mov   ax, ss
mov   ds, ax

mov   ax, SIDES_SEGMENT
mov   si, word ptr ds:[bx + SEG_RENDER_T.sr_sidedefOffset]			; get sidedefOffset
mov   es, ax
; si was preshifted
mov   bx, si						; side_render_t is 4 bytes each
shl   si, 1							; side_t is 8 bytes each
add   bh, (_sides_render SHR 8 )		; sides render near addr is ds:[0xAE00]
mov   si, word ptr es:[si + SIDE_T.s_midtexture]		; lookup side->midtexture
mov   ax, word ptr ds:[bx + SIDE_RENDER_T.sr_rowoffset] 
mov   word ptr cs:[SELFMODIFY_MASKED_siderender_00+1 - OFFSET R_MASK24_STARTMARKER_], ax
mov   ax, word ptr ds:[bx + SIDE_RENDER_T.sr_secnum] 
mov   word ptr cs:[SELFMODIFY_MASKED_siderender_02+1 - OFFSET R_MASK24_STARTMARKER_], ax

mov   ax, TEXTURETRANSLATION_SEGMENT
add   si, si
mov   es, ax
mov   ax, MASKED_LOOKUP_SEGMENT
mov   si, word ptr es:[si]			; get texnum. si is stored for the whole function. not good revisit.
mov   es, ax
mov   al, byte ptr es:[si]			; translate texnum to lookup

; put texnum where it needs to be
mov   word ptr cs:[SELFMODIFY_MASKED_texnum_1+1 - OFFSET R_MASK24_STARTMARKER_], si
mov   word ptr cs:[SELFMODIFY_MASKED_texnum_2+1 - OFFSET R_MASK24_STARTMARKER_], si
mov   word ptr cs:[SELFMODIFY_MASKED_texnum_3+3 - OFFSET R_MASK24_STARTMARKER_], si

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



xchg  ax, bx
mov   ax, word ptr ds:[bx + _masked_headers + MASKED_HEADER_T.mh_postofsoffset]
mov   word ptr cs:[SELFMODIFY_MASKED_maskedpostofs_1  +3 - OFFSET R_MASK24_STARTMARKER_], ax
mov   word ptr cs:[SELFMODIFY_MASKED_maskedpostofs_2+3 - OFFSET R_MASK24_STARTMARKER_], ax

; nops
mov   ax, 0c089h 
mov   bx, ax

do_lookup_selfmodifies:
; write instructions forward
mov   word ptr cs:[SELFMODIFY_MASKED_lookup_1 - OFFSET R_MASK24_STARTMARKER_], ax
mov   word ptr cs:[SELFMODIFY_MASKED_lookup_2 - OFFSET R_MASK24_STARTMARKER_], bx



mov   ax, SEG_LINEDEFS_SEGMENT
mov   es, ax
mov   ax, word ptr ds:[_curseg]
mov   bx, ax
add   bh, (seg_sides_offset_in_seglines SHR 8)		; seg_sides_offset_in_seglines high word
mov   dl, byte ptr es:[bx]		; ; dl is curlineside here
sal   ax, 1
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
mov   word ptr cs:[SELFMODIFY_MASKED_lineflags_ml_dontpegbottom - OFFSET R_MASK24_STARTMARKER_], ax

les   bx, dword ptr ds:[bx]				; get v1 offset
mov   cx, es                            ; get v2 offset
mov   es, word ptr ds:[_VERTEXES_SEGMENT_PTR]

; todo i think remove this. i think they are preshifted, double check
SHIFT_MACRO shl bx 2
SHIFT_MACRO shl cx 2


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
mov   byte ptr cs:[SELFMODIFY_MASKED_add_vertex_field - OFFSET R_MASK24_STARTMARKER_], al




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



mov   bx, word ptr ds:[bx + _sides_render + SIDE_RENDER_T.sr_secnum]   ; get backsecnum



SELFMODIFY_MASKED_siderender_02:
mov   di, 01000h		; get side_render secnum



; bx holds backsector

mov   ax, SECTORS_SEGMENT
mov   es, ax



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
SHIFT32_MACRO_RIGHT ax dx 3

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
mov   word ptr cs:[SELFMODIFY_MASKED_dc_texturemid_lo_1 + 1 - OFFSET R_MASK24_STARTMARKER_], dx
mov   word ptr cs:[SELFMODIFY_MASKED_dc_texturemid_lo_2 + 1 - OFFSET R_MASK24_STARTMARKER_], dx
mov   word ptr cs:[SELFMODIFY_MASKED_dc_texturemid_lo_3 + 1 - OFFSET R_MASK24_STARTMARKER_], dx
mov   byte ptr cs:[SELFMODIFY_MASKED_dc_texturemid_hi_1 + 1 - OFFSET R_MASK24_STARTMARKER_], al
mov   word ptr cs:[SELFMODIFY_MASKED_dc_texturemid_hi_2 + 1 - OFFSET R_MASK24_STARTMARKER_], ax
mov   word ptr cs:[SELFMODIFY_MASKED_dc_texturemid_hi_3 + 1 - OFFSET R_MASK24_STARTMARKER_], ax

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
mov   byte ptr cs:[SELFMODIFY_MASKED_set_xlat_offset+2 - OFFSET R_MASK24_STARTMARKER_], 0
jmp   colormap_set


clip_lights_to_max:
mov    ax, 720   ; hardcoded (lightmult48lookup[LIGHTLEVELS - 1])

lights_set:
add   ax, OFFSET _scalelight
mov   word ptr cs:[SELFMODIFY_MASKED_set_walllights+2 - OFFSET R_MASK24_STARTMARKER_], ax      ; store lights


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

mov   word ptr cs:[SELFMODIFY_MASKED_rw_scalestep_lo_1+1 - OFFSET R_MASK24_STARTMARKER_], bx		; rw_scalestep
mov   word ptr cs:[SELFMODIFY_MASKED_rw_scalestep_lo_2+5 - OFFSET R_MASK24_STARTMARKER_], bx		; rw_scalestep
mov   word ptr cs:[SELFMODIFY_MASKED_rw_scalestep_lo_3+5 - OFFSET R_MASK24_STARTMARKER_], bx		; rw_scalestep
mov   word ptr cs:[SELFMODIFY_MASKED_rw_scalestep_hi_1+1 - OFFSET R_MASK24_STARTMARKER_], cx		; rw_scalestep
mov   word ptr cs:[SELFMODIFY_MASKED_rw_scalestep_hi_2+5 - OFFSET R_MASK24_STARTMARKER_], cx		; rw_scalestep
mov   word ptr cs:[SELFMODIFY_MASKED_rw_scalestep_hi_3+5 - OFFSET R_MASK24_STARTMARKER_], cx		; rw_scalestep



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
mov   word ptr cs:[SELFMODIFY_MASKED_dc_x_base4+1 - OFFSET R_MASK24_STARTMARKER_], ax

;		int16_t base4diff = x1 - dc_x_base4;

sub   di, ax						; di = base4diff = x1 - dc_x_base4

;		fixed_t basespryscale = spryscale.w;

mov   ax, word ptr ds:[_spryscale]
mov   word ptr cs:[SELFMODIFY_MASKED_get_basespryscale_lo+1 - OFFSET R_MASK24_STARTMARKER_], ax
mov   ax, word ptr ds:[_spryscale + 2]
mov   word ptr cs:[SELFMODIFY_MASKED_get_basespryscale_hi+1 - OFFSET R_MASK24_STARTMARKER_], ax

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


mov   word ptr cs:[SELFMODIFY_MASKED_rw_scalestep_shift_lo_1+1 - OFFSET R_MASK24_STARTMARKER_], ax		; rw_scalestep_shift
mov   word ptr cs:[SELFMODIFY_MASKED_rw_scalestep_shift_lo_2+4 - OFFSET R_MASK24_STARTMARKER_], ax		; rw_scalestep_shift
mov   word ptr cs:[SELFMODIFY_MASKED_rw_scalestep_shift_hi_1+2 - OFFSET R_MASK24_STARTMARKER_], dx		; rw_scalestep_shift
mov   word ptr cs:[SELFMODIFY_MASKED_rw_scalestep_shift_hi_2+4 - OFFSET R_MASK24_STARTMARKER_], dx		; rw_scalestep_shift

;		fixed_t sprtopscreen_step = FixedMul(dc_texturemid.w, rw_scalestep_shift);

SELFMODIFY_MASKED_dc_texturemid_lo_2:
mov   bx, 01000h
SELFMODIFY_MASKED_dc_texturemid_hi_2:
mov   cx, 01000h
call FixedMulMaskedLocal_


mov   word ptr cs:[SELFMODIFY_MASKED_sprtopscreen_lo+4 - OFFSET R_MASK24_STARTMARKER_], ax	  ; sprtopscreen_step
mov   word ptr cs:[SELFMODIFY_MASKED_sprtopscreen_hi+4 - OFFSET R_MASK24_STARTMARKER_], dx	  ; sprtopscreen_step


;	while (base4diff){
;		basespryscale -= rw_scalestep.w;
;		base4diff--;
;	}

test  di, di
je    base4diff_is_zero_rendermaskedsegrange

loop_dec_base4diff:
;			basespryscale -= rw_scalestep.w;

SELFMODIFY_MASKED_rw_scalestep_lo_2:
sub   word ptr cs:[SELFMODIFY_MASKED_get_basespryscale_lo+1 - OFFSET R_MASK24_STARTMARKER_], 01000h
SELFMODIFY_MASKED_rw_scalestep_hi_2:
sbb   word ptr cs:[SELFMODIFY_MASKED_get_basespryscale_hi+1 - OFFSET R_MASK24_STARTMARKER_], 01000h


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
mov   al, byte ptr ds:[di + 010h] ; selfmodified...
out   dx, al


;			spryscale.w = basespryscale;

SELFMODIFY_MASKED_get_basespryscale_lo:
mov   ax, 01000h
SELFMODIFY_MASKED_get_basespryscale_hi:
mov   dx, 01000h

; di holds xoffset.
; dx:ax temporarily holds _spryscale
; bx will temporarily store dc_x
;			dc_x        = dc_x_base4 + xoffset;
SELFMODIFY_MASKED_dc_x_base4:
mov   bx, 01000h
add   bx, di		; add xoffset to dc_x



;	if (dc_x < x1){
SELFMODIFY_MASKED_x1_field_3:
cmp   bx, 08000h   ; x1 
jge   calculate_sprtopscreen

; adjust by shiftstep

;	dc_x        += detailshiftitercount;
;	spryscale.w += rw_scalestep_shift;

SELFMODIFY_MASKED_detailshiftitercount_9:
add   bx, 01000h
SELFMODIFY_MASKED_rw_scalestep_shift_lo_1:
add   ax, 01000h
SELFMODIFY_MASKED_rw_scalestep_shift_hi_1:
adc   dx, 01000h

calculate_sprtopscreen:

mov   word ptr ds:[_dc_x], bx
mov   word ptr ds:[_spryscale], ax
mov   word ptr ds:[_spryscale + 2], dx

; bx:dx written back to  _spryscale

;			sprtopscreen.h.intbits = centery;
;			sprtopscreen.h.fracbits = 0;



;			sprtopscreen.w -= FixedMul(dc_texturemid.w,spryscale.w);


SELFMODIFY_MASKED_dc_texturemid_lo_3:
mov   bx, 01000h
SELFMODIFY_MASKED_dc_texturemid_hi_3:
mov   si, 01000h

test  dx, dx
jnz   do_32_bit_mul
test  ax, ax
js    do_32_bit_mul_after_all

do_16_bit_mul_after_all:


; todo make room to inline
;call FixedMul1632MaskedLocal_

  MOV CX, AX
  MUL BX
  XCHG AX, DX
  XCHG AX, CX
  CWD
  AND BX, DX

  IMUL SI
  SUB CX, BX
  SBB BX, BX
  ADD AX, CX
  ADC DX, BX



done_with_mul:

neg   ax ; no need to subtract from zero...
mov   word ptr ds:[_sprtopscreen], ax
SELFMODIFY_MASKED_centery_2:
mov   ax, 01000h
sbb   ax, dx
mov   word ptr ds:[_sprtopscreen + 2], ax

mov   word ptr cs:[SELF_MODIFY_MASKED_xoffset+1 - OFFSET R_MASK24_STARTMARKER_], di

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
add   word ptr cs:[SELFMODIFY_MASKED_get_basespryscale_lo+1 - OFFSET R_MASK24_STARTMARKER_], 01000h
SELFMODIFY_MASKED_rw_scalestep_hi_3:
adc   word ptr cs:[SELFMODIFY_MASKED_get_basespryscale_hi+1 - OFFSET R_MASK24_STARTMARKER_], 01000h


; xoffset < detailshiftitercount
SELFMODIFY_MASKED_detailshiftitercount_8:
cmp   di, 0
jle   continue_outer_loop		; 6 bytes out of range

exit_render_masked_segrange:
mov   ax, NULL_TEX_COL
mov   word ptr ds:[_maskednextlookup], ax
mov   word ptr ds:[_maskedcachedbasecol], ax
mov   word ptr ds:[_maskedtexrepeat], 0

pop   di

ret   

do_32_bit_mul:
inc   dx
jz    do_16_bit_mul_after_all
dec   dx
do_32_bit_mul_after_all:

call FixedMulMaskedLocal_


jmp done_with_mul

do_inner_loop:
;   ax is dc_x
les   bx, dword ptr ds:[_maskedtexturecol]
sal   ax, 1
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
SHIFT32_MACRO_RIGHT dx ax 4

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
mov   byte ptr cs:[SELFMODIFY_MASKED_set_xlat_offset+2 - OFFSET R_MASK24_STARTMARKER_], al

SELFMODIFY_MASKED_fixedcolormap_1_TARGET:
got_colormap:

mov   bx, word ptr ds:[_spryscale]
mov   cx, word ptr ds:[_spryscale + 2]
call  FastDiv3232FFFF_   ; todo inline?

mov   word ptr cs:[SELFMODIFY_MASKED_set_dc_iscale_lo+1 - OFFSET R_MASK24_STARTMARKER_], ax
mov   byte ptr cs:[SELFMODIFY_MASKED_set_dc_iscale_hi+1 - OFFSET R_MASK24_STARTMARKER_], dl


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
call  R_GetMaskedColumnSegment_  


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
call  R_GetMaskedColumnSegment_

mov   di, word ptr ds:[_maskedcachedbasecol]
mov   dx, word ptr ds:[_cachedbyteheight]  ; todo optimize this to a full word with 0 high byte in data. then optimize in _R_DrawSingleMaskedColumn_ as well

; call  dword ptr ds:[_R_DrawSingleMaskedColumnCallHigh]  ; todo... do i really want this
call R_DrawSingleMaskedColumn_  ;todo inline here, jump from above case? both jump to same spot after.


jmp   update_maskedtexturecol_finish_loop_iter

ENDP

; todo constants
PATCH_TEXTURE_SEGMENT = 05000h
COMPOSITE_TEXTURE_SEGMENT = 05000h
SPRITE_COLUMN_SEGMENT = 09000h
SCRATCH_ADDRESS_4000_SEGMENT = 04000h
SCRATCH_ADDRESS_5000_SEGMENT = 05000h

PROC R_GetSpriteTexture_ NEAR

push  dx
push  si
mov   si, SPRITEPAGE_SEGMENT
mov   es, si

xchg  ax, si    ; si gets index

mov   al, byte ptr es:[si]
cmp   al, 0FFh
je    sprite_not_in_cache

mov   dl, byte ptr es:[si + SPRITEOFFSETS_OFFSET]

call  R_GetSpritePage_
xor   ah, ah
mov   si, ax
mov   al, dl
SHIFT_MACRO shl   ax 4
sal   si, 1
mov   dx, word ptr cs:[si + _pagesegments - OFFSET R_MASK24_STARTMARKER_]
add   dh, (SPRITE_COLUMN_SEGMENT SHR 8)
add   ax, dx
pop   si
pop   dx
ret

sprite_not_in_cache:

mov   ax, word ptr ds:[_firstspritelump]
add   ax, si
push  ax    ; bp - 2, index
push  es    ; bp - 4, segment
call  R_GetNextSpriteBlock_

pop   es    ; bp - 4, segment
mov   al, byte ptr es:[si]

mov   dl, byte ptr es:[si + SPRITEOFFSETS_OFFSET]

call  R_GetSpritePage_
xor   ah, ah
mov   si, ax
mov   al, dl
SHIFT_MACRO shl   ax 4
sal   si, 1
mov   dx, word ptr cs:[si + _pagesegments - OFFSET R_MASK24_STARTMARKER_]
add   dh, (SPRITE_COLUMN_SEGMENT SHR 8) 
add   dx, ax
mov   si, dx ; back this up
pop   ax     ; bp - 2, index

call  R_LoadSpriteColumns_

mov   ax, si
pop   si
pop   dx
ret


ENDP





PROC R_GetNextSpriteBlock_ NEAR



PUSHA_NO_AX_MACRO
push      bp
mov       bp, sp

IF COMPISA GE COMPILE_186
    push      CACHETYPE_SPRITE 
ELSE
    mov   dx, CACHETYPE_SPRITE 
    push  dx
ENDIF
sub       ax, word ptr ds:[_firstspritelump]
mov       dx, SPRITETOTALDATASIZES_SEGMENT
mov       es, dx
mov       bx, ax
sal       bx, 1
mov       dx, word ptr es:[bx] ; dx = size
mov       bl, dh
push      bx  ; bp - 4  only bl technically
IF COMPISA GE COMPILE_186
    push      NUM_SPRITE_CACHE_PAGES 
ELSE
    mov   di, NUM_SPRITE_CACHE_PAGES 
    push  di
ENDIF


push      ax  ; bp - 6  store for later
mov       di, OFFSET _spritecache_nodes
mov       si, OFFSET _usedspritepagemem


xchg      ax, bx


;	if (size & 0xFF) {
;		blocksize++;
;	}

test      dl, 0FFh
je        dont_increment_blocksize
inc       al
mov       byte ptr [bp - 4], al
dont_increment_blocksize:
;	numpages = blocksize >> 6; // num EMS pages needed

xor       ah, ah
SHIFT_MACRO rol       al 2
and       al, 3

;	if (blocksize & 0x3F) {
;		numpages++;
;	}

mov       ch, al
test      byte ptr [bp - 4], 03Fh
je        dont_increment_numpages
inc       ch
dont_increment_numpages:

;	if (numpages == 1) {

xor       bx, bx
cmp       ch, 1
jne       multipage_textureblock
;		uint8_t freethreshold = 64 - blocksize;
mov       dx, 04000h
sub       dh, byte ptr [bp - 4]
; dl zeroed 

;		for (i = 0; i < NUM_TEXTURE_PAGES; i++) {
;			if (freethreshold >= usedtexturepagemem[i]) {
;				goto foundonepage;
;			}
;		}

check_next_texture_page_for_space:
mov       bl, dl
cmp       dh, byte ptr ds:[bx + si]
jnb       foundonepage

;		i = R_EvictL2CacheEMSPage(1, cachetype);

inc       dl
cmp       dl, [bp - 6]
jl        check_next_texture_page_for_space
mov       al, byte ptr [bp - 2]
cbw      
mov       dx, ax
mov       al, 1
call      R_EvictL2CacheEMSPage_Sprite_
mov       dl, al

foundonepage:

;		texpage = i << 2;
;		texoffset = usedtexturepagemem[i];
;		usedtexturepagemem[i] += blocksize;

mov       dh, dl
SHIFT_MACRO shl       dh 2
mov       bl, dl
mov       al, byte ptr ds:[bx + si]
mov       ah, byte ptr [bp - 4]
add       ah, al
mov       byte ptr ds:[bx + si], ah

done_finding_open_page:
pop       si ; was bp - 6
cmp       byte ptr [bp - 2], CACHETYPE_PATCH
jne       set_non_patch_pages
set_patch_pages:
mov       bx, PATCHOFFSET_SEGMENT
mov       es, bx
mov       byte ptr es:[si], dh
mov       byte ptr es:[si + PATCHOFFSET_OFFSET], al
LEAVE_MACRO     
POPA_NO_AX_MACRO
ret       
set_non_patch_pages:
jb        set_sprite_pages
set_tex_pages:
mov       bx, COMPOSITETEXTUREOFFSET_SEGMENT
mov       es, bx
mov       byte ptr es:[si], dh
mov       byte ptr es:[si + COMPOSITETEXTUREOFFSET_OFFSET], al
LEAVE_MACRO     
POPA_NO_AX_MACRO
ret       
set_sprite_pages:
mov       bx, SPRITEPAGE_SEGMENT
mov       es, bx
mov       byte ptr es:[si], dh
mov       byte ptr es:[si + SPRITEOFFSETS_OFFSET], al
LEAVE_MACRO     
POPA_NO_AX_MACRO
ret       


multipage_textureblock:

;		uint8_t numpagesminus1 = numpages - 1;

mov       dh, byte ptr ds:[_texturecache_l2_head]
mov       ah, 0FFh
mov       cl, 040h
; al is free, in use a lot
; ah is 0FFh
; bh is 000h
; bl is active offset
; ch is numpages
; cl is 040h
; dh is head
; dl is nextpage


;		for (i = texturecache_l2_head;
;				i != -1; 
;				i = texturecache_nodes[i].prev
;				) {
;			if (!usedtexturepagemem[i]) {
;				// need to check following pages for emptiness, or else after evictions weird stuff can happen
;				int8_t nextpage = texturecache_nodes[i].prev;
;				if ((nextpage != -1 &&!usedtexturepagemem[nextpage])) {
;					nextpage = texturecache_nodes[nextpage].prev;

;				}
;			}
;		}

cmp       dh, ah  ; dh is texturecache_l2_head
je        done_with_textureblock_multipage_loop

do_texture_multipage_loop:
mov       bl, dh
cmp       byte ptr ds:[bx + si], bh
jne       do_next_texture_multipage_loop_iter

page_has_space:
SHIFT_MACRO shl       bl 2
mov       al, byte ptr ds:[bx + di]
cmp       al, ah
je        do_next_texture_multipage_loop_iter
; has next page
mov       bl, al
cmp       byte ptr ds:[bx + si], bh
jne       do_next_texture_multipage_loop_iter
SHIFT_MACRO shl       bl 2
mov       dl, byte ptr ds:[bx + di]

;					if (numpagesminus1 < 2 || (nextpage != -1 && (!usedtexturepagemem[nextpage]))) {


cmp       ch, 3   ; use numpages instead of numpagesminus1
jb        less_than_2_pages_or_next_page_good
not_less_than_2_pages_check_next_page_good:
cmp       dl, ah
je        do_next_texture_multipage_loop_iter
mov       bl, dl
cmp       byte ptr ds:[bx + si], bh
jne       do_next_texture_multipage_loop_iter

less_than_2_pages_or_next_page_good:

;						nextpage = texturecache_nodes[nextpage].prev;

mov       bl, dl
SHIFT_MACRO shl       bl 2
mov       dl, byte ptr ds:[bx + di]

;						if (numpagesminus1 < 3 || (nextpage != -1 &&(!usedtexturepagemem[nextpage]))) {
;							goto foundmultipage;
;						}

cmp       ch, 4  ; use numpages instead of numpagesminus1
jb        found_multipage


check_for_next_multipage_loop_iter:

; (nextpage != -1 &&(!usedtexturepagemem[nextpage])
cmp       dl, ah
je        do_next_texture_multipage_loop_iter
mov       bl, dl
cmp       byte ptr ds:[bx + si], bh
jne       do_next_texture_multipage_loop_iter

do_next_texture_multipage_loop_iter:
mov       bl, dh
SHIFT_MACRO shl       bl 2
mov       dh, byte ptr ds:[bx + di]
cmp       dh, ah
jne       do_texture_multipage_loop

done_with_textureblock_multipage_loop:

;		i = R_EvictL2CacheEMSPage(numpages, cachetype);

mov       al, byte ptr [bp - 2]
cbw      
mov       dx, ax
mov       al, ch
call      R_EvictL2CacheEMSPage_Sprite_
mov       dh, al

less_than_3_pages_or_next_page_good:
found_multipage:
;		foundmultipage:
;        usedtexturepagemem[i] = 64;

mov       bl, dh
mov       byte ptr ds:[bx + si], cl

;		texturecache_nodes[i].numpages = numpages;
;		texturecache_nodes[i].pagecount = numpages;

SHIFT_MACRO shl       bl 2
mov       byte ptr ds:[bx + di + 3], ch
mov       byte ptr ds:[bx + di + 2], ch
mov       dl, dh
;		if (numpages >= 3) {
cmp       ch, 3
jl        numpages_not_3_or_more
mov       dl, byte ptr ds:[bx + di]
mov       bl, dl
mov       al, ch
dec       al
mov       byte ptr ds:[bx + si], cl
SHIFT_MACRO shl       bl 2
mov       byte ptr ds:[bx + di + 3], ch
mov       byte ptr ds:[bx + di + 2], al
numpages_not_3_or_more:
mov       bl, dl
SHIFT_MACRO shl       bl 2
mov       al, byte ptr ds:[bx + di]
mov       bl, al
SHIFT_MACRO shl       bl 2

;		texturecache_nodes[j].numpages = numpages;
;		texturecache_nodes[j].pagecount = 1;

mov       byte ptr ds:[bx + di + 2], 1
mov       byte ptr ds:[bx + di + 3], ch
mov       bl, al

mov       al, byte ptr [bp - 4]

;	if (blocksize & 0x3F) {

test      al, 03Fh
jne        dont_set_used_all_memory_for_page
;			usedtexturepagemem[j] = blocksize & 0x3F;
set_used_all_memory_for_page:

;			usedtexturepagemem[j] = 64;


;		texpage = (i << 2) + (numpagesminus1);
;		texoffset = 0; // if multipage then its always aligned to start of its block


mov       byte ptr ds:[bx + si], cl
SHIFT_MACRO shl       dh 2
xor       al, al
add       dh, ch  ; use numpages instead of numpagesminus1
dec       dh 
jmp       done_finding_open_page
dont_set_used_all_memory_for_page:
and       al, 03Fh
mov       byte ptr ds:[bx + si], al

;		texpage = (i << 2) + (numpagesminus1);
;		texoffset = 0; // if multipage then its always aligned to start of its block

SHIFT_MACRO shl       dh 2
xor       al, al
add       dh, ch    ; use numpages instead of numpagesminus1. need the dec
dec       dh
jmp       done_finding_open_page



ENDP




PROC R_EvictL2CacheEMSPage_Sprite_ NEAR

; bp - 2 currentpage

push      bx
push      cx
push      si
push      di
mov       dh, al




mov       di, OFFSET _spritecache_nodes


done_with_switchblock:

;	currentpage = *nodetail;

mov       al, byte ptr ds:[_spritecache_l2_tail]
cbw      
xor       dl, dl

;	// go back enough pages to allocate them all.
;	for (j = 0; j < numpages-1; j++){
;		currentpage = nodelist[currentpage].next;
;	}


; dh has numpages
; dl has j
dec       dh  ; numpages - 1

go_back_next_page:
cmp       dl, dh
jge       found_enough_pages
mov       bx, ax
SHIFT_MACRO shl       bx, 2
mov       al, byte ptr ds:[bx + di + 1]  ; get next
inc       dl
jmp       go_back_next_page


found_enough_pages:

push ax   ; bp - 2 store currentpage

;	evictedpage = currentpage;

mov       cx, ax

;	while (nodelist[evictedpage].numpages != nodelist[evictedpage].pagecount){
;		evictedpage = nodelist[evictedpage].next;
;	}


find_first_evictable_page:
mov       bx, cx
SHIFT_MACRO shl       bx, 2
mov       ax, word ptr ds:[bx + di + 2]
cmp       al, ah
je        found_first_evictable_page
mov       al, byte ptr ds:[bx + di + 1]
cbw      
mov       cx, ax
jmp       find_first_evictable_page

found_first_evictable_page:





;	while (evictedpage != -1){
mov       dx, 000FFh      ; dh gets 0, dl gets ff

check_next_evicted_page:
cmp       cl, dl
je        cleared_all_cache_data


do_next_evicted_page:


; loop setup
mov       bx, cx
SHIFT_MACRO shl       bx 2

xor       ax, ax


;		nodelist[evictedpage].pagecount = 0;
;		nodelist[evictedpage].numpages = 0;

mov       word ptr ss:[bx + di + 2], ax    ; set both at once
mov       si, ax                   ; zero
; ds!

mov       bx, SPRITEPAGE_SEGMENT
mov       ds, bx
mov       bx, MAX_SPRITE_LUMPS


;    for (k = 0; k < maxitersize; k++){
;			if ((cacherefpage[k] >> 2) == evictedpage){
;				cacherefpage[k] = 0xFF;
;				cacherefoffset[k] = 0xFF;
;			}
;		}
dec       bx   ; lodsw makes this off by one so we offset here...

continue_first_cache_erase_loop:
lodsb     ; increments si...
SHIFT_MACRO shr       ax, 2
cmp       al, cl
je        erase_this_page
done_erasing_page:
cmp       si, bx
jle       continue_first_cache_erase_loop   ; jle, not jl because bx is decced

done_with_first_cache_erase_loop:

; sprites have no secondary cache loop

;		usedcacherefpage[evictedpage] = 0;





mov       bx, cx
mov       byte ptr ss:[bx + _usedspritepagemem], dh    ; 0

;		evictedpage = nodelist[evictedpage].prev;

SHIFT_MACRO shl       bx 2
mov       cl, byte ptr ss:[bx + di]     ; get prev
cmp       cl, dl                   ; dl is -1
jne       do_next_evicted_page


cleared_all_cache_data:

;	// connect old tail and old head.
;	nodelist[*nodetail].prev = *nodehead;
mov      ax, ss
mov      ds, ax
mov       al, byte ptr ds:[_spritecache_l2_tail]
cbw      
mov       cx, ax            ; cx stores nodetail

SHIFT_MACRO shl       ax 2
xchg      ax, bx            ; bx has nodelist nodetail lookup

mov       si, OFFSET _spritecache_l2_head
mov       al, byte ptr ds:[si]
mov       byte ptr ds:[bx + di], al
mov       bl, al

;	nodelist[*nodehead].next = *nodetail;
SHIFT_MACRO shl       bx 2
mov       byte ptr ds:[bx + di + 1], cl  ; write nodetail to next
;	previous_next = nodelist[currentpage].next;
;	*nodehead = currentpage;
pop       bx ; retrieve currentpage

mov       byte ptr ds:[si], bl
SHIFT_MACRO shl       bx 2
mov       al, byte ptr ds:[bx + di + 1]    ; previous_next
cbw
;	nodelist[currentpage].next = -1;
mov       byte ptr ds:[bx + di + 1], dl   ; still 0FFh
;	*nodetail = previous_next;
mov       byte ptr ds:[_spritecache_l2_tail], al

;	// new tail
;	nodelist[previous_next].prev = -1;
mov       bx, ax
SHIFT_MACRO shl       bx 2
mov       byte ptr ds:[bx + di], dl    ; still 0FFh

;	return *nodehead;

lodsb       

pop       di
pop       si
pop       cx
pop       bx
ret       
erase_this_page:
mov       byte ptr ds:[si-1], dl     ; 0FFh
mov       byte ptr ds:[si+bx], dl    ; 0FFh
jmp       done_erasing_page




ENDP

PROC R_MarkL1SpriteCacheMRU_ NEAR


mov  ah, byte ptr ds:[_spriteL1LRU+0]
cmp  al, ah
je   exit_markl1spritecachemru
mov  byte ptr ds:[_spriteL1LRU+0], al
xchg byte ptr ds:[_spriteL1LRU+1], ah
cmp  al, ah
je   exit_markl1spritecachemru
xchg byte ptr ds:[_spriteL1LRU+2], ah
cmp  al, ah
je   exit_markl1spritecachemru
xchg byte ptr ds:[_spriteL1LRU+3], ah
exit_markl1spritecachemru:
ret  


ENDP




ENDP

PROC R_MarkL2SpriteCacheMRU_ NEAR

;	if (index == spritecache_l2_head) {
;		return;
;	}

cmp  al, byte ptr ds:[_spritecache_l2_head]
jne  dont_early_out
ret



dont_early_out:
PUSHA_NO_AX_MACRO
mov  si, OFFSET _spritecache_nodes
mov  di, OFFSET _spritecache_l2_tail
mov  es, di
mov  di, OFFSET _spritecache_l2_head
;dec  di ; OFFSET _spritecache_l2_head
; todo just use di - 1 instead of es
do_markl2func:

mov  cl, byte ptr ds:[di]
mov  dl, al
mov  bx, ax

;	pagecount = spritecache_nodes[index].pagecount;
;	if (pagecount){

SHIFT_MACRO shl  bx 2
mov  al, byte ptr ds:[bx + si + 2]
test al, al
je   sprite_pagecount_zero

;	 	while (spritecache_nodes[index].numpages != spritecache_nodes[index].pagecount){
;			index = spritecache_nodes[index].next;
;		}

sprite_check_next_cache_node:
mov  bl, dl   ; bh always zero here...
SHIFT_MACRO shl  bx 2
mov  ax, word ptr ds:[bx + si + 2]
cmp  al, ah
je   sprite_found_first_index
mov  dl, byte ptr ds:[bx + si + 1]
jmp  sprite_check_next_cache_node

sprite_found_first_index:

;		if (index == spritecache_l2_head) {
;			return;
;		}

cmp  dl, cl             ; dh is free, use dh instead here?
je   mark_sprite_lru_exit
sprite_pagecount_zero:


; bx should already be set...

;	if (spritecache_nodes[index].numpages){

cmp  byte ptr ds:[bx + si + 3], 0
je   selected_sprite_page_single_page

; multi page case...

;		lastindex = index;
;		while (spritecache_nodes[lastindex].pagecount != 1){
;			lastindex = spritecache_nodes[lastindex].prev;
;		}


mov  dh, dl         ; dh = last index
sprite_check_next_cache_node_pagecount:

mov  bl, dh         ; bh always 0 here...
SHIFT_MACRO  shl  bx 2
cmp  byte ptr ds:[bx + si + 2], 1
je   found_sprite_multipage_last_page
mov  dh, byte ptr ds:[bx + si + 0]
jmp  sprite_check_next_cache_node_pagecount

found_sprite_multipage_last_page:

; dl = index
; dh = lastindex

;		lastindex_prev = spritecache_nodes[lastindex].prev;
;		index_next = spritecache_nodes[index].next;


mov  ch, byte ptr ds:[bx + si + 0]    ; lastindex_prev
mov  bl, dl
SHIFT_MACRO   shl  bx 2

mov  cl, byte ptr ds:[bx + si + 1]    ; index_next

;		if (spritecache_l2_tail == lastindex){
mov  bx, es  ; tail
cmp  dh, byte ptr ds:[bx]
jne  spritecache_l2_tail_not_equal_to_lastindex

;			spritecache_l2_tail = index_next;
;			spritecache_nodes[index_next].prev = -1;

mov  byte ptr ds:[bx], cl
xor  bx, bx
mov  bl, cl
SHIFT_MACRO   shl  bx 2
mov  byte ptr ds:[bx + si + 0], -1
jmp  sprite_done_with_multi_tail_update

spritecache_l2_tail_not_equal_to_lastindex:

;			spritecache_nodes[lastindex_prev].next = index_next;
;			spritecache_nodes[index_next].prev = lastindex_prev;

xor  bx, bx
mov  bl, ch
SHIFT_MACRO shl  bx 2
mov  byte ptr ds:[bx + si + 1], cl

mov  bl, cl
SHIFT_MACRO shl  bx 2
mov  byte ptr ds:[bx + si + 0], ch

sprite_done_with_multi_tail_update:

;		spritecache_nodes[lastindex].prev = spritecache_l2_head;
;		spritecache_nodes[spritecache_l2_head].next = lastindex;

mov  bl, dh
SHIFT_MACRO    shl  bx 2
mov  al, byte ptr ds:[di]
mov  byte ptr ds:[bx + si + 0], al  ; spritecache_l2_head
mov  bl, al
SHIFT_MACRO    shl  bx 2
mov  byte ptr ds:[bx + si + 1], dh  ; lastindex

mov  bl, dl
SHIFT_MACRO    shl  bx 2

;		spritecache_nodes[index].next = -1;
;		spritecache_l2_head = index;


mov  byte ptr ds:[di], dl
mov  byte ptr ds:[bx + si + 1], -1
mark_sprite_lru_exit:
POPA_NO_AX_MACRO
ret  

selected_sprite_page_single_page:

;		// handle the simple one page case.
;		prev = spritecache_nodes[index].prev;
;		next = spritecache_nodes[index].next;

mov  dh, byte ptr ds:[bx + si + 1]
mov  ch, byte ptr ds:[bx + si + 0]

;		if (index == spritecache_l2_tail) {
;			spritecache_l2_tail = next;
;		} else {
;			spritecache_nodes[prev].next = next; 
;		}


mov  bx, es  ; tail
cmp  dl, byte ptr ds:[bx]
jne  spritecache_tail_not_equal_to_index
mov  byte ptr ds:[bx], dh
xor  bx, bx
jmp  done_with_spritecache_tail_handling

spritecache_tail_not_equal_to_index:
xor  bx, bx
mov  bl, ch
SHIFT_MACRO shl  bx 2
mov  byte ptr ds:[bx + si + 1], dh

done_with_spritecache_tail_handling:

; spritecache_nodes[next].prev = prev;  // works in either of the above cases. prev is -1 if tail.

mov  bl, dh
SHIFT_MACRO shl  bx 2
mov  byte ptr ds:[bx + si + 0], ch

;	spritecache_nodes[index].prev = spritecache_l2_head;
;	spritecache_nodes[index].next = -1;

mov  bl, dl
SHIFT_MACRO shl  bx 2
mov  ch, -1
mov  word ptr ds:[bx + si + 0], cx

; spritecache_nodes[spritecache_l2_head].next = index;

mov  bl, cl
SHIFT_MACRO shl  bx 2
mov  byte ptr ds:[bx + si + 1], dl

;	spritecache_l2_head = index;

mov  byte ptr ds:[di], dl

POPA_NO_AX_MACRO
ret  


ENDP

; todo inline...
PROC Z_QuickMapSpritePage_ NEAR

push  dx
push  cx
push  si

Z_QUICKMAPAI4 pageswapargs_spritecache_offset_size INDEXED_PAGE_9000_OFFSET

pop   si
pop   cx
pop   dx
ret   

ENDP

; part of R_GetTexturePage_

found_active_single_page:

;    R_MarkL1TextureCacheMRU(i);
; bl holds i
; al holds realtexpage

xchg  ax, dx            ; dx gets realtexpage
mov   ax, bx            ; ax gets i
call  R_MarkL1SpriteCacheMRU_

;    R_MarkL2TextureCacheMRU(realtexpage);

xchg  ax, dx            ; realtexpage into ax. 
call  R_MarkL2SpriteCacheMRU_

;    return i;

mov   es, bx            ; return i
LEAVE_MACRO 
POPA_NO_AX_MACRO
mov   ax, es
ret   


PROC R_GetSpritePage_ NEAR

PUSHA_NO_AX_MACRO
push  bp
mov   bp, sp


mov   si, OFFSET _activespritepages
mov   di, OFFSET _activespritenumpages
mov   cx, NUM_SPRITE_L1_CACHE_PAGES
mov   dx, FIRST_SPRITE_CACHE_LOGICAL_PAGE ; pageoffset

continue_get_page:

push  cx        ; bp - 2         max   (loop counter etc). ch 0
push  dx        ; bp - 4   dh 0 pageoffset

;	uint8_t realtexpage = texpage >> 2;
mov   dl, al
SHIFT_MACRO sar   dx 2
push  dx        ; bp - 6   dh 0 realtexpage

;	uint8_t numpages = (texpage& 0x03);


xchg  ax, dx   ; ax has realtexpage
and   dx, 3    ; zero dh here
;	if (!numpages) {                ; todo push less stuff if we get the zero case?
jne   get_multipage

; single page

;		// one page, most common case - lets write faster code here...
;		for (i = 0; i < NUM_TEXTURE_L1_CACHE_PAGES; i++) {
;			if (activetexturepages[i] == realtexpage ) {
;				R_MarkL1TextureCacheMRU(i);
;				R_MarkL2TextureCacheMRU(realtexpage);
;				return i;
;			}
;		}

;     dl/dx known zero because we jumped otherwise.
mov   bx, dx ; zero

; al is realtexpage
; bx is i

loop_next_active_page_single:
cmp   al, byte ptr ds:[bx + si]
je    found_active_single_page
inc   bx
cmp   bx, cx
jb    loop_next_active_page_single

; cache miss...

;		startpage = textureL1LRU[NUM_TEXTURE_L1_CACHE_PAGES-1];
;		R_MarkL1TextureCacheMRU7(startpage);

;   ah is 0. al is dirty but gets fixed...
cwd
dec   dx ; dx = -1, ah is 0
mov   bx, cx    ; NUM_TEXTURE_L1_CACHE_PAGES
dec   bx        ; NUM_TEXTURE_L1_CACHE_PAGES - 1
mov   al, byte ptr ds:[bx + _spriteL1LRU]   ; textureL1LRU[NUM_TEXTURE_L1_CACHE_PAGES-1]
mov   bx, ax
mov   cx, ax
;call  R_MarkL1SpriteCacheMRU3_
; inlined
push word ptr ds:[_spriteL1LRU+1]     ; grab [1] and [2]
pop  word ptr ds:[_spriteL1LRU+2]     ; put in [2] and [3]
xchg al, byte ptr ds:[_spriteL1LRU+0] ; swap index for [0]
mov  byte ptr ds:[_spriteL1LRU+1], al ; put [0] in [1]



;		// if the deallocated page was a multipage allocation then we want to invalidate the other pages.
;		if (activenumpages[startpage]) {
;			for (i = 1; i <= activenumpages[startpage]; i++) {
;				activetexturepages[startpage+i]  = -1; // unpaged
;				//this is unmapping the page, so we don't need to use pagenum/nodelist
;				pageswapargs[pageswapargs_rend_texture_offset+( startpage+i)*PAGE_SWAP_ARG_MULT] = 
;					_NPR(PAGE_5000_OFFSET+startpage+i);
;				activenumpages[startpage+i] = 0;
;			}
;		}

cmp   byte ptr ds:[bx + di], ah  ; ah is still 0 after MRU7/MRU3 func 0
je    found_start_page_single

mov   al, 1 ; al/ax is i
; cl/cx is start page.
; bx is start page or startpage + i offset
; dl was numpages but we know its zero. so use dx for -1 for small code reasons

deallocate_next_startpage_single:

cmp   al, byte ptr ds:[bx + di]
ja    found_start_page_single

add   bl, al
mov   byte ptr ds:[bx + di], 0


; bx is currently startpage+i as a byte lookup

; _NPR(PAGE_5000_OFFSET+startpage+i);


IFDEF COMP_CH
    IF COMP_CH EQ CHIPSET_SCAT
        mov   byte ptr ds:[bx + si], dl   ; dl is -1
        sal   bx, 1
        SHIFT_PAGESWAP_ARGS bx
        mov   word ptr ds:[bx + _pageswapargs + (PAGESWAPARGS_SPRITECACHE_OFFSET * 2)], 03FFh
    ELSEIF COMP_CH EQ CHIPSET_SCAMP
        mov   byte ptr ds:[bx + si], dl   ; dl is -1
        mov   dx, bx
        sal   bx, 1
        add   dx, ((SCAMP_PAGE_9000_OFFSET + 4) - (010000h - PAGE_9000_OFFSET))   ; shut up compiler warning   ; page offset
        SHIFT_PAGESWAP_ARGS bx
        mov   word ptr ds:[bx + _pageswapargs + (PAGESWAPARGS_SPRITECACHE_OFFSET * 2)], dx
        mov   dx, -1
    ELSEIF COMP_CH EQ CHIPSET_HT18
        mov   byte ptr ds:[bx + si], dl   ; dl is -1
        sal   bx, 1
        SHIFT_PAGESWAP_ARGS bx
        mov   word ptr ds:[bx + _pageswapargs + (PAGESWAPARGS_SPRITECACHE_OFFSET * 2)], 0
    ENDIF
ELSE
    mov   byte ptr ds:[bx + si], dl   ; dl is -1
    sal   bx, 1
    SHIFT_PAGESWAP_ARGS bx
    mov   word ptr ds:[bx + _pageswapargs + (PAGESWAPARGS_SPRITECACHE_OFFSET * 2)], dx ; dx is -1

ENDIF

inc   al


mov   bx, cx    ; zero out bh
jmp   deallocate_next_startpage_single

get_multipage:

; ah already zero

mov   bx, 0FFFFh ; -1, offset for the initial inc
; cx already the number
sub   cx, dx
;  al/ax already realtexpage

; dl is numpages
; cl is NUM_TEXTURE_L1_CACHE_PAGES-numpages
; ch is 0
; bl will be i (starts as -2, incrementing to 0 first loop)
; for (i = 0; i < NUM_TEXTURE_L1_CACHE_PAGES-numpages; i++) {
; al is realtexpage


grab_next_page_loop_multi_continue:

inc   bx  ; 0 for 1st iteration after dec

cmp   bl, cl ; loop compare

jnl   evict_and_find_startpage_multi

;    if (activetexturepages[i] != realtexpage){
;        continue;
;    }

cmp   al, byte ptr ds:[bx + si]
jne   grab_next_page_loop_multi_continue


;    // all pages for this texture are in the cache, unevicted.
;    for (j = 0; j <= numpages; j++) {
;        R_MarkL1TextureCacheMRU(i+j);
;    }
mov   dh, bl
; bl is i
; bl/bx will be i+j   
; dl is numpages but we dec it till < 0

mark_all_pages_mru_loop:
mov   ax, bx

call  R_MarkL1SpriteCacheMRU_
inc   bl
dec   dl
jns   mark_all_pages_mru_loop
 


;    R_MarkL2TextureCacheMRU(realtexpage);
;    return i;

pop   ax;   word ptr [bp - 6]
call  R_MarkL2SpriteCacheMRU_
mov   al, dh
mov   es, ax
LEAVE_MACRO 
POPA_NO_AX_MACRO
mov   ax, es
ret   
 
;		// figure out startpage based on LRU
;		startpage = NUM_TEXTURE_L1_CACHE_PAGES-1; // num EMS pages in conventional memory - 1

evict_and_find_startpage_multi:
xor   ax, ax ; set ah to 0. 
mov   bx, word ptr [bp - 2]
dec   bx
mov   cx, bx
sub   cl, dl
; dl is numpages
; bx is startpage
; cx is ((NUM_TEXTURE_L1_CACHE_PAGES-1)-numpages)

add   bx, OFFSET _spriteL1LRU 

find_start_page_loop_multi:

;		while (textureL1LRU[startpage] > ((NUM_TEXTURE_L1_CACHE_PAGES-1)-numpages)){
;			startpage--;
;		}

mov   al, byte ptr ds:[bx]
cmp   al, cl
jle   found_startpage_multi
dec   bx
jmp   find_start_page_loop_multi

found_start_page_single:

;		activetexturepages[startpage] = realtexpage; // FIRST_TEXTURE_LOGICAL_PAGE + pagenum;		
;  cl/cx is startpage
;  bl/bx is startpage 

pop   dx  ; bp - 6, get realtexpage
; dx has realtexpage
; bx already ok

mov   byte ptr ds:[bx + di], bh  ; zero
mov   byte ptr ds:[bx + si], dl
shl   bx, 1                      ; startpage word offset.
pop   ax                         ; mov   ax, word ptr [bp - 4]

add   ax, dx                     ; _EPR(pageoffset + realtexpage);
EPR_MACRO ax

; pageswapargs[pageswapargs_rend_texture_offset+(startpage)*PAGE_SWAP_ARG_MULT]

SHIFT_PAGESWAP_ARGS bx
mov   word ptr ds:[bx + _pageswapargs + (PAGESWAPARGS_SPRITECACHE_OFFSET * 2)], ax        ; = _EPR(pageoffset + realtexpage);

; dx should be realtexpage???
xchg  ax, dx

call  R_MarkL2SpriteCacheMRU_
call  Z_QuickMapSpritePage_

mov   ax, 0FFFFh

mov   dx, cx
do_sprite_eviction:

mov   word ptr ds:[_lastvisspritepatch], ax
mov   word ptr ds:[_lastvisspritepatch2], ax

mov   es, dx ; cl/cx is start page
LEAVE_MACRO 
POPA_NO_AX_MACRO
mov   ax, es
ret

found_startpage_multi:
;		startpage = textureL1LRU[startpage];

; al already set to startpage
mov   bx, ax    ; ah/bh is 0
push  ax  ; bp - 8
mov   dh, al ; dh gets startpage..
mov   cx, -1

;		// if the deallocated page was a multipage allocation then we want to invalidate the other pages.
;		if (activenumpages[startpage] > numpages) {
;			for (i = numpages; i <= activenumpages[startpage]; i++) {
;				activetexturepages[startpage + i] = -1;
;				// unmapping the page, so we dont need pagenum
;				pageswapargs[pageswapargs_rend_texture_offset+(startpage + i)*PAGE_SWAP_ARG_MULT] 
;					= _NPR(PAGE_5000_OFFSET+startpage+i); // unpaged
;				activenumpages[startpage + i] = 0;
;			}
;		}


cmp   dl, byte ptr ds:[bx + di]
jae   done_invalidating_pages_multi
mov   al, dl

; dl is numpages
; dh is startpage
; al is i
; ah is 0
; bx is startpage lookup

loop_next_invalidate_page_multi:
mov   bl, dh   ; set bl to startpage

cmp   al, byte ptr ds:[bx + di]
ja    done_invalidating_pages_multi

add   bx, ax                     ; startpage + i
mov   byte ptr ds:[bx + di], ah  ; ah is 0


; bx is currently startpage+i as a byte lookup
; _NPR(PAGE_5000_OFFSET+startpage+i);

; complicated because _NPR for scamp requires a calculation,
; for other chipsets its various constants.

IFDEF COMP_CH
    IF COMP_CH EQ CHIPSET_SCAT
        mov   byte ptr ds:[bx + si], cl  ; -1
        sal   bx, 1                      ; startpage word offset.
        SHIFT_PAGESWAP_ARGS bx
        mov   word ptr ds:[bx + _pageswapargs + (PAGESWAPARGS_SPRITECACHE_OFFSET * 2)], 03FFh
    ELSEIF COMP_CH EQ CHIPSET_SCAMP
        mov   byte ptr ds:[bx + si], cl  ; -1
        mov   cx, bx
        sal   bx, 1                      ; startpage word offset.
        add   cx, ((SCAMP_PAGE_9000_OFFSET + 4) - (010000h - PAGE_9000_OFFSET))   ; shut up compiler warning   ; page offset
        SHIFT_PAGESWAP_ARGS bx
        mov   word ptr ds:[bx + _pageswapargs + (PAGESWAPARGS_SPRITECACHE_OFFSET * 2)], cx
        mov   cx, -1
    ELSEIF COMP_CH EQ CHIPSET_HT18
        mov   byte ptr ds:[bx + si], cl  ; -1
        sal   bx, 1                      ; startpage word offset.
        SHIFT_PAGESWAP_ARGS bx
        mov   word ptr ds:[bx + _pageswapargs + (PAGESWAPARGS_SPRITECACHE_OFFSET * 2)], 0
    ENDIF
ELSE
    mov   byte ptr ds:[bx + si], cl  ; -1
    sal   bx, 1                      ; startpage word offset.
    SHIFT_PAGESWAP_ARGS bx
    mov   word ptr ds:[bx + _pageswapargs + (PAGESWAPARGS_SPRITECACHE_OFFSET * 2)], cx  ; cx is -1  TODO NPR or whatever

ENDIF

inc   al

xor   bh, bh
jmp   loop_next_invalidate_page_multi



done_invalidating_pages_multi:

;	int8_t currentpage = realtexpage; // pagenum - pageoffset
;	for (i = 0; i <= numpages; i++) {

mov   cl, dh  ; startpage
mov   ch, dl

; ch is numpages - i    (todo could be dl)
; cl has startpage + i

; dl still has numpages, decremented for loop
; dh has startpage


;	for (i = 0; i <= numpages; i++) {
; es gets currentpage
mov   es, word ptr [bp - 6]

;    for (i = 0; i <= numpages; i++) {
;        R_MarkL1TextureCacheMRU(startpage+i);
;        activetexturepages[startpage + i]  = currentpage;
;        activenumpages[startpage + i] = numpages-i;
;        pageswapargs[pageswapargs_rend_texture_offset+(startpage + i)*PAGE_SWAP_ARG_MULT]  = _EPR(currentpage+pageoffset);
;        currentpage = texturecache_nodes[currentpage].prev;
;    }


loop_mark_next_page_mru_multi:

;	R_MarkL1TextureCacheMRU(startpage+i);

mov   al, cl

call  R_MarkL1SpriteCacheMRU_  ; does not affect es


mov   ax, es ; currentpage in ax

mov   bl, cl
mov   byte ptr ds:[bx + di], ch   ;   activenumpages[startpage + i] = numpages-i;
mov   byte ptr ds:[bx + si], al   ;	activetexturepages[startpage + i]  = currentpage;
sal   bx, 1             ; word lookup

add   ax, word ptr [bp - 4]  ; pageoffset
EPR_MACRO ax

;	pageswapargs[pageswapargs_rend_texture_offset+(startpage + i)*PAGE_SWAP_ARG_MULT]  = _EPR(currentpage+pageoffset);

SHIFT_PAGESWAP_ARGS bx
mov   word ptr ds:[bx + _pageswapargs + (PAGESWAPARGS_SPRITECACHE_OFFSET * 2)], ax

dec   ch    ; dec numpages - i
inc   cl    ; inc startpage + i

;    currentpage = texturecache_nodes[currentpage].prev;
mov   bx, es ; currentpage
SHIFT_MACRO sal   bx 2
mov   bl, byte ptr ds:[bx + _spritecache_nodes]
xor   bh, bh
mov   es, bx
dec   dl
jns   loop_mark_next_page_mru_multi

;    R_MarkL2SpriteCacheMRU(realspritepage);
;    Z_QuickMapSpritePage();

mov   ax, word ptr [bp - 6]
call  R_MarkL2SpriteCacheMRU_
call  Z_QuickMapSpritePage_

;	//todo: detected and only do -1 if its in the knocked out page? pretty infrequent though.
;    cachedtex = -1;
;    cachedtex2 = -1;

mov   ax, 0FFFFh

mov   dl, dh  ; numpages in cl
jmp   do_sprite_eviction
ENDP


;void R_LoadSpriteColumns(uint16_t lump, segment_t destpatch_segment);
; ax = lump
; dx = segment

PROC R_LoadSpriteColumns_ NEAR

PUSHA_NO_AX_MACRO
push      bp
mov       bp, sp
mov       bx, ax

mov       di, dx    ; preserve dx thru quickmap
;call      Z_QuickMapScratch_5000_
Z_QUICKMAPAI4 pageswapargs_scratch5000_offset_size INDEXED_PAGE_5000_OFFSET

mov       dx, di

;	patch_t __far *wadpatch = (patch_t __far *)SCRATCH_ADDRESS_5000;
;	uint16_t __far * columnofs = (uint16_t __far *)&(destpatch->columnofs[0]);   // will be updated in place..

mov       di, SCRATCH_ADDRESS_5000_SEGMENT
mov       cx, di
mov       si, bx
mov       ax, si
xor       bx, bx
;	W_CacheLumpNumDirect(lump, SCRATCH_ADDRESS_5000);

;call      W_CacheLumpNumDirect_
call  dword ptr ds:[_W_CacheLumpNumDirect_addr]

; wadpatch  is 0x5000 seg
; destpatch is dx
;	patchwidth = wadpatch->width;
;	destpatch->width = wadpatch->width;
;	destpatch->height = wadpatch->height;
;	destpatch->leftoffset = wadpatch->leftoffset;
;	destpatch->topoffset = wadpatch->topoffset;

sub       si, word ptr ds:[_firstspritelump] ; get this before we clobber ds
mov       cx, si ; store in cx

mov       ds, di
xor       di, di
mov       si, di

mov       es, dx
lodsw
mov       word ptr cs:[SELFMODIFY_loadspritecolumn_width_check+1 - OFFSET R_MASK24_STARTMARKER_],  ax  ; patchwidth
stosw
movsw
movsw
movsw
mov       bx, ax ; patchwidth
mov       bp, di   ; bp gets 8


; 	destoffset = 8 + ( patchwidth << 2);
;	currentpostbyte = destoffset;
;	postdata = (uint16_t __far *)(((byte __far*)destpatch) + currentpostbyte);


SHIFT_MACRO shl       bx 2
mov       si, cx
shl       si, 1
add       bx, 8
;	destoffset += spritepostdatasizes[lump-firstspritelump];
mov       ax, SPRITEPOSTDATASIZES_SEGMENT
mov       es, ax

mov       di, bx
add       di, word ptr es:[si]
mov       es, dx  ; restore es
mov       dx, bp  ; dx starts as 8 for loop too

;	destoffset += (16 - ((destoffset &0xF)) &0xF); // round up so first pixel data starts aligned of course.
;	currentpixelbyte = destoffset;
;	pixeldataoffset = (byte __far *)MK_FP(destpatch_segment, currentpixelbyte);

add       di, 15
and       di, 0FFF0h

start_sprite_column_loop:
xor       cx, cx
do_next_sprite_column:
dec       word ptr cs:[SELFMODIFY_loadspritecolumn_width_check+1 - OFFSET R_MASK24_STARTMARKER_]

mov       ax, di

SHIFT_MACRO shr       ax 4
mov       si, dx
mov       si, word ptr ds:[si]


mov       word ptr es:[bp], ax
mov       word ptr es:[bp+2], bx
add       bp, 4


lodsw
cmp       al, 0FFh
je        done_with_sprite_column

do_next_sprite_post:

mov       word ptr es:[bx], ax
mov       cl, ah
mov       ax, cx
inc       si

shr       cx, 1
rep movsw 
adc       cx, cx
rep movsb 

add       di, 15
and       di, 0FFF0h  ; round up to next segment destination

; column = (column_t __far *)(  ((byte  __far*)column) + column->length + 4 );

inc       si
inc       bx
inc       bx

lodsw
cmp       al, 0FFh
jne       do_next_sprite_post
done_with_sprite_column:

mov       word ptr es:[bx], 0FFFFh
add       dx, 4
inc       bx
inc       bx


SELFMODIFY_loadspritecolumn_width_check:
mov       ax, 01000h
test      ax, ax
jne       do_next_sprite_column


done_with_sprite_column_loop:

mov       ax, ss  ; restore ds
mov       ds, ax
pop       bp 

;call      Z_QuickMapRender5000_
Z_QUICKMAPAI4 (pageswapargs_rend_offset_size+4) INDEXED_PAGE_5000_OFFSET

POPA_NO_AX_MACRO
ret      


ENDP



IF COMPISA GE COMPILE_386

    PROC FastDiv3232FFFF_ NEAR

    ; EDX:EAX as 00000000 FFFFFFFF

    db 066h, 031h, 0C0h              ; xor eax, eax
    db 066h, 099h                    ; cdq
    db 066h, 048h                    ; dec eax


    ; set up ecx
    db 066h, 0C1h, 0E3h, 010h        ; shl  ebx, 0x10
    db 066h, 00Fh, 0A4h, 0D9h, 010h  ; shld ecx, ebx, 0x10

    ; divide
    db 066h, 0F7h, 0F1h              ; div ecx

    ; set up return
    db 066h, 00Fh, 0A4h, 0C2h, 010h  ; shld edx, eax, 0x10
    ret

    ENDP

ELSE

    fast_div_32_16_FFFF:

    xchg dx, cx   ; cx was 0, dx is FFFF
    div bx        ; after this dx stores remainder, ax stores q1
    xchg cx, ax   ; q1 to cx, ffff to ax  so div remaidner:ffff 
    div bx
    mov dx, cx   ; q1:q0 is dx:ax
    ret


    ; NOTE: this may not work right for negative params or DX:AX  besides 0xFFFFFFFF
    ; TODO: We only use the low 24 bits of output from this function. can we optimize..?
    ;FastDiv3232FFFF_
    ; DX:AX / CX:BX

    PROC FastDiv3232FFFF_ NEAR



    ; if top 16 bits missing just do a 32 / 16
    mov  ax, -1
    cwd

    test cx, cx
    je fast_div_32_16_FFFF

    main_3232_div:

    push  si
    push  di



    XOR SI, SI ; zero this out to get high bits of numhi




    test ch, ch
    jne shift_bits_3232
    ; shift a whole byte immediately

    mov ch, cl
    mov cl, bh
    mov bh, bl
    xor bl, bl

    ; dont need a full shift 8 because we know everything is FF
    mov  si, 000FFh
    xor al, al

    shift_bits_3232:

    ; less than a byte to shift
    ; shift until MSB is 1
    ; DX gets 1s so we can skip it.

    SAL BX, 1
    RCL CX, 1
    JC done_shifting_3232  
    SAL AX, 1
    RCL SI, 1

    SAL BX, 1
    RCL CX, 1
    JC done_shifting_3232
    SAL AX, 1
    RCL SI, 1

    SAL BX, 1
    RCL CX, 1
    JC done_shifting_3232
    SAL AX, 1
    RCL SI, 1

    SAL BX, 1
    RCL CX, 1
    JC done_shifting_3232
    SAL AX, 1
    RCL SI, 1

    SAL BX, 1
    RCL CX, 1
    JC done_shifting_3232
    SAL AX, 1
    RCL SI, 1

    SAL BX, 1
    RCL CX, 1
    JC done_shifting_3232
    SAL AX, 1
    RCL SI, 1

    SAL BX, 1
    RCL CX, 1
    JC done_shifting_3232
    SAL AX, 1
    RCL SI, 1

    SAL BX, 1
    RCL CX, 1



    ; store this
    done_shifting_3232:

    ; we overshifted by one and caught it in the carry bit. lets shift back right one.

    RCR CX, 1
    RCR BX, 1


    ; SI:DX:AX holds divisor...
    ; CX:BX holds dividend...
    ; numhi = SI:DX
    ; numlo = AX:00...


    ; save numlo word in sp.
    ; avoid going to memory... lets do interrupt magic
    mov di, ax


    ; set up first div. 
    ; dx:ax becomes numhi
    mov   ax, dx
    mov   dx, si    

    ; store these two long term...
    mov   si, bx



    ; numhi is 00:SI in this case?

    ;	divresult.wu = DIV3216RESULTREMAINDER(numhi.wu, den1);
    ; DX:AX = numhi.wu


    div   cx

    ; rhat = dx
    ; qhat = ax
    ;    c1 = FastMul16u16u(qhat , den0);

    mov   bx, dx					; bx stores rhat
    mov   es, ax     ; store qhat

    mul   si   						; DX:AX = c1


    ; c1 hi = dx, c2 lo = bx
    cmp   dx, bx

    ja    check_c1_c2_diff_3232
    jne   q1_ready_3232
    cmp   ax, di
    jbe   q1_ready_3232
    check_c1_c2_diff_3232:

    ; (c1 - c2.wu > den.wu)

    sub   ax, di
    sbb   dx, bx
    cmp   dx, cx
    ja    qhat_subtract_2_3232
    je    compare_low_word_3232

    qhat_subtract_1_3232:
    mov ax, es
    dec ax
    xor dx, dx

    pop   di
    pop   si
    ret

    compare_low_word_3232:
    cmp   ax, si
    jbe   qhat_subtract_1_3232

    ; ugly but rare occurrence i think?
    qhat_subtract_2_3232:
    mov ax, es
    dec ax
    dec ax

    pop   di
    pop   si
    ret  






    q1_ready_3232:

    mov  ax, es
    xor  dx, dx;

    pop   di
    pop   si
    ret


    ENDP

ENDIF






;R_PointOnSegSide_

PROC R_PointOnSegSide_ NEAR

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


mov   di, word ptr ds:[_segs_render + si + SEG_RENDER_T.sr_v1Offset]
mov   es, word ptr ds:[_VERTEXES_SEGMENT_PTR]

; todo lodsw chain?
mov   bx, word ptr es:[di]      ; lx
mov   ax, word ptr es:[di + 2]  ; ly


mov   di, word ptr ds:[_segs_render + si + SEG_RENDER_T.sr_v2Offset]

;mov   es, ax  ; juggle ax around isntead of putting on stack...


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
;call FixedMul1632MaskedLocal_
  MOV ES, CX
  MOV CX, AX
  MUL BX
  XCHG AX, DX
  XCHG AX, CX
  CWD
  AND BX, DX
  MOV DX, ES
  IMUL DX
  SUB CX, BX
  SBB BX, BX
  ADD AX, CX
  ADC DX, BX



; set up params..
pop   bx
mov   cx, di
push  ax
mov   ax, si
mov   di, dx

;call FixedMul1632MaskedLocal_
  MOV ES, CX
  MOV CX, AX
  MUL BX
  XCHG AX, DX
  XCHG AX, CX
  CWD
  AND BX, DX
  MOV DX, ES
  IMUL DX
  SUB CX, BX
  SBB BX, BX
  ADD AX, CX
  ADC DX, BX


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

; todo feels improvable without too many outside deps

SIL_NONE =   0
SIL_BOTTOM = 1
SIL_TOP =    2
SIL_BOTH =   3

; todo: only push bx?

PROC R_DrawSprite_ NEAR

; bp - 2	   ds_p segment. TODO always DRAWSEGS_BASE_SEGMENT
; bp - 4       vissprite near pointer

push  bp
mov   bp, sp
; bx is already the sprite
mov   dx, DRAWSEGS_BASE_SEGMENT
push  dx        ; bp - 2
push  bx        ; bp - 4h   ; bx is already vissprite

les   si, dword ptr ds:[bx + VISSPRITE_T.vs_x1]
mov   cx, es   ; ;  x2
cmp   si, cx
jg    no_clip   ; todo fall thru in which case is better?


;	for (x = spr->x1; x <= spr->x2; x++) {
;		clipbot[x] = cliptop[x] = -2;
;	}
    
; init clipbot, cliptop

inc   cx				     ; for the equals case.
sub   cx, si   				 ; minus spr->x1
shl   si, 1                  ; si 
lea   di, [si + CLIPTOP_START_OFFSET]
mov   ax, cs
mov   es, ax
push  cx                 ; backup for iter 2
mov   ax, UNCLIPPED_COLUMN             ; -2
rep   stosw
lea   di, [si + CLIPBOT_START_OFFSET]
pop   cx                 ; restore for iter 2
rep   stosw


no_clip:

; di equals ds_p offset
mov   di, word ptr ds:[_ds_p]
sub   di, SIZE DRAWSEG_T	
jz   done_masking  ; no drawsegs! i suppose possible on a map edge.
mov   es, dx   ; DRAWSEGS_BASE_SEGMENT from above
check_loop_conditions:

; compare ds->x1 > spr->x2
mov   ax, word ptr es:[di + DRAWSEG_T.drawseg_x1]
cmp   ax, word ptr ds:[bx + VISSPRITE_T.vs_x2]
jng   continue_checking_if_drawseg_obscures_sprite
iterate_next_drawseg_loop:
; note: es and bx dont necessaryly go together.
; es is paired with di and ds with bx.
les   bx, dword ptr [bp - 4] 
iterate_next_drawseg_loop_dont_restore_esbx:
sub   di, SIZE DRAWSEG_T   
jnz   check_loop_conditions
done_masking:
; check for unclipped columns
push  bx  ; cache vissprite pointer bp - 6
les   si, dword ptr ds:[bx + VISSPRITE_T.vs_x1]
mov   cx, es 
sub   cx, si
jl    draw_the_vissprite
inc   cx
shl   si, 1
add   si, CLIPBOT_START_OFFSET
mov   bx, (SCREENWIDTH * 2)

push  cs
pop   ds

SELFMODIFY_MASKED_viewheight_2:
mov   ax, 01000h
mov   dx, UNCLIPPED_COLUMN
; ds is cs here

loop_clipping_columns:
cmp   word ptr ds:[si], dx ; UNCLIPPED_COLUMN -2
jne   dont_clip_bot
mov   word ptr ds:[si], ax
dont_clip_bot:
cmp   word ptr ds:[si+bx], dx ; UNCLIPPED_COLUMN -2
jne   dont_clip_top
mov   word ptr ds:[si+bx], 0FFFFh
dont_clip_top:
sub   si, dx ; add 2 by sub -2
loop loop_clipping_columns

push  ss
pop   ds


draw_the_vissprite:
; could also be the segments and not the offsets.
mov   word ptr ds:[_mfloorclip], CLIPBOT_START_OFFSET
mov   word ptr ds:[_mfloorclip + 2], cs

mov   word ptr ds:[_mceilingclip], CLIPTOP_START_OFFSET
mov   word ptr ds:[_mceilingclip + 2], cs
pop   si      ; vissprite pointer from above bp - 6
call  R_DrawVisSprite_
mov   word ptr ds:[_mceilingclip + 2], OPENINGS_SEGMENT
mov   word ptr ds:[_mfloorclip + 2], OPENINGS_SEGMENT

pop  bx ; restore bx
pop  es ; garbage pop
LEAVE_MACRO

ret   
continue_checking_if_drawseg_obscures_sprite:
; compare (ds->x2 < spr->x1)
mov   ax, word ptr es:[di + DRAWSEG_T.drawseg_x2]
cmp   ax, word ptr ds:[bx + VISSPRITE_T.vs_x1]
jl    iterate_next_drawseg_loop_dont_restore_esbx
;  (!ds->silhouette     && ds->maskedtexturecol_val == NULL_TEX_COL) ) {
cmp   byte ptr es:[di + DRAWSEG_T.drawseg_silhouette], 0    ; TODO constants..
jne   check_drawseg_scales
cmp   word ptr es:[di + DRAWSEG_T.drawseg_maskedtexturecol_val], NULL_TEX_COL
je    iterate_next_drawseg_loop_dont_restore_esbx
check_drawseg_scales:

;		if (ds->scale1 > ds->scale2) {

;ax:dx = scale1. we will keep this throughout the scalecheckpass logic.
;cx:si = scale2  we will also keep this throughout the scalecheckpass logic.

mov   dx, word ptr es:[di + DRAWSEG_T.drawseg_scale1 + 0]
mov   ax, word ptr es:[di + DRAWSEG_T.drawseg_scale1 + 2]
mov   si, word ptr es:[di + DRAWSEG_T.drawseg_scale2 + 0]
mov   cx, word ptr es:[di + DRAWSEG_T.drawseg_scale2 + 2]
cmp   ax, cx
jg    scale1_highbits_larger_than_scale2
je    scale1_highbits_equal_to_scale2

scale1_smaller_than_scale2:

;lowscalecheckpass = ds->scale1 < spr->scale;
; ax:dx is ds->scale2

cmp   cx, word ptr ds:[bx + VISSPRITE_T.vs_scale + 2]
jl    set_r1_r2_and_render_masked_set_range
jne   lowscalecheckpass_set_route2
cmp   si, word ptr ds:[bx + VISSPRITE_T.vs_scale + 0]
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

cmp   ax, word ptr ds:[bx + VISSPRITE_T.vs_scale + 2]
jl    set_r1_r2_and_render_masked_set_range
jne   get_lowscalepass_1
cmp   dx, word ptr ds:[bx + VISSPRITE_T.vs_scale + 0]
jae   get_lowscalepass_1

;     scalecheckpass 1, fail early

set_r1_r2_and_render_masked_set_range:
;	if (ds->maskedtexturecol_val != NULL_TEX_COL) {
 
cmp   word ptr es:[di + DRAWSEG_T.drawseg_maskedtexturecol_val], NULL_TEX_COL
; continue
je    jump_to_iterate_next_drawseg_loop
;  r1 = ds->x1 < spr->x1 ? spr->x1 : ds->x1;
;  set r1 to the greater of the two.
mov   ax, word ptr es:[di + DRAWSEG_T.drawseg_x1] ; ds->x1
cmp   ax, word ptr ds:[bx + VISSPRITE_T.vs_x1]
jge   r1_stays_ds_x1
mov   ax, word ptr ds:[bx + VISSPRITE_T.vs_x1]   ; spr->x1
r1_stays_ds_x1:

; r2 = ds->x2 > spr->x2 ? spr->x2 : ds->x2;
; set r2 as the minimum of the two.
mov   cx, word ptr ds:[bx + VISSPRITE_T.vs_x2]    ; spr->x2
cmp   cx, word ptr es:[di + DRAWSEG_T.drawseg_x2]
jle   r2_stays_ds_x2

mov   cx, word ptr es:[di + DRAWSEG_T.drawseg_x2] ; ds->x2

r2_stays_ds_x2:



call  R_RenderMaskedSegRange_
jmp   iterate_next_drawseg_loop
get_lowscalepass_1:

;			lowscalecheckpass = ds->scale2 < spr->scale;

;dx:bx = ds->scale2

cmp   cx, word ptr ds:[bx + VISSPRITE_T.vs_scale + 2]
jl    do_R_PointOnSegSide_check
jne   failed_check_pass_set_r1_r2
cmp   si, word ptr ds:[bx + VISSPRITE_T.vs_scale + 0]
jae   failed_check_pass_set_r1_r2

jmp   do_R_PointOnSegSide_check
jump_to_iterate_next_drawseg_loop:
jmp   iterate_next_drawseg_loop_dont_restore_esbx




lowscalecheckpass_set_route2:
;scalecheckpass = ds->scale2 < spr->scale;
; ax:dx is still ds->scale1


cmp   ax, word ptr ds:[bx + VISSPRITE_T.vs_scale + 2]
jl    do_R_PointOnSegSide_check
jne   failed_check_pass_set_r1_r2
cmp   dx, word ptr ds:[bx + VISSPRITE_T.vs_scale + 0]
jae   failed_check_pass_set_r1_r2

do_R_PointOnSegSide_check:


mov   si, word ptr es:[di + DRAWSEG_T.drawseg_cursegvalue]
les   ax, dword ptr ds:[bx + VISSPRITE_T.vs_gx]
mov   dx, es
les   bx, dword ptr ds:[bx + VISSPRITE_T.vs_gy]
mov   cx, es

; todo this is the only place calling this? make sense to inline?
call  R_PointOnSegSide_   ; todo return in carry?
test  ax, ax
les   bx, dword ptr [bp - 4] 

je   set_r1_r2_and_render_masked_set_range

failed_check_pass_set_r1_r2:

;		r1 = ds->x1 < spr->x1 ? spr->x1 : ds->x1;


mov   si, word ptr es:[di + DRAWSEG_T.drawseg_x1]  ; spr->x1
cmp   si, word ptr ds:[bx + VISSPRITE_T.vs_x1]
jnl   r1_set

spr_x1_smaller_than_ds_x1:
mov   si, word ptr ds:[bx +  VISSPRITE_T.vs_x1]
r1_set:

;		r2 = ds->x2 > spr->x2 ? spr->x2 : ds->x2;

mov   cx, word ptr es:[di + DRAWSEG_T.drawseg_x2]	; spr->x2
cmp   cx, word ptr ds:[bx + VISSPRITE_T.vs_x2]		; ds->x2
jng   r2_set


spr_x2_greater_than_dx_x2:
mov   cx, word ptr ds:[bx +  VISSPRITE_T.vs_x2]
r2_set:

; si is r1 and cx is r2
; bx is vissprite
; es:di is drawseg
; so only ax and cx are free.
; lets precalculate the loop count into cx, freeing up dx.

sub   cx, si
jl    jump_to_iterate_next_drawseg_loop
inc   cx  ; cx is now count! dont modify



;        silhouette = ds->silhouette;
;    	SET_FIXED_UNION_FROM_SHORT_HEIGHT(temp, ds->bsilheight);

mov   al, byte ptr es:[di + DRAWSEG_T.drawseg_silhouette]
mov   byte ptr cs:[SELFMODIFY_MASKED_set_al_to_silhouette+1 - OFFSET R_MASK24_STARTMARKER_],  al

; todo could these be preshifted?

mov   ax, word ptr es:[di + DRAWSEG_T.drawseg_bsilheight]
xor   dx, dx
sar   ax, 1
rcr   dx, 1
sar   ax, 1
rcr   dx, 1
sar   ax, 1
rcr   dx, 1

;ax:dx = temp
cmp   ax, word ptr ds:[bx + VISSPRITE_T.vs_gz + 2]

;		if (spr->gz.w >= temp.w) {
;			silhouette &= ~SIL_BOTTOM;
;		}

jl    remove_bot_silhouette
jg    do_not_remove_bot_silhouette
cmp   dx, word ptr ds:[bx + VISSPRITE_T.vs_gz + 0]
ja    do_not_remove_bot_silhouette
remove_bot_silhouette:
and   byte ptr cs:[SELFMODIFY_MASKED_set_al_to_silhouette+1 - OFFSET R_MASK24_STARTMARKER_], 0FEh  
do_not_remove_bot_silhouette:

mov   ax, word ptr es:[di + DRAWSEG_T.drawseg_tsilheight]
xor   dx, dx
sar   ax, 1
rcr   dx, 1
sar   ax, 1
rcr   dx, 1
sar   ax, 1
rcr   dx, 1

;dx:ax = temp

;		if (spr->gzt.w <= temp.w) {
;			silhouette &= ~SIL_TOP;
;		}

cmp   ax, word ptr ds:[bx + VISSPRITE_T.vs_gzt + 2]
mov   ah,  0FFh		; for later and
jg    remove_top_silhouette
jl    do_not_remove_top_silhouette
cmp   dx, word ptr ds:[bx + VISSPRITE_T.vs_gzt + 0]

jb    do_not_remove_top_silhouette
remove_top_silhouette:

; ok. this is too close to the following instruction to and to 0FD so instead, 
; we put the value to AND into ah.
mov   ah,  0FDh  ; ~SIL_TOP

do_not_remove_top_silhouette:


shl   si, 1

; si is r1 and cx is count
; bx is near vissprite
; es:di is drawseg


SELFMODIFY_MASKED_set_al_to_silhouette:
mov   al, 0FFh ; this gets selfmodified
and   al, ah   ; second AND is applied 
je    silhouette_is_SIL_NONE ; quit early

cmp   al, SIL_TOP  ; al is 0 1 2 or 3. 2 = sil_top
les   ax, dword ptr es:[di + DRAWSEG_T.drawseg_sprtopclip_offset]
mov   bx, es ; top
mov   dx, OPENINGS_SEGMENT
mov   es, dx
mov   dx, CLIPBOT_START_SEGMENT
mov   ds, dx  ; ds gets cs to index clipbot
mov   dx, UNCLIPPED_COLUMN
je    silhouette_is_SIL_TOP
ja    silhouette_is_SIL_BOTH

silhouette_is_SIL_BOTTOM:

; bx already right

silhouette_SIL_BOTTOM_loop:
cmp   word ptr ds:[si], dx ; UNCLIPPED_COLUMN or -2
jne   increment_silhouette_SIL_BOTTOM_loop

push  word ptr es:[bx+si]
pop   word ptr ds:[si]
increment_silhouette_SIL_BOTTOM_loop:
sub   si, dx ; add 2 by sub -2
loop   silhouette_SIL_BOTTOM_loop
mov   cx, ss
mov   ds, cx
jmp   iterate_next_drawseg_loop  ;todo change the flow to go to the other jump


silhouette_is_SIL_TOP:

xchg  ax, bx   ; get botclip in bx
add   si, SCREENWIDTH * 2 ; CLIPTOP_START_OFFSET
sub   bx, SCREENWIDTH * 2  ; to cancel bx + si case to offset the above

silhouette_2_loop:
cmp   word ptr ds:[si], dx ; UNCLIPPED_COLUMN or -2
jne   increment_silhouette_2_loop

push  word ptr es:[bx+si]
pop   word ptr ds:[si]
increment_silhouette_2_loop:
sub   si, dx ; add 2 by sub -2
loop  silhouette_2_loop
silhouette_is_SIL_NONE:
mov   cx, ss
mov   ds, cx
jmp   iterate_next_drawseg_loop  ;todo change the flow to go to the other jump


silhouette_is_SIL_BOTH:

; ax/bx already set

xchg  ax, bp  ; ; use bp for bp + si pattern

silhouette_SIL_BOTH_loop:

cmp   word ptr ds:[si], dx ; UNCLIPPED_COLUMN or -2
jne   do_next_silhouette_SIL_BOTH_subloop

push  word ptr es:[bx+si]
pop   word ptr ds:[si]
do_next_silhouette_SIL_BOTH_subloop:
cmp   word ptr ds:[si + (SCREENWIDTH * 2)], dx ; UNCLIPPED_COLUMN or -2
jne   increment_silhouette_SIL_BOTH_loop


push  word ptr es:[bp+si]
pop   word ptr ds:[si + (SCREENWIDTH * 2)]


increment_silhouette_SIL_BOTH_loop:

sub   si, dx ; add 2 by sub -2
loop  silhouette_SIL_BOTH_loop
xchg  ax, bp  ; restore bp


mov   cx, ss
mov   ds, cx
jmp   iterate_next_drawseg_loop


ENDP

VISSPRITE_SORTED_HEAD_INDEX = 0FEh

PROC R_DrawMasked24_ FAR
PUBLIC R_DrawMasked24_

PUSHA_NO_AX_OR_BP_MACRO

call R_SortVisSprites_

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
mov  ah, (SIZE VISSPRITE_T)
mul  ah
add  ax, OFFSET _vissprites
mov  bx, ax  ; bx gets this for the call
call R_DrawSprite_
mov  al, byte ptr ds:[bx]


cmp  al, VISSPRITE_SORTED_HEAD_INDEX
jne  draw_next_sprite
done_drawing_sprites:

les  di, dword ptr ds:[_ds_p]

sub  di, (SIZE DRAWSEG_T)

jle  done_rendering_masked_segranges

check_next_seg:
cmp  word ptr es:[di + DRAWSEG_T.drawseg_maskedtexturecol_val], NULL_TEX_COL
je   not_masked

mov  ax, word ptr es:[di + 2]
mov  cx, word ptr es:[di + 4]

call R_RenderMaskedSegRange_
mov  es, word ptr ds:[_ds_p + 2]
not_masked:
sub  di, (SIZE DRAWSEG_T)

ja   check_next_seg
done_rendering_masked_segranges:
call R_DrawPlayerSprites_
exit_draw_masked:
POPA_NO_AX_OR_BP_MACRO
retf

ENDP




; ax pixelsegment
; cx:bx column
; todo: use es:bx instead of cx.

;
; R_DrawMaskedColumn
;
	
PROC   R_DrawMaskedColumn_ NEAR
PUBLIC R_DrawMaskedColumn_
;  bp - 02 cx/maskedcolumn segment
;  bp - 04  ax/pixelsegment cache
;  bp - 06  cached dc_texturemid intbits to restore before function

; todo: synergy with outer function... cx and es
; todo dont create stack frame

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

xor   cx, cx
mov   cl, byte ptr es:[si]   ; todo use ds and lodsb pattern...?

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
mov   cl, 010h;  dc_texturemid intbits
les   ax, dword ptr [bp - 4]        ; es gets texture segment
add   ax, bx
mov   word ptr ds:[_dc_source_segment], ax
sub   cl, byte ptr es:[si]          ; subtract tex top offset
; dl = dc_texturemid hi. carry this into the call
; dont set dc_texturemid lo till inside call


call  R_DrawColumnPrepMaskedMulti_   ;todo inline?

increment_column_and_continue_loop:
mov   es, word ptr [bp-2]
mov   al, byte ptr es:[si + 1] ; get patch height again. todo add this earlier?
xor   ah, ah

add   di, ax
neg   al
and   al, 0Fh
add   di, ax    ; round up segment.

add   si, 2     ; todo bench inc si inc si
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




loop_below_zero_subtractor_masked:
;	textotal += subtractor; // add the last's total.

add       di, ax
jmp       done_with_loop_check_subtractor_maksed

lump_below_zero_masked:

;	maskedcachedbasecol = runningbasetotal - textotal;

mov       bx, dx
sub       bx, di
jmp       done_with_loop_check_masked

PROC R_GetMaskedColumnSegment_ NEAR

;  bp - 2      ; tex (orig ax)
;  bp - 4      ; texcol. maybe ok to remain here.
;  bp - 6      ; loopwidth
;  bp - 8      ; basecol

push      bx
push      cx
push      si
push      di
push      bp
mov       bp, sp
push      ax        ; tex bp - 2
xchg      ax, di
;	maskedheaderpixeolfs = 0xFFFF;

mov       word ptr ds:[_maskedheaderpixeolfs], 0FFFFh

	
;	col &= texturewidthmasks[tex];

mov       ax, TEXTUREWIDTHMASKS_SEGMENT
mov       es, ax
xor       dh, dh
mov       cx, dx
and       cl, byte ptr es:[di] ; di is tex

;	basecol -= col;
sub       dx, cx

;	texcol = col;
push      cx  ; bp - 4

sal       di, 1

;	texturecolumnlump = &(texturecolumnlumps_bytes_7000[texturepatchlump_offset[tex]]);

mov       bx, word ptr ds:[di + _texturepatchlump_offset]
sal       bx, 1 ; bx is  texturecolumnlump ptr

;	loopwidth = texturecolumnlump[1].bu.bytehigh;


mov       ax, TEXTURECOLUMNLUMPS_BYTES_SEGMENT
mov       es, ax
mov       al, byte ptr es:[bx + 3]
xor       ah, ah
push      ax  ; bp - 6 ; loopwidth


test      al, al
je       loopwidth_zero_masked

loopwidth_nonzero_masked:
; di is tex shifted left 1?
; es:bx is texcollump


;	lump = texturecolumnlump[0].h;
;    maskedcachedbasecol  = basecol;
;    maskedtexrepeat	 	 = loopwidth;

mov       si, word ptr es:[bx]
mov       word ptr ds:[_maskedcachedbasecol], dx ; basecol
mov       word ptr ds:[_maskedtexrepeat], ax  ; loopwidth
jmp       done_with_loopwidth_masked

loopwidth_zero_masked:
xor       di, di   ; textotal

;		uint8_t startpixel;
;		int16_t subtractor;
;		int16_t textotal = 0;
;		int16_t runningbasetotal = basecol;
;		int16_t n = 0;


push      dx  ; bp - 8, basecol

; ax is subtractor      
; bx is loop iter        
; cx is col 
; dx is runningbasetotal
; bp - 4 is texcol
; si is lump
; di is textotal


;    while (col >= 0) {
;        subtractor = texturecolumnlump[n+1].bu.bytelow + 1;
;        runningbasetotal += subtractor;
;        lump = texturecolumnlump[n].h;
;        col -= subtractor;
;        if (lump >= 0){ // should be equiv to == -1?
;            texcol -= subtractor; // is this correct or does it have to be bytelow direct?
;        } else {
;            textotal += subtractor; // add the last's total.
;        }
;        n += 2;
;    }

;    while (col >= 0) {
test      cx, cx
jl        done_with_subtractor_loop_masked

do_next_subtractor_loop_masked:

;			subtractor = texturecolumnlump[n+1].bu.bytelow + 1;

;todo lodsw and swap bx/si
xor       ax, ax
mov       al, byte ptr es:[bx + 2]
inc       ax                     ; subtractor = texturecolumnlump[n+1].bu.bytelow + 1;
mov       si, word ptr es:[bx]   ; lump = texturecolumnlump[n].h;
add       dx, ax                 ; runningbasetotal += subtractor;
sub       cx, ax                 ; col -= subtractor;
test      si, si
jnge      loop_below_zero_subtractor_masked

;				texcol -= subtractor; // is this correct or does it have to be bytelow direct?
sub       byte ptr [bp - 4], al
done_with_loop_check_subtractor_maksed:
add       bx, 4
test      cx, cx
jge       do_next_subtractor_loop_masked
done_with_subtractor_loop_masked:

;		maskednextlookup     = runningbasetotal; 

mov       word ptr ds:[_maskednextlookup], dx 

test      si, si
jng       lump_below_zero_masked

;    startpixel = texturecolumnlump[n-1].bu.bytehigh;
mov       bl, byte ptr es:[bx - 1]  ; startpixel
xor       bh, bh
;    maskedcachedbasecol = basecol + startpixel;
add       bx, word ptr [bp - 8]   ; basecol
done_with_loop_check_masked:
; undo bp - 8/ basecol
inc       sp
inc       sp

; cx is now col
; bx is _maskedcachedbasecol
; dx is runningbasetotal
; ax is subtractor
; di is textotal
; si is lump

;		maskedprevlookup     = runningbasetotal - subtractor;
mov       word ptr ds:[_maskedcachedbasecol], bx
sub       dx, ax
mov       word ptr ds:[_maskedprevlookup], dx  ;	maskedprevlookup     = runningbasetotal - subtractor;
mov       word ptr ds:[_maskedtexrepeat], 0
done_with_loopwidth_masked:

;	if (lump > 0){

mov       di, word ptr [bp - 2]
test      si, si
jg        lump_greater_than_zero_masked
jmp       no_lump_do_texture

not_cache_0_masked:
;    segment_t usedsegment = cachedsegmentlumps[cachelumpindex];
;    int16_t cachedlump = cachedlumps[cachelumpindex];
;    int16_t i;



xchg      ax, si
mov       di, OFFSET _cachedsegmentlumps
mov       si, OFFSET _cachedlumps
push      word ptr ds:[bx + di]
push      word ptr ds:[bx + si]


;    // reorder cache MRU				
;    for (i = cachelumpindex; i > 0; i--){
;        cachedsegmentlumps[i] = cachedsegmentlumps[i-1];
;        cachedlumps[i] = cachedlumps[i-1];
;    }
loop_move_cachelump_masked:
sub       bx, 2
push      word ptr ds:[bx + di]
push      word ptr ds:[bx + si]
pop       word ptr ds:[bx + si + 2]
pop       word ptr ds:[bx + di + 2]
jg        loop_move_cachelump_masked
done_moving_cachelumps_masked:



;    cachedsegmentlumps[0] = usedsegment;
;    cachedlumps[0] = cachedlump;
;    goto foundcachedlump;	
pop       word ptr ds:[si]
pop       word ptr ds:[di]
xchg      ax, si ; restore lump

jmp       found_cached_lump_masked_set_di

lump_greater_than_zero_masked:
; di is bp - 2

;	uint8_t lookup = masked_lookup_7000[tex];
;mov       ax, MASKED_LOOKUP_SEGMENT
;mov       es, ax
mov       dl, byte ptr es:[di + ((MASKED_LOOKUP_SEGMENT - TEXTURECOLUMNLUMPS_BYTES_SEGMENT) * 16)]
;mov       ax, PATCHHEIGHTS_SEGMENT
;mov       es, ax

;    uint8_t heightval = patchheights_7000[lump-firstpatch];
mov       bx, si                        ; bx is lump-firstpatch lookup
sub       bx, word ptr ds:[_firstpatch] ; hardcode?
mov       al, byte ptr es:[bx + ((PATCHHEIGHTS_SEGMENT - TEXTURECOLUMNLUMPS_BYTES_SEGMENT) * 16)]


;	cachedbyteheight = heightval & 0xF0;
;	heightval &= 0x0F;

mov       ah, al
and       ax, 0F00Fh        ; ah is cachedbyteheight, al is heightval
mov       dh, al
; dx stores heightval high (dh), lookup low (dl)

mov       byte ptr ds:[_cachedbyteheight], ah
xor       bx, bx


;	for (cachelumpindex = 0; cachelumpindex < NUM_CACHE_LUMPS; cachelumpindex++){

;	if (lump == cachedlumps[cachelumpindex]){
cmp       si, word ptr ds:[_cachedlumps]
je        cachedlumphit_masked
loop_check_next_cached_lump_masked:

inc       bx
inc       bx
cmp       bx, (NUM_CACHE_LUMPS * 2)
jge       cache_miss_move_all_cache_back_masked
cmp       si, word ptr ds:[bx + _cachedlumps]
jne       loop_check_next_cached_lump_masked

;    if (cachelumpindex == 0){ // todo move this out? or unloop it?
cachedlumphit_masked:
test      bx, bx
jne       not_cache_0_masked

found_cached_lump_masked_set_di:
mov       di, dx  ; store the two values in di
found_cached_lump_masked:   ; di was already dx
; di has the 2 values now
;	if (col < 0){
test      cx, cx



jnl       col_not_under_zero_masked



;    uint16_t patchwidth = patchwidths_7000[lump-firstpatch];
;    if (patchwidth == 0){
;        patchwidth = 0x100;
;    }

mov       ax, PATCHWIDTHS_SEGMENT
mov       es, ax
sub       si, word ptr ds:[_firstpatch]
xor       ax, ax
mov       al, byte ptr es:[si]
cwd       ; zero out dh especially
cmp       al, 1     ; set carry if al is 0
adc       ah, ah    ; if width is zero that encoded 0x100. now ah is 1.

;    if (patchwidth > texturewidthmasks[tex]){
;        patchwidth = texturewidthmasks[tex];
;        patchwidth++;
;    }


mov       bx, TEXTUREWIDTHMASKS_SEGMENT
mov       es, bx
mov       bx, word ptr [bp - 2]
mov       dl, byte ptr es:[bx]      ; dh 0 from above cwd
cmp       ax, dx
jna       negative_modulo_thing_masked
xchg      ax, dx
inc       ax

;    while (col < 0){
;        col+= patchwidth;
;    }
negative_modulo_thing_masked:
add       cx, ax
jl        negative_modulo_thing_masked

col_not_under_zero_masked:

;		maskedcachedsegment  = cachedsegmentlumps[0];

push      word ptr ds:[_cachedsegmentlumps]
pop       word ptr ds:[_maskedcachedsegment]

xchg      ax, di  ;lookup low, heighval height  ; herehere
cmp       al, 0FFh
jne       is_masked
; weird reverse walls like e1m1 sewage room

;    maskedheightvalcache  = heightval;

mov       al, ah
mov       byte ptr ds:[_maskedheightvalcache], al
;    return maskedcachedsegment + (FastMul8u8u(col , heightval) );
mul       cl
add       ax, word ptr ds:[_maskedcachedsegment]
LEAVE_MACRO     
pop       di
pop       si
pop       cx
pop       bx
ret  
is_masked:

; al has lookup...
xor       ah, ah
SHIFT_MACRO shl       ax 3
xchg      ax, bx
mov       ax, MASKEDPIXELDATAOFS_SEGMENT
mov       es, ax

mov       bx, word ptr ds:[bx + _masked_headers]    ;    maskedheader->pixelofsoffset;
mov       word ptr ds:[_maskedheaderpixeolfs], bx   ;    maskedheaderpixeolfs = maskedheader->pixelofsoffset;

;    uint16_t __far* pixelofs   =  MK_FP(maskedpixeldataofs_segment, maskedheader->pixelofsoffset);
; es:bx is paixelofs

;    uint16_t ofs  = pixelofs[col]; // precached as segment value.
sal       cx, 1  ; col word lookup
add       bx, cx

;    return maskedcachedsegment + ofs;
mov       ax, word ptr ds:[_maskedcachedsegment]
add       ax, word ptr es:[bx]
LEAVE_MACRO     
pop       di
pop       si
pop       cx
pop       bx
ret      



cache_miss_move_all_cache_back_masked:

;		cachedsegmentlumps[3] = cachedsegmentlumps[2];
;		cachedsegmentlumps[2] = cachedsegmentlumps[1];
;		cachedsegmentlumps[1] = cachedsegmentlumps[0];
;		cachedlumps[3] = cachedlumps[2];
;		cachedlumps[2] = cachedlumps[1];
;		cachedlumps[1] = cachedlumps[0];

mov       ax, ds
mov       es, ax
xchg      ax, si   ; store lump

mov       si, OFFSET _cachedsegmentlumps
lea       di, [si + 2]
; _cachedsegmentlumps and _cachedlumps are adjacent. we hit both with 2 sets of 3 word copies.
; doing 7 movsw breaks things
;_cachedsegmentlumps =                   _NULL_OFFSET + 00698h
;_cachedlumps =                 	     _NULL_OFFSET + 006A0h
movsw
movsw
movsw
mov       si, di
lea       di, [si + 2] ; todo or inc twice or add? bench?
movsw
movsw
movsw
mov       si, ax    ; restore lump
mov       di, dx    ; store lookup
;		cached_nextlookup = maskednextlookup; 
push      word ptr ds:[_maskednextlookup]
; dx is lookup
; ax is lump
;call      R_GetPatchTexture_
call  dword ptr ds:[_R_GetPatchTexture_addr]

; todo use di with offsets to all these? same size.
;		cachedsegmentlumps[0] = R_GetPatchTexture(lump, lookup);  // might zero out cachedlump vars;
mov       word ptr ds:[_cachedsegmentlumps], ax
;		cachedlumps[0] = lump;
mov       word ptr ds:[_cachedlumps], si
;		maskednextlookup     = cached_nextlookup; 
pop       word ptr ds:[_maskednextlookup]
;		maskedtexrepeat 	 = loopwidth;
pop       word ptr ds:[_maskedtexrepeat]    ; bp - 6 off

; di was set above before the function call...

jmp       found_cached_lump_masked


 
no_lump_do_texture:
; di is bp - 2 (tex)
;		uint8_t collength = texturecollength[tex];
mov       ax, TEXTURECOLLENGTH_SEGMENT ; todo can this end up in DS?
mov       es, ax
mov       si, OFFSET _cachedsegmenttex
mov       bx, OFFSET _cachedtex
;		if (cachedtex[0] != tex){
mov       ax, word ptr ds:[bx]  ; cachedtex[0]
mov       cl, byte ptr es:[di]  ; collength
cmp       ax, di
jne       do_cache_tex_miss_masked
do_cache_tex_hit_masked:
;mov       ax, word ptr ds:[si]
lodsw

done_setting_cached_tex_masked:

; ax is cachedsegmenttex[0];

;    cachedbyteheight = collength;
;    maskedheightvalcache  = collength;
;    maskedcachedsegment   = cachedsegmenttex[0];

; todo none of these close to bx, si, etc. worth moving them for smaller addressing?
mov       byte ptr ds:[_cachedbyteheight], cl
mov       byte ptr ds:[_maskedheightvalcache], cl
mov       word ptr ds:[_maskedcachedsegment], ax

; return maskedcachedsegment + (FastMul8u8u(cachedcollength[0] , texcol));

xchg      ax, dx
mov       al, byte ptr ds:[_cachedcollength] ; cachedcollength
mul       byte ptr [bp - 4]
add       ax, dx
LEAVE_MACRO     
pop       di
pop       si
pop       cx
pop       bx
ret      
do_cache_tex_miss_masked:

;if (cachedtex[1] != tex){
; si is _cachedsegmenttex (6B8)
; bx is _cachedtex (6D8)
; _cachedcollength is 6DC (bx + 4) (si - 0Ch)
xchg      ax, word ptr ds:[bx+2]   ;    cachedtex[1] = cachedtex[0];
cmp       ax, di
jne       update_both_cache_texes_masked
swap_tex1_tex2_masked:
mov       word ptr ds:[bx], ax

; todo use collength offset from bx (bx+4?)
mov       ax, word ptr ds:[_cachedcollength]   ;_cachedcollength
xchg      al, ah
mov       word ptr ds:[_cachedcollength], ax ;_cachedcollength

lodsw     ; mov       ax, word ptr ds:[si]
xchg      ax, word ptr ds:[si]
mov       word ptr ds:[si-2], ax

jmp       done_setting_cached_tex_masked

update_both_cache_texes_masked:


push      word ptr ds:[si]          ;    cachedsegmenttex[1] = cachedsegmenttex[0];
pop       word ptr ds:[si+2]

push      word ptr ds:[_maskednextlookup] ;   cached_nextlookup = maskednextlookup; 

mov       al, byte ptr ds:[_cachedcollength]   ; _cachedcollength
mov       byte ptr ds:[_cachedcollength + 1], al ;    cachedcollength[0] = cachedcollength[0];

xchg      ax, di
mov       word ptr ds:[bx], ax ;    cachedtex[0] = tex;    

;    cachedsegmenttex[0] = R_GetCompositeTexture(cachedtex[0]);
;call      R_GetCompositeTexture_
call  dword ptr ds:[_R_GetCompositeTexture_addr]

;    // restore these if composite texture is unloaded...

mov       word ptr ds:[si], ax 
mov       byte ptr ds:[_cachedcollength], cl  ;    cachedcollength[0] = collength;

pop       word ptr ds:[_maskednextlookup] ;    maskednextlookup     = cached_nextlookup; 
pop       word ptr ds:[_maskedtexrepeat]      ;    maskedtexrepeat 	 = loopwidth (bp - 6_);
jmp       done_setting_cached_tex_masked


ENDP



VISSPRITE_UNSORTED_INDEX    = 0FFh
VISSPRITE_SORTED_HEAD_INDEX = 0FEh


PROC R_SortVisSprites_ NEAR

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

mov       byte ptr cs:[SELFMODIFY_MASKED_loop_compare_instruction+1 - OFFSET R_MASK24_STARTMARKER_], al ; store count
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
add       bx, (SIZE VISSPRITE_T)  
cmp       ax, dx
jl        loop_set_vissprite_next

done_setting_vissprite_next:

sub        bx, (SIZE VISSPRITE_T)
mov       byte ptr cs:[SELFMODIFY_MASKED_set_al_to_loop_counter+1 - OFFSET R_MASK24_STARTMARKER_], 0  ; zero loop counter

mov       al, VISSPRITE_SORTED_HEAD_INDEX

mov       byte ptr [bp - 2], al
mov       byte ptr ds:[_vsprsortedheadfirst], al
mov       byte ptr ds:[bx], VISSPRITE_UNSORTED_INDEX
cmp       dx, 0  ; is this redundant?
jle       exit_sort_vissprites

loop_visplane_sort:

inc       byte ptr cs:[SELFMODIFY_MASKED_set_al_to_loop_counter+1 - OFFSET R_MASK24_STARTMARKER_] ; update loop counter

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
mov       ah, (SIZE VISSPRITE_T)
mov       bx, ax
mul       ah
xchg      ax, bx

mov       word ptr [bp - 06h], 0  ; field in unsorted
mov       word ptr [bp - 08h], bx ; field in unsorted
cmp       di, word ptr ds:[bx + si + + 1Ah + 2]
jg        unsorted_next_is_best_next
jne       prepare_find_best_index_subloop
cmp       cx, word ptr ds:[bx + si + 1Ah]
jbe       prepare_find_best_index_subloop
unsorted_next_is_best_next:
mov       dh, al  ;  store bestindex ( i think)
les       cx, dword ptr ds:[bx + si + 1Ah]
mov       di, es
add       bx, si
mov       word ptr [bp - 4], bx   ; todo dont add vissprites to this?

prepare_find_best_index_subloop:

mul       ah	  ; still 028h ((SIZE VISSPRITE_T) )
mov       bx, ax

mov       al, byte ptr ds:[bx+si]
cmp       al, VISSPRITE_UNSORTED_INDEX
jne       loop_sort_subloop
done_with_sort_subloop:
mov       di, word ptr [bp - 4]		; retrieve best visprite pointer
mov       al, byte ptr [bp - 034h]

cmp       al, dh
je        done_with_find_best_index_loop
mov       dl, (SIZE VISSPRITE_T)
loop_find_best_index:
mul       dl
mov       word ptr [bp - 0Ah], 0  ; some unsorted field
mov       bx, ax
mov       word ptr [bp - 0Ch], ax ; some unsorted field
mov       al, byte ptr ds:[bx + si]

cmp       al, dh
jne       loop_find_best_index



; vissprites[ds].next = best->next;
 ;break;

mov       al, byte ptr ds:[di]
mov       byte ptr ds:[bx+si], al
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


mov       al, byte ptr ds:[di]
mov       byte ptr [bp - 034h], al
found_best_index:
;        if (vsprsortedheadfirst == VISSPRITE_SORTED_HEAD_INDEX){
cmp       byte ptr ds:[_vsprsortedheadfirst], VISSPRITE_SORTED_HEAD_INDEX
jne       set_next_to_best_index

mov       byte ptr ds:[_vsprsortedheadfirst], dh
increment_visplane_sort_loop_variables:

mov       byte ptr [bp - 2], dh
mov       byte ptr ds:[di], VISSPRITE_SORTED_HEAD_INDEX
SELFMODIFY_MASKED_set_al_to_loop_counter:
mov       al, 0FFh ; get loop counter
SELFMODIFY_MASKED_loop_compare_instruction:
cmp       al, 0FFh ; compare
jge       exit_sort_vissprites
jmp       loop_visplane_sort

set_next_to_best_index:
;            vissprites[vsprsortedheadprev].next = bestindex;

mov       al, byte ptr [bp - 2]
mov	      ah, (SIZE VISSPRITE_T)
mul       ah
mov       bx, ax

mov       byte ptr ds:[bx + _vissprites], dh
jmp       increment_visplane_sort_loop_variables

ENDP











;
; The following functions are loaded into a different segment at runtime.
; However, at compile time they have access to the labels in this file.
;


;R_WriteBackViewConstantsMasked

PROC R_WriteBackViewConstantsMasked24_ FAR
PUBLIC R_WriteBackViewConstantsMasked24_ 



mov      ax, DRAWFUZZCOL_AREA_SEGMENT
mov      ds, ax


ASSUME DS:R_MASK24_TEXT

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
mov      word ptr ds:[SELFMODIFY_MASKED_detailshift_2_minus_16_bit_shift- OFFSET R_MASK24_STARTMARKER_+0], ax
mov      word ptr ds:[SELFMODIFY_MASKED_detailshift_2_minus_16_bit_shift- OFFSET R_MASK24_STARTMARKER_+2], ax
mov      word ptr ds:[SELFMODIFY_MASKED_multi_detailshift_2_minus_16_bit_shift- OFFSET R_MASK24_STARTMARKER_+0], ax
mov      word ptr ds:[SELFMODIFY_MASKED_multi_detailshift_2_minus_16_bit_shift- OFFSET R_MASK24_STARTMARKER_+2], ax




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
mov      word ptr ds:[SELFMODIFY_MASKED_detailshift_2_minus_16_bit_shift- OFFSET R_MASK24_STARTMARKER_+0], ax
mov      word ptr ds:[SELFMODIFY_MASKED_multi_detailshift_2_minus_16_bit_shift- OFFSET R_MASK24_STARTMARKER_+0], ax

; nop 
mov      ax, 0c089h 
mov      word ptr ds:[SELFMODIFY_MASKED_detailshift_2_minus_16_bit_shift- OFFSET R_MASK24_STARTMARKER_+2], ax
mov      word ptr ds:[SELFMODIFY_MASKED_multi_detailshift_2_minus_16_bit_shift- OFFSET R_MASK24_STARTMARKER_+2], ax



; 81 c3 00 00 = add bx, 0000. Not technically a nop, but probably better than two mov ax, ax?
; 89 c0       = mov ax, ax. two byte nop.

jmp      done_modding_shift_detail_code_masked
set_to_zero_masked:

; detailshift 0 case. usually involves two shift pairs.
; in this case - we make that first shift a proper shift

; d1 f8  = sar ax, 1
mov      ax, 0f8d1h 

; write to colfunc segment
mov      word ptr ds:[SELFMODIFY_MASKED_detailshift_2_minus_16_bit_shift- OFFSET R_MASK24_STARTMARKER_+0], ax
mov      word ptr ds:[SELFMODIFY_MASKED_detailshift_2_minus_16_bit_shift- OFFSET R_MASK24_STARTMARKER_+2], ax
mov      word ptr ds:[SELFMODIFY_MASKED_multi_detailshift_2_minus_16_bit_shift- OFFSET R_MASK24_STARTMARKER_+0], ax
mov      word ptr ds:[SELFMODIFY_MASKED_multi_detailshift_2_minus_16_bit_shift- OFFSET R_MASK24_STARTMARKER_+2], ax


; fall thru
done_modding_shift_detail_code_masked:


; note: examples 3/6/9 overwrite "add ax, 0" which compiles to the opcode where
; you get 16 bit immediate starting at base + 1 instead of a 8 bit immediate starting at base + 2.
mov   al, byte ptr ss:[_detailshiftitercount]
mov   byte ptr ds:[SELFMODIFY_MASKED_detailshiftitercount_1+2 - OFFSET R_MASK24_STARTMARKER_], al
mov   byte ptr ds:[SELFMODIFY_MASKED_detailshiftitercount_2+4 - OFFSET R_MASK24_STARTMARKER_], al
mov   byte ptr ds:[SELFMODIFY_MASKED_detailshiftitercount_3+1 - OFFSET R_MASK24_STARTMARKER_], al
mov   byte ptr ds:[SELFMODIFY_MASKED_detailshiftitercount_4+2 - OFFSET R_MASK24_STARTMARKER_], al
mov   byte ptr ds:[SELFMODIFY_MASKED_detailshiftitercount_5+4 - OFFSET R_MASK24_STARTMARKER_], al
mov   byte ptr ds:[SELFMODIFY_MASKED_detailshiftitercount_6+1 - OFFSET R_MASK24_STARTMARKER_], al
mov   byte ptr ds:[SELFMODIFY_MASKED_detailshiftitercount_7+4 - OFFSET R_MASK24_STARTMARKER_], al
mov   byte ptr ds:[SELFMODIFY_MASKED_detailshiftitercount_8+2 - OFFSET R_MASK24_STARTMARKER_], al
mov   byte ptr ds:[SELFMODIFY_MASKED_detailshiftitercount_9+2 - OFFSET R_MASK24_STARTMARKER_], al


mov   ax, word ptr ss:[_detailshiftandval]
mov   word ptr ds:[SELFMODIFY_MASKED_detailshiftandval_1+1 - OFFSET R_MASK24_STARTMARKER_], ax
mov   word ptr ds:[SELFMODIFY_MASKED_detailshiftandval_2+1 - OFFSET R_MASK24_STARTMARKER_], ax


mov   al, byte ptr ss:[_detailshift+1]
mov   byte ptr ds:[SELFMODIFY_MASKED_detailshiftplus1_1+1 - OFFSET R_MASK24_STARTMARKER_], al
add   al, _quality_port_lookup
mov   byte ptr ds:[SELFMODIFY_MASKED_detailshiftplus1_2+2 - OFFSET R_MASK24_STARTMARKER_], al
mov   byte ptr ds:[SELFMODIFY_MASKED_detailshiftplus1_3+2 - OFFSET R_MASK24_STARTMARKER_], al
mov   byte ptr ds:[SELFMODIFY_MASKED_detailshiftplus1_4+2 - OFFSET R_MASK24_STARTMARKER_], al

mov   ax, word ptr ss:[_viewheight]
mov   word ptr ds:[SELFMODIFY_MASKED_viewheight_1+1 - OFFSET R_MASK24_STARTMARKER_], ax
mov   word ptr ds:[SELFMODIFY_MASKED_viewheight_2+1 - OFFSET R_MASK24_STARTMARKER_], ax



mov      ax, ss
mov      ds, ax



retf

endp

;R_WriteBackMaskedFrameConstants

PROC R_WriteBackMaskedFrameConstants24_ FAR
PUBLIC R_WriteBackMaskedFrameConstants24_ 

; todo: merge this with some other code. maybe R_DrawMasked and use CS

mov      ax, DRAWFUZZCOL_AREA_SEGMENT
mov      ds, ax


ASSUME DS:R_MASK24_TEXT

; get whole dword at the end here.

mov   ax, word ptr ss:[_centery]
mov   word ptr ds:[SELFMODIFY_MASKED_centery_1+3 - OFFSET R_MASK24_STARTMARKER_], ax
mov   word ptr ds:[SELFMODIFY_MASKED_centery_2+1 - OFFSET R_MASK24_STARTMARKER_], ax

mov   ax, word ptr ss:[_viewz+0]
mov   word ptr ds:[SELFMODIFY_MASKED_viewz_lo_1+2 - OFFSET R_MASK24_STARTMARKER_], ax
mov   ax, word ptr ss:[_viewz+2]
mov   word ptr ds:[SELFMODIFY_MASKED_viewz_hi_1+1 - OFFSET R_MASK24_STARTMARKER_], ax

mov   ax, word ptr ss:[_destview+0]
mov   word ptr ds:[SELFMODIFY_MASKED_destview_lo_1+2 - OFFSET R_MASK24_STARTMARKER_], ax
mov   word ptr ds:[SELFMODIFY_MASKED_destview_lo_2+1 - OFFSET R_MASK24_STARTMARKER_], ax
mov   word ptr ds:[SELFMODIFY_MASKED_destview_lo_3+1 - OFFSET R_MASK24_STARTMARKER_], ax

mov   ax, word ptr ss:[_destview+2]
mov   word ptr ds:[SELFMODIFY_MASKED_destview_hi_1+1 - OFFSET R_MASK24_STARTMARKER_], ax

mov   al, byte ptr ss:[_extralight]
mov   byte ptr ds:[SELFMODIFY_MASKED_extralight_1+1 - OFFSET R_MASK24_STARTMARKER_], al

mov   al, byte ptr ss:[_fixedcolormap]
cmp   al, 0
jne   do_fixedcolormap_selfmodify
do_no_fixedcolormap_selfmodify:

; replace with nop.
; nop 
mov      ax, 0c089h 
mov      word ptr ds:[SELFMODIFY_MASKED_fixedcolormap_1 - OFFSET R_MASK24_STARTMARKER_], ax
mov      word ptr ds:[SELFMODIFY_MASKED_fixedcolormap_2 - OFFSET R_MASK24_STARTMARKER_], ax



jmp done_with_fixedcolormap_selfmodify

do_fixedcolormap_selfmodify:
mov   byte ptr ds:[SELFMODIFY_MASKED_fixedcolormap_3+5 - OFFSET R_MASK24_STARTMARKER_], al

; modify jmp in place.
mov   ax, ((SELFMODIFY_MASKED_fixedcolormap_1_TARGET - SELFMODIFY_MASKED_fixedcolormap_1_AFTER) SHL 8) + 0EBh
mov   word ptr ds:[SELFMODIFY_MASKED_fixedcolormap_1 - OFFSET R_MASK24_STARTMARKER_], ax
mov   ah, (SELFMODIFY_MASKED_fixedcolormap_2_TARGET - SELFMODIFY_MASKED_fixedcolormap_2_AFTER)
mov   word ptr ds:[SELFMODIFY_MASKED_fixedcolormap_2 - OFFSET R_MASK24_STARTMARKER_], ax



; fall thru
done_with_fixedcolormap_selfmodify:

mov      ax, ss
mov      ds, ax






retf



ENDP

; end marker for this asm file
PROC R_MASK24_ENDMARKER_ FAR
PUBLIC R_MASK24_ENDMARKER_ 
ENDP

ENDS
END
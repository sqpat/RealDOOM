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





_spritepagesegments:
PUBLIC _spritepagesegments

; 90, 94, 98, 9C
db (SPRITE_COLUMN_SEGMENT + 00000h) SHR 8
db (SPRITE_COLUMN_SEGMENT + 00400h) SHR 8
db (SPRITE_COLUMN_SEGMENT + 00800h) SHR 8
db (SPRITE_COLUMN_SEGMENT + 00C00h) SHR 8








_fuzzpos:

dw  (OFFSET _fuzzoffset) - (OFFSET R_MASK24_STARTMARKER_)



SIZE_FUZZTABLE = 50

; DONT MOVE THIS FROM 0

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

base_product = OFFSET _scalelight

_mul48lookup_with_scalelight_with_minusone_offset:
   dw base_product

_mul48lookup_with_scalelight:
REPT 16
   dw base_product
   base_product = base_product + 48
ENDM
   base_product = base_product - 48
   dw base_product ; for overflow cases...
   dw base_product ; for overflow cases...
   dw base_product ; for overflow cases...



IF COMPISA GE COMPILE_386
; todo used only once. 
ALIGN_MACRO
PROC   FixedMulMaskedLocal_ NEAR   ; fairly optimized
PUBLIC FixedMulMaskedLocal_
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


ALIGN_MACRO
PROC   FixedMulMaskedLocal_ NEAR   ; fairly optimized
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





COLFUNC_JUMP_AND_FUNCTION_AREA_OFFSET_DIFF = ((COLFUNC_FUNCTION_AREA_SEGMENT - COLFUNC_FILE_START_SEGMENT) * 16)



; multi/single refer to whether this is drawing real masked columns with multiple sections
; most are multi
; single generally involves false mid walls like e1m1's slime room
; this function is not actually significantly different but there are
; different codepaths leading here and different data formats used.
;  So its easier to have different functions, and really optimize the the multi version.
; Note that this isnt called once in shareware timedemo 3 for instance



;
; R_DrawSingleMaskedColumn
;
	
; all 3 instances called from R_RenderMaskedSegRange_

ALIGN_MACRO
PROC   R_DrawSingleMaskedColumn_  NEAR    ; fairly unoptimized, barely runs though so who cares
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

exit_draw_masked_column_shadow_early:
ret

ALIGN_MACRO
PROC   R_DrawMaskedSpriteShadow_ NEAR  ; fairly optimized
PUBLIC R_DrawMaskedSpriteShadow_
; ax 	 pixelsegment
; cx:bx  column fardata

; bp carries topscreen segment

mov   es, cx

cmp   byte ptr es:[bx + COLUMN_T.column_topdelta], 0FFh
je    exit_draw_masked_column_shadow_early


push  dx
push  si
push  di
push  bp


mov   si, bx

mov   bx, word ptr ds:[_dc_x]
mov   word ptr cs:[SELFMODIFY_MASKED_SHADOW_drawmaskedcolumn_set_dc_x+1], bx
sal   bx, 1                             ; word lookup
lds   di, dword ptr ds:[_mfloorclip]
mov   ax, word ptr ds:[bx+di]
mov   word ptr cs:[SELFMODIFY_MASKED_SHADOW_set_mfloorclip_dc_x_lookup+1], ax
lds   di, dword ptr ss:[_mceilingclip]
mov   ax, word ptr ds:[bx+di]
mov   word ptr cs:[SELFMODIFY_MASKED_SHADOW_set_mceilingclip_dc_x_lookup+1], ax

mov   ax, ss
mov   ds, ax   ; restore ds...

lods  word ptr es:[si]

draw_next_shadow_sprite_post:
push  es
push  si

; es, si, bp safe to use


xor   cx, cx
mov   cl, al      ; al 0, cx = 0 extended topdelta for mul

xchg  ax, bx      ; back column field up in bx

xor   ax, ax  ; ax = 0
cwd           ; dx = 0

les   di, dword ptr ds:[_spryscale]
mov   bp, es

jcxz  skip_topdelta_mul_shadow

mov   ax, bp

; todo this is actually mul 8x32. is there a faster way involving 8 bit muls?
;inlined FastMul16u32u_
MUL  CX        ; AX * CX
XCHG CX, AX    ; store low product to be high result. Retrieve orig AX
MUL  DI        ; AX * BX
ADD  DX, CX    ; add 

skip_topdelta_mul_shadow:

add   ax, word ptr ds:[_sprtopscreen]       ; are these lowbits ever nonzero? yes, usually so
adc   dx, word ptr ds:[_sprtopscreen+2]


; topscreen = DX:AX.

;		dc_yl = topscreen.h.intbits; 
;		if (topscreen.h.fracbits)
;			dc_yl++;

xor  si, si
neg  ax
adc  si, dx  ; si stores dc_yl
neg  ax


; calculate dc_yh ((length * scale))

mov  cl, bh   ; cached length. bx now free to use. ch already was 0

xchg ax, bp   ;  ax gets spyscale+2 back. bp stores old topscreen low
mov  bx, dx   ;  bx:bp stores old topscreen result

;        bottomscreen.w = topscreen.w + FastMul16u32u(column->length, spryscale.w);

; ax:bx spryscale

; todo can this be 8 bit mul without the xor ch or not
;inlined fastmul16u32u
MUL  CX        ; AX * CX
XCHG CX, AX    ; store low product to be high result. Retrieve orig AX
MUL  DI        ; AX * DI
ADD  DX, CX    ; add prev low result to high word


; add cached topscreen
add   ax, bp
adc   dx, bx

;		dc_yh = bottomscreen.h.intbits;
;		if (!bottomscreen.h.fracbits)
;			dc_yh--;

neg ax
sbb dx, 0h

mov di, dx  ; todo get this for free with register juggling above?


; dx is dc_yh but needs to be written back 
; dc_yh, dc_yl are set (di, si)


SELFMODIFY_MASKED_SHADOW_set_mfloorclip_dc_x_lookup:
mov   cx, 01000h
cmp   di, cx
jl    skip_floor_clip_set_shadow
mov   di, cx
dec   di
skip_floor_clip_set_shadow:


;        if (dc_yl <= mceilingclip[dc_x])
;            dc_yl = mceilingclip[dc_x]+1;

SELFMODIFY_MASKED_SHADOW_set_mceilingclip_dc_x_lookup:
mov   cx, 01000h

cmp   si, cx
jg    skip_ceil_clip_set_shadow
mov   si, cx
inc   si
skip_ceil_clip_set_shadow:


sub   di, si   ; count =  dc_yh - dc_yl
js    jump_to_do_next_shadow_sprite_iteration  ; rare i think... branch is fine


; texmid not needed for fuzzdraws, because we are reading from screen behind sprite, not texture.

SELFMODIFY_MASKED_SHADOW_drawmaskedcolumn_set_dc_x:
mov   dx, 01000h

; todo... is this supposed to be done outside?

mov   ax, DC_YL_LOOKUP_MASKEDMAPPING_SEGMENT
mov   es, ax
mov   bx, si   ; bx+si = dc_yl word lookup

; todo: proper shift jmp thing.
mov   cl, byte ptr ds:[_detailshift2minus]
sar   dx, cl

SELFMODIFY_MASKED_destview_lo_1:
add   dx, 1000h   ; need the 2 byte constant.
add   dx, word ptr es:[bx+si]

mov   cx, dx

; todo has this already been done?

SELFMODIFY_MASKED_destview_hi_1:
mov   bx, 0

; pass in count via di
; pass in destview via bx
; pass in offset via cx



;call R_DrawFuzzColumn_  ; inlined


mov  es, bx
mov  si, word ptr cs:[_fuzzpos - OFFSET R_MASK24_STARTMARKER_]	; note this is always the byte offset - no shift conversion necessary

;  need to put di in cx
xchg cx, di   ; cx gets count , di gets screen offset

mov  ax, cs     ; cs holds fuzzpos
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
ALIGN_MACRO
jump_to_do_next_shadow_sprite_iteration:
jmp  do_next_shadow_sprite_iteration
ALIGN_MACRO
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
ALIGN_MACRO
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

 





do_next_shadow_sprite_iteration:
pop   si
pop   es

lods  word ptr es:[si]

cmp   al, 0FFh
je    exit_draw_shadow_sprite
jmp   draw_next_shadow_sprite_post
ALIGN_MACRO
zero_out_fuzzpos:
mov   si, (OFFSET _fuzzoffset) - (OFFSET R_MASK24_STARTMARKER_)
loop  draw_one_fuzzpixel
jmp finished_drawing_fuzzpixels
ALIGN_MACRO
exit_draw_shadow_sprite:

pop   bp
mov   cx, es
pop   di
pop   si
pop   dx
ret   

ENDP



ALIGN_MACRO
do_quick_return_whole:
  xor   ax, ax
  mov   dx, 08000h

  ret

ALIGN_MACRO
PROC   FixedDivWholeA_MaskedLocal_   NEAR ; fairly optimized i think
PUBLIC FixedDivWholeA_MaskedLocal_

; big improvements to branchless fixeddiv 'preamble' by zero318
; both numbers positive. no signs!

; note: AX is always a fairly low number in this call and will never shift 2 into high bits


   jcxz do_simple_div_whole  ; if cx is nonzero then the bounds check definitely failed and does not need to be done
  restore_reg_then_do_full_divide_whole:


do_full_divide_whole:

  
push si
push di

; todo inline i guess.
call div48_32_whole_BSPLocal_ ; internally does push pop of di/bp but not si

; set negative if need be...

mov   dx, es      ; retrieve q1
pop   di
pop   si



ret

; ALIGN_MACRO  ; adding these back seems to lower bench scores
do_simple_div_whole:
; AX:0000 div 0000:BX
; high word is AX:0000 / BX
; low word: divide remainder << 16 / BX

   mov  dx, ax  ; for division of AX:0000
   shl  ax, 1
   shl  ax, 1
   cmp  ax, bx
   jae  do_quick_return_whole   ; fixeddiv shift 14 
   xchg ax, cx  ; zero ax for div. cx is known zero since we jcxzed here.

   div  bx       ; get high result
   mov  cx, ax   ; store high result
   xor  ax, ax   ; prep to divide remainder
   div  bx       ; divide by remainder, get low word
   mov  dx, cx   ; restore high result
   ret


ENDP





;div48_32_whole_
; basically, shift numerator left 16 and divide
; AX:00:00 / CX:BX

; ALIGN_MACRO  ; adding these back seems to lower bench scores
PROC div48_32_whole_BSPLocal_ NEAR ; fairly optimized i think

; di:si get shifted cx:bx
xor dx, dx
; cx known nonzero.

test ch, ch
jne shift_bits_whole
; shift a whole byte immediately

mov ch, cl
mov cl, bh
mov bh, bl
xor bl, bl

mov dh, dl
mov dl, ah
mov ah, al
xor al, al

shift_bits_whole:



; less than a byte to shift
; shift until MSB is 1

SAL BX, 1
RCL CX, 1
JC done_shifting_whole
SAL AX, 1
RCL DX, 1

SAL BX, 1
RCL CX, 1
JC done_shifting_whole  
SAL AX, 1
RCL DX, 1

SAL BX, 1
RCL CX, 1
JC done_shifting_whole  
SAL AX, 1
RCL DX, 1

SAL BX, 1
RCL CX, 1
JC done_shifting_whole  
SAL AX, 1
RCL DX, 1

SAL BX, 1
RCL CX, 1
JC done_shifting_whole  
SAL AX, 1
RCL DX, 1

SAL BX, 1
RCL CX, 1
JC done_shifting_whole  
SAL AX, 1
RCL DX, 1

SAL BX, 1
RCL CX, 1
JC done_shifting_whole  
SAL AX, 1
RCL DX, 1

SAL BX, 1
RCL CX, 1






; store this
done_shifting_whole:

; we overshifted by one and caught it in the carry bit. lets shift back right one.

RCR CX, 1
RCR BX, 1

; todo unsure if this is worth it
;test bx, bx                ; rcr does not set zero flag, lame!
;jz  do_simple_div_after_all_whole  ; we can divide by 16 bits after all?





; DX:AX holds divisor...
; CX:BX holds dividend...
; numhi = DX:AX
; numlo = 00:00...



mov   di, ax      ; store copy of numhi.low


;	divresult.wu = DIV3216RESULTREMAINDER(numhi.wu, den1);
; DX:AX = numhi.wu

div   cx

; rhat = dx
; qhat = ax
;    c1 = FastMul16u16u(qhat , den0);

mov   si, dx					; si stores rhat
mov   es, ax     ; store qhat
mul   bx   						; DX:AX = c1

;  c2 = rhat:num1

;    if (c1 > c2.wu)
;         qhat -= (c1 - c2.wu > den.wu) ? 2 : 1;
; 

; c1 hi = dx, c2 lo = si
cmp   dx, si

jae   continue_checking_q1_whole

q1_ready_whole:

mov  ax, es
;	rem.hu.intbits = numhi.hu.fracbits;
;	rem.hu.fracbits = num1;
;	rem.wu -= FastMul16u32u(q1, den.wu);



; multiplying by cx:bx basically. inline bx in as si.

;inlined FastMul16u32u_

MUL  cx        ; AX * CX
mov  si, AX    ; store low product to be high result. Retrieve orig AX
mov  ax, es
MUL  bx        ; AX * si
ADD  DX, si    ; add 

; actual 2nd division...


neg   ax
sbb   di, dx
mov   dx, di

cmp   dx, cx

; check for adjustment

;    if (rem.hu.intbits < den1){

jnb    adjust_for_overflow_whole

div   cx

mov   si, ax
mov   di, dx

mul   bx
sub   dx, di

jae   continue_c1_c2_test_whole

do_return_2_whole:
mov   ax, si

ret  

; ALIGN_MACRO  ; adding these back seems to lower bench scores
continue_check2_whole:
test  ax, ax
jz    do_return_2_whole
continue_c1_c2_test_whole:
je    continue_check2_whole
; happens about 25% of the time

cmp   dx, cx
jae   check_for_extra_qhat_subtraction_whole

do_qhat_subtraction_by_1_whole:
dec   si

mov   ax, si

ret  

; ALIGN_MACRO  ; adding these back seems to lower bench scores
check_for_extra_qhat_subtraction_whole:
ja    do_qhat_subtraction_by_2_whole
cmp   bx, ax

jae   do_qhat_subtraction_by_1_whole
do_qhat_subtraction_by_2_whole:

dec   si
jmp   do_qhat_subtraction_by_1_whole

; ALIGN_MACRO  ; adding these back seems to lower bench scores
do_simple_div_after_all_whole:

; zero high word just calculate low word.
div  cx       ; get low result
mov  es, ax
mov  ax, bx   ; known zero
div  cx
ret


; ALIGN_MACRO  ; adding these back seems to lower bench scores
continue_checking_q1_whole:
ja    check_c1_c2_diff_whole

test  ax, ax
jz    q1_ready_whole

; rare codepath! 
;cmp   ax, di
;jbe   q1_ready_whole

check_c1_c2_diff_whole:
;sub   ax, di
sub   dx, si
cmp   dx, cx
; these branches havent been tested but this is a super rare codepath
ja    qhat_subtract_2_whole 
je    compare_low_word_whole

qhat_subtract_1_whole:
mov ax, es
dec ax
mov es, ax
jmp q1_ready_whole

; very rare case!
; ALIGN_MACRO  ; adding these back seems to lower bench scores
adjust_for_overflow_whole:
xor   di, di
sub   ax, cx
sbb   dx, di

cmp   dx, cx

; check for overflow param

jae   adjust_for_overflow_again_whole


div   cx
mov   si, ax
mov   di, dx

mul   bx
sub   dx, di
; these branches havent been tested but this is a super super super rare codepath
ja    continue_c1_c2_test_2_whole
jne   dont_decrement_qhat_and_return_whole
test  ax, ax
jz   dont_decrement_qhat_and_return_whole
continue_c1_c2_test_2_whole:


cmp   dx, cx
ja    decrement_qhat_and_return_whole
; these branches havent been tested but this is a super super super super super rare codepath
jne   dont_decrement_qhat_and_return_whole
cmp   bx, ax
jae   dont_decrement_qhat_and_return_whole
decrement_qhat_and_return_whole:
dec   si
dont_decrement_qhat_and_return_whole:
mov   ax, si
ret  

; ALIGN_MACRO  ; adding these back seems to lower bench scores
compare_low_word_whole:
cmp   ax, bx
jbe   qhat_subtract_1_whole

qhat_subtract_2_whole:
mov ax, es
dec ax
mov es, ax
jmp qhat_subtract_1_whole

; the divide would have overflowed. subtract values
; ALIGN_MACRO  ; adding these back seems to lower bench scores
adjust_for_overflow_again_whole:

sub   ax, cx
sbb   dx, di

div   cx

; ax has its result...

ret 


ENDP


ALIGN_MACRO
flip_not_zero:

; rare case

dec   word ptr ds:[si + VISSPRITE_T.vs_startfrac + 0]   ; 0FFFFh

neg   cx
neg   bx
sbb   cx, ax ; known 0
jmp   flip_stuff_done


;
; R_DrawVisSprite_
;




ALIGN_MACRO
PROC   R_DrawVisSprite_ NEAR  ; fairly optimized.
PUBLIC R_DrawVisSprite_
; si is vissprite_t near pointer



; todo calculate xiscale now.
; note: we lazily calculate xiscale (the result of a FixedDiv (FRACUNIT, xxxx) operation) here.
; this is because the sprite may have been obscured by this point with no visible pixels.


mov   ax, 1

les   bx, dword ptr ds:[si + VISSPRITE_T.vs_xiscale]
mov   cx, es

call FixedDivWholeA_MaskedLocal_   ; todo inline? then make do_32_bit_mul_vissprite etc fit without jump.

xchg  ax, bx
mov   cx, dx  ; cx:bx get vs_xiscale

xor   ax, ax
cwd
cmp   word ptr ds:[si + VISSPRITE_T.vs_startfrac + 2], ax   ; startfrac +0 = flip
xchg  dx, word ptr ds:[si + VISSPRITE_T.vs_startfrac]       ; dx gets x1, startfrac + 0 gets 0 
jne   flip_not_zero

flip_stuff_done:

mov   word ptr ds:[si + VISSPRITE_T.vs_xiscale + 0], bx
mov   word ptr ds:[si + VISSPRITE_T.vs_xiscale + 2], cx


;    if (vis->x1 > x1)
;        vis->startfrac += FastMul16u32u((vis->x1-x1),vis->xiscale);

mov   ax, word ptr ds:[si + VISSPRITE_T.vs_x1]

sub   ax, dx  ; we grabbed x1 earlier
jle   vis_x1_greater_than_x1

; cx:bx already vs_xiscale 
mov   di, cx ; backup

; inlined FastMul16u32u

IF COMPISA GE COMPILE_386


   ; set up ecx
   db 066h, 0C1h, 0E3h, 010h        ; shl  ebx, 0x10
   db 066h, 00Fh, 0A4h, 0D9h, 010h  ; shld ecx, ebx, 0x10

   ; set up eax
   db 066h, 098h                    ; cwde (prepare AX)

   ; actual mul
   db 066h, 0F7h, 0E1h              ; mul ecx
   ; set up return
   db 066h, 00Fh, 0A4h, 0C2h, 010h  ; shld edx, eax, 0x10
   

ELSE

   XCHG CX, AX    ; AX stored in CX
   MUL  CX        ; AX * CX
   XCHG CX, AX    ; store low product to be high result. Retrieve orig AX
   MUL  BX        ; AX * BX
   ADD  DX, CX    ; add 
ENDIF

add   word ptr ds:[si + VISSPRITE_T.vs_startfrac + 0], ax
adc   word ptr ds:[si + VISSPRITE_T.vs_startfrac + 2], dx

mov   cx, di ; restore cx. bx was unchanged.

vis_x1_greater_than_x1:

; TODO: dont write startfrac to memory. instead self modify it ahead directly.

; get xiscale into dx:ax
xchg  ax, bx
mov   dx, cx  ; xi_scale was in cx:bx



R_DrawPlayerVisSprite_:  ; pass in vs_xiscale in dx:ax. todo: consider a whole speciailized variant just for player.
PUBLIC R_DrawPlayerVisSprite_


xor   cx, cx  ; cx is 0
; labs
or    dx, dx
jge   xiscale_already_positive
neg   ax
adc   dx, cx   ; 0
neg   dx
xiscale_already_positive:

SELFMODIFY_MASKED_detailshift_2_32bit_1:
sar   dx, 1
rcr   ax, 1
sar   dx, 1
rcr   ax, 1



mov   word ptr cs:[SELFMODIFY_MASKED_set_dc_iscale_lo+1 - OFFSET R_MASK24_STARTMARKER_], ax
mov   byte ptr cs:[SELFMODIFY_MASKED_set_dc_iscale_hi+1 - OFFSET R_MASK24_STARTMARKER_], dl

mov   al, byte ptr ds:[si + VISSPRITE_T.vs_colormap]
; al is colormap. 
mov   byte ptr cs:[SELFMODIFY_MASKED_set_xlat_offset+2 - OFFSET R_MASK24_STARTMARKER_], al


test  dl, dl
je    is_stretch_draw ; from dl
not_stretch_draw:
mov   dx, SELFMODIFY_COLFUNC_JUMP_OFFSET24_NOLOOP_OFFSET+1
mov   di, DRAWCOL_NOLOOP_OFFSET_MASKED
jmp   continue_selfmodifies_vissprites

ALIGN_MACRO
do_32_bit_mul_vissprite:
inc   dx
jz    do_16_bit_mul_after_all_vissprite
dec   dx
do_32_bit_mul_after_all_vissprite:

call FixedMulMaskedLocal_

jmp done_with_mul_vissprite

ALIGN_MACRO
is_stretch_draw:
mov   dx, SELFMODIFY_COLFUNC_JUMP_OFFSET24_NOLOOPANDSTRETCH_OFFSET+1
mov   di, DRAWCOL_NOLOOPSTRETCH_OFFSET_MASKED

continue_selfmodifies_vissprites:
mov   word ptr cs:[SELFMODIFY_MASKED_COLFUNC_set_func_offset], di
mov   word ptr cs:[SELFMODIFY_masked_set_jump_write_offset+1 - OFFSET R_MASK24_STARTMARKER_], dx


mov   di, OFFSET _sprtopscreen
mov   word ptr ds:[di], cx   ; cx is 0
SELFMODIFY_MASKED_centery_1:
mov   word ptr ds:[di + 2], 01000h

les   ax, dword ptr ds:[si + VISSPRITE_T.vs_scale]  ; vis->scale
mov   dx, es

mov   word ptr ds:[_spryscale], ax
mov   word ptr ds:[_spryscale + 2], dx

les   bx, dword ptr ds:[si + VISSPRITE_T.vs_texturemid] ; vis->texturemid
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


; di is _sprtopscreen
sub   word ptr ds:[di], ax
sbb   word ptr ds:[di + 2], dx

mov   ax, word ptr ds:[si + VISSPRITE_T.vs_patch]
cmp   ax, word ptr ds:[_lastvisspritepatch]
jne   sprite_not_first_cachedsegment
mov   es, word ptr ds:[_lastvisspritesegment]

spritesegment_ready:

mov   di, word ptr ds:[si + VISSPRITE_T.vs_startfrac + 0]
mov   cx, word ptr ds:[si + VISSPRITE_T.vs_startfrac + 2]  

mov   ax, word ptr ds:[si + VISSPRITE_T.vs_x2]
mov   word ptr cs:[SELFMODIFY_MASKED_visspriteloop_x2_1+1 - OFFSET R_MASK24_STARTMARKER_], ax
mov   ax, word ptr ds:[si + VISSPRITE_T.vs_x1]
mov   word ptr cs:[SELFMODIFY_MASKED_visspriteloop_x1_1+1 - OFFSET R_MASK24_STARTMARKER_], ax
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

mov   word ptr cs:[SELFMODIFY_MASKED_vissprite_xiscale_lo+5 - OFFSET R_MASK24_STARTMARKER_], bx
mov   word ptr cs:[SELFMODIFY_MASKED_vissprite_xiscale_hi+5 - OFFSET R_MASK24_STARTMARKER_], dx

; todo: proper shift jmp thing

SELFMODIFY_MASKED_detailshift_2_32bit_2:
shl   bx, 1
rcl   dx, 1
shl   bx, 1
rcl   dx, 1

mov   word ptr cs:[SELFMODIFY_MASKED_add_shifted_xiscale_lo+2 - OFFSET R_MASK24_STARTMARKER_], bx
mov   word ptr cs:[SELFMODIFY_MASKED_add_shifted_xiscale_hi+2 - OFFSET R_MASK24_STARTMARKER_], dx

;        while (base4diff){
;            basespryscale-=vis->xiscale; 
;            base4diff--;
;        }

; cx:di  carry startfrac..
test  ax, ax
je    base4diff_is_zero


decrementbase4loop:
sub   di, word ptr ds:[si + VISSPRITE_T.vs_xiscale + 0]
sbb   cx, word ptr ds:[si + VISSPRITE_T.vs_xiscale + 2]
dec   ax
jne   decrementbase4loop

base4diff_is_zero:

; AX zero

; finally write these 
mov   word ptr cs:[SELFMODIFY_MASKED_vissprite_get_startfrac_lo+1 - OFFSET R_MASK24_STARTMARKER_], di
mov   word ptr cs:[SELFMODIFY_MASKED_vissprite_get_startfrac_hi+1 - OFFSET R_MASK24_STARTMARKER_], cx


; zero xoffset loop iter ; ax known zero after loop
mov   byte ptr cs:[SELFMODIFY_MASKED_set_bx_to_xoffset+1 - OFFSET R_MASK24_STARTMARKER_], al ; 0


; last use of si so si is free after this (?)
cmp   byte ptr ds:[si + VISSPRITE_T.vs_colormap], COLORMAP_SHADOW
je    jump_to_draw_shadow_sprite

; selfmodify any other visplane stuff here...?

jmp loop_vga_plane_draw_normal 
ALIGN_MACRO
jump_to_draw_shadow_sprite:
jmp   draw_shadow_sprite
ALIGN_MACRO
  
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
ALIGN_MACRO
sprite_not_in_cached_segments:
mov   dx, word ptr ds:[_lastvisspritepatch]
mov   word ptr ds:[_lastvisspritepatch2], dx
mov   dx, word ptr ds:[_lastvisspritesegment]
mov   word ptr ds:[_lastvisspritesegment2], dx
;call  R_GetSpriteTexture_   inlined


push  si
push  bp
; everything but si and bp is free game to be clobbered! 

mov   di, SPRITEPAGE_SEGMENT
mov   es, di

xchg  ax, di    ; di gets index

mov   al, byte ptr es:[di]
cmp   al, 0FFh
je    sprite_not_in_cache

mov   cl, byte ptr es:[di + SPRITEOFFSETS_OFFSET]

call  R_GetSpritePage_  ; destroys di, get cl first
; di got 13! cl was 0.
cbw
mov   di, ax
mov   al, cl
SHIFT_MACRO shl   ax 4      ;shift4
add   ah, byte ptr cs:[di + _spritepagesegments - OFFSET R_MASK24_STARTMARKER_]

pop   bp
pop   si

;jmp   done_with_R_GetSpriteTexture_
mov   word ptr ds:[_lastvisspritesegment], ax
mov   es, ax
mov   ax, word ptr ds:[si + VISSPRITE_T.vs_patch]
mov   word ptr ds:[_lastvisspritepatch], ax
jmp   spritesegment_ready
ALIGN_MACRO

sprite_not_in_cache:

mov       bp, di
mov       dx, SPRITETOTALDATASIZES_SEGMENT
mov       es, dx


;	if (size & 0xFF) {
;		blocksize++;
;	}

mov       bx, word ptr es:[bp+di] ; dx = size  ; bp+di = word lookup
add       bx, 0FFh
mov       bl, bh  ; blocksize = size >> 8

;   bl is blocksize

;	numpages = blocksize >> 6; // num EMS pages needed
xor       bh, bh
mov       ax, bx

;	if (blocksize & 0x3F) {
;		numpages++;
;	}

add       al, 03Fh      ; numpages in high 2 bits of al
SHIFT_MACRO sal ax 2

; ah is numpages
; bl = blocksize


mov       di, OFFSET _spritecache_nodes
mov       si, OFFSET _usedspritepagemem



;	if (numpages == 1) {
dec       ah

jnz       multipage_textureblock
;   uint8_t freethreshold = 64 - blocksize;
mov       al, 040h
sub       al, bl  
mov       cl, bl   
mov       ch, NUM_SPRITE_CACHE_PAGES
xor       bx, bx
;  cl = blocksize
;  al = threshold
;  bl = i
;  bh = 0


;		for (i = 0; i < NUM_SPRITE_CACHE_PAGES; i++) {
;			if (freethreshold >= usedspritepagemem[i]) {
;				goto foundonepage;
;			}
;		}

check_next_texture_page_for_space:

cmp       al, byte ptr ds:[bx + si]
jae       foundonepage

;		i = R_EvictL2CacheEMSPage(1, cachetype);

inc       bx
cmp       bl, ch
jl        check_next_texture_page_for_space

call      R_EvictL2CacheEMSPage_Sprite_Single_
; ah is 0
xchg      ax, bx  ; bl = page, bh = 0

foundonepage:
public foundonepage
; bl = page

;		texpage = i << 2;
;		texoffset = usedspritepagemem[i];   ; si
;		usedspritepagemem[i] += blocksize;


mov       al, byte ptr ds:[bx + si]  ; al = texoffset
add       byte ptr ds:[bx + si], cl  ; add blocksize

SHIFT_MACRO shl       bx 2 

; al = texoffset
; bx = texpage

;	spritepage[lump - firstspritelump] = texpage;
;	spriteoffset[lump - firstspritelump] = texoffset;
; bp = lump - firstsegment
mov       dx, SPRITEPAGE_SEGMENT
mov       es, dx
mov       byte ptr es:[bp], bl
mov       byte ptr es:[bp + SPRITEOFFSETS_OFFSET], al

mov       cl, al
mov       al, bl

jmp       done_with_getnextspriteblock
ALIGN_MACRO
multipage_textureblock:

; sprites are never 4 pages in practice... sort of a hack but maybe custom wads with sprites this big arent meant for realdoom

; ch is numpages
; bl = blocksize

mov       dh, byte ptr ds:[_spritecache_l2_head]

mov       cx, 01FFh ; plus for for the dec to ah
add       ch, ah    ; add multipage amount
mov       ah, bl    ; al stores blocksize for a bit
xor       bx, bx    ; bh needs to be 0 for various lookups/offsets

; al is free, in use a lot
; ch is numpages
; cl is 0FFh
; bh is 000h
; bl is active offset used for lookups 
; dh is i
; dl is nextpage


;		for (i = spritecache_l2_head;
;				i != -1; 
;				i = spritecache_nodes[i].prev
;				) {
;			if (!usedspritepagemem[i]) {
;				// need to check following pages for emptiness, or else after evictions weird stuff can happen
;				int8_t nextpage = spritecache_nodes[i].prev;
;				if ((nextpage != -1 &&!usedspritepagemem[nextpage])) {
;					nextpage = spritecache_nodes[nextpage].prev;

;				}
;			}
;		}

; note: the reason weird stuff can happen is that we dont reorder pages here, 
; so we only return a multipage is ok if we found enough contiguous pages
; if we dont, then we evict.


do_texture_multipage_loop:
mov       bl, dh
cmp       byte ptr ds:[bx + si], bh                    ; usedspritepagemem == 0?
jne       do_next_texture_multipage_loop_iter_bl_set   ; page is not empty

page_1_has_space:
SHIFT_MACRO shl       bl 2
mov       al, byte ptr ds:[bx + di + CACHE_NODE_PAGE_COUNT_T.cachenodecount_prev] ; check prev page
cmp       al, cl
je        do_next_texture_multipage_loop_iter
; has next page
mov       bl, al
cmp       byte ptr ds:[bx + si], bh             ; usedspritepagemem == 0?
je        found_multipage                       ; page is empty



do_next_texture_multipage_loop_iter:
mov       bl, dh
do_next_texture_multipage_loop_iter_bl_set:
SHIFT_MACRO shl       bl 2
mov       dh, byte ptr ds:[bx + di + CACHE_NODE_PAGE_COUNT_T.cachenodecount_prev]
cmp       dh, cl
jne       do_texture_multipage_loop

done_with_textureblock_multipage_loop:

;		i = R_EvictL2CacheEMSPage(numpages, cachetype);


mov       al, ch   ; numpages
mov       cl, ah   ; backup blocksize
call      R_EvictL2CacheEMSPage_Sprite_Multi_
cbw
mov       dh, al
xchg      ax, bx   ; zero bh. todo necessary? inner func may clear it.
mov       ah, cl   ; restore blocksize in ah


found_multipage:
PUBLIC  found_multipage
; reminder:
; al is prev page
; cl is now free (currenly 0FFh)
; bh is 000h
; ah is blocksize
; bl is active offset used for lookups 
; ch is numpages
; dh is i, becomes texpage
; dl is nextpage


mov       al, 040h

;		foundmultipage:
;        usedspritepagemem[i] = 64;

mov       bl, dh

mov       byte ptr ds:[bx + si], al
SHIFT_MACRO shl       bl 2

mov       dh, bl    ; texpage = (i << 2) + (numpagesminus1);
add       dh, ch    ; + numpages
dec       dh        ; minus1

;		spritecache_nodes[i].numpages = numpages;
;		spritecache_nodes[i].pagecount = numpages;

mov       cl, ch ; cl = numpages
mov       word ptr ds:[bx + di + CACHE_NODE_PAGE_COUNT_T.cachenodecount_pagecount], cx  ; write .numpages too at once
; numpages for sprites can only be 1 or 2, so if we are in multipage sprite  area its 2.

mov       bl, byte ptr ds:[bx + di + CACHE_NODE_PAGE_COUNT_T.cachenodecount_prev]

dec       cx
cmp       cl, 1 ; gross... better way?
je        two_page_sprite

three_page_sprite:
PUBLIC    three_page_sprite
mov       byte ptr ds:[bx + si], al
SHIFT_MACRO shl       bl 2
mov       word ptr ds:[bx + di + CACHE_NODE_PAGE_COUNT_T.cachenodecount_pagecount], cx  ; write .numpages too at once

mov       bl, byte ptr ds:[bx + di + CACHE_NODE_PAGE_COUNT_T.cachenodecount_prev]
dec       cx
two_page_sprite:
; set the last page.
; is bl FF?



;	if (blocksize & 0x3F) {
test      ah, 03Fh
je        dont_update_blocksize
and       ah, 03Fh
mov       al, ah            ;			usedspritepagemem[j] = blocksize & 0x3F;
dont_update_blocksize:


;		texoffset = 0; // if multipage then its always aligned to start of its block


mov       byte ptr ds:[bx + si], al ; set last page blocksize

SHIFT_MACRO shl       bl 2

;		spritecache_nodes[j].numpages = numpages;
;		spritecache_nodes[j].pagecount = 1;


mov       word ptr ds:[bx + di + CACHE_NODE_PAGE_COUNT_T.cachenodecount_pagecount], cx  ; write .numpages too at once


;	spritepage[lump - firstspritelump] = texpage;
;	spriteoffset[lump - firstspritelump] = texoffset;

; finally - use bp again
; bp = lump - firstsegment
mov       di, SPRITEPAGE_SEGMENT
mov       es, di
mov       byte ptr es:[bp], dh
mov       byte ptr es:[bp + SPRITEOFFSETS_OFFSET], bh  ; known 0


mov       al, dh
mov       cl, bh

done_with_getnextspriteblock:

xor       ch, ch

 ; es already spritepagesegment
 ; bp already lump

; al is spritepage   value
; cl is spriteoffset value

push  bp  ; store "index", lump + firstspritelump

call  R_GetSpritePage_  ; destroys di/bp, mantains cx
cbw
xchg  ax, di

SHIFT_MACRO shl   cx 4      ;shift4

add   ch, byte ptr cs:[di + _spritepagesegments  - OFFSET R_MASK24_STARTMARKER_]

pop   ax     ; "index"
push  cx     ; dest segment

add   ax, word ptr ds:[_firstspritelump]

;call  R_LoadSpriteColumns_  ; inlined
R_LoadSpriteColumns_:
PUBLIC R_LoadSpriteColumns_

;void R_LoadSpriteColumns(uint16_t lump, segment_t destpatch_segment);
; ax = lump
; dx = segment




xchg      ax, bx    ; backup..

;call      Z_QuickMapScratch_5000_
Z_QUICKMAPAI4 pageswapargs_scratch5000_offset_size INDEXED_PAGE_5000_OFFSET

pop       dx ; dest segment

;	patch_t __far *wadpatch = (patch_t __far *)SCRATCH_ADDRESS_5000;
;	uint16_t __far * columnofs = (uint16_t __far *)&(destpatch->columnofs[0]);   // will be updated in place..

mov       cx, SCRATCH_ADDRESS_5000_SEGMENT
push      cx   ; for ds later
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

pop       ds ; SCRATCH_ADDRESS_5000_SEGMENT
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

SHIFT_MACRO shr       ax 4;shift4  unlikely due to word?
mov       si, dx
mov       si, word ptr ds:[si]


mov       word ptr es:[bp], ax      ; todo swap bp/di and stosw?
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
mov       bp, es  ; return segment

;call      Z_QuickMapRender5000_
Z_QUICKMAPAI4 (pageswapargs_rend_offset_size+4) INDEXED_PAGE_5000_OFFSET



xchg     ax, bp  ; get return segment

pop   bp
pop   si




done_with_R_GetSpriteTexture_:


mov   word ptr ds:[_lastvisspritesegment], ax
mov   es, ax
mov   ax, word ptr ds:[si + VISSPRITE_T.vs_patch]
mov   word ptr ds:[_lastvisspritepatch], ax
jmp   spritesegment_ready
ALIGN_MACRO
exit_draw_vissprites:
ret 
ALIGN_MACRO


loop_vga_plane_draw_normal:
public loop_vga_plane_draw_normal
mov   cx, es
; si currently unused. can we use it?

SELFMODIFY_MASKED_set_bx_to_xoffset:
mov   bx, 0 ; zero out bh
SELFMODIFY_MASKED_detailshiftitercount_1:
cmp   bx, 0
jge    exit_draw_vissprites


mov   dx, SC_DATA
SELFMODIFY_MASKED_detailshiftplus1_2:
mov   al, byte ptr ds:[bx + 010h] ; NOTE this offset is selfmodified
out   dx, al
; es seems to be in use

SELFMODIFY_MASKED_vissprite_get_startfrac_lo:
mov   di, 01000h  
SELFMODIFY_MASKED_vissprite_get_startfrac_hi:
mov   dx, 01000h  
SELFMODIFY_MASKED_set_ax_to_dc_x_base4:
mov   ax, 0
mov   word ptr ds:[_dc_x], ax
SELFMODIFY_MASKED_visspriteloop_x1_1:
cmp   ax, 01000h 
jl    increment_by_shift
; todo try ALIGN_MACRO

draw_sprite_normal_innerloop:
SELFMODIFY_MASKED_visspriteloop_x2_1:
cmp   ax, 01000h
jg    end_draw_sprite_normal_innerloop
mov   bx, dx

SHIFT_MACRO shl bx 2 ; possible to preshift dx by 2?
; es is patch   
; bx way too high???
mov   ax, word ptr es:[bx + PATCH_T.patch_columnofs+0] ; todo LES?
mov   bx, word ptr es:[bx + PATCH_T.patch_columnofs+2]

add   ax, cx ; self modify? does it change?

; ax pixelsegment
; cx:bx column
; dx unused
; cx is preserved by this call here
; so is ES

call R_DrawMaskedColumn_  ; does si need to be preserved?

increment_by_shift:

; todohigh add into an immediate and remove dependency on variables, stack, etc. only makes sense if R_DrawMaskedColumn stops push/popping

SELFMODIFY_MASKED_detailshiftitercount_2:
add   word ptr ds:[_dc_x], 0
SELFMODIFY_MASKED_add_shifted_xiscale_lo:
add   di, 01000h
SELFMODIFY_MASKED_add_shifted_xiscale_hi:
adc   dx, 01000h

mov   ax, word ptr ds:[_dc_x]
jmp   draw_sprite_normal_innerloop
ALIGN_MACRO


end_draw_sprite_normal_innerloop:
inc   word ptr cs:[SELFMODIFY_MASKED_set_ax_to_dc_x_base4+1 - OFFSET R_MASK24_STARTMARKER_]
inc   byte ptr cs:[SELFMODIFY_MASKED_set_bx_to_xoffset+1 - OFFSET R_MASK24_STARTMARKER_]
SELFMODIFY_MASKED_vissprite_xiscale_lo:
add   word ptr cs:[SELFMODIFY_MASKED_vissprite_get_startfrac_lo+1], 01000h
SELFMODIFY_MASKED_vissprite_xiscale_hi:
adc   word ptr cs:[SELFMODIFY_MASKED_vissprite_get_startfrac_hi+1], 01000h
jmp   loop_vga_plane_draw_normal
ALIGN_MACRO

; shadow sprite loop

draw_shadow_sprite:
; this is jank, but also a rarer draw case. copy the selfmodifies from above..
; but yet, maybe there is a better way? probably not a huge deal on performance though?
; ax still 0
mov   byte ptr cs:[SELFMODIFY_MASKED_set_bx_to_xoffset_shadow+1 - OFFSET R_MASK24_STARTMARKER_], al
; di/cx are still these values.
mov   word ptr cs:[SELFMODIFY_MASKED_vissprite_get_startfrac_lo_shadow+1 - OFFSET R_MASK24_STARTMARKER_], di
mov   word ptr cs:[SELFMODIFY_MASKED_vissprite_get_startfrac_hi_shadow+1 - OFFSET R_MASK24_STARTMARKER_], cx

mov   ax, word ptr ds:[si + VISSPRITE_T.vs_x2]
mov   word ptr cs:[SELFMODIFY_MASKED_visspriteloop_x2_1_shadow+1 - OFFSET R_MASK24_STARTMARKER_], ax
mov   ax, word ptr ds:[si + VISSPRITE_T.vs_x1]
mov   word ptr cs:[SELFMODIFY_MASKED_visspriteloop_x1_1_shadow+1 - OFFSET R_MASK24_STARTMARKER_], ax

; bx/dx are still these values
mov   word ptr cs:[SELFMODIFY_MASKED_add_shifted_xiscale_lo_shadow+2 - OFFSET R_MASK24_STARTMARKER_], bx
mov   word ptr cs:[SELFMODIFY_MASKED_add_shifted_xiscale_hi_shadow+2 - OFFSET R_MASK24_STARTMARKER_], dx

mov   ax, word ptr cs:[SELFMODIFY_MASKED_vissprite_xiscale_lo+5 - OFFSET R_MASK24_STARTMARKER_]
mov   word ptr cs:[SELFMODIFY_MASKED_vissprite_xiscale_lo_shadow+5 - OFFSET R_MASK24_STARTMARKER_], ax
mov   ax, word ptr cs:[SELFMODIFY_MASKED_vissprite_xiscale_hi+5 - OFFSET R_MASK24_STARTMARKER_]
mov   word ptr cs:[SELFMODIFY_MASKED_vissprite_xiscale_hi_shadow+5 - OFFSET R_MASK24_STARTMARKER_], ax

mov   cx, es

loop_vga_plane_draw_shadow:
SELFMODIFY_MASKED_set_bx_to_xoffset_shadow:
mov   bx, 0
SELFMODIFY_MASKED_detailshiftitercount_4:
cmp   bx, 0
jge   exit_draw_vissprites_2


mov   dx, SC_DATA
SELFMODIFY_MASKED_detailshiftplus1_3:
mov   al, byte ptr ds:[bx + 010h] ; NOTE this offset is selfmodified
out   dx, al

sal   bx, 1
mov   dx, GC_INDEX
mov   ax, word ptr ds:[bx + _vga_read_port_lookup]
out   dx, ax

SELFMODIFY_MASKED_vissprite_get_startfrac_lo_shadow:
mov   di, 01000h  
SELFMODIFY_MASKED_vissprite_get_startfrac_hi_shadow:
mov   dx, 01000h  
SELFMODIFY_MASKED_set_ax_to_dc_x_base4_shadow:
mov   ax, 0
mov   word ptr ds:[_dc_x], ax

SELFMODIFY_MASKED_visspriteloop_x1_1_shadow:
cmp   ax, 01000h
jle   increment_by_shift_shadow

draw_sprite_shadow_innerloop:
SELFMODIFY_MASKED_visspriteloop_x2_1_shadow:
cmp   ax, 01000h 
jg    end_draw_sprite_shadow_innerloop
mov   bx, dx   ; frac.h.intbits

;   uint16_t __far * columndata = (uint16_t __far *)(&(patch->columnofs[frac.h.intbits]));
;   column_t __far * postdata   = (column_t __far *)(((byte __far *) patch) + columndata[1]);
;   R_DrawMaskedSpriteShadow(patch_segment + columndata[0], postdata);


SHIFT_MACRO shl bx 2

mov   ax, word ptr es:[bx + 8]  ; columndata[0] ?
mov   bx, word ptr es:[bx + 10] ; columndata[1] ?

add   ax, cx    ; patch_segment + columndata[0] ?

; cx, es preserved in the call

call R_DrawMaskedSpriteShadow_


increment_by_shift_shadow:
SELFMODIFY_MASKED_detailshiftitercount_5:
add   word ptr ds:[_dc_x], 0
SELFMODIFY_MASKED_add_shifted_xiscale_lo_shadow:
add   di, 01000h
SELFMODIFY_MASKED_add_shifted_xiscale_hi_shadow:
adc   dx, 01000h

mov   ax, word ptr ds:[_dc_x]

jmp   draw_sprite_shadow_innerloop
ALIGN_MACRO


end_draw_sprite_shadow_innerloop:
inc   word ptr cs:[SELFMODIFY_MASKED_set_ax_to_dc_x_base4_shadow+1 - OFFSET R_MASK24_STARTMARKER_]
inc   byte ptr cs:[SELFMODIFY_MASKED_set_bx_to_xoffset_shadow+1 - OFFSET R_MASK24_STARTMARKER_]

SELFMODIFY_MASKED_vissprite_xiscale_lo_shadow:
add   word ptr cs:[SELFMODIFY_MASKED_vissprite_get_startfrac_lo_shadow+1], 01000h
SELFMODIFY_MASKED_vissprite_xiscale_hi_shadow:
adc   word ptr cs:[SELFMODIFY_MASKED_vissprite_get_startfrac_hi_shadow+1], 01000h
jmp   loop_vga_plane_draw_shadow
ALIGN_MACRO
exit_draw_vissprites_2:
ret 


ENDP





ALIGN_MACRO
PROC   R_RenderMaskedSegRange_ NEAR ; todo definitely needs another look
PUBLIC R_RenderMaskedSegRange_

;void __near R_RenderMaskedSegRange (drawseg_t __far* ds, int16_t x1, int16_t x2) {

;es:di is far drawseg pointer
;x1 is ax
;x2 is cx

; no stack frame used..

; todo pass in si instead of di?
  
push  di

; todo selfmodify all this up ahead too.


mov   word ptr cs:[SELFMODIFY_MASKED_x1_field_1+1 - OFFSET R_MASK24_STARTMARKER_], ax
mov   word ptr cs:[SELFMODIFY_MASKED_x1_field_2+1 - OFFSET R_MASK24_STARTMARKER_], ax
mov   word ptr cs:[SELFMODIFY_MASKED_x1_field_3+2 - OFFSET R_MASK24_STARTMARKER_], ax
mov   word ptr cs:[SELFMODIFY_MASKED_cmp_to_x2+1 - OFFSET R_MASK24_STARTMARKER_], cx

; grab a bunch of drawseg values early in the function and write them forward.
mov   si, di
mov   ax, es
mov   ds, ax

lods  word ptr ds:[si]  ; si 2 after   ; drawseg_cursegvalue

mov   cx, ax  ; cx stores curseg. todo move all the uses up here.
SHIFT_MACRO shl ax 3
add   ah, (_segs_render SHR 8 ) 		; segs_render is ds:[0x4000] 
xchg  ax, di   ; di stores _curseg_render

; todo rearrange fields to make this faster?
; this whole charade with the lodsw is ~6-8 bytes smaller overall than just doing displacement.
; It could be better if we arranged adjacent fields i guess.

lods  word ptr ds:[si]  ; si 4 after    ; drawseg_x1
mov   word ptr cs:[SELFMODIFY_MASKED_dsp_02+1 - OFFSET R_MASK24_STARTMARKER_], ax
inc   si
inc   si  ; skip drawseg_x2
lods  word ptr ds:[si]  ; si 8 after    ; drawseg_scale1 lo
mov   word ptr cs:[SELFMODIFY_MASKED_dsp_06+1 - OFFSET R_MASK24_STARTMARKER_], ax
lods  word ptr ds:[si]  ; si A after    ; drawseg_scale1 hi
add   si, 4 ; skip drawseg_scale2
mov   word ptr cs:[SELFMODIFY_MASKED_dsp_08+2 - OFFSET R_MASK24_STARTMARKER_], ax
lods  word ptr ds:[si]  ; si 0x10 after ; drawseg_scalestep lo
mov   word ptr cs:[SELFMODIFY_MASKED_dsp_0E+1 - OFFSET R_MASK24_STARTMARKER_], ax
lods  word ptr ds:[si]  ; si 0x12 after ; drawseg_scalestep hi
mov   word ptr cs:[SELFMODIFY_MASKED_dsp_10+1 - OFFSET R_MASK24_STARTMARKER_], ax
add   si, 4 ; drawseg_bsilheight, drawseg_tsilheight
lods  word ptr ds:[si]  ; si 0x18 after ; drawseg_sprtopclip_offset
mov   word ptr cs:[SELFMODIFY_MASKED_dsp_16+4 - OFFSET R_MASK24_STARTMARKER_], ax
lods  word ptr ds:[si]  ; si 0x1A after ; drawseg_maskedtexturecol_val
mov   word ptr cs:[SELFMODIFY_MASKED_dsp_18+4 - OFFSET R_MASK24_STARTMARKER_], ax
lods  word ptr ds:[si]  ; si 0x1C after ; drawseg_silhouette
mov   word ptr cs:[SELFMODIFY_MASKED_dsp_1A+1 - OFFSET R_MASK24_STARTMARKER_], ax

mov   ax, ss
mov   ds, ax

mov   ax, SIDES_SEGMENT
mov   si, word ptr ds:[di + SEG_RENDER_T.sr_sidedefOffset]			; get sidedefOffset
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
shl   si, 1
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
ALIGN_MACRO
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

mov   bx, cx ; _curseg
add   bh, (seg_sides_offset_in_seglines SHR 8)		; seg_sides_offset_in_seglines high word
mov   dl, byte ptr es:[bx]		; ; dl is curlineside here
sal   cx, 1
mov   bx, cx ; _curseg word


mov   bx, word ptr es:[bx]		; 
xchg  bx, di                    ; di holds curlinelinedef, bx holds curseg_render  

mov   ax, LINEFLAGSLIST_SEGMENT
mov   es, ax

test  byte ptr es:[di], ML_DONTPEGBOTTOM

; todo lineflags jmp/nop selfmodify here?
; nop 
mov   ax, 0c089h 
je    peg_bottom

mov   ax, ((SELFMODIFY_MASKED_lineflags_ml_dontpegbottom_TARGET - SELFMODIFY_MASKED_lineflags_ml_dontpegbottom_AFTER) SHL 8) + 0EBh
peg_bottom:
; write instruction forward
mov   word ptr cs:[SELFMODIFY_MASKED_lineflags_ml_dontpegbottom - OFFSET R_MASK24_STARTMARKER_], ax

les   bx, dword ptr ds:[bx]				; get v1 offset
mov   cx, es                            ; get v2 offset

mov   ax, VERTEXES_SEGMENT
mov   es, ax
; bx/cx are preshifted


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
ALIGN_MACRO
ys_equal:
mov   al, 048h  ; dec ax instruction
jmp   done_comparing_vertexes
ALIGN_MACRO
xs_equal:
mov   al, 040h  ; inc ax instruciton
jmp   done_comparing_vertexes
ALIGN_MACRO


SELFMODIFY_MASKED_lineflags_ml_dontpegbottom_TARGET:
front_back_floor_case:

;	base = frontsector->floorheight > backsector->floorheight ? frontsector->floorheight : backsector->floorheight;

mov   ax, word ptr es:[di + SECTOR_T.sec_floorheight] ; frontsector floor
mov   cx, word ptr es:[bx + SECTOR_T.sec_floorheight] ; backsector floor
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



mov   al, byte ptr es:[di + SECTOR_T.sec_lightlevel]   ; get sector lightlevel

SHIFT_MACRO shr al 4

SELFMODIFY_MASKED_extralight_1_plus_one:
add   al, 0  ; added one extra, in case the next instruction went dec and turned it into -1

SELFMODIFY_MASKED_add_vertex_field:
nop				; becomes inc ax, dec ax, or nop

cbw
shl   ax, 1

xchg  ax, bx
mov   ax, word ptr cs:[_mul48lookup_with_scalelight_with_minusone_offset + bx]


mov   word ptr cs:[SELFMODIFY_MASKED_set_walllights+2 - OFFSET R_MASK24_STARTMARKER_], ax      ; store lights

;    maskedtexturecol = &openings[ds->maskedtexturecol_val];

SELFMODIFY_MASKED_dsp_1A:
mov   ax, 01000h		; ds->maskedtexturecol_val
sal   ax, 1  ; todo should this value be stored preshifted by default?
mov   word ptr ds:[_maskedtexturecol], ax


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
jmp fixed_colormap		; jump when fixedcolormap is not 0. 3 byte (word) jump!!!
SELFMODIFY_MASKED_fixedcolormap_2_AFTER:
;ALIGN_MACRO
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

; clobbers SI, seems safe? if not use es

; call FixedMulMaskedLocal_  ; inlined


IF COMPISA GE COMPILE_386
  shl  ecx, 16
  mov  cx, bx
  xchg ax, dx
  shl  eax, 16
  xchg ax, dx
  imul  ecx
  shr  eax, 16

ENDP
ELSE


    MOV  SI, DX
    PUSH AX
    MUL  BX
    MOV  es, DX
    MOV  AX, SI
    MUL  CX
    XCHG AX, SI
    CWD
    AND  DX, BX
    SUB  SI, DX
    MUL  BX
    MOV  BX, ES
    ADD  AX, BX
    ADC  SI, DX
    XCHG AX, CX
    CWD
    POP  BX
    AND  DX, BX
    SUB  SI, DX
    MUL  BX
    ADD  AX, CX
    ADC  DX, SI
ENDIF



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
jne   loop_dec_base4diff    ; if xoffset < detailshiftitercount exit loop
base4diff_is_zero_rendermaskedsegrange:

; di is 0








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
add   bx, 00000h
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
ALIGN_MACRO

do_32_bit_mul:
inc   dx
jz    do_16_bit_mul_after_all
dec   dx
do_32_bit_mul_after_all:
mov   cx, si
;call FixedMulMaskedLocal_  ; inlined


IF COMPISA GE COMPILE_386
  shl  ecx, 16
  mov  cx, bx
  xchg ax, dx
  shl  eax, 16
  xchg ax, dx
  imul  ecx
  shr  eax, 16

ENDP
ELSE


    MOV  SI, DX
    PUSH AX
    MUL  BX
    MOV  es, DX
    MOV  AX, SI
    MUL  CX
    XCHG AX, SI
    CWD
    AND  DX, BX
    SUB  SI, DX
    MUL  BX
    MOV  BX, ES
    ADD  AX, BX
    ADC  SI, DX
    XCHG AX, CX
    CWD
    POP  BX
    AND  DX, BX
    SUB  SI, DX
    MUL  BX
    ADD  AX, CX
    ADC  DX, SI
ENDIF


jmp done_with_mul
ALIGN_MACRO

; kinda rare case, fine if its a far jmp
SELFMODIFY_MASKED_fixedcolormap_2_TARGET:
fixed_colormap:
SELFMODIFY_MASKED_fixedcolormap_3:
mov   byte ptr cs:[SELFMODIFY_MASKED_set_xlat_offset+2 - OFFSET R_MASK24_STARTMARKER_], 0
jmp   colormap_set
ALIGN_MACRO


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
ALIGN_MACRO


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
ALIGN_MACRO

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

call  FastDiv3232FFFF_  ; todo inline eventually

mov   word ptr cs:[SELFMODIFY_MASKED_set_dc_iscale_lo+1 - OFFSET R_MASK24_STARTMARKER_], ax
; high byte set in fastdiv.

SELFMODIFY_MASKED_apply_stretch_tag:
jmp   is_stretch_draw_2     ; nop or jmp
SELFMODIFY_MASKED_apply_stretch_tag_AFTER:
mov   dx, SELFMODIFY_COLFUNC_JUMP_OFFSET24_NOLOOP_OFFSET+1
mov   bx, DRAWCOL_NOLOOP_OFFSET_MASKED
jmp   continue_selfmodifies_maskedsegrange
SELFMODIFY_MASKED_apply_stretch_tag_TARGET:
is_stretch_draw_2:
mov   dx, SELFMODIFY_COLFUNC_JUMP_OFFSET24_NOLOOPANDSTRETCH_OFFSET+1
mov   bx, DRAWCOL_NOLOOPSTRETCH_OFFSET_MASKED

continue_selfmodifies_maskedsegrange:
mov   word ptr cs:[SELFMODIFY_MASKED_COLFUNC_set_func_offset], bx
mov   word ptr cs:[SELFMODIFY_masked_set_jump_write_offset+1 - OFFSET R_MASK24_STARTMARKER_], dx

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
;ALIGN_MACRO

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
ALIGN_MACRO


SELFMODIFY_MASKED_lookup_2_TARGET:
lookup_FF_repeat:

;	if (texturecolumn >= maskednextlookup ||
; 		texturecolumn < maskedprevlookup

mul   byte ptr ds:[_maskedheightvalcache]
add   ax, word ptr ds:[_maskedcachedsegment]

mov   dx, word ptr ds:[_cachedbyteheight]  ; todo optimize this to a full word with 0 high byte in data. then optimize in _R_DrawSingleMaskedColumn_ as well

call R_DrawSingleMaskedColumn_

jmp   update_maskedtexturecol_finish_loop_iter
ALIGN_MACRO

; pixelsegment = FastMul8u8u((uint8_t) usetexturecolumn, maskedheightvalcache);
calculate_pixelsegment_mul:

mul   byte ptr ds:[_maskedheightvalcache]
jmp   go_draw_masked_column_repeat
ALIGN_MACRO

do_non_repeat:

mov   dh, ah	; todo why is ah needed
mov   ax, si
mov   ah, dh
sub   ax, di


;	if (lookup != 0xFF){
SELFMODIFY_MASKED_lookup_1:  
jmp   lookup_FF
SELFMODIFY_MASKED_lookup_1_AFTER:
;ALIGN_MACRO

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
ALIGN_MACRO

calculate_maskedheader_pixel_ofs:
; es:ax previously LESed
mov   bx, si
sub   bx, di
add   bx, bx
add   bx, ax
mov   ax, word ptr es:[bx]
jmp   go_draw_masked_column
ALIGN_MACRO

load_masked_column_segment_lookup:
mov   dx, si
SELFMODIFY_MASKED_texnum_1:
mov   ax, 08000h
call  R_GetMaskedColumnSegment_  


mov   di, word ptr ds:[_maskedcachedbasecol] ; todo return in di
mov   dx, word ptr ds:[_maskedcachedsegment]   ; to offset for above
sub   ax, dx

jmp   go_draw_masked_column
ALIGN_MACRO


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
ALIGN_MACRO

load_masked_column_segment:
mov   dx, si
SELFMODIFY_MASKED_texnum_2:
mov   ax, 08000h
call  R_GetMaskedColumnSegment_

mov   di, word ptr ds:[_maskedcachedbasecol] ; todo return in di
mov   dx, word ptr ds:[_cachedbyteheight]    ; todo optimize this to a full word with 0 high byte in data. then optimize in _R_DrawSingleMaskedColumn_ as well

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

ALIGN_MACRO

PROC   R_EvictL2CacheEMSPage_Sprite_Multi_ NEAR ; fairly optimized
PUBLIC R_EvictL2CacheEMSPage_Sprite_Multi_
push      cx
push      si   ; find a way to not use this? or reset to constant after call

xchg      ax, dx  ; dl gets numpages
mov       al, byte ptr ds:[_spritecache_l2_tail]
cbw      


;	// go back enough pages to allocate them all.
;	for (j = 0; j < numpages-1; j++){
;		currentpage = nodelist[currentpage].next;
;	}




 ; 2 page sprite case

mov       bx, ax
SHIFT_MACRO shl       bx, 2
mov       al, byte ptr ds:[bx + di + CACHE_NODE_PAGE_COUNT_T.cachenodecount_next]  ; get next

sub       dl, 2
jz        found_enough_pages

; 3 page sprite
mov       bx, ax
SHIFT_MACRO shl       bx, 2
mov       al, byte ptr ds:[bx + di + CACHE_NODE_PAGE_COUNT_T.cachenodecount_next]  ; get next

jmp       found_enough_pages
ENDP


ALIGN_MACRO
PROC   R_EvictL2CacheEMSPage_Sprite_Single_ NEAR ; fairly optimized
PUBLIC R_EvictL2CacheEMSPage_Sprite_Single_

; DONT USE BP, outer scope needs it maintained
push      cx
push      si   ; find a way to not use this? or reset to constant after call



;	currentpage = *nodetail;

mov       al, byte ptr ds:[_spritecache_l2_tail]  
cbw      

found_enough_pages:
public found_enough_pages

; ax = currentpage
cbw
push ax    ; store currentpage. ah is 0

; di is already _spritecache_nodes

; we store this here because we may go back and clear more pages 
; (if they are part of a contiguous allocation that were are evicting)
; but at the end, this is where we actually want to begin our allocation from - 
; and we will leave the extra pages empty on the tail.

;	evictedpage = currentpage;

xchg      ax, cx

; cx = evictedpage
; bx = becomes evictedpage CACHE_NODE_PAGE_COUNT_T ptr

;	while (nodelist[evictedpage].numpages != nodelist[evictedpage].pagecount){
;		evictedpage = nodelist[evictedpage].next;
;	}

; was this page part of a multipage allocation? then go back...
; bh, ch, ah zero
find_first_evictable_page:
mov       bx, cx
SHIFT_MACRO shl       bx, 2
mov       ax, word ptr ds:[bx + di + CACHE_NODE_PAGE_COUNT_T.cachenodecount_pagecount] ; ah has numpages. when pagecount = numpages this is the last page
cmp       al, ah
je        found_first_evictable_page
mov       cl, byte ptr ds:[bx + di + CACHE_NODE_PAGE_COUNT_T.cachenodecount_next]
jmp       find_first_evictable_page
ALIGN_MACRO

found_first_evictable_page:

; got to the end of the multipage (if any) allocaiton.
; now go back towards tail, remove things from cache until we reach 0FFh node

mov       dx, SPRITEPAGE_SEGMENT
mov       ds, dx                ; es..

; evict cache loop setup.
mov       dx, 0FFFFh      ; dh gets ff, dl gets ff

xchg      ax, cx                ; al gets furthest back page we are clearing. free cx for loop

; si = iter
; cx = maxitersize (for lodsb)
; al = evictedpage
; bx = evictedpage ptr

;	while (evictedpage != -1){

do_next_evicted_page:


; loop setup
mov       bl, al
mov       byte ptr ss:[bx + _usedspritepagemem], bh ; usedspritepagemem[evictedpage] = 0;

SHIFT_MACRO shl       bx 2



;		nodelist[evictedpage].pagecount = 0;
;		nodelist[evictedpage].numpages = 0;

xor       si, si                   ; zero for lods
mov       word ptr ss:[bx + di + CACHE_NODE_PAGE_COUNT_T.cachenodecount_pagecount], si    ; set both at once
mov       ah, al                ; clear al for lodsb

mov       cx, MAX_SPRITE_LUMPS


;    for (k = 0; k < maxitersize; k++){
;			if ((cacherefpage[k] >> 2) == evictedpage){
;				cacherefpage[k] = 0xFF;
;				cacherefoffset[k] = 0xFF;
;			}
;		}

; loop through every element in the list looking for this element.

ALIGN_MACRO
continue_first_cache_erase_loop:
lodsb
SHIFT_MACRO shr al 2
cmp       al, ah
je        edit_cache_entries                ; rare, assume fall through fail.
loop      continue_first_cache_erase_loop

done_with_first_cache_erase_loop:  ; sprites have no secondary cache loop




;		evictedpage = nodelist[evictedpage].prev;


mov       al, byte ptr ss:[bx + di + CACHE_NODE_PAGE_COUNT_T.cachenodecount_prev]     ; get prev
cmp       al, dl                   ; dl is 0FFh. have we reached the end of the list again?
jne       do_next_evicted_page

push      ss
pop       ds




mov       cl, byte ptr ds:[_spritecache_l2_tail] ; cx was 0 from loop ending
mov       ax, cx            ; ax/cx stores nodetail, ah gets 0

xchg      ax, bx            ; bx has nodelist nodetail lookup ; ah/bh still safely 0
SHIFT_MACRO shl       bx 2



;   connect old tail and old head.
;	nodelist[*nodetail].prev = *nodehead;
; cx holds tail. 
; bx holds tail ptr.
;  ax holds evicted page.

pop       ax         ; retrieve currentpage from way earlier
mov       si, ax     ; si gets currentpage hold onto this...
xchg      al, byte ptr ds:[_spritecache_l2_head] ; get old head. set currentpage as new head

mov       byte ptr ds:[bx + di + CACHE_NODE_PAGE_COUNT_T.cachenodecount_prev], al ; tail->prev = head
xchg      ax, bx ; bx gets old head

;	nodelist[*nodehead].next = *nodetail;
SHIFT_MACRO shl       bx 2  ; head ptr
mov       byte ptr ds:[bx + di + CACHE_NODE_PAGE_COUNT_T.cachenodecount_next], cl ;  head->next = tail
 
;	previous_next = nodelist[currentpage].next;
;	*nodehead = currentpage;
mov       bx, si ; bx gets current page
SHIFT_MACRO shl       bx 2

;	nodelist[currentpage].next = -1;
xchg      byte ptr ds:[bx + di + CACHE_NODE_PAGE_COUNT_T.cachenodecount_next], dl   

;	*nodetail = previous_next;
mov       bl, dl
mov       byte ptr ds:[_spritecache_l2_tail], dl

;	// new tail
;	nodelist[previous_next].prev = -1;

SHIFT_MACRO shl       bx 2
mov       byte ptr ds:[bx + di + CACHE_NODE_PAGE_COUNT_T.cachenodecount_prev], dh    ; dl not ff, but dh still 0FFh

;	return *nodehead;
xchg      ax, si   ; restore currentpage/new nodehead in ax


pop       si
pop       cx

ret       

edit_cache_entries:
mov       byte ptr ds:[si-1],  dl    ; 0FFh
mov       byte ptr ds:[si+MAX_SPRITE_LUMPS - 1], dl    ; 0FFh
loop      continue_first_cache_erase_loop
jmp       done_with_first_cache_erase_loop


ENDP






ALIGN_MACRO
PROC   R_MarkL2SpriteCacheMRU_ NEAR ; fairly optimized
PUBLIC R_MarkL2SpriteCacheMRU_

;	if (index == spritecache_l2_head) {
;		return;
;	}
; check done outside now


; wreck all regs

mov  si, OFFSET _spritecache_nodes
mov  di, OFFSET _spritecache_l2_head ; di + 1 is tail.
cbw
; ah assume 0?
; al = index
; cl = head
; bx is pointer
; TODO al is barely used! replace cl etc usage with it. smaller code?

mov  bx, ax  ; bx gets index..
mov  cl, byte ptr ds:[di] ; cl = head
mov  ch, -1

;	pagecount = spritecache_nodes[index].pagecount;
;	if (pagecount){

SHIFT_MACRO shl  bx 2
cmp  byte ptr ds:[bx + si + CACHE_NODE_PAGE_COUNT_T.cachenodecount_pagecount], bh ; 0
jne   selected_sprite_page_multi

selected_sprite_page_single_page:

;		// handle the simple one page case.
;		prev = spritecache_nodes[index].prev;
;		next = spritecache_nodes[index].next;

mov  dx, word ptr ds:[bx + si + CACHE_NODE_PAGE_COUNT_T.cachenodecount_prev]
; dl = prev
; dh = next

;		if (index == spritecache_l2_tail) {
;			spritecache_l2_tail = next;
;		} else {
;			spritecache_nodes[prev].next = next; 
;		}



cmp  al, byte ptr ds:[di + 1]   ; tail
jne  spritecache_tail_not_equal_to_index
mov  byte ptr ds:[di + 1], dh   ; tail

jmp  done_with_spritecache_tail_handling

ALIGN_MACRO
spritecache_tail_not_equal_to_index:
mov  bl, dl
SHIFT_MACRO shl  bx 2
mov  byte ptr ds:[bx + si + CACHE_NODE_PAGE_COUNT_T.cachenodecount_next], dh

done_with_spritecache_tail_handling:

; spritecache_nodes[next].prev = prev;  // works in either of the above cases. prev is -1 if tail.
mov  bl, dh
SHIFT_MACRO shl  bx 2
mov  byte ptr ds:[bx + si + CACHE_NODE_PAGE_COUNT_T.cachenodecount_prev], dl

;	spritecache_nodes[index].prev = spritecache_l2_head;
;	spritecache_nodes[index].next = -1;

mov  bl, al
SHIFT_MACRO shl  bx 2
mov  word ptr ds:[bx + si + CACHE_NODE_PAGE_COUNT_T.cachenodecount_prev], cx ; ch is -1

; spritecache_nodes[spritecache_l2_head].next = index;

mov  bl, cl
SHIFT_MACRO shl  bx 2
mov  byte ptr ds:[bx + si + CACHE_NODE_PAGE_COUNT_T.cachenodecount_next], al

;	spritecache_l2_head = index;

mov  byte ptr ds:[di], al
mark_sprite_lru_exit:
ret  

ALIGN_MACRO
selected_sprite_page_multi:
PUBLIC selected_sprite_page_multi
; multi page case...

;	 	while (spritecache_nodes[index].numpages != spritecache_nodes[index].pagecount){
;			index = spritecache_nodes[index].next;
;		}

sprite_check_next_cache_node:
mov  bl, al   ; bh always zero here...  ; initial case, i think this rechecks the first tile again. maybe we can set al to next before first iter?
SHIFT_MACRO shl  bx 2
mov  dx, word ptr ds:[bx + si + CACHE_NODE_PAGE_COUNT_T.cachenodecount_pagecount]
cmp  dl, dh
je   sprite_found_first_index
mov  al, byte ptr ds:[bx + si + CACHE_NODE_PAGE_COUNT_T.cachenodecount_next]
jmp  sprite_check_next_cache_node
ALIGN_MACRO

sprite_found_first_index:

;		if (index == spritecache_l2_head) {
;			return;
;		}

cmp  al, cl               ; dh is free, use dh instead here?
je   mark_sprite_lru_exit ; already MRU, no need to move anything!

; bx should already be set...

;	if (spritecache_nodes[index].numpages){
;		lastindex = index;
;		while (spritecache_nodes[lastindex].pagecount != 1){
;			lastindex = spritecache_nodes[lastindex].prev;
;		}


mov  dh, al         ; dh = last index
sprite_check_next_cache_node_pagecount:

mov  bl, dh         ; bh always 0 here...
SHIFT_MACRO  shl  bx 2
cmp  byte ptr ds:[bx + si + CACHE_NODE_PAGE_COUNT_T.cachenodecount_pagecount], 1
je   found_sprite_multipage_last_page
mov  dh, byte ptr ds:[bx + si + CACHE_NODE_PAGE_COUNT_T.cachenodecount_prev]
jmp  sprite_check_next_cache_node_pagecount
ALIGN_MACRO

found_sprite_multipage_last_page:

; al = index
; dh = lastindex
; ch = lastindex_prev
; cl = index_next
;		lastindex_prev = spritecache_nodes[lastindex].prev;
;		index_next = spritecache_nodes[index].next;


mov  ch, byte ptr ds:[bx + si + CACHE_NODE_PAGE_COUNT_T.cachenodecount_prev]    ; lastindex_prev
mov  bl, al
SHIFT_MACRO   shl  bx 2

mov  cl, byte ptr ds:[bx + si + CACHE_NODE_PAGE_COUNT_T.cachenodecount_next]    ; index_next

;		if (spritecache_l2_tail == lastindex){

cmp  dh, byte ptr ds:[di + 1] ; tail
jne  spritecache_l2_tail_not_equal_to_lastindex

;			spritecache_l2_tail = index_next;
;			spritecache_nodes[index_next].prev = -1;

mov  byte ptr ds:[di + 1], cl ; tail

mov  bl, cl
SHIFT_MACRO   shl  bx 2
mov  byte ptr ds:[bx + si + CACHE_NODE_PAGE_COUNT_T.cachenodecount_prev], ch ; - 1
jmp  sprite_done_with_multi_tail_update
ALIGN_MACRO

spritecache_l2_tail_not_equal_to_lastindex:

;			spritecache_nodes[lastindex_prev].next = index_next;
;			spritecache_nodes[index_next].prev = lastindex_prev;


mov  bl, ch
SHIFT_MACRO shl  bx 2
mov  byte ptr ds:[bx + si + CACHE_NODE_PAGE_COUNT_T.cachenodecount_next], cl

mov  bl, cl
SHIFT_MACRO shl  bx 2
mov  byte ptr ds:[bx + si + CACHE_NODE_PAGE_COUNT_T.cachenodecount_prev], ch

sprite_done_with_multi_tail_update:

;		spritecache_nodes[lastindex].prev = spritecache_l2_head;
;		spritecache_nodes[spritecache_l2_head].next = lastindex;

mov  bl, dh
SHIFT_MACRO    shl  bx 2
mov  dl, byte ptr ds:[di]
mov  byte ptr ds:[bx + si + CACHE_NODE_PAGE_COUNT_T.cachenodecount_prev], dl  ; spritecache_l2_head
mov  bl, dl
SHIFT_MACRO    shl  bx 2
mov  byte ptr ds:[bx + si + CACHE_NODE_PAGE_COUNT_T.cachenodecount_next], dh  ; lastindex

mov  bl, al
SHIFT_MACRO    shl  bx 2

;		spritecache_nodes[index].next = -1;
;		spritecache_l2_head = index;


mov  byte ptr ds:[di], al
mov  byte ptr ds:[bx + si + CACHE_NODE_PAGE_COUNT_T.cachenodecount_next], -1
ret  
ALIGN_MACRO





ENDP


; part of R_GetSpritePage_
ALIGN_MACRO

; todo any optimizations for lru1?
return_single_page_pos_0:
return_single_page_pos_1:
return_single_page_pos_2:
return_single_page_pos_3:
mov  si, OFFSET _spriteL1LRU
cmp  byte ptr ds:[si], bl
jne  update_sprite_lru_caches
 ; was spot 0; no need to update lru
;    return i;
xchg  ax, bx
ret   
ALIGN_MACRO
update_sprite_lru_caches:

;    R_MarkL1SpriteCacheMRU(i);
; bl holds i
; al holds realtexpage

xchg  ax, dx            ; dx gets realtexpage
mov   ax, bx            ; ax gets i

;call  R_MarkL1SpriteCacheMRU_  ; inlined
mov  ah, al
xchg ah, byte ptr ds:[si]  ; we know its not pos 0.
xchg ah, byte ptr ds:[si+1]

cmp  al, ah
je   exit_markl1spritecachemru_inline_1
xchg ah, byte ptr ds:[si+2]
cmp  al, ah
je   exit_markl1spritecachemru_inline_1
xchg ah, byte ptr ds:[si+3]
exit_markl1spritecachemru_inline_1:

;    R_MarkL2SpriteCacheMRU(realtexpage);

cmp   dl, byte ptr ds:[_spritecache_l2_head]
je    skip_l2_sprite_cache_marklru

; bx stores eventual return value
xchg  ax, dx            ; realtexpage into ax. 
push  bx ; eventual return value
push  cx ; wrecked by markl2
call  R_MarkL2SpriteCacheMRU_ 
pop   cx
pop   ax
;    return i;
ret
ALIGN_MACRO

skip_l2_sprite_cache_marklru:
xchg  ax, bx
ret   


ALIGN_MACRO
PROC   R_GetSpritePage_ NEAR ; seems more or less ok, maybe can improve a little bit. 
PUBLIC R_GetSpritePage_
; stack: dont wreck cx... thats it. outer frame eventually takes care of the rest.


mov   si, OFFSET _activespritepages
cbw



;	uint8_t realtexpage = texpage >> 2;
mov   bx, ax                        ; bh 0
SHIFT_MACRO sar   ax 2


;	uint8_t numpages = (texpage& 0x03);


and   bx, 3
;	if (!numpages) {                ; todo push less stuff if we get the zero case?
jnz   get_multipage_spritepage

; single page

;		// one page, most common case - lets write faster code here...
;		for (i = 0; i < NUM_SPRITE_L1_CACHE_PAGES; i++) {
;			if (_activespritepages[i] == realtexpage ) {
;				R_MarkL1SpriteCacheMRU(i);
;				R_MarkL2SpriteCacheMRU(realtexpage);
;				return i;
;			}
;		}

;    bh/bx known zero because we jumped otherwise.


; al is realtexpage
; bx is i
cmp   al, byte ptr ds:[bx + si]
je    return_single_page_pos_0
inc   bx
cmp   al, byte ptr ds:[bx + si]
je    return_single_page_pos_1
inc   bx
cmp   al, byte ptr ds:[bx + si]
je    return_single_page_pos_2
inc   bx
cmp   al, byte ptr ds:[bx + si]
je    return_single_page_pos_3

; cache miss...

;		startpage = _spriteL1LRU[NUM_SPRITE_L1_CACHE_PAGES-1];
;		R_MarkL1SpriteCacheMRU(startpage);

mov   bp, ax         ; bp holds onto copy of realtexpage  
;   ah is 0. al is dirty but gets fixed...
cwd
dec   dx ; dx = -1, ah is 0
push  cx
mov   di, OFFSET _activespritenumpages




mov   al, byte ptr ds:[_spriteL1LRU + (NUM_SPRITE_L1_CACHE_PAGES - 1)]   ; _spriteL1LRU[NUM_SPRITE_L1_CACHE_PAGES-1]
mov   bx, ax
mov   cx, ax
;call  R_MarkL1SpriteCacheMRU3_
; inlined
push word ptr ds:[_spriteL1LRU+1]     ; grab [1] and [2]
pop  word ptr ds:[_spriteL1LRU+2]     ; put in [2] and [3]
xchg al, byte ptr ds:[_spriteL1LRU+0] ; swap index for [0]
mov  byte ptr ds:[_spriteL1LRU+1], al ; put [0] in [1]


;		// if the deallocated page was a multipage allocation then we want to invalidate the other pages.
;		if (_activespritenumpages[startpage]) {
;			for (i = 1; i <= _activespritenumpages[startpage]; i++) {
;				_activespritepages[startpage+i]  = -1; // unpaged
;				//this is unmapping the page, so we don't need to use pagenum/nodelist
;				pageswapargs[pageswapargs_rend_texture_offset+( startpage+i)*PAGE_SWAP_ARG_MULT] = 
;					_NPR(PAGE_5000_OFFSET+startpage+i);
;				_activespritenumpages[startpage+i] = 0;
;			}
;		}

cmp   byte ptr ds:[bx + di], ah  ; ah is still 0. di is _activespritenumpages
je    found_start_page_single
; this l1 page is part of a multipage allocation. need to dump them all even though we are only getting a single page
mov   al, 1 ; al/ax is i
; cl/cx is start page.
; bx is startpage, becomes startpage + i offset
; dx is -1

deallocate_next_startpage_single:

cmp   al, byte ptr ds:[bx + di]  ; di is _activespritenumpages
ja    found_start_page_single

add   bl, al    ; startpage+i]
mov   byte ptr ds:[bx + di], ah  ; ah is 0


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

inc   ax ; i++


mov   bx, cx    ; zero out bh, set bx to startpage again
jmp   deallocate_next_startpage_single
ALIGN_MACRO

; get the segment address of a multipage sprite allocation.
get_multipage_spritepage:
PUBLIC get_multipage_spritepage

push  cx
mov   di, OFFSET _activespritenumpages
mov   bp, ax         ; bp holds onto copy of realtexpage  

; ah already zero
cwd              ; dx 0
mov   cx, NUM_SPRITE_L1_CACHE_PAGES
xchg  bx, dx     ; bx 0, dl is numpages-1

sub   cx, dx     ; NUM_SPRITE_L1_CACHE_PAGES-numpages
;  al/ax already realtexpage

; dl is numpages-1
; dh is 0
; cl is NUM_SPRITE_L1_CACHE_PAGES-numpages
; ch is 0
; bx will be i
; al is realtexpage


grab_next_page_loop_multi_continue:


; for (i = 0; i < NUM_SPRITE_L1_CACHE_PAGES-numpages; i++) {
;    if (_activespritepages[i] != realtexpage){
;        continue;
;    }

cmp   al, byte ptr ds:[bx + si]     ; _activespritepages
je    found_starting_multi_page
inc   bx
loop  grab_next_page_loop_multi_continue
jmp   evict_and_find_startpage_multi

ALIGN_MACRO
found_starting_multi_page:

;    // all pages for this texture are in the cache, unevicted.
;    for (j = 0; j <= numpages; j++) {
;        R_MarkL1SpriteCacheMRU(i+j);
;    }
mov   cx, bx

; cx backs up i
; bl/bx will be i+j   
; dx is numpages-1 but we dec it till < 0
; ends up 01 00... should it be 00 01? seems fine

mark_all_pages_mru_loop:
PUBLIC mark_all_pages_mru_loop
mov   ax, bx

;call  R_MarkL1SpriteCacheMRU_  ; inlined

mov  ah, byte ptr ds:[_spriteL1LRU+0]
cmp  al, ah
je   exit_markl1spritecachemru_inline_2
mov  byte ptr ds:[_spriteL1LRU+0], al
xchg byte ptr ds:[_spriteL1LRU+1], ah
cmp  al, ah
je   exit_markl1spritecachemru_inline_2
xchg byte ptr ds:[_spriteL1LRU+2], ah
cmp  al, ah
je   exit_markl1spritecachemru_inline_2
xchg byte ptr ds:[_spriteL1LRU+3], ah
exit_markl1spritecachemru_inline_2:

inc   bx    ; i + j
dec   dx    ; not dx; dx has a value!
jns   mark_all_pages_mru_loop
 

; cx contains i
;    R_MarkL2SpriteCacheMRU(realtexpage);
;    return i;

xchg  ax, bp    ; realtexpage in ap

cmp   al, byte ptr ds:[_spritecache_l2_head]
jne   do_l2_sprite_cache_marklru_4

xchg  ax, cx    
pop   cx
ret   

ALIGN_MACRO

do_l2_sprite_cache_marklru_4:
; ch has index..
push  cx ; eventual return value
call  R_MarkL2SpriteCacheMRU_
pop   ax
pop   cx
ret   

ALIGN_MACRO
 
;		// figure out startpage based on LRU
;		startpage = NUM_SPRITE_L1_CACHE_PAGES-1; // num EMS pages in conventional memory - 1

evict_and_find_startpage_multi:
PUBLIC evict_and_find_startpage_multi
; did not find all the pages in l1 cache
xor   ax, ax ; set ah to 0. 
mov   bx, NUM_SPRITE_L1_CACHE_PAGES - 1 + OFFSET _spriteL1LRU 

mov   cl, NUM_SPRITE_L1_CACHE_PAGES - 1  ; ch was already 0
sub   cl, dl
; dl is ; dl is numpages-1
; bx is startpage
; cx is ((NUM_SPRITE_L1_CACHE_PAGES-1)-numpages)

; start from last page of lru, work backward to find this page

find_start_page_loop_multi:

;		while (_spriteL1LRU[startpage] > ((NUM_SPRITE_L1_CACHE_PAGES-1)-numpages)){
;			startpage--;
;		}

mov   al, byte ptr ds:[bx]
cmp   al, cl
jle   found_startpage_multi
dec   bx
jmp   find_start_page_loop_multi
ALIGN_MACRO

found_start_page_single:

;		_activespritepages[startpage] = realtexpage; // FIRST_TEXTURE_LOGICAL_PAGE + pagenum;		
;  cl/cx is startpage
;  bl/bx is startpage 

mov   dx, bp
; dx has realtexpage
; bx already ok

mov   byte ptr ds:[bx + di], bh  ; activespritenumpages[startpage] = 0;
mov   byte ptr ds:[bx + si], dl  ; activespritepages[startpage] = realtexpage;
shl   bx, 1                      ; startpage word offset.
mov   ax, FIRST_SPRITE_CACHE_LOGICAL_PAGE

add   ax, dx                     ; _EPR(pageoffset + realtexpage);
EPR_MACRO ax

; pageswapargs[pageswapargs_rend_texture_offset+(startpage)*PAGE_SWAP_ARG_MULT]

SHIFT_PAGESWAP_ARGS bx
mov   word ptr ds:[bx + _pageswapargs + (PAGESWAPARGS_SPRITECACHE_OFFSET * 2)], ax        ; = _EPR(pageoffset + realtexpage);

;		R_MarkL2SpriteCacheMRU(realtexpage);


; dx is realtexpage
cmp   dl, byte ptr ds:[_spritecache_l2_head]
jne   do_l2_sprite_cache_marklru_3
push  cx ; eventual return value
Z_QUICKMAPAI4 pageswapargs_spritecache_offset_size INDEXED_PAGE_9000_OFFSET

; todo is this code path possible
mov   ax, 0FFFFh
mov   word ptr ds:[_lastvisspritepatch], ax
mov   word ptr ds:[_lastvisspritepatch2], ax
pop   ax  ; return value
pop   cx
ret

ALIGN_MACRO
do_l2_sprite_cache_marklru_3:
xchg  ax, dx
push  cx ; eventual return value
call  R_MarkL2SpriteCacheMRU_

;call  Z_QuickMapSpritePage_
Z_QUICKMAPAI4 pageswapargs_spritecache_offset_size INDEXED_PAGE_9000_OFFSET

mov   ax, 0FFFFh
mov   word ptr ds:[_lastvisspritepatch], ax
mov   word ptr ds:[_lastvisspritepatch2], ax

pop   ax  ; return value 
pop   cx
ret

ALIGN_MACRO

found_startpage_multi:
public found_startpage_multi
;		startpage = _spriteL1LRU[startpage];

; al already set to startpage
mov   bx, ax    ; ah/bh is 0

mov   dh, al ; dh gets startpage..
mov   cx, -1

;		// if the deallocated page was a multipage allocation then we want to invalidate the other pages.
;		if (_activespritenumpages[startpage] > numpages) {
;			for (i = numpages; i <= _activespritenumpages[startpage]; i++) {
;				_activespritepages[startpage + i] = -1;
;				// unmapping the page, so we dont need pagenum
;				pageswapargs[pageswapargs_rend_texture_offset+(startpage + i)*PAGE_SWAP_ARG_MULT] 
;					= _NPR(PAGE_5000_OFFSET+startpage+i); // unpaged
;				_activespritenumpages[startpage + i] = 0;
;			}
;		}


cmp   dl, byte ptr ds:[bx + di]  ; di is _activespritenumpages
jae   done_invalidating_pages_multi
mov   al, dl

; dl is numpages
; dh is startpage
; al is i
; ah is 0
; bx is startpage looxkup

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

inc   ax

xor   bx, bx
jmp   loop_next_invalidate_page_multi
ALIGN_MACRO



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
mov   es, bp

;    for (i = 0; i <= numpages; i++) {
;        R_MarkL1SpriteCacheMRU(startpage+i);
;        _activespritepages[startpage + i]  = currentpage;
;        _activespritenumpages[startpage + i] = numpages-i;
;        pageswapargs[pageswapargs_rend_texture_offset+(startpage + i)*PAGE_SWAP_ARG_MULT]  = _EPR(currentpage+pageoffset);
;        currentpage = spritecache_nodes[currentpage].prev;
;    }


loop_mark_next_page_mru_multi:

;	R_MarkL1SpriteCacheMRU(startpage+i);

mov   al, cl

;call  R_MarkL1SpriteCacheMRU_  ; inlined

mov  ah, byte ptr ds:[_spriteL1LRU+0]
cmp  al, ah
je   exit_markl1spritecachemru_inline_3
mov  byte ptr ds:[_spriteL1LRU+0], al
xchg byte ptr ds:[_spriteL1LRU+1], ah
cmp  al, ah
je   exit_markl1spritecachemru_inline_3
xchg byte ptr ds:[_spriteL1LRU+2], ah
cmp  al, ah
je   exit_markl1spritecachemru_inline_3
xchg byte ptr ds:[_spriteL1LRU+3], ah
exit_markl1spritecachemru_inline_3:


mov   ax, es ; currentpage in ax

mov   bl, cl
mov   byte ptr ds:[bx + di], ch   ;   _activespritenumpages[startpage + i] = numpages-i;
mov   byte ptr ds:[bx + si], al   ;	_activespritepages[startpage + i]  = currentpage;
sal   bx, 1             ; word lookup

add   ax, FIRST_SPRITE_CACHE_LOGICAL_PAGE
EPR_MACRO ax

;	pageswapargs[pageswapargs_rend_texture_offset+(startpage + i)*PAGE_SWAP_ARG_MULT]  = _EPR(currentpage+pageoffset);

SHIFT_PAGESWAP_ARGS bx
mov   word ptr ds:[bx + _pageswapargs + (PAGESWAPARGS_SPRITECACHE_OFFSET * 2)], ax

dec   ch    ; dec numpages - i
inc   cl    ; inc startpage + i

;    currentpage = _spritecache_nodes[currentpage].prev;
mov   bx, es ; currentpage
SHIFT_MACRO sal   bx 2
mov   bl, byte ptr ds:[bx + _spritecache_nodes]
xor   bh, bh
mov   es, bx
dec   dl
jns   loop_mark_next_page_mru_multi

;    R_MarkL2SpriteCacheMRU(realspritepage);
;    Z_QuickMapSpritePage();

mov   ax, bp
cmp   al, byte ptr ds:[_spritecache_l2_head]
jne   do_l2_sprite_cache_marklru_1


push  dx ; eventual return value
Z_QUICKMAPAI4 pageswapargs_spritecache_offset_size INDEXED_PAGE_9000_OFFSET



mov   ax, 0FFFFh

mov   word ptr ds:[_lastvisspritepatch], ax
mov   word ptr ds:[_lastvisspritepatch2], ax

pop   ax  ; return value
mov   al, ah
pop   cx
ret

ALIGN_MACRO
do_l2_sprite_cache_marklru_1:

push  dx ; eventual return value

call  R_MarkL2SpriteCacheMRU_

Z_QUICKMAPAI4 pageswapargs_spritecache_offset_size INDEXED_PAGE_9000_OFFSET
pop   dx
mov   ax, 0FFFFh ; this path let to -1

mov   word ptr ds:[_lastvisspritepatch], ax
mov   word ptr ds:[_lastvisspritepatch2], ax

mov   al, dh  ; numpages in al
pop   cx
ret

ENDP




IF COMPISA GE COMPILE_386
;call  FastDiv3232FFFF_   ; todo inline?

ALIGN_MACRO
    PROC   FastDiv3232FFFF_ NEAR    ; fairly optimized, could be inlined
    PUBLIC FastDiv3232FFFF_
    ; EDX:EAX as 00000000 FFFFFFFF

; if top 16 bits missing just do a 32 / 16

; continue fast_div_32_16_FFFF


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

   ; ?only write to dc_iscale_hi when nonzero.
   mov   byte ptr cs:[SELFMODIFY_MASKED_set_dc_iscale_hi+1 - OFFSET R_MASK24_STARTMARKER_], dl
   

   ret
   ;jmp FastDiv3232FFFF_done 

ELSE
   ALIGN_MACRO
   fast_div_32_16_FFFF:
   cwd

   xchg dx, cx   ; cx was 0, dx is FFFF
   div bx        ; after this dx stores remainder, ax stores q1
   xchg cx, ax   ; q1 to cx, ffff to ax  so div remaidner:ffff 
   div bx
   ; cx:ax is result 
   ; ch is known zero.
   mov word ptr cs:[SELFMODIFY_MASKED_apply_stretch_tag], 0C089h ; NOP  ; toggle stretch variant for this frame
   ; only write to dc_iscale_hi when nonzero.
   mov   byte ptr cs:[SELFMODIFY_MASKED_set_dc_iscale_hi+1 - OFFSET R_MASK24_STARTMARKER_], cl

   ;jmp FastDiv3232FFFF_done    ; todo branch better 

   ret
   ALIGN_MACRO  ; adding these back seems to lower bench scores

    PROC   FastDiv3232FFFF_ NEAR    ; fairly optimized, could be inlined
    PUBLIC FastDiv3232FFFF_
    mov  ax, -1
    jcxz fast_div_32_16_FFFF

   main_3232_div:
   push si
  ; todo dont use di, use dx instead


   ; generally cx maxes out at around 5 bits of precision? bias towards shift right instead of left.  

   xor si, si ; zero this out to get high bits of numhi
   xor dx, dx

   shr cx, 1
   jz  done_shifting_3232
   rcr bx, 1
   rcr dx, 1
   shr ax, 1
   rcr si, 1


   shr cx, 1
   jz  done_shifting_3232
   rcr bx, 1
   rcr dx, 1
   shr ax, 1
   rcr si, 1

   shr cx, 1
   jz  done_shifting_3232
   rcr bx, 1
   rcr dx, 1
   shr ax, 1
   rcr si, 1

   shr cx, 1
   jz  done_shifting_3232
   rcr bx, 1
   rcr dx, 1
   shr ax, 1
   rcr si, 1

   shr cx, 1
   jz  done_shifting_3232
   rcr bx, 1
   rcr dx, 1
   shr ax, 1
   rcr si, 1

   shr cx, 1
   jz  done_shifting_3232
   rcr bx, 1
   rcr dx, 1
   shr ax, 1
   rcr si, 1

   shr cx, 1
   ; todo shouldnt fall thru here? if it does may crash with dxvide overflow down the line.

   ; store this
   done_shifting_3232:

   ; continue the last bit
   rcr bx, 1
   rcr dx, 1
    ; todo bench branch
   jnz do_full_div_ffff

   do_single_div_FFFF:
   ; bx has entire dividend, in 16 bits of precision. we know cx and di are zero after all.
   ; si contains a bit count of how much to shift result left by...

   shr ax, 1   ; still gotta continue to shift the last ax/si
   rcr si, 1

   ; i want to skip last rcr si but it makes detecting the 0 case hard.
   dec  dx        ; make it 0FFFFh
   xchg ax, dx    ; ax all 1s,  dx 0 leading 1s
   div  bx

   ; cx is zero already coming in from the first shift so cx:ax is already the result.

   mov   word ptr cs:[SELFMODIFY_MASKED_apply_stretch_tag], ((SELFMODIFY_MASKED_apply_stretch_tag_TARGET - SELFMODIFY_MASKED_apply_stretch_tag_AFTER) SHL 8) + 0EBh  ; jmp 8 turn on stretch variant for this frame
   ;xor   dx, dx
   pop   si
   ret
   ;jmp FastDiv3232FFFF_done_restore_si  
   ALIGN_MACRO

   do_full_div_ffff:
   shr ax, 1
   rcr si, 1

   ; todo shift into the right places, reduce juggle

   mov  cx, bx  ; dividend hi
   mov  bx, dx  ; dividend lo


   xchg ax, si
   cwd          ; dx 0FFFFh again. si hi bit is 1 for sure.



   ; SI:DX:AX holds divisor...
   ; CX:BX holds dividend...
   ; numhi = SI:DX
   ; numlo = AX:00...

   ; save numlo word in es
   mov es, ax 


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

   mov   word ptr cs:[_SELFMODIFY_get_qhat+1], ax     ; store qhat. use div's prefetch to juice this...

   mov   bx, dx					; bx stores rhat

   mul   si   						; DX:AX = c1


   ; c1 hi = dx, c2 lo = es
   sub   dx, bx      ; cmp and sub at same time... 


   jb    q1_ready_3232
   mov   bx, es   ; bx get numlo

   jne   check_c1_c2_diff_3232
   cmp   ax, bx
   jbe   q1_ready_3232
   check_c1_c2_diff_3232:

   ; (c1 - c2.wu > den.wu)
   sub   ax, bx
   sbb   dx, 0    ; already subbed without borrow.
   cmp   dx, cx
   mov   bx, 1                
   ja    qhat_subtract_2_3232
   jne   finalize_div


   ; compare low word..
   cmp   ax, si
   jbe   finalize_div

   ; ugly but rare occurrence i think?
   qhat_subtract_2_3232:
   inc  bx
   jmp finalize_div
   ALIGN_MACRO  ; adding these back seems to lower bench scores


   q1_ready_3232:
   mov  bx, 0   ; no sub case
   finalize_div:
   _SELFMODIFY_get_qhat:
   mov  ax, 01000h

   sub  ax, bx ; modify qhat by measured amount


   mov   word ptr cs:[SELFMODIFY_MASKED_apply_stretch_tag], ((SELFMODIFY_MASKED_apply_stretch_tag_TARGET - SELFMODIFY_MASKED_apply_stretch_tag_AFTER) SHL 8) + 0EBh  ;  turn on stretch variant for this frame

   FastDiv3232FFFF_done_restore_si:
   
   pop   si
   FastDiv3232FFFF_done:
   ret
   ENDP

ENDIF









;R_PointOnSegSide_

ALIGN_MACRO
PROC   R_PointOnSegSide_ NEAR  ; needs another look
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

SHIFT_MACRO shl si 3   ; todo preshift? (drawseg_cursegvalue)


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
ALIGN_MACRO

;        return ly < ldy;

return_ly_below_ldy:
cmp  di, ax
jge  return_false

return_true:
mov   ax, 1
LEAVE_MACRO
pop   di
ret   
ALIGN_MACRO

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
ALIGN_MACRO
ret_ldx_less_than_lx:

;            return ldx < lx;

cmp    si, bx

jle    return_true

; return false
xor   ax, ax

LEAVE_MACRO
pop   di
ret   
ALIGN_MACRO
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
ALIGN_MACRO

check_lowbits:
pop   cx ;  old AX
cmp   ax, cx
jb    return_false_2
return_true_2:
mov   ax, 1

LEAVE_MACRO
pop   di
ret   
ALIGN_MACRO
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



SIL_NONE =   0
SIL_BOTTOM = 1
SIL_TOP =    2
SIL_BOTH =   3





END_OF_VISSPRITE_SORTED_LOOP   = 0


ALIGN_MACRO
PROC   R_DrawMasked24_ FAR   ; fairly optimized? doesnt run much, procedural
PUBLIC R_DrawMasked24_

PUSHA_NO_AX_OR_BP_MACRO
push  bp
mov   bp, sp




;    if (vissprite_p > 0) {
mov       bx, OFFSET _vissprites
mov       ax, word ptr ds:[_vissprite_p]

cmp  ax, bx
jbe  done_drawing_sprites ; no sprites.

;call R_SortVisSprites_  ; inlined

; di stores vsprsortedheadprev
; bp stores unsorted
; si stores best
; ax stores iterator

; no need to check for count on inside, we already check on outside.

push      bp
mov       bp, bx         ; back up &vissprites[0]
mov       di, OFFSET _vsprsortedhead

; create default list
;   for (ds=vissprites ; ds<vissprite_p ; ds++) {
;	    ds->next = ds+1;
;   	ds->prev = ds-1;
;   }


loop_set_vissprite_next:
; bx is current counter

mov       word ptr ds:[bx + VISSPRITE_T.vs_prev], si ; ds->prev = ds-1;  first iter sets this to garbage, clean up later
mov       si, bx                    ; si = ds
add       bx, (SIZE VISSPRITE_T)  
mov       word ptr ds:[si + VISSPRITE_T.vs_next], bx   ; ds->next = ds+1;
cmp       bx, ax    ; ax is vissprite_p
jb        loop_set_vissprite_next

done_setting_vissprite_next:

; unsorted will be sp, so sp + 0 = next, sp + 2 = prev.
push      si ; unsorted->prev = vissprite_p - 1
push      bp ; unsorted->next = vissprites[0]
mov       word ptr ss:[bp + VISSPRITE_T.vs_prev], sp ; vissprites[0].prev = &unsorted;
mov       word ptr ds:[si + VISSPRITE_T.vs_next], sp ; (vissprite_p-1)->next = &unsorted;

mov       bp, sp   ; finally set bp to unsorted for the rest of the function

;    vsprsortedhead.next = vsprsortedhead.prev = &vsprsortedhead;
mov       word ptr ds:[di + VISSPRITE_T.vs_next], di ; vsprsortedhead.prev = &vsprsortedhead;
mov       word ptr ds:[di + VISSPRITE_T.vs_prev], di ; vsprsortedhead.next = &vsprsortedhead;



loop_vissprite_sort:


;DX:CX is bestscale

; bp is unsorted
; bx is ds
; si is best


; instead of maxlong, just set it to the first one... inlined first iteration
mov       bx, word ptr ss:[bp + VISSPRITE_T.vs_next]    ; ds = unsorted.next
; could just jmp unsorted_next_is_best_next here
les       cx, dword ptr ds:[bx + VISSPRITE_T.vs_scale]
mov       dx, es        ;	bestscale = ds->scale;
mov       si, bx        ;   best = ds;
mov       bx, word ptr ds:[bx + VISSPRITE_T.vs_next]
cmp       bx, bp        ; ds!= &unsorted
je        done_with_sort_subloop


loop_sort_subloop:

cmp       dx, word ptr ds:[bx + VISSPRITE_T.vs_scale + 2]
jg        unsorted_next_is_best_next
jne       iter_next_find_best_index_loop
cmp       cx, word ptr ds:[bx + VISSPRITE_T.vs_scale]
jbe       iter_next_find_best_index_loop
unsorted_next_is_best_next:

les       cx, dword ptr ds:[bx + VISSPRITE_T.vs_scale]
mov       dx, es        ;	bestscale = ds->scale;
mov       si, bx        ;   best = ds;

iter_next_find_best_index_loop:

mov       bx, word ptr ds:[bx + VISSPRITE_T.vs_next]
cmp       bx, bp  ; ds!= &unsorted
jne       loop_sort_subloop

done_with_sort_subloop:


;	best->next->prev = best->prev;
;	best->prev->next = best->next;
;	best->next = &vsprsortedhead;
;	best->prev = vsprsortedhead.prev;
;	vsprsortedhead.prev->next = best;
;	vsprsortedhead.prev = best;


mov       bx, word ptr ds:[si + VISSPRITE_T.vs_next]   ; bx = best->next
mov       dx, word ptr ds:[si + VISSPRITE_T.vs_prev]   ; dx = best->prev

mov       word ptr ds:[bx + VISSPRITE_T.vs_prev], dx   ; best->next->prev = best->prev;
xchg      bx, dx
mov       word ptr ds:[bx + VISSPRITE_T.vs_next], dx   ; best->prev->next = best->next;

mov       word ptr ds:[si + VISSPRITE_T.vs_next], di   ; best->next = &vsprsortedhead;

mov       bx, word ptr ds:[di + VISSPRITE_T.vs_prev]   ; bx = vsprsortedhead.prev
mov       word ptr ds:[si + VISSPRITE_T.vs_prev], bx   ; best->prev = vsprsortedhead.prev;
mov       word ptr ds:[bx + VISSPRITE_T.vs_next], si   ; vsprsortedhead.prev->next = best;
mov       word ptr ds:[di + VISSPRITE_T.vs_prev], si   ; vsprsortedhead.prev = best;

sub       ax, SIZE VISSPRITE_T
cmp       ax, OFFSET _vissprites ; iterate once per vissprite_p; ax started as vissprite_p and _vissprites is array base
jg        loop_vissprite_sort

exit_sort_vissprites:
pop        ax
pop        ax ; add sp, 4
pop        bp

; di is still _vsprsortedhead
mov        bx, word ptr ds:[di + VISSPRITE_T.vs_next]  ; set up bx for following loop

; END R_SortVisSprites_

;	for (spr = vsprsortedheadfirst ;
;       spr != END_OF_VISSPRITE_SORTED_LOOP ;
;       spr=vissprites[spr].next) {
;       R_DrawSprite (&vissprites[spr]);
;   }


; SET FUNCTION CONSTANTS FOR DRAWSPRITE LOOP 

PUSH_MACRO_WITH_REG dx DRAWSEGS_BASE_SEGMENT  ; bp - 2


jmp  R_DrawSprite_  ; draw first sprite
ALIGN_MACRO


done_drawing_sprites:

mov   sp, bp ; undo stack. sp should be bp - 2.
; now start iterating drawsegs for masked seg ranges
les  di, dword ptr ds:[_ds_p]
sub  di, (SIZE DRAWSEG_T)

jle  done_rendering_masked_segranges

check_next_seg:
cmp  word ptr es:[di + DRAWSEG_T.drawseg_maskedtexturecol_val], NULL_TEX_COL
je   not_masked

mov  ax, word ptr es:[di + DRAWSEG_T.drawseg_x1]
mov  cx, word ptr es:[di + DRAWSEG_T.drawseg_x2]

call R_RenderMaskedSegRange_
mov  es, word ptr ds:[_ds_p + 2] ; retrieve segment
not_masked:
sub  di, (SIZE DRAWSEG_T)

ja   check_next_seg
done_rendering_masked_segranges:
;call R_DrawPlayerSprites_  ; inlined


; todo some sort of special draw unclipped sprite function? can scale lookups also be optimized?
mov  word ptr ds:[_mfloorclip], OFFSET_SCREENHEIGHTARRAY 
mov  word ptr ds:[_mceilingclip], OFFSET_NEGONEARRAY 

cmp  word ptr ds:[_psprites + PSPDEF_T.pspdef_statenum], -1  ; STATENUM_NULL
je  check_next_player_sprite
mov  si, _player_vissprites       ; vissprite 0
les  ax, dword ptr ds:[si + VISSPRITE_T.vs_xiscale]
mov  dx, es
call R_DrawPlayerVisSprite_

check_next_player_sprite:
cmp  word ptr ds:[_psprites + (SIZE PSPDEF_T) +  PSPDEF_T.pspdef_statenum], -1  ; STATENUM_NULL
je   exit_drawplayersprites
mov  si, _player_vissprites + (SIZE VISSPRITE_T)
les  ax, dword ptr ds:[si + VISSPRITE_T.vs_xiscale]
mov  dx, es
call R_DrawPlayerVisSprite_

exit_drawplayersprites:


exit_draw_masked:
LEAVE_MACRO
POPA_NO_AX_OR_BP_MACRO
retf

ENDP


; LOOP EXTRA CALLS TO DRAWSPRITE HERE

done_with_drawsprite:
pop  bx   ; bp - 4
no_draw:            ; in theory this doesnt need a pop, but its rare and otherwise we cant balance stack.

mov  bx, word ptr ds:[bx + VISSPRITE_T.vs_next]


cmp  bx, OFFSET _vsprsortedhead
je   done_drawing_sprites   ; todo jne to R_DrawSprite instead

; fall thru to R_DrawSprite_

ALIGN_MACRO
PROC   R_DrawSprite_ NEAR  ; fairly optimized
PUBLIC R_DrawSprite_
; bp - 2	   ds_p segment.  always DRAWSEGS_BASE_SEGMENT
; bp - 4 not set yet but becomes bx/current vissprite
; bp - 6 not set yet but becomes bx/current vissprite

; bx is already the sprite

les   si, dword ptr ds:[bx + VISSPRITE_T.vs_x1]
mov   cx, es    
sub   cx, si
jl    no_draw   ; no pixels
push  bx        ; bp - 4h   ; for next loop
push  bx        ; bp - 6h   ; for si later


; write these ahead into immediates in the drawseg loop.
mov   word ptr cs:[SELFMODIFY_MASKED_vissprite_x1_1+1], si
mov   word ptr cs:[SELFMODIFY_MASKED_vissprite_x1_2+1], si
mov   word ptr cs:[SELFMODIFY_MASKED_vissprite_x2_1+1], es
mov   word ptr cs:[SELFMODIFY_MASKED_vissprite_x2_2+1], es
mov   word ptr cs:[SELFMODIFY_MASKED_vissprite_x2_3+1], es
; todo any others? some (vs_scale + 2) situations look intriguing



;	for (x = spr->x1; x <= spr->x2; x++) {
;		clipbot[x] = cliptop[x] = -2;
;	}
    
; init clipbot, cliptop

inc   cx				   ; for the equals case.
shl   si, 1                ; word offset
lea   di, [si + CLIPTOP_START_OFFSET]
mov   ax, cs
mov   es, ax
push  cx                   ; bp - 8 count  for use in later loop
push  cx                   ; bp - 0Ah backup for iter 2
mov   ax, UNCLIPPED_COLUMN ; -2
rep   stosw
lea   di, [si + CLIPBOT_START_OFFSET]
pop   cx                   ; bp - 0Ah restore for iter 2
push  di                   ; bp - 0Ah clipbot start offset for use in later loop

rep   stosw

no_clip:

; di equals ds_p offset
mov   di, word ptr ds:[_ds_p]
sub   di, SIZE DRAWSEG_T	
jz   done_masking  ; no drawsegs! i suppose possible on a map edge.
mov   es, word ptr [bp - 2] ; DRAWSEGS_BASE_SEGMENT

check_loop_conditions:

; compare ds->x1 > spr->x2
mov   ax, word ptr es:[di + DRAWSEG_T.drawseg_x1]
SELFMODIFY_MASKED_vissprite_x2_1:
cmp   ax, 01000h    ; maybe put this in ax from outside the loop...?
jng   continue_checking_if_drawseg_obscures_sprite

iterate_next_drawseg_loop:
; note: es and bx dont necessaryly go together.
; es is paired with di and ds with bx.
les   bx, dword ptr [bp - 4] 
iterate_next_drawseg_loop_dont_restore_esbx:
sub   di, SIZE DRAWSEG_T   
jnz   check_loop_conditions

done_masking:

pop  si   ; bp - 0Ah get clipbot
pop  cx   ; bp - 8 get count back


mov   bx, CLIPTOP_START_OFFSET - CLIPBOT_START_OFFSET;  (SCREENWIDTH * 2)  ; clip top

mov   ax, cs
mov   ds, ax

SELFMODIFY_MASKED_viewheight_2:
mov   ax, 01000h
mov   dx, 0FFFFh
mov   es, dx
dec   dx        ; UNCLIPPED_COLUMN, -2
; ds is cs here

loop_clipping_columns:

; would this be faster with scas pattern?
; ANSWER: no! tested. 
; scan_for_next_instance:
; repne scasb
; mov   byte ptr ds:[di-1], ah
; jnz scan_for_next_instance

cmp   word ptr ds:[si], dx ; UNCLIPPED_COLUMN -2
jne   dont_clip_bot
mov   word ptr ds:[si], ax
dont_clip_bot:
cmp   word ptr ds:[si+bx], dx ; UNCLIPPED_COLUMN -2
jne   dont_clip_top
mov   word ptr ds:[si+bx], es  ; 0FFFFh
dont_clip_top:
sub   si, dx ; add 2 by sub -2
loop loop_clipping_columns

mov   ax, ss
mov   ds, ax    ; restore ds



; could also be the segments and not the offsets.
pop   si      ; vissprite pointer from bp - 6

mov   word ptr ds:[_mfloorclip], CLIPBOT_START_OFFSET   ; todo sucks... maybe have drawvissprite use a different ptr than maskedsegrange?
mov   word ptr ds:[_mfloorclip + 2], cs

mov   word ptr ds:[_mceilingclip], CLIPTOP_START_OFFSET
mov   word ptr ds:[_mceilingclip + 2], cs

call  R_DrawVisSprite_
; restore bx, because R_DrawVisSprite_ does naughy things to stack and cant be trusted
mov   word ptr ds:[_mceilingclip + 2], OPENINGS_SEGMENT
mov   word ptr ds:[_mfloorclip + 2], OPENINGS_SEGMENT

; sp should be bp - 4 again

jmp  done_with_drawsprite
ALIGN_MACRO

continue_checking_if_drawseg_obscures_sprite:
; compare (ds->x2 < spr->x1)
mov   ax, word ptr es:[di + DRAWSEG_T.drawseg_x2]
cmp   ax, word ptr ds:[bx + VISSPRITE_T.vs_x1]   ; todo i think comparatively rare and maybe not worth the selfmodify. test?
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
je    compare_lowbits_scale1_scale2

scale1_smaller_than_scale2:

;lowscalecheckpass = ds->scale1 < spr->scale;
; ax:dx is ds->scale2

cmp   cx, word ptr ds:[bx + VISSPRITE_T.vs_scale + 2]
jl    set_r1_r2_and_render_masked_set_range
jne   lowscalecheckpass_set_route2
cmp   si, word ptr ds:[bx + VISSPRITE_T.vs_scale + 0]
jae   lowscalecheckpass_set_route2
jmp   set_r1_r2_and_render_masked_set_range
ALIGN_MACRO


compare_lowbits_scale1_scale2:
cmp   dx, si
jbe   scale1_smaller_than_scale2
scale1_highbits_larger_than_scale2:
;   bx is vissprite..
;			scalecheckpass = ds->scale1 < spr->scale;

;ax:dx = scale1

; if scalecheckpass is 0, go calculate lowscalecheck pass. 
; if not, the following if/else fails and we skip out early

cmp   ax, word ptr ds:[bx + VISSPRITE_T.vs_scale + 2]  ; todo consider selfmodify
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
SELFMODIFY_MASKED_vissprite_x1_1:
mov   cx, 01000h
cmp   ax, cx
jge   r1_stays_ds_x1
xchg  ax, cx  ; ax gets spr->x1
r1_stays_ds_x1:

; r2 = ds->x2 > spr->x2 ? spr->x2 : ds->x2;
; set r2 as the minimum of the two.
SELFMODIFY_MASKED_vissprite_x2_2:
mov   cx, 01000h
mov   dx, word ptr es:[di + DRAWSEG_T.drawseg_x2]
cmp   cx, dx
jle    r2_stays_ds_x2

mov   cx, dx

r2_stays_ds_x2:



call  R_RenderMaskedSegRange_
jmp   iterate_next_drawseg_loop
ALIGN_MACRO

get_lowscalepass_1:

;			lowscalecheckpass = ds->scale2 < spr->scale;

;dx:bx = ds->scale2

cmp   cx, word ptr ds:[bx + VISSPRITE_T.vs_scale + 2] ; todo selfmodify?
jl    do_R_PointOnSegSide_check
jne   failed_check_pass_set_r1_r2
cmp   si, word ptr ds:[bx + VISSPRITE_T.vs_scale + 0]
jae   failed_check_pass_set_r1_r2

jmp   do_R_PointOnSegSide_check
ALIGN_MACRO
jump_to_iterate_next_drawseg_loop:
jmp   iterate_next_drawseg_loop_dont_restore_esbx
ALIGN_MACRO



lowscalecheckpass_set_route2:
;scalecheckpass = ds->scale2 < spr->scale;
; ax:dx is still ds->scale1


cmp   ax, word ptr ds:[bx + VISSPRITE_T.vs_scale + 2] ; todo selfmodify?
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
SELFMODIFY_MASKED_vissprite_x1_2:
mov   cx, 01000h
cmp   si, cx
jnl   r1_set
spr_x1_smaller_than_ds_x1:
mov   si, cx
r1_set:

;		r2 = ds->x2 > spr->x2 ? spr->x2 : ds->x2;

SELFMODIFY_MASKED_vissprite_x2_3:
mov   dx, 01000h
mov   cx, word ptr es:[di + DRAWSEG_T.drawseg_x2]	; spr->x2
cmp   cx, dx 		; ds->x2
jng   r2_set


spr_x2_greater_than_dx_x2:
mov   cx, dx
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
SHIFT32_MACRO_RIGHT ax, dx, 3

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
SHIFT32_MACRO_RIGHT ax, dx, 3


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
ALIGN_MACRO

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
ALIGN_MACRO

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
ALIGN_MACRO

ENDP



; ax pixelsegment
; cx:bx column
; todo: use es:si instead of cx:bx. lodsw and compare al as 0FFh right away. si then shouldnt need to be preserved.

;
; R_DrawMaskedColumn
;

exit_draw_masked_column_early:
ret

; three uses... two in maskedsegrange one in drawvissprite?
; revisit what really needs to be push/popped

	
ALIGN_MACRO
PROC   R_DrawMaskedColumn_ NEAR ; fairly optimized
PUBLIC R_DrawMaskedColumn_

; todo: synergy with outer function... cx and es
; todo push/pop fewer?

mov   es, cx

cmp   byte ptr es:[bx + COLUMN_T.column_topdelta], 0FFh
je    exit_draw_masked_column_early

; no early out, properly run the function. note fixed stack frame

push  dx
push  si
push  di
push  bp

mov   word ptr cs:[SELFMODIFY_MASKED_set_base_segment+1], ax
mov   si, bx        ; si now holds column address.
; es:si is now column

; dc_texturemid already set pre call.

; look up loop constants which involve segment juggling (floor/ceil clips)

mov   byte ptr cs:[SELFMODIFY_MASKED_add_currentoffset+1], 0

mov   bx, word ptr ds:[_dc_x]
mov   word ptr cs:[SELFMODIFY_MASKED_drawmaskedcolumn_set_dc_x+1], bx
sal   bx, 1                             ; word lookup
lds   di, dword ptr ds:[_mfloorclip]
mov   ax, word ptr ds:[bx+di]
mov   word ptr cs:[SELFMODIFY_MASKED_set_mfloorclip_dc_x_lookup+1], ax
lds   di, dword ptr ss:[_mceilingclip]
mov   ax, word ptr ds:[bx+di]
mov   word ptr cs:[SELFMODIFY_MASKED_set_mceilingclip_dc_x_lookup+1], ax

mov   ax, ss
mov   ds, ax   ; restore ds...


lods  word ptr es:[si]  ; load column for first iter

draw_next_column_patch:

push  es   ; retrieve after R_DrawColumnPrepMaskedMulti call. 
push  si   ; retrieve after R_DrawColumnPrepMaskedMulti call. 

; ax contains column fields!

;        topscreen.w = sprtopscreen + FastMul16u32u(column->topdelta, spryscale.w);


mov   byte ptr cs:[SELFMODIFY_MASKED_sub_topdelta + 2], al
mov   byte ptr cs:[SELFMODIFY_MASKED_set_last_offset + 1], ah

; calculate dc_yl (topdelta * scale)

xor   cx, cx
mov   cl, al      ; al 0, cx = 0 extended topdelta for mul

xchg  ax, bx      ; back column field up in bx

xor   ax, ax  ; ax = 0
cwd           ; dx = 0

les   di, dword ptr ds:[_spryscale]
mov   bp, es

jcxz  skip_topdelta_mul

mov   ax, bp

; todo this is actually mul 8x32. is there a faster way involving 8 bit muls?
;inlined fastmul16u32u

MUL  CX        ; AX * CX
XCHG CX, AX    ; store low product to be high result. Retrieve orig AX
MUL  DI        ; AX * DI
ADD  DX, CX    ; add prev low result to high word

skip_topdelta_mul:

add   ax, word ptr ds:[_sprtopscreen]       ; are these lowbits ever nonzero? yes, usually so
adc   dx, word ptr ds:[_sprtopscreen+2]

; topscreen = DX:AX.

;		dc_yl = topscreen.h.intbits; 
;		if (topscreen.h.fracbits)
;			dc_yl++;

xor  si, si
neg  ax
adc  si, dx  ; si stores dc_yl
neg  ax



; calculate dc_yh ((length * scale))

mov  cl, bh   ; cached length. bx now free to use. ch already was 0

xchg ax, bp   ;  ax gets spyscale+2 back. bp stores old topscreen low
mov  bx, dx   ;  bx:bp stores old topscreen result

;        bottomscreen.w = topscreen.w + FastMul16u32u(column->length, spryscale.w);

; ax:bx spryscale

; todo can this be 8 bit mul without the xor ch or not
;inlined fastmul16u32u
MUL  CX        ; AX * CX
XCHG CX, AX    ; store low product to be high result. Retrieve orig AX
MUL  DI        ; AX * DI
ADD  DX, CX    ; add prev low result to high word


; add cached topscreen
add   ax, bp
adc   dx, bx

;		dc_yh = bottomscreen.h.intbits;
;		if (!bottomscreen.h.fracbits)
;			dc_yh--;

neg ax
sbb dx, 0FFFFh  ; we actually want to simultaneously add one back to this. has to do with the >= case and is made up for with jmp lookup

mov   di, dx  ; would be nice to get this without a register juggle


; dx is dc_yh but needs to be written back 
; dc_yh, dc_yl are set (di, si)
        



;        if (dc_yh >= mfloorclip[dc_x])
;            dc_yh = mfloorclip[dc_x]-1;

; todo look these up otuside of loop 
; alternatively store dc_x in bp/di/si?


SELFMODIFY_MASKED_set_mfloorclip_dc_x_lookup:
mov   cx, 01000h
cmp   di, cx
jl    skip_floor_clip_set
mov   di, cx
dec   di        ; todo bake this into the lookup
skip_floor_clip_set:


;        if (dc_yl <= mceilingclip[dc_x])
;            dc_yl = mceilingclip[dc_x]+1;

SELFMODIFY_MASKED_set_mceilingclip_dc_x_lookup:
mov   cx, 01000h

cmp   si, cx
jg    skip_ceil_clip_set
mov   si, cx
inc   si        ; todo bake this into the lookup
skip_ceil_clip_set:


sub   di, si   ; di is dc_yh
jl    increment_column_and_continue_loop

SELFMODIFY_MASKED_dc_texturemid_hi_1:
mov   cl, 010h;  dc_texturemid intbits

SELFMODIFY_MASKED_set_base_segment:
mov   ax, 01000h    ; preshifted right 4 


SELFMODIFY_MASKED_add_currentoffset:
db 05, 00, 00    ; add ax, 0000 (word)  ; always a single low byte actually

mov   word ptr ds:[_dc_source_segment], ax

SELFMODIFY_MASKED_sub_topdelta:
sub    cl, 010h          ; subtract tex top offset. si = si+1
; cl = dc_texturemid hi. carry this into the call


;call  R_DrawColumnPrepMaskedMulti_  ; INLINED

; dc_yl is si
; dc_yh is di
; dc_x not loaded.


; cl:?? currently has dc_texturemid

; si is already dc_yl
; di is already dc_yh
SELFMODIFY_MASKED_drawmaskedcolumn_set_dc_x:
mov   ax, 01000h

mov   bx, (COLFUNC_FILE_START_SEGMENT - COLORMAPS_MASKEDMAPPING_SEG_DIFF)
mov   ds, bx                                 ; store this segment for now, with offset pre-added

; shift ax by (2 - detailshift.)
SELFMODIFY_MASKED_multi_detailshift_2_minus_16_bit_shift:
sar   ax, 1
sar   ax, 1


; di already subtracted above
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

; cl:si is dc_texturemid
; ch:bx is dc_iscale
; pass in xlat offset for bx via bp



SELFMODIFY_MASKED_set_dc_iscale_lo:
mov   bx, 01000h ; dc_iscale +0
SELFMODIFY_MASKED_set_dc_iscale_hi:
mov   ch, 010h ; dc_iscale +1
SELFMODIFY_MASKED_dc_texturemid_lo_1:
mov   si, 01000h        ; todo can this just go to si in the call?


SELFMODIFY_MASKED_set_xlat_offset:
mov   bp, 01000h   

db 09Ah
SELFMODIFY_MASKED_COLFUNC_set_func_offset:
dw DRAWCOL_NOLOOP_OFFSET_MASKED, COLORMAPS_SEGMENT_MASKEDMAPPING


increment_column_and_continue_loop:
pop   si
pop   es
; check next column
lods  word ptr es:[si]       ; column->length. now si = si + 2.


cmp   al, 0FFh               ; do we have another post int he column?
je    exit_function

; only calculate next offset if necessary since the shift 4 is expensive..
;        currentoffset += column->length;
;        currentoffset += (16 - ((column->length &0xF)) &0xF);

; round up to next segment. add 0Fh and shift right four. but dont do this if we dont continue the loop.

SELFMODIFY_MASKED_set_last_offset:
db    0bbh, 00, 00   ; mov   bx, (byte) zero extended into high
add   bx, 0Fh        

SHIFT_MACRO shr bx 4   ; TODO separately bench lookup table for shift right 4? mov bl, byte ptrs cs:[_sar4table + bx]
add   byte ptr cs:[SELFMODIFY_MASKED_add_currentoffset+1], bl

jmp   draw_next_column_patch 
exit_function:


mov   cx, es               ; restore cx

pop   bp
pop   di
pop   si
pop   dx
ret


ENDP




loop_below_zero_subtractor_masked:
;	textotal += subtractor; // add the last's total.

add       bx, ax
jmp       done_with_loop_check_subtractor_MASKED
ALIGN_MACRO
lump_below_zero_masked:

;	maskedcachedbasecol = runningbasetotal - textotal;
; bx to become maskedcachedbasecol, currently is  is textotal, dx is running base total.
neg       bx
add       bx, dx
jmp       done_with_loop_check_masked
ALIGN_MACRO

PROC   R_GetMaskedColumnSegment_ NEAR ; could use another look
PUBLIC R_GetMaskedColumnSegment_
;  bp - 2      ; tex (orig ax)
;  cl generally stores texcol texcol


; di, dx ok to clobber
; bx ok to clobber. mayeb cx
; probably not si or bp

push      si
push      bp

push      ax        ; tex bp - 2
xchg      ax, di
;	maskedheaderpixeolfs = 0xFFFF;

mov       word ptr ds:[_maskedheaderpixeolfs], 0FFFFh

	
;	col &= texturewidthmasks[tex];

mov       ax, TEXTUREWIDTHMASKS_SEGMENT
mov       es, ax
xor       dh, dh
mov       cx, dx
and       cl, byte ptr es:[di] ; and by mask 

;	basecol -= col;
sub       dx, cx

;	texcol = col;
mov       bp, cx ; cl is 'bp - 4'

sal       di, 1

;	texturecolumnlump = &(texturecolumnlumps_bytes_7000[texturepatchlump_offset[tex]]);

mov       si, word ptr ds:[di + _texturepatchlump_offset]
sal       si, 1 ; si is  texturecolumnlump ptr

;	loopwidth = texturecolumnlump[1].bu.bytehigh;


mov       ax, TEXTURECOLUMNLUMPS_BYTES_SEGMENT
mov       ds, ax
xor       ax, ax
mov       al, byte ptr ds:[si + TEXTURECOLUMNLUMP_T.texturecolumnlump_loopwidth]
mov       word ptr ds:[_maskedtexrepeat], ax  ; always equals loopwidth whether 0 or not?


test      al, al
je        loopwidth_zero_masked

loopwidth_nonzero_masked:
; di is free to use
; ds:si is texcollump


;	lump = texturecolumnlump[0].h;
;    maskedcachedbasecol  = basecol;
;    maskedtexrepeat	 	 = loopwidth;

mov       word ptr ss:[_maskedtexrepeat], ax  ; loopwidth
lodsw       ; mov       ax, word ptr ds:[si + TEXTURECOLUMNLUMP_T.texturecolumnlump_lump]
xchg      ax, si
mov       ax, ss
mov       ds, ax
mov       word ptr ds:[_maskedcachedbasecol], dx ; basecol
jmp       done_with_loopwidth_masked

ALIGN_MACRO
loopwidth_zero_masked:
xor       bx, bx   ; textotal

;		uint8_t startpixel;
;		int16_t subtractor;
;		int16_t textotal = 0;
;		int16_t runningbasetotal = basecol;
;		int16_t n = 0;


mov        es, dx

; es is basecol
; ax is subtractor      
; si is loop iter        
; bp is col 
; dx is runningbasetotal
; cx is texcol
; di is lump
; bx is textotal

mov       bp, cx

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
test      bp, bp
jl        done_with_subtractor_loop_masked

do_next_subtractor_loop_masked:

;			subtractor = texturecolumnlump[n+1].bu.bytelow + 1;



; ah should be 0
lodsw     ; ax gets lump
xchg      ax, di  ; di gets lump
lodsw     ; al gets subtractor
xor       ah, ah
inc       ax                     ; subtractor = texturecolumnlump[n+1].bu.bytelow + 1;
add       dx, ax                 ; runningbasetotal += subtractor;
sub       bp, ax                 ; col -= subtractor;
test      di, di
js        loop_below_zero_subtractor_masked

;				texcol -= subtractor; ; todo really consider this. does it have to be plus one? is this the garbage source? is this correct or does it have to be bytelow direct?
sub       cl, al
done_with_loop_check_subtractor_MASKED:

test      bp, bp
jge       do_next_subtractor_loop_masked
done_with_subtractor_loop_masked:

;		maskednextlookup     = runningbasetotal; 

mov       word ptr ds:[_maskednextlookup], dx 

test      di, di
jng       lump_below_zero_masked

;    startpixel = texturecolumnlump[n-1].bu.bytehigh;
xor       bx, bx
mov       bl, byte ptr ds:[si - SIZE TEXTURECOLUMNLUMP_T + TEXTURECOLUMNLUMP_T.texturecolumnlump_loopwidth]  ; startpixel
;    maskedcachedbasecol = basecol + startpixel;
mov       si, es ; basecol
add       bx, si
done_with_loop_check_masked:

mov       si, ss
mov       ds, si

; bp is now col
; bx is _maskedcachedbasecol
; dx is runningbasetotal
; ax is subtractor
; si is free
; di is lump

; todo reverse this again
mov       si, di ; reverse. si is lump again

;		maskedprevlookup     = runningbasetotal - subtractor;
mov       word ptr ds:[_maskedcachedbasecol], bx
sub       dx, ax
mov       word ptr ds:[_maskedprevlookup], dx  ;	maskedprevlookup     = runningbasetotal - subtractor;
done_with_loopwidth_masked:

; cx = col
; si = lump
; bx = cachelumpindex? needs to be zeroed...

;	if (lump > 0){

pop       di ; bp - 2
push      di ; restore bp - 2 todo remove

test      si, si
jg        lump_greater_than_zero_masked
jmp       no_lump_do_texture
ALIGN_MACRO
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
ALIGN_MACRO
lump_greater_than_zero_masked:
; di is bp - 2

;	uint8_t lookup = masked_lookup_7000[tex];
mov       ax, TEXTURECOLUMNLUMPS_BYTES_SEGMENT
mov       es, ax
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
test      bp, bp



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
pop       bx ; bp - 2
push      bx ; restore bp - 2 todo remove

mov       dl, byte ptr es:[bx]      ; dh 0 from above cwd
cmp       ax, dx
jna       negative_modulo_thing_masked
xchg      ax, dx
inc       ax

;    while (col < 0){
;        col+= patchwidth;
;    }
negative_modulo_thing_masked:
add       bp, ax
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
add       sp, 2  ; garbage bp - 2 pop
pop       bp    
pop       si
ret  
ALIGN_MACRO
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
; es:bx is pixelofs

;    uint16_t ofs  = pixelofs[col]; // precached as segment value.
sal       bp, 1  ; col word lookup
add       bx, bp

;    return maskedcachedsegment + ofs;
mov       ax, word ptr ds:[_maskedcachedsegment]
add       ax, word ptr es:[bx]

add       sp, 2  ; garbage bp - 2 pop
pop       bp    
pop       si
ret      
ALIGN_MACRO



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


; di was set above before the function call...

jmp       found_cached_lump_masked

ALIGN_MACRO
 
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
mul       cl ; bp - 4
add       ax, dx
LEAVE_MACRO     
pop       si
ret      
ALIGN_MACRO
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
ALIGN_MACRO
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
jmp       done_setting_cached_tex_masked


ENDP












;
; The following functions are loaded into a different segment at runtime.
; However, at compile time they have access to the labels in this file.
;


;R_WriteBackViewConstantsMasked

ALIGN_MACRO
PROC   R_WriteBackViewConstantsMasked24_ FAR   ; fairly unoptimized, doesnt run much
PUBLIC R_WriteBackViewConstantsMasked24_ 



mov      ax, DRAWFUZZCOL_AREA_SEGMENT
mov      ds, ax




ASSUME DS:R_MASK24_TEXT

mov      ax,  word ptr ss:[_detailshift]



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
mov      bx, OFFSET (SELFMODIFY_MASKED_detailshift_2_32bit_1+0 - OFFSET R_MASK24_STARTMARKER_)
mov      ax, 0FAD1h ; sar dx, 1 
mov      word ptr ds:[bx], ax
mov      word ptr ds:[bx+4], ax
mov      ax, 0D8D1h ; rcr ax, 1
mov      word ptr ds:[bx+2], ax
mov      word ptr ds:[bx+6], ax

mov      word ptr ds:[SELFMODIFY_MASKED_detailshift_2_32bit_2 - OFFSET R_MASK24_STARTMARKER_], 006EBh



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

mov      bx, OFFSET (SELFMODIFY_MASKED_detailshift_2_32bit_1+0 - OFFSET R_MASK24_STARTMARKER_)
mov      word ptr ds:[bx], ax
mov      word ptr ds:[bx+2], ax
mov      word ptr ds:[bx+4], 0FAD1h ; sar dx, 1 
mov      word ptr ds:[bx+6], 0D8D1h ; rcr ax, 1

mov      bx, OFFSET (SELFMODIFY_MASKED_detailshift_2_32bit_2+0 - OFFSET R_MASK24_STARTMARKER_)
mov      word ptr ds:[bx], ax
mov      word ptr ds:[bx+2], ax
mov      word ptr ds:[bx+4], 0E3D1h ; shl bx, 1 
mov      word ptr ds:[bx+6], 0D2D1h ; rcl dx, 1


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

;mov      ax, 006EBh  ; jmp 6
mov      word ptr ds:[SELFMODIFY_MASKED_detailshift_2_32bit_1 - OFFSET R_MASK24_STARTMARKER_], 006EBh

mov      bx, OFFSET (SELFMODIFY_MASKED_detailshift_2_32bit_2+0 - OFFSET R_MASK24_STARTMARKER_)
mov      ax, 0E3D1h ; shl bx, 1 
mov      word ptr ds:[bx], ax
mov      word ptr ds:[bx+4], ax
mov      ax, 0D2D1h ; rcl dx, 1
mov      word ptr ds:[bx+2], ax
mov      word ptr ds:[bx+6], ax


; fall thru
done_modding_shift_detail_code_masked:


; note: examples 3/6/9 overwrite "add ax, 0" which compiles to the opcode where
; you get 16 bit immediate starting at base + 1 instead of a 8 bit immediate starting at base + 2.
mov   al, byte ptr ss:[_detailshiftitercount]
mov   byte ptr ds:[SELFMODIFY_MASKED_detailshiftitercount_1+2 - OFFSET R_MASK24_STARTMARKER_], al
mov   byte ptr ds:[SELFMODIFY_MASKED_detailshiftitercount_2+4 - OFFSET R_MASK24_STARTMARKER_], al

mov   byte ptr ds:[SELFMODIFY_MASKED_detailshiftitercount_4+2 - OFFSET R_MASK24_STARTMARKER_], al
mov   byte ptr ds:[SELFMODIFY_MASKED_detailshiftitercount_5+4 - OFFSET R_MASK24_STARTMARKER_], al
mov   byte ptr ds:[SELFMODIFY_MASKED_detailshiftitercount_7+4 - OFFSET R_MASK24_STARTMARKER_], al
mov   byte ptr ds:[SELFMODIFY_MASKED_detailshiftitercount_8+2 - OFFSET R_MASK24_STARTMARKER_], al
mov   byte ptr ds:[SELFMODIFY_MASKED_detailshiftitercount_9+2 - OFFSET R_MASK24_STARTMARKER_], al


mov   ax, word ptr ss:[_detailshiftandval]
mov   word ptr ds:[SELFMODIFY_MASKED_detailshiftandval_1+1 - OFFSET R_MASK24_STARTMARKER_], ax
mov   word ptr ds:[SELFMODIFY_MASKED_detailshiftandval_2+1 - OFFSET R_MASK24_STARTMARKER_], ax


mov   al, byte ptr ss:[_detailshift+1]
add   al, _quality_port_lookup
mov   byte ptr ds:[SELFMODIFY_MASKED_detailshiftplus1_2+2 - OFFSET R_MASK24_STARTMARKER_], al
mov   byte ptr ds:[SELFMODIFY_MASKED_detailshiftplus1_3+2 - OFFSET R_MASK24_STARTMARKER_], al
mov   byte ptr ds:[SELFMODIFY_MASKED_detailshiftplus1_4+2 - OFFSET R_MASK24_STARTMARKER_], al

mov   ax, word ptr ss:[_viewheight]
; todo revisit. shadow column no longer checking vs view height? i guess sprites should have already been clipped?
;mov   word ptr ds:[SELFMODIFY_MASKED_viewheight_1+1 - OFFSET R_MASK24_STARTMARKER_], ax
mov   word ptr ds:[SELFMODIFY_MASKED_viewheight_2+1 - OFFSET R_MASK24_STARTMARKER_], ax



push   ss
pop    ds



retf

ENDP

;R_WriteBackMaskedFrameConstants

ALIGN_MACRO
PROC   R_WriteBackMaskedFrameConstants24_ FAR   ; fairly unoptimized, doesnt run much
PUBLIC R_WriteBackMaskedFrameConstants24_ 


; cs is NOT DRAWFUZZCOL_AREA_SEGMENT. todo fixable?
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
inc   ax
mov   byte ptr ds:[SELFMODIFY_MASKED_extralight_1_plus_one+1 - OFFSET R_MASK24_STARTMARKER_], al

mov   al, byte ptr ss:[_fixedcolormap]
cmp   al, 0
jne   do_fixedcolormap_selfmodify
do_no_fixedcolormap_selfmodify:

; replace with nop.
; nop 
mov      bx, SELFMODIFY_MASKED_fixedcolormap_2 - OFFSET R_MASK24_STARTMARKER_
mov      ax, 0c089h 
mov      word ptr ds:[SELFMODIFY_MASKED_fixedcolormap_1 - OFFSET R_MASK24_STARTMARKER_], ax
; lea bp, [bp + 0] ; 3 byte nop
mov      word ptr ds:[bx], 06E8Dh 
mov      byte ptr ds:[bx+2], 00



jmp done_with_fixedcolormap_selfmodify

do_fixedcolormap_selfmodify:
mov   byte ptr ds:[SELFMODIFY_MASKED_fixedcolormap_3+5 - OFFSET R_MASK24_STARTMARKER_], al

; modify jmp in place.
mov   ax, ((SELFMODIFY_MASKED_fixedcolormap_1_TARGET - SELFMODIFY_MASKED_fixedcolormap_1_AFTER) SHL 8) + 0EBh
mov   word ptr ds:[SELFMODIFY_MASKED_fixedcolormap_1 - OFFSET R_MASK24_STARTMARKER_], ax
mov   byte ptr ds:[bx+0], 0E9h ; word jmp
mov   word ptr ds:[bx+1], (SELFMODIFY_MASKED_fixedcolormap_2_TARGET - SELFMODIFY_MASKED_fixedcolormap_2_AFTER)



; fall thru
done_with_fixedcolormap_selfmodify:

push   ss
pop    ds


retf



ENDP

; end marker for this asm file
PROC R_MASK24_ENDMARKER_ FAR
PUBLIC R_MASK24_ENDMARKER_ 
ENDP

ENDS
END
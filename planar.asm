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

.DATA

EXTRN	_destview:DWORD
EXTRN	_centery:WORD

EXTRN	_dc_yl:WORD
EXTRN	_dc_yh:WORD
EXTRN	_dc_source_segment:WORD

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

COLFUNC_JUMP_LOOKUP_SEGMENT    = 6A10h
DC_YL_LOOKUP_SEGMENT           = 6A29h
COLFUNC_FUNCTION_AREA_SEGMENT  = 6A42h
COLFUNC_JUMP_AND_DC_YL_OFFSET_DIFF   = ((DC_YL_LOOKUP_SEGMENT - COLFUNC_JUMP_LOOKUP_SEGMENT) * 16)
COLFUNC_JUMP_AND_FUNCTION_AREA_OFFSET_DIFF = ((COLFUNC_FUNCTION_AREA_SEGMENT - COLFUNC_JUMP_LOOKUP_SEGMENT) * 16)


COLFUNC_JUMP_OFFSET            = 06Dh

DRAWCOL_OFFSET                 = 2420h


FINESINE_SEGMENT               = 31e4h
FINECOSINE_SEGMENT             = 33e4h
 


CACHEDHEIGHT_SEGMENT           = 9000h
Y_SLOPE_SEGMENT                = 9032h
CACHEDDISTANCE_SEGMENT         = 9064h
CACHEDXSTEP_SEGMENT            = 9096h
CACHEDYSTEP_SEGMENT            = 90C8h
SPANSTART_SEGMENT              = 90FAh
DISTSCALE_SEGMENT              = 9113h

SPANFUNC_FUNCTION_AREA_SEGMENT = 6EAAh
SPANFUNC_PREP_OFFSET           = 070Fh

; jump table is 0 offset at this segment
SPANFUNC_JUMP_LOOKUP_SEGMENT   = 6EA0h
; offset of the jmp instruction's immediate from the above segment
SPANFUNC_JUMP_OFFSET           = 1E5h


BASE_COLORMAP_POINTER          = 6800h
XTOVIEWANGLE_SEGMENT           = 833bh
MAXLIGHTZ                      = 0080h
MAXLIGHTZ_UNSHIFTED            = 0800h

DC_YL_LOOKUP_SPACE             = _ss_variable_space+4

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

; no need to push anything. outer function just returns and pops


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
	

    add   di, word ptr [DC_YL_LOOKUP_SPACE]   ; quick mul 80
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
   xor     bx, bx       ; common bx offset
   mov     ax, word ptr [_dc_source_segment]     ; this will be ds..
   mov     ds, ax                          ; do this last, makes us unable to to ref other vars...
   mov     si,  4Fh
   mov     ah,  7Fh



   jmp loop_done         ; relative jump to be modified before function is called


pixel_loop_fast:

   ;; 14 bytes loop iter

DRAW_SINGLE_PIXEL MACRO 
   ; tried to reorder adds in between xlats and stos, but it didn't make anything faster.
   ; TODO: fix texture 'jaggies', maybe every sixteen pixels or so add a corrective factor.
   ;   would have to preadd to dx by (16 - drawnpixelcount &0xF) so it'd be consistent?

    mov    al,dh
	and    al,ah                  ; ah has 0x7F (127)
	; add    al,bh                ; REMOVED! bh has the 0 to F offset. 
	xlat   BYTE PTR ds:[bx]       ;
	xlat   BYTE PTR cs:[bx]       ; before calling this function we already set CS to the correct segment..
	stos   BYTE PTR es:[di]       ;
	add    dx,cx
	add    di,si                  ; si has 79 (0x4F) and stos added one
ENDM

REPT 199
    DRAW_SINGLE_PIXEL
endm


; draw last pixel, cut off the add

    mov    al,dh
	and    al,ah                  ; ah has 0x7F (127)
	;add    al,bh                  ; bh has the 0 to F offset
	xlat   BYTE PTR ds:[bx]       ;
	xlat   BYTE PTR cs:[bx]       ; before calling this function we already set CS to the correct segment..
	stos   BYTE PTR es:[di]       ;
	; dont need these in last loop
    ;add    di,si                  ; si has 79 (0x4F) and stos added one
	;add    dx,cx

loop_done:
; clean up

; restore ds without going to memory.
    mov ax, ss
    mov ds, ax
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
add   ax, COLFUNC_JUMP_LOOKUP_SEGMENT        ; compute segment
mov   es, ax                                 ; store this segment for now, with offset pre-added
mov   si, word ptr [_dc_yh]                  ; grab dc_yh
mov   bx, word ptr [_dc_yl]
sub   si, bx                                 ;
add   bx, bx                                 ; double dc_yl to get a word offset
add   bx, COLFUNC_JUMP_AND_DC_YL_OFFSET_DIFF;
mov   bx, word ptr es:[bx]
mov   word ptr [DC_YL_LOOKUP_SPACE], bx      ; store pre-calculated dc_yl * 80
add   si, si                                 ; double diff (dc_yh - dc_yl) to get a word offset
mov   ax, word ptr es:[si]                   ; get the jump value
mov   word ptr es:[COLFUNC_JUMP_OFFSET+COLFUNC_JUMP_AND_FUNCTION_AREA_OFFSET_DIFF], ax  ; overwrite the jump relative call for however many iterations in unrolled loop we need
mov   al, byte ptr [_dc_colormap_index]      ; lookup colormap index
; what follows is compution of desired CS segment and offset to function to allow for colormaps to be CS:BX and match DS:BX column
mov   dx, word ptr [_dc_colormap_segment]    
mov   si, OFFSET _ss_variable_space ; lets use this variable space
test  al, al
jne    skipcolormapzero

mov   word ptr [si], DRAWCOL_OFFSET				; setup dynamic call
mov   word ptr [si+2], dx

db 0FFh  ; lcall[si]
db 01Ch  ;


pop   di ; unused but drawcol clobbers it.
pop   si
pop   dx
pop   cx
pop   bx
retf  
cld  

; if colormap is not zero we must do some segment math
skipcolormapzero:
mov   bx, DRAWCOL_OFFSET

cbw           ; al is like 0-20 so this will zero out ah...
xchg   ah, al ; move it high with 0 al.
sub   bx, ax
shr   ax, 1
shr   ax, 1
shr   ax, 1
shr   ax, 1
add   dx, ax

mov   word ptr [si], bx				; setup dynamic call
mov   word ptr [si+2], dx

db 0FFh  ; lcall[si]
db 01Ch  ;

pop   di ; unused but drawcol clobbers it.
pop   si
pop   dx
pop   cx
pop   bx
retf   

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

DRAW_SINGLE_SPAN_PIXEL MACRO 
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

ENDM

REPT 79
    DRAW_SINGLE_SPAN_PIXEL
endm

; final pixel

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
mov sp, bp
pop bp 

retf  
cld   

ENDP




;
; R_DrawSpanPrep
;
	
PROC  R_DrawSpanPrep_
PUBLIC  R_DrawSpanPrep_ 

 
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
 xor   bl, bl							; zero out bl. use it as loop counter/ i
 
 cmp   byte ptr [_spanfunc_main_loop_count], 0		; if shiftamount is equal to zero
 jle   spanfunc_arg_setup_complete
 mov   word ptr [_ss_variable_space], dx			; store base view offset
 
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

 jge   dont_increment_ds_x1     ; signed so carry flag adc 0 doesnt work?
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
 add   dx, word ptr [_ss_variable_space]						   ; dsp_x1 + base view offset
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
 jne    ds_colormap_nonzero


 ; easy address calculation
 
; 		uint16_t cs_base = ds_colormap_segment - cs_source_segment_offset;
;		uint16_t callfunc_offset = colormaps_spanfunc_off_difference + cs_source_offset;
;		dynamic_callfunc  =       ((void    (__far *)(void))  (MK_FP(cs_base, callfunc_offset)));




mov   si, OFFSET _ss_variable_space ; lets use this variable space
mov   word ptr [si], 07a60h
mov   word ptr [si+2], dx				; setup dynamic call

db 0FFh  ; lcall[si]
db 01Ch  ;
 
 
 retf  
 ds_colormap_nonzero:									; if ds_colormap_index is 0
 

 
 
 
 ; colormap not zero. need to offset cs etc by its address

 ;		uint16_t ds_colormap_offset = ds_colormap_index << 8;
;		uint16_t ds_colormap_shift4 = ds_colormap_index << 4;
	 	
;		uint16_t cs_base = ds_colormap_segment - cs_source_segment_offset + ds_colormap_shift4;
;		uint16_t callfunc_offset = colormaps_spanfunc_off_difference + cs_source_offset - ds_colormap_offset;
;		dynamic_callfunc  =       ((void    (__far *)(void))  (MK_FP(cs_base, callfunc_offset)));

 
 xor   ah, ah
 mov   bx, ax
 shl   ax, 1
 shl   ax, 1
 shl   ax, 1
 shl   ax, 1
 mov   bh, bl
 xor   bl, bl
 add   dx, ax
 mov   ax, 07a60h
 sub   ax, bx

mov   si, OFFSET _ss_variable_space ; lets use this variable space
mov   word ptr [si], ax
mov   word ptr [si+2], dx				; setup dynamic call

db 0FFh  ; lcall[si]
db 01Ch  ;
 retf  

ENDP







PROC R_FixedMulTrigLocal_
PUBLIC R_FixedMulTrigLocal_

; DX:AX  *  CX:BX
;  0  1   2  3

; AX * CX:BX
; The difference between FixedMulTrig and FixedMul1632:
; fine sine/cosine lookup tables are -65535 to 65535, so 17 bits. 
; technically, this resembles 16 * 32 with sign extend, except we cannot use CWD to generate the high 16 bits.
; So those sign bits which contain bit 17, sign extended must be stored somewhere cannot be regenerated via CWD
; we basically take the above function and shove sign bits in DS for storage and regenerate DS from SS upon return
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

; AX is param 1 (segment)
; DX is param 2 (fineangle or lookup)
; CX:BX is value 2




push  si

; lookup the fine angle

sal dx, 1
sal dx, 1   ; DWORD lookup index
mov si, dx
mov es, ax  ; put segment in ES
mov ax, es:[si]
mov dx, es:[si+2]


mov   es, ax    ; store ax in es
mov   DS, DX    ; store sign bits in DS
AND   DX, BX	; S0*BX
NEG   DX
mov   SI, DX	; DI stores hi word return

mov   DX, DS    ; restore sign bits from DS

AND  DX, CX    ; DX*CX
NEG  DX
add  SI, DX    ; low word result into high word return

mov   DX, DS    ; restore sign bits from DS

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
 
MOV CX, SS
MOV DS, CX    ; put DS back from SS

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
; bp - 02h   y
; bp - 04h   distance low
; bp - 06h   distance high
; bp - 08h   x2
; bp - 0Ah   fineangle

;cachedheight   9000:0000
;yslope         9032:0000
;distscale      9064:0000
;cacheddistance 90B4:0000
;cachedxstep    90E6:0000
;cachedystep    9118:0000
; 	rather than changing ES a ton we will just modify offsets by segment distance
;   confirmed to be faster even on 8088 with it's baby prefetch queue - i think on 16 bit busses it is only faster.

PROC  R_MapPlane_
PUBLIC  R_MapPlane_ 

push  cx
push  si
push  di
push  bp
mov   bp, sp
sub   sp, 0Ah

xor   ah, ah
; set these values for drawspan while they are still in registers
mov   word ptr [_ds_y], ax
mov   word ptr [_ds_x1], dx
mov   word ptr [_ds_x2], bx

mov   byte ptr [bp - 2], al
mov   word ptr [bp - 8], dx

mov   bx, CACHEDHEIGHT_SEGMENT			; base segment
mov   es, bx
xor   ah, ah
xchg  si, ax
mov   ax, word ptr [_planeheight]
mov   dx, word ptr [_planeheight + 2]
shl   si, 1
shl   si, 1
; CACHEDHEIGHT LOOKUP

cmp   ax, word ptr es:[si] ; compare low word
je    use_cached_values
go_generate_values:
jmp   generate_distance_steps
use_cached_values:

cmp   dx, word ptr es:[si+2]
jne   go_generate_values	; comparing high word


; CACHED DISTANCE lookup

mov   ax, word ptr es:[si + (( CACHEDDISTANCE_SEGMENT - CACHEDHEIGHT_SEGMENT) * 16)]
mov   dx, word ptr es:[si + 2 + (( CACHEDDISTANCE_SEGMENT - CACHEDHEIGHT_SEGMENT) * 16)]
mov   di, dx					; store distance high word
mov   word ptr [bp - 04h], ax	; store distance low word

; CACHEDXSTEP lookup


mov   ax, word ptr es:[si + (( CACHEDXSTEP_SEGMENT - CACHEDHEIGHT_SEGMENT) * 16)]
mov   dx, word ptr es:[si + 2 + (( CACHEDXSTEP_SEGMENT - CACHEDHEIGHT_SEGMENT) * 16)]
mov   word ptr [_ds_xstep], ax
mov   word ptr [_ds_xstep+2], dx

; CACHEDYSTEP lookup


mov   ax, word ptr es:[si + (( CACHEDYSTEP_SEGMENT - CACHEDHEIGHT_SEGMENT) * 16)]
mov   dx, word ptr es:[si + 2 + (( CACHEDYSTEP_SEGMENT - CACHEDHEIGHT_SEGMENT) * 16)]
mov   word ptr [_ds_ystep], ax
mov   word ptr [_ds_ystep+2], dx
distance_steps_ready:

; dx:ax is y_step
;     length = R_FixedMulLocal (distance,distscale[x1]);

mov   si, word ptr [bp - 8]		; grab x2 (function input)
mov   ax, DISTSCALE_SEGMENT
shl   si, 1
shl   si, 1						; dword lookup
mov   es, ax
mov   dx, di  				    ; distance high word
mov   word ptr [bp - 06h], dx   ; store distance high word in case needed for colormap
mov   ax, word ptr [bp - 04h]   ; distance low word
mov   bx, word ptr es:[si]		; distscale low word
mov   cx, word ptr es:[si + 2]	; distscale high word

;call FAR PTR FixedMul_ 
call R_FixedMulLocal_


;	angle = MOD_FINE_ANGLE(viewangle_shiftright3+ xtoviewangle[x1]);
; ds_xfrac = viewx.w + R_FixedMulLocal(finecosine[angle], length );

mov   bx, si
shr   bx, 1		
xchg  di, ax			; store low word of length (product result)in di
mov   si, dx			; store high word of length  (product result) in si
mov   ax, XTOVIEWANGLE_SEGMENT
mov   es, ax
mov   ax, word ptr [_viewangle_shiftright3]
add   ax, word ptr es:[bx]		; ax is unmodded fine angle..
and   ah, 01Fh			; MOD_FINE_ANGLE mod high bits
mov   word ptr [bp - 0Ah], ax	; store fineangle
mov   dx, ax			; fineangle in DX

mov   ax, FINECOSINE_SEGMENT
mov   bx, di			; length low word to DX
mov   cx, si			; length low word to DX

;call FAR PTR FixedMul_ 
call R_FixedMulTrigLocal_

;    ds_yfrac = -viewy.w - R_FixedMulLocal(finesine[angle], length );

add   ax, word ptr [_viewx]
adc   dx, word ptr [_viewx+2]
mov   word ptr [_ds_xfrac], ax
mov   word ptr [_ds_xfrac+2], dx

mov   ax, FINESINE_SEGMENT
mov   dx, word ptr [bp - 0Ah]
mov   cx, si					; prep length
mov   bx, di					; prep length

;call FAR PTR FixedMul_ 
call R_FixedMulTrigLocal_

;    ds_yfrac = -viewy.w - R_FixedMulLocalWrapper(finesine[angle], length );

; let's instead add then take the negative of the whole

; CX:BX as viewy
mov   bx, word ptr [_viewy]
mov   cx, word ptr [_viewy+2]
add   ax, bx
adc   dx, cx
; take negative of the whole
; apparently this is how you neg a dword. 
neg   dx
neg   ax
; i dont understand why this is here but the compiler did this. it works with or without, 
; probably too tiny an error to be visibly noticable?
sbb   dx, 0

mov   word ptr [_ds_yfrac], ax
mov   word ptr [_ds_yfrac+2], dx

; 	if (fixedcolormap) {

cmp   byte ptr [_fixedcolormap], 0
je   use_nonfixed_colormap

mov   al, byte ptr [_fixedcolormap]
mov   word ptr [_ds_colormap_index], BASE_COLORMAP_POINTER



colormap_ready:

; lcall SPANFUNC_FUNCTION_AREA_SEGMENT:SPANFUNC_PREP_OFFSET

db 09Ah
dw SPANFUNC_PREP_OFFSET
dw SPANFUNC_FUNCTION_AREA_SEGMENT


mov sp, bp
pop bp 
pop   di
pop   si
pop   cx
retf  

use_nonfixed_colormap:

; 		index = distance >> LIGHTZSHIFT;
mov   ax, word ptr [bp - 06h]
sar   ax, 1
sar   ax, 1
sar   ax, 1
sar   ax, 1


;		if (index >= MAXLIGHTZ) {
;			index = MAXLIGHTZ - 1;
;		}



cmp   al, MAXLIGHTZ
jb    index_set
mov   al, MAXLIGHTZ - 1
index_set:

;		ds_colormap_segment = colormapssegment;
;		ds_colormap_index = planezlight[index];

mov   word ptr [_ds_colormap_segment], BASE_COLORMAP_POINTER
mov   bx, word ptr [_planezlight]
xor   ah, ah
mov   es, word ptr [_planezlight+2]
add   bx, ax
mov   al, byte ptr es:[bx]
mov   byte ptr [_ds_colormap_index], al

; lcall SPANFUNC_FUNCTION_AREA_SEGMENT:SPANFUNC_PREP_OFFSET

db 09Ah
dw SPANFUNC_PREP_OFFSET
dw SPANFUNC_FUNCTION_AREA_SEGMENT


mov sp, bp
pop bp 
pop   di
pop   si
pop   cx
retf  
generate_distance_steps:

; es = 9000h  (CACHEDHEIGHT_SEGMENT)
; dx:ax = planeheight segment
; note: es wrecked by function calls to r_fixedmullocal...



mov   word ptr es:[si], ax
mov   word ptr es:[si + 2], dx   ; cachedheight into dx
mov   bx, word ptr es:[si + (( Y_SLOPE_SEGMENT - CACHEDHEIGHT_SEGMENT) * 16)]
mov   cx, word ptr es:[si + 2 + (( Y_SLOPE_SEGMENT - CACHEDHEIGHT_SEGMENT) * 16)]


; not worth continuing to LEA because fixedmul destroys ES and then we have to store and restore from SI which is too much extra time
; distance = cacheddistance[y] = R_FixedMulLocal (planeheight, yslope[y]);

;call FAR PTR FixedMul_ 
call R_FixedMulLocal_

; result is distance
mov   bx, CACHEDDISTANCE_SEGMENT
mov   es, bx
mov   bx, word ptr [_basexscale]
mov   cx, word ptr [_basexscale+2]
mov   word ptr es:[si], ax			; store distance
mov   word ptr es:[si + 2], dx		; store distance
mov   di, dx						; store distance high word in di
mov   word ptr [bp - 04h], ax		; distance low word

; 		ds_xstep = cachedxstep[y] = (R_FixedMulLocal (distance,basexscale));

;call FAR PTR FixedMul_ 
call R_FixedMulLocal_

mov   bx, CACHEDXSTEP_SEGMENT
mov   es, bx
mov   word ptr es:[si], ax
mov   word ptr es:[si + 2], dx
mov   word ptr [_ds_xstep], ax
mov   word ptr [_ds_xstep+2], dx
mov   dx, di
mov   bx, word ptr [_baseyscale]
mov   cx, word ptr [_baseyscale+2]
mov   ax, word ptr [bp - 04h]	; retrieve distance low word

;		ds_ystep = cachedystep[y] = (R_FixedMulLocal (distance,baseyscale));

;call FAR PTR FixedMul_ 
call R_FixedMulLocal_

mov   bx, CACHEDYSTEP_SEGMENT
mov   es, bx
mov   word ptr es:[si], ax
mov   word ptr es:[si + 2], dx
mov   word ptr [_ds_ystep], ax
mov   word ptr [_ds_ystep+2], dx
jmp   distance_steps_ready
cld   

ENDP

END
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

EXTRN  Z_QuickMapPhysics_:NEAR
EXTRN  Z_QuickMapRender_:NEAR
EXTRN  Z_QuickMapRenderPlanes_:NEAR
EXTRN  Z_QuickMapUndoFlatCache_:NEAR
EXTRN  Z_QuickMapPhysics_FunctionAreaOnly_:NEAR
EXTRN  FixedMul_:NEAR
EXTRN  FastDiv32u16u_:NEAR

 
.DATA



.CODE

PUBLIC _SELFMODIFY_R_WRITEBACKVIEWCONSTANTSSPANCALL
PUBLIC _SELFMODIFY_R_WRITEBACKVIEWCONSTANTSMASKEDCALL
PUBLIC _SELFMODIFY_R_WRITEBACKVIEWCONSTANTS
FINE_TANGENT_MAX = 2048

FIXED_FINE_TAN = 010032H
NUMCOLORMAPS = 32

;  #define finetangent(x) (x < 2048 ? finetangentinner[x] : -(finetangentinner[(-x+4095)]) )


PROC    R_SETUP_STARTMARKER_ NEAR
PUBLIC  R_SETUP_STARTMARKER_
ENDP

use_min:
test    ax, ax
jz      dont_use_min
use_min_skip_check:
mov     ax, -1
jmp     set_value_and_continue_loop




PROC    R_InitTextureMapping_ NEAR
PUBLIC  R_InitTextureMapping_

PUSHA_NO_AX_MACRO


;	focallength = FixedDivWholeA(centerx, FIXED_FINE_TAN);
mov     ax, word ptr ds:[_viewwidth]

inc     ax



mov     word ptr cs:[_SELFMODIFY_check_viewwidth_plus_1+1], ax
mov     ax, word ptr ds:[_centerx]
mov     word ptr cs:[_SELFMODIFY_add_center_x+1], ax
mov     bx, FIXED_FINE_TAN AND 0FFFFh
mov     cx, FIXED_FINE_TAN SHR 16

; this can be much faster

; no paging needed, already in this code segment.
db    09Ah
dw    FIXEDDIVWHOLEA_ML, PHYSICS_HIGHCODE_SEGMENT

mov     word ptr cs:[_SELFMODIFY_set_focallength_hi + 1], dx
mov     word ptr cs:[_SELFMODIFY_set_focallength_low + 1], ax

xor     si, si ; loop read in
mov     di, si ; loop write out
xor     bp, bp  ; bp = backwards toggle for si reads...


call	Z_QuickMapRender_

; we break this into 2 loop variants that are self modified in between, due to finetangentinner logic
;	for (i = 0; i < FINEANGLES / 2; i++) {

; todo 

MOV   BP, word ptr ds:[_viewwidth]
inc   bp    ; viewwidth+1
MOV   AX, FINETANGENTINNER_SEGMENT
    MOV   DS, AX ; fixedmul no longer clobbers DS
MOV   AX, VIEWANGLETOX_SEGMENT
MOV   ES, AX
XOR   DI, DI

loop_next_fineangle:
MOV   BX, DI
; No AND because value is known in-range
SUB   BX, 4096
SBB   CX, CX         ; cx is mask...
XOR   BX, CX         ; apply sign
ADD   BX, CX         ; offset left by 2 (after shift) for negatives

;CMP   BX, (1443 SHL 1) ; 1443 is the index that equals FRACUNIT * 2
;JB    small_tangent

; Read tangent table
SHL   BX, 1
LES   AX, DS:[BX]
MOV   DX, ES

;NOT   CX

XOR   AX, CX
XOR   DX, CX
SUB   AX, CX
SBB   DX, CX

cmp   dx, 2
jge   use_min
dont_use_min:
cmp   dx, -2
jle   use_max
dont_use_max:


_SELFMODIFY_set_focallength_hi:
MOV   CX, 01000h
_SELFMODIFY_set_focallength_low:
MOV   BX, 01000h
CALL FixedMul_ ; t.w = FixedMul(finetan_i.w, focallength);
; t.w = (temp.w - t.w + 0xFFFFu);
xchg   ax, dx

neg    ax  ; neg sbb cancels out FFFFu add
_SELFMODIFY_add_center_x:
add     ax, 01000h

;   if (t.h.intbits < -1){
;       t.h.intbits = -1;
;   } else if (t.h.intbits > viewwidth + 1){
;       t.h.intbits = viewwidth + 1;
;   }


cmp     ax, -1
jl      use_min_skip_check
cmp     ax, bp
jg      use_max_skip_check


set_value_and_continue_loop:

; viewangletox[i] = t.h.intbits;
mov     dx, VIEWANGLETOX_SEGMENT
mov     es, dx
stosw
cmp  di, (FINEANGLES / 4) * 4  ; 8192
jb   loop_next_fineangle
; loop ends here
jmp  cleanup_and_exit_function
use_max:
test    ax, ax
jz      dont_use_max
use_max_skip_check:

mov     ax, bp
jmp     set_value_and_continue_loop

small_tangent:
NOT  CX
XCHG AX, CX
; finetan_i.w > FRACUNIT * 2 -> AX == -1, OR does nothing
; finetan_i.w < -FRACUNIT * 2 -> AX == 0, OR is MOV
OR   AX, BP
JMP  set_value_and_continue_loop
 
set_value_to_min:
mov    word ptr ds:[si - 2], 0
jmp    continue_fencepost_checks
set_value_to_max:

dec    bp
mov    word ptr ds:[si - 2], bp
inc    bp
jmp    continue_fencepost_checks




cleanup_and_exit_function:

; restore neg





;	for (x = 0; x <= viewwidth; x++) {
;		i = 0;
;		while (viewangletox[i] > x){
;			i++;
;		}
;		xtoviewangle[x] = MOD_FINE_ANGLE((i)-FINE_ANG90);
;	}

xor   di, di
mov   ax, XTOVIEWANGLE_SEGMENT
mov   es, ax
mov   ax, VIEWANGLETOX_SEGMENT
mov   ds, ax
mov   dx, FINEMASK
mov   cx, word ptr ss:[_viewwidth]
mov   bx, FINE_ANG90

loop_next_x_to_viewwidth:
xor   ax, ax
xor   si, si

repeat_scan:
lodsw
cmp   ax, di
jg    repeat_scan

xchg  ax, si
shr   ax, 1  ; undo word scan. ax = i 
dec   ax     ; undo last read
sub   ax, bx  ; - FINE_ANG90
and   ax, dx  ; MOD_FINE_ANGLE
shl   di, 1   ; for word write
stosw
shr   di, 1   ; undo word write

loop  loop_next_x_to_viewwidth


;	// Take out the fencepost cases from viewangletox.
;	for (i = 0; i < FINEANGLES / 2; i++) {
;
;		if (viewangletox[i] == -1){
;			viewangletox[i] = 0;
;		} else if (viewangletox[i] == viewwidth + 1){
;			viewangletox[i] = viewwidth;
;		}
;	}

xor   si, si
mov   cx, FINEANGLES / 2

loop_check_next_for_fenceposts:
lodsw
cmp    ax, -1
je     set_value_to_min
_SELFMODIFY_check_viewwidth_plus_1:
cmp    ax, 01000h
je     set_value_to_max

continue_fencepost_checks:
loop   loop_check_next_for_fenceposts

;	clipangle = xtoviewangle[0] << 3;
;	fieldofview = clipangle << 1;

mov     ax, word ptr es:[0]   ; still xtoviewangle segment
SHIFT_MACRO shl ax 3

push    ss
pop     ds

mov     word ptr ds:[_clipangle], ax
shl     ax, 1
mov     word ptr ds:[_fieldofview], ax


xor     ax, ax
mov     cx, word ptr ds:[_viewwidth]
mov     bx, SCREENWIDTH
cmp     cx, bx
jne     calculate_spritescales

;		pspritescale = 0;
;		pspriteiscale = FRACUNIT;

mov     word ptr ds:[_pspritescale], ax
mov     word ptr ds:[_pspriteiscale+0], ax
inc     ax
mov     word ptr ds:[_pspriteiscale+2], ax
jmp     done_calculating_spritescale
calculate_spritescales:

;		pspritescale = FastDiv32u16u(FRACUNIT * viewwidth, SCREENWIDTH);
;		pspriteiscale = FastDiv32u16u(FRACUNIT * SCREENWIDTH, viewwidth);
;		// 			10000	11C71	14000	16DB6	1AAAA	20000	28000	35555	50000	A0000 
;		//detail    10-11,   9		 8		 7		 6		 5		 4		 3		 2		 1
; todo hardcode in table smaller?

mov     dx, cx
call    FastDiv32u16u_
mov     word ptr ds:[_pspritescale+0], ax
xor     ax, ax
mov     dx, SCREENWIDTH
mov     bx, cx
call    FastDiv32u16u_
mov     word ptr ds:[_pspriteiscale+0], ax
mov     word ptr ds:[_pspriteiscale+2], dx  ; todo always 0?

done_calculating_spritescale:		
; cx still view width
;	for (i = 0; i < viewwidth; i++) {
;		screenheightarray[i] = viewheight;
;	}
xor    di, di
mov    ax, (SCREENHEIGHTARRAY_SEGMENT + OFFSET_SCREENHEIGHTARRAY SHR 4)
mov    es, ax
mov    ax, word ptr ds:[_viewheight]
mov    si, ax   ; si gets viewheight
inc    ax ; plus 1
mov    ah, al
shr    cx, 1
rep    stosw

; prep the following loop.
mov    ax, si  ; ax gets viewheight back
shr    ax, 1
mov    word ptr cs:[_SELFMODIFY_sub_viewheight_shr_1+2], ax
mov    ax, word ptr ds:[_viewwidth]
mov    cl, byte ptr ds:[_detailshift]
shl    ax, cl
shr    ax, 1
mov    word ptr cs:[_SELFMODIFY_viewwidth_precalculate+1], ax

call   Z_QuickMapRenderPlanes_
call   Z_QuickMapPhysics_FunctionAreaOnly_

; si has viewheight..

;	for (i = 0; i < viewheight; i++) {
;		temp.h.intbits = (i - (viewheight >> 1));
;		dy = (temp.w) + 0x8000u;
;		dy = labs(dy);
;		temp.h.intbits = (viewwidth << detailshift.b.bytelow) >> 1;
;		yslope[i] = FixedDivWholeA(temp.h.intbits, dy);
;	}

xor   bp, bp
xor   di, di


loop_next_yslope:
mov   cx, bp
_SELFMODIFY_sub_viewheight_shr_1:
sub   cx, 01000h
jns   skip_labs
neg   cx
inc   cx
skip_labs:
mov   bx, 08000h
_SELFMODIFY_viewwidth_precalculate:
mov   ax, 01000h
db    09Ah
dw    FIXEDDIVWHOLEA_ML, PHYSICS_HIGHCODE_SEGMENT

mov   bx, YSLOPE_SEGMENT
mov   es, bx
stosw
xchg  ax, dx
stosw
inc   bp
cmp   bp, si
jl    loop_next_yslope


;	for (i = 0; i < viewwidth; i++) {
;		an = xtoviewangle[i];
;		cosadj = labs(finecosine[an]);
;		distscale[i] = FixedDivWholeA(1, cosadj);
;	}


xor   si, si
mov   di, si
mov   bp, word ptr ds:[_viewwidth]
shl   bp, 1  ; word compare with si index as i

loop_next_distscale_calc:
mov   ax, XTOVIEWANGLE_SEGMENT
mov   ds, ax

lodsw
xchg  ax, bx
; word lookup
shl   bx, 1
lea   ax, [bx + 01000h]
SHIFT_MACRO shl ax 2
cwd

mov   cx, dx
mov   ax, FINECOSINE_SEGMENT
mov   ds, ax
mov   bx, word ptr ds:[bx]
test  cx, cx
; cosine is 17 bit in a 32 bit storage... we can probably figure out a way to do this without labs.

jns   dont_do_labs
neg   cx
neg   bx
sbb   bx, 0
dont_do_labs:
mov   ax, 1
db    09Ah
dw    FIXEDDIVWHOLEA_ML, PHYSICS_HIGHCODE_SEGMENT


mov   bx, DISTSCALE_SEGMENT
mov   es, bx
stosw
xchg  ax, dx
stosw
cmp   si, bp
jl    loop_next_distscale_calc

push  ss
pop   ds

call  Z_QuickMapRender_


;	// Calculate the light levels to use
;	//  for each level / scale combination.
;	for (i2 = 0; i2 < LIGHTLEVELS; i2++) {
;		startmap = ((LIGHTLEVELS - 1 - i2) << 2);
;		for (j = 0; j < MAXLIGHTSCALE; j++) {
;			level = startmap - ((j * SCREENWIDTH / (viewwidth << detailshift.b.bytelow)) >> 1);
;			if (level < 0) {
;				level = 0;
;			}
;			if (level >= NUMCOLORMAPS) {
;				level = NUMCOLORMAPS - 1;
;			}
;			// pre shift by 2 here, since its ultimately shifted by 2 for the colfunc lookup addr..
;			scalelight[i2*MAXLIGHTSCALE+j] =  level << 2;// * 256;
;		}
;	}

xor   di, di
mov   ax, SCALELIGHT_SEGMENT
mov   es, ax
mov   ax, word ptr ds:[_viewwidth]
mov   cl, byte ptr ds:[_detailshift]
shl   ax, cl
xchg  ax, cx   ; cx = viewwidth << detailshift.b.bytelow for division

xor   bp, bp   ; i2

outer_lightscale_loop:
mov   ax, LIGHTLEVELS - 1
xor   bx, bx
sub   ax, bp
SHIFT_MACRO shl ax 2
xchg  ax, si    ; si = startmap
; si = startmap
; bx = j * SCREENWIDTH
; cx = viewwidth << detailshift

inner_lightscale_loop:

mov   ax, bx
cwd
div   cx
mov   dx, si
shr   ax, 1
sub   dx, ax  
xchg  ax, dx
js    use_level_0
cmp   ax, NUMCOLORMAPS
jge   use_max_colormaps
jmp   set_value

use_max_colormaps:
mov   al, NUMCOLORMAPS - 1
jmp   set_value
use_level_0:
xor   ax, ax
set_value:

stosb
add   bx, SCREENWIDTH
cmp   bx, (SCREENWIDTH * MAXLIGHTSCALE)  ; 0x3C00
jb    inner_lightscale_loop
inc   bp
cmp   bp, LIGHTLEVELS
jb    outer_lightscale_loop

POPA_NO_AX_MACRO



ret


ENDP



PROC    R_ExecuteSetViewSize_ NEAR
PUBLIC  R_ExecuteSetViewSize_

push  bx
push  cx
push  dx

xor   cx, cx
xor   ax, ax
mov   byte ptr ds:[_setsizeneeded], cl
mov   byte ptr ds:[_hudneedsupdate], 6
cmp   byte ptr ds:[_setblocks], 11
jne   notfullscreen
fullscreen:
mov   word ptr ds:[_scaledviewwidth], SCREENWIDTH
mov   byte ptr ds:[_viewheight], SCREENHEIGHT
jmp   done_with_screensize

notfullscreen:
mov   al, byte ptr ds:[_setblocks]
SHIFT_MACRO  sal ax 5
mov   word ptr ds:[_scaledviewwidth], ax
;		viewheight = (setblocks * 168 / 10)&~7;
mov   al, 168 
mul   byte ptr ds:[_setblocks]
mov   dl, 10
div   dl
and   al, 0F8h   ; make multiple of 8.
mov   byte ptr ds:[_viewheight], al

done_with_screensize:


;	detailshift.b.bytelow = pendingdetail;
;	detailshift.b.bytehigh = (pendingdetail << 2); // high bit contains preshifted by four pendingdetail


mov   al, byte ptr ds:[_pendingdetail]
mov   ah, al
SHIFT_MACRO  sal ah 2
mov   word ptr ds:[_detailshift], ax

;	detailshift2minus =  (2-pendingdetail);
;	detailshiftitercount = 1 << (detailshift2minus);
;	detailshiftandval = 0 - detailshiftitercount;

mov   ah, 2
sub   ah, al
mov   byte ptr ds:[_detailshift2minus], ah
mov   cl, ah
mov   ah, 1
sal   ah, cl
mov   byte ptr ds:[_detailshiftitercount], ah
neg   ah
mov   byte ptr ds:[_detailshiftandval], ah
mov   byte ptr ds:[_detailshiftandval+1], 0FFh   ; word value...

mov   cl, al

;	viewwidth = scaledviewwidth >> detailshift.b.bytelow;

mov   ax, word ptr ds:[_scaledviewwidth]
shr   ax, cl
mov   word ptr ds:[_viewwidth], ax


;	centerx = viewwidth >> 1;
shr   ax, 1
mov   word ptr ds:[_centerx], ax
;	centery = viewheight >> 1;

mov   ax, word ptr ds:[_viewheight]
shr   ax, 1
mov   word ptr ds:[_centery], ax



;	// multiple of 16 guaranteed.. can be a segment instead of offset
;	viewwindowx = (SCREENWIDTH - scaledviewwidth) >> 1;
mov   cx, SCREENWIDTH
sub   cx, word ptr ds:[_scaledviewwidth]
shr   cx, 1
mov   word ptr ds:[_viewwindowx], cx


cmp   word ptr ds:[_scaledviewwidth], SCREENWIDTH
jne   raise_view_window_base
xor   ax, ax
jmp   set_view_window_base
raise_view_window_base:
;		viewwindowy = (SCREENHEIGHT - SBARHEIGHT - viewheight) >> 1;
mov   ax, (SCREENHEIGHT - SBARHEIGHT)
sub   ax, word ptr ds:[_viewheight]
shr   ax, 1

set_view_window_base:
mov   word ptr ds:[_viewwindowy], ax

;	viewwindowoffset = (viewwindowy*(SCREENWIDTH / 4)) + (viewwindowx >> 2);
mov   dx, (SCREENWIDTH / 4)
mul   dx

; viewwindowx >> 2
SHIFT_MACRO  shr cx 2  
add   ax, cx
mov   word ptr ds:[_viewwindowoffset], ax



call	R_InitTextureMapping_
;call	dword ptr ds:[_R_WriteBackViewConstants]
db    09Ah
_SELFMODIFY_R_WRITEBACKVIEWCONSTANTS:
dw    R_WRITEBACKVIEWCONSTANTS24OFFSET, 0
call	Z_QuickMapRenderPlanes_
;call	dword ptr ds:[_R_WriteBackViewConstantsSpanCall]
db    09Ah
_SELFMODIFY_R_WRITEBACKVIEWCONSTANTSSPANCALL:
dw    R_WRITEBACKVIEWCONSTANTSSPAN24OFFSET, SPANFUNC_JUMP_LOOKUP_SEGMENT
call	Z_QuickMapUndoFlatCache_
;call	dword ptr ds:[_R_WriteBackViewConstantsMaskedCall]
db    09Ah
_SELFMODIFY_R_WRITEBACKVIEWCONSTANTSMASKEDCALL:
dw    R_WRITEBACKVIEWCONSTANTSMASKED24OFFSET, MASKEDCONSTANTS_FUNCAREA_SEGMENT
call	Z_QuickMapPhysics_



;	spanfunc_outp[0] = 1;
;	spanfunc_outp[1] = 2;
;	spanfunc_outp[2] = 4;
;	spanfunc_outp[3] = 8;

mov     ax, 00201h ; detailshift 0 case
mov     word ptr ds:[_spanfunc_outp + 2], 0804h ; technically this never has to be changed 


;	if (detailshift.b.bytelow == 1){
;		spanfunc_outp[0] = 3;
;		spanfunc_outp[1] = 12;
;	}
;	if (detailshift.b.bytelow == 2){
;		spanfunc_outp[0] = 15;
;	}

cmp   byte ptr ds:[_detailshift], 1
jb    detail_0
ja    detail_2
detail_1:
mov   ax, 3 + (12 SHL 8)
jmp   done_checking_detail
detail_2:
mov   al, 15
done_checking_detail:
detail_0:

mov     word ptr ds:[_spanfunc_outp + 0], ax

pop   dx
pop   cx
pop   bx
ret

ENDP



PROC    R_SETUP_ENDMARKER_ NEAR
PUBLIC  R_SETUP_ENDMARKER_
ENDP
END
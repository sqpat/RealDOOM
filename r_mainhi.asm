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




EXTRN _lastvisplane:word
EXTRN _lastopening:word
EXTRN _viewheight:word
EXTRN _viewwidth:word

EXTRN FixedMulTrig_:PROC
EXTRN div48_32_:PROC
EXTRN FixedDiv_:PROC
EXTRN FixedMul1632_:PROC

EXTRN Z_QuickMapVisplanePage_:PROC
EXTRN _ceilphyspage:BYTE
EXTRN _floorphyspage:BYTE
EXTRN _visplanedirty:BYTE
EXTRN _active_visplanes:BYTE
EXTRN _floortop:DWORD
EXTRN _ceiltop:DWORD
EXTRN _visplane_offset:WORD
EXTRN _visplanelookupsegments:WORD
EXTRN _skyflatnum:BYTE

INCLUDE defs.inc

.CODE



;R_ScaleFromGlobalAngle_

PROC R_ScaleFromGlobalAngle_ NEAR
PUBLIC R_ScaleFromGlobalAngle_ 


push  bx
push  cx
push  si
push  di

; input ax = visangle_shift3

;    anglea = MOD_FINE_ANGLE(FINE_ANG90 + (visangle_shift3 - viewangle_shiftright3));
;    angleb = MOD_FINE_ANGLE(FINE_ANG90 + (visangle_shift3) - rw_normalangle);

add   ah, 8      
mov   dx, ax      ; copy input
sub   dx, word ptr ds:[_viewangle_shiftright3]  ; 
sub   ax, word ptr ds:[_rw_normalangle]

and   dh, 01Fh
and   ah, 01Fh

mov   di, ax

; dx = anglea
; di = angleb

mov   ax, FINESINE_SEGMENT
mov   si, ax
mov   bx, word ptr ds:[_rw_distance]
mov   cx, word ptr ds:[_rw_distance+2]

; todo is rw_distance = 0 a common case...?

;    den = FixedMulTrig(FINE_SINE_ARGUMENT, anglea, rw_distance);
 
call FixedMulTrig_


;    num.w = FixedMulTrig(FINE_SINE_ARGUMENT, angleb, projection.w)<<detailshift.b.bytelow;
 
;call FixedMulTrig16_
; inlined  16 bit times sine value

mov es, si
sal di, 1
sal di, 1
mov si, word ptr es:[di]
mov di, word ptr es:[di+2]
xchg dx, di
xchg ax, si

;  dx now has anglea
;  ax has finesine_segment
;  di:si is den

mov   cx, word ptr ds:[_centerx]


AND  DX, CX    ; DX*CX
NEG  DX
MOV  BX, DX    ; store high result

MUL  CX       ; AX*CX
ADD  DX, BX   


; di:si had den
; dx:ax has num

mov   cl, byte ptr ds:[_detailshift]
xor   ch, ch

; cl is 0 to 2

jcxz  shift_done
shl   ax, 1
rcl   dx, 1
dec   cl
jcxz  shift_done
shl   ax, 1
rcl   dx, 1

shift_done:


; di:si had den
; dx:ax has num



;    if (den > num.h.intbits) {

; annoying - we have to account for sign!
; is there a cleaner way?

 
mov    cx, ax  ; temp storage
mov    ax, dx
cwd            ; sign extend

cmp   di, dx
mov   dx, ax
mov   bx, si 

jg    do_divide  ; compare sign bits..




jne   return_maxvalue   ; less than case - result is greater than 0x1,0000,0000

; todo we can bitshift and catch more cases here...


; shift to account for 0x400000 compare

; so this does work but it triggers once every [many] frames, so wasting 8 ticks to save a hundred or two
; isn't worth it when the hit rate is < 1%
;mov ah, al
;xor al, al
;sal ah, 1
;sal ah, 1

cmp   si, ax    
ja    do_divide


return_maxvalue:
; rare occurence
mov   dx, 040h
xor   ax, ax
jmp normal_return

do_divide:

; set up params
mov   ax, cx  ; mov back..
mov   cx, di 

; we actually already bounds check more aggressively than fixeddiv
;  and guarantee positives here so the fixeddiv wrapper is unnecessary

; NOTE: a high word bounds triggered early return on the first divide result 
;   is super rare due to the outer checks...
;   doesnt occur even every frame. lets avoid the "optimized" dupe function.


call div48_32_

cmp   dx, 040h
jg    return_maxvalue
test  dx, dx
; dont need to check for negative result, this was unsigned.
je   continue_check 

normal_return:

pop   di
pop   si
pop   cx
pop   bx
ret

continue_check:
cmp   ax, 0100h
jnae   return_minvalue

; also normal return
pop   di
pop   si
pop   cx
pop   bx
ret

return_minvalue:
; super duper rare case. actually never caught it happening.
mov   ax, 0100h
xor   dx, dx

pop   di
pop   si
pop   cx
pop   bx
ret

endp


;R_PointToDist_

PROC R_PointToDist_ NEAR
PUBLIC R_PointToDist_ 


push  bx
push  cx
push  si
push  di

;    dx = labs(x.w - viewx.w);
;  x = ax register
;  y = dx

xor   bx, bx
mov   cx, ax
xor   ax, ax
; DX:AX = y
; CX:BX = x
sub   bx, word ptr ds:[_viewx]
sbb   cx, word ptr ds:[_viewx+2]

sub   ax, word ptr ds:[_viewy]
sbb   dx, word ptr ds:[_viewy+2]


or    cx, cx
jge   skip_x_abs
neg   bx
adc   cx, 0
neg   cx
skip_x_abs:

or    dx, dx
jge   skip_y_abs
neg   ax
adc   dx, 0
neg   dx
skip_y_abs:




;    if (dy>dx) {

cmp   dx, cx
jg    swap_x_y
jne   skip_swap_x_y
cmp   ax, bx
jbe   skip_swap_x_y

swap_x_y:
xchg  dx, cx
xchg  ax, bx
skip_swap_x_y:

;	angle = (tantoangle[ FixedDiv(dy,dx)>>DBITS ].hu.intbits+ANG90_HIGHBITS) >> SHORTTOFINESHIFT;

; save dx (var not register)

mov   si, bx
mov   di, cx



; dx:ax ffa0fd1a


call  FixedDiv_

; shift 5. since we do a tantoangle lookup... this maxes at 2048
sar   dx, 1
rcr   ax, 1
sar   dx, 1
rcr   ax, 1
sar   dx, 1
rcr   ax, 1
and   al, 0FCh
mov   dx, di ; move di to dx early to free up di for les + di + bx combo


mov   bx, ax
mov   es, word ptr ds:[_tantoangle] 
mov   bx, word ptr es:[bx + 2] ; get just intbits..

;    dist = FixedDiv (dx, finesine[angle] );	

add   bh, 040h ; ang90 highbits
mov   ax, FINESINE_SEGMENT
shr   bx, 1
and   bl, 0FCh
mov   es, ax
mov   ax, si
mov   cx, word ptr es:[bx + 2]
mov   bx, word ptr es:[bx]
call  FixedDiv_

pop   di
pop   si
pop   cx
pop   bx
ret   

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
; todo double check jge vs jg
jg    return_true

; return false
xor   ax, ax

LEAVE_MACRO
pop   di
ret   
ret_ldx_less_than_lx:

;            return ldx < lx;

cmp    si, bx
; todo double check jle vs jl
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
pop bx
mov   cx, dx
call FixedMul1632_

; set up params..
pop bx
mov   cx, di
mov   ds, ax
mov   ax, si
mov   di, dx
call FixedMul1632_
cmp   dx, di
jg    return_true_2
je    check_lowbits
return_false_2:
xor   ax, ax
mov   di, ss ;  restore ds
mov   ds, di
pop   bp
pop   di
ret   

check_lowbits:
mov   cx, ds
cmp   ax, cx
jb    return_false_2
return_true_2:
mov   ax, 1

mov   di, ss ;  restore ds
mov   ds, di

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


endp


;R_ClearPlanes

PROC R_ClearPlanes_ NEAR
PUBLIC R_ClearPlanes_ 


push  bx
push  cx
push  dx
push  di


mov   cx, word ptr ds:[_viewwidth]
mov   dx, cx

xor   di, di
mov   ax, word ptr ds:[_viewheight]
mov bx, 08250h;  todo can this be better... 
mov es, bx

rep stosw  ; write vieweight to es:di

mov ax, 0FFFFh
mov di, 0280h  ; offset of ceilingclip within floorclip
mov cx, dx
rep stosw  ; write vieweight to es:di

inc ax   ; zeroed
mov   word ptr ds:[_lastvisplane], ax
mov   word ptr ds:[_lastopening], ax
mov   ax, word ptr ds:[_viewangle_shiftright3]
sub   ah, 08h   ; FINE_ANG90
and   ah, 01Fh    ; MOD_FINE_ANGLE
shl   ax, 2
mov   cx, word ptr ds:[_centerx]
mov   di, ax

mov   ax, FINECOSINE_SEGMENT

mov   es, ax

mov   word ptr ds:[_viewwidth], dx
mov   ax, word ptr es:[di]
mov   dx, word ptr es:[di + 2]
mov   bx, 0

call FixedDiv_  ; TODO! FixedDivWholeB? Optimize?
mov   word ptr ds:[_basexscale], ax
mov   word ptr ds:[_basexscale + 2], dx
mov   ax, FINESINE_SEGMENT

mov   es, ax
mov   cx, word ptr ds:[_centerx]
mov   ax, word ptr es:[di]
mov   dx, word ptr es:[di + 2]
mov   bx, 0
call FixedDiv_  ; TODO! FixedDivWholeB? Optimize?
neg   dx
neg   ax
sbb   dx, 0
mov   word ptr ds:[_baseyscale], ax
mov   word ptr ds:[_baseyscale + 2], dx


pop   di
pop   dx
pop   cx
pop   bx
ret   

endp





;R_HandleEMSPagination

PROC R_HandleEMSPagination_ NEAR
PUBLIC R_HandleEMSPagination_ 

; input: 
; al is index, dl is isceil

; in func:
; ah stores 0  (copied to and from dx/bx)
; al stores various things
; dl stores usedvirtualpage
; dh stores 0 (copied to and from ax/bx)
; bl stores usedphyspage
; bh stores 0 (bx indexed a lot, copied to/from ax/dx )
; cl stores isceil
; ch stores usedsubindex

push  bx
push  cx

mov   cl, dl        ; copy is_ceil to cl
mov   ch, al
xor   dx, dx
cmp   al, VISPLANES_PER_EMS_PAGE
jae   loop_cycle_visplane_ems_page
visplane_ems_page_ready:
cmp   byte ptr ds:[_visplanedirty], 0
je    visplane_not_dirty
visplane_dirty_or_index_over_max_conventional_visplanes:
mov   bx, dx


mov   al, byte ptr ds:[bx + _active_visplanes]
test  al, al
xchg  ax, dx
je    do_quickmap_ems_visplaes
; found active visplane page 
mov   bl, dl
dec   bl
return_visplane:

test  cl, cl    ; check isceil
je    is_floor_2

mov   byte ptr ds:[_ceilphyspage], bl
sal   bx, 1
mov   dx, word ptr ds:[bx + _visplanelookupsegments] ; return value for ax

mov   bl, ch
sal   bx, 1

mov   ax, word ptr ds:[bx + _visplane_offset]
add   ax, 2

mov   word ptr ds:[_ceiltop], ax
sub   ax, 2
mov   word ptr ds:[_ceiltop+2], dx


pop   cx
pop   bx
ret   
is_floor_2:
mov   byte ptr ds:[_floorphyspage], bl   
sal   bx, 1
mov   dx, word ptr ds:[bx + _visplanelookupsegments] ; return value for ax

mov   bl, ch
sal   bx, 1

mov   ax, word ptr ds:[bx + _visplane_offset]
add   ax, 2

mov   word ptr ds:[_floortop], ax
sub   ax, 2
mov   word ptr ds:[_floortop+2], dx

pop   cx
pop   bx
ret
loop_cycle_visplane_ems_page:  ; move this above func
sub   ch, VISPLANES_PER_EMS_PAGE
inc   dl
cmp   ch, VISPLANES_PER_EMS_PAGE
jae   loop_cycle_visplane_ems_page
jmp   visplane_ems_page_ready
visplane_not_dirty:
cmp   al, MAX_CONVENTIONAL_VISPLANES  
jge   visplane_dirty_or_index_over_max_conventional_visplanes
mov   bx, dx
jmp   return_visplane
do_quickmap_ems_visplaes:
test  cl, cl    ; check isceil
je    is_floor
; is ceil
cmp   byte ptr ds:[_floorphyspage], 2  
jne   use_phys_page_2
use_phys_page_1:
mov   bl, 1

mov   dl, bl


call  Z_QuickMapVisplanePage_
jmp   return_visplane
use_phys_page_2:
mov   bl, 2
mov   dl, bl


call  Z_QuickMapVisplanePage_
jmp   return_visplane
is_floor:
cmp   byte ptr ds:[_ceilphyspage], 2
je    use_phys_page_1
mov   bl, 2
mov   dl, bl

call  Z_QuickMapVisplanePage_
jmp   return_visplane



ENDP


; todo... when the caller is in asm, put all the params in asm instead of stack shenanigans

;R_FindPlane_

PROC R_FindPlane_ NEAR
PUBLIC R_FindPlane_ 


; bp - 2 is i
; bp - 4
; bp - 5 is lightlevel
; bp - 6 is picnum
; bp - 8 is 

; dx:ax is height
; cl is lightlevel
; bl is picnum

push      si
push      di
push      bp
mov       bp, sp
sub       sp, 6
cmp       bl, byte ptr ds:[_skyflatnum]
jne       not_skyflat
xor       ax, ax
cwd
xor       cl, cl
not_skyflat:

; set up find visplane loop
push      ax  ; set bp - 8
mov       word ptr [bp - 2], 0
mov       byte ptr [bp - 6], bl
mov       byte ptr [bp - 5], cl
cmp       word ptr ds:[_lastvisplane], 0
jl        compare_visplane
mov       cx, word ptr ds:[_lastvisplane]
mov       bx, _visplaneheaders
add       cx, cx
xor       ax, ax
mov       word ptr [bp - 4], cx
mov       cx, word ptr [bp - 6]
label7:
mov       di, bx
cmp       ax, word ptr [bp - 4]
jne       label3
compare_visplane:
mov       ax, word ptr [bp - 2]
cmp       ax, word ptr ds:[_lastvisplane]
jge       not_found_create_new_visplane

; found visplane match. return it
mov       al, byte ptr [bp + 8]
cbw      
mov       dx, ax
mov       al, byte ptr [bp - 2]

call      R_HandleEMSPagination_
; fetch and return i
mov       ax, word ptr [bp - 2]

LEAVE_MACRO

pop       di
pop       si
ret       2
label3:
mov       si, word ptr [bp - 8]
cmp       dx, word ptr [bx + 2]
jne       label5
cmp       si, word ptr [bx]
jne       label5
mov       si, ax
add       si, _visplanepiclights
cmp       cx, word ptr [si]
je        compare_visplane
label5:
inc       word ptr [bp - 2]
add       bx, 8
mov       si, word ptr [bp - 2]
add       ax, 2
cmp       si, word ptr ds:[_lastvisplane]
jle       label7
jmp       compare_visplane
not_found_create_new_visplane:
mov       ax, word ptr [bp - 8]
mov       word ptr [di + 4], SCREENWIDTH
mov       word ptr [di], ax
mov       ax, word ptr [bp - 2]
mov       word ptr [di + 6], 0FFFFh
add       ax, ax
mov       word ptr [di + 2], dx
mov       bx, ax
mov       ax, word ptr [bp - 6]
mov       word ptr [bx - 0DF0h], ax   ; todo what is this
mov       al, byte ptr [bp + 8]
cbw      
mov       dx, ax
mov       al, byte ptr [bp - 2]
inc       word ptr ds:[_lastvisplane]
cbw      
add       bx, _visplanepiclights  ; todo is this used
call      R_HandleEMSPagination_

;; ff out pl top
mov       di, ax
mov       es, dx

mov       cx, (SCREENWIDTH / 2) + 1    ; one extra word for pad
mov       ax, 0FFFFh
rep stosw 


; zero out pl bot
; di is already set
inc       ax   ; zeroed
mov       cx, (SCREENWIDTH / 2) + 1  ; one extra word for pad
rep stosw 


mov       ax, word ptr [bp - 2]

LEAVE_MACRO


pop       di
pop       si
ret       2

ENDP


END

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

; todo move these all out


EXTRN _lastvisplane:word
EXTRN _lastopening:word
EXTRN _viewheight:word
EXTRN _viewwidth:word

EXTRN FixedMulTrig_:PROC
EXTRN div48_32_:PROC
EXTRN FixedDiv_:PROC
EXTRN FixedMul1632_:PROC
EXTRN R_AddSprites_:PROC
EXTRN R_AddLine_:PROC
EXTRN Z_QuickMapVisplanePage_:PROC
EXTRN Z_QuickMapVisplaneRevert_:PROC
EXTRN Z_QuickMapFlatPage_:PROC
EXTRN W_CacheLumpNumDirect_:PROC
EXTRN R_EvictFlatCacheEMSPage_:NEAR
EXTRN R_MarkL2FlatCacheLRU_:NEAR


EXTRN _ceilphyspage:BYTE
EXTRN _floorphyspage:BYTE
EXTRN _visplanedirty:BYTE
EXTRN _active_visplanes:BYTE
EXTRN _floortop:DWORD
EXTRN _ceiltop:DWORD
EXTRN _visplane_offset:WORD
EXTRN _visplanelookupsegments:WORD
EXTRN _skyflatnum:BYTE

EXTRN _frontsector:DWORD
EXTRN _floorplaneindex:WORD
EXTRN _ceilingplaneindex:WORD


EXTRN _lastflatcacheindicesused:BYTE
EXTRN _allocatedflatsperpage:BYTE
EXTRN _currentflatpage:BYTE
EXTRN _firstflat:BYTE
EXTRN _MULT_256:BYTE
EXTRN _FLAT_CACHE_PAGE:BYTE
EXTRN _extralight:BYTE
EXTRN _lightshift7lookup:BYTE
EXTRN _MULT_4096:BYTE

FIRST_FLAT_CACHE_LOGICAL_PAGE = 026h

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



;R_FindPlane_

PROC R_FindPlane_ NEAR
PUBLIC R_FindPlane_ 



; dx:ax is height
; cx is picandlight
; bl is icceil

push      si
push      di

cmp       cl, byte ptr ds:[_skyflatnum]
jne       not_skyflat

;		height = 0;			// all skys map together
;		lightlevel = 0;

xor       ax, ax
cwd
xor       ch, ch
not_skyflat:


; loop vars

; al = i
; ah = lastvisplane
; dx is height high precision
; di is height low precision
; bx is .. checkheader
; cx is pic_and_light
; si is visplanepiclights[i] (used for visplanelights lookups)


; set up find visplane loop
mov       di, ax  
push      bx  ; push isceil

; init loop vars
xor       ax, ax
mov       si, _visplanepiclights    ; initial offset
mov       ah, byte ptr ds:[_lastvisplane]

cmp       ah, 0
jl        break_loop   ; else break

; do loop setup

mov       al, 0
mov       bx, _visplaneheaders   ; set bx to header 0


next_loop_iteration:

cmp       al, ah
jne       check_for_visplane_match

break_loop:
;         al is i, ah is lastvisplane
cmp       al, ah
jge       break_loop_visplane_not_found

; found visplane match. return it
cbw       ; clear lastvisplane out of ah
pop       dx  ; get isceil
mov       bx, ax        ; store i
call      R_HandleEMSPagination_
; fetch and return i
mov       ax, bx


pop       di
pop       si
ret       


;		if (height == checkheader->height
;			&& piclight.hu == visplanepiclights[i].pic_and_light) {
;				break;
;		}

check_for_visplane_match:
cmp       di, word ptr [bx]     ; compare height low word
jne       loop_iter_step_variables
cmp       dx, word ptr [bx + 2] ; compare height high word
jne       loop_iter_step_variables
cmp       cx, word ptr [si] ; compare picandlight
je        break_loop

loop_iter_step_variables:
inc       al
add       si, 2
add       bx, 8

cmp       al, ah
jle       next_loop_iteration
sub       bx, 8  ; use last checkheader index
jmp       break_loop


break_loop_visplane_not_found:
; not found, create new visplane

cbw       ; no longer need lastvisplane, zero out ah


; set up new visplaneheader
mov       word ptr [bx], di
mov       word ptr [bx + 2], dx
mov       word ptr [bx + 4], SCREENWIDTH
mov       word ptr [bx + 6], 0FFFFh

;si already has  word lookup for piclights


mov       word ptr ds:[si], cx 

pop       dx  ; get isceil
inc       word ptr ds:[_lastvisplane]

mov       si, ax     ; store i      

call      R_HandleEMSPagination_

;; ff out pl top
mov       di, ax
mov       es, dx

mov       cx, (SCREENWIDTH / 2) + 1    ; one extra word for pad
mov       ax, 0FFFFh
rep stosw 


; zero out pl bot
; di is already set
;inc       ax   ; zeroed
;mov       cx, (SCREENWIDTH / 2) + 1  ; one extra word for pad
;rep stosw 


mov       ax, si


pop       di
pop       si
ret       

ENDP



SUBSECTOR_OFFSET_IN_SECTORS       = (SUBSECTORS_SEGMENT - SECTORS_SEGMENT) * 16
;SUBSECTOR_LINES_OFFSET_IN_SECTORS = (SUBSECTOR_LINES_SEGMENT - SECTORS_SEGMENT) * 16

;R_Subsector_

PROC R_Subsector_ NEAR
PUBLIC R_Subsector_ 


;ax is subsecnum

push  bx
push  cx
push  dx
push  bp
mov   bp, sp ; todo remove when we can?

mov   bx, ax
mov   ax, SUBSECTOR_LINES_SEGMENT
mov   es, ax
mov   al, byte ptr es:[bx]
xor   ah, ah
mov   word ptr cs:[SELFMODIFY_countvalue+1], ax    ; di stores count for later

mov   ax, SECTORS_SEGMENT
mov   es, ax

shl   bx, 1
shl   bx, 1

mov   ax, word ptr es:[bx+SUBSECTOR_OFFSET_IN_SECTORS] ; get subsec secnum

shl   ax, 4    ; todo make  8086 friendly
mov   word ptr ds:[_frontsector], ax
mov   word ptr ds:[_frontsector+2], es   ; es holds sectors_segment..
mov   bx, word ptr es:[bx+SUBSECTOR_OFFSET_IN_SECTORS + 2]   ; get subsec firstline
xchg  bx, ax
mov   word ptr cs:[SELFMODIFY_firstlinevalue+1], ax    ; di stores count for later


cmp   byte ptr [_visplanedirty], 0
jne   revert_visplane

prepare_fields:

;	ceilphyspage = 0;
;	floorphyspage = 0;
;	ceiltop = NULL;
;	floortop = NULL;

xor   ax, ax
; todo: put these variables all next to each other, then knock them out
; with movsw
mov   byte ptr ds:[_ceilphyspage], al
mov   byte ptr ds:[_floorphyspage], al

;  es:bx holds frontsector
mov   word ptr ds:[_ceiltop], ax
mov   word ptr ds:[_ceiltop+2], ax
mov   word ptr ds:[_floortop], ax
mov   word ptr ds:[_floortop+2], ax


mov   dx, word ptr es:[bx]
; ax is already 0

;	SET_FIXED_UNION_FROM_SHORT_HEIGHT

sar   dx, 1
rcr   ax, 1
sar   dx, 1
rcr   ax, 1
sar   dx, 1
rcr   ax, 1

cmp   dx, word ptr ds:[_viewz + 2]
jl    find_floor_plane_index
je    check_viewz_lowbits_floor

set_floor_plane_minus_one:
mov   word ptr ds:[_floorplaneindex], 0FFFFh
jmp   floor_plane_set
revert_visplane:
call  Z_QuickMapVisplaneRevert_
jmp   prepare_fields


set_ceiling_plane_minus_one:

; es:bx is still frontsector
mov   cl, byte ptr es:[bx + 5]
cmp   cl, byte ptr ds:[_skyflatnum]
je    find_ceiling_plane_index
mov   word ptr ds:[_ceilingplaneindex], 0FFFFh
jmp   do_addsprites

check_viewz_lowbits_floor:
cmp   ax, word ptr ds:[_viewz]
jae   set_floor_plane_minus_one    ; todo move to the other label
find_floor_plane_index:

; set up picandlight
mov   ch, byte ptr es:[bx + 0Eh]
mov   cl, byte ptr es:[bx + 4]
xor   bx, bx ; isceil = 0
call  R_FindPlane_
mov   word ptr ds:[_floorplaneindex], ax
floor_plane_set:
les   bx, dword ptr ds:[_frontsector]
mov   dx, word ptr es:[bx + 2]
xor   ax, ax
;	SET_FIXED_UNION_FROM_SHORT_HEIGHT

sar   dx, 1
rcr   ax, 1
sar   dx, 1
rcr   ax, 1
sar   dx, 1
rcr   ax, 1


cmp   dx, word ptr ds:[_viewz + 2]
jg    find_ceiling_plane_index
jne   set_ceiling_plane_minus_one
cmp   ax, word ptr ds:[_viewz]
jbe   set_ceiling_plane_minus_one
find_ceiling_plane_index:
les   bx, dword ptr ds:[_frontsector]

; set up picandlight
mov   ch, byte ptr es:[bx + 0Eh]
mov   cl, byte ptr es:[bx + 5]
mov   bx, 1

call  R_FindPlane_
mov   word ptr ds:[_ceilingplaneindex], ax
do_addsprites:
mov   ax, word ptr ds:[_frontsector]
mov   dx, word ptr ds:[_frontsector+2]
; todo make this not a function argument if its always frontsector?
call  R_AddSprites_

SELFMODIFY_countvalue:
mov   cx, 0FFFFh
SELFMODIFY_firstlinevalue:
mov   bx, 0FFFFh

loop_addline:

; what if we inlined AddLine? or unrolled this?
; whats realistic maximum of numlines? a few hundred? might be 1800ish bytes... save about 10 cycles per call to addline maybe?


mov   ax, bx   ; bx has firstline
call  R_AddLine_
inc   bx

loop   loop_addline




LEAVE_MACRO 

pop   dx
pop   cx
pop   bx
ret   

ENDP

;R_CheckPlane_

PROC R_CheckPlane_ NEAR
PUBLIC R_CheckPlane_ 

; ax: index
; dx: start
; bx: stop
; cl: isceil?



; di holds visplaneheaders lookup. maybe should be si

push      si
push      di

mov       word ptr cs:[SELFMODIFY_setindex+1], ax
mov       si, dx    ; si holds start

mov       di, ax
shl       di, 1
shl       di, 1
shl       di, 1
add       di, _visplaneheaders  ; _di is plheader
mov       byte ptr cs:[SELFMODIFY_setisceil + 1], cl  ; write cl value
test      cl, cl
mov       cx, bx    ; cx holds stop
je        check_plane_is_floor
check_plane_is_ceil:
les       bx, dword ptr ds:[_ceiltop]
loaded_floor_or_ceiling:
; bx holds offset..

mov       ax, si  ; fetch start
cmp       ax, word ptr [di + 4]    ; compare to minx
jge       start_greater_than_min
mov       word ptr cs:[SELFMODIFY_setminx+3], ax
mov       dx, word ptr [di + 4]    ; fetch minx into intrl
checked_start:
; now checkmax
mov       ax, word ptr [di + 6]   ; fetch maxx, ax = intrh = plheader->max
cmp       cx, ax                  ; compare stop to maxx
jle       stop_smaller_than_max
mov       word ptr cs:[SELFMODIFY_setmax+3], cx
done_checking_max:

; begin loop checks

; x = intrl to intrh
; so use intrl as x
; dx = intrl
; ax = intrh


cmp       dx, ax        ; x<= intrh 
jg        breakloop

add       bx, dx
loop_increment_x:

;	pltop[x]==0xff

cmp       byte ptr es:[bx], 0FFh
jne       breakloop
; x++
inc       dx            
inc       bx
cmp       dx, ax
jle       loop_increment_x

breakloop:


;    if (x > intrh) {

cmp       dx, ax
jle       make_new_visplane
SELFMODIFY_setminx:
mov       word ptr [di + 4], 0FFFFh
SELFMODIFY_setmax:
mov       word ptr [di + 6], 0FFFFh

SELFMODIFY_setindex:
mov       ax, 0ffffh


pop       di
pop       si
ret       


check_plane_is_floor:
les       bx, dword ptr ds:[_floortop]
jmp       loaded_floor_or_ceiling
start_greater_than_min:
mov       ax, word ptr [di + 4]
; todo comment out since dx was si to begin with
mov       dx, si                ; put start into intrl
mov       word ptr cs:[SELFMODIFY_setminx+3], ax
jmp       checked_start
stop_smaller_than_max:
mov       word ptr cs:[SELFMODIFY_setmax+3], ax     ; unionh = plheader->max
mov       ax, cx                                    ; intrh = stop
jmp       done_checking_max

make_new_visplane:
mov       bx, word ptr ds:[_lastvisplane]  ; todo byte
mov       es, bx    ; store in es
sal       bx, 1   ; bx is 2 per index

; dx/ax is plheader->height
; done with old plheader..
mov       ax, word ptr ds:[di]
mov       dx, word ptr ds:[di + 2]

;	visplanepiclights[lastvisplane].pic_and_light = visplanepiclights[index].pic_and_light;

; generate index from di again. 
sub       di, _visplaneheaders
sar       di, 1
sar       di, 1
mov       di, word ptr [di + _visplanepiclights]

mov       word ptr [bx + _visplanepiclights], di
sal       bx, 1
sal       bx, 1 ; now bx is 8 per

; set all plheader fields for lastvisplane...
mov       word ptr [bx + _visplaneheaders], ax
mov       word ptr [bx + _visplaneheaders+2], dx
mov       word ptr [bx + _visplaneheaders+4], si ; looks weird
mov       word ptr [bx + _visplaneheaders+6], cx  ; looks weird




SELFMODIFY_setisceil:
mov       dx, 0000h     ; set isceil argument

mov       ax, es ; todo keep this from above somehow
mov       si, ax ; todo keep this from above somehow
cbw      

call      R_HandleEMSPagination_
mov       di, ax
mov       es, dx
mov       ax, 0FFFFh

mov       cx, (SCREENWIDTH / 2) + 1   ; plus one for the padding
rep stosw 


mov       ax, si
inc       word ptr [_lastvisplane]


pop       di
pop       si
ret       

ENDP



exit_drawplanes:
leave 
pop   di
pop   si
pop   dx
pop   cx
pop   bx
mov   byte ptr cs:[SELFMODIFY_drawplaneiter+1], 0
ret   

do_next_drawplanes_loop:	

inc   byte ptr cs:[SELFMODIFY_drawplaneiter+1]
add   word ptr [bp - 8], VISPLANE_BYTE_SIZE
jmp   drawplanes_loop
do_sky_flat_draw:
mov   bx, word ptr [bp - 8] ; get visplane offset
mov   cx, word ptr [bp - 6] ; and segment
mov   dx, word ptr [si + 6]
mov   ax, word ptr [si + 4]
;call  [_R_DrawSkyPlaneCallHigh]
db    09Ah
dw    R_DRAWSKYPLANE_OFFSET
dw    DRAWSKYPLANE_AREA_SEGMENT
inc   byte ptr cs:[SELFMODIFY_drawplaneiter+1]
add   word ptr [bp - 8], VISPLANE_BYTE_SIZE
jmp   drawplanes_loop

;R_DrawPlanes_

PROC R_DrawPlanes_ NEAR
PUBLIC R_DrawPlanes_ 

; ARGS none

; STACK
; bp - 8 visplaneoffset
; bp - 6 visplanesegment
; bp - 4 usedflatindex    ; maybe use DI to store this?
; bp - 2 physindex


push  bx
push  cx
push  dx
push  si
push  di
push  bp
mov   bp, sp
sub   sp, 08h
xor   ax, ax
mov   word ptr [bp - 8], ax
mov   word ptr [bp - 6], FIRST_VISPLANE_PAGE_SEGMENT   ; todo make constant visplane segment
mov   word ptr [bp - 2], ax
mov   word ptr [bp - 4], ax
mov   byte ptr cs:[SELFMODIFY_compareflatunloaded+1], al ; set flatunloaded to 0

drawplanes_loop:
SELFMODIFY_drawplaneiter:
mov   al, 0 ; get i value. this is at the start of the function so its hard to self modify. so we reset to 0 at the end of the function
cbw  
cmp   ax, word ptr [_lastvisplane]
jge   exit_drawplanes
shl   ax, 3
add   ax, offset _visplaneheaders
mov   si, ax
mov   ax, word ptr [si + 4]			; fetch visplane minx
cmp   ax, word ptr [si + 6]			; fetch visplane maxx
jnle   do_next_drawplanes_loop

loop_visplane_page_check:
cmp   word ptr [bp - 8], VISPLANE_BYTES_PER_PAGE
jnb   check_next_visplane_page


; todo: DI is (mostly) unused here. Can probably be used to hold something usedful.

mov   al, byte ptr cs:[SELFMODIFY_drawplaneiter+1]

cbw  

add   ax, ax
mov   bx, ax
mov   cx, word ptr [bx +  _visplanepiclights]
cmp   cl, byte ptr [_skyflatnum]
je    do_sky_flat_draw

do_nonsky_flat_draw:

mov   byte ptr cs:[SELFMODIFY_lookuppicnum+1], cl 
mov   al, ch
xor   ah, ah
sar   ax, LIGHTSEGSHIFT
add   al, byte ptr [_extralight]
cmp   al, LIGHTLEVELS
jb    lightlevel_in_range
mov   al, LIGHTLEVELS-1
lightlevel_in_range:

add   ax, ax
mov   bx, ax
mov   ax, word ptr [bx + _lightshift7lookup]
mov   word ptr ds:[_planezlight], ax
;mov   word ptr ds:[_planezlight + 2], ZLIGHT_SEGMENT  ; this is static and set in memory.asm

mov   ax, FLATTRANSLATION_SEGMENT
mov   es, ax
mov   bl, cl
xor   bh, bh

mov   bl, byte ptr es:[bx]
mov   ax, FLATINDEX_SEGMENT
mov   es, ax

mov   al, byte ptr es:[bx]
mov   byte ptr [bp - 4], al
cmp   al, 0ffh
jne   flat_loaded
xor   bx, bx
loop_find_flat:
cmp   byte ptr [bx + _allocatedflatsperpage], 4   ; if (allocatedflatsperpage[j]<4){
jl    found_page_with_empty_space
inc   bl
cmp   bl, NUM_FLAT_CACHE_PAGES
jge   found_flat_page_to_evict
jmp   loop_find_flat
check_next_visplane_page:
; do next visplane page
sub   word ptr [bp - 8], VISPLANE_BYTES_PER_PAGE
inc   byte ptr [bp - 2]
cmp   byte ptr [bp - 2], 3
je    do_visplane_pagination
lookup_visplane_segment:
mov   bx, word ptr [bp - 2]
add   bx, bx
mov   ax, word ptr [bx + _visplanelookupsegments]
mov   word ptr [bp - 6], ax
jmp   loop_visplane_page_check
do_visplane_pagination:
mov   al, byte ptr [_visplanedirty+3]
add   al, 3
mov   dx, 2
cbw  
mov   byte ptr [bp - 2], 2
call  Z_QuickMapVisplanePage_
jmp   lookup_visplane_segment




found_page_with_empty_space:

mov   al, bl ; bl is usedflatindex
shl   al, 2
mov   ah, byte ptr [bx + _allocatedflatsperpage]
add   ah, al
inc   byte ptr [bx + _allocatedflatsperpage]
mov   byte ptr [bp - 4], ah
found_flat:
mov   ax, FLATTRANSLATION_SEGMENT
mov   es, ax
mov   bl, cl
xor   bh, bh

mov   bl, byte ptr es:[bx]
mov   ax, FLATINDEX_SEGMENT
mov   es, ax
mov   al, byte ptr [bp - 4]
mov   byte ptr cs:[SELFMODIFY_compareflatunloaded+1], 1 ; update flat unloaded

mov   byte ptr es:[bx], al	; flatindex[flattranslation[piclight.bytes.picnum]] = usedflatindex;

; check l2 cache next
flat_loaded:
mov   dx, word ptr [bp - 4] ; a byte, but read the 0 together
sar   dx, 2
; dl = flatcacheL2pagenumber
cmp   dl, byte ptr [_currentflatpage+0]
je    in_flat_page_0

; check if L2 page is in L1 cache

cmp   dl, byte ptr [_currentflatpage+1]
jne   not_in_flat_page_1
mov   cl, 1
jmp   update_l1_cache
found_flat_page_to_evict:
call  R_EvictFlatCacheEMSPage_   ; al stores result..
shl   al, 2
mov   byte ptr [bp - 4], al
jmp   found_flat

not_in_flat_page_1:
cmp   dl, byte ptr [_currentflatpage+2]
jne   not_in_flat_page_2
mov   cl, 2
jmp   update_l1_cache
not_in_flat_page_2:
cmp   dl, byte ptr [_currentflatpage+3]
jne   not_in_flat_page_3
mov   cl, 3
jmp   update_l1_cache
not_in_flat_page_3:
; L2 page not in L1 cache. need to EMS remap

; doing word writes/reads instead of byte writes/reads when possible
mov   ch, byte ptr [_lastflatcacheindicesused]
mov   ax, word ptr [_lastflatcacheindicesused+1]
mov   cl, byte ptr [_lastflatcacheindicesused+3]

mov   word ptr [_lastflatcacheindicesused], cx
mov   word ptr [_lastflatcacheindicesused+2], ax

mov   ax, dx

mov   bl, cl
xor   bh, bh   ; ugly... can i do cx above
mov   byte ptr [bx + _currentflatpage], al
mov   dx, bx
add   ax, FIRST_FLAT_CACHE_LOGICAL_PAGE

call  Z_QuickMapFlatPage_
jmp   l1_cache_finished_updating
in_flat_page_0:
mov   cl, 0

update_l1_cache:
mov   ch, byte ptr [_lastflatcacheindicesused]
cmp   ch, cl
je    l1_cache_finished_updating
mov   ah, byte ptr [_lastflatcacheindicesused+1]
cmp   ah, cl
je    in_flat_page_1
mov   al, byte ptr [_lastflatcacheindicesused+2]
cmp   al, cl
je    in_flat_page_2
mov   byte ptr [_lastflatcacheindicesused+3], al
in_flat_page_2:
mov   byte ptr [_lastflatcacheindicesused+2], ah
in_flat_page_1:
mov   word ptr [_lastflatcacheindicesused], cx
l1_cache_finished_updating:
mov   ax, word ptr [bp - 4]
sar   ax, 2
cbw  
call  R_MarkL2FlatCacheLRU_
xor   ax, ax
SELFMODIFY_compareflatunloaded:
add   al, 0
jnz    flat_is_unloaded
flat_not_unloaded:
; calculate ds_source_segment
mov   ax, word ptr [bp - 4]
and   ax, 3
mov   bx, ax
add   bx, ax
mov   ax, word ptr [bx + _MULT_256]
mov   bl, cl
add   bx, bx
add   ax, word ptr [bx + _FLAT_CACHE_PAGE]

mov   word ptr ds:[_ds_source_segment], ax
mov   ax, word ptr [si]
mov   dx, word ptr [si + 2]
sub   ax, word ptr ds:[_viewz]
sbb   dx, word ptr ds:[_viewz + 2]
or    dx, dx

; planeheight = labs(plheader->height - viewz.w);

jge   planeheight_already_positive	; labs check
neg   ax
adc   dx, 0
neg   dx
planeheight_already_positive:
mov   word ptr ds:[_planeheight], ax
mov   word ptr ds:[_planeheight + 2], dx
mov   ax, word ptr [si + 6]
mov   di, ax
les   bx, dword ptr [bp - 8]

mov   byte ptr es:[bx + di + 3], 0ffh
mov   si, word ptr [si + 4]
mov   byte ptr es:[bx + si + 1], 0ffh
inc   ax

mov   word ptr cs:[SELFMODIFY_comparestop+2], ax ; set count value to be compared against in loop.

cmp   si, ax
jle   start_single_plane_draw_loop
jmp   do_next_drawplanes_loop
; flat is unloaded. load it in
flat_is_unloaded:
mov   bl, cl
xor   bh, bh

add   bx, bx
mov   cx, word ptr [bx + _FLAT_CACHE_PAGE]

mov   ax, FLATTRANSLATION_SEGMENT
mov   es, ax
SELFMODIFY_lookuppicnum:
; todo figure out how to lookup es:[00h] instead
mov   bl, 00h
mov   al, byte ptr es:[bx]    ; uses picnum from way above.

xor   ah, ah
add   ax, word ptr [_firstflat]
mov   bl, byte ptr [bp - 4]
and   bl, 3

add   bx, bx
mov   bx, word ptr [bx + _MULT_4096]

call  W_CacheLumpNumDirect_
jmp   flat_not_unloaded



start_single_plane_draw_loop:
; loop setup

single_plane_draw_loop:
; si is x, bx is plheader pointer. so adding si gets us plheader->top[x] etc.
les    bx, dword ptr [bp - 8]

;			t1 = pl->top[x - 1];
;			b1 = pl->bottom[x - 1];
;			t2 = pl->top[x];
;			b2 = pl->bottom[x];


mov   dx, word ptr es:[bx + si + 0143h]	; b1&b2
mov   cx, word ptr es:[bx + si + 1]		; t1&t2


mov   ax, SPANSTART_SEGMENT
mov   es, ax


; t1/t2 ch/cl
; b1/b2 dh/dl

;    while (t1 < t2 && t1 <= b1)
dec   si	; x - 1  constant
cmp   cl, ch

jae   done_with_first_mapplane_loop
loop_first_mapplane:
cmp   cl, dl
ja   done_with_first_mapplane_loop

mov   al, cl
xor   ah, ah
mov   bx, ax
add   bx, ax
push  es
push  dx
mov   dx, word ptr es:[bx] ; todo refactor params to mapplane?
mov   bx, si
inc   cl
;call  [_R_MapPlaneCall]
db    09Ah
dw    R_MAPPLANE_OFFSET
dw    SPANFUNC_FUNCTION_AREA_SEGMENT

pop   dx
pop   es
cmp   cl, ch
jae   done_with_first_mapplane_loop
jmp   loop_first_mapplane

end_single_plane_draw_loop_iteration:
;  todo: di not really in use at all in this loop. could be made to hold something useful
inc   si
SELFMODIFY_comparestop:
cmp   si, 1000h
jle   single_plane_draw_loop
jmp   do_next_drawplanes_loop

done_with_first_mapplane_loop:
loop_second_mapplane:
cmp   dl, dh
jbe    done_with_second_mapplane_loop
cmp   cl, dl
ja   done_with_second_mapplane_loop

mov   al, dl
xor   ah, ah
mov   bx, ax
add   bx, ax
dec   dl
push  es
push  dx
mov   dx, word ptr es:[bx]
mov   bx, si
;call  [_R_MapPlaneCall]
db    09Ah
dw    R_MAPPLANE_OFFSET
dw    SPANFUNC_FUNCTION_AREA_SEGMENT
pop   dx
pop   es
; todo do loop break check here with fall thru?
jmp   loop_second_mapplane
done_with_second_mapplane_loop:

; update spanstarts



; b1 = dl
; b2 = dh
; t1 = cl
; t2 = ch

;			while (t2 < t1 && t2 <= b2) {
;				spanstart[t2] = x;

inc   si  ; add one back from the previous saved x-1 state
mov   ax, SPANSTART_SEGMENT
mov   es, ax

mov   bx, cx

sub   cl, ch     ; t2 < t1?
jbe   second_spanstart_update_loop
mov   ax, dx
sub   ah, ch     ; t2 <= b2?
jb    second_spanstart_update_loop

inc   ah		; add one for the >= 
cmp   ah, cl
ja    dont_swap_cx_params_1  ; todo jae and inc inside
mov   cl, ah
dont_swap_cx_params_1:


mov   al, ch  ; get t2 word lookup...
xor   ah, ah
add   ax, ax
mov   di, ax  ; di = offset

xor   ch, ch  ; cx loop count is set
mov   ax, bx
add   bh, cl  ; add the t2 increment

mov   ax, si  ;  ax = x
rep   stosw



second_spanstart_update_loop:


;			while (b2 > b1 && b2 >= t2) {
;				spanstart[b2] = x;
; b1 = dl
; b2 = dh
; t1 = bl
; t2 = bh

mov   ax, dx
sub   ah, al    ; b2 - b1
jbe   end_single_plane_draw_loop_iteration
mov   cl, dh	; store b2 copy for spanstart addr calculation
sub   dh, bh    ; b2 - t2
jb    end_single_plane_draw_loop_iteration

; add one for the >= case 
inc   dh
; ah and ch store the two values... take the smallest one to get loop count
cmp   ah, dh
ja    dont_swap_cx_params_2
mov   dh, ah
dont_swap_cx_params_2:


xor   ch, ch
mov   di, cx  ; cl held copied b2 from above
add   di, di  ; di = offset

mov   cl, dh  ; count


mov   ax, si  ;  ax = x
std   
rep   stosw
cld
jmp   end_single_plane_draw_loop_iteration












ENDP




END

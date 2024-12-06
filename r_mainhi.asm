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



EXTRN FixedMul_:PROC
EXTRN FixedMulTrig_:PROC
EXTRN div48_32_:PROC
EXTRN FixedDiv_:PROC
EXTRN FixedMul1632_:PROC

EXTRN FastDiv3232_:PROC
EXTRN R_GetMaskedColumnSegment_:NEAR
;EXTRN R_RenderMaskedSegRange2_:NEAR
EXTRN R_AddSprites_:PROC
EXTRN R_AddLine_:PROC
EXTRN Z_QuickMapVisplanePage_:PROC
EXTRN Z_QuickMapVisplaneRevert_:PROC

EXTRN _R_DrawFuzzColumnCallHigh:DWORD
EXTRN _R_DrawMaskedColumnCallSpriteHigh:DWORD
EXTRN getspritetexture_:NEAR
EXTRN _lastvisspritepatch:WORD
EXTRN _lastvisspritepatch2:WORD
EXTRN _lastvisspritesegment:WORD
EXTRN _lastvisspritesegment2:WORD
EXTRN _vga_read_port_lookup:BYTE
EXTRN _psprites:BYTE
EXTRN _ds_p:DWORD
EXTRN _vissprite_p:DWORD
EXTRN _vsprsortedheadfirst:DWORD

EXTRN _maskedtexturecol:BYTE
EXTRN _maskedcachedbasecol:BYTE
EXTRN _maskedheaderpixeolfs:BYTE
EXTRN _maskedcachedsegment:WORD
EXTRN _maskedheightvalcache:BYTE
EXTRN _cachedbyteheight:BYTE
EXTRN _maskednextlookup:WORD
EXTRN _lightmult48lookup:BYTE
EXTRN _walllights:BYTE
EXTRN _R_DrawSingleMaskedColumnCallHigh:DWORD
EXTRN _R_DrawMaskedColumnCallHigh:DWORD
EXTRN _curseg:WORD
EXTRN _curseg_render:WORD
EXTRN _masked_headers:WORD



UNCLIPPED_COLUMN  = 0FFFEh


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

IF COMPILE_INSTRUCTIONSET GE COMPILE_186
 shl   ax, 2
ELSE
 shl   ax, 1
 shl   ax, 1
ENDIF
 
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


IF COMPILE_INSTRUCTIONSET GE COMPILE_186
 shl   ax, 4
ELSE
 shl   ax, 1
 shl   ax, 1
 shl   ax, 1
 shl   ax, 1
ENDIF


mov   word ptr ds:[_frontsector], ax
;mov   word ptr ds:[_frontsector+2], es   ; es holds sectors_segment..
mov   bx, word ptr es:[bx+SUBSECTOR_OFFSET_IN_SECTORS + 2]   ; get subsec firstline
xchg  bx, ax
mov   word ptr cs:[SELFMODIFY_firstlinevalue+1], ax    ; di stores count for later


cmp   byte ptr ds:[_visplanedirty], 0
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
mov   dx, SECTORS_SEGMENT
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
inc       word ptr ds:[_lastvisplane]


pop       di
pop       si
ret       

ENDP


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
mov   byte ptr cs:[SELFMODIFY_set_bx_to_lookup+1], al
mov   cx, 08E29h   ;  todo make dc_yl_lookup_maskedmapping a constant

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

db 0FFh  ; lcall[addr]
db 01Eh  ;
dw _R_DrawFuzzColumnCallHigh

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
mov   byte ptr cs:[SELFMODIFY_detailshiftitercount1+2], al
mov   byte ptr cs:[SELFMODIFY_detailshiftitercount2+4], al
mov   byte ptr cs:[SELFMODIFY_detailshiftitercount3+1], al
mov   byte ptr cs:[SELFMODIFY_detailshiftitercount4+2], al
mov   byte ptr cs:[SELFMODIFY_detailshiftitercount5+4], al
mov   byte ptr cs:[SELFMODIFY_detailshiftitercount6+1], al


mov   ax, word ptr ds:[si + 01Eh]   ; vis->xiscale
mov   dx, word ptr ds:[si + 020h]

; labs
or    dx, dx
jge   xiscale_already_positive
neg   ax
adc   dx, 0
neg   dx
xiscale_already_positive:

xor   cx, cx
mov   cl, byte ptr ds:[_detailshift]



jcxz  xiscale_shift_done
sar   dx, 1
rcr   ax, 1
dec   cx
jcxz  xiscale_shift_done
sar   dx, 1
rcr   ax, 1
dec   cx
jcxz  xiscale_shift_done
sar   dx, 1
rcr   ax, 1
xiscale_shift_done:

mov   word ptr ds:[_dc_iscale], ax
mov   word ptr ds:[_dc_iscale+2], dx

mov   ax, word ptr [si + 022h] ; vis->texturemid
mov   dx, word ptr [si + 024h]

mov   word ptr ds:[_dc_texturemid], ax
mov   word ptr ds:[_dc_texturemid + 2], dx

mov   bx, word ptr [si + 01Ah]  ; vis->scale
mov   cx, word ptr [si + 01Ch]  

mov   word ptr ds:[_spryscale], bx
mov   word ptr ds:[_spryscale + 2], cx

mov   ax, word ptr ds:[_centery]
mov   word ptr ds:[_sprtopscreen], 0
mov   word ptr ds:[_sprtopscreen + 2], ax


mov   ax, word ptr ds:[_dc_texturemid]
mov   dx, word ptr ds:[_dc_texturemid + 2]

call FixedMul_

sub   word ptr ds:[_sprtopscreen], ax
sbb   word ptr ds:[_sprtopscreen + 2], dx

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

mov   word ptr cs:[SELFMODIFY_set_ax_to_dc_x_base4+1], ax
mov   word ptr cs:[SELFMODIFY_set_ax_to_dc_x_base4_shadow+1], ax

sub   dx, ax
xchg  ax, dx
xor   cx, cx
mov   cl, byte ptr ds:[_detailshift2minus]


; xiscalestep_shift = vis->xiscale << detailshift2minus;

mov   bx, word ptr [si + 01Eh] ; DX:BX = vis->xiscale
mov   dx, word ptr [si + 020h]

; todo unroll if it doesnt break the jne above..
jcxz  done_shifting_shift_xiscalestep_shift
shl   bx, 1
rcl   dx, 1
dec   cx
jcxz  done_shifting_shift_xiscalestep_shift
shl   bx, 1
rcl   dx, 1
dec   cx
jcxz  done_shifting_shift_xiscalestep_shift
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
mov   byte ptr cs:[SELFMODIFY_set_bx_to_xoffset+1], 0
mov   byte ptr cs:[SELFMODIFY_set_bx_to_xoffset_shadow+1], 0

mov   cx, es


cmp   byte ptr [si + 1], COLORMAP_SHADOW
je    jump_to_draw_shadow_sprite


jmp loop_vga_plane_draw_normal 

  
sprite_not_first_cachedsegment:
cmp   ax, word ptr _lastvisspritepatch2
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
mov   word ptr _lastvisspritepatch2, dx
mov   dx, word ptr ds:[_lastvisspritesegment]
mov   word ptr ds:[_lastvisspritesegment2], dx
call  getspritetexture_
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

db 0FFh  ; lcall[addr]
db 01Eh  ;
dw _R_DrawMaskedColumnCallSpriteHigh

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
inc   word ptr cs:[SELFMODIFY_set_ax_to_dc_x_base4+1]
inc   byte ptr cs:[SELFMODIFY_set_bx_to_xoffset+1]
mov   ax, word ptr [si + 01Eh]
add   word ptr [bp - 4], ax
mov   ax, word ptr [si + 020h]
adc   word ptr [bp - 2], ax
jmp   loop_vga_plane_draw_normal
draw_shadow_sprite:
mov   ax, word ptr ds:[_destview]
mov   word ptr cs:[SELFMODIFY_set_dx_to_destview_offset+2], ax
mov   ax, word ptr ds:[_destview + 2]
mov   word ptr cs:[SELFMODIFY_set_bx_to_destview_segment+1], ax

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
inc   word ptr cs:[SELFMODIFY_set_ax_to_dc_x_base4_shadow+1]
inc   byte ptr cs:[SELFMODIFY_set_bx_to_xoffset_shadow+1]
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

mov  word ptr ds:[_mfloorclip], 0A280h  ; set offset to size_negonearray
mov  word ptr ds:[_mceilingclip], 0A000h ; set offset to size_openings

cmp  word ptr ds:[_psprites], -1  ; STATENUM_NULL
je  check_next_player_sprite
mov  ax, _player_vissprites       ; vissprite 0
call R_DrawVisSprite_

check_next_player_sprite:
cmp  word ptr ds:[_psprites + 0Ch], -1  ; STATENUM_NULL
je  exit_drawplayersprites
mov  ax, _player_vissprites + 028h ; vissprite 1
call R_DrawVisSprite_

exit_drawplayersprites:
ret 


ENDP

;todo move these to codegen

ML_TWOSIDED  = 4h
ML_DONTPEGBOTTOM  = 010h

PROC R_RenderMaskedSegRange_ NEAR
PUBLIC R_RenderMaskedSegRange_

;void __near R_RenderMaskedSegRange (drawseg_t __far* ds, int16_t x1, int16_t x2) {

;dx:ax is far drawseg pointer
;x1 is bx
;x2 is cx

; bp - 2        side_render
; bp - 4        lineflags
; bp - 6        maskedtexturecolumn todo put in register
; bp - 8        rw_scalestep_shift hi word
; bp - 0Ah      rw_scalestep_shift lo word
; bp - 0Ch      cached xoffset/di
; bp - 0Eh      UNUSED
; bp - 010h     sprtopscreen_step hi word
; bp - 012h     sprtopscreen_step lo word
; bp - 014h     basespryscale hi word
; bp - 016h     basespryscale lo word
; bp - 018h     UNUSED moved to cx xoffset (iterator) todo replace with selfmodify
; bp - 01Ah     UNUSED
; bp - 01Ch     rw_scalestep hi word
; bp - 01Eh     rw_scalestep lo word
; bp - 020h     UNUSED
; bp - 022h     UNUSED
; bp - 024h     UNUSED
; bp - 026h     UNUSED curseg pointer. pointless since its a var?
; bp - 028h     UNUSED v2.x
; bp - 02Ah     UNUSED v1.y
; bp - 02Ch     UNUSED side_render secnum todo selfmodify easy
; bp - 02Eh     UNUSED v1
; bp - 030h     UNUSED
; bp - 032h     dc_x_base4
; bp - 034h     drawseg far segment (this is a constant)
; bp - 036h     ds
push  si
push  di
push  bp
mov   bp, sp
sub   sp, 036h
mov   di, ax
mov   word ptr [bp - 036h], ax
mov   word ptr [bp - 034h], dx

mov   ax, bx
mov   word ptr cs:[SELFMODIFY_x1_field_1+1], ax
mov   word ptr cs:[SELFMODIFY_x1_field_2+1], ax
mov   word ptr cs:[SELFMODIFY_x1_field_3+1], ax

mov   word ptr cs:[SELFMODIFY_cmp_to_x2+1], cx
mov   es, dx
mov   ax, word ptr es:[di]       ; get ds->curseg
mov   word ptr ds:[_curseg], ax  
shl   ax, 1
shl   ax, 1
shl   ax, 1
add   ah, 040h					; segs_render is ds:[0x4000] todo constant
mov   word ptr ds:[_curseg_render], ax
mov   bx, ax
mov   ax, SIDES_SEGMENT
mov   si, word ptr [bx + 6]			; get sidedefOffset
mov   es, ax
shl   si, 1
shl   si, 1
mov   ax, si						; side_render_t is 4 bytes each
shl   si, 1							; side_t is 8 bytes each
add   ah, 0AEh						; sides render is ds:[0xAE00] todo constant
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
mov   word ptr cs:[SELFMODIFY_texnum_1+1], si
mov   word ptr cs:[SELFMODIFY_texnum_2+1], si
mov   word ptr cs:[SELFMODIFY_texnum_3+1], si

mov   byte ptr cs:[SELFMODIFY_compare_lookup+2], al

;	if (lookup != 0xFF){
cmp   al, 0FFh
je    lookup_not_ff

;		masked_header_t __near * maskedheader = &masked_headers[lookup];
;		maskedpostsofs = maskedheader->postofsoffset;
cbw
shl   ax, 3
mov   bx, ax
mov   ax, word ptr [bx + _masked_headers + 2]
mov   word ptr cs:[SELFMODIFY_maskedpostofs+3], ax
lookup_not_ff:

mov   ax, SEG_LINEDEFS_SEGMENT
mov   es, ax
mov   ax, word ptr ds:[_curseg]
mov   bx, ax
add   bh, 016h					; todo.... seg_sides_offset_in_seglines high word
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
shl   bx, 2
shl   cx, 2
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
mov   byte ptr cs:[SELFMODIFY_add_vertex_field], al


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
shl   bx, 2

mov   ax, word ptr ds:[bx + _sides_render + 2]   ; get a field in the sides render area

shl   ax, 4
backsector_set:
mov   word ptr ds:[_backsector], ax
mov   ax, SECTORS_SEGMENT
mov   es, ax
mov   bx, cx        ; retrieve side_render secnum from above
shl   bx, 4
mov   word ptr ds:[_frontsector], bx


mov   al, byte ptr es:[bx + 0Eh]
xor   ah, ah
mov   dx, ax
sar   dx, 4
mov   al, byte ptr ds:[_extralight]
add   ax, dx

SELFMODIFY_add_vertex_field:
nop				; becomes inc ax, dec ax, or nop

;	if (lightnum < 0){
test  ax, ax			; todo get for free?
jl   set_walllights_zero
cmp   ax, LIGHTLEVELS
jge   clip_lights_to_max
mov   bx, ax
add   bx, ax
mov   ax, word ptr [bx + _lightmult48lookup]
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
les   di, dword ptr [bp - 036h]          ; get drawseg far ptr

; es:di is input drawseg

;    maskedtexturecol = &openings[ds->maskedtexturecol];

mov   ax, word ptr es:[di + 01Ah]		; ds->maskedtexturecol
add   ax, ax
mov   word ptr ds:[_maskedtexturecol], ax
mov   word ptr ds:[_maskedtexturecol+2], OPENINGS_SEGMENT	; todo hardcode this in data

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
mov   word ptr [bp - 032h], ax

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
mov   cx, word ptr ds:[_detailshift2minus]

; cx is 0 to 2

jcxz  done_shifting_spryscale
shl   ax, 1
rcl   dx, 1
dec   cl
jcxz  done_shifting_spryscale
shl   ax, 1
rcl   dx, 1

done_shifting_spryscale:
mov   word ptr [bp - 0Ah], ax		; rw_scalestep_shift
mov   word ptr [bp - 8], dx			; rw_scalestep_shift
mov   cx, dx
mov   bx, ax

;		fixed_t sprtopscreen_step = FixedMul(dc_texturemid.w, rw_scalestep_shift);


mov   ax, word ptr ds:[_dc_texturemid]
mov   dx, word ptr ds:[_dc_texturemid + 2]
call  FixedMul_
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



check_outer_loop_conditions:

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
mov   ax, word ptr [bp - 032h]		; dc_x_base4
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

mov   bx, word ptr ds:[_spryscale]
mov   cx, word ptr ds:[_spryscale + 2]
mov   ax, word ptr ds:[_dc_texturemid]
mov   dx, word ptr ds:[_dc_texturemid + 2]
call  FixedMul_


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
LEAVE_MACRO 
pop   di
pop   si
ret   

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

increment_inner_loop:

les   bx, dword ptr ds:[_maskedtexturecol]
mov   ax, word ptr ds:[_dc_x]
add   ax, ax
add   bx, ax
mov   word ptr es:[bx], MAXSHORT

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
mov   al, 02Fh			; todo MAXLIGHTSCALE - 1;
get_colormap:
xor   ah, ah
mov   word ptr ds:[_dc_colormap_segment], COLORMAPS_SEGMENT_MASKEDMAPPING
mov   bx, word ptr ds:[_walllights]			; todo set this constant outside the loop?
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
call  FastDiv3232_
mov   word ptr ds:[_dc_iscale], ax
mov   word ptr ds:[_dc_iscale + 2], dx
mov   dh, ah	; todo why is ah needed
mov   ax, si
mov   ah, dh
sub   ax, di

; todo: make two loops instead of branching here?

;	if (lookup != 0xFF){
SELFMODIFY_compare_lookup:  
mov   dl, 0FFh
cmp   dl, 0FFh
je    lookup_FF ; todo fine?

; lookup NOT ff.

cmp   si, word ptr ds:[_maskednextlookup]
jae   load_masked_column_segment_lookup

cmp   si, di
jb    load_masked_column_segment_lookup

mov   ax, MASKEDPIXELDATAOFS_SEGMENT
mov   es, ax

cmp   word ptr ds:[_maskedheaderpixeolfs], -1
jne   calculate_maskedheader_pixel_ofs
mul   byte ptr ds:[_maskedheightvalcache]
go_draw_masked_column:
SELFMODIFY_add_maskedcachedsegment:
add   ax, 08000h;

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
call  dword ptr ds:[_R_DrawMaskedColumnCallHigh]

jmp   increment_inner_loop

calculate_maskedheader_pixel_ofs:
mov   bx, si
mov   ax, word ptr ds:[_maskedheaderpixeolfs]
sub   bx, di
add   bx, bx
add   bx, ax
mov   ax, word ptr es:[bx]
jmp   go_draw_masked_column

load_masked_column_segment_lookup:
mov   dx, si
SELFMODIFY_texnum_1:
mov   ax, 08000h
call  R_GetMaskedColumnSegment_  
mov   di, word ptr ds:[_maskedcachedbasecol]
mov   dx, word ptr [_maskedcachedsegment]   ; to offset for above
sub   ax, dx
mov   word ptr cs:[SELFMODIFY_add_maskedcachedsegment+1], dx
; todo put some cached values here in di, dh, dl, etc
; _maskedheaderpixeolfs is strong selfmodify candidate.
jmp   go_draw_masked_column


lookup_FF:

;	if (texturecolumn >= maskednextlookup ||
; 		texturecolumn < maskedcachedbasecol
cmp   si, word ptr ds:[_maskednextlookup]
jae   load_masked_column_segment
cmp   si, di
jb    load_masked_column_segment
mul   byte ptr ds:[_maskedheightvalcache]
add   ax, word ptr ds:[_maskedcachedsegment]

mov   dl, byte ptr ds:[_cachedbyteheight]  ; todo optimize this to a full word with 0 high byte in data. then optimize in _R_DrawSingleMaskedColumn_ as well
xor   dh, dh
call  dword ptr [_R_DrawSingleMaskedColumnCallHigh]  ; todo... do i really want this
jmp   update_maskedtexturecol_finish_loop_iter

load_masked_column_segment:
mov   dx, si
SELFMODIFY_texnum_2:
mov   ax, 08000h
call  R_GetMaskedColumnSegment_
mov   di, word ptr ds:[_maskedcachedbasecol]
mov   dl, byte ptr ds:[_cachedbyteheight]  ; todo optimize this to a full word with 0 high byte in data. then optimize in _R_DrawSingleMaskedColumn_ as well
xor   dh, dh
call  dword ptr [_R_DrawSingleMaskedColumnCallHigh]  ; todo... do i really want this
jmp   update_maskedtexturecol_finish_loop_iter

endp


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
;  (!ds->silhouette     && ds->maskedtexturecol == NULL_TEX_COL) ) {
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
;	if (ds->maskedtexturecol != NULL_TEX_COL) {
 
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
mov   dx, es
mov   bx, ax   ; todo figure out a way to keep bx 
mov   ax, di
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
mov   byte ptr cs:[SELFMODIFY_set_al_to_silhouette+1],  al

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
and   byte ptr cs:[SELFMODIFY_set_al_to_silhouette+1], 0FEh  
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


VISSPRITE_UNSORTED_INDEX    = 0FFh
VISSPRITE_SORTED_HEAD_INDEX = 0FEh


PROC R_SortVisSprites_ NEAR
PUBLIC R_SortVisSprites_

; bp - 2     vsprsortedheadfirst ?
; bp - 4     best ?
; bp - 8     UNUSED i (loop counter). todo selfmodify out.
; bp - 0ah   UNUSED vissprite_p pointer/count todo selfmodify out
; bp -034h   unsorted?


mov       ax, word ptr [_vissprite_p]
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
mov       byte ptr cs:[SELFMODIFY_loop_compare_instruction+1], al ; store count
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
add       bx, 028h  ; size visprites todo
cmp       ax, dx
jl        loop_set_vissprite_next

done_setting_vissprite_next:

sub        bx, 028h
mov       byte ptr cs:[SELFMODIFY_set_al_to_loop_counter+1], 0  ; zero loop counter

mov       al, VISSPRITE_SORTED_HEAD_INDEX

mov       byte ptr [bp - 2], al
mov       byte ptr ds:[_vsprsortedheadfirst], al
mov       byte ptr [bx], VISSPRITE_UNSORTED_INDEX
cmp       dx, 0  ; is this redundant?
jle       exit_sort_vissprites

loop_visplane_sort:

inc       byte ptr cs:[SELFMODIFY_set_al_to_loop_counter+1] ; update loop counter

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
mov       ah, 028h
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

mul       ah	  ; still 028h
mov       bx, ax

mov       al, byte ptr [bx+si]
cmp       al, VISSPRITE_UNSORTED_INDEX
jne       loop_sort_subloop
done_with_sort_subloop:
mov       di, word ptr [bp - 4]		; retrieve best visprite pointer
mov       al, byte ptr [bp - 034h]

cmp       al, dh
je        done_with_find_best_index_loop
mov       dl, 028h
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
cmp       byte ptr [_vsprsortedheadfirst], VISSPRITE_SORTED_HEAD_INDEX
jne       set_next_to_best_index

mov       byte ptr [_vsprsortedheadfirst], dh
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
mov	      ah, 028h
mul       ah
mov       bx, ax
add       bx, OFFSET _vissprites
mov       byte ptr [bx], dh
jmp       increment_visplane_sort_loop_variables

endp


END

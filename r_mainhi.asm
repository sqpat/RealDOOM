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

; todo move these all out once BSP code moved out of binary


EXTRN FixedMulTrig_:PROC
EXTRN div48_32_:PROC
EXTRN FixedDiv_:PROC
;EXTRN R_AddSprites_:PROC
EXTRN R_AddLine_:PROC
EXTRN Z_QuickMapVisplanePage_:PROC
EXTRN Z_QuickMapVisplaneRevert_:PROC
EXTRN FixedMulTrigNoShift_:PROC
EXTRN FixedMul_:PROC
EXTRN FastMul16u32u_:PROC
EXTRN FixedDivWholeA_:PROC
EXTRN R_PointToAngle_:PROC

EXTRN _validcount:WORD
EXTRN _spritelights:WORD
EXTRN _spritewidths_segment:WORD



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


cmp byte ptr ds:[_detailshift], 1
jb shift_done
je do_once
; fall thru do twice
shl   ax, 1
rcl   dx, 1
do_once:
shl   ax, 1
rcl   dx, 1
shift_done:


; di:si had den
; dx:ax has num



;    if (den > num.h.intbits) {

; annoying - we have to account for sign!
; is there a cleaner way?

 
xchg   cx, ax  ; temp storage
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
mov bx, FLOORCLIP_PARAGRAPH_ALIGNED_SEGMENT; 
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
; idea: put these variables all next to each other, then knock them out
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

;mov       dx, si                ; put start into intrl (dx was already si)
mov       word ptr cs:[SELFMODIFY_setminx+3], ax
jmp       checked_start
stop_smaller_than_max:
mov       word ptr cs:[SELFMODIFY_setmax+3], ax     ; unionh = plheader->max
mov       ax, cx                                    ; intrh = stop
jmp       done_checking_max

make_new_visplane:
mov       bx, word ptr ds:[_lastvisplane] 
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

mov       ax, es 
mov       si, ax 
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



FF_FRAMEMASK = 07Fh
FF_FULLBRIGHT = 080h
MINZ_HIGHBITS = 4
;R_ProjectSprite_

PROC R_ProjectSprite_ NEAR
PUBLIC R_ProjectSprite_ 

; es:si is sprite.
; es is a constant..



; bp - 2:	 	UNUSED   was rot (byte)
; bp - 4:    	thingsprite (byte)   do selfmodifying
; bp - 6:    	thingframe (byte)
; bp - 8:    	flip (?) (byte)      do selfmodifying
; bp - 0Ah:    	xscale hi
; bp - 0Ch:    	xscale lo
; bp - 0Eh:    	x1
; bp - 010h:	thing->y hi
; bp - 012h:	thing->y lo
; bp - 014h:	thing->x hi
; bp - 016h:    x2
; bp - 018h:	thing->x lo
; bp - 01Ah:	UNUSED was SPRITES_SEGMENT (far segment for spriteframes?)
; bp - 01Ch:	tz_w hi
; bp - 01Eh:	tr_x hi
; bp - 020h:    tr_y hi
; bp - 022h:    thing->flags2
; bp - 024h:    thing->x hi
; bp - 026h:    usedwidth
; bp - 028h:    thing->x lo
; bp - 02Ah:    thing->angle hibits. only used for rot.    do selfmodifying
; bp - 02Ch:    temp fracbits. probably something else is temp hibits..
; bp - 02Eh:    spriteindex. used for spriteframes and spritetopindex?
; bp - 030h:    gxt lo
; bp - 032h:    tr_x lo
; bp - 034h:    gxt lo
; bp - 036h:    gxt hi
; bp - 038h:    gxt hi
; bp - 060h;    overflowsprite (SIZEOF_VISSPRITE_T is 028h)


push  si
push  es
push  bp
mov   bp, sp
sub   sp, 060h
mov   dx, es					   ; back this up...
mov   bx, word ptr es:[si + 012h]  ; thing->stateNum
mov   ax, STATES_RENDER_SEGMENT
mov   es, ax
add   bx, bx

; todo clean all this up. do we need local copy?
; otherwise use ds and rep movsw
mov   al, byte ptr es:[bx]		   ; states_render[thing->stateNum].sprite
mov   byte ptr [bp - 4], al		   
mov   al, byte ptr es:[bx + 1]	; states_render[thing->stateNum].frame
mov   es, dx					; restore sprite segment
mov   byte ptr [bp - 6], al		; todo a lot of lodsb? set ds to es?

mov   ax, word ptr es:[si]			; x lo
mov   word ptr [bp - 018h], ax
mov   ax, word ptr es:[si + 2]		; x hi
mov   word ptr [bp - 014h], ax
mov   ax, word ptr es:[si + 4]		; y lo
mov   word ptr [bp - 012h], ax
mov   ax, word ptr es:[si + 6]		; y hi
mov   word ptr [bp - 010h], ax
mov   ax, word ptr es:[si + 8]		; z lo
mov   word ptr [bp - 028h], ax
mov   ax, word ptr es:[si + 0Ah]	; z hi
mov   word ptr [bp - 024h], ax
mov   ax, word ptr es:[si + 016h]	; flags2
mov   word ptr [bp - 022h], ax
mov   ax, word ptr es:[si + 010h]	; angle_t
mov   word ptr [bp - 02Ah], ax
mov   ax, word ptr [bp - 018h]		; x lo
sub   ax, word ptr ds:[_viewx]
mov   word ptr [bp - 032h], ax
mov   ax, word ptr [bp - 014h]
sbb   ax, word ptr ds:[_viewx + 2]
mov   si, word ptr [bp - 012h]		; y lo
mov   word ptr [bp - 01Eh], ax
mov   cx, ax						
sub   si, word ptr ds:[_viewy]		
mov   ax, word ptr [bp - 010h]		; y hi
sbb   ax, word ptr ds:[_viewy + 2]	; si:ax = tr_y

;    gxt.w = FixedMulTrigNoShift(FINE_COSINE_ARGUMENT, viewangle_shiftright1 ,tr_x.w);

mov   word ptr [bp - 020h], ax		
mov   ax, FINECOSINE_SEGMENT
mov   di, word ptr ds:[_viewangle_shiftright1]
mov   dx, di
mov   bx, word ptr [bp - 032h]
call FixedMulTrigNoShift_


;    gyt.w = -FixedMulTrigNoShift(FINE_SINE_ARGUMENT, viewangle_shiftright1 ,tr_y.w);

mov   cx, word ptr [bp - 020h]		; tr_y hi
mov   word ptr [bp - 036h], ax		; store gxt
mov   word ptr [bp - 034h], dx
mov   ax, FINESINE_SEGMENT
mov   dx, di						; _viewangle_shiftright1
mov   bx, si						; cx:bx = tr_y
mov   byte ptr [bp - 2], 0
call FixedMulTrigNoShift_


mov   di, dx
mov   dx, word ptr [bp - 036h]
neg   di
neg   ax
sbb   di, 0

;    tz.w = gxt.w-gyt.w; 

sub   dx, ax
mov   ax, word ptr [bp - 034h]
sbb   ax, di
mov   word ptr [bp - 01Ch], dx
mov   di, ax
cmp   ax, MINZ_HIGHBITS

;    // thing is behind view plane?
;    if (tz.h.intbits < MINZ_HIGHBITS){ // (- sq: where does this come from)
;        return;
;    }

jl   exit_project_sprite
mov   cx, di
mov   ax, word ptr ds:[_centerx]
mov   bx, dx
call FixedDivWholeA_
mov   cx, word ptr [bp - 01eh]
mov   word ptr [bp - 0Ch], ax
mov   word ptr [bp - 0Ah], dx
mov   ax, FINESINE_SEGMENT
mov   dx, word ptr ds:[_viewangle_shiftright1]
mov   bx, word ptr [bp - 032h]
call FixedMulTrigNoShift_
mov   cx, word ptr [bp - 020h]
mov   word ptr [bp - 038h], dx
mov   word ptr [bp - 030h], ax
neg   word ptr [bp - 038h]
mov   ax, FINECOSINE_SEGMENT
mov   dx, word ptr ds:[_viewangle_shiftright1]
mov   bx, si
neg   word ptr [bp - 030h]
sbb   word ptr [bp - 038h], 0
call FixedMulTrigNoShift_

;    tx.w = -(gyt.w+gxt.w); 

add   ax, word ptr [bp - 030h]		; add gxt
adc   dx, word ptr [bp - 038h]
neg   dx
neg   ax
sbb   dx, 0
mov   word ptr [bp - 02Ch], ax
mov   si, dx						; si stores tx highbits
or    dx, dx

; si stores tx highbits?

;    // too far off the side?
;    if (labs(tx.w)>(tz.w<<2)){ // check just high 16 bits?

jge   tx_already_positive				; labs sign check
neg   ax
adc   dx, 0
neg   dx
tx_already_positive:

;        return;
;	}


mov   word ptr [bp - 036h], ax
mov   ax, word ptr [bp - 01ch]
add   ax, ax
adc   di, di
add   ax, ax
adc   di, di
cmp   dx, di
jle   not_too_far_off_side_highbits
exit_project_sprite:
LEAVE_MACRO 
pop   es
pop   si
ret   
not_too_far_off_side_highbits:
jne   not_too_far_off_side_lowbits
cmp   ax, word ptr [bp - 036h]
jb    exit_project_sprite
not_too_far_off_side_lowbits:
mov   al, byte ptr [bp - 4]
xor   ah, ah
mov   di, ax
shl   di, 2
sub   di, ax
mov   ax, SPRITES_SEGMENT
mov   es, ax
mov   al, byte ptr [bp - 6]
and   al, FF_FRAMEMASK
xor   ah, ah
imul  ax, ax, SIZEOF_SPRITEFRAME_T			; sucks. do shifts? 3 << 4 + 1
mov   di, word ptr es:[di]
mov   bx, di
add   bx, ax
cmp   byte ptr es:[bx + 018h], 0
mov   bl, 0					; rot 0 on jmp
je    skip_sprite_rotation
mov   bx, word ptr [bp - 012h]
mov   cx, word ptr [bp - 010h]
mov   ax, word ptr [bp - 018h]
mov   dx, word ptr [bp - 014h]
call  R_PointToAngle_
mov   ax, dx
sub   ax, word ptr [bp - 02Ah]
mov   cx, 3

;rot = _rotl(ang.hu.intbits - thingangle.hu.intbits + 0x9000u, 3) & 0x07;
add   ah, 090h
rol   ax, cl
and   al, 7
mov   bl, al				; rot result
skip_sprite_rotation:
mov   al, byte ptr [bp - 6]
and   al, FF_FRAMEMASK
xor   ah, ah
imul  ax, ax, SIZEOF_SPRITEFRAME_T
mov   dx, di
add   dx, ax
xor   bh, bh
add   bx, bx					; rot lookup
mov   cx, SPRITES_SEGMENT
mov   es, cx
add   bx, dx
mov   bx, word ptr es:[bx]
mov   word ptr [bp - 02Eh], bx
xchg  bx, dx
add   bx, ax
mov   al, byte ptr es:[bx + 010h]
mov   cx, word ptr [bp - 0Ah]
mov   byte ptr [bp - 8], al
mov   ax, SPRITEOFFSETS_SEGMENT
mov   bx, dx						; restore this
mov   es, ax
mov   al, byte ptr es:[bx]
mov   bx, word ptr [bp - 0Ch]
xor   ah, ah
;sub   word ptr [bp - 02Ch], 0
sub   si, ax						; no need for sbb?
mov   ax, word ptr [bp - 02Ch]
mov   dx, si
mov   di, word ptr ds:[_centerx]
call FixedMul_
mov   bx, ax
mov   ax, dx
xor   dx, dx
add   dx, bx
adc   di, ax

;    // off the right side?
;    if (x1 > viewwidth){
;        return;
;    }
    

mov   word ptr [bp - 0Eh], di
cmp   di, word ptr ds:[_viewwidth]
jle   not_too_far_off_right_side_highbits
jump_to_exit_project_sprite_2:
jmp   exit_project_sprite
not_too_far_off_right_side_highbits:
mov   bx, word ptr [bp - 02Eh]
mov   es, word ptr ds:[_spritewidths_segment]
mov   al, byte ptr es:[bx]
xor   ah, ah
mov   word ptr [bp - 026h], ax


;    if (usedwidth == 1){
;        usedwidth = 257;
;    }


cmp   ax, 1
jne   not_too_far_off_right_side_lowbits
mov   word ptr [bp - 026h], 257   
not_too_far_off_right_side_lowbits:

;   temp.h.fracbits = 0;
;    temp.h.intbits = usedwidth;
;    // hack to make this fit in 8 bits, check r_init.c
;    tx.w +=  temp.w;
;	temp.h.intbits = centerx;
;	temp.w += FixedMul (tx.w,xscale.w);

mov   di, word ptr [bp - 026h]
mov   bx, word ptr [bp - 0Ch]
mov   cx, word ptr [bp - 0Ah]
mov   dx, si
;add   word ptr [bp - 02Ch], 0
add   dx, di					; no need for adc
mov   ax, word ptr [bp - 02Ch]
mov   di, word ptr ds:[_centerx]
call FixedMul_

;    x2 = temp.h.intbits - 1;

mov   bx, dx
xor   dx, dx
add   dx, ax
adc   di, bx
dec   di
mov   word ptr [bp - 016h], di

;    // off the left side
;    if (x2 < 0)
;        return;

test  di, di
jl    jump_to_exit_project_sprite_2

inc   word ptr ds:[_vissprite_p]
mov   si, word ptr ds:[_vissprite_p]
dec   si
imul  si, si, SIZEOF_VISSPRITE_T
add   si, OFFSET _vissprites

;todo fix overflow sprite.
;    vis->scale = xscale.w<<detailshift.b.bytelow;


mov   al, byte ptr ds:[_detailshift]
cbw  
mov   di, word ptr [bp - 0Ah]
mov   cx, ax
mov   ax, word ptr [bp - 0Ch]
jcxz  done_looping_shift_visscale  ; todo unroll
loop_shift_visscale:
shl   ax, 1
rcl   di, 1
loop  loop_shift_visscale
done_looping_shift_visscale:

; si is vis
; todo clean this up too...

mov   word ptr ds:[si  + 01Ah], ax
mov   ax, word ptr [bp - 018h]
mov   word ptr ds:[si  + 006h], ax
mov   ax, word ptr [bp - 014h]
mov   word ptr ds:[si  + 008h], ax
mov   ax, word ptr [bp - 012h]
mov   word ptr ds:[si  + 00Ah], ax
mov   ax, word ptr [bp - 010h]
mov   word ptr ds:[si  + 00Ch], ax
mov   ax, word ptr [bp - 028h]
mov   word ptr ds:[si  + 00Eh], ax
mov   ax, word ptr [bp - 024h]
mov   bx, word ptr [bp - 02Eh]
mov   word ptr ds:[si  + 010h], ax
mov   ax, SPRITETOPOFFSETS_SEGMENT
mov   word ptr ds:[si  + 01Ch], di
mov   es, ax
mov   al, byte ptr es:[bx]
xor   dx, dx
cbw  

; todo maybe vis = &vissprites[vissprite_p - 1];
mov   di, ax

;    // hack to make this fit in 8 bits, check r_init.c
;    if (temp.h.intbits == -128){
;        temp.h.intbits = 129;
;    }


cmp   ax, 0FF80h
je   intbits_128
intbits_ready:
mov   bx, word ptr [si + 0Eh]
mov   ax, word ptr [si + 010h]
add   bx, dx
adc   ax, di
mov   word ptr [si + 012h], bx
mov   bx, OFFSET _viewz
mov   dx, word ptr [si + 012h]
mov   word ptr [si + 014h], ax
sub   dx, word ptr [bx]
sbb   ax, word ptr [bx + 2]
mov   word ptr [si + 024h], ax
mov   ax, word ptr [bp - 0Eh]
mov   word ptr [si + 022h], dx
; todo move x1 code way up where its still register

;    vis->x1 = x1 < 0 ? 0 : x1;

test  ax, ax
jge   x1_positive
xor   ax, ax

x1_positive:
mov   word ptr [si + 2], ax

;    vis->x2 = x2 >= viewwidth ? viewwidth-1 : x2;       
; todo move x2 code way up where its still register

mov   ax, word ptr [bp - 016h]
mov   bx, word ptr ds:[_viewwidth]
cmp   ax, bx
jl    x2_smaller_than_viewwidth
mov   ax, bx
dec   ax
x2_smaller_than_viewwidth:
mov   bx, word ptr [bp - 0Ch]
mov   cx, word ptr [bp - 0Ah]
mov   word ptr [si + 4], ax
mov   ax, 1
call FixedDivWholeA_
mov   bx, ax
cmp   byte ptr [bp - 8], 0
jne   flip_not_zero
jmp   flip_zero
intbits_128:
mov   di, 129
jmp intbits_ready

flip_not_zero:
mov   di, word ptr [bp - 026h]
mov   word ptr [si + 020h], dx
xor   ax, ax
mov   word ptr [si + 01eh], bx
add   ax, -1
adc   di, -1
mov   word ptr [si + 016h], ax
mov   word ptr [si + 018h], di
neg   word ptr [si + 020h]
neg   word ptr [si + 01eh]
sbb   word ptr [si + 020h], 0

flip_stuff_done:


;    if (vis->x1 > x1)
;        vis->startfrac += FastMul16u32u((vis->x1-x1),vis->xiscale);

mov   ax, word ptr [si + 2]
mov   bx, word ptr [bp - 0Eh]
cmp   ax, bx
jle   vis_x1_greater_than_x1
sub   ax, bx
mov   bx, word ptr [si + 01eh]
mov   cx, word ptr [si + 020h]
call FastMul16u32u_
add   word ptr [si + 016h], ax
adc   word ptr [si + 018h], dx

vis_x1_greater_than_x1:
mov   bx, word ptr [bp - 02Eh]
mov   word ptr [si + 026h], bx

;    if (thingflags2 & MF_SHADOW) {

test  byte ptr [bp - 022h], 4
jne   exit_set_shadow
mov   al, byte ptr ds:[_fixedcolormap]
test  al, al
jne   exit_set_fixed_colormap
test  byte ptr [bp - 6], FF_FULLBRIGHT
jne   exit_set_fixed_colormap


;        index = xscale.w>>(LIGHTSCALESHIFT-detailshift.b.bytelow);

mov   al, byte ptr ds:[_detailshift]	; set fullbright colormap
mov   cx, 0Ch							; todo what
cbw  
mov   di, word ptr [bp - 0Ah]
sub   cx, ax
mov   ax, word ptr [bp - 0Ch]
jcxz  done_shifting_xscale
loop_shift_xscale:
sar   di, 1
rcr   ax, 1
loop  loop_shift_xscale
done_shifting_xscale:
mov   dx, ax

;        if (index >= MAXLIGHTSCALE) {
;            index = MAXLIGHTSCALE-1;
;        }


cmp   ax, MAXLIGHTSCALE
jl    index_below_maxlightscale
mov   dx, MAXLIGHTSCALE - 1
index_below_maxlightscale:
mov   ax, SCALELIGHTFIXED_SEGMENT
mov   bx, word ptr ds:[_spritelights]
mov   es, ax
add   bx, dx
mov   al, byte ptr es:[bx]
exit_set_fixed_colormap:
mov   byte ptr [si + 1], al
LEAVE_MACRO
pop   es
pop   si
ret   

flip_zero:
mov   word ptr [si + 016h], 0
mov   word ptr [si + 018h], 0
mov   word ptr [si + 01eh], ax
mov   word ptr [si + 020h], dx
jmp   flip_stuff_done
exit_set_shadow:
mov   byte ptr [si + 1], COLORMAP_SHADOW
LEAVE_MACRO
pop   es
pop   si
ret   

ENDP





;R_AddSprites_

PROC R_AddSprites_ NEAR
PUBLIC R_AddSprites_ 

; DX:AX = sector_t __far* sec

push  bx
mov   bx, ax
mov   es, dx
mov   ax, word ptr es:[bx + 6]		; sec->validcount
mov   dx, word ptr ds:[_validcount]
cmp   ax, dx
je    exit_add_sprites_bx_only				; do this without push/pop
push  di
push  cx
push  si

mov   word ptr es:[bx + 6], dx
mov   al, byte ptr es:[bx + 0Eh]		; sec->lightlevel
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
test  ax, ax
jl    set_spritelights_to_zero
cmp   ax, LIGHTLEVELS
jge   set_spritelights_to_max
mov   si, ax
add   si, ax
mov   ax, word ptr ds:[si + _lightmult48lookup]
spritelights_set:
mov   word ptr ds:[_spritelights], ax
mov   ax, word ptr es:[bx + 8]
test  ax, ax
je    exit_add_sprites
mov   si, MOBJPOSLIST_SEGMENT
mov   es, si

loop_things_in_thinglist:
; multiply by 18h (SIZEOF_MOBJ_POS_T), AX maxes at MAX_THINKERS - 1 (839), cant 8 bit mul
sal   ax, 1
sal   ax, 1
sal   ax, 1
mov   si, ax
sal   si, 1
add   si, ax
call  R_ProjectSprite_
mov   ax, word ptr es:[si + 0Ch]
test  ax, ax
jne   loop_things_in_thinglist

exit_add_sprites:
pop   si
pop   cx
pop   di
exit_add_sprites_bx_only:
pop   bx
ret   
set_spritelights_to_zero:
xor   ax, ax
jmp   spritelights_set
set_spritelights_to_max:
; _NULL_OFFSET + 02A0h + 16 - 1 ... (0x2ee)
mov   ax, word ptr ds:[_lightmult48lookup + (2 * (LIGHTLEVELS - 1))]
jmp   spritelights_set


endp








END

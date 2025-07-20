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
INCLUDE CONSTANT.INC
INCLUDE defs.inc
INSTRUCTION_SET_MACRO


; these can be called near but must have push cs prefix
EXTRN P_TryMove_:NEAR
EXTRN P_SlideMove_:NEAR         ; except this is really near
EXTRN P_AproxDistance_:NEAR
EXTRN P_AimLineAttack_:NEAR
EXTRN P_CheckPosition_:NEAR
EXTRN R_PointInSubsector_:NEAR

.DATA

.CODE

PROC    P_MOBJ_STARTMARKER_ 
PUBLIC  P_MOBJ_STARTMARKER_
ENDP


;void __far P_XYMovement (mobj_t __near* mo, mobj_pos_t __far* mo_pos);


PROC P_XYMovement_ FAR
PUBLIC P_XYMovement_
; bp - 2    mobj/ax
; bp - 4    mobjpos offset/bx
; bp - 6    mobjpos seg/cx
; bp - 8    mobj_type
; bp - 0Ah  mobj_secnum
; bp - 0Ch  ymove hi
; bp - 0Eh  ymove lo


push  dx
push  si
push  di
push  bp
mov   bp, sp

push  ax ; bp - 2
push  cx ; bp - 4
push  bx ; bp - 6
mov   di, bx
mov   es, cx
mov   bx, ax  ; bx gets mobj

;	if (!mo->momx.w && !mo->momy.w) {

mov   al, byte ptr ds:[bx + MOBJ_T.m_mobjtype] ; todo move push later. 
xor   ah, ah
push  ax  ; bp - 8

mov   ax, word ptr ds:[bx + MOBJ_T.m_momx+2]
or    ax, word ptr ds:[bx + MOBJ_T.m_momx+0]
jne   mobj_is_moving
mov   ax, word ptr ds:[bx + MOBJ_T.m_momy+2]
or    ax, word ptr ds:[bx + MOBJ_T.m_momy+0]
jne   mobj_is_moving

;		if (mo_pos->flags2 & MF_SKULLFLY) {

test  byte ptr es:[di + MOBJ_POS_T.mp_flags2+1], (MF_SKULLFLY SHR 8)
jne   skull_slammed_into_something
exit_p_xymovement:
LEAVE_MACRO
pop   di
pop   si
pop   dx
retf   
skull_slammed_into_something:

;			// the skull slammed into something
;			mo_pos->flags2 &= ~MF_SKULLFLY;
;			mo->momx.w = mo->momy.w = mo->momz.w = 0;
;			P_SetMobjState (mo,mobjinfo[mo->type].spawnstate);
and   byte ptr es:[di + MOBJ_POS_T.mp_flags2+1], (NOT (MF_SKULLFLY SHR 8))  ; 0xFE
; ax already 0
mov   word ptr ds:[bx + MOBJ_T.m_momz+2], ax
mov   word ptr ds:[bx + MOBJ_T.m_momz+0], ax
; if we are in this code block we already determined these were 0
; mov   word ptr ds:[bx + MOBJ_T.m_momy+0], ax
; mov   word ptr ds:[bx + MOBJ_T.m_momy+2], ax
; mov   word ptr ds:[bx + MOBJ_T.m_momx+0], ax
; mov   word ptr ds:[bx + MOBJ_T.m_momx+2], ax

mov   al, byte ptr ds:[bx + MOBJ_T.m_mobjtype]
mov   ah, 0Bh
mul   ah
xchg  ax, bx
mov   dx, word ptr ds:[bx + _mobjinfo]

;call  P_SetMobjState_
db 0FFh  ; lcall[addr]
db 01Eh  ;
dw _P_SetMobjState_addr

jmp   exit_p_xymovement
mobj_is_moving:
push  word ptr ds:[bx + MOBJ_T.m_secnum]        ; bp - 0Ah


;    if (mo->momx.w > MAXMOVE){
;		mo->momx.w = MAXMOVE;
;	} else if (mo->momx.w < -MAXMOVE){
;		mo->momx.w = -MAXMOVE;
;	}


mov   ax, word ptr ds:[bx + MOBJ_T.m_momx+2]
cmp   ax, MAXMOVE

jge   cap_x_at_maxmove


cmp   ax, -MAXMOVE
jnl   done_capping_xmove
mov   word ptr ds:[bx + MOBJ_T.m_momx+0], 0
mov   word ptr ds:[bx + MOBJ_T.m_momx+2], -MAXMOVE
jmp   done_capping_xmove
cap_x_at_maxmove:
mov   word ptr ds:[bx + MOBJ_T.m_momx+0], 0
mov   word ptr ds:[bx + MOBJ_T.m_momx+2], 01Eh  ; MAXXMOVE 1E0000
done_capping_xmove:

;    if (mo->momy.w > MAXMOVE){
;		mo->momy.w = MAXMOVE;
;	} else if (mo->momy.w < -MAXMOVE){
;		mo->momy.w = -MAXMOVE;
;	}



mov   ax, word ptr ds:[bx + MOBJ_T.m_momy+2]
cmp   ax, MAXMOVE
jge   cap_y_at_maxmove
cmp   ax, -MAXMOVE
jnl   done_capping_ymove
mov   word ptr ds:[bx + MOBJ_T.m_momy+0], 0
mov   word ptr ds:[bx + MOBJ_T.m_momy+2], -MAXMOVE ; 0FFE2
jmp   done_capping_ymove

cap_y_at_maxmove:
mov   word ptr ds:[bx + MOBJ_T.m_momy+0], 0
mov   word ptr ds:[bx + MOBJ_T.m_momy+2], MAXMOVE
done_capping_ymove:

;    xmove = mo->momx;
;    ymove = mo->momy;


push  word ptr ds:[bx + MOBJ_T.m_momy+2] ; bp - 0Ch
push  word ptr ds:[bx + MOBJ_T.m_momy+0] ; bp - 0Eh

; xmove is di:si
; ymove is 0C 0E
mov   si, word ptr ds:[bx + MOBJ_T.m_momx+0]
mov   di, word ptr ds:[bx + MOBJ_T.m_momx+2]

;	do {

do_while_x_or_y_nonzero:

;	if (xmove.w > MAXMOVE/2 || ymove.w > MAXMOVE/2) {
les   bx, dword ptr [bp - 6]

cmp   di, (MAXMOVE SHR 1)
jg    do_xy_shift
jne   test_ymove
test_xmove_lobits:
test  si, si
jbe   test_ymove
do_xy_shift:

;	ptryx.w = mo_pos->x.w + xmove.w/2;
;	ptryy.w = mo_pos->y.w + ymove.w/2;
;	xmove.w >>= 1;
;	ymove.w >>= 1;


sar   di, 1
rcr   si, 1
mov   cx, si
mov   dx, di

jnc   do_div1_no_round_up  ; if it was odd, then carry was set
test  dx, dx
jns   do_div1_no_round_up
add   cx, 1                ; div 2 must round to 0, while shift rounds to negative infinity. timedemo desyncs if we dont do this.
adc   dx, 0
do_div1_no_round_up:

add   cx, word ptr es:[bx + MOBJ_POS_T.mp_x + 0]
adc   dx, word ptr es:[bx + MOBJ_POS_T.mp_x + 2]

sar   word ptr [bp - 0Ch], 1
rcr   word ptr [bp - 0Eh], 1

; if rcr was odd then carry flag is set. 

mov   ax, word ptr es:[bx + MOBJ_POS_T.mp_y + 0]
mov   bx, word ptr es:[bx + MOBJ_POS_T.mp_y + 2] ; knocks out bx... 

jnc   dont_round_up_div2 
test  byte ptr [bp - 0Bh], 080h
je    dont_round_up_div2
; signed and odd ,add one...
add   ax, 1
adc   bx, 0
dont_round_up_div2:
add   ax, word ptr [bp - 0Eh]
adc   bx, word ptr [bp - 0Ch]


jmp   done_shifting_xymove
test_ymove:

cmp   word ptr [bp - 0Ch], (MAXMOVE SHR 1)
jnle  do_xy_shift
test_ymove_lobits:
jne   dont_do_xy_shift
cmp   word ptr [bp - 0Eh], 0
ja    do_xy_shift
dont_do_xy_shift:


;    ptryx.w = mo_pos->x.w + xmove.w;
;    ptryy.w = mo_pos->y.w + ymove.w;
;    xmove.w = ymove.w = 0;

mov   cx, word ptr es:[bx]
mov   dx, word ptr es:[bx + 2]
add   cx, si
adc   dx, di

xor   si, si
mov   di, si

mov   ax, word ptr es:[bx + MOBJ_POS_T.mp_y + 0]
add   ax, word ptr [bp - 0Eh]    
mov   bx, word ptr es:[bx + MOBJ_POS_T.mp_y + 2]
adc   bx, word ptr [bp - 0Ch]

mov   word ptr [bp - 0Eh], si ; zero
mov   word ptr [bp - 0Ch], si ; zero



done_shifting_xymove:

;		if (!P_TryMove (mo, mo_pos, ptryx, ptryy)) {

push  bx
push  ax
push  dx
push  cx
mov   bx, word ptr [bp - 6]
mov   cx, es
mov   ax, word ptr [bp - 2]

push  cs
call  P_TryMove_   ; what if we returned in the carry flag...


test  al, al
jne   cant_move
; 
cmp   word ptr [bp - 8], MT_PLAYER
je    player_try_slide
jmp   do_missile_check
player_try_slide:
call  P_SlideMove_

cant_move:
;    } while (xmove.w || ymove.w);

test  di, di
je    continue_ymove_check
jump_to_do_while_x_or_y_nonzero:
jmp   do_while_x_or_y_nonzero
continue_ymove_check:
test  si, si
jne   jump_to_do_while_x_or_y_nonzero
cmp   word ptr [bp - 0Ch], 0
jne   jump_to_do_while_x_or_y_nonzero
cmp   word ptr [bp - 0Eh], 0
jne   jump_to_do_while_x_or_y_nonzero

mov   bx, word ptr [bp - 2]

;    // slow down
;    if (motype == MT_PLAYER && player.cheats & CF_NOMOMENTUM) {

cmp   word ptr [bp - 8], MT_PLAYER
jne   skip_no_momentum_cheat ;todo inverse logic


test  byte ptr ds:[_player + PLAYER_T.player_cheats], CF_NOMOMENTUM
je    skip_no_momentum_cheat

;		// debug option for no sliding at all
;		mo->momx.w = mo->momy.w = 0;
;		return;

xor   ax, ax
mov   word ptr ds:[bx + MOBJ_T.m_momx+0], ax
mov   word ptr ds:[bx + MOBJ_T.m_momx+2], ax
mov   word ptr ds:[bx + MOBJ_T.m_momy+0], ax
mov   word ptr ds:[bx + MOBJ_T.m_momy+2], ax
jmp   exit_p_xymovement
skip_no_momentum_cheat:
les   di, dword ptr [bp - 6]

;	if (mo_pos->flags2 & (MF_MISSILE | MF_SKULLFLY)) {

test  word ptr es:[di + MOBJ_POS_T.mp_flags2], (MF_MISSILE OR MF_SKULLFLY)
je    not_missile_or_skullfly
jump_to_exit_p_xymovement:
jmp   exit_p_xymovement
not_missile_or_skullfly:
;	SET_FIXED_UNION_FROM_SHORT_HEIGHT(temp, mo->floorz);
xor   dx, dx
mov   ax, word ptr ds:[bx + MOBJ_T.m_floorz]
sar       ax, 1
rcr       dx, 1
sar       ax, 1
rcr       dx, 1
sar       ax, 1
rcr       dx, 1

;	if (mo_pos->z.w > temp.w) {
;		return;		// no friction when airborne
;	}


cmp   ax, word ptr es:[di + MOBJ_POS_T.mp_z + 2]
jl    jump_to_exit_p_xymovement
jne   not_in_air
cmp   dx, word ptr es:[di + MOBJ_POS_T.mp_z + 0]
jb    jump_to_exit_p_xymovement
not_in_air:

; if (mo_pos->flags2 & MF_CORPSE) {
test  byte ptr es:[di + MOBJ_POS_T.mp_flags2], MF_CORPSE
je    is_not_corpse


;		// do not stop sliding
;		//  if halfway off a step with some momentum
;		if (mo->momx.w > FRACUNIT/4 || mo->momx.w < -FRACUNIT/4 || mo->momy.w > FRACUNIT/4 || mo->momy.w < -FRACUNIT/4) {
;			sectorfloorheight = sectors[mosecnum].floorheight;
;			if (mo->floorz != sectorfloorheight) {				
;				return;

mov   ax, word ptr ds:[bx + MOBJ_T.m_momx+2]
test  ax, ax
jg    check_floor_height
je    check_y_pos
;		if (mo->momx.w > FRACUNIT/4 || mo->momx.w < -FRACUNIT/4 || mo->momy.w > FRACUNIT/4 || mo->momy.w < -FRACUNIT/4) {
; ax is momx hibits
continue_fracunit_over_4_momentum_check:
cmp   ax, 0FFFFh   ; hi bits negative
jnge  check_floor_height
jne   continue_momy_check_floor
cmp   word ptr ds:[bx + MOBJ_T.m_momx+0], -FRACUNITOVER4
jb    check_floor_height
continue_momy_check_floor:
mov   ax, word ptr ds:[bx + MOBJ_T.m_momy+2]
test  ax, ax
jg    check_floor_height
jne   check_momy_negative
cmp   word ptr ds:[bx + MOBJ_T.m_momy+0], FRACUNITOVER4
ja    check_floor_height
check_momy_negative:
cmp   ax, 0FFFFh   ; hi bits negative
jl    check_floor_height
jne   done_with_corpse_check
cmp   word ptr ds:[bx + MOBJ_T.m_momy+0], -FRACUNITOVER4  ; 0c000h
jb    check_floor_height
jmp   done_with_corpse_check

check_y_pos:
cmp   word ptr ds:[bx + MOBJ_T.m_momx+0], FRACUNITOVER4 ; 04000h
jbe   continue_fracunit_over_4_momentum_check
check_floor_height:
mov   di, word ptr [bp - 0Ah]
mov   ax, SECTORS_SEGMENT
SHIFT_MACRO shl   di 4
mov   es, ax
mov   ax, word ptr es:[di]
cmp   ax, word ptr ds:[bx + 6]  ; ? MOBJ_T.m_floorz
jne   jump_to_exit_p_xymovement


is_not_corpse:
done_with_corpse_check:


;	momomx = mo->momx;
;	momomy = mo->momy;

mov   di, word ptr ds:[bx + MOBJ_T.m_momy+0]
mov   cx, word ptr ds:[bx + MOBJ_T.m_momx+2]


; if ((momomx.w > -STOPSPEED && momomx.w < STOPSPEED && momomy.w > -STOPSPEED && momomy.w < STOPSPEED) && 

mov   si, word ptr ds:[bx + MOBJ_T.m_momy+2]
mov   bx, word ptr ds:[bx + MOBJ_T.m_momx+0]
cmp   cx, 0FFFFh   ; hi bits negative
jg    momomx_not_in_negative_range
je    continue_stopspeed_checks_1
apply_friction:

mov   ax, FRICTION
;call  FixedMul16u32_
db 0FFh  ; lcall[addr]
db 01Eh  ;
dw _FixedMul16u32_addr


mov   bx, word ptr [bp - 2]
mov   word ptr ds:[bx + MOBJ_T.m_momx+0], ax
mov   cx, si
mov   word ptr ds:[bx + MOBJ_T.m_momx+2], dx
mov   bx, di
mov   ax, FRICTION
;call  FixedMul16u32_
db 0FFh  ; lcall[addr]
db 01Eh  ;
dw _FixedMul16u32_addr

mov   bx, word ptr [bp - 2]
mov   word ptr ds:[bx + MOBJ_T.m_momy+0], ax
mov   word ptr ds:[bx + MOBJ_T.m_momy+2], dx
LEAVE_MACRO 
pop   di
pop   si
pop   dx
retf   

continue_stopspeed_checks_1:
cmp   bx, -STOPSPEED
jbe   apply_friction
momomx_not_in_negative_range:
test  cx, cx
jl    continue_stopspeed_checks_2
jne   apply_friction
cmp   bx, STOPSPEED
jae   apply_friction
continue_stopspeed_checks_2:
cmp   si, 0FFFFh    ; hi bits negative
jg    continue_stopspeed_checks_3
jne   apply_friction
cmp   di, -STOPSPEED
jbe   apply_friction
continue_stopspeed_checks_3:
test  si, si
jl    continue_stopspeed_checks_4
jne   apply_friction
cmp   di, STOPSPEED
jae   apply_friction
continue_stopspeed_checks_4:
cmp   word ptr [bp - 8], MT_PLAYER
jne   dont_apply_friction
; check if pressing buttons
cmp   word ptr ds:[_player + PLAYER_T.player_cmd_forwardmove], 0
jne   apply_friction
; gotten for free above
;cmp   byte ptr ds:[_player + PLAYER_T.player_cmd_sidemove], 0
;jne   apply_friction
dont_apply_friction:
cmp   word ptr [bp - 8], MT_PLAYER
jne   done_stepping_stop_moving
les   si, dword ptr ds:[_playerMobj_pos]
mov   ax, word ptr es:[si + MOBJ_POS_T.mp_statenum]
sub   ax, S_PLAY_RUN1
cmp   ax, 4
jae   done_stepping_stop_moving
;	// if in a walking frame, stop moving
mov   dx, S_PLAY
mov   ax, word ptr ds:[_playerMobj]

;call  P_SetMobjState_
db 0FFh  ; lcall[addr]
db 01Eh  ;
dw _P_SetMobjState_addr
done_stepping_stop_moving:
;		mo->momx.w = 0;
;		mo->momy.w = 0;
mov   bx, word ptr [bp - 2]
mov   word ptr ds:[bx + MOBJ_T.m_momx+0], 0
mov   word ptr ds:[bx + MOBJ_T.m_momx+2], 0
mov   word ptr ds:[bx + MOBJ_T.m_momy+0], 0
mov   word ptr ds:[bx + MOBJ_T.m_momy+2], 0
LEAVE_MACRO
pop   di
pop   si
pop   dx
retf   



do_missile_check:

;			} else if (mo_pos->flags2 & MF_MISSILE) {

les   dx, dword ptr [bp - 6]
mov   cx, es
mov   bx, dx
test  byte ptr es:[bx + MOBJ_POS_T.mp_flags2], MF_MISSILE
je    not_missile_dont_explode
mov   bx, word ptr ds:[_ceilinglinenum]
cmp   bx, SECNUM_NULL
je    do_explosion
SHIFT_MACRO shl   bx 4
mov   ax, LINES_PHYSICS_SEGMENT
mov   es, ax
mov   bx, word ptr es:[bx + LINE_PHYSICS_T.lp_backsecnum]

cmp   bx, SECNUM_NULL
je    do_explosion
SHIFT_MACRO shl   bx 4
mov   ax, SECTORS_SEGMENT
mov   es, ax
mov   al, byte ptr es:[bx + 5]
cmp   al, byte ptr ds:[_skyflatnum]
je    is_sky_dont_explode
do_explosion:
mov   bx, dx
;     cx already set above
mov   ax, word ptr [bp - 2]
call  P_ExplodeMissile_
jmp   cant_move
is_sky_dont_explode:
mov   ax, word ptr [bp - 2]

;call  P_RemoveMobj_
db 0FFh  ; lcall[addr]
db 01Eh  ;
dw _P_RemoveMobj_addr

LEAVE_MACRO
pop   di
pop   si
pop   dx
retf   
not_missile_dont_explode:

;				mo->momx.w = mo->momy.w = 0;

mov   bx, word ptr [bp - 2]
xor   ax, ax
mov   word ptr ds:[bx + MOBJ_T.m_momx+0], ax
mov   word ptr ds:[bx + MOBJ_T.m_momx+2], ax
mov   word ptr ds:[bx + MOBJ_T.m_momy+0], ax
mov   word ptr ds:[bx + MOBJ_T.m_momy+2], ax
jmp   cant_move


ENDP


FLOATSPEED_HIGHBITS = 4
VIEWHEIGHT_HIGH = 41

PROC P_ZMovement_ FAR
PUBLIC P_ZMovement_

; bp - 2  segment for mobjpos (MOBJPOSLIST_6800_SEGMENT)
; bp - 4  floorz fixedheight hi
; bp - 6  floorz fixedheight lo
; bp - 8  mobj type  
; bp - 0Ah  dist hi
; bp - 0Ch  dist lo



push  dx
push  si
push  di
push  bp
mov   bp, sp
push  cx ; bp - 2
mov   si, ax
mov   di, bx

;	SET_FIXED_UNION_FROM_SHORT_HEIGHT(temp, mo->floorz);

mov   ax, word ptr ds:[si + MOBJ_T.m_floorz]
xor   dx, dx
sar   ax, 1
rcr   dx, 1
sar   ax, 1
rcr   dx, 1
sar   ax, 1
rcr   dx, 1
push  ax ; bp - 4
push  dx ; bp - 6
mov   es, cx
mov   cl, byte ptr ds:[si + MOBJ_T.m_mobjtype]
push  cx  ; bp - 8
;    if (motype == MT_PLAYER && mo_pos->z.w < temp.w) {
test  cl, cl
jne   z_not_player
sub   dx, word ptr es:[di + MOBJ_POS_T.mp_z + 0]
sbb   ax, word ptr es:[di + MOBJ_POS_T.mp_z + 2]

jg    do_smooth_step_up
jne   z_not_player
test   dx, dx
jnae  z_not_player
do_smooth_step_up:

; todo maybe sub then compare to zero? fewer mem access?
;		player.viewheightvalue.w -= (temp.w-mo_pos->z.w);
sub   word ptr ds:[_player + PLAYER_T.player_viewheightvalue+0], dx
sbb   word ptr ds:[_player + PLAYER_T.player_viewheightvalue+2], ax

;		player.deltaviewheight.w = (VIEWHEIGHT - player.viewheightvalue.w)>>3;

; todo... neg and add?

neg   ax
neg   dx
;sbb   ax, 0
;add   ax, VIEWHEIGHT_HIGH ;todo combine with above.
sbb   ax, (010000h - VIEWHEIGHT_HIGH)  ; combined

sar   ax, 1
rcr   dx, 1
sar   ax, 1
rcr   dx, 1
sar   ax, 1
rcr   dx, 1

mov   word ptr ds:[_player + PLAYER_T.player_deltaviewheight+0], dx
mov   word ptr ds:[_player + PLAYER_T.player_deltaviewheight+2], ax
z_not_player:

;	mo_pos->z.w += mo->momz.w;

mov   ax, word ptr ds:[si + MOBJ_T.m_momz+0]
mov   dx, word ptr ds:[si + MOBJ_T.m_momz+2]

add   word ptr es:[di + MOBJ_POS_T.mp_z+0], ax
adc   word ptr es:[di + MOBJ_POS_T.mp_z+2], dx

;    if (mo_pos->flags1 & MF_FLOAT && mo->targetRef) {

test  byte ptr es:[di + MOBJ_POS_T.mp_flags1+1], (MF_FLOAT SHR 8)
jne   continue_floating_with_target_check
jump_to_done_with_floating_with_target:
jmp   done_with_floating_with_target
continue_floating_with_target_check:
cmp   word ptr ds:[si + MOBJ_T.m_targetRef], 0
je    jump_to_done_with_floating_with_target
test  byte ptr es:[di + MOBJ_POS_T.mp_flags2 + 1], (MF_SKULLFLY SHR 8)
jne   jump_to_done_with_floating_with_target
test  byte ptr es:[di + MOBJ_POS_T.mp_flags2], MF_INFLOAT
jne   jump_to_done_with_floating_with_target

;		// float down towards target if too close
;		if ( !(mo_pos->flags2 & MF_SKULLFLY) && !(mo_pos->flags2 & MF_INFLOAT) ) {


;    moTarget = (mobj_t __near*)&thinkerlist[mo->targetRef].data;
;    moTarget_pos = &mobjposlist_6800[mo->targetRef];

IF COMPISA GE COMPILE_186
    imul  bx, word ptr ds:[si + MOBJ_T.m_targetRef], SIZEOF_MOBJ_POS_T
ELSE
    mov   ax, SIZEOF_MOBJ_POS_T
    mul   word ptr ds:[si + MOBJ_T.m_targetRef]
    mov   bx, ax
ENDIF

push  bx  ; store for later


;    dist = P_AproxDistance (mo_pos->x.w - moTarget_pos->x.w,
;        mo_pos->y.w - moTarget_pos->y.w);

mov   ax, word ptr es:[di + MOBJ_POS_T.mp_y + 0]
mov   cx, word ptr es:[di + MOBJ_POS_T.mp_y + 2]
sub   ax, word ptr es:[bx + MOBJ_POS_T.mp_y + 0]
sbb   cx, word ptr es:[bx + MOBJ_POS_T.mp_y + 2]
push  ax    ; store y diff lo



mov   ax, word ptr es:[di + MOBJ_POS_T.mp_x + 0]
mov   dx, word ptr es:[di + MOBJ_POS_T.mp_x + 2]
sub   ax, word ptr es:[bx + MOBJ_POS_T.mp_x + 0]
sbb   dx, word ptr es:[bx + MOBJ_POS_T.mp_x + 2]

pop   bx    ; get y diff lo

push   cs
call  P_AproxDistance_

pop   bx  ; recover offset
mov   es, word ptr [bp - 2]
push  dx  ; bp - 0Ah
push  ax  ; bp - 0Ch

;	delta =(moTarget_pos->z.w + (mo->height.w>>1)) - mo_pos->z.w;

mov   ax, word ptr ds:[si + MOBJ_T.m_height+0]
mov   dx, word ptr ds:[si + MOBJ_T.m_height+2]
sar   dx, 1
rcr   ax, 1

add   ax, word ptr es:[bx + MOBJ_POS_T.mp_z+0]
adc   dx, word ptr es:[bx + MOBJ_POS_T.mp_z+2]
sub   ax, word ptr es:[di + MOBJ_POS_T.mp_z+0]
sbb   dx, word ptr es:[di + MOBJ_POS_T.mp_z+2]


;    if (delta<0 && dist < -(FastMul8u32(3, delta)) )
;        mo_pos->z.h.intbits -= FLOATSPEED_HIGHBITS;

test  dx, dx
jge   dont_sub_floatspeed
check_for_sub_floatspeed:
push  ax ; in case we need delta again
push  dx ; in case we need delta again
mov   bx, ax
mov   cx, dx
mov   ax, 3
; call  FastMul16u32u_
db 0FFh  ; lcall[addr]
db 01Eh  ;
dw _FastMul16u32u_addr

mov   bx, ax
mov   ax, dx
neg   ax
neg   bx
sbb   ax, 0
cmp   ax, word ptr [bp - 0Ah]
jg    do_sub_floatspeed
je    compare_low_bits_floatspeed
jump_to_dont_sub_floatspeed:
pop   dx
pop   ax
jmp   dont_sub_floatspeed
compare_low_bits_floatspeed:
cmp   bx, word ptr [bp - 0Ch]
jbe   jump_to_dont_sub_floatspeed
do_sub_floatspeed:
mov   es, word ptr [bp - 2]
sub   word ptr es:[di + MOBJ_POS_T.mp_z + 2], FLOATSPEED_HIGHBITS
jmp   done_with_floating_with_target

dont_sub_floatspeed:
; delta dx:ax
;			else if (delta>0 && dist < FastMul8u32(3, delta)  )
;				mo_pos->z.h.intbits += FLOATSPEED_HIGHBITS;

test  dx, dx
jg    check_for_add_floatspeed
jne   done_with_floating_with_target
cmp   ax, 0
jbe   done_with_floating_with_target
check_for_add_floatspeed:
mov   bx, ax
mov   cx, dx
mov   ax, 3
; call  FastMul16u32u_
db 0FFh  ; lcall[addr]
db 01Eh  ;
dw _FastMul16u32u_addr

cmp   dx, word ptr [bp - 0Ah]
jg    do_add_floatspeed
jne   done_with_floating_with_target
cmp   ax, word ptr [bp - 0Ch]
jbe   done_with_floating_with_target
do_add_floatspeed:
mov   es, word ptr [bp - 2]
add   word ptr es:[di + MOBJ_POS_T.mp_z + 2], FLOATSPEED_HIGHBITS

done_with_floating_with_target:

;    // clip movement
;    if (mo_pos->z.w <= temp.w) {

mov   es, word ptr [bp - 2]
mov   ax, word ptr es:[di + MOBJ_POS_T.mp_z + 2]
cmp   ax, word ptr [bp - 4]
jl    hit_floor
je    check_floor_lobits

didnt_hit_floor:

;	} else if (! (mo_pos->flags1 & MF_NOGRAVITY) ) {

test  byte ptr es:[di + MOBJ_POS_T.mp_flags1 + 1], (MF_NOGRAVITY SHR 8)
je    do_gravity
jmp   done_with_floor_z_collision
do_gravity:
;		if (mo->momz.w == 0) {
mov   ax, word ptr ds:[si + MOBJ_T.m_momz + 2]
or    ax, word ptr ds:[si + MOBJ_T.m_momz + 0]
jne   add_gravity
;	mo->momz.h.intbits = -GRAVITY_HIGHBITS << 1;
mov   word ptr ds:[si + MOBJ_T.m_momz + 2], 0FFFEh
jmp   done_with_floor_z_collision
add_gravity:
;    mo->momz.h.intbits -= GRAVITY_HIGHBITS;

dec   word ptr ds:[si + MOBJ_T.m_momz + 2]
jmp   done_with_floor_z_collision

check_floor_lobits:
mov   ax, word ptr es:[di + MOBJ_POS_T.mp_z + 0]
cmp   ax, word ptr [bp - 6]
ja    didnt_hit_floor
hit_floor:
cmp   byte ptr ds:[_is_ultimate], 0
je    skip_ultimate_hack


test  byte ptr es:[di + MOBJ_POS_T.mp_flags2 + 1], (MF_SKULLFLY SHR 8)
je    skip_ultimate_hack

;			// Note (id):
;			//  somebody left this after the setting momz to 0,
;			//  kinda useless there.
;			if (mo_pos->flags2 & MF_SKULLFLY)
;			{
;				// the skull slammed into something
;				mo->momz.w = -mo->momz.w;
;			}

neg   word ptr ds:[si + MOBJ_T.m_momz + 2]
neg   word ptr ds:[si + MOBJ_T.m_momz + 0]
sbb   word ptr ds:[si + MOBJ_T.m_momz + 2], 0
skip_ultimate_hack:

;	if (mo->momz.h.intbits < 0) {

cmp   word ptr ds:[si + MOBJ_T.m_momz + 2], 0
jge   dont_squat
jmp   continue_squat_check
dont_squat:
done_with_squat:

;	mo_pos->z.w = temp.w;   (floor value)

mov   es, word ptr [bp - 2]
mov   ax, word ptr [bp - 6]
mov   word ptr es:[di + MOBJ_POS_T.mp_z + 0], ax
mov   ax, word ptr [bp - 4]
mov   word ptr es:[di + MOBJ_POS_T.mp_z + 2], ax

;		if (!is_ultimate){
;			if (mo_pos->flags2 & MF_SKULLFLY) {
;				// the skull slammed into something
;				mo->momz.w = -mo->momz.w;


cmp   byte ptr ds:[_is_ultimate], 0
jne   skip_ultimate_skull_check
test  byte ptr es:[di + MOBJ_POS_T.mp_flags2 + 1], (MF_SKULLFLY SHR 8)
je    skip_ultimate_skull_check
neg   word ptr ds:[si + MOBJ_T.m_momz + 2]
neg   word ptr ds:[si + MOBJ_T.m_momz + 0]
sbb   word ptr ds:[si + MOBJ_T.m_momz + 2], 0
skip_ultimate_skull_check:

;mov   es, word ptr [bp - 2]
test  byte ptr es:[di + MOBJ_POS_T.mp_flags2], MF_MISSILE
je    dont_explode_missile
test  byte ptr es:[di + MOBJ_POS_T.mp_flags1 + 1], (MF_NOCLIP SHR 8)
jne   dont_explode_missile
do_explode_missile:
mov   bx, di
mov   cx, es
mov   ax, si
call  P_ExplodeMissile_
LEAVE_MACRO 
pop   di
pop   si
pop   dx
retf   
dont_explode_missile:
done_with_floor_z_collision:

;	SET_FIXED_UNIO;N_FROM_SHORT_HEIGHT(temp, mo->ceilingz);

mov   es, word ptr [bp - 2]
mov   dx, word ptr ds:[si + MOBJ_T.m_ceilingz]
xor   ax, ax
sar   dx, 1
rcr   ax, 1
sar   dx, 1
rcr   ax, 1
sar   dx, 1
rcr   ax, 1



mov   bx, word ptr es:[di + MOBJ_POS_T.mp_z + 0]
mov   cx, word ptr es:[di + MOBJ_POS_T.mp_z + 2]
add   bx, word ptr ds:[si + MOBJ_T.m_height + 0]
adc   cx, word ptr ds:[si + MOBJ_T.m_height + 2]

cmp   cx, dx
jg    check_ceil_lobits
jne   exit_p_zmovement
cmp   bx, ax
jbe   exit_p_zmovement
check_ceil_lobits:

cmp   word ptr ds:[si + MOBJ_T.m_momz + 2], 0
jg    hit_ceiling
jne   cap_z_to_ceiling
cmp   word ptr ds:[si + MOBJ_T.m_momz + 0], 0
jbe   cap_z_to_ceiling
hit_ceiling:

;		if (mo->momz.w > 0) {
;			mo->momz.w = 0;
;		}

mov   word ptr ds:[si + MOBJ_T.m_momz + 0], 0
mov   word ptr ds:[si + MOBJ_T.m_momz + 2], 0
cap_z_to_ceiling:

sub   ax, word ptr ds:[si + MOBJ_T.m_height + 0]
sbb   dx, word ptr ds:[si + MOBJ_T.m_height + 2]
mov   word ptr es:[di + MOBJ_POS_T.mp_z + 0], ax
mov   word ptr es:[di + MOBJ_POS_T.mp_z + 2], dx

test  byte ptr es:[di + MOBJ_POS_T.mp_flags2 + 1], (MF_SKULLFLY SHR 8)
je    skip_skull_slam
; skull slam
neg   word ptr ds:[si + MOBJ_T.m_momz + 2]
neg   word ptr ds:[si + MOBJ_T.m_momz + 0]
sbb   word ptr ds:[si + MOBJ_T.m_momz + 2], 0

skip_skull_slam:
test  byte ptr es:[di + MOBJ_POS_T.mp_flags2], MF_MISSILE
je    exit_p_zmovement
test  byte ptr es:[di + MOBJ_POS_T.mp_flags1 + 1], (MF_NOCLIP SHR 8)
je    do_explode_missile
exit_p_zmovement:
LEAVE_MACRO
pop   di
pop   si
pop   dx
retf   

continue_squat_check:
;	if (motype == MT_PLAYER && mo->momz.w < -GRAVITY*8)	 {

cmp   byte ptr [bp - 8], MT_PLAYER
jne   land_and_momz_0
mov   ax, word ptr ds:[si + MOBJ_T.m_momz + 2]
cmp   ax, 0FFF8h                    ; -GRAVITY*8. gravity is FRACUNIT or 1 in the high word.
jnl   land_and_momz_0

do_player_squat_landing:

;    // Squat down.
;    // Decrease viewheight for a moment
;    // after hitting the ground (hard),
;    // and utter appropriate sound.
;    player.deltaviewheight.w = mo->momz.w>>3;
;    S_StartSound (mo, sfx_oof);

mov   ax, word ptr ds:[si + MOBJ_T.m_momz + 0]
mov   dx, word ptr ds:[si + MOBJ_T.m_momz + 2]


sar   dx, 1
rcr   ax, 1
sar   dx, 1
rcr   ax, 1
sar   dx, 1
rcr   ax, 1

mov   word ptr ds:[_player + PLAYER_T.player_deltaviewheight+0], ax
mov   word ptr ds:[_player + PLAYER_T.player_deltaviewheight+2], dx
mov   dx, SFX_OOF
mov   ax, si

;call  S_StartSound_
db 0FFh  ; lcall[addr]
db 01Eh  ;
dw _S_StartSound_addr

;	mo->momz.w = 0;

land_and_momz_0:
mov   word ptr ds:[si + MOBJ_T.m_momz + 0], 0
mov   word ptr ds:[si + MOBJ_T.m_momz + 2], 0
jmp   done_with_squat


ENDP




PROC P_ExplodeMissile_ NEAR
PUBLIC P_ExplodeMissile_

; bp - 2   mobjpos segment

push  dx
push  si
push  di

xchg  ax, si
push  cx   ; on stack for later
xor   ax, ax

;    mo->momx.w = mo->momy.w = mo->momz.w = 0;
mov   cx, 6
push  ds
pop   es
lea   di, [si + MOBJ_T.m_momx+0]
rep   stosw ; zero all six words out

mov   al, byte ptr ds:[si + MOBJ_T.m_mobjtype]
xor   ah, ah

; call GetDeathState..
db    09Ah
dw    GETDEATHSTATEADDR, INFOFUNCLOADSEGMENT

xchg  ax, dx    ; dx gets deathstate
mov   ax, si    ; ax gets mobj ptr back


;call  P_SetMobjState_
db 0FFh  ; lcall[addr]
db 01Eh  ;
dw _P_SetMobjState_addr

mov   ax, RNDTABLE_SEGMENT
mov   es, ax
inc   byte ptr ds:[_prndindex]
mov   al, byte ptr ds:[_prndindex]
xor   ah, ah
xchg  ax, di

;    mo->tics -= P_Random()&3;
;	if (mo->tics < 1 || mo->tics > 240) {
;		mo->tics = 1;
;	}

mov   al, byte ptr es:[di]
and   al, 3
sub   byte ptr ds:[si + MOBJ_T.m_tics], al
mov   al, byte ptr ds:[si + MOBJ_T.m_tics]
cmp   al, 1
jb    set_tics_to_1_b
cmp   al, 240 ; check for tics overflow. jank
jbe   dont_set_tics_to_1_b
set_tics_to_1_b:
mov   byte ptr ds:[si + MOBJ_T.m_tics], 1
dont_set_tics_to_1_b:

;	mo_pos->flags2 &= ~MF_MISSILE;

;	if (mobjinfo[mo->type].deathsound) {
;		S_StartSound(mo, mobjinfo[mo->type].deathsound);
;	}

pop   es  ; was bp - 2, only use...
and   byte ptr es:[bx + MOBJ_POS_T.mp_flags2], (NOT MF_MISSILE)
mov   al, SIZEOF_MOBJINFO_T
mul   byte ptr ds:[si + MOBJ_T.m_mobjtype]

xor   dx, dx
mov   dl, byte ptr ds:[si + _mobjinfo+3] ; deathsound offset
xchg  ax, si

test  dl, dl
jne   do_deathsound

pop   di
pop   si
pop   dx
ret
do_deathsound:
; ax got si earlier

;call  S_StartSound_
db 0FFh  ; lcall[addr]
db 01Eh  ;
dw _S_StartSound_addr


pop   di
pop   si
pop   dx
ret

ENDP

PROC P_NightmareRespawn_ FAR
PUBLIC P_NightmareRespawn_

; bp - 2       ax arg (mobj)
; bp - 4       bx arg (mobjpos offset)
; bp - 6       cx arg (mobjpos segment); bp - 8       unused (y.fracbits?)
; bp - 8       mapthing options
; bp - 0Ah     mapthing type
; bp - 0Ch     mapthing angle
; bp - 0Eh     mapthing y
; bp - 010h    mapthing x / top of mapthing

push  dx
push  si
push  di
push  bp
mov   bp, sp
push  ax    ; bp - 2
push  bx    ; bp - 4
push  cx    ; bp - 6
sub   sp, 0Ah

mov   bx, SIZEOF_THINKER_T
sub   ax, (_thinkerlist + THINKER_T.t_data)
cwd
div   bx

lea   di, [bp - 010h]
mov   si, ax

SHIFT_MACRO shl   si 2
add   si, ax
sal   si, 1  ; si * 10
mov   dx, 0FFFFh

push  ds
pop   es
xor   bx, bx

;mapthing_t
;    int16_t		x;
;    int16_t		y;
;    int16_t		angle;
;    int16_t		type;
;    int16_t		options;

mov   ax, NIGHTMARESPAWNS_SEGMENT
mov   ds, ax
mov   ax, word ptr [bp - 2]
movsw 
movsw 
movsw 
movsw 
movsw 

push  ss
pop   ds ; restore ds

push  word ptr [bp - 0Eh] ; y
mov   cx, word ptr [bp - 010h] ; x
; bx is 0
push  bx



;	// somthing is occupying it's position?
;	if (!P_CheckPosition(mobj, -1, x, y)) {
;		return;	// no respwan
;	}


push cs
call P_CheckPosition_

test  al, al
jne   do_respawn
exit_nightmare_respawn:
LEAVE_MACRO
pop   di
pop   si
pop   dx
retf   
do_respawn:
mov   si, word ptr [bp - 2]
mov   ax, word ptr ds:[si + MOBJ_T.m_secnum]     ; mobjsecnum
mov   es, word ptr [bp - 6]

push  ax
mov   di, word ptr [bp - 4]

IF COMPISA GE COMPILE_186
    push  MT_TFOG
ELSE
    mov   dx, MT_TFOG
    push  dx
ENDIF


mov   bx, word ptr es:[di + MOBJ_POS_T.mp_y + 0]
mov   cx, word ptr es:[di + MOBJ_POS_T.mp_y + 2]
les   di, dword ptr es:[di + MOBJ_POS_T.mp_x + 0]
mov   dx, es

xchg  ax, di
SHIFT_MACRO shl   di 4

;	SET_FIXED_UNION_FROM_SHORT_HEIGHT(temp,  sectors[mobjsecnum].floorheight);
mov   si, SECTORS_SEGMENT
mov   es, si


mov   di, word ptr es:[di] ; floorheight
xor   si, si

sar   di, 1
rcr   si, 1
sar   di, 1
rcr   si, 1
sar   di, 1
rcr   si, 1



push  di
push  si

;	moRef = P_SpawnMobj(mobjx.w, mobjy.w, temp.w, MT_TFOG, mobjsecnum);

;call  P_SpawnMobj_
db 0FFh  ; lcall[addr]
db 01Eh  ;
dw _P_SpawnMobj_addr

mov   dx, SFX_TELEPT
mov   ax, word ptr ds:[_setStateReturn]
mov   cx, word ptr [bp - 0Eh]
;call  S_StartSound_
db 0FFh  ; lcall[addr]
db 01Eh  ;
dw _S_StartSound_addr
mov   dx, word ptr [bp - 010h]
xor   bx, bx
xor   ax, ax

push cs
call R_PointInSubsector_


mov   bx, ax
SHIFT_MACRO shl   bx 2
mov   ax, SUBSECTORS_SEGMENT
mov   es, ax
push  word ptr es:[bx]


IF COMPISA GE COMPILE_186
    push  MT_TFOG
ELSE
    mov   ax, MT_TFOG
    push  ax
ENDIF

mov   cx, word ptr [bp - 0Eh]
mov   dx, word ptr [bp - 010h]
push  di
push  si
xor   ax, ax
mov   bx, ax

;call  P_SpawnMobj_
db 0FFh  ; lcall[addr]
db 01Eh  ;
dw _P_SpawnMobj_addr

mov   dx, SFX_TELEPT
mov   ax, word ptr ds:[_setStateReturn]
mov   bx, word ptr [bp - 2]

;call  S_StartSound_
db 0FFh  ; lcall[addr]
db 01Eh  ;
dw _S_StartSound_addr

xor   cx, cx
mov   cl, byte ptr ds:[bx + MOBJ_T.m_mobjtype]
mov   al, 0Bh
mul   cl
mov   bx, ax
test  byte ptr ds:[bx + _mobjinfo + MOBJINFO_T.mobjinfo_flags1 + 1], (MF_SPAWNCEILING SHR 8)
jne   set_respawn_ceil
; #define ONFLOORZ		MINLONG
mov   dx, 08000h
xor   bx, bx
jmp   done_setting_respawn_z

set_respawn_ceil:
; ONCEILINGZ = MAXLONG 
mov   bx, 0FFFFh
mov   dx, 07FFFh
done_setting_respawn_z:

; dx:bx is respawn z??

mov   ax, -1
push  ax  ; -1
push  cx  ; type
push  dx  ; x hi
push  bx  ; z lo

inc   ax  ; 0 now
mov   bx, ax ; zero
mov   cx, word ptr [bp - 0Eh]
mov   dx, word ptr [bp - 010h]

;    moRef = P_SpawnMobj (x.w,y.w,z.w, mobjtype, -1);

;call  P_SpawnMobj_
db 0FFh  ; lcall[addr]
db 01Eh  ;
dw _P_SpawnMobj_addr

mov   di, ax
SHIFT_MACRO shl   di 2
add   di, ax
sal   di, 1    ; di * 10
lea   si, [bp - 010h]
mov   ax, NIGHTMARESPAWNS_SEGMENT
mov   es, ax

;	nightmarespawns[moRef] = mobjspawnpoint;

movsw 
movsw 
movsw 
movsw 
movsw 

;	mo_pos->angle.wu = FastMul1632u((mobjspawnpoint.angle / 45), ANG45);


mov   ax, word ptr [bp - 0Ch] ; the angle..
cwd   
mov   bx, 45    ; todo
idiv  bx

xor   bx, bx
mov   cx, ANG45_HIGHBITS
mov   si, word ptr ds:[_setStateReturn_pos + 0]
mov   di, word ptr ds:[_setStateReturn_pos + 2]
; call  FastMul16u32u_
db 0FFh  ; lcall[addr]
db 01Eh  ;
dw _FastMul16u32u_addr

mov   es, di
mov   word ptr es:[si + MOBJ_POS_T.mp_angle + 0], ax
mov   word ptr es:[si + MOBJ_POS_T.mp_angle + 2], dx
test  byte ptr [bp - 8], MTF_AMBUSH
je    no_ambush
or    byte ptr es:[si + MOBJ_POS_T.mp_flags1], MF_AMBUSH
no_ambush:
mov   bx, word ptr ds:[_setStateReturn]
mov   ax, word ptr [bp - 2]
mov   byte ptr ds:[bx + MOBJ_T.m_reactiontime], 18
;call  P_RemoveMobj_
db 0FFh  ; lcall[addr]
db 01Eh  ;
dw _P_RemoveMobj_addr
jmp   exit_nightmare_respawn

ENDP


;; callers dont use si or dx. can freely clobber
PROC P_CheckMissileSpawn_ NEAR
PUBLIC P_CheckMissileSpawn_


push  di

mov   di, ax
mov   si, bx
mov   es, cx
inc   byte ptr ds:[_prndindex]
mov   bl, byte ptr ds:[_prndindex]
xor   bh, bh
mov   ax, RNDTABLE_SEGMENT
mov   es, ax

mov   al, byte ptr es:[bx]
mov   es, cx

and   al, 3
sub   byte ptr ds:[di + MOBJ_T.m_tics], al
mov   al, byte ptr ds:[di + MOBJ_T.m_tics]
cmp   al, 1
jb    set_tics_to_1_c
cmp   al, 240
jbe   dont_set_tics_to_1_c
set_tics_to_1_c:
mov   byte ptr ds:[di + MOBJ_T.m_tics], 1
dont_set_tics_to_1_c:

;   // move a little forward so an angle can
;   // be computed if it immediately explodes
;	th_pos->x.w += (th->momx.w>>1);
;	th_pos->y.w += (th->momy.w>>1);
;	th_pos->z.w += (th->momz.w>>1);



mov   ax, word ptr ds:[di + MOBJ_T.m_momx+0]
mov   dx, word ptr ds:[di + MOBJ_T.m_momx+2]
sar   dx, 1
rcr   ax, 1
add   word ptr es:[si], ax
adc   word ptr es:[si + 2], dx

mov   ax, word ptr ds:[di + MOBJ_T.m_momy+0]
mov   dx, word ptr ds:[di + MOBJ_T.m_momy+2]
sar   dx, 1
rcr   ax, 1
add   word ptr es:[si + MOBJ_POS_T.mp_y + 0], ax
adc   word ptr es:[si + MOBJ_POS_T.mp_y + 2], dx

mov   ax, word ptr ds:[di + MOBJ_T.m_momz+0]
mov   dx, word ptr ds:[di + MOBJ_T.m_momz+2]
sar   dx, 1
rcr   ax, 1
add   word ptr es:[si + MOBJ_POS_T.mp_z + 0], ax
adc   word ptr es:[si + MOBJ_POS_T.mp_z + 2], dx

push  word ptr es:[si + MOBJ_POS_T.mp_y + 2]
push  word ptr es:[si + MOBJ_POS_T.mp_y + 0]
push  word ptr es:[si + MOBJ_POS_T.mp_x + 2]
push  word ptr es:[si + MOBJ_POS_T.mp_x + 0]


mov   ax, di
;mov   cx, es
mov   bx, si


push  cs
call  P_TryMove_  ; what if we returned in the carry flag...

test  al, al
jne   exit_check_missile_sapwn
do_missile_explode_on_spawn:
mov   cx, MOBJPOSLIST_6800_SEGMENT
mov   bx, si
mov   ax, di
call  P_ExplodeMissile_
exit_check_missile_sapwn:
pop   di
ret

ENDP




PROC P_SpawnMissile_ FAR
PUBLIC P_SpawnMissile_

; bp + 0Ah    type

; bp - 2     ax (mobj)
; bp - 4     MOBJPOSLIST_6800_SEGMENT
; bp - 6     dest_pos offset
; bp - 8     thRef
; bp - 0Ah   th_pos offset
; bp - 0Ch   destz hi
; bp - 0Eh   destz lo
; bp - 010h  an fracbits
; bp - 012h  an intbits
; bp - 014h  mobjinfo speed value


push  si
push  di
push  bp
mov   bp, sp
push  ax    ; bp - 2
push  cx    ; bp - 4
mov   si, bx
xchg  ax, di

mov   ax, dx
mov   bx, SIZEOF_THINKER_T
sub   ax, (_thinkerlist + THINKER_T.t_data)
xor   dx, dx
div   bx

mov   dx, SIZEOF_MOBJ_POS_T
mul   dx

push  ax  ; bp - 6



xor   ax, ax
mov   al, byte ptr [bp + 0Ah]


push  word ptr ds:[di + MOBJ_T.m_secnum]         ; secnum
push  ax                        ; type
mov   es, cx

mov   ax, word ptr es:[si + MOBJ_POS_T.mp_z + 2]
add   ax, 32  ;  4*8*FRACUNIT

push  ax                    ; z hi
push  word ptr es:[si + MOBJ_POS_T.mp_z + 0]   ; z lo

mov   bx, word ptr es:[si + MOBJ_POS_T.mp_y + 0] ; y
mov   cx, word ptr es:[si + MOBJ_POS_T.mp_y + 2]
les   ax, dword ptr es:[si]  ; x
mov   dx, es

;call  P_SpawnMobj_
db 0FFh  ; lcall[addr]
db 01Eh  ;
dw _P_SpawnMobj_addr



push  ax  ; bp - 8
push  word ptr ds:[_setStateReturn_pos] ; bp - 0Ah
;sub   sp, 0Eh


mov   al, SIZEOF_MOBJINFO_T
mul   byte ptr [bp + 0Ah]   ; type

mov   di, word ptr ds:[_setStateReturn]
mov   bx, ax

mov   al, byte ptr ds:[bx + _mobjInfo + 2]  ; seesound

test  al, al
je    no_see_sound
mov   dl, al
mov   ax, di
xor   dh, dh
;call  S_StartSound_
db 0FFh  ; lcall[addr]
db 01Eh  ;
dw _S_StartSound_addr

no_see_sound:

;    th->targetRef = GETTHINKERREF(source);	// where it came from


mov   ax, word ptr [bp - 2]
mov   bx, SIZEOF_THINKER_T
sub   ax, (_thinkerlist + THINKER_T.t_data)
cwd
div   bx
mov   word ptr ds:[di + MOBJ_T.m_targetRef], ax
lds   bx, dword ptr [bp - 6]

;	destz = dest_pos->z.w;
;	an.wu = R_PointToAngle2 (source_pos->x, source_pos->y, dest_pos->x, dest_pos->y);

; store destz..
push  word ptr ds:[bx + MOBJ_POS_T.mp_z + 2] ; bp - 0Ch
push  word ptr ds:[bx + MOBJ_POS_T.mp_z + 0]   ; bp - 0Eh


push  word ptr ds:[bx + MOBJ_POS_T.mp_y + 2]
push  word ptr ds:[bx + MOBJ_POS_T.mp_y + 0]
push  word ptr ds:[bx + MOBJ_POS_T.mp_x + 2]
push  word ptr ds:[bx + MOBJ_POS_T.mp_x + 0]

lodsw
xchg ax, cx
lodsw
xchg ax, dx
lodsw
xchg ax, bx
lodsw
xchg ax, cx

push  ss
pop   ds
lea   si, [si - 8]

;call  R_PointToAngle2_
db 0FFh  ; lcall[addr]
db 01Eh  ;
dw _R_PointToAngle2_addr

les   bx, dword ptr [bp - 6]
push  ax  ; bp - 010h
test  byte ptr es:[bx + MOBJ_POS_T.mp_flags2], MF_SHADOW

je    no_fuzzmissile
mov   ax, RNDTABLE_SEGMENT
mov   es, ax


;		temp = (P_Random() - P_Random());


xor   ax, ax
mov   bx, ax
mov   bl, byte ptr ds:[_prndindex]
inc   bl
mov   al, byte ptr es:[bx]
inc   bl
sub   al, byte ptr es:[bx]
mov   byte ptr ds:[_prndindex], bl

;		temp  <<= 4;

SHIFT_MACRO shl   ax 4
;		an.hu.intbits += temp;

add   dx, ax
no_fuzzmissile:
push  dx

mov   bx, si
lds   si, dword ptr [bp - 6]

;	dist.w = P_AproxDistance(dest_pos->x.w - source_pos->x.w, dest_pos->y.w - source_pos->y.w);

lodsw
xchg ax, cx
lodsw
xchg ax, dx
lodsw
xchg ax, cx
lodsw
mov  si, bx

xchg ax, cx
; ax/bx swapped.

sub   ax, word ptr ds:[si + MOBJ_POS_T.mp_y + 0]
sbb   cx, word ptr ds:[si + MOBJ_POS_T.mp_y + 2]
xchg ax, bx

sub   ax, word ptr ds:[si + MOBJ_POS_T.mp_x + 0]
sbb   dx, word ptr ds:[si + MOBJ_POS_T.mp_x + 2]

push  ss
pop   ds


push   cs
call  P_AproxDistance_


mov   al, SIZEOF_MOBJINFO_T
mul   byte ptr [bp + 0Ah]
xchg  ax, bx
xchg  ax, dx
mov   bl, byte ptr ds:[bx + _mobjinfo + MOBJINFO_T.mobjinfo_speed]
xor   bh, bh
;	dist16 = dist.h.intbits / (mobjinfo[type].speed - 0x80);

push  bx   ; bp - 014h
sub   bx, 080h
cwd   
idiv  bx


;	momz = FastDiv3216u(destz - source_pos->z.w, dist16);

mov   cx, word ptr [bp - 0Eh]
mov   es, word ptr [bp - 4]
mov   bx, ax
sub   cx, word ptr es:[si + MOBJ_POS_T.mp_z + 0]
mov   ax, cx
mov   dx, word ptr [bp - 0Ch]
sbb   dx, word ptr es:[si + MOBJ_POS_T.mp_z + 2]
;call   FastDiv3216u_
db 0FFh  ; lcall[addr]
db 01Eh  ;
dw _FastDiv3216u_addr
mov   word ptr ds:[di + MOBJ_T.m_momz + 0], ax
mov   word ptr ds:[di + MOBJ_T.m_momz + 2], dx


mov   es, word ptr [bp - 4]
mov   bx, word ptr [bp - 0Ah]
mov   ax, word ptr [bp - 010h]
mov   word ptr es:[bx + MOBJ_POS_T.mp_angle + 0], ax

;    th->momx.w = FixedMulTrigSpeedNoShift(FINE_COSINE_ARGUMENT, temp, mobjinfo[type].speed);

mov   si, word ptr [bp - 012h]
mov   word ptr es:[bx + MOBJ_POS_T.mp_angle + 2], si
shr   si, 1
and   si, 0FFFCh
mov   dx, si
mov   bx, word ptr [bp - 014h]
mov   ax, FINECOSINE_SEGMENT
;call FixedMulTrigSpeedNoShift_
db 0FFh  ; lcall[addr]
db 01Eh  ;
dw _FixedMulTrigSpeedNoShift_addr

mov   word ptr ds:[di + MOBJ_T.m_momx + 0], ax
mov   word ptr ds:[di + MOBJ_T.m_momx + 2], dx

;    th->momy.w = FixedMulTrigSpeedNoShift(FINE_SINE_ARGUMENT  , temp, mobjinfo[type].speed);

mov   dx, si
;mov   bx, word ptr [bp - 014h]
pop   bx
mov   ax, FINESINE_SEGMENT
;call FixedMulTrigSpeedNoShift_
db 0FFh  ; lcall[addr]
db 01Eh  ;
dw _FixedMulTrigSpeedNoShift_addr


mov   word ptr ds:[di + MOBJ_T.m_momy + 0], ax
mov   word ptr ds:[di + MOBJ_T.m_momy + 2], dx

mov   bx, word ptr [bp - 0Ah]
mov   cx, word ptr [bp - 4]
mov   ax, di
call  P_CheckMissileSpawn_

mov   word ptr ds:[_setStateReturn], di

push  word ptr [bp - 0Ah]
push  word ptr [bp - 4]
pop   word ptr ds:[_setStateReturn_pos + 2]  ; todo should be constant write
pop   word ptr ds:[_setStateReturn_pos + 0]

mov   ax, word ptr [bp - 8]
LEAVE_MACRO 
pop   di
pop   si
retf   2


ENDP


PROC P_SpawnPlayerMissile_ NEAR
PUBLIC P_SpawnPlayerMissile_

; bp - 2    type
; bp - 4    slope hi
; bp - 6    slope lo
; bp - 8    thRef
; bp - 0Ah  mobjinfo speed lookup



PUSHA_NO_AX_OR_BP_MACRO 

push   bp
mov    bp, sp
xor    ah, ah   ; todo necessary?
push   ax      ; bp - 2



;	an = playerMobj_pos->angle.hu.intbits >> SHORTTOFINESHIFT;


les    si, dword ptr ds:[_playerMobj_pos]
mov    si, word ptr es:[si + MOBJ_POS_T.mp_angle + 2]

SHIFT_MACRO shr    si 3

;	slope = P_AimLineAttack (playerMobj, an, HALFMISSILERANGE);

mov    ax, word ptr ds:[_playerMobj]
mov    bx, HALFMISSILERANGE
mov    dx, si

push   cs
call   P_AimLineAttack_

mov    di, ax
mov    cx, dx
cmp    word ptr ds:[_linetarget], 0
jne    no_line_target

;		an = MOD_FINE_ANGLE(an +(1<<(26- ANGLETOFINESHIFT)));

add    si, 080h   ; go 0x80 ticks one way
and    si, 01FFFh ; modulo

mov    ax, word ptr ds:[_playerMobj]
mov    bx, HALFMISSILERANGE
mov    dx, si

push   cs
call   P_AimLineAttack_

mov    di, ax
mov    cx, dx

cmp    word ptr ds:[_linetarget], 0

jne    no_line_target_b
sub    si, 0100h  ; go back 0x80 ticks and an extra 0x80 to get the other side
and    si, 01FFFh ; modulo
mov    ax, word ptr ds:[_playerMobj]
mov    bx, HALFMISSILERANGE
mov    dx, si

push   cs
call   P_AimLineAttack_

mov    di, ax
mov    cx, dx

no_line_target_b:
mov    ax, word ptr ds:[_linetarget]
test   ax, ax
jne    no_line_target
; ax is 0
mov    di, ax
mov    cx, ax
les    bx, dword ptr ds:[_playerMobj_pos]
mov    si, word ptr es:[bx + MOBJ_POS_T.mp_angle + 2]
SHIFT_MACRO shr    si 3

no_line_target:
push   cx  ; push hi bp - 4
push   di  ; push lo bp - 6

les    bx, dword ptr ds:[_playerMobj_pos]

mov    di, word ptr es:[bx + MOBJ_POS_T.mp_z + 2]

mov    bx, word ptr ds:[_playerMobj]
push   word ptr ds:[bx + MOBJ_T.m_secnum] ; secnum
push   word ptr [bp - 2] ; type

;	z.w = playerMobj_pos->z.w;
;	z.h.intbits += 32;

add    di, 32
push   di ; z hi

;    thRef = P_SpawnMobj (playerMobj_pos->x.w, playerMobj_pos->y.w,z.w, type, playerMobj->secnum);

les    di, dword ptr ds:[_playerMobj_pos]
push   word ptr es:[di + MOBJ_POS_T.mp_z + 0] ; z lo

mov    bx, word ptr es:[di + MOBJ_POS_T.mp_y + 0]
mov    cx, word ptr es:[di + MOBJ_POS_T.mp_y + 2]

les    ax, dword ptr es:[di]
mov    dx, es

;call  P_SpawnMobj_
db     0FFh  ; lcall[addr]
db     01Eh  ;
dw     _P_SpawnMobj_addr

push   word ptr ds:[_setStateReturn_pos]   ; bp - 8


mov    al, SIZEOF_MOBJINFO_T
mul    byte ptr [bp - 2]


mov    di, word ptr ds:[_setStateReturn]
mov    bx, ax

mov    al, byte ptr ds:[bx + _mobjinfo + 2]

test   al, al
je     no_see_sound_b

mov    dl, al
mov    ax, di
xor    dh, dh

;call  S_StartSound_
db 0FFh  ; lcall[addr]
db 01Eh  ;
dw _S_StartSound_addr

no_see_sound_b:
mov    ax, word ptr ds:[_playerMobjRef]
mov    word ptr ds:[di + MOBJ_T.m_targetRef], ax

mov    al, SIZEOF_MOBJINFO_T
mul    byte ptr [bp - 2]

mov    bx, MOBJPOSLIST_6800_SEGMENT
mov    es, bx
mov    bx, word ptr [bp - 8]
mov    word ptr es:[bx + MOBJ_POS_T.mp_angle + 0], 0
mov    dx, si
SHIFT_MACRO shl dx 3
mov    word ptr es:[bx + MOBJ_POS_T.mp_angle + 2], dx
mov    dx, si


mov    bx, ax
mov    bl, byte ptr ds:[bx + _mobjinfo + MOBJINFO_T.mobjinfo_speed]
xor    bh, bh
push   bx  ; bp - 0Ah
mov    ax, FINECOSINE_SEGMENT
;call   FixedMulTrigSpeed_
db 0FFh  ; lcall[addr]
db 01Eh  ;
dw _FixedMulTrigSpeed_addr

mov    word ptr ds:[di + MOBJ_T.m_momx + 0], ax
mov    word ptr ds:[di + MOBJ_T.m_momx + 2], dx

mov    bx, word ptr [bp - 0Ah]
mov    dx, si
mov    ax, FINESINE_SEGMENT
;call   FixedMulTrigSpeed_
db 0FFh  ; lcall[addr]
db 01Eh  ;
dw _FixedMulTrigSpeed_addr

mov    word ptr ds:[di + MOBJ_T.m_momy + 0], ax
mov    word ptr ds:[di + MOBJ_T.m_momy + 2], dx

pop    ax ; bp - 0Ah
sub    ax, 080h

mov    cx, word ptr [bp - 4]
mov    bx, word ptr [bp - 6]

; call  FastMul16u32u_
db 0FFh  ; lcall[addr]
db 01Eh  ;
dw _FastMul16u32u_addr

mov    bx, word ptr [bp - 8]
mov    cx, MOBJPOSLIST_6800_SEGMENT
mov    word ptr ds:[di + MOBJ_T.m_momz + 0], ax
mov    ax, di
mov    word ptr ds:[di + MOBJ_T.m_momz + 2], dx
call   P_CheckMissileSpawn_

LEAVE_MACRO
POPA_NO_AX_OR_BP_MACRO
ret



ENDP

PROC    P_MOBJ_ENDMARKER_ 
PUBLIC  P_MOBJ_ENDMARKER_
ENDP



END
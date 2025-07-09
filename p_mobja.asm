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


EXTRN FixedMul16u32_:PROC
EXTRN FastMul16u32u_:PROC
EXTRN P_ExplodeMissile_:NEAR
EXTRN P_RemoveMobj_:PROC

.DATA
EXTRN _P_TryMove:DWORD
EXTRN _P_SlideMove:DWORD


.CODE


;void __near P_SpawnPuff ( fixed_t	x, fixed_t	y, fixed_t	z ){

;P_SpawnPuff_

PROC P_SpawnPuff_ FAR
PUBLIC P_SpawnPuff_


push  ax
push  dx
push  bx

mov   ax, RNDTABLE_SEGMENT
mov   es, ax

mov   al, byte ptr ds:[_prndindex]
add   byte ptr ds:[_prndindex], 3  ; for 3 calls this func..
xor   ah, ah
mov   bx, ax
inc   bx
mov   al, byte ptr es:[bx]
sub   al, byte ptr es:[bx+1]

sbb   ah, 0
cwd

; shift ax left 10
mov   dl, ah ; shift 8
mov   ah, al ; shift 8
sal   ax, 1
rcl   dx, 1
sal   ax, 1
rcl   dx, 1
and   ax, 0FC00h  ; clean out bottom bits


add   si, ax
adc   di, dx

mov   al, byte ptr es:[bx+2]
mov   byte ptr cs:[SELFMODIFY_set_rnd_value_3+1], al  

pop   bx
pop   dx
pop   ax

IF COMPISA GE COMPILE_186

push  -1        ; complicated for 8088...
push  MT_PUFF
push  di
push  si


ELSE

mov   es, si
mov   si, -1
push  si
mov   si, MT_PUFF
push  si
push  di
push  es


ENDIF


;call  P_SpawnMobj_
db 0FFh  ; lcall[addr]
db 01Eh  ;
dw _P_SpawnMobj_addr
;	 th = setStateReturn;
;    th->momz.h.intbits = 1;
;    th->tics -= P_Random()&3;

mov   bx, word ptr ds:[_setStateReturn];
mov   word ptr [bx + 018h], 1
SELFMODIFY_set_rnd_value_3:
mov   al, 0FFh
and   al, 3
sub   byte ptr [bx + 01Bh], al

;    if (th->tics < 1 || th->tics > 240){
;		th->tics = 1;
;	}


mov   al, byte ptr [bx + 01Bh]
cmp   al, 1
jb    set_tics_to_1
cmp   al, 240
jbe   dont_set_tics_to_1
set_tics_to_1:
mov   byte ptr [bx + 01Bh], 1
dont_set_tics_to_1:
cmp   word ptr ds:[_attackrange16], MELEERANGE
je    spark_punch_on_wall
retf  
spark_punch_on_wall:
mov   dx, S_PUFF3
mov   ax, bx
;call  P_SetMobjState_
db 0FFh  ; lcall[addr]
db 01Eh  ;
dw _P_SetMobjState_addr
retf   


ENDP

;void __near P_XYMovement (mobj_t __near* mo, mobj_pos_t __far* mo_pos);


PROC P_XYMovement_ NEAR
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
ret   
skull_slammed_into_something:

;			// the skull slammed into something
;			mo_pos->flags2 &= ~MF_SKULLFLY;
;			mo->momx.w = mo->momy.w = mo->momz.w = 0;
;			P_SetMobjState (mo,mobjinfo[mo->type].spawnstate);
and   byte ptr es:[di + MOBJ_POS_T.mp_flags2+1], (NOT (MF_SKULLFLY SHR 8))  ; 0xFE
; ax already 0
mov   word ptr [bx + MOBJ_T.m_momz+2], ax
mov   word ptr [bx + MOBJ_T.m_momz+0], ax
; if we are in this code block we already determined these were 0
; mov   word ptr [bx + MOBJ_T.m_momy+0], ax
; mov   word ptr [bx + MOBJ_T.m_momy+2], ax
; mov   word ptr [bx + MOBJ_T.m_momx+0], ax
; mov   word ptr [bx + MOBJ_T.m_momx+2], ax

mov   al, byte ptr [bx + 01Ah]
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


mov   ax, word ptr [bx + MOBJ_T.m_momx+2]
cmp   ax, MAXMOVE

jge   cap_x_at_maxmove


cmp   ax, -MAXMOVE
jnl   done_capping_xmove
mov   word ptr [bx + MOBJ_T.m_momx+0], 0
mov   word ptr [bx + MOBJ_T.m_momx+2], -MAXMOVE
jmp   done_capping_xmove
cap_x_at_maxmove:
mov   word ptr [bx + MOBJ_T.m_momx+0], 0
mov   word ptr [bx + MOBJ_T.m_momx+2], 01Eh  ; MAXXMOVE 1E0000
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
mov   si, word ptr [bx + MOBJ_T.m_momx+0]
mov   di, word ptr [bx + MOBJ_T.m_momx+2]

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


mov   cx, si
mov   dx, di
sar   dx, 1
rcr   cx, 1
add   cx, word ptr es:[bx]
adc   dx, word ptr es:[bx + 2]

sar   word ptr [bp - 0Ch], 1
rcr   word ptr [bp - 0Eh], 1

mov   ax, word ptr es:[bx + 4]
mov   bx, word ptr es:[bx + 6]
add   ax, word ptr [bp - 0Eh]
adc   bx, word ptr [bp - 0Ch]

sar   di, 1
rcr   si, 1

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

mov   ax, word ptr es:[bx + 4]
add   ax, word ptr [bp - 0Eh]    
mov   bx, word ptr es:[bx + 6]
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
call  _P_TryMove   ; what if we returned in the carry flag...
test  al, al
jne   cant_move
; 
cmp   word ptr [bp - 8], MT_PLAYER
je    player_try_slide
jmp   do_missile_check
player_try_slide:
call  _P_SlideMove

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
mov   ax, word ptr [bx + 6]
sar       ax, 1
rcr       dx, 1
sar       ax, 1
rcr       dx, 1
sar       ax, 1
rcr       dx, 1

;	if (mo_pos->z.w > temp.w) {
;		return;		// no friction when airborne
;	}


cmp   ax, word ptr es:[di + 0Ah]
jl    jump_to_exit_p_xymovement
jne   not_in_air
cmp   dx, word ptr es:[di + 8]
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

mov   ax, word ptr [bx + MOBJ_T.m_momx+2]
test  ax, ax
jg    check_floor_height
je    check_y_pos
;		if (mo->momx.w > FRACUNIT/4 || mo->momx.w < -FRACUNIT/4 || mo->momy.w > FRACUNIT/4 || mo->momy.w < -FRACUNIT/4) {
; ax is momx hibits
continue_fracunit_over_4_momentum_check:
cmp   ax, 0FFFFh   ; hi bits negative
jnge  check_floor_height
jne   continue_momy_check_floor
cmp   word ptr [bx + MOBJ_T.m_momx+0], -FRACUNITOVER4
jb    check_floor_height
continue_momy_check_floor:
mov   ax, word ptr [bx + MOBJ_T.m_momy+2]
test  ax, ax
jg    check_floor_height
jne   check_momy_negative
cmp   word ptr [bx + MOBJ_T.m_momy+0], FRACUNITOVER4
ja    check_floor_height
check_momy_negative:
cmp   ax, 0FFFFh   ; hi bits negative
jl    check_floor_height
jne   done_with_corpse_check
cmp   word ptr [bx + MOBJ_T.m_momy+0], -FRACUNITOVER4  ; 0c000h
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
cmp   ax, word ptr [bx + 6]
jne   jump_to_exit_p_xymovement


is_not_corpse:
done_with_corpse_check:


;	momomx = mo->momx;
;	momomy = mo->momy;

mov   di, word ptr [bx + MOBJ_T.m_momy+0]
mov   cx, word ptr [bx + MOBJ_T.m_momx+2]


; if ((momomx.w > -STOPSPEED && momomx.w < STOPSPEED && momomy.w > -STOPSPEED && momomy.w < STOPSPEED) && 

mov   si, word ptr [bx + MOBJ_T.m_momy+2]
mov   bx, word ptr [bx + MOBJ_T.m_momx+0]
cmp   cx, 0FFFFh   ; hi bits negative
jg    momomx_not_in_negative_range
je    continue_stopspeed_checks_1
apply_friction:

mov   ax, FRICTION
call  FixedMul16u32_
mov   bx, word ptr [bp - 2]
mov   word ptr [bx + MOBJ_T.m_momx+0], ax
mov   cx, si
mov   word ptr [bx + MOBJ_T.m_momx+2], dx
mov   bx, di
mov   ax, FRICTION
call  FixedMul16u32_
mov   bx, word ptr [bp - 2]
mov   word ptr [bx + MOBJ_T.m_momy+0], ax
mov   word ptr [bx + MOBJ_T.m_momy+2], dx
LEAVE_MACRO 
pop   di
pop   si
pop   dx
ret   

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
mov   ax, word ptr es:[si + 012h]
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
mov   word ptr [bx + MOBJ_T.m_momx+0], 0
mov   word ptr [bx + MOBJ_T.m_momx+2], 0
mov   word ptr [bx + MOBJ_T.m_momy+0], 0
mov   word ptr [bx + MOBJ_T.m_momy+2], 0
LEAVE_MACRO
pop   di
pop   si
pop   dx
ret   



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
mov   bx, word ptr es:[bx + 0Ch]

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

call  P_RemoveMobj_
LEAVE_MACRO
pop   di
pop   si
pop   dx
ret   
not_missile_dont_explode:

;				mo->momx.w = mo->momy.w = 0;

mov   bx, word ptr [bp - 2]
xor   ax, ax
mov   word ptr [bx + MOBJ_T.m_momx+0], ax
mov   word ptr [bx + MOBJ_T.m_momx+2], ax
mov   word ptr [bx + MOBJ_T.m_momy+0], ax
mov   word ptr [bx + MOBJ_T.m_momy+2], ax
jmp   cant_move



ENDP


FLOATSPEED_HIGHBITS = 4
VIEWHEIGHT_HIGH = 41

PROC P_ZMovement_ NEAR
PUBLIC P_ZMovement_

; bp - 2  segment for mobjpos (MOBJPOSLIST_6800_SEGMENT)
; bp - 4  floorz fixedheight hi
; bp - 6  floorz fixedheight lo
; bp - 8    delta hi
; bp - 0Ah  delta lo
; bp - 0Ch  dist hi
; bp - 0Eh  dist lo
; bp - 010h UNUSED
; bp - 012h UNUSED
; bp - 014h mobj type
; bp - 016h unused
; bp - 018h unused
; bp - 01Ah moTarget_pos offset
; bp - 01Ch unused


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
sub   sp, 014h
mov   es, cx
xor   cx, cx
mov   cl, byte ptr ds:[si + MOBJ_T.m_mobjtype]
mov   word ptr [bp - 014h], cx  ; todo push
;    if (motype == MT_PLAYER && mo_pos->z.w < temp.w) {
test  cl, cl
jne   z_not_player
cmp   ax, word ptr es:[di + 0Ah]    ; ax still has high
jg    do_smooth_step_up
jne   z_not_player
cmp   dx, word ptr es:[di + 8]      ; dx still has low
jnae  z_not_player
do_smooth_step_up:

;		player.viewheightvalue.w -= (temp.w-mo_pos->z.w);
sub   dx, word ptr es:[di + 8]
sbb   ax, word ptr es:[di + 0Ah]
sub   word ptr ds:[_player + PLAYER_T.player_viewheightvalue+0], dx
sbb   word ptr ds:[_player + PLAYER_T.player_viewheightvalue+2], ax

;		player.deltaviewheight.w = (VIEWHEIGHT - player.viewheightvalue.w)>>3;

xor   ax, ax
sub   ax, word ptr ds:[PLAYER_T.player_viewheightvalue+0]
mov   dx, VIEWHEIGHT_HIGH
sbb   dx, word ptr ds:[PLAYER_T.player_viewheightvalue+2]

sar   dx, 1
rcr   ax, 1
sar   dx, 1
rcr   ax, 1
sar   dx, 1
rcr   ax, 1

mov   word ptr ds:[_player + PLAYER_T.player_deltaviewheight+0], ax
mov   word ptr ds:[_player + PLAYER_T.player_deltaviewheight+2], dx
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
cmp   word ptr [si + 022h], 0
je    jump_to_done_with_floating_with_target
test  byte ptr es:[di + 017h], (MF_SKULLFLY SHR 8)
jne   jump_to_done_with_floating_with_target
test  byte ptr es:[di + 016h], MF_INFLOAT
jne   jump_to_done_with_floating_with_target

;		// float down towards target if too close
;		if ( !(mo_pos->flags2 & MF_SKULLFLY) && !(mo_pos->flags2 & MF_INFLOAT) ) {


;    moTarget = (mobj_t __near*)&thinkerlist[mo->targetRef].data;
;    moTarget_pos = &mobjposlist_6800[mo->targetRef];

IF COMPISA GE COMPILE_186
    imul  bx, word ptr [si + 022h], SIZEOF_MOBJ_POS_T
ELSE
    mov   ax, SIZEOF_MOBJ_POS_T
    mul   word ptr [si + 022h]
    mov   bx, ax
ENDIF

mov   word ptr [bp - 01Ah], bx


;    dist = P_AproxDistance (mo_pos->x.w - moTarget_pos->x.w,
;        mo_pos->y.w - moTarget_pos->y.w);

mov   ax, word ptr es:[di + 4]
mov   cx, word ptr es:[di + 6]
sub   ax, word ptr es:[bx + 4]
sbb   cx, word ptr es:[bx + 6]
push  ax    ; store y diff lo



mov   ax, word ptr es:[di]
mov   dx, word ptr es:[di + 2]
sub   ax, word ptr es:[bx]
sbb   dx, word ptr es:[bx + 2]

pop   bx

;call  dword ptr ds:[_P_AproxDistance]

db    09Ah
dw P_AproxDistanceOffset
dw PHYSICS_HIGHCODE_SEGMENT

mov   bx, word ptr [bp - 01Ah]
mov   es, word ptr [bp - 2]
mov   word ptr [bp - 0Eh], ax
mov   word ptr [bp - 0Ch], dx

;	delta =(moTarget_pos->z.w + (mo->height.w>>1)) - mo_pos->z.w;

mov   ax, word ptr ds:[si + MOBJ_T.m_height+0]
mov   dx, word ptr ds:[si + MOBJ_T.m_height+2]
sar   dx, 1
rcr   ax, 1

add   ax, word ptr es:[bx + MOBJ_POS_T.mp_z+0]
adc   dx, word ptr es:[bx + MOBJ_POS_T.mp_z+2]
sub   ax, word ptr es:[di + MOBJ_POS_T.mp_z+0]
sbb   dx, word ptr es:[di + MOBJ_POS_T.mp_z+2]
;mov   word ptr [bp - 0Ah], ax
;mov   word ptr [bp - 8], dx

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
call  FastMul16u32u_
mov   bx, ax
mov   ax, dx
neg   ax
neg   bx
sbb   ax, 0
cmp   ax, word ptr [bp - 0Ch]
jg    do_sub_floatspeed
je    compare_low_bits_floatspeed
jump_to_dont_sub_floatspeed:
pop   dx
pop   ax
jmp   dont_sub_floatspeed
compare_low_bits_floatspeed:
cmp   bx, word ptr [bp - 0Eh]
jbe   jump_to_dont_sub_floatspeed
do_sub_floatspeed:
mov   es, word ptr [bp - 2]
sub   word ptr es:[di + 0Ah], FLOATSPEED_HIGHBITS
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
call  FastMul16u32u_
cmp   dx, word ptr [bp - 0Ch]
jg    do_add_floatspeed
jne   done_with_floating_with_target
cmp   ax, word ptr [bp - 0Eh]
jbe   done_with_floating_with_target
do_add_floatspeed:
mov   es, word ptr [bp - 2]
add   word ptr es:[di + 0Ah], FLOATSPEED_HIGHBITS

done_with_floating_with_target:
mov   es, word ptr [bp - 2]
mov   ax, word ptr es:[di + 0Ah]
cmp   ax, word ptr [bp - 4]
jl    label_9
je    label_10
jump_to_label_11:
jmp   label_11
label_10:
mov   ax, word ptr es:[di + 8]
cmp   ax, word ptr [bp - 6]
ja    jump_to_label_11
label_9:
cmp   byte ptr ds:[_is_ultimate], 0
je    label_12
test  byte ptr es:[di + 017h], 1
je    label_12
neg   word ptr [si + 018h]
neg   word ptr [si + 016h]
sbb   word ptr [si + 018h], 0
label_12:
cmp   word ptr [si + 018h], 0
jge   label_13
jmp   label_14
label_13:
mov   es, word ptr [bp - 2]
mov   ax, word ptr [bp - 6]
mov   word ptr es:[di + 8], ax
mov   ax, word ptr [bp - 4]

mov   word ptr es:[di + 0Ah], ax
cmp   byte ptr ds:[_is_ultimate], 0
jne   label_15
test  byte ptr es:[di + 017h], 1
je    label_15
neg   word ptr [si + 018h]
neg   word ptr [si + 016h]
sbb   word ptr [si + 018h], 0
label_15:
mov   es, word ptr [bp - 2]
test  byte ptr es:[di + 016h], 1
je    label_16
test  byte ptr es:[di + 015h], 010h
jne   label_16
jmp   label_18
label_16:
mov   ax, word ptr [si + 8]
sar   ax, 3
mov   word ptr [bp - 4], ax
mov   ax, word ptr [si + 8]
and   ax, 7
mov   es, word ptr [bp - 2]
shl   ax, 0Dh
mov   dx, word ptr es:[di + 8]
mov   word ptr [bp - 6], ax
mov   ax, word ptr es:[di + 0Ah]
add   dx, word ptr [si + 0Ah]
adc   ax, word ptr [si + 0Ch]
cmp   ax, word ptr [bp - 4]
jg    label_17
jne   exit_p_zmovement
cmp   dx, word ptr [bp - 6]
jbe   exit_p_zmovement
label_17:
mov   ax, word ptr [si + 018h]
test  ax, ax
jg    label_21
jne   label_22
cmp   word ptr [si + 016h], 0
jbe   label_22
label_21:
mov   word ptr [si + 016h], 0
mov   word ptr [si + 018h], 0
label_22:
mov   bx, word ptr [bp - 6]
mov   dx, word ptr [si + 0Ah]
mov   ax, word ptr [si + 0Ch]
mov   es, word ptr [bp - 2]
sub   bx, dx
mov   word ptr es:[di + 8], bx
mov   dx, word ptr [bp - 4]
sbb   dx, ax
mov   word ptr es:[di + 0Ah], dx
test  byte ptr es:[di + 017h], 1
jne   jump_to_label_19
label_20:
mov   es, word ptr [bp - 2]
test  byte ptr es:[di + 016h], 1
je    exit_p_zmovement
test  byte ptr es:[di + 015h], 010h
je    jump_to_label_18
exit_p_zmovement:
LEAVE_MACRO
pop   di
pop   si
pop   dx
ret   

label_14:
cmp   word ptr [bp - 014h], MT_PLAYER
jne   label_23
mov   ax, word ptr [si + 018h]
cmp   ax, 0fff8h
jl    label_24
label_23:
mov   word ptr [si + 016h], 0
mov   word ptr [si + 018h], 0
jmp   label_13
jump_to_label_19:
jmp   label_19
jump_to_label_18:
jmp   label_18
label_24:
mov   ax, word ptr [si + 016h]
mov   dx, word ptr [si + 018h]


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


jmp   label_23
label_18:
mov   bx, di
mov   cx, es
mov   ax, si
call  P_ExplodeMissile_
LEAVE_MACRO 
pop   di
pop   si
pop   dx
ret   
label_11:
test  byte ptr es:[di + 015h], 2
je    label_25
jmp   label_16
label_25:
mov   ax, word ptr [si + 018h]
or    ax, word ptr [si + 016h]
jne   label_26
mov   word ptr [si + 018h], 0fffeh
jmp   label_16
label_26:
dec   word ptr [si + 018h]
jmp   label_16
label_19:
neg   word ptr [si + 018h]
neg   word ptr [si + 016h]
sbb   word ptr [si + 018h], 0
jmp   label_20



ENDP


END
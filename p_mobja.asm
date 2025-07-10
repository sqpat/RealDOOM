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

;call  P_RemoveMobj_
db 0FFh  ; lcall[addr]
db 01Eh  ;
dw _P_RemoveMobj_addr

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
sub   dx, word ptr es:[di + 8]
sbb   ax, word ptr es:[di + 0Ah]

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

push  bx  ; store for later


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

pop   bx    ; get y diff lo

;call  dword ptr ds:[_P_AproxDistance]

db    09Ah
dw P_AproxDistanceOffset
dw PHYSICS_HIGHCODE_SEGMENT

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
call  FastMul16u32u_
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
cmp   dx, word ptr [bp - 0Ah]
jg    do_add_floatspeed
jne   done_with_floating_with_target
cmp   ax, word ptr [bp - 0Ch]
jbe   done_with_floating_with_target
do_add_floatspeed:
mov   es, word ptr [bp - 2]
add   word ptr es:[di + 0Ah], FLOATSPEED_HIGHBITS

done_with_floating_with_target:

;    // clip movement
;    if (mo_pos->z.w <= temp.w) {

mov   es, word ptr [bp - 2]
mov   ax, word ptr es:[di + 0Ah]
cmp   ax, word ptr [bp - 4]
jl    hit_floor
je    check_floor_lobits

didnt_hit_floor:

;	} else if (! (mo_pos->flags1 & MF_NOGRAVITY) ) {

test  byte ptr es:[di + 015h], (MF_NOGRAVITY SHR 8)
je    do_gravity
jmp   done_with_floor_z_collision
do_gravity:
;		if (mo->momz.w == 0) {
mov   ax, word ptr [si + 018h]
or    ax, word ptr [si + 016h]
jne   add_gravity
;	mo->momz.h.intbits = -GRAVITY_HIGHBITS << 1;
mov   word ptr [si + 018h], 0FFFEh
jmp   done_with_floor_z_collision
add_gravity:
;    mo->momz.h.intbits -= GRAVITY_HIGHBITS;

dec   word ptr [si + 018h]
jmp   done_with_floor_z_collision

check_floor_lobits:
mov   ax, word ptr es:[di + 8]
cmp   ax, word ptr [bp - 6]
ja    didnt_hit_floor
hit_floor:
cmp   byte ptr ds:[_is_ultimate], 0
je    skip_ultimate_hack


test  byte ptr es:[di + 017h], (MF_SKULLFLY SHR 8)
je    skip_ultimate_hack

;			// Note (id):
;			//  somebody left this after the setting momz to 0,
;			//  kinda useless there.
;			if (mo_pos->flags2 & MF_SKULLFLY)
;			{
;				// the skull slammed into something
;				mo->momz.w = -mo->momz.w;
;			}

neg   word ptr [si + 018h]
neg   word ptr [si + 016h]
sbb   word ptr [si + 018h], 0
skip_ultimate_hack:

;	if (mo->momz.h.intbits < 0) {

cmp   word ptr [si + 018h], 0
jge   dont_squat
jmp   continue_squat_check
dont_squat:
done_with_squat:

;	mo_pos->z.w = temp.w;   (floor value)

mov   es, word ptr [bp - 2]
mov   ax, word ptr [bp - 6]
mov   word ptr es:[di + 8], ax
mov   ax, word ptr [bp - 4]
mov   word ptr es:[di + 0Ah], ax

;		if (!is_ultimate){
;			if (mo_pos->flags2 & MF_SKULLFLY) {
;				// the skull slammed into something
;				mo->momz.w = -mo->momz.w;


cmp   byte ptr ds:[_is_ultimate], 0
jne   skip_ultimate_skull_check
test  byte ptr es:[di + 017h], (MF_SKULLFLY SHR 8)
je    skip_ultimate_skull_check
neg   word ptr [si + 018h]
neg   word ptr [si + 016h]
sbb   word ptr [si + 018h], 0
skip_ultimate_skull_check:

;mov   es, word ptr [bp - 2]
test  byte ptr es:[di + 016h], MF_MISSILE
je    dont_explode_missile
test  byte ptr es:[di + 015h], (MF_NOCLIP SHR 8)
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
ret   
dont_explode_missile:
done_with_floor_z_collision:

;	SET_FIXED_UNIO;N_FROM_SHORT_HEIGHT(temp, mo->ceilingz);

mov   es, word ptr [bp - 2]
mov   dx, word ptr [si + 8]
xor   ax, ax
sar   dx, 1
rcr   ax, 1
sar   dx, 1
rcr   ax, 1
sar   dx, 1
rcr   ax, 1



mov   bx, word ptr es:[di + 8]
mov   cx, word ptr es:[di + 0Ah]
add   bx, word ptr [si + 0Ah]
adc   cx, word ptr [si + 0Ch]

cmp   cx, dx
jg    check_ceil_lobits
jne   exit_p_zmovement
cmp   bx, ax
jbe   exit_p_zmovement
check_ceil_lobits:

cmp   word ptr [si + 018h], 0
jg    hit_ceiling
jne   cap_z_to_ceiling
cmp   word ptr [si + 016h], 0
jbe   cap_z_to_ceiling
hit_ceiling:

;		if (mo->momz.w > 0) {
;			mo->momz.w = 0;
;		}

mov   word ptr [si + 016h], 0
mov   word ptr [si + 018h], 0
cap_z_to_ceiling:

sub   ax, word ptr [si + 0Ah]
sbb   dx, word ptr [si + 0Ch]
mov   word ptr es:[di + 8], ax
mov   word ptr es:[di + 0Ah], dx

test  byte ptr es:[di + 017h], (MF_SKULLFLY SHR 8)
je    skip_skull_slam
; skull slam
neg   word ptr [si + 018h]
neg   word ptr [si + 016h]
sbb   word ptr [si + 018h], 0

skip_skull_slam:
test  byte ptr es:[di + 016h], MF_MISSILE
je    exit_p_zmovement
test  byte ptr es:[di + 015h], (MF_NOCLIP SHR 8)
je    do_explode_missile
exit_p_zmovement:
LEAVE_MACRO
pop   di
pop   si
pop   dx
ret   

continue_squat_check:
;	if (motype == MT_PLAYER && mo->momz.w < -GRAVITY*8)	 {

cmp   byte ptr [bp - 8], MT_PLAYER
jne   land_and_momz_0
mov   ax, word ptr [si + 018h]
cmp   ax, 0FFF8h                    ; -GRAVITY*8. gravity is FRACUNIT or 1 in the high word.
jnl   land_and_momz_0

do_player_squat_landing:

;    // Squat down.
;    // Decrease viewheight for a moment
;    // after hitting the ground (hard),
;    // and utter appropriate sound.
;    player.deltaviewheight.w = mo->momz.w>>3;
;    S_StartSound (mo, sfx_oof);

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

;	mo->momz.w = 0;

land_and_momz_0:
mov   word ptr [si + 016h], 0
mov   word ptr [si + 018h], 0
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
rep   stosb ; zero all six words out

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
sub   byte ptr [si + 01Bh], al
mov   al, byte ptr [si + 01Bh]
cmp   al, 1
jb    set_tics_to_1_b
cmp   al, 240 ; check for tics overflow. jank
jbe   dont_set_tics_to_1_b
set_tics_to_1_b:
mov   byte ptr [si + 01Bh], 1
dont_set_tics_to_1_b:

;	mo_pos->flags2 &= ~MF_MISSILE;

;	if (mobjinfo[mo->type].deathsound) {
;		S_StartSound(mo, mobjinfo[mo->type].deathsound);
;	}

pop   es  ; was bp - 2, only use...
and   byte ptr es:[bx + 016h], (NOT MF_MISSILE)
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

PROC P_NightmareRespawn_ NEAR
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
sub   ax, (_thinkerlist + 4)
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



; call P_CheckPosition_
db    09Ah
dw    P_CHECKPOSITIONOFFSET, PHYSICS_HIGHCODE_SEGMENT

test  al, al
jne   do_respawn
exit_nightmare_respawn:
LEAVE_MACRO
pop   di
pop   si
pop   dx
ret   
do_respawn:
mov   si, word ptr [bp - 2]
mov   ax, word ptr [si + 4]     ; mobjsecnum
mov   es, word ptr [bp - 6]

push  ax
mov   di, word ptr [bp - 4]

IF COMPISA GE COMPILE_186
    push  MT_TFOG
ELSE
    mov   dx, MT_TFOG
    push  dx
ENDIF


mov   bx, word ptr es:[di + 4]
mov   cx, word ptr es:[di + 6]
les   di, dword ptr es:[di + 0]
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


; call P_CheckPosition_
db    09Ah
dw    R_POINTINSUBSECTOROFFSET, PHYSICS_HIGHCODE_SEGMENT


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
mov   cl, byte ptr [bx + 01Ah]
mov   al, 0Bh
mul   cl
mov   bx, ax
test  byte ptr ds:[bx + _mobjinfo + 8], (MF_SPAWNCEILING SHR 8)
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
call  FastMul16u32u_
mov   es, di
mov   word ptr es:[si + 0Eh], ax
mov   word ptr es:[si + 010h], dx
test  byte ptr [bp - 8], MTF_AMBUSH
je    no_ambush
or    byte ptr es:[si + 014h], MF_AMBUSH
no_ambush:
mov   bx, word ptr ds:[_setStateReturn]
mov   ax, word ptr [bp - 2]
mov   byte ptr [bx + 024h], 18
;call  P_RemoveMobj_
db 0FFh  ; lcall[addr]
db 01Eh  ;
dw _P_RemoveMobj_addr
jmp   exit_nightmare_respawn

ENDP

END
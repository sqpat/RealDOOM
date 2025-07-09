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


EXTRN __I4D:PROC
EXTRN FixedMul16u32_:PROC
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
; bp - 2    ptryx hi
; bp - 4    ptryx lo
; bp - 6    mobj_type
; bp - 8    momomx hi
; bp - 0Ah  mobj_secnum
; bp - 0Ch  ymove hi
; bp - 0Eh  ymove lo

; bp - 010h  mobj/ax
; bp - 012h  mobjpos offset/bx
; bp - 014h  mobjpos seg/cx

push  dx
push  si
push  di
push  bp
mov   bp, sp
sub   sp, 0Eh
push  ax        ; mobj
push  cx
push  bx
mov   bx, ax  ; bx gets mobj

;	if (!mo->momx.w && !mo->momy.w) {

mov   al, byte ptr ds:[bx + MOBJ_T.m_mobjtype] ; todo move push later. 
xor   ah, ah
mov   word ptr [bp - 6], ax

mov   ax, word ptr ds:[bx + MOBJ_T.m_momx+2]
or    ax, word ptr ds:[bx + MOBJ_T.m_momx+0]
jne   mobj_is_moving
mov   ax, word ptr ds:[bx + MOBJ_T.m_momy+2]
or    ax, word ptr ds:[bx + MOBJ_T.m_momy+0]
jne   mobj_is_moving

;		if (mo_pos->flags2 & MF_SKULLFLY) {

mov   di, word ptr [bp - 014h]
mov   es, cx
test  byte ptr es:[di + 017h], (MF_SKULLFLY SHR 8)
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
mov   ax, word ptr ds:[bx + m_secnum]         ; mosecnum = mo->secnum;
mov   word ptr [bp - 0Ah], ax

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

mov   ax, word ptr [bx + MOBJ_T.m_momy+0]
mov   word ptr [bp - 0Eh], ax
mov   ax, word ptr [bx + MOBJ_T.m_momy+2]
mov   word ptr [bp - 0Ch], ax

; xmove is di:si
; ymove is 0C 0E
mov   si, word ptr [bx + MOBJ_T.m_momx+0]
mov   di, word ptr [bx + MOBJ_T.m_momx+2]

;	do {

do_while_x_or_y_nonzero:

;	if (xmove.w > MAXMOVE/2 || ymove.w > MAXMOVE/2) {
les   bx, dword ptr [bp - 014h]

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


mov   ax, si
mov   dx, di
sar   dx, 1
rcr   ax, 1
add   ax, word ptr es:[bx]
adc   dx, word ptr es:[bx + 2]
mov   word ptr [bp - 4], ax
mov   word ptr [bp - 2], dx
mov   dx, word ptr [bp - 0Ch]
mov   ax, word ptr [bp - 0Eh]

sar   dx, 1
rcr   ax, 1

add   ax, word ptr es:[bx + 4]
adc   dx, word ptr es:[bx + 6]
sar   word ptr [bp - 0Ch], 1
rcr   word ptr [bp - 0Eh], 1
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

mov   ax, word ptr es:[bx]
add   ax, si
mov   word ptr [bp - 4], ax
mov   ax, word ptr es:[bx + 2]
adc   ax, di
mov   word ptr [bp - 2], ax
xor   si, si
mov   di, si

mov   ax, word ptr es:[bx + 4]
add   ax, word ptr [bp - 0Eh]    
mov   dx, word ptr es:[bx + 6]
adc   dx, word ptr [bp - 0Ch]

mov   word ptr [bp - 0Eh], si
mov   word ptr [bp - 0Ch], si



done_shifting_xymove:


;		if (!P_TryMove (mo, mo_pos, ptryx, ptryy)) {

push  dx
push  ax
push  word ptr [bp - 2]
push  word ptr [bp - 4]
; bx already set
mov   cx, es
mov   ax, word ptr [bp - 010h]
call  _P_TryMove   ; what if we returned in the carry flag...
test  al, al
jne   cant_move
; 
cmp   word ptr [bp - 6], 0
je    label_42
jmp   label_43
label_42:
call  _P_SlideMove

cant_move:
;    } while (xmove.w || ymove.w);

test  di, di
je    label_26
jump_to_do_while_x_or_y_nonzero:
jmp   do_while_x_or_y_nonzero
label_26:
test  si, si
jne   jump_to_do_while_x_or_y_nonzero
cmp   word ptr [bp - 0Ch], 0
jne   jump_to_do_while_x_or_y_nonzero
cmp   word ptr [bp - 0Eh], 0
jne   jump_to_do_while_x_or_y_nonzero

mov   bx, word ptr [bp - 010h]

;    // slow down
;    if (motype == MT_PLAYER && player.cheats & CF_NOMOMENTUM) {

cmp   word ptr [bp - 6], 0
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
les   di, dword ptr [bp - 014h]

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
test  byte ptr es:[di + 016h], MF_CORPSE
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
cmp   ax, 0FFFFh
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
cmp   ax, 0FFFFh
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

mov   ax, word ptr [bx + MOBJ_T.m_momy+0]
mov   cx, word ptr [bx + MOBJ_T.m_momx+2]


; if ((momomx.w > -STOPSPEED && momomx.w < STOPSPEED && momomy.w > -STOPSPEED && momomy.w < STOPSPEED) && 

mov   word ptr [bp - 8], ax
mov   si, word ptr [bx + MOBJ_T.m_momy+2]
mov   bx, word ptr [bx + MOBJ_T.m_momx+0]
cmp   cx, 0FFFFh   ; hi bits negative
jg    label_14
je    label_15
label_19:
jmp   label_16
label_15:
cmp   bx, -STOPSPEED
jbe   label_19
label_14:
test  cx, cx
jl    label_18
jne   label_19
cmp   bx, STOPSPEED
jae   label_19
label_18:
cmp   si, -1
jg    label_44
jne   label_19
cmp   ax, -STOPSPEED
jbe   label_19
label_44:
test  si, si
jl    label_45
jne   label_19
cmp   ax, STOPSPEED
jae   label_19
label_45:
cmp   word ptr [bp - 6], 0
je    label_20
label_17:
cmp   word ptr [bp - 6], 0
jne   label_13
mov   bx, OFFSET _playerMobj_pos
les   si, dword ptr [bx]
mov   ax, word ptr es:[si + 012h]
sub   ax, S_PLAY_RUN1
cmp   ax, 4
jae   label_13
mov   bx, OFFSET _playerMobj
mov   dx, S_PLAY
mov   ax, word ptr [bx]

;call  P_SetMobjState_
db 0FFh  ; lcall[addr]
db 01Eh  ;
dw _P_SetMobjState_addr
label_13:
mov   bx, word ptr [bp - 010h]
mov   word ptr [bx + MOBJ_T.m_momx+0], 0
mov   word ptr [bx + MOBJ_T.m_momx+2], 0
mov   word ptr [bx + MOBJ_T.m_momy+0], 0
mov   word ptr [bx + MOBJ_T.m_momy+2], 0
LEAVE_MACRO
pop   di
pop   si
pop   dx
ret   
label_20:
mov   di, OFFSET _player + PLAYER_T.player_cmd_forwardmove
cmp   byte ptr [di], 0
jne   label_16
mov   di, OFFSET _player + PLAYER_T.player_cmd_sidemove
cmp   byte ptr [di], 0
je    label_17
label_16:
mov   ax, FRICTION
call  FixedMul16u32_
mov   bx, word ptr [bp - 010h]
mov   word ptr [bx + MOBJ_T.m_momx+0], ax
mov   cx, si
mov   word ptr [bx + MOBJ_T.m_momx+2], dx
mov   bx, word ptr [bp - 8]
mov   ax, FRICTION
call  FixedMul16u32_
mov   bx, word ptr [bp - 010h]
mov   word ptr [bx + MOBJ_T.m_momy+0], ax
mov   word ptr [bx + MOBJ_T.m_momy+2], dx
LEAVE_MACRO 
pop   di
pop   si
pop   dx
ret   

label_43:
les   bx, dword ptr [bp - 014h]
test  byte ptr es:[bx + 016h], MF_MISSILE
je    label_38
mov   bx, OFFSET _ceilinglinenum
mov   bx, word ptr [bx]
mov   dx, LINES_PHYSICS_SEGMENT
SHIFT_MACRO shl   bx 4
mov   es, dx
add   bx, 0Ch
mov   ax, word ptr es:[bx]
mov   bx, OFFSET _ceilinglinenum
cmp   word ptr [bx], SECNUM_NULL
je    label_39
cmp   ax, SECNUM_NULL
je    label_39
mov   bx, ax
mov   dx, SECTORS_SEGMENT
SHIFT_MACRO shl   bx 4
mov   es, dx
add   bx, 5
mov   al, byte ptr es:[bx]
mov   bx, OFFSET _skyflatnum
cmp   al, byte ptr [bx]
je    label_40
label_39:
mov   bx, word ptr [bp - 014h]
mov   cx, word ptr [bp - 012h]
mov   ax, word ptr [bp - 010h]
call  P_ExplodeMissile_
jmp   cant_move
label_40:
mov   ax, word ptr [bp - 010h]

call  P_RemoveMobj_
LEAVE_MACRO
pop   di
pop   si
pop   dx
ret   
label_38:
mov   bx, word ptr [bp - 010h]
mov   word ptr [bx + MOBJ_T.m_momy+0], 0
mov   word ptr [bx + MOBJ_T.m_momy+2], 0
mov   dx, word ptr [bx + MOBJ_T.m_momy+0]
mov   ax, word ptr [bx + MOBJ_T.m_momy+2]
mov   word ptr [bx + MOBJ_T.m_momx+0], dx
mov   word ptr [bx + MOBJ_T.m_momx+2], ax
jmp   cant_move



ENDP

COMMENT @
PROC P_ZMovement_ FAR
PUBLIC P_ZMovement_


0x00000000000003ec:  52                   push  dx
0x00000000000003ed:  56                   push  si
0x00000000000003ee:  57                   push  di
0x00000000000003ef:  55                   push  bp
0x00000000000003f0:  89 E5                mov   bp, sp
0x00000000000003f2:  83 EC 1E             sub   sp, 01Eh
0x00000000000003f5:  89 C6                mov   si, ax
0x00000000000003f7:  89 DF                mov   di, bx
0x00000000000003f9:  89 4E FE             mov   word ptr [bp - 2], cx
0x00000000000003fc:  8B 54 06             mov   dx, word ptr [si + 6]
0x00000000000003ff:  C1 FA 03             sar   dx, 3
0x0000000000000402:  89 56 FC             mov   word ptr [bp - 4], dx
0x0000000000000405:  8B 54 06             mov   dx, word ptr [si + 6]
0x0000000000000408:  30 F6                xor   dh, dh
0x000000000000040a:  8A 44 1A             mov   al, byte ptr [si + 01Ah]
0x000000000000040d:  80 E2 07             and   dl, 7
0x0000000000000410:  30 E4                xor   ah, ah
0x0000000000000412:  C1 E2 0D             shl   dx, 0Dh
0x0000000000000415:  89 46 EC             mov   word ptr [bp - 014h], ax
0x0000000000000418:  89 56 FA             mov   word ptr [bp - 6], dx
0x000000000000041b:  85 C0                test  ax, ax
0x000000000000041d:  75 43                jne   0x462
0x000000000000041f:  8E C1                mov   es, cx
0x0000000000000421:  26 8B 45 0A          mov   ax, word ptr es:[di + 0Ah]
0x0000000000000425:  3B 46 FC             cmp   ax, word ptr [bp - 4]
0x0000000000000428:  7C 0A                jl    0x434
0x000000000000042a:  75 36                jne   0x462
0x000000000000042c:  26 8B 45 08          mov   ax, word ptr es:[di + 8]
0x0000000000000430:  39 D0                cmp   ax, dx
0x0000000000000432:  73 2E                jae   0x462
0x0000000000000434:  BB DC 07             mov   bx, 0x7dc
0x0000000000000437:  26 2B 55 08          sub   dx, word ptr es:[di + 8]
0x000000000000043b:  8B 46 FC             mov   ax, word ptr [bp - 4]
0x000000000000043e:  26 1B 45 0A          sbb   ax, word ptr es:[di + 0Ah]
0x0000000000000442:  29 17                sub   word ptr [bx], dx
0x0000000000000444:  19 47 02             sbb   word ptr [bx + 2], ax
0x0000000000000447:  31 C0                xor   ax, ax
0x0000000000000449:  2B 07                sub   ax, word ptr [bx]
0x000000000000044b:  BA 29 00             mov   dx, 0x29
0x000000000000044e:  1B 57 02             sbb   dx, word ptr [bx + 2]
0x0000000000000451:  BB E0 07             mov   bx, 0x7e0
0x0000000000000454:  B9 03 00             mov   cx, 3
0x0000000000000457:  D1 FA                sar   dx, 1
0x0000000000000459:  D1 D8                rcr   ax, 1
0x000000000000045b:  E2 FA                loop  0x457
0x000000000000045d:  89 07                mov   word ptr [bx], ax
0x000000000000045f:  89 57 02             mov   word ptr [bx + 2], dx
0x0000000000000462:  8B 44 16             mov   ax, word ptr [si + 016h]
0x0000000000000465:  8B 54 18             mov   dx, word ptr [si + 018h]
0x0000000000000468:  8E 46 FE             mov   es, word ptr [bp - 2]
0x000000000000046b:  26 01 45 08          add   word ptr es:[di + 8], ax
0x000000000000046f:  26 11 55 0A          adc   word ptr es:[di + 0Ah], dx
0x0000000000000473:  26 F6 45 15 40       test  byte ptr es:[di + 015h], 0x40
0x0000000000000478:  75 03                jne   0x47d
0x000000000000047a:  E9 DD 00             jmp   0x55a
0x000000000000047d:  83 7C 22 00          cmp   word ptr [si + 022h], 0
0x0000000000000481:  74 F7                je    0x47a
0x0000000000000483:  26 F6 45 17 01       test  byte ptr es:[di + 017h], 1
0x0000000000000488:  75 F0                jne   0x47a
0x000000000000048a:  26 F6 45 16 20       test  byte ptr es:[di + 016h], 020h
0x000000000000048f:  75 E9                jne   0x47a
0x0000000000000491:  6B 5C 22 18          imul  bx, word ptr [si + 022h], 018h
0x0000000000000495:  C7 46 E2 F5 6A       mov   word ptr [bp - 01Eh], MOBJPOSLIST_6800_SEGMENT
0x000000000000049a:  26 8B 45 06          mov   ax, word ptr es:[di + 6]
0x000000000000049e:  26 8B 55 04          mov   dx, word ptr es:[di + 4]
0x00000000000004a2:  89 46 E8             mov   word ptr [bp - 018h], ax
0x00000000000004a5:  8E 46 E2             mov   es, word ptr [bp - 01Eh]
0x00000000000004a8:  89 5E E6             mov   word ptr [bp - 01Ah], bx
0x00000000000004ab:  89 5E E4             mov   word ptr [bp - 01Ch], bx
0x00000000000004ae:  26 2B 57 04          sub   dx, word ptr es:[bx + 4]
0x00000000000004b2:  26 8B 47 06          mov   ax, word ptr es:[bx + 6]
0x00000000000004b6:  8E 46 FE             mov   es, word ptr [bp - 2]
0x00000000000004b9:  19 46 E8             sbb   word ptr [bp - 018h], ax
0x00000000000004bc:  26 8B 05             mov   ax, word ptr es:[di]
0x00000000000004bf:  26 8B 5D 02          mov   bx, word ptr es:[di + 2]
0x00000000000004c3:  8E 46 E2             mov   es, word ptr [bp - 01Eh]
0x00000000000004c6:  89 5E EA             mov   word ptr [bp - 016h], bx
0x00000000000004c9:  8B 5E E6             mov   bx, word ptr [bp - 01Ah]
0x00000000000004cc:  26 2B 07             sub   ax, word ptr es:[bx]
0x00000000000004cf:  8B 5E E4             mov   bx, word ptr [bp - 01Ch]
0x00000000000004d2:  26 8B 4F 02          mov   cx, word ptr es:[bx + 2]
0x00000000000004d6:  19 4E EA             sbb   word ptr [bp - 016h], cx
0x00000000000004d9:  89 D3                mov   bx, dx
0x00000000000004db:  8B 4E E8             mov   cx, word ptr [bp - 018h]
0x00000000000004de:  8B 56 EA             mov   dx, word ptr [bp - 016h]
0x00000000000004e1:  FF 1E A4 0C          lcall [0xca4]
0x00000000000004e5:  8B 5E E6             mov   bx, word ptr [bp - 01Ah]
0x00000000000004e8:  89 46 F2             mov   word ptr [bp - 0Eh], ax
0x00000000000004eb:  89 56 F4             mov   word ptr [bp - 0Ch], dx
0x00000000000004ee:  89 46 EE             mov   word ptr [bp - 012h], ax
0x00000000000004f1:  89 56 F0             mov   word ptr [bp - 010h], dx
0x00000000000004f4:  8B 44 0A             mov   ax, word ptr [si + 0Ah]
0x00000000000004f7:  8B 54 0C             mov   dx, word ptr [si + 0Ch]
0x00000000000004fa:  8E 46 E2             mov   es, word ptr [bp - 01Eh]
0x00000000000004fd:  D1 FA                sar   dx, 1
0x00000000000004ff:  D1 D8                rcr   ax, 1
0x0000000000000501:  26 8B 4F 08          mov   cx, word ptr es:[bx + 8]
0x0000000000000505:  8B 5E E4             mov   bx, word ptr [bp - 01Ch]
0x0000000000000508:  01 C1                add   cx, ax
0x000000000000050a:  26 8B 47 0A          mov   ax, word ptr es:[bx + 0Ah]
0x000000000000050e:  8E 46 FE             mov   es, word ptr [bp - 2]
0x0000000000000511:  11 D0                adc   ax, dx
0x0000000000000513:  89 CA                mov   dx, cx
0x0000000000000515:  26 2B 55 08          sub   dx, word ptr es:[di + 8]
0x0000000000000519:  26 1B 45 0A          sbb   ax, word ptr es:[di + 0Ah]
0x000000000000051d:  89 56 F6             mov   word ptr [bp - 0Ah], dx
0x0000000000000520:  89 46 F8             mov   word ptr [bp - 8], ax
0x0000000000000523:  85 C0                test  ax, ax
0x0000000000000525:  7D 03                jge   0x52a
0x0000000000000527:  E9 2D 01             jmp   0x657
0x000000000000052a:  8B 46 F8             mov   ax, word ptr [bp - 8]
0x000000000000052d:  85 C0                test  ax, ax
0x000000000000052f:  7F 08                jg    0x539
0x0000000000000531:  75 27                jne   0x55a
0x0000000000000533:  83 7E F6 00          cmp   word ptr [bp - 0Ah], 0
0x0000000000000537:  76 21                jbe   0x55a
0x0000000000000539:  8B 5E F6             mov   bx, word ptr [bp - 0Ah]
0x000000000000053c:  89 C1                mov   cx, ax
0x000000000000053e:  B8 03 00             mov   ax, 3
0x0000000000000541:  9A BF 5B 81 0A       call  FastMul16u32u_
0x0000000000000546:  3B 56 F0             cmp   dx, word ptr [bp - 010h]
0x0000000000000549:  7F 07                jg    0x552
0x000000000000054b:  75 0D                jne   0x55a
0x000000000000054d:  3B 46 EE             cmp   ax, word ptr [bp - 012h]
0x0000000000000550:  76 08                jbe   0x55a
0x0000000000000552:  8E 46 FE             mov   es, word ptr [bp - 2]
0x0000000000000555:  26 83 45 0A 04       add   word ptr es:[di + 0Ah], 4
0x000000000000055a:  8E 46 FE             mov   es, word ptr [bp - 2]
0x000000000000055d:  26 8B 45 0A          mov   ax, word ptr es:[di + 0Ah]
0x0000000000000561:  3B 46 FC             cmp   ax, word ptr [bp - 4]
0x0000000000000564:  7C 0E                jl    0x574
0x0000000000000566:  74 03                je    0x56b
0x0000000000000568:  E9 6D 01             jmp   0x6d8
0x000000000000056b:  26 8B 45 08          mov   ax, word ptr es:[di + 8]
0x000000000000056f:  3B 46 FA             cmp   ax, word ptr [bp - 6]
0x0000000000000572:  77 F4                ja    0x568
0x0000000000000574:  BB E5 00             mov   bx, 0xe5
0x0000000000000577:  80 3F 00             cmp   byte ptr [bx], 0
0x000000000000057a:  74 11                je    0x58d
0x000000000000057c:  26 F6 45 17 01       test  byte ptr es:[di + 017h], 1
0x0000000000000581:  74 0A                je    0x58d
0x0000000000000583:  F7 5C 18             neg   word ptr [si + 018h]
0x0000000000000586:  F7 5C 16             neg   word ptr [si + 016h]
0x0000000000000589:  83 5C 18 00          sbb   word ptr [si + 018h], 0
0x000000000000058d:  83 7C 18 00          cmp   word ptr [si + 018h], 0
0x0000000000000591:  7D 03                jge   0x596
0x0000000000000593:  E9 F2 00             jmp   0x688
0x0000000000000596:  8E 46 FE             mov   es, word ptr [bp - 2]
0x0000000000000599:  8B 46 FA             mov   ax, word ptr [bp - 6]
0x000000000000059c:  26 89 45 08          mov   word ptr es:[di + 8], ax
0x00000000000005a0:  8B 46 FC             mov   ax, word ptr [bp - 4]
0x00000000000005a3:  BB E5 00             mov   bx, 0xe5
0x00000000000005a6:  26 89 45 0A          mov   word ptr es:[di + 0Ah], ax
0x00000000000005aa:  80 3F 00             cmp   byte ptr [bx], 0
0x00000000000005ad:  75 11                jne   0x5c0
0x00000000000005af:  26 F6 45 17 01       test  byte ptr es:[di + 017h], 1
0x00000000000005b4:  74 0A                je    0x5c0
0x00000000000005b6:  F7 5C 18             neg   word ptr [si + 018h]
0x00000000000005b9:  F7 5C 16             neg   word ptr [si + 016h]
0x00000000000005bc:  83 5C 18 00          sbb   word ptr [si + 018h], 0
0x00000000000005c0:  8E 46 FE             mov   es, word ptr [bp - 2]
0x00000000000005c3:  26 F6 45 16 01       test  byte ptr es:[di + 016h], 1
0x00000000000005c8:  74 0A                je    0x5d4
0x00000000000005ca:  26 F6 45 15 10       test  byte ptr es:[di + 015h], 010h
0x00000000000005cf:  75 03                jne   0x5d4
0x00000000000005d1:  E9 F6 00             jmp   0x6ca
0x00000000000005d4:  8B 44 08             mov   ax, word ptr [si + 8]
0x00000000000005d7:  C1 F8 03             sar   ax, 3
0x00000000000005da:  89 46 FC             mov   word ptr [bp - 4], ax
0x00000000000005dd:  8B 44 08             mov   ax, word ptr [si + 8]
0x00000000000005e0:  25 07 00             and   ax, 7
0x00000000000005e3:  8E 46 FE             mov   es, word ptr [bp - 2]
0x00000000000005e6:  C1 E0 0D             shl   ax, 0Dh
0x00000000000005e9:  26 8B 55 08          mov   dx, word ptr es:[di + 8]
0x00000000000005ed:  89 46 FA             mov   word ptr [bp - 6], ax
0x00000000000005f0:  26 8B 45 0A          mov   ax, word ptr es:[di + 0Ah]
0x00000000000005f4:  03 54 0A             add   dx, word ptr [si + 0Ah]
0x00000000000005f7:  13 44 0C             adc   ax, word ptr [si + 0Ch]
0x00000000000005fa:  3B 46 FC             cmp   ax, word ptr [bp - 4]
0x00000000000005fd:  7F 07                jg    0x606
0x00000000000005ff:  75 51                jne   0x652
0x0000000000000601:  3B 56 FA             cmp   dx, word ptr [bp - 6]
0x0000000000000604:  76 4C                jbe   0x652
0x0000000000000606:  8B 44 18             mov   ax, word ptr [si + 018h]
0x0000000000000609:  85 C0                test  ax, ax
0x000000000000060b:  7F 08                jg    0x615
0x000000000000060d:  75 10                jne   0x61f
0x000000000000060f:  83 7C 16 00          cmp   word ptr [si + 016h], 0
0x0000000000000613:  76 0A                jbe   0x61f
0x0000000000000615:  C7 44 16 00 00       mov   word ptr [si + 016h], 0
0x000000000000061a:  C7 44 18 00 00       mov   word ptr [si + 018h], 0
0x000000000000061f:  8B 5E FA             mov   bx, word ptr [bp - 6]
0x0000000000000622:  8B 54 0A             mov   dx, word ptr [si + 0Ah]
0x0000000000000625:  8B 44 0C             mov   ax, word ptr [si + 0Ch]
0x0000000000000628:  8E 46 FE             mov   es, word ptr [bp - 2]
0x000000000000062b:  29 D3                sub   bx, dx
0x000000000000062d:  26 89 5D 08          mov   word ptr es:[di + 8], bx
0x0000000000000631:  8B 56 FC             mov   dx, word ptr [bp - 4]
0x0000000000000634:  19 C2                sbb   dx, ax
0x0000000000000636:  26 89 55 0A          mov   word ptr es:[di + 0Ah], dx
0x000000000000063a:  26 F6 45 17 01       test  byte ptr es:[di + 017h], 1
0x000000000000063f:  75 62                jne   0x6a3
0x0000000000000641:  8E 46 FE             mov   es, word ptr [bp - 2]
0x0000000000000644:  26 F6 45 16 01       test  byte ptr es:[di + 016h], 1
0x0000000000000649:  74 07                je    0x652
0x000000000000064b:  26 F6 45 15 10       test  byte ptr es:[di + 015h], 010h
0x0000000000000650:  74 53                je    0x6a5
0x0000000000000652:  C9                   leave 
0x0000000000000653:  5F                   pop   di
0x0000000000000654:  5E                   pop   si
0x0000000000000655:  5A                   pop   dx
0x0000000000000656:  C3                   ret   
0x0000000000000657:  89 D3                mov   bx, dx
0x0000000000000659:  89 C1                mov   cx, ax
0x000000000000065b:  B8 03 00             mov   ax, 3
0x000000000000065e:  9A BF 5B 81 0A       lcall 0xa81:0x5bbf
0x0000000000000663:  89 C3                mov   bx, ax
0x0000000000000665:  89 D0                mov   ax, dx
0x0000000000000667:  F7 D8                neg   ax
0x0000000000000669:  F7 DB                neg   bx
0x000000000000066b:  1D 00 00             sbb   ax, 0
0x000000000000066e:  3B 46 F4             cmp   ax, word ptr [bp - 0Ch]
0x0000000000000671:  7F 0A                jg    0x67d
0x0000000000000673:  74 03                je    0x678
0x0000000000000675:  E9 B2 FE             jmp   0x52a
0x0000000000000678:  3B 5E F2             cmp   bx, word ptr [bp - 0Eh]
0x000000000000067b:  76 F8                jbe   0x675
0x000000000000067d:  8E 46 FE             mov   es, word ptr [bp - 2]
0x0000000000000680:  26 83 6D 0A 04       sub   word ptr es:[di + 0Ah], 4
0x0000000000000685:  E9 D2 FE             jmp   0x55a
0x0000000000000688:  83 7E EC 00          cmp   word ptr [bp - 014h], 0
0x000000000000068c:  75 08                jne   0x696
0x000000000000068e:  8B 44 18             mov   ax, word ptr [si + 018h]
0x0000000000000691:  3D F8 FF             cmp   ax, 0xfff8
0x0000000000000694:  7C 11                jl    0x6a7
0x0000000000000696:  C7 44 16 00 00       mov   word ptr [si + 016h], 0
0x000000000000069b:  C7 44 18 00 00       mov   word ptr [si + 018h], 0
0x00000000000006a0:  E9 F3 FE             jmp   0x596
0x00000000000006a3:  EB 53                jmp   0x6f8
0x00000000000006a5:  EB 23                jmp   0x6ca
0x00000000000006a7:  8B 44 16             mov   ax, word ptr [si + 016h]
0x00000000000006aa:  8B 54 18             mov   dx, word ptr [si + 018h]
0x00000000000006ad:  BB E0 07             mov   bx, 0x7e0
0x00000000000006b0:  B9 03 00             mov   cx, 3
0x00000000000006b3:  D1 FA                sar   dx, 1
0x00000000000006b5:  D1 D8                rcr   ax, 1
0x00000000000006b7:  E2 FA                loop  0x6b3
0x00000000000006b9:  89 07                mov   word ptr [bx], ax
0x00000000000006bb:  89 57 02             mov   word ptr [bx + 2], dx
0x00000000000006be:  BA 22 00             mov   dx, 022h
0x00000000000006c1:  89 F0                mov   ax, si

0x00000000000006c4:  3E E8 4C 65          call  0x6c14
0x00000000000006c8:  EB CC                jmp   0x696
0x00000000000006ca:  89 FB                mov   bx, di
0x00000000000006cc:  8C C1                mov   cx, es
0x00000000000006ce:  89 F0                mov   ax, si
0x00000000000006d0:  E8 7D F8             call  0xff50
0x00000000000006d3:  C9                   leave 
0x00000000000006d4:  5F                   pop   di
0x00000000000006d5:  5E                   pop   si
0x00000000000006d6:  5A                   pop   dx
0x00000000000006d7:  C3                   ret   
0x00000000000006d8:  26 F6 45 15 02       test  byte ptr es:[di + 015h], 2
0x00000000000006dd:  74 03                je    0x6e2
0x00000000000006df:  E9 F2 FE             jmp   0x5d4
0x00000000000006e2:  8B 44 18             mov   ax, word ptr [si + 018h]
0x00000000000006e5:  0B 44 16             or    ax, word ptr [si + 016h]
0x00000000000006e8:  75 08                jne   0x6f2
0x00000000000006ea:  C7 44 18 FE FF       mov   word ptr [si + 018h], 0xfffe
0x00000000000006ef:  E9 E2 FE             jmp   0x5d4
0x00000000000006f2:  FF 4C 18             dec   word ptr [si + 018h]
0x00000000000006f5:  E9 DC FE             jmp   0x5d4
0x00000000000006f8:  F7 5C 18             neg   word ptr [si + 018h]
0x00000000000006fb:  F7 5C 16             neg   word ptr [si + 016h]
0x00000000000006fe:  83 5C 18 00          sbb   word ptr [si + 018h], 0
0x0000000000000702:  E9 3C FF             jmp   0x641



ENDP

@

END
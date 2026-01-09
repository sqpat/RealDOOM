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
INCLUDE states.inc
INCLUDE sound.inc
INSTRUCTION_SET_MACRO


; hack but oh well
P_SIGHT_STARTMARKER_ = 0 

EXTRN S_StartSound_:NEAR
EXTRN P_Random_:NEAR
EXTRN P_SpawnPuff_:NEAR
EXTRN P_SpawnMobj_:NEAR
EXTRN P_RemoveMobj_:NEAR
EXTRN P_CheckSight_:NEAR
EXTRN P_RadiusAttack_:NEAR
EXTRN A_BFGSpray_:NEAR
EXTRN P_AimLineAttack_:NEAR
EXTRN P_LineAttack_:NEAR
EXTRN P_AproxDistance_:NEAR
EXTRN P_LineOpening_:NEAR
EXTRN P_UnsetThingPosition_:NEAR
EXTRN P_SetThingPosition_:NEAR
EXTRN P_TryMove_:NEAR
EXTRN P_CheckPosition_:NEAR
EXTRN P_SpawnMissile_:NEAR
EXTRN P_TeleportMove_:NEAR
EXTRN P_BlockThingsIterator_:NEAR
EXTRN P_UseSpecialLine_:NEAR
EXTRN P_DamageMobj_:NEAR
EXTRN EV_DoDoor_:NEAR
EXTRN EV_DoFloor_:NEAR
EXTRN GetPainSound_:NEAR
EXTRN GetActiveSound_:NEAR
EXTRN GetMeleeState_:NEAR
EXTRN GetMissileState_:NEAR
EXTRN GetSpawnHealth_:NEAR
EXTRN GetSeeState_:NEAR
EXTRN GetRaiseState_:NEAR
EXTRN GetAttackSound_:NEAR
EXTRN FixedMulTrigNoShift_MapLocal_:NEAR
EXTRN FixedMulTrigSpeedNoShift_MapLocal_:NEAR

.DATA



.CODE



;FATSPREAD = (ANG90/8)
FATSPREADHIGH = 00800h
FATSPREADLOW  =  0h

TRACEANGLEHIGH = 0C00h
TRACEANGLELOW = 00000h

; todo constants.inc


DI_EAST = 0
DI_NORTHEAST = 1
DI_NORTH = 2
DI_NORTHWEST = 3
DI_WEST = 4
DI_SOUTHWEST = 5
DI_SOUTH = 6
DI_SOUTHEAST = 7
DI_NODIR = 8
NUMDIRS = 9
 

DIAG_DI_NORTHWEST = 0
DIAG_DI_NORTHEAST = 1
DIAG_DI_SOUTHWEST = 2 
DIAG_DI_SOUTHEAST = 3

FLOATSPEED_HIGHBITS = 4


; P_NewChaseDir related LUT.




SKULLSPEED_SMALL = 20


PROC    P_ENEMY_STARTMARKER_ 
PUBLIC  P_ENEMY_STARTMARKER_
ENDP

_opposite:
db  DI_WEST, DI_SOUTHWEST, DI_SOUTH, DI_SOUTHEAST
db  DI_EAST, DI_NORTHEAST, DI_NORTH, DI_NORTHWEST, DI_NODIR


_diags:
db  DI_NORTHWEST, DI_NORTHEAST, DI_SOUTHWEST, DI_SOUTHEAST

_movedirangles:
dw  00000h, 02000h, 04000h, 06000h, 08000h, 0A000h, 0C000h, 0E000h




PROC    P_RecursiveSound_ NEAR
PUBLIC  P_RecursiveSound_


PUSHA_NO_AX_MACRO
;dl holds soundblocks.
;dh will hold flags. dh is 0 at func start.

mov   cx, SECTORS_SEGMENT
mov   es, cx
mov   di, ax ; di stores secnum for the function.
xchg  ax, bx
SHIFT_MACRO shl   bx 4
mov   si, SECTOR_SOUNDTRAVERSED_SEGMENT
mov   ax, word ptr es:[bx + SECTOR_T.sec_validcount]

cmp   ax, word ptr ds:[_validcount_global]
jne   do_sound_recursion

;    if (soundsector->validcount == validcount_global && sector_soundtraversed[secnum] <= soundblocks+1) {
;		return;		// already flooded
;    }


mov   es, si
mov   al, byte ptr es:[di]
cbw
dec   ax ; instead of plus 1 to soundblocks do minus 12 to sector_soundtraversed
js    exit_p_recursive_sound_2 ; was definitely too small...
cmp   ax, dx
jg    do_sound_recursion
exit_p_recursive_sound_2:

POPA_NO_AX_MACRO
ret

do_sound_recursion:

;	soundsector->validcount = validcount_global;
mov   es, cx
mov   ax, word ptr ds:[_validcount_global]

mov   word ptr es:[bx + SECTOR_T.sec_validcount], ax

mov   cx, word ptr es:[bx + SECTOR_T.sec_linesoffset]
mov   bp, word ptr es:[bx + SECTOR_T.sec_linecount]  
add   bp, cx


;	sector_soundtraversed[secnum] = soundblocks+1;
mov   es, si
mov   ax, dx
inc   ax

; lol... i mean its 1 byte shorter
;mov   byte ptr es:[di], al
stosb
dec   di 



do_next_sector_line_loop:
mov   si, cx
sal   si, 1
mov   si, word ptr ds:[si + _linebuffer]  ; line number
mov   ax, LINEFLAGSLIST_SEGMENT
mov   es, ax

mov   dh, byte ptr es:[si] ; dh has flags.

test  dh, ML_TWOSIDED
je    continue_recursive_sound_loop

mov   ax, LINES_SEGMENT
mov   es, ax
SHIFT_MACRO shl   si 2  ; si has line number.
mov   ax, word ptr es:[si + LINE_T.l_sidenum + 2]    ; back side
SHIFT_MACRO shl   si 2  ; si shifted 4
mov   bx, LINES_PHYSICS_SEGMENT
mov   es, bx

push   dx  ; store params... no where else ot put it.
;mov   bx, word ptr es:[si + LINE_PHYSICS_T.lp_backsecnum]
;mov   dx, word ptr es:[si + LINE_PHYSICS_T.lp_frontsecnum]
les    dx, dword ptr es:[si + LINE_PHYSICS_T.lp_frontsecnum] ; backsecnum to es.
mov    bx, es

call   P_LineOpening_

pop    dx

;	if (lineopening.opentop <= lineopening.openbottom) {

mov   ax, word ptr ds:[_lineopening + LINE_OPENING_T.lo_opentop]
cmp   ax, word ptr ds:[_lineopening + LINE_OPENING_T.lo_openbottom]
jle   continue_recursive_sound_loop

mov   ax, LINES_PHYSICS_SEGMENT
mov   es, ax

;		if (check_physics->frontsecnum == secnum) {
;			othersecnum = check_physics->backsecnum;
;		} else {
;			othersecnum = check_physics->frontsecnum;
;		}


les   ax, dword ptr es:[si + LINE_PHYSICS_T.lp_frontsecnum] ; es gets backsecnum
cmp   ax, di
jne   found_othersecnum
mov   ax, es ; use backsecnum.
found_othersecnum:
; ax is othersecnum..

;		if (checkflags & ML_SOUNDBLOCK) {
;			if (!soundblocks) {
;				P_RecursiveSound(othersecnum, 1);


test  dh, ML_SOUNDBLOCK
je    recursive_call_soundblocks
cmp   dl, 0
jne   continue_recursive_sound_loop

mov   si, dx ; store old dl
mov   dx, 1
call  P_RecursiveSound_
mov   dx, si ; restore old values..
continue_recursive_sound_loop:
inc   cx
cmp   cx, bp
jl    do_next_sector_line_loop

exit_p_recursive_sound:
POPA_NO_AX_MACRO
ret   
recursive_call_soundblocks:
xor   dh, dh ; clear flags.
call  P_RecursiveSound_
jmp   continue_recursive_sound_loop


ENDP


PROC    P_NoiseAlert_ NEAR
PUBLIC  P_NoiseAlert_

inc   word ptr ds:[_validcount_global]
mov   bx, word ptr ds:[_playerMobj]
xor   dx, dx
mov   ax, word ptr ds:[bx + MOBJ_T.m_secnum]
call  P_RecursiveSound_
ret

ENDP

; return result in carry flag

PROC    P_CheckMeleeRange_ NEAR
PUBLIC  P_CheckMeleeRange_

; bp - 2    mobj (arg)
; bp - 4    targ (pl)
; bp - 6    


cmp   word ptr ds:[si + MOBJ_T.m_targetRef], 0
jne   do_check_meleerange
clc
ret   

do_check_meleerange:

PUSHA_NO_AX_OR_BP_MACRO

push  si  ; bp - 2


mov   di, bx
mov   cx, MOBJPOSLIST_6800_SEGMENT  ; might not be necessary. whatever.
mov   es, cx


mov   si, word ptr ds:[si + MOBJ_T.m_targetRef]

IF COMPISA GE COMPILE_186
    imul  bx, si, (SIZE THINKER_T)
    add   bx, (_thinkerlist + THINKER_T.t_data)
    imul  si, si, (SIZE MOBJ_POS_T)
ELSE
    mov   ax, (SIZE THINKER_T)
    mul   si
    add   ax, (_thinkerlist + THINKER_T.t_data)
    xchg  ax, bx
    mov   ax, (SIZE MOBJ_POS_T)
    mul   si
    xchg  ax, si

ENDIF


push  bx  ; bp - 4


mov   al, (SIZE MOBJINFO_T)
mul   byte ptr ds:[bx + MOBJ_T.m_mobjtype]
xchg  ax, bx
add   bx, (_mobjinfo + MOBJINFO_T.mobjinfo_radius)
xor   ax, ax
mov   al, byte ptr ds:[bx]
add   ax, (MELEERANGE - 20)

push  ax  ; bp - 6

push  es
pop   ds

lodsw 
sub   ax, word ptr ds:[di + MOBJ_POS_T.mp_x + 0]
xchg  ax, cx            ; cx holds onto x lo
lodsw 
sbb   ax, word ptr ds:[di + MOBJ_POS_T.mp_x + 2]
xchg  ax, dx            ; dx gets x hi
lodsw 
sub   ax, word ptr ds:[di + MOBJ_POS_T.mp_y + 0]
xchg  ax, bx            ; bx gets y lo
lodsw
sbb   ax, word ptr ds:[di + MOBJ_POS_T.mp_y + 2]
xchg  ax, cx            ; cx gets y hi. and ax gets x lo back

push  ss
pop   ds



;call  dword ptr ds:[_P_AproxDistance]

call   P_AproxDistance_

pop   ax  ; bp - 6
cmp   dx, ax
pop   dx  ; bp - 4
pop   ax  ; bp - 2
jnl   exit_check_meleerange_return_0
mov   bx,  di
lea   cx, [si - 8] ; because of lodsw increment above..
call  P_CheckSight_

jc    exit_check_meleerange_return_1
exit_check_meleerange_return_0:
clc  
exit_check_meleerange_return_1:
POPA_NO_AX_OR_BP_MACRO
ret  


ENDP


PROC    P_CheckMissileRange_ NEAR
PUBLIC  P_CheckMissileRange_


PUSHA_NO_AX_MACRO
xchg  di, si

IF COMPISA GE COMPILE_186
    imul  bx, word ptr ds:[di + MOBJ_T.m_targetRef], (SIZE THINKER_T)
ELSE
    mov   ax, (SIZE THINKER_T) 
    mul   word ptr ds:[di + MOBJ_T.m_targetRef]
    xchg  ax, bx
ENDIF

mov   cx, (SIZE THINKER_T)

; di is actor mobj
; si is actorpos
; bx is targ mobj

xor   dx, dx
mov   ax, bx
div   cx
; ax has index...

IF COMPISA GE COMPILE_186
    imul  cx, ax, (SIZE MOBJ_POS_T)
ELSE
    mov   dx, (SIZE MOBJ_POS_T)
    mul   dx
    xchg  ax, cx
ENDIF

mov   bp, cx

lea   dx, ds:[bx + (_thinkerlist + THINKER_T.t_data)]
mov   ax, di
mov   bx, si

call  P_CheckSight_

jnc   exit_checkmissilerange_return_0_and_pop
mov   ax, MOBJPOSLIST_6800_SEGMENT
mov   es, ax
test  byte ptr es:[si + MOBJ_POS_T.mp_flags1], MF_JUSTHIT
jne   just_hit_enemy
cmp   byte ptr ds:[di + MOBJ_T.m_reactiontime], 0
je    ready_to_attack

exit_checkmissilerange_return_0_and_pop:

;LEAVE_MACRO 
POPA_NO_AX_MACRO
clc
ret   
just_hit_enemy:
and   byte ptr es:[si + MOBJ_POS_T.mp_flags1], (NOT MF_JUSTHIT)
jmp   exit_checkmissilerange_return_1
ready_to_attack:
xor   ax, ax
mov   al, byte ptr ds:[di + MOBJ_T.m_mobjtype];
mov   di, bp ;  dont need actor ptr anymore. only use type ahead of here.
mov   bp, ax ;  store type.

;	disttemp.w = P_AproxDistance(actor_pos->x.w - actorTargetx.w,
;		actor_pos->y.w - actorTargety.w);

push  es
pop   ds

lodsw 
sub   ax, word ptr ds:[di + MOBJ_POS_T.mp_x + 0]
xchg  ax, cx            ; cx holds onto x lo
lodsw 
sbb   ax, word ptr ds:[di + MOBJ_POS_T.mp_x + 2]
xchg  ax, dx            ; dx gets x hi
lodsw 
sub   ax, word ptr ds:[di + MOBJ_POS_T.mp_y + 0]
xchg  ax, bx            ; bx gets y lo
lodsw
sbb   ax, word ptr ds:[di + MOBJ_POS_T.mp_y + 2]
xchg  ax, cx            ; cx gets y hi. and ax gets x lo back

push  ss
pop   ds

call   P_AproxDistance_

mov   ax, bp
sub   dx, 64

push  cs
call  GetMeleeState_

test  ax, ax
jne   has_melee

;		dist -= 128;	// no melee attack, so fire more

sub   dx, 128
has_melee:
xchg  ax, bp
cmp   al, MT_VILE
jne   missile_not_vile
cmp   dx, (14 * 64)
jg    exit_checkmissilerange_return_0
missile_not_vile:
cmp   al, MT_UNDEAD
jne   missile_not_revenant
cmp   dx, 196
jge   distance_not_too_close
jmp   exit_checkmissilerange_return_0
distance_not_too_close:
sar   dx, 1
missile_not_revenant:
cmp   al, MT_CYBORG
jne   missile_not_cyberdemon
missile_is_spider_skull_cyborg:
sar   dx, 1
missile_dist_200_check:
cmp   dx, 200
jle   missile_under_200_dont_cap
mov   dx, 200
missile_under_200_dont_cap:
cmp   al, MT_CYBORG
jne   not_cyborg_distance_check
cmp   dx, 160
jle   not_cyborg_distance_check
mov   dx, 160
not_cyborg_distance_check:
call  P_Random_
cmp   ax, dx
jge   exit_checkmissilerange_return_1
exit_checkmissilerange_return_0:
;LEAVE_MACRO 
POPA_NO_AX_MACRO
exit_pmove_ret_0_early:
clc
ret   
missile_not_cyberdemon:
cmp   al, MT_SPIDER
je    missile_is_spider_skull_cyborg
cmp   al, MT_SKULL
je    missile_is_spider_skull_cyborg
jmp   missile_dist_200_check
exit_checkmissilerange_return_1:
;LEAVE_MACRO 
POPA_NO_AX_MACRO
stc
ret   
ENDP



_p_move_dir_switch_table:

dw OFFSET switch_movedir_0 - OFFSET P_SIGHT_STARTMARKER_
dw OFFSET switch_movedir_1 - OFFSET P_SIGHT_STARTMARKER_
dw OFFSET switch_movedir_2 - OFFSET P_SIGHT_STARTMARKER_
dw OFFSET switch_movedir_3 - OFFSET P_SIGHT_STARTMARKER_
dw OFFSET switch_movedir_4 - OFFSET P_SIGHT_STARTMARKER_
dw OFFSET switch_movedir_5 - OFFSET P_SIGHT_STARTMARKER_
dw OFFSET switch_movedir_6 - OFFSET P_SIGHT_STARTMARKER_
dw OFFSET switch_movedir_7 - OFFSET P_SIGHT_STARTMARKER_




  
; return boolean in carry
PROC    P_Move_ NEAR
PUBLIC  P_Move_




; di/si have the offsets already

cmp   byte ptr ds:[si + MOBJ_T.m_movedir], DI_NODIR

je    exit_pmove_ret_0_early


do_pmove:

push  dx
push  si
push  di
push  bp
mov   bp, sp

mov   cx, MOBJPOSLIST_6800_SEGMENT
mov   es, cx
mov   al, (SIZE MOBJINFO_T) 
mul   byte ptr ds:[si + MOBJ_T.m_mobjtype]
xchg  ax, bx
xor   ax, ax
mov   al, byte ptr ds:[bx + (_mobjinfo + MOBJINFO_T.mobjinfo_speed)]
mov   bx, ax ; zero out bh
mov   bl, byte ptr ds:[si + MOBJ_T.m_movedir]

test  bl, 1             ; diagonals are odd and use the 47000 mult in ax/dx
je    skip_diag_mult
mov   dx, 47000
mul   dx
skip_diag_mult:

sal   bx, 1 ; jump word index...

; ax has speed, or dx:ax has 47000 * speed
; bx has jump lookup offset
; cx already MOBJPOSLIST_6800_SEGMENT
; trymove params will be pre-pushed here.

push  word ptr es:[di + MOBJ_POS_T.mp_y + 2] ; bp - 2
push  word ptr es:[di + MOBJ_POS_T.mp_y + 0] ; bp - 4
push  word ptr es:[di + MOBJ_POS_T.mp_x + 2] ; bp - 6
push  word ptr es:[di + MOBJ_POS_T.mp_x + 0] ; bp - 8


jmp   word ptr cs:[bx + OFFSET _p_move_dir_switch_table - OFFSET P_SIGHT_STARTMARKER_]


switch_movedir_0:
add   word ptr [bp - 6], ax

got_x_y_for_trymove: 


mov   bx, di
mov   ax, si
;mov   cx, MOBJPOSLIST_6800_SEGMENT ; this was set above.



call  P_TryMove_



mov   cx, MOBJPOSLIST_6800_SEGMENT
mov   es, cx

jc    try_ok
test  byte ptr es:[di + MOBJ_POS_T.mp_flags1 + 1], (MF_FLOAT SHR 8)
je    check_for_specials_hit_in_move
cmp   byte ptr ds:[_floatok], 0
je    check_for_specials_hit_in_move
; must adjust height.

;			SET_FIXED_UNION_FROM_SHORT_HEIGHT(temp, tmfloorz);
xor   ax, ax
mov   dx, word ptr ds:[_tmfloorz]
sar   dx, 1
rcr   ax, 1
sar   dx, 1
rcr   ax, 1
sar   dx, 1
rcr   ax, 1
mov   bx, FLOATSPEED_HIGHBITS
cmp   dx, word ptr es:[di + MOBJ_POS_T.mp_z + 2]
jg    add_floatspeed
jne   sub_floatspeed
cmp   ax, word ptr es:[di + MOBJ_POS_T.mp_z + 0]
jnbe  add_floatspeed
sub_floatspeed:
neg   bx    ; turn it into a subtract.
add_floatspeed:
add   word ptr es:[di + MOBJ_POS_T.mp_z + 2], bx

or    byte ptr es:[di + MOBJ_POS_T.mp_flags2], MF_INFLOAT
jmp   exit_p_move_return_1
try_ok:
and   byte ptr es:[di + MOBJ_POS_T.mp_flags2], (NOT MF_INFLOAT)
test  byte ptr es:[di + MOBJ_POS_T.mp_flags1 + 1], (MF_FLOAT SHR 8)
jne   exit_p_move_return_1
xor   ax, ax
mov   dx, word ptr ds:[si + MOBJ_T.m_floorz]
sar   dx, 1
rcr   ax, 1
sar   dx, 1
rcr   ax, 1
sar   dx, 1
rcr   ax, 1
mov   word ptr es:[di + MOBJ_POS_T.mp_z + 0], ax
mov   word ptr es:[di + MOBJ_POS_T.mp_z + 2], dx
exit_p_move_return_1:
stc
exit_p_move:
LEAVE_MACRO 
pop   di
pop   si
pop   dx
ret 

check_for_specials_hit_in_move:
cmp   word ptr ds:[_numspechit], 0
jne  specials_hit
exit_p_move_return_0:
clc
jmp   exit_p_move
specials_hit:
; specials hit..
mov   bx, (SIZE THINKER_T)
lea   ax, ds:[si - (_thinkerlist + THINKER_T.t_data)]
xor   dx, dx
;mov   bp, dx   ; bp is "good" boolean var (default to false)
push  dx
div   bx
mov   di, ax  ; store index in di...
mov   byte ptr ds:[si + MOBJ_T.m_movedir], DI_NODIR

do_next_spechit:
mov   bx, OFFSET _numspechit
dec   word ptr ds:[bx]  
js    end_spechit_loop
mov   bx, ds:[bx]
sal   bx, 1
mov   dx, word ptr ds:[bx + _spechit]
mov   cx, di
mov   ax, si
xor   bx, bx

call  P_UseSpecialLine_

jnc   do_next_spechit
mov   word ptr [bp - 2], 1
jmp   do_next_spechit
end_spechit_loop:
sar   word ptr [bp - 2], 1 ; set carry
jmp   exit_p_move
switch_movedir_1:
add   word ptr [bp - 8], ax
adc   word ptr [bp - 6], dx
add   word ptr [bp - 4], ax
adc   word ptr [bp - 2], dx
jmp   got_x_y_for_trymove
switch_movedir_2:
add   word ptr [bp - 2], ax
jmp   got_x_y_for_trymove
switch_movedir_3:
sub   word ptr [bp - 8], ax
sbb   word ptr [bp - 6], dx
add   word ptr [bp - 4], ax
adc   word ptr [bp - 2], dx
jmp   got_x_y_for_trymove
switch_movedir_4:
sub   word ptr [bp - 6], ax
jmp   got_x_y_for_trymove
switch_movedir_5:
sub   word ptr [bp - 8], ax
sbb   word ptr [bp - 6], dx
sub   word ptr [bp - 4], ax
sbb   word ptr [bp - 2], dx
jmp   got_x_y_for_trymove
switch_movedir_6:
sub   word ptr [bp - 2], ax
jmp   got_x_y_for_trymove
switch_movedir_7:
add   word ptr [bp - 8], ax
adc   word ptr [bp - 6], dx
sub   word ptr [bp - 4], ax
sbb   word ptr [bp - 2], dx
jmp   got_x_y_for_trymove

ENDP

; return boolean in carry

PROC    P_TryWalk_ NEAR
PUBLIC  P_TryWalk_

; si/di have the ptr offsets.

;todo change this to take si/di instead of ax/bx/cx... 


call  P_Move_
jnc   exit_try_walk  ; al 0
call  P_Random_
and   al, 15  
mov   word ptr ds:[si + MOBJ_T.m_movecount], ax
stc
exit_try_walk:
ret   

ENDP


PROC    P_NewChaseDir_ NEAR
PUBLIC  P_NewChaseDir_

; bp - 1   turnaround
; bp - 2   olddir
; bp - 3  d[2]
; bp - 4  d[1]

push  dx
push  si
push  di
push  bp
mov   bp, sp

; si is mobj
; di is mobjpos
mov   cx, MOBJPOSLIST_6800_SEGMENT

;	olddir = actor->movedir;
;	actorTarget = (mobj_t __near*)(&thinkerlist[actor->targetRef].data);
;	actorTarget_pos = GET_MOBJPOS_FROM_MOBJ(actorTarget);
;   turnaround=opposite[olddir];





mov   al, byte ptr ds:[si + MOBJ_T.m_movedir]
cbw
mov   bx, ax
mov   ah, byte ptr cs:[bx + _opposite - OFFSET P_SIGHT_STARTMARKER_] ; todo make cs?
push  ax  ; bp - 2. both movedir and opposite.
push  ax  ; garbage push instead of sub sp 2 to hold d[1] d[2]

mov   es, si  ; backup si

IF COMPISA GE COMPILE_186
    imul  si, word ptr ds:[si + MOBJ_T.m_targetRef], (SIZE MOBJ_POS_T)
ELSE
    mov  ax, (SIZE MOBJ_POS_T)
    mul  word ptr ds:[si + MOBJ_T.m_targetRef]
    xchg  ax, si
ENDIF

mov   ds, cx

;    deltax.w = actorTarget_pos->x.w - actorx.w;
;    deltay.w = actorTarget_pos->y.w - actory.w;

lodsw
sub   ax, word ptr ds:[di + MOBJ_POS_T.mp_x + 0]
xchg  ax, cx

lodsw
sbb   ax, word ptr ds:[di + MOBJ_POS_T.mp_x + 2]
xchg  ax, dx

lodsw
sub   ax, word ptr ds:[di + MOBJ_POS_T.mp_y + 0]
xchg  ax, bx

lodsw
sbb   ax, word ptr ds:[di + MOBJ_POS_T.mp_y + 2]
xchg  ax, cx  

; dx:ax deltax.
; cx:bx deltay

mov   si, es  ; si restored.

push  ss
pop   ds

;    if (deltax.w>10*FRACUNIT)
;		d[1]= DI_EAST;
;    else if (deltax.w<-10*FRACUNIT)
;		d[1]= DI_WEST;
;    else
;		d[1]=DI_NODIR;

cmp   dx, 10  ; 10 * fracbits
jg    set_d1_east
jne   compare_deltax_west
test  ax, ax
jne   set_d1_east
compare_deltax_west:
cmp   dx, -10  ; (neg 10 * fracunit)
jl    set_d1_west
mov   byte ptr [bp - 4], DI_NODIR
jmp   d1_is_set
set_d1_west:
mov   byte ptr [bp - 4], DI_WEST
jmp   d1_is_set


set_d1_east:
mov   byte ptr [bp - 4], DI_EAST



d1_is_set:

;    if (deltay.w<-10*FRACUNIT)
;		d[2]= DI_SOUTH;
;    else if (deltay.w>10*FRACUNIT)
;		d[2]= DI_NORTH;
;    else
;		d[2]=DI_NODIR;

cmp   cx, -10  ; -10 * fracbits
jge   compare_deltay_north
mov   byte ptr [bp - 3], DI_SOUTH
jmp   d2_is_set
compare_deltay_north:
cmp   cx, 10
jg    set_d2_north
jne    set_d2_nodir
compare_deltay_lobits:
test  bx, bx
je    set_d2_nodir
set_d2_north:
mov   byte ptr [bp - 3], DI_NORTH
jmp   d2_is_set
set_d2_nodir:
mov   byte ptr [bp - 3], DI_NODIR
d2_is_set:

cmp   byte ptr [bp - 4], DI_NODIR
je    no_direct_route
cmp   byte ptr [bp - 3], DI_NODIR
je    no_direct_route

;		actor->movedir = diags[((deltay.h.intbits<0)<<1)+(deltax.w>0)];
;		if (actor->movedir != turnaround && P_TryWalk(actor, actor_pos)) {

test  cx, cx    ; deltay.h.intbits<0
jge   deltay_not_negative
mov   si, 2     ; included shift
jmp   deltay_sign_set
deltay_not_negative:
xor   si, si
deltay_sign_set:

test  dx, dx
jg    deltax_positive
jne   movedir_set   ; dont add to si.
check_deltax_lobits:
test  ax, ax
je    movedir_set   ; dont add to si_
deltax_positive:
inc   si            ; add 1 to dir.
movedir_set:
; es has mobj ptr still.
; dx:ax, cx:bx are deltas. 
; di has mobjpos...
; si has movedir lookup.

; store stuff in case of trywalk call.  need these for potential labs check later.
push  ax  ; store deltax lo.


mov   al, byte ptr cs:[si + _diags - OFFSET P_SIGHT_STARTMARKER_]  ; do diags lookup. todo make cs table
mov   si, es    ; restore mobj ptr.

mov   byte ptr ds:[si + MOBJ_T.m_movedir], al
cmp   al, byte ptr [bp - 1]     ; turnaround check.

je    no_direct_route_restore_deltax_delta_y_1

push  bx
push  cx

call  P_TryWalk_
jnc   no_direct_route_restore_deltax_delta_y_2

jmp   exit_p_newchasedir
no_direct_route_restore_deltax_delta_y_2:

pop   cx
pop   bx

no_direct_route_restore_deltax_delta_y_1:

pop   ax 

no_direct_route:

; labs(deltay.w)>labs(deltax.w)

; dx:ax, cx:bx are deltas. 

or    cx, cx
jge   deltay_is_positive
neg   bx
adc   cx, 0
neg   cx
deltay_is_positive:

or    dx, dx
jge   delta_x_is_positive
neg   ax
adc   dx, 0
neg   dx
delta_x_is_positive:

cmp   cx, dx
jg    do_other_direction_and_inc_random
jl    try_random_check
; equal....
cmp   bx, ax
ja    do_other_direction_and_inc_random
;jmp   try_random_check
try_random_check:
call  P_Random_
cmp   al, 200
ja    do_other_direction
jmp   done_checking_for_direction_swap ; already incremented prndindex.



do_other_direction_and_inc_random:
inc   byte ptr ds:[_prndindex]  ; didnt call p_random but should have. just inc index.
do_other_direction:
mov   ax, word ptr [bp - 4]
xchg  al, ah
mov   word ptr [bp - 4], ax

done_checking_for_direction_swap:

;    if (d[1]==turnaround)
;		d[1]=DI_NODIR;
;    if (d[2]==turnaround)
;		d[2]=DI_NODIR;

mov   ax, word ptr [bp - 4]
cmp   al, byte ptr [bp - 1]
jne   d1_not_turnaround
mov   al, DI_NODIR
d1_not_turnaround:
cmp   ah, byte ptr [bp - 1]
jne   d2_not_turnaround
mov   ah, DI_NODIR
d2_not_turnaround:
; write back.
mov   word ptr [bp - 4], ax


mov   al, byte ptr [bp - 4]
cmp   al, DI_NODIR

je    dont_try_d1
mov   byte ptr ds:[si + MOBJ_T.m_movedir], al
call  P_TryWalk_
jc    exit_p_newchasedir

dont_try_d1:
mov   al, byte ptr [bp - 3]
cmp   al, DI_NODIR
je    dont_try_d2
mov   byte ptr ds:[si + MOBJ_T.m_movedir], al
call  P_TryWalk_
jc    exit_p_newchasedir

dont_try_d2:
mov   al, byte ptr [bp - 2]
cmp   al, DI_NODIR
je    dont_try_olddir
mov   byte ptr ds:[si + MOBJ_T.m_movedir], al
call  P_TryWalk_
jc    exit_p_newchasedir

dont_try_olddir:

mov   dh, byte ptr [bp - 1]  ; store this in dh

call  P_Random_
test  al, 1
je    loop_from_southeast

xor   dl, dl
loop_next_chase_try:
cmp   dl, dh
je    do_next_chase_try_loop
mov   byte ptr ds:[si + MOBJ_T.m_movedir], dl
call  P_TryWalk_
jc    exit_p_newchasedir

do_next_chase_try_loop:
inc   dl
cmp   dl, DI_SOUTHEAST
jle   loop_next_chase_try

check_turnaround:
cmp   dh, DI_NODIR
je    set_nodir_exit_p_newchasedir


mov   byte ptr ds:[si + MOBJ_T.m_movedir], dh
call  P_TryWalk_

jc    exit_p_newchasedir



set_nodir_exit_p_newchasedir:
mov   byte ptr ds:[si + MOBJ_T.m_movedir], DI_NODIR
exit_p_newchasedir:
LEAVE_MACRO 
pop   di
pop   si
pop   dx
ret   





loop_from_southeast:

mov   dl, DI_SOUTHEAST
loop_next_chase_try_from_southeast:
cmp   dl, dh
je   do_next_chase_try_loop_from_southeast
mov   byte ptr ds:[si + MOBJ_T.m_movedir], dl
call  P_TryWalk_
jc   exit_p_newchasedir
do_next_chase_try_loop_from_southeast:
dec   dl
jns   loop_next_chase_try_from_southeast

jmp   check_turnaround


ENDP


jump_to_exit_look_for_players_return_0:
and     byte ptr es:[si + MOBJ_POS_T.mp_flags2+1], ((NOT MF_LASTLOOK_1) SHR 8) ; undo the byte
player_dead_dont_look:
jmp     exit_look_for_players_return_0

PROC    P_LookForPlayers_ NEAR
PUBLIC  P_LookForPlayers_

; boolean __near P_LookForPlayers (mobj_t __near*	actor, boolean	allaround ) {




PUSHA_NO_AX_MACRO

mov   bp, dx        ; todo selfmodify below instead? or could this be recursively called
mov   di, ax



mov   bx, (SIZE THINKER_T)
sub   ax, (_thinkerlist + THINKER_T.t_data)
xor   dx, dx
div   bx



IF COMPISA GE COMPILE_186
    imul  si, ax, (SIZE MOBJ_POS_T)
ELSE
    mov  dx, (SIZE MOBJ_POS_T)
    mul  dx
    xchg ax, si
ENDIF

mov   ax, MOBJPOSLIST_6800_SEGMENT
mov   es, ax
; read about this hack in p_mobj.h MF_LASTLOOK_1 notes...
test  byte ptr es:[si + MOBJ_POS_T.mp_flags2+1], (MF_LASTLOOK_1 SHR 8)
jne   jump_to_exit_look_for_players_return_0

cmp   word ptr ds:[_player + PLAYER_T.player_health], 0
jng   player_dead_dont_look  

mov   cx, word ptr ds:[_playerMobj_pos]


mov   dx, word ptr ds:[_playerMobj]
mov   bx, si
mov   ax, di
call  P_CheckSight_
jnc   exit_look_for_players_return_0
cmp   bp, 0
je    check_angle_for_player
look_set_target_player:
push  ss
pop   ds  ; might have been unset in some paths.
mov   ax, word ptr ds:[_playerMobjRef]
mov   word ptr ds:[di + MOBJ_T.m_targetRef], ax
exit_look_for_players_return_1:
stc
POPA_NO_AX_MACRO
ret   
check_angle_for_player:
lds   bx, dword ptr ds:[_playerMobj_pos]

push  word ptr ds:[bx + MOBJ_POS_T.mp_y + 2]
push  word ptr ds:[bx + MOBJ_POS_T.mp_y + 0]
push  word ptr ds:[bx + MOBJ_POS_T.mp_x + 2]
push  word ptr ds:[bx + MOBJ_POS_T.mp_x + 0]
lodsw
xchg  ax, cx
lodsw
xchg  ax, dx
lodsw
xchg  ax, bx
lodsw
xchg  ax, cx
lea   si, [si - 8]  ; restore actor pos
push  ss
pop   ds

;call  R_PointToAngle2_
db 0FFh  ; lcall[addr]
db 01Eh  ;
dw _R_PointToAngle2_addr
mov   cx, MOBJPOSLIST_6800_SEGMENT
mov   ds, cx


sub   ax, word ptr ds:[si + MOBJ_POS_T.mp_angle+0]
sbb   dx, word ptr ds:[si + MOBJ_POS_T.mp_angle+2]
cmp   dx, ANG90_HIGHBITS
ja    lookforplayers_above_ang90
jne   look_set_target_player
test  cx, cx
jbe   look_set_target_player
lookforplayers_above_ang90:
cmp   dx, ANG270_HIGHBITS
jae   look_set_target_player

lodsw 
xchg  ax, cx
lodsw 
xchg  ax, dx
lodsw 
xchg  ax, bx
lodsw 
xchg  ax, cx

; done with actorpos. can clobber si

mov   si, word ptr ss:[_playerMobj_pos]


sub   ax, word ptr ds:[si + MOBJ_POS_T.mp_x + 0]
sbb   dx, word ptr ds:[si + MOBJ_POS_T.mp_x + 2]
sub   bx, word ptr ds:[si + MOBJ_POS_T.mp_y + 0]
sbb   cx, word ptr ds:[si + MOBJ_POS_T.mp_y + 2]

push  ss
pop   ds

call   P_AproxDistance_
cmp   dx, MELEERANGE
jnle  exit_look_for_players_return_0
jne   look_set_target_player
test  ax, ax
jbe   look_set_target_player
exit_look_for_players_return_0:
clc
POPA_NO_AX_MACRO
ret   

ENDP





PROC    A_KeenDie_ NEAR
PUBLIC  A_KeenDie_

push  bp
mov   bp, sp

;mov   si, ax
push  word ptr ds:[si + MOBJ_T.m_mobjtype]

mov   es, cx
mov   cx, (SIZE THINKER_T)
xor   dx, dx
lea   ax, ds:[si - (_thinkerlist + THINKER_T.t_data)]
div   cx

; inlined A_Fall_
and   byte ptr es:[bx + MOBJ_POS_T.mp_flags1], (NOT MF_SOLID)


mov   cx, ax
mov   ax, word ptr ds:[_thinkerlist + THINKER_T.t_next]

loop_next_thinker_keendie:

IF COMPISA GE COMPILE_186
    imul  bx, ax, (SIZE THINKER_T)
ELSE
    mov  dx, (SIZE THINKER_T)
    mul  dx
    xchg ax, bx
ENDIF

mov   dx, word ptr ds:[bx + _thinkerlist + THINKER_T.t_prevFunctype]
and   dx, TF_FUNCBITS
cmp   dx, TF_MOBJTHINKER_HIGHBITS

jne    not_thinker_skip_keencheck



cmp   ax, cx
je    not_thinker_skip_keencheck
mov   al, byte ptr ds:[bx + _thinkerlist + THINKER_T.t_data + MOBJ_T.m_mobjtype]
cmp   al, byte ptr [bp - 2]
jne   not_thinker_skip_keencheck
cmp   word ptr ds:[bx + _thinkerlist + THINKER_T.t_data + MOBJ_T.m_health], 0
jg    exit_keen_die
not_thinker_skip_keencheck:

mov   ax, word ptr ds:[bx + _thinkerlist + THINKER_T.t_next]
test  ax, ax
jne   loop_next_thinker_keendie

; done iteratng
mov   dx, DOOR_OPEN
mov   ax, TAG_666
call  EV_DoDoor_


exit_keen_die:
LEAVE_MACRO 
ret   


ENDP


PROC    A_Look_ NEAR
PUBLIC  A_Look_


;xchg  ax, si
mov   ax, SECTOR_SOUNDTRAVERSED_SEGMENT
mov   es, ax
xor   ax, ax
mov   di, word ptr ds:[si + MOBJ_T.m_secnum] 
mov   byte ptr ds:[si + MOBJ_T.m_threshold], al     ; actor->threshold = 0;	// any shot will wake up

;    targRef = sector_soundtraversed[actorsecnum] ? playerMobjRef : 0;

cmp   byte ptr es:[di], al
je    no_target
mov   dx, word ptr ds:[_playerMobj]
les   di, dword ptr ds:[_playerMobj_pos]


test  byte ptr es:[di + MOBJ_POS_T.mp_flags1], MF_SHOOTABLE
je    no_target
push  ds:[_playerMobjRef]
pop   word ptr ds:[si + MOBJ_T.m_targetRef]
test  byte ptr es:[bx + MOBJ_POS_T.mp_flags1], MF_AMBUSH
je    see_you
mov   cx, di
mov   ax, si

call  P_CheckSight_

jc    see_you

no_target:
mov   ax, si
xor   dx, dx
call  P_LookForPlayers_
jnc   exit_a_look

see_you:

; di is free here?
; bl is mobjtype

mov   bl, byte ptr ds:[si + MOBJ_T.m_mobjtype]
mov   al, (SIZE MOBJINFO_T)
mul   bl

xchg  ax, di

mov   al, byte ptr ds:[di + OFFSET _mobjinfo + MOBJINFO_T.mobjinfo_seesound]
test  al, al
je    no_seesound
cmp   al, SFX_POSIT1
jae   compare_seesound_1
just_use_seesound:
xchg  ax, dx  ; just use seesound.

check_mobjtype:
; dl should have sound.
mov   al, bl
cmp   al, MT_SPIDER
jne   compare_mobjtype_not_spider
found_boss_loud_mobjtype:
xor   ax, ax
do_seesound:

call  S_StartSound_
no_seesound:
mov   al, bl
xor   ah, ah

push  cs
call  GetSeeState_

xchg  ax, dx
xchg  ax, si
call  P_SetMobjState_

exit_a_look:
ret   
compare_seesound_1:
cmp   al, SFX_POSIT3
jbe   compare_seesound_2
cmp   al, sfx_bgsit2
ja    just_use_seesound

call  P_Random_
and   al, 1
add   al, SFX_BGSIT1
xchg  ax, dx
jmp   check_mobjtype
compare_seesound_2:
call  P_Random_

mov   dl, 3
div   dl
mov   dl, SFX_POSIT1
add   dl, ah ; modulo..
jmp   check_mobjtype
compare_mobjtype_not_spider:
cmp   al, MT_CYBORG
je    found_boss_loud_mobjtype
mov   ax, si  ; use actor sound source
jmp   do_seesound



ENDP

;todo make something fall into chase.

PROC    A_Chase_ NEAR
PUBLIC  A_Chase_

push  dx
push  si
push  di
push  bp

mov   bp, MOBJPOSLIST_6800_SEGMENT
;mov   si, ax
mov   di, bx

IF COMPISA GE COMPILE_186
    mov   ax, word ptr ds:[si + MOBJ_T.m_targetRef]
    imul  dx, ax, (SIZE THINKER_T)
    imul  cx, ax, (SIZE MOBJ_POS_T)
ELSE
    mov   bx, word ptr ds:[si + MOBJ_T.m_targetRef]
    mov   ax, (SIZE MOBJ_POS_T)
    mul   bx
    xchg  ax, cx
    mov   ax, (SIZE THINKER_T)
    mul   bx
    xchg  ax, dx
    xchg  ax, bx
    

ENDIF


add   dx, (OFFSET _thinkerlist + THINKER_T.t_data)
cmp   byte ptr ds:[si + MOBJ_T.m_reactiontime], 0
je    dont_dec_reaction
dec   byte ptr ds:[si + MOBJ_T.m_reactiontime]
dont_dec_reaction:
cmp   byte ptr ds:[si + MOBJ_T.m_threshold], 0

je    done_modifying_threshold
test  ax, ax
je    set_threshold_0

mov   bx, dx
cmp   word ptr ds:[bx + MOBJ_T.m_health], 0
jle   set_threshold_0
dec   byte ptr ds:[si + MOBJ_T.m_threshold]
jmp   done_modifying_threshold

set_threshold_0:
mov   byte ptr ds:[si + MOBJ_T.m_threshold], 0

done_modifying_threshold:
mov   es, bp

;    // turn towards movement direction if not there yet

cmp   byte ptr ds:[si + MOBJ_T.m_movedir], DI_NODIR
jae   done_with_dir_change
mov   byte ptr es:[di + MOBJ_POS_T.mp_angle + 2], 0
mov   word ptr es:[di + MOBJ_POS_T.mp_angle + 0], 0
and   byte ptr es:[di + MOBJ_POS_T.mp_angle+3], 0E0h
xor   ax, ax
mov   al, byte ptr ds:[si + MOBJ_T.m_movedir]
sal   ax, 1
xchg  ax, bx
mov   ax, word ptr es:[di + MOBJ_POS_T.mp_angle+2]
sub   ax, word ptr cs:[bx + OFFSET _movedirangles]
test  ax, ax
jnle  sub_dirchange

jge   done_with_dir_change
add   byte ptr es:[di + MOBJ_POS_T.mp_angle+3], (ANG90_HIGHBITS SHR 9)
jmp   done_with_dir_change

sub_dirchange:
sub   word ptr es:[di + MOBJ_POS_T.mp_angle+2], (ANG90_HIGHBITS / 2)
done_with_dir_change:

test  dx, dx
je    look_for_new_target

mov   bx, cx
test  byte ptr es:[bx + MOBJ_POS_T.mp_flags1], MF_SHOOTABLE
je    look_for_new_target

test  byte ptr es:[di + MOBJ_POS_T.mp_flags1], MF_JUSTATTACKED
je    check_for_melee_attack
and   byte ptr es:[di + MOBJ_POS_T.mp_flags1], (NOT MF_JUSTATTACKED)
cmp   byte ptr ds:[_gameskill], SK_NIGHTMARE
je    exit_a_chase
cmp   byte ptr ds:[_fastparm], 0
je    new_chase_dir_and_exit
exit_a_chase:
pop   bp
pop   di
pop   si
pop   dx
ret   

look_for_new_target:
mov   dx, 1
mov   ax, si
call  P_LookForPlayers_

jc    exit_a_chase
mov   al, (SIZE MOBJINFO_T)
mul   byte ptr ds:[si + MOBJ_T.m_mobjtype]
xchg  ax, si
mov   dx, word ptr ds:[si + _mobjinfo]
call  P_SetMobjState_

jmp   exit_a_chase
new_chase_dir_and_exit:

call  P_NewChaseDir_
jmp   exit_a_chase

check_for_melee_attack:
mov   al, byte ptr ds:[si + MOBJ_T.m_mobjtype]
xor   ah, ah

push  cs
call  GetMeleeState_


test  ax, ax
je    melee_check_failed_try_missile
mov   bx, di
call  P_CheckMeleeRange_
jnc   melee_check_failed_try_missile

do_melee_attack:
mov   al, byte ptr ds:[si + MOBJ_T.m_mobjtype]
xor   ah, ah
push  cs
call  GetAttackSound_

mov   dl, al
mov   ax, si

call  S_StartSound_

mov   al, byte ptr ds:[si + MOBJ_T.m_mobjtype]
xor   ah, ah

push  cs
call  GetMeleeState_

mov   dx, ax
mov   ax, si
call  P_SetMobjState_

exit_a_chase_2:
pop   bp
pop   di
pop   si
pop   dx
ret   

melee_check_failed_try_missile:
mov   al, byte ptr ds:[si + MOBJ_T.m_mobjtype]
xor   ah, ah
push  cs
call  GetMissileState_

test  ax, ax
je    nomissile
cmp   byte ptr ds:[_gameskill], SK_NIGHTMARE
jae   check_missile_range
cmp   byte ptr ds:[_fastparm], 0
jne   check_missile_range
cmp   word ptr ds:[si + MOBJ_T.m_movecount], 0
je    check_missile_range


nomissile:
dec   word ptr ds:[si + MOBJ_T.m_movecount]
js    dont_move_this_tic


call  P_Move_
jc   dont_change_dir
dont_move_this_tic:


call  P_NewChaseDir_
dont_change_dir:

xor   ax, ax
mov   al, byte ptr ds:[si + MOBJ_T.m_mobjtype]

push  cs
call  GetActiveSound_

mov   dl, al
test  al, al
je    exit_a_chase_2

call  P_Random_
cmp   al, 3
jae   exit_a_chase_2
xchg  ax, si

call  S_StartSound_

jmp   exit_a_chase_2




check_missile_range:

call  P_CheckMissileRange_

jnc    nomissile
mov   al, byte ptr ds:[si + MOBJ_T.m_mobjtype]
xor   ah, ah
push  cs
call  GetMissileState_

mov   dx, ax
mov   ax, si
call  P_SetMobjState_

mov   es, bp
or    byte ptr es:[di + MOBJ_POS_T.mp_flags1], MF_JUSTATTACKED
jmp   exit_a_chase

ENDP

; void __near A_FaceTarget (mobj_t __near* actor){	

PROC    A_FaceTarget_ NEAR
PUBLIC  A_FaceTarget_


PUSHA_NO_AX_OR_BP_MACRO

mov   bx, ax
cmp   word ptr ds:[bx + MOBJ_T.m_targetRef], 0
je    exit_a_facetarget
mov   cx, (SIZE THINKER_T)
sub   ax, (OFFSET _thinkerlist + THINKER_T.t_data)
xor   dx, dx
div   cx

IF COMPISA GE COMPILE_186
    imul  si, ax, (SIZE MOBJ_POS_T)
ELSE
    mov  dx, (SIZE MOBJ_POS_T)
    mul  dx
    xchg ax, si
ENDIF


IF COMPISA GE COMPILE_186
    imul  di, word ptr ds:[bx + MOBJ_T.m_targetRef], (SIZE MOBJ_POS_T)
ELSE
    mov  ax, (SIZE MOBJ_POS_T)
    mul  word ptr ds:[bx + MOBJ_T.m_targetRef]
    xchg ax, di
ENDIF


mov   cx, MOBJPOSLIST_6800_SEGMENT
mov   ds, cx
and   byte ptr ds:[si + MOBJ_POS_T.mp_flags1], (NOT MF_AMBUSH)




push  word ptr ds:[di + MOBJ_POS_T.mp_y + 2]
push  word ptr ds:[di + MOBJ_POS_T.mp_y + 0]
push  word ptr ds:[di + MOBJ_POS_T.mp_x + 2]
push  word ptr ds:[di + MOBJ_POS_T.mp_x + 0]

test  byte ptr ds:[di + MOBJ_POS_T.mp_flags2], MF_SHADOW
mov   di, 0
je    noshadow
inc   di
noshadow:

lodsw 
xchg  ax, cx
lodsw 
xchg  ax, dx
lodsw 
xchg  ax, bx
lodsw 
xchg  ax, cx

lea   si, [si - 8]

push  ss
pop   ds


;call  R_PointToAngle2_
db 0FFh  ; lcall[addr]
db 01Eh  ;
dw _R_PointToAngle2_addr

mov   cx, MOBJPOSLIST_6800_SEGMENT
mov   es, cx
mov   word ptr es:[si + MOBJ_POS_T.mp_angle + 0], ax
mov   word ptr es:[si + MOBJ_POS_T.mp_angle + 2], dx

test  di, di
je    exit_a_facetarget

call  P_Random_
xchg  ax, bx
call  P_Random_

sub   bx, ax
mov   es, cx
SHIFT_MACRO shl   bx 5
add   word ptr es:[si + MOBJ_POS_T.mp_angle + 2], bx
exit_a_facetarget:
POPA_NO_AX_OR_BP_MACRO

ret   


ENDP


PROC    A_PosAttack_ NEAR
PUBLIC  A_PosAttack_


;mov   si, ax
cmp   word ptr ds:[si + MOBJ_T.m_targetRef], 0
je    exit_a_posattack

do_a_posattack:

mov   bx, (SIZE THINKER_T)
sub   ax, (OFFSET _thinkerlist + THINKER_T.t_data)
xor   dx, dx
div   bx

IF COMPISA GE COMPILE_186
    imul  bx, ax, (SIZE MOBJ_POS_T)
ELSE
    mov  dx, (SIZE MOBJ_POS_T)
    mul  dx
    xchg ax, bx
ENDIF



mov   ax, si
call  A_FaceTarget_

mov   dx, MOBJPOSLIST_6800_SEGMENT
mov   es, dx
mov   cx, word ptr es:[bx + MOBJ_POS_T.mp_angle + 2]
mov   ax, si
SHIFT_MACRO shr   cx, 3
mov   bx, MISSILERANGE
mov   dx, cx

call  P_AimLineAttack_

mov   bx, ax
mov   di, dx
mov   dl, SFX_PISTOL
mov   ax, si
call  S_StartSound_


;    angle = MOD_FINE_ANGLE(angle + (((P_Random()-P_Random())<<(20-ANGLETOFINESHIFT))));
;    damage = ((P_Random()%5)+1)*3;

call  P_Random_
xchg  ax, dx
call  P_Random_
sub   dx, ax
sal   dx, 1
add   dx, cx ; angle into dx.
and   dh, (FINEMASK SHR 8)


call  P_Random_

mov   cl, 5
div   cl

mov   al, ah  ; mod 5
cbw     
inc   ax      ; plus 1

mov   cx, ax
shl   ax, 1
add   ax, cx ; times 3
push  ax ; damage
push  di ; slope hi
push  bx ; slope lo

xchg  ax, si
mov   bx, MISSILERANGE

call  P_LineAttack_

exit_a_posattack:
ret   

ENDP


PROC    A_SPosAttack_ NEAR
PUBLIC  A_SPosAttack_

push  bp
mov   bp, sp
mov   di, ax
cmp   word ptr ds:[di + MOBJ_T.m_targetRef], 0
je    exit_a_sposattack


do_a_sposattack:
mov   si, (SIZE THINKER_T)
sub   ax, (OFFSET _thinkerlist + THINKER_T.t_data)
xor   dx, dx
div   si

IF COMPISA GE COMPILE_186
    imul  si, ax, (SIZE MOBJ_POS_T)
ELSE
    mov  dx, (SIZE MOBJ_POS_T)
    mul  dx
    xchg ax, si
ENDIF


mov   dl, SFX_SHOTGN
mov   ax, di
call  S_StartSound_

mov   ax, di
call  A_FaceTarget_

;	bangle = actor_pos->angle.hu.intbits >> SHORTTOFINESHIFT;

mov   ax, MOBJPOSLIST_6800_SEGMENT
mov   es, ax
mov   dx, word ptr es:[si + MOBJ_POS_T.mp_angle + 2]
SHIFT_MACRO shr   dx 3

;    slope = P_AimLineAttack (actor, bangle, MISSILERANGE);

mov   bx, MISSILERANGE
mov   si, dx ; store bangle
mov   ax, di

call  P_AimLineAttack_

push  ax ; bp - 2
push  dx ; bp - 4
mov   cx, 3

do_next_shotgun_pellet:

;	angle = MOD_FINE_ANGLE((bangle + ((P_Random()-P_Random())<<(20-ANGLETOFINESHIFT))));

call  P_Random_

xchg  ax, dx
call  P_Random_

sub   dx, ax

sal   dx, 1
add   dx, si ; bangle
and   dx, FINEMASK

;		damage = ((P_Random()%5)+1)*3;
call  P_Random_

mov   bl, 5
div   bl
mov   al, ah
cbw
inc   ax
mov   bx, ax
sal   ax, 1
add   ax, bx ; ax * 3

; dx already set.
mov   bx, MISSILERANGE
push  ax
push  word ptr [bp - 4]
push  word ptr [bp - 2]
mov   ax, di
call  P_LineAttack_

loop  do_next_shotgun_pellet

exit_a_sposattack:
LEAVE_MACRO 
ret   

ENDP


PROC    A_CPosAttack_ NEAR
PUBLIC  A_CPosAttack_

;mov   si, ax
cmp   word ptr ds:[si + MOBJ_T.m_targetRef], 0
je    exit_a_cposattack

do_cposattack:

mov   bx, (SIZE THINKER_T)
sub   ax, (_thinkerlist + THINKER_T.t_data)
xor   dx, dx
div   bx

IF COMPISA GE COMPILE_186
    imul  bx, ax, (SIZE MOBJ_POS_T)
ELSE
    mov  dx, (SIZE MOBJ_POS_T)
    mul  dx
    xchg ax, bx
ENDIF

mov   dl, SFX_SHOTGN
mov   ax, si
call  S_StartSound_

mov   ax, si
call  A_FaceTarget_

mov   cx, MOBJPOSLIST_6800_SEGMENT
mov   es, cx
mov   cx, word ptr es:[bx + MOBJ_POS_T.mp_angle + 2]
mov   ax, si
SHIFT_MACRO shr   cx 3
mov   bx, MISSILERANGE
mov   dx, cx
call  P_AimLineAttack_

mov   di, ax
mov   bx, dx

call  P_Random_
xchg  ax, dx
call  P_Random_

sub   dx, ax
sal   dx, 1
add   dx, cx
and   dh, (FINEMASK SHR 8)

call  P_Random_

mov   cl, 5
div   cl
mov   al, ah
cbw
inc   ax
mov   cx, ax
sal   ax, 1
add   ax, cx

push  ax
push  bx
push  di


mov   ax, si
mov   bx, MISSILERANGE
call  P_LineAttack_

exit_a_cposattack:

ret   

ENDP


PROC    A_CPosRefire_ NEAR
PUBLIC  A_CPosRefire_

;mov   si, ax
call  A_FaceTarget_
call  P_Random_
cmp   al, 40
jb    exit_a_cposrefire
mov   dx, word ptr ds:[si + MOBJ_T.m_targetRef]
test  dx, dx
je    exit_a_cposrefire


IF COMPISA GE COMPILE_186
    imul  di, dx, (SIZE THINKER_T)
ELSE
    mov  ax, (SIZE THINKER_T)
    mul  dx
    xchg ax, di
ENDIF

add   di, (_thinkerlist + THINKER_T.t_data)
cmp   word ptr ds:[di + MOBJ_T.m_health], 0
jle   set_cgunner_seestate
mov   cx, (SIZE THINKER_T)
lea   ax, ds:[di - (_thinkerlist + THINKER_T.t_data)]
xor   dx, dx
div   cx

IF COMPISA GE COMPILE_186
    imul  cx, ax, (SIZE MOBJ_POS_T)
ELSE
    mov  dx, (SIZE MOBJ_POS_T)
    mul  dx
    xchg ax, cx
ENDIF

mov   dx, di
mov   ax, si
call  P_CheckSight_

jc    exit_a_cposrefire


set_cgunner_seestate:
; dumb thought. this is a hardcoded value as per engine right. Why call a function?
mov   al, byte ptr ds:[si + MOBJ_T.m_mobjtype]
xor   ah, ah
push  cs
call  GetSeeState_


mov   dx, ax
mov   ax, si
call  P_SetMobjState_

exit_a_cposrefire:
ret   

ENDP


PROC    A_SpidRefire_ NEAR
PUBLIC  A_SpidRefire_

;mov   si, ax
call  A_FaceTarget_

call  P_Random_
cmp   al, 10
jb    exit_a_spidrefire
mov   dx, word ptr ds:[si + MOBJ_T.m_targetRef]
test  dx, dx
je    exit_a_spidrefire

IF COMPISA GE COMPILE_186
    imul  di, dx, (SIZE THINKER_T)
ELSE
    mov  ax, (SIZE THINKER_T)
    mul  dx
    xchg ax, di
ENDIF

add   di, (_thinkerlist + THINKER_T.t_data)

cmp   word ptr ds:[di + MOBJ_T.m_health], 0
jle   set_spid_seestate
mov   cx, (SIZE THINKER_T)
lea   ax, ds:[di - (_thinkerlist + THINKER_T.t_data)]
xor   dx, dx
div   cx

IF COMPISA GE COMPILE_186
    imul  cx, ax, (SIZE MOBJ_POS_T)
ELSE
    mov  dx, (SIZE MOBJ_POS_T)
    mul  dx
    xchg ax, cx
ENDIF

mov   dx, di
mov   ax, si
call  P_CheckSight_

jc   exit_a_spidrefire

set_spid_seestate:
mov   al, byte ptr ds:[si + MOBJ_T.m_mobjtype]
xor   ah, ah

push  cs
call  GetSeeState_

mov   dx, ax
mov   ax, si
call  P_SetMobjState_

exit_a_spidrefire:
ret   

ENDP


PROC    A_BspiAttack_ NEAR
PUBLIC  A_BspiAttack_

;mov   si, ax
cmp   word ptr ds:[si + MOBJ_T.m_targetRef], 0
je    a_bspiexit
do_a_bspiattack:
call  A_FaceTarget_


IF COMPISA GE COMPILE_186
    imul  dx, word ptr ds:[si + MOBJ_T.m_targetRef], (SIZE THINKER_T)
    push  MT_ARACHPLAZ  
ELSE
    mov   ax, (SIZE THINKER_T)
    mul   word ptr ds:[si + MOBJ_T.m_targetRef]
    xchg  ax, dx
    mov   ax, MT_ARACHPLAZ
    push  ax
ENDIF

xchg  ax, si
add   dx, (_thinkerlist + THINKER_T.t_data)
call  P_SpawnMissile_
a_bspiexit:
ret   

ENDP


PROC    A_TroopAttack_ NEAR
PUBLIC  A_TroopAttack_

;mov   si, ax
cmp   word ptr ds:[si + MOBJ_T.m_targetRef], 0
je    a_troopattack_exit

do_a_troopattack:
mov   dx, bx
call  A_FaceTarget_
mov   bx, dx
call  P_CheckMeleeRange_
jnc    do_troop_missile
mov   dl, SFX_CLAW
mov   ax, si
call  S_StartSound_

call  P_Random_

;		damage = (P_Random()%8+1)*3;


and   al, 7
inc   ax

mov   cx, ax
sal   ax, 1
add   cx, ax  ; cx is damage.

IF COMPISA GE COMPILE_186
    imul  ax, word ptr ds:[si + MOBJ_T.m_targetRef], (SIZE THINKER_T)
ELSE
    mov   ax, (SIZE THINKER_T)
    mul   word ptr ds:[si + MOBJ_T.m_targetRef]
ENDIF

mov   bx, si
mov   dx, si
add   ax, (_thinkerlist + THINKER_T.t_data)

call  P_DamageMobj_

ret   

do_troop_missile:

IF COMPISA GE COMPILE_186
    imul  dx, word ptr ds:[si + MOBJ_T.m_targetRef], (SIZE THINKER_T)
    push  MT_TROOPSHOT 
ELSE
    mov   ax, (SIZE THINKER_T)
    mul   word ptr ds:[si + MOBJ_T.m_targetRef]
    xchg  ax, dx
    mov   ax, MT_TROOPSHOT
    push  ax
ENDIF

mov   ax, si
add   dx, (_thinkerlist + THINKER_T.t_data)
call  P_SpawnMissile_

a_troopattack_exit:
ret   

ENDP


PROC    A_SargAttack_ NEAR
PUBLIC  A_SargAttack_

;mov   si, ax
cmp   word ptr ds:[si + MOBJ_T.m_targetRef], 0
je    exit_a_sargattack

do_a_sargattack:
mov   dx, bx
call  A_FaceTarget_
mov   bx, dx
call  P_CheckMeleeRange_
jnc   exit_a_sargattack_full

;		damage = ((P_Random()%10)+1)*4;

call  P_Random_

mov   cl, 10
div   cl
mov   al, ah
cbw
inc   ax
SHIFT_MACRO sal  ax 2
xchg  ax, cx


IF COMPISA GE COMPILE_186
    imul  ax, word ptr ds:[si + MOBJ_T.m_targetRef], (SIZE THINKER_T)
ELSE
    mov   ax, (SIZE THINKER_T)
    mul   word ptr ds:[si + MOBJ_T.m_targetRef]
ENDIF

mov   bx, si
mov   dx, si

add   ax, (_thinkerlist + THINKER_T.t_data)
call  P_DamageMobj_

exit_a_sargattack_full:
exit_a_sargattack:
ret   

ENDP


PROC    A_HeadAttack_ NEAR
PUBLIC  A_HeadAttack_

;mov   si, ax
cmp   word ptr ds:[si + MOBJ_T.m_targetRef], 0
je    exit_head_attack
do_head_attack:
mov   dx, bx
call  A_FaceTarget_
mov   bx, dx
call  P_CheckMeleeRange_
jnc   do_head_missile
call  P_Random_

;		damage = (P_Random()%6+1)*10;


mov   bx, 00A06h  ; 10 hi 6 lo
div   bl

mov   al, ah
cbw
inc   ax
mul   bh
xchg  ax, cx


IF COMPISA GE COMPILE_186
    imul  ax, word ptr ds:[si + MOBJ_T.m_targetRef], (SIZE THINKER_T)
ELSE
    mov   ax, (SIZE THINKER_T)
    mul   word ptr ds:[si + MOBJ_T.m_targetRef]
ENDIF


mov   bx, si
mov   dx, si
add   ax, (_thinkerlist + THINKER_T.t_data)
call  P_DamageMobj_

ret   

do_head_missile:

IF COMPISA GE COMPILE_186
    imul  dx, word ptr ds:[si + MOBJ_T.m_targetRef], (SIZE THINKER_T)
    push  MT_HEADSHOT
ELSE
    mov   ax, (SIZE THINKER_T)
    mul   word ptr ds:[si + MOBJ_T.m_targetRef]
    xchg  ax, dx
    mov   ax, MT_HEADSHOT
    push  ax
ENDIF

mov   ax, si
add   dx, (_thinkerlist + THINKER_T.t_data)
call  P_SpawnMissile_

exit_head_attack:
ret   

ENDP


PROC    A_CyberAttack_ NEAR
PUBLIC  A_CyberAttack_


;mov   si, ax
cmp   word ptr ds:[si + MOBJ_T.m_targetRef], 0
je    exit_cyber_attack
call  A_FaceTarget_

IF COMPISA GE COMPILE_186
    imul  dx, word ptr ds:[si + MOBJ_T.m_targetRef], (SIZE THINKER_T)
    push  MT_ROCKET
ELSE
    mov   ax, (SIZE THINKER_T)
    mul   word ptr ds:[si + MOBJ_T.m_targetRef]
    xchg  ax, dx
    mov   ax, MT_ROCKET
    push  ax
ENDIF

mov   ax, si
add   dx, (_thinkerlist + THINKER_T.t_data)
call  P_SpawnMissile_

exit_cyber_attack:
ret   

ENDP


PROC    A_BruisAttack_ NEAR
PUBLIC  A_BruisAttack_

;mov   si, ax
cmp   word ptr ds:[si + MOBJ_T.m_targetRef], 0
je    exit_a_bruisattack

do_a_bruisattack:
; cx:bx here
call  P_CheckMeleeRange_

jnc    do_bruis_missile
mov   dl, SFX_CLAW
mov   ax, si
call  S_StartSound_

;		damage = (P_Random()%8+1)*10;


call  P_Random_
and   al, 7
inc   ax
mov   ah, 10
mul   ah
mov   cx, ax
IF COMPISA GE COMPILE_186
    imul  ax, word ptr ds:[si + MOBJ_T.m_targetRef], (SIZE THINKER_T)
ELSE
    mov   ax, (SIZE THINKER_T)
    mul   word ptr ds:[si + MOBJ_T.m_targetRef]
ENDIF

mov   bx, si
mov   dx, si
add   ax, (_thinkerlist + THINKER_T.t_data)
call  P_DamageMobj_

ret   

do_bruis_missile:

IF COMPISA GE COMPILE_186
    imul  dx, word ptr ds:[si + MOBJ_T.m_targetRef], (SIZE THINKER_T)
    push  MT_BRUISERSHOT
ELSE
    mov   ax, (SIZE THINKER_T)
    mul   word ptr ds:[si + MOBJ_T.m_targetRef]
    xchg  ax, dx
    mov   ax, MT_BRUISERSHOT
    push  ax
ENDIF

mov   ax, si
add   dx, (_thinkerlist + THINKER_T.t_data)
call  P_SpawnMissile_

exit_a_bruisattack:
ret   

ENDP


PROC    A_SkelMissile_ NEAR
PUBLIC  A_SkelMissile_

;mov   si, ax
cmp   word ptr ds:[si + MOBJ_T.m_targetRef], 0
je    exit_a_skelmissile

do_a_skelmissile:
mov   di, bx

call  A_FaceTarget_

mov   es, cx
add   word ptr es:[di + MOBJ_POS_T.mp_z + 2], 16

IF COMPISA GE COMPILE_186
    imul  dx, word ptr ds:[si + MOBJ_T.m_targetRef], (SIZE THINKER_T)
    push  MT_TRACER
ELSE
    mov   ax, (SIZE THINKER_T)
    mul   word ptr ds:[si + MOBJ_T.m_targetRef] 
    xchg  ax, dx
    mov   ax, MT_TRACER
    push  ax
ENDIF

mov   ax, si
add   dx, (_thinkerlist + THINKER_T.t_data)
call  P_SpawnMissile_

les   bx, dword ptr ds:[_setStateReturn_pos]
sub   word ptr es:[di + MOBJ_POS_T.mp_z + 2], 16

push  word ptr ds:[si + MOBJ_T.m_targetRef]
mov   si, word ptr ds:[_setStateReturn]
pop   word ptr ds:[si + MOBJ_T.m_tracerRef]



;	mo_pos->x.w += mo->momx.w;
;	mo_pos->y.w += mo->momy.w;

lea   si, [si + MOBJ_T.m_momx]
lodsw
add   word ptr es:[bx + MOBJ_POS_T.mp_x+0], ax
lodsw
adc   word ptr es:[bx + MOBJ_POS_T.mp_x+2], ax
lodsw
add   word ptr es:[bx + MOBJ_POS_T.mp_y+0], ax
lodsw
adc   word ptr es:[bx + MOBJ_POS_T.mp_y+2], ax


exit_a_skelmissile:
ret   

ENDP


exit_a_tracer_ret:
ret

PROC    A_Tracer_ NEAR
PUBLIC  A_Tracer_

test  byte ptr ds:[_gametic], 3
jne   exit_a_tracer_ret

do_a_tracer:

push  dx
push  si
push  di
push  bp
mov   bp, sp
push  ax  ; bp - 2
push  cx  ; bp - 4
push  bx  ; bp - 6

mov   ds, cx
mov   si, bx

;    P_SpawnPuff (actor_pos->x.w, actor_pos->y.w, actor_pos->z.w);

lodsw
xchg  ax, di                ; for ax
lodsw
xchg  ax, dx
lodsw
xchg  ax, bx
lodsw
xchg  ax, cx
lodsw                       ; for si
mov   si, word ptr ds:[si]  ; for di
xchg  ax, si                
xchg  ax, di

push  ss
pop   ds

call  P_SpawnPuff_


;	thRef = P_SpawnMobj (actor_pos->x.w-actor->momx.w,
;		actor_pos->y.w-actor->momy.w,
;		actor_pos->z.w, MT_SMOKE, -1);

IF COMPISA GE COMPILE_186
    push  -1 
    push  MT_SMOKE
ELSE
    mov   ax, -1 
    push  ax
    mov   ax, MT_SMOKE
    push  ax
ENDIF


lds   si, dword ptr [bp - 6]

lodsw 
xchg  ax, cx
lodsw 
xchg  ax, dx
lodsw 
xchg  ax, bx
lodsw 
xchg  ax, cx

push  word ptr ds:[si+2]
push  word ptr ds:[si]

push  ss
pop   ds
mov   di, word ptr [bp - 2]

sub   ax, word ptr ds:[di + MOBJ_T.m_momx + 0]
sbb   dx, word ptr ds:[di + MOBJ_T.m_momx + 2]

sub   bx, word ptr ds:[di + MOBJ_T.m_momy + 0]
sbb   cx, word ptr ds:[di + MOBJ_T.m_momy + 2]

call  P_SpawnMobj_

;    th->momz = FRACUNIT

mov   bx, word ptr ds:[_setStateReturn]
mov   word ptr ds:[bx + MOBJ_T.m_momz + 0], 0
mov   word ptr ds:[bx + MOBJ_T.m_momz + 2], 1

;    th->tics -= P_Random()&3;

call  P_Random_
and   al, 3
sub   byte ptr ds:[bx + MOBJ_T.m_tics], al

;    if (th->tics < 1 || th->tics > 240)
;		th->tics = 1;


mov   al, byte ptr ds:[bx + MOBJ_T.m_tics]
cmp   al, 1
jb    cap_tracer_tics_to_1
cmp   al, 240
jbe   dont_cap_tracer_tics
jmp   cap_tracer_tics_to_1


cap_tracer_tics_to_1:
mov   byte ptr ds:[bx + MOBJ_T.m_tics], 1
dont_cap_tracer_tics:

;	if (!actor->tracerRef) {
;		return;
;	}

mov   ax, word ptr ds:[di + MOBJ_T.m_tracerRef]
test  ax, ax
jne   valid_tracerref
jump_to_exit_a_tracer:
jmp   exit_a_tracer

valid_tracerref:

IF COMPISA GE COMPILE_186
    imul  bx, ax, (SIZE THINKER_T)
ELSE
    xchg ax, bx
    mov  ax, (SIZE THINKER_T)
    mul  bx
    xchg ax, bx
ENDIF


cmp   word ptr ds:[bx + _thinkerlist + THINKER_T.t_data + MOBJ_T.m_health], 0
jle   jump_to_exit_a_tracer

IF COMPISA GE COMPILE_186
    imul  bx, ax, (SIZE MOBJ_POS_T)
ELSE
    mov  dx, (SIZE MOBJ_POS_T)
    mul  dx
    xchg ax, bx
ENDIF

lds   si, dword ptr [bp - 6]

push  bx ; bp - 8  ; store destpos

push  word ptr ds:[bx + MOBJ_POS_T.mp_y + 2]
push  word ptr ds:[bx + MOBJ_POS_T.mp_y + 0]
push  word ptr ds:[bx + MOBJ_POS_T.mp_x + 2]
push  word ptr ds:[bx + MOBJ_POS_T.mp_x + 0]

lodsw 
xchg  ax, cx
lodsw 
xchg  ax, dx
lodsw 
xchg  ax, bx
lodsw 
xchg  ax, cx


push  ss
pop   ds

;call  R_PointToAngle2_
db 0FFh  ; lcall[addr]
db 01Eh  ;
dw _R_PointToAngle2_addr

lds   si, dword ptr [bp - 6]

;jmp   use_exact_angle  ; doesnt fix it?

cmp   dx, word ptr ds:[si + MOBJ_POS_T.mp_angle + 2]
jne   angle_not_exact_reaim
cmp   ax, word ptr ds:[si + MOBJ_POS_T.mp_angle + 0]
je    done_setting_tracer_angle
angle_not_exact_reaim:
mov   bx, ax
mov   cx, dx
sub   bx, word ptr ds:[si + MOBJ_POS_T.mp_angle + 0]
sbb   cx, word ptr ds:[si + MOBJ_POS_T.mp_angle + 2]
cmp   cx, 08000h
ja    subtract_trace_angle
jb    add_trace_angle
test  bx, bx
jne   subtract_trace_angle

add_trace_angle:
add   word ptr ds:[si + MOBJ_POS_T.mp_angle + 2], TRACEANGLEHIGH
sub   cx, TRACEANGLEHIGH
jc    use_exact_angle
jmp   done_setting_tracer_angle


subtract_trace_angle:

sub   word ptr ds:[si + MOBJ_POS_T.mp_angle + 2], TRACEANGLEHIGH
add   cx, TRACEANGLEHIGH
jnc   done_setting_tracer_angle
use_exact_angle:

mov   word ptr ds:[si + MOBJ_POS_T.mp_angle + 0], ax
mov   word ptr ds:[si + MOBJ_POS_T.mp_angle + 2], dx
done_setting_tracer_angle:

;fineexact = (actor_pos->angle.hu.intbits >> 1) & 0xFFFC;

push  ds
pop   es
push  ss
pop   ds

mov   bx, si
mov   si, di

call  A_SetMomxMomyFromAngleAndGetSpeedAngle_



pop   si ; bp - 8

lds   di, dword ptr [bp - 6]


lodsw 
xchg  ax, cx
lodsw 
xchg  ax, dx
lodsw 
xchg  ax, bx
lodsw 
xchg  ax, cx

sub   ax, word ptr ds:[di + MOBJ_POS_T.mp_x + 0]
sbb   dx, word ptr ds:[di + MOBJ_POS_T.mp_x + 2]
sub   bx, word ptr ds:[di + MOBJ_POS_T.mp_y + 0]
sbb   cx, word ptr ds:[di + MOBJ_POS_T.mp_y + 2]

push  ss
pop   ds

call   P_AproxDistance_

;	dist16 =  dist.h.intbits / (mobjinfo[actor->type].speed - 0x80);


mov   bx, word ptr [bp - 2]

mov   al, (SIZE MOBJINFO_T)
mul   byte ptr ds:[bx + MOBJ_T.m_mobjtype]
xchg  ax, bx

mov   bl, byte ptr ds:[bx + (_mobjinfo + MOBJINFO_T.mobjinfo_speed)]
xor   bh, bh
;xchg  ax, dx  ; intbits

sub   bx, 080h
cwd   
div   bx
cmp   ax, 1
jge   dont_cap_dist16_to_1
mov   ax, 1
dont_cap_dist16_to_1:

mov   bx, ax ; dist16

pop   di ; bp - 6
pop   ds ; bp - 4

lodsw ; dest x lo
xchg  ax, dx
lodsw ; dest x hi
add   ax, 40
xchg  ax, dx


sub   ax, word ptr ds:[di + MOBJ_POS_T.mp_z + 0]
sbb   dx, word ptr ds:[di + MOBJ_POS_T.mp_z + 2]

push  ss
pop   ds

;call   FastDiv3216u_
db 0FFh  ; lcall[addr]
db 01Eh  ;
dw _FastDiv3216u_addr

;    if (slope < actor->momz.w)
;		actor->momz.w -= FRACUNIT/8;
;    else
;		actor->momz.w += FRACUNIT/8;

mov   cx, MOBJPOSLIST_6800_SEGMENT
mov   ds, cx
pop   di ; bp - 2
cmp   dx, word ptr ds:[di + MOBJ_T.m_momz + 2]
jl    subtract_fracover8
jne   add_fracover8
cmp   ax, word ptr ds:[di + MOBJ_T.m_momz + 0]
jae   add_fracover8
subtract_fracover8:
sub   word ptr ds:[di + MOBJ_T.m_momz + 0], 02000h ; -fracunit / 8
sbb   word ptr ds:[di + MOBJ_T.m_momz + 2], 0
push  ss
pop   ds

exit_a_tracer:

LEAVE_MACRO 
pop   di
pop   si
pop   dx
ret   


add_fracover8:
add   word ptr ds:[di + MOBJ_T.m_momz + 0], 02000h ; fracunit / 8
adc   word ptr ds:[di + MOBJ_T.m_momz + 2], 0
push  ss
pop   ds

LEAVE_MACRO 
pop   di
pop   si
pop   dx
ret   


ENDP


PROC    A_SkelWhoosh_ NEAR
PUBLIC  A_SkelWhoosh_

;mov   si, ax
cmp   word ptr ds:[si + MOBJ_T.m_targetRef], 0
je    exit_skelwhoosh

do_a_skelwhoosh:
call  A_FaceTarget_
mov   dl, SFX_SKESWG
mov   ax, si
call  S_StartSound_

exit_skelwhoosh:
ret   

ENDP


PROC    A_SkelFist_ NEAR
PUBLIC  A_SkelFist_


;mov   si, ax
cmp   word ptr ds:[si + MOBJ_T.m_targetRef], 0
je    exit_a_skelfist

do_a_skelfist:
mov   dx, bx
call  A_FaceTarget_
mov   bx, dx
call  P_CheckMeleeRange_

jnc    exit_a_skelfist_full

;		damage = ((P_Random()%10)+1)*6;

call  P_Random_

mov   cl, 10
div   cl
mov   al, ah
cbw
inc   ax
mov   cl, 6
mul   cl
xchg  ax, cx

mov   ax, si
mov   dl, SFX_SKEPCH
call  S_StartSound_

IF COMPISA GE COMPILE_186
    imul  ax, word ptr ds:[si + MOBJ_T.m_targetRef], (SIZE THINKER_T)
ELSE
    mov   ax, (SIZE THINKER_T)
    mul   word ptr ds:[si + MOBJ_T.m_targetRef]
ENDIF

mov   bx, si
mov   dx, si
add   ax, (_thinkerlist + THINKER_T.t_data)
call  P_DamageMobj_

exit_a_skelfist_full:
exit_a_skelfist:
ret   

ENDP



PROC    PIT_VileCheck_ NEAR
PUBLIC  PIT_VileCheck_

mov   es, cx
test  byte ptr es:[bx + MOBJ_POS_T.mp_flags2], MF_CORPSE
je    exit_pit_vilecheck_return_1
push  si
mov   si, dx

cmp   byte ptr ds:[si + MOBJ_T.m_tics], 0FFh
je    do_vilecheck
pop   si
exit_pit_vilecheck_return_1:
stc
ret   

exit_pit_vilecheck_return_1_pop3:
pop   ax ; garbage
pop   di 
pop   si 
stc
ret   

do_vilecheck:

push  di

push  ax    ; pop later... 3 pops


mov   al, byte ptr ds:[si + MOBJ_T.m_mobjtype]
xor   ah, ah

push  cs
call  GetRaiseState_


test  ax, ax
je    exit_pit_vilecheck_return_1_pop3
mov   al, (SIZE MOBJINFO_T)
mul   byte ptr ds:[si + MOBJ_T.m_mobjtype]
xchg  ax, di

mov   ax, MOBJPOSLIST_6800_SEGMENT
mov   es, ax

mov   al, byte ptr ds:[di + _mobjinfo + MOBJINFO_T.mobjinfo_radius]
xor   ah, ah

mov   cl, byte ptr ds:[_mobjinfo + (MT_VILE * (SIZE MOBJINFO_T)) + MOBJINFO_T.mobjinfo_radius] ; todo hardcode...?

xor   ch, ch
add   cx, ax

;	if (labs(thing_pos->x.w - viletryx.w) > maxdist.w || labs(thing_pos->y.w - viletryy.w) > maxdist.w) {

mov   ax, word ptr es:[bx + MOBJ_POS_T.mp_x + 0]
mov   dx, word ptr es:[bx + MOBJ_POS_T.mp_x + 2]
sub   ax, word ptr ds:[_viletryx + 0]
sbb   dx, word ptr ds:[_viletryx + 2]
or    dx, dx
jge   skip_labs_x
neg   ax
adc   dx, 0
neg   dx
skip_labs_x:
cmp   dx, cx
jg    exit_pit_vilecheck_return_1_pop3
jne   check_vile_y
test  ax, ax
ja    exit_pit_vilecheck_return_1_pop3

check_vile_y:
mov   ax, word ptr es:[bx + MOBJ_POS_T.mp_y + 0]
mov   dx, word ptr es:[bx + MOBJ_POS_T.mp_y + 2]
sub   ax, word ptr ds:[_viletryy + 0]
sbb   dx, word ptr ds:[_viletryy + 2]
or    dx, dx
jge   skip_labs_y
neg   ax
adc   dx, 0
neg   dx
skip_labs_y:
cmp   dx, cx
jg    exit_pit_vilecheck_return_1_pop3
jne   do_further_check
test  ax, ax
ja    exit_pit_vilecheck_return_1_pop3
do_further_check:

pop   word ptr ds:[_corpsehitRef]
xor   ax, ax

;    thing->momx.w = thing->momy.w = 0;


mov   word ptr ds:[si + MOBJ_T.m_momy + 0], ax
mov   word ptr ds:[si + MOBJ_T.m_momy + 2], ax
mov   word ptr ds:[si + MOBJ_T.m_momx + 0], ax
mov   word ptr ds:[si + MOBJ_T.m_momx + 2], ax

;	thing->height.w <<= 2;
shl   word ptr ds:[si + MOBJ_T.m_height + 0], 1
rcl   word ptr ds:[si + MOBJ_T.m_height + 2], 1
shl   word ptr ds:[si + MOBJ_T.m_height + 0], 1
rcl   word ptr ds:[si + MOBJ_T.m_height + 2], 1

;    check = P_CheckPosition (thing, thing->secnum, thing_pos->x, thing_pos->y);

push  word ptr es:[bx + MOBJ_POS_T.mp_y + 2]
push  word ptr es:[bx + MOBJ_POS_T.mp_y + 0]
les   bx, dword ptr es:[bx + MOBJ_POS_T.mp_x + 0]
mov   cx, es
mov   dx, word ptr ds:[si + MOBJ_T.m_secnum]
mov   ax, si

call  P_CheckPosition_


;mov   al, 0
rcl   al, 1  ; todo hack for now... get carry result into al bit 0
;	thing->height.w >>= 2;


sar   word ptr ds:[si + MOBJ_T.m_height + 2], 1
rcr   word ptr ds:[si + MOBJ_T.m_height + 0], 1
sar   word ptr ds:[si + MOBJ_T.m_height + 2], 1
rcr   word ptr ds:[si + MOBJ_T.m_height + 0], 1
; al 1 if carry 0 if false
; return revers3

sar   al, 1
cmc
;test  al, al
;mov   al, 0
;jne   exit_pit_vilecheck_return_0
;stc
;exit_pit_vilecheck_return_0:
pop   di
pop   si
ret   


_vilechase_lookup_table:

dw OFFSET vile_switch_movedir_0 - OFFSET P_SIGHT_STARTMARKER_
dw OFFSET vile_switch_movedir_1 - OFFSET P_SIGHT_STARTMARKER_
dw OFFSET vile_switch_movedir_2 - OFFSET P_SIGHT_STARTMARKER_
dw OFFSET vile_switch_movedir_3 - OFFSET P_SIGHT_STARTMARKER_
dw OFFSET vile_switch_movedir_4 - OFFSET P_SIGHT_STARTMARKER_
dw OFFSET vile_switch_movedir_5 - OFFSET P_SIGHT_STARTMARKER_
dw OFFSET vile_switch_movedir_6 - OFFSET P_SIGHT_STARTMARKER_
dw OFFSET vile_switch_movedir_7 - OFFSET P_SIGHT_STARTMARKER_

ENDP


PROC    A_VileChase_ NEAR
PUBLIC  A_VileChase_


; bp - 2   ax arg
; bp - 4   bx arg
; bp - 6   mobjinfo pointer
; bp - 8     xh
; bp - 0Ah   yl

push  bp
mov   bp, sp
push  ax ; bp - 2
push  bx ; bp - 4


xchg  ax, si
cmp   byte ptr ds:[si + MOBJ_T.m_movedir], DI_NODIR
je    jump_to_do_chase_and_exit
mov   al, (SIZE MOBJINFO_T)
mul   byte ptr ds:[si + MOBJ_T.m_mobjtype]  ; 
push  ax   ; bp - 6
xchg  ax, di
xor   ax, ax


mov   al, byte ptr ds:[di + (_mobjinfo + MOBJINFO_T.mobjinfo_speed)]

mov   ds, cx
push  word ptr ds:[bx + MOBJ_POS_T.mp_x + 0]
push  word ptr ds:[bx + MOBJ_POS_T.mp_x + 2]
push  word ptr ds:[bx + MOBJ_POS_T.mp_y + 0]
push  word ptr ds:[bx + MOBJ_POS_T.mp_y + 2]

push  ss
pop   ds

pop   word ptr ds:[_viletryy + 2]
pop   word ptr ds:[_viletryy + 0]
pop   word ptr ds:[_viletryx + 2]
pop   word ptr ds:[_viletryx + 0]


;fixed_t	xspeed[8] = {FRACUNIT,47000,0,-47000,-FRACUNIT,-47000,0,47000};
;fixed_t yspeed[8] = {0,47000,FRACUNIT,47000,0,-47000,-FRACUNIT,-47000};

;	viletryx =
;	    actor->x + actor->info->speed*xspeed[actor->movedir];
;	viletryy =
;	    actor->y + actor->info->speed*yspeed[actor->movedir];


; would movsw save...?


mov   bl, byte ptr ds:[si + MOBJ_T.m_movedir]

cmp   bl, 7
ja    done_with_vile_switch_block

; movedir 7

test  bl, 1             ; diagonals are odd and use the 47000 mult in ax/dx
je    skip_diag_mult2
mov   dx, 47000
mul   dx
skip_diag_mult2:

xor   bh, bh
sal   bx, 1 ; jump word index...
mov   si, OFFSET _viletryx

jmp   word ptr cs:[bx + OFFSET _vilechase_lookup_table - OFFSET P_SIGHT_STARTMARKER_]
jump_to_do_chase_and_exit:
jmp   do_chase_and_exit
vile_switch_movedir_0:
add   word ptr ds:[si + 2], ax

done_with_vile_switch_block:

; si is _viletryx
lodsw
;xchg  ax, dx ; lo word not used!
lodsw

; si is now _viletryy.
; ax:dx viletryx

;		xl = (viletryx.w - coord.w - MAXRADIUS*2)>>MAPBLOCKSHIFT;
;		xh = (viletryx.w - coord.w + MAXRADIUS*2)>>MAPBLOCKSHIFT;

mov   di, (MAXRADIUSNONFRAC * 2)

sub   ax, word ptr ds:[_bmaporgx]

mov   bx, ax

sub   ax, di
add   bx, di

; shift right 7 + 16
rol   ax, 1
and   al, 1
xchg  al, ah
xchg  ax, bx  ; bx gets xl, ax gets copy back

rol   ax, 1
and   al, 1
xchg  al, ah


; in theory can check xl vs xh, fail  early here
push  ax  ; bp - 8 ; xh



;		yl = (viletryy.w - coord.w - MAXRADIUS*2)>>MAPBLOCKSHIFT;
;		yh = (viletryy.w - coord.w + MAXRADIUS*2)>>MAPBLOCKSHIFT;


lodsw           ; viletryy
lodsw
mov   si, bx ; si gets xl now

sub   ax, word ptr ds:[_bmaporgy]

mov   cx, ax

sub   ax, di
add   cx, di

; shift right 7 + 16
rol   ax, 1
and   al, 1
xchg  al, ah
xchg  ax, cx  ; cx gets yl, ax gets copy back

rol   ax, 1
and   al, 1
xchg  al, ah

; si has xl
; cx has yl

xchg  ax, di ; di gets yh

push  cx   ; bp - 0Ah

; si has xl
; bp - 8 has xh
; di has yh
; bp - 0Ah has yl  ; (for refreshing each inner loop repeat)


;		for (bx=xl ; bx<=xh ; bx++)
cmp   si, word ptr [bp - 8]
jg    do_chase_and_exit
loop_next_x_vile:
mov   cx, word ptr [bp - 0Ah]  ; reset each loop iter!
cmp   cx, di 
jg    done_with_vile_y_loop
loop_next_y_vile:
mov   bx, OFFSET PIT_VileCheck_ - OFFSET P_SIGHT_STARTMARKER_
mov   dx, cx   ; by
mov   ax, si   ; bx

call  P_BlockThingsIterator_

jnc   got_vile_target
inc   cx
cmp   cx, di
jle   loop_next_y_vile

done_with_vile_y_loop:
inc   si
cmp   si, word ptr [bp - 8]
jle   loop_next_x_vile

do_chase_and_exit:

mov   bx, word ptr [bp - 4]
mov   si, word ptr [bp - 2]
;call  A_Chase_

LEAVE_MACRO 
jmp   A_Chase_


got_vile_target:
mov   bx, word ptr [bp - 2]
mov   dx, word ptr ds:[bx + MOBJ_T.m_targetRef] ; tempref
push  word ptr ds:[_corpsehitRef]
pop   word ptr ds:[bx + MOBJ_T.m_targetRef]
mov   ax, bx
call  A_FaceTarget_

mov   ax, bx
mov   word ptr ds:[bx + MOBJ_T.m_targetRef], dx  ; put tempref back.
mov   dx, S_VILE_HEAL1

call  P_SetMobjState_


IF COMPISA GE COMPILE_186
    imul  si, word ptr ds:[_corpsehitRef], (SIZE THINKER_T)
    imul  bx, word ptr ds:[_corpsehitRef], (SIZE MOBJ_POS_T)
ELSE
    mov   ax, (SIZE THINKER_T)
    mov   cx, word ptr ds:[_corpsehitRef]
    mul   cx
    xchg  ax, si
    mov   ax, (SIZE MOBJ_POS_T)
    mul   cx
    xchg  ax, bx

ENDIF

add   si, (_thinkerlist + THINKER_T.t_data)
mov   dl, SFX_SLOP
mov   ax, si
call  S_StartSound_

xor   ax, ax
mov   al, byte ptr ds:[si + MOBJ_T.m_mobjtype]

push  cs
call  GetRaiseState_

xchg  ax, dx
mov   ax, si
call  P_SetMobjState_

; todo dont know if shift_macro works on this.
shl   word ptr ds:[si + MOBJ_T.m_height+2], 1
shl   word ptr ds:[si + MOBJ_T.m_height+2], 1

mov   cx, MOBJPOSLIST_6800_SEGMENT
mov   es, cx

mov   di, word ptr [bp - 6]

lea   ax, [di + _mobjinfo + MOBJINFO_T.mobjinfo_flags1]
lea   di, [bx + MOBJ_POS_T.mp_flags1]

xchg  ax, si   ; si gets mobjtpos dest
movsw ; copy flags1
movsw ; copy flags2

xchg  ax, si   ; si gets mobj ptr again

xor   ax, ax
mov   word ptr ds:[si + MOBJ_T.m_targetRef], ax

mov   al, byte ptr ds:[si + MOBJ_T.m_mobjtype]


push  cs
call  GetSpawnHealth_

mov   word ptr ds:[si + MOBJ_T.m_health], ax

LEAVE_MACRO 
ret   

vile_switch_movedir_1:
add   word ptr ds:[si + 0], ax
adc   word ptr ds:[si + 2], dx
add   word ptr ds:[si + 4], ax
adc   word ptr ds:[si + 6], dx
jmp   done_with_vile_switch_block
vile_switch_movedir_2:

add   word ptr ds:[si + 6], ax
jmp   done_with_vile_switch_block
vile_switch_movedir_3:
sub   word ptr ds:[si + 0], ax
sbb   word ptr ds:[si + 2], dx
add   word ptr ds:[si + 4], ax
adc   word ptr ds:[si + 6], dx
jmp   done_with_vile_switch_block
vile_switch_movedir_4:
sub   word ptr ds:[si + 0], bx
sbb   word ptr ds:[si + 2], ax
jmp   done_with_vile_switch_block
vile_switch_movedir_5:
sub   word ptr ds:[si], ax
sbb   word ptr ds:[si + 2], dx
sub   word ptr ds:[_viletryy], ax
sbb   word ptr ds:[si + 6], dx
jmp   done_with_vile_switch_block
vile_switch_movedir_6:
sub   word ptr ds:[si + 4], bx
sbb   word ptr ds:[si + 6], ax
jmp   done_with_vile_switch_block
vile_switch_movedir_7:
add   word ptr ds:[si + 0], ax
adc   word ptr ds:[si + 2], dx
sub   word ptr ds:[si + 4], ax
sbb   word ptr ds:[si + 6], dx
jmp   done_with_vile_switch_block



ENDP


PROC    A_VileStart_ NEAR
PUBLIC  A_VileStart_

mov   dl, SFX_VILATK
call  S_StartSound_

exit_a_fire_early:
ret   

ENDP


PROC    A_StartFire_ NEAR
PUBLIC  A_StartFire_


mov   dl, SFX_FLAMST
call  S_StartSound_

jmp   A_Fire_ 

ENDP


PROC    A_FireCrackle_ NEAR
PUBLIC  A_FireCrackle_


mov   dl, SFX_FLAME
call  S_StartSound_

ENDP

; fall thru A_FIRE


PROC    A_Fire_ NEAR
PUBLIC  A_Fire_


mov   ax, word ptr ds:[si + MOBJ_T.m_tracerRef]
test  ax, ax
je    exit_a_fire_early
do_a_fire:
push  bp
mov   bp, sp
push  cx ; bp - 2
push  si ; bp - 4  ; mobj
mov   di, bx

; todo move this logic into checksight

;; ax gets    targetRef thinker
; dx gets    dest (tracerref thinker)
; bx,        gets targetref mobjpos
; cx         destpos (tracerref mobjpos)

IF COMPISA GE COMPILE_186
    
    imul  dx, ax, (SIZE THINKER_T)
    imul  cx, ax, (SIZE MOBJ_POS_T)
    imul  ax, word ptr ds:[si + MOBJ_T.m_targetRef], (SIZE THINKER_T)
    imul  bx, word ptr ds:[si + MOBJ_T.m_targetRef], (SIZE MOBJ_POS_T)

ELSE
    xchg  ax, cx   ; cx stores index
    mov   ax, (SIZE MOBJ_POS_T)
    mul   word ptr ds:[si + MOBJ_T.m_targetRef]
    xchg  ax, bx  ; bx has what it needs
    mov   ax, (SIZE THINKER_T)
    mul   word ptr ds:[si + MOBJ_T.m_targetRef]
    xchg  ax, si   ; si has ax's contents
    mov   ax, (SIZE MOBJ_POS_T)
    mul   cx
    xchg  ax, cx   ; cx has what it needs, ax has index for next mult
    mov   dx, (SIZE THINKER_T)
    mul   dx
    xchg  ax, dx   ; dx has what it needs
    xchg  ax, si   ; ax has what it needs
ENDIF


mov   si, cx
add   dx, (_thinkerlist + THINKER_T.t_data)
add   ax, (_thinkerlist + THINKER_T.t_data)

call  P_CheckSight_

jnc   exit_a_fire
mov   es, word ptr [bp - 2]
mov   ax, word ptr es:[si + MOBJ_POS_T.mp_angle + 2]
shr   ax, 1
and   al, 0FCh
mov   dx, di
push  ax  ; bp - 6
mov   ax, word ptr [bp - 4]
call  P_UnsetThingPosition_

mov   cx, 24
xor   bx, bx
mov   dx, word ptr [bp - 6]
mov   ax, FINECOSINE_SEGMENT
call  FixedMulTrigNoShift_MapLocal_
mov   ds, word ptr [bp - 2]

add   ax, word ptr ds:[si + MOBJ_POS_T.mp_x + 0]
adc   dx, word ptr ds:[si + MOBJ_POS_T.mp_x + 2]
mov   word ptr ds:[di + MOBJ_POS_T.mp_x + 0], ax
mov   word ptr ds:[di + MOBJ_POS_T.mp_x + 2], dx

push  ss
pop   ds

mov   cx, 24
xor   bx, bx
mov   ax, FINESINE_SEGMENT
pop   dx  ; bp - 6

call  FixedMulTrigNoShift_MapLocal_
mov   ds, word ptr [bp - 2]

add   ax, word ptr ds:[si + MOBJ_POS_T.mp_y + 0]
adc   dx, word ptr ds:[si + MOBJ_POS_T.mp_y + 2]
mov   word ptr ds:[di + MOBJ_POS_T.mp_y + 0], ax
mov   word ptr ds:[di + MOBJ_POS_T.mp_y + 2], dx

push  word ptr ds:[si + MOBJ_POS_T.mp_z + 0]
push  word ptr ds:[si + MOBJ_POS_T.mp_z + 2]
pop   word ptr ds:[di + MOBJ_POS_T.mp_z + 2]
pop   word ptr ds:[di + MOBJ_POS_T.mp_z + 0]

push  ss
pop   ds

mov   bx, -1
pop   ax ; bp - 4
mov   dx, di

call      P_SetThingPosition_


exit_a_fire:
LEAVE_MACRO 
exit_vile_target:
ret   

ENDP


PROC    A_VileTarget_ NEAR
PUBLIC  A_VileTarget_

;mov   si, ax
cmp   word ptr ds:[si + MOBJ_T.m_targetRef], 0
je    exit_vile_target

do_vile_target:

call  A_FaceTarget_

IF COMPISA GE COMPILE_186
    mov   ax, word ptr ds:[si + MOBJ_T.m_targetRef]
    imul  di, ax, (SIZE THINKER_T)
    imul  bx, ax, (SIZE MOBJ_POS_T)
ELSE
    mov   ax, (SIZE THINKER_T)
    mul   word ptr ds:[si + MOBJ_T.m_targetRef]
    xchg  ax, di
    mov   ax, (SIZE MOBJ_POS_T)
    mul   word ptr ds:[si + MOBJ_T.m_targetRef]
    xchg  ax, bx

ENDIF

add   di, (_thinkerlist + THINKER_T.t_data)
push  word ptr ds:[di + MOBJ_T.m_secnum]
IF COMPISA GE COMPILE_186
    push  MT_FIRE
ELSE
    mov   ax, MT_FIRE
    push  ax
ENDIF

mov   ds, cx


push  word ptr ds:[bx + MOBJ_POS_T.mp_z + 2]
push  word ptr ds:[bx + MOBJ_POS_T.mp_z + 0]

les   ax, dword ptr ds:[bx + MOBJ_POS_T.mp_x + 0]
mov   dx, es
les   bx, dword ptr ds:[bx + MOBJ_POS_T.mp_y + 0]
mov   cx, es

push  ss
pop   ds

call  P_SpawnMobj_

mov   word ptr ds:[si + MOBJ_T.m_tracerRef], ax

mov   cx, (SIZE THINKER_T)
xor   dx, dx
lea   ax, ds:[si - (_thinkerlist + THINKER_T.t_data)]
div   cx

mov   di, word ptr ds:[_setStateReturn]

mov   word ptr ds:[di + MOBJ_T.m_targetRef], ax
push  word ptr ds:[si + MOBJ_T.m_targetRef]
pop   word ptr ds:[di + MOBJ_T.m_tracerRef]
les   bx, dword ptr ds:[_setStateReturn_pos]
mov   cx, es
mov   si, di
jmp   A_Fire_

_vile_momz_lookuptable:

dw vilemomz_ret_2
dw vilemomz_ret_10
dw vilemomz_ret_2
dw vilemomz_ret_10
dw vilemomz_ret_10
dw vilemomz_ret_1_high
dw vilemomz_ret_10
dw vilemomz_ret_10
dw vilemomz_ret_10

dw vilemomz_ret_163840
dw vilemomz_ret_163840
dw vilemomz_ret_163840
dw vilemomz_ret_1_high
dw vilemomz_ret_10
dw vilemomz_ret_1_high
dw vilemomz_ret_20

dw vilemomz_ret_1_high
dw vilemomz_ret_109226
dw vilemomz_ret_1_high
dw vilemomz_ret_163840

dw vilemomz_ret_10
dw vilemomz_ret_1_low
dw vilemomz_ret_1_low




ENDP

PROC    GetVileMomz_ NEAR
PUBLIC  GetVileMomz_


sub   al, 3
cmp   al, (MT_BOSSBRAIN - 3) 
ja    vilemomz_ret_10  ; default
xor   ah, ah
xchg  ax, bx
sal   bx, 1
xor   ax, ax
cwd
jmp   word ptr cs:[bx + _vile_momz_lookuptable - OFFSET P_SIGHT_STARTMARKER_]
vilemomz_ret_2:
inc   dx
inc   dx
ret   
vilemomz_ret_20:
mov   dx, 20
ret   
vilemomz_ret_163840:
mov   ax, 08000h
jmp   vilemomz_ret_2  ; dx 2 and pop bx and ret.
vilemomz_ret_109226:
mov   ax, 0AAAAh
inc   dx
ret   
vilemomz_ret_1_high:
inc   dx
ret   
vilemomz_ret_1_low:
inc   ax
ret   
vilemomz_ret_10:
mov   dx, 10
ret   

ENDP


PROC    A_VileAttack_ NEAR
PUBLIC  A_VileAttack_

; bp - 2   (bx) mobjpos offset
; bp - 4   (cx) MOBJPOSLIST_6800_SEGMENT
; bp - 6   actorTarget_pos
; bp - 8   angle
; bp - 0Ah fire (mobj)

push  bp
mov   bp, sp

;mov   si, ax
push  bx ; bp - 2
push  cx ; bp - 4
mov   ax, word ptr ds:[si + MOBJ_T.m_targetRef]
test  ax, ax
jne   do_vile_attack
exit_vile_attack:
LEAVE_MACRO 
ret   
do_vile_attack:

IF COMPISA GE COMPILE_186
    imul  cx, ax, (SIZE MOBJ_POS_T)
ELSE
    mov   cx, (SIZE MOBJ_POS_T)
    mul   cx
    xchg  ax, cx
ENDIF
mov   ax, si
call  A_FaceTarget_
IF COMPISA GE COMPILE_186
    imul  di, word ptr ds:[si + MOBJ_T.m_targetRef], (SIZE THINKER_T)
ELSE
    mov   ax, (SIZE THINKER_T)
    mul   word ptr ds:[si + MOBJ_T.m_targetRef]
    xchg  ax, di
ENDIF

push  cx  ; bp - 6
add   di, (_thinkerlist + THINKER_T.t_data)
mov   ax, si
mov   dx, di


call  P_CheckSight_

jnc   exit_vile_attack
mov   dl, SFX_BAREXP
mov   ax, si
call  S_StartSound_

mov   ax, di
mov   cx, 20
mov   bx, si
mov   dx, si

call  P_DamageMobj_


mov   bx, word ptr [bp - 2]
mov   es, word ptr [bp - 4]
mov   ax, word ptr es:[bx + MOBJ_POS_T.mp_angle + 2]
shr   ax, 1
and   al, 0FCh
push  ax  ; bp - 8
mov   al, byte ptr ds:[di + MOBJ_T.m_mobjtype]
cbw  
mov   bx, word ptr ds:[si + MOBJ_T.m_tracerRef]
mov   cx, bx  ; back up so bx can be clobbered.
call  GetVileMomz_
mov   word ptr ds:[di + MOBJ_T.m_momz + 0], ax
mov   word ptr ds:[di + MOBJ_T.m_momz + 2], dx
test  cx, cx
je    exit_vile_attack

IF COMPISA GE COMPILE_186
    imul  ax, cx, (SIZE THINKER_T)
    imul  di, cx, (SIZE MOBJ_POS_T)
ELSE
    mov   ax, (SIZE MOBJ_POS_T)
    mul   cx
    xchg  ax, di
    mov   ax, (SIZE THINKER_T)
    mul   cx
ENDIF

mov   cx, 24
add   ax, (_thinkerlist + THINKER_T.t_data)
mov   dx, word ptr [bp - 8]
push  ax  ; bp - 0Ah
mov   ax, FINECOSINE_SEGMENT
xor   bx, bx

call  FixedMulTrigNoShift_MapLocal_
les   bx, dword ptr [bp - 6]

xchg  ax, cx
mov   ax, word ptr es:[bx + MOBJ_POS_T.mp_x + 0]
sub   ax, cx
mov   word ptr es:[di + MOBJ_POS_T.mp_x + 0], ax
mov   ax, word ptr es:[bx + MOBJ_POS_T.mp_x + 2]
sbb   ax, dx
mov   word ptr es:[di + MOBJ_POS_T.mp_x + 2], ax


mov   cx, 24
mov   dx, word ptr [bp - 8]
xor   bx, bx
mov   ax, FINESINE_SEGMENT
call  FixedMulTrigNoShift_MapLocal_
les   bx, dword ptr [bp - 6]

xchg  ax, cx
mov   ax, word ptr es:[bx + MOBJ_POS_T.mp_y + 0]
sub   ax, cx
mov   word ptr es:[di + MOBJ_POS_T.mp_y + 0], ax
mov   ax, word ptr es:[bx + MOBJ_POS_T.mp_y + 2]
sbb   ax, dx
mov   word ptr es:[di + MOBJ_POS_T.mp_y + 2], ax



mov   bx, si
sub   dx, cx
mov   cx, 70
mov   dx, di
pop   ax ; bp - 0Ah fire mobj

call  P_RadiusAttack_

LEAVE_MACRO 
ret   

ENDP


PROC    A_FatRaise_ NEAR
PUBLIC  A_FatRaise_


call  A_FaceTarget_
mov   dl, SFX_MANATK
xchg  ax, si  ; si has ax value
call  S_StartSound_
ret   

ENDP


PROC    A_FatAttack3_ NEAR
PUBLIC  A_FatAttack3_


mov   di, ax
call  A_FaceTarget_

push  bx  ; store ptr...
mov   si,  -(FATSPREADHIGH/2)
call  A_DoFatShot_

pop   bx  ; restore ptr
mov   si, FATSPREADHIGH/2
;call  A_DoFatShot_

; fall thru

; di has actor ptr
; cx has MOBJPOSLIST_6800_SEGMENT
; bx has actor pos
; dx target actor
; ax free...
; si carries angle

PROC    A_DoFatShot_ NEAR


IF COMPISA GE COMPILE_186
    imul  dx, word ptr ds:[di + MOBJ_T.m_targetRef], (SIZE THINKER_T)
    add   dx, (_thinkerlist + THINKER_T.t_data)
ELSE
    
    mov   ax, (SIZE THINKER_T)
    mul   word ptr ds:[di + MOBJ_T.m_targetRef]
    xchg  ax, dx
    add   dx, (_thinkerlist + THINKER_T.t_data)
ENDIF


IF COMPISA GE COMPILE_186
    push  MT_FATSHOT
ELSE
    mov   ax, MT_FATSHOT
    push  ax
ENDIF
mov   cx, MOBJPOSLIST_6800_SEGMENT

mov   ax, di
call  P_SpawnMissile_

test  si, si
je    no_angle_mod

les   bx, dword ptr ds:[_setStateReturn_pos]

add   word ptr es:[bx + MOBJ_POS_T.mp_angle + 2], si  ; add angle

mov   si, word ptr ds:[_setStateReturn]


;call  A_SetMomxMomyFromAngleAndGetSpeedAngle_
; INLINED 
ENDP
PROC  A_SetMomxMomyFromAngleAndGetSpeedAngle_ NEAR

; es:bx is thing
; si is mobj ptr

mov   al, (SIZE MOBJINFO_T)
mul   byte ptr ds:[si + MOBJ_T.m_mobjtype]


mov   dx, word ptr es:[bx + MOBJ_POS_T.mp_angle + 2]
xchg  ax, bx

mov   bl, byte ptr ds:[bx + (_mobjinfo + MOBJINFO_T.mobjinfo_speed)]

ENDP
; fall thru

PROC  A_SetMomxMomyFromAngle_  NEAR

; bx has speed component.
; dx has unshifted angle
; si has mobj ptr

shr   dx, 1
and   dx, 0FFFCh

push  dx  ; angle
push  bx  ; speed
mov   ax, FINECOSINE_SEGMENT

call FixedMulTrigSpeedNoShift_MapLocal_

mov   word ptr ds:[si + MOBJ_T.m_momx + 0], ax
mov   word ptr ds:[si + MOBJ_T.m_momx + 2], dx


pop   bx  ; speed
pop   dx  ; angle
mov   ax, FINESINE_SEGMENT

call FixedMulTrigSpeedNoShift_MapLocal_
mov   word ptr ds:[si + MOBJ_T.m_momy + 0], ax
mov   word ptr ds:[si + MOBJ_T.m_momy + 2], dx

no_angle_mod:
ret

ENDP


PROC    A_FatAttack1_ NEAR
PUBLIC  A_FatAttack1_


mov   di, ax
call  A_FaceTarget_
mov   es, cx
add   word ptr es:[bx + MOBJ_POS_T.mp_angle + 2], FATSPREADHIGH

push  bx  ; store ptr...
xor   si, si  ; 0 angle  
call  A_DoFatShot_

pop   bx  ; restore ptr
mov   si, FATSPREADHIGH
call  A_DoFatShot_

ret   

ENDP


PROC    A_FatAttack2_ NEAR
PUBLIC  A_FatAttack2_


mov   di, ax
call  A_FaceTarget_
mov   es, cx
add   word ptr es:[bx + MOBJ_POS_T.mp_angle + 2], -FATSPREADHIGH

push  bx  ; store ptr...
xor   si, si  ; 0 angle  
call  A_DoFatShot_

pop   bx  ; restore ptr
mov   si, -(2*FATSPREADHIGH)
call  A_DoFatShot_
exit_skull_attack_early:

ret

ENDP




ENDP

; bp - 2 destpos
; bp - 4 dest
; bp - 6 ang hibits

PROC    A_SkullAttack_ NEAR
PUBLIC  A_SkullAttack_

cmp   word ptr ds:[si + MOBJ_T.m_targetRef], 0
jne   do_skullattack
ret   
do_skullattack:

push  bp
mov   di, bx


mov   es, cx
or    byte ptr es:[di + MOBJ_POS_T.mp_flags2 + 1], 1
mov   al, byte ptr ds:[si + MOBJ_T.m_mobjtype]
xor   ah, ah

push  cs
call  GetAttackSound_


xchg  ax, dx
mov   ax, si
call  S_StartSound_

mov   ax, si
call  A_FaceTarget_

IF COMPISA GE COMPILE_186
    mov   cx, word ptr ds:[si + MOBJ_T.m_targetRef]
    imul  ax, cx, (SIZE THINKER_T)
    imul  bx, cx, (SIZE MOBJ_POS_T)
ELSE
    mov   ax, (SIZE MOBJ_POS_T)
    mul   word ptr ds:[si + MOBJ_T.m_targetRef]
    xchg  ax, bx
    mov   ax, (SIZE THINKER_T)
    mul   word ptr ds:[si + MOBJ_T.m_targetRef]
ENDIF


add   ax, (_thinkerlist + THINKER_T.t_data)
mov   cx, MOBJPOSLIST_6800_SEGMENT

mov   dx, word ptr es:[di + MOBJ_POS_T.mp_angle + 2]
shr   dx, 1
and   dl, 0FCh
mov   bp, bx  ; store 
push  ax  ; bp - 2
push  dx  ; bp - 4


mov   ax, FINECOSINE_SEGMENT
mov   bx, SKULLSPEED_SMALL
call FixedMulTrigSpeedNoShift_MapLocal_

mov   word ptr ds:[si + MOBJ_T.m_momx + 0], ax
mov   word ptr ds:[si + MOBJ_T.m_momx + 2], dx

mov   bx, SKULLSPEED_SMALL
pop   dx ; bp - 4
mov   ax, FINESINE_SEGMENT
call FixedMulTrigSpeedNoShift_MapLocal_

mov   word ptr ds:[si + MOBJ_T.m_momy + 0], ax
mov   word ptr ds:[si + MOBJ_T.m_momy + 2], dx

mov   cx, MOBJPOSLIST_6800_SEGMENT
mov   ds, cx
mov   bx, bp

les   ax, dword ptr ds:[bx + MOBJ_POS_T.mp_x + 0]
mov   dx, es
les   bx, dword ptr ds:[bx + MOBJ_POS_T.mp_y + 0]
mov   cx, es

sub   ax, word ptr ds:[di + MOBJ_POS_T.mp_x + 0]
sbb   dx, word ptr ds:[di + MOBJ_POS_T.mp_x + 2]
sub   bx, word ptr ds:[di + MOBJ_POS_T.mp_y + 0]
sbb   cx, word ptr ds:[di + MOBJ_POS_T.mp_y + 2]

push  ss
pop   ds

call   P_AproxDistance_

mov   cx, MOBJPOSLIST_6800_SEGMENT
mov   es, cx


mov   ax, dx
cwd   
mov   cx, SKULLSPEED_SMALL
idiv  cx
cmp   ax, 1
jae   dont_set_dist16_to_1
mov   ax, 1
dont_set_dist16_to_1:
mov   cx, ax

pop   bx ; bp - 2

mov   ax, word ptr ds:[bx + MOBJ_T.m_height+0]
mov   dx, word ptr ds:[bx + MOBJ_T.m_height+2]
sar   dx, 1
rcr   ax, 1

sub   ax, word ptr es:[di + MOBJ_POS_T.mp_z + 0]
sbb   dx, word ptr es:[di + MOBJ_POS_T.mp_z + 2]
mov   di, bp
add   ax, word ptr es:[di + MOBJ_POS_T.mp_z + 0]
adc   dx, word ptr es:[di + MOBJ_POS_T.mp_z + 2]

mov   bx, cx

;call   FastDiv3216u_
db 0FFh  ; lcall[addr]
db 01Eh  ;
dw _FastDiv3216u_addr
mov   word ptr ds:[si + MOBJ_T.m_momz + 0], ax
mov   word ptr ds:[si + MOBJ_T.m_momz + 2], dx

pop   bp
ret   

ENDP





PROC    A_PainDie_ NEAR
PUBLIC  A_PainDie_

;mov   si, ax
mov   es, cx
and   byte ptr es:[bx + MOBJ_POS_T.mp_flags1],  (NOT MF_SOLID) ; inlined A_FALL?

les   di, dword ptr es:[bx + MOBJ_POS_T.mp_angle + 0]
mov   dx, es
add   dh, (ANG90_HIGHBITS SHR 8)
mov   bx, di
mov   cx, dx
call  A_PainShootSkull_
add   dh, (ANG90_HIGHBITS SHR 8)
mov   bx, di
mov   ax, si
mov   cx, dx
call  A_PainShootSkull_
add   dh, (ANG90_HIGHBITS SHR 8)
mov   bx, di
mov   ax, si
mov   cx, dx
;call  A_PainShootSkull_

; fall thru

ENDP

PROC    A_PainShootSkull_ NEAR
PUBLIC  A_PainShootSkull_

; bp - 2     fineangle
; bp - 4     targref
; bp - 6     x lo  then newmobj
; bp - 8     x hi

push  bp
mov   bp, sp

xchg  ax, di

shr   cx, 1
and   cl, 0FCh
push  cx  ; bp - 2


mov   ax, word ptr ds:[_thinkerlist + THINKER_T.t_next]
xor   cx, cx  ; count = 0
continue_checking_thinkers_for_skulls:

IF COMPISA GE COMPILE_186
    imul  bx, ax, (SIZE THINKER_T)
ELSE
    mov   bx, (SIZE THINKER_T)
    mul   bx
    xchg  ax, bx
ENDIF
mov   dx, word ptr ds:[bx + _thinkerlist + THINKER_T.t_prevFunctype]
and   dx, TF_FUNCBITS SHR 8
cmp   dx, TF_MOBJTHINKER_HIGHBITS
jne   not_thinker_do_next
cmp   byte ptr ds:[bx + _thinkerlist + THINKER_T.t_data + MOBJ_T.m_mobjtype], MT_SKULL
jne   not_thinker_do_next
inc   cx
not_thinker_do_next:
cmp   cx, 20
jg    exit_a_painshootskull

mov   ax, word ptr ds:[bx + _thinkerlist + THINKER_T.t_next]
test  ax, ax
jne   continue_checking_thinkers_for_skulls

exit_a_painshootskull_loop:
cmp   cx, 20
jle   less_than_20_skulls
exit_a_painshootskull:
LEAVE_MACRO 
ret   


less_than_20_skulls:

push  word ptr ds:[di + MOBJ_T.m_targetRef] ; bp - 4


;	prestep.h.intbits = 4 + 3 * ((radii) >> 1);

; this is a constant! 
; evaluates to 0x4A8000

lea   ax, ds:[di - (_thinkerlist + THINKER_T.t_data)]
cwd
mov   bx, (SIZE THINKER_T)
div   bx


IF COMPISA GE COMPILE_186
    imul  si, ax, (SIZE MOBJ_POS_T)
ELSE
    mov   si, (SIZE MOBJ_POS_T)
    mul   si
    xchg  ax, si
ENDIF

;    x = actor_pos->x.w + FixedMulTrigNoShift(FINE_COSINE_ARGUMENT, an, prestep.w);


mov   cx, 0004Ah
mov   bx, 08000h
mov   dx, word ptr [bp - 2]
mov   ax, FINECOSINE_SEGMENT

call  FixedMulTrigNoShift_MapLocal_
mov   cx, MOBJPOSLIST_6800_SEGMENT
mov   es, cx
add   ax, word ptr es:[si + MOBJ_POS_T.mp_x + 0]
adc   dx, word ptr es:[si + MOBJ_POS_T.mp_x + 2]
push  ax  ; bp - 6h
push  dx  ; bp - 8h
mov   cx, 0004Ah
mov   bx, 08000h
mov   dx, word ptr [bp - 2]
mov   ax, FINESINE_SEGMENT
call  FixedMulTrigNoShift_MapLocal_

mov   cx, MOBJPOSLIST_6800_SEGMENT
mov   es, cx

add   ax, word ptr es:[si + MOBJ_POS_T.mp_y + 0]
adc   dx, word ptr es:[si + MOBJ_POS_T.mp_y + 2]
xchg  ax, bx
mov   cx, dx

pop   dx ; bp - 8h
pop   ax ; bp - 6h

IF COMPISA GE COMPILE_186
    push  -1
    push  MT_SKULL
ELSE
    mov   es, ax
    
    mov   ax, -1
    push  ax
    mov   ax, MT_SKULL
    push  ax
    
    mov   ax, MOBJPOSLIST_6800_SEGMENT
    push  ax
    mov   ax, es
    pop   es
ENDIF

; UGLY but we're tapped out for registers...
push  word ptr es:[si + MOBJ_POS_T.mp_z + 2]
add   word ptr [bp - 0Ah], 8

push  word ptr es:[si + MOBJ_POS_T.mp_z + 0]

call  P_SpawnMobj_

mov   ax, word ptr ds:[_setStateReturn]
push  ax ; bp - 6 again (newmobj)
les   si, dword ptr ds:[_setStateReturn_pos]
push  word ptr es:[si + MOBJ_POS_T.mp_y + 2]
push  word ptr es:[si + MOBJ_POS_T.mp_y + 0]
push  word ptr es:[si + MOBJ_POS_T.mp_x + 2]
push  word ptr es:[si + MOBJ_POS_T.mp_x + 0]

mov   bx, si
mov   cx, es
call  P_TryMove_


jc    skull_nodamage
mov   cx, 10000
pop   ax ; bp - 6
mov   bx, di
mov   dx, di
call  P_DamageMobj_

jmp   exit_a_painshootskull

skull_nodamage:
pop   bx ; bp - 6
pop   ax ; bp - 4
mov   cx, dx
mov   word ptr ds:[bx + MOBJ_T.m_targetRef], ax
xchg  ax, bx
mov   bx, si
call  A_SkullAttack_
jmp   exit_a_painshootskull

ENDP

PROC    A_PainAttack_ NEAR
PUBLIC  A_PainAttack_

;mov   si, ax
cmp   word ptr ds:[si + MOBJ_T.m_targetRef], 0
je    exit_painattack
do_painattack:
call  A_FaceTarget_
mov   es, cx
les   bx, dword ptr es:[bx + MOBJ_POS_T.mp_angle + 0]
mov   cx, es
mov   ax, si
call  A_PainShootSkull_
exit_painattack:
ret   

ENDP


PROC    A_Scream_ NEAR
PUBLIC  A_Scream_

mov   bx, ax
mov   al, (SIZE MOBJINFO_T)
mul   byte ptr ds:[bx + MOBJ_T.m_mobjtype]
mov   si, ax
mov   al, byte ptr ds:[si + _mobjinfo + MOBJINFO_T.mobjinfo_deathsound]
cmp   al, SFX_PODTH1
jae   check_for_other_deathsound_1
test  al, al
je    exit_a_scream

got_deathsound:
cmp   byte ptr ds:[bx + MOBJ_T.m_mobjtype], MT_SPIDER
je    full_sound_deathscream
cmp   byte ptr ds:[bx + MOBJ_T.m_mobjtype], MT_CYBORG
jne   not_full_sound_deathscream
full_sound_deathscream:
xchg  ax, dx
xor   ax, ax
do_death_sound:
call  S_StartSound_

exit_a_scream:
ret   
check_for_other_deathsound_1:
cmp   al, SFX_PODTH3
jbe   check_for_other_deathsound_2
cmp   al, SFX_BGDTH2
ja    got_deathsound
call  P_Random_

; sound = sfx_bgdth1 + P_Random ()%2;
and   al, 1
add   al, SFX_BGDTH1
jmp   got_deathsound

check_for_other_deathsound_2:
call  P_Random_


mov   dl, 3
div   dl
mov   al, ah
cbw
add   al, SFX_PODTH1

jmp   got_deathsound
not_full_sound_deathscream:
xchg  ax, dx  ; dl gets al
xchg  ax, bx  ; ax gets bx

jmp   do_death_sound

ENDP


PROC    A_XScream_ NEAR
PUBLIC  A_XScream_

mov   dl, SFX_SLOP
call  S_StartSound_

ret   

ENDP


PROC    A_Pain_ NEAR
PUBLIC  A_Pain_

mov   bx, ax
mov   al, byte ptr ds:[bx + MOBJ_T.m_mobjtype]
xor   ah, ah

push  cs
call  GetPainSound_


xchg  ax, dx  ; dx gets ax
xchg  ax, bx  ; bx gets ax
call  S_StartSound_

ret   

ENDP


PROC    A_Fall_ NEAR
PUBLIC  A_Fall_

mov   es, cx
and   byte ptr es:[bx + MOBJ_POS_T.mp_flags1], (NOT MF_SOLID)
ret   

ENDP


PROC    A_Explode_ NEAR
PUBLIC  A_Explode_

;xchg  ax, si

IF COMPISA GE COMPILE_186
    mov   dx, bx
    imul  bx, word ptr ds:[si + MOBJ_T.m_targetRef], (SIZE THINKER_T)
ELSE
    push  ax
    mov   ax, (SIZE THINKER_T)
    mul   word ptr ds:[si + MOBJ_T.m_targetRef]
    xchg  ax, bx  ; product to bx
    xchg  ax, dx  ; dx gets bx
    pop   ax
ENDIF

mov   cx, 128
add   bx, (_thinkerlist + THINKER_T.t_data)
call  P_RadiusAttack_

ret   



ENDP

ultimate_episode_1:
cmp   al, 8
jne   exit_a_bossdeath_3
cmp   cl, MT_BRUISER
jmp   generic_shared_jne_weird

ultimate_episode_3:
cmp   al, 8
jne   exit_a_bossdeath_3
cmp   cl, MT_SPIDER
jmp   generic_shared_jne_weird

ultimate_episode_2:

cmp   al, 8
jne   exit_a_bossdeath_3
cmp   cl, MT_CYBORG
jmp   generic_shared_jne_weird

map_not_8:
cmp   al, 6
jne   exit_a_bossdeath_3
cmp   cl, MT_CYBORG
jmp   generic_shared_jne_weird


is_ultimate_1:
mov   al, byte ptr ds:[_gameepisode]
cmp   al, 4
ja    episode_above_4
;       4   3   2   1
;xor:   7   0   1   2
;dec:  6   -1   0   1

xor   al, 3
dec   ax
mov   al, byte ptr ds:[_gamemap]
js    ultimate_episode_3 ; -1 case
je    ultimate_episode_2 ;  0 case
jpo   ultimate_episode_1 ; was odd
; fall thru
ultimate_episode_4:
cmp   al, 8
jne   map_not_8
cmp   cl, MT_SPIDER
jmp   generic_shared_jne_weird




episode_above_4:

cmp   byte ptr ds:[_gamemap], 8
jmp   generic_shared_jne_weird

do_floor_and_exit:
call  EV_DoFloor_

exit_a_bossdeath_3:
ret   


PROC    A_BossDeath_ NEAR
PUBLIC  A_BossDeath_

xchg  ax, bx
mov   cl, byte ptr ds:[bx + MOBJ_T.m_mobjtype]
xor   ax, ax
cmp   byte ptr ds:[_commercial], al
jne   is_commercial_1 ; doom 2

cmp   byte ptr ds:[_is_ultimate], al
jne   is_ultimate_1

cmp   byte ptr ds:[_gamemap], 8
jne   exit_a_bossdeath_3
cmp   cl, MT_BRUISER
jne   test_player_health

cmp   byte ptr ds:[_gameepisode], 1
jmp   generic_shared_jne_weird

is_commercial_1:
cmp   byte ptr ds:[_gamemap], 7
jne   exit_a_bossdeath
cmp   cl, 8
je    test_player_health
cmp   cl, MT_BABY
generic_shared_jne_weird:
jne   exit_a_bossdeath

test_player_health:
cmp   word ptr ds:[_player + PLAYER_T.player_health], 0
jle   exit_a_bossdeath
lea   ax, ds:[bx - (_thinkerlist + THINKER_T.t_data)]
cwd
mov   si, (SIZE THINKER_T)
div   si
xchg  ax, si
mov   ax, word ptr ds:[_thinkerlist + THINKER_T.t_next]

je    all_bosses_dead
scan_next_mobj_for_bosscheck:
mov   bx, (SIZE THINKER_T)
mul   bx
xchg  ax, bx
mov   dx, word ptr ds:[bx + _thinkerlist + THINKER_T.t_prevFunctype]
and   dx, TF_FUNCBITS 
cmp   dx, TF_MOBJTHINKER_HIGHBITS
jne   not_live_boss_continue_scan

cmp   ax, si
je    not_live_boss_continue_scan

cmp   cl, byte ptr ds:[bx + _thinkerlist + THINKER_T.t_data + MOBJ_T.m_mobjtype]
jne   not_live_boss_continue_scan
cmp   word ptr ds:[bx + _thinkerlist + THINKER_T.t_data + MOBJ_T.m_health], 0
jnle  exit_a_bossdeath   ; 	    // other boss not dead

not_live_boss_continue_scan:
mov   ax, word ptr ds:[bx + _thinkerlist + THINKER_T.t_next]
test  ax, ax
jne   scan_next_mobj_for_bosscheck

all_bosses_dead:

cmp   byte ptr ds:[_commercial], 0
je    not_commercial_bosses_dead

cmp   byte ptr ds:[_gamemap], 7
jne   do_exit_level
cmp   cl, MT_FATSO
je    do_lower_floor_to_lowest
cmp   cl, MT_BABY
jne   do_exit_level
mov   bx, FLOOR_RAISETOTEXTURE
mov   dx, -1
mov   ax, TAG_667
jmp   do_floor_and_exit
do_exit_level:
;call  G_ExitLevel_ ; inlined
mov   byte ptr ds:[_secretexit], 0
mov   byte ptr ds:[_gameaction], GA_COMPLETED
exit_a_bossdeath:
ret   

continue_noncommercial_level_check:
cmp   al, 1
jne   do_exit_level

do_lower_floor_to_lowest:
mov   bx, FLOOR_LOWERFLOORTOLOWEST
mov   dx, -1
do_tag_666_and_door:
mov   ax, TAG_666
jmp   do_floor_and_exit


not_commercial_bosses_dead:
mov   al, byte ptr ds:[_gameepisode]
cmp   al, 4
jne   continue_noncommercial_level_check
mov   al, byte ptr ds:[_gamemap]
cmp   al, 8
je    do_lower_floor_to_lowest
cmp   al, 6
jne   do_exit_level
mov   dx, DOOR_BLAZEOPEN
jmp   do_tag_666_and_door








ENDP


PROC    A_Hoof_ NEAR
PUBLIC  A_Hoof_


mov   dl, SFX_HOOF
call  S_StartSound_

xchg  ax, si  ; si has ax value
jmp   A_Chase_

ENDP


PROC    A_Metal_ NEAR
PUBLIC  A_Metal_


mov   dl, SFX_METAL
call  S_StartSound_

xchg  ax, si  ; si has ax value
jmp   A_Chase_

ENDP


PROC    A_BabyMetal_ NEAR
PUBLIC  A_BabyMetal_


mov   dl, SFX_BSPWLK
call  S_StartSound_

xchg  ax, si  ; si has ax value
jmp   A_Chase_

ENDP


PROC    A_BrainAwake_ NEAR
PUBLIC  A_BrainAwake_

mov   byte ptr ds:[si + MOBJ_T.m_tics], 181
mov   word ptr ds:[_numbraintargets], 0
mov   word ptr ds:[_braintargeton], 0
mov   ax, word ptr ds:[_thinkerlist + THINKER_T.t_next]

loop_next_brainawake:

IF COMPISA GE COMPILE_186
    imul  bx, ax, (SIZE THINKER_T)
ELSE
    xchg  ax, bx
    mov   ax, (SIZE THINKER_T)
    mul   bx
    xchg  ax, bx
ENDIF

mov   dx, word ptr ds:[bx + _thinkerlist + THINKER_T.t_prevFunctype]
and   dx, TF_FUNCBITS
cmp   dx, TF_MOBJTHINKER_HIGHBITS
jne   mobj_not_braintarget



cmp   byte ptr ds:[bx + OFFSET _thinkerlist + THINKER_T.t_data + MOBJ_T.m_mobjtype], MT_BOSSTARGET
jne   mobj_not_braintarget

mov   bx, word ptr ds:[_numbraintargets]
sal   bx, 1
mov   word ptr ds:[bx + _braintargets], ax
inc   word ptr ds:[_numbraintargets]


mobj_not_braintarget:

IF COMPISA GE COMPILE_186
    imul  bx, ax, (SIZE THINKER_T)
ELSE
    mov   bx, (SIZE THINKER_T)
    mul   bx
    xchg  ax, bx
ENDIF

mov   ax, word ptr ds:[bx + OFFSET _thinkerlist + THINKER_T.t_next]
test  ax, ax
jne   loop_next_brainawake


mov   dl, SFX_BOSSIT
xor   ax, ax
call  S_StartSound_

ret   


ENDP


PROC    A_BrainPain_ NEAR
PUBLIC  A_BrainPain_

mov   dl, SFX_BOSPN
xor   ax, ax
call  S_StartSound_

ret   

ENDP


PROC    A_BrainScream_ NEAR
PUBLIC  A_BrainScream_


mov   di, bx
mov   es, cx


mov   ax, word ptr es:[di + MOBJ_POS_T.mp_x + 0]
mov   si, word ptr es:[di + MOBJ_POS_T.mp_x + 2]


sub   si, 196
do_next_brain_scream_iter:

mov   cx, MOBJPOSLIST_6800_SEGMENT
mov   es, cx
mov   ax, word ptr es:[di + MOBJ_POS_T.mp_x + 2]
add   ax, 320
cmp   si, ax
jnl   done_with_brain_scream_loop

mov   dx, word ptr es:[di + MOBJ_POS_T.mp_x + 0]
les   bx, dword ptr es:[di + MOBJ_POS_T.mp_y + 0]
mov   cx, es

IF COMPISA GE COMPILE_186
    push  -1
    push  MT_ROCKET
ELSE
    mov   ax, -1
    push  ax
    mov   ax, MT_ROCKET
    push  ax
ENDIF

call  P_Random_

sal   ax, 1
add   ax, 128
push  ax  ; z hi

IF COMPISA GE COMPILE_186
    push  0   ; z lo
ELSE
    xor ax, ax
    push  ax   ; z 
ENDIF

sub   cx, 320
xchg  ax, dx   ; ax gets x lobits
mov   dx, si   ; dx gets stored x hibits

call  P_SpawnMobj_


mov   bx, word ptr ds:[_setStateReturn]
call  P_Random_

;		th->momz.w = P_Random()*512;

cwd
xchg  ah, al
sal   ax, 1
rcl   dx, 1
mov   word ptr ds:[bx + MOBJ_T.m_momz + 0], ax
mov   word ptr ds:[bx + MOBJ_T.m_momz + 2], dx
mov   dx, S_BRAINEXPLODE1
mov   ax, bx
call  P_SetMobjState_


call  P_Random_
and   al, 7
sub   byte ptr ds:[bx + MOBJ_T.m_tics], al
mov   al, byte ptr ds:[bx + MOBJ_T.m_tics]
cmp   al, 1
jae   tics_above_1
tics_negative_cap_to_1:
mov   byte ptr ds:[bx + MOBJ_T.m_tics], 1
add   si, 8
jmp   do_next_brain_scream_iter
tics_above_1:
cmp   al, 240
ja    tics_negative_cap_to_1
add   si, 8
jmp   do_next_brain_scream_iter


done_with_brain_scream_loop:
mov   dl, SFX_BOSDTH
xor   ax, ax
call  S_StartSound_

ret   


ENDP


PROC    A_BrainExplode_ NEAR
PUBLIC  A_BrainExplode_



call  P_Random_
xchg  ax, dx
call  P_Random_
;    x = mo_pos->x.w + (P_Random () - P_Random ())*2048;
sub   dx, ax




IF COMPISA GE COMPILE_186
    push  -1 
    push  MT_ROCKET
ELSE
    mov   ax, -1
    push  ax
    mov   ax, MT_ROCKET
    push  ax
ENDIF


call  P_Random_

mov   es, cx

sal   ax, 1
add   ax, 128
push  ax

IF COMPISA GE COMPILE_186
    push  0
ELSE
    xor   ax, ax
    push  ax
ENDIF

; shift 11
xor   cx, cx
mov   cl, dh
mov   dh, dl
mov   dl, ch  ; zero
sal   dx, 1
rcl   cx, 1
sal   dx, 1
rcl   cx, 1
sal   dx, 1
rcl   cx, 1

; cx:dx has (prandom - prandom * 2048)

mov   ax, word ptr es:[bx + MOBJ_POS_T.mp_x + 0]
add   ax, dx
mov   dx, word ptr es:[bx + MOBJ_POS_T.mp_x + 2]
adc   dx, cx

les   bx, dword ptr es:[bx + MOBJ_POS_T.mp_y + 0]
mov   cx, es




call  P_SpawnMobj_


mov   bx, word ptr ds:[_setStateReturn]
call  P_Random_

;    th->momz.w = P_Random()*512;

cwd
xchg  al, ah
sal   ax, 1
rcl   dx, 1
mov   word ptr ds:[bx + MOBJ_T.m_momz + 0], ax
mov   word ptr ds:[bx + MOBJ_T.m_momz + 2], dx

mov   dx, S_BRAINEXPLODE1
mov   ax, bx
call  P_SetMobjState_

call  P_Random_
and   al, 7
sub   byte ptr ds:[bx + MOBJ_T.m_tics], al
mov   al, byte ptr ds:[bx + MOBJ_T.m_tics]
cmp   al, 1
jb    cap_tics_to_1_2
cmp   al, 240
jna   exit_brainexplode
cap_tics_to_1_2:
mov   byte ptr ds:[bx + MOBJ_T.m_tics], 1
exit_brainexplode:
exit_brainspit:
ret   

ENDP


PROC    A_BrainSpit_ NEAR
PUBLIC  A_BrainSpit_

; bp - 2   targRef
; bp - 4   targ_pos
mov   byte ptr ds:[si + MOBJ_T.m_tics], 150

xor   byte ptr ds:[_brainspit_easy], 1
cmp   byte ptr ds:[_gameskill], SK_EASY
ja    do_brainspit
cmp   byte ptr ds:[_brainspit_easy], 0
je    exit_brainspit

do_brainspit:


; si has ptr already...
mov   di, bx

mov   bx, word ptr ds:[_braintargeton]
sal   bx, 1
mov   cx, word ptr ds:[bx + _braintargets]
push  cx  ; bp - 2

mov   ax, word ptr ds:[_braintargeton]
inc   ax
cmp   ax, word ptr ds:[_numbraintargets]
jl    dont_mod_braintargets
xor   ax, ax
dont_mod_braintargets:
mov   word ptr ds:[_braintargeton], ax


IF COMPISA GE COMPILE_186
    imul  dx, cx, (SIZE THINKER_T)
    imul  bx, cx, (SIZE MOBJ_POS_T)
    push  bx   ; bp - 4
    push  MT_SPAWNSHOT ; todo 186
ELSE
    mov   ax, (SIZE MOBJ_POS_T)
    mul   cx
    xchg  ax, bx

    mov   ax, (SIZE THINKER_T)
    mul   cx
    xchg  ax, dx

    push  bx   ; bp - 4

    mov   ax, MT_SPAWNSHOT
    push  ax

ENDIF

add   dx, (OFFSET _thinkerlist + THINKER_T.t_data)


mov   cx, MOBJPOSLIST_6800_SEGMENT
mov   ax, si
mov   bx, di
call  P_SpawnMissile_

mov   si, word ptr ds:[_setStateReturn]

;	newmobj->targetRef = targRef;
pop   bx  ; bp - 4
pop   word ptr ds:[si + MOBJ_T.m_targetRef]  ; bp - 2


;    newmobj->reactiontime = ((targ->y - mo->y) / newmobj->momy) / newmobj->state->tics;


; HACK alert
; div 32 bit by 32 bit sucks, especially for a small (one byte) result.
; to get an accurate answer without external dependencies or a lot of code we are looping.
; it's fine. this runs really rarely. Once every many frames in one map of doom2.

; ok you end up with a negative divided by a negative in doom 2 due to mobj positioning.
; we will ABS then sub loop instead of add looping. 
; in theory some wad might not have downward pointing boss?


xor   dx, dx 
mov   es, word ptr ds:[_setStateReturn_pos+2]
mov   ax, word ptr es:[bx + MOBJ_POS_T.mp_y + 2]
sub   ax, word ptr es:[di + MOBJ_POS_T.mp_y + 2]

jns   dont_abs_y_1
neg   ax
; dx known zero. wont overflow.
dont_abs_y_1:


les   bx, dword ptr ds:[si + MOBJ_T.m_momy + 0]
mov   di, es

test  di, di
jns   dont_abs_y_2
neg   bx
adc   di, 0
neg   di

dont_abs_y_2:

xor   cx, cx
dec   cx

; the answer maxes at around 160?
loop_subtract_to_divide_like_a_moron:
inc   cx
sub   dx, bx
sbb   ax, di
jns   loop_subtract_to_divide_like_a_moron

; cx has first divide result

les   di, dword ptr ds:[_setStateReturn_pos]

mov   ax, (SIZE STATE_T)

mul   word ptr es:[di + MOBJ_POS_T.mp_statenum]
mov   dx, STATES_SEGMENT
mov   es, dx
xchg  ax, bx
mov   al, byte ptr es:[bx + STATE_T.state_tics] ; todo is this a hardcoded value
cbw  

;cwd
;xchg  ax, cx
;div   cx

xchg  ax, cx
div   cl

mov   byte ptr ds:[si + MOBJ_T.m_reactiontime], al
mov   dl, SFX_BOSPIT
xor   ax, ax
call  S_StartSound_
exit_spawnfly:
ret   

ENDP


PROC    A_SpawnSound_ NEAR
PUBLIC  A_SpawnSound_

mov   dl, SFX_BOSCUB
call  S_StartSound_



;call  A_SpawnFly_
;ret   

; FALL THROUGH. use si for ax

ENDP


PROC    A_SpawnFly_ NEAR
PUBLIC  A_SpawnFly_


dec   byte ptr ds:[si + MOBJ_T.m_reactiontime]
jne   exit_spawnfly

do_spawnfly:



mov   di, word ptr ds:[si + MOBJ_T.m_targetRef]
IF COMPISA GE COMPILE_186
    imul  bx, di, (SIZE THINKER_T)
    imul  di, di, (SIZE MOBJ_POS_T)
ELSE
    mov   ax, (SIZE MOBJ_POS_T)
    mul   di
    xchg  ax, di
    mov   bx, (SIZE THINKER_T)
    mul   bx
    xchg  ax, bx
ENDIF


; push once for arg for next function, once for arg to this function
add   bx, _thinkerlist + THINKER_T.t_data + MOBJ_T.m_secnum
push  word ptr ds:[bx]   ; param secnum

push  word ptr ds:[bx]   ; param secnum

;mov   ax, MOBJPOSLIST_6800_SEGMENT
mov   ds, cx

IF COMPISA GE COMPILE_186
    push  MT_SPAWNFIRE                      ; param graphic
ELSE
    mov   ax, MT_SPAWNFIRE
    push  ax
ENDIF
push  word ptr ds:[di + MOBJ_POS_T.mp_z + 2] ; param z hi
push  word ptr ds:[di + MOBJ_POS_T.mp_z + 0] ; param z lo

les   bx, dword ptr ds:[di + MOBJ_POS_T.mp_y + 0]
mov   cx, es
les   ax, dword ptr ds:[di + MOBJ_POS_T.mp_x + 0]
mov   dx, es

push  ss
pop   ds

call  P_SpawnMobj_


mov   dl, SFX_TELEPT
mov   ax, word ptr ds:[_setStateReturn]
call  S_StartSound_

call  P_Random_
cmp   al, 50
jb    spawn_imp
spawn_non_imp:
cmp   al, 90
jae   spawn_non_cgunner
mov   al, MT_SERGEANT
jmp   chose_spawn_unit
spawn_non_cgunner:
cmp   al, 120
jae   spawn_not_spectre
mov   al, MT_SHADOWS
jmp   chose_spawn_unit
spawn_not_spectre:
cmp   al, 130
jae   spawn_not_painelem
mov   al, MT_PAIN
jmp   chose_spawn_unit
spawn_not_painelem:
cmp   al, 160
jae   spawn_not_caco
mov   al, MT_HEAD
jmp   chose_spawn_unit
spawn_not_caco:
cmp   al, 162
jae   spawn_not_vile
mov   al, MT_VILE
jmp   chose_spawn_unit
spawn_not_vile:
cmp   al, 172
jae   spawn_not_revenant
mov   al, MT_UNDEAD
jmp   chose_spawn_unit
spawn_not_revenant:
cmp   al, 192
jae   spawn_not_spider
mov   al, MT_BABY
jmp   chose_spawn_unit
spawn_not_spider:
cmp   al, 222
jae   spawn_not_mancubus
mov   al, MT_FATSO
jmp   chose_spawn_unit
spawn_not_mancubus:
cmp   al, 246
jae   spawn_not_hellknight
mov   al, MT_KNIGHT
jmp   chose_spawn_unit
spawn_not_hellknight:
mov   al, MT_BRUISER
jmp   chose_spawn_unit
spawn_imp:
mov   al, MT_TROOP
chose_spawn_unit:

; this was already pushed twice before last function call

;pop   bx  ; bp - 2
;push  word ptr ds:[bx + MOBJ_T.m_secnum]  ; secnum

xor   ah, ah
push  ax                                  ; type

mov   ax, MOBJPOSLIST_6800_SEGMENT
mov   ds, ax

push  word ptr ds:[di + MOBJ_POS_T.mp_z + 2]
push  word ptr ds:[di + MOBJ_POS_T.mp_z + 0]

les   bx, dword ptr ds:[di + MOBJ_POS_T.mp_y + 0]
mov   cx, es
les   ax, dword ptr ds:[di + MOBJ_POS_T.mp_x + 0]
mov   dx, es

push  ss
pop   ds

call  P_SpawnMobj_


IF COMPISA GE COMPILE_186
    imul  di, ax, (SIZE THINKER_T)
    add   di, (OFFSET _thinkerlist + THINKER_T.t_data)
    imul  bx, ax, (SIZE MOBJ_POS_T)
ELSE
    xchg  ax, bx
    mov   ax, (SIZE THINKER_T)
    mul   bx
    xchg  ax, di
    add   di, (OFFSET _thinkerlist + THINKER_T.t_data)
    mov   ax, (SIZE MOBJ_POS_T)
    mul   bx
    xchg  ax, bx

ENDIF

mov   dx, 1
mov   ax, di
mov   cx, MOBJPOSLIST_6800_SEGMENT
call  P_LookForPlayers_
jnc   dont_set_seestate
mov   al, byte ptr ds:[di + MOBJ_T.m_mobjtype]
xor   ah, ah

push  cs
call  GetSeeState_


mov   dx, ax
mov   ax, di
call  P_SetMobjState_

dont_set_seestate:
push  word ptr ds:[di + MOBJ_T.m_secnum]
mov   ds, cx
push  word ptr ds:[bx + MOBJ_POS_T.mp_y + 2]
push  word ptr ds:[bx + MOBJ_POS_T.mp_y + 0]
push  word ptr ds:[bx + MOBJ_POS_T.mp_x + 2]
push  word ptr ds:[bx + MOBJ_POS_T.mp_x + 0]
xchg  ax, di 

push  ss
pop   ds

push  cs
call  P_TeleportMove_

xchg   ax, si
call   P_RemoveMobj_

ret   



ENDP


PROC    A_PlayerScream_ NEAR
PUBLIC  A_PlayerScream_

mov   dx, SFX_PLDETH 
mov   bx, word ptr ds:[_playerMobj]
cmp   byte ptr ds:[_commercial], 0
je    normal_scream
cmp   word ptr ds:[bx + MOBJ_T.m_health], -50
jge   normal_scream
mov   dl, SFX_PDIEHI
normal_scream:
xchg  ax, bx ; player
call  S_StartSound_

ret   

ENDP




setmobjstate_jump_table:
dw A_BFGSpray_
dw A_Explode_
dw A_Pain_
dw A_PlayerScream_
dw A_Fall_
dw A_XScream_
dw A_Look_
dw A_Chase_
dw A_FaceTarget_
dw A_PosAttack_
dw A_Scream_
dw A_SPosAttack_
dw A_VileChase_
dw A_VileStart_
dw A_VileTarget_
dw A_VileAttack_
dw A_StartFire_
dw A_Fire_
dw A_FireCrackle_
dw A_Tracer_
dw A_SkelWhoosh_
dw A_SkelFist_
dw A_SkelMissile_
dw A_FatRaise_
dw A_FatAttack1_
dw A_FatAttack2_
dw A_FatAttack3_
dw A_BossDeath_
dw A_CPosAttack_
dw A_CPosRefire_
dw A_TroopAttack_
dw A_SargAttack_
dw A_HeadAttack_
dw A_BruisAttack_
dw A_SkullAttack_
dw A_Metal_
dw A_SpidRefire_
dw A_BabyMetal_
dw A_BspiAttack_
dw A_Hoof_
dw A_CyberAttack_
dw A_PainAttack_
dw A_PainDie_
dw A_KeenDie_
dw A_BrainPain_
dw A_BrainScream_
dw A_DoBrainDie_
dw A_BrainAwake_
dw A_BrainSpit_
dw A_SpawnSound_
dw A_SpawnFly_
dw A_BrainExplode_

ENDP



; todo idea p_setmobjstate variant with mobjpos already loaded. skips the div/mul steps.
PROC P_SetMobjState_ NEAR
PUBLIC P_SetMobjState_

; bp - 2   unused
; bp - 4   unused
; bp - 6   state offset
; bp - 8   mobjpos offset

; dx state
; ax mobj

push      bx
push      cx
push      si
push      di

mov       si, ax
mov       cx, dx

mov       word ptr ds:[_setStateReturn], ax
mov       bx, (SIZE THINKER_T)
sub       ax, (_thinkerlist + THINKER_T.t_data)
xor       dx, dx
div       bx

IF COMPISA GE COMPILE_186
    imul  ax, ax, (SIZE MOBJ_POS_T)
ELSE
    mov   di, (SIZE MOBJ_POS_T)
    mul   di
ENDIF

;mov       word ptr ds:[_setStateReturn_pos + 2], MOBJPOSLIST_6800_SEGMENT
mov       word ptr ds:[_setStateReturn_pos], ax


;test      cx, cx
;je        state_is_null
jcxz      state_is_null


do_next_state:
push      ax  ; mobjpos offset
xchg      ax, bx   ; bx gets mobjpos offset
mov       ax, 6
mul       cx        ; todo shift.. 
mov       di, MOBJPOSLIST_6800_SEGMENT
mov       es, di
push      ax    ; state offset
xchg      ax, di

mov       word ptr es:[bx + MOBJ_POS_T.mp_statenum], cx
mov       ax, STATES_SEGMENT
mov       es, ax
mov       al, byte ptr es:[di + STATE_T.state_tics]
mov       byte ptr ds:[si + MOBJ_T.m_tics], al
mov       al, byte ptr es:[di + state_action]
sub       al, ETF_A_BFGSpray                        ; minimum action number

;cmp       al, ETF_A_BRAINEXPLODE ; max range
cmp       al, (ETF_A_BRAINEXPLODE - ETF_A_BFGSPRAY) ; max range
ja        done_with_mobj_state_action
cbw
sal       ax, 1
xchg      ax, di

mov       cx, MOBJPOSLIST_6800_SEGMENT
mov       ax, si

PUSHA_NO_AX_MACRO

call      word ptr cs:[di + OFFSET setmobjstate_jump_table - OFFSET P_SIGHT_STARTMARKER_]

POPA_NO_AX_MACRO


done_with_mobj_state_action:
mov       word ptr ds:[_setStateReturn], si

pop       di
pop       ax
mov       word ptr ds:[_setStateReturn_pos], ax

;mov       word ptr ds:[_setStateReturn_pos + 2], dx

mov       cx, STATES_SEGMENT
mov       es, cx

mov       cx, word ptr es:[di + STATE_T.state_nextstate]
cmp       byte ptr ds:[si + MOBJ_T.m_tics], 0
jne       exit_p_setmobjstate_return_1
test      cx, cx

jne       do_next_state

state_is_null:
xchg      ax, bx  ; bx gets ptr from ax

mov       ax, MOBJPOSLIST_6800_SEGMENT
mov       es, ax
mov       ax, si
mov       word ptr es:[bx + MOBJ_POS_T.mp_stateNum], 0

xor       dx, dx

call      P_RemoveMobj_


mov       word ptr ds:[_setStateReturn], si
lea       ax, [si - (_thinkerlist + THINKER_T.t_data)]
mov       bx, (SIZE THINKER_T)
div       bx


IF COMPISA GE COMPILE_186
    imul  ax, ax, (SIZE MOBJ_POS_T)
ELSE
    mov   di, (SIZE MOBJ_POS_T)
    mul   di
ENDIF

;mov       word ptr ds:[_setStateReturn_pos + 2], MOBJPOSLIST_6800_SEGMENT
mov       word ptr ds:[_setStateReturn_pos], ax
xor       al, al

exit_p_setmobjstate:
pop       di
pop       si
pop       cx
pop       bx
ret
exit_p_setmobjstate_return_1:
mov       al, 1
jmp       exit_p_setmobjstate


ENDP





PROC      A_DoBrainDie_ NEAR
;call      G_ExitLevel_
;call  G_ExitLevel_ ; inlined
mov   byte ptr ds:[_secretexit], 0
mov   byte ptr ds:[_gameaction], GA_COMPLETED


ret
ENDP





PROC    P_ENEMY_ENDMARKER_ 
PUBLIC  P_ENEMY_ENDMARKER_
ENDP



END
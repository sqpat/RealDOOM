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


; hack but oh well
P_SIGHT_STARTMARKER_ = 0 

EXTRN P_Random_:NEAR
EXTRN FastDiv3216u_:PROC
EXTRN FixedMulTrigSpeed_:PROC
EXTRN FixedMulTrigSpeedNoShift_:PROC
EXTRN FixedMulTrigNoShift_:PROC
EXTRN G_ExitLevel_:PROC
EXTRN S_StartSound_:PROC
EXTRN P_SpawnMobj_:PROC
EXTRN P_RemoveMobj_:PROC
EXTRN P_DamageMobj_:PROC
EXTRN R_PointToAngle2_:PROC
EXTRN P_SpawnPuff_:PROC
EXTRN P_UseSpecialLine_:PROC


EXTRN P_SetMobjState_:PROC
EXTRN EV_DoDoor_:PROC
EXTRN EV_DoFloor_:NEAR
EXTRN __I4D:PROC

.DATA

EXTRN _gameskill:BYTE
EXTRN _gametic:DWORD
EXTRN _fastparm:BYTE
EXTRN _diags:WORD
EXTRN _opposite:WORD
EXTRN _P_AproxDistance:DWORD
EXTRN _P_SpawnMissile:DWORD
EXTRN _P_TeleportMove:DWORD
EXTRN _P_RadiusAttack:DWORD
EXTRN _P_TryMove:DWORD
EXTRN _P_CheckPosition:DWORD
EXTRN _P_CheckSightTemp:DWORD
EXTRN _P_SetThingPosition:DWORD
EXTRN _P_UnsetThingPosition:DWORD
EXTRN _P_AimLineAttack:DWORD
EXTRN _P_LineAttack:DWORD


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


TAG_1323 =		56
TAG_1044 =		57
TAG_86	=		58
TAG_77	=		59
TAG_99	=		60
TAG_666	=		61
TAG_667	=		62
TAG_999	=		63

DOOR_NORMAL = 0
DOOR_CLOSE30THENOPEN = 1
DOOR_CLOSE = 2
DOOR_OPEN = 3
DOOR_RAISEIN5MINS = 4
DOOR_BLAZERAISE   = 5
DOOR_BLAZEOPEN    = 6
DOOR_BLAZECLOSE   = 7

FLOOR_LOWERFLOOR = 0
FLOOR_LOWERFLOORTOLOWEST = 1
FLOOR_TURBOLOWER = 2
FLOOR_RAISEFLOOR = 3
FLOOR_RAISEFLOORTONEAREST = 4
FLOOR_RAISETOTEXTURE = 5
FLOOR_LOWERANDCHANGE = 6
FLOOR_RAISEFLOOR24 = 7
FLOOR_RAISEFLOOR24ANDCHANGE = 8
FLOOR_RAISEFLOORCRUSH = 9
FLOOR_RAISEFLOORTURBO = 10
FLOOR_DONUTRAISE = 11
FLOOR_RAISEFLOOR512 = 12

SKULLSPEED_SMALL = 20


PROC    P_ENEMY_STARTMARKER_ 
PUBLIC  P_ENEMY_STARTMARKER_
ENDP


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

;    if (soundsector->validcount == validcount_global && sector_soundtraversed_far[secnum] <= soundblocks+1) {
;		return;		// already flooded
;    }


mov   es, si
mov   al, byte ptr es:[di]
cbw
dec   ax ; instead of plus 1 to soundblocks do minus 12 to sector_soundtraversed_far
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


;	sector_soundtraversed_far[secnum] = soundblocks+1;
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

db    09Ah
dw    P_LINEOPENINGOFFSET, PHYSICS_HIGHCODE_SEGMENT

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


PROC    P_NoiseAlert_ FAR
PUBLIC  P_NoiseAlert_

push  bx
push  dx
inc   word ptr ds:[_validcount_global]
mov   bx, word ptr ds:[_playerMobj]
xor   dx, dx
mov   ax, word ptr ds:[bx + MOBJ_T.m_secnum]
call  P_RecursiveSound_
pop   dx
pop   bx
retf  

ENDP


PROC    P_CheckMeleeRange_ NEAR
PUBLIC  P_CheckMeleeRange_

push  bx
push  cx
push  dx
push  si
push  di
push  bp
mov   bp, sp
sub   sp, 010h
push  ax
mov   bx, ax
cmp   word ptr ds:[bx + MOBJ_T.m_targetRef], 0
jne   label_9
exit_check_meleerange_return_0:
xor   al, al
exit_check_meleerange:
LEAVE_MACRO 
pop   di
pop   si
pop   dx
pop   cx
pop   bx
ret   
label_9:
mov   bx, SIZEOF_THINKER_T
sub   ax, (OFFSET _thinkerlist + THINKER_T.t_data)
xor   dx, dx
div   bx
imul  si, ax, SIZEOF_MOBJ_POS_T
mov   ax, MOBJPOSLIST_6800_SEGMENT
mov   es, ax
mov   ax, word ptr es:[si]
mov   word ptr [bp - 4], ax
mov   ax, word ptr es:[si + 2]
mov   di, word ptr [bp - 012h]
mov   word ptr [bp - 0Eh], ax
mov   ax, word ptr es:[si + MOBJ_POS_T.mp_y + 0]
mov   di, word ptr ds:[di + MOBJ_T.m_targetRef]
mov   word ptr [bp - 0Ch], ax
imul  ax, di, SIZEOF_THINKER_T
imul  di, di, SIZEOF_MOBJ_POS_T
add   ax, (OFFSET _thinkerlist + THINKER_T.t_data)
mov   word ptr [bp - 2], ax
mov   ax, word ptr es:[di]
mov   word ptr [bp - 0Ah], ax
mov   ax, word ptr es:[di + 2]
mov   word ptr [bp - 010h], ax
mov   ax, word ptr es:[di + MOBJ_POS_T.mp_y + 0]
mov   bx, word ptr [bp - 2]
mov   word ptr [bp - 8], ax
mov   al, byte ptr ds:[bx + MOBJ_T.m_mobjtype]
xor   ah, ah
imul  ax, ax, SIZEOF_MOBJINFO_T
mov   cx, word ptr es:[si + MOBJ_POS_T.mp_y + 2]
mov   bx, ax
mov   dx, word ptr es:[di + MOBJ_POS_T.mp_y + 2]
add   bx, (OFFSET _mobjinfo + MOBJINFO_T.mobjinfo_radius)
mov   al, byte ptr ds:[bx]
mov   bx, word ptr [bp - 8]
mov   byte ptr [bp - 6], al
sub   bx, word ptr [bp - 0Ch]
sbb   dx, cx
mov   ax, word ptr [bp - 0Ah]
mov   cx, dx
sub   ax, word ptr [bp - 4]
mov   dx, word ptr [bp - 010h]
sbb   dx, word ptr [bp - 0Eh]
mov   byte ptr [bp - 5], 0
call  dword ptr ds:[_P_AproxDistance]
mov   ax, word ptr [bp - 6]
add   ax, (MELEERANGE - 20)
cmp   dx, ax
jl    label_10
jmp   exit_check_meleerange_return_0
label_10:
mov   dx, word ptr [bp - 2]
mov   ax, word ptr [bp - 012h]
mov   cx, di
mov   bx, si
call  dword ptr ds:[_P_CheckSightTemp]
test  al, al
jne   exit_check_meleerange_return_1
jmp   exit_check_meleerange
exit_check_meleerange_return_1:
mov   al, 1
LEAVE_MACRO 
pop   di
pop   si
pop   dx
pop   cx
pop   bx
ret   

ENDP


PROC    P_CheckMissileRange_ NEAR
PUBLIC  P_CheckMissileRange_

push  bx
push  cx
push  dx
push  si
push  di
push  bp
mov   bp, sp
sub   sp, 012h
mov   si, ax
imul  bx, word ptr ds:[si + MOBJ_T.m_targetRef], SIZEOF_THINKER_T
mov   cx, SIZEOF_THINKER_T
lea   ax, ds:[bx + (OFFSET _thinkerlist + THINKER_T.t_data)]
xor   dx, dx
mov   word ptr [bp - 0Ah], ax
lea   ax, ds:[si - (OFFSET _thinkerlist + THINKER_T.t_data)]
div   cx
imul  di, ax, SIZEOF_MOBJ_POS_T
xor   dx, dx
mov   ax, bx
div   cx
imul  bx, ax, SIZEOF_MOBJ_POS_T
mov   word ptr [bp - 012h], GETMELEESTATEADDR
mov   word ptr [bp - 010h], INFOFUNCLOADSEGMENT
mov   word ptr [bp - 2], MOBJPOSLIST_6800_SEGMENT
mov   word ptr [bp - 6], MOBJPOSLIST_6800_SEGMENT
mov   dx, word ptr [bp - 0Ah]
mov   word ptr [bp - 4], bx
mov   cx, bx
mov   ax, si
mov   bx, di
call  dword ptr ds:[_P_CheckSightTemp]
test  al, al
je    exit_checkmissilerange
mov   es, word ptr [bp - 2]
test  byte ptr es:[di + MOBJ_POS_T.mp_flags1], MF_JUSTHIT
jne   label_11
cmp   byte ptr ds:[si + MOBJ_T.m_reactiontime], 0
je    label_12
exit_checkmissilerange_return_0:
xor   al, al
exit_checkmissilerange:
LEAVE_MACRO 
pop   di
pop   si
pop   dx
pop   cx
pop   bx
ret   
label_11:
mov   al, 1
and   byte ptr es:[di + MOBJ_POS_T.mp_flags1], (NOT MF_JUSTHIT)
jmp   exit_checkmissilerange
label_12:
mov   es, word ptr [bp - 6]
mov   bx, word ptr [bp - 4]
mov   ax, word ptr es:[bx]
mov   word ptr [bp - 0Eh], ax
mov   ax, word ptr es:[bx + 2]
mov   cx, word ptr es:[bx + MOBJ_POS_T.mp_y + 2]
mov   word ptr [bp - 0Ch], ax
mov   ax, word ptr es:[bx + MOBJ_POS_T.mp_y + 0]
mov   es, word ptr [bp - 2]
mov   dx, word ptr es:[di + MOBJ_POS_T.mp_y + 0]
mov   bx, di
sub   dx, ax
mov   ax, dx
mov   dx, word ptr es:[bx + MOBJ_POS_T.mp_y + 2]
sbb   dx, cx
mov   cx, dx
mov   dx, word ptr es:[di]
sub   dx, word ptr [bp - 0Eh]
mov   bx, word ptr es:[bx + 2]
sbb   bx, word ptr [bp - 0Ch]
mov   word ptr [bp - 8], bx
mov   bx, ax
mov   ax, dx
mov   dx, word ptr [bp - 8]
call  dword ptr ds:[_P_AproxDistance]
mov   al, byte ptr ds:[si + MOBJ_T.m_mobjtype]
xor   ah, ah
sub   dx, 64
call  dword ptr [bp - 012h]
test  ax, ax
jne   label_13
sub   dx, 128
label_13:
cmp   byte ptr ds:[si + MOBJ_T.m_mobjtype], MT_VILE
jne   label_14
cmp   dx, (14 * 64)
jg    exit_checkmissilerange_return_0
label_14:
cmp   byte ptr ds:[si + MOBJ_T.m_mobjtype], MT_UNDEAD
jne   label_16
cmp   dx, 196
jge   label_15
jmp   exit_checkmissilerange_return_0
label_15:
sar   dx, 1
label_16:
mov   al, byte ptr ds:[si + MOBJ_T.m_mobjtype]
cmp   al, MT_CYBORG
jne   label_17
label_20:
sar   dx, 1
label_21:
cmp   dx, 200
jle   label_18
mov   dx, 200
label_18:
cmp   byte ptr ds:[si + MOBJ_T.m_mobjtype], MT_CYBORG
jne   label_19
cmp   dx, 160
jle   label_19
mov   dx, 160
label_19:
call  P_Random_
xor   ah, ah
cmp   ax, dx
jge   exit_checkmissilerange_return_1
xor   al, al
LEAVE_MACRO 
pop   di
pop   si
pop   dx
pop   cx
pop   bx
ret   
label_17:
cmp   al, MT_SPIDER
je    label_20
cmp   al, MT_SKULL
je    label_20
jmp   label_21
exit_checkmissilerange_return_1:
mov   al, 1
LEAVE_MACRO 
pop   di
pop   si
pop   dx
pop   cx
pop   bx
ret   

; todo some table?

_some_lookup_table_2:

dw OFFSET table_2_label_0
dw OFFSET table_2_label_1
dw OFFSET table_2_label_2
dw OFFSET table_2_label_3
dw OFFSET table_2_label_4
dw OFFSET table_2_label_5
dw OFFSET table_2_label_6
dw OFFSET table_2_label_7


ENDP


PROC    P_Move_ NEAR
PUBLIC  P_Move_


push  dx
push  si
push  di
push  bp
mov   bp, sp
sub   sp, 0Ah
mov   si, ax
mov   di, bx
mov   word ptr [bp - 4], cx
cmp   byte ptr ds:[si + MOBJ_T.m_movedir], DI_NODIR
je    label_22
mov   es, cx
mov   ax, word ptr es:[di]
mov   word ptr [bp - 8], ax
mov   ax, word ptr es:[di + MOBJ_POS_T.mp_y + 0]
mov   word ptr [bp - 0Ah], ax
mov   ax, word ptr es:[di + MOBJ_POS_T.mp_y + 2]
mov   word ptr [bp - 6], ax
mov   al, byte ptr ds:[si + MOBJ_T.m_mobjtype]
xor   ah, ah
imul  ax, ax, SIZEOF_MOBJINFO_T
mov   cx, word ptr es:[di + 2]
mov   dl, byte ptr ds:[si + MOBJ_T.m_movedir]
mov   bx, ax
mov   al, byte ptr ds:[bx + (OFFSET _mobjinfo + MOBJINFO_T.mobjinfo_speed)]
add   bx, (OFFSET _mobjinfo + MOBJINFO_T.mobjinfo_speed)
xor   ah, ah
cmp   dl, DI_SOUTHEAST
ja    label_24
xor   dh, dh
mov   bx, dx
add   bx, dx
jmp   word ptr cs:[bx + OFFSET _some_lookup_table_2]
label_22:
jmp   label_23
table_2_label_0:
add   cx, ax
label_24:
push  word ptr [bp - 6]
push  word ptr [bp - 0Ah]
mov   bx, di
push  cx
mov   ax, si
push  word ptr [bp - 8]
mov   cx, word ptr [bp - 4]
call  dword ptr ds:[_P_TryMove]
test  al, al
jne   label_25
mov   es, word ptr [bp - 4]
test  byte ptr es:[di + MOBJ_POS_T.mp_flags1 + 1], (MF_FLOAT SHR 8)
je    jump_to_label_28
mov   bx, OFFSET _floatok
cmp   byte ptr ds:[bx], 0
je    jump_to_label_28
mov   bx, OFFSET _tmfloorz
mov   dx, word ptr ds:[bx]
xor   dh, dh
mov   ax, word ptr ds:[bx]
and   dl, 7
sar   ax, 3
shl   dx, 13
cmp   ax, word ptr es:[di + MOBJ_POS_T.mp_z + 2]
jg    label_29
jne   label_30
cmp   dx, word ptr es:[di + MOBJ_POS_T.mp_z + 0]
jbe   label_30
label_29:
add   word ptr es:[di + MOBJ_POS_T.mp_z + 2], FLOATSPEED_HIGHBITS
label_27:
mov   es, word ptr [bp - 4]
mov   al, 1
or    byte ptr es:[di + MOBJ_POS_T.mp_flags2], MF_INFLOAT
exit_p_move:
LEAVE_MACRO 
pop   di
pop   si
pop   dx
ret   
label_23:
xor   al, al
jmp   exit_p_move
table_2_label_1:
mov   dx, 47000
mul   dx
add   word ptr [bp - 8], ax
adc   cx, dx
add   word ptr [bp - 0Ah], ax
adc   word ptr [bp - 6], dx
jmp   label_24
table_2_label_2:
add   word ptr [bp - 6], ax
jmp   label_24
label_25:
jmp   label_26
table_2_label_3:
mov   dx, 47000
mul   dx
sub   word ptr [bp - 8], ax
sbb   cx, dx
add   word ptr [bp - 0Ah], ax
adc   word ptr [bp - 6], dx
jmp   label_24
jump_to_label_28:
jmp   label_28
table_2_label_4:
sub   word ptr [bp - 8], 0
sbb   cx, ax
jmp   label_24
table_2_label_5:
mov   dx, 47000
mul   dx
sub   word ptr [bp - 8], ax
sbb   cx, dx
sub   word ptr [bp - 0Ah], ax
sbb   word ptr [bp - 6], dx
jmp   label_24
table_2_label_6:
sub   word ptr [bp - 0Ah], 0
sbb   word ptr [bp - 6], ax
jmp   label_24
label_30:
sub   word ptr es:[di + MOBJ_POS_T.mp_z + 2], FLOATSPEED_HIGHBITS
jmp   label_27
table_2_label_7:
mov   dx, 47000
mul   dx
add   word ptr [bp - 8], ax
adc   cx, dx
sub   word ptr [bp - 0Ah], ax
sbb   word ptr [bp - 6], dx
jmp   label_24
label_28:
mov   bx, OFFSET _numspechit
cmp   word ptr ds:[bx], 0
je    label_23
mov   bx, SIZEOF_THINKER_T
lea   ax, ds:[si - (OFFSET _thinkerlist + THINKER_T.t_data)]
xor   dx, dx
div   bx
mov   byte ptr [bp - 2], 0
mov   byte ptr ds:[si + MOBJ_T.m_movedir], DI_NODIR
mov   di, ax
label_32:
mov   bx, OFFSET _numspechit
mov   ax, word ptr ds:[bx]
mov   dx, ax
dec   dx
mov   word ptr ds:[bx], dx
test  ax, ax
je    label_31
mov   bx, dx
mov   cx, di
add   bx, dx
mov   ax, si
mov   dx, word ptr ds:[bx + _spechit]
xor   bx, bx
call  P_UseSpecialLine_
test  al, al
je    label_32
mov   byte ptr [bp - 2], 1
jmp   label_32
label_31:
mov   al, byte ptr [bp - 2]
LEAVE_MACRO 
pop   di
pop   si
pop   dx
ret   
label_26:
mov   es, word ptr [bp - 4]
and   byte ptr es:[di + MOBJ_POS_T.mp_flags2], (NOT MF_INFLOAT)
test  byte ptr es:[di + MOBJ_POS_T.mp_flags1 + 1], (MF_FLOAT SHR 8)
jne   exit_p_move_return_1
mov   ax, word ptr ds:[si + MOBJ_T.m_floorz]
sar   ax, 3
mov   word ptr es:[di + MOBJ_POS_T.mp_z + 2], ax
mov   ax, word ptr ds:[si + MOBJ_T.m_floorz]
and   ax, 7
shl   ax, 13
mov   word ptr es:[di + MOBJ_POS_T.mp_z + 0], ax
exit_p_move_return_1:
mov   al, 1
LEAVE_MACRO 
pop   di
pop   si
pop   dx
ret   

ENDP


PROC    P_TryWalk_ NEAR
PUBLIC  P_TryWalk_

push  si
mov   si, ax
call  P_Move_
test  al, al
jne   label_37
pop   si
ret   
label_37:
call  P_Random_
mov   bl, al
and   bl, 15
xor   bh, bh
mov   al, 1
mov   word ptr ds:[si + MOBJ_T.m_movecount], bx
pop   si
ret   

ENDP


PROC    P_NewChaseDir_ NEAR
PUBLIC  P_NewChaseDir_

push  dx
push  si
push  di
push  bp
mov   bp, sp
sub   sp, 016h
mov   si, ax
mov   di, bx
mov   word ptr [bp - 6], cx
mov   es, cx
mov   ax, word ptr es:[di]
mov   word ptr [bp - 012h], ax
mov   ax, word ptr es:[di + 2]
mov   word ptr [bp - 0Eh], ax
mov   ax, word ptr es:[di + MOBJ_POS_T.mp_y + 0]
mov   word ptr [bp - 010h], ax
mov   al, byte ptr ds:[si + MOBJ_T.m_movedir]
mov   byte ptr [bp - 2], al
imul  ax, word ptr ds:[si + MOBJ_T.m_targetRef], SIZEOF_THINKER_T
mov   bx, SIZEOF_THINKER_T
xor   dx, dx
div   bx
imul  dx, ax, SIZEOF_MOBJ_POS_T
mov   ax, MOBJPOSLIST_6800_SEGMENT
mov   cx, word ptr es:[di + MOBJ_POS_T.mp_y + 2]
mov   es, ax
mov   al, byte ptr [bp - 2]
cbw  
mov   bx, ax
mov   al, byte ptr ds:[bx + _opposite] ; todo make cs?
mov   bx, dx
mov   byte ptr [bp - 4], al
mov   ax, word ptr es:[bx]
sub   ax, word ptr [bp - 012h]
mov   word ptr [bp - 0Ah], ax
mov   ax, word ptr es:[bx + 2]
sbb   ax, word ptr [bp - 0Eh]
mov   word ptr [bp - 8], ax
mov   ax, word ptr es:[bx + MOBJ_POS_T.mp_y + 0]
sub   ax, word ptr [bp - 010h]
mov   word ptr [bp - 0Ch], ax
mov   ax, word ptr [bp - 8]
mov   dx, word ptr es:[bx + MOBJ_POS_T.mp_y + 2]
sbb   dx, cx
cmp   ax, 10  ; 10 * fracbits
jg    label_38
je    label_39
jump_to_label_40:
jmp   label_40
label_39:
cmp   word ptr [bp - 0Ah], 0
jbe   jump_to_label_40
label_38:
mov   byte ptr [bp - 015h], 0
label_75:
cmp   dx, -10  ; -10 * fracbits
jge   label_41
jmp   label_42
label_41:
cmp   dx, 10
jg    label_43
je    label_44
jump_to_label_45:
jmp   label_45
label_44:
cmp   word ptr [bp - 0Ch], 0
jbe   jump_to_label_45
label_43:
mov   byte ptr [bp - 014h], 2
label_48:
cmp   byte ptr [bp - 015h], 8
je    label_46
cmp   byte ptr [bp - 014h], 8
je    label_46
test  dx, dx
jge   label_49
jmp   label_50
label_49:
xor   bx, bx
label_51:
mov   ax, bx
add   ax, bx
cmp   word ptr [bp - 8], 0
jg    label_52
je    label_53
jump_to_label_54:
jmp   label_54
label_53:
cmp   word ptr [bp - 0Ah], 0
jbe   jump_to_label_54
label_52:
mov   bx, 1
label_55:
add   bx, ax
mov   al, byte ptr ds:[bx + _diags]
mov   bl, al
mov   byte ptr ds:[si + MOBJ_T.m_movedir], al
mov   al, byte ptr [bp - 4]
xor   bh, bh
cbw  
cmp   bx, ax
je    label_46
jmp   label_47
label_46:
call  P_Random_
cmp   al, 200
ja    label_63
jmp   label_56
label_63:
mov   al, byte ptr [bp - 015h]
mov   ah, byte ptr [bp - 014h]
mov   byte ptr [bp - 015h], ah
mov   byte ptr [bp - 014h], al
label_65:
mov   al, byte ptr [bp - 015h]
cmp   al, byte ptr [bp - 4]
jne   label_72
mov   byte ptr [bp - 015h], 8
label_72:
mov   al, byte ptr [bp - 014h]
cmp   al, byte ptr [bp - 4]
jne   label_710
mov   byte ptr [bp - 014h], 8
label_710:
mov   al, byte ptr [bp - 015h]
cmp   al, 8
jne   jump_to_label_70
label_78:
mov   al, byte ptr [bp - 014h]
cmp   al, 8
jne   jump_to_label_73
label_76:
mov   al, byte ptr [bp - 2]
cmp   al, 8
je    label_720
mov   cx, word ptr [bp - 6]
mov   bx, di
mov   byte ptr ds:[si + MOBJ_T.m_movedir], al
mov   ax, si
call  P_TryWalk_
test  al, al
jne   exit_p_newchasedir
label_720:
call  P_Random_
test  al, 1
je    jump_to_label_57
xor   dl, dl
label_67:
cmp   dl, byte ptr [bp - 4]
jne   jump_to_label_58
label_77:
inc   dl
cmp   dl, 7
jle   label_67
label_71:
mov   al, byte ptr [bp - 4]
cmp   al, 8
jne   jump_to_label_59
mov   byte ptr ds:[si + MOBJ_T.m_movedir], DI_NODIR
exit_p_newchasedir:
LEAVE_MACRO 
pop   di
pop   si
pop   dx
ret   
label_40:
cmp   ax, -10  ; (neg 10 * fracunit)
jl    label_74
mov   byte ptr [bp - 015h], 8
jmp   label_75
label_74:
mov   byte ptr [bp - 015h], 4
jmp   label_75
label_42:
mov   byte ptr [bp - 014h], 6
jmp   label_48
label_45:
mov   byte ptr [bp - 014h], 8
jmp   label_48
jump_to_label_70:
jmp   label_70
label_50:
mov   bx, 1
jmp   label_51
jump_to_label_73:
jmp   label_73
label_54:
xor   bx, bx
jmp   label_55
label_47:
mov   cx, word ptr [bp - 6]
mov   bx, di
mov   ax, si
call  P_TryWalk_
test  al, al
jne   exit_p_newchasedir
jmp   label_46
jump_to_label_57:
jmp   label_57
jump_to_label_58:
jmp   label_58
jump_to_label_59:
jmp   label_59
label_56:
mov   ax, word ptr [bp - 0Ch]
or    dx, dx
jge   label_60
neg   ax
adc   dx, 0
neg   dx
label_60:
mov   cx, ax
mov   bx, dx
mov   ax, word ptr [bp - 0Ah]
mov   dx, word ptr [bp - 8]
or    dx, dx
jge   label_61
neg   ax
adc   dx, 0
neg   dx
label_61:
cmp   bx, dx
jle   label_62
jump_to_label_63:
jmp   label_63
label_62:
je    label_64
jmp   label_65
label_64:
cmp   cx, ax
ja    jump_to_label_63
jmp   label_65
label_70:
mov   cx, word ptr [bp - 6]
mov   bx, di
mov   byte ptr ds:[si + MOBJ_T.m_movedir], al
mov   ax, si
call  P_TryWalk_
test  al, al
je    label_66
jump_to_exit_p_newchasedir:
jmp   exit_p_newchasedir
label_66:
jmp   label_78
label_73:
mov   cx, word ptr [bp - 6]
mov   bx, di
mov   byte ptr ds:[si + MOBJ_T.m_movedir], al
mov   ax, si
call  P_TryWalk_
test  al, al
jne   jump_to_exit_p_newchasedir
jmp   label_76
label_58:
mov   cx, word ptr [bp - 6]
mov   bx, di
mov   ax, si
mov   byte ptr ds:[si + MOBJ_T.m_movedir], dl
call  P_TryWalk_
test  al, al
jne   jump_to_exit_p_newchasedir
jmp   label_77
label_57:
mov   dl, DI_SOUTHEAST
label_68:
cmp   dl, byte ptr [bp - 4]
jne   label_69
label_79:
dec   dl
cmp   dl, (DI_EAST-1)  ; 0FFh
jne   label_68
jmp   label_71
label_69:
mov   cx, word ptr [bp - 6]
mov   bx, di
mov   ax, si
mov   byte ptr ds:[si + MOBJ_T.m_movedir], dl
call  P_TryWalk_
test  al, al
je    label_79
jmp   exit_p_newchasedir
label_59:
mov   cx, word ptr [bp - 6]
mov   bx, di
mov   byte ptr ds:[si + MOBJ_T.m_movedir], al
mov   ax, si
call  P_TryWalk_
test  al, al
jne   jump_to_exit_p_newchasedir
mov   byte ptr ds:[si + MOBJ_T.m_movedir], DI_NODIR
LEAVE_MACRO 
pop   di
pop   si
pop   dx
ret   

ENDP


PROC    P_LookForPlayers_ NEAR
PUBLIC  P_LookForPlayers_

push  bx
push  cx
push  si
push  di
push  bp
mov   bp, sp
sub   sp, 6
mov   di, ax
mov   byte ptr [bp - 2], dl
mov   bx, OFFSET _player + PLAYER_T.player_health
cmp   word ptr ds:[bx], 0
jg    do_look_for_players
exit_look_for_players_return_0:
xor   al, al
exit_look_for_players:
LEAVE_MACRO 
pop   di
pop   si
pop   cx
pop   bx
ret   
do_look_for_players:
mov   bx, SIZEOF_THINKER_T
sub   ax, (OFFSET _thinkerlist + THINKER_T.t_data)
xor   dx, dx
div   bx
imul  si, ax, SIZEOF_MOBJ_POS_T
mov   bx, OFFSET _playerMobj_pos
mov   cx, word ptr ds:[bx]
mov   bx, OFFSET _playerMobj
mov   word ptr [bp - 4], MOBJPOSLIST_6800_SEGMENT
mov   dx, word ptr ds:[bx]
mov   bx, si
mov   ax, di
call  dword ptr ds:[_P_CheckSightTemp]
test  al, al
je    exit_look_for_players
cmp   byte ptr [bp - 2], 0
je    label_80
look_set_target_player:
mov   bx, OFFSET _playerMobjRef
mov   ax, word ptr ds:[bx]
mov   word ptr ds:[di + MOBJ_T.m_targetRef], ax
mov   al, 1
LEAVE_MACRO 
pop   di
pop   si
pop   cx
pop   bx
ret   
label_80:
mov   bx, OFFSET _playerMobj_pos
les   ax, dword ptr ds:[bx]
mov   bx, ax
push  word ptr es:[bx + MOBJ_POS_T.mp_y + 2]
push  word ptr es:[bx + MOBJ_POS_T.mp_y + 0]
mov   bx, OFFSET _playerMobj_pos
les   ax, dword ptr ds:[bx]
mov   bx, ax
push  word ptr es:[bx + 2]
push  word ptr es:[bx]
mov   es, word ptr [bp - 4]
mov   bx, word ptr es:[si + MOBJ_POS_T.mp_y + 0]
mov   cx, word ptr es:[si + MOBJ_POS_T.mp_y + 2]
mov   ax, word ptr es:[si]
mov   dx, word ptr es:[si + 2]
call  R_PointToAngle2_
mov   es, word ptr [bp - 4]
mov   cx, ax
mov   bx, si
mov   ax, dx
sub   cx, word ptr es:[si + MOBJ_POS_T.mp_angle+0]
sbb   ax, word ptr es:[bx + MOBJ_POS_T.mp_angle+2]
cmp   ax, ANG90_HIGHBITS
ja    lookforplayers_above_ang90
jne   look_set_target_player
test  cx, cx
jbe   look_set_target_player
lookforplayers_above_ang90:
cmp   ax, ANG270_HIGHBITS
jae   look_set_target_player
mov   bx, OFFSET _playerMobj_pos
les   dx, dword ptr ds:[bx]
mov   bx, dx
mov   ax, word ptr es:[bx + MOBJ_POS_T.mp_y + 0]
mov   cx, word ptr es:[bx + MOBJ_POS_T.mp_y + 2]
mov   es, word ptr [bp - 4]
mov   word ptr [bp - 6], ax
mov   ax, word ptr es:[si + MOBJ_POS_T.mp_y + 0]
mov   bx, si
sub   word ptr [bp - 6], ax
sbb   cx, word ptr es:[bx + MOBJ_POS_T.mp_y + 2]
mov   bx, OFFSET _playerMobj_pos
les   dx, dword ptr ds:[bx]
mov   bx, dx
mov   ax, word ptr es:[bx]
mov   dx, word ptr es:[bx + 2]
mov   es, word ptr [bp - 4]
mov   bx, si
sub   ax, word ptr es:[si]
sbb   dx, word ptr es:[bx + 2]
mov   bx, word ptr [bp - 6]
call  dword ptr ds:[_P_AproxDistance]
cmp   dx, MELEERANGE
jle   label_81
jmp   exit_look_for_players_return_0
label_81:
je    label_82
jump_to_look_set_target_player:
jmp   look_set_target_player
label_82:
test  ax, ax
jbe   jump_to_look_set_target_player
xor   al, al
LEAVE_MACRO 
pop   di
pop   si
pop   cx
pop   bx
ret   

ENDP


PROC    A_KeenDie_ NEAR
PUBLIC  A_KeenDie_

push  dx
push  si
push  bp
mov   bp, sp
sub   sp, 2
mov   si, ax
mov   es, cx
mov   cx, SIZEOF_THINKER_T
mov   al, byte ptr ds:[si + MOBJ_T.m_mobjtype]
xor   dx, dx
mov   byte ptr [bp - 2], al
lea   ax, ds:[si - (OFFSET _thinkerlist + THINKER_T.t_data)]
div   cx
and   byte ptr es:[bx + MOBJ_POS_T.mp_flags1], (NOT MF_SOLID)
mov   bx, OFFSET _thinkerlist + THINKER_T.t_next
mov   cx, ax
mov   ax, word ptr ds:[bx]
test  ax, ax
je    label_33
label_34:
imul  bx, ax, SIZEOF_THINKER_T
mov   dx, word ptr ds:[bx + _thinkerlist]
xor   dl, dl
and   dh, (TF_FUNCBITS SHR 8)
cmp   dx, TF_MOBJTHINKER_HIGHBITS
je    label_35
label_36:
imul  bx, ax, SIZEOF_THINKER_T
mov   ax, word ptr ds:[bx + OFFSET _thinkerlist + THINKER_T.t_next]
test  ax, ax
jne   label_34
label_33:
mov   dx, DOOR_OPEN
mov   ax, TAG_666
call  EV_DoDoor_
exit_keen_die:
LEAVE_MACRO 
pop   si
pop   dx
ret   
label_35:
add   bx, (OFFSET _thinkerlist + THINKER_T.t_data)
cmp   ax, cx
je    label_36
mov   dl, byte ptr ds:[bx + MOBJ_T.m_mobjtype]
cmp   dl, byte ptr [bp - 2]
jne   label_36
cmp   word ptr ds:[bx + MOBJ_T.m_health], 0
jg    exit_keen_die
jmp   label_36

ENDP


PROC    A_Look_ NEAR
PUBLIC  A_Look_

push  dx
push  si
push  di
push  bp
mov   bp, sp
sub   sp, 8
mov   si, ax
mov   word ptr [bp - 8], GETSEESTATEADDR
mov   ax, SECTOR_SOUNDTRAVERSED_SEGMENT
mov   di, word ptr ds:[si + 4]
mov   byte ptr ds:[si + MOBJ_T.m_threshold], 0
mov   es, ax
mov   word ptr [bp - 6], INFOFUNCLOADSEGMENT
cmp   byte ptr es:[di], 0
jne   label_83
jump_to_label_84:
jmp   label_84
label_83:
mov   di, OFFSET _playerMobjRef
mov   ax, word ptr ds:[di]
test  ax, ax
je    jump_to_label_84
imul  di, ax, SIZEOF_MOBJ_POS_T
mov   dx, MOBJPOSLIST_6800_SEGMENT
mov   es, dx
imul  dx, ax, SIZEOF_THINKER_T
add   dx, (OFFSET _thinkerlist + THINKER_T.t_data)
test  byte ptr es:[di + MOBJ_POS_T.mp_flags1], MF_SHOOTABLE
je    jump_to_label_84
mov   word ptr ds:[si + MOBJ_T.m_targetRef], ax
mov   es, cx
test  byte ptr es:[bx + MOBJ_POS_T.mp_flags1], MF_AMBUSH
je    label_85
mov   cx, di
mov   ax, si
call  dword ptr ds:[_P_CheckSightTemp]
test  al, al
je    label_84
label_85:
mov   al, byte ptr ds:[si + MOBJ_T.m_mobjtype]
xor   ah, ah
imul  ax, ax, SIZEOF_MOBJINFO_T
mov   word ptr [bp - 2], 0
mov   bx, ax
mov   word ptr [bp - 4], ax
mov   al, byte ptr ds:[bx + OFFSET _mobjinfo + MOBJINFO_T.mobjinfo_seesound]
add   bx, OFFSET _mobjinfo + MOBJINFO_T.mobjinfo_seesound
test  al, al
je    label_86
cmp   al, SFX_POSIT1
jae   label_87
label_89:
mov   al, byte ptr ds:[si + MOBJ_T.m_mobjtype]
xor   ah, ah
imul  ax, ax, SIZEOF_MOBJINFO_T
mov   bx, ax
add   bx, OFFSET _mobjinfo + MOBJINFO_T.mobjinfo_seesound
mov   bl, byte ptr ds:[bx]
xor   bh, bh
label_93:
mov   al, byte ptr ds:[si + MOBJ_T.m_mobjtype]
cmp   al, MT_SPIDER
jne   label_90
label_91:
mov   dl, bl
xor   ax, ax
label_92:
xor   dh, dh
call  S_StartSound_
label_86:
mov   al, byte ptr ds:[si + MOBJ_T.m_mobjtype]
xor   ah, ah
call  dword ptr [bp - 8]
mov   dx, ax
mov   ax, si
call  P_SetMobjState_
exit_a_look:
LEAVE_MACRO 
pop   di
pop   si
pop   dx
ret   
label_84:
mov   ax, si
xor   dx, dx
call  P_LookForPlayers_
test  al, al
je    exit_a_look
jmp   label_85
label_87:
cmp   al, SFX_POSIT3
jbe   label_88
cmp   al, sfx_bgsit2
ja    label_89
call  P_Random_
mov   dl, al
xor   dh, dh
mov   ax, dx
mov   bx, dx
sar   ax, 0Fh ; todo no
xor   bx, ax
sub   bx, ax
and   bx, 1
xor   bx, ax
sub   bx, ax
add   bx, SFX_BGSIT1
jmp   label_93
label_88:
call  P_Random_
xor   ah, ah
mov   bx, 3
cwd   
idiv  bx
mov   bx, dx
add   bx, SFX_POSIT1
jmp   label_93
label_90:
cmp   al, MT_CYBORG
je    label_91
mov   dl, bl
mov   ax, si
jmp   label_92

ENDP


PROC    A_Chase_ NEAR
PUBLIC  A_Chase_

push  dx
push  si
push  di
push  bp
mov   bp, sp
sub   sp, 014h
mov   si, ax
mov   di, bx
mov   word ptr [bp - 2], cx
mov   ax, word ptr ds:[si + MOBJ_T.m_targetRef]
imul  dx, ax, SIZEOF_THINKER_T
imul  cx, ax, SIZEOF_MOBJ_POS_T
mov   word ptr [bp - 4], MOBJPOSLIST_6800_SEGMENT
mov   word ptr [bp - 010h], GETMISSILESTATEADDR
mov   word ptr [bp - 0Eh], INFOFUNCLOADSEGMENT
mov   word ptr [bp - 0Ch], GETMELEESTATEADDR
mov   word ptr [bp - 0Ah], INFOFUNCLOADSEGMENT
mov   word ptr [bp - 014h], GETACTIVESOUNDADDR
mov   word ptr [bp - 012h], INFOFUNCLOADSEGMENT
mov   word ptr [bp - 8], GETATTACKSOUNDADDR
mov   word ptr [bp - 6], INFOFUNCLOADSEGMENT
add   dx, (OFFSET _thinkerlist + THINKER_T.t_data)
cmp   byte ptr ds:[si + MOBJ_T.m_reactiontime], 0
je    label_94
jmp   label_96
label_94:
cmp   byte ptr ds:[si + MOBJ_T.m_threshold], 0
je    label_95
test  ax, ax
je    label_99
jmp   label_100
label_99:
mov   byte ptr ds:[si + MOBJ_T.m_threshold], 0
label_95:
cmp   byte ptr ds:[si + MOBJ_T.m_movedir], DI_NODIR
jae   label_98
mov   es, word ptr [bp - 2]
mov   byte ptr es:[di + MOBJ_POS_T.mp_angle + 2], 0
mov   word ptr es:[di + MOBJ_POS_T.mp_angle + 0], 0
and   byte ptr es:[di + MOBJ_POS_T.mp_angle+3], 0E0h
mov   al, byte ptr ds:[si + MOBJ_T.m_movedir]
xor   ah, ah
mov   bx, ax
add   bx, ax
mov   ax, word ptr es:[di + MOBJ_POS_T.mp_angle+2]
sub   ax, word ptr ds:[bx + _movedirangles]
test  ax, ax
jle   label_97
sub   word ptr es:[di + MOBJ_POS_T.mp_angle+2], (ANG90_HIGHBITS / 2)
label_98:
test  dx, dx
je    label_106
mov   es, word ptr [bp - 4]
mov   bx, cx
test  byte ptr es:[bx + MOBJ_POS_T.mp_flags1], MF_SHOOTABLE
je    label_106
mov   es, word ptr [bp - 2]
test  byte ptr es:[di + MOBJ_POS_T.mp_flags1], MF_JUSTATTACKED
je    label_107
and   byte ptr es:[di + MOBJ_POS_T.mp_flags1], (NOT MF_JUSTATTACKED)
cmp   byte ptr ds:[_gameskill], sk_nightmare
je    exit_a_chase
cmp   byte ptr ds:[_fastparm], 0
je    label_110
exit_a_chase:
LEAVE_MACRO 
pop   di
pop   si
pop   dx
ret   
label_96:
dec   byte ptr ds:[si + MOBJ_T.m_reactiontime]
jmp   label_94
label_100:
mov   bx, dx
cmp   word ptr ds:[bx + MOBJ_T.m_health], 0
jle   label_99
dec   byte ptr ds:[si + MOBJ_T.m_threshold]
jmp   label_95
label_97:
jge   label_98
add   byte ptr es:[di + MOBJ_POS_T.mp_angle+3], (ANG90_HIGHBITS SHR 9)
jmp   label_98
label_106:
mov   dx, 1
mov   ax, si
call  P_LookForPlayers_
test  al, al
jne   exit_a_chase
mov   al, byte ptr ds:[si + MOBJ_T.m_mobjtype]
xor   ah, ah
imul  ax, ax, SIZEOF_MOBJINFO_T
mov   di, ax
mov   ax, si
mov   dx, word ptr ds:[di + _mobjinfo]
add   di, OFFSET _mobjinfo
call  P_SetMobjState_
jmp   exit_a_chase
label_110:
mov   bx, di
mov   cx, es
mov   ax, si
call  P_NewChaseDir_
jmp   exit_a_chase
label_107:
mov   al, byte ptr ds:[si + MOBJ_T.m_mobjtype]
xor   ah, ah
call  dword ptr [bp - 0Ch]
test  ax, ax
je    label_108
mov   ax, si
call  P_CheckMeleeRange_
test  al, al
jne   label_109
label_108:
mov   al, byte ptr ds:[si + MOBJ_T.m_mobjtype]
xor   ah, ah
call  dword ptr [bp - 010h]
test  ax, ax
je    label_104
cmp   byte ptr ds:[_gameskill], sk_nightmare
jae   jump_to_label_103
cmp   byte ptr ds:[_fastparm], 0
jne   jump_to_label_103
cmp   word ptr ds:[si + MOBJ_T.m_movecount], 0
je    label_103
label_104:
dec   word ptr ds:[si + MOBJ_T.m_movecount]
cmp   word ptr ds:[si + MOBJ_T.m_movecount], 0
jl    label_101
mov   cx, word ptr [bp - 2]
mov   bx, di
mov   ax, si
call  P_Move_
test  al, al
jne   label_102
label_101:
mov   cx, word ptr [bp - 2]
mov   bx, di
mov   ax, si
call  P_NewChaseDir_
label_102:
mov   al, byte ptr ds:[si + MOBJ_T.m_mobjtype]
xor   ah, ah
call  dword ptr [bp - 014h]
mov   dl, al
test  al, al
jne   label_105
jump_to_exit_a_chase:
jmp   exit_a_chase
label_105:
call  P_Random_
cmp   al, 3
jae   jump_to_exit_a_chase
mov   ax, si
xor   dh, dh
call  S_StartSound_
LEAVE_MACRO 
pop   di
pop   si
pop   dx
ret   
jump_to_label_103:
jmp   label_103
label_109:
mov   al, byte ptr ds:[si + MOBJ_T.m_mobjtype]
xor   ah, ah
call  dword ptr [bp - 8]
mov   dl, al
mov   ax, si
xor   dh, dh
call  S_StartSound_
mov   al, byte ptr ds:[si + MOBJ_T.m_mobjtype]
xor   ah, ah
call  dword ptr [bp - 0Ch]
mov   dx, ax
mov   ax, si
call  P_SetMobjState_
LEAVE_MACRO 
pop   di
pop   si
pop   dx
ret   
label_103:
mov   ax, si
call  P_CheckMissileRange_
test  al, al
je    label_104
mov   al, byte ptr ds:[si + MOBJ_T.m_mobjtype]
xor   ah, ah
call  dword ptr [bp - 010h]
mov   dx, ax
mov   ax, si
call  P_SetMobjState_
mov   es, word ptr [bp - 2]
or    byte ptr es:[di + MOBJ_POS_T.mp_flags1], MF_JUSTATTACKED
LEAVE_MACRO 
pop   di
pop   si
pop   dx
ret   

ENDP


PROC    A_FaceTarget_ NEAR
PUBLIC  A_FaceTarget_

push  bx
push  cx
push  dx
push  si
push  di
push  bp
mov   bp, sp
sub   sp, 4
mov   bx, ax
cmp   word ptr ds:[bx + MOBJ_T.m_targetRef], 0
je    exit_a_facetarget
mov   cx, SIZEOF_THINKER_T
sub   ax, (OFFSET _thinkerlist + THINKER_T.t_data)
xor   dx, dx
div   cx
imul  di, ax, SIZEOF_MOBJ_POS_T
mov   ax, MOBJPOSLIST_6800_SEGMENT
mov   es, ax
and   byte ptr es:[di + MOBJ_POS_T.mp_flags1], (NOT MF_AMBUSH)
mov   si, di
imul  di, word ptr ds:[bx + MOBJ_T.m_targetRef], SIZEOF_MOBJ_POS_T
mov   word ptr [bp - 2], ax
mov   bx, di
test  byte ptr es:[di + MOBJ_POS_T.mp_flags2], 4
je    label_111
mov   word ptr [bp - 4], 1
label_113:
push  word ptr es:[bx + MOBJ_POS_T.mp_y + 2]
push  word ptr es:[bx + MOBJ_POS_T.mp_y + 0]
push  word ptr es:[bx + 2]
push  word ptr es:[bx]
mov   es, word ptr [bp - 2]
mov   bx, word ptr es:[si + MOBJ_POS_T.mp_y + 0]
mov   cx, word ptr es:[si + MOBJ_POS_T.mp_y + 2]
mov   ax, word ptr es:[si]
mov   dx, word ptr es:[si + 2]
call  R_PointToAngle2_
mov   es, word ptr [bp - 2]
mov   word ptr es:[si + MOBJ_POS_T.mp_angle + 0], ax
mov   word ptr es:[si + MOBJ_POS_T.mp_angle + 2], dx
cmp   byte ptr [bp - 4], 0
jne   label_112
exit_a_facetarget:
LEAVE_MACRO 
pop   di
pop   si
pop   dx
pop   cx
pop   bx
ret   
label_111:
mov   word ptr [bp - 4], 0
jmp   label_113
label_112:
call  P_Random_
mov   dl, al
call  P_Random_
mov   bl, al
xor   dh, dh
xor   bh, bh
sub   dx, bx
mov   bx, dx
mov   es, word ptr [bp - 2]
shl   bx, 5
add   word ptr es:[si + MOBJ_POS_T.mp_angle + 2], bx
LEAVE_MACRO 
pop   di
pop   si
pop   dx
pop   cx
pop   bx
ret   

ENDP


PROC    A_PosAttack_ NEAR
PUBLIC  A_PosAttack_

push  bx
push  cx
push  dx
push  si
push  di
push  bp
mov   bp, sp
sub   sp, 2
mov   si, ax
cmp   word ptr ds:[si + MOBJ_T.m_targetRef], 0
jne   do_a_posattack
LEAVE_MACRO 
pop   di
pop   si
pop   dx
pop   cx
pop   bx
ret   
do_a_posattack:
mov   bx, SIZEOF_THINKER_T
sub   ax, (OFFSET _thinkerlist + THINKER_T.t_data)
xor   dx, dx
div   bx
imul  bx, ax, SIZEOF_MOBJ_POS_T
mov   ax, si
mov   dx, MOBJPOSLIST_6800_SEGMENT
call  A_FaceTarget_
mov   es, dx
mov   cx, word ptr es:[bx + MOBJ_POS_T.mp_angle + 2]
mov   ax, si
shr   cx, 3
mov   bx, MISSILERANGE
mov   dx, cx
call  dword ptr ds:[_P_AimLineAttack]
mov   bx, ax
mov   word ptr [bp - 2], dx
mov   dx, 1
mov   ax, si
call  S_StartSound_
call  P_Random_
mov   dl, al
call  P_Random_
xor   dh, dh
xor   ah, ah
mov   di, 5
sub   dx, ax
call  P_Random_
add   dx, dx
xor   ah, ah
add   cx, dx
cwd   
idiv  di
inc   dx
mov   ax, dx
shl   ax, 2
sub   ax, dx
and   ch, (FINEMASK SHR 8)
push  ax
mov   dx, cx
push  word ptr [bp - 2]
mov   ax, si
push  bx
mov   bx, MISSILERANGE
call  dword ptr ds:[_P_LineAttack]
LEAVE_MACRO 
pop   di
pop   si
pop   dx
pop   cx
pop   bx
ret   

ENDP


PROC    A_SPosAttack_ NEAR
PUBLIC  A_SPosAttack_

push  bx
push  cx
push  dx
push  si
push  di
push  bp
mov   bp, sp
sub   sp, 6
mov   di, ax
cmp   word ptr ds:[di + MOBJ_T.m_targetRef], 0
jne   do_asposattack
LEAVE_MACRO 
pop   di
pop   si
pop   dx
pop   cx
pop   bx
ret   
do_asposattack:
mov   si, SIZEOF_THINKER_T
sub   ax, (OFFSET _thinkerlist + THINKER_T.t_data)
xor   dx, dx
div   si
imul  si, ax, SIZEOF_MOBJ_POS_T
mov   dx, 2
mov   ax, di
call  S_StartSound_
mov   ax, di
mov   bx, MOBJPOSLIST_6800_SEGMENT
call  A_FaceTarget_
mov   es, bx
mov   ax, word ptr es:[si + MOBJ_POS_T.mp_angle + 2]
shr   ax, 3
mov   bx, MISSILERANGE
mov   word ptr [bp - 2], ax
mov   dx, ax
mov   ax, di
xor   cl, cl
call  dword ptr ds:[_P_AimLineAttack]
mov   word ptr [bp - 6], ax
mov   word ptr [bp - 4], dx
label_114:
call  P_Random_
mov   si, word ptr [bp - 2]
mov   dl, al
call  P_Random_
xor   dh, dh
xor   ah, ah
mov   bx, 5
sub   dx, ax
call  P_Random_
add   dx, dx
xor   ah, ah
add   si, dx
cwd   
idiv  bx
mov   ax, dx
inc   ax
imul  ax, ax, 3
and   si, FINEMASK
cbw  
mov   bx, MISSILERANGE
push  ax
mov   dx, si
push  word ptr [bp - 4]
mov   ax, di
push  word ptr [bp - 6]
inc   cl
call  dword ptr ds:[_P_LineAttack]
cmp   cl, 3
jl    label_114
LEAVE_MACRO 
pop   di
pop   si
pop   dx
pop   cx
pop   bx
ret   

ENDP


PROC    A_CPosAttack_ NEAR
PUBLIC  A_CPosAttack_

push  bx
push  cx
push  dx
push  si
push  di
push  bp
mov   bp, sp
sub   sp, 2
mov   si, ax
cmp   word ptr ds:[si + MOBJ_T.m_targetRef], 0
jne   do_cposattack
LEAVE_MACRO 
pop   di
pop   si
pop   dx
pop   cx
pop   bx
ret   
do_cposattack:
mov   bx, SIZEOF_THINKER_T
sub   ax, (OFFSET _thinkerlist + THINKER_T.t_data)
xor   dx, dx
div   bx
imul  bx, ax, SIZEOF_MOBJ_POS_T
mov   dx, 2
mov   ax, si
call  S_StartSound_
mov   ax, si
mov   cx, MOBJPOSLIST_6800_SEGMENT
call  A_FaceTarget_
mov   es, cx
mov   cx, word ptr es:[bx + MOBJ_POS_T.mp_angle + 2]
mov   ax, si
shr   cx, 3
mov   bx, MISSILERANGE
mov   dx, cx
call  dword ptr ds:[_P_AimLineAttack]
mov   word ptr [bp - 2], ax
mov   bx, dx
call  P_Random_
mov   dl, al
call  P_Random_
xor   dh, dh
xor   ah, ah
sub   dx, ax
mov   ax, dx
add   ax, dx
add   cx, ax
call  P_Random_
xor   ah, ah
mov   di, 5
cwd   
idiv  di
inc   dx
mov   ax, dx
shl   ax, 2
sub   ax, dx
cbw  
and   ch, (FINEMASK SHR 8)
push  ax
mov   dx, cx
push  bx
mov   ax, si
push  word ptr [bp - 2]
mov   bx, MISSILERANGE
call  dword ptr ds:[_P_LineAttack]
LEAVE_MACRO 
pop   di
pop   si
pop   dx
pop   cx
pop   bx
ret   

ENDP


PROC    A_CPosRefire_ NEAR
PUBLIC  A_CPosRefire_

push  dx
push  si
push  di
push  bp
mov   bp, sp
sub   sp, 4
mov   si, ax
call  A_FaceTarget_
mov   word ptr [bp - 4], GETSEESTATEADDR
mov   word ptr [bp - 2], INFOFUNCLOADSEGMENT
mov   dx, word ptr ds:[si + MOBJ_T.m_targetRef]
call  P_Random_
cmp   al, 40
jb    exit_a_cposrefire
test  dx, dx
je    exit_a_cposrefire
imul  di, dx, SIZEOF_THINKER_T
add   di, (OFFSET _thinkerlist + THINKER_T.t_data)
test  dx, dx
je    label_115
cmp   word ptr ds:[di + MOBJ_T.m_health], 0
jle   label_115
mov   cx, SIZEOF_THINKER_T
lea   ax, ds:[di - (OFFSET _thinkerlist + THINKER_T.t_data)]
xor   dx, dx
div   cx
imul  cx, ax, SIZEOF_MOBJ_POS_T
mov   dx, di
mov   ax, si
call  dword ptr ds:[_P_CheckSightTemp]
test  al, al
je    label_115
exit_a_cposrefire:
LEAVE_MACRO 
pop   di
pop   si
pop   dx
ret   
label_115:
mov   al, byte ptr ds:[si + MOBJ_T.m_mobjtype]
xor   ah, ah
call  dword ptr [bp - 4]
mov   dx, ax
mov   ax, si
call  P_SetMobjState_
LEAVE_MACRO 
pop   di
pop   si
pop   dx
ret   

ENDP


PROC    A_SpidRefire_ NEAR
PUBLIC  A_SpidRefire_

push  dx
push  si
push  di
push  bp
mov   bp, sp
sub   sp, 4
mov   si, ax
call  A_FaceTarget_
mov   word ptr [bp - 4], GETSEESTATEADDR
mov   word ptr [bp - 2], INFOFUNCLOADSEGMENT
mov   dx, word ptr ds:[si + MOBJ_T.m_targetRef]
call  P_Random_
cmp   al, 10
jb    exit_a_spidrefire
test  dx, dx
je    exit_a_spidrefire
imul  di, dx, SIZEOF_THINKER_T
add   di, (OFFSET _thinkerlist + THINKER_T.t_data)
test  dx, dx
je    label_116
cmp   word ptr ds:[di + MOBJ_T.m_health], 0
jle   label_116
mov   cx, SIZEOF_THINKER_T
lea   ax, ds:[di - (OFFSET _thinkerlist + THINKER_T.t_data)]
xor   dx, dx
div   cx
imul  cx, ax, SIZEOF_MOBJ_POS_T
mov   dx, di
mov   ax, si
call  dword ptr ds:[_P_CheckSightTemp]
test  al, al
je    label_116
exit_a_spidrefire:
LEAVE_MACRO 
pop   di
pop   si
pop   dx
ret   
label_116:
mov   al, byte ptr ds:[si + MOBJ_T.m_mobjtype]
xor   ah, ah
call  dword ptr [bp - 4]
mov   dx, ax
mov   ax, si
call  P_SetMobjState_
LEAVE_MACRO 
pop   di
pop   si
pop   dx
ret   

ENDP


PROC    A_BspiAttack_ NEAR
PUBLIC  A_BspiAttack_

push  dx
push  si
mov   si, ax
cmp   word ptr ds:[si + MOBJ_T.m_targetRef], 0
jne   do_a_bspiattack
pop   si
pop   dx
ret   
do_a_bspiattack:
call  A_FaceTarget_
imul  dx, word ptr ds:[si + MOBJ_T.m_targetRef], SIZEOF_THINKER_T
push  MT_ARACHPLAZ  ; todo 186
mov   ax, si
add   dx, (OFFSET _thinkerlist + THINKER_T.t_data)
call  dword ptr ds:[_P_SpawnMissile]
pop   si
pop   dx
ret   

ENDP


PROC    A_TroopAttack_ NEAR
PUBLIC  A_TroopAttack_

push  dx
push  si
mov   si, ax
cmp   word ptr ds:[si + MOBJ_T.m_targetRef], 0
jne   do_a_troopattack
pop   si
pop   dx
ret   
do_a_troopattack:
call  A_FaceTarget_
mov   ax, si
call  P_CheckMeleeRange_
test  al, al
je    do_troop_missile
mov   dx, sfx_claw
mov   ax, si
call  S_StartSound_
call  P_Random_
xor   ah, ah
mov   cx, ax
sar   cx, 0Fh  ; todo no
xor   ax, cx
sub   ax, cx
and   ax, 7
xor   ax, cx
sub   ax, cx
inc   ax
mov   cx, ax
shl   cx, 2
sub   cx, ax
imul  ax, word ptr ds:[si + MOBJ_T.m_targetRef], SIZEOF_THINKER_T
mov   bx, si
mov   dx, si
add   ax, (OFFSET _thinkerlist + THINKER_T.t_data)
call  P_DamageMobj_
pop   si
pop   dx
ret   
do_troop_missile:
imul  dx, word ptr ds:[si + MOBJ_T.m_targetRef], SIZEOF_THINKER_T
push  MT_TROOPSHOT  ; todo 186
mov   ax, si
add   dx, (OFFSET _thinkerlist + THINKER_T.t_data)
call  dword ptr ds:[_P_SpawnMissile]
pop   si
pop   dx
ret   

ENDP


PROC    A_SargAttack_ NEAR
PUBLIC  A_SargAttack_

push  bx
push  cx
push  dx
push  si
mov   si, ax
cmp   word ptr ds:[si + MOBJ_T.m_targetRef], 0
jne   do_a_sargattack
exit_a_sargattack:
pop   si
pop   dx
pop   cx
pop   bx
ret   
do_a_sargattack:
call  A_FaceTarget_
mov   ax, si
call  P_CheckMeleeRange_
test  al, al
je    exit_a_sargattack
call  P_Random_
xor   ah, ah
mov   cx, 10
cwd   
idiv  cx
imul  ax, word ptr ds:[si + MOBJ_T.m_targetRef], SIZEOF_THINKER_T
mov   cx, dx
mov   bx, si
shl   cx, 2
mov   dx, si
add   cx, 4

add   ax, (OFFSET _thinkerlist + THINKER_T.t_data)
call  P_DamageMobj_
pop   si
pop   dx
pop   cx
pop   bx
ret   

ENDP


PROC    A_HeadAttack_ NEAR
PUBLIC  A_HeadAttack_

push  dx
push  si
mov   si, ax
cmp   word ptr ds:[si + MOBJ_T.m_targetRef], 0
jne   do_head_attack
pop   si
pop   dx
ret   
do_head_attack:
call  A_FaceTarget_
mov   ax, si
call  P_CheckMeleeRange_
test  al, al
je    label_117
call  P_Random_
xor   ah, ah
mov   bx, 6
cwd   
idiv  bx
imul  ax, word ptr ds:[si + MOBJ_T.m_targetRef], SIZEOF_THINKER_T
inc   dx
mov   cx, dx
shl   cx, 2
mov   bx, si
add   cx, dx
mov   dx, si
add   cx, cx
add   ax, (OFFSET _thinkerlist + THINKER_T.t_data)
call  P_DamageMobj_
pop   si
pop   dx
ret   
label_117:
imul  dx, word ptr ds:[si + MOBJ_T.m_targetRef], SIZEOF_THINKER_T
push  MT_HEADSHOT  ; todo 186
mov   ax, si
add   dx, (OFFSET _thinkerlist + THINKER_T.t_data)
call  dword ptr ds:[_P_SpawnMissile]
pop   si
pop   dx
ret   
ENDP


PROC    A_CyberAttack_ NEAR
PUBLIC  A_CyberAttack_


push  dx
push  si
mov   si, ax
cmp   word ptr ds:[si + MOBJ_T.m_targetRef], 0
jne   label_118
pop   si
pop   dx
ret   
label_118:
call  A_FaceTarget_
imul  dx, word ptr ds:[si + MOBJ_T.m_targetRef], SIZEOF_THINKER_T
push  MT_ROCKET
mov   ax, si
add   dx, (OFFSET _thinkerlist + THINKER_T.t_data)
call  dword ptr ds:[_P_SpawnMissile]
pop   si
pop   dx
ret   

ENDP


PROC    A_BruisAttack_ NEAR
PUBLIC  A_BruisAttack_

push  dx
push  si
mov   si, ax
cmp   word ptr ds:[si + MOBJ_T.m_targetRef], 0
jne   do_a_bruisattack
pop   si
pop   dx
ret   
do_a_bruisattack:
call  P_CheckMeleeRange_
test  al, al
je    do_bruis_missile
mov   dx, sfx_claw
mov   ax, si
call  S_StartSound_
call  P_Random_
xor   ah, ah
mov   cx, ax
sar   cx, 0Fh ; todo no
xor   ax, cx
sub   ax, cx
and   ax, 7
xor   ax, cx
sub   ax, cx
inc   ax
mov   cx, ax
shl   cx, 2
add   cx, ax
imul  ax, word ptr ds:[si + MOBJ_T.m_targetRef], SIZEOF_THINKER_T
mov   bx, si
mov   dx, si
add   cx, cx
add   ax, (OFFSET _thinkerlist + THINKER_T.t_data)
call  P_DamageMobj_
pop   si
pop   dx
ret   
do_bruis_missile:
imul  dx, word ptr ds:[si + MOBJ_T.m_targetRef], SIZEOF_THINKER_T
push  MT_BRUISERSHOT ; todo 186
mov   ax, si
add   dx, (OFFSET _thinkerlist + THINKER_T.t_data)
call  dword ptr ds:[_P_SpawnMissile]
pop   si
pop   dx
ret   

ENDP


PROC    A_SkelMissile_ NEAR
PUBLIC  A_SkelMissile_

push  dx
push  si
push  di
push  bp
mov   bp, sp
sub   sp, 6
mov   si, ax
mov   word ptr [bp - 2], bx
mov   word ptr [bp - 4], cx
cmp   word ptr ds:[si + MOBJ_T.m_targetRef], 0
jne   do_a_skelmissile
LEAVE_MACRO 
pop   di
pop   si
pop   dx
ret   
do_a_skelmissile:
call  A_FaceTarget_
mov   es, cx
add   word ptr es:[bx + MOBJ_POS_T.mp_z + 2], 16
imul  dx, word ptr ds:[si + MOBJ_T.m_targetRef], SIZEOF_THINKER_T
push  MT_TRACER  ;todo 186
mov   ax, si
add   dx, (OFFSET _thinkerlist + THINKER_T.t_data)
mov   di, OFFSET _setStateReturn_pos
call  dword ptr ds:[_P_SpawnMissile]
mov   bx, OFFSET _setStateReturn
mov   ax, word ptr ds:[di + 2]
mov   cx, word ptr ds:[bx]
mov   bx, word ptr ds:[di]
mov   es, word ptr [bp - 4]
mov   di, word ptr [bp - 2]
sub   word ptr es:[di + MOBJ_POS_T.mp_z + 2], 16
mov   word ptr [bp - 6], ax
mov   ax, word ptr ds:[si + MOBJ_T.m_targetRef]
mov   si, cx
mov   dx, word ptr ds:[si + MOBJ_T.m_momx + 0]
mov   si, word ptr ds:[si + MOBJ_T.m_momx + 2]
mov   es, word ptr [bp - 6]
add   word ptr es:[bx + MOBJ_POS_T.mp_x+0], dx
adc   word ptr es:[bx + MOBJ_POS_T.mp_x+2], si
mov   si, cx
mov   di, cx

;	mo_pos->x.w += mo->momx.w;
;	mo_pos->y.w += mo->momy.w;

mov   si, word ptr ds:[si + MOBJ_T.m_momy + 0]
mov   dx, word ptr ds:[di + MOBJ_T.m_momy + 2]
add   word ptr es:[bx + MOBJ_POS_T.mp_y+0], si
adc   word ptr es:[bx + MOBJ_POS_T.mp_y+2], dx
mov   word ptr ds:[di + MOBJ_T.m_tracerRef], ax
LEAVE_MACRO 
pop   di
pop   si
pop   dx
ret   

ENDP


PROC    A_Tracer_ NEAR
PUBLIC  A_Tracer_

push  dx
push  si
push  di
push  bp
mov   bp, sp
sub   sp, 4
push  ax
push  bx
push  cx
test  byte ptr ds:[_gametic], 3
je    do_a_tracer
exit_a_tracer:
LEAVE_MACRO 
pop   di
pop   si
pop   dx
ret   
do_a_tracer:
mov   es, cx
mov   si, bx
mov   di, word ptr [bp - 8]
mov   si, word ptr es:[si + MOBJ_POS_T.mp_z+0]
mov   cx, word ptr es:[bx + MOBJ_POS_T.mp_z+2]
mov   ax, word ptr es:[di + MOBJ_POS_T.mp_y+2]
mov   dx, word ptr es:[di + MOBJ_POS_T.mp_x+2]
mov   word ptr [bp - 4], ax
mov   bx, word ptr es:[bx + MOBJ_POS_T.mp_y+0]
mov   ax, word ptr es:[di + MOBJ_POS_T.mp_x+0]
mov   di, cx
mov   cx, word ptr [bp - 4]
call  P_SpawnPuff_
push  -1 ; todo 186
mov   es, word ptr [bp - 0Ah]
mov   bx, word ptr [bp - 8]
mov   si, word ptr [bp - 8]
push  MT_SMOKE ; todo 186
mov   cx, word ptr es:[si + MOBJ_POS_T.mp_y + 2]
push  word ptr es:[bx + MOBJ_POS_T.mp_z+2]
mov   si, word ptr [bp - 6]
push  word ptr es:[bx + MOBJ_POS_T.mp_z+0]
mov   bx, word ptr es:[bx + MOBJ_POS_T.mp_y+0]
sub   bx, word ptr ds:[si + MOBJ_T.m_momy + 0]
sbb   cx, word ptr ds:[si + MOBJ_T.m_momy + 2]
mov   si, word ptr [bp - 8]
mov   ax, word ptr es:[si + MOBJ_POS_T.mp_x+0]
mov   dx, word ptr es:[si + MOBJ_POS_T.mp_x+2]
mov   si, word ptr [bp - 6]
sub   ax, word ptr ds:[si + MOBJ_T.m_momx + 0]
sbb   dx, word ptr ds:[si + MOBJ_T.m_momx + 2]
call  P_SpawnMobj_
mov   bx, OFFSET _setStateReturn
mov   bx, word ptr ds:[bx]
mov   word ptr ds:[bx + MOBJ_T.m_momz + 2], 1
call  P_Random_
and   al, 3
sub   byte ptr ds:[bx + MOBJ_T.m_tics], al
mov   al, byte ptr ds:[bx + MOBJ_T.m_tics]
cmp   al, 1
jb    label_119
jmp   label_120
label_119:
mov   byte ptr ds:[bx + MOBJ_T.m_tics], 1
label_121:
mov   bx, word ptr [bp - 6]
mov   ax, word ptr ds:[bx + MOBJ_T.m_tracerRef]
test  ax, ax
jne   label_122
jump_to_exit_a_tracer:
jmp   exit_a_tracer
label_122:
imul  bx, ax, SIZEOF_THINKER_T
add   bx, (OFFSET _thinkerlist + THINKER_T.t_data)
je    jump_to_exit_a_tracer
cmp   word ptr ds:[bx + MOBJ_T.m_health], 0
jle   jump_to_exit_a_tracer
push  word ptr es:[bx + MOBJ_POS_T.mp_y + 2]
push  word ptr es:[bx + MOBJ_POS_T.mp_y + 0]
push  word ptr es:[bx + MOBJ_POS_T.mp_x + 2]
push  word ptr es:[bx + MOBJ_POS_T.mp_x + 0]
mov   es, word ptr [bp - 0Ah]
mov   bx, word ptr [bp - 8]
mov   si, word ptr [bp - 8]
mov   bx, word ptr es:[bx + MOBJ_POS_T.mp_y + 0]
mov   cx, word ptr es:[si + MOBJ_POS_T.mp_y + 2]
mov   ax, word ptr es:[si + MOBJ_POS_T.mp_x + 0]
mov   dx, word ptr es:[si + MOBJ_POS_T.mp_x + 2]
call  R_PointToAngle2_
mov   es, word ptr [bp - 0Ah]
mov   bx, si
cmp   dx, word ptr es:[bx + MOBJ_POS_T.mp_angle + 2]
jne   label_123
cmp   ax, word ptr es:[bx + MOBJ_POS_T.mp_angle + 0]
je    label_124
label_123:
mov   cx, ax
sub   cx, word ptr es:[bx + MOBJ_POS_T.mp_angle + 0]
mov   bx, dx
sbb   bx, word ptr es:[si + MOBJ_POS_T.mp_angle + 2]
cmp   bx, 08000h
ja    label_131
je    label_132
jump_to_label_133:
jmp   label_133
label_132:
test  cx, cx
jbe   jump_to_label_133
label_131:
mov   bx, si
mov   cx, ax
add   word ptr es:[bx + MOBJ_POS_T.mp_angle + 0], TRACEANGLELOW
adc   word ptr es:[bx + MOBJ_POS_T.mp_angle + 2], -TRACEANGLEHIGH
sub   cx, word ptr es:[bx + MOBJ_POS_T.mp_angle + 0]
mov   bx, dx
sbb   bx, word ptr es:[si + MOBJ_POS_T.mp_angle + 2]
cmp   bx, 08000h
jae   label_124
jmp   label_125
label_124:
mov   bx, word ptr [bp - 6]
mov   es, word ptr [bp - 0Ah]
mov   al, byte ptr ds:[bx + MOBJ_T.m_mobjtype]
xor   ah, ah
imul  ax, ax, SIZEOF_MOBJINFO_T
mov   si, word ptr [bp - 8]
mov   si, word ptr es:[si + MOBJ_POS_T.mp_angle + 2]
shr   si, 1
and   si, 0FFFCh
mov   bx, ax
mov   al, byte ptr ds:[bx + (OFFSET _mobjinfo + MOBJINFO_T.mobjinfo_speed)]
add   bx, (OFFSET _mobjinfo + MOBJINFO_T.mobjinfo_speed)
cbw  
mov   dx, si
mov   bx, ax
mov   ax, FINECOSINE_SEGMENT
call  FixedMulTrigSpeed_
mov   bx, word ptr [bp - 6]
mov   word ptr ds:[bx + MOBJ_T.m_momx + 0], ax
mov   al, byte ptr ds:[bx + MOBJ_T.m_mobjtype]
xor   ah, ah
imul  ax, ax, SIZEOF_MOBJINFO_T
mov   word ptr ds:[bx + MOBJ_T.m_momx + 2], dx
mov   bx, ax
mov   al, byte ptr ds:[bx + (OFFSET _mobjinfo + MOBJINFO_T.mobjinfo_speed)]
add   bx, (OFFSET _mobjinfo + MOBJINFO_T.mobjinfo_speed)
cbw  
mov   dx, si
mov   bx, ax
mov   ax, FINESINE_SEGMENT
call  FixedMulTrigSpeed_
mov   bx, word ptr [bp - 6]
mov   word ptr ds:[bx + MOBJ_T.m_momy + 0], ax
mov   word ptr ds:[bx + MOBJ_T.m_momy + 2], dx
imul  bx, word ptr ds:[bx + MOBJ_T.m_tracerRef], SIZEOF_MOBJ_POS_T
mov   ax, MOBJPOSLIST_6800_SEGMENT
mov   si, word ptr [bp - 8]
mov   es, ax
mov   word ptr [bp - 4], ax
mov   di, word ptr es:[bx + MOBJ_POS_T.mp_z + 0]
mov   ax, word ptr es:[bx + MOBJ_POS_T.mp_z + 2]
mov   cx, word ptr es:[bx + MOBJ_POS_T.mp_y + 2]
mov   word ptr [bp - 2], ax
mov   ax, word ptr es:[bx + MOBJ_POS_T.mp_y + 0]
mov   es, word ptr [bp - 0Ah]
sub   ax, word ptr es:[si + MOBJ_POS_T.mp_y + 0]
sbb   cx, word ptr es:[si + MOBJ_POS_T.mp_y + 2]
mov   es, word ptr [bp - 4]
mov   dx, word ptr es:[bx + MOBJ_POS_T.mp_x + 0]
mov   si, word ptr es:[bx + MOBJ_POS_T.mp_x + 2]
mov   es, word ptr [bp - 0Ah]
mov   bx, word ptr [bp - 8]
sub   dx, word ptr es:[bx + MOBJ_POS_T.mp_x + 0]
sbb   si, word ptr es:[bx + MOBJ_POS_T.mp_x + 2]
mov   bx, ax
mov   ax, dx
mov   dx, si
call  dword ptr ds:[_P_AproxDistance]
mov   bx, word ptr [bp - 6]
mov   ax, dx
mov   dl, byte ptr ds:[bx + MOBJ_T.m_mobjtype]
xor   dh, dh
imul  dx, dx, SIZEOF_MOBJINFO_T
mov   bx, dx
mov   dl, byte ptr ds:[bx + (OFFSET _mobjinfo + MOBJINFO_T.mobjinfo_speed)]
add   bx, (OFFSET _mobjinfo + MOBJINFO_T.mobjinfo_speed)
xor   dh, dh
mov   bx, dx
sub   bx, 080h
cwd   
idiv  bx
cmp   ax, 1
jge   label_130
mov   ax, 1
label_130:
mov   es, word ptr [bp - 0Ah]
mov   dx, di
mov   bx, word ptr [bp - 8]
add   dx, 0  ; todo remove 
mov   cx, word ptr [bp - 2]
adc   cx, 40 ; 40*FRACUNIT
sub   dx, word ptr es:[bx + MOBJ_POS_T.mp_z + 0]
sbb   cx, word ptr es:[bx + MOBJ_POS_T.mp_z + 2]
mov   bx, ax
mov   ax, dx
mov   dx, cx
call  FastDiv3216u_
mov   bx, word ptr [bp - 6]
cmp   dx, word ptr ds:[bx + MOBJ_T.m_momz + 2]
jl    label_129
jne   label_128
cmp   ax, word ptr ds:[bx + MOBJ_T.m_momz + 0]
jae   label_128
label_129:
add   word ptr ds:[bx + MOBJ_T.m_momz + 0], 0E000h ; -fracunit / 8
adc   word ptr ds:[bx + MOBJ_T.m_momz + 2], 0FFFFh
LEAVE_MACRO 
pop   di
pop   si
pop   dx
ret   
label_120:
cmp   al, 240
jbe   jump_to_label_121
jmp   label_119
jump_to_label_121:
jmp   label_121
label_125:
mov   bx, si
mov   word ptr es:[bx + MOBJ_POS_T.mp_angle + 0], ax
mov   word ptr es:[bx + MOBJ_POS_T.mp_angle + 2], dx
jmp   label_124
label_133:
mov   bx, si
mov   cx, ax
add   word ptr es:[bx + MOBJ_POS_T.mp_angle + 0], TRACEANGLELOW
adc   word ptr es:[bx + MOBJ_POS_T.mp_angle + 2], TRACEANGLEHIGH
sub   cx, word ptr es:[bx + MOBJ_POS_T.mp_angle + 0]
mov   bx, dx
sbb   bx, word ptr es:[si + MOBJ_POS_T.mp_angle + 2]
cmp   bx, 08000h
ja    label_126
je    label_127
jump_to_label_124:
jmp   label_124
label_127:
test  cx, cx
jbe   jump_to_label_124
label_126:
mov   bx, si
mov   word ptr es:[bx + MOBJ_POS_T.mp_angle + 0], ax
mov   word ptr es:[bx + MOBJ_POS_T.mp_angle + 2], dx
jmp   label_124
label_128:
add   word ptr ds:[bx + MOBJ_T.m_momz + 0], 02000h ; fracunit / 8
adc   word ptr ds:[bx + MOBJ_T.m_momz + 2], 0
LEAVE_MACRO 
pop   di
pop   si
pop   dx
ret   


ENDP


PROC    A_SkelWhoosh_ NEAR
PUBLIC  A_SkelWhoosh_

push  bx
push  dx
mov   bx, ax
cmp   word ptr ds:[bx + MOBJ_T.m_targetRef], 0
jne   do_a_skelwhoosh
pop   dx
pop   bx
ret   
do_a_skelwhoosh:
call  A_FaceTarget_
mov   dx, SFX_SKESWG
mov   ax, bx
call  S_StartSound_
pop   dx
pop   bx
ret   

ENDP


PROC    A_SkelFist_ NEAR
PUBLIC  A_SkelFist_

push  bx
push  cx
push  dx
push  si
mov   si, ax
cmp   word ptr ds:[si + MOBJ_T.m_targetRef], 0
jne   do_a_skelfist
exit_a_skelfist:
pop   si
pop   dx
pop   cx
pop   bx
ret   
do_a_skelfist:
call  A_FaceTarget_
mov   ax, si
call  P_CheckMeleeRange_
test  al, al
je    exit_a_skelfist
call  P_Random_
xor   ah, ah
mov   cx, 10
cwd   
idiv  cx
inc   dx
mov   cx, dx
shl   cx, 2
mov   ax, si
sub   cx, dx
mov   dx, SFX_SKEPCH
call  S_StartSound_
imul  ax, word ptr ds:[si + MOBJ_T.m_targetRef], SIZEOF_THINKER_T
mov   bx, si
add   cx, cx
mov   dx, si
add   ax, (OFFSET _thinkerlist + THINKER_T.t_data)
call  P_DamageMobj_
pop   si
pop   dx
pop   cx
pop   bx
ret   

ENDP


PROC    PIT_VileCheck_ NEAR
PUBLIC  PIT_VileCheck_

push  si
push  di
push  bp
mov   bp, sp
sub   sp, 6
push  ax
mov   si, dx
mov   word ptr [bp - 2], cx
mov   word ptr [bp - 6], GETRAISESTATEADDR
mov   es, cx
mov   word ptr [bp - 4], INFOFUNCLOADSEGMENT
test  byte ptr es:[bx + MOBJ_POS_T.mp_flags2], MF_CORPSE
je    exit_pit_vilecheck_return_1
cmp   byte ptr ds:[si + MOBJ_T.m_tics], 0FFh
je    label_134
exit_pit_vilecheck_return_1:
mov   al, 1
LEAVE_MACRO 
pop   di
pop   si
ret   
label_134:
mov   al, byte ptr ds:[si + MOBJ_T.m_mobjtype]
xor   ah, ah
call  dword ptr [bp - 6]
test  ax, ax
je    exit_pit_vilecheck_return_1
mov   al, byte ptr ds:[si + MOBJ_T.m_mobjtype]
xor   ah, ah
imul  ax, ax, SIZEOF_MOBJINFO_T
mov   di, ax
add   di, OFFSET _mobjinfo + MOBJINFO_T.mobjinfo_radius
mov   al, byte ptr ds:[di]
mov   di, OFFSET _mobjinfo + (MT_VILE * SIZEOF_MOBJINFO_T) + MOBJINFO_T.mobjinfo_radius
xor   ah, ah
mov   cl, byte ptr ds:[di]
mov   di, OFFSET _viletryx
xor   ch, ch
mov   es, word ptr [bp - 2]
add   cx, ax
mov   ax, word ptr es:[bx]
mov   dx, word ptr es:[bx + 2]
sub   ax, word ptr ds:[di]
sbb   dx, word ptr ds:[di + 2]
or    dx, dx
jge   label_135
neg   ax
adc   dx, 0
neg   dx
label_135:
cmp   dx, cx
jg    exit_pit_vilecheck_return_1
jne   label_137
test  ax, ax
ja    exit_pit_vilecheck_return_1
label_137:
mov   di, OFFSET _viletryy
mov   ax, word ptr es:[bx + MOBJ_POS_T.mp_y + 0]
mov   dx, word ptr es:[bx + MOBJ_POS_T.mp_y + 2]
sub   ax, word ptr ds:[di]
sbb   dx, word ptr ds:[di + 2]
or    dx, dx
jge   label_136
neg   ax
adc   dx, 0
neg   dx
label_136:
cmp   dx, cx
jg    exit_pit_vilecheck_return_1
jne   label_138
test  ax, ax
ja    exit_pit_vilecheck_return_1
label_138:
mov   di, OFFSET _corpsehitRef
mov   ax, word ptr [bp - 8]
mov   word ptr ds:[di], ax
mov   word ptr ds:[si + MOBJ_T.m_momy + 0], 0
mov   word ptr ds:[si + MOBJ_T.m_momy + 2], 0
shl   word ptr ds:[si + MOBJ_T.m_height + 0], 1
rcl   word ptr ds:[si + MOBJ_T.m_height + 2], 1
shl   word ptr ds:[si + MOBJ_T.m_height + 0], 1
rcl   word ptr ds:[si + MOBJ_T.m_height + 2], 1
mov   ax, word ptr ds:[si + MOBJ_T.m_momy + 0]
mov   dx, word ptr ds:[si + MOBJ_T.m_momy + 2]
mov   word ptr ds:[si + MOBJ_T.m_momx + 0], ax
mov   word ptr ds:[si + MOBJ_T.m_momx + 2], dx
push  word ptr es:[bx + MOBJ_POS_T.mp_y + 2]
mov   ax, word ptr es:[bx]
mov   cx, word ptr es:[bx + 2]
mov   dx, word ptr ds:[si + 4]
push  word ptr es:[bx + MOBJ_POS_T.mp_y + 0]
mov   bx, ax
mov   ax, si
call  dword ptr ds:[_P_CheckPosition]
sar   word ptr ds:[si + MOBJ_T.m_height + 2], 1
rcr   word ptr ds:[si + MOBJ_T.m_height + 0], 1
sar   word ptr ds:[si + MOBJ_T.m_height + 2], 1
rcr   word ptr ds:[si + MOBJ_T.m_height + 0], 1
test  al, al
jne   exit_pit_vilecheck_return_0
jmp   exit_pit_vilecheck_return_1
exit_pit_vilecheck_return_0:
xor   al, al
LEAVE_MACRO 
pop   di
pop   si
ret   

;3e28
_some_lookup_table:

dw OFFSET table_0_label_0
dw OFFSET table_0_label_1
dw OFFSET table_0_label_2
dw OFFSET table_0_label_3
dw OFFSET table_0_label_4
dw OFFSET table_0_label_5
dw OFFSET table_0_label_6
dw OFFSET table_0_label_7

ENDP


PROC    A_VileChase_ NEAR
PUBLIC  A_VileChase_

push  dx
push  si
push  di
push  bp
mov   bp, sp
sub   sp, 016h
push  ax
push  bx
push  cx
mov   word ptr [bp - 012h], P_BLOCKTHINGSITERATOROFFSET
mov   word ptr [bp - 010h], PHYSICS_HIGHCODE_SEGMENT
mov   word ptr [bp - 0Eh], GETSPAWNHEALTHADDR
mov   word ptr [bp - 0Ch], INFOFUNCLOADSEGMENT
mov   word ptr [bp - 016h], GETRAISESTATEADDR
mov   word ptr [bp - 014h], INFOFUNCLOADSEGMENT
mov   si, ax
xor   bx, bx
cmp   byte ptr ds:[si + MOBJ_T.m_movedir], DI_NODIR
je    jump_to_label_139
mov   al, byte ptr ds:[si + MOBJ_T.m_mobjtype]
xor   ah, ah
imul  ax, ax, SIZEOF_MOBJINFO_T
mov   word ptr [bp - 8], bx
mov   word ptr [bp - 0Ah], ax
mov   si, word ptr [bp - 0Ah]
xor   ax, ax
mov   di, word ptr [bp - 01Ah]
mov   al, byte ptr ds:[si + (OFFSET _mobjinfo + MOBJINFO_T.mobjinfo_speed)]
add   si, (OFFSET _mobjinfo + MOBJINFO_T.mobjinfo_speed)
mov   es, cx
mov   si, OFFSET _viletryx
mov   cx, word ptr es:[di]
mov   dx, word ptr es:[di + 2]
mov   word ptr ds:[si], cx
mov   word ptr ds:[si + 2], dx
mov   si, OFFSET _viletryy
mov   dx, word ptr es:[di + MOBJ_POS_T.mp_y + 0]
mov   cx, word ptr es:[di + MOBJ_POS_T.mp_y + 2]
mov   word ptr ds:[si], dx
mov   word ptr ds:[si + 2], cx
mov   si, word ptr [bp - 018h]
mov   dl, byte ptr ds:[si + MOBJ_T.m_movedir]
xor   ah, bh
cmp   dl, 7
ja    label_140
xor   dh, dh
mov   si, dx
add   si, dx
jmp   word ptr cs:[si + OFFSET _some_lookup_table]
jump_to_label_139:
jmp   label_139
table_0_label_0:
mov   si, OFFSET _viletryx + 2
label_141:
add   word ptr ds:[si], ax
label_140:
mov   si, OFFSET _viletryx
mov   di, OFFSET _bmaporgx
mov   dx, word ptr ds:[si]
mov   di, word ptr ds:[di]
sub   dx, bx
mov   ax, word ptr ds:[si + 2]
sbb   ax, di
add   dx, 0
adc   ax, -(MAXRADIUSNONFRAC * 2)
mov   word ptr [bp - 0Ah], dx
mov   word ptr [bp - 8], ax
mov   ax, word ptr ds:[si]
mov   cx, 7
loop_shift_7_4:
sar   word ptr [bp - 8], 1
rcr   word ptr [bp - 0Ah], 1
loop  loop_shift_7_4
sub   ax, bx
mov   dx, word ptr ds:[si + 2]
sbb   dx, di
add   ax, 0
adc   dx, (MAXRADIUSNONFRAC * 2)
mov   si, OFFSET _viletryy
mov   cx, 7
loop_shift_7:
sar   dx, 1
rcr   ax, 1
loop  loop_shift_7
mov   di, OFFSET _bmaporgy
mov   dx, word ptr ds:[si]
mov   di, word ptr ds:[di]
sub   dx, bx
mov   si, word ptr ds:[si + 2]
sbb   si, di
add   dx, 0
adc   si, -(MAXRADIUSNONFRAC * 2)
mov   word ptr [bp - 6], si
mov   si, dx
mov   dx, word ptr [bp - 6]
mov   cx, 7
loop_shift_7_2:
sar   dx, 1
rcr   si, 1
loop  loop_shift_7_2
mov   word ptr [bp - 2], si
mov   si, OFFSET _viletryy
mov   dx, word ptr ds:[si]
mov   word ptr [bp - 4], ax
sub   dx, bx
mov   bx, word ptr ds:[si + 2]
sbb   bx, di
mov   di, dx
mov   dx, bx
add   di, 0
adc   dx, (MAXRADIUSNONFRAC * 2)
mov   si, word ptr [bp - 0Ah]
mov   cx, 7
loop_shift_7_3:
sar   dx, 1
rcr   di, 1
loop  loop_shift_7_3
cmp   ax, si
jl    label_139
label_145:
mov   cx, word ptr [bp - 2]
cmp   di, cx
jl    label_142
label_144:
mov   bx, OFFSET PIT_VileCheck_
mov   dx, cx
mov   ax, si
call  dword ptr [bp - 012h]
test  al, al
je    label_143
inc   cx
cmp   cx, di
jle   label_144
label_142:
inc   si
cmp   si, word ptr [bp - 4]
jle   label_145
label_139:
mov   bx, word ptr [bp - 01Ah]
mov   cx, word ptr [bp - 01Ch]
mov   ax, word ptr [bp - 018h]
call  A_Chase_
LEAVE_MACRO 
pop   di
pop   si
pop   dx
ret   
table_0_label_1:
mov   dx, 47000
mov   si, OFFSET _viletryx
mul   dx
add   word ptr ds:[si], ax
adc   word ptr ds:[si + 2], dx
mov   si, OFFSET _viletryy
add   word ptr ds:[si], ax
adc   word ptr ds:[si + 2], dx
jmp   label_140
table_0_label_2:
mov   si, OFFSET _viletryy + 2
jmp   label_141
table_0_label_3:
mov   dx, 47000
mov   si, OFFSET _viletryx
mul   dx
sub   word ptr ds:[si], ax
sbb   word ptr ds:[si + 2], dx
mov   si, OFFSET _viletryy
add   word ptr ds:[si], ax
adc   word ptr ds:[si + 2], dx
jmp   label_140
table_0_label_4:
mov   si, OFFSET _viletryx
sub   word ptr ds:[si], bx
sbb   word ptr ds:[si + 2], ax
jmp   label_140
table_0_label_5:
mov   dx, 47000
mov   si, OFFSET _viletryx
mul   dx
sub   word ptr ds:[si], ax
sbb   word ptr ds:[si + 2], dx
mov   si, OFFSET _viletryy
sub   word ptr ds:[si], ax
sbb   word ptr ds:[si + 2], dx
jmp   label_140
label_143:
mov   bx, word ptr [bp - 018h]
mov   dx, word ptr ds:[bx + MOBJ_T.m_targetRef]
mov   bx, OFFSET _corpsehitRef
mov   ax, word ptr ds:[bx]
mov   bx, word ptr [bp - 018h]
mov   word ptr ds:[bx + MOBJ_T.m_targetRef], ax
mov   ax, bx
call  A_FaceTarget_
mov   ax, bx
mov   word ptr ds:[bx + MOBJ_T.m_targetRef], dx
mov   dx, S_VILE_HEAL1
mov   bx, OFFSET _corpsehitRef
call  P_SetMobjState_
imul  si, word ptr ds:[bx], SIZEOF_THINKER_T
imul  bx, word ptr ds:[bx], SIZEOF_MOBJ_POS_T
add   si, (OFFSET _thinkerlist + THINKER_T.t_data)
mov   dx, SFX_SLOP
mov   ax, si
call  S_StartSound_
mov   al, byte ptr ds:[si + MOBJ_T.m_mobjtype]
xor   ah, ah
imul  di, ax, SIZEOF_MOBJINFO_T
call  dword ptr [bp - 016h]
mov   dx, ax
mov   ax, si
call  P_SetMobjState_
shl   word ptr ds:[si + MOBJ_T.m_height+2], 2
mov   cx, MOBJPOSLIST_6800_SEGMENT
mov   ax, word ptr ds:[di + OFFSET _mobjinfo + MOBJINFO_T.mobjinfo_flags1]
mov   es, cx
mov   word ptr es:[bx + MOBJ_POS_T.mp_flags1], ax
mov   ax, word ptr ds:[di + OFFSET _mobjinfo + MOBJINFO_T.mobjinfo_flags2]
mov   word ptr es:[bx + MOBJ_POS_T.mp_flags2], ax
mov   al, byte ptr ds:[si + MOBJ_T.m_mobjtype]
xor   ah, ah
call  dword ptr [bp - 0Eh]
mov   word ptr ds:[si + MOBJ_T.m_targetRef], 0
add   di, OFFSET _mobjinfo
mov   word ptr ds:[si + MOBJ_T.m_health], ax
LEAVE_MACRO 
pop   di
pop   si
pop   dx
ret   
table_0_label_6:
mov   si, OFFSET _viletryy
sub   word ptr ds:[si], bx
sbb   word ptr ds:[si + 2], ax
jmp   label_140
table_0_label_7:
mov   dx, 47000
mov   si, OFFSET _viletryx
mul   dx
add   word ptr ds:[si], ax
adc   word ptr ds:[si + 2], dx
mov   si, OFFSET _viletryy
sub   word ptr ds:[si], ax
sbb   word ptr ds:[si + 2], dx
jmp   label_140

ENDP


PROC    A_VileStart_ NEAR
PUBLIC  A_VileStart_

push  dx
mov   dx, SFX_VILATK
call  S_StartSound_
pop   dx
ret   

ENDP


PROC    A_StartFire_ NEAR
PUBLIC  A_StartFire_

push  dx
push  si
mov   si, ax
mov   dx, SFX_FLAMST
call  S_StartSound_
mov   ax, si
call  A_Fire_
pop   si
pop   dx
ret   

ENDP


PROC    A_FireCrackle_ NEAR
PUBLIC  A_FireCrackle_

push  dx
push  si
mov   si, ax
mov   dx, SFX_FLAME
call  S_StartSound_
mov   ax, si
call  A_Fire_
pop   si
pop   dx
ret   

ENDP


PROC    A_Fire_ NEAR
PUBLIC  A_Fire_

push  dx
push  si
push  di
push  bp
mov   bp, sp
sub   sp, 8
push  ax
mov   si, bx
mov   word ptr [bp - 8], cx
mov   di, ax
mov   di, word ptr ds:[di + MOBJ_T.m_tracerRef]
test  di, di
jne   do_a_fire
exit_a_fire:
LEAVE_MACRO 
pop   di
pop   si
pop   dx
ret   
do_a_fire:
imul  dx, di, SIZEOF_THINKER_T
mov   bx, ax
imul  ax, word ptr ds:[bx + MOBJ_T.m_targetRef], SIZEOF_MOBJ_POS_T
imul  di, di, SIZEOF_MOBJ_POS_T
mov   word ptr [bp - 4], ax
imul  ax, word ptr ds:[bx + MOBJ_T.m_targetRef], SIZEOF_THINKER_T
add   dx, (OFFSET _thinkerlist + THINKER_T.t_data)
mov   cx, di
mov   bx, word ptr [bp - 4]
add   ax, (OFFSET _thinkerlist + THINKER_T.t_data)
mov   word ptr [bp - 2], MOBJPOSLIST_6800_SEGMENT
call  dword ptr ds:[_P_CheckSightTemp]
test  al, al
je    exit_a_fire
mov   es, word ptr [bp - 2]
mov   ax, word ptr es:[di + MOBJ_POS_T.mp_angle + 2]
shr   ax, 1
mov   cx, 24
and   al, 0FCh
mov   dx, si
mov   word ptr [bp - 6], ax
mov   ax, word ptr [bp - 0Ah]
xor   bx, bx
call  dword ptr ds:[_P_UnsetThingPosition]
mov   dx, word ptr [bp - 6]
mov   ax, FINECOSINE_SEGMENT
call  FixedMulTrigNoShift_
mov   es, word ptr [bp - 2]
mov   cx, 24
mov   word ptr [bp - 4], ax
mov   bx, dx
mov   ax, word ptr es:[di + MOBJ_POS_T.mp_x + 0]
mov   dx, word ptr es:[di + MOBJ_POS_T.mp_x + 2]
mov   es, word ptr [bp - 8]
add   ax, word ptr [bp - 4]
adc   dx, bx
mov   word ptr es:[si + MOBJ_POS_T.mp_x + 0], ax
mov   ax, FINESINE_SEGMENT
xor   bx, bx
mov   word ptr es:[si + MOBJ_POS_T.mp_x + 2], dx
mov   dx, word ptr [bp - 6]
call  FixedMulTrigNoShift_
mov   es, word ptr [bp - 2]
mov   bx, ax
mov   cx, dx
mov   ax, word ptr es:[di + MOBJ_POS_T.mp_y + 0]
mov   dx, word ptr es:[di + MOBJ_POS_T.mp_y + 2]
mov   es, word ptr [bp - 8]
add   ax, bx
adc   dx, cx
mov   word ptr es:[si + MOBJ_POS_T.mp_y + 0], ax
mov   word ptr es:[si + MOBJ_POS_T.mp_y + 2], dx
mov   es, word ptr [bp - 2]
mov   ax, word ptr es:[di + MOBJ_POS_T.mp_z + 0]
mov   dx, word ptr es:[di + MOBJ_POS_T.mp_z + 2]
mov   es, word ptr [bp - 8]
mov   word ptr es:[si + MOBJ_POS_T.mp_z + 0], ax
mov   bx, -1
mov   word ptr es:[si + MOBJ_POS_T.mp_z + 2], dx
mov   ax, word ptr [bp - 0Ah]
mov   dx, si
call  dword ptr ds:[_P_SetThingPosition]
LEAVE_MACRO 
pop   di
pop   si
pop   dx
ret   

ENDP


PROC    A_VileTarget_ NEAR
PUBLIC  A_VileTarget_

push  bx
push  cx
push  dx
push  si
push  di
push  bp
mov   bp, sp
sub   sp, 2
mov   si, ax
cmp   word ptr ds:[si + MOBJ_T.m_targetRef], 0
jne   do_vile_target
LEAVE_MACRO 
pop   di
pop   si
pop   dx
pop   cx
pop   bx
ret   
do_vile_target:
call  A_FaceTarget_
mov   ax, word ptr ds:[si + MOBJ_T.m_targetRef]
mov   word ptr [bp - 2], ax
imul  di, ax, SIZEOF_THINKER_T
imul  bx, ax, SIZEOF_MOBJ_POS_T
mov   ax, MOBJPOSLIST_6800_SEGMENT
add   di, (OFFSET _thinkerlist + THINKER_T.t_data)
mov   es, ax
push  word ptr ds:[di + MOBJ_T.m_secnum]
mov   cx, word ptr es:[bx + MOBJ_POS_T.mp_y + 2]
mov   ax, word ptr es:[bx]
push  MT_FIRE ; todo 186
mov   dx, word ptr es:[bx + 2]
push  word ptr es:[bx + MOBJ_POS_T.mp_z + 2]
mov   di, word ptr es:[bx + MOBJ_POS_T.mp_y + 0]
push  word ptr es:[bx + MOBJ_POS_T.mp_z + 0]
mov   bx, di
call  P_SpawnMobj_
mov   cx, SIZEOF_THINKER_T
mov   bx, ax
xor   dx, dx
lea   ax, ds:[si - (OFFSET _thinkerlist + THINKER_T.t_data)]
div   cx
mov   di, OFFSET _setStateReturn
mov   di, word ptr ds:[di]
mov   word ptr ds:[di + MOBJ_T.m_targetRef], ax
mov   ax, word ptr [bp - 2]
mov   word ptr ds:[di + MOBJ_T.m_tracerRef], ax
mov   word ptr ds:[si + MOBJ_T.m_tracerRef], bx
mov   bx, OFFSET _setStateReturn_pos
mov   ax, word ptr ds:[bx]
mov   cx, word ptr ds:[bx + 2]
mov   bx, ax
mov   ax, di
call  A_Fire_
LEAVE_MACRO 
pop   di
pop   si
pop   dx
pop   cx
pop   bx
ret   

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

push  bx
sub   al, 3
cmp   al, MT_PAIN  ; todo this logic seems incorrect..?
ja    vilemomz_ret_10
xor   ah, ah
mov   bx, ax
add   bx, ax
jmp   word ptr cs:[bx + OFFSET _vile_momz_lookuptable]
vilemomz_ret_2:
mov   dx, 2
vilemomz_lowbits_0_and_return:
xor   ax, ax
pop   bx
ret   
vilemomz_ret_20:
mov   dx, 20
xor   al, al
pop   bx
ret   
vilemomz_ret_163840:
mov   ax, 08000h
mov   dx, 2
pop   bx
ret   
vilemomz_ret_109226:
mov   ax, 0AAAAh
mov   dx, 1
pop   bx
ret   
vilemomz_ret_1_high:
mov   dx, 1
jmp   vilemomz_lowbits_0_and_return
vilemomz_ret_1_low:
mov   ax, 1
xor   dx, dx
pop   bx
ret   
vilemomz_ret_10:
mov   dx, 10
xor   ax, ax
pop   bx
ret   

ENDP


PROC    A_VileAttack_ NEAR
PUBLIC  A_VileAttack_

push  dx
push  si
push  di
push  bp
mov   bp, sp
sub   sp, 010h
mov   si, ax
mov   word ptr [bp - 0Ah], bx
mov   word ptr [bp - 6], cx
mov   ax, word ptr ds:[si + MOBJ_T.m_targetRef]
test  ax, ax
jne   do_vile_attack
exit_vile_attack:
LEAVE_MACRO 
pop   di
pop   si
pop   dx
ret   
do_vile_attack:
imul  bx, ax, SIZEOF_MOBJ_POS_T
mov   ax, si
call  A_FaceTarget_
imul  di, word ptr ds:[si + MOBJ_T.m_targetRef], SIZEOF_THINKER_T
mov   word ptr [bp - 2], bx
mov   cx, bx
mov   bx, word ptr [bp - 0Ah]
add   di, (OFFSET _thinkerlist + THINKER_T.t_data)
mov   ax, si
mov   dx, di
mov   word ptr [bp - 4], MOBJPOSLIST_6800_SEGMENT
call  dword ptr ds:[_P_CheckSightTemp]
test  al, al
je    exit_vile_attack
mov   dx, SFX_BAREXP
mov   ax, si
call  S_StartSound_
imul  ax, word ptr ds:[si + MOBJ_T.m_targetRef], SIZEOF_THINKER_T
mov   cx, 20
mov   bx, si
mov   dx, si
add   ax, (OFFSET _thinkerlist + THINKER_T.t_data)
call  P_DamageMobj_
mov   es, word ptr [bp - 6]
mov   bx, word ptr [bp - 0Ah]
mov   ax, word ptr es:[bx + MOBJ_POS_T.mp_angle + 2]
shr   ax, 1
and   al, 0FCh
mov   word ptr [bp - 8], ax
mov   al, byte ptr ds:[di + MOBJ_T.m_mobjtype]
cbw  
mov   bx, word ptr ds:[si + MOBJ_T.m_tracerRef]
call  GetVileMomz_
mov   word ptr ds:[di + MOBJ_T.m_momz + 0], ax
mov   word ptr ds:[di + MOBJ_T.m_momz + 2], dx
test  bx, bx
je    exit_vile_attack
imul  ax, bx, SIZEOF_THINKER_T
imul  di, bx, SIZEOF_MOBJ_POS_T
mov   cx, 24
add   ax, (OFFSET _thinkerlist + THINKER_T.t_data)
mov   dx, word ptr [bp - 8]
mov   word ptr [bp - 0Eh], ax
mov   ax, FINECOSINE_SEGMENT
xor   bx, bx
mov   word ptr [bp - 0Ch], MOBJPOSLIST_6800_SEGMENT
call  FixedMulTrigNoShift_
mov   es, word ptr [bp - 4]
mov   bx, word ptr [bp - 2]
mov   word ptr [bp - 010h], ax
mov   cx, dx
mov   dx, word ptr es:[bx]
mov   ax, word ptr es:[bx + 2]
mov   es, word ptr [bp - 0Ch]
sub   dx, word ptr [bp - 010h]
sbb   ax, cx
mov   word ptr es:[di], dx
mov   cx, 24
mov   dx, word ptr [bp - 8]
xor   bx, bx
mov   word ptr es:[di + 2], ax
mov   ax, FINESINE_SEGMENT
call  FixedMulTrigNoShift_
mov   es, word ptr [bp - 4]
mov   bx, word ptr [bp - 2]
mov   cx, ax
mov   word ptr [bp - 010h], dx
mov   dx, word ptr es:[bx + MOBJ_POS_T.mp_y + 0]
mov   ax, word ptr es:[bx + MOBJ_POS_T.mp_y + 2]
mov   es, word ptr [bp - 0Ch]
mov   bx, si
sub   dx, cx
mov   cx, 70
sbb   ax, word ptr [bp - 010h]
mov   word ptr es:[di + MOBJ_POS_T.mp_y + 0], dx
mov   dx, di
mov   word ptr es:[di + MOBJ_POS_T.mp_y + 2], ax
mov   ax, word ptr [bp - 0Eh]
call  dword ptr ds:[_P_RadiusAttack]
LEAVE_MACRO 
pop   di
pop   si
pop   dx
ret   

ENDP


PROC    A_FatRaise_ NEAR
PUBLIC  A_FatRaise_

push  bx
push  dx
mov   bx, ax
call  A_FaceTarget_
mov   dx, SFX_MANATK
mov   ax, bx
call  S_StartSound_
pop   dx
pop   bx
ret   

ENDP


PROC    A_FatAttack1_ NEAR
PUBLIC  A_FatAttack1_

push  dx
push  si
push  di
push  bp
mov   bp, sp
sub   sp, 2
mov   di, ax
mov   si, bx
mov   word ptr [bp - 2], cx
call  A_FaceTarget_
mov   es, cx
add   word ptr es:[si + MOBJ_POS_T.mp_angle + 0], FATSPREADLOW
adc   word ptr es:[si + MOBJ_POS_T.mp_angle + 2], FATSPREADHIGH
imul  dx, word ptr ds:[di + MOBJ_T.m_targetRef], SIZEOF_THINKER_T
push  9
mov   ax, di
add   dx, (OFFSET _thinkerlist + THINKER_T.t_data)
call  dword ptr ds:[_P_SpawnMissile]
imul  dx, word ptr ds:[di + MOBJ_T.m_targetRef], SIZEOF_THINKER_T
push  9
mov   cx, word ptr [bp - 2]
mov   bx, si
mov   ax, di
add   dx, (OFFSET _thinkerlist + THINKER_T.t_data)
call  dword ptr ds:[_P_SpawnMissile]
imul  si, ax, SIZEOF_THINKER_T
imul  di, ax, SIZEOF_MOBJ_POS_T
mov   ax, MOBJPOSLIST_6800_SEGMENT
add   si, (OFFSET _thinkerlist + THINKER_T.t_data)
mov   es, ax
mov   bx, di
add   word ptr es:[di + MOBJ_POS_T.mp_angle + 0], FATSPREADLOW
adc   word ptr es:[bx + MOBJ_POS_T.mp_angle + 2], FATSPREADHIGH
mov   al, byte ptr ds:[si + MOBJ_T.m_mobjtype]
xor   ah, ah
imul  ax, ax, SIZEOF_MOBJINFO_T
mov   di, word ptr es:[di + MOBJ_POS_T.mp_angle + 2]
shr   di, 1
and   di, 0FFFCh
mov   bx, ax
mov   al, byte ptr ds:[bx + (OFFSET _mobjinfo + MOBJINFO_T.mobjinfo_speed)]
add   bx, (OFFSET _mobjinfo + MOBJINFO_T.mobjinfo_speed)
cbw  
mov   dx, di
mov   bx, ax
mov   ax, FINECOSINE_SEGMENT
call  FixedMulTrigSpeedNoShift_
mov   word ptr ds:[si + MOBJ_T.m_momx + 0], ax
mov   al, byte ptr ds:[si + MOBJ_T.m_mobjtype]
xor   ah, ah
imul  ax, ax, SIZEOF_MOBJINFO_T
mov   word ptr ds:[si + MOBJ_T.m_momx + 2], dx
mov   bx, ax
mov   al, byte ptr ds:[bx + (OFFSET _mobjinfo + MOBJINFO_T.mobjinfo_speed)]
add   bx, (OFFSET _mobjinfo + MOBJINFO_T.mobjinfo_speed)
cbw  
mov   dx, di
mov   bx, ax
mov   ax, FINESINE_SEGMENT
call  FixedMulTrigSpeedNoShift_
mov   word ptr ds:[si + MOBJ_T.m_momy + 0], ax
mov   word ptr ds:[si + MOBJ_T.m_momy + 2], dx
LEAVE_MACRO 
pop   di
pop   si
pop   dx
ret   

ENDP


PROC    A_FatAttack2_ NEAR
PUBLIC  A_FatAttack2_

push  dx
push  si
push  di
push  bp
mov   bp, sp
sub   sp, 2
mov   di, ax
mov   si, bx
mov   word ptr [bp - 2], cx
call  A_FaceTarget_
mov   es, cx
add   word ptr es:[si + MOBJ_POS_T.mp_angle + 0], FATSPREADLOW
adc   word ptr es:[si + MOBJ_POS_T.mp_angle + 2], -FATSPREADHIGH
imul  dx, word ptr ds:[di + MOBJ_T.m_targetRef], SIZEOF_THINKER_T
push  MT_FATSHOT  ; todo 186
mov   ax, di
add   dx, (OFFSET _thinkerlist + THINKER_T.t_data)
call  dword ptr ds:[_P_SpawnMissile]
imul  dx, word ptr ds:[di + MOBJ_T.m_targetRef], SIZEOF_THINKER_T
push  MT_FATSHOT  ; todo 186
mov   cx, word ptr [bp - 2]
mov   bx, si
mov   ax, di
add   dx, (OFFSET _thinkerlist + THINKER_T.t_data)
mov   si, OFFSET _setStateReturn
call  dword ptr ds:[_P_SpawnMissile]
mov   bx, OFFSET _setStateReturn_pos
mov   si, word ptr ds:[si]
les   di, dword ptr ds:[bx]
add   word ptr es:[di + MOBJ_POS_T.mp_angle + 0], FATSPREADLOW
adc   word ptr es:[di + MOBJ_POS_T.mp_angle + 2], -(2*FATSPREADHIGH)
mov   al, byte ptr ds:[si + MOBJ_T.m_mobjtype]
xor   ah, ah
imul  ax, ax, SIZEOF_MOBJINFO_T
mov   di, word ptr es:[di + MOBJ_POS_T.mp_angle + 2]
shr   di, 1
and   di, 0FFFCh
mov   bx, ax
mov   al, byte ptr ds:[bx + (OFFSET _mobjinfo + MOBJINFO_T.mobjinfo_speed)]
add   bx, (OFFSET _mobjinfo + MOBJINFO_T.mobjinfo_speed)
cbw  
mov   dx, di
mov   bx, ax
mov   ax, FINECOSINE_SEGMENT
call  FixedMulTrigSpeedNoShift_
mov   word ptr ds:[si + MOBJ_T.m_momx + 0], ax
mov   al, byte ptr ds:[si + MOBJ_T.m_mobjtype]
xor   ah, ah
imul  ax, ax, SIZEOF_MOBJINFO_T
mov   word ptr ds:[si + MOBJ_T.m_momx + 2], dx
mov   bx, ax
mov   al, byte ptr ds:[bx + (OFFSET _mobjinfo + MOBJINFO_T.mobjinfo_speed)]
add   bx, (OFFSET _mobjinfo + MOBJINFO_T.mobjinfo_speed)
cbw  
mov   dx, di
mov   bx, ax
mov   ax, FINESINE_SEGMENT
call  FixedMulTrigSpeedNoShift_
mov   word ptr ds:[si + MOBJ_T.m_momy + 0], ax
mov   word ptr ds:[si + MOBJ_T.m_momy + 2], dx
LEAVE_MACRO 
pop   di
pop   si
pop   dx
ret   

ENDP


PROC    A_FatAttack3_ NEAR
PUBLIC  A_FatAttack3_

push  dx
push  si
push  di
push  bp
mov   bp, sp
sub   sp, 6
push  ax
push  bx
push  cx
mov   bx, word ptr [bp - 8]
call  A_FaceTarget_
mov   ax, word ptr ds:[bx + MOBJ_T.m_targetRef]
imul  ax, ax, SIZEOF_THINKER_T
push  MT_FATSHOT  ; todo 186
mov   si, OFFSET _setStateReturn
add   ax, (OFFSET _thinkerlist + THINKER_T.t_data)
mov   bx, word ptr [bp - 0Ah]
mov   word ptr [bp - 4], ax
mov   dx, ax
mov   ax, word ptr [bp - 8]
mov   di, OFFSET _setStateReturn_pos
call  dword ptr ds:[_P_SpawnMissile]
mov   si, word ptr ds:[si]
les   bx, dword ptr ds:[di]
add   word ptr es:[bx + MOBJ_POS_T.mp_angle + 0], FATSPREADLOW
adc   word ptr es:[bx + MOBJ_POS_T.mp_angle + 2], -(FATSPREADHIGH/2)
mov   ax, word ptr es:[bx + MOBJ_POS_T.mp_angle + 2]
mov   bl, byte ptr ds:[si + MOBJ_T.m_mobjtype]
xor   bh, bh
imul  bx, bx, SIZEOF_MOBJINFO_T
shr   ax, 1
and   al, 0FCh
mov   word ptr [bp - 2], ax
mov   dx, word ptr [bp - 2]
mov   al, byte ptr ds:[bx + (OFFSET _mobjinfo + MOBJINFO_T.mobjinfo_speed)]
cbw  
add   bx, (OFFSET _mobjinfo + MOBJINFO_T.mobjinfo_speed)
mov   word ptr [bp - 6], ax
mov   bx, ax
mov   ax, FINECOSINE_SEGMENT
call  FixedMulTrigSpeedNoShift_
mov   word ptr ds:[si + MOBJ_T.m_momx + 0], ax
mov   bx, word ptr [bp - 6]
mov   word ptr ds:[si + MOBJ_T.m_momx + 2], dx
mov   dx, word ptr [bp - 2]
mov   ax, FINESINE_SEGMENT
call  FixedMulTrigSpeedNoShift_
push  9
mov   bx, word ptr [bp - 0Ah]
mov   word ptr ds:[si + MOBJ_T.m_momy + 0], ax
mov   cx, word ptr [bp - 0Ch]
mov   word ptr ds:[si + MOBJ_T.m_momy + 2], dx
mov   dx, word ptr [bp - 4]
mov   ax, word ptr [bp - 8]
mov   si, OFFSET _setStateReturn
call  dword ptr ds:[_P_SpawnMissile]
mov   si, word ptr ds:[si]
les   bx, dword ptr ds:[di]
add   word ptr es:[bx + MOBJ_POS_T.mp_angle + 0], FATSPREADLOW
adc   word ptr es:[bx + MOBJ_POS_T.mp_angle + 2], FATSPREADHIGH/2
mov   ax, word ptr es:[bx + MOBJ_POS_T.mp_angle + 2]
shr   ax, 1
and   al, 0FCh
mov   bx, word ptr [bp - 6]
mov   word ptr [bp - 2], ax
mov   dx, ax
mov   ax, FINECOSINE_SEGMENT
call  FixedMulTrigSpeedNoShift_
mov   word ptr ds:[si + MOBJ_T.m_momx + 0], ax
mov   bx, word ptr [bp - 6]
mov   word ptr ds:[si + MOBJ_T.m_momx + 2], dx
mov   dx, word ptr [bp - 2]
mov   ax, FINESINE_SEGMENT
call  FixedMulTrigSpeedNoShift_
mov   word ptr ds:[si + MOBJ_T.m_momy + 0], ax
mov   word ptr ds:[si + MOBJ_T.m_momy + 2], dx
LEAVE_MACRO 
pop   di
pop   si
pop   dx
ret   

ENDP


PROC    A_SkullAttack_ NEAR
PUBLIC  A_SkullAttack_

push  dx
push  si
push  di
push  bp
mov   bp, sp
sub   sp, 010h
mov   si, ax
mov   di, bx
mov   word ptr [bp - 2], cx
mov   word ptr [bp - 010h], GETATTACKSOUNDADDR
mov   word ptr [bp - 0Eh], INFOFUNCLOADSEGMENT
cmp   word ptr ds:[si + MOBJ_T.m_targetRef], 0
jne   do_skullattack
LEAVE_MACRO 
pop   di
pop   si
pop   dx
ret   
do_skullattack:
mov   es, cx
or    byte ptr es:[di + MOBJ_POS_T.mp_flags2 + 1], 1
mov   al, byte ptr ds:[si + MOBJ_T.m_mobjtype]
xor   ah, ah
mov   cx, word ptr ds:[si + MOBJ_T.m_targetRef]
call  dword ptr [bp - 010h]
mov   dl, al
mov   ax, si
xor   dh, dh
call  S_StartSound_
mov   ax, si
call  A_FaceTarget_
imul  ax, cx, SIZEOF_THINKER_T
imul  bx, cx, SIZEOF_MOBJ_POS_T
add   ax, (OFFSET _thinkerlist + THINKER_T.t_data)
mov   es, word ptr [bp - 2]
mov   word ptr [bp - 8], ax
mov   ax, word ptr es:[di + MOBJ_POS_T.mp_angle + 2]
shr   ax, 1
and   al, 0FCh
mov   word ptr [bp - 0Ch], ax
mov   dx, ax
mov   word ptr [bp - 0Ah], bx
mov   word ptr [bp - 6], bx
mov   ax, FINECOSINE_SEGMENT
mov   bx, SKULLSPEED_SMALL
call  FixedMulTrigSpeedNoShift_
mov   word ptr ds:[si + MOBJ_T.m_momx + 0], ax
mov   bx, SKULLSPEED_SMALL
mov   word ptr ds:[si + MOBJ_T.m_momx + 2], dx
mov   dx, word ptr [bp - 0Ch]
mov   ax, FINESINE_SEGMENT
mov   word ptr [bp - 4], MOBJPOSLIST_6800_SEGMENT
call  FixedMulTrigSpeedNoShift_
mov   word ptr ds:[si + MOBJ_T.m_momy + 0], ax
mov   bx, word ptr [bp - 0Ah]
mov   word ptr ds:[si + MOBJ_T.m_momy + 2], dx
mov   es, word ptr [bp - 4]
mov   ax, word ptr es:[bx + MOBJ_POS_T.mp_y + 0]
mov   cx, word ptr es:[bx + MOBJ_POS_T.mp_y + 2]
mov   es, word ptr [bp - 2]
sub   ax, word ptr es:[di + MOBJ_POS_T.mp_y + 0]
sbb   cx, word ptr es:[di + MOBJ_POS_T.mp_y + 2]
mov   es, word ptr [bp - 4]
mov   dx, word ptr es:[bx]
mov   word ptr [bp - 0Ah], dx
mov   dx, word ptr es:[bx + 2]
mov   es, word ptr [bp - 2]
mov   bx, word ptr es:[di]
sub   word ptr [bp - 0Ah], bx
mov   bx, ax
sbb   dx, word ptr es:[di + 2]
mov   ax, word ptr [bp - 0Ah]
call  dword ptr ds:[_P_AproxDistance]
mov   ax, dx
mov   cx, SKULLSPEED_SMALL
cwd   
idiv  cx
mov   cx, ax
cmp   ax, 1
jae   label_146
mov   cx, 1
label_146:
mov   bx, word ptr [bp - 8]
mov   ax, word ptr ds:[bx + MOBJ_T.m_height+0]
mov   dx, word ptr ds:[bx + MOBJ_T.m_height+2]
mov   es, word ptr [bp - 4]
sar   dx, 1
rcr   ax, 1
mov   bx, word ptr [bp - 6]
mov   word ptr [bp - 0Ah], dx
add   ax, word ptr es:[bx + MOBJ_POS_T.mp_z + 0]
mov   dx, word ptr es:[bx + MOBJ_POS_T.mp_z + 2]
mov   es, word ptr [bp - 2]
adc   dx, word ptr [bp - 0Ah]
mov   bx, cx
sub   ax, word ptr es:[di + MOBJ_POS_T.mp_z + 0]
sbb   dx, word ptr es:[di + MOBJ_POS_T.mp_z + 2]
call  FastDiv3216u_
mov   word ptr ds:[si + MOBJ_T.m_momz + 0], ax
mov   word ptr ds:[si + MOBJ_T.m_momz + 2], dx
LEAVE_MACRO 
pop   di
pop   si
pop   dx
ret   

ENDP


PROC    A_PainShootSkull_ NEAR
PUBLIC  A_PainShootSkull_

push  dx
push  si
push  di
push  bp
mov   bp, sp
sub   sp, 010h
mov   di, ax
mov   word ptr [bp - 0Ah], cx
mov   bx, OFFSET _thinkerlist + THINKER_T.t_next
mov   ax, word ptr ds:[bx]
xor   dx, dx
test  ax, ax
je    label_147
label_148:
imul  bx, ax, SIZEOF_THINKER_T
mov   cx, word ptr ds:[bx + _thinkerlist + THINKER_T.t_prevFunctype]
xor   cl, cl
and   ch, (TF_FUNCBITS SHR 8)
cmp   cx, TF_MOBJTHINKER_HIGHBITS
jne   label_149
; BIG BIG TODO this should (?) also have THINKER_T.t_data (4) added to it.
cmp   byte ptr ds:[bx + _thinkerlist + MOBJ_T.m_mobjtype], MT_SKULL
jne   label_149
inc   dx
label_149:
cmp   dx, 20
jle   label_150
label_147:
cmp   dx, 20
jle   label_151
LEAVE_MACRO 
pop   di
pop   si
pop   dx
ret   
label_150:
imul  bx, ax, SIZEOF_THINKER_T
mov   ax, word ptr ds:[bx + OFFSET _thinkerlist + THINKER_T.t_next]
test  ax, ax
jne   label_148
jmp   label_147
label_151:
mov   ax, word ptr [bp - 0Ah]
shr   ax, 1
and   al, 0FCh
mov   word ptr [bp - 6], ax
mov   ax, word ptr ds:[di + MOBJ_T.m_targetRef]
mov   word ptr [bp - 8], ax
mov   al, byte ptr ds:[di + MOBJ_T.m_mobjtype]
xor   ah, ah
imul  ax, ax, SIZEOF_MOBJINFO_T
mov   bx, ax
add   bx, OFFSET _mobjinfo + MOBJINFO_T.mobjinfo_radius
mov   al, byte ptr ds:[bx]
mov   bx, OFFSET _mobjinfo + (SIZEOF_MOBJINFO_T * MT_SKULL) + MOBJINFO_T.mobjinfo_radius ;  0C52Bh
mov   dl, byte ptr ds:[bx]
xor   ah, ah
xor   dh, dh
add   dx, ax
sar   dx, 1
mov   ax, dx
shl   ax, 2
sub   ax, dx
mov   bx, SIZEOF_THINKER_T
add   ax, 4
xor   dx, dx
mov   word ptr [bp - 4], ax
lea   ax, ds:[di - (OFFSET _thinkerlist + THINKER_T.t_data)]
div   bx
imul  si, ax, SIZEOF_MOBJ_POS_T
mov   cx, word ptr [bp - 4]
mov   dx, word ptr [bp - 6]
xor   bx, bx
mov   ax, FINECOSINE_SEGMENT
mov   word ptr [bp - 0Ch], MOBJPOSLIST_6800_SEGMENT
call  FixedMulTrigNoShift_
mov   es, word ptr [bp - 0Ch]
mov   bx, word ptr es:[si]
add   bx, ax
mov   word ptr [bp - 0Eh], bx
mov   bx, si
mov   cx, word ptr [bp - 4]
mov   ax, word ptr es:[bx + 2]
adc   ax, dx
mov   dx, word ptr [bp - 6]
mov   word ptr [bp - 010h], ax
xor   bx, si
mov   ax, FINESINE_SEGMENT
call  FixedMulTrigNoShift_
mov   es, word ptr [bp - 0Ch]
push  -1  ; todo 186
mov   cx, dx
mov   bx, si
mov   dx, word ptr es:[si + MOBJ_POS_T.mp_y + 0]
push  MT_SKULL  ; todo 186
add   dx, ax
mov   ax, word ptr es:[si + MOBJ_POS_T.mp_z + 2]
adc   cx, word ptr es:[bx + MOBJ_POS_T.mp_y + 2]
add   ax, 8
mov   bx, word ptr es:[si + MOBJ_POS_T.mp_z + 0]
push  ax
mov   ax, word ptr [bp - 0Eh]
push  bx
mov   bx, dx
mov   dx, word ptr [bp - 010h]
call  P_SpawnMobj_
mov   bx, OFFSET _setStateReturn
mov   bx, word ptr ds:[bx]
mov   word ptr [bp - 2], bx
mov   bx, OFFSET _setStateReturn_pos
mov   dx, word ptr ds:[bx + 2]
mov   si, word ptr ds:[bx]
mov   es, dx
push  word ptr es:[si + MOBJ_POS_T.mp_y + 2]
mov   ax, word ptr [bp - 2]
push  word ptr es:[si + MOBJ_POS_T.mp_y + 0]
mov   bx, si
push  word ptr es:[si + 2]
mov   cx, dx
push  word ptr es:[si]
call  dword ptr ds:[_P_TryMove]
test  al, al
jne   label_152
mov   cx, 10000
mov   ax, word ptr [bp - 2]
mov   bx, di
mov   dx, di
call  P_DamageMobj_
LEAVE_MACRO 
pop   di
pop   si
pop   dx
ret   
label_152:
mov   ax, word ptr [bp - 8]
mov   bx, word ptr [bp - 2]
mov   cx, dx
mov   word ptr ds:[bx + MOBJ_T.m_targetRef], ax
mov   ax, word ptr [bp - 2]
mov   bx, si
call  A_SkullAttack_
LEAVE_MACRO 
pop   di
pop   si
pop   dx
ret   

ENDP

PROC    A_PainAttack_ NEAR
PUBLIC  A_PainAttack_

push  si
mov   si, ax
cmp   word ptr ds:[si + MOBJ_T.m_targetRef], 0
jne   do_painattack
pop   si
ret   
do_painattack:
call  A_FaceTarget_
mov   es, cx
mov   ax, word ptr es:[bx + MOBJ_POS_T.mp_angle + 0]
mov   cx, word ptr es:[bx + MOBJ_POS_T.mp_angle + 2]
mov   bx, ax
mov   ax, si
call  A_PainShootSkull_
pop   si
ret   

ENDP


PROC    A_PainDie_ NEAR
PUBLIC  A_PainDie_

push  dx
push  si
push  di
mov   si, ax
mov   es, cx
mov   di, word ptr es:[bx + MOBJ_POS_T.mp_angle + 0]
mov   dx, word ptr es:[bx + MOBJ_POS_T.mp_angle + 2]
and   byte ptr es:[bx + MOBJ_POS_T.mp_flags1],  (NOT MF_SOLID)
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
call  A_PainShootSkull_
pop   di
pop   si
pop   dx
ret   

ENDP


PROC    A_Scream_ NEAR
PUBLIC  A_Scream_

push  bx
push  dx
push  si
mov   bx, ax
mov   al, byte ptr ds:[bx + MOBJ_T.m_mobjtype]
xor   ah, ah
imul  ax, ax, SIZEOF_MOBJINFO_T
mov   si, ax
mov   al, byte ptr ds:[si + OFFSET _mobjinfo + MOBJINFO_T.mobjinfo_deathsound]
add   si, OFFSET _mobjinfo + MOBJINFO_T.mobjinfo_deathsound
cmp   al, SFX_PODTH1
jae   label_153
test  al, al
je    exit_a_scream
label_157:
mov   al, byte ptr ds:[bx + MOBJ_T.m_mobjtype]
xor   ah, ah
imul  ax, ax, SIZEOF_MOBJINFO_T
mov   si, ax
mov   al, byte ptr ds:[si + OFFSET _mobjinfo + MOBJINFO_T.mobjinfo_deathsound]
add   si, OFFSET _mobjinfo + MOBJINFO_T.mobjinfo_deathsound
label_158:
cmp   byte ptr ds:[bx + MOBJ_T.m_mobjtype], MT_SPIDER
je    label_154
cmp   byte ptr ds:[bx + MOBJ_T.m_mobjtype], MT_CYBORG
jne   label_155
label_154:
mov   dl, al
xor   dh, dh
xor   ax, ax
call  S_StartSound_
exit_a_scream:
pop   si
pop   dx
pop   bx
ret   
label_153:
cmp   al, SFX_PODTH3
jbe   label_156
cmp   al, SFX_BGDTH2
ja    label_157
call  P_Random_
mov   dl, al
xor   dh, dh
mov   ax, dx
sar   ax, 0Fh ; todo no
xor   dx, ax
sub   dx, ax
and   dx, 1
xor   dx, ax
sub   dx, ax
mov   ax, dx
add   ax, SFX_BGDTH1
jmp   label_158
label_156:
call  P_Random_
xor   ah, ah
mov   si, 3
cwd   
idiv  si
mov   ax, dx
add   ax, SFX_PODTH1
jmp   label_158
label_155:
mov   dl, al
mov   ax, bx
xor   dh, dh
call  S_StartSound_
pop   si
pop   dx
pop   bx
ret   

ENDP


PROC    A_XScream_ NEAR
PUBLIC  A_XScream_

push  dx
mov   dx, SFX_SLOP
call  S_StartSound_
pop   dx
ret   

ENDP


PROC    A_Pain_ NEAR
PUBLIC  A_Pain_

push  bx
push  dx
push  bp
mov   bp, sp
sub   sp, 4
mov   bx, ax
mov   word ptr [bp - 4], GETPAINSOUNDADDR
mov   al, byte ptr ds:[bx + MOBJ_T.m_mobjtype]
mov   word ptr [bp - 2], INFOFUNCLOADSEGMENT
xor   ah, ah
call  dword ptr [bp - 4]
xor   ah, ah
mov   dx, ax
mov   ax, bx
call  S_StartSound_
LEAVE_MACRO 
pop   dx
pop   bx
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

push  dx
push  si
mov   si, ax
mov   dx, bx
imul  bx, word ptr ds:[si + MOBJ_T.m_targetRef], SIZEOF_THINKER_T
mov   cx, 128
add   bx, (OFFSET _thinkerlist + THINKER_T.t_data)
call  dword ptr ds:[_P_RadiusAttack]
pop   si
pop   dx
ret   

_some_lookup_table_4:

dw OFFSET table_4_label_0
dw OFFSET table_4_label_1
dw OFFSET table_4_label_2
dw OFFSET table_4_label_3


ENDP


PROC    A_BossDeath_ NEAR
PUBLIC  A_BossDeath_

push  bx
push  cx
push  dx
push  si
mov   bx, ax
mov   si, OFFSET _commercial
mov   cl, byte ptr ds:[bx + MOBJ_T.m_mobjtype]
cmp   byte ptr ds:[si], 0
jne   label_159
jmp   label_160
label_159:
mov   si, OFFSET _gamemap
cmp   byte ptr ds:[si], 7
je    label_161
jmp   exit_a_bossdeath
label_161:
cmp   cl, 8
je    label_164
cmp   cl, MT_BABY
label_165:
jne   exit_a_bossdeath
label_164:
mov   si, OFFSET _player + PLAYER_T.player_health
cmp   word ptr ds:[si], 0
jle   exit_a_bossdeath
lea   ax, ds:[bx - (OFFSET _thinkerlist + THINKER_T.t_data)]
xor   dx, dx
mov   bx, SIZEOF_THINKER_T
div   bx
mov   bx, OFFSET _thinkerlist + THINKER_T.t_next
mov   si, ax
mov   ax, word ptr ds:[bx]
test  ax, ax
je    label_162
label_166:
imul  bx, ax, SIZEOF_THINKER_T
mov   dx, word ptr ds:[bx + _thinkerlist + THINKER_T.t_prevFunctype]
xor   dl, dl
and   dh, (TF_FUNCBITS SHR 8)
cmp   dx, TF_MOBJTHINKER_HIGHBITS
je    jump_to_label_163
label_174:
imul  bx, ax, SIZEOF_THINKER_T
mov   ax, word ptr ds:[bx + OFFSET _thinkerlist + THINKER_T.t_next]
test  ax, ax
jne   label_166
label_162:
mov   bx, OFFSET _commercial
cmp   byte ptr ds:[bx], 0
je    jump_to_label_167
mov   bx, OFFSET _gamemap
cmp   byte ptr ds:[bx], 7
jne   jump_to_do_exit_level
cmp   cl, MT_FATSO
je    jump_to_label_170
cmp   cl, MT_BABY
jne   jump_to_do_exit_level
mov   bx, FLOOR_RAISETOTEXTURE
mov   dx, -1
mov   ax, TAG_667
call  EV_DoFloor_
exit_a_bossdeath:
pop   si
pop   dx
pop   cx
pop   bx
ret   
label_160:
mov   si, OFFSET _is_ultimate
cmp   byte ptr ds:[si], 0
jne   label_173
mov   si, OFFSET _gamemap
cmp   byte ptr ds:[si], 8
jne   exit_a_bossdeath
cmp   cl, MT_BRUISER
jne   label_164
mov   si, OFFSET _gameepisode
cmp   byte ptr ds:[si], 1
jmp   label_165
jump_to_label_163:
jmp   label_163
label_173:
mov   si, OFFSET _gameepisode
mov   al, byte ptr ds:[si]
dec   al
cmp   al, 3
ja    label_175
xor   ah, ah
mov   si, ax
add   si, ax
jmp   word ptr cs:[si + _some_lookup_table_4]
jump_to_label_167:
jmp   label_167
table_4_label_0:
mov   si, OFFSET _gamemap
cmp   byte ptr ds:[si], 8
jne   exit_a_bossdeath
cmp   cl, MT_BRUISER
jmp   label_165
jump_to_do_exit_level:
jmp   do_exit_level
jump_to_label_170:
jmp   label_170
table_4_label_1:
mov   si, OFFSET _gamemap
cmp   byte ptr ds:[si], 8
jne   exit_a_bossdeath
cmp   cl, MT_CYBORG
jmp   label_165
table_4_label_2:
mov   si, OFFSET _gamemap
cmp   byte ptr ds:[si], 8
jne   exit_a_bossdeath
cmp   cl, MT_SPIDER
jmp   label_165
table_4_label_3:
mov   si, OFFSET _gamemap
mov   al, byte ptr ds:[si]
cmp   al, 8
jne   label_171
cmp   cl, MT_SPIDER
jmp   label_165
label_171:
cmp   al, 6
jne   exit_a_bossdeath
cmp   cl, MT_CYBORG
jmp   label_165
label_175:
mov   si, OFFSET _gamemap
cmp   byte ptr ds:[si], 8
jmp   label_165
label_163:
add   bx, (OFFSET _thinkerlist + THINKER_T.t_data)
cmp   ax, si
jne   label_172
jump_to_label_174_2:
jmp   label_174
label_172:
cmp   cl, byte ptr ds:[bx + MOBJ_T.m_mobjtype]
jne   jump_to_label_174_2
cmp   word ptr ds:[bx + MOBJ_T.m_health], 0
jle   jump_to_label_174
jmp   exit_a_bossdeath
jump_to_label_174:
jmp   label_174
label_170:
mov   bx, FLOOR_LOWERFLOORTOLOWEST
mov   dx, -1
mov   ax, TAG_666
call  EV_DoFloor_
pop   si
pop   dx
pop   cx
pop   bx
ret   
label_167:
mov   bx, OFFSET _gameepisode
mov   al, byte ptr ds:[bx]
cmp   al, 4
jne   label_168
mov   bx, OFFSET _gamemap
mov   al, byte ptr ds:[bx]
cmp   al, 8
je    label_169
cmp   al, 6
jne   do_exit_level
mov   dx, DOOR_BLAZEOPEN
mov   ax, TAG_666
call  EV_DoDoor_
pop   si
pop   dx
pop   cx
pop   bx
ret   
label_168:
cmp   al, 1
jne   do_exit_level
label_169:
mov   bx, FLOOR_LOWERFLOORTOLOWEST
mov   dx, -1
mov   ax, TAG_666
call  EV_DoFloor_
pop   si
pop   dx
pop   cx
pop   bx
ret   
do_exit_level:
call  G_ExitLevel_
pop   si
pop   dx
pop   cx
pop   bx
ret   

ENDP


PROC    A_Hoof_ NEAR
PUBLIC  A_Hoof_

push  dx
push  si
mov   si, ax
mov   dx, SFX_HOOF
call  S_StartSound_
mov   ax, si
call  A_Chase_
pop   si
pop   dx
ret   

ENDP


PROC    A_Metal_ NEAR
PUBLIC  A_Metal_

push  dx
push  si
mov   si, ax
mov   dx, SFX_METAL
call  S_StartSound_
mov   ax, si
call  A_Chase_
pop   si
pop   dx
ret   

ENDP


PROC    A_BabyMetal_ NEAR
PUBLIC  A_BabyMetal_

push  dx
push  si
mov   si, ax
mov   dx, SFX_BSPWLK
call  S_StartSound_
mov   ax, si
call  A_Chase_
pop   si
pop   dx
ret   

ENDP


PROC    A_BrainAwake_ NEAR
PUBLIC  A_BrainAwake_

push  bx
push  dx
mov   bx, OFFSET _numbraintargets
mov   word ptr ds:[bx], 0
mov   bx, OFFSET _braintargeton
mov   word ptr ds:[bx], 0
mov   bx, OFFSET _thinkerlist + THINKER_T.t_next
mov   ax, word ptr ds:[bx]
test  ax, ax
je    label_176
label_177:
imul  bx, ax, SIZEOF_THINKER_T
mov   dx, word ptr ds:[bx + _thinkerlist + THINKER_T.t_prevFunctype]
xor   dl, dl
and   dh, (TF_FUNCBITS SHR 8)
cmp   dx, TF_MOBJTHINKER_HIGHBITS
je    label_178
label_179:
imul  bx, ax, SIZEOF_THINKER_T
mov   ax, word ptr ds:[bx + OFFSET _thinkerlist + THINKER_T.t_next]
test  ax, ax
jne   label_177
label_176:
mov   dx, SFX_BOSSIT
xor   ax, ax
call  S_StartSound_
pop   dx
pop   bx
ret   
label_178:
add   bx, (OFFSET _thinkerlist + THINKER_T.t_data)
cmp   byte ptr ds:[bx + MOBJ_T.m_mobjtype], MT_BOSSTARGET
jne   label_179
mov   bx, OFFSET _numbraintargets
mov   bx, word ptr ds:[bx]
add   bx, bx
mov   word ptr ds:[bx + _braintargets], ax
mov   bx, OFFSET _numbraintargets
inc   word ptr ds:[bx]
jmp   label_179

ENDP


PROC    A_BrainPain_ NEAR
PUBLIC  A_BrainPain_

push  dx
mov   dx, SFX_BOSPN
xor   ax, ax
call  S_StartSound_
pop   dx
ret   

ENDP


PROC    A_BrainScream_ NEAR
PUBLIC  A_BrainScream_

push  dx
push  si
push  di
push  bp
mov   bp, sp
sub   sp, 6
mov   di, bx
mov   word ptr [bp - 2], cx
mov   es, cx
mov   word ptr [bp - 6], 0
mov   ax, word ptr es:[di]
mov   si, word ptr es:[di + 2]
mov   word ptr [bp - 4], ax
sub   si, 196
label_181:
mov   es, word ptr [bp - 2]
mov   ax, word ptr es:[di + 2]
add   ax, 320
cmp   si, ax
jl    label_2
mov   dx, SFX_BOSDTH
xor   ax, ax
call  S_StartSound_
LEAVE_MACRO 
pop   di
pop   si
pop   dx
ret   
label_2:
mov   dx, word ptr es:[di + MOBJ_POS_T.mp_y + 0]
mov   cx, word ptr es:[di + MOBJ_POS_T.mp_y + 2]
call  P_Random_
mov   bl, al
xor   bh, bh
push  -1 ; todo 186
add   bx, bx
push  MT_ROCKET  ; todo 186
add   bx, 128
sub   cx, 320
push  bx
mov   ax, word ptr [bp - 4]
push  word ptr [bp - 6]
mov   bx, dx
mov   dx, si
call  P_SpawnMobj_
mov   bx, OFFSET _setStateReturn
mov   bx, word ptr ds:[bx]
call  P_Random_
mov   cl, al
xor   ch, ch
mov   ax, cx
shl   ax, 9
cwd   
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
jae   label_180
label_182:
mov   byte ptr ds:[bx + MOBJ_T.m_tics], 1
add   si, 8
jmp   label_181
label_180:
cmp   al, 240
ja    label_182
add   si, 8
jmp   label_181

ENDP


PROC    A_BrainExplode_ NEAR
PUBLIC  A_BrainExplode_

push  dx
push  si
push  di
call  P_Random_
mov   dl, al
call  P_Random_
xor   dh, dh
xor   ah, ah
sub   dx, ax
mov   es, cx
mov   ax, dx
mov   si, word ptr es:[bx]
shl   ax, SIZEOF_MOBJINFO_T
mov   di, word ptr es:[bx + MOBJ_POS_T.mp_y + 0]
cwd   
mov   cx, word ptr es:[bx + MOBJ_POS_T.mp_y + 2]
add   si, ax
adc   dx, word ptr es:[bx + MOBJ_POS_T.mp_x + 2]
call  P_Random_
xor   ah, ah
push  -1 ; todo 186
add   ax, ax
push  MT_ROCKET ; todo 186
add   ax, 128
push  ax
mov   bx, di
push  0 ; todo 186
mov   ax, si
call  P_SpawnMobj_
mov   bx, OFFSET _setStateReturn
mov   bx, word ptr ds:[bx]
call  P_Random_
xor   ah, ah
shl   ax, 9
cwd   
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
jb    label_184
cmp   al, 240
ja    label_184
pop   di
pop   si
pop   dx
ret   
label_184:
mov   byte ptr ds:[bx + MOBJ_T.m_tics], 1
pop   di
pop   si
pop   dx
ret   

ENDP


PROC    A_BrainSpit_ NEAR
PUBLIC  A_BrainSpit_

push  dx
push  si
push  di
push  bp
mov   bp, sp
sub   sp, 0Ah
mov   di, ax
mov   si, bx
mov   word ptr [bp - 2], cx
mov   bx, OFFSET _brainspit_easy
xor   byte ptr ds:[bx], 1
cmp   byte ptr ds:[_gameskill], SK_EASY
ja    label_183
cmp   byte ptr ds:[bx], 0
jne   label_183
LEAVE_MACRO 
pop   di
pop   si
pop   dx
ret   
label_183:
mov   bx, OFFSET _braintargeton
mov   bx, word ptr ds:[bx]
add   bx, bx
mov   ax, word ptr ds:[bx + _braintargets]
mov   bx, OFFSET _braintargeton
mov   word ptr [bp - 8], ax
mov   ax, word ptr ds:[bx]
inc   ax
mov   bx, OFFSET _numbraintargets
cwd   
idiv  word ptr ds:[bx]
mov   bx, OFFSET _braintargeton
mov   word ptr ds:[bx], dx
imul  dx, word ptr [bp - 8], SIZEOF_THINKER_T
imul  bx, word ptr [bp - 8], SIZEOF_MOBJ_POS_T
push  MT_SPAWNSHOT ; todo 186
mov   cx, word ptr [bp - 2]
mov   ax, di
add   dx, (OFFSET _thinkerlist + THINKER_T.t_data)
mov   word ptr [bp - 4], bx
mov   bx, si
mov   di, OFFSET _setStateReturn
call  dword ptr ds:[_P_SpawnMissile]
mov   bx, OFFSET _setStateReturn_pos
mov   ax, word ptr [bp - 8]
mov   di, word ptr ds:[di]
les   dx, dword ptr ds:[bx]
mov   bx, dx
mov   word ptr ds:[di + MOBJ_T.m_targetRef], ax
mov   dx, word ptr es:[bx + MOBJ_POS_T.mp_statenum]
mov   bx, dx
shl   bx, 2
sub   bx, dx
mov   dx, STATES_SEGMENT
add   bx, bx
mov   es, dx
mov   al, byte ptr es:[bx + 2]
mov   word ptr [bp - 0Ah], MOBJPOSLIST_6800_SEGMENT
cbw  
add   bx, 2
cwd   
mov   bx, word ptr [bp - 4]
mov   cx, ax
mov   ax, word ptr ds:[di + MOBJ_T.m_momy + 2]
mov   es, word ptr [bp - 0Ah]
mov   word ptr [bp - 6], ax
mov   ax, word ptr es:[bx + MOBJ_POS_T.mp_y + 2]
mov   es, word ptr [bp - 2]
mov   word ptr [bp - 4], dx
sub   ax, word ptr es:[si + MOBJ_POS_T.mp_y + 2]
mov   bx, word ptr [bp - 6]
cwd   
call  FastDiv3216u_
mov   bx, cx
mov   cx, word ptr [bp - 4]
call  __I4D
mov   dx, SFX_BOSPIT
mov   byte ptr ds:[di + MOBJ_T.m_reactiontime], al
xor   ax, ax
call  S_StartSound_
LEAVE_MACRO 
pop   di
pop   si
pop   dx
ret   

ENDP


PROC    A_SpawnSound_ NEAR
PUBLIC  A_SpawnSound_

push  dx
push  si
mov   si, ax
mov   dx, SFX_BOSCUB
call  S_StartSound_
mov   ax, si
call  A_SpawnFly_
pop   si
pop   dx
ret   

ENDP


PROC    A_SpawnFly_ NEAR
PUBLIC  A_SpawnFly_

push  dx
push  si
push  di
push  bp
mov   bp, sp
sub   sp, 0Ah
mov   di, ax
mov   word ptr [bp - 0Ah], GETSEESTATEADDR
mov   word ptr [bp - 8], INFOFUNCLOADSEGMENT
dec   byte ptr ds:[di + MOBJ_T.m_reactiontime]
je    do_spawnfly
LEAVE_MACRO 
pop   di
pop   si
pop   dx
ret   
do_spawnfly:
mov   si, word ptr ds:[di + MOBJ_T.m_targetRef]
imul  ax, si, SIZEOF_THINKER_T
imul  si, si, SIZEOF_MOBJ_POS_T
add   ax, (OFFSET _thinkerlist + THINKER_T.t_data)
mov   word ptr [bp - 6], ax
mov   bx, word ptr [bp - 6]
push  word ptr ds:[bx + MOBJ_T.m_secnum]
mov   ax, MOBJPOSLIST_6800_SEGMENT
push  MT_SPAWNFIRE ; todo 186
mov   es, ax
mov   word ptr [bp - 2], ax
push  word ptr es:[si + MOBJ_POS_T.mp_z + 2]
mov   bx, word ptr es:[si + MOBJ_POS_T.mp_y + 0]
mov   cx, word ptr es:[si + MOBJ_POS_T.mp_y + 2]
mov   ax, word ptr es:[si]
push  word ptr es:[si + MOBJ_POS_T.mp_z + 0]
mov   dx, word ptr es:[si + 2]
call  P_SpawnMobj_
mov   bx, OFFSET _setStateReturn
mov   dx, SFX_TELEPT
mov   ax, word ptr ds:[bx]
mov   word ptr [bp - 4], si
call  S_StartSound_
call  P_Random_
cmp   al, 50
jb    spawn_imp
jmp   spawn_non_imp
spawn_imp:
mov   al, SIZEOF_MOBJINFO_T
chose_spawn_unit:
mov   bx, word ptr [bp - 6]
xor   ah, ah
push  word ptr ds:[bx + MOBJ_T.m_secnum]
les   bx, dword ptr [bp - 4]
push  ax
mov   si, word ptr [bp - 4]
push  word ptr es:[bx + MOBJ_POS_T.mp_z + 2]
mov   cx, word ptr es:[si + MOBJ_POS_T.mp_y + 2]
mov   ax, word ptr es:[si]
mov   dx, word ptr es:[si + 2]
push  word ptr es:[bx + MOBJ_POS_T.mp_z + 0]
mov   bx, word ptr es:[bx + MOBJ_POS_T.mp_y + 0]
call  P_SpawnMobj_
imul  si, ax, SIZEOF_THINKER_T
imul  bx, ax, SIZEOF_MOBJ_POS_T
add   si, (OFFSET _thinkerlist + THINKER_T.t_data)
mov   dx, 1
mov   ax, si
mov   cx, MOBJPOSLIST_6800_SEGMENT
call  P_LookForPlayers_
test  al, al
je    label_185
mov   al, byte ptr ds:[si + MOBJ_T.m_mobjtype]
xor   ah, ah
call  dword ptr [bp - 0Ah]
mov   dx, ax
mov   ax, si
call  P_SetMobjState_
label_185:
push  word ptr ds:[si + 4]
mov   es, cx
push  word ptr es:[bx + MOBJ_POS_T.mp_y + 2]
push  word ptr es:[bx + MOBJ_POS_T.mp_y + 0]
push  word ptr es:[bx + 2]
push  word ptr es:[bx]
mov   ax, si
call  dword ptr ds:[_P_TeleportMove]
mov   ax, di
call  P_RemoveMobj_
LEAVE_MACRO 
pop   di
pop   si
pop   dx
ret   
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

ENDP


PROC    A_PlayerScream_ NEAR
PUBLIC  A_PlayerScream_

push  bx
push  dx
mov   bx, OFFSET _commercial
mov   al, SFX_PLDETH 
cmp   byte ptr ds:[bx], 0
je    label_186
mov   bx, OFFSET _playerMobj
mov   bx, word ptr ds:[bx]
cmp   word ptr ds:[bx + MOBJ_T.m_health], -50
jge   label_186
mov   al, SFX_PDIEHI
label_186:
xor   ah, ah
mov   bx, OFFSET _playerMobj
mov   dx, ax
mov   ax, word ptr ds:[bx]
call  S_StartSound_
pop   dx
pop   bx
ret   

ENDP

PROC    P_ENEMY_ENDMARKER_ 
PUBLIC  P_ENEMY_ENDMARKER_
ENDP



END
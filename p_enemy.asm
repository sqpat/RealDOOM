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
EXTRN G_ExitLevel_:PROC

EXTRN EV_DoDoor_:PROC
EXTRN EV_DoFloor_:NEAR
EXTRN __I4D:PROC

.DATA

EXTRN _gameskill:BYTE
EXTRN _gametic:DWORD
EXTRN _fastparm:BYTE
EXTRN _diags:WORD
EXTRN _opposite:WORD



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

; todo cx/bx should not need to be on stac

PROC    P_CheckMeleeRange_ NEAR
PUBLIC  P_CheckMeleeRange_

; bp - 2    mobj (arg)
; bp - 4    targ (pl)
; bp - 6    

push  si
xchg  ax, si
cmp   word ptr ds:[si + MOBJ_T.m_targetRef], 0
jne   do_check_meleerange

xor   ax, ax
pop   si
ret   

do_check_meleerange:

push  bx
push  cx
push  dx
push  di

push  si  ; bp - 2


mov   di, bx
mov   cx, MOBJPOSLIST_6800_SEGMENT  ; might not be necessary. whatever.
mov   es, cx


mov   si, word ptr ds:[si + MOBJ_T.m_targetRef]

IF COMPISA GE COMPILE_186
    imul  bx, si, SIZEOF_THINKER_T
    add   bx, (OFFSET _thinkerlist + THINKER_T.t_data)
    imul  si, si, SIZEOF_MOBJ_POS_T
ELSE
    mov   ax, SIZEOF_THINKER_T
    mul   si
    mov   bx, ax
    add   bx, (OFFSET _thinkerlist + THINKER_T.t_data)
    mov   ax, SIZEOF_MOBJ_POS_T
    mul   si
    mov   si, ax

ENDIF


push  bx  ; bp - 4


mov   al, SIZEOF_MOBJINFO_T
mul   byte ptr ds:[bx + MOBJ_T.m_mobjtype]
xchg  ax, bx
add   bx, (OFFSET _mobjinfo + MOBJINFO_T.mobjinfo_radius)
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

db    09Ah
dw    P_APROXDISTANCEOFFSET, PHYSICS_HIGHCODE_SEGMENT

;physics_highcode_segment, 		 P_AproxDistanceOffset

pop   ax  ; bp - 6
cmp   dx, ax
pop   dx  ; bp - 4
pop   ax  ; bp - 2
jnl   exit_check_meleerange_return_0
mov   bx,  di
lea   cx, [si - 8] ; because of lodsw increment above..
db    09Ah
dw    P_CHECKSIGHTOFFSET, PHYSICS_HIGHCODE_SEGMENT
test  al, al
jne   exit_check_meleerange_return_1
jmp   exit_check_meleerange
exit_check_meleerange_return_1:
mov   ax, 1
exit_check_meleerange:
pop   di
pop   dx
pop   cx
pop   bx
pop   si
ret  
exit_check_meleerange_return_0:
xor   ax, ax
jmp   exit_check_meleerange

ENDP


PROC    P_CheckMissileRange_ NEAR
PUBLIC  P_CheckMissileRange_


PUSHA_NO_AX_OR_BP_MACRO
push  bp
mov   bp, sp
mov   di, ax
mov   si, bx

IF COMPISA GE COMPILE_186
    imul  bx, word ptr ds:[di + MOBJ_T.m_targetRef], SIZEOF_THINKER_T
ELSE
    mov   ax, SIZEOF_THINKER_T 
    mul   word ptr ds:[di + MOBJ_T.m_targetRef]
    mov   bx, ax
ENDIF

mov   cx, SIZEOF_THINKER_T

; di is actor mobj
; si is actorpos
; bx is targ mobj

xor   dx, dx
mov   ax, bx
div   cx
; ax has index...

IF COMPISA GE COMPILE_186
    imul  cx, ax, SIZEOF_MOBJ_POS_T
ELSE
    mov   dx, SIZEOF_MOBJ_POS_T
    mul   dx
    mov   cx, ax
ENDIF

push  cx  ; bp - 2  store mobjpos for x/y subtraction later

lea   dx, ds:[bx + (OFFSET _thinkerlist + THINKER_T.t_data)]
mov   ax, di
mov   bx, si

db    09Ah
dw    P_CHECKSIGHTOFFSET, PHYSICS_HIGHCODE_SEGMENT

test  al, al
je    exit_checkmissilerange_return_0
mov   ax, MOBJPOSLIST_6800_SEGMENT
mov   es, ax
test  byte ptr es:[si + MOBJ_POS_T.mp_flags1], MF_JUSTHIT
jne   just_hit_enemy
cmp   byte ptr ds:[di + MOBJ_T.m_reactiontime], 0
je    ready_to_attack
exit_checkmissilerange_return_0:
LEAVE_MACRO 
POPA_NO_AX_OR_BP_MACRO
xor   ax, ax
ret   
just_hit_enemy:
and   byte ptr es:[si + MOBJ_POS_T.mp_flags1], (NOT MF_JUSTHIT)
jmp   exit_checkmissilerange_return_1
ready_to_attack:
xor   ax, ax
mov   al, byte ptr ds:[di + MOBJ_T.m_mobjtype];
pop   di   ; bp - 2 dont need actor ptr anymore. only use type ahead of here.
push  ax   ; bp - 2 store type.

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

db    09Ah
dw    P_APROXDISTANCEOFFSET, PHYSICS_HIGHCODE_SEGMENT

pop   ax  ; bp - 2
push  ax  ; bp - 2
sub   dx, 64

db    09Ah
dw    GETMELEESTATEADDR, INFOFUNCLOADSEGMENT

test  ax, ax
jne   has_melee

;		dist -= 128;	// no melee attack, so fire more

sub   dx, 128
has_melee:
pop   ax  ; get type
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
xor   ah, ah
cmp   ax, dx
jge   exit_checkmissilerange_return_1
LEAVE_MACRO 
POPA_NO_AX_OR_BP_MACRO
xor   ax, ax
ret   
missile_not_cyberdemon:
cmp   al, MT_SPIDER
je    missile_is_spider_skull_cyborg
cmp   al, MT_SKULL
je    missile_is_spider_skull_cyborg
jmp   missile_dist_200_check
exit_checkmissilerange_return_1:
LEAVE_MACRO 
POPA_NO_AX_OR_BP_MACRO
mov   al, 1
ret   
ENDP



_p_move_dir_switch_table:

dw OFFSET switch_movedir_0
dw OFFSET switch_movedir_1
dw OFFSET switch_movedir_2
dw OFFSET switch_movedir_3
dw OFFSET switch_movedir_4
dw OFFSET switch_movedir_5
dw OFFSET switch_movedir_6
dw OFFSET switch_movedir_7




  

PROC    P_Move_ NEAR
PUBLIC  P_Move_


push  dx
push  si
push  di
push  bp
mov   bp, sp

; di/si have the offsets already

cmp   byte ptr ds:[si + MOBJ_T.m_movedir], DI_NODIR

jne   do_pmove
xor   ax, ax
jmp   exit_p_move

do_pmove:
mov   cx, MOBJPOSLIST_6800_SEGMENT
mov   es, cx
mov   al, SIZEOF_MOBJINFO_T 
mul   byte ptr ds:[si + MOBJ_T.m_mobjtype]
xchg  ax, bx
xor   ax, ax
mov   al, byte ptr ds:[bx + (OFFSET _mobjinfo + MOBJINFO_T.mobjinfo_speed)]
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


jmp   word ptr cs:[bx + OFFSET _p_move_dir_switch_table]


switch_movedir_0:
add   word ptr [bp - 6], ax

got_x_y_for_trymove: 


mov   bx, di
mov   ax, si
;mov   cx, MOBJPOSLIST_6800_SEGMENT ; this was set above.



;call  dword ptr ds:[_P_TryMove]
db    09Ah
dw    P_TRYMOVEOFFSET, PHYSICS_HIGHCODE_SEGMENT


mov   cx, MOBJPOSLIST_6800_SEGMENT
mov   es, cx
test  al, al
jne   try_ok
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
mov   al, 1
exit_p_move:
LEAVE_MACRO 
pop   di
pop   si
pop   dx
ret 

check_for_specials_hit_in_move:
cmp   word ptr ds:[_numspechit], 0
jne  specials_hit

xor   ax, ax
jmp   exit_p_move
specials_hit:
; specials hit..
mov   bx, SIZEOF_THINKER_T
lea   ax, ds:[si - (OFFSET _thinkerlist + THINKER_T.t_data)]
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
;call  P_UseSpecialLine_
db 0FFh  ; lcall[addr]
db 01Eh  ;
dw _P_UseSpecialLine_addr
test  al, al
je    do_next_spechit
mov   word ptr [bp - 2], 1
jmp   do_next_spechit
end_spechit_loop:
pop   ax  ;  result
LEAVE_MACRO 
pop   di
pop   si
pop   dx
ret   
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


PROC    P_TryWalk_ NEAR
PUBLIC  P_TryWalk_

; si/di have the ptr offsets.

;todo change this to take si/di instead of ax/bx/cx... 


call  P_Move_
test  al, al
je    exit_try_walk  ; al 0
call  P_Random_
and   ax, 15  ; todo al once proper random
mov   word ptr ds:[si + MOBJ_T.m_movecount], ax
mov   al, 1
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
mov   ah, byte ptr ds:[bx + _opposite] ; todo make cs?
push  ax  ; bp - 2. both movedir and opposite.
push  ax  ; garbage push instead of sub sp 2 to hold d[1] d[2]

mov   es, si  ; backup si

IF COMPISA GE COMPILE_186
    imul  si, word ptr ds:[si + MOBJ_T.m_targetRef], SIZEOF_MOBJ_POS_T
ELSE
    mov  ax, SIZEOF_MOBJ_POS_T
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


mov   al, byte ptr ds:[si + _diags]  ; do diags lookup. todo make cs table
mov   si, es    ; restore mobj ptr.

mov   byte ptr ds:[si + MOBJ_T.m_movedir], al
cmp   al, byte ptr [bp - 1]     ; turnaround check.

je    no_direct_route_restore_deltax_delta_y_1

push  bx
push  cx

call  P_TryWalk_
test  al, al
je    no_direct_route_restore_deltax_delta_y_2

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
test  al, al
jne   exit_p_newchasedir

dont_try_d1:
mov   al, byte ptr [bp - 3]
cmp   al, DI_NODIR
je    dont_try_d2
mov   byte ptr ds:[si + MOBJ_T.m_movedir], al
call  P_TryWalk_
test  al, al
jne   exit_p_newchasedir

dont_try_d2:
mov   al, byte ptr [bp - 2]
cmp   al, DI_NODIR
je    dont_try_olddir
mov   byte ptr ds:[si + MOBJ_T.m_movedir], al
call  P_TryWalk_
test  al, al
jne   exit_p_newchasedir

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
test  al, al
jne   exit_p_newchasedir

do_next_chase_try_loop:
inc   dl
cmp   dl, DI_SOUTHEAST
jle   loop_next_chase_try

check_turnaround:
cmp   dh, DI_NODIR
je    set_nodir_exit_p_newchasedir


mov   byte ptr ds:[si + MOBJ_T.m_movedir], dh
call  P_TryWalk_
test  al, al
jne   exit_p_newchasedir



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
test  al, al
jne   exit_p_newchasedir
do_next_chase_try_loop_from_southeast:
dec   dl
jns   loop_next_chase_try_from_southeast

jmp   check_turnaround


ENDP


PROC    P_LookForPlayers_ NEAR
PUBLIC  P_LookForPlayers_

; boolean __near P_LookForPlayers (mobj_t __near*	actor, boolean	allaround ) {


; bp - 2   allaround (dl)
; bp - 4   some temp thing

cmp   word ptr ds:[_player + PLAYER_T.player_health], 0
jg    do_look_for_players
xor   al, al
ret

do_look_for_players:

push  bx
push  cx
push  si
push  di
push  bp
mov   bp, sp
push  dx
mov   di, ax



mov   bx, SIZEOF_THINKER_T
sub   ax, (OFFSET _thinkerlist + THINKER_T.t_data)
xor   dx, dx
div   bx



IF COMPISA GE COMPILE_186
    imul  si, ax, SIZEOF_MOBJ_POS_T
ELSE
    mov  dx, SIZEOF_MOBJ_POS_T
    mul  ax
    xchg ax, si
ENDIF

mov   cx, word ptr ds:[_playerMobj_pos]


mov   dx, word ptr ds:[_playerMobj]
mov   bx, si
mov   ax, di
;call  dword ptr ds:[_P_CheckSightTemp]
db    09Ah
dw    P_CHECKSIGHTOFFSET, PHYSICS_HIGHCODE_SEGMENT

test  al, al
je    exit_look_for_players_2
cmp   byte ptr [bp - 2], 0
je    check_angle_for_player
look_set_target_player:
push  ss
pop   ds  ; might have been unset in some paths.
mov   ax, word ptr ds:[_playerMobjRef]
mov   word ptr ds:[di + MOBJ_T.m_targetRef], ax
mov   al, 1
exit_look_for_players_2:
LEAVE_MACRO 
pop   di
pop   si
pop   cx
pop   bx
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

mov   si, word ptr ds:[_playerMobj_pos]


sub   ax, word ptr ds:[si + MOBJ_POS_T.mp_x + 0]
sbb   dx, word ptr ds:[si + MOBJ_POS_T.mp_x + 2]
sub   bx, word ptr ds:[si + MOBJ_POS_T.mp_y + 0]
sbb   cx, word ptr ds:[si + MOBJ_POS_T.mp_y + 2]

push  ss
pop   ds

db    09Ah
dw    P_APROXDISTANCEOFFSET, PHYSICS_HIGHCODE_SEGMENT
cmp   dx, MELEERANGE
jnle  exit_look_for_players_return_0
jne   look_set_target_player
test  ax, ax
jbe   look_set_target_player
exit_look_for_players_return_0:
xor   al, al
exit_look_for_players:
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

mov   si, ax
push  word ptr ds:[si + MOBJ_T.m_mobjtype]

mov   es, cx
mov   cx, SIZEOF_THINKER_T
xor   dx, dx
lea   ax, ds:[si - (OFFSET _thinkerlist + THINKER_T.t_data)]
div   cx

; inlined A_Fall_
and   byte ptr es:[bx + MOBJ_POS_T.mp_flags1], (NOT MF_SOLID)


mov   cx, ax
mov   ax, word ptr ds:[_thinkerlist + THINKER_T.t_next]

loop_next_thinker_keendie:

IF COMPISA GE COMPILE_186
    imul  bx, ax, SIZEOF_THINKER_T
ELSE
    mov  dx, SIZEOF_THINKER_T
    mul  ax
    xchg ax, bx
ENDIF

mov   dx, word ptr ds:[bx + _thinkerlist]
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

mov   ax, word ptr ds:[bx + OFFSET _thinkerlist + THINKER_T.t_next]
test  ax, ax
jne   loop_next_thinker_keendie

; done iteratng
mov   dx, DOOR_OPEN
mov   ax, TAG_666
call  EV_DoDoor_
exit_keen_die:
LEAVE_MACRO 
pop   si
pop   dx
ret   


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
;call  dword ptr ds:[_P_CheckSightTemp]
db    09Ah
dw    P_CHECKSIGHTOFFSET, PHYSICS_HIGHCODE_SEGMENT

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
;call  S_StartSound_
db 0FFh  ; lcall[addr]
db 01Eh  ;
dw _S_StartSound_addr
label_86:
mov   al, byte ptr ds:[si + MOBJ_T.m_mobjtype]
xor   ah, ah
call  dword ptr [bp - 8]
mov   dx, ax
mov   ax, si
;call  P_SetMobjState_
db 0FFh  ; lcall[addr]
db 01Eh  ;
dw _P_SetMobjState_addr
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
;call  P_SetMobjState_
db 0FFh  ; lcall[addr]
db 01Eh  ;
dw _P_SetMobjState_addr
jmp   exit_a_chase
label_110:

call  P_NewChaseDir_
jmp   exit_a_chase
label_107:
mov   al, byte ptr ds:[si + MOBJ_T.m_mobjtype]
xor   ah, ah
call  dword ptr [bp - 0Ch]
test  ax, ax
je    label_108
mov   ax, si
mov   bx, di
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


call  P_Move_
test  al, al
jne   label_102
label_101:


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
;call  S_StartSound_
db 0FFh  ; lcall[addr]
db 01Eh  ;
dw _S_StartSound_addr

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
;call  S_StartSound_
db 0FFh  ; lcall[addr]
db 01Eh  ;
dw _S_StartSound_addr

mov   al, byte ptr ds:[si + MOBJ_T.m_mobjtype]
xor   ah, ah
call  dword ptr [bp - 0Ch]
mov   dx, ax
mov   ax, si
;call  P_SetMobjState_
db 0FFh  ; lcall[addr]
db 01Eh  ;
dw _P_SetMobjState_addr
LEAVE_MACRO 
pop   di
pop   si
pop   dx
ret   
label_103:
mov   ax, si
mov   bx, di
call  P_CheckMissileRange_
test  al, al
je    label_104
mov   al, byte ptr ds:[si + MOBJ_T.m_mobjtype]
xor   ah, ah
call  dword ptr [bp - 010h]
mov   dx, ax
mov   ax, si
;call  P_SetMobjState_
db 0FFh  ; lcall[addr]
db 01Eh  ;
dw _P_SetMobjState_addr
mov   es, word ptr [bp - 2]
or    byte ptr es:[di + MOBJ_POS_T.mp_flags1], MF_JUSTATTACKED
LEAVE_MACRO 
pop   di
pop   si
pop   dx
ret   

ENDP

; void __near A_FaceTarget (mobj_t __near* actor){	

PROC    A_FaceTarget_ NEAR
PUBLIC  A_FaceTarget_


PUSHA_NO_AX_OR_BP_MACRO

mov   bx, ax
cmp   word ptr ds:[bx + MOBJ_T.m_targetRef], 0
je    exit_a_facetarget
mov   cx, SIZEOF_THINKER_T
sub   ax, (OFFSET _thinkerlist + THINKER_T.t_data)
xor   dx, dx
div   cx

IF COMPISA GE COMPILE_186
    imul  si, ax, SIZEOF_MOBJ_POS_T
ELSE
    mov  dx, SIZEOF_MOBJ_POS_T
    mul  dx
    xchg ax, si
ENDIF


IF COMPISA GE COMPILE_186
    imul  di, word ptr ds:[bx + MOBJ_T.m_targetRef], SIZEOF_MOBJ_POS_T
ELSE
    mov  ax, SIZEOF_MOBJ_POS_T
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
mov   bl, al
call  P_Random_
xor   bh, bh
xor   ah, ah
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

PUSHA_NO_AX_OR_BP_MACRO

mov   si, ax
cmp   word ptr ds:[si + MOBJ_T.m_targetRef], 0
je    exit_a_posattack

do_a_posattack:

mov   bx, SIZEOF_THINKER_T
sub   ax, (OFFSET _thinkerlist + THINKER_T.t_data)
xor   dx, dx
div   bx

IF COMPISA GE COMPILE_186
    imul  bx, ax, SIZEOF_MOBJ_POS_T
ELSE
    mov  dx, SIZEOF_MOBJ_POS_T
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
;call  dword ptr ds:[_P_AimLineAttack]
db    09Ah
dw    P_AIMLINEATTACKOFFSET, PHYSICS_HIGHCODE_SEGMENT

mov   bx, ax
mov   di, dx
mov   dx, SFX_PISTOL
mov   ax, si
;call  S_StartSound_
db 0FFh  ; lcall[addr]
db 01Eh  ;
dw _S_StartSound_addr


;    angle = MOD_FINE_ANGLE(angle + (((P_Random()-P_Random())<<(20-ANGLETOFINESHIFT))));
;    damage = ((P_Random()%5)+1)*3;

call  P_Random_
mov   dl, al
call  P_Random_
xor   dh, dh
xor   ah, ah
sub   dx, ax
sal   dx, 1
add   dx, cx ; angle into dx.
and   dh, (FINEMASK SHR 8)


call  P_Random_
xor   ah, ah
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
;call  dword ptr ds:[_P_LineAttack]
db    09Ah
dw    P_LINEATTACKOFFSET, PHYSICS_HIGHCODE_SEGMENT

exit_a_posattack:
POPA_NO_AX_OR_BP_MACRO
ret   

ENDP


PROC    A_SPosAttack_ NEAR
PUBLIC  A_SPosAttack_

PUSHA_NO_AX_OR_BP_MACRO
push  bp
mov   bp, sp
mov   di, ax
cmp   word ptr ds:[di + MOBJ_T.m_targetRef], 0
je    exit_a_sposattack


do_a_sposattack:
mov   si, SIZEOF_THINKER_T
sub   ax, (OFFSET _thinkerlist + THINKER_T.t_data)
xor   dx, dx
div   si

IF COMPISA GE COMPILE_186
    imul  si, ax, SIZEOF_MOBJ_POS_T
ELSE
    mov  dx, SIZEOF_MOBJ_POS_T
    mul  dx
    xchg ax, si
ENDIF


mov   dx, SFX_SHOTGN
mov   ax, di
;call  S_StartSound_
db 0FFh  ; lcall[addr]
db 01Eh  ;
dw _S_StartSound_addr

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
;call  dword ptr ds:[_P_AimLineAttack]
db    09Ah
dw    P_AIMLINEATTACKOFFSET, PHYSICS_HIGHCODE_SEGMENT

push  ax ; bp - 2
push  dx ; bp - 4
mov   cx, 3

do_next_shotgun_pellet:

;	angle = MOD_FINE_ANGLE((bangle + ((P_Random()-P_Random())<<(20-ANGLETOFINESHIFT))));

call  P_Random_

mov   dl, al
call  P_Random_
xor   dh, dh
xor   ah, ah

sub   dx, ax

sal   dx, 1
add   dx, si ; bangle
and   dx, FINEMASK

;		damage = ((P_Random()%5)+1)*3;
call  P_Random_
xor   ah, ah
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
;call  dword ptr ds:[_P_LineAttack]
db    09Ah
dw    P_LINEATTACKOFFSET, PHYSICS_HIGHCODE_SEGMENT

loop  do_next_shotgun_pellet

exit_a_sposattack:
LEAVE_MACRO 
POPA_NO_AX_OR_BP_MACRO
ret   

ENDP


PROC    A_CPosAttack_ NEAR
PUBLIC  A_CPosAttack_


PUSHA_NO_AX_OR_BP_MACRO

mov   si, ax
cmp   word ptr ds:[si + MOBJ_T.m_targetRef], 0
je    exit_a_cposattack

do_cposattack:

mov   bx, SIZEOF_THINKER_T
sub   ax, (OFFSET _thinkerlist + THINKER_T.t_data)
xor   dx, dx
div   bx

IF COMPISA GE COMPILE_186
    imul  bx, ax, SIZEOF_MOBJ_POS_T
ELSE
    mov  dx, SIZEOF_MOBJ_POS_T
    mul  dx
    xchg ax, bx
ENDIF

mov   dx, SFX_SHOTGN
mov   ax, si
;call  S_StartSound_
db 0FFh  ; lcall[addr]
db 01Eh  ;
dw _S_StartSound_addr

mov   ax, si
call  A_FaceTarget_

mov   cx, MOBJPOSLIST_6800_SEGMENT
mov   es, cx
mov   cx, word ptr es:[bx + MOBJ_POS_T.mp_angle + 2]
mov   ax, si
SHIFT_MACRO shr   cx 3
mov   bx, MISSILERANGE
mov   dx, cx
;call  dword ptr ds:[_P_AimLineAttack]
db    09Ah
dw    P_AIMLINEATTACKOFFSET, PHYSICS_HIGHCODE_SEGMENT

mov   di, ax
mov   bx, dx

call  P_Random_
mov   dl, al
call  P_Random_
xor   dh, dh
xor   ah, ah
sub   dx, ax
sal   dx, 1
add   dx, cx
and   dh, (FINEMASK SHR 8)

call  P_Random_
xor   ah, ah
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
;call  dword ptr ds:[_P_LineAttack]
db    09Ah
dw    P_LINEATTACKOFFSET, PHYSICS_HIGHCODE_SEGMENT

exit_a_cposattack:
POPA_NO_AX_OR_BP_MACRO

ret   

ENDP


PROC    A_CPosRefire_ NEAR
PUBLIC  A_CPosRefire_

push  dx
push  si
push  di
mov   si, ax
call  A_FaceTarget_
call  P_Random_
cmp   al, 40
jb    exit_a_cposrefire
mov   dx, word ptr ds:[si + MOBJ_T.m_targetRef]
test  dx, dx
je    exit_a_cposrefire


IF COMPISA GE COMPILE_186
    imul  di, dx, SIZEOF_THINKER_T
ELSE
    mov  ax, SIZEOF_THINKER_T
    mul  dx
    xchg ax, di
ENDIF

add   di, (OFFSET _thinkerlist + THINKER_T.t_data)
cmp   word ptr ds:[di + MOBJ_T.m_health], 0
jle   set_cgunner_seestate
mov   cx, SIZEOF_THINKER_T
lea   ax, ds:[di - (OFFSET _thinkerlist + THINKER_T.t_data)]
xor   dx, dx
div   cx

IF COMPISA GE COMPILE_186
    imul  cx, ax, SIZEOF_MOBJ_POS_T
ELSE
    mov  dx, SIZEOF_MOBJ_POS_T
    mul  dx
    xchg ax, cx
ENDIF

mov   dx, di
mov   ax, si
;call  dword ptr ds:[_P_CheckSightTemp]
db    09Ah
dw    P_CHECKSIGHTOFFSET, PHYSICS_HIGHCODE_SEGMENT

test  al, al
je    set_cgunner_seestate
exit_a_cposrefire:
pop   di
pop   si
pop   dx
ret   
set_cgunner_seestate:
; dumb thought. this is a hardcoded value as per engine right. Why call a function?
mov   al, byte ptr ds:[si + MOBJ_T.m_mobjtype]
xor   ah, ah
db    09Ah
dw    GETSEESTATEADDR, INFOFUNCLOADSEGMENT


mov   dx, ax
mov   ax, si
;call  P_SetMobjState_
db 0FFh  ; lcall[addr]
db 01Eh  ;
dw _P_SetMobjState_addr
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
mov   si, ax
call  A_FaceTarget_

call  P_Random_
cmp   al, 10
jb    exit_a_spidrefire
mov   dx, word ptr ds:[si + MOBJ_T.m_targetRef]
test  dx, dx
je    exit_a_spidrefire

IF COMPISA GE COMPILE_186
    imul  di, dx, SIZEOF_THINKER_T
ELSE
    mov  ax, SIZEOF_THINKER_T
    mul  dx
    xchg ax, di
ENDIF

add   di, (OFFSET _thinkerlist + THINKER_T.t_data)

cmp   word ptr ds:[di + MOBJ_T.m_health], 0
jle   set_spid_seestate
mov   cx, SIZEOF_THINKER_T
lea   ax, ds:[di - (OFFSET _thinkerlist + THINKER_T.t_data)]
xor   dx, dx
div   cx

IF COMPISA GE COMPILE_186
    imul  cx, ax, SIZEOF_MOBJ_POS_T
ELSE
    mov  dx, SIZEOF_MOBJ_POS_T
    mul  dx
    xchg ax, cx
ENDIF

mov   dx, di
mov   ax, si
;call  dword ptr ds:[_P_CheckSightTemp]
db    09Ah
dw    P_CHECKSIGHTOFFSET, PHYSICS_HIGHCODE_SEGMENT

test  al, al
je    set_spid_seestate
exit_a_spidrefire:
pop   di
pop   si
pop   dx
ret   

set_spid_seestate:
mov   al, byte ptr ds:[si + MOBJ_T.m_mobjtype]
xor   ah, ah

db    09Ah
dw    GETSEESTATEADDR, INFOFUNCLOADSEGMENT

mov   dx, ax
mov   ax, si
;call  P_SetMobjState_
db 0FFh  ; lcall[addr]
db 01Eh  ;
dw _P_SetMobjState_addr
pop   di
pop   si
pop   dx
ret   

ENDP


PROC    A_BspiAttack_ NEAR
PUBLIC  A_BspiAttack_

push  si
mov   si, ax
cmp   word ptr ds:[si + MOBJ_T.m_targetRef], 0
je    a_bspiexit
push  dx
do_a_bspiattack:
call  A_FaceTarget_


IF COMPISA GE COMPILE_186
    imul  dx, word ptr ds:[si + MOBJ_T.m_targetRef], SIZEOF_THINKER_T
    push  MT_ARACHPLAZ  
ELSE
    mov   ax, SIZEOF_THINKER_T
    mul   word ptr ds:[si + MOBJ_T.m_targetRef]
    xchg  ax, dx
    mov   ax, MT_ARACHPLAZ
    push  ax
ENDIF

mov   ax, si
add   dx, (OFFSET _thinkerlist + THINKER_T.t_data)
;call  dword ptr ds:[_P_SpawnMissile]
db    09Ah
dw    P_SPAWNMISSILEOFFSET, PHYSICS_HIGHCODE_SEGMENT
pop   dx
a_bspiexit:
pop   si
ret   

ENDP


PROC    A_TroopAttack_ NEAR
PUBLIC  A_TroopAttack_

push  si
mov   si, ax
cmp   word ptr ds:[si + MOBJ_T.m_targetRef], 0
je    a_troopattack_exit
push  dx

do_a_troopattack:
mov   dx, bx
call  A_FaceTarget_
mov   ax, si
mov   bx, dx
call  P_CheckMeleeRange_
test  al, al
je    do_troop_missile
mov   dx, SFX_CLAW
mov   ax, si
;call  S_StartSound_
db 0FFh  ; lcall[addr]
db 01Eh  ;
dw _S_StartSound_addr

call  P_Random_

;		damage = (P_Random()%8+1)*3;


and   ax, 7
inc   ax

mov   cx, ax
sal   ax, 1
add   cx, ax  ; cx is damage.

IF COMPISA GE COMPILE_186
    imul  ax, word ptr ds:[si + MOBJ_T.m_targetRef], SIZEOF_THINKER_T
ELSE
    mov   ax, SIZEOF_THINKER_T
    mul   word ptr ds:[si + MOBJ_T.m_targetRef]
ENDIF

mov   bx, si
mov   dx, si
add   ax, (OFFSET _thinkerlist + THINKER_T.t_data)
;call  P_DamageMobj_
db 0FFh  ; lcall[addr]
db 01Eh  ;
dw _P_DamageMobj_addr
pop   dx
pop   si
ret   

do_troop_missile:

IF COMPISA GE COMPILE_186
    imul  dx, word ptr ds:[si + MOBJ_T.m_targetRef], SIZEOF_THINKER_T
    push  MT_TROOPSHOT 
ELSE
    mov   ax, SIZEOF_THINKER_T
    mul   word ptr ds:[si + MOBJ_T.m_targetRef]
    xchg  ax, dx
    mov   ax, MT_TROOPSHOT
    push  ax
ENDIF

mov   ax, si
add   dx, (OFFSET _thinkerlist + THINKER_T.t_data)
;call  dword ptr ds:[_P_SpawnMissile]
db    09Ah
dw    P_SPAWNMISSILEOFFSET, PHYSICS_HIGHCODE_SEGMENT

pop   dx
a_troopattack_exit:
pop   si
ret   

ENDP


PROC    A_SargAttack_ NEAR
PUBLIC  A_SargAttack_

push  si
mov   si, ax
cmp   word ptr ds:[si + MOBJ_T.m_targetRef], 0
je    exit_a_sargattack
push  dx

do_a_sargattack:
mov   dx, bx
call  A_FaceTarget_
mov   ax, si
mov   bx, dx
call  P_CheckMeleeRange_
test  al, al
je    exit_a_sargattack_full

;		damage = ((P_Random()%10)+1)*4;

call  P_Random_
xor   ah, ah
mov   cl, 10
div   cl
mov   al, ah
cbw
inc   ax
SHIFT_MACRO sal  ax 2
xchg  ax, cx


IF COMPISA GE COMPILE_186
    imul  ax, word ptr ds:[si + MOBJ_T.m_targetRef], SIZEOF_THINKER_T
ELSE
    mov   ax, SIZEOF_THINKER_T
    mul   word ptr ds:[si + MOBJ_T.m_targetRef]
ENDIF

mov   bx, si
mov   dx, si

add   ax, (OFFSET _thinkerlist + THINKER_T.t_data)
;call  P_DamageMobj_
db 0FFh  ; lcall[addr]
db 01Eh  ;
dw _P_DamageMobj_addr
exit_a_sargattack_full:
pop   dx
exit_a_sargattack:
pop   si
ret   

ENDP


PROC    A_HeadAttack_ NEAR
PUBLIC  A_HeadAttack_

push  si
mov   si, ax
cmp   word ptr ds:[si + MOBJ_T.m_targetRef], 0
je    exit_head_attack
push  dx
do_head_attack:
mov   dx, bx
call  A_FaceTarget_
mov   ax, si
mov   bx, dx
call  P_CheckMeleeRange_
test  al, al
je    do_head_missile
call  P_Random_

;		damage = (P_Random()%6+1)*10;

xor   ah, ah
mov   bx, 00A06h  ; 10 hi 6 lo
div   bl

mov   al, ah
cbw
inc   ax
mul   bh
xchg  ax, cx


IF COMPISA GE COMPILE_186
    imul  ax, word ptr ds:[si + MOBJ_T.m_targetRef], SIZEOF_THINKER_T
ELSE
    mov   ax, SIZEOF_THINKER_T
    mul   word ptr ds:[si + MOBJ_T.m_targetRef]
ENDIF


mov   bx, si
mov   dx, si
add   ax, (OFFSET _thinkerlist + THINKER_T.t_data)
;call  P_DamageMobj_
db 0FFh  ; lcall[addr]
db 01Eh  ;
dw _P_DamageMobj_addr
pop   dx
pop   si
ret   

do_head_missile:

IF COMPISA GE COMPILE_186
    imul  dx, word ptr ds:[si + MOBJ_T.m_targetRef], SIZEOF_THINKER_T
    push  MT_HEADSHOT
ELSE
    mov   ax, SIZEOF_THINKER_T
    mul   word ptr ds:[si + MOBJ_T.m_targetRef]
    xchg  ax, dx
    mov   ax, MT_HEADSHOT
    push  ax
ENDIF

mov   ax, si
add   dx, (OFFSET _thinkerlist + THINKER_T.t_data)
;call  dword ptr ds:[_P_SpawnMissile]
db    09Ah
dw    P_SPAWNMISSILEOFFSET, PHYSICS_HIGHCODE_SEGMENT

pop   dx
exit_head_attack:
pop   si
ret   

ENDP


PROC    A_CyberAttack_ NEAR
PUBLIC  A_CyberAttack_


push  si
mov   si, ax
cmp   word ptr ds:[si + MOBJ_T.m_targetRef], 0
je    exit_cyber_attack
push  dx
call  A_FaceTarget_

IF COMPISA GE COMPILE_186
    imul  dx, word ptr ds:[si + MOBJ_T.m_targetRef], SIZEOF_THINKER_T
    push  MT_ROCKET
ELSE
    mov   ax, SIZEOF_THINKER_T
    mul   word ptr ds:[si + MOBJ_T.m_targetRef]
    xchg  ax, dx
    mov   ax, MT_ROCKET
    push  ax
ENDIF

mov   ax, si
add   dx, (OFFSET _thinkerlist + THINKER_T.t_data)
;call  dword ptr ds:[_P_SpawnMissile]
db    09Ah
dw    P_SPAWNMISSILEOFFSET, PHYSICS_HIGHCODE_SEGMENT

pop   dx
exit_cyber_attack:
pop   si
ret   

ENDP


PROC    A_BruisAttack_ NEAR
PUBLIC  A_BruisAttack_

push  si
mov   si, ax
cmp   word ptr ds:[si + MOBJ_T.m_targetRef], 0
je    exit_a_bruisattack
push  dx

do_a_bruisattack:
; cx:bx here
call  P_CheckMeleeRange_
test  al, al
je    do_bruis_missile
mov   dx, SFX_CLAW
mov   ax, si
;call  S_StartSound_
db 0FFh  ; lcall[addr]
db 01Eh  ;
dw _S_StartSound_addr

;		damage = (P_Random()%8+1)*10;


call  P_Random_
and   ax, 7
inc   ax
mov   ah, 10
mul   ah
mov   cx, ax
IF COMPISA GE COMPILE_186
    imul  ax, word ptr ds:[si + MOBJ_T.m_targetRef], SIZEOF_THINKER_T
ELSE
    mov   ax, SIZEOF_THINKER_T
    mul   word ptr ds:[si + MOBJ_T.m_targetRef]
ENDIF

mov   bx, si
mov   dx, si
add   ax, (OFFSET _thinkerlist + THINKER_T.t_data)
;call  P_DamageMobj_
db 0FFh  ; lcall[addr]
db 01Eh  ;
dw _P_DamageMobj_addr
pop   dx
pop   si
ret   

do_bruis_missile:

IF COMPISA GE COMPILE_186
    imul  dx, word ptr ds:[si + MOBJ_T.m_targetRef], SIZEOF_THINKER_T
    push  MT_BRUISERSHOT
ELSE
    mov   ax, SIZEOF_THINKER_T
    mul   word ptr ds:[si + MOBJ_T.m_targetRef]
    xchg  ax, dx
    mov   ax, MT_BRUISERSHOT
    push  ax
ENDIF

mov   ax, si
add   dx, (OFFSET _thinkerlist + THINKER_T.t_data)
;call  dword ptr ds:[_P_SpawnMissile]
db    09Ah
dw    P_SPAWNMISSILEOFFSET, PHYSICS_HIGHCODE_SEGMENT

pop   dx
exit_a_bruisattack:
pop   si
ret   

ENDP


PROC    A_SkelMissile_ NEAR
PUBLIC  A_SkelMissile_

push  si
mov   si, ax
cmp   word ptr ds:[si + MOBJ_T.m_targetRef], 0
je    exit_a_skelmissile

do_a_skelmissile:
push  dx
push  di
mov   di, bx

call  A_FaceTarget_

mov   es, cx
add   word ptr es:[di + MOBJ_POS_T.mp_z + 2], 16

IF COMPISA GE COMPILE_186
    imul  dx, word ptr ds:[si + MOBJ_T.m_targetRef], SIZEOF_THINKER_T
    push  MT_TRACER
ELSE
    mov   ax, SIZEOF_THINKER_T
    mul   word ptr ds:[si + MOBJ_T.m_targetRef], 
    xchg  ax, dx
    mov   ax, MT_TRACER
    push  ax
ENDIF

mov   ax, si
add   dx, (OFFSET _thinkerlist + THINKER_T.t_data)
;call  dword ptr ds:[_P_SpawnMissile]
db    09Ah
dw    P_SPAWNMISSILEOFFSET, PHYSICS_HIGHCODE_SEGMENT

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


pop   di
pop   dx
exit_a_skelmissile:
pop   si
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

;call  P_SpawnPuff_
db 0FFh  ; lcall[addr]
db 01Eh  ;
dw _P_SpawnPuff_addr


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

;call  P_SpawnMobj_
db 0FFh  ; lcall[addr]
db 01Eh  ;
dw _P_SpawnMobj_addr

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
    imul  bx, ax, SIZEOF_THINKER_T
ELSE
    xchg ax, bx
    mov  ax, SIZEOF_THINKER_T
    mul  bx
    xchg ax, bx
ENDIF


cmp   word ptr ds:[bx + _thinkerlist + THINKER_T.t_data + MOBJ_T.m_health], 0
jle   jump_to_exit_a_tracer

IF COMPISA GE COMPILE_186
    imul  bx, ax, SIZEOF_MOBJ_POS_T
ELSE
    mov  dx, SIZEOF_MOBJ_POS_T
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
mov   si, word ptr ds:[si + MOBJ_POS_T.mp_angle + 2]

push  ss
pop   ds

mov   al, SIZEOF_MOBJINFO_T
mul   byte ptr ds:[di + MOBJ_T.m_mobjtype]
shr   si, 1
and   si, 0FFFCh
mov   bx, ax
mov   bl, byte ptr ds:[bx +  _mobjinfo + MOBJINFO_T.mobjinfo_speed]
push  bx  ; store for next time
mov   dx, si
mov   ax, FINECOSINE_SEGMENT
;call   FixedMulTrigSpeedNoShift_
db 0FFh  ; lcall[addr]
db 01Eh  ;
dw _FixedMulTrigSpeedNoShift_addr
mov   word ptr ds:[di + MOBJ_T.m_momx + 0], ax
mov   word ptr ds:[di + MOBJ_T.m_momx + 2], dx

mov   dx, si    ; restore fineexact
pop   bx        ; restore speed
mov   ax, FINESINE_SEGMENT
;call   FixedMulTrigSpeedNoShift_
db 0FFh  ; lcall[addr]
db 01Eh  ;
dw _FixedMulTrigSpeedNoShift_addr

mov   word ptr ds:[di + MOBJ_T.m_momy + 0], ax
mov   word ptr ds:[di + MOBJ_T.m_momy + 2], dx


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

db    09Ah
dw    P_APROXDISTANCEOFFSET, PHYSICS_HIGHCODE_SEGMENT

;	dist16 =  dist.h.intbits / (mobjinfo[actor->type].speed - 0x80);


mov   bx, word ptr [bp - 2]

mov   al, SIZEOF_MOBJINFO_T
mul   byte ptr ds:[bx + MOBJ_T.m_mobjtype]
xchg  ax, bx

mov   bl, byte ptr ds:[bx + (OFFSET _mobjinfo + MOBJINFO_T.mobjinfo_speed)]
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

push  si
mov   si, ax
cmp   word ptr ds:[si + MOBJ_T.m_targetRef], 0
je    exit_skelwhoosh
push  dx

do_a_skelwhoosh:
call  A_FaceTarget_
mov   dx, SFX_SKESWG
mov   ax, si
;call  S_StartSound_
db 0FFh  ; lcall[addr]
db 01Eh  ;
dw _S_StartSound_addr

pop   dx
exit_skelwhoosh:
pop   si
ret   

ENDP


PROC    A_SkelFist_ NEAR
PUBLIC  A_SkelFist_


push  si
mov   si, ax
cmp   word ptr ds:[si + MOBJ_T.m_targetRef], 0
je    exit_a_skelfist
push  dx

do_a_skelfist:
mov   dx, bx
call  A_FaceTarget_
mov   ax, si
mov   bx, dx
call  P_CheckMeleeRange_
test  al, al
je    exit_a_skelfist_full

;		damage = ((P_Random()%10)+1)*6;

call  P_Random_
xor   ah, ah
mov   cl, 10
div   cl
mov   al, ah
cbw
inc   ax
mov   cl, 6
mul   cl
xchg  ax, cx

mov   ax, si
mov   dx, SFX_SKEPCH
;call  S_StartSound_
db 0FFh  ; lcall[addr]
db 01Eh  ;
dw _S_StartSound_addr

IF COMPISA GE COMPILE_186
    imul  ax, word ptr ds:[si + MOBJ_T.m_targetRef], SIZEOF_THINKER_T
ELSE
    mov   ax, SIZEOF_THINKER_T
    mul   word ptr ds:[si + MOBJ_T.m_targetRef]
ENDIF

mov   bx, si
mov   dx, si
add   ax, (OFFSET _thinkerlist + THINKER_T.t_data)
;call  P_DamageMobj_
db 0FFh  ; lcall[addr]
db 01Eh  ;
dw _P_DamageMobj_addr
exit_a_skelfist_full:
pop   dx
exit_a_skelfist:
pop   si
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
mov   al, 1
ret   

exit_pit_vilecheck_return_1_pop3:
pop   ax ; garbage
pop   di 
pop   si 
mov   al, 1
ret   

do_vilecheck:

push  di

push  ax    ; pop later... 3 pops


mov   al, byte ptr ds:[si + MOBJ_T.m_mobjtype]
xor   ah, ah

;call  dword ptr [bp - 6]
db    09Ah
dw    GETRAISESTATEADDR, INFOFUNCLOADSEGMENT


test  ax, ax
je    exit_pit_vilecheck_return_1_pop3
mov   al, SIZEOF_MOBJINFO_T
mul   byte ptr ds:[si + MOBJ_T.m_mobjtype]
xchg  ax, di

mov   ax, MOBJPOSLIST_6800_SEGMENT
mov   es, ax

mov   al, byte ptr ds:[di + _mobjinfo + MOBJINFO_T.mobjinfo_radius]
xor   ah, ah

mov   cl, byte ptr ds:[_mobjinfo + (MT_VILE * SIZEOF_MOBJINFO_T) + MOBJINFO_T.mobjinfo_radius]

xor   ch, ch
add   cx, ax

;	if (labs(thing_pos->x.w - viletryx.w) > maxdist.w || labs(thing_pos->y.w - viletryy.w) > maxdist.w) {

mov   ax, word ptr es:[bx + MOBJ_POS_T.mp_x + 0]
mov   dx, word ptr es:[bx + MOBJ_POS_T.mp_y + 2]
sub   ax, word ptr ds:[_viletryx + 0]
sbb   dx, word ptr ds:[_viletryx + 2]
or    dx, dx
jge   skip_x_Labs
neg   ax
adc   dx, 0
neg   dx
skip_x_Labs:
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
;call  dword ptr ds:[_P_CheckPosition]
db    09Ah
dw    P_CHECKPOSITIONOFFSET, PHYSICS_HIGHCODE_SEGMENT

;	thing->height.w >>= 2;

sar   word ptr ds:[si + MOBJ_T.m_height + 2], 1
rcr   word ptr ds:[si + MOBJ_T.m_height + 0], 1
sar   word ptr ds:[si + MOBJ_T.m_height + 2], 1
rcr   word ptr ds:[si + MOBJ_T.m_height + 0], 1
test  al, al
mov   al, 0
jne   exit_pit_vilecheck_return_0
mov   al, 1
exit_pit_vilecheck_return_0:
pop   di
pop   si
ret   


_vilechase_lookup_table:

dw OFFSET vile_switch_movedir_0
dw OFFSET vile_switch_movedir_1
dw OFFSET vile_switch_movedir_2
dw OFFSET vile_switch_movedir_3
dw OFFSET vile_switch_movedir_4
dw OFFSET vile_switch_movedir_5
dw OFFSET vile_switch_movedir_6
dw OFFSET vile_switch_movedir_7

ENDP


PROC    A_VileChase_ NEAR
PUBLIC  A_VileChase_


; bp - 2   ax arg
; bp - 4   bx arg
; bp - 6   mobjinfo pointer
; bp - 0Ah   yl
; bp - 8 xh
; bp - 0Ch 
; bp - 0Eh 

push  dx
push  si
push  di
push  bp
mov   bp, sp
push  ax ; bp - 2
push  bx ; bp - 4


xchg  ax, si
cmp   byte ptr ds:[si + MOBJ_T.m_movedir], DI_NODIR
je    jump_to_do_chase_and_exit
mov   al, SIZEOF_MOBJINFO_T
mul   byte ptr ds:[si + MOBJ_T.m_mobjtype]
push  ax   ; bp - 6
mov   di, ax
xor   ax, ax


mov   al, byte ptr ds:[di + (OFFSET _mobjinfo + MOBJINFO_T.mobjinfo_speed)]

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

; would movsw save...?


mov   bl, byte ptr ds:[si + MOBJ_T.m_movedir]

cmp   bl, 7
ja    done_with_vile_switch_block



test  bl, 1             ; diagonals are odd and use the 47000 mult in ax/dx
je    skip_diag_mult2
mov   dx, 47000
mul   dx
skip_diag_mult2:

xor   bh, bh
sal   bx, 1 ; jump word index...
mov   si, OFFSET _viletryx

jmp   word ptr cs:[bx + OFFSET _vilechase_lookup_table]
jump_to_do_chase_and_exit:
jmp   do_chase_and_exit
vile_switch_movedir_0:
add   word ptr ds:[si + 2], ax

done_with_vile_switch_block:

; si is _viletryx

lodsw
xchg  ax, dx
lodsw

; si is now _viletryy.
; ax:dx viletryx

;		xl = (viletryx.w - coord.w - MAXRADIUS*2)>>MAPBLOCKSHIFT;
;		xh = (viletryx.w - coord.w + MAXRADIUS*2)>>MAPBLOCKSHIFT;

mov   di, (MAXRADIUSNONFRAC * 2)

sub   ax, word ptr ds:[_bmaporgx]

mov   cx, ax
mov   bx, dx

sub   ax, di
add   cx, di

; shift right 7
sal   dx, 1
rcl   ax, 1
mov   dl, dh
mov   dh, al  ; only needs 16 bits.

sal   bx, 1
rcl   cx, 1
mov   bl, bh
mov   bh, cl  ; only needs 16 bits.

mov   si, dx  ; si gets xl.
push  bx  ; bp - 8




lodsw           ; viletryy
xchg  ax, cx
lodsw


sub   cx, word ptr ds:[_bmaporgy]


mov   dx, ax
mov   bx, cx

sub   ax, di
add   dx, di

; shift right 7
sal   cx, 1
rcl   ax, 1
mov   cl, ch
mov   ch, al  ; only needs 16 bits.

sal   bx, 1
rcl   dx, 1
mov   bl, bh
mov   bh, dl  ; only needs 16 bits.

; si has xl
; cx has yl

mov   di, bx

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
cmp   di, cx
jl    done_with_vile_y_loop
loop_next_y_vile:
mov   bx, OFFSET PIT_VileCheck_
mov   dx, cx   ; by
mov   ax, si   ; bx
;call  dword ptr [bp - 012h]

db    09Ah
dw    P_BLOCKTHINGSITERATOROFFSET, PHYSICS_HIGHCODE_SEGMENT


test  al, al
je    got_vile_target
inc   cx
cmp   cx, di
jle   loop_next_y_vile

done_with_vile_y_loop:
inc   si
cmp   si, word ptr [bp - 8]
jle   loop_next_x_vile
do_chase_and_exit:
mov   bx, word ptr [bp - 4]
mov   cx, MOBJPOSLIST_6800_SEGMENT
mov   ax, word ptr [bp - 2]
call  A_Chase_

LEAVE_MACRO 
pop   di
pop   si
pop   dx
ret   


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

;call  P_SetMobjState_
db 0FFh  ; lcall[addr]
db 01Eh  ;
dw _P_SetMobjState_addr


IF COMPISA GE COMPILE_186
    imul  si, word ptr ds:[_corpsehitRef], SIZEOF_THINKER_T
    imul  bx, word ptr ds:[_corpsehitRef], SIZEOF_MOBJ_POS_T
ELSE
    mov   ax, SIZEOF_THINKER_T
    mov   cx, word ptr ds:[_corpsehitRef]
    mul   cx
    xchg  ax, si
    mov   ax, SIZEOF_MOBJ_POS_T
    mul   cx
    xchg  ax, bx

ENDIF

add   si, (OFFSET _thinkerlist + THINKER_T.t_data)
mov   dx, SFX_SLOP
mov   ax, si
;call  S_StartSound_
db 0FFh  ; lcall[addr]
db 01Eh  ;
dw _S_StartSound_addr

xor   ax, ax
mov   al, byte ptr ds:[si + MOBJ_T.m_mobjtype]

db    09Ah
dw    GETRAISESTATEADDR, INFOFUNCLOADSEGMENT

xchg  ax, dx
mov   ax, si
;call  P_SetMobjState_
db 0FFh  ; lcall[addr]
db 01Eh  ;
dw _P_SetMobjState_addr
; todo dont know if shift_macro works on this.
shl   word ptr ds:[si + MOBJ_T.m_height+2], 1
shl   word ptr ds:[si + MOBJ_T.m_height+2], 1

mov   cx, MOBJPOSLIST_6800_SEGMENT
mov   es, cx

mov   di, word ptr [bp - 6]

lea   ax, [di + OFFSET _mobjinfo + MOBJINFO_T.mobjinfo_flags1]
lea   di, [bx + MOBJ_POS_T.mp_flags1]

xchg  ax, si   ; si gets mobjtpos dest
movsw ; copy flags1
movsw ; copy flags2

xchg  ax, si   ; si gets mobj ptr again

xor   ax, ax
mov   word ptr ds:[si + MOBJ_T.m_targetRef], ax

mov   al, byte ptr ds:[si + MOBJ_T.m_mobjtype]


db    09Ah
dw    GETSPAWNHEALTHADDR, INFOFUNCLOADSEGMENT

mov   word ptr ds:[si + MOBJ_T.m_health], ax

LEAVE_MACRO 
pop   di
pop   si
pop   dx
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

push  dx
mov   dx, SFX_VILATK
;call  S_StartSound_
db 0FFh  ; lcall[addr]
db 01Eh  ;
dw _S_StartSound_addr

pop   dx
ret   

ENDP


PROC    A_StartFire_ NEAR
PUBLIC  A_StartFire_

push  dx
push  ax
mov   dx, SFX_FLAMST
;call  S_StartSound_
db 0FFh  ; lcall[addr]
db 01Eh  ;
dw _S_StartSound_addr

pop   ax
call  A_Fire_
pop   dx
ret   

ENDP


PROC    A_FireCrackle_ NEAR
PUBLIC  A_FireCrackle_

push  dx
push  ax
mov   dx, SFX_FLAME
;call  S_StartSound_
db 0FFh  ; lcall[addr]
db 01Eh  ;
dw _S_StartSound_addr

pop   ax
call  A_Fire_
pop   dx
ret   

ENDP


PROC    A_Fire_ NEAR
PUBLIC  A_Fire_

push  di
mov   di, ax
mov   di, word ptr ds:[di + MOBJ_T.m_tracerRef]
test  di, di
jne   do_a_fire
pop   di
ret   
do_a_fire:
push  dx
push  si
push  bp
mov   bp, sp
push  cx ; bp - 2
push  ax ; bp - 4
mov   si, bx
xchg  ax, bx


IF COMPISA GE COMPILE_186
    
    imul  dx, di, SIZEOF_THINKER_T
    imul  bx, word ptr ds:[bx + MOBJ_T.m_targetRef], SIZEOF_MOBJ_POS_T
    mov   ax, bx
    imul  di, di, SIZEOF_MOBJ_POS_T
ELSE
    mov   ax, SIZEOF_THINKER_T
    mul   di
    xchg  ax, cx
    mov   ax, SIZEOF_MOBJ_POS_T
    mul   di
    xchg  ax, di
    mov   ax, SIZEOF_MOBJ_POS_T
    mul   word ptr ds:[bx + MOBJ_T.m_targetRef]
    mov   bx, ax
    mov   dx, cx

ENDIF



mov   cx, di
add   dx, (OFFSET _thinkerlist + THINKER_T.t_data)
add   ax, (OFFSET _thinkerlist + THINKER_T.t_data)

;call  dword ptr ds:[_P_CheckSightTemp]
db    09Ah
dw    P_CHECKSIGHTOFFSET, PHYSICS_HIGHCODE_SEGMENT

test  al, al
je    exit_a_fire
mov   es, word ptr [bp - 2]
mov   ax, word ptr es:[di + MOBJ_POS_T.mp_angle + 2]
shr   ax, 1
and   al, 0FCh
mov   dx, si
push  ax  ; bp - 6
mov   ax, word ptr [bp - 4]
;call  dword ptr ds:[_P_UnsetThingPosition]
db    09Ah
dw    P_UNSETTHINGPOSITIONOFFSET, PHYSICS_HIGHCODE_SEGMENT

mov   cx, 24
xor   bx, bx
mov   dx, word ptr [bp - 6]
mov   ax, FINECOSINE_SEGMENT
;call  FixedMulTrigNoShift_
db 0FFh  ; lcall[addr]
db 01Eh  ;
dw _FixedMulTrigNoShift_addr
mov   ds, word ptr [bp - 2]

add   ax, word ptr ds:[di + MOBJ_POS_T.mp_x + 0]
adc   dx, word ptr ds:[di + MOBJ_POS_T.mp_x + 2]
mov   word ptr ds:[si + MOBJ_POS_T.mp_x + 0], ax
mov   word ptr ds:[si + MOBJ_POS_T.mp_x + 2], dx

push  ss
pop   ds

mov   cx, 24
xor   bx, bx
mov   ax, FINESINE_SEGMENT
pop   dx  ; bp - 6

;call  FixedMulTrigNoShift_
db 0FFh  ; lcall[addr]
db 01Eh  ;
dw _FixedMulTrigNoShift_addr
mov   ds, word ptr [bp - 2]

add   ax, word ptr ds:[di + MOBJ_POS_T.mp_y + 0]
adc   dx, word ptr ds:[di + MOBJ_POS_T.mp_y + 2]
mov   word ptr ds:[si + MOBJ_POS_T.mp_y + 0], ax
mov   word ptr ds:[si + MOBJ_POS_T.mp_y + 2], dx

push  word ptr ds:[di + MOBJ_POS_T.mp_z + 0]
push  word ptr ds:[di + MOBJ_POS_T.mp_z + 2]
pop   word ptr ds:[si + MOBJ_POS_T.mp_z + 2]
pop   word ptr ds:[si + MOBJ_POS_T.mp_z + 0]

push  ss
pop   ds

mov   bx, -1
pop   ax ; bp - 4
mov   dx, si
;call  dword ptr ds:[_P_SetThingPosition]
db    09Ah
dw    P_SETTHINGPOSITIONOFFSET, PHYSICS_HIGHCODE_SEGMENT

exit_a_fire:
LEAVE_MACRO 
pop   si
pop   dx
pop   di
ret   

ENDP


PROC    A_VileTarget_ NEAR
PUBLIC  A_VileTarget_

PUSHA_NO_AX_OR_BP_MACRO
mov   si, ax
cmp   word ptr ds:[si + MOBJ_T.m_targetRef], 0
je    exit_vile_target

do_vile_target:

call  A_FaceTarget_

IF COMPISA GE COMPILE_186
    mov   ax, word ptr ds:[si + MOBJ_T.m_targetRef]
    imul  di, ax, SIZEOF_THINKER_T
    imul  bx, ax, SIZEOF_MOBJ_POS_T
ELSE
    mov   ax, SIZEOF_THINKER_T
    mul   word ptr ds:[si + MOBJ_T.m_targetRef]
    xchg  ax, di
    mov   ax, SIZEOF_MOBJ_POS_T
    mul   word ptr ds:[si + MOBJ_T.m_targetRef]
    xchg  ax, bx

ENDIF

add   di, (OFFSET _thinkerlist + THINKER_T.t_data)
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

;call  P_SpawnMobj_
db 0FFh  ; lcall[addr]
db 01Eh  ;
dw _P_SpawnMobj_addr


mov   word ptr ds:[si + MOBJ_T.m_tracerRef], ax

mov   cx, SIZEOF_THINKER_T
xor   dx, dx
lea   ax, ds:[si - (OFFSET _thinkerlist + THINKER_T.t_data)]
div   cx

mov   di, word ptr ds:[_setStateReturn]

mov   word ptr ds:[di + MOBJ_T.m_targetRef], ax
push  word ptr ds:[si + MOBJ_T.m_targetRef]
pop   word ptr ds:[di + MOBJ_T.m_tracerRef]
les   bx, dword ptr ds:[_setStateReturn_pos]
mov   cx, es
mov   ax, di
call  A_Fire_
exit_vile_target:
POPA_NO_AX_OR_BP_MACRO
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
cmp   al, (MT_BOSSBRAIN - 3) 
ja    vilemomz_ret_10  ; default
xor   ah, ah
xchg  ax, bx
sal   bx, 1
xor   ax, ax
cwd
jmp   word ptr cs:[bx + OFFSET _vile_momz_lookuptable]
vilemomz_ret_2:
inc   dx
inc   dx
pop   bx
ret   
vilemomz_ret_20:
mov   dx, 20
pop   bx
ret   
vilemomz_ret_163840:
mov   ax, 08000h
jmp   vilemomz_ret_2  ; dx 2 and pop bx and ret.
vilemomz_ret_109226:
mov   ax, 0AAAAh
inc   dx
pop   bx
ret   
vilemomz_ret_1_high:
inc   dx
pop   bx
ret   
vilemomz_ret_1_low:
inc   ax
pop   bx
ret   
vilemomz_ret_10:
mov   dx, 10
pop   bx
ret   

ENDP


PROC    A_VileAttack_ NEAR
PUBLIC  A_VileAttack_

; bp - 2   actorTarget_pos
; bp - 4   MOBJPOSLIST_6800_SEGMENT
; bp - 6   mobjpos offset
; bp - 8   angle
; bp - 0Ah fire (mobj)
; bp - 0Ch temp?

push  dx
push  si
push  di
push  bp
mov   bp, sp
sub   sp, 6
mov   si, ax
mov   word ptr [bp - 6], bx
mov   word ptr [bp - 4], cx
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

IF COMPISA GE COMPILE_186
    imul  cx, ax, SIZEOF_MOBJ_POS_T
ELSE
    mov   cx, SIZEOF_MOBJ_POS_T
    mul   cx
    xchg  ax, cx
ENDIF
mov   ax, si
call  A_FaceTarget_
IF COMPISA GE COMPILE_186
    imul  di, word ptr ds:[si + MOBJ_T.m_targetRef], SIZEOF_THINKER_T
ELSE
    mov   ax, SIZEOF_THINKER_T
    mul   word ptr ds:[si + MOBJ_T.m_targetRef]
    xchg  ax, di
ENDIF

mov   word ptr [bp - 2], cx
add   di, (OFFSET _thinkerlist + THINKER_T.t_data)
mov   ax, si
mov   dx, di


;call  dword ptr ds:[_P_CheckSightTemp]
db    09Ah
dw    P_CHECKSIGHTOFFSET, PHYSICS_HIGHCODE_SEGMENT

test  al, al
je    exit_vile_attack
mov   dx, SFX_BAREXP
mov   ax, si
;call  S_StartSound_
db 0FFh  ; lcall[addr]
db 01Eh  ;
dw _S_StartSound_addr

mov   ax, di
mov   cx, 20
mov   bx, si
mov   dx, si

;call  P_DamageMobj_
db 0FFh  ; lcall[addr]
db 01Eh  ;
dw _P_DamageMobj_addr

les   bx, dword ptr [bp - 6]
mov   ax, word ptr es:[bx + MOBJ_POS_T.mp_angle + 2]
shr   ax, 1
and   al, 0FCh
push  ax  ; bp - 8
mov   al, byte ptr ds:[di + MOBJ_T.m_mobjtype]
cbw  
mov   bx, word ptr ds:[si + MOBJ_T.m_tracerRef]
call  GetVileMomz_
mov   word ptr ds:[di + MOBJ_T.m_momz + 0], ax
mov   word ptr ds:[di + MOBJ_T.m_momz + 2], dx
test  bx, bx
je    exit_vile_attack

IF COMPISA GE COMPILE_186
    imul  ax, bx, SIZEOF_THINKER_T
    imul  di, bx, SIZEOF_MOBJ_POS_T
ELSE
    mov   ax, SIZEOF_MOBJ_POS_T
    mul   bx
    xchg  ax, di
    mov   ax, SIZEOF_THINKER_T
    mul   bx
ENDIF

mov   cx, 24
add   ax, (OFFSET _thinkerlist + THINKER_T.t_data)
mov   dx, word ptr [bp - 8]
push  ax  ; bp - 0Ah
mov   ax, FINECOSINE_SEGMENT
xor   bx, bx

;call  FixedMulTrigNoShift_
db 0FFh  ; lcall[addr]
db 01Eh  ;
dw _FixedMulTrigNoShift_addr
mov   es, word ptr [bp - 4]
mov   bx, word ptr [bp - 2]
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
;call  FixedMulTrigNoShift_
db 0FFh  ; lcall[addr]
db 01Eh  ;
dw _FixedMulTrigNoShift_addr
mov   es, word ptr [bp - 4]
mov   bx, word ptr [bp - 2]

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

;call  dword ptr ds:[_P_RadiusAttack]
db    09Ah
dw    P_RADIUSATTACKOFFSET, PHYSICS_HIGHCODE_SEGMENT

LEAVE_MACRO 
pop   di
pop   si
pop   dx
ret   

ENDP


PROC    A_FatRaise_ NEAR
PUBLIC  A_FatRaise_

push  dx
push  ax
call  A_FaceTarget_
mov   dx, SFX_MANATK
pop   ax
;call  S_StartSound_
db 0FFh  ; lcall[addr]
db 01Eh  ;
dw _S_StartSound_addr
pop   dx
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
;call  dword ptr ds:[_P_SpawnMissile]
db    09Ah
dw    P_SPAWNMISSILEOFFSET, PHYSICS_HIGHCODE_SEGMENT

imul  dx, word ptr ds:[di + MOBJ_T.m_targetRef], SIZEOF_THINKER_T
push  9
mov   cx, word ptr [bp - 2]
mov   bx, si
mov   ax, di
add   dx, (OFFSET _thinkerlist + THINKER_T.t_data)
;call  dword ptr ds:[_P_SpawnMissile]
db    09Ah
dw    P_SPAWNMISSILEOFFSET, PHYSICS_HIGHCODE_SEGMENT

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
;call FixedMulTrigSpeedNoShift_
db 0FFh  ; lcall[addr]
db 01Eh  ;
dw _FixedMulTrigSpeedNoShift_addr

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
;call FixedMulTrigSpeedNoShift_
db 0FFh  ; lcall[addr]
db 01Eh  ;
dw _FixedMulTrigSpeedNoShift_addr
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
;call  dword ptr ds:[_P_SpawnMissile]
db    09Ah
dw    P_SPAWNMISSILEOFFSET, PHYSICS_HIGHCODE_SEGMENT

imul  dx, word ptr ds:[di + MOBJ_T.m_targetRef], SIZEOF_THINKER_T
push  MT_FATSHOT  ; todo 186
mov   cx, word ptr [bp - 2]
mov   bx, si
mov   ax, di
add   dx, (OFFSET _thinkerlist + THINKER_T.t_data)
mov   si, OFFSET _setStateReturn
;call  dword ptr ds:[_P_SpawnMissile]
db    09Ah
dw    P_SPAWNMISSILEOFFSET, PHYSICS_HIGHCODE_SEGMENT

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
;call FixedMulTrigSpeedNoShift_
db 0FFh  ; lcall[addr]
db 01Eh  ;
dw _FixedMulTrigSpeedNoShift_addr
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
;call FixedMulTrigSpeedNoShift_
db 0FFh  ; lcall[addr]
db 01Eh  ;
dw _FixedMulTrigSpeedNoShift_addr
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
;call  dword ptr ds:[_P_SpawnMissile]
db    09Ah
dw    P_SPAWNMISSILEOFFSET, PHYSICS_HIGHCODE_SEGMENT

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
;call FixedMulTrigSpeedNoShift_
db 0FFh  ; lcall[addr]
db 01Eh  ;
dw _FixedMulTrigSpeedNoShift_addr
mov   word ptr ds:[si + MOBJ_T.m_momx + 0], ax
mov   bx, word ptr [bp - 6]
mov   word ptr ds:[si + MOBJ_T.m_momx + 2], dx
mov   dx, word ptr [bp - 2]
mov   ax, FINESINE_SEGMENT
;call FixedMulTrigSpeedNoShift_
db 0FFh  ; lcall[addr]
db 01Eh  ;
dw _FixedMulTrigSpeedNoShift_addr
push  9
mov   bx, word ptr [bp - 0Ah]
mov   word ptr ds:[si + MOBJ_T.m_momy + 0], ax
mov   cx, word ptr [bp - 0Ch]
mov   word ptr ds:[si + MOBJ_T.m_momy + 2], dx
mov   dx, word ptr [bp - 4]
mov   ax, word ptr [bp - 8]
mov   si, OFFSET _setStateReturn
;call  dword ptr ds:[_P_SpawnMissile]
db    09Ah
dw    P_SPAWNMISSILEOFFSET, PHYSICS_HIGHCODE_SEGMENT

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
;call FixedMulTrigSpeedNoShift_
db 0FFh  ; lcall[addr]
db 01Eh  ;
dw _FixedMulTrigSpeedNoShift_addr
mov   word ptr ds:[si + MOBJ_T.m_momx + 0], ax
mov   bx, word ptr [bp - 6]
mov   word ptr ds:[si + MOBJ_T.m_momx + 2], dx
mov   dx, word ptr [bp - 2]
mov   ax, FINESINE_SEGMENT
;call FixedMulTrigSpeedNoShift_
db 0FFh  ; lcall[addr]
db 01Eh  ;
dw _FixedMulTrigSpeedNoShift_addr
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
;call  S_StartSound_
db 0FFh  ; lcall[addr]
db 01Eh  ;
dw _S_StartSound_addr

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
;call FixedMulTrigSpeedNoShift_
db 0FFh  ; lcall[addr]
db 01Eh  ;
dw _FixedMulTrigSpeedNoShift_addr
mov   word ptr ds:[si + MOBJ_T.m_momx + 0], ax
mov   bx, SKULLSPEED_SMALL
mov   word ptr ds:[si + MOBJ_T.m_momx + 2], dx
mov   dx, word ptr [bp - 0Ch]
mov   ax, FINESINE_SEGMENT
mov   word ptr [bp - 4], MOBJPOSLIST_6800_SEGMENT
;call FixedMulTrigSpeedNoShift_
db 0FFh  ; lcall[addr]
db 01Eh  ;
dw _FixedMulTrigSpeedNoShift_addr
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
db    09Ah
dw    P_APROXDISTANCEOFFSET, PHYSICS_HIGHCODE_SEGMENT
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
;call   FastDiv3216u_
db 0FFh  ; lcall[addr]
db 01Eh  ;
dw _FastDiv3216u_addr
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
;call  FixedMulTrigNoShift_
db 0FFh  ; lcall[addr]
db 01Eh  ;
dw _FixedMulTrigNoShift_addr
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
;call  FixedMulTrigNoShift_
db 0FFh  ; lcall[addr]
db 01Eh  ;
dw _FixedMulTrigNoShift_addr
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
;call  P_SpawnMobj_
db 0FFh  ; lcall[addr]
db 01Eh  ;
dw _P_SpawnMobj_addr
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
;call  dword ptr ds:[_P_TryMove]
db    09Ah
dw    P_TRYMOVEOFFSET, PHYSICS_HIGHCODE_SEGMENT

test  al, al
jne   label_152
mov   cx, 10000
mov   ax, word ptr [bp - 2]
mov   bx, di
mov   dx, di
;call  P_DamageMobj_
db 0FFh  ; lcall[addr]
db 01Eh  ;
dw _P_DamageMobj_addr
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
;call  S_StartSound_
db 0FFh  ; lcall[addr]
db 01Eh  ;
dw _S_StartSound_addr

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
;call  S_StartSound_
db 0FFh  ; lcall[addr]
db 01Eh  ;
dw _S_StartSound_addr

pop   si
pop   dx
pop   bx
ret   

ENDP


PROC    A_XScream_ NEAR
PUBLIC  A_XScream_

push  dx
mov   dx, SFX_SLOP
;call  S_StartSound_
db 0FFh  ; lcall[addr]
db 01Eh  ;
dw _S_StartSound_addr

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
;call  S_StartSound_
db 0FFh  ; lcall[addr]
db 01Eh  ;
dw _S_StartSound_addr

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
;call  dword ptr ds:[_P_RadiusAttack]
db    09Ah
dw    P_RADIUSATTACKOFFSET, PHYSICS_HIGHCODE_SEGMENT

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
;call  S_StartSound_
db 0FFh  ; lcall[addr]
db 01Eh  ;
dw _S_StartSound_addr

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
;call  S_StartSound_
db 0FFh  ; lcall[addr]
db 01Eh  ;
dw _S_StartSound_addr

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
;call  S_StartSound_
db 0FFh  ; lcall[addr]
db 01Eh  ;
dw _S_StartSound_addr

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
;call  S_StartSound_
db 0FFh  ; lcall[addr]
db 01Eh  ;
dw _S_StartSound_addr

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
;call  S_StartSound_
db 0FFh  ; lcall[addr]
db 01Eh  ;
dw _S_StartSound_addr

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
;call  S_StartSound_
db 0FFh  ; lcall[addr]
db 01Eh  ;
dw _S_StartSound_addr

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
;call  P_SpawnMobj_
db 0FFh  ; lcall[addr]
db 01Eh  ;
dw _P_SpawnMobj_addr
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
;call  P_SetMobjState_
db 0FFh  ; lcall[addr]
db 01Eh  ;
dw _P_SetMobjState_addr
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
;call  P_SpawnMobj_
db 0FFh  ; lcall[addr]
db 01Eh  ;
dw _P_SpawnMobj_addr
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
;call  P_SetMobjState_
db 0FFh  ; lcall[addr]
db 01Eh  ;
dw _P_SetMobjState_addr
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
;call  dword ptr ds:[_P_SpawnMissile]
db    09Ah
dw    P_SPAWNMISSILEOFFSET, PHYSICS_HIGHCODE_SEGMENT

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
;call   FastDiv3216u_
db 0FFh  ; lcall[addr]
db 01Eh  ;
dw _FastDiv3216u_addr
mov   bx, cx
mov   cx, word ptr [bp - 4]
call  __I4D
mov   dx, SFX_BOSPIT
mov   byte ptr ds:[di + MOBJ_T.m_reactiontime], al
xor   ax, ax
;call  S_StartSound_
db 0FFh  ; lcall[addr]
db 01Eh  ;
dw _S_StartSound_addr

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
;call  S_StartSound_
db 0FFh  ; lcall[addr]
db 01Eh  ;
dw _S_StartSound_addr

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
;call  P_SpawnMobj_
db 0FFh  ; lcall[addr]
db 01Eh  ;
dw _P_SpawnMobj_addr
mov   bx, OFFSET _setStateReturn
mov   dx, SFX_TELEPT
mov   ax, word ptr ds:[bx]
mov   word ptr [bp - 4], si
;call  S_StartSound_
db 0FFh  ; lcall[addr]
db 01Eh  ;
dw _S_StartSound_addr

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
;call  P_SpawnMobj_
db 0FFh  ; lcall[addr]
db 01Eh  ;
dw _P_SpawnMobj_addr
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
;call  P_SetMobjState_
db 0FFh  ; lcall[addr]
db 01Eh  ;
dw _P_SetMobjState_addr
label_185:
push  word ptr ds:[si + 4]
mov   es, cx
push  word ptr es:[bx + MOBJ_POS_T.mp_y + 2]
push  word ptr es:[bx + MOBJ_POS_T.mp_y + 0]
push  word ptr es:[bx + 2]
push  word ptr es:[bx]
mov   ax, si
;call  dword ptr ds:[_P_TeleportMove]
db    09Ah
dw    P_TELEPORTMOVEOFFSET, PHYSICS_HIGHCODE_SEGMENT

mov   ax, di
;call  P_RemoveMobj_
db 0FFh  ; lcall[addr]
db 01Eh  ;
dw _P_RemoveMobj_addr


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
mov   dx, SFX_PLDETH 
mov   bx, word ptr ds:[_playerMobj]
cmp   byte ptr ds:[_commercial], 0
je    normal_scream
cmp   word ptr ds:[bx + MOBJ_T.m_health], -50
jge   normal_scream
mov   dl, SFX_PDIEHI
normal_scream:
xchg  ax, bx ; player
;call  S_StartSound_
db 0FFh  ; lcall[addr]
db 01Eh  ;
dw _S_StartSound_addr

pop   dx
pop   bx
ret   

ENDP

PROC    P_ENEMY_ENDMARKER_ 
PUBLIC  P_ENEMY_ENDMARKER_
ENDP



END
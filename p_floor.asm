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


EXTRN S_StartSoundWithParams_:PROC
EXTRN P_RemoveThinker_:PROC
EXTRN _P_ChangeSector:DWORD
EXTRN P_FindHighestOrLowestFloorSurrounding_:NEAR
EXTRN twoSided_:NEAR
EXTRN P_FindLowestOrHighestCeilingSurrounding_:NEAR
EXTRN P_FindSectorsFromLineTag_:NEAR
EXTRN P_FindNextHighestFloor_:NEAR
EXTRN P_CreateThinker_:FAR

SHORTFLOORBITS = 3

.DATA




.CODE



PROC    P_FLOOR_STARTMARKER_ NEAR
PUBLIC  P_FLOOR_STARTMARKER_
ENDP

PROC    T_MovePlaneCeilingDown_ NEAR
PUBLIC  T_MovePlaneCeilingDown_

;result_e __near T_MovePlaneCeilingDown ( uint16_t sector_offset, short_height_t	speed, short_height_t	dest, boolean	crush ) {

push  si
push  di
push  bp
xor   bp, bp
add   al, SECTOR_T.sec_ceilingheight  ; this is safe because they are 16 byte structs that are paragraph aligned. will never overflow.
xchg  ax, si

mov   ax, SECTORS_SEGMENT
mov   es, ax

;	if (sector->ceilingheight - speed < dest) {


mov   di, word ptr es:[si]
mov   ax, di
sub   ax, dx 

cmp   ax, bx
jl    ceiling_down_past_dest
jmp   ceil_down_not_past_dest


ENDP



PROC    T_MovePlaneCeilingUp_ NEAR
PUBLIC  T_MovePlaneCeilingUp_

push  si
push  di
push  bp
mov   bp, 1 ; do check 
add   al, SECTOR_T.sec_ceilingheight  ; this is safe because they are 16 byte structs that are paragraph aligned. will never overflow.
xchg  ax, si

;	if (sector->ceilingheight + speed > dest) {

mov   ax, SECTORS_SEGMENT
mov   es, ax
mov   di, word ptr es:[si]
mov   ax, di
add   ax, dx
cmp   ax, bx
jg    ceiling_up_past_dest


jmp   floor_up_not_past_dest


ENDP



PROC    T_MovePlaneFloorDown_ NEAR
PUBLIC  T_MovePlaneFloorDown_

push  si
push  di
push  bp
mov   bp, 1
add   al, SECTOR_T.sec_floorheight  ; this is safe because they are 16 byte structs that are paragraph aligned. will never overflow.
xchg  ax, si
mov   ax, SECTORS_SEGMENT
mov   es, ax

;	if (sector->floorheight - speed < dest) {


mov   di, word ptr es:[si]
mov   ax, di
sub   ax, dx 

cmp   ax, bx
jge   floor_down_not_past_dest
floor_down_past_dest:
ceiling_down_past_dest:
ceiling_up_past_dest:
floor_up_past_dest:
mov   word ptr es:[si], bx

mov   dx, es
mov   bx, cx
mov   ax, si
and   al, 0F0h ; undo the ptr
call  dword ptr ds:[_P_ChangeSector]
test  al, al
je    exit_moveplanefloordown_return_floorpastdest
; something crushed

mov   dx, SECTORS_SEGMENT
mov   es, dx
mov   word ptr es:[si], di
mov   bx, cx
xchg  ax, si
and   al, 0F0h ; undo the ptr
call  dword ptr ds:[_P_ChangeSector]
exit_moveplanefloordown_return_floorpastdest:
exit_moveplanefloorup_return_floorpastdest:
mov   al, FLOOR_PASTDEST
exit_moveplanefloordown:

pop   bp
pop   di
pop   si
ret   

ceil_down_not_past_dest:
floor_down_not_past_dest:
sub   word ptr es:[si], dx

mov   dx, es
mov   bx, cx ; crush
mov   ax, si
and   al, 0F0h ; undo the ptr
call  dword ptr ds:[_P_ChangeSector]
test  al, al
je    exit_moveplanefloordown_return_floorok

test  bp, bp
jne   do_second_floor_changesector_call   ; skip second check...
test  cl, cl
jne   exit_moveplaneceilingdown_return_floorcrushed


do_second_floor_changesector_call:
mov   dx, SECTORS_SEGMENT
mov   es, dx
mov   word ptr es:[si], di
mov   bx, cx ; crush
xchg  ax, si
and   al, 0F0h ; undo the ptr
call  dword ptr ds:[_P_ChangeSector]
exit_moveplanefloordown_return_floorcrushed:
exit_moveplanefloorup_return_floorcrushed:
exit_moveplaneceilingdown_return_floorcrushed:
mov   al, FLOOR_CRUSHED
exit_moveplanefloordown_return_floorok:
exit_moveplanefloorup_return_floorok:
pop   bp
pop   di
pop   si
ret   


ENDP

PROC    T_MovePlaneFloorUp_ NEAR
PUBLIC  T_MovePlaneFloorUp_

push  si
push  di
push  bp
xor   bp, bp
add   al, SECTOR_T.sec_floorheight  ; this is safe because they are 16 byte structs that are paragraph aligned. will never overflow.
xchg  ax, si

;	if (sector->floorheight + speed > dest) {


mov   ax, SECTORS_SEGMENT
mov   es, ax
mov   di, word ptr es:[si]
mov   ax, di
add   ax, dx
cmp   ax, bx
jg    floor_up_past_dest

floor_up_not_past_dest:


add   word ptr es:[si], dx
mov   dx, es
mov   bx, cx
mov   ax, si
and   al, 0F0h ; undo the ptr
call  dword ptr ds:[_P_ChangeSector]
test  al, al
je    exit_moveplanefloorup_return_floorok
mov   al, 0 ; to force a ret 0 below...
test  bp, bp  ; skip 2nd call if 1
jne   exit_moveplanefloorup_return_floorok
test  cl, cl
jne   exit_moveplanefloorup_return_floorcrushed
jmp   do_second_floor_changesector_call



ENDP



PROC    T_MoveFloor_ NEAR
PUBLIC  T_MoveFloor_

;void __near T_MoveFloor(floormove_t __near* floor, THINKERREF floorRef) {


PUSHA_NO_AX_OR_BP_MACRO
push  bp
mov   bp, sp

xchg  ax, si
push  dx  ; bp - 2
mov   di, word ptr ds:[si + FLOORMOVE_T.floormove_secnum]


test  byte ptr ds:[_leveltime], 7
jne   dont_play_floor_sound
mov   dx, SFX_STNMOV
mov   ax, di
call  S_StartSoundWithParams_   
dont_play_floor_sound:

mov   ax, di
SHIFT_MACRO shl   ax 4
push  ax  ; bp - 4
cmp   byte ptr ds:[si + FLOORMOVE_T.floormove_direction], 0
je    exit_move_floor

mov   bx, word ptr ds:[si + FLOORMOVE_T.floormove_floordestheight]
mov   dx, word ptr ds:[si + FLOORMOVE_T.floormove_speed]
mov   cl, byte ptr ds:[si + FLOORMOVE_T.floormove_crush]
; ax already offset
jl    floor_direction_down

floor_direction_up:
call  T_MovePlaneFloorUp_
jmp   done_with_TMovePlanecall

floor_direction_down:
call  T_MovePlaneFloorDown_
done_with_TMovePlanecall:



cmp   al, FLOOR_PASTDEST
jne   exit_move_floor

xor   ax, ax
pop   bx ; bp - 4
mov   word ptr ds:[bx + _sectors_physics + SECTOR_PHYSICS_T.secp_specialdataRef], ax ; NULL_THINKERREF


cmp  byte ptr ds:[si + FLOORMOVE_T.floormove_direction], al
mov  al, byte ptr ds:[si + FLOORMOVE_T.floormove_type]
je   dont_change_specials
jg   check_for_raising_donut

cmp   al, FLOOR_LOWERANDCHANGE
jmp   do_type_compare


check_for_raising_donut:
cmp   al, FLOOR_DONUTRAISE
do_type_compare:
jne   dont_change_specials

mov   ax, SECTORS_SEGMENT
mov   es, ax


mov   al, byte ptr ds:[si + FLOORMOVE_T.floormove_texture]
mov   byte ptr es:[bx + SECTOR_T.sec_floorpic], al
mov   al, byte ptr ds:[si + FLOORMOVE_T.floormove_newspecial]
mov   byte ptr ds:[bx + _sectors_physics + SECTOR_PHYSICS_T.secp_special], al

dont_change_specials:
pop   ax  ; bp - 2 retrieve floorRef
mov   dx, SFX_PSTOP

call  P_RemoveThinker_
xchg  ax, di

call  S_StartSoundWithParams_
   
exit_move_floor:
LEAVE_MACRO 
POPA_NO_AX_OR_BP_MACRO
ret   

ENDP


_do_floor_jump_table:
dw do_floor_switch_case_type_lowerfloor
dw do_floor_switch_case_type_lowerFloorToLowest
dw do_floor_switch_case_type_turboLower
dw do_floor_switch_case_type_raiseFloor
dw do_floor_switch_case_type_raiseFloorToNearest
dw do_floor_switch_case_type_raiseToTexture
dw do_floor_switch_case_type_lowerAndChange
dw do_floor_switch_case_type_raiseFloor24
dw do_floor_switch_case_type_raiseFloor24AndChange
dw do_floor_switch_case_type_raiseFloorCrush
dw do_floor_switch_case_type_raiseFloorTurbo
dw do_floor_switch_case_type_default
dw do_floor_switch_case_type_raiseFloor512 






PROC    EV_DoFloor_ FAR
PUBLIC  EV_DoFloor_

;int16_t __far EV_DoFloor ( uint8_t linetag,int16_t linefrontsecnum,floor_e	floortype ){

; bp - 2    floortype
; bp - 0202h secnumlist
; bp - 0204h secnumlist iter



push  cx
push  si
push  di
push  bp
mov   bp, sp

mov   word ptr cs:[SELFMODIFY_set_frontsector+1], dx

xor   bh, bh
mov   byte ptr cs:[SELFMODIFY_set_dofloor_return + 1], bh ; zero
mov   word ptr cs:[SELFMODIFY_set_dofloor_type + 1], bx
lea   dx, [bp - 0202h]
sub   sp, 0200h
push  dx

mov   si, dx


;	P_FindSectorsFromLineTag(linetag, secnumlist, false);


xor   bx, bx
call  P_FindSectorsFromLineTag_
cmp   word ptr [si], 0

jl    no_sectors_in_list_exit

loop_next_secnum_dofloor:

mov   cx, word ptr [si]
push  si ; bp - 204h. pop at end of loop...

mov   ax, TF_MOVEFLOOR_HIGHBITS
cwd   ; zero dx
call  P_CreateThinker_

mov   si, ax  ;  si is floor

sub   ax, (_thinkerlist + THINKER_T.t_data)
mov   di, SIZEOF_THINKER_T
div   di

mov   di, SECTORS_SEGMENT
mov   es, di

mov   di, cx
mov   byte ptr cs:[SELFMODIFY_set_dofloor_return+1], 1
; ax is floor ref
mov   word ptr ds:[di + _sectors_physics + SECTOR_PHYSICS_T.secp_specialdataRef], ax ;floor ref
SHIFT_MACRO shl  di 4  

; di is sectors offset
; si is floor
; cx is secnum


mov  ax, cx  ; ax gets secnum too
; set type 
SELFMODIFY_set_dofloor_type:
mov   bx, 01000h

mov   byte ptr ds:[si + FLOORMOVE_T.floormove_type], bl
mov   byte ptr ds:[si + FLOORMOVE_T.floormove_crush], bh ; known 0


; ds:si is floor
; ds:di + _sectors_physics is sector_physics
; es:di  is sector
; ax/cx is secnum
; bx is floor type (soon to be shifted for jmp)
; dl is 1 

cmp   bl, FLOOR_RAISEFLOOR512
ja    done_with_dofloor_switch_block
sal   bx, 1
mov   dl, 1 ; "true" used for many calls.
jmp   word ptr cs:[bx + _do_floor_jump_table]


do_floor_switch_case_type_lowerFloorToLowest:
xor   dx, dx
do_floor_switch_case_type_lowerfloor:
xor   bx, bx
mov   word ptr ds:[si + FLOORMOVE_T.floormove_speed], FLOORSPEED
find_highestlowest_dont_set_bx:
call  P_FindHighestOrLowestFloorSurrounding_
mov   dl, -1 ; dir negative.

test  bh, bh
je    write_floordestheight_secnum_dir
;turbo case
mov   bx, SECTORS_SEGMENT
mov   es, bx
cmp   ax, word ptr es:[di + SECTOR_T.sec_floorheight]
je    write_floordestheight_secnum_dir

add   ax, (8 SHL SHORTFLOORBITS)

write_floordestheight_secnum_dir:
mov   byte ptr ds:[si + FLOORMOVE_T.floormove_direction], dl
mov   word ptr ds:[si + FLOORMOVE_T.floormove_floordestheight], ax
mov   word ptr ds:[si + FLOORMOVE_T.floormove_secnum], cx


done_with_dofloor_switch_block:

do_floor_switch_case_type_default:

pop   si ; pop and inc word ptr
inc   si
inc   si

cmp   word ptr [si], 0
jnl   loop_next_secnum_dofloor
exit_ev_dofloor_and_return_rtn:
no_sectors_in_list_exit:
SELFMODIFY_set_dofloor_return:
mov   al, 010h
LEAVE_MACRO 
pop   di
pop   si
pop   cx
retf  


do_floor_switch_case_type_turboLower:
mov   bh, 1
mov   word ptr ds:[si + FLOORMOVE_T.floormove_speed], FLOORSPEED * 4
jmp   find_highestlowest_dont_set_bx

do_floor_switch_case_type_raiseFloorCrush:
mov   byte ptr ds:[si + FLOORMOVE_T.floormove_crush], dl ; 1

do_floor_switch_case_type_raiseFloor:
mov   word ptr ds:[si + FLOORMOVE_T.floormove_speed], FLOORSPEED

xor   dx, dx
call  P_FindLowestOrHighestCeilingSurrounding_

mov   dx, word ptr es:[di + SECTOR_T.sec_floorheight]
cmp   ax, dx
jge   dont_adjust_to_ceil_height
mov   ax, dx
dont_adjust_to_ceil_height:

cmp  bx, (FLOOR_RAISEFLOORCRUSH * 2)
jne   finally_set_destheight
sub   ax, (8 SHL SHORTFLOORBITS)

finally_set_destheight:
mov   dl, 1

jmp   write_floordestheight_secnum_dir



do_floor_switch_case_type_raiseFloorTurbo:
mov   word ptr ds:[si + FLOORMOVE_T.floormove_speed], (FLOORSPEED * 4)

do_raisefloor:
mov   dx, word ptr es:[di + SECTOR_T.sec_floorheight]
call  P_FindNextHighestFloor_
mov   dl, 1
jmp   write_floordestheight_secnum_dir

do_floor_switch_case_type_raiseFloorToNearest:
mov   word ptr ds:[si + FLOORMOVE_T.floormove_speed], FLOORSPEED

jmp   do_raisefloor

do_floor_switch_case_type_raiseFloor24AndChange:
SELFMODIFY_set_frontsector:
mov   ax, 01000h
SHIFT_MACRO shl   ax 4
xchg  ax, di
mov   dh, byte ptr es:[di + SECTOR_T.sec_floorpic]
mov   di, word ptr ds:[di + _sectors_physics + SECTOR_PHYSICS_T.secp_special] ; high byte garbage.
xchg  ax, di
mov   byte ptr es:[di + SECTOR_T.sec_floorpic], dh
mov   byte ptr ds:[di + _sectors_physics + SECTOR_PHYSICS_T.secp_special], al

; fall thru

do_floor_switch_case_type_raiseFloor24:
mov   ax, (24 SHL SHORTFLOORBITS)
do_raisefloor_fixed:
add   ax, word ptr es:[di+ SECTOR_T.sec_floorheight] 
mov   word ptr ds:[si + FLOORMOVE_T.floormove_speed], FLOORSPEED
;mov   dl, 1 ; dl already 1.
jmp   write_floordestheight_secnum_dir
do_floor_switch_case_type_raiseFloor512:
mov   ax, (512 SHL SHORTFLOORBITS)
jmp   do_raisefloor_fixed



do_floor_switch_case_type_raiseToTexture:

mov   word ptr ds:[si + FLOORMOVE_T.floormove_secnum], ax
mov   word ptr ds:[si + FLOORMOVE_T.floormove_speed], FLOORSPEED
mov   byte ptr ds:[si + FLOORMOVE_T.floormove_direction], dl ; 1



push  word ptr es:[di + SECTOR_T.sec_floorheight]
pop   word ptr cs:[SELFMODIFY_add_floorheight+1]

mov   bx, word ptr es:[di + SECTOR_T.sec_linesoffset]
mov   ax, word ptr es:[di + SECTOR_T.sec_linecount]

sal   bx, 1
add   bx, _linebuffer

sal   ax, 1
add   ax, bx

mov   word ptr cs:[SELFMODIFY_set_raisetotexture_linecount + 2], ax ; set end case.

mov   ax, 07FFFh ; maxshort

; loop from bx to dx
loop_next_secnum_raisetotexture:

; if twosided?
mov   cx, word ptr ds:[bx]
xchg  cx, bx
mov   dx, LINEFLAGSLIST_SEGMENT
mov   es, dx
test  byte ptr es:[bx], ML_TWOSIDED
je    continue_secnum_raisetotextureloop


mov   dx, LINES_SEGMENT
mov   es, dx


SHIFT_MACRO shl       bx 2


; cx has old loop iter
; bx has lines ptr.

les   bx, dword ptr es:[bx + LINE_T.l_sidenum + (0 * 2)] ; side 0
mov   di, es ; side 1
mov   dx, SIDES_SEGMENT
mov   es, dx

SHIFT_MACRO sal bx 3
mov   bx, word ptr es:[bx + SIDE_T.s_bottomtexture] ; side0bottomtexture

SHIFT_MACRO sal di 3
mov   di, word ptr es:[di + SIDE_T.s_bottomtexture] ; side1bottomtexture

; bx has side 0 bottom tex
; di has side 1 bottom tex

mov   dx, TEXTUREHEIGHTS_SEGMENT
mov   es, dx

;    if ((textureheights[sidebottomtexture]+1) < minsize) {
;        minsize = textureheights[sidebottomtexture]+1;
;    }

xor   dx, dx
mov   dl, byte ptr es:[bx]
cmp   dx, ax
jg    dont_set_new_min_a
xchg  ax, dx
dont_set_new_min_a:

mov   dl, byte ptr es:[di]
cmp   dx, ax
jg    dont_set_new_min_b
xchg  ax, dx
dont_set_new_min_b:




continue_secnum_raisetotextureloop:
mov   bx, cx ; restore bx loop counter
inc   bx
inc   bx
SELFMODIFY_set_raisetotexture_linecount:
cmp   bx, 01000h
jl    loop_next_secnum_raisetotexture

;			  floor->floordestheight = sectors[floor->secnum].floorheight + (minsize << SHORTFLOORBITS);

; al was a byte, minsize - 1

inc   ax
SHIFT_MACRO shl ax SHORTFLOORBITS
SELFMODIFY_add_floorheight:
add   ax, 01000h ;   word ptr es:[di+ SECTOR_T.sec_floorheight] 
mov   word ptr ds:[si + FLOORMOVE_T.floormove_floordestheight], ax



jmp   done_with_dofloor_switch_block
do_floor_switch_case_type_lowerAndChange:

mov   word ptr ds:[si + FLOORMOVE_T.floormove_secnum], ax
mov   word ptr ds:[si + FLOORMOVE_T.floormove_speed], FLOORSPEED
mov   byte ptr ds:[si + FLOORMOVE_T.floormove_direction], dl ; 1


mov   word ptr cs:[selfmodify_check_secnum+4], ax
xor   dx, dx
call  P_FindHighestOrLowestFloorSurrounding_

mov   word ptr ds:[si + FLOORMOVE_T.floormove_floordestheight], ax  ; STORE FLOORDESTHEIGHT FOR LATER
mov   dl, byte ptr es:[di + SECTOR_T.sec_floorpic]
mov   byte ptr ds:[si + FLOORMOVE_T.floormove_texture], dl  


; ax is floordestheight for loop

; cx and di and bx are free
; bx will be loop counter.

mov   bx, word ptr es:[di + SECTOR_T.sec_linesoffset]
mov   cx, word ptr es:[di + SECTOR_T.sec_linecount]

sal   bx, 1
add   bx, _linebuffer

sal   cx, 1
add   cx, bx

mov   word ptr cs:[SELFMODIFY_set_lowerandchange_linecount + 2], cx ; set end case.

loop_next_secnum_lowerandchange:


; if twosided?
mov   cx, word ptr ds:[bx]
xchg  cx, bx
mov   dx, LINEFLAGSLIST_SEGMENT
mov   es, dx
test  byte ptr es:[bx], ML_TWOSIDED
je    continue_secnum_lowerandchangeloop


;	if (sideline_physics->frontsecnum == secnum) {

mov   dx, LINES_PHYSICS_SEGMENT
mov   es, dx

SHIFT_MACRO shl       bx 4


mov   di, word ptr es:[bx + LINE_PHYSICS_T.lp_frontsecnum]
selfmodify_check_secnum:
cmp   word ptr es:[bx + LINE_PHYSICS_T.lp_frontsecnum], 01000h 
jne   set_sector_values_and_break_loop
mov   di, word ptr es:[bx + LINE_PHYSICS_T.lp_backsecnum]
set_sector_values_and_break_loop:


SHIFT_MACRO shl di 4
mov   ax, SECTORS_SEGMENT
mov   es, ax
mov   al, byte ptr es:[di + SECTOR_T.sec_floorpic]
mov   byte ptr ds:[si + FLOORMOVE_T.floormove_texture], al
mov   al, byte ptr es:[di + _sectors_physics + SECTOR_PHYSICS_T.secp_special]
mov   byte ptr ds:[si + FLOORMOVE_T.floormove_newspecial], al

jmp   done_with_dofloor_switch_block




continue_secnum_lowerandchangeloop:
mov   bx, cx ; restore bx loop countr

inc   bx
inc   bx
SELFMODIFY_set_lowerandchange_linecount:
cmp   bx, 01000h
jl    loop_next_secnum_lowerandchange



jmp   done_with_dofloor_switch_block



ENDP



PROC    EV_BuildStairs_ NEAR
PUBLIC  EV_BuildStairs_


push  bx
push  cx
push  si
push  di
push  bp
mov   bp, sp
sub   sp, 0218h
mov   byte ptr [bp - 2], dl
mov   word ptr [bp - 012h], 0
lea   dx, [bp - 0218h]
cbw  
xor   bx, bx
mov   word ptr [bp - 010h], 0
call  P_FindSectorsFromLineTag_
cmp   word ptr [bp - 0218h], 0
jge   label_30
jmp   label_51
label_30:
mov   si, word ptr [bp - 010h]
mov   word ptr [bp - 6], SIZEOF_THINKER_T
mov   ax, word ptr [bp + si - 0218h]
xor   dx, dx
mov   word ptr [bp - 8], ax
mov   cx, ax
mov   ax, SECTORS_SEGMENT
shl   cx, 4
mov   es, ax
mov   bx, cx
mov   ax, TF_MOVEFLOOR_HIGHBITS
mov   di, word ptr es:[bx]

call  P_CreateThinker_
mov   bx, ax
mov   si, ax
sub   ax, (_thinkerlist + THINKER_T.t_data)
div   word ptr [bp - 6]
mov   word ptr [bp - 012h], 1
mov   byte ptr ds:[bx + 4], 1
mov   dx, word ptr [bp - 8]
add   word ptr [bp - 010h], 2
mov   word ptr ds:[bx + 2], dx
mov   bx, cx
mov   word ptr ds:[bx + _sectors_physics + SECTOR_PHYSICS_T.secp_specialdataRef], ax
mov   al, byte ptr [bp - 2]
add   bx, _sectors_physics + SECTOR_PHYSICS_T.secp_specialdataRef
cmp   al, 1
jne   label_42
mov   word ptr [bp - 0Eh], (FLOORSPEED*4)
mov   word ptr [bp - 0Ch], (16 SHL SHORTFLOORBITS)
label_39:
mov   cx, word ptr [bp - 0Ch]
mov   ax, word ptr [bp - 0Eh]
add   cx, di
mov   word ptr ds:[si + 9], ax
mov   word ptr ds:[si + 7], cx
label_52:
mov   bx, word ptr [bp - 8]
mov   ax, SECTORS_SEGMENT
shl   bx, 4
mov   es, ax
mov   al, byte ptr es:[bx + 4]
mov   byte ptr [bp - 4], al
mov   ax, word ptr es:[bx + SECTOR_T.sec_linecount]
xor   di, di
mov   word ptr [bp - 0Ah], ax
mov   ax, word ptr es:[bx + SECTOR_T.sec_linesoffset]
xor   dl, dl
mov   word ptr [bp - 014h], ax
label_38:
mov   al, dl
xor   ah, ah
cmp   ax, word ptr [bp - 0Ah]
jge   label_41
add   ax, word ptr [bp - 014h]
add   ax, ax
mov   bx, ax
add   bx, _linebuffer
mov   ax, word ptr ds:[bx]
mov   bx, LINEFLAGSLIST_SEGMENT
mov   es, bx
mov   bx, ax
test  byte ptr es:[bx], 4
jne   label_36
label_35:
inc   dl
jmp   label_38
label_42:
test  al, al
jne   label_39
mov   word ptr [bp - 0Eh], (FLOORSPEED / 4)
mov   word ptr [bp - 0Ch], (8 SHL SHORTFLOORBITS)
jmp   label_39
label_41:
jmp   label_40
label_36:
mov   bx, LINES_PHYSICS_SEGMENT
shl   ax, 4
mov   es, bx
mov   bx, ax

mov   bx, word ptr es:[bx + LINE_PHYSICS_T.lp_frontsecnum]
cmp   bx, word ptr [bp - 8]
jne   label_35
mov   bx, ax
mov   word ptr [bp - 016h], 0
mov   si, word ptr es:[bx + LINE_PHYSICS_T.lp_backsecnum]
add   bx, LINE_PHYSICS_T.lp_backsecnum
mov   ax, si
mov   bx, SECTORS_SEGMENT
shl   ax, 4
mov   es, bx
mov   bx, ax
mov   word ptr [bp - 018h], ax
mov   al, byte ptr es:[bx + 4]
add   bx, 4
cmp   al, byte ptr [bp - 4]
jne   label_35
mov   bx, word ptr [bp - 018h]
add   bx, _sectors_physics + SECTOR_PHYSICS_T.secp_specialdataRef
add   cx, word ptr [bp - 0Ch]
cmp   word ptr ds:[bx], 0
jne   label_35
mov   ax, TF_MOVEFLOOR_HIGHBITS
mov   word ptr [bp - 6], SIZEOF_THINKER_T

call  P_CreateThinker_
xor   dx, dx
mov   di, ax
sub   ax, (_thinkerlist + THINKER_T.t_data)
div   word ptr [bp - 6]
mov   byte ptr ds:[di + 4], 1
mov   word ptr ds:[di + 7], cx
mov   word ptr ds:[di + 2], si
mov   word ptr ds:[di + 7], cx
mov   dx, word ptr [bp - 0Eh]
mov   word ptr ds:[di + 9], dx
mov   word ptr [bp - 8], si
mov   word ptr ds:[bx], ax
jmp   label_52
label_40:
test  di, di
je    label_54
jmp   label_52
label_54:
mov   si, word ptr [bp - 010h]
cmp   word ptr [bp + si - 0218h], 0
jl    label_51
jmp   label_30
label_51:
mov   ax, word ptr [bp - 012h]
LEAVE_MACRO 
pop   di
pop   si
pop   cx
pop   bx
ret   

ENDP



PROC    P_FLOOR_ENDMARKER_ NEAR
PUBLIC  P_FLOOR_ENDMARKER_
ENDP

END
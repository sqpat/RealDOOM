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


EXTRN FixedMul16u32_:FAR
EXTRN FixedMul1632_:FAR
EXTRN FixedMul2424_:FAR
EXTRN FixedMul2432_:FAR
EXTRN FixedMul_:FAR
EXTRN FixedDiv_:FAR
EXTRN FixedMulBig1632_:FAR
EXTRN FixedMulTrigNoShift_:PROC
EXTRN S_StartSound_:FAR
EXTRN R_PointToAngle2_16_:PROC
EXTRN R_PointToAngle2_:PROC
EXTRN P_Random_:NEAR
EXTRN P_UseSpecialLine_:PROC
EXTRN P_DamageMobj_:NEAR
EXTRN P_SetMobjState_:NEAR
EXTRN P_TouchSpecialThing_:NEAR
EXTRN P_CrossSpecialLine_:NEAR
EXTRN P_ShootSpecialLine_:NEAR
EXTRN P_SpawnMobj_:NEAR
EXTRN P_RemoveMobj_:NEAR


.DATA

EXTRN _prndindex:BYTE
EXTRN _setStateReturn:WORD
EXTRN _attackrange16:WORD


.CODE


;void __near P_SpawnPuff ( fixed_t	x, fixed_t	y, fixed_t	z ){

;P_SpawnPuff_

PROC P_SpawnPuff_ NEAR
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

push  -1        ; complicated for 8088...
push  MT_PUFF
push  di
push  si

call  P_SpawnMobj_

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
ret   
spark_punch_on_wall:
mov   dx, S_PUFF3
mov   ax, bx
call  P_SetMobjState_
ret   


ENDP



;P_SpawnBlood_

PROC P_SpawnBlood_ NEAR
PUBLIC P_SpawnBlood_


push  bp
mov   bp, sp
push  ax
push  dx
push  bx
push  cx
mov   ax, word ptr ds:[_prndindex]
inc   ax
xor   ah, ah
mov   word ptr ds:[_prndindex], ax
mov   bx, ax
mov   ax, RNDTABLE_SEGMENT
mov   es, ax
mov   ax, bx
inc   ax
mov   cl, byte ptr es:[bx]
xor   ah, ah
xor   ch, ch
mov   bx, ax
mov   word ptr ds:[_prndindex], ax
mov   al, byte ptr es:[bx]
sub   cx, ax
mov   ax, cx
push  -1
cwd   
push  MT_BLOOD
mov   cl, 10
shl   dx, cl
rol   ax, cl
xor   dx, ax
and   ax, 0FC00h
xor   dx, ax
mov   bx, word ptr [bp - 6]
add   si, ax
adc   di, dx
mov   cx, word ptr [bp - 8]
push  di
mov   ax, word ptr [bp - 2]
push  si
mov   dx, word ptr [bp - 4]
call  P_SpawnMobj_
mov   ax, word ptr ds:[_prndindex]
inc   ax
xor   ah, ah
mov   bx, word ptr ds:[_setStateReturn]
mov   word ptr ds:[_prndindex], ax
mov   di, ax
mov   ax, RNDTABLE_SEGMENT
mov   word ptr [bx + 018h], 2
mov   es, ax
mov   al, byte ptr es:[di]
lea   si, [bx + 01Bh]
and   al, 3
sub   byte ptr [si], al
mov   al, byte ptr [bx + 01Bh]
cmp   al, 1
jb    label_3
cmp   al, 240
jbe   label_4
label_3:
mov   byte ptr [bx + 01Bh], 1
label_4:
mov   ax, word ptr [bp + 4]
cmp   ax, 12
jg    label_5
cmp   ax, 9
jge   label_6
label_5:
cmp   word ptr [bp + 4], 9
jl    label_7
LEAVE_MACRO
ret   2
label_6:
mov   dx, S_BLOOD2
mov   ax, bx
call  P_SetMobjState_
LEAVE_MACRO
ret 2
label_7:
mov   dx, S_BLOOD3
mov   ax, bx
call  P_SetMobjState_
LEAVE_MACRO 
ret   2

ENDP


END
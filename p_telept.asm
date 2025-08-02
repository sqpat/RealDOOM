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

EXTRN _P_TeleportMove:DWORD
EXTRN _P_SpawnMobj:DWORD

EXTRN FastMul16u32u_:NEAR


.DATA




.CODE

; 02000h
COSINE_OFFSET_IN_SINE = ((FINECOSINE_SEGMENT - FINESINE_SEGMENT) SHL 4)


PROC    P_TELEPT_STARTMARKER_ NEAR
PUBLIC  P_TELEPT_STARTMARKER_
ENDP

PROC    EV_Teleport_ NEAR
PUBLIC  EV_Teleport_

;int16_t __near EV_Teleport (uint8_t linetag, int16_t		side,mobj_t __near*	thing,mobj_pos_t __far* thing_pos){

push  cx
push  si
push  di
push  bp
mov   bp, sp
sub   sp, 018h
mov   byte ptr [bp - 2], al
mov   word ptr [bp - 018h], bx
les   bx, dword ptr [bp + 0Ah]

test  byte ptr es:[bx + MOBJ_POS_T.mp_flags2], MF_MISSILE
jne   exit_ev_teleport_return_0
cmp   dx, 1
je    exit_ev_teleport_return_0
xor   cx, cx
xor   si, si
xor   di, di
label_3:
mov   bx, _numsectors
cmp   cx, word ptr ds:[bx]
jge   exit_ev_teleport_return_0
lea   bx, [si + _sectors_physics + SECTOR_PHYSICS_T.secp_tag]
mov   al, byte ptr ds:[bx]
cmp   al, byte ptr [bp - 2]
jne   label_1
mov   ax, di
label_4:
imul  bx, ax, SIZEOF_THINKER_T
mov   ax, word ptr ds:[bx + _thinkerlist + THINKER_T.t_next]
test  ax, ax
jne   label_2
label_1:
add   si, SIZEOF_SECTOR_PHYSICS_T
inc   cx
jmp   label_3
exit_ev_teleport_return_0:
xor   ax, ax
LEAVE_MACRO 
pop   di
pop   si
pop   cx
ret   4
label_2:
imul  bx, ax, SIZEOF_THINKER_T
mov   dx, word ptr ds:[bx + _thinkerlist]
xor   dl, dl
and   dh, (TF_FUNCBITS SHR 8)
cmp   dx, TF_MOBJTHINKER_HIGHBITS
jne   label_4
add   bx, _thinkerlist + THINKER_T.t_data
cmp   byte ptr ds:[bx + MOBJ_T.m_mobjtype], MT_TELEPORTMAN
jne   label_4
mov   bx, word ptr ds:[bx + 4]
cmp   bx, cx
jne   label_4
imul  dx, ax, SIZEOF_MOBJ_POS_T
les   di, dword ptr [bp + 0Ah]
mov   ax, word ptr es:[di + MOBJ_POS_T.mp_x + 0]
mov   word ptr [bp - 0Ah], ax
mov   ax, word ptr es:[di + MOBJ_POS_T.mp_x + 2]
mov   word ptr [bp - 8], ax
mov   ax, word ptr es:[di + MOBJ_POS_T.mp_y + 0]
mov   word ptr [bp - 4], MOBJPOSLIST_6800_SEGMENT
mov   word ptr [bp - 010h], ax
mov   ax, word ptr es:[di + MOBJ_POS_T.mp_y + 2]
push  cx
mov   word ptr [bp - 6], ax
mov   ax, word ptr es:[di + MOBJ_POS_T.mp_z + 0]
mov   bx, dx
mov   word ptr [bp - 0Ch], ax
mov   ax, word ptr es:[di  + MOBJ_POS_T.mp_z + 2]
mov   di, word ptr [bp - 018h]
mov   word ptr [bp - 016h], ax
mov   ax, word ptr ds:[di + 4]
mov   es, word ptr [bp - 4]
push  word ptr es:[bx + MOBJ_POS_T.mp_y + 2]
mov   cx, word ptr [bp + 0Ch]
push  word ptr es:[bx + MOBJ_POS_T.mp_y + 0]
mov   word ptr [bp - 0Eh], ax
push  word ptr es:[bx + MOBJ_POS_T.mp_x + 2]
mov   ax, di
push  word ptr es:[bx + MOBJ_POS_T.mp_x + 0]
mov   bx, word ptr [bp + 0Ah]
mov   si, dx
call  dword ptr [_P_TeleportMove]
test  al, al
jne   label_5
jmp   label_6
label_5:
mov   bx, word ptr [bp + 0Ah]
mov   dx, word ptr ds:[di + 6]
mov   ax, word ptr ds:[di + 6]
mov   es, word ptr [bp + 0Ch]
xor   ah, ah
sar   dx, 3
and   al, 7
mov   word ptr es:[bx + MOBJ_POS_T.mp_z + 2], dx
shl   ax, 0Dh   ; todo no
mov   word ptr es:[bx + MOBJ_POS_T.mp_z + 0], ax
cmp   byte ptr ds:[di + MOBJ_T.m_mobjtype], 0
jne   label_7
mov   di, word ptr [bp + 0Ah]
mov   bx, _player + PLAYER_T.player_viewheightvalue
mov   ax, word ptr es:[di + MOBJ_POS_T.mp_z + 0]
mov   dx, word ptr es:[di  + MOBJ_POS_T.mp_z + 2]
add   ax, word ptr ds:[bx]
adc   dx, word ptr ds:[bx + 2]
mov   bx, _player + PLAYER_T.player_viewzvalue
mov   word ptr ds:[bx], ax
mov   word ptr ds:[bx + 2], dx
label_7:
push  word ptr [bp - 0Eh]
mov   bx, word ptr [bp - 010h]
push  MT_TFOG
mov   cx, word ptr [bp - 6]
push  word ptr [bp - 016h]
mov   ax, word ptr [bp - 0Ah]
push  word ptr [bp - 0Ch]
mov   dx, word ptr [bp - 8]
call  dword ptr ds:[_P_SpawnMobj]
mov   bx, _setStateReturn
mov   dx, sfx_telept
mov   ax, word ptr ds:[bx]
;call  S_StartSound_
db 0FFh  ; lcall[addr]
db 01Eh  ;
dw _S_StartSound_addr
nop   
mov   es, word ptr [bp - 4]
push  -1
mov   bx, word ptr [bp + 0Ah]
mov   ax, FINESINE_SEGMENT
push  MT_TFOG
mov   di, word ptr es:[si + MOBJ_POS_T.mp_angle + 2]
mov   es, word ptr [bp + 0Ch]
shr   di, 3
push  word ptr es:[bx  + MOBJ_POS_T.mp_z + 2]
shl   di, 2
push  word ptr es:[bx + MOBJ_POS_T.mp_z + 0]
mov   es, ax
mov   ax, 20
mov   bx, word ptr es:[di + MOBJ_POS_T.mp_x + 0]
mov   cx, word ptr es:[di + MOBJ_POS_T.mp_x + 2]
; call  FastMul16u32u_
db 0FFh  ; lcall[addr]
db 01Eh  ;
dw _FastMul16u32u_addr
mov   es, word ptr [bp - 4]
mov   bx, word ptr es:[si + MOBJ_POS_T.mp_y + 0]
add   bx, ax
mov   ax, word ptr es:[si + MOBJ_POS_T.mp_y + 2]
adc   ax, dx
mov   word ptr [bp - 012h], ax
mov   ax, FINESINE_SEGMENT
mov   word ptr [bp - 014h], bx
mov   es, ax
mov   ax, 20
mov   bx, word ptr es:[di + COSINE_OFFSET_IN_SINE + 0]
mov   cx, word ptr es:[di + COSINE_OFFSET_IN_SINE + 2]
add   di, COSINE_OFFSET_IN_SINE  ; dont need
; call  FastMul16u32u_
db 0FFh  ; lcall[addr]
db 01Eh  ;
dw _FastMul16u32u_addr
mov   es, word ptr [bp - 4]
mov   bx, word ptr [bp - 014h]
mov   cx, word ptr [bp - 012h]
add   ax, word ptr es:[si + MOBJ_POS_T.mp_x + 0]
adc   dx, word ptr es:[si + MOBJ_POS_T.mp_x + 2]
call  dword ptr ds:[_P_SpawnMobj]
mov   bx, _setStateReturn
mov   dx, sfx_telept
mov   ax, word ptr ds:[bx]
mov   bx, word ptr [bp - 018h]
;call  S_StartSound_
db 0FFh  ; lcall[addr]
db 01Eh  ;
dw _S_StartSound_addr
cmp   byte ptr ds:[bx + MOBJ_T.m_mobjtype], MT_PLAYER
jne   label_8
mov   bx, _playerMobj
mov   bx, word ptr ds:[bx]
mov   byte ptr ds:[bx + MOBJ_T.m_reactiontime], 18
label_8:
mov   es, word ptr [bp - 4]
mov   bx, word ptr [bp + 0Ah]
mov   ax, word ptr es:[si + MOBJ_POS_T.mp_angle + 0]
mov   dx, word ptr es:[si + MOBJ_POS_T.mp_angle + 2]
mov   es, word ptr [bp + 0Ch]
mov   word ptr es:[bx + MOBJ_POS_T.mp_angle + 0], ax
mov   word ptr es:[bx + MOBJ_POS_T.mp_angle + 2], dx
mov   bx, word ptr [bp - 018h]
xor    ax, ax
lea    di, [bx + MOBJ_T.m_momx + 0]
push   ds
pop    es
stosw
stosw
stosw
stosw
stosw
stosw
inc ax ; return 1
LEAVE_MACRO 
pop   di
pop   si
pop   cx
ret   4
label_6:
xor   ah, ah
LEAVE_MACRO 
pop   di
pop   si
pop   cx
ret   4




ENDP

PROC    P_TELEPT_ENDMARKER_ NEAR
PUBLIC  P_TELEPT_ENDMARKER_
ENDP

END
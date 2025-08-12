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




EXTRN P_TeleportMove_:NEAR
EXTRN P_SpawnMobj_:NEAR



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


; bp - 2  thing
; bp - 4  thingpos offset
; bp - 6  thingpos offset segment

; cx thing_pos offset



push  si
push  di
push  bp
mov   bp, sp
mov   byte ptr cs:[OFFSET SELFMODIFY_telept_linetag + 4], al
push  bx  ; bp - 2
mov   di, bx
mov   bx, cx
mov   es, word ptr ds:[_MOBJPOSLIST_6800_SEGMENT_PTR]
push  es ; bp - 4
push  bx ; bp - 6

test  byte ptr es:[bx + MOBJ_POS_T.mp_flags2], MF_MISSILE
jne   exit_ev_teleport_return_0
cmp   dx, 1
je    exit_ev_teleport_return_0
push  word ptr ds:[_numsectors]
pop   word ptr cs:[OFFSET SELFMODIFY_telept_numsectors + 2]
xor   cx, cx   ; i 
xor   si, si   ; sector physics for inner loop

;    for (i = 0; i < numsectors; i++) {

loop_next_sector:

SELFMODIFY_telept_linetag:
cmp   byte ptr ds:[si + _sectors_physics + SECTOR_PHYSICS_T.secp_tag], 010h
je    line_tag_match

continue_sector_loop:
add   si, SIZEOF_SECTOR_PHYSICS_T
inc   cx
SELFMODIFY_telept_numsectors:
cmp   cx, 01000h
jl    loop_next_sector

exit_ev_teleport_return_0:
xor   ax, ax
LEAVE_MACRO 
pop   di
pop   si
ret

line_tag_match:

xor   ax, ax


loop_next_thinker:
mov   bx, SIZEOF_THINKER_T
mul   bx
xchg  ax, bx
mov   ax, word ptr ds:[bx + _thinkerlist + THINKER_T.t_next]
test  ax, ax
je    continue_sector_loop




mov   bx, SIZEOF_THINKER_T
xchg  ax, bx
mul   bx
xchg  ax, bx ; preserve ax/counter.
mov   dx, word ptr ds:[bx + _thinkerlist]
and   dx, TF_FUNCBITS
cmp   dx, TF_MOBJTHINKER_HIGHBITS
jne   loop_next_thinker
cmp   byte ptr ds:[bx + _thinkerlist + THINKER_T.t_data + MOBJ_T.m_mobjtype], MT_TELEPORTMAN
jne   loop_next_thinker
cmp   cx, word ptr ds:[bx + _thinkerlist + THINKER_T.t_data + MOBJ_T.m_secnum]
jne   loop_next_thinker

; point of no return... si free to use again

; bx free now
mov   dx, SIZEOF_MOBJ_POS_T
mul   dx
xchg  ax, dx

; push things for three functions down the road.
; third call will be
;				fogRef = P_SpawnMobj (m_pos->x.w + FastMul16u32(20, finecosine[an]), m_pos->y.w + FastMul16u32(20,finesine[an]) , thing_pos->z.w, MT_TFOG, -1);

; ax known zero after xchg
dec   ax
;mov   ax, -1
push  ax
mov   ax, MT_TFOG
push  ax
; still need to calculate two z pushes later.

; push things for two functions down the road.
; second call will be
;				fogRef = P_SpawnMobj (oldx.w, oldy.w, oldz.w, MT_TFOG, oldsecnum);

;mov   di, word ptr [bp - 2]
; already bp - 2

push  word ptr ds:[di + MOBJ_T.m_secnum]
;mov   ax, MT_TFOG
push  ax
lds   bx, dword ptr [bp - 6]
lea   si, [bx  + MOBJ_POS_T.mp_z + 2]
std
lodsw    ; z hi
push  ax 
lodsw    ; z lo
push  ax
lodsw    ; y hi   ; NOT STACK PARAMS! x and y will be popped into registers before their call.
push  ax
lodsw    ; y lo
push  ax
lodsw    ; x hi
push  ax
lodsw    ; x lo
push  ax


push  cx ; for first call
mov   cx, ds ; cx:bx for mobjpos

mov   si, dx
lea   si, [si + MOBJ_POS_T.mp_y + 2]
lodsw    ; y hi   ; NOT STACK PARAMS! x and y will be popped into registers before their call.
push  ax
lodsw    ; y lo
push  ax
lodsw    ; x hi
push  ax
lodsw    ; x lo
push  ax
; si now offset + 0 again.

push  ss
pop   ds  ; restore ds
cld




; -1          func 3
; fog         func 3
     ; NOT ON STACK YET  func 3 z hi
     ; NOT ON STACK YET  func 3 z lo  P_SpawnMobj_
; oldsecnum   func 2
; fog         func 2
; oldz hi     func 2
; oldz lo     func 2
; oldy hi     func 2 not param, to be popped off into cx
; oldy lo     func 2 not param, to be popped off into bx
; oldx hi     func 2 not param, to be popped off into dx
; oldx lo     func 2 not param, to be popped off into ax P_SpawnMobj_
; m->secnum   func 1 
; mpos->y hi  func 1 
; mpos->y lo  func 1 
; mpos->x hi  func 1 
; mpos->x lo  func 1  P_TeleportMove_

mov   ax, di   ; ax gets thing ptr for first call



mov   si, dx ; not needed, already equal after lodsw...
push  cs
call  P_TeleportMove_
jnc   exit_ev_teleport_return_0; return false

les   bx, dword ptr [bp - 6]

; TODO
;		#if (EXE_VERSION != EXE_VERSION_FINAL)



mov   dx, word ptr ds:[di + MOBJ_T.m_floorz]
xor   ax, ax
sar   dx, 1
rcr   ax, 1
sar   dx, 1
rcr   ax, 1
sar   dx, 1
rcr   ax, 1

mov   word ptr es:[bx + MOBJ_POS_T.mp_z + 0], ax
mov   word ptr es:[bx + MOBJ_POS_T.mp_z + 2], dx

; TODO
;		#endif


cmp   byte ptr ds:[di + MOBJ_T.m_mobjtype], MT_PLAYER
jne   skip_player_view_height_adjusted

;	player.viewzvalue.w = thing_pos->z.w + player.viewheightvalue.w;

les   ax, dword ptr es:[bx + MOBJ_POS_T.mp_z + 0]
mov   dx, es
add   ax, word ptr ds:[_player + PLAYER_T.player_viewheightvalue + 0]
adc   dx, word ptr ds:[_player + PLAYER_T.player_viewheightvalue + 2]
mov   word ptr ds:[_player + PLAYER_T.player_viewzvalue + 0], ax
mov   word ptr ds:[_player + PLAYER_T.player_viewzvalue + 2], dx
skip_player_view_height_adjusted:

pop   ax
pop   dx
pop   bx
pop   cx

call  P_SpawnMobj_
mov   dl, SFX_TELEPT
mov   ax, word ptr ds:[_setStateReturn]
;call  S_StartSound_
db 0FFh  ; lcall[addr]
db 01Eh  ;
dw _S_StartSound_addr


lds   bx, dword ptr [bp - 6]
push  word ptr ds:[bx + MOBJ_POS_T.mp_z + 2]
push  word ptr ds:[bx + MOBJ_POS_T.mp_z + 0]  ; push call 1 z

mov   di, word ptr ds:[si + MOBJ_POS_T.mp_angle + 2]

;				an = m_pos->angle.hu.intbits >> SHORTTOFINESHIFT;

shr   di, 1
and   di, 0FFFCh  ; clear bottom 3 bits. same as shr 3 shl 2

; time to calculate ax dx bx cx.
; z, mt_tfog, -1 all pushed on stack already.
;	fogRef = P_SpawnMobj (m_pos->x.w + FastMul16u32(20, finecosine[an]), m_pos->y.w + FastMul16u32(20,finesine[an]) , thing_pos->z.w, MT_TFOG, -1);


mov   ax, FINESINE_SEGMENT
mov   es, ax
mov   cx, 20
les   bx, dword ptr es:[di + 0]
mov   ax, es

; FastMul16u32u
MUL  CX        ; AX * CX
XCHG CX, AX    ; store low product to be high result. Retrieve orig AX
MUL  BX        ; AX * BX
ADD  DX, CX    ; add 

add   ax, word ptr ds:[si + MOBJ_POS_T.mp_y + 0]
adc   dx, word ptr ds:[si + MOBJ_POS_T.mp_y + 2]
push  dx
push  ax   ; get these after next mul call

mov   ax, FINECOSINE_SEGMENT
mov   es, ax
mov   cx, 20
les   bx, dword ptr es:[di + 0]
mov   ax, es

; FastMul16u32u
MUL  CX        ; AX * CX
XCHG CX, AX    ; store low product to be high result. Retrieve orig AX
MUL  BX        ; AX * BX
ADD  DX, CX    ; add 

add   ax, word ptr ds:[si + MOBJ_POS_T.mp_x + 0]
adc   dx, word ptr ds:[si + MOBJ_POS_T.mp_x + 2] ;ax/dx ready

push  ss
pop   ds ; restore ds

pop   bx
pop   cx ; cx/bx ready
call  P_SpawnMobj_
mov   dl, SFX_TELEPT
mov   ax, word ptr ds:[_setStateReturn]
;call  S_StartSound_
db 0FFh  ; lcall[addr]
db 01Eh  ;
dw _S_StartSound_addr

pop   bx  ;mov   bx, word ptr [bp - 2]  ; last use.
cmp   byte ptr ds:[bx + MOBJ_T.m_mobjtype], MT_PLAYER
jne   skip_player_reaction_time_set
mov   byte ptr ds:[bx + MOBJ_T.m_reactiontime], 18
skip_player_reaction_time_set:

lds   di, dword ptr [bp - 6]
add   si, MOBJ_POS_T.mp_angle
add   di, MOBJ_POS_T.mp_angle
push  ds  ; lds above
pop   es
movsw
movsw
;				thing_pos->angle = m_pos->angle;
;				thing->momx.w = thing->momy.w = thing->momz.w = 0;
;				return 1;




xor    ax, ax
lea    di, [bx + MOBJ_T.m_momx + 0]
push   ss
pop    es

stosw
stosw
stosw
stosw
stosw
stosw

push   ss
pop    ds

inc ax ; return 1
LEAVE_MACRO 
pop   di
pop   si
ret




ENDP

PROC    P_TELEPT_ENDMARKER_ NEAR
PUBLIC  P_TELEPT_ENDMARKER_
ENDP

END
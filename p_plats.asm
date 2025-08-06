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
EXTRN P_FindHighestOrLowestFloorSurrounding_:NEAR
EXTRN P_FindSectorsFromLineTag_:NEAR
EXTRN P_FindNextHighestFloor_:NEAR
EXTRN P_CreateThinker_:FAR
EXTRN T_MovePlaneFloorUp_:NEAR
EXTRN T_MovePlaneFloorDown_:NEAR
EXTRN P_Random_:NEAR
EXTRN P_UpdateThinkerFunc_:NEAR


.DATA



.CODE



PROC    P_PLATS_STARTMARKER_ NEAR
PUBLIC  P_PLATS_STARTMARKER_
ENDP

_plat_raise_jump_table:
dw platraise_switch_case_0
dw platraise_switch_case_1
dw platraise_switch_case_2
dw platraise_switch_case_default


PROC    T_PlatRaise_ NEAR
PUBLIC  T_PlatRaise_ 

;void __near T_PlatRaise(plat_t __near* plat, THINKERREF platRef) {


push        bx
push        cx
push        si
push        di
push        bp
mov         bp, sp
sub         sp, 4
mov         si, ax
mov         word ptr [bp - 4], dx
mov         di, word ptr ds:[si]
mov         ax, SECTORS_SEGMENT
mov         bx, di
mov         es, ax
shl         bx, 4
mov         al, byte ptr ds:[si + PLAT_T.plat_status]
mov         word ptr [bp - 2], bx
mov         dx, word ptr es:[bx]
cmp         al, 3
ja          platraise_switch_case_default
xor         ah, ah
mov         bx, ax
add         bx, ax
jmp         word ptr cs:[bx + _plat_raise_jump_table]
platraise_switch_case_0:
mov         al, byte ptr ds:[si + PLAT_T.plat_crush]
mov         bx, word ptr ds:[si + 6]
cbw        
mov         dx, word ptr ds:[si + 2]
mov         cx, ax
mov         ax, word ptr [bp - 2]
call        T_MovePlaneFloorUp_
mov         cl, al
mov         al, byte ptr ds:[si + PLAT_T.plat_type]
cmp         al, 2
jne         label_1
label_10:
mov         bx, _leveltime
test        byte ptr ds:[bx], 7
jne         label_2
mov         dx, SFX_STNMOV
mov         ax, di

call        S_StartSoundWithParams_
label_2:
cmp         cl, 1
jne         label_3
cmp         byte ptr ds:[si + PLAT_T.plat_crush], 0
je          label_4
label_3:
cmp         cl, 2
je          label_5
platraise_switch_case_default:
platraise_switch_case_3:
done_with_platraise_switch_block:
LEAVE_MACRO       
pop         di
pop         si
pop         cx
pop         bx
ret         
label_1:
cmp         al, 3
je          label_10
jmp         label_2
label_4:
mov         al, byte ptr ds:[si + 8]
mov         dx, SFX_PSTART
mov         byte ptr ds:[si + 9], al
mov         ax, di
mov         byte ptr ds:[si + PLAT_T.plat_status], cl

call        S_StartSoundWithParams_
         
jmp         done_with_platraise_switch_block
label_5:
mov         al, byte ptr ds:[si + 8]
mov         dx, SFX_PSTOP
mov         byte ptr ds:[si + 9], al
mov         ax, di
mov         byte ptr ds:[si + PLAT_T.plat_status], cl

call        S_StartSoundWithParams_
mov         al, byte ptr ds:[si + PLAT_T.plat_type]
cmp         al, 4
je          label_9
cmp         al, 1
jb          done_with_platraise_switch_block
jbe         label_9
cmp         al, 3
ja          done_with_platraise_switch_block
label_9:
mov         ax, word ptr [bp - 4]
call        P_RemoveActivePlat_
LEAVE_MACRO       
pop         di
pop         si
pop         cx
pop         bx
ret         
platraise_switch_case_1:
mov         ax, word ptr [bp - 2]
mov         bx, word ptr ds:[si + 4]
mov         dx, word ptr ds:[si + 2]
xor         cx, cx
call        T_MovePlaneFloorDown_
cmp         al, 2
jne         done_with_platraise_switch_block
mov         al, byte ptr ds:[si + 8]
mov         dx, SFX_PSTOP
mov         byte ptr ds:[si + 9], al
mov         ax, di
mov         byte ptr ds:[si + PLAT_T.plat_status], 2

call        S_StartSoundWithParams_
         
LEAVE_MACRO       
pop         di
pop         si
pop         cx
pop         bx
ret         
platraise_switch_case_2:
dec         byte ptr ds:[si + 9]
je          label_8
jmp         done_with_platraise_switch_block
label_8:
cmp         dx, word ptr ds:[si + 4]
je          label_6
mov         byte ptr ds:[si + PLAT_T.plat_status], 1
label_7:
mov         dx, SFX_PSTART
mov         ax, di

call        S_StartSoundWithParams_
LEAVE_MACRO       
pop         di
pop         si
pop         cx
pop         bx
ret         
label_6:
mov         byte ptr ds:[si + PLAT_T.plat_status], ah
jmp         label_7
ENDP

_doplat_jump_table:
dw switch_block_ev_doplat_case_0
dw switch_block_ev_doplat_case_1
dw switch_block_ev_doplat_case_2
dw switch_block_ev_doplat_case_3
dw switch_block_ev_doplat_case_4


PROC    EV_DoPlat_ NEAR
PUBLIC  EV_DoPlat_ 


push        si
push        di
push        bp
mov         bp, sp
sub         sp, 0218h
mov         byte ptr [bp - 4], al
mov         si, dx
mov         byte ptr [bp - 2], bl
mov         word ptr [bp - 014h], cx
xor         ax, ax
mov         word ptr [bp - 012h], ax
mov         word ptr [bp - 0Eh], ax
test        bl, bl
jne         label_11
mov         al, byte ptr [bp - 4]
xor         dx, dx
xor         ah, ah
call        EV_PlatFunc_
label_11:
mov         al, byte ptr [bp - 4]
lea         dx, [bp - 0218h]
shl         si, 4
xor         bx, bx
mov         word ptr [bp - 0Ch], si
mov         si, word ptr [bp - 012h]
cbw        
add         si, si
call        P_FindSectorsFromLineTag_
mov         word ptr [bp - 0Ah], si
cmp         word ptr [bp + si - 0218h], 0
jl          label_12
label_27:
mov         si, word ptr [bp - 0Ah]
mov         cx, word ptr [bp + si - 0218h]
mov         ax, cx
shl         ax, 4
mov         word ptr [bp - 8], ax
mov         word ptr [bp - 018h], ax
mov         ax, SECTORS_SEGMENT
mov         bx, word ptr [bp - 8]
mov         es, ax
mov         ax, word ptr es:[bx]
mov         di, SIZEOF_THINKER_T
mov         word ptr [bp - 6], ax
mov         ax, TF_PLATRAISE_HIGHBITS
xor         dx, dx

call        P_CreateThinker_
         
mov         bx, ax
mov         si, ax
sub         ax, (_thinkerlist + THINKER_T.t_data)
div         di
mov         word ptr [bp - 0Eh], 1
mov         word ptr [bp - 016h], 0
inc         word ptr [bp - 012h]
mov         di, word ptr [bp - 018h]
mov         word ptr [bp - 010h], ax
mov         word ptr ds:[di + _sectors_physics + SECTOR_PHYSICS_T.secp_specialdataRef], ax
mov         al, byte ptr [bp - 2]
mov         byte ptr ds:[bx + PLAT_T.plat_crush], 0
add         word ptr [bp - 0Ah], 2
mov         byte ptr ds:[bx + PLAT_T.plat_type], al
mov         al, byte ptr [bp - 4]
add         di, _sectors_physics + SECTOR_PHYSICS_T.secp_specialdataRef
mov         byte ptr ds:[bx + PLAT_T.plat_tag], al
mov         al, byte ptr [bp - 2]
mov         word ptr ds:[bx], cx
cmp         al, 4
ja          label_13
xor         ah, ah
mov         di, ax
add         di, ax
jmp         word ptr cs:[di + _doplat_jump_table]
label_12:
jmp         label_14
switch_block_ev_doplat_case_0:
mov         ax, cx
xor         dx, dx
mov         word ptr ds:[bx + 2], 8
call        P_FindHighestOrLowestFloorSurrounding_
mov         bx, ax
cmp         ax, word ptr [bp - 6]
jle         label_17
mov         bx, word ptr [bp - 6]
label_17:
mov         dx, 1
mov         ax, cx
mov         word ptr ds:[si + 4], bx
call        P_FindHighestOrLowestFloorSurrounding_
mov         word ptr ds:[si + 6], ax
cmp         ax, word ptr [bp - 6]
jge         label_18
mov         ax, word ptr [bp - 6]
mov         word ptr ds:[si + 6], ax
label_18:
mov         byte ptr ds:[si + 8], PLATWAIT * 35
call        P_Random_
and         al, 1
mov         dx, SFX_PSTART
mov         byte ptr ds:[si + PLAT_T.plat_status], al
mov         ax, cx
label_15:

call        S_StartSoundWithParams_
label_13:
mov         ax, word ptr [bp - 010h]
mov         si, word ptr [bp - 0Ah]
call        P_AddActivePlat_
cmp         word ptr [bp + si - 0218h], 0
jl          label_14
jmp         label_27
label_14:
mov         ax, word ptr [bp - 0Eh]
LEAVE_MACRO       
pop         di
pop         si
ret         
switch_block_ev_doplat_case_3:
mov         ax, SECTORS_SEGMENT
mov         si, word ptr [bp - 0Ch]
mov         word ptr ds:[bx + 2], 4
mov         es, ax
mov         di, word ptr [bp - 8]
mov         al, byte ptr es:[si + 4]
mov         dx, word ptr [bp - 6]
mov         byte ptr es:[di + 4], al
mov         ax, cx
call        P_FindNextHighestFloor_
mov         byte ptr ds:[bx + 8], 0
add         si, 4
mov         byte ptr ds:[bx + PLAT_T.plat_status], 0
add         di, 4
mov         word ptr ds:[bx + 6], ax
mov         bx, word ptr [bp - 018h]
mov         dx, SFX_STNMOV
add         bx, _sectors_physics + SECTOR_PHYSICS_T.secp_linecount
mov         ax, cx
mov         byte ptr ds:[bx], 0
jmp         label_15
switch_block_ev_doplat_case_2:
mov         ax, SECTORS_SEGMENT
mov         di, word ptr [bp - 0Ch]
mov         si, word ptr [bp - 8]
mov         es, ax
mov         dx, SFX_STNMOV
mov         al, byte ptr es:[di + 4]
add         di, 4
mov         byte ptr es:[si + 4], al
mov         ax, word ptr [bp - 6]
mov         word ptr ds:[bx + 2], 4
add         ax, word ptr [bp - 014h]
mov         byte ptr ds:[bx + 8], 0
shl         ax, 3
add         si, 4
mov         word ptr ds:[bx + 6], ax
mov         ax, cx
mov         byte ptr ds:[bx + PLAT_T.plat_status], 0
jmp         label_15
switch_block_ev_doplat_case_1:
mov         ax, cx
xor         dx, dx
mov         word ptr ds:[bx + 2], PLATSPEED * 4
call        P_FindHighestOrLowestFloorSurrounding_
mov         word ptr ds:[bx + 4], ax
cmp         ax, word ptr [bp - 6]
jle         label_16
mov         ax, word ptr [bp - 6]
mov         word ptr ds:[bx + 4], ax
label_16:
mov         ax, word ptr [bp - 6]
mov         byte ptr ds:[si + 8], PLATWAIT * 35
mov         dx, SFX_PSTART
mov         word ptr ds:[si + 6], ax
mov         ax, cx
mov         byte ptr ds:[si + PLAT_T.plat_status], 1
jmp         label_15
switch_block_ev_doplat_case_4:
mov         ax, cx
xor         dx, dx
mov         word ptr ds:[bx + 2], PLATSPEED * 8
call        P_FindHighestOrLowestFloorSurrounding_
mov         word ptr ds:[bx + 4], ax
cmp         ax, word ptr [bp - 6]
jle         label_19
mov         ax, word ptr [bp - 6]
mov         word ptr ds:[bx + 4], ax
label_19:
mov         ax, word ptr [bp - 6]
mov         byte ptr ds:[si + 8], PLATWAIT * 35
mov         dx, SFX_PSTART
mov         word ptr ds:[si + 6], ax
mov         ax, cx
mov         byte ptr ds:[si + PLAT_T.plat_status], 1
jmp         label_15

ENDP

PROC    EV_PlatFunc_ NEAR
PUBLIC  EV_PlatFunc_ 

push        bx
push        cx
push        si
push        bp
mov         bp, sp
sub         sp, 2
mov         byte ptr [bp - 2], al
mov         ch, dl
xor         cl, cl
label_22:
mov         al, cl
cbw        
mov         si, ax
add         si, ax
mov         ax, word ptr ds:[si + _activeplats]
test        ax, ax
je          label_20
imul        bx, ax, SIZEOF_THINKER_T
mov         al, byte ptr ds:[bx + _thinkerlist + t_data + PLAT_T.plat_tag]
cbw        
mov         dx, ax
mov         al, byte ptr [bp - 2]
xor         ah, ah
add         bx, (_thinkerlist + THINKER_T.t_data)
cmp         dx, ax
jne         label_20
test        ch, ch
jne         label_21
mov         al, byte ptr ds:[bx + PLAT_T.plat_status]
cmp         al, 3
jne         label_21
mov         byte ptr ds:[bx + PLAT_T.plat_oldstatus], al
mov         dx, TF_PLATRAISE_HIGHBITS
mov         ax, word ptr ds:[si + _activeplats]
call        P_UpdateThinkerFunc_
label_21:
cmp         ch, 1
jne         label_20
mov         al, byte ptr ds:[bx + PLAT_T.plat_status]
cmp         al, 3
je          label_20
mov         byte ptr ds:[bx + PLAT_T.plat_oldstatus], al
mov         al, cl
cbw        
mov         byte ptr ds:[bx + PLAT_T.plat_status], 3
mov         bx, ax
add         bx, ax
xor         dx, dx
mov         ax, word ptr ds:[bx + _activeplats]
call        P_UpdateThinkerFunc_
label_20:
inc         cl
cmp         cl, MAXPLATS
jl          label_22
LEAVE_MACRO       
pop         si
pop         cx
pop         bx
ret         

ENDP

PROC    P_AddActivePlat_ NEAR
PUBLIC  P_AddActivePlat_ 


push        bx
push        cx
push        dx
mov         cx, ax
xor         dl, dl
label_24:
mov         al, dl
cbw        
mov         bx, ax
add         bx, ax
cmp         word ptr ds:[bx + _activeplats], 0
je          label_23
inc         dl
cmp         dl, MAXPLATS
jl          label_24
pop         dx
pop         cx
pop         bx
ret         
label_23:
mov         word ptr ds:[bx + _activeplats], cx
pop         dx
pop         cx
pop         bx
ret         


ENDP

PROC    P_RemoveActivePlat_ NEAR
PUBLIC  P_RemoveActivePlat_ 


push        bx
push        dx
mov         bx, _activeplats
loop_look_for_empty_platslot_removeactiveplat:
cmp         ax, word ptr ds:[bx]
je          found_plat_to_remove
inc         bx
inc         bx
cmp         bx, (_activeplats + MAXPLATS * 2)
jl          loop_look_for_empty_platslot_removeactiveplat
jmp         exit_removeactiveplat
found_plat_to_remove:

push        bx  ; store activeplats[bx] ptr
xchg        ax, bx  ; bx gets platref
mov         ax, SIZEOF_THINKER_T
mul         bx ; dx zeroed.
xchg        ax, bx  ; bx gets ptr. ax gets platref back. dx is zeroed from mul

mov         bx, word ptr [bx + _thinkerlist + THINKER_T.t_data + PLAT_T.plat_secnum]
SHIFT_MACRO shl         bx 4

call        P_RemoveThinker_

mov         word ptr [bx + _sectors_physics + SECTOR_PHYSICS_T.secp_specialdataRef], dx ; 0
pop         bx
mov         word ptr [bx], dx ; 0

exit_removeactiveplat:
pop         dx
pop         bx
ret  

ENDP


PROC    P_PLATS_ENDMARKER_ NEAR
PUBLIC  P_PLATS_ENDMARKER_
ENDP


END
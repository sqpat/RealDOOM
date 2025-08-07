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
EXTRN P_FindMinSurroundingLight_:NEAR
EXTRN P_FindSectorsFromLineTag_:NEAR
EXTRN P_FindNextHighestFloor_:NEAR
EXTRN P_CreateThinker_:FAR
EXTRN T_MovePlaneFloorUp_:NEAR
EXTRN T_MovePlaneFloorDown_:NEAR
EXTRN P_Random_:NEAR
EXTRN P_UpdateThinkerFunc_:NEAR


.DATA


.CODE



PROC    P_LIGHTS_STARTMARKER_ NEAR
PUBLIC  P_LIGHTS_STARTMARKER_
ENDP


PROC    T_FireFlicker_ NEAR
PUBLIC  T_FireFlicker_ 



push  bx

xchg  ax, bx
dec   word ptr ds:[bx + FIREFLICKER_T.fireflicker_count]
jnz   exit_t_fireflicker_early
call  P_Random_
and   al, 3
SHIFT_MACRO sal ax 4
mov   word ptr ds:[bx + FIREFLICKER_T.fireflicker_count], 4
mov   es, word ptr ds:[_SECTORS_SEGMENT_PTR]
mov   dx, word ptr ds:[bx + FIREFLICKER_T.fireflicker_secnum]
SHIFT_MACRO sal dx 4
mov   ah, byte ptr ds:[bx + FIREFLICKER_T.fireflicker_maxlight]
mov   bl, byte ptr ds:[bx + FIREFLICKER_T.fireflicker_minlight]
xchg  dx, bx

;	if (sectors[flicksecnum].lightlevel - amount < flickminlight)
;		sectors[flicksecnum].lightlevel = flickminlight;
;	else
;		sectors[flicksecnum].lightlevel = flickmaxlight - amount;

mov   dh, byte ptr es:[bx + SECTOR_T.sec_lightlevel]

; al = amount
; ah = maxlight
; dl = minlight
; dh = lightlevel

sub   dh, al
cmp   dh, dl
jnl   set_max_minus_amount
mov   ah, dl
jmp   set_lightlevel_and_exit
set_max_minus_amount:
sub   ah, al


set_lightlevel_and_exit:
mov   byte ptr es:[bx + SECTOR_T.sec_lightlevel], ah
exit_t_fireflicker_early:
pop   bx
ret   

ENDP

PROC    P_SpawnFireFlicker_ NEAR
PUBLIC  P_SpawnFireFlicker_


push  bx
push  cx
push  dx
push  bp
mov   bp, sp
sub   sp, 4
mov   cx, ax
mov   dx, ax
mov   bx, SECTORS_SEGMENT
shl   dx, 4
mov   es, bx
mov   bx, dx
mov   word ptr [bp - 2], 0
add   bx, SECTOR_PHYSICS_T.secp_special
mov   word ptr [bp - 4], dx
mov   dl, byte ptr es:[bx]
mov   bx, word ptr [bp - 4]
add   bx, _sectors_physics + SECTOR_PHYSICS_T.secp_special
mov   ax, TF_FIREFLICKER_HIGHBITS
mov   byte ptr ds:[bx + FIREFLICKER_T.fireflicker_secnum], 0
call  P_CreateThinker_
mov   bx, ax
mov   ax, cx
mov   byte ptr ds:[bx + FIREFLICKER_T.fireflicker_maxlight], dl
xor   dh, dh
mov   word ptr ds:[bx + FIREFLICKER_T.fireflicker_secnum], cx
call  P_FindMinSurroundingLight_
add   al, 16
mov   word ptr ds:[bx + FIREFLICKER_T.fireflicker_count], 4
mov   byte ptr ds:[bx + FIREFLICKER_T.fireflicker_minlight], al
LEAVE_MACRO 
pop   dx
pop   cx
pop   bx
ret   


ENDP

PROC    T_LightFlash_ NEAR
PUBLIC  T_LightFlash_

push  bx
push  si
mov   bx, ax
mov   ah, byte ptr ds:[bx + LIGHTFLASH_T.lightflash_minlight]
mov   si, word ptr ds:[bx + LIGHTFLASH_T.lightflash_secnum]
mov   al, byte ptr ds:[bx + LIGHTFLASH_T.lightflash_maxlight]
dec   word ptr ds:[bx + LIGHTFLASH_T.lightflash_count]
jne   label_3
mov   dx, SECTORS_SEGMENT
shl   si, 4
mov   es, dx
add   si, SECTOR_T.sec_lightlevel
cmp   al, byte ptr es:[si]
jne   label_4
mov   byte ptr es:[si], ah
mov   al, byte ptr ds:[bx + LIGHTFLASH_T.lightflash_mintime]
label_5:
cbw  
mov   si, ax
call  P_Random_
xor   ah, ah
and   ax, si
inc   ax
mov   word ptr ds:[bx + LIGHTFLASH_T.lightflash_count], ax
label_3:
pop   si
pop   bx
ret   
label_4:
mov   byte ptr es:[si], al
mov   al, byte ptr ds:[bx + LIGHTFLASH_T.lightflash_maxtime]
jmp   label_5

ENDP


PROC    P_SpawnLightFlash_ NEAR
PUBLIC  P_SpawnLightFlash_

push  bx
push  cx
push  dx
push  bp
mov   bp, sp
sub   sp, 6
mov   cx, ax
mov   word ptr [bp - 4], 0
mov   dx, ax
mov   bx, SECTORS_SEGMENT
shl   dx, 4
mov   es, bx
mov   bx, dx
mov   word ptr [bp - 6], dx
mov   dl, byte ptr es:[bx + SECTOR_T.sec_lightlevel]
add   bx, SECTOR_T.sec_lightlevel
xor   dh, dh
mov   bx, word ptr [bp - 6]
mov   word ptr [bp - 2], dx
mov   byte ptr ds:[bx + _sectors_physics + SECTOR_PHYSICS_T.secp_special], dh
mov   dl, byte ptr [bp - 2]
call  P_FindMinSurroundingLight_
mov   dl, al
mov   ax, TF_LIGHTFLASH_HIGHBITS
add   bx, _sectors_physics + SECTOR_PHYSICS_T.secp_special

call  P_CreateThinker_
mov   bx, ax
mov   byte ptr ds:[bx + LIGHTFLASH_T.lightflash_maxtime], 64
mov   byte ptr ds:[bx + LIGHTFLASH_T.lightflash_mintime], 7  ; todo double check
mov   word ptr ds:[bx + LIGHTFLASH_T.lightflash_secnum], cx
mov   dh, byte ptr [bp - 2]
mov   al, byte ptr ds:[bx + LIGHTFLASH_T.lightflash_maxtime]
mov   byte ptr ds:[bx + LIGHTFLASH_T.lightflash_maxlight], dh
cbw  
mov   byte ptr ds:[bx + LIGHTFLASH_T.lightflash_minlight], dl
mov   cx, ax
call  P_Random_
mov   dl, al
xor   dh, dh
and   dl, cl
inc   dx
mov   word ptr ds:[bx + LIGHTFLASH_T.lightflash_count], dx
LEAVE_MACRO 
pop   dx
pop   cx
pop   bx
ret   

ENDP


PROC    T_StrobeFlash_ NEAR
PUBLIC  T_StrobeFlash_


push  bx
push  si
mov   bx, ax
dec   word ptr ds:[bx + STROBE_T.strobe_count]
jne   label_6
mov   si, word ptr ds:[bx + STROBE_T.strobe_secnum]
mov   ax, SECTORS_SEGMENT
shl   si, 4
mov   es, ax
mov   al, byte ptr es:[si + SECTOR_T.sec_lightlevel]
add   si, SECTOR_T.sec_lightlevel
cmp   al, byte ptr ds:[bx + STROBE_T.strobe_maxlight]
jne   label_7
mov   al, byte ptr ds:[bx + STROBE_T.strobe_minlight]
mov   byte ptr es:[si], al
mov   si, word ptr ds:[bx + STROBE_T.strobe_brighttime]
mov   word ptr ds:[bx + 2], si
label_6:
pop   si
pop   bx
ret   
label_7:
mov   al, byte ptr ds:[bx + STROBE_T.strobe_maxlight]
mov   byte ptr es:[si], al
mov   si, word ptr ds:[bx + STROBE_T.strobe_darktime]
mov   word ptr ds:[bx + STROBE_T.strobe_count], si
pop   si
pop   bx
ret   

ENDP


PROC    P_SpawnStrobeFlash_ NEAR
PUBLIC  P_SpawnStrobeFlash_

push  cx
push  si
push  di
push  bp
mov   bp, sp
sub   sp, 6
mov   cx, ax
mov   word ptr [bp - 2], dx
mov   di, bx
mov   dx, ax
mov   bx, SECTORS_SEGMENT
shl   dx, 4
mov   es, bx
mov   bx, dx
mov   word ptr [bp - 4], 0
add   bx, SECTOR_T.sec_lightlevel
mov   word ptr [bp - 6], dx
mov   dl, byte ptr es:[bx]
mov   bx, word ptr [bp - 6]
add   bx, _sectors_physics + SECTOR_PHYSICS_T.secp_special
mov   ax, TF_STROBEFLASH_HIGHBITS
mov   byte ptr ds:[bx + STROBE_T.strobe_secnum], 0

call  P_CreateThinker_
mov   bx, ax
mov   si, ax
mov   word ptr ds:[bx + STROBE_T.strobe_brighttime], 5
mov   ax, word ptr [bp - 2]
mov   byte ptr ds:[bx + STROBE_T.strobe_minlight], dl
xor   dh, dh
mov   word ptr ds:[bx + STROBE_T.strobe_darktime], ax
mov   ax, cx
mov   word ptr ds:[bx + STROBE_T.strobe_secnum], cx
call  P_FindMinSurroundingLight_
mov   byte ptr ds:[bx + STROBE_T.strobe_maxlight], al
cmp   al, byte ptr ds:[bx + STROBE_T.strobe_minlight]
je    label_8
label_10:
test  di, di
je    label_9
mov   word ptr ds:[si + STROBE_T.strobe_count], 1
LEAVE_MACRO 
pop   di
pop   si
pop   cx
ret   
label_8:
mov   byte ptr ds:[bx + STROBE_T.strobe_maxlight], 0
jmp   label_10
label_9:
call  P_Random_
mov   dl, al
and   dl, 7
xor   dh, dh
inc   dx
mov   word ptr ds:[si + STROBE_T.strobe_count], dx
LEAVE_MACRO 
pop   di
pop   si
pop   cx
ret   

ENDP


PROC    EV_StartLightStrobing_ NEAR
PUBLIC  EV_StartLightStrobing_

push  bx
push  dx
push  si
push  bp
mov   bp, sp
sub   sp, 0200h
lea   dx, [bp - 0200h]
cbw  
xor   bx, bx
call  P_CreateThinker_
xor   si, si
cmp   word ptr [bp - 0200h], 0
jl    exit_evstartlightstrobing
label_11:
mov   dx, SLOWDARK
mov   ax, word ptr [bp + si - 0200h]
xor   bx, bx
add   si, 2
call  P_SpawnStrobeFlash_
cmp   word ptr [bp + si - 0200h], 0
jge   label_11
exit_evstartlightstrobing:
LEAVE_MACRO 
pop   si
pop   dx
pop   bx
ret   

ENDP


PROC    EV_LightChange_ NEAR
PUBLIC  EV_LightChange_

push  cx
push  si
push  di
push  bp
mov   bp, sp
sub   sp, 0406h
mov   ch, dl
mov   cl, bl
mov   bx, 1
lea   dx, [bp - 0406h]
cbw  
mov   word ptr [bp - 4], 0
call  P_FindSectorsFromLineTag_
cmp   word ptr [bp - 0406h], 0
jge   label_12
jmp   exit_ev_lightchange
label_12:
mov   si, word ptr [bp - 4]
mov   ax, word ptr [bp + si - 0406h]
mov   word ptr [bp - 6], ax
shl   ax, 4
mov   dx, SECTORS_SEGMENT
mov   bx, ax
mov   es, dx
add   bx, SECTOR_T.sec_linecount
add   word ptr [bp - 4], 2
mov   dx, word ptr es:[bx]
mov   bx, ax
mov   word ptr [bp - 2], dx
mov   dl, byte ptr es:[bx + SECTOR_T.sec_lightlevel]
add   bx, SECTOR_T.sec_lightlevel
test  ch, ch
jne   label_13
label_19:
xor   ax, ax
cmp   word ptr [bp - 2], 0
jle   label_14
xor   si, si
label_17:
mov   bx, word ptr [bp + si - 0206h]
shl   bx, 4
test  ch, ch
je    label_15
mov   di, SECTORS_SEGMENT
add   bx, SECTOR_T.sec_lightlevel
mov   es, di
cmp   cl, byte ptr es:[bx]
jae   label_16
mov   cl, byte ptr es:[bx]
label_16:
inc   ax
add   si, 2
cmp   ax, word ptr [bp - 2]
jl    label_17
label_14:
mov   ax, word ptr [bp - 6]
shl   ax, 4
test  ch, ch
je    label_18
mov   dx, SECTORS_SEGMENT
mov   bx, ax
mov   es, dx
add   bx, SECTOR_T.sec_lightlevel
mov   byte ptr es:[bx], cl
label_20:
mov   si, word ptr [bp - 4]
cmp   word ptr [bp + si - 0406h], 0
jge   label_12
exit_ev_lightchange:
LEAVE_MACRO 
pop   di
pop   si
pop   cx
ret   
label_13:
test  cl, cl
je    label_19
jmp   label_14
label_15:
mov   di, SECTORS_SEGMENT
add   bx, SECTOR_T.sec_lightlevel
mov   es, di
cmp   dl, byte ptr es:[bx]
jbe   label_16
mov   dl, byte ptr es:[bx]
jmp   label_16
label_18:
mov   bx, SECTORS_SEGMENT
mov   es, bx
mov   bx, ax
mov   byte ptr es:[bx + SECTOR_T.sec_lightlevel], dl
add   bx, SECTOR_T.sec_lightlevel
jmp   label_20

ENDP


PROC    T_Glow_ NEAR
PUBLIC  T_Glow_

push  bx
push  si
mov   bx, ax
mov   ax, word ptr ds:[bx + GLOW_T.glow_secnum]
mov   dl, byte ptr ds:[bx + GLOW_T.glow_maxlight]
mov   si, word ptr ds:[bx + GLOW_T.glow_direction]
shl   ax, 4
mov   dh, byte ptr ds:[bx + GLOW_T.glow_minlight]
cmp   si, -1
je    label_21
cmp   si, 1
jne   exit_tglow
mov   si, SECTORS_SEGMENT
mov   es, si
mov   si, ax
add   si, SECTOR_T.sec_lightlevel
add   byte ptr es:[si], 8
cmp   dh, byte ptr es:[si]
jbe   label_22
exit_tglow:
pop   si
pop   bx
ret   
label_21:
mov   si, SECTORS_SEGMENT
mov   es, si
mov   si, ax
add   si, SECTOR_T.sec_lightlevel
sub   byte ptr es:[si], 8
cmp   dl, byte ptr es:[si]
jb    exit_tglow
add   byte ptr es:[si], 8
mov   word ptr ds:[bx + GLOW_T.glow_direction], 1
pop   si
pop   bx
ret   
label_22:
sub   byte ptr es:[si], 8
mov   word ptr ds:[bx + GLOW_T.glow_direction], -1
pop   si
pop   bx
ret   


ENDP


PROC    P_SpawnGlowingLight_ NEAR
PUBLIC  P_SpawnGlowingLight_

push  bx
push  cx
push  dx
push  bp
mov   bp, sp
sub   sp, 6
mov   cx, ax
mov   word ptr [bp - 4], 0
mov   bx, SECTORS_SEGMENT
mov   dx, ax
mov   ax, TF_GLOW_HIGHBITS
shl   dx, 4
mov   es, bx
mov   bx, dx
mov   word ptr [bp - 6], dx
mov   dl, byte ptr es:[bx + SECTOR_PHYSICS_T.secp_special]
add   bx, SECTOR_PHYSICS_T.secp_special
xor   dh, dh
mov   bx, word ptr [bp - 6]
mov   word ptr [bp - 2], dx
mov   byte ptr ds:[bx + _sectors_physics + SECTOR_PHYSICS_T.secp_special], dh
add   bx, _sectors_physics + SECTOR_PHYSICS_T.secp_special
call  P_CreateThinker_
mov   dl, byte ptr [bp - 2]
mov   bx, ax
mov   ax, cx
mov   word ptr ds:[bx + GLOW_T.glow_secnum], cx
call  P_FindMinSurroundingLight_
mov   word ptr ds:[bx + GLOW_T.glow_direction], -1
mov   byte ptr ds:[bx + GLOW_T.glow_maxlight], al
mov   al, byte ptr [bp - 2]
mov   byte ptr ds:[bx + GLOW_T.glow_minlight], al
LEAVE_MACRO 
pop   dx
pop   cx
pop   bx
ret   

ENDP


PROC    P_LIGHTS_ENDMARKER_ NEAR
PUBLIC  P_LIGHTS_ENDMARKER_
ENDP

END

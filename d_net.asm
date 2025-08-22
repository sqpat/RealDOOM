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


EXTRN G_BuildTiccmd_:NEAR
EXTRN D_ProcessEvents_: NEAR
EXTRN I_StartTic_: NEAR
EXTRN M_Ticker_:NEAR
EXTRN G_Ticker_:NEAR
EXTRN D_DoAdvanceDemo_:NEAR
.DATA

EXTRN _gametime:DWORD
EXTRN _maketic:DWORD
EXTRN _oldentertics:WORD

.CODE



PROC    D_NET_STARTMARKER_ NEAR
PUBLIC  D_NET_STARTMARKER_
ENDP




PROC    NetUpdate_ FAR
PUBLIC  NetUpdate_

push  bx
push  cx
push  dx
push  si
mov   bx, _ticcount
mov   ax, word ptr ds:[bx]
mov   dx, word ptr ds:[bx + 2]
mov   cx, ax
sub   cx, word ptr ds:[_gametime + 0]
test  cx, cx
jle   exit_net_update
mov   word ptr ds:[_gametime + 0], ax
mov   word ptr ds:[_gametime + 2], dx
xor   bx, bx
test  cx, cx
jle   exit_net_update
mov   si, _gametic
label_2:
call  I_StartTic_
call  D_ProcessEvents_
mov   dx, word ptr ds:[_maketic + 0]
mov   ax, word ptr ds:[_maketic + 2]
sub   dx, word ptr ds:[si]
sbb   ax, word ptr ds:[si + 2]
test  ax, ax
jg    exit_net_update
jne   label_1
cmp   dx, 7
jb    label_1
exit_net_update:
pop   si
pop   dx
pop   cx
pop   bx
retf  
label_1:
mov   al, byte ptr ds:[_maketic + 0]
and   al, 0Fh
cbw  
call  G_BuildTiccmd_
add   word ptr ds:[_maketic + 0], 1
adc   word ptr ds:[_maketic + 2], 0
inc   bx
cmp   bx, cx
jl    label_2
pop   si
pop   dx
pop   cx
pop   bx
retf  

ENDP


PROC    TryRunTics_ NEAR
PUBLIC  TryRunTics_


push  bx
push  dx
push  si
push  bp
mov   bp, sp
sub   sp, 2
mov   bx, _ticcount
mov   ax, word ptr ds:[bx]
mov   si, _gametic
mov   dx, ax
mov   word ptr ds:[bp - 2], ax
sub   dx, word ptr ds:[_oldentertics]
mov   word ptr ds:[_oldentertics], ax

call  NetUpdate_
mov   ax, dx
mov   bx, word ptr ds:[_maketic + 0]
inc   ax
sub   bx, word ptr ds:[si]
cmp   ax, bx
jge   label_3
mov   bx, ax
label_10:
cmp   bx, 1
jl    label_4
label_11:
mov   ax, bx
mov   si, _gametic
cwd
add   ax, word ptr ds:[si]
mov   si, word ptr ds:[si + 2]
adc   si, dx
cmp   si, word ptr ds:[_maketic + 2]
jg    label_5
jne   label_6
cmp   ax, word ptr ds:[_maketic + 0]
ja    label_5
label_6:
mov   dx, _gametic
label_9:
dec   bx
cmp   bx, -1
je    exit_tryruntics
mov   si, _advancedemo
cmp   byte ptr ds:[si], 0
jne   label_7
label_8:
mov   si, dx
call  M_Ticker_
call  G_Ticker_
add   word ptr ds:[si], 1
adc   word ptr ds:[si + 2], 0

call  NetUpdate_
jmp   label_9
label_3:
cmp   dx, bx
jge   label_10
mov   bx, dx
jmp   label_10
label_4:
mov   bx, 1
jmp   label_11
label_5:

call  NetUpdate_
mov   si, _ticcount
xor   ax, ax
mov   dx, word ptr ds:[si]
sub   dx, word ptr ds:[bp - 2]
mov   si, word ptr ds:[si + 2]
sbb   si, ax
test  si, si
ja    label_12
jne   label_11
cmp   dx, 20
jb    label_11
label_12:
call  M_Ticker_
exit_tryruntics:
leave 
pop   si
pop   dx
pop   bx
ret   
label_7:
call  D_DoAdvanceDemo_
jmp   label_8

ENDP

PROC    D_NET_ENDMARKER_ NEAR
PUBLIC  D_NET_ENDMARKER_
ENDP


END
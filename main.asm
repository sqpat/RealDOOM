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


EXTRN _all_cheats:WORD


.CODE



; Called in st_stuff module, which handles the input.
; Returns a 1 if the cheat was successful, 0 if failed.


PROC cht_CheckCheat_ NEAR
PUBLIC cht_CheckCheat_


push bx
push si
mov  dh, dl
cbw 
mov  bx, ax
add  bx, ax
mov  bx, word ptr [bx + _all_cheats]
xor  dl, dl
cmp  word ptr [bx + 2], 0
je   label_1
label_7:
mov  si, word ptr [bx + 2]
mov  al, byte ptr [si]
test al, al
jne  label_2
lea  ax, [si + 1]
mov  word ptr [bx + 2], ax
mov  byte ptr [si], dh
label_5:
mov  si, word ptr [bx + 2]
mov  al, byte ptr [si]
cmp  al, 1
je   label_3
cmp  al, 0FFh
je   label_4
label_8:
mov  al, dl
pop  si
pop  bx
ret  
label_1:
mov  ax, word ptr [bx]
mov  word ptr [bx + 2], ax
jmp  label_7
label_2:
cmp  dh, al
jne  label_6
inc  si
mov  word ptr [bx + 2], si
jmp  label_5
label_6:
mov  ax, word ptr [bx]
mov  word ptr [bx + 2], ax
jmp  label_5
label_3:
inc  si
mov  word ptr [bx + 2], si
jmp  label_8
label_4:
mov  ax, word ptr [bx]
mov  dl, 1
mov  word ptr [bx + 2], ax
mov  al, dl
pop  si
pop  bx
ret  

 
ENDP


; get custom param for change level, change music type cheats.

PROC cht_GetParam_ NEAR
PUBLIC cht_GetParam_


push bx
push si
push di
mov  si, dx
cbw 
mov  bx, ax
add  bx, ax
mov  bx, word ptr [bx + _all_cheats]
mov  bx, word ptr [bx]
loop_find_param_marker:
mov  di, bx
inc  bx
cmp  byte ptr [di], 1       ; 1 is marker for custom params position in cheat
jne  loop_find_param_marker
check_next_cheat_char:
mov  al, byte ptr [bx]
mov  byte ptr [si], al
inc  si
mov  byte ptr [bx], 0
inc  bx
test al, al
je   end_of_custom_param
cmp  byte ptr [bx], 0FFh
jne  check_next_cheat_char
end_of_custom_param:
cmp  byte ptr [bx], 0FFh
je   getparam_return_0
getparam_return_1:
pop  di
pop  si
pop  bx
ret  
getparam_return_0:
mov  byte ptr [si], 0
pop  di
pop  si
pop  bx
ret  

ENDP




end
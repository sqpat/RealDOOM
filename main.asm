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



EXTRN _mousepresent:BYTE
EXTRN resetDS_:PROC
EXTRN I_ReadMouse_:PROC
EXTRN D_PostEvent_:PROC

.CODE


; ALL THE CHEAT DATA inlined here in CS rather than in DGROUP.

; Called in st_stuff module, which handles the input.
; Returns a 1 if the cheat was successful, 0 if failed.

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;;;;;;;;;;;;; CHEAT STRINGS ;;;;;;;;;;;;;;;;;;;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

cheat_mus_seq:
db "idmus", 1, 0, 0, 0FFh
cheat_choppers_seq:
db "idchoppers", 0FFh
cheat_god_seq:
db "iddqd", 0FFh
cheat_ammo_seq:
db "idkfa", 0FFh
cheat_ammonokey_seq:
db "idfa", 0FFh
; Smashing Pumpkins Into Samml Piles Of Putried Debris. 
cheat_noclip_seq:
db "idspispopd", 0FFh
cheat_commercial_noclip_seq:
db "idclip", 0FFh
cheat_powerup_seq0:
db "idbeholdv", 0FFh
cheat_powerup_seq1:
db "idbeholds", 0FFh
cheat_powerup_seq2:
db "idbeholdi", 0FFh
cheat_powerup_seq3:
db "idbeholdr", 0FFh
cheat_powerup_seq4:
db "idbeholda", 0FFh
cheat_powerup_seq5:
db "idbeholdl", 0FFh
cheat_powerup_seq6:
db "idbehold", 0FFh
cheat_clev_seq:
db "idclev", 1, 0, 0, 0FFh
cheat_mypos_seq:
db "idmypos", 0FFh
cheat_amap_seq:
db "iddt", 0FFh


;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;;;;;;;;;;;; CHEAT SEQUENCES ;;;;;;;;;;;;;;;;;;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;


BASE_CHEAT_ADDRESS:
cheat_powerup0:
dw  OFFSET cheat_powerup_seq0, 0
cheat_powerup1:
dw  OFFSET cheat_powerup_seq1, 0
cheat_powerup2:
dw  OFFSET cheat_powerup_seq2, 0
cheat_powerup3:
dw  OFFSET cheat_powerup_seq3, 0
cheat_powerup4:
dw  OFFSET cheat_powerup_seq4, 0
cheat_powerup5:
dw  OFFSET cheat_powerup_seq5, 0
cheat_powerup6:
dw  OFFSET cheat_powerup_seq6, 0

cheat_amap:
dw  OFFSET cheat_amap_seq, 0
cheat_mus:
dw  OFFSET cheat_mus_seq, 0
cheat_god:
dw  OFFSET cheat_god_seq, 0
cheat_ammo:
dw  OFFSET cheat_ammo_seq, 0
cheat_ammonokey:
dw  OFFSET cheat_ammonokey_seq, 0
cheat_noclip:
dw  OFFSET cheat_noclip_seq, 0
cheat_commercial_noclip:
dw  OFFSET cheat_commercial_noclip_seq, 0
cheat_choppers:
dw  OFFSET cheat_choppers_seq, 0
cheat_clev:
dw  OFFSET cheat_clev_seq, 0
cheat_mypos:
dw  OFFSET cheat_mypos_seq, 0


PROC cht_CheckCheat_ NEAR
PUBLIC cht_CheckCheat_


push bx
push si
 
; argument is preshifted by 2 (as the struct offset should be)
mov  bx, ax
add  bx, OFFSET BASE_CHEAT_ADDRESS
cmp  word ptr cs:[bx + 2], 0
je   initialize_cheat
cheat_initialized:
mov  si, word ptr cs:[bx + 2]   ; si stores p
mov  al, byte ptr cs:[si]
test al, al
jne  char_not_null
lea  ax, [si + 1]               ; advance p
mov  word ptr cs:[bx + 2], ax   ; store updated p ptr in cheat (should we just inc si?)
mov  byte ptr cs:[si], dl       ; store keypress
check_cheat_result:
mov  si, word ptr cs:[bx + 2]
mov  al, byte ptr cs:[si]
cmp  al, 1
je   reached_custom_param
cmp  al, 0FFh
je   reached_end_of_cheat
return_fail:
mov  al, 0
pop  si
pop  bx
ret  
initialize_cheat:
mov  ax, word ptr cs:[bx]
mov  word ptr cs:[bx + 2], ax   ; set p to start of cht
jmp  cheat_initialized
char_not_null:
cmp  dl, al
jne  char_not_match
; char match
inc  si
mov  word ptr cs:[bx + 2], si
jmp  check_cheat_result
char_not_match:
mov  ax, word ptr cs:[bx]       ; reset cheat ptr
mov  word ptr cs:[bx + 2], ax
jmp  check_cheat_result
reached_custom_param:
inc  si
mov  word ptr cs:[bx + 2], si
jmp  return_fail
reached_end_of_cheat:
; return success
mov  ax, word ptr cs:[bx]
mov  word ptr cs:[bx + 2], ax
mov  al, 1
pop  si
pop  bx
ret  

 
ENDP


; get custom param for change level, change music type cheats.

PROC cht_GetParam_ NEAR
PUBLIC cht_GetParam_

push bx
push di
mov  di, dx
 
; argument is preshifted by 2 (as the struct offset should be)
mov  bx, ax
add  bx, OFFSET BASE_CHEAT_ADDRESS
mov  bx, word ptr cs:[bx]        ; get str addr
loop_find_param_marker:
inc  bx
cmp  byte ptr cs:[bx-1], 1       ; 1 is marker for custom params position in cheat
jne  loop_find_param_marker

check_next_cheat_char:
mov  al, byte ptr cs:[bx]
mov  byte ptr ds:[di], al
inc  di
mov  byte ptr cs:[bx], 0
inc  bx
test al, al
je   end_of_custom_param
cmp  byte ptr cs:[bx], 0FFh
jne  check_next_cheat_char
end_of_custom_param:
cmp  byte ptr cs:[bx], 0FFh
je   getparam_return_0
getparam_return_1:
pop  di
pop  bx
ret  
getparam_return_0:
mov  byte ptr [di], 0
pop  di
pop  bx
ret  

ENDP
; 32 bytes
_keyboardque:
db 0, 0, 0, 0, 0, 0, 0, 0
db 0, 0, 0, 0, 0, 0, 0, 0
db 0, 0, 0, 0, 0, 0, 0, 0
db 0, 0, 0, 0, 0, 0, 0, 0
_kbdtail:
db 0
_kbdhead:
db 0


PROC I_KeyboardISR_  INTERRUPT
PUBLIC I_KeyboardISR_


push   bx
push   ax

in     al, 060h                     ; read kb
mov    bl, byte ptr cs:[_kbdhead]
and    bx, KBDQUESIZE - 1           ; wraparound keyboard queue
mov    byte ptr cs:[bx + _keyboardque], al
inc    byte ptr cs:[_kbdhead]
mov    al, 020h
out    KBDQUESIZE, al

pop    ax
pop    bx


iret   



ENDP

do_exit:
LEAVE_MACRO
pop     dx
pop     bx
ret
lshift_not_held:
cmp  ah, SC_RSHIFT
je   rshift_held
jmp  rshift_not_held

PROC I_StartTic_ NEAR
PUBLIC I_StartTic_

push bx
push dx
push bp
mov  bp, sp
sub  sp, 0Eh
; event is created at 0Eh and passed to D_PostEvent and stored in stack

cmp  byte ptr [_mousepresent], 0
je   no_mouse

call I_ReadMouse_

no_mouse:
loop_next_char:
mov  al, byte ptr cs:[_kbdtail]
cmp  al, byte ptr cs:[_kbdhead]
jae  do_exit
cmp  al, KBDQUESIZE
jbe  kbpos_ready
cmp  byte ptr cs:[_kbdhead], KBDQUESIZE
jbe  kbpos_ready
sub  al, KBDQUESIZE
sub  byte ptr cs:[_kbdhead], KBDQUESIZE
mov  byte ptr cs:[_kbdtail], al
kbpos_ready:
mov  bl, byte ptr cs:[_kbdtail]
and  bl, KBDQUESIZE - 1
xor  bh, bh
mov  al, byte ptr cs:[bx + _keyboardque]
mov  ah, al
and  ah, 07Fh                 ; some constant

;		// extended keyboard shift key bullshit


inc  byte ptr cs:[_kbdtail]
cmp  ah, SC_LSHIFT
jne  lshift_not_held
rshift_held:
mov  dl, byte ptr cs:[_kbdtail]
xor  dh, dh
mov  bx, dx
sub  bx, 2
and  bx, KBDQUESIZE - 1
cmp  byte ptr cs:[bx + _keyboardque], 0E0h   ; special / pause keys
je   loop_next_char
and  al, 080h       ; keyup/down
or   al, SC_RSHIFT
rshift_not_held:
cmp  al, 0E0h       ; special/pause keys
je   loop_next_char
mov  dl, byte ptr cs:[_kbdtail]
xor  dh, dh
mov  bx, dx
sub  bx, 2
xor  bh, bh
and  bl, KBDQUESIZE - 1
cmp  byte ptr cs:[bx + _keyboardque], 0E1h   ; pause key bullshit
je   loop_next_char
cmp  al, 0C5h                            ; dunno
jne  not_c5_press
cmp  byte ptr cs:[bx + _keyboardque], 09Dh
je   is_9D_press
not_c5_press:
test al, 080h   ; keyup/down
je   is_keydown
mov  byte ptr [bp - 0Eh], 1
check_pressed_key:
and  al, 07Fh                            ; keycode
mov  dl, al
cmp  dl, SC_UPARROW
je   case_uparrow
cmp  dl, SC_DOWNARROW
je   case_downarrow
cmp  dl, SC_RIGHTARROW
je   case_rightarrow
cmp  dl, SC_LEFTARROW
je   case_leftarrow
default_case_key:
mov  dx, SCANTOKEY_SEGMENT
xor  ah, ah
mov  es, dx
mov  bx, ax
mov  dl, byte ptr es:[bx]
xor  al, al
xor  dh, dh
mov  word ptr [bp - 0Bh], ax
mov  word ptr [bp - 0Dh], dx
lea  ax, [bp - 0Eh]
mov  dx, ds
call D_PostEvent_
jmp  loop_next_char
case_uparrow:
mov  word ptr [bp - 0Dh], KEY_UPARROW
key_selected:
mov  word ptr [bp - 0Bh], 0
lea  ax, [bp - 0Eh]
mov  dx, ds
call D_PostEvent_
jmp  loop_next_char
is_9D_press:
mov  word ptr [bp - 0Dh], KEY_PAUSE
lea  ax, [bp - 0Eh]
mov  byte ptr [bp - 0Eh], dh
mov  dx, ds
mov  word ptr [bp - 0Bh], 0
call D_PostEvent_
jmp  loop_next_char
is_keydown:
mov  byte ptr [bp - 0Eh], 0
jmp  check_pressed_key
case_downarrow:
mov  word ptr [bp - 0Dh], KEY_DOWNARROW
jmp  key_selected
case_leftarrow:
mov  word ptr [bp - 0Dh], KEY_LEFTARROW
jmp  key_selected
case_rightarrow:
mov  word ptr [bp - 0Dh], KEY_RIGHTARROW
jmp  key_selected



ENDP



end
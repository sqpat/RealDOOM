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
EXTRN _localcmds:WORD
EXTRN _gamekeydown:BYTE
EXTRN _key_strafe:BYTE
EXTRN _key_straferight:BYTE
EXTRN _key_strafeleft:BYTE
EXTRN _key_speed:BYTE
EXTRN _key_right:BYTE
EXTRN _key_left:BYTE
EXTRN _key_up:BYTE
EXTRN _key_down:BYTE
EXTRN _key_fire:BYTE
EXTRN _key_use:BYTE
EXTRN _dclicks:WORD
EXTRN _dclicks2:WORD
EXTRN _dclicktime:WORD
EXTRN _dclicktime2:WORD
EXTRN _dclickstate:WORD
EXTRN _dclickstate2:WORD
EXTRN _mousebforward:BYTE
EXTRN _mousebstrafe:BYTE
EXTRN _mousebuttons:BYTE
EXTRN _mousebfire:BYTE
EXTRN _mousex:BYTE
EXTRN _turnheld:BYTE
EXTRN _sidemove:BYTE
EXTRN _angleturn:WORD
EXTRN _forwardmove:WORD
EXTRN _savegameslot:BYTE
EXTRN _sendsave:BYTE
EXTRN _sendpause:BYTE

EXTRN _sendsave:BYTE
EXTRN _sendsave:BYTE
EXTRN _sendsave:BYTE



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


PROC G_BuildTiccmd_ NEAR
PUBLIC G_BuildTiccmd_

; bp - 2      strafe


push      bx
push      cx
push      dx
push      si
push      di
push      bp
mov       bp, sp
sub       sp, 8
cbw      
mov       si, OFFSET _localcmds
shl       ax, 3
add       si, ax
mov       di, si
xor       ax, ax

push      ds
pop       es
mov       cx, 4
rep       stosw 


mov       bl, byte ptr [_key_strafe]
xor       bh, bh
cmp       byte ptr [bx + _gamekeydown], 0
jne       strafe_is_on

mov       al, byte ptr [_mousebstrafe]
mov       bx, word ptr [_mousebuttons]
xor       ah, ah
add       bx, ax
mov       al, byte ptr [bx]
test      al, al
je        strafe_is_not_on
strafe_is_on:
mov       al, 1
strafe_is_not_on:
mov       bl, byte ptr [_key_speed]
mov       byte ptr [bp - 2], al
xor       cx, cx
xor       di, di
xor       bh, bh
mov       word ptr [bp - 4], cx
mov       dh, byte ptr [bx + _gamekeydown]
mov       bl, byte ptr [_key_right]
mov       word ptr [bp - 6], cx
cmp       byte ptr [bx + _gamekeydown], 0
jne       turn_is_held

mov       bl, byte ptr [_key_left]
mov       al, byte ptr [bx + _gamekeydown]
test      al, al
jne       turn_is_held
mov       byte ptr [_turnheld], al
jmp       finished_checking_turn

turn_is_held:
inc       byte ptr [_turnheld]
cmp       byte ptr [_turnheld], 6            ; todo SLOWTURNTICS
jl        finished_checking_turn
mov       dl, dh
jmp       check_strafe
finished_checking_turn:
mov       dl, 2
check_strafe:
; let movement keys cancel each other out

cmp       byte ptr [bp - 2], 0
jne       handle_strafe
handle_no_strafe:
mov       bl, byte ptr [_key_right]
xor       bh, bh
cmp       byte ptr [bx + _gamekeydown], 0
je        handle_checking_left_turn
handle_right_turn:
mov       al, dl
cbw      
mov       bx, ax
add       bx, ax
mov       ax, word ptr [bx + _angleturn]
sub       word ptr [si + 2], ax
handle_checking_left_turn:
mov       bl, byte ptr [_key_left]
xor       bh, bh
cmp       byte ptr [bx + _gamekeydown], 0
je        done_handling_strafe
handle_left_turn:
mov       al, dl
cbw      
mov       bx, ax
add       bx, ax
mov       ax, word ptr [bx + _angleturn]
add       word ptr [si + 2], ax
jmp       done_handling_strafe

handle_strafe:
mov       bl, byte ptr [_key_right]
xor       bh, bh
cmp       byte ptr [bx + _gamekeydown], 0
je        handle_checking_strafe_left
handle_strafe_right:
mov       al, dh
cbw      
mov       bx, ax
shl       bx, 2
add       cx, word ptr [bx + _sidemove]
adc       di, word ptr [bx + _sidemove+2]
handle_checking_strafe_left:
mov       bl, byte ptr [_key_left]
xor       bh, bh
cmp       byte ptr [bx + _gamekeydown], 0
je        done_handling_strafe
handle_strafe_left:
mov       al, dh
cbw      
mov       bx, ax
shl       bx, 2
sub       cx, word ptr [bx + _sidemove]
sbb       di, word ptr [bx + _sidemove+2]
done_handling_strafe:
mov       bl, byte ptr [_key_up]
xor       bh, bh
cmp       byte ptr [bx + _gamekeydown], 0
je        up_not_pressed
up_pressed:
mov       al, dh
cbw      
mov       bx, ax
shl       bx, 2
mov       ax, word ptr [bx + _forwardmove]
add       word ptr [bp - 4], ax
mov       ax, word ptr [bx + _forwardmove+2]
adc       word ptr [bp - 6], ax
up_not_pressed:
mov       bl, byte ptr [_key_down]
xor       bh, bh
cmp       byte ptr [bx + _gamekeydown], 0
je        down_not_pressed
down_pressed:
mov       al, dh
cbw      
mov       bx, ax
shl       bx, 2
mov       ax, word ptr [bx + _forwardmove]
sub       word ptr [bp - 4], ax
mov       ax, word ptr [bx + _forwardmove+2]
sbb       word ptr [bp - 6], ax
down_not_pressed:
mov       bl, byte ptr [_key_straferight]
xor       bh, bh
cmp       byte ptr [bx + _gamekeydown], 0
je        straferight_not_pressed
straferight_pressed:
mov       al, dh
cbw      
mov       bx, ax
shl       bx, 2
add       cx, word ptr [bx + _sidemove]
adc       di, word ptr [bx + _sidemove+2]
straferight_not_pressed:
mov       bl, byte ptr [_key_strafeleft]
xor       bh, bh
cmp       byte ptr [bx + _gamekeydown], 0
je        strafeleft_not_pressed
strafeleft_pressed:
mov       al, dh
cbw      
mov       bx, ax
shl       bx, 2
sub       cx, word ptr [bx + _sidemove]
sbb       di, word ptr [bx + _sidemove]
strafeleft_not_pressed:
mov       bl, byte ptr [_key_fire]
xor       bh, bh
cmp       byte ptr [bx + _gamekeydown], 0
jne       fire_pressed
; check mouse fire
mov       al, byte ptr [_mousebfire]
mov       bx, word ptr [_mousebuttons]
xor       ah, ah
mov       word ptr [bp - 8], bx
mov       bx, ax
add       bx, word ptr [bp - 8]
cmp       byte ptr [bx], 0
je        done_handling_fire

fire_pressed:
or        byte ptr [si + 7], BT_ATTACK
done_handling_fire:
mov       bl, byte ptr [_key_use]
xor       bh, bh
cmp       byte ptr [bx + _gamekeydown], 0
jne       use_pressed

done_handling_use:
xor       dl, dl
loop_handle_weapon_swap:
mov       al, dl
cbw      
mov       bx, ax
cmp       byte ptr [bx + _gamekeydown+ 031h], 0          ; 031h is ascii '1'
jne       handle_weapon_change

inc       dl
cmp       dl, NUMWEAPONS - 1
jge       done_checking_weapons
jmp       loop_handle_weapon_swap
use_pressed:
xor       ax, ax
or        byte ptr [si + 7], BT_USE
mov       word ptr [_dclicks], ax
jmp       done_handling_use

handle_weapon_change:
mov       al, dl
or        byte ptr [si + 7], BT_CHANGE
shl       al, 1
shl       al, 1
shl       al, 1
or        byte ptr [si + 7], al
done_checking_weapons:
mov       al, byte ptr [_mousebforward]
mov       bx, word ptr [_mousebuttons]
xor       ah, ah
mov       word ptr [bp - 8], bx
mov       bx, ax
add       bx, word ptr [bp - 8]
cmp       byte ptr [bx], 0
je        mouse_forward_not_pressed
mov       al, dh
cbw      
mov       bx, ax
shl       bx, 1
shl       bx, 1
mov       ax, word ptr [bx + _forwardmove]
add       word ptr [bp - 4], ax
mov       ax, word ptr [bx + _forwardmove+2]
adc       word ptr [bp - 6], ax
mouse_forward_not_pressed:
mov       al, byte ptr [_mousebforward]
mov       bx, word ptr [_mousebuttons]
xor       ah, ah
add       bx, ax
mov       al, byte ptr [bx]
cbw      
cmp       ax, word ptr [_dclickstate]
jne       label_55
label_35:

inc       word ptr [_dclicktime]
cmp       word ptr [_dclicktime], 20
jng       label_34

xor       ax, ax
mov       word ptr [_dclicks], ax
mov       word ptr [_dclickstate], ax
jmp       label_34


label_55:
cmp       word ptr [_dclicktime], 1
jle       label_35
mov       word ptr [_dclickstate], ax
test      ax, ax
je        label_54
inc       word ptr [_dclicks]
label_54:
cmp       word ptr [_dclicks], 2
je        label_53

xor       ax, ax
mov       word ptr [_dclicktime], ax
jmp       label_34

label_53:
xor       ax, ax
or        byte ptr [si + 7], 2
mov       word ptr [_dclicks], ax
label_34:
mov       al, byte ptr [_mousebstrafe]
mov       bx, word ptr [_mousebuttons]
xor       ah, ah
add       bx, ax
mov       al, byte ptr [bx]
cbw      
cmp       ax, word ptr [_dclickstate2]
jne       label_29
label_30:
inc       word ptr [_dclicktime2]
cmp       word ptr [_dclicktime2], 20  
jg        label_31
jmp       label_40
label_31:
xor       ax, ax
mov       word ptr [_dclicks2], ax
mov       word ptr [_dclickstate2], ax
jmp       label_40
label_29:
cmp       word ptr [_dclicktime2], 1
jle       label_30
mov       word ptr [_dclickstate2], ax
test      ax, ax
je        label_28
inc       word ptr [_dclicks2]
label_28:
cmp       word ptr [_dclicks2], 2
je        label_27

xor       ax, ax
mov       word ptr [_dclicktime2], ax
jmp       label_40
label_23:
mov       ax, word ptr [_mousex]
shl       ax, 3
sub       word ptr [si + 2], ax
jmp       label_24

label_27:
xor       ax, ax
or        byte ptr [si + 7], 2
mov       word ptr [_dclicks2], ax
label_40:
cmp       byte ptr [bp - 2], 0
je        label_23
mov       ax, word ptr [_mousex]
add       ax, ax
cwd       
add       cx, ax
adc       di, dx
label_24:
xor       ax, ax
mov       word ptr [_mousex], ax
mov       ax, word ptr [bp - 6]
cmp       ax, word ptr [_forwardmove + 6]
jg        label_25
jne       label_71
mov       ax, word ptr [bp - 4]
cmp       ax, word ptr [_forwardmove + 4]
jbe       label_71
label_25:
mov       ax, word ptr [_forwardmove + 4]
label_7:
mov       word ptr [bp - 4], ax
label_21:
mov       ax, word ptr [_forwardmove + 6]
cmp       di, ax
jg        label_68
jne       label_8
cmp       cx, word ptr [_forwardmove + 4]
jbe       label_8
label_68:
mov       cx, word ptr [_forwardmove + 4]
label_12:
mov       al, byte ptr [bp - 4]
add       byte ptr [si + 1], cl
add       byte ptr [si], al
cmp       byte ptr [_sendpause], 0
je        label_59
mov       byte ptr [_sendpause], 0
mov       byte ptr [si + 7], 081h            ; todo BT_SPECIAL | BTS_PAUSE
label_59:
cmp       byte ptr [_sendsave], 0
jne       label_52
LEAVE_MACRO
pop       di
pop       si
pop       dx
pop       cx
pop       bx
ret       
label_71:
mov       dx, word ptr [_forwardmove + 6]
mov       ax, word ptr [_forwardmove + 4]
neg       dx
neg       ax
sbb       dx, 0
cmp       dx, word ptr [bp - 6]
jnle      label_7
je        label_60
jmp       label_21
label_60:
cmp       ax, word ptr [bp - 4]
jbe       label_21
jmp       label_7



label_52:
mov       al, byte ptr [_savegameslot]
shl       al, 2
or        al, 082h                       ; todo
mov       byte ptr [_sendsave], 0
mov       byte ptr [si + 7], al
LEAVE_MACRO     
pop       di
pop       si
pop       dx
pop       cx
pop       bx
ret       





label_8:
mov       dx, ax
mov       ax, word ptr [_forwardmove + 4]
neg       dx
neg       ax
sbb       dx, 0
cmp       di, dx
jl        label_9
je        label_10
jump_to_label_12:
jmp       label_12
label_10:
cmp       cx, ax
jae       jump_to_label_12
label_9:
mov       cx, ax
jmp       label_12

ENDP


end
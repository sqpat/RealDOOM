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



EXTRN resetDS_:PROC
EXTRN I_ReadMouse_:PROC
EXTRN D_PostEvent_:PROC
EXTRN M_CheckParm_:PROC
EXTRN fopen_:PROC
EXTRN fgetc_:PROC
EXTRN fclose_:PROC
EXTRN DEBUG_PRINT_:PROC
EXTRN locallib_strcmp_:PROC
EXTRN sscanf_uint8_:PROC

EXTRN _mousepresent:BYTE
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
EXTRN _forwardmove:WORD
EXTRN _savegameslot:BYTE
EXTRN _sendsave:BYTE
EXTRN _sendpause:BYTE

EXTRN _defaults:WORD
EXTRN _defaultfile:BYTE
EXTRN _myargc:WORD
EXTRN _myargv:BYTE



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




; todo not heavily optimized


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

;  ticcmd_t localcmds[BACKUPTICS];
;  8 bytes each, 16 entries


_localcmds:
dw 0, 0, 0, 0
dw 0, 0, 0, 0
dw 0, 0, 0, 0
dw 0, 0, 0, 0
dw 0, 0, 0, 0
dw 0, 0, 0, 0
dw 0, 0, 0, 0
dw 0, 0, 0, 0
dw 0, 0, 0, 0
dw 0, 0, 0, 0
dw 0, 0, 0, 0
dw 0, 0, 0, 0
dw 0, 0, 0, 0
dw 0, 0, 0, 0
dw 0, 0, 0, 0
dw 0, 0, 0, 0



PROC G_CopyCmd_  NEAR
PUBLIC G_CopyCmd_

    push    si
    push    di
    
    push    ds              ; es:di is player.cmd
    pop     es
    mov     di, ax

    push    cs              ; ds:si is _localcmds struct
    pop     ds

    xor     dh, dh
    mov     si, dx
    sal     si, 1
    sal     si, 1
    sal     si, 1      ; 8 bytes per
    add     si, OFFSET _localcmds

    movsw
    movsw
    movsw
    movsw   ; copy one cmd
    
    mov     ax, ss
    mov     ds, ax
    
    pop     di
    pop     si
    ret

ENDP


_gamekeydown:   ;  256 bytes.
db 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0
db 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0
db 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0
db 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0
db 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0
db 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0
db 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0
db 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0
db 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0
db 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0
db 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0
db 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0
db 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0
db 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0
db 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0
db 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0

_angleturn:
dw 640, 1280, 320


PROC G_ResetGameKeys_  NEAR
PUBLIC G_ResetGameKeys_

push cx
push di

push cs
pop  es

xor  ax, ax
mov  cx, 128
mov  di, OFFSET _gamekeydown

rep  stosw

pop  di
pop  cx
ret

ENDP

PROC G_SetGameKeyDown_  NEAR
PUBLIC G_SetGameKeyDown_

push bx
xor  ah, ah
mov  bx, ax
mov  byte ptr cs:[bx + _gamekeydown], 1
pop  bx
ret

ENDP

PROC G_SetGameKeyUp_  NEAR
PUBLIC G_SetGameKeyUp_

push bx
xor  ah, ah
mov  bx, ax
mov  byte ptr cs:[bx + _gamekeydown], 0
pop  bx
ret

ENDP


PROC G_GetGameKey_  NEAR
PUBLIC G_GetGameKey_

push bx
xor  ah, ah
mov  bx, ax
mov  al, byte ptr cs:[bx + _gamekeydown]
pop  bx
ret

ENDP


; todo not heavily optimized
PROC G_BuildTiccmd_ NEAR
PUBLIC G_BuildTiccmd_

; bp - 2      strafe
; bp - 4      forward lo
; bp - 6      forward hi


push      bx
push      cx
push      dx
push      si
push      di
push      bp
mov       bp, sp
sub       sp, 6
cbw      
mov       si, OFFSET _localcmds
shl       ax, 1
shl       ax, 1
shl       ax, 1
add       si, ax
mov       di, si
xor       ax, ax

push      cs
pop       es

stosw 
stosw 
stosw 
stosw 


mov       bl, byte ptr [_key_strafe]
xor       bh, bh
cmp       byte ptr cs:[bx + _gamekeydown], 0
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
xor       cx, cx        ; cx:di is sidemove?
xor       di, di
xor       bh, bh
mov       word ptr [bp - 4], cx
mov       dh, byte ptr cs:[bx + _gamekeydown]
mov       bl, byte ptr [_key_right]
mov       word ptr [bp - 6], cx
cmp       byte ptr cs:[bx + _gamekeydown], 0
jne       turn_is_held

mov       bl, byte ptr [_key_left]
mov       al, byte ptr cs:[bx + _gamekeydown]
test      al, al
jne       turn_is_held
mov       byte ptr [_turnheld], al
jmp       finished_checking_turn

turn_is_held:
inc       byte ptr [_turnheld]
cmp       byte ptr [_turnheld], SLOWTURNTICS
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
cmp       byte ptr cs:[bx + _gamekeydown], 0
je        handle_checking_left_turn
handle_right_turn:
mov       al, dl
cbw      
mov       bx, ax
add       bx, ax
mov       ax, word ptr cs:[bx + _angleturn]
sub       word ptr cs:[si + 2], ax
handle_checking_left_turn:
mov       bl, byte ptr [_key_left]
xor       bh, bh
cmp       byte ptr cs:[bx + _gamekeydown], 0
je        done_handling_strafe
handle_left_turn:
mov       al, dl
cbw      
mov       bx, ax
add       bx, ax
mov       ax, word ptr cs:[bx + _angleturn]
add       word ptr cs:[si + 2], ax
jmp       done_handling_strafe

handle_strafe:
mov       bl, byte ptr [_key_right]
xor       bh, bh
cmp       byte ptr cs:[bx + _gamekeydown], 0
je        handle_checking_strafe_left
handle_strafe_right:
mov       al, dh
cbw      
mov       bx, ax
shl       bx, 1
shl       bx, 1
add       cx, word ptr [bx + _sidemove]
adc       di, word ptr [bx + _sidemove+2]
handle_checking_strafe_left:
mov       bl, byte ptr [_key_left]
xor       bh, bh
cmp       byte ptr cs:[bx + _gamekeydown], 0
je        done_handling_strafe
handle_strafe_left:
mov       al, dh
cbw      
mov       bx, ax
shl       bx, 1
shl       bx, 1
sub       cx, word ptr [bx + _sidemove]
sbb       di, word ptr [bx + _sidemove+2]
done_handling_strafe:
mov       bl, byte ptr [_key_up]
xor       bh, bh
cmp       byte ptr cs:[bx + _gamekeydown], 0
je        up_not_pressed
up_pressed:
mov       al, dh
cbw      
mov       bx, ax
shl       bx, 1
shl       bx, 1
mov       ax, word ptr [bx + _forwardmove]
add       word ptr [bp - 4], ax
mov       ax, word ptr [bx + _forwardmove+2]
adc       word ptr [bp - 6], ax
up_not_pressed:
mov       bl, byte ptr [_key_down]
xor       bh, bh
cmp       byte ptr cs:[bx + _gamekeydown], 0
je        down_not_pressed
down_pressed:
mov       al, dh
cbw      
mov       bx, ax
shl       bx, 1
shl       bx, 1
mov       ax, word ptr [bx + _forwardmove]
sub       word ptr [bp - 4], ax
mov       ax, word ptr [bx + _forwardmove+2]
sbb       word ptr [bp - 6], ax
down_not_pressed:
mov       bl, byte ptr [_key_straferight]
xor       bh, bh
cmp       byte ptr cs:[bx + _gamekeydown], 0
je        straferight_not_pressed
straferight_pressed:
mov       al, dh
cbw      
mov       bx, ax
shl       bx, 1
shl       bx, 1
add       cx, word ptr [bx + _sidemove]
adc       di, word ptr [bx + _sidemove+2]
straferight_not_pressed:
mov       bl, byte ptr [_key_strafeleft]
xor       bh, bh
cmp       byte ptr cs:[bx + _gamekeydown], 0
je        strafeleft_not_pressed
strafeleft_pressed:
mov       al, dh
cbw      
mov       bx, ax
shl       bx, 1
shl       bx, 1
sub       cx, word ptr [bx + _sidemove]
sbb       di, word ptr [bx + _sidemove]
strafeleft_not_pressed:
mov       bl, byte ptr [_key_fire]
xor       bh, bh
cmp       byte ptr cs:[bx + _gamekeydown], 0
jne       fire_pressed
; check mouse fire
mov       al, byte ptr [_mousebfire]
mov       bx, word ptr [_mousebuttons]
xor       ah, ah
add       bx, ax
cmp       byte ptr [bx], 0
je        done_handling_fire

fire_pressed:
or        byte ptr cs:[si + 7], BT_ATTACK
done_handling_fire:
mov       bl, byte ptr [_key_use]
xor       bh, bh
cmp       byte ptr cs:[bx + _gamekeydown], 0
jne       use_pressed

done_handling_use:
xor       dl, dl
loop_handle_weapon_swap:
mov       al, dl
cbw      
mov       bx, ax
cmp       byte ptr cs:[bx + _gamekeydown+ 031h], 0          ; 031h is ascii '1'
jne       handle_weapon_change

inc       dl
cmp       dl, NUMWEAPONS - 1
jge       done_checking_weapons
jmp       loop_handle_weapon_swap
use_pressed:
xor       ax, ax
or        byte ptr cs:[si + 7], BT_USE
mov       word ptr [_dclicks], ax
jmp       done_handling_use

handle_weapon_change:
mov       al, dl
or        byte ptr cs:[si + 7], BT_CHANGE
shl       al, 1
shl       al, 1
shl       al, 1
or        byte ptr cs:[si + 7], al
done_checking_weapons:
mov       al, byte ptr [_mousebforward]
mov       bx, word ptr [_mousebuttons]
xor       ah, ah
add       bx, ax
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

; check mouse strafe double click?
mov       al, byte ptr [_mousebstrafe]
mov       bx, word ptr [_mousebuttons]
xor       ah, ah
add       bx, ax
mov       al, byte ptr [bx]
cbw      
cmp       ax, word ptr [_dclickstate2]
jne       strafe_clickstate_nonequal
handle_strafe_clickstate:
inc       word ptr [_dclicktime2]
cmp       word ptr [_dclicktime2], 20  
jng       done_handling_mouse_strafe
xor       ax, ax
mov       word ptr [_dclicks2], ax
mov       word ptr [_dclickstate2], ax
jmp       done_handling_mouse_strafe
strafe_clickstate_nonequal:
cmp       word ptr [_dclicktime2], 1
jle       handle_strafe_clickstate
mov       word ptr [_dclickstate2], ax
test      ax, ax
je        dont_increment_dclicks2
inc       word ptr [_dclicks2]
dont_increment_dclicks2:
cmp       word ptr [_dclicks2], 2
je        handle_double_click

xor       ax, ax
mov       word ptr [_dclicktime2], ax
jmp       done_handling_mouse_strafe
strafe_on_add_mousex:
mov       ax, word ptr [_mousex]
shl       ax, 1
shl       ax, 1
shl       ax, 1
sub       word ptr cs:[si + 2], ax
jmp       done_handling_mousex

handle_double_click:
xor       ax, ax
or        byte ptr cs:[si + 7], BT_USE
mov       word ptr [_dclicks2], ax

done_handling_mouse_strafe:
cmp       byte ptr [bp - 2], 0
je        strafe_on_add_mousex
; set angle turn
mov       ax, word ptr [_mousex]
add       ax, ax
cwd       
add       cx, ax
adc       di, dx
done_handling_mousex:

; limit move speed to max move (forward_move[1])

mov       word ptr [_mousex], 0
mov       ax, word ptr [bp - 6]
cmp       ax, word ptr [_forwardmove + 6]
jg        clip_forwardmove_to_max
jne       check_negative_max_forward
mov       ax, word ptr [bp - 4]
cmp       ax, word ptr [_forwardmove + 4]
jbe       check_negative_max_forward
clip_forwardmove_to_max:
mov       ax, word ptr [_forwardmove + 4]
overwrite_forwardmove:
mov       word ptr [bp - 4], ax
dont_overwrite_forwardmove:
mov       ax, word ptr [_forwardmove + 6]

; compare side to maxmove
cmp       di, ax
jg        clip_sidemove_to_max
jne       check_negative_max_side
cmp       cx, word ptr [_forwardmove + 4]
jbe       check_negative_max_side
clip_sidemove_to_max:
mov       cx, word ptr [_forwardmove + 4]
done_checking_sidemove:
; add sidemove/forwardmove to cmd
mov       al, byte ptr [bp - 4]
add       byte ptr cs:[si + 1], cl
add       byte ptr cs:[si], al
cmp       byte ptr [_sendpause], 0
je        dont_pause
mov       byte ptr [_sendpause], 0
mov       byte ptr cs:[si + 7], (BT_SPECIAL OR BTS_PAUSE) 
dont_pause:
cmp       byte ptr [_sendsave], 0
jne       handle_save_press
LEAVE_MACRO
pop       di
pop       si
pop       dx
pop       cx
pop       bx
ret       
check_negative_max_forward:
mov       dx, word ptr [_forwardmove + 6]
mov       ax, word ptr [_forwardmove + 4]
neg       dx
neg       ax
sbb       dx, 0
cmp       dx, word ptr [bp - 6]
jnle      overwrite_forwardmove
je        check_forwardmove_negative_lowbits
jmp       dont_overwrite_forwardmove
check_forwardmove_negative_lowbits:
cmp       ax, word ptr [bp - 4]
jbe       dont_overwrite_forwardmove
jmp       overwrite_forwardmove



handle_save_press:
mov       al, byte ptr [_savegameslot]
shl       al, 1
shl       al, 1 ;; BTS_SAVESHIFT
or        al, (BT_SPECIAL OR BTS_SAVEGAME)
mov       byte ptr [_sendsave], 0
mov       byte ptr cs:[si + 7], al
LEAVE_MACRO     
pop       di
pop       si
pop       dx
pop       cx
pop       bx
ret       


check_negative_max_side:
mov       dx, ax
mov       ax, word ptr [_forwardmove + 4]
neg       dx
neg       ax
sbb       dx, 0
cmp       di, dx
jl        clip_sidemove_to_negative_max
je        check_sidemove_negative_lowbits
jmp       done_checking_sidemove
check_sidemove_negative_lowbits:
cmp       cx, ax
jae       done_checking_sidemove
clip_sidemove_to_negative_max:
mov       cx, ax
jmp       done_checking_sidemove

ENDP


; copy string from cs:bx to ds:_filename_argument
; return _filename_argument in ax
; todo make use cs:si or something?

PROC CopyString13_ NEAR
PUBLIC CopyString13_

push  si
push  di
push  cx

mov   di, OFFSET _filename_argument

push  ds
pop   es    ; es = ds

push  cs
pop   ds    ; ds = cs

mov   si, ax

mov   ax, 0
stosw       ; zero out
stosw
stosw
stosw
stosw
stosw
stosb

mov  cx, 13
sub  di, cx

do_next_char:
lodsb
stosb
test  al, al
je    done_writing
loop do_next_char


done_writing:

mov   ax, OFFSET _filename_argument   ; ax now points to the near string

push  ss
pop   ds    ; restore ds

pop   cx
pop   di
pop   si

ret

ENDP




SIZEOF_DEFAULT_T = 7
NUM_DEFAULTS = 28

_str_config:
db "-config", 0
_str_default_file:
db "\tdefault file: %s\n", 0
_str_default_filename:
db "default.cfg", 0


PROC M_LoadDefaults_  FAR
PUBLIC M_LoadDefaults_

push  bx
push  cx
push  dx
push  si
push  di
push  bp
mov   bp, sp
sub   sp, 0AAh
sub   bp, 080h
xor   bx, bx


loop_set_default_values:
mov   si, word ptr [bx + _defaults + 2]
mov   al, byte ptr [bx + _defaults + 4]
add   bx, 7               ; 
mov   byte ptr [si], al
cmp   bx, NUM_DEFAULTS * SIZEOF_DEFAULT_T  ; c4, can be single byte check
jne   loop_set_default_values


mov   ax, OFFSET _str_config
call  CopyString13_


call  M_CheckParm_



test  ax, ax
je    set_default_defaultsfilename
mov   dx, word ptr [_myargc]
dec   dx
cmp   ax, dx
jge   set_default_defaultsfilename
mov   bx, word ptr [_myargv]
add   ax, ax
add   bx, ax
mov   ax, word ptr [bx + 2]   ; pointer to myargv for default filename
push  ax
mov   word ptr [_defaultfile], ax  ; store filename ptr

mov   ax, OFFSET _str_default_file
call  CopyString13_
push  ax

call  DEBUG_PRINT_
add   sp, 4

got_defaults_filename:



mov   dx, OFFSET _fopen_r_argument
mov   ax, word ptr [_defaultfile]
call  fopen_

mov   bx, ax
mov   word ptr [bp + 076h], ax
test  ax, ax
jne   defaults_file_loaded
; bad file
defaults_file_closed:
mov   dx, SCANTOKEY_SEGMENT
xor   bx, bx

loop_defaults_to_set_initial_values:
cmp   byte ptr [bx + _defaults + 5], 0
je    load_next_defaults_value
mov   si, word ptr [bx + _defaults + 2]
mov   al, byte ptr [si]
mov   byte ptr [bx + _defaults + 6], al
xor   ah, ah
mov   es, dx
mov   si, ax
mov   di, word ptr [bx + _defaults + 2]
mov   al, byte ptr es:[si]
mov   byte ptr [di], al
load_next_defaults_value:
add   bx, SIZEOF_DEFAULT_T
cmp   bx, NUM_DEFAULTS * SIZEOF_DEFAULT_T
jne   loop_defaults_to_set_initial_values

exit_mloaddefaults:
lea   sp, [bp + 080h]
pop   bp
pop   di
pop   si
pop   dx
pop   cx
pop   bx
retf  
set_default_defaultsfilename:

mov   ax, OFFSET _str_default_filename
call  CopyString13_

mov   word ptr [_defaultfile], ax
jmp   got_defaults_filename
defaults_file_loaded:


; bx is file pointer..
xor   al, al
;		int8_t readphase = 0; // getting param 0
;		int8_t defindex = 0;
;		int8_t strparmindex = 0;
mov   byte ptr [bp + 07Ah], al          ; readphase
mov   byte ptr [bp + 07Ch], al
mov   byte ptr [bp + 07Eh], al          ; strparmindex
test  byte ptr [bx + 6], 010h    ; check feof
jne   end_loop_close_file
handle_next_char:
mov   ax, word ptr [bp + 076h]
call  fgetc_
mov   dl, al
cmp   al, 020h                    ; space charcater
jne   not_space
is_tab_or_space:
mov   ah, 1
checked_for_tab_or_space:
; ah = 1 if whitespace.
; dl is copy of char...
cmp   dl, 0Ah                     ; line feed character \n
jne   not_linefeed
is_linefeed_or_carriage_return:
mov   al, 1
checked_for_endline:
; ah = 1 if whiteespace, al = 1 if newline
cmp   byte ptr [bp + 07Ah], 0       ; check readphase
jne   readphase_not_0
; readphase is 0
test  ah, ah
jne   readphase_0_whitespace_or_newline
test  al, al
jne   readphase_0_whitespace_or_newline
mov   al, byte ptr [bp + 07Ch]
cbw  
mov   si, ax
inc   byte ptr [bp + 07Ch]
mov   byte ptr [bp + si - 02Ah], dl
character_finished_handling:
mov   bx, word ptr [bp + 076h]
test  byte ptr [bx + 6], 010h        ; test feof
je    handle_next_char      
end_loop_close_file:
mov   ax, word ptr [bp + 076h]      ; retrieve FP
call  fclose_
jmp   defaults_file_closed
not_space:
cmp   al, 9                           ; tab characters \t
je    is_tab_or_space
xor   ah, ah
jmp   checked_for_tab_or_space
not_linefeed:
cmp   dl, 0Dh                         ; carriage return characters \r
je    is_linefeed_or_carriage_return
xor   al, al
jmp   checked_for_endline
readphase_0_whitespace_or_newline:
test  ah, ah
je    readphase_0_whitespace
mov   al, byte ptr [bp + 07Ch]
cbw  
mov   si, ax
mov   byte ptr [bp + 07Ah], 1
mov   byte ptr [bp + si - 02Ah], 0
jmp   character_finished_handling
readphase_0_whitespace:
mov   byte ptr [bp + 07Ah], ah
mov   byte ptr [bp + 07Ch], ah
mov   byte ptr [bp + 07Eh], ah
jmp   character_finished_handling
readphase_not_0:
cmp   byte ptr [bp + 07Ah], 1
jne   character_finished_handling
test  ah, ah
jne   character_finished_handling
test  al, al
jne   hit_newline
mov   al, byte ptr [bp + 07Eh]
cbw  
mov   si, ax
inc   byte ptr [bp + 07Eh]
mov   byte ptr [bp + si + 026h], dl
jmp   character_finished_handling
hit_newline:
mov   al, byte ptr [bp + 07Eh]      ; get strparmindex
cbw  
mov   si, ax
xor   al, al
mov   byte ptr [bp + 07Ah], al
mov   byte ptr [bp + 07Ch], al
mov   byte ptr [bp + si + 026h], al
cmp   byte ptr [bp + 07Eh], 0
je    character_finished_handling
; prepare to get param...
mov   byte ptr [bp + 07Eh], al
xor   di, di
lea   ax, [bp + 026h]
xor   si, si

call  sscanf_uint8_
mov   byte ptr [bp + 078h], al
scan_next_default_name_for_match:
lea   ax, [bp - 02Ah]
mov   cx, ds
mov   dx, ds
mov   bx, word ptr [si + _defaults]

call  locallib_strcmp_
test  ax, ax
jne   no_match_increment_default
mov   bx, word ptr [si + _defaults + 2]
mov   al, byte ptr [bp + 078h]
mov   byte ptr [bx], al
jmp   character_finished_handling
no_match_increment_default:
inc   di
add   si, SIZEOF_DEFAULT_T
cmp   di, NUM_DEFAULTS
jl    scan_next_default_name_for_match
jmp   character_finished_handling


ENDP


end
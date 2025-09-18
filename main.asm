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
INCLUDE defs.inc
INSTRUCTION_SET_MACRO


EXTRN ST_Drawer_:NEAR
EXTRN HU_Drawer_:NEAR
EXTRN HU_Erase_:NEAR
EXTRN R_ExecuteSetViewSize_:NEAR
EXTRN R_DrawViewBorder_:NEAR
EXTRN D_PageDrawer_:NEAR
EXTRN R_FillBackScreen_:NEAR
EXTRN NetUpdate_:FAR
EXTRN Z_QuickMapMenu_:FAR
EXTRN Z_QuickMapPhysics_:FAR
EXTRN Z_QuickMapIntermission_:FAR

EXTRN I_ReadMouse_:NEAR
EXTRN D_PostEvent_:NEAR
EXTRN M_CheckParm_:NEAR
EXTRN HU_Responder_:NEAR
EXTRN ST_Responder_:NEAR

EXTRN FastDiv3216u_:FAR
EXTRN Z_SetOverlay_:FAR
EXTRN fopen_:FAR
EXTRN fgetc_:FAR
EXTRN fputc_:FAR
EXTRN fclose_:FAR
;EXTRN locallib_putchar_:NEAR



EXTRN I_WaitVBL_:FAR
EXTRN Z_QuickMapPalette_:FAR
EXTRN Z_QuickMapByTaskNum_:FAR

EXTRN _R_RenderPlayerView:DWORD
EXTRN _oldgamestate:BYTE
EXTRN _singledemo:BYTE
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
EXTRN _mousebforward:BYTE
EXTRN _mousebstrafe:BYTE
EXTRN _mousebuttons:BYTE
EXTRN _mousebfire:BYTE

EXTRN _turnheld:BYTE



EXTRN _myargc:WORD
EXTRN _myargv:BYTE
EXTRN _novideo:BYTE


EXTRN _key_right:BYTE
EXTRN _key_left:BYTE
EXTRN _key_up:BYTE
EXTRN _key_down:BYTE
EXTRN _key_strafeleft:BYTE
EXTRN _key_straferight:BYTE
EXTRN _key_fire:BYTE
EXTRN _key_use:BYTE
EXTRN _key_strafe:BYTE
EXTRN _usemouse:BYTE
EXTRN _mousebfire:BYTE
EXTRN _mousebstrafe:BYTE
EXTRN _mousebforward:BYTE
EXTRN ___iob:WORD
EXTRN _oldkeyboardisr:DWORD
EXTRN _OldInt8:DWORD
EXTRN _TS_Installed:BYTE


.CODE

SIZEOF_FILE = 0Eh
STDOUT = OFFSET ___iob + SIZEOF_FILE


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


PROC D_MAIN_STARTMARKER_ NEAR
PUBLIC D_MAIN_STARTMARKER_
ENDP

_dclicks:
dw 0
_dclicks2:
dw 0
_dclicktime:
dw 0
_dclicktime2:
dw 0
_dclickstate:
dw 0
_dclickstate2:
dw 0

_mousex:
dw 0

_forwardmove:
dw  019h, 032h
_sidemove:
dw  018h, 028h

PUBLIC _forwardmove
PUBLIC _sidemove

; external hook for am_map which is high

PROC   cht_CheckCheat_Far_ FAR
PUBLIC cht_CheckCheat_Far_
call cht_CheckCheat_
retf
ENDP


; ax is cheat index
; dx is ptr
PROC cht_CheckCheat_ NEAR
PUBLIC cht_CheckCheat_

; return in carry

push bx
push si
 
; argument is preshifted by 2 (as the struct offset should be)
cbw
mov  bx, ax
add  bx, OFFSET BASE_CHEAT_ADDRESS
cmp  word ptr cs:[bx + 2], 0
je   initialize_cheat
cheat_initialized:
mov  si, word ptr cs:[bx + 2]   ; si stores p
mov  al, byte ptr cs:[si]
test al, al
jne  char_not_null
mov  byte ptr cs:[si], dl       ; store keypress
inc  si                         ; advance p
mov  word ptr cs:[bx + 2], si   ; store updated p ptr in cheat (should we just inc si?)

check_cheat_result:
; si was inc'd
mov  al, byte ptr cs:[si]
cmp  al, 1
je   reached_custom_param
cmp  al, 0FFh
je   reached_end_of_cheat
return_fail:
clc
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
mov  si, word ptr cs:[bx]       ; reset cheat ptr
mov  word ptr cs:[bx + 2], si
jmp  check_cheat_result
reached_custom_param:
inc  si
mov  word ptr cs:[bx + 2], si
jmp  return_fail
reached_end_of_cheat:
; return success
mov  ax, word ptr cs:[bx]
mov  word ptr cs:[bx + 2], ax
stc
pop  si
pop  bx
ret  

 
ENDP


; get custom param for change level, change music type cheats.
; pass in via di not dx
; pass in via bx not ax
PROC cht_GetParam_ NEAR
PUBLIC cht_GetParam_

push ds
pop  es
; argument is preshifted by 2 (as the struct offset should be)
mov  bx, word ptr cs:[bx + OFFSET BASE_CHEAT_ADDRESS]        ; get str addr
loop_find_param_marker:
inc  bx
cmp  byte ptr cs:[bx-1], 1       ; 1 is marker for custom params position in cheat
jne  loop_find_param_marker

check_next_cheat_char:
mov  al, byte ptr cs:[bx]
;mov  byte ptr ds:[di], al
;inc  di
stosb
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
ret  
getparam_return_0:
mov  byte ptr ds:[di], 0
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

ACKNOWLEDGE_INTERRUPT = 020h

push   bx
push   ax

in     al, 060h                     ; read kb
mov    bl, byte ptr cs:[_kbdhead]
and    bx, KBDQUESIZE - 1           ; wraparound keyboard queue
mov    byte ptr cs:[bx + _keyboardque], al

;mov    ah, al   ; store for checking...

in     al, 061h ; xt keyboard support shuffle.
or     al, 080h
out    061h, al
and    al, 07Fh
out    061h, al


inc    byte ptr cs:[_kbdhead]
mov    al, 020h
out    ACKNOWLEDGE_INTERRUPT, al

;cmp    ah, 0B5h     ; / keydown
;jne    skip_ctrl_c
;call   dumpstacktrace_
skip_ctrl_c:

pop    ax
pop    bx


iret   

ENDP

COMMENT @
_used_dumpfile:

db "dumpdump.bin", 0

; old ax, bx on the stack already!

PROC dumpstacktrace_ NEAR
PUBLIC dumpstacktrace_

push  ax
push  bx
push  cx
push  dx
push  di
push  si
push  es
push  ds
push  ss
push  cs
push  sp
push  bp
mov   bp, sp

mov   ax, OFFSET _used_dumpfile
call  CopyString13_

mov   dx, OFFSET _fopen_w_argument
call  fopen_
mov   bx, ax    ; store 
xor   di, di

mov   cx, 256

nextbyte:
mov   dx, bx
mov   al, byte ptr ss:[bp + di]
call  fputc_
inc   di
loop  nextbyte

mov   ax, bx
call  fclose_

LEAVE_MACRO
pop   ax  ; sp
pop   ax  ; cs
pop   ax  ; ss
pop   ax  ; ds
pop   es
pop   si
pop   di
pop   dx
pop   cx
pop   bx
pop   ax

ret

ENDP

@



; todo revisit and optimize a bit better.


do_exit:
LEAVE_MACRO
pop     dx
pop     bx
ret

PROC I_StartTic_ NEAR
PUBLIC I_StartTic_

push bx
push dx
push bp
mov  bp, sp
sub  sp, SIZE EVENT_T ; built event stored in stack

cmp  byte ptr ds:[_mousepresent], 0
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
and  bx, KBDQUESIZE - 1
mov  al, byte ptr cs:[bx + _keyboardque]
mov  ah, al
and  ah, 07Fh                 ; just the key, no 080h up/downflag
cwd  ; zero dx
;		// extended keyboard shift key bullshit


inc  byte ptr cs:[_kbdtail]
cmp  ah, SC_LSHIFT
je   shift_held
lshift_not_held:
cmp  ah, SC_RSHIFT
jne  rshift_not_held


shift_held:
mov  dl, byte ptr cs:[_kbdtail]
mov  bx, dx
dec  bx
dec  bx 
and  bl, KBDQUESIZE - 1
cmp  byte ptr cs:[bx + _keyboardque], 0E0h   ; special / pause keys
je   loop_next_char
and  al, 080h       ; preserve keyup/down
or   al, SC_RSHIFT
rshift_not_held:
cmp  al, 0E0h       ; special/pause keys
je   loop_next_char
mov  dl, byte ptr cs:[_kbdtail]
mov  bx, dx
dec  bx
dec  bx
and  bl, KBDQUESIZE - 1
cmp  byte ptr cs:[bx + _keyboardque], 0E1h   ; pause key bullshit
je   loop_next_char
cmp  al, 0C5h                            ; dunno
jne  not_c5_press
cmp  byte ptr cs:[bx + _keyboardque], 09Dh
je   is_9D_press
not_c5_press:
test al, 080h   ; keyup/down
mov  ah, EV_KEYDOWN
je   is_keydown
mov  ah, EV_KEYUP
is_keydown:
mov  byte ptr [bp - SIZE EVENT_T + EVENT_T.event_evtype], ah

check_pressed_key:
and  ax, 07Fh                            ; keycode

cmp  al, SC_UPARROW
je   case_uparrow
cmp  al, SC_DOWNARROW
je   case_downarrow
cmp  al, SC_RIGHTARROW
je   case_rightarrow
cmp  al, SC_LEFTARROW
je   case_leftarrow
default_case_key:
xchg ax, bx
mov  al, byte ptr cs:[bx + _scantokey]
key_selected:
mov  byte ptr [bp - SIZE EVENT_T + EVENT_T.event_data1], al
call_post_event:
mov  ax, sp
mov  dx, ds
call D_PostEvent_
jmp  loop_next_char
case_uparrow:
mov  al, KEY_UPARROW
jmp  key_selected
is_9D_press:
mov  word ptr [bp - SIZE EVENT_T + EVENT_T.event_data1], KEY_PAUSE + (EV_KEYDOWN SHL 8)
;mov  byte ptr [bp - SIZE EVENT_T + EVENT_T.event_evtype], EV_KEYDOWN
jmp  call_post_event
case_downarrow:
mov  al, KEY_DOWNARROW
jmp  key_selected
case_leftarrow:
mov  al, KEY_LEFTARROW
jmp  key_selected
case_rightarrow:
mov  al, KEY_RIGHTARROW
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

_scantokey:


db  0  ,    27,     '1',    '2',    '3',    '4',    '5',    '6'
db '7',    '8',    '9',    '0',    '-',    '=',    KEY_BACKSPACE, 9
db 'q',    'w',    'e',    'r',    't',    'y',    'u',    'i'
db 'o',    'p',    '[',    ']',    13 ,    KEY_RCTRL,'a',  's'    
db 'd',    'f',    'g',    'h',    'j',    'k',    'l',    ';'
db 39 ,    '`',    KEY_LSHIFT,92,  'z',    'x',    'c',    'v' 
db 'b',    'n',    'm',    ',',    '.',    '/',    KEY_RSHIFT,'*'
db KEY_RALT,' ',   0  ,    KEY_F1, KEY_F2, KEY_F3, KEY_F4, KEY_F5
db KEY_F6, KEY_F7, KEY_F8, KEY_F9, KEY_F10,0  ,    0  , KEY_HOME
db KEY_UPARROW,KEY_PGUP,'-',KEY_LEFTARROW,'5',KEY_RIGHTARROW,'+',KEY_END
db KEY_DOWNARROW,KEY_PGDN,KEY_INS,KEY_DEL,0,0,             0,              KEY_F11
db KEY_F12,0  ,    0  ,    0  ,    0  ,    0  ,    0  ,    0
db 0  ,    0  ,    0  ,    0  ,    0  ,    0  ,    0  ,    0
db 0  ,    0  ,    0  ,    0  ,    0  ,    0  ,    0  ,    0
db 0  ,    0  ,    0  ,    0  ,    0  ,    0  ,    0  ,    0
db 0  ,    0  ,    0  ,    0  ,    0  ,    0  ,    0  ,    0




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

mov  word ptr cs:[_mousex], ax

pop  di
pop  cx
ret

ENDP

; inlined
COMMENT @

PROC G_SetGameKeyDown_  NEAR
PUBLIC G_SetGameKeyDown_

push bx
xor  ah, ah
mov  bx, ax
mov  byte ptr cs:[bx + _gamekeydown], 1
pop  bx
ret

ENDP

; todo inline
PROC G_SetGameKeyUp_  NEAR
PUBLIC G_SetGameKeyUp_

push bx
xor  ah, ah
mov  bx, ax
mov  byte ptr cs:[bx + _gamekeydown], 0
pop  bx
ret

ENDP

@
; todo inline later
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
cbw      
mov       si, OFFSET _localcmds
SHIFT_MACRO shl ax 3
add       si, ax
mov       di, si
xor       ax, ax

push      cs
pop       es

stosw 
stosw 
stosw 
stosw 

xor       bx, bx
mov       bl, byte ptr ds:[_key_strafe]
cmp       byte ptr cs:[bx + _gamekeydown], bh  ; 0
jne       strafe_is_on
; ax already 0
mov       al, byte ptr ds:[_mousebstrafe]
mov       bx, word ptr ds:[_mousebuttons]

add       bx, ax
mov       al, byte ptr ds:[bx]
test      al, al
je        strafe_is_not_on
strafe_is_on:
inc       ax ; strafe = 1
strafe_is_not_on:
xor       bx, bx
mov       bl, byte ptr ds:[_key_speed]
push      ax
xor       cx, cx        ; cx:di is sidemove?
push      cx
push      cx
xor       di, di

mov       dh, byte ptr cs:[bx + _gamekeydown]    ; speed
mov       bl, byte ptr ds:[_key_right]

cmp       byte ptr cs:[bx + _gamekeydown], bh ; 0
jne       turn_is_held

mov       bl, byte ptr ds:[_key_left]
mov       al, byte ptr cs:[bx + _gamekeydown]
test      al, al
jne       turn_is_held
mov       byte ptr ds:[_turnheld], al
jmp       finished_checking_turn

turn_is_held:
inc       byte ptr ds:[_turnheld]
cmp       byte ptr ds:[_turnheld], SLOWTURNTICS
jl        finished_checking_turn
mov       dl, dh
jmp       check_strafe
finished_checking_turn:
mov       dl, 2
check_strafe:
shl       dh, 1  ; do this once here and re-use
; let movement keys cancel each other out
; dl is speed or strafe?

cmp       byte ptr [bp - 2], bh ; 0
jne       handle_strafe
handle_no_strafe:
mov       bl, byte ptr ds:[_key_right]
cmp       byte ptr cs:[bx + _gamekeydown], bh ; 0
je        handle_checking_left_turn
handle_right_turn:
mov       al, dl
cbw      
mov       bx, ax
sal       bx, 1
mov       ax, word ptr cs:[bx + _angleturn]
sub       word ptr cs:[si + 2], ax
handle_checking_left_turn:
mov       bl, byte ptr ds:[_key_left]
cmp       byte ptr cs:[bx + _gamekeydown], bh ; 0
je        done_handling_strafe
handle_left_turn:
mov       bl, dl
shl       bx, 1
mov       ax, word ptr cs:[bx + _angleturn]
add       word ptr cs:[si + 2], ax
jmp       done_handling_strafe

handle_strafe:
mov       bl, byte ptr ds:[_key_right]
cmp       byte ptr cs:[bx + _gamekeydown], bh ; 0
je        handle_checking_strafe_left
handle_strafe_right:
mov       bl, dh
add       cx, word ptr cs:[bx + _sidemove]
adc       di, 0
handle_checking_strafe_left:
mov       bl, byte ptr ds:[_key_left]
cmp       byte ptr cs:[bx + _gamekeydown], bh
je        done_handling_strafe
handle_strafe_left:
mov       bl, dh
sub       cx, word ptr cs:[bx + _sidemove]
sbb       di, 0
done_handling_strafe:
mov       bl, byte ptr ds:[_key_up]
cmp       byte ptr cs:[bx + _gamekeydown], bh ; 0
je        up_not_pressed
up_pressed:
mov       bl, dh
mov       ax, word ptr cs:[bx + _forwardmove]
add       word ptr [bp - 4], ax
adc       word ptr [bp - 6], 0
up_not_pressed:
mov       bl, byte ptr ds:[_key_down]

cmp       byte ptr cs:[bx + _gamekeydown], bh ; 0
je        down_not_pressed
down_pressed:
mov       bl, dh
mov       ax, word ptr cs:[bx + _forwardmove]
sub       word ptr [bp - 4], ax
sbb       word ptr [bp - 6], 0
down_not_pressed:
mov       bl, byte ptr ds:[_key_straferight]

cmp       byte ptr cs:[bx + _gamekeydown], bh; 0
je        straferight_not_pressed
straferight_pressed:
mov       bl, dh
add       cx, word ptr cs:[bx + _sidemove]
adc       di, 0
straferight_not_pressed:
mov       bl, byte ptr ds:[_key_strafeleft]

cmp       byte ptr cs:[bx + _gamekeydown], bh; 0
je        strafeleft_not_pressed
strafeleft_pressed:
mov       bl, dh
sub       cx, word ptr cs:[bx + _sidemove]
sbb       di, 0
strafeleft_not_pressed:
mov       bl, byte ptr ds:[_key_fire]

cmp       byte ptr cs:[bx + _gamekeydown], bh ; 0
jne       fire_pressed
; check mouse fire
mov       al, byte ptr ds:[_mousebfire]
cbw
mov       bx, word ptr ds:[_mousebuttons]
add       bx, ax
cmp       byte ptr ds:[bx], ah ; 0
je        done_handling_fire

fire_pressed:
or        byte ptr cs:[si + 7], BT_ATTACK
done_handling_fire:
xor       bx, bx
mov       bl, byte ptr ds:[_key_use]
cmp       byte ptr cs:[bx + _gamekeydown], bh ; 0
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
mov       word ptr cs:[_dclicks], ax
jmp       done_handling_use

handle_weapon_change:
mov       al, dl
or        byte ptr cs:[si + 7], BT_CHANGE
SHIFT_MACRO shl al 3
or        byte ptr cs:[si + 7], al
done_checking_weapons:
mov       al, byte ptr ds:[_mousebforward]
mov       bx, word ptr ds:[_mousebuttons]
xor       ah, ah
add       bx, ax
cmp       byte ptr ds:[bx], 0
je        mouse_forward_not_pressed
mov       al, dh
cbw      
mov       bx, ax
SHIFT_MACRO shl bx 1
mov       ax, word ptr cs:[bx + _forwardmove]
add       word ptr [bp - 4], ax
adc       word ptr [bp - 6], 0
mouse_forward_not_pressed:

; check mouse strafe double click?
mov       al, byte ptr ds:[_mousebstrafe]
mov       bx, word ptr ds:[_mousebuttons]
xor       ah, ah
add       bx, ax
mov       al, byte ptr ds:[bx]
cbw      
cmp       ax, word ptr cs:[_dclickstate2]
jne       strafe_clickstate_nonequal
handle_strafe_clickstate:
inc       word ptr cs:[_dclicktime2]
cmp       word ptr cs:[_dclicktime2], 20  
jng       done_handling_mouse_strafe
xor       ax, ax
mov       word ptr cs:[_dclicks2], ax
mov       word ptr cs:[_dclickstate2], ax
jmp       done_handling_mouse_strafe
strafe_clickstate_nonequal:
cmp       word ptr cs:[_dclicktime2], 1
jle       handle_strafe_clickstate
mov       word ptr cs:[_dclickstate2], ax
test      ax, ax
je        dont_increment_dclicks2
inc       word ptr cs:[_dclicks2]
dont_increment_dclicks2:
cmp       word ptr cs:[_dclicks2], 2
je        handle_double_click

xor       ax, ax
mov       word ptr cs:[_dclicktime2], ax
jmp       done_handling_mouse_strafe
strafe_on_add_mousex:
mov       ax, word ptr cs:[_mousex]
SHIFT_MACRO shl ax 3
sub       word ptr cs:[si + 2], ax
jmp       done_handling_mousex

handle_double_click:
xor       ax, ax
or        byte ptr cs:[si + 7], BT_USE
mov       word ptr cs:[_dclicks2], ax

done_handling_mouse_strafe:
cmp       byte ptr [bp - 2], 0
je        strafe_on_add_mousex
; set angle turn
mov       ax, word ptr cs:[_mousex]
add       ax, ax
cwd       
add       cx, ax
adc       di, dx
done_handling_mousex:

; limit move speed to max move (forward_move[1])
; so many zero immediates, so many bytes to save... is a register possibly free?
mov       word ptr cs:[_mousex], 0
mov       ax, word ptr [bp - 6]
cmp       ax, 0
jg        clip_forwardmove_to_max
jne       check_negative_max_forward
mov       ax, word ptr [bp - 4]
cmp       ax, word ptr cs:[_forwardmove + 2]
jbe       check_negative_max_forward
clip_forwardmove_to_max:
mov       ax, word ptr cs:[_forwardmove + 2]
overwrite_forwardmove:
mov       word ptr [bp - 4], ax
dont_overwrite_forwardmove:
mov       ax, 0

; compare side to maxmove
cmp       di, ax
jg        clip_sidemove_to_max
jne       check_negative_max_side
cmp       cx, word ptr cs:[_forwardmove + 2]
jbe       check_negative_max_side
clip_sidemove_to_max:
mov       cx, word ptr cs:[_forwardmove + 2]
done_checking_sidemove:
; add sidemove/forwardmove to cmd
mov       al, byte ptr [bp - 4]
add       byte ptr cs:[si + 1], cl
add       byte ptr cs:[si], al
cmp       byte ptr ds:[_sendpause], 0
je        dont_pause
mov       byte ptr ds:[_sendpause], 0
mov       byte ptr cs:[si + 7], (BT_SPECIAL OR BTS_PAUSE) 
dont_pause:
cmp       byte ptr ds:[_sendsave], 0
jne       handle_save_press
LEAVE_MACRO
pop       di
pop       si
pop       dx
pop       cx
pop       bx
ret       
check_negative_max_forward:

mov       ax, word ptr cs:[_forwardmove + 2]
cwd
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
mov       al, byte ptr ds:[_savegameslot]
SHIFT_MACRO shl al 2
;; BTS_SAVESHIFT
or        al, (BT_SPECIAL OR BTS_SAVEGAME)
mov       byte ptr ds:[_sendsave], 0
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
mov       ax, word ptr cs:[_forwardmove + 2]
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


; copy string from cs:ax to ds:_filename_argument
; return _filename_argument in ax

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




_str_config:
db "-config", 0
_str_default_file:
db "\tdefault file: %s\n", 0    ; todo check if escapes have to be done as bytes
_used_defaultfile:              ; used filename with default value. recorded here after loaddefaults, till savedefaults in case changed.
db "default.cfg", 0, 0

str_defaultname_00:
db "mouse_sensitivity", 0
str_defaultname_01:
db "sfx_volume", 0
str_defaultname_02:
db "music_volume", 0
str_defaultname_03:
db "show_messages", 0
str_defaultname_04:
db "key_right", 0
str_defaultname_05:
db "key_left", 0
str_defaultname_06:
db "key_up", 0
str_defaultname_07:
db "key_down", 0
str_defaultname_08:
db "key_strafeleft", 0
str_defaultname_09:
db "key_straferight", 0
str_defaultname_10:
db "key_fire", 0
str_defaultname_11:
db "key_use", 0
str_defaultname_12:
db "key_strafe", 0
str_defaultname_13:
db "key_speed", 0
str_defaultname_14:
db "use_mouse", 0
str_defaultname_15:
db "mouseb_fire", 0
str_defaultname_16:
db "mouseb_strafe", 0
str_defaultname_17:
db "mouseb_forward", 0
str_defaultname_18:
db "screenblocks", 0
str_defaultname_19:
db "detaillevel", 0
str_defaultname_20:
db "snd_channels", 0
str_defaultname_21:
db "snd_musicdevice", 0
str_defaultname_22:
db "snd_sfxdevice", 0
str_defaultname_23:
db "snd_sbport", 0
str_defaultname_24:
db "snd_sbirq", 0
str_defaultname_25:
db "snd_sbdma", 0
str_defaultname_26:
db "snd_mport", 0
str_defaultname_27:
db "usegamma", 0
str_defaultname_28:
db "span_quality", 0
str_defaultname_29:
db "column_quality", 0
str_defaultname_30:
db "sky_quality", 0

; 7 bytes per.
; todo move the vars all to a cs array?
; will need to mirror some vars like screenblocks, detaillevel..
_defaults:
dw OFFSET str_defaultname_00, OFFSET _mouseSensitivity
db  5, 0, 0
dw OFFSET str_defaultname_01, OFFSET _sfxVolume
db  8, 0, 0
dw OFFSET str_defaultname_02, OFFSET _musicVolume
db  8, 0, 0
dw OFFSET str_defaultname_03, OFFSET _showMessages
db  1, 0, 0
dw OFFSET str_defaultname_04, OFFSET _key_right
db  SC_RIGHTARROW, 1, 0
dw OFFSET str_defaultname_05, OFFSET _key_left
db  SC_LEFTARROW, 1, 0
dw OFFSET str_defaultname_06, OFFSET _key_up
db  SC_UPARROW, 1, 0
dw OFFSET str_defaultname_07, OFFSET _key_down
db  SC_DOWNARROW, 1, 0
dw OFFSET str_defaultname_08, OFFSET _key_strafeleft
db  SC_COMMA, 1, 0
dw OFFSET str_defaultname_09, OFFSET _key_straferight
db  SC_PERIOD, 1, 0
dw OFFSET str_defaultname_10, OFFSET _key_fire
db  SC_RCTRL, 1, 0
dw OFFSET str_defaultname_11, OFFSET _key_use
db  SC_SPACE, 1, 0
dw OFFSET str_defaultname_12, OFFSET _key_strafe
db  SC_RALT, 1, 0
dw OFFSET str_defaultname_13, OFFSET _key_speed
db  SC_RSHIFT, 1, 0
dw OFFSET str_defaultname_14, OFFSET _usemouse
db  0, 0, 0
dw OFFSET str_defaultname_15, OFFSET _mousebfire
db 0, 0, 0
dw OFFSET str_defaultname_16, OFFSET _mousebstrafe
db 1, 0, 0
dw OFFSET str_defaultname_17, OFFSET _mousebforward
db 2, 0, 0
dw OFFSET str_defaultname_18, OFFSET _screenblocks
db  9, 0, 0
dw OFFSET str_defaultname_19, OFFSET _detailLevel
db  0, 0, 0
dw OFFSET str_defaultname_20, OFFSET _numChannels
db  3, 0, 0
dw OFFSET str_defaultname_21, OFFSET _snd_DesiredMusicDevice
db  0, 0, 0
dw OFFSET str_defaultname_22, OFFSET _snd_DesiredSfxDevice
db  0, 0, 0
dw OFFSET str_defaultname_23, OFFSET _snd_SBport
db  022h, 0, 0 ; must be shifted one nibble
dw OFFSET str_defaultname_24, OFFSET _snd_SBirq
db  5, 0, 0
dw OFFSET str_defaultname_25, OFFSET _snd_SBdma
db  1, 0, 0
dw OFFSET str_defaultname_26, OFFSET _snd_Mport
db  033h, 0, 0  ; must be shifted one nibble
dw OFFSET str_defaultname_27, OFFSET _usegamma
db  0, 0, 0    
dw OFFSET str_defaultname_28, OFFSET _spanquality
db  0, 0, 0    
dw OFFSET str_defaultname_29, OFFSET _columnquality
db  0, 0, 0    
dw OFFSET str_defaultname_30, OFFSET _skyquality
db  0, 0, 0    





PROC M_LoadDefaults_  NEAR
PUBLIC M_LoadDefaults_

PUSHA_NO_AX_MACRO
push  bp

mov   bp, sp
sub   sp, 0AAh
sub   bp, 080h
xor   bx, bx

mov   cx, NUM_DEFAULTS
loop_set_default_values:
xor   ax, ax
mov   si, word ptr cs:[bx + _defaults + DEFAULT_T.default_loc_ptr]
mov   al, byte ptr cs:[bx + _defaults + DEFAULT_T.default_defaultvalue] ; default...
add   bx, 7               ; 
cmp   si, OFFSET _snd_SBport    ; 16 bit value special case
je    shift4_write_word
cmp   si, OFFSET _snd_Mport    ; 16 bit value special case
je    shift4_write_word
mov   byte ptr ds:[si], al         ; written here 1
jmp   wrote_byte
shift4_write_word:
SHIFT_MACRO shl ax 4
mov   word ptr ds:[si], ax
wrote_byte:
loop  loop_set_default_values


mov   ax, OFFSET _str_config
call  CopyString13_
mov   dx, ds
call  M_CheckParm_



test  ax, ax
je    set_default_defaultsfilename
mov   dx, word ptr ds:[_myargc]
dec   dx
cmp   ax, dx
jge   set_default_defaultsfilename
mov   si, word ptr ds:[_myargv]
add   ax, ax
add   si, ax
mov   si, word ptr ds:[si + 2]   ; pointer to myargv for default filename
push  si
mov   bx, si  ; cache

; copy updated filename locally

mov   di, OFFSET _used_defaultfile
push  cs
pop   es
mov   cx, 12        ; 12 chars max for 8.3 filename 

loop_copy_new_defaults_filename:
lodsb
stosb
cmp   al, 0
je    done_copying_new_defaults_filename
loop loop_copy_new_defaults_filename
done_copying_new_defaults_filename:

;mov   ax, OFFSET _str_default_file
;call  DEBUG_PRINT_
;add   sp, 4




set_default_defaultsfilename:
mov   ax, OFFSET _used_defaultfile
call  CopyString13_




mov   dx, OFFSET _fopen_r_argument
;mov   ax, OFFSET _filename_argument    ; already set above
call  fopen_

mov   bx, ax
mov   word ptr [bp + 076h], ax          ; store fopen fp file handle
test  ax, ax
jne   defaults_file_loaded
; fall thru to bad file
defaults_file_closed:

exit_mloaddefaults:
lea   sp, [bp + 080h]
pop   bp
POPA_NO_AX_MACRO

ret


defaults_file_loaded:

; bx is file pointer..
xor   al, al
;		int8_t readphase = 0; // getting param 0
;		int8_t defindex = 0;
;		int8_t strparmindex = 0;
mov   byte ptr [bp + 07Ah], al          ; readphase
mov   byte ptr [bp + 07Ch], al
mov   byte ptr [bp + 07Eh], al          ; strparmindex
test  byte ptr ds:[bx + 6], 010h    ; check feof
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
test  byte ptr ds:[bx + 6], 010h        ; test feof
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
xor   ax, ax
mov   di, ax
mov   si, ax
mov   cx, ax

;lea   ax, [bp + 026h]
;call  sscanf_uint8_                 ; todo inline this


read_next_digit:
mov   cl, 10
mul   cl         ; mul by 10
mov   cl, byte ptr [bp + si + 026h];
add   ax, cx     ; add next char
sub   ax, 030h   ; but sub '0' from char
inc   si
cmp   byte ptr [bp + si + 026h], 0 ; check for null term
jne   read_next_digit



mov   word ptr [bp + 078h], ax
xor   si, si

scan_next_default_name_for_match:
lea   ax, [bp - 02Ah]
mov   cx, cs
mov   dx, ds
mov   bx, word ptr cs:[si + _defaults + DEFAULT_T.default_name_ptr]

call  locallib_strcmp_
test  ax, ax
jne   no_match_increment_default
mov   bx, word ptr cs:[si + _defaults + DEFAULT_T.default_loc_ptr]
mov   ax, word ptr [bp + 078h]
; if one of the 16 bit ones then write word..
cmp   bx, OFFSET _snd_SBport
je    do_word_write
cmp   bx, OFFSET _snd_Mport
je    do_word_write
do_byte_write:
mov   byte ptr ds:[bx], al                             ; written here 2 
jmp   character_finished_handling      
do_word_write:
mov   word ptr ds:[bx], ax
jmp   character_finished_handling
no_match_increment_default:
inc   di
add   si, SIZEOF_DEFAULT_T
cmp   di, NUM_DEFAULTS
jl    scan_next_default_name_for_match
jmp   character_finished_handling


ENDP

PROC M_ScanTranslateDefaults_ NEAR
PUBLIC M_ScanTranslateDefaults_

PUSHA_NO_AX_MACRO

xor   bx, bx

;	for (i = 0; i < NUM_DEFAULTS; i++) {
;		if (defaults[i].scantranslate) {
;			parm = *defaults[i].location;
;			defaults[i].untranslated = parm;
;			*defaults[i].location = scantokey[parm];
;		}
;	}

loop_defaults_to_set_initial_values:
cmp   byte ptr cs:[bx + _defaults + DEFAULT_T.default_scantranslate], 0
je    no_pointer_load_next_defaults_value
mov   si, word ptr cs:[bx + _defaults + DEFAULT_T.default_loc_ptr]
mov   al, byte ptr ds:[si]
mov   byte ptr cs:[bx + _defaults + DEFAULT_T.default_untranslated], al  ; written here 3
xor   ah, ah
mov   si, ax
mov   di, word ptr cs:[bx + _defaults + DEFAULT_T.default_loc_ptr]
mov   al, byte ptr cs:[si + _scantokey]
mov   byte ptr ds:[di], al                     ; written here 4
no_pointer_load_next_defaults_value:
add   bx, SIZEOF_DEFAULT_T
cmp   bx, NUM_DEFAULTS * SIZEOF_DEFAULT_T
jne   loop_defaults_to_set_initial_values

POPA_NO_AX_MACRO
ret



ENDP

PROC M_SaveDefaults_  NEAR
PUBLIC M_SaveDefaults_


push  bx
push  cx
push  dx
push  si
push  di


mov   ax, OFFSET _used_defaultfile
call  CopyString13_


mov   dx, OFFSET  _fopen_w_argument
;mov   ax, OFFSET _filename_argument  ; already set above
call  fopen_


mov   cx, ax
test  ax, ax
je    exit_msavedefaults
xor   bh, bh
cld   
loop_next_default:
mov   al, SIZEOF_DEFAULT_T
mul   bh
mov   si, ax
cmp   byte ptr cs:[si + _defaults + DEFAULT_T.default_scantranslate], 0
jne   get_untranslated_value
mov   di, word ptr cs:[si + _defaults + DEFAULT_T.default_loc_ptr]
cmp   di, OFFSET _snd_Mport
je    get_16_bit
cmp   di, OFFSET _snd_SBport
je    get_16_bit
xor   ah, ah
mov   al, byte ptr ds:[di]
jmp   got_value_to_write
get_16_bit:
mov   ax, word ptr ds:[di]

got_value_to_write:         ; if we got untranslated value we skip here with value in al.

mov   di, ax             ; store the value.
mov   si, word ptr cs:[si + _defaults + DEFAULT_T.default_name_ptr]  ; string ptr

write_next_default_name_character:

lods  byte ptr cs:[si]
test  al, al
je    done_writing_default_name
cbw  
mov   dx, cx    ; get fp
call  fputc_
jmp   write_next_default_name_character

print_last_digit:
mov   al, bl
mov   dx, cx    ; get fp
add   al, 030h       ;  add '0' char to digit
call  fputc_
mov   ax, 0Ah  ; line feed character \n
mov   dx, cx    ; get fp
call  fputc_
inc   bh
cmp   bh, NUM_DEFAULTS
jl    loop_next_default
mov   ax, cx
call  fclose_
exit_msavedefaults:
pop   di
pop   si
pop   dx
pop   cx
pop   bx
ret   
get_untranslated_value:        ; this is pointing pointer to cs value instead of ds value. BAD
mov   al, byte ptr cs:[si + _defaults + DEFAULT_T.default_untranslated]  ; get the untranslated value
jmp   got_value_to_write
done_writing_default_name:
mov   dx, cx    ; fp
mov   ax, 9     ; tab char
call  fputc_
mov   dx, cx    ; fp
mov   ax, 9     ; tab char
call  fputc_

mov   si, 0             ; if nonzero then we have printed a 100s digit and thus a zero 10s digit must be printed.

mov   ax, di
; note: AH gets divide result and AL gets mod!
mov   dl, 10
div   dl
mov   bl, ah            ; bl gets last digit.
xor   ah, ah
div   dl
;     bl is 1s digit
;     ah is 10s digit
;     al is 100s digit

test  al, al
je    handle_tens_number
mov   si, ax
mov   dx, cx         ; fp
add   al, 030h       ;   '0' char
call  fputc_

mov   ax, si

handle_tens_number:
test  si, si
jne   force_print_tens_digit    ; even if 0
test  ah, ah
je    print_last_digit
force_print_tens_digit:

mov   al, ah
mov   dx, cx         ; fp
add   al, 030h       ;   '0' char
call  fputc_

jmp   print_last_digit


ENDP
call_startcontrolpanel:
; should already be in menu task?
db    09Ah
dw    M_STARTCONTROLPANELOFFSET, MENU_CODE_AREA_SEGMENT

exit_gresponder_return_1:
mov   al, 1
pop   si
pop   cx
pop   bx
ret   

; todo return carry
PROC G_Responder_  NEAR
PUBLIC G_Responder_

push  bx
push  cx
push  si
mov   bx, ax
mov   cx, dx
cmp   byte ptr ds:[_gameaction], 0
jne   not_starting_controlpanel
cmp   byte ptr ds:[_singledemo], 0
jne   not_starting_controlpanel
cmp   byte ptr ds:[_demoplayback], 0
jne   check_key_for_controlpanel
cmp   byte ptr ds:[_gamestate], GS_DEMOSCREEN
jne   not_starting_controlpanel
check_key_for_controlpanel:
mov   es, cx
mov   ax, word ptr es:[bx + EVENT_T.event_data1]
test  ah, ah ; EV_KEYDOWN
je    call_startcontrolpanel    ; keydown?
cmp   ah, EV_MOUSE              ; mouse?
jne   exit_gresponder_return_0
test  al, al
jne   call_startcontrolpanel    ; any mousebutton down?
exit_gresponder_return_0:
xor   ax, ax
pop   si
pop   cx
pop   bx
ret   
not_starting_controlpanel:
cmp   byte ptr ds:[_gamestate], GS_LEVEL
jne   not_gamestate_level
mov   ax, bx
mov   dx, cx
call  HU_Responder_
; jc    exit_gresponder_return_1  ; always false. i think only netcode/chat stuff could eat the key
mov   ax, bx
mov   dx, cx
call  ST_Responder_ ; never returns true
;test  al, al
;jne   exit_gresponder_return_1
mov   ax, bx
mov   dx, cx

;call  AM_Responder_
db    09Ah
dw    AM_RESPONDER_OFFSET, PHYSICS_HIGHCODE_SEGMENT

jc    exit_gresponder_return_1

not_gamestate_level:
cmp   byte ptr ds:[_gamestate], GS_FINALE
jne   not_gamestate_finale
mov   ax, OVERLAY_ID_FINALE
call  Z_SetOverlay_
mov   dx, cx
mov   ax, bx

;call  dword ptr ds:[_F_Responder]
db 09Ah
dw F_RESPONDEROFFSET, CODE_OVERLAY_SEGMENT

test  al, al
jne   exit_gresponder_return_1_2

not_gamestate_finale:

; check event type
mov   es, cx
mov   ax, word ptr es:[bx + EVENT_T.event_data1]
cmp   ah, EV_KEYUP
ja    handle_game_mouse_event  ; ev_mouse
xchg  ax, bx
mov   al, 0
je   handle_game_keyup_event
; al has key

handle_game_keydown_event:
; i dont think we have to handle high word
cmp   bl, KEY_PAUSE
jne   handle_nonpause_game_keydown_event

mov   byte ptr ds:[_sendpause], 1
exit_gresponder_return_1_2:
mov   al, 1
exit_gresponder_return_al:
pop   si
pop   cx
pop   bx
ret   

handle_nonpause_game_keydown_event:
inc   ax  ; al is 1. write 1 not 0 and return 1.
handle_game_keyup_event:
; G_SetGameKeyUp/Down:

xor   bh, bh
mov   byte ptr cs:[bx + _gamekeydown], al ; 0 or 1...
jmp   exit_gresponder_return_al



handle_game_mouse_event:
mov   ah, al
mov   bx, ax ; backup button
mov   si, word ptr ds:[_mousebuttons]
and   ax, 00201h
mov   word ptr ds:[si], ax ; write two buttons;

xchg  ax, bx  ; get another copy of button
and   ax, 4   ; zero ah
mov   byte ptr ds:[si + 2], al
mov   al, byte ptr ds:[_mouseSensitivity]

mov   dx, word ptr es:[bx + EVENT_T.event_data2]
add   ax, 5
mov   bx, 10
imul  dx
call  FastDiv3216u_
mov   word ptr cs:[_mousex], ax
mov   al, 1
pop   si
pop   cx
pop   bx
ret   

ENDP

;void __near I_SetPalette(int8_t paletteNumber) {

PROC I_SetPalette_  FAR
PUBLIC I_SetPalette_

PALETTEBYTES_SEGMENT = 09000h

cmp   byte ptr ds:[_novideo], 0
jne   just_exit
has_video:

PUSHA_NO_AX_OR_BP_MACRO
mov   ah, al
add   ah, al  ; times 0x200..
add   ah, al  ; times 0x300..
xor   al, al
mov   si, ax  ; si = al * 768

;mov   di, word ptr ds:[_currenttask] ; get this before quickmap
push  word ptr ds:[_currenttask] ; get this before quickmap
mov   ax, 1
call  I_WaitVBL_
call  Z_QuickMapPalette_

mov   dx, PEL_WRITE_ADR
xor   ax, ax
out   dx, al

mov   bx, ax ; zero
mov   bh, byte ptr ds:[_usegamma]

;mov   dx, PALETTEBYTES_SEGMENT
;mov   ds, dx
mov   dx, GAMMATABLE_SEGMENT
;mov   es, dx
mov   ds, dx

add   si, (PALETTEBYTES_SEGMENT - GAMMATABLE_SEGMENT) * 16

mov   dx, PEL_DATA
mov   cx, 768

loop_palette_out:

lodsb                   ; *palette
xlat                    ; gammatablelookup[*palette]
SHIFT_MACRO sar   ax 2  ; gammatablelookup[*palette] >> 2
out   dx, al

loop  loop_palette_out

mov   ax, ss
mov   ds, ax

;xchg  ax, di  ; get current task back
pop   ax  ; task

call  Z_QuickMapByTaskNum_

POPA_NO_AX_OR_BP_MACRO
just_exit:
ret   
ENDP


;void __near I_UpdateBox(int16_t x, int16_t y, int16_t w, int16_t h) {


PROC I_UpdateBox_  NEAR
PUBLIC I_UpdateBox_




push  si
push  di

mov   word ptr cs:[SELFMODIFY_set_h_check+2], cx

mov   cx, ax

; mul dx by screenwidth
mov   al, SCREENWIDTHOVER2
mul   dl
sal   ax, 1
xchg  ax, dx  ; dx gets dx * screenwidth
mov   ax, cx ; retrieve ax

;    sp_x1 = x >> 3;
;    sp_x2 = (x + w) >> 3;

add   ax, bx
SHIFT_MACRO sar   ax 3
mov   bx, cx   ; store this
SHIFT_MACRO sar   cx 3

;    count = sp_x2 - sp_x1 + 1;
sub   ax, cx
inc   ax        ; ax is count

; mul done earlier to dx
;    offset = (uint16_t)y * SCREENWIDTH + (sp_x1 << 3);
and   bx, 0FFF8h ; shift right 3, shift left 3. just clear bottom 3 bits.
add   bx, dx    ; bx is offset

;    poffset = offset >> 2;


mov   word ptr cs:[SELFMODIFY_set_offset+1], bx ; set
SHIFT_MACRO shr   bx 2  ; poffset
mov   word ptr cs:[SELFMODIFY_add_poffset+1], bx ; set


les   di, dword ptr ds:[_destscreen]
add   word ptr cs:[SELFMODIFY_set_original_destscreen_offset+1], di ; add in by default


;    step = SCREENWIDTH - (count << 3);

mov   word ptr cs:[SELFMODIFY_set_count+1], ax



SHIFT_MACRO shl   ax 3
mov   dx, SCREENWIDTH
sub   dx, ax            ; dx is step



;    pstep = step >> 2;

mov   ax, dx
mov   word ptr cs:[SELFMODIFY_add_step+2], ax
SHIFT_MACRO sar   ax 2
mov   word ptr cs:[SELFMODIFY_add_pstep+2], ax
mov   dx, SC_INDEX
mov   al, SC_MAPMASK
out   dx, al

mov   ax, SCREEN0_SEGMENT
mov   ds, ax
xor   cx, cx ; loopcount

loop_next_vga_plane:

;	outp(SC_INDEX + 1, 1 << i);

mov   al, 1
mov   dx, SC_DATA
; bx is offset
shl   ax, cl
out   dx, al

;        source = &screen0[offset + i];
; source is ds:si
SELFMODIFY_set_offset:
mov   si, 01000h
add   si, cx   ; screen0 offset = offset + i


;        dest = (byte __far*) (destscreen.w + poffset);
; dest is es:di
SELFMODIFY_set_original_destscreen_offset:
SELFMODIFY_add_poffset:
mov   di, 01000h ; just add it beforehand

xor   bx, bx  ; j = 0 loop counter


loop_next_pixel:
SELFMODIFY_set_count:
mov   dx, 01000h;
dec   dx

inner_inner_loop:

;    while (k--) {
;        *(uint16_t __far *)dest = (uint16_t)(((*(source + 4)) << 8) + (*source));
;        dest += 2;
;        source += 8;
;    }

;mov   al, byte ptr ds:[si]
lodsb
mov   ah, byte ptr ds:[si + 3]

stosw 
add   si, 7
dec   dx
jns    inner_inner_loop

inner_inner_loop_done:
inc   bx
SELFMODIFY_add_step:
add   si, 01000h
SELFMODIFY_add_pstep:
add   di, 01000h

;        for (j = 0; j < h; j++) {

SELFMODIFY_set_h_check:
cmp   bx, 01000h
jb    loop_next_pixel
inner_box_loop_done:
inc   cx
cmp   cx, 4
jb    loop_next_vga_plane

mov   ax, ss
mov   ds, ax  ; restore ds

pop   di
pop   si
ret   


ENDP

CRTC_INDEX = 03D4h  ; todo contstants

PROC I_FinishUpdate_  NEAR
PUBLIC I_FinishUpdate_


;	outpw(CRTC_INDEX, (destscreen.h.fracbits & 0xff00L) + 0xc);
;	//Next plane
;    destscreen.h.fracbits += 0x4000;
;	if ((uint16_t)destscreen.h.fracbits == 0xc000) {
;		destscreen.h.fracbits = 0x0000;
;	}


push  dx
mov   ax, word ptr ds:[_destscreen]
mov   dx, CRTC_INDEX
mov   al, 0Ch
out   dx, ax
add   byte ptr ds:[_destscreen + 1], 040h
;cmp   byte ptr ds:[_destscreen + 1], 0C0h
;je    set_destscreen_0 ; SF != OF
jl    set_destscreen_0 ; SF != OF
pop   dx
ret
set_destscreen_0:
mov   byte ptr ds:[_destscreen+1], 0
pop   dx
ret



ENDP

PROC I_UpdateNoBlit_  NEAR
PUBLIC I_UpdateNoBlit_


PUSHA_NO_AX_OR_BP_MACRO
; todo word only. segment should be fixed..?
les  ax, dword ptr ds:[_destscreen]
mov  word ptr ds:[_currentscreen], ax
mov  word ptr ds:[_currentscreen + 2], es



; cx is realdr[BOXTOP]
; bx is realdr[BOXRIGHT]
; dx is realdr[BOXBOTTOM]
; ax is realdr[BOXLEFT]

;    // Update dirtybox size
;    realdr[BOXTOP] = dirtybox[BOXTOP];
;    if (realdr[BOXTOP] < olddb[0+BOXTOP]) {
;        realdr[BOXTOP] = olddb[0+BOXTOP];
;    }
;    if (realdr[BOXTOP] < olddb[4+BOXTOP]) {
;        realdr[BOXTOP] = olddb[4+BOXTOP];
;    }

mov  si, OFFSET _olddb
mov  di, OFFSET _dirtybox

; cx gets boxtop

lodsw  ; ax = olddb[0+BOXTOP]
mov  cx, word ptr ds:[di + (BOXTOP * 2)]        ; realdr[BOXTOP]
cmp  cx, ax
jge  dont_cap_top_1
xchg cx, ax
dont_cap_top_1:
mov  ax, word ptr ds:[si + (3 * 2)]
cmp  cx, ax
jge  dont_cap_top_2
xchg cx, ax
dont_cap_top_2:

;    realdr[BOXBOTTOM] = dirtybox[BOXBOTTOM];
;    if (realdr[BOXBOTTOM] > olddb[0+BOXBOTTOM]) {
;        realdr[BOXBOTTOM] = olddb[0+BOXBOTTOM];
;    }
;    if (realdr[BOXBOTTOM] > olddb[4+BOXBOTTOM]) {
;        realdr[BOXBOTTOM] = olddb[4+BOXBOTTOM];
;    }

;  dx gets boxbottom

lodsw  ; ax = olddb[0+BOXBOTTOM]
mov  dx, word ptr ds:[di + (BOXBOTTOM * 2)]  ; realdr[BOXBOTTOM]
cmp  dx, ax         
jle  dont_cap_bot_1
xchg dx, ax
dont_cap_bot_1:
mov  ax, word ptr ds:[si + (3 * 2)]
cmp  dx, ax
jle  dont_cap_bot_2
xchg dx, ax
dont_cap_bot_2:


;    realdr[BOXLEFT] = dirtybox[BOXLEFT];
;    if (realdr[BOXLEFT] > olddb[0+BOXLEFT]) {
;        realdr[BOXLEFT] = olddb[0+BOXLEFT];
;    }
;    if (realdr[BOXLEFT] > olddb[4+BOXLEFT]) {
;        realdr[BOXLEFT] = olddb[4+BOXLEFT];
;    }

; bx stores boxleft for now

lodsw  ; ax = olddb[0+BOXLEFT]
mov  bx, word ptr ds:[di + (BOXLEFT * 2)]  ; ; realdr[BOXLEFT]
cmp  bx, ax
jle  dont_cap_left_1
xchg bx, ax
dont_cap_left_1:
mov  ax, word ptr ds:[si + (3 * 2)]
cmp  bx, ax
jle  dont_cap_left_2
xchg bx, ax
dont_cap_left_2:


;    realdr[BOXRIGHT] = dirtybox[BOXRIGHT];
;    if (realdr[BOXRIGHT] < olddb[0+BOXRIGHT]) {
;        realdr[BOXRIGHT] = olddb[0+BOXRIGHT];
;    }
;    if (realdr[BOXRIGHT] < olddb[4+BOXRIGHT]) {
;        realdr[BOXRIGHT] = olddb[4+BOXRIGHT];
;    }
; di stores boxright for now

lodsw  ; ax = olddb[0+BOXRIGHT]
mov  di, word ptr ds:[di + (BOXRIGHT * 2)]
cmp  di, ax
jge  dont_cap_right_1
xchg di, ax
dont_cap_right_1:
mov  ax, word ptr ds:[si + (3 * 2)]
cmp  di, ax
jge  dont_cap_right_2
xchg di, ax
dont_cap_right_2:

xchg ax, di ; ax gets boxright
xchg ax, bx ; ax gets boxleft. bx gets boxright.

;    // Leave current box for next update
;    olddb[0] = olddb[4];
;    olddb[1] = olddb[5];
;    olddb[2] = olddb[6];
;    olddb[3] = olddb[7];
;    olddb[4] = dirtybox[0];
;    olddb[5] = dirtybox[1];
;    olddb[6] = dirtybox[2];
;    olddb[7] = dirtybox[3];

mov  di, ds
mov  es, di
;mov  si, OFFSET _olddb + (4 * 2)  ; si is already set thru lodsw
mov  di, OFFSET _olddb
movsw
movsw
movsw
movsw
mov  si, OFFSET _dirtybox  ; worth making them adjacent and removing this?
movsw
movsw
movsw
movsw


; cx is realdr[BOXTOP]
; bx is realdr[BOXRIGHT]
; dx is realdr[BOXBOTTOM]
; ax is realdr[BOXLEFT]

;    // Update screen
;    if (realdr[BOXBOTTOM] <= realdr[BOXTOP]) {
;        x = realdr[BOXLEFT];
;        y = realdr[BOXBOTTOM];
;        w = realdr[BOXRIGHT] - realdr[BOXLEFT] + 1;
;        h = realdr[BOXTOP] - realdr[BOXBOTTOM] + 1;
;        I_UpdateBox(x, y, w, h); // todo inline, only use.
;    }

cmp  dx, cx
jnle  dont_update_box

sub  bx, ax
sub  cx, dx
inc  bx
inc  cx
call I_UpdateBox_  ; cx guaranteed 1 or more
mov  ax, ds
mov  es, ax

dont_update_box:

;	// Clear box
;	dirtybox[BOXTOP] = dirtybox[BOXRIGHT] = MINSHORT;
;	dirtybox[BOXBOTTOM] = dirtybox[BOXLEFT] = MAXSHORT;
mov  ax, MINSHORT
mov  di, OFFSET _dirtybox
stosw       ; boxtop    = minshort
dec   ax
stosw       ; boxbottom = maxshort
stosw       ; boxleft   = maxshort
inc   ax
stosw       ; boxright  = minshort

POPA_NO_AX_OR_BP_MACRO
ret 

ENDP

PROC    M_Ticker_    NEAR
PUBLIC  M_Ticker_


dec   word ptr ds:[_skullAnimCounter]
jnle   exit_m_ticker
xor   byte ptr ds:[_whichSkull], 1
mov   word ptr ds:[_skullAnimCounter], 8
exit_m_ticker:
ret   



ENDP


PROC   combine_strings_ NEAR
PUBLIC combine_strings_ 

;void __far combine_strings_(char __far *dest, char __far *src1, char __far *src2){
;               ; bp + 8 is IP?
push si         ; bp + 4
push di         ; bp + 2
push bp         ; bp + 0
mov  bp, sp

mov  es, dx
xchg ax, di


mov  si, bx
mov  ds, cx

do_next_char_far_1:
lodsb
test al, al
stosb
jne  do_next_char_far_1

dec  di ; back one up

lds  si, dword ptr [bp + 8]

do_next_char_far_2:
lodsb
test al, al
stosb
jne  do_next_char_far_2

push ss
pop  ds

; leave last char, was the '\0'


LEAVE_MACRO

pop  di
pop  si
ret

ENDP


PROC   locallib_strcmp_ NEAR
PUBLIC locallib_strcmp_ 

push  si
push  di

xchg  ax, di
mov   es, dx
mov   si, bx
mov   ds, cx

xor   ax, ax
mov   dx, di ; store old
repne scasb  ; find end of string
sub   di, dx
mov   cx, di ; cx has len
mov   di, dx ; di restored


repe  cmpsb

dec   si
lodsb
sub   al, byte ptr es:[di-1]

push  ss
pop   ds

pop   di
pop   si

ret
ENDP



PROC   locallib_strcpy_ NEAR
PUBLIC locallib_strcpy_ 

push  si
push  di

xchg  ax, di
mov   es, dx
mov   si, bx
mov   ds, cx


copy_next_char_1:
lodsb
test al, al
stosb
jne  copy_next_char_1

push  ss
pop   ds

pop   di
pop   si

ret
ENDP

PROC   locallib_strlen_ NEAR
PUBLIC locallib_strlen_

push   di
push   cx
mov    es, dx
xchg   ax, di
xor    ax, ax
mov    cx, 0FFFFh

repne  scasb
dec    ax ;  ax was 0, now 0FFFFh
sub    ax, cx


pop    cx
pop    di
ret

ENDP



PROC   locallib_toupper_ NEAR
PUBLIC locallib_toupper_

cmp   al, 061h
jb    exit_m_to_upper
cmp   al, 07Ah
ja    exit_m_to_upper
sub   al, 020h
exit_m_to_upper:
ret

ENDP



PROC   copystr8_ NEAR
PUBLIC copystr8_

push   di
push   si

xchg  ax, di
mov   es, dx
mov   si, bx
mov   ds, cx

mov   cx, 8

copy_next_char_str8:
lodsb
test al, al
stosb
je   break_loop_str8
loop copy_next_char_str8
break_loop_str8:

push   ss
pop    ds

pop    si
pop    di
ret

ENDP

PROC   locallib_createhexnibble_ NEAR
PUBLIC locallib_createhexnibble_

;char __far locallib_printhexdigit (uint8_t digit, boolean printifzero){
    ; printifzero turned into direction flag
test   al, al
je     handle_zero_hexdigit
cmp    al, 0Ah
jl     add_zerochar
add    al, 55
ret
handle_zero_hexdigit:

test   bh, bh
je     ret_zero
add_zerochar:
add    al, '0'
ret_zero:
ret
ENDP

PROC   locallib_putchar_check_di NEAR
test   di, di
je     locallib_putchar_
push   ds
pop    es
stosb

ret
ENDP

PROC   locallib_putchar_ NEAR
PUBLIC locallib_putchar_ 

push  dx
mov   dx, STDOUT
cbw
call  fputc_
pop   dx
ret

COMMENT @
push  dx
test  byte ptr ds:[STDOUT + WATCOM_C_FILE.watcom_file_flag+1], (0400h SHR 8) ; IONBF  0x0400  /* no buffering */
jne   just_putchar
mov   dx, word ptr ds:[STDOUT + WATCOM_C_FILE.watcom_file_bufsize]
sub   dx, word ptr ds:[STDOUT + WATCOM_C_FILE.watcom_file_cnt]
cmp   dx, 1         ; dec dx jnge?
jbe   just_putchar
push  bx
mov   bx, word ptr ds:[STDOUT + WATCOM_C_FILE.watcom_file_ptr]
mov   byte ptr ds:[bx], al
pop   bx
cmp   al, 0Ah  ; '\n'
je    just_putchar
or    byte ptr ds:[STDOUT + WATCOM_C_FILE.watcom_file_flag+1], (01000h SHR 8)  ; _DIRTY  0x1000  /* buffer has been modified */
inc   byte ptr ds:[STDOUT + WATCOM_C_FILE.watcom_file_cnt]
inc   byte ptr ds:[STDOUT + WATCOM_C_FILE.watcom_file_ptr]
pop   dx
ret
just_putchar:
mov   dx, STDOUT
cbw
call  fputc_
pop   dx
@
ret

ENDP
PROC   locallib_printhex_ NEAR
PUBLIC locallib_printhex_
;void __far locallib_printhex (uint32_t number, boolean islong){
; number to print in ax:dx.   islong boolean in cx 

; if bx nonzero then print to it.
push  di
mov   di, bx

test  cl, cl
mov   cx, 7
jne   is_long
mov   cl, 3
mov   dx, ax ; dupe ax in DX. makes the algorithm work in both cases.
is_long:

push  ax  ; save current ax state. 

; cx is shifter
mov   bx, cx  ; zero bh

loop_shifter:

; start with high nibbles. rotate left. each loop

push  cx
mov   cl, 4
xor   bl, bl
shift_nibble_loop:
sal   ax, 1
rcl   dx, 1
rcl   bl, 1
loop  shift_nibble_loop
or    al, bl
pop   cx

push  ax  ; back up
and   al, 0Fh
je    dont_update_self_modify ; update the instruction above if al is not zero
inc   bh
dont_update_self_modify:

call  locallib_createhexnibble_
test  al, al
je    skip_print_hex_digit

call  locallib_putchar_check_di

skip_print_hex_digit:
iter_next_hex_digit:

pop   ax  ; recover old ax

loop  loop_shifter

; done with loop..

; last digit is forced print even if 0
inc   bh

pop   ax  ; recover initial digit
mov   al, 010h
and   al, 0Fh
call  locallib_createhexnibble_
call  locallib_putchar_check_di

test   di, di
je     exit_printhex
xor    ax, ax
stosb
exit_printhex:

pop   di

ret
ENDP

_powers_of_ten_int:
dw 0000Ah  ; 10
dw 00064h  ; 100
dw 003E8h  ; 1,000
dw 02710h  ; 10,000

_powers_of_ten_long:
dd 0000186A0h  ; 100,000
dd 0000F4240h  ; 1,000,000
dd 000989680h  ; 10,000,000
dd 005F5E100h  ; 100,000,000
dd 03B9ACA00h  ; 1,000,000,000


PROC   locallib_printdecimal_ NEAR
PUBLIC locallib_printdecimal_
;void __near locallib_printdecimal (uint32_t number){
; number to print in dx:ax.   islong boolean in bx 

PUSHA_NO_AX_MACRO
xor   bp, bp
xchg  ax, cx  ; print dx:cx 
test  dx, dx
js    print_negative_long
jne   print_long
test  cx, cx
je    print_last_int_digit
jmp   print_int
print_negative_long:
push  ax
mov   al, '-'
call  locallib_putchar_
pop   ax
neg   dx
neg   ax
sbb   dx, 0

print_long:
mov   bx, 16
print_next_digit_long:
les   si, dword ptr cs:[_powers_of_ten_long + bx]
mov   di, es
xor   ax, ax  ; digit counter
sub   cx, si
sbb   dx, di
jl    skip_digit
sub_again:
inc   ax
inc   bp  ; printed at least one char
sub   cx, si
sbb   dx, di
jge   sub_again
skip_digit:
add   cx, si
adc   dx, di
test  bp, bp
je    skip_print_char
add   al, '0'
call  locallib_putchar_

skip_print_char:
sub   bx, 4
jns   print_next_digit_long


print_int:

mov   bx, 6

print_next_digit_int:
mov   dx, word ptr cs:[_powers_of_ten_int + bx]
xor   ax, ax  ; digit counter
sub   cx, dx
jl    skip_digit_int
sub_again_int:
inc   ax
inc   bp  ; printed at least one char
sub   cx, dx
jge   sub_again_int
skip_digit_int:
add   cx, dx
test  bp, bp
je    skip_print_char_int
add   al, '0'
call  locallib_putchar_

skip_print_char_int:
dec   bx
dec   bx
jns   print_next_digit_int


print_last_int_digit:
xchg  ax, cx
add   al, '0'
call  locallib_putchar_

POPA_NO_AX_MACRO
ret


ENDP




PROC   locallib_strlwr_ NEAR
PUBLIC locallib_strlwr_

push   si
xchg   ax, si
mov    ds, dx
loop_next_char_strlwr:
lodsb
test   al, al
je     done_with_strlwr
cmp    al, 'A'
jb     loop_next_char_strlwr
cmp    al, 'Z'
ja     loop_next_char_strlwr
add    al, 32
mov    byte ptr ds:[si-1], al
jmp    loop_next_char_strlwr
done_with_strlwr:
push   ss
pop    ds
pop    si

ret
ENDP

; old version, now used optimized in the single use case in g_setup
COMMENT @

PROC   locallib_strncasecmp_ NEAR
PUBLIC locallib_strncasecmp_


;int16_t __near locallib_strncasecmp(char __near *str1, char __near *str2, int16_t n){

push   si

xchg   ax, bx ; bx gets str1
xchg   ax, dx ; dx gets n
xchg   ax, si ; si gets str2

; ds:si vs ds:bx.
; n = dx 

loop_next_char_strncasecmp:
lodsb
call   locallib_toupper_
mov    ah, al
xchg   bx, si
lodsb
xchg   bx, si
call   locallib_toupper_

; ah is a
; al is b

sub    al, ah
jne    done_with_strncasecmp

test   ah, ah
mov    al, 0    ; in case we branch, we must return 0...
je     done_with_strncasecmp

dec    dx
jnz    loop_next_char_strncasecmp

done_with_strncasecmp:
cbw

pop    si

ret
ENDP

@

PROC   locallib_printstringfar_ NEAR
PUBLIC locallib_printstringfar_

mov   ds, dx
ENDP

PROC   locallib_printstringnear_ NEAR
PUBLIC locallib_printstringnear_

push  si
xchg  ax, si    ; ds:si string

print_next_string_char:
lodsb
test  al, al
je    done_printing
call  locallib_putchar_
jmp   print_next_string_char
done_printing:


push  ss
pop   ds
pop   si
ret

ENDP

PROC    DEBUG_PRINT_NOARG_CS_ NEAR
PUBLIC  DEBUG_PRINT_NOARG_CS_

mov     dx, cs

ENDP
PROC    DEBUG_PRINT_NOARG_ NEAR
PUBLIC  DEBUG_PRINT_NOARG_

ENDP
PROC    locallib_printf_ NEAR
PUBLIC  locallib_printf_


push  cx
push  si
push  di

mov   di, dx  ; backup segment in di
xchg  ax, si  

; es:si will be string
; ds:bx will be varargs

loop_next_arg_and_reset_params:
mov   es, di
loop_next_arg:
xor   cx, cx
; cl holds 'longflag'

lods  byte ptr es:[si]
test  al, al
je    done_with_printf_loop
cmp   al, 025h   ; '%'
je    handle_percent

just_print_char:
print_percent:
call  locallib_putchar_
jmp   loop_next_arg_and_reset_params

done_with_printf_loop:
pop   di
pop   si
pop   cx
ret

do_long:
inc   cx ; long flag
handle_percent:

lods  byte ptr es:[si]
test  al, al
je    done_with_printf_loop
cmp   al, 025h   ; '%'
je    print_percent
cmp   al, 04Ch   ; 'L'
je    do_long
cmp   al, 06Ch   ; 'l'
je    do_long
cmp   al, 046h   ; 'F'
je    do_long
cmp   al, 066h   ; 'f'
je    do_long

xchg  bx, si  ; set up si as varargs ptr instead of string ptr
cmp   al, 058h   ; 'X'
je    do_hex
cmp   al, 078h   ; 'x'
je    do_hex
cmp   al, 050h   ; 'P'
je    do_hex
cmp   al, 070h   ; 'p'
je    do_hex
cmp   al, 049h   ; 'I'
je    do_int
cmp   al, 069h   ; 'i'
je    do_int
cmp   al, 053h   ; 'S'
je    do_string
cmp   al, 073h   ; 's'
je    do_string
cmp   al, 043h   ; 'C'
je    do_char
cmp   al, 063h   ; 'c'
je    do_char
xchg  bx, si   ; put string ptr back
jmp   loop_next_arg

do_hex:

jcxz  do_hex_word
do_hex_long:
lodsw
xchg  ax, dx
lodsw
xchg  ax, dx
jmp   do_hex_call
do_hex_word:
lodsw
do_hex_call:

xchg  bx, si   ; put string ptr back
push  bx
xor   bx, bx
call  locallib_printhex_   ; pass is-long in cx
pop   bx
jmp   loop_next_arg_and_reset_params

do_int:
xor   dx, dx
jcxz  do_int_word

do_int_long:
lodsw       
xchg  ax, dx
lodsw       
xchg  ax, dx

jmp   do_int_call

do_int_word:
lodsw           ;  only word in ax or high word in ax and low word in dx.

do_int_call:
xchg  bx, si   ; put string ptr back
call  locallib_printdecimal_

jmp   loop_next_arg_and_reset_params



do_string:

mov   dx, ds
jcxz  do_near_string

do_far_string:
lodsw
xchg  ax, dx  
lodsw
xchg  ax, dx  
call  locallib_printstringfar_ 
xchg  bx, si   ; put string ptr back
jmp   loop_next_arg_and_reset_params

do_near_string:
lodsw
xchg  bx, si   ; put string ptr back
call  locallib_printstringnear_
jmp   loop_next_arg_and_reset_params
do_char :

lodsw  ; todo or lodsb? not sure.
xchg  bx, si   ; put string ptr back
jmp   just_print_char



ENDP






; todo these can move to init code and get safely clobbered?

PROC    locallib_dos_getvect_ NEAR
PUBLIC  locallib_dos_getvect_

push  bx
mov   ah, 035h
int   021h
xchg  ax, bx
pop   bx
mov   dx, es   ; todo get rid of this
ret

ENDP

;	AH = 25h
;	AL = interrupt number
;	DS:DX = pointer to interrupt handler

; params are ax, bx:dx, 
PROC    locallib_dos_setvect_ NEAR
PUBLIC  locallib_dos_setvect_

push  ds
mov   ds, bx
mov   ah, 025h
int   021h
pop   ds
ret

ENDP

PROC    locallib_dos_setvect_old_ NEAR
PUBLIC  locallib_dos_setvect_old_

push  ds
push  dx
mov   ds, cx
mov   dx, bx
mov   ah, 025h
int   021h
pop   dx
pop   ds
ret

ENDP

KEYBOARDINT = 9





PROC    I_ShutdownTimer_ NEAR
PUBLIC  I_ShutdownTimer_

cli
mov   al, 036h
out   043h, al
xor   ax, ax
out   040h, al
out   040h, al
sti
cmp   byte ptr ds:[_TS_Installed], al ; 0 
je    exit_shutdown_timer
push  bx
push  dx
les   dx, dword ptr ds:[_OldInt8]
mov   bx, es
mov   byte ptr ds:[_TS_Installed], al ; 0 
mov   al, 8
call  locallib_dos_setvect_
pop   dx
pop   bx
exit_shutdown_timer:
ret

ENDP

PROC    I_ShutdownKeyboard_ NEAR
PUBLIC  I_ShutdownKeyboard_

xor   ax, ax
cmp   word ptr ds:[_oldkeyboardisr], ax
je    exit_shutdown_keyboard
push  bx
push  dx
les   dx, dword ptr ds:[_oldkeyboardisr]
mov   bx, es
mov   byte ptr ds:[_oldkeyboardisr], al ; 0 
mov   al, KEYBOARDINT
call  locallib_dos_setvect_
pop   dx
pop   bx
exit_shutdown_keyboard:
xor   ax, ax
mov   es, ax
push  word ptr es:[041Ah]
pop   word ptr es:[041Ch]
exit_d_display_early:
ret

ENDP

d_display_switch_table:
dw switch_case_1
dw switch_case_2
dw switch_case_3
dw switch_case_4

do_execute_setviewsize:
call  R_ExecuteSetViewSize_
mov   byte ptr ds:[_oldgamestate], -1
mov   byte ptr ds:[_borderdrawcount], 3
jmp   done_with_execute_viewsize

do_wipe_start:
mov   ax, OVERLAY_ID_WIPE
inc   bx ; 1

call  Z_SetOverlay_

db 09Ah
dw WIPE_STARTSCREENOFFSET, CODE_OVERLAY_SEGMENT

jmp   done_zeroing_wipe


PROC    D_Display_ NEAR
PUBLIC  D_Display_


cmp   byte ptr ds:[_novideo], 0
jne   exit_d_display_early

PUSHA_NO_AX_OR_BP_MACRO

;todo: cache game state (cl?)

xor   bx, bx  ; bl is wipe state
mov   cx, bx  ; bl is wipe state
mov   cl, byte ptr ds:[_gamestate]
cmp   byte ptr ds:[_setsizeneeded], bh ; 0
jne   do_execute_setviewsize
done_with_execute_viewsize:
cmp   cl, byte ptr ds:[_wipegamestate]
jne   do_wipe_start

done_zeroing_wipe:

cmp   cl, bh ; 0
jne   dont_erase_hud
mov   ax, word ptr ds:[_gametic + 2]
or    ax, word ptr ds:[_gametic + 0]
je    dont_erase_hud
call  HU_Erase_
dont_erase_hud:
cmp   cl, 3
ja    done_with_gs_level_case

mov   si, cx
sal   si, 1
jmp   word ptr cs:[si + d_display_switch_table] 


switch_case_1:
mov   ax, word ptr ds:[_gametic + 2]
or    ax, word ptr ds:[_gametic + 0]
je    done_with_gs_level_case

cmp   byte ptr ds:[_inhelpscreensstate], bh ; 0
jne   dont_draw_automap
cmp   byte ptr ds:[_automapactive], bh ; 0
je    dont_draw_automap


db    09Ah
dw    AM_DRAWER_OFFSET, PHYSICS_HIGHCODE_SEGMENT

dont_draw_automap:
xor    ax, ax
cwd
test   bl, bl ; wipe state
jne    draw_status_bar

cmp   byte ptr ds:[_fullscreen], al ; 0
je    screen_too_big_for_statusbar
cmp   byte ptr ds:[_viewheight], SCREENHEIGHT
jne   draw_status_bar

screen_too_big_for_statusbar:
cmp   byte ptr ds:[_inhelpscreensstate], al; 0
je    fullscreen_statusbar_hidden

cmp   byte ptr ds:[_inhelpscreens], al; 0
jne   fullscreen_statusbar_hidden

draw_status_bar:
inc   dx
fullscreen_statusbar_hidden:
cmp   byte ptr ds:[_inhelpscreens], al; 0
je    helpscreen_hide_level
mov   byte ptr ds:[_skipdirectdraws], 1
helpscreen_hide_level:
cmp   byte ptr ds:[_viewheight], SCREENHEIGHT
jne   screen_too_small_for_statusbar ; ax already 0
inc   ax  ; ax is 1

screen_too_small_for_statusbar:
call  ST_Drawer_
xor   ax, ax
mov   byte ptr ds:[_skipdirectdraws], al
cmp   byte ptr ds:[_viewheight], SCREENHEIGHT
jne   fulscreen_zero
inc   ax
fulscreen_zero:
mov   byte ptr ds:[_fullscreen], al

done_with_gs_level_case:

call  I_UpdateNoBlit_
cmp   cl, bh ; 0
jne   skip_render_player_view

cmp   byte ptr ds:[_automapactive], bh ; 0
jne   skip_render_player_view

mov   ax, word ptr ds:[_gametic + 2]
or    ax, word ptr ds:[_gametic + 0]
je    skip_render_player_view

cmp   byte ptr ds:[_inhelpscreens], bh ; 0
jne   skip_render_player_view
call  dword ptr ds:[_R_RenderPlayerView]
skip_render_player_view:

cmp   cl, bh ; 0
jne   skip_hu_drawer

mov   ax, word ptr ds:[_gametic + 2]
or    ax, word ptr ds:[_gametic]
je    skip_hu_drawer

cmp   byte ptr ds:[_inhelpscreens], bh ; 0
jne   skip_hu_drawer
call  HU_Drawer_
skip_hu_drawer:


cmp   cl, byte ptr ds:[_oldgamestate]
je    skip_set_palette

jcxz  skip_set_palette
xor   ax, ax

call  I_SetPalette_

skip_set_palette:

cmp   cl, bh ; 0
jne   skip_fillbackscreen
cmp   byte ptr ds:[_oldgamestate], bh ; 0
je    skip_fillbackscreen
mov   byte ptr ds:[_viewactivestate], bh ; 0

call  R_FillBackScreen_

skip_fillbackscreen:

cmp   cl, bh ; 0
jne   skip_border_checks

cmp   byte ptr ds:[_automapactive], bh ; 0
jne   skip_border_checks

cmp   word ptr ds:[_scaledviewwidth], SCREENWIDTH
je    skip_border_checks

cmp   byte ptr ds:[_menuactive], bh ; 0
jne   set_border_draw_count
cmp   byte ptr ds:[_fullscreen], bh ; 0
jne   set_border_draw_count
cmp   byte ptr ds:[_viewactivestate], bh ; 0
jne   skip_set_border_draw_count
set_border_draw_count:

mov   byte ptr ds:[_borderdrawcount], 3
skip_set_border_draw_count:

cmp   byte ptr ds:[_borderdrawcount], bh ; 0
je    skip_border_checks

cmp   byte ptr ds:[_inhelpscreens], bh ; 0
jne   dont_draw_border
call  R_DrawViewBorder_ 
dont_draw_border:
dec   byte ptr ds:[_borderdrawcount]
cmp   byte ptr ds:[_hudneedsupdate], bh ; 0
je    skip_border_checks
inc   byte ptr ds:[_hudneedsupdate]
skip_border_checks:

mov   al, byte ptr ds:[_menuactive]
mov   byte ptr ds:[_menuactivestate], al
mov   al, byte ptr ds:[_viewactive]
mov   byte ptr ds:[_viewactivestate], al
mov   al, byte ptr ds:[_inhelpscreens]
mov   byte ptr ds:[_inhelpscreensstate], al

mov   byte ptr ds:[_wipegamestate], cl
mov   byte ptr ds:[_oldgamestate], cl

call  Z_QuickMapMenu_
cmp   byte ptr ds:[_paused], bh ; 0
je    done_pause

db 09Ah
dw M_DRAWPAUSEOFFSET, MENU_CODE_AREA_SEGMENT

done_pause:

db 09Ah
dw M_DRAWEROFFSET, MENU_CODE_AREA_SEGMENT


call  Z_QuickmapPhysics_

call  NetUpdate_

test  bl, bl
jne   do_fwipe
call  I_FinishUpdate_
exit_d_display:
 
POPA_NO_AX_OR_BP_MACRO
ret   

do_fwipe:
mov   ax, OVERLAY_ID_WIPE

call  Z_SetOverlay_

db 09Ah
dw WIPE_WIPELOOPOFFSET, CODE_OVERLAY_SEGMENT

POPA_NO_AX_OR_BP_MACRO
ret   



switch_case_2:
call  Z_QuickMapIntermission_

db 09Ah
dw WI_DRAWEROFFSET, WIANIM_CODESPACE_SEGMENT


call  Z_QuickmapPhysics_

jmp   done_with_gs_level_case
switch_case_3:
mov   ax, OVERLAY_ID_FINALE

call  Z_SetOverlay_
db 09Ah
dw F_DRAWEROFFSET, CODE_OVERLAY_SEGMENT

call  Z_QuickmapPhysics_
jmp   done_with_gs_level_case
switch_case_4:
call  D_PageDrawer_
jmp   done_with_gs_level_case




ENDP

PROC    DEBUG_PRINT_ NEAR
PUBLIC  DEBUG_PRINT_


push bx
push dx
push bp
mov  bp, sp
lea  bx, [bp + 0Ch]
mov  ax, word ptr [bp + 8]
mov  dx, word ptr [bp + 0Ah]
call locallib_printf_
pop  bp
pop  dx
pop  bx
ret


ENDP


PROC    S_PauseSound_ NEAR
PUBLIC  S_PauseSound_

xor   ax, ax
cmp   byte ptr ds:[_mus_playing], al ; 0
je    exit_pause_sound
cmp   byte ptr ds:[_mus_paused], al  ; todo put these adjacent. use a single word check
jne   exit_pause_sound

mov   byte ptr ds:[_playingstate], ST_PAUSED
cmp   byte ptr ds:[_playingdriver+3], al  ; segment high byte shouldnt be 0 if its set.
je    exit_pause_sound
push  bx
les   bx, dword ptr ds:[_playingdriver]
call  es:[bx + MUSIC_DRIVER_T.md_pausemusic_func]
pop   bx
mov   byte ptr ds:[_mus_paused], 1
exit_pause_sound:
ret  

ENDP



PROC    S_ResumeSound_ NEAR
PUBLIC  S_ResumeSound_

xor   ax, ax
cmp   byte ptr ds:[_mus_playing], al
je    exit_resume_sound
cmp   byte ptr ds:[_mus_paused], al 
je    exit_resume_sound
mov   byte ptr ds:[_playingstate], ST_PLAYING

cmp   byte ptr ds:[_playingdriver+3], al  ; segment high byte shouldnt be 0 if its set.
je    exit_pause_sound
push  bx
les   bx, dword ptr ds:[_playingdriver]
call  es:[bx + MUSIC_DRIVER_T.md_resumemusic_func]
pop bx

mov   byte ptr ds:[_mus_paused], al ; 0
exit_resume_sound:
ret

ENDP

PROC    D_MAIN_ENDMARKER_ NEAR
PUBLIC  D_MAIN_ENDMARKER_
ENDP


END
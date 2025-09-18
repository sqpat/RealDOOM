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


EXTRN fread_:FAR
EXTRN fseek_:FAR
EXTRN fopen_:FAR
EXTRN fclose_:FAR
EXTRN locallib_far_fread_:FAR
EXTRN DEBUG_PRINT_NOARG_CS_:NEAR
EXTRN M_CheckParm_:NEAR
EXTRN TS_Dispatch_:NEAR
EXTRN TS_ScheduleMainTask_:NEAR
EXTRN CopyString13_:NEAR
EXTRN I_KeyboardISR_:NEAR
EXTRN locallib_dos_getvect_:NEAR
EXTRN locallib_dos_setvect_:NEAR


.DATA

EXTRN _oldkeyboardisr:DWORD
EXTRN _novideo:BYTE
EXTRN _usemouse:BYTE
EXTRN _musdriverstartposition:BYTE


.CODE

EXTRN _doomcode_filename:BYTE

KEYBOARDINT = 9


PROC    I_INIT_STARTMARKER_ NEAR
PUBLIC  I_INIT_STARTMARKER_
ENDP


str_nomouse_option:
db "-nomouse", 0
str_mousenotpresent:
db "Mouse: not present", 0Ah, 0
str_mousedetected:
db "Mouse: detected", 0Ah, 0
str_nodraw_option:
db "-nodraw", 0
str_startup_mouse:
db "I_StartupMouse", 0Ah, 0
str_startup_keyboard:
db "I_StartupKeyboard", 0Ah, 0
str_startup_sound:
db "I_StartupSound", 0Ah, 0


_startuptimer_string:
db "I_StartupTimer()", 0Dh, 0Ah, 0




ENDP

PROC    I_Init_ NEAR
PUBLIC  I_Init_

PUSHA_NO_AX_OR_BP_MACRO
push    bp
mov     bp, sp
sub     sp, 4  ; bp - 4 is codesize



mov  ax, OFFSET str_nodraw_option
mov  dx, cs
call M_CheckParm_
mov  byte ptr ds:[_novideo], al


mov  ax,  OFFSET str_startup_mouse
call DEBUG_PRINT_NOARG_CS_


;call I_StartupMouse_
; inlined


mov  ax, OFFSET str_nomouse_option
mov   dx, cs
mov  byte ptr ds:[_mousepresent], 0
call M_CheckParm_
test ax, ax
jne  exit_startup_mouse
cmp  byte ptr ds:[_usemouse], al ; known 0
je   exit_startup_mouse

int  033h


cmp  ax, -1
mov  ax, OFFSET str_mousenotpresent
jne   mouse_not_present

mov  ax, OFFSET str_mousedetected
mov  byte ptr ds:[_mousepresent], 1
mouse_not_present:
call DEBUG_PRINT_NOARG_CS_

exit_startup_mouse:

mov  ax,  OFFSET str_startup_keyboard
call DEBUG_PRINT_NOARG_CS_



;call I_StartupKeyboard_
; inlined

mov   al, KEYBOARDINT
call  locallib_dos_getvect_
mov   word ptr ds:[_oldkeyboardisr + 0], ax
mov   word ptr ds:[_oldkeyboardisr + 2], es  
mov   al, KEYBOARDINT
mov   bx, cs
mov   dx, OFFSET I_KeyboardISR_
call  locallib_dos_setvect_



mov  ax,  OFFSET str_startup_sound
call DEBUG_PRINT_NOARG_CS_

;call I_StartupSound_
;inlined


; todo test for hw availability?



mov     ax, word ptr ds:[_snd_DesiredSfxDevice]  ; ah is music device
mov     word ptr ds:[_snd_SfxDevice], ax  ; ah is music device
mov     al, ah
cmp     al, SND_ADLIB ; 2
je      setup_adlib_mus_driver ; 2
jb      no_music_driver        ; 0/1
cmp     al, SND_PAS            
jb      setup_sb_mus_driver    ; 3
je      setup_pas_mus_driver   ; 4

cmp     al, SND_MPU
je      setup_mpu_mus_driver   ; 6
jb      setup_gus_mus_driver   ; 5
cmp     al, SND_MPU3
je      setup_mpu_mus_driver_3 ; 8
jb      setup_mpu_mus_driver_2 ; 7
cmp     al, SND_ENSONIQ
;je      setup_ensoniq_mus_driver_3 ; 0Ah
jb      setup_awe_mus_driver       ; 9
ja      setup_codec_mus_driver     ; 0Bh

; TODO unimplemented drivers below...
no_music_driver:
setup_codec_mus_driver:
setup_ensoniq_mus_driver_3:
setup_awe_mus_driver:
setup_pas_mus_driver:
setup_gus_mus_driver:
jmp   done_setting_up_mus_driver

setup_adlib_mus_driver:
;mov     bl, MUS_DRIVER_TYPE_OPL2
mov     si, ADLIBPORT
jmp     setup_mus_driver

setup_sb_mus_driver:
;mov     bl, MUS_DRIVER_TYPE_OPL3
mov     si, ADLIBPORT
jmp     setup_mus_driver

setup_mpu_mus_driver_2:
setup_mpu_mus_driver_3:
;mov     bl, MUS_DRIVER_TYPE_MPU401

mov     si, word ptr ds:[_snd_Mport]
test    si, si
jne     setup_mus_driver
mov     si, MPU401PORT
jmp     setup_mus_driver ; fall thru

setup_mpu_mus_driver:
;mov     bl, MUS_DRIVER_TYPE_SBMIDI

mov     si, word ptr ds:[_snd_SBport]
test    si, si
jne     setup_mus_driver
mov     si, SBMIDIPORT
jmp     setup_mus_driver ; fall thru




setup_mus_driver:

; si is port bl is type


mov   ax, OFFSET _doomcode_filename
call  CopyString13_
mov   dx, OFFSET  _fopen_rb_argument
call  fopen_        ; fopen("DOOMCODE.BIN", "rb"); 
mov   di, ax ; di stores fp

les   bx, dword ptr ds:[_musdriverstartposition]
mov   cx, es
xor   dx, dx  ; SEEK_SET  ; 0?
call  fseek_        ; fseek(fp, musdriverstartposition[driverindex-1], SEEK_SET);


mov   bx, 1
mov   dx, 2
lea   ax, [bp - 4] 
mov   cx, di
call  fread_        ; fread(&codesize, 2, 1, fp);


mov   cx, di                  ; fp
mov   bx, word ptr [bp - 4]  ; codesize
mov   dx, MUSIC_DRIVER_CODE_SEGMENT

xor   ax, ax        ; offset

call  locallib_far_fread_       ; locallib_far_fread(playingdriver, codesize, 1, fp);
xchg  ax, di
call  fclose_                   ; fclose(fp);

; update segments for farcalls...
mov   ax, MUSIC_DRIVER_CODE_SEGMENT
mov   word ptr ds:[_playingdriver+2], ax
mov   es, ax
push  si  ;store port
xor   di, di

mov   cx, 13

update_driver_pointer_loop:
inc   di  ;segment of ptr is offset + 2
inc   di
stosw
loop  update_driver_pointer_loop

pop   ax  ; recover port number
xor   di, di
mov   dx, di ; zero these params for inithardware call
mov   bx, dx
call  dword ptr es:[di + MUSIC_DRIVER_T.md_inithardware_func]

mov   ax, MUSIC_DRIVER_CODE_SEGMENT
mov   es, ax
call  dword ptr es:[di + MUSIC_DRIVER_T.md_initdriver_func]


done_setting_up_mus_driver:


; I_StartupTimer():
; fall thru. inlined only use


mov      ax, OFFSET _startuptimer_string
call     DEBUG_PRINT_NOARG_CS_

call     TS_ScheduleMainTask_
call     TS_Dispatch_





LEAVE_MACRO
POPA_NO_AX_OR_BP_MACRO
ret

ENDP











PROC    I_INIT_ENDMARKER_ NEAR
PUBLIC  I_INIT_ENDMARKER_
ENDP


END
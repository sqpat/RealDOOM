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


EXTRN locallib_fclose_:NEAR
EXTRN SB_Shutdown_:NEAR
EXTRN Z_QuickMapUnmapAll_:NEAR
EXTRN Z_QuickMapPhysics_:NEAR
EXTRN G_CheckDemoStatus_:NEAR
EXTRN M_SaveDefaults_:NEAR
EXTRN W_CacheLumpNameDirectFarString_:FAR
EXTRN putchar_stdout_:NEAR
EXTRN locallib_printf_:NEAR
EXTRN locallib_dos_setvect_:NEAR

EXTRN DEBUG_PRINT_:NEAR



.DATA






COLORMAPS_SIZE = 33 * 256
LUMP_PER_EMS_PAGE = 1024 

; TODO ENABLE_DISK_FLASH

.CODE

EXTRN  _TS_Installed:BYTE
EXTRN  _OldInt8:DWORD
EXTRN  _oldkeyboardisr:BYTE

PROC    I_QUIT_STARTMARKER_ NEAR
PUBLIC  I_QUIT_STARTMARKER_
ENDP


str_ENDOOM:
db "ENDOOM", 0


PROC    I_ShutdownSound_   NEAR
PUBLIC  I_ShutdownSound_

cmp  word ptr ds:[_playingdriver+2], 0
je   skip_music_unload
push bx
les  bx, dword ptr ds:[_playingdriver]

call  dword ptr es:[bx + MUSIC_DRIVER_T.md_stopmusic_func]
les  bx, dword ptr ds:[_playingdriver]
call  dword ptr es:[bx + MUSIC_DRIVER_T.md_deinithardware_func]

pop  bx

skip_music_unload:

cmp   byte ptr ds:[_snd_SfxDevice], snd_SB
jne   skip_sound_unload
call  SB_Shutdown_
skip_sound_unload:


ret


ENDP



PROC    I_ShutdownGraphics_   NEAR
PUBLIC  I_ShutdownGraphics_
    xor  ax, ax
    mov  es, ax
    cmp  byte ptr es:[0449h], 013h  ;  // don't reset mode if it didn't get set
    jne  just_exit_graphics
    mov  al, 3
    push dx
    push bx
    cwd
    xor  bx, bx
    int 010h            ; // back to text mode

    pop  bx
    pop  dx
    
    just_exit_graphics:
    ret

ENDP




PROC    Z_ShutdownEMS_   NEAR
PUBLIC  Z_ShutdownEMS_

IFDEF COMP_CH
    call Z_QuickMapUnmapAll_
ELSE
    cmp   word ptr ds:[_emshandle], 0
    je    skip_unmap
    cmp   byte ptr ds:[_emsconventional], 0
    je    skip_unmap
        push  dx
        call  Z_QuickMapUnmapAll_
        mov   ax, 04500h
        mov   dx, word ptr ds:[_emshandle]
        int   067h
        test  ah, ah
        jne   do_unmap_error


        pop   dx


    skip_unmap:
    ret

    do_unmap_error:
        mov   al, ah
        xor   ah, ah
        push  ax  ; todo order?
        push  cs
        mov   dx, OFFSET _str_ems_unmap_error
        push  dx
        call  DEBUG_PRINT_
        pop   dx
        add   sp, 6
    ret
    _str_ems_unmap_error:
    db "Failed deallocating EMS memory! %i!", 0Ah, 0

ENDIF




ENDP


ENDP


PROC zeroConventional_ NEAR
PUBLIC zeroConventional_

cli

push cx
push di

xor  ax, ax
mov  di, ax

mov  cx, 04000h
mov  es, cx
mov  cx, 08000h
rep  stosw

mov  cx, 05000h
mov  es, cx
mov  cx, 08000h
rep  stosw

mov  cx, 06000h
mov  es, cx
mov  cx, 08000h
rep  stosw

mov  cx, 07000h
mov  es, cx
mov  cx, 08000h
rep  stosw

mov  cx, 08000h
mov  es, cx
mov  cx, 08000h
rep  stosw

mov  cx, 09000h
mov  es, cx
mov  cx, 08000h
rep  stosw

pop di
pop cx
sti


ret

ENDP

PROC   I_ShutdownWads_ NEAR
PUBLIC I_ShutdownWads_


push bx
push dx

xor  bx, bx

cmp   bl, byte ptr ds:[_currentloadedfileindex]
jge   skip_wad_unload
loop_wad_unload:
shl   bx, 1   ; word lookup
mov   ax, word ptr ds:[_wadfiles + bx]
test  ax, ax
je    skip_fclose_wadfile
call  locallib_fclose_

skip_fclose_wadfile:
shr   bx, 1
inc   bx
cmp   bl, byte ptr ds:[_currentloadedfileindex]
jl    loop_wad_unload

skip_wad_unload:

xor  dx, dx
pop dx
pop bx



ret
ENDP


PROC    CallQuitFunctions_  NEAR

call  I_ShutdownGraphics_
call  I_ShutdownSound_
;call  I_ShutdownTimer_

cli
mov   al, 036h
out   043h, al
xor   ax, ax
out   040h, al
out   040h, al
sti
cmp   byte ptr cs:[_TS_Installed], al ; 0 
je    exit_shutdown_timer
push  bx
push  dx
les   dx, dword ptr cs:[_OldInt8]
mov   bx, es
mov   byte ptr cs:[_TS_Installed], al ; 0 
mov   al, 8
call  locallib_dos_setvect_
pop   dx
pop   bx
exit_shutdown_timer:


;call  I_ShutdownMouse_
xor   ax, ax

cmp   byte ptr ds:[_mousepresent], al
je    just_exit
; ax 0
int   033h
just_exit:


;call  I_ShutdownKeyboard_
KEYBOARDINT = 9


xor   ax, ax
cmp   word ptr cs:[_oldkeyboardisr], ax
je    exit_shutdown_keyboard
push  bx
push  dx
les   dx, dword ptr cs:[_oldkeyboardisr]
mov   bx, es
;mov   byte ptr cs:[_oldkeyboardisr], al ; 0 
mov   al, KEYBOARDINT
call  locallib_dos_setvect_
pop   dx
pop   bx
exit_shutdown_keyboard:
xor   ax, ax
mov   es, ax
push  word ptr es:[041Ah]
pop   word ptr es:[041Ch]



test  dx, dx
je    skip_enddoom

    push  bx
    push  cx

    mov  ax, OFFSET str_ENDOOM
    mov  dx, cs
    mov  cx, 0B800h
    xor  bx, bx
    call W_CacheLumpNameDirectFarString_ ; ("ENDOOM", (byte __far *)0xb8000000);

    mov ax, 00200h
    xor bx, bx
    mov dx, 02300h
    int 010h        ; // Set text pos

    mov  al, 0Ah  ; newline
    call putchar_stdout_


    pop   cx
    pop   bx

    call I_ShutdownWads_

skip_enddoom:


call  Z_ShutdownEMS_
call  zeroConventional_; // zero conventional. clears various bugs that assume 0 in memory. kind of bad practice, the bugs shouldnt happen... todo fix
;call  hackDSBack_ 
; inlined

cli
push cx
push si
push di

mov cx, DGROUP
mov es, cx

xor di, di
mov si, di
mov CX, 1000h   ; 2000h bytes
rep movsw
mov cx, es
mov ds, cx
mov ss, cx

pop di
pop si
pop cx

sti

ret

ENDP



PROC    I_Quit_   FAR
PUBLIC  I_Quit_

push  dx

call Z_QuickMapPhysics_
cmp  byte ptr ds:[_demorecording], 0
je   dont_check_demo_status
call G_CheckDemoStatus_
dont_check_demo_status:

call M_SaveDefaults_

mov  dx, 1
call CallQuitFunctions_


mov   ax, 1
jmp   exit_


ENDP



; todo jump to instead of exit
PROC   I_Error_ FAR
PUBLIC I_Error_


;call I_Shutdown_ inlined
call I_ShutdownWads_
xor  dx, dx
call CallQuitFunctions_


pop  ax  ; ip
pop  ax  ; cs
pop  ax  ; str off
pop  dx  ; str seg
mov  bx, sp  ; args ptr
call locallib_printf_
mov  al, 0Ah  ; newline
call putchar_stdout_
mov  ax, 1
jmp  exit_

ENDP


_NULL_AREA_STR:
db "!!", 020h, "NULL area write detected"

_NEWLINE_STR:
db 0Dh, 0Ah , 0

_CON_STR:
db "con", 0




; todo clean up triple exit function stuff..

PROC    exit_   NEAR
PUBLIC  exit_


push  ax                        ; al = return code.
mov   dx, DGROUP  ; worst case call getds
mov   ds, dx

; fall thru


cld        
xor        di, di   ; di = null area
mov        es, dx
mov        cx, 08h
mov        ax, 0101h
repe       scasw
jne        null_check_fail

null_check_ok:

pop        ax
mov        ah, 04Ch  ; Terminate process with return code
int        021h


null_check_fail:
pop        bx
mov        ax, OFFSET _NULL_AREA_STR
mov        dx, cs

__do_exit_with_msg_:
__exit_with_msg_:
PUBLIC __do_exit_with_msg_
PUBLIC __exit_with_msg_

push       bx
push       ax
push       dx
mov        di, cs
mov        ds, di
mov        dx, OFFSET _CON_STR
mov        ax, 03D01h        ; get console file handle into bx
int        021h
mov        bx, ax
pop        ds
pop        dx
mov        si, dx
cld        
loop_find_end_of_string:
lodsb      
test       al, al
jne        loop_find_end_of_string
mov        cx, si
sub        cx, dx
dec        cx
mov        ah, 040h  ; Write file or device using handle
int        021h
mov        ds, di   ; cs
mov        dx, OFFSET _NEWLINE_STR
mov        cx, 2
mov        ah, 040h  ; Write file or device using handle
int        021h


ENDP





PROC    I_QUIT_ENDMARKER_ NEAR
PUBLIC  I_QUIT_ENDMARKER_
ENDP




END
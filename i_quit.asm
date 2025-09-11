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


EXTRN fclose_:FAR
EXTRN SB_Shutdown_:NEAR
EXTRN Z_QuickMapUnmapAll_:NEAR
EXTRN Z_QuickMapPhysics_:FAR
EXTRN G_CheckDemoStatus_:NEAR
EXTRN M_SaveDefaults_:NEAR
EXTRN W_CacheLumpNameDirectFarString_:FAR
EXTRN I_ShutdownTimer_:NEAR
EXTRN I_ShutdownKeyboard_:NEAR


EXTRN DEBUG_PRINT_:FAR
EXTRN exit_:FAR


.DATA

EXTRN _wadfiles:WORD
EXTRN _mousepresent:BYTE
EXTRN _currentloadedfileindex:BYTE
EXTRN _demorecording:BYTE




COLORMAPS_SIZE = 33 * 256
LUMP_PER_EMS_PAGE = 1024 

; TODO ENABLE_DISK_FLASH

.CODE


PROC    I_QUIT_STARTMARKER_ NEAR
PUBLIC  I_QUIT_STARTMARKER_
ENDP


str_ENDOOM:
db "ENDOOM", 0


PROC    I_ShutdownSound_   NEAR
PUBLIC  I_ShutdownSound_

cmp  word ptr ds:[_playingdriver], 0
je   skip_music_unload
push bx
les  bx, dword ptr ds:[_playingdriver]

call  dword ptr es:[bx + MUSIC_DRIVER_T.md_stopmusic_func]
les  bx, dword ptr ds:[_playingdriver]
call  dword ptr es:[bx + MUSIC_DRIVER_T.md_deinithardware_func]

pop  bx

skip_music_unload:

cmp   word ptr ds:[_snd_SfxDevice], snd_SB
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



PROC    I_ShutdownMouse_   NEAR
PUBLIC  I_ShutdownMouse_

    cmp   byte ptr ds:[_mousepresent], 0
    je    just_exit
    xor   ax, ax
    int   033h
    just_exit:
    ret

ENDP


PROC    Z_ShutdownEMS_   NEAR
PUBLIC  Z_ShutdownEMS_

IFDEF COMP_CH
    call Z_QuickMapUnmapAll_
ELSE
    cmp   word ptr ds:[_emshandle], 0
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
        add   sp, 4   ; or 6?
    ret
    _str_ems_unmap_error:
    db "Failed deallocating EMS memory! %i!", 0Ah, 0

ENDIF




ENDP


PROC    I_Shutdown_   NEAR
PUBLIC  I_Shutdown_

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
call  fclose_

skip_fclose_wadfile:
shr   bx, 1
inc   bx
cmp   bl, byte ptr ds:[_currentloadedfileindex]
jl    loop_wad_unload

skip_wad_unload:

xor  dx, dx

call CallQuitFunctions_

pop dx
pop bx
ret
	


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

PROC hackDSBack_ NEAR
PUBLIC hackDSBack_

cli
push cx
push si
push di

mov es, ds:[_stored_ds]

xor di, di
mov si, di
mov CX, 2000h   ; 4000h bytes
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

PROC    CallQuitFunctions_  NEAR

call  I_ShutdownGraphics_
call  I_ShutdownSound_
call  I_ShutdownTimer_
call  I_ShutdownMouse_
call  I_ShutdownKeyboard_
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

    pop   cx
    pop   bx


skip_enddoom:
call  Z_ShutdownEMS_
call  zeroConventional_; // zero conventional. clears various bugs that assume 0 in memory. kind of bad practice, the bugs shouldnt happen... todo fix
call  hackDSBack_

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
call  exit_

pop   dx


retf

ENDP

PROC    I_QUIT_ENDMARKER_ NEAR
PUBLIC  I_QUIT_ENDMARKER_
ENDP




END



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


EXTRN locallib_putchar_:NEAR
EXTRN locallib_printf_:NEAR
EXTRN I_Shutdown_:NEAR
EXTRN exit_:FAR
EXTRN I_SetPalette_:FAR
EXTRN D_PostEvent_:NEAR

.DATA

EXTRN _grmode:BYTE
EXTRN _novideo:BYTE

; TODO ENABLE_DISK_FLASH

.CODE


PROC    I_IBM_STARTMARKER_ NEAR
PUBLIC  I_IBM_STARTMARKER_
ENDP


STATUS_REGISTER_1  = 03DAh

PROC    I_WaitVBL_ FAR
PUBLIC  I_WaitVBL_

cmp     byte ptr ds:[_novideo], 0
jne     return_early
push    dx
push    cx
xchg    ax, cx ; cx gets count
mov     dx, STATUS_REGISTER_1

loop_next_vbl:
in      al, dx
test    al, 8
jne     got_flag_8
jmp     loop_next_vbl

got_flag_8:

loop_next_vbl_2:
in      al, dx
test    al, 8
je      cleared_flag_8
jmp     loop_next_vbl_2

cleared_flag_8:


loop    loop_next_vbl


pop     cx
pop     dx
return_early:
retf

ENDP

PROC    I_ReadMouse_ NEAR
PUBLIC  I_ReadMouse_

push    bx
push    cx
push    dx
push    di
push    bp
mov     bp, sp
sub     sp, SIZE EVENT_T
mov     byte ptr [bp - SIZE EVENT_T + EVENT_T.event_evtype], EV_MOUSE
mov     ax, 0Bh
int     033h

xchg    ax, bx
lea     di, [bp - SIZE EVENT_T + EVENT_T.event_data1]
push    ss
pop     es
stosw
xor     ax, ax
stosw
xchg    ax, cx 
stosw   ; data 2
xchg    ax, cx
stosw   ; data 2
stosw   ; data 3
stosw   ; data 3

; TODO: event_t should be words?
; data3 isnt even used...



mov     ax, sp
call    D_PostEvent_

pop     di
pop     dx
pop     cx
pop     bx
ret

ENDP



; todo make near
; todo eventually jump to instead of call. 
PROC   I_Error_ FAR
PUBLIC I_Error_

push bx
push dx
push bp
mov  bp, sp
call I_Shutdown_
lea  bx, [bp + 0Eh]
mov  ax, word ptr [bp + 0Ah]
mov  dx, word ptr [bp + 0Ch]
call locallib_printf_
mov  ax, 0Ah
call locallib_putchar_
mov  ax, 1
jmp  exit_

;doesnt work, figure it out..
COMMENT @

call I_Shutdown_
pop  ax  ; ip
pop  ax  ; cs
pop  ax  ; str off
pop  dx  ; str seg
lea  bx, [bp]  ; args ptr
call locallib_printf_
mov  al, 0Ah  ; newline
call locallib_putchar_
mov  ax, 1
jmp  exit_
@
ENDP



PROC   I_InitGraphics_ NEAR
PUBLIC I_InitGraphics_

cmp     byte ptr ds:[_novideo], 0
jne     return_early_near

push   bx
push   cx
push   dx
push   di


mov    ax, 013h
cwd
xor    bx, bx
int    010h
mov    ax, 1
cwd
mov    byte ptr ds:[_grmode], al ; true
mov    word ptr ds:[_currentscreen+0], dx 
mov    cx, 0A000h
mov    es, cx
mov    word ptr ds:[_currentscreen+2], cx 
mov    word ptr ds:[_destscreen+2], cx 
mov    ch, 040h
mov    word ptr ds:[_destscreen+0], cx 

mov    dx, SC_INDEX  ; 03C4h
mov    al, 4 ; SC_MEMMODE
out    dx, al

inc    dx
in     al, dx
and    al, NOT 8
or     al, 4
out    dx, al   ; outp(SC_INDEX + 1, (inp(SC_INDEX + 1)&~8) | 4);

mov    dx, GC_INDEX ; 03Ceh
mov    al, GC_MODE  ; 5
out    dx, al

inc    dx
in     al, dx
and    al, NOT 13
out    dx, al   ; GC_INDEX + 1, inp(GC_INDEX + 1)&~0x13);

dec    dx
mov    al , 6; GC_MISCELLANEOUS
out    dx, al

inc    dx
in     al, dx
and    al, NOT 2
out    dx, al   ; outp(GC_INDEX + 1, inp(GC_INDEX + 1)&~2);

mov    dx, SC_INDEX  ; 03C4h
mov    ax, 0F02h
out    dx, ax

; cx still 04000
shl    cx, 1
xor    ax, ax
mov    di, ax
rep    stosw        ; FAR_memset(currentscreen, 0, 0xFFFFu);

mov    dx, CRTC_INDEX
mov    al, 20; CRTC_UNDERLINE
out    dx, al

inc    dx
in     al, dx
and    al, NOT 040h
out    dx, al   ; inp(CRTC_INDEX + 1)&~0x40

dec    dx
mov    al, 23; CRTC_MODE
out    dx, al

inc    dx
in     al, dx
or     al, 040h
out    dx, al   ; inp(CRTC_INDEX + 1) | 0x40)

mov    dx, GC_INDEX
mov    al, GC_READMAP
out    dx, al

xor    ax, ax
call   I_SetPalette_

; call I_InitDiskFlash_  ; todo

pop    di
pop    dx
pop    cx
pop    bx
return_early_near:
ret
ENDP

PROC    I_IBM_ENDMARKER_ NEAR
PUBLIC  I_IBM_ENDMARKER_
ENDP


END
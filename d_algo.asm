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


.CODE

EXTRN __GETDS:WORD;



PROC resetDS_ NEAR
PUBLIC resetDS_

;todo is ax necessary? if 286+ can push immediate.
push ax
mov ax, FIXED_DS_SEGMENT
mov ds, ax
pop ax

ret
endp


PROC hackDS_ NEAR
PUBLIC hackDS_

;todo: make cli held for less time

cli
push cx
push si
push di

mov ds:[_stored_ds], ds
xor di, di
mov si, di
mov cx, FIXED_DS_SEGMENT

;mov cx, ds
;add cx, 400h
mov es, cx

mov CX, 2000h    ; 4000h bytes
rep movsw

mov cx, es
mov ds, cx
mov ss, cx

mov word ptr cs:[__GETDS+2], cx

;extern uint16_t __near* _GETDS;
;	((uint16_t __near*)(&_GETDS))[1] = FIXED_DS_SEGMENT;




pop di
pop si
pop cx




sti



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


; nice for debug... 
COMMENT @

PROC getSPBP_ NEAR
PUBLIC getSPBP_

mov dx, sp
mov ax, bp


ret


PROC getDSSS_ NEAR
PUBLIC getDSSS_

mov dx, ds
mov ax, ss


ret

@

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

; end marker for this asm file
PROC D_ALGO_END_ NEAR
PUBLIC D_ALGO_END_ 
ENDP


END
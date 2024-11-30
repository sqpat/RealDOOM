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


.CODE



PROC resetDS_ FAR
PUBLIC resetDS_

;todo is ax necessary? if 286+ can push immediate.
push ax
mov ax, 03C00h
mov ds, ax
pop ax

retf
endp


PROC hackDS_ FAR
PUBLIC hackDS_

;todo: make cli held for less time

cli
push cx
push si
push di

mov ds:[_stored_ds], ds
xor di, di
mov si, di
mov cx, 03C00h

;mov cx, ds
;add cx, 400h
mov es, cx

mov CX, 2000h    ; 4000h bytes
rep movsw

mov cx, es
mov ds, cx
mov ss, cx

COMMENT @

;; clear out BASE_LOWER_MEMORY_SEGMENT. Not needed? if we do this then push/pop ax!
push ax
mov cx, BASE_LOWER_MEMORY_SEGMENT
mov es, cx

; zero up till 3C00h
mov cx, 03C00h
sub cx, BASE_LOWER_MEMORY_SEGMENT
sal cx, 1 ; 16 bytes per paragraphs divided by 2 (word writes) = shift 8
sal cx, 1
sal cx, 1 
xor ax, ax
mov di, ax
rep stosw
pop ax
@

pop di
pop si
pop cx




sti



retf

ENDP





PROC hackDSBack_ FAR
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



retf

ENDP



END


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


EXTRN V_DrawPatchDirect_:FAR
EXTRN locallib_toupper_:NEAR
EXTRN R_VideoErase_:NEAR


SHORTFLOORBITS = 3

.DATA




.CODE



PROC    HULIB_STARTMARKER NEAR
PUBLIC  HULIB_STARTMARKER
ENDP




PROC    HUlib_addStringToTextLine_ NEAR
PUBLIC  HUlib_addStringToTextLine_


;void __near HUlib_addStringToTextLine(hu_textline_t  __near*textline, int8_t* __far str){	


push  bx
push  si
push  di
mov   bx, ax
mov   di, dx
mov   si, dx
cmp   byte ptr ds:[di], 0
je    label_1
label_3:
mov   ax, word ptr ds:[bx + HU_TEXTLINE_T.hu_textline_len]
cmp   ax, HU_MAXLINELENGTH
jne   label_2
add   bx, ax
mov   byte ptr ds:[bx + HU_TEXTLINE_T.hu_textline_characters], 0
pop   di
pop   si
pop   bx
ret   

label_2:
mov   al, byte ptr ds:[si]
xor   ah, ah
call  locallib_toupper_
mov   dl, al
mov   ax, word ptr ds:[bx + HU_TEXTLINE_T.hu_textline_len]
mov   di, ax
inc   di
mov   word ptr ds:[bx + HU_TEXTLINE_T.hu_textline_len], di
mov   di, bx
add   di, ax
mov   byte ptr ds:[di + HU_TEXTLINE_T.hu_textline_characters], dl
inc   si
mov   byte ptr ds:[bx + HU_TEXTLINE_T.hu_textline_needsupdate], 4
cmp   byte ptr ds:[si], 0
jne   label_3
label_1:
add   bx, word ptr ds:[bx + HU_TEXTLINE_T.hu_textline_len]
mov   byte ptr ds:[bx + HU_TEXTLINE_T.hu_textline_characters], 0
pop   di
pop   si
pop   bx
ret   

ENDP




PROC    HUlib_drawTextLine_ NEAR
PUBLIC  HUlib_drawTextLine_




push  bx
push  cx
push  dx
push  si
push  di
push  bp
mov   bp, sp
sub   sp, 4
mov   si, ax
mov   word ptr [bp - 2], 0
mov   ax, word ptr ds:[si]
cmp   word ptr ds:[si + HU_TEXTLINE_T.hu_textline_len], 0
jle   exit_hulib_drawtextline
mov   di, si
label_5:
mov   dl, byte ptr ds:[di + HU_TEXTLINE_T.hu_textline_characters]
cmp   dl, ' '
je    iter_next_drawtextline
cmp   dl, byte ptr ds:[si + 4]
jb    iter_next_drawtextline
cmp   dl, '_'
ja    iter_next_drawtextline
mov   bl, byte ptr ds:[si + 4]
xor   dh, dh
xor   bh, bh
sub   dx, bx
mov   bx, dx
add   bx, dx
mov   dx, ST_GRAPHICS_SEGMENT
mov   bx, word ptr ds:[bx + _hu_font]
mov   es, dx
mov   cx, ax
mov   dx, word ptr es:[bx]
add   cx, dx
mov   word ptr [bp - 4], cx
cmp   cx, SCREENWIDTH
jg    exit_hulib_drawtextline
mov   cx, es
mov   dx, word ptr ds:[si + 2]

call  V_DrawPatchDirect_
mov   ax, word ptr [bp - 4]
label_4:
inc   word ptr [bp - 2]
mov   dx, word ptr [bp - 2]
inc   di
cmp   dx, word ptr ds:[si + HU_TEXTLINE_T.hu_textline_len]
jl    label_5
exit_hulib_drawtextline:

LEAVE_MACRO 
pop   di
pop   si
pop   dx
pop   cx
pop   bx
ret   
iter_next_drawtextline:
add   ax, 4
cmp   ax, SCREENWIDTH
jge   exit_hulib_drawtextline
jmp   label_4


ENDP




PROC    HUlib_eraseTextLine_ NEAR
PUBLIC  HUlib_eraseTextLine_

push  bx
push  cx
push  dx
push  si
push  di
push  bp
mov   bp, sp
push  ax
cmp   byte ptr ds:[_automapactive], 0
jne   label_6
cmp   word ptr ds:[_viewwindowx], 0
je    label_6
mov   bx, ax
cmp   byte ptr ds:[bx + HU_TEXTLINE_T.hu_textline_needsupdate], 0
je    label_6
mov   cx, word ptr ds:[bx + 2]
imul  bx, cx, SCREENWIDTH
label_9:
mov   si, word ptr [bp - 2]
mov   ax, word ptr ds:[si + 2]
add   ax, 8
cmp   cx, ax
jae   label_6
cmp   cx, word ptr ds:[_viewwindowy]
jae   label_7
label_8:
mov   dx, SCREENWIDTH
mov   ax, bx
label_10:
push  cs
call  R_VideoErase_
inc   cx
add   bx, SCREENWIDTH
jmp   label_9
label_7:
mov   di, si
mov   ax, word ptr ds:[di]
add   ax, word ptr ds:[_viewheight]
cmp   cx, ax
jae   label_8

mov   ax, bx
mov   dx, word ptr ds:[_viewwindowx]
push  cs
call  R_VideoErase_
mov   dx, word ptr ds:[_viewwindowx]
mov   ax, dx

add   ax, bx
add   ax, word ptr ds:[_viewwidth]
jmp   label_10
label_6:
mov   bx, word ptr [bp - 2]
cmp   byte ptr ds:[bx + HU_TEXTLINE_T.hu_textline_needsupdate], 0
jne   label_11
LEAVE_MACRO 
pop   di
pop   si
pop   dx
pop   cx
pop   bx
ret   
label_11:
dec   byte ptr ds:[bx + HU_TEXTLINE_T.hu_textline_needsupdate]
LEAVE_MACRO 
pop   di
pop   si
pop   dx
pop   cx
pop   bx
ret   

ENDP




PROC    HUlib_addMessageToSText_ NEAR
PUBLIC  HUlib_addMessageToSText_


push  bx
push  cx
push  dx
push  si
mov   cx, ax
mov   si, _w_message
inc   byte ptr ds:[si + HU_STEXT_T.hu_stext_currentline]
mov   al, byte ptr ds:[si + HU_STEXT_T.hu_stext_currentline]
cmp   al, byte ptr ds:[si + HU_STEXT_T.hu_stext_height]
je    label_12
label_15:
mov   al, byte ptr ds:[si + HU_STEXT_T.hu_stext_currentline]
cbw  
imul  ax, ax, SIZEOF_HUTEXTLINE_T
mov   bx, si
add   bx, ax
mov   word ptr ds:[bx + HU_TEXTLINE_T.hu_textline_len], 0
mov   byte ptr ds:[bx + HU_TEXTLINE_T.hu_textline_characters], 0
xor   dx, dx
mov   byte ptr ds:[bx + HU_TEXTLINE_T.hu_textline_needsupdate], 1
mov   bx, si
label_13:
mov   al, byte ptr ds:[si + HU_STEXT_T.hu_stext_height]
cbw  
cmp   dx, ax
jge   label_14
add   bx, SIZEOF_HUTEXTLINE_T
inc   dx
mov   byte ptr ds:[bx - 1], 4
jmp   label_13
label_12:
mov   byte ptr ds:[si + HU_STEXT_T.hu_stext_currentline], 0
jmp   label_15
label_14:
mov   al, byte ptr ds:[si + HU_STEXT_T.hu_stext_currentline]
cbw  
imul  ax, ax, SIZEOF_HUTEXTLINE_T
mov   dx, cx
add   ax, si

call  HUlib_addStringToTextLine_
mov   byte ptr ds:[_hudneedsupdate], 4
pop   si
pop   dx
pop   cx
pop   bx
ret   

ENDP



PROC    HULIB_ENDMARKER NEAR
PUBLIC  HULIB_ENDMARKER
ENDP

END 
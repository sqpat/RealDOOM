

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


EXTRN HUlib_drawTextLine_:NEAR
EXTRN HUlib_eraseTextLine_:NEAR
EXTRN HUlib_addMessageToSText_:NEAR
EXTRN Z_QuickMapStatus_:FAR
EXTRN Z_QuickMapPhysics_:FAR
EXTRN getStringByIndex_:FAR

.DATA




.CODE



HU_MSGTIMEOUT = 4 * TICRATE
HU_MSGREFRESH = KEY_ENTER

PROC    HU_STUFF_STARTMARKER_ NEAR
PUBLIC  HU_STUFF_STARTMARKER_
ENDP



PROC    HU_Drawer_ NEAR
PUBLIC  HU_Drawer_

push  bx
push  cx
push  dx
push  si
mov   si, _w_message
mov   bx, word ptr ds:[si + HU_STEXT_T.hu_stext_onptr]
xor   cl, cl
cmp   byte ptr ds:[bx], 0
je    exit_hu_drawer
mov   bx, _hudneedsupdate
cmp   byte ptr ds:[bx], 0
je    label_1
label_6:
xor   dx, dx
label_5:
mov   al, byte ptr ds:[si + HU_STEXT_T.hu_stext_height]
cbw  
mov   bx, ax
cmp   dx, ax
jge   label_2
mov   al, byte ptr ds:[si + HU_STEXT_T.hu_stext_currentline]
cbw  
sub   ax, dx
test  ax, ax
jl    label_3
label_11:
imul  ax, ax, SIZEOF_HUTEXTLINE_T
mov   bx, si
add   bx, ax
test  cl, cl
je    label_4
label_8:
mov   ax, bx
call  HUlib_drawTextLine_
inc   dx
jmp   label_5
label_1:
mov   bx, _automapactive
cmp   byte ptr ds:[bx], 0
jne   label_6
mov   bx, _screenblocks
cmp   byte ptr ds:[bx], 10
jae   label_6
label_9:
mov   bx, _automapactive
cmp   byte ptr ds:[bx], 0
jne   label_7
test  cl, cl
jne   label_10
exit_hu_drawer:
pop   si
pop   dx
pop   cx
pop   bx
ret   
label_3:
add   ax, bx
jmp   label_11
label_4:
call  Z_QuickMapStatus_
mov   cl, 1
jmp   label_8
label_2:
mov   bx, _hudneedsupdate
dec   byte ptr ds:[bx]
jmp   label_9
label_7:
call  Z_QuickMapStatus_
mov   ax, _w_title
call  HUlib_drawTextLine_
label_10:
call  Z_QuickmapPhysics_
pop   si
pop   dx
pop   cx
pop   bx
ret   

ENDP



PROC    HU_Erase_ NEAR
PUBLIC  HU_Erase_


push  bx
push  dx
push  si
mov   dx, _w_message
xor   bx, bx
label_14:
mov   si, _w_message + HU_STEXT_T.hu_stext_height
mov   al, byte ptr ds:[si]
cbw  
cmp   bx, ax
jge   label_12
mov   si, _w_message + HU_STEXT_T.hu_stext_laston
cmp   byte ptr ds:[si], 0
jne   label_13
label_15:
mov   ax, dx
call  HUlib_eraseTextLine_
inc   bx
add   dx, SIZEOF_HUTEXTLINE_T
jmp   label_14
label_13:
mov   si, _w_message + HU_STEXT_T.hu_stext_onptr
mov   si, word ptr ds:[si]
cmp   byte ptr ds:[si], 0
jne   label_15
imul  si, bx, SIZEOF_HUTEXTLINE_T
mov   byte ptr ds:[si + OFFSET _w_message + HU_TEXTLINE_T.hu_textline_needsupdate], 4
jmp   label_15
label_12:
mov   bx, _w_message + HU_STEXT_T.hu_stext_onptr
mov   si, word ptr ds:[bx]
mov   bx, _w_message + HU_STEXT_T.hu_stext_laston
mov   al, byte ptr ds:[si]
mov   byte ptr ds:[bx], al
mov   ax, _w_title
call  HUlib_eraseTextLine_
pop   si
pop   dx
pop   bx
ret   


ENDP



PROC    HU_Ticker_ NEAR
PUBLIC  HU_Ticker_


push  bx
push  cx
push  si
push  bp
mov   bp, sp
sub   sp, 0100h
mov   bx, _message_counter
cmp   byte ptr ds:[bx], 0
jne   label_16
label_21:
mov   bx, _showMessages
cmp   byte ptr ds:[bx], 0
je    label_17
label_22:
mov   bx, _player + PLAYER_T.player_messagestring
cmp   word ptr ds:[bx], 0
je    label_18
label_24:
mov   bx, _message_nottobefuckedwith
cmp   byte ptr ds:[bx], 0
jne   label_19
label_25:
mov   bx, _player + PLAYER_T.player_message
mov   ax, word ptr ds:[bx]
cmp   ax, -1
je    jump_to_label_20
lea   bx, [bp - 0100h]
mov   cx, ds

call  getStringByIndex_

lea   ax, [bp - 0100h]
mov   bx, _player + PLAYER_T.player_message
call  HUlib_addMessageToSText_
mov   word ptr ds:[bx], -1
label_23:
mov   bx, _message_on
mov   byte ptr ds:[bx], 1
mov   bx, _message_counter
mov   si, _message_dontfuckwithme
mov   byte ptr ds:[bx], HU_MSGTIMEOUT
mov   bx, _message_nottobefuckedwith
mov   al, byte ptr ds:[si]
mov   byte ptr ds:[bx], al
mov   byte ptr ds:[si], 0
exit_hu_ticker:
LEAVE_MACRO 
pop   si
pop   cx
pop   bx
ret   
label_16:
dec   byte ptr ds:[bx]
mov   al, byte ptr ds:[bx]
test  al, al
jne   label_21
mov   bx, _message_on
mov   byte ptr ds:[bx], al
mov   bx, _message_nottobefuckedwith
mov   byte ptr ds:[bx], al
jmp   label_21
label_17:
mov   bx, _message_dontfuckwithme
cmp   byte ptr ds:[bx], 0
jne   label_22
jmp   exit_hu_ticker
jump_to_label_20:
jmp   label_20
label_18:
mov   bx, _player + PLAYER_T.player_message
cmp   word ptr ds:[bx], -1
jne   label_24
label_19:
mov   bx, _player + PLAYER_T.player_message
cmp   word ptr ds:[bx], 0
je    exit_hu_ticker
mov   bx, _message_dontfuckwithme
cmp   byte ptr ds:[bx], 0
jne   label_25
LEAVE_MACRO 
pop   si
pop   cx
pop   bx
ret   
label_20:
mov   bx, _player + PLAYER_T.player_messagestring
mov   ax, word ptr ds:[bx]
call  HUlib_addMessageToSText_
mov   word ptr ds:[bx], 0
jmp   label_23


ENDP

PROC    HU_Responder_ NEAR
PUBLIC  HU_Responder_

push  bx
xchg  ax, bx
mov   es, dx
xor   ax, ax
cmp   word ptr es:[bx + EVENT_T.event_data1 + 2], ax
jne   not_rshift
cmp   word ptr es:[bx + EVENT_T.event_data1], KEY_RSHIFT
je    exit_hu_responder
not_rshift:
cmp   word ptr es:[bx + EVENT_T.event_data1 + 2], ax
jne   not_alt
cmp   word ptr es:[bx + EVENT_T.event_data1], KEY_RALT
je    exit_hu_responder
not_alt:
cmp   byte ptr es:[bx + EVENT_T.event_evtype], al   ; EV_KEYDOWN
jne   exit_hu_responder
cmp   word ptr es:[bx + EVENT_T.event_data1 + 2], ax
jne   exit_hu_responder
cmp   word ptr es:[bx + EVENT_T.event_data1], HU_MSGREFRESH
jne   exit_hu_responder
inc   ax
mov   byte ptr ds:[_message_on], al
mov   byte ptr ds:[_message_counter], HU_MSGTIMEOUT
exit_hu_responder:
pop   bx
ret   




ENDP



PROC    HU_STUFF_ENDMARKER_ NEAR
PUBLIC  HU_STUFF_ENDMARKER_
ENDP

END 
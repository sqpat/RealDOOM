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


EXTRN HUlib_addStringToTextLine_:NEAR
EXTRN getStringByIndex_:FAR

.DATA




.CODE



HU_MSGTIMEOUT = 4 * TICRATE
HU_MSGREFRESH = KEY_ENTER

PROC    HU_SETUP_STARTMARKER_ FAR
PUBLIC  HU_SETUP_STARTMARKER_
ENDP

HUD_FONTHEIGHT = 7
HU_MSGX = 0
HU_MSGY = 0
HU_TITLEX = 0
HU_TITLEY = 167 - HUD_FONTHEIGHT

TITLE_STRING_OFFSET = HUSTR_E1M1

HU_TITLE2_OFFSET = (HUSTR_1  - TITLE_STRING_OFFSET - 1 )


PROC    HU_Start_ NEAR
PUBLIC  HU_Start_

push    cx
push    bx
push    dx
mov   bp, sp
sub   sp, 0100h


xor   ax, ax
mov   word ptr ds:[_message_on], ax  ; 0
;	message_nottobefuckedwith = false;
mov   byte ptr ds:[_message_dontfuckwithme], al  ; 0

;	w_message.height = 1;
;	w_message.on = &message_on;
;	w_message.laston = true;
;	w_message.currentline = 0;

mov   byte ptr ds:[bx + HU_STEXT_T.hu_stext_currentline], al ; 0

mov   word ptr ds:[_w_message + HU_STEXT_T.hu_stext_textlines + HU_TEXTLINE_T.hu_textline_x], ax  ; 0, HU_MSGX
mov   word ptr ds:[_w_message + HU_STEXT_T.hu_stext_textlines + HU_TEXTLINE_T.hu_textline_y], ax  ; 0, HU_MSGY
mov   word ptr ds:[_w_message + HU_STEXT_T.hu_stext_textlines + HU_TEXTLINE_T.hu_textline_len], ax  ; 0
mov   byte ptr ds:[_w_message + HU_STEXT_T.hu_stext_textlines + HU_TEXTLINE_T.hu_textline_characters], al  ; 0

mov   word ptr ds:[_w_title + HU_TEXTLINE_T.hu_textline_x], ax      ; 0  HU_TITLEX
mov   word ptr ds:[_w_title + HU_TEXTLINE_T.hu_textline_y], HU_TITLEY
mov   word ptr ds:[_w_title + HU_TEXTLINE_T.hu_textline_len], ax ; 0
mov   byte ptr ds:[_w_title + HU_TEXTLINE_T.hu_textline_characters], al  ; 0


mov   word ptr ds:[_w_message + HU_STEXT_T.hu_stext_onptr], OFFSET _message_on


inc   ax
mov   byte ptr ds:[_w_message + HU_STEXT_T.hu_stext_height], al ; 1
mov   byte ptr ds:[_w_message + HU_STEXT_T.hu_stext_laston], al ; 1
mov   byte ptr ds:[_w_message + HU_STEXT_T.hu_stext_textlines + HU_TEXTLINE_T.hu_textline_needsupdate], al  ; 1
mov   byte ptr ds:[_w_title + HU_TEXTLINE_T.hu_textline_needsupdate], al ; 1

cmp   byte ptr ds:[_commercial], 0
mov   al, byte ptr ds:[_gamemap]

je    not_commercial
add   ax, HU_TITLE2_OFFSET

jmp   got_index
not_commercial:

dec   ax
xchg  ax, dx
mov   al, byte ptr ds:[_gameepisode]
dec   ax
mov   ah, 9
mul   ah
add   ax, dx
cmp   al, 36
jnge  do_other_calc

mov   ax, NEWLEVELMSG - TITLE_STRING_OFFSET
jmp   got_index

do_other_calc:
add   ax, (HUSTR_E1M1 - TITLE_STRING_OFFSET)
got_index:

lea   bx, [bp - 0100h]
mov   cx, ss
push  bx
call  getStringByIndex_

pop   dx  ;bp - 0100h
mov   ax, _w_title
call  HUlib_addStringToTextLine_


LEAVE_MACRO
pop   dx
pop   bx
pop   cx



retf
ENDP

PROC    HU_SETUP_ENDMARKER_ NEAR
PUBLIC  HU_SETUP_ENDMARKER_
ENDP


END
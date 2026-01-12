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





.DATA



.CODE

EXTRN _w_ready:BYTE
EXTRN _w_health:BYTE
EXTRN _w_armsbg:BYTE
EXTRN _w_arms:BYTE
EXTRN _w_faces:BYTE
EXTRN _w_armor:BYTE
EXTRN _w_keyboxes:BYTE
EXTRN _w_ammo:BYTE
EXTRN _w_maxammo:BYTE
EXTRN _w_end:BYTE

EXTRN _keyboxes:BYTE

EXTRN _tallpercent_:BYTE
EXTRN _armsbgarray_:BYTE
EXTRN _arms_:BYTE
EXTRN _faces_:BYTE
EXTRN _keys_:WORD
EXTRN _shortnum_:BYTE
EXTRN _tallnum_:BYTE


EXTRN _st_palette:BYTE
EXTRN _st_faceindex:BYTE
EXTRN _st_oldhealth:BYTE
EXTRN _oldweaponsowned:BYTE

EXTRN _st_stopped:BYTE
EXTRN _st_statusbaron:BYTE




PROC    ST_SETUP_STARTMARKER_ NEAR
PUBLIC  ST_SETUP_STARTMARKER_
ENDP


ST_MAXAMMO0Y = 173 ; 0ADh
ST_MAXAMMO1Y = 179 ; 0B3h
ST_MAXAMMO2Y = 191 ; 0BFh
ST_MAXAMMO3Y = 185 ; 0B9h;

ST_AMMOWIDTH =           3       
ST_AMMOX =               44      ; 2C
ST_AMMOY =               171     ; 0AB

ST_HEALTHWIDTH =            3        
ST_HEALTHX =                90  ; 05Ah
ST_HEALTHY =                171 ; 0ABh


ST_KEY0WIDTH =            8
ST_KEY0HEIGHT =           5
ST_KEY0X =                239   ; EF
ST_KEY0Y =                171   ; 0ABh
ST_KEY1WIDTH =            ST_KEY0WIDTH
ST_KEY1X =                239   ; EF
ST_KEY1Y =                181   ; 0B5h
ST_KEY2WIDTH =            ST_KEY0WIDTH
ST_KEY2X =                239   ; EF
ST_KEY2Y =                191   ; 0BFh

ST_ARMORY = 171  ; 0ABh
ST_ARMORX = 221  ; 0DDh

ST_ARMSX =               111    ; 6Fh
ST_ARMSY =               172    ; ACh
ST_ARMSXSPACE =          12     ; 0Ch
ST_ARMSYSPACE =          10     ; 0Ah


ST_ARMSBGX =             104    ; 068h
ST_ARMSBGY =             168    ; 0A8h

ST_MAXAMMO0X =           314
ST_MAXAMMO0Y =           173

ST_ARMSX =                      111
ST_ARMSY =                      172

ST_AMMOWIDTH = 3
ST_MAXAMMO0WIDTH =          3
ST_AMMO0WIDTH =          3
ST_MAXAMMO0HEIGHT =              5
ST_AMMO0HEIGHT =         6

ST_AMMO0X =                      288
ST_AMMO0Y =                      173

_ammobgdata:
dw ST_AMMOX, ST_AMMOY, ST_AMMOWIDTH, 0, OFFSET _tallnum_

_healthdata:
dw ST_HEALTHX, ST_HEALTHY, 3, 0, OFFSET _tallnum_, OFFSET _tallpercent_

_armsbgdata:
dw ST_ARMSBGX, ST_ARMSBGY, 0,  OFFSET _armsbgarray_

_weapondata:
dw ST_ARMSX + 0 * ST_ARMSXSPACE,  ST_ARMSY + 0 * ST_ARMSYSPACE, -1, OFFSET _arms_ + 0 * 4
dw ST_ARMSX + 1 * ST_ARMSXSPACE,  ST_ARMSY + 0 * ST_ARMSYSPACE, -1, OFFSET _arms_ + 1 * 4
dw ST_ARMSX + 2 * ST_ARMSXSPACE,  ST_ARMSY + 0 * ST_ARMSYSPACE, -1, OFFSET _arms_ + 2 * 4
dw ST_ARMSX + 0 * ST_ARMSXSPACE,  ST_ARMSY + 1 * ST_ARMSYSPACE, -1, OFFSET _arms_ + 3 * 4
dw ST_ARMSX + 1 * ST_ARMSXSPACE,  ST_ARMSY + 1 * ST_ARMSYSPACE, -1, OFFSET _arms_ + 4 * 4
dw ST_ARMSX + 2 * ST_ARMSXSPACE,  ST_ARMSY + 1 * ST_ARMSYSPACE, -1, OFFSET _arms_ + 5 * 4

_facedata:
dw ST_FACESX, ST_FACESY, -1,  OFFSET _faces_

_armordata:
dw ST_ARMORX, ST_ARMORY, 3, 0, OFFSET _tallnum_, OFFSET _tallpercent_

_keyboxdata:
dw ST_KEY0X,  ST_KEY0Y, -1, OFFSET _keys_
dw ST_KEY1X,  ST_KEY1Y, -1, OFFSET _keys_
dw ST_KEY2X,  ST_KEY2Y, -1, OFFSET _keys_

_ammodata:
dw ST_AMMO0X, ST_MAXAMMO0Y, ST_AMMOWIDTH, 0, OFFSET _shortnum_
dw ST_AMMO0X, ST_MAXAMMO1Y, ST_AMMOWIDTH, 0, OFFSET _shortnum_
dw ST_AMMO0X, ST_MAXAMMO2Y, ST_AMMOWIDTH, 0, OFFSET _shortnum_
dw ST_AMMO0X, ST_MAXAMMO3Y, ST_AMMOWIDTH, 0, OFFSET _shortnum_
_maxammodata:
dw ST_MAXAMMO0X, ST_MAXAMMO0Y, ST_MAXAMMO0WIDTH, 0, OFFSET _shortnum_
dw ST_MAXAMMO0X, ST_MAXAMMO1Y, ST_MAXAMMO0WIDTH, 0, OFFSET _shortnum_
dw ST_MAXAMMO0X, ST_MAXAMMO2Y, ST_MAXAMMO0WIDTH, 0, OFFSET _shortnum_
dw ST_MAXAMMO0X, ST_MAXAMMO3Y, ST_MAXAMMO0WIDTH, 0, OFFSET _shortnum_




; IN GENERAL this function could make everything smaller with direct writes to fields?
; or a fat memcpy from a file with all defaults? etc? consider if we have to save 200 bytes later









PROC    ST_Start_ NEAR
PUBLIC  ST_Start_

PUSHA_NO_AX_MACRO

xor   ax, ax
cmp   byte ptr cs:[_st_stopped], al
jne   dont_call_st_stop
; inlined st_stop only use
call  dword ptr ds:[_I_SetPalette_addr]
mov   byte ptr cs:[_st_stopped], 1

dont_call_st_stop:
mov   ax, 1
mov   byte ptr ds:[_st_firsttime], al   ; 1
mov   byte ptr ds:[_st_gamestate], al   ; 1

push  cs
pop   es

mov   si, OFFSET _player + PLAYER_T.player_weaponowned
mov   di, OFFSET _oldweaponsowned
mov   cx, 9
rep   movsb

push  cs
pop   ds

ASSUME DS:ST_SETUP_TEXT

mov   byte ptr cs:[_st_statusbaron], al ; 1
neg   ax
mov   byte ptr cs:[_st_palette], al   ; -1
mov   word ptr cs:[_st_oldhealth], ax ; -1


;mov   di, OFFSET _keyboxes
stosw ; mov   word ptr cs:[_keyboxes + 0], ax  ; -1
stosw ; mov   word ptr cs:[_keyboxes + 2], ax  ; -1
stosw ; mov   word ptr cs:[_keyboxes + 4], ax  ; -1


mov   word ptr ds:[_st_faceindex], cx ; 0  ; actually cs
mov   byte ptr ds:[_st_stopped], cl   ; 0  ; actually cs



;call  ST_createWidgets_  ; inlined


; aligned these targets all in memory. one rep movsw.

mov   si, OFFSET _ammobgdata
;mov   di, OFFSET _w_ready
mov   cx, word ptr ds:[_w_end] ; todo should be constant but borland wont let me
ASSUME DS:DGROUP

rep   movsw



push  ss
pop   ds


call  Z_QuickMapPhysics_Physics_  ; returns to physics region, must be done.



POPA_NO_AX_MACRO
ret


ENDP



PROC   Z_QuickMapPhysics_Physics_ NEAR
PUBLIC Z_QuickMapPhysics_Physics_

push  dx
push  cx
push  si


Z_QUICKMAPAI24 pageswapargs_phys_offset_size INDEXED_PAGE_4000_OFFSET
mov   byte ptr ds:[_currenttask], TASK_PHYSICS

pop   si
pop   cx
pop   dx
ret

ENDP

PROC    ST_SETUP_ENDMARKER_ NEAR
PUBLIC  ST_SETUP_ENDMARKER_
ENDP



END
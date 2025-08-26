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


EXTRN Z_QuickMapPhysics_:FAR
EXTRN I_SetPalette_:FAR

.DATA

EXTRN _st_stopped:BYTE
EXTRN _st_palette:BYTE
EXTRN _st_oldhealth:BYTE
EXTRN _st_firsttime:BYTE
EXTRN _st_gamestate:BYTE
EXTRN _st_statusbaron:BYTE
EXTRN _st_faceindex:BYTE

EXTRN _tallpercent:BYTE

EXTRN _armsbgarray:BYTE



EXTRN _arms:BYTE
EXTRN _faces:BYTE
EXTRN _keys:BYTE
EXTRN _keyboxes:BYTE
EXTRN _oldweaponsowned:BYTE

EXTRN _w_ammo:BYTE
EXTRN _w_arms:BYTE
EXTRN _w_armsbg:BYTE
EXTRN _w_armor:BYTE
EXTRN _w_health:BYTE
EXTRN _w_faces:BYTE
EXTRN _w_keyboxes:BYTE
EXTRN _w_maxammo:BYTE
EXTRN _w_ready:BYTE


.CODE



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
dw ST_AMMOX, ST_AMMOY, ST_AMMOWIDTH, 0, OFFSET _tallnum

_healthdata:
dw ST_HEALTHX, ST_HEALTHY, 3, 0, OFFSET _tallnum, OFFSET _tallpercent

_armsbgdata:
dw ST_ARMSBGX, ST_ARMSBGY, 0,  OFFSET _armsbgarray

_weapondata:
dw ST_ARMSX + 0 * ST_ARMSXSPACE,  ST_ARMSY + 0 * ST_ARMSYSPACE, -1, OFFSET _arms + 0 * 4
dw ST_ARMSX + 1 * ST_ARMSXSPACE,  ST_ARMSY + 0 * ST_ARMSYSPACE, -1, OFFSET _arms + 1 * 4
dw ST_ARMSX + 2 * ST_ARMSXSPACE,  ST_ARMSY + 0 * ST_ARMSYSPACE, -1, OFFSET _arms + 2 * 4
dw ST_ARMSX + 0 * ST_ARMSXSPACE,  ST_ARMSY + 1 * ST_ARMSYSPACE, -1, OFFSET _arms + 3 * 4
dw ST_ARMSX + 1 * ST_ARMSXSPACE,  ST_ARMSY + 1 * ST_ARMSYSPACE, -1, OFFSET _arms + 4 * 4
dw ST_ARMSX + 2 * ST_ARMSXSPACE,  ST_ARMSY + 1 * ST_ARMSYSPACE, -1, OFFSET _arms + 5 * 4

_facedata:
dw ST_FACESX, ST_FACESY, -1,  OFFSET _faces

_armordata:
dw ST_ARMORX, ST_ARMORY, 3, 0, OFFSET _tallnum, OFFSET _tallpercent

_keyboxdata:
dw ST_KEY0X,  ST_KEY0Y, -1, OFFSET _keys
dw ST_KEY1X,  ST_KEY1Y, -1, OFFSET _keys
dw ST_KEY2X,  ST_KEY2Y, -1, OFFSET _keys

_ammodata:
dw ST_AMMO0X, ST_MAXAMMO0Y, ST_AMMOWIDTH, 0, OFFSET _shortnum
dw ST_AMMO0X, ST_MAXAMMO1Y, ST_AMMOWIDTH, 0, OFFSET _shortnum
dw ST_AMMO0X, ST_MAXAMMO2Y, ST_AMMOWIDTH, 0, OFFSET _shortnum
dw ST_AMMO0X, ST_MAXAMMO3Y, ST_AMMOWIDTH, 0, OFFSET _shortnum
_maxammodata:
dw ST_MAXAMMO0X, ST_MAXAMMO0Y, ST_MAXAMMO0WIDTH, 0, OFFSET _shortnum
dw ST_MAXAMMO0X, ST_MAXAMMO1Y, ST_MAXAMMO0WIDTH, 0, OFFSET _shortnum
dw ST_MAXAMMO0X, ST_MAXAMMO2Y, ST_MAXAMMO0WIDTH, 0, OFFSET _shortnum
dw ST_MAXAMMO0X, ST_MAXAMMO3Y, ST_MAXAMMO0WIDTH, 0, OFFSET _shortnum




; IN GENERAL this function could make everything smaller with direct writes to fields?
; or a fat memcpy from a file with all defaults? etc? consider if we have to save 200 bytes later








ENDP

PROC    ST_Start_ FAR
PUBLIC  ST_Start_

PUSHA_NO_AX_MACRO

xor   ax, ax
cmp   byte ptr ds:[_st_stopped], al
jne   dont_call_st_stop
; inlined st_stop only use
call  I_SetPalette_
mov   byte ptr ds:[_st_stopped], 1

dont_call_st_stop:
mov   ax, 1
mov   byte ptr ds:[_st_firsttime], al   ; 1
mov   byte ptr ds:[_st_gamestate], al   ; 1
mov   byte ptr ds:[_st_statusbaron], al ; 1
neg   ax
mov   byte ptr ds:[_st_palette], al   ; -1
mov   word ptr ds:[_st_oldhealth], ax ; -1

push  ds
pop   es
mov   di, OFFSET _keyboxes
stosw ; mov   word ptr ds:[_keyboxes + 0], ax  ; -1
stosw ; mov   word ptr ds:[_keyboxes + 2], ax  ; -1
stosw ; mov   word ptr ds:[_keyboxes + 4], ax  ; -1

inc   ax ; 0
mov   word ptr ds:[_st_faceindex], ax ; 0
mov   byte ptr ds:[_st_stopped], al   ; 0

mov   si, OFFSET _player + PLAYER_T.player_weaponowned
mov   di, OFFSET _oldweaponsowned
mov   cx, 9
rep   movsb

;call  ST_createWidgets_  ; inlined


;push  ds
;pop   es
push  cs
pop   ds

; todo align these targets all in memory. one rep movsw.
; further todo: source data in file. read from file. less persistent ram usage.

mov   si, OFFSET _ammobgdata
mov   di, OFFSET _w_ready
mov   cx, (SIZEOF_ST_NUMBER_T / 2)
rep   movsw
; si carries..

mov   di, OFFSET _w_health
mov   cl, (SIZEOF_ST_PERCENT_T / 2)
rep   movsw

mov   di, OFFSET _w_armsbg
mov   cl, (SIZEOF_ST_MULTICON_T / 2)
rep   movsw

mov   di, OFFSET _w_arms
mov   cl, (SIZEOF_ST_MULTICON_T / 2) * 6 
rep   movsw


mov   di, offset _w_faces
mov   cl, (SIZEOF_ST_MULTICON_T / 2)
rep   movsw

mov   di, offset _w_armor
mov   cl, (SIZEOF_ST_PERCENT_T / 2)
rep   movsw

mov   di, offset _w_keyboxes
mov   cl, (SIZEOF_ST_MULTICON_T / 2) * 3
rep   movsw

mov   di, offset _w_ammo
mov   cl, (SIZEOF_ST_NUMBER_T / 2) * 4
rep   movsw

mov   di, offset _w_maxammo
mov   cl, (SIZEOF_ST_NUMBER_T / 2) * 4
rep   movsw

push  ss
pop   ds

; hardcoded in
;mov   word ptr ds:[_w_armsbg + ST_MULTIICON_T.st_multicon_oldinum], 0

call  Z_QuickMapPhysics_
POPA_NO_AX_MACRO
retf  


ENDP

PROC    ST_SETUP_ENDMARKER_ NEAR
PUBLIC  ST_SETUP_ENDMARKER_
ENDP



END
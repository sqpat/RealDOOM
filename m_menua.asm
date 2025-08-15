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

LINEHEIGHT = 16

OPTIONS_E_MESSAGES = 1
OPTIONS_E_MOUSESENS = 5
OPTIONS_E_SCRNSIZE = 3
OPTIONS_E_DETAIL = 2

SOUND_E_SFX_VOL     = 0
SOUND_E_SFX_EMPTY1  = 1
SOUND_E_MUSIC_VOL   = 2
SOUND_E_SFX_EMPTY2  = 3
SOUND_E_SOUND_END   = 4

LOAD_END = 6


EXTRN S_SetSfxVolume_:FAR
EXTRN S_SetMusicVolume_:FAR


EXTRN V_DrawPatchDirect_:FAR
EXTRN V_DrawFullscreenPatch_:FAR
EXTRN getStringByIndex_:FAR
EXTRN locallib_far_fread_:FAR
EXTRN fclose_:FAR
EXTRN fopen_:FAR
EXTRN makesavegamename_:FAR

EXTRN G_LoadGame_:FAR
EXTRN G_SaveGame_:FAR
EXTRN G_DeferedInitNew_:NEAR

EXTRN locallib_strcmp_:FAR
EXTRN combine_strings_:FAR
EXTRN D_StartTitle_:FAR
EXTRN locallib_strncpy_:FAR
EXTRN locallib_strcpy_:FAR

EXTRN locallib_strlen_:FAR
EXTRN combine_strings_near_:FAR
EXTRN I_Quit_:FAR
EXTRN I_WaitVBL_:FAR
EXTRN S_StartSound_:FAR
EXTRN R_SetViewSize_:FAR
EXTRN I_SetPalette_:FAR

EXTRN Z_QuickMapStatus_:FAR
EXTRN Z_QuickMapMenu_:FAR
EXTRN Z_QuickMapPhysics_:FAR
EXTRN Z_QuickMapWipe_:FAR
EXTRN Z_QuickMapByTaskNum_:FAR

.DATA


EXTRN _saveSlot:WORD
EXTRN _saveCharIndex:WORD
EXTRN _saveStringEnter:WORD
EXTRN _saveOldString:BYTE

EXTRN _usegamma:BYTE
EXTRN _inhelpscreens:BYTE
EXTRN _borderdrawcount:BYTE
EXTRN _sfxVolume:BYTE
EXTRN _musicVolume:BYTE
EXTRN _snd_SfxVolume:BYTE

EXTRN   _quickSaveSlot:BYTE

EXTRN _usergame:BYTE
EXTRN _showMessages:BYTE
EXTRN _itemOn:BYTE
EXTRN _message_dontfuckwithme:BYTE
EXTRN _msgNames:BYTE
EXTRN _mouseSensitivity:BYTE
EXTRN _detailLevel:BYTE
EXTRN _detailNames:BYTE
EXTRN _screenSize:BYTE

EXTRN _hu_font:WORD

EXTRN _messageToPrint:BYTE
EXTRN _messageNeedsInput:BYTE
EXTRN _messageLastMenuActive:WORD
EXTRN _currentMenu:WORD
EXTRN _messageRoutine:WORD
EXTRN _menu_messageString:WORD


EXTRN _OptionsDef:WORD
EXTRN _menu_epi:WORD
EXTRN _ReadDef1:WORD
EXTRN _ReadDef2:WORD
EXTRN _NewDef:WORD
EXTRN _MainDef:WORD
EXTRN _LoadDef:WORD
EXTRN _SaveDef:WORD
EXTRN _EpiDef:WORD
EXTRN _SoundDef:WORD
EXTRN _LoadMenu:WORD



.CODE





PROC    M_MENU_STARTMARKER_ NEAR
PUBLIC  M_MENU_STARTMARKER_
ENDP



MENUPATCH_M_DOOM    =  0
MENUPATCH_M_RDTHIS  =  1
MENUPATCH_M_OPTION  =  2
MENUPATCH_M_QUITG   =  3
MENUPATCH_M_NGAME   =  4
MENUPATCH_M_SKULL1  =  5
MENUPATCH_M_SKULL2  =  6
MENUPATCH_M_THERMO  =  7
MENUPATCH_M_THERMR  =  8
MENUPATCH_M_THERMM  =  9
MENUPATCH_M_THERML  =  10
MENUPATCH_M_ENDGAM  =  11
MENUPATCH_M_PAUSE   =  12
MENUPATCH_M_MESSG   =  13
MENUPATCH_M_MSGON   =  14
MENUPATCH_M_MSGOFF  =  15
MENUPATCH_M_EPISOD  =  16
MENUPATCH_M_EPI1    =  17
MENUPATCH_M_EPI2    =  18
MENUPATCH_M_EPI3    =  19
MENUPATCH_M_HURT    =  20
MENUPATCH_M_JKILL   =  21
MENUPATCH_M_ROUGH   =  22
MENUPATCH_M_SKILL   =  23
MENUPATCH_M_NEWG    =  24
MENUPATCH_M_ULTRA   =  25
MENUPATCH_M_NMARE   =  26
MENUPATCH_M_SVOL    =  27
MENUPATCH_M_OPTTTL  =  28
MENUPATCH_M_SAVEG   =  29
MENUPATCH_M_LOADG   =  30
MENUPATCH_M_DISP    =  31
MENUPATCH_M_MSENS   =  32
MENUPATCH_M_GDHIGH  =  33
MENUPATCH_M_GDLOW   =  34
MENUPATCH_M_DETAIL  =  35
MENUPATCH_M_DISOPT  =  36
MENUPATCH_M_SCRNSZ  =  37
MENUPATCH_M_SGTTL   =  38
MENUPATCH_M_LGTTL   =  39
MENUPATCH_M_SFXVOL  =  40
MENUPATCH_M_MUSVOL  =  41
MENUPATCH_M_LSLEFT  =  42
MENUPATCH_M_LSCNTR  =  43
MENUPATCH_M_LSRGHT  =  44
MENUPATCH_M_EPI4    =  45


_menu_string_underscore:
db "_", 0

PROC    M_GetMenuPatch_ NEAR
PUBLIC  M_GetMenuPatch_


push  bx
cbw
mov   bx, ax
add   bx, ax
cmp   al, 27   ; number of menu graphics in first menu page. Todo unhardcode?
mov   ax, MENUOFFSETS_SEGMENT ; todo use offset in cs?
mov   es, ax
mov   dx, MENUGRAPHICSPAGE0SEGMENT
jl    use_page_0
mov   dx, MENUGRAPHICSPAGE4SEGMENT
use_page_0:
mov   ax, word ptr es:[bx]
pop   bx
ret  




ENDP

LOADDEF_X = 80
LOADDEF_Y = 54


PROC    M_DrawLoad_ NEAR
PUBLIC  M_DrawLoad_


PUSHA_NO_AX_OR_BP_MACRO
call  Z_QuickMapStatus_
mov   al, MENUPATCH_M_LOADG
call  M_GetMenuPatch_
xchg  ax, bx
mov   cx, dx

xor   si, si
mov   di, LOADDEF_Y

mov   dx, 28
mov   ax, 72
call  V_DrawPatchDirect_

loop_draw_next_load_bar:

mov   dx, di ; zero dh...
mov   ax, LOADDEF_X
call  M_DrawSaveLoadBorder_

mov   bx, si
mov   dx, di
mov   ax, LOADDEF_X
mov   cx, SAVEGAMESTRINGS_SEGMENT
call  M_WriteText_
add   si, SAVESTRINGSIZE
add   di, 16
cmp   si, (LOAD_END * SAVESTRINGSIZE)
jl    loop_draw_next_load_bar

POPA_NO_AX_OR_BP_MACRO
ret   


ENDP


PROC    M_DrawSaveLoadBorder_ NEAR
PUBLIC  M_DrawSaveLoadBorder_


PUSHA_NO_AX_MACRO

mov   si, ax
add   dx, 7
mov   di, dx  ; si/di get x/y

mov   al, MENUPATCH_M_LSCNTR
call  M_GetMenuPatch_
mov   word ptr cs:[SELFMODIFY_set_saveloadborder_offset+1], ax
mov   word ptr cs:[SELFMODIFY_set_saveloadborder_segment+1], dx


mov   al, MENUPATCH_M_LSLEFT
call  M_GetMenuPatch_

xchg  ax, bx
mov   cx, dx
mov   ax, si
mov   dx, di
sub   ax, 8

call  V_DrawPatchDirect_



xor   bp, bp ; loop counter
loop_next_tile:
mov   dx, di
mov   ax, si
SELFMODIFY_set_saveloadborder_offset:
mov   bx, 01000h
SELFMODIFY_set_saveloadborder_segment:
mov   cx, 01000h
call  V_DrawPatchDirect_
add   si, 8
inc   bp
cmp   bp, 24
jl    loop_next_tile

mov   al, MENUPATCH_M_LSRGHT
call  M_GetMenuPatch_
xchg  bx, ax
mov   cx, dx
mov   dx, di
mov   ax, si
call  V_DrawPatchDirect_
POPA_NO_AX_MACRO
ret   


ENDP


PROC    M_LoadSelect_ NEAR
PUBLIC  M_LoadSelect_


push  bx
push  dx
push  bp
mov   bp, sp
sub   sp, 0100h
cbw  
mov   dx, ds
mov   bx, ax
lea   ax, [bp - 0100h]
call  makesavegamename_  ; todo make local
lea   ax, [bp - 0100h]
call  G_LoadGame_
mov   byte ptr ds:[_menuactive], 0
LEAVE_MACRO 
pop   dx
pop   bx
ret   


ENDP

PROC    M_LoadGame_ NEAR
PUBLIC  M_LoadGame_

mov   ax, word ptr ds:[_LoadDef + MENU_T.menu_laston]
mov   word ptr ds:[_currentMenu], OFFSET _LoadDef  ; inlined setupnextmenu
mov   word ptr ds:[_itemOn], ax


ENDP  ; fall thru?

PROC    M_ReadSaveStrings_ NEAR
PUBLIC  M_ReadSaveStrings_

PUSHA_NO_AX_OR_BP_MACRO
push  bp
mov   bp, sp
sub   sp, 0100h
xor   si, si
mov   di, _LoadMenu + MENUITEM_T.menuitem_status


loop_next_savestring:
mov   bx, si
mov   dx, ss
lea   ax, [bp - 0100h]
call  makesavegamename_
mov   dx, OFFSET _fopen_rb_argument
lea   ax, [bp - 0100h]
call  fopen_

xchg  ax, bx ; fp to bx
mov   ax, si
mov   cx, SAVESTRINGSIZE ; used in both loops.
mul   cl
mov   dx, SAVEGAMESTRINGS_SEGMENT

test  bx, bx
jne   good_savegame_file

no_savegame_file:

xchg  ax, bx  ; bx gets product result..
mov   cx, dx ; actually cx gets the segment in this case.
mov   ax, EMPTYSTRING
call  getStringByIndex_

mov   byte ptr ds:[di], 0
jmp   iter_next_savestring

good_savegame_file:
; load file slot string

; ax already has product/dest offset
; dx already has segment
; cx already has SAVESTRINGSIZE
; bp currently has fp.

push  bx ; fp. 2nd time for later pop
push  bx ; fp arg for far read

mov   bx, 1
call  locallib_far_fread_

pop   ax  ; recover fp
call  fclose_

mov   byte ptr ds:[di], 1
iter_next_savestring:
inc   si
add   di, SIZEOF_MENUITEM_T
cmp   si, LOAD_END
jl    loop_next_savestring

LEAVE_MACRO
POPA_NO_AX_OR_BP_MACRO

ret   


ENDP

PROC    M_DrawSave_ NEAR
PUBLIC  M_DrawSave_

push  bx
push  cx
push  dx
push  bp
mov   bp, sp
sub   sp, 2
call  Z_QuickMapStatus_
mov   al, MENUPATCH_M_SAVEG
call  M_GetMenuPatch_
mov   bx, ax
mov   cx, dx
mov   dx, 28
mov   ax, 72
mov   byte ptr [bp - 2], 0
call  V_DrawPatchDirect_
label_8:
mov   al, byte ptr [bp - 2]
cbw  
mov   dl, byte ptr [_LoadDef + MENU_T.menu_y]
mov   bx, ax
xor   dh, dh
shl   bx, 4
mov   ax, word ptr [_LoadDef + MENU_T.menu_x]
add   dx, bx
call  M_DrawSaveLoadBorder_
mov   al, byte ptr [bp - 2]
cbw  
imul  cx, ax, SAVESTRINGSIZE
mov   al, byte ptr [_LoadDef + MENU_T.menu_y]
xor   ah, ah
mov   dx, ax
mov   ax, word ptr [_LoadDef + MENU_T.menu_x]
add   dx, bx
mov   bx, cx
mov   cx, SAVEGAMESTRINGS_SEGMENT
inc   byte ptr [bp - 2]
call  M_WriteText_
cmp   byte ptr [bp - 2], 6
jl    label_8
cmp   word ptr ds:[_saveStringEnter], 0
jne   label_9
LEAVE_MACRO 
pop   dx
pop   cx
pop   bx
ret   
label_9:
imul  ax, word ptr ds:[_saveSlot], SAVESTRINGSIZE
mov   dx, SAVEGAMESTRINGS_SEGMENT
mov   cx, cs
call  M_StringWidth_
mov   dl, byte ptr [_LoadDef + MENU_T.menu_y]
mov   bx, word ptr ds:[_saveSlot]
cbw  
shl   bx, 4
xor   dh, dh
add   ax, word ptr [_LoadDef + MENU_T.menu_x]
add   dx, bx
mov   bx, OFFSET _menu_string_underscore
call  M_WriteText_
LEAVE_MACRO 
pop   dx
pop   cx
pop   bx
ret   


ENDP

COMMENT @


PROC    M_DoSave_ NEAR
PUBLIC  M_DoSave_

push  bx
push  cx
push  dx
mov   dx, ax
imul  bx, ax, SAVESTRINGSIZE
mov   cx, SAVEGAMESTRINGS_SEGMENT
cbw  
call  G_SaveGame_
mov   bx, _menuactive
mov   byte ptr ds:[bx], 0
cmp   byte ptr ds:[_snd_SfxVolume], -2
je    label_10
pop   dx
pop   cx
pop   bx
ret   
label_10:
mov   byte ptr ds:[_snd_SfxVolume], dl
pop   dx
pop   cx
pop   bx
ret   



ENDP

PROC    M_SaveSelect_ NEAR
PUBLIC  M_SaveSelect_


push  bx
push  cx
push  dx
push  si
push  di
push  bp
mov   bp, sp
sub   sp, 0100h
mov   di, ax
imul  cx, ax, SAVESTRINGSIZE
mov   word ptr ds:[_saveStringEnter], 1
xor   dl, dl
mov   word ptr ds:[_saveSlot], ax
label_12:
mov   al, dl
cbw  
cmp   ax, SAVESTRINGSIZE
jae   label_11
mov   al, dl
cbw  
mov   si, cx
mov   bx, ax
add   si, ax
mov   ax, SAVEGAMESTRINGS_SEGMENT
mov   es, ax
mov   al, byte ptr es:[si]
inc   dl
mov   byte ptr ds:[bx + _saveOldString], al
jmp   label_12
label_11:
imul  si, di, SAVESTRINGSIZE
lea   bx, [bp - 0100h]
mov   ax, EMPTYSTRING
mov   cx, ds
mov   dx, SAVEGAMESTRINGS_SEGMENT
call  getStringByIndex_
lea   bx, [bp - 0100h]
mov   cx, ds
mov   ax, si
call  locallib_strcmp_
test  ax, ax
jne   label_13
mov   ax, SAVEGAMESTRINGS_SEGMENT
mov   es, ax
mov   byte ptr es:[si], 0
label_13:
imul  ax, di, SAVESTRINGSIZE
mov   dx, SAVEGAMESTRINGS_SEGMENT
call  locallib_strlen_
mov   word ptr ds:[_saveCharIndex], ax
LEAVE_MACRO 
pop   di
pop   si
pop   dx
pop   cx
pop   bx
ret   


ENDP

PROC    M_SaveGame_ NEAR
PUBLIC  M_SaveGame_


push  bx
push  cx
push  dx
push  bp
mov   bp, sp
sub   sp, 0100h
cmp   byte ptr ds:[_usergame], 0
je    label_14
mov   bx, _gamestate
cmp   byte ptr ds:[bx], 0
je    label_15
exit_m_savegame:
LEAVE_MACRO 
pop   dx
pop   cx
pop   bx
ret   
label_14:
lea   bx, [bp - 0100h]
mov   ax, SAVEDEAD
mov   cx, ds
call  getStringByIndex_
xor   dx, dx
lea   ax, [bp - 0100h]
xor   bx, bx
call  M_StartMessage_
jmp   exit_m_savegame
label_15:
mov   ax, word ptr ds:[_SaveDef + MENU_T.menu_laston]
mov   word ptr ds:[_currentMenu], OFFSET _SaveDef
mov   word ptr ds:[_itemOn], ax
call  M_ReadSaveStrings_
LEAVE_MACRO 
pop   dx
pop   cx
pop   bx
ret   
cld   

ENDP

PROC    M_QuickSaveResponse_ NEAR
PUBLIC  M_QuickSaveResponse_

push  dx
cmp   ax, 'y'  ; 079h
je    do_quicksave
pop   dx
ret   
do_quicksave:
mov   al, byte ptr ds:[_quickSaveSlot]
cbw  
mov   dx, SAVESTRINGSIZE
call  M_DoSave_
xor   ax, ax
call  S_StartSound_
pop   dx
ret   
cld   


ENDP

PROC    M_QuickSave_ NEAR
PUBLIC  M_QuickSave_

push  bx
push  cx
push  dx
push  bp
mov   bp, sp
sub   sp, 0E2h
sub   bp, 098h
mov   al, byte ptr ds:[_usergame]
test  al, al
je    label_16
mov   bx, _gamestate
cmp   byte ptr ds:[bx], 0
jne   label_17
cmp   byte ptr ds:[_quickSaveSlot], 0
jl    label_18
lea   bx, [bp + 04ch]
mov   ax, 7
mov   cx, ds
call  getStringByIndex_
lea   bx, [bp + 07Eh]
mov   ax, QLQLPROMPTEND
mov   cx, ds
call  getStringByIndex_
mov   al, byte ptr ds:[_quickSaveSlot]
cbw  
imul  ax, ax, SAVESTRINGSIZE
mov   dx, ds
push  SAVEGAMESTRINGS_SEGMENT
lea   bx, [bp + 04Ch]
mov   cx, ds
push  ax
lea   ax, [bp - 04Ah]
call  combine_strings_
lea   ax, [bp + 07Eh]
lea   bx, [bp - 04Ah]
mov   dx, ds
push  ds
mov   cx, ds
push  ax
lea   ax, [bp - 04Ah]
call  combine_strings_
mov   bx, 1
mov   dx, OFFSET M_QuickSaveResponse_
lea   ax, [bp - 04Ah]
call  M_StartMessage_
label_17:
lea   sp, [bp + 098h]
pop   bp
pop   dx
pop   cx
pop   bx
ret   
label_16:
mov   dx, SFX_OOF
xor   ah, ah
call  S_StartSound_
jmp   label_17
label_18:
call  M_StartControlPanel_
call  M_ReadSaveStrings_
mov   word ptr ds:[_currentMenu], OFFSET _SaveDef
mov   ax, word ptr ds:[_SaveDef + MENU_T.menu_laston]
mov   byte ptr ds:[_quickSaveSlot], -2
mov   word ptr ds:[_itemOn], ax
lea   sp, [bp + 098h]
pop   bp
pop   dx
pop   cx
pop   bx
ret   
cld   


ENDP

PROC    M_QuickLoadResponse_ NEAR
PUBLIC  M_QuickLoadResponse_


push  dx
cmp   ax, 'y' ; 079h
je    label_3
pop   dx
ret   
label_3:
mov   al, byte ptr ds:[_quickSaveSlot]
cbw  
mov   dx, SFX_SWTCHX
call  S_StartSound_
xor   ax, ax
call  S_StartSound_
pop   dx
ret   
cld   



ENDP

PROC    M_QuickLoad_ NEAR
PUBLIC  M_QuickLoad_


push  bx
push  cx
push  dx
push  bp
mov   bp, sp
sub   sp, 0E2h
sub   bp, 098h
cmp   byte ptr ds:[_quickSaveSlot], 0
jl    label_19
lea   bx, [bp + 04Ch]
mov   ax, 8
mov   cx, ds
call  getStringByIndex_
lea   bx, [bp + 07Eh]
mov   ax, QLQLPROMPTEND
mov   cx, ds
call  getStringByIndex_
mov   al, byte ptr ds:[_quickSaveSlot]
cbw  
imul  ax, ax, SAVESTRINGSIZE
mov   dx, ds
push  SAVEGAMESTRINGS_SEGMENT
lea   bx, [bp + 04Ch]
mov   cx, ds
push  ax
lea   ax, [bp - 04Ah]
call  combine_strings_
lea   dx, [bp + 07Eh]
lea   bx, [bp - 04Ah]
lea   ax, [bp - 04Ah]
push  ds
mov   cx, ds
push  dx
mov   dx, ds
call  combine_strings_
mov   bx, 1
mov   dx, OFFSET M_QuickLoadResponse_
lea   ax, [bp - 04Ah]
call  M_StartMessage_
lea   sp, [bp + 098h]
pop   bp
pop   dx
pop   cx
pop   bx
ret   
label_19:
lea   bx, [bp - 04Ah]
mov   ax, 5
mov   cx, ds
call  getStringByIndex_
xor   dx, dx
lea   ax, [bp - 04Ah]
xor   bx, bx
call  M_StartMessage_
lea   sp, [bp + 098h]
pop   bp
pop   dx
pop   cx
pop   bx
ret   



ENDP

PROC    M_DrawReadThis1_ NEAR
PUBLIC  M_DrawReadThis1_

push  dx
mov   ax, _STRING_HELP2
xor   dx, dx
mov   byte ptr ds:[_inhelpscreens], 1
call  V_DrawFullscreenPatch_
pop   dx
ret   


ENDP

PROC    M_DrawReadThis2_ NEAR
PUBLIC  M_DrawReadThis2_


push  dx
mov   ax, _STRING_HELP1
xor   dx, dx
mov   byte ptr ds:[_inhelpscreens], 1
call  V_DrawFullscreenPatch_
pop   dx
ret   


ENDP

PROC    M_DrawReadThisRetail_ NEAR
PUBLIC  M_DrawReadThisRetail_

push  dx
mov   ax, _STRING_HELP
xor   dx, dx
mov   byte ptr ds:[_inhelpscreens], 1
call  V_DrawFullscreenPatch_
pop   dx
ret   


ENDP

PROC    M_DrawSound_ NEAR
PUBLIC  M_DrawSound_


push  bx
push  cx
push  dx
mov   al, MENUPATCH_M_SVOL
call  M_GetMenuPatch_
mov   cx, dx
mov   bx, ax
mov   dx, 38
mov   ax, 60
call  V_DrawPatchDirect_
mov   bx, 16
mov   al, byte ptr ds:[_SoundDef + MENU_T.menu_y]
mov   cl, byte ptr ds:[_sfxVolume]
xor   ah, ah
xor   ch, ch
mov   dx, ax
mov   ax, word ptr ds:[_SoundDef + MENU_T.menu_x]
add   dx, LINEHEIGHT*(SOUND_E_SFX_VOL+1)
call  M_DrawThermo_
mov   bx, 16
mov   al, byte ptr ds:[_SoundDef + MENU_T.menu_y]
mov   cl, byte ptr ds:[_musicVolume]
xor   ah, ah
xor   ch, ch
mov   dx, ax
mov   ax, word ptr ds:[_SoundDef + MENU_T.menu_x]
add   dx, LINEHEIGHT*(SOUND_E_MUSIC_VOL+1)
call  M_DrawThermo_
pop   dx
pop   cx
pop   bx
ret   



ENDP

PROC    M_Sound_ NEAR
PUBLIC  M_Sound_


mov   ax, word ptr ds:[_SoundDef + MENU_T.menu_laston]
mov   word ptr ds:[_currentMenu], OFFSET _SoundDef
mov   word ptr ds:[_itemOn], ax
ret   
cld   



ENDP

PROC    M_SfxVol_ NEAR
PUBLIC  M_SfxVol_


push  dx
mov   dl, byte ptr ds:[_sfxVolume]
cmp   ax, 1
jne   label_4
cmp   dl, 15
jae   label_5
inc   dl
label_5:
mov   al, dl
xor   ah, ah
mov   byte ptr ds:[_sfxVolume], dl
call  S_SetSfxVolume_
mov   dl, byte ptr ds:[_sfxVolume]
pop   dx
ret   
label_4:
test  ax, ax
jne   label_5
test  dl, dl
je    label_5
dec   dl
jmp   label_5


ENDP

PROC    M_MusicVol_ NEAR
PUBLIC  M_MusicVol_


push  dx
mov   dl, byte ptr ds:[_musicVolume]
cmp   ax, 1
jne   label_22
cmp   dl, 15
jae   label_23
inc   dl
label_23:
mov   al, dl
xor   ah, ah
mov   byte ptr ds:[_musicVolume], dl
call  S_SetMusicVolume_  ; todo maybe this should just be here?
mov   dl, byte ptr ds:[_musicVolume]
pop   dx
ret   
label_22:
test  ax, ax
jne   label_23
test  dl, dl
je    label_23
dec   dl
jmp   label_23


ENDP

PROC    M_DrawMainMenu_ NEAR
PUBLIC  M_DrawMainMenu_


push  bx
push  cx
push  dx
xor   ax, ax ; MENUPATCH_M_DOOM
call  M_GetMenuPatch_
mov   bx, ax
mov   cx, dx
mov   dx, 2
mov   ax, 94
call  V_DrawPatchDirect_
pop   dx
pop   cx
pop   bx
ret   
cld   


ENDP

PROC    M_DrawNewGame_ NEAR
PUBLIC  M_DrawNewGame_


push  bx
push  cx
push  dx
mov   al, 24
call  M_GetMenuPatch_
mov   bx, ax
mov   cx, dx
mov   dx, 14
mov   ax, 96
call  V_DrawPatchDirect_
mov   al, MENUPATCH_M_SKILL
call  M_GetMenuPatch_
mov   bx, ax
mov   cx, dx
mov   dx, 38
mov   ax, 54
call  V_DrawPatchDirect_
pop   dx
pop   cx
pop   bx
ret   
cld   


ENDP

PROC    M_NewGame_ NEAR
PUBLIC  M_NewGame_


push  bx
mov   bx, _commercial
cmp   byte ptr ds:[bx], 0
je    label_24
mov   bx, word ptr ds:[_NewDef + MENU_T.menu_laston]
mov   word ptr ds:[_currentMenu], OFFSET _NewDef
mov   word ptr ds:[_itemOn], bx
pop   bx
ret   
label_24:
mov   bx, word ptr ds:[_EpiDef + MENU_T.menu_laston]
mov   word ptr ds:[_currentMenu], OFFSET _EpiDef
mov   word ptr ds:[_itemOn], bx
pop   bx
ret   
cld   


ENDP

PROC    M_DrawEpisode_ NEAR
PUBLIC  M_DrawEpisode_


push  bx
push  cx
push  dx
mov   al, MENUPATCH_M_EPISOD
call  M_GetMenuPatch_
mov   bx, ax
mov   cx, dx
mov   dx, 54
mov   ax, 38
call  V_DrawPatchDirect_
pop   dx
pop   cx
pop   bx
ret   



ENDP

PROC    M_VerifyNightmare_ NEAR
PUBLIC  M_VerifyNightmare_


push  bx
push  dx
cmp   ax, 'y' ; 079h
je    label_25
pop   dx
pop   bx
ret   
label_25:
mov   al, byte ptr ds:[_menu_epi]
inc   al
cbw  
mov   bx, 1
mov   dx, ax
mov   ax, 4
call  G_DeferedInitNew_
mov   bx, _menuactive
mov   byte ptr ds:[bx], 0
pop   dx
pop   bx
ret   



ENDP

PROC    M_ChooseSkill_ NEAR
PUBLIC  M_ChooseSkill_


push  bx
push  cx
push  dx
push  bp
mov   bp, sp
sub   sp, 0100h
mov   cx, ax
cmp   ax, 4
jne   label_26
lea   bx, [bp - 0100h]
mov   ax, 9
mov   cx, ds
mov   dx, OFFSET M_VerifyNightmare_
call  getStringByIndex_
mov   bx, 1
lea   ax, [bp - 0100h]
call  M_StartMessage_
LEAVE_MACRO 
pop   dx
pop   cx
pop   bx
ret   
label_26:
mov   al, byte ptr ds:[_menu_epi]
inc   al
cbw  
mov   dx, ax
mov   al, cl
mov   bx, 1
xor   ah, ah
call  G_DeferedInitNew_
mov   bx, _menuactive
mov   byte ptr ds:[bx], 0
LEAVE_MACRO 
pop   dx
pop   cx
pop   bx
ret   



ENDP

PROC    M_Episode_ NEAR
PUBLIC  M_Episode_

push  bx
push  cx
push  dx
push  bp
mov   bp, sp
sub   sp, 0100h
mov   bx, _shareware
cmp   byte ptr ds:[bx], 0
je    label_20
test  ax, ax
jne   label_21
label_20:
mov   byte ptr ds:[_menu_epi], al
mov   ax, word ptr ds:[_ReadDef1 + MENU_T.menu_laston]
mov   word ptr ds:[_currentMenu], OFFSET _ReadDef1  
mov   word ptr ds:[_itemOn], ax
LEAVE_MACRO 
pop   dx
pop   cx
pop   bx
ret   
label_21:
lea   bx, [bp - 0100h]
mov   ax, SWSTRING
mov   cx, ds
call  getStringByIndex_
xor   dx, dx
lea   ax, [bp - 0100h]
xor   bx, bx
call  M_StartMessage_
mov   ax, word ptr ds:[_NewDef + MENU_T.menu_laston]
mov   word ptr ds:[_currentMenu], OFFSET _NewDef
mov   word ptr ds:[_itemOn], ax
LEAVE_MACRO 
pop   dx
pop   cx
pop   bx
ret   


ENDP

PROC    M_DrawOptions_ NEAR
PUBLIC  M_DrawOptions_

push  bx
push  cx
push  dx
push  si
mov   al, MENUPATCH_M_OPTTTL
call  M_GetMenuPatch_
mov   cx, dx
mov   bx, ax
mov   dx, 15
mov   ax, 108
call  V_DrawPatchDirect_
mov   bl, byte ptr ds:[_detailLevel]
xor   bh, bh
mov   al, byte ptr ds:[bx + _detailNames]
call  M_GetMenuPatch_
mov   bl, byte ptr ds:[_OptionsDef + MENU_T.menu_y]
mov   si, word ptr ds:[_OptionsDef + MENU_T.menu_x]
mov   cx, dx
lea   dx, [bx + LINEHEIGHT*options_e_detail]
add   si, 175
mov   bx, ax
mov   ax, si
call  V_DrawPatchDirect_
mov   bl, byte ptr ds:[_showMessages]
xor   bh, bh
mov   al, byte ptr ds:[bx + _msgNames]
call  M_GetMenuPatch_
mov   bl, byte ptr ds:[_OptionsDef + MENU_T.menu_y]
mov   si, word ptr ds:[_OptionsDef + MENU_T.menu_x]
mov   cx, dx
lea   dx, [bx + LINEHEIGHT*options_e_messages]
add   si, 120
mov   bx, ax
mov   ax, si
call  V_DrawPatchDirect_
mov   bx, 10
mov   al, byte ptr ds:[_OptionsDef + MENU_T.menu_y]
mov   cl, byte ptr ds:[_mouseSensitivity]
xor   ah, ah
xor   ch, ch
mov   dx, ax
mov   ax, word ptr ds:[_OptionsDef + MENU_T.menu_x]
add   dx, LINEHEIGHT*(options_e_mousesens+1)
call  M_DrawThermo_
mov   bx, 11
mov   al, byte ptr ds:[_OptionsDef + MENU_T.menu_y]
mov   cl, byte ptr ds:[_screenSize]
xor   ah, ah
xor   ch, ch
mov   dx, ax
mov   ax, word ptr ds:[_OptionsDef + MENU_T.menu_x]
add   dx, LINEHEIGHT*(options_e_scrnsize+1)
call  M_DrawThermo_
pop   si
pop   dx
pop   cx
pop   bx
ret   
cld   



ENDP

PROC    M_Options_ NEAR
PUBLIC  M_Options_


mov   ax, word ptr ds:[_OptionsDef + MENU_T.menu_laston]
mov   word ptr ds:[_currentMenu], OFFSET _OptionsDef
mov   word ptr ds:[_itemOn], ax
ret   
cld   


ENDP

PROC    M_ChangeMessages_ NEAR
PUBLIC  M_ChangeMessages_



push  bx
mov   bl, 1
sub   bl, byte ptr ds:[_showMessages]
mov   byte ptr ds:[_showMessages], bl
jne   label_28
mov   bx, _player + PLAYER_T.player_message
mov   word ptr ds:[bx], MSGOFF
mov   byte ptr ds:[_message_dontfuckwithme], 1
pop   bx
ret   
label_28:
mov   bx, _player + PLAYER_T.player_message
mov   word ptr ds:[bx], MSGON
mov   byte ptr ds:[_message_dontfuckwithme], 1
pop   bx
ret   
cld   


ENDP

PROC    M_EndGameResponse_ NEAR
PUBLIC  M_EndGameResponse_



push  bx
cmp   ax, 'y' ; 079h
je    label_29
pop   bx
ret   
label_29:
mov   bx, word ptr ds:[_currentMenu]
mov   ax, word ptr ds:[_itemOn]
mov   word ptr ds:[bx + MENU_T.menu_laston], ax
mov   bx, _menuactive
mov   byte ptr ds:[bx], 0
call  D_StartTitle_
pop   bx
ret   
cld   


ENDP

PROC    M_EndGame_ NEAR
PUBLIC  M_EndGame_



push  bx
push  cx
push  dx
push  bp
mov   bp, sp
sub   sp, 0100h
mov   al, byte ptr ds:[_usergame]
test  al, al
jne   label_30
mov   dx, SFX_OOF
xor   ah, ah
call  S_StartSound_
LEAVE_MACRO 
pop   dx
pop   cx
pop   bx
ret   
label_30:
lea   bx, [bp - 0100h]
mov   ax, ENDGAME
mov   cx, ds
mov   dx, OFFSET M_EndGameResponse_
call  getStringByIndex_
mov   bx, 1
lea   ax, [bp - 0100h]
call  M_StartMessage_
LEAVE_MACRO 
pop   dx
pop   cx
pop   bx
ret   


ENDP

PROC    M_ReadThis_ NEAR
PUBLIC  M_ReadThis_



push  bx
mov   bx, _is_ultimate
cmp   byte ptr ds:[bx], 0
je    label_31
; todo inlined m_readthis2...
mov   bx, word ptr ds:[_ReadDef2 + MENU_T.menu_laston]
mov   word ptr ds:[_currentMenu], OFFSET _ReadDef2
mov   word ptr ds:[_itemOn], bx
pop   bx
ret   
label_31:
mov   bx, word ptr ds:[_ReadDef1 + MENU_T.menu_laston]
mov   word ptr ds:[_currentMenu], OFFSET _ReadDef1
mov   word ptr ds:[_itemOn], bx
pop   bx
ret   
cld   


ENDP

PROC    M_ReadThis2_ NEAR
PUBLIC  M_ReadThis2_

mov   ax, word ptr ds:[_ReadDef2 + MENU_T.menu_laston]
mov   word ptr ds:[_currentMenu], OFFSET _ReadDef2
mov   word ptr ds:[_itemOn], ax
ret   
cld   


ENDP

PROC    M_FinishReadThis_ NEAR
PUBLIC  M_FinishReadThis_

mov   ax, word ptr ds:[_MainDef + MENU_T.menu_laston]
mov   word ptr ds:[_currentMenu], OFFSET _MainDef
mov   word ptr ds:[_itemOn], ax
ret   
cld   

ENDP

; todo make quitsounds a lookup here.
PROC    M_QuitResponse_ NEAR
PUBLIC  M_QuitResponse_

push  bx
push  dx
push  si
push  bp
mov   bp, sp
sub   sp, 8
cmp   ax, 'y' ; 079h
jne   exit_m_quitresponse
mov   bx, _commercial
cmp   byte ptr ds:[bx], 0
jne   label_32
mov   word ptr [bp - 8], 01A39h
mov   word ptr [bp - 6], 01F1Bh
mov   word ptr [bp - 4], 02423h
mov   byte ptr [bp - 2], 026h
mov   bx, _gametic
mov   byte ptr [bp - 1], 034h
label_33:
mov   ax, word ptr ds:[bx]
mov   dx, word ptr ds:[bx + 2]
sar   dx, 1
rcr   ax, 1
sar   dx, 1
rcr   ax, 1
mov   si, ax
and   si, 7
mov   dl, byte ptr [bp + si - 8]
xor   ax, ax
xor   dh, dh
call  S_StartSound_
mov   ax, 069h  ;todo fix
call  I_WaitVBL_
call  I_Quit_
exit_m_quitresponse:
LEAVE_MACRO 
pop   si
pop   dx
pop   bx
ret   
label_32:
mov   bx, _gametic
mov   byte ptr [bp - 8], 034h
jmp   label_33
cld   

ENDP

PROC    M_QuitDOOM_ NEAR
PUBLIC  M_QuitDOOM_


push  bx
push  cx
push  dx
push  bp
mov   bp, sp
sub   sp, 088h
sub   bp, 09ch
mov   bx, _gametic
mov   ax, word ptr ds:[bx]
mov   dx, word ptr ds:[bx + 2]
mov   cx, word ptr ds:[bx + 2]
sar   dx, 1
rcr   ax, 1
sar   cx, 15 ; todo no
sar   dx, 1
rcr   ax, 1
mov   dx, cx
xor   dx, ax
mov   ax, word ptr ds:[bx + 2]
sar   ax, 15 ; todo no
sub   dx, ax
mov   ax, word ptr ds:[bx + 2]
sar   ax, 15 ; todo no
and   dx, 7
xor   dx, ax
mov   ax, word ptr ds:[bx + 2]
mov   cx, FIXED_DS_SEGMENT ; todo DS
sar   ax, 15 ; todo no
lea   bx, [bp + 07Eh]
sub   dx, ax
mov   ax, DOSY
call  getStringByIndex_
test  dx, dx
je    label_34
mov   bx, _commercial
cmp   byte ptr ds:[bx], 0
je    label_35
mov   ax, dx
add   ax, QUITMSGD21 - 1
label_36:
lea   bx, [bp + 014h]
mov   cx, ds
lea   dx, [bp + 014h]
call  getStringByIndex_
mov   bx, _STRING_newline
lea   ax, [bp + 014h]
call  combine_strings_near_
lea   bx, [bp + 07Eh]
lea   dx, [bp + 014h]
lea   ax, [bp + 014h]
call  combine_strings_near_
mov   bx, 1
mov   dx, OFFSET M_QuitResponse_
lea   ax, [bp + 014h]
call  M_StartMessage_
lea   sp, [bp + 09Ch]
pop   bp
pop   dx
pop   cx
pop   bx
ret   
label_34:
mov   ax, 2
jmp   label_36
label_35:
mov   ax, dx
add   ax, QUITMSGD11 - 1
jmp   label_36
cld   

ENDP

PROC    M_ChangeSensitivity_ NEAR
PUBLIC  M_ChangeSensitivity_

push  dx
mov   dl, byte ptr ds:[_mouseSensitivity]
cmp   ax, 1
jne   label_37
cmp   dl, 9
jae   set_sensitivity_and_return
inc   dl
set_sensitivity_and_return:
mov   byte ptr ds:[_mouseSensitivity], dl
pop   dx
ret   
label_37:
test  ax, ax
jne   set_sensitivity_and_return
test  dl, dl
je    set_sensitivity_and_return
dec   dl
mov   byte ptr ds:[_mouseSensitivity], dl
pop   dx
ret   
cld   

ENDP

PROC    M_ChangeDetail_ NEAR
PUBLIC  M_ChangeDetail_

push  bx
push  dx
push  si
mov   bl, byte ptr ds:[_detailLevel]
inc   bl
cmp   bl, 3
jne   label_27
xor   bl, bl
label_27:
mov   al, bl
xor   ah, ah
mov   si, _screenblocks
mov   dx, ax
mov   al, byte ptr ds:[si]
mov   byte ptr ds:[_detailLevel], bl
call  R_SetViewSize_
mov   bl, byte ptr ds:[_detailLevel]
test  bl, bl
je    label_38
cmp   bl, 1
jne   label_39
mov   si, _player + PLAYER_T.player_message
mov   word ptr ds:[si], DETAILLO
label_40:
mov   byte ptr ds:[_detailLevel], bl
pop   si
pop   dx
pop   bx
ret   
label_38:
mov   si, _player + PLAYER_T.player_message
mov   word ptr ds:[si], DETAILHI
jmp   label_40
label_39:
mov   si, _player + PLAYER_T.player_message
mov   word ptr ds:[si], DETAILPOTATO
mov   byte ptr ds:[_detailLevel], bl
pop   si
pop   dx
pop   bx
ret   


ENDP

PROC    M_SizeDisplay_ NEAR
PUBLIC  M_SizeDisplay_

push  bx
push  cx
push  dx
mov   cl, byte ptr ds:[_screenSize]
cmp   ax, 1
jne   label_41
cmp   cl, 10
jae   label_42
mov   bx, _screenblocks
inc   cl
inc   byte ptr ds:[bx]
label_42:
mov   al, byte ptr ds:[_detailLevel]
xor   ah, ah
mov   bx, _screenblocks
mov   dx, ax
mov   al, byte ptr ds:[bx]
mov   byte ptr ds:[_screenSize], cl
call  R_SetViewSize_
mov   cl, byte ptr ds:[_screenSize]
pop   dx
pop   cx
pop   bx
ret   
label_41:
test  ax, ax
jne   label_42
test  cl, cl
jbe   label_42
mov   bx, _screenblocks
dec   cl
dec   byte ptr ds:[bx]
jmp   label_42

ENDP

PROC    M_DrawThermo_ NEAR
PUBLIC  M_DrawThermo_

push  si
push  di
push  bp
mov   bp, sp
push  ax
push  dx
push  bx
push  cx
mov   al, MENUPATCH_M_THERML
mov   si, word ptr [bp - 2]
call  M_GetMenuPatch_
xor   di, di
mov   bx, ax
mov   cx, dx
mov   dx, word ptr [bp - 4]
mov   ax, word ptr [bp - 2]
add   si, 8
call  V_DrawPatchDirect_
cmp   word ptr [bp - 6], 0
jle   label_43
label_44:
mov   al, 9
call  M_GetMenuPatch_
mov   bx, ax
mov   cx, dx
mov   dx, word ptr [bp - 4]
mov   ax, si
inc   di
call  V_DrawPatchDirect_
add   si, 8
cmp   di, word ptr [bp - 6]
jl    label_44
label_43:
mov   al, 8
mov   di, word ptr [bp - 2]
call  M_GetMenuPatch_
mov   bx, ax
mov   cx, dx
mov   dx, word ptr [bp - 4]
mov   ax, si
add   di, 8
call  V_DrawPatchDirect_
mov   al, 7
mov   si, word ptr [bp - 8]
call  M_GetMenuPatch_
shl   si, 3
mov   bx, ax
mov   cx, dx
add   si, di
mov   dx, word ptr [bp - 4]
mov   ax, si
call  V_DrawPatchDirect_
LEAVE_MACRO 
pop   di
pop   si
ret   
cld   


ENDP

PROC    M_StartMessage_ NEAR
PUBLIC  M_StartMessage_

push  cx
push  si
push  bp
mov   bp, sp
sub   sp, 2
mov   cx, ax
mov   si, dx
mov   byte ptr [bp - 2], bl
mov   bx, _menuactive
mov   al, byte ptr ds:[bx]
mov   dx, ds
cbw  
mov   bx, cx
mov   word ptr ds:[_messageLastMenuActive], ax
mov   cx, ds
mov   ax, _menu_messageString
mov   byte ptr ds:[_messageToPrint], 1
call  locallib_strcpy_
mov   al, byte ptr [bp - 2]
mov   bx, _menuactive
mov   word ptr ds:[_messageRoutine], si
mov   byte ptr ds:[_messageNeedsInput], al
mov   byte ptr ds:[bx], 1
LEAVE_MACRO 
pop   si
pop   cx
ret   
cld   

ENDP

@

PROC    M_StringWidth_ NEAR
PUBLIC  M_StringWidth_

push  bx
push  cx
push  si
push  di
push  bp
mov   bp, sp
sub   sp, 2
mov   si, ax
mov   di, dx
call  locallib_strlen_
mov   cx, ax
xor   bx, bx
xor   dx, dx
test  ax, ax
jle   label_45
mov   word ptr [bp - 2], di
label_48:
mov   es, word ptr [bp - 2]
mov   al, byte ptr es:[si]
xor   ah, ah
call  M_ToUpper_
xor   ah, ah
sub   ax, HU_FONTSTART
test  ax, ax
jl    label_46
cmp   ax, HU_FONTSIZE
jl    label_47
label_46:
add   bx, 4
label_49:
inc   dx
inc   si
cmp   dx, cx
jl    label_48
label_45:
mov   ax, bx
LEAVE_MACRO 
pop   di
pop   si
pop   cx
pop   bx
ret   
label_47:
mov   di, FONT_WIDTHS_SEGMENT
mov   es, di
mov   di, ax
mov   al, byte ptr es:[di]
cbw  
add   bx, ax
jmp   label_49
cld   

ENDP

COMMENT @

PROC    M_StringHeight_ NEAR
PUBLIC  M_StringHeight_

push  bx
push  cx
push  si
push  di
push  bp
mov   bp, sp
sub   sp, 2
mov   cx, ax
mov   si, dx
mov   word ptr [bp - 2], 8
xor   bl, bl
label_51:
mov   ax, cx
mov   dx, si
call  locallib_strlen_
mov   dx, ax
mov   al, bl
cbw  
cmp   ax, dx
jge   done_with_stringheight_loop
mov   di, cx
mov   es, si
add   di, ax
cmp   byte ptr es:[di], 0Ah  ; newline char
je    label_50
label_52:
inc   bl
jmp   label_51
label_50:
add   word ptr [bp - 2], 8
jmp   label_52
done_with_stringheight_loop:
mov   ax, word ptr [bp - 2]
LEAVE_MACRO 
pop   di
pop   si
pop   cx
pop   bx
ret   


ENDP

@

;uint8_t __far locallib_toupper(uint8_t ch){
;	if (ch >=  0x61 && ch <= 0x7A){
;		return ch - 0x20;
;	}
;	return ch;
;}


PROC    M_ToUpper_ NEAR

cmp   al, 061h
jb    exit_m_to_upper
cmp   al, 07Ah
ja    exit_m_to_upper
sub   al, 020h
exit_m_to_upper:
ret

ENDP


PROC    M_WriteText_ NEAR
PUBLIC  M_WriteText_

push  si
push  di
push  bp
mov   bp, sp
push  cx
push  bx
mov   word ptr cs:[SELFMODIFY_default_x_writetext+1], ax

; si/di are cx/cy
xchg  ax, si
mov   di, dx

loop_next_char_to_write:
les   bx, dword ptr [bp - 4]
mov   al, byte ptr es:[bx]
test  al, al
je    exit_m_writetext
inc   word ptr [bp - 4]
cmp   al, 0Ah  ; newline
je    is_newline
not_newline:
call  M_ToUpper_ ; todo inline or 
sub   al, HU_FONTSTART
js    do_space_char
cmp   al, HU_FONTSIZE
jae   do_space_char
good_fontchar:
cbw
xchg  ax, bx    ; bx gets 'c' index
mov   ax, FONT_WIDTHS_SEGMENT
mov   es, ax
mov   al, byte ptr es:[bx]
cbw  
;        if (cx+w > SCREENWIDTH){
;            break;
;        }


add   ax, si
cmp   ax, SCREENWIDTH
jg    exit_m_writetext
do_write_char:
mov   cx, ST_GRAPHICS_SEGMENT
sal   bx, 1
mov   bx, word ptr ds:[bx + _hu_font]
xchg  ax, si
mov   dx, di
call  V_DrawPatchDirect_
jmp   loop_next_char_to_write
exit_m_writetext:

LEAVE_MACRO 
pop   di
pop   si
ret   
do_space_char:
add   si, 4
jmp   loop_next_char_to_write
is_newline:
SELFMODIFY_default_x_writetext:
mov   si, 01000h
add   di, 12
jmp   loop_next_char_to_write


ENDP

COMMENT @

PROC    M_Responder_ NEAR
PUBLIC  M_Responder_

push  bx
push  cx
push  si
mov   si, ax
mov   es, dx
mov   bx, -1
cmp   byte ptr es:[si], 0
jne   label_57
mov   bx, word ptr es:[si + 1]
label_57:
cmp   bx, -1
je    label_58
cmp   word ptr ds:[_saveStringEnter], 0
je    label_59
cmp   bx, KEY_BACKSPACE
jne   label_60
cmp   word ptr ds:[_saveCharIndex], 0
jle   exit_m_responder_return_1
imul  bx, word ptr ds:[_saveSlot], SAVESTRINGSIZE
dec   word ptr ds:[_saveCharIndex]
mov   dx, SAVEGAMESTRINGS_SEGMENT
add   bx, word ptr ds:[_saveCharIndex]
mov   es, dx
mov   byte ptr es:[bx], 0
exit_m_responder_return_1:
mov   al, 1
exit_m_responder:
pop   si
pop   cx
pop   bx
retf  
label_58:
xor   al, al
jmp   exit_m_responder
label_60:
cmp   bx, KEY_ESCAPE
jne   label_61
xor   ax, ax
xor   dl, dl
mov   word ptr ds:[_saveStringEnter], ax
imul  cx, word ptr ds:[_saveSlot], SAVESTRINGSIZE
label_62:
mov   al, dl
cbw  
cmp   ax, SAVESTRINGSIZE
jae   exit_m_responder_return_1
mov   al, dl
cbw  
mov   si, cx
mov   bx, ax
add   si, ax
mov   ax, SAVEGAMESTRINGS_SEGMENT
mov   es, ax
mov   al, byte ptr ds:[bx + _saveOldString]
inc   dl
mov   byte ptr es:[si], al
jmp   label_62
label_59:
jmp   label_63
label_61:
cmp   bx, KEY_ENTER
jne   label_64
imul  bx, word ptr ds:[_saveSlot], SAVESTRINGSIZE
xor   ax, ax
mov   dx, SAVEGAMESTRINGS_SEGMENT
mov   word ptr ds:[_saveStringEnter], ax
mov   es, dx
cmp   byte ptr es:[bx], 0
je    exit_m_responder_return_1
mov   ax, word ptr ds:[_saveSlot]
call  M_DoSave_
mov   al, 1
pop   si
pop   cx
pop   bx
retf  
label_64:
xor   bh, bh
mov   ax, bx
call  M_ToUpper_
mov   bl, al
cmp   bx, 32
je    label_65
lea   ax, [bx - HU_FONTSTART]
test  ax, ax
jl    exit_m_responder_return_1
lea   ax, [bx - HU_FONTSTART]
cmp   ax, HU_FONTSIZE
jl    label_65
jump_to_exit_m_responder_return_1:
jmp   exit_m_responder_return_1
label_65:
cmp   bx, 32
jl    jump_to_exit_m_responder_return_1
cmp   bx, 127
jg    jump_to_exit_m_responder_return_1
cmp   word ptr ds:[_saveCharIndex], (SAVESTRINGSIZE-1)  ; 017h
jae   jump_to_exit_m_responder_return_1
imul  ax, word ptr ds:[_saveSlot], SAVESTRINGSIZE
mov   dx, SAVEGAMESTRINGS_SEGMENT
call  M_StringWidth_
cmp   ax, ((SAVESTRINGSIZE-2)*8) ; 0B0h
jae   jump_to_exit_m_responder_return_1
imul  ax, word ptr ds:[_saveSlot], SAVESTRINGSIZE
mov   dx, SAVEGAMESTRINGS_SEGMENT
mov   si, word ptr ds:[_saveCharIndex]
mov   es, dx
add   si, ax
inc   word ptr ds:[_saveCharIndex]
mov   byte ptr es:[si], bl
mov   bx, word ptr ds:[_saveCharIndex]
add   bx, ax
mov   byte ptr es:[bx], 0
mov   al, 1
pop   si
pop   cx
pop   bx
retf  
label_63:
cmp   byte ptr ds:[_messageToPrint], 0
je    label_66
cmp   byte ptr ds:[_messageNeedsInput], 1
jne   label_67
cmp   bx, 32
jne   label_68
label_67:
mov   si, _menuactive
mov   al, byte ptr ds:[_messageLastMenuActive]
mov   byte ptr ds:[_messageToPrint], 0
mov   byte ptr ds:[si], al
cmp   word ptr ds:[_messageRoutine], 0
je    label_69
mov   ax, bx
call  word ptr ds:[_messageRoutine]
label_69:
mov   bx, _menuactive
mov   dx, SFX_SWTCHX
xor   ax, ax
mov   byte ptr ds:[bx], 0
call  S_StartSound_
mov   al, 1
pop   si
pop   cx
pop   bx
retf  
label_68:
cmp   bx, 06Eh  ; 'n'
je    label_67
cmp   bx, 079h  ; 'y'
je    label_67
cmp   bx, KEY_ESCAPE
je    label_67
xor   al, al
pop   si
pop   cx
pop   bx
retf  
label_66:
mov   si, _menuactive
mov   al, byte ptr ds:[si]
test  al, al
jne   label_70
cmp   bx, KEY_F5
jae   label_71
cmp   bx, KEY_F1
jae   label_72
cmp   bx, KEY_EQUALS
jne   label_73
mov   bx, _automapactive
cmp   byte ptr ds:[bx], 0
je    label_74
pop   si
pop   cx
pop   bx
retf  
label_71:
jbe   label_75
cmp   bx, KEY_F8
jae   label_76
cmp   bx, KEY_F7
jne   label_77
mov   dx, SFX_SWTCHN
xor   ah, ah
call  S_StartSound_
xor   ax, ax
call  M_EndGame_
mov   al, 1
pop   si
pop   cx
pop   bx
retf  
label_70:
jmp   label_78
label_76:
jbe   label_79
cmp   bx, KEY_F11
jne   label_80
inc   byte ptr ds:[_usegamma]
cmp   byte ptr ds:[_usegamma], 4
jbe   label_81
mov   byte ptr ds:[_usegamma], al
label_81:
mov   al, byte ptr ds:[_usegamma]
xor   ah, ah
mov   bx, _player + PLAYER_T.player_message
add   ax, GAMMALVL0
mov   word ptr ds:[bx], ax
xor   ax, ax
call  I_SetPalette_
mov   al, 1
pop   si
pop   cx
pop   bx
retf  
label_72:
jmp   label_82
label_73:
jmp   label_83
label_74:
jmp   label_84
label_75:
jmp   label_85
label_77:
jmp   label_86
label_80:
cmp   bx, KEY_F10
je    label_87
cmp   bx, KEY_F9
je    label_88
label_78:
mov   si, _menuactive
mov   al, byte ptr ds:[si]
test  al, al
jne   label_89
cmp   bx, KEY_ESCAPE
je    label_90
pop   si
pop   cx
pop   bx
retf  
label_79:
jmp   label_91
label_82:
jbe   label_92
cmp   bx, KEY_F4
je    label_93
cmp   bx, KEY_F3
jne   label_94
call  M_StartControlPanel_
mov   dx, SFX_SWTCHN
xor   ax, ax
call  S_StartSound_
mov   ax, word ptr ds:[_LoadDef + MENU_T.menu_laston]
mov   word ptr ds:[_currentMenu], OFFSET _LoadDef
mov   word ptr ds:[_itemOn], ax
call  M_ReadSaveStrings_
mov   al, 1
pop   si
pop   cx
pop   bx
retf  
label_83:
cmp   bx, KEY_MINUS
jne   label_78
mov   bx, _automapactive
mov   al, byte ptr ds:[bx]
test  al, al
je    label_95
xor   al, al
pop   si
pop   cx
pop   bx
retf  
label_87:
jmp   label_96
label_88:
jmp   label_97
label_95:
xor   ah, ah
mov   dx, SFX_STNMOV
call  M_SizeDisplay_
xor   ax, ax
call  S_StartSound_
mov   al, 1
pop   si
pop   cx
pop   bx
retf  
label_89:
jmp   label_98
label_90:
jmp   label_99
label_92:
jmp   label_100
label_93:
jmp   pressed_f4
label_84:
mov   ax, 1
mov   dx, SFX_STNMOV
call  M_SizeDisplay_
xor   ax, ax
call  S_StartSound_
mov   al, 1
pop   si
pop   cx
pop   bx
retf  
label_94:
jmp   label_102
label_100:
mov   bx, _is_ultimate
call  M_StartControlPanel_
cmp   byte ptr ds:[bx], 0
je    label_103
mov   word ptr ds:[_currentMenu], OFFSET _ReadDef2
label_104:
xor   ax, ax
mov   dx, SFX_SWTCHN
mov   word ptr ds:[_itemOn], ax
call  S_StartSound_
mov   al, 1
pop   si
pop   cx
pop   bx
retf  
label_103:
mov   word ptr ds:[_currentMenu], OFFSET _ReadDef1
jmp   label_104
label_102:
call  M_StartControlPanel_
mov   dx, SFX_SWTCHN
xor   ax, ax
call  S_StartSound_
xor   ax, ax
call  M_SaveGame_
mov   al, 1
pop   si
pop   cx
pop   bx
retf  
pressed_f4:
call  M_StartControlPanel_
mov   word ptr ds:[_currentMenu], OFFSET _SoundDef
xor   ax, ax
mov   dx, SFX_SWTCHN
mov   word ptr ds:[_itemOn], ax
call  S_StartSound_
mov   al, 1
pop   si
pop   cx
pop   bx
retf  
label_85:
xor   ah, ah
mov   dx, SFX_SWTCHN
call  M_ChangeDetail_
xor   ax, ax
call  S_StartSound_
mov   al, 1
pop   si
pop   cx
pop   bx
retf  
label_86:
mov   dx, SFX_SWTCHN
xor   ah, ah
call  S_StartSound_
call  M_QuickSave_
mov   al, 1
pop   si
pop   cx
pop   bx
retf  
label_91:
xor   ah, ah
mov   dx, SFX_SWTCHN
call  M_ChangeMessages_
xor   ax, ax
call  S_StartSound_
mov   al, 1
pop   si
pop   cx
pop   bx
retf  
label_97:
mov   dx, SFX_SWTCHN
xor   ah, ah
call  S_StartSound_
call  M_QuickLoad_
mov   al, 1
pop   si
pop   cx
pop   bx
retf  
label_96:
mov   dx, SFX_SWTCHN
xor   ah, ah
call  S_StartSound_
xor   ax, ax
call  M_QuitDOOM_
mov   al, 1
pop   si
pop   cx
pop   bx
retf  
label_99:
call  M_StartControlPanel_
mov   dx, SFX_SWTCHN
xor   ax, ax
call  S_StartSound_
mov   al, 1
pop   si
pop   cx
pop   bx
retf  
label_98:
mov   dx, word ptr ds:[_itemOn]
mov   ax, dx
shl   ax, 2
add   ax, dx
cmp   bx, KEY_LEFTARROW
jae   label_105
cmp   bx, KEY_BACKSPACE
jne   label_106
mov   bx, word ptr ds:[_currentMenu]
mov   ax, word ptr ds:[bx + 1]
mov   word ptr ds:[bx + MENU_T.menu_laston], dx
test  ax, ax
jne   label_107
jump_to_exit_m_responder_return_1_2:
jmp   exit_m_responder_return_1
label_107:
mov   bx, ax
mov   word ptr ds:[_currentMenu], ax
mov   ax, word ptr ds:[bx + MENU_T.menu_laston]
mov   dx, SFX_SWTCHN
mov   word ptr ds:[_itemOn], ax
xor   ax, ax
call  S_StartSound_
mov   al, 1
pop   si
pop   cx
pop   bx
retf  
label_106:
jmp   label_108
label_105:
ja    label_109
mov   bx, word ptr ds:[_currentMenu]
mov   bx, word ptr ds:[bx + 3]
add   bx, ax
cmp   word ptr ds:[bx + 2], 0
je    jump_to_exit_m_responder_return_1_2
cmp   byte ptr ds:[bx], 2
jne   jump_to_exit_m_responder_return_1_2
mov   bx, _currenttask
mov   dx, SFX_STNMOV
mov   bl, byte ptr ds:[bx]
call  Z_QuickMapMenu_
xor   ax, ax
call  S_StartSound_
mov   dx, word ptr ds:[_itemOn]
mov   ax, dx
mov   si, word ptr ds:[_currentMenu]
shl   ax, 2
mov   si, word ptr ds:[si + 3]
add   ax, dx
add   si, ax
xor   ax, ax
call  word ptr ds:[si + 2]
mov   al, bl
cbw  
call  Z_QuickMapByTaskNum_
mov   al, 1
pop   si
pop   cx
pop   bx
retf  
label_109:
cmp   bx, KEY_DOWNARROW
jne   label_110
xor   cx, cx
label_112:
mov   bx, word ptr ds:[_currentMenu]
mov   al, byte ptr ds:[bx]
cbw  
mov   dx, ax
mov   ax, word ptr ds:[_itemOn]
dec   dx
inc   ax
cmp   ax, dx
jle   label_111
mov   word ptr ds:[_itemOn], cx
label_127:
mov   dx, SFX_PSTOP
mov   ax, cx
call  S_StartSound_
imul  ax, word ptr ds:[_itemOn], 5
mov   bx, word ptr ds:[_currentMenu]
mov   bx, word ptr ds:[bx + 3]
add   bx, ax
cmp   byte ptr ds:[bx], -1
je    label_112
mov   al, 1
pop   si
pop   cx
pop   bx
retf  
label_111:
jmp   label_113
label_110:
cmp   bx, KEY_RIGHTARROW
jne   label_114
mov   bx, word ptr ds:[_currentMenu]
mov   bx, word ptr ds:[bx + 3]
add   bx, ax
cmp   word ptr ds:[bx + 2], 0
jne   label_115
jump_to_exit_m_responder_return_1_3:
jmp   exit_m_responder_return_1
label_115:
cmp   byte ptr ds:[bx], 2
jne   jump_to_exit_m_responder_return_1_3
mov   bx, _currenttask
mov   dx, SFX_STNMOV
mov   bl, byte ptr ds:[bx]
call  Z_QuickMapMenu_
xor   ax, ax
call  S_StartSound_
mov   dx, word ptr ds:[_itemOn]
mov   ax, dx
mov   si, word ptr ds:[_currentMenu]
shl   ax, 2
mov   si, word ptr ds:[si + 3]
add   ax, dx
add   si, ax
mov   ax, 1
call  word ptr ds:[si + 2]
mov   al, bl
cbw  
call  Z_QuickMapByTaskNum_
mov   al, 1
pop   si
pop   cx
pop   bx
retf  
label_114:
cmp   bx, KEY_UPARROW
jne   label_116
mov   cx, -1
xor   si, si
label_118:
cmp   si, word ptr ds:[_itemOn]
jne   label_117
mov   bx, word ptr ds:[_currentMenu]
mov   al, byte ptr ds:[bx]
cbw  
add   ax, cx
mov   word ptr ds:[_itemOn], ax
label_128:
mov   dx, SFX_PSTOP
mov   ax, si
call  S_StartSound_
imul  ax, word ptr ds:[_itemOn], 5
mov   bx, word ptr ds:[_currentMenu]
mov   bx, word ptr ds:[bx + 3]
add   bx, ax
cmp   cl, byte ptr ds:[bx]
je    label_118
mov   al, 1
pop   si
pop   cx
pop   bx
retf  
label_116:
jmp   label_119
label_108:
cmp   bx, KEY_ESCAPE
jne   label_120
mov   bx, word ptr ds:[_currentMenu]
mov   word ptr ds:[bx + MENU_T.menu_laston], dx
mov   bx, _screenblocks
mov   byte ptr ds:[si], 0
mov   byte ptr ds:[_inhelpscreens], 0
cmp   byte ptr ds:[bx], 9
ja    label_121
mov   bx, _hudneedsupdate
mov   byte ptr ds:[_borderdrawcount], 3
cmp   byte ptr ds:[bx], 0
je    label_121
mov   byte ptr ds:[bx], 6
label_121:
mov   dx, SFX_SWTCHX
xor   ax, ax
call  S_StartSound_
mov   al, 1
pop   si
pop   cx
pop   bx
retf  
label_117:
jmp   label_122
label_120:
cmp   bx, KEY_ENTER
je    label_123
label_119:
mov   dx, word ptr ds:[_itemOn]
inc   dx
mov   cx, dx
shl   cx, 2
add   cx, dx
label_126:
mov   si, word ptr ds:[_currentMenu]
mov   al, byte ptr ds:[si]
cbw  
cmp   dx, ax
jge   label_124
mov   si, word ptr ds:[si + 3]
add   si, cx
mov   al, byte ptr ds:[si + 4]
cbw  
cmp   ax, bx
je    label_125
add   cx, 5
inc   dx
jmp   label_126
label_113:
mov   word ptr ds:[_itemOn], ax
jmp   label_127
label_122:
add   word ptr ds:[_itemOn], cx
jmp   label_128
label_124:
jmp   label_129
label_123:
mov   bx, word ptr ds:[_currentMenu]
mov   bx, word ptr ds:[bx + 3]
add   bx, ax
cmp   word ptr ds:[bx + 2], 0
jne   label_130
jump_to_exit_m_responder_return_1_4:
jmp   exit_m_responder_return_1
label_130:
cmp   byte ptr ds:[bx], 0
je    jump_to_exit_m_responder_return_1_4
mov   bx, _currenttask
mov   cl, byte ptr ds:[bx]
call  Z_QuickMapMenu_
mov   ax, word ptr ds:[_itemOn]
mov   bx, word ptr ds:[_currentMenu]
mov   dx, ax
mov   word ptr ds:[bx + MENU_T.menu_laston], ax
shl   dx, 2
mov   bx, word ptr ds:[bx + 3]
add   dx, ax
add   bx, dx
cmp   byte ptr ds:[bx], 2
jne   label_131
mov   ax, 1
mov   dx, SFX_STNMOV
call  word ptr ds:[bx + 2]
label_133:
xor   ax, ax
call  S_StartSound_
mov   al, cl
cbw  
call  Z_QuickMapByTaskNum_
mov   al, 1
pop   si
pop   cx
pop   bx
retf  
label_125:
jmp   label_132
label_131:
call  word ptr ds:[bx + 2]
mov   dx, 1
jmp   label_133
label_132:
mov   word ptr ds:[_itemOn], dx
xor   ax, bx
mov   dx, SFX_PSTOP
call  S_StartSound_
mov   al, 1
pop   si
pop   cx
pop   bx
retf  
label_129:
xor   dx, dx
cmp   word ptr ds:[_itemOn], 0
jl    exit_m_responder_return_0
xor   cx, cx
label_134:
mov   si, word ptr ds:[_currentMenu]
mov   si, word ptr ds:[si + 3]
add   si, cx
mov   al, byte ptr ds:[si + 4]
cbw  
cmp   ax, bx
je    label_132
inc   dx
add   cx, 5
cmp   dx, word ptr ds:[_itemOn]
jle   label_134
exit_m_responder_return_0:
xor   al, al
pop   si
pop   cx
pop   bx
retf  

ENDP

PROC    M_StartControlPanel_ NEAR
PUBLIC  M_StartControlPanel_


push  bx
mov   bx, _menuactive
cmp   byte ptr ds:[bx], 0
je    label_135
pop   bx
ret   
label_135:
mov   byte ptr ds:[bx], 1
mov   bx, word ptr ds:[_MainDef + MENU_T.menu_laston]
mov   word ptr ds:[_currentMenu], OFFSET _MainDef
mov   word ptr ds:[_itemOn], bx
pop   bx
ret   

ENDP

SKULLXOFF = 32

PROC    M_Drawer_ NEAR
PUBLIC  M_Drawer_

push  bx
push  cx
push  dx
push  si
push  di
push  bp
mov   bp, sp
sub   sp, 036h
mov   byte ptr [bp - 2], al
mov   byte ptr ds:[_inhelpscreens], 0
cmp   byte ptr ds:[_messageToPrint], 0
jne   label_136
mov   bx, _menuactive
cmp   byte ptr ds:[bx], 0
jne   label_137
LEAVE_MACRO 
pop   di
pop   si
pop   dx
pop   cx
pop   bx
retf  
label_136:
call  Z_QuickMapStatus_
mov   ax, _menu_messageString
mov   dx, ds
call  M_StringHeight_
mov   dx, 100
sar   ax, 1
sub   dx, ax
mov   word ptr [bp - 0Eh], 0
mov   word ptr [bp - 8], dx
cmp   byte ptr ds:[_menu_messageString], 0
je    label_138
label_144:
mov   ax, _menu_messageString
mov   bx, word ptr [bp - 0Eh]
mov   cx, ds
add   ax, word ptr [bp - 0Eh]
xor   si, si
mov   word ptr [bp - 4], ax
label_141:
mov   ax, word ptr [bp - 4]
mov   dx, ds
call  locallib_strlen_
cmp   si, ax
jge   label_139
lea   di, [si + 1]
cmp   byte ptr ds:[bx + _menu_messageString], 0Ah   ; newline char
je    label_140
inc   bx
mov   si, di
jmp   label_141
label_137:
jmp   label_142
label_138:
jmp   label_143
label_140:
mov   bx, word ptr [bp - 4]
lea   ax, [bp - 036h]
push  si
mov   dx, ds
call  locallib_strncpy_
add   word ptr [bp - 0Eh], di
mov   byte ptr [bp + si - 036h], 0
label_139:
mov   bx, _menu_messageString
add   bx, word ptr [bp - 0Eh]
mov   dx, ds
mov   ax, bx
mov   cx, ds
call  locallib_strlen_
cmp   si, ax
jne   label_151
lea   ax, [bp - 036h]
mov   dx, ds
call  locallib_strcpy_
add   word ptr [bp - 0Eh], si
label_151:
lea   ax, [bp - 036h]
mov   dx, ds
call  M_StringWidth_
mov   dx, 160
sar   ax, 1
lea   bx, [bp - 036h]
sub   dx, ax
mov   cx, ds
mov   ax, dx
mov   dx, word ptr [bp - 8]
call  M_WriteText_
mov   bx, word ptr [bp - 0Eh]
add   word ptr [bp - 8], 8
cmp   byte ptr ds:[bx + _menu_messageString], 0
je    label_143
jmp   label_144
label_143:
cmp   byte ptr [bp - 2], 0
je    label_145
call  Z_QuickMapWipe_
LEAVE_MACRO 
pop   di
pop   si
pop   dx
pop   cx
pop   bx
retf  
label_145:
call  Z_QuickMapPhysics_
LEAVE_MACRO 
pop   di
pop   si
pop   dx
pop   cx
pop   bx
retf  
label_142:
call  Z_QuickMapMenu_
mov   bx, word ptr ds:[_currentMenu]
cmp   word ptr ds:[bx + 5], 0
je    label_147
call  word ptr ds:[bx + 5]
label_147:
mov   bx, word ptr ds:[_currentMenu]
mov   ax, word ptr ds:[bx + 7]
mov   word ptr [bp - 0Ch], ax
mov   al, byte ptr ds:[bx + 9]
xor   ah, ah
mov   si, ax
mov   al, byte ptr ds:[bx]
cbw  
mov   word ptr [bp - 6], 0
mov   word ptr [bp - 0Ah], ax
test  ax, ax
jle   label_148
xor   di, di
label_101:
mov   bx, word ptr ds:[_currentMenu]
mov   bx, word ptr ds:[bx + 3]
add   bx, di
mov   al, byte ptr ds:[bx + 1]
cmp   al, -1
je    label_149

call  M_GetMenuPatch_
mov   cx, dx
mov   bx, ax
mov   ax, word ptr [bp - 0Ch]
mov   dx, si
call  V_DrawPatchDirect_
label_149:
inc   word ptr [bp - 6]
add   si, LINEHEIGHT
mov   bx, word ptr [bp - 6]
add   di, 5
cmp   bx, word ptr [bp - 0Ah]
jl    label_101
label_148:
mov   bx, _whichSkull
mov   bx, word ptr ds:[bx]
add   bx, bx
mov   al, word ptr ds:[bx + _skullName]
mov   di, word ptr [bp - 0Ch]
call  M_GetMenuPatch_
mov   bx, word ptr ds:[_currentMenu]
sub   di, SKULLXOFF
mov   bl, byte ptr ds:[bx + 9]
mov   si, word ptr ds:[_itemOn]
xor   bh, bh
shl   si, 4
sub   bx, 5
mov   cx, dx
add   si, bx
mov   bx, ax
mov   dx, si
mov   ax, di
call  V_DrawPatchDirect_
cmp   byte ptr [bp - 2], 0
jne   label_146
jmp   label_145
label_146:
call  Z_QuickMapWipe_
LEAVE_MACRO 
pop   di
pop   si
pop   dx
pop   cx
pop   bx
retf  


ENDP

PROC    M_SetupNextMenu_ NEAR
PUBLIC  M_SetupNextMenu_

push  bx
mov   bx, ax
mov   bx, word ptr ds:[bx + MENU_T.menu_laston]
mov   word ptr ds:[_currentMenu], ax
mov   word ptr ds:[_itemOn], bx
pop   bx
ret   
cld   


ENDP

PROC    M_Ticker_    NEAR
PUBLIC  M_Ticker_

push  bx
mov   bx, _skullAnimCounter
dec   word ptr ds:[bx]
cmp   word ptr ds:[bx], 0
jle   label_150
pop   bx
ret   
label_150:
mov   bx, _whichSkull
xor   byte ptr ds:[bx], 1
mov   bx, _skullAnimCounter
mov   word ptr ds:[bx], 8
pop   bx
ret   
push  ax
mov   ax, FIXED_DS_SEGMENT
mov   ds, ax
pop   ax
retf  


ENDP
@

PROC    M_MENU_ENDMARKER_ NEAR
PUBLIC  M_MENU_ENDMARKER_
ENDP


END
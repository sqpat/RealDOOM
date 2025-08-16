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


EXTRN _saveSlot:BYTE
EXTRN _saveCharIndex:WORD
EXTRN _saveStringEnter:BYTE
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
SOUNDDEF_X = 80
SOUNDDEF_Y = 64
OPTIONSDEF_X = 60
OPTIONSDEF_Y = 37


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
add   di, LINEHEIGHT
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

push  word ptr ds:[_LoadDef + MENU_T.menu_laston]
pop   word ptr ds:[_itemOn]
mov   word ptr ds:[_currentMenu], OFFSET _LoadDef  ; inlined setupnextmenu


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

PUSHA_NO_AX_OR_BP_MACRO

call  Z_QuickMapStatus_
mov   al, MENUPATCH_M_SAVEG
call  M_GetMenuPatch_
xchg  ax, bx
mov   cx, dx

mov   di, LOADDEF_Y


mov   dx, 28
mov   ax, 72

call  V_DrawPatchDirect_

xor   si, si

loop_draw_next_save_bar:

mov   dx, di
mov   ax, LOADDEF_X
call  M_DrawSaveLoadBorder_

mov   cx, SAVEGAMESTRINGS_SEGMENT
mov   bx, si
mov   dx, di
mov   ax, LOADDEF_X
call  M_WriteText_

add   si, SAVESTRINGSIZE
add   di, LINEHEIGHT
cmp   si, (LOAD_END * SAVESTRINGSIZE)
jl    loop_draw_next_save_bar

cmp   byte ptr ds:[_saveStringEnter], 0
je    exit_drawsave

mov   al, SAVESTRINGSIZE
mov   bl, byte ptr ds:[_saveSlot]
mul   bl

mov   dx, SAVEGAMESTRINGS_SEGMENT
call  M_StringWidth_

xchg  ax, si ; store.

mov   al, LINEHEIGHT
mul   bl

xchg  ax, dx
add   dx, di
sub   dx, (LOAD_END * LINEHEIGHT)

xchg  ax, si
add   ax, LOADDEF_X

mov   cx, cs
mov   bx, OFFSET _menu_string_underscore
call  M_WriteText_

exit_drawsave:

POPA_NO_AX_OR_BP_MACRO

ret   


ENDP



PROC    M_DoSave_ NEAR
PUBLIC  M_DoSave_

push  bx
push  cx
push  dx
mov   dx, ax
mov   ah, SAVESTRINGSIZE
mul   ah
xchg  ax, bx
mov   ax, dx
mov   cx, SAVEGAMESTRINGS_SEGMENT
cbw  
call  G_SaveGame_

mov   byte ptr ds:[_menuactive], 0
cmp   byte ptr ds:[_quickSaveSlot], -2
jne   dont_update_quicksaveslot
mov   byte ptr ds:[_quickSaveSlot], dl
dont_update_quicksaveslot:
pop   dx
pop   cx
pop   bx
ret   



ENDP



PROC    M_SaveSelect_ NEAR
PUBLIC  M_SaveSelect_
;void __near M_SaveSelect(int16_t choice){


PUSHA_NO_AX_OR_BP_MACRO
push  bp
mov   bp, sp
sub   sp, 0100h

mov   byte ptr ds:[_saveSlot], al
xchg  bx, ax ; backup
mov   al, SAVESTRINGSIZE
mul   bl
xchg  ax, si ; 
mov   byte ptr ds:[_saveStringEnter], 1

push  ds
pop   es
mov   ax, SAVEGAMESTRINGS_SEGMENT
mov   ds, ax
mov   cx, SAVESTRINGSIZE / 2
mov   di, OFFSET _saveOldString
rep   movsw

sub   si, SAVESTRINGSIZE ; si has original choice * savestringsize

push  ss
pop   ds ; restore ds.

lea   bx, [bp - 0100h]
mov   ax, EMPTYSTRING
mov   cx, ds
mov   dx, SAVEGAMESTRINGS_SEGMENT
call  getStringByIndex_

lea   bx, [bp - 0100h]
mov   cx, ds
mov   ax, si
call  locallib_strcmp_   ; todo make this carry based?
mov   dx, SAVEGAMESTRINGS_SEGMENT
test  ax, ax
jne   not_empty_string
mov   es, dx
mov   byte ptr es:[si], 0
not_empty_string:
xchg  ax, si  ; retrieve once more
call  M_Strlen_
mov   word ptr ds:[_saveCharIndex], ax
LEAVE_MACRO 
POPA_NO_AX_OR_BP_MACRO
ret   


ENDP


;void __near M_SaveGame (int16_t choice){

PROC    M_SaveGame_ NEAR
PUBLIC  M_SaveGame_


push  bx
push  cx
push  dx
push  bp
mov   bp, sp
sub   sp, 0100h
xor   ax, ax
cmp   byte ptr ds:[_usergame], al
jne   can_save_game

lea   bx, [bp - 0100h]
mov   ax, SAVEDEAD
mov   cx, ds
call  getStringByIndex_
xor   dx, dx
lea   ax, [bp - 0100h]
mov   bx, dx
call  M_StartMessage_
jmp   exit_m_savegame

can_save_game:
cmp   byte ptr ds:[_gamestate], al
jne   exit_m_savegame

push  word ptr ds:[_SaveDef + MENU_T.menu_laston]
pop   word ptr ds:[_itemOn]
mov   word ptr ds:[_currentMenu], OFFSET _SaveDef
call  M_ReadSaveStrings_


exit_m_savegame:
LEAVE_MACRO 
pop   dx
pop   cx
pop   bx
ret   

   

ENDP


PROC    M_QuickSaveResponse_ NEAR
PUBLIC  M_QuickSaveResponse_

cmp   al, 'y'  ; 079h
jne   exit_quicksave
do_quicksave:
push  dx
mov   al, byte ptr ds:[_quickSaveSlot]
cbw  
call  M_DoSave_
mov   dx, SFX_SWTCHX
xor   ax, ax
call  S_StartSound_
pop   dx
exit_quicksave:
ret   
   



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
je    cant_save_not_in_game

cmp   byte ptr ds:[_gamestate], 0
jne   exit_m_quicksave
cmp   byte ptr ds:[_quickSaveSlot], 0
jl    no_quicksave_slot
lea   bx, [bp + 04ch]
mov   ax, QSPROMPT
mov   cx, ds
call  getStringByIndex_
lea   bx, [bp + 07Eh]
mov   ax, QLQLPROMPTEND
mov   cx, ds
call  getStringByIndex_
mov   al, byte ptr ds:[_quickSaveSlot]
mov   ah, SAVESTRINGSIZE
mul   ah
mov   dx, SAVEGAMESTRINGS_SEGMENT
push  dx
push  ax
mov   dx, ds
mov   cx, ds
lea   bx, [bp + 04Ch]
lea   ax, [bp - 04Ah]
call  combine_strings_

lea   ax, [bp + 07Eh]
push  ds
push  ax
lea   bx, [bp - 04Ah]
mov   ax, bx
mov   dx, ds
mov   cx, ds
call  combine_strings_
mov   bx, 1
mov   dx, OFFSET M_QuickSaveResponse_
lea   ax, [bp - 04Ah]
call  M_StartMessage_
exit_m_quicksave:
lea   sp, [bp + 098h]
pop   bp
pop   dx
pop   cx
pop   bx
ret   
cant_save_not_in_game:
mov   dx, SFX_OOF
xor   ah, ah
call  S_StartSound_
jmp   exit_m_quicksave

no_quicksave_slot:
call  M_StartControlPanel_
call  M_ReadSaveStrings_
mov   word ptr ds:[_currentMenu], OFFSET _SaveDef
push  word ptr ds:[_SaveDef + MENU_T.menu_laston]
pop   word ptr ds:[_itemOn]
mov   byte ptr ds:[_quickSaveSlot], -2
jmp   exit_m_quicksave



ENDP



PROC    M_QuickLoadResponse_ NEAR
PUBLIC  M_QuickLoadResponse_


cmp   al, 'y' ; 079h
jne   exit_quickload
push  dx
mov   al, byte ptr ds:[_quickSaveSlot]
cbw  
call  M_LoadSelect_
mov   dx, SFX_SWTCHX
xor   ax, ax
call  S_StartSound_
pop   dx
exit_quickload:
ret   

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
jl    no_quickload_slot
lea   bx, [bp + 04Ch]
mov   ax, QLPROMPT
mov   cx, ds
call  getStringByIndex_
lea   bx, [bp + 07Eh]
mov   ax, QLQLPROMPTEND
mov   cx, ds
call  getStringByIndex_
mov   al, byte ptr ds:[_quickSaveSlot]
mov   ah, SAVESTRINGSIZE
mul   ah
mov   dx, SAVEGAMESTRINGS_SEGMENT
push  dx
push  ax
mov   dx, ds
mov   cx, ds
lea   bx, [bp + 04Ch]
lea   ax, [bp - 04Ah]
call  combine_strings_

lea   dx, [bp + 07Eh]
lea   bx, [bp - 04Ah]
mov   ax, bx
push  ds
push  dx
mov   cx, ds
mov   dx, ds
call  combine_strings_
mov   bx, 1
mov   dx, OFFSET M_QuickLoadResponse_
show_message_and_exitquickload:
lea   ax, [bp - 04Ah]
call  M_StartMessage_
lea   sp, [bp + 098h]
pop   bp
pop   dx
pop   cx
pop   bx
ret   
no_quickload_slot:
lea   bx, [bp - 04Ah]
mov   ax, QSAVESPOT
mov   cx, ds
call  getStringByIndex_
xor   dx, dx
xor   bx, bx
jmp   show_message_and_exitquickload


ENDP



PROC    M_DrawReadThis1_ NEAR
PUBLIC  M_DrawReadThis1_

push  dx
mov   ax, OFFSET _STRING_HELP2
xor   dx, dx
mov   byte ptr ds:[_inhelpscreens], 1
call  V_DrawFullscreenPatch_
pop   dx
ret   


ENDP

PROC    M_DrawReadThis2_ NEAR
PUBLIC  M_DrawReadThis2_


push  dx
mov   ax, OFFSET _STRING_HELP1
xor   dx, dx
mov   byte ptr ds:[_inhelpscreens], 1
call  V_DrawFullscreenPatch_
pop   dx
ret   


ENDP

PROC    M_DrawReadThisRetail_ NEAR
PUBLIC  M_DrawReadThisRetail_

push  dx
mov   ax, OFFSET _STRING_HELP
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
xchg  ax, bx
mov   dx, 38
mov   ax, 60
call  V_DrawPatchDirect_
mov   bx, 16
mov   ax, SOUNDDEF_X
mov   dx, SOUNDDEF_Y  + LINEHEIGHT*(SOUND_E_SFX_VOL+1)
mov   cl, byte ptr ds:[_sfxVolume]
call  M_DrawThermo_
mov   bx, 16
mov   ax, SOUNDDEF_X
mov   dx, SOUNDDEF_Y + LINEHEIGHT*(SOUND_E_MUSIC_VOL+1)
mov   cl, byte ptr ds:[_musicVolume]
call  M_DrawThermo_
pop   dx
pop   cx
pop   bx
ret   



ENDP

PROC    M_Sound_ NEAR
PUBLIC  M_Sound_


push  word ptr ds:[_SoundDef + MENU_T.menu_laston]
pop   word ptr ds:[_itemOn]
mov   word ptr ds:[_currentMenu], OFFSET _SoundDef
ret   

ENDP




PROC    M_SfxVol_ NEAR
PUBLIC  M_SfxVol_


cmp   al, 1
mov   al, byte ptr ds:[_sfxVolume]
jne   do_decrease
cmp   al, 15
jae   done_updating_vol
inc   ax
done_updating_vol:
cbw
mov   byte ptr ds:[_sfxVolume], al
call  S_SetSfxVolume_  ; todo move local?
ret   
do_decrease:
test  al, al
je    done_updating_vol
dec   ax
jmp   done_updating_vol


ENDP

PROC    M_MusicVol_ NEAR
PUBLIC  M_MusicVol_


cmp   al, 1
mov   al, byte ptr ds:[_musicVolume]
jne   do_music_decrease
cmp   al, 15
jae   done_updating_music_vol
inc   ax
done_updating_music_vol:
cbw
mov   byte ptr ds:[_musicVolume], al
call  S_SetMusicVolume_  ; todo move local?
ret   
do_music_decrease:
test  al, al
je    done_updating_music_vol
dec   ax
jmp   done_updating_music_vol


ENDP



PROC    M_DrawMainMenu_ NEAR
PUBLIC  M_DrawMainMenu_


push  bx
push  cx
push  dx
xor   ax, ax ; MENUPATCH_M_DOOM
call  M_GetMenuPatch_
xchg  ax, bx
mov   cx, dx
mov   dx, 2
mov   ax, 94
call  V_DrawPatchDirect_
pop   dx
pop   cx
pop   bx
ret   


ENDP


PROC    M_DrawNewGame_ NEAR
PUBLIC  M_DrawNewGame_


push  bx
push  cx
push  dx
mov   al, MENUPATCH_M_NEWG
call  M_GetMenuPatch_

xchg  ax, bx
mov   cx, dx
mov   dx, 14
mov   ax, 96
call  V_DrawPatchDirect_

mov   al, MENUPATCH_M_SKILL
call  M_GetMenuPatch_

xchg  ax, bx
mov   cx, dx
mov   dx, 38
mov   ax, 54
call  V_DrawPatchDirect_

pop   dx
pop   cx
pop   bx
ret   


ENDP

PROC    M_NewGame_ NEAR
PUBLIC  M_NewGame_

push  bx
mov   bx, OFFSET _EpiDef
cmp   byte ptr ds:[_commercial], 0
je    do_episode_menu
mov   bx, OFFSET _NewDef
do_episode_menu:
push  word ptr ds:[bx + MENU_T.menu_laston]
pop   word ptr ds:[_itemOn]
mov   word ptr ds:[_currentMenu], bx
pop   bx
ret

ENDP



PROC    M_DrawEpisode_ NEAR
PUBLIC  M_DrawEpisode_


push  bx
push  cx
push  dx
mov   al, MENUPATCH_M_EPISOD
call  M_GetMenuPatch_
xchg  ax, bx
mov   cx, dx
mov   dx, 38
mov   ax, 54
call  V_DrawPatchDirect_
pop   dx
pop   cx
pop   bx
ret   


ENDP

PROC    M_VerifyNightmare_ NEAR
PUBLIC  M_VerifyNightmare_


cmp   al, 'y' ; 079h
jne   exit_verify_nightmare
push  bx
push  dx
xor   dx, dx
mov   dl, byte ptr ds:[_menu_epi]
inc   dx
mov   bx, 1
mov   ax, SK_NIGHTMARE
call  G_DeferedInitNew_
mov   byte ptr ds:[_menuactive], 0
pop   dx
pop   bx
exit_verify_nightmare:
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

cmp   al, 4
jne   not_nightmare
lea   bx, [bp - 0100h]
mov   ax, NIGHTMARE
mov   cx, ds
mov   dx, OFFSET M_VerifyNightmare_
call  getStringByIndex_
mov   bx, 1
lea   ax, [bp - 0100h]
call  M_StartMessage_
jmp   exit_choose_skill
not_nightmare:
xor   dx, dx
mov   dl, byte ptr ds:[_menu_epi]
inc   dx
mov   bx, 1
call  G_DeferedInitNew_
mov   byte ptr ds:[_menuactive], 0
exit_choose_skill:
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

cmp   byte ptr ds:[_shareware], 0
je    show_episode
test  ax, ax
jne   force_shareware_msg

show_episode:
mov   byte ptr ds:[_menu_epi], al
mov   word ptr ds:[_currentMenu], OFFSET _NewDef  
push  word ptr ds:[_NewDef + MENU_T.menu_laston]
jmp   pop_and_exit_m_episode


force_shareware_msg:
lea   bx, [bp - 0100h]
mov   ax, SWSTRING
mov   cx, ds
call  getStringByIndex_
xor   dx, dx
lea   ax, [bp - 0100h]
xor   bx, bx
call  M_StartMessage_
mov   word ptr ds:[_currentMenu], OFFSET _ReadDef1
push  word ptr ds:[_ReadDef1 + MENU_T.menu_laston]
pop_and_exit_m_episode:
pop   word ptr ds:[_itemOn]
LEAVE_MACRO 
pop   dx
pop   cx
pop   bx
ret   


ENDP

PROC    M_DrawOptions_ NEAR
PUBLIC  M_DrawOptions_

PUSHA_NO_AX_OR_BP_MACRO
mov   al, MENUPATCH_M_OPTTTL
call  M_GetMenuPatch_
mov   cx, dx
xchg  ax, bx
mov   dx, 15
mov   ax, 108
call  V_DrawPatchDirect_

xor   bx, bx
mov   bl, byte ptr ds:[_detailLevel]
mov   al, byte ptr ds:[bx + _detailNames]
call  M_GetMenuPatch_

xchg  ax, bx
mov   cx, dx

mov   dx, OPTIONSDEF_Y + LINEHEIGHT*OPTIONS_E_DETAIL
mov   ax, OPTIONSDEF_X + 175
call  V_DrawPatchDirect_

xor   bx, bx
mov   bl, byte ptr ds:[_showMessages]

mov   al, byte ptr ds:[bx + _msgNames]
call  M_GetMenuPatch_

xchg  ax, bx
mov   cx, dx

mov   dx, OPTIONSDEF_Y + LINEHEIGHT*OPTIONS_E_MESSAGES
mov   ax, OPTIONSDEF_X + 120

call  V_DrawPatchDirect_
mov   bx, 10
mov   cl, byte ptr ds:[_mouseSensitivity]
mov   ax, OPTIONSDEF_X
mov   dx, OPTIONSDEF_Y + LINEHEIGHT*(OPTIONS_E_MOUSESENS+1)

call  M_DrawThermo_

mov   bx, 11
mov   cl, byte ptr ds:[_screenSize]
mov   ax, OPTIONSDEF_X
mov   dx, OPTIONSDEF_Y + LINEHEIGHT*(OPTIONS_E_SCRNSIZE+1)
call  M_DrawThermo_

POPA_NO_AX_OR_BP_MACRO
ret   




ENDP

PROC    M_Options_ NEAR
PUBLIC  M_Options_


push  word ptr ds:[_OptionsDef + MENU_T.menu_laston]
pop   word ptr ds:[_itemOn]
mov   word ptr ds:[_currentMenu], OFFSET _OptionsDef
ret   



ENDP


PROC    M_ChangeMessages_ NEAR
PUBLIC  M_ChangeMessages_



mov   ax, MSGON
xor   byte ptr ds:[_showMessages], 1
jnz   use_message_on
dec   ax
use_message_on:
mov   word ptr ds:[_player + PLAYER_T.player_message], ax
mov   byte ptr ds:[_message_dontfuckwithme], 1
ret   


ENDP



PROC    M_EndGameResponse_ NEAR
PUBLIC  M_EndGameResponse_



cmp   al, 'y' ; 079h
jne   exit_endgame_response
push  bx
;    currentMenu->lastOn = itemOn;
mov   bx,  word ptr ds:[_currentMenu]

push  word ptr ds:[_itemOn]
pop   word ptr ds:[bx + MENU_T.menu_laston]
mov   byte ptr ds:[_menuactive], 0
call  D_StartTitle_
pop   bx
exit_endgame_response:
ret   
   


ENDP

PROC    M_EndGame_ NEAR
PUBLIC  M_EndGame_



push  bx
push  cx
push  dx
push  bp
mov   bp, sp
sub   sp, 0100h
xor   ax, ax
cmp   byte ptr ds:[_usergame], al
jne   do_endgame
mov   dx, SFX_OOF
call  S_StartSound_
exit_end_game:
LEAVE_MACRO 
pop   dx
pop   cx
pop   bx
ret   
do_endgame:
lea   bx, [bp - 0100h]
mov   ax, ENDGAME
mov   cx, ds
mov   dx, OFFSET M_EndGameResponse_
call  getStringByIndex_
mov   bx, 1
lea   ax, [bp - 0100h]
call  M_StartMessage_
jmp   exit_end_game


ENDP

PROC    M_ReadThis_ NEAR
PUBLIC  M_ReadThis_



cmp   byte ptr ds:[_is_ultimate], 0
jne   M_ReadThis2_

push  word ptr ds:[_ReadDef1 + MENU_T.menu_laston]
pop   word ptr ds:[_itemOn]
mov   word ptr ds:[_currentMenu], OFFSET _ReadDef1
ret      


ENDP

PROC    M_ReadThis2_ NEAR
PUBLIC  M_ReadThis2_

push  word ptr ds:[_ReadDef2 + MENU_T.menu_laston]
pop   word ptr ds:[_itemOn]
mov   word ptr ds:[_currentMenu], OFFSET _ReadDef2
ret   
   


ENDP

PROC    M_FinishReadThis_ NEAR
PUBLIC  M_FinishReadThis_

push  word ptr ds:[_MainDef + MENU_T.menu_laston]
pop   word ptr ds:[_itemOn]
mov   word ptr ds:[_currentMenu], OFFSET _MainDef
ret   
   

ENDP

_quitsounds_1:
db SFX_VILACT
db SFX_GETPOW
db SFX_BOSCUB
db SFX_SLOP
db SFX_SKESWG
db SFX_KNTDTH
db SFX_BSPACT
db SFX_SGTATK


_quitsounds_2:

db SFX_PLDETH
db SFX_DMPAIN
db SFX_POPAIN
db SFX_SLOP
db SFX_TELEPT
db SFX_POSIT1
db SFX_POSIT3
db SFX_SGTATK


PROC    M_QuitResponse_ NEAR
PUBLIC  M_QuitResponse_

push  bx
push  dx

cmp   al, 'y' ; 079h
jne   exit_m_quitresponse
mov   bx, OFFSET _quitsounds_2
cmp   byte ptr ds:[_commercial], 0
je    label_33
mov   bx, OFFSET _quitsounds_1
label_33:
mov   ax, word ptr ds:[_gametic]

sar   ax, 1
sar   ax, 1
and   ax, 7
add   bx, ax
xor   ax, ax
cwd
mov   dl, byte ptr cs:[bx]
call  S_StartSound_
mov   ax, 105
call  I_WaitVBL_
call  I_Quit_
exit_m_quitresponse:

pop   dx
pop   bx
ret   


ENDP

COMMENT @

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

@


PROC    M_DrawThermo_ NEAR
PUBLIC  M_DrawThermo_

push  si
push  di
push  bp
mov   bp, bx ; count in bp

mov   di, dx  ; di holds y.
xchg  ax, si  ; si holds xx. x + 8 combined with cx and written forward

mov   al, MENUPATCH_M_THERMM
call  M_GetMenuPatch_
mov   word ptr cs:[SELFMODIFY_thermm_offset+1], ax
mov   word ptr cs:[SELFMODIFY_thermm_segment+1], dx

mov   al, MENUPATCH_M_THERML
call  M_GetMenuPatch_

xchg  bx, ax
mov   ax, si
add   si, 8

xor   ch, ch
SHIFT_MACRO sal cx 3
add   cx, si
mov   word ptr cs:[SELFMODIFY_thermDot+1], cx



mov   cx, dx
mov   dx, di

call  V_DrawPatchDirect_


loop_next_thermo:

SELFMODIFY_thermm_offset:
mov   bx, 01000h
SELFMODIFY_thermm_segment:
mov   cx, 01000h
mov   dx, di
mov   ax, si

call  V_DrawPatchDirect_
add   si, 8
dec   bp
jnz   loop_next_thermo
done_with_thermo_loop:

mov   al, MENUPATCH_M_THERMR
call  M_GetMenuPatch_

xchg  bx, ax
mov   cx, dx
mov   dx, di
mov   ax, si

call  V_DrawPatchDirect_
mov   al, MENUPATCH_M_THERMO
call  M_GetMenuPatch_


xchg  ax, bx
mov   cx, dx


mov   dx, di
SELFMODIFY_thermDot:
mov   ax, 01000h
call  V_DrawPatchDirect_

pop   bp
pop   di
pop   si
ret   



ENDP


;void __near M_StartMessage ( int8_t __near * string, void __near (*routine)(int16_t), boolean input ) {

; ax string
; dx routine
; bx input boolean

PROC    M_StartMessage_ NEAR
PUBLIC  M_StartMessage_

push  cx

mov   word ptr ds:[_messageRoutine], dx
mov   byte ptr ds:[_messageNeedsInput], bl
mov   byte ptr ds:[_messageToPrint], 1
mov   byte ptr ds:[_menuactive], 1
xchg  ax, bx  ; bx gets string ptr.

mov   al, byte ptr ds:[_menuactive]
cbw  
mov   word ptr ds:[_messageLastMenuActive], ax

mov   dx, ds
mov   cx, ds
mov   ax, OFFSET _menu_messageString
call  locallib_strcpy_  ; todo make local

pop   cx
ret   

ENDP



PROC    M_Strlen_ NEAR

push    cx
push    di

mov     cx, -1
mov     es, dx
mov     dx, ax
xchg    ax, di
xor     ax, ax
repne   scasb
sub     di, dx
xchg    ax, di
dec     ax

pop     di
pop     cx


ret
ENDP


PROC    M_StringWidth_ NEAR
PUBLIC  M_StringWidth_

push  bx
push  cx
push  si

mov   si, ax
mov   ds, dx  ; for lodsb

call  M_Strlen_


xor   dx, dx  ; dx is width
test  ax, ax
jle   exit_stringwidth
xchg  ax, cx
add   cx, si  ; cx is end condition (startcondition + count)


mov   bx, FONT_WIDTHS_SEGMENT
mov   es, bx


loop_next_char_stringwidth:

lodsb
call  M_ToUpper_
sub   al, HU_FONTSTART
js    bad_char_do_space
cmp   al, HU_FONTSIZE
ja    bad_char_do_space
good_char:
cbw
xchg  ax, bx
mov   al, byte ptr es:[bx]
cbw  
add   dx, ax

iter_next_char_stringwidth:
cmp   si, cx
jl    loop_next_char_stringwidth

exit_stringwidth:
xchg  ax, dx
push  ss
pop   ds
pop   si
pop   cx
pop   bx
ret   
bad_char_do_space:
add   dx, 4
jmp   iter_next_char_stringwidth


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
call  M_Strlen_
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
cmp   byte ptr ds:[_saveStringEnter], 0
je    label_59
cmp   bx, KEY_BACKSPACE
jne   label_60
cmp   word ptr ds:[_saveCharIndex], 0
jle   exit_m_responder_return_1
imul  bx, byte ptr ds:[_saveSlot], SAVESTRINGSIZE
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
mov   byte ptr ds:[_saveStringEnter], al
imul  cx, byte ptr ds:[_saveSlot], SAVESTRINGSIZE
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
imul  bx, byte ptr ds:[_saveSlot], SAVESTRINGSIZE
xor   ax, ax
mov   dx, SAVEGAMESTRINGS_SEGMENT
mov   byte ptr ds:[_saveStringEnter], al
mov   es, dx
cmp   byte ptr es:[bx], 0
je    exit_m_responder_return_1
mov   al, byte ptr ds:[_saveSlot]
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
imul  ax, byte ptr ds:[_saveSlot], SAVESTRINGSIZE
mov   dx, SAVEGAMESTRINGS_SEGMENT
call  M_StringWidth_
cmp   ax, ((SAVESTRINGSIZE-2)*8) ; 0B0h
jae   jump_to_exit_m_responder_return_1
imul  ax, byte ptr ds:[_saveSlot], SAVESTRINGSIZE
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

@

PROC    M_StartControlPanel_ NEAR
PUBLIC  M_StartControlPanel_


cmp   byte ptr ds:[_menuactive], 0
jne   exit_m_startcontrolpanel
mov   byte ptr ds:[_menuactive], 1
push  word ptr ds:[_MainDef + MENU_T.menu_laston]
mov   word ptr ds:[_currentMenu], OFFSET _MainDef
pop   word ptr ds:[_itemOn]
exit_m_startcontrolpanel:
ret   

ENDP

COMMENT @

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
call  M_Strlen_
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
call  M_Strlen_
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
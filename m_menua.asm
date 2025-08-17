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

_menu_messageString:
REPT 100
    db 0
ENDM

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

cmp   al, SK_NIGHTMARE
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
je    use_quitsounds_2
mov   bx, OFFSET _quitsounds_1
use_quitsounds_2:
mov   al, byte ptr ds:[_gametic]

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


PROC    M_QuitDOOM_ NEAR
PUBLIC  M_QuitDOOM_


push  bx
push  cx
push  dx
push  bp
mov   bp, sp
sub   sp, 088h
sub   bp, 09ch

mov   al, byte ptr ds:[_gametic]
sar   ax, 1
sar   ax, 1
and   ax, 7
xchg  ax, dx


mov   cx, FIXED_DS_SEGMENT ; todo DS
lea   bx, [bp + 07Eh]
mov   ax, DOSY
call  getStringByIndex_
xchg  ax, dx
test  ax, ax
je    force_message_as_2

cmp   byte ptr ds:[_commercial], 0
je    use_doom1_msg
add   ax, QUITMSGD21 - 1
got_message:
lea   bx, [bp + 014h]
mov   cx, ds
mov   dx, bx
call  getStringByIndex_

mov   bx, _STRING_newline
lea   ax, [bp + 014h]
call  combine_strings_near_

lea   bx, [bp + 07Eh]
lea   ax, [bp + 014h]
mov   dx, ax

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
force_message_as_2:
mov   ax, 2
jmp   got_message
use_doom1_msg:
add   ax, QUITMSGD11 - 1
jmp   got_message


ENDP



PROC    M_ChangeSensitivity_ NEAR
PUBLIC  M_ChangeSensitivity_

cmp   al, 1
mov   al, byte ptr ds:[_mouseSensitivity]
cbw
jne   do_dec_sensitivity
cmp   al, 9
jae   exit_change_set_sensitivity
inc   ax
set_sensitivity_and_return:
mov   byte ptr ds:[_mouseSensitivity], al
exit_change_set_sensitivity:
ret   
do_dec_sensitivity:
test  al, al
je    exit_change_set_sensitivity
dec   ax
jmp   set_sensitivity_and_return

ENDP


_detaillevel_lookup:
dw DETAILHI, DETAILLO, DETAILPOTATO

PROC    M_ChangeDetail_ NEAR
PUBLIC  M_ChangeDetail_

push  bx
push  dx
mov   al, byte ptr ds:[_detailLevel]
inc   ax
cmp   al, 3
jne   dont_cap_detail
xor   ax, ax
dont_cap_detail:
cbw
mov   byte ptr ds:[_detailLevel], al
xchg  ax, dx
mov   bx, dx
shl   bx, 1
mov   al, byte ptr ds:[_screenblocks]
call  R_SetViewSize_

mov   ax, word ptr cs:[bx + _detaillevel_lookup]
mov   word ptr ds:[_player + PLAYER_T.player_message], ax

pop   dx
pop   bx
ret   


ENDP



PROC    M_SizeDisplay_ NEAR
PUBLIC  M_SizeDisplay_

push  dx
cmp   al, 1
mov   al, byte ptr ds:[_screenSize]
cbw
cwd
jne   dec_size
cmp   al, 10
jae   update_size_display

inc   ax
inc   byte ptr ds:[_screenblocks]
update_size_display:
mov   byte ptr ds:[_screenSize], al
mov   dl, byte ptr ds:[_detailLevel]
mov   al, byte ptr ds:[_screenblocks]

call  R_SetViewSize_

pop   dx
ret   
dec_size:
test  ax, ax
je    update_size_display
dec   ax
dec   byte ptr ds:[_screenblocks]
jmp   update_size_display

ENDP




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

mov   dx, cs
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

HU_FONT_SIZE = 8

PROC    M_StringHeight_ NEAR
PUBLIC  M_StringHeight_

push  cx
push  si

mov   si, ax
mov   cx, dx

call  M_Strlen_

mov   dx, HU_FONT_SIZE
test  ax, ax 
je    exit_stringheight
xchg  ax, cx ; cx gets len
mov   ds, ax ; ds gets segment
mov   ah, 0Ah ; newline
loop_next_stringheight:
lodsb
cmp   al, ah
jne   iter_next_char_stringheight
add   dx, HU_FONT_SIZE
iter_next_char_stringheight:
loop  loop_next_stringheight

push  ss
pop   ds


exit_stringheight:
xchg  ax, dx
pop   si
pop   cx
ret   


ENDP



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

exit_m_responder_return_false:
xor   ax, ax
jmp   exit_m_responder
savestringenter_is_escape:
mov   byte ptr ds:[_saveStringEnter], cl
mov   di, bx 
;mov   si, SAVEGAMESTRINGS_SEGMENT
;mov   es, si
mov   cx, SAVESTRINGSIZE / 2
mov   si, OFFSET _saveOldString
rep   movsw

jmp   exit_m_responder_return_1
savestringenter_is_backspace:
cmp   di, cx ; 0
jle   exit_m_responder_return_1

dec   di
mov   word ptr ds:[_saveCharIndex], di
mov   byte ptr es:[bx+di], cl
jmp   exit_m_responder_return_1



PROC    M_Responder_ FAR
PUBLIC  M_Responder_

push  bx
push  cx
push  si
push  di
xchg  ax, si
mov   es, dx  ; events_segment
xor   cx, cx
mov   ax, -1
cmp   byte ptr es:[si], cl ; 0 or EV_KEYDOWN
jne   no_char
mov   ax, word ptr es:[si + 1]
no_char:
cmp   al, -1
je    exit_m_responder_return_false
cmp   byte ptr ds:[_saveStringEnter], cl ; 0
je    not_savestringenter
xchg  ax, bx
mov   al, SAVESTRINGSIZE
mul   byte ptr ds:[_saveSlot]
mov   dx, SAVEGAMESTRINGS_SEGMENT
mov   es, dx
xchg  ax, bx
mov   di, word ptr ds:[_saveCharIndex]

; di is savecharindex
; dx/es are SAVEGAMESTRINGS_SEGMENT
; al is key
; bx is (_saveSlot * savestringsize)
; cx is 0

cmp   al, KEY_BACKSPACE
je    savestringenter_is_backspace
cmp   al, KEY_ESCAPE
je    savestringenter_is_escape
cmp   al, KEY_ENTER
je    savestringenter_is_enter

savestringenter_do_other_character:
call  M_ToUpper_
cmp   al, 32
jb    exit_m_responder_return_1
cmp   al, 127
ja    exit_m_responder_return_1

; saveCharIndex < (SAVESTRINGSIZE-1) &&
xchg  ax, bx  ; bx had saveslot * savestringsize. now it gets the char.
cmp   di, (SAVESTRINGSIZE-1)
jge   exit_m_responder_return_1
add   di, ax  ; di gets that added to offset for stosw later

; mov   dx, SAVEGAMESTRINGS_SEGMENT
call  M_StringWidth_

cmp   ax, (SAVESTRINGSIZE-2)*8 ; 0B0h
jae   exit_m_responder_return_1


xchg  ax, bx ; ax gets char

mov   dx, SAVEGAMESTRINGS_SEGMENT
mov   es, dx
inc   word ptr ds:[_saveCharIndex]
cbw
stosw  ; also hits 0 in 2nd byte.
exit_m_responder_return_1:
mov   al, 1
exit_m_responder:
pop   di
pop   si
pop   cx
pop   bx
retf  

savestringenter_is_enter:

mov   byte ptr ds:[_saveStringEnter], cl ; 0
cmp   byte ptr es:[bx], cl ; 0
je    exit_m_responder_return_1
mov   al, byte ptr ds:[_saveSlot]
call  M_DoSave_
jmp   exit_m_responder_return_1

not_savestringenter:
cmp   byte ptr ds:[_messageToPrint], cl ; 0
je    no_message_to_print_mresponder
cmp   byte ptr ds:[_messageNeedsInput], 1
jne   no_input_needed
cmp   al, 32
je    not_response_char

cmp   al, 06Eh  ; 'n'
je    not_response_char
cmp   al, 079h  ; 'y'
je    not_response_char
cmp   al, KEY_ESCAPE
je    not_response_char
jmp   exit_m_responder_return_0

no_input_needed:
not_response_char:

mov   dl, byte ptr ds:[_messageLastMenuActive]
mov   byte ptr ds:[_messageToPrint], cl ; 0
mov   byte ptr ds:[_menuactive], dl
cmp   word ptr ds:[_messageRoutine], cx ; 0
je    no_message_routine

call  word ptr ds:[_messageRoutine]
no_message_routine:
mov   byte ptr ds:[_menuactive], cl  ; 0

mov   dx, SFX_SWTCHX
jmp   play_sound_and_exit_m_responder_return_1


no_message_to_print_mresponder:
 
cmp   byte ptr ds:[_menuactive], cl 
jne   jump_to_menu_is_active

; KEY_MINUS  2d
; KEY_EQUALS 3d
; KEY_ESCAPE 1B
; KEY_F1     0BBh
; KEY_F10    0C4h
; KEY_F11    0D7h

cmp   al, KEY_MINUS
je    do_key_minus
cmp   al, KEY_EQUALS
je    do_key_equals
cmp   al, KEY_ESCAPE
je    do_key_escape
cmp   al, KEY_F1
je    do_key_f1
jb    didnt_find_key_in_nonmenu
cmp   al, KEY_F3
jb    do_key_f2
je    do_key_f3
cmp   al, KEY_F5
jb    do_key_f4
je    do_key_f5
cmp   al, KEY_F7
jb    do_key_f6
je    do_key_f7
cmp   al, KEY_F9
jb    do_key_f8
je    do_key_f9
cmp   al, KEY_F10
je    do_key_f10
cmp   al, KEY_F11
jne   didnt_find_key_in_nonmenu
jmp   do_key_f11

jump_to_menu_is_active:
jmp   menu_is_active
do_key_escape:
call  M_StartControlPanel_
jmp   play_switch_sound_and_exit_m_responder_return_1

do_key_equals:
inc   cx
do_key_minus:
cmp   byte ptr ds:[_automapactive], 0
jne   jump_to_exit_m_responder_return_0

xchg  ax, cx
call  M_SizeDisplay_

jmp   play_stnmov_sound_and_exit_m_responder_return_1
jump_to_exit_m_responder_return_0:
didnt_find_key_in_nonmenu:
jmp   exit_m_responder_return_0

do_key_f1:
call  M_StartControlPanel_
cmp   byte ptr ds:[_is_ultimate], cl
mov   ax, OFFSET _ReadDef1
je    use_readdef1
mov   ax, OFFSET _ReadDef2
use_readdef1:
mov   word ptr ds:[_currentMenu], ax
mov   word ptr ds:[_itemOn], cx 
jmp   play_switch_sound_and_exit_m_responder_return_1


do_key_f2:
call  M_StartControlPanel_
xchg  ax, cx ; 0
call  M_SaveGame_
jmp   play_switch_sound_and_exit_m_responder_return_1

do_key_f3:
call  M_StartControlPanel_
xchg  ax, cx ; 0
call  M_LoadGame_
jmp   play_switch_sound_and_exit_m_responder_return_1

do_key_f4:
call  M_StartControlPanel_
mov   word ptr ds:[_currentMenu], OFFSET _SoundDef
mov   word ptr ds:[_itemOn], cx ; 0 , sound_e_sfx_vol
jmp   play_switch_sound_and_exit_m_responder_return_1

do_key_f5:
xchg  ax, cx ; 0
call  M_ChangeDetail_
jmp   play_switch_sound_and_exit_m_responder_return_1

do_key_f6:
xchg  ax, cx ; 0
call  M_QuickSave_
jmp   play_switch_sound_and_exit_m_responder_return_1


do_key_f7:
xchg  ax, cx ; 0
call  M_EndGame_
jmp   play_switch_sound_and_exit_m_responder_return_1

do_key_f8:
xchg  ax, cx ; 0
call  M_ChangeMessages_
jmp   play_switch_sound_and_exit_m_responder_return_1

do_key_f9:
xchg  ax, cx ; 0
call  M_QuickLoad_
jmp   play_switch_sound_and_exit_m_responder_return_1

do_key_f10:
xchg  ax, cx ; 0
call  M_QuitDOOM_
play_switch_sound_and_exit_m_responder_return_1:
mov   dx, SFX_SWTCHN
play_sound_and_exit_m_responder_return_1:
xor   ax, ax
call  S_StartSound_

mov   al, 1

pop   di
pop   si
pop   cx
pop   bx
retf  
menu_is_active:

mov   dx, word ptr ds:[_itemOn]
xchg  ax, si
mov   al, SIZEOF_MENUITEM_T
mul   dl
xchg  ax, si
mov   bx, word ptr ds:[_currentMenu]
mov   di, word ptr ds:[bx + MENU_T.menu_menuitems]
add   si, di

; al is key
; bx is currentMenu
; dx is itemOn
; cx is 0
; si is currentMenu->menuItems[itemOn]
; di is currentMenu->menuItems

; KEY_DOWNARROW  AF
; KEY_UPARROW    AD
; KEY_LEFTARROW  AC
; KEY_RIGHTARROW AE
; KEY_ENTER      13
; KEY_ESCAPE     27
; KEY_BACKSPACE  127
; default..

cmp   al, KEY_ENTER
je    do_menu_key_enter
cmp   al, KEY_ESCAPE
je    do_menu_key_escape
cmp   al, KEY_BACKSPACE
je    do_menu_key_backspace

cmp   al, KEY_DOWNARROW
ja    handle_default
je    do_menu_key_downarrow
cmp   al, KEY_LEFTARROW
je    do_menu_key_leftarrow
jb    handle_default
cmp   al, KEY_RIGHTARROW
je    do_menu_key_rightarrow
do_menu_key_uparrow:

loop_next_up:
cmp   dx, cx
jne   just_dec_itemon
mov   dl, byte ptr ds:[bx + MENU_T.menu_numitems]
just_dec_itemon:
dec   dx
mov   al, SIZEOF_MENUITEM_T
mul   dl
xchg  ax, si
add   si, di
cmp   byte ptr ds:[si + MENUITEM_T.menuitem_status], -1
je    loop_next_up
finish_key_upordown:
mov   word ptr ds:[_itemOn], dx
mov   dx, SFX_PSTOP
jmp   play_sound_and_exit_m_responder_return_1
do_menu_key_enter:
cmp   word ptr ds:[si + MENUITEM_T.menuitem_routine], cx
je    exit_m_responder_return_1_3
cmp   byte ptr ds:[si + MENUITEM_T.menuitem_status], cl
je    exit_m_responder_return_1_3
jmp   handle_rest_of_enter_case


do_menu_key_backspace:

mov   word ptr ds:[bx + MENU_T.menu_laston], dx
mov   ax, word ptr ds:[bx + MENU_T.menu_prevMenu]
cmp   ax, cx
je    exit_m_responder_return_1_3
mov   word ptr ds:[_currentMenu], ax
xchg  ax, bx
push  word ptr ds:[bx + MENU_T.menu_laston]
pop   word ptr ds:[_itemOn]
jmp   play_switch_sound_and_exit_m_responder_return_1
handle_default:
jmp   do_menu_key_default
do_menu_key_escape:
mov   word ptr ds:[bx + MENU_T.menu_laston], dx
mov   byte ptr ds:[_menuactive], cl ; 0
mov   byte ptr ds:[_inhelpscreens], cl ; 0
cmp   byte ptr ds:[_screenblocks], 9
jle   force_hud_update
jmp   just_play_sound
do_menu_key_downarrow:
loop_next_down:
inc   dx
add   si, SIZEOF_MENUITEM_T
cmp   dl, byte ptr ds:[bx + MENU_T.menu_numitems]
jne   dont_reset_itemon
mov   dx, cx
mov   si, di
dont_reset_itemon:

cmp   byte ptr ds:[si + MENUITEM_T.menuitem_status], -1
je    loop_next_down
jmp   finish_key_upordown
do_menu_key_rightarrow:
inc   cx
do_menu_key_leftarrow:
; cx already 0 in left arrow case
cmp   word ptr ds:[si + MENUITEM_T.menuitem_routine], 0
je    exit_m_responder_return_1_3
cmp   byte ptr ds:[si + MENUITEM_T.menuitem_status], 2
jne   exit_m_responder_return_1_3
mov   bl, byte ptr ds:[_currenttask]
call  Z_QuickMapMenu_  ; todo remove
xchg  ax, cx
call  word ptr ds:[si + MENUITEM_T.menuitem_routine]
xchg  ax, bx
cbw
call  Z_QuickMapByTaskNum_

play_stnmov_sound_and_exit_m_responder_return_1:
mov   dx, SFX_STNMOV
xor   ax, ax
call  S_StartSound_
exit_m_responder_return_1_3:
mov   al, 1
pop   di
pop   si
pop   cx
pop   bx
retf  
do_menu_key_default:

mov   cl, byte ptr ds:[bx + MENU_T.menu_numitems]
lea   bx, [si + SIZEOF_MENUITEM_T]
mov   si, dx
inc   si

check_next_alphakey:

cmp   al, byte ptr ds:[bx + MENUITEM_T.menuitem_alphakey]
je    found_key_stop
add   bx, SIZEOF_MENUITEM_T
cmp   si, cx
jl    check_next_alphakey

xor   si, si

check_next_alphakey_2:
cmp   al, byte ptr ds:[di + MENUITEM_T.menuitem_alphakey]
je    found_key_stop
inc   si
cmp   si, dx
jl    check_next_alphakey_2

exit_m_responder_return_0:
xor   ax, ax
pop   di
pop   si
pop   cx
pop   bx
retf  

force_hud_update:
mov   byte ptr ds:[_borderdrawcount], 3
cmp   byte ptr ds:[_hudneedsupdate], cl
je    just_play_sound
mov   byte ptr ds:[_hudneedsupdate], 6

just_play_sound:
mov   dx, SFX_SWTCHX
jmp   play_sound_and_exit_m_responder_return_1
handle_rest_of_enter_case:
mov   word ptr ds:[bx + MENU_T.menu_laston], dx
mov   bl, byte ptr ds:[_currenttask]
call  Z_QuickMapMenu_  ; todo remove

cmp   byte ptr ds:[si + MENUITEM_T.menuitem_status], 2
jne   status_not_2
mov   ax, 1
mov   dx, SFX_STNMOV
jmp   do_enter_call
status_not_2:
xchg  ax, dx
mov   dx, SFX_PISTOL
do_enter_call:
call  word ptr ds:[si + MENUITEM_T.menuitem_routine]
xchg  ax, bx
cbw
call  Z_QuickMapByTaskNum_
jmp   play_sound_and_exit_m_responder_return_1
do_key_f11:
mov   al, byte ptr ds:[_usegamma]
inc   ax
cmp   al, 4
jbe   dont_cap_gamma
mov   ax, cx ; 0
dont_cap_gamma:
mov   byte ptr ds:[_usegamma], al
add   al, GAMMALVL0
cbw
mov   word ptr ds:[_player + PLAYER_T.player_message], ax
xchg  ax, cx ; 0
call  I_SetPalette_
jmp   exit_m_responder_return_1

found_key_stop:
mov   word ptr ds:[_itemOn], si
mov   dx, SFX_PSTOP
jmp   play_sound_and_exit_m_responder_return_1

ENDP


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


SKULLXOFF = 32



PROC    M_Drawer_ FAR
PUBLIC  M_Drawer_

PUSHA_NO_AX_OR_BP_MACRO
push  bp
mov   bp, sp
sub   sp, 02Ch
push  ax       ; isfromwipe - 2Eh
xor   ax, ax
mov   byte ptr ds:[_inhelpscreens], al  ; 0
cmp   byte ptr ds:[_messageToPrint], al ; 0
je    no_message_to_print
xchg  ax, cx ; cx gets 0
call  Z_QuickMapStatus_
mov   ax, OFFSET _menu_messageString
mov   dx, cs
call  M_StringHeight_

mov   dx, 100
sar   ax, 1
sub   dx, ax
mov   word ptr [bp - 2], dx
cmp   byte ptr cs:[_menu_messageString], cl ; 0
je    jump_to_do_exit_check


;        while(*(menu_messageString+start)) {
;            for (i = 0; i < locallib_strlen(menu_messageString + start); i++) {
;                if (*(menu_messageString + start + i) == '\n') {
;                    locallib_strncpy(string, menu_messageString + start, i);       ; this becomes repne scasb
;                    string[i] = '\0';
;                    start += i + 1;
;                    break;
;                }
;            }
;
;            if (i == locallib_strlen(menu_messageString+start)) {
;                locallib_strcpy(string,menu_messageString+start);
;                start += i;
;            }
;                                
;            menu_drawer_x = 160 - (M_StringWidth(string)>>1);
;            M_WriteText(menu_drawer_x,menu_drawer_y,string);
;
;            menu_drawer_y += HU_FONT_SIZE;
;        }

; bx is start
mov   si, OFFSET _menu_messageString

loop_next_menu_string_line:
mov   ax, si
mov   dx, cs
call  M_Strlen_

push  ds
pop   es
push  cs
pop   ds

; find newline

xchg  ax, cx


mov   ah, 0Ah; newline
lea   di, [bp - 02Ch]
mov   bx, di
copy_next_message_char:
lodsb
cmp   al, ah
je    handle_newline
stosb
loop  copy_next_message_char

handle_newline:
xor   ax, ax
stosb

push  ss
pop   ds


mov   ax, bx ;  bp - 02Ch
mov   dx, ds
call  M_StringWidth_

mov   dx, 160
sar   ax, 1
sub   dx, ax
xchg  ax, dx

mov   dx, word ptr [bp - 2]
add   word ptr [bp - 2], HU_FONT_SIZE

mov   cx, ds


call  M_WriteText_


cmp   byte ptr cs:[si], 0
jne   loop_next_menu_string_line

jump_to_do_exit_check:
jmp   do_exit_check





no_message_to_print:
mov   bx, word ptr ds:[_currentMenu]
cmp   byte ptr ds:[_menuactive], al ; 0
je    do_m_drawer_exit

call  Z_QuickMapMenu_
cmp   word ptr ds:[bx + MENU_T.menu_routine], 0
je    no_menu_routine
call  word ptr ds:[bx + MENU_T.menu_routine]
no_menu_routine:

mov   di, word ptr ds:[bx + MENU_T.menu_x]
mov   al, byte ptr ds:[bx + MENU_T.menu_y]
cbw
xchg  ax, si
mov   al, byte ptr ds:[bx + MENU_T.menu_numitems]
mov   ah, SIZEOF_MENUITEM_T
mul   ah
mov   bx, word ptr ds:[bx + MENU_T.menu_menuitems]
add   ax, bx
mov   word ptr cs:[SELFMODIFY_lastmenuitem+2], ax
inc   bx ; + MENUITEM_T.menuitem_name

loop_next_menu_patch:
mov   al, byte ptr ds:[bx]
test  al, al
js    dont_draw_this_item
call  M_GetMenuPatch_
push  bx
xchg  ax, bx
mov   cx, dx
mov   ax, di
mov   dx, si
call  V_DrawPatchDirect_
pop   bx

dont_draw_this_item:
add   bx, SIZEOF_MENUITEM_T
add   si, LINEHEIGHT
SELFMODIFY_lastmenuitem:
cmp   bx, 01000h
jl    loop_next_menu_patch

done_with_menuitems:

mov   bx, word ptr ds:[_whichSkull]
mov   al, byte ptr ds:[bx + _skullName]
call  M_GetMenuPatch_
xchg  ax, bx
mov   cx, dx

mov   si, word ptr ds:[_currentMenu]
xor   dx, dx
mov   dl, byte ptr ds:[si + MENU_T.menu_y]

mov   al, LINEHEIGHT
mul   byte ptr ds:[_itemOn] 
add   dx, ax
sub   dx, 5
lea   ax, [di - SKULLXOFF]
call  V_DrawPatchDirect_
do_exit_check:
cmp   byte ptr [bp - 2Eh], 0   ; isFromWipe
jne   do_quickmap_wipe_exit
do_quickmap_physics_exit:
call  Z_QuickMapPhysics_
do_m_drawer_exit:
LEAVE_MACRO 
POPA_NO_AX_OR_BP_MACRO
retf  
do_quickmap_wipe_exit:
call  Z_QuickMapWipe_
jmp   do_m_drawer_exit



ENDP



COMMENT @

; NO LONGER USED! always inlined.
PROC    M_SetupNextMenu_ NEAR
PUBLIC  M_SetupNextMenu_

push  bx
mov   bx, ax
mov   bx, word ptr ds:[bx + MENU_T.menu_laston]
mov   word ptr ds:[_currentMenu], ax
mov   word ptr ds:[_itemOn], bx
pop   bx
ret   
@



ENDP

; todo inline this wherever its used..
PROC    M_Ticker_    NEAR
PUBLIC  M_Ticker_


dec   word ptr ds:[_skullAnimCounter]
jnle   exit_m_ticker
xor   byte ptr ds:[_whichSkull], 1
mov   word ptr ds:[_skullAnimCounter], 8
exit_m_ticker:
ret   



ENDP

PROC    M_MENU_ENDMARKER_ NEAR
PUBLIC  M_MENU_ENDMARKER_
ENDP


END
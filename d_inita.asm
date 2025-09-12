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


EXTRN fread_:FAR
EXTRN fseek_:FAR
EXTRN fopen_:FAR
EXTRN fclose_:FAR


EXTRN Z_QuickMapMenu_:FAR
EXTRN Z_QuickMapPhysics_:FAR
EXTRN getStringByIndex_:FAR
EXTRN D_InitStrings_:NEAR
EXTRN Z_LoadBinaries_:NEAR
EXTRN M_LoadDefaults_:NEAR
EXTRN M_ScanTranslateDefaults_:NEAR
EXTRN Z_GetEMSPageMap_:NEAR
EXTRN P_Init_:NEAR
EXTRN I_Init_:NEAR
EXTRN R_Init_:NEAR
EXTRN HU_Init_:NEAR
EXTRN ST_Init_:NEAR
EXTRN S_Init_:NEAR
EXTRN AM_loadPics_:NEAR
EXTRN G_RecordDemo_:NEAR
EXTRN G_TimeDemo_:NEAR
EXTRN G_InitNew_:NEAR
EXTRN G_DeferedPlayDemo_:NEAR
EXTRN DEBUG_PRINT_NOARG_CS_:NEAR
EXTRN DEBUG_PRINT_NOARG_:NEAR
EXTRN M_CheckParm_:NEAR


.DATA

EXTRN _M_Init:DWORD
EXTRN _M_LoadFromSaveGame:DWORD
EXTRN _myargc:WORD
EXTRN _myargv:WORD
EXTRN _autostart:BYTE
EXTRN _singledemo:BYTE
EXTRN _startskill:BYTE
EXTRN _startepisode:BYTE
EXTRN _startmap:BYTE

.CODE

KEYBOARDINT = 9

str_getemspagemap:
db 0Ah, "Z_GetEMSPageMap: Init EMS 4.0 features.", 0
str_loaddefaults:
db 0Ah, "M_LoadDefaults	: Load system defaults.", 0
str_z_loadbinaries:
db 0Ah, "Z_LoadBinaries: Load game code into memory", 0
str_initstrings:
db 0Ah, "D_InitStrings: loading text.", 0
str_record_param:
db "-record", 0
str_playdemo_param:
db "-playdemo", 0
str_timedemo_param:
db "-timedemo", 0
str_loadgame_param:
db "-loadgame", 0

PROC    D_INIT_STARTMARKER_ NEAR
PUBLIC  D_INIT_STARTMARKER_
ENDP


PROC    DoPrintChain_ NEAR

mov   bx, sp
inc   bx
inc   bx
push  bx  ; sp + 2
mov   cx, ss
call  getStringByIndex_
pop   ax  ; sp + 2
mov   dx, ss
call  DEBUG_PRINT_NOARG_
;call  D_RedrawTitle_

ret
ENDP

PROC    D_DoomMain3_ NEAR
PUBLIC  D_DoomMain3_

PUSHA_NO_AX_MACRO
push    bp
mov     bp, sp
sub     sp, 280


mov     ax, OFFSET str_getemspagemap
call    DEBUG_PRINT_NOARG_CS_
call    Z_GetEMSPageMap_

mov     ax, OFFSET str_loaddefaults
call    DEBUG_PRINT_NOARG_CS_
call    M_LoadDefaults_

mov     ax, OFFSET str_z_loadbinaries
call    DEBUG_PRINT_NOARG_CS_
call    Z_LoadBinaries_

call    M_ScanTranslateDefaults_

mov     ax, OFFSET str_initstrings
call    DEBUG_PRINT_NOARG_CS_
call    D_InitStrings_

cmp     byte ptr ds:[_registered], 0
je      skip_registered

  mov   ax, VERSION_REGISTERED
  call  DoPrintChain_

  mov   ax, NOT_SHAREWARE
  call  DoPrintChain_

skip_registered:

cmp     byte ptr ds:[_shareware], 0
je      skip_shareware

  mov   ax, VERSION_SHAREWARE
  call  DoPrintChain_


skip_shareware:

cmp     byte ptr ds:[_commercial], 0
je      skip_commercial

  mov   ax, VERSION_COMMERCIAL
  call  DoPrintChain_

  mov   ax, DO_NOT_DISTRIBUTE
  call  DoPrintChain_

skip_commercial:

mov   ax, M_INIT_TEXT_STR
call  DoPrintChain_



call  Z_QuickMapMenu_
call  dword ptr ds:[_M_Init]
call  Z_QuickMapPhysics_


mov   ax, R_INIT_TEXT_STR
call  DoPrintChain_
call  R_Init_

mov   ax, P_INIT_TEXT_STR
call  DoPrintChain_
call  P_Init_

mov   ax, I_INIT_TEXT_STR
call  DoPrintChain_
call  I_Init_

mov   word ptr ds:[_maketic+0], 0
mov   word ptr ds:[_maketic+2], 0


mov   ax, S_INIT_STRING_TEXT
call  DoPrintChain_
call  S_Init_

mov   ax, HU_INIT_TEXT_STR
call  DoPrintChain_
call  HU_Init_

mov   ax, ST_INIT_TEXT_STR
call  DoPrintChain_
call  ST_Init_

call  AM_loadPics_

mov   dx, word ptr ds:[_myargc]
dec   dx                        ; myargc - 1
mov   cx, 1
mov   bx, word ptr ds:[_myargv]
inc   bx
inc   bx                        ; myargv[n + 1]

mov   ax, OFFSET str_record_param
call  M_CheckParm_


test  ax, ax
je    skip_record_param
cmp   ax, dx
jnl   skip_record_param


    sal   ax, 1
    xchg  ax, si
    mov   ax, word ptr ds:[bx + si]
    call  G_RecordDemo_
    mov   byte ptr ds:[_autostart], cl  ; 1

skip_record_param:


mov   ax, OFFSET str_playdemo_param
call  M_CheckParm_


test  ax, ax
je    skip_playdemo_param
cmp   ax, dx
jnl   skip_playdemo_param

    mov   byte ptr ds:[_singledemo], cl  ; 1
    sal   ax, 1
    xchg  ax, si
    mov   ax, word ptr ds:[bx + si]
    call  G_DeferedPlayDemo_
    jmp   exit_doommain


skip_playdemo_param:


mov   ax, OFFSET str_timedemo_param
call  M_CheckParm_


test  ax, ax
je    skip_timedemo_param
cmp   ax, dx
jnl   skip_timedemo_param


    sal   ax, 1
    xchg  ax, si
    mov   ax, word ptr ds:[bx + si]
    call  G_TimeDemo_
    jmp   exit_doommain

skip_timedemo_param:

mov   ax, OFFSET str_loadgame_param
call  M_CheckParm_


test  ax, ax
je    skip_loadgame_param
cmp   ax, dx
jnl   skip_loadgame_param

    call  Z_QuickMapMenu_
    sal   ax, 1
    xchg  ax, si
    mov   ax, word ptr ds:[bx + si]
    call  dword ptr ds:[_M_LoadFromSaveGame]
    call  Z_QuickMapPhysics_

skip_loadgame_param:

cmp  byte ptr ds:[_gameaction], GA_LOADGAME
je   skip_loadgame
cmp  byte ptr ds:[_autostart], 0
je   not_autostart
autostart:
xor  ax, ax
cwd
mov  bx, ax
mov  al, byte ptr ds:[_startskill]
mov  dl, byte ptr ds:[_startepisode]
mov  bl, byte ptr ds:[_startmap]
call G_InitNew_
jmp  exit_doommain
not_autostart:

; inline D_StartTitle_

skip_loadgame:

xor   ax, ax
mov   byte ptr ds:[_gameaction], al ; GA_NOTHING
dec   ax  ; - 1
mov   byte ptr ds:[_demosequence], al
neg   ax  ; 1
mov   byte ptr ds:[_advancedemo], al


exit_doommain:

LEAVE_MACRO
POPA_NO_AX_MACRO

ret

ENDP

PROC    D_INIT_ENDMARKER_ NEAR
PUBLIC  D_INIT_ENDMARKER_
ENDP


END
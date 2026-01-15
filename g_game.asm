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
INCLUDE strings.inc
INSTRUCTION_SET_MACRO


EXTRN M_WriteFile_:NEAR
EXTRN M_ReadFile_:NEAR

EXTRN Z_QuickMapPhysics_:NEAR
EXTRN Z_QuickMapScratch_5000_:NEAR
EXTRN Z_QuickMapIntermission_:NEAR

EXTRN R_ExecuteSetViewSize_:NEAR
EXTRN R_FillBackScreen_ForceBufferRedraw_:NEAR
EXTRN W_CheckNumForNameFarString_:NEAR
EXTRN locallib_strcmp_:NEAR
EXTRN Z_QuickMapDemo_:NEAR
EXTRN W_GetNumForNameFarString_:NEAR
EXTRN W_ReadLump_:NEAR
EXTRN G_DoLoadLevel_:NEAR
EXTRN G_InitNew_:NEAR
EXTRN I_Error_:FAR



EXTRN Z_SetOverlay_:FAR

EXTRN G_ReadDemoTiccmd_:NEAR
EXTRN G_WriteDemoTiccmd_:NEAR
EXTRN S_ResumeSound_:NEAR




.DATA


.CODE

EXTRN _localcmds



PROC    G_GAME_STARTMARKER_ NEAR
PUBLIC  G_GAME_STARTMARKER_
ENDP




ENDP




VERSIONSIZE = 16


PROC    R_FlatNumForName_FAR_ FAR
PUBLIC  R_FlatNumForName_FAR_
call    R_FlatNumForName_
retf
ENDP

PROC    R_FlatNumForName_ NEAR
PUBLIC  R_FlatNumForName_

push    dx
push    ax

call    W_CheckNumForNameFarString_

test    ax, ax
js      do_flat_error

sub     ax, word ptr ds:[_firstflat]

add     sp, 4
ret
ENDP

str_error_flatnum:
db "\nR_FlatNumForName: %Fs not found", 0

do_flat_error:

; dx/ax already on stack?
push     cs
mov      ax, OFFSET str_error_flatnum
push     ax
call     I_Error_

g_ticker_gameaction_table:
dw OFFSET case_nothing
dw OFFSET case_loadlevel
dw OFFSET case_newgame
dw OFFSET case_loadgame
dw OFFSET case_savegame
dw OFFSET case_playdemo
dw OFFSET case_completed
dw OFFSET case_victory
dw OFFSET case_worlddone




case_playdemo:
;call    G_DoPlayDemo_   ; inlined

; OUTER SCOPE PUSHES AND POPS

call   Z_QuickMapDemo_
xor    bx, bx
mov    byte ptr ds:[_gameaction], bl ; 0 GA_NOTHING

les    ax, dword ptr ds:[_defdemoname]
mov    dx, es
mov    cx, DEMO_SEGMENT
mov    si, cx
; TODO_BUG ftell, detect longer than MAX_DEMO_SIZE?
;call   W_CacheLumpNameDirectFarString_ ; (defdemoname, demobuffer);
; inlined W_CacheLumpNameDirectFarString_
call   W_GetNumForNameFarString_
call   W_ReadLump_


mov    ds, si
xor    si, si
; ds:si is demo_addr
lodsb
cmp    al, VERSION
jne    do_version_error
do_version_error:  ; TODO_IMPROVEMENT implement bad version check?

lodsw
xchg   ax, dx   ; dl = skill, dh = episode
lodsw
xchg   ax, bx   ; bl = map,   bh = deathmatch
lodsw
xchg   ax, cx   ; cl = respawn, ch = fastparm
lodsb


push   ss
pop    ds
mov    byte ptr ds:[_respawnparm], cl
mov    byte ptr ds:[_fastparm], ch
mov    byte ptr ds:[_nomonsters], al
lea    ax, [si+ 5]
mov    word ptr ds:[_demo_p], ax ; probably a constant actually

xchg   ax, dx ; al = skill, ah = episode
mov    dl, ah ; dl = episode
mov    byte ptr ds:[_precache], 0  ; false
call   G_InitNew_

mov    ax, 1
mov    byte ptr ds:[_precache], al      ; true
mov    byte ptr ds:[_usergame], ah      ; false
mov    byte ptr ds:[_demoplayback], al  ; true


call   Z_QuickMapPhysics_

; OUTER SCOPE PUSHES AND POPS

jmp     continue_while_loop

ENDP




case_loadgame:

;call    G_DoLoadGame_ ; inlined



; todo move this code into savegame stuff once its good to go. 

call    Z_QuickMapScratch_5000_

mov     di, SCRATCH_SEGMENT_5000
mov     cx, di
xor     bx, bx
mov     ax, OFFSET _savename
call    M_ReadFile_

mov     al, OVERLAY_ID_SAVELOADGAME
call    Z_SetOverlay_

mov     si, SAVESTRINGSIZE

; es:di = save_p/savebuffer
mov     ax, 0 ; OFFSET str_versionstring
mov     dx, CODE_OVERLAY_SEGMENT
mov     bx, si
mov     cx, di
call    locallib_strcmp_
test    al, al
jne     error_bad_version
add     si, VERSIONSIZE
mov     es, di

lods    byte ptr es:[si]
mov     byte ptr ds:[_gameskill], al
xchg    ax, dx
lods    word ptr es:[si]
mov     word ptr ds:[_gameepisode], ax ; two at once
mov     bl, ah
xchg    ax, dx
add     si, 4

call    G_InitNew_
; g_initnew_ may destroy a lot of these memory ranges...
call    Z_QuickMapPhysics_
call    Z_QuickMapScratch_5000_

mov     cx, di
xor     bx, bx
mov     ax, OFFSET _savename
call    M_ReadFile_

mov     al, OVERLAY_ID_SAVELOADGAME
call    Z_SetOverlay_

; here call into save code overlay to handle the rest.
db      09Ah
dw      G_CONTINUELOADGAMEOFFSET, CODE_OVERLAY_SEGMENT
 


error_bad_version:
call    Z_QuickMapPhysics_

cmp     byte ptr ds:[_setsizeneeded], 0
je      skip_setviewsize
call    R_ExecuteSetViewSize_
skip_setviewsize:

call    R_FillBackScreen_ForceBufferRedraw_




jmp     continue_while_loop


case_savegame:
mov     al, OVERLAY_ID_SAVELOADGAME
call    Z_SetOverlay_
;call    G_DoSaveGame_ ; inlined

call    Z_QuickMapScratch_5000_
mov     al, '0'
add     al, byte ptr ds:[_savegameslot];
mov     byte ptr ds:[_doomsav0_string + 7], al

db      09Ah
dw      G_CONTINUESAVEGAMEOFFSET, CODE_OVERLAY_SEGMENT

mov     ax, OFFSET _doomsav0_string
mov     cx, es
xor     bx, bx
mov     dx, word ptr ds:[_save_p]
call    M_WriteFile_
xor     ax, ax
mov     byte ptr ds:[_gameaction], al ; GA_NOTHING
mov     byte ptr ds:[_savedescription], al ; \0
mov     word ptr ds:[_player + PLAYER_T.player_message], GGSAVED
call    R_FillBackScreen_ForceBufferRedraw_   ; force screen draw for save message



jmp     continue_while_loop



PROC    G_Ticker_ NEAR
PUBLIC  G_Ticker_

PUSHA_NO_AX_OR_BP_MACRO

cmp     byte ptr ds:[_player + PLAYER_T.player_playerstate], PST_REBORN
jne     dont_reborn
mov     byte ptr ds:[_gameaction], GA_LOADLEVEL
dont_reborn:

continue_while_loop:
xor     ax, ax
xor     bx, bx
mov     bl, byte ptr ds:[_gameaction]
sal     bx, 1
jmp     word ptr cs:[g_ticker_gameaction_table + bx]

case_loadlevel:
call    G_DoLoadLevel_
jmp     continue_while_loop
case_newgame:
;call    G_DoNewGame_
; inlined. bx/dx are ok to ruin in this stack frame
xor    ax, ax
mov    byte ptr ds:[_demoplayback], al ; false
mov    byte ptr ds:[_respawnparm], al ; false
mov    byte ptr ds:[_fastparm], al ; false
mov    byte ptr ds:[_nomonsters], al ; false
mov    byte ptr ds:[_gameaction], al ; GA_NOTHING
mov    ax, word ptr ds:[_d_skill]
mov    dl, ah
; mov    dl, byte ptr ds:[_d_episode]
mov    bl, byte ptr ds:[_d_map]
call   G_InitNew_

jmp     continue_while_loop
case_completed:

call    Z_QuickMapIntermission_
db      09Ah
dw      G_DOCOMPLETED_OFFSET, WIANIM_CODESPACE_SEGMENT
call    Z_QuickMapPhysics_


jmp     continue_while_loop
case_victory:
mov     al, OVERLAY_ID_FINALE
call    Z_SetOverlay_
db      09Ah
dw      F_STARTFINALEOFFSET, CODE_OVERLAY_SEGMENT
jmp     continue_while_loop

case_worlddone:
;call    G_DoWorldDone_  ; inlined

mov    ax, 1
mov    byte ptr ds:[_gamestate], ah ; GS_LEVEL
mov    byte ptr ds:[_gameaction], ah ; GA_NOTHING
mov    byte ptr ds:[_viewactive], al ; true
add    al, byte ptr ds:[_wminfo + WBSTARTSTRUCT_T.wbss_next] ; one plus...
mov    byte ptr ds:[_gamemap], al ; true

call   G_DoLoadLevel_

jmp     continue_while_loop


case_nothing:
xor     bx, bx
mov     al, byte ptr ds:[_gametic]
and     ax, (BACKUPTICS-1)
xchg    ax, dx


;call    G_CopyCmd_
; inlined only use...

    
    push    ds              ; es:di is player.cmd
    pop     es
    mov     di, OFFSET [_player + PLAYER_T.player_cmd]

    push    cs              ; ds:si is _localcmds struct
    pop     ds

    xor     dh, dh
    mov     si, dx
    SHIFT_MACRO sal si 3 ; 8 bytes per
    add     si, OFFSET _localcmds

    movsw
    movsw
    movsw
    movsw   ; copy one cmd
    
    push    ss
    pop     ds
    

; todo improve defaults. compare both bytes to zero at once and branch out 

cmp     byte ptr ds:[_demoplayback], bl ; 0
je      dont_do_demo_play
mov     ax, OFFSET [_player + PLAYER_T.player_cmd]
call    G_ReadDemoTiccmd_
dont_do_demo_play:
cmp     byte ptr ds:[_demorecording], bl ; 0
je      dont_do_demo_write
mov     bx, OFFSET [_player + PLAYER_T.player_cmd]
mov     ax, word ptr ds:[_player + PLAYER_T.player_cmd + TICCMD_T.ticcmd_angleturn]
add     ax, 128
;mov     ah, al
xor     al, al
mov     word ptr ds:[_player + PLAYER_T.player_cmd + TICCMD_T.ticcmd_angleturn], ax
xchg    ax, bx
call    G_WriteDemoTiccmd_
dont_do_demo_write:
mov     al, byte ptr ds:[_player + PLAYER_T.player_cmd_buttons]
test    al, BT_SPECIAL
je      skip_special_button   ; todo make this reverse logic case?
mov     ah, al
and     al, BT_SPECIALMASK
cmp     al, BTS_PAUSE
je      not_pause
xor     byte ptr ds:[_paused], 1
jne     do_pause
call    S_ResumeSound_
jmp     done_with_special_buttons
do_pause:
;call    S_PauseSound_ ; inlined

xor   ax, ax
cmp   byte ptr ds:[_mus_playing], al ; 0
je    done_with_special_buttons
cmp   byte ptr ds:[_mus_paused], al  ; todo put these adjacent. use a single word check
jne   done_with_special_buttons

mov   byte ptr ds:[_playingstate], ST_PAUSED
cmp   byte ptr ds:[_playingdriver+3], al  ; segment high byte shouldnt be 0 if its set.
je    done_with_special_buttons
les   bx, dword ptr ds:[_playingdriver]
call  es:[bx + MUSIC_DRIVER_T.md_pausemusic_func]
mov   byte ptr ds:[_mus_paused], 1
exit_pause_sound:

jmp     done_with_special_buttons
not_pause:
cmp     al, BTS_SAVEGAME
jne     not_savegame
mov     al, ah
and     al, BTS_SAVEMASK
SHIFT_MACRO shr al BTS_SAVESHIFT
mov     byte ptr ds:[_savegameslot], al
mov     byte ptr ds:[_gameaction], GA_SAVEGAME

not_savegame:
done_with_special_buttons:
skip_special_button:

mov     al, byte ptr ds:[_gamestate]
cmp     al, GS_FINALE ; 2 
je      do_finale
ja      do_demoscreen
jpe     do_intermission
do_level:
db      09Ah
dw      P_TICKEROFFSET, PHYSICS_HIGHCODE_SEGMENT

call    Z_QuickmapPhysics_
db      09Ah
dw      ST_TICKER_OFFSET, PHYSICS_HIGHCODE_SEGMENT

cmp     byte ptr ds:[_automapactive], 0
je      skip_automap
db      09Ah
dw      AM_TICKEROFFSET, PHYSICS_HIGHCODE_SEGMENT


skip_automap:
db      09Ah
dw      HU_TICKER_OFFSET, PHYSICS_HIGHCODE_SEGMENT

jmp     exit_g_ticker

do_intermission:
call    Z_QuickMapIntermission_
db      09Ah
dw      WI_TICKEROFFSET, WIANIM_CODESPACE_SEGMENT

call    Z_QuickMapPhysics_

jmp     exit_g_ticker
do_finale:
mov     ax, OVERLAY_ID_FINALE
call    Z_SetOverlay_
db      09Ah
dw      F_TICKEROFFSET, CODE_OVERLAY_SEGMENT


jmp     exit_g_ticker

do_demoscreen:
dec     word ptr ds:[_pagetic]
jnz     exit_g_ticker
mov     byte ptr ds:[_advancedemo], 1
exit_g_ticker:
POPA_NO_AX_OR_BP_MACRO
ret
ENDP





PROC    G_GAME_ENDMARKER_ NEAR
PUBLIC  G_GAME_ENDMARKER_
ENDP


END
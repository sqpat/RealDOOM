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

EXTRN Z_QuickMapPhysics_:FAR
EXTRN Z_QuickMapScratch_5000_:FAR
EXTRN Z_QuickMapIntermission_:FAR

EXTRN R_ExecuteSetViewSize_:NEAR
EXTRN R_FillBackScreen_ForceBufferRedraw_:NEAR
EXTRN W_CheckNumForNameFarString_:NEAR
EXTRN locallib_strcmp_:NEAR

EXTRN G_DoLoadLevel_:NEAR
EXTRN G_InitNew_:NEAR
EXTRN I_Error_:FAR


EXTRN ST_Ticker_:NEAR
EXTRN Z_SetOverlay_:FAR
EXTRN G_DoPlayDemo_:NEAR
EXTRN G_ReadDemoTiccmd_:NEAR
EXTRN G_WriteDemoTiccmd_:NEAR
EXTRN S_ResumeSound_:NEAR
EXTRN S_PauseSound_:NEAR
EXTRN G_CopyCmd_:NEAR

EXTRN FastDiv32u16u_:FAR


.DATA


.CODE

EXTRN _localcmds:WORD



PROC    G_GAME_STARTMARKER_ NEAR
PUBLIC  G_GAME_STARTMARKER_
ENDP



PROC    G_PlayerFinishLevel_ NEAR
PUBLIC  G_PlayerFinishLevel_

push    di
push    cx

xor     ax, ax
mov     word ptr ds:[_player + PLAYER_T.player_extralightvalue], ax ; 0        cancel invisibility 
;mov     byte ptr ds:[_player + PLAYER_T.player_fixedcolormapvalue], al ; 0    cancel ir gogles 
mov     word ptr ds:[_player + PLAYER_T.player_damagecount], ax ; 0            no palette changes 
mov     byte ptr ds:[_player + PLAYER_T.player_bonuscount], al ; 0            
les     di, dword ptr ds:[_playerMobj_pos]
and     byte ptr es:[di + MOBJ_POS_T.mp_flags2], (NOT MF_SHADOW)
mov     cx, (2 * NUMPOWERS + 1 * NUMCARDS) / 2  ; 18 or 012h / 2 = 9
mov     di, OFFSET _player + PLAYER_T.player_powers
push    ds
pop     es
rep     stosw
    ;memset (player.powers, 0, sizeof (player.powers));
    ;memset (player.cards, 0, sizeof (player.cards));

pop    cx
pop    di

ret
ENDP


PROC   G_DoNewGame_ NEAR
PUBLIC G_DoNewGame_

push   dx
push   bx
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
pop    bx
pop    dx

ret
ENDP



PROC   G_DoWorldDone_ NEAR
PUBLIC G_DoWorldDone_

mov    ax, 1
mov    byte ptr ds:[_gamestate], ah ; GS_LEVEL
mov    byte ptr ds:[_gameaction], ah ; GA_NOTHING
mov    byte ptr ds:[_viewactive], al ; true
add    al, byte ptr ds:[_wminfo + WBSTARTSTRUCT_T.wbss_next] ; one plus...
mov    byte ptr ds:[_gamemap], al ; true

call   G_DoLoadLevel_

ret
ENDP



PROC    G_DoSaveGame_ NEAR
PUBLIC  G_DoSaveGame_

PUSHA_NO_AX_OR_BP_MACRO

; todo move this code into savegame stuff once its good to go. 

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


POPA_NO_AX_OR_BP_MACRO

ret
ENDP





VERSIONSIZE = 16

PROC    G_DoLoadGame_ NEAR
PUBLIC  G_DoLoadGame_

PUSHA_NO_AX_OR_BP_MACRO

; todo move this code into savegame stuff once its good to go. 

call    Z_QuickMapScratch_5000_

mov     di, SCRATCH_SEGMENT_5000
mov     cx, di
xor     bx, bx
mov     ax, OFFSET _savename
call    M_ReadFile_

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


POPA_NO_AX_OR_BP_MACRO

ret
ENDP

PROC    R_FlatNumForName_FAR_ FAR
PUBLIC  R_FlatNumForName_FAR_
call    R_FlatNumForName_
retf

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

PROC    G_Ticker_ NEAR
PUBLIC  G_Ticker_

push    bx
push    dx

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
call    G_DoNewGame_
jmp     continue_while_loop
case_loadgame:
mov     al, OVERLAY_ID_SAVELOADGAME
call    Z_SetOverlay_
call    G_DoLoadGame_
jmp     continue_while_loop
case_savegame:
mov     al, OVERLAY_ID_SAVELOADGAME
call    Z_SetOverlay_
call    G_DoSaveGame_
jmp     continue_while_loop
case_playdemo:
call    G_DoPlayDemo_
jmp     continue_while_loop
case_completed:
call    G_DoCompleted_
jmp     continue_while_loop
case_victory:
mov     al, OVERLAY_ID_FINALE
call    Z_SetOverlay_
db      09Ah
dw      F_STARTFINALEOFFSET, CODE_OVERLAY_SEGMENT
jmp     continue_while_loop

case_worlddone:
call    G_DoWorldDone_

jmp     continue_while_loop


case_nothing:
xor     bx, bx
mov     al, byte ptr ds:[_gametic]
and     ax, (BACKUPTICS-1)
xchg    ax, dx


;call    G_CopyCmd_
; inlined only use...

    push    si
    push    di
    
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
    
    pop     di
    pop     si

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
je      skip_special_button
mov     ah, al
and     al, BT_SPECIALMASK
cmp     al, BTS_PAUSE
jne     not_pause
xor     byte ptr ds:[_paused], 1
jne     do_pause
call    S_ResumeSound_
jmp     done_with_special_buttons
do_pause:
call    S_PauseSound_
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
call    ST_Ticker_
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
pop     dx
pop     bx
ret
ENDP


PROC    G_DoCompleted_ NEAR
PUBLIC  G_DoCompleted_

push    bx
push    dx

xor     ax, ax
mov     byte ptr ds:[_gameaction], al ; GA_NOTHING
call    G_PlayerFinishLevel_
mov     ax, 1
cmp     byte ptr ds:[_automapactive], ah ; 0
je      skip_am_stop
; AM_Stop() inlined
mov     byte ptr ds:[_am_stopped], al ; 1
mov     byte ptr ds:[_st_gamestate], al ; 1
skip_am_stop:
cmp     byte ptr ds:[_commercial], ah ; 0
jne     skip_non_commercial_stuff
cmp     byte ptr ds:[_gamemap], 8
ja      do_level_9
jne     skip_non_commercial_stuff
do_level_8:
mov     byte ptr ds:[_gameaction], GA_VICTORY
jmp     done_with_non_commercial_stuff
do_level_9:
mov     byte ptr ds:[_player + PLAYER_T.player_didsecret], al ; true
done_with_non_commercial_stuff:
skip_non_commercial_stuff:

mov     al, byte ptr ds:[_player + PLAYER_T.player_didsecret]
mov     byte ptr ds:[_wminfo + WBSTARTSTRUCT_T.wbss_didsecret], al
mov     ax, word ptr ds:[_gameepisode]
sub     ax, 00101h ; sub 1 from each
mov     byte ptr ds:[_wminfo + WBSTARTSTRUCT_T.wbss_epsd], al
mov     byte ptr ds:[_wminfo + WBSTARTSTRUCT_T.wbss_last], ah

xor     ax, ax
mov     al, byte ptr ds:[_gamemap]

cmp     byte ptr ds:[_commercial], ah
je      do_non_commercial_wminfo
cmp     byte ptr ds:[_secretexit], ah
je      not_commercial_secret
mov     ah, 30
cmp     al, 15
je      do_map_30
inc     ah
cmp     al, 31;    // wminfo.next is 0 biased, unlike gamemap
je      do_map_31
jmp     done_with_wbss_next_calc
not_commercial_secret:
mov     ah, 15
cmp     al, 31
jae      do_map_15
;cmp     al, 32;    // wminfo.next is 0 biased, unlike gamemap
;je      do_map_31
jmp    do_default_map

do_non_commercial_wminfo:
cmp     byte ptr ds:[_secretexit], ah
mov     ah, 8
jne     do_map_8   ; secret
cmp     al, 9  ; returning from secret level
jne     not_map_9
mov     al, byte ptr ds:[_gameepisode]
mov     ah, 3
cmp     al, 2
jb      do_map_3  ; episode 1
mov     ah, 5
je      do_map_5  ; episode 2
mov     ah, 6
jpo     do_map_6  ; episode 3
mov     ah, 2
jmp     do_map_2  ; episode 4
not_map_9:
do_default_map:
mov     ah, al  ; gamemap
do_map_2:
do_map_3:
do_map_5:
do_map_6:
do_map_8:
do_map_15:
do_map_30:
do_map_31:
mov     byte ptr ds:[_wminfo + WBSTARTSTRUCT_T.wbss_next], ah

done_with_wbss_next_calc:

les     ax, dword ptr ds:[_totalkills]
mov     word ptr ds:[_wminfo + WBSTARTSTRUCT_T.wbss_maxkills], ax
mov     word ptr ds:[_wminfo + WBSTARTSTRUCT_T.wbss_maxitems], es
mov     ax, word ptr ds:[_totalsecret]
mov     word ptr ds:[_wminfo + WBSTARTSTRUCT_T.wbss_maxsecret], ax
mov     byte ptr ds:[_wminfo + WBSTARTSTRUCT_T.wbss_plyr + WBPLAYERSTRUCT_T.wbos_in], 1 ; true
les     ax, dword ptr ds:[_player + PLAYER_T.player_killcount]
mov     word ptr ds:[_wminfo + WBSTARTSTRUCT_T.wbss_plyr + WBPLAYERSTRUCT_T.wbos_skills], ax
mov     word ptr ds:[_wminfo + WBSTARTSTRUCT_T.wbss_plyr + WBPLAYERSTRUCT_T.wbos_sitems], es
mov     ax, word ptr ds:[_player + PLAYER_T.player_secretcount]
mov     word ptr ds:[_wminfo + WBSTARTSTRUCT_T.wbss_plyr + WBPLAYERSTRUCT_T.wbos_ssecret], ax
les     ax, dword ptr ds:[_leveltime]
mov     dx, es
mov     bx, 35
call    FastDiv32u16u_
mov     word ptr ds:[_wminfo + WBSTARTSTRUCT_T.wbss_plyr + WBPLAYERSTRUCT_T.wbos_stime], ax
mov     ax, 1
mov     byte ptr ds:[_gamestate], al ; GS_INTERMISSION
mov     byte ptr ds:[_viewactive], ah ; false
mov     byte ptr ds:[_automapactive], ah ; false


;    WI_Start (&wminfo, secretexit); 
call    Z_QuickMapIntermission_

mov     ax, OFFSET _wminfo
mov     dl, byte ptr ds:[_secretexit]  ; todo get this from inside the func?

db      09Ah
dw      WI_STARTOFFSET, WIANIM_CODESPACE_SEGMENT

call    Z_QuickMapPhysics_

pop     dx
pop     bx

ret

ENDP



PROC    G_GAME_ENDMARKER_ NEAR
PUBLIC  G_GAME_ENDMARKER_
ENDP


END
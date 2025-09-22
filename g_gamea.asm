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
EXTRN Z_QuickMapScratch_5000_:FAR
EXTRN M_WriteFile_:NEAR
EXTRN R_FillBackScreen_ForceBufferRedraw_:NEAR

EXTRN G_DoLoadLevel_:NEAR
EXTRN G_InitNew_:NEAR
EXTRN I_Error_:FAR
.DATA

EXTRN _wminfo:WBSTARTSTRUCT_T

.CODE


PROC    G_GAME_STARTMARKER_ NEAR
PUBLIC  G_GAME_STARTMARKER_
ENDP

str_outofthinkers:
db "Out of thinkers!", 0

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
mov    al, byte ptr ds:[_wminfo + WBSTARTSTRUCT_T.wbss_next]
mov    byte ptr ds:[_gamemap], al ; true

call   G_DoLoadLevel_

ret
ENDP


PROC    OutOfThinkers_ FAR
PUBLIC  OutOfThinkers_

push    cs
mov     ax, OFFSET str_outofthinkers
push    ax
call    I_Error_
ENDP

SAVEGAMESIZE = 0F800h

str_versionstring:
db "version 109", 0


PROC    G_DoSaveGame_ NEAR
PUBLIC  G_DoSaveGame_

PUSHA_NO_AX_OR_BP_MACRO

; todo move this code into savegame stuff once its good to go. 

call    Z_QuickMapScratch_5000_
mov     al, '0'
add     al, byte ptr ds:[_savegameslot];
mov     byte ptr ds:[_doomsav0_string + 7], al
mov     di, SCRATCH_SEGMENT_5000
mov     es, di
xor     di, di
; es:di = save_p/savebuffer

mov     si, OFFSET _savedescription
mov     cx, SAVESTRINGSIZE / 2
rep     movsw
mov     si, OFFSET str_versionstring
push    cs
pop     ds
mov     cl, 12 / 2
rep     movsw
xor     ax, ax
stosw   ; // last 4 bytes of versionsize...
stosw
push    ss
pop     ds
mov     al, byte ptr ds:[_gameskill]
stosb
mov     ax, word ptr ds:[_gameepisode] ; get both...
;mov     ah, byte ptr ds:[_gamemap]
stosw
mov     ax, 1
stosw           ; true, false
dec     dx
stosw           ; false, false
mov     al, byte ptr ds:[_leveltime+2]
stosb
mov     ax, word ptr ds:[_leveltime+0]
xchg    al, ah
stosb
mov     al, ah
stosb

mov     word ptr ds:[_save_p], di
;mov     word ptr ds:[_save_p+2], es


db      09Ah
dw      P_ARCHIVEPLAYERSOFFSET, CODE_OVERLAY_SEGMENT
db      09Ah
dw      P_ARCHIVEWORLDOFFSET, CODE_OVERLAY_SEGMENT
db      09Ah
dw      P_ARCHIVETHINKERSOFFSET, CODE_OVERLAY_SEGMENT
db      09Ah
dw      P_ARCHIVESPECIALSOFFSET, CODE_OVERLAY_SEGMENT

les     di, dword ptr ds:[_save_p]
mov     cx, es

mov     al, 01Dh
stosb   ; consistency marker.
cmp     di, SAVEGAMESIZE
ja      savegame_too_big

mov     ax, OFFSET _doomsav0_string
; cx already 5000
xor     bx, bx
mov     dx, di
call    M_WriteFile_
xor     ax, ax
mov     byte ptr ds:[_gameaction], al ; GA_NOTHING
mov     byte ptr ds:[_savedescription], al ; \0
mov     word ptr ds:[_player + PLAYER_T.player_message], GGSAVED
call    Z_QuickMapPhysics_
call    R_FillBackScreen_ForceBufferRedraw_


POPA_NO_AX_OR_BP_MACRO

ret
ENDP

str_savegame_too_big:
db "Savegame buffer overrun", 0

savegame_too_big:
push    cs
mov     ax, OFFSET str_savegame_too_big
push    ax
call    I_Error_


 




PROC    G_GAME_ENDMARKER_ NEAR
PUBLIC  G_GAME_ENDMARKER_
ENDP


END
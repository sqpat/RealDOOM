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


EXTRN G_DoLoadLevel_:NEAR

.DATA

EXTRN _wminfo:WBSTARTSTRUCT_T
EXTRN _maxammo:word

.CODE


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


PROC   G_PlayerReborn_ FAR
PUBLIC G_PlayerReborn_

push   cx
push   di
push   si

push   word ptr ds:[_player + PLAYER_T.player_killcount]
push   word ptr ds:[_player + PLAYER_T.player_itemcount]
push   word ptr ds:[_player + PLAYER_T.player_secretcount]
mov    cx, SIZE PLAYER_T
mov    di, OFFSET _player
xor    ax, ax
rep    stosb
pop    word ptr ds:[_player + PLAYER_T.player_secretcount]
pop    word ptr ds:[_player + PLAYER_T.player_itemcount]
pop    word ptr ds:[_player + PLAYER_T.player_killcount]

inc    ax
mov    byte ptr ds:[_player + PLAYER_T.player_attackdown], al    ; true, dont do anything immediately
mov    byte ptr ds:[_player + PLAYER_T.player_usedown], al       ; true, dont do anything immediately
;mov    byte ptr ds:[_player + PLAYER_T.player_playerstate], ah   ; PST_LIVE, 0
mov    word ptr ds:[_player + PLAYER_T.player_health], MAXHEALTH
mov    byte ptr ds:[_player + PLAYER_T.player_pendingweapon], al ; WP_PISTOL
mov    byte ptr ds:[_player + PLAYER_T.player_readyweapon], al ; WP_PISTOL
mov    byte ptr ds:[_player + PLAYER_T.player_weaponowned + WP_FIST], al ; true
mov    byte ptr ds:[_player + PLAYER_T.player_weaponowned + WP_PISTOL], al ; true
mov    word ptr ds:[_player + PLAYER_T.player_ammo + 2 * AM_CLIP], 50

mov    di, OFFSET _player + PLAYER_T.player_ammo
mov    si, OFFSET _maxammo
movsw
movsw
movsw
movsw

pop    si
pop    di
pop    cx

retf
ENDP


PROC    G_GAME_ENDMARKER_ NEAR
PUBLIC  G_GAME_ENDMARKER_
ENDP


END
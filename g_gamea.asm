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


EXTRN M_WriteFile_:NEAR
EXTRN M_ReadFile_:NEAR

EXTRN Z_QuickMapPhysics_:FAR
EXTRN Z_QuickMapScratch_5000_:FAR

EXTRN R_ExecuteSetViewSize_:NEAR
EXTRN R_FillBackScreen_ForceBufferRedraw_:NEAR
EXTRN W_CheckNumForNameFarString_:NEAR
EXTRN locallib_strcmp_:NEAR

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
call    Z_QuickMapPhysics_
call    R_FillBackScreen_ForceBufferRedraw_


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



PROC    G_GAME_ENDMARKER_ NEAR
PUBLIC  G_GAME_ENDMARKER_
ENDP


END
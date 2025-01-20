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



EXTRN resetDS_:PROC
EXTRN _save_p:DWORD
EXTRN _playerMobjRef:WORD
EXTRN _player:PLAYER_T

.CODE
 
PROC P_LOADSTART
PUBLIC P_LOADSTART
ENDP

SIZEOF_PLAYER_VANILLA_T = 0118h
SIZEOF_PSPDEF_VANILLA_T = 16
SIZEOF_PSPDEF_T = 12
NUMPSPRITES = 2
NUMPOWERS = 6
NUMCARDS = 6
NUMAMMO = 4


PLAYER_T STRUC 

    ; cmd struct 8 bytes
    player_cmd_forwardmove    db ?
    player_cmd_sidemove       db ?
    player_cmd_angleturn      dw ?
    player_cmd_consistancy    dw ?
    player_cmd_chatchar       db ?
    player_cmd_buttons        db ?
    player_viewzvalue         dd ?
    player_viewheightvalue    dd ?
    player_deltaviewheight    dd ?
    player_bob                dd ?
    player_health             dw ?
    player_armorpoints        dw ?
    player_armortype	      db ?
    player_playerstate        db ?
    player_powers             dw NUMPOWERS   DUP(?)
    player_cards              db NUMCARDS    DUP(?)
    player_readyweapon        db ?
    player_pendingweapon      db ?
    player_weaponowned        db NUMWEAPONS  DUP(?)
    player_cheats		      db ?
    player_ammo               dw NUMAMMO     DUP(?)
    player_maxammo            dw NUMAMMO     DUP(?)
    player_attackdown         db ?
    player_usedown            db ?
    player_killcount          dw ?
    player_itemcount          dw ?
    player_secretcount        dw ?
    player_message            dw ?
	player_messagestring      dw ?
    player_damagecount        dw ?
    player_bonuscount         db ?
    player_refire		      db ?
    player_attackerRef        dw ?
    player_extralightvalue    db ?
    player_fixedcolormapvalue db ?
    player_colormap	          db ?
    player_didsecret	      db ?
    player_backpack           db ?

PLAYER_T ENDS



PROC P_UnArchivePlayers_  FAR
PUBLIC P_UnArchivePlayers_


push  bx
push  cx
push  dx
push  si
push  di

mov   ax, word ptr [_save_p]

;	PADSAVEP();
; todo probably improvable
mov   dx, 4
and   ax, 3
sub   dx, ax
mov   ax, dx
and   ax, 3
add   word ptr [_save_p], ax
les   cx, dword ptr [_save_p]
mov   bx, cx
mov   al, byte ptr es:[bx + 4]
mov   byte ptr [_player + 01Dh], al
push  ds  ; store ds
push  es  ; store es

push  es  ; swap ds/es
push  ds
pop   es
pop   ds
lea   si, [bx + 8]
mov   di, OFFSET _player
movsw 
movsw 
movsw 
movsw 

pop   es  ; retrieve es
pop   ds  ; retrieve ds 

mov   ax, word ptr es:[bx + 010h]
mov   word ptr [_player + 8], ax
mov   ax, word ptr es:[bx + 014h]
mov   word ptr [_player + 0Ch], ax
mov   ax, word ptr es:[bx + 018h]
mov   word ptr [_player + 010h], ax
mov   ax, word ptr es:[bx + 01ch]
mov   word ptr [_player + 014h], ax
mov   ax, word ptr es:[bx + 020h]
mov   word ptr [_player + 018h], ax
mov   ax, word ptr es:[bx + 024h]
mov   word ptr [_player + 01Ah], ax
mov   al, byte ptr es:[bx + 028h]
mov   byte ptr [_player + 01Ch], al
mov   al, byte ptr es:[bx + 05ch]
mov   byte ptr [_player + 022h], al
mov   al, byte ptr es:[bx + 070h]
mov   byte ptr [_player + 030h], al
mov   al, byte ptr es:[bx + 074h]
mov   byte ptr [_player + 031h], al
mov   al, byte ptr es:[bx + 0bch]
mov   byte ptr [_player + 04Ch], al
mov   al, byte ptr es:[bx + 0c0h]
mov   byte ptr [_player + 04Dh], al
mov   al, byte ptr es:[bx + 0c4h]
mov   byte ptr [_player + 03Bh], al
mov   al, byte ptr es:[bx + 0c8h]
mov   byte ptr [_player + 05Dh], al
mov   ax, word ptr es:[bx + 0cch]
mov   si, cx
mov   word ptr [_player + 043h], ax
mov   ax, word ptr es:[bx + 0d0h]
mov   dx, word ptr es:[bx + 012h]
mov   word ptr [_player + 050h], ax
mov   ax, word ptr es:[bx + 0d4h]
mov   word ptr [_player + 0Ah], dx
mov   word ptr [_player + 052h], ax
mov   ax, word ptr es:[bx + 0dch]
mov   dx, word ptr es:[bx + 016h]
mov   word ptr [_player + 058h], ax
mov   al, byte ptr es:[bx + 0e0h]
mov   word ptr [_player + 0Eh], dx
mov   byte ptr [_player + 05Ah], al
mov   al, byte ptr es:[bx + 0e8h]
mov   dx, word ptr es:[bx + 01ah]
mov   byte ptr [_player + 05Eh], al
mov   al, byte ptr es:[bx + 0ech]
mov   word ptr [_player + 012h], dx
mov   byte ptr [_player + 05Fh], al
mov   al, byte ptr es:[bx + 0f0h]
mov   dx, word ptr es:[bx + 01eh]
mov   byte ptr [_player + 060h], al
mov   al, byte ptr es:[bx + 0114h]
mov   word ptr [_player + 016h], dx
mov   byte ptr [_player + 061h], al
xor   bx, cx
load_next_power:
add   bx, 2
mov   ax, word ptr es:[si + 02ch]
add   si, 4
mov   word ptr [bx + _player + 01Ch], ax
cmp   bx, NUMPOWERS * 2  ; sizeof dw
jne   load_next_power
mov   si, cx
xor   bx, bx
load_next_key:
inc   bx
mov   al, byte ptr es:[si + 044h]
add   si, 4
mov   byte ptr [bx + _player + 029h], al
cmp   bx, NUMCARDS
jl    load_next_key
mov   si, cx
xor   bx, bx
load_next_ammo:
mov   ax, word ptr es:[si + 09ch]
mov   word ptr [bx + _player + 03Ch], ax
add   bx, 2
mov   ax, word ptr es:[si + 0ach]
add   si, 4
mov   word ptr [bx + _player + 042h], ax
cmp   bx, NUMAMMO * 2
jne   load_next_ammo
mov   si, cx
xor   bx, bx
load_next_weapon:
inc   bx
mov   al, byte ptr es:[si + 078h]
add   si, 4
mov   byte ptr [bx + _player + 031h], al
cmp   bx, NUMWEAPONS
jl    load_next_weapon
mov   si, cx
xor   bx, bx
load_next_sprite:
mov   ax, word ptr es:[si + 0F4h]
mov   word ptr [bx + _psprites], ax
test  ax, ax
je    set_psprite_statenum_null
done_with_psprite:
mov   ax, word ptr es:[si + 0F8h]
mov   word ptr [bx + _psprites + 2], ax
mov   ax, word ptr es:[si + 0FCh]
mov   dx, word ptr es:[si + 0FEh]
mov   word ptr [bx + _psprites + 4], ax
mov   word ptr [bx + _psprites + 6], dx
mov   ax, word ptr es:[si + 0100h]
mov   dx, word ptr es:[si + 0102h]
mov   word ptr [bx + _psprites + 8], ax
add   si, SIZEOF_PSPDEF_VANILLA_T
mov   word ptr [bx + _psprites + 0Ah], dx
add   bx, SIZEOF_PSPDEF_T
cmp   bx, SIZEOF_PSPDEF_T * NUMPSPRITES
jne   load_next_sprite
mov   word ptr [_player + 056h], 0FFFFh
xor   ax, ax
add   word ptr [_save_p], SIZEOF_PLAYER_VANILLA_T 
mov   word ptr [_playerMobjRef], ax
mov   word ptr [_player + 05Ch], ax

pop   di
pop   si
pop   dx
pop   cx
pop   bx
retf  
set_psprite_statenum_null:
mov   word ptr [bx + _psprites], 0FFFFh
jmp   done_with_psprite



ENDP


END
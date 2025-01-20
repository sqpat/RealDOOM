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
EXTRN _numlines:WORD
EXTRN _numsectors:WORD
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
push  si
push  di

mov   ax, word ptr [_save_p]

;	PADSAVEP();
and   ax, 3
jz    dont_pad
mov   cx, 4
sub   cx, ax
add   word ptr [_save_p], cx
dont_pad:
les   bx, dword ptr [_save_p]

mov   al, byte ptr es:[bx + 4]
mov   byte ptr [_player + 01Dh], al


push  es  ; swap ds/es
push  ds
pop   es
pop   ds
lea   si, [bx + 8]
mov   di, OFFSET _player

mov   cx, 13
rep   movsw
mov   cx, bx
inc   si
inc   si
movsw           ; 024h -> 01Ah
inc   si
inc   si
movsw           ; 028h -> 01Ch

push  es  ; swap ds/es
push  ds
pop   es
pop   ds



mov   al, byte ptr es:[bx + 05Ch]
mov   byte ptr [_player + 022h], al

mov   al, byte ptr es:[bx + 070h]
mov   ah, byte ptr es:[bx + 074h]
mov   word ptr [_player + 030h], ax

mov   al, byte ptr es:[bx + 0BCh]
mov   ah, byte ptr es:[bx + 0C0h]
mov   word ptr [_player + 04Ch], ax

mov   al, byte ptr es:[bx + 0C4h]
mov   byte ptr [_player + 03Bh], al
mov   al, byte ptr es:[bx + 0C8h]
mov   byte ptr [_player + 05Dh], al

mov   ax, word ptr es:[bx + 0CCh]
mov   word ptr [_player + 043h], ax
mov   ax, word ptr es:[bx + 0D0h]
mov   word ptr [_player + 050h], ax
mov   ax, word ptr es:[bx + 0D4h]
mov   word ptr [_player + 052h], ax
mov   ax, word ptr es:[bx + 0DCh]
mov   word ptr [_player + 058h], ax
mov   al, byte ptr es:[bx + 0E0h]
mov   byte ptr [_player + 05Ah], al

mov   al, byte ptr es:[bx + 0E8h]
mov   ah, byte ptr es:[bx + 0ECh]
mov   word ptr [_player + 05Eh], ax

mov   al, byte ptr es:[bx + 0F0h]
mov   ah, byte ptr es:[bx + 0114h]
mov   word ptr [_player + 060h], ax

mov   si, cx
xor   bx, bx
load_next_power:
add   bx, 2
mov   ax, word ptr es:[si + 02Ch]
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
inc   bx
inc   bx
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
mov   word ptr [bx + _psprites + 4], ax
mov   ax, word ptr es:[si + 0FEh]
mov   word ptr [bx + _psprites + 6], ax
mov   ax, word ptr es:[si + 0100h]
mov   word ptr [bx + _psprites + 8], ax
mov   ax, word ptr es:[si + 0102h]
mov   word ptr [bx + _psprites + 0Ah], ax
add   si, SIZEOF_PSPDEF_VANILLA_T
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
pop   cx
pop   bx
retf  
set_psprite_statenum_null:
mov   word ptr [bx + _psprites], 0FFFFh
jmp   done_with_psprite



ENDP





SIZEOF_SECTOR_T = 16
SIZEOF_SECTOR_PHYSICS_T = 16
SIZEOF_LINE_PHYSICS_T = 16
SIZEOF_LINE_T = 4

PROC P_UnArchiveWorld_  FAR
PUBLIC P_UnArchiveWorld_


push  bx
push  cx
push  dx
push  si
push  di
push  bp
mov   bp, sp
sub   sp, 012h

mov   cx, SECTORS_SEGMENT
mov   es, cx
mov   word ptr [bp - 4], cx

mov   cx, word ptr [_numsectors]

mov   di, _sectors_physics
lds   bx, dword ptr [_save_p]

xor   si, si



load_next_sector:
; todo change to si/di not bx/si
mov   ax, word ptr ds:[bx]
shl   ax, 3
mov   word ptr es:[si], ax

mov   ax, word ptr ds:[bx + 2]
shl   ax, 3
add   bx, 2
mov   word ptr es:[si + 2], ax

mov   al, byte ptr ds:[bx + 2]
add   bx, 2
mov   byte ptr es:[si + 4], al
mov   al, byte ptr ds:[bx + 2]
add   bx, 2
mov   byte ptr es:[si + 5], al
mov   al, byte ptr ds:[bx + 2]
add   bx, 4
mov   word ptr es:[si + 8], 0
mov   byte ptr es:[si + 0Eh], al
mov   al, byte ptr ds:[bx]
add   bx, 2
mov   byte ptr ss:[di + 0Eh], al
mov   al, byte ptr ds:[bx]
mov   word ptr ss:[di + 8], 0
add   bx, 2
mov   byte ptr ss:[di + 0Eh], al

add   si, SIZEOF_SECTOR_T
add   di, SIZEOF_SECTOR_PHYSICS_T

loop  load_next_sector

done_loading_sectors:

push  ss
pop   ds



mov   word ptr [bp - 0Ah], 0

do_load_lines:
mov   word ptr [bp - 010h], 0
mov   word ptr [bp - 0Ch], LINES_PHYSICS_SEGMENT
mov   word ptr [bp - 0Eh], 0
load_next_line:
mov   ax, word ptr [bp - 0Ah]
mov   cx, word ptr [bp - 0Ah]
sar   ax, 0Fh
xor   cx, ax
sub   cx, ax
xor   ch, ch
mov   es, word ptr [bp - 4]
and   cl, 7
mov   si, word ptr [bp - 0Ah]
xor   cx, ax
mov   dx, word ptr es:[bx]
sub   cx, ax
mov   ax, 8
mov   byte ptr [bp - 2], dl
sub   ax, cx
xor   dl, dl
mov   cx, ax
mov   ax, LINEFLAGSLIST_SEGMENT
and   dh, 1
mov   es, ax
mov   al, byte ptr [bp - 2]
sar   dx, cl
mov   byte ptr es:[si], al
mov   ax, si
mov   cx, dx
cwd
shl   dx, 3
sbb   ax, dx
sar   ax, 3
mov   di, word ptr [bp - 0Eh]
mov   word ptr [bp - 8], LINES_SEGMENT
add   bx, 4
mov   dx, SEENLINES_6800_SEGMENT
mov   si, ax
mov   es, dx
or    byte ptr es:[si], cl
mov   es, word ptr [bp - 4]
mov   si, word ptr [bp - 010h]
mov   al, byte ptr es:[bx - 2]
mov   es, word ptr [bp - 0Ch]
add   bx, 2
mov   byte ptr es:[si + 0Fh], al
mov   es, word ptr [bp - 4]
mov   word ptr [bp - 6], di
mov   al, byte ptr es:[bx - 2]
mov   es, word ptr [bp - 0Ch]
mov   cx, SIDES_RENDER_9000_SEGMENT
mov   byte ptr es:[si + 0Eh], al
xor   ax, ax
label_7:
mov   es, word ptr [bp - 8]
mov   si, word ptr [bp - 6]
cmp   word ptr es:[si], -1
jne   label_8
label_5:
inc   ax
add   word ptr [bp - 6], 2
cmp   ax, 2
jl    label_7
inc   word ptr [bp - 0Ah]
add   word ptr [bp - 010h], SIZEOF_LINE_PHYSICS_T
mov   ax, word ptr [bp - 0Ah]
add   word ptr [bp - 0Eh], SIZEOF_LINE_T
cmp   ax, word ptr [_numlines]
jge   done_loading_lines
jmp   load_next_line
done_loading_lines:

mov   word ptr [_save_p], bx

LEAVE
pop   di
pop   si
pop   dx
pop   cx
pop   bx
retf  
label_8:
mov   word ptr [bp - 012h], SIDES_SEGMENT
mov   di, word ptr [bp - 6]
mov   si, word ptr es:[si]
mov   di, word ptr es:[di]
mov   es, word ptr [bp - 4]
shl   si, 3
mov   dx, word ptr es:[bx]
mov   es, word ptr [bp - 012h]
add   bx, 2
mov   word ptr es:[si + 6], dx
mov   es, word ptr [bp - 4]
shl   di, 2
mov   dx, word ptr es:[bx]
mov   es, cx
add   bx, 2
mov   word ptr es:[di], dx
mov   es, word ptr [bp - 4]
mov   dx, word ptr es:[bx]
mov   es, word ptr [bp - 012h]
add   bx, 2
mov   word ptr es:[si], dx
mov   es, word ptr [bp - 4]
mov   dx, word ptr es:[bx]
mov   es, word ptr [bp - 012h]
add   bx, 2
mov   word ptr es:[si + 2], dx
mov   es, word ptr [bp - 4]
mov   dx, word ptr es:[bx]
mov   es, word ptr [bp - 012h]
add   bx, 2
mov   word ptr es:[si + 4], dx
jmp   label_5


ENDP



END
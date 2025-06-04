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

DIVLINE_T STRUC 
    dl_x    dd ?
    dl_y    dd ?
    dl_dx   dd ?
    dl_dy   dd ?
DIVLINE_T ENDS

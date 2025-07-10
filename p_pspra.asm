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
INCLUDE CONSTANT.INC
INCLUDE defs.inc
INSTRUCTION_SET_MACRO


; hack but oh well
P_SIGHT_STARTMARKER_ = 0 

.DATA

EXTRN _weaponinfo:DWORD

.CODE



PROC    P_PSPR_STARTMARKER_ 
PUBLIC  P_PSPR_STARTMARKER_
ENDP

COMMENT @

PS_WEAPON = 0
PS_FLASH = 1
WEAPONBOTTOM_HIGH = 128
WEAPONBOTTOM_LOW = 0
WEAPONTOP_HIGH = 32
WEAPONTOP_LOW = 0

; todo constants
WP_FIST = 0
WP_PISTOL = 1
WP_SHOTGUN = 2
WP_CHAINGUN = 3
WP_MISSILE = 4
WP_PLASMA = 5
WP_BFG = 6
WP_CHAINSAW = 7
WP_SUPERSHOTGUN = 8
WP_NOCHANGE = 0Ah

BFGCELLS = 40



AM_CLIP = 0	 ; Pistol / chaingun ammo.
AM_SHELL = 1 ; Shotgun / double barreled shotgun.
AM_CELL = 2  ; Plasma rifle, BFG.
AM_MISL = 3	 ; Missile launcher.
NUMAMMO 4
AM_NOAMMO 5	 ; Unlimited for chainsaw / fist.	

PROC P_BringUpWeapon_ NEAR
PUBLIC P_BringUpWeapon_
 


0x0000000000006cd0:  53                   push  bx
0x0000000000006cd1:  52                   push  dx
0x0000000000006cd2:  56                   push  si
0x0000000000006cd3:  BB 01 08             mov   bx, OFFSET _player + PLAYER_T.player_pendingweapon
0x0000000000006cd6:  80 3F 0A             cmp   byte ptr ds:[bx], WP_NOCHANGE
0x0000000000006cd9:  74 31                je    label_1
label_3:
0x0000000000006cdb:  BB 01 08             mov   bx, OFFSET _player + PLAYER_T.player_pendingweapon
0x0000000000006cde:  80 3F 07             cmp   byte ptr ds:[bx], 7
0x0000000000006ce1:  74 32                je    label_2
label_4:
0x0000000000006ce3:  BB 01 08             mov   bx, OFFSET _player + PLAYER_T.player_pendingweapon
0x0000000000006ce6:  8A 1F                mov   bl, byte ptr ds:[bx]
0x0000000000006ce8:  30 FF                xor   bh, bh
0x0000000000006cea:  6B DB 0B             imul  bx, bx, SIZEOF_MOBJINFO_T  ; todo x86-16
0x0000000000006ced:  8B 97 0F 0E          mov   dx, word ptr ds:[bx + _weaponinfo + WEAPONINFO_T.weaponinfo_upstate]
0x0000000000006cf1:  BB 01 08             mov   bx, OFFSET _player + PLAYER_T.player_pendingweapon
0x0000000000006cf4:  C6 07 0A             mov   byte ptr ds:[bx], WP_NOCHANGE
0x0000000000006cf7:  BB 90 03             mov   bx, OFFSET _psprites + (PS_WEAPON * SIZEOF_PSPDEF_T) + PSPDEF_T.pspdef_sy
0x0000000000006cfa:  C7 07 00 00          mov   word ptr ds:[bx], WEAPONBOTTOM_LOW
0x0000000000006cfe:  31 C0                xor   ax, ax
0x0000000000006d00:  C7 47 02 80 00       mov   word ptr ds:[bx + 2], WEAPONBOTTOM_HIGH
0x0000000000006d05:  E8 CC 0A             call  P_SetPsprite_
0x0000000000006d08:  5E                   pop   si
0x0000000000006d09:  5A                   pop   dx
0x0000000000006d0a:  5B                   pop   bx
0x0000000000006d0b:  C3                   ret   
label_1:
0x0000000000006d0c:  BE 00 08             mov   si, OFFSET _player + PLAYER_T.player_readyweapon
0x0000000000006d0f:  8A 04                mov   al, byte ptr ds:[si]
0x0000000000006d11:  88 07                mov   byte ptr ds:[bx], al
0x0000000000006d13:  EB C6                jmp   label_3
label_2:
0x0000000000006d15:  BB EC 06             mov   bx, OFFSET _playerMobj
0x0000000000006d18:  BA 0A 00             mov   dx, SFX_SAWUP
0x0000000000006d1b:  8B 07                mov   ax, word ptr ds:[bx]
0x0000000000006d1d:  0E                   push  cs
0x0000000000006d1e:  3E E8 2E 98          call  S_StartSound_
0x0000000000006d22:  EB BF                jmp   label_4

ENDP

PROC P_CheckAmmo_ NEAR
PUBLIC P_CheckAmmo_
ENDP
; same func apparently
PROC A_CheckReload_ NEAR 
PUBLIC A_CheckReload_

0x0000000000006d24:  53                   push  bx
0x0000000000006d25:  52                   push  dx
0x0000000000006d26:  56                   push  si
0x0000000000006d27:  BB 00 08             mov   bx, OFFSET _player + PLAYER_T.player_readyweapon
0x0000000000006d2a:  8A 07                mov   al, byte ptr ds:[bx]
0x0000000000006d2c:  30 E4                xor   ah, ah
0x0000000000006d2e:  6B D8 0B             imul  bx, ax, SIZEOF_MOBJINFO_T  ; todo x86-16
0x0000000000006d31:  8A 87 0E 0E          mov   al, byte ptr ds:[bx + _weaponinfo]
0x0000000000006d35:  BB 00 08             mov   bx, OFFSET _player + PLAYER_T.player_readyweapon
0x0000000000006d38:  80 3F 06             cmp   byte ptr ds:[bx], WP_BFG
0x0000000000006d3b:  75 52                jne   label_5
0x0000000000006d3d:  BB 28 00             mov   bx, BFGCELLS
label_7:
0x0000000000006d40:  3C 05                cmp   al, AM_NOAMMO
0x0000000000006d42:  74 5A                je    label_8
0x0000000000006d44:  30 E4                xor   ah, ah
0x0000000000006d46:  89 C6                mov   si, ax
0x0000000000006d48:  01 C6                add   si, ax
0x0000000000006d4a:  3B 9C 0C 08          cmp   bx, word ptr ds:[si + OFFSET _player + PLAYER_T.player_ammo]
0x0000000000006d4e:  7E 4E                jle   label_8
0x0000000000006d50:  BA 01 08             mov   dx, OFFSET _player + PLAYER_T.player_pendingweapon
0x0000000000006d53:  30 C0                xor   al, al
label_15:
0x0000000000006d55:  BB 07 08             mov   bx, OFFSET _player + PLAYER_T.player_weaponowned + WP_PLASMA
0x0000000000006d58:  3A 07                cmp   al, byte ptr ds:[bx]
0x0000000000006d5a:  74 46                je    label_14
0x0000000000006d5c:  BB 10 08             mov   bx, OFFSET _player + PLAYER_T.player_ammo + (2 * AM_CELL)
0x0000000000006d5f:  3B 07                cmp   ax, word ptr ds:[bx]
0x0000000000006d61:  74 3F                je    label_14
0x0000000000006d63:  BB ED 02             mov   bx, OFFSET _shareware
0x0000000000006d66:  3A 07                cmp   al, byte ptr ds:[bx]
0x0000000000006d68:  75 38                jne   label_14
0x0000000000006d6a:  89 D3                mov   bx, dx
0x0000000000006d6c:  C6 07 05             mov   byte ptr ds:[bx], WP_PLASMA
label_11:
0x0000000000006d6f:  89 D3                mov   bx, dx
0x0000000000006d71:  80 3F 0A             cmp   byte ptr ds:[bx], WP_NOCHANGE
0x0000000000006d74:  74 DF                je    label_15
0x0000000000006d76:  BB 00 08             mov   bx, OFFSET _player + PLAYER_T.player_readyweapon
0x0000000000006d79:  8A 07                mov   al, byte ptr ds:[bx]
0x0000000000006d7b:  30 E4                xor   ah, ah
0x0000000000006d7d:  6B D8 0B             imul  bx, ax, SIZEOF_MOBJINFO_T  ; todo x86-16
0x0000000000006d80:  8B 97 11 0E          mov   dx, word ptr ds:[bx + OFFSET _weaponinfo + WEAPONINFO_T.weaponinfo_downstate]

0x0000000000006d84:  30 C0                xor   al, al
0x0000000000006d86:  E8 4B 0A             call  P_SetPsprite_
0x0000000000006d89:  30 C0                xor   al, al
label_9:
0x0000000000006d8b:  5E                   pop   si
0x0000000000006d8c:  5A                   pop   dx
0x0000000000006d8d:  5B                   pop   bx
0x0000000000006d8e:  C3                   ret   
label_5:
0x0000000000006d8f:  80 3F 08             cmp   byte ptr ds:[bx], WP_SUPERSHOTGUN
0x0000000000006d92:  75 05                jne   label_6
0x0000000000006d94:  BB 02 00             mov   bx, 2
0x0000000000006d97:  EB A7                jmp   label_7
label_6:
0x0000000000006d99:  BB 01 00             mov   bx, 1
0x0000000000006d9c:  EB A2                jmp   label_7
label_8:
0x0000000000006d9e:  B0 01                mov   al, 1
0x0000000000006da0:  EB E9                jmp   label_9
label_14:
0x0000000000006da2:  BB 0A 08             mov   bx, OFFSET _player + PLAYER_T.player_weaponowned + WP_SUPERSHOTGUN
0x0000000000006da5:  3A 07                cmp   al, byte ptr ds:[bx]
0x0000000000006da7:  74 16                je    label_10
0x0000000000006da9:  BB 0E 08             mov   bx, OFFSET _player + PLAYER_T.player_ammo + (2 * AM_SHELL)
0x0000000000006dac:  83 3F 02             cmp   word ptr ds:[bx], 2
0x0000000000006daf:  7E 0E                jle   label_10
0x0000000000006db1:  BB EB 02             mov   bx, OFFSET _commercial
0x0000000000006db4:  3A 07                cmp   al, byte ptr ds:[bx]
0x0000000000006db6:  74 07                je    label_10
0x0000000000006db8:  89 D3                mov   bx, dx
0x0000000000006dba:  C6 07 08             mov   byte ptr ds:[bx], 8
0x0000000000006dbd:  EB B0                jmp   label_11
label_10:
0x0000000000006dbf:  BB 05 08             mov   bx, OFFSET _player + PLAYER_T.player_weaponowned + WP_CHAINGUN
0x0000000000006dc2:  3A 07                cmp   al, byte ptr ds:[bx]
0x0000000000006dc4:  74 0E                je    label_16
0x0000000000006dc6:  BB 0C 08             mov   bx, OFFSET _player + PLAYER_T.player_ammo
0x0000000000006dc9:  3B 07                cmp   ax, word ptr ds:[bx]
0x0000000000006dcb:  74 07                je    label_16
0x0000000000006dcd:  89 D3                mov   bx, dx
0x0000000000006dcf:  C6 07 03             mov   byte ptr ds:[bx], 3
0x0000000000006dd2:  EB 9B                jmp   label_11
label_16:
0x0000000000006dd4:  BB 04 08             mov   bx, OFFSET _player + PLAYER_T.player_weaponowned + WP_SHOTGUN
0x0000000000006dd7:  3A 07                cmp   al, byte ptr ds:[bx]
0x0000000000006dd9:  74 0E                je    label_13
0x0000000000006ddb:  BB 0E 08             mov   bx, OFFSET _player + PLAYER_T.player_ammo + (2 * AM_SHELL)
0x0000000000006dde:  3B 07                cmp   ax, word ptr ds:[bx]
0x0000000000006de0:  74 07                je    label_13
0x0000000000006de2:  89 D3                mov   bx, dx
0x0000000000006de4:  C6 07 02             mov   byte ptr ds:[bx], 2
0x0000000000006de7:  EB 86                jmp   label_11
label_13:
0x0000000000006de9:  BB 0C 08             mov   bx, OFFSET _player + PLAYER_T.player_ammo
0x0000000000006dec:  3B 07                cmp   ax, word ptr ds:[bx]
0x0000000000006dee:  74 08                je    label_17
0x0000000000006df0:  89 D3                mov   bx, dx
0x0000000000006df2:  C6 07 01             mov   byte ptr ds:[bx], 1
0x0000000000006df5:  E9 77 FF             jmp   label_11
label_17:
0x0000000000006df8:  BB 09 08             mov   bx, OFFSET _player + PLAYER_T.player_weaponowned + WP_CHAINSAW
0x0000000000006dfb:  3A 07                cmp   al, byte ptr ds:[bx]
0x0000000000006dfd:  74 08                je    label_18
0x0000000000006dff:  89 D3                mov   bx, dx
0x0000000000006e01:  C6 07 07             mov   byte ptr ds:[bx], 7
0x0000000000006e04:  E9 68 FF             jmp   label_11
label_18
0x0000000000006e07:  BB 06 08             mov   bx, OFFSET _player + PLAYER_T.player_weaponowned + WP_MISSILE
0x0000000000006e0a:  3A 07                cmp   al, byte ptr ds:[bx]
0x0000000000006e0c:  74 0F                je    label_19
0x0000000000006e0e:  BB 12 08             mov   bx, OFFSET _player + PLAYER_T.player_ammo + (2 * AM_MISL)
0x0000000000006e11:  3B 07                cmp   ax, word ptr ds:[bx]
0x0000000000006e13:  74 08                je    label_19
0x0000000000006e15:  89 D3                mov   bx, dx
0x0000000000006e17:  C6 07 04             mov   byte ptr ds:[bx], 4
0x0000000000006e1a:  E9 52 FF             jmp   label_11
label_19:
0x0000000000006e1d:  BB 08 08             mov   bx, OFFSET _player + PLAYER_T.player_weaponowned + WP_BFG
0x0000000000006e20:  3A 07                cmp   al, byte ptr ds:[bx]
0x0000000000006e22:  74 17                je    label_12
0x0000000000006e24:  BB 10 08             mov   bx, OFFSET _player + PLAYER_T.player_ammo + (2 * AM_CELL)
0x0000000000006e27:  83 3F 28             cmp   word ptr ds:[bx], BFGCELLS
0x0000000000006e2a:  7E 0F                jle   label_12
0x0000000000006e2c:  BB ED 02             mov   bx, OFFSET _shareware
0x0000000000006e2f:  3A 07                cmp   al, byte ptr ds:[bx]
0x0000000000006e31:  75 08                jne   label_12
0x0000000000006e33:  89 D3                mov   bx, dx
0x0000000000006e35:  C6 07 06             mov   byte ptr ds:[bx], 6
0x0000000000006e38:  E9 34 FF             jmp   label_11
label_12:
0x0000000000006e3b:  89 D3                mov   bx, dx
0x0000000000006e3d:  88 07                mov   byte ptr ds:[bx], al
0x0000000000006e3f:  E9 2D FF             jmp   label_11

ENDP

PROC P_FireWeapon_ NEAR 
PUBLIC P_FireWeapon_


0x0000000000006e42:  53                   push  bx
0x0000000000006e43:  52                   push  dx
0x0000000000006e44:  E8 DD FE             call  A_CheckReload_
0x0000000000006e47:  84 C0                test  al, al
0x0000000000006e49:  75 03                jne   label_20
0x0000000000006e4b:  5A                   pop   dx
0x0000000000006e4c:  5B                   pop   bx
0x0000000000006e4d:  C3                   ret   
label_20:
0x0000000000006e4e:  BB EC 06             mov   bx, OFFSET _playerMobj
0x0000000000006e51:  BA 9A 00             mov   dx, S_PLAY_ATK1
0x0000000000006e54:  8B 07                mov   ax, word ptr ds:[bx]
0x0000000000006e56:  BB 00 08             mov   bx, OFFSET _player + PLAYER_T.player_readyweapon
0x0000000000006e59:  0E                   push  cs
0x0000000000006e5a:  3E E8 CE 2D          call  P_SetMobjState_
0x0000000000006e5e:  8A 07                mov   al, byte ptr ds:[bx]
0x0000000000006e60:  30 E4                xor   ah, ah
0x0000000000006e62:  6B D8 0B             imul  bx, ax, SIZEOF_MOBJINFO_T  ; todo x86-16
0x0000000000006e65:  8B 97 15 0E          mov   dx, word ptr ds:[bx + OFFSET _weaponinfo + WEAPONINFO_T.weaponinfo_atkstate]
0x0000000000006e69:  30 C0                xor   al, al
0x0000000000006e6b:  E8 66 09             call  P_SetPsprite_
0x0000000000006e6e:  E8 53 BB             call  P_NoiseAlert_
0x0000000000006e71:  5A                   pop   dx
0x0000000000006e72:  5B                   pop   bx
0x0000000000006e73:  C3                   ret   

ENDP

PROC P_DropWeapon_ NEAR
PUBLIC P_DropWeapon_

0x0000000000006e74:  53                   push  bx
0x0000000000006e75:  52                   push  dx
0x0000000000006e76:  BB 00 08             mov   bx, OFFSET _player + PLAYER_T.player_readyweapon
0x0000000000006e79:  8A 07                mov   al, byte ptr ds:[bx]
0x0000000000006e7b:  30 E4                xor   ah, ah
0x0000000000006e7d:  6B D8 0B             imul  bx, ax, SIZEOF_MOBJINFO_T  ; todo x86-16
0x0000000000006e80:  8B 97 11 0E          mov   dx, word ptr ds:[bx + OFFSET _weaponinfo + WEAPONINFO_T.weaponinfo_downstate]
0x0000000000006e84:  30 C0                xor   al, al
0x0000000000006e86:  E8 4B 09             call  P_SetPsprite_
0x0000000000006e89:  5A                   pop   dx
0x0000000000006e8a:  5B                   pop   bx
0x0000000000006e8b:  C3                   ret   

ENDP

PROC A_WeaponReady_ NEAR
PUBLIC A_WeaponReady_

0x0000000000006e8c:  53                   push  bx
0x0000000000006e8d:  51                   push  cx
0x0000000000006e8e:  52                   push  dx
0x0000000000006e8f:  56                   push  si
0x0000000000006e90:  57                   push  di
0x0000000000006e91:  55                   push  bp
0x0000000000006e92:  89 E5                mov   bp, sp
0x0000000000006e94:  83 EC 02             sub   sp, 2
0x0000000000006e97:  89 C6                mov   si, ax
0x0000000000006e99:  BB 30 07             mov   bx, OFFSET _playerMobj_pos
0x0000000000006e9c:  C4 3F                les   di, dword ptr ds:[bx]
0x0000000000006e9e:  26 8B 45 12          mov   ax, word ptr es:[di + MOBJ_POS_T.mp_statenum]
0x0000000000006ea2:  3D 9A 00             cmp   ax, S_PLAY_ATK1
0x0000000000006ea5:  74 05                je    label_22
0x0000000000006ea7:  3D 9B 00             cmp   ax, S_PLAY_ATK2
0x0000000000006eaa:  75 0D                jne   label_23
label_22:
0x0000000000006eac:  BB EC 06             mov   bx, OFFSET _playerMobj
0x0000000000006eaf:  BA 95 00             mov   dx, S_PLAY
0x0000000000006eb2:  8B 07                mov   ax, word ptr ds:[bx]
0x0000000000006eb4:  0E                   push  cs
0x0000000000006eb5:  E8 74 2D             call  P_SetMobjState_
0x0000000000006eb8:  90                   nop   
label_23:
0x0000000000006eb9:  BB 00 08             mov   bx, OFFSET _player + PLAYER_T.player_readyweapon
0x0000000000006ebc:  80 3F 07             cmp   byte ptr ds:[bx], 7
0x0000000000006ebf:  75 12                jne   label_24
0x0000000000006ec1:  83 3C 43             cmp   word ptr ds:[si], S_SAW
0x0000000000006ec4:  75 0D                jne   label_24
0x0000000000006ec6:  BB EC 06             mov   bx, OFFSET _playerMobj
0x0000000000006ec9:  BA 0B 00             mov   dx, SFX_SAWIDL
0x0000000000006ecc:  8B 07                mov   ax, word ptr ds:[bx]
0x0000000000006ece:  0E                   push  cs
0x0000000000006ecf:  E8 7E 96             call  S_StartSound_
0x0000000000006ed2:  90                   nop   
label_24:
0x0000000000006ed3:  BB 01 08             mov   bx, OFFSET _player + PLAYER_T.player_pendingweapon
0x0000000000006ed6:  80 3F 0A             cmp   byte ptr ds:[bx], WP_NOCHANGE
0x0000000000006ed9:  75 35                jne   label_25
0x0000000000006edb:  BB E8 07             mov   bx, OFFSET _player + PLAYER_T.player_health
0x0000000000006ede:  83 3F 00             cmp   word ptr ds:[bx], 0
0x0000000000006ee1:  74 2D                je    label_25
0x0000000000006ee3:  BB D7 07             mov   bx, OFFSET _player + PLAYER_T.player_cmd_buttons
0x0000000000006ee6:  F6 07 01             test  byte ptr ds:[bx], 1
0x0000000000006ee9:  74 3A                je    label_26
0x0000000000006eeb:  BB 1C 08             mov   bx, OFFSET _player + PLAYER_T.player_attackdown
0x0000000000006eee:  80 3F 00             cmp   byte ptr ds:[bx], 0
0x0000000000006ef1:  74 0D                je    label_27
0x0000000000006ef3:  BB 00 08             mov   bx, OFFSET _player + PLAYER_T.player_readyweapon
0x0000000000006ef6:  8A 07                mov   al, byte ptr ds:[bx]
0x0000000000006ef8:  3C 04                cmp   al, 4
0x0000000000006efa:  74 2F                je    label_28
0x0000000000006efc:  3C 06                cmp   al, 6
0x0000000000006efe:  74 2B                je    label_28
label_27:
0x0000000000006f00:  BB 1C 08             mov   bx, OFFSET _player + PLAYER_T.player_attackdown
0x0000000000006f03:  C6 07 01             mov   byte ptr ds:[bx], 1
0x0000000000006f06:  E8 39 FF             call  P_FireWeapon_
exit_a_weaponready:
0x0000000000006f09:  C9                   LEAVE_MACRO 
0x0000000000006f0a:  5F                   pop   di
0x0000000000006f0b:  5E                   pop   si
0x0000000000006f0c:  5A                   pop   dx
0x0000000000006f0d:  59                   pop   cx
0x0000000000006f0e:  5B                   pop   bx
0x0000000000006f0f:  C3                   ret   
label_25:
0x0000000000006f10:  BB 00 08             mov   bx, OFFSET _player + PLAYER_T.player_readyweapon
0x0000000000006f13:  8A 1F                mov   bl, byte ptr ds:[bx]
0x0000000000006f15:  30 FF                xor   bh, bh
0x0000000000006f17:  6B DB 0B             imul  bx, bx, SIZEOF_MOBJINFO_T  ; todo x86-16
0x0000000000006f1a:  31 C0                xor   ax, ax
0x0000000000006f1c:  8B 97 11 0E          mov   dx, word ptr ds:[bx + OFFSET _weaponinfo + WEAPONINFO_T.weaponinfo_downstate]
0x0000000000006f20:  E8 B1 08             call  P_SetPsprite_
0x0000000000006f23:  EB E4                jmp   exit_a_weaponready
label_26:
0x0000000000006f25:  BB 1C 08             mov   bx, OFFSET _player + PLAYER_T.player_attackdown
0x0000000000006f28:  C6 07 00             mov   byte ptr ds:[bx], 0
label_28:
0x0000000000006f2b:  BB 1C 07             mov   bx, OFFSET _leveltime
0x0000000000006f2e:  8B 07                mov   ax, word ptr ds:[bx]
0x0000000000006f30:  C1 E0 07             shl   ax, 7
0x0000000000006f33:  BB E4 07             mov   bx, OFFSET _player + PLAYER_T.player_bob
0x0000000000006f36:  80 E4 1F             and   ah, 0x1f
0x0000000000006f39:  8B 4F 02             mov   cx, word ptr ds:[bx + 2]
0x0000000000006f3c:  89 46 FE             mov   word ptr [bp - 2], ax
0x0000000000006f3f:  8B 07                mov   ax, word ptr ds:[bx]
0x0000000000006f41:  8B 56 FE             mov   dx, word ptr [bp - 2]
0x0000000000006f44:  89 C3                mov   bx, ax
0x0000000000006f46:  B8 D6 33             mov   ax, FINECOSINE_SEGMENT
0x0000000000006f49:  9A 9F 5B 86 0A       call  FixedMulTrig_
0x0000000000006f4e:  BB E4 07             mov   bx, OFFSET _player + PLAYER_T.player_bob
0x0000000000006f51:  05 00 00             add   ax, 0
0x0000000000006f54:  83 D2 01             adc   dx, 1
0x0000000000006f57:  89 44 04             mov   word ptr ds:[si + 4], ax
0x0000000000006f5a:  80 66 FF 0F          and   byte ptr [bp - 1], 0Fh
0x0000000000006f5e:  89 54 06             mov   word ptr ds:[si + 6], dx
0x0000000000006f61:  8B 56 FE             mov   dx, word ptr [bp - 2]
0x0000000000006f64:  8B 07                mov   ax, word ptr ds:[bx]
0x0000000000006f66:  8B 4F 02             mov   cx, word ptr ds:[bx + 2]
0x0000000000006f69:  89 C3                mov   bx, ax
0x0000000000006f6b:  B8 D6 31             mov   ax, FINESINE_SEGMENT
0x0000000000006f6e:  9A 9F 5B 86 0A       call  FixedMulTrig_
0x0000000000006f73:  05 00 00             add   ax, 0
0x0000000000006f76:  83 D2 20             adc   dx, WEAPONTOP_HIGH
0x0000000000006f79:  89 44 08             mov   word ptr ds:[si + 8], ax
0x0000000000006f7c:  89 54 0A             mov   word ptr ds:[si + 0Ah], dx
0x0000000000006f7f:  C9                   LEAVE_MACRO 
0x0000000000006f80:  5F                   pop   di
0x0000000000006f81:  5E                   pop   si
0x0000000000006f82:  5A                   pop   dx
0x0000000000006f83:  59                   pop   cx
0x0000000000006f84:  5B                   pop   bx
0x0000000000006f85:  C3                   ret   

ENDP

PROC A_ReFire_ NEAR
PUBLIC A_ReFire_


0x0000000000006f86:  53                   push  bx
0x0000000000006f87:  BB D7 07             mov   bx, OFFSET _player + PLAYER_T.player_cmd_buttons
0x0000000000006f8a:  F6 07 01             test  byte ptr ds:[bx], 1
0x0000000000006f8d:  74 1A                je    0x6fa9
0x0000000000006f8f:  BB 01 08             mov   bx, OFFSET _player + PLAYER_T.player_pendingweapon
0x0000000000006f92:  80 3F 0A             cmp   byte ptr ds:[bx], WP_NOCHANGE
0x0000000000006f95:  75 12                jne   0x6fa9
0x0000000000006f97:  BB E8 07             mov   bx, OFFSET _player + PLAYER_T.player_health
0x0000000000006f9a:  83 3F 00             cmp   word ptr ds:[bx], 0
0x0000000000006f9d:  74 0A                je    0x6fa9
0x0000000000006f9f:  BB 2B 08             mov   bx, OFFSET _player + PLAYER_T.player_refire
0x0000000000006fa2:  FE 07                inc   byte ptr ds:[bx]
0x0000000000006fa4:  E8 9B FE             call  P_FireWeapon_
0x0000000000006fa7:  5B                   pop   bx
0x0000000000006fa8:  C3                   ret   
0x0000000000006fa9:  BB 2B 08             mov   bx, OFFSET _player + PLAYER_T.player_refire
0x0000000000006fac:  C6 07 00             mov   byte ptr ds:[bx], 0
0x0000000000006faf:  E8 72 FD             call  A_CheckReload_
0x0000000000006fb2:  5B                   pop   bx
0x0000000000006fb3:  C3                   ret   

ENDP

PROC A_Lower_ NEAR
PUBLIC A_Lower_

0x0000000000006fb4:  53                   push  bx
0x0000000000006fb5:  52                   push  dx
0x0000000000006fb6:  56                   push  si
0x0000000000006fb7:  89 C3                mov   bx, ax
0x0000000000006fb9:  83 47 08 00          add   word ptr ds:[bx + 8], 0
0x0000000000006fbd:  83 57 0A 06          adc   word ptr ds:[bx + 0xa], 6
0x0000000000006fc1:  8B 47 0A             mov   ax, word ptr ds:[bx + 0xa]
0x0000000000006fc4:  3D 80 00             cmp   ax, 0x80
0x0000000000006fc7:  7C 16                jl    0x6fdf
0x0000000000006fc9:  BE ED 07             mov   si, OFFSET _player + PLAYER_T.player_powers + (PW_INVULNERABILITY * 2)
0x0000000000006fcc:  80 3C 01             cmp   byte ptr ds:[si], 1
0x0000000000006fcf:  74 12                je    0x6fe3
0x0000000000006fd1:  BB E8 07             mov   bx, OFFSET _player + PLAYER_T.player_health
0x0000000000006fd4:  8B 07                mov   ax, word ptr ds:[bx]
0x0000000000006fd6:  85 C0                test  ax, ax
0x0000000000006fd8:  75 15                jne   0x6fef
0x0000000000006fda:  31 D2                xor   dx, dx
0x0000000000006fdc:  E8 F5 07             call  P_SetPsprite_
0x0000000000006fdf:  5E                   pop   si
0x0000000000006fe0:  5A                   pop   dx
0x0000000000006fe1:  5B                   pop   bx
0x0000000000006fe2:  C3                   ret   
0x0000000000006fe3:  C7 47 08 00 00       mov   word ptr ds:[bx + 8], 0
0x0000000000006fe8:  C7 47 0A 80 00       mov   word ptr ds:[bx + 0xa], 0x80
0x0000000000006fed:  EB F0                jmp   0x6fdf
0x0000000000006fef:  BB 01 08             mov   bx, OFFSET _player + PLAYER_T.player_pendingweapon
0x0000000000006ff2:  BE 00 08             mov   si, OFFSET _player + PLAYER_T.player_readyweapon
0x0000000000006ff5:  8A 1F                mov   bl, byte ptr ds:[bx]
0x0000000000006ff7:  88 1C                mov   byte ptr ds:[si], bl
0x0000000000006ff9:  E8 D4 FC             call  P_BringUpWeapon_
0x0000000000006ffc:  5E                   pop   si
0x0000000000006ffd:  5A                   pop   dx
0x0000000000006ffe:  5B                   pop   bx
0x0000000000006fff:  C3                   ret   

ENDP

PROC A_Raise_ NEAR
PUBLIC A_Raise_

0x0000000000007000:  53                   push  bx
0x0000000000007001:  52                   push  dx
0x0000000000007002:  89 C3                mov   bx, ax
0x0000000000007004:  83 47 08 00          add   word ptr ds:[bx + 8], 0
0x0000000000007008:  83 57 0A FA          adc   word ptr ds:[bx + 0xa], -6
0x000000000000700c:  8B 47 0A             mov   ax, word ptr ds:[bx + 0xa]
0x000000000000700f:  3D 20 00             cmp   ax, WEAPONTOP_HIGH
0x0000000000007012:  7F 08                jg    0x701c
0x0000000000007014:  75 09                jne   0x701f
0x0000000000007016:  83 7F 08 00          cmp   word ptr ds:[bx + 8], 0
0x000000000000701a:  76 03                jbe   0x701f
0x000000000000701c:  5A                   pop   dx
0x000000000000701d:  5B                   pop   bx
0x000000000000701e:  C3                   ret   
0x000000000000701f:  C7 47 08 00 00       mov   word ptr ds:[bx + 8], WEAPONTOP_LOW
0x0000000000007024:  C7 47 0A 20 00       mov   word ptr ds:[bx + 0xa], WEAPONTOP_HIGH
0x0000000000007029:  BB 00 08             mov   bx, OFFSET _player + PLAYER_T.player_readyweapon
0x000000000000702c:  8A 1F                mov   bl, byte ptr ds:[bx]
0x000000000000702e:  30 FF                xor   bh, bh
0x0000000000007030:  6B DB 0B             imul  bx, bx, SIZEOF_MOBJINFO_T  ; todo x86-16
0x0000000000007033:  31 C0                xor   ax, ax
0x0000000000007035:  8B 97 13 0E          mov   dx, word ptr ds:[bx + OFFSET _weaponinfo + WEAPONINFO_T.weaponinfo_readystate]
0x0000000000007039:  E8 98 07             call  P_SetPsprite_
0x000000000000703c:  5A                   pop   dx
0x000000000000703d:  5B                   pop   bx
0x000000000000703e:  C3                   ret   


ENDP

PROC A_GunFlash_ NEAR
PUBLIC A_GunFlash_

0x0000000000007040:  53                   push  bx
0x0000000000007041:  52                   push  dx
0x0000000000007042:  BB EC 06             mov   bx, OFFSET _playerMobj
0x0000000000007045:  BA 9B 00             mov   dx, S_PLAY_ATK2
0x0000000000007048:  8B 07                mov   ax, word ptr ds:[bx]
0x000000000000704a:  BB 00 08             mov   bx, OFFSET _player + PLAYER_T.player_readyweapon
0x000000000000704d:  0E                   push  cs
0x000000000000704e:  3E E8 DA 2B          call  P_SetMobjState_
0x0000000000007052:  8A 07                mov   al, byte ptr ds:[bx]
0x0000000000007054:  30 E4                xor   ah, ah
0x0000000000007056:  6B D8 0B             imul  bx, ax, SIZEOF_MOBJINFO_T  ; todo x86-16
0x0000000000007059:  B8 01 00             mov   ax, 1
0x000000000000705c:  8B 97 17 0E          mov   dx, word ptr ds:[bx + OFFSET _weaponinfo + WEAPONINFO_T.weaponinfo_flashstate]
0x0000000000007060:  E8 71 07             call  P_SetPsprite_
0x0000000000007063:  5A                   pop   dx
0x0000000000007064:  5B                   pop   bx
0x0000000000007065:  C3                   ret   

ENDP

PROC A_Punch_ NEAR
PUBLIC A_Punch_

0x0000000000007066:  53                   push  bx
0x0000000000007067:  51                   push  cx
0x0000000000007068:  52                   push  dx
0x0000000000007069:  56                   push  si
0x000000000000706a:  57                   push  di
0x000000000000706b:  E8 82 25             call  P_Random_
0x000000000000706e:  30 E4                xor   ah, ah
0x0000000000007070:  BB 0A 00             mov   bx, 0xa
0x0000000000007073:  99                   cwd   
0x0000000000007074:  F7 FB                idiv  bx
0x0000000000007076:  89 D6                mov   si, dx
0x0000000000007078:  01 D6                add   si, dx
0x000000000000707a:  BB F0 07             mov   bx, OFFSET _player + PLAYER_T.player_powers + (PW_STRENGTH * 2)
0x000000000000707d:  83 C6 02             add   si, 2
0x0000000000007080:  83 3F 00             cmp   word ptr ds:[bx], 0
0x0000000000007083:  74 09                je    0x708e
0x0000000000007085:  89 F1                mov   cx, si
0x0000000000007087:  C1 E1 02             shl   cx, 2
0x000000000000708a:  01 CE                add   si, cx
0x000000000000708c:  01 F6                add   si, si
0x000000000000708e:  BB 30 07             mov   bx, OFFSET _playerMobj_pos
0x0000000000007091:  C4 3F                les   di, dword ptr ds:[bx]
0x0000000000007093:  26 8B 4D 10          mov   cx, word ptr es:[di + MOBJ_POS_T.mp_angle+2]
0x0000000000007097:  E8 56 25             call  P_Random_
0x000000000000709a:  88 C3                mov   bl, al
0x000000000000709c:  E8 51 25             call  P_Random_
0x000000000000709f:  30 FF                xor   bh, bh
0x00000000000070a1:  30 E4                xor   ah, ah
0x00000000000070a3:  29 C3                sub   bx, ax
0x00000000000070a5:  89 D8                mov   ax, bx
0x00000000000070a7:  C1 E9 03             shr   cx, 3
0x00000000000070aa:  D1 F8                sar   ax, 1
0x00000000000070ac:  01 C1                add   cx, ax
0x00000000000070ae:  BB EC 06             mov   bx, OFFSET _playerMobj
0x00000000000070b1:  89 CA                mov   dx, cx
0x00000000000070b3:  8B 07                mov   ax, word ptr ds:[bx]
0x00000000000070b5:  BB 40 00             mov   bx, 0x40
0x00000000000070b8:  FF 1E 78 0C          call  dword ptr ds:[_P_AimLineAttack]
0x00000000000070bc:  56                   push  si
0x00000000000070bd:  52                   push  dx
0x00000000000070be:  BB EC 06             mov   bx, OFFSET _playerMobj
0x00000000000070c1:  50                   push  ax
0x00000000000070c2:  89 CA                mov   dx, cx
0x00000000000070c4:  8B 07                mov   ax, word ptr ds:[bx]
0x00000000000070c6:  BB 40 00             mov   bx, 0x40
0x00000000000070c9:  FF 1E 7C 0C          call  dword ptr ds:[_P_LineAttack]
0x00000000000070cd:  BB 12 07             mov   bx, 0x712
0x00000000000070d0:  83 3F 00             cmp   word ptr ds:[bx], 0
0x00000000000070d3:  75 06                jne   0x70db
0x00000000000070d5:  5F                   pop   di
0x00000000000070d6:  5E                   pop   si
0x00000000000070d7:  5A                   pop   dx
0x00000000000070d8:  59                   pop   cx
0x00000000000070d9:  5B                   pop   bx
0x00000000000070da:  C3                   ret   
0x00000000000070db:  BB EC 06             mov   bx, OFFSET _playerMobj
0x00000000000070de:  BA 53 00             mov   dx, SFX_PUNCH
0x00000000000070e1:  8B 07                mov   ax, word ptr ds:[bx]
0x00000000000070e3:  BB 14 07             mov   bx, 0x714
0x00000000000070e6:  0E                   push  cs
0x00000000000070e7:  E8 66 94             call  S_StartSound_
0x00000000000070ea:  90                   nop   
0x00000000000070eb:  C4 37                les   si, dword ptr ds:[bx]
0x00000000000070ed:  26 FF 74 06          push  word ptr es:[si + 6]
0x00000000000070f1:  26 FF 74 04          push  word ptr es:[si + 4]
0x00000000000070f5:  26 FF 74 02          push  word ptr es:[si + 2]
0x00000000000070f9:  BB 30 07             mov   bx, OFFSET _playerMobj_pos
0x00000000000070fc:  26 FF 34             push  word ptr es:[si]
0x00000000000070ff:  C4 37                les   si, dword ptr ds:[bx]
0x0000000000007101:  26 8B 44 04          mov   ax, word ptr es:[si + 4]
0x0000000000007105:  26 8B 4C 06          mov   cx, word ptr es:[si + 6]
0x0000000000007109:  89 DE                mov   si, bx
0x000000000000710b:  8B 1F                mov   bx, word ptr ds:[bx]
0x000000000000710d:  8E 44 02             mov   es, word ptr ds:[si + 2]
0x0000000000007110:  26 8B 17             mov   dx, word ptr es:[bx]
0x0000000000007113:  26 8B 77 02          mov   si, word ptr es:[bx + 2]
0x0000000000007117:  89 C3                mov   bx, ax
0x0000000000007119:  89 D0                mov   ax, dx
0x000000000000711b:  89 F2                mov   dx, si
0x000000000000711d:  0E                   push  cs
0x000000000000711e:  3E E8 45 3C          call  R_PointToAngle2_
0x0000000000007122:  BB 30 07             mov   bx, OFFSET _playerMobj_pos
0x0000000000007125:  C4 37                les   si, dword ptr ds:[bx]
0x0000000000007127:  26 89 44 0E          mov   word ptr es:[si + MOBJ_POS_T.mp_angle+0], ax
0x000000000000712b:  26 89 54 10          mov   word ptr es:[si + MOBJ_POS_T.mp_angle+2], dx
0x000000000000712f:  5F                   pop   di
0x0000000000007130:  5E                   pop   si
0x0000000000007131:  5A                   pop   dx
0x0000000000007132:  59                   pop   cx
0x0000000000007133:  5B                   pop   bx
0x0000000000007134:  C3                   ret   


ENDP

PROC A_Saw_ NEAR
PUBLIC A_Saw_

0x0000000000007136:  53                   push  bx
0x0000000000007137:  51                   push  cx
0x0000000000007138:  52                   push  dx
0x0000000000007139:  56                   push  si
0x000000000000713a:  57                   push  di
0x000000000000713b:  E8 B2 24             call  P_Random_
0x000000000000713e:  30 E4                xor   ah, ah
0x0000000000007140:  BB 0A 00             mov   bx, 0xa
0x0000000000007143:  99                   cwd   
0x0000000000007144:  F7 FB                idiv  bx
0x0000000000007146:  BB 30 07             mov   bx, OFFSET _playerMobj_pos
0x0000000000007149:  89 D7                mov   di, dx
0x000000000000714b:  C4 37                les   si, dword ptr ds:[bx]
0x000000000000714d:  01 D7                add   di, dx
0x000000000000714f:  26 8B 4C 10          mov   cx, word ptr es:[si + MOBJ_POS_T.mp_angle+2]
0x0000000000007153:  E8 9A 24             call  P_Random_
0x0000000000007156:  88 C2                mov   dl, al
0x0000000000007158:  E8 95 24             call  P_Random_
0x000000000000715b:  30 F6                xor   dh, dh
0x000000000000715d:  30 E4                xor   ah, ah
0x000000000000715f:  29 C2                sub   dx, ax
0x0000000000007161:  89 D0                mov   ax, dx
0x0000000000007163:  C1 E9 03             shr   cx, 3
0x0000000000007166:  D1 F8                sar   ax, 1
0x0000000000007168:  01 C1                add   cx, ax
0x000000000000716a:  BB EC 06             mov   bx, OFFSET _playerMobj
0x000000000000716d:  80 E5 1F             and   ch, 0x1f
0x0000000000007170:  8B 07                mov   ax, word ptr ds:[bx]
0x0000000000007172:  BB 41 00             mov   bx, 0x41
0x0000000000007175:  89 CA                mov   dx, cx
0x0000000000007177:  83 C7 02             add   di, 2
0x000000000000717a:  FF 1E 78 0C          call  dword ptr ds:[_P_AimLineAttack]
0x000000000000717e:  57                   push  di
0x000000000000717f:  52                   push  dx
0x0000000000007180:  BB EC 06             mov   bx, OFFSET _playerMobj
0x0000000000007183:  50                   push  ax
0x0000000000007184:  89 CA                mov   dx, cx
0x0000000000007186:  8B 07                mov   ax, word ptr ds:[bx]
0x0000000000007188:  BB 41 00             mov   bx, 0x41
0x000000000000718b:  FF 1E 7C 0C          call  dword ptr ds:[_P_LineAttack]
0x000000000000718f:  BB 12 07             mov   bx, 0x712
0x0000000000007192:  83 3F 00             cmp   word ptr ds:[bx], 0
0x0000000000007195:  75 03                jne   0x719a
0x0000000000007197:  E9 AC 00             jmp   0x7246
0x000000000000719a:  BB EC 06             mov   bx, OFFSET _playerMobj
0x000000000000719d:  BA 0D 00             mov   dx, SFX_SAWHIT
0x00000000000071a0:  8B 07                mov   ax, word ptr ds:[bx]
0x00000000000071a2:  BE 14 07             mov   si, 0x714
0x00000000000071a5:  0E                   push  cs
0x00000000000071a6:  3E E8 A6 93          call  S_StartSound_
0x00000000000071aa:  C4 1C                les   bx, dword ptr ds:[si]
0x00000000000071ac:  26 FF 77 06          push  word ptr es:[bx + 6]
0x00000000000071b0:  26 FF 77 04          push  word ptr es:[bx + 4]
0x00000000000071b4:  89 F3                mov   bx, si
0x00000000000071b6:  8B 34                mov   si, word ptr ds:[si]
0x00000000000071b8:  8E 47 02             mov   es, word ptr ds:[bx + 2]
0x00000000000071bb:  26 FF 74 02          push  word ptr es:[si + 2]
0x00000000000071bf:  26 FF 34             push  word ptr es:[si]
0x00000000000071c2:  BE 30 07             mov   si, OFFSET _playerMobj_pos
0x00000000000071c5:  C4 1C                les   bx, dword ptr ds:[si]
0x00000000000071c7:  26 8B 47 04          mov   ax, word ptr es:[bx + 4]
0x00000000000071cb:  26 8B 4F 06          mov   cx, word ptr es:[bx + 6]
0x00000000000071cf:  89 F3                mov   bx, si
0x00000000000071d1:  8B 34                mov   si, word ptr ds:[si]
0x00000000000071d3:  8E 47 02             mov   es, word ptr ds:[bx + 2]
0x00000000000071d6:  89 C3                mov   bx, ax
0x00000000000071d8:  26 8B 3C             mov   di, word ptr es:[si]
0x00000000000071db:  26 8B 54 02          mov   dx, word ptr es:[si + 2]
0x00000000000071df:  89 F8                mov   ax, di
0x00000000000071e1:  BE 30 07             mov   si, OFFSET _playerMobj_pos
0x00000000000071e4:  0E                   push  cs
0x00000000000071e5:  E8 7F 3B             call  R_PointToAngle2_
0x00000000000071e8:  90                   nop   
0x00000000000071e9:  C4 1C                les   bx, dword ptr ds:[si]
0x00000000000071eb:  89 C1                mov   cx, ax
0x00000000000071ed:  26 2B 4F 0E          sub   cx, word ptr es:[bx + MOBJ_POS_T.mp_angle+0]
0x00000000000071f1:  89 D6                mov   si, dx
0x00000000000071f3:  26 1B 77 10          sbb   si, word ptr es:[bx + MOBJ_POS_T.mp_angle+2]
0x00000000000071f7:  81 FE 00 80          cmp   si, 0x8000
0x00000000000071fb:  77 06                ja    0x7203
0x00000000000071fd:  75 69                jne   0x7268
0x00000000000071ff:  85 C9                test  cx, cx
0x0000000000007201:  76 65                jbe   0x7268
0x0000000000007203:  BB 30 07             mov   bx, OFFSET _playerMobj_pos
0x0000000000007206:  C4 37                les   si, dword ptr ds:[bx]
0x0000000000007208:  89 C1                mov   cx, ax
0x000000000000720a:  26 2B 4C 0E          sub   cx, word ptr es:[si + MOBJ_POS_T.mp_angle+0]
0x000000000000720e:  89 D3                mov   bx, dx
0x0000000000007210:  26 1B 5C 10          sbb   bx, word ptr es:[si + MOBJ_POS_T.mp_angle+2]
0x0000000000007214:  81 FB 99 09          cmp   bx, 0x999
0x0000000000007218:  72 08                jb    0x7222
0x000000000000721a:  75 39                jne   0x7255
0x000000000000721c:  81 F9 99 99          cmp   cx, 0x9999
0x0000000000007220:  73 33                jae   0x7255
0x0000000000007222:  BE 30 07             mov   si, OFFSET _playerMobj_pos
0x0000000000007225:  C4 1C                les   bx, dword ptr ds:[si]
0x0000000000007227:  05 C3 30             add   ax, 0x30c3
0x000000000000722a:  81 D2 0C 03          adc   dx, 0x30c
0x000000000000722e:  26 89 47 0E          mov   word ptr es:[bx + MOBJ_POS_T.mp_angle+0], ax
0x0000000000007232:  26 89 57 10          mov   word ptr es:[bx + MOBJ_POS_T.mp_angle+2], dx
0x0000000000007236:  BB 30 07             mov   bx, OFFSET _playerMobj_pos
0x0000000000007239:  C4 37                les   si, dword ptr ds:[bx]
0x000000000000723b:  26 80 4C 14 80       or    byte ptr es:[si + 0x14], 0x80
0x0000000000007240:  5F                   pop   di
0x0000000000007241:  5E                   pop   si
0x0000000000007242:  5A                   pop   dx
0x0000000000007243:  59                   pop   cx
0x0000000000007244:  5B                   pop   bx
0x0000000000007245:  C3                   ret   
0x0000000000007246:  BB EC 06             mov   bx, OFFSET _playerMobj
0x0000000000007249:  BA 0C 00             mov   dx, SFX_SAWFUL
0x000000000000724c:  8B 07                mov   ax, word ptr ds:[bx]
0x000000000000724e:  0E                   push  cs
0x000000000000724f:  E8 FE 92             call  S_StartSound_
0x0000000000007252:  90                   nop   
0x0000000000007253:  EB EB                jmp   0x7240
0x0000000000007255:  BE 30 07             mov   si, OFFSET _playerMobj_pos
0x0000000000007258:  C4 1C                les   bx, dword ptr ds:[si]
0x000000000000725a:  26 81 47 0E CD CC    add   word ptr es:[bx + MOBJ_POS_T.mp_angle+0], 0xcccd
0x0000000000007260:  26 81 57 10 CC FC    adc   word ptr es:[bx + MOBJ_POS_T.mp_angle+2], 0xfccc
0x0000000000007266:  EB CE                jmp   0x7236
0x0000000000007268:  BB 30 07             mov   bx, OFFSET _playerMobj_pos
0x000000000000726b:  C4 37                les   si, dword ptr ds:[bx]
0x000000000000726d:  89 C1                mov   cx, ax
0x000000000000726f:  26 2B 4C 0E          sub   cx, word ptr es:[si + MOBJ_POS_T.mp_angle+0]
0x0000000000007273:  89 D3                mov   bx, dx
0x0000000000007275:  26 1B 5C 10          sbb   bx, word ptr es:[si + MOBJ_POS_T.mp_angle+2]
0x0000000000007279:  81 FB 33 03          cmp   bx, 0x333
0x000000000000727d:  77 08                ja    0x7287
0x000000000000727f:  75 1C                jne   0x729d
0x0000000000007281:  81 F9 33 33          cmp   cx, 0x3333
0x0000000000007285:  76 16                jbe   0x729d
0x0000000000007287:  BB 30 07             mov   bx, OFFSET _playerMobj_pos
0x000000000000728a:  C4 37                les   si, dword ptr ds:[bx]
0x000000000000728c:  05 3D CF             add   ax, 0xcf3d
0x000000000000728f:  81 D2 F3 FC          adc   dx, 0xfcf3
0x0000000000007293:  26 89 44 0E          mov   word ptr es:[si + MOBJ_POS_T.mp_angle+0], ax
0x0000000000007297:  26 89 54 10          mov   word ptr es:[si + MOBJ_POS_T.mp_angle+2], dx
0x000000000000729b:  EB 99                jmp   0x7236
0x000000000000729d:  BE 30 07             mov   si, OFFSET _playerMobj_pos
0x00000000000072a0:  C4 1C                les   bx, dword ptr ds:[si]
0x00000000000072a2:  26 81 47 0E 33 33    add   word ptr es:[bx + MOBJ_POS_T.mp_angle+0], 0x3333
0x00000000000072a8:  26 81 57 10 33 03    adc   word ptr es:[bx + MOBJ_POS_T.mp_angle+2], 0x333
0x00000000000072ae:  EB 86                jmp   0x7236

ENDP

PROC A_FireMissile_ NEAR
PUBLIC A_FireMissile_


0x00000000000072b0:  53                   push  bx
0x00000000000072b1:  BB 00 08             mov   bx, OFFSET _player + PLAYER_T.player_readyweapon
0x00000000000072b4:  8A 1F                mov   bl, byte ptr ds:[bx]
0x00000000000072b6:  30 FF                xor   bh, bh
0x00000000000072b8:  6B DB 0B             imul  bx, bx, SIZEOF_MOBJINFO_T  ; todo x86-16
0x00000000000072bb:  8A 9F 0E 0E          mov   bl, byte ptr ds:[bx + _weaponinfo]
0x00000000000072bf:  30 FF                xor   bh, bh
0x00000000000072c1:  01 DB                add   bx, bx
0x00000000000072c3:  B8 21 00             mov   ax, 0x21
0x00000000000072c6:  FF 8F 0C 08          dec   word ptr ds:[bx + OFFSET _player + PLAYER_T.player_ammo]
0x00000000000072ca:  FF 1E 8C 0C          call  dword ptr ds:[_P_SpawnPlayerMissile]
0x00000000000072ce:  5B                   pop   bx
0x00000000000072cf:  C3                   ret   

ENDP

PROC A_FireBFG_ NEAR
PUBLIC A_FireBFG_

0x00000000000072d0:  53                   push  bx
0x00000000000072d1:  BB 00 08             mov   bx, OFFSET _player + PLAYER_T.player_readyweapon
0x00000000000072d4:  8A 1F                mov   bl, byte ptr ds:[bx]
0x00000000000072d6:  30 FF                xor   bh, bh
0x00000000000072d8:  6B DB 0B             imul  bx, bx, SIZEOF_MOBJINFO_T  ; todo x86-16
0x00000000000072db:  8A 9F 0E 0E          mov   bl, byte ptr ds:[bx + _weaponinfo]
0x00000000000072df:  30 FF                xor   bh, bh
0x00000000000072e1:  01 DB                add   bx, bx
0x00000000000072e3:  B8 23 00             mov   ax, 0x23
0x00000000000072e6:  83 AF 0C 08 28       sub   word ptr ds:[bx + OFFSET _player + PLAYER_T.player_ammo], 0x28
0x00000000000072eb:  FF 1E 8C 0C          call  dword ptr ds:[_P_SpawnPlayerMissile]
0x00000000000072ef:  5B                   pop   bx
0x00000000000072f0:  C3                   ret   


ENDP

PROC A_FirePlasma_ NEAR
PUBLIC A_FirePlasma_

0x00000000000072f2:  53                   push  bx
0x00000000000072f3:  52                   push  dx
0x00000000000072f4:  56                   push  si
0x00000000000072f5:  BB 00 08             mov   bx, OFFSET _player + PLAYER_T.player_readyweapon
0x00000000000072f8:  8A 1F                mov   bl, byte ptr ds:[bx]
0x00000000000072fa:  30 FF                xor   bh, bh
0x00000000000072fc:  6B DB 0B             imul  bx, bx, SIZEOF_MOBJINFO_T  ; todo x86-16
0x00000000000072ff:  8A 9F 0E 0E          mov   bl, byte ptr ds:[bx + _weaponinfo]
0x0000000000007303:  30 FF                xor   bh, bh
0x0000000000007305:  01 DB                add   bx, bx
0x0000000000007307:  BE 00 08             mov   si, OFFSET _player + PLAYER_T.player_readyweapon
0x000000000000730a:  FF 8F 0C 08          dec   word ptr ds:[bx + OFFSET _player + PLAYER_T.player_ammo]
0x000000000000730e:  8A 1C                mov   bl, byte ptr ds:[si]
0x0000000000007310:  30 FF                xor   bh, bh
0x0000000000007312:  6B F3 0B             imul  si, bx, SIZEOF_MOBJINFO_T  ; todo x86-16
0x0000000000007315:  E8 D8 22             call  P_Random_
0x0000000000007318:  88 C3                mov   bl, al
0x000000000000731a:  8B 94 17 0E          mov   dx, word ptr ds:[si + OFFSET _weaponinfo + WEAPONINFO_T.weaponinfo_flashstate]
0x000000000000731e:  80 E3 01             and   bl, 1
0x0000000000007321:  B8 01 00             mov   ax, 1
0x0000000000007324:  01 DA                add   dx, bx
0x0000000000007326:  E8 AB 04             call  P_SetPsprite_
0x0000000000007329:  B8 22 00             mov   ax, 0x22
0x000000000000732c:  FF 1E 8C 0C          call  dword ptr ds:[_P_SpawnPlayerMissile]
0x0000000000007330:  5E                   pop   si
0x0000000000007331:  5A                   pop   dx
0x0000000000007332:  5B                   pop   bx
0x0000000000007333:  C3                   ret   

ENDP

PROC P_BulletSlope_ NEAR
PUBLIC P_BulletSlope_

0x0000000000007334:  53                   push  bx
0x0000000000007335:  51                   push  cx
0x0000000000007336:  52                   push  dx
0x0000000000007337:  56                   push  si
0x0000000000007338:  BB 30 07             mov   bx, OFFSET _playerMobj_pos
0x000000000000733b:  C4 37                les   si, dword ptr ds:[bx]
0x000000000000733d:  26 8B 4C 10          mov   cx, word ptr es:[si + MOBJ_POS_T.mp_angle+2]
0x0000000000007341:  BB EC 06             mov   bx, OFFSET _playerMobj
0x0000000000007344:  C1 E9 03             shr   cx, 3
0x0000000000007347:  8B 07                mov   ax, word ptr ds:[bx]
0x0000000000007349:  BB 00 04             mov   bx, 0x400
0x000000000000734c:  89 CA                mov   dx, cx
0x000000000000734e:  FF 1E 78 0C          call  dword ptr ds:[_P_AimLineAttack]
0x0000000000007352:  BB 12 07             mov   bx, 0x712
0x0000000000007355:  A3 24 1D             mov   word ptr [0x1d24], ax
0x0000000000007358:  89 16 26 1D          mov   word ptr [0x1d26], dx
0x000000000000735c:  83 3F 00             cmp   word ptr ds:[bx], 0
0x000000000000735f:  74 05                je    0x7366
0x0000000000007361:  5E                   pop   si
0x0000000000007362:  5A                   pop   dx
0x0000000000007363:  59                   pop   cx
0x0000000000007364:  5B                   pop   bx
0x0000000000007365:  C3                   ret   
0x0000000000007366:  81 C1 80 00          add   cx, 0x80
0x000000000000736a:  BB EC 06             mov   bx, OFFSET _playerMobj
0x000000000000736d:  80 E5 1F             and   ch, 0x1f
0x0000000000007370:  8B 07                mov   ax, word ptr ds:[bx]
0x0000000000007372:  BB 00 04             mov   bx, 0x400
0x0000000000007375:  89 CA                mov   dx, cx
0x0000000000007377:  FF 1E 78 0C          call  dword ptr ds:[_P_AimLineAttack]
0x000000000000737b:  BB 12 07             mov   bx, 0x712
0x000000000000737e:  A3 24 1D             mov   word ptr [0x1d24], ax
0x0000000000007381:  89 16 26 1D          mov   word ptr [0x1d26], dx
0x0000000000007385:  83 3F 00             cmp   word ptr ds:[bx], 0
0x0000000000007388:  75 D7                jne   0x7361
0x000000000000738a:  81 E9 00 01          sub   cx, 0x100
0x000000000000738e:  BB EC 06             mov   bx, OFFSET _playerMobj
0x0000000000007391:  80 E5 1F             and   ch, 0x1f
0x0000000000007394:  8B 07                mov   ax, word ptr ds:[bx]
0x0000000000007396:  BB 00 04             mov   bx, 0x400
0x0000000000007399:  89 CA                mov   dx, cx
0x000000000000739b:  FF 1E 78 0C          call  dword ptr ds:[_P_AimLineAttack]
0x000000000000739f:  A3 24 1D             mov   word ptr [0x1d24], ax
0x00000000000073a2:  89 16 26 1D          mov   word ptr [0x1d26], dx
0x00000000000073a6:  5E                   pop   si
0x00000000000073a7:  5A                   pop   dx
0x00000000000073a8:  59                   pop   cx
0x00000000000073a9:  5B                   pop   bx
0x00000000000073aa:  C3                   ret   

ENDP

PROC P_GunShot_ NEAR
PUBLIC P_GunShot_

0x00000000000073ac:  53                   push  bx
0x00000000000073ad:  51                   push  cx
0x00000000000073ae:  52                   push  dx
0x00000000000073af:  56                   push  si
0x00000000000073b0:  57                   push  di
0x00000000000073b1:  88 C1                mov   cl, al
0x00000000000073b3:  E8 3A 22             call  P_Random_
0x00000000000073b6:  30 E4                xor   ah, ah
0x00000000000073b8:  BB 03 00             mov   bx, 3
0x00000000000073bb:  99                   cwd   
0x00000000000073bc:  F7 FB                idiv  bx
0x00000000000073be:  42                   inc   dx
0x00000000000073bf:  BB 30 07             mov   bx, OFFSET _playerMobj_pos
0x00000000000073c2:  89 D7                mov   di, dx
0x00000000000073c4:  8B 37                mov   si, word ptr ds:[bx]
0x00000000000073c6:  C1 E7 02             shl   di, 2
0x00000000000073c9:  8E 47 02             mov   es, word ptr ds:[bx + 2]
0x00000000000073cc:  01 D7                add   di, dx
0x00000000000073ce:  26 8B 54 10          mov   dx, word ptr es:[si + MOBJ_POS_T.mp_angle+2]
0x00000000000073d2:  C1 EA 03             shr   dx, 3
0x00000000000073d5:  84 C9                test  cl, cl
0x00000000000073d7:  74 1B                je    0x73f4
0x00000000000073d9:  57                   push  di
0x00000000000073da:  BB EC 06             mov   bx, OFFSET _playerMobj
0x00000000000073dd:  FF 36 26 1D          push  word ptr [0x1d26]
0x00000000000073e1:  8B 07                mov   ax, word ptr ds:[bx]
0x00000000000073e3:  FF 36 24 1D          push  word ptr [0x1d24]
0x00000000000073e7:  BB 00 08             mov   bx, OFFSET _player + PLAYER_T.player_readyweapon
0x00000000000073ea:  FF 1E 7C 0C          call  dword ptr ds:[_P_LineAttack]
0x00000000000073ee:  5F                   pop   di
0x00000000000073ef:  5E                   pop   si
0x00000000000073f0:  5A                   pop   dx
0x00000000000073f1:  59                   pop   cx
0x00000000000073f2:  5B                   pop   bx
0x00000000000073f3:  C3                   ret   
0x00000000000073f4:  E8 F9 21             call  P_Random_
0x00000000000073f7:  88 C3                mov   bl, al
0x00000000000073f9:  E8 F4 21             call  P_Random_
0x00000000000073fc:  30 FF                xor   bh, bh
0x00000000000073fe:  30 E4                xor   ah, ah
0x0000000000007400:  29 C3                sub   bx, ax
0x0000000000007402:  D1 FB                sar   bx, 1
0x0000000000007404:  01 DA                add   dx, bx
0x0000000000007406:  80 E6 1F             and   dh, 0x1f
0x0000000000007409:  EB CE                jmp   0x73d9

ENDP

PROC A_FirePistol_ NEAR
PUBLIC A_FirePistol_

0x000000000000740c:  53                   push  bx
0x000000000000740d:  52                   push  dx
0x000000000000740e:  56                   push  si
0x000000000000740f:  BB EC 06             mov   bx, OFFSET _playerMobj
0x0000000000007412:  BA 01 00             mov   dx, SFX_PISTOL
0x0000000000007415:  8B 07                mov   ax, word ptr ds:[bx]
0x0000000000007417:  0E                   push  cs
0x0000000000007418:  3E E8 34 91          call  S_StartSound_
0x000000000000741c:  BA 9B 00             mov   dx, S_PLAY_ATK2
0x000000000000741f:  8B 07                mov   ax, word ptr ds:[bx]
0x0000000000007421:  BB 00 08             mov   bx, OFFSET _player + PLAYER_T.player_readyweapon
0x0000000000007424:  0E                   push  cs
0x0000000000007425:  E8 04 28             call  P_SetMobjState_
0x0000000000007428:  90                   nop   
0x0000000000007429:  8A 07                mov   al, byte ptr ds:[bx]
0x000000000000742b:  30 E4                xor   ah, ah
0x000000000000742d:  6B D8 0B             imul  bx, ax, SIZEOF_MOBJINFO_T  ; todo x86-16
0x0000000000007430:  8A 87 0E 0E          mov   al, byte ptr ds:[bx + _weaponinfo]
0x0000000000007434:  89 C3                mov   bx, ax
0x0000000000007436:  01 C3                add   bx, ax
0x0000000000007438:  BE 00 08             mov   si, OFFSET _player + PLAYER_T.player_readyweapon
0x000000000000743b:  FF 8F 0C 08          dec   word ptr ds:[bx + OFFSET _player + PLAYER_T.player_ammo]
0x000000000000743f:  8A 04                mov   al, byte ptr ds:[si]
0x0000000000007441:  6B D8 0B             imul  bx, ax, SIZEOF_MOBJINFO_T  ; todo x86-16
0x0000000000007444:  B8 01 00             mov   ax, 1
0x0000000000007447:  8B 97 17 0E          mov   dx, word ptr ds:[bx + OFFSET _weaponinfo + WEAPONINFO_T.weaponinfo_flashstate]
0x000000000000744b:  BB 2B 08             mov   bx, OFFSET _player + PLAYER_T.player_refire
0x000000000000744e:  E8 83 03             call  P_SetPsprite_
0x0000000000007451:  E8 E0 FE             call  P_BulletSlope_
0x0000000000007454:  80 3F 00             cmp   byte ptr ds:[bx], 0
0x0000000000007457:  75 0A                jne   0x7463
0x0000000000007459:  B0 01                mov   al, 1
0x000000000000745b:  98                   cbw  
0x000000000000745c:  E8 4D FF             call  P_GunShot_
0x000000000000745f:  5E                   pop   si
0x0000000000007460:  5A                   pop   dx
0x0000000000007461:  5B                   pop   bx
0x0000000000007462:  C3                   ret   
0x0000000000007463:  30 C0                xor   al, al
0x0000000000007465:  98                   cbw  
0x0000000000007466:  E8 43 FF             call  P_GunShot_
0x0000000000007469:  5E                   pop   si
0x000000000000746a:  5A                   pop   dx
0x000000000000746b:  5B                   pop   bx
0x000000000000746c:  C3                   ret   

ENDP

PROC A_FireShotgun_ NEAR
PUBLIC A_FireShotgun_

0x000000000000746e:  53                   push  bx
0x000000000000746f:  52                   push  dx
0x0000000000007470:  56                   push  si
0x0000000000007471:  BB EC 06             mov   bx, OFFSET _playerMobj
0x0000000000007474:  BA 02 00             mov   dx, SFX_SHOTGN
0x0000000000007477:  8B 07                mov   ax, word ptr ds:[bx]
0x0000000000007479:  0E                   push  cs
0x000000000000747a:  3E E8 D2 90          call  S_StartSound_
0x000000000000747e:  BA 9B 00             mov   dx, S_PLAY_ATK2
0x0000000000007481:  8B 07                mov   ax, word ptr ds:[bx]
0x0000000000007483:  BB 00 08             mov   bx, OFFSET _player + PLAYER_T.player_readyweapon
0x0000000000007486:  0E                   push  cs
0x0000000000007487:  E8 A2 27             call  P_SetMobjState_
0x000000000000748a:  90                   nop   
0x000000000000748b:  8A 1F                mov   bl, byte ptr ds:[bx]
0x000000000000748d:  30 FF                xor   bh, bh
0x000000000000748f:  6B DB 0B             imul  bx, bx, SIZEOF_MOBJINFO_T  ; todo x86-16
0x0000000000007492:  8A 9F 0E 0E          mov   bl, byte ptr ds:[bx + _weaponinfo]
0x0000000000007496:  30 FF                xor   bh, bh
0x0000000000007498:  01 DB                add   bx, bx
0x000000000000749a:  BE 00 08             mov   si, OFFSET _player + PLAYER_T.player_readyweapon
0x000000000000749d:  FF 8F 0C 08          dec   word ptr ds:[bx + OFFSET _player + PLAYER_T.player_ammo]
0x00000000000074a1:  8A 1C                mov   bl, byte ptr ds:[si]
0x00000000000074a3:  30 FF                xor   bh, bh
0x00000000000074a5:  6B DB 0B             imul  bx, bx, SIZEOF_MOBJINFO_T  ; todo x86-16
0x00000000000074a8:  B8 01 00             mov   ax, 1
0x00000000000074ab:  8B 97 17 0E          mov   dx, word ptr ds:[bx + OFFSET _weaponinfo + WEAPONINFO_T.weaponinfo_flashstate]
0x00000000000074af:  E8 22 03             call  P_SetPsprite_
0x00000000000074b2:  E8 7F FE             call  P_BulletSlope_
0x00000000000074b5:  30 D2                xor   dl, dl
0x00000000000074b7:  31 C0                xor   ax, ax
0x00000000000074b9:  FE C2                inc   dl
0x00000000000074bb:  E8 EE FE             call  P_GunShot_
0x00000000000074be:  80 FA 07             cmp   dl, 7
0x00000000000074c1:  7C F4                jl    0x74b7
0x00000000000074c3:  5E                   pop   si
0x00000000000074c4:  5A                   pop   dx
0x00000000000074c5:  5B                   pop   bx
0x00000000000074c6:  C3                   ret   

ENDP

PROC A_FireShotgun2_ NEAR
PUBLIC A_FireShotgun2_

0x00000000000074c8:  53                   push  bx
0x00000000000074c9:  51                   push  cx
0x00000000000074ca:  52                   push  dx
0x00000000000074cb:  56                   push  si
0x00000000000074cc:  57                   push  di
0x00000000000074cd:  55                   push  bp
0x00000000000074ce:  89 E5                mov   bp, sp
0x00000000000074d0:  83 EC 02             sub   sp, 2
0x00000000000074d3:  BB EC 06             mov   bx, OFFSET _playerMobj
0x00000000000074d6:  BA 04 00             mov   dx, SFX_DSHTGN
0x00000000000074d9:  8B 07                mov   ax, word ptr ds:[bx]
0x00000000000074db:  0E                   push  cs
0x00000000000074dc:  3E E8 70 90          call  S_StartSound_
0x00000000000074e0:  BA 9B 00             mov   dx, S_PLAY_ATK2
0x00000000000074e3:  8B 07                mov   ax, word ptr ds:[bx]
0x00000000000074e5:  BB 00 08             mov   bx, OFFSET _player + PLAYER_T.player_readyweapon
0x00000000000074e8:  0E                   push  cs
0x00000000000074e9:  E8 40 27             call  P_SetMobjState_
0x00000000000074ec:  90                   nop   
0x00000000000074ed:  8A 07                mov   al, byte ptr ds:[bx]
0x00000000000074ef:  30 E4                xor   ah, ah
0x00000000000074f1:  6B D8 0B             imul  bx, ax, SIZEOF_MOBJINFO_T  ; todo x86-16
0x00000000000074f4:  8A 9F 0E 0E          mov   bl, byte ptr ds:[bx + _weaponinfo]
0x00000000000074f8:  30 FF                xor   bh, bh
0x00000000000074fa:  01 DB                add   bx, bx
0x00000000000074fc:  BE 00 08             mov   si, OFFSET _player + PLAYER_T.player_readyweapon
0x00000000000074ff:  83 AF 0C 08 02       sub   word ptr ds:[bx + OFFSET _player + PLAYER_T.player_ammo], 2
0x0000000000007504:  8A 04                mov   al, byte ptr ds:[si]
0x0000000000007506:  6B D8 0B             imul  bx, ax, SIZEOF_MOBJINFO_T  ; todo x86-16
0x0000000000007509:  C6 46 FE 00          mov   byte ptr [bp - 2], 0
0x000000000000750d:  B8 01 00             mov   ax, 1
0x0000000000007510:  8B 97 17 0E          mov   dx, word ptr ds:[bx + OFFSET _weaponinfo + WEAPONINFO_T.weaponinfo_flashstate]
0x0000000000007514:  BF 30 07             mov   di, OFFSET _playerMobj_pos
0x0000000000007517:  E8 BA 02             call  P_SetPsprite_
0x000000000000751a:  E8 17 FE             call  P_BulletSlope_
0x000000000000751d:  FC                   cld   
0x000000000000751e:  E8 CF 20             call  P_Random_
0x0000000000007521:  30 E4                xor   ah, ah
0x0000000000007523:  BB 03 00             mov   bx, 3
0x0000000000007526:  99                   cwd   
0x0000000000007527:  F7 FB                idiv  bx
0x0000000000007529:  42                   inc   dx
0x000000000000752a:  6B F2 05             imul  si, dx, 5
0x000000000000752d:  BB 30 07             mov   bx, OFFSET _playerMobj_pos
0x0000000000007530:  8B 1F                mov   bx, word ptr ds:[bx]
0x0000000000007532:  8E 45 02             mov   es, word ptr ds:[di + 2]
0x0000000000007535:  26 8B 4F 10          mov   cx, word ptr es:[bx + MOBJ_POS_T.mp_angle+2]
0x0000000000007539:  E8 B4 20             call  P_Random_
0x000000000000753c:  C1 E9 03             shr   cx, 3
0x000000000000753f:  88 C2                mov   dl, al
0x0000000000007541:  E8 AC 20             call  P_Random_
0x0000000000007544:  30 F6                xor   dh, dh
0x0000000000007546:  30 E4                xor   ah, ah
0x0000000000007548:  56                   push  si
0x0000000000007549:  29 C2                sub   dx, ax
0x000000000000754b:  E8 A2 20             call  P_Random_
0x000000000000754e:  01 D1                add   cx, dx
0x0000000000007550:  88 C2                mov   dl, al
0x0000000000007552:  E8 9B 20             call  P_Random_
0x0000000000007555:  30 F6                xor   dh, dh
0x0000000000007557:  30 E4                xor   ah, ah
0x0000000000007559:  29 C2                sub   dx, ax
0x000000000000755b:  89 D0                mov   ax, dx
0x000000000000755d:  C1 E0 05             shl   ax, 5
0x0000000000007560:  99                   cwd   
0x0000000000007561:  80 E5 1F             and   ch, 0x1f
0x0000000000007564:  03 06 24 1D          add   ax, word ptr [0x1d24]
0x0000000000007568:  13 16 26 1D          adc   dx, word ptr [0x1d26]
0x000000000000756c:  52                   push  dx
0x000000000000756d:  BB EC 06             mov   bx, OFFSET _playerMobj
0x0000000000007570:  50                   push  ax
0x0000000000007571:  89 CA                mov   dx, cx
0x0000000000007573:  8B 07                mov   ax, word ptr ds:[bx]
0x0000000000007575:  BB 00 08             mov   bx, OFFSET _player + PLAYER_T.player_readyweapon
0x0000000000007578:  FE 46 FE             inc   byte ptr [bp - 2]
0x000000000000757b:  FF 1E 7C 0C          call  dword ptr ds:[_P_LineAttack]
0x000000000000757f:  80 7E FE 14          cmp   byte ptr [bp - 2], 0x14
0x0000000000007583:  7C 99                jl    0x751e
0x0000000000007585:  C9                   LEAVE_MACRO 
0x0000000000007586:  5F                   pop   di
0x0000000000007587:  5E                   pop   si
0x0000000000007588:  5A                   pop   dx
0x0000000000007589:  59                   pop   cx
0x000000000000758a:  5B                   pop   bx
0x000000000000758b:  C3                   ret   

ENDP

PROC A_FireCGun_ NEAR
PUBLIC A_FireCGun_

0x000000000000758c:  53                   push  bx
0x000000000000758d:  52                   push  dx
0x000000000000758e:  56                   push  si
0x000000000000758f:  57                   push  di
0x0000000000007590:  89 C6                mov   si, ax
0x0000000000007592:  BB EC 06             mov   bx, OFFSET _playerMobj
0x0000000000007595:  BA 01 00             mov   dx, SFX_PISTOL
0x0000000000007598:  8B 07                mov   ax, word ptr ds:[bx]
0x000000000000759a:  BB 00 08             mov   bx, OFFSET _player + PLAYER_T.player_readyweapon
0x000000000000759d:  0E                   push  cs
0x000000000000759e:  3E E8 AE 8F          call  S_StartSound_
0x00000000000075a2:  8A 07                mov   al, byte ptr ds:[bx]
0x00000000000075a4:  30 E4                xor   ah, ah
0x00000000000075a6:  6B D8 0B             imul  bx, ax, SIZEOF_MOBJINFO_T  ; todo x86-16
0x00000000000075a9:  8A 87 0E 0E          mov   al, byte ptr ds:[bx + _weaponinfo]
0x00000000000075ad:  89 C3                mov   bx, ax
0x00000000000075af:  01 C3                add   bx, ax
0x00000000000075b1:  83 BF 0C 08 00       cmp   word ptr ds:[bx + OFFSET _player + PLAYER_T.player_ammo], 0
0x00000000000075b6:  75 05                jne   label_21
0x00000000000075b8:  5F                   pop   di
0x00000000000075b9:  5E                   pop   si
0x00000000000075ba:  5A                   pop   dx
0x00000000000075bb:  5B                   pop   bx
0x00000000000075bc:  C3                   ret   
label_21:
0x00000000000075bd:  BB EC 06             mov   bx, OFFSET _playerMobj
0x00000000000075c0:  BA 9B 00             mov   dx, S_PLAY_ATK2
0x00000000000075c3:  8B 07                mov   ax, word ptr ds:[bx]
0x00000000000075c5:  BB 00 08             mov   bx, OFFSET _player + PLAYER_T.player_readyweapon
0x00000000000075c8:  0E                   push  cs
0x00000000000075c9:  E8 60 26             call  P_SetMobjState_
0x00000000000075cc:  90                   nop   
0x00000000000075cd:  8A 07                mov   al, byte ptr ds:[bx]
0x00000000000075cf:  30 E4                xor   ah, ah
0x00000000000075d1:  6B D8 0B             imul  bx, ax, SIZEOF_MOBJINFO_T  ; todo x86-16
0x00000000000075d4:  8A 87 0E 0E          mov   al, byte ptr ds:[bx + _weaponinfo]
0x00000000000075d8:  89 C3                mov   bx, ax
0x00000000000075da:  01 C3                add   bx, ax
0x00000000000075dc:  BF 00 08             mov   di, OFFSET _player + PLAYER_T.player_readyweapon
0x00000000000075df:  FF 8F 0C 08          dec   word ptr ds:[bx + OFFSET _player + PLAYER_T.player_ammo]
0x00000000000075e3:  8A 05                mov   al, byte ptr ds:[di]
0x00000000000075e5:  6B D8 0B             imul  bx, ax, SIZEOF_MOBJINFO_T  ; todo x86-16
0x00000000000075e8:  8B 97 17 0E          mov   dx, word ptr ds:[bx + OFFSET _weaponinfo + WEAPONINFO_T.weaponinfo_flashstate]
0x00000000000075ec:  03 14                add   dx, word ptr ds:[si]
0x00000000000075ee:  B8 01 00             mov   ax, 1
0x00000000000075f1:  83 EA 34             sub   dx, 0x34
0x00000000000075f4:  BB 2B 08             mov   bx, OFFSET _player + PLAYER_T.player_refire
0x00000000000075f7:  E8 DA 01             call  P_SetPsprite_
0x00000000000075fa:  E8 37 FD             call  P_BulletSlope_
0x00000000000075fd:  80 3F 00             cmp   byte ptr ds:[bx], 0
0x0000000000007600:  75 0B                jne   0x760d
0x0000000000007602:  B0 01                mov   al, 1
0x0000000000007604:  98                   cbw  
0x0000000000007605:  E8 A4 FD             call  P_GunShot_
0x0000000000007608:  5F                   pop   di
0x0000000000007609:  5E                   pop   si
0x000000000000760a:  5A                   pop   dx
0x000000000000760b:  5B                   pop   bx
0x000000000000760c:  C3                   ret   
0x000000000000760d:  30 C0                xor   al, al
0x000000000000760f:  98                   cbw  
0x0000000000007610:  E8 99 FD             call  P_GunShot_
0x0000000000007613:  5F                   pop   di
0x0000000000007614:  5E                   pop   si
0x0000000000007615:  5A                   pop   dx
0x0000000000007616:  5B                   pop   bx
0x0000000000007617:  C3                   ret   


ENDP

PROC A_Light0_ NEAR
PUBLIC A_Light0_

0x0000000000007618:  53                   push  bx
0x0000000000007619:  BB 2E 08             mov   bx, OFFSET _player + PLAYER_T.player_extralightvalue
0x000000000000761c:  C6 07 00             mov   byte ptr ds:[bx], 0
0x000000000000761f:  5B                   pop   bx
0x0000000000007620:  C3                   ret   

ENDP

PROC A_Light1_ NEAR
PUBLIC A_Light1_

0x0000000000007622:  53                   push  bx
0x0000000000007623:  BB 2E 08             mov   bx, OFFSET _player + PLAYER_T.player_extralightvalue
0x0000000000007626:  C6 07 01             mov   byte ptr ds:[bx], 1
0x0000000000007629:  5B                   pop   bx
0x000000000000762a:  C3                   ret   

ENDP

PROC A_Light2_ NEAR
PUBLIC A_Light2_

0x000000000000762c:  53                   push  bx
0x000000000000762d:  BB 2E 08             mov   bx, OFFSET _player + PLAYER_T.player_extralightvalue
0x0000000000007630:  C6 07 02             mov   byte ptr ds:[bx], 2
0x0000000000007633:  5B                   pop   bx
0x0000000000007634:  C3                   ret   

ENDP

PROC A_OpenShotgun2_ NEAR
PUBLIC A_OpenShotgun2_

0x0000000000007636:  53                   push  bx
0x0000000000007637:  52                   push  dx
0x0000000000007638:  BB EC 06             mov   bx, OFFSET _playerMobj
0x000000000000763b:  BA 05 00             mov   dx, SFX_DBOPN
0x000000000000763e:  8B 07                mov   ax, word ptr ds:[bx]
0x0000000000007640:  0E                   push  cs
0x0000000000007641:  E8 0C 8F             call  S_StartSound_
0x0000000000007644:  90                   nop   
0x0000000000007645:  5A                   pop   dx
0x0000000000007646:  5B                   pop   bx

ENDP

PROC A_LoadShotgun2_ NEAR
PUBLIC A_LoadShotgun2_

0x0000000000007648:  53                   push  bx
0x0000000000007649:  52                   push  dx
0x000000000000764a:  BB EC 06             mov   bx, OFFSET _playerMobj
0x000000000000764d:  BA 07 00             mov   dx, SFX_DBLOAD
0x0000000000007650:  8B 07                mov   ax, word ptr ds:[bx]
0x0000000000007652:  0E                   push  cs
0x0000000000007653:  E8 FA 8E             call  S_StartSound_
0x0000000000007656:  90                   nop   
0x0000000000007657:  5A                   pop   dx
0x0000000000007658:  5B                   pop   bx
0x0000000000007659:  C3                   ret   

ENDP

PROC A_CloseShotgun2_ NEAR
PUBLIC A_CloseShotgun2_

0x000000000000765a:  53                   push  bx
0x000000000000765b:  52                   push  dx
0x000000000000765c:  56                   push  si
0x000000000000765d:  89 C3                mov   bx, ax
0x000000000000765f:  BE EC 06             mov   si, OFFSET _playerMobj
0x0000000000007662:  BA 06 00             mov   dx, SFX_DBCLS
0x0000000000007665:  8B 04                mov   ax, word ptr ds:[si]
0x0000000000007667:  0E                   push  cs
0x0000000000007668:  3E E8 E4 8E          call  S_StartSound_
0x000000000000766c:  89 D8                mov   ax, bx
0x000000000000766e:  E8 15 F9             call  A_Refire_
0x0000000000007671:  5E                   pop   si
0x0000000000007672:  5A                   pop   dx
0x0000000000007673:  5B                   pop   bx
0x0000000000007674:  C3                   ret   

ENDP

PROC A_BFGSpray_ NEAR
PUBLIC A_BFGSpray_

0x0000000000007676:  52                   push  dx
0x0000000000007677:  56                   push  si
0x0000000000007678:  57                   push  di
0x0000000000007679:  55                   push  bp
0x000000000000767a:  89 E5                mov   bp, sp
0x000000000000767c:  83 EC 02             sub   sp, 2
0x000000000000767f:  50                   push  ax
0x0000000000007680:  53                   push  bx
0x0000000000007681:  51                   push  cx
0x0000000000007682:  C6 46 FE 00          mov   byte ptr [bp - 2], 0
0x0000000000007686:  8A 46 FE             mov   al, byte ptr [bp - 2]
0x0000000000007689:  98                   cbw  
0x000000000000768a:  6B C0 33             imul  ax, ax, 0x33
0x000000000000768d:  8E 46 F8             mov   es, word ptr [bp - 8]
0x0000000000007690:  8B 5E FA             mov   bx, word ptr [bp - 6]
0x0000000000007693:  26 8B 57 10          mov   dx, word ptr es:[bx + 0x10]
0x0000000000007697:  8B 5E FC             mov   bx, word ptr [bp - 4]
0x000000000000769a:  6B 77 22 2C          imul  si, word ptr ds:[bx + 0x22], SIZEOF_THINKER_T
0x000000000000769e:  C1 EA 03             shr   dx, 3
0x00000000000076a1:  81 EA 00 04          sub   dx, 0x400
0x00000000000076a5:  01 C2                add   dx, ax
0x00000000000076a7:  BB 00 04             mov   bx, 0x400
0x00000000000076aa:  81 C6 04 34          add   si, 0x3404
0x00000000000076ae:  80 E6 1F             and   dh, 0x1f
0x00000000000076b1:  89 F0                mov   ax, si
0x00000000000076b3:  FF 1E 78 0C          call  dword ptr ds:[_P_AimLineAttack]
0x00000000000076b7:  BB 12 07             mov   bx, 0x712
0x00000000000076ba:  8B 07                mov   ax, word ptr ds:[bx]
0x00000000000076bc:  85 C0                test  ax, ax
0x00000000000076be:  75 0E                jne   0x76ce
0x00000000000076c0:  FE 46 FE             inc   byte ptr [bp - 2]
0x00000000000076c3:  80 7E FE 28          cmp   byte ptr [bp - 2], 0x28
0x00000000000076c7:  7C BD                jl    0x7686
0x00000000000076c9:  C9                   LEAVE_MACRO 
0x00000000000076ca:  5F                   pop   di
0x00000000000076cb:  5E                   pop   si
0x00000000000076cc:  5A                   pop   dx
0x00000000000076cd:  C3                   ret   
0x00000000000076ce:  89 C3                mov   bx, ax
0x00000000000076d0:  BF 14 07             mov   di, 0x714
0x00000000000076d3:  8B 47 0A             mov   ax, word ptr ds:[bx + 0xa]
0x00000000000076d6:  8B 4F 0C             mov   cx, word ptr ds:[bx + 0xc]
0x00000000000076d9:  FF 77 04             push  word ptr ds:[bx + 4]
0x00000000000076dc:  D1 F9                sar   cx, 1
0x00000000000076de:  D1 D8                rcr   ax, 1
0x00000000000076e0:  BB 14 07             mov   bx, 0x714
0x00000000000076e3:  D1 F9                sar   cx, 1
0x00000000000076e5:  D1 D8                rcr   ax, 1
0x00000000000076e7:  8B 1F                mov   bx, word ptr ds:[bx]
0x00000000000076e9:  8E 45 02             mov   es, word ptr ds:[di + 2]
0x00000000000076ec:  6A 2A                push  0x2a
0x00000000000076ee:  26 03 47 08          add   ax, word ptr es:[bx + 8]
0x00000000000076f2:  26 13 4F 0A          adc   cx, word ptr es:[bx + 0xa]
0x00000000000076f6:  26 8B 17             mov   dx, word ptr es:[bx]
0x00000000000076f9:  51                   push  cx
0x00000000000076fa:  26 8B 7F 02          mov   di, word ptr es:[bx + 2]
0x00000000000076fe:  50                   push  ax
0x00000000000076ff:  26 8B 47 04          mov   ax, word ptr es:[bx + 4]
0x0000000000007703:  26 8B 4F 06          mov   cx, word ptr es:[bx + 6]
0x0000000000007707:  89 C3                mov   bx, ax
0x0000000000007709:  89 D0                mov   ax, dx
0x000000000000770b:  89 FA                mov   dx, di
0x000000000000770d:  0E                   push  cs
0x000000000000770e:  3E E8 D0 22          call  P_SpawnMobj_
0x0000000000007712:  31 C9                xor   cx, cx
0x0000000000007714:  30 D2                xor   dl, dl
0x0000000000007716:  E8 D7 1E             call  P_Random_
0x0000000000007719:  24 07                and   al, 7
0x000000000000771b:  30 E4                xor   ah, ah
0x000000000000771d:  40                   inc   ax
0x000000000000771e:  FE C2                inc   dl
0x0000000000007720:  01 C1                add   cx, ax
0x0000000000007722:  80 FA 0F             cmp   dl, 0xf
0x0000000000007725:  7C EF                jl    0x7716
0x0000000000007727:  BB 12 07             mov   bx, 0x712
0x000000000000772a:  89 F2                mov   dx, si
0x000000000000772c:  8B 07                mov   ax, word ptr ds:[bx]
0x000000000000772e:  89 F3                mov   bx, si
0x0000000000007730:  0E                   push  cs
0x0000000000007731:  E8 FE E9             call  P_DamageMobj_
0x0000000000007734:  90                   nop   
0x0000000000007735:  EB 89                jmp   0x76c0
0x0000000000007737:  FC                   cld   

ENDP

PROC A_BFGsound_ NEAR
PUBLIC A_BFGsound_


0x0000000000007738:  53                   push  bx
0x0000000000007739:  52                   push  dx
0x000000000000773a:  BB EC 06             mov   bx, OFFSET _playerMobj
0x000000000000773d:  BA 09 00             mov   dx, SFX_BFG
0x0000000000007740:  8B 07                mov   ax, word ptr ds:[bx]
0x0000000000007742:  0E                   push  cs
0x0000000000007743:  E8 0A 8E             call  S_StartSound_
0x0000000000007746:  90                   nop   
0x0000000000007747:  5A                   pop   dx
0x0000000000007748:  5B                   pop   bx
0x0000000000007749:  C3                   ret   


ENDP

PROC P_MovePsprites_ NEAR
PUBLIC P_MovePsprites_

0x000000000000774a:  53                   push  bx
0x000000000000774b:  51                   push  cx
0x000000000000774c:  52                   push  dx
0x000000000000774d:  56                   push  si
0x000000000000774e:  BB 88 03             mov   bx, 0x388
0x0000000000007751:  30 C9                xor   cl, cl
0x0000000000007753:  83 3F FF             cmp   word ptr ds:[bx], -1
0x0000000000007756:  74 20                je    0x7778
0x0000000000007758:  83 7F 02 FF          cmp   word ptr ds:[bx + 2], -1
0x000000000000775c:  74 1A                je    0x7778
0x000000000000775e:  FF 4F 02             dec   word ptr ds:[bx + 2]
0x0000000000007761:  75 15                jne   0x7778
0x0000000000007763:  6B 37 06             imul  si, word ptr ds:[bx], 6
0x0000000000007766:  B8 74 7D             mov   ax, 0x7d74
0x0000000000007769:  8E C0                mov   es, ax
0x000000000000776b:  88 C8                mov   al, cl
0x000000000000776d:  26 8B 54 04          mov   dx, word ptr es:[si + 4]
0x0000000000007771:  98                   cbw  
0x0000000000007772:  83 C6 04             add   si, 4
0x0000000000007775:  E8 5C 00             call  P_SetPsprite_
0x0000000000007778:  FE C1                inc   cl
0x000000000000777a:  83 C3 0C             add   bx, 0xc
0x000000000000777d:  80 F9 02             cmp   cl, 2
0x0000000000007780:  7C D1                jl    0x7753
0x0000000000007782:  BB 8C 03             mov   bx, 0x38c
0x0000000000007785:  BE 98 03             mov   si, 0x398
0x0000000000007788:  8B 07                mov   ax, word ptr ds:[bx]
0x000000000000778a:  8B 57 02             mov   dx, word ptr ds:[bx + 2]
0x000000000000778d:  89 04                mov   word ptr ds:[si], ax
0x000000000000778f:  89 54 02             mov   word ptr ds:[si + 2], dx
0x0000000000007792:  BE 90 03             mov   si, 0x390
0x0000000000007795:  BB 9C 03             mov   bx, 0x39c
0x0000000000007798:  8B 04                mov   ax, word ptr ds:[si]
0x000000000000779a:  8B 54 02             mov   dx, word ptr ds:[si + 2]
0x000000000000779d:  89 07                mov   word ptr ds:[bx], ax
0x000000000000779f:  89 57 02             mov   word ptr ds:[bx + 2], dx
0x00000000000077a2:  5E                   pop   si
0x00000000000077a3:  5A                   pop   dx
0x00000000000077a4:  59                   pop   cx
0x00000000000077a5:  5B                   pop   bx
0x00000000000077a6:  C3                   ret   

; todo probably switch jump table

0x00000000000077a8:  12 78 40             adc   bh, byte ptr ds:[bx + si + 0x40]
0x00000000000077ab:  78 47                js    0x77f4
0x00000000000077ad:  78 4E                js    0x77fd
0x00000000000077af:  78 55                js    0x7806
0x00000000000077b1:  78 5C                js    0x780f
0x00000000000077b3:  78 63                js    0x7818
0x00000000000077b5:  78 6A                js    0x7821
0x00000000000077b7:  78 71                js    0x782a
0x00000000000077b9:  78 78                js    0x7833
0x00000000000077bb:  78 80                js    0x773d
0x00000000000077bd:  78 87                js    0x7746
0x00000000000077bf:  78 8C                js    0x774d
0x00000000000077c1:  78 9C                js    0x775f
0x00000000000077c3:  78 AC                js    0x7771
0x00000000000077c5:  78 C1                js    0x7788
0x00000000000077c7:  78 C9                js    0x7792
0x00000000000077c9:  78 D1                js    0x779c
0x00000000000077cb:  78 D9                js    0x77a6
0x00000000000077cd:  78 E1                js    0x77b0
0x00000000000077cf:  78 E9                js    0x77ba
0x00000000000077d1:  78 F9                js    0x77cc
0x00000000000077d3:  78                 js    0x7828




ENDP

PROC P_SetPsprite_ NEAR
PUBLIC P_SetPsprite_


0x00000000000077d4:  53                   push  bx
0x00000000000077d5:  51                   push  cx
0x00000000000077d6:  56                   push  si
0x00000000000077d7:  98                   cbw  
0x00000000000077d8:  6B D8 0C             imul  bx, ax, 0xc
0x00000000000077db:  81 C3 88 03          add   bx, 0x388
0x00000000000077df:  85 D2                test  dx, dx
0x00000000000077e1:  74 55                je    0x7838
0x00000000000077e3:  B1 01                mov   cl, 1
0x00000000000077e5:  83 FA FF             cmp   dx, -1
0x00000000000077e8:  74 4E                je    0x7838
0x00000000000077ea:  6B F2 06             imul  si, dx, 6
0x00000000000077ed:  B8 74 7D             mov   ax, 0x7d74
0x00000000000077f0:  8E C0                mov   es, ax
0x00000000000077f2:  89 17                mov   word ptr ds:[bx], dx
0x00000000000077f4:  26 8A 44 02          mov   al, byte ptr es:[si + 2]
0x00000000000077f8:  98                   cbw  
0x00000000000077f9:  89 47 02             mov   word ptr ds:[bx + 2], ax
0x00000000000077fc:  26 8A 54 03          mov   dl, byte ptr es:[si + 3]
0x0000000000007800:  28 CA                sub   dl, cl
0x0000000000007802:  80 FA 15             cmp   dl, 0x15
0x0000000000007805:  77 19                ja    0x7820
0x0000000000007807:  30 F6                xor   dh, dh
0x0000000000007809:  89 D6                mov   si, dx
0x000000000000780b:  01 D6                add   si, dx
0x000000000000780d:  2E FF A4 A8 77       jmp   word ptr cs:[si + 0x77a8]
0x0000000000007812:  BE 2E 08             mov   si, OFFSET _player + PLAYER_T.player_extralightvalue
0x0000000000007815:  88 34                mov   byte ptr ds:[si], dh
label_29:
0x0000000000007817:  84 C9                test  cl, cl
0x0000000000007819:  74 05                je    0x7820
0x000000000000781b:  83 3F FF             cmp   word ptr ds:[bx], -1
0x000000000000781e:  74 1C                je    0x783c
0x0000000000007820:  6B 37 06             imul  si, word ptr ds:[bx], 6
0x0000000000007823:  B8 74 7D             mov   ax, 0x7d74
0x0000000000007826:  8E C0                mov   es, ax
0x0000000000007828:  83 C6 04             add   si, 4
0x000000000000782b:  26 8B 14             mov   dx, word ptr es:[si]
0x000000000000782e:  83 7F 02 00          cmp   word ptr ds:[bx + 2], 0
0x0000000000007832:  75 08                jne   0x783c
0x0000000000007834:  85 D2                test  dx, dx
0x0000000000007836:  75 AD                jne   0x77e5
0x0000000000007838:  C7 07 FF FF          mov   word ptr ds:[bx], 0xffff
0x000000000000783c:  5E                   pop   si
0x000000000000783d:  59                   pop   cx
0x000000000000783e:  5B                   pop   bx
0x000000000000783f:  C3                   ret   
0x0000000000007840:  89 D8                mov   ax, bx
0x0000000000007842:  E8 47 F6             call  A_WeaponReady_
0x0000000000007845:  EB D0                jmp   label_29
0x0000000000007847:  89 D8                mov   ax, bx
0x0000000000007849:  E8 68 F7             call  A_Lower_
0x000000000000784c:  EB C9                jmp   label_29
0x000000000000784e:  89 D8                mov   ax, bx
0x0000000000007850:  E8 AD F7             call  A_Raise_
0x0000000000007853:  EB C2                jmp   label_29
0x0000000000007855:  89 D8                mov   ax, bx
0x0000000000007857:  E8 0C F8             call  A_Punch_
0x000000000000785a:  EB BB                jmp   label_29
0x000000000000785c:  89 D8                mov   ax, bx
0x000000000000785e:  E8 25 F7             call  A_Refire_
0x0000000000007861:  EB B4                jmp   label_29
0x0000000000007863:  89 D8                mov   ax, bx
0x0000000000007865:  E8 A4 FB             call  A_FirePistol_
0x0000000000007868:  EB AD                jmp   label_29
0x000000000000786a:  BE 2E 08             mov   si, OFFSET _player + PLAYER_T.player_extralightvalue
0x000000000000786d:  88 0C                mov   byte ptr ds:[si], cl
0x000000000000786f:  EB A6                jmp   label_29
0x0000000000007871:  89 D8                mov   ax, bx
0x0000000000007873:  E8 F8 FB             call  A_FireShotgun_
0x0000000000007876:  EB 9F                jmp   label_29
0x0000000000007878:  BE 2E 08             mov   si, OFFSET _player + PLAYER_T.player_extralightvalue
0x000000000000787b:  C6 04 02             mov   byte ptr ds:[si], 2
0x000000000000787e:  EB 97                jmp   label_29
0x0000000000007880:  89 D8                mov   ax, bx
0x0000000000007882:  E8 43 FC             call  A_FireShotgun2_
0x0000000000007885:  EB 90                jmp   label_29
0x0000000000007887:  E8 9A F4             call  A_CheckReload_
0x000000000000788a:  EB 8B                jmp   label_29
0x000000000000788c:  BE EC 06             mov   si, OFFSET _playerMobj
0x000000000000788f:  BA 05 00             mov   dx, SFX_DBOPN
0x0000000000007892:  8B 04                mov   ax, word ptr ds:[si]
0x0000000000007894:  0E                   push  cs
0x0000000000007895:  E8 B8 8C             call  S_StartSound_
0x0000000000007898:  90                   nop   
0x0000000000007899:  E9 7B FF             jmp   label_29
0x000000000000789c:  BE EC 06             mov   si, OFFSET _playerMobj
0x000000000000789f:  BA 07 00             mov   dx, SFX_DBLOAD
0x00000000000078a2:  8B 04                mov   ax, word ptr ds:[si]
0x00000000000078a4:  0E                   push  cs
0x00000000000078a5:  E8 A8 8C             call  S_StartSound_
0x00000000000078a8:  90                   nop   
0x00000000000078a9:  E9 6B FF             jmp   label_29
0x00000000000078ac:  BE EC 06             mov   si, OFFSET _playerMobj
0x00000000000078af:  BA 06 00             mov   dx, SFX_DBCLS
0x00000000000078b2:  8B 04                mov   ax, word ptr ds:[si]
0x00000000000078b4:  0E                   push  cs
0x00000000000078b5:  E8 98 8C             call  S_StartSound_
0x00000000000078b8:  90                   nop   
0x00000000000078b9:  89 D8                mov   ax, bx
0x00000000000078bb:  E8 C8 F6             call  A_Refire_
0x00000000000078be:  E9 56 FF             jmp   label_29
0x00000000000078c1:  89 D8                mov   ax, bx
0x00000000000078c3:  E8 C6 FC             call  A_FireCGun_
0x00000000000078c6:  E9 4E FF             jmp   label_29
0x00000000000078c9:  89 D8                mov   ax, bx
0x00000000000078cb:  E8 72 F7             call  A_GunFlash_
0x00000000000078ce:  E9 46 FF             jmp   label_29
0x00000000000078d1:  89 D8                mov   ax, bx
0x00000000000078d3:  E8 DA F9             call  A_FireMissile_
0x00000000000078d6:  E9 3E FF             jmp   label_29
0x00000000000078d9:  89 D8                mov   ax, bx
0x00000000000078db:  E8 58 F8             call  A_Saw_
0x00000000000078de:  E9 36 FF             jmp   label_29
0x00000000000078e1:  89 D8                mov   ax, bx
0x00000000000078e3:  E8 0C FA             call  A_FirePlasma_
0x00000000000078e6:  E9 2E FF             jmp   label_29
0x00000000000078e9:  BE EC 06             mov   si, OFFSET _playerMobj
0x00000000000078ec:  BA 09 00             mov   dx, SFX_BFG
0x00000000000078ef:  8B 04                mov   ax, word ptr ds:[si]
0x00000000000078f1:  0E                   push  cs
0x00000000000078f2:  3E E8 5A 8C          call  S_StartSound_
0x00000000000078f6:  E9 1E FF             jmp   label_29
0x00000000000078f9:  89 D8                mov   ax, bx
0x00000000000078fb:  E8 D2 F9             call  A_FireBFG_
0x00000000000078fe:  E9 16 FF             jmp   label_29

@


PROC    P_PSPR_ENDMARKER_ 
PUBLIC  P_PSPR_ENDMARKER_
ENDP


END
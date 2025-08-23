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



ASCII_0 = 030h
ASCII_1 = 031h

EXTRN Z_QuickMapPhysics_:FAR
EXTRN Z_QuickMapStatus_:FAR
EXTRN I_SetPalette_:FAR
EXTRN V_CopyRect_:FAR
EXTRN V_MarkRect_:FAR
EXTRN V_DrawPatch_:FAR
EXTRN cht_CheckCheat_:NEAR
EXTRN cht_GetParam_:NEAR
EXTRN S_ChangeMusic_:FAR
EXTRN locallib_printhex_:NEAR
EXTRN G_DeferedInitNew_:FAR
EXTRN R_PointToAngle2_:FAR
EXTRN combine_strings_:NEAR

.DATA

EXTRN _st_randomnumber:BYTE
EXTRN _updatedthisframe:BYTE
EXTRN _do_st_refresh:BYTE
EXTRN _st_facecount:WORD
EXTRN _st_faceindex:WORD
EXTRN _st_calc_lastcalc:WORD
EXTRN _st_calc_oldhealth:WORD
EXTRN _P_GivePower:DWORD
EXTRN _st_stopped:BYTE
EXTRN _st_palette:BYTE
EXTRN _st_oldhealth:WORD
EXTRN _st_firsttime:BYTE
EXTRN _st_gamestate:BYTE
EXTRN _st_statusbaron:BYTE
EXTRN _st_faceindex:BYTE

EXTRN _tallpercent:BYTE

EXTRN _armsbgarray:BYTE

;todo move to cs
EXTRN _st_stuff_buf:BYTE
EXTRN _arms:BYTE
EXTRN _faces:BYTE
EXTRN _keys:BYTE
EXTRN _keyboxes:BYTE
EXTRN _oldweaponsowned:BYTE

EXTRN _w_ammo:BYTE
EXTRN _w_arms:BYTE
EXTRN _w_armsbg:BYTE
EXTRN _w_armor:BYTE
EXTRN _w_health:BYTE
EXTRN _w_faces:BYTE
EXTRN _w_keyboxes:BYTE
EXTRN _w_maxammo:BYTE
EXTRN _w_ready:BYTE
EXTRN _sbar:WORD


.CODE

RADIATIONPAL = 13


PROC    ST_STUFF_STARTMARKER_ NEAR
PUBLIC  ST_STUFF_STARTMARKER_
ENDP


PROC    ST_refreshBackground_ NEAR
PUBLIC  ST_refreshBackground_



0x0000000000004e60:  53                   push  bx
0x0000000000004e61:  51                   push  cx
0x0000000000004e62:  52                   push  dx
0x0000000000004e63:  80 3E CF 1C 00       cmp   byte ptr ds:[_st_statusbaron], 0
0x0000000000004e68:  75 04                je    exit_st_refresh_background


0x0000000000004e6e:  68 00 70             push  ST_GRAPHICS_SEGMENT
0x0000000000004e71:  BB 04 00             mov   bx, 4
0x0000000000004e74:  A1 5E 1C             push  word ptr ds:[_sbar]
0x0000000000004e7a:  31 C0                xor   ax, ax
cwd
0x0000000000004e7c:  B9 20 00             mov   cx, ST_HEIGHT
0x0000000000004e80:  3E E8 86 6B          call  V_DrawPatch_
0x0000000000004e84:  BB 40 01             mov   bx, SCREENWIDTH
0x0000000000004e87:  BA A8 00             mov   dx, ST_Y
0x0000000000004e8a:  31 C0                xor   ax, ax
0x0000000000004e8d:  E8 5F 70             call  V_MarkRect_
0x0000000000004e91:  B9 20 00             mov   cx, ST_HEIGHT
0x0000000000004e94:  BB 40 01             mov   bx, SCREENWIDTH
0x0000000000004e97:  BA 00 D2             mov   dx, ST_Y * SCREENWIDTH ;0D200h
0x0000000000004e9a:  31 C0                xor   ax, ax
0x0000000000004e9d:  E8 6D 70             call  V_CopyRect_
exit_st_refresh_background:
0x0000000000004ea1:  5A                   pop   dx
0x0000000000004ea2:  59                   pop   cx
0x0000000000004ea3:  5B                   pop   bx
0x0000000000004ea4:  C3                   ret   

ENDP


PROC    ST_Responder_ NEAR
PUBLIC  ST_Responder_


0x0000000000004ea6:  53                   push  bx
0x0000000000004ea7:  51                   push  cx
0x0000000000004ea8:  56                   push  si
0x0000000000004ea9:  57                   push  di
0x0000000000004eaa:  55                   push  bp
0x0000000000004eab:  89 E5                mov   bp, sp
0x0000000000004ead:  83 EC 14             sub   sp, 014h
0x0000000000004eb0:  89 C7                mov   di, ax
0x0000000000004eb2:  89 56 FE             mov   word ptr [bp - 2], dx
0x0000000000004eb5:  8E C2                mov   es, dx
0x0000000000004eb7:  26 80 3D 00          cmp   byte ptr es:[di], 0
0x0000000000004ebb:  74 03                je    label_1
0x0000000000004ebd:  E9 AE 00             jmp   exit_st_responder_ret_0
label_1:
0x0000000000004ec0:  BB 31 01             mov   bx, _gameskill
0x0000000000004ec3:  80 3F 04             cmp   byte ptr ds:[bx], 4
0x0000000000004ec6:  75 03                jne   label_3
0x0000000000004ec8:  E9 8F 00             jmp   label_2
label_3:
0x0000000000004ecb:  26 8A 45 01          mov   al, byte ptr es:[di + 1]
0x0000000000004ecf:  98                   cbw  
0x0000000000004ed0:  89 C2                mov   dx, ax
0x0000000000004ed2:  B8 24 00             mov   ax, CHEATID_GODMODE
0x0000000000004ed5:  E8 AF 17             call  cht_CheckCheat_
0x0000000000004ed8:  84 C0                test  al, al
0x0000000000004eda:  75 03                jne   label_4
0x0000000000004edc:  E9 A6 00             jmp   label_5
label_4:
0x0000000000004edf:  BB 0B 07             mov   bx, _player + PLAYER_T.player_cheats
0x0000000000004ee2:  80 37 02             xor   byte ptr ds:[bx], 2
0x0000000000004ee5:  F6 07 02             test  byte ptr ds:[bx], 2
0x0000000000004ee8:  75 03                jne   label_7
0x0000000000004eea:  E9 89 00             jmp   label_6
label_7:
0x0000000000004eed:  BB EC 05             mov   bx, _playerMobj
0x0000000000004ef0:  8B 1F                mov   bx, word ptr ds:[bx]
0x0000000000004ef2:  C7 47 1C 64 00       mov   word ptr ds:[bx + MOBJ_T.m_health], 100
0x0000000000004ef7:  BB E8 06             mov   bx, _player + PLAYER_T.player_health
0x0000000000004efa:  C7 07 64 00          mov   word ptr ds:[bx], 100
0x0000000000004efe:  BB 24 07             mov   bx, _player + PLAYER_T.player_message
0x0000000000004f01:  C7 07 E3 00          mov   word ptr ds:[bx], STSTR_DQDON
label_12:
0x0000000000004f05:  30 DB                xor   bl, bl
label_10:
0x0000000000004f07:  8E 46 FE             mov   es, word ptr [bp - 2]
0x0000000000004f0a:  26 8A 45 01          mov   al, byte ptr es:[di + 1]
0x0000000000004f0e:  98                   cbw  
0x0000000000004f0f:  89 C2                mov   dx, ax
0x0000000000004f11:  88 D8                mov   al, bl
0x0000000000004f13:  98                   cbw  
0x0000000000004f14:  89 C1                mov   cx, ax
0x0000000000004f16:  C1 E0 02             shl   ax, 2
0x0000000000004f19:  E8 6B 17             call  cht_CheckCheat_
0x0000000000004f1c:  84 C0                test  al, al
0x0000000000004f1e:  74 18                je    label_8
0x0000000000004f20:  89 CE                mov   si, cx
0x0000000000004f22:  01 F6                add   si, si
0x0000000000004f24:  83 BC EE 06 00       cmp   word ptr ds:[si + _player + PLAYER_T.player_powers], 0
0x0000000000004f29:  75 54                jne   jump_to_label_9
0x0000000000004f2b:  89 C8                mov   ax, cx
0x0000000000004f2d:  FF 1E 18 0F          call  dword ptr [_P_GivePower]
label_34:
0x0000000000004f31:  BE 24 07             mov   si, _player + PLAYER_T.player_message
0x0000000000004f34:  C7 04 EA 00          mov   word ptr ds:[si], STSTR_BEHOLDX
label_8:
0x0000000000004f38:  FE C3                inc   bl
0x0000000000004f3a:  80 FB 06             cmp   bl, 6
0x0000000000004f3d:  7C C8                jl    label_10
0x0000000000004f3f:  8E 46 FE             mov   es, word ptr [bp - 2]
0x0000000000004f42:  26 8A 45 01          mov   al, byte ptr es:[di + 1]
0x0000000000004f46:  98                   cbw  
0x0000000000004f47:  89 C2                mov   dx, ax
0x0000000000004f49:  B8 18 00             mov   ax, CHEATID_BEHOLD
0x0000000000004f4c:  E8 38 17             call  cht_CheckCheat_
0x0000000000004f4f:  84 C0                test  al, al
0x0000000000004f51:  74 2F                je    jump_to_label_11
0x0000000000004f53:  BB 24 07             mov   bx, _player + PLAYER_T.player_message
0x0000000000004f56:  C7 07 E9 00          mov   word ptr ds:[bx], STSTR_BEHOLD
label_2:
0x0000000000004f5a:  8E 46 FE             mov   es, word ptr [bp - 2]
0x0000000000004f5d:  26 8A 45 01          mov   al, byte ptr es:[di + 1]
0x0000000000004f61:  98                   cbw  
0x0000000000004f62:  89 C2                mov   dx, ax
0x0000000000004f64:  B8 3C 00             mov   ax, CHEATID_CHANGE_LEVEL
0x0000000000004f67:  E8 1D 17             call  cht_CheckCheat_
0x0000000000004f6a:  84 C0                test  al, al
0x0000000000004f6c:  75 6D                jne   jump_to_label_17
exit_st_responder_ret_0:
0x0000000000004f6e:  30 C0                xor   al, al
0x0000000000004f70:  C9                   LEAVE_MACRO 
0x0000000000004f71:  5F                   pop   di
0x0000000000004f72:  5E                   pop   si
0x0000000000004f73:  59                   pop   cx
0x0000000000004f74:  5B                   pop   bx
0x0000000000004f75:  C3                   ret   
label_6:
0x0000000000004f76:  BB 24 07             mov   bx, _player + PLAYER_T.player_message
0x0000000000004f79:  C7 07 E4 00          mov   word ptr ds:[bx], STSTR_DQDOFF
0x0000000000004f7d:  EB 86                jmp   label_12
jump_to_label_9:
0x0000000000004f7f:  E9 D9 01             jmp   label_9
jump_to_label_11:
0x0000000000004f82:  E9 ED 01             jmp   label_11
label_5:
0x0000000000004f85:  8E 46 FE             mov   es, word ptr [bp - 2]
0x0000000000004f88:  26 8A 45 01          mov   al, byte ptr es:[di + 1]
0x0000000000004f8c:  98                   cbw  
0x0000000000004f8d:  89 C2                mov   dx, ax
0x0000000000004f8f:  B8 2C 00             mov   ax, CHEATID_AMMONOKEYS
0x0000000000004f92:  E8 F2 16             call  cht_CheckCheat_
0x0000000000004f95:  84 C0                test  al, al
0x0000000000004f97:  74 45                je    label_18
0x0000000000004f99:  BB EA 06             mov   bx, _player + PLAYER_T.player_armorpoints
0x0000000000004f9c:  C7 07 C8 00          mov   word ptr ds:[bx], 200
0x0000000000004fa0:  BB EC 06             mov   bx, _player + PLAYER_T.player_armortype
0x0000000000004fa3:  C6 07 02             mov   byte ptr ds:[bx], 2
0x0000000000004fa6:  30 DB                xor   bl, bl
label_20:
0x0000000000004fa8:  88 D8                mov   al, bl
0x0000000000004faa:  98                   cbw  
0x0000000000004fab:  89 C6                mov   si, ax
0x0000000000004fad:  FE C3                inc   bl
0x0000000000004faf:  C6 84 02 07 01       mov   byte ptr ds:[si + _player + PLAYER_T.player_weaponowned], 1
0x0000000000004fb4:  80 FB 09             cmp   bl, 9
0x0000000000004fb7:  7C EF                jl    label_20
0x0000000000004fb9:  30 DB                xor   bl, bl
label_19:
0x0000000000004fbb:  88 D8                mov   al, bl
0x0000000000004fbd:  98                   cbw  
0x0000000000004fbe:  89 C6                mov   si, ax
0x0000000000004fc0:  01 C6                add   si, ax
0x0000000000004fc2:  8B 84 14 07          mov   ax, word ptr ds:[si + _player + PLAYER_T.player_maxammo]
0x0000000000004fc6:  FE C3                inc   bl
0x0000000000004fc8:  89 84 0C 07          mov   word ptr ds:[si + _player + PLAYER_T.player_ammo], ax
0x0000000000004fcc:  80 FB 04             cmp   bl, 4
0x0000000000004fcf:  7C EA                jl    label_19
0x0000000000004fd1:  BB 24 07             mov   bx, _player + PLAYER_T.player_message
0x0000000000004fd4:  C7 07 E6 00          mov   word ptr ds:[bx], STSTR_KFAADDED
0x0000000000004fd8:  E9 2A FF             jmp   label_12
jump_to_label_17:
0x0000000000004fdb:  E9 87 02             jmp   label_17
label_18:
0x0000000000004fde:  8E 46 FE             mov   es, word ptr [bp - 2]
0x0000000000004fe1:  26 8A 45 01          mov   al, byte ptr es:[di + 1]
0x0000000000004fe5:  98                   cbw  
0x0000000000004fe6:  89 C2                mov   dx, ax
0x0000000000004fe8:  B8 28 00             mov   ax, CHEATID_AMMOANDKEYS
0x0000000000004feb:  E8 99 16             call  cht_CheckCheat_
0x0000000000004fee:  84 C0                test  al, al
0x0000000000004ff0:  74 55                je    label_21
0x0000000000004ff2:  BB EA 06             mov   bx, _player + PLAYER_T.player_armorpoints
0x0000000000004ff5:  C7 07 C8 00          mov   word ptr ds:[bx], 200
0x0000000000004ff9:  BB EC 06             mov   bx, _player + PLAYER_T.player_armortype
0x0000000000004ffc:  C6 07 02             mov   byte ptr ds:[bx], 2
0x0000000000004fff:  30 DB                xor   bl, bl
label_22:
0x0000000000005001:  88 D8                mov   al, bl
0x0000000000005003:  98                   cbw  
0x0000000000005004:  89 C6                mov   si, ax
0x0000000000005006:  FE C3                inc   bl
0x0000000000005008:  C6 84 02 07 01       mov   byte ptr ds:[si + _player + PLAYER_T.player_weaponowned], 1
0x000000000000500d:  80 FB 09             cmp   bl, 9
0x0000000000005010:  7C EF                jl    label_22
0x0000000000005012:  30 DB                xor   bl, bl
label_23:
0x0000000000005014:  88 D8                mov   al, bl
0x0000000000005016:  98                   cbw  
0x0000000000005017:  89 C6                mov   si, ax
0x0000000000005019:  01 C6                add   si, ax
0x000000000000501b:  8B 84 14 07          mov   ax, word ptr ds:[si + _player + PLAYER_T.player_maxammo]
0x000000000000501f:  FE C3                inc   bl
0x0000000000005021:  89 84 0C 07          mov   word ptr ds:[si + _player + PLAYER_T.player_ammo], ax
0x0000000000005025:  80 FB 04             cmp   bl, 4
0x0000000000005028:  7C EA                jl    label_23
0x000000000000502a:  30 DB                xor   bl, bl
label_24:
0x000000000000502c:  88 D8                mov   al, bl
0x000000000000502e:  98                   cbw  
0x000000000000502f:  89 C6                mov   si, ax
0x0000000000005031:  FE C3                inc   bl
0x0000000000005033:  C6 84 FA 06 01       mov   byte ptr ds:[si + _player + PLAYER_T.player_cards], 1
0x0000000000005038:  80 FB 06             cmp   bl, 6
0x000000000000503b:  7C EF                jl    label_24
0x000000000000503d:  BB 24 07             mov   bx, _player + PLAYER_T.player_message
0x0000000000005040:  C7 07 E5 00          mov   word ptr ds:[bx], STSTR_KFAADDED
0x0000000000005044:  E9 BE FE             jmp   label_12
label_21:
0x0000000000005047:  8E 46 FE             mov   es, word ptr [bp - 2]
0x000000000000504a:  26 8A 45 01          mov   al, byte ptr es:[di + 1]
0x000000000000504e:  98                   cbw  
0x000000000000504f:  89 C2                mov   dx, ax
0x0000000000005051:  B8 20 00             mov   ax, CHEATID_MUSIC
0x0000000000005054:  E8 30 16             call  cht_CheckCheat_
0x0000000000005057:  84 C0                test  al, al
0x0000000000005059:  75 3F                jne   label_25
0x000000000000505b:  BB EB 02             mov   bx, _commercial
0x000000000000505e:  80 3F 00             cmp   byte ptr ds:[bx], 0
0x0000000000005061:  74 34                je    jump_to_label_26
label_32:
0x0000000000005063:  BB EB 02             mov   bx, _commercial
0x0000000000005066:  80 3F 00             cmp   byte ptr ds:[bx], 0
0x0000000000005069:  75 03                jne   label_27
jump_to_label_12:
0x000000000000506b:  E9 97 FE             jmp   label_12
label_27:
0x000000000000506e:  8E 46 FE             mov   es, word ptr [bp - 2]
0x0000000000005071:  26 8A 45 01          mov   al, byte ptr es:[di + 1]
0x0000000000005075:  98                   cbw  
0x0000000000005076:  89 C2                mov   dx, ax
0x0000000000005078:  B8 34 00             mov   ax, CHEATID_NOCLIPDOOM2
0x000000000000507b:  E8 09 16             call  cht_CheckCheat_
0x000000000000507e:  84 C0                test  al, al
0x0000000000005080:  74 E9                je    jump_to_label_12
0x0000000000005082:  BB 0B 07             mov   bx, _player + PLAYER_T.player_cheats
0x0000000000005085:  80 37 01             xor   byte ptr ds:[bx], 1
0x0000000000005088:  F6 07 01             test  byte ptr ds:[bx], 1
0x000000000000508b:  74 66                je    jump_to_label_28
0x000000000000508d:  BB 24 07             mov   bx, _player + PLAYER_T.player_message
0x0000000000005090:  C7 07 E7 00          mov   word ptr ds:[bx], STSTR_NCON
0x0000000000005094:  E9 6E FE             jmp   label_12
jump_to_label_26:
0x0000000000005097:  E9 8B 00             jmp   label_26
label_25:
0x000000000000509a:  BB 24 07             mov   bx, _player + PLAYER_T.player_message
0x000000000000509d:  8D 56 F6             lea   dx, [bp - 0Ah]
0x00000000000050a0:  B8 20 00             mov   ax, CHEATID_MUSIC
0x00000000000050a3:  C7 07 E1 00          mov   word ptr ds:[bx], STSTR_MUS
0x00000000000050a7:  BB EB 02             mov   bx, _commercial
0x00000000000050aa:  E8 3C 16             call  cht_GetParam_
0x00000000000050ad:  80 3F 00             cmp   byte ptr ds:[bx], 0
0x00000000000050b0:  74 43                je    label_29
0x00000000000050b2:  8A 46 F6             mov   al, byte ptr [bp - 0Ah]
0x00000000000050b5:  98                   cbw  
0x00000000000050b6:  2D 30 00             sub   ax, ASCII_0
0x00000000000050b9:  89 C2                mov   dx, ax
0x00000000000050bb:  C1 E2 02             shl   dx, 2
0x00000000000050be:  01 C2                add   dx, ax
0x00000000000050c0:  01 D2                add   dx, dx
0x00000000000050c2:  8A 46 F7             mov   al, byte ptr [bp - 9]
0x00000000000050c5:  89 D3                mov   bx, dx
0x00000000000050c7:  98                   cbw  
0x00000000000050c8:  83 C3 21             add   bx, 0x21 ; todo wot
0x00000000000050cb:  01 C3                add   bx, ax
0x00000000000050cd:  01 D0                add   ax, dx
0x00000000000050cf:  2D 30 00             sub   ax, ASCII_0
0x00000000000050d2:  8D 4F CF             lea   cx, [bx - ASCII_1]
0x00000000000050d5:  3D 23 00             cmp   ax, 35
0x00000000000050d8:  7E 0A                jle   label_30
0x00000000000050da:  BB 24 07             mov   bx, _player + PLAYER_T.player_message
0x00000000000050dd:  C7 07 E2 00          mov   word ptr ds:[bx], STSTR_NOMUS
0x00000000000050e1:  E9 21 FE             jmp   label_12
label_30:
0x00000000000050e4:  88 C8                mov   al, cl
0x00000000000050e6:  BA 01 00             mov   dx, 1
0x00000000000050e9:  30 E4                xor   ah, ah

0x00000000000050ec:  3E E8 52 44          call  S_ChangeMusic_
0x00000000000050f0:  E9 12 FE             jmp   label_12
jump_to_label_28:
0x00000000000050f3:  EB 5C                jmp   label_28
label_29:
0x00000000000050f5:  8A 46 F6             mov   al, byte ptr [bp - 0Ah]
0x00000000000050f8:  98                   cbw  
0x00000000000050f9:  2D 31 00             sub   ax, ASCII_1
0x00000000000050fc:  89 C2                mov   dx, ax
0x00000000000050fe:  C1 E2 03             shl   dx, 3
0x0000000000005101:  01 C2                add   dx, ax
0x0000000000005103:  8A 46 F7             mov   al, byte ptr [bp - 9]
0x0000000000005106:  89 D3                mov   bx, dx
0x0000000000005108:  98                   cbw  
0x0000000000005109:  43                   inc   bx
0x000000000000510a:  89 C1                mov   cx, ax
0x000000000000510c:  01 D0                add   ax, dx
0x000000000000510e:  83 E9 31             sub   cx, ASCII_1
0x0000000000005111:  2D 31 00             sub   ax, ASCII_1
0x0000000000005114:  01 D9                add   cx, bx
0x0000000000005116:  3D 1F 00             cmp   ax, 31
0x0000000000005119:  7E C9                jle   label_30
0x000000000000511b:  BB 24 07             mov   bx, _player + PLAYER_T.player_message
0x000000000000511e:  C7 07 E2 00          mov   word ptr ds:[bx], STSTR_NOMUS
0x0000000000005122:  E9 E0 FD             jmp   label_12
label_26:
0x0000000000005125:  8E 46 FE             mov   es, word ptr [bp - 2]
0x0000000000005128:  26 8A 45 01          mov   al, byte ptr es:[di + 1]
0x000000000000512c:  98                   cbw  
0x000000000000512d:  89 C2                mov   dx, ax
0x000000000000512f:  B8 30 00             mov   ax, CHEATID_NOCLIP
0x0000000000005132:  E8 52 15             call  cht_CheckCheat_
0x0000000000005135:  84 C0                test  al, al
0x0000000000005137:  75 03                jne   label_31
0x0000000000005139:  E9 27 FF             jmp   label_32
label_31:
0x000000000000513c:  BB 0B 07             mov   bx, _player + PLAYER_T.player_cheats
0x000000000000513f:  80 37 01             xor   byte ptr ds:[bx], 1
0x0000000000005142:  F6 07 01             test  byte ptr ds:[bx], 1
0x0000000000005145:  74 0A                je    label_28
0x0000000000005147:  BB 24 07             mov   bx, _player + PLAYER_T.player_message
0x000000000000514a:  C7 07 E7 00          mov   word ptr ds:[bx], STSTR_NCON
0x000000000000514e:  E9 B4 FD             jmp   label_12
label_28:
0x0000000000005151:  BB 24 07             mov   bx, _player + PLAYER_T.player_message
0x0000000000005154:  C7 07 E8 00          mov   word ptr ds:[bx], STSTR_NCOFF
0x0000000000005158:  E9 AA FD             jmp   label_12
label_9:
0x000000000000515b:  80 FB 01             cmp   bl, 1
0x000000000000515e:  74 09                je    label_33
0x0000000000005160:  C7 84 EE 06 01 00    mov   word ptr ds:[si + _player + PLAYER_T.player_powers], 1
0x0000000000005166:  E9 C8 FD             jmp   label_34
label_33:
0x0000000000005169:  C7 84 EE 06 00 00    mov   word ptr ds:[si + _player + PLAYER_T.player_powers], 0
0x000000000000516f:  E9 BF FD             jmp   label_34
label_11:
0x0000000000005172:  8E 46 FE             mov   es, word ptr [bp - 2]
0x0000000000005175:  26 8A 45 01          mov   al, byte ptr es:[di + 1]
0x0000000000005179:  98                   cbw  
0x000000000000517a:  89 C2                mov   dx, ax
0x000000000000517c:  B8 38 00             mov   ax, CHEATID_CHOPPERS
0x000000000000517f:  E8 05 15             call  cht_CheckCheat_
0x0000000000005182:  84 C0                test  al, al
0x0000000000005184:  74 17                je    label_35
0x0000000000005186:  BB 09 07             mov   bx, 0x709
0x0000000000005189:  C6 07 01             mov   byte ptr ds:[bx], 1
0x000000000000518c:  BB EE 06             mov   bx, _player + PLAYER_T.player_powers
0x000000000000518f:  C7 07 01 00          mov   word ptr ds:[bx], 1
0x0000000000005193:  BB 24 07             mov   bx, _player + PLAYER_T.player_message
0x0000000000005196:  C7 07 EB 00          mov   word ptr ds:[bx], STSTR_CHOPPERS
0x000000000000519a:  E9 BD FD             jmp   label_2
label_35:
0x000000000000519d:  8E 46 FE             mov   es, word ptr [bp - 2]
0x00000000000051a0:  26 8A 45 01          mov   al, byte ptr es:[di + 1]
0x00000000000051a4:  98                   cbw  
0x00000000000051a5:  89 C2                mov   dx, ax
0x00000000000051a7:  B8 40 00             mov   ax, CHEATID_MAPPOS
0x00000000000051aa:  E8 DA 14             call  cht_CheckCheat_
0x00000000000051ad:  84 C0                test  al, al
0x00000000000051af:  75 03                jne   label_36
0x00000000000051b1:  E9 A6 FD             jmp   label_2
label_36:
0x00000000000051b4:  BB 30 06             mov   bx, _playerMobj_pos
0x00000000000051b7:  8D 4E EC             lea   cx, [bp - 014h]
0x00000000000051ba:  C4 37                les   si, dword ptr ds:[bx]
0x00000000000051bc:  BB 01 00             mov   bx, 1
0x00000000000051bf:  26 8B 44 0E          mov   ax, word ptr es:[si + MOBJ_POS_T.mp_angle + 0]
0x00000000000051c3:  26 8B 54 10          mov   dx, word ptr es:[si + MOBJ_POS_T.mp_angle + 2]
0x00000000000051c7:  E8 97 24             call  locallib_printhex_
0x00000000000051ca:  8D 56 EC             lea   dx, [bp - 014h]
0x00000000000051cd:  BB 12 18             mov   bx, 0x1812
0x00000000000051d0:  B8 7C 1B             mov   ax, OFFSET _st_stuff_buf
0x00000000000051d3:  1E                   push  ds
0x00000000000051d4:  8C D9                mov   cx, ds
0x00000000000051d6:  52                   push  dx
0x00000000000051d7:  8C DA                mov   dx, ds
0x00000000000051d9:  E8 D8 23             call  combine_strings_
0x00000000000051dc:  BB 7C 1B             mov   bx, OFFSET _st_stuff_buf
0x00000000000051df:  1E                   push  ds
0x00000000000051e0:  8C D9                mov   cx, ds
0x00000000000051e2:  8C DA                mov   dx, ds
0x00000000000051e4:  68 19 18             push  0x1819
0x00000000000051e7:  89 D8                mov   ax, bx
0x00000000000051e9:  BE 30 06             mov   si, _playerMobj_pos
0x00000000000051ec:  E8 C5 23             call  combine_strings_
0x00000000000051ef:  C4 1C                les   bx, dword ptr ds:[si]
0x00000000000051f1:  8D 4E EC             lea   cx, [bp - 014h]
0x00000000000051f4:  26 8B 07             mov   ax, word ptr es:[bx]
0x00000000000051f7:  26 8B 57 02          mov   dx, word ptr es:[bx + 2]
0x00000000000051fb:  BB 01 00             mov   bx, 1
0x00000000000051fe:  E8 60 24             call  locallib_printhex_
0x0000000000005201:  8D 56 EC             lea   dx, [bp - 014h]
0x0000000000005204:  BB 7C 1B             mov   bx, OFFSET _st_stuff_buf
0x0000000000005207:  1E                   push  ds
0x0000000000005208:  8C D9                mov   cx, ds
0x000000000000520a:  52                   push  dx
0x000000000000520b:  89 D8                mov   ax, bx
0x000000000000520d:  8C DA                mov   dx, ds
0x000000000000520f:  E8 A2 23             call  combine_strings_
0x0000000000005212:  BB 7C 1B             mov   bx, OFFSET _st_stuff_buf
0x0000000000005215:  1E                   push  ds
0x0000000000005216:  8C D9                mov   cx, ds
0x0000000000005218:  8C DA                mov   dx, ds
0x000000000000521a:  68 22 18             push  0x1822
0x000000000000521d:  89 D8                mov   ax, bx
0x000000000000521f:  E8 92 23             call  combine_strings_
0x0000000000005222:  8D 4E EC             lea   cx, [bp - 014h]
0x0000000000005225:  89 F3                mov   bx, si
0x0000000000005227:  8B 34                mov   si, word ptr ds:[si]
0x0000000000005229:  8E 47 02             mov   es, word ptr ds:[bx + 2]
0x000000000000522c:  BB 01 00             mov   bx, 1
0x000000000000522f:  26 8B 44 04          mov   ax, word ptr es:[si + 4]
0x0000000000005233:  26 8B 54 06          mov   dx, word ptr es:[si + 6]
0x0000000000005237:  E8 27 24             call  locallib_printhex_
0x000000000000523a:  8D 56 EC             lea   dx, [bp - 014h]
0x000000000000523d:  BB 7C 1B             mov   bx, OFFSET _st_stuff_buf
0x0000000000005240:  1E                   push  ds
0x0000000000005241:  8C D9                mov   cx, ds
0x0000000000005243:  52                   push  dx
0x0000000000005244:  89 D8                mov   ax, bx
0x0000000000005246:  8C DA                mov   dx, ds
0x0000000000005248:  E8 69 23             call  combine_strings_
0x000000000000524b:  BB 7C 1B             mov   bx, OFFSET _st_stuff_buf
0x000000000000524e:  1E                   push  ds
0x000000000000524f:  8C D9                mov   cx, ds
0x0000000000005251:  8C DA                mov   dx, ds
0x0000000000005253:  68 26 18             push  0x1826
0x0000000000005256:  89 D8                mov   ax, bx
0x0000000000005258:  E8 59 23             call  combine_strings_
0x000000000000525b:  BB 26 07             mov   bx, _player + PLAYER_T.player_messagestring
0x000000000000525e:  C7 07 7C 1B          mov   word ptr ds:[bx], OFFSET _st_stuff_buf
0x0000000000005262:  E9 F5 FC             jmp   label_2
label_17:
0x0000000000005265:  8D 56 FA             lea   dx, [bp - 6]
0x0000000000005268:  B8 3C 00             mov   ax, CHEATID_CHANGE_LEVEL
0x000000000000526b:  B3 04                mov   bl, 4
0x000000000000526d:  E8 79 14             call  cht_GetParam_
0x0000000000005270:  8A 46 FA             mov   al, byte ptr [bp - 6]
0x0000000000005273:  BE EB 02             mov   si, _commercial
0x0000000000005276:  2C 30                sub   al, ASCII_0
0x0000000000005278:  80 3C 00             cmp   byte ptr ds:[si], 0
0x000000000000527b:  74 63                je    label_58
0x000000000000527d:  B4 0A                mov   ah, 10
0x000000000000527f:  F6 EC                imul  ah
0x0000000000005281:  02 46 FB             add   al, byte ptr [bp - 5]
0x0000000000005284:  30 D2                xor   dl, dl

label_16:
0x0000000000005286:  2C 30                sub   al, ASCII_0
0x0000000000005288:  BE E1 00             mov   si, _is_ultimate
0x000000000000528b:  80 3C 00             cmp   byte ptr ds:[si], 0
0x000000000000528e:  74 02                je    label_56
0x0000000000005290:  B3 05                mov   bl, 5
label_56:
0x0000000000005292:  BE EB 02             mov   si, _commercial
0x0000000000005295:  80 3C 00             cmp   byte ptr ds:[si], 0
0x0000000000005298:  75 10                jne   label_57
0x000000000000529a:  84 D2                test  dl, dl
0x000000000000529c:  7E 0C                jle   label_57
0x000000000000529e:  38 DA                cmp   dl, bl
0x00000000000052a0:  7D 08                jge   label_57
0x00000000000052a2:  84 C0                test  al, al
0x00000000000052a4:  7E 04                jle   label_57
0x00000000000052a6:  3C 0A                cmp   al, 10
0x00000000000052a8:  7C 13                jl    label_59
label_57:
0x00000000000052aa:  BB EB 02             mov   bx, _commercial
0x00000000000052ad:  80 3F 00             cmp   byte ptr ds:[bx], 0
0x00000000000052b0:  75 03                jne   label_60
label_55:
0x00000000000052b2:  E9 B9 FC             jmp   exit_st_responder_ret_0
label_60:
0x00000000000052b5:  84 C0                test  al, al
0x00000000000052b7:  7E F9                jle   label_55
0x00000000000052b9:  3C 28                cmp   al, 40
0x00000000000052bb:  7F F5                jg    label_55
label_59:
0x00000000000052bd:  BB 24 07             mov   bx, _player + PLAYER_T.player_message
0x00000000000052c0:  98                   cbw  
0x00000000000052c1:  C7 07 EC 00          mov   word ptr ds:[bx], STSTR_CLEV
0x00000000000052c5:  89 C3                mov   bx, ax
0x00000000000052c7:  88 D0                mov   al, dl
0x00000000000052c9:  98                   cbw  
0x00000000000052ca:  BE 31 01             mov   si, _gameskill
0x00000000000052cd:  89 C2                mov   dx, ax
0x00000000000052cf:  8A 04                mov   al, byte ptr ds:[si]
0x00000000000052d1:  30 E4                xor   ah, ah
0x00000000000052d4:  3E E8 D4 E5          call  G_DeferedInitNew_
0x00000000000052d8:  30 C0                xor   al, al
0x00000000000052da:  C9                   LEAVE_MACRO 
0x00000000000052db:  5F                   pop   di
0x00000000000052dc:  5E                   pop   si
0x00000000000052dd:  59                   pop   cx
0x00000000000052de:  5B                   pop   bx
0x00000000000052df:  C3                   ret   
label_58:
0x00000000000052e0:  88 C2                mov   dl, al
0x00000000000052e2:  8A 46 FB             mov   al, byte ptr [bp - 5]
0x00000000000052e5:  EB 9F                jmp   label_16

ENDP


PROC    ST_calcPainOffset_ NEAR
PUBLIC  ST_calcPainOffset_

0x00000000000052e8:  53                   push  bx
0x00000000000052e9:  51                   push  cx
0x00000000000052ea:  52                   push  dx
0x00000000000052eb:  BB E8 06             mov   bx, _player_health
0x00000000000052ee:  8B 07                mov   ax, word ptr ds:[bx]
0x00000000000052f0:  3D 64 00             cmp   ax, 100
0x00000000000052f3:  7E 10                jle   label_13
0x00000000000052f5:  BB 64 00             mov   bx, 100
label_15:
0x00000000000052f8:  3B 1E 5E 0F          cmp   bx, word ptr ds:[_st_calc_oldhealth]
0x00000000000052fc:  75 0B                jne   label_14
0x00000000000052fe:  A1 58 1C             mov   ax, word ptr ds:[_st_calc_lastcalc]
0x0000000000005301:  5A                   pop   dx
0x0000000000005302:  59                   pop   cx
0x0000000000005303:  5B                   pop   bx
0x0000000000005304:  C3                   ret   
label_13:
0x0000000000005305:  89 C3                mov   bx, ax
0x0000000000005307:  EB EF                jmp   label_15
label_14:
0x0000000000005309:  BA 64 00             mov   dx, 100
0x000000000000530c:  29 DA                sub   dx, bx
0x000000000000530e:  89 D0                mov   ax, dx
0x0000000000005310:  C1 E0 02             shl   ax, 2
0x0000000000005313:  01 D0                add   ax, dx
0x0000000000005315:  B9 65 00             mov   cx, 101
0x0000000000005318:  99                   cwd   
0x0000000000005319:  F7 F9                idiv  cx
0x000000000000531b:  C1 E0 03             shl   ax, 3
0x000000000000531e:  89 1E 5E 0F          mov   word ptr ds:[_st_calc_oldhealth], bx
0x0000000000005322:  A3 58 1C             mov   word ptr ds:[_st_calc_lastcalc], ax
0x0000000000005325:  A1 58 1C             mov   ax, word ptr ds:[_st_calc_lastcalc]
0x0000000000005328:  5A                   pop   dx
0x0000000000005329:  59                   pop   cx
0x000000000000532a:  5B                   pop   bx
0x000000000000532b:  C3                   ret   

ENDP


PROC    ST_updateFaceWidget_ NEAR
PUBLIC  ST_updateFaceWidget_


0x000000000000532c:  53                   push  bx
0x000000000000532d:  51                   push  cx
0x000000000000532e:  52                   push  dx
0x000000000000532f:  56                   push  si
0x0000000000005330:  80 3E 61 0F 0A       cmp   byte ptr ds:[_st_face_priority], 10
0x0000000000005335:  7D 0B                jge   label_37
0x0000000000005337:  BB E8 06             mov   bx, _player + PLAYER_T.player_health
0x000000000000533a:  83 3F 00             cmp   word ptr ds:[bx], 0
0x000000000000533d:  75 03                jne   label_37
0x000000000000533f:  E9 05 01             jmp   label_38
label_37:
0x0000000000005342:  80 3E 61 0F 09       cmp   byte ptr ds:[_st_face_priority], 9
0x0000000000005347:  7D 44                jge   label_39
0x0000000000005349:  BB 2A 07             mov   bx, _player + PLAYER_T.player_bonuscount
0x000000000000534c:  80 3F 00             cmp   byte ptr ds:[bx], 0
0x000000000000534f:  74 3C                je    label_39
0x0000000000005351:  30 F6                xor   dh, dh
0x0000000000005353:  30 D2                xor   dl, dl
label_61:
0x0000000000005355:  88 D0                mov   al, dl
0x0000000000005357:  98                   cbw  
0x0000000000005358:  89 C3                mov   bx, ax
0x000000000000535a:  8A 87 AA 1C          mov   al, byte ptr ds:[bx + _oldweaponsowned]
0x000000000000535e:  3A 87 02 07          cmp   al, byte ptr ds:[bx + _player + PLAYER_T.player_weaponowned]
0x0000000000005362:  74 0A                je    label_40
0x0000000000005364:  8A 87 02 07          mov   al, byte ptr ds:[bx + _player + PLAYER_T.player_weaponowned]
0x0000000000005368:  B6 01                mov   dh, 1
0x000000000000536a:  88 87 AA 1C          mov   byte ptr ds:[bx + _oldweaponsowned], al
label_40:
0x000000000000536e:  FE C2                inc   dl
0x0000000000005370:  80 FA 09             cmp   dl, 9
0x0000000000005373:  7C E0                jl    label_61
0x0000000000005375:  84 F6                test  dh, dh
0x0000000000005377:  74 14                je    label_39
0x0000000000005379:  C6 06 61 0F 08       mov   byte ptr ds:[_st_face_priority], 8
0x000000000000537e:  C7 06 58 0F 46 00    mov   word ptr ds:[_st_facecount], ST_EVILGRINCOUNT
0x0000000000005384:  E8 61 FF             call  ST_calcPainOffset_
0x0000000000005387:  05 06 00             add   ax, 6
0x000000000000538a:  A3 5A 0F             mov   word ptr ds:[_st_faceindex], ax
label_39:
0x000000000000538d:  80 3E 61 0F 08       cmp   byte ptr ds:[_st_face_priority], 8
0x0000000000005392:  7D 3D                jge   label_62
0x0000000000005394:  BB 28 07             mov   bx, _player + PLAYER_T.player_damagecount
0x0000000000005397:  83 3F 00             cmp   word ptr ds:[bx], 0
0x000000000000539a:  74 35                je    label_62
0x000000000000539c:  BB 2C 07             mov   bx, _player + PLAYER_T.player_attackerRef
0x000000000000539f:  8B 07                mov   ax, word ptr ds:[bx]
0x00000000000053a1:  85 C0                test  ax, ax
0x00000000000053a3:  74 2C                je    label_62
0x00000000000053a5:  BE F6 05             mov   si, _playerMobjRef
0x00000000000053a8:  3B 04                cmp   ax, word ptr ds:[si]
0x00000000000053aa:  74 25                je    label_62
0x00000000000053ac:  BB E8 06             mov   bx, _player + PLAYER_T.player_health
0x00000000000053af:  8B 07                mov   ax, word ptr ds:[bx]
0x00000000000053b1:  2B 06 56 0F          sub   ax, word ptr ds:[_st_oldhealth]
0x00000000000053b5:  C6 06 61 0F 07       mov   byte ptr ds:[_st_face_priority], 7
0x00000000000053ba:  3D 14 00             cmp   ax, 20
0x00000000000053bd:  7F 03                jg    label_87
0x00000000000053bf:  E9 C8 00             jmp   label_88
label_87:
0x00000000000053c2:  C7 06 58 0F 23 00    mov   word ptr ds:[_st_facecount], 0x23
0x00000000000053c8:  E8 1D FF             call  ST_calcPainOffset_
0x00000000000053cb:  05 05 00             add   ax, 5
0x00000000000053ce:  A3 5A 0F             mov   word ptr ds:[_st_faceindex], ax
label_62:
0x00000000000053d1:  80 3E 61 0F 07       cmp   byte ptr ds:[_st_face_priority], 7
0x00000000000053d6:  7D 2A                jge   label_89
0x00000000000053d8:  BB 28 07             mov   bx, _player + PLAYER_T.player_damagecount
0x00000000000053db:  83 3F 00             cmp   word ptr ds:[bx], 0
0x00000000000053de:  74 22                je    label_89
0x00000000000053e0:  BB E8 06             mov   bx, _player + PLAYER_T.player_health
0x00000000000053e3:  8B 07                mov   ax, word ptr ds:[bx]
0x00000000000053e5:  2B 06 56 0F          sub   ax, word ptr ds:[_st_oldhealth]
0x00000000000053e9:  3D 14 00             cmp   ax, 0x14
0x00000000000053ec:  7E 56                jle   jump_to_label_90
0x00000000000053ee:  C6 06 61 0F 07       mov   byte ptr ds:[_st_face_priority], 7
0x00000000000053f3:  C7 06 58 0F 23 00    mov   word ptr ds:[_st_facecount], 0x23
0x00000000000053f9:  E8 EC FE             call  ST_calcPainOffset_
0x00000000000053fc:  05 05 00             add   ax, 5
0x00000000000053ff:  A3 5A 0F             mov   word ptr ds:[_st_faceindex], ax
label_89:
0x0000000000005402:  80 3E 61 0F 06       cmp   byte ptr ds:[_st_face_priority], 6
0x0000000000005407:  7D 14                jge   label_91
0x0000000000005409:  BB 1C 07             mov   bx, 0x71c
0x000000000000540c:  80 3F 00             cmp   byte ptr ds:[bx], 0
0x000000000000540f:  74 49                je    jump_to_label_92
0x0000000000005411:  80 3E 60 0F FF       cmp   byte ptr ds:[0xf60], 0xff
0x0000000000005416:  75 45                jne   jump_to_label_93
0x0000000000005418:  C6 06 60 0F 46       mov   byte ptr ds:[0xf60], 0x46
label_91:
0x000000000000541d:  80 3E 61 0F 05       cmp   byte ptr ds:[_st_face_priority], 5
0x0000000000005422:  7D 10                jge   label_94
0x0000000000005424:  BB 0B 07             mov   bx, _player + PLAYER_T.player_cheats
0x0000000000005427:  F6 07 02             test  byte ptr ds:[bx], 2
0x000000000000542a:  75 34                jne   jump_to_label_95
0x000000000000542c:  BB EE 06             mov   bx, _player + PLAYER_T.player_powers
0x000000000000542f:  83 3F 00             cmp   word ptr ds:[bx], 0
0x0000000000005432:  75 2C                jne   jump_to_label_95
label_94:
0x0000000000005434:  83 3E 58 0F 00       cmp   word ptr ds:[_st_facecount], 0
0x0000000000005439:  74 28                je    label_96
0x000000000000543b:  FF 0E 58 0F          dec   word ptr ds:[_st_facecount]
0x000000000000543f:  5E                   pop   si
0x0000000000005440:  5A                   pop   dx
0x0000000000005441:  59                   pop   cx
0x0000000000005442:  5B                   pop   bx
0x0000000000005443:  C3                   ret   
jump_to_label_90:
0x0000000000005444:  E9 FC 00             jmp   label_90
label_38:
0x0000000000005447:  C6 06 61 0F 09       mov   byte ptr ds:[_st_face_priority], 9
0x000000000000544c:  C7 06 5A 0F 29 00    mov   word ptr ds:[_st_faceindex], ST_DEADFACE
0x0000000000005452:  C7 06 58 0F 01 00    mov   word ptr ds:[_st_facecount], 1
0x0000000000005458:  EB E1                jmp   0x543b
jump_to_label_92:
0x000000000000545a:  E9 1F 01             jmp   label_92
jump_to_label_93:
0x000000000000545d:  E9 F7 00             jmp   label_93
jump_to_label_95:
0x0000000000005460:  E9 21 01             jmp   label_95
label_96:
0x0000000000005463:  A0 C8 1C             mov   al, byte ptr ds:[_st_randomnumber]
0x0000000000005466:  30 E4                xor   ah, ah
0x0000000000005468:  BB 03 00             mov   bx, 3
0x000000000000546b:  99                   cwd   
0x000000000000546c:  F7 FB                idiv  bx
0x000000000000546e:  E8 77 FE             call  ST_calcPainOffset_
0x0000000000005471:  C7 06 58 0F 11 00    mov   word ptr ds:[_st_facecount], 0x11
0x0000000000005477:  01 D0                add   ax, dx
0x0000000000005479:  C6 06 61 0F 00       mov   byte ptr ds:[_st_face_priority], 0
0x000000000000547e:  A3 5A 0F             mov   word ptr ds:[_st_faceindex], ax
0x0000000000005481:  FF 0E 58 0F          dec   word ptr ds:[_st_facecount]
0x0000000000005485:  5E                   pop   si
0x0000000000005486:  5A                   pop   dx
0x0000000000005487:  59                   pop   cx
0x0000000000005488:  5B                   pop   bx
0x0000000000005489:  C3                   ret   
label_88:
0x000000000000548a:  BB 2C 07             mov   bx, _player + PLAYER_T.player_attackerRef
0x000000000000548d:  6B 1F 18             imul  bx, word ptr ds:[bx], SIZEOF_MOBJ_POS_T
0x0000000000005490:  B8 F5 6A             mov   ax, MOBJPOSLIST_6800_SEGMENT
0x0000000000005493:  8E C0                mov   es, ax
0x0000000000005495:  26 FF 77 06          push  word ptr es:[bx + 6]
0x0000000000005499:  26 FF 77 04          push  word ptr es:[bx + 4]
0x000000000000549d:  26 FF 77 02          push  word ptr es:[bx + 2]
0x00000000000054a1:  BE 30 06             mov   si, _playerMobj_pos
0x00000000000054a4:  26 FF 37             push  word ptr es:[bx]
0x00000000000054a7:  C4 1C                les   bx, dword ptr ds:[si]
0x00000000000054a9:  26 8B 47 04          mov   ax, word ptr es:[bx + 4]
0x00000000000054ad:  26 8B 4F 06          mov   cx, word ptr es:[bx + 6]
0x00000000000054b1:  26 8B 17             mov   dx, word ptr es:[bx]
0x00000000000054b4:  26 8B 77 02          mov   si, word ptr es:[bx + 2]
0x00000000000054b8:  89 C3                mov   bx, ax
0x00000000000054ba:  89 D0                mov   ax, dx
0x00000000000054bc:  89 F2                mov   dx, si
0x00000000000054be:  BE 30 06             mov   si, _playerMobj_pos
0x00000000000054c2:  3E E8 4D 61          call  R_PointToAngle2_
0x00000000000054c6:  C4 1C                les   bx, dword ptr ds:[si]
0x00000000000054c8:  26 3B 57 10          cmp   dx, word ptr es:[bx + 0x10]
0x00000000000054cc:  77 08                ja    0x54d6
0x00000000000054ce:  75 3C                jne   0x550c
0x00000000000054d0:  26 3B 47 0E          cmp   ax, word ptr es:[bx + 0xe]
0x00000000000054d4:  76 36                jbe   0x550c
0x00000000000054d6:  89 F3                mov   bx, si
0x00000000000054d8:  8B 34                mov   si, word ptr ds:[si]
0x00000000000054da:  8E 47 02             mov   es, word ptr ds:[bx + 2]
0x00000000000054dd:  26 2B 44 0E          sub   ax, word ptr es:[si + 0xe]
0x00000000000054e1:  26 1B 54 10          sbb   dx, word ptr es:[si + 0x10]
0x00000000000054e5:  81 FA 00 80          cmp   dx, 0x8000
0x00000000000054e9:  77 06                ja    0x54f1
0x00000000000054eb:  75 1B                jne   0x5508
0x00000000000054ed:  85 C0                test  ax, ax
0x00000000000054ef:  76 17                jbe   0x5508
0x00000000000054f1:  B3 01                mov   bl, 1
0x00000000000054f3:  C7 06 58 0F 23 00    mov   word ptr ds:[_st_facecount], 0x23
0x00000000000054f9:  E8 EC FD             call  ST_calcPainOffset_
0x00000000000054fc:  81 FA 00 20          cmp   dx, 0x2000
0x0000000000005500:  73 31                jae   0x5533
0x0000000000005502:  05 07 00             add   ax, 7
0x0000000000005505:  E9 C6 FE             jmp   0x53ce
0x0000000000005508:  30 DB                xor   bl, bl
0x000000000000550a:  EB E7                jmp   0x54f3
0x000000000000550c:  89 F3                mov   bx, si
0x000000000000550e:  8B 34                mov   si, word ptr ds:[si]
0x0000000000005510:  8E 47 02             mov   es, word ptr ds:[bx + 2]
0x0000000000005513:  26 8B 5C 0E          mov   bx, word ptr es:[si + 0xe]
0x0000000000005517:  29 C3                sub   bx, ax
0x0000000000005519:  89 D8                mov   ax, bx
0x000000000000551b:  26 8B 5C 10          mov   bx, word ptr es:[si + 0x10]
0x000000000000551f:  19 D3                sbb   bx, dx
0x0000000000005521:  89 DA                mov   dx, bx
0x0000000000005523:  81 FB 00 80          cmp   bx, 0x8000
0x0000000000005527:  72 C8                jb    0x54f1
0x0000000000005529:  75 04                jne   0x552f
0x000000000000552b:  85 C0                test  ax, ax
0x000000000000552d:  76 C2                jbe   0x54f1
0x000000000000552f:  30 DB                xor   bl, bl
0x0000000000005531:  EB C0                jmp   0x54f3
0x0000000000005533:  84 DB                test  bl, bl
0x0000000000005535:  74 06                je    0x553d
0x0000000000005537:  05 03 00             add   ax, 3
0x000000000000553a:  E9 91 FE             jmp   0x53ce
0x000000000000553d:  05 04 00             add   ax, 4
0x0000000000005540:  E9 8B FE             jmp   0x53ce
label_90:
0x0000000000005543:  C6 06 61 0F 06       mov   byte ptr ds:[_st_face_priority], 6
0x0000000000005548:  C7 06 58 0F 23 00    mov   word ptr ds:[_st_facecount], 0x23
0x000000000000554e:  E8 97 FD             call  ST_calcPainOffset_
0x0000000000005551:  05 07 00             add   ax, 7
0x0000000000005554:  E9 A8 FE             jmp   0x53ff
label_93:
0x0000000000005557:  FE 0E 60 0F          dec   byte ptr ds:[0xf60]
0x000000000000555b:  74 03                je    0x5560
0x000000000000555d:  E9 BD FE             jmp   0x541d
0x0000000000005560:  C6 06 61 0F 05       mov   byte ptr ds:[_st_face_priority], 5
0x0000000000005565:  E8 80 FD             call  ST_calcPainOffset_
0x0000000000005568:  C7 06 58 0F 01 00    mov   word ptr ds:[_st_facecount], 1
0x000000000000556e:  05 07 00             add   ax, 7
0x0000000000005571:  C6 06 60 0F 01       mov   byte ptr ds:[0xf60], 1
0x0000000000005576:  A3 5A 0F             mov   word ptr ds:[_st_faceindex], ax
0x0000000000005579:  E9 A1 FE             jmp   0x541d
label_92:
0x000000000000557c:  C6 06 60 0F FF       mov   byte ptr ds:[0xf60], 0xff
0x0000000000005581:  E9 99 FE             jmp   0x541d
label_95:
0x0000000000005584:  C6 06 61 0F 04       mov   byte ptr ds:[_st_face_priority], 4
0x0000000000005589:  C7 06 5A 0F 28 00    mov   word ptr ds:[_st_faceindex], 0x28
0x000000000000558f:  C7 06 58 0F 01 00    mov   word ptr ds:[_st_facecount], 1
0x0000000000005595:  FF 0E 58 0F          dec   word ptr ds:[_st_facecount]
0x0000000000005599:  5E                   pop   si
0x000000000000559a:  5A                   pop   dx
0x000000000000559b:  59                   pop   cx
0x000000000000559c:  5B                   pop   bx
0x000000000000559d:  C3                   ret   
ENDP


PROC    ST_updateWidgets_ NEAR
PUBLIC  ST_updateWidgets_

0x000000000000559e:  53                   push  bx
0x000000000000559f:  51                   push  cx
0x00000000000055a0:  52                   push  dx
0x00000000000055a1:  56                   push  si
0x00000000000055a2:  30 D2                xor   dl, dl
label_53:
0x00000000000055a4:  88 D0                mov   al, dl
0x00000000000055a6:  98                   cbw  
0x00000000000055a7:  89 C3                mov   bx, ax
0x00000000000055a9:  80 BF FA 06 00       cmp   byte ptr ds:[bx + _player + PLAYER_T.player_cards], 0
0x00000000000055ae:  74 2C                je    label_51
0x00000000000055b0:  89 C1                mov   cx, ax
label_54:
0x00000000000055b2:  88 D0                mov   al, dl
0x00000000000055b4:  98                   cbw  
0x00000000000055b5:  89 C6                mov   si, ax
0x00000000000055b7:  01 C6                add   si, ax
0x00000000000055b9:  89 C3                mov   bx, ax
0x00000000000055bb:  89 8C 4E 1C          mov   word ptr ds:[si + _keyboxes], cx
0x00000000000055bf:  80 BF FD 06 00       cmp   byte ptr ds:[bx + _player + PLAYER_T + player_cards + 3], 0
0x00000000000055c4:  74 07                je    label_52
0x00000000000055c6:  83 C3 03             add   bx, 3
0x00000000000055c9:  89 9C 4E 1C          mov   word ptr ds:[si + _keyboxes], bx
label_52:
0x00000000000055cd:  FE C2                inc   dl
0x00000000000055cf:  80 FA 03             cmp   dl, 3
0x00000000000055d2:  7C D0                jl    label_53
0x00000000000055d4:  E8 55 FD             call  ST_updateFaceWidget_
0x00000000000055d7:  5E                   pop   si
0x00000000000055d8:  5A                   pop   dx
0x00000000000055d9:  59                   pop   cx
0x00000000000055da:  5B                   pop   bx
0x00000000000055db:  C3                   ret   
label_51:
0x00000000000055dc:  B9 FF FF             mov   cx, -1
0x00000000000055df:  EB D1                jmp   label_54

ENDP


PROC    ST_Ticker_ NEAR
PUBLIC  ST_Ticker_

0x00000000000055e2:  53                   push  bx
0x00000000000055e4:  3E E8 E8 E4          call  M_Random_
0x00000000000055e8:  BB E8 06             mov   bx, _player + PLAYER_T.player_health
0x00000000000055eb:  A2 C8 1C             mov   byte ptr ds:[_st_randomnumber], al
0x00000000000055ee:  E8 AD FF             call  ST_updateWidgets_
0x00000000000055f1:  8B 1F                mov   bx, word ptr ds:[bx]
0x00000000000055f3:  89 1E 56 0F          mov   word ptr ds:[_st_oldhealth], bx
0x00000000000055f7:  5B                   pop   bx
0x00000000000055f8:  C3                   ret   

ENDP


PROC    ST_doPaletteStuff_ NEAR
PUBLIC  ST_doPaletteStuff_

0x00000000000055fa:  53                   push  bx
0x00000000000055fb:  52                   push  dx
0x00000000000055fc:  BB 28 07             mov   bx, _player + PLAYER_T.player_damagecount
0x00000000000055ff:  8B 07                mov   ax, word ptr ds:[bx]
0x0000000000005601:  BB F0 06             mov   bx, _player + PLAYER_T.player_powers + (2 * PW_STRENGTH)
0x0000000000005604:  83 3F 00             cmp   word ptr ds:[bx], 0
0x0000000000005607:  74 12                je    label_63
0x0000000000005609:  8B 17                mov   dx, word ptr ds:[bx]
0x000000000000560b:  BB 0C 00             mov   bx, 12  ; fade berserk out
0x000000000000560e:  C1 FA 06             sar   dx, 6
0x0000000000005611:  29 D3                sub   bx, dx
0x0000000000005613:  89 DA                mov   dx, bx
0x0000000000005615:  39 C3                cmp   bx, ax
0x0000000000005617:  7E 02                jle   label_63
0x0000000000005619:  89 D8                mov   ax, bx
label_63:
0x000000000000561b:  85 C0                test  ax, ax
0x000000000000561d:  74 17                je    label_64
0x000000000000561f:  05 07 00             add   ax, 7
0x0000000000005622:  C1 F8 03             sar   ax, 3
0x0000000000005625:  3C 08                cmp   al, 8
0x0000000000005627:  7C 02                jl    label_65
0x0000000000005629:  B0 07                mov   al, 7
label_65:
0x000000000000562b:  FE C0                inc   al
0x000000000000562d:  3A 06 5C 0F          cmp   al, byte ptr ds:[_st_palette]
0x0000000000005631:  75 46                jne   label_66
0x0000000000005633:  5A                   pop   dx
0x0000000000005634:  5B                   pop   bx
0x0000000000005635:  C3                   ret   
label_64:
0x0000000000005636:  BB 2A 07             mov   bx, _player + PLAYER_T.player_bonuscount
0x0000000000005639:  8A 07                mov   al, byte ptr ds:[bx]
0x000000000000563b:  84 C0                test  al, al
0x000000000000563d:  74 18                je    label_69
0x000000000000563f:  98                   cbw  
0x0000000000005640:  05 07 00             add   ax, 7
0x0000000000005643:  C1 F8 03             sar   ax, 3
0x0000000000005646:  3C 04                cmp   al, 4
0x0000000000005648:  7C 02                jl    label_70
0x000000000000564a:  B0 03                mov   al, 3
label_70:
0x000000000000564c:  04 09                add   al, 9
0x000000000000564e:  3A 06 5C 0F          cmp   al, byte ptr ds:[_st_palette]
0x0000000000005652:  75 25                jne   label_66
0x0000000000005654:  5A                   pop   dx
0x0000000000005655:  5B                   pop   bx
0x0000000000005656:  C3                   ret   
label_69:
0x0000000000005657:  BB F4 06             mov   bx, _player + PLAYER_T.player_powers + (2 * PW_IRONFEET)
0x000000000000565a:  81 3F 80 00          cmp   word ptr ds:[bx], 128
0x000000000000565e:  7E 0B                jle   label_68
label_67:
0x0000000000005660:  B0 0D                mov   al, RADIATIONPAL
0x0000000000005662:  3A 06 5C 0F          cmp   al, byte ptr ds:[_st_palette]
0x0000000000005666:  75 11                jne   label_66
0x0000000000005668:  5A                   pop   dx
0x0000000000005669:  5B                   pop   bx
0x000000000000566a:  C3                   ret   
label_68:
0x000000000000566b:  F6 07 08             test  byte ptr ds:[bx], 8
0x000000000000566e:  75 F0                jne   label_67
0x0000000000005670:  3A 06 5C 0F          cmp   al, byte ptr ds:[_st_palette]
0x0000000000005674:  75 03                jne   label_66
0x0000000000005676:  5A                   pop   dx
0x0000000000005677:  5B                   pop   bx
0x0000000000005678:  C3                   ret   
label_66:
0x0000000000005679:  A2 5C 0F             mov   byte ptr ds:[_st_palette], al
0x000000000000567c:  98                   cbw  
0x000000000000567e:  3E E8 83 1D          call  I_SetPalette_
0x0000000000005682:  5A                   pop   dx
0x0000000000005683:  5B                   pop   bx
0x0000000000005684:  C3                   ret   

ENDP


PROC    STlib_updateflag_ NEAR
PUBLIC  STlib_updateflag_

0x0000000000005686:  80 3E D0 1C 00       cmp   byte ptr ds:[_updatedthisframe], 0
0x000000000000568b:  74 01                jne   exit_updateflag
0x000000000000568f:  E8 E5 6A             call  Z_QuickMapStatus_
0x0000000000005693:  C6 06 D0 1C 01       mov   byte ptr ds:[_updatedthisframe], 1
exit_updateflag:
0x0000000000005698:  C3                   ret   


ENDP


PROC    STlib_updateMultIcon_ NEAR
PUBLIC  STlib_updateMultIcon_

0x000000000000569a:  51                   push  cx
0x000000000000569b:  56                   push  si
0x000000000000569c:  57                   push  di
0x000000000000569d:  55                   push  bp
0x000000000000569e:  89 E5                mov   bp, sp
0x00000000000056a0:  83 EC 0A             sub   sp, 0Ah
0x00000000000056a3:  89 C6                mov   si, ax
0x00000000000056a5:  89 56 FC             mov   word ptr [bp - 4], dx
0x00000000000056a8:  88 5E FE             mov   byte ptr [bp - 2], bl
0x00000000000056ab:  8B 44 04             mov   ax, word ptr ds:[si + 4]
0x00000000000056ae:  39 D0                cmp   ax, dx
0x00000000000056b0:  74 0B                je    label_72
label_74:
0x00000000000056b2:  83 7E FC FF          cmp   word ptr [bp - 4], -1
0x00000000000056b6:  75 0E                jne   label_73
exit_updatemulticon:
0x00000000000056b8:  C9                   LEAVE_MACRO 
0x00000000000056b9:  5F                   pop   di
0x00000000000056ba:  5E                   pop   si
0x00000000000056bb:  59                   pop   cx
0x00000000000056bc:  C3                   ret   
label_72:
0x00000000000056bd:  80 3E C9 1C 00       cmp   byte ptr ds:[_do_st_refresh], 0
0x00000000000056c2:  75 EE                jne   label_74
0x00000000000056c4:  EB F2                jmp   exit_updatemulticon
label_73:
0x00000000000056c6:  E8 BD FF             call  STlib_updateflag_
0x00000000000056c9:  80 7E FE 00          cmp   byte ptr [bp - 2], 0
0x00000000000056cd:  75 5E                jne   label_75
0x00000000000056cf:  8B 44 04             mov   ax, word ptr ds:[si + 4]
0x00000000000056d2:  3D FF FF             cmp   ax, -1
0x00000000000056d5:  74 56                je    label_75
0x00000000000056d7:  89 C3                mov   bx, ax
0x00000000000056d9:  01 C3                add   bx, ax
0x00000000000056db:  8B 44 06             mov   ax, word ptr ds:[si + 6]
0x00000000000056de:  01 C3                add   bx, ax
0x00000000000056e0:  B8 00 70             mov   ax, ST_GRAPHICS_SEGMENT
0x00000000000056e3:  8B 1F                mov   bx, word ptr ds:[bx]
0x00000000000056e5:  8E C0                mov   es, ax
0x00000000000056e7:  8B 44 02             mov   ax, word ptr ds:[si + 2]
0x00000000000056ea:  8B 3C                mov   di, word ptr ds:[si]
0x00000000000056ec:  89 46 FA             mov   word ptr [bp - 6], ax
0x00000000000056ef:  26 8B 47 06          mov   ax, word ptr es:[bx + 6]
0x00000000000056f3:  26 2B 7F 04          sub   di, word ptr es:[bx + 4]
0x00000000000056f7:  29 46 FA             sub   word ptr [bp - 6], ax
0x00000000000056fa:  26 8B 07             mov   ax, word ptr es:[bx]
0x00000000000056fd:  8B 56 FA             mov   dx, word ptr [bp - 6]
0x0000000000005700:  89 46 F8             mov   word ptr [bp - 8], ax
0x0000000000005703:  26 8B 47 02          mov   ax, word ptr es:[bx + 2]
0x0000000000005707:  8B 5E F8             mov   bx, word ptr [bp - 8]
0x000000000000570a:  89 46 F6             mov   word ptr [bp - 0Ah], ax
0x000000000000570d:  89 C1                mov   cx, ax
0x000000000000570f:  89 F8                mov   ax, di

0x0000000000005712:  3E E8 D9 67          call  V_MarkRect_
0x0000000000005716:  69 56 FA 40 01       imul  dx, word ptr [bp - 6], SCREENWIDTH
0x000000000000571b:  01 FA                add   dx, di
0x000000000000571d:  8B 4E F6             mov   cx, word ptr [bp - 0Ah]
0x0000000000005720:  89 D0                mov   ax, dx
0x0000000000005722:  8B 5E F8             mov   bx, word ptr [bp - 8]
0x0000000000005725:  2D 00 D2             sub   ax, ST_Y * SCREENWIDTH ; 0D200

0x0000000000005729:  E8 E1 67             call  V_CopyRect_
label_75:
0x000000000000572d:  8A 46 FE             mov   al, byte ptr [bp - 2]
0x0000000000005730:  8B 56 FC             mov   dx, word ptr [bp - 4]
0x0000000000005733:  98                   cbw  
0x0000000000005734:  29 C2                sub   dx, ax
0x0000000000005736:  89 D0                mov   ax, dx
0x0000000000005738:  8B 5C 06             mov   bx, word ptr ds:[si + 6]
0x000000000000573b:  01 D0                add   ax, dx
0x000000000000573d:  01 C3                add   bx, ax
0x000000000000573f:  68 00 70             push  ST_GRAPHICS_SEGMENT
0x0000000000005742:  8B 07                mov   ax, word ptr ds:[bx]
0x0000000000005744:  8B 54 02             mov   dx, word ptr ds:[si + 2]
0x0000000000005747:  50                   push  ax
0x0000000000005748:  31 DB                xor   bx, bx
0x000000000000574a:  8B 04                mov   ax, word ptr ds:[si]

0x000000000000574d:  E8 BA 62             call  V_DrawPatch_

0x0000000000005751:  8B 46 FC             mov   ax, word ptr [bp - 4]
0x0000000000005754:  89 44 04             mov   word ptr ds:[si + 4], ax
0x0000000000005757:  C9                   LEAVE_MACRO 
0x0000000000005758:  5F                   pop   di
0x0000000000005759:  5E                   pop   si
0x000000000000575a:  59                   pop   cx
0x000000000000575b:  C3                   ret   


ENDP


PROC    STlib_drawNum_ NEAR
PUBLIC  STlib_drawNum_


0x000000000000575c:  53                   push  bx
0x000000000000575d:  51                   push  cx
0x000000000000575e:  56                   push  si
0x000000000000575f:  57                   push  di
0x0000000000005760:  55                   push  bp
0x0000000000005761:  89 E5                mov   bp, sp
0x0000000000005763:  83 EC 0A             sub   sp, 0Ah
0x0000000000005766:  89 C7                mov   di, ax
0x0000000000005768:  89 D6                mov   si, dx
0x000000000000576a:  8A 45 04             mov   al, byte ptr ds:[di + 4]
0x000000000000576d:  88 46 FC             mov   byte ptr [bp - 4], al
0x0000000000005770:  3B 55 06             cmp   dx, word ptr ds:[di + 6]
0x0000000000005773:  75 0A                jne   label_76
0x0000000000005775:  80 3E C9 1C 00       cmp   byte ptr ds:[_do_st_refresh], 0
0x000000000000577a:  75 03                jne   label_76
0x000000000000577c:  E9 8B 00             jmp   exit_stlib_drawnum
label_76:
0x000000000000577f:  E8 04 FF             call  STlib_updateflag_
0x0000000000005782:  8B 5D 08             mov   bx, word ptr ds:[di + 8]
0x0000000000005785:  B8 00 70             mov   ax, ST_GRAPHICS_SEGMENT
0x0000000000005788:  8B 1F                mov   bx, word ptr ds:[bx]
0x000000000000578a:  8E C0                mov   es, ax
0x000000000000578c:  26 8B 07             mov   ax, word ptr es:[bx]
0x000000000000578f:  89 46 FA             mov   word ptr [bp - 6], ax
0x0000000000005792:  26 8B 47 02          mov   ax, word ptr es:[bx + 2]
0x0000000000005796:  89 46 F8             mov   word ptr [bp - 8], ax
0x0000000000005799:  89 75 06             mov   word ptr ds:[di + 6], si
0x000000000000579c:  85 F6                test  si, si
0x000000000000579e:  7D 10                jge   label_77
0x00000000000057a0:  80 7E FC 02          cmp   byte ptr [bp - 4], 2
0x00000000000057a4:  75 6A                jne   label_78
0x00000000000057a6:  83 FE F7             cmp   si, -9
0x00000000000057a9:  7D 65                jge   label_78
0x00000000000057ab:  BE F7 FF             mov   si, -9
neg_si:
0x00000000000057ae:  F7 DE                neg   si
label_77:
0x00000000000057b0:  8A 46 FA             mov   al, byte ptr [bp - 6]
0x00000000000057b3:  F6 66 FC             mul   byte ptr [bp - 4]
0x00000000000057b6:  88 46 FE             mov   byte ptr [bp - 2], al
0x00000000000057b9:  88 C3                mov   bl, al
0x00000000000057bb:  8B 05                mov   ax, word ptr ds:[di]
0x00000000000057bd:  30 FF                xor   bh, bh
0x00000000000057bf:  8B 4E F8             mov   cx, word ptr [bp - 8]
0x00000000000057c2:  29 D8                sub   ax, bx
0x00000000000057c4:  8B 55 02             mov   dx, word ptr ds:[di + 2]
0x00000000000057c7:  89 46 F6             mov   word ptr [bp - 0Ah], ax

0x00000000000057cb:  E8 21 67             call  V_MarkRect_
0x00000000000057cf:  69 55 02 40 01       imul  dx, word ptr ds:[di + 2], SCREENWIDTH
0x00000000000057d4:  8B 45 02             mov   ax, word ptr ds:[di + 2]
0x00000000000057d7:  2D A8 00             sub   ax, ST_Y
0x00000000000057da:  69 C0 40 01          imul  ax, ax, SCREENWIDTH
0x00000000000057de:  8A 5E FE             mov   bl, byte ptr [bp - 2]
0x00000000000057e1:  8B 4E F8             mov   cx, word ptr [bp - 8]
0x00000000000057e4:  30 FF                xor   bh, bh
0x00000000000057e6:  03 56 F6             add   dx, word ptr [bp - 0Ah]
0x00000000000057e9:  03 46 F6             add   ax, word ptr [bp - 0Ah]
0x00000000000057ed:  E8 1D 67             call  V_CopyRect_
0x00000000000057f1:  81 FE CA 07          cmp   si, 1994
0x00000000000057f5:  74 13                je    exit_stlib_drawnum
0x00000000000057f7:  8B 0D                mov   cx, word ptr ds:[di]
0x00000000000057f9:  85 F6                test  si, si
0x00000000000057fb:  74 23                je    label_80
label_79:
0x00000000000057fd:  85 F6                test  si, si
0x00000000000057ff:  74 09                je    exit_stlib_drawnum
0x0000000000005801:  FE 4E FC             dec   byte ptr [bp - 4]
0x0000000000005804:  80 7E FC FF          cmp   byte ptr [bp - 4], -1
0x0000000000005808:  75 30                jne   label_81
exit_stlib_drawnum:
0x000000000000580a:  C9                   LEAVE_MACRO 
0x000000000000580b:  5F                   pop   di
0x000000000000580c:  5E                   pop   si
0x000000000000580d:  59                   pop   cx
0x000000000000580e:  5B                   pop   bx
0x000000000000580f:  C3                   ret   
label_78:
0x0000000000005810:  80 7E FC 03          cmp   byte ptr [bp - 4], 3
0x0000000000005814:  75 98                jne   neg_si
0x0000000000005816:  83 FE 9D             cmp   si, -99
0x0000000000005819:  7D 93                jge   neg_si
0x000000000000581b:  BE 9D FF             mov   si, -99
0x000000000000581e:  EB 8E                jmp   neg_si
label_80:
0x0000000000005820:  8B 5D 08             mov   bx, word ptr ds:[di + 8]
0x0000000000005823:  68 00 70             push  ST_GRAPHICS_SEGMENT
0x0000000000005826:  8B 07                mov   ax, word ptr ds:[bx]
0x0000000000005828:  8B 55 02             mov   dx, word ptr ds:[di + 2]
0x000000000000582b:  50                   push  ax
0x000000000000582c:  89 C8                mov   ax, cx
0x000000000000582e:  31 DB                xor   bx, bx
0x0000000000005830:  2B 46 FA             sub   ax, word ptr [bp - 6]
0x0000000000005834:  3E E8 D2 61          call  V_DrawPatch_
0x0000000000005838:  EB C3                jmp   label_79
label_81:
0x000000000000583a:  89 F0                mov   ax, si
0x000000000000583c:  BB 0A 00             mov   bx, 10
0x000000000000583f:  99                   cwd   
0x0000000000005840:  F7 FB                idiv  bx
0x0000000000005842:  8B 5D 08             mov   bx, word ptr ds:[di + 8]
0x0000000000005845:  01 D2                add   dx, dx
0x0000000000005847:  68 00 70             push  ST_GRAPHICS_SEGMENT
0x000000000000584a:  01 D3                add   bx, dx
0x000000000000584c:  2B 4E FA             sub   cx, word ptr [bp - 6]
0x000000000000584f:  8B 17                mov   dx, word ptr ds:[bx]
0x0000000000005851:  89 C8                mov   ax, cx
0x0000000000005853:  52                   push  dx
0x0000000000005854:  31 DB                xor   bx, bx
0x0000000000005856:  8B 55 02             mov   dx, word ptr ds:[di + 2]
0x000000000000585a:  3E E8 AC 61          call  V_DrawPatch_
0x000000000000585e:  89 F0                mov   ax, si
0x0000000000005860:  BB 0A 00             mov   bx, 10
0x0000000000005863:  99                   cwd   
0x0000000000005864:  F7 FB                idiv  bx
0x0000000000005866:  89 C6                mov   si, ax
0x0000000000005868:  EB 93                jmp   label_79


ENDP


PROC    STlib_updatePercent_ NEAR
PUBLIC  STlib_updatePercent_


0x000000000000586a:  53                   push  bx
0x000000000000586b:  51                   push  cx
0x000000000000586c:  56                   push  si
0x000000000000586d:  89 C6                mov   si, ax
0x000000000000586f:  89 D1                mov   cx, dx
0x0000000000005871:  80 3E C9 1C 00       cmp   byte ptr ds:[_do_st_refresh], 0
0x0000000000005876:  75 0B                jne   label_82
0x0000000000005878:  89 CA                mov   dx, cx
0x000000000000587a:  89 F0                mov   ax, si
0x000000000000587c:  E8 DD FE             call  STlib_drawNum_
0x000000000000587f:  5E                   pop   si
0x0000000000005880:  59                   pop   cx
0x0000000000005881:  5B                   pop   bx
0x0000000000005882:  C3                   ret   
label_82:
0x0000000000005883:  E8 00 FE             call  STlib_updateflag_
0x0000000000005886:  8B 5C 0A             mov   bx, word ptr ds:[si + ST_PERCENT_T.st_percent_patch_offset]
0x0000000000005889:  68 00 70             push  ST_GRAPHICS_SEGMENT
0x000000000000588c:  8B 07                mov   ax, word ptr ds:[bx]
0x000000000000588e:  8B 54 02             mov   dx, word ptr ds:[si + 2]
0x0000000000005891:  50                   push  ax
0x0000000000005892:  31 DB                xor   bx, bx
0x0000000000005894:  8B 04                mov   ax, word ptr ds:[si]

0x0000000000005897:  E8 70 61             call  V_DrawPatch_

0x000000000000589b:  89 CA                mov   dx, cx
0x000000000000589d:  89 F0                mov   ax, si
0x000000000000589f:  E8 BA FE             call  STlib_drawNum_
0x00000000000058a2:  5E                   pop   si
0x00000000000058a3:  59                   pop   cx
0x00000000000058a4:  5B                   pop   bx
0x00000000000058a5:  C3                   ret   

ENDP


PROC    ST_drawWidgets_ NEAR
PUBLIC  ST_drawWidgets_

0x00000000000058a6:  53                   push  bx
0x00000000000058a7:  51                   push  cx
0x00000000000058a8:  52                   push  dx
0x00000000000058a9:  56                   push  si
0x00000000000058aa:  80 3E CF 1C 00       cmp   byte ptr ds:[_st_statusbaron], 0
0x00000000000058af:  75 03                jne   label_49
0x00000000000058b1:  E9 BA 00             jmp   exit_st_drawwidgets
label_49:
0x00000000000058b4:  BB 00 07             mov   bx, _player + PLAYER_T.player_readyweapon
0x00000000000058b7:  8A 07                mov   al, byte ptr ds:[bx]
0x00000000000058b9:  30 E4                xor   ah, ah
0x00000000000058bb:  6B D8 0B             imul  bx, ax, SIZEOF_WEAPONINFO_T
0x00000000000058be:  8A AF 58 07          mov   ch, byte ptr ds:[bx + _weaponinfo]
0x00000000000058c2:  30 C9                xor   cl, cl
label_83:
0x00000000000058c4:  88 C8                mov   al, cl
0x00000000000058c6:  98                   cbw  
0x00000000000058c7:  89 C3                mov   bx, ax
0x00000000000058c9:  01 C3                add   bx, ax
0x00000000000058cb:  6B F0 0A             imul  si, ax, SIZEOF_ST_NUMBER_T
0x00000000000058ce:  B8 68 1A             mov   ax, _w_ammo
0x00000000000058d1:  8B 97 0C 07          mov   dx, word ptr ds:[bx + _player + PLAYER_T.player_ammo]
0x00000000000058d5:  01 F0                add   ax, si
0x00000000000058d7:  E8 82 FE             call  STlib_drawNum_
0x00000000000058da:  B8 F8 1A             mov   ax, _w_maxammo
0x00000000000058dd:  8B 97 14 07          mov   dx, word ptr ds:[bx + _player + PLAYER_T.player_maxammo]
0x00000000000058e1:  01 F0                add   ax, si
0x00000000000058e3:  FE C1                inc   cl
0x00000000000058e5:  E8 74 FE             call  STlib_drawNum_
0x00000000000058e8:  80 F9 04             cmp   cl, 4
0x00000000000058eb:  7C D7                jl    label_83
0x00000000000058ed:  80 FD 05             cmp   ch, 5
0x00000000000058f0:  74 03                je    label_84
0x00000000000058f2:  E9 7E 00             jmp   label_85
label_84:
0x00000000000058f5:  BA CA 07             mov   dx, 1994
0x00000000000058f8:  B8 44 1C             mov   ax, _w_ready
label_86:
0x00000000000058fb:  E8 5E FE             call  STlib_drawNum_
0x00000000000058fe:  BB E8 06             mov   bx, _player + PLAYER_T.player_health
0x0000000000005901:  B8 B0 1B             mov   ax, OFFSET _w_health
0x0000000000005904:  8B 17                mov   dx, word ptr ds:[bx]
0x0000000000005906:  E8 61 FF             call  STlib_updatePercent_
0x0000000000005909:  BB EA 06             mov   bx, _player + PLAYER_T.player_armorpoints
0x000000000000590c:  B8 C8 1B             mov   ax, OFFSET _w_armor
0x000000000000590f:  8B 17                mov   dx, word ptr ds:[bx]
0x0000000000005911:  E8 56 FF             call  STlib_updatePercent_
0x0000000000005914:  BB 01 00             mov   bx, 1
0x0000000000005917:  B8 F0 1A             mov   ax, OFFSET _w_armsbg
0x000000000000591a:  89 DA                mov   dx, bx
0x000000000000591c:  30 C9                xor   cl, cl
0x000000000000591e:  E8 79 FD             call  STlib_updateMultIcon_
label_71:
0x0000000000005921:  88 C8                mov   al, cl
0x0000000000005923:  98                   cbw  
0x0000000000005924:  89 C3                mov   bx, ax
0x0000000000005926:  BE 90 1A             mov   si, OFFSET _w_arms
0x0000000000005929:  8A 87 03 07          mov   al, byte ptr ds:[bx + _player + PLAYER_T._player_weaponowned + 1]
0x000000000000592d:  C1 E3 03             shl   bx, 3
0x0000000000005930:  98                   cbw  
0x0000000000005931:  01 DE                add   si, bx
0x0000000000005933:  89 C2                mov   dx, ax
0x0000000000005935:  89 F0                mov   ax, si
0x0000000000005937:  31 DB                xor   bx, bx
0x0000000000005939:  FE C1                inc   cl
0x000000000000593b:  E8 5C FD             call  STlib_updateMultIcon_
0x000000000000593e:  80 F9 06             cmp   cl, 6
0x0000000000005941:  7C DE                jl    label_71
0x0000000000005943:  B8 60 1A             mov   ax, OFFSET _w_faces
0x0000000000005946:  8B 16 5A 0F          mov   dx, word ptr ds:[_st_faceindex]
0x000000000000594a:  31 DB                xor   bx, bx
0x000000000000594c:  E8 4B FD             call  STlib_updateMultIcon_
0x000000000000594f:  30 C9                xor   cl, cl
label_50:
0x0000000000005951:  88 C8                mov   al, cl
0x0000000000005953:  98                   cbw  
0x0000000000005954:  89 C3                mov   bx, ax
0x0000000000005956:  01 C3                add   bx, ax
0x0000000000005958:  C1 E0 03             shl   ax, 3
0x000000000000595b:  8B 97 4E 1C          mov   dx, word ptr ds:[bx + _keyboxes]
0x000000000000595f:  05 C0 1A             add   ax, OFFSET _w_keyboxes
0x0000000000005962:  31 DB                xor   bx, bx
0x0000000000005964:  FE C1                inc   cl
0x0000000000005966:  E8 31 FD             call  STlib_updateMultIcon_
0x0000000000005969:  80 F9 03             cmp   cl, 3
0x000000000000596c:  7C E3                jl    label_50
exit_st_drawwidgets:
0x000000000000596e:  5E                   pop   si
0x000000000000596f:  5A                   pop   dx
0x0000000000005970:  59                   pop   cx
0x0000000000005971:  5B                   pop   bx
0x0000000000005972:  C3                   ret   
label_85:
0x0000000000005973:  88 E8                mov   al, ch
0x0000000000005975:  98                   cbw  
0x0000000000005976:  89 C3                mov   bx, ax
0x0000000000005978:  01 C3                add   bx, ax
0x000000000000597a:  B8 44 1C             mov   ax, _w_ready
0x000000000000597d:  8B 97 0C 07          mov   dx, word ptr ds:[bx + _player + PLAYER_T.player_ammo]
0x0000000000005981:  E9 77 FF             jmp   label_86


ENDP


PROC    ST_Drawer_ NEAR
PUBLIC  ST_Drawer_

0x0000000000005984:  53                   push  bx
0x0000000000005985:  84 C0                test  al, al
0x0000000000005987:  75 43                jne   label_42
label_45:
0x0000000000005989:  B0 01                mov   al, 1
label_46:
0x000000000000598b:  A2 CF 1C             mov   byte ptr ds:[_st_statusbaron], al
0x000000000000598e:  A0 D1 1C             mov   al, byte ptr ds:[_st_firsttime]
0x0000000000005991:  84 C0                test  al, al
0x0000000000005993:  74 42                je    label_43
label_47:
0x0000000000005995:  B0 01                mov   al, 1
label_48:
0x0000000000005997:  C6 06 D0 1C 00       mov   byte ptr ds:[_updatedthisframe], 0
0x000000000000599c:  A2 D1 1C             mov   byte ptr ds:[_st_firsttime], al
0x000000000000599f:  E8 58 FC             call  ST_doPaletteStuff_
0x00000000000059a2:  A0 D1 1C             mov   al, byte ptr ds:[_st_firsttime]
0x00000000000059a5:  84 C0                test  al, al
0x00000000000059a7:  74 34                je    label_44
0x00000000000059a9:  C6 06 D1 1C 00       mov   byte ptr ds:[_st_firsttime], 0
0x00000000000059ae:  C6 06 D0 1C 01       mov   byte ptr ds:[_updatedthisframe], 1

0x00000000000059b4:  3E E8 BF 67          call  Z_QuickMapStatus_
0x00000000000059b8:  E8 A5 F4             call  ST_refreshBackground_  ; todo inline?
0x00000000000059bb:  C6 06 C9 1C 01       mov   byte ptr ds:[_do_st_refresh], 1
label_41:
0x00000000000059c0:  E8 E3 FE             call  ST_drawWidgets_
0x00000000000059c3:  80 3E D0 1C 00       cmp   byte ptr ds:[_updatedthisframe], 0
0x00000000000059c8:  75 18                jne   do_quickmapphysics
0x00000000000059ca:  5B                   pop   bx
0x00000000000059cb:  C3                   ret   
label_42:
0x00000000000059cc:  BB EA 02             mov   bx, _automapactive
0x00000000000059cf:  8A 07                mov   al, byte ptr ds:[bx]
0x00000000000059d1:  84 C0                test  al, al
0x00000000000059d3:  75 B4                jne   label_45
0x00000000000059d5:  EB B4                jmp   label_46
label_43:
0x00000000000059d7:  84 D2                test  dl, dl
0x00000000000059d9:  75 BA                jne   label_47
0x00000000000059db:  EB BA                jmp   label_48
label_44:
0x00000000000059dd:  A2 C9 1C             mov   byte ptr ds:[_do_st_refresh], al
0x00000000000059e0:  EB DE                jmp   label_41
do_quickmapphysics:
0x00000000000059e3:  E8 B0 66             call  Z_QuickMapPhysics_
0x00000000000059e7:  5B                   pop   bx
0x00000000000059e8:  C3                   ret   


PROC    ST_STUFF_ENDMARKER_ NEAR
PUBLIC  ST_STUFF_ENDMARKER_
ENDP


ENDP

END
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


EXTRN S_StartSoundWithParams_:PROC
EXTRN P_RemoveThinker_:PROC
EXTRN P_FindHighestOrLowestFloorSurrounding_:NEAR
EXTRN P_FindMinSurroundingLight_:NEAR
EXTRN P_FindSectorsFromLineTag_:NEAR
EXTRN P_FindNextHighestFloor_:NEAR
EXTRN P_CreateThinker_:FAR
EXTRN T_MovePlaneFloorUp_:NEAR
EXTRN T_MovePlaneFloorDown_:NEAR
EXTRN P_Random_:NEAR
EXTRN P_UpdateThinkerFunc_:NEAR


.DATA

EXTRN _secretexit:BYTE

.CODE




PROC    P_USER_STARTMARKER_ NEAR
PUBLIC  P_USER_STARTMARKER_
ENDP




PROC    P_Thrust_ NEAR
PUBLIC  P_Thrust_


0x00000000000048b0:  52                   push  dx
0x00000000000048b1:  56                   push  si
0x00000000000048b2:  57                   push  di
0x00000000000048b3:  55                   push  bp
0x00000000000048b4:  89 E5                mov   bp, sp
0x00000000000048b6:  83 EC 02             sub   sp, 2
0x00000000000048b9:  50                   push  ax
0x00000000000048ba:  89 DE                mov   si, bx
0x00000000000048bc:  89 CF                mov   di, cx
0x00000000000048be:  BB EC 06             mov   bx, _playerMobj
0x00000000000048c1:  B1 0B                mov   cl, 11
0x00000000000048c3:  D3 E7                shl   di, cl
0x00000000000048c5:  D3 C6                rol   si, cl
0x00000000000048c7:  31 F7                xor   di, si
0x00000000000048c9:  81 E6 00 F8          and   si, 0F800  ; shift mask todo make suck less.
0x00000000000048cd:  31 F7                xor   di, si
0x00000000000048cf:  89 C2                mov   dx, ax
0x00000000000048d1:  B8 D6 33             mov   ax, FINECOSINE_SEGMENT
0x00000000000048d4:  8B 1F                mov   bx, word ptr ds:[bx]
0x00000000000048d6:  89 F9                mov   cx, di
0x00000000000048d8:  89 5E FE             mov   word ptr [bp - 2], bx
0x00000000000048db:  89 F3                mov   bx, si
0x00000000000048dd:  9A FF 5B A8 0A       call  FixedMulTrig_
0x00000000000048e2:  8B 5E FE             mov   bx, word ptr [bp - 2]
0x00000000000048e5:  89 F9                mov   cx, di
0x00000000000048e7:  01 47 0E             add   word ptr ds:[bx + MOBJ_T.m_momx + 0], ax
0x00000000000048ea:  11 57 10             adc   word ptr ds:[bx + MOBJ_T.m_momx + 2], dx
0x00000000000048ed:  BB EC 06             mov   bx, _playerMobj
0x00000000000048f0:  B8 D6 31             mov   ax, FINESINE_SEGMENT
0x00000000000048f3:  8B 1F                mov   bx, word ptr ds:[bx]
0x00000000000048f5:  8B 56 FC             mov   dx, word ptr [bp - 4]
0x00000000000048f8:  89 5E FE             mov   word ptr [bp - 2], bx
0x00000000000048fb:  89 F3                mov   bx, si
0x00000000000048fd:  9A FF 5B A8 0A       call  FixedMulTrig_
0x0000000000004902:  8B 5E FE             mov   bx, word ptr [bp - 2]
0x0000000000004905:  01 47 12             add   word ptr ds:[bx + MOBJ_T.m_momy + 0], ax
0x0000000000004908:  11 57 14             adc   word ptr ds:[bx + MOBJ_T.m_momy + 2], dx
0x000000000000490b:  C9                   LEAVE_MACRO 
0x000000000000490c:  5F                   pop   di
0x000000000000490d:  5E                   pop   si
0x000000000000490e:  5A                   pop   dx
0x000000000000490f:  CB                   ret  

ENDP


PROC    P_CalcHeight_ NEAR
PUBLIC  P_CalcHeight_

0x0000000000004910:  53                   push  bx
0x0000000000004911:  51                   push  cx
0x0000000000004912:  52                   push  dx
0x0000000000004913:  56                   push  si
0x0000000000004914:  57                   push  di
0x0000000000004915:  55                   push  bp
0x0000000000004916:  89 E5                mov   bp, sp
0x0000000000004918:  83 EC 08             sub   sp, 8
0x000000000000491b:  BB EC 06             mov   bx, _playerMobj
0x000000000000491e:  8B 1F                mov   bx, word ptr ds:[bx]
0x0000000000004920:  8B 47 08             mov   ax, word ptr ds:[bx + MOBJ_T.m_ceilingz]
0x0000000000004923:  2D 20 00             sub   ax, (4 SHL SHORTFLOORBITS)
0x0000000000004926:  89 C6                mov   si, ax
0x0000000000004928:  30 E4                xor   ah, ah
0x000000000000492a:  BB EC 06             mov   bx, _playerMobj
0x000000000000492d:  24 07                and   al, 7
0x000000000000492f:  8B 1F                mov   bx, word ptr ds:[bx]
0x0000000000004931:  C1 E0 0D             shl   ax, 13
0x0000000000004934:  8B 4F 10             mov   cx, word ptr ds:[bx + MOBJ_T.m_momx + 2]
0x0000000000004937:  89 46 FE             mov   word ptr [bp - 2], ax
0x000000000000493a:  8B 47 0E             mov   ax, word ptr ds:[bx + MOBJ_T.m_momx + 0]
0x000000000000493d:  BB EC 06             mov   bx, _playerMobj
0x0000000000004940:  8B 1F                mov   bx, word ptr ds:[bx]
0x0000000000004942:  8B 7F 0E             mov   di, word ptr ds:[bx + MOBJ_T.m_momx + 0]
0x0000000000004945:  8B 57 10             mov   dx, word ptr ds:[bx + MOBJ_T.m_momx + 2]
0x0000000000004948:  89 C3                mov   bx, ax
0x000000000000494a:  89 F8                mov   ax, di
0x000000000000494c:  9A 3C 5B A8 0A       call  FixedMul_
0x0000000000004951:  BB EC 06             mov   bx, _playerMobj
0x0000000000004954:  89 C7                mov   di, ax
0x0000000000004956:  8B 1F                mov   bx, word ptr ds:[bx]
0x0000000000004958:  89 56 F8             mov   word ptr [bp - 8], dx
0x000000000000495b:  8B 47 12             mov   ax, word ptr ds:[bx + MOBJ_T.m_momy + 0]
0x000000000000495e:  8B 57 14             mov   dx, word ptr ds:[bx + MOBJ_T.m_momy + 2]
0x0000000000004961:  BB EC 06             mov   bx, _playerMobj
0x0000000000004964:  8B 1F                mov   bx, word ptr ds:[bx]
0x0000000000004966:  89 56 FA             mov   word ptr [bp - 6], dx
0x0000000000004969:  8B 57 12             mov   dx, word ptr ds:[bx + MOBJ_T.m_momy + 0]
0x000000000000496c:  8B 5F 14             mov   bx, word ptr ds:[bx + MOBJ_T.m_momy + 2]
0x000000000000496f:  8B 4E FA             mov   cx, word ptr [bp - 6]
0x0000000000004972:  89 5E FA             mov   word ptr [bp - 6], bx
0x0000000000004975:  89 C3                mov   bx, ax
0x0000000000004977:  89 D0                mov   ax, dx
0x0000000000004979:  8B 56 FA             mov   dx, word ptr [bp - 6]
0x000000000000497c:  C1 FE 03             sar   si, 3
0x000000000000497f:  9A 3C 5B A8 0A       call  FixedMul_
0x0000000000004984:  BB E4 07             mov   bx, _player + PLAYER_T.player_bob + 0
0x0000000000004987:  01 F8                add   ax, di
0x0000000000004989:  13 56 F8             adc   dx, word ptr [bp - 8]
0x000000000000498c:  89 07                mov   word ptr ds:[bx], ax
0x000000000000498e:  89 57 02             mov   word ptr ds:[bx + 2], dx
0x0000000000004991:  D1 7F 02             sar   word ptr ds:[bx + 2], 1
0x0000000000004994:  D1 1F                rcr   word ptr ds:[bx], 1
0x0000000000004996:  D1 7F 02             sar   word ptr ds:[bx + 2], 1
0x0000000000004999:  D1 1F                rcr   word ptr ds:[bx], 1
0x000000000000499b:  8B 47 02             mov   ax, word ptr ds:[bx + 2]
0x000000000000499e:  3D 10 00             cmp   ax, MAXBOB_HIGHBITS
0x00000000000049a1:  7F 07                jg    label_1
0x00000000000049a3:  75 0E                jne   label_2
0x00000000000049a5:  83 3F 00             cmp   word ptr ds:[bx], 0
0x00000000000049a8:  76 09                jbe   label_2
label_1:
0x00000000000049aa:  C7 07 00 00          mov   word ptr ds:[bx], 0
0x00000000000049ae:  C7 47 02 10 00       mov   word ptr ds:[bx + 2], MAXBOB_HIGHBITS
label_2:
0x00000000000049b3:  BB 0B 08             mov   bx, _player + PLAYER_T.player_cheats
0x00000000000049b6:  F6 07 04             test  byte ptr ds:[bx], CF_NOMOMENTUM
0x00000000000049b9:  75 07                jne   label_3
0x00000000000049bb:  80 3E 2E 20 00       cmp   byte ptr ds:[_secretexit], 0
0x00000000000049c0:  75 57                jne   label_4
label_3:
0x00000000000049c2:  BB 30 07             mov   bx, _playerMobj_pos
0x00000000000049c5:  C4 3F                les   di, dword ptr ds:[bx]
0x00000000000049c7:  BB D8 07             mov   bx, _player + PLAYER_T.player_viewzvalue
0x00000000000049ca:  26 8B 55 08          mov   dx, word ptr es:[di + MOBJ_POS_T.mp_z + 0]
0x00000000000049ce:  26 8B 45 0A          mov   ax, word ptr es:[di + MOBJ_POS_T.mp_z + 2]
0x00000000000049d2:  89 17                mov   word ptr ds:[bx], dx
0x00000000000049d4:  BF DA 07             mov   di, _player + PLAYER_T.player_viewzvalue + 2
0x00000000000049d7:  89 47 02             mov   word ptr ds:[bx + 2], ax
0x00000000000049da:  83 05 29             add   word ptr ds:[di], VIEWHEIGHT_HIGHBITS
0x00000000000049dd:  8B 47 02             mov   ax, word ptr ds:[bx + 2]
0x00000000000049e0:  39 C6                cmp   si, ax
0x00000000000049e2:  7C 09                jl    label_5
0x00000000000049e4:  75 0F                jne   label_6
0x00000000000049e6:  8B 07                mov   ax, word ptr ds:[bx]
0x00000000000049e8:  3B 46 FE             cmp   ax, word ptr [bp - 2]
0x00000000000049eb:  76 08                jbe   label_6
label_5:
0x00000000000049ed:  8B 46 FE             mov   ax, word ptr [bp - 2]
0x00000000000049f0:  89 77 02             mov   word ptr ds:[bx + 2], si
0x00000000000049f3:  89 07                mov   word ptr ds:[bx], ax
label_6:
0x00000000000049f5:  BB 30 07             mov   bx, _playerMobj_pos
0x00000000000049f8:  C4 3F                les   di, dword ptr ds:[bx]
0x00000000000049fa:  BE DC 07             mov   si, _player + PLAYER_T.player_viewheightvalue
0x00000000000049fd:  26 8B 5D 08          mov   bx, word ptr es:[di + MOBJ_POS_T.mp_z + 0]
0x0000000000004a01:  26 8B 45 0A          mov   ax, word ptr es:[di + MOBJ_POS_T.mp_z + 2]
0x0000000000004a05:  03 1C                add   bx, word ptr ds:[si]
0x0000000000004a07:  13 44 02             adc   ax, word ptr ds:[si + 2]
0x0000000000004a0a:  BE D8 07             mov   si, _player + PLAYER_T.player_viewzvalue
0x0000000000004a0d:  89 1C                mov   word ptr ds:[si], bx
0x0000000000004a0f:  89 44 02             mov   word ptr ds:[si + 2], ax
exit_p_calcheight:
0x0000000000004a12:  C9                   LEAVE_MACRO 
0x0000000000004a13:  5F                   pop   di
0x0000000000004a14:  5E                   pop   si
0x0000000000004a15:  5A                   pop   dx
0x0000000000004a16:  59                   pop   cx
0x0000000000004a17:  5B                   pop   bx
0x0000000000004a18:  CB                   ret  
label_4:
0x0000000000004a19:  BB 1C 07             mov   bx, _leveltime
mov   ax,   (FINEANGLES/20)
mul   word ptr ds:[bx]
xchg  ax, dx
0x0000000000004a1c:  69 17 99 01          ;imul  dx, word ptr ds:[bx], 409   ; 409 = (FINEANGLES/20)
0x0000000000004a20:  BB E4 07             mov   bx, _player + PLAYER_T.player_bob
0x0000000000004a23:  8B 07                mov   ax, word ptr ds:[bx]
0x0000000000004a25:  8B 4F 02             mov   cx, word ptr ds:[bx + 2]
0x0000000000004a28:  D1 F9                sar   cx, 1
0x0000000000004a2a:  D1 D8                rcr   ax, 1
0x0000000000004a2c:  80 E6 1F             and   dh, (FINEMASK SHR 8)
0x0000000000004a2f:  89 C3                mov   bx, ax
0x0000000000004a31:  B8 D6 31             mov   ax, FINESINE_SEGMENT
0x0000000000004a34:  9A FF 5B A8 0A       call  FixedMulTrig_
0x0000000000004a39:  BB ED 07             mov   bx, _player + PLAYER_T.player_playerstate
0x0000000000004a3c:  89 C1                mov   cx, ax
0x0000000000004a3e:  89 56 FC             mov   word ptr [bp - 4], dx
0x0000000000004a41:  80 3F 00             cmp   byte ptr ds:[bx], 0
0x0000000000004a44:  74 03                je    label_7
0x0000000000004a46:  E9 81 00             jmp   label_8
label_7:
0x0000000000004a49:  BF E0 07             mov   di, _player + PLAYER_T.player_deltaviewheight
0x0000000000004a4c:  BB DC 07             mov   bx, _player + PLAYER_T.player_viewheightvalue
0x0000000000004a4f:  8B 05                mov   ax, word ptr ds:[di]
0x0000000000004a51:  8B 55 02             mov   dx, word ptr ds:[di + 2]
0x0000000000004a54:  01 07                add   word ptr ds:[bx], ax
0x0000000000004a56:  11 57 02             adc   word ptr ds:[bx + 2], dx
0x0000000000004a59:  8B 47 02             mov   ax, word ptr ds:[bx + 2]
0x0000000000004a5c:  3D 29 00             cmp   ax, VIEWHEIGHT_HIGHBITS
0x0000000000004a5f:  7F 07                jg    label_9
0x0000000000004a61:  75 17                jne   label_10
0x0000000000004a63:  83 3F 00             cmp   word ptr ds:[bx], 0
0x0000000000004a66:  76 12                jbe   label_10
label_9:
0x0000000000004a68:  C7 07 00 00          mov   word ptr ds:[bx], 0
0x0000000000004a6c:  C7 47 02 29 00       mov   word ptr ds:[bx + 2], VIEWHEIGHT_HIGHBITS
0x0000000000004a71:  C7 05 00 00          mov   word ptr ds:[di], 0
0x0000000000004a75:  C7 45 02 00 00       mov   word ptr ds:[di + 2], 0
label_10:
0x0000000000004a7a:  BB DC 07             mov   bx, _player + PLAYER_T.player_viewheightvalue
0x0000000000004a7d:  8B 47 02             mov   ax, word ptr ds:[bx + 2]
0x0000000000004a80:  3D 14 00             cmp   ax, VIEWHEIGHT_HIGHBITS/2  ; 20
0x0000000000004a83:  7C 08                jl    label_11
0x0000000000004a85:  75 23                jne   label_12
0x0000000000004a87:  81 3F 00 80          cmp   word ptr ds:[bx], 08000h   ;  VIEWHEIGHT_HIGHBITS / 2 fractional part
0x0000000000004a8b:  73 1D                jae   label_12
label_11:
0x0000000000004a8d:  C7 07 00 80          mov   word ptr ds:[bx], 08000h  ;  VIEWHEIGHT_HIGHBITS / 2 fractional part
0x0000000000004a91:  C7 47 02 14 00       mov   word ptr ds:[bx + 2], VIEWHEIGHT_HIGHBITS/2 ; 20
0x0000000000004a96:  BB E0 07             mov   bx, _player + PLAYER_T.player_deltaviewheight
0x0000000000004a99:  8B 47 02             mov   ax, word ptr ds:[bx + 2]
0x0000000000004a9c:  85 C0                test  ax, ax
0x0000000000004a9e:  7D 03                jge   label_13
0x0000000000004aa0:  E9 6E 00             jmp   label_14
label_13:
0x0000000000004aa3:  75 05                jne   label_12
0x0000000000004aa5:  83 3F 00             cmp   word ptr ds:[bx], 0
0x0000000000004aa8:  76 67                jbe   label_14
label_12:
0x0000000000004aaa:  BB E0 07             mov   bx, _player + PLAYER_T.player_deltaviewheight
0x0000000000004aad:  8B 47 02             mov   ax, word ptr ds:[bx + 2]
0x0000000000004ab0:  0B 07                or    ax, word ptr ds:[bx]
0x0000000000004ab2:  74 16                je    label_8
0x0000000000004ab4:  81 07 00 40          add   word ptr ds:[bx], 04000h  ; FRACUNIT / 4
0x0000000000004ab8:  83 57 02 00          adc   word ptr ds:[bx + 2], 0
0x0000000000004abc:  8B 47 02             mov   ax, word ptr ds:[bx + 2]
0x0000000000004abf:  0B 07                or    ax, word ptr ds:[bx]
0x0000000000004ac1:  75 07                jne   label_8
0x0000000000004ac3:  C7 07 01 00          mov   word ptr ds:[bx], 1
0x0000000000004ac7:  89 47 02             mov   word ptr ds:[bx + 2], ax
label_8:
0x0000000000004aca:  BB 30 07             mov   bx, _playerMobj_pos
0x0000000000004acd:  C4 3F                les   di, dword ptr ds:[bx]
0x0000000000004acf:  BA DC 07             mov   dx, _player + PLAYER_T.player_viewheightvalue
0x0000000000004ad2:  26 8B 45 08          mov   ax, word ptr es:[di + MOBJ_POS_T.mp_z + 0]
0x0000000000004ad6:  26 8B 5D 0A          mov   bx, word ptr es:[di + MOBJ_POS_T.mp_z + 2]
0x0000000000004ada:  89 D7                mov   di, dx
0x0000000000004adc:  89 C2                mov   dx, ax
0x0000000000004ade:  03 15                add   dx, word ptr ds:[di]
0x0000000000004ae0:  13 5D 02             adc   bx, word ptr ds:[di + 2]
0x0000000000004ae3:  01 CA                add   dx, cx
0x0000000000004ae5:  8B 46 FC             mov   ax, word ptr [bp - 4]
0x0000000000004ae8:  11 D8                adc   ax, bx
0x0000000000004aea:  BB D8 07             mov   bx, _player + PLAYER_T.player_viewzvalue
0x0000000000004aed:  89 17                mov   word ptr ds:[bx], dx
0x0000000000004aef:  89 47 02             mov   word ptr ds:[bx + 2], ax
0x0000000000004af2:  39 C6                cmp   si, ax
0x0000000000004af4:  7C 0C                jl    label_15
0x0000000000004af6:  74 03                je    label_16
jump_to_exit_p_calcheight:
0x0000000000004af8:  E9 17 FF             jmp   exit_p_calcheight
label_16:
0x0000000000004afb:  8B 07                mov   ax, word ptr ds:[bx]
0x0000000000004afd:  3B 46 FE             cmp   ax, word ptr [bp - 2]
0x0000000000004b00:  76 F6                jbe   jump_to_exit_p_calcheight
label_15:
0x0000000000004b02:  8B 46 FE             mov   ax, word ptr [bp - 2]
0x0000000000004b05:  89 77 02             mov   word ptr ds:[bx + 2], si
0x0000000000004b08:  89 07                mov   word ptr ds:[bx], ax
0x0000000000004b0a:  C9                   LEAVE_MACRO 
0x0000000000004b0b:  5F                   pop   di
0x0000000000004b0c:  5E                   pop   si
0x0000000000004b0d:  5A                   pop   dx
0x0000000000004b0e:  59                   pop   cx
0x0000000000004b0f:  5B                   pop   bx
0x0000000000004b10:  CB                   ret  
label_14:
0x0000000000004b11:  C7 07 01 00          mov   word ptr ds:[bx], 1
0x0000000000004b15:  C7 47 02 00 00       mov   word ptr ds:[bx + 2], 0
0x0000000000004b1a:  EB 8E                jmp   label_12


ENDP


PROC    P_MovePlayer_ NEAR
PUBLIC  P_MovePlayer_

0x0000000000004b1c:  53                   push  bx
0x0000000000004b1d:  51                   push  cx
0x0000000000004b1e:  52                   push  dx
0x0000000000004b1f:  56                   push  si
0x0000000000004b20:  57                   push  di
0x0000000000004b21:  BE D0 07             mov   si, 0x7d0
0x0000000000004b24:  BF 30 07             mov   di, _playerMobj_pos
0x0000000000004b27:  8B 44 02             mov   ax, word ptr ds:[si + PLAYER_T.player_cmd_angleturn]
0x0000000000004b2a:  C4 1D                les   bx, dword ptr ds:[di]
0x0000000000004b2c:  26 83 47 0E 00       add   word ptr es:[bx + MOBJ_POS_T.mp_angle + 0], 0
0x0000000000004b31:  26 11 47 10          adc   word ptr es:[bx + MOBJ_POS_T.mp_angle + 0], ax
0x0000000000004b35:  BB EC 06             mov   bx, _playerMobj
0x0000000000004b38:  8B 1F                mov   bx, word ptr ds:[bx]
0x0000000000004b3a:  8B 47 06             mov   ax, word ptr ds:[bx + 6]
0x0000000000004b3d:  BB EC 06             mov   bx, _playerMobj
0x0000000000004b40:  8B 1F                mov   bx, word ptr ds:[bx]
0x0000000000004b42:  8B 57 06             mov   dx, word ptr ds:[bx + 6]
0x0000000000004b45:  C1 F8 03             sar   ax, 3
0x0000000000004b48:  30 F6                xor   dh, dh
0x0000000000004b4a:  8B 1D                mov   bx, word ptr ds:[di]
0x0000000000004b4c:  80 E2 07             and   dl, 7
0x0000000000004b4f:  8E 45 02             mov   es, word ptr ds:[di + 2]
0x0000000000004b52:  C1 E2 0D             shl   dx, 13
0x0000000000004b55:  26 3B 47 0A          cmp   ax, word ptr es:[bx + MOBJ_POS_T.mp_z + 2]
0x0000000000004b59:  7F 0B                jg    label_17
0x0000000000004b5b:  74 03                je    label_18
jump_to_label_19:
0x0000000000004b5d:  E9 76 00             jmp   label_19
label_18:
0x0000000000004b60:  26 3B 57 08          cmp   dx, word ptr es:[bx + MOBJ_POS_T.mp_z + 8]
0x0000000000004b64:  72 F7                jb    jump_to_label_19
label_17:
0x0000000000004b66:  B0 01                mov   al, 1
label_22:
0x0000000000004b68:  A2 2E 20             mov   byte ptr ds:[_secretexit], al
0x0000000000004b6b:  80 3C 00             cmp   byte ptr ds:[si + PLAYER_T.player_cmd_forwardmove], 0
0x0000000000004b6e:  74 1E                je    label_20
0x0000000000004b70:  84 C0                test  al, al
0x0000000000004b72:  74 1A                je    label_20
0x0000000000004b74:  8A 04                mov   al, byte ptr ds:[si + PLAYER_T.player_cmd_forwardmove]
0x0000000000004b76:  BB 30 07             mov   bx, _playerMobj_pos
0x0000000000004b79:  98                   cbw  
0x0000000000004b7a:  C4 3F                les   di, dword ptr ds:[bx]
0x0000000000004b7c:  99                   cwd   
0x0000000000004b7d:  26 8B 7D 10          mov   di, word ptr es:[di + MOBJ_POS_T.mp_angle+2]
0x0000000000004b81:  89 C3                mov   bx, ax
0x0000000000004b83:  C1 EF 03             shr   di, 3
0x0000000000004b86:  89 D1                mov   cx, dx
0x0000000000004b88:  89 F8                mov   ax, di
0x0000000000004b8a:  0E                   
0x0000000000004b8b:  E8 22 FD             call  P_Thrust_
label_20:
0x0000000000004b8e:  80 7C 01 00          cmp   byte ptr ds:[si + PLAYER_T.player_cmd_sidemove], 0
0x0000000000004b92:  74 2A                je    label_21
0x0000000000004b94:  80 3E 2E 20 00       cmp   byte ptr ds:[_secretexit], 0
0x0000000000004b99:  74 23                je    label_21
0x0000000000004b9b:  BB 30 07             mov   bx, _playerMobj_pos
0x0000000000004b9e:  8A 44 01             mov   al, byte ptr ds:[si + PLAYER_T.player_cmd_sidemove]
0x0000000000004ba1:  C4 3F                les   di, dword ptr ds:[bx]
0x0000000000004ba3:  26 8B 7D 10          mov   di, word ptr es:[di + MOBJ_POS_T.mp_angle+2]
0x0000000000004ba7:  98                   cbw  
0x0000000000004ba8:  C1 EF 03             shr   di, SHORTTOFINESHIFT
0x0000000000004bab:  99                   cwd   
0x0000000000004bac:  81 EF 00 08          sub   di, FINE_ANG90
0x0000000000004bb0:  89 C3                mov   bx, ax
0x0000000000004bb2:  81 E7 FF 1F          and   di, FINEMASK
0x0000000000004bb6:  89 D1                mov   cx, dx
0x0000000000004bb8:  89 F8                mov   ax, di
0x0000000000004bba:  0E                   
0x0000000000004bbb:  E8 F2 FC             call  P_Thrust_
label_21:
0x0000000000004bbe:  80 3C 00             cmp   byte ptr ds:[si + PLAYER_T.player_cmd_forwardmove], 0
0x0000000000004bc1:  74 17                je    label_77
label_23:
0x0000000000004bc3:  BB 30 07             mov   bx, _playerMobj_pos
0x0000000000004bc6:  C4 37                les   si, dword ptr ds:[bx]
0x0000000000004bc8:  26 81 7C 12 95 00    cmp   word ptr es:[si + MOBJ_POS_T.mp_statenum], S_PLAY
0x0000000000004bce:  74 12                je    label_78
label_24:
0x0000000000004bd0:  5F                   pop   di
0x0000000000004bd1:  5E                   pop   si
0x0000000000004bd2:  5A                   pop   dx
0x0000000000004bd3:  59                   pop   cx
0x0000000000004bd4:  5B                   pop   bx
0x0000000000004bd5:  CB                   ret  
label_19:
0x0000000000004bd6:  30 C0                xor   al, al
0x0000000000004bd8:  EB 8E                jmp   label_22
label_77:
0x0000000000004bda:  80 7C 01 00          cmp   byte ptr ds:[si + 1], 0
0x0000000000004bde:  75 E3                jne   label_23
0x0000000000004be0:  EB EE                jmp   label_24
label_78:
0x0000000000004be2:  BB EC 06             mov   bx, _playerMobj
0x0000000000004be5:  BA 96 00             mov   dx, S_PLAY_RUN1
0x0000000000004be8:  8B 07                mov   ax, word ptr ds:[bx]
0x0000000000004bea:  FF 1E 7C 0F          call  word ptr ds:[_P_SetMobjState]
0x0000000000004bee:  5F                   pop   di
0x0000000000004bef:  5E                   pop   si
0x0000000000004bf0:  5A                   pop   dx
0x0000000000004bf1:  59                   pop   cx
0x0000000000004bf2:  5B                   pop   bx
0x0000000000004bf3:  CB                   ret  


ENDP


PROC    P_DeathThink_ NEAR
PUBLIC  P_DeathThink_

0x0000000000004bf4:  53                   push  bx
0x0000000000004bf5:  51                   push  cx
0x0000000000004bf6:  52                   push  dx
0x0000000000004bf7:  56                   push  si
0x0000000000004bf8:  57                   push  di
0x0000000000004bf9:  BB DC 07             mov   bx, _player + PLAYER_T.player_viewheightvalue
0x0000000000004bfc:  FF 1E 64 0F          call  word ptr ds:[_P_MovePsprites]
0x0000000000004c00:  8B 47 02             mov   ax, word ptr ds:[bx + 2]
0x0000000000004c03:  3D 06 00             cmp   ax, 6
0x0000000000004c06:  7F 07                jg    label_25
0x0000000000004c08:  75 0A                jne   label_26
0x0000000000004c0a:  83 3F 00             cmp   word ptr ds:[bx], 0
0x0000000000004c0d:  76 05                jbe   label_26
label_25:
0x0000000000004c0f:  BB DE 07             mov   bx, _player + PLAYER_T.player_viewheightvalue + 2
0x0000000000004c12:  FF 0F                dec   word ptr ds:[bx]
label_26:
0x0000000000004c14:  BB DC 07             mov   bx, _player + PLAYER_T.player_viewheightvalue + 0
0x0000000000004c17:  8B 47 02             mov   ax, word ptr ds:[bx + 2]
0x0000000000004c1a:  3D 06 00             cmp   ax, 6
0x0000000000004c1d:  7D 03                jge   label_27
0x0000000000004c1f:  E9 D4 00             jmp   label_28
label_27:
0x0000000000004c22:  BB E0 07             mov   bx, _player + PLAYER_T.player_deltaviewheight
0x0000000000004c25:  C7 07 00 00          mov   word ptr ds:[bx], 0
0x0000000000004c29:  C7 47 02 00 00       mov   word ptr ds:[bx + 2], 0
0x0000000000004c2e:  BB EC 06             mov   bx, _playerMobj
0x0000000000004c31:  8B 1F                mov   bx, word ptr ds:[bx]
0x0000000000004c33:  8B 47 06             mov   ax, word ptr ds:[bx + 6]
0x0000000000004c36:  BB EC 06             mov   bx, _playerMobj
0x0000000000004c39:  8B 1F                mov   bx, word ptr ds:[bx]
0x0000000000004c3b:  BE 30 07             mov   si, _playerMobj_pos
0x0000000000004c3e:  8B 57 06             mov   dx, word ptr ds:[bx + 6]
0x0000000000004c41:  C1 F8 03             sar   ax, 3
0x0000000000004c44:  30 F6                xor   dh, dh
0x0000000000004c46:  8B 1C                mov   bx, word ptr ds:[si]
0x0000000000004c48:  80 E2 07             and   dl, 7
0x0000000000004c4b:  8E 44 02             mov   es, word ptr ds:[si + 2]
0x0000000000004c4e:  C1 E2 0D             shl   dx, 13
0x0000000000004c51:  26 3B 47 0A          cmp   ax, word ptr es:[bx + MOBJ_POS_T.mp_z + 2]
0x0000000000004c55:  7F 0B                jg    label_29
0x0000000000004c57:  74 03                je    label_30
jump_to_label_31:
0x0000000000004c59:  E9 A6 00             jmp   label_31
label_30:
0x0000000000004c5c:  26 3B 57 08          cmp   dx, word ptr es:[bx + MOBJ_POS_T.mp_z + 0]
0x0000000000004c60:  72 F7                jb    jump_to_label_31
label_29:
0x0000000000004c62:  B0 01                mov   al, 1
label_39:
0x0000000000004c64:  BB 2C 08             mov   bx, 0x82c
0x0000000000004c67:  A2 2E 20             mov   byte ptr ds:[_secretexit], al
0x0000000000004c6a:  0E                   
0x0000000000004c6b:  E8 A2 FC             call  P_CalcHeight_
0x0000000000004c6e:  8B 07                mov   ax, word ptr ds:[bx]
0x0000000000004c70:  85 C0                test  ax, ax
0x0000000000004c72:  75 03                jne   label_32
jump_to_label_33:
0x0000000000004c74:  E9 07 01             jmp   label_33
label_32:
0x0000000000004c77:  BE F6 06             mov   si, 0x6f6
0x0000000000004c7a:  3B 04                cmp   ax, word ptr ds:[si]
0x0000000000004c7c:  74 F6                je    jump_to_label_33
0x0000000000004c7e:  BB 6A 04             mov   bx, 0x46a
0x0000000000004c81:  80 3F 00             cmp   byte ptr ds:[bx], 0
0x0000000000004c84:  74 6E                je    jump_to_label_34
0x0000000000004c86:  BB 2C 02             mov   bx, 0x22c
0x0000000000004c89:  FF 77 02             push  word ptr ds:[bx + 2]
0x0000000000004c8c:  FF 37                push  word ptr ds:[bx]
0x0000000000004c8e:  BB 28 02             mov   bx, 0x228
0x0000000000004c91:  FF 77 02             push  word ptr ds:[bx + 2]
0x0000000000004c94:  FF 37                push  word ptr ds:[bx]
0x0000000000004c96:  BB 30 07             mov   bx, _playerMobj_pos
0x0000000000004c99:  C4 37                les   si, dword ptr ds:[bx]
0x0000000000004c9b:  26 8B 5C 04          mov   bx, word ptr es:[si + 4]
0x0000000000004c9f:  26 8B 4C 06          mov   cx, word ptr es:[si + 6]
0x0000000000004ca3:  26 8B 04             mov   ax, word ptr es:[si]
0x0000000000004ca6:  26 8B 54 02          mov   dx, word ptr es:[si + 2]
label_40:
0x0000000000004cab:  E8 E7 05             call  R_PointToAngle2_
0x0000000000004caf:  89 C3                mov   bx, ax
0x0000000000004cb1:  BE 30 07             mov   si, _playerMobj_pos
0x0000000000004cb4:  C4 3C                les   di, dword ptr ds:[si]
0x0000000000004cb6:  89 D9                mov   cx, bx
0x0000000000004cb8:  26 2B 4D 0E          sub   cx, word ptr es:[di + MOBJ_POS_T.mp_angle + 0]
0x0000000000004cbc:  89 D0                mov   ax, dx
0x0000000000004cbe:  26 1B 45 10          sbb   ax, word ptr es:[di + MOBJ_POS_T.mp_angle + 2]
0x0000000000004cc2:  3D 8E 03             cmp   ax, 0x38e
0x0000000000004cc5:  72 08                jb    label_35
0x0000000000004cc7:  75 3E                jne   jump_to_label_36
0x0000000000004cc9:  81 F9 E3 38          cmp   cx, 0x38e3
0x0000000000004ccd:  73 38                jae   jump_to_label_36
label_35:
0x0000000000004ccf:  BF 30 07             mov   di, _playerMobj_pos
0x0000000000004cd2:  C4 35                les   si, dword ptr ds:[di]
0x0000000000004cd4:  26 89 5C 0E          mov   word ptr es:[si + MOBJ_POS_T.mp_angle + 0], bx
0x0000000000004cd8:  BB 28 08             mov   bx, 0x828
0x0000000000004cdb:  26 89 54 10          mov   word ptr es:[si + MOBJ_POS_T.mp_angle + 2], dx
label_43:
0x0000000000004cdf:  83 3F 00             cmp   word ptr ds:[bx], 0
0x0000000000004ce2:  74 02                je    label_37
0x0000000000004ce4:  FF 0F                dec   word ptr ds:[bx]
label_37:
0x0000000000004ce6:  BB D7 07             mov   bx, 0x7d7
0x0000000000004ce9:  F6 07 02             test  byte ptr ds:[bx], 2
0x0000000000004cec:  75 57                jne   jump_to_label_38
0x0000000000004cee:  5F                   pop   di
0x0000000000004cef:  5E                   pop   si
0x0000000000004cf0:  5A                   pop   dx
0x0000000000004cf1:  59                   pop   cx
0x0000000000004cf2:  5B                   pop   bx
0x0000000000004cf3:  CB                   ret  
jump_to_label_34:
0x0000000000004cf4:  EB 13                jmp   label_34
label_28:
0x0000000000004cf6:  C7 07 00 00          mov   word ptr ds:[bx], 0
0x0000000000004cfa:  C7 47 02 06 00       mov   word ptr ds:[bx + 2], 6
0x0000000000004cff:  E9 20 FF             jmp   label_27
label_31:
0x0000000000004d02:  30 C0                xor   al, al
0x0000000000004d04:  E9 5D FF             jmp   label_39
jump_to_label_36:
0x0000000000004d07:  EB 3E                jmp   label_36
label_34:
0x0000000000004d09:  BB 2C 08             mov   bx, 0x82c
0x0000000000004d0c:  6B 1F 18             imul  bx, word ptr ds:[bx], 0x18
0x0000000000004d0f:  B8 F5 6A             mov   ax, MOBJPOSLIST_6800_SEGMENT
0x0000000000004d12:  8E C0                mov   es, ax
0x0000000000004d14:  26 FF 77 06          push  word ptr es:[bx + 6]
0x0000000000004d18:  26 FF 77 04          push  word ptr es:[bx + 4]
0x0000000000004d1c:  26 FF 77 02          push  word ptr es:[bx + 2]
0x0000000000004d20:  26 FF 37             push  word ptr es:[bx]
0x0000000000004d23:  BB 30 07             mov   bx, _playerMobj_pos
0x0000000000004d26:  C4 37                les   si, dword ptr ds:[bx]
0x0000000000004d28:  26 8B 44 04          mov   ax, word ptr es:[si + 4]
0x0000000000004d2c:  26 8B 4C 06          mov   cx, word ptr es:[si + 6]
0x0000000000004d30:  89 DE                mov   si, bx
0x0000000000004d32:  8B 1F                mov   bx, word ptr ds:[bx]
0x0000000000004d34:  8E 44 02             mov   es, word ptr ds:[si + 2]
0x0000000000004d37:  26 8B 37             mov   si, word ptr es:[bx]
0x0000000000004d3a:  26 8B 57 02          mov   dx, word ptr es:[bx + 2]
0x0000000000004d3e:  89 C3                mov   bx, ax
0x0000000000004d40:  89 F0                mov   ax, si
0x0000000000004d42:  E9 65 FF             jmp   label_40
jump_to_label_38:
0x0000000000004d45:  EB 3D                jmp   label_38
label_36:
0x0000000000004d47:  3D 71 FC             cmp   ax, 0xfc71
0x0000000000004d4a:  77 83                ja    label_35
0x0000000000004d4c:  75 09                jne   label_41
0x0000000000004d4e:  81 F9 1D C7          cmp   cx, 0xc71d
0x0000000000004d52:  76 03                jbe   label_41
0x0000000000004d54:  E9 78 FF             jmp   label_35
label_41:
0x0000000000004d57:  3D 00 80             cmp   ax, 0x8000
0x0000000000004d5a:  73 11                jae   label_42
0x0000000000004d5c:  89 FB                mov   bx, di
0x0000000000004d5e:  26 81 47 0E E3 38    add   word ptr es:[bx + MOBJ_POS_T.mp_angle + 0], 0x38e3
0x0000000000004d64:  26 81 57 10 8E 03    adc   word ptr es:[bx + MOBJ_POS_T.mp_angle + 2], 0x38e
0x0000000000004d6a:  E9 79 FF             jmp   label_37
label_42:
0x0000000000004d6d:  89 FB                mov   bx, di
0x0000000000004d6f:  26 81 47 0E 1D C7    add   word ptr es:[bx + MOBJ_POS_T.mp_angle + 0], 0xc71d
0x0000000000004d75:  26 81 57 10 71 FC    adc   word ptr es:[bx + MOBJ_POS_T.mp_angle + 2], 0xfc71
0x0000000000004d7b:  E9 68 FF             jmp   label_37
label_33:
0x0000000000004d7e:  BB 28 08             mov   bx, 0x828
0x0000000000004d81:  E9 5B FF             jmp   label_43
label_38:
0x0000000000004d84:  BB ED 07             mov   bx, _player + PLAYER_T.player_playerstate
0x0000000000004d87:  C6 07 02             mov   byte ptr ds:[bx], 2
0x0000000000004d8a:  5F                   pop   di
0x0000000000004d8b:  5E                   pop   si
0x0000000000004d8c:  5A                   pop   dx
0x0000000000004d8d:  59                   pop   cx
0x0000000000004d8e:  5B                   pop   bx
0x0000000000004d8f:  CB                   ret  


ENDP


PROC    P_PlayerThink_ NEAR
PUBLIC  P_PlayerThink_


0x0000000000004d90:  53                   push  bx
0x0000000000004d91:  52                   push  dx
0x0000000000004d92:  56                   push  si
0x0000000000004d93:  57                   push  di
0x0000000000004d94:  55                   push  bp
0x0000000000004d95:  89 E5                mov   bp, sp
0x0000000000004d97:  83 EC 04             sub   sp, 4
0x0000000000004d9a:  C7 46 FC C8 25       mov   word ptr [bp - 4], 0x25c8
0x0000000000004d9f:  BB 0B 08             mov   bx, _player + PLAYER_T.player_cheats
0x0000000000004da2:  C7 46 FE 00 94       mov   word ptr [bp - 2], 0x9400
0x0000000000004da7:  F6 07 01             test  byte ptr ds:[bx], 1
0x0000000000004daa:  74 03                je    label_48
0x0000000000004dac:  E9 F5 00             jmp   label_49
label_48:
0x0000000000004daf:  BE 30 07             mov   si, _playerMobj_pos
0x0000000000004db2:  C4 1C                les   bx, dword ptr ds:[si]
0x0000000000004db4:  26 80 67 15 EF       and   byte ptr es:[bx + 0x15], 0xef
label_44:
0x0000000000004db9:  BE 30 07             mov   si, _playerMobj_pos
0x0000000000004dbc:  C4 3C                les   di, dword ptr ds:[si]
0x0000000000004dbe:  BB D0 07             mov   bx, 0x7d0
0x0000000000004dc1:  26 F6 45 14 80       test  byte ptr es:[di + 0x14], 0x80
0x0000000000004dc6:  74 15                je    label_45
0x0000000000004dc8:  C7 47 02 00 00       mov   word ptr ds:[bx + 2], 0
0x0000000000004dcd:  C7 07 64 00          mov   word ptr ds:[bx], 0x64
0x0000000000004dd1:  89 F7                mov   di, si
0x0000000000004dd3:  8B 34                mov   si, word ptr ds:[si]
0x0000000000004dd5:  8E 45 02             mov   es, word ptr ds:[di + 2]
0x0000000000004dd8:  26 80 64 14 7F       and   byte ptr es:[si + 0x14], 0x7f
label_45:
0x0000000000004ddd:  BE ED 07             mov   si, _player + PLAYER_T.player_playerstate
0x0000000000004de0:  80 3C 01             cmp   byte ptr ds:[si], 1
0x0000000000004de3:  75 03                jne   label_46
0x0000000000004de5:  E9 C9 00             jmp   label_47
label_46:
0x0000000000004de8:  BE EC 06             mov   si, _playerMobj
0x0000000000004deb:  8B 34                mov   si, word ptr ds:[si]
0x0000000000004ded:  80 7C 24 00          cmp   byte ptr ds:[si + 0x24], 0
0x0000000000004df1:  75 03                jne   label_50
0x0000000000004df3:  E9 C1 00             jmp   label_51
label_50:
0x0000000000004df6:  BE EC 06             mov   si, _playerMobj
0x0000000000004df9:  8B 34                mov   si, word ptr ds:[si]
0x0000000000004dfb:  FE 4C 24             dec   byte ptr ds:[si + 0x24]
label_52:
0x0000000000004dfe:  BE EC 06             mov   si, _playerMobj
0x0000000000004e01:  0E                   
0x0000000000004e02:  E8 0B FB             call  P_CalcHeight_
0x0000000000004e05:  8B 34                mov   si, word ptr ds:[si]
0x0000000000004e07:  8B 44 04             mov   ax, word ptr ds:[si + 4]
0x0000000000004e0a:  C1 E0 04             shl   ax, 4
0x0000000000004e0d:  89 C6                mov   si, ax
0x0000000000004e0f:  81 C6 3E DE          add   si, _sectors_physics + SECTOR_PHYSICS_T.secp_special
0x0000000000004e13:  80 3C 00             cmp   byte ptr ds:[si], 0
0x0000000000004e16:  74 03                je    label_53
0x0000000000004e18:  E8 71 EF             call  P_PlayerInSpecialSector_
label_53:
0x0000000000004e1b:  8A 47 07             mov   al, byte ptr ds:[bx + 7]
0x0000000000004e1e:  A8 80                test  al, 0x80
0x0000000000004e20:  75 03                jne   label_54
0x0000000000004e22:  E9 A8 00             jmp   label_55
label_54:
0x0000000000004e25:  C6 47 07 00          mov   byte ptr ds:[bx + 7], 0
label_67:
0x0000000000004e29:  BB 1D 08             mov   bx, 0x81d
0x0000000000004e2c:  C6 07 00             mov   byte ptr ds:[bx], 0
label_63:
0x0000000000004e2f:  BB F0 07             mov   bx, 0x7f0
0x0000000000004e32:  FF 1E 64 0F          call  word ptr ds:[_P_MovePsprites]
0x0000000000004e36:  83 3F 00             cmp   word ptr ds:[bx], 0
0x0000000000004e39:  74 02                je    label_64
0x0000000000004e3b:  FF 07                inc   word ptr ds:[bx]
label_64:
0x0000000000004e3d:  BB EE 07             mov   bx, 0x7ee
0x0000000000004e40:  83 3F 00             cmp   word ptr ds:[bx], 0
0x0000000000004e43:  74 02                je    label_65
0x0000000000004e45:  FF 0F                dec   word ptr ds:[bx]
label_65:
0x0000000000004e47:  BB F2 07             mov   bx, 0x7f2
0x0000000000004e4a:  83 3F 00             cmp   word ptr ds:[bx], 0
0x0000000000004e4d:  74 0E                je    label_75
0x0000000000004e4f:  FF 0F                dec   word ptr ds:[bx]
0x0000000000004e51:  75 0A                jne   label_75
0x0000000000004e53:  BE 30 07             mov   si, _playerMobj_pos
0x0000000000004e56:  C4 1C                les   bx, dword ptr ds:[si]
0x0000000000004e58:  26 80 67 16 FB       and   byte ptr es:[bx + 0x16], 0xfb
label_75:
0x0000000000004e5d:  BB F8 07             mov   bx, 0x7f8
0x0000000000004e60:  83 3F 00             cmp   word ptr ds:[bx], 0
0x0000000000004e63:  74 02                je    label_76
0x0000000000004e65:  FF 0F                dec   word ptr ds:[bx]
label_76:
0x0000000000004e67:  BB F4 07             mov   bx, 0x7f4
0x0000000000004e6a:  83 3F 00             cmp   word ptr ds:[bx], 0
0x0000000000004e6d:  74 02                je    label_74
0x0000000000004e6f:  FF 0F                dec   word ptr ds:[bx]
label_74:
0x0000000000004e71:  BB 28 08             mov   bx, 0x828
0x0000000000004e74:  83 3F 00             cmp   word ptr ds:[bx], 0
0x0000000000004e77:  74 02                je    label_79
0x0000000000004e79:  FF 0F                dec   word ptr ds:[bx]
label_79:
0x0000000000004e7b:  BB 2A 08             mov   bx, 0x82a
0x0000000000004e7e:  80 3F 00             cmp   byte ptr ds:[bx], 0
0x0000000000004e81:  74 02                je    label_80
0x0000000000004e83:  FE 0F                dec   byte ptr ds:[bx]
label_80:
0x0000000000004e85:  BB 2F 08             mov   bx, 0x82f
0x0000000000004e88:  C6 07 00             mov   byte ptr ds:[bx], 0
0x0000000000004e8b:  BB EE 07             mov   bx, 0x7ee
0x0000000000004e8e:  8B 07                mov   ax, word ptr ds:[bx]
0x0000000000004e90:  85 C0                test  ax, ax
0x0000000000004e92:  74 2A                je    jump_to_label_73
0x0000000000004e94:  3D 80 00             cmp   ax, 0x80
0x0000000000004e97:  7F 28                jg    label_74
0x0000000000004e99:  F6 07 08             test  byte ptr ds:[bx], 8
0x0000000000004e9c:  75 23                jne   label_74
exit_player_think:
0x0000000000004e9e:  C9                   LEAVE_MACRO 
0x0000000000004e9f:  5F                   pop   di
0x0000000000004ea0:  5E                   pop   si
0x0000000000004ea1:  5A                   pop   dx
0x0000000000004ea2:  5B                   pop   bx
0x0000000000004ea3:  C3                   ret   
label_49:
0x0000000000004ea4:  BE 30 07             mov   si, _playerMobj_pos
0x0000000000004ea7:  C4 1C                les   bx, dword ptr ds:[si]
0x0000000000004ea9:  26 80 4F 15 10       or    byte ptr es:[bx + 0x15], 0x10
0x0000000000004eae:  E9 08 FF             jmp   label_44
label_47:
0x0000000000004eb1:  0E                   
0x0000000000004eb2:  E8 3F FD             call  P_DeathThink_
0x0000000000004eb5:  EB E7                jmp   exit_player_think
label_51:
0x0000000000004eb7:  0E                   
0x0000000000004eb8:  E8 61 FC             call  P_MovePlayer_
0x0000000000004ebb:  E9 40 FF             jmp   label_52
jump_to_label_73:
0x0000000000004ebe:  E9 A7 00             jmp   label_73
label_74:
0x0000000000004ec1:  BB 2F 08             mov   bx, 0x82f
0x0000000000004ec4:  C6 07 20             mov   byte ptr ds:[bx], 0x20
0x0000000000004ec7:  C9                   LEAVE_MACRO 
0x0000000000004ec8:  5F                   pop   di
0x0000000000004ec9:  5E                   pop   si
0x0000000000004eca:  5A                   pop   dx
0x0000000000004ecb:  5B                   pop   bx
0x0000000000004ecc:  C3                   ret   
label_55:
0x0000000000004ecd:  A8 04                test  al, 4
0x0000000000004ecf:  75 03                jne   label_56
0x0000000000004ed1:  E9 69 00             jmp   label_57
label_56:
0x0000000000004ed4:  24 38                and   al, 0x38
0x0000000000004ed6:  30 E4                xor   ah, ah
0x0000000000004ed8:  89 C2                mov   dx, ax
0x0000000000004eda:  C1 FA 03             sar   dx, 3
0x0000000000004edd:  88 D0                mov   al, dl
0x0000000000004edf:  84 D2                test  dl, dl
0x0000000000004ee1:  75 1B                jne   label_62
0x0000000000004ee3:  BE 09 08             mov   si, 0x809
0x0000000000004ee6:  80 3C 00             cmp   byte ptr ds:[si], 0
0x0000000000004ee9:  74 13                je    label_62
0x0000000000004eeb:  BE 00 08             mov   si, 0x800
0x0000000000004eee:  80 3C 07             cmp   byte ptr ds:[si], 7
0x0000000000004ef1:  74 03                je    label_70
0x0000000000004ef3:  E9 64 00             jmp   label_71
label_70:
0x0000000000004ef6:  BE F0 07             mov   si, 0x7f0
0x0000000000004ef9:  83 3C 00             cmp   word ptr ds:[si], 0
0x0000000000004efc:  74 5C                je    label_71
label_62:
0x0000000000004efe:  BE EB 02             mov   si, 0x2eb
0x0000000000004f01:  80 3C 00             cmp   byte ptr ds:[si], 0
0x0000000000004f04:  74 16                je    label_69
0x0000000000004f06:  3C 02                cmp   al, 2
0x0000000000004f08:  75 12                jne   label_69
0x0000000000004f0a:  BE 0A 08             mov   si, 0x80a
0x0000000000004f0d:  80 3C 00             cmp   byte ptr ds:[si], 0
0x0000000000004f10:  74 0A                je    label_69
0x0000000000004f12:  BE 00 08             mov   si, 0x800
0x0000000000004f15:  80 3C 08             cmp   byte ptr ds:[si], 8
0x0000000000004f18:  74 02                je    label_69
0x0000000000004f1a:  B0 08                mov   al, 8
label_69:
0x0000000000004f1c:  88 C2                mov   dl, al
0x0000000000004f1e:  30 F6                xor   dh, dh
0x0000000000004f20:  89 D6                mov   si, dx
0x0000000000004f22:  80 BC 02 08 00       cmp   byte ptr ds:[si + 0x802], 0
0x0000000000004f27:  74 14                je    label_57
0x0000000000004f29:  BE 00 08             mov   si, 0x800
0x0000000000004f2c:  3A 04                cmp   al, byte ptr ds:[si]
0x0000000000004f2e:  74 0D                je    label_57
0x0000000000004f30:  3C 05                cmp   al, 5
0x0000000000004f32:  74 2A                je    label_68
0x0000000000004f34:  3C 06                cmp   al, 6
0x0000000000004f36:  74 26                je    label_68
label_61:
0x0000000000004f38:  BE 01 08             mov   si, 0x801
0x0000000000004f3b:  88 04                mov   byte ptr ds:[si], al
label_57:
0x0000000000004f3d:  F6 47 07 02          test  byte ptr ds:[bx + 7], 2
0x0000000000004f41:  75 03                jne   label_66
0x0000000000004f43:  E9 E3 FE             jmp   label_67
label_66:
0x0000000000004f46:  BB 1D 08             mov   bx, 0x81d
0x0000000000004f49:  80 3F 00             cmp   byte ptr ds:[bx], 0
0x0000000000004f4c:  74 03                je    label_72
0x0000000000004f4e:  E9 DE FE             jmp   label_63
label_72:
0x0000000000004f51:  FF 5E FC             lcall [bp - 4]
0x0000000000004f54:  C6 07 01             mov   byte ptr ds:[bx], 1
0x0000000000004f57:  E9 D5 FE             jmp   label_63
label_71:
0x0000000000004f5a:  B0 07                mov   al, 7
0x0000000000004f5c:  EB A0                jmp   label_62
label_68:
0x0000000000004f5e:  BE ED 02             mov   si, 0x2ed
0x0000000000004f61:  80 3C 00             cmp   byte ptr ds:[si], 0
0x0000000000004f64:  74 D2                je    label_61
0x0000000000004f66:  EB D5                jmp   label_57
label_73:
0x0000000000004f68:  BB F8 07             mov   bx, 0x7f8
0x0000000000004f6b:  8B 07                mov   ax, word ptr ds:[bx]
0x0000000000004f6d:  85 C0                test  ax, ax
0x0000000000004f6f:  75 03                jne   label_60
label_58:
0x0000000000004f71:  E9 2A FF             jmp   exit_player_think
label_60:
0x0000000000004f74:  3D 80 00             cmp   ax, 0x80
0x0000000000004f77:  7F 05                jg    label_59
0x0000000000004f79:  F6 07 08             test  byte ptr ds:[bx], 8
0x0000000000004f7c:  74 F3                je    label_58
label_59:
0x0000000000004f7e:  BB 2F 08             mov   bx, 0x82f
0x0000000000004f81:  C6 07 01             mov   byte ptr ds:[bx], 1
0x0000000000004f84:  C9                   LEAVE_MACRO 
0x0000000000004f85:  5F                   pop   di
0x0000000000004f86:  5E                   pop   si
0x0000000000004f87:  5A                   pop   dx
0x0000000000004f88:  5B                   pop   bx
0x0000000000004f89:  C3                   ret   

ENDP


PROC    P_USER_ENDMARKER_ NEAR
PUBLIC  P_USER_ENDMARKER_
ENDP

END

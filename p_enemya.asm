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


.CODE


;FATSPREAD = (ANG90/8)
FATSPREADHIGH = 00800h
FATSPREADLOW  =  0h

TRACEANGLEHIGH = 0C00h
TRACEANGLELOW = 00000h

; todo constants.inc

DI_WEST = 0 
DI_SOUTHWEST = 1
DI_SOUTH = 2
DI_SOUTHEAST = 3
DI_EAST= 4
DI_NORTHEAST= 5
DI_NORTH = 6
DI_NORTHWEST = 7
DI_NODIR = 8

DI_NORTHWEST = 0
DI_NORTHEAST = 1
DI_SOUTHWEST = 2 
DI_SOUTHEAST = 3

FLOATSPEED_HIGHBITS = 4


TAG_1323 =		56
TAG_1044 =		57
TAG_86	=		58
TAG_77	=		59
TAG_99	=		60
TAG_666	=		61
TAG_667	=		62
TAG_999	=		63

DOOR_NORMAL = 0
DOOR_CLOSE30THENOPEN = 1
DOOR_CLOSE = 2
DOOR_OPEN = 3
DOOR_RAISEIN5MINS = 4
DOOR_BLAZERAISE   = 5
DOOR_BLAZEOPEN    = 6
DOOR_BLAZECLOSE   = 7

SKULLSPEED_SMALL = 20


PROC    P_ENEMY_STARTMARKER_ 
PUBLIC  P_ENEMY_STARTMARKER_
ENDP


PROC    P_RecursiveSound_ NEAR
PUBLIC  P_RecursiveSound_


0x00000000000028a0:  53                   push  bx
0x00000000000028a1:  51                   push  cx
0x00000000000028a2:  56                   push  si
0x00000000000028a3:  57                   push  di
0x00000000000028a4:  55                   push  bp
0x00000000000028a5:  89 E5                mov   bp, sp
0x00000000000028a7:  83 EC 10             sub   sp, 010h
0x00000000000028aa:  50                   push  ax
0x00000000000028ab:  88 56 FC             mov   byte ptr [bp - 4], dl
0x00000000000028ae:  C7 46 F8 90 21       mov   word ptr [bp - 8], SECTORS_SEGMENT
0x00000000000028b3:  C7 46 F0 74 09       mov   word ptr [bp - 010h], OFFSET P_LineOpening_
0x00000000000028b8:  C7 46 F2 00 94       mov   word ptr [bp - 0Eh], PHYSICS_HIGHCODE_SEGMENT
0x00000000000028bd:  89 C3                mov   bx, ax
0x00000000000028bf:  8E 46 F8             mov   es, word ptr [bp - 8]
0x00000000000028c2:  C1 E3 04             shl   bx, 4
0x00000000000028c5:  BE 24 01             mov   si, OFFSET _validcount_global
0x00000000000028c8:  26 8B 47 06          mov   ax, word ptr es:[bx + MOBJ_POS_T.mp_y + 2]
0x00000000000028cc:  89 5E F6             mov   word ptr [bp - 0Ah], bx
0x00000000000028cf:  3B 04                cmp   ax, word ptr ds:[si]
0x00000000000028d1:  75 19                jne   label_1
0x00000000000028d3:  B8 56 4C             mov   ax, SECTOR_SOUNDTRAVERSED_SEGMENT
0x00000000000028d6:  8B 5E EE             mov   bx, word ptr [bp - 012h]
0x00000000000028d9:  8E C0                mov   es, ax
0x00000000000028db:  26 8A 07             mov   al, byte ptr es:[bx]
0x00000000000028de:  98                   cbw  
0x00000000000028df:  89 C3                mov   bx, ax
0x00000000000028e1:  88 D0                mov   al, dl
0x00000000000028e3:  98                   cbw  
0x00000000000028e4:  40                   inc   ax
0x00000000000028e5:  39 C3                cmp   bx, ax
0x00000000000028e7:  7F 03                jg    label_1
0x00000000000028e9:  E9 89 00             jmp   exit_p_recursive_sound
label_1:
0x00000000000028ec:  BB 24 01             mov   bx, OFFSET _validcount_global
0x00000000000028ef:  8B 07                mov   ax, word ptr ds:[bx]
0x00000000000028f1:  C4 5E F6             les   bx, ptr [bp - 0Ah]
0x00000000000028f4:  26 89 47 06          mov   word ptr es:[bx + SECTOR_T.sec_validcount], ax
0x00000000000028f8:  BB 56 4C             mov   bx, SECTOR_SOUNDTRAVERSED_SEGMENT
0x00000000000028fb:  8A 46 FC             mov   al, byte ptr [bp - 4]
0x00000000000028fe:  8E C3                mov   es, bx
0x0000000000002900:  8B 5E EE             mov   bx, word ptr [bp - 012h]
0x0000000000002903:  FE C0                inc   al
0x0000000000002905:  26 88 07             mov   byte ptr es:[bx], al
0x0000000000002908:  C4 5E F6             les   bx, ptr [bp - 0Ah]
0x000000000000290b:  31 C9                xor   cx, cx
0x000000000000290d:  26 8B 47 0A          mov   ax, word ptr es:[bx + SECTOR_T.sec_linecount]
0x0000000000002911:  8B 5E EE             mov   bx, word ptr [bp - 012h]
0x0000000000002914:  C7 46 F8 90 21       mov   word ptr [bp - 8], SECTORS_SEGMENT
0x0000000000002919:  C1 E3 04             shl   bx, 4
0x000000000000291c:  89 46 F4             mov   word ptr [bp - 0Ch], ax
0x000000000000291f:  89 5E F6             mov   word ptr [bp - 0Ah], bx
0x0000000000002922:  85 C0                test  ax, ax
0x0000000000002924:  7E 4F                jle   exit_p_recursive_sound
label_4:
0x0000000000002926:  C4 5E F6             les   bx, ptr [bp - 0Ah]
0x0000000000002929:  26 8B 47 0C          mov   ax, word ptr es:[bx + SECTOR_T.sec_linesoffset]
0x000000000000292d:  01 C8                add   ax, cx
0x000000000000292f:  01 C0                add   ax, ax
0x0000000000002931:  89 C3                mov   bx, ax
0x0000000000002933:  81 C3 50 CA          add   bx, OFFSET _linebuffer
0x0000000000002937:  8B 07                mov   ax, word ptr ds:[bx]
0x0000000000002939:  BB 4A 2B             mov   bx, LINEFLAGSLIST_SEGMENT
0x000000000000293c:  8E C3                mov   es, bx
0x000000000000293e:  89 C3                mov   bx, ax
0x0000000000002940:  BE 91 29             mov   si, LINES_SEGMENT
0x0000000000002943:  26 8A 1F             mov   bl, byte ptr es:[bx]
0x0000000000002946:  C7 46 FA 00 70       mov   word ptr [bp - 6], LINES_PHYSICS_SEGMENT
0x000000000000294b:  88 5E FE             mov   byte ptr [bp - 2], bl
0x000000000000294e:  8E C6                mov   es, si
0x0000000000002950:  89 C3                mov   bx, ax
0x0000000000002952:  89 C6                mov   si, ax
0x0000000000002954:  C1 E3 02             shl   bx, 2
0x0000000000002957:  C1 E6 04             shl   si, 4
0x000000000000295a:  26 8B 47 02          mov   ax, word ptr es:[bx + LINE_T.l_sidenum + 2]
0x000000000000295e:  8E 46 FA             mov   es, word ptr [bp - 6]
0x0000000000002961:  26 8B 7C 0A          mov   di, word ptr es:[si + LINE_PHYSICS_T.lp_frontsecnum]
0x0000000000002965:  26 8B 5C 0C          mov   bx, word ptr es:[si + LINE_PHYSICS_T.lp_backsecnum]
0x0000000000002969:  F6 46 FE 04          test  byte ptr [bp - 2], ML_TWOSIDED
0x000000000000296d:  75 0C                jne   label_3
label_5:
0x000000000000296f:  41                   inc   cx
0x0000000000002970:  3B 4E F4             cmp   cx, word ptr [bp - 0Ch]
0x0000000000002973:  7C B1                jl    label_4
exit_p_recursive_sound:
0x0000000000002975:  C9                   LEAVE_MACRO 
0x0000000000002976:  5F                   pop   di
0x0000000000002977:  5E                   pop   si
0x0000000000002978:  59                   pop   cx
0x0000000000002979:  5B                   pop   bx
0x000000000000297a:  C3                   ret   
label_3:
0x000000000000297b:  89 FA                mov   dx, di
0x000000000000297d:  FF 5E F0             call  dword ptr [bp - 010h]
0x0000000000002980:  BB F0 06             mov   bx, OFFSET _lineopening + 0
0x0000000000002983:  8B 07                mov   ax, word ptr ds:[bx]
0x0000000000002985:  BB F2 06             mov   bx, OFFSET _lineopening + 2
0x0000000000002988:  3B 07                cmp   ax, word ptr ds:[bx]
0x000000000000298a:  7E E3                jle   label_5
0x000000000000298c:  8E 46 FA             mov   es, word ptr [bp - 6]
0x000000000000298f:  26 8B 44 0A          mov   ax, word ptr es:[si + LINE_PHYSICS_T.lp_frontsecnum]
0x0000000000002993:  3B 46 EE             cmp   ax, word ptr [bp - 012h]
0x0000000000002996:  75 1A                jne   label_6
0x0000000000002998:  26 8B 74 0C          mov   si, word ptr es:[si + LINE_PHYSICS_T.lp_backsecnum]
label_8:
0x000000000000299c:  F6 46 FE 40          test  byte ptr [bp - 2], ML_SOUNDBLOCK
0x00000000000029a0:  74 14                je    label_7
0x00000000000029a2:  80 7E FC 00          cmp   byte ptr [bp - 4], 0
0x00000000000029a6:  75 C7                jne   label_5
0x00000000000029a8:  BA 01 00             mov   dx, 1
0x00000000000029ab:  89 F0                mov   ax, si
0x00000000000029ad:  E8 F0 FE             call  P_RecursiveSound_
0x00000000000029b0:  EB BD                jmp   label_5
label_6:
0x00000000000029b2:  89 C6                mov   si, ax
0x00000000000029b4:  EB E6                jmp   label_8
label_7:
0x00000000000029b6:  8A 46 FC             mov   al, byte ptr [bp - 4]
0x00000000000029b9:  98                   cbw  
0x00000000000029ba:  89 C2                mov   dx, ax
0x00000000000029bc:  89 F0                mov   ax, si
0x00000000000029be:  E8 DF FE             call  P_RecursiveSound_
0x00000000000029c1:  EB AC                jmp   label_5
0x00000000000029c3:  FC                   cld   

ENDP


PROC    P_NoiseAlert_ FAR
PUBLIC  P_NoiseAlert_

0x00000000000029c4:  53                   push  bx
0x00000000000029c5:  52                   push  dx
0x00000000000029c6:  56                   push  si
0x00000000000029c7:  BB 24 01             mov   bx, OFFSET _validcount_global
0x00000000000029ca:  BE EC 06             mov   si, OFFSET _playerMobj
0x00000000000029cd:  FF 07                inc   word ptr ds:[bx]
0x00000000000029cf:  8B 1C                mov   bx, word ptr ds:[si]
0x00000000000029d1:  31 D2                xor   dx, dx
0x00000000000029d3:  8B 47 04             mov   ax, word ptr ds:[bx + 4]
0x00000000000029d6:  E8 C7 FE             call  P_RecursiveSound_
0x00000000000029d9:  5E                   pop   si
0x00000000000029da:  5A                   pop   dx
0x00000000000029db:  5B                   pop   bx
0x00000000000029dc:  CB                   retf  
0x00000000000029dd:  FC                   cld   

ENDP


PROC    P_CheckMeleeRange_ NEAR
PUBLIC  P_CheckMeleeRange_

0x00000000000029de:  53                   push  bx
0x00000000000029df:  51                   push  cx
0x00000000000029e0:  52                   push  dx
0x00000000000029e1:  56                   push  si
0x00000000000029e2:  57                   push  di
0x00000000000029e3:  55                   push  bp
0x00000000000029e4:  89 E5                mov   bp, sp
0x00000000000029e6:  83 EC 10             sub   sp, 010h
0x00000000000029e9:  50                   push  ax
0x00000000000029ea:  89 C3                mov   bx, ax
0x00000000000029ec:  83 7F 22 00          cmp   word ptr ds:[bx + MOBJ_T.m_targetRef], 0
0x00000000000029f0:  75 09                jne   label_9
exit_check_meleerange_return_0:
0x00000000000029f2:  30 C0                xor   al, al
exit_check_meleerange:
0x00000000000029f4:  C9                   LEAVE_MACRO 
0x00000000000029f5:  5F                   pop   di
0x00000000000029f6:  5E                   pop   si
0x00000000000029f7:  5A                   pop   dx
0x00000000000029f8:  59                   pop   cx
0x00000000000029f9:  5B                   pop   bx
0x00000000000029fa:  C3                   ret   
label_9:
0x00000000000029fb:  BB 2C 00             mov   bx, SIZEOF_THINKER_T
0x00000000000029fe:  2D 04 34             sub   ax, (OFFSET _thinkerlist + THINKER_T.t_data)
0x0000000000002a01:  31 D2                xor   dx, dx
0x0000000000002a03:  F7 F3                div   bx
0x0000000000002a05:  6B F0 18             imul  si, ax, SIZEOF_MOBJ_POS_T
0x0000000000002a08:  B8 F5 6A             mov   ax, MOBJPOSLIST_6800_SEGMENT
0x0000000000002a0b:  8E C0                mov   es, ax
0x0000000000002a0d:  26 8B 04             mov   ax, word ptr es:[si]
0x0000000000002a10:  89 46 FC             mov   word ptr [bp - 4], ax
0x0000000000002a13:  26 8B 44 02          mov   ax, word ptr es:[si + 2]
0x0000000000002a17:  8B 7E EE             mov   di, word ptr [bp - 012h]
0x0000000000002a1a:  89 46 F2             mov   word ptr [bp - 0Eh], ax
0x0000000000002a1d:  26 8B 44 04          mov   ax, word ptr es:[si + MOBJ_POS_T.mp_y + 0]
0x0000000000002a21:  8B 7D 22             mov   di, word ptr ds:[di + MOBJ_T.m_targetRef]
0x0000000000002a24:  89 46 F4             mov   word ptr [bp - 0Ch], ax
0x0000000000002a27:  6B C7 2C             imul  ax, di, SIZEOF_THINKER_T
0x0000000000002a2a:  6B FF 18             imul  di, di, SIZEOF_MOBJ_POS_T
0x0000000000002a2d:  05 04 34             add   ax, (OFFSET _thinkerlist + THINKER_T.t_data)
0x0000000000002a30:  89 46 FE             mov   word ptr [bp - 2], ax
0x0000000000002a33:  26 8B 05             mov   ax, word ptr es:[di]
0x0000000000002a36:  89 46 F6             mov   word ptr [bp - 0Ah], ax
0x0000000000002a39:  26 8B 45 02          mov   ax, word ptr es:[di + 2]
0x0000000000002a3d:  89 46 F0             mov   word ptr [bp - 010h], ax
0x0000000000002a40:  26 8B 45 04          mov   ax, word ptr es:[di + MOBJ_POS_T.mp_y + 0]
0x0000000000002a44:  8B 5E FE             mov   bx, word ptr [bp - 2]
0x0000000000002a47:  89 46 F8             mov   word ptr [bp - 8], ax
0x0000000000002a4a:  8A 47 1A             mov   al, byte ptr ds:[bx + MOBJ_T.m_mobjtype]
0x0000000000002a4d:  30 E4                xor   ah, ah
0x0000000000002a4f:  6B C0 0B             imul  ax, ax, SIZEOF_MOBJINFO_T
0x0000000000002a52:  26 8B 4C 06          mov   cx, word ptr es:[si + MOBJ_POS_T.mp_y + 2]
0x0000000000002a56:  89 C3                mov   bx, ax
0x0000000000002a58:  26 8B 55 06          mov   dx, word ptr es:[di + MOBJ_POS_T.mp_y + 2]
0x0000000000002a5c:  81 C3 65 C4          add   bx, (OFFSET _mobjinfo + MOBJINFO_T.mobjinfo_radius)
0x0000000000002a60:  8A 07                mov   al, byte ptr ds:[bx]
0x0000000000002a62:  8B 5E F8             mov   bx, word ptr [bp - 8]
0x0000000000002a65:  88 46 FA             mov   byte ptr [bp - 6], al
0x0000000000002a68:  2B 5E F4             sub   bx, word ptr [bp - 0Ch]
0x0000000000002a6b:  19 CA                sbb   dx, cx
0x0000000000002a6d:  8B 46 F6             mov   ax, word ptr [bp - 0Ah]
0x0000000000002a70:  89 D1                mov   cx, dx
0x0000000000002a72:  2B 46 FC             sub   ax, word ptr [bp - 4]
0x0000000000002a75:  8B 56 F0             mov   dx, word ptr [bp - 010h]
0x0000000000002a78:  1B 56 F2             sbb   dx, word ptr [bp - 0Eh]
0x0000000000002a7b:  C6 46 FB 00          mov   byte ptr [bp - 5], 0
0x0000000000002a7f:  FF 1E D0 0C          call  dword ptr ds:[_P_AproxDistance]
0x0000000000002a83:  8B 46 FA             mov   ax, word ptr [bp - 6]
0x0000000000002a86:  05 2C 00             add   ax, (MELEERANGE - 20)
0x0000000000002a89:  39 C2                cmp   dx, ax
0x0000000000002a8b:  7C 03                jl    label_10
0x0000000000002a8d:  E9 62 FF             jmp   exit_check_meleerange_return_0
label_10:
0x0000000000002a90:  8B 56 FE             mov   dx, word ptr [bp - 2]
0x0000000000002a93:  8B 46 EE             mov   ax, word ptr [bp - 012h]
0x0000000000002a96:  89 F9                mov   cx, di
0x0000000000002a98:  89 F3                mov   bx, si
0x0000000000002a9a:  FF 1E CC 0C          call  dword ptr ds:[_P_CheckSightTemp]
0x0000000000002a9e:  84 C0                test  al, al
0x0000000000002aa0:  75 03                jne   exit_check_meleerange_return_1
0x0000000000002aa2:  E9 4F FF             jmp   exit_check_meleerange
exit_check_meleerange_return_1:
0x0000000000002aa5:  B0 01                mov   al, 1
0x0000000000002aa7:  C9                   LEAVE_MACRO 
0x0000000000002aa8:  5F                   pop   di
0x0000000000002aa9:  5E                   pop   si
0x0000000000002aaa:  5A                   pop   dx
0x0000000000002aab:  59                   pop   cx
0x0000000000002aac:  5B                   pop   bx
0x0000000000002aad:  C3                   ret   

ENDP


PROC    P_CheckMissileRange_ NEAR
PUBLIC  P_CheckMissileRange_

0x0000000000002aae:  53                   push  bx
0x0000000000002aaf:  51                   push  cx
0x0000000000002ab0:  52                   push  dx
0x0000000000002ab1:  56                   push  si
0x0000000000002ab2:  57                   push  di
0x0000000000002ab3:  55                   push  bp
0x0000000000002ab4:  89 E5                mov   bp, sp
0x0000000000002ab6:  83 EC 12             sub   sp, 012h
0x0000000000002ab9:  89 C6                mov   si, ax
0x0000000000002abb:  6B 5C 22 2C          imul  bx, word ptr ds:[si + MOBJ_T.m_targetRef], SIZEOF_THINKER_T
0x0000000000002abf:  B9 2C 00             mov   cx, SIZEOF_THINKER_T
0x0000000000002ac2:  8D 87 04 34          lea   ax, ds:[bx + (OFFSET _thinkerlist + THINKER_T.t_data)]
0x0000000000002ac6:  31 D2                xor   dx, dx
0x0000000000002ac8:  89 46 F6             mov   word ptr [bp - 0Ah], ax
0x0000000000002acb:  8D 84 FC CB          lea   ax, ds:[si - (OFFSET _thinkerlist + THINKER_T.t_data)]
0x0000000000002acf:  F7 F1                div   cx
0x0000000000002ad1:  6B F8 18             imul  di, ax, SIZEOF_MOBJ_POS_T
0x0000000000002ad4:  31 D2                xor   dx, dx
0x0000000000002ad6:  89 D8                mov   ax, bx
0x0000000000002ad8:  F7 F1                div   cx
0x0000000000002ada:  6B D8 18             imul  bx, ax, SIZEOF_MOBJ_POS_T
0x0000000000002add:  C7 46 EE 5A 01       mov   word ptr [bp - 012h], GETMELEESTATEADDR
0x0000000000002ae2:  C7 46 F0 D9 92       mov   word ptr [bp - 010h], INFOFUNCLOADSEGMENT
0x0000000000002ae7:  C7 46 FE F5 6A       mov   word ptr [bp - 2], MOBJPOSLIST_6800_SEGMENT
0x0000000000002aec:  C7 46 FA F5 6A       mov   word ptr [bp - 6], MOBJPOSLIST_6800_SEGMENT
0x0000000000002af1:  8B 56 F6             mov   dx, word ptr [bp - 0Ah]
0x0000000000002af4:  89 5E FC             mov   word ptr [bp - 4], bx
0x0000000000002af7:  89 D9                mov   cx, bx
0x0000000000002af9:  89 F0                mov   ax, si
0x0000000000002afb:  89 FB                mov   bx, di
0x0000000000002afd:  FF 1E CC 0C          call  dword ptr ds:[_P_CheckSightTemp]
0x0000000000002b01:  84 C0                test  al, al
0x0000000000002b03:  74 12                je    exit_checkmissilerange
0x0000000000002b05:  8E 46 FE             mov   es, word ptr [bp - 2]
0x0000000000002b08:  26 F6 45 14 40       test  byte ptr es:[di + MOBJ_POS_T.mp_flags1], MF_JUSTHIT
0x0000000000002b0d:  75 0F                jne   label_11
0x0000000000002b0f:  80 7C 24 00          cmp   byte ptr ds:[si + MOBJ_T.m_reactiontime], 0
0x0000000000002b13:  74 12                je    label_12
exit_checkmissilerange_return_0:
0x0000000000002b15:  30 C0                xor   al, al
exit_checkmissilerange:
0x0000000000002b17:  C9                   LEAVE_MACRO 
0x0000000000002b18:  5F                   pop   di
0x0000000000002b19:  5E                   pop   si
0x0000000000002b1a:  5A                   pop   dx
0x0000000000002b1b:  59                   pop   cx
0x0000000000002b1c:  5B                   pop   bx
0x0000000000002b1d:  C3                   ret   
label_11:
0x0000000000002b1e:  B0 01                mov   al, 1
0x0000000000002b20:  26 80 65 14 BF       and   byte ptr es:[di + MOBJ_POS_T.mp_flags1], (NOT MF_JUSTHIT)
0x0000000000002b25:  EB F0                jmp   exit_checkmissilerange
label_12:
0x0000000000002b27:  8E 46 FA             mov   es, word ptr [bp - 6]
0x0000000000002b2a:  8B 5E FC             mov   bx, word ptr [bp - 4]
0x0000000000002b2d:  26 8B 07             mov   ax, word ptr es:[bx]
0x0000000000002b30:  89 46 F2             mov   word ptr [bp - 0Eh], ax
0x0000000000002b33:  26 8B 47 02          mov   ax, word ptr es:[bx + 2]
0x0000000000002b37:  26 8B 4F 06          mov   cx, word ptr es:[bx + MOBJ_POS_T.mp_y + 2]
0x0000000000002b3b:  89 46 F4             mov   word ptr [bp - 0Ch], ax
0x0000000000002b3e:  26 8B 47 04          mov   ax, word ptr es:[bx + MOBJ_POS_T.mp_y + 0]
0x0000000000002b42:  8E 46 FE             mov   es, word ptr [bp - 2]
0x0000000000002b45:  26 8B 55 04          mov   dx, word ptr es:[di + MOBJ_POS_T.mp_y + 0]
0x0000000000002b49:  89 FB                mov   bx, di
0x0000000000002b4b:  29 C2                sub   dx, ax
0x0000000000002b4d:  89 D0                mov   ax, dx
0x0000000000002b4f:  26 8B 57 06          mov   dx, word ptr es:[bx + MOBJ_POS_T.mp_y + 2]
0x0000000000002b53:  19 CA                sbb   dx, cx
0x0000000000002b55:  89 D1                mov   cx, dx
0x0000000000002b57:  26 8B 15             mov   dx, word ptr es:[di]
0x0000000000002b5a:  2B 56 F2             sub   dx, word ptr [bp - 0Eh]
0x0000000000002b5d:  26 8B 5F 02          mov   bx, word ptr es:[bx + 2]
0x0000000000002b61:  1B 5E F4             sbb   bx, word ptr [bp - 0Ch]
0x0000000000002b64:  89 5E F8             mov   word ptr [bp - 8], bx
0x0000000000002b67:  89 C3                mov   bx, ax
0x0000000000002b69:  89 D0                mov   ax, dx
0x0000000000002b6b:  8B 56 F8             mov   dx, word ptr [bp - 8]
0x0000000000002b6e:  FF 1E D0 0C          call  dword ptr ds:[_P_AproxDistance]
0x0000000000002b72:  8A 44 1A             mov   al, byte ptr ds:[si + MOBJ_T.m_mobjtype]
0x0000000000002b75:  30 E4                xor   ah, ah
0x0000000000002b77:  83 EA 40             sub   dx, 64
0x0000000000002b7a:  FF 5E EE             call  dword ptr [bp - 012h]
0x0000000000002b7d:  85 C0                test  ax, ax
0x0000000000002b7f:  75 04                jne   label_13
0x0000000000002b81:  81 EA 80 00          sub   dx, 128
label_13:
0x0000000000002b85:  80 7C 1A 03          cmp   byte ptr ds:[si + MOBJ_T.m_mobjtype], MT_VILE
0x0000000000002b89:  75 06                jne   label_14
0x0000000000002b8b:  81 FA 80 03          cmp   dx, (14 * 64)
0x0000000000002b8f:  7F 84                jg    exit_checkmissilerange_return_0
label_14:
0x0000000000002b91:  80 7C 1A 05          cmp   byte ptr ds:[si + MOBJ_T.m_mobjtype], MT_UNDEAD
0x0000000000002b95:  75 0B                jne   label_16
0x0000000000002b97:  81 FA C4 00          cmp   dx, 196
0x0000000000002b9b:  7D 03                jge   label_15
0x0000000000002b9d:  E9 75 FF             jmp   exit_checkmissilerange_return_0
label_15:
0x0000000000002ba0:  D1 FA                sar   dx, 1
label_16:
0x0000000000002ba2:  8A 44 1A             mov   al, byte ptr ds:[si + MOBJ_T.m_mobjtype]
0x0000000000002ba5:  3C 15                cmp   al, MT_CYBORG
0x0000000000002ba7:  75 2C                jne   label_17
label_20:
0x0000000000002ba9:  D1 FA                sar   dx, 1
label_21:
0x0000000000002bab:  81 FA C8 00          cmp   dx, 200
0x0000000000002baf:  7E 03                jle   label_18
0x0000000000002bb1:  BA C8 00             mov   dx, 200
label_18:
0x0000000000002bb4:  80 7C 1A 15          cmp   byte ptr ds:[si + MOBJ_T.m_mobjtype], MT_CYBORG
0x0000000000002bb8:  75 09                jne   label_19
0x0000000000002bba:  81 FA A0 00          cmp   dx, 160
0x0000000000002bbe:  7E 03                jle   label_19
0x0000000000002bc0:  BA A0 00             mov   dx, 160
label_19:
0x0000000000002bc3:  E8 EA 5D             call  P_Random_
0x0000000000002bc6:  30 E4                xor   ah, ah
0x0000000000002bc8:  39 D0                cmp   ax, dx
0x0000000000002bca:  7D 13                jge   exit_checkmissilerange_return_1
0x0000000000002bcc:  30 C0                xor   al, al
0x0000000000002bce:  C9                   LEAVE_MACRO 
0x0000000000002bcf:  5F                   pop   di
0x0000000000002bd0:  5E                   pop   si
0x0000000000002bd1:  5A                   pop   dx
0x0000000000002bd2:  59                   pop   cx
0x0000000000002bd3:  5B                   pop   bx
0x0000000000002bd4:  C3                   ret   
label_17:
0x0000000000002bd5:  3C 13                cmp   al, MT_SPIDER
0x0000000000002bd7:  74 D0                je    label_20
0x0000000000002bd9:  3C 12                cmp   al, MT_SKULL
0x0000000000002bdb:  74 CC                je    label_20
0x0000000000002bdd:  EB CC                jmp   label_21
exit_checkmissilerange_return_1:
0x0000000000002bdf:  B0 01                mov   al, 1
0x0000000000002be1:  C9                   LEAVE_MACRO 
0x0000000000002be2:  5F                   pop   di
0x0000000000002be3:  5E                   pop   si
0x0000000000002be4:  5A                   pop   dx
0x0000000000002be5:  59                   pop   cx
0x0000000000002be6:  5B                   pop   bx
0x0000000000002be7:  C3                   ret   

; todo some table?

_some_lookup_table_2:

dw 02C51h
dw 02CB6h
dw 02CC8h
dw 02CD0h
dw 02CE5h
dw 02CEEh
dw 02D01h
dw 02D12h


ENDP


PROC    P_Move_ NEAR
PUBLIC  P_Move_


0x0000000000002bf8:  52                   push  dx
0x0000000000002bf9:  56                   push  si
0x0000000000002bfa:  57                   push  di
0x0000000000002bfb:  55                   push  bp
0x0000000000002bfc:  89 E5                mov   bp, sp
0x0000000000002bfe:  83 EC 0A             sub   sp, 0Ah
0x0000000000002c01:  89 C6                mov   si, ax
0x0000000000002c03:  89 DF                mov   di, bx
0x0000000000002c05:  89 4E FC             mov   word ptr [bp - 4], cx
0x0000000000002c08:  80 7C 1F 08          cmp   byte ptr ds:[si + MOBJ_T.m_movedir], DI_NODIR
0x0000000000002c0c:  74 41                je    label_22
0x0000000000002c0e:  8E C1                mov   es, cx
0x0000000000002c10:  26 8B 05             mov   ax, word ptr es:[di]
0x0000000000002c13:  89 46 F8             mov   word ptr [bp - 8], ax
0x0000000000002c16:  26 8B 45 04          mov   ax, word ptr es:[di + MOBJ_POS_T.mp_y + 0]
0x0000000000002c1a:  89 46 F6             mov   word ptr [bp - 0Ah], ax
0x0000000000002c1d:  26 8B 45 06          mov   ax, word ptr es:[di + MOBJ_POS_T.mp_y + 2]
0x0000000000002c21:  89 46 FA             mov   word ptr [bp - 6], ax
0x0000000000002c24:  8A 44 1A             mov   al, byte ptr ds:[si + MOBJ_T.m_mobjtype]
0x0000000000002c27:  30 E4                xor   ah, ah
0x0000000000002c29:  6B C0 0B             imul  ax, ax, SIZEOF_MOBJINFO_T
0x0000000000002c2c:  26 8B 4D 02          mov   cx, word ptr es:[di + 2]
0x0000000000002c30:  8A 54 1F             mov   dl, byte ptr ds:[si + MOBJ_T.m_movedir]
0x0000000000002c33:  89 C3                mov   bx, ax
0x0000000000002c35:  8A 87 64 C4          mov   al, byte ptr ds:[bx + (OFFSET _mobjinfo + MOBJINFO_T.mobjinfo_speed)]
0x0000000000002c39:  81 C3 64 C4          add   bx, (OFFSET _mobjinfo + MOBJINFO_T.mobjinfo_speed)
0x0000000000002c3d:  30 E4                xor   ah, ah
0x0000000000002c3f:  80 FA 07             cmp   dl, DI_NORTHWEST
0x0000000000002c42:  77 0F                ja    label_24
0x0000000000002c44:  30 F6                xor   dh, dh
0x0000000000002c46:  89 D3                mov   bx, dx
0x0000000000002c48:  01 D3                add   bx, dx
0x0000000000002c4a:  2E FF A7 E8 2B       jmp   word ptr cs:[bx + OFFSET _some_lookup_table_2]
label_22:
0x0000000000002c4f:  EB 61                jmp   label_23
0x0000000000002c51:  01 C1                add   cx, ax
label_24:
0x0000000000002c53:  FF 76 FA             push  word ptr [bp - 6]
0x0000000000002c56:  FF 76 F6             push  word ptr [bp - 0Ah]
0x0000000000002c59:  89 FB                mov   bx, di
0x0000000000002c5b:  51                   push  cx
0x0000000000002c5c:  89 F0                mov   ax, si
0x0000000000002c5e:  FF 76 F8             push  word ptr [bp - 8]
0x0000000000002c61:  8B 4E FC             mov   cx, word ptr [bp - 4]
0x0000000000002c64:  FF 1E DC 0C          call  dword ptr ds:[_P_TryMove]
0x0000000000002c68:  84 C0                test  al, al
0x0000000000002c6a:  75 61                jne   label_25
0x0000000000002c6c:  8E 46 FC             mov   es, word ptr [bp - 4]
0x0000000000002c6f:  26 F6 45 15 40       test  byte ptr es:[di + MOBJ_POS_T.mp_flags1 + 1], (MF_FLOAT SHR 8)
0x0000000000002c74:  74 6D                je    jump_to_label_28
0x0000000000002c76:  BB 2D 01             mov   bx, OFFSET _floatok
0x0000000000002c79:  80 3F 00             cmp   byte ptr ds:[bx], 0
0x0000000000002c7c:  74 65                je    jump_to_label_28
0x0000000000002c7e:  BB 52 01             mov   bx, OFFSET _tmfloorz
0x0000000000002c81:  8B 17                mov   dx, word ptr ds:[bx]
0x0000000000002c83:  30 F6                xor   dh, dh
0x0000000000002c85:  8B 07                mov   ax, word ptr ds:[bx]
0x0000000000002c87:  80 E2 07             and   dl, 7
0x0000000000002c8a:  C1 F8 03             sar   ax, 3
0x0000000000002c8d:  C1 E2 0D             shl   dx, 13
0x0000000000002c90:  26 3B 45 0A          cmp   ax, word ptr es:[di + MOBJ_POS_T.mp_z + 2]
0x0000000000002c94:  7F 08                jg    label_29
0x0000000000002c96:  75 73                jne   label_30
0x0000000000002c98:  26 3B 55 08          cmp   dx, word ptr es:[di + MOBJ_POS_T.mp_z + 0]
0x0000000000002c9c:  76 6D                jbe   label_30
label_29:
0x0000000000002c9e:  26 83 45 0A 04       add   word ptr es:[di + MOBJ_POS_T.mp_z + 2], FLOATSPEED_HIGHBITS
label_27:
0x0000000000002ca3:  8E 46 FC             mov   es, word ptr [bp - 4]
0x0000000000002ca6:  B0 01                mov   al, 1
0x0000000000002ca8:  26 80 4D 16 20       or    byte ptr es:[di + MOBJ_POS_T.mp_flags2], MF_INFLOAT
exit_p_move:
0x0000000000002cad:  C9                   LEAVE_MACRO 
0x0000000000002cae:  5F                   pop   di
0x0000000000002caf:  5E                   pop   si
0x0000000000002cb0:  5A                   pop   dx
0x0000000000002cb1:  C3                   ret   
label_23:
0x0000000000002cb2:  30 C0                xor   al, al
0x0000000000002cb4:  EB F7                jmp   exit_p_move
0x0000000000002cb6:  BA 98 B7             mov   dx, 47000
0x0000000000002cb9:  F7 E2                mul   dx
0x0000000000002cbb:  01 46 F8             add   word ptr [bp - 8], ax
0x0000000000002cbe:  11 D1                adc   cx, dx
0x0000000000002cc0:  01 46 F6             add   word ptr [bp - 0Ah], ax
0x0000000000002cc3:  11 56 FA             adc   word ptr [bp - 6], dx
0x0000000000002cc6:  EB 8B                jmp   label_24
0x0000000000002cc8:  01 46 FA             add   word ptr [bp - 6], ax
0x0000000000002ccb:  EB 86                jmp   label_24
label_25:
0x0000000000002ccd:  E9 A5 00             jmp   label_26
0x0000000000002cd0:  BA 98 B7             mov   dx, 47000
0x0000000000002cd3:  F7 E2                mul   dx
0x0000000000002cd5:  29 46 F8             sub   word ptr [bp - 8], ax
0x0000000000002cd8:  19 D1                sbb   cx, dx
0x0000000000002cda:  01 46 F6             add   word ptr [bp - 0Ah], ax
0x0000000000002cdd:  11 56 FA             adc   word ptr [bp - 6], dx
0x0000000000002ce0:  E9 70 FF             jmp   label_24
jump_to_label_28:
0x0000000000002ce3:  EB 40                jmp   label_28
0x0000000000002ce5:  83 6E F8 00          sub   word ptr [bp - 8], 0
0x0000000000002ce9:  19 C1                sbb   cx, ax
0x0000000000002ceb:  E9 65 FF             jmp   label_24
0x0000000000002cee:  BA 98 B7             mov   dx, 47000
0x0000000000002cf1:  F7 E2                mul   dx
0x0000000000002cf3:  29 46 F8             sub   word ptr [bp - 8], ax
0x0000000000002cf6:  19 D1                sbb   cx, dx
0x0000000000002cf8:  29 46 F6             sub   word ptr [bp - 0Ah], ax
0x0000000000002cfb:  19 56 FA             sbb   word ptr [bp - 6], dx
0x0000000000002cfe:  E9 52 FF             jmp   label_24
0x0000000000002d01:  83 6E F6 00          sub   word ptr [bp - 0Ah], 0
0x0000000000002d05:  19 46 FA             sbb   word ptr [bp - 6], ax
0x0000000000002d08:  E9 48 FF             jmp   label_24
label_30:
0x0000000000002d0b:  26 83 6D 0A 04       sub   word ptr es:[di + MOBJ_POS_T.mp_z + 2], FLOATSPEED_HIGHBITS
0x0000000000002d10:  EB 91                jmp   label_27
0x0000000000002d12:  BA 98 B7             mov   dx, 47000
0x0000000000002d15:  F7 E2                mul   dx
0x0000000000002d17:  01 46 F8             add   word ptr [bp - 8], ax
0x0000000000002d1a:  11 D1                adc   cx, dx
0x0000000000002d1c:  29 46 F6             sub   word ptr [bp - 0Ah], ax
0x0000000000002d1f:  19 56 FA             sbb   word ptr [bp - 6], dx
0x0000000000002d22:  E9 2E FF             jmp   label_24
label_28:
0x0000000000002d25:  BB 06 07             mov   bx, OFFSET _numspechit
0x0000000000002d28:  83 3F 00             cmp   word ptr ds:[bx], 0
0x0000000000002d2b:  74 85                je    label_23
0x0000000000002d2d:  BB 2C 00             mov   bx, SIZEOF_THINKER_T
0x0000000000002d30:  8D 84 FC CB          lea   ax, ds:[si - (OFFSET _thinkerlist + THINKER_T.t_data)]
0x0000000000002d34:  31 D2                xor   dx, dx
0x0000000000002d36:  F7 F3                div   bx
0x0000000000002d38:  C6 46 FE 00          mov   byte ptr [bp - 2], 0
0x0000000000002d3c:  C6 44 1F 08          mov   byte ptr ds:[si + MOBJ_T.m_movedir], DI_NODIR
0x0000000000002d40:  89 C7                mov   di, ax
label_32:
0x0000000000002d42:  BB 06 07             mov   bx, OFFSET _numspechit
0x0000000000002d45:  8B 07                mov   ax, word ptr ds:[bx]
0x0000000000002d47:  89 C2                mov   dx, ax
0x0000000000002d49:  4A                   dec   dx
0x0000000000002d4a:  89 17                mov   word ptr ds:[bx], dx
0x0000000000002d4c:  85 C0                test  ax, ax
0x0000000000002d4e:  74 1D                je    label_31
0x0000000000002d50:  89 D3                mov   bx, dx
0x0000000000002d52:  89 F9                mov   cx, di
0x0000000000002d54:  01 D3                add   bx, dx
0x0000000000002d56:  89 F0                mov   ax, si
0x0000000000002d58:  8B 97 BA 00          mov   dx, word ptr ds:[bx + _spechit]
0x0000000000002d5c:  31 DB                xor   bx, bx
0x0000000000002d5e:  0E                   push  cs
0x0000000000002d5f:  E8 32 54             call  P_UseSpecialLine_
0x0000000000002d62:  90                   nop   
0x0000000000002d63:  84 C0                test  al, al
0x0000000000002d65:  74 DB                je    label_32
0x0000000000002d67:  C6 46 FE 01          mov   byte ptr [bp - 2], 1
0x0000000000002d6b:  EB D5                jmp   label_32
label_31:
0x0000000000002d6d:  8A 46 FE             mov   al, byte ptr [bp - 2]
0x0000000000002d70:  C9                   LEAVE_MACRO 
0x0000000000002d71:  5F                   pop   di
0x0000000000002d72:  5E                   pop   si
0x0000000000002d73:  5A                   pop   dx
0x0000000000002d74:  C3                   ret   
label_26:
0x0000000000002d75:  8E 46 FC             mov   es, word ptr [bp - 4]
0x0000000000002d78:  26 80 65 16 DF       and   byte ptr es:[di + MOBJ_POS_T.mp_flags2], (NOT MF_INFLOAT)
0x0000000000002d7d:  26 F6 45 15 40       test  byte ptr es:[di + MOBJ_POS_T.mp_flags1 + 1], (MF_FLOAT SHR 8)
0x0000000000002d82:  75 17                jne   exit_p_move_return_1
0x0000000000002d84:  8B 44 06             mov   ax, word ptr ds:[si + MOBJ_T.m_floorz]
0x0000000000002d87:  C1 F8 03             sar   ax, 3
0x0000000000002d8a:  26 89 45 0A          mov   word ptr es:[di + MOBJ_POS_T.mp_z + 2], ax
0x0000000000002d8e:  8B 44 06             mov   ax, word ptr ds:[si + MOBJ_T.m_floorz]
0x0000000000002d91:  25 07 00             and   ax, 7
0x0000000000002d94:  C1 E0 0D             shl   ax, 13
0x0000000000002d97:  26 89 45 08          mov   word ptr es:[di + MOBJ_POS_T.mp_z + 0], ax
exit_p_move_return_1:
0x0000000000002d9b:  B0 01                mov   al, 1
0x0000000000002d9d:  C9                   LEAVE_MACRO 
0x0000000000002d9e:  5F                   pop   di
0x0000000000002d9f:  5E                   pop   si
0x0000000000002da0:  5A                   pop   dx
0x0000000000002da1:  C3                   ret   

ENDP


PROC    P_TryWalk_ NEAR
PUBLIC  P_TryWalk_

0x0000000000002da2:  56                   push  si
0x0000000000002da3:  89 C6                mov   si, ax
0x0000000000002da5:  E8 50 FE             call  P_Move_
0x0000000000002da8:  84 C0                test  al, al
0x0000000000002daa:  75 02                jne   label_37
0x0000000000002dac:  5E                   pop   si
0x0000000000002dad:  C3                   ret   
label_37:
0x0000000000002dae:  E8 FF 5B             call  P_Random_
0x0000000000002db1:  88 C3                mov   bl, al
0x0000000000002db3:  80 E3 0F             and   bl, 15
0x0000000000002db6:  30 FF                xor   bh, bh
0x0000000000002db8:  B0 01                mov   al, 1
0x0000000000002dba:  89 5C 20             mov   word ptr ds:[si + MOBJ_T.m_movecount], bx
0x0000000000002dbd:  5E                   pop   si
0x0000000000002dbe:  C3                   ret   
0x0000000000002dbf:  FC                   cld   

ENDP


PROC    P_NewChaseDir_ NEAR
PUBLIC  P_NewChaseDir_

0x0000000000002dc0:  52                   push  dx
0x0000000000002dc1:  56                   push  si
0x0000000000002dc2:  57                   push  di
0x0000000000002dc3:  55                   push  bp
0x0000000000002dc4:  89 E5                mov   bp, sp
0x0000000000002dc6:  83 EC 16             sub   sp, 016h
0x0000000000002dc9:  89 C6                mov   si, ax
0x0000000000002dcb:  89 DF                mov   di, bx
0x0000000000002dcd:  89 4E FA             mov   word ptr [bp - 6], cx
0x0000000000002dd0:  8E C1                mov   es, cx
0x0000000000002dd2:  26 8B 05             mov   ax, word ptr es:[di]
0x0000000000002dd5:  89 46 EE             mov   word ptr [bp - 012h], ax
0x0000000000002dd8:  26 8B 45 02          mov   ax, word ptr es:[di + 2]
0x0000000000002ddc:  89 46 F2             mov   word ptr [bp - 0Eh], ax
0x0000000000002ddf:  26 8B 45 04          mov   ax, word ptr es:[di + MOBJ_POS_T.mp_y + 0]
0x0000000000002de3:  89 46 F0             mov   word ptr [bp - 010h], ax
0x0000000000002de6:  8A 44 1F             mov   al, byte ptr ds:[si + MOBJ_T.m_movedir]
0x0000000000002de9:  88 46 FE             mov   byte ptr [bp - 2], al
0x0000000000002dec:  6B 44 22 2C          imul  ax, word ptr ds:[si + MOBJ_T.m_targetRef], SIZEOF_THINKER_T
0x0000000000002df0:  BB 2C 00             mov   bx, SIZEOF_THINKER_T
0x0000000000002df3:  31 D2                xor   dx, dx
0x0000000000002df5:  F7 F3                div   bx
0x0000000000002df7:  6B D0 18             imul  dx, ax, SIZEOF_MOBJ_POS_T
0x0000000000002dfa:  B8 F5 6A             mov   ax, MOBJPOSLIST_6800_SEGMENT
0x0000000000002dfd:  26 8B 4D 06          mov   cx, word ptr es:[di + MOBJ_POS_T.mp_y + 2]
0x0000000000002e01:  8E C0                mov   es, ax
0x0000000000002e03:  8A 46 FE             mov   al, byte ptr [bp - 2]
0x0000000000002e06:  98                   cbw  
0x0000000000002e07:  89 C3                mov   bx, ax
0x0000000000002e09:  8A 87 96 0E          mov   al, byte ptr ds:[bx + _opposite] ; todo make cs?
0x0000000000002e0d:  89 D3                mov   bx, dx
0x0000000000002e0f:  88 46 FC             mov   byte ptr [bp - 4], al
0x0000000000002e12:  26 8B 07             mov   ax, word ptr es:[bx]
0x0000000000002e15:  2B 46 EE             sub   ax, word ptr [bp - 012h]
0x0000000000002e18:  89 46 F6             mov   word ptr [bp - 0Ah], ax
0x0000000000002e1b:  26 8B 47 02          mov   ax, word ptr es:[bx + 2]
0x0000000000002e1f:  1B 46 F2             sbb   ax, word ptr [bp - 0Eh]
0x0000000000002e22:  89 46 F8             mov   word ptr [bp - 8], ax
0x0000000000002e25:  26 8B 47 04          mov   ax, word ptr es:[bx + MOBJ_POS_T.mp_y + 0]
0x0000000000002e29:  2B 46 F0             sub   ax, word ptr [bp - 010h]
0x0000000000002e2c:  89 46 F4             mov   word ptr [bp - 0Ch], ax
0x0000000000002e2f:  8B 46 F8             mov   ax, word ptr [bp - 8]
0x0000000000002e32:  26 8B 57 06          mov   dx, word ptr es:[bx + MOBJ_POS_T.mp_y + 2]
0x0000000000002e36:  19 CA                sbb   dx, cx
0x0000000000002e38:  3D 0A 00             cmp   ax, 10  ; 10 * fracbits
0x0000000000002e3b:  7F 0B                jg    label_38
0x0000000000002e3d:  74 03                je    label_39
jump_to_label_40:
0x0000000000002e3f:  E9 E4 00             jmp   label_40
label_39:
0x0000000000002e42:  83 7E F6 00          cmp   word ptr [bp - 0Ah], 0
0x0000000000002e46:  76 F7                jbe   jump_to_label_40
label_38:
0x0000000000002e48:  C6 46 EB 00          mov   byte ptr [bp - 015h], 0
label_75:
0x0000000000002e4c:  83 FA F6             cmp   dx, -10  ; -10 * fracbits
0x0000000000002e4f:  7D 03                jge   label_41
0x0000000000002e51:  E9 E5 00             jmp   label_42
label_41:
0x0000000000002e54:  83 FA 0A             cmp   dx, 10
0x0000000000002e57:  7F 0B                jg    label_43
0x0000000000002e59:  74 03                je    label_44
jump_to_label_45:
0x0000000000002e5b:  E9 E2 00             jmp   label_45
label_44:
0x0000000000002e5e:  83 7E F4 00          cmp   word ptr [bp - 0Ch], 0
0x0000000000002e62:  76 F7                jbe   jump_to_label_45
label_43:
0x0000000000002e64:  C6 46 EC 02          mov   byte ptr [bp - 014h], 2
label_48:
0x0000000000002e68:  80 7E EB 08          cmp   byte ptr [bp - 015h], 8
0x0000000000002e6c:  74 3F                je    label_46
0x0000000000002e6e:  80 7E EC 08          cmp   byte ptr [bp - 014h], 8
0x0000000000002e72:  74 39                je    label_46
0x0000000000002e74:  85 D2                test  dx, dx
0x0000000000002e76:  7D 03                jge   label_49
0x0000000000002e78:  E9 CE 00             jmp   label_50
label_49:
0x0000000000002e7b:  31 DB                xor   bx, bx
label_51:
0x0000000000002e7d:  89 D8                mov   ax, bx
0x0000000000002e7f:  01 D8                add   ax, bx
0x0000000000002e81:  83 7E F8 00          cmp   word ptr [bp - 8], 0
0x0000000000002e85:  7F 0B                jg    label_52
0x0000000000002e87:  74 03                je    label_53
jump_to_label_54:
0x0000000000002e89:  E9 C5 00             jmp   label_54
label_53:
0x0000000000002e8c:  83 7E F6 00          cmp   word ptr [bp - 0Ah], 0
0x0000000000002e90:  76 F7                jbe   jump_to_label_54
label_52:
0x0000000000002e92:  BB 01 00             mov   bx, 1
label_55:
0x0000000000002e95:  01 C3                add   bx, ax
0x0000000000002e97:  8A 87 9F 0E          mov   al, byte ptr ds:[bx + _diags]
0x0000000000002e9b:  88 C3                mov   bl, al
0x0000000000002e9d:  88 44 1F             mov   byte ptr ds:[si + MOBJ_T.m_movedir], al
0x0000000000002ea0:  8A 46 FC             mov   al, byte ptr [bp - 4]
0x0000000000002ea3:  30 FF                xor   bh, bh
0x0000000000002ea5:  98                   cbw  
0x0000000000002ea6:  39 C3                cmp   bx, ax
0x0000000000002ea8:  74 03                je    label_46
0x0000000000002eaa:  E9 A9 00             jmp   label_47
label_46:
0x0000000000002ead:  E8 00 5B             call  P_Random_
0x0000000000002eb0:  3C C8                cmp   al, 200
0x0000000000002eb2:  77 03                ja    OFFSET _commercial7
0x0000000000002eb4:  E9 B8 00             jmp   label_56
label_63:
0x0000000000002eb7:  8A 46 EB             mov   al, byte ptr [bp - 015h]
0x0000000000002eba:  8A 66 EC             mov   ah, byte ptr [bp - 014h]
0x0000000000002ebd:  88 66 EB             mov   byte ptr [bp - 015h], ah
0x0000000000002ec0:  88 46 EC             mov   byte ptr [bp - 014h], al
label_65:
0x0000000000002ec3:  8A 46 EB             mov   al, byte ptr [bp - 015h]
0x0000000000002ec6:  3A 46 FC             cmp   al, byte ptr [bp - 4]
0x0000000000002ec9:  75 04                jne   label_72
0x0000000000002ecb:  C6 46 EB 08          mov   byte ptr [bp - 015h], 8
label_72:
0x0000000000002ecf:  8A 46 EC             mov   al, byte ptr [bp - 014h]
0x0000000000002ed2:  3A 46 FC             cmp   al, byte ptr [bp - 4]
0x0000000000002ed5:  75 04                jne   label_71
0x0000000000002ed7:  C6 46 EC 08          mov   byte ptr [bp - 014h], 8
label_71:
0x0000000000002edb:  8A 46 EB             mov   al, byte ptr [bp - 015h]
0x0000000000002ede:  3C 08                cmp   al, 8
0x0000000000002ee0:  75 65                jne   jump_to_label_70
label_78:
0x0000000000002ee2:  8A 46 EC             mov   al, byte ptr [bp - 014h]
0x0000000000002ee5:  3C 08                cmp   al, 8
0x0000000000002ee7:  75 66                jne   jump_to_label_73
label_76:
0x0000000000002ee9:  8A 46 FE             mov   al, byte ptr [bp - 2]
0x0000000000002eec:  3C 08                cmp   al, 8
0x0000000000002eee:  74 11                je    label_72
0x0000000000002ef0:  8B 4E FA             mov   cx, word ptr [bp - 6]
0x0000000000002ef3:  89 FB                mov   bx, di
0x0000000000002ef5:  88 44 1F             mov   byte ptr ds:[si + MOBJ_T.m_movedir], al
0x0000000000002ef8:  89 F0                mov   ax, si
0x0000000000002efa:  E8 A5 FE             call  P_TryWalk_
0x0000000000002efd:  84 C0                test  al, al
0x0000000000002eff:  75 20                jne   exit_p_newchasedir
label_72:
0x0000000000002f01:  E8 AC 5A             call  P_Random_
0x0000000000002f04:  A8 01                test  al, 1
0x0000000000002f06:  74 5F                je    jump_to_label_57
0x0000000000002f08:  30 D2                xor   dl, dl
label_67:
0x0000000000002f0a:  3A 56 FC             cmp   dl, byte ptr [bp - 4]
0x0000000000002f0d:  75 5B                jne   jump_to_label_58
label_77:
0x0000000000002f0f:  FE C2                inc   dl
0x0000000000002f11:  80 FA 07             cmp   dl, 7
0x0000000000002f14:  7E F4                jle   label_67
label_71:
0x0000000000002f16:  8A 46 FC             mov   al, byte ptr [bp - 4]
0x0000000000002f19:  3C 08                cmp   al, 8
0x0000000000002f1b:  75 4F                jne   jump_to_label_59
0x0000000000002f1d:  C6 44 1F 08          mov   byte ptr ds:[si + MOBJ_T.m_movedir], DI_NODIR
exit_p_newchasedir:
0x0000000000002f21:  C9                   LEAVE_MACRO 
0x0000000000002f22:  5F                   pop   di
0x0000000000002f23:  5E                   pop   si
0x0000000000002f24:  5A                   pop   dx
0x0000000000002f25:  C3                   ret   
label_40:
0x0000000000002f26:  3D F6 FF             cmp   ax, -10  (neg 10 * fracunit)
0x0000000000002f29:  7C 07                jl    label_74
0x0000000000002f2b:  C6 46 EB 08          mov   byte ptr [bp - 015h], 8
0x0000000000002f2f:  E9 1A FF             jmp   label_75
label_74:
0x0000000000002f32:  C6 46 EB 04          mov   byte ptr [bp - 015h], 4
0x0000000000002f36:  E9 13 FF             jmp   label_75
label_42:
0x0000000000002f39:  C6 46 EC 06          mov   byte ptr [bp - 014h], 6
0x0000000000002f3d:  E9 28 FF             jmp   label_48
label_45:
0x0000000000002f40:  C6 46 EC 08          mov   byte ptr [bp - 014h], 8
0x0000000000002f44:  E9 21 FF             jmp   label_48
jump_to_label_70:
0x0000000000002f47:  EB 5C                jmp   label_70
label_50:
0x0000000000002f49:  BB 01 00             mov   bx, 1
0x0000000000002f4c:  E9 2E FF             jmp   label_51
jump_to_label_73:
0x0000000000002f4f:  EB 6B                jmp   label_73
label_54:
0x0000000000002f51:  31 DB                xor   bx, bx
0x0000000000002f53:  E9 3F FF             jmp   label_55
label_47:
0x0000000000002f56:  8B 4E FA             mov   cx, word ptr [bp - 6]
0x0000000000002f59:  89 FB                mov   bx, di
0x0000000000002f5b:  89 F0                mov   ax, si
0x0000000000002f5d:  E8 42 FE             call  P_TryWalk_
0x0000000000002f60:  84 C0                test  al, al
0x0000000000002f62:  75 BD                jne   exit_p_newchasedir
0x0000000000002f64:  E9 46 FF             jmp   label_46
jump_to_label_57:
0x0000000000002f67:  E9 7A 00             jmp   label_57
jump_to_label_58:
0x0000000000002f6a:  EB 64                jmp   label_58
jump_to_label_59:
0x0000000000002f6c:  E9 9A 00             jmp   label_59
label_56:
0x0000000000002f6f:  8B 46 F4             mov   ax, word ptr [bp - 0Ch]
0x0000000000002f72:  0B D2                or    dx, dx
0x0000000000002f74:  7D 07                jge   label_60
0x0000000000002f76:  F7 D8                neg   ax
0x0000000000002f78:  83 D2 00             adc   dx, 0
0x0000000000002f7b:  F7 DA                neg   dx
label_60:
0x0000000000002f7d:  89 C1                mov   cx, ax
0x0000000000002f7f:  89 D3                mov   bx, dx
0x0000000000002f81:  8B 46 F6             mov   ax, word ptr [bp - 0Ah]
0x0000000000002f84:  8B 56 F8             mov   dx, word ptr [bp - 8]
0x0000000000002f87:  0B D2                or    dx, dx
0x0000000000002f89:  7D 07                jge   label_61
0x0000000000002f8b:  F7 D8                neg   ax
0x0000000000002f8d:  83 D2 00             adc   dx, 0
0x0000000000002f90:  F7 DA                neg   dx
label_61:
0x0000000000002f92:  39 D3                cmp   bx, dx
0x0000000000002f94:  7E 03                jle   label_62
jump_to_label_63:
0x0000000000002f96:  E9 1E FF             jmp   label_63
label_62:
0x0000000000002f99:  74 03                je    label_64
0x0000000000002f9b:  E9 25 FF             jmp   label_65
label_64:
0x0000000000002f9e:  39 C1                cmp   cx, ax
0x0000000000002fa0:  77 F4                ja    jump_to_label_63
0x0000000000002fa2:  E9 1E FF             jmp   label_65
label_70:
0x0000000000002fa5:  8B 4E FA             mov   cx, word ptr [bp - 6]
0x0000000000002fa8:  89 FB                mov   bx, di
0x0000000000002faa:  88 44 1F             mov   byte ptr ds:[si + MOBJ_T.m_movedir], al
0x0000000000002fad:  89 F0                mov   ax, si
0x0000000000002faf:  E8 F0 FD             call  P_TryWalk_
0x0000000000002fb2:  84 C0                test  al, al
0x0000000000002fb4:  74 03                je    label_66
jump_to_exit_p_newchasedir:
0x0000000000002fb6:  E9 68 FF             jmp   exit_p_newchasedir
label_66:
0x0000000000002fb9:  E9 26 FF             jmp   label_78
label_73:
0x0000000000002fbc:  8B 4E FA             mov   cx, word ptr [bp - 6]
0x0000000000002fbf:  89 FB                mov   bx, di
0x0000000000002fc1:  88 44 1F             mov   byte ptr ds:[si + MOBJ_T.m_movedir], al
0x0000000000002fc4:  89 F0                mov   ax, si
0x0000000000002fc6:  E8 D9 FD             call  P_TryWalk_
0x0000000000002fc9:  84 C0                test  al, al
0x0000000000002fcb:  75 E9                jne   jump_to_exit_p_newchasedir
0x0000000000002fcd:  E9 19 FF             jmp   label_76
label_58:
0x0000000000002fd0:  8B 4E FA             mov   cx, word ptr [bp - 6]
0x0000000000002fd3:  89 FB                mov   bx, di
0x0000000000002fd5:  89 F0                mov   ax, si
0x0000000000002fd7:  88 54 1F             mov   byte ptr ds:[si + MOBJ_T.m_movedir], dl
0x0000000000002fda:  E8 C5 FD             call  P_TryWalk_
0x0000000000002fdd:  84 C0                test  al, al
0x0000000000002fdf:  75 D5                jne   jump_to_exit_p_newchasedir
0x0000000000002fe1:  E9 2B FF             jmp   label_77
label_57:
0x0000000000002fe4:  B2 07                mov   dl, DI_EAST-1
label_68:
0x0000000000002fe6:  3A 56 FC             cmp   dl, byte ptr [bp - 4]
0x0000000000002fe9:  75 0A                jne   label_69
label_79:
0x0000000000002feb:  FE CA                dec   dl
0x0000000000002fed:  80 FA FF             cmp   dl, (DI_EAST-1)  ; 0FFh
0x0000000000002ff0:  75 F4                jne   label_68
0x0000000000002ff2:  E9 21 FF             jmp   label_71
label_69:
0x0000000000002ff5:  8B 4E FA             mov   cx, word ptr [bp - 6]
0x0000000000002ff8:  89 FB                mov   bx, di
0x0000000000002ffa:  89 F0                mov   ax, si
0x0000000000002ffc:  88 54 1F             mov   byte ptr ds:[si + MOBJ_T.m_movedir], dl
0x0000000000002fff:  E8 A0 FD             call  P_TryWalk_
0x0000000000003002:  84 C0                test  al, al
0x0000000000003004:  74 E5                je    label_79
0x0000000000003006:  E9 18 FF             jmp   exit_p_newchasedir
label_59:
0x0000000000003009:  8B 4E FA             mov   cx, word ptr [bp - 6]
0x000000000000300c:  89 FB                mov   bx, di
0x000000000000300e:  88 44 1F             mov   byte ptr ds:[si + MOBJ_T.m_movedir], al
0x0000000000003011:  89 F0                mov   ax, si
0x0000000000003013:  E8 8C FD             call  P_TryWalk_
0x0000000000003016:  84 C0                test  al, al
0x0000000000003018:  75 9C                jne   jump_to_exit_p_newchasedir
0x000000000000301a:  C6 44 1F 08          mov   byte ptr ds:[si + MOBJ_T.m_movedir], DI_NODIR
0x000000000000301e:  C9                   LEAVE_MACRO 
0x000000000000301f:  5F                   pop   di
0x0000000000003020:  5E                   pop   si
0x0000000000003021:  5A                   pop   dx
0x0000000000003022:  C3                   ret   
0x0000000000003023:  FC                   cld   

ENDP


PROC    P_LookForPlayers_ NEAR
PUBLIC  P_LookForPlayers_

0x0000000000003024:  53                   push  bx
0x0000000000003025:  51                   push  cx
0x0000000000003026:  56                   push  si
0x0000000000003027:  57                   push  di
0x0000000000003028:  55                   push  bp
0x0000000000003029:  89 E5                mov   bp, sp
0x000000000000302b:  83 EC 06             sub   sp, 6
0x000000000000302e:  89 C7                mov   di, ax
0x0000000000003030:  88 56 FE             mov   byte ptr [bp - 2], dl
0x0000000000003033:  BB E8 07             mov   bx, OFFSET _player + PLAYER_T.player_health
0x0000000000003036:  83 3F 00             cmp   word ptr ds:[bx], 0
0x0000000000003039:  7F 08                jg    do_look_for_players
exit_look_for_players_return_0:
0x000000000000303b:  30 C0                xor   al, al
exit_look_for_players:
0x000000000000303d:  C9                   LEAVE_MACRO 
0x000000000000303e:  5F                   pop   di
0x000000000000303f:  5E                   pop   si
0x0000000000003040:  59                   pop   cx
0x0000000000003041:  5B                   pop   bx
0x0000000000003042:  C3                   ret   
do_look_for_players
0x0000000000003043:  BB 2C 00             mov   bx, SIZEOF_THINKER_T
0x0000000000003046:  2D 04 34             sub   ax, (OFFSET _thinkerlist + THINKER_T.t_data)
0x0000000000003049:  31 D2                xor   dx, dx
0x000000000000304b:  F7 F3                div   bx
0x000000000000304d:  6B F0 18             imul  si, ax, SIZEOF_MOBJ_POS_T
0x0000000000003050:  BB 30 07             mov   bx, OFFSET _playerMobj_pos
0x0000000000003053:  8B 0F                mov   cx, word ptr ds:[bx]
0x0000000000003055:  BB EC 06             mov   bx, OFFSET _playerMobj
0x0000000000003058:  C7 46 FC F5 6A       mov   word ptr [bp - 4], MOBJPOSLIST_6800_SEGMENT
0x000000000000305d:  8B 17                mov   dx, word ptr ds:[bx]
0x000000000000305f:  89 F3                mov   bx, si
0x0000000000003061:  89 F8                mov   ax, di
0x0000000000003063:  FF 1E CC 0C          call  dword ptr ds:[_P_CheckSightTemp]
0x0000000000003067:  84 C0                test  al, al
0x0000000000003069:  74 D2                je    exit_look_for_players
0x000000000000306b:  80 7E FE 00          cmp   byte ptr [bp - 2], 0
0x000000000000306f:  74 10                je    label_80
look_set_target_player:
0x0000000000003071:  BB F6 06             mov   bx, OFFSET _playerMobjRef
0x0000000000003074:  8B 07                mov   ax, word ptr ds:[bx]
0x0000000000003076:  89 45 22             mov   word ptr ds:[di + MOBJ_T.m_targetRef], ax
0x0000000000003079:  B0 01                mov   al, 1
0x000000000000307b:  C9                   LEAVE_MACRO 
0x000000000000307c:  5F                   pop   di
0x000000000000307d:  5E                   pop   si
0x000000000000307e:  59                   pop   cx
0x000000000000307f:  5B                   pop   bx
0x0000000000003080:  C3                   ret   
label_80:
0x0000000000003081:  BB 30 07             mov   bx, OFFSET _playerMobj_pos
0x0000000000003084:  C4 07                les   ax, ptr ds:[bx]
0x0000000000003086:  89 C3                mov   bx, ax
0x0000000000003088:  26 FF 77 06          push  word ptr es:[bx + MOBJ_POS_T.mp_y + 2]
0x000000000000308c:  26 FF 77 04          push  word ptr es:[bx + MOBJ_POS_T.mp_y + 0]
0x0000000000003090:  BB 30 07             mov   bx, OFFSET _playerMobj_pos
0x0000000000003093:  C4 07                les   ax, ptr ds:[bx]
0x0000000000003095:  89 C3                mov   bx, ax
0x0000000000003097:  26 FF 77 02          push  word ptr es:[bx + 2]
0x000000000000309b:  26 FF 37             push  word ptr es:[bx]
0x000000000000309e:  8E 46 FC             mov   es, word ptr [bp - 4]
0x00000000000030a1:  26 8B 5C 04          mov   bx, word ptr es:[si + MOBJ_POS_T.mp_y + 0]
0x00000000000030a5:  26 8B 4C 06          mov   cx, word ptr es:[si + MOBJ_POS_T.mp_y + 2]
0x00000000000030a9:  26 8B 04             mov   ax, word ptr es:[si]
0x00000000000030ac:  26 8B 54 02          mov   dx, word ptr es:[si + 2]
0x00000000000030b0:  0E                   push  cs
0x00000000000030b1:  E8 85 70             call  R_PointToAngle2_
0x00000000000030b4:  90                   nop   
0x00000000000030b5:  8E 46 FC             mov   es, word ptr [bp - 4]
0x00000000000030b8:  89 C1                mov   cx, ax
0x00000000000030ba:  89 F3                mov   bx, si
0x00000000000030bc:  89 D0                mov   ax, dx
0x00000000000030be:  26 2B 4C 0E          sub   cx, word ptr es:[si + MOBJ_POS_T.mp_angle+0]
0x00000000000030c2:  26 1B 47 10          sbb   ax, word ptr es:[bx + MOBJ_POS_T.mp_angle+2]
0x00000000000030c6:  3D 00 40             cmp   ax, ANG90_HIGHBITS
0x00000000000030c9:  77 06                ja    lookforplayers_above_ang90
0x00000000000030cb:  75 A4                jne   look_set_target_player
0x00000000000030cd:  85 C9                test  cx, cx
0x00000000000030cf:  76 A0                jbe   look_set_target_player
lookforplayers_above_ang90:
0x00000000000030d1:  3D 00 C0             cmp   ax, ANG270_HIGHBITS
0x00000000000030d4:  73 9B                jae   look_set_target_player
0x00000000000030d6:  BB 30 07             mov   bx, OFFSET _playerMobj_pos
0x00000000000030d9:  C4 17                les   dx, ptr ds:[bx]
0x00000000000030db:  89 D3                mov   bx, dx
0x00000000000030dd:  26 8B 47 04          mov   ax, word ptr es:[bx + MOBJ_POS_T.mp_y + 0]
0x00000000000030e1:  26 8B 4F 06          mov   cx, word ptr es:[bx + MOBJ_POS_T.mp_y + 2]
0x00000000000030e5:  8E 46 FC             mov   es, word ptr [bp - 4]
0x00000000000030e8:  89 46 FA             mov   word ptr [bp - 6], ax
0x00000000000030eb:  26 8B 44 04          mov   ax, word ptr es:[si + MOBJ_POS_T.mp_y + 0]
0x00000000000030ef:  89 F3                mov   bx, si
0x00000000000030f1:  29 46 FA             sub   word ptr [bp - 6], ax
0x00000000000030f4:  26 1B 4F 06          sbb   cx, word ptr es:[bx + MOBJ_POS_T.mp_y + 2]
0x00000000000030f8:  BB 30 07             mov   bx, OFFSET _playerMobj_pos
0x00000000000030fb:  C4 17                les   dx, ptr ds:[bx]
0x00000000000030fd:  89 D3                mov   bx, dx
0x00000000000030ff:  26 8B 07             mov   ax, word ptr es:[bx]
0x0000000000003102:  26 8B 57 02          mov   dx, word ptr es:[bx + 2]
0x0000000000003106:  8E 46 FC             mov   es, word ptr [bp - 4]
0x0000000000003109:  89 F3                mov   bx, si
0x000000000000310b:  26 2B 04             sub   ax, word ptr es:[si]
0x000000000000310e:  26 1B 57 02          sbb   dx, word ptr es:[bx + 2]
0x0000000000003112:  8B 5E FA             mov   bx, word ptr [bp - 6]
0x0000000000003115:  FF 1E D0 0C          call  dword ptr ds:[_P_AproxDistance]
0x0000000000003119:  83 FA 40             cmp   dx, MELEERANGE
0x000000000000311c:  7E 03                jle   label_81
0x000000000000311e:  E9 1A FF             jmp   exit_look_for_players_return_0
label_81:
0x0000000000003121:  74 03                je    label_82
jump_to_look_set_target_player:
0x0000000000003123:  E9 4B FF             jmp   look_set_target_player
label_82:
0x0000000000003126:  85 C0                test  ax, ax
0x0000000000003128:  76 F9                jbe   jump_to_look_set_target_player
0x000000000000312a:  30 C0                xor   al, al
0x000000000000312c:  C9                   LEAVE_MACRO 
0x000000000000312d:  5F                   pop   di
0x000000000000312e:  5E                   pop   si
0x000000000000312f:  59                   pop   cx
0x0000000000003130:  5B                   pop   bx
0x0000000000003131:  C3                   ret   

ENDP


PROC    A_KeenDie_ NEAR
PUBLIC  A_KeenDie_

0x0000000000003132:  52                   push  dx
0x0000000000003133:  56                   push  si
0x0000000000003134:  55                   push  bp
0x0000000000003135:  89 E5                mov   bp, sp
0x0000000000003137:  83 EC 02             sub   sp, 2
0x000000000000313a:  89 C6                mov   si, ax
0x000000000000313c:  8E C1                mov   es, cx
0x000000000000313e:  B9 2C 00             mov   cx, SIZEOF_THINKER_T
0x0000000000003141:  8A 44 1A             mov   al, byte ptr ds:[si + MOBJ_T.m_mobjtype]
0x0000000000003144:  31 D2                xor   dx, dx
0x0000000000003146:  88 46 FE             mov   byte ptr [bp - 2], al
0x0000000000003149:  8D 84 FC CB          lea   ax, ds:[si - (OFFSET _thinkerlist + THINKER_T.t_data)]
0x000000000000314d:  F7 F1                div   cx
0x000000000000314f:  26 80 67 14 FD       and   byte ptr es:[bx + MOBJ_POS_T.mp_flags1], (NOT MF_SOLID)
0x0000000000003154:  BB 02 34             mov   bx, OFFSET _thinkerlist + THINKER_T.t_next
0x0000000000003157:  89 C1                mov   cx, ax
0x0000000000003159:  8B 07                mov   ax, word ptr ds:[bx]
0x000000000000315b:  85 C0                test  ax, ax
0x000000000000315d:  74 1D                je    label_33
label_34:
0x000000000000315f:  6B D8 2C             imul  bx, ax, SIZEOF_THINKER_T
0x0000000000003162:  8B 97 00 34          mov   dx, word ptr ds:[bx + _thinkerlist]
0x0000000000003166:  30 D2                xor   dl, dl
0x0000000000003168:  80 E6 F8             and   dh, (TF_FUNCBITS SHR 8)
0x000000000000316b:  81 FA 00 08          cmp   dx, TF_MOBJTHINKER_HIGHBITS
0x000000000000316f:  74 1A                je    label_35
label_36:
0x0000000000003171:  6B D8 2C             imul  bx, ax, SIZEOF_THINKER_T
0x0000000000003174:  8B 87 02 34          mov   ax, word ptr ds:[bx + OFFSET _thinkerlist + THINKER_T.t_next]
0x0000000000003178:  85 C0                test  ax, ax
0x000000000000317a:  75 E3                jne   label_34
label_33:
0x000000000000317c:  BA 03 00             mov   dx, DOOR_OPEN
0x000000000000317f:  B8 3D 00             mov   ax, TAG_666
0x0000000000003182:  0E                   push  cs
0x0000000000003183:  E8 FE F2             call  EV_DoDoor_
0x0000000000003186:  90                   nop   
exit_keen_die:
0x0000000000003187:  C9                   LEAVE_MACRO 
0x0000000000003188:  5E                   pop   si
0x0000000000003189:  5A                   pop   dx
0x000000000000318a:  C3                   ret   
label_35:
0x000000000000318b:  81 C3 04 34          add   bx, (OFFSET _thinkerlist + THINKER_T.t_data)
0x000000000000318f:  39 C8                cmp   ax, cx
0x0000000000003191:  74 DE                je    label_36
0x0000000000003193:  8A 57 1A             mov   dl, byte ptr ds:[bx + MOBJ_T.m_mobjtype]
0x0000000000003196:  3A 56 FE             cmp   dl, byte ptr [bp - 2]
0x0000000000003199:  75 D6                jne   label_36
0x000000000000319b:  83 7F 1C 00          cmp   word ptr ds:[bx + MOBJ_T.m_health], 0
0x000000000000319f:  7F E6                jg    exit_keen_die
0x00000000000031a1:  EB CE                jmp   label_36
0x00000000000031a3:  FC                   cld   

ENDP


PROC    A_Look_ NEAR
PUBLIC  A_Look_

0x00000000000031a4:  52                   push  dx
0x00000000000031a5:  56                   push  si
0x00000000000031a6:  57                   push  di
0x00000000000031a7:  55                   push  bp
0x00000000000031a8:  89 E5                mov   bp, sp
0x00000000000031aa:  83 EC 08             sub   sp, 8
0x00000000000031ad:  89 C6                mov   si, ax
0x00000000000031af:  C7 46 F8 50 03       mov   word ptr [bp - 8], GETSEESTATEADDR
0x00000000000031b4:  B8 56 4C             mov   ax, SECTOR_SOUNDTRAVERSED_SEGMENT
0x00000000000031b7:  8B 7C 04             mov   di, word ptr ds:[si + 4]
0x00000000000031ba:  C6 44 25 00          mov   byte ptr ds:[si + MOBJ_T.m_threshold], 0
0x00000000000031be:  8E C0                mov   es, ax
0x00000000000031c0:  C7 46 FA D9 92       mov   word ptr [bp - 6], INFOFUNCLOADSEGMENT
0x00000000000031c5:  26 80 3D 00          cmp   byte ptr es:[di], 0
0x00000000000031c9:  75 03                jne   label_83
jump_to_label_84:
0x00000000000031cb:  E9 93 00             jmp   label_84
label_83:
0x00000000000031ce:  BF F6 06             mov   di, OFFSET _playerMobjRef
0x00000000000031d1:  8B 05                mov   ax, word ptr ds:[di]
0x00000000000031d3:  85 C0                test  ax, ax
0x00000000000031d5:  74 F4                je    jump_to_label_84
0x00000000000031d7:  6B F8 18             imul  di, ax, SIZEOF_MOBJ_POS_T
0x00000000000031da:  BA F5 6A             mov   dx, MOBJPOSLIST_6800_SEGMENT
0x00000000000031dd:  8E C2                mov   es, dx
0x00000000000031df:  6B D0 2C             imul  dx, ax, SIZEOF_THINKER_T
0x00000000000031e2:  81 C2 04 34          add   dx, (OFFSET _thinkerlist + THINKER_T.t_data)
0x00000000000031e6:  26 F6 45 14 04       test  byte ptr es:[di + MOBJ_POS_T.mp_flags1], MF_SHOOTABLE
0x00000000000031eb:  74 DE                je    jump_to_label_84
0x00000000000031ed:  89 44 22             mov   word ptr ds:[si + MOBJ_T.m_targetRef], ax
0x00000000000031f0:  8E C1                mov   es, cx
0x00000000000031f2:  26 F6 47 14 20       test  byte ptr es:[bx + MOBJ_POS_T.mp_flags1], MF_AMBUSH
0x00000000000031f7:  74 0C                je    label_85
0x00000000000031f9:  89 F9                mov   cx, di
0x00000000000031fb:  89 F0                mov   ax, si
0x00000000000031fd:  FF 1E CC 0C          call  dword ptr ds:[_P_CheckSightTemp]
0x0000000000003201:  84 C0                test  al, al
0x0000000000003203:  74 5C                je    label_84
label_85:
0x0000000000003205:  8A 44 1A             mov   al, byte ptr ds:[si + MOBJ_T.m_mobjtype]
0x0000000000003208:  30 E4                xor   ah, ah
0x000000000000320a:  6B C0 0B             imul  ax, ax, SIZEOF_MOBJINFO_T
0x000000000000320d:  C7 46 FE 00 00       mov   word ptr [bp - 2], 0
0x0000000000003212:  89 C3                mov   bx, ax
0x0000000000003214:  89 46 FC             mov   word ptr [bp - 4], ax
0x0000000000003217:  8A 87 62 C4          mov   al, byte ptr ds:[bx + OFFSET _mobjinfo + MOBJINFO_T.mobjinfo_seesound]
0x000000000000321b:  81 C3 62 C4          add   bx, OFFSET _mobjinfo + MOBJINFO_T.mobjinfo_seesound
0x000000000000321f:  84 C0                test  al, al
0x0000000000003221:  74 28                je    label_86
0x0000000000003223:  3C 24                cmp   al, SFX_POSIT1
0x0000000000003225:  73 47                jae   label_87
label_89:
0x0000000000003227:  8A 44 1A             mov   al, byte ptr ds:[si + MOBJ_T.m_mobjtype]
0x000000000000322a:  30 E4                xor   ah, ah
0x000000000000322c:  6B C0 0B             imul  ax, ax, SIZEOF_MOBJINFO_T
0x000000000000322f:  89 C3                mov   bx, ax
0x0000000000003231:  81 C3 62 C4          add   bx, OFFSET _mobjinfo + MOBJINFO_T.mobjinfo_seesound
0x0000000000003235:  8A 1F                mov   bl, byte ptr ds:[bx]
0x0000000000003237:  30 FF                xor   bh, bh
label_93:
0x0000000000003239:  8A 44 1A             mov   al, byte ptr ds:[si + MOBJ_T.m_mobjtype]
0x000000000000323c:  3C 13                cmp   al, MT_SPIDER
0x000000000000323e:  75 66                jne   label_90
label_91:
0x0000000000003240:  88 DA                mov   dl, bl
0x0000000000003242:  31 C0                xor   ax, ax
label_92:
0x0000000000003244:  30 F6                xor   dh, dh
0x0000000000003246:  0E                   push  cs
0x0000000000003247:  E8 06 D3             call  S_StartSound_
0x000000000000324a:  90                   nop   
label_86:
0x000000000000324b:  8A 44 1A             mov   al, byte ptr ds:[si + MOBJ_T.m_mobjtype]
0x000000000000324e:  30 E4                xor   ah, ah
0x0000000000003250:  FF 5E F8             call  dword ptr [bp - 8]
0x0000000000003253:  89 C2                mov   dx, ax
0x0000000000003255:  89 F0                mov   ax, si
0x0000000000003257:  0E                   push  cs
0x0000000000003258:  3E E8 92 5D          call  P_SetMobjState_
exit_a_look:
0x000000000000325c:  C9                   LEAVE_MACRO 
0x000000000000325d:  5F                   pop   di
0x000000000000325e:  5E                   pop   si
0x000000000000325f:  5A                   pop   dx
0x0000000000003260:  C3                   ret   
label_84:
0x0000000000003261:  89 F0                mov   ax, si
0x0000000000003263:  31 D2                xor   dx, dx
0x0000000000003265:  E8 BC FD             call  P_LookForPlayers_
0x0000000000003268:  84 C0                test  al, al
0x000000000000326a:  74 F0                je    exit_a_look
0x000000000000326c:  EB 97                jmp   label_85
label_87:
0x000000000000326e:  3C 26                cmp   al, SFX_POSIT3
0x0000000000003270:  76 22                jbe   label_88
0x0000000000003272:  3C 28                cmp   al, sfx_bgsit2
0x0000000000003274:  77 B1                ja    label_89
0x0000000000003276:  E8 37 57             call  P_Random_
0x0000000000003279:  88 C2                mov   dl, al
0x000000000000327b:  30 F6                xor   dh, dh
0x000000000000327d:  89 D0                mov   ax, dx
0x000000000000327f:  89 D3                mov   bx, dx
0x0000000000003281:  C1 F8 0F             sar   ax, 0Fh ; todo no
0x0000000000003284:  31 C3                xor   bx, ax
0x0000000000003286:  29 C3                sub   bx, ax
0x0000000000003288:  83 E3 01             and   bx, 1
0x000000000000328b:  31 C3                xor   bx, ax
0x000000000000328d:  29 C3                sub   bx, ax
0x000000000000328f:  83 C3 27             add   bx, SFX_BGSIT1
0x0000000000003292:  EB A5                jmp   label_93
label_88:
0x0000000000003294:  E8 19 57             call  P_Random_
0x0000000000003297:  30 E4                xor   ah, ah
0x0000000000003299:  BB 03 00             mov   bx, 3
0x000000000000329c:  99                   cwd   
0x000000000000329d:  F7 FB                idiv  bx
0x000000000000329f:  89 D3                mov   bx, dx
0x00000000000032a1:  83 C3 24             add   bx, SFX_POSIT1
0x00000000000032a4:  EB 93                jmp   label_93
label_90:
0x00000000000032a6:  3C 15                cmp   al, MT_CYBORG
0x00000000000032a8:  74 96                je    label_91
0x00000000000032aa:  88 DA                mov   dl, bl
0x00000000000032ac:  89 F0                mov   ax, si
0x00000000000032ae:  EB 94                jmp   label_92

ENDP


PROC    A_Chase_ NEAR
PUBLIC  A_Chase_

0x00000000000032b0:  52                   push  dx
0x00000000000032b1:  56                   push  si
0x00000000000032b2:  57                   push  di
0x00000000000032b3:  55                   push  bp
0x00000000000032b4:  89 E5                mov   bp, sp
0x00000000000032b6:  83 EC 14             sub   sp, 014h
0x00000000000032b9:  89 C6                mov   si, ax
0x00000000000032bb:  89 DF                mov   di, bx
0x00000000000032bd:  89 4E FE             mov   word ptr [bp - 2], cx
0x00000000000032c0:  8B 44 22             mov   ax, word ptr ds:[si + MOBJ_T.m_targetRef]
0x00000000000032c3:  6B D0 2C             imul  dx, ax, SIZEOF_THINKER_T
0x00000000000032c6:  6B C8 18             imul  cx, ax, SIZEOF_MOBJ_POS_T
0x00000000000032c9:  C7 46 FC F5 6A       mov   word ptr [bp - 4], MOBJPOSLIST_6800_SEGMENT
0x00000000000032ce:  C7 46 F0 F4 03       mov   word ptr [bp - 010h], GETMISSILESTATEADDR
0x00000000000032d3:  C7 46 F2 D9 92       mov   word ptr [bp - 0Eh], INFOFUNCLOADSEGMENT
0x00000000000032d8:  C7 46 F4 5A 01       mov   word ptr [bp - 0Ch], GETMELEESTATEADDR
0x00000000000032dd:  C7 46 F6 D9 92       mov   word ptr [bp - 0Ah], INFOFUNCLOADSEGMENT
0x00000000000032e2:  C7 46 EC 22 02       mov   word ptr [bp - 014h], GETACTIVESOUNDADDR
0x00000000000032e7:  C7 46 EE D9 92       mov   word ptr [bp - 012h], INFOFUNCLOADSEGMENT
0x00000000000032ec:  C7 46 F8 B8 02       mov   word ptr [bp - 8], GETATTACKSOUNDADDR
0x00000000000032f1:  C7 46 FA D9 92       mov   word ptr [bp - 6], INFOFUNCLOADSEGMENT
0x00000000000032f6:  81 C2 04 34          add   dx, (OFFSET _thinkerlist + THINKER_T.t_data)
0x00000000000032fa:  80 7C 24 00          cmp   byte ptr ds:[si + MOBJ_T.m_reactiontime], 0
0x00000000000032fe:  74 03                je    label_94
0x0000000000003300:  E9 77 00             jmp   label_96
label_94:
0x0000000000003303:  80 7C 25 00          cmp   byte ptr ds:[si + MOBJ_T.m_threshold], 0
0x0000000000003307:  74 0B                je    label_95
0x0000000000003309:  85 C0                test  ax, ax
0x000000000000330b:  74 03                je    label_99
0x000000000000330d:  E9 6F 00             jmp   label_100
label_99:
0x0000000000003310:  C6 44 25 00          mov   byte ptr ds:[si + MOBJ_T.m_threshold], 0
label_95:
0x0000000000003314:  80 7C 1F 08          cmp   byte ptr ds:[si + MOBJ_T.m_movedir], DI_NODIR
0x0000000000003318:  73 2E                jae   label_98
0x000000000000331a:  8E 46 FE             mov   es, word ptr [bp - 2]
0x000000000000331d:  26 C6 45 10 00       mov   byte ptr es:[di + MOBJ_POS_T.mp_angle + 2], 0
0x0000000000003322:  26 C7 45 0E 00 00    mov   word ptr es:[di + MOBJ_POS_T.mp_angle + 0], 0
0x0000000000003328:  26 80 65 11 E0       and   byte ptr es:[di + MOBJ_POS_T.mp_angle+3], 0E0h
0x000000000000332d:  8A 44 1F             mov   al, byte ptr ds:[si + MOBJ_T.m_movedir]
0x0000000000003330:  30 E4                xor   ah, ah
0x0000000000003332:  89 C3                mov   bx, ax
0x0000000000003334:  01 C3                add   bx, ax
0x0000000000003336:  26 8B 45 10          mov   ax, word ptr es:[di + MOBJ_POS_T.mp_angle+2]
0x000000000000333a:  2B 87 A0 04          sub   ax, word ptr ds:[bx + _movedirangles]
0x000000000000333e:  85 C0                test  ax, ax
0x0000000000003340:  7E 4A                jle   label_97
0x0000000000003342:  26 81 6D 10 00 20    sub   word ptr es:[di + MOBJ_POS_T.mp_angle+2], (ANG90_HIGHBITS / 2)
label_98:
0x0000000000003348:  85 D2                test  dx, dx
0x000000000000334a:  74 49                je    label_106
0x000000000000334c:  8E 46 FC             mov   es, word ptr [bp - 4]
0x000000000000334f:  89 CB                mov   bx, cx
0x0000000000003351:  26 F6 47 14 04       test  byte ptr es:[bx + MOBJ_POS_T.mp_flags1], MF_SHOOTABLE
0x0000000000003356:  74 3D                je    label_106
0x0000000000003358:  8E 46 FE             mov   es, word ptr [bp - 2]
0x000000000000335b:  26 F6 45 14 80       test  byte ptr es:[di + MOBJ_POS_T.mp_flags1], MF_JUSTATTACKED
0x0000000000003360:  74 65                je    label_107
0x0000000000003362:  26 80 65 14 7F       and   byte ptr es:[di + MOBJ_POS_T.mp_flags1], (NOT MF_JUSTATTACKED)
0x0000000000003367:  80 3E 14 22 04       cmp   byte ptr ds:[_gameskill], sk_nightmare
0x000000000000336c:  74 07                je    exit_a_chase
0x000000000000336e:  80 3E 2F 22 00       cmp   byte ptr ds:[_fastparm], 0
0x0000000000003373:  74 47                je    label_110
exit_a_chase:
0x0000000000003375:  C9                   LEAVE_MACRO 
0x0000000000003376:  5F                   pop   di
0x0000000000003377:  5E                   pop   si
0x0000000000003378:  5A                   pop   dx
0x0000000000003379:  C3                   ret   
label_96:
0x000000000000337a:  FE 4C 24             dec   byte ptr ds:[si + MOBJ_T.m_reactiontime]
0x000000000000337d:  EB 84                jmp   label_94
label_100:
0x000000000000337f:  89 D3                mov   bx, dx
0x0000000000003381:  83 7F 1C 00          cmp   word ptr ds:[bx + MOBJ_T.m_health], 0
0x0000000000003385:  7E 89                jle   label_99
0x0000000000003387:  FE 4C 25             dec   byte ptr ds:[si + MOBJ_T.m_threshold]
0x000000000000338a:  EB 88                jmp   label_95
label_97:
0x000000000000338c:  7D BA                jge   label_98
0x000000000000338e:  26 80 45 11 20       add   byte ptr es:[di + MOBJ_POS_T.mp_angle+3], (ANG90_HIGHBITS SHR 9)
0x0000000000003393:  EB B3                jmp   label_98
label_106:
0x0000000000003395:  BA 01 00             mov   dx, 1
0x0000000000003398:  89 F0                mov   ax, si
0x000000000000339a:  E8 87 FC             call  P_LookForPlayers_
0x000000000000339d:  84 C0                test  al, al
0x000000000000339f:  75 D4                jne   exit_a_chase
0x00000000000033a1:  8A 44 1A             mov   al, byte ptr ds:[si + MOBJ_T.m_mobjtype]
0x00000000000033a4:  30 E4                xor   ah, ah
0x00000000000033a6:  6B C0 0B             imul  ax, ax, SIZEOF_MOBJINFO_T
0x00000000000033a9:  89 C7                mov   di, ax
0x00000000000033ab:  89 F0                mov   ax, si
0x00000000000033ad:  8B 95 60 C4          mov   dx, word ptr ds:[di + _mobjinfo]
0x00000000000033b1:  81 C7 60 C4          add   di, OFFSET _mobjinfo
0x00000000000033b5:  0E                   push  cs
0x00000000000033b6:  3E E8 34 5C          call  P_SetMobjState_
0x00000000000033ba:  EB B9                jmp   exit_a_chase
label_110:
0x00000000000033bc:  89 FB                mov   bx, di
0x00000000000033be:  8C C1                mov   cx, es
0x00000000000033c0:  89 F0                mov   ax, si
0x00000000000033c2:  E8 FB F9             call  P_NewChaseDir_
0x00000000000033c5:  EB AE                jmp   exit_a_chase
label_107:
0x00000000000033c7:  8A 44 1A             mov   al, byte ptr ds:[si + MOBJ_T.m_mobjtype]
0x00000000000033ca:  30 E4                xor   ah, ah
0x00000000000033cc:  FF 5E F4             call  dword ptr [bp - 0Ch]
0x00000000000033cf:  85 C0                test  ax, ax
0x00000000000033d1:  74 09                je    label_108
0x00000000000033d3:  89 F0                mov   ax, si
0x00000000000033d5:  E8 06 F6             call  P_CheckMeleeRange_
0x00000000000033d8:  84 C0                test  al, al
0x00000000000033da:  75 69                jne   label_109
label_108:
0x00000000000033dc:  8A 44 1A             mov   al, byte ptr ds:[si + MOBJ_T.m_mobjtype]
0x00000000000033df:  30 E4                xor   ah, ah
0x00000000000033e1:  FF 5E F0             call  dword ptr [bp - 010h]
0x00000000000033e4:  85 C0                test  ax, ax
0x00000000000033e6:  74 14                je    label_104
0x00000000000033e8:  80 3E 14 22 04       cmp   byte ptr ds:[_gameskill], sk_nightmare
0x00000000000033ed:  73 54                jae   jump_to_label_103
0x00000000000033ef:  80 3E 2F 22 00       cmp   byte ptr ds:[_fastparm], 0
0x00000000000033f4:  75 4D                jne   jump_to_label_103
0x00000000000033f6:  83 7C 20 00          cmp   word ptr ds:[si + MOBJ_T.m_movecount], 0
0x00000000000033fa:  74 72                je    label_103
label_104:
0x00000000000033fc:  FF 4C 20             dec   word ptr ds:[si + MOBJ_T.m_movecount]
0x00000000000033ff:  83 7C 20 00          cmp   word ptr ds:[si + MOBJ_T.m_movecount], 0
0x0000000000003403:  7C 0E                jl    label_101
0x0000000000003405:  8B 4E FE             mov   cx, word ptr [bp - 2]
0x0000000000003408:  89 FB                mov   bx, di
0x000000000000340a:  89 F0                mov   ax, si
0x000000000000340c:  E8 E9 F7             call  P_Move_
0x000000000000340f:  84 C0                test  al, al
0x0000000000003411:  75 0A                jne   label_102
label_101:
0x0000000000003413:  8B 4E FE             mov   cx, word ptr [bp - 2]
0x0000000000003416:  89 FB                mov   bx, di
0x0000000000003418:  89 F0                mov   ax, si
0x000000000000341a:  E8 A3 F9             call  P_NewChaseDir_
label_102:
0x000000000000341d:  8A 44 1A             mov   al, byte ptr ds:[si + MOBJ_T.m_mobjtype]
0x0000000000003420:  30 E4                xor   ah, ah
0x0000000000003422:  FF 5E EC             call  dword ptr [bp - 014h]
0x0000000000003425:  88 C2                mov   dl, al
0x0000000000003427:  84 C0                test  al, al
0x0000000000003429:  75 03                jne   label_105
jump_to_exit_a_chase:
0x000000000000342b:  E9 47 FF             jmp   exit_a_chase
label_105:
0x000000000000342e:  E8 7F 55             call  P_Random_
0x0000000000003431:  3C 03                cmp   al, 3
0x0000000000003433:  73 F6                jae   jump_to_exit_a_chase
0x0000000000003435:  89 F0                mov   ax, si
0x0000000000003437:  30 F6                xor   dh, dh
0x0000000000003439:  0E                   push  cs
0x000000000000343a:  3E E8 12 D1          call  S_StartSound_
0x000000000000343e:  C9                   LEAVE_MACRO 
0x000000000000343f:  5F                   pop   di
0x0000000000003440:  5E                   pop   si
0x0000000000003441:  5A                   pop   dx
0x0000000000003442:  C3                   ret   
jump_to_label_103:
0x0000000000003443:  EB 29                jmp   label_103
label_109:
0x0000000000003445:  8A 44 1A             mov   al, byte ptr ds:[si + MOBJ_T.m_mobjtype]
0x0000000000003448:  30 E4                xor   ah, ah
0x000000000000344a:  FF 5E F8             call  dword ptr [bp - 8]
0x000000000000344d:  88 C2                mov   dl, al
0x000000000000344f:  89 F0                mov   ax, si
0x0000000000003451:  30 F6                xor   dh, dh
0x0000000000003453:  0E                   push  cs
0x0000000000003454:  3E E8 F8 D0          call  S_StartSound_
0x0000000000003458:  8A 44 1A             mov   al, byte ptr ds:[si + MOBJ_T.m_mobjtype]
0x000000000000345b:  30 E4                xor   ah, ah
0x000000000000345d:  FF 5E F4             call  dword ptr [bp - 0Ch]
0x0000000000003460:  89 C2                mov   dx, ax
0x0000000000003462:  89 F0                mov   ax, si
0x0000000000003464:  0E                   push  cs
0x0000000000003465:  E8 86 5B             call  P_SetMobjState_
0x0000000000003468:  90                   nop   
0x0000000000003469:  C9                   LEAVE_MACRO 
0x000000000000346a:  5F                   pop   di
0x000000000000346b:  5E                   pop   si
0x000000000000346c:  5A                   pop   dx
0x000000000000346d:  C3                   ret   
label_103:
0x000000000000346e:  89 F0                mov   ax, si
0x0000000000003470:  E8 3B F6             call  P_CheckMissileRange_
0x0000000000003473:  84 C0                test  al, al
0x0000000000003475:  74 85                je    label_104
0x0000000000003477:  8A 44 1A             mov   al, byte ptr ds:[si + MOBJ_T.m_mobjtype]
0x000000000000347a:  30 E4                xor   ah, ah
0x000000000000347c:  FF 5E F0             call  dword ptr [bp - 010h]
0x000000000000347f:  89 C2                mov   dx, ax
0x0000000000003481:  89 F0                mov   ax, si
0x0000000000003483:  0E                   push  cs
0x0000000000003484:  3E E8 66 5B          call  P_SetMobjState_
0x0000000000003488:  8E 46 FE             mov   es, word ptr [bp - 2]
0x000000000000348b:  26 80 4D 14 80       or    byte ptr es:[di + MOBJ_POS_T.mp_flags1], MF_JUSTATTACKED
0x0000000000003490:  C9                   LEAVE_MACRO 
0x0000000000003491:  5F                   pop   di
0x0000000000003492:  5E                   pop   si
0x0000000000003493:  5A                   pop   dx
0x0000000000003494:  C3                   ret   
0x0000000000003495:  FC                   cld   

ENDP


PROC    A_FaceTarget_ NEAR
PUBLIC  A_FaceTarget_

0x0000000000003496:  53                   push  bx
0x0000000000003497:  51                   push  cx
0x0000000000003498:  52                   push  dx
0x0000000000003499:  56                   push  si
0x000000000000349a:  57                   push  di
0x000000000000349b:  55                   push  bp
0x000000000000349c:  89 E5                mov   bp, sp
0x000000000000349e:  83 EC 04             sub   sp, 4
0x00000000000034a1:  89 C3                mov   bx, ax
0x00000000000034a3:  83 7F 22 00          cmp   word ptr ds:[bx + MOBJ_T.m_targetRef], 0
0x00000000000034a7:  74 65                je    exit_a_facetarget
0x00000000000034a9:  B9 2C 00             mov   cx, SIZEOF_THINKER_T
0x00000000000034ac:  2D 04 34             sub   ax, (OFFSET _thinkerlist + THINKER_T.t_data)
0x00000000000034af:  31 D2                xor   dx, dx
0x00000000000034b1:  F7 F1                div   cx
0x00000000000034b3:  6B F8 18             imul  di, ax, SIZEOF_MOBJ_POS_T
0x00000000000034b6:  B8 F5 6A             mov   ax, MOBJPOSLIST_6800_SEGMENT
0x00000000000034b9:  8E C0                mov   es, ax
0x00000000000034bb:  26 80 65 14 DF       and   byte ptr es:[di + MOBJ_POS_T.mp_flags1], (NOT MF_AMBUSH)
0x00000000000034c0:  89 FE                mov   si, di
0x00000000000034c2:  6B 7F 22 18          imul  di, word ptr ds:[bx + MOBJ_T.m_targetRef], SIZEOF_MOBJ_POS_T
0x00000000000034c6:  89 46 FE             mov   word ptr [bp - 2], ax
0x00000000000034c9:  89 FB                mov   bx, di
0x00000000000034cb:  26 F6 45 16 04       test  byte ptr es:[di + MOBJ_POS_T.mp_flags2], 4
0x00000000000034d0:  74 43                je    label_111
0x00000000000034d2:  C7 46 FC 01 00       mov   word ptr [bp - 4], 1
label_113:
0x00000000000034d7:  26 FF 77 06          push  word ptr es:[bx + MOBJ_POS_T.mp_y + 2]
0x00000000000034db:  26 FF 77 04          push  word ptr es:[bx + MOBJ_POS_T.mp_y + 0]
0x00000000000034df:  26 FF 77 02          push  word ptr es:[bx + 2]
0x00000000000034e3:  26 FF 37             push  word ptr es:[bx]
0x00000000000034e6:  8E 46 FE             mov   es, word ptr [bp - 2]
0x00000000000034e9:  26 8B 5C 04          mov   bx, word ptr es:[si + MOBJ_POS_T.mp_y + 0]
0x00000000000034ed:  26 8B 4C 06          mov   cx, word ptr es:[si + MOBJ_POS_T.mp_y + 2]
0x00000000000034f1:  26 8B 04             mov   ax, word ptr es:[si]
0x00000000000034f4:  26 8B 54 02          mov   dx, word ptr es:[si + 2]
0x00000000000034f8:  0E                   push  cs
0x00000000000034f9:  E8 3D 6C             call  R_PointToAngle2_
0x00000000000034fc:  90                   nop   
0x00000000000034fd:  8E 46 FE             mov   es, word ptr [bp - 2]
0x0000000000003500:  26 89 44 0E          mov   word ptr es:[si + MOBJ_POS_T.mp_angle + 0], ax
0x0000000000003504:  26 89 54 10          mov   word ptr es:[si + MOBJ_POS_T.mp_angle + 2], dx
0x0000000000003508:  80 7E FC 00          cmp   byte ptr [bp - 4], 0
0x000000000000350c:  75 0E                jne   label_112
exit_a_facetarget:
0x000000000000350e:  C9                   LEAVE_MACRO 
0x000000000000350f:  5F                   pop   di
0x0000000000003510:  5E                   pop   si
0x0000000000003511:  5A                   pop   dx
0x0000000000003512:  59                   pop   cx
0x0000000000003513:  5B                   pop   bx
0x0000000000003514:  C3                   ret   
label_111:
0x0000000000003515:  C7 46 FC 00 00       mov   word ptr [bp - 4], 0
0x000000000000351a:  EB BB                jmp   label_113
label_112:
0x000000000000351c:  E8 91 54             call  P_Random_
0x000000000000351f:  88 C2                mov   dl, al
0x0000000000003521:  E8 8C 54             call  P_Random_
0x0000000000003524:  88 C3                mov   bl, al
0x0000000000003526:  30 F6                xor   dh, dh
0x0000000000003528:  30 FF                xor   bh, bh
0x000000000000352a:  29 DA                sub   dx, bx
0x000000000000352c:  89 D3                mov   bx, dx
0x000000000000352e:  8E 46 FE             mov   es, word ptr [bp - 2]
0x0000000000003531:  C1 E3 05             shl   bx, 5
0x0000000000003534:  26 01 5C 10          add   word ptr es:[si + MOBJ_POS_T.mp_angle + 2], bx
0x0000000000003538:  C9                   LEAVE_MACRO 
0x0000000000003539:  5F                   pop   di
0x000000000000353a:  5E                   pop   si
0x000000000000353b:  5A                   pop   dx
0x000000000000353c:  59                   pop   cx
0x000000000000353d:  5B                   pop   bx
0x000000000000353e:  C3                   ret   
0x000000000000353f:  FC                   cld   

ENDP


PROC    A_PosAttack_ NEAR
PUBLIC  A_PosAttack_

0x0000000000003540:  53                   push  bx
0x0000000000003541:  51                   push  cx
0x0000000000003542:  52                   push  dx
0x0000000000003543:  56                   push  si
0x0000000000003544:  57                   push  di
0x0000000000003545:  55                   push  bp
0x0000000000003546:  89 E5                mov   bp, sp
0x0000000000003548:  83 EC 02             sub   sp, 2
0x000000000000354b:  89 C6                mov   si, ax
0x000000000000354d:  83 7C 22 00          cmp   word ptr ds:[si + MOBJ_T.m_targetRef], 0
0x0000000000003551:  75 07                jne   do_a_posattack
0x0000000000003553:  C9                   LEAVE_MACRO 
0x0000000000003554:  5F                   pop   di
0x0000000000003555:  5E                   pop   si
0x0000000000003556:  5A                   pop   dx
0x0000000000003557:  59                   pop   cx
0x0000000000003558:  5B                   pop   bx
0x0000000000003559:  C3                   ret   
do_a_posattack:
0x000000000000355a:  BB 2C 00             mov   bx, SIZEOF_THINKER_T
0x000000000000355d:  2D 04 34             sub   ax, (OFFSET _thinkerlist + THINKER_T.t_data)
0x0000000000003560:  31 D2                xor   dx, dx
0x0000000000003562:  F7 F3                div   bx
0x0000000000003564:  6B D8 18             imul  bx, ax, SIZEOF_MOBJ_POS_T
0x0000000000003567:  89 F0                mov   ax, si
0x0000000000003569:  BA F5 6A             mov   dx, MOBJPOSLIST_6800_SEGMENT
0x000000000000356c:  E8 27 FF             call  A_FaceTarget_
0x000000000000356f:  8E C2                mov   es, dx
0x0000000000003571:  26 8B 4F 10          mov   cx, word ptr es:[bx + MOBJ_POS_T.mp_angle + 2]
0x0000000000003575:  89 F0                mov   ax, si
0x0000000000003577:  C1 E9 03             shr   cx, 3
0x000000000000357a:  BB 00 08             mov   bx, MISSILERANGE
0x000000000000357d:  89 CA                mov   dx, cx
0x000000000000357f:  FF 1E E8 0C          call  dword ptr ds:[_P_AimLineAttack]
0x0000000000003583:  89 C3                mov   bx, ax
0x0000000000003585:  89 56 FE             mov   word ptr [bp - 2], dx
0x0000000000003588:  BA 01 00             mov   dx, 1
0x000000000000358b:  89 F0                mov   ax, si
0x000000000000358d:  0E                   push  cs
0x000000000000358e:  3E E8 BE CF          call  S_StartSound_
0x0000000000003592:  E8 1B 54             call  P_Random_
0x0000000000003595:  88 C2                mov   dl, al
0x0000000000003597:  E8 16 54             call  P_Random_
0x000000000000359a:  30 F6                xor   dh, dh
0x000000000000359c:  30 E4                xor   ah, ah
0x000000000000359e:  BF 05 00             mov   di, 5
0x00000000000035a1:  29 C2                sub   dx, ax
0x00000000000035a3:  E8 0A 54             call  P_Random_
0x00000000000035a6:  01 D2                add   dx, dx
0x00000000000035a8:  30 E4                xor   ah, ah
0x00000000000035aa:  01 D1                add   cx, dx
0x00000000000035ac:  99                   cwd   
0x00000000000035ad:  F7 FF                idiv  di
0x00000000000035af:  42                   inc   dx
0x00000000000035b0:  89 D0                mov   ax, dx
0x00000000000035b2:  C1 E0 02             shl   ax, 2
0x00000000000035b5:  29 D0                sub   ax, dx
0x00000000000035b7:  80 E5 1F             and   ch, (FINEMASK SHR 8)
0x00000000000035ba:  50                   push  ax
0x00000000000035bb:  89 CA                mov   dx, cx
0x00000000000035bd:  FF 76 FE             push  word ptr [bp - 2]
0x00000000000035c0:  89 F0                mov   ax, si
0x00000000000035c2:  53                   push  bx
0x00000000000035c3:  BB 00 08             mov   bx, MISSILERANGE
0x00000000000035c6:  FF 1E EC 0C          call  dword ptr ds:[_P_LineAttack]
0x00000000000035ca:  C9                   LEAVE_MACRO 
0x00000000000035cb:  5F                   pop   di
0x00000000000035cc:  5E                   pop   si
0x00000000000035cd:  5A                   pop   dx
0x00000000000035ce:  59                   pop   cx
0x00000000000035cf:  5B                   pop   bx
0x00000000000035d0:  C3                   ret   
0x00000000000035d1:  FC                   cld   

ENDP


PROC    A_SPosAttack_ NEAR
PUBLIC  A_SPosAttack_

0x00000000000035d2:  53                   push  bx
0x00000000000035d3:  51                   push  cx
0x00000000000035d4:  52                   push  dx
0x00000000000035d5:  56                   push  si
0x00000000000035d6:  57                   push  di
0x00000000000035d7:  55                   push  bp
0x00000000000035d8:  89 E5                mov   bp, sp
0x00000000000035da:  83 EC 06             sub   sp, 6
0x00000000000035dd:  89 C7                mov   di, ax
0x00000000000035df:  83 7D 22 00          cmp   word ptr ds:[di + MOBJ_T.m_targetRef], 0
0x00000000000035e3:  75 07                jne   do_asposattack
0x00000000000035e5:  C9                   LEAVE_MACRO 
0x00000000000035e6:  5F                   pop   di
0x00000000000035e7:  5E                   pop   si
0x00000000000035e8:  5A                   pop   dx
0x00000000000035e9:  59                   pop   cx
0x00000000000035ea:  5B                   pop   bx
0x00000000000035eb:  C3                   ret   
do_asposattack:
0x00000000000035ec:  BE 2C 00             mov   si, SIZEOF_THINKER_T
0x00000000000035ef:  2D 04 34             sub   ax, (OFFSET _thinkerlist + THINKER_T.t_data)
0x00000000000035f2:  31 D2                xor   dx, dx
0x00000000000035f4:  F7 F6                div   si
0x00000000000035f6:  6B F0 18             imul  si, ax, SIZEOF_MOBJ_POS_T
0x00000000000035f9:  BA 02 00             mov   dx, 2
0x00000000000035fc:  89 F8                mov   ax, di
0x00000000000035fe:  0E                   push  cs
0x00000000000035ff:  E8 4E CF             call  S_StartSound_
0x0000000000003602:  90                   nop   
0x0000000000003603:  89 F8                mov   ax, di
0x0000000000003605:  BB F5 6A             mov   bx, MOBJPOSLIST_6800_SEGMENT
0x0000000000003608:  E8 8B FE             call  A_FaceTarget_
0x000000000000360b:  8E C3                mov   es, bx
0x000000000000360d:  26 8B 44 10          mov   ax, word ptr es:[si + MOBJ_POS_T.mp_angle + 2]
0x0000000000003611:  C1 E8 03             shr   ax, 3
0x0000000000003614:  BB 00 08             mov   bx, MISSILERANGE
0x0000000000003617:  89 46 FE             mov   word ptr [bp - 2], ax
0x000000000000361a:  89 C2                mov   dx, ax
0x000000000000361c:  89 F8                mov   ax, di
0x000000000000361e:  30 C9                xor   cl, cl
0x0000000000003620:  FF 1E E8 0C          call  dword ptr ds:[_P_AimLineAttack]
0x0000000000003624:  89 46 FA             mov   word ptr [bp - 6], ax
0x0000000000003627:  89 56 FC             mov   word ptr [bp - 4], dx
label_114:
0x000000000000362a:  E8 83 53             call  P_Random_
0x000000000000362d:  8B 76 FE             mov   si, word ptr [bp - 2]
0x0000000000003630:  88 C2                mov   dl, al
0x0000000000003632:  E8 7B 53             call  P_Random_
0x0000000000003635:  30 F6                xor   dh, dh
0x0000000000003637:  30 E4                xor   ah, ah
0x0000000000003639:  BB 05 00             mov   bx, 5
0x000000000000363c:  29 C2                sub   dx, ax
0x000000000000363e:  E8 6F 53             call  P_Random_
0x0000000000003641:  01 D2                add   dx, dx
0x0000000000003643:  30 E4                xor   ah, ah
0x0000000000003645:  01 D6                add   si, dx
0x0000000000003647:  99                   cwd   
0x0000000000003648:  F7 FB                idiv  bx
0x000000000000364a:  89 D0                mov   ax, dx
0x000000000000364c:  40                   inc   ax
0x000000000000364d:  6B C0 03             imul  ax, ax, 3
0x0000000000003650:  81 E6 FF 1F          and   si, FINEMASK
0x0000000000003654:  98                   cbw  
0x0000000000003655:  BB 00 08             mov   bx, MISSILERANGE
0x0000000000003658:  50                   push  ax
0x0000000000003659:  89 F2                mov   dx, si
0x000000000000365b:  FF 76 FC             push  word ptr [bp - 4]
0x000000000000365e:  89 F8                mov   ax, di
0x0000000000003660:  FF 76 FA             push  word ptr [bp - 6]
0x0000000000003663:  FE C1                inc   cl
0x0000000000003665:  FF 1E EC 0C          call  dword ptr ds:[_P_LineAttack]
0x0000000000003669:  80 F9 03             cmp   cl, 3
0x000000000000366c:  7C BC                jl    label_114
0x000000000000366e:  C9                   LEAVE_MACRO 
0x000000000000366f:  5F                   pop   di
0x0000000000003670:  5E                   pop   si
0x0000000000003671:  5A                   pop   dx
0x0000000000003672:  59                   pop   cx
0x0000000000003673:  5B                   pop   bx
0x0000000000003674:  C3                   ret   
0x0000000000003675:  FC                   cld   

ENDP


PROC    A_CPosAttack_ NEAR
PUBLIC  A_CPosAttack_

0x0000000000003676:  53                   push  bx
0x0000000000003677:  51                   push  cx
0x0000000000003678:  52                   push  dx
0x0000000000003679:  56                   push  si
0x000000000000367a:  57                   push  di
0x000000000000367b:  55                   push  bp
0x000000000000367c:  89 E5                mov   bp, sp
0x000000000000367e:  83 EC 02             sub   sp, 2
0x0000000000003681:  89 C6                mov   si, ax
0x0000000000003683:  83 7C 22 00          cmp   word ptr ds:[si + MOBJ_T.m_targetRef], 0
0x0000000000003687:  75 07                jne   label_114
0x0000000000003689:  C9                   LEAVE_MACRO 
0x000000000000368a:  5F                   pop   di
0x000000000000368b:  5E                   pop   si
0x000000000000368c:  5A                   pop   dx
0x000000000000368d:  59                   pop   cx
0x000000000000368e:  5B                   pop   bx
0x000000000000368f:  C3                   ret   
c:
0x0000000000003690:  BB 2C 00             mov   bx, SIZEOF_THINKER_T
0x0000000000003693:  2D 04 34             sub   ax, (OFFSET _thinkerlist + THINKER_T.t_data)
0x0000000000003696:  31 D2                xor   dx, dx
0x0000000000003698:  F7 F3                div   bx
0x000000000000369a:  6B D8 18             imul  bx, ax, SIZEOF_MOBJ_POS_T
0x000000000000369d:  BA 02 00             mov   dx, 2
0x00000000000036a0:  89 F0                mov   ax, si
0x00000000000036a2:  0E                   push  cs
0x00000000000036a3:  E8 AA CE             call  S_StartSound_
0x00000000000036a6:  90                   nop   
0x00000000000036a7:  89 F0                mov   ax, si
0x00000000000036a9:  B9 F5 6A             mov   cx, MOBJPOSLIST_6800_SEGMENT
0x00000000000036ac:  E8 E7 FD             call  A_FaceTarget_
0x00000000000036af:  8E C1                mov   es, cx
0x00000000000036b1:  26 8B 4F 10          mov   cx, word ptr es:[bx + MOBJ_POS_T.mp_angle + 2]
0x00000000000036b5:  89 F0                mov   ax, si
0x00000000000036b7:  C1 E9 03             shr   cx, 3
0x00000000000036ba:  BB 00 08             mov   bx, MISSILERANGE
0x00000000000036bd:  89 CA                mov   dx, cx
0x00000000000036bf:  FF 1E E8 0C          call  dword ptr ds:[_P_AimLineAttack]
0x00000000000036c3:  89 46 FE             mov   word ptr [bp - 2], ax
0x00000000000036c6:  89 D3                mov   bx, dx
0x00000000000036c8:  E8 E5 52             call  P_Random_
0x00000000000036cb:  88 C2                mov   dl, al
0x00000000000036cd:  E8 E0 52             call  P_Random_
0x00000000000036d0:  30 F6                xor   dh, dh
0x00000000000036d2:  30 E4                xor   ah, ah
0x00000000000036d4:  29 C2                sub   dx, ax
0x00000000000036d6:  89 D0                mov   ax, dx
0x00000000000036d8:  01 D0                add   ax, dx
0x00000000000036da:  01 C1                add   cx, ax
0x00000000000036dc:  E8 D1 52             call  P_Random_
0x00000000000036df:  30 E4                xor   ah, ah
0x00000000000036e1:  BF 05 00             mov   di, 5
0x00000000000036e4:  99                   cwd   
0x00000000000036e5:  F7 FF                idiv  di
0x00000000000036e7:  42                   inc   dx
0x00000000000036e8:  89 D0                mov   ax, dx
0x00000000000036ea:  C1 E0 02             shl   ax, 2
0x00000000000036ed:  29 D0                sub   ax, dx
0x00000000000036ef:  98                   cbw  
0x00000000000036f0:  80 E5 1F             and   ch, (FINEMASK SHR 8)
0x00000000000036f3:  50                   push  ax
0x00000000000036f4:  89 CA                mov   dx, cx
0x00000000000036f6:  53                   push  bx
0x00000000000036f7:  89 F0                mov   ax, si
0x00000000000036f9:  FF 76 FE             push  word ptr [bp - 2]
0x00000000000036fc:  BB 00 08             mov   bx, MISSILERANGE
0x00000000000036ff:  FF 1E EC 0C          call  dword ptr ds:[_P_LineAttack]
0x0000000000003703:  C9                   LEAVE_MACRO 
0x0000000000003704:  5F                   pop   di
0x0000000000003705:  5E                   pop   si
0x0000000000003706:  5A                   pop   dx
0x0000000000003707:  59                   pop   cx
0x0000000000003708:  5B                   pop   bx
0x0000000000003709:  C3                   ret   

ENDP


PROC    A_CPosRefire_ NEAR
PUBLIC  A_CPosRefire_

0x000000000000370a:  52                   push  dx
0x000000000000370b:  56                   push  si
0x000000000000370c:  57                   push  di
0x000000000000370d:  55                   push  bp
0x000000000000370e:  89 E5                mov   bp, sp
0x0000000000003710:  83 EC 04             sub   sp, 4
0x0000000000003713:  89 C6                mov   si, ax
0x0000000000003715:  E8 7E FD             call  A_FaceTarget_
0x0000000000003718:  C7 46 FC 50 03       mov   word ptr [bp - 4], GETSEESTATEADDR
0x000000000000371d:  C7 46 FE D9 92       mov   word ptr [bp - 2], INFOFUNCLOADSEGMENT
0x0000000000003722:  8B 54 22             mov   dx, word ptr ds:[si + MOBJ_T.m_targetRef]
0x0000000000003725:  E8 88 52             call  P_Random_
0x0000000000003728:  3C 28                cmp   al, 0x28
0x000000000000372a:  72 2F                jb    exit_a_cposrefire
0x000000000000372c:  85 D2                test  dx, dx
0x000000000000372e:  74 2B                je    exit_a_cposrefire
0x0000000000003730:  6B FA 2C             imul  di, dx, SIZEOF_THINKER_T
0x0000000000003733:  81 C7 04 34          add   di, (OFFSET _thinkerlist + THINKER_T.t_data)
0x0000000000003737:  85 D2                test  dx, dx
0x0000000000003739:  74 25                je    label_115
0x000000000000373b:  83 7D 1C 00          cmp   word ptr ds:[di + MOBJ_T.m_health], 0
0x000000000000373f:  7E 1F                jle   label_115
0x0000000000003741:  B9 2C 00             mov   cx, SIZEOF_THINKER_T
0x0000000000003744:  8D 85 FC CB          lea   ax, ds:[di - (OFFSET _thinkerlist + THINKER_T.t_data)]
0x0000000000003748:  31 D2                xor   dx, dx
0x000000000000374a:  F7 F1                div   cx
0x000000000000374c:  6B C8 18             imul  cx, ax, SIZEOF_MOBJ_POS_T
0x000000000000374f:  89 FA                mov   dx, di
0x0000000000003751:  89 F0                mov   ax, si
0x0000000000003753:  FF 1E CC 0C          call  dword ptr ds:[_P_CheckSightTemp]
0x0000000000003757:  84 C0                test  al, al
0x0000000000003759:  74 05                je    label_115
exit_a_cposrefire:
0x000000000000375b:  C9                   LEAVE_MACRO 
0x000000000000375c:  5F                   pop   di
0x000000000000375d:  5E                   pop   si
0x000000000000375e:  5A                   pop   dx
0x000000000000375f:  C3                   ret   
label_115:
0x0000000000003760:  8A 44 1A             mov   al, byte ptr ds:[si + MOBJ_T.m_mobjtype]
0x0000000000003763:  30 E4                xor   ah, ah
0x0000000000003765:  FF 5E FC             call  dword ptr [bp - 4]
0x0000000000003768:  89 C2                mov   dx, ax
0x000000000000376a:  89 F0                mov   ax, si
0x000000000000376c:  0E                   push  cs
0x000000000000376d:  E8 7E 58             call  P_SetMobjState_
0x0000000000003770:  90                   nop   
0x0000000000003771:  C9                   LEAVE_MACRO 
0x0000000000003772:  5F                   pop   di
0x0000000000003773:  5E                   pop   si
0x0000000000003774:  5A                   pop   dx
0x0000000000003775:  C3                   ret   

ENDP


PROC    A_SpidRefire_ NEAR
PUBLIC  A_SpidRefire_

0x0000000000003776:  52                   push  dx
0x0000000000003777:  56                   push  si
0x0000000000003778:  57                   push  di
0x0000000000003779:  55                   push  bp
0x000000000000377a:  89 E5                mov   bp, sp
0x000000000000377c:  83 EC 04             sub   sp, 4
0x000000000000377f:  89 C6                mov   si, ax
0x0000000000003781:  E8 12 FD             call  A_FaceTarget_
0x0000000000003784:  C7 46 FC 50 03       mov   word ptr [bp - 4], GETSEESTATEADDR
0x0000000000003789:  C7 46 FE D9 92       mov   word ptr [bp - 2], INFOFUNCLOADSEGMENT
0x000000000000378e:  8B 54 22             mov   dx, word ptr ds:[si + MOBJ_T.m_targetRef]
0x0000000000003791:  E8 1C 52             call  P_Random_
0x0000000000003794:  3C 0A                cmp   al, 10
0x0000000000003796:  72 2F                jb    exit_a_spidrefire
0x0000000000003798:  85 D2                test  dx, dx
0x000000000000379a:  74 2B                je    exit_a_spidrefire
0x000000000000379c:  6B FA 2C             imul  di, dx, SIZEOF_THINKER_T
0x000000000000379f:  81 C7 04 34          add   di, (OFFSET _thinkerlist + THINKER_T.t_data)
0x00000000000037a3:  85 D2                test  dx, dx
0x00000000000037a5:  74 25                je    label_116
0x00000000000037a7:  83 7D 1C 00          cmp   word ptr ds:[di + MOBJ_T.m_health], 0
0x00000000000037ab:  7E 1F                jle   label_116
0x00000000000037ad:  B9 2C 00             mov   cx, SIZEOF_THINKER_T
0x00000000000037b0:  8D 85 FC CB          lea   ax, ds:[di - (OFFSET _thinkerlist + THINKER_T.t_data)]
0x00000000000037b4:  31 D2                xor   dx, dx
0x00000000000037b6:  F7 F1                div   cx
0x00000000000037b8:  6B C8 18             imul  cx, ax, SIZEOF_MOBJ_POS_T
0x00000000000037bb:  89 FA                mov   dx, di
0x00000000000037bd:  89 F0                mov   ax, si
0x00000000000037bf:  FF 1E CC 0C          call  dword ptr ds:[_P_CheckSightTemp]
0x00000000000037c3:  84 C0                test  al, al
0x00000000000037c5:  74 05                je    label_116
exit_a_spidrefire:
0x00000000000037c7:  C9                   LEAVE_MACRO 
0x00000000000037c8:  5F                   pop   di
0x00000000000037c9:  5E                   pop   si
0x00000000000037ca:  5A                   pop   dx
0x00000000000037cb:  C3                   ret   
label_116:
0x00000000000037cc:  8A 44 1A             mov   al, byte ptr ds:[si + MOBJ_T.m_mobjtype]
0x00000000000037cf:  30 E4                xor   ah, ah
0x00000000000037d1:  FF 5E FC             call  dword ptr [bp - 4]
0x00000000000037d4:  89 C2                mov   dx, ax
0x00000000000037d6:  89 F0                mov   ax, si
0x00000000000037d8:  0E                   push  cs
0x00000000000037d9:  E8 12 58             call  P_SetMobjState_
0x00000000000037dc:  90                   nop   
0x00000000000037dd:  C9                   LEAVE_MACRO 
0x00000000000037de:  5F                   pop   di
0x00000000000037df:  5E                   pop   si
0x00000000000037e0:  5A                   pop   dx
0x00000000000037e1:  C3                   ret   

ENDP


PROC    A_BspiAttack_ NEAR
PUBLIC  A_BspiAttack_

0x00000000000037e2:  52                   push  dx
0x00000000000037e3:  56                   push  si
0x00000000000037e4:  89 C6                mov   si, ax
0x00000000000037e6:  83 7C 22 00          cmp   word ptr ds:[si + MOBJ_T.m_targetRef], 0
0x00000000000037ea:  75 03                jne   do_a_bspiattack
0x00000000000037ec:  5E                   pop   si
0x00000000000037ed:  5A                   pop   dx
0x00000000000037ee:  C3                   ret   
do_a_bspiattack:
0x00000000000037ef:  E8 A4 FC             call  A_FaceTarget_
0x00000000000037f2:  6B 54 22 2C          imul  dx, word ptr ds:[si + MOBJ_T.m_targetRef], SIZEOF_THINKER_T
0x00000000000037f6:  6A 24                push  MT_ARACHPLAZ  ; todo 186
0x00000000000037f8:  89 F0                mov   ax, si
0x00000000000037fa:  81 C2 04 34          add   dx, (OFFSET _thinkerlist + THINKER_T.t_data)
0x00000000000037fe:  FF 1E F8 0C          call  dword ptr ds:[_SpawnMissile]
0x0000000000003802:  5E                   pop   si
0x0000000000003803:  5A                   pop   dx
0x0000000000003804:  C3                   ret   
0x0000000000003805:  FC                   cld   

ENDP


PROC    A_TroopAttack_ NEAR
PUBLIC  A_TroopAttack_

0x0000000000003806:  52                   push  dx
0x0000000000003807:  56                   push  si
0x0000000000003808:  89 C6                mov   si, ax
0x000000000000380a:  83 7C 22 00          cmp   word ptr ds:[si + MOBJ_T.m_targetRef], 0
0x000000000000380e:  75 03                jne   do_a_troopattack
0x0000000000003810:  5E                   pop   si
0x0000000000003811:  5A                   pop   dx
0x0000000000003812:  C3                   ret   
do_a_troopattack:
0x0000000000003813:  E8 80 FC             call  A_FaceTarget_
0x0000000000003816:  89 F0                mov   ax, si
0x0000000000003818:  E8 C3 F1             call  P_CheckMeleeRange_
0x000000000000381b:  84 C0                test  al, al
0x000000000000381d:  74 3A                je    do_troop_missile
0x000000000000381f:  BA 37 00             mov   dx, sfx_claw
0x0000000000003822:  89 F0                mov   ax, si
0x0000000000003824:  0E                   push  cs
0x0000000000003825:  E8 28 CD             call  S_StartSound_
0x0000000000003828:  90                   nop   
0x0000000000003829:  E8 84 51             call  P_Random_
0x000000000000382c:  30 E4                xor   ah, ah
0x000000000000382e:  89 C1                mov   cx, ax
0x0000000000003830:  C1 F9 0F             sar   cx, 0Fh  ; todo no
0x0000000000003833:  31 C8                xor   ax, cx
0x0000000000003835:  29 C8                sub   ax, cx
0x0000000000003837:  25 07 00             and   ax, 7
0x000000000000383a:  31 C8                xor   ax, cx
0x000000000000383c:  29 C8                sub   ax, cx
0x000000000000383e:  40                   inc   ax
0x000000000000383f:  89 C1                mov   cx, ax
0x0000000000003841:  C1 E1 02             shl   cx, 2
0x0000000000003844:  29 C1                sub   cx, ax
0x0000000000003846:  6B 44 22 2C          imul  ax, word ptr ds:[si + MOBJ_T.m_targetRef], SIZEOF_THINKER_T
0x000000000000384a:  89 F3                mov   bx, si
0x000000000000384c:  89 F2                mov   dx, si
0x000000000000384e:  05 04 34             add   ax, (OFFSET _thinkerlist + THINKER_T.t_data)
0x0000000000003851:  0E                   push  cs
0x0000000000003852:  3E E8 DA 28          call  P_DamageMobj_
0x0000000000003856:  5E                   pop   si
0x0000000000003857:  5A                   pop   dx
0x0000000000003858:  C3                   ret   
do_troop_missile:
0x0000000000003859:  6B 54 22 2C          imul  dx, word ptr ds:[si + MOBJ_T.m_targetRef], SIZEOF_THINKER_T
0x000000000000385d:  6A 1F                push  MT_TROOPSHOT  ; todo 186
0x000000000000385f:  89 F0                mov   ax, si
0x0000000000003861:  81 C2 04 34          add   dx, (OFFSET _thinkerlist + THINKER_T.t_data)
0x0000000000003865:  FF 1E F8 0C          call  dword ptr ds:[_SpawnMissile]
0x0000000000003869:  5E                   pop   si
0x000000000000386a:  5A                   pop   dx
0x000000000000386b:  C3                   ret   

ENDP


PROC    A_SargAttack_ NEAR
PUBLIC  A_SargAttack_

0x000000000000386c:  53                   push  bx
0x000000000000386d:  51                   push  cx
0x000000000000386e:  52                   push  dx
0x000000000000386f:  56                   push  si
0x0000000000003870:  89 C6                mov   si, ax
0x0000000000003872:  83 7C 22 00          cmp   word ptr ds:[si + MOBJ_T.m_targetRef], 0
0x0000000000003876:  75 05                jne   do_a_sargattack
exit_a_sargattack:
0x0000000000003878:  5E                   pop   si
0x0000000000003879:  5A                   pop   dx
0x000000000000387a:  59                   pop   cx
0x000000000000387b:  5B                   pop   bx
0x000000000000387c:  C3                   ret   
do_a_sargattack:
0x000000000000387d:  E8 16 FC             call  A_FaceTarget_
0x0000000000003880:  89 F0                mov   ax, si
0x0000000000003882:  E8 59 F1             call  P_CheckMeleeRange_
0x0000000000003885:  84 C0                test  al, al
0x0000000000003887:  74 EF                je    exit_a_sargattack
0x0000000000003889:  E8 24 51             call  P_Random_
0x000000000000388c:  30 E4                xor   ah, ah
0x000000000000388e:  B9 0A 00             mov   cx, 10
0x0000000000003891:  99                   cwd   
0x0000000000003892:  F7 F9                idiv  cx
0x0000000000003894:  6B 44 22 2C          imul  ax, word ptr ds:[si + MOBJ_T.m_targetRef], SIZEOF_THINKER_T
0x0000000000003898:  89 D1                mov   cx, dx
0x000000000000389a:  89 F3                mov   bx, si
0x000000000000389c:  C1 E1 02             shl   cx, 2
0x000000000000389f:  89 F2                mov   dx, si
0x00000000000038a1:  83 C1 04             add   cx, 4

0x00000000000038a4:  05 04 34             add   ax, (OFFSET _thinkerlist + THINKER_T.t_data)
0x00000000000038a7:  0E                   push  cs
0x00000000000038a8:  3E E8 84 28          call  P_DamageMobj_
0x00000000000038ac:  5E                   pop   si
0x00000000000038ad:  5A                   pop   dx
0x00000000000038ae:  59                   pop   cx
0x00000000000038af:  5B                   pop   bx
0x00000000000038b0:  C3                   ret   
0x00000000000038b1:  FC                   cld   

ENDP


PROC    A_HeadAttack_ NEAR
PUBLIC  A_HeadAttack_

0x00000000000038b2:  52                   push  dx
0x00000000000038b3:  56                   push  si
0x00000000000038b4:  89 C6                mov   si, ax
0x00000000000038b6:  83 7C 22 00          cmp   word ptr ds:[si + MOBJ_T.m_targetRef], 0
0x00000000000038ba:  75 03                jne   do_head_attack
0x00000000000038bc:  5E                   pop   si
0x00000000000038bd:  5A                   pop   dx
0x00000000000038be:  C3                   ret   
do_head_attack:
0x00000000000038bf:  E8 D4 FB             call  A_FaceTarget_
0x00000000000038c2:  89 F0                mov   ax, si
0x00000000000038c4:  E8 17 F1             call  P_CheckMeleeRange_
0x00000000000038c7:  84 C0                test  al, al
0x00000000000038c9:  74 28                je    label_117
0x00000000000038cb:  E8 E2 50             call  P_Random_
0x00000000000038ce:  30 E4                xor   ah, ah
0x00000000000038d0:  BB 06 00             mov   bx, 6
0x00000000000038d3:  99                   cwd   
0x00000000000038d4:  F7 FB                idiv  bx
0x00000000000038d6:  6B 44 22 2C          imul  ax, word ptr ds:[si + MOBJ_T.m_targetRef], SIZEOF_THINKER_T
0x00000000000038da:  42                   inc   dx
0x00000000000038db:  89 D1                mov   cx, dx
0x00000000000038dd:  C1 E1 02             shl   cx, 2
0x00000000000038e0:  89 F3                mov   bx, si
0x00000000000038e2:  01 D1                add   cx, dx
0x00000000000038e4:  89 F2                mov   dx, si
0x00000000000038e6:  01 C9                add   cx, cx
0x00000000000038e8:  05 04 34             add   ax, (OFFSET _thinkerlist + THINKER_T.t_data)
0x00000000000038eb:  0E                   push  cs
0x00000000000038ec:  3E E8 40 28          call  P_DamageMobj_
0x00000000000038f0:  5E                   pop   si
0x00000000000038f1:  5A                   pop   dx
0x00000000000038f2:  C3                   ret   
label_117:
0x00000000000038f3:  6B 54 22 2C          imul  dx, word ptr ds:[si + MOBJ_T.m_targetRef], SIZEOF_THINKER_T
0x00000000000038f7:  6A 20                push  MT_HEADSHOT  ; todo 186
0x00000000000038f9:  89 F0                mov   ax, si
0x00000000000038fb:  81 C2 04 34          add   dx, (OFFSET _thinkerlist + THINKER_T.t_data)
0x00000000000038ff:  FF 1E F8 0C          call  dword ptr ds:[_SpawnMissile]
0x0000000000003903:  5E                   pop   si
0x0000000000003904:  5A                   pop   dx
0x0000000000003905:  C3                   ret   
ENDP


PROC    A_CyberAttack_ NEAR
PUBLIC  A_CyberAttack_


0x0000000000003906:  52                   push  dx
0x0000000000003907:  56                   push  si
0x0000000000003908:  89 C6                mov   si, ax
0x000000000000390a:  83 7C 22 00          cmp   word ptr ds:[si + MOBJ_T.m_targetRef], 0
0x000000000000390e:  75 03                jne   label_118
0x0000000000003910:  5E                   pop   si
0x0000000000003911:  5A                   pop   dx
0x0000000000003912:  C3                   ret   
label_118:
0x0000000000003913:  E8 80 FB             call  A_FaceTarget_
0x0000000000003916:  6B 54 22 2C          imul  dx, word ptr ds:[si + MOBJ_T.m_targetRef], SIZEOF_THINKER_T
0x000000000000391a:  6A 21                push  MT_ROCKET
0x000000000000391c:  89 F0                mov   ax, si
0x000000000000391e:  81 C2 04 34          add   dx, (OFFSET _thinkerlist + THINKER_T.t_data)
0x0000000000003922:  FF 1E F8 0C          call  dword ptr ds:[_SpawnMissile]
0x0000000000003926:  5E                   pop   si
0x0000000000003927:  5A                   pop   dx
0x0000000000003928:  C3                   ret   
0x0000000000003929:  FC                   cld   

ENDP


PROC    A_BruisAttack_ NEAR
PUBLIC  A_BruisAttack_

0x000000000000392a:  52                   push  dx
0x000000000000392b:  56                   push  si
0x000000000000392c:  89 C6                mov   si, ax
0x000000000000392e:  83 7C 22 00          cmp   word ptr ds:[si + MOBJ_T.m_targetRef], 0
0x0000000000003932:  75 03                jne   do_a_bruisattack
0x0000000000003934:  5E                   pop   si
0x0000000000003935:  5A                   pop   dx
0x0000000000003936:  C3                   ret   
do_a_bruisattack:
0x0000000000003937:  E8 A4 F0             call  P_CheckMeleeRange_
0x000000000000393a:  84 C0                test  al, al
0x000000000000393c:  74 3C                je    do_bruis_missile
0x000000000000393e:  BA 37 00             mov   dx, sfx_claw
0x0000000000003941:  89 F0                mov   ax, si
0x0000000000003943:  0E                   push  cs
0x0000000000003944:  3E E8 08 CC          call  S_StartSound_
0x0000000000003948:  E8 65 50             call  P_Random_
0x000000000000394b:  30 E4                xor   ah, ah
0x000000000000394d:  89 C1                mov   cx, ax
0x000000000000394f:  C1 F9 0F             sar   cx, 0Fh ; todo no
0x0000000000003952:  31 C8                xor   ax, cx
0x0000000000003954:  29 C8                sub   ax, cx
0x0000000000003956:  25 07 00             and   ax, 7
0x0000000000003959:  31 C8                xor   ax, cx
0x000000000000395b:  29 C8                sub   ax, cx
0x000000000000395d:  40                   inc   ax
0x000000000000395e:  89 C1                mov   cx, ax
0x0000000000003960:  C1 E1 02             shl   cx, 2
0x0000000000003963:  01 C1                add   cx, ax
0x0000000000003965:  6B 44 22 2C          imul  ax, word ptr ds:[si + MOBJ_T.m_targetRef], SIZEOF_THINKER_T
0x0000000000003969:  89 F3                mov   bx, si
0x000000000000396b:  89 F2                mov   dx, si
0x000000000000396d:  01 C9                add   cx, cx
0x000000000000396f:  05 04 34             add   ax, (OFFSET _thinkerlist + THINKER_T.t_data)
0x0000000000003972:  0E                   push  cs
0x0000000000003973:  E8 BA 27             call  P_DamageMobj_
0x0000000000003976:  90                   nop   
0x0000000000003977:  5E                   pop   si
0x0000000000003978:  5A                   pop   dx
0x0000000000003979:  C3                   ret   
do_bruis_missile:
0x000000000000397a:  6B 54 22 2C          imul  dx, word ptr ds:[si + MOBJ_T.m_targetRef], SIZEOF_THINKER_T
0x000000000000397e:  6A 10                push  MT_BRUISERSHOT ; todo 186
0x0000000000003980:  89 F0                mov   ax, si
0x0000000000003982:  81 C2 04 34          add   dx, (OFFSET _thinkerlist + THINKER_T.t_data)
0x0000000000003986:  FF 1E F8 0C          call  dword ptr ds:[_SpawnMissile]
0x000000000000398a:  5E                   pop   si
0x000000000000398b:  5A                   pop   dx
0x000000000000398c:  C3                   ret   
0x000000000000398d:  FC                   cld   

ENDP


PROC    A_SkelMissile_ NEAR
PUBLIC  A_SkelMissile_

0x000000000000398e:  52                   push  dx
0x000000000000398f:  56                   push  si
0x0000000000003990:  57                   push  di
0x0000000000003991:  55                   push  bp
0x0000000000003992:  89 E5                mov   bp, sp
0x0000000000003994:  83 EC 06             sub   sp, 6
0x0000000000003997:  89 C6                mov   si, ax
0x0000000000003999:  89 5E FE             mov   word ptr [bp - 2], bx
0x000000000000399c:  89 4E FC             mov   word ptr [bp - 4], cx
0x000000000000399f:  83 7C 22 00          cmp   word ptr ds:[si + MOBJ_T.m_targetRef], 0
0x00000000000039a3:  75 05                jne   do_a_skelmissile
0x00000000000039a5:  C9                   LEAVE_MACRO 
0x00000000000039a6:  5F                   pop   di
0x00000000000039a7:  5E                   pop   si
0x00000000000039a8:  5A                   pop   dx
0x00000000000039a9:  C3                   ret   
do_a_skelmissile:
0x00000000000039aa:  E8 E9 FA             call  A_FaceTarget_
0x00000000000039ad:  8E C1                mov   es, cx
0x00000000000039af:  26 83 47 0A 10       add   word ptr es:[bx + MOBJ_POS_T.mp_z + 2], 16
0x00000000000039b4:  6B 54 22 2C          imul  dx, word ptr ds:[si + MOBJ_T.m_targetRef], SIZEOF_THINKER_T
0x00000000000039b8:  6A 06                push  MT_TRACER  ;todo 186
0x00000000000039ba:  89 F0                mov   ax, si
0x00000000000039bc:  81 C2 04 34          add   dx, (OFFSET _thinkerlist + THINKER_T.t_data)
0x00000000000039c0:  BF 34 07             mov   di, OFFSET _setStateReturn_pos
0x00000000000039c3:  FF 1E F8 0C          call  dword ptr ds:[_SpawnMissile]
0x00000000000039c7:  BB BA 01             mov   bx, OFFSET _setStateReturn
0x00000000000039ca:  8B 45 02             mov   ax, word ptr ds:[di + 2]
0x00000000000039cd:  8B 0F                mov   cx, word ptr ds:[bx]
0x00000000000039cf:  8B 1D                mov   bx, word ptr ds:[di]
0x00000000000039d1:  8E 46 FC             mov   es, word ptr [bp - 4]
0x00000000000039d4:  8B 7E FE             mov   di, word ptr [bp - 2]
0x00000000000039d7:  26 83 6D 0A 10       sub   word ptr es:[di + MOBJ_POS_T.mp_z + 2], 16
0x00000000000039dc:  89 46 FA             mov   word ptr [bp - 6], ax
0x00000000000039df:  8B 44 22             mov   ax, word ptr ds:[si + MOBJ_T.m_targetRef]
0x00000000000039e2:  89 CE                mov   si, cx
0x00000000000039e4:  8B 54 0E             mov   dx, word ptr ds:[si + MOBJ_T.m_momx + 0]
0x00000000000039e7:  8B 74 10             mov   si, word ptr ds:[si + MOBJ_T.m_momx + 2]
0x00000000000039ea:  8E 46 FA             mov   es, word ptr [bp - 6]
0x00000000000039ed:  26 01 17             add   word ptr es:[bx + MOBJ_POS_T.mp_x+0], dx
0x00000000000039f0:  26 11 77 02          adc   word ptr es:[bx + MOBJ_POS_T.mp_y+2], si
0x00000000000039f4:  89 CE                mov   si, cx
0x00000000000039f6:  89 CF                mov   di, cx

;	mo_pos->x.w += mo->momx.w;
;	mo_pos->y.w += mo->momy.w;

0x00000000000039f8:  8B 74 12             mov   si, word ptr ds:[si + MOBJ_T.m_momy + 0]
0x00000000000039fb:  8B 55 14             mov   dx, word ptr ds:[di + MOBJ_T.m_momy + 2]
0x00000000000039fe:  26 01 77 04          add   word ptr es:[bx + MOBJ_POS_T.mp_y+0], si
0x0000000000003a02:  26 11 57 06          adc   word ptr es:[bx + MOBJ_POS_T.mp_y+2], dx
0x0000000000003a06:  89 45 26             mov   word ptr ds:[di + MOBJ_T.m_tracerRef], ax
0x0000000000003a09:  C9                   LEAVE_MACRO 
0x0000000000003a0a:  5F                   pop   di
0x0000000000003a0b:  5E                   pop   si
0x0000000000003a0c:  5A                   pop   dx
0x0000000000003a0d:  C3                   ret   

ENDP


PROC    A_Tracer_ NEAR
PUBLIC  A_Tracer_

0x0000000000003a0e:  52                   push  dx
0x0000000000003a0f:  56                   push  si
0x0000000000003a10:  57                   push  di
0x0000000000003a11:  55                   push  bp
0x0000000000003a12:  89 E5                mov   bp, sp
0x0000000000003a14:  83 EC 04             sub   sp, 4
0x0000000000003a17:  50                   push  ax
0x0000000000003a18:  53                   push  bx
0x0000000000003a19:  51                   push  cx
0x0000000000003a1a:  F6 06 54 1E 03       test  byte ptr ds:[_gametic], 3
0x0000000000003a1f:  74 05                je    do_a_tracer
exit_a_tracer:
0x0000000000003a21:  C9                   LEAVE_MACRO 
0x0000000000003a22:  5F                   pop   di
0x0000000000003a23:  5E                   pop   si
0x0000000000003a24:  5A                   pop   dx
0x0000000000003a25:  C3                   ret   
do_a_tracer:
0x0000000000003a26:  8E C1                mov   es, cx
0x0000000000003a28:  89 DE                mov   si, bx
0x0000000000003a2a:  8B 7E F8             mov   di, word ptr [bp - 8]
0x0000000000003a2d:  26 8B 74 08          mov   si, word ptr es:[si + MOBJ_POS_T.mp_z+0]
0x0000000000003a31:  26 8B 4F 0A          mov   cx, word ptr es:[bx + MOBJ_POS_T.mp_z+2]
0x0000000000003a35:  26 8B 45 06          mov   ax, word ptr es:[di + MOBJ_POS_T.mp_y+2]
0x0000000000003a39:  26 8B 55 02          mov   dx, word ptr es:[di + MOBJ_POS_T.mp_x+2]
0x0000000000003a3d:  89 46 FC             mov   word ptr [bp - 4], ax
0x0000000000003a40:  26 8B 5F 04          mov   bx, word ptr es:[bx + MOBJ_POS_T.mp_y+0]
0x0000000000003a44:  26 8B 05             mov   ax, word ptr es:[di + MOBJ_POS_T.mp_x+0]
0x0000000000003a47:  89 CF                mov   di, cx
0x0000000000003a49:  8B 4E FC             mov   cx, word ptr [bp - 4]
0x0000000000003a4c:  0E                   push  cs
0x0000000000003a4d:  E8 86 58             call  P_SpawnPuff_
0x0000000000003a50:  90                   nop   
0x0000000000003a51:  6A FF                push  -1 ; todo 186
0x0000000000003a53:  8E 46 F6             mov   es, word ptr [bp - 0Ah]
0x0000000000003a56:  8B 5E F8             mov   bx, word ptr [bp - 8]
0x0000000000003a59:  8B 76 F8             mov   si, word ptr [bp - 8]
0x0000000000003a5c:  6A 07                push  MT_SMOKE ; todo 186
0x0000000000003a5e:  26 8B 4C 06          mov   cx, word ptr es:[si + MOBJ_POS_T.mp_y + 2]
0x0000000000003a62:  26 FF 77 0A          push  word ptr es:[bx + MOBJ_POS_T.mp_z+2]
0x0000000000003a66:  8B 76 FA             mov   si, word ptr [bp - 6]
0x0000000000003a69:  26 FF 77 08          push  word ptr es:[bx + MOBJ_POS_T.mp_z+0]
0x0000000000003a6d:  26 8B 5F 04          mov   bx, word ptr es:[bx + MOBJ_POS_T.mp_y+0]
0x0000000000003a71:  2B 5C 12             sub   bx, word ptr ds:[si + MOBJ_T.m_momy + 0]
0x0000000000003a74:  1B 4C 14             sbb   cx, word ptr ds:[si + MOBJ_T.m_momy + 2]
0x0000000000003a77:  8B 76 F8             mov   si, word ptr [bp - 8]
0x0000000000003a7a:  26 8B 04             mov   ax, word ptr es:[si + MOBJ_POS_T.mp_x+0]
0x0000000000003a7d:  26 8B 54 02          mov   dx, word ptr es:[si + MOBJ_POS_T.mp_x+2]
0x0000000000003a81:  8B 76 FA             mov   si, word ptr [bp - 6]
0x0000000000003a84:  2B 44 0E             sub   ax, word ptr ds:[si + MOBJ_T.m_momx + 0]
0x0000000000003a87:  1B 54 10             sbb   dx, word ptr ds:[si + MOBJ_T.m_momx + 2]
0x0000000000003a8a:  0E                   push  cs
0x0000000000003a8b:  E8 16 53             call  P_SpawnMobj_
0x0000000000003a8e:  90                   nop   
0x0000000000003a8f:  BB BA 01             mov   bx, OFFSET _setStateReturn
0x0000000000003a92:  8B 1F                mov   bx, word ptr ds:[bx]
0x0000000000003a94:  C7 47 18 01 00       mov   word ptr ds:[bx + MOBJ_T.m_momz + 2], 1
0x0000000000003a99:  E8 14 4F             call  P_Random_
0x0000000000003a9c:  24 03                and   al, 3
0x0000000000003a9e:  28 47 1B             sub   byte ptr ds:[bx + MOBJ_T.m_tics], al
0x0000000000003aa1:  8A 47 1B             mov   al, byte ptr ds:[bx + MOBJ_T.m_tics]
0x0000000000003aa4:  3C 01                cmp   al, 1
0x0000000000003aa6:  72 03                jb    label_119
0x0000000000003aa8:  E9 B5 01             jmp   label_120
label_119:
0x0000000000003aab:  C6 47 1B 01          mov   byte ptr ds:[bx + MOBJ_T.m_tics], 1
label_121:
0x0000000000003aaf:  8B 5E FA             mov   bx, word ptr [bp - 6]
0x0000000000003ab2:  8B 47 26             mov   ax, word ptr ds:[bx + MOBJ_T.m_tracerRef]
0x0000000000003ab5:  85 C0                test  ax, ax
0x0000000000003ab7:  75 03                jne   label_122
jump_to_exit_a_tracer:
0x0000000000003ab9:  E9 65 FF             jmp   exit_a_tracer
label_122:
0x0000000000003abc:  6B D8 2C             imul  bx, ax, SIZEOF_THINKER_T
0x0000000000003abf:  81 C3 04 34          add   bx, (OFFSET _thinkerlist + THINKER_T.t_data)
0x0000000000003ac3:  74 F4                je    jump_to_exit_a_tracer
0x0000000000003ac5:  83 7F 1C 00          cmp   word ptr ds:[bx + MOBJ_T.m_health], 0
0x0000000000003ac9:  7E EE                jle   jump_to_exit_a_tracer
0x0000000000003acb:  26 FF 77 06          push  word ptr es:[bx + MOBJ_POS_T.mp_y + 2]
0x0000000000003acf:  26 FF 77 04          push  word ptr es:[bx + MOBJ_POS_T.mp_y + 0]
0x0000000000003ad3:  26 FF 77 02          push  word ptr es:[bx + MOBJ_POS_T.mp_x + 2]
0x0000000000003ad7:  26 FF 37             push  word ptr es:[bx + MOBJ_POS_T.mp_x + 0]
0x0000000000003ada:  8E 46 F6             mov   es, word ptr [bp - 0Ah]
0x0000000000003add:  8B 5E F8             mov   bx, word ptr [bp - 8]
0x0000000000003ae0:  8B 76 F8             mov   si, word ptr [bp - 8]
0x0000000000003ae3:  26 8B 5F 04          mov   bx, word ptr es:[bx + MOBJ_POS_T.mp_y + 0]
0x0000000000003ae7:  26 8B 4C 06          mov   cx, word ptr es:[si + MOBJ_POS_T.mp_y + 2]
0x0000000000003aeb:  26 8B 04             mov   ax, word ptr es:[si + MOBJ_POS_T.mp_x + 0]
0x0000000000003aee:  26 8B 54 02          mov   dx, word ptr es:[si + MOBJ_POS_T.mp_x + 2]
0x0000000000003af2:  0E                   push  cs
0x0000000000003af3:  E8 43 66             call  R_PointToAngle2_
0x0000000000003af6:  90                   nop   
0x0000000000003af7:  8E 46 F6             mov   es, word ptr [bp - 0Ah]
0x0000000000003afa:  89 F3                mov   bx, si
0x0000000000003afc:  26 3B 57 10          cmp   dx, word ptr es:[bx + MOBJ_POS_T.mp_angle + 2]
0x0000000000003b00:  75 06                jne   label_123
0x0000000000003b02:  26 3B 47 0E          cmp   ax, word ptr es:[bx + MOBJ_POS_T.mp_angle + 0]
0x0000000000003b06:  74 3D                je    label_124
label_123:
0x0000000000003b08:  89 C1                mov   cx, ax
0x0000000000003b0a:  26 2B 4F 0E          sub   cx, word ptr es:[bx + MOBJ_POS_T.mp_angle + 0]
0x0000000000003b0e:  89 D3                mov   bx, dx
0x0000000000003b10:  26 1B 5C 10          sbb   bx, word ptr es:[si + MOBJ_POS_T.mp_angle + 2]
0x0000000000003b14:  81 FB 00 80          cmp   bx, 0x8000
0x0000000000003b18:  77 09                ja    label_131
0x0000000000003b1a:  74 03                je    label_132
jump_to_label_133:
0x0000000000003b1c:  E9 58 01             jmp   label_133
label_132:
0x0000000000003b1f:  85 C9                test  cx, cx
0x0000000000003b21:  76 F9                jbe   jump_to_label_133
label_131:
0x0000000000003b23:  89 F3                mov   bx, si
0x0000000000003b25:  89 C1                mov   cx, ax
0x0000000000003b27:  26 83 47 0E 00       add   word ptr es:[bx + MOBJ_POS_T.mp_angle + 0], -TRACEANGLELOW
0x0000000000003b2c:  26 81 57 10 00 F4    adc   word ptr es:[bx + MOBJ_POS_T.mp_angle + 2], -TRACEANGLEHIGH
0x0000000000003b32:  26 2B 4F 0E          sub   cx, word ptr es:[bx + MOBJ_POS_T.mp_angle + 0]
0x0000000000003b36:  89 D3                mov   bx, dx
0x0000000000003b38:  26 1B 5C 10          sbb   bx, word ptr es:[si + MOBJ_POS_T.mp_angle + 2]
0x0000000000003b3c:  81 FB 00 80          cmp   bx, 08000h
0x0000000000003b40:  73 03                jae   label_124
0x0000000000003b42:  E9 25 01             jmp   label_125
label_124:
0x0000000000003b45:  8B 5E FA             mov   bx, word ptr [bp - 6]
0x0000000000003b48:  8E 46 F6             mov   es, word ptr [bp - 0Ah]
0x0000000000003b4b:  8A 47 1A             mov   al, byte ptr ds:[bx + MOBJ_T.m_mobjtype]
0x0000000000003b4e:  30 E4                xor   ah, ah
0x0000000000003b50:  6B C0 0B             imul  ax, ax, SIZEOF_MOBJINFO_T
0x0000000000003b53:  8B 76 F8             mov   si, word ptr [bp - 8]
0x0000000000003b56:  26 8B 74 10          mov   si, word ptr es:[si + MOBJ_POS_T.mp_angle + 2]
0x0000000000003b5a:  D1 EE                shr   si, 1
0x0000000000003b5c:  83 E6 FC             and   si, 0FFFCh
0x0000000000003b5f:  89 C3                mov   bx, ax
0x0000000000003b61:  8A 87 64 C4          mov   al, byte ptr ds:[bx + (OFFSET _mobjinfo + MOBJINFO_T.mobjinfo_speed)]
0x0000000000003b65:  81 C3 64 C4          add   bx, (OFFSET _mobjinfo + MOBJINFO_T.mobjinfo_speed)
0x0000000000003b69:  98                   cbw  
0x0000000000003b6a:  89 F2                mov   dx, si
0x0000000000003b6c:  89 C3                mov   bx, ax
0x0000000000003b6e:  B8 D6 33             mov   ax, FINECOSINE_SEGMENT
0x0000000000003b71:  9A 8D 5C 88 0A       call  FixedMulTrigSpeed_
0x0000000000003b76:  8B 5E FA             mov   bx, word ptr [bp - 6]
0x0000000000003b79:  89 47 0E             mov   word ptr ds:[bx + MOBJ_T.m_momx + 0], ax
0x0000000000003b7c:  8A 47 1A             mov   al, byte ptr ds:[bx + MOBJ_T.m_mobjtype]
0x0000000000003b7f:  30 E4                xor   ah, ah
0x0000000000003b81:  6B C0 0B             imul  ax, ax, SIZEOF_MOBJINFO_T
0x0000000000003b84:  89 57 10             mov   word ptr ds:[bx + MOBJ_T.m_momx + 2], dx
0x0000000000003b87:  89 C3                mov   bx, ax
0x0000000000003b89:  8A 87 64 C4          mov   al, byte ptr ds:[bx + (OFFSET _mobjinfo + MOBJINFO_T.mobjinfo_speed)]
0x0000000000003b8d:  81 C3 64 C4          add   bx, (OFFSET _mobjinfo + MOBJINFO_T.mobjinfo_speed)
0x0000000000003b91:  98                   cbw  
0x0000000000003b92:  89 F2                mov   dx, si
0x0000000000003b94:  89 C3                mov   bx, ax
0x0000000000003b96:  B8 D6 31             mov   ax, FINESINE_SEGMENT
0x0000000000003b99:  9A 8D 5C 88 0A       call  FixedMulTrigSpeed_
0x0000000000003b9e:  8B 5E FA             mov   bx, word ptr [bp - 6]
0x0000000000003ba1:  89 47 12             mov   word ptr ds:[bx + MOBJ_T.m_momy + 0], ax
0x0000000000003ba4:  89 57 14             mov   word ptr ds:[bx + MOBJ_T.m_momy + 2], dx
0x0000000000003ba7:  6B 5F 26 18          imul  bx, word ptr ds:[bx + MOBJ_T.m_tracerRef], SIZEOF_MOBJ_POS_T
0x0000000000003bab:  B8 F5 6A             mov   ax, MOBJPOSLIST_6800_SEGMENT
0x0000000000003bae:  8B 76 F8             mov   si, word ptr [bp - 8]
0x0000000000003bb1:  8E C0                mov   es, ax
0x0000000000003bb3:  89 46 FC             mov   word ptr [bp - 4], ax
0x0000000000003bb6:  26 8B 7F 08          mov   di, word ptr es:[bx + MOBJ_POS_T.mp_z + 0]
0x0000000000003bba:  26 8B 47 0A          mov   ax, word ptr es:[bx + MOBJ_POS_T.mp_z + 2]
0x0000000000003bbe:  26 8B 4F 06          mov   cx, word ptr es:[bx + MOBJ_POS_T.mp_y + 2]
0x0000000000003bc2:  89 46 FE             mov   word ptr [bp - 2], ax
0x0000000000003bc5:  26 8B 47 04          mov   ax, word ptr es:[bx + MOBJ_POS_T.mp_y + 0]
0x0000000000003bc9:  8E 46 F6             mov   es, word ptr [bp - 0Ah]
0x0000000000003bcc:  26 2B 44 04          sub   ax, word ptr es:[si + MOBJ_POS_T.mp_y + 0]
0x0000000000003bd0:  26 1B 4C 06          sbb   cx, word ptr es:[si + MOBJ_POS_T.mp_y + 2]
0x0000000000003bd4:  8E 46 FC             mov   es, word ptr [bp - 4]
0x0000000000003bd7:  26 8B 17             mov   dx, word ptr es:[bx + MOBJ_POS_T.mp_x + 0]
0x0000000000003bda:  26 8B 77 02          mov   si, word ptr es:[bx + MOBJ_POS_T.mp_x + 2]
0x0000000000003bde:  8E 46 F6             mov   es, word ptr [bp - 0Ah]
0x0000000000003be1:  8B 5E F8             mov   bx, word ptr [bp - 8]
0x0000000000003be4:  26 2B 17             sub   dx, word ptr es:[bx + MOBJ_POS_T.mp_x + 0]
0x0000000000003be7:  26 1B 77 02          sbb   si, word ptr es:[bx + MOBJ_POS_T.mp_x + 2]
0x0000000000003beb:  89 C3                mov   bx, ax
0x0000000000003bed:  89 D0                mov   ax, dx
0x0000000000003bef:  89 F2                mov   dx, si
0x0000000000003bf1:  FF 1E D0 0C          call  dword ptr ds:[_P_AproxDistance]
0x0000000000003bf5:  8B 5E FA             mov   bx, word ptr [bp - 6]
0x0000000000003bf8:  89 D0                mov   ax, dx
0x0000000000003bfa:  8A 57 1A             mov   dl, byte ptr ds:[bx + MOBJ_T.m_mobjtype]
0x0000000000003bfd:  30 F6                xor   dh, dh
0x0000000000003bff:  6B D2 0B             imul  dx, dx, SIZEOF_MOBJINFO_T
0x0000000000003c02:  89 D3                mov   bx, dx
0x0000000000003c04:  8A 97 64 C4          mov   dl, byte ptr ds:[bx + (OFFSET _mobjinfo + MOBJINFO_T.mobjinfo_speed)]
0x0000000000003c08:  81 C3 64 C4          add   bx, (OFFSET _mobjinfo + MOBJINFO_T.mobjinfo_speed)
0x0000000000003c0c:  30 F6                xor   dh, dh
0x0000000000003c0e:  89 D3                mov   bx, dx
0x0000000000003c10:  81 EB 80 00          sub   bx, 080h
0x0000000000003c14:  99                   cwd   
0x0000000000003c15:  F7 FB                idiv  bx
0x0000000000003c17:  3D 01 00             cmp   ax, 1
0x0000000000003c1a:  7D 03                jge   label_130
0x0000000000003c1c:  B8 01 00             mov   ax, 1
label_130:
0x0000000000003c1f:  8E 46 F6             mov   es, word ptr [bp - 0Ah]
0x0000000000003c22:  89 FA                mov   dx, di
0x0000000000003c24:  8B 5E F8             mov   bx, word ptr [bp - 8]
0x0000000000003c27:  83 C2 00             add   dx, 0  ; todo remove 
0x0000000000003c2a:  8B 4E FE             mov   cx, word ptr [bp - 2]
0x0000000000003c2d:  83 D1 28             adc   cx, 40 ; 40*FRACUNIT
0x0000000000003c30:  26 2B 57 08          sub   dx, word ptr es:[bx + MOBJ_POS_T.mp_z + 0]
0x0000000000003c34:  26 1B 4F 0A          sbb   cx, word ptr es:[bx + MOBJ_POS_T.mp_z + 2]
0x0000000000003c38:  89 C3                mov   bx, ax
0x0000000000003c3a:  89 D0                mov   ax, dx
0x0000000000003c3c:  89 CA                mov   dx, cx
0x0000000000003c3e:  9A CB 5E 88 0A       call  FastDiv3216u_
0x0000000000003c43:  8B 5E FA             mov   bx, word ptr [bp - 6]
0x0000000000003c46:  3B 57 18             cmp   dx, word ptr ds:[bx + MOBJ_T.m_momz + 2]
0x0000000000003c49:  7C 07                jl    label_129
0x0000000000003c4b:  75 5F                jne   label_128
0x0000000000003c4d:  3B 47 16             cmp   ax, word ptr ds:[bx + MOBJ_T.m_momz + 0]
0x0000000000003c50:  73 5A                jae   label_128
label_129:
0x0000000000003c52:  81 47 16 00 E0       add   word ptr ds:[bx + MOBJ_T.m_momz + 0], 0E000h ; -fracunit / 8
0x0000000000003c57:  83 57 18 FF          adc   word ptr ds:[bx + MOBJ_T.m_momz + 2], 0FFFFh
0x0000000000003c5b:  C9                   LEAVE_MACRO 
0x0000000000003c5c:  5F                   pop   di
0x0000000000003c5d:  5E                   pop   si
0x0000000000003c5e:  5A                   pop   dx
0x0000000000003c5f:  C3                   ret   
label_120:
0x0000000000003c60:  3C F0                cmp   al, 240
0x0000000000003c62:  76 03                jbe   jump_to_label_121
0x0000000000003c64:  E9 44 FE             jmp   label_119
jump_to_label_121:
0x0000000000003c67:  E9 45 FE             jmp   label_121
label_125:
0x0000000000003c6a:  89 F3                mov   bx, si
0x0000000000003c6c:  26 89 47 0E          mov   word ptr es:[bx + MOBJ_POS_T.mp_angle + 0], ax
0x0000000000003c70:  26 89 57 10          mov   word ptr es:[bx + MOBJ_POS_T.mp_angle + 2], dx
0x0000000000003c74:  E9 CE FE             jmp   label_124
label_133:
0x0000000000003c77:  89 F3                mov   bx, si
0x0000000000003c79:  89 C1                mov   cx, ax
0x0000000000003c7b:  26 83 47 0E 00       add   word ptr es:[bx + MOBJ_POS_T.mp_angle + 0], TRACEANGLELOW
0x0000000000003c80:  26 81 57 10 00 0C    adc   word ptr es:[bx + MOBJ_POS_T.mp_angle + 2], TRACEANGLEHIGH
0x0000000000003c86:  26 2B 4F 0E          sub   cx, word ptr es:[bx + MOBJ_POS_T.mp_angle + 0]
0x0000000000003c8a:  89 D3                mov   bx, dx
0x0000000000003c8c:  26 1B 5C 10          sbb   bx, word ptr es:[si + MOBJ_POS_T.mp_angle + 2]
0x0000000000003c90:  81 FB 00 80          cmp   bx, 08000h
0x0000000000003c94:  77 09                ja    label_126
0x0000000000003c96:  74 03                je    label_127
jump_to_label_124:
0x0000000000003c98:  E9 AA FE             jmp   label_124
label_127:
0x0000000000003c9b:  85 C9                test  cx, cx
0x0000000000003c9d:  76 F9                jbe   jump_to_label_124
label_126:
0x0000000000003c9f:  89 F3                mov   bx, si
0x0000000000003ca1:  26 89 47 0E          mov   word ptr es:[bx + MOBJ_POS_T.mp_angle + 0], ax
0x0000000000003ca5:  26 89 57 10          mov   word ptr es:[bx + MOBJ_POS_T.mp_angle + 2], dx
0x0000000000003ca9:  E9 99 FE             jmp   label_124
label_128:
0x0000000000003cac:  81 47 16 00 20       add   word ptr ds:[bx + MOBJ_T.m_momz + 0], 02000h ; fracunit / 8
0x0000000000003cb1:  83 57 18 00          adc   word ptr ds:[bx + MOBJ_T.m_momz + 2], 0
0x0000000000003cb5:  C9                   LEAVE_MACRO 
0x0000000000003cb6:  5F                   pop   di
0x0000000000003cb7:  5E                   pop   si
0x0000000000003cb8:  5A                   pop   dx
0x0000000000003cb9:  C3                   ret   


ENDP


PROC    A_SkelWhoosh_ NEAR
PUBLIC  A_SkelWhoosh_

0x0000000000003cba:  53                   push  bx
0x0000000000003cbb:  52                   push  dx
0x0000000000003cbc:  89 C3                mov   bx, ax
0x0000000000003cbe:  83 7F 22 00          cmp   word ptr ds:[bx + MOBJ_T.m_targetRef], 0
0x0000000000003cc2:  75 03                jne   do_a_skelwhoosh
0x0000000000003cc4:  5A                   pop   dx
0x0000000000003cc5:  5B                   pop   bx
0x0000000000003cc6:  C3                   ret   
do_a_skelwhoosh:
0x0000000000003cc7:  E8 CC F7             call  A_FaceTarget_
0x0000000000003cca:  BA 38 00             mov   dx, SFX_SKESWG
0x0000000000003ccd:  89 D8                mov   ax, bx
0x0000000000003ccf:  0E                   push  cs
0x0000000000003cd0:  3E E8 7C C8          call  S_StartSound_
0x0000000000003cd4:  5A                   pop   dx
0x0000000000003cd5:  5B                   pop   bx
0x0000000000003cd6:  C3                   ret   
0x0000000000003cd7:  FC                   cld   

ENDP


PROC    A_SkelFist_ NEAR
PUBLIC  A_SkelFist_

0x0000000000003cd8:  53                   push  bx
0x0000000000003cd9:  51                   push  cx
0x0000000000003cda:  52                   push  dx
0x0000000000003cdb:  56                   push  si
0x0000000000003cdc:  89 C6                mov   si, ax
0x0000000000003cde:  83 7C 22 00          cmp   word ptr ds:[si + MOBJ_T.m_targetRef], 0
0x0000000000003ce2:  75 05                jne   do_a_skelfist
exit_a_skelfist:
0x0000000000003ce4:  5E                   pop   si
0x0000000000003ce5:  5A                   pop   dx
0x0000000000003ce6:  59                   pop   cx
0x0000000000003ce7:  5B                   pop   bx
0x0000000000003ce8:  C3                   ret   
do_a_skelfist:
0x0000000000003ce9:  E8 AA F7             call  A_FaceTarget_
0x0000000000003cec:  89 F0                mov   ax, si
0x0000000000003cee:  E8 ED EC             call  P_CheckMeleeRange_
0x0000000000003cf1:  84 C0                test  al, al
0x0000000000003cf3:  74 EF                je    exit_a_skelfist
0x0000000000003cf5:  E8 B8 4C             call  P_Random_
0x0000000000003cf8:  30 E4                xor   ah, ah
0x0000000000003cfa:  B9 0A 00             mov   cx, 10
0x0000000000003cfd:  99                   cwd   
0x0000000000003cfe:  F7 F9                idiv  cx
0x0000000000003d00:  42                   inc   dx
0x0000000000003d01:  89 D1                mov   cx, dx
0x0000000000003d03:  C1 E1 02             shl   cx, 2
0x0000000000003d06:  89 F0                mov   ax, si
0x0000000000003d08:  29 D1                sub   cx, dx
0x0000000000003d0a:  BA 35 00             mov   dx, SFX_SKEPCH
0x0000000000003d0d:  0E                   push  cs
0x0000000000003d0e:  3E E8 3E C8          call  S_StartSound_
0x0000000000003d12:  6B 44 22 2C          imul  ax, word ptr ds:[si + MOBJ_T.m_targetRef], SIZEOF_THINKER_T
0x0000000000003d16:  89 F3                mov   bx, si
0x0000000000003d18:  01 C9                add   cx, cx
0x0000000000003d1a:  89 F2                mov   dx, si
0x0000000000003d1c:  05 04 34             add   ax, (OFFSET _thinkerlist + THINKER_T.t_data)
0x0000000000003d1f:  0E                   push  cs
0x0000000000003d20:  3E E8 0C 24          call  P_DamageMobj_
0x0000000000003d24:  5E                   pop   si
0x0000000000003d25:  5A                   pop   dx
0x0000000000003d26:  59                   pop   cx
0x0000000000003d27:  5B                   pop   bx
0x0000000000003d28:  C3                   ret   
0x0000000000003d29:  FC                   cld   

ENDP


PROC    PIT_VileCheck_ NEAR
PUBLIC  PIT_VileCheck_

0x0000000000003d2a:  56                   push  si
0x0000000000003d2b:  57                   push  di
0x0000000000003d2c:  55                   push  bp
0x0000000000003d2d:  89 E5                mov   bp, sp
0x0000000000003d2f:  83 EC 06             sub   sp, 6
0x0000000000003d32:  50                   push  ax
0x0000000000003d33:  89 D6                mov   si, dx
0x0000000000003d35:  89 4E FE             mov   word ptr [bp - 2], cx
0x0000000000003d38:  C7 46 FA B2 00       mov   word ptr [bp - 6], GETRAISESTATEADDR
0x0000000000003d3d:  8E C1                mov   es, cx
0x0000000000003d3f:  C7 46 FC D9 92       mov   word ptr [bp - 4], INFOFUNCLOADSEGMENT
0x0000000000003d44:  26 F6 47 16 10       test  byte ptr es:[bx + MOBJ_POS_T.mp_flags2], MF_CORPSE
0x0000000000003d49:  74 06                je    exit_pit_vilecheck_return_1:
0x0000000000003d4b:  80 7C 1B FF          cmp   byte ptr ds:[si + MOBJ_T.m_tics], 0FFh
0x0000000000003d4f:  74 06                je    label_134
exit_pit_vilecheck_return_1:
0x0000000000003d51:  B0 01                mov   al, 1
0x0000000000003d53:  C9                   LEAVE_MACRO 
0x0000000000003d54:  5F                   pop   di
0x0000000000003d55:  5E                   pop   si
0x0000000000003d56:  C3                   ret   
label_134:
0x0000000000003d57:  8A 44 1A             mov   al, byte ptr ds:[si + MOBJ_T.m_mobjtype]
0x0000000000003d5a:  30 E4                xor   ah, ah
0x0000000000003d5c:  FF 5E FA             call  dword ptr [bp - 6]
0x0000000000003d5f:  85 C0                test  ax, ax
0x0000000000003d61:  74 EE                je    exit_pit_vilecheck_return_1
0x0000000000003d63:  8A 44 1A             mov   al, byte ptr ds:[si + MOBJ_T.m_mobjtype]
0x0000000000003d66:  30 E4                xor   ah, ah
0x0000000000003d68:  6B C0 0B             imul  ax, ax, SIZEOF_MOBJINFO_T
0x0000000000003d6b:  89 C7                mov   di, ax
0x0000000000003d6d:  81 C7 65 C4          add   di, OFFSET _mobjinfo + MOBJINFO_T.mobjinfo_radius
0x0000000000003d71:  8A 05                mov   al, byte ptr ds:[di]
0x0000000000003d73:  BF 86 C4             mov   di, OFFSET _mobjinfo + (MT_VILE * SIZEOF_MOBJINFO_T)  MOBJINFO_T.mobjinfo_radius
0x0000000000003d76:  30 E4                xor   ah, ah
0x0000000000003d78:  8A 0D                mov   cl, byte ptr ds:[di]
0x0000000000003d7a:  BF FC 00             mov   di, OFFSET _viletryx
0x0000000000003d7d:  30 ED                xor   ch, ch
0x0000000000003d7f:  8E 46 FE             mov   es, word ptr [bp - 2]
0x0000000000003d82:  01 C1                add   cx, ax
0x0000000000003d84:  26 8B 07             mov   ax, word ptr es:[bx]
0x0000000000003d87:  26 8B 57 02          mov   dx, word ptr es:[bx + 2]
0x0000000000003d8b:  2B 05                sub   ax, word ptr ds:[di]
0x0000000000003d8d:  1B 55 02             sbb   dx, word ptr ds:[di + 2]
0x0000000000003d90:  0B D2                or    dx, dx
0x0000000000003d92:  7D 07                jge   label_135
0x0000000000003d94:  F7 D8                neg   ax
0x0000000000003d96:  83 D2 00             adc   dx, 0
0x0000000000003d99:  F7 DA                neg   dx
label_135:
0x0000000000003d9b:  39 CA                cmp   dx, cx
0x0000000000003d9d:  7F B2                jg    exit_pit_vilecheck_return_1
label_137:
0x0000000000003d9f:  75 04                jne   
0x0000000000003da1:  85 C0                test  ax, ax
0x0000000000003da3:  77 AC                ja    exit_pit_vilecheck_return_1
label_137:
0x0000000000003da5:  BF 00 01             mov   di, OFFSET _viletryy
0x0000000000003da8:  26 8B 47 04          mov   ax, word ptr es:[bx + MOBJ_POS_T.mp_y + 0]
0x0000000000003dac:  26 8B 57 06          mov   dx, word ptr es:[bx + MOBJ_POS_T.mp_y + 2]
0x0000000000003db0:  2B 05                sub   ax, word ptr ds:[di]
0x0000000000003db2:  1B 55 02             sbb   dx, word ptr ds:[di + 2]
0x0000000000003db5:  0B D2                or    dx, dx
0x0000000000003db7:  7D 07                jge   label_136
0x0000000000003db9:  F7 D8                neg   ax
0x0000000000003dbb:  83 D2 00             adc   dx, 0
0x0000000000003dbe:  F7 DA                neg   dx
label_136:
0x0000000000003dc0:  39 CA                cmp   dx, cx
0x0000000000003dc2:  7F 8D                jg    exit_pit_vilecheck_return_1
0x0000000000003dc4:  75 04                jne   label_138
0x0000000000003dc6:  85 C0                test  ax, ax
0x0000000000003dc8:  77 87                ja    exit_pit_vilecheck_return_1
label_138:
0x0000000000003dca:  BF 2E 01             mov   di, OFFSET _corpsehitRef
0x0000000000003dcd:  8B 46 F8             mov   ax, word ptr [bp - 8]
0x0000000000003dd0:  89 05                mov   word ptr ds:[di], ax
0x0000000000003dd2:  C7 44 12 00 00       mov   word ptr ds:[si + MOBJ_T.m_momy + 0], 0
0x0000000000003dd7:  C7 44 14 00 00       mov   word ptr ds:[si + MOBJ_T.m_momy + 2], 0
0x0000000000003ddc:  D1 64 0A             shl   word ptr ds:[si + MOBJ_T.m_height + 0], 1
0x0000000000003ddf:  D1 54 0C             rcl   word ptr ds:[si + MOBJ_T.m_height + 2], 1
0x0000000000003de2:  D1 64 0A             shl   word ptr ds:[si + MOBJ_T.m_height + 0], 1
0x0000000000003de5:  D1 54 0C             rcl   word ptr ds:[si + MOBJ_T.m_height + 2], 1
0x0000000000003de8:  8B 44 12             mov   ax, word ptr ds:[si + MOBJ_T.m_momy + 0]
0x0000000000003deb:  8B 54 14             mov   dx, word ptr ds:[si + MOBJ_T.m_momy + 2]
0x0000000000003dee:  89 44 0E             mov   word ptr ds:[si + MOBJ_T.m_momx + 0], ax
0x0000000000003df1:  89 54 10             mov   word ptr ds:[si + MOBJ_T.m_momx + 2], dx
0x0000000000003df4:  26 FF 77 06          push  word ptr es:[bx + MOBJ_POS_T.mp_y + 2]
0x0000000000003df8:  26 8B 07             mov   ax, word ptr es:[bx]
0x0000000000003dfb:  26 8B 4F 02          mov   cx, word ptr es:[bx + 2]
0x0000000000003dff:  8B 54 04             mov   dx, word ptr ds:[si + 4]
0x0000000000003e02:  26 FF 77 04          push  word ptr es:[bx + MOBJ_POS_T.mp_y + 0]
0x0000000000003e06:  89 C3                mov   bx, ax
0x0000000000003e08:  89 F0                mov   ax, si
0x0000000000003e0a:  FF 1E E0 0C          call  dword ptr ds:[_P_CheckPosition]
0x0000000000003e0e:  D1 7C 0C             sar   word ptr ds:[si + MOBJ_T.m_height + 2], 1
0x0000000000003e11:  D1 5C 0A             rcr   word ptr ds:[si + MOBJ_T.m_height + 0], 1
0x0000000000003e14:  D1 7C 0C             sar   word ptr ds:[si + MOBJ_T.m_height + 2], 1
0x0000000000003e17:  D1 5C 0A             rcr   word ptr ds:[si + MOBJ_T.m_height + 0], 1
0x0000000000003e1a:  84 C0                test  al, al
0x0000000000003e1c:  75 03                jne   exit_pit_vilecheck_return_0
0x0000000000003e1e:  E9 30 FF             jmp   exit_pit_vilecheck_return_1
exit_pit_vilecheck_return_0:
0x0000000000003e21:  30 C0                xor   al, al
0x0000000000003e23:  C9                   LEAVE_MACRO 
0x0000000000003e24:  5F                   pop   di
0x0000000000003e25:  5E                   pop   si
0x0000000000003e26:  C3                   ret   
0x0000000000003e27:  FC                   cld   

;3e28
_some_lookup_table:

dw 03EC6h
dw 03F90h
dw 03FA8h
dw 03FAEh
dw 03FC6h
dw 03FD1h
dw 04069h
dw 04074h

ENDP

; todo remove
P_BLOCKTHINGSITERATOROFFSET = 00C00h

PROC    A_VileChase_ NEAR
PUBLIC  A_VileChase_

0x0000000000003e38:  52                   push  dx
0x0000000000003e39:  56                   push  si
0x0000000000003e3a:  57                   push  di
0x0000000000003e3b:  55                   push  bp
0x0000000000003e3c:  89 E5                mov   bp, sp
0x0000000000003e3e:  83 EC 16             sub   sp, 016h
0x0000000000003e41:  50                   push  ax
0x0000000000003e42:  53                   push  bx
0x0000000000003e43:  51                   push  cx
0x0000000000003e44:  C7 46 EE 00 0C       mov   word ptr [bp - 012h], P_BLOCKTHINGSITERATOROFFSET
0x0000000000003e49:  C7 46 F0 00 94       mov   word ptr [bp - 010h], PHYSICS_HIGHCODE_SEGMENT
0x0000000000003e4e:  C7 46 F2 3C 06       mov   word ptr [bp - 0Eh], GETSPAWNHEALTHADDR
0x0000000000003e53:  C7 46 F4 D9 92       mov   word ptr [bp - 0Ch], INFOFUNCLOADSEGMENT
0x0000000000003e58:  C7 46 EA B2 00       mov   word ptr [bp - 016h], GETRAISESTATEADDR
0x0000000000003e5d:  C7 46 EC D9 92       mov   word ptr [bp - 014h], INFOFUNCLOADSEGMENT
0x0000000000003e62:  89 C6                mov   si, ax
0x0000000000003e64:  31 DB                xor   bx, bx
0x0000000000003e66:  80 7C 1F 08          cmp   byte ptr ds:[si + MOBJ_T.m_movedir], DI_NODIR
0x0000000000003e6a:  74 57                je    jump_to_label_139
0x0000000000003e6c:  8A 44 1A             mov   al, byte ptr ds:[si + MOBJ_T.m_mobjtype]
0x0000000000003e6f:  30 E4                xor   ah, ah
0x0000000000003e71:  6B C0 0B             imul  ax, ax, SIZEOF_MOBJINFO_T
0x0000000000003e74:  89 5E F8             mov   word ptr [bp - 8], bx
0x0000000000003e77:  89 46 F6             mov   word ptr [bp - 0Ah], ax
0x0000000000003e7a:  8B 76 F6             mov   si, word ptr [bp - 0Ah]
0x0000000000003e7d:  31 C0                xor   ax, ax
0x0000000000003e7f:  8B 7E E6             mov   di, word ptr [bp - 01Ah]
0x0000000000003e82:  8A 84 64 C4          mov   al, byte ptr ds:[si + (OFFSET _mobjinfo + MOBJINFO_T.mobjinfo_speed)]
0x0000000000003e86:  81 C6 64 C4          add   si, (OFFSET _mobjinfo + MOBJINFO_T.mobjinfo_speed)
0x0000000000003e8a:  8E C1                mov   es, cx
0x0000000000003e8c:  BE FC 00             mov   si, OFFSET _viletryx
0x0000000000003e8f:  26 8B 0D             mov   cx, word ptr es:[di]
0x0000000000003e92:  26 8B 55 02          mov   dx, word ptr es:[di + 2]
0x0000000000003e96:  89 0C                mov   word ptr ds:[si], cx
0x0000000000003e98:  89 54 02             mov   word ptr ds:[si + 2], dx
0x0000000000003e9b:  BE 00 01             mov   si, OFFSET _viletryy
0x0000000000003e9e:  26 8B 55 04          mov   dx, word ptr es:[di + MOBJ_POS_T.mp_y + 0]
0x0000000000003ea2:  26 8B 4D 06          mov   cx, word ptr es:[di + MOBJ_POS_T.mp_y + 2]
0x0000000000003ea6:  89 14                mov   word ptr ds:[si], dx
0x0000000000003ea8:  89 4C 02             mov   word ptr ds:[si + 2], cx
0x0000000000003eab:  8B 76 E8             mov   si, word ptr [bp - 018h]
0x0000000000003eae:  8A 54 1F             mov   dl, byte ptr ds:[si + MOBJ_T.m_movedir]
0x0000000000003eb1:  30 FC                xor   ah, bh
0x0000000000003eb3:  80 FA 07             cmp   dl, 7
0x0000000000003eb6:  77 13                ja    label_140
0x0000000000003eb8:  30 F6                xor   dh, dh
0x0000000000003eba:  89 D6                mov   si, dx
0x0000000000003ebc:  01 D6                add   si, dx
0x0000000000003ebe:  2E FF A4 28 3E       jmp   word ptr cs:[si + OFFSET _some_lookup_table]
jump_to_label_139:
0x0000000000003ec3:  E9 B9 00             jmp   label_139
0x0000000000003ec6:  BE FE 00             mov   si, OFFSET _viletryx + 2
label_141:
0x0000000000003ec9:  01 04                add   word ptr ds:[si], ax
label_140:
0x0000000000003ecb:  BE FC 00             mov   si, OFFSET _viletryx
0x0000000000003ece:  BF E0 05             mov   di, OFFSET _bmaporgx
0x0000000000003ed1:  8B 14                mov   dx, word ptr ds:[si]
0x0000000000003ed3:  8B 3D                mov   di, word ptr ds:[di]
0x0000000000003ed5:  29 DA                sub   dx, bx
0x0000000000003ed7:  8B 44 02             mov   ax, word ptr ds:[si + 2]
0x0000000000003eda:  19 F8                sbb   ax, di
0x0000000000003edc:  83 C2 00             add   dx, 0
0x0000000000003edf:  15 C0 FF             adc   ax, -(MAXRADIUSNONFRAC * 2)
0x0000000000003ee2:  89 56 F6             mov   word ptr [bp - 0Ah], dx
0x0000000000003ee5:  89 46 F8             mov   word ptr [bp - 8], ax
0x0000000000003ee8:  8B 04                mov   ax, word ptr ds:[si]
0x0000000000003eea:  B9 07 00             mov   cx, 7
loop_shift_7_4:
0x0000000000003eed:  D1 7E F8             sar   word ptr [bp - 8], 1
0x0000000000003ef0:  D1 5E F6             rcr   word ptr [bp - 0Ah], 1
0x0000000000003ef3:  E2 F8                loop  loop_shift_7_4
0x0000000000003ef5:  29 D8                sub   ax, bx
0x0000000000003ef7:  8B 54 02             mov   dx, word ptr ds:[si + 2]
0x0000000000003efa:  19 FA                sbb   dx, di
0x0000000000003efc:  05 00 00             add   ax, 0
0x0000000000003eff:  83 D2 40             adc   dx, (MAXRADIUSNONFRAC * 2)
0x0000000000003f02:  BE 00 01             mov   si, OFFSET _viletryy
0x0000000000003f05:  B9 07 00             mov   cx, 7
loop_shift_7:
0x0000000000003f08:  D1 FA                sar   dx, 1
0x0000000000003f0a:  D1 D8                rcr   ax, 1
0x0000000000003f0c:  E2 FA                loop  loop_shift_7
0x0000000000003f0e:  BF E2 05             mov   di, OFFSET _bmaporgy
0x0000000000003f11:  8B 14                mov   dx, word ptr ds:[si]
0x0000000000003f13:  8B 3D                mov   di, word ptr ds:[di]
0x0000000000003f15:  29 DA                sub   dx, bx
0x0000000000003f17:  8B 74 02             mov   si, word ptr ds:[si + 2]
0x0000000000003f1a:  19 FE                sbb   si, di
0x0000000000003f1c:  83 C2 00             add   dx, 0
0x0000000000003f1f:  83 D6 C0             adc   si, -(MAXRADIUSNONFRAC * 2)
0x0000000000003f22:  89 76 FA             mov   word ptr [bp - 6], si
0x0000000000003f25:  89 D6                mov   si, dx
0x0000000000003f27:  8B 56 FA             mov   dx, word ptr [bp - 6]
0x0000000000003f2a:  B9 07 00             mov   cx, 7
loop_shift_7_2:
0x0000000000003f2d:  D1 FA                sar   dx, 1
0x0000000000003f2f:  D1 DE                rcr   si, 1
0x0000000000003f31:  E2 FA                loop  loop_shift_7_2
0x0000000000003f33:  89 76 FE             mov   word ptr [bp - 2], si
0x0000000000003f36:  BE 00 01             mov   si, OFFSET _viletryy
0x0000000000003f39:  8B 14                mov   dx, word ptr ds:[si]
0x0000000000003f3b:  89 46 FC             mov   word ptr [bp - 4], ax
0x0000000000003f3e:  29 DA                sub   dx, bx
0x0000000000003f40:  8B 5C 02             mov   bx, word ptr ds:[si + 2]
0x0000000000003f43:  19 FB                sbb   bx, di
0x0000000000003f45:  89 D7                mov   di, dx
0x0000000000003f47:  89 DA                mov   dx, bx
0x0000000000003f49:  83 C7 00             add   di, 0
0x0000000000003f4c:  83 D2 40             adc   dx, (MAXRADIUSNONFRAC * 2)
0x0000000000003f4f:  8B 76 F6             mov   si, word ptr [bp - 0Ah]
0x0000000000003f52:  B9 07 00             mov   cx, 7
loop_shift_7_3:
0x0000000000003f55:  D1 FA                sar   dx, 1
0x0000000000003f57:  D1 DF                rcr   di, 1
0x0000000000003f59:  E2 FA                loop  loop_shift_7_3
0x0000000000003f5b:  39 F0                cmp   ax, si
0x0000000000003f5d:  7C 20                jl    label_139
label_145:
0x0000000000003f5f:  8B 4E FE             mov   cx, word ptr [bp - 2]
0x0000000000003f62:  39 CF                cmp   di, cx
0x0000000000003f64:  7C 13                jl    label_142
label_144:
0x0000000000003f66:  BB 2A 3D             mov   bx, OFFSET PIT_VileCheck_
0x0000000000003f69:  89 CA                mov   dx, cx
0x0000000000003f6b:  89 F0                mov   ax, si
0x0000000000003f6d:  FF 5E EE             call  dword ptr [bp - 012h]
0x0000000000003f70:  84 C0                test  al, al
0x0000000000003f72:  74 75                je    label_143
0x0000000000003f74:  41                   inc   cx
0x0000000000003f75:  39 F9                cmp   cx, di
0x0000000000003f77:  7E ED                jle   label_144
label_142:
0x0000000000003f79:  46                   inc   si
0x0000000000003f7a:  3B 76 FC             cmp   si, word ptr [bp - 4]
0x0000000000003f7d:  7E E0                jle   label_145
label_139:
0x0000000000003f7f:  8B 5E E6             mov   bx, word ptr [bp - 01Ah]
0x0000000000003f82:  8B 4E E4             mov   cx, word ptr [bp - 01Ch]
0x0000000000003f85:  8B 46 E8             mov   ax, word ptr [bp - 018h]
0x0000000000003f88:  E8 25 F3             call  A_Chase_
0x0000000000003f8b:  C9                   LEAVE_MACRO 
0x0000000000003f8c:  5F                   pop   di
0x0000000000003f8d:  5E                   pop   si
0x0000000000003f8e:  5A                   pop   dx
0x0000000000003f8f:  C3                   ret   
0x0000000000003f90:  BA 98 B7             mov   dx, 47000
0x0000000000003f93:  BE FC 00             mov   si, OFFSET _viletryx
0x0000000000003f96:  F7 E2                mul   dx
0x0000000000003f98:  01 04                add   word ptr ds:[si], ax
0x0000000000003f9a:  11 54 02             adc   word ptr ds:[si + 2], dx
0x0000000000003f9d:  BE 00 01             mov   si, OFFSET _viletryy
0x0000000000003fa0:  01 04                add   word ptr ds:[si], ax
0x0000000000003fa2:  11 54 02             adc   word ptr ds:[si + 2], dx
0x0000000000003fa5:  E9 23 FF             jmp   label_140
0x0000000000003fa8:  BE 02 01             mov   si, OFFSET _viletryy + 2
0x0000000000003fab:  E9 1B FF             jmp   label_141
0x0000000000003fae:  BA 98 B7             mov   dx, 47000
0x0000000000003fb1:  BE FC 00             mov   si, OFFSET _viletryx
0x0000000000003fb4:  F7 E2                mul   dx
0x0000000000003fb6:  29 04                sub   word ptr ds:[si], ax
0x0000000000003fb8:  19 54 02             sbb   word ptr ds:[si + 2], dx
0x0000000000003fbb:  BE 00 01             mov   si, OFFSET _viletryy
0x0000000000003fbe:  01 04                add   word ptr ds:[si], ax
0x0000000000003fc0:  11 54 02             adc   word ptr ds:[si + 2], dx
0x0000000000003fc3:  E9 05 FF             jmp   label_140
0x0000000000003fc6:  BE FC 00             mov   si, OFFSET _viletryx
0x0000000000003fc9:  29 1C                sub   word ptr ds:[si], bx
0x0000000000003fcb:  19 44 02             sbb   word ptr ds:[si + 2], ax
0x0000000000003fce:  E9 FA FE             jmp   label_140
0x0000000000003fd1:  BA 98 B7             mov   dx, 47000
0x0000000000003fd4:  BE FC 00             mov   si, OFFSET _viletryx
0x0000000000003fd7:  F7 E2                mul   dx
0x0000000000003fd9:  29 04                sub   word ptr ds:[si], ax
0x0000000000003fdb:  19 54 02             sbb   word ptr ds:[si + 2], dx
0x0000000000003fde:  BE 00 01             mov   si, OFFSET _viletryy
0x0000000000003fe1:  29 04                sub   word ptr ds:[si], ax
0x0000000000003fe3:  19 54 02             sbb   word ptr ds:[si + 2], dx
0x0000000000003fe6:  E9 E2 FE             jmp   label_140
label_143:
0x0000000000003fe9:  8B 5E E8             mov   bx, word ptr [bp - 018h]
0x0000000000003fec:  8B 57 22             mov   dx, word ptr ds:[bx + MOBJ_T.m_targetRef]
0x0000000000003fef:  BB 2E 01             mov   bx, OFFSET _corpsehitRef
0x0000000000003ff2:  8B 07                mov   ax, word ptr ds:[bx]
0x0000000000003ff4:  8B 5E E8             mov   bx, word ptr [bp - 018h]
0x0000000000003ff7:  89 47 22             mov   word ptr ds:[bx + MOBJ_T.m_targetRef], ax
0x0000000000003ffa:  89 D8                mov   ax, bx
0x0000000000003ffc:  E8 97 F4             call  A_FaceTarget_
0x0000000000003fff:  89 D8                mov   ax, bx
0x0000000000004001:  89 57 22             mov   word ptr ds:[bx + MOBJ_T.m_targetRef], dx
0x0000000000004004:  BA 0A 01             mov   dx, S_VILE_HEAL1
0x0000000000004007:  BB 2E 01             mov   bx, OFFSET _corpsehitRef
0x000000000000400a:  0E                   push  cs
0x000000000000400b:  E8 E0 4F             call  P_SetMobjState_
0x000000000000400e:  90                   nop   
0x000000000000400f:  6B 37 2C             imul  si, word ptr ds:[bx], SIZEOF_THINKER_T
0x0000000000004012:  6B 1F 18             imul  bx, word ptr ds:[bx], SIZEOF_MOBJ_POS_T
0x0000000000004015:  81 C6 04 34          add   si, (OFFSET _thinkerlist + THINKER_T.t_data)
0x0000000000004019:  BA 1F 00             mov   dx, SFX_SLOP
0x000000000000401c:  89 F0                mov   ax, si
0x000000000000401e:  0E                   push  cs
0x000000000000401f:  E8 2E C5             call  S_StartSound_
0x0000000000004022:  90                   nop   
0x0000000000004023:  8A 44 1A             mov   al, byte ptr ds:[si + MOBJ_T.m_mobjtype]
0x0000000000004026:  30 E4                xor   ah, ah
0x0000000000004028:  6B F8 0B             imul  di, ax, SIZEOF_MOBJINFO_T
0x000000000000402b:  FF 5E EA             call  dword ptr [bp - 016h]
0x000000000000402e:  89 C2                mov   dx, ax
0x0000000000004030:  89 F0                mov   ax, si
0x0000000000004032:  0E                   push  cs
0x0000000000004033:  E8 B8 4F             call  P_SetMobjState_
0x0000000000004036:  90                   nop   
0x0000000000004037:  C1 64 0C 02          shl   word ptr ds:[si + MOBJ_T.m_height+2], 2
0x000000000000403b:  B9 F5 6A             mov   cx, MOBJPOSLIST_6800_SEGMENT
0x000000000000403e:  8B 85 67 C4          mov   ax, word ptr ds:[di + OFFSET _mobjinfo + MOBJINFO_T.mobjinfo_flags1]
0x0000000000004042:  8E C1                mov   es, cx
0x0000000000004044:  26 89 47 14          mov   word ptr es:[bx + MOBJ_POS_T.mp_flags1], ax
0x0000000000004048:  8B 85 69 C4          mov   ax, word ptr ds:[di + OFFSET _mobjinfo + MOBJINFO_T.mobjinfo_flags2]
0x000000000000404c:  26 89 47 16          mov   word ptr es:[bx + MOBJ_POS_T.mp_flags2], ax
0x0000000000004050:  8A 44 1A             mov   al, byte ptr ds:[si + MOBJ_T.m_mobjtype]
0x0000000000004053:  30 E4                xor   ah, ah
0x0000000000004055:  FF 5E F2             call  dword ptr [bp - 0Eh]
0x0000000000004058:  C7 44 22 00 00       mov   word ptr ds:[si + MOBJ_T.m_targetRef], 0
0x000000000000405d:  81 C7 60 C4          add   di, OFFSET _mobjinfo
0x0000000000004061:  89 44 1C             mov   word ptr ds:[si + MOBJ_T.m_health], ax
0x0000000000004064:  C9                   LEAVE_MACRO 
0x0000000000004065:  5F                   pop   di
0x0000000000004066:  5E                   pop   si
0x0000000000004067:  5A                   pop   dx
0x0000000000004068:  C3                   ret   
0x0000000000004069:  BE 00 01             mov   si, OFFSET _viletryy
0x000000000000406c:  29 1C                sub   word ptr ds:[si], bx
0x000000000000406e:  19 44 02             sbb   word ptr ds:[si + 2], ax
0x0000000000004071:  E9 57 FE             jmp   label_140
0x0000000000004074:  BA 98 B7             mov   dx, 47000
0x0000000000004077:  BE FC 00             mov   si, OFFSET _viletryx
0x000000000000407a:  F7 E2                mul   dx
0x000000000000407c:  01 04                add   word ptr ds:[si], ax
0x000000000000407e:  11 54 02             adc   word ptr ds:[si + 2], dx
0x0000000000004081:  BE 00 01             mov   si, OFFSET _viletryy
0x0000000000004084:  29 04                sub   word ptr ds:[si], ax
0x0000000000004086:  19 54 02             sbb   word ptr ds:[si + 2], dx
0x0000000000004089:  E9 3F FE             jmp   label_140

ENDP


PROC    A_VileStart_ NEAR
PUBLIC  A_VileStart_

0x000000000000408c:  52                   push  dx
0x000000000000408d:  BA 36 00             mov   dx, SFX_VILATK
0x0000000000004090:  0E                   push  cs
0x0000000000004091:  E8 BC C4             call  S_StartSound_
0x0000000000004094:  90                   nop   
0x0000000000004095:  5A                   pop   dx
0x0000000000004096:  C3                   ret   
0x0000000000004097:  FC                   cld   

ENDP


PROC    A_StartFire_ NEAR
PUBLIC  A_StartFire_

0x0000000000004098:  52                   push  dx
0x0000000000004099:  56                   push  si
0x000000000000409a:  89 C6                mov   si, ax
0x000000000000409c:  BA 5C 00             mov   dx, SFX_FLAMST
0x000000000000409f:  0E                   push  cs
0x00000000000040a0:  3E E8 AC C4          call  S_StartSound_
0x00000000000040a4:  89 F0                mov   ax, si
0x00000000000040a6:  E8 17 00             call  A_Fire_
0x00000000000040a9:  5E                   pop   si
0x00000000000040aa:  5A                   pop   dx
0x00000000000040ab:  C3                   ret   

ENDP


PROC    A_FireCrackle_ NEAR
PUBLIC  A_FireCrackle_

0x00000000000040ac:  52                   push  dx
0x00000000000040ad:  56                   push  si
0x00000000000040ae:  89 C6                mov   si, ax
0x00000000000040b0:  BA 5B 00             mov   dx, SFX_FLAME
0x00000000000040b3:  0E                   push  cs
0x00000000000040b4:  3E E8 98 C4          call  S_StartSound_
0x00000000000040b8:  89 F0                mov   ax, si
0x00000000000040ba:  E8 03 00             call  A_Fire_
0x00000000000040bd:  5E                   pop   si
0x00000000000040be:  5A                   pop   dx
0x00000000000040bf:  C3                   ret   

ENDP


PROC    A_Fire_ NEAR
PUBLIC  A_Fire_

0x00000000000040c0:  52                   push  dx
0x00000000000040c1:  56                   push  si
0x00000000000040c2:  57                   push  di
0x00000000000040c3:  55                   push  bp
0x00000000000040c4:  89 E5                mov   bp, sp
0x00000000000040c6:  83 EC 08             sub   sp, 8
0x00000000000040c9:  50                   push  ax
0x00000000000040ca:  89 DE                mov   si, bx
0x00000000000040cc:  89 4E F8             mov   word ptr [bp - 8], cx
0x00000000000040cf:  89 C7                mov   di, ax
0x00000000000040d1:  8B 7D 26             mov   di, word ptr ds:[di + MOBJ_T.m_tracerRef]
0x00000000000040d4:  85 FF                test  di, di
0x00000000000040d6:  75 05                jne   do_a_fire
exit_a_fire:
0x00000000000040d8:  C9                   LEAVE_MACRO 
0x00000000000040d9:  5F                   pop   di
0x00000000000040da:  5E                   pop   si
0x00000000000040db:  5A                   pop   dx
0x00000000000040dc:  C3                   ret   
do_a_fire:
0x00000000000040dd:  6B D7 2C             imul  dx, di, SIZEOF_THINKER_T
0x00000000000040e0:  89 C3                mov   bx, ax
0x00000000000040e2:  6B 47 22 18          imul  ax, word ptr ds:[bx + MOBJ_T.m_targetRef], SIZEOF_MOBJ_POS_T
0x00000000000040e6:  6B FF 18             imul  di, di, SIZEOF_MOBJ_POS_T
0x00000000000040e9:  89 46 FC             mov   word ptr [bp - 4], ax
0x00000000000040ec:  6B 47 22 2C          imul  ax, word ptr ds:[bx + MOBJ_T.m_targetRef], SIZEOF_THINKER_T
0x00000000000040f0:  81 C2 04 34          add   dx, (OFFSET _thinkerlist + THINKER_T.t_data)
0x00000000000040f4:  89 F9                mov   cx, di
0x00000000000040f6:  8B 5E FC             mov   bx, word ptr [bp - 4]
0x00000000000040f9:  05 04 34             add   ax, (OFFSET _thinkerlist + THINKER_T.t_data)
0x00000000000040fc:  C7 46 FE F5 6A       mov   word ptr [bp - 2], MOBJPOSLIST_6800_SEGMENT
0x0000000000004101:  FF 1E CC 0C          call  dword ptr ds:[_P_CheckSightTemp]
0x0000000000004105:  84 C0                test  al, al
0x0000000000004107:  74 CF                je    exit_a_fire
0x0000000000004109:  8E 46 FE             mov   es, word ptr [bp - 2]
0x000000000000410c:  26 8B 45 10          mov   ax, word ptr es:[di + MOBJ_POS_T.mp_angle + 2]
0x0000000000004110:  D1 E8                shr   ax, 1
0x0000000000004112:  B9 18 00             mov   cx, 24
0x0000000000004115:  24 FC                and   al, 0FCh
0x0000000000004117:  89 F2                mov   dx, si
0x0000000000004119:  89 46 FA             mov   word ptr [bp - 6], ax
0x000000000000411c:  8B 46 F6             mov   ax, word ptr [bp - 0Ah]
0x000000000000411f:  31 DB                xor   bx, bx
0x0000000000004121:  FF 1E D4 0C          call  dword ptr ds:[_P_UnsetThingPosition]
0x0000000000004125:  8B 56 FA             mov   dx, word ptr [bp - 6]
0x0000000000004128:  B8 D6 33             mov   ax, FINECOSINE_SEGMENT
0x000000000000412b:  9A 03 5C 88 0A       call  FixedMulTrigNoShift_
0x0000000000004130:  8E 46 FE             mov   es, word ptr [bp - 2]
0x0000000000004133:  B9 18 00             mov   cx, 24
0x0000000000004136:  89 46 FC             mov   word ptr [bp - 4], ax
0x0000000000004139:  89 D3                mov   bx, dx
0x000000000000413b:  26 8B 05             mov   ax, word ptr es:[di + MOBJ_POS_T.mp_x + 0]
0x000000000000413e:  26 8B 55 02          mov   dx, word ptr es:[di + MOBJ_POS_T.mp_x + 2]
0x0000000000004142:  8E 46 F8             mov   es, word ptr [bp - 8]
0x0000000000004145:  03 46 FC             add   ax, word ptr [bp - 4]
0x0000000000004148:  11 DA                adc   dx, bx
0x000000000000414a:  26 89 04             mov   word ptr es:[si + MOBJ_POS_T.mp_x + 0], ax
0x000000000000414d:  B8 D6 31             mov   ax, FINESINE_SEGMENT
0x0000000000004150:  31 DB                xor   bx, bx
0x0000000000004152:  26 89 54 02          mov   word ptr es:[si + MOBJ_POS_T.mp_x + 2], dx
0x0000000000004156:  8B 56 FA             mov   dx, word ptr [bp - 6]
0x0000000000004159:  9A 03 5C 88 0A       call  FixedMulTrigNoShift_
0x000000000000415e:  8E 46 FE             mov   es, word ptr [bp - 2]
0x0000000000004161:  89 C3                mov   bx, ax
0x0000000000004163:  89 D1                mov   cx, dx
0x0000000000004165:  26 8B 45 04          mov   ax, word ptr es:[di + MOBJ_POS_T.mp_y + 0]
0x0000000000004169:  26 8B 55 06          mov   dx, word ptr es:[di + MOBJ_POS_T.mp_y + 2]
0x000000000000416d:  8E 46 F8             mov   es, word ptr [bp - 8]
0x0000000000004170:  01 D8                add   ax, bx
0x0000000000004172:  11 CA                adc   dx, cx
0x0000000000004174:  26 89 44 04          mov   word ptr es:[si + MOBJ_POS_T.mp_y + 0], ax
0x0000000000004178:  26 89 54 06          mov   word ptr es:[si + MOBJ_POS_T.mp_y + 2], dx
0x000000000000417c:  8E 46 FE             mov   es, word ptr [bp - 2]
0x000000000000417f:  26 8B 45 08          mov   ax, word ptr es:[di + MOBJ_POS_T.mp_z + 0]
0x0000000000004183:  26 8B 55 0A          mov   dx, word ptr es:[di + MOBJ_POS_T.mp_z + 2]
0x0000000000004187:  8E 46 F8             mov   es, word ptr [bp - 8]
0x000000000000418a:  26 89 44 08          mov   word ptr es:[si + MOBJ_POS_T.mp_z + 0], ax
0x000000000000418e:  BB FF FF             mov   bx, -1
0x0000000000004191:  26 89 54 0A          mov   word ptr es:[si + MOBJ_POS_T.mp_z + 2], dx
0x0000000000004195:  8B 46 F6             mov   ax, word ptr [bp - 0Ah]
0x0000000000004198:  89 F2                mov   dx, si
0x000000000000419a:  FF 1E D8 0C          call  dword ptr ds:[_P_SetThingPosition]
0x000000000000419e:  C9                   LEAVE_MACRO 
0x000000000000419f:  5F                   pop   di
0x00000000000041a0:  5E                   pop   si
0x00000000000041a1:  5A                   pop   dx
0x00000000000041a2:  C3                   ret   
0x00000000000041a3:  FC                   cld   

ENDP


PROC    A_VileTarget_ NEAR
PUBLIC  A_VileTarget_

0x00000000000041a4:  53                   push  bx
0x00000000000041a5:  51                   push  cx
0x00000000000041a6:  52                   push  dx
0x00000000000041a7:  56                   push  si
0x00000000000041a8:  57                   push  di
0x00000000000041a9:  55                   push  bp
0x00000000000041aa:  89 E5                mov   bp, sp
0x00000000000041ac:  83 EC 02             sub   sp, 2
0x00000000000041af:  89 C6                mov   si, ax
0x00000000000041b1:  83 7C 22 00          cmp   word ptr ds:[si + MOBJ_T.m_targetRef], 0
0x00000000000041b5:  75 07                jne   do_vile_target
0x00000000000041b7:  C9                   LEAVE_MACRO 
0x00000000000041b8:  5F                   pop   di
0x00000000000041b9:  5E                   pop   si
0x00000000000041ba:  5A                   pop   dx
0x00000000000041bb:  59                   pop   cx
0x00000000000041bc:  5B                   pop   bx
0x00000000000041bd:  C3                   ret   
do_vile_target:
0x00000000000041be:  E8 D5 F2             call  A_FaceTarget_
0x00000000000041c1:  8B 44 22             mov   ax, word ptr ds:[si + MOBJ_T.m_targetRef]
0x00000000000041c4:  89 46 FE             mov   word ptr [bp - 2], ax
0x00000000000041c7:  6B F8 2C             imul  di, ax, SIZEOF_THINKER_T
0x00000000000041ca:  6B D8 18             imul  bx, ax, SIZEOF_MOBJ_POS_T
0x00000000000041cd:  B8 F5 6A             mov   ax, MOBJPOSLIST_6800_SEGMENT
0x00000000000041d0:  81 C7 04 34          add   di, (OFFSET _thinkerlist + THINKER_T.t_data)
0x00000000000041d4:  8E C0                mov   es, ax
0x00000000000041d6:  FF 75 04             push  word ptr ds:[di + MOBJ_T.m_secnum]
0x00000000000041d9:  26 8B 4F 06          mov   cx, word ptr es:[bx + MOBJ_POS_T.mp_y + 2]
0x00000000000041dd:  26 8B 07             mov   ax, word ptr es:[bx]
0x00000000000041e0:  6A 04                push  MT_FIRE ; todo 186
0x00000000000041e2:  26 8B 57 02          mov   dx, word ptr es:[bx + 2]
0x00000000000041e6:  26 FF 77 0A          push  word ptr es:[bx + MOBJ_POS_T.mp_z + 2]
0x00000000000041ea:  26 8B 7F 04          mov   di, word ptr es:[bx + MOBJ_POS_T.mp_y + 0]
0x00000000000041ee:  26 FF 77 08          push  word ptr es:[bx + MOBJ_POS_T.mp_z + 0]
0x00000000000041f2:  89 FB                mov   bx, di
0x00000000000041f4:  0E                   push  cs
0x00000000000041f5:  E8 AC 4B             call  P_SpawnMobj_
0x00000000000041f8:  90                   nop   
0x00000000000041f9:  B9 2C 00             mov   cx, SIZEOF_THINKER_T
0x00000000000041fc:  89 C3                mov   bx, ax
0x00000000000041fe:  31 D2                xor   dx, dx
0x0000000000004200:  8D 84 FC CB          lea   ax, ds:[si - (OFFSET _thinkerlist + THINKER_T.t_data)]
0x0000000000004204:  F7 F1                div   cx
0x0000000000004206:  BF BA 01             mov   di, OFFSET _setStateReturn
0x0000000000004209:  8B 3D                mov   di, word ptr ds:[di]
0x000000000000420b:  89 45 22             mov   word ptr ds:[di + MOBJ_T.m_targetRef], ax
0x000000000000420e:  8B 46 FE             mov   ax, word ptr [bp - 2]
0x0000000000004211:  89 45 26             mov   word ptr ds:[di + MOBJ_T.m_tracerRef], ax
0x0000000000004214:  89 5C 26             mov   word ptr ds:[si + MOBJ_T.m_tracerRef], bx
0x0000000000004217:  BB 34 07             mov   bx, OFFSET _setStateReturn_pos
0x000000000000421a:  8B 07                mov   ax, word ptr ds:[bx]
0x000000000000421c:  8B 4F 02             mov   cx, word ptr ds:[bx + 2]
0x000000000000421f:  89 C3                mov   bx, ax
0x0000000000004221:  89 F8                mov   ax, di
0x0000000000004223:  E8 9A FE             call  A_Fire_
0x0000000000004226:  C9                   LEAVE_MACRO 
0x0000000000004227:  5F                   pop   di
0x0000000000004228:  5E                   pop   si
0x0000000000004229:  5A                   pop   dx
0x000000000000422a:  59                   pop   cx
0x000000000000422b:  5B                   pop   bx
0x000000000000422c:  C3                   ret   
0x000000000000422d:  FC                   cld   

_vile_momz_lookuptable:

dw vilemomz_ret_2
dw vilemomz_ret_10
dw vilemomz_ret_2
dw vilemomz_ret_10
dw vilemomz_ret_10
dw vilemomz_ret_1_high
dw vilemomz_ret_10
dw vilemomz_ret_10
dw vilemomz_ret_10

dw vilemomz_ret_163840
dw vilemomz_ret_163840
dw vilemomz_ret_163840
dw vilemomz_ret_1_high
dw vilemomz_ret_10
dw vilemomz_ret_1_high
dw vilemomz_ret_20

dw vilemomz_ret_1_high
dw vilemomz_ret_109226
dw vilemomz_ret_1_high
dw vilemomz_ret_163840

dw vilemomz_ret_10
dw vilemomz_ret_1_low
dw vilemomz_ret_1_low




ENDP

PROC    GetVileMomz_ NEAR
PUBLIC  GetVileMomz_

0x000000000000425c:  53                   push  bx
0x000000000000425d:  2C 03                sub   al, 3
0x000000000000425f:  3C 16                cmp   al, MT_PAIN  ; todo this logic seems incorrect..?
0x0000000000004261:  77 35                ja    vilemomz_ret_10
0x0000000000004263:  30 E4                xor   ah, ah
0x0000000000004265:  89 C3                mov   bx, ax
0x0000000000004267:  01 C3                add   bx, ax
0x0000000000004269:  2E FF A7 2E 42       jmp   word ptr cs:[bx + OFFSET _vile_momz_lookuptable]
vilemomz_ret_2:
0x000000000000426e:  BA 02 00             mov   dx, 2
vilemomz_lowbits_0_and_return:
0x0000000000004271:  31 C0                xor   ax, ax
0x0000000000004273:  5B                   pop   bx
0x0000000000004274:  C3                   ret   
vilemomz_ret_20:
0x0000000000004275:  BA 14 00             mov   dx, 20
0x0000000000004278:  30 C0                xor   al, al
0x000000000000427a:  5B                   pop   bx
0x000000000000427b:  C3                   ret   
vilemomz_ret_163840:
0x000000000000427c:  B8 00 80             mov   ax, 08000h
0x000000000000427f:  BA 02 00             mov   dx, 2
0x0000000000004282:  5B                   pop   bx
0x0000000000004283:  C3                   ret   
vilemomz_ret_109226:
0x0000000000004284:  B8 AA AA             mov   ax, 0AAAAh
0x0000000000004287:  BA 01 00             mov   dx, 1
0x000000000000428a:  5B                   pop   bx
0x000000000000428b:  C3                   ret   
vilemomz_ret_1_high:
0x000000000000428c:  BA 01 00             mov   dx, 1
0x000000000000428f:  EB E0                jmp   vilemomz_lowbits_0_and_return
vilemomz_ret_1_low:
0x0000000000004291:  B8 01 00             mov   ax, 1
0x0000000000004294:  31 D2                xor   dx, dx
0x0000000000004296:  5B                   pop   bx
0x0000000000004297:  C3                   ret   
vilemomz_ret_10:
0x0000000000004298:  BA 0A 00             mov   dx, 10
0x000000000000429b:  31 C0                xor   ax, ax
0x000000000000429d:  5B                   pop   bx
0x000000000000429e:  C3                   ret   
0x000000000000429f:  FC                   cld   

ENDP


PROC    A_VileAttack_ NEAR
PUBLIC  A_VileAttack_

0x00000000000042a0:  52                   push  dx
0x00000000000042a1:  56                   push  si
0x00000000000042a2:  57                   push  di
0x00000000000042a3:  55                   push  bp
0x00000000000042a4:  89 E5                mov   bp, sp
0x00000000000042a6:  83 EC 10             sub   sp, 010h
0x00000000000042a9:  89 C6                mov   si, ax
0x00000000000042ab:  89 5E F6             mov   word ptr [bp - 0Ah], bx
0x00000000000042ae:  89 4E FA             mov   word ptr [bp - 6], cx
0x00000000000042b1:  8B 44 22             mov   ax, word ptr ds:[si + MOBJ_T.m_targetRef]
0x00000000000042b4:  85 C0                test  ax, ax
0x00000000000042b6:  75 05                jne   do_vile_attack
exit_vile_attack:
0x00000000000042b8:  C9                   LEAVE_MACRO 
0x00000000000042b9:  5F                   pop   di
0x00000000000042ba:  5E                   pop   si
0x00000000000042bb:  5A                   pop   dx
0x00000000000042bc:  C3                   ret   
do_vile_attack:
0x00000000000042bd:  6B D8 18             imul  bx, ax, SIZEOF_MOBJ_POS_T
0x00000000000042c0:  89 F0                mov   ax, si
0x00000000000042c2:  E8 D1 F1             call  A_FaceTarget_
0x00000000000042c5:  6B 7C 22 2C          imul  di, word ptr ds:[si + MOBJ_T.m_targetRef], SIZEOF_THINKER_T
0x00000000000042c9:  89 5E FE             mov   word ptr [bp - 2], bx
0x00000000000042cc:  89 D9                mov   cx, bx
0x00000000000042ce:  8B 5E F6             mov   bx, word ptr [bp - 0Ah]
0x00000000000042d1:  81 C7 04 34          add   di, (OFFSET _thinkerlist + THINKER_T.t_data)
0x00000000000042d5:  89 F0                mov   ax, si
0x00000000000042d7:  89 FA                mov   dx, di
0x00000000000042d9:  C7 46 FC F5 6A       mov   word ptr [bp - 4], MOBJPOSLIST_6800_SEGMENT
0x00000000000042de:  FF 1E CC 0C          call  dword ptr ds:[_P_CheckSightTemp]
0x00000000000042e2:  84 C0                test  al, al
0x00000000000042e4:  74 D2                je    exit_vile_attack
0x00000000000042e6:  BA 52 00             mov   dx, SFX_BAREXP
0x00000000000042e9:  89 F0                mov   ax, si
0x00000000000042eb:  0E                   push  cs
0x00000000000042ec:  3E E8 60 C2          call  S_StartSound_
0x00000000000042f0:  6B 44 22 2C          imul  ax, word ptr ds:[si + MOBJ_T.m_targetRef], SIZEOF_THINKER_T
0x00000000000042f4:  B9 14 00             mov   cx, 20
0x00000000000042f7:  89 F3                mov   bx, si
0x00000000000042f9:  89 F2                mov   dx, si
0x00000000000042fb:  05 04 34             add   ax, (OFFSET _thinkerlist + THINKER_T.t_data)
0x00000000000042fe:  0E                   push  cs
0x00000000000042ff:  E8 2E 1E             call  P_DamageMobj_
0x0000000000004302:  90                   nop   
0x0000000000004303:  8E 46 FA             mov   es, word ptr [bp - 6]
0x0000000000004306:  8B 5E F6             mov   bx, word ptr [bp - 0Ah]
0x0000000000004309:  26 8B 47 10          mov   ax, word ptr es:[bx + MOBJ_POS_T.mp_angle + 2]
0x000000000000430d:  D1 E8                shr   ax, 1
0x000000000000430f:  24 FC                and   al, 0FCh
0x0000000000004311:  89 46 F8             mov   word ptr [bp - 8], ax
0x0000000000004314:  8A 45 1A             mov   al, byte ptr ds:[di + MOBJ_T.m_mobjtype]
0x0000000000004317:  98                   cbw  
0x0000000000004318:  8B 5C 26             mov   bx, word ptr ds:[si + MOBJ_T.m_tracerRef]
0x000000000000431b:  E8 3E FF             call  GetVileMomz_
0x000000000000431e:  89 45 16             mov   word ptr ds:[di + MOBJ_T.m_momz + 0], ax
0x0000000000004321:  89 55 18             mov   word ptr ds:[di + MOBJ_T.m_momz + 2], dx
0x0000000000004324:  85 DB                test  bx, bx
0x0000000000004326:  74 90                je    exit_vile_attack
0x0000000000004328:  6B C3 2C             imul  ax, bx, SIZEOF_THINKER_T
0x000000000000432b:  6B FB 18             imul  di, bx, SIZEOF_MOBJ_POS_T
0x000000000000432e:  B9 18 00             mov   cx, 24
0x0000000000004331:  05 04 34             add   ax, (OFFSET _thinkerlist + THINKER_T.t_data)
0x0000000000004334:  8B 56 F8             mov   dx, word ptr [bp - 8]
0x0000000000004337:  89 46 F2             mov   word ptr [bp - 0Eh], ax
0x000000000000433a:  B8 D6 33             mov   ax, FINECOSINE_SEGMENT
0x000000000000433d:  31 DB                xor   bx, bx
0x000000000000433f:  C7 46 F4 F5 6A       mov   word ptr [bp - 0Ch], MOBJPOSLIST_6800_SEGMENT
0x0000000000004344:  9A 03 5C 88 0A       call  FixedMulTrigNoShift_
0x0000000000004349:  8E 46 FC             mov   es, word ptr [bp - 4]
0x000000000000434c:  8B 5E FE             mov   bx, word ptr [bp - 2]
0x000000000000434f:  89 46 F0             mov   word ptr [bp - 010h], ax
0x0000000000004352:  89 D1                mov   cx, dx
0x0000000000004354:  26 8B 17             mov   dx, word ptr es:[bx]
0x0000000000004357:  26 8B 47 02          mov   ax, word ptr es:[bx + 2]
0x000000000000435b:  8E 46 F4             mov   es, word ptr [bp - 0Ch]
0x000000000000435e:  2B 56 F0             sub   dx, word ptr [bp - 010h]
0x0000000000004361:  19 C8                sbb   ax, cx
0x0000000000004363:  26 89 15             mov   word ptr es:[di], dx
0x0000000000004366:  B9 18 00             mov   cx, 24
0x0000000000004369:  8B 56 F8             mov   dx, word ptr [bp - 8]
0x000000000000436c:  31 DB                xor   bx, bx
0x000000000000436e:  26 89 45 02          mov   word ptr es:[di + 2], ax
0x0000000000004372:  B8 D6 31             mov   ax, FINESINE_SEGMENT
0x0000000000004375:  9A 03 5C 88 0A       call  FixedMulTrigNoShift_
0x000000000000437a:  8E 46 FC             mov   es, word ptr [bp - 4]
0x000000000000437d:  8B 5E FE             mov   bx, word ptr [bp - 2]
0x0000000000004380:  89 C1                mov   cx, ax
0x0000000000004382:  89 56 F0             mov   word ptr [bp - 010h], dx
0x0000000000004385:  26 8B 57 04          mov   dx, word ptr es:[bx + MOBJ_POS_T.mp_y + 0]
0x0000000000004389:  26 8B 47 06          mov   ax, word ptr es:[bx + MOBJ_POS_T.mp_y + 2]
0x000000000000438d:  8E 46 F4             mov   es, word ptr [bp - 0Ch]
0x0000000000004390:  89 F3                mov   bx, si
0x0000000000004392:  29 CA                sub   dx, cx
0x0000000000004394:  B9 46 00             mov   cx, 70
0x0000000000004397:  1B 46 F0             sbb   ax, word ptr [bp - 010h]
0x000000000000439a:  26 89 55 04          mov   word ptr es:[di + MOBJ_POS_T.mp_y + 0], dx
0x000000000000439e:  89 FA                mov   dx, di
0x00000000000043a0:  26 89 45 06          mov   word ptr es:[di + MOBJ_POS_T.mp_y + 2], ax
0x00000000000043a4:  8B 46 F2             mov   ax, word ptr [bp - 0Eh]
0x00000000000043a7:  FF 1E F0 0C          call  dword ptr ds:[_P_RadiusAttack]
0x00000000000043ab:  C9                   LEAVE_MACRO 
0x00000000000043ac:  5F                   pop   di
0x00000000000043ad:  5E                   pop   si
0x00000000000043ae:  5A                   pop   dx
0x00000000000043af:  C3                   ret   

ENDP


PROC    A_FatRaise_ NEAR
PUBLIC  A_FatRaise_

0x00000000000043b0:  53                   push  bx
0x00000000000043b1:  52                   push  dx
0x00000000000043b2:  89 C3                mov   bx, ax
0x00000000000043b4:  E8 DF F0             call  A_FaceTarget_
0x00000000000043b7:  BA 63 00             mov   dx, SFX_MANATK
0x00000000000043ba:  89 D8                mov   ax, bx
0x00000000000043bc:  0E                   push  cs
0x00000000000043bd:  E8 90 C1             call  S_StartSound_
0x00000000000043c0:  90                   nop   
0x00000000000043c1:  5A                   pop   dx
0x00000000000043c2:  5B                   pop   bx
0x00000000000043c3:  C3                   ret   

ENDP


PROC    A_FatAttack1_ NEAR
PUBLIC  A_FatAttack1_

0x00000000000043c4:  52                   push  dx
0x00000000000043c5:  56                   push  si
0x00000000000043c6:  57                   push  di
0x00000000000043c7:  55                   push  bp
0x00000000000043c8:  89 E5                mov   bp, sp
0x00000000000043ca:  83 EC 02             sub   sp, 2
0x00000000000043cd:  89 C7                mov   di, ax
0x00000000000043cf:  89 DE                mov   si, bx
0x00000000000043d1:  89 4E FE             mov   word ptr [bp - 2], cx
0x00000000000043d4:  E8 BF F0             call  A_FaceTarget_
0x00000000000043d7:  8E C1                mov   es, cx
0x00000000000043d9:  26 83 44 0E 00       add   word ptr es:[si + MOBJ_POS_T.mp_angle + 0], FATSPREADLOW
0x00000000000043de:  26 81 54 10 00 08    adc   word ptr es:[si + MOBJ_POS_T.mp_angle + 2], FATSPREADHIGH
0x00000000000043e4:  6B 55 22 2C          imul  dx, word ptr ds:[di + MOBJ_T.m_targetRef], SIZEOF_THINKER_T
0x00000000000043e8:  6A 09                push  9
0x00000000000043ea:  89 F8                mov   ax, di
0x00000000000043ec:  81 C2 04 34          add   dx, (OFFSET _thinkerlist + THINKER_T.t_data)
0x00000000000043f0:  FF 1E F8 0C          call  dword ptr ds:[_SpawnMissile]
0x00000000000043f4:  6B 55 22 2C          imul  dx, word ptr ds:[di + MOBJ_T.m_targetRef], SIZEOF_THINKER_T
0x00000000000043f8:  6A 09                push  9
0x00000000000043fa:  8B 4E FE             mov   cx, word ptr [bp - 2]
0x00000000000043fd:  89 F3                mov   bx, si
0x00000000000043ff:  89 F8                mov   ax, di
0x0000000000004401:  81 C2 04 34          add   dx, (OFFSET _thinkerlist + THINKER_T.t_data)
0x0000000000004405:  FF 1E F8 0C          call  dword ptr ds:[_SpawnMissile]
0x0000000000004409:  6B F0 2C             imul  si, ax, SIZEOF_THINKER_T
0x000000000000440c:  6B F8 18             imul  di, ax, SIZEOF_MOBJ_POS_T
0x000000000000440f:  B8 F5 6A             mov   ax, MOBJPOSLIST_6800_SEGMENT
0x0000000000004412:  81 C6 04 34          add   si, (OFFSET _thinkerlist + THINKER_T.t_data)
0x0000000000004416:  8E C0                mov   es, ax
0x0000000000004418:  89 FB                mov   bx, di
0x000000000000441a:  26 83 45 0E 00       add   word ptr es:[di + MOBJ_POS_T.mp_angle + 0], FATSPREADLOW
0x000000000000441f:  26 81 57 10 00 08    adc   word ptr es:[bx + MOBJ_POS_T.mp_angle + 2], FATSPREADHIGH
0x0000000000004425:  8A 44 1A             mov   al, byte ptr ds:[si + MOBJ_T.m_mobjtype]
0x0000000000004428:  30 E4                xor   ah, ah
0x000000000000442a:  6B C0 0B             imul  ax, ax, SIZEOF_MOBJINFO_T
0x000000000000442d:  26 8B 7D 10          mov   di, word ptr es:[di + MOBJ_POS_T.mp_angle + 2]
0x0000000000004431:  D1 EF                shr   di, 1
0x0000000000004433:  83 E7 FC             and   di, 0FFFCh
0x0000000000004436:  89 C3                mov   bx, ax
0x0000000000004438:  8A 87 64 C4          mov   al, byte ptr ds:[bx + (OFFSET _mobjinfo + MOBJINFO_T.mobjinfo_speed)]
0x000000000000443c:  81 C3 64 C4          add   bx, (OFFSET _mobjinfo + MOBJINFO_T.mobjinfo_speed)
0x0000000000004440:  98                   cbw  
0x0000000000004441:  89 FA                mov   dx, di
0x0000000000004443:  89 C3                mov   bx, ax
0x0000000000004445:  B8 D6 33             mov   ax, FINECOSINE_SEGMENT
0x0000000000004448:  9A 91 5C 88 0A       call  FixedMulTrigSpeedNoShift_
0x000000000000444d:  89 44 0E             mov   word ptr ds:[si + MOBJ_T.m_momx + 0], ax
0x0000000000004450:  8A 44 1A             mov   al, byte ptr ds:[si + MOBJ_T.m_mobjtype]
0x0000000000004453:  30 E4                xor   ah, ah
0x0000000000004455:  6B C0 0B             imul  ax, ax, SIZEOF_MOBJINFO_T
0x0000000000004458:  89 54 10             mov   word ptr ds:[si + MOBJ_T.m_momx + 2], dx
0x000000000000445b:  89 C3                mov   bx, ax
0x000000000000445d:  8A 87 64 C4          mov   al, byte ptr ds:[bx + (OFFSET _mobjinfo + MOBJINFO_T.mobjinfo_speed)]
0x0000000000004461:  81 C3 64 C4          add   bx, (OFFSET _mobjinfo + MOBJINFO_T.mobjinfo_speed)
0x0000000000004465:  98                   cbw  
0x0000000000004466:  89 FA                mov   dx, di
0x0000000000004468:  89 C3                mov   bx, ax
0x000000000000446a:  B8 D6 31             mov   ax, FINESINE_SEGMENT
0x000000000000446d:  9A 91 5C 88 0A       call  FixedMulTrigSpeedNoShift_
0x0000000000004472:  89 44 12             mov   word ptr ds:[si + MOBJ_T.m_momy + 0], ax
0x0000000000004475:  89 54 14             mov   word ptr ds:[si + MOBJ_T.m_momy + 2], dx
0x0000000000004478:  C9                   LEAVE_MACRO 
0x0000000000004479:  5F                   pop   di
0x000000000000447a:  5E                   pop   si
0x000000000000447b:  5A                   pop   dx
0x000000000000447c:  C3                   ret   
0x000000000000447d:  FC                   cld   

ENDP


PROC    A_FatAttack2_ NEAR
PUBLIC  A_FatAttack2_

0x000000000000447e:  52                   push  dx
0x000000000000447f:  56                   push  si
0x0000000000004480:  57                   push  di
0x0000000000004481:  55                   push  bp
0x0000000000004482:  89 E5                mov   bp, sp
0x0000000000004484:  83 EC 02             sub   sp, 2
0x0000000000004487:  89 C7                mov   di, ax
0x0000000000004489:  89 DE                mov   si, bx
0x000000000000448b:  89 4E FE             mov   word ptr [bp - 2], cx
0x000000000000448e:  E8 05 F0             call  A_FaceTarget_
0x0000000000004491:  8E C1                mov   es, cx
0x0000000000004493:  26 83 44 0E 00       add   word ptr es:[si + MOBJ_POS_T.mp_angle + 0], -FATSPREADLOW
0x0000000000004498:  26 81 54 10 00 F8    adc   word ptr es:[si + MOBJ_POS_T.mp_angle + 2], -FATSPREADHIGH
0x000000000000449e:  6B 55 22 2C          imul  dx, word ptr ds:[di + MOBJ_T.m_targetRef], SIZEOF_THINKER_T
0x00000000000044a2:  6A 09                push  MT_FATSHOT  ; todo 186
0x00000000000044a4:  89 F8                mov   ax, di
0x00000000000044a6:  81 C2 04 34          add   dx, (OFFSET _thinkerlist + THINKER_T.t_data)
0x00000000000044aa:  FF 1E F8 0C          call  dword ptr ds:[_SpawnMissile]
0x00000000000044ae:  6B 55 22 2C          imul  dx, word ptr ds:[di + MOBJ_T.m_targetRef], SIZEOF_THINKER_T
0x00000000000044b2:  6A 09                push  MT_FATSHOT  ; todo 186
0x00000000000044b4:  8B 4E FE             mov   cx, word ptr [bp - 2]
0x00000000000044b7:  89 F3                mov   bx, si
0x00000000000044b9:  89 F8                mov   ax, di
0x00000000000044bb:  81 C2 04 34          add   dx, (OFFSET _thinkerlist + THINKER_T.t_data)
0x00000000000044bf:  BE BA 01             mov   si, OFFSET _setStateReturn
0x00000000000044c2:  FF 1E F8 0C          call  dword ptr ds:[_SpawnMissile]
0x00000000000044c6:  BB 34 07             mov   bx, OFFSET _setStateReturn_pos
0x00000000000044c9:  8B 34                mov   si, word ptr ds:[si]
0x00000000000044cb:  C4 3F                les   di, ptr ds:[bx]
0x00000000000044cd:  26 83 45 0E 00       add   word ptr es:[di + MOBJ_POS_T.mp_angle + 0], -(2*FATSPREADLOW)
0x00000000000044d2:  26 81 55 10 00 F0    adc   word ptr es:[di + MOBJ_POS_T.mp_angle + 2], -(2*FATSPREADHIGH)
0x00000000000044d8:  8A 44 1A             mov   al, byte ptr ds:[si + MOBJ_T.m_mobjtype]
0x00000000000044db:  30 E4                xor   ah, ah
0x00000000000044dd:  6B C0 0B             imul  ax, ax, SIZEOF_MOBJINFO_T
0x00000000000044e0:  26 8B 7D 10          mov   di, word ptr es:[di + MOBJ_POS_T.mp_angle + 2]
0x00000000000044e4:  D1 EF                shr   di, 1
0x00000000000044e6:  83 E7 FC             and   di, 0FFFCh
0x00000000000044e9:  89 C3                mov   bx, ax
0x00000000000044eb:  8A 87 64 C4          mov   al, byte ptr ds:[bx + (OFFSET _mobjinfo + MOBJINFO_T.mobjinfo_speed)]
0x00000000000044ef:  81 C3 64 C4          add   bx, (OFFSET _mobjinfo + MOBJINFO_T.mobjinfo_speed)
0x00000000000044f3:  98                   cbw  
0x00000000000044f4:  89 FA                mov   dx, di
0x00000000000044f6:  89 C3                mov   bx, ax
0x00000000000044f8:  B8 D6 33             mov   ax, FINECOSINE_SEGMENT
0x00000000000044fb:  9A 91 5C 88 0A       call  FixedMulTrigSpeedNoShift_
0x0000000000004500:  89 44 0E             mov   word ptr ds:[si + MOBJ_T.m_momx + 0], ax
0x0000000000004503:  8A 44 1A             mov   al, byte ptr ds:[si + MOBJ_T.m_mobjtype]
0x0000000000004506:  30 E4                xor   ah, ah
0x0000000000004508:  6B C0 0B             imul  ax, ax, SIZEOF_MOBJINFO_T
0x000000000000450b:  89 54 10             mov   word ptr ds:[si + MOBJ_T.m_momx + 2], dx
0x000000000000450e:  89 C3                mov   bx, ax
0x0000000000004510:  8A 87 64 C4          mov   al, byte ptr ds:[bx + (OFFSET _mobjinfo + MOBJINFO_T.mobjinfo_speed)]
0x0000000000004514:  81 C3 64 C4          add   bx, (OFFSET _mobjinfo + MOBJINFO_T.mobjinfo_speed)
0x0000000000004518:  98                   cbw  
0x0000000000004519:  89 FA                mov   dx, di
0x000000000000451b:  89 C3                mov   bx, ax
0x000000000000451d:  B8 D6 31             mov   ax, FINESINE_SEGMENT
0x0000000000004520:  9A 91 5C 88 0A       call  FixedMulTrigSpeedNoShift_
0x0000000000004525:  89 44 12             mov   word ptr ds:[si + MOBJ_T.m_momy + 0], ax
0x0000000000004528:  89 54 14             mov   word ptr ds:[si + MOBJ_T.m_momy + 2], dx
0x000000000000452b:  C9                   LEAVE_MACRO 
0x000000000000452c:  5F                   pop   di
0x000000000000452d:  5E                   pop   si
0x000000000000452e:  5A                   pop   dx
0x000000000000452f:  C3                   ret   

ENDP


PROC    A_FatAttack3_ NEAR
PUBLIC  A_FatAttack3_

0x0000000000004530:  52                   push  dx
0x0000000000004531:  56                   push  si
0x0000000000004532:  57                   push  di
0x0000000000004533:  55                   push  bp
0x0000000000004534:  89 E5                mov   bp, sp
0x0000000000004536:  83 EC 06             sub   sp, 6
0x0000000000004539:  50                   push  ax
0x000000000000453a:  53                   push  bx
0x000000000000453b:  51                   push  cx
0x000000000000453c:  8B 5E F8             mov   bx, word ptr [bp - 8]
0x000000000000453f:  E8 54 EF             call  A_FaceTarget_
0x0000000000004542:  8B 47 22             mov   ax, word ptr ds:[bx + MOBJ_T.m_targetRef]
0x0000000000004545:  6B C0 2C             imul  ax, ax, SIZEOF_THINKER_T
0x0000000000004548:  6A 09                push  MT_FATSHOT  ; todo 186
0x000000000000454a:  BE BA 01             mov   si, OFFSET _setStateReturn
0x000000000000454d:  05 04 34             add   ax, (OFFSET _thinkerlist + THINKER_T.t_data)
0x0000000000004550:  8B 5E F6             mov   bx, word ptr [bp - 0Ah]
0x0000000000004553:  89 46 FC             mov   word ptr [bp - 4], ax
0x0000000000004556:  89 C2                mov   dx, ax
0x0000000000004558:  8B 46 F8             mov   ax, word ptr [bp - 8]
0x000000000000455b:  BF 34 07             mov   di, OFFSET _setStateReturn_pos
0x000000000000455e:  FF 1E F8 0C          call  dword ptr ds:[_SpawnMissile]
0x0000000000004562:  8B 34                mov   si, word ptr ds:[si]
0x0000000000004564:  C4 1D                les   bx, ptr ds:[di]
0x0000000000004566:  26 83 47 0E 00       add   word ptr es:[bx + MOBJ_POS_T.mp_angle + 0], -(FATSPREADLOW/2)
0x000000000000456b:  26 81 57 10 00 FC    adc   word ptr es:[bx + MOBJ_POS_T.mp_angle + 2], -(FATSPREADHIGH/2)
0x0000000000004571:  26 8B 47 10          mov   ax, word ptr es:[bx + MOBJ_POS_T.mp_angle + 2]
0x0000000000004575:  8A 5C 1A             mov   bl, byte ptr ds:[si + MOBJ_T.m_mobjtype]
0x0000000000004578:  30 FF                xor   bh, bh
0x000000000000457a:  6B DB 0B             imul  bx, bx, SIZEOF_MOBJINFO_T
0x000000000000457d:  D1 E8                shr   ax, 1
0x000000000000457f:  24 FC                and   al, 0FCh
0x0000000000004581:  89 46 FE             mov   word ptr [bp - 2], ax
0x0000000000004584:  8B 56 FE             mov   dx, word ptr [bp - 2]
0x0000000000004587:  8A 87 64 C4          mov   al, byte ptr ds:[bx + (OFFSET _mobjinfo + MOBJINFO_T.mobjinfo_speed)]
0x000000000000458b:  98                   cbw  
0x000000000000458c:  81 C3 64 C4          add   bx, (OFFSET _mobjinfo + MOBJINFO_T.mobjinfo_speed)
0x0000000000004590:  89 46 FA             mov   word ptr [bp - 6], ax
0x0000000000004593:  89 C3                mov   bx, ax
0x0000000000004595:  B8 D6 33             mov   ax, FINECOSINE_SEGMENT
0x0000000000004598:  9A 91 5C 88 0A       call  FixedMulTrigSpeedNoShift_
0x000000000000459d:  89 44 0E             mov   word ptr ds:[si + MOBJ_T.m_momx + 0], ax
0x00000000000045a0:  8B 5E FA             mov   bx, word ptr [bp - 6]
0x00000000000045a3:  89 54 10             mov   word ptr ds:[si + MOBJ_T.m_momx + 2], dx
0x00000000000045a6:  8B 56 FE             mov   dx, word ptr [bp - 2]
0x00000000000045a9:  B8 D6 31             mov   ax, FINESINE_SEGMENT
0x00000000000045ac:  9A 91 5C 88 0A       call  FixedMulTrigSpeedNoShift_
0x00000000000045b1:  6A 09                push  9
0x00000000000045b3:  8B 5E F6             mov   bx, word ptr [bp - 0Ah]
0x00000000000045b6:  89 44 12             mov   word ptr ds:[si + MOBJ_T.m_momy + 0], ax
0x00000000000045b9:  8B 4E F4             mov   cx, word ptr [bp - 0Ch]
0x00000000000045bc:  89 54 14             mov   word ptr ds:[si + MOBJ_T.m_momy + 2], dx
0x00000000000045bf:  8B 56 FC             mov   dx, word ptr [bp - 4]
0x00000000000045c2:  8B 46 F8             mov   ax, word ptr [bp - 8]
0x00000000000045c5:  BE BA 01             mov   si, OFFSET _setStateReturn
0x00000000000045c8:  FF 1E F8 0C          call  dword ptr ds:[_SpawnMissile]
0x00000000000045cc:  8B 34                mov   si, word ptr ds:[si]
0x00000000000045ce:  C4 1D                les   bx, ptr ds:[di]
0x00000000000045d0:  26 83 47 0E 00       add   word ptr es:[bx + MOBJ_POS_T.mp_angle + 0], FATSPREADLOW/2
0x00000000000045d5:  26 81 57 10 00 04    adc   word ptr es:[bx + MOBJ_POS_T.mp_angle + 2], FATSPREADHIGH/2
0x00000000000045db:  26 8B 47 10          mov   ax, word ptr es:[bx + MOBJ_POS_T.mp_angle + 2]
0x00000000000045df:  D1 E8                shr   ax, 1
0x00000000000045e1:  24 FC                and   al, 0FCh
0x00000000000045e3:  8B 5E FA             mov   bx, word ptr [bp - 6]
0x00000000000045e6:  89 46 FE             mov   word ptr [bp - 2], ax
0x00000000000045e9:  89 C2                mov   dx, ax
0x00000000000045eb:  B8 D6 33             mov   ax, FINECOSINE_SEGMENT
0x00000000000045ee:  9A 91 5C 88 0A       call  FixedMulTrigSpeedNoShift_
0x00000000000045f3:  89 44 0E             mov   word ptr ds:[si + MOBJ_T.m_momx + 0], ax
0x00000000000045f6:  8B 5E FA             mov   bx, word ptr [bp - 6]
0x00000000000045f9:  89 54 10             mov   word ptr ds:[si + MOBJ_T.m_momx + 2], dx
0x00000000000045fc:  8B 56 FE             mov   dx, word ptr [bp - 2]
0x00000000000045ff:  B8 D6 31             mov   ax, FINESINE_SEGMENT
0x0000000000004602:  9A 91 5C 88 0A       call  FixedMulTrigSpeedNoShift_
0x0000000000004607:  89 44 12             mov   word ptr ds:[si + MOBJ_T.m_momy + 0], ax
0x000000000000460a:  89 54 14             mov   word ptr ds:[si + MOBJ_T.m_momy + 2], dx
0x000000000000460d:  C9                   LEAVE_MACRO 
0x000000000000460e:  5F                   pop   di
0x000000000000460f:  5E                   pop   si
0x0000000000004610:  5A                   pop   dx
0x0000000000004611:  C3                   ret   

ENDP


PROC    A_SkullAttack_ NEAR
PUBLIC  A_SkullAttack_

0x0000000000004612:  52                   push  dx
0x0000000000004613:  56                   push  si
0x0000000000004614:  57                   push  di
0x0000000000004615:  55                   push  bp
0x0000000000004616:  89 E5                mov   bp, sp
0x0000000000004618:  83 EC 10             sub   sp, 010h
0x000000000000461b:  89 C6                mov   si, ax
0x000000000000461d:  89 DF                mov   di, bx
0x000000000000461f:  89 4E FE             mov   word ptr [bp - 2], cx
0x0000000000004622:  C7 46 F0 B8 02       mov   word ptr [bp - 010h], GETATTACKSOUNDADDR
0x0000000000004627:  C7 46 F2 D9 92       mov   word ptr [bp - 0Eh], INFOFUNCLOADSEGMENT
0x000000000000462c:  83 7C 22 00          cmp   word ptr ds:[si + MOBJ_T.m_targetRef], 0
0x0000000000004630:  75 05                jne   MOBJ_POS_T.mp_angle + 2
0x0000000000004632:  C9                   LEAVE_MACRO 
0x0000000000004633:  5F                   pop   di
0x0000000000004634:  5E                   pop   si
0x0000000000004635:  5A                   pop   dx
0x0000000000004636:  C3                   ret   
c:
0x0000000000004637:  8E C1                mov   es, cx
0x0000000000004639:  26 80 4D 17 01       or    byte ptr es:[di + MOBJ_POS_T.mp_flags2 + 1], 1
0x000000000000463e:  8A 44 1A             mov   al, byte ptr ds:[si + MOBJ_T.m_mobjtype]
0x0000000000004641:  30 E4                xor   ah, ah
0x0000000000004643:  8B 4C 22             mov   cx, word ptr ds:[si + MOBJ_T.m_targetRef]
0x0000000000004646:  FF 5E F0             call  dword ptr [bp - 010h]
0x0000000000004649:  88 C2                mov   dl, al
0x000000000000464b:  89 F0                mov   ax, si
0x000000000000464d:  30 F6                xor   dh, dh
0x000000000000464f:  0E                   push  cs
0x0000000000004650:  3E E8 FC BE          call  S_StartSound_
0x0000000000004654:  89 F0                mov   ax, si
0x0000000000004656:  E8 3D EE             call  A_FaceTarget_
0x0000000000004659:  6B C1 2C             imul  ax, cx, SIZEOF_THINKER_T
0x000000000000465c:  6B D9 18             imul  bx, cx, SIZEOF_MOBJ_POS_T
0x000000000000465f:  05 04 34             add   ax, (OFFSET _thinkerlist + THINKER_T.t_data)
0x0000000000004662:  8E 46 FE             mov   es, word ptr [bp - 2]
0x0000000000004665:  89 46 F8             mov   word ptr [bp - 8], ax
0x0000000000004668:  26 8B 45 10          mov   ax, word ptr es:[di + MOBJ_POS_T.mp_angle + 2]
0x000000000000466c:  D1 E8                shr   ax, 1
0x000000000000466e:  24 FC                and   al, 0FCh
0x0000000000004670:  89 46 F4             mov   word ptr [bp - 0Ch], ax
0x0000000000004673:  89 C2                mov   dx, ax
0x0000000000004675:  89 5E F6             mov   word ptr [bp - 0Ah], bx
0x0000000000004678:  89 5E FA             mov   word ptr [bp - 6], bx
0x000000000000467b:  B8 D6 33             mov   ax, FINECOSINE_SEGMENT
0x000000000000467e:  BB 14 00             mov   bx, SKULLSPEED_SMALL
0x0000000000004681:  9A 91 5C 88 0A       call  FixedMulTrigSpeedNoShift_
0x0000000000004686:  89 44 0E             mov   word ptr ds:[si + MOBJ_T.m_momx + 0], ax
0x0000000000004689:  BB 14 00             mov   bx, SKULLSPEED_SMALL
0x000000000000468c:  89 54 10             mov   word ptr ds:[si + MOBJ_T.m_momx + 2], dx
0x000000000000468f:  8B 56 F4             mov   dx, word ptr [bp - 0Ch]
0x0000000000004692:  B8 D6 31             mov   ax, FINESINE_SEGMENT
0x0000000000004695:  C7 46 FC F5 6A       mov   word ptr [bp - 4], MOBJPOSLIST_6800_SEGMENT
0x000000000000469a:  9A 91 5C 88 0A       call  FixedMulTrigSpeedNoShift_
0x000000000000469f:  89 44 12             mov   word ptr ds:[si + MOBJ_T.m_momy + 0], ax
0x00000000000046a2:  8B 5E F6             mov   bx, word ptr [bp - 0Ah]
0x00000000000046a5:  89 54 14             mov   word ptr ds:[si + MOBJ_T.m_momy + 2], dx
0x00000000000046a8:  8E 46 FC             mov   es, word ptr [bp - 4]
0x00000000000046ab:  26 8B 47 04          mov   ax, word ptr es:[bx + MOBJ_POS_T.mp_y + 0]
0x00000000000046af:  26 8B 4F 06          mov   cx, word ptr es:[bx + MOBJ_POS_T.mp_y + 2]
0x00000000000046b3:  8E 46 FE             mov   es, word ptr [bp - 2]
0x00000000000046b6:  26 2B 45 04          sub   ax, word ptr es:[di + MOBJ_POS_T.mp_y + 0]
0x00000000000046ba:  26 1B 4D 06          sbb   cx, word ptr es:[di + MOBJ_POS_T.mp_y + 2]
0x00000000000046be:  8E 46 FC             mov   es, word ptr [bp - 4]
0x00000000000046c1:  26 8B 17             mov   dx, word ptr es:[bx]
0x00000000000046c4:  89 56 F6             mov   word ptr [bp - 0Ah], dx
0x00000000000046c7:  26 8B 57 02          mov   dx, word ptr es:[bx + 2]
0x00000000000046cb:  8E 46 FE             mov   es, word ptr [bp - 2]
0x00000000000046ce:  26 8B 1D             mov   bx, word ptr es:[di]
0x00000000000046d1:  29 5E F6             sub   word ptr [bp - 0Ah], bx
0x00000000000046d4:  89 C3                mov   bx, ax
0x00000000000046d6:  26 1B 55 02          sbb   dx, word ptr es:[di + 2]
0x00000000000046da:  8B 46 F6             mov   ax, word ptr [bp - 0Ah]
0x00000000000046dd:  FF 1E D0 0C          call  dword ptr ds:[_P_AproxDistance]
0x00000000000046e1:  89 D0                mov   ax, dx
0x00000000000046e3:  B9 14 00             mov   cx, SKULLSPEED_SMALL
0x00000000000046e6:  99                   cwd   
0x00000000000046e7:  F7 F9                idiv  cx
0x00000000000046e9:  89 C1                mov   cx, ax
0x00000000000046eb:  3D 01 00             cmp   ax, 1
0x00000000000046ee:  73 03                jae   label_146
0x00000000000046f0:  B9 01 00             mov   cx, 1
label_146:
0x00000000000046f3:  8B 5E F8             mov   bx, word ptr [bp - 8]
0x00000000000046f6:  8B 47 0A             mov   ax, word ptr ds:[bx + MOBJ_T.m_height+0]
0x00000000000046f9:  8B 57 0C             mov   dx, word ptr ds:[bx + MOBJ_T.m_height+2]
0x00000000000046fc:  8E 46 FC             mov   es, word ptr [bp - 4]
0x00000000000046ff:  D1 FA                sar   dx, 1
0x0000000000004701:  D1 D8                rcr   ax, 1
0x0000000000004703:  8B 5E FA             mov   bx, word ptr [bp - 6]
0x0000000000004706:  89 56 F6             mov   word ptr [bp - 0Ah], dx
0x0000000000004709:  26 03 47 08          add   ax, word ptr es:[bx + MOBJ_POS_T.mp_z + 0]
0x000000000000470d:  26 8B 57 0A          mov   dx, word ptr es:[bx + MOBJ_POS_T.mp_z + 2]
0x0000000000004711:  8E 46 FE             mov   es, word ptr [bp - 2]
0x0000000000004714:  13 56 F6             adc   dx, word ptr [bp - 0Ah]
0x0000000000004717:  89 CB                mov   bx, cx
0x0000000000004719:  26 2B 45 08          sub   ax, word ptr es:[di + MOBJ_POS_T.mp_z + 0]
0x000000000000471d:  26 1B 55 0A          sbb   dx, word ptr es:[di + MOBJ_POS_T.mp_z + 2]
0x0000000000004721:  9A CB 5E 88 0A       call  FastDiv3216u_
0x0000000000004726:  89 44 16             mov   word ptr ds:[si + MOBJ_T.m_momz + 0], ax
0x0000000000004729:  89 54 18             mov   word ptr ds:[si + MOBJ_T.m_momz + 2], dx
0x000000000000472c:  C9                   LEAVE_MACRO 
0x000000000000472d:  5F                   pop   di
0x000000000000472e:  5E                   pop   si
0x000000000000472f:  5A                   pop   dx
0x0000000000004730:  C3                   ret   
0x0000000000004731:  FC                   cld   

ENDP


PROC    A_PainShootSkull_ NEAR
PUBLIC  A_PainShootSkull_

0x0000000000004732:  52                   push  dx
0x0000000000004733:  56                   push  si
0x0000000000004734:  57                   push  di
0x0000000000004735:  55                   push  bp
0x0000000000004736:  89 E5                mov   bp, sp
0x0000000000004738:  83 EC 10             sub   sp, 010h
0x000000000000473b:  89 C7                mov   di, ax
0x000000000000473d:  89 4E F6             mov   word ptr [bp - 0Ah], cx
0x0000000000004740:  BB 02 34             mov   bx, OFFSET _thinkerlist + THINKER_T.t_next
0x0000000000004743:  8B 07                mov   ax, word ptr ds:[bx]
0x0000000000004745:  31 D2                xor   dx, dx
0x0000000000004747:  85 C0                test  ax, ax
0x0000000000004749:  74 1F                je    label_147
label_148:
0x000000000000474b:  6B D8 2C             imul  bx, ax, SIZEOF_THINKER_T
0x000000000000474e:  8B 8F 00 34          mov   cx, word ptr ds:[bx + _thinkerlist + THINKER_T.t_prevFunctype]
0x0000000000004752:  30 C9                xor   cl, cl
0x0000000000004754:  80 E5 F8             and   ch, (TF_FUNCBITS SHR 8)
0x0000000000004757:  81 F9 00 08          cmp   cx, TF_MOBJTHINKER_HIGHBITS
0x000000000000475b:  75 08                jne   label_149
; BIG BIG TODO this should (?) also have THINKER_T.t_data (4) added to it.
0x000000000000475d:  80 BF 1A 34 12       cmp   byte ptr ds:[bx + _thinkerlist + MOBJ_T.m_mobjtype], MT_SKULL
0x0000000000004762:  75 01                jne   label_149
0x0000000000004764:  42                   inc   dx
label_149:
0x0000000000004765:  83 FA 14             cmp   dx, 20
0x0000000000004768:  7E 0A                jle   label_150
label_147:
0x000000000000476a:  83 FA 14             cmp   dx, 20
0x000000000000476d:  7E 12                jle   label_151
0x000000000000476f:  C9                   LEAVE_MACRO 
0x0000000000004770:  5F                   pop   di
0x0000000000004771:  5E                   pop   si
0x0000000000004772:  5A                   pop   dx
0x0000000000004773:  C3                   ret   
label_150:
0x0000000000004774:  6B D8 2C             imul  bx, ax, SIZEOF_THINKER_T
0x0000000000004777:  8B 87 02 34          mov   ax, word ptr ds:[bx + OFFSET _thinkerlist + THINKER_T.t_next]
0x000000000000477b:  85 C0                test  ax, ax
0x000000000000477d:  75 CC                jne   label_148
0x000000000000477f:  EB E9                jmp   label_147
label_151:
0x0000000000004781:  8B 46 F6             mov   ax, word ptr [bp - 0Ah]
0x0000000000004784:  D1 E8                shr   ax, 1
0x0000000000004786:  24 FC                and   al, 0FCh
0x0000000000004788:  89 46 FA             mov   word ptr [bp - 6], ax
0x000000000000478b:  8B 45 22             mov   ax, word ptr ds:[di + MOBJ_T.m_targetRef]
0x000000000000478e:  89 46 F8             mov   word ptr [bp - 8], ax
0x0000000000004791:  8A 45 1A             mov   al, byte ptr ds:[di + MOBJ_T.m_mobjtype]
0x0000000000004794:  30 E4                xor   ah, ah
0x0000000000004796:  6B C0 0B             imul  ax, ax, SIZEOF_MOBJINFO_T
0x0000000000004799:  89 C3                mov   bx, ax
0x000000000000479b:  81 C3 65 C4          add   bx, OFFSET _mobjinfo + MOBJINFO_T.mobjinfo_radius
0x000000000000479f:  8A 07                mov   al, byte ptr ds:[bx]
0x00000000000047a1:  BB 2B C5             mov   bx, OFFSET _mobjinfo + (SIZEOF_MOBJINFO_T * MT_SKULL) + MOBJ.mobjinfo_radius ;  0C52Bh
0x00000000000047a4:  8A 17                mov   dl, byte ptr ds:[bx]
0x00000000000047a6:  30 E4                xor   ah, ah
0x00000000000047a8:  30 F6                xor   dh, dh
0x00000000000047aa:  01 C2                add   dx, ax
0x00000000000047ac:  D1 FA                sar   dx, 1
0x00000000000047ae:  89 D0                mov   ax, dx
0x00000000000047b0:  C1 E0 02             shl   ax, 2
0x00000000000047b3:  29 D0                sub   ax, dx
0x00000000000047b5:  BB 2C 00             mov   bx, SIZEOF_THINKER_T
0x00000000000047b8:  05 04 00             add   ax, 4
0x00000000000047bb:  31 D2                xor   dx, dx
0x00000000000047bd:  89 46 FC             mov   word ptr [bp - 4], ax
0x00000000000047c0:  8D 85 FC CB          lea   ax, ds:[di - (OFFSET _thinkerlist + THINKER_T.t_data)]
0x00000000000047c4:  F7 F3                div   bx
0x00000000000047c6:  6B F0 18             imul  si, ax, SIZEOF_MOBJ_POS_T
0x00000000000047c9:  8B 4E FC             mov   cx, word ptr [bp - 4]
0x00000000000047cc:  8B 56 FA             mov   dx, word ptr [bp - 6]
0x00000000000047cf:  31 DB                xor   bx, bx
0x00000000000047d1:  B8 D6 33             mov   ax, FINECOSINE_SEGMENT
0x00000000000047d4:  C7 46 F4 F5 6A       mov   word ptr [bp - 0Ch], MOBJPOSLIST_6800_SEGMENT
0x00000000000047d9:  9A 03 5C 88 0A       call  FixedMulTrigNoShift_
0x00000000000047de:  8E 46 F4             mov   es, word ptr [bp - 0Ch]
0x00000000000047e1:  26 8B 1C             mov   bx, word ptr es:[si]
0x00000000000047e4:  01 C3                add   bx, ax
0x00000000000047e6:  89 5E F2             mov   word ptr [bp - 0Eh], bx
0x00000000000047e9:  89 F3                mov   bx, si
0x00000000000047eb:  8B 4E FC             mov   cx, word ptr [bp - 4]
0x00000000000047ee:  26 8B 47 02          mov   ax, word ptr es:[bx + 2]
0x00000000000047f2:  11 D0                adc   ax, dx
0x00000000000047f4:  8B 56 FA             mov   dx, word ptr [bp - 6]
0x00000000000047f7:  89 46 F0             mov   word ptr [bp - 010h], ax
0x00000000000047fa:  31 F3                xor   bx, si
0x00000000000047fc:  B8 D6 31             mov   ax, FINESINE_SEGMENT
0x00000000000047ff:  9A 03 5C 88 0A       call  FixedMulTrigNoShift_
0x0000000000004804:  8E 46 F4             mov   es, word ptr [bp - 0Ch]
0x0000000000004807:  6A FF                push  -1  ; todo 186
0x0000000000004809:  89 D1                mov   cx, dx
0x000000000000480b:  89 F3                mov   bx, si
0x000000000000480d:  26 8B 54 04          mov   dx, word ptr es:[si + MOBJ_POS_T.mp_y + 0]
0x0000000000004811:  6A 12                push  MT_SKULL  ; todo 186
0x0000000000004813:  01 C2                add   dx, ax
0x0000000000004815:  26 8B 44 0A          mov   ax, word ptr es:[si + MOBJ_POS_T.mp_z + 2]
0x0000000000004819:  26 13 4F 06          adc   cx, word ptr es:[bx + MOBJ_POS_T.mp_y + 2]
0x000000000000481d:  05 08 00             add   ax, 8
0x0000000000004820:  26 8B 5C 08          mov   bx, word ptr es:[si + MOBJ_POS_T.mp_z + 0]
0x0000000000004824:  50                   push  ax
0x0000000000004825:  8B 46 F2             mov   ax, word ptr [bp - 0Eh]
0x0000000000004828:  53                   push  bx
0x0000000000004829:  89 D3                mov   bx, dx
0x000000000000482b:  8B 56 F0             mov   dx, word ptr [bp - 010h]
0x000000000000482e:  0E                   push  cs
0x000000000000482f:  E8 72 45             call  P_SpawnMobj_
0x0000000000004832:  90                   nop   
0x0000000000004833:  BB BA 01             mov   bx, OFFSET _setStateReturn
0x0000000000004836:  8B 1F                mov   bx, word ptr ds:[bx]
0x0000000000004838:  89 5E FE             mov   word ptr [bp - 2], bx
0x000000000000483b:  BB 34 07             mov   bx, OFFSET _setStateReturn_pos
0x000000000000483e:  8B 57 02             mov   dx, word ptr ds:[bx + 2]
0x0000000000004841:  8B 37                mov   si, word ptr ds:[bx]
0x0000000000004843:  8E C2                mov   es, dx
0x0000000000004845:  26 FF 74 06          push  word ptr es:[si + MOBJ_POS_T.mp_y + 2]
0x0000000000004849:  8B 46 FE             mov   ax, word ptr [bp - 2]
0x000000000000484c:  26 FF 74 04          push  word ptr es:[si + MOBJ_POS_T.mp_y + 0]
0x0000000000004850:  89 F3                mov   bx, si
0x0000000000004852:  26 FF 74 02          push  word ptr es:[si + 2]
0x0000000000004856:  89 D1                mov   cx, dx
0x0000000000004858:  26 FF 34             push  word ptr es:[si]
0x000000000000485b:  FF 1E DC 0C          call  dword ptr ds:[_P_TryMove]
0x000000000000485f:  84 C0                test  al, al
0x0000000000004861:  75 14                jne   label_152
0x0000000000004863:  B9 10 27             mov   cx, 10000
0x0000000000004866:  8B 46 FE             mov   ax, word ptr [bp - 2]
0x0000000000004869:  89 FB                mov   bx, di
0x000000000000486b:  89 FA                mov   dx, di
0x000000000000486d:  0E                   push  cs
0x000000000000486e:  3E E8 BE 18          call  P_DamageMobj_
0x0000000000004872:  C9                   LEAVE_MACRO 
0x0000000000004873:  5F                   pop   di
0x0000000000004874:  5E                   pop   si
0x0000000000004875:  5A                   pop   dx
0x0000000000004876:  C3                   ret   
label_152:
0x0000000000004877:  8B 46 F8             mov   ax, word ptr [bp - 8]
0x000000000000487a:  8B 5E FE             mov   bx, word ptr [bp - 2]
0x000000000000487d:  89 D1                mov   cx, dx
0x000000000000487f:  89 47 22             mov   word ptr ds:[bx + MOBJ_T.m_targetRef], ax
0x0000000000004882:  8B 46 FE             mov   ax, word ptr [bp - 2]
0x0000000000004885:  89 F3                mov   bx, si
0x0000000000004887:  E8 88 FD             call  A_SkullAttack_
0x000000000000488a:  C9                   LEAVE_MACRO 
0x000000000000488b:  5F                   pop   di
0x000000000000488c:  5E                   pop   si
0x000000000000488d:  5A                   pop   dx
0x000000000000488e:  C3                   ret   
0x000000000000488f:  FC                   cld   

ENDP

PROC    A_PainAttack_ NEAR
PUBLIC  A_PainAttack_

0x0000000000004890:  56                   push  si
0x0000000000004891:  89 C6                mov   si, ax
0x0000000000004893:  83 7C 22 00          cmp   word ptr ds:[si + MOBJ_T.m_targetRef], 0
0x0000000000004897:  75 02                jne   0x489b
0x0000000000004899:  5E                   pop   si
0x000000000000489a:  C3                   ret   
0x000000000000489b:  E8 F8 EB             call  A_FaceTarget_
0x000000000000489e:  8E C1                mov   es, cx
0x00000000000048a0:  26 8B 47 0E          mov   ax, word ptr es:[bx + MOBJ_POS_T.mp_angle + 0]
0x00000000000048a4:  26 8B 4F 10          mov   cx, word ptr es:[bx + MOBJ_POS_T.mp_angle + 2]
0x00000000000048a8:  89 C3                mov   bx, ax
0x00000000000048aa:  89 F0                mov   ax, si
0x00000000000048ac:  E8 83 FE             call  A_PainShootSkull_
0x00000000000048af:  5E                   pop   si
0x00000000000048b0:  C3                   ret   
0x00000000000048b1:  FC                   cld   

ENDP


PROC    A_PainDie_ NEAR
PUBLIC  A_PainDie_

0x00000000000048b2:  52                   push  dx
0x00000000000048b3:  56                   push  si
0x00000000000048b4:  57                   push  di
0x00000000000048b5:  89 C6                mov   si, ax
0x00000000000048b7:  8E C1                mov   es, cx
0x00000000000048b9:  26 8B 7F 0E          mov   di, word ptr es:[bx + MOBJ_POS_T.mp_angle + 0]
0x00000000000048bd:  26 8B 57 10          mov   dx, word ptr es:[bx + MOBJ_POS_T.mp_angle + 2]
0x00000000000048c1:  26 80 67 14 FD       and   byte ptr es:[bx + MOBJ_POS_T.mp_flags1],  (NOT MF_SOLID)
0x00000000000048c6:  80 C6 40             add   dh, 0x40
0x00000000000048c9:  89 FB                mov   bx, di
0x00000000000048cb:  89 D1                mov   cx, dx
0x00000000000048cd:  E8 62 FE             call  A_PainShootSkull_
0x00000000000048d0:  80 C6 40             add   dh, 0x40
0x00000000000048d3:  89 FB                mov   bx, di
0x00000000000048d5:  89 F0                mov   ax, si
0x00000000000048d7:  89 D1                mov   cx, dx
0x00000000000048d9:  E8 56 FE             call  A_PainShootSkull_
0x00000000000048dc:  80 C6 40             add   dh, 0x40
0x00000000000048df:  89 FB                mov   bx, di
0x00000000000048e1:  89 F0                mov   ax, si
0x00000000000048e3:  89 D1                mov   cx, dx
0x00000000000048e5:  E8 4A FE             call  A_PainShootSkull_
0x00000000000048e8:  5F                   pop   di
0x00000000000048e9:  5E                   pop   si
0x00000000000048ea:  5A                   pop   dx
0x00000000000048eb:  C3                   ret   

ENDP


PROC    A_Scream_ NEAR
PUBLIC  A_Scream_

0x00000000000048ec:  53                   push  bx
0x00000000000048ed:  52                   push  dx
0x00000000000048ee:  56                   push  si
0x00000000000048ef:  89 C3                mov   bx, ax
0x00000000000048f1:  8A 47 1A             mov   al, byte ptr ds:[bx + MOBJ_T.m_mobjtype]
0x00000000000048f4:  30 E4                xor   ah, ah
0x00000000000048f6:  6B C0 0B             imul  ax, ax, SIZEOF_MOBJINFO_T
0x00000000000048f9:  89 C6                mov   si, ax
0x00000000000048fb:  8A 84 63 C4          mov   al, byte ptr ds:[si + OFFSET _mobjinfo + MOBJINFO_T.mobjinfo_deathsound]
0x00000000000048ff:  81 C6 63 C4          add   si, OFFSET _mobjinfo + MOBJINFO_T.mobjinfo_deathsound
0x0000000000004903:  3C 3B                cmp   al, SFX_PODTH1
0x0000000000004905:  73 31                jae   0x4938
0x0000000000004907:  84 C0                test  al, al
0x0000000000004909:  74 29                je    0x4934
0x000000000000490b:  8A 47 1A             mov   al, byte ptr ds:[bx + MOBJ_T.m_mobjtype]
0x000000000000490e:  30 E4                xor   ah, ah
0x0000000000004910:  6B C0 0B             imul  ax, ax, SIZEOF_MOBJINFO_T
0x0000000000004913:  89 C6                mov   si, ax
0x0000000000004915:  8A 84 63 C4          mov   al, byte ptr ds:[si + OFFSET _mobjinfo + MOBJINFO_T.mobjinfo_deathsound]
0x0000000000004919:  81 C6 63 C4          add   si, OFFSET _mobjinfo + MOBJINFO_T.mobjinfo_deathsound
0x000000000000491d:  80 7F 1A 13          cmp   byte ptr ds:[bx + MOBJ_T.m_mobjtype], 0x13
0x0000000000004921:  74 06                je    0x4929
0x0000000000004923:  80 7F 1A 15          cmp   byte ptr ds:[bx + MOBJ_T.m_mobjtype], 0x15
0x0000000000004927:  75 47                jne   0x4970
0x0000000000004929:  88 C2                mov   dl, al
0x000000000000492b:  30 F6                xor   dh, dh
0x000000000000492d:  31 C0                xor   ax, ax
0x000000000000492f:  0E                   push  cs
0x0000000000004930:  3E E8 1C BC          call  S_StartSound_
0x0000000000004934:  5E                   pop   si
0x0000000000004935:  5A                   pop   dx
0x0000000000004936:  5B                   pop   bx
0x0000000000004937:  C3                   ret   
0x0000000000004938:  3C 3D                cmp   al, SFX_PDTH3
0x000000000000493a:  76 22                jbe   0x495e
0x000000000000493c:  3C 3F                cmp   al, SFX_BGDTH2
0x000000000000493e:  77 CB                ja    0x490b
0x0000000000004940:  E8 6D 40             call  P_Random_
0x0000000000004943:  88 C2                mov   dl, al
0x0000000000004945:  30 F6                xor   dh, dh
0x0000000000004947:  89 D0                mov   ax, dx
0x0000000000004949:  C1 F8 0F             sar   ax, 0xf
0x000000000000494c:  31 C2                xor   dx, ax
0x000000000000494e:  29 C2                sub   dx, ax
0x0000000000004950:  83 E2 01             and   dx, 1
0x0000000000004953:  31 C2                xor   dx, ax
0x0000000000004955:  29 C2                sub   dx, ax
0x0000000000004957:  89 D0                mov   ax, dx
0x0000000000004959:  05 3E 00             add   ax, SFX_BGDTH1
0x000000000000495c:  EB BF                jmp   0x491d
0x000000000000495e:  E8 4F 40             call  P_Random_
0x0000000000004961:  30 E4                xor   ah, ah
0x0000000000004963:  BE 03 00             mov   si, 3
0x0000000000004966:  99                   cwd   
0x0000000000004967:  F7 FE                idiv  si
0x0000000000004969:  89 D0                mov   ax, dx
0x000000000000496b:  05 3B 00             add   ax, SFX_PODTH1
0x000000000000496e:  EB AD                jmp   0x491d
0x0000000000004970:  88 C2                mov   dl, al
0x0000000000004972:  89 D8                mov   ax, bx
0x0000000000004974:  30 F6                xor   dh, dh
0x0000000000004976:  0E                   push  cs
0x0000000000004977:  E8 D6 BB             call  S_StartSound_
0x000000000000497a:  90                   nop   
0x000000000000497b:  5E                   pop   si
0x000000000000497c:  5A                   pop   dx
0x000000000000497d:  5B                   pop   bx
0x000000000000497e:  C3                   ret   
0x000000000000497f:  FC                   cld   

ENDP


PROC    A_XScream_ NEAR
PUBLIC  A_XScream_

0x0000000000004980:  52                   push  dx
0x0000000000004981:  BA 1F 00             mov   dx, SFX_SLOP
0x0000000000004984:  0E                   push  cs
0x0000000000004985:  E8 C8 BB             call  S_StartSound_
0x0000000000004988:  90                   nop   
0x0000000000004989:  5A                   pop   dx
0x000000000000498a:  C3                   ret   
0x000000000000498b:  FC                   cld   

ENDP


PROC    A_Pain_ NEAR
PUBLIC  A_Pain_

0x000000000000498c:  53                   push  bx
0x000000000000498d:  52                   push  dx
0x000000000000498e:  55                   push  bp
0x000000000000498f:  89 E5                mov   bp, sp
0x0000000000004991:  83 EC 04             sub   sp, 4
0x0000000000004994:  89 C3                mov   bx, ax
0x0000000000004996:  C7 46 FC 84 02       mov   word ptr [bp - 4], GETPAINSOUNDADDR
0x000000000000499b:  8A 47 1A             mov   al, byte ptr ds:[bx + MOBJ_T.m_mobjtype]
0x000000000000499e:  C7 46 FE D9 92       mov   word ptr [bp - 2], INFOFUNCLOADSEGMENT
0x00000000000049a3:  30 E4                xor   ah, ah
0x00000000000049a5:  FF 5E FC             call  dword ptr [bp - 4]
0x00000000000049a8:  30 E4                xor   ah, ah
0x00000000000049aa:  89 C2                mov   dx, ax
0x00000000000049ac:  89 D8                mov   ax, bx
0x00000000000049ae:  0E                   push  cs
0x00000000000049af:  E8 9E BB             call  S_StartSound_
0x00000000000049b2:  90                   nop   
0x00000000000049b3:  C9                   LEAVE_MACRO 
0x00000000000049b4:  5A                   pop   dx
0x00000000000049b5:  5B                   pop   bx
0x00000000000049b6:  C3                   ret   
0x00000000000049b7:  FC                   cld   

ENDP


PROC    A_Fall_ NEAR
PUBLIC  A_Fall_

0x00000000000049b8:  8E C1                mov   es, cx
0x00000000000049ba:  26 80 67 14 FD       and   byte ptr es:[bx + MOBJ_POS_T.mp_flags1], (NOT MF_SOLID)
0x00000000000049bf:  C3                   ret   

ENDP


PROC    A_Explode_ NEAR
PUBLIC  A_Explode_

0x00000000000049c0:  52                   push  dx
0x00000000000049c1:  56                   push  si
0x00000000000049c2:  89 C6                mov   si, ax
0x00000000000049c4:  89 DA                mov   dx, bx
0x00000000000049c6:  6B 5C 22 2C          imul  bx, word ptr ds:[si + MOBJ_T.m_targetRef], SIZEOF_THINKER_T
0x00000000000049ca:  B9 80 00             mov   cx, 128
0x00000000000049cd:  81 C3 04 34          add   bx, (OFFSET _thinkerlist + THINKER_T.t_data)
0x00000000000049d1:  FF 1E F0 0C          call  dword ptr ds:[_P_RadiusAttack]
0x00000000000049d5:  5E                   pop   si
0x00000000000049d6:  5A                   pop   dx
0x00000000000049d7:  C3                   ret   

_some_lookup_table_4:

dw 04AA8h
dw 04ABBh
dw 04AC9h
dw 04AD7h


ENDP


PROC    A_BossDeath_ NEAR
PUBLIC  A_BossDeath_

0x00000000000049e0:  53                   push  bx
0x00000000000049e1:  51                   push  cx
0x00000000000049e2:  52                   push  dx
0x00000000000049e3:  56                   push  si
0x00000000000049e4:  89 C3                mov   bx, ax
0x00000000000049e6:  BE EB 02             mov   si, OFFSET _commercial
0x00000000000049e9:  8A 4F 1A             mov   cl, byte ptr ds:[bx + MOBJ_T.m_mobjtype]
0x00000000000049ec:  80 3C 00             cmp   byte ptr ds:[si], 0
0x00000000000049ef:  75 03                jne   0x49f4
0x00000000000049f1:  E9 7B 00             jmp   0x4a6f
0x00000000000049f4:  BE BF 03             mov   si, OFFSET _gamemap
0x00000000000049f7:  80 3C 07             cmp   byte ptr ds:[si], 7
0x00000000000049fa:  74 03                je    0x49ff
0x00000000000049fc:  E9 6B 00             jmp   0x4a6a
0x00000000000049ff:  80 F9 08             cmp   cl, 8
0x0000000000004a02:  74 05                je    0x4a09
0x0000000000004a04:  80 F9 14             cmp   cl, 0x14
0x0000000000004a07:  75 61                jne   0x4a6a
0x0000000000004a09:  BE E8 07             mov   si, OFFSET _player + PLAYER_T.player_health
0x0000000000004a0c:  83 3C 00             cmp   word ptr ds:[si], 0
0x0000000000004a0f:  7E 59                jle   0x4a6a
0x0000000000004a11:  8D 87 FC CB          lea   ax, ds:[bx - (OFFSET _thinkerlist + THINKER_T.t_data)]
0x0000000000004a15:  31 D2                xor   dx, dx
0x0000000000004a17:  BB 2C 00             mov   bx, SIZEOF_THINKER_T
0x0000000000004a1a:  F7 F3                div   bx
0x0000000000004a1c:  BB 02 34             mov   bx, OFFSET _thinkerlist + THINKER_T.t_next
0x0000000000004a1f:  89 C6                mov   si, ax
0x0000000000004a21:  8B 07                mov   ax, word ptr ds:[bx]
0x0000000000004a23:  85 C0                test  ax, ax
0x0000000000004a25:  74 1D                je    0x4a44
0x0000000000004a27:  6B D8 2C             imul  bx, ax, SIZEOF_THINKER_T
0x0000000000004a2a:  8B 97 00 34          mov   dx, word ptr ds:[bx + _thinkerlist + THINKER_T.t_prevFunctype]
0x0000000000004a2e:  30 D2                xor   dl, dl
0x0000000000004a30:  80 E6 F8             and   dh, (TF_FUNCBITS SHR 8)
0x0000000000004a33:  81 FA 00 08          cmp   dx, TF_MOBJTHINKER_HIGHBITS
0x0000000000004a37:  74 54                je    0x4a8d
0x0000000000004a39:  6B D8 2C             imul  bx, ax, SIZEOF_THINKER_T
0x0000000000004a3c:  8B 87 02 34          mov   ax, word ptr ds:[bx + OFFSET _thinkerlist + THINKER_T.t_next]
0x0000000000004a40:  85 C0                test  ax, ax
0x0000000000004a42:  75 E3                jne   0x4a27
0x0000000000004a44:  BB EB 02             mov   bx, OFFSET _commercial
0x0000000000004a47:  80 3F 00             cmp   byte ptr ds:[bx], 0
0x0000000000004a4a:  74 59                je    0x4aa5
0x0000000000004a4c:  BB BF 03             mov   bx, OFFSET _gamemap
0x0000000000004a4f:  80 3F 07             cmp   byte ptr ds:[bx], 7
0x0000000000004a52:  75 62                jne   0x4ab6
0x0000000000004a54:  80 F9 08             cmp   cl, 8
0x0000000000004a57:  74 60                je    0x4ab9
0x0000000000004a59:  80 F9 14             cmp   cl, 0x14
0x0000000000004a5c:  75 58                jne   0x4ab6
0x0000000000004a5e:  BB 05 00             mov   bx, 5
0x0000000000004a61:  BA FF FF             mov   dx, 0xffff
0x0000000000004a64:  B8 3E 00             mov   ax, 0x3e
0x0000000000004a67:  E8 28 08             call  EV_DoFloor_
0x0000000000004a6a:  5E                   pop   si
0x0000000000004a6b:  5A                   pop   dx
0x0000000000004a6c:  59                   pop   cx
0x0000000000004a6d:  5B                   pop   bx
0x0000000000004a6e:  C3                   ret   
0x0000000000004a6f:  BE E5 00             mov   si, 0xe5
0x0000000000004a72:  80 3C 00             cmp   byte ptr ds:[si], 0
0x0000000000004a75:  75 18                jne   0x4a8f
0x0000000000004a77:  BE BF 03             mov   si, OFFSET _gamemap
0x0000000000004a7a:  80 3C 08             cmp   byte ptr ds:[si], 8
0x0000000000004a7d:  75 EB                jne   0x4a6a
0x0000000000004a7f:  80 F9 0F             cmp   cl, 0xf
0x0000000000004a82:  75 85                jne   0x4a09
0x0000000000004a84:  BE BE 03             mov   si, 0x3be
0x0000000000004a87:  80 3C 01             cmp   byte ptr ds:[si], 1
0x0000000000004a8a:  E9 7A FF             jmp   0x4a07
0x0000000000004a8d:  EB 6A                jmp   0x4af9
0x0000000000004a8f:  BE BE 03             mov   si, 0x3be
0x0000000000004a92:  8A 04                mov   al, byte ptr ds:[si]
0x0000000000004a94:  FE C8                dec   al
0x0000000000004a96:  3C 03                cmp   al, 3
0x0000000000004a98:  77 56                ja    0x4af0
0x0000000000004a9a:  30 E4                xor   ah, ah
0x0000000000004a9c:  89 C6                mov   si, ax
0x0000000000004a9e:  01 C6                add   si, ax
0x0000000000004aa0:  2E FF A4 D8 49       jmp   word ptr cs:[si + _some_lookup_table_4]
0x0000000000004aa5:  E9 7E 00             jmp   0x4b26
0x0000000000004aa8:  BE BF 03             mov   si, OFFSET _gamemap
0x0000000000004aab:  80 3C 08             cmp   byte ptr ds:[si], 8
0x0000000000004aae:  75 BA                jne   0x4a6a
0x0000000000004ab0:  80 F9 0F             cmp   cl, 0xf
0x0000000000004ab3:  E9 51 FF             jmp   0x4a07
0x0000000000004ab6:  E9 A8 00             jmp   0x4b61
0x0000000000004ab9:  EB 5A                jmp   0x4b15
0x0000000000004abb:  BE BF 03             mov   si, OFFSET _gamemap
0x0000000000004abe:  80 3C 08             cmp   byte ptr ds:[si], 8
0x0000000000004ac1:  75 A7                jne   0x4a6a
0x0000000000004ac3:  80 F9 15             cmp   cl, 0x15
0x0000000000004ac6:  E9 3E FF             jmp   0x4a07
0x0000000000004ac9:  BE BF 03             mov   si, OFFSET _gamemap
0x0000000000004acc:  80 3C 08             cmp   byte ptr ds:[si], 8
0x0000000000004acf:  75 99                jne   0x4a6a
0x0000000000004ad1:  80 F9 13             cmp   cl, 0x13
0x0000000000004ad4:  E9 30 FF             jmp   0x4a07
0x0000000000004ad7:  BE BF 03             mov   si, OFFSET _gamemap
0x0000000000004ada:  8A 04                mov   al, byte ptr ds:[si]
0x0000000000004adc:  3C 08                cmp   al, 8
0x0000000000004ade:  75 06                jne   0x4ae6
0x0000000000004ae0:  80 F9 13             cmp   cl, 0x13
0x0000000000004ae3:  E9 21 FF             jmp   0x4a07
0x0000000000004ae6:  3C 06                cmp   al, 6
0x0000000000004ae8:  75 80                jne   0x4a6a
0x0000000000004aea:  80 F9 15             cmp   cl, 0x15
0x0000000000004aed:  E9 17 FF             jmp   0x4a07
0x0000000000004af0:  BE BF 03             mov   si, OFFSET _gamemap
0x0000000000004af3:  80 3C 08             cmp   byte ptr ds:[si], 8
0x0000000000004af6:  E9 0E FF             jmp   0x4a07
0x0000000000004af9:  81 C3 04 34          add   bx, (OFFSET _thinkerlist + THINKER_T.t_data)
0x0000000000004afd:  39 F0                cmp   ax, si
0x0000000000004aff:  75 03                jne   0x4b04
0x0000000000004b01:  E9 35 FF             jmp   0x4a39
0x0000000000004b04:  3A 4F 1A             cmp   cl, byte ptr ds:[bx + MOBJ_T.m_mobjtype]
0x0000000000004b07:  75 F8                jne   0x4b01
0x0000000000004b09:  83 7F 1C 00          cmp   word ptr ds:[bx + MOBJ_T.m_health], 0
0x0000000000004b0d:  7E 03                jle   0x4b12
0x0000000000004b0f:  E9 58 FF             jmp   0x4a6a
0x0000000000004b12:  E9 24 FF             jmp   0x4a39
0x0000000000004b15:  BB 01 00             mov   bx, 1
0x0000000000004b18:  BA FF FF             mov   dx, 0xffff
0x0000000000004b1b:  B8 3D 00             mov   ax, 0x3d
0x0000000000004b1e:  E8 71 07             call  EV_DoFloor_
0x0000000000004b21:  5E                   pop   si
0x0000000000004b22:  5A                   pop   dx
0x0000000000004b23:  59                   pop   cx
0x0000000000004b24:  5B                   pop   bx
0x0000000000004b25:  C3                   ret   
0x0000000000004b26:  BB BE 03             mov   bx, 0x3be
0x0000000000004b29:  8A 07                mov   al, byte ptr ds:[bx]
0x0000000000004b2b:  3C 04                cmp   al, 4
0x0000000000004b2d:  75 1D                jne   0x4b4c
0x0000000000004b2f:  BB BF 03             mov   bx, OFFSET _gamemap
0x0000000000004b32:  8A 07                mov   al, byte ptr ds:[bx]
0x0000000000004b34:  3C 08                cmp   al, 8
0x0000000000004b36:  74 18                je    0x4b50
0x0000000000004b38:  3C 06                cmp   al, 6
0x0000000000004b3a:  75 25                jne   0x4b61
0x0000000000004b3c:  BA 06 00             mov   dx, 6
0x0000000000004b3f:  B8 3D 00             mov   ax, 0x3d
0x0000000000004b42:  0E                   push  cs
0x0000000000004b43:  E8 3E D9             call  EV_DoDoor_
0x0000000000004b46:  90                   nop   
0x0000000000004b47:  5E                   pop   si
0x0000000000004b48:  5A                   pop   dx
0x0000000000004b49:  59                   pop   cx
0x0000000000004b4a:  5B                   pop   bx
0x0000000000004b4b:  C3                   ret   
0x0000000000004b4c:  3C 01                cmp   al, 1
0x0000000000004b4e:  75 11                jne   0x4b61
0x0000000000004b50:  BB 01 00             mov   bx, 1
0x0000000000004b53:  BA FF FF             mov   dx, 0xffff
0x0000000000004b56:  B8 3D 00             mov   ax, 0x3d
0x0000000000004b59:  E8 36 07             call  EV_DoFloor_
0x0000000000004b5c:  5E                   pop   si
0x0000000000004b5d:  5A                   pop   dx
0x0000000000004b5e:  59                   pop   cx
0x0000000000004b5f:  5B                   pop   bx
0x0000000000004b60:  C3                   ret   
0x0000000000004b61:  9A 68 19 88 0A       call  G_ExitLevel_
0x0000000000004b66:  5E                   pop   si
0x0000000000004b67:  5A                   pop   dx
0x0000000000004b68:  59                   pop   cx
0x0000000000004b69:  5B                   pop   bx
0x0000000000004b6a:  C3                   ret   
0x0000000000004b6b:  FC                   cld   

ENDP


PROC    A_Hoof_ NEAR
PUBLIC  A_Hoof_

0x0000000000004b6c:  52                   push  dx
0x0000000000004b6d:  56                   push  si
0x0000000000004b6e:  89 C6                mov   si, ax
0x0000000000004b70:  BA 54 00             mov   dx, 0x54
0x0000000000004b73:  0E                   push  cs
0x0000000000004b74:  3E E8 D8 B9          call  S_StartSound_
0x0000000000004b78:  89 F0                mov   ax, si
0x0000000000004b7a:  E8 33 E7             call  A_Chase_
0x0000000000004b7d:  5E                   pop   si
0x0000000000004b7e:  5A                   pop   dx
0x0000000000004b7f:  C3                   ret   

ENDP


PROC    A_Metal_ NEAR
PUBLIC  A_Metal_

0x0000000000004b80:  52                   push  dx
0x0000000000004b81:  56                   push  si
0x0000000000004b82:  89 C6                mov   si, ax
0x0000000000004b84:  BA 55 00             mov   dx, 0x55
0x0000000000004b87:  0E                   push  cs
0x0000000000004b88:  3E E8 C4 B9          call  S_StartSound_
0x0000000000004b8c:  89 F0                mov   ax, si
0x0000000000004b8e:  E8 1F E7             call  A_Chase_
0x0000000000004b91:  5E                   pop   si
0x0000000000004b92:  5A                   pop   dx
0x0000000000004b93:  C3                   ret   

ENDP


PROC    A_BabyMetal_ NEAR
PUBLIC  A_BabyMetal_

0x0000000000004b94:  52                   push  dx
0x0000000000004b95:  56                   push  si
0x0000000000004b96:  89 C6                mov   si, ax
0x0000000000004b98:  BA 4F 00             mov   dx, 0x4f
0x0000000000004b9b:  0E                   push  cs
0x0000000000004b9c:  3E E8 B0 B9          call  S_StartSound_
0x0000000000004ba0:  89 F0                mov   ax, si
0x0000000000004ba2:  E8 0B E7             call  A_Chase_
0x0000000000004ba5:  5E                   pop   si
0x0000000000004ba6:  5A                   pop   dx
0x0000000000004ba7:  C3                   ret   

ENDP


PROC    A_BrainAwake_ NEAR
PUBLIC  A_BrainAwake_

0x0000000000004ba8:  53                   push  bx
0x0000000000004ba9:  52                   push  dx
0x0000000000004baa:  BB 28 01             mov   bx, 0x128
0x0000000000004bad:  C7 07 00 00          mov   word ptr ds:[bx], 0
0x0000000000004bb1:  BB 2A 01             mov   bx, 0x12a
0x0000000000004bb4:  C7 07 00 00          mov   word ptr ds:[bx], 0
0x0000000000004bb8:  BB 02 34             mov   bx, OFFSET _thinkerlist + THINKER_T.t_next
0x0000000000004bbb:  8B 07                mov   ax, word ptr ds:[bx]
0x0000000000004bbd:  85 C0                test  ax, ax
0x0000000000004bbf:  74 1D                je    0x4bde
0x0000000000004bc1:  6B D8 2C             imul  bx, ax, SIZEOF_THINKER_T
0x0000000000004bc4:  8B 97 00 34          mov   dx, word ptr ds:[bx + _thinkerlist + THINKER_T.t_prevFunctype]
0x0000000000004bc8:  30 D2                xor   dl, dl
0x0000000000004bca:  80 E6 F8             and   dh, (TF_FUNCBITS SHR 8)
0x0000000000004bcd:  81 FA 00 08          cmp   dx, TF_MOBJTHINKER_HIGHBITS
0x0000000000004bd1:  74 18                je    0x4beb
0x0000000000004bd3:  6B D8 2C             imul  bx, ax, SIZEOF_THINKER_T
0x0000000000004bd6:  8B 87 02 34          mov   ax, word ptr ds:[bx + OFFSET _thinkerlist + THINKER_T.t_next]
0x0000000000004bda:  85 C0                test  ax, ax
0x0000000000004bdc:  75 E3                jne   0x4bc1
0x0000000000004bde:  BA 60 00             mov   dx, 0x60
0x0000000000004be1:  31 C0                xor   ax, ax
0x0000000000004be3:  0E                   push  cs
0x0000000000004be4:  3E E8 68 B9          call  S_StartSound_
0x0000000000004be8:  5A                   pop   dx
0x0000000000004be9:  5B                   pop   bx
0x0000000000004bea:  C3                   ret   
0x0000000000004beb:  81 C3 04 34          add   bx, (OFFSET _thinkerlist + THINKER_T.t_data)
0x0000000000004bef:  80 7F 1A 1B          cmp   byte ptr ds:[bx + MOBJ_T.m_mobjtype], 0x1b
0x0000000000004bf3:  75 DE                jne   0x4bd3
0x0000000000004bf5:  BB 28 01             mov   bx, 0x128
0x0000000000004bf8:  8B 1F                mov   bx, word ptr ds:[bx]
0x0000000000004bfa:  01 DB                add   bx, bx
0x0000000000004bfc:  89 87 B0 04          mov   word ptr ds:[bx + 0x4b0], ax
0x0000000000004c00:  BB 28 01             mov   bx, 0x128
0x0000000000004c03:  FF 07                inc   word ptr ds:[bx]
0x0000000000004c05:  EB CC                jmp   0x4bd3
0x0000000000004c07:  FC                   cld   

ENDP


PROC    A_BrainPain_ NEAR
PUBLIC  A_BrainPain_

0x0000000000004c08:  52                   push  dx
0x0000000000004c09:  BA 61 00             mov   dx, 0x61
0x0000000000004c0c:  31 C0                xor   ax, ax
0x0000000000004c0e:  0E                   push  cs
0x0000000000004c0f:  E8 3E B9             call  S_StartSound_
0x0000000000004c12:  90                   nop   
0x0000000000004c13:  5A                   pop   dx
0x0000000000004c14:  C3                   ret   
0x0000000000004c15:  FC                   cld   

ENDP


PROC    A_BrainScream_ NEAR
PUBLIC  A_BrainScream_

0x0000000000004c16:  52                   push  dx
0x0000000000004c17:  56                   push  si
0x0000000000004c18:  57                   push  di
0x0000000000004c19:  55                   push  bp
0x0000000000004c1a:  89 E5                mov   bp, sp
0x0000000000004c1c:  83 EC 06             sub   sp, 6
0x0000000000004c1f:  89 DF                mov   di, bx
0x0000000000004c21:  89 4E FE             mov   word ptr [bp - 2], cx
0x0000000000004c24:  8E C1                mov   es, cx
0x0000000000004c26:  C7 46 FA 00 00       mov   word ptr [bp - 6], 0
0x0000000000004c2b:  26 8B 05             mov   ax, word ptr es:[di]
0x0000000000004c2e:  26 8B 75 02          mov   si, word ptr es:[di + 2]
0x0000000000004c32:  89 46 FC             mov   word ptr [bp - 4], ax
0x0000000000004c35:  81 EE C4 00          sub   si, 0xc4
0x0000000000004c39:  8E 46 FE             mov   es, word ptr [bp - 2]
0x0000000000004c3c:  26 8B 45 02          mov   ax, word ptr es:[di + 2]
0x0000000000004c40:  05 40 01             add   ax, 0x140
0x0000000000004c43:  39 C6                cmp   si, ax
0x0000000000004c45:  7C 0F                jl    label_2:
0x0000000000004c47:  BA 62 00             mov   dx, 0x62
0x0000000000004c4a:  31 C0                xor   ax, ax
0x0000000000004c4c:  0E                   push  cs
0x0000000000004c4d:  E8 00 B9             call  S_StartSound_
0x0000000000004c50:  90                   nop   
0x0000000000004c51:  C9                   LEAVE_MACRO 
0x0000000000004c52:  5F                   pop   di
0x0000000000004c53:  5E                   pop   si
0x0000000000004c54:  5A                   pop   dx
0x0000000000004c55:  C3                   ret   
label_2:
0x0000000000004c56:  26 8B 55 04          mov   dx, word ptr es:[di + MOBJ_POS_T.mp_y + 0]
0x0000000000004c5a:  26 8B 4D 06          mov   cx, word ptr es:[di + MOBJ_POS_T.mp_y + 2]
0x0000000000004c5e:  E8 4F 3D             call  P_Random_
0x0000000000004c61:  88 C3                mov   bl, al
0x0000000000004c63:  30 FF                xor   bh, bh
0x0000000000004c65:  6A FF                push  -1
0x0000000000004c67:  01 DB                add   bx, bx
0x0000000000004c69:  6A 21                push  0x21
0x0000000000004c6b:  81 C3 80 00          add   bx, 0x80
0x0000000000004c6f:  81 E9 40 01          sub   cx, 0x140
0x0000000000004c73:  53                   push  bx
0x0000000000004c74:  8B 46 FC             mov   ax, word ptr [bp - 4]
0x0000000000004c77:  FF 76 FA             push  word ptr [bp - 6]
0x0000000000004c7a:  89 D3                mov   bx, dx
0x0000000000004c7c:  89 F2                mov   dx, si
0x0000000000004c7e:  0E                   push  cs
0x0000000000004c7f:  E8 22 41             call  P_SpawnMobj_
0x0000000000004c82:  90                   nop   
0x0000000000004c83:  BB BA 01             mov   bx, OFFSET _setStateReturn
0x0000000000004c86:  8B 1F                mov   bx, word ptr ds:[bx]
0x0000000000004c88:  E8 25 3D             call  P_Random_
0x0000000000004c8b:  88 C1                mov   cl, al
0x0000000000004c8d:  30 ED                xor   ch, ch
0x0000000000004c8f:  89 C8                mov   ax, cx
0x0000000000004c91:  C1 E0 09             shl   ax, 9
0x0000000000004c94:  99                   cwd   
0x0000000000004c95:  89 47 16             mov   word ptr ds:[bx + MOBJ_T.m_momz + 0], ax
0x0000000000004c98:  89 57 18             mov   word ptr ds:[bx + MOBJ_T.m_momz + 2], dx
0x0000000000004c9b:  BA 1F 03             mov   dx, 0x31f
0x0000000000004c9e:  89 D8                mov   ax, bx
0x0000000000004ca0:  0E                   push  cs
0x0000000000004ca1:  E8 4A 43             call  P_SetMobjState_
0x0000000000004ca4:  90                   nop   
0x0000000000004ca5:  E8 08 3D             call  P_Random_
0x0000000000004ca8:  24 07                and   al, 7
0x0000000000004caa:  28 47 1B             sub   byte ptr ds:[bx + MOBJ_T.m_tics], al
0x0000000000004cad:  8A 47 1B             mov   al, byte ptr ds:[bx + MOBJ_T.m_tics]
0x0000000000004cb0:  3C 01                cmp   al, 1
0x0000000000004cb2:  73 0A                jae   0x4cbe
0x0000000000004cb4:  C6 47 1B 01          mov   byte ptr ds:[bx + MOBJ_T.m_tics], 1
0x0000000000004cb8:  83 C6 08             add   si, 8
0x0000000000004cbb:  E9 7B FF             jmp   0x4c39
0x0000000000004cbe:  3C F0                cmp   al, 240
0x0000000000004cc0:  77 F2                ja    0x4cb4
0x0000000000004cc2:  83 C6 08             add   si, 8
0x0000000000004cc5:  E9 71 FF             jmp   0x4c39

ENDP


PROC    A_BrainExplode_ NEAR
PUBLIC  A_BrainExplode_

0x0000000000004cc8:  52                   push  dx
0x0000000000004cc9:  56                   push  si
0x0000000000004cca:  57                   push  di
0x0000000000004ccb:  E8 E2 3C             call  P_Random_
0x0000000000004cce:  88 C2                mov   dl, al
0x0000000000004cd0:  E8 DD 3C             call  P_Random_
0x0000000000004cd3:  30 F6                xor   dh, dh
0x0000000000004cd5:  30 E4                xor   ah, ah
0x0000000000004cd7:  29 C2                sub   dx, ax
0x0000000000004cd9:  8E C1                mov   es, cx
0x0000000000004cdb:  89 D0                mov   ax, dx
0x0000000000004cdd:  26 8B 37             mov   si, word ptr es:[bx]
0x0000000000004ce0:  C1 E0 0B             shl   ax, SIZEOF_MOBJINFO_T
0x0000000000004ce3:  26 8B 7F 04          mov   di, word ptr es:[bx + MOBJ_POS_T.mp_y + 0]
0x0000000000004ce7:  99                   cwd   
0x0000000000004ce8:  26 8B 4F 06          mov   cx, word ptr es:[bx + MOBJ_POS_T.mp_y + 2]
0x0000000000004cec:  01 C6                add   si, ax
0x0000000000004cee:  26 13 57 02          adc   dx, word ptr es:[bx + MOBJ_POS_T.mp_x + 2]
0x0000000000004cf2:  E8 BB 3C             call  P_Random_
0x0000000000004cf5:  30 E4                xor   ah, ah
0x0000000000004cf7:  6A FF                push  -1
0x0000000000004cf9:  01 C0                add   ax, ax
0x0000000000004cfb:  6A 21                push  0x21
0x0000000000004cfd:  05 80 00             add   ax, 0x80
0x0000000000004d00:  50                   push  ax
0x0000000000004d01:  89 FB                mov   bx, di
0x0000000000004d03:  6A 00                push  0
0x0000000000004d05:  89 F0                mov   ax, si
0x0000000000004d07:  0E                   push  cs
0x0000000000004d08:  3E E8 98 40          call  P_SpawnMobj_
0x0000000000004d0c:  BB BA 01             mov   bx, OFFSET _setStateReturn
0x0000000000004d0f:  8B 1F                mov   bx, word ptr ds:[bx]
0x0000000000004d11:  E8 9C 3C             call  P_Random_
0x0000000000004d14:  30 E4                xor   ah, ah
0x0000000000004d16:  C1 E0 09             shl   ax, 9
0x0000000000004d19:  99                   cwd   
0x0000000000004d1a:  89 47 16             mov   word ptr ds:[bx + MOBJ_T.m_momz + 0], ax
0x0000000000004d1d:  89 57 18             mov   word ptr ds:[bx + MOBJ_T.m_momz + 2], dx
0x0000000000004d20:  BA 1F 03             mov   dx, 0x31f
0x0000000000004d23:  89 D8                mov   ax, bx
0x0000000000004d25:  0E                   push  cs
0x0000000000004d26:  3E E8 C4 42          call  P_SetMobjState_
0x0000000000004d2a:  E8 83 3C             call  P_Random_
0x0000000000004d2d:  24 07                and   al, 7
0x0000000000004d2f:  28 47 1B             sub   byte ptr ds:[bx + MOBJ_T.m_tics], al
0x0000000000004d32:  8A 47 1B             mov   al, byte ptr ds:[bx + MOBJ_T.m_tics]
0x0000000000004d35:  3C 01                cmp   al, 1
0x0000000000004d37:  72 08                jb    0x4d41
0x0000000000004d39:  3C F0                cmp   al, 240
0x0000000000004d3b:  77 04                ja    0x4d41
0x0000000000004d3d:  5F                   pop   di
0x0000000000004d3e:  5E                   pop   si
0x0000000000004d3f:  5A                   pop   dx
0x0000000000004d40:  C3                   ret   
0x0000000000004d41:  C6 47 1B 01          mov   byte ptr ds:[bx + MOBJ_T.m_tics], 1
0x0000000000004d45:  5F                   pop   di
0x0000000000004d46:  5E                   pop   si
0x0000000000004d47:  5A                   pop   dx
0x0000000000004d48:  C3                   ret   
0x0000000000004d49:  FC                   cld   

ENDP


PROC    A_BrainSpit_ NEAR
PUBLIC  A_BrainSpit_

0x0000000000004d4a:  52                   push  dx
0x0000000000004d4b:  56                   push  si
0x0000000000004d4c:  57                   push  di
0x0000000000004d4d:  55                   push  bp
0x0000000000004d4e:  89 E5                mov   bp, sp
0x0000000000004d50:  83 EC 0A             sub   sp, 0Ah
0x0000000000004d53:  89 C7                mov   di, ax
0x0000000000004d55:  89 DE                mov   si, bx
0x0000000000004d57:  89 4E FE             mov   word ptr [bp - 2], cx
0x0000000000004d5a:  BB 2C 01             mov   bx, 0x12c
0x0000000000004d5d:  80 37 01             xor   byte ptr ds:[bx], 1
0x0000000000004d60:  80 3E 14 22 01       cmp   byte ptr ds:[_gameskill], SK_EASY
0x0000000000004d65:  77 0A                ja    0x4d71
0x0000000000004d67:  80 3F 00             cmp   byte ptr ds:[bx], 0
0x0000000000004d6a:  75 05                jne   0x4d71
0x0000000000004d6c:  C9                   LEAVE_MACRO 
0x0000000000004d6d:  5F                   pop   di
0x0000000000004d6e:  5E                   pop   si
0x0000000000004d6f:  5A                   pop   dx
0x0000000000004d70:  C3                   ret   
0x0000000000004d71:  BB 2A 01             mov   bx, 0x12a
0x0000000000004d74:  8B 1F                mov   bx, word ptr ds:[bx]
0x0000000000004d76:  01 DB                add   bx, bx
0x0000000000004d78:  8B 87 B0 04          mov   ax, word ptr ds:[bx + 0x4b0]
0x0000000000004d7c:  BB 2A 01             mov   bx, 0x12a
0x0000000000004d7f:  89 46 F8             mov   word ptr [bp - 8], ax
0x0000000000004d82:  8B 07                mov   ax, word ptr ds:[bx]
0x0000000000004d84:  40                   inc   ax
0x0000000000004d85:  BB 28 01             mov   bx, 0x128
0x0000000000004d88:  99                   cwd   
0x0000000000004d89:  F7 3F                idiv  word ptr ds:[bx]
0x0000000000004d8b:  BB 2A 01             mov   bx, 0x12a
0x0000000000004d8e:  89 17                mov   word ptr ds:[bx], dx
0x0000000000004d90:  6B 56 F8 2C          imul  dx, word ptr [bp - 8], SIZEOF_THINKER_T
0x0000000000004d94:  6B 5E F8 18          imul  bx, word ptr [bp - 8], SIZEOF_MOBJ_POS_T
0x0000000000004d98:  6A 1C                push  0x1c
0x0000000000004d9a:  8B 4E FE             mov   cx, word ptr [bp - 2]
0x0000000000004d9d:  89 F8                mov   ax, di
0x0000000000004d9f:  81 C2 04 34          add   dx, (OFFSET _thinkerlist + THINKER_T.t_data)
0x0000000000004da3:  89 5E FC             mov   word ptr [bp - 4], bx
0x0000000000004da6:  89 F3                mov   bx, si
0x0000000000004da8:  BF BA 01             mov   di, OFFSET _setStateReturn
0x0000000000004dab:  FF 1E F8 0C          call  dword ptr ds:[_SpawnMissile]
0x0000000000004daf:  BB 34 07             mov   bx, OFFSET _setStateReturn_pos
0x0000000000004db2:  8B 46 F8             mov   ax, word ptr [bp - 8]
0x0000000000004db5:  8B 3D                mov   di, word ptr ds:[di]
0x0000000000004db7:  C4 17                les   dx, ptr ds:[bx]
0x0000000000004db9:  89 D3                mov   bx, dx
0x0000000000004dbb:  89 45 22             mov   word ptr ds:[di + MOBJ_T.m_targetRef], ax
0x0000000000004dbe:  26 8B 57 12          mov   dx, word ptr es:[bx + 0x12]
0x0000000000004dc2:  89 D3                mov   bx, dx
0x0000000000004dc4:  C1 E3 02             shl   bx, 2
0x0000000000004dc7:  29 D3                sub   bx, dx
0x0000000000004dc9:  BA 74 7D             mov   dx, 0x7d74
0x0000000000004dcc:  01 DB                add   bx, bx
0x0000000000004dce:  8E C2                mov   es, dx
0x0000000000004dd0:  26 8A 47 02          mov   al, byte ptr es:[bx + 2]
0x0000000000004dd4:  C7 46 F6 F5 6A       mov   word ptr [bp - 0Ah], MOBJPOSLIST_6800_SEGMENT
0x0000000000004dd9:  98                   cbw  
0x0000000000004dda:  83 C3 02             add   bx, 2
0x0000000000004ddd:  99                   cwd   
0x0000000000004dde:  8B 5E FC             mov   bx, word ptr [bp - 4]
0x0000000000004de1:  89 C1                mov   cx, ax
0x0000000000004de3:  8B 45 14             mov   ax, word ptr ds:[di + 0x14]
0x0000000000004de6:  8E 46 F6             mov   es, word ptr [bp - 0Ah]
0x0000000000004de9:  89 46 FA             mov   word ptr [bp - 6], ax
0x0000000000004dec:  26 8B 47 06          mov   ax, word ptr es:[bx + MOBJ_POS_T.mp_y + 2]
0x0000000000004df0:  8E 46 FE             mov   es, word ptr [bp - 2]
0x0000000000004df3:  89 56 FC             mov   word ptr [bp - 4], dx
0x0000000000004df6:  26 2B 44 06          sub   ax, word ptr es:[si + MOBJ_POS_T.mp_y + 2]
0x0000000000004dfa:  8B 5E FA             mov   bx, word ptr [bp - 6]
0x0000000000004dfd:  99                   cwd   
0x0000000000004dfe:  9A CB 5E 88 0A       call  FastDiv3216u_
0x0000000000004e03:  89 CB                mov   bx, cx
0x0000000000004e05:  8B 4E FC             mov   cx, word ptr [bp - 4]
0x0000000000004e08:  0E                   push  cs
0x0000000000004e09:  E8 1A 6E             call  __I4Dc26
0x0000000000004e0c:  90                   nop   
0x0000000000004e0d:  BA 5E 00             mov   dx, 0x5e
0x0000000000004e10:  88 45 24             mov   byte ptr ds:[di + 0x24], al
0x0000000000004e13:  31 C0                xor   ax, ax
0x0000000000004e15:  0E                   push  cs
0x0000000000004e16:  3E E8 36 B7          call  S_StartSound_
0x0000000000004e1a:  C9                   LEAVE_MACRO 
0x0000000000004e1b:  5F                   pop   di
0x0000000000004e1c:  5E                   pop   si
0x0000000000004e1d:  5A                   pop   dx
0x0000000000004e1e:  C3                   ret   
0x0000000000004e1f:  FC                   cld   

ENDP


PROC    A_SpawnSound_ NEAR
PUBLIC  A_SpawnSound_

0x0000000000004e20:  52                   push  dx
0x0000000000004e21:  56                   push  si
0x0000000000004e22:  89 C6                mov   si, ax
0x0000000000004e24:  BA 5F 00             mov   dx, 0x5f
0x0000000000004e27:  0E                   push  cs
0x0000000000004e28:  3E E8 24 B7          call  S_StartSound_
0x0000000000004e2c:  89 F0                mov   ax, si
0x0000000000004e2e:  E8 03 00             call  A_SpawnFly_
0x0000000000004e31:  5E                   pop   si
0x0000000000004e32:  5A                   pop   dx
0x0000000000004e33:  C3                   ret   

ENDP


PROC    A_SpawnFly_ NEAR
PUBLIC  A_SpawnFly_

0x0000000000004e34:  52                   push  dx
0x0000000000004e35:  56                   push  si
0x0000000000004e36:  57                   push  di
0x0000000000004e37:  55                   push  bp
0x0000000000004e38:  89 E5                mov   bp, sp
0x0000000000004e3a:  83 EC 0A             sub   sp, 0Ah
0x0000000000004e3d:  89 C7                mov   di, ax
0x0000000000004e3f:  C7 46 F6 50 03       mov   word ptr [bp - 0Ah], GETSEESTATEADDR
0x0000000000004e44:  C7 46 F8 D9 92       mov   word ptr [bp - 8], INFOFUNCLOADSEGMENT
0x0000000000004e49:  FE 4D 24             dec   byte ptr ds:[di + 0x24]
0x0000000000004e4c:  74 05                je    0x4e53
0x0000000000004e4e:  C9                   LEAVE_MACRO 
0x0000000000004e4f:  5F                   pop   di
0x0000000000004e50:  5E                   pop   si
0x0000000000004e51:  5A                   pop   dx
0x0000000000004e52:  C3                   ret   
0x0000000000004e53:  8B 75 22             mov   si, word ptr ds:[di + MOBJ_T.m_targetRef]
0x0000000000004e56:  6B C6 2C             imul  ax, si, SIZEOF_THINKER_T
0x0000000000004e59:  6B F6 18             imul  si, si, SIZEOF_MOBJ_POS_T
0x0000000000004e5c:  05 04 34             add   ax, (OFFSET _thinkerlist + THINKER_T.t_data)
0x0000000000004e5f:  89 46 FA             mov   word ptr [bp - 6], ax
0x0000000000004e62:  8B 5E FA             mov   bx, word ptr [bp - 6]
0x0000000000004e65:  FF 77 04             push  word ptr ds:[bx + MOBJ_T.m_secnum]
0x0000000000004e68:  B8 F5 6A             mov   ax, MOBJPOSLIST_6800_SEGMENT
0x0000000000004e6b:  6A 1D                push  0x1d
0x0000000000004e6d:  8E C0                mov   es, ax
0x0000000000004e6f:  89 46 FE             mov   word ptr [bp - 2], ax
0x0000000000004e72:  26 FF 74 0A          push  word ptr es:[si + MOBJ_POS_T.mp_z + 2]
0x0000000000004e76:  26 8B 5C 04          mov   bx, word ptr es:[si + MOBJ_POS_T.mp_y + 0]
0x0000000000004e7a:  26 8B 4C 06          mov   cx, word ptr es:[si + MOBJ_POS_T.mp_y + 2]
0x0000000000004e7e:  26 8B 04             mov   ax, word ptr es:[si]
0x0000000000004e81:  26 FF 74 08          push  word ptr es:[si + MOBJ_POS_T.mp_z + 0]
0x0000000000004e85:  26 8B 54 02          mov   dx, word ptr es:[si + 2]
0x0000000000004e89:  0E                   push  cs
0x0000000000004e8a:  3E E8 16 3F          call  P_SpawnMobj_
0x0000000000004e8e:  BB BA 01             mov   bx, OFFSET _setStateReturn
0x0000000000004e91:  BA 23 00             mov   dx, 0x23
0x0000000000004e94:  8B 07                mov   ax, word ptr ds:[bx]
0x0000000000004e96:  89 76 FC             mov   word ptr [bp - 4], si
0x0000000000004e99:  0E                   push  cs
0x0000000000004e9a:  3E E8 B2 B6          call  S_StartSound_
0x0000000000004e9e:  E8 0F 3B             call  P_Random_
0x0000000000004ea1:  3C 32                cmp   al, 0x32
0x0000000000004ea3:  72 03                jb    0x4ea8
0x0000000000004ea5:  E9 7D 00             jmp   0x4f25
0x0000000000004ea8:  B0 0B                mov   al, SIZEOF_MOBJINFO_T
0x0000000000004eaa:  8B 5E FA             mov   bx, word ptr [bp - 6]
0x0000000000004ead:  30 E4                xor   ah, ah
0x0000000000004eaf:  FF 77 04             push  word ptr ds:[bx + MOBJ_T.m_secnum]
0x0000000000004eb2:  C4 5E FC             les   bx, ptr [bp - 4]
0x0000000000004eb5:  50                   push  ax
0x0000000000004eb6:  8B 76 FC             mov   si, word ptr [bp - 4]
0x0000000000004eb9:  26 FF 77 0A          push  word ptr es:[bx + MOBJ_POS_T.mp_z + 2]
0x0000000000004ebd:  26 8B 4C 06          mov   cx, word ptr es:[si + MOBJ_POS_T.mp_y + 2]
0x0000000000004ec1:  26 8B 04             mov   ax, word ptr es:[si]
0x0000000000004ec4:  26 8B 54 02          mov   dx, word ptr es:[si + 2]
0x0000000000004ec8:  26 FF 77 08          push  word ptr es:[bx + MOBJ_POS_T.mp_z + 0]
0x0000000000004ecc:  26 8B 5F 04          mov   bx, word ptr es:[bx + MOBJ_POS_T.mp_y + 0]
0x0000000000004ed0:  0E                   push  cs
0x0000000000004ed1:  E8 D0 3E             call  P_SpawnMobj_
0x0000000000004ed4:  90                   nop   
0x0000000000004ed5:  6B F0 2C             imul  si, ax, SIZEOF_THINKER_T
0x0000000000004ed8:  6B D8 18             imul  bx, ax, SIZEOF_MOBJ_POS_T
0x0000000000004edb:  81 C6 04 34          add   si, (OFFSET _thinkerlist + THINKER_T.t_data)
0x0000000000004edf:  BA 01 00             mov   dx, 1
0x0000000000004ee2:  89 F0                mov   ax, si
0x0000000000004ee4:  B9 F5 6A             mov   cx, MOBJPOSLIST_6800_SEGMENT
0x0000000000004ee7:  E8 3A E1             call  P_LookForPlayers_
0x0000000000004eea:  84 C0                test  al, al
0x0000000000004eec:  74 11                je    0x4eff
0x0000000000004eee:  8A 44 1A             mov   al, byte ptr ds:[si + MOBJ_T.m_mobjtype]
0x0000000000004ef1:  30 E4                xor   ah, ah
0x0000000000004ef3:  FF 5E F6             call  dword ptr [bp - 0Ah]
0x0000000000004ef6:  89 C2                mov   dx, ax
0x0000000000004ef8:  89 F0                mov   ax, si
0x0000000000004efa:  0E                   push  cs
0x0000000000004efb:  E8 F0 40             call  P_SetMobjState_
0x0000000000004efe:  90                   nop   
0x0000000000004eff:  FF 74 04             push  word ptr ds:[si + 4]
0x0000000000004f02:  8E C1                mov   es, cx
0x0000000000004f04:  26 FF 77 06          push  word ptr es:[bx + MOBJ_POS_T.mp_y + 2]
0x0000000000004f08:  26 FF 77 04          push  word ptr es:[bx + MOBJ_POS_T.mp_y + 0]
0x0000000000004f0c:  26 FF 77 02          push  word ptr es:[bx + 2]
0x0000000000004f10:  26 FF 37             push  word ptr es:[bx]
0x0000000000004f13:  89 F0                mov   ax, si
0x0000000000004f15:  FF 1E E4 0C          call  dword ptr ds:[_P_TeleportMove]
0x0000000000004f19:  89 F8                mov   ax, di
0x0000000000004f1b:  0E                   push  cs
0x0000000000004f1c:  3E E8 3C 40          call  P_RemoveMobj_
0x0000000000004f20:  C9                   LEAVE_MACRO 
0x0000000000004f21:  5F                   pop   di
0x0000000000004f22:  5E                   pop   si
0x0000000000004f23:  5A                   pop   dx
0x0000000000004f24:  C3                   ret   
0x0000000000004f25:  3C 5A                cmp   al, 0x5a
0x0000000000004f27:  73 05                jae   0x4f2e
0x0000000000004f29:  B0 0C                mov   al, 0xc
0x0000000000004f2b:  E9 7C FF             jmp   0x4eaa
0x0000000000004f2e:  3C 78                cmp   al, 0x78
0x0000000000004f30:  73 05                jae   0x4f37
0x0000000000004f32:  B0 0D                mov   al, 0xd
0x0000000000004f34:  E9 73 FF             jmp   0x4eaa
0x0000000000004f37:  3C 82                cmp   al, 0x82
0x0000000000004f39:  73 05                jae   0x4f40
0x0000000000004f3b:  B0 16                mov   al, 0x16
0x0000000000004f3d:  E9 6A FF             jmp   0x4eaa
0x0000000000004f40:  3C A0                cmp   al, 0xa0
0x0000000000004f42:  73 05                jae   0x4f49
0x0000000000004f44:  B0 0E                mov   al, 0xe
0x0000000000004f46:  E9 61 FF             jmp   0x4eaa
0x0000000000004f49:  3C A2                cmp   al, 0xa2
0x0000000000004f4b:  73 05                jae   0x4f52
0x0000000000004f4d:  B0 03                mov   al, 3
0x0000000000004f4f:  E9 58 FF             jmp   0x4eaa
0x0000000000004f52:  3C AC                cmp   al, 0xac
0x0000000000004f54:  73 05                jae   0x4f5b
0x0000000000004f56:  B0 05                mov   al, 5
0x0000000000004f58:  E9 4F FF             jmp   0x4eaa
0x0000000000004f5b:  3C C0                cmp   al, 0xc0
0x0000000000004f5d:  73 05                jae   0x4f64
0x0000000000004f5f:  B0 14                mov   al, 0x14
0x0000000000004f61:  E9 46 FF             jmp   0x4eaa
0x0000000000004f64:  3C DE                cmp   al, 0xde
0x0000000000004f66:  73 05                jae   0x4f6d
0x0000000000004f68:  B0 08                mov   al, 8
0x0000000000004f6a:  E9 3D FF             jmp   0x4eaa
0x0000000000004f6d:  3C F6                cmp   al, 0xf6
0x0000000000004f6f:  73 05                jae   0x4f76
0x0000000000004f71:  B0 11                mov   al, 0x11
0x0000000000004f73:  E9 34 FF             jmp   0x4eaa
0x0000000000004f76:  B0 0F                mov   al, 0xf
0x0000000000004f78:  E9 2F FF             jmp   0x4eaa
0x0000000000004f7b:  FC                   cld   

ENDP


PROC    A_PlayerScream_ NEAR
PUBLIC  A_PlayerScream_

0x0000000000004f7c:  53                   push  bx
0x0000000000004f7d:  52                   push  dx
0x0000000000004f7e:  BB EB 02             mov   bx, OFFSET _commercial
0x0000000000004f81:  B0 39                mov   al, SFX_PLDETH 
0x0000000000004f83:  80 3F 00             cmp   byte ptr ds:[bx], 0
0x0000000000004f86:  74 0D                je    0x4f95
0x0000000000004f88:  BB EC 06             mov   bx, OFFSET _playerMobj
0x0000000000004f8b:  8B 1F                mov   bx, word ptr ds:[bx]
0x0000000000004f8d:  83 7F 1C CE          cmp   word ptr ds:[bx + MOBJ_T.m_health], -50
0x0000000000004f91:  7D 02                jge   0x4f95
0x0000000000004f93:  B0 3A                mov   al, SFX_PDIEHI
0x0000000000004f95:  30 E4                xor   ah, ah
0x0000000000004f97:  BB EC 06             mov   bx, OFFSET _playerMobj
0x0000000000004f9a:  89 C2                mov   dx, ax
0x0000000000004f9c:  8B 07                mov   ax, word ptr ds:[bx]
0x0000000000004f9e:  0E                   push  cs
0x0000000000004f9f:  E8 AE B5             call  S_StartSound_
0x0000000000004fa2:  90                   nop   
0x0000000000004fa3:  5A                   pop   dx
0x0000000000004fa4:  5B                   pop   bx
0x0000000000004fa5:  C3                   ret   


PROC    P_ENEMY_ENDMARKER_ 
PUBLIC  P_ENEMY_ENDMARKER_
ENDP



END
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



PROC    P_ENEMY_STARTMARKER_ 
PUBLIC  P_ENEMY_STARTMARKER_
ENDP

COMMENT @


0x00000000000028a0:  53                   push  bx
0x00000000000028a1:  51                   push  cx
0x00000000000028a2:  56                   push  si
0x00000000000028a3:  57                   push  di
0x00000000000028a4:  55                   push  bp
0x00000000000028a5:  89 E5                mov   bp, sp
0x00000000000028a7:  83 EC 10             sub   sp, 0x10
0x00000000000028aa:  50                   push  ax
0x00000000000028ab:  88 56 FC             mov   byte ptr [bp - 4], dl
0x00000000000028ae:  C7 46 F8 90 21       mov   word ptr [bp - 8], 0x2190
0x00000000000028b3:  C7 46 F0 74 09       mov   word ptr [bp - 0x10], 0x974
0x00000000000028b8:  C7 46 F2 00 94       mov   word ptr [bp - 0xe], 0x9400
0x00000000000028bd:  89 C3                mov   bx, ax
0x00000000000028bf:  8E 46 F8             mov   es, word ptr [bp - 8]
0x00000000000028c2:  C1 E3 04             shl   bx, 4
0x00000000000028c5:  BE 24 01             mov   si, 0x124
0x00000000000028c8:  26 8B 47 06          mov   ax, word ptr es:[bx + 6]
0x00000000000028cc:  89 5E F6             mov   word ptr [bp - 0xa], bx
0x00000000000028cf:  3B 04                cmp   ax, word ptr [si]
0x00000000000028d1:  75 19                jne   0x28ec
0x00000000000028d3:  B8 56 4C             mov   ax, 0x4c56
0x00000000000028d6:  8B 5E EE             mov   bx, word ptr [bp - 0x12]
0x00000000000028d9:  8E C0                mov   es, ax
0x00000000000028db:  26 8A 07             mov   al, byte ptr es:[bx]
0x00000000000028de:  98                   cwde  
0x00000000000028df:  89 C3                mov   bx, ax
0x00000000000028e1:  88 D0                mov   al, dl
0x00000000000028e3:  98                   cwde  
0x00000000000028e4:  40                   inc   ax
0x00000000000028e5:  39 C3                cmp   bx, ax
0x00000000000028e7:  7F 03                jg    0x28ec
0x00000000000028e9:  E9 89 00             jmp   0x2975
0x00000000000028ec:  BB 24 01             mov   bx, 0x124
0x00000000000028ef:  8B 07                mov   ax, word ptr [bx]
0x00000000000028f1:  C4 5E F6             les   bx, ptr [bp - 0xa]
0x00000000000028f4:  26 89 47 06          mov   word ptr es:[bx + 6], ax
0x00000000000028f8:  BB 56 4C             mov   bx, 0x4c56
0x00000000000028fb:  8A 46 FC             mov   al, byte ptr [bp - 4]
0x00000000000028fe:  8E C3                mov   es, bx
0x0000000000002900:  8B 5E EE             mov   bx, word ptr [bp - 0x12]
0x0000000000002903:  FE C0                inc   al
0x0000000000002905:  26 88 07             mov   byte ptr es:[bx], al
0x0000000000002908:  C4 5E F6             les   bx, ptr [bp - 0xa]
0x000000000000290b:  31 C9                xor   cx, cx
0x000000000000290d:  26 8B 47 0A          mov   ax, word ptr es:[bx + 0xa]
0x0000000000002911:  8B 5E EE             mov   bx, word ptr [bp - 0x12]
0x0000000000002914:  C7 46 F8 90 21       mov   word ptr [bp - 8], 0x2190
0x0000000000002919:  C1 E3 04             shl   bx, 4
0x000000000000291c:  89 46 F4             mov   word ptr [bp - 0xc], ax
0x000000000000291f:  89 5E F6             mov   word ptr [bp - 0xa], bx
0x0000000000002922:  85 C0                test  ax, ax
0x0000000000002924:  7E 4F                jle   0x2975
0x0000000000002926:  C4 5E F6             les   bx, ptr [bp - 0xa]
0x0000000000002929:  26 8B 47 0C          mov   ax, word ptr es:[bx + 0xc]
0x000000000000292d:  01 C8                add   ax, cx
0x000000000000292f:  01 C0                add   ax, ax
0x0000000000002931:  89 C3                mov   bx, ax
0x0000000000002933:  81 C3 50 CA          add   bx, 0xca50
0x0000000000002937:  8B 07                mov   ax, word ptr [bx]
0x0000000000002939:  BB 4A 2B             mov   bx, 0x2b4a
0x000000000000293c:  8E C3                mov   es, bx
0x000000000000293e:  89 C3                mov   bx, ax
0x0000000000002940:  BE 91 29             mov   si, 0x2991
0x0000000000002943:  26 8A 1F             mov   bl, byte ptr es:[bx]
0x0000000000002946:  C7 46 FA 00 70       mov   word ptr [bp - 6], 0x7000
0x000000000000294b:  88 5E FE             mov   byte ptr [bp - 2], bl
0x000000000000294e:  8E C6                mov   es, si
0x0000000000002950:  89 C3                mov   bx, ax
0x0000000000002952:  89 C6                mov   si, ax
0x0000000000002954:  C1 E3 02             shl   bx, 2
0x0000000000002957:  C1 E6 04             shl   si, 4
0x000000000000295a:  26 8B 47 02          mov   ax, word ptr es:[bx + 2]
0x000000000000295e:  8E 46 FA             mov   es, word ptr [bp - 6]
0x0000000000002961:  26 8B 7C 0A          mov   di, word ptr es:[si + 0xa]
0x0000000000002965:  26 8B 5C 0C          mov   bx, word ptr es:[si + 0xc]
0x0000000000002969:  F6 46 FE 04          test  byte ptr [bp - 2], 4
0x000000000000296d:  75 0C                jne   0x297b
0x000000000000296f:  41                   inc   cx
0x0000000000002970:  3B 4E F4             cmp   cx, word ptr [bp - 0xc]
0x0000000000002973:  7C B1                jl    0x2926
0x0000000000002975:  C9                   leave 
0x0000000000002976:  5F                   pop   di
0x0000000000002977:  5E                   pop   si
0x0000000000002978:  59                   pop   cx
0x0000000000002979:  5B                   pop   bx
0x000000000000297a:  C3                   ret   
0x000000000000297b:  89 FA                mov   dx, di
0x000000000000297d:  FF 5E F0             lcall [bp - 0x10]
0x0000000000002980:  BB F0 06             mov   bx, 0x6f0
0x0000000000002983:  8B 07                mov   ax, word ptr [bx]
0x0000000000002985:  BB F2 06             mov   bx, 0x6f2
0x0000000000002988:  3B 07                cmp   ax, word ptr [bx]
0x000000000000298a:  7E E3                jle   0x296f
0x000000000000298c:  8E 46 FA             mov   es, word ptr [bp - 6]
0x000000000000298f:  26 8B 44 0A          mov   ax, word ptr es:[si + 0xa]
0x0000000000002993:  3B 46 EE             cmp   ax, word ptr [bp - 0x12]
0x0000000000002996:  75 1A                jne   0x29b2
0x0000000000002998:  26 8B 74 0C          mov   si, word ptr es:[si + 0xc]
0x000000000000299c:  F6 46 FE 40          test  byte ptr [bp - 2], 0x40
0x00000000000029a0:  74 14                je    0x29b6
0x00000000000029a2:  80 7E FC 00          cmp   byte ptr [bp - 4], 0
0x00000000000029a6:  75 C7                jne   0x296f
0x00000000000029a8:  BA 01 00             mov   dx, 1
0x00000000000029ab:  89 F0                mov   ax, si
0x00000000000029ad:  E8 F0 FE             call  0x28a0
0x00000000000029b0:  EB BD                jmp   0x296f
0x00000000000029b2:  89 C6                mov   si, ax
0x00000000000029b4:  EB E6                jmp   0x299c
0x00000000000029b6:  8A 46 FC             mov   al, byte ptr [bp - 4]
0x00000000000029b9:  98                   cwde  
0x00000000000029ba:  89 C2                mov   dx, ax
0x00000000000029bc:  89 F0                mov   ax, si
0x00000000000029be:  E8 DF FE             call  0x28a0
0x00000000000029c1:  EB AC                jmp   0x296f
0x00000000000029c3:  FC                   cld   
0x00000000000029c4:  53                   push  bx
0x00000000000029c5:  52                   push  dx
0x00000000000029c6:  56                   push  si
0x00000000000029c7:  BB 24 01             mov   bx, 0x124
0x00000000000029ca:  BE EC 06             mov   si, 0x6ec
0x00000000000029cd:  FF 07                inc   word ptr [bx]
0x00000000000029cf:  8B 1C                mov   bx, word ptr [si]
0x00000000000029d1:  31 D2                xor   dx, dx
0x00000000000029d3:  8B 47 04             mov   ax, word ptr [bx + 4]
0x00000000000029d6:  E8 C7 FE             call  0x28a0
0x00000000000029d9:  5E                   pop   si
0x00000000000029da:  5A                   pop   dx
0x00000000000029db:  5B                   pop   bx
0x00000000000029dc:  CB                   retf  
0x00000000000029dd:  FC                   cld   
0x00000000000029de:  53                   push  bx
0x00000000000029df:  51                   push  cx
0x00000000000029e0:  52                   push  dx
0x00000000000029e1:  56                   push  si
0x00000000000029e2:  57                   push  di
0x00000000000029e3:  55                   push  bp
0x00000000000029e4:  89 E5                mov   bp, sp
0x00000000000029e6:  83 EC 10             sub   sp, 0x10
0x00000000000029e9:  50                   push  ax
0x00000000000029ea:  89 C3                mov   bx, ax
0x00000000000029ec:  83 7F 22 00          cmp   word ptr [bx + 0x22], 0
0x00000000000029f0:  75 09                jne   0x29fb
0x00000000000029f2:  30 C0                xor   al, al
0x00000000000029f4:  C9                   leave 
0x00000000000029f5:  5F                   pop   di
0x00000000000029f6:  5E                   pop   si
0x00000000000029f7:  5A                   pop   dx
0x00000000000029f8:  59                   pop   cx
0x00000000000029f9:  5B                   pop   bx
0x00000000000029fa:  C3                   ret   
0x00000000000029fb:  BB 2C 00             mov   bx, 0x2c
0x00000000000029fe:  2D 04 34             sub   ax, 0x3404
0x0000000000002a01:  31 D2                xor   dx, dx
0x0000000000002a03:  F7 F3                div   bx
0x0000000000002a05:  6B F0 18             imul  si, ax, 0x18
0x0000000000002a08:  B8 F5 6A             mov   ax, 0x6af5
0x0000000000002a0b:  8E C0                mov   es, ax
0x0000000000002a0d:  26 8B 04             mov   ax, word ptr es:[si]
0x0000000000002a10:  89 46 FC             mov   word ptr [bp - 4], ax
0x0000000000002a13:  26 8B 44 02          mov   ax, word ptr es:[si + 2]
0x0000000000002a17:  8B 7E EE             mov   di, word ptr [bp - 0x12]
0x0000000000002a1a:  89 46 F2             mov   word ptr [bp - 0xe], ax
0x0000000000002a1d:  26 8B 44 04          mov   ax, word ptr es:[si + 4]
0x0000000000002a21:  8B 7D 22             mov   di, word ptr [di + 0x22]
0x0000000000002a24:  89 46 F4             mov   word ptr [bp - 0xc], ax
0x0000000000002a27:  6B C7 2C             imul  ax, di, 0x2c
0x0000000000002a2a:  6B FF 18             imul  di, di, 0x18
0x0000000000002a2d:  05 04 34             add   ax, 0x3404
0x0000000000002a30:  89 46 FE             mov   word ptr [bp - 2], ax
0x0000000000002a33:  26 8B 05             mov   ax, word ptr es:[di]
0x0000000000002a36:  89 46 F6             mov   word ptr [bp - 0xa], ax
0x0000000000002a39:  26 8B 45 02          mov   ax, word ptr es:[di + 2]
0x0000000000002a3d:  89 46 F0             mov   word ptr [bp - 0x10], ax
0x0000000000002a40:  26 8B 45 04          mov   ax, word ptr es:[di + 4]
0x0000000000002a44:  8B 5E FE             mov   bx, word ptr [bp - 2]
0x0000000000002a47:  89 46 F8             mov   word ptr [bp - 8], ax
0x0000000000002a4a:  8A 47 1A             mov   al, byte ptr [bx + 0x1a]
0x0000000000002a4d:  30 E4                xor   ah, ah
0x0000000000002a4f:  6B C0 0B             imul  ax, ax, 0xb
0x0000000000002a52:  26 8B 4C 06          mov   cx, word ptr es:[si + 6]
0x0000000000002a56:  89 C3                mov   bx, ax
0x0000000000002a58:  26 8B 55 06          mov   dx, word ptr es:[di + 6]
0x0000000000002a5c:  81 C3 65 C4          add   bx, 0xc465
0x0000000000002a60:  8A 07                mov   al, byte ptr [bx]
0x0000000000002a62:  8B 5E F8             mov   bx, word ptr [bp - 8]
0x0000000000002a65:  88 46 FA             mov   byte ptr [bp - 6], al
0x0000000000002a68:  2B 5E F4             sub   bx, word ptr [bp - 0xc]
0x0000000000002a6b:  19 CA                sbb   dx, cx
0x0000000000002a6d:  8B 46 F6             mov   ax, word ptr [bp - 0xa]
0x0000000000002a70:  89 D1                mov   cx, dx
0x0000000000002a72:  2B 46 FC             sub   ax, word ptr [bp - 4]
0x0000000000002a75:  8B 56 F0             mov   dx, word ptr [bp - 0x10]
0x0000000000002a78:  1B 56 F2             sbb   dx, word ptr [bp - 0xe]
0x0000000000002a7b:  C6 46 FB 00          mov   byte ptr [bp - 5], 0
0x0000000000002a7f:  FF 1E D0 0C          lcall [0xcd0]
0x0000000000002a83:  8B 46 FA             mov   ax, word ptr [bp - 6]
0x0000000000002a86:  05 2C 00             add   ax, 0x2c
0x0000000000002a89:  39 C2                cmp   dx, ax
0x0000000000002a8b:  7C 03                jl    0x2a90
0x0000000000002a8d:  E9 62 FF             jmp   0x29f2
0x0000000000002a90:  8B 56 FE             mov   dx, word ptr [bp - 2]
0x0000000000002a93:  8B 46 EE             mov   ax, word ptr [bp - 0x12]
0x0000000000002a96:  89 F9                mov   cx, di
0x0000000000002a98:  89 F3                mov   bx, si
0x0000000000002a9a:  FF 1E CC 0C          lcall [0xccc]
0x0000000000002a9e:  84 C0                test  al, al
0x0000000000002aa0:  75 03                jne   0x2aa5
0x0000000000002aa2:  E9 4F FF             jmp   0x29f4
0x0000000000002aa5:  B0 01                mov   al, 1
0x0000000000002aa7:  C9                   leave 
0x0000000000002aa8:  5F                   pop   di
0x0000000000002aa9:  5E                   pop   si
0x0000000000002aaa:  5A                   pop   dx
0x0000000000002aab:  59                   pop   cx
0x0000000000002aac:  5B                   pop   bx
0x0000000000002aad:  C3                   ret   
0x0000000000002aae:  53                   push  bx
0x0000000000002aaf:  51                   push  cx
0x0000000000002ab0:  52                   push  dx
0x0000000000002ab1:  56                   push  si
0x0000000000002ab2:  57                   push  di
0x0000000000002ab3:  55                   push  bp
0x0000000000002ab4:  89 E5                mov   bp, sp
0x0000000000002ab6:  83 EC 12             sub   sp, 0x12
0x0000000000002ab9:  89 C6                mov   si, ax
0x0000000000002abb:  6B 5C 22 2C          imul  bx, word ptr [si + 0x22], 0x2c
0x0000000000002abf:  B9 2C 00             mov   cx, 0x2c
0x0000000000002ac2:  8D 87 04 34          lea   ax, [bx + 0x3404]
0x0000000000002ac6:  31 D2                xor   dx, dx
0x0000000000002ac8:  89 46 F6             mov   word ptr [bp - 0xa], ax
0x0000000000002acb:  8D 84 FC CB          lea   ax, [si - 0x3404]
0x0000000000002acf:  F7 F1                div   cx
0x0000000000002ad1:  6B F8 18             imul  di, ax, 0x18
0x0000000000002ad4:  31 D2                xor   dx, dx
0x0000000000002ad6:  89 D8                mov   ax, bx
0x0000000000002ad8:  F7 F1                div   cx
0x0000000000002ada:  6B D8 18             imul  bx, ax, 0x18
0x0000000000002add:  C7 46 EE 5A 01       mov   word ptr [bp - 0x12], 0x15a
0x0000000000002ae2:  C7 46 F0 D9 92       mov   word ptr [bp - 0x10], 0x92d9
0x0000000000002ae7:  C7 46 FE F5 6A       mov   word ptr [bp - 2], 0x6af5
0x0000000000002aec:  C7 46 FA F5 6A       mov   word ptr [bp - 6], 0x6af5
0x0000000000002af1:  8B 56 F6             mov   dx, word ptr [bp - 0xa]
0x0000000000002af4:  89 5E FC             mov   word ptr [bp - 4], bx
0x0000000000002af7:  89 D9                mov   cx, bx
0x0000000000002af9:  89 F0                mov   ax, si
0x0000000000002afb:  89 FB                mov   bx, di
0x0000000000002afd:  FF 1E CC 0C          lcall [0xccc]
0x0000000000002b01:  84 C0                test  al, al
0x0000000000002b03:  74 12                je    0x2b17
0x0000000000002b05:  8E 46 FE             mov   es, word ptr [bp - 2]
0x0000000000002b08:  26 F6 45 14 40       test  byte ptr es:[di + 0x14], 0x40
0x0000000000002b0d:  75 0F                jne   0x2b1e
0x0000000000002b0f:  80 7C 24 00          cmp   byte ptr [si + 0x24], 0
0x0000000000002b13:  74 12                je    0x2b27
0x0000000000002b15:  30 C0                xor   al, al
0x0000000000002b17:  C9                   leave 
0x0000000000002b18:  5F                   pop   di
0x0000000000002b19:  5E                   pop   si
0x0000000000002b1a:  5A                   pop   dx
0x0000000000002b1b:  59                   pop   cx
0x0000000000002b1c:  5B                   pop   bx
0x0000000000002b1d:  C3                   ret   
0x0000000000002b1e:  B0 01                mov   al, 1
0x0000000000002b20:  26 80 65 14 BF       and   byte ptr es:[di + 0x14], 0xbf
0x0000000000002b25:  EB F0                jmp   0x2b17
0x0000000000002b27:  8E 46 FA             mov   es, word ptr [bp - 6]
0x0000000000002b2a:  8B 5E FC             mov   bx, word ptr [bp - 4]
0x0000000000002b2d:  26 8B 07             mov   ax, word ptr es:[bx]
0x0000000000002b30:  89 46 F2             mov   word ptr [bp - 0xe], ax
0x0000000000002b33:  26 8B 47 02          mov   ax, word ptr es:[bx + 2]
0x0000000000002b37:  26 8B 4F 06          mov   cx, word ptr es:[bx + 6]
0x0000000000002b3b:  89 46 F4             mov   word ptr [bp - 0xc], ax
0x0000000000002b3e:  26 8B 47 04          mov   ax, word ptr es:[bx + 4]
0x0000000000002b42:  8E 46 FE             mov   es, word ptr [bp - 2]
0x0000000000002b45:  26 8B 55 04          mov   dx, word ptr es:[di + 4]
0x0000000000002b49:  89 FB                mov   bx, di
0x0000000000002b4b:  29 C2                sub   dx, ax
0x0000000000002b4d:  89 D0                mov   ax, dx
0x0000000000002b4f:  26 8B 57 06          mov   dx, word ptr es:[bx + 6]
0x0000000000002b53:  19 CA                sbb   dx, cx
0x0000000000002b55:  89 D1                mov   cx, dx
0x0000000000002b57:  26 8B 15             mov   dx, word ptr es:[di]
0x0000000000002b5a:  2B 56 F2             sub   dx, word ptr [bp - 0xe]
0x0000000000002b5d:  26 8B 5F 02          mov   bx, word ptr es:[bx + 2]
0x0000000000002b61:  1B 5E F4             sbb   bx, word ptr [bp - 0xc]
0x0000000000002b64:  89 5E F8             mov   word ptr [bp - 8], bx
0x0000000000002b67:  89 C3                mov   bx, ax
0x0000000000002b69:  89 D0                mov   ax, dx
0x0000000000002b6b:  8B 56 F8             mov   dx, word ptr [bp - 8]
0x0000000000002b6e:  FF 1E D0 0C          lcall [0xcd0]
0x0000000000002b72:  8A 44 1A             mov   al, byte ptr [si + 0x1a]
0x0000000000002b75:  30 E4                xor   ah, ah
0x0000000000002b77:  83 EA 40             sub   dx, 0x40
0x0000000000002b7a:  FF 5E EE             lcall [bp - 0x12]
0x0000000000002b7d:  85 C0                test  ax, ax
0x0000000000002b7f:  75 04                jne   0x2b85
0x0000000000002b81:  81 EA 80 00          sub   dx, 0x80
0x0000000000002b85:  80 7C 1A 03          cmp   byte ptr [si + 0x1a], 3
0x0000000000002b89:  75 06                jne   0x2b91
0x0000000000002b8b:  81 FA 80 03          cmp   dx, 0x380
0x0000000000002b8f:  7F 84                jg    0x2b15
0x0000000000002b91:  80 7C 1A 05          cmp   byte ptr [si + 0x1a], 5
0x0000000000002b95:  75 0B                jne   0x2ba2
0x0000000000002b97:  81 FA C4 00          cmp   dx, 0xc4
0x0000000000002b9b:  7D 03                jge   0x2ba0
0x0000000000002b9d:  E9 75 FF             jmp   0x2b15
0x0000000000002ba0:  D1 FA                sar   dx, 1
0x0000000000002ba2:  8A 44 1A             mov   al, byte ptr [si + 0x1a]
0x0000000000002ba5:  3C 15                cmp   al, 0x15
0x0000000000002ba7:  75 2C                jne   0x2bd5
0x0000000000002ba9:  D1 FA                sar   dx, 1
0x0000000000002bab:  81 FA C8 00          cmp   dx, 0xc8
0x0000000000002baf:  7E 03                jle   0x2bb4
0x0000000000002bb1:  BA C8 00             mov   dx, 0xc8
0x0000000000002bb4:  80 7C 1A 15          cmp   byte ptr [si + 0x1a], 0x15
0x0000000000002bb8:  75 09                jne   0x2bc3
0x0000000000002bba:  81 FA A0 00          cmp   dx, 0xa0
0x0000000000002bbe:  7E 03                jle   0x2bc3
0x0000000000002bc0:  BA A0 00             mov   dx, 0xa0
0x0000000000002bc3:  E8 EA 5D             call  0x89b0
0x0000000000002bc6:  30 E4                xor   ah, ah
0x0000000000002bc8:  39 D0                cmp   ax, dx
0x0000000000002bca:  7D 13                jge   0x2bdf
0x0000000000002bcc:  30 C0                xor   al, al
0x0000000000002bce:  C9                   leave 
0x0000000000002bcf:  5F                   pop   di
0x0000000000002bd0:  5E                   pop   si
0x0000000000002bd1:  5A                   pop   dx
0x0000000000002bd2:  59                   pop   cx
0x0000000000002bd3:  5B                   pop   bx
0x0000000000002bd4:  C3                   ret   
0x0000000000002bd5:  3C 13                cmp   al, 0x13
0x0000000000002bd7:  74 D0                je    0x2ba9
0x0000000000002bd9:  3C 12                cmp   al, 0x12
0x0000000000002bdb:  74 CC                je    0x2ba9
0x0000000000002bdd:  EB CC                jmp   0x2bab
0x0000000000002bdf:  B0 01                mov   al, 1
0x0000000000002be1:  C9                   leave 
0x0000000000002be2:  5F                   pop   di
0x0000000000002be3:  5E                   pop   si
0x0000000000002be4:  5A                   pop   dx
0x0000000000002be5:  59                   pop   cx
0x0000000000002be6:  5B                   pop   bx
0x0000000000002be7:  C3                   ret   
0x0000000000002be8:  51                   push  cx
0x0000000000002be9:  2C B6                sub   al, 0xb6
0x0000000000002beb:  2C C8                sub   al, 0xc8
0x0000000000002bed:  2C D0                sub   al, 0xd0
0x0000000000002bef:  2C E5                sub   al, 0xe5
0x0000000000002bf1:  2C EE                sub   al, 0xee
0x0000000000002bf3:  2C 01                sub   al, 1
0x0000000000002bf5:  2D 12 2D             sub   ax, 0x2d12
0x0000000000002bf8:  52                   push  dx
0x0000000000002bf9:  56                   push  si
0x0000000000002bfa:  57                   push  di
0x0000000000002bfb:  55                   push  bp
0x0000000000002bfc:  89 E5                mov   bp, sp
0x0000000000002bfe:  83 EC 0A             sub   sp, 0xa
0x0000000000002c01:  89 C6                mov   si, ax
0x0000000000002c03:  89 DF                mov   di, bx
0x0000000000002c05:  89 4E FC             mov   word ptr [bp - 4], cx
0x0000000000002c08:  80 7C 1F 08          cmp   byte ptr [si + 0x1f], 8
0x0000000000002c0c:  74 41                je    0x2c4f
0x0000000000002c0e:  8E C1                mov   es, cx
0x0000000000002c10:  26 8B 05             mov   ax, word ptr es:[di]
0x0000000000002c13:  89 46 F8             mov   word ptr [bp - 8], ax
0x0000000000002c16:  26 8B 45 04          mov   ax, word ptr es:[di + 4]
0x0000000000002c1a:  89 46 F6             mov   word ptr [bp - 0xa], ax
0x0000000000002c1d:  26 8B 45 06          mov   ax, word ptr es:[di + 6]
0x0000000000002c21:  89 46 FA             mov   word ptr [bp - 6], ax
0x0000000000002c24:  8A 44 1A             mov   al, byte ptr [si + 0x1a]
0x0000000000002c27:  30 E4                xor   ah, ah
0x0000000000002c29:  6B C0 0B             imul  ax, ax, 0xb
0x0000000000002c2c:  26 8B 4D 02          mov   cx, word ptr es:[di + 2]
0x0000000000002c30:  8A 54 1F             mov   dl, byte ptr [si + 0x1f]
0x0000000000002c33:  89 C3                mov   bx, ax
0x0000000000002c35:  8A 87 64 C4          mov   al, byte ptr [bx - 0x3b9c]
0x0000000000002c39:  81 C3 64 C4          add   bx, 0xc464
0x0000000000002c3d:  30 E4                xor   ah, ah
0x0000000000002c3f:  80 FA 07             cmp   dl, 7
0x0000000000002c42:  77 0F                ja    0x2c53
0x0000000000002c44:  30 F6                xor   dh, dh
0x0000000000002c46:  89 D3                mov   bx, dx
0x0000000000002c48:  01 D3                add   bx, dx
0x0000000000002c4a:  2E FF A7 E8 2B       jmp   word ptr cs:[bx + 0x2be8]
0x0000000000002c4f:  EB 61                jmp   0x2cb2
0x0000000000002c51:  01 C1                add   cx, ax
0x0000000000002c53:  FF 76 FA             push  word ptr [bp - 6]
0x0000000000002c56:  FF 76 F6             push  word ptr [bp - 0xa]
0x0000000000002c59:  89 FB                mov   bx, di
0x0000000000002c5b:  51                   push  cx
0x0000000000002c5c:  89 F0                mov   ax, si
0x0000000000002c5e:  FF 76 F8             push  word ptr [bp - 8]
0x0000000000002c61:  8B 4E FC             mov   cx, word ptr [bp - 4]
0x0000000000002c64:  FF 1E DC 0C          lcall [0xcdc]
0x0000000000002c68:  84 C0                test  al, al
0x0000000000002c6a:  75 61                jne   0x2ccd
0x0000000000002c6c:  8E 46 FC             mov   es, word ptr [bp - 4]
0x0000000000002c6f:  26 F6 45 15 40       test  byte ptr es:[di + 0x15], 0x40
0x0000000000002c74:  74 6D                je    0x2ce3
0x0000000000002c76:  BB 2D 01             mov   bx, 0x12d
0x0000000000002c79:  80 3F 00             cmp   byte ptr [bx], 0
0x0000000000002c7c:  74 65                je    0x2ce3
0x0000000000002c7e:  BB 52 01             mov   bx, 0x152
0x0000000000002c81:  8B 17                mov   dx, word ptr [bx]
0x0000000000002c83:  30 F6                xor   dh, dh
0x0000000000002c85:  8B 07                mov   ax, word ptr [bx]
0x0000000000002c87:  80 E2 07             and   dl, 7
0x0000000000002c8a:  C1 F8 03             sar   ax, 3
0x0000000000002c8d:  C1 E2 0D             shl   dx, 0xd
0x0000000000002c90:  26 3B 45 0A          cmp   ax, word ptr es:[di + 0xa]
0x0000000000002c94:  7F 08                jg    0x2c9e
0x0000000000002c96:  75 73                jne   0x2d0b
0x0000000000002c98:  26 3B 55 08          cmp   dx, word ptr es:[di + 8]
0x0000000000002c9c:  76 6D                jbe   0x2d0b
0x0000000000002c9e:  26 83 45 0A 04       add   word ptr es:[di + 0xa], 4
0x0000000000002ca3:  8E 46 FC             mov   es, word ptr [bp - 4]
0x0000000000002ca6:  B0 01                mov   al, 1
0x0000000000002ca8:  26 80 4D 16 20       or    byte ptr es:[di + 0x16], 0x20
0x0000000000002cad:  C9                   leave 
0x0000000000002cae:  5F                   pop   di
0x0000000000002caf:  5E                   pop   si
0x0000000000002cb0:  5A                   pop   dx
0x0000000000002cb1:  C3                   ret   
0x0000000000002cb2:  30 C0                xor   al, al
0x0000000000002cb4:  EB F7                jmp   0x2cad
0x0000000000002cb6:  BA 98 B7             mov   dx, 0xb798
0x0000000000002cb9:  F7 E2                mul   dx
0x0000000000002cbb:  01 46 F8             add   word ptr [bp - 8], ax
0x0000000000002cbe:  11 D1                adc   cx, dx
0x0000000000002cc0:  01 46 F6             add   word ptr [bp - 0xa], ax
0x0000000000002cc3:  11 56 FA             adc   word ptr [bp - 6], dx
0x0000000000002cc6:  EB 8B                jmp   0x2c53
0x0000000000002cc8:  01 46 FA             add   word ptr [bp - 6], ax
0x0000000000002ccb:  EB 86                jmp   0x2c53
0x0000000000002ccd:  E9 A5 00             jmp   0x2d75
0x0000000000002cd0:  BA 98 B7             mov   dx, 0xb798
0x0000000000002cd3:  F7 E2                mul   dx
0x0000000000002cd5:  29 46 F8             sub   word ptr [bp - 8], ax
0x0000000000002cd8:  19 D1                sbb   cx, dx
0x0000000000002cda:  01 46 F6             add   word ptr [bp - 0xa], ax
0x0000000000002cdd:  11 56 FA             adc   word ptr [bp - 6], dx
0x0000000000002ce0:  E9 70 FF             jmp   0x2c53
0x0000000000002ce3:  EB 40                jmp   0x2d25
0x0000000000002ce5:  83 6E F8 00          sub   word ptr [bp - 8], 0
0x0000000000002ce9:  19 C1                sbb   cx, ax
0x0000000000002ceb:  E9 65 FF             jmp   0x2c53
0x0000000000002cee:  BA 98 B7             mov   dx, 0xb798
0x0000000000002cf1:  F7 E2                mul   dx
0x0000000000002cf3:  29 46 F8             sub   word ptr [bp - 8], ax
0x0000000000002cf6:  19 D1                sbb   cx, dx
0x0000000000002cf8:  29 46 F6             sub   word ptr [bp - 0xa], ax
0x0000000000002cfb:  19 56 FA             sbb   word ptr [bp - 6], dx
0x0000000000002cfe:  E9 52 FF             jmp   0x2c53
0x0000000000002d01:  83 6E F6 00          sub   word ptr [bp - 0xa], 0
0x0000000000002d05:  19 46 FA             sbb   word ptr [bp - 6], ax
0x0000000000002d08:  E9 48 FF             jmp   0x2c53
0x0000000000002d0b:  26 83 6D 0A 04       sub   word ptr es:[di + 0xa], 4
0x0000000000002d10:  EB 91                jmp   0x2ca3
0x0000000000002d12:  BA 98 B7             mov   dx, 0xb798
0x0000000000002d15:  F7 E2                mul   dx
0x0000000000002d17:  01 46 F8             add   word ptr [bp - 8], ax
0x0000000000002d1a:  11 D1                adc   cx, dx
0x0000000000002d1c:  29 46 F6             sub   word ptr [bp - 0xa], ax
0x0000000000002d1f:  19 56 FA             sbb   word ptr [bp - 6], dx
0x0000000000002d22:  E9 2E FF             jmp   0x2c53
0x0000000000002d25:  BB 06 07             mov   bx, 0x706
0x0000000000002d28:  83 3F 00             cmp   word ptr [bx], 0
0x0000000000002d2b:  74 85                je    0x2cb2
0x0000000000002d2d:  BB 2C 00             mov   bx, 0x2c
0x0000000000002d30:  8D 84 FC CB          lea   ax, [si - 0x3404]
0x0000000000002d34:  31 D2                xor   dx, dx
0x0000000000002d36:  F7 F3                div   bx
0x0000000000002d38:  C6 46 FE 00          mov   byte ptr [bp - 2], 0
0x0000000000002d3c:  C6 44 1F 08          mov   byte ptr [si + 0x1f], 8
0x0000000000002d40:  89 C7                mov   di, ax
0x0000000000002d42:  BB 06 07             mov   bx, 0x706
0x0000000000002d45:  8B 07                mov   ax, word ptr [bx]
0x0000000000002d47:  89 C2                mov   dx, ax
0x0000000000002d49:  4A                   dec   dx
0x0000000000002d4a:  89 17                mov   word ptr [bx], dx
0x0000000000002d4c:  85 C0                test  ax, ax
0x0000000000002d4e:  74 1D                je    0x2d6d
0x0000000000002d50:  89 D3                mov   bx, dx
0x0000000000002d52:  89 F9                mov   cx, di
0x0000000000002d54:  01 D3                add   bx, dx
0x0000000000002d56:  89 F0                mov   ax, si
0x0000000000002d58:  8B 97 BA 00          mov   dx, word ptr [bx + 0xba]
0x0000000000002d5c:  31 DB                xor   bx, bx
0x0000000000002d5e:  0E                   push  cs
0x0000000000002d5f:  E8 32 54             call  0x8194
0x0000000000002d62:  90                   nop   
0x0000000000002d63:  84 C0                test  al, al
0x0000000000002d65:  74 DB                je    0x2d42
0x0000000000002d67:  C6 46 FE 01          mov   byte ptr [bp - 2], 1
0x0000000000002d6b:  EB D5                jmp   0x2d42
0x0000000000002d6d:  8A 46 FE             mov   al, byte ptr [bp - 2]
0x0000000000002d70:  C9                   leave 
0x0000000000002d71:  5F                   pop   di
0x0000000000002d72:  5E                   pop   si
0x0000000000002d73:  5A                   pop   dx
0x0000000000002d74:  C3                   ret   
0x0000000000002d75:  8E 46 FC             mov   es, word ptr [bp - 4]
0x0000000000002d78:  26 80 65 16 DF       and   byte ptr es:[di + 0x16], 0xdf
0x0000000000002d7d:  26 F6 45 15 40       test  byte ptr es:[di + 0x15], 0x40
0x0000000000002d82:  75 17                jne   0x2d9b
0x0000000000002d84:  8B 44 06             mov   ax, word ptr [si + 6]
0x0000000000002d87:  C1 F8 03             sar   ax, 3
0x0000000000002d8a:  26 89 45 0A          mov   word ptr es:[di + 0xa], ax
0x0000000000002d8e:  8B 44 06             mov   ax, word ptr [si + 6]
0x0000000000002d91:  25 07 00             and   ax, 7
0x0000000000002d94:  C1 E0 0D             shl   ax, 0xd
0x0000000000002d97:  26 89 45 08          mov   word ptr es:[di + 8], ax
0x0000000000002d9b:  B0 01                mov   al, 1
0x0000000000002d9d:  C9                   leave 
0x0000000000002d9e:  5F                   pop   di
0x0000000000002d9f:  5E                   pop   si
0x0000000000002da0:  5A                   pop   dx
0x0000000000002da1:  C3                   ret   
0x0000000000002da2:  56                   push  si
0x0000000000002da3:  89 C6                mov   si, ax
0x0000000000002da5:  E8 50 FE             call  0x2bf8
0x0000000000002da8:  84 C0                test  al, al
0x0000000000002daa:  75 02                jne   0x2dae
0x0000000000002dac:  5E                   pop   si
0x0000000000002dad:  C3                   ret   
0x0000000000002dae:  E8 FF 5B             call  0x89b0
0x0000000000002db1:  88 C3                mov   bl, al
0x0000000000002db3:  80 E3 0F             and   bl, 0xf
0x0000000000002db6:  30 FF                xor   bh, bh
0x0000000000002db8:  B0 01                mov   al, 1
0x0000000000002dba:  89 5C 20             mov   word ptr [si + 0x20], bx
0x0000000000002dbd:  5E                   pop   si
0x0000000000002dbe:  C3                   ret   
0x0000000000002dbf:  FC                   cld   
0x0000000000002dc0:  52                   push  dx
0x0000000000002dc1:  56                   push  si
0x0000000000002dc2:  57                   push  di
0x0000000000002dc3:  55                   push  bp
0x0000000000002dc4:  89 E5                mov   bp, sp
0x0000000000002dc6:  83 EC 16             sub   sp, 0x16
0x0000000000002dc9:  89 C6                mov   si, ax
0x0000000000002dcb:  89 DF                mov   di, bx
0x0000000000002dcd:  89 4E FA             mov   word ptr [bp - 6], cx
0x0000000000002dd0:  8E C1                mov   es, cx
0x0000000000002dd2:  26 8B 05             mov   ax, word ptr es:[di]
0x0000000000002dd5:  89 46 EE             mov   word ptr [bp - 0x12], ax
0x0000000000002dd8:  26 8B 45 02          mov   ax, word ptr es:[di + 2]
0x0000000000002ddc:  89 46 F2             mov   word ptr [bp - 0xe], ax
0x0000000000002ddf:  26 8B 45 04          mov   ax, word ptr es:[di + 4]
0x0000000000002de3:  89 46 F0             mov   word ptr [bp - 0x10], ax
0x0000000000002de6:  8A 44 1F             mov   al, byte ptr [si + 0x1f]
0x0000000000002de9:  88 46 FE             mov   byte ptr [bp - 2], al
0x0000000000002dec:  6B 44 22 2C          imul  ax, word ptr [si + 0x22], 0x2c
0x0000000000002df0:  BB 2C 00             mov   bx, 0x2c
0x0000000000002df3:  31 D2                xor   dx, dx
0x0000000000002df5:  F7 F3                div   bx
0x0000000000002df7:  6B D0 18             imul  dx, ax, 0x18
0x0000000000002dfa:  B8 F5 6A             mov   ax, 0x6af5
0x0000000000002dfd:  26 8B 4D 06          mov   cx, word ptr es:[di + 6]
0x0000000000002e01:  8E C0                mov   es, ax
0x0000000000002e03:  8A 46 FE             mov   al, byte ptr [bp - 2]
0x0000000000002e06:  98                   cwde  
0x0000000000002e07:  89 C3                mov   bx, ax
0x0000000000002e09:  8A 87 96 0E          mov   al, byte ptr [bx + 0xe96]
0x0000000000002e0d:  89 D3                mov   bx, dx
0x0000000000002e0f:  88 46 FC             mov   byte ptr [bp - 4], al
0x0000000000002e12:  26 8B 07             mov   ax, word ptr es:[bx]
0x0000000000002e15:  2B 46 EE             sub   ax, word ptr [bp - 0x12]
0x0000000000002e18:  89 46 F6             mov   word ptr [bp - 0xa], ax
0x0000000000002e1b:  26 8B 47 02          mov   ax, word ptr es:[bx + 2]
0x0000000000002e1f:  1B 46 F2             sbb   ax, word ptr [bp - 0xe]
0x0000000000002e22:  89 46 F8             mov   word ptr [bp - 8], ax
0x0000000000002e25:  26 8B 47 04          mov   ax, word ptr es:[bx + 4]
0x0000000000002e29:  2B 46 F0             sub   ax, word ptr [bp - 0x10]
0x0000000000002e2c:  89 46 F4             mov   word ptr [bp - 0xc], ax
0x0000000000002e2f:  8B 46 F8             mov   ax, word ptr [bp - 8]
0x0000000000002e32:  26 8B 57 06          mov   dx, word ptr es:[bx + 6]
0x0000000000002e36:  19 CA                sbb   dx, cx
0x0000000000002e38:  3D 0A 00             cmp   ax, 0xa
0x0000000000002e3b:  7F 0B                jg    0x2e48
0x0000000000002e3d:  74 03                je    0x2e42
0x0000000000002e3f:  E9 E4 00             jmp   0x2f26
0x0000000000002e42:  83 7E F6 00          cmp   word ptr [bp - 0xa], 0
0x0000000000002e46:  76 F7                jbe   0x2e3f
0x0000000000002e48:  C6 46 EB 00          mov   byte ptr [bp - 0x15], 0
0x0000000000002e4c:  83 FA F6             cmp   dx, -0xa
0x0000000000002e4f:  7D 03                jge   0x2e54
0x0000000000002e51:  E9 E5 00             jmp   0x2f39
0x0000000000002e54:  83 FA 0A             cmp   dx, 0xa
0x0000000000002e57:  7F 0B                jg    0x2e64
0x0000000000002e59:  74 03                je    0x2e5e
0x0000000000002e5b:  E9 E2 00             jmp   0x2f40
0x0000000000002e5e:  83 7E F4 00          cmp   word ptr [bp - 0xc], 0
0x0000000000002e62:  76 F7                jbe   0x2e5b
0x0000000000002e64:  C6 46 EC 02          mov   byte ptr [bp - 0x14], 2
0x0000000000002e68:  80 7E EB 08          cmp   byte ptr [bp - 0x15], 8
0x0000000000002e6c:  74 3F                je    0x2ead
0x0000000000002e6e:  80 7E EC 08          cmp   byte ptr [bp - 0x14], 8
0x0000000000002e72:  74 39                je    0x2ead
0x0000000000002e74:  85 D2                test  dx, dx
0x0000000000002e76:  7D 03                jge   0x2e7b
0x0000000000002e78:  E9 CE 00             jmp   0x2f49
0x0000000000002e7b:  31 DB                xor   bx, bx
0x0000000000002e7d:  89 D8                mov   ax, bx
0x0000000000002e7f:  01 D8                add   ax, bx
0x0000000000002e81:  83 7E F8 00          cmp   word ptr [bp - 8], 0
0x0000000000002e85:  7F 0B                jg    0x2e92
0x0000000000002e87:  74 03                je    0x2e8c
0x0000000000002e89:  E9 C5 00             jmp   0x2f51
0x0000000000002e8c:  83 7E F6 00          cmp   word ptr [bp - 0xa], 0
0x0000000000002e90:  76 F7                jbe   0x2e89
0x0000000000002e92:  BB 01 00             mov   bx, 1
0x0000000000002e95:  01 C3                add   bx, ax
0x0000000000002e97:  8A 87 9F 0E          mov   al, byte ptr [bx + 0xe9f]
0x0000000000002e9b:  88 C3                mov   bl, al
0x0000000000002e9d:  88 44 1F             mov   byte ptr [si + 0x1f], al
0x0000000000002ea0:  8A 46 FC             mov   al, byte ptr [bp - 4]
0x0000000000002ea3:  30 FF                xor   bh, bh
0x0000000000002ea5:  98                   cwde  
0x0000000000002ea6:  39 C3                cmp   bx, ax
0x0000000000002ea8:  74 03                je    0x2ead
0x0000000000002eaa:  E9 A9 00             jmp   0x2f56
0x0000000000002ead:  E8 00 5B             call  0x89b0
0x0000000000002eb0:  3C C8                cmp   al, 0xc8
0x0000000000002eb2:  77 03                ja    0x2eb7
0x0000000000002eb4:  E9 B8 00             jmp   0x2f6f
0x0000000000002eb7:  8A 46 EB             mov   al, byte ptr [bp - 0x15]
0x0000000000002eba:  8A 66 EC             mov   ah, byte ptr [bp - 0x14]
0x0000000000002ebd:  88 66 EB             mov   byte ptr [bp - 0x15], ah
0x0000000000002ec0:  88 46 EC             mov   byte ptr [bp - 0x14], al
0x0000000000002ec3:  8A 46 EB             mov   al, byte ptr [bp - 0x15]
0x0000000000002ec6:  3A 46 FC             cmp   al, byte ptr [bp - 4]
0x0000000000002ec9:  75 04                jne   0x2ecf
0x0000000000002ecb:  C6 46 EB 08          mov   byte ptr [bp - 0x15], 8
0x0000000000002ecf:  8A 46 EC             mov   al, byte ptr [bp - 0x14]
0x0000000000002ed2:  3A 46 FC             cmp   al, byte ptr [bp - 4]
0x0000000000002ed5:  75 04                jne   0x2edb
0x0000000000002ed7:  C6 46 EC 08          mov   byte ptr [bp - 0x14], 8
0x0000000000002edb:  8A 46 EB             mov   al, byte ptr [bp - 0x15]
0x0000000000002ede:  3C 08                cmp   al, 8
0x0000000000002ee0:  75 65                jne   0x2f47
0x0000000000002ee2:  8A 46 EC             mov   al, byte ptr [bp - 0x14]
0x0000000000002ee5:  3C 08                cmp   al, 8
0x0000000000002ee7:  75 66                jne   0x2f4f
0x0000000000002ee9:  8A 46 FE             mov   al, byte ptr [bp - 2]
0x0000000000002eec:  3C 08                cmp   al, 8
0x0000000000002eee:  74 11                je    0x2f01
0x0000000000002ef0:  8B 4E FA             mov   cx, word ptr [bp - 6]
0x0000000000002ef3:  89 FB                mov   bx, di
0x0000000000002ef5:  88 44 1F             mov   byte ptr [si + 0x1f], al
0x0000000000002ef8:  89 F0                mov   ax, si
0x0000000000002efa:  E8 A5 FE             call  0x2da2
0x0000000000002efd:  84 C0                test  al, al
0x0000000000002eff:  75 20                jne   0x2f21
0x0000000000002f01:  E8 AC 5A             call  0x89b0
0x0000000000002f04:  A8 01                test  al, 1
0x0000000000002f06:  74 5F                je    0x2f67
0x0000000000002f08:  30 D2                xor   dl, dl
0x0000000000002f0a:  3A 56 FC             cmp   dl, byte ptr [bp - 4]
0x0000000000002f0d:  75 5B                jne   0x2f6a
0x0000000000002f0f:  FE C2                inc   dl
0x0000000000002f11:  80 FA 07             cmp   dl, 7
0x0000000000002f14:  7E F4                jle   0x2f0a
0x0000000000002f16:  8A 46 FC             mov   al, byte ptr [bp - 4]
0x0000000000002f19:  3C 08                cmp   al, 8
0x0000000000002f1b:  75 4F                jne   0x2f6c
0x0000000000002f1d:  C6 44 1F 08          mov   byte ptr [si + 0x1f], 8
0x0000000000002f21:  C9                   leave 
0x0000000000002f22:  5F                   pop   di
0x0000000000002f23:  5E                   pop   si
0x0000000000002f24:  5A                   pop   dx
0x0000000000002f25:  C3                   ret   
0x0000000000002f26:  3D F6 FF             cmp   ax, 0xfff6
0x0000000000002f29:  7C 07                jl    0x2f32
0x0000000000002f2b:  C6 46 EB 08          mov   byte ptr [bp - 0x15], 8
0x0000000000002f2f:  E9 1A FF             jmp   0x2e4c
0x0000000000002f32:  C6 46 EB 04          mov   byte ptr [bp - 0x15], 4
0x0000000000002f36:  E9 13 FF             jmp   0x2e4c
0x0000000000002f39:  C6 46 EC 06          mov   byte ptr [bp - 0x14], 6
0x0000000000002f3d:  E9 28 FF             jmp   0x2e68
0x0000000000002f40:  C6 46 EC 08          mov   byte ptr [bp - 0x14], 8
0x0000000000002f44:  E9 21 FF             jmp   0x2e68
0x0000000000002f47:  EB 5C                jmp   0x2fa5
0x0000000000002f49:  BB 01 00             mov   bx, 1
0x0000000000002f4c:  E9 2E FF             jmp   0x2e7d
0x0000000000002f4f:  EB 6B                jmp   0x2fbc
0x0000000000002f51:  31 DB                xor   bx, bx
0x0000000000002f53:  E9 3F FF             jmp   0x2e95
0x0000000000002f56:  8B 4E FA             mov   cx, word ptr [bp - 6]
0x0000000000002f59:  89 FB                mov   bx, di
0x0000000000002f5b:  89 F0                mov   ax, si
0x0000000000002f5d:  E8 42 FE             call  0x2da2
0x0000000000002f60:  84 C0                test  al, al
0x0000000000002f62:  75 BD                jne   0x2f21
0x0000000000002f64:  E9 46 FF             jmp   0x2ead
0x0000000000002f67:  E9 7A 00             jmp   0x2fe4
0x0000000000002f6a:  EB 64                jmp   0x2fd0
0x0000000000002f6c:  E9 9A 00             jmp   0x3009
0x0000000000002f6f:  8B 46 F4             mov   ax, word ptr [bp - 0xc]
0x0000000000002f72:  0B D2                or    dx, dx
0x0000000000002f74:  7D 07                jge   0x2f7d
0x0000000000002f76:  F7 D8                neg   ax
0x0000000000002f78:  83 D2 00             adc   dx, 0
0x0000000000002f7b:  F7 DA                neg   dx
0x0000000000002f7d:  89 C1                mov   cx, ax
0x0000000000002f7f:  89 D3                mov   bx, dx
0x0000000000002f81:  8B 46 F6             mov   ax, word ptr [bp - 0xa]
0x0000000000002f84:  8B 56 F8             mov   dx, word ptr [bp - 8]
0x0000000000002f87:  0B D2                or    dx, dx
0x0000000000002f89:  7D 07                jge   0x2f92
0x0000000000002f8b:  F7 D8                neg   ax
0x0000000000002f8d:  83 D2 00             adc   dx, 0
0x0000000000002f90:  F7 DA                neg   dx
0x0000000000002f92:  39 D3                cmp   bx, dx
0x0000000000002f94:  7E 03                jle   0x2f99
0x0000000000002f96:  E9 1E FF             jmp   0x2eb7
0x0000000000002f99:  74 03                je    0x2f9e
0x0000000000002f9b:  E9 25 FF             jmp   0x2ec3
0x0000000000002f9e:  39 C1                cmp   cx, ax
0x0000000000002fa0:  77 F4                ja    0x2f96
0x0000000000002fa2:  E9 1E FF             jmp   0x2ec3
0x0000000000002fa5:  8B 4E FA             mov   cx, word ptr [bp - 6]
0x0000000000002fa8:  89 FB                mov   bx, di
0x0000000000002faa:  88 44 1F             mov   byte ptr [si + 0x1f], al
0x0000000000002fad:  89 F0                mov   ax, si
0x0000000000002faf:  E8 F0 FD             call  0x2da2
0x0000000000002fb2:  84 C0                test  al, al
0x0000000000002fb4:  74 03                je    0x2fb9
0x0000000000002fb6:  E9 68 FF             jmp   0x2f21
0x0000000000002fb9:  E9 26 FF             jmp   0x2ee2
0x0000000000002fbc:  8B 4E FA             mov   cx, word ptr [bp - 6]
0x0000000000002fbf:  89 FB                mov   bx, di
0x0000000000002fc1:  88 44 1F             mov   byte ptr [si + 0x1f], al
0x0000000000002fc4:  89 F0                mov   ax, si
0x0000000000002fc6:  E8 D9 FD             call  0x2da2
0x0000000000002fc9:  84 C0                test  al, al
0x0000000000002fcb:  75 E9                jne   0x2fb6
0x0000000000002fcd:  E9 19 FF             jmp   0x2ee9
0x0000000000002fd0:  8B 4E FA             mov   cx, word ptr [bp - 6]
0x0000000000002fd3:  89 FB                mov   bx, di
0x0000000000002fd5:  89 F0                mov   ax, si
0x0000000000002fd7:  88 54 1F             mov   byte ptr [si + 0x1f], dl
0x0000000000002fda:  E8 C5 FD             call  0x2da2
0x0000000000002fdd:  84 C0                test  al, al
0x0000000000002fdf:  75 D5                jne   0x2fb6
0x0000000000002fe1:  E9 2B FF             jmp   0x2f0f
0x0000000000002fe4:  B2 07                mov   dl, 7
0x0000000000002fe6:  3A 56 FC             cmp   dl, byte ptr [bp - 4]
0x0000000000002fe9:  75 0A                jne   0x2ff5
0x0000000000002feb:  FE CA                dec   dl
0x0000000000002fed:  80 FA FF             cmp   dl, 0xff
0x0000000000002ff0:  75 F4                jne   0x2fe6
0x0000000000002ff2:  E9 21 FF             jmp   0x2f16
0x0000000000002ff5:  8B 4E FA             mov   cx, word ptr [bp - 6]
0x0000000000002ff8:  89 FB                mov   bx, di
0x0000000000002ffa:  89 F0                mov   ax, si
0x0000000000002ffc:  88 54 1F             mov   byte ptr [si + 0x1f], dl
0x0000000000002fff:  E8 A0 FD             call  0x2da2
0x0000000000003002:  84 C0                test  al, al
0x0000000000003004:  74 E5                je    0x2feb
0x0000000000003006:  E9 18 FF             jmp   0x2f21
0x0000000000003009:  8B 4E FA             mov   cx, word ptr [bp - 6]
0x000000000000300c:  89 FB                mov   bx, di
0x000000000000300e:  88 44 1F             mov   byte ptr [si + 0x1f], al
0x0000000000003011:  89 F0                mov   ax, si
0x0000000000003013:  E8 8C FD             call  0x2da2
0x0000000000003016:  84 C0                test  al, al
0x0000000000003018:  75 9C                jne   0x2fb6
0x000000000000301a:  C6 44 1F 08          mov   byte ptr [si + 0x1f], 8
0x000000000000301e:  C9                   leave 
0x000000000000301f:  5F                   pop   di
0x0000000000003020:  5E                   pop   si
0x0000000000003021:  5A                   pop   dx
0x0000000000003022:  C3                   ret   
0x0000000000003023:  FC                   cld   
0x0000000000003024:  53                   push  bx
0x0000000000003025:  51                   push  cx
0x0000000000003026:  56                   push  si
0x0000000000003027:  57                   push  di
0x0000000000003028:  55                   push  bp
0x0000000000003029:  89 E5                mov   bp, sp
0x000000000000302b:  83 EC 06             sub   sp, 6
0x000000000000302e:  89 C7                mov   di, ax
0x0000000000003030:  88 56 FE             mov   byte ptr [bp - 2], dl
0x0000000000003033:  BB E8 07             mov   bx, 0x7e8
0x0000000000003036:  83 3F 00             cmp   word ptr [bx], 0
0x0000000000003039:  7F 08                jg    0x3043
0x000000000000303b:  30 C0                xor   al, al
0x000000000000303d:  C9                   leave 
0x000000000000303e:  5F                   pop   di
0x000000000000303f:  5E                   pop   si
0x0000000000003040:  59                   pop   cx
0x0000000000003041:  5B                   pop   bx
0x0000000000003042:  C3                   ret   
0x0000000000003043:  BB 2C 00             mov   bx, 0x2c
0x0000000000003046:  2D 04 34             sub   ax, 0x3404
0x0000000000003049:  31 D2                xor   dx, dx
0x000000000000304b:  F7 F3                div   bx
0x000000000000304d:  6B F0 18             imul  si, ax, 0x18
0x0000000000003050:  BB 30 07             mov   bx, 0x730
0x0000000000003053:  8B 0F                mov   cx, word ptr [bx]
0x0000000000003055:  BB EC 06             mov   bx, 0x6ec
0x0000000000003058:  C7 46 FC F5 6A       mov   word ptr [bp - 4], 0x6af5
0x000000000000305d:  8B 17                mov   dx, word ptr [bx]
0x000000000000305f:  89 F3                mov   bx, si
0x0000000000003061:  89 F8                mov   ax, di
0x0000000000003063:  FF 1E CC 0C          lcall [0xccc]
0x0000000000003067:  84 C0                test  al, al
0x0000000000003069:  74 D2                je    0x303d
0x000000000000306b:  80 7E FE 00          cmp   byte ptr [bp - 2], 0
0x000000000000306f:  74 10                je    0x3081
0x0000000000003071:  BB F6 06             mov   bx, 0x6f6
0x0000000000003074:  8B 07                mov   ax, word ptr [bx]
0x0000000000003076:  89 45 22             mov   word ptr [di + 0x22], ax
0x0000000000003079:  B0 01                mov   al, 1
0x000000000000307b:  C9                   leave 
0x000000000000307c:  5F                   pop   di
0x000000000000307d:  5E                   pop   si
0x000000000000307e:  59                   pop   cx
0x000000000000307f:  5B                   pop   bx
0x0000000000003080:  C3                   ret   
0x0000000000003081:  BB 30 07             mov   bx, 0x730
0x0000000000003084:  C4 07                les   ax, ptr [bx]
0x0000000000003086:  89 C3                mov   bx, ax
0x0000000000003088:  26 FF 77 06          push  word ptr es:[bx + 6]
0x000000000000308c:  26 FF 77 04          push  word ptr es:[bx + 4]
0x0000000000003090:  BB 30 07             mov   bx, 0x730
0x0000000000003093:  C4 07                les   ax, ptr [bx]
0x0000000000003095:  89 C3                mov   bx, ax
0x0000000000003097:  26 FF 77 02          push  word ptr es:[bx + 2]
0x000000000000309b:  26 FF 37             push  word ptr es:[bx]
0x000000000000309e:  8E 46 FC             mov   es, word ptr [bp - 4]
0x00000000000030a1:  26 8B 5C 04          mov   bx, word ptr es:[si + 4]
0x00000000000030a5:  26 8B 4C 06          mov   cx, word ptr es:[si + 6]
0x00000000000030a9:  26 8B 04             mov   ax, word ptr es:[si]
0x00000000000030ac:  26 8B 54 02          mov   dx, word ptr es:[si + 2]
0x00000000000030b0:  0E                   push  cs
0x00000000000030b1:  E8 85 70             call  0xa139
0x00000000000030b4:  90                   nop   
0x00000000000030b5:  8E 46 FC             mov   es, word ptr [bp - 4]
0x00000000000030b8:  89 C1                mov   cx, ax
0x00000000000030ba:  89 F3                mov   bx, si
0x00000000000030bc:  89 D0                mov   ax, dx
0x00000000000030be:  26 2B 4C 0E          sub   cx, word ptr es:[si + 0xe]
0x00000000000030c2:  26 1B 47 10          sbb   ax, word ptr es:[bx + 0x10]
0x00000000000030c6:  3D 00 40             cmp   ax, 0x4000
0x00000000000030c9:  77 06                ja    0x30d1
0x00000000000030cb:  75 A4                jne   0x3071
0x00000000000030cd:  85 C9                test  cx, cx
0x00000000000030cf:  76 A0                jbe   0x3071
0x00000000000030d1:  3D 00 C0             cmp   ax, 0xc000
0x00000000000030d4:  73 9B                jae   0x3071
0x00000000000030d6:  BB 30 07             mov   bx, 0x730
0x00000000000030d9:  C4 17                les   dx, ptr [bx]
0x00000000000030db:  89 D3                mov   bx, dx
0x00000000000030dd:  26 8B 47 04          mov   ax, word ptr es:[bx + 4]
0x00000000000030e1:  26 8B 4F 06          mov   cx, word ptr es:[bx + 6]
0x00000000000030e5:  8E 46 FC             mov   es, word ptr [bp - 4]
0x00000000000030e8:  89 46 FA             mov   word ptr [bp - 6], ax
0x00000000000030eb:  26 8B 44 04          mov   ax, word ptr es:[si + 4]
0x00000000000030ef:  89 F3                mov   bx, si
0x00000000000030f1:  29 46 FA             sub   word ptr [bp - 6], ax
0x00000000000030f4:  26 1B 4F 06          sbb   cx, word ptr es:[bx + 6]
0x00000000000030f8:  BB 30 07             mov   bx, 0x730
0x00000000000030fb:  C4 17                les   dx, ptr [bx]
0x00000000000030fd:  89 D3                mov   bx, dx
0x00000000000030ff:  26 8B 07             mov   ax, word ptr es:[bx]
0x0000000000003102:  26 8B 57 02          mov   dx, word ptr es:[bx + 2]
0x0000000000003106:  8E 46 FC             mov   es, word ptr [bp - 4]
0x0000000000003109:  89 F3                mov   bx, si
0x000000000000310b:  26 2B 04             sub   ax, word ptr es:[si]
0x000000000000310e:  26 1B 57 02          sbb   dx, word ptr es:[bx + 2]
0x0000000000003112:  8B 5E FA             mov   bx, word ptr [bp - 6]
0x0000000000003115:  FF 1E D0 0C          lcall [0xcd0]
0x0000000000003119:  83 FA 40             cmp   dx, 0x40
0x000000000000311c:  7E 03                jle   0x3121
0x000000000000311e:  E9 1A FF             jmp   0x303b
0x0000000000003121:  74 03                je    0x3126
0x0000000000003123:  E9 4B FF             jmp   0x3071
0x0000000000003126:  85 C0                test  ax, ax
0x0000000000003128:  76 F9                jbe   0x3123
0x000000000000312a:  30 C0                xor   al, al
0x000000000000312c:  C9                   leave 
0x000000000000312d:  5F                   pop   di
0x000000000000312e:  5E                   pop   si
0x000000000000312f:  59                   pop   cx
0x0000000000003130:  5B                   pop   bx
0x0000000000003131:  C3                   ret   
0x0000000000003132:  52                   push  dx
0x0000000000003133:  56                   push  si
0x0000000000003134:  55                   push  bp
0x0000000000003135:  89 E5                mov   bp, sp
0x0000000000003137:  83 EC 02             sub   sp, 2
0x000000000000313a:  89 C6                mov   si, ax
0x000000000000313c:  8E C1                mov   es, cx
0x000000000000313e:  B9 2C 00             mov   cx, 0x2c
0x0000000000003141:  8A 44 1A             mov   al, byte ptr [si + 0x1a]
0x0000000000003144:  31 D2                xor   dx, dx
0x0000000000003146:  88 46 FE             mov   byte ptr [bp - 2], al
0x0000000000003149:  8D 84 FC CB          lea   ax, [si - 0x3404]
0x000000000000314d:  F7 F1                div   cx
0x000000000000314f:  26 80 67 14 FD       and   byte ptr es:[bx + 0x14], 0xfd
0x0000000000003154:  BB 02 34             mov   bx, 0x3402
0x0000000000003157:  89 C1                mov   cx, ax
0x0000000000003159:  8B 07                mov   ax, word ptr [bx]
0x000000000000315b:  85 C0                test  ax, ax
0x000000000000315d:  74 1D                je    0x317c
0x000000000000315f:  6B D8 2C             imul  bx, ax, 0x2c
0x0000000000003162:  8B 97 00 34          mov   dx, word ptr [bx + 0x3400]
0x0000000000003166:  30 D2                xor   dl, dl
0x0000000000003168:  80 E6 F8             and   dh, 0xf8
0x000000000000316b:  81 FA 00 08          cmp   dx, 0x800
0x000000000000316f:  74 1A                je    0x318b
0x0000000000003171:  6B D8 2C             imul  bx, ax, 0x2c
0x0000000000003174:  8B 87 02 34          mov   ax, word ptr [bx + 0x3402]
0x0000000000003178:  85 C0                test  ax, ax
0x000000000000317a:  75 E3                jne   0x315f
0x000000000000317c:  BA 03 00             mov   dx, 3
0x000000000000317f:  B8 3D 00             mov   ax, 0x3d
0x0000000000003182:  0E                   push  cs
0x0000000000003183:  E8 FE F2             call  0x2484
0x0000000000003186:  90                   nop   
0x0000000000003187:  C9                   leave 
0x0000000000003188:  5E                   pop   si
0x0000000000003189:  5A                   pop   dx
0x000000000000318a:  C3                   ret   
0x000000000000318b:  81 C3 04 34          add   bx, 0x3404
0x000000000000318f:  39 C8                cmp   ax, cx
0x0000000000003191:  74 DE                je    0x3171
0x0000000000003193:  8A 57 1A             mov   dl, byte ptr [bx + 0x1a]
0x0000000000003196:  3A 56 FE             cmp   dl, byte ptr [bp - 2]
0x0000000000003199:  75 D6                jne   0x3171
0x000000000000319b:  83 7F 1C 00          cmp   word ptr [bx + 0x1c], 0
0x000000000000319f:  7F E6                jg    0x3187
0x00000000000031a1:  EB CE                jmp   0x3171
0x00000000000031a3:  FC                   cld   
0x00000000000031a4:  52                   push  dx
0x00000000000031a5:  56                   push  si
0x00000000000031a6:  57                   push  di
0x00000000000031a7:  55                   push  bp
0x00000000000031a8:  89 E5                mov   bp, sp
0x00000000000031aa:  83 EC 08             sub   sp, 8
0x00000000000031ad:  89 C6                mov   si, ax
0x00000000000031af:  C7 46 F8 50 03       mov   word ptr [bp - 8], 0x350
0x00000000000031b4:  B8 56 4C             mov   ax, 0x4c56
0x00000000000031b7:  8B 7C 04             mov   di, word ptr [si + 4]
0x00000000000031ba:  C6 44 25 00          mov   byte ptr [si + 0x25], 0
0x00000000000031be:  8E C0                mov   es, ax
0x00000000000031c0:  C7 46 FA D9 92       mov   word ptr [bp - 6], 0x92d9
0x00000000000031c5:  26 80 3D 00          cmp   byte ptr es:[di], 0
0x00000000000031c9:  75 03                jne   0x31ce
0x00000000000031cb:  E9 93 00             jmp   0x3261
0x00000000000031ce:  BF F6 06             mov   di, 0x6f6
0x00000000000031d1:  8B 05                mov   ax, word ptr [di]
0x00000000000031d3:  85 C0                test  ax, ax
0x00000000000031d5:  74 F4                je    0x31cb
0x00000000000031d7:  6B F8 18             imul  di, ax, 0x18
0x00000000000031da:  BA F5 6A             mov   dx, 0x6af5
0x00000000000031dd:  8E C2                mov   es, dx
0x00000000000031df:  6B D0 2C             imul  dx, ax, 0x2c
0x00000000000031e2:  81 C2 04 34          add   dx, 0x3404
0x00000000000031e6:  26 F6 45 14 04       test  byte ptr es:[di + 0x14], 4
0x00000000000031eb:  74 DE                je    0x31cb
0x00000000000031ed:  89 44 22             mov   word ptr [si + 0x22], ax
0x00000000000031f0:  8E C1                mov   es, cx
0x00000000000031f2:  26 F6 47 14 20       test  byte ptr es:[bx + 0x14], 0x20
0x00000000000031f7:  74 0C                je    0x3205
0x00000000000031f9:  89 F9                mov   cx, di
0x00000000000031fb:  89 F0                mov   ax, si
0x00000000000031fd:  FF 1E CC 0C          lcall [0xccc]
0x0000000000003201:  84 C0                test  al, al
0x0000000000003203:  74 5C                je    0x3261
0x0000000000003205:  8A 44 1A             mov   al, byte ptr [si + 0x1a]
0x0000000000003208:  30 E4                xor   ah, ah
0x000000000000320a:  6B C0 0B             imul  ax, ax, 0xb
0x000000000000320d:  C7 46 FE 00 00       mov   word ptr [bp - 2], 0
0x0000000000003212:  89 C3                mov   bx, ax
0x0000000000003214:  89 46 FC             mov   word ptr [bp - 4], ax
0x0000000000003217:  8A 87 62 C4          mov   al, byte ptr [bx - 0x3b9e]
0x000000000000321b:  81 C3 62 C4          add   bx, 0xc462
0x000000000000321f:  84 C0                test  al, al
0x0000000000003221:  74 28                je    0x324b
0x0000000000003223:  3C 24                cmp   al, 0x24
0x0000000000003225:  73 47                jae   0x326e
0x0000000000003227:  8A 44 1A             mov   al, byte ptr [si + 0x1a]
0x000000000000322a:  30 E4                xor   ah, ah
0x000000000000322c:  6B C0 0B             imul  ax, ax, 0xb
0x000000000000322f:  89 C3                mov   bx, ax
0x0000000000003231:  81 C3 62 C4          add   bx, 0xc462
0x0000000000003235:  8A 1F                mov   bl, byte ptr [bx]
0x0000000000003237:  30 FF                xor   bh, bh
0x0000000000003239:  8A 44 1A             mov   al, byte ptr [si + 0x1a]
0x000000000000323c:  3C 13                cmp   al, 0x13
0x000000000000323e:  75 66                jne   0x32a6
0x0000000000003240:  88 DA                mov   dl, bl
0x0000000000003242:  31 C0                xor   ax, ax
0x0000000000003244:  30 F6                xor   dh, dh
0x0000000000003246:  0E                   push  cs
0x0000000000003247:  E8 06 D3             call  0x550
0x000000000000324a:  90                   nop   
0x000000000000324b:  8A 44 1A             mov   al, byte ptr [si + 0x1a]
0x000000000000324e:  30 E4                xor   ah, ah
0x0000000000003250:  FF 5E F8             lcall [bp - 8]
0x0000000000003253:  89 C2                mov   dx, ax
0x0000000000003255:  89 F0                mov   ax, si
0x0000000000003257:  0E                   push  cs
0x0000000000003258:  3E E8 92 5D          call  0x8fee
0x000000000000325c:  C9                   leave 
0x000000000000325d:  5F                   pop   di
0x000000000000325e:  5E                   pop   si
0x000000000000325f:  5A                   pop   dx
0x0000000000003260:  C3                   ret   
0x0000000000003261:  89 F0                mov   ax, si
0x0000000000003263:  31 D2                xor   dx, dx
0x0000000000003265:  E8 BC FD             call  0x3024
0x0000000000003268:  84 C0                test  al, al
0x000000000000326a:  74 F0                je    0x325c
0x000000000000326c:  EB 97                jmp   0x3205
0x000000000000326e:  3C 26                cmp   al, 0x26
0x0000000000003270:  76 22                jbe   0x3294
0x0000000000003272:  3C 28                cmp   al, 0x28
0x0000000000003274:  77 B1                ja    0x3227
0x0000000000003276:  E8 37 57             call  0x89b0
0x0000000000003279:  88 C2                mov   dl, al
0x000000000000327b:  30 F6                xor   dh, dh
0x000000000000327d:  89 D0                mov   ax, dx
0x000000000000327f:  89 D3                mov   bx, dx
0x0000000000003281:  C1 F8 0F             sar   ax, 0xf
0x0000000000003284:  31 C3                xor   bx, ax
0x0000000000003286:  29 C3                sub   bx, ax
0x0000000000003288:  83 E3 01             and   bx, 1
0x000000000000328b:  31 C3                xor   bx, ax
0x000000000000328d:  29 C3                sub   bx, ax
0x000000000000328f:  83 C3 27             add   bx, 0x27
0x0000000000003292:  EB A5                jmp   0x3239
0x0000000000003294:  E8 19 57             call  0x89b0
0x0000000000003297:  30 E4                xor   ah, ah
0x0000000000003299:  BB 03 00             mov   bx, 3
0x000000000000329c:  99                   cdq   
0x000000000000329d:  F7 FB                idiv  bx
0x000000000000329f:  89 D3                mov   bx, dx
0x00000000000032a1:  83 C3 24             add   bx, 0x24
0x00000000000032a4:  EB 93                jmp   0x3239
0x00000000000032a6:  3C 15                cmp   al, 0x15
0x00000000000032a8:  74 96                je    0x3240
0x00000000000032aa:  88 DA                mov   dl, bl
0x00000000000032ac:  89 F0                mov   ax, si
0x00000000000032ae:  EB 94                jmp   0x3244
0x00000000000032b0:  52                   push  dx
0x00000000000032b1:  56                   push  si
0x00000000000032b2:  57                   push  di
0x00000000000032b3:  55                   push  bp
0x00000000000032b4:  89 E5                mov   bp, sp
0x00000000000032b6:  83 EC 14             sub   sp, 0x14
0x00000000000032b9:  89 C6                mov   si, ax
0x00000000000032bb:  89 DF                mov   di, bx
0x00000000000032bd:  89 4E FE             mov   word ptr [bp - 2], cx
0x00000000000032c0:  8B 44 22             mov   ax, word ptr [si + 0x22]
0x00000000000032c3:  6B D0 2C             imul  dx, ax, 0x2c
0x00000000000032c6:  6B C8 18             imul  cx, ax, 0x18
0x00000000000032c9:  C7 46 FC F5 6A       mov   word ptr [bp - 4], 0x6af5
0x00000000000032ce:  C7 46 F0 F4 03       mov   word ptr [bp - 0x10], 0x3f4
0x00000000000032d3:  C7 46 F2 D9 92       mov   word ptr [bp - 0xe], 0x92d9
0x00000000000032d8:  C7 46 F4 5A 01       mov   word ptr [bp - 0xc], 0x15a
0x00000000000032dd:  C7 46 F6 D9 92       mov   word ptr [bp - 0xa], 0x92d9
0x00000000000032e2:  C7 46 EC 22 02       mov   word ptr [bp - 0x14], 0x222
0x00000000000032e7:  C7 46 EE D9 92       mov   word ptr [bp - 0x12], 0x92d9
0x00000000000032ec:  C7 46 F8 B8 02       mov   word ptr [bp - 8], 0x2b8
0x00000000000032f1:  C7 46 FA D9 92       mov   word ptr [bp - 6], 0x92d9
0x00000000000032f6:  81 C2 04 34          add   dx, 0x3404
0x00000000000032fa:  80 7C 24 00          cmp   byte ptr [si + 0x24], 0
0x00000000000032fe:  74 03                je    0x3303
0x0000000000003300:  E9 77 00             jmp   0x337a
0x0000000000003303:  80 7C 25 00          cmp   byte ptr [si + 0x25], 0
0x0000000000003307:  74 0B                je    0x3314
0x0000000000003309:  85 C0                test  ax, ax
0x000000000000330b:  74 03                je    0x3310
0x000000000000330d:  E9 6F 00             jmp   0x337f
0x0000000000003310:  C6 44 25 00          mov   byte ptr [si + 0x25], 0
0x0000000000003314:  80 7C 1F 08          cmp   byte ptr [si + 0x1f], 8
0x0000000000003318:  73 2E                jae   0x3348
0x000000000000331a:  8E 46 FE             mov   es, word ptr [bp - 2]
0x000000000000331d:  26 C6 45 10 00       mov   byte ptr es:[di + 0x10], 0
0x0000000000003322:  26 C7 45 0E 00 00    mov   word ptr es:[di + 0xe], 0
0x0000000000003328:  26 80 65 11 E0       and   byte ptr es:[di + 0x11], 0xe0
0x000000000000332d:  8A 44 1F             mov   al, byte ptr [si + 0x1f]
0x0000000000003330:  30 E4                xor   ah, ah
0x0000000000003332:  89 C3                mov   bx, ax
0x0000000000003334:  01 C3                add   bx, ax
0x0000000000003336:  26 8B 45 10          mov   ax, word ptr es:[di + 0x10]
0x000000000000333a:  2B 87 A0 04          sub   ax, word ptr [bx + 0x4a0]
0x000000000000333e:  85 C0                test  ax, ax
0x0000000000003340:  7E 4A                jle   0x338c
0x0000000000003342:  26 81 6D 10 00 20    sub   word ptr es:[di + 0x10], 0x2000
0x0000000000003348:  85 D2                test  dx, dx
0x000000000000334a:  74 49                je    0x3395
0x000000000000334c:  8E 46 FC             mov   es, word ptr [bp - 4]
0x000000000000334f:  89 CB                mov   bx, cx
0x0000000000003351:  26 F6 47 14 04       test  byte ptr es:[bx + 0x14], 4
0x0000000000003356:  74 3D                je    0x3395
0x0000000000003358:  8E 46 FE             mov   es, word ptr [bp - 2]
0x000000000000335b:  26 F6 45 14 80       test  byte ptr es:[di + 0x14], 0x80
0x0000000000003360:  74 65                je    0x33c7
0x0000000000003362:  26 80 65 14 7F       and   byte ptr es:[di + 0x14], 0x7f
0x0000000000003367:  80 3E 14 22 04       cmp   byte ptr [0x2214], 4
0x000000000000336c:  74 07                je    0x3375
0x000000000000336e:  80 3E 2F 22 00       cmp   byte ptr [0x222f], 0
0x0000000000003373:  74 47                je    0x33bc
0x0000000000003375:  C9                   leave 
0x0000000000003376:  5F                   pop   di
0x0000000000003377:  5E                   pop   si
0x0000000000003378:  5A                   pop   dx
0x0000000000003379:  C3                   ret   
0x000000000000337a:  FE 4C 24             dec   byte ptr [si + 0x24]
0x000000000000337d:  EB 84                jmp   0x3303
0x000000000000337f:  89 D3                mov   bx, dx
0x0000000000003381:  83 7F 1C 00          cmp   word ptr [bx + 0x1c], 0
0x0000000000003385:  7E 89                jle   0x3310
0x0000000000003387:  FE 4C 25             dec   byte ptr [si + 0x25]
0x000000000000338a:  EB 88                jmp   0x3314
0x000000000000338c:  7D BA                jge   0x3348
0x000000000000338e:  26 80 45 11 20       add   byte ptr es:[di + 0x11], 0x20
0x0000000000003393:  EB B3                jmp   0x3348
0x0000000000003395:  BA 01 00             mov   dx, 1
0x0000000000003398:  89 F0                mov   ax, si
0x000000000000339a:  E8 87 FC             call  0x3024
0x000000000000339d:  84 C0                test  al, al
0x000000000000339f:  75 D4                jne   0x3375
0x00000000000033a1:  8A 44 1A             mov   al, byte ptr [si + 0x1a]
0x00000000000033a4:  30 E4                xor   ah, ah
0x00000000000033a6:  6B C0 0B             imul  ax, ax, 0xb
0x00000000000033a9:  89 C7                mov   di, ax
0x00000000000033ab:  89 F0                mov   ax, si
0x00000000000033ad:  8B 95 60 C4          mov   dx, word ptr [di - 0x3ba0]
0x00000000000033b1:  81 C7 60 C4          add   di, 0xc460
0x00000000000033b5:  0E                   push  cs
0x00000000000033b6:  3E E8 34 5C          call  0x8fee
0x00000000000033ba:  EB B9                jmp   0x3375
0x00000000000033bc:  89 FB                mov   bx, di
0x00000000000033be:  8C C1                mov   cx, es
0x00000000000033c0:  89 F0                mov   ax, si
0x00000000000033c2:  E8 FB F9             call  0x2dc0
0x00000000000033c5:  EB AE                jmp   0x3375
0x00000000000033c7:  8A 44 1A             mov   al, byte ptr [si + 0x1a]
0x00000000000033ca:  30 E4                xor   ah, ah
0x00000000000033cc:  FF 5E F4             lcall [bp - 0xc]
0x00000000000033cf:  85 C0                test  ax, ax
0x00000000000033d1:  74 09                je    0x33dc
0x00000000000033d3:  89 F0                mov   ax, si
0x00000000000033d5:  E8 06 F6             call  0x29de
0x00000000000033d8:  84 C0                test  al, al
0x00000000000033da:  75 69                jne   0x3445
0x00000000000033dc:  8A 44 1A             mov   al, byte ptr [si + 0x1a]
0x00000000000033df:  30 E4                xor   ah, ah
0x00000000000033e1:  FF 5E F0             lcall [bp - 0x10]
0x00000000000033e4:  85 C0                test  ax, ax
0x00000000000033e6:  74 14                je    0x33fc
0x00000000000033e8:  80 3E 14 22 04       cmp   byte ptr [0x2214], 4
0x00000000000033ed:  73 54                jae   0x3443
0x00000000000033ef:  80 3E 2F 22 00       cmp   byte ptr [0x222f], 0
0x00000000000033f4:  75 4D                jne   0x3443
0x00000000000033f6:  83 7C 20 00          cmp   word ptr [si + 0x20], 0
0x00000000000033fa:  74 72                je    0x346e
0x00000000000033fc:  FF 4C 20             dec   word ptr [si + 0x20]
0x00000000000033ff:  83 7C 20 00          cmp   word ptr [si + 0x20], 0
0x0000000000003403:  7C 0E                jl    0x3413
0x0000000000003405:  8B 4E FE             mov   cx, word ptr [bp - 2]
0x0000000000003408:  89 FB                mov   bx, di
0x000000000000340a:  89 F0                mov   ax, si
0x000000000000340c:  E8 E9 F7             call  0x2bf8
0x000000000000340f:  84 C0                test  al, al
0x0000000000003411:  75 0A                jne   0x341d
0x0000000000003413:  8B 4E FE             mov   cx, word ptr [bp - 2]
0x0000000000003416:  89 FB                mov   bx, di
0x0000000000003418:  89 F0                mov   ax, si
0x000000000000341a:  E8 A3 F9             call  0x2dc0
0x000000000000341d:  8A 44 1A             mov   al, byte ptr [si + 0x1a]
0x0000000000003420:  30 E4                xor   ah, ah
0x0000000000003422:  FF 5E EC             lcall [bp - 0x14]
0x0000000000003425:  88 C2                mov   dl, al
0x0000000000003427:  84 C0                test  al, al
0x0000000000003429:  75 03                jne   0x342e
0x000000000000342b:  E9 47 FF             jmp   0x3375
0x000000000000342e:  E8 7F 55             call  0x89b0
0x0000000000003431:  3C 03                cmp   al, 3
0x0000000000003433:  73 F6                jae   0x342b
0x0000000000003435:  89 F0                mov   ax, si
0x0000000000003437:  30 F6                xor   dh, dh
0x0000000000003439:  0E                   push  cs
0x000000000000343a:  3E E8 12 D1          call  0x550
0x000000000000343e:  C9                   leave 
0x000000000000343f:  5F                   pop   di
0x0000000000003440:  5E                   pop   si
0x0000000000003441:  5A                   pop   dx
0x0000000000003442:  C3                   ret   
0x0000000000003443:  EB 29                jmp   0x346e
0x0000000000003445:  8A 44 1A             mov   al, byte ptr [si + 0x1a]
0x0000000000003448:  30 E4                xor   ah, ah
0x000000000000344a:  FF 5E F8             lcall [bp - 8]
0x000000000000344d:  88 C2                mov   dl, al
0x000000000000344f:  89 F0                mov   ax, si
0x0000000000003451:  30 F6                xor   dh, dh
0x0000000000003453:  0E                   push  cs
0x0000000000003454:  3E E8 F8 D0          call  0x550
0x0000000000003458:  8A 44 1A             mov   al, byte ptr [si + 0x1a]
0x000000000000345b:  30 E4                xor   ah, ah
0x000000000000345d:  FF 5E F4             lcall [bp - 0xc]
0x0000000000003460:  89 C2                mov   dx, ax
0x0000000000003462:  89 F0                mov   ax, si
0x0000000000003464:  0E                   push  cs
0x0000000000003465:  E8 86 5B             call  0x8fee
0x0000000000003468:  90                   nop   
0x0000000000003469:  C9                   leave 
0x000000000000346a:  5F                   pop   di
0x000000000000346b:  5E                   pop   si
0x000000000000346c:  5A                   pop   dx
0x000000000000346d:  C3                   ret   
0x000000000000346e:  89 F0                mov   ax, si
0x0000000000003470:  E8 3B F6             call  0x2aae
0x0000000000003473:  84 C0                test  al, al
0x0000000000003475:  74 85                je    0x33fc
0x0000000000003477:  8A 44 1A             mov   al, byte ptr [si + 0x1a]
0x000000000000347a:  30 E4                xor   ah, ah
0x000000000000347c:  FF 5E F0             lcall [bp - 0x10]
0x000000000000347f:  89 C2                mov   dx, ax
0x0000000000003481:  89 F0                mov   ax, si
0x0000000000003483:  0E                   push  cs
0x0000000000003484:  3E E8 66 5B          call  0x8fee
0x0000000000003488:  8E 46 FE             mov   es, word ptr [bp - 2]
0x000000000000348b:  26 80 4D 14 80       or    byte ptr es:[di + 0x14], 0x80
0x0000000000003490:  C9                   leave 
0x0000000000003491:  5F                   pop   di
0x0000000000003492:  5E                   pop   si
0x0000000000003493:  5A                   pop   dx
0x0000000000003494:  C3                   ret   
0x0000000000003495:  FC                   cld   
0x0000000000003496:  53                   push  bx
0x0000000000003497:  51                   push  cx
0x0000000000003498:  52                   push  dx
0x0000000000003499:  56                   push  si
0x000000000000349a:  57                   push  di
0x000000000000349b:  55                   push  bp
0x000000000000349c:  89 E5                mov   bp, sp
0x000000000000349e:  83 EC 04             sub   sp, 4
0x00000000000034a1:  89 C3                mov   bx, ax
0x00000000000034a3:  83 7F 22 00          cmp   word ptr [bx + 0x22], 0
0x00000000000034a7:  74 65                je    0x350e
0x00000000000034a9:  B9 2C 00             mov   cx, 0x2c
0x00000000000034ac:  2D 04 34             sub   ax, 0x3404
0x00000000000034af:  31 D2                xor   dx, dx
0x00000000000034b1:  F7 F1                div   cx
0x00000000000034b3:  6B F8 18             imul  di, ax, 0x18
0x00000000000034b6:  B8 F5 6A             mov   ax, 0x6af5
0x00000000000034b9:  8E C0                mov   es, ax
0x00000000000034bb:  26 80 65 14 DF       and   byte ptr es:[di + 0x14], 0xdf
0x00000000000034c0:  89 FE                mov   si, di
0x00000000000034c2:  6B 7F 22 18          imul  di, word ptr [bx + 0x22], 0x18
0x00000000000034c6:  89 46 FE             mov   word ptr [bp - 2], ax
0x00000000000034c9:  89 FB                mov   bx, di
0x00000000000034cb:  26 F6 45 16 04       test  byte ptr es:[di + 0x16], 4
0x00000000000034d0:  74 43                je    0x3515
0x00000000000034d2:  C7 46 FC 01 00       mov   word ptr [bp - 4], 1
0x00000000000034d7:  26 FF 77 06          push  word ptr es:[bx + 6]
0x00000000000034db:  26 FF 77 04          push  word ptr es:[bx + 4]
0x00000000000034df:  26 FF 77 02          push  word ptr es:[bx + 2]
0x00000000000034e3:  26 FF 37             push  word ptr es:[bx]
0x00000000000034e6:  8E 46 FE             mov   es, word ptr [bp - 2]
0x00000000000034e9:  26 8B 5C 04          mov   bx, word ptr es:[si + 4]
0x00000000000034ed:  26 8B 4C 06          mov   cx, word ptr es:[si + 6]
0x00000000000034f1:  26 8B 04             mov   ax, word ptr es:[si]
0x00000000000034f4:  26 8B 54 02          mov   dx, word ptr es:[si + 2]
0x00000000000034f8:  0E                   push  cs
0x00000000000034f9:  E8 3D 6C             call  0xa139
0x00000000000034fc:  90                   nop   
0x00000000000034fd:  8E 46 FE             mov   es, word ptr [bp - 2]
0x0000000000003500:  26 89 44 0E          mov   word ptr es:[si + 0xe], ax
0x0000000000003504:  26 89 54 10          mov   word ptr es:[si + 0x10], dx
0x0000000000003508:  80 7E FC 00          cmp   byte ptr [bp - 4], 0
0x000000000000350c:  75 0E                jne   0x351c
0x000000000000350e:  C9                   leave 
0x000000000000350f:  5F                   pop   di
0x0000000000003510:  5E                   pop   si
0x0000000000003511:  5A                   pop   dx
0x0000000000003512:  59                   pop   cx
0x0000000000003513:  5B                   pop   bx
0x0000000000003514:  C3                   ret   
0x0000000000003515:  C7 46 FC 00 00       mov   word ptr [bp - 4], 0
0x000000000000351a:  EB BB                jmp   0x34d7
0x000000000000351c:  E8 91 54             call  0x89b0
0x000000000000351f:  88 C2                mov   dl, al
0x0000000000003521:  E8 8C 54             call  0x89b0
0x0000000000003524:  88 C3                mov   bl, al
0x0000000000003526:  30 F6                xor   dh, dh
0x0000000000003528:  30 FF                xor   bh, bh
0x000000000000352a:  29 DA                sub   dx, bx
0x000000000000352c:  89 D3                mov   bx, dx
0x000000000000352e:  8E 46 FE             mov   es, word ptr [bp - 2]
0x0000000000003531:  C1 E3 05             shl   bx, 5
0x0000000000003534:  26 01 5C 10          add   word ptr es:[si + 0x10], bx
0x0000000000003538:  C9                   leave 
0x0000000000003539:  5F                   pop   di
0x000000000000353a:  5E                   pop   si
0x000000000000353b:  5A                   pop   dx
0x000000000000353c:  59                   pop   cx
0x000000000000353d:  5B                   pop   bx
0x000000000000353e:  C3                   ret   
0x000000000000353f:  FC                   cld   
0x0000000000003540:  53                   push  bx
0x0000000000003541:  51                   push  cx
0x0000000000003542:  52                   push  dx
0x0000000000003543:  56                   push  si
0x0000000000003544:  57                   push  di
0x0000000000003545:  55                   push  bp
0x0000000000003546:  89 E5                mov   bp, sp
0x0000000000003548:  83 EC 02             sub   sp, 2
0x000000000000354b:  89 C6                mov   si, ax
0x000000000000354d:  83 7C 22 00          cmp   word ptr [si + 0x22], 0
0x0000000000003551:  75 07                jne   0x355a
0x0000000000003553:  C9                   leave 
0x0000000000003554:  5F                   pop   di
0x0000000000003555:  5E                   pop   si
0x0000000000003556:  5A                   pop   dx
0x0000000000003557:  59                   pop   cx
0x0000000000003558:  5B                   pop   bx
0x0000000000003559:  C3                   ret   
0x000000000000355a:  BB 2C 00             mov   bx, 0x2c
0x000000000000355d:  2D 04 34             sub   ax, 0x3404
0x0000000000003560:  31 D2                xor   dx, dx
0x0000000000003562:  F7 F3                div   bx
0x0000000000003564:  6B D8 18             imul  bx, ax, 0x18
0x0000000000003567:  89 F0                mov   ax, si
0x0000000000003569:  BA F5 6A             mov   dx, 0x6af5
0x000000000000356c:  E8 27 FF             call  0x3496
0x000000000000356f:  8E C2                mov   es, dx
0x0000000000003571:  26 8B 4F 10          mov   cx, word ptr es:[bx + 0x10]
0x0000000000003575:  89 F0                mov   ax, si
0x0000000000003577:  C1 E9 03             shr   cx, 3
0x000000000000357a:  BB 00 08             mov   bx, 0x800
0x000000000000357d:  89 CA                mov   dx, cx
0x000000000000357f:  FF 1E E8 0C          lcall [0xce8]
0x0000000000003583:  89 C3                mov   bx, ax
0x0000000000003585:  89 56 FE             mov   word ptr [bp - 2], dx
0x0000000000003588:  BA 01 00             mov   dx, 1
0x000000000000358b:  89 F0                mov   ax, si
0x000000000000358d:  0E                   push  cs
0x000000000000358e:  3E E8 BE CF          call  0x550
0x0000000000003592:  E8 1B 54             call  0x89b0
0x0000000000003595:  88 C2                mov   dl, al
0x0000000000003597:  E8 16 54             call  0x89b0
0x000000000000359a:  30 F6                xor   dh, dh
0x000000000000359c:  30 E4                xor   ah, ah
0x000000000000359e:  BF 05 00             mov   di, 5
0x00000000000035a1:  29 C2                sub   dx, ax
0x00000000000035a3:  E8 0A 54             call  0x89b0
0x00000000000035a6:  01 D2                add   dx, dx
0x00000000000035a8:  30 E4                xor   ah, ah
0x00000000000035aa:  01 D1                add   cx, dx
0x00000000000035ac:  99                   cdq   
0x00000000000035ad:  F7 FF                idiv  di
0x00000000000035af:  42                   inc   dx
0x00000000000035b0:  89 D0                mov   ax, dx
0x00000000000035b2:  C1 E0 02             shl   ax, 2
0x00000000000035b5:  29 D0                sub   ax, dx
0x00000000000035b7:  80 E5 1F             and   ch, 0x1f
0x00000000000035ba:  50                   push  ax
0x00000000000035bb:  89 CA                mov   dx, cx
0x00000000000035bd:  FF 76 FE             push  word ptr [bp - 2]
0x00000000000035c0:  89 F0                mov   ax, si
0x00000000000035c2:  53                   push  bx
0x00000000000035c3:  BB 00 08             mov   bx, 0x800
0x00000000000035c6:  FF 1E EC 0C          lcall [0xcec]
0x00000000000035ca:  C9                   leave 
0x00000000000035cb:  5F                   pop   di
0x00000000000035cc:  5E                   pop   si
0x00000000000035cd:  5A                   pop   dx
0x00000000000035ce:  59                   pop   cx
0x00000000000035cf:  5B                   pop   bx
0x00000000000035d0:  C3                   ret   
0x00000000000035d1:  FC                   cld   
0x00000000000035d2:  53                   push  bx
0x00000000000035d3:  51                   push  cx
0x00000000000035d4:  52                   push  dx
0x00000000000035d5:  56                   push  si
0x00000000000035d6:  57                   push  di
0x00000000000035d7:  55                   push  bp
0x00000000000035d8:  89 E5                mov   bp, sp
0x00000000000035da:  83 EC 06             sub   sp, 6
0x00000000000035dd:  89 C7                mov   di, ax
0x00000000000035df:  83 7D 22 00          cmp   word ptr [di + 0x22], 0
0x00000000000035e3:  75 07                jne   0x35ec
0x00000000000035e5:  C9                   leave 
0x00000000000035e6:  5F                   pop   di
0x00000000000035e7:  5E                   pop   si
0x00000000000035e8:  5A                   pop   dx
0x00000000000035e9:  59                   pop   cx
0x00000000000035ea:  5B                   pop   bx
0x00000000000035eb:  C3                   ret   
0x00000000000035ec:  BE 2C 00             mov   si, 0x2c
0x00000000000035ef:  2D 04 34             sub   ax, 0x3404
0x00000000000035f2:  31 D2                xor   dx, dx
0x00000000000035f4:  F7 F6                div   si
0x00000000000035f6:  6B F0 18             imul  si, ax, 0x18
0x00000000000035f9:  BA 02 00             mov   dx, 2
0x00000000000035fc:  89 F8                mov   ax, di
0x00000000000035fe:  0E                   push  cs
0x00000000000035ff:  E8 4E CF             call  0x550
0x0000000000003602:  90                   nop   
0x0000000000003603:  89 F8                mov   ax, di
0x0000000000003605:  BB F5 6A             mov   bx, 0x6af5
0x0000000000003608:  E8 8B FE             call  0x3496
0x000000000000360b:  8E C3                mov   es, bx
0x000000000000360d:  26 8B 44 10          mov   ax, word ptr es:[si + 0x10]
0x0000000000003611:  C1 E8 03             shr   ax, 3
0x0000000000003614:  BB 00 08             mov   bx, 0x800
0x0000000000003617:  89 46 FE             mov   word ptr [bp - 2], ax
0x000000000000361a:  89 C2                mov   dx, ax
0x000000000000361c:  89 F8                mov   ax, di
0x000000000000361e:  30 C9                xor   cl, cl
0x0000000000003620:  FF 1E E8 0C          lcall [0xce8]
0x0000000000003624:  89 46 FA             mov   word ptr [bp - 6], ax
0x0000000000003627:  89 56 FC             mov   word ptr [bp - 4], dx
0x000000000000362a:  E8 83 53             call  0x89b0
0x000000000000362d:  8B 76 FE             mov   si, word ptr [bp - 2]
0x0000000000003630:  88 C2                mov   dl, al
0x0000000000003632:  E8 7B 53             call  0x89b0
0x0000000000003635:  30 F6                xor   dh, dh
0x0000000000003637:  30 E4                xor   ah, ah
0x0000000000003639:  BB 05 00             mov   bx, 5
0x000000000000363c:  29 C2                sub   dx, ax
0x000000000000363e:  E8 6F 53             call  0x89b0
0x0000000000003641:  01 D2                add   dx, dx
0x0000000000003643:  30 E4                xor   ah, ah
0x0000000000003645:  01 D6                add   si, dx
0x0000000000003647:  99                   cdq   
0x0000000000003648:  F7 FB                idiv  bx
0x000000000000364a:  89 D0                mov   ax, dx
0x000000000000364c:  40                   inc   ax
0x000000000000364d:  6B C0 03             imul  ax, ax, 3
0x0000000000003650:  81 E6 FF 1F          and   si, 0x1fff
0x0000000000003654:  98                   cwde  
0x0000000000003655:  BB 00 08             mov   bx, 0x800
0x0000000000003658:  50                   push  ax
0x0000000000003659:  89 F2                mov   dx, si
0x000000000000365b:  FF 76 FC             push  word ptr [bp - 4]
0x000000000000365e:  89 F8                mov   ax, di
0x0000000000003660:  FF 76 FA             push  word ptr [bp - 6]
0x0000000000003663:  FE C1                inc   cl
0x0000000000003665:  FF 1E EC 0C          lcall [0xcec]
0x0000000000003669:  80 F9 03             cmp   cl, 3
0x000000000000366c:  7C BC                jl    0x362a
0x000000000000366e:  C9                   leave 
0x000000000000366f:  5F                   pop   di
0x0000000000003670:  5E                   pop   si
0x0000000000003671:  5A                   pop   dx
0x0000000000003672:  59                   pop   cx
0x0000000000003673:  5B                   pop   bx
0x0000000000003674:  C3                   ret   
0x0000000000003675:  FC                   cld   
0x0000000000003676:  53                   push  bx
0x0000000000003677:  51                   push  cx
0x0000000000003678:  52                   push  dx
0x0000000000003679:  56                   push  si
0x000000000000367a:  57                   push  di
0x000000000000367b:  55                   push  bp
0x000000000000367c:  89 E5                mov   bp, sp
0x000000000000367e:  83 EC 02             sub   sp, 2
0x0000000000003681:  89 C6                mov   si, ax
0x0000000000003683:  83 7C 22 00          cmp   word ptr [si + 0x22], 0
0x0000000000003687:  75 07                jne   0x3690
0x0000000000003689:  C9                   leave 
0x000000000000368a:  5F                   pop   di
0x000000000000368b:  5E                   pop   si
0x000000000000368c:  5A                   pop   dx
0x000000000000368d:  59                   pop   cx
0x000000000000368e:  5B                   pop   bx
0x000000000000368f:  C3                   ret   
0x0000000000003690:  BB 2C 00             mov   bx, 0x2c
0x0000000000003693:  2D 04 34             sub   ax, 0x3404
0x0000000000003696:  31 D2                xor   dx, dx
0x0000000000003698:  F7 F3                div   bx
0x000000000000369a:  6B D8 18             imul  bx, ax, 0x18
0x000000000000369d:  BA 02 00             mov   dx, 2
0x00000000000036a0:  89 F0                mov   ax, si
0x00000000000036a2:  0E                   push  cs
0x00000000000036a3:  E8 AA CE             call  0x550
0x00000000000036a6:  90                   nop   
0x00000000000036a7:  89 F0                mov   ax, si
0x00000000000036a9:  B9 F5 6A             mov   cx, 0x6af5
0x00000000000036ac:  E8 E7 FD             call  0x3496
0x00000000000036af:  8E C1                mov   es, cx
0x00000000000036b1:  26 8B 4F 10          mov   cx, word ptr es:[bx + 0x10]
0x00000000000036b5:  89 F0                mov   ax, si
0x00000000000036b7:  C1 E9 03             shr   cx, 3
0x00000000000036ba:  BB 00 08             mov   bx, 0x800
0x00000000000036bd:  89 CA                mov   dx, cx
0x00000000000036bf:  FF 1E E8 0C          lcall [0xce8]
0x00000000000036c3:  89 46 FE             mov   word ptr [bp - 2], ax
0x00000000000036c6:  89 D3                mov   bx, dx
0x00000000000036c8:  E8 E5 52             call  0x89b0
0x00000000000036cb:  88 C2                mov   dl, al
0x00000000000036cd:  E8 E0 52             call  0x89b0
0x00000000000036d0:  30 F6                xor   dh, dh
0x00000000000036d2:  30 E4                xor   ah, ah
0x00000000000036d4:  29 C2                sub   dx, ax
0x00000000000036d6:  89 D0                mov   ax, dx
0x00000000000036d8:  01 D0                add   ax, dx
0x00000000000036da:  01 C1                add   cx, ax
0x00000000000036dc:  E8 D1 52             call  0x89b0
0x00000000000036df:  30 E4                xor   ah, ah
0x00000000000036e1:  BF 05 00             mov   di, 5
0x00000000000036e4:  99                   cdq   
0x00000000000036e5:  F7 FF                idiv  di
0x00000000000036e7:  42                   inc   dx
0x00000000000036e8:  89 D0                mov   ax, dx
0x00000000000036ea:  C1 E0 02             shl   ax, 2
0x00000000000036ed:  29 D0                sub   ax, dx
0x00000000000036ef:  98                   cwde  
0x00000000000036f0:  80 E5 1F             and   ch, 0x1f
0x00000000000036f3:  50                   push  ax
0x00000000000036f4:  89 CA                mov   dx, cx
0x00000000000036f6:  53                   push  bx
0x00000000000036f7:  89 F0                mov   ax, si
0x00000000000036f9:  FF 76 FE             push  word ptr [bp - 2]
0x00000000000036fc:  BB 00 08             mov   bx, 0x800
0x00000000000036ff:  FF 1E EC 0C          lcall [0xcec]
0x0000000000003703:  C9                   leave 
0x0000000000003704:  5F                   pop   di
0x0000000000003705:  5E                   pop   si
0x0000000000003706:  5A                   pop   dx
0x0000000000003707:  59                   pop   cx
0x0000000000003708:  5B                   pop   bx
0x0000000000003709:  C3                   ret   
0x000000000000370a:  52                   push  dx
0x000000000000370b:  56                   push  si
0x000000000000370c:  57                   push  di
0x000000000000370d:  55                   push  bp
0x000000000000370e:  89 E5                mov   bp, sp
0x0000000000003710:  83 EC 04             sub   sp, 4
0x0000000000003713:  89 C6                mov   si, ax
0x0000000000003715:  E8 7E FD             call  0x3496
0x0000000000003718:  C7 46 FC 50 03       mov   word ptr [bp - 4], 0x350
0x000000000000371d:  C7 46 FE D9 92       mov   word ptr [bp - 2], 0x92d9
0x0000000000003722:  8B 54 22             mov   dx, word ptr [si + 0x22]
0x0000000000003725:  E8 88 52             call  0x89b0
0x0000000000003728:  3C 28                cmp   al, 0x28
0x000000000000372a:  72 2F                jb    0x375b
0x000000000000372c:  85 D2                test  dx, dx
0x000000000000372e:  74 2B                je    0x375b
0x0000000000003730:  6B FA 2C             imul  di, dx, 0x2c
0x0000000000003733:  81 C7 04 34          add   di, 0x3404
0x0000000000003737:  85 D2                test  dx, dx
0x0000000000003739:  74 25                je    0x3760
0x000000000000373b:  83 7D 1C 00          cmp   word ptr [di + 0x1c], 0
0x000000000000373f:  7E 1F                jle   0x3760
0x0000000000003741:  B9 2C 00             mov   cx, 0x2c
0x0000000000003744:  8D 85 FC CB          lea   ax, [di - 0x3404]
0x0000000000003748:  31 D2                xor   dx, dx
0x000000000000374a:  F7 F1                div   cx
0x000000000000374c:  6B C8 18             imul  cx, ax, 0x18
0x000000000000374f:  89 FA                mov   dx, di
0x0000000000003751:  89 F0                mov   ax, si
0x0000000000003753:  FF 1E CC 0C          lcall [0xccc]
0x0000000000003757:  84 C0                test  al, al
0x0000000000003759:  74 05                je    0x3760
0x000000000000375b:  C9                   leave 
0x000000000000375c:  5F                   pop   di
0x000000000000375d:  5E                   pop   si
0x000000000000375e:  5A                   pop   dx
0x000000000000375f:  C3                   ret   
0x0000000000003760:  8A 44 1A             mov   al, byte ptr [si + 0x1a]
0x0000000000003763:  30 E4                xor   ah, ah
0x0000000000003765:  FF 5E FC             lcall [bp - 4]
0x0000000000003768:  89 C2                mov   dx, ax
0x000000000000376a:  89 F0                mov   ax, si
0x000000000000376c:  0E                   push  cs
0x000000000000376d:  E8 7E 58             call  0x8fee
0x0000000000003770:  90                   nop   
0x0000000000003771:  C9                   leave 
0x0000000000003772:  5F                   pop   di
0x0000000000003773:  5E                   pop   si
0x0000000000003774:  5A                   pop   dx
0x0000000000003775:  C3                   ret   
0x0000000000003776:  52                   push  dx
0x0000000000003777:  56                   push  si
0x0000000000003778:  57                   push  di
0x0000000000003779:  55                   push  bp
0x000000000000377a:  89 E5                mov   bp, sp
0x000000000000377c:  83 EC 04             sub   sp, 4
0x000000000000377f:  89 C6                mov   si, ax
0x0000000000003781:  E8 12 FD             call  0x3496
0x0000000000003784:  C7 46 FC 50 03       mov   word ptr [bp - 4], 0x350
0x0000000000003789:  C7 46 FE D9 92       mov   word ptr [bp - 2], 0x92d9
0x000000000000378e:  8B 54 22             mov   dx, word ptr [si + 0x22]
0x0000000000003791:  E8 1C 52             call  0x89b0
0x0000000000003794:  3C 0A                cmp   al, 0xa
0x0000000000003796:  72 2F                jb    0x37c7
0x0000000000003798:  85 D2                test  dx, dx
0x000000000000379a:  74 2B                je    0x37c7
0x000000000000379c:  6B FA 2C             imul  di, dx, 0x2c
0x000000000000379f:  81 C7 04 34          add   di, 0x3404
0x00000000000037a3:  85 D2                test  dx, dx
0x00000000000037a5:  74 25                je    0x37cc
0x00000000000037a7:  83 7D 1C 00          cmp   word ptr [di + 0x1c], 0
0x00000000000037ab:  7E 1F                jle   0x37cc
0x00000000000037ad:  B9 2C 00             mov   cx, 0x2c
0x00000000000037b0:  8D 85 FC CB          lea   ax, [di - 0x3404]
0x00000000000037b4:  31 D2                xor   dx, dx
0x00000000000037b6:  F7 F1                div   cx
0x00000000000037b8:  6B C8 18             imul  cx, ax, 0x18
0x00000000000037bb:  89 FA                mov   dx, di
0x00000000000037bd:  89 F0                mov   ax, si
0x00000000000037bf:  FF 1E CC 0C          lcall [0xccc]
0x00000000000037c3:  84 C0                test  al, al
0x00000000000037c5:  74 05                je    0x37cc
0x00000000000037c7:  C9                   leave 
0x00000000000037c8:  5F                   pop   di
0x00000000000037c9:  5E                   pop   si
0x00000000000037ca:  5A                   pop   dx
0x00000000000037cb:  C3                   ret   
0x00000000000037cc:  8A 44 1A             mov   al, byte ptr [si + 0x1a]
0x00000000000037cf:  30 E4                xor   ah, ah
0x00000000000037d1:  FF 5E FC             lcall [bp - 4]
0x00000000000037d4:  89 C2                mov   dx, ax
0x00000000000037d6:  89 F0                mov   ax, si
0x00000000000037d8:  0E                   push  cs
0x00000000000037d9:  E8 12 58             call  0x8fee
0x00000000000037dc:  90                   nop   
0x00000000000037dd:  C9                   leave 
0x00000000000037de:  5F                   pop   di
0x00000000000037df:  5E                   pop   si
0x00000000000037e0:  5A                   pop   dx
0x00000000000037e1:  C3                   ret   
0x00000000000037e2:  52                   push  dx
0x00000000000037e3:  56                   push  si
0x00000000000037e4:  89 C6                mov   si, ax
0x00000000000037e6:  83 7C 22 00          cmp   word ptr [si + 0x22], 0
0x00000000000037ea:  75 03                jne   0x37ef
0x00000000000037ec:  5E                   pop   si
0x00000000000037ed:  5A                   pop   dx
0x00000000000037ee:  C3                   ret   
0x00000000000037ef:  E8 A4 FC             call  0x3496
0x00000000000037f2:  6B 54 22 2C          imul  dx, word ptr [si + 0x22], 0x2c
0x00000000000037f6:  6A 24                push  0x24
0x00000000000037f8:  89 F0                mov   ax, si
0x00000000000037fa:  81 C2 04 34          add   dx, 0x3404
0x00000000000037fe:  FF 1E F8 0C          lcall [0xcf8]
0x0000000000003802:  5E                   pop   si
0x0000000000003803:  5A                   pop   dx
0x0000000000003804:  C3                   ret   
0x0000000000003805:  FC                   cld   
0x0000000000003806:  52                   push  dx
0x0000000000003807:  56                   push  si
0x0000000000003808:  89 C6                mov   si, ax
0x000000000000380a:  83 7C 22 00          cmp   word ptr [si + 0x22], 0
0x000000000000380e:  75 03                jne   0x3813
0x0000000000003810:  5E                   pop   si
0x0000000000003811:  5A                   pop   dx
0x0000000000003812:  C3                   ret   
0x0000000000003813:  E8 80 FC             call  0x3496
0x0000000000003816:  89 F0                mov   ax, si
0x0000000000003818:  E8 C3 F1             call  0x29de
0x000000000000381b:  84 C0                test  al, al
0x000000000000381d:  74 3A                je    0x3859
0x000000000000381f:  BA 37 00             mov   dx, 0x37
0x0000000000003822:  89 F0                mov   ax, si
0x0000000000003824:  0E                   push  cs
0x0000000000003825:  E8 28 CD             call  0x550
0x0000000000003828:  90                   nop   
0x0000000000003829:  E8 84 51             call  0x89b0
0x000000000000382c:  30 E4                xor   ah, ah
0x000000000000382e:  89 C1                mov   cx, ax
0x0000000000003830:  C1 F9 0F             sar   cx, 0xf
0x0000000000003833:  31 C8                xor   ax, cx
0x0000000000003835:  29 C8                sub   ax, cx
0x0000000000003837:  25 07 00             and   ax, 7
0x000000000000383a:  31 C8                xor   ax, cx
0x000000000000383c:  29 C8                sub   ax, cx
0x000000000000383e:  40                   inc   ax
0x000000000000383f:  89 C1                mov   cx, ax
0x0000000000003841:  C1 E1 02             shl   cx, 2
0x0000000000003844:  29 C1                sub   cx, ax
0x0000000000003846:  6B 44 22 2C          imul  ax, word ptr [si + 0x22], 0x2c
0x000000000000384a:  89 F3                mov   bx, si
0x000000000000384c:  89 F2                mov   dx, si
0x000000000000384e:  05 04 34             add   ax, 0x3404
0x0000000000003851:  0E                   push  cs
0x0000000000003852:  3E E8 DA 28          call  0x6130
0x0000000000003856:  5E                   pop   si
0x0000000000003857:  5A                   pop   dx
0x0000000000003858:  C3                   ret   
0x0000000000003859:  6B 54 22 2C          imul  dx, word ptr [si + 0x22], 0x2c
0x000000000000385d:  6A 1F                push  0x1f
0x000000000000385f:  89 F0                mov   ax, si
0x0000000000003861:  81 C2 04 34          add   dx, 0x3404
0x0000000000003865:  FF 1E F8 0C          lcall [0xcf8]
0x0000000000003869:  5E                   pop   si
0x000000000000386a:  5A                   pop   dx
0x000000000000386b:  C3                   ret   
0x000000000000386c:  53                   push  bx
0x000000000000386d:  51                   push  cx
0x000000000000386e:  52                   push  dx
0x000000000000386f:  56                   push  si
0x0000000000003870:  89 C6                mov   si, ax
0x0000000000003872:  83 7C 22 00          cmp   word ptr [si + 0x22], 0
0x0000000000003876:  75 05                jne   0x387d
0x0000000000003878:  5E                   pop   si
0x0000000000003879:  5A                   pop   dx
0x000000000000387a:  59                   pop   cx
0x000000000000387b:  5B                   pop   bx
0x000000000000387c:  C3                   ret   
0x000000000000387d:  E8 16 FC             call  0x3496
0x0000000000003880:  89 F0                mov   ax, si
0x0000000000003882:  E8 59 F1             call  0x29de
0x0000000000003885:  84 C0                test  al, al
0x0000000000003887:  74 EF                je    0x3878
0x0000000000003889:  E8 24 51             call  0x89b0
0x000000000000388c:  30 E4                xor   ah, ah
0x000000000000388e:  B9 0A 00             mov   cx, 0xa
0x0000000000003891:  99                   cdq   
0x0000000000003892:  F7 F9                idiv  cx
0x0000000000003894:  6B 44 22 2C          imul  ax, word ptr [si + 0x22], 0x2c
0x0000000000003898:  89 D1                mov   cx, dx
0x000000000000389a:  89 F3                mov   bx, si
0x000000000000389c:  C1 E1 02             shl   cx, 2
0x000000000000389f:  89 F2                mov   dx, si
0x00000000000038a1:  83 C1 04             add   cx, 4
0x00000000000038a4:  05 04 34             add   ax, 0x3404
0x00000000000038a7:  0E                   push  cs
0x00000000000038a8:  3E E8 84 28          call  0x6130
0x00000000000038ac:  5E                   pop   si
0x00000000000038ad:  5A                   pop   dx
0x00000000000038ae:  59                   pop   cx
0x00000000000038af:  5B                   pop   bx
0x00000000000038b0:  C3                   ret   
0x00000000000038b1:  FC                   cld   
0x00000000000038b2:  52                   push  dx
0x00000000000038b3:  56                   push  si
0x00000000000038b4:  89 C6                mov   si, ax
0x00000000000038b6:  83 7C 22 00          cmp   word ptr [si + 0x22], 0
0x00000000000038ba:  75 03                jne   0x38bf
0x00000000000038bc:  5E                   pop   si
0x00000000000038bd:  5A                   pop   dx
0x00000000000038be:  C3                   ret   
0x00000000000038bf:  E8 D4 FB             call  0x3496
0x00000000000038c2:  89 F0                mov   ax, si
0x00000000000038c4:  E8 17 F1             call  0x29de
0x00000000000038c7:  84 C0                test  al, al
0x00000000000038c9:  74 28                je    0x38f3
0x00000000000038cb:  E8 E2 50             call  0x89b0
0x00000000000038ce:  30 E4                xor   ah, ah
0x00000000000038d0:  BB 06 00             mov   bx, 6
0x00000000000038d3:  99                   cdq   
0x00000000000038d4:  F7 FB                idiv  bx
0x00000000000038d6:  6B 44 22 2C          imul  ax, word ptr [si + 0x22], 0x2c
0x00000000000038da:  42                   inc   dx
0x00000000000038db:  89 D1                mov   cx, dx
0x00000000000038dd:  C1 E1 02             shl   cx, 2
0x00000000000038e0:  89 F3                mov   bx, si
0x00000000000038e2:  01 D1                add   cx, dx
0x00000000000038e4:  89 F2                mov   dx, si
0x00000000000038e6:  01 C9                add   cx, cx
0x00000000000038e8:  05 04 34             add   ax, 0x3404
0x00000000000038eb:  0E                   push  cs
0x00000000000038ec:  3E E8 40 28          call  0x6130
0x00000000000038f0:  5E                   pop   si
0x00000000000038f1:  5A                   pop   dx
0x00000000000038f2:  C3                   ret   
0x00000000000038f3:  6B 54 22 2C          imul  dx, word ptr [si + 0x22], 0x2c
0x00000000000038f7:  6A 20                push  0x20
0x00000000000038f9:  89 F0                mov   ax, si
0x00000000000038fb:  81 C2 04 34          add   dx, 0x3404
0x00000000000038ff:  FF 1E F8 0C          lcall [0xcf8]
0x0000000000003903:  5E                   pop   si
0x0000000000003904:  5A                   pop   dx
0x0000000000003905:  C3                   ret   
0x0000000000003906:  52                   push  dx
0x0000000000003907:  56                   push  si
0x0000000000003908:  89 C6                mov   si, ax
0x000000000000390a:  83 7C 22 00          cmp   word ptr [si + 0x22], 0
0x000000000000390e:  75 03                jne   0x3913
0x0000000000003910:  5E                   pop   si
0x0000000000003911:  5A                   pop   dx
0x0000000000003912:  C3                   ret   
0x0000000000003913:  E8 80 FB             call  0x3496
0x0000000000003916:  6B 54 22 2C          imul  dx, word ptr [si + 0x22], 0x2c
0x000000000000391a:  6A 21                push  0x21
0x000000000000391c:  89 F0                mov   ax, si
0x000000000000391e:  81 C2 04 34          add   dx, 0x3404
0x0000000000003922:  FF 1E F8 0C          lcall [0xcf8]
0x0000000000003926:  5E                   pop   si
0x0000000000003927:  5A                   pop   dx
0x0000000000003928:  C3                   ret   
0x0000000000003929:  FC                   cld   
0x000000000000392a:  52                   push  dx
0x000000000000392b:  56                   push  si
0x000000000000392c:  89 C6                mov   si, ax
0x000000000000392e:  83 7C 22 00          cmp   word ptr [si + 0x22], 0
0x0000000000003932:  75 03                jne   0x3937
0x0000000000003934:  5E                   pop   si
0x0000000000003935:  5A                   pop   dx
0x0000000000003936:  C3                   ret   
0x0000000000003937:  E8 A4 F0             call  0x29de
0x000000000000393a:  84 C0                test  al, al
0x000000000000393c:  74 3C                je    0x397a
0x000000000000393e:  BA 37 00             mov   dx, 0x37
0x0000000000003941:  89 F0                mov   ax, si
0x0000000000003943:  0E                   push  cs
0x0000000000003944:  3E E8 08 CC          call  0x550
0x0000000000003948:  E8 65 50             call  0x89b0
0x000000000000394b:  30 E4                xor   ah, ah
0x000000000000394d:  89 C1                mov   cx, ax
0x000000000000394f:  C1 F9 0F             sar   cx, 0xf
0x0000000000003952:  31 C8                xor   ax, cx
0x0000000000003954:  29 C8                sub   ax, cx
0x0000000000003956:  25 07 00             and   ax, 7
0x0000000000003959:  31 C8                xor   ax, cx
0x000000000000395b:  29 C8                sub   ax, cx
0x000000000000395d:  40                   inc   ax
0x000000000000395e:  89 C1                mov   cx, ax
0x0000000000003960:  C1 E1 02             shl   cx, 2
0x0000000000003963:  01 C1                add   cx, ax
0x0000000000003965:  6B 44 22 2C          imul  ax, word ptr [si + 0x22], 0x2c
0x0000000000003969:  89 F3                mov   bx, si
0x000000000000396b:  89 F2                mov   dx, si
0x000000000000396d:  01 C9                add   cx, cx
0x000000000000396f:  05 04 34             add   ax, 0x3404
0x0000000000003972:  0E                   push  cs
0x0000000000003973:  E8 BA 27             call  0x6130
0x0000000000003976:  90                   nop   
0x0000000000003977:  5E                   pop   si
0x0000000000003978:  5A                   pop   dx
0x0000000000003979:  C3                   ret   
0x000000000000397a:  6B 54 22 2C          imul  dx, word ptr [si + 0x22], 0x2c
0x000000000000397e:  6A 10                push  0x10
0x0000000000003980:  89 F0                mov   ax, si
0x0000000000003982:  81 C2 04 34          add   dx, 0x3404
0x0000000000003986:  FF 1E F8 0C          lcall [0xcf8]
0x000000000000398a:  5E                   pop   si
0x000000000000398b:  5A                   pop   dx
0x000000000000398c:  C3                   ret   
0x000000000000398d:  FC                   cld   
0x000000000000398e:  52                   push  dx
0x000000000000398f:  56                   push  si
0x0000000000003990:  57                   push  di
0x0000000000003991:  55                   push  bp
0x0000000000003992:  89 E5                mov   bp, sp
0x0000000000003994:  83 EC 06             sub   sp, 6
0x0000000000003997:  89 C6                mov   si, ax
0x0000000000003999:  89 5E FE             mov   word ptr [bp - 2], bx
0x000000000000399c:  89 4E FC             mov   word ptr [bp - 4], cx
0x000000000000399f:  83 7C 22 00          cmp   word ptr [si + 0x22], 0
0x00000000000039a3:  75 05                jne   0x39aa
0x00000000000039a5:  C9                   leave 
0x00000000000039a6:  5F                   pop   di
0x00000000000039a7:  5E                   pop   si
0x00000000000039a8:  5A                   pop   dx
0x00000000000039a9:  C3                   ret   
0x00000000000039aa:  E8 E9 FA             call  0x3496
0x00000000000039ad:  8E C1                mov   es, cx
0x00000000000039af:  26 83 47 0A 10       add   word ptr es:[bx + 0xa], 0x10
0x00000000000039b4:  6B 54 22 2C          imul  dx, word ptr [si + 0x22], 0x2c
0x00000000000039b8:  6A 06                push  6
0x00000000000039ba:  89 F0                mov   ax, si
0x00000000000039bc:  81 C2 04 34          add   dx, 0x3404
0x00000000000039c0:  BF 34 07             mov   di, 0x734
0x00000000000039c3:  FF 1E F8 0C          lcall [0xcf8]
0x00000000000039c7:  BB BA 01             mov   bx, 0x1ba
0x00000000000039ca:  8B 45 02             mov   ax, word ptr [di + 2]
0x00000000000039cd:  8B 0F                mov   cx, word ptr [bx]
0x00000000000039cf:  8B 1D                mov   bx, word ptr [di]
0x00000000000039d1:  8E 46 FC             mov   es, word ptr [bp - 4]
0x00000000000039d4:  8B 7E FE             mov   di, word ptr [bp - 2]
0x00000000000039d7:  26 83 6D 0A 10       sub   word ptr es:[di + 0xa], 0x10
0x00000000000039dc:  89 46 FA             mov   word ptr [bp - 6], ax
0x00000000000039df:  8B 44 22             mov   ax, word ptr [si + 0x22]
0x00000000000039e2:  89 CE                mov   si, cx
0x00000000000039e4:  8B 54 0E             mov   dx, word ptr [si + 0xe]
0x00000000000039e7:  8B 74 10             mov   si, word ptr [si + 0x10]
0x00000000000039ea:  8E 46 FA             mov   es, word ptr [bp - 6]
0x00000000000039ed:  26 01 17             add   word ptr es:[bx], dx
0x00000000000039f0:  26 11 77 02          adc   word ptr es:[bx + 2], si
0x00000000000039f4:  89 CE                mov   si, cx
0x00000000000039f6:  89 CF                mov   di, cx
0x00000000000039f8:  8B 74 12             mov   si, word ptr [si + 0x12]
0x00000000000039fb:  8B 55 14             mov   dx, word ptr [di + 0x14]
0x00000000000039fe:  26 01 77 04          add   word ptr es:[bx + 4], si
0x0000000000003a02:  26 11 57 06          adc   word ptr es:[bx + 6], dx
0x0000000000003a06:  89 45 26             mov   word ptr [di + 0x26], ax
0x0000000000003a09:  C9                   leave 
0x0000000000003a0a:  5F                   pop   di
0x0000000000003a0b:  5E                   pop   si
0x0000000000003a0c:  5A                   pop   dx
0x0000000000003a0d:  C3                   ret   
0x0000000000003a0e:  52                   push  dx
0x0000000000003a0f:  56                   push  si
0x0000000000003a10:  57                   push  di
0x0000000000003a11:  55                   push  bp
0x0000000000003a12:  89 E5                mov   bp, sp
0x0000000000003a14:  83 EC 04             sub   sp, 4
0x0000000000003a17:  50                   push  ax
0x0000000000003a18:  53                   push  bx
0x0000000000003a19:  51                   push  cx
0x0000000000003a1a:  F6 06 54 1E 03       test  byte ptr [0x1e54], 3
0x0000000000003a1f:  74 05                je    0x3a26
0x0000000000003a21:  C9                   leave 
0x0000000000003a22:  5F                   pop   di
0x0000000000003a23:  5E                   pop   si
0x0000000000003a24:  5A                   pop   dx
0x0000000000003a25:  C3                   ret   
0x0000000000003a26:  8E C1                mov   es, cx
0x0000000000003a28:  89 DE                mov   si, bx
0x0000000000003a2a:  8B 7E F8             mov   di, word ptr [bp - 8]
0x0000000000003a2d:  26 8B 74 08          mov   si, word ptr es:[si + 8]
0x0000000000003a31:  26 8B 4F 0A          mov   cx, word ptr es:[bx + 0xa]
0x0000000000003a35:  26 8B 45 06          mov   ax, word ptr es:[di + 6]
0x0000000000003a39:  26 8B 55 02          mov   dx, word ptr es:[di + 2]
0x0000000000003a3d:  89 46 FC             mov   word ptr [bp - 4], ax
0x0000000000003a40:  26 8B 5F 04          mov   bx, word ptr es:[bx + 4]
0x0000000000003a44:  26 8B 05             mov   ax, word ptr es:[di]
0x0000000000003a47:  89 CF                mov   di, cx
0x0000000000003a49:  8B 4E FC             mov   cx, word ptr [bp - 4]
0x0000000000003a4c:  0E                   push  cs
0x0000000000003a4d:  E8 86 58             call  0x92d6
0x0000000000003a50:  90                   nop   
0x0000000000003a51:  6A FF                push  -1
0x0000000000003a53:  8E 46 F6             mov   es, word ptr [bp - 0xa]
0x0000000000003a56:  8B 5E F8             mov   bx, word ptr [bp - 8]
0x0000000000003a59:  8B 76 F8             mov   si, word ptr [bp - 8]
0x0000000000003a5c:  6A 07                push  7
0x0000000000003a5e:  26 8B 4C 06          mov   cx, word ptr es:[si + 6]
0x0000000000003a62:  26 FF 77 0A          push  word ptr es:[bx + 0xa]
0x0000000000003a66:  8B 76 FA             mov   si, word ptr [bp - 6]
0x0000000000003a69:  26 FF 77 08          push  word ptr es:[bx + 8]
0x0000000000003a6d:  26 8B 5F 04          mov   bx, word ptr es:[bx + 4]
0x0000000000003a71:  2B 5C 12             sub   bx, word ptr [si + 0x12]
0x0000000000003a74:  1B 4C 14             sbb   cx, word ptr [si + 0x14]
0x0000000000003a77:  8B 76 F8             mov   si, word ptr [bp - 8]
0x0000000000003a7a:  26 8B 04             mov   ax, word ptr es:[si]
0x0000000000003a7d:  26 8B 54 02          mov   dx, word ptr es:[si + 2]
0x0000000000003a81:  8B 76 FA             mov   si, word ptr [bp - 6]
0x0000000000003a84:  2B 44 0E             sub   ax, word ptr [si + 0xe]
0x0000000000003a87:  1B 54 10             sbb   dx, word ptr [si + 0x10]
0x0000000000003a8a:  0E                   push  cs
0x0000000000003a8b:  E8 16 53             call  0x8da4
0x0000000000003a8e:  90                   nop   
0x0000000000003a8f:  BB BA 01             mov   bx, 0x1ba
0x0000000000003a92:  8B 1F                mov   bx, word ptr [bx]
0x0000000000003a94:  C7 47 18 01 00       mov   word ptr [bx + 0x18], 1
0x0000000000003a99:  E8 14 4F             call  0x89b0
0x0000000000003a9c:  24 03                and   al, 3
0x0000000000003a9e:  28 47 1B             sub   byte ptr [bx + 0x1b], al
0x0000000000003aa1:  8A 47 1B             mov   al, byte ptr [bx + 0x1b]
0x0000000000003aa4:  3C 01                cmp   al, 1
0x0000000000003aa6:  72 03                jb    0x3aab
0x0000000000003aa8:  E9 B5 01             jmp   0x3c60
0x0000000000003aab:  C6 47 1B 01          mov   byte ptr [bx + 0x1b], 1
0x0000000000003aaf:  8B 5E FA             mov   bx, word ptr [bp - 6]
0x0000000000003ab2:  8B 47 26             mov   ax, word ptr [bx + 0x26]
0x0000000000003ab5:  85 C0                test  ax, ax
0x0000000000003ab7:  75 03                jne   0x3abc
0x0000000000003ab9:  E9 65 FF             jmp   0x3a21
0x0000000000003abc:  6B D8 2C             imul  bx, ax, 0x2c
0x0000000000003abf:  81 C3 04 34          add   bx, 0x3404
0x0000000000003ac3:  74 F4                je    0x3ab9
0x0000000000003ac5:  83 7F 1C 00          cmp   word ptr [bx + 0x1c], 0
0x0000000000003ac9:  7E EE                jle   0x3ab9
0x0000000000003acb:  26 FF 77 06          push  word ptr es:[bx + 6]
0x0000000000003acf:  26 FF 77 04          push  word ptr es:[bx + 4]
0x0000000000003ad3:  26 FF 77 02          push  word ptr es:[bx + 2]
0x0000000000003ad7:  26 FF 37             push  word ptr es:[bx]
0x0000000000003ada:  8E 46 F6             mov   es, word ptr [bp - 0xa]
0x0000000000003add:  8B 5E F8             mov   bx, word ptr [bp - 8]
0x0000000000003ae0:  8B 76 F8             mov   si, word ptr [bp - 8]
0x0000000000003ae3:  26 8B 5F 04          mov   bx, word ptr es:[bx + 4]
0x0000000000003ae7:  26 8B 4C 06          mov   cx, word ptr es:[si + 6]
0x0000000000003aeb:  26 8B 04             mov   ax, word ptr es:[si]
0x0000000000003aee:  26 8B 54 02          mov   dx, word ptr es:[si + 2]
0x0000000000003af2:  0E                   push  cs
0x0000000000003af3:  E8 43 66             call  0xa139
0x0000000000003af6:  90                   nop   
0x0000000000003af7:  8E 46 F6             mov   es, word ptr [bp - 0xa]
0x0000000000003afa:  89 F3                mov   bx, si
0x0000000000003afc:  26 3B 57 10          cmp   dx, word ptr es:[bx + 0x10]
0x0000000000003b00:  75 06                jne   0x3b08
0x0000000000003b02:  26 3B 47 0E          cmp   ax, word ptr es:[bx + 0xe]
0x0000000000003b06:  74 3D                je    0x3b45
0x0000000000003b08:  89 C1                mov   cx, ax
0x0000000000003b0a:  26 2B 4F 0E          sub   cx, word ptr es:[bx + 0xe]
0x0000000000003b0e:  89 D3                mov   bx, dx
0x0000000000003b10:  26 1B 5C 10          sbb   bx, word ptr es:[si + 0x10]
0x0000000000003b14:  81 FB 00 80          cmp   bx, 0x8000
0x0000000000003b18:  77 09                ja    0x3b23
0x0000000000003b1a:  74 03                je    0x3b1f
0x0000000000003b1c:  E9 58 01             jmp   0x3c77
0x0000000000003b1f:  85 C9                test  cx, cx
0x0000000000003b21:  76 F9                jbe   0x3b1c
0x0000000000003b23:  89 F3                mov   bx, si
0x0000000000003b25:  89 C1                mov   cx, ax
0x0000000000003b27:  26 83 47 0E 00       add   word ptr es:[bx + 0xe], 0
0x0000000000003b2c:  26 81 57 10 00 F4    adc   word ptr es:[bx + 0x10], 0xf400
0x0000000000003b32:  26 2B 4F 0E          sub   cx, word ptr es:[bx + 0xe]
0x0000000000003b36:  89 D3                mov   bx, dx
0x0000000000003b38:  26 1B 5C 10          sbb   bx, word ptr es:[si + 0x10]
0x0000000000003b3c:  81 FB 00 80          cmp   bx, 0x8000
0x0000000000003b40:  73 03                jae   0x3b45
0x0000000000003b42:  E9 25 01             jmp   0x3c6a
0x0000000000003b45:  8B 5E FA             mov   bx, word ptr [bp - 6]
0x0000000000003b48:  8E 46 F6             mov   es, word ptr [bp - 0xa]
0x0000000000003b4b:  8A 47 1A             mov   al, byte ptr [bx + 0x1a]
0x0000000000003b4e:  30 E4                xor   ah, ah
0x0000000000003b50:  6B C0 0B             imul  ax, ax, 0xb
0x0000000000003b53:  8B 76 F8             mov   si, word ptr [bp - 8]
0x0000000000003b56:  26 8B 74 10          mov   si, word ptr es:[si + 0x10]
0x0000000000003b5a:  D1 EE                shr   si, 1
0x0000000000003b5c:  83 E6 FC             and   si, 0xfffc
0x0000000000003b5f:  89 C3                mov   bx, ax
0x0000000000003b61:  8A 87 64 C4          mov   al, byte ptr [bx - 0x3b9c]
0x0000000000003b65:  81 C3 64 C4          add   bx, 0xc464
0x0000000000003b69:  98                   cwde  
0x0000000000003b6a:  89 F2                mov   dx, si
0x0000000000003b6c:  89 C3                mov   bx, ax
0x0000000000003b6e:  B8 D6 33             mov   ax, 0x33d6
0x0000000000003b71:  9A 8D 5C 88 0A       lcall 0xa88:0x5c8d
0x0000000000003b76:  8B 5E FA             mov   bx, word ptr [bp - 6]
0x0000000000003b79:  89 47 0E             mov   word ptr [bx + 0xe], ax
0x0000000000003b7c:  8A 47 1A             mov   al, byte ptr [bx + 0x1a]
0x0000000000003b7f:  30 E4                xor   ah, ah
0x0000000000003b81:  6B C0 0B             imul  ax, ax, 0xb
0x0000000000003b84:  89 57 10             mov   word ptr [bx + 0x10], dx
0x0000000000003b87:  89 C3                mov   bx, ax
0x0000000000003b89:  8A 87 64 C4          mov   al, byte ptr [bx - 0x3b9c]
0x0000000000003b8d:  81 C3 64 C4          add   bx, 0xc464
0x0000000000003b91:  98                   cwde  
0x0000000000003b92:  89 F2                mov   dx, si
0x0000000000003b94:  89 C3                mov   bx, ax
0x0000000000003b96:  B8 D6 31             mov   ax, 0x31d6
0x0000000000003b99:  9A 8D 5C 88 0A       lcall 0xa88:0x5c8d
0x0000000000003b9e:  8B 5E FA             mov   bx, word ptr [bp - 6]
0x0000000000003ba1:  89 47 12             mov   word ptr [bx + 0x12], ax
0x0000000000003ba4:  89 57 14             mov   word ptr [bx + 0x14], dx
0x0000000000003ba7:  6B 5F 26 18          imul  bx, word ptr [bx + 0x26], 0x18
0x0000000000003bab:  B8 F5 6A             mov   ax, 0x6af5
0x0000000000003bae:  8B 76 F8             mov   si, word ptr [bp - 8]
0x0000000000003bb1:  8E C0                mov   es, ax
0x0000000000003bb3:  89 46 FC             mov   word ptr [bp - 4], ax
0x0000000000003bb6:  26 8B 7F 08          mov   di, word ptr es:[bx + 8]
0x0000000000003bba:  26 8B 47 0A          mov   ax, word ptr es:[bx + 0xa]
0x0000000000003bbe:  26 8B 4F 06          mov   cx, word ptr es:[bx + 6]
0x0000000000003bc2:  89 46 FE             mov   word ptr [bp - 2], ax
0x0000000000003bc5:  26 8B 47 04          mov   ax, word ptr es:[bx + 4]
0x0000000000003bc9:  8E 46 F6             mov   es, word ptr [bp - 0xa]
0x0000000000003bcc:  26 2B 44 04          sub   ax, word ptr es:[si + 4]
0x0000000000003bd0:  26 1B 4C 06          sbb   cx, word ptr es:[si + 6]
0x0000000000003bd4:  8E 46 FC             mov   es, word ptr [bp - 4]
0x0000000000003bd7:  26 8B 17             mov   dx, word ptr es:[bx]
0x0000000000003bda:  26 8B 77 02          mov   si, word ptr es:[bx + 2]
0x0000000000003bde:  8E 46 F6             mov   es, word ptr [bp - 0xa]
0x0000000000003be1:  8B 5E F8             mov   bx, word ptr [bp - 8]
0x0000000000003be4:  26 2B 17             sub   dx, word ptr es:[bx]
0x0000000000003be7:  26 1B 77 02          sbb   si, word ptr es:[bx + 2]
0x0000000000003beb:  89 C3                mov   bx, ax
0x0000000000003bed:  89 D0                mov   ax, dx
0x0000000000003bef:  89 F2                mov   dx, si
0x0000000000003bf1:  FF 1E D0 0C          lcall [0xcd0]
0x0000000000003bf5:  8B 5E FA             mov   bx, word ptr [bp - 6]
0x0000000000003bf8:  89 D0                mov   ax, dx
0x0000000000003bfa:  8A 57 1A             mov   dl, byte ptr [bx + 0x1a]
0x0000000000003bfd:  30 F6                xor   dh, dh
0x0000000000003bff:  6B D2 0B             imul  dx, dx, 0xb
0x0000000000003c02:  89 D3                mov   bx, dx
0x0000000000003c04:  8A 97 64 C4          mov   dl, byte ptr [bx - 0x3b9c]
0x0000000000003c08:  81 C3 64 C4          add   bx, 0xc464
0x0000000000003c0c:  30 F6                xor   dh, dh
0x0000000000003c0e:  89 D3                mov   bx, dx
0x0000000000003c10:  81 EB 80 00          sub   bx, 0x80
0x0000000000003c14:  99                   cdq   
0x0000000000003c15:  F7 FB                idiv  bx
0x0000000000003c17:  3D 01 00             cmp   ax, 1
0x0000000000003c1a:  7D 03                jge   0x3c1f
0x0000000000003c1c:  B8 01 00             mov   ax, 1
0x0000000000003c1f:  8E 46 F6             mov   es, word ptr [bp - 0xa]
0x0000000000003c22:  89 FA                mov   dx, di
0x0000000000003c24:  8B 5E F8             mov   bx, word ptr [bp - 8]
0x0000000000003c27:  83 C2 00             add   dx, 0
0x0000000000003c2a:  8B 4E FE             mov   cx, word ptr [bp - 2]
0x0000000000003c2d:  83 D1 28             adc   cx, 0x28
0x0000000000003c30:  26 2B 57 08          sub   dx, word ptr es:[bx + 8]
0x0000000000003c34:  26 1B 4F 0A          sbb   cx, word ptr es:[bx + 0xa]
0x0000000000003c38:  89 C3                mov   bx, ax
0x0000000000003c3a:  89 D0                mov   ax, dx
0x0000000000003c3c:  89 CA                mov   dx, cx
0x0000000000003c3e:  9A CB 5E 88 0A       lcall 0xa88:0x5ecb
0x0000000000003c43:  8B 5E FA             mov   bx, word ptr [bp - 6]
0x0000000000003c46:  3B 57 18             cmp   dx, word ptr [bx + 0x18]
0x0000000000003c49:  7C 07                jl    0x3c52
0x0000000000003c4b:  75 5F                jne   0x3cac
0x0000000000003c4d:  3B 47 16             cmp   ax, word ptr [bx + 0x16]
0x0000000000003c50:  73 5A                jae   0x3cac
0x0000000000003c52:  81 47 16 00 E0       add   word ptr [bx + 0x16], 0xe000
0x0000000000003c57:  83 57 18 FF          adc   word ptr [bx + 0x18], -1
0x0000000000003c5b:  C9                   leave 
0x0000000000003c5c:  5F                   pop   di
0x0000000000003c5d:  5E                   pop   si
0x0000000000003c5e:  5A                   pop   dx
0x0000000000003c5f:  C3                   ret   
0x0000000000003c60:  3C F0                cmp   al, 0xf0
0x0000000000003c62:  76 03                jbe   0x3c67
0x0000000000003c64:  E9 44 FE             jmp   0x3aab
0x0000000000003c67:  E9 45 FE             jmp   0x3aaf
0x0000000000003c6a:  89 F3                mov   bx, si
0x0000000000003c6c:  26 89 47 0E          mov   word ptr es:[bx + 0xe], ax
0x0000000000003c70:  26 89 57 10          mov   word ptr es:[bx + 0x10], dx
0x0000000000003c74:  E9 CE FE             jmp   0x3b45
0x0000000000003c77:  89 F3                mov   bx, si
0x0000000000003c79:  89 C1                mov   cx, ax
0x0000000000003c7b:  26 83 47 0E 00       add   word ptr es:[bx + 0xe], 0
0x0000000000003c80:  26 81 57 10 00 0C    adc   word ptr es:[bx + 0x10], 0xc00
0x0000000000003c86:  26 2B 4F 0E          sub   cx, word ptr es:[bx + 0xe]
0x0000000000003c8a:  89 D3                mov   bx, dx
0x0000000000003c8c:  26 1B 5C 10          sbb   bx, word ptr es:[si + 0x10]
0x0000000000003c90:  81 FB 00 80          cmp   bx, 0x8000
0x0000000000003c94:  77 09                ja    0x3c9f
0x0000000000003c96:  74 03                je    0x3c9b
0x0000000000003c98:  E9 AA FE             jmp   0x3b45
0x0000000000003c9b:  85 C9                test  cx, cx
0x0000000000003c9d:  76 F9                jbe   0x3c98
0x0000000000003c9f:  89 F3                mov   bx, si
0x0000000000003ca1:  26 89 47 0E          mov   word ptr es:[bx + 0xe], ax
0x0000000000003ca5:  26 89 57 10          mov   word ptr es:[bx + 0x10], dx
0x0000000000003ca9:  E9 99 FE             jmp   0x3b45
0x0000000000003cac:  81 47 16 00 20       add   word ptr [bx + 0x16], 0x2000
0x0000000000003cb1:  83 57 18 00          adc   word ptr [bx + 0x18], 0
0x0000000000003cb5:  C9                   leave 
0x0000000000003cb6:  5F                   pop   di
0x0000000000003cb7:  5E                   pop   si
0x0000000000003cb8:  5A                   pop   dx
0x0000000000003cb9:  C3                   ret   
0x0000000000003cba:  53                   push  bx
0x0000000000003cbb:  52                   push  dx
0x0000000000003cbc:  89 C3                mov   bx, ax
0x0000000000003cbe:  83 7F 22 00          cmp   word ptr [bx + 0x22], 0
0x0000000000003cc2:  75 03                jne   0x3cc7
0x0000000000003cc4:  5A                   pop   dx
0x0000000000003cc5:  5B                   pop   bx
0x0000000000003cc6:  C3                   ret   
0x0000000000003cc7:  E8 CC F7             call  0x3496
0x0000000000003cca:  BA 38 00             mov   dx, 0x38
0x0000000000003ccd:  89 D8                mov   ax, bx
0x0000000000003ccf:  0E                   push  cs
0x0000000000003cd0:  3E E8 7C C8          call  0x550
0x0000000000003cd4:  5A                   pop   dx
0x0000000000003cd5:  5B                   pop   bx
0x0000000000003cd6:  C3                   ret   
0x0000000000003cd7:  FC                   cld   
0x0000000000003cd8:  53                   push  bx
0x0000000000003cd9:  51                   push  cx
0x0000000000003cda:  52                   push  dx
0x0000000000003cdb:  56                   push  si
0x0000000000003cdc:  89 C6                mov   si, ax
0x0000000000003cde:  83 7C 22 00          cmp   word ptr [si + 0x22], 0
0x0000000000003ce2:  75 05                jne   0x3ce9
0x0000000000003ce4:  5E                   pop   si
0x0000000000003ce5:  5A                   pop   dx
0x0000000000003ce6:  59                   pop   cx
0x0000000000003ce7:  5B                   pop   bx
0x0000000000003ce8:  C3                   ret   
0x0000000000003ce9:  E8 AA F7             call  0x3496
0x0000000000003cec:  89 F0                mov   ax, si
0x0000000000003cee:  E8 ED EC             call  0x29de
0x0000000000003cf1:  84 C0                test  al, al
0x0000000000003cf3:  74 EF                je    0x3ce4
0x0000000000003cf5:  E8 B8 4C             call  0x89b0
0x0000000000003cf8:  30 E4                xor   ah, ah
0x0000000000003cfa:  B9 0A 00             mov   cx, 0xa
0x0000000000003cfd:  99                   cdq   
0x0000000000003cfe:  F7 F9                idiv  cx
0x0000000000003d00:  42                   inc   dx
0x0000000000003d01:  89 D1                mov   cx, dx
0x0000000000003d03:  C1 E1 02             shl   cx, 2
0x0000000000003d06:  89 F0                mov   ax, si
0x0000000000003d08:  29 D1                sub   cx, dx
0x0000000000003d0a:  BA 35 00             mov   dx, 0x35
0x0000000000003d0d:  0E                   push  cs
0x0000000000003d0e:  3E E8 3E C8          call  0x550
0x0000000000003d12:  6B 44 22 2C          imul  ax, word ptr [si + 0x22], 0x2c
0x0000000000003d16:  89 F3                mov   bx, si
0x0000000000003d18:  01 C9                add   cx, cx
0x0000000000003d1a:  89 F2                mov   dx, si
0x0000000000003d1c:  05 04 34             add   ax, 0x3404
0x0000000000003d1f:  0E                   push  cs
0x0000000000003d20:  3E E8 0C 24          call  0x6130
0x0000000000003d24:  5E                   pop   si
0x0000000000003d25:  5A                   pop   dx
0x0000000000003d26:  59                   pop   cx
0x0000000000003d27:  5B                   pop   bx
0x0000000000003d28:  C3                   ret   
0x0000000000003d29:  FC                   cld   
0x0000000000003d2a:  56                   push  si
0x0000000000003d2b:  57                   push  di
0x0000000000003d2c:  55                   push  bp
0x0000000000003d2d:  89 E5                mov   bp, sp
0x0000000000003d2f:  83 EC 06             sub   sp, 6
0x0000000000003d32:  50                   push  ax
0x0000000000003d33:  89 D6                mov   si, dx
0x0000000000003d35:  89 4E FE             mov   word ptr [bp - 2], cx
0x0000000000003d38:  C7 46 FA B2 00       mov   word ptr [bp - 6], 0xb2
0x0000000000003d3d:  8E C1                mov   es, cx
0x0000000000003d3f:  C7 46 FC D9 92       mov   word ptr [bp - 4], 0x92d9
0x0000000000003d44:  26 F6 47 16 10       test  byte ptr es:[bx + 0x16], 0x10
0x0000000000003d49:  74 06                je    0x3d51
0x0000000000003d4b:  80 7C 1B FF          cmp   byte ptr [si + 0x1b], 0xff
0x0000000000003d4f:  74 06                je    0x3d57
0x0000000000003d51:  B0 01                mov   al, 1
0x0000000000003d53:  C9                   leave 
0x0000000000003d54:  5F                   pop   di
0x0000000000003d55:  5E                   pop   si
0x0000000000003d56:  C3                   ret   
0x0000000000003d57:  8A 44 1A             mov   al, byte ptr [si + 0x1a]
0x0000000000003d5a:  30 E4                xor   ah, ah
0x0000000000003d5c:  FF 5E FA             lcall [bp - 6]
0x0000000000003d5f:  85 C0                test  ax, ax
0x0000000000003d61:  74 EE                je    0x3d51
0x0000000000003d63:  8A 44 1A             mov   al, byte ptr [si + 0x1a]
0x0000000000003d66:  30 E4                xor   ah, ah
0x0000000000003d68:  6B C0 0B             imul  ax, ax, 0xb
0x0000000000003d6b:  89 C7                mov   di, ax
0x0000000000003d6d:  81 C7 65 C4          add   di, 0xc465
0x0000000000003d71:  8A 05                mov   al, byte ptr [di]
0x0000000000003d73:  BF 86 C4             mov   di, 0xc486
0x0000000000003d76:  30 E4                xor   ah, ah
0x0000000000003d78:  8A 0D                mov   cl, byte ptr [di]
0x0000000000003d7a:  BF FC 00             mov   di, 0xfc
0x0000000000003d7d:  30 ED                xor   ch, ch
0x0000000000003d7f:  8E 46 FE             mov   es, word ptr [bp - 2]
0x0000000000003d82:  01 C1                add   cx, ax
0x0000000000003d84:  26 8B 07             mov   ax, word ptr es:[bx]
0x0000000000003d87:  26 8B 57 02          mov   dx, word ptr es:[bx + 2]
0x0000000000003d8b:  2B 05                sub   ax, word ptr [di]
0x0000000000003d8d:  1B 55 02             sbb   dx, word ptr [di + 2]
0x0000000000003d90:  0B D2                or    dx, dx
0x0000000000003d92:  7D 07                jge   0x3d9b
0x0000000000003d94:  F7 D8                neg   ax
0x0000000000003d96:  83 D2 00             adc   dx, 0
0x0000000000003d99:  F7 DA                neg   dx
0x0000000000003d9b:  39 CA                cmp   dx, cx
0x0000000000003d9d:  7F B2                jg    0x3d51
0x0000000000003d9f:  75 04                jne   0x3da5
0x0000000000003da1:  85 C0                test  ax, ax
0x0000000000003da3:  77 AC                ja    0x3d51
0x0000000000003da5:  BF 00 01             mov   di, 0x100
0x0000000000003da8:  26 8B 47 04          mov   ax, word ptr es:[bx + 4]
0x0000000000003dac:  26 8B 57 06          mov   dx, word ptr es:[bx + 6]
0x0000000000003db0:  2B 05                sub   ax, word ptr [di]
0x0000000000003db2:  1B 55 02             sbb   dx, word ptr [di + 2]
0x0000000000003db5:  0B D2                or    dx, dx
0x0000000000003db7:  7D 07                jge   0x3dc0
0x0000000000003db9:  F7 D8                neg   ax
0x0000000000003dbb:  83 D2 00             adc   dx, 0
0x0000000000003dbe:  F7 DA                neg   dx
0x0000000000003dc0:  39 CA                cmp   dx, cx
0x0000000000003dc2:  7F 8D                jg    0x3d51
0x0000000000003dc4:  75 04                jne   0x3dca
0x0000000000003dc6:  85 C0                test  ax, ax
0x0000000000003dc8:  77 87                ja    0x3d51
0x0000000000003dca:  BF 2E 01             mov   di, 0x12e
0x0000000000003dcd:  8B 46 F8             mov   ax, word ptr [bp - 8]
0x0000000000003dd0:  89 05                mov   word ptr [di], ax
0x0000000000003dd2:  C7 44 12 00 00       mov   word ptr [si + 0x12], 0
0x0000000000003dd7:  C7 44 14 00 00       mov   word ptr [si + 0x14], 0
0x0000000000003ddc:  D1 64 0A             shl   word ptr [si + 0xa], 1
0x0000000000003ddf:  D1 54 0C             rcl   word ptr [si + 0xc], 1
0x0000000000003de2:  D1 64 0A             shl   word ptr [si + 0xa], 1
0x0000000000003de5:  D1 54 0C             rcl   word ptr [si + 0xc], 1
0x0000000000003de8:  8B 44 12             mov   ax, word ptr [si + 0x12]
0x0000000000003deb:  8B 54 14             mov   dx, word ptr [si + 0x14]
0x0000000000003dee:  89 44 0E             mov   word ptr [si + 0xe], ax
0x0000000000003df1:  89 54 10             mov   word ptr [si + 0x10], dx
0x0000000000003df4:  26 FF 77 06          push  word ptr es:[bx + 6]
0x0000000000003df8:  26 8B 07             mov   ax, word ptr es:[bx]
0x0000000000003dfb:  26 8B 4F 02          mov   cx, word ptr es:[bx + 2]
0x0000000000003dff:  8B 54 04             mov   dx, word ptr [si + 4]
0x0000000000003e02:  26 FF 77 04          push  word ptr es:[bx + 4]
0x0000000000003e06:  89 C3                mov   bx, ax
0x0000000000003e08:  89 F0                mov   ax, si
0x0000000000003e0a:  FF 1E E0 0C          lcall [0xce0]
0x0000000000003e0e:  D1 7C 0C             sar   word ptr [si + 0xc], 1
0x0000000000003e11:  D1 5C 0A             rcr   word ptr [si + 0xa], 1
0x0000000000003e14:  D1 7C 0C             sar   word ptr [si + 0xc], 1
0x0000000000003e17:  D1 5C 0A             rcr   word ptr [si + 0xa], 1
0x0000000000003e1a:  84 C0                test  al, al
0x0000000000003e1c:  75 03                jne   0x3e21
0x0000000000003e1e:  E9 30 FF             jmp   0x3d51
0x0000000000003e21:  30 C0                xor   al, al
0x0000000000003e23:  C9                   leave 
0x0000000000003e24:  5F                   pop   di
0x0000000000003e25:  5E                   pop   si
0x0000000000003e26:  C3                   ret   
0x0000000000003e27:  FC                   cld   
0x0000000000003e28:  53                   push  bx
0x0000000000003e29:  51                   push  cx
0x0000000000003e2a:  8B 5E F8             mov   bx, word ptr [bp - 8]
0x0000000000003e2d:  E8 54 EF             call  0x2d84
0x0000000000003e30:  8B 47 22             mov   ax, word ptr [bx + 0x22]
0x0000000000003e33:  6B C0 2C             imul  ax, ax, 0x2c
0x0000000000003e36:  6A 09                push  9
0x0000000000003e38:  BE BA 01             mov   si, 0x1ba
0x0000000000003e3b:  05 04 34             add   ax, 0x3404
0x0000000000003e3e:  8B 5E F6             mov   bx, word ptr [bp - 0xa]
0x0000000000003e41:  89 46 FC             mov   word ptr [bp - 4], ax
0x0000000000003e44:  89 C2                mov   dx, ax
0x0000000000003e46:  8B 46 F8             mov   ax, word ptr [bp - 8]
0x0000000000003e49:  BF 34 07             mov   di, 0x734
0x0000000000003e4c:  FF 1E F8 0C          lcall [0xcf8]
0x0000000000003e50:  8B 34                mov   si, word ptr [si]
0x0000000000003e52:  C4 1D                les   bx, ptr [di]
0x0000000000003e54:  26 83 47 0E 00       add   word ptr es:[bx + 0xe], 0
0x0000000000003e59:  26 81 57 10 00 FC    adc   word ptr es:[bx + 0x10], 0xfc00
0x0000000000003e5f:  26 8B 47 10          mov   ax, word ptr es:[bx + 0x10]
0x0000000000003e63:  8A 5C 1A             mov   bl, byte ptr [si + 0x1a]
0x0000000000003e66:  30 FF                xor   bh, bh
0x0000000000003e68:  6B DB 0B             imul  bx, bx, 0xb
0x0000000000003e6b:  D1 E8                shr   ax, 1
0x0000000000003e6d:  24 FC                and   al, 0xfc
0x0000000000003e6f:  89 46 FE             mov   word ptr [bp - 2], ax
0x0000000000003e72:  8B 56 FE             mov   dx, word ptr [bp - 2]
0x0000000000003e75:  8A 87 64 C4          mov   al, byte ptr [bx - 0x3b9c]
0x0000000000003e79:  98                   cwde  
0x0000000000003e7a:  81 C3 64 C4          add   bx, 0xc464
0x0000000000003e7e:  89 46 FA             mov   word ptr [bp - 6], ax
0x0000000000003e81:  89 C3                mov   bx, ax
0x0000000000003e83:  B8 D6 33             mov   ax, 0x33d6
0x0000000000003e86:  9A 91 5C 88 0A       lcall 0xa88:0x5c91
0x0000000000003e8b:  89 44 0E             mov   word ptr [si + 0xe], ax
0x0000000000003e8e:  8B 5E FA             mov   bx, word ptr [bp - 6]
0x0000000000003e91:  89 54 10             mov   word ptr [si + 0x10], dx
0x0000000000003e94:  8B 56 FE             mov   dx, word ptr [bp - 2]
0x0000000000003e97:  B8 D6 31             mov   ax, 0x31d6
0x0000000000003e9a:  9A 91 5C 88 0A       lcall 0xa88:0x5c91
0x0000000000003e9f:  6A 09                push  9
0x0000000000003ea1:  8B 5E F6             mov   bx, word ptr [bp - 0xa]
0x0000000000003ea4:  89 44 12             mov   word ptr [si + 0x12], ax
0x0000000000003ea7:  8B 4E F4             mov   cx, word ptr [bp - 0xc]
0x0000000000003eaa:  89 54 14             mov   word ptr [si + 0x14], dx
0x0000000000003ead:  8B 56 FC             mov   dx, word ptr [bp - 4]
0x0000000000003eb0:  8B 46 F8             mov   ax, word ptr [bp - 8]
0x0000000000003eb3:  BE BA 01             mov   si, 0x1ba
0x0000000000003eb6:  FF 1E F8 0C          lcall [0xcf8]
0x0000000000003eba:  8B 34                mov   si, word ptr [si]
0x0000000000003ebc:  C4 1D                les   bx, ptr [di]
0x0000000000003ebe:  26 83 47 0E 00       add   word ptr es:[bx + 0xe], 0
0x0000000000003ec3:  26 81 57 10 00 04    adc   word ptr es:[bx + 0x10], 0x400
0x0000000000003ec9:  26 8B 47 10          mov   ax, word ptr es:[bx + 0x10]
0x0000000000003ecd:  D1 E8                shr   ax, 1
0x0000000000003ecf:  24 FC                and   al, 0xfc
0x0000000000003ed1:  8B 5E FA             mov   bx, word ptr [bp - 6]
0x0000000000003ed4:  89 46 FE             mov   word ptr [bp - 2], ax
0x0000000000003ed7:  89 C2                mov   dx, ax
0x0000000000003ed9:  B8 D6 33             mov   ax, 0x33d6
0x0000000000003edc:  9A 91 5C 88 0A       lcall 0xa88:0x5c91
0x0000000000003ee1:  89 44 0E             mov   word ptr [si + 0xe], ax
0x0000000000003ee4:  8B 5E FA             mov   bx, word ptr [bp - 6]
0x0000000000003ee7:  89 54 10             mov   word ptr [si + 0x10], dx
0x0000000000003eea:  8B 56 FE             mov   dx, word ptr [bp - 2]
0x0000000000003eed:  B8 D6 31             mov   ax, 0x31d6
0x0000000000003ef0:  9A 91 5C 88 0A       lcall 0xa88:0x5c91
0x0000000000003ef5:  89 44 12             mov   word ptr [si + 0x12], ax
0x0000000000003ef8:  89 54 14             mov   word ptr [si + 0x14], dx
0x0000000000003efb:  C9                   leave 
0x0000000000003efc:  5F                   pop   di
0x0000000000003efd:  5E                   pop   si
0x0000000000003efe:  5A                   pop   dx
0x0000000000003eff:  C3                   ret   
0x0000000000003f00:  52                   push  dx
0x0000000000003f01:  56                   push  si
0x0000000000003f02:  57                   push  di
0x0000000000003f03:  55                   push  bp
0x0000000000003f04:  89 E5                mov   bp, sp
0x0000000000003f06:  83 EC 10             sub   sp, 0x10
0x0000000000003f09:  89 C6                mov   si, ax
0x0000000000003f0b:  89 DF                mov   di, bx
0x0000000000003f0d:  89 4E FE             mov   word ptr [bp - 2], cx
0x0000000000003f10:  C7 46 F0 B8 02       mov   word ptr [bp - 0x10], 0x2b8
0x0000000000003f15:  C7 46 F2 D9 92       mov   word ptr [bp - 0xe], 0x92d9
0x0000000000003f1a:  83 7C 22 00          cmp   word ptr [si + 0x22], 0
0x0000000000003f1e:  75 05                jne   0x3f25
0x0000000000003f20:  C9                   leave 
0x0000000000003f21:  5F                   pop   di
0x0000000000003f22:  5E                   pop   si
0x0000000000003f23:  5A                   pop   dx
0x0000000000003f24:  C3                   ret   
0x0000000000003f25:  8E C1                mov   es, cx
0x0000000000003f27:  26 80 4D 17 01       or    byte ptr es:[di + 0x17], 1
0x0000000000003f2c:  8A 44 1A             mov   al, byte ptr [si + 0x1a]
0x0000000000003f2f:  30 E4                xor   ah, ah
0x0000000000003f31:  8B 4C 22             mov   cx, word ptr [si + 0x22]
0x0000000000003f34:  FF 5E F0             lcall [bp - 0x10]
0x0000000000003f37:  88 C2                mov   dl, al
0x0000000000003f39:  89 F0                mov   ax, si
0x0000000000003f3b:  30 F6                xor   dh, dh
0x0000000000003f3d:  0E                   push  cs
0x0000000000003f3e:  3E E8 FC BE          call  0xfe3e
0x0000000000003f42:  89 F0                mov   ax, si
0x0000000000003f44:  E8 3D EE             call  0x2d84
0x0000000000003f47:  6B C1 2C             imul  ax, cx, 0x2c
0x0000000000003f4a:  6B D9 18             imul  bx, cx, 0x18
0x0000000000003f4d:  05 04 34             add   ax, 0x3404
0x0000000000003f50:  8E 46 FE             mov   es, word ptr [bp - 2]
0x0000000000003f53:  89 46 F8             mov   word ptr [bp - 8], ax
0x0000000000003f56:  26 8B 45 10          mov   ax, word ptr es:[di + 0x10]
0x0000000000003f5a:  D1 E8                shr   ax, 1
0x0000000000003f5c:  24 FC                and   al, 0xfc
0x0000000000003f5e:  89 46 F4             mov   word ptr [bp - 0xc], ax
0x0000000000003f61:  89 C2                mov   dx, ax
0x0000000000003f63:  89 5E F6             mov   word ptr [bp - 0xa], bx
0x0000000000003f66:  89 5E FA             mov   word ptr [bp - 6], bx
0x0000000000003f69:  B8 D6 33             mov   ax, 0x33d6
0x0000000000003f6c:  BB 14 00             mov   bx, 0x14
0x0000000000003f6f:  9A 91 5C 88 0A       lcall 0xa88:0x5c91
0x0000000000003f74:  89 44 0E             mov   word ptr [si + 0xe], ax
0x0000000000003f77:  BB 14 00             mov   bx, 0x14
0x0000000000003f7a:  89 54 10             mov   word ptr [si + 0x10], dx
0x0000000000003f7d:  8B 56 F4             mov   dx, word ptr [bp - 0xc]
0x0000000000003f80:  B8 D6 31             mov   ax, 0x31d6
0x0000000000003f83:  C7 46 FC F5 6A       mov   word ptr [bp - 4], 0x6af5
0x0000000000003f88:  9A 91 5C 88 0A       lcall 0xa88:0x5c91
0x0000000000003f8d:  89 44 12             mov   word ptr [si + 0x12], ax
0x0000000000003f90:  8B 5E F6             mov   bx, word ptr [bp - 0xa]
0x0000000000003f93:  89 54 14             mov   word ptr [si + 0x14], dx
0x0000000000003f96:  8E 46 FC             mov   es, word ptr [bp - 4]
0x0000000000003f99:  26 8B 47 04          mov   ax, word ptr es:[bx + 4]
0x0000000000003f9d:  26 8B 4F 06          mov   cx, word ptr es:[bx + 6]
0x0000000000003fa1:  8E 46 FE             mov   es, word ptr [bp - 2]
0x0000000000003fa4:  26 2B 45 04          sub   ax, word ptr es:[di + 4]
0x0000000000003fa8:  26 1B 4D 06          sbb   cx, word ptr es:[di + 6]
0x0000000000003fac:  8E 46 FC             mov   es, word ptr [bp - 4]
0x0000000000003faf:  26 8B 17             mov   dx, word ptr es:[bx]
0x0000000000003fb2:  89 56 F6             mov   word ptr [bp - 0xa], dx
0x0000000000003fb5:  26 8B 57 02          mov   dx, word ptr es:[bx + 2]
0x0000000000003fb9:  8E 46 FE             mov   es, word ptr [bp - 2]
0x0000000000003fbc:  26 8B 1D             mov   bx, word ptr es:[di]
0x0000000000003fbf:  29 5E F6             sub   word ptr [bp - 0xa], bx
0x0000000000003fc2:  89 C3                mov   bx, ax
0x0000000000003fc4:  26 1B 55 02          sbb   dx, word ptr es:[di + 2]
0x0000000000003fc8:  8B 46 F6             mov   ax, word ptr [bp - 0xa]
0x0000000000003fcb:  FF 1E D0 0C          lcall [0xcd0]
0x0000000000003fcf:  89 D0                mov   ax, dx
0x0000000000003fd1:  B9 14 00             mov   cx, 0x14
0x0000000000003fd4:  99                   cdq   
0x0000000000003fd5:  F7 F9                idiv  cx
0x0000000000003fd7:  89 C1                mov   cx, ax
0x0000000000003fd9:  3D 01 00             cmp   ax, 1
0x0000000000003fdc:  73 03                jae   0x3fe1
0x0000000000003fde:  B9 01 00             mov   cx, 1
0x0000000000003fe1:  8B 5E F8             mov   bx, word ptr [bp - 8]
0x0000000000003fe4:  8B 47 0A             mov   ax, word ptr [bx + 0xa]
0x0000000000003fe7:  8B 57 0C             mov   dx, word ptr [bx + 0xc]
0x0000000000003fea:  8E 46 FC             mov   es, word ptr [bp - 4]
0x0000000000003fed:  D1 FA                sar   dx, 1
0x0000000000003fef:  D1 D8                rcr   ax, 1
0x0000000000003ff1:  8B 5E FA             mov   bx, word ptr [bp - 6]
0x0000000000003ff4:  89 56 F6             mov   word ptr [bp - 0xa], dx
0x0000000000003ff7:  26 03 47 08          add   ax, word ptr es:[bx + 8]
0x0000000000003ffb:  26 8B 57 0A          mov   dx, word ptr es:[bx + 0xa]
0x0000000000003fff:  8E 46 FE             mov   es, word ptr [bp - 2]
0x0000000000004002:  13 56 F6             adc   dx, word ptr [bp - 0xa]
0x0000000000004005:  89 CB                mov   bx, cx
0x0000000000004007:  26 2B 45 08          sub   ax, word ptr es:[di + 8]
0x000000000000400b:  26 1B 55 0A          sbb   dx, word ptr es:[di + 0xa]
0x000000000000400f:  9A CB 5E 88 0A       lcall 0xa88:0x5ecb
0x0000000000004014:  89 44 16             mov   word ptr [si + 0x16], ax
0x0000000000004017:  89 54 18             mov   word ptr [si + 0x18], dx
0x000000000000401a:  C9                   leave 
0x000000000000401b:  5F                   pop   di
0x000000000000401c:  5E                   pop   si
0x000000000000401d:  5A                   pop   dx
0x000000000000401e:  C3                   ret   
0x000000000000401f:  FC                   cld   
0x0000000000004020:  52                   push  dx
0x0000000000004021:  56                   push  si
0x0000000000004022:  57                   push  di
0x0000000000004023:  55                   push  bp
0x0000000000004024:  89 E5                mov   bp, sp
0x0000000000004026:  83 EC 10             sub   sp, 0x10
0x0000000000004029:  89 C7                mov   di, ax
0x000000000000402b:  89 4E F6             mov   word ptr [bp - 0xa], cx
0x000000000000402e:  BB 02 34             mov   bx, 0x3402
0x0000000000004031:  8B 07                mov   ax, word ptr [bx]
0x0000000000004033:  31 D2                xor   dx, dx
0x0000000000004035:  85 C0                test  ax, ax
0x0000000000004037:  74 1F                je    0x4058
0x0000000000004039:  6B D8 2C             imul  bx, ax, 0x2c
0x000000000000403c:  8B 8F 00 34          mov   cx, word ptr [bx + 0x3400]
0x0000000000004040:  30 C9                xor   cl, cl
0x0000000000004042:  80 E5 F8             and   ch, 0xf8
0x0000000000004045:  81 F9 00 08          cmp   cx, 0x800
0x0000000000004049:  75 08                jne   0x4053
0x000000000000404b:  80 BF 1A 34 12       cmp   byte ptr [bx + 0x341a], 0x12
0x0000000000004050:  75 01                jne   0x4053
0x0000000000004052:  42                   inc   dx
0x0000000000004053:  83 FA 14             cmp   dx, 0x14
0x0000000000004056:  7E 0A                jle   0x4062
0x0000000000004058:  83 FA 14             cmp   dx, 0x14
0x000000000000405b:  7E 12                jle   0x406f
0x000000000000405d:  C9                   leave 
0x000000000000405e:  5F                   pop   di
0x000000000000405f:  5E                   pop   si
0x0000000000004060:  5A                   pop   dx
0x0000000000004061:  C3                   ret   
0x0000000000004062:  6B D8 2C             imul  bx, ax, 0x2c
0x0000000000004065:  8B 87 02 34          mov   ax, word ptr [bx + 0x3402]
0x0000000000004069:  85 C0                test  ax, ax
0x000000000000406b:  75 CC                jne   0x4039
0x000000000000406d:  EB E9                jmp   0x4058
0x000000000000406f:  8B 46 F6             mov   ax, word ptr [bp - 0xa]
0x0000000000004072:  D1 E8                shr   ax, 1
0x0000000000004074:  24 FC                and   al, 0xfc
0x0000000000004076:  89 46 FA             mov   word ptr [bp - 6], ax
0x0000000000004079:  8B 45 22             mov   ax, word ptr [di + 0x22]
0x000000000000407c:  89 46 F8             mov   word ptr [bp - 8], ax
0x000000000000407f:  8A 45 1A             mov   al, byte ptr [di + 0x1a]
0x0000000000004082:  30 E4                xor   ah, ah
0x0000000000004084:  6B C0 0B             imul  ax, ax, 0xb
0x0000000000004087:  89 C3                mov   bx, ax
0x0000000000004089:  81 C3 65 C4          add   bx, 0xc465
0x000000000000408d:  8A 07                mov   al, byte ptr [bx]
0x000000000000408f:  BB 2B C5             mov   bx, 0xc52b
0x0000000000004092:  8A 17                mov   dl, byte ptr [bx]
0x0000000000004094:  30 E4                xor   ah, ah
0x0000000000004096:  30 F6                xor   dh, dh
0x0000000000004098:  01 C2                add   dx, ax
0x000000000000409a:  D1 FA                sar   dx, 1
0x000000000000409c:  89 D0                mov   ax, dx
0x000000000000409e:  C1 E0 02             shl   ax, 2
0x00000000000040a1:  29 D0                sub   ax, dx
0x00000000000040a3:  BB 2C 00             mov   bx, 0x2c
0x00000000000040a6:  05 04 00             add   ax, 4
0x00000000000040a9:  31 D2                xor   dx, dx
0x00000000000040ab:  89 46 FC             mov   word ptr [bp - 4], ax
0x00000000000040ae:  8D 85 FC CB          lea   ax, [di - 0x3404]
0x00000000000040b2:  F7 F3                div   bx
0x00000000000040b4:  6B F0 18             imul  si, ax, 0x18
0x00000000000040b7:  8B 4E FC             mov   cx, word ptr [bp - 4]
0x00000000000040ba:  8B 56 FA             mov   dx, word ptr [bp - 6]
0x00000000000040bd:  31 DB                xor   bx, bx
0x00000000000040bf:  B8 D6 33             mov   ax, 0x33d6
0x00000000000040c2:  C7 46 F4 F5 6A       mov   word ptr [bp - 0xc], 0x6af5
0x00000000000040c7:  9A 03 5C 88 0A       lcall 0xa88:0x5c03
0x00000000000040cc:  8E 46 F4             mov   es, word ptr [bp - 0xc]
0x00000000000040cf:  26 8B 1C             mov   bx, word ptr es:[si]
0x00000000000040d2:  01 C3                add   bx, ax
0x00000000000040d4:  89 5E F2             mov   word ptr [bp - 0xe], bx
0x00000000000040d7:  89 F3                mov   bx, si
0x00000000000040d9:  8B 4E FC             mov   cx, word ptr [bp - 4]
0x00000000000040dc:  26 8B 47 02          mov   ax, word ptr es:[bx + 2]
0x00000000000040e0:  11 D0                adc   ax, dx
0x00000000000040e2:  8B 56 FA             mov   dx, word ptr [bp - 6]
0x00000000000040e5:  89 46 F0             mov   word ptr [bp - 0x10], ax
0x00000000000040e8:  31 F3                xor   bx, si
0x00000000000040ea:  B8 D6 31             mov   ax, 0x31d6
0x00000000000040ed:  9A 03 5C 88 0A       lcall 0xa88:0x5c03
0x00000000000040f2:  8E 46 F4             mov   es, word ptr [bp - 0xc]
0x00000000000040f5:  6A FF                push  -1
0x00000000000040f7:  89 D1                mov   cx, dx
0x00000000000040f9:  89 F3                mov   bx, si
0x00000000000040fb:  26 8B 54 04          mov   dx, word ptr es:[si + 4]
0x00000000000040ff:  6A 12                push  0x12
0x0000000000004101:  01 C2                add   dx, ax
0x0000000000004103:  26 8B 44 0A          mov   ax, word ptr es:[si + 0xa]
0x0000000000004107:  26 13 4F 06          adc   cx, word ptr es:[bx + 6]
0x000000000000410b:  05 08 00             add   ax, 8
0x000000000000410e:  26 8B 5C 08          mov   bx, word ptr es:[si + 8]
0x0000000000004112:  50                   push  ax
0x0000000000004113:  8B 46 F2             mov   ax, word ptr [bp - 0xe]
0x0000000000004116:  53                   push  bx
0x0000000000004117:  89 D3                mov   bx, dx
0x0000000000004119:  8B 56 F0             mov   dx, word ptr [bp - 0x10]
0x000000000000411c:  0E                   push  cs
0x000000000000411d:  E8 72 45             call  0x8692
0x0000000000004120:  90                   nop   
0x0000000000004121:  BB BA 01             mov   bx, 0x1ba
0x0000000000004124:  8B 1F                mov   bx, word ptr [bx]
0x0000000000004126:  89 5E FE             mov   word ptr [bp - 2], bx
0x0000000000004129:  BB 34 07             mov   bx, 0x734
0x000000000000412c:  8B 57 02             mov   dx, word ptr [bx + 2]
0x000000000000412f:  8B 37                mov   si, word ptr [bx]
0x0000000000004131:  8E C2                mov   es, dx
0x0000000000004133:  26 FF 74 06          push  word ptr es:[si + 6]
0x0000000000004137:  8B 46 FE             mov   ax, word ptr [bp - 2]
0x000000000000413a:  26 FF 74 04          push  word ptr es:[si + 4]
0x000000000000413e:  89 F3                mov   bx, si
0x0000000000004140:  26 FF 74 02          push  word ptr es:[si + 2]
0x0000000000004144:  89 D1                mov   cx, dx
0x0000000000004146:  26 FF 34             push  word ptr es:[si]
0x0000000000004149:  FF 1E DC 0C          lcall [0xcdc]
0x000000000000414d:  84 C0                test  al, al
0x000000000000414f:  75 14                jne   0x4165
0x0000000000004151:  B9 10 27             mov   cx, 0x2710
0x0000000000004154:  8B 46 FE             mov   ax, word ptr [bp - 2]
0x0000000000004157:  89 FB                mov   bx, di
0x0000000000004159:  89 FA                mov   dx, di
0x000000000000415b:  0E                   push  cs
0x000000000000415c:  3E E8 BE 18          call  0x5a1e
0x0000000000004160:  C9                   leave 
0x0000000000004161:  5F                   pop   di
0x0000000000004162:  5E                   pop   si
0x0000000000004163:  5A                   pop   dx
0x0000000000004164:  C3                   ret   
0x0000000000004165:  8B 46 F8             mov   ax, word ptr [bp - 8]
0x0000000000004168:  8B 5E FE             mov   bx, word ptr [bp - 2]
0x000000000000416b:  89 D1                mov   cx, dx
0x000000000000416d:  89 47 22             mov   word ptr [bx + 0x22], ax
0x0000000000004170:  8B 46 FE             mov   ax, word ptr [bp - 2]
0x0000000000004173:  89 F3                mov   bx, si
0x0000000000004175:  E8 88 FD             call  0x3f00
0x0000000000004178:  C9                   leave 
0x0000000000004179:  5F                   pop   di
0x000000000000417a:  5E                   pop   si
0x000000000000417b:  5A                   pop   dx
0x000000000000417c:  C3                   ret   
0x000000000000417d:  FC                   cld   
0x000000000000417e:  56                   push  si
0x000000000000417f:  89 C6                mov   si, ax
0x0000000000004181:  83 7C 22 00          cmp   word ptr [si + 0x22], 0
0x0000000000004185:  75 02                jne   0x4189
0x0000000000004187:  5E                   pop   si
0x0000000000004188:  C3                   ret   
0x0000000000004189:  E8 F8 EB             call  0x2d84
0x000000000000418c:  8E C1                mov   es, cx
0x000000000000418e:  26 8B 47 0E          mov   ax, word ptr es:[bx + 0xe]
0x0000000000004192:  26 8B 4F 10          mov   cx, word ptr es:[bx + 0x10]
0x0000000000004196:  89 C3                mov   bx, ax
0x0000000000004198:  89 F0                mov   ax, si
0x000000000000419a:  E8 83 FE             call  0x4020
0x000000000000419d:  5E                   pop   si
0x000000000000419e:  C3                   ret   
0x000000000000419f:  FC                   cld   
0x00000000000041a0:  52                   push  dx
0x00000000000041a1:  56                   push  si
0x00000000000041a2:  57                   push  di
0x00000000000041a3:  89 C6                mov   si, ax
0x00000000000041a5:  8E C1                mov   es, cx
0x00000000000041a7:  26 8B 7F 0E          mov   di, word ptr es:[bx + 0xe]
0x00000000000041ab:  26 8B 57 10          mov   dx, word ptr es:[bx + 0x10]
0x00000000000041af:  26 80 67 14 FD       and   byte ptr es:[bx + 0x14], 0xfd
0x00000000000041b4:  80 C6 40             add   dh, 0x40
0x00000000000041b7:  89 FB                mov   bx, di
0x00000000000041b9:  89 D1                mov   cx, dx
0x00000000000041bb:  E8 62 FE             call  0x4020
0x00000000000041be:  80 C6 40             add   dh, 0x40
0x00000000000041c1:  89 FB                mov   bx, di
0x00000000000041c3:  89 F0                mov   ax, si
0x00000000000041c5:  89 D1                mov   cx, dx
0x00000000000041c7:  E8 56 FE             call  0x4020
0x00000000000041ca:  80 C6 40             add   dh, 0x40
0x00000000000041cd:  89 FB                mov   bx, di
0x00000000000041cf:  89 F0                mov   ax, si
0x00000000000041d1:  89 D1                mov   cx, dx
0x00000000000041d3:  E8 4A FE             call  0x4020
0x00000000000041d6:  5F                   pop   di
0x00000000000041d7:  5E                   pop   si
0x00000000000041d8:  5A                   pop   dx
0x00000000000041d9:  C3                   ret   
0x00000000000041da:  53                   push  bx
0x00000000000041db:  52                   push  dx
0x00000000000041dc:  56                   push  si
0x00000000000041dd:  89 C3                mov   bx, ax
0x00000000000041df:  8A 47 1A             mov   al, byte ptr [bx + 0x1a]
0x00000000000041e2:  30 E4                xor   ah, ah
0x00000000000041e4:  6B C0 0B             imul  ax, ax, 0xb
0x00000000000041e7:  89 C6                mov   si, ax
0x00000000000041e9:  8A 84 63 C4          mov   al, byte ptr [si - 0x3b9d]
0x00000000000041ed:  81 C6 63 C4          add   si, 0xc463
0x00000000000041f1:  3C 3B                cmp   al, 0x3b
0x00000000000041f3:  73 31                jae   0x4226
0x00000000000041f5:  84 C0                test  al, al
0x00000000000041f7:  74 29                je    0x4222
0x00000000000041f9:  8A 47 1A             mov   al, byte ptr [bx + 0x1a]
0x00000000000041fc:  30 E4                xor   ah, ah
0x00000000000041fe:  6B C0 0B             imul  ax, ax, 0xb
0x0000000000004201:  89 C6                mov   si, ax
0x0000000000004203:  8A 84 63 C4          mov   al, byte ptr [si - 0x3b9d]
0x0000000000004207:  81 C6 63 C4          add   si, 0xc463
0x000000000000420b:  80 7F 1A 13          cmp   byte ptr [bx + 0x1a], 0x13
0x000000000000420f:  74 06                je    0x4217
0x0000000000004211:  80 7F 1A 15          cmp   byte ptr [bx + 0x1a], 0x15
0x0000000000004215:  75 47                jne   0x425e
0x0000000000004217:  88 C2                mov   dl, al
0x0000000000004219:  30 F6                xor   dh, dh
0x000000000000421b:  31 C0                xor   ax, ax
0x000000000000421d:  0E                   push  cs
0x000000000000421e:  3E E8 1C BC          call  0xfe3e
0x0000000000004222:  5E                   pop   si
0x0000000000004223:  5A                   pop   dx
0x0000000000004224:  5B                   pop   bx
0x0000000000004225:  C3                   ret   
0x0000000000004226:  3C 3D                cmp   al, 0x3d
0x0000000000004228:  76 22                jbe   0x424c
0x000000000000422a:  3C 3F                cmp   al, 0x3f
0x000000000000422c:  77 CB                ja    0x41f9
0x000000000000422e:  E8 6D 40             call  0x829e
0x0000000000004231:  88 C2                mov   dl, al
0x0000000000004233:  30 F6                xor   dh, dh
0x0000000000004235:  89 D0                mov   ax, dx
0x0000000000004237:  C1 F8 0F             sar   ax, 0xf
0x000000000000423a:  31 C2                xor   dx, ax
0x000000000000423c:  29 C2                sub   dx, ax
0x000000000000423e:  83 E2 01             and   dx, 1
0x0000000000004241:  31 C2                xor   dx, ax
0x0000000000004243:  29 C2                sub   dx, ax
0x0000000000004245:  89 D0                mov   ax, dx
0x0000000000004247:  05 3E 00             add   ax, 0x3e
0x000000000000424a:  EB BF                jmp   0x420b
0x000000000000424c:  E8 4F 40             call  0x829e
0x000000000000424f:  30 E4                xor   ah, ah
0x0000000000004251:  BE 03 00             mov   si, 3
0x0000000000004254:  99                   cdq   
0x0000000000004255:  F7 FE                idiv  si
0x0000000000004257:  89 D0                mov   ax, dx
0x0000000000004259:  05 3B 00             add   ax, 0x3b
0x000000000000425c:  EB AD                jmp   0x420b
0x000000000000425e:  88 C2                mov   dl, al
0x0000000000004260:  89 D8                mov   ax, bx
0x0000000000004262:  30 F6                xor   dh, dh
0x0000000000004264:  0E                   push  cs
0x0000000000004265:  E8 D6 BB             call  0xfe3e
0x0000000000004268:  90                   nop   
0x0000000000004269:  5E                   pop   si
0x000000000000426a:  5A                   pop   dx
0x000000000000426b:  5B                   pop   bx
0x000000000000426c:  C3                   ret   
0x000000000000426d:  FC                   cld   
0x000000000000426e:  52                   push  dx
0x000000000000426f:  BA 1F 00             mov   dx, 0x1f
0x0000000000004272:  0E                   push  cs
0x0000000000004273:  E8 C8 BB             call  0xfe3e
0x0000000000004276:  90                   nop   
0x0000000000004277:  5A                   pop   dx
0x0000000000004278:  C3                   ret   
0x0000000000004279:  FC                   cld   
0x000000000000427a:  53                   push  bx
0x000000000000427b:  52                   push  dx
0x000000000000427c:  55                   push  bp
0x000000000000427d:  89 E5                mov   bp, sp
0x000000000000427f:  83 EC 04             sub   sp, 4
0x0000000000004282:  89 C3                mov   bx, ax
0x0000000000004284:  C7 46 FC 84 02       mov   word ptr [bp - 4], 0x284
0x0000000000004289:  8A 47 1A             mov   al, byte ptr [bx + 0x1a]
0x000000000000428c:  C7 46 FE D9 92       mov   word ptr [bp - 2], 0x92d9
0x0000000000004291:  30 E4                xor   ah, ah
0x0000000000004293:  FF 5E FC             lcall [bp - 4]
0x0000000000004296:  30 E4                xor   ah, ah
0x0000000000004298:  89 C2                mov   dx, ax
0x000000000000429a:  89 D8                mov   ax, bx
0x000000000000429c:  0E                   push  cs
0x000000000000429d:  E8 9E BB             call  0xfe3e
0x00000000000042a0:  90                   nop   
0x00000000000042a1:  C9                   leave 
0x00000000000042a2:  5A                   pop   dx
0x00000000000042a3:  5B                   pop   bx
0x00000000000042a4:  C3                   ret   
0x00000000000042a5:  FC                   cld   
0x00000000000042a6:  8E C1                mov   es, cx
0x00000000000042a8:  26 80 67 14 FD       and   byte ptr es:[bx + 0x14], 0xfd
0x00000000000042ad:  C3                   ret   
0x00000000000042ae:  52                   push  dx
0x00000000000042af:  56                   push  si
0x00000000000042b0:  89 C6                mov   si, ax
0x00000000000042b2:  89 DA                mov   dx, bx
0x00000000000042b4:  6B 5C 22 2C          imul  bx, word ptr [si + 0x22], 0x2c
0x00000000000042b8:  B9 80 00             mov   cx, 0x80
0x00000000000042bb:  81 C3 04 34          add   bx, 0x3404
0x00000000000042bf:  FF 1E F0 0C          lcall [0xcf0]
0x00000000000042c3:  5E                   pop   si
0x00000000000042c4:  5A                   pop   dx
0x00000000000042c5:  C3                   ret   
0x00000000000042c6:  A8 4A                test  al, 0x4a
0x00000000000042c8:  BB 4A C9             mov   bx, 0xc94a
0x00000000000042cb:  4A                   dec   dx
0x00000000000042cc:  D7                   xlatb 
0x00000000000042cd:  4A                   dec   dx
0x00000000000042ce:  53                   push  bx
0x00000000000042cf:  51                   push  cx
0x00000000000042d0:  52                   push  dx
0x00000000000042d1:  56                   push  si
0x00000000000042d2:  89 C3                mov   bx, ax
0x00000000000042d4:  BE EB 02             mov   si, 0x2eb
0x00000000000042d7:  8A 4F 1A             mov   cl, byte ptr [bx + 0x1a]
0x00000000000042da:  80 3C 00             cmp   byte ptr [si], 0
0x00000000000042dd:  75 03                jne   0x42e2
0x00000000000042df:  E9 7B 00             jmp   0x435d
0x00000000000042e2:  BE BF 03             mov   si, 0x3bf
0x00000000000042e5:  80 3C 07             cmp   byte ptr [si], 7
0x00000000000042e8:  74 03                je    0x42ed
0x00000000000042ea:  E9 6B 00             jmp   0x4358
0x00000000000042ed:  80 F9 08             cmp   cl, 8
0x00000000000042f0:  74 05                je    0x42f7
0x00000000000042f2:  80 F9 14             cmp   cl, 0x14
0x00000000000042f5:  75 61                jne   0x4358
0x00000000000042f7:  BE E8 07             mov   si, 0x7e8
0x00000000000042fa:  83 3C 00             cmp   word ptr [si], 0
0x00000000000042fd:  7E 59                jle   0x4358
0x00000000000042ff:  8D 87 FC CB          lea   ax, [bx - 0x3404]
0x0000000000004303:  31 D2                xor   dx, dx
0x0000000000004305:  BB 2C 00             mov   bx, 0x2c
0x0000000000004308:  F7 F3                div   bx
0x000000000000430a:  BB 02 34             mov   bx, 0x3402
0x000000000000430d:  89 C6                mov   si, ax
0x000000000000430f:  8B 07                mov   ax, word ptr [bx]
0x0000000000004311:  85 C0                test  ax, ax
0x0000000000004313:  74 1D                je    0x4332
0x0000000000004315:  6B D8 2C             imul  bx, ax, 0x2c
0x0000000000004318:  8B 97 00 34          mov   dx, word ptr [bx + 0x3400]
0x000000000000431c:  30 D2                xor   dl, dl
0x000000000000431e:  80 E6 F8             and   dh, 0xf8
0x0000000000004321:  81 FA 00 08          cmp   dx, 0x800
0x0000000000004325:  74 54                je    0x437b
0x0000000000004327:  6B D8 2C             imul  bx, ax, 0x2c
0x000000000000432a:  8B 87 02 34          mov   ax, word ptr [bx + 0x3402]
0x000000000000432e:  85 C0                test  ax, ax
0x0000000000004330:  75 E3                jne   0x4315
0x0000000000004332:  BB EB 02             mov   bx, 0x2eb
0x0000000000004335:  80 3F 00             cmp   byte ptr [bx], 0
0x0000000000004338:  74 59                je    0x4393
0x000000000000433a:  BB BF 03             mov   bx, 0x3bf
0x000000000000433d:  80 3F 07             cmp   byte ptr [bx], 7
0x0000000000004340:  75 62                jne   0x43a4
0x0000000000004342:  80 F9 08             cmp   cl, 8
0x0000000000004345:  74 60                je    0x43a7
0x0000000000004347:  80 F9 14             cmp   cl, 0x14
0x000000000000434a:  75 58                jne   0x43a4
0x000000000000434c:  BB 05 00             mov   bx, 5
0x000000000000434f:  BA FF FF             mov   dx, 0xffff
0x0000000000004352:  B8 3E 00             mov   ax, 0x3e
0x0000000000004355:  E8 28 08             call  0x4b80
0x0000000000004358:  5E                   pop   si
0x0000000000004359:  5A                   pop   dx
0x000000000000435a:  59                   pop   cx
0x000000000000435b:  5B                   pop   bx
0x000000000000435c:  C3                   ret   
0x000000000000435d:  BE E5 00             mov   si, 0xe5
0x0000000000004360:  80 3C 00             cmp   byte ptr [si], 0
0x0000000000004363:  75 18                jne   0x437d
0x0000000000004365:  BE BF 03             mov   si, 0x3bf
0x0000000000004368:  80 3C 08             cmp   byte ptr [si], 8
0x000000000000436b:  75 EB                jne   0x4358
0x000000000000436d:  80 F9 0F             cmp   cl, 0xf
0x0000000000004370:  75 85                jne   0x42f7
0x0000000000004372:  BE BE 03             mov   si, 0x3be
0x0000000000004375:  80 3C 01             cmp   byte ptr [si], 1
0x0000000000004378:  E9 7A FF             jmp   0x42f5
0x000000000000437b:  EB 6A                jmp   0x43e7
0x000000000000437d:  BE BE 03             mov   si, 0x3be
0x0000000000004380:  8A 04                mov   al, byte ptr [si]
0x0000000000004382:  FE C8                dec   al
0x0000000000004384:  3C 03                cmp   al, 3
0x0000000000004386:  77 56                ja    0x43de
0x0000000000004388:  30 E4                xor   ah, ah
0x000000000000438a:  89 C6                mov   si, ax
0x000000000000438c:  01 C6                add   si, ax
0x000000000000438e:  2E FF A4 D8 49       jmp   word ptr cs:[si + 0x49d8]
0x0000000000004393:  E9 7E 00             jmp   0x4414
0x0000000000004396:  BE BF 03             mov   si, 0x3bf
0x0000000000004399:  80 3C 08             cmp   byte ptr [si], 8
0x000000000000439c:  75 BA                jne   0x4358
0x000000000000439e:  80 F9 0F             cmp   cl, 0xf
0x00000000000043a1:  E9 51 FF             jmp   0x42f5
0x00000000000043a4:  E9 A8 00             jmp   0x444f
0x00000000000043a7:  EB 5A                jmp   0x4403
0x00000000000043a9:  BE BF 03             mov   si, 0x3bf
0x00000000000043ac:  80 3C 08             cmp   byte ptr [si], 8
0x00000000000043af:  75 A7                jne   0x4358
0x00000000000043b1:  80 F9 15             cmp   cl, 0x15
0x00000000000043b4:  E9 3E FF             jmp   0x42f5
0x00000000000043b7:  BE BF 03             mov   si, 0x3bf
0x00000000000043ba:  80 3C 08             cmp   byte ptr [si], 8
0x00000000000043bd:  75 99                jne   0x4358
0x00000000000043bf:  80 F9 13             cmp   cl, 0x13
0x00000000000043c2:  E9 30 FF             jmp   0x42f5
0x00000000000043c5:  BE BF 03             mov   si, 0x3bf
0x00000000000043c8:  8A 04                mov   al, byte ptr [si]
0x00000000000043ca:  3C 08                cmp   al, 8
0x00000000000043cc:  75 06                jne   0x43d4
0x00000000000043ce:  80 F9 13             cmp   cl, 0x13
0x00000000000043d1:  E9 21 FF             jmp   0x42f5
0x00000000000043d4:  3C 06                cmp   al, 6
0x00000000000043d6:  75 80                jne   0x4358
0x00000000000043d8:  80 F9 15             cmp   cl, 0x15
0x00000000000043db:  E9 17 FF             jmp   0x42f5
0x00000000000043de:  BE BF 03             mov   si, 0x3bf
0x00000000000043e1:  80 3C 08             cmp   byte ptr [si], 8
0x00000000000043e4:  E9 0E FF             jmp   0x42f5
0x00000000000043e7:  81 C3 04 34          add   bx, 0x3404
0x00000000000043eb:  39 F0                cmp   ax, si
0x00000000000043ed:  75 03                jne   0x43f2
0x00000000000043ef:  E9 35 FF             jmp   0x4327
0x00000000000043f2:  3A 4F 1A             cmp   cl, byte ptr [bx + 0x1a]
0x00000000000043f5:  75 F8                jne   0x43ef
0x00000000000043f7:  83 7F 1C 00          cmp   word ptr [bx + 0x1c], 0
0x00000000000043fb:  7E 03                jle   0x4400
0x00000000000043fd:  E9 58 FF             jmp   0x4358
0x0000000000004400:  E9 24 FF             jmp   0x4327
0x0000000000004403:  BB 01 00             mov   bx, 1
0x0000000000004406:  BA FF FF             mov   dx, 0xffff
0x0000000000004409:  B8 3D 00             mov   ax, 0x3d
0x000000000000440c:  E8 71 07             call  0x4b80
0x000000000000440f:  5E                   pop   si
0x0000000000004410:  5A                   pop   dx
0x0000000000004411:  59                   pop   cx
0x0000000000004412:  5B                   pop   bx
0x0000000000004413:  C3                   ret   
0x0000000000004414:  BB BE 03             mov   bx, 0x3be
0x0000000000004417:  8A 07                mov   al, byte ptr [bx]
0x0000000000004419:  3C 04                cmp   al, 4
0x000000000000441b:  75 1D                jne   0x443a
0x000000000000441d:  BB BF 03             mov   bx, 0x3bf
0x0000000000004420:  8A 07                mov   al, byte ptr [bx]
0x0000000000004422:  3C 08                cmp   al, 8
0x0000000000004424:  74 18                je    0x443e
0x0000000000004426:  3C 06                cmp   al, 6
0x0000000000004428:  75 25                jne   0x444f
0x000000000000442a:  BA 06 00             mov   dx, 6
0x000000000000442d:  B8 3D 00             mov   ax, 0x3d
0x0000000000004430:  0E                   push  cs
0x0000000000004431:  E8 3E D9             call  0x1d72
0x0000000000004434:  90                   nop   
0x0000000000004435:  5E                   pop   si
0x0000000000004436:  5A                   pop   dx
0x0000000000004437:  59                   pop   cx
0x0000000000004438:  5B                   pop   bx
0x0000000000004439:  C3                   ret   
0x000000000000443a:  3C 01                cmp   al, 1
0x000000000000443c:  75 11                jne   0x444f
0x000000000000443e:  BB 01 00             mov   bx, 1
0x0000000000004441:  BA FF FF             mov   dx, 0xffff
0x0000000000004444:  B8 3D 00             mov   ax, 0x3d
0x0000000000004447:  E8 36 07             call  0x4b80
0x000000000000444a:  5E                   pop   si
0x000000000000444b:  5A                   pop   dx
0x000000000000444c:  59                   pop   cx
0x000000000000444d:  5B                   pop   bx
0x000000000000444e:  C3                   ret   
0x000000000000444f:  9A 68 19 88 0A       lcall 0xa88:0x1968
0x0000000000004454:  5E                   pop   si
0x0000000000004455:  5A                   pop   dx
0x0000000000004456:  59                   pop   cx
0x0000000000004457:  5B                   pop   bx
0x0000000000004458:  C3                   ret   
0x0000000000004459:  FC                   cld   
0x000000000000445a:  52                   push  dx
0x000000000000445b:  56                   push  si
0x000000000000445c:  89 C6                mov   si, ax
0x000000000000445e:  BA 54 00             mov   dx, 0x54
0x0000000000004461:  0E                   push  cs
0x0000000000004462:  3E E8 D8 B9          call  0xfe3e
0x0000000000004466:  89 F0                mov   ax, si
0x0000000000004468:  E8 33 E7             call  0x2b9e
0x000000000000446b:  5E                   pop   si
0x000000000000446c:  5A                   pop   dx
0x000000000000446d:  C3                   ret   
0x000000000000446e:  52                   push  dx
0x000000000000446f:  56                   push  si
0x0000000000004470:  89 C6                mov   si, ax
0x0000000000004472:  BA 55 00             mov   dx, 0x55
0x0000000000004475:  0E                   push  cs
0x0000000000004476:  3E E8 C4 B9          call  0xfe3e
0x000000000000447a:  89 F0                mov   ax, si
0x000000000000447c:  E8 1F E7             call  0x2b9e
0x000000000000447f:  5E                   pop   si
0x0000000000004480:  5A                   pop   dx
0x0000000000004481:  C3                   ret   
0x0000000000004482:  52                   push  dx
0x0000000000004483:  56                   push  si
0x0000000000004484:  89 C6                mov   si, ax
0x0000000000004486:  BA 4F 00             mov   dx, 0x4f
0x0000000000004489:  0E                   push  cs
0x000000000000448a:  3E E8 B0 B9          call  0xfe3e
0x000000000000448e:  89 F0                mov   ax, si
0x0000000000004490:  E8 0B E7             call  0x2b9e
0x0000000000004493:  5E                   pop   si
0x0000000000004494:  5A                   pop   dx
0x0000000000004495:  C3                   ret   
0x0000000000004496:  53                   push  bx
0x0000000000004497:  52                   push  dx
0x0000000000004498:  BB 28 01             mov   bx, 0x128
0x000000000000449b:  C7 07 00 00          mov   word ptr [bx], 0
0x000000000000449f:  BB 2A 01             mov   bx, 0x12a
0x00000000000044a2:  C7 07 00 00          mov   word ptr [bx], 0
0x00000000000044a6:  BB 02 34             mov   bx, 0x3402
0x00000000000044a9:  8B 07                mov   ax, word ptr [bx]
0x00000000000044ab:  85 C0                test  ax, ax
0x00000000000044ad:  74 1D                je    0x44cc
0x00000000000044af:  6B D8 2C             imul  bx, ax, 0x2c
0x00000000000044b2:  8B 97 00 34          mov   dx, word ptr [bx + 0x3400]
0x00000000000044b6:  30 D2                xor   dl, dl
0x00000000000044b8:  80 E6 F8             and   dh, 0xf8
0x00000000000044bb:  81 FA 00 08          cmp   dx, 0x800
0x00000000000044bf:  74 18                je    0x44d9
0x00000000000044c1:  6B D8 2C             imul  bx, ax, 0x2c
0x00000000000044c4:  8B 87 02 34          mov   ax, word ptr [bx + 0x3402]
0x00000000000044c8:  85 C0                test  ax, ax
0x00000000000044ca:  75 E3                jne   0x44af
0x00000000000044cc:  BA 60 00             mov   dx, 0x60
0x00000000000044cf:  31 C0                xor   ax, ax
0x00000000000044d1:  0E                   push  cs
0x00000000000044d2:  3E E8 68 B9          call  0xfe3e
0x00000000000044d6:  5A                   pop   dx
0x00000000000044d7:  5B                   pop   bx
0x00000000000044d8:  C3                   ret   
0x00000000000044d9:  81 C3 04 34          add   bx, 0x3404
0x00000000000044dd:  80 7F 1A 1B          cmp   byte ptr [bx + 0x1a], 0x1b
0x00000000000044e1:  75 DE                jne   0x44c1
0x00000000000044e3:  BB 28 01             mov   bx, 0x128
0x00000000000044e6:  8B 1F                mov   bx, word ptr [bx]
0x00000000000044e8:  01 DB                add   bx, bx
0x00000000000044ea:  89 87 B0 04          mov   word ptr [bx + 0x4b0], ax
0x00000000000044ee:  BB 28 01             mov   bx, 0x128
0x00000000000044f1:  FF 07                inc   word ptr [bx]
0x00000000000044f3:  EB CC                jmp   0x44c1
0x00000000000044f5:  FC                   cld   
0x00000000000044f6:  52                   push  dx
0x00000000000044f7:  BA 61 00             mov   dx, 0x61
0x00000000000044fa:  31 C0                xor   ax, ax
0x00000000000044fc:  0E                   push  cs
0x00000000000044fd:  E8 3E B9             call  0xfe3e
0x0000000000004500:  90                   nop   
0x0000000000004501:  5A                   pop   dx
0x0000000000004502:  C3                   ret   
0x0000000000004503:  FC                   cld   
0x0000000000004504:  52                   push  dx
0x0000000000004505:  56                   push  si
0x0000000000004506:  57                   push  di
0x0000000000004507:  55                   push  bp
0x0000000000004508:  89 E5                mov   bp, sp
0x000000000000450a:  83 EC 06             sub   sp, 6
0x000000000000450d:  89 DF                mov   di, bx
0x000000000000450f:  89 4E FE             mov   word ptr [bp - 2], cx
0x0000000000004512:  8E C1                mov   es, cx
0x0000000000004514:  C7 46 FA 00 00       mov   word ptr [bp - 6], 0
0x0000000000004519:  26 8B 05             mov   ax, word ptr es:[di]
0x000000000000451c:  26 8B 75 02          mov   si, word ptr es:[di + 2]
0x0000000000004520:  89 46 FC             mov   word ptr [bp - 4], ax
0x0000000000004523:  81 EE C4 00          sub   si, 0xc4
0x0000000000004527:  8E 46 FE             mov   es, word ptr [bp - 2]
0x000000000000452a:  26 8B 45 02          mov   ax, word ptr es:[di + 2]
0x000000000000452e:  05 40 01             add   ax, 0x140
0x0000000000004531:  39 C6                cmp   si, ax
0x0000000000004533:  7C 0F                jl    0x4544
0x0000000000004535:  BA 62 00             mov   dx, 0x62
0x0000000000004538:  31 C0                xor   ax, ax
0x000000000000453a:  0E                   push  cs
0x000000000000453b:  E8 00 B9             call  0xfe3e
0x000000000000453e:  90                   nop   
0x000000000000453f:  C9                   leave 
0x0000000000004540:  5F                   pop   di
0x0000000000004541:  5E                   pop   si
0x0000000000004542:  5A                   pop   dx
0x0000000000004543:  C3                   ret   
0x0000000000004544:  26 8B 55 04          mov   dx, word ptr es:[di + 4]
0x0000000000004548:  26 8B 4D 06          mov   cx, word ptr es:[di + 6]
0x000000000000454c:  E8 4F 3D             call  0x829e
0x000000000000454f:  88 C3                mov   bl, al
0x0000000000004551:  30 FF                xor   bh, bh
0x0000000000004553:  6A FF                push  -1
0x0000000000004555:  01 DB                add   bx, bx
0x0000000000004557:  6A 21                push  0x21
0x0000000000004559:  81 C3 80 00          add   bx, 0x80
0x000000000000455d:  81 E9 40 01          sub   cx, 0x140
0x0000000000004561:  53                   push  bx
0x0000000000004562:  8B 46 FC             mov   ax, word ptr [bp - 4]
0x0000000000004565:  FF 76 FA             push  word ptr [bp - 6]
0x0000000000004568:  89 D3                mov   bx, dx
0x000000000000456a:  89 F2                mov   dx, si
0x000000000000456c:  0E                   push  cs
0x000000000000456d:  E8 22 41             call  0x8692
0x0000000000004570:  90                   nop   
0x0000000000004571:  BB BA 01             mov   bx, 0x1ba
0x0000000000004574:  8B 1F                mov   bx, word ptr [bx]
0x0000000000004576:  E8 25 3D             call  0x829e
0x0000000000004579:  88 C1                mov   cl, al
0x000000000000457b:  30 ED                xor   ch, ch
0x000000000000457d:  89 C8                mov   ax, cx
0x000000000000457f:  C1 E0 09             shl   ax, 9
0x0000000000004582:  99                   cdq   
0x0000000000004583:  89 47 16             mov   word ptr [bx + 0x16], ax
0x0000000000004586:  89 57 18             mov   word ptr [bx + 0x18], dx
0x0000000000004589:  BA 1F 03             mov   dx, 0x31f
0x000000000000458c:  89 D8                mov   ax, bx
0x000000000000458e:  0E                   push  cs
0x000000000000458f:  E8 4A 43             call  0x88dc
0x0000000000004592:  90                   nop   
0x0000000000004593:  E8 08 3D             call  0x829e
0x0000000000004596:  24 07                and   al, 7
0x0000000000004598:  28 47 1B             sub   byte ptr [bx + 0x1b], al
0x000000000000459b:  8A 47 1B             mov   al, byte ptr [bx + 0x1b]
0x000000000000459e:  3C 01                cmp   al, 1
0x00000000000045a0:  73 0A                jae   0x45ac
0x00000000000045a2:  C6 47 1B 01          mov   byte ptr [bx + 0x1b], 1
0x00000000000045a6:  83 C6 08             add   si, 8
0x00000000000045a9:  E9 7B FF             jmp   0x4527
0x00000000000045ac:  3C F0                cmp   al, 0xf0
0x00000000000045ae:  77 F2                ja    0x45a2
0x00000000000045b0:  83 C6 08             add   si, 8
0x00000000000045b3:  E9 71 FF             jmp   0x4527
0x00000000000045b6:  52                   push  dx
0x00000000000045b7:  56                   push  si
0x00000000000045b8:  57                   push  di
0x00000000000045b9:  E8 E2 3C             call  0x829e
0x00000000000045bc:  88 C2                mov   dl, al
0x00000000000045be:  E8 DD 3C             call  0x829e
0x00000000000045c1:  30 F6                xor   dh, dh
0x00000000000045c3:  30 E4                xor   ah, ah
0x00000000000045c5:  29 C2                sub   dx, ax
0x00000000000045c7:  8E C1                mov   es, cx
0x00000000000045c9:  89 D0                mov   ax, dx
0x00000000000045cb:  26 8B 37             mov   si, word ptr es:[bx]
0x00000000000045ce:  C1 E0 0B             shl   ax, 0xb
0x00000000000045d1:  26 8B 7F 04          mov   di, word ptr es:[bx + 4]
0x00000000000045d5:  99                   cdq   
0x00000000000045d6:  26 8B 4F 06          mov   cx, word ptr es:[bx + 6]
0x00000000000045da:  01 C6                add   si, ax
0x00000000000045dc:  26 13 57 02          adc   dx, word ptr es:[bx + 2]
0x00000000000045e0:  E8 BB 3C             call  0x829e
0x00000000000045e3:  30 E4                xor   ah, ah
0x00000000000045e5:  6A FF                push  -1
0x00000000000045e7:  01 C0                add   ax, ax
0x00000000000045e9:  6A 21                push  0x21
0x00000000000045eb:  05 80 00             add   ax, 0x80
0x00000000000045ee:  50                   push  ax
0x00000000000045ef:  89 FB                mov   bx, di
0x00000000000045f1:  6A 00                push  0
0x00000000000045f3:  89 F0                mov   ax, si
0x00000000000045f5:  0E                   push  cs
0x00000000000045f6:  3E E8 98 40          call  0x8692
0x00000000000045fa:  BB BA 01             mov   bx, 0x1ba
0x00000000000045fd:  8B 1F                mov   bx, word ptr [bx]
0x00000000000045ff:  E8 9C 3C             call  0x829e
0x0000000000004602:  30 E4                xor   ah, ah
0x0000000000004604:  C1 E0 09             shl   ax, 9
0x0000000000004607:  99                   cdq   
0x0000000000004608:  89 47 16             mov   word ptr [bx + 0x16], ax
0x000000000000460b:  89 57 18             mov   word ptr [bx + 0x18], dx
0x000000000000460e:  BA 1F 03             mov   dx, 0x31f
0x0000000000004611:  89 D8                mov   ax, bx
0x0000000000004613:  0E                   push  cs
0x0000000000004614:  3E E8 C4 42          call  0x88dc
0x0000000000004618:  E8 83 3C             call  0x829e
0x000000000000461b:  24 07                and   al, 7
0x000000000000461d:  28 47 1B             sub   byte ptr [bx + 0x1b], al
0x0000000000004620:  8A 47 1B             mov   al, byte ptr [bx + 0x1b]
0x0000000000004623:  3C 01                cmp   al, 1
0x0000000000004625:  72 08                jb    0x462f
0x0000000000004627:  3C F0                cmp   al, 0xf0
0x0000000000004629:  77 04                ja    0x462f
0x000000000000462b:  5F                   pop   di
0x000000000000462c:  5E                   pop   si
0x000000000000462d:  5A                   pop   dx
0x000000000000462e:  C3                   ret   
0x000000000000462f:  C6 47 1B 01          mov   byte ptr [bx + 0x1b], 1
0x0000000000004633:  5F                   pop   di
0x0000000000004634:  5E                   pop   si
0x0000000000004635:  5A                   pop   dx
0x0000000000004636:  C3                   ret   
0x0000000000004637:  FC                   cld   
0x0000000000004638:  52                   push  dx
0x0000000000004639:  56                   push  si
0x000000000000463a:  57                   push  di
0x000000000000463b:  55                   push  bp
0x000000000000463c:  89 E5                mov   bp, sp
0x000000000000463e:  83 EC 0A             sub   sp, 0xa
0x0000000000004641:  89 C7                mov   di, ax
0x0000000000004643:  89 DE                mov   si, bx
0x0000000000004645:  89 4E FE             mov   word ptr [bp - 2], cx
0x0000000000004648:  BB 2C 01             mov   bx, 0x12c
0x000000000000464b:  80 37 01             xor   byte ptr [bx], 1
0x000000000000464e:  80 3E 14 22 01       cmp   byte ptr [0x2214], 1
0x0000000000004653:  77 0A                ja    0x465f
0x0000000000004655:  80 3F 00             cmp   byte ptr [bx], 0
0x0000000000004658:  75 05                jne   0x465f
0x000000000000465a:  C9                   leave 
0x000000000000465b:  5F                   pop   di
0x000000000000465c:  5E                   pop   si
0x000000000000465d:  5A                   pop   dx
0x000000000000465e:  C3                   ret   
0x000000000000465f:  BB 2A 01             mov   bx, 0x12a
0x0000000000004662:  8B 1F                mov   bx, word ptr [bx]
0x0000000000004664:  01 DB                add   bx, bx
0x0000000000004666:  8B 87 B0 04          mov   ax, word ptr [bx + 0x4b0]
0x000000000000466a:  BB 2A 01             mov   bx, 0x12a
0x000000000000466d:  89 46 F8             mov   word ptr [bp - 8], ax
0x0000000000004670:  8B 07                mov   ax, word ptr [bx]
0x0000000000004672:  40                   inc   ax
0x0000000000004673:  BB 28 01             mov   bx, 0x128
0x0000000000004676:  99                   cdq   
0x0000000000004677:  F7 3F                idiv  word ptr [bx]
0x0000000000004679:  BB 2A 01             mov   bx, 0x12a
0x000000000000467c:  89 17                mov   word ptr [bx], dx
0x000000000000467e:  6B 56 F8 2C          imul  dx, word ptr [bp - 8], 0x2c
0x0000000000004682:  6B 5E F8 18          imul  bx, word ptr [bp - 8], 0x18
0x0000000000004686:  6A 1C                push  0x1c
0x0000000000004688:  8B 4E FE             mov   cx, word ptr [bp - 2]
0x000000000000468b:  89 F8                mov   ax, di
0x000000000000468d:  81 C2 04 34          add   dx, 0x3404
0x0000000000004691:  89 5E FC             mov   word ptr [bp - 4], bx
0x0000000000004694:  89 F3                mov   bx, si
0x0000000000004696:  BF BA 01             mov   di, 0x1ba
0x0000000000004699:  FF 1E F8 0C          lcall [0xcf8]
0x000000000000469d:  BB 34 07             mov   bx, 0x734
0x00000000000046a0:  8B 46 F8             mov   ax, word ptr [bp - 8]
0x00000000000046a3:  8B 3D                mov   di, word ptr [di]
0x00000000000046a5:  C4 17                les   dx, ptr [bx]
0x00000000000046a7:  89 D3                mov   bx, dx
0x00000000000046a9:  89 45 22             mov   word ptr [di + 0x22], ax
0x00000000000046ac:  26 8B 57 12          mov   dx, word ptr es:[bx + 0x12]
0x00000000000046b0:  89 D3                mov   bx, dx
0x00000000000046b2:  C1 E3 02             shl   bx, 2
0x00000000000046b5:  29 D3                sub   bx, dx
0x00000000000046b7:  BA 74 7D             mov   dx, 0x7d74
0x00000000000046ba:  01 DB                add   bx, bx
0x00000000000046bc:  8E C2                mov   es, dx
0x00000000000046be:  26 8A 47 02          mov   al, byte ptr es:[bx + 2]
0x00000000000046c2:  C7 46 F6 F5 6A       mov   word ptr [bp - 0xa], 0x6af5
0x00000000000046c7:  98                   cwde  
0x00000000000046c8:  83 C3 02             add   bx, 2
0x00000000000046cb:  99                   cdq   
0x00000000000046cc:  8B 5E FC             mov   bx, word ptr [bp - 4]
0x00000000000046cf:  89 C1                mov   cx, ax
0x00000000000046d1:  8B 45 14             mov   ax, word ptr [di + 0x14]
0x00000000000046d4:  8E 46 F6             mov   es, word ptr [bp - 0xa]
0x00000000000046d7:  89 46 FA             mov   word ptr [bp - 6], ax
0x00000000000046da:  26 8B 47 06          mov   ax, word ptr es:[bx + 6]
0x00000000000046de:  8E 46 FE             mov   es, word ptr [bp - 2]
0x00000000000046e1:  89 56 FC             mov   word ptr [bp - 4], dx
0x00000000000046e4:  26 2B 44 06          sub   ax, word ptr es:[si + 6]
0x00000000000046e8:  8B 5E FA             mov   bx, word ptr [bp - 6]
0x00000000000046eb:  99                   cdq   
0x00000000000046ec:  9A CB 5E 88 0A       lcall 0xa88:0x5ecb
0x00000000000046f1:  89 CB                mov   bx, cx
0x00000000000046f3:  8B 4E FC             mov   cx, word ptr [bp - 4]
0x00000000000046f6:  0E                   push  cs
0x00000000000046f7:  E8 1A 6E             call  0xb514
0x00000000000046fa:  90                   nop   
0x00000000000046fb:  BA 5E 00             mov   dx, 0x5e
0x00000000000046fe:  88 45 24             mov   byte ptr [di + 0x24], al
0x0000000000004701:  31 C0                xor   ax, ax
0x0000000000004703:  0E                   push  cs
0x0000000000004704:  3E E8 36 B7          call  0xfe3e
0x0000000000004708:  C9                   leave 
0x0000000000004709:  5F                   pop   di
0x000000000000470a:  5E                   pop   si
0x000000000000470b:  5A                   pop   dx
0x000000000000470c:  C3                   ret   
0x000000000000470d:  FC                   cld   
0x000000000000470e:  52                   push  dx
0x000000000000470f:  56                   push  si
0x0000000000004710:  89 C6                mov   si, ax
0x0000000000004712:  BA 5F 00             mov   dx, 0x5f
0x0000000000004715:  0E                   push  cs
0x0000000000004716:  3E E8 24 B7          call  0xfe3e
0x000000000000471a:  89 F0                mov   ax, si
0x000000000000471c:  E8 03 00             call  0x4722
0x000000000000471f:  5E                   pop   si
0x0000000000004720:  5A                   pop   dx
0x0000000000004721:  C3                   ret   
0x0000000000004722:  52                   push  dx
0x0000000000004723:  56                   push  si
0x0000000000004724:  57                   push  di
0x0000000000004725:  55                   push  bp
0x0000000000004726:  89 E5                mov   bp, sp
0x0000000000004728:  83 EC 0A             sub   sp, 0xa
0x000000000000472b:  89 C7                mov   di, ax
0x000000000000472d:  C7 46 F6 50 03       mov   word ptr [bp - 0xa], 0x350
0x0000000000004732:  C7 46 F8 D9 92       mov   word ptr [bp - 8], 0x92d9
0x0000000000004737:  FE 4D 24             dec   byte ptr [di + 0x24]
0x000000000000473a:  74 05                je    0x4741
0x000000000000473c:  C9                   leave 
0x000000000000473d:  5F                   pop   di
0x000000000000473e:  5E                   pop   si
0x000000000000473f:  5A                   pop   dx
0x0000000000004740:  C3                   ret   
0x0000000000004741:  8B 75 22             mov   si, word ptr [di + 0x22]
0x0000000000004744:  6B C6 2C             imul  ax, si, 0x2c
0x0000000000004747:  6B F6 18             imul  si, si, 0x18
0x000000000000474a:  05 04 34             add   ax, 0x3404
0x000000000000474d:  89 46 FA             mov   word ptr [bp - 6], ax
0x0000000000004750:  8B 5E FA             mov   bx, word ptr [bp - 6]
0x0000000000004753:  FF 77 04             push  word ptr [bx + 4]
0x0000000000004756:  B8 F5 6A             mov   ax, 0x6af5
0x0000000000004759:  6A 1D                push  0x1d
0x000000000000475b:  8E C0                mov   es, ax
0x000000000000475d:  89 46 FE             mov   word ptr [bp - 2], ax
0x0000000000004760:  26 FF 74 0A          push  word ptr es:[si + 0xa]
0x0000000000004764:  26 8B 5C 04          mov   bx, word ptr es:[si + 4]
0x0000000000004768:  26 8B 4C 06          mov   cx, word ptr es:[si + 6]
0x000000000000476c:  26 8B 04             mov   ax, word ptr es:[si]
0x000000000000476f:  26 FF 74 08          push  word ptr es:[si + 8]
0x0000000000004773:  26 8B 54 02          mov   dx, word ptr es:[si + 2]
0x0000000000004777:  0E                   push  cs
0x0000000000004778:  3E E8 16 3F          call  0x8692
0x000000000000477c:  BB BA 01             mov   bx, 0x1ba
0x000000000000477f:  BA 23 00             mov   dx, 0x23
0x0000000000004782:  8B 07                mov   ax, word ptr [bx]
0x0000000000004784:  89 76 FC             mov   word ptr [bp - 4], si
0x0000000000004787:  0E                   push  cs
0x0000000000004788:  3E E8 B2 B6          call  0xfe3e
0x000000000000478c:  E8 0F 3B             call  0x829e
0x000000000000478f:  3C 32                cmp   al, 0x32
0x0000000000004791:  72 03                jb    0x4796
0x0000000000004793:  E9 7D 00             jmp   0x4813
0x0000000000004796:  B0 0B                mov   al, 0xb
0x0000000000004798:  8B 5E FA             mov   bx, word ptr [bp - 6]
0x000000000000479b:  30 E4                xor   ah, ah
0x000000000000479d:  FF 77 04             push  word ptr [bx + 4]
0x00000000000047a0:  C4 5E FC             les   bx, ptr [bp - 4]
0x00000000000047a3:  50                   push  ax
0x00000000000047a4:  8B 76 FC             mov   si, word ptr [bp - 4]
0x00000000000047a7:  26 FF 77 0A          push  word ptr es:[bx + 0xa]
0x00000000000047ab:  26 8B 4C 06          mov   cx, word ptr es:[si + 6]
0x00000000000047af:  26 8B 04             mov   ax, word ptr es:[si]
0x00000000000047b2:  26 8B 54 02          mov   dx, word ptr es:[si + 2]
0x00000000000047b6:  26 FF 77 08          push  word ptr es:[bx + 8]
0x00000000000047ba:  26 8B 5F 04          mov   bx, word ptr es:[bx + 4]
0x00000000000047be:  0E                   push  cs
0x00000000000047bf:  E8 D0 3E             call  0x8692
0x00000000000047c2:  90                   nop   
0x00000000000047c3:  6B F0 2C             imul  si, ax, 0x2c
0x00000000000047c6:  6B D8 18             imul  bx, ax, 0x18
0x00000000000047c9:  81 C6 04 34          add   si, 0x3404
0x00000000000047cd:  BA 01 00             mov   dx, 1
0x00000000000047d0:  89 F0                mov   ax, si
0x00000000000047d2:  B9 F5 6A             mov   cx, 0x6af5
0x00000000000047d5:  E8 3A E1             call  0x2912
0x00000000000047d8:  84 C0                test  al, al
0x00000000000047da:  74 11                je    0x47ed
0x00000000000047dc:  8A 44 1A             mov   al, byte ptr [si + 0x1a]
0x00000000000047df:  30 E4                xor   ah, ah
0x00000000000047e1:  FF 5E F6             lcall [bp - 0xa]
0x00000000000047e4:  89 C2                mov   dx, ax
0x00000000000047e6:  89 F0                mov   ax, si
0x00000000000047e8:  0E                   push  cs
0x00000000000047e9:  E8 F0 40             call  0x88dc
0x00000000000047ec:  90                   nop   
0x00000000000047ed:  FF 74 04             push  word ptr [si + 4]
0x00000000000047f0:  8E C1                mov   es, cx
0x00000000000047f2:  26 FF 77 06          push  word ptr es:[bx + 6]
0x00000000000047f6:  26 FF 77 04          push  word ptr es:[bx + 4]
0x00000000000047fa:  26 FF 77 02          push  word ptr es:[bx + 2]
0x00000000000047fe:  26 FF 37             push  word ptr es:[bx]
0x0000000000004801:  89 F0                mov   ax, si
0x0000000000004803:  FF 1E E4 0C          lcall [0xce4]
0x0000000000004807:  89 F8                mov   ax, di
0x0000000000004809:  0E                   push  cs
0x000000000000480a:  3E E8 3C 40          call  0x884a
0x000000000000480e:  C9                   leave 
0x000000000000480f:  5F                   pop   di
0x0000000000004810:  5E                   pop   si
0x0000000000004811:  5A                   pop   dx
0x0000000000004812:  C3                   ret   
0x0000000000004813:  3C 5A                cmp   al, 0x5a
0x0000000000004815:  73 05                jae   0x481c
0x0000000000004817:  B0 0C                mov   al, 0xc
0x0000000000004819:  E9 7C FF             jmp   0x4798
0x000000000000481c:  3C 78                cmp   al, 0x78
0x000000000000481e:  73 05                jae   0x4825
0x0000000000004820:  B0 0D                mov   al, 0xd
0x0000000000004822:  E9 73 FF             jmp   0x4798
0x0000000000004825:  3C 82                cmp   al, 0x82
0x0000000000004827:  73 05                jae   0x482e
0x0000000000004829:  B0 16                mov   al, 0x16
0x000000000000482b:  E9 6A FF             jmp   0x4798
0x000000000000482e:  3C A0                cmp   al, 0xa0
0x0000000000004830:  73 05                jae   0x4837
0x0000000000004832:  B0 0E                mov   al, 0xe
0x0000000000004834:  E9 61 FF             jmp   0x4798
0x0000000000004837:  3C A2                cmp   al, 0xa2
0x0000000000004839:  73 05                jae   0x4840
0x000000000000483b:  B0 03                mov   al, 3
0x000000000000483d:  E9 58 FF             jmp   0x4798
0x0000000000004840:  3C AC                cmp   al, 0xac
0x0000000000004842:  73 05                jae   0x4849
0x0000000000004844:  B0 05                mov   al, 5
0x0000000000004846:  E9 4F FF             jmp   0x4798
0x0000000000004849:  3C C0                cmp   al, 0xc0
0x000000000000484b:  73 05                jae   0x4852
0x000000000000484d:  B0 14                mov   al, 0x14
0x000000000000484f:  E9 46 FF             jmp   0x4798
0x0000000000004852:  3C DE                cmp   al, 0xde
0x0000000000004854:  73 05                jae   0x485b
0x0000000000004856:  B0 08                mov   al, 8
0x0000000000004858:  E9 3D FF             jmp   0x4798
0x000000000000485b:  3C F6                cmp   al, 0xf6
0x000000000000485d:  73 05                jae   0x4864
0x000000000000485f:  B0 11                mov   al, 0x11
0x0000000000004861:  E9 34 FF             jmp   0x4798
0x0000000000004864:  B0 0F                mov   al, 0xf
0x0000000000004866:  E9 2F FF             jmp   0x4798
0x0000000000004869:  FC                   cld   
0x000000000000486a:  53                   push  bx
0x000000000000486b:  52                   push  dx
0x000000000000486c:  BB EB 02             mov   bx, 0x2eb
0x000000000000486f:  B0 39                mov   al, 0x39
0x0000000000004871:  80 3F 00             cmp   byte ptr [bx], 0
0x0000000000004874:  74 0D                je    0x4883
0x0000000000004876:  BB EC 06             mov   bx, 0x6ec
0x0000000000004879:  8B 1F                mov   bx, word ptr [bx]
0x000000000000487b:  83 7F 1C CE          cmp   word ptr [bx + 0x1c], -0x32
0x000000000000487f:  7D 02                jge   0x4883
0x0000000000004881:  B0 3A                mov   al, 0x3a
0x0000000000004883:  30 E4                xor   ah, ah
0x0000000000004885:  BB EC 06             mov   bx, 0x6ec
0x0000000000004888:  89 C2                mov   dx, ax
0x000000000000488a:  8B 07                mov   ax, word ptr [bx]
0x000000000000488c:  0E                   push  cs
0x000000000000488d:  E8 AE B5             call  0xfe3e
0x0000000000004890:  90                   nop   
0x0000000000004891:  5A                   pop   dx
0x0000000000004892:  5B                   pop   bx
0x0000000000004893:  C3                   ret   

@

PROC    P_ENEMY_ENDMARKER_ 
PUBLIC  P_ENEMY_ENDMARKER_
ENDP



END
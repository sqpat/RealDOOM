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


EXTRN AM_Stop_:PROC
EXTRN P_Random_:NEAR
EXTRN FastDiv32u16u_:PROC
EXTRN FastMul16u32u_:PROC
EXTRN R_PointToAngle2_:PROC
EXTRN FixedMulTrigNoShift_:PROC

EXTRN _P_RemoveMobj:DWORD
EXTRN _P_DropWeaponFar:DWORD
EXTRN _P_SpawnMobj:DWORD
EXTRN _P_SetMobjState:DWORD

.DATA




.CODE




PROC    P_SWITCH_STARTMARKER_ 
PUBLIC  P_SWITCH_STARTMARKER_
ENDP

;void __near P_StartButton ( int16_t linenum,int16_t linefrontsecnum,bwhere_e	w,int16_t		texture,int16_t		time ){

; TODO: change to pass time in si.

PROC    P_StartButton_
PUBLIC  P_StartButton_

push  si
push  di
push  bp
mov   bp, sp
mov   si, ax
mov   di, dx
mov   dh, bl
xor   dl, dl
label_3:
mov   al, dl
cbw  
imul  bx, ax, 9
cmp   word ptr [bx + _buttonlist + BUTTON_T.button_btimer], 0
je    label_1
cmp   si, word ptr [bx + _buttonlist + BUTTON_T.button_linenum]
je    label_2
label_1:
inc   dl
cmp   dl, 4
jl    label_3
xor   dl, dl
label_4:
mov   al, dl
cbw  
imul  bx, ax, 9
cmp   word ptr [bx + _buttonlist + BUTTON_T.button_btimer], 0
je    label_5
inc   dl
cmp   dl, 4
jl    label_4
label_2:
pop   bp
pop   di
pop   si
ret   2
label_5:
mov   word ptr [bx + _buttonlist + BUTTON_T.button_linenum], si
mov   byte ptr [bx + _buttonlist + BUTTON_T.button_where], dh
mov   word ptr [bx + _buttonlist + BUTTON_T.button_btexture], cx
mov   ax, word ptr [bp + 8]
mov   word ptr [bx + _buttonlist + BUTTON_T.button_soundorg], di
mov   word ptr [bx + _buttonlist + BUTTON_T.button_btimer], ax
pop   bp
pop   di
pop   si
ret   2

ENDP

COMMENT @

PROC    P_ChangeSwitchTexture_
PUBLIC  P_ChangeSwitchTexture_



0x0000000000004c10:  56                push  si
0x0000000000004c11:  57                push  di
0x0000000000004c12:  55                push  bp
0x0000000000004c13:  89 E5             mov   bp, sp
0x0000000000004c15:  83 EC 06          sub   sp, 6
0x0000000000004c18:  50                push  ax
0x0000000000004c19:  51                push  cx
0x0000000000004c1a:  89 D0             mov   ax, dx
0x0000000000004c1c:  88 DA             mov   dl, bl
0x0000000000004c1e:  B9 83 24          mov   cx, 0x2483
0x0000000000004c21:  89 C3             mov   bx, ax
0x0000000000004c23:  C7 46 FC 17 00    mov   word ptr [bp - 4], 0x17
0x0000000000004c28:  C1 E3 03          shl   bx, 3
0x0000000000004c2b:  8E C1             mov   es, cx
0x0000000000004c2d:  8D 77 04          lea   si, [bx + 4]
0x0000000000004c30:  26 8B 3F          mov   di, word ptr es:[bx]
0x0000000000004c33:  26 8B 0C          mov   cx, word ptr es:[si]
0x0000000000004c36:  83 C3 02          add   bx, 2
0x0000000000004c39:  89 4E FE          mov   word ptr [bp - 2], cx
0x0000000000004c3c:  26 8B 37          mov   si, word ptr es:[bx]
0x0000000000004c3f:  83 7E 08 00       cmp   word ptr [bp + 8], 0
0x0000000000004c43:  74 39             je    0x4c7e
0x0000000000004c45:  80 FA 0B          cmp   dl, 0xb
0x0000000000004c48:  74 48             je    0x4c92
0x0000000000004c4a:  C1 E0 03          shl   ax, 3
0x0000000000004c4d:  30 D2             xor   dl, dl
0x0000000000004c4f:  89 46 FA          mov   word ptr [bp - 6], ax
0x0000000000004c52:  BB BE 09          mov   bx, 0x9be
0x0000000000004c55:  88 D0             mov   al, dl
0x0000000000004c57:  8B 1F             mov   bx, word ptr [bx]
0x0000000000004c59:  98                cbw  
0x0000000000004c5a:  01 DB             add   bx, bx
0x0000000000004c5c:  39 D8             cmp   ax, bx
0x0000000000004c5e:  7D 64             jge   0x4cc4
0x0000000000004c60:  89 C3             mov   bx, ax
0x0000000000004c62:  01 C3             add   bx, ax
0x0000000000004c64:  88 D1             mov   cl, dl
0x0000000000004c66:  8B 87 80 0A       mov   ax, word ptr [bx + 0xa80]
0x0000000000004c6a:  80 F1 01          xor   cl, 1
0x0000000000004c6d:  39 C7             cmp   di, ax
0x0000000000004c6f:  74 28             je    0x4c99
0x0000000000004c71:  3B 46 FE          cmp   ax, word ptr [bp - 2]
0x0000000000004c74:  74 69             je    0x4cdf
0x0000000000004c76:  39 C6             cmp   si, ax
0x0000000000004c78:  74 63             je    0x4cdd
0x0000000000004c7a:  FE C2             inc   dl
0x0000000000004c7c:  EB D4             jmp   0x4c52
0x0000000000004c7e:  8B 5E F8          mov   bx, word ptr [bp - 8]
0x0000000000004c81:  B9 00 70          mov   cx, 0x7000
0x0000000000004c84:  C1 E3 04          shl   bx, 4
0x0000000000004c87:  8E C1             mov   es, cx
0x0000000000004c89:  83 C3 0F          add   bx, 0xf
0x0000000000004c8c:  26 C6 07 00       mov   byte ptr es:[bx], 0
0x0000000000004c90:  EB B3             jmp   0x4c45
0x0000000000004c92:  C7 46 FC 18 00    mov   word ptr [bp - 4], 0x18
0x0000000000004c97:  EB B1             jmp   0x4c4a
0x0000000000004c99:  BE 9B 09          mov   si, 0x99b
0x0000000000004c9c:  8A 56 FC          mov   dl, byte ptr [bp - 4]
0x0000000000004c9f:  8B 04             mov   ax, word ptr [si]
0x0000000000004ca1:  30 F6             xor   dh, dh
0x0000000000004ca3:  0E                push  cs
0x0000000000004ca4:  3E E8 BA B8       call  0x562
0x0000000000004ca8:  88 C8             mov   al, cl
0x0000000000004caa:  98                cbw  
0x0000000000004cab:  89 C6             mov   si, ax
0x0000000000004cad:  01 C6             add   si, ax
0x0000000000004caf:  B8 83 24          mov   ax, 0x2483
0x0000000000004cb2:  8E C0             mov   es, ax
0x0000000000004cb4:  8B 84 80 0A       mov   ax, word ptr [si + 0xa80]
0x0000000000004cb8:  8B 76 FA          mov   si, word ptr [bp - 6]
0x0000000000004cbb:  26 89 04          mov   word ptr es:[si], ax
0x0000000000004cbe:  83 7E 08 00       cmp   word ptr [bp + 8], 0
0x0000000000004cc2:  75 06             jne   0x4cca
0x0000000000004cc4:  C9                LEAVE_MACRO 
0x0000000000004cc5:  5F                pop   di
0x0000000000004cc6:  5E                pop   si
0x0000000000004cc7:  C2 02 00          ret   2
0x0000000000004cca:  6A 23             push  0x23
0x0000000000004ccc:  8B 56 F6          mov   dx, word ptr [bp - 0xa]
0x0000000000004ccf:  8B 46 F8          mov   ax, word ptr [bp - 8]
0x0000000000004cd2:  8B 8F 80 0A       mov   cx, word ptr [bx + 0xa80]
0x0000000000004cd6:  31 DB             xor   bx, bx
0x0000000000004cd8:  E8 D5 FE          call  0x4bb0
0x0000000000004cdb:  EB E7             jmp   0x4cc4
0x0000000000004cdd:  EB 46             jmp   0x4d25
0x0000000000004cdf:  BE 9B 09          mov   si, 0x99b
0x0000000000004ce2:  8A 56 FC          mov   dl, byte ptr [bp - 4]
0x0000000000004ce5:  8B 04             mov   ax, word ptr [si]
0x0000000000004ce7:  30 F6             xor   dh, dh
0x0000000000004ce9:  0E                push  cs
0x0000000000004cea:  3E E8 74 B8       call  0x562
0x0000000000004cee:  88 C8             mov   al, cl
0x0000000000004cf0:  98                cbw  
0x0000000000004cf1:  89 C7             mov   di, ax
0x0000000000004cf3:  8B 76 FA          mov   si, word ptr [bp - 6]
0x0000000000004cf6:  01 C7             add   di, ax
0x0000000000004cf8:  B8 83 24          mov   ax, 0x2483
0x0000000000004cfb:  83 C6 04          add   si, 4
0x0000000000004cfe:  8E C0             mov   es, ax
0x0000000000004d00:  8B 85 80 0A       mov   ax, word ptr [di + 0xa80]
0x0000000000004d04:  26 89 04          mov   word ptr es:[si], ax
0x0000000000004d07:  83 7E 08 00       cmp   word ptr [bp + 8], 0
0x0000000000004d0b:  74 B7             je    0x4cc4
0x0000000000004d0d:  6A 23             push  0x23
0x0000000000004d0f:  8B 56 F6          mov   dx, word ptr [bp - 0xa]
0x0000000000004d12:  8B 46 F8          mov   ax, word ptr [bp - 8]
0x0000000000004d15:  8B 8F 80 0A       mov   cx, word ptr [bx + 0xa80]
0x0000000000004d19:  BB 01 00          mov   bx, 1
0x0000000000004d1c:  E8 91 FE          call  0x4bb0
0x0000000000004d1f:  C9                LEAVE_MACRO 
0x0000000000004d20:  5F                pop   di
0x0000000000004d21:  5E                pop   si
0x0000000000004d22:  C2 02 00          ret   2
0x0000000000004d25:  BE 9B 09          mov   si, 0x99b
0x0000000000004d28:  8A 56 FC          mov   dl, byte ptr [bp - 4]
0x0000000000004d2b:  8B 04             mov   ax, word ptr [si]
0x0000000000004d2d:  30 F6             xor   dh, dh
0x0000000000004d2f:  0E                push  cs
0x0000000000004d30:  3E E8 2E B8       call  0x562
0x0000000000004d34:  88 C8             mov   al, cl
0x0000000000004d36:  98                cbw  
0x0000000000004d37:  89 C6             mov   si, ax
0x0000000000004d39:  8B 7E FA          mov   di, word ptr [bp - 6]
0x0000000000004d3c:  01 C6             add   si, ax
0x0000000000004d3e:  B8 83 24          mov   ax, 0x2483
0x0000000000004d41:  83 C7 02          add   di, 2
0x0000000000004d44:  8E C0             mov   es, ax
0x0000000000004d46:  8B 84 80 0A       mov   ax, word ptr [si + 0xa80]
0x0000000000004d4a:  26 89 05          mov   word ptr es:[di], ax
0x0000000000004d4d:  83 7E 08 00       cmp   word ptr [bp + 8], 0
0x0000000000004d51:  75 03             jne   0x4d56
0x0000000000004d53:  E9 6E FF          jmp   0x4cc4
0x0000000000004d56:  6A 23             push  0x23
0x0000000000004d58:  8B 56 F6          mov   dx, word ptr [bp - 0xa]
0x0000000000004d5b:  8B 46 F8          mov   ax, word ptr [bp - 8]
0x0000000000004d5e:  8B 8F 80 0A       mov   cx, word ptr [bx + 0xa80]
0x0000000000004d62:  BB 02 00          mov   bx, 2
0x0000000000004d65:  E8 48 FE          call  0x4bb0
0x0000000000004d68:  C9                LEAVE_MACRO 
0x0000000000004d69:  5F                pop   di
0x0000000000004d6a:  5E                pop   si
0x0000000000004d6b:  C2 02 00          ret   2

ENDP

_special_line_switch_block:

0x0000000000004d6e:  F8                clc   
0x0000000000004d6f:  4E                dec   si
0x0000000000004d70:  FD                std   
0x0000000000004d71:  4E                dec   si
0x0000000000004d72:  FD                std   
0x0000000000004d73:  4E                dec   si
0x0000000000004d74:  FD                std   
0x0000000000004d75:  4E                dec   si
0x0000000000004d76:  FD                std   
0x0000000000004d77:  4E                dec   si
0x0000000000004d78:  FD                std   
0x0000000000004d79:  4E                dec   si
0x0000000000004d7a:  17                pop   ss
0x0000000000004d7b:  4F                dec   di
0x0000000000004d7c:  FD                std   
0x0000000000004d7d:  4E                dec   si
0x0000000000004d7e:  3B 4F FD          cmp   cx, word ptr [bx - 3]
0x0000000000004d81:  4E                dec   si
0x0000000000004d82:  5D                pop   bp
0x0000000000004d83:  4F                dec   di
0x0000000000004d84:  FD                std   
0x0000000000004d85:  4E                dec   si
0x0000000000004d86:  FD                std   
0x0000000000004d87:  4E                dec   si
0x0000000000004d88:  7B 4F             jnp   0x4dd9
0x0000000000004d8a:  A8 4F             test  al, 0x4f
0x0000000000004d8c:  FD                std   
0x0000000000004d8d:  4E                dec   si
0x0000000000004d8e:  FD                std   
0x0000000000004d8f:  4E                dec   si
0x0000000000004d90:  D2 4F FD          ror   byte ptr [bx - 3], cl
0x0000000000004d93:  4E                dec   si
0x0000000000004d94:  FB                sti   
0x0000000000004d95:  4F                dec   di
0x0000000000004d96:  24 50             and   al, 0x50
0x0000000000004d98:  FD                std   
0x0000000000004d99:  4E                dec   si
0x0000000000004d9a:  50                push  ax
0x0000000000004d9b:  50                push  ax
0x0000000000004d9c:  FD                std   
0x0000000000004d9d:  4E                dec   si
0x0000000000004d9e:  FD                std   
0x0000000000004d9f:  4E                dec   si
0x0000000000004da0:  F8                clc   
0x0000000000004da1:  4E                dec   si
0x0000000000004da2:  F8                clc   
0x0000000000004da3:  4E                dec   si
0x0000000000004da4:  F8                clc   
0x0000000000004da5:  4E                dec   si
0x0000000000004da6:  79 50             jns   0x4df8
0x0000000000004da8:  FD                std   
0x0000000000004da9:  4E                dec   si
0x0000000000004daa:  F8                clc   
0x0000000000004dab:  4E                dec   si
0x0000000000004dac:  F8                clc   
0x0000000000004dad:  4E                dec   si
0x0000000000004dae:  F8                clc   
0x0000000000004daf:  4E                dec   si
0x0000000000004db0:  F8                clc   
0x0000000000004db1:  4E                dec   si
0x0000000000004db2:  FD                std   
0x0000000000004db3:  4E                dec   si
0x0000000000004db4:  FD                std   
0x0000000000004db5:  4E                dec   si
0x0000000000004db6:  FD                std   
0x0000000000004db7:  4E                dec   si
0x0000000000004db8:  FD                std   
0x0000000000004db9:  4E                dec   si
0x0000000000004dba:  FD                std   
0x0000000000004dbb:  4E                dec   si
0x0000000000004dbc:  FD                std   
0x0000000000004dbd:  4E                dec   si
0x0000000000004dbe:  9F                lahf  
0x0000000000004dbf:  50                push  ax
0x0000000000004dc0:  39 53 60          cmp   word ptr [bp + di + 0x60], dx
0x0000000000004dc3:  53                push  bx
0x0000000000004dc4:  FD                std   
0x0000000000004dc5:  4E                dec   si
0x0000000000004dc6:  84 53 FD          test  byte ptr [bp + di - 3], dl
0x0000000000004dc9:  4E                dec   si
0x0000000000004dca:  FD                std   
0x0000000000004dcb:  4E                dec   si
0x0000000000004dcc:  FD                std   
0x0000000000004dcd:  4E                dec   si
0x0000000000004dce:  EF                out   dx, ax
0x0000000000004dcf:  50                push  ax
0x0000000000004dd0:  14 51             adc   al, 0x51
0x0000000000004dd2:  3B 51 FD          cmp   dx, word ptr [bx + di - 3]
0x0000000000004dd5:  4E                dec   si
0x0000000000004dd6:  FD                std   
0x0000000000004dd7:  4E                dec   si
0x0000000000004dd8:  FD                std   
0x0000000000004dd9:  4E                dec   si
0x0000000000004dda:  59                pop   cx
0x0000000000004ddb:  51                push  cx
0x0000000000004ddc:  FD                std   
0x0000000000004ddd:  4E                dec   si
0x0000000000004dde:  FD                std   
0x0000000000004ddf:  4E                dec   si
0x0000000000004de0:  FD                std   
0x0000000000004de1:  4E                dec   si
0x0000000000004de2:  FD                std   
0x0000000000004de3:  4E                dec   si
0x0000000000004de4:  AC                lodsb al, byte ptr [si]
0x0000000000004de5:  53                push  bx
0x0000000000004de6:  D8 53 FF          fcom  dword ptr [bp + di - 1]
0x0000000000004de9:  53                push  bx
0x0000000000004dea:  28 54 4E          sub   byte ptr [si + 0x4e], dl
0x0000000000004ded:  54                push  sp
0x0000000000004dee:  CE                into  
0x0000000000004def:  54                push  sp
0x0000000000004df0:  7A 54             jp    0x4e46
0x0000000000004df2:  A4                movsb byte ptr es:[di], byte ptr [si]
0x0000000000004df3:  54                push  sp
0x0000000000004df4:  F7 54 23          not   word ptr [si + 0x23]
0x0000000000004df7:  55                push  bp
0x0000000000004df8:  4C                dec   sp
0x0000000000004df9:  55                push  bp
0x0000000000004dfa:  C3                ret   
0x0000000000004dfb:  50                push  ax
0x0000000000004dfc:  FD                std   
0x0000000000004dfd:  4E                dec   si
0x0000000000004dfe:  FD                std   
0x0000000000004dff:  4E                dec   si
0x0000000000004e00:  FD                std   
0x0000000000004e01:  4E                dec   si
0x0000000000004e02:  FD                std   
0x0000000000004e03:  4E                dec   si
0x0000000000004e04:  FD                std   
0x0000000000004e05:  4E                dec   si
0x0000000000004e06:  FD                std   
0x0000000000004e07:  4E                dec   si
0x0000000000004e08:  FD                std   
0x0000000000004e09:  4E                dec   si
0x0000000000004e0a:  FD                std   
0x0000000000004e0b:  4E                dec   si
0x0000000000004e0c:  FD                std   
0x0000000000004e0d:  4E                dec   si
0x0000000000004e0e:  FD                std   
0x0000000000004e0f:  4E                dec   si
0x0000000000004e10:  FD                std   
0x0000000000004e11:  4E                dec   si
0x0000000000004e12:  FD                std   
0x0000000000004e13:  4E                dec   si
0x0000000000004e14:  FD                std   
0x0000000000004e15:  4E                dec   si
0x0000000000004e16:  FD                std   
0x0000000000004e17:  4E                dec   si
0x0000000000004e18:  FD                std   
0x0000000000004e19:  4E                dec   si
0x0000000000004e1a:  FD                std   
0x0000000000004e1b:  4E                dec   si
0x0000000000004e1c:  FD                std   
0x0000000000004e1d:  4E                dec   si
0x0000000000004e1e:  FD                std   
0x0000000000004e1f:  4E                dec   si
0x0000000000004e20:  FD                std   
0x0000000000004e21:  4E                dec   si
0x0000000000004e22:  FD                std   
0x0000000000004e23:  4E                dec   si
0x0000000000004e24:  FD                std   
0x0000000000004e25:  4E                dec   si
0x0000000000004e26:  FD                std   
0x0000000000004e27:  4E                dec   si
0x0000000000004e28:  FD                std   
0x0000000000004e29:  4E                dec   si
0x0000000000004e2a:  FD                std   
0x0000000000004e2b:  4E                dec   si
0x0000000000004e2c:  FD                std   
0x0000000000004e2d:  4E                dec   si
0x0000000000004e2e:  FD                std   
0x0000000000004e2f:  4E                dec   si
0x0000000000004e30:  FD                std   
0x0000000000004e31:  4E                dec   si
0x0000000000004e32:  35 56 FD          xor   ax, 0xfd56
0x0000000000004e35:  4E                dec   si
0x0000000000004e36:  85 51 AE          test  word ptr [bx + di - 0x52], dx
0x0000000000004e39:  51                push  cx
0x0000000000004e3a:  D4 51             aam   0x51
0x0000000000004e3c:  FD                std   
0x0000000000004e3d:  4E                dec   si
0x0000000000004e3e:  FD                std   
0x0000000000004e3f:  4E                dec   si
0x0000000000004e40:  FD                std   
0x0000000000004e41:  4E                dec   si
0x0000000000004e42:  FD                std   
0x0000000000004e43:  4E                dec   si
0x0000000000004e44:  FD                std   
0x0000000000004e45:  4E                dec   si
0x0000000000004e46:  FD                std   
0x0000000000004e47:  4E                dec   si
0x0000000000004e48:  FD                std   
0x0000000000004e49:  4E                dec   si
0x0000000000004e4a:  F9                stc   
0x0000000000004e4b:  51                push  cx
0x0000000000004e4c:  21 52 46          and   word ptr [bp + si + 0x46], dx
0x0000000000004e4f:  52                push  dx
0x0000000000004e50:  75 55             jne   0x4ea7
0x0000000000004e52:  9A 55 C2 55 F8    lcall 0xf855:0xc255
0x0000000000004e57:  4E                dec   si
0x0000000000004e58:  F8                clc   
0x0000000000004e59:  4E                dec   si
0x0000000000004e5a:  FD                std   
0x0000000000004e5b:  4E                dec   si
0x0000000000004e5c:  FD                std   
0x0000000000004e5d:  4E                dec   si
0x0000000000004e5e:  FD                std   
0x0000000000004e5f:  4E                dec   si
0x0000000000004e60:  6B 52 E7 55       imul  dx, word ptr [bp + si - 0x19], 0x55
0x0000000000004e64:  FD                std   
0x0000000000004e65:  4E                dec   si
0x0000000000004e66:  FD                std   
0x0000000000004e67:  4E                dec   si
0x0000000000004e68:  FD                std   
0x0000000000004e69:  4E                dec   si
0x0000000000004e6a:  92                xchg  ax, dx
0x0000000000004e6b:  52                push  dx
0x0000000000004e6c:  FD                std   
0x0000000000004e6d:  4E                dec   si
0x0000000000004e6e:  FD                std   
0x0000000000004e6f:  4E                dec   si
0x0000000000004e70:  FD                std   
0x0000000000004e71:  4E                dec   si
0x0000000000004e72:  B8 52 0E          mov   ax, 0xe52
0x0000000000004e75:  56                push  si
0x0000000000004e76:  DF 52 35          fist  word ptr [bp + si + 0x35]
0x0000000000004e79:  56                push  si
0x0000000000004e7a:  DF 52 35          fist  word ptr [bp + si + 0x35]
0x0000000000004e7d:  56                push  si
0x0000000000004e7e:  DF 52 68          fist  word ptr [bp + si + 0x68]
0x0000000000004e81:  56                push  si
0x0000000000004e82:  8A 56 0F          mov   dl, byte ptr [bp + 0xf]



PROC    P_UseSpecialLine_
PUBLIC  P_UseSpecialLine_


0x0000000000004e85:  53                push  bx
0x0000000000004e86:  56                push  si
0x0000000000004e87:  57                push  di
0x0000000000004e88:  55                push  bp
0x0000000000004e89:  89 E5             mov   bp, sp
0x0000000000004e8b:  83 EC 0E          sub   sp, 0xe
0x0000000000004e8e:  89 D7             mov   di, dx
0x0000000000004e90:  89 5E F6          mov   word ptr [bp - 0xa], bx
0x0000000000004e93:  89 CA             mov   dx, cx
0x0000000000004e95:  C7 46 F2 91 29    mov   word ptr [bp - 0xe], 0x2991
0x0000000000004e9a:  C7 46 F4 00 70    mov   word ptr [bp - 0xc], 0x7000
0x0000000000004e9f:  B8 4A 2B          mov   ax, 0x2b4a
0x0000000000004ea2:  89 FB             mov   bx, di
0x0000000000004ea4:  89 FE             mov   si, di
0x0000000000004ea6:  8E C0             mov   es, ax
0x0000000000004ea8:  C1 E6 04          shl   si, 4
0x0000000000004eab:  26 8A 25          mov   ah, byte ptr es:[di]
0x0000000000004eae:  8E 46 F4          mov   es, word ptr [bp - 0xc]
0x0000000000004eb1:  C1 E3 02          shl   bx, 2
0x0000000000004eb4:  26 8A 44 0E       mov   al, byte ptr es:[si + 0xe]
0x0000000000004eb8:  26 8A 4C 0F       mov   cl, byte ptr es:[si + 0xf]
0x0000000000004ebc:  26 8B 74 0A       mov   si, word ptr es:[si + 0xa]
0x0000000000004ec0:  8E 46 F2          mov   es, word ptr [bp - 0xe]
0x0000000000004ec3:  26 8B 1F          mov   bx, word ptr es:[bx]
0x0000000000004ec6:  88 4E FE          mov   byte ptr [bp - 2], cl
0x0000000000004ec9:  89 5E FA          mov   word ptr [bp - 6], bx
0x0000000000004ecc:  83 7E F6 00       cmp   word ptr [bp - 0xa], 0
0x0000000000004ed0:  75 31             jne   0x4f03
0x0000000000004ed2:  BB F6 06          mov   bx, 0x6f6
0x0000000000004ed5:  3B 17             cmp   dx, word ptr [bx]
0x0000000000004ed7:  74 0C             je    0x4ee5
0x0000000000004ed9:  F6 C4 20          test  ah, 0x20
0x0000000000004edc:  75 25             jne   0x4f03
0x0000000000004ede:  80 F9 01          cmp   cl, 1
0x0000000000004ee1:  72 2E             jb    0x4f11
0x0000000000004ee3:  77 22             ja    0x4f07
0x0000000000004ee5:  8A 5E FE          mov   bl, byte ptr [bp - 2]
0x0000000000004ee8:  FE CB             dec   bl
0x0000000000004eea:  80 FB 8B          cmp   bl, 0x8b
0x0000000000004eed:  77 0E             ja    0x4efd
0x0000000000004eef:  30 FF             xor   bh, bh
0x0000000000004ef1:  01 DB             add   bx, bx
0x0000000000004ef3:  2E FF A7 6E 4D    jmp   word ptr cs:[bx + 0x4d6e]
0x0000000000004ef8:  89 F8             mov   ax, di
0x0000000000004efa:  E8 F9 D6          call  0x25f6
0x0000000000004efd:  B0 01             mov   al, 1
0x0000000000004eff:  C9                LEAVE_MACRO 
0x0000000000004f00:  5F                pop   di
0x0000000000004f01:  5E                pop   si
0x0000000000004f02:  CB                retf  
0x0000000000004f03:  30 C0             xor   al, al
0x0000000000004f05:  EB F8             jmp   0x4eff
0x0000000000004f07:  80 F9 20          cmp   cl, 0x20
0x0000000000004f0a:  72 05             jb    0x4f11
0x0000000000004f0c:  80 F9 22          cmp   cl, 0x22
0x0000000000004f0f:  76 D4             jbe   0x4ee5
0x0000000000004f11:  30 C0             xor   al, al
0x0000000000004f13:  C9                LEAVE_MACRO 
0x0000000000004f14:  5F                pop   di
0x0000000000004f15:  5E                pop   si
0x0000000000004f16:  CB                retf  
0x0000000000004f17:  31 D2             xor   dx, dx
0x0000000000004f19:  30 E4             xor   ah, ah
0x0000000000004f1b:  E8 16 E0          call  0x2f34
0x0000000000004f1e:  85 C0             test  ax, ax
0x0000000000004f20:  74 DB             je    0x4efd
0x0000000000004f22:  6A 00             push  0
0x0000000000004f24:  8A 46 FE          mov   al, byte ptr [bp - 2]
0x0000000000004f27:  8B 56 FA          mov   dx, word ptr [bp - 6]
0x0000000000004f2a:  30 E4             xor   ah, ah
0x0000000000004f2c:  89 F1             mov   cx, si
0x0000000000004f2e:  89 C3             mov   bx, ax
0x0000000000004f30:  89 F8             mov   ax, di
0x0000000000004f32:  E8 DB FC          call  0x4c10
0x0000000000004f35:  B0 01             mov   al, 1
0x0000000000004f37:  C9                LEAVE_MACRO 
0x0000000000004f38:  5F                pop   di
0x0000000000004f39:  5E                pop   si
0x0000000000004f3a:  CB                retf  
0x0000000000004f3b:  30 E4             xor   ah, ah
0x0000000000004f3d:  E8 6F FA          call  0x49af
0x0000000000004f40:  85 C0             test  ax, ax
0x0000000000004f42:  74 B9             je    0x4efd
0x0000000000004f44:  6A 00             push  0
0x0000000000004f46:  8A 46 FE          mov   al, byte ptr [bp - 2]
0x0000000000004f49:  8B 56 FA          mov   dx, word ptr [bp - 6]
0x0000000000004f4c:  30 E4             xor   ah, ah
0x0000000000004f4e:  89 F1             mov   cx, si
0x0000000000004f50:  89 C3             mov   bx, ax
0x0000000000004f52:  89 F8             mov   ax, di
0x0000000000004f54:  E8 B9 FC          call  0x4c10
0x0000000000004f57:  B0 01             mov   al, 1
0x0000000000004f59:  C9                LEAVE_MACRO 
0x0000000000004f5a:  5F                pop   di
0x0000000000004f5b:  5E                pop   si
0x0000000000004f5c:  CB                retf  
0x0000000000004f5d:  6A 00             push  0
0x0000000000004f5f:  8A 46 FE          mov   al, byte ptr [bp - 2]
0x0000000000004f62:  8B 56 FA          mov   dx, word ptr [bp - 6]
0x0000000000004f65:  30 E4             xor   ah, ah
0x0000000000004f67:  89 F1             mov   cx, si
0x0000000000004f69:  89 C3             mov   bx, ax
0x0000000000004f6b:  89 F8             mov   ax, di
0x0000000000004f6d:  E8 A0 FC          call  0x4c10
0x0000000000004f70:  9A 34 19 A8 0A    lcall 0xaa8:0x1934
0x0000000000004f75:  B0 01             mov   al, 1
0x0000000000004f77:  C9                LEAVE_MACRO 
0x0000000000004f78:  5F                pop   di
0x0000000000004f79:  5E                pop   si
0x0000000000004f7a:  CB                retf  
0x0000000000004f7b:  B9 20 00          mov   cx, 0x20
0x0000000000004f7e:  BB 02 00          mov   bx, 2
0x0000000000004f81:  89 F2             mov   dx, si
0x0000000000004f83:  30 E4             xor   ah, ah
0x0000000000004f85:  E8 06 EF          call  0x3e8e
0x0000000000004f88:  85 C0             test  ax, ax
0x0000000000004f8a:  75 03             jne   0x4f8f
0x0000000000004f8c:  E9 6E FF          jmp   0x4efd
0x0000000000004f8f:  6A 00             push  0
0x0000000000004f91:  8A 46 FE          mov   al, byte ptr [bp - 2]
0x0000000000004f94:  8B 56 FA          mov   dx, word ptr [bp - 6]
0x0000000000004f97:  30 E4             xor   ah, ah
0x0000000000004f99:  89 F1             mov   cx, si
0x0000000000004f9b:  89 C3             mov   bx, ax
0x0000000000004f9d:  89 F8             mov   ax, di
0x0000000000004f9f:  E8 6E FC          call  0x4c10
0x0000000000004fa2:  B0 01             mov   al, 1
0x0000000000004fa4:  C9                LEAVE_MACRO 
0x0000000000004fa5:  5F                pop   di
0x0000000000004fa6:  5E                pop   si
0x0000000000004fa7:  CB                retf  
0x0000000000004fa8:  B9 18 00          mov   cx, 0x18
0x0000000000004fab:  BB 02 00          mov   bx, 2
0x0000000000004fae:  89 F2             mov   dx, si
0x0000000000004fb0:  30 E4             xor   ah, ah
0x0000000000004fb2:  E8 D9 EE          call  0x3e8e
0x0000000000004fb5:  85 C0             test  ax, ax
0x0000000000004fb7:  74 D3             je    0x4f8c
0x0000000000004fb9:  6A 00             push  0
0x0000000000004fbb:  8A 46 FE          mov   al, byte ptr [bp - 2]
0x0000000000004fbe:  8B 56 FA          mov   dx, word ptr [bp - 6]
0x0000000000004fc1:  30 E4             xor   ah, ah
0x0000000000004fc3:  89 F1             mov   cx, si
0x0000000000004fc5:  89 C3             mov   bx, ax
0x0000000000004fc7:  89 F8             mov   ax, di
0x0000000000004fc9:  E8 44 FC          call  0x4c10
0x0000000000004fcc:  B0 01             mov   al, 1
0x0000000000004fce:  C9                LEAVE_MACRO 
0x0000000000004fcf:  5F                pop   di
0x0000000000004fd0:  5E                pop   si
0x0000000000004fd1:  CB                retf  
0x0000000000004fd2:  BB 04 00          mov   bx, 4
0x0000000000004fd5:  89 F2             mov   dx, si
0x0000000000004fd7:  30 E4             xor   ah, ah
0x0000000000004fd9:  0E                push  cs
0x0000000000004fda:  3E E8 C6 DB       call  0x2ba4
0x0000000000004fde:  85 C0             test  ax, ax
0x0000000000004fe0:  74 AA             je    0x4f8c
0x0000000000004fe2:  6A 00             push  0
0x0000000000004fe4:  8A 46 FE          mov   al, byte ptr [bp - 2]
0x0000000000004fe7:  8B 56 FA          mov   dx, word ptr [bp - 6]
0x0000000000004fea:  30 E4             xor   ah, ah
0x0000000000004fec:  89 F1             mov   cx, si
0x0000000000004fee:  89 C3             mov   bx, ax
0x0000000000004ff0:  89 F8             mov   ax, di
0x0000000000004ff2:  E8 1B FC          call  0x4c10
0x0000000000004ff5:  B0 01             mov   al, 1
0x0000000000004ff7:  C9                LEAVE_MACRO 
0x0000000000004ff8:  5F                pop   di
0x0000000000004ff9:  5E                pop   si
0x0000000000004ffa:  CB                retf  
0x0000000000004ffb:  BB 03 00          mov   bx, 3
0x0000000000004ffe:  89 F2             mov   dx, si
0x0000000000005000:  31 C9             xor   cx, cx
0x0000000000005002:  30 E4             xor   ah, ah
0x0000000000005004:  E8 87 EE          call  0x3e8e
0x0000000000005007:  85 C0             test  ax, ax
0x0000000000005009:  74 81             je    0x4f8c
0x000000000000500b:  6A 00             push  0
0x000000000000500d:  8A 46 FE          mov   al, byte ptr [bp - 2]
0x0000000000005010:  8B 56 FA          mov   dx, word ptr [bp - 6]
0x0000000000005013:  30 E4             xor   ah, ah
0x0000000000005015:  89 F1             mov   cx, si
0x0000000000005017:  89 C3             mov   bx, ax
0x0000000000005019:  89 F8             mov   ax, di
0x000000000000501b:  E8 F2 FB          call  0x4c10
0x000000000000501e:  B0 01             mov   al, 1
0x0000000000005020:  C9                LEAVE_MACRO 
0x0000000000005021:  5F                pop   di
0x0000000000005022:  5E                pop   si
0x0000000000005023:  CB                retf  
0x0000000000005024:  BB 01 00          mov   bx, 1
0x0000000000005027:  89 F2             mov   dx, si
0x0000000000005029:  31 C9             xor   cx, cx
0x000000000000502b:  30 E4             xor   ah, ah
0x000000000000502d:  E8 5E EE          call  0x3e8e
0x0000000000005030:  85 C0             test  ax, ax
0x0000000000005032:  75 03             jne   0x5037
0x0000000000005034:  E9 C6 FE          jmp   0x4efd
0x0000000000005037:  6A 00             push  0
0x0000000000005039:  8A 46 FE          mov   al, byte ptr [bp - 2]
0x000000000000503c:  8B 56 FA          mov   dx, word ptr [bp - 6]
0x000000000000503f:  30 E4             xor   ah, ah
0x0000000000005041:  89 F1             mov   cx, si
0x0000000000005043:  89 C3             mov   bx, ax
0x0000000000005045:  89 F8             mov   ax, di
0x0000000000005047:  E8 C6 FB          call  0x4c10
0x000000000000504a:  B0 01             mov   al, 1
0x000000000000504c:  C9                LEAVE_MACRO 
0x000000000000504d:  5F                pop   di
0x000000000000504e:  5E                pop   si
0x000000000000504f:  CB                retf  
0x0000000000005050:  BB 01 00          mov   bx, 1
0x0000000000005053:  89 F2             mov   dx, si
0x0000000000005055:  30 E4             xor   ah, ah
0x0000000000005057:  0E                push  cs
0x0000000000005058:  3E E8 48 DB       call  0x2ba4
0x000000000000505c:  85 C0             test  ax, ax
0x000000000000505e:  74 D4             je    0x5034
0x0000000000005060:  6A 00             push  0
0x0000000000005062:  8A 46 FE          mov   al, byte ptr [bp - 2]
0x0000000000005065:  8B 56 FA          mov   dx, word ptr [bp - 6]
0x0000000000005068:  30 E4             xor   ah, ah
0x000000000000506a:  89 F1             mov   cx, si
0x000000000000506c:  89 C3             mov   bx, ax
0x000000000000506e:  89 F8             mov   ax, di
0x0000000000005070:  E8 9D FB          call  0x4c10
0x0000000000005073:  B0 01             mov   al, 1
0x0000000000005075:  C9                LEAVE_MACRO 
0x0000000000005076:  5F                pop   di
0x0000000000005077:  5E                pop   si
0x0000000000005078:  CB                retf  
0x0000000000005079:  31 D2             xor   dx, dx
0x000000000000507b:  30 E4             xor   ah, ah
0x000000000000507d:  0E                push  cs
0x000000000000507e:  3E E8 1C D4       call  0x249e
0x0000000000005082:  85 C0             test  ax, ax
0x0000000000005084:  74 AE             je    0x5034
0x0000000000005086:  6A 00             push  0
0x0000000000005088:  8A 46 FE          mov   al, byte ptr [bp - 2]
0x000000000000508b:  8B 56 FA          mov   dx, word ptr [bp - 6]
0x000000000000508e:  30 E4             xor   ah, ah
0x0000000000005090:  89 F1             mov   cx, si
0x0000000000005092:  89 C3             mov   bx, ax
0x0000000000005094:  89 F8             mov   ax, di
0x0000000000005096:  E8 77 FB          call  0x4c10
0x0000000000005099:  B0 01             mov   al, 1
0x000000000000509b:  C9                LEAVE_MACRO 
0x000000000000509c:  5F                pop   di
0x000000000000509d:  5E                pop   si
0x000000000000509e:  CB                retf  
0x000000000000509f:  31 D2             xor   dx, dx
0x00000000000050a1:  30 E4             xor   ah, ah
0x00000000000050a3:  E8 16 CF          call  0x1fbc
0x00000000000050a6:  85 C0             test  ax, ax
0x00000000000050a8:  74 8A             je    0x5034
0x00000000000050aa:  6A 00             push  0
0x00000000000050ac:  8A 46 FE          mov   al, byte ptr [bp - 2]
0x00000000000050af:  8B 56 FA          mov   dx, word ptr [bp - 6]
0x00000000000050b2:  30 E4             xor   ah, ah
0x00000000000050b4:  89 F1             mov   cx, si
0x00000000000050b6:  89 C3             mov   bx, ax
0x00000000000050b8:  89 F8             mov   ax, di
0x00000000000050ba:  E8 53 FB          call  0x4c10
0x00000000000050bd:  B0 01             mov   al, 1
0x00000000000050bf:  C9                LEAVE_MACRO 
0x00000000000050c0:  5F                pop   di
0x00000000000050c1:  5E                pop   si
0x00000000000050c2:  CB                retf  
0x00000000000050c3:  BB 02 00          mov   bx, 2
0x00000000000050c6:  89 F2             mov   dx, si
0x00000000000050c8:  30 E4             xor   ah, ah
0x00000000000050ca:  0E                push  cs
0x00000000000050cb:  E8 D6 DA          call  0x2ba4
0x00000000000050ce:  90                nop   
0x00000000000050cf:  85 C0             test  ax, ax
0x00000000000050d1:  75 03             jne   0x50d6
0x00000000000050d3:  E9 27 FE          jmp   0x4efd
0x00000000000050d6:  6A 00             push  0
0x00000000000050d8:  8A 46 FE          mov   al, byte ptr [bp - 2]
0x00000000000050db:  8B 56 FA          mov   dx, word ptr [bp - 6]
0x00000000000050de:  30 E4             xor   ah, ah
0x00000000000050e0:  89 F1             mov   cx, si
0x00000000000050e2:  89 C3             mov   bx, ax
0x00000000000050e4:  89 F8             mov   ax, di
0x00000000000050e6:  E8 27 FB          call  0x4c10
0x00000000000050e9:  B0 01             mov   al, 1
0x00000000000050eb:  C9                LEAVE_MACRO 
0x00000000000050ec:  5F                pop   di
0x00000000000050ed:  5E                pop   si
0x00000000000050ee:  CB                retf  
0x00000000000050ef:  BA 03 00          mov   dx, 3
0x00000000000050f2:  30 E4             xor   ah, ah
0x00000000000050f4:  E8 C5 CE          call  0x1fbc
0x00000000000050f7:  85 C0             test  ax, ax
0x00000000000050f9:  74 D8             je    0x50d3
0x00000000000050fb:  6A 00             push  0
0x00000000000050fd:  8A 46 FE          mov   al, byte ptr [bp - 2]
0x0000000000005100:  8B 56 FA          mov   dx, word ptr [bp - 6]
0x0000000000005103:  30 E4             xor   ah, ah
0x0000000000005105:  89 F1             mov   cx, si
0x0000000000005107:  89 C3             mov   bx, ax
0x0000000000005109:  89 F8             mov   ax, di
0x000000000000510b:  E8 02 FB          call  0x4c10
0x000000000000510e:  B0 01             mov   al, 1
0x0000000000005110:  C9                LEAVE_MACRO 
0x0000000000005111:  5F                pop   di
0x0000000000005112:  5E                pop   si
0x0000000000005113:  CB                retf  
0x0000000000005114:  BA 02 00          mov   dx, 2
0x0000000000005117:  30 E4             xor   ah, ah
0x0000000000005119:  0E                push  cs
0x000000000000511a:  3E E8 80 D3       call  0x249e
0x000000000000511e:  85 C0             test  ax, ax
0x0000000000005120:  74 B1             je    0x50d3
0x0000000000005122:  6A 00             push  0
0x0000000000005124:  8A 46 FE          mov   al, byte ptr [bp - 2]
0x0000000000005127:  8B 56 FA          mov   dx, word ptr [bp - 6]
0x000000000000512a:  30 E4             xor   ah, ah
0x000000000000512c:  89 F1             mov   cx, si
0x000000000000512e:  89 C3             mov   bx, ax
0x0000000000005130:  89 F8             mov   ax, di
0x0000000000005132:  E8 DB FA          call  0x4c10
0x0000000000005135:  B0 01             mov   al, 1
0x0000000000005137:  C9                LEAVE_MACRO 
0x0000000000005138:  5F                pop   di
0x0000000000005139:  5E                pop   si
0x000000000000513a:  CB                retf  
0x000000000000513b:  6A 00             push  0
0x000000000000513d:  8A 46 FE          mov   al, byte ptr [bp - 2]
0x0000000000005140:  8B 56 FA          mov   dx, word ptr [bp - 6]
0x0000000000005143:  30 E4             xor   ah, ah
0x0000000000005145:  89 F1             mov   cx, si
0x0000000000005147:  89 C3             mov   bx, ax
0x0000000000005149:  89 F8             mov   ax, di
0x000000000000514b:  E8 C2 FA          call  0x4c10
0x000000000000514e:  9A 42 19 A8 0A    lcall 0xaa8:0x1942
0x0000000000005153:  B0 01             mov   al, 1
0x0000000000005155:  C9                LEAVE_MACRO 
0x0000000000005156:  5F                pop   di
0x0000000000005157:  5E                pop   si
0x0000000000005158:  CB                retf  
0x0000000000005159:  BB 09 00          mov   bx, 9
0x000000000000515c:  89 F2             mov   dx, si
0x000000000000515e:  30 E4             xor   ah, ah
0x0000000000005160:  0E                push  cs
0x0000000000005161:  E8 40 DA          call  0x2ba4
0x0000000000005164:  90                nop   
0x0000000000005165:  85 C0             test  ax, ax
0x0000000000005167:  75 03             jne   0x516c
0x0000000000005169:  E9 91 FD          jmp   0x4efd
0x000000000000516c:  6A 00             push  0
0x000000000000516e:  8A 46 FE          mov   al, byte ptr [bp - 2]
0x0000000000005171:  8B 56 FA          mov   dx, word ptr [bp - 6]
0x0000000000005174:  30 E4             xor   ah, ah
0x0000000000005176:  89 F1             mov   cx, si
0x0000000000005178:  89 C3             mov   bx, ax
0x000000000000517a:  89 F8             mov   ax, di
0x000000000000517c:  E8 91 FA          call  0x4c10
0x000000000000517f:  B0 01             mov   al, 1
0x0000000000005181:  C9                LEAVE_MACRO 
0x0000000000005182:  5F                pop   di
0x0000000000005183:  5E                pop   si
0x0000000000005184:  CB                retf  
0x0000000000005185:  BB 03 00          mov   bx, 3
0x0000000000005188:  89 F2             mov   dx, si
0x000000000000518a:  30 E4             xor   ah, ah
0x000000000000518c:  0E                push  cs
0x000000000000518d:  E8 14 DA          call  0x2ba4
0x0000000000005190:  90                nop   
0x0000000000005191:  85 C0             test  ax, ax
0x0000000000005193:  74 D4             je    0x5169
0x0000000000005195:  6A 00             push  0
0x0000000000005197:  8A 46 FE          mov   al, byte ptr [bp - 2]
0x000000000000519a:  8B 56 FA          mov   dx, word ptr [bp - 6]
0x000000000000519d:  30 E4             xor   ah, ah
0x000000000000519f:  89 F1             mov   cx, si
0x00000000000051a1:  89 C3             mov   bx, ax
0x00000000000051a3:  89 F8             mov   ax, di
0x00000000000051a5:  E8 68 FA          call  0x4c10
0x00000000000051a8:  B0 01             mov   al, 1
0x00000000000051aa:  C9                LEAVE_MACRO 
0x00000000000051ab:  5F                pop   di
0x00000000000051ac:  5E                pop   si
0x00000000000051ad:  CB                retf  
0x00000000000051ae:  89 F2             mov   dx, si
0x00000000000051b0:  30 E4             xor   ah, ah
0x00000000000051b2:  31 DB             xor   bx, bx
0x00000000000051b4:  0E                push  cs
0x00000000000051b5:  E8 EC D9          call  0x2ba4
0x00000000000051b8:  90                nop   
0x00000000000051b9:  85 C0             test  ax, ax
0x00000000000051bb:  74 AC             je    0x5169
0x00000000000051bd:  6A 00             push  0
0x00000000000051bf:  8A 5E FE          mov   bl, byte ptr [bp - 2]
0x00000000000051c2:  8B 56 FA          mov   dx, word ptr [bp - 6]
0x00000000000051c5:  89 F1             mov   cx, si
0x00000000000051c7:  89 F8             mov   ax, di
0x00000000000051c9:  30 FF             xor   bh, bh
0x00000000000051cb:  E8 42 FA          call  0x4c10
0x00000000000051ce:  B0 01             mov   al, 1
0x00000000000051d0:  C9                LEAVE_MACRO 
0x00000000000051d1:  5F                pop   di
0x00000000000051d2:  5E                pop   si
0x00000000000051d3:  CB                retf  
0x00000000000051d4:  BA 03 00          mov   dx, 3
0x00000000000051d7:  30 E4             xor   ah, ah
0x00000000000051d9:  0E                push  cs
0x00000000000051da:  3E E8 C0 D2       call  0x249e
0x00000000000051de:  85 C0             test  ax, ax
0x00000000000051e0:  74 87             je    0x5169
0x00000000000051e2:  6A 00             push  0
0x00000000000051e4:  8A 5E FE          mov   bl, byte ptr [bp - 2]
0x00000000000051e7:  8B 56 FA          mov   dx, word ptr [bp - 6]
0x00000000000051ea:  89 F1             mov   cx, si
0x00000000000051ec:  89 F8             mov   ax, di
0x00000000000051ee:  30 FF             xor   bh, bh
0x00000000000051f0:  E8 1D FA          call  0x4c10
0x00000000000051f3:  B0 01             mov   al, 1
0x00000000000051f5:  C9                LEAVE_MACRO 
0x00000000000051f6:  5F                pop   di
0x00000000000051f7:  5E                pop   si
0x00000000000051f8:  CB                retf  
0x00000000000051f9:  BA 05 00          mov   dx, 5
0x00000000000051fc:  30 E4             xor   ah, ah
0x00000000000051fe:  0E                push  cs
0x00000000000051ff:  E8 9C D2          call  0x249e
0x0000000000005202:  90                nop   
0x0000000000005203:  85 C0             test  ax, ax
0x0000000000005205:  75 03             jne   0x520a
0x0000000000005207:  E9 F3 FC          jmp   0x4efd
0x000000000000520a:  6A 00             push  0
0x000000000000520c:  8A 5E FE          mov   bl, byte ptr [bp - 2]
0x000000000000520f:  8B 56 FA          mov   dx, word ptr [bp - 6]
0x0000000000005212:  89 F1             mov   cx, si
0x0000000000005214:  89 F8             mov   ax, di
0x0000000000005216:  30 FF             xor   bh, bh
0x0000000000005218:  E8 F5 F9          call  0x4c10
0x000000000000521b:  B0 01             mov   al, 1
0x000000000000521d:  C9                LEAVE_MACRO 
0x000000000000521e:  5F                pop   di
0x000000000000521f:  5E                pop   si
0x0000000000005220:  CB                retf  
0x0000000000005221:  BA 06 00          mov   dx, 6
0x0000000000005224:  30 E4             xor   ah, ah
0x0000000000005226:  0E                push  cs
0x0000000000005227:  E8 74 D2          call  0x249e
0x000000000000522a:  90                nop   
0x000000000000522b:  85 C0             test  ax, ax
0x000000000000522d:  74 D8             je    0x5207
0x000000000000522f:  6A 00             push  0
0x0000000000005231:  8A 5E FE          mov   bl, byte ptr [bp - 2]
0x0000000000005234:  8B 56 FA          mov   dx, word ptr [bp - 6]
0x0000000000005237:  89 F1             mov   cx, si
0x0000000000005239:  89 F8             mov   ax, di
0x000000000000523b:  30 FF             xor   bh, bh
0x000000000000523d:  E8 D0 F9          call  0x4c10
0x0000000000005240:  B0 01             mov   al, 1
0x0000000000005242:  C9                LEAVE_MACRO 
0x0000000000005243:  5F                pop   di
0x0000000000005244:  5E                pop   si
0x0000000000005245:  CB                retf  
0x0000000000005246:  BA 07 00          mov   dx, 7
0x0000000000005249:  30 E4             xor   ah, ah
0x000000000000524b:  0E                push  cs
0x000000000000524c:  3E E8 4E D2       call  0x249e
0x0000000000005250:  85 C0             test  ax, ax
0x0000000000005252:  74 B3             je    0x5207
0x0000000000005254:  6A 00             push  0
0x0000000000005256:  8A 5E FE          mov   bl, byte ptr [bp - 2]
0x0000000000005259:  8B 56 FA          mov   dx, word ptr [bp - 6]
0x000000000000525c:  89 F1             mov   cx, si
0x000000000000525e:  89 F8             mov   ax, di
0x0000000000005260:  30 FF             xor   bh, bh
0x0000000000005262:  E8 AB F9          call  0x4c10
0x0000000000005265:  B0 01             mov   al, 1
0x0000000000005267:  C9                LEAVE_MACRO 
0x0000000000005268:  5F                pop   di
0x0000000000005269:  5E                pop   si
0x000000000000526a:  CB                retf  
0x000000000000526b:  BB 04 00          mov   bx, 4
0x000000000000526e:  89 F2             mov   dx, si
0x0000000000005270:  30 E4             xor   ah, ah
0x0000000000005272:  31 C9             xor   cx, cx
0x0000000000005274:  E8 17 EC          call  0x3e8e
0x0000000000005277:  85 C0             test  ax, ax
0x0000000000005279:  74 8C             je    0x5207
0x000000000000527b:  6A 00             push  0
0x000000000000527d:  8A 5E FE          mov   bl, byte ptr [bp - 2]
0x0000000000005280:  8B 56 FA          mov   dx, word ptr [bp - 6]
0x0000000000005283:  89 F1             mov   cx, si
0x0000000000005285:  89 F8             mov   ax, di
0x0000000000005287:  30 FF             xor   bh, bh
0x0000000000005289:  E8 84 F9          call  0x4c10
0x000000000000528c:  B0 01             mov   al, 1
0x000000000000528e:  C9                LEAVE_MACRO 
0x000000000000528f:  5F                pop   di
0x0000000000005290:  5E                pop   si
0x0000000000005291:  CB                retf  
0x0000000000005292:  BA 01 00          mov   dx, 1
0x0000000000005295:  30 E4             xor   ah, ah
0x0000000000005297:  E8 9A DC          call  0x2f34
0x000000000000529a:  85 C0             test  ax, ax
0x000000000000529c:  75 03             jne   0x52a1
0x000000000000529e:  E9 5C FC          jmp   0x4efd
0x00000000000052a1:  6A 00             push  0
0x00000000000052a3:  8A 5E FE          mov   bl, byte ptr [bp - 2]
0x00000000000052a6:  8B 56 FA          mov   dx, word ptr [bp - 6]
0x00000000000052a9:  89 F1             mov   cx, si
0x00000000000052ab:  89 F8             mov   ax, di
0x00000000000052ad:  30 FF             xor   bh, bh
0x00000000000052af:  E8 5E F9          call  0x4c10
0x00000000000052b2:  B0 01             mov   al, 1
0x00000000000052b4:  C9                LEAVE_MACRO 
0x00000000000052b5:  5F                pop   di
0x00000000000052b6:  5E                pop   si
0x00000000000052b7:  CB                retf  
0x00000000000052b8:  BB 0A 00          mov   bx, 0xa
0x00000000000052bb:  89 F2             mov   dx, si
0x00000000000052bd:  30 E4             xor   ah, ah
0x00000000000052bf:  0E                push  cs
0x00000000000052c0:  3E E8 E0 D8       call  0x2ba4
0x00000000000052c4:  85 C0             test  ax, ax
0x00000000000052c6:  74 D6             je    0x529e
0x00000000000052c8:  6A 00             push  0
0x00000000000052ca:  8A 5E FE          mov   bl, byte ptr [bp - 2]
0x00000000000052cd:  8B 56 FA          mov   dx, word ptr [bp - 6]
0x00000000000052d0:  89 F1             mov   cx, si
0x00000000000052d2:  89 F8             mov   ax, di
0x00000000000052d4:  30 FF             xor   bh, bh
0x00000000000052d6:  E8 37 F9          call  0x4c10
0x00000000000052d9:  B0 01             mov   al, 1
0x00000000000052db:  C9                LEAVE_MACRO 
0x00000000000052dc:  5F                pop   di
0x00000000000052dd:  5E                pop   si
0x00000000000052de:  CB                retf  
0x00000000000052df:  8A 66 FE          mov   ah, byte ptr [bp - 2]
0x00000000000052e2:  C6 46 F9 00       mov   byte ptr [bp - 7], 0
0x00000000000052e6:  BB 06 00          mov   bx, 6
0x00000000000052e9:  88 66 F8          mov   byte ptr [bp - 8], ah
0x00000000000052ec:  89 D1             mov   cx, dx
0x00000000000052ee:  8B 56 F8          mov   dx, word ptr [bp - 8]
0x00000000000052f1:  30 E4             xor   ah, ah
0x00000000000052f3:  E8 E2 D0          call  0x23d8
0x00000000000052f6:  85 C0             test  ax, ax
0x00000000000052f8:  74 A4             je    0x529e
0x00000000000052fa:  6A 00             push  0
0x00000000000052fc:  8B 5E F8          mov   bx, word ptr [bp - 8]
0x00000000000052ff:  8B 56 FA          mov   dx, word ptr [bp - 6]
0x0000000000005302:  89 F1             mov   cx, si
0x0000000000005304:  89 F8             mov   ax, di
0x0000000000005306:  E8 07 F9          call  0x4c10
0x0000000000005309:  B0 01             mov   al, 1
0x000000000000530b:  C9                LEAVE_MACRO 
0x000000000000530c:  5F                pop   di
0x000000000000530d:  5E                pop   si
0x000000000000530e:  CB                retf  
0x000000000000530f:  BB 0C 00          mov   bx, 0xc
0x0000000000005312:  89 F2             mov   dx, si
0x0000000000005314:  30 E4             xor   ah, ah
0x0000000000005316:  0E                push  cs
0x0000000000005317:  E8 8A D8          call  0x2ba4
0x000000000000531a:  90                nop   
0x000000000000531b:  85 C0             test  ax, ax
0x000000000000531d:  75 03             jne   0x5322
0x000000000000531f:  E9 DB FB          jmp   0x4efd
0x0000000000005322:  6A 00             push  0
0x0000000000005324:  8A 5E FE          mov   bl, byte ptr [bp - 2]
0x0000000000005327:  8B 56 FA          mov   dx, word ptr [bp - 6]
0x000000000000532a:  89 F1             mov   cx, si
0x000000000000532c:  89 F8             mov   ax, di
0x000000000000532e:  30 FF             xor   bh, bh
0x0000000000005330:  E8 DD F8          call  0x4c10
0x0000000000005333:  B0 01             mov   al, 1
0x0000000000005335:  C9                LEAVE_MACRO 
0x0000000000005336:  5F                pop   di
0x0000000000005337:  5E                pop   si
0x0000000000005338:  CB                retf  
0x0000000000005339:  BA 02 00          mov   dx, 2
0x000000000000533c:  30 E4             xor   ah, ah
0x000000000000533e:  0E                push  cs
0x000000000000533f:  E8 5C D1          call  0x249e
0x0000000000005342:  90                nop   
0x0000000000005343:  85 C0             test  ax, ax
0x0000000000005345:  74 D8             je    0x531f
0x0000000000005347:  6A 01             push  1
0x0000000000005349:  8A 46 FE          mov   al, byte ptr [bp - 2]
0x000000000000534c:  8B 56 FA          mov   dx, word ptr [bp - 6]
0x000000000000534f:  30 E4             xor   ah, ah
0x0000000000005351:  89 F1             mov   cx, si
0x0000000000005353:  89 C3             mov   bx, ax
0x0000000000005355:  89 F8             mov   ax, di
0x0000000000005357:  E8 B6 F8          call  0x4c10
0x000000000000535a:  B0 01             mov   al, 1
0x000000000000535c:  C9                LEAVE_MACRO 
0x000000000000535d:  5F                pop   di
0x000000000000535e:  5E                pop   si
0x000000000000535f:  CB                retf  
0x0000000000005360:  31 D2             xor   dx, dx
0x0000000000005362:  30 E4             xor   ah, ah
0x0000000000005364:  E8 55 CC          call  0x1fbc
0x0000000000005367:  85 C0             test  ax, ax
0x0000000000005369:  74 B4             je    0x531f
0x000000000000536b:  6A 01             push  1
0x000000000000536d:  8A 46 FE          mov   al, byte ptr [bp - 2]
0x0000000000005370:  8B 56 FA          mov   dx, word ptr [bp - 6]
0x0000000000005373:  30 E4             xor   ah, ah
0x0000000000005375:  89 F1             mov   cx, si
0x0000000000005377:  89 C3             mov   bx, ax
0x0000000000005379:  89 F8             mov   ax, di
0x000000000000537b:  E8 92 F8          call  0x4c10
0x000000000000537e:  B0 01             mov   al, 1
0x0000000000005380:  C9                LEAVE_MACRO 
0x0000000000005381:  5F                pop   di
0x0000000000005382:  5E                pop   si
0x0000000000005383:  CB                retf  
0x0000000000005384:  89 F2             mov   dx, si
0x0000000000005386:  31 DB             xor   bx, bx
0x0000000000005388:  30 E4             xor   ah, ah
0x000000000000538a:  0E                push  cs
0x000000000000538b:  E8 16 D8          call  0x2ba4
0x000000000000538e:  90                nop   
0x000000000000538f:  85 C0             test  ax, ax
0x0000000000005391:  74 8C             je    0x531f
0x0000000000005393:  6A 01             push  1
0x0000000000005395:  8A 46 FE          mov   al, byte ptr [bp - 2]
0x0000000000005398:  8B 56 FA          mov   dx, word ptr [bp - 6]
0x000000000000539b:  30 E4             xor   ah, ah
0x000000000000539d:  89 F1             mov   cx, si
0x000000000000539f:  89 C3             mov   bx, ax
0x00000000000053a1:  89 F8             mov   ax, di
0x00000000000053a3:  E8 6A F8          call  0x4c10
0x00000000000053a6:  B0 01             mov   al, 1
0x00000000000053a8:  C9                LEAVE_MACRO 
0x00000000000053a9:  5F                pop   di
0x00000000000053aa:  5E                pop   si
0x00000000000053ab:  CB                retf  
0x00000000000053ac:  BB 01 00          mov   bx, 1
0x00000000000053af:  89 F2             mov   dx, si
0x00000000000053b1:  30 E4             xor   ah, ah
0x00000000000053b3:  0E                push  cs
0x00000000000053b4:  3E E8 EC D7       call  0x2ba4
0x00000000000053b8:  85 C0             test  ax, ax
0x00000000000053ba:  75 03             jne   0x53bf
0x00000000000053bc:  E9 3E FB          jmp   0x4efd
0x00000000000053bf:  6A 01             push  1
0x00000000000053c1:  8A 46 FE          mov   al, byte ptr [bp - 2]
0x00000000000053c4:  8B 56 FA          mov   dx, word ptr [bp - 6]
0x00000000000053c7:  30 E4             xor   ah, ah
0x00000000000053c9:  89 F1             mov   cx, si
0x00000000000053cb:  89 C3             mov   bx, ax
0x00000000000053cd:  89 F8             mov   ax, di
0x00000000000053cf:  E8 3E F8          call  0x4c10
0x00000000000053d2:  B0 01             mov   al, 1
0x00000000000053d4:  C9                LEAVE_MACRO 
0x00000000000053d5:  5F                pop   di
0x00000000000053d6:  5E                pop   si
0x00000000000053d7:  CB                retf  
0x00000000000053d8:  BA 03 00          mov   dx, 3
0x00000000000053db:  30 E4             xor   ah, ah
0x00000000000053dd:  0E                push  cs
0x00000000000053de:  3E E8 BC D0       call  0x249e
0x00000000000053e2:  85 C0             test  ax, ax
0x00000000000053e4:  74 D6             je    0x53bc
0x00000000000053e6:  6A 01             push  1
0x00000000000053e8:  8A 46 FE          mov   al, byte ptr [bp - 2]
0x00000000000053eb:  8B 56 FA          mov   dx, word ptr [bp - 6]
0x00000000000053ee:  30 E4             xor   ah, ah
0x00000000000053f0:  89 F1             mov   cx, si
0x00000000000053f2:  89 C3             mov   bx, ax
0x00000000000053f4:  89 F8             mov   ax, di
0x00000000000053f6:  E8 17 F8          call  0x4c10
0x00000000000053f9:  B0 01             mov   al, 1
0x00000000000053fb:  C9                LEAVE_MACRO 
0x00000000000053fc:  5F                pop   di
0x00000000000053fd:  5E                pop   si
0x00000000000053fe:  CB                retf  
0x00000000000053ff:  B9 01 00          mov   cx, 1
0x0000000000005402:  89 F2             mov   dx, si
0x0000000000005404:  30 E4             xor   ah, ah
0x0000000000005406:  89 CB             mov   bx, cx
0x0000000000005408:  E8 83 EA          call  0x3e8e
0x000000000000540b:  85 C0             test  ax, ax
0x000000000000540d:  74 AD             je    0x53bc
0x000000000000540f:  6A 01             push  1
0x0000000000005411:  8A 46 FE          mov   al, byte ptr [bp - 2]
0x0000000000005414:  8B 56 FA          mov   dx, word ptr [bp - 6]
0x0000000000005417:  30 E4             xor   ah, ah
0x0000000000005419:  89 F1             mov   cx, si
0x000000000000541b:  89 C3             mov   bx, ax
0x000000000000541d:  89 F8             mov   ax, di
0x000000000000541f:  E8 EE F7          call  0x4c10
0x0000000000005422:  B0 01             mov   al, 1
0x0000000000005424:  C9                LEAVE_MACRO 
0x0000000000005425:  5F                pop   di
0x0000000000005426:  5E                pop   si
0x0000000000005427:  CB                retf  
0x0000000000005428:  31 D2             xor   dx, dx
0x000000000000542a:  30 E4             xor   ah, ah
0x000000000000542c:  0E                push  cs
0x000000000000542d:  E8 6E D0          call  0x249e
0x0000000000005430:  90                nop   
0x0000000000005431:  85 C0             test  ax, ax
0x0000000000005433:  74 87             je    0x53bc
0x0000000000005435:  6A 01             push  1
0x0000000000005437:  8A 46 FE          mov   al, byte ptr [bp - 2]
0x000000000000543a:  8B 56 FA          mov   dx, word ptr [bp - 6]
0x000000000000543d:  30 E4             xor   ah, ah
0x000000000000543f:  89 F1             mov   cx, si
0x0000000000005441:  89 C3             mov   bx, ax
0x0000000000005443:  89 F8             mov   ax, di
0x0000000000005445:  E8 C8 F7          call  0x4c10
0x0000000000005448:  B0 01             mov   al, 1
0x000000000000544a:  C9                LEAVE_MACRO 
0x000000000000544b:  5F                pop   di
0x000000000000544c:  5E                pop   si
0x000000000000544d:  CB                retf  
0x000000000000544e:  BB 03 00          mov   bx, 3
0x0000000000005451:  89 F2             mov   dx, si
0x0000000000005453:  30 E4             xor   ah, ah
0x0000000000005455:  0E                push  cs
0x0000000000005456:  3E E8 4A D7       call  0x2ba4
0x000000000000545a:  85 C0             test  ax, ax
0x000000000000545c:  75 03             jne   0x5461
0x000000000000545e:  E9 9C FA          jmp   0x4efd
0x0000000000005461:  6A 01             push  1
0x0000000000005463:  8A 46 FE          mov   al, byte ptr [bp - 2]
0x0000000000005466:  8B 56 FA          mov   dx, word ptr [bp - 6]
0x0000000000005469:  30 E4             xor   ah, ah
0x000000000000546b:  89 F1             mov   cx, si
0x000000000000546d:  89 C3             mov   bx, ax
0x000000000000546f:  89 F8             mov   ax, di
0x0000000000005471:  E8 9C F7          call  0x4c10
0x0000000000005474:  B0 01             mov   al, 1
0x0000000000005476:  C9                LEAVE_MACRO 
0x0000000000005477:  5F                pop   di
0x0000000000005478:  5E                pop   si
0x0000000000005479:  CB                retf  
0x000000000000547a:  B9 18 00          mov   cx, 0x18
0x000000000000547d:  BB 02 00          mov   bx, 2
0x0000000000005480:  89 F2             mov   dx, si
0x0000000000005482:  30 E4             xor   ah, ah
0x0000000000005484:  E8 07 EA          call  0x3e8e
0x0000000000005487:  85 C0             test  ax, ax
0x0000000000005489:  74 D3             je    0x545e
0x000000000000548b:  6A 01             push  1
0x000000000000548d:  8A 46 FE          mov   al, byte ptr [bp - 2]
0x0000000000005490:  8B 56 FA          mov   dx, word ptr [bp - 6]
0x0000000000005493:  30 E4             xor   ah, ah
0x0000000000005495:  89 F1             mov   cx, si
0x0000000000005497:  89 C3             mov   bx, ax
0x0000000000005499:  89 F8             mov   ax, di
0x000000000000549b:  E8 72 F7          call  0x4c10
0x000000000000549e:  B0 01             mov   al, 1
0x00000000000054a0:  C9                LEAVE_MACRO 
0x00000000000054a1:  5F                pop   di
0x00000000000054a2:  5E                pop   si
0x00000000000054a3:  CB                retf  
0x00000000000054a4:  B9 20 00          mov   cx, 0x20
0x00000000000054a7:  BB 02 00          mov   bx, 2
0x00000000000054aa:  89 F2             mov   dx, si
0x00000000000054ac:  30 E4             xor   ah, ah
0x00000000000054ae:  E8 DD E9          call  0x3e8e
0x00000000000054b1:  85 C0             test  ax, ax
0x00000000000054b3:  74 A9             je    0x545e
0x00000000000054b5:  6A 01             push  1
0x00000000000054b7:  8A 46 FE          mov   al, byte ptr [bp - 2]
0x00000000000054ba:  8B 56 FA          mov   dx, word ptr [bp - 6]
0x00000000000054bd:  30 E4             xor   ah, ah
0x00000000000054bf:  89 F1             mov   cx, si
0x00000000000054c1:  89 C3             mov   bx, ax
0x00000000000054c3:  89 F8             mov   ax, di
0x00000000000054c5:  E8 48 F7          call  0x4c10
0x00000000000054c8:  B0 01             mov   al, 1
0x00000000000054ca:  C9                LEAVE_MACRO 
0x00000000000054cb:  5F                pop   di
0x00000000000054cc:  5E                pop   si
0x00000000000054cd:  CB                retf  
0x00000000000054ce:  BB 09 00          mov   bx, 9
0x00000000000054d1:  89 F2             mov   dx, si
0x00000000000054d3:  30 E4             xor   ah, ah
0x00000000000054d5:  0E                push  cs
0x00000000000054d6:  3E E8 CA D6       call  0x2ba4
0x00000000000054da:  85 C0             test  ax, ax
0x00000000000054dc:  74 80             je    0x545e
0x00000000000054de:  6A 01             push  1
0x00000000000054e0:  8A 46 FE          mov   al, byte ptr [bp - 2]
0x00000000000054e3:  8B 56 FA          mov   dx, word ptr [bp - 6]
0x00000000000054e6:  30 E4             xor   ah, ah
0x00000000000054e8:  89 F1             mov   cx, si
0x00000000000054ea:  89 C3             mov   bx, ax
0x00000000000054ec:  89 F8             mov   ax, di
0x00000000000054ee:  E8 1F F7          call  0x4c10
0x00000000000054f1:  B0 01             mov   al, 1
0x00000000000054f3:  C9                LEAVE_MACRO 
0x00000000000054f4:  5F                pop   di
0x00000000000054f5:  5E                pop   si
0x00000000000054f6:  CB                retf  
0x00000000000054f7:  BB 03 00          mov   bx, 3
0x00000000000054fa:  89 F2             mov   dx, si
0x00000000000054fc:  31 C9             xor   cx, cx
0x00000000000054fe:  30 E4             xor   ah, ah
0x0000000000005500:  E8 8B E9          call  0x3e8e
0x0000000000005503:  85 C0             test  ax, ax
0x0000000000005505:  75 03             jne   0x550a
0x0000000000005507:  E9 F3 F9          jmp   0x4efd
0x000000000000550a:  6A 01             push  1
0x000000000000550c:  8A 46 FE          mov   al, byte ptr [bp - 2]
0x000000000000550f:  8B 56 FA          mov   dx, word ptr [bp - 6]
0x0000000000005512:  30 E4             xor   ah, ah
0x0000000000005514:  89 F1             mov   cx, si
0x0000000000005516:  89 C3             mov   bx, ax
0x0000000000005518:  89 F8             mov   ax, di
0x000000000000551a:  E8 F3 F6          call  0x4c10
0x000000000000551d:  B0 01             mov   al, 1
0x000000000000551f:  C9                LEAVE_MACRO 
0x0000000000005520:  5F                pop   di
0x0000000000005521:  5E                pop   si
0x0000000000005522:  CB                retf  
0x0000000000005523:  BB 04 00          mov   bx, 4
0x0000000000005526:  89 F2             mov   dx, si
0x0000000000005528:  30 E4             xor   ah, ah
0x000000000000552a:  0E                push  cs
0x000000000000552b:  E8 76 D6          call  0x2ba4
0x000000000000552e:  90                nop   
0x000000000000552f:  85 C0             test  ax, ax
0x0000000000005531:  74 D4             je    0x5507
0x0000000000005533:  6A 01             push  1
0x0000000000005535:  8A 46 FE          mov   al, byte ptr [bp - 2]
0x0000000000005538:  8B 56 FA          mov   dx, word ptr [bp - 6]
0x000000000000553b:  30 E4             xor   ah, ah
0x000000000000553d:  89 F1             mov   cx, si
0x000000000000553f:  89 C3             mov   bx, ax
0x0000000000005541:  89 F8             mov   ax, di
0x0000000000005543:  E8 CA F6          call  0x4c10
0x0000000000005546:  B0 01             mov   al, 1
0x0000000000005548:  C9                LEAVE_MACRO 
0x0000000000005549:  5F                pop   di
0x000000000000554a:  5E                pop   si
0x000000000000554b:  CB                retf  
0x000000000000554c:  BB 02 00          mov   bx, 2
0x000000000000554f:  89 F2             mov   dx, si
0x0000000000005551:  30 E4             xor   ah, ah
0x0000000000005553:  0E                push  cs
0x0000000000005554:  3E E8 4C D6       call  0x2ba4
0x0000000000005558:  85 C0             test  ax, ax
0x000000000000555a:  74 AB             je    0x5507
0x000000000000555c:  6A 01             push  1
0x000000000000555e:  8A 46 FE          mov   al, byte ptr [bp - 2]
0x0000000000005561:  8B 56 FA          mov   dx, word ptr [bp - 6]
0x0000000000005564:  30 E4             xor   ah, ah
0x0000000000005566:  89 F1             mov   cx, si
0x0000000000005568:  89 C3             mov   bx, ax
0x000000000000556a:  89 F8             mov   ax, di
0x000000000000556c:  E8 A1 F6          call  0x4c10
0x000000000000556f:  B0 01             mov   al, 1
0x0000000000005571:  C9                LEAVE_MACRO 
0x0000000000005572:  5F                pop   di
0x0000000000005573:  5E                pop   si
0x0000000000005574:  CB                retf  
0x0000000000005575:  BA 05 00          mov   dx, 5
0x0000000000005578:  30 E4             xor   ah, ah
0x000000000000557a:  0E                push  cs
0x000000000000557b:  E8 20 CF          call  0x249e
0x000000000000557e:  90                nop   
0x000000000000557f:  85 C0             test  ax, ax
0x0000000000005581:  74 84             je    0x5507
0x0000000000005583:  6A 01             push  1
0x0000000000005585:  8A 5E FE          mov   bl, byte ptr [bp - 2]
0x0000000000005588:  8B 56 FA          mov   dx, word ptr [bp - 6]
0x000000000000558b:  89 F1             mov   cx, si
0x000000000000558d:  89 F8             mov   ax, di
0x000000000000558f:  30 FF             xor   bh, bh
0x0000000000005591:  E8 7C F6          call  0x4c10
0x0000000000005594:  B0 01             mov   al, 1
0x0000000000005596:  C9                LEAVE_MACRO 
0x0000000000005597:  5F                pop   di
0x0000000000005598:  5E                pop   si
0x0000000000005599:  CB                retf  
0x000000000000559a:  BA 06 00          mov   dx, 6
0x000000000000559d:  30 E4             xor   ah, ah
0x000000000000559f:  0E                push  cs
0x00000000000055a0:  3E E8 FA CE       call  0x249e
0x00000000000055a4:  85 C0             test  ax, ax
0x00000000000055a6:  75 03             jne   0x55ab
0x00000000000055a8:  E9 52 F9          jmp   0x4efd
0x00000000000055ab:  6A 01             push  1
0x00000000000055ad:  8A 5E FE          mov   bl, byte ptr [bp - 2]
0x00000000000055b0:  8B 56 FA          mov   dx, word ptr [bp - 6]
0x00000000000055b3:  89 F1             mov   cx, si
0x00000000000055b5:  89 F8             mov   ax, di
0x00000000000055b7:  30 FF             xor   bh, bh
0x00000000000055b9:  E8 54 F6          call  0x4c10
0x00000000000055bc:  B0 01             mov   al, 1
0x00000000000055be:  C9                LEAVE_MACRO 
0x00000000000055bf:  5F                pop   di
0x00000000000055c0:  5E                pop   si
0x00000000000055c1:  CB                retf  
0x00000000000055c2:  BA 07 00          mov   dx, 7
0x00000000000055c5:  30 E4             xor   ah, ah
0x00000000000055c7:  0E                push  cs
0x00000000000055c8:  3E E8 D2 CE       call  0x249e
0x00000000000055cc:  85 C0             test  ax, ax
0x00000000000055ce:  74 D8             je    0x55a8
0x00000000000055d0:  6A 01             push  1
0x00000000000055d2:  8A 5E FE          mov   bl, byte ptr [bp - 2]
0x00000000000055d5:  8B 56 FA          mov   dx, word ptr [bp - 6]
0x00000000000055d8:  89 F1             mov   cx, si
0x00000000000055da:  89 F8             mov   ax, di
0x00000000000055dc:  30 FF             xor   bh, bh
0x00000000000055de:  E8 2F F6          call  0x4c10
0x00000000000055e1:  B0 01             mov   al, 1
0x00000000000055e3:  C9                LEAVE_MACRO 
0x00000000000055e4:  5F                pop   di
0x00000000000055e5:  5E                pop   si
0x00000000000055e6:  CB                retf  
0x00000000000055e7:  BB 04 00          mov   bx, 4
0x00000000000055ea:  89 F2             mov   dx, si
0x00000000000055ec:  30 E4             xor   ah, ah
0x00000000000055ee:  31 C9             xor   cx, cx
0x00000000000055f0:  E8 9B E8          call  0x3e8e
0x00000000000055f3:  85 C0             test  ax, ax
0x00000000000055f5:  74 B1             je    0x55a8
0x00000000000055f7:  6A 01             push  1
0x00000000000055f9:  8A 5E FE          mov   bl, byte ptr [bp - 2]
0x00000000000055fc:  8B 56 FA          mov   dx, word ptr [bp - 6]
0x00000000000055ff:  89 F1             mov   cx, si
0x0000000000005601:  89 F8             mov   ax, di
0x0000000000005603:  30 FF             xor   bh, bh
0x0000000000005605:  E8 08 F6          call  0x4c10
0x0000000000005608:  B0 01             mov   al, 1
0x000000000000560a:  C9                LEAVE_MACRO 
0x000000000000560b:  5F                pop   di
0x000000000000560c:  5E                pop   si
0x000000000000560d:  CB                retf  
0x000000000000560e:  BB 0A 00          mov   bx, 0xa
0x0000000000005611:  89 F2             mov   dx, si
0x0000000000005613:  30 E4             xor   ah, ah
0x0000000000005615:  0E                push  cs
0x0000000000005616:  3E E8 8A D5       call  0x2ba4
0x000000000000561a:  85 C0             test  ax, ax
0x000000000000561c:  74 8A             je    0x55a8
0x000000000000561e:  6A 01             push  1
0x0000000000005620:  8A 5E FE          mov   bl, byte ptr [bp - 2]
0x0000000000005623:  8B 56 FA          mov   dx, word ptr [bp - 6]
0x0000000000005626:  89 F1             mov   cx, si
0x0000000000005628:  89 F8             mov   ax, di
0x000000000000562a:  30 FF             xor   bh, bh
0x000000000000562c:  E8 E1 F5          call  0x4c10
0x000000000000562f:  B0 01             mov   al, 1
0x0000000000005631:  C9                LEAVE_MACRO 
0x0000000000005632:  5F                pop   di
0x0000000000005633:  5E                pop   si
0x0000000000005634:  CB                retf  
0x0000000000005635:  8A 66 FE          mov   ah, byte ptr [bp - 2]
0x0000000000005638:  C6 46 FD 00       mov   byte ptr [bp - 3], 0
0x000000000000563c:  BB 06 00          mov   bx, 6
0x000000000000563f:  88 66 FC          mov   byte ptr [bp - 4], ah
0x0000000000005642:  89 D1             mov   cx, dx
0x0000000000005644:  8B 56 FC          mov   dx, word ptr [bp - 4]
0x0000000000005647:  30 E4             xor   ah, ah
0x0000000000005649:  E8 8C CD          call  0x23d8
0x000000000000564c:  85 C0             test  ax, ax
0x000000000000564e:  75 03             jne   0x5653
0x0000000000005650:  E9 AA F8          jmp   0x4efd
0x0000000000005653:  6A 01             push  1
0x0000000000005655:  8B 5E FC          mov   bx, word ptr [bp - 4]
0x0000000000005658:  8B 56 FA          mov   dx, word ptr [bp - 6]
0x000000000000565b:  89 F1             mov   cx, si
0x000000000000565d:  89 F8             mov   ax, di
0x000000000000565f:  E8 AE F5          call  0x4c10
0x0000000000005662:  B0 01             mov   al, 1
0x0000000000005664:  C9                LEAVE_MACRO 
0x0000000000005665:  5F                pop   di
0x0000000000005666:  5E                pop   si
0x0000000000005667:  CB                retf  
0x0000000000005668:  BB FF 00          mov   bx, 0xff
0x000000000000566b:  BA 01 00          mov   dx, 1
0x000000000000566e:  30 E4             xor   ah, ah
0x0000000000005670:  E8 5D E5          call  0x3bd0
0x0000000000005673:  89 F1             mov   cx, si
0x0000000000005675:  6A 01             push  1
0x0000000000005677:  8A 5E FE          mov   bl, byte ptr [bp - 2]
0x000000000000567a:  8B 56 FA          mov   dx, word ptr [bp - 6]
0x000000000000567d:  89 F8             mov   ax, di
0x000000000000567f:  30 FF             xor   bh, bh
0x0000000000005681:  E8 8C F5          call  0x4c10
0x0000000000005684:  B0 01             mov   al, 1
0x0000000000005686:  C9                LEAVE_MACRO 
0x0000000000005687:  5F                pop   di
0x0000000000005688:  5E                pop   si
0x0000000000005689:  CB                retf  
0x000000000000568a:  BB 23 00          mov   bx, 0x23
0x000000000000568d:  BA 01 00          mov   dx, 1
0x0000000000005690:  30 E4             xor   ah, ah
0x0000000000005692:  E8 3B E5          call  0x3bd0
0x0000000000005695:  89 F1             mov   cx, si
0x0000000000005697:  6A 01             push  1
0x0000000000005699:  8A 5E FE          mov   bl, byte ptr [bp - 2]
0x000000000000569c:  8B 56 FA          mov   dx, word ptr [bp - 6]
0x000000000000569f:  89 F8             mov   ax, di
0x00000000000056a1:  30 FF             xor   bh, bh
0x00000000000056a3:  E8 6A F5          call  0x4c10
0x00000000000056a6:  B0 01             mov   al, 1
0x00000000000056a8:  C9                LEAVE_MACRO 
0x00000000000056a9:  5F                pop   di
0x00000000000056aa:  5E                pop   si
0x00000000000056ab:  CB                retf  






ENDP
@

PROC    P_SWITCH_ENDMARKER_ 
PUBLIC  P_SWITCH_ENDMARKER_
ENDP


END
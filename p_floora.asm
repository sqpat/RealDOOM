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
EXTRN _P_ChangeSector:DWORD

SHORTFLOORBITS = 3

.DATA




.CODE



PROC    P_FLOOR_STARTMARKER_ NEAR
PUBLIC  P_FLOOR_STARTMARKER_
ENDP

PROC    T_MovePlaneCeilingDown_ NEAR
PUBLIC  T_MovePlaneCeilingDown_

;result_e __near T_MovePlaneCeilingDown ( uint16_t sector_offset, short_height_t	speed, short_height_t	dest, boolean	crush ) {


push  si
push  di
push  bp
mov   bp, sp
sub   sp, 4
mov   si, ax
mov   ax, bx
mov   word ptr [bp - 2], SECTORS_SEGMENT
mov   es, word ptr [bp - 2]
mov   di, word ptr es:[si + 2]
sub   di, dx
cmp   di, bx
jge   label_1
mov   dx, SECTORS_SEGMENT
mov   al, cl
mov   di, word ptr es:[si + 2]
cbw  
mov   word ptr es:[si + 2], bx
mov   cx, ax
mov   bx, ax
mov   ax, si
call  dword ptr ds:[_P_ChangeSector]
test  al, al
je    exit_moveplaneceilingdown_return_floorpastdest
mov   es, word ptr [bp - 2]
mov   dx, SECTORS_SEGMENT
mov   bx, cx
mov   ax, si
mov   word ptr es:[si + 2], di
call  dword ptr ds:[_P_ChangeSector]
exit_moveplaneceilingdown_return_floorpastdest:
mov   al, FLOOR_PASTDEST
exit_moveplaneceilingdown:
LEAVE_MACRO 
pop   di
pop   si
ret   
label_1:
mov   ax, word ptr es:[si + 2]
mov   word ptr [bp - 4], ax
sub   ax, dx
mov   word ptr es:[si + 2], ax
mov   al, cl
cbw  
mov   dx, SECTORS_SEGMENT
mov   di, ax
mov   bx, ax
mov   ax, si
call  dword ptr ds:[_P_ChangeSector]
test  al, al
je    exit_moveplaneceilingdown
cmp   cl, 1
jne   label_2
mov   al, cl
LEAVE_MACRO 
pop   di
pop   si
ret   
label_2:
les   ax, dword ptr [bp - 4]
mov   dx, SECTORS_SEGMENT
mov   bx, di
mov   word ptr es:[si + 2], ax
mov   ax, si
call  dword ptr ds:[_P_ChangeSector]
mov   al, FLOOR_CRUSHED
LEAVE_MACRO 
pop   di
pop   si
ret   

ENDP

COMMENT @


PROC    T_MovePlaneCeilingUp_ NEAR
PUBLIC  T_MovePlaneCeilingUp_



0x0000000000002846:  56                push  si
0x0000000000002847:  57                push  di
0x0000000000002848:  55                push  bp
0x0000000000002849:  89 E5             mov   bp, sp
0x000000000000284b:  83 EC 02          sub   sp, 2
0x000000000000284e:  89 C6             mov   si, ax
0x0000000000002850:  88 C8             mov   al, cl
0x0000000000002852:  C7 46 FE 90 21    mov   word ptr [bp - 2], SECTORS_SEGMENT
0x0000000000002857:  8E 46 FE          mov   es, word ptr [bp - 2]
0x000000000000285a:  26 8B 4C 02       mov   cx, word ptr es:[si + 2]
0x000000000000285e:  01 D1             add   cx, dx
0x0000000000002860:  39 D9             cmp   cx, bx
0x0000000000002862:  7E 32             jle   0x2896
0x0000000000002864:  BA 90 21          mov   dx, SECTORS_SEGMENT
0x0000000000002867:  98                cbw  
0x0000000000002868:  26 8B 7C 02       mov   di, word ptr es:[si + 2]
0x000000000000286c:  89 C1             mov   cx, ax
0x000000000000286e:  26 89 5C 02       mov   word ptr es:[si + 2], bx
0x0000000000002872:  89 C3             mov   bx, ax
0x0000000000002874:  89 F0             mov   ax, si
0x0000000000002876:  FF 1E 60 0F       call  dword ptr ds:[_P_ChangeSector]
0x000000000000287a:  84 C0             test  al, al
0x000000000000287c:  74 12             je    0x2890
0x000000000000287e:  8E 46 FE          mov   es, word ptr [bp - 2]
0x0000000000002881:  BA 90 21          mov   dx, SECTORS_SEGMENT
0x0000000000002884:  89 CB             mov   bx, cx
0x0000000000002886:  89 F0             mov   ax, si
0x0000000000002888:  26 89 7C 02       mov   word ptr es:[si + 2], di
0x000000000000288c:  FF 1E 60 0F       call  dword ptr ds:[_P_ChangeSector]
0x0000000000002890:  B0 02             mov   al, 2
0x0000000000002892:  C9                LEAVE_MACRO 
0x0000000000002893:  5F                pop   di
0x0000000000002894:  5E                pop   si
0x0000000000002895:  C3                ret   
0x0000000000002896:  26 8B 5C 02       mov   bx, word ptr es:[si + 2]
0x000000000000289a:  98                cbw  
0x000000000000289b:  01 D3             add   bx, dx
0x000000000000289d:  BA 90 21          mov   dx, SECTORS_SEGMENT
0x00000000000028a0:  26 89 5C 02       mov   word ptr es:[si + 2], bx
0x00000000000028a4:  89 C3             mov   bx, ax
0x00000000000028a6:  89 F0             mov   ax, si
0x00000000000028a8:  FF 1E 60 0F       call  dword ptr ds:[_P_ChangeSector]
0x00000000000028ac:  30 C0             xor   al, al
0x00000000000028ae:  C9                LEAVE_MACRO 
0x00000000000028af:  5F                pop   di
0x00000000000028b0:  5E                pop   si
0x00000000000028b1:  C3                ret   

ENDP

PROC    T_MovePlaneFloorDown_ NEAR
PUBLIC  T_MovePlaneFloorDown_



0x00000000000028b2:  56                push  si
0x00000000000028b3:  57                push  di
0x00000000000028b4:  55                push  bp
0x00000000000028b5:  89 E5             mov   bp, sp
0x00000000000028b7:  83 EC 02          sub   sp, 2
0x00000000000028ba:  89 C6             mov   si, ax
0x00000000000028bc:  88 C8             mov   al, cl
0x00000000000028be:  C7 46 FE 90 21    mov   word ptr [bp - 2], SECTORS_SEGMENT
0x00000000000028c3:  8E 46 FE          mov   es, word ptr [bp - 2]
0x00000000000028c6:  26 8B 0C          mov   cx, word ptr es:[si]
0x00000000000028c9:  29 D1             sub   cx, dx
0x00000000000028cb:  39 D9             cmp   cx, bx
0x00000000000028cd:  7D 2F             jge   0x28fe
0x00000000000028cf:  BA 90 21          mov   dx, SECTORS_SEGMENT
0x00000000000028d2:  98                cbw  
0x00000000000028d3:  26 8B 3C          mov   di, word ptr es:[si]
0x00000000000028d6:  89 C1             mov   cx, ax
0x00000000000028d8:  26 89 1C          mov   word ptr es:[si], bx
0x00000000000028db:  89 C3             mov   bx, ax
0x00000000000028dd:  89 F0             mov   ax, si
0x00000000000028df:  FF 1E 60 0F       call  dword ptr ds:[_P_ChangeSector]
0x00000000000028e3:  84 C0             test  al, al
0x00000000000028e5:  74 11             je    0x28f8
0x00000000000028e7:  8E 46 FE          mov   es, word ptr [bp - 2]
0x00000000000028ea:  BA 90 21          mov   dx, SECTORS_SEGMENT
0x00000000000028ed:  89 CB             mov   bx, cx
0x00000000000028ef:  89 F0             mov   ax, si
0x00000000000028f1:  26 89 3C          mov   word ptr es:[si], di
0x00000000000028f4:  FF 1E 60 0F       call  dword ptr ds:[_P_ChangeSector]
0x00000000000028f8:  B0 02             mov   al, 2
0x00000000000028fa:  C9                LEAVE_MACRO 
0x00000000000028fb:  5F                pop   di
0x00000000000028fc:  5E                pop   si
0x00000000000028fd:  C3                ret   
0x00000000000028fe:  26 8B 3C          mov   di, word ptr es:[si]
0x0000000000002901:  98                cbw  
0x0000000000002902:  89 FB             mov   bx, di
0x0000000000002904:  89 C1             mov   cx, ax
0x0000000000002906:  29 D3             sub   bx, dx
0x0000000000002908:  BA 90 21          mov   dx, SECTORS_SEGMENT
0x000000000000290b:  26 89 1C          mov   word ptr es:[si], bx
0x000000000000290e:  89 C3             mov   bx, ax
0x0000000000002910:  89 F0             mov   ax, si
0x0000000000002912:  FF 1E 60 0F       call  dword ptr ds:[_P_ChangeSector]
0x0000000000002916:  84 C0             test  al, al
0x0000000000002918:  74 E0             je    0x28fa
0x000000000000291a:  8E 46 FE          mov   es, word ptr [bp - 2]
0x000000000000291d:  BA 90 21          mov   dx, SECTORS_SEGMENT
0x0000000000002920:  89 CB             mov   bx, cx
0x0000000000002922:  89 F0             mov   ax, si
0x0000000000002924:  26 89 3C          mov   word ptr es:[si], di
0x0000000000002927:  FF 1E 60 0F       call  dword ptr ds:[_P_ChangeSector]
0x000000000000292b:  B0 01             mov   al, 1
0x000000000000292d:  C9                LEAVE_MACRO 
0x000000000000292e:  5F                pop   di
0x000000000000292f:  5E                pop   si
0x0000000000002930:  C3                ret   


ENDP

PROC    T_MovePlaneFloorUp_ NEAR
PUBLIC  T_MovePlaneFloorUp_


0x0000000000002932:  56                push  si
0x0000000000002933:  57                push  di
0x0000000000002934:  55                push  bp
0x0000000000002935:  89 E5             mov   bp, sp
0x0000000000002937:  83 EC 04          sub   sp, 4
0x000000000000293a:  89 C6             mov   si, ax
0x000000000000293c:  89 D8             mov   ax, bx
0x000000000000293e:  C7 46 FE 90 21    mov   word ptr [bp - 2], SECTORS_SEGMENT
0x0000000000002943:  8E 46 FE          mov   es, word ptr [bp - 2]
0x0000000000002946:  26 8B 3C          mov   di, word ptr es:[si]
0x0000000000002949:  01 D7             add   di, dx
0x000000000000294b:  39 DF             cmp   di, bx
0x000000000000294d:  7E 31             jle   0x2980
0x000000000000294f:  BA 90 21          mov   dx, SECTORS_SEGMENT
0x0000000000002952:  88 C8             mov   al, cl
0x0000000000002954:  26 8B 3C          mov   di, word ptr es:[si]
0x0000000000002957:  98                cbw  
0x0000000000002958:  26 89 1C          mov   word ptr es:[si], bx
0x000000000000295b:  89 C1             mov   cx, ax
0x000000000000295d:  89 C3             mov   bx, ax
0x000000000000295f:  89 F0             mov   ax, si
0x0000000000002961:  FF 1E 60 0F       call  dword ptr ds:[_P_ChangeSector]
0x0000000000002965:  84 C0             test  al, al
0x0000000000002967:  74 11             je    0x297a
0x0000000000002969:  8E 46 FE          mov   es, word ptr [bp - 2]
0x000000000000296c:  BA 90 21          mov   dx, SECTORS_SEGMENT
0x000000000000296f:  89 CB             mov   bx, cx
0x0000000000002971:  89 F0             mov   ax, si
0x0000000000002973:  26 89 3C          mov   word ptr es:[si], di
0x0000000000002976:  FF 1E 60 0F       call  dword ptr ds:[_P_ChangeSector]
0x000000000000297a:  B0 02             mov   al, 2
0x000000000000297c:  C9                LEAVE_MACRO 
0x000000000000297d:  5F                pop   di
0x000000000000297e:  5E                pop   si
0x000000000000297f:  C3                ret   
0x0000000000002980:  26 8B 04          mov   ax, word ptr es:[si]
0x0000000000002983:  89 46 FC          mov   word ptr [bp - 4], ax
0x0000000000002986:  01 D0             add   ax, dx
0x0000000000002988:  26 89 04          mov   word ptr es:[si], ax
0x000000000000298b:  88 C8             mov   al, cl
0x000000000000298d:  98                cbw  
0x000000000000298e:  BA 90 21          mov   dx, SECTORS_SEGMENT
0x0000000000002991:  89 C7             mov   di, ax
0x0000000000002993:  89 C3             mov   bx, ax
0x0000000000002995:  89 F0             mov   ax, si
0x0000000000002997:  FF 1E 60 0F       call  dword ptr ds:[_P_ChangeSector]
0x000000000000299b:  84 C0             test  al, al
0x000000000000299d:  74 DD             je    0x297c
0x000000000000299f:  80 F9 01          cmp   cl, 1
0x00000000000029a2:  75 06             jne   0x29aa
0x00000000000029a4:  88 C8             mov   al, cl
0x00000000000029a6:  C9                LEAVE_MACRO 
0x00000000000029a7:  5F                pop   di
0x00000000000029a8:  5E                pop   si
0x00000000000029a9:  C3                ret   
0x00000000000029aa:  C4 46 FC          les   ax, dword ptr [bp - 4]
0x00000000000029ad:  BA 90 21          mov   dx, SECTORS_SEGMENT
0x00000000000029b0:  89 FB             mov   bx, di
0x00000000000029b2:  26 89 04          mov   word ptr es:[si], ax
0x00000000000029b5:  89 F0             mov   ax, si
0x00000000000029b7:  FF 1E 60 0F       call  dword ptr ds:[_P_ChangeSector]
0x00000000000029bb:  B0 01             mov   al, 1
0x00000000000029bd:  C9                LEAVE_MACRO 
0x00000000000029be:  5F                pop   di
0x00000000000029bf:  5E                pop   si
0x00000000000029c0:  C3                ret   



ENDP

PROC    T_MoveFloor_ NEAR
PUBLIC  T_MoveFloor_


0x00000000000029c2:  53                push  bx
0x00000000000029c3:  51                push  cx
0x00000000000029c4:  56                push  si
0x00000000000029c5:  57                push  di
0x00000000000029c6:  55                push  bp
0x00000000000029c7:  89 E5             mov   bp, sp
0x00000000000029c9:  83 EC 08          sub   sp, 8
0x00000000000029cc:  89 C6             mov   si, ax
0x00000000000029ce:  89 56 FC          mov   word ptr [bp - 4], dx
0x00000000000029d1:  8B 7C 02          mov   di, word ptr ds:[si + 2]
0x00000000000029d4:  89 F8             mov   ax, di
0x00000000000029d6:  C1 E0 04          shl   ax, 4
0x00000000000029d9:  89 46 FE          mov   word ptr [bp - 2], ax
0x00000000000029dc:  8A 44 04          mov   al, byte ptr ds:[si + 4]
0x00000000000029df:  3C 01             cmp   al, 1
0x00000000000029e1:  75 03             jne   0x29e6
0x00000000000029e3:  E9 89 00          jmp   0x2a6f
0x00000000000029e6:  3C FF             cmp   al, 0xff
0x00000000000029e8:  74 03             je    0x29ed
0x00000000000029ea:  E9 97 00          jmp   0x2a84
0x00000000000029ed:  8A 44 01          mov   al, byte ptr ds:[si + 1]
0x00000000000029f0:  8B 5C 07          mov   bx, word ptr ds:[si + 7]
0x00000000000029f3:  98                cbw  
0x00000000000029f4:  8B 54 09          mov   dx, word ptr ds:[si + 9]
0x00000000000029f7:  89 C1             mov   cx, ax
0x00000000000029f9:  8B 46 FE          mov   ax, word ptr [bp - 2]
0x00000000000029fc:  E8 B3 FE          call  0x28b2
0x00000000000029ff:  88 C1             mov   cl, al
0x0000000000002a01:  BB 1C 07          mov   bx, 0x71c
0x0000000000002a04:  F6 07 07          test  byte ptr ds:[bx], 7
0x0000000000002a07:  75 0A             jne   0x2a13
0x0000000000002a09:  BA 16 00          mov   dx, 0x16
0x0000000000002a0c:  89 F8             mov   ax, di
0x0000000000002a0e:  0E                push  cs
0x0000000000002a0f:  E8 50 DB          call  0x562
0x0000000000002a12:  90                nop   
0x0000000000002a13:  80 F9 02          cmp   cl, 2
0x0000000000002a16:  75 51             jne   0x2a69
0x0000000000002a18:  8A 74 05          mov   dh, byte ptr ds:[si + 5]
0x0000000000002a1b:  8A 44 04          mov   al, byte ptr ds:[si + 4]
0x0000000000002a1e:  8A 4C 06          mov   cl, byte ptr ds:[si + 6]
0x0000000000002a21:  8A 14             mov   dl, byte ptr ds:[si]
0x0000000000002a23:  89 FE             mov   si, di
0x0000000000002a25:  C1 E6 04          shl   si, 4
0x0000000000002a28:  89 76 F8          mov   word ptr [bp - 8], si
0x0000000000002a2b:  8D 9C 38 DE       lea   bx, [si - 0x21c8]
0x0000000000002a2f:  C7 46 FA 00 00    mov   word ptr [bp - 6], 0
0x0000000000002a34:  C7 07 00 00       mov   word ptr ds:[bx], 0
0x0000000000002a38:  BB 90 21          mov   bx, SECTORS_SEGMENT
0x0000000000002a3b:  98                cbw  
0x0000000000002a3c:  8E C3             mov   es, bx
0x0000000000002a3e:  8B 5E F8          mov   bx, word ptr [bp - 8]
0x0000000000002a41:  83 C6 04          add   si, 4
0x0000000000002a44:  81 C3 3E DE       add   bx, 0xde3e
0x0000000000002a48:  3D 01 00          cmp   ax, 1
0x0000000000002a4b:  75 3C             jne   0x2a89
0x0000000000002a4d:  80 FA 0B          cmp   dl, 0xb
0x0000000000002a50:  75 05             jne   0x2a57
0x0000000000002a52:  88 37             mov   byte ptr ds:[bx], dh
0x0000000000002a54:  26 88 0C          mov   byte ptr es:[si], cl
0x0000000000002a57:  8B 46 FC          mov   ax, word ptr [bp - 4]
0x0000000000002a5a:  BA 13 00          mov   dx, 0x13
0x0000000000002a5d:  0E                push  cs
0x0000000000002a5e:  3E E8 20 26       call  0x5082
0x0000000000002a62:  89 F8             mov   ax, di
0x0000000000002a64:  0E                push  cs
0x0000000000002a65:  E8 FA DA          call  0x562
0x0000000000002a68:  90                nop   
0x0000000000002a69:  C9                LEAVE_MACRO 
0x0000000000002a6a:  5F                pop   di
0x0000000000002a6b:  5E                pop   si
0x0000000000002a6c:  59                pop   cx
0x0000000000002a6d:  5B                pop   bx
0x0000000000002a6e:  C3                ret   
0x0000000000002a6f:  8A 44 01          mov   al, byte ptr ds:[si + 1]
0x0000000000002a72:  8B 5C 07          mov   bx, word ptr ds:[si + 7]
0x0000000000002a75:  98                cbw  
0x0000000000002a76:  8B 54 09          mov   dx, word ptr ds:[si + 9]
0x0000000000002a79:  89 C1             mov   cx, ax
0x0000000000002a7b:  8B 46 FE          mov   ax, word ptr [bp - 2]
0x0000000000002a7e:  E8 B1 FE          call  0x2932
0x0000000000002a81:  E9 7B FF          jmp   0x29ff
0x0000000000002a84:  30 C9             xor   cl, cl
0x0000000000002a86:  E9 78 FF          jmp   0x2a01
0x0000000000002a89:  3D FF FF          cmp   ax, 0xffff
0x0000000000002a8c:  75 C9             jne   0x2a57
0x0000000000002a8e:  80 FA 06          cmp   dl, 6
0x0000000000002a91:  EB BD             jmp   0x2a50


2B51 2B7D 2B8C 2bB2 2C07 2CB3 2D73 2C1E 2C65 2BAE 2BF0 2B68 2C42 
0x0000000000002a94:  51                push  cx
0x0000000000002a95:  2B 7D 2B          sub   di, word ptr ds:[di + 0x2b]
0x0000000000002a98:  8C 2B             mov   word ptr [bp + di], gs
0x0000000000002a9a:  B2 2B             mov   dl, 0x2b
0x0000000000002a9c:  07                pop   es
0x0000000000002a9d:  2C B3             sub   al, 0xb3
0x0000000000002a9f:  2C 73             sub   al, 0x73
0x0000000000002aa1:  2D 1E 2C          sub   ax, 0x2c1e
0x0000000000002aa4:  65 2C AE          sub   al, 0xae
0x0000000000002aa7:  2B F0             sub   si, ax
0x0000000000002aa9:  2B 68 2B          sub   bp, word ptr ds:[bx + si + 0x2b]
0x0000000000002aac:  42                inc   dx
0x0000000000002aad:  2C 




ENDP

PROC    EV_DoFloor_ NEAR
PUBLIC  EV_DoFloor_


0x0000000000002aae:  51                push  cx
0x0000000000002aaf:  56                push  si
0x0000000000002ab0:  57                push  di
0x0000000000002ab1:  55                push  bp
0x0000000000002ab2:  89 E5             mov   bp, sp
0x0000000000002ab4:  81 EC 20 02       sub   sp, 0x220
0x0000000000002ab8:  89 D1             mov   cx, dx
0x0000000000002aba:  88 5E FE          mov   byte ptr [bp - 2], bl
0x0000000000002abd:  C7 46 E4 00 00    mov   word ptr [bp - 0x1c], 0
0x0000000000002ac2:  8D 96 E0 FD       lea   dx, [bp - 0x220]
0x0000000000002ac6:  C7 46 F6 00 00    mov   word ptr [bp - 0xa], 0
0x0000000000002acb:  98                cbw  
0x0000000000002acc:  31 DB             xor   bx, bx
0x0000000000002ace:  C1 E1 04          shl   cx, 4
0x0000000000002ad1:  E8 78 17          call  0x424c
0x0000000000002ad4:  89 4E E8          mov   word ptr [bp - 0x18], cx
0x0000000000002ad7:  83 BE E0 FD 00    cmp   word ptr [bp - 0x220], 0
0x0000000000002adc:  7C 71             jl    0x2b4f
0x0000000000002ade:  8B 76 F6          mov   si, word ptr [bp - 0xa]
0x0000000000002ae1:  8B 8A E0 FD       mov   cx, word ptr [bp + si - 0x220]
0x0000000000002ae5:  89 C8             mov   ax, cx
0x0000000000002ae7:  C7 46 FC 90 21    mov   word ptr [bp - 4], SECTORS_SEGMENT
0x0000000000002aec:  C1 E0 04          shl   ax, 4
0x0000000000002aef:  8E 46 FC          mov   es, word ptr [bp - 4]
0x0000000000002af2:  89 46 FA          mov   word ptr [bp - 6], ax
0x0000000000002af5:  05 30 DE          add   ax, 0xde30
0x0000000000002af8:  8B 5E FA          mov   bx, word ptr [bp - 6]
0x0000000000002afb:  89 46 F2          mov   word ptr [bp - 0xe], ax
0x0000000000002afe:  26 8B 47 0C       mov   ax, word ptr es:[bx + 0xc]
0x0000000000002b02:  89 46 E6          mov   word ptr [bp - 0x1a], ax
0x0000000000002b05:  26 8B 47 02       mov   ax, word ptr es:[bx + 2]
0x0000000000002b09:  89 46 EA          mov   word ptr [bp - 0x16], ax
0x0000000000002b0c:  26 8B 07          mov   ax, word ptr es:[bx]
0x0000000000002b0f:  BF 2C 00          mov   di, 0x2c
0x0000000000002b12:  89 46 F4          mov   word ptr [bp - 0xc], ax
0x0000000000002b15:  B8 00 28          mov   ax, 0x2800
0x0000000000002b18:  31 D2             xor   dx, dx
0x0000000000002b1a:  0E                push  cs
0x0000000000002b1b:  E8 CE 24          call  0x4fec
0x0000000000002b1e:  90                nop   
0x0000000000002b1f:  89 C3             mov   bx, ax
0x0000000000002b21:  89 C6             mov   si, ax
0x0000000000002b23:  2D 04 34          sub   ax, 0x3404
0x0000000000002b26:  F7 F7             div   di
0x0000000000002b28:  8B 7E F2          mov   di, word ptr [bp - 0xe]
0x0000000000002b2b:  C7 46 E4 01 00    mov   word ptr [bp - 0x1c], 1
0x0000000000002b30:  89 45 08          mov   word ptr ds:[di + 8], ax
0x0000000000002b33:  8A 46 FE          mov   al, byte ptr [bp - 2]
0x0000000000002b36:  C6 47 01 00       mov   byte ptr ds:[bx + 1], 0
0x0000000000002b3a:  83 46 F6 02       add   word ptr [bp - 0xa], 2
0x0000000000002b3e:  88 07             mov   byte ptr ds:[bx], al
0x0000000000002b40:  3C 0C             cmp   al, 0xc
0x0000000000002b42:  77 24             ja    0x2b68
0x0000000000002b44:  30 E4             xor   ah, ah
0x0000000000002b46:  89 C7             mov   di, ax
0x0000000000002b48:  01 C7             add   di, ax
0x0000000000002b4a:  2E FF A5 94 2A    jmp   word ptr cs:[di + 0x2a94]
0x0000000000002b4f:  EB 24             jmp   0x2b75
0x0000000000002b51:  C6 47 04 FF       mov   byte ptr ds:[bx + 4], 0xff
0x0000000000002b55:  BA 01 00          mov   dx, 1
0x0000000000002b58:  C7 47 09 08 00    mov   word ptr ds:[bx + 9], 8
0x0000000000002b5d:  89 C8             mov   ax, cx
0x0000000000002b5f:  89 4F 02          mov   word ptr ds:[bx + 2], cx
0x0000000000002b62:  E8 8A 15          call  0x40ef
0x0000000000002b65:  89 47 07          mov   word ptr ds:[bx + 7], ax
0x0000000000002b68:  8B 76 F6          mov   si, word ptr [bp - 0xa]
0x0000000000002b6b:  83 BA E0 FD 00    cmp   word ptr [bp + si - 0x220], 0
0x0000000000002b70:  7C 03             jl    0x2b75
0x0000000000002b72:  E9 69 FF          jmp   0x2ade
0x0000000000002b75:  8B 46 E4          mov   ax, word ptr [bp - 0x1c]
0x0000000000002b78:  C9                LEAVE_MACRO 
0x0000000000002b79:  5F                pop   di
0x0000000000002b7a:  5E                pop   si
0x0000000000002b7b:  59                pop   cx
0x0000000000002b7c:  CB                retf  
0x0000000000002b7d:  C6 47 04 FF       mov   byte ptr ds:[bx + 4], 0xff
0x0000000000002b81:  89 C8             mov   ax, cx
0x0000000000002b83:  C7 47 09 08 00    mov   word ptr ds:[bx + 9], 8
0x0000000000002b88:  31 D2             xor   dx, dx
0x0000000000002b8a:  EB D3             jmp   0x2b5f
0x0000000000002b8c:  C6 47 04 FF       mov   byte ptr ds:[bx + 4], 0xff
0x0000000000002b90:  BA 01 00          mov   dx, 1
0x0000000000002b93:  C7 47 09 20 00    mov   word ptr ds:[bx + 9], 0x20
0x0000000000002b98:  89 C8             mov   ax, cx
0x0000000000002b9a:  89 4F 02          mov   word ptr ds:[bx + 2], cx
0x0000000000002b9d:  E8 4F 15          call  0x40ef
0x0000000000002ba0:  89 47 07          mov   word ptr ds:[bx + 7], ax
0x0000000000002ba3:  3B 46 F4          cmp   ax, word ptr [bp - 0xc]
0x0000000000002ba6:  74 C0             je    0x2b68
0x0000000000002ba8:  83 47 07 40       add   word ptr ds:[bx + 7], 0x40
0x0000000000002bac:  EB BA             jmp   0x2b68
0x0000000000002bae:  C6 47 01 01       mov   byte ptr ds:[bx + 1], 1
0x0000000000002bb2:  C6 44 04 01       mov   byte ptr ds:[si + 4], 1
0x0000000000002bb6:  89 C8             mov   ax, cx
0x0000000000002bb8:  C7 44 09 08 00    mov   word ptr ds:[si + 9], 8
0x0000000000002bbd:  31 D2             xor   dx, dx
0x0000000000002bbf:  89 4C 02          mov   word ptr ds:[si + 2], cx
0x0000000000002bc2:  E8 11 16          call  0x41d6
0x0000000000002bc5:  89 44 07          mov   word ptr ds:[si + 7], ax
0x0000000000002bc8:  3B 46 EA          cmp   ax, word ptr [bp - 0x16]
0x0000000000002bcb:  7E 06             jle   0x2bd3
0x0000000000002bcd:  8B 46 EA          mov   ax, word ptr [bp - 0x16]
0x0000000000002bd0:  89 44 07          mov   word ptr ds:[si + 7], ax
0x0000000000002bd3:  83 C6 07          add   si, 7
0x0000000000002bd6:  80 7E FE 09       cmp   byte ptr [bp - 2], 9
0x0000000000002bda:  75 0A             jne   0x2be6
0x0000000000002bdc:  BB 01 00          mov   bx, 1
0x0000000000002bdf:  C1 E3 06          shl   bx, 6
0x0000000000002be2:  29 1C             sub   word ptr ds:[si], bx
0x0000000000002be4:  EB 82             jmp   0x2b68
0x0000000000002be6:  31 DB             xor   bx, bx
0x0000000000002be8:  C1 E3 06          shl   bx, 6
0x0000000000002beb:  29 1C             sub   word ptr ds:[si], bx
0x0000000000002bed:  E9 78 FF          jmp   0x2b68
0x0000000000002bf0:  C6 47 04 01       mov   byte ptr ds:[bx + 4], 1
0x0000000000002bf4:  8B 56 F4          mov   dx, word ptr [bp - 0xc]
0x0000000000002bf7:  C7 47 09 20 00    mov   word ptr ds:[bx + 9], 0x20
0x0000000000002bfc:  89 C8             mov   ax, cx
0x0000000000002bfe:  89 4F 02          mov   word ptr ds:[bx + 2], cx
0x0000000000002c01:  E8 61 15          call  0x4165
0x0000000000002c04:  E9 5E FF          jmp   0x2b65
0x0000000000002c07:  C6 47 04 01       mov   byte ptr ds:[bx + 4], 1
0x0000000000002c0b:  8B 56 F4          mov   dx, word ptr [bp - 0xc]
0x0000000000002c0e:  C7 47 09 08 00    mov   word ptr ds:[bx + 9], 8
0x0000000000002c13:  89 C8             mov   ax, cx
0x0000000000002c15:  89 4F 02          mov   word ptr ds:[bx + 2], cx
0x0000000000002c18:  E8 4A 15          call  0x4165
0x0000000000002c1b:  E9 47 FF          jmp   0x2b65
0x0000000000002c1e:  C6 47 04 01       mov   byte ptr ds:[bx + 4], 1
0x0000000000002c22:  89 4F 02          mov   word ptr ds:[bx + 2], cx
0x0000000000002c25:  B8 90 21          mov   ax, SECTORS_SEGMENT
0x0000000000002c28:  8B 77 02          mov   si, word ptr ds:[bx + 2]
0x0000000000002c2b:  C7 47 09 08 00    mov   word ptr ds:[bx + 9], 8
0x0000000000002c30:  C1 E6 04          shl   si, 4
0x0000000000002c33:  8E C0             mov   es, ax
0x0000000000002c35:  26 8B 0C          mov   cx, word ptr es:[si]
0x0000000000002c38:  81 C1 C0 00       add   cx, 0xc0
0x0000000000002c3c:  89 4F 07          mov   word ptr ds:[bx + 7], cx
0x0000000000002c3f:  E9 26 FF          jmp   0x2b68
0x0000000000002c42:  C6 47 04 01       mov   byte ptr ds:[bx + 4], 1
0x0000000000002c46:  89 4F 02          mov   word ptr ds:[bx + 2], cx
0x0000000000002c49:  B8 90 21          mov   ax, SECTORS_SEGMENT
0x0000000000002c4c:  8B 77 02          mov   si, word ptr ds:[bx + 2]
0x0000000000002c4f:  C7 47 09 08 00    mov   word ptr ds:[bx + 9], 8
0x0000000000002c54:  C1 E6 04          shl   si, 4
0x0000000000002c57:  8E C0             mov   es, ax
0x0000000000002c59:  26 8B 0C          mov   cx, word ptr es:[si]
0x0000000000002c5c:  80 C5 10          add   ch, 0x10
0x0000000000002c5f:  89 4F 07          mov   word ptr ds:[bx + 7], cx
0x0000000000002c62:  E9 03 FF          jmp   0x2b68
0x0000000000002c65:  C6 47 04 01       mov   byte ptr ds:[bx + 4], 1
0x0000000000002c69:  89 4F 02          mov   word ptr ds:[bx + 2], cx
0x0000000000002c6c:  B8 90 21          mov   ax, SECTORS_SEGMENT
0x0000000000002c6f:  8B 77 02          mov   si, word ptr ds:[bx + 2]
0x0000000000002c72:  C7 47 09 08 00    mov   word ptr ds:[bx + 9], 8
0x0000000000002c77:  C1 E6 04          shl   si, 4
0x0000000000002c7a:  8E C0             mov   es, ax
0x0000000000002c7c:  26 8B 0C          mov   cx, word ptr es:[si]
0x0000000000002c7f:  81 C1 C0 00       add   cx, 0xc0
0x0000000000002c83:  8B 46 E8          mov   ax, word ptr [bp - 0x18]
0x0000000000002c86:  89 4F 07          mov   word ptr ds:[bx + 7], cx
0x0000000000002c89:  89 C3             mov   bx, ax
0x0000000000002c8b:  89 46 E0          mov   word ptr [bp - 0x20], ax
0x0000000000002c8e:  26 8A 47 04       mov   al, byte ptr es:[bx + 4]
0x0000000000002c92:  83 C3 04          add   bx, 4
0x0000000000002c95:  C4 5E FA          les   bx, dword ptr [bp - 6]
0x0000000000002c98:  C7 46 E2 00 00    mov   word ptr [bp - 0x1e], 0
0x0000000000002c9d:  26 88 47 04       mov   byte ptr es:[bx + 4], al
0x0000000000002ca1:  8B 5E E0          mov   bx, word ptr [bp - 0x20]
0x0000000000002ca4:  81 C3 3E DE       add   bx, 0xde3e
0x0000000000002ca8:  8A 07             mov   al, byte ptr ds:[bx]
0x0000000000002caa:  8B 5E F2          mov   bx, word ptr [bp - 0xe]
0x0000000000002cad:  88 47 0E          mov   byte ptr ds:[bx + 0xe], al
0x0000000000002cb0:  E9 B5 FE          jmp   0x2b68
0x0000000000002cb3:  C6 47 04 01       mov   byte ptr ds:[bx + 4], 1
0x0000000000002cb7:  C7 46 F8 FF 7F    mov   word ptr [bp - 8], 0x7fff
0x0000000000002cbc:  C7 47 09 08 00    mov   word ptr ds:[bx + 9], 8
0x0000000000002cc1:  8B 7E FA          mov   di, word ptr [bp - 6]
0x0000000000002cc4:  89 4F 02          mov   word ptr ds:[bx + 2], cx
0x0000000000002cc7:  8E 46 FC          mov   es, word ptr [bp - 4]
0x0000000000002cca:  31 DB             xor   bx, bx
0x0000000000002ccc:  26 83 7D 0A 00    cmp   word ptr es:[di + 0xa], 0
0x0000000000002cd1:  7F 03             jg    0x2cd6
0x0000000000002cd3:  E9 81 00          jmp   0x2d57
0x0000000000002cd6:  8B 46 E6          mov   ax, word ptr [bp - 0x1a]
0x0000000000002cd9:  01 C0             add   ax, ax
0x0000000000002cdb:  89 46 EE          mov   word ptr [bp - 0x12], ax
0x0000000000002cde:  89 DA             mov   dx, bx
0x0000000000002ce0:  89 C8             mov   ax, cx
0x0000000000002ce2:  E8 91 13          call  0x4076
0x0000000000002ce5:  85 C0             test  ax, ax
0x0000000000002ce7:  74 60             je    0x2d49
0x0000000000002ce9:  8B 46 EE          mov   ax, word ptr [bp - 0x12]
0x0000000000002cec:  89 C7             mov   di, ax
0x0000000000002cee:  81 C7 50 CA       add   di, 0xca50
0x0000000000002cf2:  8B 3D             mov   di, word ptr ds:[di]
0x0000000000002cf4:  B8 91 29          mov   ax, 0x2991
0x0000000000002cf7:  C1 E7 02          shl   di, 2
0x0000000000002cfa:  8E C0             mov   es, ax
0x0000000000002cfc:  26 8B 05          mov   ax, word ptr es:[di]
0x0000000000002cff:  26 8B 55 02       mov   dx, word ptr es:[di + 2]
0x0000000000002d03:  BF 83 24          mov   di, 0x2483
0x0000000000002d06:  C1 E0 03          shl   ax, 3
0x0000000000002d09:  8E C7             mov   es, di
0x0000000000002d0b:  89 C7             mov   di, ax
0x0000000000002d0d:  83 C7 02          add   di, 2
0x0000000000002d10:  B8 4A 3C          mov   ax, 0x3c4a
0x0000000000002d13:  26 8B 3D          mov   di, word ptr es:[di]
0x0000000000002d16:  8E C0             mov   es, ax
0x0000000000002d18:  26 8A 05          mov   al, byte ptr es:[di]
0x0000000000002d1b:  30 E4             xor   ah, ah
0x0000000000002d1d:  40                inc   ax
0x0000000000002d1e:  3B 46 F8          cmp   ax, word ptr [bp - 8]
0x0000000000002d21:  7D 03             jge   0x2d26
0x0000000000002d23:  89 46 F8          mov   word ptr [bp - 8], ax
0x0000000000002d26:  89 D7             mov   di, dx
0x0000000000002d28:  B8 83 24          mov   ax, 0x2483
0x0000000000002d2b:  C1 E7 03          shl   di, 3
0x0000000000002d2e:  8E C0             mov   es, ax
0x0000000000002d30:  83 C7 02          add   di, 2
0x0000000000002d33:  B8 4A 3C          mov   ax, 0x3c4a
0x0000000000002d36:  26 8B 3D          mov   di, word ptr es:[di]
0x0000000000002d39:  8E C0             mov   es, ax
0x0000000000002d3b:  26 8A 05          mov   al, byte ptr es:[di]
0x0000000000002d3e:  30 E4             xor   ah, ah
0x0000000000002d40:  40                inc   ax
0x0000000000002d41:  3B 46 F8          cmp   ax, word ptr [bp - 8]
0x0000000000002d44:  7D 03             jge   0x2d49
0x0000000000002d46:  89 46 F8          mov   word ptr [bp - 8], ax
0x0000000000002d49:  C4 7E FA          les   di, dword ptr [bp - 6]
0x0000000000002d4c:  43                inc   bx
0x0000000000002d4d:  83 46 EE 02       add   word ptr [bp - 0x12], 2
0x0000000000002d51:  26 3B 5D 0A       cmp   bx, word ptr es:[di + 0xa]
0x0000000000002d55:  7C 87             jl    0x2cde
0x0000000000002d57:  B8 90 21          mov   ax, SECTORS_SEGMENT
0x0000000000002d5a:  8B 5C 02          mov   bx, word ptr ds:[si + 2]
0x0000000000002d5d:  8B 56 F8          mov   dx, word ptr [bp - 8]
0x0000000000002d60:  C1 E3 04          shl   bx, 4
0x0000000000002d63:  8E C0             mov   es, ax
0x0000000000002d65:  C1 E2 03          shl   dx, 3
0x0000000000002d68:  26 8B 07          mov   ax, word ptr es:[bx]
0x0000000000002d6b:  01 D0             add   ax, dx
0x0000000000002d6d:  89 44 07          mov   word ptr ds:[si + 7], ax
0x0000000000002d70:  E9 F5 FD          jmp   0x2b68
0x0000000000002d73:  8B 7E FA          mov   di, word ptr [bp - 6]
0x0000000000002d76:  C6 47 04 FF       mov   byte ptr ds:[bx + 4], 0xff
0x0000000000002d7a:  89 C8             mov   ax, cx
0x0000000000002d7c:  C7 47 09 08 00    mov   word ptr ds:[bx + 9], 8
0x0000000000002d81:  31 D2             xor   dx, dx
0x0000000000002d83:  89 4F 02          mov   word ptr ds:[bx + 2], cx
0x0000000000002d86:  E8 66 13          call  0x40ef
0x0000000000002d89:  89 47 07          mov   word ptr ds:[bx + 7], ax
0x0000000000002d8c:  8E 46 FC          mov   es, word ptr [bp - 4]
0x0000000000002d8f:  26 8A 45 04       mov   al, byte ptr es:[di + 4]
0x0000000000002d93:  88 47 06          mov   byte ptr ds:[bx + 6], al
0x0000000000002d96:  31 DB             xor   bx, bx
0x0000000000002d98:  26 83 7D 0A 00    cmp   word ptr es:[di + 0xa], 0
0x0000000000002d9d:  7F 03             jg    0x2da2
0x0000000000002d9f:  E9 C6 FD          jmp   0x2b68
0x0000000000002da2:  8B 46 E6          mov   ax, word ptr [bp - 0x1a]
0x0000000000002da5:  01 C0             add   ax, ax
0x0000000000002da7:  89 46 F0          mov   word ptr [bp - 0x10], ax
0x0000000000002daa:  89 DA             mov   dx, bx
0x0000000000002dac:  89 C8             mov   ax, cx
0x0000000000002dae:  E8 C5 12          call  0x4076
0x0000000000002db1:  85 C0             test  ax, ax
0x0000000000002db3:  74 74             je    0x2e29
0x0000000000002db5:  8B 46 F0          mov   ax, word ptr [bp - 0x10]
0x0000000000002db8:  89 C7             mov   di, ax
0x0000000000002dba:  C7 46 EC 91 29    mov   word ptr [bp - 0x14], 0x2991
0x0000000000002dbf:  81 C7 50 CA       add   di, 0xca50
0x0000000000002dc3:  8B 05             mov   ax, word ptr ds:[di]
0x0000000000002dc5:  8B 3D             mov   di, word ptr ds:[di]
0x0000000000002dc7:  BA 00 70          mov   dx, 0x7000
0x0000000000002dca:  C1 E7 04          shl   di, 4
0x0000000000002dcd:  8E C2             mov   es, dx
0x0000000000002dcf:  C1 E0 02          shl   ax, 2
0x0000000000002dd2:  26 3B 4D 0A       cmp   cx, word ptr es:[di + 0xa]
0x0000000000002dd6:  75 29             jne   0x2e01
0x0000000000002dd8:  8E 46 EC          mov   es, word ptr [bp - 0x14]
0x0000000000002ddb:  89 C7             mov   di, ax
0x0000000000002ddd:  26 8B 4D 02       mov   cx, word ptr es:[di + 2]
0x0000000000002de1:  C4 7E FA          les   di, dword ptr [bp - 6]
0x0000000000002de4:  26 8B 05          mov   ax, word ptr es:[di]
0x0000000000002de7:  3B 44 07          cmp   ax, word ptr ds:[si + 7]
0x0000000000002dea:  75 3D             jne   0x2e29
0x0000000000002dec:  89 FB             mov   bx, di
0x0000000000002dee:  26 8A 47 04       mov   al, byte ptr es:[bx + 4]
0x0000000000002df2:  8B 5E F2          mov   bx, word ptr [bp - 0xe]
0x0000000000002df5:  88 44 06          mov   byte ptr ds:[si + 6], al
0x0000000000002df8:  8A 47 0E          mov   al, byte ptr ds:[bx + 0xe]
0x0000000000002dfb:  88 44 05          mov   byte ptr ds:[si + 5], al
0x0000000000002dfe:  E9 67 FD          jmp   0x2b68
0x0000000000002e01:  8E 46 EC          mov   es, word ptr [bp - 0x14]
0x0000000000002e04:  89 C7             mov   di, ax
0x0000000000002e06:  26 8B 0D          mov   cx, word ptr es:[di]
0x0000000000002e09:  C4 7E FA          les   di, dword ptr [bp - 6]
0x0000000000002e0c:  26 8B 05          mov   ax, word ptr es:[di]
0x0000000000002e0f:  3B 44 07          cmp   ax, word ptr ds:[si + 7]
0x0000000000002e12:  75 15             jne   0x2e29
0x0000000000002e14:  89 FB             mov   bx, di
0x0000000000002e16:  26 8A 47 04       mov   al, byte ptr es:[bx + 4]
0x0000000000002e1a:  8B 5E F2          mov   bx, word ptr [bp - 0xe]
0x0000000000002e1d:  88 44 06          mov   byte ptr ds:[si + 6], al
0x0000000000002e20:  8A 47 0E          mov   al, byte ptr ds:[bx + 0xe]
0x0000000000002e23:  88 44 05          mov   byte ptr ds:[si + 5], al
0x0000000000002e26:  E9 3F FD          jmp   0x2b68
0x0000000000002e29:  C4 7E FA          les   di, dword ptr [bp - 6]
0x0000000000002e2c:  43                inc   bx
0x0000000000002e2d:  83 46 F0 02       add   word ptr [bp - 0x10], 2
0x0000000000002e31:  26 3B 5D 0A       cmp   bx, word ptr es:[di + 0xa]
0x0000000000002e35:  7D 03             jge   0x2e3a
0x0000000000002e37:  E9 70 FF          jmp   0x2daa
0x0000000000002e3a:  E9 2B FD          jmp   0x2b68


ENDP

PROC    EV_BuildStairs_ NEAR
PUBLIC  EV_BuildStairs_


0x0000000000002e3e:  53                push  bx
0x0000000000002e3f:  51                push  cx
0x0000000000002e40:  56                push  si
0x0000000000002e41:  57                push  di
0x0000000000002e42:  55                push  bp
0x0000000000002e43:  89 E5             mov   bp, sp
0x0000000000002e45:  81 EC 18 02       sub   sp, 0x218
0x0000000000002e49:  88 56 FE          mov   byte ptr [bp - 2], dl
0x0000000000002e4c:  C7 46 EE 00 00    mov   word ptr [bp - 0x12], 0
0x0000000000002e51:  8D 96 E8 FD       lea   dx, [bp - 0x218]
0x0000000000002e55:  98                cbw  
0x0000000000002e56:  31 DB             xor   bx, bx
0x0000000000002e58:  C7 46 F0 00 00    mov   word ptr [bp - 0x10], 0
0x0000000000002e5d:  E8 EC 13          call  0x424c
0x0000000000002e60:  83 BE E8 FD 00    cmp   word ptr [bp - 0x218], 0
0x0000000000002e65:  7D 03             jge   0x2e6a
0x0000000000002e67:  E9 5F 01          jmp   0x2fc9
0x0000000000002e6a:  8B 76 F0          mov   si, word ptr [bp - 0x10]
0x0000000000002e6d:  C7 46 FA 2C 00    mov   word ptr [bp - 6], 0x2c
0x0000000000002e72:  8B 82 E8 FD       mov   ax, word ptr [bp + si - 0x218]
0x0000000000002e76:  31 D2             xor   dx, dx
0x0000000000002e78:  89 46 F8          mov   word ptr [bp - 8], ax
0x0000000000002e7b:  89 C1             mov   cx, ax
0x0000000000002e7d:  B8 90 21          mov   ax, SECTORS_SEGMENT
0x0000000000002e80:  C1 E1 04          shl   cx, 4
0x0000000000002e83:  8E C0             mov   es, ax
0x0000000000002e85:  89 CB             mov   bx, cx
0x0000000000002e87:  B8 00 28          mov   ax, 0x2800
0x0000000000002e8a:  26 8B 3F          mov   di, word ptr es:[bx]
0x0000000000002e8d:  0E                push  cs
0x0000000000002e8e:  3E E8 5A 21       call  0x4fec
0x0000000000002e92:  89 C3             mov   bx, ax
0x0000000000002e94:  89 C6             mov   si, ax
0x0000000000002e96:  2D 04 34          sub   ax, 0x3404
0x0000000000002e99:  F7 76 FA          div   word ptr [bp - 6]
0x0000000000002e9c:  C7 46 EE 01 00    mov   word ptr [bp - 0x12], 1
0x0000000000002ea1:  C6 47 04 01       mov   byte ptr ds:[bx + 4], 1
0x0000000000002ea5:  8B 56 F8          mov   dx, word ptr [bp - 8]
0x0000000000002ea8:  83 46 F0 02       add   word ptr [bp - 0x10], 2
0x0000000000002eac:  89 57 02          mov   word ptr ds:[bx + 2], dx
0x0000000000002eaf:  89 CB             mov   bx, cx
0x0000000000002eb1:  89 87 38 DE       mov   word ptr ds:[bx - 0x21c8], ax
0x0000000000002eb5:  8A 46 FE          mov   al, byte ptr [bp - 2]
0x0000000000002eb8:  81 C3 38 DE       add   bx, 0xde38
0x0000000000002ebc:  3C 01             cmp   al, 1
0x0000000000002ebe:  75 63             jne   0x2f23
0x0000000000002ec0:  C7 46 F2 20 00    mov   word ptr [bp - 0xe], 0x20
0x0000000000002ec5:  C7 46 F4 80 00    mov   word ptr [bp - 0xc], 0x80
0x0000000000002eca:  8B 4E F4          mov   cx, word ptr [bp - 0xc]
0x0000000000002ecd:  8B 46 F2          mov   ax, word ptr [bp - 0xe]
0x0000000000002ed0:  01 F9             add   cx, di
0x0000000000002ed2:  89 44 09          mov   word ptr ds:[si + 9], ax
0x0000000000002ed5:  89 4C 07          mov   word ptr ds:[si + 7], cx
0x0000000000002ed8:  8B 5E F8          mov   bx, word ptr [bp - 8]
0x0000000000002edb:  B8 90 21          mov   ax, SECTORS_SEGMENT
0x0000000000002ede:  C1 E3 04          shl   bx, 4
0x0000000000002ee1:  8E C0             mov   es, ax
0x0000000000002ee3:  26 8A 47 04       mov   al, byte ptr es:[bx + 4]
0x0000000000002ee7:  88 46 FC          mov   byte ptr [bp - 4], al
0x0000000000002eea:  26 8B 47 0A       mov   ax, word ptr es:[bx + 0xa]
0x0000000000002eee:  31 FF             xor   di, di
0x0000000000002ef0:  89 46 F6          mov   word ptr [bp - 0xa], ax
0x0000000000002ef3:  26 8B 47 0C       mov   ax, word ptr es:[bx + 0xc]
0x0000000000002ef7:  30 D2             xor   dl, dl
0x0000000000002ef9:  89 46 EC          mov   word ptr [bp - 0x14], ax
0x0000000000002efc:  88 D0             mov   al, dl
0x0000000000002efe:  30 E4             xor   ah, ah
0x0000000000002f00:  3B 46 F6          cmp   ax, word ptr [bp - 0xa]
0x0000000000002f03:  7D 2E             jge   0x2f33
0x0000000000002f05:  03 46 EC          add   ax, word ptr [bp - 0x14]
0x0000000000002f08:  01 C0             add   ax, ax
0x0000000000002f0a:  89 C3             mov   bx, ax
0x0000000000002f0c:  81 C3 50 CA       add   bx, 0xca50
0x0000000000002f10:  8B 07             mov   ax, word ptr ds:[bx]
0x0000000000002f12:  BB 4A 2B          mov   bx, 0x2b4a
0x0000000000002f15:  8E C3             mov   es, bx
0x0000000000002f17:  89 C3             mov   bx, ax
0x0000000000002f19:  26 F6 07 04       test  byte ptr es:[bx], 4
0x0000000000002f1d:  75 17             jne   0x2f36
0x0000000000002f1f:  FE C2             inc   dl
0x0000000000002f21:  EB D9             jmp   0x2efc
0x0000000000002f23:  84 C0             test  al, al
0x0000000000002f25:  75 A3             jne   0x2eca
0x0000000000002f27:  C7 46 F2 02 00    mov   word ptr [bp - 0xe], 2
0x0000000000002f2c:  C7 46 F4 40 00    mov   word ptr [bp - 0xc], 0x40
0x0000000000002f31:  EB 97             jmp   0x2eca
0x0000000000002f33:  E9 7F 00          jmp   0x2fb5
0x0000000000002f36:  BB 00 70          mov   bx, 0x7000
0x0000000000002f39:  C1 E0 04          shl   ax, 4
0x0000000000002f3c:  8E C3             mov   es, bx
0x0000000000002f3e:  89 C3             mov   bx, ax
0x0000000000002f40:  83 C3 0A          add   bx, 0xa
0x0000000000002f43:  26 8B 1F          mov   bx, word ptr es:[bx]
0x0000000000002f46:  3B 5E F8          cmp   bx, word ptr [bp - 8]
0x0000000000002f49:  75 D4             jne   0x2f1f
0x0000000000002f4b:  89 C3             mov   bx, ax
0x0000000000002f4d:  C7 46 EA 00 00    mov   word ptr [bp - 0x16], 0
0x0000000000002f52:  26 8B 77 0C       mov   si, word ptr es:[bx + 0xc]
0x0000000000002f56:  83 C3 0C          add   bx, 0xc
0x0000000000002f59:  89 F0             mov   ax, si
0x0000000000002f5b:  BB 90 21          mov   bx, SECTORS_SEGMENT
0x0000000000002f5e:  C1 E0 04          shl   ax, 4
0x0000000000002f61:  8E C3             mov   es, bx
0x0000000000002f63:  89 C3             mov   bx, ax
0x0000000000002f65:  89 46 E8          mov   word ptr [bp - 0x18], ax
0x0000000000002f68:  26 8A 47 04       mov   al, byte ptr es:[bx + 4]
0x0000000000002f6c:  83 C3 04          add   bx, 4
0x0000000000002f6f:  3A 46 FC          cmp   al, byte ptr [bp - 4]
0x0000000000002f72:  75 AB             jne   0x2f1f
0x0000000000002f74:  8B 5E E8          mov   bx, word ptr [bp - 0x18]
0x0000000000002f77:  81 C3 38 DE       add   bx, 0xde38
0x0000000000002f7b:  03 4E F4          add   cx, word ptr [bp - 0xc]
0x0000000000002f7e:  83 3F 00          cmp   word ptr ds:[bx], 0
0x0000000000002f81:  75 9C             jne   0x2f1f
0x0000000000002f83:  B8 00 28          mov   ax, 0x2800
0x0000000000002f86:  C7 46 FA 2C 00    mov   word ptr [bp - 6], 0x2c
0x0000000000002f8b:  0E                push  cs
0x0000000000002f8c:  3E E8 5C 20       call  0x4fec
0x0000000000002f90:  31 D2             xor   dx, dx
0x0000000000002f92:  89 C7             mov   di, ax
0x0000000000002f94:  2D 04 34          sub   ax, 0x3404
0x0000000000002f97:  F7 76 FA          div   word ptr [bp - 6]
0x0000000000002f9a:  C6 45 04 01       mov   byte ptr ds:[di + 4], 1
0x0000000000002f9e:  89 4D 07          mov   word ptr ds:[di + 7], cx
0x0000000000002fa1:  89 75 02          mov   word ptr ds:[di + 2], si
0x0000000000002fa4:  89 4D 07          mov   word ptr ds:[di + 7], cx
0x0000000000002fa7:  8B 56 F2          mov   dx, word ptr [bp - 0xe]
0x0000000000002faa:  89 55 09          mov   word ptr ds:[di + 9], dx
0x0000000000002fad:  89 76 F8          mov   word ptr [bp - 8], si
0x0000000000002fb0:  89 07             mov   word ptr ds:[bx], ax
0x0000000000002fb2:  E9 23 FF          jmp   0x2ed8
0x0000000000002fb5:  85 FF             test  di, di
0x0000000000002fb7:  74 03             je    0x2fbc
0x0000000000002fb9:  E9 1C FF          jmp   0x2ed8
0x0000000000002fbc:  8B 76 F0          mov   si, word ptr [bp - 0x10]
0x0000000000002fbf:  83 BA E8 FD 00    cmp   word ptr [bp + si - 0x218], 0
0x0000000000002fc4:  7C 03             jl    0x2fc9
0x0000000000002fc6:  E9 A1 FE          jmp   0x2e6a
0x0000000000002fc9:  8B 46 EE          mov   ax, word ptr [bp - 0x12]
0x0000000000002fcc:  C9                LEAVE_MACRO 
0x0000000000002fcd:  5F                pop   di
0x0000000000002fce:  5E                pop   si
0x0000000000002fcf:  59                pop   cx
0x0000000000002fd0:  5B                pop   bx
0x0000000000002fd1:  C3                ret   
0x0000000000002fd2:  0A 00             or    al, byte ptr ds:[bx + si]
0x0000000000002fd4:  04 00             add   al, 0
0x0000000000002fd6:  14 00             adc   al, 0
0x0000000000002fd8:  01 00             add   word ptr ds:[bx + si], ax
0x0000000000002fda:  3C 30             cmp   al, 0x30
0x0000000000002fdc:  57                push  di
0x0000000000002fdd:  30 6F 30          xor   byte ptr ds:[bx + 0x30], ch
0x0000000000002fe0:  87 30             xchg  word ptr ds:[bx + si], si
0x0000000000002fe2:  53                push  bx
0x0000000000002fe3:  98                cbw  
0x0000000000002fe4:  3C 05             cmp   al, 5
0x0000000000002fe6:  74 50             je    0x3038
0x0000000000002fe8:  93                xchg  ax, bx
0x0000000000002fe9:  D1 E3             shl   bx, 1
0x0000000000002feb:  8B 87 0C 08       mov   ax, word ptr ds:[bx + 0x80c]
0x0000000000002fef:  3B 87 14 08       cmp   ax, word ptr ds:[bx + 0x814]
0x0000000000002ff3:  74 43             je    0x3038
0x0000000000002ff5:  2E 8B 87 D2 2F    mov   ax, word ptr cs:[bx + 0x2fd2]
0x0000000000002ffa:  84 D2             test  dl, dl
0x0000000000002ffc:  75 06             jne   0x3004
0x0000000000002ffe:  8B D0             mov   dx, ax
0x0000000000003000:  D1 FA             sar   dx, 1
0x0000000000003002:  EB 03             jmp   0x3007
0x0000000000003004:  F6 E2             mul   dl
0x0000000000003006:  92                xchg  ax, dx
0x0000000000003007:  A0 31 01          mov   al, byte ptr ds:[_gameskill]
0x000000000000300a:  84 C0             test  al, al
0x000000000000300c:  74 04             je    0x3012
0x000000000000300e:  3C 04             cmp   al, 4
0x0000000000003010:  75 02             jne   0x3014
0x0000000000003012:  D1 E2             shl   dx, 1
0x0000000000003014:  8B 87 0C 08       mov   ax, word ptr ds:[bx + 0x80c]
0x0000000000003018:  03 D0             add   dx, ax
0x000000000000301a:  89 97 0C 08       mov   word ptr ds:[bx + 0x80c], dx
0x000000000000301e:  3B 97 14 08       cmp   dx, word ptr ds:[bx + 0x814]
0x0000000000003022:  7E 08             jle   0x302c
0x0000000000003024:  8B 97 14 08       mov   dx, word ptr ds:[bx + 0x814]
0x0000000000003028:  89 97 0C 08       mov   word ptr ds:[bx + 0x80c], dx
0x000000000000302c:  85 C0             test  ax, ax
0x000000000000302e:  75 1C             jne   0x304c
0x0000000000003030:  A0 00 08          mov   al, byte ptr ds:[0x800]
0x0000000000003033:  2E FF A7 DA 2F    jmp   word ptr cs:[bx + 0x2fda]
0x0000000000003038:  33 C0             xor   ax, ax
0x000000000000303a:  5B                pop   bx
0x000000000000303b:  C3                ret   
0x000000000000303c:  3C 00             cmp   al, 0
0x000000000000303e:  75 0C             jne   0x304c
0x0000000000003040:  80 3E 05 08 00    cmp   byte ptr ds:[0x805], 0
0x0000000000003045:  74 09             je    0x3050
0x0000000000003047:  C6 06 01 08 03    mov   byte ptr ds:[0x801], 3
0x000000000000304c:  B0 01             mov   al, 1
0x000000000000304e:  5B                pop   bx
0x000000000000304f:  C3                ret   
0x0000000000003050:  B0 01             mov   al, 1
0x0000000000003052:  A2 00 08          mov   byte ptr ds:[0x800], al
0x0000000000003055:  5B                pop   bx
0x0000000000003056:  C3                ret   
0x0000000000003057:  84 C0             test  al, al
0x0000000000003059:  74 04             je    0x305f
0x000000000000305b:  3C 01             cmp   al, 1
0x000000000000305d:  75 ED             jne   0x304c
0x000000000000305f:  80 3E 04 08 00    cmp   byte ptr ds:[0x804], 0
0x0000000000003064:  74 E6             je    0x304c
0x0000000000003066:  C6 06 01 08 02    mov   byte ptr ds:[0x801], 2
0x000000000000306b:  B0 01             mov   al, 1
0x000000000000306d:  5B                pop   bx
0x000000000000306e:  C3                ret   
0x000000000000306f:  84 C0             test  al, al
0x0000000000003071:  74 04             je    0x3077
0x0000000000003073:  3C 01             cmp   al, 1
0x0000000000003075:  75 D5             jne   0x304c
0x0000000000003077:  80 3E 07 08 00    cmp   byte ptr ds:[0x807], 0
0x000000000000307c:  74 CE             je    0x304c
0x000000000000307e:  C6 06 01 08 05    mov   byte ptr ds:[0x801], 5
0x0000000000003083:  B0 01             mov   al, 1
0x0000000000003085:  5B                pop   bx
0x0000000000003086:  C3                ret   
0x0000000000003087:  3C 00             cmp   al, 0
0x0000000000003089:  75 C1             jne   0x304c
0x000000000000308b:  80 3E 06 08 00    cmp   byte ptr ds:[0x806], 0
0x0000000000003090:  74 BA             je    0x304c
0x0000000000003092:  C6 06 01 08 04    mov   byte ptr ds:[0x801], 4
0x0000000000003097:  B0 01             mov   al, 1
0x0000000000003099:  5B                pop   bx
0x000000000000309a:  C3                ret   
0x000000000000309b:  53                push  bx
0x000000000000309c:  98                cbw  
0x000000000000309d:  93                xchg  ax, bx
0x000000000000309e:  B0 0B             mov   al, 0xb
0x00000000000030a0:  F6 E3             mul   bl
0x00000000000030a2:  93                xchg  ax, bx
0x00000000000030a3:  8A B7 58 08       mov   dh, byte ptr ds:[bx + 0x858]
0x00000000000030a7:  80 FE 05          cmp   dh, 5
0x00000000000030aa:  75 0C             jne   0x30b8
0x00000000000030ac:  93                xchg  ax, bx
0x00000000000030ad:  80 BF 02 08 00    cmp   byte ptr ds:[bx + 0x802], 0
0x00000000000030b2:  74 1B             je    0x30cf
0x00000000000030b4:  33 C0             xor   ax, ax
0x00000000000030b6:  5B                pop   bx
0x00000000000030b7:  C3                ret   
0x00000000000030b8:  93                xchg  ax, bx
0x00000000000030b9:  8A C6             mov   al, dh
0x00000000000030bb:  84 D2             test  dl, dl
0x00000000000030bd:  75 02             jne   0x30c1
0x00000000000030bf:  B2 02             mov   dl, 2
0x00000000000030c1:  E8 1E FF          call  0x2fe2
0x00000000000030c4:  84 C0             test  al, al
0x00000000000030c6:  74 E5             je    0x30ad
0x00000000000030c8:  80 BF 02 08 00    cmp   byte ptr ds:[bx + 0x802], 0
0x00000000000030cd:  75 09             jne   0x30d8
0x00000000000030cf:  C6 87 02 08 01    mov   byte ptr ds:[bx + 0x802], 1
0x00000000000030d4:  88 1E 01 08       mov   byte ptr ds:[0x801], bl
0x00000000000030d8:  B0 01             mov   al, 1
0x00000000000030da:  5B                pop   bx
0x00000000000030db:  C3                ret   
0x00000000000030dc:  53                push  bx
0x00000000000030dd:  BB E8 07          mov   bx, 0x7e8
0x00000000000030e0:  83 3F 64          cmp   word ptr ds:[bx], 0x64
0x00000000000030e3:  7D 17             jge   0x30fc
0x00000000000030e5:  03 07             add   ax, word ptr ds:[bx]
0x00000000000030e7:  3D 64 00          cmp   ax, 0x64
0x00000000000030ea:  7E 03             jle   0x30ef
0x00000000000030ec:  B8 64 00          mov   ax, 0x64
0x00000000000030ef:  89 07             mov   word ptr ds:[bx], ax
0x00000000000030f1:  8B 1E EC 06       mov   bx, word ptr ds:[0x6ec]
0x00000000000030f5:  89 47 1C          mov   word ptr ds:[bx + 0x1c], ax
0x00000000000030f8:  B0 01             mov   al, 1
0x00000000000030fa:  5B                pop   bx
0x00000000000030fb:  C3                ret   
0x00000000000030fc:  32 C0             xor   al, al
0x00000000000030fe:  5B                pop   bx
0x00000000000030ff:  C3                ret   
0x0000000000003100:  52                push  dx
0x0000000000003101:  BA 64 00          mov   dx, 0x64
0x0000000000003104:  3C 01             cmp   al, 1
0x0000000000003106:  74 02             je    0x310a
0x0000000000003108:  D1 E2             shl   dx, 1
0x000000000000310a:  3B 16 EA 07       cmp   dx, word ptr ds:[0x7ea]
0x000000000000310e:  7F 04             jg    0x3114
0x0000000000003110:  33 C0             xor   ax, ax
0x0000000000003112:  5A                pop   dx
0x0000000000003113:  C3                ret   
0x0000000000003114:  A2 EC 07          mov   byte ptr ds:[0x7ec], al
0x0000000000003117:  89 16 EA 07       mov   word ptr ds:[0x7ea], dx
0x000000000000311b:  B0 01             mov   al, 1
0x000000000000311d:  5A                pop   dx
0x000000000000311e:  C3                ret   
0x000000000000311f:  53                push  bx
0x0000000000003120:  98                cbw  
0x0000000000003121:  8B D8             mov   bx, ax
0x0000000000003123:  80 BF FA 07 00    cmp   byte ptr ds:[bx + 0x7fa], 0
0x0000000000003128:  74 03             je    0x312d
0x000000000000312a:  5E                pop   si
0x000000000000312b:  5B                pop   bx
0x000000000000312c:  C3                ret   
0x000000000000312d:  C6 06 2A 08 06    mov   byte ptr ds:[0x82a], 6
0x0000000000003132:  C6 87 FA 07 01    mov   byte ptr ds:[bx + 0x7fa], 1
0x0000000000003137:  5B                pop   bx
0x0000000000003138:  C3                ret   
0x0000000000003139:  53                push  bx
0x000000000000313a:  8B D8             mov   bx, ax
0x000000000000313c:  D1 E3             shl   bx, 1
0x000000000000313e:  85 C0             test  ax, ax
0x0000000000003140:  75 05             jne   0x3147
0x0000000000003142:  B8 1A 04          mov   ax, 0x41a
0x0000000000003145:  EB 25             jmp   0x316c
0x0000000000003147:  3C 02             cmp   al, 2
0x0000000000003149:  74 13             je    0x315e
0x000000000000314b:  72 2C             jb    0x3179
0x000000000000314d:  3C 04             cmp   al, 4
0x000000000000314f:  72 18             jb    0x3169
0x0000000000003151:  77 21             ja    0x3174
0x0000000000003153:  83 BF EE 07 00    cmp   word ptr ds:[bx + 0x7ee], 0
0x0000000000003158:  74 25             je    0x317f
0x000000000000315a:  33 C0             xor   ax, ax
0x000000000000315c:  5B                pop   bx
0x000000000000315d:  CB                retf  
0x000000000000315e:  93                xchg  ax, bx
0x000000000000315f:  C4 1E 30 07       les   bx, dword ptr ds:[0x730]
0x0000000000003163:  26 80 4F 16 04    or    byte ptr es:[bx + 0x16], 4
0x0000000000003168:  93                xchg  ax, bx
0x0000000000003169:  B8 34 08          mov   ax, 0x834
0x000000000000316c:  89 87 EE 07       mov   word ptr ds:[bx + 0x7ee], ax
0x0000000000003170:  B0 01             mov   al, 1
0x0000000000003172:  5B                pop   bx
0x0000000000003173:  CB                retf  
0x0000000000003174:  B8 68 10          mov   ax, 0x1068
0x0000000000003177:  EB F3             jmp   0x316c
0x0000000000003179:  B8 64 00          mov   ax, 0x64
0x000000000000317c:  E8 5D FF          call  0x30dc
0x000000000000317f:  B8 01 00          mov   ax, 1
0x0000000000003182:  89 87 EE 07       mov   word ptr ds:[bx + 0x7ee], ax
0x0000000000003186:  5B                pop   bx
0x0000000000003187:  CB                retf  

ENDP

@

PROC    P_FLOOR_ENDMARKER_ NEAR
PUBLIC  P_FLOOR_ENDMARKER_
ENDP

END
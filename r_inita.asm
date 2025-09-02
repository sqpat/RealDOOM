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


EXTRN DEBUG_PRINT_:FAR
;todo inline quickmaps?
EXTRN Z_QuickMapScratch_5000_:FAR
EXTRN Z_QuickMapUndoFlatCache_:FAR
EXTRN Z_QuickMapRender_:FAR
EXTRN W_CacheLumpNameDirect_:FAR
.DATA

EXTRN _numspritelumps:WORD
EXTRN _numflats:WORD
EXTRN _numpatches:WORD
EXTRN _numtextures:WORD

EXTRN _currentlumpindex:WORD
EXTRN _maskedcount:WORD

EXTRN _currentpostdataoffset:WORD
EXTRN _currentpostoffset:WORD
EXTRN _currentpixeloffset:WORD

.CODE


str_dot:
db ".", 0

do_print_dot:
push      cs
mov       ax, OFFSET str_dot
push      ax
call      DEBUG_PRINT_       
add       sp, 4
jmp       done_printing_dot


PROC   R_InitSpriteLumps_ NEAR
PUBLIC R_InitSpriteLumps_

PUSHA_NO_AX_OR_BP_MACRO
push      bp
mov       bp, sp
sub       sp, 010h
xor       dx, dx
cmp       byte ptr ds:[_is_ultimate], dl ; 0
mov       ax, SPRITEWIDTHS_NORMAL_SEGMENT
je        not_ultimate
mov       ax, SPRITEWIDTHS_ULT_SEGMENT

not_ultimate:
mov       word ptr ds:[_spritewidths_segment], ax
mov       word ptr [bp - 8], dx ; 0
; 0 sprite check should be unnecessary
; cmp       word ptr ds:[_numspritelumps], dx ; 0
; jg        continue_spritelumps
; jmp       exit_r_initspritelumps
continue_spritelumps:
mov       word ptr [bp - 0Ch], dx ; 0
loop_next_sprite:
xor       di, di
xor       si, si
test      byte ptr [bp - 8], 63
je        do_print_dot
done_printing_dot:
call      Z_QuickMapScratch_5000_
mov       ax, word ptr ds:[_firstspritelump]
mov       cx, SCRATCH_SEGMENT_5000
add       ax, word ptr [bp - 8]
xor       bx, bx
mov       word ptr [bp - 010h], bx ; 0
call      W_CacheLumpNameDirect_
mov       ax, SCRATCH_SEGMENT_5000
mov       es, ax
xor       bx, bx
mov       word ptr [bp - 0Ah], ax
mov       ax, word ptr es:[bx + PATCH_T.patch_width]
mov       cx, word ptr es:[bx + PATCH_T.patch_topoffset]
mov       word ptr [bp - 4], ax
mov       ax, word ptr es:[bx + PATCH_T.patch_leftoffset]
mov       es, word ptr ds:[_spritewidths_segment]
mov       bx, word ptr [bp - 8]
mov       dl, 1

cmp       word ptr [bp - 4], 257
je        hardcode_257_spritewidth
normal_spritewidth:
mov       dl, byte ptr [bp - 4]
hardcode_257_spritewidth:
mov       byte ptr es:[bx], dl
; abs ax
cwd       
xor       ax, dx
sub       ax, dx
; bx still this
;mov       bx, word ptr [bp - 8]
mov       dx, SPRITEOFFSETS_SEGMENT
mov       es, dx
mov       byte ptr es:[bx], al
mov       ax, SPRITETOPOFFSETS_SEGMENT
mov       es, ax
mov       al, 080h  ; - 128
cmp       cx, 129
je        handle_129_spritetopoffset
handle_normal_sprite_offset:
xchg      ax, cx
handle_129_spritetopoffset:
mov       byte ptr es:[bx], al

xor       dx, dx
; shouldnt have width 0 sprites..
;cmp       word ptr [bp - 4], dx ; 0
;jle       finished_sprite_loading_loop
mov       bx, word ptr [bp - 010h]
mov       word ptr [bp - 2], bx

loop_next_spritecolumn:
mov       ax, SCRATCH_SEGMENT_5000
mov       es, ax

mov       bx, word ptr [bp - 2]
mov       bx, word ptr es:[bx + 8]
mov       word ptr [bp - 0Eh], ax
cmp       byte ptr es:[bx], 0FFh
je        found_end_of_spritecolumn
mov       es, word ptr [bp - 0Eh]
loop_next_spritepost:
mov       al, byte ptr es:[bx + 1]
xor       ah, ah
mov       cx, 16
add       si, ax
and       al, 0Fh
sub       cx, ax
mov       ax, cx
xor       ah, ch
and       al, 0Fh
add       si, ax
mov       al, byte ptr es:[bx + 1]
xor       ah, ah
add       bx, ax
add       bx, 4
add       di, 2
cmp       byte ptr es:[bx], 0FFh
jne       loop_next_spritepost
found_end_of_spritecolumn:
add       word ptr [bp - 2], 4
inc       dx
add       di, 2
cmp       dx, word ptr [bp - 4]
jl        loop_next_spritecolumn
finished_sprite_loading_loop:
mov       dx, word ptr [bp - 4]
shl       dx, 2
add       dx, 8
add       dx, di
mov       ax, dx
xor       ah, dh
mov       bx, 16
and       al, 15
sub       bx, ax
mov       ax, bx
xor       ah, bh
inc       word ptr [bp - 8]
and       al, 15
mov       bx, word ptr [bp - 0Ch]
add       dx, ax
call      Z_QuickMapUndoFlatCache_
add       dx, si
mov       ax, SPRITEPOSTDATASIZES_SEGMENT
mov       es, ax
mov       word ptr es:[bx], di
mov       ax, SPRITETOTALDATASIZES_SEGMENT
mov       es, ax
add       word ptr [bp - 0Ch], 2
mov       word ptr es:[bx], dx
mov       bx, word ptr [bp - 8]
call      Z_QuickMapRender_
cmp       bx, word ptr ds:[_numspritelumps]
jge       exit_r_initspritelumps
jmp       loop_next_sprite
exit_r_initspritelumps:
LEAVE_MACRO     
POPA_NO_AX_OR_BP_MACRO
ret      


ENDP


COMMENT @

PROC    R_GenerateLookup_ NEAR

0x0000000000000728:  53                push      bx
0x0000000000000729:  51                push      cx
0x000000000000072a:  52                push      dx
0x000000000000072b:  56                push      si
0x000000000000072c:  57                push      di
0x000000000000072d:  55                push      bp
0x000000000000072e:  89 E5             mov       bp, sp
0x0000000000000730:  81 EC 82 00       sub       sp, 0x82
0x0000000000000734:  50                push      ax
0x0000000000000735:  81 ED 80 00       sub       bp, 0x80
0x0000000000000739:  C7 46 04 FF FF    mov       word ptr [bp + 4], 0xffff
0x000000000000073e:  C6 46 7C 00       mov       byte ptr [bp + 0x7c], 0
0x0000000000000742:  C6 46 7E 01       mov       byte ptr [bp + 0x7e], 1
0x0000000000000746:  C7 46 06 00 E0    mov       word ptr [bp + 6], 0xe000
0x000000000000074b:  C7 46 10 00 70    mov       word ptr [bp + 0x10], 0x7000
0x0000000000000750:  C7 46 40 00 F5    mov       word ptr [bp + 0x40], 0xf500
0x0000000000000755:  C7 46 3E 00 70    mov       word ptr [bp + 0x3e], 0x7000
0x000000000000075a:  C7 46 22 00 F7    mov       word ptr [bp + 0x22], 0xf700
0x000000000000075f:  31 C0             xor       ax, ax
0x0000000000000761:  8B 76 FC          mov       si, word ptr [bp - 4]
0x0000000000000764:  89 46 1C          mov       word ptr [bp + 0x1c], ax
0x0000000000000767:  01 F6             add       si, si
0x0000000000000769:  A1 5C 0E          mov       ax, word ptr ds:[_currentlumpindex]
0x000000000000076c:  8D 9C F0 DA       lea       bx, [si - 0x2510]
0x0000000000000770:  C7 46 0E 00 70    mov       word ptr [bp + 0xe], 0x7000
0x0000000000000775:  89 07             mov       word ptr ds:[bx], ax
0x0000000000000777:  B8 2D 93          mov       ax, 0x932d
0x000000000000077a:  C7 46 2C 00 F8    mov       word ptr [bp + 0x2c], 0xf800
0x000000000000077f:  8E C0             mov       es, ax
0x0000000000000781:  B9 B2 90          mov       cx, 0x90b2
0x0000000000000784:  26 8B 34          mov       si, word ptr es:[si]
0x0000000000000787:  8E C1             mov       es, cx
0x0000000000000789:  C7 46 24 00 70    mov       word ptr [bp + 0x24], 0x7000
0x000000000000078e:  26 8A 44 08       mov       al, byte ptr es:[si + 8]
0x0000000000000792:  C7 46 16 00 FA    mov       word ptr [bp + 0x16], 0xfa00
0x0000000000000797:  30 E4             xor       ah, ah
0x0000000000000799:  C7 46 4A 00 70    mov       word ptr [bp + 0x4a], 0x7000
0x000000000000079e:  40                inc       ax
0x000000000000079f:  C7 46 4C 00 FC    mov       word ptr [bp + 0x4c], 0xfc00
0x00000000000007a4:  89 46 08          mov       word ptr [bp + 8], ax
0x00000000000007a7:  26 8A 44 09       mov       al, byte ptr es:[si + 9]
0x00000000000007ab:  C7 46 14 00 70    mov       word ptr [bp + 0x14], 0x7000
0x00000000000007b0:  30 E4             xor       ah, ah
0x00000000000007b2:  C7 46 52 00 FF    mov       word ptr [bp + 0x52], 0xff00
0x00000000000007b7:  40                inc       ax
0x00000000000007b8:  C7 46 54 00 70    mov       word ptr [bp + 0x54], 0x7000
0x00000000000007bd:  89 46 0C          mov       word ptr [bp + 0xc], ax
0x00000000000007c0:  30 E4             xor       ah, ah
0x00000000000007c2:  BA 10 00          mov       dx, 0x10
0x00000000000007c5:  24 0F             and       al, 0xf
0x00000000000007c7:  C7 46 18 00 00    mov       word ptr [bp + 0x18], 0
0x00000000000007cc:  29 C2             sub       dx, ax
0x00000000000007ce:  C7 46 1A 00 90    mov       word ptr [bp + 0x1a], 0x9000
0x00000000000007d3:  89 D0             mov       ax, dx
0x00000000000007d5:  31 FF             xor       di, di
0x00000000000007d7:  30 F4             xor       ah, dh
0x00000000000007d9:  8B 56 0C          mov       dx, word ptr [bp + 0xc]
0x00000000000007dc:  24 0F             and       al, 0xf
0x00000000000007de:  BB 00 FF          mov       bx, 0xff00
0x00000000000007e1:  01 C2             add       dx, ax
0x00000000000007e3:  B8 00 70          mov       ax, 0x7000
0x00000000000007e6:  89 56 38          mov       word ptr [bp + 0x38], dx
0x00000000000007e9:  8E C0             mov       es, ax
0x00000000000007eb:  26 C7 07 00 00    mov       word ptr es:[bx], 0
0x00000000000007f0:  83 C3 02          add       bx, 2
0x00000000000007f3:  75 F4             jne       0x7e9
0x00000000000007f5:  C7 46 0A 00 70    mov       word ptr [bp + 0xa], 0x7000
0x00000000000007fa:  8E C1             mov       es, cx
0x00000000000007fc:  89 5E 26          mov       word ptr [bp + 0x26], bx
0x00000000000007ff:  89 5E 34          mov       word ptr [bp + 0x34], bx
0x0000000000000802:  83 C6 0B          add       si, 0xb
0x0000000000000805:  89 4E 5C          mov       word ptr [bp + 0x5c], cx
0x0000000000000808:  26 8A 44 FF       mov       al, byte ptr es:[si - 1]
0x000000000000080c:  89 76 5A          mov       word ptr [bp + 0x5a], si
0x000000000000080f:  88 46 7A          mov       byte ptr [bp + 0x7a], al
0x0000000000000812:  8A 46 7A          mov       al, byte ptr [bp + 0x7a]
0x0000000000000815:  30 E4             xor       ah, ah
0x0000000000000817:  3B 46 34          cmp       ax, word ptr [bp + 0x34]
0x000000000000081a:  7F 03             jg        0x81f
0x000000000000081c:  E9 26 02          jmp       0xa45
0x000000000000081f:  8B 4E 5C          mov       cx, word ptr [bp + 0x5c]
0x0000000000000822:  8B 5E 5A          mov       bx, word ptr [bp + 0x5a]
0x0000000000000825:  8E C1             mov       es, cx
0x0000000000000827:  89 DE             mov       si, bx
0x0000000000000829:  26 F6 44 03 80    test      byte ptr es:[si + 3], 0x80
0x000000000000082e:  75 03             jne       0x833
0x0000000000000830:  E9 B3 01          jmp       0x9e6
0x0000000000000833:  BA FF FF          mov       dx, 0xffff
0x0000000000000836:  8E C1             mov       es, cx
0x0000000000000838:  26 8A 07          mov       al, byte ptr es:[bx]
0x000000000000083b:  30 E4             xor       ah, ah
0x000000000000083d:  F7 EA             imul      dx
0x000000000000083f:  89 C6             mov       si, ax
0x0000000000000841:  26 8B 47 02       mov       ax, word ptr es:[bx + 2]
0x0000000000000845:  80 E4 7F          and       ah, 0x7f
0x0000000000000848:  89 46 20          mov       word ptr [bp + 0x20], ax
0x000000000000084b:  8B 46 04          mov       ax, word ptr [bp + 4]
0x000000000000084e:  3B 46 20          cmp       ax, word ptr [bp + 0x20]
0x0000000000000851:  74 2C             je        0x87f
0x0000000000000853:  B9 00 70          mov       cx, 0x7000
0x0000000000000856:  8B 46 20          mov       ax, word ptr [bp + 0x20]
0x0000000000000859:  31 DB             xor       bx, bx
0x000000000000085b:  0E                
0x000000000000085c:  3E E8 06 A3       call      W_CacheLumpNameDirect_
0x0000000000000860:  8E 46 0A          mov       es, word ptr [bp + 0xa]
0x0000000000000863:  8B 5E 26          mov       bx, word ptr [bp + 0x26]
0x0000000000000866:  26 8B 47 02       mov       ax, word ptr es:[bx + 2]
0x000000000000086a:  89 46 02          mov       word ptr [bp + 2], ax
0x000000000000086d:  30 E4             xor       ah, ah
0x000000000000086f:  BA 10 00          mov       dx, 0x10
0x0000000000000872:  24 0F             and       al, 0xf
0x0000000000000874:  29 C2             sub       dx, ax
0x0000000000000876:  89 D0             mov       ax, dx
0x0000000000000878:  30 F4             xor       ah, dh
0x000000000000087a:  24 0F             and       al, 0xf
0x000000000000087c:  01 46 02          add       word ptr [bp + 2], ax
0x000000000000087f:  8E 46 0A          mov       es, word ptr [bp + 0xa]
0x0000000000000882:  8B 5E 26          mov       bx, word ptr [bp + 0x26]
0x0000000000000885:  8B 46 02          mov       ax, word ptr [bp + 2]
0x0000000000000888:  26 F7 2F          imul      word ptr es:[bx]
0x000000000000088b:  BB 26 01          mov       bx, 0x126
0x000000000000088e:  8B 56 20          mov       dx, word ptr [bp + 0x20]
0x0000000000000891:  2B 17             sub       dx, word ptr ds:[bx]
0x0000000000000893:  01 D2             add       dx, dx
0x0000000000000895:  89 D3             mov       bx, dx
0x0000000000000897:  89 87 70 E6       mov       word ptr ds:[bx - 0x1990], ax
0x000000000000089b:  81 C3 70 E6       add       bx, 0xe670
0x000000000000089f:  8B 46 20          mov       ax, word ptr [bp + 0x20]
0x00000000000008a2:  8B 5E 26          mov       bx, word ptr [bp + 0x26]
0x00000000000008a5:  89 46 04          mov       word ptr [bp + 4], ax
0x00000000000008a8:  26 8B 07          mov       ax, word ptr es:[bx]
0x00000000000008ab:  01 F0             add       ax, si
0x00000000000008ad:  89 46 32          mov       word ptr [bp + 0x32], ax
0x00000000000008b0:  85 F6             test      si, si
0x00000000000008b2:  7D 03             jge       0x8b7
0x00000000000008b4:  E9 35 01          jmp       0x9ec
0x00000000000008b7:  89 76 00          mov       word ptr [bp], si
0x00000000000008ba:  8B 46 32          mov       ax, word ptr [bp + 0x32]
0x00000000000008bd:  3B 46 08          cmp       ax, word ptr [bp + 8]
0x00000000000008c0:  7E 06             jle       0x8c8
0x00000000000008c2:  8B 46 08          mov       ax, word ptr [bp + 8]
0x00000000000008c5:  89 46 32          mov       word ptr [bp + 0x32], ax
0x00000000000008c8:  8B 5E 00          mov       bx, word ptr [bp]
0x00000000000008cb:  8A 76 00          mov       dh, byte ptr [bp]
0x00000000000008ce:  8B 46 00          mov       ax, word ptr [bp]
0x00000000000008d1:  C1 E3 02          shl       bx, 2
0x00000000000008d4:  3B 46 32          cmp       ax, word ptr [bp + 0x32]
0x00000000000008d7:  7C 03             jl        0x8dc
0x00000000000008d9:  E9 58 01          jmp       0xa34
0x00000000000008dc:  8B 76 40          mov       si, word ptr [bp + 0x40]
0x00000000000008df:  8B 4E 3E          mov       cx, word ptr [bp + 0x3e]
0x00000000000008e2:  01 C0             add       ax, ax
0x00000000000008e4:  C7 46 58 00 70    mov       word ptr [bp + 0x58], 0x7000
0x00000000000008e9:  01 C6             add       si, ax
0x00000000000008eb:  89 5E 56          mov       word ptr [bp + 0x56], bx
0x00000000000008ee:  89 76 3A          mov       word ptr [bp + 0x3a], si
0x00000000000008f1:  8B 76 22          mov       si, word ptr [bp + 0x22]
0x00000000000008f4:  89 4E 3C          mov       word ptr [bp + 0x3c], cx
0x00000000000008f7:  03 76 00          add       si, word ptr [bp]
0x00000000000008fa:  8B 4E 0E          mov       cx, word ptr [bp + 0xe]
0x00000000000008fd:  89 76 42          mov       word ptr [bp + 0x42], si
0x0000000000000900:  8B 76 2C          mov       si, word ptr [bp + 0x2c]
0x0000000000000903:  89 4E 44          mov       word ptr [bp + 0x44], cx
0x0000000000000906:  01 C6             add       si, ax
0x0000000000000908:  8B 46 24          mov       ax, word ptr [bp + 0x24]
0x000000000000090b:  89 76 46          mov       word ptr [bp + 0x46], si
0x000000000000090e:  8B 76 52          mov       si, word ptr [bp + 0x52]
0x0000000000000911:  89 46 48          mov       word ptr [bp + 0x48], ax
0x0000000000000914:  03 76 00          add       si, word ptr [bp]
0x0000000000000917:  8B 46 54          mov       ax, word ptr [bp + 0x54]
0x000000000000091a:  89 76 4E          mov       word ptr [bp + 0x4e], si
0x000000000000091d:  89 46 50          mov       word ptr [bp + 0x50], ax
0x0000000000000920:  C4 5E 4E          les       bx, ptr [bp + 0x4e]
0x0000000000000923:  8B 76 46          mov       si, word ptr [bp + 0x46]
0x0000000000000926:  26 FE 07          inc       byte ptr es:[bx]
0x0000000000000929:  8E 46 48          mov       es, word ptr [bp + 0x48]
0x000000000000092c:  8B 5E 20          mov       bx, word ptr [bp + 0x20]
0x000000000000092f:  26 89 1C          mov       word ptr es:[si], bx
0x0000000000000932:  C4 5E 42          les       bx, ptr [bp + 0x42]
0x0000000000000935:  8B 46 00          mov       ax, word ptr [bp]
0x0000000000000938:  26 88 37          mov       byte ptr es:[bx], dh
0x000000000000093b:  8E 46 0A          mov       es, word ptr [bp + 0xa]
0x000000000000093e:  8B 5E 26          mov       bx, word ptr [bp + 0x26]
0x0000000000000941:  8B 76 3A          mov       si, word ptr [bp + 0x3a]
0x0000000000000944:  26 8B 1F          mov       bx, word ptr es:[bx]
0x0000000000000947:  8E 46 3C          mov       es, word ptr [bp + 0x3c]
0x000000000000094a:  01 C0             add       ax, ax
0x000000000000094c:  26 89 1C          mov       word ptr es:[si], bx
0x000000000000094f:  80 7E 7A 01       cmp       byte ptr [bp + 0x7a], 1
0x0000000000000953:  74 03             je        0x958
0x0000000000000955:  E9 BC 00          jmp       0xa14
0x0000000000000958:  C4 5E 56          les       bx, ptr [bp + 0x56]
0x000000000000095b:  8B 76 4C          mov       si, word ptr [bp + 0x4c]
0x000000000000095e:  8B 4E 1C          mov       cx, word ptr [bp + 0x1c]
0x0000000000000961:  26 8B 5F 08       mov       bx, word ptr es:[bx + 8]
0x0000000000000965:  01 C6             add       si, ax
0x0000000000000967:  8E 46 14          mov       es, word ptr [bp + 0x14]
0x000000000000096a:  C7 46 28 00 00    mov       word ptr [bp + 0x28], 0
0x000000000000096f:  26 89 0C          mov       word ptr es:[si], cx
0x0000000000000972:  89 F9             mov       cx, di
0x0000000000000974:  8B 36 62 0E       mov       si, word ptr ds:[_currentpostdataoffset]
0x0000000000000978:  01 F9             add       cx, di
0x000000000000097a:  C7 46 12 00 70    mov       word ptr [bp + 0x12], 0x7000
0x000000000000097f:  01 CE             add       si, cx
0x0000000000000981:  30 D2             xor       dl, dl
0x0000000000000983:  89 76 2A          mov       word ptr [bp + 0x2a], si
0x0000000000000986:  8B 76 16          mov       si, word ptr [bp + 0x16]
0x0000000000000989:  8E 46 4A          mov       es, word ptr [bp + 0x4a]
0x000000000000098c:  01 C6             add       si, ax
0x000000000000098e:  8B 46 2A          mov       ax, word ptr [bp + 0x2a]
0x0000000000000991:  26 89 04          mov       word ptr es:[si], ax
0x0000000000000994:  8B 46 10          mov       ax, word ptr [bp + 0x10]
0x0000000000000997:  8B 76 06          mov       si, word ptr [bp + 6]
0x000000000000099a:  89 46 36          mov       word ptr [bp + 0x36], ax
0x000000000000099d:  01 CE             add       si, cx
0x000000000000099f:  8E 46 12          mov       es, word ptr [bp + 0x12]
0x00000000000009a2:  47                inc       di
0x00000000000009a3:  26 80 3F FF       cmp       byte ptr es:[bx], 0xff
0x00000000000009a7:  74 4B             je        0x9f4
0x00000000000009a9:  26 8A 47 01       mov       al, byte ptr es:[bx + 1]
0x00000000000009ad:  30 E4             xor       ah, ah
0x00000000000009af:  89 C1             mov       cx, ax
0x00000000000009b1:  80 E1 0F          and       cl, 0xf
0x00000000000009b4:  89 4E 2A          mov       word ptr [bp + 0x2a], cx
0x00000000000009b7:  B9 10 00          mov       cx, 0x10
0x00000000000009ba:  2B 4E 2A          sub       cx, word ptr [bp + 0x2a]
0x00000000000009bd:  83 E1 0F          and       cx, 0xf
0x00000000000009c0:  01 46 28          add       word ptr [bp + 0x28], ax
0x00000000000009c3:  01 C8             add       ax, cx
0x00000000000009c5:  01 46 1C          add       word ptr [bp + 0x1c], ax
0x00000000000009c8:  26 8B 07          mov       ax, word ptr es:[bx]
0x00000000000009cb:  8E 46 36          mov       es, word ptr [bp + 0x36]
0x00000000000009ce:  26 89 04          mov       word ptr es:[si], ax
0x00000000000009d1:  8E 46 12          mov       es, word ptr [bp + 0x12]
0x00000000000009d4:  26 8A 47 01       mov       al, byte ptr es:[bx + 1]
0x00000000000009d8:  83 C6 02          add       si, 2
0x00000000000009db:  30 E4             xor       ah, ah
0x00000000000009dd:  FE C2             inc       dl
0x00000000000009df:  01 C3             add       bx, ax
0x00000000000009e1:  83 C3 04          add       bx, 4
0x00000000000009e4:  EB B9             jmp       0x99f
0x00000000000009e6:  BA 01 00          mov       dx, 1
0x00000000000009e9:  E9 4A FE          jmp       0x836
0x00000000000009ec:  C7 46 00 00 00    mov       word ptr [bp], 0
0x00000000000009f1:  E9 C6 FE          jmp       0x8ba
0x00000000000009f4:  8E 46 36          mov       es, word ptr [bp + 0x36]
0x00000000000009f7:  26 C7 04 FF FF    mov       word ptr es:[si], 0xffff
0x00000000000009fc:  80 FA 01          cmp       dl, 1
0x00000000000009ff:  7E 13             jle       0xa14
0x0000000000000a01:  8B 46 28          mov       ax, word ptr [bp + 0x28]
0x0000000000000a04:  3B 46 0C          cmp       ax, word ptr [bp + 0xc]
0x0000000000000a07:  7D 0B             jge       0xa14
0x0000000000000a09:  81 7E 08 00 01    cmp       word ptr [bp + 8], 0x100
0x0000000000000a0e:  74 2E             je        0xa3e
0x0000000000000a10:  C6 46 7C 01       mov       byte ptr [bp + 0x7c], 1
0x0000000000000a14:  83 46 3A 02       add       word ptr [bp + 0x3a], 2
0x0000000000000a18:  FF 46 42          inc       word ptr [bp + 0x42]
0x0000000000000a1b:  83 46 46 02       add       word ptr [bp + 0x46], 2
0x0000000000000a1f:  FF 46 00          inc       word ptr [bp]
0x0000000000000a22:  FF 46 4E          inc       word ptr [bp + 0x4e]
0x0000000000000a25:  8B 46 00          mov       ax, word ptr [bp]
0x0000000000000a28:  83 46 56 04       add       word ptr [bp + 0x56], 4
0x0000000000000a2c:  3B 46 32          cmp       ax, word ptr [bp + 0x32]
0x0000000000000a2f:  7D 03             jge       0xa34
0x0000000000000a31:  E9 EC FE          jmp       0x920
0x0000000000000a34:  83 46 5A 04       add       word ptr [bp + 0x5a], 4
0x0000000000000a38:  FF 46 34          inc       word ptr [bp + 0x34]
0x0000000000000a3b:  E9 D4 FD          jmp       0x812
0x0000000000000a3e:  80 FA 03          cmp       dl, 3
0x0000000000000a41:  7F CD             jg        0xa10
0x0000000000000a43:  EB CF             jmp       0xa14
0x0000000000000a45:  B8 63 93          mov       ax, 0x9363
0x0000000000000a48:  8B 5E FC          mov       bx, word ptr [bp - 4]
0x0000000000000a4b:  8E C0             mov       es, ax
0x0000000000000a4d:  26 C6 07 FF       mov       byte ptr es:[bx], 0xff
0x0000000000000a51:  80 7E 7C 00       cmp       byte ptr [bp + 0x7c], 0
0x0000000000000a55:  75 03             jne       0xa5a
0x0000000000000a57:  E9 D4 00          jmp       0xb2e
0x0000000000000a5a:  A1 62 0E          mov       ax, word ptr ds:[_currentpostdataoffset]
0x0000000000000a5d:  89 46 2E          mov       word ptr [bp + 0x2e], ax
0x0000000000000a60:  A0 5E 0E          mov       al, byte ptr ds:[_maskedcount]
0x0000000000000a63:  26 88 07          mov       byte ptr es:[bx], al
0x0000000000000a66:  8B 1E 5E 0E       mov       bx, word ptr ds:[_maskedcount]
0x0000000000000a6a:  8B 46 1C          mov       ax, word ptr [bp + 0x1c]
0x0000000000000a6d:  C1 E3 03          shl       bx, 3
0x0000000000000a70:  8B 0E 64 0E       mov       cx, word ptr ds:[_currentpixeloffset]
0x0000000000000a74:  89 87 54 02       mov       word ptr ds:[bx + _masked_headers + 4], ax
0x0000000000000a78:  8B 16 60 0E       mov       dx, word ptr ds:[_currentpostoffset]
0x0000000000000a7c:  89 8F 50 02       mov       word ptr ds:[bx + _masked_headers + 0], cx
0x0000000000000a80:  C7 46 30 00 84    mov       word ptr [bp + 0x30], 0x8400
0x0000000000000a85:  89 97 52 02       mov       word ptr ds:[bx + _masked_headers + 2], dx
0x0000000000000a89:  31 C0             xor       ax, ax
0x0000000000000a8b:  83 7E 08 00       cmp       word ptr [bp + 8], 0
0x0000000000000a8f:  7E 59             jle       0xaea
0x0000000000000a91:  C7 46 60 E8 89    mov       word ptr [bp + 0x60], 0x89e8
0x0000000000000a96:  8B 5E 16          mov       bx, word ptr [bp + 0x16]
0x0000000000000a99:  C7 46 66 C0 8A    mov       word ptr [bp + 0x66], 0x8ac0
0x0000000000000a9e:  89 56 5E          mov       word ptr [bp + 0x5e], dx
0x0000000000000aa1:  8B 56 4A          mov       dx, word ptr [bp + 0x4a]
0x0000000000000aa4:  89 5E 62          mov       word ptr [bp + 0x62], bx
0x0000000000000aa7:  89 56 64          mov       word ptr [bp + 0x64], dx
0x0000000000000aaa:  89 CB             mov       bx, cx
0x0000000000000aac:  8B 56 14          mov       dx, word ptr [bp + 0x14]
0x0000000000000aaf:  8B 4E 4C          mov       cx, word ptr [bp + 0x4c]
0x0000000000000ab2:  89 56 68          mov       word ptr [bp + 0x68], dx
0x0000000000000ab5:  8E 46 68          mov       es, word ptr [bp + 0x68]
0x0000000000000ab8:  89 CE             mov       si, cx
0x0000000000000aba:  83 C3 02          add       bx, 2
0x0000000000000abd:  40                inc       ax
0x0000000000000abe:  83 C1 02          add       cx, 2
0x0000000000000ac1:  26 8B 14          mov       dx, word ptr es:[si]
0x0000000000000ac4:  8E 46 66          mov       es, word ptr [bp + 0x66]
0x0000000000000ac7:  C1 EA 04          shr       dx, 4
0x0000000000000aca:  8B 76 62          mov       si, word ptr [bp + 0x62]
0x0000000000000acd:  26 89 57 FE       mov       word ptr es:[bx - 2], dx
0x0000000000000ad1:  8E 46 64          mov       es, word ptr [bp + 0x64]
0x0000000000000ad4:  83 46 62 02       add       word ptr [bp + 0x62], 2
0x0000000000000ad8:  26 8B 14          mov       dx, word ptr es:[si]
0x0000000000000adb:  C4 76 5E          les       si, ptr [bp + 0x5e]
0x0000000000000ade:  83 46 5E 02       add       word ptr [bp + 0x5e], 2
0x0000000000000ae2:  26 89 14          mov       word ptr es:[si], dx
0x0000000000000ae5:  3B 46 08          cmp       ax, word ptr [bp + 8]
0x0000000000000ae8:  7C CB             jl        0xab5
0x0000000000000aea:  31 C0             xor       ax, ax
0x0000000000000aec:  85 FF             test      di, di
0x0000000000000aee:  76 27             jbe       0xb17
0x0000000000000af0:  8B 76 2E          mov       si, word ptr [bp + 0x2e]
0x0000000000000af3:  8B 56 30          mov       dx, word ptr [bp + 0x30]
0x0000000000000af6:  8B 5E 06          mov       bx, word ptr [bp + 6]
0x0000000000000af9:  8B 4E 10          mov       cx, word ptr [bp + 0x10]
0x0000000000000afc:  89 56 6A          mov       word ptr [bp + 0x6a], dx
0x0000000000000aff:  8E C1             mov       es, cx
0x0000000000000b01:  83 C3 02          add       bx, 2
0x0000000000000b04:  83 C6 02          add       si, 2
0x0000000000000b07:  26 8B 57 FE       mov       dx, word ptr es:[bx - 2]
0x0000000000000b0b:  8E 46 6A          mov       es, word ptr [bp + 0x6a]
0x0000000000000b0e:  40                inc       ax
0x0000000000000b0f:  26 89 54 FE       mov       word ptr es:[si - 2], dx
0x0000000000000b13:  39 F8             cmp       ax, di
0x0000000000000b15:  72 E8             jb        0xaff
0x0000000000000b17:  8B 46 08          mov       ax, word ptr [bp + 8]
0x0000000000000b1a:  FF 06 5E 0E       inc       word ptr ds:[_maskedcount]
0x0000000000000b1e:  01 FF             add       di, di
0x0000000000000b20:  01 C0             add       ax, ax
0x0000000000000b22:  01 3E 62 0E       add       word ptr ds:[_currentpostdataoffset], di
0x0000000000000b26:  01 06 60 0E       add       word ptr ds:[_currentpostoffset], ax
0x0000000000000b2a:  01 06 64 0E       add       word ptr ds:[_currentpixeloffset], ax
0x0000000000000b2e:  C7 46 00 00 00    mov       word ptr [bp], 0
0x0000000000000b33:  30 C0             xor       al, al
0x0000000000000b35:  83 7E 08 00       cmp       word ptr [bp + 8], 0
0x0000000000000b39:  7F 03             jg        0xb3e
0x0000000000000b3b:  E9 81 00          jmp       0xbbf
0x0000000000000b3e:  8B 56 FC          mov       dx, word ptr [bp - 4]
0x0000000000000b41:  8B 5E 52          mov       bx, word ptr [bp + 0x52]
0x0000000000000b44:  8B 4E 54          mov       cx, word ptr [bp + 0x54]
0x0000000000000b47:  8B 76 40          mov       si, word ptr [bp + 0x40]
0x0000000000000b4a:  8B 7E 22          mov       di, word ptr [bp + 0x22]
0x0000000000000b4d:  89 4E 6C          mov       word ptr [bp + 0x6c], cx
0x0000000000000b50:  89 76 6E          mov       word ptr [bp + 0x6e], si
0x0000000000000b53:  8B 4E 3E          mov       cx, word ptr [bp + 0x3e]
0x0000000000000b56:  01 D2             add       dx, dx
0x0000000000000b58:  89 4E 70          mov       word ptr [bp + 0x70], cx
0x0000000000000b5b:  8B 4E 0E          mov       cx, word ptr [bp + 0xe]
0x0000000000000b5e:  8B 76 2C          mov       si, word ptr [bp + 0x2c]
0x0000000000000b61:  89 4E 72          mov       word ptr [bp + 0x72], cx
0x0000000000000b64:  8B 4E 24          mov       cx, word ptr [bp + 0x24]
0x0000000000000b67:  89 76 76          mov       word ptr [bp + 0x76], si
0x0000000000000b6a:  89 4E 74          mov       word ptr [bp + 0x74], cx
0x0000000000000b6d:  8E 46 6C          mov       es, word ptr [bp + 0x6c]
0x0000000000000b70:  26 80 3F 00       cmp       byte ptr es:[bx], 0
0x0000000000000b74:  75 03             jne       0xb79
0x0000000000000b76:  E9 28 01          jmp       0xca1
0x0000000000000b79:  26 80 3F 01       cmp       byte ptr es:[bx], 1
0x0000000000000b7d:  76 2B             jbe       0xbaa
0x0000000000000b7f:  8E 46 74          mov       es, word ptr [bp + 0x74]
0x0000000000000b82:  8B 76 76          mov       si, word ptr [bp + 0x76]
0x0000000000000b85:  B9 4B 4F          mov       cx, 0x4f4b
0x0000000000000b88:  26 C7 04 FF FF    mov       word ptr es:[si], 0xffff
0x0000000000000b8d:  8E C1             mov       es, cx
0x0000000000000b8f:  89 D6             mov       si, dx
0x0000000000000b91:  8B 4E 38          mov       cx, word ptr [bp + 0x38]
0x0000000000000b94:  26 01 0C          add       word ptr es:[si], cx
0x0000000000000b97:  8E 46 72          mov       es, word ptr [bp + 0x72]
0x0000000000000b9a:  8B 76 6E          mov       si, word ptr [bp + 0x6e]
0x0000000000000b9d:  26 88 05          mov       byte ptr es:[di], al
0x0000000000000ba0:  8E 46 70          mov       es, word ptr [bp + 0x70]
0x0000000000000ba3:  FE C0             inc       al
0x0000000000000ba5:  26 C7 04 FF 7F    mov       word ptr es:[si], 0x7fff
0x0000000000000baa:  83 46 6E 02       add       word ptr [bp + 0x6e], 2
0x0000000000000bae:  83 46 76 02       add       word ptr [bp + 0x76], 2
0x0000000000000bb2:  FF 46 00          inc       word ptr [bp]
0x0000000000000bb5:  43                inc       bx
0x0000000000000bb6:  8B 4E 00          mov       cx, word ptr [bp]
0x0000000000000bb9:  47                inc       di
0x0000000000000bba:  3B 4E 08          cmp       cx, word ptr [bp + 8]
0x0000000000000bbd:  7C AE             jl        0xb6d
0x0000000000000bbf:  8E 46 24          mov       es, word ptr [bp + 0x24]
0x0000000000000bc2:  8B 5E 2C          mov       bx, word ptr [bp + 0x2c]
0x0000000000000bc5:  C7 46 00 01 00    mov       word ptr [bp], 1
0x0000000000000bca:  31 D2             xor       dx, dx
0x0000000000000bcc:  26 8B 07          mov       ax, word ptr es:[bx]
0x0000000000000bcf:  8E 46 0E          mov       es, word ptr [bp + 0xe]
0x0000000000000bd2:  8B 5E 22          mov       bx, word ptr [bp + 0x22]
0x0000000000000bd5:  89 46 1E          mov       word ptr [bp + 0x1e], ax
0x0000000000000bd8:  26 8A 07          mov       al, byte ptr es:[bx]
0x0000000000000bdb:  83 7E 08 01       cmp       word ptr [bp + 8], 1
0x0000000000000bdf:  7F 03             jg        0xbe4
0x0000000000000be1:  E9 7D 00          jmp       0xc61
0x0000000000000be4:  8B 4E 24          mov       cx, word ptr [bp + 0x24]
0x0000000000000be7:  8D 77 01          lea       si, [bx + 1]
0x0000000000000bea:  8C 46 FE          mov       word ptr [bp - 2], es
0x0000000000000bed:  8B 5E 2C          mov       bx, word ptr [bp + 0x2c]
0x0000000000000bf0:  89 4E 78          mov       word ptr [bp + 0x78], cx
0x0000000000000bf3:  83 C3 02          add       bx, 2
0x0000000000000bf6:  8B 7E 00          mov       di, word ptr [bp]
0x0000000000000bf9:  8B 4E 1E          mov       cx, word ptr [bp + 0x1e]
0x0000000000000bfc:  8E 46 78          mov       es, word ptr [bp + 0x78]
0x0000000000000bff:  01 FF             add       di, di
0x0000000000000c01:  26 3B 0F          cmp       cx, word ptr es:[bx]
0x0000000000000c04:  75 03             jne       0xc09
0x0000000000000c06:  E9 AF 00          jmp       0xcb8
0x0000000000000c09:  8B 3E 5C 0E       mov       di, word ptr ds:[_currentlumpindex]
0x0000000000000c0d:  8B 4E 1E          mov       cx, word ptr [bp + 0x1e]
0x0000000000000c10:  01 FF             add       di, di
0x0000000000000c12:  8E 46 1A          mov       es, word ptr [bp + 0x1a]
0x0000000000000c15:  03 7E 18          add       di, word ptr [bp + 0x18]
0x0000000000000c18:  C6 46 7E 00       mov       byte ptr [bp + 0x7e], 0
0x0000000000000c1c:  26 89 0D          mov       word ptr es:[di], cx
0x0000000000000c1f:  8B 0E 5C 0E       mov       cx, word ptr ds:[_currentlumpindex]
0x0000000000000c23:  8A 66 00          mov       ah, byte ptr [bp]
0x0000000000000c26:  89 CF             mov       di, cx
0x0000000000000c28:  28 D4             sub       ah, dl
0x0000000000000c2a:  01 CF             add       di, cx
0x0000000000000c2c:  FE CC             dec       ah
0x0000000000000c2e:  03 7E 18          add       di, word ptr [bp + 0x18]
0x0000000000000c31:  8B 56 00          mov       dx, word ptr [bp]
0x0000000000000c34:  26 88 65 02       mov       byte ptr es:[di + 2], ah
0x0000000000000c38:  83 C1 02          add       cx, 2
0x0000000000000c3b:  26 88 45 03       mov       byte ptr es:[di + 3], al
0x0000000000000c3f:  8E 46 78          mov       es, word ptr [bp + 0x78]
0x0000000000000c42:  89 0E 5C 0E       mov       word ptr ds:[_currentlumpindex], cx
0x0000000000000c46:  26 8B 07          mov       ax, word ptr es:[bx]
0x0000000000000c49:  8E 46 FE          mov       es, word ptr [bp - 2]
0x0000000000000c4c:  89 46 1E          mov       word ptr [bp + 0x1e], ax
0x0000000000000c4f:  26 8A 04          mov       al, byte ptr es:[si]
0x0000000000000c52:  FF 46 00          inc       word ptr [bp]
0x0000000000000c55:  46                inc       si
0x0000000000000c56:  8B 4E 00          mov       cx, word ptr [bp]
0x0000000000000c59:  83 C3 02          add       bx, 2
0x0000000000000c5c:  3B 4E 08          cmp       cx, word ptr [bp + 8]
0x0000000000000c5f:  7C 95             jl        0xbf6
0x0000000000000c61:  80 7E 7E 00       cmp       byte ptr [bp + 0x7e], 0
0x0000000000000c65:  74 05             je        0xc6c
0x0000000000000c67:  8A 46 08          mov       al, byte ptr [bp + 8]
0x0000000000000c6a:  FE C8             dec       al
0x0000000000000c6c:  8B 0E 5C 0E       mov       cx, word ptr ds:[_currentlumpindex]
0x0000000000000c70:  89 CB             mov       bx, cx
0x0000000000000c72:  01 CB             add       bx, cx
0x0000000000000c74:  8E 46 1A          mov       es, word ptr [bp + 0x1a]
0x0000000000000c77:  03 5E 18          add       bx, word ptr [bp + 0x18]
0x0000000000000c7a:  26 88 47 03       mov       byte ptr es:[bx + 3], al
0x0000000000000c7e:  8B 46 1E          mov       ax, word ptr [bp + 0x1e]
0x0000000000000c81:  26 89 07          mov       word ptr es:[bx], ax
0x0000000000000c84:  8A 46 08          mov       al, byte ptr [bp + 8]
0x0000000000000c87:  28 D0             sub       al, dl
0x0000000000000c89:  83 C1 02          add       cx, 2
0x0000000000000c8c:  FE C8             dec       al
0x0000000000000c8e:  89 0E 5C 0E       mov       word ptr ds:[_currentlumpindex], cx
0x0000000000000c92:  26 88 47 02       mov       byte ptr es:[bx + 2], al
0x0000000000000c96:  8D A6 80 00       lea       sp, [bp + 0x80]
0x0000000000000c9a:  5D                pop       bp
0x0000000000000c9b:  5F                pop       di
0x0000000000000c9c:  5E                pop       si
0x0000000000000c9d:  5A                pop       dx
0x0000000000000c9e:  59                pop       cx
0x0000000000000c9f:  5B                pop       bx
0x0000000000000ca0:  CB                retf      
0x0000000000000ca1:  1E                push      ds
0x0000000000000ca2:  68 14 14          push      0x1414
0x0000000000000ca5:  0E                
0x0000000000000ca6:  3E E8 78 1A       call      I_Error_
0x0000000000000caa:  83 C4 04          add       sp, 4
0x0000000000000cad:  8D A6 80 00       lea       sp, [bp + 0x80]
0x0000000000000cb1:  5D                pop       bp
0x0000000000000cb2:  5F                pop       di
0x0000000000000cb3:  5E                pop       si
0x0000000000000cb4:  5A                pop       dx
0x0000000000000cb5:  59                pop       cx
0x0000000000000cb6:  5B                pop       bx
0x0000000000000cb7:  CB                retf      
0x0000000000000cb8:  8B 4E 00          mov       cx, word ptr [bp]
0x0000000000000cbb:  8E 46 3E          mov       es, word ptr [bp + 0x3e]
0x0000000000000cbe:  29 D1             sub       cx, dx
0x0000000000000cc0:  03 7E 40          add       di, word ptr [bp + 0x40]
0x0000000000000cc3:  26 3B 0D          cmp       cx, word ptr es:[di]
0x0000000000000cc6:  7C 03             jl        0xccb
0x0000000000000cc8:  E9 3E FF          jmp       0xc09
0x0000000000000ccb:  8E 46 78          mov       es, word ptr [bp + 0x78]
0x0000000000000cce:  26 83 3F FF       cmp       word ptr es:[bx], -1
0x0000000000000cd2:  75 03             jne       0xcd7
0x0000000000000cd4:  E9 7B FF          jmp       0xc52
0x0000000000000cd7:  8E 46 FE          mov       es, word ptr [bp - 2]
0x0000000000000cda:  26 3A 04          cmp       al, byte ptr es:[si]
0x0000000000000cdd:  75 E9             jne       0xcc8
0x0000000000000cdf:  E9 70 FF          jmp       0xc52

ENDP

PROC   R_InitTextures_ NEAR

0x0000000000000ce2:  53                push      bx
0x0000000000000ce3:  51                push      cx
0x0000000000000ce4:  52                push      dx
0x0000000000000ce5:  56                push      si
0x0000000000000ce6:  57                push      di
0x0000000000000ce7:  55                push      bp
0x0000000000000ce8:  89 E5             mov       bp, sp
0x0000000000000cea:  81 EC D8 03       sub       sp, 03d8h
0x0000000000000cee:  B8 17 14          mov       ax, 0x1417
0x0000000000000cf1:  BB 26 01          mov       bx, 0x126
0x0000000000000cf4:  0E                
0x0000000000000cf5:  E8 4C 9D          call      W_GetNumForName_
0x0000000000000cf8:  90                       
0x0000000000000cf9:  40                inc       ax
0x0000000000000cfa:  89 07             mov       word ptr ds:[bx], ax
0x0000000000000cfc:  B8 1F 14          mov       ax, 0x141f
0x0000000000000cff:  0E                
0x0000000000000d00:  3E E8 40 9D       call      W_GetNumForName_
0x0000000000000d04:  48                dec       ax
0x0000000000000d05:  2B 07             sub       ax, word ptr ds:[bx]
0x0000000000000d07:  40                inc       ax
0x0000000000000d08:  A3 96 18          mov       word ptr ds:[_numpatches], ax
0x0000000000000d0b:  B8 25 14          mov       ax, 0x1425
0x0000000000000d0e:  BB 6E 01          mov       bx, 0x16e
0x0000000000000d11:  0E                
0x0000000000000d12:  3E E8 2E 9D       call      W_GetNumForName_
0x0000000000000d16:  40                inc       ax
0x0000000000000d17:  89 07             mov       word ptr ds:[bx], ax
0x0000000000000d19:  B8 2D 14          mov       ax, 0x142d
0x0000000000000d1c:  0E                
0x0000000000000d1d:  E8 24 9D          call      W_GetNumForName_
0x0000000000000d20:  90                       
0x0000000000000d21:  48                dec       ax
0x0000000000000d22:  2B 07             sub       ax, word ptr ds:[bx]
0x0000000000000d24:  40                inc       ax
0x0000000000000d25:  A3 9C 18          mov       word ptr ds:[_numflats], ax
0x0000000000000d28:  B8 33 14          mov       ax, 0x1433
0x0000000000000d2b:  BB E6 00          mov       bx, 0xe6
0x0000000000000d2e:  0E                
0x0000000000000d2f:  E8 12 9D          call      W_GetNumForName_
0x0000000000000d32:  90                       
0x0000000000000d33:  40                inc       ax
0x0000000000000d34:  89 07             mov       word ptr ds:[bx], ax
0x0000000000000d36:  B8 3B 14          mov       ax, 0x143b
0x0000000000000d39:  0E                
0x0000000000000d3a:  3E E8 06 9D       call      W_GetNumForName_
0x0000000000000d3e:  48                dec       ax
0x0000000000000d3f:  2B 07             sub       ax, word ptr ds:[bx]
0x0000000000000d41:  B9 00 70          mov       cx, 0x7000
0x0000000000000d44:  40                inc       ax
0x0000000000000d45:  31 DB             xor       bx, bx
0x0000000000000d47:  A3 9A 18          mov       word ptr ds:[_numspritelumps], ax
0x0000000000000d4a:  B8 41 14          mov       ax, 0x1441
0x0000000000000d4d:  C6 46 DC 00       mov       byte ptr [bp - 0x24], 0
0x0000000000000d51:  0E                
0x0000000000000d52:  3E E8 F0 9D       call      W_CacheLumpNameDirect_
0x0000000000000d56:  B8 00 70          mov       ax, 0x7000
0x0000000000000d59:  31 DB             xor       bx, bx
0x0000000000000d5b:  8E C0             mov       es, ax
0x0000000000000d5d:  C7 46 EA 00 70    mov       word ptr [bp - 0x16], 0x7000
0x0000000000000d62:  26 8B 07          mov       ax, word ptr es:[bx]
0x0000000000000d65:  89 5E E8          mov       word ptr [bp - 0x18], bx
0x0000000000000d68:  89 46 E2          mov       word ptr [bp - 0x1e], ax
0x0000000000000d6b:  85 C0             test      ax, ax
0x0000000000000d6d:  7E 30             jle       0xd9f
0x0000000000000d6f:  BE 04 00          mov       si, 4
0x0000000000000d72:  8C 46 E0          mov       word ptr [bp - 0x20], es
0x0000000000000d75:  31 FF             xor       di, di
0x0000000000000d77:  8B 4E E0          mov       cx, word ptr [bp - 0x20]
0x0000000000000d7a:  8D 46 D4          lea       ax, [bp - 0x2c]
0x0000000000000d7d:  89 F3             mov       bx, si
0x0000000000000d7f:  8C DA             mov       dx, ds
0x0000000000000d81:  E8 FA 59          call      copystr8_
0x0000000000000d84:  83 C7 02          add       di, 2
0x0000000000000d87:  8D 46 D4          lea       ax, [bp - 0x2c]
0x0000000000000d8a:  FF 46 E8          inc       word ptr [bp - 0x18]
0x0000000000000d8d:  E8 10 9E          call      W_CheckNumForName_
0x0000000000000d90:  89 83 26 FC       mov       word ptr [bp + di - 0x3da], ax
0x0000000000000d94:  8B 46 E8          mov       ax, word ptr [bp - 0x18]
0x0000000000000d97:  83 C6 08          add       si, 8
0x0000000000000d9a:  3B 46 E2          cmp       ax, word ptr [bp - 0x1e]
0x0000000000000d9d:  7C D8             jl        0xd77
0x0000000000000d9f:  B9 00 70          mov       cx, 0x7000
0x0000000000000da2:  B8 48 14          mov       ax, 0x1448
0x0000000000000da5:  31 DB             xor       bx, bx
0x0000000000000da7:  0E                
0x0000000000000da8:  3E E8 9A 9D       call      W_CacheLumpNameDirect_
0x0000000000000dac:  B8 00 70          mov       ax, 0x7000
0x0000000000000daf:  31 DB             xor       bx, bx
0x0000000000000db1:  8E C0             mov       es, ax
0x0000000000000db3:  26 8B 07          mov       ax, word ptr es:[bx]
0x0000000000000db6:  C7 46 DE 04 00    mov       word ptr [bp - 0x22], 4
0x0000000000000dbb:  89 46 E4          mov       word ptr [bp - 0x1c], ax
0x0000000000000dbe:  A3 98 18          mov       word ptr ds:[_numtextures], ax
0x0000000000000dc1:  B8 51 14          mov       ax, 0x1451
0x0000000000000dc4:  8C 46 E6          mov       word ptr [bp - 0x1a], es
0x0000000000000dc7:  E8 D6 9D          call      W_CheckNumForName_
0x0000000000000dca:  3D FF FF          cmp       ax, 0xffff
0x0000000000000dcd:  74 19             je        0xde8
0x0000000000000dcf:  B9 00 78          mov       cx, 0x7800
0x0000000000000dd2:  B8 51 14          mov       ax, 0x1451
0x0000000000000dd5:  0E                
0x0000000000000dd6:  3E E8 6C 9D       call      W_CacheLumpNameDirect_
0x0000000000000dda:  B8 00 78          mov       ax, 0x7800
0x0000000000000ddd:  31 DB             xor       bx, bx
0x0000000000000ddf:  8E C0             mov       es, ax
0x0000000000000de1:  26 8B 07          mov       ax, word ptr es:[bx]
0x0000000000000de4:  01 06 98 18       add       word ptr ds:[_numtextures], ax
0x0000000000000de8:  B8 3B 14          mov       ax, 0x143b
0x0000000000000deb:  0E                
0x0000000000000dec:  3E E8 54 9C       call      W_GetNumForName_
0x0000000000000df0:  89 C2             mov       dx, ax
0x0000000000000df2:  89 D7             mov       di, dx
0x0000000000000df4:  B8 33 14          mov       ax, 0x1433
0x0000000000000df7:  4F                dec       di
0x0000000000000df8:  0E                
0x0000000000000df9:  E8 48 9C          call      W_GetNumForName_
0x0000000000000dfc:  90                       
0x0000000000000dfd:  29 C7             sub       di, ax
0x0000000000000dff:  8D 45 3F          lea       ax, [di + 0x3f]
0x0000000000000e02:  99                cwd       
0x0000000000000e03:  C1 E2 06          shl       dx, 6
0x0000000000000e06:  1B C2             sbb       ax, dx
0x0000000000000e08:  C1 F8 06          sar       ax, 6
0x0000000000000e0b:  89 C7             mov       di, ax
0x0000000000000e0d:  A1 98 18          mov       ax, word ptr ds:[_numtextures]
0x0000000000000e10:  05 3F 00          add       ax, 0x3f
0x0000000000000e13:  99                cwd       
0x0000000000000e14:  C1 E2 06          shl       dx, 6
0x0000000000000e17:  1B C2             sbb       ax, dx
0x0000000000000e19:  C1 F8 06          sar       ax, 6
0x0000000000000e1c:  1E                push      ds
0x0000000000000e1d:  31 F6             xor       si, si
0x0000000000000e1f:  68 5A 14          push      0x145a
0x0000000000000e22:  01 C7             add       di, ax
0x0000000000000e24:  0E                
0x0000000000000e25:  E8 B8 1A          call      DEBUG_PRINT_
0x0000000000000e28:  90                       
0x0000000000000e29:  83 C4 04          add       sp, 4
0x0000000000000e2c:  85 FF             test      di, di
0x0000000000000e2e:  7E 11             jle       0xe41
0x0000000000000e30:  1E                push      ds
0x0000000000000e31:  68 5C 14          push      0x145c
0x0000000000000e34:  46                inc       si
0x0000000000000e35:  0E                
0x0000000000000e36:  3E E8 A6 1A       call      DEBUG_PRINT_
0x0000000000000e3a:  83 C4 04          add       sp, 4
0x0000000000000e3d:  39 FE             cmp       si, di
0x0000000000000e3f:  7C EF             jl        0xe30
0x0000000000000e41:  1E                push      ds
0x0000000000000e42:  68 5E 14          push      0x145e
0x0000000000000e45:  31 D2             xor       dx, dx
0x0000000000000e47:  0E                
0x0000000000000e48:  3E E8 94 1A       call      DEBUG_PRINT_
0x0000000000000e4c:  83 C4 04          add       sp, 4
0x0000000000000e4f:  85 FF             test      di, di
0x0000000000000e51:  7E 11             jle       0xe64
0x0000000000000e53:  1E                push      ds
0x0000000000000e54:  68 69 14          push      0x1469
0x0000000000000e57:  42                inc       dx
0x0000000000000e58:  0E                
0x0000000000000e59:  E8 84 1A          call      DEBUG_PRINT_
0x0000000000000e5c:  90                       
0x0000000000000e5d:  83 C4 04          add       sp, 4
0x0000000000000e60:  39 FA             cmp       dx, di
0x0000000000000e62:  7C EF             jl        0xe53
0x0000000000000e64:  1E                push      ds
0x0000000000000e65:  68 6B 14          push      0x146b
0x0000000000000e68:  C7 46 F0 00 00    mov       word ptr [bp - 0x10], 0
0x0000000000000e6d:  0E                
0x0000000000000e6e:  3E E8 6E 1A       call      DEBUG_PRINT_
0x0000000000000e72:  83 C4 04          add       sp, 4
0x0000000000000e75:  83 3E 98 18 00    cmp       word ptr ds:[_numtextures], 0
0x0000000000000e7a:  7F 03             jg        0xe7f
0x0000000000000e7c:  E9 C2 01          jmp       0x1041
0x0000000000000e7f:  C7 46 EC 02 00    mov       word ptr [bp - 0x14], 2
0x0000000000000e84:  C7 46 EE 00 00    mov       word ptr [bp - 0x12], 0
0x0000000000000e89:  F6 46 F0 3F       test      byte ptr [bp - 0x10], 0x3f
0x0000000000000e8d:  75 03             jne       0xe92
0x0000000000000e8f:  E9 D8 00          jmp       0xf6a
0x0000000000000e92:  8B 46 F0          mov       ax, word ptr [bp - 0x10]
0x0000000000000e95:  3B 46 E4          cmp       ax, word ptr [bp - 0x1c]
0x0000000000000e98:  75 0F             jne       0xea9
0x0000000000000e9a:  C7 46 EA 00 78    mov       word ptr [bp - 0x16], 0x7800
0x0000000000000e9f:  C7 46 DE 04 00    mov       word ptr [bp - 0x22], 4
0x0000000000000ea4:  C7 46 E6 00 78    mov       word ptr [bp - 0x1a], 0x7800
0x0000000000000ea9:  8E 46 E6          mov       es, word ptr [bp - 0x1a]
0x0000000000000eac:  8B 46 F0          mov       ax, word ptr [bp - 0x10]
0x0000000000000eaf:  8B 76 DE          mov       si, word ptr [bp - 0x22]
0x0000000000000eb2:  40                inc       ax
0x0000000000000eb3:  26 8B 34          mov       si, word ptr es:[si]
0x0000000000000eb6:  8E 46 EA          mov       es, word ptr [bp - 0x16]
0x0000000000000eb9:  89 F3             mov       bx, si
0x0000000000000ebb:  8C C2             mov       dx, es
0x0000000000000ebd:  3B 06 98 18       cmp       ax, word ptr ds:[_numtextures]
0x0000000000000ec1:  7D 03             jge       0xec6
0x0000000000000ec3:  E9 B3 00          jmp       0xf79
0x0000000000000ec6:  B8 2D 93          mov       ax, 0x932d
0x0000000000000ec9:  8B 76 EE          mov       si, word ptr [bp - 0x12]
0x0000000000000ecc:  8E C0             mov       es, ax
0x0000000000000ece:  26 8B 34          mov       si, word ptr es:[si]
0x0000000000000ed1:  8E C2             mov       es, dx
0x0000000000000ed3:  C7 46 F6 B2 90    mov       word ptr [bp - 0xa], 0x90b2
0x0000000000000ed8:  26 8A 47 0C       mov       al, byte ptr es:[bx + 0xc]
0x0000000000000edc:  8E 46 F6          mov       es, word ptr [bp - 0xa]
0x0000000000000edf:  FE C8             dec       al
0x0000000000000ee1:  26 88 44 08       mov       byte ptr es:[si + 8], al
0x0000000000000ee5:  8E C2             mov       es, dx
0x0000000000000ee7:  26 8A 47 0E       mov       al, byte ptr es:[bx + 0xe]
0x0000000000000eeb:  8E 46 F6          mov       es, word ptr [bp - 0xa]
0x0000000000000eee:  FE C8             dec       al
0x0000000000000ef0:  26 88 44 09       mov       byte ptr es:[si + 9], al
0x0000000000000ef4:  8E C2             mov       es, dx
0x0000000000000ef6:  26 8A 47 14       mov       al, byte ptr es:[bx + 0x14]
0x0000000000000efa:  8E 46 F6          mov       es, word ptr [bp - 0xa]
0x0000000000000efd:  C7 46 FC B2 90    mov       word ptr [bp - 4], 0x90b2
0x0000000000000f02:  26 88 44 0A       mov       byte ptr es:[si + 0xa], al
0x0000000000000f06:  C7 46 F8 B2 90    mov       word ptr [bp - 8], 0x90b2
0x0000000000000f0b:  26 8A 44 08       mov       al, byte ptr es:[si + 8]
0x0000000000000f0f:  89 D1             mov       cx, dx
0x0000000000000f11:  30 E4             xor       ah, ah
0x0000000000000f13:  89 76 F4          mov       word ptr [bp - 0xc], si
0x0000000000000f16:  40                inc       ax
0x0000000000000f17:  8B 7E F4          mov       di, word ptr [bp - 0xc]
0x0000000000000f1a:  89 46 F2          mov       word ptr [bp - 0xe], ax
0x0000000000000f1d:  26 8A 44 09       mov       al, byte ptr es:[si + 9]
0x0000000000000f21:  8E 46 FC          mov       es, word ptr [bp - 4]
0x0000000000000f24:  88 46 FE          mov       byte ptr [bp - 2], al
0x0000000000000f27:  89 DE             mov       si, bx
0x0000000000000f29:  B8 08 00          mov       ax, 8
0x0000000000000f2c:  C7 46 FA 00 00    mov       word ptr [bp - 6], 0
0x0000000000000f31:  1E                push      ds
0x0000000000000f32:  57                push      di
0x0000000000000f33:  91                xchg      ax, cx
0x0000000000000f34:  8E D8             mov       ds, ax
0x0000000000000f36:  D1 E9             shr       cx, 1
0x0000000000000f38:  F3 A5             rep movsw word ptr es:[di], word ptr ds:[si]
0x0000000000000f3a:  13 C9             adc       cx, cx
0x0000000000000f3c:  F3 A4             rep movsb byte ptr es:[di], byte ptr ds:[si]
0x0000000000000f3e:  5F                pop       di
0x0000000000000f3f:  1F                pop       ds
0x0000000000000f40:  83 C3 16          add       bx, 0x16
0x0000000000000f43:  89 D1             mov       cx, dx
0x0000000000000f45:  8D 75 0B          lea       si, [di + 0xb]
0x0000000000000f48:  C4 7E F4          les       di, ptr [bp - 0xc]
0x0000000000000f4b:  26 8A 45 0A       mov       al, byte ptr es:[di + 0xa]
0x0000000000000f4f:  30 E4             xor       ah, ah
0x0000000000000f51:  3B 46 FA          cmp       ax, word ptr [bp - 6]
0x0000000000000f54:  7F 42             jg        0xf98
0x0000000000000f56:  C7 46 FA 01 00    mov       word ptr [bp - 6], 1
0x0000000000000f5b:  8B 46 FA          mov       ax, word ptr [bp - 6]
0x0000000000000f5e:  01 C0             add       ax, ax
0x0000000000000f60:  3B 46 F2          cmp       ax, word ptr [bp - 0xe]
0x0000000000000f63:  7F 79             jg        0xfde
0x0000000000000f65:  89 46 FA          mov       word ptr [bp - 6], ax
0x0000000000000f68:  EB F1             jmp       0xf5b
0x0000000000000f6a:  1E                push      ds
0x0000000000000f6b:  68 12 14          push      0x1412
0x0000000000000f6e:  0E                
0x0000000000000f6f:  E8 6E 19          call      DEBUG_PRINT_
0x0000000000000f72:  90                       
0x0000000000000f73:  83 C4 04          add       sp, 4
0x0000000000000f76:  E9 19 FF          jmp       0xe92
0x0000000000000f79:  26 8B 44 14       mov       ax, word ptr es:[si + 0x14]
0x0000000000000f7d:  B9 2D 93          mov       cx, 0x932d
0x0000000000000f80:  48                dec       ax
0x0000000000000f81:  8B 76 EE          mov       si, word ptr [bp - 0x12]
0x0000000000000f84:  C1 E0 02          shl       ax, 2
0x0000000000000f87:  8E C1             mov       es, cx
0x0000000000000f89:  05 0F 00          add       ax, 0xf
0x0000000000000f8c:  26 03 04          add       ax, word ptr es:[si]
0x0000000000000f8f:  8B 76 EC          mov       si, word ptr [bp - 0x14]
0x0000000000000f92:  26 89 04          mov       word ptr es:[si], ax
0x0000000000000f95:  E9 2E FF          jmp       0xec6
0x0000000000000f98:  8E C1             mov       es, cx
0x0000000000000f9a:  26 8B 07          mov       ax, word ptr es:[bx]
0x0000000000000f9d:  99                cwd       
0x0000000000000f9e:  33 C2             xor       ax, dx
0x0000000000000fa0:  2B C2             sub       ax, dx
0x0000000000000fa2:  8E 46 F8          mov       es, word ptr [bp - 8]
0x0000000000000fa5:  26 88 04          mov       byte ptr es:[si], al
0x0000000000000fa8:  8E C1             mov       es, cx
0x0000000000000faa:  26 8A 47 02       mov       al, byte ptr es:[bx + 2]
0x0000000000000fae:  8E 46 F8          mov       es, word ptr [bp - 8]
0x0000000000000fb1:  26 88 44 01       mov       byte ptr es:[si + 1], al
0x0000000000000fb5:  8E C1             mov       es, cx
0x0000000000000fb7:  26 8B 7F 04       mov       di, word ptr es:[bx + 4]
0x0000000000000fbb:  01 FF             add       di, di
0x0000000000000fbd:  26 83 3F 00       cmp       word ptr es:[bx], 0
0x0000000000000fc1:  7C 1D             jl        0xfe0
0x0000000000000fc3:  31 D2             xor       dx, dx
0x0000000000000fc5:  FF 46 FA          inc       word ptr [bp - 6]
0x0000000000000fc8:  83 C6 04          add       si, 4
0x0000000000000fcb:  8B 83 28 FC       mov       ax, word ptr [bp + di - 0x3d8]
0x0000000000000fcf:  8E 46 F8          mov       es, word ptr [bp - 8]
0x0000000000000fd2:  01 D0             add       ax, dx
0x0000000000000fd4:  83 C3 0A          add       bx, 0xa
0x0000000000000fd7:  26 89 44 FE       mov       word ptr es:[si - 2], ax
0x0000000000000fdb:  E9 6A FF          jmp       0xf48
0x0000000000000fde:  EB 05             jmp       0xfe5
0x0000000000000fe0:  BA 00 80          mov       dx, 0x8000
0x0000000000000fe3:  EB E0             jmp       0xfc5
0x0000000000000fe5:  8A 46 FA          mov       al, byte ptr [bp - 6]
0x0000000000000fe8:  BA A2 82          mov       dx, 0x82a2
0x0000000000000feb:  8B 5E F0          mov       bx, word ptr [bp - 0x10]
0x0000000000000fee:  8E C2             mov       es, dx
0x0000000000000ff0:  FE C8             dec       al
0x0000000000000ff2:  26 88 07          mov       byte ptr es:[bx], al
0x0000000000000ff5:  B8 99 3C          mov       ax, 0x3c99
0x0000000000000ff8:  8E C0             mov       es, ax
0x0000000000000ffa:  8A 46 FE          mov       al, byte ptr [bp - 2]
0x0000000000000ffd:  26 88 07          mov       byte ptr es:[bx], al
0x0000000000001000:  30 E4             xor       ah, ah
0x0000000000001002:  40                inc       ax
0x0000000000001003:  89 C2             mov       dx, ax
0x0000000000001005:  30 E6             xor       dh, ah
0x0000000000001007:  BB 10 00          mov       bx, 0x10
0x000000000000100a:  80 E2 0F          and       dl, 0xf
0x000000000000100d:  29 D3             sub       bx, dx
0x000000000000100f:  89 DA             mov       dx, bx
0x0000000000001011:  83 46 EC 02       add       word ptr [bp - 0x14], 2
0x0000000000001015:  30 FE             xor       dh, bh
0x0000000000001017:  83 46 EE 02       add       word ptr [bp - 0x12], 2
0x000000000000101b:  80 E2 0F          and       dl, 0xf
0x000000000000101e:  8B 5E F0          mov       bx, word ptr [bp - 0x10]
0x0000000000001021:  01 D0             add       ax, dx
0x0000000000001023:  BA 30 4F          mov       dx, 0x4f30
0x0000000000001026:  C1 F8 04          sar       ax, 4
0x0000000000001029:  8E C2             mov       es, dx
0x000000000000102b:  FF 46 F0          inc       word ptr [bp - 0x10]
0x000000000000102e:  26 88 07          mov       byte ptr es:[bx], al
0x0000000000001031:  8B 46 F0          mov       ax, word ptr [bp - 0x10]
0x0000000000001034:  83 46 DE 04       add       word ptr [bp - 0x22], 4
0x0000000000001038:  3B 06 98 18       cmp       ax, word ptr ds:[_numtextures]
0x000000000000103c:  7D 03             jge       0x1041
0x000000000000103e:  E9 48 FE          jmp       0xe89
0x0000000000001041:  C9                LEAVE_MACRO     
0x0000000000001042:  5F                pop       di
0x0000000000001043:  5E                pop       si
0x0000000000001044:  5A                pop       dx
0x0000000000001045:  59                pop       cx
0x0000000000001046:  5B                pop       bx
0x0000000000001047:  CB                retf      

ENDP

PROC   R_InitTextures2_ NEAR


0x0000000000001048:  53                push      bx
0x0000000000001049:  52                push      dx
0x000000000000104a:  56                push      si
0x000000000000104b:  0E                
0x000000000000104c:  3E E8 97 A4       call      Z_QuickMapMaskedExtraData_
0x0000000000001050:  0E                
0x0000000000001051:  E8 EE A3          call      Z_QuickMapScratch_7000_
0x0000000000001054:  90                       
0x0000000000001055:  BA 2D 93          mov       dx, 0x932d
0x0000000000001058:  31 DB             xor       bx, bx
0x000000000000105a:  8E C2             mov       es, dx
0x000000000000105c:  31 D2             xor       dx, dx
0x000000000000105e:  26 89 1F          mov       word ptr es:[bx], bx
0x0000000000001061:  83 3E 98 18 00    cmp       word ptr ds:[_numtextures], 0
0x0000000000001066:  7E 26             jle       0x108e
0x0000000000001068:  BE 4B 4F          mov       si, 0x4f4b
0x000000000000106b:  8E C6             mov       es, si
0x000000000000106d:  89 DE             mov       si, bx
0x000000000000106f:  26 C7 04 00 00    mov       word ptr es:[si], 0
0x0000000000001074:  BE 63 3C          mov       si, 0x3c63
0x0000000000001077:  8E C6             mov       es, si
0x0000000000001079:  89 DE             mov       si, bx
0x000000000000107b:  89 D0             mov       ax, dx
0x000000000000107d:  26 89 14          mov       word ptr es:[si], dx
0x0000000000001080:  0E                
0x0000000000001081:  E8 A4 F6          call      R_GenerateLookup_
0x0000000000001084:  42                inc       dx
0x0000000000001085:  83 C3 02          add       bx, 2
0x0000000000001088:  3B 16 98 18       cmp       dx, word ptr ds:[_numtextures]
0x000000000000108c:  7C DA             jl        0x1068
0x000000000000108e:  0E                
0x000000000000108f:  E8 B8 A2          call      Z_QuickMapRender_
0x0000000000001092:  90                       
0x0000000000001093:  5E                pop       si
0x0000000000001094:  5A                pop       dx
0x0000000000001095:  5B                pop       bx
0x0000000000001096:  CB                retf      

ENDP

PROC   R_InitPatches_ NEAR


0x0000000000001098:  53                push      bx
0x0000000000001099:  51                push      cx
0x000000000000109a:  52                push      dx
0x000000000000109b:  56                push      si
0x000000000000109c:  57                push      di
0x000000000000109d:  BF 00 70          mov       di, 0x7000
0x00000000000010a0:  31 F6             xor       si, si
0x00000000000010a2:  31 D2             xor       dx, dx
0x00000000000010a4:  83 3E 96 18 00    cmp       word ptr ds:[_numpatches], 0
0x00000000000010a9:  7E 53             jle       0x10fe
0x00000000000010ab:  BB 26 01          mov       bx, 0x126
0x00000000000010ae:  8B 07             mov       ax, word ptr ds:[bx]
0x00000000000010b0:  B9 00 70          mov       cx, 0x7000
0x00000000000010b3:  01 D0             add       ax, dx
0x00000000000010b5:  31 DB             xor       bx, bx
0x00000000000010b7:  0E                
0x00000000000010b8:  3E E8 AA 9A       call      W_CacheLumpNameDirect_
0x00000000000010bc:  B9 7E 93          mov       cx, 0x937e
0x00000000000010bf:  8E C7             mov       es, di
0x00000000000010c1:  89 D3             mov       bx, dx
0x00000000000010c3:  26 8A 04          mov       al, byte ptr es:[si]
0x00000000000010c6:  8E C1             mov       es, cx
0x00000000000010c8:  26 88 07          mov       byte ptr es:[bx], al
0x00000000000010cb:  8E C7             mov       es, di
0x00000000000010cd:  26 8B 44 02       mov       ax, word ptr es:[si + 2]
0x00000000000010d1:  89 C3             mov       bx, ax
0x00000000000010d3:  30 E7             xor       bh, ah
0x00000000000010d5:  B9 10 00          mov       cx, 0x10
0x00000000000010d8:  80 E3 0F          and       bl, 0xf
0x00000000000010db:  29 D9             sub       cx, bx
0x00000000000010dd:  89 CB             mov       bx, cx
0x00000000000010df:  30 EF             xor       bh, ch
0x00000000000010e1:  80 E3 0F          and       bl, 0xf
0x00000000000010e4:  01 D8             add       ax, bx
0x00000000000010e6:  89 C3             mov       bx, ax
0x00000000000010e8:  C1 FB 04          sar       bx, 4
0x00000000000010eb:  09 D8             or        ax, bx
0x00000000000010ed:  BB 9C 93          mov       bx, 0x939c
0x00000000000010f0:  8E C3             mov       es, bx
0x00000000000010f2:  89 D3             mov       bx, dx
0x00000000000010f4:  42                inc       dx
0x00000000000010f5:  26 88 07          mov       byte ptr es:[bx], al
0x00000000000010f8:  3B 16 96 18       cmp       dx, word ptr ds:[_numpatches]
0x00000000000010fc:  7C AD             jl        0x10ab
0x00000000000010fe:  5F                pop       di
0x00000000000010ff:  5E                pop       si
0x0000000000001100:  5A                pop       dx
0x0000000000001101:  59                pop       cx
0x0000000000001102:  5B                pop       bx
0x0000000000001103:  C3                ret       

ENDP

PROC   R_InitData_ NEAR


0x0000000000001104:  53                push      bx
0x0000000000001105:  52                push      dx
0x0000000000001106:  B8 2D 93          mov       ax, 0x932d
0x0000000000001109:  8E C0             mov       es, ax
0x000000000000110b:  31 DB             xor       bx, bx
0x000000000000110d:  26 89 1F          mov       word ptr es:[bx], bx
0x0000000000001110:  0E                
0x0000000000001111:  E8 CE FB          call      R_InitTextures_
0x0000000000001114:  0E                
0x0000000000001115:  E8 30 FF          call      R_InitTextures2_
0x0000000000001118:  1E                push      ds
0x0000000000001119:  68 76 14          push      0x1476
0x000000000000111c:  0E                
0x000000000000111d:  E8 C0 17          call      DEBUG_PRINT_
0x0000000000001120:  90                       
0x0000000000001121:  83 C4 04          add       sp, 4
0x0000000000001124:  30 D2             xor       dl, dl
0x0000000000001126:  E8 6F FF          call      R_InitPatches_
0x0000000000001129:  88 D0             mov       al, dl
0x000000000000112b:  30 E4             xor       ah, ah
0x000000000000112d:  3B 06 9C 18       cmp       ax, word ptr ds:[_numflats]
0x0000000000001131:  7D 0E             jge       0x1141
0x0000000000001133:  BB 59 3C          mov       bx, 0x3c59
0x0000000000001136:  8E C3             mov       es, bx
0x0000000000001138:  89 C3             mov       bx, ax
0x000000000000113a:  26 88 17          mov       byte ptr es:[bx], dl
0x000000000000113d:  FE C2             inc       dl
0x000000000000113f:  EB E8             jmp       0x1129
0x0000000000001141:  0E                
0x0000000000001142:  E8 4B F4          call      R_InitSpriteLumps_
0x0000000000001145:  1E                push      ds
0x0000000000001146:  68 12 14          push      0x1412
0x0000000000001149:  0E                
0x000000000000114a:  3E E8 92 17       call      DEBUG_PRINT_
0x000000000000114e:  83 C4 04          add       sp, 4
0x0000000000001151:  5A                pop       dx
0x0000000000001152:  5B                pop       bx
0x0000000000001153:  C3                ret       


ENDP

PROC   R_Init_ NEAR


0x0000000000001154:  53                push      bx
0x0000000000001155:  51                push      cx
0x0000000000001156:  52                push      dx
0x0000000000001157:  0E                
0x0000000000001158:  3E E8 EE A1       call      Z_QuickMapRender_
0x000000000000115c:  B9 00 98          mov       cx, 0x9800
0x000000000000115f:  B8 01 00          mov       ax, 1
0x0000000000001162:  31 DB             xor       bx, bx
0x0000000000001164:  0E                
0x0000000000001165:  E8 FE 99          call      W_CacheLumpNameDirect_
0x0000000000001168:  90                       
0x0000000000001169:  E8 98 FF          call      R_InitData_
0x000000000000116c:  1E                push      ds
0x000000000000116d:  68 76 14          push      0x1476
0x0000000000001170:  BB 69 0A          mov       bx, 0xa69
0x0000000000001173:  0E                
0x0000000000001174:  3E E8 68 17       call      DEBUG_PRINT_
0x0000000000001178:  8A 07             mov       al, byte ptr ds:[bx]
0x000000000000117a:  83 C4 04          add       sp, 4
0x000000000000117d:  30 E4             xor       ah, ah
0x000000000000117f:  BB 9B 01          mov       bx, 0x19b
0x0000000000001182:  89 C2             mov       dx, ax
0x0000000000001184:  8A 07             mov       al, byte ptr ds:[bx]
0x0000000000001186:  0E                
0x0000000000001187:  E8 F5 96          call      R_SetViewSize_
0x000000000000118a:  90                       
0x000000000000118b:  1E                push      ds
0x000000000000118c:  68 79 14          push      0x1479
0x000000000000118f:  0E                
0x0000000000001190:  3E E8 4C 17       call      DEBUG_PRINT_
0x0000000000001194:  83 C4 04          add       sp, 4
0x0000000000001197:  0E                
0x0000000000001198:  3E E8 68 A1       call      Z_QuickMapPhysics_
0x000000000000119c:  B8 7D 14          mov       ax, 0x147d
0x000000000000119f:  E8 EE 1A          call      R_FlatNumForName_
0x00000000000011a2:  1E                push      ds
0x00000000000011a3:  BB 98 01          mov       bx, 0x198
0x00000000000011a6:  68 12 14          push      0x1412
0x00000000000011a9:  88 07             mov       byte ptr ds:[bx], al
0x00000000000011ab:  0E                
0x00000000000011ac:  3E E8 30 17       call      DEBUG_PRINT_
0x00000000000011b0:  83 C4 04          add       sp, 4
0x00000000000011b3:  5A                pop       dx
0x00000000000011b4:  59                pop       cx
0x00000000000011b5:  5B                pop       bx
0x00000000000011b6:  C3                ret     


ENDP

@

END
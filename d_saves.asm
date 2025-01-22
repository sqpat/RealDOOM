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




;EXTRN _playerMobjRef:WORD

EXTRN _player:PLAYER_T

.CODE
 
PROC P_SAVESTART_
PUBLIC P_SAVESTART_
ENDP

_CSDATA_playerMobjRef_ptr:
dw    0
_CSDATA_player_ptr:
dw    0



PROC P_ArchivePlayers_ FAR
PUBLIC P_ArchivePlayers_


push      bx
push      cx
push      dx
push      si
push      di
push      bp
mov       bp, sp
sub       sp, 4
mov       bx, _save_p
mov       ax, word ptr [bx]
mov       dx, 4
and       ax, 3
sub       dx, ax
mov       ax, dx
mov       si, bx
and       ax, 3
add       word ptr [bx], ax
mov       cx, SIZEOF_PLAYER_VANILLA_T
mov       ax, word ptr [si + 2]
mov       bx, word ptr [bx]
mov       word ptr [bp - 2], ax
mov       di, bx
mov       es, word ptr [bp - 2]
xor       al, al
push      di
mov       ah, al
shr       cx, 1
rep stosw
adc       cx, cx
rep stosb
pop       di
mov       al, byte ptr ds:[_player + 01Dh]
mov       word ptr es:[bx + 6], 0
xor       ah, ah
mov       word ptr es:[bx + 4], ax
mov       si, OFFSET _player
lea       di, [di + 8]
movsw     
movsw     
movsw     
movsw     
mov       dx, word ptr ds:[_player + 08h]
mov       ax, word ptr ds:[_player + 0Ah]
mov       word ptr es:[bx + 010h], dx
mov       word ptr es:[bx + 012h], ax
mov       ax, word ptr ds:[_player + 0Ch]
mov       dx, word ptr ds:[_player + 0Eh]
mov       word ptr es:[bx + 014h], ax
mov       word ptr es:[bx + 016h], dx
mov       dx, word ptr ds:[_player + 010h]
mov       ax, word ptr ds:[_player + 012h]
mov       word ptr es:[bx + 018h], dx
mov       word ptr es:[bx + 01ah], ax
mov       ax, word ptr ds:[_player + 014h]
mov       dx, word ptr ds:[_player + 016h]
mov       word ptr es:[bx + 01ch], ax
mov       word ptr es:[bx + 01eh], dx
mov       ax, word ptr ds:[_player + 018h]
cwd       
mov       word ptr es:[bx + 020h], ax
mov       word ptr es:[bx + 022h], dx
mov       ax, word ptr ds:[_player + 01Ah]
cwd       
mov       word ptr es:[bx + 024h], ax
mov       word ptr es:[bx + 026h], dx
mov       al, byte ptr ds:[_player + 01Ch]
cbw      
cwd       
mov       word ptr es:[bx + 028h], ax
mov       word ptr es:[bx + 02ah], dx
mov       al, byte ptr ds:[_player + 062h]
cbw      
cwd       
mov       word ptr es:[bx + 05ch], ax
mov       word ptr es:[bx + 05eh], dx
mov       al, byte ptr ds:[_player + 030h]
mov       word ptr es:[bx + 072h], 0
xor       ah, ah
mov       word ptr es:[bx + 070h], ax
mov       al, byte ptr ds:[_player + 031h]
mov       word ptr es:[bx + 076h], 0
mov       word ptr es:[bx + 074h], ax
mov       al, byte ptr ds:[_player + 04Ch]
cbw      
cwd       
mov       word ptr es:[bx + 0bch], ax
mov       word ptr es:[bx + 0beh], dx
mov       al, byte ptr ds:[_player + 04Dh]
cbw      
cwd       
mov       word ptr es:[bx + 0c0h], ax
mov       word ptr es:[bx + 0c2h], dx
mov       al, byte ptr ds:[_player + 03Bh]
cbw      
cwd       
mov       word ptr es:[bx + 0c4h], ax
mov       word ptr es:[bx + 0c6h], dx
mov       al, byte ptr ds:[_player + 05Bh]
cbw      
cwd       
mov       word ptr es:[bx + 0c8h], ax
mov       word ptr es:[bx + 0cah], dx
mov       ax, word ptr ds:[_player + 04Eh]
cwd       
mov       word ptr es:[bx + 0cch], ax
mov       word ptr es:[bx + 0ceh], dx
mov       ax, word ptr ds:[_player + 050h]
cwd       
mov       word ptr es:[bx + 0d0h], ax
mov       word ptr es:[bx + 0d2h], dx
mov       ax, word ptr ds:[_player + 052h]
cwd       
mov       word ptr es:[bx + 0d4h], ax
mov       word ptr es:[bx + 0d6h], dx
mov       ax, word ptr ds:[_player + 058h]
cwd       
mov       word ptr es:[bx + 0dch], ax
mov       word ptr es:[bx + 0deh], dx
mov       al, byte ptr ds:[_player + 05Ah]
cbw      
cwd       
mov       word ptr es:[bx + 0e0h], ax
mov       word ptr es:[bx + 0e2h], dx
mov       al, byte ptr ds:[_player + 05Eh]
cbw      
cwd       
mov       word ptr es:[bx + 0e8h], ax
mov       word ptr es:[bx + 0eah], dx
mov       al, byte ptr ds:[_player + 05Fh]
mov       word ptr es:[bx + 0eeh], 0
xor       ah, ah
mov       word ptr es:[bx + 0ech], ax
mov       al, byte ptr ds:[_player + 060h]
cbw      
cwd       
mov       word ptr es:[bx + 0f0h], ax
mov       word ptr es:[bx + 0f2h], dx
mov       al, byte ptr ds:[_player + 061h]
cbw      
cwd       
mov       word ptr [bp - 4], bx
mov       word ptr es:[bx + 0114h], ax
xor       si, si
mov       word ptr es:[bx + 0116h], dx
label_2:
mov       ax, word ptr ds:[si + _player + 01Eh]
add       bx, 4
cwd       
mov       word ptr es:[bx + 028h], ax
add       si, 2
mov       word ptr es:[bx + 02ah], dx
cmp       si, 0Ch
jne       label_2
les       bx, dword ptr [bp - 4]
xor       si, si
label_3:
mov       al, byte ptr ds:[si + _player + 02Ah]
cbw      
add       bx, 4
cwd       
mov       word ptr es:[bx + 040h], ax
inc       si
mov       word ptr es:[bx + 042h], dx
cmp       si, 6
jl        label_3
les       bx, dword ptr [bp - 4]
xor       ax, ax
label_4:
add       bx, 4
mov       word ptr es:[bx + 05ch], 0
inc       ax
mov       word ptr es:[bx + 05eh], 0
cmp       ax, 4
jl        label_4
les       bx, dword ptr [bp - 4]
xor       si, si
label_5:
mov       ax, word ptr ds:[si + _player + 03Ch]
cwd       
mov       word ptr es:[bx + 09ch], ax
mov       word ptr es:[bx + 09eh], dx
mov       ax, word ptr ds:[si + _player + 044h]
add       bx, 4
cwd       
mov       word ptr es:[bx + 0a8h], ax
add       si, 2
mov       word ptr es:[bx + 0aah], dx
cmp       si, 8
jne       label_5
les       bx, dword ptr [bp - 4]
xor       si, si
label_6:
mov       al, byte ptr ds:[si + _player + 032h]
cbw      
add       bx, 4
cwd       
mov       word ptr es:[bx + 074h], ax
inc       si
mov       word ptr es:[bx + 076h], dx
cmp       si, 9
jl        label_6
les       bx, dword ptr [bp - 4]
xor       si, si
label_1:
mov       ax, word ptr ds:[si + _psprites + 0]
cmp       ax, 0FFFFh
je        label_7
mov       word ptr es:[bx + 0f6h], 0
mov       word ptr es:[bx + 0f4h], ax
label_8:
mov       ax, word ptr ds:[si +  + _psprites + 2]
cwd       
mov       word ptr es:[bx + 0f8h], ax
mov       word ptr es:[bx + 0fah], dx
mov       ax, word ptr ds:[si + _psprites + 4]
mov       dx, word ptr ds:[si + _psprites + 6]
mov       word ptr es:[bx + 0fch], ax
mov       word ptr es:[bx + 0feh], dx
add       bx, 010h
mov       dx, word ptr ds:[si + _psprites + 8]
mov       ax, word ptr ds:[si + _psprites + 0Ah]
mov       word ptr es:[bx + 0f0h], dx
add       si, 0Ch
mov       word ptr es:[bx + 0f2h], ax
cmp       si, 018h
jne       label_1
mov       bx, _save_p
add       word ptr [bx], SIZEOF_PLAYER_VANILLA_T
LEAVE_MACRO 
pop       di
pop       si
pop       dx
pop       cx
pop       bx
retf      
label_7:
mov       word ptr es:[bx + 0f4h], 0
mov       word ptr es:[bx + 0f6h], 0
jmp       label_8





ENDP





PROC P_SAVEEND_
PUBLIC P_SAVEEND_
ENDP


END
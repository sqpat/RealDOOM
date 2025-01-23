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


push      cx
push      dx
push      si
push      di

les       di, dword ptr ds:[_save_p]

mov       dx, di
mov       ax, 4
and       dx, 3
sub       ax, dx
and       ax, 3
add       di, ax

mov       cx, SIZEOF_PLAYER_VANILLA_T / 2


mov       dx, di
xor       ax, ax
rep stosw

mov       di, dx

mov       si, OFFSET _player
lea       di, [di + 8]                  
movsw                           ; 0 -> 8    
movsw                           ; 2 -> A
movsw                           ; 4 -> C
movsw                           ; 6 -> E    ticcmd

movsw                           ; 8  -> 10
movsw                           ; A  -> 12  viewzvalue
movsw                           ; C  -> 14
movsw                           ; E  -> 16  viewheightvalue
movsw                           ; 10 -> 18
movsw                           ; 12 -> 1A  deltaviewheight
movsw                           ; 14 -> 1C  
movsw                           ; 16 -> 1E  bob

lodsw
cwd
stosw                           ; 18 -> 20
xchg      ax, dx
stosw                           ; 18 -> 22  health

lodsw
cwd
stosw                           ; 1A -> 24
xchg      ax, dx
stosw                           ; 1A -> 26  armorpoints

lodsb
cbw
cwd
stosw                           ; 1C -> 28
xchg      ax, dx
stosw                           ; 1C -> 2A  armortype

;         si now 1d    di now 2C

lodsb     ; si now 1E               ; playerstate
xor       ah, ah
mov       word ptr es:[di - 028h], ax     ; playerstate is (base)di + 4

;         si now 1E    di now 2C
mov       cx, NUMPOWERS

loop_save_powers:
lodsw
cwd       
stosw
xchg      ax, dx
stosw
loop      loop_save_powers

;         si 02Ah,   di 044h

mov       cx, NUMCARDS
loop_save_keys:
lodsb
cbw
cwd       
stosw
xchg      ax, dx
stosw
loop      loop_save_keys

;         si 030h,    di 05Ch
add       di, 014h              ; backpack, MAX_PLAYERS * dword for frag count,
;         si  030h,   di 070h

lodsb     ; ready weapon
cbw
cwd       
stosw
xchg      ax, dx
stosw
;         si  031h,   di 078h

lodsb     ; pending weapon
cbw
cwd       
stosw
xchg      ax, dx
stosw
;         si  032h,   di 078h

mov       cx, NUMWEAPONS
loop_save_weaponowned:
lodsb
cbw
cwd       
stosw
xchg      ax, dx
stosw
loop      loop_save_weaponowned

;         si  03Bh,   di 09Ch

lodsb     ; cheats
cbw
cwd   
mov       word ptr es:[di + 028h], ax     ; cheats is (base)di + C4h
mov       word ptr es:[di + 02Ah], dx


;         si  03Ch,   di 09Ch

mov       cx, NUMAMMO
loop_save_ammo:
lodsw
cwd       
stosw
xchg      ax, dx
stosw
loop      loop_save_ammo

;         si  044h,   di 0ACh

mov       cx, NUMAMMO
loop_save_max_ammo:
lodsw
cwd       
stosw
xchg      ax, dx
stosw
loop      loop_save_max_ammo

;         si  04Ch,   di 0BCh

lodsb     ; attackdown
cbw
cwd   
stosw
xchg      ax, dx
stosw
;         si  04Dh,   di 0C0h

lodsb     ; usedown
cbw
cwd   
stosw
xchg      ax, dx
stosw
;         si  04Eh,   di 0C4h

add       di, 8             ; cheats, refire (c4, c8)
;         si  04Eh,   di 0CCh

lodsw     ; killcount
cwd       
stosw
xchg      ax, dx
stosw
;         si  050h,   di 0D0h

lodsw     ; itemcount
cwd       
stosw
xchg      ax, dx
stosw
;         si  052h,   di 0D4h

lodsw     ; secretcount
cwd       
stosw
xchg      ax, dx
stosw
;         si  054h,   di 0D8h

add       si, 4             ; message, messagestring
add       di, 4             ; message
;         si  058h,   di 0DCh

lodsw     ; damagecount
cwd       
stosw
xchg      ax, dx
stosw
;         si  05Ah,   di 0E0h


lodsb     ; bonuscount
cbw
cwd       
stosw
xchg      ax, dx
stosw
;         si  05Bh,   di 0E4h


lodsb       ; refire            
cbw
cwd
mov       word ptr es:[di - 01Ch], ax     ; refire is (base)di + C8h
mov       word ptr es:[di - 01Ah], dx


;         si  05Ch,   di 0E4h
inc       si
inc       si                ; attackerref
add       di, 4             ; attacker
;         si  05Eh,   di 0E8h


lodsb     ; extralightvalue
cbw
cwd       
stosw
xchg      ax, dx
stosw
;         si  05Fh,   di 0ECh

lodsb     ; fixedcolormapvalue
xor       ah, ah
cwd       
stosw
xchg      ax, dx
stosw
;         si  060h,   di 0F0h

lodsb     ; colormap
xor       ah, ah
cwd       
stosw
xchg      ax, dx
stosw
;         si  061h,   di 0F4h

lodsb     ; didsecret
cbw
cwd       
mov       word ptr es:[di + 020h], ax     ; didsecret is 0114h
mov       word ptr es:[di + 022h], dx

;         si  062h,   di 0F4h

lodsb     ; backpack
cbw
cwd       
mov       word ptr es:[di - 098h], ax     ; backpack is (base)di + 5Ch
mov       word ptr es:[di - 096h], dx
;         si  063h,   di 0F4h
; should be 63 F4

; psprite states


mov       si, _psprites
mov       cx, NUMPSPRITES
loop_save_next_psprite:
lodsw
cmp       ax, 0FFFFh
je        skip_statenum_write           ; no need to write zeros. we already memset.
;mov       word ptr es:[di + 0f6h], 0
stosw
add       di, 2
done_with_statenum_write:

lodsw
cwd       
stosw
xchg      ax, dx
stosw
movsw
movsw
movsw
movsw
loop      loop_save_next_psprite

add       di, 4         ; for didsecret
mov       word ptr ds:[_save_p], di


pop       di
pop       si
pop       dx
pop       cx
retf      
skip_statenum_write:
add       di, 4
jmp       done_with_statenum_write





ENDP


PROC P_ArchiveWorld_ FAR
PUBLIC P_ArchiveWorld_



push  bx
push  cx
push  dx
push  si
push  di
push  bp
mov   bp, sp
sub   sp, 016h
mov   si, _save_p
mov   cx, SECTORS_SEGMENT
mov   word ptr [bp - 014h], _sectors_physics
xor   dx, dx
mov   ax, word ptr [si + 2]
mov   bx, word ptr [si]
mov   word ptr [bp - 2], ax
xor   si, si
label_8:
mov   di, _numsectors
cmp   dx, word ptr [di]
jge   label_1
jmp   label_2
label_1:
mov   word ptr [bp - 0Eh], LINES_SEGMENT
xor   ax, ax
mov   word ptr [bp - 010h], LINES_PHYSICS_SEGMENT
mov   word ptr [bp - 8], ax
mov   word ptr [bp - 012h], ax
mov   word ptr [bp - 0Ah], ax
label_13:
mov   si, _numlines
mov   ax, word ptr [bp - 8]
cmp   ax, word ptr [si]
jl    label_3
jmp   label_4
label_3:
mov   ax, LINEFLAGSLIST_SEGMENT
mov   si, word ptr [bp - 8]
mov   es, ax
mov   al, byte ptr es:[si]
mov   byte ptr [bp - 0Ch], al
mov   ax, word ptr [bp - 8]
mov   cx, word ptr [bp - 8]
sar   ax, 0Fh
xor   cx, ax
sub   cx, ax
and   cx, 7
xor   cx, ax
sub   cx, ax
mov   ax, 1
shl   ax, cl
mov   cx, ax
mov   ax, word ptr [bp - 8]
cwd   
shl   dx, 3
sbb   ax, dx
sar   ax, 3
mov   dx, SEENLINES_6800_SEGMENT
mov   di, ax
mov   es, dx
mov   al, byte ptr es:[di]
mov   byte ptr [bp - 0Bh], 0
xor   ah, ah
mov   si, word ptr [bp - 0Ch]
test  ax, cx
jne   label_5
label_9:
mov   es, word ptr [bp - 2]
mov   dx, word ptr [bp - 0Eh]
add   bx, 2
mov   cx, SIDES_RENDER_9000_SEGMENT
mov   word ptr es:[bx - 2], si
mov   es, word ptr [bp - 010h]
mov   si, word ptr [bp - 0Ah]
add   bx, 2
mov   al, byte ptr es:[si + 0Fh]
mov   es, word ptr [bp - 2]
xor   ah, ah
mov   word ptr [bp - 4], dx
mov   word ptr es:[bx - 2], ax
mov   es, word ptr [bp - 010h]
add   bx, 2
mov   al, byte ptr es:[si + 0Eh]
mov   si, word ptr [bp - 012h]
mov   es, word ptr [bp - 2]
mov   word ptr [bp - 6], si
mov   word ptr es:[bx - 2], ax
xor   al, al
label_12:
les   si, dword ptr [bp - 6]
cmp   word ptr es:[si], -1
jne   label_11
label_10:
inc   ax
add   word ptr [bp - 6], 2
cmp   ax, 2
jl    label_12
inc   word ptr [bp - 8]
add   word ptr [bp - 012h], 4
add   word ptr [bp - 0Ah], 010h ; todo
jmp   label_13
label_5:
jmp   label_6
label_11:
jmp   label_7
label_2:
mov   es, cx
add   bx, 2
mov   ax, word ptr es:[si]
mov   es, word ptr [bp - 2]
sar   ax, 3
mov   word ptr es:[bx - 2], ax
mov   es, cx
add   bx, 2
mov   ax, word ptr es:[si + 2]
mov   es, word ptr [bp - 2]
sar   ax, 3
mov   word ptr es:[bx - 2], ax
mov   es, cx
add   bx, 2
mov   al, byte ptr es:[si + 4]
mov   es, word ptr [bp - 2]
xor   ah, ah
mov   word ptr es:[bx - 2], ax
mov   es, cx
add   bx, 2
mov   al, byte ptr es:[si + 5]
mov   es, word ptr [bp - 2]
mov   di, word ptr [bp - 014h]
mov   word ptr es:[bx - 2], ax
mov   es, cx
add   bx, 2
mov   al, byte ptr es:[si + 0Eh]
mov   es, word ptr [bp - 2]
inc   dx
mov   word ptr es:[bx - 2], ax
add   bx, 2
mov   al, byte ptr [di + 0Eh]
add   si, 010h                   ; todo?
mov   word ptr es:[bx - 2], ax
add   bx, 2
mov   al, byte ptr [di + 0Fh]
add   word ptr [bp - 014h], 010h ; todo
mov   word ptr es:[bx - 2], ax
jmp   label_8
label_6:
or    si, 0100h      ; bit 9 for flags
jmp   label_9
label_7:
mov   word ptr [bp - 016h], SIDES_SEGMENT
mov   si, word ptr es:[si]
mov   di, word ptr [bp - 6]
shl   si, 3
mov   di, word ptr es:[di]
mov   es, word ptr [bp - 016h]
add   bx, 2
mov   dx, word ptr es:[si + 6]
mov   es, word ptr [bp - 2]
shl   di, 2
mov   word ptr es:[bx - 2], dx
mov   es, cx
add   bx, 2
mov   dx, word ptr es:[di]
mov   es, word ptr [bp - 2]
mov   word ptr es:[bx - 2], dx
mov   es, word ptr [bp - 016h]
add   bx, 2
mov   dx, word ptr es:[si]
mov   es, word ptr [bp - 2]
mov   word ptr es:[bx - 2], dx
mov   es, word ptr [bp - 016h]
add   bx, 2
mov   dx, word ptr es:[si + 2]
mov   es, word ptr [bp - 2]
mov   word ptr es:[bx - 2], dx
mov   es, word ptr [bp - 016h]
add   bx, 2
mov   dx, word ptr es:[si + 4]
mov   es, word ptr [bp - 2]
mov   word ptr es:[bx - 2], dx
jmp   label_10
label_4:
mov   si, _save_p
mov   ax, word ptr [bp - 2]
mov   word ptr [si], bx
mov   word ptr [si + 2], ax
leave 
pop   di
pop   si
pop   dx
pop   cx
pop   bx
retf  
cld   

ENDP



PROC P_SAVEEND_
PUBLIC P_SAVEEND_
ENDP


END
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

SIZEOF_SECTOR_T = 16
SIZEOF_SECTOR_PHYSICS_T = 16
SIZEOF_LINE_PHYSICS_T = 16
SIZEOF_LINE_T = 4
SIDE_2_ID = -2      ; impossible side id, use as marker for 2nd iter

PROC P_ArchiveWorld_ FAR
PUBLIC P_ArchiveWorld_



push  bx
push  cx
push  dx
push  si
push  di

mov   cx, word ptr ds:[_numsectors]
les   di, dword ptr ds:[_save_p]
mov   ax, SECTORS_SEGMENT
mov   ds, ax
mov   bx, _sectors_physics + 14  ; offset to tags


xor   si, si
loop_save_next_sector:

; si is sector pointer (in ds)
; bx is sector_physics (in ss)

do_save_next_sector:

lodsw                   ; todo shr?? can this be negative
sar   ax, 1
sar   ax, 1
sar   ax, 1
stosw           ; floorheight

lodsw                   ; todo shr?? can this be negative
sar   ax, 1
sar   ax, 1
sar   ax, 1
stosw           ; ceilingheight

xor   ah, ah    ; zero high bit for next 5 writes.

lodsb           ; floorpic
stosw

lodsb           ; ceiling pic
stosw

mov   al, byte ptr ds:[si + 8]  ; si is 6, 0Dh is lightlevel
stosw

mov   al, byte ptr ss:[bx]      ; special
stosw

mov   al, byte ptr ss:[bx+1]    ; tag
stosw

add   si, (SIZEOF_SECTOR_T - 6)
add   bx, SIZEOF_SECTOR_PHYSICS_T
loop  loop_save_next_sector

done_saving_sectors:


xor   dx, dx
mov   si, 14

loop_save_next_line:

mov   ax, LINEFLAGSLIST_SEGMENT
mov   ds, ax
mov   bx, dx
mov   al, byte ptr ds:[bx]

mov   cx, SEENLINES_6800_SEGMENT
mov   ds, cx
sar   bx, 1
sar   bx, 1
sar   bx, 1                  ; 8 bits per.
mov   ah, byte ptr ds:[bx]   ; get seenlines bit in byte

mov   cl, dl
and   cl, 7
shr   ah, cl   ; shift ah by 0-7 to get it in the LSB
and   ah, 1    ; turn off all other bits. 9 bit spot is now seenline

stosw          ; write lineflags.

mov   ax, LINES_PHYSICS_SEGMENT
mov   ds, ax

mov   cx, word ptr ds:[si]      ; special and tag, 0E and 0F offsets
xor   ah, ah

mov   al, ch                    ; swapped order
stosw                           ; special       ; todo convert these tags to vanilla values

mov   al, cl
stosw                           ; tag


mov   ax, LINES_SEGMENT
mov   ds, ax
mov   bx, bx
sal   bx, 1
sal   bx, 1                     ; 4 bytes per line 

mov   ax, word ptr ds:[bx]      ; side1
mov   cx, word ptr ds:[bx+2]    ; side2

check_next_side:
cmp   ax, -1
je    done_checking_side

sal   ax, 1
sal   ax, 1     ; 4 per side_render

push  si
xchg  si, ax    ; shove this in si

mov   ax, SIDES_SEGMENT
push  ax
mov   ax, SIDES_RENDER_9000_SEGMENT
mov   ds, ax

;mov   ax, ds:[si]               ; hold onto rowoffset  from siderender
lodsw 
inc    si                       ; we want to read si + 6 after the sal...
; could be weird and lodsw and inc then get the +6 free later.

pop   ds                        ; sides_segment again

sal    si, 1                     ; 8 per side 
;add   si, 6

movsw                           ; textureoffset. si now 8
stosw                           ; write rowoffset
sub   si, 8                     ; back to si + 0
movsw                           ; toptexture
movsw                           ; midtexture
movsw                           ; bottexture


pop   si
done_checking_side:
cmp   cx, SIDE_2_ID             ; already checked side 2
je    done_saving_lines
xchg  ax, cx                    ; set ax to side 2 
mov   cx, SIDE_2_ID             ; set side 2 marker to quit next iter
jmp   check_next_side



done_saving_lines:

add   si, SIZEOF_LINE_PHYSICS_T

inc   dx                                ; increment line
cmp   dx, word ptr ss:[_numlines]

jl    loop_save_next_line





exit_archive_world:
push  ss
pop   ds

mov   word ptr ds:[_save_p], di

pop   di
pop   si
pop   dx
pop   cx
pop   bx
retf  

ENDP



PROC P_SAVEEND_
PUBLIC P_SAVEEND_
ENDP


END
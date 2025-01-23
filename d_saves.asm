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
mov   bx, dx
sal   bx, 1
sal   bx, 1                     ; 4 bytes per line 

mov   ax, word ptr ds:[bx]      ; side1
mov   bx, word ptr ds:[bx+2]    ; side2
mov   cx, 2                     ; num sides
push  si

check_next_side:
cmp   ax, -1
je    done_checking_side

sal   ax, 1
sal   ax, 1     ; 4 per side_render

xchg  si, ax    ; shove this in si

mov   ax, SIDES_SEGMENT
push  ax
mov   ax, SIDES_RENDER_9000_SEGMENT
mov   ds, ax


lodsw                           ; rowoffset into ax
inc    si                       ; we want to read si + 6 after the sal...
; could be weird and lodsw and inc then get the +6 free later.

pop   ds                        ; sides_segment again

sal    si, 1                    ; 8 per side, not 4.
;add   si, 6

movsw                           ; textureoffset. si now 8
stosw                           ; write rowoffset
sub   si, 8                     ; back to si + 0
movsw                           ; toptexture
movsw                           ; midtexture
movsw                           ; bottexture


done_checking_side:
xchg   ax, bx
loop   check_next_side

pop    si


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


SIZEOF_THINKER_T = 44
SIZEOF_MOBJ_VANILLA_T = 09Ah
SIZEOF_MOBJ_T = 028h
SIZEOF_MOBJPOS_T = 018h
SIZEOF_THINKER_VANILLA_T = 12
SIZEOF_MAPTHING_T = 10
SIZEOF_STATE_T = 6

PROC P_ArchiveThinkers_ FAR
PUBLIC P_ArchiveThinkers_


push      bx
push      cx
push      dx
push      si
push      di
push      bp
mov       bp, sp
sub       sp, 8
mov       bx, OFFSET _thinkerlist + 2
mov       ax, word ptr ds:[bx]
mov       word ptr [bp - 6], ax
test      ax, ax
je        exit_archivethinkers
loop_check_next_thinker:
imul      bx, word ptr [bp - 6], SIZEOF_THINKER_T
mov       ax, word ptr [bx + OFFSET _thinkerlist]
and       ax, TF_FUNCBITS
cmp       ax, TF_MOBJTHINKER_HIGHBITS
je        do_save_next_thinker
iterate_to_next_thinker:
imul      bx, word ptr [bp - 6], SIZEOF_THINKER_T
mov       ax, word ptr [bx + OFFSET _thinkerlist + 2]
mov       word ptr [bp - 6], ax
test      ax, ax
jne       loop_check_next_thinker
exit_archivethinkers:
mov       bx, OFFSET _save_p
les       si, dword ptr [bx]
inc       word ptr [bx]
mov       byte ptr es:[si], 0       ; tc_end
LEAVE_MACRO
pop       di
pop       si
pop       dx
pop       cx
pop       bx
retf      
do_save_next_thinker:
imul      si, word ptr [bp - 6], SIZEOF_MOBJPOS_T
add       bx, OFFSET _thinkerlist + 4
mov       word ptr [bp - 4], bx
mov       bx, OFFSET _save_p
mov       bx, word ptr ds:[bx]
mov       di, OFFSET _save_p
lea       ax, [bx + 1]
mov       es, word ptr [di + 2]
mov       word ptr [di], ax
mov       byte ptr es:[bx], 1       ; tc_mobj
mov       ax, word ptr [di]
mov       dx, ax
mov       bx, 4
and       dx, 3
sub       bx, dx
mov       dx, bx
and       dx, 3
add       ax, dx
mov       word ptr [di], ax
mov       bx, ax
mov       ax, word ptr [di + 2]
mov       cx, SIZEOF_MOBJ_VANILLA_T
mov       word ptr [bp - 2], ax
mov       di, bx
mov       es, word ptr [bp - 2]
xor       al, al
mov       word ptr [bp - 8], MOBJPOSLIST_6800_SEGMENT
push      di
mov       ah, al
shr       cx, 1

rep stosw 
adc       cx, cx
rep stosb 
pop       di
mov       es, word ptr [bp - 8]
mov       dx, word ptr es:[si]
mov       ax, word ptr es:[si + 2]
mov       es, word ptr [bp - 2]
mov       word ptr es:[bx + 0Ch], dx
mov       word ptr es:[bx + 0Eh], ax
mov       es, word ptr [bp - 8]
mov       ax, word ptr es:[si + 4]
mov       dx, word ptr es:[si + 6]
mov       es, word ptr [bp - 2]
mov       word ptr es:[bx + 010h], ax
mov       word ptr es:[bx + 012h], dx
mov       es, word ptr [bp - 8]
mov       dx, word ptr es:[si + 8]
mov       ax, word ptr es:[si + 0Ah]
mov       es, word ptr [bp - 2]
mov       word ptr es:[bx + 014h], dx
mov       word ptr es:[bx + 016h], ax
mov       es, word ptr [bp - 8]
mov       ax, word ptr es:[si + 0Eh]
mov       dx, word ptr es:[si + 010h]
mov       es, word ptr [bp - 2]
mov       word ptr es:[bx + 020h], ax
mov       word ptr es:[bx + 022h], dx
mov       es, word ptr [bp - 8]
mov       ax, word ptr es:[si + 012h]
mov       es, word ptr [bp - 2]
mov       word ptr es:[bx + 066h], 0
mov       word ptr es:[bx + 064h], ax
mov       es, word ptr [bp - 8]
mov       ax, word ptr es:[si + 016h]
mov       dx, word ptr es:[si + 014h]
mov       es, word ptr [bp - 2]
mov       word ptr es:[bx + 068h], dx
mov       word ptr es:[bx + 06ah], ax
mov       es, word ptr [bp - 8]
imul      di, word ptr es:[si + 012h], SIZEOF_STATE_T
mov       ax, STATES_SEGMENT
mov       es, ax
mov       al, byte ptr es:[di]
mov       es, word ptr [bp - 2]
xor       ah, ah
mov       word ptr es:[bx + 026h], 0
mov       word ptr es:[bx + 024h], ax
mov       es, word ptr [bp - 8]
imul      si, word ptr es:[si + 012h], SIZEOF_STATE_T
mov       ax, STATES_SEGMENT
mov       es, ax
mov       al, byte ptr es:[si + 1]
mov       es, word ptr [bp - 2]
xor       ah, ah
mov       word ptr es:[bx + 02ah], 0
mov       word ptr es:[bx + 028h], ax
inc       si
test      byte ptr es:[bx + 028h], FF_FULLBRIGHT
je        not_fullbright
mov       word ptr es:[bx + 02ah], 0
and       word ptr es:[bx + 028h], FF_FRAMEMASK
or        byte ptr es:[bx + 029h], FF_FULLBRIGHT
not_fullbright:
mov       si, word ptr [bp - 4]
mov       al, byte ptr [si + 01eh]
mov       es, word ptr [bp - 2]
xor       ah, ah
mov       word ptr es:[bx + 040h], 0
mov       word ptr es:[bx + 042h], ax
mov       dx, word ptr [si + 0Ah]
mov       ax, word ptr [si + 0Ch]
mov       word ptr es:[bx + 044h], dx
mov       word ptr es:[bx + 046h], ax
mov       ax, word ptr [si + 0Eh]
mov       dx, word ptr [si + 010h]
mov       word ptr es:[bx + 048h], ax
mov       word ptr es:[bx + 04ah], dx
mov       ax, word ptr [si + 012h]
mov       dx, word ptr [si + 014h]
mov       word ptr es:[bx + 04ch], ax
mov       word ptr es:[bx + 04eh], dx
mov       ax, word ptr [si + 016h]
mov       dx, word ptr [si + 018h]
mov       word ptr es:[bx + 050h], ax
mov       word ptr es:[bx + 052h], dx
mov       al, byte ptr [si + 01ah]
mov       word ptr es:[bx + 05ah], 0
xor       ah, ah
mov       word ptr es:[bx + 058h], ax
mov       al, byte ptr [si + 01bh]
mov       word ptr es:[bx + 062h], 0
mov       word ptr es:[bx + 060h], ax
cmp       byte ptr [si + 01bh], -1
jne       skip_set_tics_32bit
mov       word ptr es:[bx + 060h], -1
mov       word ptr es:[bx + 062h], -1
skip_set_tics_32bit:
mov       si, word ptr [bp - 4]
mov       ax, word ptr [si + 01ch]
mov       es, word ptr [bp - 2]
cwd       
mov       word ptr es:[bx + 06ch], ax
mov       word ptr es:[bx + 06eh], dx
mov       al, byte ptr [si + 01fh]
cbw      
cwd       
mov       word ptr es:[bx + 070h], ax
mov       word ptr es:[bx + 072h], dx
mov       ax, word ptr [si + 020h]
cwd       
mov       word ptr es:[bx + 074h], ax
mov       word ptr es:[bx + 076h], dx
mov       al, byte ptr [si + 024h]
cbw      
cwd       
mov       word ptr es:[bx + 07ch], ax
mov       word ptr es:[bx + 07eh], dx
mov       al, byte ptr [si + 025h]
cbw      
cwd       
mov       word ptr es:[bx + 080h], ax
mov       word ptr es:[bx + 082h], dx
xor       ax, ax
cmp       byte ptr [si + 01ah], 0
jne       skip_player_set
mov       ax, 1
skip_player_set:
imul      si, word ptr [bp - 6], SIZEOF_MAPTHING_T
mov       es, word ptr [bp - 2]
cwd       
mov       word ptr es:[bx + 084h], ax
push      ds
mov       word ptr es:[bx + 086h], dx
mov       ax, NIGHTMARESPAWNS_SEGMENT
lea       di, [bx + 08ch]
mov       ds, ax
movsw     
movsw     
movsw     
movsw     
movsw     
mov       si, word ptr [bp - 4]
pop       ds
mov       ax, word ptr [si + 026h]
mov       word ptr es:[bx + 098h], 0
mov       word ptr es:[bx + 096h], ax
mov       bx, OFFSET _save_p
add       word ptr ds:[bx], SIZEOF_MOBJ_VANILLA_T
jmp       iterate_to_next_thinker


ENDP

PROC P_SAVEEND_
PUBLIC P_SAVEEND_
ENDP


END
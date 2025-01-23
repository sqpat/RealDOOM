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
EXTRN _activeceilings:WORD

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


SIZEOF_THINKER_T = 02Ch
SIZEOF_MOBJ_VANILLA_T = 09Ah
SIZEOF_MOBJ_T = 028h
SIZEOF_MOBJPOS_T = 018h
SIZEOF_THINKER_VANILLA_T = 12
SIZEOF_MAPTHING_T = 10
SIZEOF_STATE_T = 6
VANILLA_FULLBRIGHT = 08000h

PROC P_ArchiveThinkers_ FAR
PUBLIC P_ArchiveThinkers_


push      bx
push      cx
push      dx
push      si
push      di

les       di, dword ptr ds:[_save_p]
mov       dx, word ptr ds:[_thinkerlist + 2]
test      dx, dx
je        exit_archivethinkers
loop_check_next_thinker:
mov       ax, SIZEOF_THINKER_T
push      dx    ; backup  th
mul       dx
pop       dx    ; restore th
xchg      ax, bx

mov       ax, word ptr ss:[bx + OFFSET _thinkerlist]
and       ax, TF_FUNCBITS
cmp       ax, TF_MOBJTHINKER_HIGHBITS
je        do_save_next_thinker
mov       dx, bx
iterate_to_next_thinker:
mov       ax, SIZEOF_THINKER_T
mul       dx
xchg      ax, bx
mov       dx, word ptr ss:[bx + OFFSET _thinkerlist + 2] ; next th
test      dx, dx
jne       loop_check_next_thinker
exit_archivethinkers:
mov       al, 0
stosb                                   ; tc_end
push      ss
pop       ds

mov       word ptr ds:[_save_p], di     ; write back _save_p

pop       di
pop       si
pop       dx
pop       cx
pop       bx
retf      

do_save_next_thinker:
; dx is index..
mov       ax, SIZEOF_MOBJPOS_T
push      dx
mul       dx         ; dx is thinker index.
pop       dx
xchg      si, ax     ; si gets mobjpos_t

mov       al, 1
stosb



; PADSAVEP
mov       cx, di
mov       ax, 4
and       cx, 3
sub       ax, cx
and       ax, 3
add       di, ax



; default everything to zero
mov       ax, MOBJPOSLIST_6800_SEGMENT
mov       ds, ax


mov       cx, SIZEOF_MOBJ_VANILLA_T / 2
xor       ax, ax
rep       stosw 


lea       di, [di + 12 - SIZEOF_MOBJ_VANILLA_T] ; skip thinker fields

movsw   ; x
movsw
movsw   ; y
movsw
movsw   ; z
movsw                   ; di + 18h    si + 0Ch now 

add       di, 8         ; di + 20h    skip snext sprev
add       si, 2         ; si + 0Eh

movsw   ; angle         ; di + 22h    si + 010h
movsw                   ; di + 24h    si + 012h





lodsw                   ; si + 014h
mov       word ptr ds:[di + 040h], ax   ; di + 64h          statenum
xchg      ax, cx        ; cx gets statenum. 

lodsw                   ; si + 016h
mov       word ptr ds:[di + 044h], ax   ; di + 68h          flags1
lodsw                   ; si + 018h
mov       word ptr ds:[di + 046h], ax   ; di + 6Ah          flags2


; 			savemobj->sprite 			= states[mobj_pos->stateNum].sprite;
;			savemobj->frame 			= states[mobj_pos->stateNum].frame;
;			if (savemobj->frame & FF_FULLBRIGHT){
;				savemobj->frame &= FF_FRAMEMASK; // get rid of fullbright
;				savemobj->frame |= 0x8000;       // add vanilla FULLBRIGHT mask
;			}


mov       ax, STATES_SEGMENT
mov       ds, ax
; 6 bytes per.
mov       si, cx
sal       si, 1
add       si, cx
sal       si, 1

xor       ah, ah
lodsb
stosw     ; sprite  ; di + 026
inc       di
inc       di        ; di + 028
lodsb
test      ax, FF_FULLBRIGHT
jne       skip_framemask
and       ax, FF_FRAMEMASK
or        ax, VANILLA_FULLBRIGHT 
skip_framemask:
stosw     ; frame   ; di + 02A

add       di, 018h      ; di + 42h . skip a bunch of stuff related to sprites, bprev..

push      ss
pop       ds

lea       si, [bx + _thinkerlist + 4 + 0Ah ]       ; point to mobj + 0Ah now

mov       al, byte ptr ds:[si + 014h]   ; 042h <- 01Eh (14h + 0a) radius
xor       ah, ah
stosw     ; di + 044h


movsw      
movsw               ; di 048h <- si 0Eh  height
movsw
movsw               ; di 04Ch <- si 12h  momx
movsw
movsw               ; di 050h <- si 16h  momy
movsw
movsw               ; di 054h <- si 1Ah  momz

add       di, 4
lodsb
; ah still 0
stosw               ; di 05Ah <- si 1Bh  type


add       di, 6
lodsb
; ah still 0
stosw               ; di 062h <- si 01Ch  tics

add       di, 0Ah
movsw               ; di 06Eh <- si 01Eh  health

add       di, 2     ; di + 070h
inc       si        ; si + 01Fh

movsb               ; di 071h <- si 020h   movedir

add       di, 3
movsw               ; di 076h <- si 022h   movecount

add       di, 6     ; di + 07Ch
add       si, 2     ; si + 024h

movsb               ; di 07Dh <- si 025h   reactiontime

add       di, 3     ; di + 080h
movsb               ; di 081h <- si 026h   threshold


add       di, 0Bh   ; di + 08Ch

mov       ax, NIGHTMARESPAWNS_SEGMENT
mov       ds, ax

; get index

mov       ax, SIZEOF_MAPTHING_T
push      dx
mul       dx
pop       dx
xchg      ax, si

; copy nightmarespawn
movsw  ; x 
movsw  ; y   
movsw  ; angle   
movsw  ; type   
movsw  ; options   

; di now 096h


add       di, (SIZEOF_MOBJ_VANILLA_T - 096h)        
jmp       iterate_to_next_thinker


ENDP


SIZEOF_CEILING_VANILLA_T = 030h
SIZEOF_FLOORMOVE_VANILLA_T = 02Ah
SIZEOF_VLDOOR_VANILLA_T = 028h
SIZEOF_PLAT_VANILLA_T = 038h
SIZEOF_STROBE_VANILLA_T = 024h
SIZEOF_LIGHTFLASH_VANILLA_T = 024h
SIZEOF_GLOW_VANILLA_T = 01Ch

MAXCEILINGS = 30

PROC P_ArchiveSpecials_ FAR
PUBLIC P_ArchiveSpecials_

push      bx
push      cx
push      dx
push      si
push      di
push      bp
mov       bp, sp
sub       sp, 020h
mov       si, OFFSET _thinkerlist + 2
mov       si, word ptr [si]
test      si, si
jne       save_next_special
jmp       exit_archive_specials
save_next_special:
imul      bx, si, SIZEOF_THINKER_T
mov       ax, word ptr [bx + OFFSET _thinkerlist]
and       ax, TF_FUNCBITS


mov       word ptr [bp - 4], ax
test      ax, ax
je        is_null_funcbits
jmp       not_null_funcbits
is_null_funcbits:
xor       bx, bx
cmp       si, word ptr [_activeceilings]
je        found_ceiling
check_next_ceiling:
inc       ax
add       bx, 2
cmp       ax, MAXCEILINGS
jge       found_ceiling
cmp       si, word ptr [bx + _activeceilings]
jne       check_next_ceiling
found_ceiling:
cmp       ax, MAXCEILINGS
jl        can_add_ceiling
jmp       iterate_to_next_special
can_add_ceiling:
imul      ax, si, SIZEOF_THINKER_T
mov       bx, _save_p
mov       di, _save_p
add       ax, OFFSET _thinkerlist + 4
mov       bx, word ptr [bx]
mov       word ptr [bp - 6], ax
lea       ax, [bx + 1]
mov       es, word ptr [di + 2]
mov       word ptr [di], ax
mov       byte ptr es:[bx], 0
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
mov       word ptr [bp - 01ah], ax
mov       di, bx
mov       es, word ptr [bp - 01ah]
mov       cx, SIZEOF_CEILING_VANILLA_T / 2
xor       ax, ax
rep       stosw 
mov       di, word ptr [bp - 6]
do_save_ceiling_stuff:
mov       al, byte ptr [di]
cbw      
cwd       
mov       word ptr es:[bx + 0Ch], ax
mov       word ptr es:[bx + 0Eh], dx
mov       ax, word ptr [di + 1]
cwd       
mov       word ptr es:[bx + 010h], ax
mov       word ptr es:[bx + 012h], dx
mov       ax, word ptr [di + 3]
cwd       
mov       cl, 0Dh
shl       dx, cl
rol       ax, cl
xor       dx, ax
and       ax, 0E000h
xor       dx, ax
mov       word ptr es:[bx + 014h], ax
mov       word ptr es:[bx + 016h], dx
mov       ax, word ptr [di + 5]
cwd       
mov       cl, 0Dh
shl       dx, cl
rol       ax, cl
xor       dx, ax
and       ax, 0E000h
xor       dx, ax
mov       word ptr es:[bx + 018h], ax
mov       word ptr es:[bx + 01ah], dx
mov       ax, word ptr [di + 7]
cwd       
mov       cl, 0Dh
shl       dx, cl
rol       ax, cl
xor       dx, ax
and       ax, 0E000h
xor       dx, ax
mov       word ptr es:[bx + 01ch], ax
mov       word ptr es:[bx + 01eh], dx
mov       al, byte ptr [di + 9]
cbw      
cwd       
mov       word ptr es:[bx + 020h], ax
mov       word ptr es:[bx + 022h], dx
mov       al, byte ptr [di + 0Ah]
cbw      
cwd       
mov       word ptr es:[bx + 024h], ax
mov       word ptr es:[bx + 026h], dx
mov       al, byte ptr [di + 0Bh]
cbw      
cwd       
mov       word ptr es:[bx + 028h], ax
mov       word ptr es:[bx + 02ah], dx
mov       al, byte ptr [di + 0Ch]
cbw      
cwd       
mov       word ptr es:[bx + 02ch], ax
mov       word ptr es:[bx + 02eh], dx
mov       bx, _save_p
add       word ptr [bx], SIZEOF_CEILING_VANILLA_T
iterate_to_next_special:
imul      si, si, SIZEOF_THINKER_T
mov       si, word ptr [si + OFFSET _thinkerlist + 2]
test      si, si
je        exit_archive_specials
jmp       save_next_special
exit_archive_specials:
mov       bx, _save_p
les       si, dword ptr [bx]
inc       word ptr [bx]
mov       byte ptr es:[si], 7
LEAVE_MACRO     
pop       di
pop       si
pop       dx
pop       cx
pop       bx
retf      
not_null_funcbits:
add       bx, OFFSET _thinkerlist + 4
mov       word ptr [bp - 2], bx
cmp       ax, TF_MOVECEILING_HIGHBITS
jne       not_ceiling
jmp       do_save_ceiling
not_ceiling:
cmp       ax, TF_VERTICALDOOR_HIGHBITS
je        do_save_door
jmp       not_door
do_save_door:
mov       bx, _save_p
mov       bx, word ptr [bx]
mov       di, _save_p
lea       ax, [bx + 1]
mov       es, word ptr [di + 2]
mov       word ptr [di], ax
mov       byte ptr es:[bx], 1
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
mov       word ptr [bp - 020h], ax
mov       di, bx
mov       es, word ptr [bp - 020h]
mov       cx, SIZEOF_VLDOOR_VANILLA_T / 2
xor       ax, ax
rep       stosw


mov       di, word ptr [bp - 2]
mov       al, byte ptr [di]
cbw      
cwd       
mov       word ptr es:[bx + 0Ch], ax
mov       word ptr es:[bx + 0Eh], dx
mov       ax, word ptr [di + 1]
cwd       
mov       word ptr es:[bx + 010h], ax
mov       word ptr es:[bx + 012h], dx
mov       ax, word ptr [di + 3]
cwd       
mov       cl, 0Dh
shl       dx, cl
rol       ax, cl
xor       dx, ax
and       ax, 0E000h
xor       dx, ax
mov       word ptr es:[bx + 014h], ax
mov       word ptr es:[bx + 016h], dx
mov       ax, word ptr [di + 5]
cwd       
mov       cl, 0Dh
shl       dx, cl
rol       ax, cl
xor       dx, ax
and       ax, 0E000h
xor       dx, ax
mov       word ptr es:[bx + 018h], ax
mov       word ptr es:[bx + 01ah], dx
mov       ax, word ptr [di + 7]
cwd       
mov       word ptr es:[bx + 01ch], ax
mov       word ptr es:[bx + 01eh], dx
mov       ax, word ptr [di + 9]
cwd       
mov       word ptr es:[bx + 020h], ax
mov       word ptr es:[bx + 022h], dx
mov       ax, word ptr [di + 0Bh]
cwd       
mov       word ptr es:[bx + 024h], ax
mov       word ptr es:[bx + 026h], dx
mov       bx, _save_p
add       word ptr [bx], SIZEOF_VLDOOR_VANILLA_T
not_door:
cmp       word ptr [bp - 4], TF_MOVEFLOOR_HIGHBITS
je        do_save_floormove
jmp       not_floormove
do_save_floormove:
imul      ax, si, SIZEOF_THINKER_T
mov       bx, _save_p
mov       di, _save_p
add       ax, OFFSET _thinkerlist + 4
mov       bx, word ptr [bx]
mov       word ptr [bp - 01ch], ax
lea       ax, [bx + 1]
mov       es, word ptr [di + 2]
mov       word ptr [di], ax
mov       byte ptr es:[bx], 2
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
mov       word ptr [bp - 0Eh], ax
mov       di, bx
mov       es, word ptr [bp - 0Eh]
mov       cx, SIZEOF_FLOORMOVE_VANILLA_T / 2
xor       ax, ax
rep       stosw 
mov       di, word ptr [bp - 01ch]
mov       al, byte ptr [di]
mov       word ptr es:[bx + 0Eh], 0
xor       ah, ah
mov       word ptr es:[bx + 0Ch], ax
mov       al, byte ptr [di + 1]
cbw      
cwd       
mov       word ptr es:[bx + 010h], ax
mov       word ptr es:[bx + 012h], dx
mov       ax, word ptr [di + 2]
cwd       
mov       word ptr es:[bx + 014h], ax
mov       word ptr es:[bx + 016h], dx
mov       al, byte ptr [di + 4]
cbw      
cwd       
mov       word ptr es:[bx + 018h], ax
mov       word ptr es:[bx + 01ah], dx
mov       al, byte ptr [di + 5]
mov       word ptr es:[bx + 01eh], 0
xor       ah, ah
mov       word ptr es:[bx + 01ch], ax
mov       al, byte ptr [di + 6]
mov       word ptr es:[bx + 020h], ax
mov       ax, word ptr [di + 7]
cwd       
mov       cl, 0Dh
shl       dx, cl
rol       ax, cl
xor       dx, ax
and       ax, 0E000h
xor       dx, ax
mov       word ptr es:[bx + 022h], ax
mov       word ptr es:[bx + 024h], dx
mov       ax, word ptr [di + 9]
cwd       
mov       cl, 0Dh
shl       dx, cl
rol       ax, cl
xor       dx, ax
and       ax, 0E000h
xor       dx, ax
mov       word ptr es:[bx + 026h], ax
mov       word ptr es:[bx + 028h], dx
mov       bx, _save_p
add       word ptr [bx], SIZEOF_FLOORMOVE_VANILLA_T
not_floormove:
imul      bx, si, SIZEOF_THINKER_T
mov       ax, word ptr [bp - 4]
add       bx, OFFSET _thinkerlist + 4
cmp       ax, TF_PLATRAISE_HIGHBITS
jne       not_platraise
jmp       do_save_platraise
not_platraise:
cmp       ax, TF_LIGHTFLASH_HIGHBITS
jne       not_lightflash
jmp       do_save_lightflash
not_lightflash:
cmp       ax, TF_STROBEFLASH_HIGHBITS
jne       not_strobe
jmp       do_save_strobeflash
not_strobe:
cmp       ax, TF_GLOW_HIGHBITS
je        do_save_glow
jmp       iterate_to_next_special
do_save_glow:
mov       di, _save_p
mov       ax, word ptr [di]
mov       dx, ax
inc       dx
mov       es, word ptr [di + 2]
mov       word ptr [di], dx
mov       di, ax
mov       byte ptr es:[di], 6
mov       di, _save_p
mov       ax, word ptr [di]
mov       dx, ax
mov       di, 4
and       dx, 3
sub       di, dx
mov       dx, di
mov       di, _save_p
and       dx, 3
add       ax, dx
mov       word ptr [di], ax
mov       word ptr [bp - 010h], ax
mov       ax, word ptr [di + 2]
mov       word ptr [bp - 0Ch], ax
mov       di, word ptr [bp - 010h]
mov       es, word ptr [bp - 0Ch]
mov       cx, SIZEOF_GLOW_VANILLA_T / 2
xor       ax, ax
push      di
rep       stosw 
pop       di
mov       ax, word ptr [bx]
cwd       
mov       word ptr es:[di + 0Ch], ax
mov       word ptr es:[di + 0Eh], dx
mov       al, byte ptr [bx + 2]
mov       word ptr es:[di + 012h], 0
xor       ah, ah
mov       word ptr es:[di + 010h], ax
mov       al, byte ptr [bx + 3]
mov       word ptr es:[di + 016h], 0
mov       word ptr es:[di + 014h], ax
mov       ax, word ptr [bx + 4]
mov       bx, di
cwd       
mov       word ptr es:[bx + 018h], ax
mov       word ptr es:[bx + 01ah], dx
mov       bx, _save_p
add       word ptr [bx], SIZEOF_GLOW_VANILLA_T
jmp       iterate_to_next_special
do_save_ceiling:
mov       bx, _save_p
mov       bx, word ptr [bx]
mov       di, _save_p
lea       ax, [bx + 1]
mov       es, word ptr [di + 2]
mov       word ptr [di], ax
mov       byte ptr es:[bx], 0
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
mov       word ptr [bp - 01eh], ax
mov       di, bx
mov       es, word ptr [bp - 01eh]
mov       cx, SIZEOF_CEILING_VANILLA_T / 2
xor       ax, ax
rep       stosw 
mov       di, word ptr [bp - 2]
jmp       do_save_ceiling_stuff
do_save_platraise:
mov       di, _save_p
mov       ax, word ptr [di]
mov       dx, ax
inc       dx
mov       es, word ptr [di + 2]
mov       word ptr [di], dx
mov       di, ax
mov       byte ptr es:[di], 3
mov       di, _save_p
mov       ax, word ptr [di]
mov       dx, ax
mov       di, 4
and       dx, 3
sub       di, dx
mov       dx, di
mov       di, _save_p
and       dx, 3
add       ax, dx
mov       word ptr [di], ax
mov       word ptr [bp - 012h], ax
mov       ax, word ptr [di + 2]
mov       word ptr [bp - 0Ah], ax
mov       di, word ptr [bp - 012h]
mov       es, word ptr [bp - 0Ah]
mov       cx, SIZEOF_PLAT_VANILLA_T / 2
xor       ax, ax
push      di
rep       stosw 

pop       di
mov       ax, word ptr [bx]
cwd       
mov       word ptr es:[di + 0Ch], ax
mov       word ptr es:[di + 0Eh], dx
mov       ax, word ptr [bx + 2]
cwd       
mov       cl, 0Dh
shl       dx, cl
rol       ax, cl
xor       dx, ax
and       ax, 0E000h
xor       dx, ax
mov       word ptr es:[di + 010h], ax
mov       word ptr es:[di + 012h], dx
mov       ax, word ptr [bx + 4]
cwd       
mov       cl, 0Dh
shl       dx, cl
rol       ax, cl
xor       dx, ax
and       ax, 0E000h
xor       dx, ax
mov       word ptr es:[di + 014h], ax
mov       word ptr es:[di + 016h], dx
mov       ax, word ptr [bx + 6]
cwd       
mov       cl, 0Dh
shl       dx, cl
rol       ax, cl
xor       dx, ax
and       ax, 0E000h
xor       dx, ax
mov       word ptr es:[di + 018h], ax
mov       word ptr es:[di + 01ah], dx
mov       al, byte ptr [bx + 8]
cbw      
cwd       
mov       word ptr es:[di + 01ch], ax
mov       word ptr es:[di + 01eh], dx
mov       al, byte ptr [bx + 9]
cbw      
cwd       
mov       word ptr es:[di + 020h], ax
mov       word ptr es:[di + 022h], dx
mov       al, byte ptr [bx + 0Ah]
mov       word ptr es:[di + 026h], 0
xor       ah, ah
mov       word ptr es:[di + 024h], ax
mov       al, byte ptr [bx + 0Bh]
mov       word ptr es:[di + 02ah], 0
mov       word ptr es:[di + 028h], ax
mov       al, byte ptr [bx + 0Ch]
cbw      
cwd       
mov       word ptr es:[di + 02ch], ax
mov       word ptr es:[di + 02eh], dx
mov       al, byte ptr [bx + 0Dh]
cbw      
cwd       
mov       word ptr es:[di + 030h], ax
mov       word ptr es:[di + 032h], dx
mov       al, byte ptr [bx + 0Eh]
mov       bx, di
xor       ah, ah
mov       word ptr es:[bx + 036h], 0
mov       word ptr es:[bx + 034h], ax
mov       bx, _save_p
add       word ptr [bx], SIZEOF_PLAT_VANILLA_T 
jmp       iterate_to_next_special
do_save_lightflash:
mov       di, _save_p
mov       ax, word ptr [di]
mov       dx, ax
inc       dx
mov       es, word ptr [di + 2]
mov       word ptr [di], dx
mov       di, ax
mov       byte ptr es:[di], 4
mov       di, _save_p
mov       ax, word ptr [di]
mov       dx, ax
mov       di, 4
and       dx, 3
sub       di, dx
mov       dx, di
mov       di, _save_p
and       dx, 3
add       ax, dx
mov       word ptr [di], ax
mov       word ptr [bp - 018h], ax
mov       ax, word ptr [di + 2]
mov       word ptr [bp - 016h], ax
les       di, dword ptr [bp - 018h]
mov       cx, SIZEOF_LIGHTFLASH_VANILLA_T / 2
xor       ax, ax
push      di
rep       stosw

pop       di
mov       ax, word ptr [bx]
cwd       
mov       word ptr es:[di + 0Ch], ax
mov       word ptr es:[di + 0Eh], dx
mov       ax, word ptr [bx + 2]
cwd       
mov       word ptr es:[di + 010h], ax
mov       word ptr es:[di + 012h], dx
mov       al, byte ptr [bx + 4]
mov       word ptr es:[di + 016h], 0
xor       ah, ah
mov       word ptr es:[di + 014h], ax
mov       al, byte ptr [bx + 5]
mov       word ptr es:[di + 01ah], 0
mov       word ptr es:[di + 018h], ax
mov       al, byte ptr [bx + 6]
cbw      
cwd       
mov       word ptr es:[di + 01ch], ax
mov       word ptr es:[di + 01eh], dx
mov       al, byte ptr [bx + 7]
cbw      
mov       bx, di
cwd       
mov       word ptr es:[bx + 020h], ax
mov       word ptr es:[bx + 022h], dx
mov       bx, _save_p
add       word ptr [bx], SIZEOF_LIGHTFLASH_VANILLA_T
jmp       iterate_to_next_special
do_save_strobeflash:
mov       di, _save_p
mov       ax, word ptr [di]
mov       dx, ax
inc       dx
mov       es, word ptr [di + 2]
mov       word ptr [di], dx
mov       di, ax
mov       byte ptr es:[di], 5
mov       di, _save_p
mov       ax, word ptr [di]
mov       dx, ax
mov       di, 4
and       dx, 3
sub       di, dx
mov       dx, di
mov       di, _save_p
and       dx, 3
add       ax, dx
mov       word ptr [di], ax
mov       word ptr [bp - 8], ax
mov       ax, word ptr [di + 2]
mov       word ptr [bp - 014h], ax
mov       di, word ptr [bp - 8]
mov       es, word ptr [bp - 014h]
mov       cx, SIZEOF_STROBE_VANILLA_T / 2
xor       ax, ax
push      di
rep       stosw 

pop       di
mov       ax, word ptr [bx]
cwd       
mov       word ptr es:[di + 0Ch], ax
mov       word ptr es:[di + 0Eh], dx
mov       ax, word ptr [bx + 2]
cwd       
mov       word ptr es:[di + 010h], ax
mov       word ptr es:[di + 012h], dx
mov       al, byte ptr [bx + 4]
mov       word ptr es:[di + 016h], 0
xor       ah, ah
mov       word ptr es:[di + 014h], ax
mov       al, byte ptr [bx + 5]
mov       word ptr es:[di + 01ah], 0
mov       word ptr es:[di + 018h], ax
mov       ax, word ptr [bx + 6]
cwd       
mov       word ptr es:[di + 01ch], ax
mov       word ptr es:[di + 01eh], dx
mov       ax, word ptr [bx + 8]
mov       bx, di
cwd       
mov       word ptr es:[bx + 020h], ax
mov       word ptr es:[bx + 022h], dx
mov       bx, _save_p
add       word ptr [bx], SIZEOF_STROBE_VANILLA_T
jmp       iterate_to_next_special
add       byte ptr [bx + si], al
add       byte ptr [bx + si], al

ENDP

PROC P_SAVEEND_
PUBLIC P_SAVEEND_
ENDP


END
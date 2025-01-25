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

call      SaveInt16_            ; 18 -> 22  health
call      SaveInt16_            ; 1A -> 26  armorpoints
call      SaveInt8_             ; 1C -> 2A  armortype


;         si now 1d    di now 2C

lodsb     ; si now 1E               ; playerstate
xor       ah, ah
mov       word ptr es:[di - 028h], ax     ; playerstate is (base)di + 4

;         si now 1E    di now 2C
mov       cx, NUMPOWERS

loop_save_powers:

call      SaveInt16_

loop      loop_save_powers

;         si 02Ah,   di 044h

mov       cx, NUMCARDS
loop_save_keys:
call      SaveInt8_

loop      loop_save_keys

;         si 030h,    di 05Ch
add       di, 014h              ; backpack, MAX_PLAYERS * dword for frag count,
;         si  030h,   di 070h

call      SaveInt8_     ;         si  031h,   di 078h
call      SaveInt8_     ;         si  032h,   di 078h

mov       cx, NUMWEAPONS
loop_save_weaponowned:
call      SaveInt8_
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
call      SaveInt16_

loop      loop_save_ammo

;         si  044h,   di 0ACh

mov       cx, NUMAMMO
loop_save_max_ammo:
call      SaveInt16_
loop      loop_save_max_ammo

;         si  04Ch,   di 0BCh

call      SaveInt8_         ; attackdown       si  04Dh,   di 0C0h
call      SaveInt8_         ; usedown          si  04Eh,   di 0C4h


add       di, 8             ; cheats, refire (c4, c8)
;         si  04Eh,   di 0CCh

call      SaveInt16_         ; killcount       si  050h,   di 0D0h
call      SaveInt16_         ; itemcount       si  052h,   di 0D4h
call      SaveInt16_         ; secretcount     si  054h,   di 0D8h



add       si, 4             ; message, messagestring
add       di, 4             ; message
;         si  058h,   di 0DCh

call      SaveInt16_         ; damagecount     si  05Ah,   di 0E0h
call      SaveInt8_          ; bonuscount      si  05Bh,   di 0E4h


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


call      SaveInt8_          ; extralightvalue      si  05Fh,   di 0ECh
call      SaveInt8_          ; fixedcolormapvalue   si  060h,   di 0F0h
call      SaveUInt8_         ; colormap             si  061h,   di 0F4h



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

call      SaveInt16_   

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

push      dx



; default everything to zero
mov       ax, MOBJPOSLIST_6800_SEGMENT
mov       ds, ax


mov       cx, SIZEOF_MOBJ_VANILLA_T / 2
xor       ax, ax
rep       stosw 


lea       di, [di + 0Ch - SIZEOF_MOBJ_VANILLA_T] ; skip thinker fields and undo rep stosw

movsw   ; x
movsw
movsw   ; y
movsw
movsw   ; z
movsw                   ; di + 18h    si + 0Ch now 

add       di, 8         ; di + 20h    skip snext sprev
add       si, 2         ; si + 0Eh    skip snextRef

movsw   ; angle         ; di + 22h    si + 010h
movsw                   ; di + 24h    si + 012h





lodsw                   ; si + 014h
mov       word ptr es:[di + 040h], ax   ; di + 64h          statenum
xchg      ax, cx        ; cx gets statenum. 

lea       di, [di + 044h]
movsw ; si + 016h di + 6Ah          flags1
movsw ; si + 018h di + 6Ch          flags2

lea       di, [di - 048h]   ; di + 024h


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
lodsb     ; si + 0
stosw     ; sprite  ; di + 026
inc       di
inc       di        ; di + 028
lodsb     ; si + 1
test      ax, FF_FULLBRIGHT
je        skip_framemask
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

add       di, 4     ; skip validcount

lodsb
; ah still 0
stosw               ; di 05Ah <- si 1Bh  type


add       di, 6     ; di 060h <- si 1Bh

call      SaveInt8_ ; di 064h <- si 01Ch  tics


add       di, 08h   ; di 06Ch <- si 01Ch


call      SaveInt16_  ; di 070h <- si 01Eh  health


inc       si        ; si + 01Fh

movsb               ; di 071h <- si 020h   movedir

add       di, 3

call      SaveInt16_  ; di 078h <- si 022h   movecount


add       di, 4     ; di + 07Ch
add       si, 2     ; si + 024h

movsb               ; di 07Dh <- si 025h   reactiontime

add       di, 3     ; di + 080h
movsb               ; di 081h <- si 026h   threshold

add       di, 3     ; di + 084h
; di 05Ah is player

mov       ax, word ptr es:[di - 02Ch]
cmp       ax, MT_PLAYER
jne       not_saving_player
mov       al, 1
stosb
dec       di
not_saving_player:
add       di, 08h   ; di + 08Ch

mov       ax, NIGHTMARESPAWNS_SEGMENT
mov       ds, ax

; get index

pop       dx    ; restore th index. dx was used for cwds above...
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

PROC SaveInt8_ NEAR

lodsb
cbw        ; sign extend 16
cwd        ; sign extend 32
stosw
xchg      ax, dx
stosw     
ret
ENDP

PROC SaveUInt8_ NEAR

movsb 
xor       ax, ax
stosb
stosw
ret
ENDP

PROC SaveInt16_ NEAR

lodsw
cwd       ; sign extend 32
stosw
xchg      ax, dx
stosw     
ret
ENDP

PROC SaveUInt16_ NEAR

movsw    
xor       ax, ax
stosw     
ret
ENDP


tag_conversions_to_vanilla:
dw 1323, 1044, 86, 77, 99, 666, 667, 999

PROC SaveTagToVanilla NEAR
lodsb
xor   ah, ah

cmp   al, 56
jb    use_tag
cmp   al, 63
ja    use_tag
sub   al, 56

sal   ax, 1     ; word lookup
xchg  ax, bx
mov   bx, word ptr cs:[tag_conversions_to_vanilla + bx]
xchg  ax, bx

use_tag:
stosw
xor   ax, ax
stosw
ret

ENDP

PROC SaveShortHeight_ NEAR

lodsw
xchg      ax, dx
xor       ax, ax
sar       dx, 1       ; shift 13 left
rcr       ax, 1
sar       dx, 1
rcr       ax, 1
sar       dx, 1
rcr       ax, 1
stosw
xchg      ax, dx
stosw
ret
ENDP

SIZEOF_CEILING_VANILLA_T = 030h
SIZEOF_FLOORMOVE_VANILLA_T = 02Ah
SIZEOF_VLDOOR_VANILLA_T = 028h
SIZEOF_PLAT_VANILLA_T = 038h
SIZEOF_STROBE_VANILLA_T = 024h
SIZEOF_LIGHTFLASH_VANILLA_T = 024h
SIZEOF_GLOW_VANILLA_T = 01Ch

MAXCEILINGS = 30

; maps func highbits to save marker types
_tc_enum_lookup:
db  -1, 3, 0, 1, 2, -1, 4, 5, 6    

jump_table_archive_specials:
;dw  OFFSET  iterate_to_next_special - OFFSET P_SAVESTART_  ; 1 mobj, skip
;dw  OFFSET  save_platraise_special  - OFFSET P_SAVESTART_  ; 2
;dw  OFFSET  save_ceiling_special    - OFFSET P_SAVESTART_  ; 3
;dw  OFFSET  save_door_special       - OFFSET P_SAVESTART_  ; 4
;dw  OFFSET  save_movefloor_special  - OFFSET P_SAVESTART_  ; 5
;dw  OFFSET  iterate_to_next_special - OFFSET P_SAVESTART_  ; 6 flicker?? not saved apparently, skip
;dw  OFFSET  save_flash_special      - OFFSET P_SAVESTART_  ; 7
;dw  OFFSET  save_strobe_special     - OFFSET P_SAVESTART_  ; 8
;dw  OFFSET  save_glow_special       - OFFSET P_SAVESTART_  ; 9

dw  OFFSET  iterate_to_next_special  ; 1 mobj, skip
dw  OFFSET  save_platraise_special   ; 2
dw  OFFSET  save_ceiling_special     ; 3
dw  OFFSET  save_door_special        ; 4
dw  OFFSET  save_movefloor_special   ; 5
dw  OFFSET  iterate_to_next_special  ; 6 flicker?? not saved apparently, skip
dw  OFFSET  save_flash_special       ; 7
dw  OFFSET  save_strobe_special      ; 8
dw  OFFSET  save_glow_special        ; 9

erase_size_table:
dw  0
dw  SIZEOF_PLAT_VANILLA_T       / 2
dw  SIZEOF_CEILING_VANILLA_T    / 2
dw  SIZEOF_VLDOOR_VANILLA_T     / 2
dw  SIZEOF_FLOORMOVE_VANILLA_T  / 2
dw  0
dw  SIZEOF_LIGHTFLASH_VANILLA_T / 2
dw  SIZEOF_STROBE_VANILLA_T     / 2
dw  SIZEOF_GLOW_VANILLA_T       / 2


PROC P_ArchiveSpecials_ FAR
PUBLIC P_ArchiveSpecials_

push      bx
push      cx
push      dx
push      si
push      di

les       di, dword ptr ds:[_save_p]
mov       cx, word ptr ds:[_thinkerlist + 2]
test      cx, cx
je        exit_archive_specials
save_next_special:
mov       ax, SIZEOF_THINKER_T
mul       cx
xchg      ax, si

mov       ax, word ptr ds:[si + OFFSET _thinkerlist]
and       ax, TF_FUNCBITS



je        is_null_funcbits  ; no thinker. go check to see if its an inactive ceiling though

cmp       ax, TF_FIREFLICKER_HIGHBITS       ; not serialized apparently
je        iterate_to_next_special
cmp       ax, TF_MOBJTHINKER_HIGHBITS       ; not serialized here
je        iterate_to_next_special



rol       ax, 1
rol       ax, 1
rol       ax, 1
rol       ax, 1
rol       ax, 1  ; put func bits (most sig 5) into least sig bits

cmp       ax, 10  ; funcbits too large or delete_me case
jge       iterate_to_next_special
; we do some checks above to guarantee we know this is a valid thinker to serialize so now we can run common code here.



; prep jump addr

dec       ax     ; offset 0 case. could just minus two in the lookup...

force_ceiling:          ; active ceilings jump here from null thinker case.
add       si, OFFSET _thinkerlist + 4   ; data pointer

xchg      ax, bx
mov       al, byte ptr cs:[bx + OFFSET _tc_enum_lookup]
;mov       al, byte ptr cs:[bx + OFFSET _tc_enum_lookup - OFFSET P_SAVESTART_]
stosb     ; write tc_type  

shl       bx, 1  ; word lookup

; PADSAVEP

mov       dx, di
mov       ax, 4
and       dx, 3
sub       ax, dx
and       ax, 3
add       di, ax

; going in:
; mobj is ds:si
; save_p is es:di

; default the thinker memory area to 0.

push      cx
mov       dx, word ptr cs:[bx + OFFSET erase_size_table ]
;mov       dx, word ptr cs:[bx + OFFSET erase_size_table - OFFSET P_SAVESTART_]
mov       cx, dx
xor       ax, ax
rep       stosw 
pop       cx

sal       dx, 1
sub       di, dx ; reset di 

add       di, 12 ; skip 12 byte thinker field



jmp       word ptr cs:[bx + OFFSET jump_table_archive_specials ]
;jmp       word ptr cs:[bx + OFFSET jump_table_archive_specials - OFFSET P_SAVESTART_]

iterate_to_next_special:

mov       ax, SIZEOF_THINKER_T
mul       cx
xchg      ax, bx

mov       cx, word ptr ds:[bx + OFFSET _thinkerlist + 2]    ; thinker next
test      cx, cx
jne       save_next_special
exit_archive_specials:

mov       al, 7
stosb
mov       word ptr ds:[_save_p], di

pop       di
pop       si
pop       dx
pop       cx
pop       bx
retf      

is_null_funcbits:
mov       bx, OFFSET _activeceilings
xor       ax, ax
cmp       cx, word ptr ds:[bx]
je        end_ceiling_search

check_next_ceiling:
inc       ax
add       bx, 2
cmp       ax, MAXCEILINGS
jge       iterate_to_next_special
cmp       cx, word ptr ds:[bx]
jne       check_next_ceiling
end_ceiling_search:
mov       ax, 2                 ; tc_ceil flag
jmp       force_ceiling


save_door_special:
call      SaveInt8_         ; type,        di = 010h, si = 01h
call      SaveUInt16_       ; sector       di = 014h, si = 03h
call      SaveShortHeight_  ; topheight    di = 018h, si = 05h
call      SaveShortHeight_  ; speed        di = 01Ch, si = 07h
call      SaveInt16_        ; direction    di = 020h, si = 09h
call      SaveInt16_        ; topwait      di = 024h, si = 0Bh
call      SaveInt16_        ; topcountdown di = 028h, si = 0Dh
jmp       iterate_to_next_special

save_movefloor_special:
call      SaveInt8_         ; type              di = 010h, si = 01h
call      SaveUInt8_        ; crush             di = 014h, si = 02h
call      SaveUInt16_       ; sector            di = 018h, si = 04h
call      SaveInt8_         ; direction         di = 01Ch, si = 05h
call      SaveUInt8_        ; newspecial        di = 020h, si = 06h
movsw                       ; texture           di = 022h, si = 08h
call      SaveShortHeight_  ; floordestheight   di = 026h, si = 0Ah
call      SaveShortHeight_  ; speed             di = 02Ah, si = 0Ch
jmp       iterate_to_next_special

save_glow_special:
call      SaveUInt16_       ; sector            di = 010h, si = 02h
call      SaveUInt8_        ; minlight          di = 014h, si = 03h
call      SaveUInt8_        ; maxlight          di = 018h, si = 04h
call      SaveInt16_        ; direction         di = 01Ch, si = 06h
jmp       iterate_to_next_special

save_ceiling_special:
call      SaveInt8_         ; type              di = 010h, si = 01h
call      SaveUInt16_       ; sector            di = 014h, si = 03h
call      SaveShortHeight_  ; bottomheight      di = 018h, si = 05h
call      SaveShortHeight_  ; topheight         di = 01Ch, si = 07h
call      SaveShortHeight_  ; speed             di = 020h, si = 09h
call      SaveUInt8_        ; crush             di = 024h, si = 0Ah
call      SaveInt8_         ; direction         di = 028h, si = 0Bh
call      SaveTagToVanilla  ; tag               di = 02Ch, si = 0Ch
call      SaveInt8_         ; olddirection      di = 030h, si = 0Dh
jmp       iterate_to_next_special

save_platraise_special:
call      SaveUInt16_       ; sector            di = 010h, si = 02h
call      SaveShortHeight_  ; speed             di = 014h, si = 04h
call      SaveShortHeight_  ; low               di = 018h, si = 06h
call      SaveShortHeight_  ; high              di = 01Ch, si = 08h
call      SaveInt8_         ; wait              di = 020h, si = 0Ah
call      SaveInt8_         ; count             di = 024h, si = 0Bh
call      SaveUInt8_        ; status            di = 028h, si = 0Ch
call      SaveUInt8_        ; oldstatus         di = 02Ch, si = 0Dh
call      SaveUInt8_        ; crush             di = 030h, si = 0Eh
call      SaveTagToVanilla  ; tag               di = 034h, si = 0Fh
call      SaveUInt8_        ; type              di = 038h, si = 10h

    
jmp       iterate_to_next_special

save_flash_special:
call      SaveUInt16_       ; sector            di = 010h, si = 02h
call      SaveInt16_        ; count             di = 014h, si = 04h
call      SaveUInt8_        ; maxlight          di = 018h, si = 05h
call      SaveUInt8_        ; minlight          di = 01Ch, si = 06h
call      SaveInt8_         ; maxtime           di = 020h, si = 07h
call      SaveInt8_         ; mintime           di = 024h, si = 08h
jmp       iterate_to_next_special

save_strobe_special:
call      SaveUInt16_       ; sector            di = 010h, si = 02h
call      SaveInt16_        ; count             di = 014h, si = 04h
call      SaveUInt8_        ; minlight          di = 018h, si = 05h
call      SaveUInt8_        ; maxlight          di = 01Ch, si = 06h
call      SaveInt16_        ; darktime          di = 020h, si = 08h
call      SaveInt16_        ; brighttime        di = 024h, si = 0Ah
jmp       iterate_to_next_special





ENDP

PROC P_SAVEEND_
PUBLIC P_SAVEEND_
ENDP


END
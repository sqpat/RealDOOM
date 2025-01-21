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




EXTRN I_Error_:PROC
EXTRN P_InitThinkers_:PROC
EXTRN P_CreateThinker_:PROC
EXTRN P_SetThingPosition_:PROC
EXTRN P_RemoveMobj_:PROC

EXTRN _save_p:DWORD
EXTRN _playerMobjRef:WORD
EXTRN _numlines:WORD
EXTRN _numsectors:WORD
EXTRN _player:PLAYER_T

.CODE
 
PROC P_LOADSTART
PUBLIC P_LOADSTART
ENDP

SIZEOF_PLAYER_VANILLA_T = 0118h
SIZEOF_PSPDEF_VANILLA_T = 16
SIZEOF_PSPDEF_T = 12
NUMPSPRITES = 2
NUMPOWERS = 6
NUMCARDS = 6
NUMAMMO = 4


PLAYER_T STRUC 

    ; cmd struct 8 bytes
    player_cmd_forwardmove    db ?
    player_cmd_sidemove       db ?
    player_cmd_angleturn      dw ?
    player_cmd_consistancy    dw ?
    player_cmd_chatchar       db ?
    player_cmd_buttons        db ?
    player_viewzvalue         dd ?
    player_viewheightvalue    dd ?
    player_deltaviewheight    dd ?
    player_bob                dd ?
    player_health             dw ?
    player_armorpoints        dw ?
    player_armortype	      db ?
    player_playerstate        db ?
    player_powers             dw NUMPOWERS   DUP(?)
    player_cards              db NUMCARDS    DUP(?)
    player_readyweapon        db ?
    player_pendingweapon      db ?
    player_weaponowned        db NUMWEAPONS  DUP(?)
    player_cheats		      db ?
    player_ammo               dw NUMAMMO     DUP(?)
    player_maxammo            dw NUMAMMO     DUP(?)
    player_attackdown         db ?
    player_usedown            db ?
    player_killcount          dw ?
    player_itemcount          dw ?
    player_secretcount        dw ?
    player_message            dw ?
	player_messagestring      dw ?
    player_damagecount        dw ?
    player_bonuscount         db ?
    player_refire		      db ?
    player_attackerRef        dw ?
    player_extralightvalue    db ?
    player_fixedcolormapvalue db ?
    player_colormap	          db ?
    player_didsecret	      db ?
    player_backpack           db ?

PLAYER_T ENDS


; copy string from cs:ax to ds:_filename_argument
; return _filename_argument in ax

PROC CopyString13Save_ NEAR
PUBLIC CopyString13Save_

push  si
push  di
push  cx

mov   di, OFFSET _filename_argument

push  ds
pop   es    ; es = ds

push  cs
pop   ds    ; ds = cs

mov   si, ax

mov   ax, 0
stosw       ; zero out
stosw
stosw
stosw
stosw
stosw
stosb

mov  cx, 13
sub  di, cx

do_next_char:
lodsb
stosb
test  al, al
je    done_writing
loop do_next_char


done_writing:

mov   ax, OFFSET _filename_argument   ; ax now points to the near string

push  ss
pop   ds    ; restore ds

pop   cx
pop   di
pop   si

ret

ENDP



PROC P_UnArchivePlayers_  FAR
PUBLIC P_UnArchivePlayers_


push  bx
push  cx
push  si
push  di

mov   ax, word ptr [_save_p]

;	PADSAVEP();
and   ax, 3
jz    dont_pad
mov   cx, 4
sub   cx, ax
add   word ptr [_save_p], cx
dont_pad:
les   bx, dword ptr [_save_p]

mov   al, byte ptr es:[bx + 4]
mov   byte ptr [_player + 01Dh], al


push  es  ; swap ds/es
push  ds
pop   es
pop   ds
lea   si, [bx + 8]
mov   di, OFFSET _player

mov   cx, 13
rep   movsw
mov   cx, bx
inc   si
inc   si
movsw           ; 024h -> 01Ah
inc   si
inc   si
movsw           ; 028h -> 01Ch

push  es  ; swap ds/es
push  ds
pop   es
pop   ds



mov   al, byte ptr es:[bx + 05Ch]
mov   byte ptr [_player + 022h], al

mov   al, byte ptr es:[bx + 070h]
mov   ah, byte ptr es:[bx + 074h]
mov   word ptr [_player + 030h], ax

mov   al, byte ptr es:[bx + 0BCh]
mov   ah, byte ptr es:[bx + 0C0h]
mov   word ptr [_player + 04Ch], ax

mov   al, byte ptr es:[bx + 0C4h]
mov   byte ptr [_player + 03Bh], al
mov   al, byte ptr es:[bx + 0C8h]
mov   byte ptr [_player + 05Dh], al

mov   ax, word ptr es:[bx + 0CCh]
mov   word ptr [_player + 043h], ax
mov   ax, word ptr es:[bx + 0D0h]
mov   word ptr [_player + 050h], ax
mov   ax, word ptr es:[bx + 0D4h]
mov   word ptr [_player + 052h], ax
mov   ax, word ptr es:[bx + 0DCh]
mov   word ptr [_player + 058h], ax
mov   al, byte ptr es:[bx + 0E0h]
mov   byte ptr [_player + 05Ah], al

mov   al, byte ptr es:[bx + 0E8h]
mov   ah, byte ptr es:[bx + 0ECh]
mov   word ptr [_player + 05Eh], ax

mov   al, byte ptr es:[bx + 0F0h]
mov   ah, byte ptr es:[bx + 0114h]
mov   word ptr [_player + 060h], ax

mov   si, cx
xor   bx, bx
load_next_power:
add   bx, 2
mov   ax, word ptr es:[si + 02Ch]
add   si, 4
mov   word ptr [bx + _player + 01Ch], ax
cmp   bx, NUMPOWERS * 2  ; sizeof dw
jne   load_next_power
mov   si, cx
xor   bx, bx

load_next_key:
inc   bx
mov   al, byte ptr es:[si + 044h]
add   si, 4
mov   byte ptr [bx + _player + 029h], al
cmp   bx, NUMCARDS
jl    load_next_key
mov   si, cx
xor   bx, bx

load_next_ammo:
mov   ax, word ptr es:[si + 09ch]
mov   word ptr [bx + _player + 03Ch], ax
inc   bx
inc   bx
mov   ax, word ptr es:[si + 0ach]
add   si, 4
mov   word ptr [bx + _player + 042h], ax
cmp   bx, NUMAMMO * 2
jne   load_next_ammo
mov   si, cx
xor   bx, bx

load_next_weapon:
inc   bx
mov   al, byte ptr es:[si + 078h]
add   si, 4
mov   byte ptr [bx + _player + 031h], al
cmp   bx, NUMWEAPONS
jl    load_next_weapon
mov   si, cx
xor   bx, bx
load_next_sprite:
mov   ax, word ptr es:[si + 0F4h]
mov   word ptr [bx + _psprites], ax
test  ax, ax
je    set_psprite_statenum_null
done_with_psprite:
mov   ax, word ptr es:[si + 0F8h]
mov   word ptr [bx + _psprites + 2], ax
mov   ax, word ptr es:[si + 0FCh]
mov   word ptr [bx + _psprites + 4], ax
mov   ax, word ptr es:[si + 0FEh]
mov   word ptr [bx + _psprites + 6], ax
mov   ax, word ptr es:[si + 0100h]
mov   word ptr [bx + _psprites + 8], ax
mov   ax, word ptr es:[si + 0102h]
mov   word ptr [bx + _psprites + 0Ah], ax
add   si, SIZEOF_PSPDEF_VANILLA_T
add   bx, SIZEOF_PSPDEF_T
cmp   bx, SIZEOF_PSPDEF_T * NUMPSPRITES
jne   load_next_sprite
mov   word ptr [_player + 056h], 0FFFFh
xor   ax, ax
add   word ptr [_save_p], SIZEOF_PLAYER_VANILLA_T 
mov   word ptr [_playerMobjRef], ax
mov   word ptr [_player + 05Ch], ax

pop   di
pop   si
pop   cx
pop   bx
retf  
set_psprite_statenum_null:
mov   word ptr [bx + _psprites], 0FFFFh
jmp   done_with_psprite



ENDP





SIZEOF_SECTOR_T = 16
SIZEOF_SECTOR_PHYSICS_T = 16
SIZEOF_LINE_PHYSICS_T = 16
SIZEOF_LINE_T = 4

PROC P_UnArchiveWorld_  FAR
PUBLIC P_UnArchiveWorld_


push  bx
push  cx
push  dx
push  si
push  di

mov   cx, SECTORS_SEGMENT
mov   es, cx


mov   cx, word ptr [_numsectors]

mov   bx, _sectors_physics      ; in near segment. use SS
lds   si, dword ptr [_save_p]
xor   di, di


load_next_sector:

lodsw           
shl   ax, 1
shl   ax, 1
shl   ax, 1
stosw           ; 00 -> 00

lodsw           
shl   ax, 1
shl   ax, 1
shl   ax, 1
stosw           ; 02 -> 02

lodsw
stosb           ; 04 -> 04

lodsw
stosb           ; 06 -> 05

xor   ax, ax
inc   di
inc   di
stosb           ; (zero) -> 08

lodsw           
mov   byte ptr es:[di+5], al        ; 08 -> 0Eh   ; di is 9, 9 + 5 = e..

; write sector_phys stuff

lodsw           
mov   byte ptr ss:[bx + 0Eh], al
lodsw
mov   byte ptr ss:[bx + 0Fh], al
mov   word ptr ss:[bx + 8], 0

add   di, (SIZEOF_SECTOR_T - 9)
add   bx, SIZEOF_SECTOR_PHYSICS_T

loop  load_next_sector

done_loading_sectors:


; loop counter
xor   dx, dx


do_load_lines:

xor   di, di
load_next_line:
mov   ax, LINEFLAGSLIST_SEGMENT
mov   es, ax

mov   bx, dx  ; get counter
mov   ch, dl
mov   cl, 8
and   ch, 7
sub   cl, ch    ; cl has (8-(i % 8));

lodsw          
mov   byte ptr es:[bx], al          ; copy 8 flags...

and   ax, 0100h
sar   ax, cl    ; dl has the flag.


mov   cx, SEENLINES_6800_SEGMENT
mov   es, cx
sar   bx, 1
sar   bx, 1
sar   bx, 1
or    byte ptr es:[bx], al



; copy li_phys felds
mov   ax, LINES_PHYSICS_SEGMENT
mov   es, ax
lodsw
mov   byte ptr es:[di + 0Fh], al
lodsw
mov   byte ptr es:[di + 0Eh], al


; time to do sides...

xor   cx, cx  ; line count
load_next_side:
mov   bx, di
sar   bx, 1
sar   bx, 1   ; LINES offset

mov   ax, LINES_SEGMENT
mov   es, ax

add   bx, cx                ; add side offset.
mov   bx, word ptr es:[bx] 

cmp   bx, 0FFFFh
je    skip_side

mov   ax, SIDES_RENDER_9000_SEGMENT
mov   es, ax
sal   bx, 1
sal   bx, 1  ; 4 bytes per.

push  dx
lodsw 
xchg   ax, dx    ; hold onto this
lodsw
mov   word ptr es:[bx]  , ax    ; rowoffset

mov   ax, SIDES_SEGMENT
mov   es, ax
sal   bx, 1    ; 8 bytes each, not 4

lodsw 
mov   word ptr es:[bx+0], ax    ; top
lodsw 
mov   word ptr es:[bx+2], ax    ; mid
lodsw 
mov   word ptr es:[bx+4], ax    ; bot
mov   word ptr es:[bx+6], dx    ; textureoffset
pop   dx

skip_side:
add   cx, 2
cmp   cx, 4
jnge  load_next_side


finish_line_iteration:
inc   dx
add   di, SIZEOF_LINE_PHYSICS_T
cmp   dx, word ptr ss:[_numlines]
jge   done_loading_lines
jmp   load_next_line
done_loading_lines:



push  ss
pop   ds

mov   word ptr [_save_p], si

pop   di
pop   si
pop   dx
pop   cx
pop   bx
retf  



ENDP

str_bad_tclass:
db "Unknown tclass %i in savegame", 0

SIZEOF_THINKER_T = 44
SIZEOF_MOBJ_VANILLA_T = 09Ah
SIZEOF_MOBJ_T = 028h
SIZEOF_MOBJPOS_T = 018h
SIZEOF_THINKER_VANILLA_T = 12
SIZEOF_MAPTHING_T = 10

PROC P_UnArchiveThinkers_  FAR
PUBLIC P_UnArchiveThinkers_


push      bx
push      cx
push      dx
push      si
push      di
push      bp
mov       bp, sp
sub       sp, 6
mov       si, word ptr ds:[_thinkerlist + 2]       ; currentthinker = thinkerlist[0].next...



loop_zeroing_thinkers:
mov       ax, SIZEOF_THINKER_T
mul       si

mov       di, ax                               ; thinker_t offset
mov       ax, word ptr ds:[di + _thinkerlist]     ; prevfunctype

mov       si, word ptr ds:[_thinkerlist + di + 2] ; get thinker next
add       di, (_thinkerlist + 4)        ; di = thinkerlist.data
and       ax, TF_FUNCBITS
cmp       ax, TF_MOBJTHINKER_HIGHBITS
je        call_removemobj
; zero out thinker
mov       cx, SIZEOF_MOBJ_T / 2
push      ds
pop       es    ; for rep stosw in loop
xor       ax, ax
rep stosw 

jmp       check_next_thinker_to_zero

handle_load_non_thinker:
test      al, al                ; test for end marker
jne       bad_thinkerclass

exit_unarchivethinkers:

LEAVE_MACRO     
push      ss
pop       ds
;sub       si, word ptr [_save_p]
mov       word ptr [_save_p], si
pop       di
pop       si
pop       dx
pop       cx
pop       bx
retf      

bad_thinkerclass:
push      ss
pop       ds
xor       ah, ah
push      ax

mov ax, OFFSET str_bad_tclass
call CopyString13Save_
push      ax
call      I_Error_
;add       sp, 4
;jmp       load_next_thinker

call_removemobj:
mov       ax, di
call      P_RemoveMobj_
check_next_thinker_to_zero:
test      si, si
jne       loop_zeroing_thinkers

call      P_InitThinkers_

; zero blocklinks.
mov       cx, MAX_BLOCKLINKS_SIZE / 2
mov       ax, BLOCKLINKS_SEGMENT
mov       es, ax
xor       ax, ax
xor       di, di
rep stosw 

mov       si, word ptr [_save_p]

load_next_thinker:
mov       ds, word ptr  ss:[_save_p+2]
lodsb

cmp       al, 1
jne       handle_load_non_thinker
handle_load_thinker:
; PADSAVEP();
mov       ax, si
and       ax, 3
jz        dont_pad_2
mov       dx, 4
sub       dx, ax
add       si, dx
dont_pad_2:
mov       ax, TF_MOBJTHINKER_HIGHBITS
xor       dx, dx
push      ds                              ; store p_save seg
push      ss
pop       ds                              ; restore ds to normal
call      P_CreateThinker_
pop       ds                              ; ds is save seg again

mov       bx, ax                          ; mobj pointer to bx
mov       word ptr [bp - 6], ax           ; store mobj pointer              ; alternatively, push/pop
sub       ax, ((_thinkerlist + 4))        ; get thinkerlist offset
xor       dx, dx
mov       cx, SIZEOF_THINKER_T
div       cx
mov       cx, ax                          ; cx = thinkerref

mov       dx, SIZEOF_MOBJPOS_T
mul       dx
mov       di, ax                          ; di has mobjpos_t offset
xchg      ax, dx                          ; dx also holds on to mobjpos_t base 


mov       ax, MOBJPOSLIST_6800_SEGMENT
mov       es, ax


add       si, SIZEOF_THINKER_VANILLA_T      ; si + 0Ch skip this section

mov       word ptr es:[di + 12], 0     ; snextRef

movsw   ; x
movsw
movsw   ; y
movsw
movsw   ; z
movsw                   ; si + 18h    di + 0Ch now 

add       si, 8         ; si + 20h skip snext sprev
add       di, 2         ; di + 0Eh

movsw   ; angle         ; si + 22h    di + 010h
movsw                   ; si + 24h    di + 012h

mov       ax, word ptr ds:[si + 040h]   ; si + 64h
stosw                                   ; statenum  di + 014h
mov       ax, word ptr ds:[si + 044h]   ; si + 68h
stosw                                   ; flags1    di + 016h
mov       ax, word ptr ds:[si + 046h]   ; si + 6Ah
stosw                                   ; flags2    di + 018h

add       si, 01Eh      ; si + 42h . skip a bunch of stuff related to sprites, bprev..

push      ss
pop       es

mov       di, bx

;es:di now mobj

lodsw     
mov       byte ptr es:[di + 01eh], al   ; 042h -> 01Eh radius

xor       ax, ax
mov       word ptr es:[di + 2], ax      ; bnextref
mov       word ptr es:[di + 022h], ax   ; targref

lea       di, [di + 0Ah]

movsw      
movsw               ; 048h -> 0Eh  height
movsw
movsw               ; 04Ch -> 12h  momx
movsw
movsw               ; 050h -> 16h  momy
movsw
movsw               ; 054h -> 1Ah  momz

add       si, 4
lodsw
stosb               ; 05Ah -> 1Bh  type

cmp       al, MT_PLAYER
jne       not_loading_player

mov       word ptr ss:[_playerMobjRef], cx  ; ds is clobbered. use ss.
not_loading_player:


add       si, 6
lodsw
stosb               ; 062h -> 1Ch  tics

add       si, 0Ah
movsw               ; 06Eh -> 1Eh  health

add       si, 2     ; si + 070h
inc       di        ; di + 01Fh

movsb               ; 71h -> 20h   movedir

add       si, 3
movsw               ; 76h -> 22h   movecount

add       si, 6     ; si + 07Ch
add       di, 2     ; di + 024h

movsb               ; 7Dh -> 25h   reactiontime

add       si, 3     ; si + 080h
movsb               ; 81h -> 26h   threshold


add       si, 0Bh   ; si + 08Ch

mov       ax, NIGHTMARESPAWNS_SEGMENT
mov       es, ax

mov       ax, SIZEOF_MAPTHING_T
xchg      cx, dx                    ; dx will be clobbered..
mul       dx

xchg      ax, di

; si is 8Ch

; copy nightmarespawn
movsw     
movsw     
movsw     
movsw     
movsw     ; si + 096h

; si now 096h

xchg      ax, di ; restore di to mobj




mov       ax, bx            ; mobj pointer
mov       di, ax            ; store mobj pointer in di

mov       bx, cx                           ; mobjposlist offset
mov       cx, MOBJPOSLIST_6800_SEGMENT     ; mobjposlist segment
mov       dx, 0FFFFh                       ; -1

push      ss
pop       ds                            ; restore ds

call      P_SetThingPosition_
; di is mobj
mov       bx, word ptr [di + 4]            ; get mobj secnum
mov       ax, SECTORS_SEGMENT
mov       es, ax
shl       bx, 1
shl       bx, 1
shl       bx, 1
shl       bx, 1
mov       ax, word ptr es:[bx]
mov       word ptr [di + 6], ax              ; floorz
mov       ax, word ptr es:[bx + 2]
mov       word ptr [di + 8], ax              ; ceilingz


add       si, (SIZEOF_MOBJ_VANILLA_T - 096h) ; add 4 (for tracer)
jmp       load_next_thinker





ENDP


END
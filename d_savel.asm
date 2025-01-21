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

PROC CopyString13_ NEAR
PUBLIC CopyString13_

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


PROC P_UnArchiveThinkers_  FAR
PUBLIC P_UnArchiveThinkers_


push      bx
push      cx
push      dx
push      si
push      di
push      bp
mov       bp, sp
sub       sp, 8
mov       bx, _thinkerlist + 2    ; thinkerlist next
mov       dx, word ptr [bx]

imul      bx, ax, SIZEOF_THINKER_T
loop_zeroing_thinkers:
imul      di, dx, SIZEOF_THINKER_T
mov       ax, word ptr [bx + _thinkerlist]

add       di, (_thinkerlist + 4)
and       ax, TF_FUNCBITS
mov       dx, word ptr [di - 2]         ; get next
cmp       ax, TF_MOBJTHINKER_HIGHBITS
je        call_removemobj
; zero out thinker
mov       cx, SIZEOF_MOBJ_T / 2

push      ds
pop       es
mov       ah, al
rep stosw 

sub       di, SIZEOF_MOBJ_T

jmp       check_next_thinker_to_zero

call_removemobj:
mov       ax, di
call      P_RemoveMobj_
check_next_thinker_to_zero:
test      dx, dx
jne       loop_zeroing_thinkers

call      P_InitThinkers_
mov       cx, MAX_BLOCKLINKS_SIZE / 2
mov       dx, BLOCKLINKS_SEGMENT
xor       al, al
xor       di, di
mov       es, dx
push      di
mov       ah, al
rep stosw 

pop       di
load_next_thinker:
les       bx, dword ptr [_save_p]
mov       dl, byte ptr es:[bx]
inc       bx
mov       word ptr [_save_p], bx
cmp       dl, 1
je        label_7
jmp       label_6
label_7:
mov       ax, bx
mov       dx, 4
and       ax, 3
sub       dx, ax
mov       ax, dx
mov       cx, SIZEOF_THINKER_T
and       ax, 3
add       word ptr [_save_p], ax
mov       ax, TF_MOBJTHINKER_HIGHBITS
xor       dx, dx
call      P_CreateThinker_
mov       bx, ax
mov       word ptr [bp - 6], ax
sub       ax, ((_thinkerlist + 4))        ; todo fix this garbage...?
div       cx
mov       cx, ax
imul      si, ax, SIZEOF_MOBJPOS_T
mov       word ptr [bp - 2], MOBJPOSLIST_6800_SEGMENT
mov       word ptr [bp - 4], si
mov       es, word ptr [_save_p+2]
mov       di, word ptr [bp - 4]
mov       si, word ptr [_save_p]
mov       word ptr [bp - 8], es
mov       dx, word ptr es:[si + 0Ch]
mov       ax, word ptr es:[si + 0Eh]
mov       es, word ptr [bp - 2]
mov       word ptr es:[di], dx
mov       word ptr es:[di + 2], ax
mov       es, word ptr [bp - 8]
mov       ax, word ptr es:[si + 010h]
mov       dx, word ptr es:[si + 012h]
mov       es, word ptr [bp - 2]
mov       word ptr es:[di + 4], ax
mov       word ptr es:[di + 6], dx
mov       es, word ptr [bp - 8]
mov       dx, word ptr es:[si + 014h]
mov       ax, word ptr es:[si + 016h]
mov       es, word ptr [bp - 2]
mov       word ptr es:[di + 8], dx
mov       word ptr es:[di + 0Ah], ax
mov       es, word ptr [bp - 8]
mov       ax, word ptr es:[si + 020h]
mov       dx, word ptr es:[si + 022h]
mov       es, word ptr [bp - 2]
mov       word ptr es:[di + 0Eh], ax
mov       word ptr es:[di + 010h], dx
mov       es, word ptr [bp - 8]
mov       ax, word ptr es:[si + 064h]
mov       es, word ptr [bp - 2]
mov       word ptr es:[di + 012h], ax
mov       es, word ptr [bp - 8]
mov       ax, word ptr es:[si + 068h]
mov       dx, word ptr es:[si + 06ah]
mov       es, word ptr [bp - 2]
mov       word ptr es:[di + 014h], ax
mov       word ptr es:[di + 016h], dx
imul      di, cx, 0Ah
mov       es, word ptr [bp - 8]
mov       ax, word ptr es:[si + 042h]
mov       byte ptr [bx + 01eh], al
mov       ax, word ptr es:[si + 044h]
mov       dx, word ptr es:[si + 046h]
mov       word ptr [bx + 0Ah], ax
mov       word ptr [bx + 0Ch], dx
mov       ax, word ptr es:[si + 048h]
mov       dx, word ptr es:[si + 04ah]
mov       word ptr [bx + 0Eh], ax
mov       word ptr [bx + 010h], dx
mov       ax, word ptr es:[si + 04ch]
mov       dx, word ptr es:[si + 04eh]
mov       word ptr [bx + 012h], ax
mov       word ptr [bx + 014h], dx
mov       ax, word ptr es:[si + 050h]
mov       dx, word ptr es:[si + 052h]
mov       word ptr [bx + 016h], ax
mov       word ptr [bx + 018h], dx
mov       al, byte ptr es:[si + 058h]
mov       byte ptr [bx + 01ah], al
mov       al, byte ptr es:[si + 060h]
mov       byte ptr [bx + 01bh], al
mov       ax, word ptr es:[si + 06ch]
mov       word ptr [bx + 01ch], ax
mov       al, byte ptr es:[si + 070h]
mov       byte ptr [bx + 01fh], al
mov       ax, word ptr es:[si + 074h]
mov       word ptr [bx + 020h], ax
mov       al, byte ptr es:[si + 07ch]
mov       byte ptr [bx + 024h], al
mov       al, byte ptr es:[si + 080h]
push      ds
mov       byte ptr [bx + 025h], al
mov       ax, NIGHTMARESPAWNS_SEGMENT
mov       ds, word ptr [bp - 8]
mov       es, ax
lea       si, [si + 08ch]                 ; todo this
movsw     
movsw     
movsw     
movsw     
movsw     
pop       ds
mov       si, word ptr [bp - 4]
mov       word ptr [bx + 2], 0
mov       es, word ptr [bp - 2]
mov       word ptr es:[si + 0Ch], 0
mov       word ptr [bx + 022h], 0
cmp       byte ptr [bx + 01ah], 0
je        record_player_mobj
label_2:
mov       dx, 0FFFFh
mov       bx, word ptr [bp - 4]
mov       cx, word ptr [bp - 2]
mov       ax, word ptr [bp - 6]
call      P_SetThingPosition_
mov       bx, word ptr [bp - 6]
mov       bx, word ptr [bx + 4]
mov       ax, SECTORS_SEGMENT
shl       bx, 4
mov       es, ax
mov       ax, word ptr es:[bx]
mov       bx, word ptr [bp - 6]
mov       word ptr [bx + 6], ax
mov       bx, word ptr [bx + 4]
shl       bx, 4
add       bx, 2
mov       ax, word ptr es:[bx]
mov       bx, word ptr [bp - 6]
add       word ptr [_save_p], SIZEOF_MOBJ_VANILLA_T 
mov       word ptr [bx + 8], ax
jmp       load_next_thinker

label_6:
test      dl, dl
jne       bad_thinkerclass
leave     
pop       di
pop       si
pop       dx
pop       cx
pop       bx
retf      
record_player_mobj:
mov       word ptr [_playerMobjRef], cx
jmp       label_2
bad_thinkerclass:
xor       dh, dh
push      dx

mov ax, OFFSET str_bad_tclass
call CopyString13_

push      ax

call      I_Error_
add       sp, 4
jmp       load_next_thinker

ENDP


END
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
INCLUDE defs.inc
INSTRUCTION_SET_MACRO





.CODE
 
PROC P_LOADSTART_
PUBLIC P_LOADSTART_
ENDP

_CSDATA_playerMobjRef_ptr:
dw    0



PROC P_UnArchivePlayers_  FAR
PUBLIC P_UnArchivePlayers_


push  bx
push  cx
push  si
push  di

mov   ax, word ptr ds:[_save_p]

;	PADSAVEP();
and   ax, 3
jz    dont_pad
mov   cx, 4
sub   cx, ax
add   word ptr ds:[_save_p], cx
dont_pad:
les   bx, dword ptr ds:[_save_p]

mov   al, byte ptr es:[bx + 4]

mov   di, OFFSET _player
mov   byte ptr ds:[di + 01Dh], al


push  es  ; swap ds/es
push  ds
pop   es
pop   ds
lea   si, ds:[bx + 8]

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

mov   di, OFFSET _player

mov   al, byte ptr es:[bx + 05Ch]
mov   byte ptr ds:[di + 022h], al

mov   al, byte ptr es:[bx + 070h]
mov   ah, byte ptr es:[bx + 074h]
mov   word ptr ds:[di + 030h], ax

mov   al, byte ptr es:[bx + 0BCh]
mov   ah, byte ptr es:[bx + 0C0h]
mov   word ptr ds:[di + 04Ch], ax

mov   al, byte ptr es:[bx + 0C4h]
mov   byte ptr ds:[di + 03Bh], al
mov   al, byte ptr es:[bx + 0C8h]
mov   byte ptr ds:[di + 05Dh], al

mov   ax, word ptr es:[bx + 0CCh]
mov   word ptr ds:[di + 043h], ax
mov   ax, word ptr es:[bx + 0D0h]
mov   word ptr ds:[di + 050h], ax
mov   ax, word ptr es:[bx + 0D4h]
mov   word ptr ds:[di + 052h], ax
mov   ax, word ptr es:[bx + 0DCh]
mov   word ptr ds:[di + 058h], ax
mov   al, byte ptr es:[bx + 0E0h]
mov   byte ptr ds:[di + 05Ah], al

mov   al, byte ptr es:[bx + 0E8h]
mov   ah, byte ptr es:[bx + 0ECh]
mov   word ptr ds:[di + 05Eh], ax

mov   al, byte ptr es:[bx + 0F0h]
mov   ah, byte ptr es:[bx + 0114h]
mov   word ptr ds:[di + 060h], ax

mov   si, cx
xor   bx, bx
load_next_power:
add   bx, 2
mov   ax, word ptr es:[si + 02Ch]
add   si, 4
mov   word ptr ds:[bx + di + 01Ch], ax
cmp   bx, NUMPOWERS * 2  ; sizeof dw
jne   load_next_power
mov   si, cx
xor   bx, bx

load_next_key:
inc   bx
mov   al, byte ptr es:[si + 044h]
add   si, 4
mov   byte ptr ds:[bx + di + 029h], al
cmp   bx, NUMCARDS
jl    load_next_key
mov   si, cx
xor   bx, bx

load_next_ammo:
mov   ax, word ptr es:[si + 09ch]
mov   word ptr ds:[bx + di + 03Ch], ax
inc   bx
inc   bx
mov   ax, word ptr es:[si + 0ach]
add   si, 4
mov   word ptr ds:[bx + di + 042h], ax
cmp   bx, NUMAMMO * 2
jne   load_next_ammo
mov   si, cx
xor   bx, bx

load_next_weapon:
inc   bx
mov   al, byte ptr es:[si + 078h]
add   si, 4
mov   byte ptr ds:[bx + di + 031h], al
cmp   bx, NUMWEAPONS
jl    load_next_weapon
mov   si, cx
xor   bx, bx
load_next_sprite:
mov   ax, word ptr es:[si + 0F4h]
mov   word ptr ds:[bx + _psprites], ax
test  ax, ax
je    set_psprite_statenum_null
done_with_psprite:
mov   ax, word ptr es:[si + 0F8h]
mov   word ptr ds:[bx + _psprites + 2], ax
mov   ax, word ptr es:[si + 0FCh]
mov   word ptr ds:[bx + _psprites + 4], ax
mov   ax, word ptr es:[si + 0FEh]
mov   word ptr ds:[bx + _psprites + 6], ax
mov   ax, word ptr es:[si + 0100h]
mov   word ptr ds:[bx + _psprites + 8], ax
mov   ax, word ptr es:[si + 0102h]
mov   word ptr ds:[bx + _psprites + 0Ah], ax
add   si, SIZEOF_PSPDEF_VANILLA_T
add   bx, SIZEOF_PSPDEF_T
cmp   bx, SIZEOF_PSPDEF_T * NUMPSPRITES
jne   load_next_sprite
mov   word ptr ds:[di + 056h], 0FFFFh
xor   ax, ax
add   word ptr ds:[_save_p], SIZEOF_PLAYER_VANILLA_T 

mov   word ptr ds:[di + 05Ch], ax

mov   word ptr ds:[_playerMobjRef], ax

pop   di
pop   si
pop   cx
pop   bx
retf  
set_psprite_statenum_null:
mov   word ptr ds:[bx + _psprites], 0FFFFh
jmp   done_with_psprite



ENDP






PROC P_UnArchiveWorld_  FAR
PUBLIC P_UnArchiveWorld_


push  bx
push  cx
push  dx
push  si
push  di

;PROC Z_QuickMapRender_4000To8000_8000Only_ NEAR
Z_QUICKMAPAI4 pageswapargs_rend_other8000_size INDEXED_PAGE_8000_OFFSET


mov   cx, SECTORS_SEGMENT
mov   es, cx


mov   cx, word ptr ds:[_numsectors]

mov   bx, _sectors_physics      ; in near segment. use SS
lds   si, dword ptr ds:[_save_p]
xor   di, di


load_next_sector:

lodsw           
SHIFT_MACRO shl ax 3
stosw           ; 00 -> 00

lodsw           
SHIFT_MACRO shl ax 3
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
SHIFT_MACRO SAR BX 3
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
SHIFT_MACRO SAR BX 2

; LINES offset

mov   ax, LINES_SEGMENT
mov   es, ax

add   bx, cx                ; add side offset.
mov   bx, word ptr es:[bx] 

cmp   bx, 0FFFFh
je    skip_side

mov   ax, SIDES_RENDER_8000_SEGMENT
mov   es, ax
SHIFT_MACRO shl bx 2

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

mov   word ptr ds:[_save_p], si

pop   di
pop   si
pop   dx
pop   cx
pop   bx
retf  



ENDP

str_bad_tclass_1:
db "Unknown tclass %i in savegame", 0
str_bad_tclass_2:
db "P_UnarchiveSpecials:Unknown tclass %i in savegame", 0


SIZEOF_MOBJ_VANILLA_T = 09Ah
SIZEOF_THINKER_VANILLA_T = 12

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
mov       si, word ptr ds:[_thinkerlist + THINKER_T.t_next]       ; currentthinker = thinkerlist[0].next...



loop_zeroing_thinkers:
mov       ax, SIZEOF_THINKER_T
mul       si

mov       di, ax                               ; thinker_t offset
mov       ax, word ptr ds:[di + _thinkerlist + THINKER_T.t_prevFunctype]     ; prevfunctype

mov       si, word ptr ds:[_thinkerlist + di + 2] ; get thinker next
add       di, (_thinkerlist + THINKER_T.t_data)        ; di = thinkerlist.data
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
;sub       si, word ptr ds:[_save_p]

end_specials:           ; todo i guess this can piggyback on another exit.
mov       word ptr ds:[_save_p], si

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

mov ax, OFFSET str_bad_tclass_1 - OFFSET P_LOADSTART_
push      cs
push      ax
;call      I_Error_
db 0FFh  ; lcall[addr]
db 01Eh  ;
dw _I_Error_addr


;add       sp, 4
;jmp       load_next_thinker

call_removemobj:
mov       ax, di
;call      P_RemoveMobj_
db    09Ah
dw    P_REMOVEMOBJOFFSET, PHYSICS_HIGHCODE_SEGMENT


check_next_thinker_to_zero:
test      si, si
jne       loop_zeroing_thinkers

;call      P_InitThinkers_
db 0FFh  ; lcall[addr]
db 01Eh  ;
dw _P_InitThinkers_addr

; zero blocklinks.
mov       cx, MAX_BLOCKLINKS_SIZE / 2
mov       ax, BLOCKLINKS_SEGMENT
mov       es, ax
xor       ax, ax
xor       di, di
rep stosw 

mov       si, word ptr ds:[_save_p]

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
;call   P_CreateThinker_
db 0FFh  ; lcall[addr]
db 01Eh  ;
dw _P_CreateThinker_addr
pop       ds                              ; ds is save seg again

mov       bx, ax                          ; mobj pointer to bx
mov       word ptr [bp - 6], ax           ; store mobj pointer              ; alternatively, push/pop
sub       ax, ((_thinkerlist + THINKER_T.t_data))        ; get thinkerlist offset
xor       dx, dx
mov       cx, SIZEOF_THINKER_T
div       cx
mov       cx, ax                          ; cx = thinkerref

mov       dx, SIZEOF_MOBJ_POS_T
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

lea       di, ds:[di + 0Ah]

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

mov       dx, cx                           ; mobjposlist offset

mov       bx, 0FFFFh                       ; -1 knownsecnum

push      ss
pop       ds                            ; restore ds

;call      P_SetThingPosition_
db    09Ah
dw    P_SETTHINGPOSITIONFAROFFSET, PHYSICS_HIGHCODE_SEGMENT

; di is mobj
mov       bx, word ptr ds:[di + 4]            ; get mobj secnum
mov       ax, SECTORS_SEGMENT
mov       es, ax
SHIFT_MACRO shl bx 4
mov       ax, word ptr es:[bx]
mov       word ptr ds:[di + 6], ax              ; floorz
mov       ax, word ptr es:[bx + 2]
mov       word ptr ds:[di + 8], ax              ; ceilingz


add       si, (SIZEOF_MOBJ_VANILLA_T - 096h) ; add 4 (for tracer)
jmp       load_next_thinker





ENDP

SIZEOF_CEILING_VANILLA_T = 030h
SIZEOF_FLOORMOVE_VANILLA_T = 02Ah
SIZEOF_VLDOOR_VANILLA_T = 028h
SIZEOF_PLAT_VANILLA_T = 038h
SIZEOF_STROBE_VANILLA_T = 024h
SIZEOF_LIGHTFLASH_VANILLA_T = 024h
SIZEOF_GLOW_VANILLA_T = 01Ch

jump_table_unarchive_specials:
dw  OFFSET  load_ceiling_special - OFFSET P_LOADSTART_    ; 0
dw  OFFSET  load_door_special - OFFSET P_LOADSTART_       ; 1
dw  OFFSET  load_movefloor_special - OFFSET P_LOADSTART_  ; 2
dw  OFFSET  load_platraise_special - OFFSET P_LOADSTART_  ; 3
dw  OFFSET  load_flash_special - OFFSET P_LOADSTART_      ; 4
dw  OFFSET  load_strobe_special - OFFSET P_LOADSTART_     ; 5
dw  OFFSET  load_glow_special - OFFSET P_LOADSTART_       ; 6
dw  OFFSET  end_specials - OFFSET P_LOADSTART_            ; 7

PROC P_UnArchiveSpecials_  FAR
PUBLIC P_UnArchiveSpecials_


push   bx
push   cx
push   dx
push   si
push   di

lds    si, dword ptr ds:[_save_p]
load_next_special:

xor    ax, ax
lodsb
mov    dx, ds   ; store segreg
push   ss
pop    ds
cmp    al, 7
ja     bad_special_thinkerclass
mov    bx, ax
sal    bx, 1

mov    ax, si
mov    cx, 4
and    ax, 3
sub    cx, ax
and    cx, 3

mov    di, SIZEOF_THINKER_T


jmp    word ptr cs:[bx + OFFSET jump_table_unarchive_specials - OFFSET P_LOADSTART_]

; default case
bad_special_thinkerclass:
xor    ah, ah

mov    ax, OFFSET str_bad_tclass_2 - OFFSET P_LOADSTART_
push   cs
push   ax
;call      I_Error_
db 0FFh  ; lcall[addr]
db 01Eh  ;
dw _I_Error_addr

; thinker_type...

load_ceiling_special:
; PADSAVEP()
add    si, cx
mov    cx, dx
mov    ax, TF_MOVECEILING_HIGHBITS
;call   P_CreateThinker_
db 0FFh  ; lcall[addr]
db 01Eh  ;
dw _P_CreateThinker_addr

push   ds
pop    es
mov    ds, cx

mov    bx, ax
sub    ax, (_thinkerlist + THINKER_T.t_data)
xor    dx, dx
div    di           ; store thinkerref
mov    di, bx
mov    bx, ax

add    si, 12
call   LoadInt8_
call   LoadInt16_
call   LoadShortHeight16_
call   LoadShortHeight16_
call   LoadInt8_
call   LoadInt8_
call   LoadTagToVanilla
call   LoadInt8_




mov    ax, word ptr ds:[di - 0Ch]        ; di is 0Dh, we want 1

SHIFT_MACRO SHL AX 4


xchg   ax, bx

mov    cx, ds
push   ss
pop    ds
mov    word ptr ds:[bx + (_sectors_physics + 8)], ax  ; sectors_physics specialdataRef
;call   P_AddActiveCeiling_
db 0FFh  ; lcall[addr]
db 01Eh  ;
dw _P_AddActiveCeiling_addr

mov    ds, cx
jmp    load_next_special

load_door_special:
; PADSAVEP()
add    si, cx
mov    cx, dx
mov    ax, TF_VERTICALDOOR_HIGHBITS
;call   P_CreateThinker_
db 0FFh  ; lcall[addr]
db 01Eh  ;
dw _P_CreateThinker_addr
push   ds
pop    es
mov    ds, cx

mov    bx, ax
sub    ax, (_thinkerlist + THINKER_T.t_data)
xor    dx, dx
div    di
mov    di, bx
mov    bx, ax

add    si, 12
call   LoadInt8_
call   LoadInt16_
call   LoadShortHeight16_
call   LoadShortHeight16_
call   LoadInt16_
call   LoadInt16_
call   LoadInt16_



mov    ax, word ptr ds:[di - 0Ch]  ; di is 0Dh, we want 1
IF COMPISA GE COMPILE_186
    shl    ax, 4
ELSE
    shl    ax, 1
    shl    ax, 1
    shl    ax, 1
    shl    ax, 1
ENDIF
mov    di, ax
mov    word ptr ss:[di + (_sectors_physics + 8)], bx  ; sectors_physics specialdataRef
jmp    load_next_special

load_movefloor_special:

; PADSAVEP()
add    si, cx
mov    cx, dx
mov    ax, TF_MOVEFLOOR_HIGHBITS
;call   P_CreateThinker_
db 0FFh  ; lcall[addr]
db 01Eh  ;
dw _P_CreateThinker_addr
push   ds
pop    es
mov    ds, cx

mov    bx, ax
sub    ax, (_thinkerlist + THINKER_T.t_data)
xor    dx, dx
div    di
mov    di, bx
mov    bx, ax

add    si, 12
call   LoadInt8_
call   LoadInt8_
call   LoadInt16_
call   LoadInt8_
call   LoadInt8_
call   LoadInt8_
call   LoadShortHeight16_
call   LoadShortHeight16_




mov    ax, word ptr ds:[di - 9]    ; di is + 0Bh, we want 2..

SHIFT_MACRO SHL AX 4


mov    di, ax
mov    word ptr ss:[di + (_sectors_physics + 8)], bx  ; sectors_physics specialdataRef
jmp    load_next_special

load_platraise_special:
; PADSAVEP()
add    si, cx
mov    cx, dx
mov    ax, TF_PLATRAISE_HIGHBITS
;call   P_CreateThinker_
db 0FFh  ; lcall[addr]
db 01Eh  ;
dw _P_CreateThinker_addr
push   ds
pop    es
mov    ds, cx

mov    bx, ax
sub    ax, (_thinkerlist + THINKER_T.t_data)
xor    dx, dx
div    di
mov    di, bx
mov    bx, ax

add    si, 12
call   LoadInt16_
call   LoadShortHeight16_
call   LoadShortHeight16_
call   LoadShortHeight16_
call   LoadInt8_
call   LoadInt8_
call   LoadInt8_
call   LoadInt8_
call   LoadInt8_
call   LoadTagToVanilla
call   LoadInt8_




mov    ax, word ptr es:[di-0Fh]  ; di is 0F, we want 0

IF COMPISA GE COMPILE_186
    shl    ax, 4
ELSE
    shl    ax, 1
    shl    ax, 1
    shl    ax, 1
    shl    ax, 1
ENDIF
; todo xchg
xchg   ax, bx
mov    word ptr ds:[bx + (_sectors_physics + 8)], ax  ; sectors_physics specialdataRef
mov    cx, ds
push   ss
pop    ds
;call   P_AddActivePlat_
db 0FFh  ; lcall[addr]
db 01Eh  ;
dw _P_AddActivePlat_addr

mov    ds, cx
jmp    load_next_special

load_flash_special:
; PADSAVEP()
add    si, cx
mov    cx, dx
mov    ax, TF_LIGHTFLASH_HIGHBITS
;call   P_CreateThinker_
db 0FFh  ; lcall[addr]
db 01Eh  ;
dw _P_CreateThinker_addr
push   ds
pop    es
mov    ds, cx

mov    di, ax

add    si, 12
call   LoadInt16_
call   LoadInt16_
call   LoadInt8_
call   LoadInt8_
call   LoadInt8_
call   LoadInt8_

jmp    load_next_special

load_strobe_special:
; PADSAVEP()
add    si, cx
mov    cx, dx
mov    ax, TF_STROBEFLASH_HIGHBITS
;call   P_CreateThinker_
db 0FFh  ; lcall[addr]
db 01Eh  ;
dw _P_CreateThinker_addr
push   ds
pop    es
mov    ds, cx

mov    di, ax

add    si, 12
call   LoadInt16_
call   LoadInt16_
call   LoadInt8_
call   LoadInt8_
call   LoadInt16_
call   LoadInt16_

jmp    load_next_special

load_glow_special:
; PADSAVEP()
add    si, cx
mov    cx, dx
mov    ax, TF_GLOW_HIGHBITS
;call   P_CreateThinker_
db 0FFh  ; lcall[addr]
db 01Eh  ;
dw _P_CreateThinker_addr
push   ds
pop    es
mov    ds, cx

mov    di, ax

add    si, 12
call   LoadInt16_
call   LoadInt8_
call   LoadInt8_
call   LoadInt16_

jmp    load_next_special



ENDP


PROC LoadTagToVanilla NEAR
lodsw
inc   si
inc   si

cmp   ax, 1323
jne   not_1323
mov   al, 56
stosb
ret

not_1323:
cmp   ax, 1044
jne   not_1044
mov   al, 57
stosb
ret


not_1044:
cmp   ax, 86
jne   not_86
mov   al, 58
stosb
ret


not_86:
cmp   ax, 77
jne   not_77
mov   al, 59
stosb
ret


not_77:
cmp   ax, 99
jne   not_99
mov   al, 60
stosb
ret


not_99:
cmp   ax, 666
jne   not_666
mov   al, 61
stosb
ret


not_666:
cmp   ax, 667
jne   not_667
mov   al, 62
stosb
ret

not_667:
cmp   ax, 999
jne   not_999
mov   al, 63
; fall thru

not_999:

stosb
ret 





ENDP


PROC LoadInt8_ NEAR

lodsw
stosb
inc    si
inc    si
ret

ENDP

PROC LoadInt16_ NEAR

lodsw
stosw
inc    si
inc    si
ret

ENDP

PROC LoadShortHeight16_ NEAR

lodsw
xchg   ax, dx
lodsw
sal    dx, 1
rcl    ax, 1
sal    dx, 1
rcl    ax, 1
sal    dx, 1
rcl    ax, 1
stosw
ret

ENDP


PROC P_ArchivePlayers_ FAR
PUBLIC P_ArchivePlayers_


push      cx
push      dx
push      si
push      di

;PROC Z_QuickMapRender_4000To8000_8000Only_ NEAR
Z_QUICKMAPAI4 pageswapargs_rend_other8000_size INDEXED_PAGE_8000_OFFSET


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
lea       di, ds:[di + 8]                  
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
SHIFT_MACRO SAR AX 3
stosw           ; floorheight

lodsw                   ; todo shr?? can this be negative
SHIFT_MACRO SAR AX 3
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
SHIFT_MACRO SAR BX 3
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
SHIFT_MACRO shl bx 2

lds   ax, dword ptr ds:[bx]      ; side1
mov   bx, ds    ; side2
mov   cx, 2                     ; num sides
push  si

check_next_side:
cmp   ax, -1
je    done_checking_side

SHIFT_MACRO shl ax 2

xchg  si, ax    ; shove this in si

mov   ax, SIDES_SEGMENT
push  ax
mov   ax, SIDES_RENDER_8000_SEGMENT
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



VANILLA_FULLBRIGHT = 08000h

PROC P_ArchiveThinkers_ FAR
PUBLIC P_ArchiveThinkers_


push      bx
push      cx
push      dx
push      si
push      di

les       di, dword ptr ds:[_save_p]
mov       dx, word ptr ds:[_thinkerlist + THINKER_T.t_next]
test      dx, dx
je        exit_archivethinkers
loop_check_next_thinker:
mov       ax, SIZEOF_THINKER_T
push      dx    ; backup  th
mul       dx
pop       dx    ; restore th
xchg      ax, bx

mov       ax, word ptr ss:[bx + OFFSET _thinkerlist + THINKER_T.t_prevFunctype]
and       ax, TF_FUNCBITS
cmp       ax, TF_MOBJTHINKER_HIGHBITS
je        do_save_next_thinker
mov       dx, bx
iterate_to_next_thinker:
mov       ax, SIZEOF_THINKER_T
mul       dx
xchg      ax, bx
mov       dx, word ptr ss:[bx + OFFSET _thinkerlist + THINKER_T.t_next] ; next th
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
mov       ax, SIZEOF_MOBJ_POS_T
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


lea       di, ds:[di + 0Ch - SIZEOF_MOBJ_VANILLA_T] ; skip thinker fields and undo rep stosw

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

lea       di, ds:[di + 044h]
movsw ; si + 016h di + 6Ah          flags1
movsw ; si + 018h di + 6Ch          flags2

lea       di, ds:[di - 048h]   ; di + 024h


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

lea       si, ds:[bx + _thinkerlist + THINKER_T.t_data + MOBJ_T.m_height ]       ; point to mobj + 0Ah now

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
mov   bx, word ptr cs:[tag_conversions_to_vanilla + bx - OFFSET P_LOADSTART_]
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

dw  OFFSET  iterate_to_next_special  - OFFSET P_LOADSTART_ ; 1 mobj, skip
dw  OFFSET  save_platraise_special   - OFFSET P_LOADSTART_ ; 2
dw  OFFSET  save_ceiling_special     - OFFSET P_LOADSTART_ ; 3
dw  OFFSET  save_door_special        - OFFSET P_LOADSTART_ ; 4
dw  OFFSET  save_movefloor_special   - OFFSET P_LOADSTART_ ; 5
dw  OFFSET  iterate_to_next_special  - OFFSET P_LOADSTART_ ; 6 flicker?? not saved apparently, skip
dw  OFFSET  save_flash_special       - OFFSET P_LOADSTART_ ; 7
dw  OFFSET  save_strobe_special      - OFFSET P_LOADSTART_ ; 8
dw  OFFSET  save_glow_special        - OFFSET P_LOADSTART_ ; 9

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
mov       cx, word ptr ds:[_thinkerlist + THINKER_T.t_next]
test      cx, cx
je        exit_archive_specials
save_next_special:
mov       ax, SIZEOF_THINKER_T
mul       cx
xchg      ax, si

mov       ax, word ptr ds:[si + OFFSET _thinkerlist + THINKER_T.t_prevFunctype]
and       ax, TF_FUNCBITS



je        is_null_funcbits  ; no thinker. go check to see if its an inactive ceiling though

cmp       ax, TF_FIREFLICKER_HIGHBITS       ; not serialized apparently
je        iterate_to_next_special
cmp       ax, TF_MOBJTHINKER_HIGHBITS       ; not serialized here
je        iterate_to_next_special



SHIFT_MACRO rol ax 5


; put func bits (most sig 5) into least sig bits

cmp       ax, 10  ; funcbits too large or delete_me case
jge       iterate_to_next_special
; we do some checks above to guarantee we know this is a valid thinker to serialize so now we can run common code here.



; prep jump addr

dec       ax     ; offset 0 case. could just minus two in the lookup...

force_ceiling:          ; active ceilings jump here from null thinker case.
add       si, OFFSET _thinkerlist + THINKER_T.t_data   ; data pointer

xchg      ax, bx
mov       al, byte ptr cs:[bx + OFFSET _tc_enum_lookup - OFFSET P_LOADSTART_]
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
mov       dx, word ptr cs:[bx + OFFSET erase_size_table  - OFFSET P_LOADSTART_]
mov       cx, dx
xor       ax, ax
rep       stosw 
pop       cx

sal       dx, 1
sub       di, dx ; reset di 

add       di, 12 ; skip 12 byte thinker field



jmp       word ptr cs:[bx + OFFSET jump_table_archive_specials  - OFFSET P_LOADSTART_]

iterate_to_next_special:

mov       ax, SIZEOF_THINKER_T
mul       cx
xchg      ax, bx

mov       cx, word ptr ds:[bx + OFFSET _thinkerlist + THINKER_T.t_next]    ; thinker next
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


PROC P_LOADEND_
PUBLIC P_LOADEND_
ENDP


END
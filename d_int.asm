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

EXTRN int86x_:PROC
EXTRN int86_:PROC

.CODE
 


PROC D_INTERRUPT_STARTMARKER_
PUBLIC D_INTERRUPT_STARTMARKER_
ENDP

;; todo do this locally...
COMMENT @
PROC Z_MapPageFrame_

;   bx is value

push dx
mov  ax, 04400h ; always page 0
mov  dx, _emshandle
mov  
pop  dx
ret

@



_mus_service_routine_jmp_table:
dw OFFSET release_note_routine
dw OFFSET play_note_routine
dw pitch_bend_routine
dw system_event_routine
dw controller_event_routine
dw end_of_measure_routine
dw finish_song_routine
dw unused_routine



PROC MUS_ServiceRoutine_
PUBLIC MUS_ServiceRoutine_


push  bx
push  cx
push  dx
push  si
push  di

cmp   byte ptr ds:[_playingstate], ST_PLAYING
jne   exit_MUS_serviceroutine
; + 0 is always zero. dx is the only one that is not null if set..
cmp   word ptr ds:[_playingdriver + 2], 0
je    exit_MUS_serviceroutine

; playing driver not null

; some pre-loop setup. si and di will contain these two fields.
mov   si, word ptr ds:[_currentsong_playing_offset]
mov   di, word ptr ds:[_currentsong_ticks_to_process]
inc   di

cmp   di, 0
jl    inc_playing_time_and_exit

service_routine_loop:


mov   es, word ptr ds:[_EMS_PAGE]
lods  word ptr es:[si]
;     ax gets first two bytes...

; ah remains untouched with the 2nd byte.

mov   bx, ax
mov   ch, 0     ; doing_loop
and   bx, 070h ; bits 4, 5, 6 of al
SHIFT_MACRO SAR BX 3
; bx stores event ptr

mov   dl, al
and   dl, 0Fh   ; dl stores channel

and   al, 080h  ; al has last
mov   cl, al    ; store last


jmp   word ptr cs:[bx + _mus_service_routine_jmp_table]
inc_playing_time_and_exit:
; finally write si/di back.
mov   word ptr ds:[_currentsong_playing_offset], si
mov   word ptr ds:[_currentsong_ticks_to_process], di

add   word ptr ds:[_playingtime], 1
adc   word ptr ds:[_playingtime + 2], 0
exit_MUS_serviceroutine:
pop   di
pop   si
pop   dx
pop   cx
pop   bx
retf  


release_note_routine:
mov   al, ah    ; previously loaded
xchg  ax, dx
mov   es, word ptr ds:[_playingdriver + 2]
call  dword ptr es:[014h]

unused_routine:

inc_service_routine_loop:

; if si over MUS_SIZE_PER_PAGE page next page in, sub MUS_SIZE_PER_PAGE...
cmp   si, MUS_SIZE_PER_PAGE
jge   page_in_new_mus_page

done_paging_in_new_mus_page:



cmp   cl, 0 ; cl was last flag
je    skip_delay
xor   dx, dx ; dx gets loop amt
mov   es, word ptr ds:[_EMS_PAGE]
read_delay_loop:
lods  byte ptr es:[si]
mov   cl, 7
shl   dx, cl
mov   ah, al
and   ah, 07Fh
add   dl, ah
and   al, 080h
jne   read_delay_loop

sub   di, dx
skip_delay:
cmp   ch, 0     ; ch is doing_loop var
jne   loop_song
done_looping_song:
cmp   byte ptr ds:[_playingstate], 1
je    inc_playing_time_and_exit
cmp   di, 0
jl    inc_playing_time_and_exit
jmp   service_routine_loop


loop_song:

; move back to page 0
mov   byte ptr ds:[_currentMusPage], 0
xor   ax, ax
cwd     ; dx is 0
call  dword ptr ds:[_Z_QuickMapPageFrame_addr]
; set si to this initial value
mov   si, word ptr ds:[_currentsong_start_offset]

jmp   done_looping_song


page_in_new_mus_page:
inc       byte ptr ds:[_currentMusPage]
xor       ax, ax
mov       dl, byte ptr ds:[_currentMusPage]
; in theory bad things might happen if currentmuspage went beyond 4?
call      dword ptr ds:[_Z_QuickMapPageFrame_addr]
sub       si, MUS_SIZE_PER_PAGE
jmp       done_paging_in_new_mus_page
play_note_routine:
mov   bl, -1  ; lastvolume
test  ah, 080h
je    use_last_volume
lods  byte ptr es:[si]   ; get volume in al
and   al, 07Fh
mov   bl, al

use_last_volume:
; bl has volume
mov   al, dl     ; get channel in al
mov   dl, ah     ; put key/note
and   dl, 07Fh   ; note anded to 127


; channel, key, volume
;  al       dl    bl

mov   es, word ptr ds:[_playingdriver + 2]
call  dword ptr es:[010h]

jmp   inc_service_routine_loop
pitch_bend_routine:
mov   al, dl    ; set channel
mov   dl, ah    ; set pitch bend value
mov   es, word ptr ds:[_playingdriver + 2]
call  dword ptr es:[018h]
jmp   inc_service_routine_loop

system_event_routine:

mov   al, dl    ; set channel
mov   dl, ah    ; set controller
and   dl, 07Fh
xor   bx, bx    ; zero arg 2

mov   es, word ptr ds:[_playingdriver + 2]
call  dword ptr es:[01CH]

jmp  inc_service_routine_loop

controller_event_routine:

lods  byte ptr es:[si] ; load arg 2
and   al, 07Fh
mov   bl, al    ; arg 2
mov   al, dl    ; get channel
mov   dl, ah    ; arg 1
and   dl, 07Fh


mov   es, word ptr ds:[_playingdriver + 2]
call  dword ptr es:[01CH]
jmp   inc_service_routine_loop

finish_song_routine:

cmp   byte ptr ds:[_loops_enabled], 0
je    no_loop
mov   ch, 1 ; force loop flag on
jmp   inc_service_routine_loop
no_loop:
mov   byte ptr ds:[_playingstate], ST_STOPPED
jmp   inc_service_routine_loop
end_of_measure_routine:
dec   si    ; offset for that lodsw...
jmp   inc_service_routine_loop


ENDP




PROC locallib_int86_ FAR
PUBLIC locallib_int86_


; int86x

;call  int86_
;retf 



push cx
push si
push bp
mov  bp, sp
sub  sp, 8



;lea  si, [bp - 8]
;mov  cx, si

push  ds
push  ss
push  cs
push  es

mov   cx, sp

; inlined segread...  todo remove lea stuff and just push?
;mov  word ptr [si], es
;mov  word ptr [si + 2], cs
;mov  word ptr [si + 4], ss
;mov  word ptr [si + 6], ds


;call locallib_int86x_
call  int86x_

mov  sp, bp
pop  bp
pop  si
pop  cx
retf 

ENDP

PROC locallib_int86x_ FAR
PUBLIC locallib_int86x_



; called after segread. whatssegread put in bx/cx?

; int86x

push si
push di
push bp
mov  bp, sp
sub  sp, 018h
push ax
mov  si, dx                 ; dx has regs pointer
mov  word ptr [bp - 2], bx ; seems to be bx backup
mov  word ptr [bp - 4], cx  ; cx has sregs ptr (??)
mov  ax, word ptr [si]
mov  word ptr [bp - 018h], ax   ; store regs 1st reg?
mov  ax, word ptr [si + 2]
mov  word ptr [bp - 016h], ax
mov  ax, word ptr [si + 4]
mov  word ptr [bp - 014h], ax
mov  ax, word ptr [si + 6]
mov  word ptr [bp - 012h], ax
mov  ax, word ptr [si + 8]
mov  word ptr [bp - 0Eh], ax
mov  ax, word ptr [si + 0Ah]
mov  bx, cx
mov  word ptr [bp - 0Ch], ax
mov  ax, word ptr [bx + 6]
mov  word ptr [bp - 0Ah], ax
xor  dx, dx
mov  ax, word ptr [bx]
mov  cx, ds
mov  word ptr [bp - 8], ax
mov  al, byte ptr [bp - 01AH]
lea  bx, [bp - 018h]
xor  ah, ah

call locallib_do_intr_
mov  bx, word ptr [bp - 2]
mov  ax, word ptr [bp - 018h]
mov  word ptr [bx], ax
mov  ax, word ptr [bp - 016h]
mov  word ptr [bx + 2], ax
mov  ax, word ptr [bp - 014h]
mov  word ptr [bx + 4], ax
mov  ax, word ptr [bp - 012h]
mov  word ptr [bx + 6], ax
mov  ax, word ptr [bp - 0Eh]
mov  word ptr [bx + 8], ax
mov  ax, word ptr [bp - 0Ch]
mov  word ptr [bx + 0Ah], ax
test byte ptr [bp - 6], 1
je   label_1
mov  ax, 1
label_2:
mov  bx, word ptr [bp - 2]
mov  word ptr [bx + 0Ch], ax
mov  bx, word ptr [bp - 4]
mov  ax, word ptr [bp - 0Ah]
mov  word ptr [bx + 6], ax
mov  ax, word ptr [bp - 8]
mov  word ptr [bx], ax
mov  ax, word ptr [bp - 018h]
mov  sp, bp
pop  bp
pop  di
pop  si
retf 
label_1:
xor  ax, ax
jmp  label_2


ENDP


PROC locallib_do_intr_ FAR
PUBLIC locallib_do_intr_
; _dointr

push  bp
push  ds
push  cx
push  bx
mov   ds, cx           ; cx was passed in as ds. store current DS??
call  locallib_do_intr_inner_
; this runs after the interrupt is finished.
push  ds
push  bp
push  bx
mov   bp, sp
lds   bx, dword ptr [bp + 6]             ; what is this equivalent to..? DS:BP?
mov   word ptr [bx], ax
pop   word ptr [bx + 2]
mov   word ptr [bx + 4], cx
mov   word ptr [bx + 6], dx
pop   word ptr [bx + 8]
mov   word ptr [bx + 0Ah], si
mov   word ptr [bx + 0Ch], di
pop   word ptr [bx + 0Eh]
mov   word ptr [bx + 010h], es
pushf 
pop   word ptr [bx + 012h]
add   sp, 4
pop   ds
pop   bp
popf  
retf  

ENDP

PROC locallib_do_intr_inner_ NEAR
PUBLIC locallib_do_intr_inner_

; inner func. set up registers?
mov   cx, ax
shl   ax, 1
add   ax, cx
add   ax, OFFSET INTERRUPT_TABLE
push  cs
push  ax           ; called via retf below 
mov   ah, dl       ; whats dl? seems to be xor dx, dx earlier...
sahf               ; whats 9E....
mov   ax, word ptr [bx]
mov   cx, word ptr [bx + 4]
mov   dx, word ptr [bx + 6]
mov   bp, word ptr [bx + 8]
mov   si, word ptr [bx + 0Ah]
mov   di, word ptr [bx + 0Ch]
push  word ptr [bx + 0Eh]
mov   es, word ptr [bx + 010h]
mov   bx, word ptr [bx + 2]
pop   ds
retf               ; this does the int call!!!
; interrupt table.
INTERRUPT_TABLE:
int   0
ret   
int   1
ret   
int   2
ret   
db    0CCh        ; int 3
nop   
ret   
int   4
ret   
int   5
ret   
int   6
ret   
int   7
ret   
int   8
ret   
int   9
ret   
int   0Ah
ret   
int   0Bh
ret   
int   0Ch
ret   
int   0Dh
ret   
int   0Eh
ret   
int   0Fh
ret   
int   010h
ret   
int   011h
ret   
int   012h
ret   
int   013h
ret   
int   014h
ret   
int   015h
ret   
int   016h
ret   
int   017h
ret   
int   018h
ret   
int   019h
ret   
int   01AH
ret   
int   01bh
ret   
int   01CH
ret   
int   01dh
ret   
int   01eh
ret   
int   01fh
ret   
int   020h
ret   
int   021h
ret   
int   022h
ret   
int   023h
ret   
int   024h
ret   
jmp   do_int_25
jmp   do_int_26
int   027h
ret   
int   028h
ret   
int   029h
ret   
int   02ah
ret   
int   02bh
ret   
int   02ch
ret   
int   02dh
ret   
int   02eh
ret   
int   02fh
ret   
int   030h
ret   
int   031h
ret   
int   032h
ret   
int   033h
ret   
int   034h
ret   
int   035h
ret   
int   036h
ret   
int   037h
ret   
int   038h
ret   
int   039h
ret   
int   03ah
ret   
int   03bh
ret   
int   03ch
ret   
int   03dh
ret   
int   03eh
ret   
int   03fh
ret   
int   040h
ret   
int   041h
ret   
int   042h
ret   
int   043h
ret   
int   044h
ret   
int   045h
ret   
int   046h
ret   
int   047h
ret   
int   048h
ret   
int   049h
ret   
int   04ah
ret   
int   04bh
ret   
int   04ch
ret   
int   04dh
ret   
int   04eh
ret   
int   04fh
ret   
int   050h
ret   
int   051h
ret   
int   052h
ret   
int   053h
ret   
int   054h
ret   
int   055h
ret   
int   056h
ret   
int   057h
ret   
int   058h
ret   
int   059h
ret   
int   05ah
ret   
int   05bh
ret   
int   05ch
ret   
int   05dh
ret   
int   05eh
ret   
int   05fh
ret   
int   060h
ret   
int   061h
ret   
int   062h
ret   
int   063h
ret   
int   064h
ret   
int   065h
ret   
int   066h
ret   
int   067h
ret   
int   068h
ret   
int   069h
ret   
int   06ah
ret   
int   06bh
ret   
int   06ch
ret   
int   06dh
ret   
int   06eh
ret   
int   06fh
ret   
int   070h
ret   
int   071h
ret   
int   072h
ret   
int   073h
ret   
int   074h
ret   
int   075h
ret   
int   076h
ret   
int   077h
ret   
int   078h
ret   
int   079h
ret   
int   07ah
ret   
int   07bh
ret   
int   07ch
ret   
int   07dh
ret   
int   07eh
ret   
int   07fh
ret   
int   080h
ret   
int   081h
ret   
int   082h
ret   
int   083h
ret   
int   084h
ret   
int   085h
ret   
int   086h
ret   
int   087h
ret   
int   088h
ret   
int   089h
ret   
int   08ah
ret   
int   08bh
ret   
int   08ch
ret   
int   08dh
ret   
int   08eh
ret   
int   08fh
ret   
int   090h
ret   
int   091h
ret   
int   092h
ret   
int   093h
ret   
int   094h
ret   
int   095h
ret   
int   096h
ret   
int   097h
ret   
int   098h
ret   
int   099h
ret   
int   09ah
ret   
int   09bh
ret   
int   09ch
ret   
int   09dh
ret   
int   09eh
ret   
int   09fh
ret   
int   0a0h
ret   
int   0a1h
ret   
int   0a2h
ret   
int   0a3h
ret   
int   0a4h
ret   
int   0a5h
ret   
int   0a6h
ret   
int   0a7h
ret   
int   0a8h
ret   
int   0a9h
ret   
int   0aah
ret   
int   0abh
ret   
int   0ach
ret   
int   0adh
ret   
int   0aeh
ret   
int   0afh
ret   
int   0b0h
ret   
int   0b1h
ret   
int   0b2h
ret   
int   0b3h
ret   
int   0b4h
ret   
int   0b5h
ret   
int   0b6h
ret   
int   0b7h
ret   
int   0b8h
ret   
int   0b9h
ret   
int   0bah
ret   
int   0bbh
ret   
int   0bch
ret   
int   0bdh
ret   
int   0beh
ret   
int   0bfh
ret   
int   0c0h
ret   
int   0c1h
ret   
int   0c2h
ret   
int   0c3h
ret   
int   0c4h
ret   
int   0c5h
ret   
int   0c6h
ret   
int   0c7h
ret   
int   0c8h
ret   
int   0c9h
ret   
int   0cah
ret   
int   0cbh
ret   
int   0cch
ret   
int   0cdh
ret   
int   0ceh
ret   
int   0cfh
ret   
int   0d0h
ret   
int   0d1h
ret   
int   0d2h
ret   
int   0d3h
ret   
int   0d4h
ret   
int   0d5h
ret   
int   0d6h
ret   
int   0d7h
ret   
int   0d8h
ret   
int   0d9h
ret   
int   0dah
ret   
int   0dbh
ret   
int   0dch
ret   
int   0ddh
ret   
int   0deh
ret   
int   0dfh
ret   
int   0e0h
ret   
int   0e1h
ret   
int   0e2h
ret   
int   0e3h
ret   
int   0e4h
ret   
int   0e5h
ret   
int   0e6h
ret   
int   0e7h
ret   
int   0e8h
ret   
int   0e9h
ret   
int   0eah
ret   
int   0ebh
ret   
int   0ech
ret   
int   0edh
ret   
int   0eeh
ret   
int   0efh
ret   
int   0f0h
ret   
int   0f1h
ret   
int   0f2h
ret   
int   0f3h
ret   
int   0f4h
ret   
int   0f5h
ret   
int   0f6h
ret   
int   0f7h
ret   
int   0f8h
ret   
int   0f9h
ret   
int   0fah
ret   
int   0fbh
ret   
int   0fch
ret   
int   0fdh
ret   
int   0feh
ret   
int   0ffh
ret   
do_int_25:
int   025h
jae   label_3
popf  
stc   
ret   
label_3:
popf  
clc   
ret   
do_int_26:
int   026h
jae   label_4
popf  
stc   
ret   
label_4:
popf  
clc   
ret   
retf  


  
ENDP


PROC D_INTERRUPT_ENDMARKER_
PUBLIC D_INTERRUPT_ENDMARKER_
ENDP


END

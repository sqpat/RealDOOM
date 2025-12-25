;
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
INCLUDE sound.inc
INSTRUCTION_SET_MACRO

;=================================
.DATA


HT18_PAGE_D000 = 01Ch
SCAT_PAGE_D000 = 018h

.CODE

; todo make struct mapping?

DRIVERBLOCK_PLAYMUSIC_OFFSET  = 020h
DRIVERBLOCK_STOPMUSIC_OFFSET  = 024h
DRIVERBLOCK_DRIVERID_OFFSET   = 034h
DRIVERBLOCK_DRIVERDATA_OFFSET = 036h

PROC  SM_LOAD_STARTMARKER_
PUBLIC  SM_LOAD_STARTMARKER_

ENDP

_str_genmidi:
db "genmidi", 0

_songnamelist:
db 0, 0, 0, 0, 0, 0, 0, 0, 0

db "d_e1m1", 0, 0, 0
db "d_e1m2", 0, 0, 0
db "d_e1m3", 0, 0, 0
db "d_e1m4", 0, 0, 0
db "d_e1m5", 0, 0, 0
db "d_e1m6", 0, 0, 0
db "d_e1m7", 0, 0, 0
db "d_e1m8", 0, 0, 0
db "d_e1m9", 0, 0, 0
db "d_e2m1", 0, 0, 0
db "d_e2m2", 0, 0, 0
db "d_e2m3", 0, 0, 0
db "d_e2m4", 0, 0, 0
db "d_e2m5", 0, 0, 0
db "d_e2m6", 0, 0, 0
db "d_e2m7", 0, 0, 0
db "d_e2m8", 0, 0, 0
db "d_e2m9", 0, 0, 0
db "d_e3m1", 0, 0, 0
db "d_e3m2", 0, 0, 0
db "d_e3m3", 0, 0, 0
db "d_e3m4", 0, 0, 0
db "d_e3m5", 0, 0, 0
db "d_e3m6", 0, 0, 0
db "d_e3m7", 0, 0, 0
db "d_e3m8", 0, 0, 0
db "d_e3m9", 0, 0, 0
db "d_inter", 0, 0
db "d_intro", 0, 0
db "d_bunny", 0, 0
db "d_victor", 0
db "d_introa", 0
db "d_runnin", 0
db "d_stalks", 0
db "d_countd", 0
db "d_betwee", 0
db "d_doom", 0, 0, 0
db "d_the_da", 0
db "d_shawn", 0, 0
db "d_ddtblu", 0
db "d_in_cit", 0
db "d_dead", 0, 0, 0
db "d_stlks2", 0
db "d_theda2", 0
db "d_doom2", 0, 0
db "d_ddtbl2", 0
db "d_runni2", 0
db "d_dead2", 0, 0
db "d_stlks3", 0
db "d_romero", 0
db "d_shawn2", 0
db "d_messag", 0
db "d_count2", 0
db "d_ddtbl3", 0
db "d_ampie", 0, 0
db "d_theda3", 0
db "d_adrian", 0
db "d_messg2", 0
db "d_romer2", 0
db "d_tense", 0, 0
db "d_shawn3", 0
db "d_openin", 0
db "d_evil", 0, 0, 0
db "d_ultima", 0
db "d_read_m", 0
db "d_dm2ttl", 0
db "d_dm2int", 0 



PROC F_CopyString9_ NEAR

push  si
push  di
push  cx
push  ax
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
stosb
mov  cx, 9
sub  di, cx

do_next_char:
lodsb
stosb
test  al, al
je    done_writing
loop do_next_char


done_writing:

push  ss
pop   ds    ; restore ds

pop   ax
pop   cx
pop   di
pop   si

ret

ENDP



do_change_music_call_1:
call      Z_QuickMapMusicPageFrame_SMLoad_
jmp       done_with_changemusic_call_1
do_change_music_call_2:
call      Z_QuickMapMusicPageFrame_SMLoad_
jmp       done_with_changemusic_call_2

; only use? inlined?

PROC  I_LoadSong_ NEAR
PUSHA_NO_AX_OR_BP_MACRO
push      bp
mov       bp, sp
push      ax        ; bp - 2 becomes lump
mov       di, word ptr ds:[_EMS_PAGE] ; music goes in ems page frame 1..
xor       si, si


mov       byte ptr ds:[_currentMusPage], 0 ; reset 'current mus page'

; set page 0
xor       ax, ax
cmp       al, byte ptr ds:[_currentpageframes + MUS_PAGE_FRAME_INDEX]
jne       do_change_music_call_1

done_with_changemusic_call_1:
; cx:bx load location
; push:push for offset
xor       bx, bx
mov       cx, di
push      bx
push      bx    ; 0 for first int32_t offset.
mov       ax, word ptr [bp - 2]
call      dword ptr ds:[_W_CacheLumpNumDirectFragment_addr]

mov       es, di


mov       word ptr ds:[_currentsong_ticks_to_process], si
mov       ax, word ptr es:[si+4]  ; length

; now we must page in pages into the page frame one by one.
; then we must load the mus data in one page at a time... then set to page 0 again

; ax has length
xor       si, si
loop_sub_len:
inc       si
sub       ax, MUS_SIZE_PER_PAGE ; some 'slack' or overlap per page.
jnc       loop_sub_len

cmp       si, 1
je        skip_loading_extra_pages

; si equals numbers of pages the mus file takes up
dec       si        ; offset for first load. was already loaded above
mov       di, 1
; di will be loop counter.
; but si will decrement...



load_next_mus_page:

; set page di
mov       ax, di

cmp       al, byte ptr ds:[_currentpageframes + MUS_PAGE_FRAME_INDEX]
jne       do_change_music_call_2

done_with_changemusic_call_2:



; 16256 is 07Fh shifted 7... this could with 8 bit mul and shfits faster but who cares.
mov       ax, MUS_SIZE_PER_PAGE
mul       di

; SET PARAMS FOR _W_CacheLumpNumDirectFragment_addr
; CX:BX:  Dest
mov       cx, word ptr ds:[_EMS_PAGE]
xor       bx, bx
; PUSH:PUSH: offset
push      bx    ; 0 for high offset word.
push      ax    ; low offset word.
; AX : LUMP
mov       ax, word ptr [bp - 2]
call      dword ptr ds:[_W_CacheLumpNumDirectFragment_addr]

inc       di
dec       si
jnz       load_next_mus_page


; set page 0 again
cmp       byte ptr ds:[_currentpageframes + MUS_PAGE_FRAME_INDEX], 0
jne       do_change_music_call_3

done_with_changemusic_call_3:



skip_loading_extra_pages:

xor       si, si
mov       es, word ptr ds:[_EMS_PAGE] ; music goes in ems page frame 1..


mov       ax, word ptr es:[si + 6]
mov       word ptr ds:[_currentsong_start_offset], ax
mov       word ptr ds:[_currentsong_playing_offset], ax

mov       ax, word ptr ds:[_playingdriver + 2]
mov       bx, word ptr es:[si + 0Ch] ; num instruments
mov       si, word ptr ds:[_playingdriver]
; bx holds onto num instruments
test      ax, ax
jne       valid_driver_do_load
test      si, si
je        jump_to_return_success  ; no driver
valid_driver_do_load:
mov       es, ax
mov       al, byte ptr es:[si + DRIVERBLOCK_DRIVERID_OFFSET] ; driver id offset
cmp       al, MUS_DRIVER_TYPE_OPL2    ; only load instruments from genmidi for opl
je        load_opl_instruments
cmp       al, MUS_DRIVER_TYPE_OPL3
jne       jump_to_return_success
load_opl_instruments:
mov       ax, word ptr ds:[_playingdriver] ; should be 0
xor       dl, dl
mov       es, word ptr ds:[_playingdriver+2] ; todo les


mov       cx, MAX_INSTRUMENTS
mov       al, 0FFh
mov       di, DRIVERBLOCK_DRIVERDATA_OFFSET + (MAX_INSTRUMENTS_PER_TRACK * SIZEOF_OP2INSTRENTRY)

rep       stosb 
loop_next_instrument_lookup:
mov       al, dl
cbw      
cmp       ax, bx
jae       done_loading_instrument_lookups
mov       al, dl
cbw      

add       ax, ax
mov       es, word ptr ds:[_EMS_PAGE]
mov       si, ax
mov       ax, word ptr es:[si + 010h]
cmp       ax, 127
ja        set_percussion_instrument_id
record_instrument_lookup:
cmp       ax, 174
ja        skip_instrument_invalid_genmidi_instrument
mov       si, MUSIC_DRIVER_CODE_SEGMENT
mov       es, si
mov       si, DRIVERBLOCK_DRIVERDATA_OFFSET + (MAX_INSTRUMENTS_PER_TRACK * SIZEOF_OP2INSTRENTRY)
add       si, ax
mov       byte ptr es:[si], dl
skip_instrument_invalid_genmidi_instrument:
inc       dl
jmp       loop_next_instrument_lookup
do_change_music_call_3:
xor       ax, ax ; set music to 0
call      Z_QuickMapMusicPageFrame_SMLoad_
jmp       done_with_changemusic_call_3

jump_to_return_success:
jmp       return_success
set_percussion_instrument_id:
sub       ax, 7
jmp       record_instrument_lookup
done_loading_instrument_lookups:
xor       bx, bx
mov       cx, word ptr ds:[_EMS_PAGE]

mov       ax, OFFSET _str_genmidi - OFFSET SM_LOAD_STARTMARKER_
call      F_CopyString9_
mov       ax, OFFSET _filename_argument

call      dword ptr ds:[_W_CacheLumpNameDirect_addr]
cmp       dh, MAX_INSTRUMENTS
jae       done_with_loading_instruments

mov       ax, MUSIC_DRIVER_CODE_SEGMENT
mov       es, ax
mov       bx, DRIVERBLOCK_DRIVERDATA_OFFSET + (MAX_INSTRUMENTS_PER_TRACK * SIZEOF_OP2INSTRENTRY)
mov       ds, word ptr ds:[_EMS_PAGE]
xor       dh, dh

loop_load_next_instrument:
mov       al, dh

xor       ah, ah
mov       si, bx    ; get instrument lookup base
add       si, ax
mov       dl, byte ptr es:[si]
cmp       dl, 0FFh
je        inc_loop_load_next_instrument

mov       ah, SIZEOF_OP2INSTRENTRY    
mul       ah
; ax has offset of this instrument (source)
add       ax, 8
xchg      ax, si

mov       al, SIZEOF_OP2INSTRENTRY    
mul       dl
add       ax, DRIVERBLOCK_DRIVERDATA_OFFSET
xchg      ax, di

mov       cx, SIZEOF_OP2INSTRENTRY / 2

rep       movsw 
inc_loop_load_next_instrument:
inc       dh
cmp       dh, MAX_INSTRUMENTS
jb        loop_load_next_instrument

done_with_loading_instruments:
push      ss
pop       ds

; load first 16384 again

; SET PARAMS 
mov       cx, word ptr ds:[_EMS_PAGE]
xor       bx, bx

push      bx
push      bx    ; 0 for int32_t offset.

mov       ax, word ptr [bp - 2]
call      dword ptr ds:[_W_CacheLumpNumDirectFragment_addr]


return_success:
return_failure:

; we dont actually use the return value... if we did, use stc/clc
LEAVE_MACRO     
POPA_NO_AX_OR_BP_MACRO
ret

COMMENT @
;stc
ret      
LEAVE_MACRO     
POPA_NO_AX_OR_BP_MACRO
;clc
ret    
@

ENDP


PROC  S_ActuallyChangeMusic_ FAR
PUBLIC  S_ActuallyChangeMusic_

xor   ax, ax
cmp   word ptr ds:[_playingdriver+2], ax
xchg  al, byte ptr ds:[_pendingmusicenum]
jne   do_changemusic
retf
do_changemusic:


push  bx
push  cx
push  dx
push  di
mov   di, ax    ;pendingmusicenum
cmp   byte ptr ds:[_snd_MusicDevice], 2
je    check_for_that_one_song_adlib_version

jmp   not_adlib
check_for_that_one_song_adlib_version:
cmp   al, MUS_INTRO
jne   not_adlib
mov   di, MUS_INTROA
continue_loading_song:
mov   ax, di
mov   ah, byte ptr ds:[_mus_playing]
cmp   al, ah
jne   dont_exit_changesong
jmp   exit_changesong
dont_exit_changesong:
test  al, al
je    dont_stop_song
mov   byte ptr ds:[_playingstate], 1
les   bx, dword ptr ds:[_playingdriver]
call  dword ptr es:[bx + DRIVERBLOCK_STOPMUSIC_OFFSET]
null_playdriver:
mov   byte ptr ds:[_mus_playing], 0
dont_stop_song:
mov   ax, di
mov   ah, 9
mul   ah
add   ax, OFFSET _songnamelist - OFFSET SM_LOAD_STARTMARKER_

call  F_CopyString9_
mov   ax, OFFSET _filename_argument
call  dword ptr ds:[_W_GetNumForName_addr]
call  I_LoadSong_
les   bx, dword ptr ds:[_playingdriver]
call  dword ptr es:[bx + DRIVERBLOCK_PLAYMUSIC_OFFSET]
dont_call_playmusic:
mov   ax, di
mov   byte ptr ds:[_loops_enabled], 1
mov   byte ptr ds:[_mus_playing], al
mov   byte ptr ds:[_playingstate], 2
not_adlib:
mov   ax, di
test  al, al
je    exit_changesong
cmp   al, NUMMUSIC
jae   exit_changesong
jmp   continue_loading_song
call_stop_music_and_exit:
les   bx, dword ptr ds:[_playingdriver]
call  dword ptr es:[bx + DRIVERBLOCK_STOPMUSIC_OFFSET]
exit_changesong:
pop   di
pop   dx
pop   cx
pop   bx
retf  

ENDP

PROC Z_QuickMapMusicPageFrame_SMLoad_ NEAR
PUBLIC Z_QuickMapMusicPageFrame_SMLoad_

IFDEF COMP_CH

        ; pageframeindex al
        ; pagenumber dl 

	IF COMP_CH EQ CHIPSET_SCAT

        push dx
        mov  ds:[_currentpageframes], al

        mov  ah, al
        mov  al, SCAT_PAGE_D000	; page D000
        mov  dx, SCAT_PAGE_SELECT_REGISTER
        cli
        out  dx, al

        mov  al, 0

        mov  dx, SCAT_PAGE_SET_REGISTER
        xchg al, ah	 ; ah becomes 0
        add  ax, (EMS_MEMORY_PAGE_OFFSET + MUS_DATA_PAGES)
        out  dx, ax
        sti

        pop dx
        ret
	ELSEIF COMP_CH EQ CHIPSET_SCAMP

        mov  ds:[_currentpageframes], al
        mov  ah, al
        mov  al, SCAMP_PAGE_FRAME_BASE_INDEX
        cli
        out  SCAMP_PAGE_SELECT_REGISTER, al
        mov  al, ah
        ; todo need xor ah/dh??
        xor  ah, ah
        ; adding EMS_MEMORY_PAGE_OFFSET is a manual _EPR process normally handled by c preprocessor...
        ; adding MUS_DATA_PAGES because this is only called for music/sound stuff, and thats the base page index for that.
        add  ax, (EMS_MEMORY_PAGE_OFFSET + MUS_DATA_PAGES)
        out  SCAMP_PAGE_SET_REGISTER, ax
        sti
        ret

	ELSEIF COMP_CH EQ CHIPSET_HT18
        push dx
        mov  ds:[_currentpageframes], al

        mov  ah, al
        mov  al, HT18_PAGE_D000
        mov  dx, HT18_PAGE_SELECT_REGISTER
        cli
        out  dx, al

        
        
        mov  dx, HT18_PAGE_SET_REGISTER
        xchg al, ah	 ; ah becomes 0
        mov  ax, MUS_DATA_PAGES
        out  dx, ax
        sti
        pop  dx
        ret


	ENDIF

ELSE

    push  bx
    push  dx
    mov   byte ptr ds:[_currentpageframes + MUS_PAGE_FRAME_INDEX], al

    xor   ah, ah
    mov   dx, word ptr ds:[_emshandle]  ; todo hardcode
    mov   bx, ax

    mov   ax, 04400h + MUS_PAGE_FRAME_INDEX
    add   bx, MUS_DATA_PAGES
    int   067h
    pop   dx
    pop   bx
    ret
ENDIF


ENDP


PROC  SM_LOAD_ENDMARKER_
PUBLIC  SM_LOAD_ENDMARKER_

ENDP


END
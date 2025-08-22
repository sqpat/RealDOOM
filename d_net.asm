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


EXTRN G_BuildTiccmd_:NEAR
EXTRN D_ProcessEvents_: NEAR
EXTRN I_StartTic_: NEAR
EXTRN M_Ticker_:NEAR
EXTRN G_Ticker_:NEAR
EXTRN D_DoAdvanceDemo_:NEAR
.DATA

EXTRN _gametime:DWORD
EXTRN _maketic:DWORD
EXTRN _oldentertics:WORD

.CODE



PROC    D_NET_STARTMARKER_ NEAR
PUBLIC  D_NET_STARTMARKER_
ENDP


; note: some of the math here assums tics wont differ by more than 16 bits signed (32768 tics) per call, which i think is more than more than enough precision in any case.

PROC    NetUpdate_ FAR
PUBLIC  NetUpdate_


push  cx
push  dx

les   ax, dword ptr ds:[_ticcount]
mov   cx, ax
sub   cx, word ptr ds:[_gametime + 0]
jle   exit_net_update
mov   word ptr ds:[_gametime + 0], ax
mov   word ptr ds:[_gametime + 2], es
; cx has loopcount..
loop_next_tic:
call  I_StartTic_
call  D_ProcessEvents_

;		if (maketic - gametic >= (BACKUPTICS / 2 - 1)) {
;			break; // can't hold any more
;		}

mov   ax, word ptr ds:[_maketic + 0]
mov   dx, ax
sub   ax, word ptr ds:[_gametic]
; fair to assume it wont overflow by 65535.
cmp   ax, (BACKUPTICS / 2) - 1  ; 7
jge   exit_net_update
xchg  ax, dx ; recover maketic
and   ax, 0000Fh
call  G_BuildTiccmd_
inc   word ptr ds:[_maketic + 0]
jz    carry_add
check_loop:
loop  loop_next_tic
exit_net_update:
pop   dx
pop   cx

retf  
carry_add:
inc   word ptr ds:[_maketic + 2]
jmp   check_loop
ENDP


PROC    TryRunTics_ NEAR
PUBLIC  TryRunTics_


push  cx
push  dx


mov   ax, word ptr ds:[_ticcount]
mov   dx, ax
mov   cx, ax ; entertic in cx
mov   word ptr ds:[_oldentertics], ax
sub   ax, word ptr ds:[_oldentertics]
xchg  ax, dx  

call  NetUpdate_

;	availabletics = maketic - gametic;


mov   ax, word ptr ds:[_maketic + 0]
sub   ax, word ptr ds:[_gametic]

xchg  ax, cx    ; cx is availabletics. ax is entertics
xchg  ax, dx    ; cx is availabletics. dx is entertics. ax is realtics

inc   ax

;   realtic  availabletics 
;      10          12          counts    11
;      10          11          counts    10
;      10          10          counts    10
;      10          9           counts    9

;	// decide how many tics to run
;	if (realtics + 1 < availabletics){
;		counts = realtics + 1;
;	} else if (realtics < availabletics){
;		counts = realtics;
;	} else {
;		counts = availabletics;
;	}


cmp   cx, ax
jge   use_realtic_plus_1
dec   ax
cmp   ax, cx
jge   use_counts

use_realtic_plus_1:
xchg  ax, cx  ; counts is realtics+1 or realtics
use_counts:

; cx is counts
; dx is entertics
test  cx, cx
jg    counts_above_0
mov   cx, 1
counts_above_0:

loop_next_maketic:

;	while (maketic < gametic + counts) {
;          maketic - gametic < counts  ; equivalent to this
mov   ax, word ptr ds:[_maketic + 0]
sub   ax, word ptr ds:[_gametic + 0] ; 16 bit precision fine if we use a diff.
cmp   cx, ax
jge   done_with_maketic_loop

call  NetUpdate_


;		if (ticcount - entertic >= 20) {
;			M_Ticker();
;			return;
;		}

mov   ax, word ptr ds:[_ticcount]
sub   ax, dx  ; entertic
cmp   al, 20
jb    loop_next_maketic
call  M_Ticker_
exit_tryruntics:

pop   dx
pop   cx
ret   


done_with_maketic_loop:

loop_counts:

cmp   byte ptr ds:[_advancedemo], 0
je    dont_do_demo
call  D_DoAdvanceDemo_
dont_do_demo:

call  M_Ticker_
call  G_Ticker_
inc   word ptr ds:[_gametic + 0]
jz    carry_add_2

do_net_update_check_loop:
call  NetUpdate_

loop  loop_counts
jmp   exit_tryruntics
carry_add_2:
inc   word ptr ds:[_gametic + 2]
jmp   do_net_update_check_loop




ENDP

PROC    D_NET_ENDMARKER_ NEAR
PUBLIC  D_NET_ENDMARKER_
ENDP


END
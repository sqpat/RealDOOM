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
INCLUDE CONSTANT.INC
INCLUDE defs.inc
INSTRUCTION_SET_MACRO


EXTRN T_FireFlicker_:NEAR
EXTRN T_PlatRaise_:NEAR
EXTRN T_Glow_:NEAR
EXTRN T_LightFlash_:NEAR
EXTRN T_StrobeFlash_:NEAR
EXTRN T_MoveCeiling_:NEAR
EXTRN T_VerticalDoor_:NEAR
EXTRN T_MoveFloor_:NEAR
EXTRN P_MobjThinker_:NEAR

EXTRN P_PlayerThink_:NEAR
EXTRN P_UpdateSpecials_:NEAR


.DATA

.CODE


PROC    P_TICK_STARTMARKER_ NEAR
PUBLIC  P_TICK_STARTMARKER_
ENDP

; THINKERREF __near P_GetNextThinkerRef(void) 

PROC P_CreateThinkerFar_ FAR
PUBLIC P_CreateThinkerFar_

call   P_CreateThinker_
retf

ENDP

PROC P_CreateThinker_ NEAR
PUBLIC P_CreateThinker_


push      bx
push      si
mov       si, ax

; INLINED, only use
;  call      P_GetNextThinkerRef_  ; returns in ax

push      dx
mov       dx, word ptr ds:[_currentThinkerListHead]
mov       ax, dx
inc       ax
cmp       ax, dx
je        error_no_thinker_found

MUL_SIZEOF_THINKER_T bx ax



add       bx, OFFSET _thinkerlist
loop_check_next_thinker:
cmp       ax, MAX_THINKERS
jne       use_current_thinker_index
xor       ax, ax
mov       bx, OFFSET _thinkerlist
use_current_thinker_index: 
cmp       word ptr ds:[bx], MAX_THINKERS
je        found_thinker
inc       ax
add       bx, SIZEOF_THINKER_T
cmp       ax, dx
jne       loop_check_next_thinker
error_no_thinker_found:
call      dword ptr ds:[_OutOfThinkers_addr]

found_thinker:
mov       word ptr ds:[_currentThinkerListHead], ax

add       si, word ptr ds:[_thinkerlist]

mov       word ptr ds:[bx], si
mov       word ptr ds:[bx+2], 0


;imul      si, word ptr ds:[_thinkerlist], SIZEOF_THINKER_T

mov   dx, word ptr ds:[_thinkerlist]

MUL_SIZEOF_THINKER_T si, dx

pop       dx


;	thinkerlist[index].next = 0;
;	thinkerlist[index].prevFunctype = temp + thinkfunc;
;	thinkerlist[temp].next = index;

mov       word ptr ds:[si + _thinkerlist + THINKER_T.t_next], ax

;	thinkerlist[0].prevFunctype = index;

mov       word ptr ds:[_thinkerlist], ax

xchg      ax, bx
add       ax, 4
pop       si
pop       bx
ret      

ENDP



PROC P_UpdateThinkerFunc_ NEAR
PUBLIC P_UpdateThinkerFunc_

push      bx

MUL_SIZEOF_THINKER_T bx ax



mov       ax, word ptr ds:[bx + _thinkerlist + THINKER_T.t_prevFunctype]
and       ax, TF_PREVBITS
add       ax, dx
mov       word ptr ds:[bx + _thinkerlist + THINKER_T.t_prevFunctype], ax
pop       bx
ret       

ENDP

PROC P_RemoveThinker_ NEAR
PUBLIC P_RemoveThinker_

;	thinkerlist[thinkerRef].prevFunctype = (thinkerlist[thinkerRef].prevFunctype & TF_PREVBITS) + TF_DELETEME_HIGHBITS;


push      bx

MUL_SIZEOF_THINKER_T bx, ax
add       bx, _thinkerlist

mov       ax, word ptr ds:[bx]
and       ah, (TF_PREVBITS SHR 8)
add       ah, (TF_DELETEME_HIGHBITS SHR 8)
mov       word ptr ds:[bx], ax
pop       bx
ret


ENDP


;TF_MOBJTHINKER_HIGHBITS = 0800h
;TF_PLATRAISE_HIGHBITS = 01000h
;TF_MOVECEILING_HIGHBITS = 01800h
;TF_VERTICALDOOR_HIGHBITS = 02000h
;TF_MOVEFLOOR_HIGHBITS = 02800h
;TF_FIREFLICKER_HIGHBITS = 03000h
;TF_LIGHTFLASH_HIGHBITS = 03800h
;TF_STROBEFLASH_HIGHBITS = 04000h
;TF_GLOW_HIGHBITS = 04800h
;TF_DELETEME_HIGHBITS = 05000h

_functable:
dw OFFSET T_PlatRaise_
dw OFFSET T_MoveCeiling_
dw OFFSET T_VerticalDoor_
dw OFFSET T_MoveFloor_
dw OFFSET T_FireFlicker_
dw OFFSET T_LightFlash_
dw OFFSET T_StrobeFlash_
dw OFFSET T_Glow_






PROC P_Ticker_ FAR
PUBLIC P_Ticker_

xor       ax, ax
cmp       al, byte ptr ds:[_paused]
jne       exit_pticker_return
cmp       al, byte ptr ds:[_menuactive]
je        do_ptick
cmp       al, byte ptr ds:[_demoplayback]
jne       do_ptick
cmp       ax, word ptr ds:[_player + 8 + 2]
jne       exit_pticker_return
inc       ax
cmp       ax, word ptr ds:[_player + 8 + 0]    ; player.viewzvalue
je        do_ptick
exit_pticker_return:
retf      
ENDP
do_ptick:

call      P_PlayerThink_ 
;call      P_RunThinkers_

; BEGIN INLINED P_RunThinkers_


PUSHA_NO_AX_MACRO ; revist once we call outer func...
mov       si, word ptr ds:[_thinkerlist + THINKER_T.t_next]
;test      si, si
;je        exit_run_thinkers  ; 0 thinkers ought to be impossible?
do_next_thinker:

;    imul  bx, si, SIZEOF_THINKER_T  ; todo test shift vs mul...
MUL_SIZEOF_THINKER_T bx, si


; consider inc bx?
mov       al, byte ptr ds:[bx + _thinkerlist + THINKER_T.t_prevFunctype +1]  ; just get high bit
lea       di, ds:[bx + _thinkerlist + THINKER_T.t_data]
and       al, (TF_FUNCBITS SHR 8)
cmp       al, (TF_MOBJTHINKER_HIGHBITS SHR 8)
jne       continue_checking_tf_types
do_mobjthinker:

;imul      bx, si, SIZEOF_MOBJ_POS_T 

mov   bx, si
SHIFT_MACRO  sal   bx 3     ; 0x08
mov   ax, bx
sal   bx, 1                  ; 0x10
add   bx, ax                 ; 0x18

mov       ax, di

mov       cx, MOBJPOSLIST_6800_SEGMENT ; todo remove maybe?
mov       dx, si
call      P_MobjThinker_




done_processing_thinker:

mov       si, word ptr ds:[di - 2]  ; (was bx + THINKER_T.t_data)
test      si, si
jne       do_next_thinker
exit_run_thinkers:
POPA_NO_AX_MACRO

; continue P_Ticker

call      P_UpdateSpecials_
add       word ptr ds:[_leveltime], 1
adc       word ptr ds:[_leveltime], 0
retf  



continue_checking_tf_types:

cmp       al, (TF_DELETEME_HIGHBITS SHR 8)
je        do_delete_me
test      al, al
je        done_processing_thinker

; all other thinkers use call table and same interface.
cbw
SHIFT_MACRO   SAR AX 2     ; highbits function are stores as 0x0800 = 1. took high byte, want word lookup. 0x08 >> 2
xchg      bx, ax
mov       ax, di
mov       dx, si

call      word ptr cs:[_functable + bx - 4];
jmp done_processing_thinker



do_delete_me:

;			// time to remove it
; THINKERREF prevRef = thinkerlist[currentthinker].prevFunctype & TF_PREVBITS;
; THINKERREF nextRef = thinkerlist[currentthinker].next;

les       ax, dword ptr ds:[bx + _thinkerlist]  ; prevref
mov       cx, es                                ; nectref

;imul      di, cx, SIZEOF_THINKER_T
MUL_SIZEOF_THINKER_T di cx

mov       byte ptr ds:[di + _thinkerlist + THINKER_T.t_prevFunctype], 0
and       ah, (TF_PREVBITS SHR 8)
; thinkerlist[nextRef].prevFunctype &= TF_FUNCBITS;
and       byte ptr ds:[di + _thinkerlist + THINKER_T.t_prevFunctype + 1], (TF_FUNCBITS SHR 8)
; thinkerlist[nextRef].prevFunctype += prevRef;
add       word ptr ds:[di + _thinkerlist + THINKER_T.t_prevFunctype], ax



MUL_SIZEOF_THINKER_T di ax



xor       ax, ax
mov       word ptr [di + _thinkerlist + THINKER_T.t_next], cx

lea       di, ds:[bx + _thinkerlist + THINKER_T.t_data]
mov       cx, ds
mov       es, cx
mov       cx, SIZEOF_MOBJ_T / 2
rep       stosw

; SIZEOF_MOBJ_POS_T

mov   di, si
SHIFT_MACRO  sal   di 3     ; 0x08
mov   cx, di
sal   di, 1                  ; 0x10
add   di, cx                 ; 0x18

mov       cx, MOBJPOSLIST_6800_SEGMENT
mov       es, cx
mov       cx, SIZEOF_MOBJ_POS_T /2
rep       stosw

mov       word ptr ds:[bx + _thinkerlist], MAX_THINKERS
lea       di, ds:[bx + _thinkerlist + THINKER_T.t_data]
jmp       done_processing_thinker


; END INLINED P_RunThinkers_



ENDP

PROC P_Random_ NEAR
PUBLIC P_Random_

; ah guaranteed 0!
push    bx
inc 	byte ptr ds:[_prndindex]

xor     ax, ax
mov     bx, ax
mov     al, byte ptr ds:[_prndindex]
xlat    byte ptr cs:[bx]
pop     bx
ret

ENDP


PROC    P_TICK_ENDMARKER_ NEAR
PUBLIC  P_TICK_ENDMARKER_
ENDP


END
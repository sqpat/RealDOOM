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
EXTRN OutOfThinkers_:NEAR


.DATA

EXTRN _prndindex:BYTE
EXTRN _setStateReturn:WORD
EXTRN _attackrange16:WORD
EXTRN _currentThinkerListHead:WORD

.CODE



; THINKERREF __near P_GetNextThinkerRef(void) 

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

imul      bx, ax, SIZEOF_THINKER_T ; get initial thinker offset
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
call      OutOfThinkers_

found_thinker:
mov       word ptr ds:[_currentThinkerListHead], ax
pop       dx

add       si, word ptr ds:[_thinkerlist]

mov       word ptr ds:[bx], si
mov       word ptr ds:[bx+2], 0

imul      si, word ptr ds:[_thinkerlist], SIZEOF_THINKER_T

;	thinkerlist[index].next = 0;
;	thinkerlist[index].prevFunctype = temp + thinkfunc;
;	thinkerlist[temp].next = index;

mov       word ptr ds:[si + _thinkerlist + 2], ax

;	thinkerlist[0].prevFunctype = index;

mov       word ptr ds:[_thinkerlist], ax

xchg      ax, bx
add       ax, 4
pop       si
pop       bx
retf      

ENDP



PROC P_UpdateThinkerFunc_ NEAR
PUBLIC P_UpdateThinkerFunc_

push      bx

IF COMPILE_INSTRUCTIONSET GE COMPILE_186
    imul      bx, ax, SIZEOF_THINKER_T
    add       bx, _thinkerlist

ELSE
    push      dx
    mov       bx, SIZEOF_THINKER_T
    mul       bx
    add       ax, _thinkerlist
    mov       bx, ax
    pop       dx

ENDIF

mov       ax, word ptr ds:[bx]
and       ah, (TF_PREVBITS SHR 8)
add       dx, ax
mov       word ptr ds:[bx], dx
pop       bx
ret       

ENDP

PROC P_RemoveThinker_ NEAR
PUBLIC P_RemoveThinker_

;	thinkerlist[thinkerRef].prevFunctype = (thinkerlist[thinkerRef].prevFunctype & TF_PREVBITS) + TF_DELETEME_HIGHBITS;


push      bx

IF COMPILE_INSTRUCTIONSET GE COMPILE_186
    imul      bx, ax, SIZEOF_THINKER_T
    add       bx, _thinkerlist

ELSE
    push      dx
    mov       bx, SIZEOF_THINKER_T
    mul       bx
    add       ax, _thinkerlist
    mov       bx, ax
    pop       dx

ENDIF
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



PROC P_RunThinkers_ NEAR
PUBLIC P_RunThinkers_

PUSHA_NO_AX_MACRO ; revist once we call outer func...
push      bp
mov       bp, sp
mov       si, word ptr ds:[_thinkerlist + 2]
;test      si, si
;je        exit_run_thinkers  ; 0 thinkers ought to be impossible?
do_next_thinker:
imul      bx, si, SIZEOF_THINKER_T  ; todo test shift vs mul...
imul      dx, si, SIZEOF_MOBJ_POS_T ; todo move later. only if necessary

; consider inc bx?
mov       al, byte ptr ds:[bx + _thinkerlist+1]  ; just get high bit
lea       di, ds:[bx + _thinkerlist + 4]
and       al, (TF_FUNCBITS SHR 8)
cmp       al, (TF_MOBJTHINKER_HIGHBITS SHR 8)
jne       continue_checking_tf_types
do_mobjthinker:
xchg      ax, di
mov       bx, dx  ; todo copy to di
mov       di, dx  ; todo copy to di
mov       cx, MOBJPOSLIST_6800_SEGMENT ; todo remove maybe?
mov       dx, si
call      P_MobjThinker_
done_processing_thinker:
imul      si, si, SIZEOF_THINKER_T  ; todo remove? store in di.
mov       si, word ptr ds:[si + _thinkerlist + 2]
test      si, si
jne       do_next_thinker
exit_run_thinkers:
LEAVE_MACRO
POPA_NO_AX_MACRO
ret   
continue_checking_tf_types:
;test      al, al                   ; not sure if necessary
;je        done_processing_thinker  ; could probable be jl

cmp       al, (TF_DELETEME_HIGHBITS SHR 8)
je        do_delete_me
cbw
SHIFT_MACRO   SAR AX 2     ; highbits function are stores as 0x0800 = 1. took high byte, want word lookup. 0x08 >> 2
xchg      ax, di
mov       dx, si

call      word ptr cs:[_functable + di - 4];
jmp done_processing_thinker



do_delete_me:

;			// time to remove it
; THINKERREF prevRef = thinkerlist[currentthinker].prevFunctype & TF_PREVBITS;
; THINKERREF nextRef = thinkerlist[currentthinker].next;

les       ax, dword ptr ds:[bx + _thinkerlist]  ; prevref
mov       cx, es                                ; nectref

imul      di, cx, SIZEOF_THINKER_T
mov       byte ptr ds:[di + _thinkerlist], 0
and       ah, (TF_PREVBITS SHR 8)
; thinkerlist[nextRef].prevFunctype &= TF_FUNCBITS;
and       byte ptr ds:[di + _thinkerlist+1], (TF_FUNCBITS SHR 8)
; thinkerlist[nextRef].prevFunctype += prevRef;
add       word ptr ds:[di + _thinkerlist], ax

imul      di, ax, SIZEOF_THINKER_T
xor       ax, ax
mov       word ptr [di + _thinkerlist + 2], cx

lea       di, ds:[bx + _thinkerlist + 4]
mov       cx, ds
mov       es, cx
mov       cx, SIZEOF_MOBJ_T / 2
rep       stosw

mov       cx, MOBJPOSLIST_6800_SEGMENT
mov       es, cx
mov       di, dx
mov       cx, SIZEOF_MOBJ_POS_T /2
rep       stosw

mov       word ptr ds:[bx + _thinkerlist], MAX_THINKERS
jmp       done_processing_thinker


ENDP

COMMENT @

PROC P_Ticker_ NEAR
PUBLIC P_Ticker_


cmp       byte ptr ds:[_paused], 0
jne       exit_pticker_return
cmp       byte ptr ds:[_menuactive], 0
je        do_ptick
cmp       byte ptr ds:[_demoplayback], 0
jne       do_ptick
cmp       word ptr ds:[_player + 8 + 2], 0
jne       exit_pticker_return
cmp       word ptr ds:[_player + 8 + 0], 1    ; player.viewzvalue
je        do_ptick
exit_pticker_return
retf      
ENDP
do_ptick:

call      P_PlayerThink_
call      P_RunThinkers_
call      P_UpdateSpecials_
add       word ptr ds:[_leveltime], 1
adc       word ptr ds:[_leveltime], 0
retf  

ENDP

@
END
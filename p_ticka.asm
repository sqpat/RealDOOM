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
EXTRN T_PlatRaise_:NEAR
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



PROC P_RunThinkers_ NEAR
PUBLIC P_RunThinkers_

push      bx
push      cx
push      dx
push      si
push      di
push      bp
mov       bp, sp
sub       sp, 4
mov       si, OFFSET _thinkerlist + 2
mov       si, word ptr [si]
test      si, si
je        exit_run_thinkers
do_next_thinker:
imul      bx, si, SIZEOF_THINKER_T
imul      dx, si, SIZEOF_MOBJ_POS_T
mov       ax, word ptr ds:[bx + _thinkerlist]
mov       word ptr [bp - 2], bx
lea       di, ds:[bx + _thinkerlist + 4]
and       ax, TF_FUNCBITS
mov       word ptr [bp - 4], dx
cmp       ax, TF_DELETEME_HIGHBITS
je        do_delete_me
test      ax, ax
je        done_processing_thinker
cmp       ax, TF_MOVEFLOOR_HIGHBITS
jae       jump_to_do_movefloor
cmp       ax, TF_PLATRAISE_HIGHBITS
jae       jump_to_do_platraise
cmp       ax, TF_MOBJTHINKER_HIGHBITS
jne       done_processing_thinker
do_mobjthinker:
mov       bx, word ptr [bp - 4]
mov       cx, MOBJPOSLIST_6800_SEGMENT
mov       dx, si
mov       ax, di
call      P_MobjThinker_
done_processing_thinker:
imul      si, si, SIZEOF_THINKER_T
mov       si, word ptr ds:[si + _thinkerlist + 2]
test      si, si
jne       do_next_thinker
exit_run_thinkers:
LEAVE_MACRO
pop       di
pop       si
pop       dx
pop       cx
pop       bx
ret       
jump_to_do_movefloor:
jmp       do_movefloor
jump_to_do_platraise:
jmp       do_platraise
do_delete_me:
mov       dx, word ptr ds:[bx + _thinkerlist + 2]
mov       ax, word ptr ds:[bx + _thinkerlist + 0]
imul      bx, dx, SIZEOF_THINKER_T
mov       byte ptr ds:[bx + _thinkerlist], 0
and       ah, 7
and       byte ptr ds:[bx + _thinkerlist+1], (TF_FUNCBITS SHR 8)
add       word ptr ds:[bx + _thinkerlist], ax
imul      bx, ax, SIZEOF_THINKER_T
mov       cx, SIZEOF_MOBJ_T
xor       al, al
mov       word ptr [bx + _thinkerlist + 2], dx
push      di
push      ds
pop       es
mov       ah, al
shr       cx, 1
rep       stosw
pop       di
mov       cx, SIZEOF_MOBJ_POS_T
mov       dx, MOBJPOSLIST_6800_SEGMENT
mov       di, word ptr [bp - 4]
mov       es, dx
mov       bx, word ptr [bp - 2]
push      di
mov       ah, al
shr       cx, 1
rep       stosw
pop       di
mov       word ptr ds:[bx + _thinkerlist], MAX_THINKERS
jmp       done_processing_thinker
do_movefloor:
jbe       actually_do_movefloor
cmp       ax, TF_LIGHTFLASH_HIGHBITS
jae       above_equal_lightflash
cmp       ax, TF_FIREFLICKER_HIGHBITS
jne       done_processing_thinker
do_fireflicker:
mov       dx, si
mov       ax, di
call      T_FireFlicker_
jmp       done_processing_thinker
above_equal_lightflash:
jbe       actually_do_lightflash
cmp       ax, TF_GLOW_HIGHBITS
je        do_glow
cmp       ax, TF_STROBEFLASH_HIGHBITS
je        do_strobeflash
jump_to_done_processing_thinker:
jmp       done_processing_thinker
do_strobeflash:
mov       dx, si
mov       ax, di
call      T_StrobeFlash_
jmp       done_processing_thinker
do_platraise:
jbe       actually_do_platraise
cmp       ax, TF_VERTICALDOOR_HIGHBITS
je        do_verticaldoor
cmp       ax, TF_MOVECEILING_HIGHBITS
jne       jump_to_done_processing_thinker
do_moveceiling:
mov       dx, si
mov       ax, di
call      T_MoveCeiling_
jmp       done_processing_thinker
actually_do_platraise:
mov       dx, si
mov       ax, di
call      T_PlatRaise_
jmp       done_processing_thinker
do_verticaldoor:
mov       dx, si
mov       ax, di
call      T_VerticalDoor_
jmp       done_processing_thinker
actually_do_movefloor:
mov       dx, si
mov       ax, di
call      T_MoveFloor_
jmp       done_processing_thinker
actually_do_lightflash:
mov       dx, si
mov       ax, di
call      T_LightFlash_
jmp       done_processing_thinker
do_glow:
mov       dx, si
mov       ax, di
call      T_Glow_
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
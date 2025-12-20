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


EXTRN locallib_dos_setvect_:NEAR
EXTRN locallib_dos_getvect_:NEAR
EXTRN MUS_ServiceRoutine_:NEAR

.DATA

EXTRN _TS_InInterrupt:BYTE
EXTRN _TS_Installed:BYTE
EXTRN _TaskServiceCount:WORD
EXTRN _TS_TimesInInterrupt:BYTE
EXTRN _OldInt8:DWORD


.CODE



HZ_RATE_35 	=	34058 ;		(1192030L / 35)
HZ_RATE_140 =	8514  ;		(1192030L / 140)

; 140 / 35
HZ_INTERRUPTS_PER_TICK = 4

PROC    D_DMX_STARTMARKER_ NEAR
PUBLIC  D_DMX_STARTMARKER_
ENDP


_lastpcspeakernotevalue:
dw 0



do_chain:
les    cx, dword ptr ds:[_OldInt8]
mov    ax, es
;jmp    locallib_chain_intr_

; inlined chain_intr for now. todo: suck less


;flags bp + 018h
; cs   bp + 016h
; ip   bp + 014h

; ax   bp + 012h    ; replaced with cs:ip for retf
; cx   bp + 010h    ; replaced with cs:ip for retf
; dx   bp + 0Eh
; bx   bp + 0Ch
; sp   bp + 0Ah
; bp   bp + 8
; si   bp + 6
; di   bp + 4
; ds   bp + 2
; es   bp + 0


mov   sp, bp
xchg  word ptr [bp + 010h], cx
xchg  word ptr [bp + 012h], ax
mov   bx, word ptr [bp + 018h]   ; get old flags
and   bx, 0FCFFh
push  bx ; push flags

popf  ; pop flags   ; bp + 01Eh
pop   es ; bp + 0
pop   ds ; bp + 2
pop   di ; bp + 4
pop   si ; bp + 6
pop   bp ; bp + 8
pop   bx ; bp + 0Ah
pop   bx ; bp + 0Ch
pop   dx ; bp + 0Eh
retf  


; main interrupt

PROC   TS_ServiceScheduleIntEnabled_ FAR
PUBLIC TS_ServiceScheduleIntEnabled_

PUSHA_MACRO_REAL 
push   ds
push   es
mov    bp, sp

cld    
mov    ax, FIXED_DS_SEGMENT
mov    ds, ax
inc    byte ptr ds:[_TS_TimesInInterrupt]
add    word ptr ds:[_TaskServiceCount], HZ_RATE_140
jc     do_chain
no_chain:
mov    al, 020h
out    020h, al
xor    ax, ax
cmp    byte ptr ds:[_TS_InInterrupt], al ; 0
jnz    exit_interrupt
inc    byte ptr ds:[_TS_InInterrupt] ; set to 1
sti    

;cmp    byte ptr ds:[_TS_TimesInInterrupt], al ; 0
;je     exit_interrupt_store_not_in_interrupt

repeat_interrupt:
cmp    byte ptr ds:[_HeadTask + TASK_T.task_active], 0
je     done_with_headtask
dec    byte ptr ds:[_HeadTask + TASK_T.task_count]
jnz    done_with_headtask
mov    byte ptr ds:[_HeadTask + TASK_T.task_count], HZ_INTERRUPTS_PER_TICK
inc    word ptr ds:[_ticcount + 0]
jz     add_second_ticcount

done_adding_ticcount_high:
done_with_headtask:
SELFMODIFY_enable_mus_task:
jmp    skip_mus_task
call   MUS_ServiceRoutine_
skip_mus_task:

cmp    word ptr ds:[_pcspeaker_currentoffset], 0
jne    do_pc_speaker

no_pc_speaker:
dec    byte ptr ds:[_TS_TimesInInterrupt]
jnz    repeat_interrupt
exit_interrupt_store_not_in_interrupt:
cli    
mov    byte ptr ds:[_TS_InInterrupt], 0

exit_interrupt:


pop    es
pop    ds
POPA_MACRO_REAL  
iret   


add_second_ticcount:
inc    word ptr ds:[_ticcount + 2]
jmp    done_adding_ticcount_high

do_pc_speaker:
; NO INTERUPT FOR SPEAKER PLAY
cli    
mov    es, ds:[_PC_SPEAKER_SFX_DATA_SEGMENT_PTR]
mov    si, word ptr ds:[_pcspeaker_currentoffset]
lods   word ptr es:[si]
;call   playpcspeakernote_ ; inlined

cmp    si, word ptr ds:[_pcspeaker_endoffset]
jge    end_sound
mov    word ptr ds:[_pcspeaker_currentoffset], si

    test   ax, ax
    je     no_note
    cmp    ax, word ptr cs:[_lastpcspeakernotevalue]
    je     done_with_pcspeaker

    mov    word ptr cs:[_lastpcspeakernotevalue], ax

    ;	outp (0x43, 0xB6);
    ;	outp (0x42, value &0xFF);
    ;	outp (0x42, value >> 8);

    push   ax
    mov    al, 0B6h
    out    043h, al
    pop    ax
    out    042h, al
    mov    al, ah
    out    042h, al
    in     al, 061h
    or     al, 3
    out    061h, al
    jmp    done_with_pcspeaker

    no_note:

    in     al, 061h
    and    al, 0FCh
    out    061h, al
    done_with_pcspeaker:


finish_pc_speaker_update:
sti     ;restore interrupts
jmp  no_pc_speaker
end_sound:
mov    word ptr ds:[_pcspeaker_currentoffset], 0
jmp    no_note



ENDP

COMMENT

PROC   TS_Startup_ NEAR
PUBLIC TS_Startup_


push   bx
push   dx
mov    al, byte ptr ds:[_TS_Installed]
test   al, al
jne    exit_ts_startup
xor    ax, ax
mov    word ptr ds:[_TaskServiceCount], ax
mov    byte ptr ds:[_TS_TimesInInterrupt], al
mov    al, 8
call   locallib_dos_getvect_
mov    word ptr ds:[_OldInt8 + 0], ax
mov    word ptr ds:[_OldInt8 + 2], dx
mov    dx, OFFSET TS_ServiceScheduleIntEnabled_
mov    bx, cs
mov    ax, 8
call   locallib_dos_setvect_
inc    byte ptr ds:[_TS_Installed]
exit_ts_startup:
pop    dx
pop    bx
ret   


ENDP



PROC   TS_ScheduleMainTask_ NEAR
PUBLIC TS_ScheduleMainTask_



call   TS_Startup_
cli    
mov    al, 036h
out    043h, al
mov    al, 042h  ; HZ_RATE_140 & FFh
out    040h, al
mov    al, 021h  ; HZ_RATE_140 >> 8
out    040h, al
sti    
ret



ENDP

PROC   TS_Dispatch_ NEAR
PUBLIC TS_Dispatch_

cli
mov    word ptr ds:[_HeadTask], (1 SHL 8 + HZ_INTERRUPTS_PER_TICK)
;mov    word ptr ds:[_HeadTask], (1 SHL 8 + 0)
cmp    word ptr ds:[_playingdriver + 2], 0
je     dont_set_mustask_active
mov    word ptr cs:[SELFMODIFY_enable_mus_task+0], 0C089h  ; two byte nop
dont_set_mustask_active:
sti    
ret   


ENDP

PROC    D_DMX_ENDMARKER_ NEAR
PUBLIC  D_DMX_ENDMARKER_
ENDP


END


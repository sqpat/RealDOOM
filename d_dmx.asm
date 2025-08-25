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


EXTRN _dos_setvect_:FAR
EXTRN _dos_getvect_:FAR
EXTRN _chain_intr_:FAR
EXTRN MUS_ServiceRoutine_:NEAR
EXTRN TS_ServiceScheduleIntEnabled_:FAR

.DATA

EXTRN _TS_InInterrupt:BYTE
EXTRN _lastpcspeakernotevalue:WORD
EXTRN _TS_Installed:BYTE
EXTRN _TaskServiceCount:WORD
EXTRN _TS_TimesInInterrupt:BYTE
EXTRN _OldInt8:DWORD
EXTRN _HeadTask:TASK_T
EXTRN _MUSTask:TASK_T

.CODE



HZ_RATE_35 	=	34058 ;		(1192030L / 35)
HZ_RATE_140 =	8514  ;		(1192030L / 140)

; 140 / 35
HZ_INTERRUPTS_PER_TICK = 4

PROC    D_DMX_STARTMARKER_ NEAR
PUBLIC  D_DMX_STARTMARKER_
ENDP

COMMENT @

PROC TS_SetTimerToMaxTaskRate_ NEAR
PUBLIC TS_SetTimerToMaxTaskRate_

cli    
mov    al, 036h
out    043h, al
xor    ax, ax
out    040h, al
out    040h, al
sti    
ret   

ENDP

PROC playpcspeakernote_ NEAR
PUBLIC playpcspeakernote_

test   ax, ax
je     no_note
cmp    ax, word ptr ds:[_lastpcspeakernotevalue]
je     exit_play_pc_speaker_note

mov    word ptr ds:[_lastpcspeakernotevalue], ax

;	outp (0x43, 0xB6);
;	outp (0x42, value &0xFF);
;	outp (0x42, value >> 8);

push   ax
mov    al, 0B6h
out    043h, al
pop    ax
out    042h, al
xchg   al, ah
out    042h, al
in     al, 061h
or     al, 3
out    061h, al
ret

no_note:

in     al, 061h
and    al, 0FCh
out    061h, al
exit_play_pc_speaker_note:
ret



ENDP

do_chain:
jmp    _chain_intr_
jmp    no_chain

; main interrupt

PROC TS_ServiceScheduleIntEnabled_ FAR
PUBLIC TS_ServiceScheduleIntEnabled_

PUSHA_NO_AX_MACRO 
push   ds
push   es
push   ax

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
cmp    byte ptr ds:[_TS_TimesInInterrupt], al ; 0
je     exit_interrupt_store_not_in_interrupt

repeat_interrupt:
cmp    byte ptr ds:[_HeadTask + TASK_T.task_active], al ; 0
je     done_with_headtask
dec    byte ptr ds:[_HeadTask + TASK_T.task_count]
jnz    done_with_headtask
mov    byte ptr ds:[_HeadTask + TASK_T.task_count], HZ_INTERRUPTS_PER_TICK
inc    word ptr ds:[_ticcount + 0]
jz     add_second_ticcount
done_adding_ticcount_high:
done_with_headtask:
cmp    byte ptr ds:[_MUSTask + TASK_T.task_active], al
je     skip_mus_task
call   MUS_ServiceRoutine_
skip_mus_task:

cmp    word ptr ds:[_pcspeaker_currentoffset], 0
je     no_pc_speaker

; STOP INTERUPPT FOR SPEAKER PLAY
cli    
mov    ax, PC_SPEAKER_SFX_DATA_SEGMENT
mov    es, ax
mov    bx, word ptr ds:[_pcspeaker_currentoffset]
mov    ax, word ptr es:[bx]
call   playpcspeakernote_

;			pcspeaker_currentoffset+=2;
;			if (pcspeaker_currentoffset >= pcspeaker_endoffset){
;				pcspeaker_currentoffset = 0;
;				// ? turn off speaker? todo should this be on next frame?
;				outp(0x61, inp(0x61) & 0xFC);
;
;			}

add    bx, 2
mov    ax, word ptr ds:[_pcspeaker_currentoffset]
cmp    bx, word ptr ds:[_pcspeaker_endoffset]
jb     finish_pc_speaker_update
mov    word ptr ds:[_pcspeaker_currentoffset], 0
in     al, 061h
and    al, 0FCh
out    061h, al
finish_pc_speaker_update:
sti    

no_pc_speaker:
dec    byte ptr ds:[_TS_TimesInInterrupt]
jnz    repeat_interrupt
exit_interrupt_store_not_in_interrupt:
cli    
mov    byte ptr ds:[_TS_InInterrupt], 0
exit_interrupt:
pop    ax
pop    es
pop    ds
POPA_NO_AX_MACRO  
iret   

add_second_ticcount:
inc    word ptr ds:[_ticcount + 2]
jmp    done_adding_ticcount_high

ENDP

@


PROC TS_Startup_ NEAR
PUBLIC TS_Startup_


push   bx
push   cx
push   dx
mov    al, byte ptr ds:[_TS_Installed]
test   al, al
jne    exit_ts_startup
xor    ax, ax
mov    word ptr ds:[_TaskServiceCount], ax
mov    byte ptr ds:[_TS_TimesInInterrupt], al
mov    al, 8
call   _dos_getvect_
mov    word ptr ds:[_OldInt8 + 0], ax
mov    word ptr ds:[_OldInt8 + 2], dx
mov    bx, OFFSET TS_ServiceScheduleIntEnabled_
mov    cx, cs
mov    ax, 8
call   _dos_setvect_
mov    byte ptr ds:[_TS_Installed], 1
exit_ts_startup:
pop    dx
pop    cx
pop    bx
ret   


ENDP



PROC TS_ScheduleMainTask_ NEAR
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

PROC TS_Dispatch_ NEAR
PUBLIC TS_Dispatch_

cli
mov    word ptr ds:[_HeadTask], (HZ_INTERRUPTS_PER_TICK SHL 8 + 1)
cmp    word ptr ds:[_playingdriver + 2], 0
je     dont_set_mustask_active
mov    byte ptr ds:[_MUSTask + TASK_T.task_active], 1
dont_set_mustask_active:
sti    
ret   


ENDP

PROC    D_DMX_ENDMARKER_ NEAR
PUBLIC  D_DMX_ENDMARKER_
ENDP


END


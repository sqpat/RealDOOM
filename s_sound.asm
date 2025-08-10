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


EXTRN I_SoundIsPlaying_:FAR
EXTRN I_StopSound_:FAR
EXTRN R_PointToAngle2_:FAR
EXTRN FastMul16u32u_:FAR
EXTRN FastDiv3216u_:FAR
EXTRN S_InitSFXCache_:FAR
EXTRN I_UpdateSoundParams_:FAR
EXTRN I_StartSound_:FAR
EXTRN I_PauseSong_:FAR
EXTRN I_ResumeSong_:FAR

.DATA

EXTRN _sfx_priority:BYTE
EXTRN _numChannels:BYTE
EXTRN _channels:WORD
EXTRN _snd_SfxVolume:BYTE
EXTRN _sb_voicelist:WORD
EXTRN _mus_paused:BYTE

.CODE

PROC    S_SOUND_STARTMARKER_ NEAR
PUBLIC  S_SOUND_STARTMARKER_
ENDP

PROC    S_SetMusicVolume_ FAR
PUBLIC  S_SetMusicVolume_

mov   ah, al
SHIFT_MACRO shl   ah 3
mov   byte ptr ds:[_snd_MusicVolume], ah
xor   ah, ah
cmp   byte ptr ds:[_playingdriver+3], ah  ; segment high byte shouldnt be 0 if its set.
je    exit_setmusicvolume
push  bx
les   bx, dword ptr ds:[_playingdriver]
; takes in ax, ah is 0...
call  es:[bx + MUSIC_DRIVER_T.md_changesystemvolume_func]
pop   bx
exit_setmusicvolume:
retf  


ENDP

PROC    S_ChangeMusic_ FAR
PUBLIC  S_ChangeMusic_

mov   byte ptr ds:[_pendingmusicenum], al
mov   byte ptr ds:[_pendingmusicenumlooping], dl
retf  


ENDP

PROC    S_StartMusic_ FAR
PUBLIC  S_StartMusic_

mov   byte ptr ds:[_pendingmusicenum], al
mov   byte ptr ds:[_pendingmusicenumlooping], 0
retf  

ENDP

SIZEOF_CHANNEL_T = 6

PROC    S_StopChannel_ FAR
PUBLIC  S_StopChannel_


; dh gets cnum

; dl will have i
; si will have channels[cnum]

push  si
cbw  
mov   si, ax
sal   si, 1  ; 2
add   si, ax ; 3
sal   si, 1  ; 6
add   si, _channels
cmp   byte ptr ds:[si + CHANNEL_T.channel_sfx_id], ah ; 0 or SFX_NONE
je    exit_stop_channel
mov   al, byte ptr ds:[si + CHANNEL_T.channel_handle]

call  I_SoundIsPlaying_  ; todo stc/clc
test  al, al
je    dont_stop_sound
mov   al, byte ptr ds:[si + CHANNEL_T.channel_handle]
call  I_StopSound_

dont_stop_sound:

mov   byte ptr ds:[si + CHANNEL_T.channel_sfx_id], SFX_NONE ; 0

exit_stop_channel:
pop   si
retf  

ENDP

PROC    S_AdjustSoundParamsSep_ NEAR
PUBLIC  S_AdjustSoundParamsSep_



push  cx ; params to R_PointToAngle2_
push  bx
push  dx
push  ax

les   bx, dword ptr ds:[_playerMobj_pos]

mov   ax, word ptr es:[bx + MOBJ_POS_T.mp_x + 0]
mov   dx, word ptr es:[bx + MOBJ_POS_T.mp_x + 2]
les   bx, dword ptr es:[bx + MOBJ_POS_T.mp_y + 0]
mov   cx, es


call  R_PointToAngle2_

les   bx, dword ptr ds:[_playerMobj_pos]
les   bx, dword ptr es:[bx + MOBJ_POS_T.mp_angle + 0]
mov   cx, es

cmp   dx, cx
jg    adjustment_angle_above
jne   adjustment_angle_below
cmp   ax, bx
ja    adjustment_angle_above

adjustment_angle_below:
; es already has cx

; (0xffffffff - playerMobj_pos->angle.w)

mov   cx, 0FFFFh
sub   bx, cx
mov   cx, es ; recover cx
mov   es, bx ; store this
mov   bx, 0FFFFh
sbb   cx, bx
mov   es, bx
add   ax, bx
adc   dx, cx
jmp   done_with_angle_adjustment
adjustment_angle_above:
sub   ax, bx
sbb   dx, cx
done_with_angle_adjustment:

; fine angle
sar   dx, 1
and   dx, 0FFFCh

mov   ax, FINESINE_SEGMENT
mov   es, ax
les   bx, dword ptr es:[bx]
mov   cx, es
mov   ax, S_STEREO_SWING_HIGH

call  FastMul16u32u_;  mul by 96.. worth inlining shift stuff?

mov   ah, 128
sub   ah, al
mov   al, ah
ret  


ENDP

PROC    S_AdjustSoundParamsVol_ NEAR
PUBLIC  S_AdjustSoundParamsVol_


;    adx.w = labs(playerMobj_pos->x.w - sourceX.w);
;    ady.w = labs(playerMobj_pos->y.w - sourceY.w);


push  si
push  di

mov   si, bx
mov   di, cx


les   si, dword ptr ds:[_playerMobj_pos]
mov   bx, word ptr es:[si + MOBJ_POS_T.mp_x + 0]
mov   cx, word ptr es:[si + MOBJ_POS_T.mp_x + 2]
sub   bx, ax
sbb   cx, dx

test  bx, bx
jns   x_already_positive
neg   bx
adc   cx, 0
neg   cx
x_already_positive:
les   ax, dword ptr es:[si + MOBJ_POS_T.mp_y + 0]
mov   dx, es
sub   ax, si
sbb   dx, di
test  dx, dx
jns   y_already_positive
neg   ax
adc   dx, 0
neg   dx
y_already_positive:


;	intermediate.w = ((adx.w < ady.w ? adx.w : ady.w)>>1);

cmp   cx, dx
jg    adx_greater_than_ady
jl    adx_less_than_ady
cmp   bx, ax
ja    adx_greater_than_ady
adx_less_than_ady:

mov   si, bx
mov   di, cx

jmp   done_calculating_intermediate

adx_greater_than_ady:
mov   si, ax
mov   di, dx

done_calculating_intermediate:
sar   di, 1
rcr   si, 1

; di:si is intermediate

;approx_dist.w = adx.w + ady.w - intermediate.w;
add   ax, bx
adc   dx, cx
sub   ax, si
sbb   dx, di

pop   di
pop   si ; dont use di/si anymore. can just ret
; dx:ax is approx_dist

;    if (gamemap != 8 && approx_dist.w > S_CLIPPING_DIST) {
;		return 0;
;     }


cmp   byte ptr ds:[_gamemap], 8
je    skip_clip_dist_check
cmp   dx, S_CLIPPING_DIST_HIGH
jg    exit_s_adjustsoundparams_ret_0
jne   skip_clip_dist_check
test  ax, ax
je    skip_clip_dist_check
exit_s_adjustsoundparams_ret_0:
xor   ax, ax
exit_s_adjustsoundparams:
ret   

skip_clip_dist_check:
cmp   dx, S_CLOSE_DIST_HIGH
jl    clip_max_vol

;	intermediate.w = S_CLIPPING_DIST - approx_dist.w;

neg   ax  ; set carry?
mov   ax, S_CLIPPING_DIST_HIGH
sbb   ax, dx
mov   bx, S_ATTENUATOR

; ax intermediate highbits
cmp   byte ptr ds:[_gamemap], 8
je    is_map_8
; gamemap 8 case
cmp   dx, S_CLIPPING_DIST_HIGH
jl    dont_clip_map_8_high
mov   al, 15
ret

clip_max_vol:
mov   al, MAX_SOUND_VOLUME
ret

is_map_8:
mov   dx, MAX_SOUND_VOLUME
imul  dx
call  FastDiv3216u_
ret
dont_clip_map_8_high:
mov   dx, (MAX_SOUND_VOLUME - 15)
imul  dx
call  FastDiv3216u_
add   al, 15
ret

ENDP

PROC    S_SetSfxVolume_ FAR
PUBLIC  S_SetSfxVolume_


push  bx
cbw
test  al, al

je    dont_adjust_vol_up
SHIFT_MACRO shl   al 3
add   al, 7
dont_adjust_vol_up:

mov   byte ptr ds:[_snd_SfxVolume], al

cli   
mov   bx, OFFSET _sb_voicelist

;	//Kind of complicated... 
;	// unload sfx. stop all sfx.
;	// when we reload, the sfx will be premixed with application volume.
;	// this way we dont do it in interrupt.

loop_next_voiceinfo_setsfxvol:
mov   byte ptr ds:[bx + SB_VOICEINFO_T.sbvi_sfx_id], ah
add   bx, SIZEOF_SB_VOICEINFO_T
cmp   bx, (OFFSET _sb_voicelist + (NUM_SFX_TO_MIX * SIZEOF_SB_VOICEINFO_T))
jl    loop_next_voiceinfo_setsfxvol

call  S_InitSFXCache_
sti   
pop   bx
retf  

ENDP

PROC    S_PauseSound_ FAR
PUBLIC  S_PauseSound_


cmp   byte ptr ds:[_mus_playing], 0
je    exit_pause_sound
cmp   byte ptr ds:[_mus_paused], 0  ; todo put these adjacent. use a single word check
jne   exit_pause_sound
call  I_PauseSong_
mov   byte ptr ds:[_mus_paused], 1
exit_pause_sound:
retf  

ENDP

PROC    S_ResumeSound_ FAR
PUBLIC  S_ResumeSound_

cmp   byte ptr ds:[_mus_playing], 0
je    exit_resume_sound
cmp   byte ptr ds:[_mus_paused], 0    ; todo put these adjacent. use a single word check
je    exit_resume_sound
call  I_ResumeSong_
mov   byte ptr ds:[_mus_paused], 0
exit_resume_sound:
retf  

ENDP

PROC    S_StopSound_ FAR
PUBLIC  S_StopSound_

;void __far S_StopSound(mobj_t __near* origin, int16_t soundorg_secnum) {

push  dx  ; push/pop dx allows the following function to piggyback.
push  bx
push  si

cmp   dx, SECNUM_NULL
je    check_for_origin
; check_for_secnum
xchg  ax, dx       ; loop condition soundorg_secnum
mov   bx, CHANNEL_T.channel_soundorg_secnum

jmp   setup_stopsound_channel_loop

check_for_origin:

xor   dx, dx
mov   si, SIZEOF_THINKER_T
sub   ax, (_thinkerlist + THINKER_T.t_data)
div   si ; loop condition originRef

check_for_mobjref:
mov   bx, CHANNEL_T.channel_originRef

; si + bx is comparison target
; ax is what to compare to
; dl is i for StopChannel call.
; dh is end condition for loop.

setup_stopsound_channel_loop:
cwd   ; zero dx. ax should be < 0x8000 in either case
mov   si, _channels
mov   dh, byte ptr ds:[_numChannels]
test  dh, dh
je    exit_stopsound


loop_next_channel_stopsound:
cmp   byte ptr ds:[si + CHANNEL_T.channel_sfx_id], bh ; bh is zero for sure
je    iter_next_channel_stopsound
cmp   word ptr ds:[si + bx], ax
jne   iter_next_channel_stopsound
xchg  ax, dx
cbw   ; necessary?
call  S_StopChannel_
pop   si
pop   bx
pop   dx
retf  
iter_next_channel_stopsound:
add   si, SIZEOF_CHANNEL_T
inc   dx
cmp   dl, dh
jl    loop_next_channel_stopsound
exit_stopsound:
pop   si
pop   bx
pop   dx
retf  

ENDP

PROC    S_StopSoundMobjRef_ FAR
PUBLIC  S_StopSoundMobjRef_

push  dx
push  bx
push  si
jmp   check_for_mobjref


ENDP

PROC    S_getChannel_ FAR
PUBLIC  S_getChannel_

push  cx
push  si
push  di
push  bp
mov   bp, sp
sub   sp, 4
mov   cx, ax
mov   word ptr [bp - 2], dx
mov   bh, bl
mov   si, SIZEOF_THINKER_T
sub   ax, (_thinkerlist + THINKER_T.t_data)
xor   dx, dx
div   si
xor   bl, bl
mov   dl, byte ptr ds:[_numChannels]
mov   di, ax
label_35:
mov   al, bl
xor   dh, dh
cbw  
cmp   ax, dx
jge   label_30
imul  si, ax, 6
cmp   byte ptr ds:[si + _channels + CHANNEL_T.channel_sfx_id], 0
jne   label_33
label_30:
mov   al, bl
cbw  
mov   dx, ax
mov   al, byte ptr ds:[_numChannels]
xor   ah, ah
cmp   dx, ax
jne   label_31
xor   bl, bl
label_34:
mov   al, bl
mov   dl, byte ptr ds:[_numChannels]
cbw  
xor   dh, dh
cmp   ax, dx
jge   label_32
imul  si, ax, 6
mov   al, byte ptr ds:[si + _channels + CHANNEL_T.channel_sfx_id]
xor   ah, ah
mov   si, ax
mov   dl, bh
mov   al, byte ptr ds:[si + _sfx_priority]
mov   si, dx
cmp   al, byte ptr ds:[si + _sfx_priority]
jae   label_32
inc   bl
jmp   label_34
label_33:
test  cx, cx
jne   label_36
label_37:
inc   bl
jmp   label_35
label_36:
cmp   di, word ptr ds:[si + _channels + CHANNEL_T.channel_originRef]
jne   label_37

call  S_StopChannel_
jmp   label_30
label_32:
mov   byte ptr [bp - 3], 0
mov   al, bl
mov   dl, byte ptr ds:[_numChannels]
cbw  
mov   byte ptr [bp - 4], dl
cmp   ax, word ptr [bp - 4]
je    label_44

call  S_StopChannel_
label_31:
mov   al, bl
cbw  
mov   dx, ax
shl   ax, 2
sub   ax, dx
mov   si, _channels
add   ax, ax
add   si, ax
mov   byte ptr ds:[si + CHANNEL_T.channel_sfx_id], bh
test  cx, cx
je    label_68
mov   ax, cx
xor   dx, dx
mov   cx, SIZEOF_THINKER_T
sub   ax, (_thinkerlist + THINKER_T.t_data)
div   cx
label_45:
mov   word ptr ds:[si + CHANNEL_T.channel_originRef], ax
mov   ax, word ptr [bp - 2]
mov   word ptr ds:[si], ax
mov   al, bl
exit_s_getchannel:
LEAVE_MACRO 
pop   di
pop   si
pop   cx
retf   
label_44:
mov   al, -1
jmp   exit_s_getchannel
label_68:
mov   ax, -1
jmp   label_45

ENDP

PROC    S_StartSoundWithPosition_ FAR
PUBLIC  S_StartSoundWithPosition_

push  cx
push  si
push  di
push  bp
mov   bp, sp
sub   sp, 010h
mov   di, ax
mov   byte ptr [bp - 8], dl
mov   si, bx
mov   bx, SIZEOF_THINKER_T
sub   ax, (_thinkerlist + THINKER_T.t_data)
xor   dx, dx
div   bx
mov   bx, _snd_SfxDevice
mov   byte ptr [bp - 4], MAX_SOUND_VOLUME
cmp   byte ptr ds:[bx], 0
jne   label_46
jmp   exit_startsoundwithposition
label_46:
test  di, di
jne   label_47
jmp   label_48
label_47:
mov   bx, _playerMobjRef
cmp   ax, word ptr ds:[bx]
jne   label_49
jmp   label_50
label_49:
cmp   si, -1
jne   label_51
jmp   label_52
label_51:
mov   bx, si
mov   ax, SECTORS_SOUNDORGS_SEGMENT
shl   bx, 2
mov   es, ax
mov   ax, word ptr es:[bx]
mov   word ptr [bp - 0Ch], ax
mov   ax, word ptr es:[bx + 2]
mov   word ptr [bp - 0Eh], ax
xor   ax, ax
add   bx, 2
mov   word ptr [bp - 0Ah], ax
mov   word ptr [bp - 010h], ax
label_56:
mov   bx, word ptr [bp - 010h]
mov   cx, word ptr [bp - 0Eh]
mov   ax, word ptr [bp - 0Ah]
mov   dx, word ptr [bp - 0Ch]
call  S_AdjustSoundParamsVol_  ; todo inline only use?
mov   byte ptr [bp - 4], al
test  al, al
je    exit_startsoundwithposition
mov   bx, _playerMobj_pos
les   dx, dword ptr ds:[bx]
mov   bx, dx
mov   ax, word ptr [bp - 0Ch]
cmp   ax, word ptr es:[bx + MOBJ_POS_T.mp_x + 2]
jne   label_53
mov   ax, word ptr [bp - 0Ah]
cmp   ax, word ptr es:[bx + MOBJ_POS_T.mp_x + 0]
jne   label_53
mov   bx, _playerMobj_pos
les   dx, dword ptr ds:[bx]
mov   bx, dx
mov   ax, word ptr [bp - 0Eh]
cmp   ax, word ptr es:[bx + MOBJ_POS_T.mp_y + 2]
jne   label_53
mov   ax, word ptr [bp - 010h]
cmp   ax, word ptr es:[bx + MOBJ_POS_T.mp_y + 0]
jne   label_53
label_50:
mov   byte ptr [bp - 2], NORM_SEP
label_55:
mov   dx, si
mov   ax, di
mov   cl, byte ptr [bp - 8]
call  S_StopSound_
mov   dx, si
xor   ch, ch
mov   ax, di
mov   bx, cx
call  S_getChannel_
mov   byte ptr [bp - 6], al
test  al, al
jge   label_54
exit_startsoundwithposition:
LEAVE_MACRO 
pop   di
pop   si
pop   cx
retf  
label_48:
cmp   si, -1
je    label_50
jmp   label_47
label_53:
mov   bx, word ptr [bp - 010h]
mov   cx, word ptr [bp - 0Eh]
mov   ax, word ptr [bp - 0Ah]
mov   dx, word ptr [bp - 0Ch]

call  S_AdjustSoundParamsSep_  ; todo inline only use?
mov   byte ptr [bp - 2], al
jmp   label_55
label_52:
imul  bx, ax, SIZEOF_MOBJ_POS_T
mov   es, word ptr ds:[_MOBJPOSLIST_6800_SEGMENT_PTR]
mov   ax, word ptr es:[bx + MOBJ_POS_T.mp_x + 0]
mov   word ptr [bp - 0Ah], ax
mov   ax, word ptr es:[bx + MOBJ_POS_T.mp_x + 2]
mov   word ptr [bp - 0Ch], ax
mov   ax, word ptr es:[bx + MOBJ_POS_T.mp_y + 0]
mov   word ptr [bp - 010h], ax
mov   ax, word ptr es:[bx + MOBJ_POS_T.mp_y + 2]
mov   word ptr [bp - 0Eh], ax
jmp   label_56
label_54:
mov   bl, byte ptr [bp - 2]
mov   dl, byte ptr [bp - 4]
mov   ax, cx
xor   bh, bh
xor   dh, dh
call  I_StartSound_
cbw  
mov   dx, ax
cmp   ax, -1
je    exit_startsoundwithposition
mov   al, byte ptr [bp - 6]
cbw  
mov   si, ax
shl   si, 2
sub   si, ax
add   si, si
mov   byte ptr ds:[si + _channels + CHANNEL_T.channel_handle], dl
LEAVE_MACRO 
pop   di
pop   si
pop   cx
retf  

ENDP

PROC    S_StartSound_ FAR
PUBLIC  S_StartSound_

push  bx
test  dl, dl
jne   label_57
pop   bx
retf  
label_57:
mov   bx, -1
xor   dh, dh
call  S_StartSoundWithPosition_
pop   bx
retf  

ENDP

PROC    S_StartSoundWithParams_ FAR
PUBLIC  S_StartSoundWithParams_

push  bx
test  dl, dl
jne   label_58
pop   bx
retf  
label_58:
mov   bx, ax
xor   dh, dh
xor   ax, ax
call  S_StartSoundWithPosition_
pop   bx
retf  

ENDP

PROC    S_UpdateSounds_ FAR
PUBLIC  S_UpdateSounds_

push  bx
push  cx
push  dx
push  si
push  di
push  bp
mov   bp, sp
sub   sp, 0Ah
mov   byte ptr [bp - 4], 0
label_61:
mov   al, byte ptr [bp - 4]
cbw  
mov   di, ax
mov   al, byte ptr ds:[_numChannels]
xor   ah, ah
cmp   di, ax
jge   label_59
imul  si, di, 6
add   si, _channels
mov   al, byte ptr ds:[si + + CHANNEL_T.channel_sfx_id]
test  al, al
jne   label_60
inc   byte ptr [bp - 4]
jmp   label_61
label_59:
jmp   exit_s_updatesounds
label_60:
mov   al, byte ptr ds:[si + + CHANNEL_T.channel_handle]
cbw  
call  I_SoundIsPlaying_
test  al, al
je    jump_to_label_64
cmp   word ptr ds:[si + + CHANNEL_T.channel_originRef], -1
je    label_65
mov   bx, _playerMobjRef
mov   ax, word ptr ds:[bx]
cmp   ax, word ptr ds:[si + + CHANNEL_T.channel_originRef]
je    label_65
label_62:
mov   ax, word ptr ds:[si]
cmp   ax, -1
je    label_67
mov   dx, SECTORS_SOUNDORGS_SEGMENT
mov   bx, ax
mov   word ptr [bp - 8], 0
shl   bx, 2
mov   es, dx
xor   di, di
mov   dx, word ptr es:[bx]
mov   ax, word ptr es:[bx + 2]
add   bx, 2
mov   word ptr [bp - 6], dx
label_63:
mov   word ptr [bp - 0Ah], ax
mov   cx, word ptr [bp - 0Ah]
mov   ax, word ptr [bp - 8]
mov   dx, word ptr [bp - 6]
mov   bx, di
call  S_AdjustSoundParamsVol_
mov   byte ptr [bp - 2], al
test  al, al
jne   label_66
mov   al, byte ptr [bp - 4]
cbw  

call  S_StopChannel_
inc   byte ptr [bp - 4]
jmp   label_61
label_65:
cmp   word ptr ds:[si], -1
jne   label_62
inc   byte ptr [bp - 4]
jmp   label_61
jump_to_label_64:
jmp   label_64
label_67:
imul  bx, word ptr ds:[si + + CHANNEL_T.channel_originRef], SIZEOF_MOBJ_POS_T

mov   es, word ptr ds:[_MOBJPOSLIST_6800_SEGMENT_PTR]
mov   ax, word ptr es:[bx + MOBJ_POS_T.mp_x + 0]
mov   word ptr [bp - 8], ax
mov   ax, word ptr es:[bx + MOBJ_POS_T.mp_x + 2]
mov   word ptr [bp - 6], ax
mov   ax, word ptr es:[bx + MOBJ_POS_T.mp_y + 2]
mov   di, word ptr es:[bx + MOBJ_POS_T.mp_y + 0]
jmp   label_63
label_66:
mov   cx, word ptr [bp - 0Ah]
mov   ax, word ptr [bp - 8]
mov   dx, word ptr [bp - 6]
mov   bx, di

call  S_AdjustSoundParamsSep_
mov   dl, byte ptr [bp - 2]
mov   bl, al
mov   al, byte ptr ds:[si + + CHANNEL_T.channel_handle]
xor   bh, bh
xor   dh, dh
cbw  
call I_UpdateSoundParams_
inc   byte ptr [bp - 4]
jmp   label_61
label_64:
mov   ax, di
call  S_StopChannel_
inc   byte ptr [bp - 4]
jmp   label_61
exit_s_updatesounds:
LEAVE_MACRO
pop   di
pop   si
pop   dx
pop   cx
pop   bx
retf  

ENDP


PROC    S_SOUND_ENDMARKER_ NEAR
PUBLIC  S_SOUND_ENDMARKER_
ENDP



END
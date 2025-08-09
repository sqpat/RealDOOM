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

.DATA

EXTRN _sfx_priority:BYTE
EXTRN _numChannels:BYTE
EXTRN _channels:WORD
EXTRN _snd_SfxVolume:BYTE
EXTRN _sb_voicelist:WORD
EXTRN _mus_paused:BYTE

.CODE

S_CLIPPING_DIST_HIGH = 1200
S_CLOSE_DIST_HIGH = 200
S_ATTENUATOR = 1000
MAX_SOUND_VOLUME = 127
S_STEREO_SWING_HIGH = 96

PROC    S_SOUND_STARTMARKER_ NEAR
PUBLIC  S_SOUND_STARTMARKER_
ENDP

PROC    S_SetMusicVolume_ NEAR
PUBLIC  S_SetMusicVolume_

push  bx
push  si
mov   ah, al
mov   bx, _snd_MusicVolume
shl   ah, 3
mov   byte ptr ds:[bx], ah
mov   bx, _playingdriver
mov   si, word ptr ds:[bx]
mov   bx, word ptr ds:[bx + 2]
test  bx, bx
jne   also_change_system_volume
test  si, si
jne   also_change_system_volume
pop   si
pop   bx
retf  
also_change_system_volume:
mov   bx, _playingdriver
les   si, dword ptr ds:[bx]
xor   ah, ah
call  es:[si + MUSIC_DRIVER_T.md_changesystemvolume_func]
pop   si
pop   bx
retf  


ENDP

PROC    S_ChangeMusic_ NEAR
PUBLIC  S_ChangeMusic_


push  bx
mov   bx, _pendingmusicenum
mov   byte ptr ds:[bx], al
mov   bx, _pendingmusicenumlooping
mov   byte ptr ds:[bx], dl
pop   bx
retf  


ENDP

PROC    S_StartMusic_ NEAR
PUBLIC  S_StartMusic_


push  bx
mov   bx, _pendingmusicenum
mov   byte ptr ds:[bx], al
mov   bx, _pendingmusicenumlooping
mov   byte ptr ds:[bx], 0
pop   bx
retf  

ENDP

PROC    S_StopChannel_ NEAR
PUBLIC  S_StopChannel_


push  bx
push  cx
push  dx
push  si
mov   cl, byte ptr ds:[_numChannels]
mov   dh, al
cbw  
mov   bx, ax
shl   ax, 2
sub   ax, bx
mov   si, _channels
add   ax, ax
add   si, ax
cmp   byte ptr ds:[si + CHANNEL_T.channel_sfx_id], 0
jne   label_1
mov   cl, byte ptr ds:[_numChannels]
pop   si
pop   dx
pop   cx
pop   bx
retf  
label_1:
mov   al, byte ptr ds:[si + CHANNEL_T.channel_handle]
cbw  
call  I_SoundIsPlaying_
test  al, al
jne   label_2
label_10:
mov   cl, byte ptr ds:[_numChannels]
xor   dl, dl
label_9:
mov   al, dl
mov   bl, cl
label_2:
cbw  
xor   bh, bh
cmp   ax, bx
jge   label_7
cmp   dh, dl
jne   label_8
label_11:
inc   dl
jmp   label_9
mov   al, byte ptr ds:[si + CHANNEL_T.channel_handle]
cbw  
call  I_StopSound_
jmp   label_10
label_8:
imul  bx, ax, 6
mov   al, byte ptr ds:[si + CHANNEL_T.channel_sfx_id]
cmp   al, byte ptr ds:[bx + _channels + CHANNEL_T.channel_sfx_id]
jne   label_11
label_7:
mov   byte ptr ds:[_numChannels], cl
mov   byte ptr ds:[si + + CHANNEL_T.channel_sfx_id], 0
mov   cl, byte ptr ds:[_numChannels]
pop   si
pop   dx
pop   cx
pop   bx
retf  

ENDP

PROC    S_AdjustSoundParamsSep_ NEAR
PUBLIC  S_AdjustSoundParamsSep_

push  si
push  cx
push  bx
mov   bx, _playerMobj_pos
push  dx
les   si, dword ptr ds:[bx]
push  ax
mov   bx, word ptr es:[si + MOBJ_POS_T.mp_y + 0]
mov   cx, word ptr es:[si + MOBJ_POS_T.mp_y + 2]
mov   ax, word ptr es:[si + MOBJ_POS_T.mp_x + 0]
mov   si, word ptr es:[si + MOBJ_POS_T.mp_x + 2]
mov   dx, si
mov   si, _playerMobj_pos

call  R_PointToAngle2_
les   bx, dword ptr ds:[si]
cmp   dx, word ptr es:[bx + MOBJ_POS_T.mp_angle + 2]
jg    label_12
jne   label_13
cmp   ax, word ptr es:[bx + MOBJ_POS_T.mp_angle + 0]
jbe   label_13
label_12:
mov   bx, si
mov   si, word ptr ds:[si]
mov   es, word ptr ds:[bx + 2]
sub   ax, word ptr es:[si + MOBJ_POS_T.mp_angle + 0]
sbb   dx, word ptr es:[si + MOBJ_POS_T.mp_angle + 2]
label_14:
mov   bx, dx
mov   ax, FINESINE_SEGMENT
sar   bx, 3
mov   es, ax
shl   bx, 2
mov   ax, word ptr es:[bx]
mov   cx, word ptr es:[bx + 2]
mov   bx, ax
mov   ax, S_STEREO_SWING_HIGH
call  FastMul16u32u_
mov   ah, 128
sub   ah, al
mov   al, ah
pop   si
retf  
label_13:
mov   cx, -1
sub   cx, word ptr es:[bx + MOBJ_POS_T.mp_angle + 0]
mov   si, -1
sbb   si, word ptr es:[bx + MOBJ_POS_T.mp_angle + 2]
add   ax, cx
adc   dx, si
jmp   label_14

ENDP

PROC    S_AdjustSoundParamsVol_ NEAR
PUBLIC  S_AdjustSoundParamsVol_

push  si
push  di
push  bp
mov   bp, sp
sub   sp, 4
push  bx
push  cx
mov   bx, _playerMobj_pos
les   si, dword ptr ds:[bx]
mov   bx, word ptr es:[si + MOBJ_POS_T.mp_x + 0]
sub   bx, ax
mov   ax, bx
mov   bx, word ptr es:[si + MOBJ_POS_T.mp_x + 2]
sbb   bx, dx
mov   dx, bx
mov   di, _playerMobj_pos
or    dx, dx
jge   already_positive
neg   ax
adc   dx, 0
neg   dx
already_positive:
mov   cx, ax
mov   bx, dx
les   si, dword ptr ds:[di]
mov   word ptr [bp - 4], ax
mov   ax, word ptr es:[si + MOBJ_POS_T.mp_y + 0]
mov   word ptr [bp - 2], dx
sub   ax, word ptr [bp - 6]
mov   dx, word ptr es:[si + MOBJ_POS_T.mp_y + 2]
sbb   dx, word ptr [bp - 8]
or    dx, dx
jge   label_3
neg   ax
adc   dx, 0
neg   dx
label_3:
mov   si, ax
mov   di, dx
cmp   bx, dx
jl    label_4
jne   label_5
cmp   cx, ax
jae   label_5
label_4:
mov   ax, cx
mov   dx, bx
label_5:
sar   dx, 1
rcr   ax, 1
mov   cx, dx
mov   dx, word ptr [bp - 4]
add   dx, si
mov   bx, word ptr [bp - 2]
adc   bx, di
sub   dx, ax
mov   ax, bx
mov   bx, _gamemap
sbb   ax, cx
cmp   byte ptr ds:[bx], 8
je    label_6
cmp   ax, S_CLIPPING_DIST_HIGH
jg    exit_s_adjustsoundparams_ret_0
jne   label_6
test  dx, dx
jbe   label_6
exit_s_adjustsoundparams_ret_0:
xor   al, al
LEAVE_MACRO 
pop   di
pop   si
ret   
label_6:
cmp   ax, S_CLOSE_DIST_HIGH
jl    label_15
xor   cx, cx
mov   bx, _gamemap
sub   cx, dx
mov   dx, S_CLIPPING_DIST_HIGH
sbb   dx, ax
cmp   byte ptr ds:[bx], 8
jne   label_16
cmp   ax, S_CLIPPING_DIST_HIGH
jl    label_17
mov   al, 15
LEAVE_MACRO 
pop   di
pop   si
ret   
label_15:
mov   al, MAX_SOUND_VOLUME
LEAVE_MACRO 
pop   di
pop   si
ret   
label_16:
mov   ax, MAX_SOUND_VOLUME
mov   bx, S_ATTENUATOR
imul  dx
call  FastDiv3216u_
LEAVE_MACRO 
pop   di
pop   si
ret   
label_17:
mov   ax, (MAX_SOUND_VOLUME - 15)
mov   bx, S_ATTENUATOR
imul  dx
call  FastDiv3216u_
add   al, 15f
LEAVE_MACRO 
pop   di
pop   si
ret   

ENDP

PROC    S_SetSfxVolume_ NEAR
PUBLIC  S_SetSfxVolume_

push  bx
push  dx
test  al, al
jne   label_18
label_20:
mov   byte ptr ds:[_snd_SfxVolume], al
cli   
xor   dl, dl
label_19:
mov   al, dl
cbw  
mov   bx, ax
shl   bx, 3
inc   dl
mov   byte ptr ds:[bx + _sb_voicelist], 0
cmp   dl, 8
jl    label_19

call  S_InitSFXCache_

sti   
cld   
pop   dx
pop   bx
retf  
label_18:
shl   al, 3
add   al, 7
jmp   label_20

ENDP

PROC    S_PauseSound_ NEAR
PUBLIC  S_PauseSound_


push  bx
mov   bx, _mus_playing
cmp   byte ptr ds:[bx], 0
je    label_21
cmp   byte ptr ds:[_mus_paused], 0
je    label_22
label_21:
pop   bx
retf  
label_22:
call  I_PauseSong_
mov   byte ptr ds:[_mus_paused], 1
pop   bx
retf  

ENDP

PROC    S_ResumeSound_ NEAR
PUBLIC  S_ResumeSound_

push  bx
mov   bx, _mus_playing
cmp   byte ptr ds:[bx], 0
je    label_23
cmp   byte ptr ds:[_mus_paused], 0
jne   label_24
label_23:
pop   bx
retf  
label_24:
call  I_ResumeSong_
mov   byte ptr ds:[_mus_paused], 0
pop   bx
retf  

ENDP

PROC    S_StopSound_ NEAR
PUBLIC  S_StopSound_

push  bx
push  cx
mov   cx, dx
cmp   dx, -1
je    label_25
xor   dl, dl
label_28:
mov   al, dl
mov   bl, byte ptr ds:[_numChannels]
cbw  
xor   bh, bh
cmp   ax, bx
jge   label_26
imul  bx, ax, 6
cmp   byte ptr ds:[bx + _channels + CHANNEL_T.channel_sfx_id], 0
jne   label_27
label_29:
inc   dl
jmp   label_28
label_27:
cmp   cx, word ptr ds:[bx + _channels]
jne   label_29

call  S_StopChannel_
label_26:
pop   cx
pop   bx
retf  
label_25:
test  ax, ax
je    label_26
mov   bx, MUL_SIZEOF_THINKER_T
sub   ax, (_thinkerlist + THINKER_T.t_data)
xor   dx, dx
div   bx
mov   cx, ax
xor   dl, dl
label_39:
mov   al, dl
mov   bl, byte ptr ds:[_numChannels]
cbw  
xor   bh, bh
cmp   ax, bx
jge   label_26
imul  bx, ax, 6
cmp   byte ptr ds:[bx + _channels + CHANNEL_T.channel_sfx_id], 0
jne   label_38
label_40:
inc   dl
jmp   label_39
label_38:
cmp   cx, word ptr ds:[bx + _channels + CHANNEL_T.channel_originRef]
jne   label_40

call  S_StopChannel_
pop   cx
pop   bx
retf  

ENDP

PROC    S_StopSoundMobjRef_ NEAR
PUBLIC  S_StopSoundMobjRef_

push  bx
push  cx
push  dx
test  ax, ax
je    exit_stopsoundmobjref
mov   bx, MUL_SIZEOF_THINKER_T
sub   ax, (_thinkerlist + THINKER_T.t_data)
xor   dx, dx
div   bx
mov   cx, ax
xor   dl, dl
label_42:
mov   al, dl
mov   bl, byte ptr ds:[_numChannels]
cbw  
xor   bh, bh
cmp   ax, bx
jge   exit_stopsoundmobjref
imul  bx, ax, 6
cmp   byte ptr ds:[bx + _channels + CHANNEL_T.channel_sfx_id], 0
jne   label_41
label_43:
inc   dl
jmp   label_42
label_41:
cmp   cx, word ptr ds:[bx + _channels + CHANNEL_T.channel_originRef]
jne   label_43

call  S_StopChannel_
exit_stopsoundmobjref:
pop   dx
pop   cx
pop   bx
retf  

ENDP

PROC    S_getChannel_ NEAR
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
mov   si, MUL_SIZEOF_THINKER_T
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
mov   cx, MUL_SIZEOF_THINKER_T
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
ret   
label_44:
mov   al, -1
jmp   exit_s_getchannel
label_68:
mov   ax, -1
jmp   label_45

ENDP

PROC    S_StartSoundWithPosition_ NEAR
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
mov   bx, MUL_SIZEOF_THINKER_T
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
call  S_AdjustSoundParamsVol_
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
push  cs
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

call  S_AdjustSoundParamsSep_
mov   byte ptr [bp - 2], al
jmp   label_55
label_52:
imul  bx, ax, SIEO_MOBJ_POS_T
mov   es, word ptr ds:[_MOBJPOSLIST_6800_SEGMENT_PTR]
mov   ax, word ptr es:[bx + MOBJ_POS_T.mp_x + 0]
mov   word ptr [bp - 0Ah], ax
mov   ax, word ptr es:[bx + MOBJ_POS_T.mp_x + 2]
mov   word ptr [bp - 0Ch], ax
mov   ax, word ptr es:[bx + MOBJ_POS_T.mp_y + 0]
mov   word ptr [bp - 010h], ax
mov   ax, word ptr es:[bx + MOBJ_POS_T.mp_y + 2]
mov   word ptr [bp - 0Eh], ax
jmp   label_56:
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

PROC    S_StartSound_ NEAR
PUBLIC  S_StartSound_

push  bx
test  dl, dl
jne   label_57
pop   bx
retf  
label_57:
mov   bx, -1
xor   dh, dh
push  cs
call  S_StartSoundWithPosition_
pop   bx
retf  

ENDP

PROC    S_StartSoundWithParams_ NEAR
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
push  cs
call  S_StartSoundWithPosition_
pop   bx
retf  

ENDP

PROC    S_UpdateSounds_ NEAR
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
I_UpdateSoundParams_
inc   byte ptr [bp - 4]
jmp   label_61
label_64:
mov   ax, di
push  cs
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
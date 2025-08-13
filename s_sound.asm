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
EXTRN SFX_PlayPatch_:FAR

.DATA

EXTRN _sfx_priority:BYTE
EXTRN _numChannels:BYTE
EXTRN _channels:WORD
EXTRN _snd_SfxVolume:BYTE
EXTRN _sb_voicelist:WORD

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

PROC    S_StopChannel_ NEAR
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
add   si, OFFSET _channels
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
ret  

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
mov   bx, dx

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

xor   ax, ax
cmp   byte ptr ds:[_mus_playing], al ; 0
je    exit_pause_sound
cmp   byte ptr ds:[_mus_paused], al  ; todo put these adjacent. use a single word check
jne   exit_pause_sound

mov   byte ptr ds:[_playingstate], ST_PAUSED
cmp   byte ptr ds:[_playingdriver+3], al  ; segment high byte shouldnt be 0 if its set.
je    exit_pause_sound
push  bx
les   bx, dword ptr ds:[_playingdriver]
call  es:[bx + MUSIC_DRIVER_T.md_pausemusic_func]
pop   bx
mov   byte ptr ds:[_mus_paused], 1
exit_pause_sound:
retf  

ENDP

PROC    S_ResumeSound_ FAR
PUBLIC  S_ResumeSound_

xor   ax, ax
cmp   byte ptr ds:[_mus_playing], al
je    exit_resume_sound
cmp   byte ptr ds:[_mus_paused], al 
je    exit_resume_sound
mov   byte ptr ds:[_playingstate], ST_PLAYING

cmp   byte ptr ds:[_playingdriver+3], al  ; segment high byte shouldnt be 0 if its set.
je    exit_pause_sound
push  bx
les   bx, dword ptr ds:[_playingdriver]
call  es:[bx + MUSIC_DRIVER_T.md_resumemusic_func]
pop bx

mov   byte ptr ds:[_mus_paused], al ; 0
exit_resume_sound:
retf  

ENDP


PROC    S_StopSound_ FAR ; has to be far for now because because S_StopSoundMobjRef_ jumps in.
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
mov   si, OFFSET _channels
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
; ax already ref
jmp   check_for_mobjref


ENDP

NULL_THINKER_ORIGINREF = -1

;int8_t __near S_getChannel (mobj_t __near* origin, int16_t soundorg_secnum, sfxenum_t sfx_id ) {

PROC    S_getChannel_ NEAR
PUBLIC  S_getChannel_

push  cx
push  si
push  di

mov   di, NULL_THINKER_ORIGINREF
mov   cx, dx ; backup soundorg secnum..
xor   dx, dx
xor   bh, bh ; sfx_id is oft used as byte lookup.

test  ax, ax
jz    dont_get_ref

mov   si, SIZEOF_THINKER_T
sub   ax, (_thinkerlist + THINKER_T.t_data)
div   si
xchg  ax, di  ; di has originref

dont_get_ref:



xor   ax, ax
cwd
mov   ah, byte ptr ds:[_numChannels]
mov   si, OFFSET _channels

; loop al to ah

loop_next_channel_getchannel:
cmp   word ptr ds:[si + CHANNEL_T.channel_sfx_id], dx ; 0
je    foundchannel
cmp   di, NULL_THINKER_ORIGINREF
je    check_secnum_instead
cmp   word ptr ds:[si + CHANNEL_T.channel_originRef], di
jne   iter_next_channel_getchannel
found_channel_to_boot:
cbw
mov   dx, ax
call  S_StopChannel_
xchg  ax, dx

foundchannel:
; al already cnum
; si alredy channel ptr
cbw
mov   byte ptr ds:[si + CHANNEL_T.channel_sfx_id], bl
mov   word ptr ds:[si + CHANNEL_T.channel_originRef], di
mov   word ptr ds:[si + CHANNEL_T.channel_soundorg_secnum], cx

; ax has cnum already

exit_s_getchannel:
pop   di
pop   si
pop   cx
exit_startsoundwithpositionearly:
ret   
check_secnum_instead:
cmp   word ptr ds:[si + CHANNEL_T.channel_soundorg_secnum], cx
je    found_channel_to_boot
iter_next_channel_getchannel:
add   si, SIZEOF_CHANNEL_T
inc   ax
cmp   al, ah
jl    loop_next_channel_getchannel

; NO CHANNEL FOUND. look for lower priority to boot
xor   al, al    ; reset counter
mov   si, OFFSET _channels
mov   dh, byte ptr ds:[bx + _sfx_priority]
; dh stores sfx priority..

loop_next_channel_getchannel_priority:
mov   dl, byte ptr ds:[si + CHANNEL_T.channel_sfx_id]
xchg  dl, bl  ; for _sfx_priority lookup
mov   bl, byte ptr ds:[bx + _sfx_priority] ; bh always 0. these numbers are low
xchg  dl, bl ; original bl back.

cmp   dl, dh
jge   found_channel_to_boot


iter_next_channel_getchannel_priority:
add   si, SIZEOF_CHANNEL_T
inc   ax
cmp   al, ah
jl    loop_next_channel_getchannel_priority

mov   ax, -1 ; no channel found
jmp   exit_s_getchannel



ENDP



PROC    S_StartSoundWithPosition_ NEAR
PUBLIC  S_StartSoundWithPosition_

;void S_StartSoundWithPosition ( mobj_t __near* origin, sfxenum_t sfx_id, int16_t soundorg_secnum ) {


cmp   byte ptr ds:[_snd_SfxDevice], SFX_NONE ; 0
je    exit_startsoundwithpositionearly

push  cx
push  si
push  di
push  bp
mov   bp, sp
xor   dh, dh
push  dx  ; sfx_id is [bp - 2]
mov   di, ax  ; di holds origin
mov   si, bx  ; si holds soundorg_secnum


;	// Check to see if it is audible,
;	//  and if not, modify the params
;	if ((origin || (soundorg_secnum != SECNUM_NULL)) && (originRef != playerMobjRef)){



cmp   si, SECNUM_NULL
jne   location_good_adjust_sound_for_sector


mov   cx, MAX_SOUND_VOLUME ; just in case we skip and dont calculate vol.

test  di, di
je    skip_vol_adjustment_use_norm_setp

; div to get mobjref.

mov   bx, SIZEOF_THINKER_T
sub   ax, (_thinkerlist + THINKER_T.t_data) ; ax still origin
xor   dx, dx
div   bx

; ax is mobjref/originref
cmp   ax, word ptr ds:[_playerMobjRef]
je    skip_vol_adjustment_use_norm_setp

location_good_adjust_sound_for_mobj:


xchg  bx, ax
mov   ax, SIZEOF_MOBJ_POS_T
mul   bx
xchg  ax, bx
mov   es, word ptr ds:[_MOBJPOSLIST_6800_SEGMENT_PTR]

;    originX = originMobjPos->x;
;    originY = originMobjPos->y;

mov   ax, word ptr es:[bx + MOBJ_POS_T.mp_x + 0]
mov   dx, word ptr es:[bx + MOBJ_POS_T.mp_x + 2]
les   bx, dword ptr es:[bx + MOBJ_POS_T.mp_y + 0]
mov   cx, es
jmp   params_ready_for_sound_vol_adjust



location_good_adjust_sound_for_sector:
;mov   bx, si  ; bx already si
mov   ax, SECTORS_SOUNDORGS_SEGMENT
mov   es, ax
SHIFT_MACRO shl   bx 2
les   ax, dword ptr es:[bx + SECTOR_SOUNDORG_T.secso_soundorgX]
mov   dx, es
xor   cx, cx
mov   bx, cx

params_ready_for_sound_vol_adjust:

push  cx ; bp - 4
push  bx ; bp - 6
push  dx ; bp - 8
push  ax ; bp - 0Ah  ;store in reverse order for later cmpsw.

call  S_AdjustSoundParamsVol_  ; todo inline only use?

test  al, al
je    exit_startsoundwithposition

;		if ( originX.w == playerMobj_pos->x.w && originY.w == playerMobj_pos->y.w) {	
; we will do this with cmpsw.

push  di
push  si

lea   si, [bp - 0Ah]
les   di, dword ptr ds:[_playerMobj_pos]
; es:di points to MOBJ_POS_T.mp_x already
mov   cx, 4
repe  cmpsw

pop   si ; restore
pop   di ; restore

jnz   calculate_separation

; fall thru. use norm sep
xchg  ax, cx ; volume
skip_vol_adjustment_use_norm_setp:
mov   ax, NORM_SEP
done_with_vol_adjustment:

; cx has volume
; ax has sep
xchg  ax, bx  ; bx has sep

mov   dx, si
mov   ax, di
call  S_StopSound_  ;  S_StopSound(origin, soundorg_secnum);

mov   dx, si
xchg  ax, di
mov   di, bx  ; di has sep
mov   bx, word ptr [bp - 2] ; recover sfx_id
mov   si, bx ; copy sfx id to si

call  S_getChannel_  ; cnum = S_getChannel(origin, soundorg_secnum, sfx_id);
test  al, al
jnge  exit_startsoundwithposition
 
mov   bx, cx ; volume
mov   dx, di ; sep
xchg  ax, si ; si gets cnum. ax gets sfx_id

; todo this could be inlined and the inner check for driver type could be self modified.
; INLINED I_StartSound_

cmp   byte ptr ds:[_snd_SfxDevice], SND_PC
je    handle_pc_speaker_sound
jb    exit_startsoundwithposition ; no sfx driver to play.
; fallthru to sb sound


call  SFX_PlayPatch_


done_with_i_sound:

cmp   al, -1
je    exit_startsoundwithposition
successful_play:
mov   al, byte ptr [bp - 6]
sal   si, 1  ; x2
mov   bx, si ; x2
sal   si, 1  ; x2 + x4 = 6
mov   byte ptr ds:[bx + si + _channels + CHANNEL_T.channel_handle], al

exit_startsoundwithposition:
LEAVE_MACRO 
pop   di
pop   si
pop   cx
ret

calculate_separation:
mov   es, ax
pop   ax ;volume
pop   dx
pop   bx
pop   cx
push  es

call  S_AdjustSoundParamsSep_  ; todo inline only use?
pop   cx ; volume
jmp   done_with_vol_adjustment


handle_pc_speaker_sound:

cmp   al, SFX_POPAIN
je    exit_startsoundwithposition
cmp   al, SFX_SAWIDL
je    exit_startsoundwithposition
cmp   al, SFX_DMPAIN
je    exit_startsoundwithposition
cmp   al, SFX_POSACT
jb    do_pc_speaker_sound
cmp   al, SFX_DMACT
jnbe  exit_startsoundwithposition  
do_pc_speaker_sound:

dec   ax
xchg  ax, bx
mov   ax, PC_SPEAKER_OFFSETS_SEGMENT
mov   es, ax
sal   bx, 1
cli
les   ax,  dword ptr es:[bx]
mov   word ptr ds:[_pcspeaker_currentoffset], ax
mov   word ptr ds:[_pcspeaker_endoffset], es
sti
jmp   successful_play



ENDP

PROC    S_StartSound_ FAR
PUBLIC  S_StartSound_

test  dl, dl
je    exit_startsound_sfxid_0
push  bx
mov   bx, -1
call  S_StartSoundWithPosition_
pop   bx
exit_startsound_sfxid_0:
retf  

ENDP

PROC    S_StartSoundWithSecnum_ FAR
PUBLIC  S_StartSoundWithSecnum_

test  dl, dl
je    exit_startsound_sfxid_0
push  bx
xchg  ax, bx
xor   ax, ax
call  S_StartSoundWithPosition_
pop   bx
retf  

ENDP

PROC    S_UpdateSounds_ FAR
PUBLIC  S_UpdateSounds_

PUSHA_NO_AX_OR_BP_MACRO

mov   si, OFFSET _channels
xor   ax, ax
cwd
mov   dh, byte ptr ds:[_numChannels]
test  dh, dh
je    exit_s_updatesounds
loop_next_channel_updatesounds:
mov   cl, byte ptr ds:[si + CHANNEL_T.channel_sfx_id]
test  cl, cl
je    iter_next_channel_updatesounds
call  I_SoundIsPlaying_
test  al, al
jne   handle_position_update
do_stop_channel_and_iter:
mov   al, dl
cbw
call  S_StopChannel_
jmp   iter_next_channel_updatesounds
handle_position_update:

mov   di, dx ; back this up...

cmp   word ptr ds:[si + CHANNEL_T.channel_soundorg_secnum], SECNUM_NULL
jne   update_sound_with_mobjpos
update_sound_with_sector:
mov   ax, SECTORS_SOUNDORGS_SEGMENT
mov   es, ax
SHIFT_MACRO shl   bx 2
les   ax, dword ptr es:[bx + SECTOR_SOUNDORG_T.secso_soundorgX]
mov   dx, es
xor   cx, cx
mov   bx, cx

origins_ready:

push  cx ; bp - 4
push  bx ; bp - 6
push  dx ; bp - 8
push  ax ; bp - 0Ah  ;store in reverse order for later cmpsw.

call  S_AdjustSoundParamsVol_  ; todo inline only use?

test  al, al
jne   update_sound_params

mov   dx, di ; restore loop counters
add   sp, 8  ; undo those four pushes.
jmp   do_stop_channel_and_iter

update_sound_params:
mov   es, ax ; store volume
pop   ax
pop   dx
pop   bx
pop   cx
push  es
call  S_AdjustSoundParamsSep_

xchg  ax, cx
pop   dx
mov   al, byte ptr ds:[si + CHANNEL_T.channel_handle]
call  I_UpdateSoundParams_

mov   dx, di ; restore loop counters

iter_next_channel_updatesounds:
add   si, SIZEOF_CHANNEL_T
inc   dx
cmp   dl, dh
jl    loop_next_channel_updatesounds

exit_s_updatesounds:
POPA_NO_AX_OR_BP_MACRO
retf  

update_sound_with_mobjpos:
mov   bx, word ptr ds:[si + CHANNEL_T.channel_originRef]
mov   ax, SIZEOF_MOBJ_POS_T
mul   bx
xchg  ax, bx
mov   es, word ptr ds:[_MOBJPOSLIST_6800_SEGMENT_PTR]

;    originX = originMobjPos->x;
;    originY = originMobjPos->y;

mov   ax, word ptr es:[bx + MOBJ_POS_T.mp_x + 0]
mov   dx, word ptr es:[bx + MOBJ_POS_T.mp_x + 2]
les   bx, dword ptr es:[bx + MOBJ_POS_T.mp_y + 0]
mov   cx, es

jmp   origins_ready
ENDP

_sp_mus:			
db	MUS_E3M4	; American	e4m1
db	MUS_E3M2	; Romero	e4m2
db	MUS_E3M3	; Shawn	    e4m3
db	MUS_E1M5	; American	e4m4
db	MUS_E2M7	; Tim 	    e4m5
db	MUS_E2M4	; Romero	e4m6
db	MUS_E2M6	; J.Andersone4m7 CHIRON.WAD
db	MUS_E2M5	; Shawn	    e4m8
db	MUS_E1M9    ; Tim		e4m9


PROC    S_Start_ FAR
PUBLIC  S_Start_

push  dx
push  si

mov   si, OFFSET _channels
xor   dx, dx
mov   dh, byte ptr ds:[_numChannels]
test  dh, dh
je    exit_s_start

loop_next_channel_s_start:
mov   al, byte ptr ds:[si + CHANNEL_T.channel_sfx_id]
test  al, al
je    iter_next_channel_s_start
cbw
call  S_StopChannel_

iter_next_channel_s_start:
add   si, SIZEOF_CHANNEL_T
inc   dx
cmp   dl, dh
jl    loop_next_channel_s_start

xor   ax, ax
mov   byte ptr ds:[_mus_paused], al
mov   dh, byte ptr ds:[_gamemap]
cmp   byte ptr ds:[_commercial], al

jne   use_commercial_track
mov   dl, byte ptr ds:[_gameepisode]
cmp   dl, 4
jl    use_episode_under_4

; mnum = spmus[gamemap-1];
mov   al, dh
cbw
dec   ax
xchg  ax, si
mov   al, byte ptr cs:[_sp_mus + si]

jmp   do_changemusic_call

use_episode_under_4:

;	mnum = mus_e1m1 + (gameepisode-1)*9 + gamemap-1;

mov   al, 9
dec   dx    ; has gameepisode
mul   dl
add   al, dh
add   al, (MUS_E1M1 - 1)

jmp   do_changemusic_call
use_commercial_track:
;mnum = mus_runnin + gamemap - 1;
mov   al, (MUS_RUNNIN - 1)
add   al, dh


do_changemusic_call:
cbw
;  S_ChangeMusic(mnum, true);
mov   dx, 1
call  S_ChangeMusic_


exit_s_start:

pop   si
pop   dx

retf

ENDP


PROC    S_SOUND_ENDMARKER_ NEAR
PUBLIC  S_SOUND_ENDMARKER_
ENDP



END
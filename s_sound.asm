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
INCLUDE sound.inc
INSTRUCTION_SET_MACRO


EXTRN  FastDiv3216u_MapLocal_:NEAR
EXTRN R_PointToAngle2_MapLocal_:NEAR

.DATA


.CODE

PROC    S_SOUND_STARTMARKER_ NEAR
PUBLIC  S_SOUND_STARTMARKER_
ENDP

_channels:
PUBLIC _channels
;  channel_t	channels[MAX_SFX_CHANNELS];
dw 0, 0, 0
dw 0, 0, 0
dw 0, 0, 0
dw 0, 0, 0
dw 0, 0, 0
dw 0, 0, 0
dw 0, 0, 0
dw 0, 0, 0

_sfx_priority:

db  0, 64, 64, 64, 64, 64, 64, 64, 64, 64
db  64, 118, 64, 64, 64, 70, 70, 70, 100, 100
db  100, 100, 119, 78, 78, 96, 96, 96, 96, 96
db  96, 78, 78, 78, 96, 32, 98, 98, 98, 98 
db  98, 98, 98, 94, 92, 90, 90, 90, 90, 90
db  90, 70, 70, 70, 70, 70, 70, 32, 32, 70
db  70, 70, 70, 70, 70, 70, 70, 32, 32, 32 
db  32, 32, 32, 32, 32, 120, 120, 120, 100, 100
db  100, 78, 60, 64, 70, 70, 64, 60, 100, 100
db  100, 32, 32, 60, 70, 70, 70, 70, 70, 70
db  70, 70, 70, 70, 70, 70, 70, 70, 60

PLAYING_FLAG = 080h


COMMENT @

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

@



COMMENT @
PROC do_logger_ NEAR

pusha
mov  dx, cs
mov  bx, OFFSET _channels

xor   cx, cx
mov   cl, byte ptr cs:[si + _channels + CHANNEL_T.channel_handle] 

SHIFT_MACRO sal cx  3  
mov   si, cx

xor   ax, ax
mov   al, byte ptr ds:[_sb_voicelist + si + SB_VOICEINFO_T.sbvi_sfx_id]

; ax is 0
; cx is 0xBX -> 0x17?

call dword ptr ds:[_MainLogger_addr];
popa

ret
ENDP

@

PROC    S_StopChannel_ NEAR
PUBLIC  S_StopChannel_

; al has cnum
; si will have channels[cnum]

push  si
cbw  
mov   si, ax
sal   si, 1  ; 2
add   si, ax ; 3
sal   si, 1  ; 6

add   si, OFFSET _channels
cmp   byte ptr cs:[si + CHANNEL_T.channel_sfx_id], ah ; 0 or SFX_NONE  ; todo maybe not necessary? i think stopchannels is never called when this is 0...
mov   byte ptr cs:[si + CHANNEL_T.channel_sfx_id], ah ; 0 or SFX_NONE  ; zero this out. some loops check for it

je    exit_stop_channel
mov   al, byte ptr cs:[si + CHANNEL_T.channel_handle] 

;inlined stop channel...
; ah still 0
mov   si, ax
SHIFT_MACRO sal si  3    

test  byte ptr ds:[_sb_voicelist + si + SB_VOICEINFO_T.sbvi_sfx_id], PLAYING_FLAG
je    exit_stop_channel  ; wasnt playing

cmp   byte ptr ds:[_snd_SfxDevice], SND_SB
je    stop_sb_patch
cmp   byte ptr ds:[_snd_SfxDevice], SND_PC
jne   exit_stop_channel
mov   word ptr ds:[_pcspeaker_currentoffset], 0
pop   si
ret  



stop_sb_patch:

;call  SFX_StopPatch_ ; inlined only use
cli


call  dword ptr ds:[_S_DecreaseRefCountFar_addr]

mov   byte ptr ds:[_sb_voicelist + si + SB_VOICEINFO_T.sbvi_sfx_id], ah ; 0
sti


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

call  R_PointToAngle2_MapLocal_


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

; todo im not sure if this comes out correct.
; mul 96... 0x60
sar  cx, 1
rcr  bx, 1  ; bh has 0x80
sar  cx, 1
rcr  bx, 1  ; bh has 0x40
mov  ax, bx
sar  cx, 1
rcl  bx, 1  ; ah has 0x40 bh has 0x20
add  ax, bx

mov   al, 128
sub   al, ah

ret  


ENDP

; todo return carry?

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

ret   

skip_clip_dist_check:
cmp   dx, S_CLOSE_DIST_HIGH
jl    clip_max_vol

;	intermediate.w = S_CLIPPING_DIST - approx_dist.w;

neg   ax  ; set carry?
mov   ax, S_CLIPPING_DIST_HIGH
sbb   ax, dx
mov   bx, S_ATTENUATOR

; ax is intermediate highbits

cmp   byte ptr ds:[_gamemap], 8
jne   is_not_map_8
; gamemap 8 case
cmp   dx, S_CLIPPING_DIST_HIGH
jl    dont_clip_map_8_high
mov   ax, 15
ret

clip_max_vol:
mov   al, MAX_SOUND_VOLUME
ret

is_not_map_8:
mov   dx, MAX_SOUND_VOLUME
imul  dx
call  FastDiv3216u_MapLocal_

and   al, MAX_SOUND_VOLUME
ret
dont_clip_map_8_high:
mov   dx, (MAX_SOUND_VOLUME - 15)
imul  dx
call  FastDiv3216u_MapLocal_
add   al, 15
and   al, MAX_SOUND_VOLUME
ret

ENDP




; todo inline only use?

PROC    S_StopSound_ NEAR 
PUBLIC  S_StopSound_

;void __far S_StopSound(mobj_t __near* origin, int16_t soundorg_secnum) {

push  dx  ; push/pop dx allows the following function to piggyback.
push  bx
push  si

cmp   dx, SECNUM_NULL
je    check_for_mobjref
; check_for_secnum

xchg  ax, dx       ; loop condition soundorg_secnum
mov   bx, CHANNEL_T.channel_soundorg_secnum

jmp   setup_stopsound_channel_loop

check_for_mobjref:

xor   dx, dx
mov   si, (SIZE THINKER_T)
sub   ax, (_thinkerlist + THINKER_T.t_data)
div   si ; loop condition originRef


mov   bx, CHANNEL_T.channel_originRef

; si + bx is comparison target
; ax is what to compare to
; dl is i for StopChannel call.
; dh is end condition for loop.

setup_stopsound_channel_loop:
xor   dx, dx
mov   si, OFFSET _channels
mov   dh, byte ptr ds:[_numChannels]
;test  dh, dh
;je    exit_stopsound


loop_next_channel_stopsound:
cmp   byte ptr cs:[si + CHANNEL_T.channel_sfx_id], bh ; bh is zero for sure
je    iter_next_channel_stopsound
cmp   word ptr cs:[si + bx], ax
jne   iter_next_channel_stopsound
xchg  ax, dx
cbw   ; necessary?
call  S_StopChannel_
pop   si
pop   bx
pop   dx
ret  
iter_next_channel_stopsound:
add   si, SIZE CHANNEL_T
inc   dx
cmp   dl, dh
jl    loop_next_channel_stopsound
exit_stopsound:
pop   si
pop   bx
pop   dx
ret  

ENDP

PROC    S_StopSoundMobjRef_ NEAR
PUBLIC  S_StopSoundMobjRef_

push  dx
push  bx
push  si
; ax already ref
jmp   check_for_mobjref


ENDP



;int8_t __near S_getChannel (mobj_t __near* origin, int16_t soundorg_secnum, sfxenum_t sfx_id ) {

PROC    S_getChannel_ NEAR
PUBLIC  S_getChannel_

push  cx
push  si
push  di

xor   di, di
mov   cx, dx ; backup soundorg secnum..
xor   dx, dx
xor   bh, bh ; sfx_id is oft used as byte lookup.

test  ax, ax
jz    dont_get_ref

mov   di, SIZE THINKER_T
sub   ax, (_thinkerlist + THINKER_T.t_data)
div   di
xchg  ax, di  ; di has originref
xor   ax, ax

dont_get_ref:



cwd   ; ax zero already
mov   ah, byte ptr ds:[_numChannels]
mov   si, OFFSET _channels

; loop al to ah

loop_next_channel_getchannel:
cmp   word ptr cs:[si + CHANNEL_T.channel_sfx_id], dx ; 0
je    foundchannel
test  di, di
je    check_secnum_instead
cmp   word ptr cs:[si + CHANNEL_T.channel_originRef], di
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
mov   byte ptr cs:[si + CHANNEL_T.channel_sfx_id], bl
mov   word ptr cs:[si + CHANNEL_T.channel_originRef], di
mov   word ptr cs:[si + CHANNEL_T.channel_soundorg_secnum], cx

; ax has cnum already

exit_s_getchannel:
pop   di
pop   si
pop   cx
exit_startsoundwithpositionearly:
ret   
check_secnum_instead:
cmp   word ptr cs:[si + CHANNEL_T.channel_soundorg_secnum], cx
je    found_channel_to_boot
iter_next_channel_getchannel:
add   si, (SIZE CHANNEL_T)
inc   ax
cmp   al, ah
jl    loop_next_channel_getchannel

; NO CHANNEL FOUND. look for lower priority to boot
xor   al, al    ; reset counter
mov   si, OFFSET _channels
mov   dh, byte ptr cs:[bx + _sfx_priority]
; dh stores sfx priority..

loop_next_channel_getchannel_priority:
mov   dl, byte ptr cs:[si + CHANNEL_T.channel_sfx_id]
xchg  dl, bl  ; for _sfx_priority lookup
mov   bl, byte ptr cs:[bx + _sfx_priority] ; bh always 0. these numbers are low
xchg  dl, bl ; original bl back.

cmp   dl, dh
jge   found_channel_to_boot


iter_next_channel_getchannel_priority:
add   si, (SIZE CHANNEL_T)
inc   ax
cmp   al, ah
jl    loop_next_channel_getchannel_priority

mov   ax, -1 ; no channel found
jmp   exit_s_getchannel



ENDP



PROC    S_StartSoundWithPosition_ NEAR
PUBLIC  S_StartSoundWithPosition_

;void S_StartSoundWithPosition ( mobj_t __near* origin, sfxenum_t sfx_id, int16_t soundorg_secnum ) {


cmp   byte ptr ds:[_snd_SfxDevice], SND_NONE ; 0
je    exit_startsoundwithpositionearly

push  cx
push  si
push  di
push  bp
mov   bp, sp
xor   dh, dh
push  dx  ; sfx_id is [bp - 2]


;	// Check to see if it is audible,
;	//  and if not, modify the params
;	if ((origin || (soundorg_secnum != SECNUM_NULL)) && (originRef != playerMobjRef)){



cmp   bx, SECNUM_NULL
jne   location_good_adjust_sound_for_sector

mov   si, bx  ; si holds soundorg_secnum
mov   di, ax  ; di holds origin

mov   cx, MAX_SOUND_VOLUME ; just in case we skip and dont calculate vol.

test  di, di
je    skip_vol_adjustment_use_norm_setp

; div to get mobjref.

mov   bx, (SIZE THINKER_T)
sub   ax, (_thinkerlist + THINKER_T.t_data) ; ax still origin
xor   dx, dx
div   bx

; ax is mobjref/originref
cmp   ax, word ptr ds:[_playerMobjRef]
je    skip_vol_adjustment_use_norm_setp

location_good_adjust_sound_for_mobj:


xchg  bx, ax
mov   ax, (SIZE MOBJ_POS_T)
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

mov   ax, SECTORS_SOUNDORGS_SEGMENT
mov   es, ax
SHIFT_MACRO shl   bx 2
les   dx, dword ptr es:[bx + SECTOR_SOUNDORG_T.secso_soundorgX] ; x hibits
mov   cx, es                                                    ; y hibits
xor   ax, ax
mov   bx, ax

params_ready_for_sound_vol_adjust:

push  cx ; bp - 4
push  bx ; bp - 6
push  dx ; bp - 8
push  ax ; bp - 0Ah  ;store in reverse order for later cmpsw.

call  S_AdjustSoundParamsVol_  

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
; todo inline only use?
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


;call  SFX_PlayPatch_
call  dword ptr ds:[_SFX_PlayPatch_addr]

; todo inline only use?



done_with_i_sound:

cmp   al, -1
je    exit_startsoundwithposition
successful_play:
;    al is already handle!
sal   si, 1  ; x2
mov   bx, si ; x2
sal   si, 1  ; x2 + x4 = 6
mov   byte ptr cs:[bx + si + _channels + CHANNEL_T.channel_handle], al

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
mov   es, word ptr ds:[_PC_SPEAKER_OFFSETS_SEGMENT_PTR]

sal   bx, 1
cli
les   ax,  dword ptr es:[bx]
mov   word ptr ds:[_pcspeaker_currentoffset], ax
mov   word ptr ds:[_pcspeaker_endoffset], es
sti
jmp   successful_play  ; todo just exit maybe? handles not used for pc speaker?



ENDP

PROC    S_StartSoundFar_ FAR
PUBLIC  S_StartSoundFar_

call  S_StartSound_
retf

ENDP


PROC    S_StartSound_ NEAR
PUBLIC  S_StartSound_

test  dl, dl   ; todo skip this check? dont play sound zero but do we ever call with sound zero? put an i_error and catch?
je    exit_startsound_sfxid_0
push  bx
mov   bx, SECNUM_NULL
call  S_StartSoundWithPosition_
pop   bx
exit_startsound_sfxid_0:
ret  

ENDP

PROC    S_StartSoundWithSecnum_ NEAR
PUBLIC  S_StartSoundWithSecnum_

test  dl, dl
je    exit_startsound_sfxid_0
push  bx
xchg  ax, bx
xor   ax, ax
call  S_StartSoundWithPosition_
pop   bx
ret

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
xor   ax, ax
cmp   byte ptr cs:[si + CHANNEL_T.channel_sfx_id], al ; 0
je    iter_next_channel_updatesounds
mov   al, byte ptr cs:[si + CHANNEL_T.channel_handle]
mov   bx, ax
SHIFT_MACRO shl bx 3
test  byte ptr ds:[_sb_voicelist + bx + SB_VOICEINFO_T.sbvi_sfx_id], PLAYING_FLAG
jne   handle_position_update

; the interrupt will turn off the playing flag, but will not clean up channel info, so we do it here.
mov   byte ptr cs:[si + CHANNEL_T.channel_sfx_id], ah ; 0   


iter_next_channel_updatesounds:
add   si, (SIZE CHANNEL_T)
inc   dx
cmp   dl, dh
jl    loop_next_channel_updatesounds

exit_s_updatesounds:
POPA_NO_AX_OR_BP_MACRO
retf  


handle_position_update:

les   bx, dword ptr cs:[si + CHANNEL_T.channel_soundorg_secnum]
mov   ax, es ; es was originref
cmp   ax, word ptr ds:[_playerMobjRef]
je    iter_next_channel_updatesounds   ; dont adjust vol for player (listener) source sounds. theyre always full vol


mov   di, dx ; back this up...
cmp   bx, SECNUM_NULL
jne   update_sound_with_sector

update_sound_with_mobjpos:
; ax is originref
test  ax, ax
jz    iter_next_channel_updatesounds   ; null source.
mov   bx, (SIZE MOBJ_POS_T)
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




update_sound_with_sector:
mov   ax, SECTORS_SOUNDORGS_SEGMENT ; todo ptr
mov   es, ax
SHIFT_MACRO shl   bx 2
les   dx, dword ptr es:[bx + SECTOR_SOUNDORG_T.secso_soundorgX] ; x hibits
mov   cx, es                                                    ; y hibits
xor   ax, ax
mov   bx, ax

origins_ready:

push  cx ; bp - 4
push  bx ; bp - 6
push  dx ; bp - 8
push  ax ; bp - 0Ah  ;store in reverse order for later cmpsw.

call  S_AdjustSoundParamsVol_

test  al, al
je    vol_zero_end_sound


mov   es, ax ; store volume
pop   ax
pop   dx
pop   bx
pop   cx
push  es   ; push vol
call  S_AdjustSoundParamsSep_

pop   bx  ; vol into bl
mov   bh, al ; bx gets vol lo sep  hi

mov   al, byte ptr cs:[si + CHANNEL_T.channel_handle]  ; known to be playing; tested above
cbw
;call  SFX_SetOrigin_ ; inlined

;cbw
SHIFT_MACRO shl ax 3

xchg    ax, bx
mov     word ptr ds:[_sb_voicelist + bx + SB_VOICEINFO_T.sbvi_volume], ax  ; volume and sep


mov   dx, di ; restore loop counters
jmp   iter_next_channel_updatesounds
vol_zero_end_sound:
mov   dx, di ; restore loop counters
add   sp, 8  ; undo those four pushes.
mov   al, dl ; restore channel
cbw

;call  S_StopChannel_
jmp   iter_next_channel_updatesounds


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
mov   al, byte ptr cs:[si + CHANNEL_T.channel_sfx_id]
test  al, al
je    iter_next_channel_s_start
cbw
call  S_StopChannel_

iter_next_channel_s_start:
add   si, (SIZE CHANNEL_T)
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
;call  S_ChangeMusic_
mov   ah, 1  ; looping
mov   word ptr ds:[_pendingmusicenum], ax
;mov   byte ptr ds:[_pendingmusicenumlooping], dl


exit_s_start:

pop   si
pop   dx

retf

ENDP



; copy string from cs:ax to ds:_filename_argument
; return _filename_argument in ax
; TODO make this near to everything eventually to not dupe..
PROC CopyString13_physics_seg_ NEAR
PUBLIC CopyString13_physics_seg_

push  si
push  di
push  cx

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
stosw
stosw
stosb

mov  cx, 13
sub  di, cx

do_next_char:
lodsb
stosb
test  al, al
je    done_writing
loop do_next_char


done_writing:

mov   ax, OFFSET _filename_argument   ; ax now points to the near string

push  ss
pop   ds    ; restore ds

pop   cx
pop   di
pop   si

ret

ENDP


PROC    S_SOUND_ENDMARKER_ NEAR
PUBLIC  S_SOUND_ENDMARKER_
ENDP



END
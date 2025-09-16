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




EXTRN P_FindHighestOrLowestFloorSurrounding_:NEAR
EXTRN P_FindMinSurroundingLight_:NEAR
EXTRN P_FindSectorsFromLineTag_:NEAR
EXTRN P_FindNextHighestFloor_:NEAR
EXTRN P_CreateThinker_:NEAR
EXTRN T_MovePlaneFloorUp_:NEAR
EXTRN T_MovePlaneFloorDown_:NEAR

EXTRN P_UpdateThinkerFunc_:NEAR
EXTRN P_Random_:NEAR


.DATA


.CODE



PROC    P_LIGHTS_STARTMARKER_ NEAR
PUBLIC  P_LIGHTS_STARTMARKER_
ENDP


PROC    T_FireFlicker_ NEAR
PUBLIC  T_FireFlicker_ 



push  bx

xchg  ax, bx
dec   word ptr ds:[bx + FIREFLICKER_T.fireflicker_count]
jnz   exit_t_fireflicker_early
call  P_Random_
and   al, 3
SHIFT_MACRO sal ax 4
mov   word ptr ds:[bx + FIREFLICKER_T.fireflicker_count], 4
mov   es, word ptr ds:[_SECTORS_SEGMENT_PTR]
mov   dx, word ptr ds:[bx + FIREFLICKER_T.fireflicker_secnum]
SHIFT_MACRO sal dx 4
mov   ah, byte ptr ds:[bx + FIREFLICKER_T.fireflicker_maxlight]
mov   bl, byte ptr ds:[bx + FIREFLICKER_T.fireflicker_minlight]
xchg  dx, bx

;	if (sectors[flicksecnum].lightlevel - amount < flickminlight)
;		sectors[flicksecnum].lightlevel = flickminlight;
;	else
;		sectors[flicksecnum].lightlevel = flickmaxlight - amount;

mov   dh, byte ptr es:[bx + SECTOR_T.sec_lightlevel]

; al = amount
; ah = maxlight
; dl = minlight
; dh = lightlevel

sub   dh, al
cmp   dh, dl
jnl   set_max_minus_amount
mov   ah, dl
jmp   set_lightlevel_and_exit
set_max_minus_amount:
sub   ah, al


set_lightlevel_and_exit:
mov   byte ptr es:[bx + SECTOR_T.sec_lightlevel], ah
exit_t_fireflicker_early:
pop   bx
ret   

ENDP

; i believe dx is ok to wreck.
PROC    P_SpawnFireFlicker_ NEAR
PUBLIC  P_SpawnFireFlicker_

push  bx

mov   bx, ax
SHIFT_MACRO  shl bx 4
xchg  ax, dx
mov   es, word ptr ds:[_SECTORS_SEGMENT_PTR]
mov   byte ptr ds:[bx + _sectors_physics + SECTOR_PHYSICS_T.secp_special], 0
mov   bl, byte ptr es:[bx + SECTOR_T.sec_lightlevel]
; dx has secnum
; bl has lightlevel
mov   ax, TF_FIREFLICKER_HIGHBITS
call  P_CreateThinker_

xchg  ax, bx

;    flick->secnum = secnum;
;    flick->maxlight = seclightlevel;
;	 flick->minlight = P_FindMinSurroundingLight(secnum, seclightlevel) + 16;
;    flick->count = 4;



mov   byte ptr ds:[bx + FIREFLICKER_T.fireflicker_maxlight], al ; seclightlevel
xchg  ax, dx
mov   word ptr ds:[bx + FIREFLICKER_T.fireflicker_secnum], ax ; secnum
mov   word ptr ds:[bx + FIREFLICKER_T.fireflicker_count], 4

call  P_FindMinSurroundingLight_

add   al, 16
mov   byte ptr ds:[bx + FIREFLICKER_T.fireflicker_minlight], al

pop   bx
ret   


ENDP

PROC    T_LightFlash_ NEAR
PUBLIC  T_LightFlash_
push  bx

xchg  ax, bx
dec   word ptr ds:[bx + LIGHTFLASH_T.lightflash_count]
jnz   exit_t_lightflash_early
call  P_Random_

mov   es, word ptr ds:[_SECTORS_SEGMENT_PTR]
mov   dx, word ptr ds:[bx + LIGHTFLASH_T.lightflash_secnum]
SHIFT_MACRO sal dx 4
push  bx ; same lightflash...
mov   ah, byte ptr ds:[bx + LIGHTFLASH_T.lightflash_maxlight]
mov   bl, byte ptr ds:[bx + LIGHTFLASH_T.lightflash_minlight]
xchg  dx, bx
mov   dh, byte ptr es:[bx + SECTOR_T.sec_lightlevel]

; ah = maxlight
; al = random
; dl = minlight
; dh = lightlevel

cmp   dh, ah
jne   lights_not_equal
mov   byte ptr es:[bx + SECTOR_T.sec_lightlevel], dl
pop   bx
and   al, ds:[bx + LIGHTFLASH_T.lightflash_mintime]
jmp   set_count_and_exit

lights_not_equal:
mov   byte ptr es:[bx + SECTOR_T.sec_lightlevel], ah
pop   bx
and   al, ds:[bx + LIGHTFLASH_T.lightflash_maxtime]
set_count_and_exit:

inc   ax
mov   byte ptr ds:[bx + LIGHTFLASH_T.lightflash_count], al

exit_t_lightflash_early:
pop   bx
ret   
ENDP


; i believe dx is ok to wreck..
PROC    P_SpawnLightFlash_ NEAR
PUBLIC  P_SpawnLightFlash_


push  bx

mov   bx, ax
SHIFT_MACRO  shl bx 4
xchg  ax, dx
mov   es, word ptr ds:[_SECTORS_SEGMENT_PTR]
mov   byte ptr ds:[bx + _sectors_physics + SECTOR_PHYSICS_T.secp_special], 0
mov   bl, byte ptr es:[bx + SECTOR_T.sec_lightlevel]
; dx has secnum
; bl has lightlevel
mov   ax, TF_LIGHTFLASH_HIGHBITS
call  P_CreateThinker_

xchg  ax, bx

mov   byte ptr ds:[bx + LIGHTFLASH_T.lightflash_maxlight], al ; seclightlevel
xchg  ax, dx
mov   word ptr ds:[bx + LIGHTFLASH_T.lightflash_secnum], ax ; secnum
call  P_FindMinSurroundingLight_
mov   byte ptr ds:[bx + LIGHTFLASH_T.lightflash_minlight], al ; seclightlevel

call  P_Random_
and   al, 64
inc   ax
mov   word ptr ds:[bx + LIGHTFLASH_T.lightflash_count], ax
mov   word ptr ds:[bx + LIGHTFLASH_T.lightflash_maxtime], 0740h ; 7 to mintime. 64 to maxtime.

pop   bx
ret   

ENDP


PROC    T_StrobeFlash_ NEAR
PUBLIC  T_StrobeFlash_



push  bx

xchg  ax, bx
dec   word ptr ds:[bx + STROBE_T.strobe_count]
jnz   exit_t_strobeflash_early

mov   dx, word ptr ds:[bx + STROBE_T.strobe_secnum]
SHIFT_MACRO shl dx 4

mov   ax, word ptr ds:[bx + STROBE_T.strobe_minlight]
; minlight al
; maxlight ah
xchg  bx, dx
mov   es, word ptr ds:[_SECTORS_SEGMENT_PTR]

cmp   al, byte ptr es:[bx + SECTOR_T.sec_lightlevel]
jne   strobe_not_equal_to_minlight
mov   byte ptr es:[bx + SECTOR_T.sec_lightlevel], ah
mov   bx, dx
push  word ptr ds:[bx + STROBE_T.strobe_brighttime]
jmp   set_count_and_exit_strobe

strobe_not_equal_to_minlight:
mov   byte ptr es:[bx + SECTOR_T.sec_lightlevel], al
mov   bx, dx
push  word ptr ds:[bx + STROBE_T.strobe_darktime]
set_count_and_exit_strobe:
pop   word ptr ds:[bx + STROBE_T.strobe_count]

exit_t_strobeflash_early:
pop   bx
ret   

ENDP

;void __near P_SpawnStrobeFlash( int16_t secnum,int16_t		fastOrSlow,int16_t		inSync ){


; i believe dx is ok to wreck..
PROC    P_SpawnStrobeFlash_ NEAR
PUBLIC  P_SpawnStrobeFlash_

push    si
xchg    ax, si


mov   ax, TF_STROBEFLASH_HIGHBITS
call  P_CreateThinker_

xchg  ax, bx

; ax has inSync
; bx has strobe ptr
; si has secnum
; dx has fastorslow


mov   word ptr ds:[bx + STROBE_T.strobe_darktime], dx   ; dx free.
mov   word ptr ds:[bx + STROBE_T.strobe_brighttime], STROBEBRIGHT

test  ax, ax
jne   in_sync
call  P_Random_
and   al, 7
jmp   done_with_sync
in_sync:
xor   ax, ax
done_with_sync:
inc   ax
mov   word ptr ds:[bx + STROBE_T.strobe_count], ax

mov   ax, si ; secnum
mov   word ptr ds:[bx + STROBE_T.strobe_secnum], ax
SHIFT_MACRO   sal si 4
mov   es, word ptr ds:[_SECTORS_SEGMENT_PTR]

mov   byte ptr ds:[si + _sectors_physics + SECTOR_PHYSICS_T.secp_special], 0
mov   dl, byte ptr es:[si + SECTOR_T.sec_lightlevel]
mov   byte ptr ds:[bx + STROBE_T.strobe_maxlight], dl

call  P_FindMinSurroundingLight_
cmp   al, byte ptr ds:[bx + STROBE_T.strobe_maxlight]
jne   just_set_minlight
xor   ax, ax
just_set_minlight:
mov   byte ptr ds:[bx + STROBE_T.strobe_minlight], al

pop   si
ret   

ENDP


PROC    EV_StartLightStrobing_ NEAR
PUBLIC  EV_StartLightStrobing_

push  bx
push  dx
push  si
push  bp
mov   bp, sp
sub   sp, 0200h
lea   dx, [bp - 0200h]
mov   si, dx
xor   bx, bx
call  P_CreateThinker_

cmp   word ptr ds:[si], 0
jl    exit_evstartlightstrobing

loop_next_secnum_lightstrobe:
lodsw
mov   dx, SLOWDARK
xor   bx, bx

call  P_SpawnStrobeFlash_
cmp   word ptr ds:[si], 0
jge   loop_next_secnum_lightstrobe
exit_evstartlightstrobing:

LEAVE_MACRO 
pop   si
pop   dx
pop   bx
ret   

ENDP

;void __near EV_LightChange(uint8_t linetag, int8_t on, uint8_t		bright) {

PROC    EV_LightChange_ NEAR
PUBLIC  EV_LightChange_

push  cx
push  si
push  di
push  bp
mov   bp, sp

mov   dh, bl
mov   word ptr cs:[SELFMODIFY_set_on_bright+1], dx 
test  dl, dl
mov   dl, 073h   ; jnb opcode. jna = 076h if it was 1
je    use_off_smc
mov   dl, 076h   ; jna opcode
use_off_smc:
mov   byte ptr cs:[SELFMODIFY_set_on_off_branch], dl

sub   sp, 0206h
mov   ch, dl
mov   cl, bl
mov   bx, 1
lea   dx, [bp - 0206h]
mov   si, dx


call  P_FindSectorsFromLineTag_

cmp   word ptr ds:[si], 0
jnge  exit_ev_lightchange

loop_next_secnm_lightchange:
lodsw
push  si
mov   es, word ptr ds:[_SECTORS_SEGMENT_PTR]


mov   di, ax
SHIFT_MACRO shl di 4
; di holds sector offset

SELFMODIFY_set_on_bright:
mov   dx, 01000h

test  dl, dl
je    use_off
mov   cl, dh  ; bright
jmp   got_light
use_off:
mov   cl, byte ptr es:[di + SECTOR_T.sec_lightlevel]
got_light:

; could selfmodify this into a single jmp or nop from the outside if we had to make these loops smaller.
test  dl, dl
jne   find_surrounding_light
test  dh, dh
je    skip_finding_surrounding_light


find_surrounding_light:

; find lights to modify... iterate over linecount
mov   si, word ptr es:[di + SECTOR_T.sec_linesoffset]
mov   di, word ptr es:[di + SECTOR_T.sec_linecount]

sal   si, 1
add   si, _linebuffer

sal   di, 1
add   di, si

mov   bx, di ; set end case in bx?
xchg  ax, dx ; dx gets unshifted secnum 

; if off case, use min
; if on case, use bright


; cl is comparator over the sector.

loop_next_secnum_find_surrounding_light:
lodsw
mov   es, word ptr ds:[_LINES_PHYSICS_SEGMENT_PTR]
SHIFT_MACRO shl ax 4
xchg  ax, di
; ax has old sector offset. di has line ptr...

cmp   dx, word ptr es:[di + LINE_PHYSICS_T.lp_frontsecnum]
je    use_front
mov   di, word ptr es:[di + LINE_PHYSICS_T.lp_backsecnum]
jmp   got_sec_ptr
use_front:
mov   di, word ptr es:[di + LINE_PHYSICS_T.lp_frontsecnum]
got_sec_ptr:
SHIFT_MACRO shl di 4
mov   es, word ptr ds:[_SECTORS_SEGMENT_PTR]

mov   ch, byte ptr es:[di + SECTOR_T.sec_lightlevel]
xchg  ax, di ; restore di's sector offset

cmp   ch, cl
; ON case
;if (sectors[offset].lightlevel > bright){
; OFF case
;if (sectors[offset].lightlevel < min) {
; on: jna. 0x76   off: jnb  0x73

SELFMODIFY_set_on_off_branch:
jna  done_updating_this_sector_light
mov  cl, ch
done_updating_this_sector_light:


cmp   si, bx
jl    loop_next_secnum_find_surrounding_light

skip_finding_surrounding_light:

mov   byte ptr es:[di + SECTOR_T.sec_lightlevel], cl   ; cl holds bright/min

pop   si
cmp   word ptr ds:[si], 0
jge   loop_next_secnm_lightchange


exit_ev_lightchange:
LEAVE_MACRO 
pop   di
pop   si
pop   cx
ret   



ENDP


PROC    T_Glow_ NEAR
PUBLIC  T_Glow_

push  bx

xchg  ax, bx

mov   ax, word ptr ds:[bx + GLOW_T.glow_secnum]
SHIFT_MACRO shl   ax 4
;mov   dl, byte ptr ds:[bx + GLOW_T.glow_minlight]
;mov   dh, byte ptr ds:[bx + GLOW_T.glow_maxlight]
mov   dx, word ptr ds:[bx + GLOW_T.glow_minlight]
mov   es, word ptr ds:[_SECTORS_SEGMENT_PTR]
cmp   word ptr ds:[bx + GLOW_T.glow_direction], 0
xchg  ax, bx

; dl minlight
; dh maxlight
; bx sector ptr
; bx thing ptr

; todo test add -8 to dh and 8 to dl in same word add? fine with no overflows..

jg    do_glow_1_case
do_glow_minus_1_case:
add   dl, GLOWSPEED
cmp   dl, byte ptr es:[bx + SECTOR_T.sec_lightlevel]
jae   do_change_glow_dir
sub   byte ptr es:[bx + SECTOR_T.sec_lightlevel], GLOWSPEED
pop   bx
ret


do_glow_1_case:
sub   dh, GLOWSPEED
cmp   dh, byte ptr es:[bx + SECTOR_T.sec_lightlevel]
jbe   do_change_glow_dir
add   byte ptr es:[bx + SECTOR_T.sec_lightlevel], GLOWSPEED
pop   bx
ret


do_change_glow_dir:
xchg  ax, bx
neg   word ptr ds:[bx + GLOW_T.glow_direction]
exit_t_glow:
pop   bx
ret

ENDP


; i believe dx is ok to wreck..
PROC    P_SpawnGlowingLight_ NEAR
PUBLIC  P_SpawnGlowingLight_

push  bx
mov   bx, ax
SHIFT_MACRO  shl bx 4
xchg  ax, dx ; preserve secnum in dx.
mov   es, word ptr ds:[_SECTORS_SEGMENT_PTR]
mov   byte ptr ds:[bx + _sectors_physics + SECTOR_PHYSICS_T.secp_special], 0
mov   bl, byte ptr es:[bx + SECTOR_T.sec_lightlevel]  ; bl gets lightlevel.
; dx has secnum
; bl has lightlevel
mov   ax, TF_GLOW_HIGHBITS
call  P_CreateThinker_

xchg  ax, bx
; al has lightlevel, bx has thing ptr
mov   byte ptr ds:[bx + GLOW_T.glow_maxlight], al
xchg  ax, dx ; secnum ax, seclightlevel dl
mov   word ptr ds:[bx + GLOW_T.glow_secnum], ax 

call  P_FindMinSurroundingLight_
mov   byte ptr ds:[bx + GLOW_T.glow_minlight], al
mov   word ptr ds:[bx + GLOW_T.glow_direction], -1
pop   bx
ret   

ENDP


PROC    P_LIGHTS_ENDMARKER_ NEAR
PUBLIC  P_LIGHTS_ENDMARKER_
ENDP

END

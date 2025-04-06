;
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

;=================================
.DATA




.CODE


PROC  S_INIT_STARTMARKER_
PUBLIC  S_INIT_STARTMARKER_
ENDP


_currentnameprefix:
db 'd', 'p'

_songnamelist:
 db "123456" ; filler for sfx 0
 db "pistol"
 db "shotgn"
 db "sgcock"
 db "dshtgn"
 db "dbopn" , 0
 db "dbcls" , 0
 db "dbload"
 db "plasma"
 db "bfg"   , 0, 0, 0
 db "sawup" , 0
 db "sawidl"
 db "sawful"
 db "sawhit"
 db "rlaunc"
 db "rxplod"
 db "firsht"
 db "firxpl"
 db "pstart"
 db "pstop" , 0
 db "doropn"
 db "dorcls"
 db "stnmov"
 db "swtchn"
 db "swtchx"
 db "plpain"
 db "dmpain"
 db "popain"
 db "vipain"
 db "mnpain"
 db "pepain"
 db "slop"  , 0, 0
 db "itemup"
 db "wpnup" , 0
 db "oof"   , 0, 0, 0
 db "telept"
 db "posit1"
 db "posit2"
 db "posit3"
 db "bgsit1"
 db "bgsit2"
 db "sgtsit"
 db "cacsit"
 db "brssit"
 db "cybsit"
 db "spisit"
 db "bspsit"
 db "kntsit"
 db "vilsit"
 db "mansit"
 db "pesit" , 0
 db "sklatk"
 db "sgtatk"
 db "skepch"
 db "vilatk"
 db "claw"  , 0, 0
 db "skeswg"
 db "pldeth"
 db "pdiehi"
 db "podth1"
 db "podth2"
 db "podth3"
 db "bgdth1"
 db "bgdth2"
 db "sgtdth"
 db "cacdth"
 db "skldth"
 db "brsdth"
 db "cybdth"
 db "spidth"
 db "bspdth"
 db "vildth"
 db "kntdth"
 db "pedth" , 0
 db "skedth"
 db "posact"
 db "bgact" , 0
 db "dmact" , 0
 db "bspact"
 db "bspwlk"
 db "vilact"
 db "noway" , 0
 db "barexp"
 db "punch" , 0
 db "hoof"  , 0, 0
 db "metal" , 0
 db "chgun" , 0
 db "tink"  , 0, 0
 db "bdopn" , 0
 db "bdcls" , 0
 db "itmbk" , 0
 db "flame" , 0
 db "flamst"
 db "getpow"
 db "bospit"
 db "boscub"
 db "bossit"
 db "bospn" , 0
 db "bosdth"
 db "manatk"
 db "mandth"
 db "sssit" , 0
 db "ssdth" , 0
 db "keenpn"
 db "keendt"
 db "skeact"
 db "skesit"
 db "skeatk"
 db "radio" , 0



;int16_t I_GetSfxLumpNum(sfxenum_t sfx_id) {
;	int8_t namebuf[9];
;    int8_t part1[3];
;    if (sfx_id == sfx_chgun) {
;        sfx_id = sfx_pistol; 
;    }
;    part1[0] = 'd';
;    part1[1] = snd_prefixen[snd_SfxDevice];
;    part1[2] = '\0';
;
;    combine_strings(namebuf, part1, S_sfx[sfx_id].name);
;    return W_GetNumForName(namebuf);
;}

; set char 2 for the lump name

PROC   I_SetSFXPrefix_
PUBLIC I_SetSFXPrefix_

    mov byte ptr cs:[_currentnameprefix + 1], al
    ret

ENDP


PROC   I_GetSfxLumpNum_
PUBLIC I_GetSfxLumpNum_

    push si
    push di

    cmp al, SFX_CHGUN
    jne not_chaingun
    mov al, SFX_PISTOL   ; linked sfx
    not_chaingun:


    push ds
    pop  es
    push cs
    pop  ds
    mov si, OFFSET _currentnameprefix
    mov di, _filename_argument

    ; copy 'd' and prefix
    movsw

    ; si already equal to _songnamelist after movsw
    cbw
    sal  ax, 1
    add  si, ax ; x2
    add  si, ax ; x4
    add  si, ax ; x6

    ; copy six characters
    movsw
    movsw
    movsw
    

    ; restore ds
    push ss
    pop  ds

    mov ax, _filename_argument

    db 0FFh  ; lcall[addr]
    db 01Eh  ;
    dw _W_GetNumForName_addr


    ; call W_GetNumForName

    pop  di
    pop  si

    ret

ENDP


PROC  LoadSFXWadLumps_

ENDP



PROC  S_INIT_ENDMARKER_
PUBLIC  S_INIT_ENDMARKER_

ENDP


END
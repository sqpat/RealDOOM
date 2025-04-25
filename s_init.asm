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

PC_SPEAKER_SFX_DATA_TEMP_SEGMENT = 0D7E0h

.CODE


PROC  S_INIT_STARTMARKER_
PUBLIC  S_INIT_STARTMARKER_
ENDP

; todo rewrite with offsets instead of segments

SINGULARITY_FLAG_HIGH =  (SOUND_SINGULARITY_FLAG SHR 8)

PROC   LoadSFXWadLumps_
PUBLIC LoadSFXWadLumps_

    push bx
    push cx
    push si
    push di


    ; set char 2 for the lump name
    mov  al, byte ptr ds:[_snd_SfxDevice]
    cbw
    xchg ax, bx

    mov al, byte ptr cs:[_snd_prefixen + bx - OFFSET S_INIT_STARTMARKER_]
    mov byte ptr cs:[_currentnameprefix + 1 - OFFSET S_INIT_STARTMARKER_], al


    cmp byte ptr ds:[_snd_SfxDevice], SND_PC
    jne not_pc_speaker

    ; pc speaker load loop

    ; DI is index
    ; CX:BX is target address

    mov  di, 1

    mov  bx, PC_SPEAKER_OFFSETS_SEGMENT
    mov  es, bx

    mov  bx, 2   ;lets start at offset 2


    mov  word ptr es:[0], bx   ; fixed first value

    loop_load_pc_sfx:


    push es ; store PC_SPEAKER_OFFSETS_SEGMENT

    mov  ax, di
    call I_GetSfxLumpNum_
    mov  si, ax  ; backup lump num
    
    db 0FFh  ; lcall[addr]
    db 01Eh  ;
    dw _W_LumpLength_addr

    ; ax is lumpsize

    xchg ax, si    ; ax gets lumpnum again. size to si.
    mov  cx, PC_SPEAKER_SFX_DATA_TEMP_SEGMENT   ; load the data into a temp spot...
    push cx ; store this
    push bx ; store current pointer
    xor  bx, bx ; load into offset 0
    db 0FFh  ; lcall[addr]
    db 01Eh  ;
    dw _W_CacheLumpNumDirect_addr
    pop  bx
    pop  ds   ; ds gets PC_SPEAKER_SFX_DATA_TEMP_SEGMENT
    
    mov  ax, PC_SPEAKER_SFX_DATA_SEGMENT
    mov  es, ax

    ; si has size

    push di   ; back this up
    mov  di, bx

    lea  cx, [si - 4]   ; cx gets length - 4 (skip first 4 bytes)
    mov  si, 4    ; skip first 4 bytes...

    prep_next_sample:
        xor  ax, ax   ; zero ah
        lodsb         ; get sample
        mov  bx, ax
        sal  bx, 1
        mov  ax, cs:[bx + OFFSET _pc_speaker_freq_table - OFFSET S_INIT_STARTMARKER_]
        stosw
        loop prep_next_sample

    push ss
    pop  ds

    mov  bx, di  ; bx restored. has been incremented meanwhile...
    xchg ax, di  ; grab this into ax
    pop  di      ; di restored


    pop  es  ; PC_SPEAKER_OFFSETS_SEGMENT

    ; store ptr
    sal  di, 1
    stosw
    sar  di, 1


    cmp  di, NUMSFX
    jne  loop_load_pc_sfx

    jmp  done_with_sfx_prep

    not_pc_speaker:

    cmp byte ptr ds:[_snd_SfxDevice], SND_SB
    jne not_soundblaster
    ; todo any others? to check?

    ; setup page

    call dword ptr ds:[_Z_QuickMapScratch_5000_addr]

    ; load sb sfx data here
    ; sb sfx load loop
    ; DI is index
    ; CX:BX is target address

    mov  di, SFX_DATA_SEGMENT
    mov  es, di

    mov  di, SIZEOF_SFX_INFO    ; skip first element.

    loop_load_sb_sfx:


    push es ; store SFX_DATA_SEGMENT
    mov  word ptr es:[di+4], 0FFFFh   ; store default value for cache pos...

    mov  ax, di
    ; gross but its init code so who cares if its slow
    mov  bl, 6 
    div  bl
    call I_GetSfxLumpNum_

    pop  es
    mov  si, ax  ; backup lump num

    mov  word ptr es:[di+0], ax      ; store lump data  in sfx_data
    

    cmp  ax, 0FFFFh
    je   bad_lump_skip

    ; apply singularity...
    mov  bl, byte ptr cs:[_singularity_list + di];
    or   byte ptr es:[di+1], bl      ; or the singularity flag onto the field

    push es

    
    db 0FFh  ; lcall[addr]
    db 01Eh  ;
    dw _W_LumpLength_addr

    ; ax is lumpsize

    sub  ax, 32     ; remove padding, header, etc from lump
    pop  es
    push es
    mov  word ptr es:[di+2], ax      ; store lump_size in sfx_data


    xchg ax, si    ; ax gets lumpnum again. size to si.
    mov  cx, SCRATCH_SEGMENT_5000   ; load the data into a temp spot...
    push cx ; store this
    xor  bx, bx ; load into offset 0
    db 0FFh  ; lcall[addr]
    db 01Eh  ;
    dw _W_CacheLumpNumDirect_addr   ; todo only load 4 bytes?

    pop  ds   ; ds gets 0x5000
    pop  es   ; SFX_DATA_SEGMENT
    
    mov  ax,  word ptr ds:[2]       ; get sample rate
    cmp  ax,  SAMPLE_RATE_22_KHZ_UINT
    je   write_22_khz_sample_bit
    and   byte ptr es:[di + 1], (NOT_SOUND_22_KHZ_FLAG SHR 8)
    jmp  done_with_sample_bit
    write_22_khz_sample_bit:
    or   byte ptr es:[di + 1], (SOUND_22_KHZ_FLAG SHR 8)

    done_with_sample_bit:

    push ss
    pop  ds

    bad_lump_skip:



    add  di, SIZEOF_SFX_INFO

    cmp  di, (NUMSFX * SIZEOF_SFX_INFO)
    jne  loop_load_sb_sfx

    ; restore 
    call      dword ptr ds:[_Z_QuickMapPhysics_addr]

    ; setup cache fields..
    mov       cx, NUM_SFX_PAGES
    mov       al, 040h     ; 64
    mov       di, OFFSET _sfx_free_bytes
    push      ds
    pop       es
    rep stosb


    jmp  done_with_sfx_prep


    not_soundblaster:
    done_with_sfx_prep:
    pop  di
    pop  si
    pop  cx
    pop  bx

    retf

ENDP

COMMENT @

push      bx
push      cx
push      dx
push      si
push      di
push      bp
mov       bp, sp
sub       sp, 0Eh
call      dword ptr [_Z_QuickMapScratch_5000_addr]
mov       word ptr [bp - 4], SCRATCH_SEGMENT_5000
mov       byte ptr [bp - 2], 1
xor       di, di
cld       

; sfx load loop
; DI is index
; CX:BX is target address
mov  di, 1
mov  bx, SFX_DATA_SEGMENT
mov  es, bx
mov  bx, 2   ;lets start at offset 2
mov  word ptr es:[0], bx   ; fixed first value

start_loading_next_sfx:


    push es ; store SFX_DATA_SEGMENT

    mov  ax, di
    call I_GetSfxLumpNum_
    mov  si, ax  ; backup lump num
    
    db 0FFh  ; lcall[addr]
    db 01Eh  ;
    dw _W_LumpLength_addr

    ; ax is lumpsize
    xchg ax, si    ; ax gets lumpnum again. size to si.




mov       dl, byte ptr [bp - 2]
xor       dh, dh
imul      si, dx, 6
lea       ax, [bp - 0Eh]
call      dword ptr [_W_GetNumForName_addr]
and       ah, (SOUND_LUMP_BITMASK SHR 8)
mov       word ptr [si + 0xd32], ax
and       ah, (SOUND_LUMP_BITMASK SHR 8)
call      dword ptr [_W_LumpLength_addr]
sub       ax, 32
mov       word ptr [si + 0xd34], ax
mov       ax, word ptr [si + 0xd32]
mov       word ptr [si + 0xd36], 0FFFFh
cmp       ax, 0FFFFh
jne       label_1
increment_sb_sfx_loop:
inc       byte ptr [bp - 2]
cmp       byte ptr [bp - 2], 0x6d
jb        start_loading_next_sfx
; done loading..
call      dword ptr [_Z_QuickMapPhysics_addr]


;    // initialize SFX cache.
;    memset(sfx_free_bytes, 64, NUM_SFX_PAGES); 

mov       cx, NUM_SFX_PAGES / 2
mov       ax, 04040h     ; 64
mov       di, OFFSET _sfx_free_bytes
push      ds
pop       es
rep stosw 
adc       cx, cx
rep stosb 

LEAVE_MACRO
pop       di
pop       si
pop       dx
pop       cx
pop       bx
retf      
label_1:
mov       cx, SCRATCH_SEGMENT_5000
and       ah, (SOUND_LUMP_BITMASK SHR 8)
xor       bx, bx
call      dword ptr [_W_CacheLumpNumDirect_addr]
mov       es, word ptr [bp - 4]
cmp       word ptr es:[di + 2], 0x5622
jne       increment_sb_sfx_loop
or        byte ptr [si + 0xd33], 0x40
jmp       increment_sb_sfx_loop

@


_currentnameprefix:
db 'd', 'p'

_sfxlist:
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


_snd_prefixen:
db 'P', 'P', 'A', 'S', 'S', 'S', 'M', 'M', 'M', 'S', 'S', 'S'

_pc_speaker_freq_table:

dw	   0, 6818, 6628, 6449, 6279, 6087, 5906, 5736
dw	5575, 5423, 5279, 5120, 4971, 4830, 4697, 4554
dw	4435, 4307, 4186, 4058, 3950, 3836, 3728, 3615
dw	3519, 3418, 3323, 3224, 3131, 3043, 2960, 2875
dw	2794, 2711, 2633, 2560, 2485, 2415, 2348, 2281
dw	2213, 2153, 2089, 2032, 1975, 1918, 1864, 1810
dw	1757, 1709, 1659, 1612, 1565, 1521, 1478, 1435
dw	1395, 1355, 1316, 1280, 1242, 1207, 1173, 1140
dw	1107, 1075, 1045, 1015, 986,  959,  931,  905
dw  879,  854,  829,  806,  783,  760,  739,  718
dw  697,  677,  658,  640,  621,  604,  586,  570
dw  553,  538,  522,  507,  493,  479,  465,  452
dw  439,  427,  415,  403,  391,  380,  369,  359
dw  348,  339,  329,  319,  310,  302,  293,  285
dw  276,  269,  261,  253,  246,  239,  232,  226
dw  219,  213,  207,  201,  195,  190,  184,  179

_singularity_list:
 db 0, 0, 0, 0, 0, 0, 0, 0, 0, 0
 db 0, 0, 0, 0, 0, 0, 0, 0, 0, 0
 db 0, 0, 0, 0, 0, 0, 0, 0, 0, 0
 db 0, SINGULARITY_FLAG_HIGH, SINGULARITY_FLAG_HIGH, 0, 0, SINGULARITY_FLAG_HIGH, SINGULARITY_FLAG_HIGH, SINGULARITY_FLAG_HIGH, SINGULARITY_FLAG_HIGH, SINGULARITY_FLAG_HIGH
 db SINGULARITY_FLAG_HIGH, SINGULARITY_FLAG_HIGH, SINGULARITY_FLAG_HIGH, SINGULARITY_FLAG_HIGH, SINGULARITY_FLAG_HIGH, SINGULARITY_FLAG_HIGH, SINGULARITY_FLAG_HIGH, SINGULARITY_FLAG_HIGH, SINGULARITY_FLAG_HIGH, SINGULARITY_FLAG_HIGH
 
 db SINGULARITY_FLAG_HIGH, 0, 0, 0, 0, 0, 0, 0, 0, 0
 db 0, 0, 0, 0, 0, 0, 0, 0, 0, 0
 db 0, 0, 0, 0, 0, 0, 0, SINGULARITY_FLAG_HIGH, SINGULARITY_FLAG_HIGH, SINGULARITY_FLAG_HIGH
 db SINGULARITY_FLAG_HIGH, SINGULARITY_FLAG_HIGH, SINGULARITY_FLAG_HIGH, 0, 0, 0, 0, 0, 0, 0
 db 0, 0, 0, 0, 0, 0, 0, 0, 0, 0

 db 0, 0, 0, 0, 0, 0, 0, 0, 0, 0



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


PROC   I_GetSfxLumpNum_ NEAR
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
    mov si, OFFSET _currentnameprefix - OFFSET S_INIT_STARTMARKER_
    mov di, _filename_argument

    ; copy 'd' and prefix
    movsw

    ; si already equal to _sfxlist after movsw
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






;	if (snd_SfxDevice == snd_PC){
;		// todo move this to an overlay?
;		uint16_t currentoffset = 0;
;		sfxenum_t i = 0;
;		pc_speaker_offsets[i] = 4;
;
;
;		for (i=1 ; i < NUMSFX ; i++){
;			int16_t lumpnum = I_GetSfxLumpNum(i);
;			int16_t lumpsize = W_LumpLength(lumpnum);
;			W_CacheLumpNumDirect(lumpnum, MK_FP(PC_SPEAKER_SFX_DATA_SEGMENT, currentoffset));
;			
;			// todo can preprocess the sfx here.
;
;			currentoffset += lumpsize;
;			pc_speaker_offsets[i] = currentoffset+4;
;		}
;
;	}



PROC  S_INIT_ENDMARKER_
PUBLIC  S_INIT_ENDMARKER_

ENDP


END
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
INCLUDE strings.inc
INSTRUCTION_SET_MACRO


EXTRN locallib_fread_nearsegment_:NEAR
EXTRN locallib_fopen_nobuffering_:NEAR
EXTRN locallib_fclose_:NEAR
EXTRN locallib_ftell_:NEAR
EXTRN locallib_fseek_:NEAR
EXTRN locallib_fread_:NEAR
EXTRN exit_:NEAR

EXTRN W_LumpLength_:FAR
EXTRN W_ReadLump_:NEAR
EXTRN W_CheckNumForNameFarString_:NEAR
EXTRN W_AddFile_:NEAR

EXTRN Z_GetEMSPageMap_:NEAR
EXTRN Z_InitEMS_:NEAR
EXTRN Z_QuickMapMenu_:NEAR
EXTRN Z_QuickMapPhysics_:NEAR
EXTRN Z_LoadBinaries_:NEAR
EXTRN Z_SetOverlay_:FAR
EXTRN Z_QuickMapStatus_:NEAR
EXTRN Z_QuickMapDemo_:NEAR
EXTRN Z_ClearDeadCode_:NEAR

EXTRN I_Error_:FAR
EXTRN getStringByIndex_:FAR

EXTRN P_Init_:NEAR
EXTRN I_Init_:NEAR
EXTRN R_Init_:NEAR

EXTRN ST_Init_:NEAR
EXTRN SB_StartInit_:NEAR

EXTRN G_InitNew_:NEAR
EXTRN DEBUG_PRINT_NOARG_CS_:NEAR
EXTRN DEBUG_PRINT_NOARG_:NEAR
EXTRN DEBUG_PRINT_:NEAR
EXTRN combine_strings_:NEAR
EXTRN I_SetPalette_:FAR
EXTRN locallib_strcpy_:NEAR

EXTRN CopyString13_:NEAR
EXTRN _defaults:NEAR
EXTRN _scantokey:NEAR
EXTRN _used_defaultfile:NEAR

EXTRN locallib_strcmp_:NEAR

.DATA




.CODE

EXTRN _forwardmove:WORD
EXTRN _sidemove:WORD


DEMO_MAX_SIZE = 0F800h
AMMNUMPATCHOFFSETS_FAR_OFFSET = 20Ch

PROC    D_INIT_STARTMARKER_ NEAR
PUBLIC  D_INIT_STARTMARKER_
ENDP

_str_config:
db "-config", 0
str_doom2filename_:
db "doom2.wad", 0
str_doomfilename_:
db "doom.wad", 0
str_doom1filename_:
db "doom1.wad", 0

; first 512 bytes of the binary will almost immediately be replaced with a 512 byte file cache for the wad once the wad is loaded. so 512 bytes are frontloaded with code that runs super early.



PROC check_is_ultimate_ NEAR

push    bp
mov     bp, sp
sub     sp, 10
lea     si, str_doomfilename_
push    cs
pop     ds
push    ss
pop     es
lea     di, [bp - 10]
mov     ax, di
movsw
movsw
movsw
movsw
movsb
push    ss
pop     ds
mov     dl, (FILEFLAG_READ OR FILEFLAG_BINARY)
call    locallib_fopen_nobuffering_
push    ax
xchg    cx, ax
lea     ax, [bp - 6]
mov     bx, 6 * 1
call    locallib_fread_nearsegment_
pop     ax  ; fp
call    locallib_fclose_
cmp     word ptr [bp - 2], 0902h
jne     dont_set_ultimate_true
mov     byte ptr ds:[_is_ultimate], 1
dont_set_ultimate_true:

LEAVE_MACRO
ret

ENDP


PROC    D_DoomMain2_ NEAR
PUBLIC  D_DoomMain2_
PUSHA_NO_AX_MACRO

push    bp
mov     bp, sp
sub     sp, 280
; _wadfile bp - 20
; _file    bp - 276
; _textbuffer bp - 280 (overlaps above but not in use at the same time)
; title will go in SECTORS_SEGMENT: 0 for now (since thats not used during init...)

mov     byte ptr [bp - 276], 0  ; file[0] = 0


mov     ax, OFFSET str_doom2filename_
mov     dx, cs
call    locallib_fileexists_
jnc     no_doom2_present
mov     byte ptr ds:[_commercial], 1
mov     cx, cs
mov     bx, OFFSET str_doom2filename_
mov     dx, ss
lea     ax, [bp - 20]
call    locallib_strcpy_
jmp     foundfile
no_doom2_present:

mov     ax, OFFSET str_doomfilename_

call    locallib_fileexists_
jnc     no_doom_present
mov     byte ptr ds:[_registered], 1
mov     cx, cs
mov     bx, OFFSET str_doomfilename_
mov     dx, ss
lea     ax, [bp - 20]
call    locallib_strcpy_
call    check_is_ultimate_
jmp     foundfile
no_doom_present:

mov     ax, OFFSET str_doom1filename_

call    locallib_fileexists_
jnc     no_doom1_present
mov     byte ptr ds:[_shareware], 1
mov     cx, cs
mov     bx, OFFSET str_doom1filename_
mov     dx, ss
lea     ax, [bp - 20]
call    locallib_strcpy_
jmp     foundfile

not_enough_memory:
mov     dx, 16
mul     dx
push    dx
push    ax  ; bytes needed

mov     ax, OFFSET str_not_enough_mem
push    cs
push    ax
call    I_Error_

no_doom1_present:

mov     ax, OFFSET str_no_wad
call    DEBUG_PRINT_NOARG_CS_
mov     ax, 1
jmp     exit_

foundfile:


xor     ax, ax
mov     byte ptr ds:[_modifiedgame], al


mov   ax, OFFSET str_mem
call  M_CheckParm_CS_
test  ax, ax
jne   do_mem_thing


mov     ax, word ptr ds:[__STACKTOP]
add     al, 0Fh
SHIFT_MACRO   shr ax 4
add     ax, DGROUP
cmp     ax, BASE_LOWER_MEMORY_SEGMENT


ja      not_enough_memory



mov   ax, OFFSET str_nomonsters
call  M_CheckParm_CS_
mov   byte ptr ds:[_nomonsters], al

mov   ax, OFFSET str_respawn
call  M_CheckParm_CS_
mov   byte ptr ds:[_respawnparm], al

mov   ax, OFFSET str_fast
call  M_CheckParm_CS_
mov   byte ptr ds:[_fastparm], al

xor   di, di
mov   es, word ptr ds:[_SECTORS_SEGMENT_PTR]

cmp   byte ptr ds:[_commercial], 0
jne   commercial_title
mov   cx, 26
call  PrintSpaces_

mov   si, OFFSET str_title_normal
cmp   byte ptr ds:[_is_ultimate], al ; just made 0 
je    not_ultimate_title_
mov   si, OFFSET str_title_ultimate
mov   byte ptr cs:[SELFMODIFY_set_ultimate_color+1], 120
not_ultimate_title_:
push  cs
push  si
xor   ax, ax
mov   dx, es
mov   bx, ax
mov   cx, es
mov   di, es
call  combine_strings_


mov   es, di
xor   ax, ax
mov   di, ax
mov   ch, 3 ; enough to find what we're looking for
repne scasb ; find end of string
dec   di
mov   cx, 24 
call  PrintSpaces_




jmp   got_title

;; todo any way to ge this dynamically?
do_mem_thing:



mov     dx, REAL_LOWEST_DATA_SEGMENT 
push    dx
mov     bx, DGROUP
mov     ax, word ptr ds:[__STACKTOP]
add     al, 0Fh
SHIFT_MACRO   shr ax 4
add     ax, bx
push    ax              ; end of binary
push    bx              ; stored_ds
sub     dx, ax          ; segments free
; push    dx
mov     ax, 16
mul     dx
; DX:AX = bytes free
push    dx
push    ax
push    cs
mov     ax, OFFSET str_mem_param
push    ax
call    I_Error_


commercial_title:
push  cs
pop   ds
mov   si, OFFSET str_title_doom2
mov   cx, 25
call  PrintSpaces_
dec   di
mov   cx, (OFFSET str_title_doom2_done - OFFSET str_title_doom2)
rep   movsb
mov   cl, 27
call  PrintSpaces_


push  ss
pop   ds
got_title:

mov   ax, 3
cwd
mov   bx, 0
int   010h    ;  set video mode?

call  D_DrawTitle_

mov   ax, OFFSET str_P_Init
call  DEBUG_PRINT_NOARG_CS_

mov   di, word ptr ds:[_myargc]
dec   di                        ; myargc - 1
mov   bx, OFFSET _myargv + 2  ; skip program name

mov   ax, OFFSET str_turbo
call  M_CheckParm_CS_
test  ax, ax
je    skip_turbo

    mov  dx, 200
    cmp   ax, di
    jnl   skip_turbo_second_param


    sal   ax, 1
    xchg  ax, si
    mov   si, word ptr ds:[bx + si]

    xor   ax, ax

    ; mul old number by ten each step. use aad and put into ah
    lodsb           ; digit 1
    sub   al, '0'
    js    done_parsing_turbo_number ; likely was zero or some other garbage. doesn't catch every case.
    aad
    mov   ah, al

    lodsb           ; digit 2
    sub   al, '0'
    js    done_parsing_turbo_number 
    aad
    mov   ah, al

    lodsb           ; digit 3
    sub   al, '0'
    js    done_parsing_turbo_number
    ; scale too big for aad...
    mov   dl, al
    mov   al, 10
    mul   ah
    add   dx, ax
    jmp   done_parsing_three_digit_turbo_number

    done_parsing_turbo_number:

    mov   dl, ah  ; 1 or 2 digit comes out of ah into dl. dh was 0.
    done_parsing_three_digit_turbo_number:
    skip_turbo_second_param:

    cmp   dx, 10
    jg    dont_cap_turbo_min
    mov   dx, 10
    dont_cap_turbo_min:
    cmp   dx, 400
    jl    dont_cap_turbo_max
    mov   dx, 400
    dont_cap_turbo_max:
    
    push  dx
    push  cs
    mov   ax, OFFSET str_turbo_scale
    push  ax
    call  DEBUG_PRINT_
    ;add   sp, 6 ; probably fine to do via leave macro


    push  di
    push  cx
    push  bx

    mov   si, 100
    mov   cx, 4
    mov   bx, dx  ; backup


	;forwardmove[0] = forwardmove[0] * scale / 100;
	;forwardmove[1] = forwardmove[1] * scale / 100;
	;sidemove[0] = sidemove[0] * scale / 100;
	;sidemove[1] = sidemove[1] * scale / 100;
    push  cs
    pop   es


    mov  di, OFFSET _forwardmove
    
    loop_next_param_modify:
    mov   ax, bx
    mul   word ptr es:[di]  ; _forwardmove + 2
    div   si     ; / 100
    stosw
    loop  loop_next_param_modify

    pop   bx  ; restore..
    pop   cx  ; restore..
    pop   di  ; restore..
    


skip_turbo:



mov   ax, OFFSET str_playdemo_param
call  M_CheckParm_CS_
test  ax, ax
je    not_playdemodemo
cmp   ax, di
jl    is_playdemo
not_playdemodemo:
mov   ax, OFFSET str_timedemo_param
call  M_CheckParm_CS_


test  ax, ax
je    not_demo
cmp   ax, di
jnl   not_demo

    is_playdemo:
    push  bx ; save

    sal   ax, 1
    xchg  ax, si
    push  cs
    mov   ax, OFFSET str_lmp_file_ext
    push  ax
    mov   si, word ptr ds:[bx + si]
    mov   bx, si
    mov   cx, ds

    lea   ax, [bp - 276]
    mov   dx, ss
    call  combine_strings_   ; result goes into bp - 276...


    pop   bx ; recover

    push  si
    push  cs
    mov   ax, OFFSET str_playing_demo
    push  ax
    call  DEBUG_PRINT_                  ;		DEBUG_PRINT("Playing demo %s.lmp.\n", myargv[p + 1]);
    ;add   sp, 6 probably fine to do via leave macro


not_demo:


mov   cx, 1
mov   byte ptr cs:[_autostart], ch     ; 0/false
mov   byte ptr ds:[_startepisode], cl  ; 1
mov   byte ptr ds:[_startmap], cl  ; 1
mov   byte ptr ds:[_startskill], SK_MEDIUM
dec   dx  ; 1

mov   ax, OFFSET str_skill
call  M_CheckParm_CS_

test  ax, ax
je    not_skill
cmp   ax, di
jnl   not_skill

    sal   ax, 1
    xchg  ax, si
    mov   si, word ptr ds:[bx + si]
    lodsb 
    sub   al, '1'
    mov   byte ptr ds:[_startskill], al    ;    startskill = myargv[p + 1][0] - '1';
    mov   byte ptr cs:[_autostart], cl     ;    autostart = true;

not_skill:

mov   ax, OFFSET str_episode
call  M_CheckParm_CS_

test  ax, ax
je    not_episode
cmp   ax, di
jnl   not_episode

    sal   ax, 1
    xchg  ax, si
    mov   si, word ptr ds:[bx + si]
    lodsb
    
    mov   byte ptr ds:[_startepisode], al  ;    startepisode = myargv[p + 1][0] - '0';
    mov   byte ptr ds:[_startmap], cl      ;    startmap = 1;
    mov   byte ptr cs:[_autostart], cl     ;    autostart = true;

not_episode:


mov   ax, OFFSET str_warp
call  M_CheckParm_CS_

test  ax, ax
je    not_warp
cmp   ax, di
jnl   not_warp

    sal   ax, 1
    xchg  ax, si
    mov   dx, word ptr ds:[bx + si + 2] ; hold on to this in case.
    mov   si, word ptr ds:[bx + si]
    lodsw    ; al gets first digit and ah gets second if it exists..

    cmp   byte ptr ds:[_commercial], ch   ; 0
    je    not_commercial_warp

    ; atoi on 1-2 numbers al/ah
        test  ah, ah        ; if null terminated 2nd char then handle a single digit
        jne   handle_two_digit
        handle_single_digit:
        mov   ah, '0'
        handle_two_digit:
        sub   ax, 03030h   ; '0' on both digits
        xchg  al, ah
        aad   10
        check_level_param:
        cmp   al, 32       ; highest level number?
        ja    skip_warp_bad_param
        jmp   set_start_map

    not_commercial_warp:

    sub   al, '0'
    mov   byte ptr ds:[_startepisode], al  ;    startepisode = myargv[p + 1][0] - '0';
    mov   si, dx    ; myargv[p + 2]
    lodsb
    sub   al, '0'
    cmp   al, 9       ; highest episode level number?
    ja    skip_warp_bad_param

    set_start_map:
    mov   byte ptr ds:[_startmap], al      ;    startmap = 1;

    mov   byte ptr cs:[_autostart], cl     ;    autostart = true;

skip_warp_bad_param:
not_warp:

mov   ax, OFFSET str_nosound
call  M_CheckParm_CS_

test  ax, ax
je    not_nosound
cmp   ax, di
jnl   not_nosound
mov   byte ptr ds:[_snd_SfxDevice], ch  ; 0
mov   byte ptr ds:[_snd_MusicDevice], ch  ; 0
not_nosound:

mov   ax, OFFSET str_nosfx
call  M_CheckParm_CS_

test  ax, ax
je    not_nosfx
cmp   ax, di
jnl   not_nosfx
mov   byte ptr ds:[_snd_SfxDevice], ch  ; 0
not_nosfx:

mov   ax, OFFSET str_nomusic
call  M_CheckParm_CS_

test  ax, ax
je    not_nomusic
cmp   ax, di
jnl   not_nomusic
mov   byte ptr ds:[_snd_MusicDevice], ch  ; 0
not_nomusic:

mov   ax, OFFSET str_z_init_ems
call  DEBUG_PRINT_NOARG_CS_
call  Z_InitEMS_
; todo return value in ax.
mov   di, OFFSET _EMS_PAGE
push  ds
pop   es
mov   ax, word ptr ds:[di]
stosw ; 0D000h / MUSIC_PAGE_SEGMENT_PTR
add   ah, 4 
stosw ;  _SFX_PAGE_SEGMENT_PTR               ; D400
add   al, 0F0h  
stosw ;  _PC_SPEAKER_OFFSETS_SEGMENT_PTR     ; D4F0
add   ax, 010h  
stosw ;  _PC_SPEAKER_SFX_DATA_SEGMENT_PTR    ; D500
add   ah, 3
stosw ;  _WAD_PAGE_FRAME_PTR                 ; D800
add   ah, 4 
stosw ;  _BSP_CODE_SEGMENT_PTR               ; DC00


mov   ax, OFFSET str_w_init
call  DEBUG_PRINT_NOARG_CS_
lea   ax, [bp - 20]  ; wadfile
call  W_AddFile_
cmp   byte ptr [bp - 276], 0
je    dont_add_2nd_file
lea   ax, [bp - 276]
call  W_AddFile_
dont_add_2nd_file:



mov     ax, OFFSET str_getemspagemap
call    DEBUG_PRINT_NOARG_CS_
call    Z_GetEMSPageMap_

mov     ax, OFFSET str_loaddefaults
call    DEBUG_PRINT_NOARG_CS_
call    M_LoadDefaults_

mov     ax, OFFSET str_z_loadbinaries
call    DEBUG_PRINT_NOARG_CS_
call    Z_LoadBinaries_

call    M_ScanTranslateDefaults_

mov     ax, OFFSET str_initstrings
call    DEBUG_PRINT_NOARG_CS_
call    D_InitStrings_

cmp     byte ptr ds:[_registered], 0
je      skip_registered

  mov   ax, VERSION_REGISTERED
  call  DoPrintChain_

  mov   ax, NOT_SHAREWARE
  call  DoPrintChain_

skip_registered:

cmp     byte ptr ds:[_shareware], 0
je      skip_shareware

  mov   ax, VERSION_SHAREWARE
  call  DoPrintChain_


skip_shareware:

cmp     byte ptr ds:[_commercial], 0
je      skip_commercial

  mov   ax, VERSION_COMMERCIAL
  call  DoPrintChain_

  mov   ax, DO_NOT_DISTRIBUTE
  call  DoPrintChain_

skip_commercial:

mov   ax, M_INIT_TEXT_STR
call  DoPrintChain_



call  Z_QuickMapMenu_
db    09Ah
dw    M_INITOFFSET, MENU_CODE_AREA_SEGMENT
call  Z_QuickMapPhysics_


mov   ax, R_INIT_TEXT_STR
call  DoPrintChain_
call  R_Init_

mov   ax, P_INIT_TEXT_STR
call  DoPrintChain_
call  P_Init_

mov   ax, I_INIT_TEXT_STR
call  DoPrintChain_
call  I_Init_

mov   word ptr ds:[_maketic+0], 0
mov   word ptr ds:[_maketic+2], 0


mov   ax, S_INIT_STRING_TEXT
call  DoPrintChain_
;call  S_Init_  ; inlined

mov   ax, OVERLAY_ID_SOUND_INIT
call  Z_SetOverlay_


;call  LoadSFXWadLumps
db 09Ah
dw LOADSFXWADLUMPSOFFSET, CODE_OVERLAY_SEGMENT

cmp   byte ptr ds:[_snd_SfxDevice], SND_SB
jne   skip_sb_init

call  SB_StartInit_
skip_sb_init:



mov   ax, HU_INIT_TEXT_STR
call  DoPrintChain_
;call  HU_Init_
; inlined

mov   ax, OFFSET str_map31
mov   dx, cs
call  W_CheckNumForNameFarString_
test  ax, ax
js    map31_doesnt_exist
mov   byte ptr ds:[_map31_exists], 1
map31_doesnt_exist:


call  Z_QuickMapStatus_

xor  si, si ; runningoffset = 0
mov  di, si ; loop index
loop_load_next_fontchar:

mov   ax, OFFSET str_hu_init_font_lump
mov   dx, cs
call W_CheckNumForNameFarString_

mov   bx, ax ; store
call  W_LumpLength_


sub   si, ax    ; runningoffset -= size;
mov   ax, si    

shl   di, 1
mov   word ptr ds:[_hu_font + di], si           ; hu_font[i] = runningoffset;
shr   di, 1

mov   cx, ST_GRAPHICS_SEGMENT
xchg  ax, bx  ; size/lump trade
call  W_ReadLump_  ;		W_CacheLumpNumDirect(lump, (byte __far*)(MK_FP(ST_GRAPHICS_SEGMENT, hu_font[i])));

;		font_widths_far[i] = (((patch_t __far *)MK_FP(ST_GRAPHICS_SEGMENT, hu_font[i]))->width);

mov   cx, ST_GRAPHICS_SEGMENT
mov   es, cx
mov   ax, word ptr es:[si + PATCH_T.patch_width]  ; read just byte..?

FONT_WIDTHS_NEAR = (FONT_WIDTHS_SEGMENT - FIXED_DS_SEGMENT) SHL 4

mov   byte ptr ds:[FONT_WIDTHS_NEAR + di], al

inc   di

inc  byte ptr cs:[str_hu_init_font_lump+7] 
cmp  byte ptr cs:[str_hu_init_font_lump+7], '9'
jbe  dont_adjust_tens
inc  byte ptr cs:[str_hu_init_font_lump+6]
mov  byte ptr cs:[str_hu_init_font_lump+7], '0'
dont_adjust_tens:
;cmp  word ptr cs:[str_hu_init_font_lump+6], ((9' SHL 8) + '6')  ; '9' and '6' chars. stop condition is 63 in, after "033" thru "095" patches have been loaded
cmp  di, 03Fh
jl  loop_load_next_fontchar

call   Z_QuickMapPhysics_

; END HU_INIT_



mov   ax, ST_INIT_TEXT_STR
call  DoPrintChain_
call  ST_Init_

;call  AM_loadPics_  ; inlined


xor   si, si  ; offset
mov   di, AMMNUMPATCHOFFSETS_FAR_OFFSET

do_next_patch:
xchg  ax, si
mov   si, AMMNUMPATCHBYTES_SEGMENT
mov   es, si
mov   cx, si ; for later call
stosw

xchg  ax, si  ; put back in si
mov   ax, OFFSET str_ammonamebuf
mov   dx, cs
call  W_CheckNumForNameFarString_

mov   dx, ax ; backup lump

; done earlier from si
;mov   cx, AMMNUMPATCHBYTES_SEGMENT
mov   bx, si
call  W_ReadLump_

xchg  ax, dx    ; retrieve lump
call  W_LumpLength_
add   si, ax

inc   byte ptr cs:[str_ammonamebuf+6]
cmp   byte ptr cs:[str_ammonamebuf+6], '9'
jbe   do_next_patch


mov   di, word ptr ds:[_myargc]
dec   di                        ; myargc - 1
mov   cl, 1
mov   bx, OFFSET _myargv + 2    ; myargv[n + 1]

mov   ax, OFFSET str_record_param
call  M_CheckParm_CS_


test  ax, ax
je    skip_record_param
cmp   ax, di
jnl   skip_record_param


    sal   ax, 1
    xchg  ax, si
    ;call  G_RecordDemo_ ; inlined


    push  cx ; backup
    push  bx ; backup
    
    mov   ax, OFFSET str_lmp_file_ext
    push  cs
    push  ax

    mov   bx, word ptr ds:[bx + si]
    mov   cx, ds
    mov   dx, ds
    mov   ax, OFFSET _demoname
    call  combine_strings_

    pop   bx 
    pop   cx

; todo we dont handle DEMO_MAX_SIZE. we give it 64k and thats it... would require some more advanced ems pagination setup.
COMMENT @
    mov   ax, OFFSET str_maxdemo_param  ; todo this is probably not really supported?
    call  M_CheckParm_CS_

    mov   dx,  DEMO_MAX_SIZE

    test  ax, ax
    je    skip_custom_maxdemo_param
    cmp   ax, di
    jnl   skip_custom_maxdemo_param
    sal   ax, 1
    xchg  ax, si
    mov   si, word ptr ds:[bx + si]
    skip_custom_maxdemo_param:
@

    mov   byte ptr ds:[_demorecording], cl  ; 1
    mov   byte ptr cs:[_autostart], cl  ; 1
    ; fall thru i guess
        

skip_record_param:


mov   ax, OFFSET str_playdemo_param
call  M_CheckParm_CS_


test  ax, ax
je    skip_playdemo_param
cmp   ax, di
jnl   skip_playdemo_param

    mov   byte ptr ds:[_singledemo], cl  ; 1
    sal   ax, 1
    xchg  ax, si
    
    ;call  G_DeferedPlayDemo_
    ; inlined

    jmp   do_just_demo ; subset of -timedemo


skip_playdemo_param:


mov   ax, OFFSET str_timedemo_param
call  M_CheckParm_CS_


test  ax, ax
je    skip_timedemo_param
cmp   ax, di
jnl   skip_timedemo_param


    sal   ax, 1
    xchg  ax, si

    ;mov   ax, OFFSET str_noblit_param
    ;call  M_CheckParm_CS_
    ;mov   byte ptr ds:[_noblit], al     ; noblit = M_CheckParm ("-noblit"); 

    mov   byte ptr ds:[_timingdemo], cl ; 1 ; timingdemo = true; 
    mov   byte ptr ds:[_singletics], cl ; 1 ; singletics = true; 
    
    ;call  G_TimeDemo_ ; inlined
    do_just_demo:
    mov   ax, word ptr ds:[bx + si]
    mov   word ptr ds:[_defdemoname+0], ax ; defdemoname = name; 
    mov   word ptr ds:[_defdemoname+2], ds ; far ptr

    mov   byte ptr ds:[_gameaction], GA_PLAYDEMO ; gameaction = ga_playdemo; 
    

    jmp   exit_doommain

skip_timedemo_param:

mov   ax, OFFSET str_loadgame_param
call  M_CheckParm_CS_


test  ax, ax
je    skip_loadgame_param
cmp   ax, di
jnl   skip_loadgame_param

    call  Z_QuickMapMenu_
    sal   ax, 1
    xchg  ax, si
    mov   ax, word ptr ds:[bx + si]
    db    09Ah
    dw    M_LOADFROMSAVEGAMEOFFSET, MENU_CODE_AREA_SEGMENT


    call  Z_QuickMapPhysics_

skip_loadgame_param:

cmp  byte ptr ds:[_gameaction], GA_LOADGAME
je   skip_loadgame
cmp  byte ptr cs:[_autostart], 0
je   not_autostart
autostart:
xor  ax, ax
cwd
mov  bx, ax
mov  al, byte ptr ds:[_startskill]
mov  dl, byte ptr ds:[_startepisode]
mov  bl, byte ptr ds:[_startmap]
call G_InitNew_
jmp  exit_doommain
not_autostart:

; inline D_StartTitle_

skip_loadgame:

xor   ax, ax
mov   byte ptr ds:[_gameaction], al ; GA_NOTHING
dec   ax  ; - 1
mov   byte ptr ds:[_demosequence], al
neg   ax  ; 1
mov   byte ptr ds:[_advancedemo], al


exit_doommain:

LEAVE_MACRO
POPA_NO_AX_MACRO

ret

ENDP






str_getemspagemap:
db "Z_GetEMSPageMap: Init EMS Conventional Mappings.", 0Ah, 0
str_loaddefaults:
db "M_LoadDefaults	: Load system defaults.", 0Ah, 0
str_z_loadbinaries:
db "Z_LoadBinaries: Load game code into memory", 0
str_initstrings:
db 0Ah, "D_InitStrings: loading text.", 0Ah, 0
str_no_wad:
db "Game mode indeterminate.", 0Ah, 0
str_mem_param:
db 0Ah, "BYTES LEFT: %li (DS : %x to %x BASEMEM : %x)", 0Ah, 0
str_not_enough_mem:
db 0Ah, "ERROR! Not enough conventioal memory free! Need %li more bytes free!", 0Ah, 0

str_P_Init:
db 0Ah, "P_Init: Checking cmd-line parameters...", 0Ah, 0
str_turbo_scale:
db "turbo scale: %i%%", 0Ah, 0

str_title_ultimate:
db " The Ultimate DOOM Startup v1.9", 0
str_title_normal:
db "  DOOM System Startup v1.9  ", 0
str_title_doom2: 
db "DOOM 2: Hell on Earth v1.9"
str_title_doom2_done:

str_z_init_ems:
db "Z_InitEMS: Initialize EMS memory.", 0Ah, 0
str_w_init:
db "W_Init: Init WADfiles.", 0Ah, 0

str_hu_init_font_lump:
db "STCFN033", 0

str_map31:
db "map31", 0

COMMENT @
str_title_plutonia:
db "                   DOOM 2: Plutonia Experiment v", 0
str_title_tnt:
db "                     DOOM 2: TNT - Evilution v", 0
str_title_doom2other:
db "                         DOOM 2: Hell on Earth v", 0
@

 str_ammonamebuf:
 db "AMMNUM0", 0

str_record_param:
db "-record", 0
str_playdemo_param:
db "-playdemo", 0
str_timedemo_param:
db "-timedemo", 0
str_loadgame_param:
db "-loadgame", 0
str_turbo:
db "-turbo", 0
str_skill:
db "-skill", 0
str_episode:
db "-episode", 0
str_warp:
db "-warp", 0
str_nosound:
db "-nosound", 0
str_nosfx:
db "-nosfx", 0
str_nomusic:
db "-nomusic", 0
str_mem:
db "-mem", 0
;str_noblit_param:
;db "-noblit", 0

str_nomonsters:
db "-nomonsters", 0
str_respawn:
db "-respawn", 0
str_fast:
db "-fast", 0


str_dstrings_filename_:
db "dstrings.txt", 0
str_dstrings_missing:
db "dstrings.txt missing?", 0

str_lmp_file_ext:
db ".lmp", 0
str_playing_demo:
db "Playing demo %s.lmp.", 0Ah, 0


_autostart:
db 0


COMMENT @
str_plutoniafilename_:
db "plutonia.wad", 0
str_tntfilename_:
db "tnt.wad", 0
@




TEMP_AREA_SEGMENT = 04000h


PROC M_LoadDefaults_  NEAR
PUBLIC M_LoadDefaults_

PUSHA_NO_AX_MACRO
push  bp

mov   bp, sp
sub   sp, 0AAh
sub   bp, 080h
xor   bx, bx

mov   cx, NUM_DEFAULTS
loop_set_default_values:
xor   ax, ax
mov   si, word ptr cs:[bx + _defaults + DEFAULT_T.default_loc_ptr]
mov   al, byte ptr cs:[bx + _defaults + DEFAULT_T.default_defaultvalue] ; default...
add   bx, 7               ; 
cmp   si, OFFSET _snd_SBport    ; 16 bit value special case
je    shift4_write_word
cmp   si, OFFSET _snd_Mport    ; 16 bit value special case
je    shift4_write_word
mov   byte ptr ds:[si], al         ; written here 1
jmp   wrote_byte
shift4_write_word:
SHIFT_MACRO shl ax 4
mov   word ptr ds:[si], ax
wrote_byte:
loop  loop_set_default_values


mov   ax, OFFSET _str_config
call  CopyString13_
mov   dx, ds
call  M_CheckParm_



test  ax, ax
je    set_default_defaultsfilename
mov   dx, word ptr ds:[_myargc]
dec   dx
cmp   ax, dx
jge   set_default_defaultsfilename
mov   si, OFFSET _myargv
add   ax, ax
add   si, ax
mov   si, word ptr ds:[si + 2]   ; pointer to myargv for default filename
push  si
mov   bx, si  ; cache

; copy updated filename locally

mov   di, OFFSET _used_defaultfile
push  cs
pop   es
mov   cx, 12        ; 12 chars max for 8.3 filename 

loop_copy_new_defaults_filename:
lodsb
stosb
cmp   al, 0
je    done_copying_new_defaults_filename
loop loop_copy_new_defaults_filename
done_copying_new_defaults_filename:

;mov   ax, OFFSET _str_default_file
;call  DEBUG_PRINT_
;add   sp, 4




set_default_defaultsfilename:
mov   ax, OFFSET _used_defaultfile
call  CopyString13_




mov     dl, (FILEFLAG_READ)
;mov    ax, OFFSET _filename_argument    ; already set above
call    locallib_fopen_nobuffering_

test    ax, ax
je      exit_mloaddefaults


xchg    ax, si   ; si gets fp

mov     ax, si
mov     dx, 2   ; SEEK_END
xor     cx, cx
mov     bx, cx
call    locallib_fseek_

mov     ax, si
call    locallib_ftell_   ; get filesize

xchg    ax, di  ; di gets size

mov     ax, si
xor     dx, dx ; 0 SEEK_SET
xor     cx, cx
mov     bx, cx
call    locallib_fseek_   ; back to start

; dump it all to memory then process?
xor     ax, ax
mov     cx, si  ; fp
mov     dx, TEMP_AREA_SEGMENT
mov     bx, di
call    locallib_fread_

xchg    ax, si           ; get fp back
call    locallib_fclose_








defaults_file_loaded:

; cx has length
mov     cx, di  ; size for loop
xor     si, si





; bx is file pointer..
xor   ax, ax
;		int8_t readphase = 0; // getting param 0
;		int8_t defindex = 0;
;		int8_t strparmindex = 0;

; todo make these flags in a single byte (bl/bh?)

mov   byte ptr [bp + 07Ah], al          ; readphase
mov   byte ptr [bp + 07Ch], al
mov   byte ptr [bp + 07Eh], al          ; strparmindex


loop_handle_next_char:
push    cx
mov     ax, TEMP_AREA_SEGMENT
mov     es, ax                  ; todo make not necessary

lods  byte ptr es:[si]
mov   dl, al    ; todo  dont do this
xor   ah, ah
cmp   al, 020h                    ; space charcater
je    is_tab_or_space
cmp   al, 9                           ; tab characters \t
jne   is_not_tab_or_space

is_tab_or_space:
inc   ah
is_not_tab_or_space:
; ah = 1 if whitespace.
; dl is copy of char...
cmp   al, 0Ah                     ; line feed character \n
jne   not_linefeed
is_linefeed_or_carriage_return:
mov   al, 1
checked_for_endline:
; ah = 1 if whiteespace, al = 1 if newline
cmp   byte ptr [bp + 07Ah], 0       ; check readphase
jne   readphase_not_0
; readphase is 0
test  ah, ah
jne   readphase_0_whitespace_or_newline
test  al, al
jne   readphase_0_whitespace_or_newline
mov   al, byte ptr [bp + 07Ch]
cbw  
mov   di, ax
inc   byte ptr [bp + 07Ch]
mov   byte ptr [bp + di - 02Ah], dl
character_finished_handling:

pop   cx
loop  loop_handle_next_char

end_loop_close_file:

; fall thru to bad file
defaults_file_closed:

exit_mloaddefaults:
lea   sp, [bp + 080h]
pop   bp
POPA_NO_AX_MACRO

ret


not_linefeed:
cmp   al, 0Dh                         ; carriage return characters \r
je    is_linefeed_or_carriage_return
xor   al, al
jmp   checked_for_endline
readphase_0_whitespace_or_newline:
test  ah, ah
je    readphase_0_whitespace
mov   al, byte ptr [bp + 07Ch]
cbw  
mov   di, ax
mov   byte ptr [bp + 07Ah], 1
mov   byte ptr [bp + di - 02Ah], 0
jmp   character_finished_handling
readphase_0_whitespace:
mov   byte ptr [bp + 07Ah], ah
mov   byte ptr [bp + 07Ch], ah
mov   byte ptr [bp + 07Eh], ah
jmp   character_finished_handling
readphase_not_0:
cmp   byte ptr [bp + 07Ah], 1
jne   character_finished_handling
test  ah, ah
jne   character_finished_handling
test  al, al
jne   hit_newline
mov   al, byte ptr [bp + 07Eh]
cbw  
mov   di, ax
inc   byte ptr [bp + 07Eh]
mov   byte ptr [bp + di + 026h], dl
jmp   character_finished_handling
hit_newline:
mov   al, byte ptr [bp + 07Eh]      ; get strparmindex
cbw  
mov   di, ax
xor   al, al
mov   byte ptr [bp + 07Ah], al
mov   byte ptr [bp + 07Ch], al
mov   byte ptr [bp + di + 026h], al
cmp   byte ptr [bp + 07Eh], 0
je    character_finished_handling
; prepare to get param...
mov   byte ptr [bp + 07Eh], al
xor   ax, ax
mov   di, ax
mov   cx, ax


read_next_digit:
mov   cl, 10
mul   cl         ; mul by 10
mov   cl, byte ptr [bp + di + 026h];
add   ax, cx     ; add next char
sub   ax, 030h   ; but sub '0' from char
inc   di
cmp   byte ptr [bp + di + 026h], 0 ; check for null term
jne   read_next_digit



mov   word ptr [bp + 078h], ax
xor   di, di

scan_next_default_name_for_match:
lea   ax, [bp - 02Ah]
mov   cx, cs
mov   dx, ds
mov   bx, word ptr cs:[di + _defaults + DEFAULT_T.default_name_ptr]

call  locallib_strcmp_
test  ax, ax
jne   no_match_increment_default
mov   bx, word ptr cs:[di + _defaults + DEFAULT_T.default_loc_ptr]
mov   ax, word ptr [bp + 078h]
; if one of the 16 bit ones then write word..
cmp   bx, OFFSET _snd_SBport
je    do_word_write
cmp   bx, OFFSET _snd_Mport
je    do_word_write
do_byte_write:
mov   byte ptr ds:[bx], al                             ; written here 2 
jmp   character_finished_handling      
do_word_write:
mov   word ptr ds:[bx], ax
jmp   character_finished_handling
no_match_increment_default:

add   di, (SIZE DEFAULT_T)
cmp   di, OFFSET _defaults +(NUM_DEFAULTS * (SIZE DEFAULT_T))
jl    scan_next_default_name_for_match

jmp   character_finished_handling


ENDP

PROC M_ScanTranslateDefaults_ NEAR
PUBLIC M_ScanTranslateDefaults_

PUSHA_NO_AX_MACRO

xor   di, di

;	for (i = 0; i < NUM_DEFAULTS; i++) {
;		if (defaults[i].scantranslate) {
;			parm = *defaults[i].location;
;			defaults[i].untranslated = parm;
;			*defaults[i].location = scantokey[parm];
;		}
;	}
mov   bx, OFFSET _scantokey

loop_defaults_to_set_initial_values:
cmp   byte ptr cs:[di + _defaults + DEFAULT_T.default_scantranslate], 0
je    no_pointer_load_next_defaults_value
mov   si, word ptr cs:[di + _defaults + DEFAULT_T.default_loc_ptr]
lodsb 
mov   byte ptr cs:[di + _defaults + DEFAULT_T.default_untranslated], al  ; written here 3

mov   si, word ptr cs:[di + _defaults + DEFAULT_T.default_loc_ptr]

;mov   al, byte ptr cs:[bx + _scantokey]
xlat  byte ptr cs:[bx]
mov   byte ptr ds:[si], al                     ; written here 4
no_pointer_load_next_defaults_value:
add   di, (SIZE DEFAULT_T)
cmp   di, NUM_DEFAULTS * (SIZE DEFAULT_T)
jne   loop_defaults_to_set_initial_values

POPA_NO_AX_MACRO
ret



ENDP



; todo constants

STRINGDATA_SEGMENT = 06000h
STRINGOFFSETS_OFFSET = 03C40h

do_string_error:
push    cs
mov     ax, OFFSET str_dstrings_missing
push    ax
call    I_Error_

PROC D_InitStrings_ NEAR

push    bp
mov     bp, sp
sub     sp, 14
lea     si, str_dstrings_filename_
push    cs
pop     ds
push    ss
pop     es
lea     di, [bp - 14]
mov     ax, di
mov     cx, 13
rep     movsb
push    ss
pop     ds

mov     dl, (FILEFLAG_READ OR FILEFLAG_BINARY)
call    locallib_fopen_nobuffering_
test    ax, ax
je      do_string_error

xchg    ax, si   ; si gets fp

mov     ax, si
mov     dx, 2   ; SEEK_END
xor     cx, cx
mov     bx, cx
call    locallib_fseek_

mov     ax, si
call    locallib_ftell_   ; get filesize

xchg    ax, di  ; di gets size

mov     ax, si
xor     dx, dx ; 0 SEEK_SET
xor     cx, cx
mov     bx, cx
call    locallib_fseek_   ; back to start

; dump it all to memory then process?
xor     ax, ax
mov     cx, si  ; fp
mov     dx, STRINGDATA_SEGMENT
mov     bx, di
call    locallib_fread_

xchg    ax, si           ; get fp back
call    locallib_fclose_

; now we want to modify in place...

mov     cx, di  ; count
xor     si, si
xor     di, di
mov     ax, STRINGDATA_SEGMENT
mov     ds, ax
mov     es, ax
xor     ax, ax
mov     bx, STRINGOFFSETS_OFFSET  ; target

mov     word ptr ds:[bx], di;  ; make sure to write zero for the first one.

; ds:bx is where the string pointers go
; ds:si is where we are reasing
; es:di is where we are writing to (getting rid of escapes etc)

loop_next_stringfile_char:
lodsb

cmp     al, 0Dh   ; carriage return
je      skip_write

cmp     al, 0Ah   ; newline
je      terminate_string

not_real_newline:

cmp     al, 'n';
jne     not_fake_newline
cmp     dl, '\';  prev char
jne     not_fake_newline
mov     al, 0Ah ; write a newline
dec     di
not_fake_newline:

stosb
xchg    ax, dx ; store prev char in dx (for prev-char stuff)


continue_loop:
loop    loop_next_stringfile_char

done_parsing_string_file:
push    ss
pop     ds
LEAVE_MACRO

ret
terminate_string:
inc     bx
inc     bx
mov     word ptr ds:[bx], di;  stringoffsets[j] = i;// +(page * 16384);
skip_write:
xor     dx, dx
jmp     continue_loop


ENDP


PROC    locallib_fileexists_ NEAR
 

; note: clobbers cx, dx
push  cs
pop   ds
xchg  ax, dx ; dx gets filename
mov   ax, 04300h
int   021h          ; DS:DX = pointer to an ASCIIZ path name  CX = attribute to set
push  ss
pop   ds
mov   ax, 0
;jc    return_0    ; file error, presumably file not found. anyway, cant read
;clc   
;return_0:
cmc         ; just cms to reverse the result


ret


do_dos_error:
;call  __doserror_
; todo??
xor   ax, ax
ret

ENDP


PROC    PrintSpaces_

mov   ax, 02020h
rep   stosb
xchg  ax, cx ; 0. null term
stosb

ret
ENDP



PROC  D_DrawTitle_ NEAR

PUSHA_NO_AX_MACRO

mov   ax, 0300h
xor   bx, bx
int   010h               ; get cursor position
push  dx ; store old pos

mov   ax, 0200h
cwd   ; zero for column pos 0
xor   bx, bx
int   010h               ; set cursor position (to 0 to redraw title above potentially scrolled text)


xor   ax, ax
mov   es, word ptr ds:[_SECTORS_SEGMENT_PTR]
mov   si, ax  ; string pos
mov   di, ax  ; column


loop_next_char:
lods  byte ptr es:[si]
test  al, al
je    end_of_string
;locallib_int86_10_4args(0x900 + string[i], 0, COLOR, 1);
mov   ah, 9
cwd   ; zero dx
SELFMODIFY_set_ultimate_color:
db    0BBh, 116, 00  ; mov   bx, 116 . selfmodified to 120 if ultimate.
mov   cx, 1
int   010h

inc   di ; column
cmp   di, 80
jl    dont_dec_column
xor   di, di
dont_dec_column:
;call  D_SetCursorPosition_  ; update cursor position
mov   ax, 0200h
mov   dx, di
xor   bx, bx
int   010h

jmp   loop_next_char

end_of_string:


;call  D_SetCursorPosition_  ; restore cursor position
mov   ax, 0200h
pop   dx   ; restore old pos
xor   bx, bx
int   010h

POPA_NO_AX_MACRO

ret
ENDP


PROC    DoPrintChain_ NEAR

mov   bx, sp
inc   bx
inc   bx
push  bx  ; sp + 2
mov   cx, ss
call  getStringByIndex_
pop   ax  ; sp + 2
mov   dx, ss
call  DEBUG_PRINT_NOARG_
;call  D_RedrawTitle_  ; inlined


call  D_DrawTitle_      ; todo maybe inline





ret
ENDP




PROC    makethreecharint_ NEAR

push    bx
mov     bx, dx                      
mov     dh, 10                    
div     dh                        
mov     dl, ah                      ; store 3rd digit
add     dl, '0'                     ; piggyback on div queue fill
xor     ah, ah                      ; clear for divide
div     dh                          ;  23 ->   2  1 
xor     dh, dh                      ; null terminate
add     ax, 03030h  ; '0' '0'
mov     word ptr ds:[bx], ax        
mov     word ptr ds:[bx+2], dx      
pop     bx

ret
ENDP


PROC   I_InitGraphics_ NEAR
PUBLIC I_InitGraphics_

cmp     byte ptr ds:[_novideo], 0
jne     return_early_near

push   bx
push   cx
push   dx
push   di


mov    ax, 013h
cwd
xor    bx, bx
int    010h
mov    ax, 1
cwd
mov    byte ptr ds:[_grmode], al ; true
mov    word ptr ds:[_currentscreen+0], dx 
mov    cx, 0A000h
mov    es, cx
mov    word ptr ds:[_currentscreen+2], cx 
mov    word ptr ds:[_destscreen+2], cx 
mov    ch, 040h
mov    word ptr ds:[_destscreen+0], cx 

mov    dx, SC_INDEX  ; 03C4h
mov    al, 4 ; SC_MEMMODE
out    dx, al

inc    dx
in     al, dx
and    al, NOT 8
or     al, 4
out    dx, al   ; outp(SC_INDEX + 1, (inp(SC_INDEX + 1)&~8) | 4);

mov    dx, GC_INDEX ; 03Ceh
mov    al, GC_MODE  ; 5
out    dx, al

inc    dx
in     al, dx
and    al, NOT 13
out    dx, al   ; GC_INDEX + 1, inp(GC_INDEX + 1)&~0x13);

dec    dx
mov    al , 6; GC_MISCELLANEOUS
out    dx, al

inc    dx
in     al, dx
and    al, NOT 2
out    dx, al   ; outp(GC_INDEX + 1, inp(GC_INDEX + 1)&~2);

mov    dx, SC_INDEX  ; 03C4h
mov    ax, 0F02h
out    dx, ax

; cx still 04000
shl    cx, 1
xor    ax, ax
mov    di, ax
rep    stosw        ; FAR_memset(currentscreen, 0, 0xFFFFu);

mov    dx, CRTC_INDEX
mov    al, 20; CRTC_UNDERLINE
out    dx, al

inc    dx
in     al, dx
and    al, NOT 040h
out    dx, al   ; inp(CRTC_INDEX + 1)&~0x40

dec    dx
mov    al, 23; CRTC_MODE
out    dx, al

inc    dx
in     al, dx
or     al, 040h
out    dx, al   ; inp(CRTC_INDEX + 1) | 0x40)

mov    dx, GC_INDEX
mov    al, GC_READMAP
out    dx, al

xor    ax, ax
call   I_SetPalette_

; call I_InitDiskFlash_  ; todo

pop    di
pop    dx
pop    cx
pop    bx
return_early_near:
ret
ENDP






PROC   G_BeginRecording_ NEAR
PUBLIC G_BeginRecording_

push   di
call   Z_QuickMapDemo_
mov    es, word ptr ds:[_DEMO_SEGMENT_PTR]
xor    di, di
mov    al, VERSION
stosb
mov    al, byte ptr ds:[_gameskill]
stosb
mov    ax, word ptr ds:[_gameepisode]
stosb
mov    al, ah ; gamemap
stosb
xor    ax, ax
stosb
mov    al, byte ptr ds:[_respawnparm]
stosb
mov    al, byte ptr ds:[_fastparm]
stosb
mov    al, byte ptr ds:[_nomonsters]
stosb
mov    al, ah ; 0
stosb
inc    ax     ; true
stosw   
dec    ax     ; true
stosw   
mov    word ptr ds:[_demo_p], di
call   Z_QuickMapPhysics_

pop    di

ret
ENDP


PROC    D_DoomMain_ NEAR
PUBLIC  D_DoomMain_

call    D_DoomMain2_   ; init code, gets clobbered.
cmp     byte ptr ds:[_demorecording], 0
je      skip_recording
call    G_BeginRecording_
skip_recording:
call    I_InitGraphics_
jmp     Z_ClearDeadCode_

ENDP



; todo inline only use?

PROC   locallib_strlwr_ NEAR
PUBLIC locallib_strlwr_

push   si
xchg   ax, si
mov    ds, dx
loop_next_char_strlwr:
lodsb
test   al, al
je     done_with_strlwr
cmp    al, 'A'
jb     loop_next_char_strlwr
cmp    al, 'Z'
ja     loop_next_char_strlwr
add    al, 32
mov    byte ptr ds:[si-1], al
jmp    loop_next_char_strlwr
done_with_strlwr:
push   ss
pop    ds
pop    si

ret
ENDP

PROC    M_CheckParm_CS_   NEAR
PUBLIC  M_CheckParm_CS_
mov     dx, cs
ENDP
PROC    M_CheckParm_   NEAR
PUBLIC  M_CheckParm_


PUSHA_NO_AX_MACRO


xchg ax, di   ; di stores arg offset
mov  bp, dx   ; bp stores arg segment

mov  si, 1
cmp  si, word ptr ds:[_myargc]
jge  exit_check_parm_return_0

loop_check_next_parm:
sal  si, 1
mov  ax, word ptr ds:[_myargv + si] ; myargv[i]
mov  dx, ds
call locallib_strlwr_   ;  locallib_strlwr(myargv[i]);

mov  ax, di
mov  dx, bp
mov  bx, word ptr ds:[_myargv + si] ; myargv[i]
mov  cx, ds

call locallib_strcmp_ ; todo carry return?      ; if ( !locallib_strcmp(check, myargv[i]) )

shr  si, 1

test ax, ax
mov  ax, si
je   exit_check_parm_return

xchg ax, bx ; retrieve check


inc  si
cmp  si, word ptr ds:[_myargc]
jl   loop_check_next_parm


exit_check_parm_return_0:
xor  ax, ax
exit_check_parm_return:

mov  es, ax
POPA_NO_AX_MACRO
mov  ax, es

ret

ENDP

PROC    D_INIT_ENDMARKER_ NEAR
PUBLIC  D_INIT_ENDMARKER_
ENDP


END
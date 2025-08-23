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




PLAYER_T STRUC 

    ; cmd struct 8 bytes
    player_cmd_forwardmove    db ?                      ; 0     ;6d0
    player_cmd_sidemove       db ?                      ; 1
    player_cmd_angleturn      dw ?                      ; 2
    player_cmd_consistancy    dw ?                      ; 4
    player_cmd_chatchar       db ?                      ; 6
    player_cmd_buttons        db ?                      ; 7     ;06D7h  06A7h
    player_viewzvalue         dd ?                      ; 8     ;06D8h  06A8h
    player_viewheightvalue    dd ?                      ; C     ;06DCh  06Ach
    player_deltaviewheight    dd ?                      ; 10    ;06E0h  06B0h
    player_bob                dd ?                      ; 14    ;06E4h  06B4h
    player_health             dw ?                      ; 18    ;06E8h  06B8h
    player_armorpoints        dw ?                      ; 1A    ;06EAh  06BAh
    player_armortype	      db ?                      ; 1C    ;06ECh  06BCh
    player_playerstate        db ?                      ; 1D    ;06EDh  06BDh
    player_powers             dw NUMPOWERS   DUP(?)     ; 1E    ;06EEh  06BEh
    player_cards              db NUMCARDS    DUP(?)     ; 2A    ;06FAh  06CAh
    player_readyweapon        db ?                      ; 30    ;0700h  06D0h
    player_pendingweapon      db ?                      ; 31    ;0701h  06D1h
    player_weaponowned        db NUMWEAPONS  DUP(?)     ; 32    ;0702h  06D2h
    player_cheats		      db ?                      ; 3B    ;070Bh  06DBh
    player_ammo               dw NUMAMMO     DUP(?)     ; 3C    ;070Ch  06DCh
    player_maxammo            dw NUMAMMO     DUP(?)     ; 44    ;0714h  06E4h
    player_attackdown         db ?                      ; 4C    ;071Ch  06ECh
    player_usedown            db ?                      ; 4D    ;071Dh  06EDh
    player_killcount          dw ?                      ; 4E    ;071Eh  06EEh
    player_itemcount          dw ?                      ; 50    ;0720h  06F0h
    player_secretcount        dw ?                      ; 52    ;0722h  06F2h
    player_message            dw ?                      ; 54    ;0724h  06F4h
	player_messagestring      dw ?                      ; 56    ;0726h  06F6h
    player_damagecount        dw ?                      ; 58    ;0728h  06F8h
    player_bonuscount         db ?                      ; 5A    ;072Ah  06FAh
    player_refire		      db ?                      ; 5B    ;072Bh  06FBh
    player_attackerRef        dw ?                      ; 5C    ;072Ch  06FCh
    player_extralightvalue    db ?                      ; 5E    ;072Eh  06FEh
    player_fixedcolormapvalue db ?                      ; 5F    ;072Fh  06FFh
    player_colormap	          db ?                      ; 60
    player_didsecret	      db ?                      ; 61
    player_backpack           db ?                      ; 62
                                                        ; 63 or 99 dec

PLAYER_T ENDS

DIVLINE_T STRUC 
    dl_x    dd ?
    dl_y    dd ?
    dl_dx   dd ?
    dl_dy   dd ?
DIVLINE_T ENDS

INTERCEPT_T STRUC 
    intercept_isaline    db ?
    intercept_data       dw ?
INTERCEPT_T ENDS


MOBJ_T STRUC 
    m_sprevRef     dw ?     ; 0
    m_bnextRef     dw ?     ; 2
    m_secnum       dw ?     ; 4

    m_floorz       dw ?     ; 6
    m_ceilingz     dw ?     ; 8

    m_height       dd ?     ; A

    m_momx         dd ?     ; E
    m_momy         dd ?     ; 12
    m_momz         dd ?     ; 16

    m_mobjtype     db ?     ; 1A
    m_tics         db ?     ; 1B

    m_health       dw ?     ; 1C

    m_radius       db ?     ; 1E
    m_movedir      db ?     ; 1F

    m_movecount    dw ?     ; 20
    m_targetRef    dw ?     ; 22

    m_reactiontime db ?     ; 24
    m_threshold    db ?     ; 25

    m_tracerRef    dw ?     ; 26
                            ; 28
MOBJ_T ENDS


THINKER_T STRUC 

    t_prevFunctype  dw ?       ; 0
    t_next          dw ?       ; 2
    t_data          MOBJ_T ?   ; 4
    
THINKER_T ENDS


MOBJ_POS_T STRUC 
    mp_x        dd ?        ; 0
    mp_y        dd ?        ; 4
    mp_z        dd ?        ; 8
    mp_snextRef dw ?        ; C
    mp_angle    dd ?        ; E
    mp_statenum dw ?        ; 12
    mp_flags1   dw ?        ; 14
    mp_flags2   dw ?        ; 16
                            ; 18

MOBJ_POS_T ENDS


 

LINE_PHYSICS_T STRUC 
    lp_v1Offset    dw ?     ; 0
    lp_v2Offset    dw ?     ; 2
    lp_dx          dw ?     ; 4
    lp_dy          dw ?     ; 6
    lp_validcount  dw ?     ; 8
    lp_frontsecnum dw ?     ; A
    lp_backsecnum  dw ?     ; C
    lp_tag         db ?     ; E
    lp_special     db ?     ; F

LINE_PHYSICS_T ENDS


VERTEX_T STRUC 
    v_x        dw ?
    v_y        dw ?
VERTEX_T ENDS



SECTOR_T STRUC 
    sec_floorheight          dw ?   ; 0
    sec_ceilingheight        dw ?   ; 2
    sec_floorpic             db ?   ; 4
    sec_ceilingpic           db ?   ; 5
    sec_validcount           dw ?   ; 6
    sec_thinglistRef         dw ?   ; 8
    sec_linecount            dw ?   ; A
    sec_linesoffset          dw ?   ; C
    sec_lightlevel           db ?   ; E
    sec_unused_padding       db ?   ; F

SECTOR_T ENDS

 


SECTOR_PHYSICS_T STRUC 
    secp_blockbox             dw 4 DUP(?)  ; 0
    secp_specialdataRef       dw ?   ; 8
    secp_linecount            dw ?   ; A 
    secp_linesoffset          dw ?   ; C
    secp_special              db ?   ; E
    secp_tag                  db ?   ; F
SECTOR_PHYSICS_T ENDS



SECTOR_SOUNDORG_T STRUC 
    secso_soundorgX       dw ?
    secso_soundorgY       dw ?
SECTOR_SOUNDORG_T ENDS



SIDE_T STRUC 
    s_toptexture       dw ? ; 0
    s_bottomtexture    dw ? ; 2
    s_midtexture       dw ? ; 4
    s_textureoffset    dw ? ; 6
SIDE_T ENDS



SIDE_RENDER_T  STRUC 
    sr_rowoffset        dw ?
    sr_secnum           dw ?
SIDE_RENDER_T ENDS



LINE_T STRUC 
    l_sidenum       dw 2
LINE_T ENDS



LINE_OPENING_T STRUC 
    lo_opentop       dw ?
    lo_openbottom    dw ?
    lo_lowfloor      dw ?
LINE_OPENING_T ENDS




SUBSECTOR_T STRUC 
    ss_secnum           dw ?
    ss_firstline        dw ?
SUBSECTOR_T ENDS



SEG_PHYSICS_T STRUC 
    sp_frontsecnum           dw ?
    sp_backsecnum            dw ?
SEG_PHYSICS_T ENDS



SEG_RENDER_T STRUC 
    sr_v1Offset           dw ?
    sr_v2Offset           dw ?
    sr_offset             dw ?
    sr_sidedefOffset      dw ?
SEG_RENDER_T ENDS




NODE_T STRUC 
    n_x           dw ?
    n_y           dw ?
    n_dx          dw ?
    n_dy          dw ?
NODE_T ENDS


NODE_CHILDREN_T STRUC 
    nc_children           dw 2
NODE_CHILDREN_T ENDS



NODE_RENDER_T STRUC 
    nr_bbox           dw 8
NODE_RENDER_T ENDS




POST_T STRUC 
    post_topdelta           db ?
    post_length             db ?
POST_T ENDS



MASKED_HEADER_T STRUC 
    mh_pixelofsoffset     dw ?
    mh_postofsoffset      dw ?
    mh_texturesize        dw ?
    mh_reserved           dw ?
MASKED_HEADER_T ENDS


DRAWSEG_T STRUC 
    drawseg_cursegvalue           dw ?
    drawseg_x1                    dw ?
    drawseg_x2                    dw ?

    drawseg_scale1                dd ?
    drawseg_scale2                dd ?
    drawseg_scalestep             dd ?

    drawseg_bsilheight            dw ?
    drawseg_tsilheight            dw ?
    
    drawseg_sprtopclip_offset     dw ?
    drawseg_sprbottomclip_offset  dw ?
    
    drawseg_maskedtexturecol_val  dw ?

    drawseg_silhouette            db ?
    
    drawseg_unused_padding_a      db ?
    drawseg_unused_padding_b      db ?
    drawseg_unused_padding_c      db ?


DRAWSEG_T ENDS




PATCH_T STRUC 
    patch_width           dw ? ; 0
    patch_height          dw ? ; 2 
    patch_leftoffset      dw ? ; 4  
    patch_topoffset       dw ? ; 6  
    patch_columnofs       dd 8 ; 8 

PATCH_T ENDS

VISSPRITE_T STRUC 
    vs_next                db ?
    vs_colormap            db ?
    vs_x1                  dw ?
    vs_x2                  dw ?
    vs_gx                  dd ?
    vs_gy                  dd ?
    vs_gz                  dd ?
    vs_gzt                 dd ?

    vs_startfrac           dd ?
    vs_scale               dd ?
    vs_xiscale             dd ?

    vs_texturemid          dd ?
    vs_patch               dw ?


VISSPRITE_T ENDS



SPRITEFRAME_T STRUC 
    spriteframe_lump                dw 8
    spriteframe_flip                db 8
    spriteframe_rotate              db ?

SPRITEFRAME_T ENDS


SPRITEDEF_T STRUC 
    spritedef_spriteframesOffset  dw ?
    spritedef_numframes           db ?

SPRITEDEF_T ENDS


VISPLANEHEADER_T STRUC 
    visplaneheader_height     dd ?
    visplaneheader_minx       dw ?
    visplaneheader_maxx       dw ?

VISPLANEHEADER_T ENDS

VISPLANEPICLIGHT_T STRUC 
    visplanepiclight_picnum     db ?
    visplanepiclight_lightlevel db ?

VISPLANEPICLIGHT_T ENDS

VISPLANE_T STRUC 
    vp_pad0     db ?
    vp_pad1     db ?
    vp_top      db SCREENWIDTH DUP(?)

    vp_pad2     db ?
    vp_pad3     db ? 
    vp_bottom   db SCREENWIDTH DUP(?)

    vp_pad4     db ?
    vp_pad5     db ?


VISPLANE_T ENDS
 


PSPDEF_T STRUC

    pspdef_statenum     dw ?  ; 0
    pspdef_tics         dw ?  ; 2
    pspdef_sx           dd ?  ; 4
    pspdef_sy           dd ?  ; 8
                              ; C

PSPDEF_T ENDS

WEAPONINFO_T STRUC

    weaponinfo_ammo         db ?  ; 0
    weaponinfo_upstate      dw ?  ; 1
    weaponinfo_downstate    dw ?  ; 3
    weaponinfo_readystate   dw ?  ; 5
    weaponinfo_atkstate     dw ?  ; 7
    weaponinfo_flashstate   dw ?  ; 9


WEAPONINFO_T ENDS

STATE_T STRUC
    state_sprite            db ?  ; 0
    state_frame             db ?  ; 1
    state_tics              db ?  ; 2
    state_action            db ?  ; 3
    state_nextstate         dw ?  ; 4

STATE_T ENDS

MOBJINFO_T STRUC

	mobjinfo_spawnstate     dw ?  ; 0
	mobjinfo_seesound       db ?  ; 2
	mobjinfo_deathsound     db ?  ; 3
    mobjinfo_speed          db ?  ; 4
    mobjinfo_radius         db ?  ; 5
    mobjinfo_height         db ?  ; 6
    mobjinfo_flags1         dw ?  ; 7
    mobjinfo_flags2         dw ?  ; 9

MOBJINFO_T ENDS


MAPTHING_T STRUC

    mapthing_x            dw ?  ; 0
    mapthing_y            dw ?  ; 2
    mapthing_angle        dw ?  ; 4
    mapthing_type         dw ?  ; 6
    mapthing_options      dw ?  ; 8

MAPTHING_T ENDS


DEFAULT_T STRUC

    default_name_ptr      dw ?  ; 0
    default_loc_ptr       dw ?  ; 2
    default_defaultvalue  db ?  ; 4
    default_scantranslate db ?  ; 5
    default_untranslated  db ?  ; 6

DEFAULT_T ENDS
    
BUTTON_T STRUC
    
    button_linenum        dw ?  ; 0
    button_where          db ?  ; 2
    button_btexture       dw ?  ; 3
    button_btimer         dw ?  ; 5
    button_soundorg       dw ?  ; 7


BUTTON_T ENDS

P_SPEC_ANIM_T STRUC

    pspecanim_istexture   db ?  ; 0
    pspecanim_numpics     db ?  ; 1
    pspecanim_picnum      dw ?  ; 2
    pspecanim_basepic     dw ?  ; 4

P_SPEC_ANIM_T ENDS


FLOORMOVE_T STRUC

    floormove_type                db ?  ; 0
    floormove_crush               db ?  ; 1
    floormove_secnum              dw ?  ; 2
    floormove_direction           db ?  ; 4
    floormove_newspecial          db ?  ; 5
    floormove_texture             db ?  ; 6
    floormove_floordestheight     dw ?  ; 7
    floormove_speed               dw ?  ; 9


FLOORMOVE_T ENDS

; align to 14 bytes candidate? currently 13.
CEILING_T STRUC

    ceiling_type               db ?  ; 0
    ceiling_secnum             dw ?  ; 1
    ceiling_bottomheight       dw ?  ; 3
    ceiling_topheight          dw ?  ; 5
    ceiling_speed              dw ?  ; 7
    ceiling_crush              db ?  ; 9
    ceiling_direction          db ?  ; 0A
    ceiling_tag                db ?  ; 0B
    ceiling_olddirection       db ?  ; 0C
    

CEILING_T ENDS

VLDOOR_T STRUC

    vldoor_type               db ?  ; 0
    vldoor_secnum             dw ?  ; 1
    vldoor_topheight          dw ?  ; 3
    vldoor_speed              dw ?  ; 5
    vldoor_direction          dw ?  ; 7
    vldoor_topwait            dw ?  ; 9
    vldoor_topcountdown       dw ?  ; 0B

VLDOOR_T ENDS
    

PLAT_T STRUC

    plat_secnum             dw ?  ; 0
    plat_speed              dw ?  ; 2
    plat_low                dw ?  ; 4
    plat_high               dw ?  ; 6
    plat_wait               db ?  ; 8
    plat_count              db ?  ; 9
    plat_status             db ?  ; 0A
    plat_oldstatus          db ?  ; 0B
    plat_crush              db ?  ; 0C
    plat_tag                db ?  ; 0D
    plat_type               db ?  ; 0E

PLAT_T ENDS


FIREFLICKER_T STRUC

    fireflicker_secnum             dw ?  ; 0
    fireflicker_count              dw ?  ; 2
    fireflicker_maxlight           db ?  ; 4
    fireflicker_minlight           db ?  ; 5

FIREFLICKER_T ENDS

LIGHTFLASH_T STRUC

    lightflash_secnum             dw ?  ; 0
    lightflash_count              dw ?  ; 2
    lightflash_maxlight           db ?  ; 4
    lightflash_minlight           db ?  ; 5
    lightflash_maxtime            db ?  ; 6
    lightflash_mintime            db ?  ; 7

LIGHTFLASH_T ENDS

STROBE_T STRUC

    strobe_secnum             dw ?  ; 0
    strobe_count              dw ?  ; 2
    strobe_minlight           db ?  ; 4
    strobe_maxlight           db ?  ; 5
    strobe_darktime           dw ?  ; 6
    strobe_brighttime         dw ?  ; 8

STROBE_T ENDS


GLOW_T STRUC

    glow_secnum             dw ?  ; 0
    glow_minlight           db ?  ; 2
    glow_maxlight           db ?  ; 3
    glow_direction          dw ?  ; 4

GLOW_T ENDS



CHANNEL_T STRUC
    channel_soundorg_secnum  dw ?  ; 0
    channel_originRef        dw ?  ; 2
    channel_handle           db ?  ; 4
    channel_sfx_id           db ?  ; 5

CHANNEL_T ENDS



MUSIC_DRIVER_T STRUC
    
    md_initdriver_func            dd ?  ; 0
    md_detecthardware_func        dd ?  ; 4
    md_inithardware_func          dd ?  ; 8
    md_deinithardward_func        dd ?  ; C
    md_playnote_func              dd ?  ; 010h
    md_releasenote_func           dd ?  ; 014h
    md_pitchwheel_func            dd ?  ; 018h
    md_changecontrol_func         dd ?  ; 01Ch
    md_playmusic_func             dd ?  ; 020h
    md_stopmusic_func             dd ?  ; 024h
    md_pausemusic_func            dd ?  ; 028h
    md_resumemusic_func           dd ?  ; 02Ch
    md_changesystemvolume_func    dd ?  ; 030h
    md_driverid                   db ?  ; 034h
    md_unused                     db ?  ; 035h
    md_driver_data_Block          db ?  ; 036h


MUSIC_DRIVER_T ENDS

SB_VOICEINFO_T STRUC

    sbvi_sfx_id            db ?  ; 0
    sbvi_samplerate        db ?  ; 1
    sbvi_length            dw ?  ; 2
    sbvi_currentsample     dw ?  ; 4
    sbvi_volume            db ?  ; 6
    sbvi_sep               db ?  ; 7

SB_VOICEINFO_T ENDS



MENUITEM_T STRUC

    menuitem_status        db ?  ; 0
    menuitem_name          db ?  ; 1
    menuitem_routine       dw ?  ; 2
    menuitem_alphakey      db ?  ; 4

MENUITEM_T ENDS


; todo reorder..
MENU_T STRUC

    menu_numitems      db ?  ; 0
    menu_prevMenu      dw ?  ; 1
    menu_menuitems     dw ?  ; 3
    menu_routine       dw ?  ; 5
    menu_x             dw ?  ; 7
    menu_y             db ?  ; 9
    menu_laston        dw ?  ; 0Ah

MENU_T ENDS





VANILLA_PLAYER_T STRUC

    vanilla_player_mo                  dd ?                  ;  0
    vanilla_player_playerstate         dd ?                  ;  4
    vanilla_player_cmd                 db 8 DUP(?)           ;  8
    vanilla_player_viewzvalue          dd ?                  ; 10
    vanilla_player_viewheightvalue     dd ?                  ; 14
    vanilla_player_deltaviewheight     dd ?                  ; 18
    vanilla_player_bob                 dd ?                  ; 1C
    vanilla_player_health              dd ?                  ; 20
    vanilla_player_armorpoints         dd ?                  ; 24
    vanilla_player_armortype           dd ?                  ; 28
    vanilla_player_powers              dd NUMPOWERS DUP(?)   ; 2C 
    vanilla_player_cards               dd NUMCARDS DUP(?)    ; 44 
    vanilla_player_backpack            dd ?                  ; 5C 
    vanilla_player_frags               dd 4 DUP(?)           ; 60 
    vanilla_player_readyweapon         dd ?                  ; 70
    vanilla_player_pendingweapon       dd ?                  ; 74
    vanilla_player_weaponowned         dd NUMWEAPONS DUP(?)  ; 78
    vanilla_player_ammo                dd NUMAMMO DUP(?)     ; 9C
    vanilla_player_maxammo             dd NUMAMMO DUP(?)     ; AC
    vanilla_player_attackdown          dd ?                  ; BC
    vanilla_player_usedown             dd ?                  ; C0
    vanilla_player_cheats              dd ?                  ; C4
    vanilla_player_refire              dd ?                  ; C8
    vanilla_player_killcount           dd ?                  ; CC
    vanilla_player_itemcount           dd ?                  ; D0
    vanilla_player_secretcount         dd ?                  ; D4
    vanilla_player_message             dd ?                  ; D8
    vanilla_player_damagecount         dd ?                  ; DC
    vanilla_player_bonuscount          dd ?                  ; E0
    vanilla_player_attacker            dd ?                  ; E4
    vanilla_player_extralightvalue     dd ?                  ; E8
    vanilla_player_fixedcolormapvalue  dd ?                  ; EC
    vanilla_player_colormap            dd ?                  ; F0
    vanilla_player_psprites_field      dd 8 DUP (?)          ; F4
    vanilla_player_didsecret           dd ?                  ; 114

VANILLA_PLAYER_T ENDS


WATCOM_C_FILE STRUC

    watcom_file_ptr        dw ? ; 00h      unsigned char        *   /* next character position */
    watcom_file_cnt        dw ? ; 02h      int                      /* number of characters left */
    watcom_file_link       dw ? ; 04h      struct __stream_link *   /* location of associated struct */
    watcom_file_flag       dw ? ; 06h      unsigned                 /* mode of file access */
    watcom_file_handle     dw ? ; 08h      int                      /* file handle */
    watcom_file_bufsize    dw ? ; 0Ah      unsigned                 /* size of buffer */
    watcom_file_ungotten   dw ? ; 0Ch      unsigned short           /* used by ungetc and ungetwc */


WATCOM_C_FILE ENDS

WATCOM_STREAM_LINK STRUC

    watcom_streamlink_next             dw ? ; 00h  struct __stream_link *  
    watcom_streamlink_stream           dw ? ; 02h  struct __iobuf *        
    watcom_streamlink_base             dw ? ; 04h  unsigned char *                   /* location of buffer */
    watcom_streamlink_orientation      dw ? ; 06h  int                        /* wide/byte/not oriented */
    watcom_streamlink_extflags         dw ? ; 08h  int                           /* extended flags */
    watcom_streamlink_tmpfchar         dw ? ; 0Ah  unsigned char                 /* tmpfile number */
    watcom_streamlink_filler           dw ? ; 0Ch  unsigned char           sizeof(int)-1];/* explicit padding */

WATCOM_STREAM_LINK ENDS
; 0Dh

    
    
    
COMMENT @
#define _READ   0x0001  /* file opened for reading */
#define _WRITE  0x0002  /* file opened for writing */
#define _UNGET  0x0004  /* ungetc has been done */
#define _BIGBUF 0x0008  /* big buffer allocated */
#define _EOF    0x0010  /* EOF has occurred */
#define _SFERR  0x0020  /* error has occurred on this file */
#define _APPEND 0x0080  /* file opened for append */
#define _BINARY 0x0040  /* file is binary, skip CRLF processing */
#define _IOFBF  0x0100  /* full buffering */
#define _IOLBF  0x0200  /* line buffering */
#define _IONBF  0x0400  /* no buffering */
#define _TMPFIL 0x0800  /* this is a temporary file */
#define _DIRTY  0x1000  /* buffer has been modified */
#define _ISTTY  0x2000  /* is console device */
#define _DYNAMIC 0x4000 /* FILE is dynamically allocated   */
#define _FILEEXT 0x8000 /* lseek with positive offset has been done */
#define _COMMIT 0x0001  /* extended flag: commit OS buffers on flush */
@


HU_MAXLINELENGTH = 80

HU_TEXTLINE_T STRUC

    ; left-justified position of scrolling text window
    hu_textline_x           dw ?                             ; 0
    hu_textline_y           dw ?                             ; 2
    hu_textline_characters  db HU_MAXLINELENGTH + 1 DUP (?)  ; 4  ; line of text
    hu_textline_len         dw ?                             ; 055h ; current line length
    hu_textline_needsupdate db ?                             ; 057h ; whether this line needs to be udpated
                                                             ; 058h
    
HU_TEXTLINE_T ENDS



HU_MAXLINES = 4

HU_STEXT_T STRUC

    hu_stext_textlines           HU_TEXTLINE_T HU_MAXLINES DUP (?)   ; 0
    hu_stext_height              db ?                                ; 0160h   ; height in lines
    hu_stext_currentline         db ?                                ; 0161h   ; current line number
    hu_stext_onptr               dw ?                                ; 0162h   ; pointer to boolean stating whether to update window
    hu_stext_laston              db ?                                ; 0164h   ; last value of *->on
; 165h

HU_STEXT_T ENDS

EVENT_T STRUC
    event_evtype                 db ?  ; 
    event_data1                  dd ?  ; 01   keys/mouse buttons
    event_data2                  dd ?  ; 05   mousex
    event_data3                  dd ?  ; 09   mousey
EVENT_T ENDS



ST_NUMBER_T STRUC
    st_number_x                dw ? ; 0
    st_number_y                dw ? ; 2
    st_number_width            dw ? ; 4
    st_number_oldnum           dw ? ; 6
    st_number_patch_offset     dw ? ; 8
ST_NUMBER_T ENDS


ST_PERCENT_T STRUC
    st_percent_number         ST_NUMBER_T  ?; 0
    st_percent_patch_offset   dw ?        ; 0Ah
ST_PERCENT_T ENDS



ST_MULTIICON_T STRUC
    st_multicon_x                dw ? ; 0
    st_multicon_y                dw ? ; 2
    st_multicon_oldinum          dw ? ; 4
    st_multicon_patch_offset     dw ? ; 6
ST_MULTIICON_T ENDS




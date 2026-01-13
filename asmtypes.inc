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


player_cmd = 0

PLAYER_T STRUC 

    ; cmd struct 8 bytes
    player_cmd_forwardmove    db ?                      ; 0     ;6d0
    player_cmd_sidemove       db ?                      ; 1
    player_cmd_angleturn      dw ?                      ; 2
    player_cmd_consistancy    dw ?                      ; 4
    player_cmd_chatchar       db ?                      ; 6
    player_cmd_buttons        db ?                      ; 7     ;06D7h  06A7h
    player_viewzvalue         dd ?                      ; 8     ;06D8h  06A8h
    player_viewheightvalue    dd ?                      ; C     ;06DCh  06ACh
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
	player_messagestring      dw ?                      ; 56    ;0726h  06F6h ; unused now
    player_damagecount        dw ?                      ; 58    ;0728h  06F8h
    player_bonuscount         db ?                      ; 5A    ;072Ah  06FAh
    player_refire		      db ?                      ; 5B    ;072Bh  06FBh
    player_attackerRef        dw ?                      ; 5C    ;072Ch  06FCh
    player_extralightvalue    db ?                      ; 5E    ;072Eh  06FEh
    player_fixedcolormapvalue db ?                      ; 5F    ;072Fh  06FFh
    player_colormap	          db ?                      ; 60    ;0730h  07000h
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
                               ; 02Ch
    
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
                            ; 010h
LINE_PHYSICS_T ENDS


VERTEX_T STRUC 
    v_x        dw ? ; 0
    v_y        dw ? ; 2
                    ; 4
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
                                    ; 010h
SECTOR_T ENDS

 


SECTOR_PHYSICS_T STRUC 
    secp_blockbox             dw 4 DUP(?)  ; 0
    secp_specialdataRef       dw ?   ; 8
    secp_linecount            dw ?   ; A 
    secp_linesoffset          dw ?   ; C
    secp_special              db ?   ; E
    secp_tag                  db ?   ; F
                                     ; 010h
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
    sr_rowoffset        dw ? ; 0
    sr_secnum           dw ? ; 2
                             ; 4
SIDE_RENDER_T ENDS



LINE_T STRUC 
    l_sidenum       dw 2
                            ; 4
LINE_T ENDS



LINE_OPENING_T STRUC 
    lo_opentop       dw ? ; 0
    lo_openbottom    dw ? ; 2
    lo_lowfloor      dw ? ; 4
                          ; 6
LINE_OPENING_T ENDS




SUBSECTOR_T STRUC 
    ss_secnum           dw ? ; 0
    ss_firstline        dw ? ; 2
                             ; 4
SUBSECTOR_T ENDS



SEG_PHYSICS_T STRUC 
    sp_frontsecnum           dw ? ; 0
    sp_backsecnum            dw ? ; 2
                                  ; 4
SEG_PHYSICS_T ENDS



SEG_RENDER_T STRUC 
    sr_v1Offset           dw ? ; 0
    sr_v2Offset           dw ? ; 2
    sr_offset             dw ? ; 4
    sr_sidedefOffset      dw ? ; 6
                               ; 8
SEG_RENDER_T ENDS




NODE_T STRUC 
    n_x           dw ? ; 0
    n_y           dw ? ; 2
    n_dx          dw ? ; 4
    n_dy          dw ? ; 6
                       ; 8
NODE_T ENDS


NODE_CHILDREN_T STRUC 
    nc_children           dw 2 ; 0
                               ; 4
NODE_CHILDREN_T ENDS



NODE_RENDER_T STRUC 
    nr_bbox           dw 8   ; 0
                             ; 010h
NODE_RENDER_T ENDS




POST_T STRUC 
    post_topdelta           db ?  ; 0
    post_length             db ?  ; 1
                                  ; 2
POST_T ENDS



MASKED_HEADER_T STRUC 
    mh_pixelofsoffset     dw ? ; 0
    mh_postofsoffset      dw ? ; 2
    mh_texturesize        dw ? ; 4
    mh_reserved           dw ? ; 6
MASKED_HEADER_T ENDS


DRAWSEG_T STRUC 
    drawseg_cursegvalue           dw ?   ; 000h
    drawseg_x1                    dw ?   ; 002h
    drawseg_x2                    dw ?   ; 004h
    drawseg_scale1                dd ?   ; 006h
    drawseg_scale2                dd ?   ; 00Ah
    drawseg_scalestep             dd ?   ; 00Eh
    drawseg_bsilheight            dw ?   ; 012h
    drawseg_tsilheight            dw ?   ; 014h
    drawseg_sprtopclip_offset     dw ?   ; 016h
    drawseg_sprbottomclip_offset  dw ?   ; 018h
    drawseg_maskedtexturecol_val  dw ?   ; 01Ah
    drawseg_silhouette            db ?   ; 01Ch
    drawseg_unused_padding_a      db ?   ; 01Dh
    drawseg_unused_padding_b      db ?   ; 01Eh
    drawseg_unused_padding_c      db ?   ; 01Fh
                                         ; 020h


DRAWSEG_T ENDS




PATCH_T STRUC 
    patch_width           dw ? ; 0
    patch_height          dw ? ; 2 
    patch_leftoffset      dw ? ; 4  
    patch_topoffset       dw ? ; 6  
    patch_columnofs       dd 8 ; 8 

PATCH_T ENDS




COLUMN_T STRUC
    column_topdelta        db ?  ; 0
    column_length          db ?  ; 1
COLUMN_T ENDS

VISSPRITE_T STRUC 
    vs_next                db ? ; 0
    vs_colormap            db ? ; 1
    vs_x1                  dw ? ; 2
    vs_x2                  dw ? ; 4
    vs_gx                  dd ? ; 6
    vs_gy                  dd ? ; 0Ah
    vs_gz                  dd ? ; 0Eh
    vs_gzt                 dd ? ; 012h
    vs_startfrac           dd ? ; 016h
    vs_scale               dd ? ; 01Ah
    vs_xiscale             dd ? ; 01Eh
    vs_texturemid          dd ? ; 022h
    vs_patch               dw ? ; 026h
;28h

VISSPRITE_T ENDS



SPRITEFRAME_T STRUC 
    spriteframe_lump                dw 8  DUP(?) ; 0h
    spriteframe_flip                db 8  DUP(?) ; 010h
    spriteframe_rotate              db ?         ; 018h

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
    vp_pad0     db ?                    ; 0
    vp_pad1     db ?                    ; 1
    vp_top      db SCREENWIDTH DUP(?)   ; 2

    vp_pad2     db ?                    ; 0142h
    vp_pad3     db ?                    ; 0143h
    vp_bottom   db SCREENWIDTH DUP(?)   ; 0144h

    vp_pad4     db ?                    ; 0284h
    vp_pad5     db ?                    ; 0285h
                                        ; 0286h (644)

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
                                  ; 0Bh

MOBJINFO_T ENDS


MAPTHING_T STRUC

    mapthing_x            dw ?  ; 0
    mapthing_y            dw ?  ; 2
    mapthing_angle        dw ?  ; 4
    mapthing_type         dw ?  ; 6
    mapthing_options      dw ?  ; 8
                                ; 0Ah
MAPTHING_T ENDS


DEFAULT_T STRUC

    default_name_ptr      dw ?  ; 0
    default_loc_ptr       dw ?  ; 2
    default_defaultvalue  db ?  ; 4
    default_scantranslate db ?  ; 5
    default_untranslated  db ?  ; 6
                                ; 7
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
    md_deinithardware_func        dd ?  ; C
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



; todo flag can be simplified to a byte. maybe handle too

DOSFILE_INFO_T STRUC

    dosfileinfo_ptr        dw ? ; 00h      ptr             ; next character position
    dosfileinfo_cnt        dw ? ; 02h      int             ; number of characters left
    dosfileinfo_flag       dw ? ; 04h      unsigned        ; mode of file access
    dosfileinfo_handle     dw ? ; 06h      int             ; file handle


DOSFILE_INFO_T ENDS


    
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
    event_data1                  db ?  ; 00   keys/mouse buttons
    event_evtype                 db ?  ; 01   eventtype
    event_data2                  dw ?  ; 02   mousex
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



ST_MULTICON_T STRUC
    st_multicon_x                dw ? ; 0
    st_multicon_y                dw ? ; 2
    st_multicon_oldinum          dw ? ; 4
    st_multicon_patch_offset     dw ? ; 6
ST_MULTICON_T ENDS


TASK_T STRUC
    task_count                db ? ; 0
    task_active               db ? ; 1
TASK_T ENDS




MPOINT_T STRUC
    mpoint_x                dw ? ; 0
    mpoint_y                dw ? ; 2
MPOINT_T ENDS



MLINE_T STRUC
    mline_a                MPOINT_T ? ; 0
    mline_b                MPOINT_T ? ; 4
MLINE_T ENDS


FPOINT_T STRUC
    fpoint_x                dw ? ; 0
    fpoint_y                dw ? ; 2
FPOINT_T ENDS


FLINE_T STRUC
    fline_a                FPOINT_T ? ; 0
    fline_b                FPOINT_T ? ; 4
FLINE_T ENDS



LUMPINFO_T STRUC
    lumpinfo_name                db 8 DUP (?) 
    lumpinfo_position            dd ?
    lumpinfo_size                dd ?
LUMPINFO_T ENDS

WADINFO_T STRUC
    wadinfo_identification              db 4 DUP (?) 
    wadinfo_numlumps                    dd ?
    wadinfo_infotableofs                dd ?
WADINFO_T ENDS

FILEINFO_T STRUC
    fileinfo_filepos             dd ?
    fileinfo_size                dd ?
    fileinfo_name                db 8 DUP (?) 
FILEINFO_T ENDS



TEXPATCH_T STRUC
    texpatch_originx             db ?  ; 0
    texpatch_originy             db ?  ; 1
    texpatch_patch               dw ?  ; 2
TEXPATCH_T ENDS


TEXTURE_T STRUC
    texture_name                 db 8  DUP(?) ; 0
    texture_width                db ?         ; 8
    texture_height               db ?         ; 9
    texture_patchcount           db ?         ; 0Ah
    ;texture_patches              TEXPATCH_T ? ; 0Bh  ; ? should have padding maybe?
TEXTURE_T ENDS

MAPPATCH_T STRUC
    mappatch_originx           dw ? ; 0
    mappatch_originy           dw ? ; 2
    mappatch_patch             dw ? ; 4
    mappatch_stepdir           dw ? ; 6
    mappatch_colormap          dw ? ; 8
MAPPATCH_T ENDS


MAPTEXTURE_T STRUC
    maptexture_name              db 8  DUP(?) ; 0
    maptexture_unusedA           db 4  DUP(?) ; 8
    maptexture_width             dw ? ; A
    maptexture_height            dw ? ; C
    maptexture_unusedB           db 4  DUP(?) ; E
    maptexture_patchcount        dw ? ; 12
    ; maptexture_t_patches       MAPPATCH_T ? 
MAPTEXTURE_T ENDS




WBPLAYERSTRUCT_T STRUC
    wbos_in                db  ? ;  0
    wbos_skills            dw  ? ;  1
    wbos_sitems            dw  ? ;  3
    wbos_ssecret           dw  ? ;  5
    wbos_stime             dw  ? ;  7
WBPLAYERSTRUCT_T ENDS

WBSTARTSTRUCT_T STRUC
    wbss_epsd              db  ? ;  0
    wbss_didsecret         db  ? ;  1
    wbss_last              db  ? ;  2
    wbss_next              db  ? ;  3
    wbss_maxkills          dw  ? ;  4
    wbss_maxitems          dw  ? ;  6
    wbss_maxsecret         dw  ? ;  8
    wbss_partime           dw  ? ;  A
    wbss_plyr              WBPLAYERSTRUCT_T  ? ;  C
WBSTARTSTRUCT_T ENDS

TICCMD_T STRUC
    ticcmd_forwardmove    db ? ; 0
    ticcmd_sidemove       db ? ; 1
    ticcmd_angleturn      dw ? ; 2
    ticcmd_consistancy    dw ? ; 4
    ticcmd_chatchar       db ? ; 6
    ticcmd_buttons        db ? ; 7

TICCMD_T ENDS



CACHE_NODE_PAGE_COUNT_T STRUC
    cachenodecount_prev       db ? ; 0
    cachenodecount_next       db ? ; 1
    cachenodecount_pagecount  db ? ; 2
    cachenodecount_numpages   db ? ; 3
CACHE_NODE_PAGE_COUNT_T ENDS


CACHE_NODE_T STRUC
    cachenode_prev       db ? ; 0
    cachenode_next       db ? ; 1
CACHE_NODE_T ENDS


SFXINFO_T STRUC
    sfxinfo_lumpandflags    dw ? ; 0
    sfxinfo_lumpsize        dw ? ; 2
    sfxinfo_cache_position  dw ? ; 4
SFXINFO_T ENDS


SWITCHLIST_T STRUC
    switchlist_name1        db 9  DUP(?) ; 0
    switchlist_name2        db 9  DUP(?) ; 9
    switchlist_episode      dw ?         ; 012h
SWITCHLIST_T ENDS


ANIMDEF_T STRUC
    animdef_istexture      db ?         ; 0
    animdef_endname        db 9  DUP(?) ; 1
    animdef_startname      db 9  DUP(?) ; 0A
ANIMDEF_T ENDS



WIPOINT_T STRUC
    wipoint_x                db ? ; 0
    wipoint_y                db ? ; 1
WIPOINT_T ENDS




WIANIM_T STRUC
    wianim_type          db ?         ; 0
    wianim_period        db ?         ; 1
    wianim_nanims        db ?         ; 2
    wianim_point         WIPOINT_T ?  ; 3
    wianim_data1         db ?         ; 5
    wianim_pRef          dw 3 DUP(?)  ; 6
    wianim_nexttic       dw ?         ; 0Ch
    wianim_ctr           db ?         ; 0Eh
    wianim_state         db ?         ; 0Fh
WIANIM_T ENDS


CLIPRANGE_T STRUC
    cliprange_first                dw ? ; 0
    cliprange_last                 dw ? ; 2
CLIPRANGE_T ENDS

MAPSECTOR_T STRUC
    mapsector_floorheight    dw ?         ; 09h
    mapsector_ceilingheight  dw ?         ; 02h
    mapsector_floorpic       db 8 DUP(?)  ; 04h
    mapsector_ceilingpic     db 8 DUP(?)  ; 0Ch
    mapsector_lightlevel     dw ?         ; 14h
    mapsector_special        dw ?         ; 16h
    mapsector_tag            dw ?         ; 18h
MAPSECTOR_T ENDS           

MAPSIDEDEF_T STRUC
    mapsidedef_textureoffset    dw ?         ; 00h
    mapsidedef_rowoffset        dw ?         ; 02h
    mapsidedef_toptexture       db 8 DUP(?)  ; 04h
    mapsidedef_bottomtexture    db 8 DUP(?)  ; 0Ch
    mapsidedef_midtexture       db 8 DUP(?)  ; 14h
    mapsidedef_sector           dw ?         ; 1Ch
MAPSIDEDEF_T ENDS                            ; 1Eh




MAPLINEDEF_T STRUC
    maplinedef_v1       dw ?         ; 00h
    maplinedef_v2       dw ?         ; 02h
    maplinedef_flags    dw ?         ; 04h
    maplinedef_special  dw ?         ; 06h
    maplinedef_tag      dw ?         ; 08h
    maplinedef_sidenum  dw 2 DUP(?)  ; 0Ah
MAPLINEDEF_T ENDS                    ; 0Eh






MAPSEG_T STRUC
    mapseg_v1         dw ?         ; 00h
    mapseg_v2         dw ?         ; 02h
    mapseg_angle      dw ?         ; 04h
    mapseg_linedef    dw ?         ; 06h
    mapseg_side       dw ?         ; 08h
    mapseg_offset     dw ?         ; 0Ah
MAPSEG_T ENDS                      ; 0Ch

MAPSUBSECTOR_T STRUC
    mapss_nummapsectorsegs  dw ?         ; 00h
    mapss_firstseg          dw ?         ; 02h
MAPSUBSECTOR_T ENDS                      ; 04h

MAPNODE_T STRUC
    mapnode_x             dw ?         ; 00h   ; Partition line from (x,y) to x+dx,y+dy)
    mapnode_y             dw ?         ; 02h
    mapnode_dx            dw ?         ; 04h
    mapnode_dy            dw ?         ; 06h
    mapnode_bbox          dw 8 DUP(?)  ; 08h   ; Bounding box for each child,clip against view frustum.
    mapnode_children      dw 2 DUP(?)  ; 010h  ; If NF_SUBSECTOR its a subsector, else it's a node of another subtree.
MAPNODE_T ENDS                         ; 014h


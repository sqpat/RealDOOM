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
    player_cmd_forwardmove    db ?                      ; 0
    player_cmd_sidemove       db ?                      ; 1
    player_cmd_angleturn      dw ?                      ; 2
    player_cmd_consistancy    dw ?                      ; 4
    player_cmd_chatchar       db ?                      ; 6
    player_cmd_buttons        db ?                      ; 7
    player_viewzvalue         dd ?                      ; 8
    player_viewheightvalue    dd ?                      ; C
    player_deltaviewheight    dd ?                      ; 10
    player_bob                dd ?                      ; 14
    player_health             dw ?                      ; 18
    player_armorpoints        dw ?                      ; 1A
    player_armortype	      db ?                      ; 1C
    player_playerstate        db ?                      ; 1D
    player_powers             dw NUMPOWERS   DUP(?)     ; 1E
    player_cards              db NUMCARDS    DUP(?)     ; 2A
    player_readyweapon        db ?                      ; 30
    player_pendingweapon      db ?                      ; 31
    player_weaponowned        db NUMWEAPONS  DUP(?)     ; 32
    player_cheats		      db ?                      ; 3B
    player_ammo               dw NUMAMMO     DUP(?)     ; 3C
    player_maxammo            dw NUMAMMO     DUP(?)     ; 44
    player_attackdown         db ?                      ; 4C
    player_usedown            db ?                      ; 4D
    player_killcount          dw ?                      ; 4E
    player_itemcount          dw ?                      ; 50
    player_secretcount        dw ?                      ; 52
    player_message            dw ?                      ; 54
	player_messagestring      dw ?                      ; 56
    player_damagecount        dw ?                      ; 58
    player_bonuscount         db ?                      ; 5A
    player_refire		      db ?                      ; 5B
    player_attackerRef        dw ?                      ; 5C
    player_extralightvalue    db ?                      ; 5E
    player_fixedcolormapvalue db ?                      ; 5F
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
    patch_width           dw ?
    patch_height          dw ?    
    patch_leftoffset      dw ?    
    patch_topoffset       dw ?    
    patch_columnofs       dd 8

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
    pspecanim_picnum      dw ?  ; 1
    pspecanim_basepic     dw ?  ; 3
    pspecanim_numpics     db ?  ; 5

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


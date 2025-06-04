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
    player_cmd_forwardmove    db ?
    player_cmd_sidemove       db ?
    player_cmd_angleturn      dw ?
    player_cmd_consistancy    dw ?
    player_cmd_chatchar       db ?
    player_cmd_buttons        db ?
    player_viewzvalue         dd ?
    player_viewheightvalue    dd ?
    player_deltaviewheight    dd ?
    player_bob                dd ?
    player_health             dw ?
    player_armorpoints        dw ?
    player_armortype	      db ?
    player_playerstate        db ?
    player_powers             dw NUMPOWERS   DUP(?)
    player_cards              db NUMCARDS    DUP(?)
    player_readyweapon        db ?
    player_pendingweapon      db ?
    player_weaponowned        db NUMWEAPONS  DUP(?)
    player_cheats		      db ?
    player_ammo               dw NUMAMMO     DUP(?)
    player_maxammo            dw NUMAMMO     DUP(?)
    player_attackdown         db ?
    player_usedown            db ?
    player_killcount          dw ?
    player_itemcount          dw ?
    player_secretcount        dw ?
    player_message            dw ?
	player_messagestring      dw ?
    player_damagecount        dw ?
    player_bonuscount         db ?
    player_refire		      db ?
    player_attackerRef        dw ?
    player_extralightvalue    db ?
    player_fixedcolormapvalue db ?
    player_colormap	          db ?
    player_didsecret	      db ?
    player_backpack           db ?

PLAYER_T ENDS

DIVLINE_T STRUC 
    dl_x    dd ?
    dl_y    dd ?
    dl_dx   dd ?
    dl_dy   dd ?
DIVLINE_T ENDS


MOBJ_T STRUC 
    sprevRef     dw ?
    bnextRef     dw ?
    secnum       dw ?

    floorz       dw ?
    ceilingz     dw ?

    height       dd ?

    momx         dd ?
    momy         dd ?
    momz         dd ?

    mobjtype     db ?
    tics         db ?

    health       dw ?

    radius       db ?
    movedir      db ?

    movecount    dw ?
    targetRef    dw ?

    reactiontime db ?
    threshold    db ?

    tracerRef    dw ?

MOBJ_T ENDS

 


MOBJ_POS_T STRUC 
    x        dd ?
    y        dd ?
    z        dd ?
    snextRef dw ?
    angle    dd ?
    statenum dw ?
    flags1   dw ?
    flags2   dw ?

MOBJ_POS_T ENDS




LINE_PHYSICS_T STRUC 
    v1Offset    dw ?
    v2Offset    dw ?
    lp_dx       dw ?
    lp_dy       dw ?
    validcount  dw ?
    frontsecnum dw ?
    backsecnum  dw ?
    tag         db ?
    special     db ?

LINE_PHYSICS_T ENDS


VERTEX_T STRUC 
    v_x        dw ?
    v_y        dw ?
VERTEX_T ENDS



SECTOR_T STRUC 
    sec_floorheight          dw ?
    sec_ceilingheight        dw ?
    sec_floorpic             db ?
    sec_ceilingpic           db ?
    sec_validcount           dw ?
    sec_thinglistRef         dw ?
    sec_linecount            dw ?
    sec_linesoffset          dw ?
    sec_lightlevel           db ?
    sec_unused_padding       db ?

SECTOR_T ENDS




SECTOR_PHYSICS_T STRUC 
    secp_blockbox             dw 4
    secp_specialdataRef       dw ?
    secp_linecount            dw ?
    secp_linesoffset          dw ?
    secp_special              db ?
    secp_tag                  db ?
SECTOR_PHYSICS_T ENDS



SECTOR_SOUNDORG_T STRUC 
    secso_soundorgX       dw ?
    secso_soundorgY       dw ?
SECTOR_SOUNDORG_T ENDS



SIDE_T STRUC 
    s_toptexture       dw ?
    s_bottomtexture    dw ?
    s_midtexture       dw ?
    s_textureoffset    dw ?
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


    uint16_t    pixelofsoffset;
    uint16_t    postofsoffset;
    uint16_t    texturesize;
    uint16_t    reserved;


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




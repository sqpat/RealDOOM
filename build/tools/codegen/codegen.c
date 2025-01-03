#include "m_offset.h"
#include "m_memory.h"
#include "m_near.h"

#define CONSTANTS_COUNT 140
#define LOCALS_COUNT 19

char* CONSTANTS[CONSTANTS_COUNT] = {
    "SECTORS_SEGMENT",
    "VERTEXES_SEGMENT",
    "SIDES_SEGMENT",
    "LINES_SEGMENT",
    "LINEFLAGSLIST_SEGMENT",
    "SEENLINES_SEGMENT",
    "SUBSECTORS_SEGMENT",
    "SUBSECTOR_LINES_SEGMENT",
    "NODES_SEGMENT",
    "NODE_CHILDREN_SEGMENT",
    "SEG_LINEDEFS_SEGMENT",
    "SEG_SIDES_SEGMENT",


    "FINESINE_SEGMENT",
    "FINECOSINE_SEGMENT",
    "FINETANGENTINNER_SEGMENT",

    "TEXTURECOLUMNLUMPS_BYTES_SEGMENT",
    "TEXTUREDEFS_BYTES_SEGMENT",
    "SPRITETOPOFFSETS_SEGMENT",
    "TEXTUREDEFS_OFFSET_SEGMENT",
    "MASKED_LOOKUP_SEGMENT",
    "MASKED_LOOKUP_SEGMENT_7000",
    "PATCHWIDTHS_SEGMENT",
    "DRAWSEGS_BASE_SEGMENT",
    "DRAWSEGS_BASE_SEGMENT_7000",

    "STATES_SEGMENT",
    "EVENTS_SEGMENT",
    "FLATTRANSLATION_SEGMENT",
    "TEXTURETRANSLATION_SEGMENT",
    "TEXTUREHEIGHTS_SEGMENT",
    "SCANTOKEY_SEGMENT",
    "RNDTABLE_SEGMENT",

    "SEGS_PHYSICS_SEGMENT",
    "DISKGRAPHICBYTES_SEGMENT",



    "THINKERLIST_SEGMENT",
    "MOBJINFO_SEGMENT",
    "LINEBUFFER_SEGMENT",
    "SECTORS_PHYSICS_SEGMENT",
    "SECTORS_SOUNDORGS_SEGMENT",
    "SECTOR_SOUNDTRAVERSED_SEGMENT",

    "INTERCEPTS_SEGMENT",
    "AMMNUMPATCHBYTES_SEGMENT",
    "AMMNUMPATCHOFFSETS_SEGMENT",
    "DOOMEDNUM_SEGMENT",
    "LINESPECIALLIST_SEGMENT",


    "SCREEN0_SEGMENT",
    "SCREEN1_SEGMENT",
    "SCREEN2_SEGMENT",
    "SCREEN3_SEGMENT",
    "SCREEN4_SEGMENT",
    "FWIPE_YCOLUMNS_SEGMENT",
    "FWIPE_MUL160LOOKUP_SEGMENT",

    "GAMMATABLE_SEGMENT",
    "MENUOFFSETS_SEGMENT",

    "LINES_PHYSICS_SEGMENT",
    "BLOCKMAPLUMP_SEGMENT",

    "COLORMAPS_SEGMENT",
    "COLFUNC_JUMP_LOOKUP_SEGMENT",
    "DC_YL_LOOKUP_SEGMENT",
    "COLFUNC_FUNCTION_AREA_SEGMENT",
    "MOBJPOSLIST_SEGMENT",

    "MASKEDPOSTDATA_SEGMENT",
    "SPRITEPOSTDATASIZES_SEGMENT",
    "SPRITETOTALDATASIZES_SEGMENT",
    "MASKEDPOSTDATAOFS_SEGMENT",
    "MASKEDPIXELDATAOFS_SEGMENT",
    "DRAWFUZZCOL_AREA_SEGMENT",

    "CACHEDHEIGHT_SEGMENT",
    "YSLOPE_SEGMENT",
    "CACHEDDISTANCE_SEGMENT",
    "CACHEDXSTEP_SEGMENT",
    "CACHEDYSTEP_SEGMENT",
    "SPANSTART_SEGMENT",
    "DISTSCALE_SEGMENT",

    "OPENINGS_SEGMENT",
    "NEGONEARRAY_SEGMENT",
    "SCREENHEIGHTARRAY_SEGMENT",
    "FLOORCLIP_SEGMENT",
    "CEILINGCLIP_SEGMENT",

    "TEXTUREWIDTHMASKS_SEGMENT",
    "ZLIGHT_SEGMENT",
    "XTOVIEWANGLE_SEGMENT",
    "SPRITEOFFSETS_SEGMENT",
    "PATCHPAGE_SEGMENT",
    "PATCHOFFSET_SEGMENT",


    "SEGS_RENDER_SEGMENT",
    "SEG_NORMALANGLES_SEGMENT",
    "SIDES_RENDER_SEGMENT",
    "VISSPRITES_SEGMENT",
    "PLAYER_VISSPRITES_SEGMENT",
    "TEXTUREPATCHLUMP_OFFSET_SEGMENT",
    "VISPLANEHEADERS_SEGMENT",
    "VISPLANEPICLIGHTS_SEGMENT",
    "FUZZOFFSET_SEGMENT",
    "SCALELIGHTFIXED_SEGMENT",
    "SCALELIGHT_SEGMENT",
    "PATCH_SIZES_SEGMENT",
    "VIEWANGLETOX_SEGMENT",
    "FLATINDEX_SEGMENT",

    "SKYTEXTURE_TEXTURE_SEGMENT",

    "SPANFUNC_JUMP_LOOKUP_SEGMENT",
    "SPANFUNC_FUNCTION_AREA_SEGMENT",
    "COLFUNC_MASKEDMAPPING_SEGMENT",
    "COLFUNC_SEGMENT",
    "R_DRAWCOLUMNPREPMASKEDMULTIOFFSET",
    "MASKEDCONSTANTS_FUNCAREA_SEGMENT",
    "STATES_RENDER_SEGMENT",
    "BASE_LOWER_MEMORY_SEGMENT",
    "BASE_LOWER_END_SEGMENT",
    "EMPTY_RENDER_9800_SEGMENT",
    "PHYSICS_7000_END_SEGMENT",
    "RENDER_8800_END_SEGMENT",
    "RENDER_8400_END_SEGMENT",
    "RENDER_9800_END_SEGMENT",
    "RENDER_9C00_END_SEGMENT",
    "R_DRAWPLANES_OFFSET",
    "DRAWSKYPLANE_AREA_SEGMENT",
    "R_DRAWSKYPLANE_OFFSET",
    "R_DRAWSKYPLANE_DYNAMIC_OFFSET",
    "COLORMAPS_MASKEDMAPPING_SEG_DIFF",
    "COLORMAPS_SEGMENT_MASKEDMAPPING",
    "SEG_SIDES_OFFSET_IN_SEGLINES",

    "ML_TWOSIDED",
    "ML_DONTPEGBOTTOM",
    "MAXLIGHTSCALE",
    "DC_YL_LOOKUP_MASKEDMAPPING_SEGMENT",
    "FLOORCLIP_PARAGRAPH_ALIGNED_SEGMENT",
    "SIZEOF_VISSPRITE_T",
    "R_DRAWMASKEDCOLUMNOFFSET",
    "R_DRAWSINGLEMASKEDCOLUMNOFFSET",
    "R_DRAWFUZZCOLUMNOFFSET",
    "SIZEOF_DRAWSEG_T",
    "OFFSET_NEGONEARRAY",
    "OFFSET_SCREENHEIGHTARRAY",
    "OFFSET_FLOORCLIP",
    "OFFSET_CEILINGCLIP",
    "SIZEOF_MOBJ_POS_T",
    "SIZEOF_SPRITEFRAME_T",
    "SPRITES_SEGMENT",
    "MAXVISSPRITES",
    "FWIPE_CODE_AREA_SEGMENT"

};




segment_t SEGMENTS[CONSTANTS_COUNT] = {
    sectors_segment,
    vertexes_segment, 
    sides_segment, 
    lines_segment, 
    lineflagslist_segment ,
    seenlines_segment, 
    subsectors_segment, 
    subsector_lines_segment, 
    nodes_segment, 
    node_children_segment, 
    seg_linedefs_segment, 
    seg_sides_segment,

    finesine_segment,
    finecosine_segment,
    finetangentinner_segment,
    texturecolumnlumps_bytes_segment,
    texturedefs_bytes_segment,
    spritetopoffsets_segment,
    texturedefs_offset_segment,
    masked_lookup_segment,
    masked_lookup_segment_7000,
    patchwidths_segment,
    drawsegs_BASE_segment,
    drawsegs_BASE_segment_7000,

    states_segment,
    events_segment,
    flattranslation_segment,
    texturetranslation_segment,
    textureheights_segment,
    scantokey_segment,
    rndtable_segment,

    segs_physics_segment,
    diskgraphicbytes_segment,



    thinkerlist_segment,
    mobjinfo_segment,
    linebuffer_segment,
    sectors_physics_segment,
    sectors_soundorgs_segment,
    sector_soundtraversed_segment,
    intercepts_segment,
    ammnumpatchbytes_segment,
    ammnumpatchoffsets_segment,
    doomednum_segment,
    linespeciallist_segment,

    screen0_segment,
    screen1_segment,
    screen2_segment,
    screen3_segment,
    screen4_segment,
    fwipe_ycolumns_segment,
    fwipe_mul160lookup_segment,
    gammatable_segment,
    menuoffsets_segment,

    lines_physics_segment,
    blockmaplump_segment,

    colormaps_segment,
    colfunc_jump_lookup_segment,
    dc_yl_lookup_segment,
    colfunc_function_area_segment,
    mobjposlist_segment,

    maskedpostdata_segment,
    spritepostdatasizes_segment,
    spritetotaldatasizes_segment,
    maskedpostdataofs_segment,
    maskedpixeldataofs_segment,
    drawfuzzcol_area_segment,


    cachedheight_segment,
    yslope_segment,
    cacheddistance_segment,
    cachedxstep_segment,
    cachedystep_segment,
    spanstart_segment,
    distscale_segment,

    openings_segment,
    negonearray_segment,
    screenheightarray_segment,
    floorclip_segment,
    ceilingclip_segment,

    texturewidthmasks_segment,
    zlight_segment,
    xtoviewangle_segment,
    spriteoffsets_segment,
    patchpage_segment,
    patchoffset_segment,



    segs_render_segment,
    seg_normalangles_segment,
    sides_render_segment,
    vissprites_segment,
    player_vissprites_segment,
    texturepatchlump_offset_segment,
    visplaneheaders_segment,
    visplanepiclights_segment,
    fuzzoffset_segment,
    scalelightfixed_segment,
    scalelight_segment,
    patch_sizes_segment,
    viewangletox_segment,
    flatindex_segment,

    skytexture_texture_segment,

    spanfunc_jump_lookup_segment,
    spanfunc_function_area_segment,
    colfunc_segment_maskedmapping,
    colfunc_segment,
    R_DrawColumnPrepMaskedMultiOffset,
    maskedconstants_funcarea_segment,
    states_render_segment,
    base_lower_memory_segment,
    base_lower_end_segment,
    empty_render_9800_segment,
    physics_7000_end_segment,
    render_8800_end_segment,
    render_8400_end_segment,
    render_9800_end_segment,
    render_9C00_end_segment,
    R_DrawPlanesOffset,
    drawskyplane_area_segment,
    R_DrawSkyPlaneOffset,
    R_DrawSkyPlaneDynamicOffset,
    colormaps_maskedmapping_seg_diff,
    colormaps_segment_maskedmapping,
    seg_sides_offset_in_seglines,
    ML_TWOSIDED,
    ML_DONTPEGBOTTOM,
    MAXLIGHTSCALE,
    dc_yl_lookup_maskedmapping_segment,
    floorclip_paragraph_aligned_segment,
    sizeof(vissprite_t),
    R_DrawMaskedColumnOffset,
    R_DrawSingleMaskedColumnOffset,
    R_DrawFuzzColumnOffset,
    sizeof(drawseg_t),
    offset_negonearray,
    offset_screenheightarray,
    offset_floorclip,
    offset_ceilingclip,
    sizeof(mobj_pos_t),
    sizeof(spriteframe_t),
    sprites_segment,
    MAXVISSPRITES,
    fwipe_code_area_segment
    
};

char* LOCALS[LOCALS_COUNT] = {
    "_segs_render",
    "_seg_normalangles",
    "_sides_render",
    "_vissprites",
    "_player_vissprites",
    "_texturepatchlump_offset",
    "_visplaneheaders",
    "_visplanepiclights",
    "_fuzzoffset",
    "_scalelightfixed",
    "_scalelight",
    "_patch_sizes",


    "_thinkerlist",
    "_mobjinfo",
    "_linebuffer",
    "_sectors_physics",
    "NUM_FLAT_CACHE_PAGES",
    "NUM_SPRITE_CACHE_PAGES",
    "NUM_TEXTURE_PAGES"




};

// NOTE: THESE ALL MUST BE HEX
void __near* VALUES[LOCALS_COUNT] = {

    segs_render,
    seg_normalangles,
    sides_render,
    vissprites,
    player_vissprites,

    texturepatchlump_offset,
    visplaneheaders,
    visplanepiclights,
    fuzzoffset,
    scalelightfixed,

    scalelight,
    patch_sizes,

    thinkerlist,
    mobjinfo,
    linebuffer,
    sectors_physics,
    NUM_FLAT_CACHE_PAGES,
    NUM_SPRITE_CACHE_PAGES,
    NUM_TEXTURE_PAGES
    


};

int16_t main ( int16_t argc,int8_t** argv )  { 
    
    // Export .inc file with segment values, etc from the c coe
    FILE* fp = fopen("constant.inc", "w");
    char* varname;
    segment_t segment;
    int16_t i;
    fprintf(fp, "; Far Segments\n");

    for (i = 0; i < CONSTANTS_COUNT; i++){
        varname = CONSTANTS[i];
        segment = SEGMENTS[i];
        fprintf(fp, "%s = 0%Xh\n", varname, segment);
    }
    fprintf(fp, "\n; Near vars as constants. Note these are all hex\n");


    for (i = 0; i < LOCALS_COUNT; i++){
        varname = LOCALS[i];
        fprintf(fp, "%s = 0%Xh\n", varname, VALUES[i]);
    }






    fclose(fp);

    printf("Generated constant.inc file");
    
    return 0;
} 

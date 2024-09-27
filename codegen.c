#include "m_memory.h"
#include "m_near.h"

#define CONSTANTS_COUNT 12

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
    "SEG_LINDEDEFS_SEGMENT",
    "SEG_SIDES_SEGMENT"
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
    seg_sides_segment



    
};

int16_t main ( int16_t argc,int8_t** argv )  { 
    
    // Export .inc file with segment values, etc from the c coe
    FILE* fp = fopen("constant.inc", "w");
    char* varname;
    segment_t segment;
    int16_t i;

    for (i = 0; i < CONSTANTS_COUNT; i++){
        varname = CONSTANTS[i];
        segment = SEGMENTS[i];
        fprintf(fp, "%s = 0%xh\n", varname, segment);

    }

    fclose(fp);

    printf("Generated constant.inc file");
    
    return 0;
} 

#include "z_zone.h"
#include "i_system.h"
#include "doomdef.h"

#include "m_menu.h"
#include "w_wad.h"
#include "r_data.h"

#include "doomstat.h"
#include "r_bsp.h"
#include "r_local.h"
#include "p_local.h"
#include "v_video.h"
#include "st_stuff.h"
#include "hu_stuff.h"
#include "wi_stuff.h"

#include <dos.h>
#include <conio.h>

#include <stdlib.h>
#include "m_memory.h"
#include "m_near.h"

void __far R_MapPlane ( byte y, int16_t x1, int16_t x2 );
void __far R_DrawColumn (void);
void __far R_DrawSkyColumn(int16_t arg_dc_yh, int16_t arg_dc_yl);
void __far R_DrawFuzzColumn(int16_t count, byte __far * dest);


int16_t main ( int16_t argc,int8_t** argv )  { 
    
    // Export .inc file with segment values, etc from the c coe
    FILE*  fp = fopen("doomcode.bin", "wb");
	uint16_t codesize;
    
    codesize = FP_OFF(R_DrawSkyColumn) - FP_OFF(R_DrawColumn);
    // write filesize..
    fwrite(&codesize, 2, 1, fp);
    // write data
    FAR_fwrite((byte __far *)R_DrawColumn, codesize, 1, fp);

    
    codesize = FP_OFF(R_FillBackScreen) - FP_OFF(R_DrawSpan);
    
    // write filesize..
    fwrite(&codesize, 2, 1, fp);
    // write data
    FAR_fwrite((byte __far *)R_DrawSpan, codesize, 1, fp);


    fclose(fp);
    printf("Generated doomcode.bin file\n");

    fp = fopen("m_offsets.h", "wb");
	fprintf(fp, "#define R_DrawColumnPrepOffset 0x%X\n", FP_OFF(R_DrawColumnPrep) - FP_OFF(R_DrawColumn));
	fprintf(fp, "#define R_MapPlaneOffset       0x%X\n", FP_OFF(R_MapPlane) - FP_OFF(R_DrawSpan));

    printf("Generated m_offset.h file");

    return 0;
} 

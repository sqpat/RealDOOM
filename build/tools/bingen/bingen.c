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
void __far R_DrawSkyPlane(int16_t minx, int16_t maxx, visplane_t __far*		pl);
void __far R_DrawSkyPlaneDynamic(int16_t minx, int16_t maxx, visplane_t __far*		pl);

void __far R_DrawPlayerSprites();
void __far hackDSBack();
int16_t __far wipe_doMelt(int16_t ticks);
void __far wipe_WipeLoop();
void __far wipe_StartScreen();
void __far I_ReadScreen(); //todo this gets made the first function...

/*
void checkDS(int16_t a) {
	struct SREGS        sregs;
	uint16_t ds;
	uint16_t ss;
	//byte __far* someptr = malloc(1);
    return;
	segread(&sregs);
	ds = sregs.ds; // 2a56 2e06 c7a
	ss = sregs.ss; // 2a56 2e06 c7a

	if (ds != 0x3C00 || ss != 0x3C00){
		I_Error("\nvalues chaged! %x %x %i", ds, ss, a);
	}

	printf("%i ok", a);

	//I_Error("\npointer is %Fp %x %x %x", someptr, ds, ss, ds_diff);
}
*/

int16_t main ( int16_t argc,int8_t** argv )  { 
    
    // Export .inc file with segment values, etc from the c coe
    FILE*  fp = fopen("doomcode.bin", "wb");
    //FILE*  fp2 = fopen("doomcod2.bin", "wb");
	uint16_t codesize1;
	uint16_t codesize2;
	uint16_t codesize3;
	uint16_t codesize4;
	uint16_t codesize5;
	uint16_t codesize6;
    
    codesize1 = FP_OFF(R_DrawSpan) - FP_OFF(R_DrawColumn);
    // write filesize..
    fwrite(&codesize1, 2, 1, fp);
    // write data
    FAR_fwrite((byte __far *)R_DrawColumn, codesize1, 1, fp);

    
    codesize2 = FP_OFF(R_DrawSkyColumn) - FP_OFF(R_DrawSpan);
    
    //FAR_fwrite((byte __far *)R_MapPlane, FP_OFF(R_DrawSkyColumn) - FP_OFF(R_MapPlane), 1, fp2);
    //fclose(fp2);

    // write filesize..
    fwrite(&codesize2, 2, 1, fp);
    // write data
    FAR_fwrite((byte __far *)R_DrawSpan, codesize2, 1, fp);


    codesize3 = FP_OFF(R_DrawPlayerSprites) - FP_OFF(R_DrawFuzzColumn);
    
    // write filesize..
    fwrite(&codesize3, 2, 1, fp);
    // write data
    FAR_fwrite((byte __far *)R_DrawFuzzColumn, codesize3, 1, fp);

    // This func gets loaded in two spots...
    codesize4 = FP_OFF(R_DrawPlayerSprites) - FP_OFF(R_DrawMaskedColumn);
    // write filesize..
    fwrite(&codesize4, 2, 1, fp);
    // write data
    FAR_fwrite((byte __far *)R_DrawMaskedColumn, codesize4, 1, fp);


    codesize5 = FP_OFF(R_FillBackScreen) - FP_OFF(R_DrawSkyColumn);
    // write filesize..
    fwrite(&codesize5, 2, 1, fp);
    // write data
    FAR_fwrite((byte __far *)R_DrawSkyColumn, codesize5, 1, fp);

    codesize6 = FP_OFF(hackDSBack) - FP_OFF(I_ReadScreen);
    // write filesize..
    fwrite(&codesize6, 2, 1, fp);
    // write data
    FAR_fwrite((byte __far *)I_ReadScreen, codesize6, 1, fp);


    fclose(fp);
    printf("Generated doomcode.bin file\n");

    fp = fopen("m_offsets.h", "wb");
	fprintf(fp, "#define R_DrawColumnPrepOffset         0x%X\n", FP_OFF(R_DrawColumnPrep)         - FP_OFF(R_DrawColumn));
	fprintf(fp, "#define R_MapPlaneOffset               0x%X\n", FP_OFF(R_MapPlane)               - FP_OFF(R_DrawSpan));
	fprintf(fp, "#define R_DrawPlanesOffset             0x%X\n", FP_OFF(R_DrawPlanes)             - FP_OFF(R_DrawSpan));
	fprintf(fp, "#define R_DrawFuzzColumnOffset         0x%X\n", FP_OFF(R_DrawFuzzColumn)         - FP_OFF(R_DrawFuzzColumn));
	fprintf(fp, "#define R_DrawSingleMaskedColumnOffset 0x%X\n", FP_OFF(R_DrawSingleMaskedColumn) - FP_OFF(R_DrawFuzzColumn));
	fprintf(fp, "#define R_DrawMaskedColumnOffset       0x%X\n", FP_OFF(R_DrawMaskedColumn)       - FP_OFF(R_DrawFuzzColumn));
	fprintf(fp, "#define R_DrawMaskedColumnSpriteOffset 0x%X\n", FP_OFF(R_DrawMaskedColumn)       - FP_OFF(R_DrawMaskedColumn));
	fprintf(fp, "#define R_DrawSkyColumnOffset          0x%X\n", FP_OFF(R_DrawSkyColumn)          - FP_OFF(R_DrawSkyColumn));
	fprintf(fp, "#define R_DrawSkyPlaneOffset           0x%X\n", FP_OFF(R_DrawSkyPlane)           - FP_OFF(R_DrawSkyColumn));
	fprintf(fp, "#define R_DrawSkyPlaneDynamicOffset    0x%X\n", FP_OFF(R_DrawSkyPlaneDynamic)    - FP_OFF(R_DrawSkyColumn));
	fprintf(fp, "#define wipe_StartScreenOffset         0x%X\n", FP_OFF(wipe_StartScreen)         - FP_OFF(I_ReadScreen));
	fprintf(fp, "#define wipe_WipeLoopOffset            0x%X\n", FP_OFF(wipe_WipeLoop)            - FP_OFF(I_ReadScreen));



	fprintf(fp, "\n");

	fprintf(fp, "#define R_DrawColumnCodeSize           0x%X\n", codesize1);
    fprintf(fp, "#define R_DrawSpanCodeSize             0x%X\n", codesize2);
	fprintf(fp, "#define R_DrawFuzzColumnCodeSize       0x%X\n", codesize3);
	fprintf(fp, "#define R_DrawMaskedColumnCodeSize     0x%X\n", codesize4);
	fprintf(fp, "#define R_DrawSkyColumnCodeSize        0x%X\n", codesize5);
	fprintf(fp, "#define WipeCodeSize                   0x%X\n", codesize6);



    printf("Generated m_offset.h file");

 
    return 0;
} 

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
//#include "m_near.h"

void __far R_SPAN_STARTMARKER();
void __far R_SPAN_ENDMARKER();
void __far R_MapPlane ( byte y, int16_t x1, int16_t x2 );
void __far R_DrawColumn (void);
void __far R_DrawSkyColumn(int16_t arg_dc_yh, int16_t arg_dc_yl);
void __far R_DrawColumnPrepMaskedMulti();
void __far R_DrawFuzzColumn(int16_t count, byte __far * dest);
void __far R_MASKED_STARTMARKER();
void __far R_DrawSkyPlane(int16_t minx, int16_t maxx, visplane_t __far*		pl);
void __far R_DrawSkyPlaneDynamic(int16_t minx, int16_t maxx, visplane_t __far*		pl);
void __near R_SortVisSprites (void);
void __near R_WriteBackMaskedFrameConstants();
void __near R_WriteBackViewConstantsMasked();
void __far R_DrawMasked();
void __far R_DrawPlayerSprites();
void __far hackDSBack();
int16_t __far wipe_doMelt(int16_t ticks);
void __far wipe_WipeLoop();
void __far wipe_StartScreen();
void __far I_ReadScreen(); //todo this gets made the first function...
void __far R_MASKED_END();
void __far D_ALGO_END();
void __far R_SKY_END();
void __far R_WriteBackViewConstantsSpan();
void __far V_DrawPatchFlipped();
void __far F_StartFinale();
void __far F_Drawer();
void __far F_Responder();
void __far F_Ticker();
void __far F_START();
void __far F_END();
void __far P_LOADSTART();
void __far P_LOADEND();
void __far P_UnArchivePlayers();
void __far P_UnArchiveWorld();
void __far P_UnArchiveThinkers();
void __far P_UnArchiveSpecials();
void __far P_ArchivePlayers();
void __far P_ArchiveWorld();
void __far P_ArchiveThinkers();
void __far P_ArchiveSpecials();
void __far WI_STARTMARKER();
void __far WI_ENDMARKER();

void __far WI_Start();
void __far WI_Ticker();
void __far WI_Drawer();

void __far SM_OPL2_STARTMARKER();
void __far SM_OPL3_STARTMARKER();
void __far SM_MPUMD_STARTMARKER();
void __far SM_SBMID_STARTMARKER();
void __far SM_OPL2_ENDMARKER();
void __far SM_OPL3_ENDMARKER();
void __far SM_MPUMD_ENDMARKER();
void __far SM_SBMID_ENDMARKER();



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
	uint16_t codesize[9];
	uint16_t muscodesize[4];
    int8_t i;
    
    codesize[0] = FP_OFF(R_SPAN_STARTMARKER) - FP_OFF(R_DrawColumn);
    // write filesize..
    fwrite(&codesize[0], 2, 1, fp);
    // write data
    FAR_fwrite((byte __far *)R_DrawColumn, codesize[0], 1, fp);

    
    codesize[1] = FP_OFF(R_SPAN_ENDMARKER) - FP_OFF(R_SPAN_STARTMARKER);
    
    //FAR_fwrite((byte __far *)R_MapPlane, FP_OFF(R_DrawSkyColumn) - FP_OFF(R_MapPlane), 1, fp2);
    //fclose(fp2);

    // write filesize..
    fwrite(&codesize[1], 2, 1, fp);
    // write data
    FAR_fwrite((byte __far *)R_SPAN_STARTMARKER, codesize[1], 1, fp);

    // DrawFuzzColumn thru R_DrawColumnPrepMaskedMulti
    codesize[2] = FP_OFF(R_WriteBackViewConstantsMasked) - FP_OFF(R_MASKED_STARTMARKER);
    
    // write filesize..
    fwrite(&codesize[2], 2, 1, fp);
    // write data
    FAR_fwrite((byte __far *)R_MASKED_STARTMARKER, codesize[2], 1, fp);

    // This func gets loaded in two spots... R_DrawMaskedColumn thru end
    codesize[3] = FP_OFF(R_MASKED_END) - FP_OFF(R_WriteBackViewConstantsMasked);
    // write filesize..
    fwrite(&codesize[3], 2, 1, fp);
    // write data
    FAR_fwrite((byte __far *)R_WriteBackViewConstantsMasked, codesize[3], 1, fp); 


    codesize[4] = FP_OFF(R_SKY_END) - FP_OFF(R_DrawSkyColumn);
    // write filesize..
    fwrite(&codesize[4], 2, 1, fp);
    // write data
    FAR_fwrite((byte __far *)R_DrawSkyColumn, codesize[4], 1, fp);

    codesize[5] = FP_OFF(WI_ENDMARKER) - FP_OFF(WI_STARTMARKER);
    // write filesize..
    fwrite(&codesize[5], 2, 1, fp);
    // write data
    FAR_fwrite((byte __far *)WI_STARTMARKER, codesize[5], 1, fp);


    codesize[6] = FP_OFF(hackDSBack) - FP_OFF(I_ReadScreen);
    // write filesize..
    fwrite(&codesize[6], 2, 1, fp);
    // write data
    FAR_fwrite((byte __far *)I_ReadScreen, codesize[6], 1, fp);

    codesize[7] = FP_OFF(F_END) - FP_OFF(F_START);
    // write filesize..
    fwrite(&codesize[7], 2, 1, fp);
    // write data
    FAR_fwrite((byte __far *)F_START, codesize[7], 1, fp);

    codesize[8] = FP_OFF(P_LOADEND) - FP_OFF(P_LOADSTART);
    // write filesize..
    fwrite(&codesize[8], 2, 1, fp);
    // write data
    FAR_fwrite((byte __far *)P_LOADSTART, codesize[8], 1, fp);

    muscodesize[0] = FP_OFF(SM_OPL2_ENDMARKER) - FP_OFF(SM_OPL2_STARTMARKER);
    fwrite(&muscodesize[0], 2, 1, fp);
    FAR_fwrite((byte __far *)SM_OPL2_STARTMARKER, muscodesize[0], 1, fp);

    muscodesize[1] = FP_OFF(SM_OPL3_ENDMARKER) - FP_OFF(SM_OPL3_STARTMARKER);
    fwrite(&muscodesize[1], 2, 1, fp);
    FAR_fwrite((byte __far *)SM_OPL3_STARTMARKER, muscodesize[1], 1, fp);

    muscodesize[2] = FP_OFF(SM_MPUMD_ENDMARKER) - FP_OFF(SM_MPUMD_STARTMARKER);
    fwrite(&muscodesize[2], 2, 1, fp);
    FAR_fwrite((byte __far *)SM_MPUMD_STARTMARKER, muscodesize[2], 1, fp);

    muscodesize[3] = FP_OFF(SM_SBMID_ENDMARKER) - FP_OFF(SM_SBMID_STARTMARKER);
    fwrite(&muscodesize[3], 2, 1, fp);
    FAR_fwrite((byte __far *)SM_SBMID_STARTMARKER, muscodesize[3], 1, fp);


    fclose(fp);
    
    printf("Generated doomcode.bin file\n");

    // todo many of these not used? clean up?
    fp = fopen("m_offsets.h", "wb");
	// bsp offsets
    fprintf(fp, "#define R_DrawColumnOffset                    0x%X\n", FP_OFF(R_DrawColumn)                    - FP_OFF(R_DrawColumn));

    // masked offsets
	fprintf(fp, "#define R_DrawColumnPrepMaskedMultiOffset     0x%X\n", FP_OFF(R_DrawColumnPrepMaskedMulti)     - FP_OFF(R_MASKED_STARTMARKER));
    fprintf(fp, "#define R_DrawFuzzColumnOffset                0x%X\n", FP_OFF(R_DrawFuzzColumn)                - FP_OFF(R_MASKED_STARTMARKER));
	fprintf(fp, "#define R_DrawSingleMaskedColumnOffset        0x%X\n", FP_OFF(R_DrawSingleMaskedColumn)        - FP_OFF(R_MASKED_STARTMARKER));
	fprintf(fp, "#define R_DrawMaskedColumnOffset              0x%X\n", FP_OFF(R_DrawMaskedColumn)              - FP_OFF(R_MASKED_STARTMARKER));
	fprintf(fp, "#define R_SortVisSpritesOffset                0x%X\n", FP_OFF(R_SortVisSprites)                - FP_OFF(R_MASKED_STARTMARKER));
	fprintf(fp, "#define R_DrawMaskedOffset                    0x%X\n", FP_OFF(R_DrawMasked)                    - FP_OFF(R_MASKED_STARTMARKER));

    // masked selfmodifying code offsets
    fprintf(fp, "#define R_WriteBackViewConstantsMaskedOffset  0x%X\n", FP_OFF(R_WriteBackViewConstantsMasked)  - FP_OFF(R_WriteBackViewConstantsMasked));
    fprintf(fp, "#define R_WriteBackMaskedFrameConstantsOffset 0x%X\n", FP_OFF(R_WriteBackMaskedFrameConstants) - FP_OFF(R_WriteBackViewConstantsMasked));

    // span offsets
    //fprintf(fp, "#define R_MapPlaneOffset                      0x%X\n", FP_OFF(R_MapPlane)                      - FP_OFF(R_SPAN_STARTMARKER));
	fprintf(fp, "#define R_DrawSpanOffset                      0x%X\n", FP_OFF(R_DrawSpan)                      - FP_OFF(R_SPAN_STARTMARKER));
	fprintf(fp, "#define R_DrawPlanesOffset                    0x%X\n", FP_OFF(R_DrawPlanes)                    - FP_OFF(R_SPAN_STARTMARKER));
	fprintf(fp, "#define R_WriteBackViewConstantsSpanOffset    0x%X\n", FP_OFF(R_WriteBackViewConstantsSpan)    - FP_OFF(R_SPAN_STARTMARKER));


    // sky offsets
	fprintf(fp, "#define R_DrawSkyColumnOffset                 0x%X\n", FP_OFF(R_DrawSkyColumn)                - FP_OFF(R_DrawSkyColumn));
	fprintf(fp, "#define R_DrawSkyPlaneOffset                  0x%X\n", FP_OFF(R_DrawSkyPlane)                 - FP_OFF(R_DrawSkyColumn));
	fprintf(fp, "#define R_DrawSkyPlaneDynamicOffset           0x%X\n", FP_OFF(R_DrawSkyPlaneDynamic)          - FP_OFF(R_DrawSkyColumn));
	
    // intermission/ wi stuff offsets
    fprintf(fp, "#define WI_StartOffset                        0x%X\n", FP_OFF(WI_Start)                       - FP_OFF(WI_STARTMARKER));
    fprintf(fp, "#define WI_TickerOffset                       0x%X\n", FP_OFF(WI_Ticker)                      - FP_OFF(WI_STARTMARKER));
    fprintf(fp, "#define WI_DrawerOffset                       0x%X\n", FP_OFF(WI_Drawer)                      - FP_OFF(WI_STARTMARKER));


    // wipe offsets
    fprintf(fp, "#define wipe_StartScreenOffset                0x%X\n", FP_OFF(wipe_StartScreen)               - FP_OFF(I_ReadScreen));
	fprintf(fp, "#define wipe_WipeLoopOffset                   0x%X\n", FP_OFF(wipe_WipeLoop)                  - FP_OFF(I_ReadScreen));

    // finale offsets
    fprintf(fp, "#define F_StartFinaleOffset                   0x%X\n", FP_OFF(F_StartFinale)                  - FP_OFF(F_START));
    fprintf(fp, "#define F_ResponderOffset                     0x%X\n", FP_OFF(F_Responder)                    - FP_OFF(F_START));
    fprintf(fp, "#define F_TickerOffset                        0x%X\n", FP_OFF(F_Ticker)                       - FP_OFF(F_START));
    fprintf(fp, "#define F_DrawerOffset                        0x%X\n", FP_OFF(F_Drawer)                       - FP_OFF(F_START));

    // load offsets
    fprintf(fp, "#define P_UnArchivePlayersOffset              0x%X\n", FP_OFF(P_UnArchivePlayers)             - FP_OFF(P_LOADSTART));
    fprintf(fp, "#define P_UnArchiveWorldOffset                0x%X\n", FP_OFF(P_UnArchiveWorld)               - FP_OFF(P_LOADSTART));
    fprintf(fp, "#define P_UnArchiveThinkersOffset             0x%X\n", FP_OFF(P_UnArchiveThinkers)            - FP_OFF(P_LOADSTART));
    fprintf(fp, "#define P_UnArchiveSpecialsOffset             0x%X\n", FP_OFF(P_UnArchiveSpecials)            - FP_OFF(P_LOADSTART));
    fprintf(fp, "#define P_ArchivePlayersOffset                0x%X\n", FP_OFF(P_ArchivePlayers)               - FP_OFF(P_LOADSTART));
    fprintf(fp, "#define P_ArchiveWorldOffset                  0x%X\n", FP_OFF(P_ArchiveWorld)                 - FP_OFF(P_LOADSTART));
    fprintf(fp, "#define P_ArchiveThinkersOffset               0x%X\n", FP_OFF(P_ArchiveThinkers)              - FP_OFF(P_LOADSTART));
    fprintf(fp, "#define P_ArchiveSpecialsOffset               0x%X\n", FP_OFF(P_ArchiveSpecials)              - FP_OFF(P_LOADSTART));

	fprintf(fp, "\n");

	fprintf(fp, "#define R_DrawColumnCodeSize           0x%X\n", codesize[0]);
    fprintf(fp, "#define R_DrawSpanCodeSize             0x%X\n", codesize[1]);
	fprintf(fp, "#define R_DrawFuzzColumnCodeSize       0x%X\n", codesize[2]);
	fprintf(fp, "#define R_MaskedConstantsCodeSize      0x%X\n", codesize[3]);
	fprintf(fp, "#define R_DrawSkyColumnCodeSize        0x%X\n", codesize[4]);
	fprintf(fp, "#define WI_StuffCodeSize               0x%X\n", codesize[5]);
	fprintf(fp, "#define WipeCodeSize                   0x%X\n", codesize[6]);
	fprintf(fp, "#define FinaleCodeSize                 0x%X\n", codesize[7]);
	fprintf(fp, "#define SaveLoadCodeSize               0x%X\n", codesize[8]);



    printf("Generated m_offset.h file");

 
    return 0;
} 

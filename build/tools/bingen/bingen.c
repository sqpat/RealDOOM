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

void __far R_SPAN16_STARTMARKER();
void __far R_SPAN16_ENDMARKER();
void __far R_DrawPlanes16 (void);
void __far R_WriteBackViewConstantsSpan16 (void);
void __far R_SPAN24_STARTMARKER();
void __far R_SPAN24_ENDMARKER();
void __far R_DrawPlanes24 (void);
void __far R_WriteBackViewConstantsSpan24 (void);
void __far R_SPAN0_STARTMARKER();
void __far R_SPAN0_ENDMARKER();
void __far R_SPANFL_STARTMARKER();
void __far R_SPANFL_ENDMARKER();
void __far R_DrawPlanesFL (void);
void __far R_WriteBackViewConstantsSpanFL (void);

void __far R_DrawPlanes0 (void);
void __far R_WriteBackViewConstantsSpan0 (void);
void __far R_COLUMN24_STARTMARKER();
void __far R_COLUMN24_ENDMARKER();
void __far R_DrawColumn24 (void);
void __far R_COLUMN16_STARTMARKER();
void __far R_COLUMN16_ENDMARKER();
void __far R_DrawColumn16 (void);
void __far R_COLUMN0_STARTMARKER();
void __far R_COLUMN0_ENDMARKER();
void __far R_DrawColumn0 (void);
void __far R_COLUMNFL_STARTMARKER();
void __far R_COLUMNFL_ENDMARKER();
void __far R_DrawColumnFL (void);
void __far R_BSP24_STARTMARKER();
void __far R_BSP24_ENDMARKER();
void __far R_WriteBackViewConstants24();
void __far R_RenderPlayerView24();
void __far R_GetCompositeTexture_Far24();
void __far R_GetPatchTexture_Far24();
void __far R_BSP16_STARTMARKER();
void __far R_BSP16_ENDMARKER();
void __far R_WriteBackViewConstants16();
void __far R_RenderPlayerView16();
void __far R_GetCompositeTexture_Far16();
void __far R_GetPatchTexture_Far16();
void __far R_BSP0_STARTMARKER();
void __far R_BSP0_ENDMARKER();
void __far R_WriteBackViewConstants0();
void __far R_RenderPlayerView0();
void __far R_GetCompositeTexture_Far0();
void __far R_GetPatchTexture_Far0();
void __far R_BSPFL_STARTMARKER();
void __far R_BSPFL_ENDMARKER();
void __far R_WriteBackViewConstantsFL();
void __far R_RenderPlayerViewFL();
void __far R_GetCompositeTexture_FarFL();
void __far R_GetPatchTexture_FarFL();


void __far R_MASK24_STARTMARKER();
void __far R_MASK24_ENDMARKER();
void __far R_MASK16_STARTMARKER();
void __far R_MASK16_ENDMARKER();
void __far R_MASK0_STARTMARKER();
void __far R_MASK0_ENDMARKER();
void __far R_MASKFL_STARTMARKER();
void __far R_MASKFL_ENDMARKER();

void __near R_WriteBackMaskedFrameConstants24();
void __near R_WriteBackViewConstantsMasked24();
void __far R_DrawMasked24();
void __near R_WriteBackMaskedFrameConstants16();
void __near R_WriteBackViewConstantsMasked16();
void __far R_DrawMasked16();
void __near R_WriteBackMaskedFrameConstants0();
void __near R_WriteBackViewConstantsMasked0();
void __far R_DrawMasked0();
void __near R_WriteBackMaskedFrameConstantsFL();
void __near R_WriteBackViewConstantsMaskedFL();
void __far R_DrawMaskedFL();



void __far R_DrawPlayerSprites();
void __far hackDSBack();
int16_t __far wipe_doMelt(int16_t ticks);
void __far wipe_WipeLoop();
void __far wipe_StartScreen();
void __far I_ReadScreen(); //todo this gets made the first function...
void __far D_ALGO_END();

void __far R_SKY_STARTMARKER();
void __far R_SKY_ENDMARKER();
void __far R_DrawSkyColumn(int16_t arg_dc_yh, int16_t arg_dc_yl);
void __far R_DrawSkyPlane(int16_t minx, int16_t maxx, visplane_t __far*		pl);
void __far R_DrawSkyPlaneDynamic(int16_t minx, int16_t maxx, visplane_t __far*		pl);

void __far R_SKYFL_STARTMARKER();
void __far R_SKYFL_ENDMARKER();
void __far R_DrawSkyColumnFL(int16_t arg_dc_yh, int16_t arg_dc_yl);
void __far R_DrawSkyPlaneFL(int16_t minx, int16_t maxx, visplane_t __far*		pl);
void __far R_DrawSkyPlaneDynamicFL(int16_t minx, int16_t maxx, visplane_t __far*		pl);

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
void __far SM_LOAD_STARTMARKER();
void __far SM_LOAD_ENDMARKER();
void __far S_ActuallyChangeMusic();
boolean __far P_CheckSight (mobj_t __near* t1,mobj_t __near* t2, uint16_t t1_pos, uint16_t t2_pos);

void __far S_INIT_STARTMARKER();
void __far S_INIT_ENDMARKER();
void __far P_SIGHT_STARTMARKER();
void __far P_SIGHT_ENDMARKER();
void __far P_MAP_STARTMARKER();
void __far P_MAP_ENDMARKER();
void __far P_MOBJ_STARTMARKER();
void __far P_MOBJ_ENDMARKER();
void __far P_PSPR_STARTMARKER();
void __far P_PSPR_ENDMARKER();
void __far P_ENEMY_STARTMARKER();
void __far P_ENEMY_ENDMARKER();

void __far P_AproxDistance();
void __far P_UnsetThingPosition();
void __far P_SetThingPositionFar();
void __far R_PointInSubsector();
void __far P_BlockThingsIterator();
void __far P_PathTraverse();
void __far P_TryMove();
void __far P_CheckPosition();
void __far P_SlideMove();
void __far P_TeleportMove();
void __far P_UseLines();
void __far P_RadiusAttack();
void __far P_ChangeSector();


// void __far P_SpawnPuff();
void __far P_XYMovement();
void __far P_ZMovement();
void __far P_ExplodeMissile();
void __far P_NightmareRespawn();
void __far P_CheckMissileSpawn();
void __far P_SpawnMissile();
void __far P_SpawnPlayerMissile();


void __far P_MovePsprites();

void __far P_MobjThinker();
void __far P_RemoveMobj();
void __far P_SpawnMobj();
void __far P_SpawnMapThing();
void __far P_SetMobjState();


void __far F_WIPE_STARTMARKER();
void __far F_WIPE_ENDMARKER();


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
void __far LoadSFXWadLumps();

void __far P_INFO_ENDMARKER();
void __far P_Ticker();
void __far P_SpawnSpecials();
void __far P_GivePower();


void __far P_RemoveThinker();



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

	if (ds != FIXED_DS_SEGMENT || ss != FIXED_DS_SEGMENT){
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
	uint16_t codesize[29];
	uint16_t muscodesize[4];
	uint16_t maxmuscodesize = 0;
    int8_t i;
    
    codesize[0] = FP_OFF(R_COLUMN24_ENDMARKER) - FP_OFF(R_COLUMN24_STARTMARKER);
    // write filesize..
    fwrite(&codesize[0], 2, 1, fp);
    // write data
    FAR_fwrite((byte __far *)R_COLUMN24_STARTMARKER, codesize[0], 1, fp);
    
    codesize[19] = FP_OFF(R_COLUMN16_ENDMARKER) - FP_OFF(R_COLUMN16_STARTMARKER);
    // write filesize..
    fwrite(&codesize[19], 2, 1, fp);
    // write data
    FAR_fwrite((byte __far *)R_COLUMN16_STARTMARKER, codesize[19], 1, fp);

    codesize[15] = FP_OFF(R_COLUMN0_ENDMARKER) - FP_OFF(R_COLUMN0_STARTMARKER);
    fwrite(&codesize[15], 2, 1, fp);
    FAR_fwrite((byte __far *)R_COLUMN0_STARTMARKER, codesize[15], 1, fp);

    codesize[24] = FP_OFF(R_COLUMNFL_ENDMARKER) - FP_OFF(R_COLUMNFL_STARTMARKER);
    fwrite(&codesize[24], 2, 1, fp);
    FAR_fwrite((byte __far *)R_COLUMNFL_STARTMARKER, codesize[24], 1, fp);

    
    codesize[1] = FP_OFF(R_SPAN24_ENDMARKER) - FP_OFF(R_SPAN24_STARTMARKER);
    fwrite(&codesize[1], 2, 1, fp); // write filesize..
    FAR_fwrite((byte __far *)R_SPAN24_STARTMARKER, codesize[1], 1, fp); // write data
    
    codesize[13] = FP_OFF(R_SPAN16_ENDMARKER) - FP_OFF(R_SPAN16_STARTMARKER);    
    fwrite(&codesize[13], 2, 1, fp); // write filesize..
    FAR_fwrite((byte __far *)R_SPAN16_STARTMARKER, codesize[13], 1, fp); // write data
    
    codesize[14] = FP_OFF(R_SPAN0_ENDMARKER) - FP_OFF(R_SPAN0_STARTMARKER);    
    fwrite(&codesize[14], 2, 1, fp); // write filesize..
    FAR_fwrite((byte __far *)R_SPAN0_STARTMARKER, codesize[14], 1, fp); // write data

    codesize[23] = FP_OFF(R_SPANFL_ENDMARKER) - FP_OFF(R_SPANFL_STARTMARKER);
    fwrite(&codesize[23], 2, 1, fp); // write filesize..
    FAR_fwrite((byte __far *)R_SPANFL_STARTMARKER, codesize[23], 1, fp); // write data


    codesize[2] = FP_OFF(R_WriteBackViewConstantsMasked24) - FP_OFF(R_MASK24_STARTMARKER);
    fwrite(&codesize[2], 2, 1, fp);
    FAR_fwrite((byte __far *)R_MASK24_STARTMARKER, codesize[2], 1, fp);


    codesize[20] = FP_OFF(R_WriteBackViewConstantsMasked16) - FP_OFF(R_MASK16_STARTMARKER);
    fwrite(&codesize[20], 2, 1, fp);
    FAR_fwrite((byte __far *)R_MASK16_STARTMARKER, codesize[20], 1, fp);

    codesize[17] = FP_OFF(R_WriteBackViewConstantsMasked0) - FP_OFF(R_MASK0_STARTMARKER);
    fwrite(&codesize[17], 2, 1, fp);
    FAR_fwrite((byte __far *)R_MASK0_STARTMARKER, codesize[17], 1, fp);

    codesize[25] = FP_OFF(R_WriteBackViewConstantsMaskedFL) - FP_OFF(R_MASKFL_STARTMARKER);
    fwrite(&codesize[25], 2, 1, fp);
    FAR_fwrite((byte __far *)R_MASKFL_STARTMARKER, codesize[25], 1, fp);

    codesize[3] = FP_OFF(R_MASK24_ENDMARKER) - FP_OFF(R_WriteBackViewConstantsMasked24);
    fwrite(&codesize[3], 2, 1, fp);
    FAR_fwrite((byte __far *)R_WriteBackViewConstantsMasked24, codesize[3], 1, fp); 

    codesize[21] = FP_OFF(R_MASK16_ENDMARKER) - FP_OFF(R_WriteBackViewConstantsMasked16);
    fwrite(&codesize[21], 2, 1, fp);
    FAR_fwrite((byte __far *)R_WriteBackViewConstantsMasked16, codesize[21], 1, fp); 

    codesize[18] = FP_OFF(R_MASK0_ENDMARKER) - FP_OFF(R_WriteBackViewConstantsMasked0);
    fwrite(&codesize[18], 2, 1, fp);
    FAR_fwrite((byte __far *)R_WriteBackViewConstantsMasked0, codesize[18], 1, fp); 

    codesize[26] = FP_OFF(R_MASKFL_ENDMARKER) - FP_OFF(R_WriteBackViewConstantsMaskedFL);
    fwrite(&codesize[26], 2, 1, fp);
    FAR_fwrite((byte __far *)R_WriteBackViewConstantsMaskedFL, codesize[26], 1, fp); 


    codesize[4] = FP_OFF(R_SKY_ENDMARKER) - FP_OFF(R_SKY_STARTMARKER);
    fwrite(&codesize[4], 2, 1, fp);
    FAR_fwrite((byte __far *)R_SKY_STARTMARKER, codesize[4], 1, fp);

    codesize[28] = FP_OFF(R_SKYFL_ENDMARKER) - FP_OFF(R_SKYFL_STARTMARKER);
    fwrite(&codesize[28], 2, 1, fp);
    FAR_fwrite((byte __far *)R_SKYFL_STARTMARKER, codesize[28], 1, fp);

    codesize[12] = FP_OFF(R_BSP24_ENDMARKER) - FP_OFF(R_BSP24_STARTMARKER);
    fwrite(&codesize[12], 2, 1, fp);
    FAR_fwrite((byte __far *)R_BSP24_STARTMARKER, codesize[12], 1, fp);

    codesize[22] = FP_OFF(R_BSP16_ENDMARKER) - FP_OFF(R_BSP16_STARTMARKER);
    fwrite(&codesize[22], 2, 1, fp);
    FAR_fwrite((byte __far *)R_BSP16_STARTMARKER, codesize[22], 1, fp);

    codesize[16] = FP_OFF(R_BSP0_ENDMARKER) - FP_OFF(R_BSP0_STARTMARKER);
    fwrite(&codesize[16], 2, 1, fp);
    FAR_fwrite((byte __far *)R_BSP0_STARTMARKER, codesize[16], 1, fp);

    codesize[27] = FP_OFF(R_BSPFL_ENDMARKER) - FP_OFF(R_BSPFL_STARTMARKER);
    fwrite(&codesize[27], 2, 1, fp);
    FAR_fwrite((byte __far *)R_BSPFL_STARTMARKER, codesize[27], 1, fp);


    codesize[5] = FP_OFF(WI_ENDMARKER) - FP_OFF(WI_STARTMARKER);
    fwrite(&codesize[5], 2, 1, fp);
    FAR_fwrite((byte __far *)WI_STARTMARKER, codesize[5], 1, fp);


    codesize[6] = FP_OFF(P_INFO_ENDMARKER) - FP_OFF(P_SIGHT_STARTMARKER);
    fwrite(&codesize[6], 2, 1, fp);
    FAR_fwrite((byte __far *)P_SIGHT_STARTMARKER, codesize[6], 1, fp);


    codesize[7] = FP_OFF(F_WIPE_ENDMARKER) - FP_OFF(F_WIPE_STARTMARKER);
    fwrite(&codesize[7], 2, 1, fp);
    FAR_fwrite((byte __far *)I_ReadScreen, codesize[7], 1, fp);

    codesize[8] = FP_OFF(F_END) - FP_OFF(F_START);
    fwrite(&codesize[8], 2, 1, fp);
    FAR_fwrite((byte __far *)F_START, codesize[8], 1, fp);

    codesize[9] = FP_OFF(P_LOADEND) - FP_OFF(P_LOADSTART);
    fwrite(&codesize[9], 2, 1, fp);
    FAR_fwrite((byte __far *)P_LOADSTART, codesize[9], 1, fp);

    codesize[10] = FP_OFF(SM_LOAD_ENDMARKER) - FP_OFF(SM_LOAD_STARTMARKER);
    fwrite(&codesize[10], 2, 1, fp);
    FAR_fwrite((byte __far *)SM_LOAD_STARTMARKER, codesize[10], 1, fp);

    codesize[11] = FP_OFF(S_INIT_ENDMARKER) - FP_OFF(S_INIT_STARTMARKER);
    fwrite(&codesize[11], 2, 1, fp);
    FAR_fwrite((byte __far *)S_INIT_STARTMARKER, codesize[11], 1, fp);


    muscodesize[0] = FP_OFF(SM_OPL2_ENDMARKER) - FP_OFF(SM_OPL2_STARTMARKER);
    fwrite(&muscodesize[0], 2, 1, fp);
    FAR_fwrite((byte __far *)SM_OPL2_STARTMARKER, muscodesize[0], 1, fp);
    maxmuscodesize = muscodesize[0] > maxmuscodesize ? muscodesize[0] : maxmuscodesize;

    muscodesize[1] = FP_OFF(SM_OPL3_ENDMARKER) - FP_OFF(SM_OPL3_STARTMARKER);
    fwrite(&muscodesize[1], 2, 1, fp);
    FAR_fwrite((byte __far *)SM_OPL3_STARTMARKER, muscodesize[1], 1, fp);
    maxmuscodesize = muscodesize[1] > maxmuscodesize ? muscodesize[1] : maxmuscodesize;

    muscodesize[2] = FP_OFF(SM_MPUMD_ENDMARKER) - FP_OFF(SM_MPUMD_STARTMARKER);
    fwrite(&muscodesize[2], 2, 1, fp);
    FAR_fwrite((byte __far *)SM_MPUMD_STARTMARKER, muscodesize[2], 1, fp);
    maxmuscodesize = muscodesize[2] > maxmuscodesize ? muscodesize[2] : maxmuscodesize;

    muscodesize[3] = FP_OFF(SM_SBMID_ENDMARKER) - FP_OFF(SM_SBMID_STARTMARKER);
    fwrite(&muscodesize[3], 2, 1, fp);
    FAR_fwrite((byte __far *)SM_SBMID_STARTMARKER, muscodesize[3], 1, fp);
    maxmuscodesize = muscodesize[3] > maxmuscodesize ? muscodesize[3] : maxmuscodesize;


    fclose(fp);
    
    printf("Generated doomcode.bin file\n");

    // todo many of these not used? clean up?
    fp = fopen("m_offset.h", "wb");
	// bsp offsets

    // masked offsets
	fprintf(fp, "#define R_DrawMasked24Offset                    0x%X\n", FP_OFF(R_DrawMasked24)                    - FP_OFF(R_MASK24_STARTMARKER));
	fprintf(fp, "#define R_DrawMasked16Offset                    0x%X\n", FP_OFF(R_DrawMasked16)                    - FP_OFF(R_MASK16_STARTMARKER));
	fprintf(fp, "#define R_DrawMasked0Offset                     0x%X\n", FP_OFF(R_DrawMasked0)                     - FP_OFF(R_MASK0_STARTMARKER));
	fprintf(fp, "#define R_DrawMaskedFLOffset                    0x%X\n", FP_OFF(R_DrawMaskedFL)                    - FP_OFF(R_MASKFL_STARTMARKER));

    // masked selfmodifying code offsets
    fprintf(fp, "#define R_WriteBackViewConstantsMasked24Offset  0x%X\n", FP_OFF(R_WriteBackViewConstantsMasked24)  - FP_OFF(R_WriteBackViewConstantsMasked24));
    fprintf(fp, "#define R_WriteBackMaskedFrameConstants24Offset 0x%X\n", FP_OFF(R_WriteBackMaskedFrameConstants24) - FP_OFF(R_WriteBackViewConstantsMasked24));
    fprintf(fp, "#define R_WriteBackViewConstantsMasked16Offset  0x%X\n", FP_OFF(R_WriteBackViewConstantsMasked16)  - FP_OFF(R_WriteBackViewConstantsMasked16));
    fprintf(fp, "#define R_WriteBackMaskedFrameConstants16Offset 0x%X\n", FP_OFF(R_WriteBackMaskedFrameConstants16) - FP_OFF(R_WriteBackViewConstantsMasked16));
    fprintf(fp, "#define R_WriteBackViewConstantsMasked0Offset   0x%X\n", FP_OFF(R_WriteBackViewConstantsMasked0)   - FP_OFF(R_WriteBackViewConstantsMasked0));
    fprintf(fp, "#define R_WriteBackMaskedFrameConstants0Offset  0x%X\n", FP_OFF(R_WriteBackMaskedFrameConstants0)  - FP_OFF(R_WriteBackViewConstantsMasked0));
    fprintf(fp, "#define R_WriteBackViewConstantsMaskedFLOffset  0x%X\n", FP_OFF(R_WriteBackViewConstantsMaskedFL)  - FP_OFF(R_WriteBackViewConstantsMaskedFL));
    fprintf(fp, "#define R_WriteBackMaskedFrameConstantsFLOffset 0x%X\n", FP_OFF(R_WriteBackMaskedFrameConstantsFL) - FP_OFF(R_WriteBackViewConstantsMaskedFL));
    

    // span offsets
	fprintf(fp, "#define R_DrawPlanes24Offset                    0x%X\n", FP_OFF(R_DrawPlanes24)                    - FP_OFF(R_SPAN24_STARTMARKER));
	fprintf(fp, "#define R_WriteBackViewConstantsSpan24Offset    0x%X\n", FP_OFF(R_WriteBackViewConstantsSpan24)    - FP_OFF(R_SPAN24_STARTMARKER));

	fprintf(fp, "#define R_DrawPlanes16Offset                    0x%X\n", FP_OFF(R_DrawPlanes16)                    - FP_OFF(R_SPAN16_STARTMARKER));
	fprintf(fp, "#define R_WriteBackViewConstantsSpan16Offset    0x%X\n", FP_OFF(R_WriteBackViewConstantsSpan16)    - FP_OFF(R_SPAN16_STARTMARKER));

	fprintf(fp, "#define R_DrawPlanes0Offset                     0x%X\n", FP_OFF(R_DrawPlanes0)                     - FP_OFF(R_SPAN0_STARTMARKER));
	fprintf(fp, "#define R_WriteBackViewConstantsSpan0Offset     0x%X\n", FP_OFF(R_WriteBackViewConstantsSpan0)     - FP_OFF(R_SPAN0_STARTMARKER));

	fprintf(fp, "#define R_DrawPlanesFLOffset                    0x%X\n", FP_OFF(R_DrawPlanesFL)                    - FP_OFF(R_SPANFL_STARTMARKER));
	fprintf(fp, "#define R_WriteBackViewConstantsSpanFLOffset    0x%X\n", FP_OFF(R_WriteBackViewConstantsSpanFL)    - FP_OFF(R_SPANFL_STARTMARKER));

    // sky offsets
	fprintf(fp, "#define R_DrawSkyColumnOffset                   0x%X\n", FP_OFF(R_DrawSkyColumn)                   - FP_OFF(R_SKY_STARTMARKER));
	fprintf(fp, "#define R_DrawSkyPlaneOffset                    0x%X\n", FP_OFF(R_DrawSkyPlane)                    - FP_OFF(R_SKY_STARTMARKER));
	fprintf(fp, "#define R_DrawSkyPlaneDynamicOffset             0x%X\n", FP_OFF(R_DrawSkyPlaneDynamic)             - FP_OFF(R_SKY_STARTMARKER));
	fprintf(fp, "#define R_DrawSkyColumnFLOffset                 0x%X\n", FP_OFF(R_DrawSkyColumnFL)                 - FP_OFF(R_SKYFL_STARTMARKER));
	fprintf(fp, "#define R_DrawSkyPlaneFLOffset                  0x%X\n", FP_OFF(R_DrawSkyPlaneFL)                  - FP_OFF(R_SKYFL_STARTMARKER));
	fprintf(fp, "#define R_DrawSkyPlaneDynamicFLOffset           0x%X\n", FP_OFF(R_DrawSkyPlaneDynamicFL)           - FP_OFF(R_SKYFL_STARTMARKER));



    // BSP offsets
	fprintf(fp, "#define R_WriteBackViewConstants24Offset        0x%X\n", FP_OFF(R_WriteBackViewConstants24)        - FP_OFF(R_BSP24_STARTMARKER));
	fprintf(fp, "#define R_RenderPlayerView24Offset              0x%X\n", FP_OFF(R_RenderPlayerView24)              - FP_OFF(R_BSP24_STARTMARKER));
	fprintf(fp, "#define R_GetCompositeTexture24Offset           0x%X\n", FP_OFF(R_GetCompositeTexture_Far24)       - FP_OFF(R_BSP24_STARTMARKER));
	fprintf(fp, "#define R_GetPatchTexture24Offset               0x%X\n", FP_OFF(R_GetPatchTexture_Far24)           - FP_OFF(R_BSP24_STARTMARKER));


	fprintf(fp, "#define R_WriteBackViewConstants16Offset        0x%X\n", FP_OFF(R_WriteBackViewConstants16)        - FP_OFF(R_BSP16_STARTMARKER));
	fprintf(fp, "#define R_RenderPlayerView16Offset              0x%X\n", FP_OFF(R_RenderPlayerView16)              - FP_OFF(R_BSP16_STARTMARKER));
	fprintf(fp, "#define R_GetCompositeTexture16Offset           0x%X\n", FP_OFF(R_GetCompositeTexture_Far16)       - FP_OFF(R_BSP16_STARTMARKER));
	fprintf(fp, "#define R_GetPatchTexture16Offset               0x%X\n", FP_OFF(R_GetPatchTexture_Far16)           - FP_OFF(R_BSP16_STARTMARKER));

	fprintf(fp, "#define R_WriteBackViewConstants0Offset         0x%X\n", FP_OFF(R_WriteBackViewConstants0)         - FP_OFF(R_BSP0_STARTMARKER));
	fprintf(fp, "#define R_RenderPlayerView0Offset               0x%X\n", FP_OFF(R_RenderPlayerView0)               - FP_OFF(R_BSP0_STARTMARKER));
	fprintf(fp, "#define R_GetCompositeTexture0Offset            0x%X\n", FP_OFF(R_GetCompositeTexture_Far0)        - FP_OFF(R_BSP0_STARTMARKER));
	fprintf(fp, "#define R_GetPatchTexture0Offset                0x%X\n", FP_OFF(R_GetPatchTexture_Far0)            - FP_OFF(R_BSP0_STARTMARKER));

	fprintf(fp, "#define R_WriteBackViewConstantsFLOffset        0x%X\n", FP_OFF(R_WriteBackViewConstantsFL)        - FP_OFF(R_BSPFL_STARTMARKER));
	fprintf(fp, "#define R_RenderPlayerViewFLOffset              0x%X\n", FP_OFF(R_RenderPlayerViewFL)              - FP_OFF(R_BSPFL_STARTMARKER));
	fprintf(fp, "#define R_GetCompositeTextureFLOffset           0x%X\n", FP_OFF(R_GetCompositeTexture_FarFL)       - FP_OFF(R_BSPFL_STARTMARKER));
	fprintf(fp, "#define R_GetPatchTextureFLOffset               0x%X\n", FP_OFF(R_GetPatchTexture_FarFL)           - FP_OFF(R_BSPFL_STARTMARKER));


    // intermission/ wi stuff offsets
    fprintf(fp, "#define WI_StartOffset                          0x%X\n", FP_OFF(WI_Start)                          - FP_OFF(WI_STARTMARKER));
    fprintf(fp, "#define WI_TickerOffset                         0x%X\n", FP_OFF(WI_Ticker)                         - FP_OFF(WI_STARTMARKER));
    fprintf(fp, "#define WI_DrawerOffset                         0x%X\n", FP_OFF(WI_Drawer)                         - FP_OFF(WI_STARTMARKER));


    // wipe offsets
    fprintf(fp, "#define wipe_StartScreenOffset                  0x%X\n", FP_OFF(wipe_StartScreen)                  - FP_OFF(I_ReadScreen));
	fprintf(fp, "#define wipe_WipeLoopOffset                     0x%X\n", FP_OFF(wipe_WipeLoop)                     - FP_OFF(I_ReadScreen));

    // finale offsets
    fprintf(fp, "#define F_StartFinaleOffset                     0x%X\n", FP_OFF(F_StartFinale)                     - FP_OFF(F_START));
    fprintf(fp, "#define F_ResponderOffset                       0x%X\n", FP_OFF(F_Responder)                       - FP_OFF(F_START));
    fprintf(fp, "#define F_TickerOffset                          0x%X\n", FP_OFF(F_Ticker)                          - FP_OFF(F_START));
    fprintf(fp, "#define F_DrawerOffset                          0x%X\n", FP_OFF(F_Drawer)                          - FP_OFF(F_START));

    // load offsets
    fprintf(fp, "#define P_UnArchivePlayersOffset                0x%X\n", FP_OFF(P_UnArchivePlayers)                - FP_OFF(P_LOADSTART));
    fprintf(fp, "#define P_UnArchiveWorldOffset                  0x%X\n", FP_OFF(P_UnArchiveWorld)                  - FP_OFF(P_LOADSTART));
    fprintf(fp, "#define P_UnArchiveThinkersOffset               0x%X\n", FP_OFF(P_UnArchiveThinkers)               - FP_OFF(P_LOADSTART));
    fprintf(fp, "#define P_UnArchiveSpecialsOffset               0x%X\n", FP_OFF(P_UnArchiveSpecials)               - FP_OFF(P_LOADSTART));
    fprintf(fp, "#define P_ArchivePlayersOffset                  0x%X\n", FP_OFF(P_ArchivePlayers)                  - FP_OFF(P_LOADSTART));
    fprintf(fp, "#define P_ArchiveWorldOffset                    0x%X\n", FP_OFF(P_ArchiveWorld)                    - FP_OFF(P_LOADSTART));
    fprintf(fp, "#define P_ArchiveThinkersOffset                 0x%X\n", FP_OFF(P_ArchiveThinkers)                 - FP_OFF(P_LOADSTART));
    fprintf(fp, "#define P_ArchiveSpecialsOffset                 0x%X\n", FP_OFF(P_ArchiveSpecials)                 - FP_OFF(P_LOADSTART));

    // s_init offsets
    fprintf(fp, "#define LoadSFXWadLumpsOffset                   0x%X\n", FP_OFF(LoadSFXWadLumps)                   - FP_OFF(S_INIT_STARTMARKER));

    // musload offset
    fprintf(fp, "#define S_ActuallyChangeMusicOffset             0x%X\n", FP_OFF(S_ActuallyChangeMusic)             - FP_OFF(SM_LOAD_STARTMARKER));

    // physics high code offsets
    fprintf(fp, "#define P_CheckSightOffset                      0x%X\n", FP_OFF(P_CheckSight)                      - FP_OFF(P_SIGHT_STARTMARKER));
    fprintf(fp, "#define P_SetThingPositionFarOffset             0x%X\n", FP_OFF(P_SetThingPositionFar)             - FP_OFF(P_SIGHT_STARTMARKER));
    fprintf(fp, "#define R_PointInSubsectorOffset                0x%X\n", FP_OFF(R_PointInSubsector)                - FP_OFF(P_SIGHT_STARTMARKER));
    
    fprintf(fp, "#define P_CheckPositionOffset                   0x%X\n", FP_OFF(P_CheckPosition)                   - FP_OFF(P_SIGHT_STARTMARKER));
    fprintf(fp, "#define P_UseLinesOffset                        0x%X\n", FP_OFF(P_UseLines)                        - FP_OFF(P_SIGHT_STARTMARKER));
    fprintf(fp, "#define P_ChangeSectorOffset                    0x%X\n", FP_OFF(P_ChangeSector)                    - FP_OFF(P_SIGHT_STARTMARKER));
    
    // fprintf(fp, "#define P_SpawnPuffOffset                     0x%X\n", FP_OFF(P_SpawnPuff)                    - FP_OFF(P_SIGHT_STARTMARKER));
    fprintf(fp, "#define P_ExplodeMissileOffset                  0x%X\n", FP_OFF(P_ExplodeMissile)                  - FP_OFF(P_SIGHT_STARTMARKER));
    fprintf(fp, "#define P_SpawnPlayerMissileOffset              0x%X\n", FP_OFF(P_SpawnPlayerMissile)              - FP_OFF(P_SIGHT_STARTMARKER));

    fprintf(fp, "#define P_MovePspritesOffset                    0x%X\n", FP_OFF(P_MovePsprites)                    - FP_OFF(P_SIGHT_STARTMARKER));

    fprintf(fp, "#define P_RemoveMobjOffset                      0x%X\n", FP_OFF(P_RemoveMobj)                      - FP_OFF(P_SIGHT_STARTMARKER));
    fprintf(fp, "#define P_SpawnMapThingOffset                   0x%X\n", FP_OFF(P_SpawnMapThing)                   - FP_OFF(P_SIGHT_STARTMARKER));
    
    fprintf(fp, "#define P_TickerOffset                          0x%X\n", FP_OFF(P_Ticker      )                    - FP_OFF(P_SIGHT_STARTMARKER));
    fprintf(fp, "#define P_SpawnSpecialsOffset                   0x%X\n", FP_OFF(P_SpawnSpecials)                   - FP_OFF(P_SIGHT_STARTMARKER));
    fprintf(fp, "#define P_GivePowerOffset                       0x%X\n", FP_OFF(P_GivePower)                        - FP_OFF(P_SIGHT_STARTMARKER));
    


	fprintf(fp, "\n");
 
	fprintf(fp, "#define R_DrawColumn24CodeSize         0x%X\n", codesize[0]);
	fprintf(fp, "#define R_DrawColumn16CodeSize         0x%X\n", codesize[19]);
	fprintf(fp, "#define R_DrawColumn0CodeSize          0x%X\n", codesize[15]);
	fprintf(fp, "#define R_DrawColumnFLCodeSize         0x%X\n", codesize[24]);
    fprintf(fp, "#define R_DrawSpan24CodeSize           0x%X\n", codesize[1]);
    fprintf(fp, "#define R_DrawSpan16CodeSize           0x%X\n", codesize[13]);
    fprintf(fp, "#define R_DrawSpan0CodeSize            0x%X\n", codesize[14]);
    fprintf(fp, "#define R_DrawSpanFLCodeSize           0x%X\n", codesize[23]);
	fprintf(fp, "#define R_DrawFuzzColumn24CodeSize     0x%X\n", codesize[2]);
	fprintf(fp, "#define R_DrawFuzzColumn16CodeSize     0x%X\n", codesize[20]);
	fprintf(fp, "#define R_DrawFuzzColumn0CodeSize      0x%X\n", codesize[17]);
	fprintf(fp, "#define R_DrawFuzzColumnFLCodeSize     0x%X\n", codesize[25]);
	fprintf(fp, "#define R_MaskedConstants24CodeSize    0x%X\n", codesize[3]);
	fprintf(fp, "#define R_MaskedConstants16CodeSize    0x%X\n", codesize[21]);
	fprintf(fp, "#define R_MaskedConstants0CodeSize     0x%X\n", codesize[18]);
	fprintf(fp, "#define R_MaskedConstantsFLCodeSize    0x%X\n", codesize[26]);
	fprintf(fp, "#define R_DrawSkyColumnCodeSize        0x%X\n", codesize[4]);
	fprintf(fp, "#define R_DrawSkyColumnFLCodeSize      0x%X\n", codesize[28]);
	fprintf(fp, "#define R_BSP24CodeSize                0x%X\n", codesize[12]);
	fprintf(fp, "#define R_BSP16CodeSize                0x%X\n", codesize[22]);
	fprintf(fp, "#define R_BSP0CodeSize                 0x%X\n", codesize[16]);
	fprintf(fp, "#define R_BSPFLCodeSize                0x%X\n", codesize[27]);

	fprintf(fp, "#define WI_StuffCodeSize               0x%X\n", codesize[5]);
	fprintf(fp, "#define PSightCodeSize                 0x%X\n", codesize[6]);
	fprintf(fp, "#define WipeCodeSize                   0x%X\n", codesize[7]);
	fprintf(fp, "#define FinaleCodeSize                 0x%X\n", codesize[8]);
	fprintf(fp, "#define SaveLoadCodeSize               0x%X\n", codesize[9]);
	fprintf(fp, "#define SMLoadCodeSize                 0x%X\n", codesize[10]);
	fprintf(fp, "#define SInitCodeSize                  0x%X\n", codesize[11]);
	fprintf(fp, "#define MaximumMusDriverSize           0x%X\n", maxmuscodesize);
    fclose(fp);


    printf("Generated m_offset.h file\n");

    fp = fopen("m_offset.inc", "wb");
	fprintf(fp, "R_DRAWPLANES24OFFSET = 0%Xh\n",                    FP_OFF(R_DrawPlanes24)                    - FP_OFF(R_SPAN24_STARTMARKER));
	fprintf(fp, "R_DRAWPLANES16OFFSET = 0%Xh\n",                    FP_OFF(R_DrawPlanes16)                    - FP_OFF(R_SPAN16_STARTMARKER));
	fprintf(fp, "R_DRAWPLANES0OFFSET = 0%Xh\n",                     FP_OFF(R_DrawPlanes0)                     - FP_OFF(R_SPAN0_STARTMARKER));
	fprintf(fp, "R_DRAWPLANESFLOFFSET = 0%Xh\n",                    FP_OFF(R_DrawPlanesFL)                    - FP_OFF(R_SPANFL_STARTMARKER));
	fprintf(fp, "R_GETCOMPOSITETEXTURE24OFFSET = 0%Xh\n",           FP_OFF(R_GetCompositeTexture_Far24)       - FP_OFF(R_BSP24_STARTMARKER));
	fprintf(fp, "R_GETPATCHTEXTURE24OFFSET = 0%Xh\n",               FP_OFF(R_GetPatchTexture_Far24)           - FP_OFF(R_BSP24_STARTMARKER));
	fprintf(fp, "R_DRAWMASKED24OFFSET = 0%Xh\n",                    FP_OFF(R_DrawMasked24)                    - FP_OFF(R_MASK24_STARTMARKER));
	fprintf(fp, "R_DRAWMASKED16OFFSET = 0%Xh\n",                    FP_OFF(R_DrawMasked16)                   - FP_OFF(R_MASK16_STARTMARKER));
	fprintf(fp, "R_DRAWMASKED0OFFSET = 0%Xh\n",                     FP_OFF(R_DrawMasked0)                     - FP_OFF(R_MASK0_STARTMARKER));
	fprintf(fp, "R_DRAWMASKEDFLOFFSET = 0%Xh\n",                    FP_OFF(R_DrawMaskedFL)                    - FP_OFF(R_MASKFL_STARTMARKER));
    fprintf(fp, "R_WRITEBACKMASKEDFRAMECONSTANTS24OFFSET = 0%Xh\n", FP_OFF(R_WriteBackMaskedFrameConstants24) - FP_OFF(R_WriteBackViewConstantsMasked24));
    fprintf(fp, "P_CHECKPOSITIONOFFSET = 0%Xh\n",                   FP_OFF(P_CheckPosition)                   - FP_OFF(P_SIGHT_STARTMARKER));
    fprintf(fp, "R_POINTINSUBSECTOROFFSET = 0%Xh\n",                FP_OFF(R_PointInSubsector)                - FP_OFF(P_SIGHT_STARTMARKER));
    
    fprintf(fp, "F_RESPONDEROFFSET = 0%Xh\n",                       FP_OFF(F_Responder)                       - FP_OFF(F_START));
    fprintf(fp, "P_SETTHINGPOSITIONFAROFFSET = 0%Xh\n",             FP_OFF(P_SetThingPositionFar)             - FP_OFF(P_SIGHT_STARTMARKER));

    fprintf(fp, "P_REMOVEMOBJOFFSET = 0%Xh\n",                      FP_OFF(P_RemoveMobj)                      - FP_OFF(P_SIGHT_STARTMARKER));
    fprintf(fp, "P_SPAWNMAPTHINGOFFSET = 0%Xh\n",                   FP_OFF(P_SpawnMapThing)                   - FP_OFF(P_SIGHT_STARTMARKER));
    fprintf(fp, "P_CREATETHINKEROFFSET = 0%Xh\n",                   FP_OFF(P_CreateThinker)                   - FP_OFF(P_SIGHT_STARTMARKER));
    fprintf(fp, "P_ADDACTIVECEILINGOFFSET = 0%Xh\n",                FP_OFF(P_AddActiveCeiling)                - FP_OFF(P_SIGHT_STARTMARKER));
    fprintf(fp, "P_ADDACTIVEPLATOFFSET = 0%Xh\n",                   FP_OFF(P_AddActivePlat)                   - FP_OFF(P_SIGHT_STARTMARKER));
    
    fprintf(fp, "P_REMOVETHINKEROFFSET = 0%Xh\n",                   FP_OFF(P_RemoveThinker)                   - FP_OFF(P_SIGHT_STARTMARKER));


	// P_AddActiveCeiling_addr =		 	(uint32_t)(P_AddActiveCeiling);
	// P_AddActivePlat_addr =		 		(uint32_t)(P_AddActivePlat);
    // P_UseSpecialLine_addr =				(uint32_t)(P_UseSpecialLine);
	// P_DamageMobj_addr =					(uint32_t)(P_DamageMobj);
	
    // P_CrossSpecialLine_addr =			(uint32_t)(P_CrossSpecialLine);
	// P_ShootSpecialLine_addr =			(uint32_t)(P_ShootSpecialLine);
	// P_TouchSpecialThing_addr =			(uint32_t)(P_TouchSpecialThing);
	// P_RemoveThinker_addr =				(uint32_t)(P_RemoveThinker);
	// EV_DoDoor_addr =					(uint32_t)(EV_DoDoor);
 	// EV_DoFloor_addr =					(uint32_t)(EV_DoFloor);



    fclose(fp);
    printf("Generated m_offset.inc file\n");
 
    return 0;
} 

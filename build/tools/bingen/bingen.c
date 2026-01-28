#include "constant.h"
#include "z_zone.h"

#include "w_wad.h"


#include <dos.h>
#include <conio.h>
#include <stdio.h>

#include <stdlib.h>
#include "m_memory.h"

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
int16_t __far wipe_doMelt(int16_t ticks);
void __far wipe_WipeLoop();
void __far wipe_StartScreen();
void __far D_ALGO_END();

void __far R_SKY_STARTMARKER();
void __far R_SKY_ENDMARKER();
void __far R_DrawSkyColumn(int16_t arg_dc_yh, int16_t arg_dc_yl);
void __far R_DrawSkyPlane();
void __far R_DrawSkyPlaneDynamic();

void __far R_SKYFL_STARTMARKER();
void __far R_SKYFL_ENDMARKER();
void __far R_DrawSkyColumnFL(int16_t arg_dc_yh, int16_t arg_dc_yl);
void __far R_DrawSkyPlaneFL();
void __far R_DrawSkyPlaneDynamicFL();

void __far P_AddActivePlat();
void __far P_AddActiveCeiling();

void __far R_WriteBackViewConstantsSpan();
void __far V_DrawPatchFlipped();
void __far F_StartFinale();
void __far F_Drawer();
void __far F_Responder();
void __far F_Ticker();
void __far F_FINALE_STARTMARKER();
void __far F_FINALE_ENDMARKER();
void __far P_SAVEG_STARTMARKER();
void __far P_SAVEG_ENDMARKER();
void __far G_ContinueLoadGame();
void __far G_ContinueSaveGame();
void __far WI_STARTMARKER();
void __far WI_ENDMARKER();
void __far S_SOUND_ENDMARKER();
void __far SM_LOAD_STARTMARKER();
void __far SM_LOAD_ENDMARKER();
void __far S_ActuallyChangeMusic();

void __far P_SETUP_STARTMARKER();
void __far P_SETUP_ENDMARKER();
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
void __far AM_Responder();
void __far AM_Drawer();
void __far AM_Ticker();
void __far S_UpdateSounds();
void __far S_Start();
void __far S_StartSoundFar();
void __far S_StartSoundAX0Far();


void __far P_AproxDistance();
void __far P_SetThingPositionFar();
void __far P_BlockThingsIterator();
void __far P_PathTraverse();
void __far P_TryMove();
void __far P_CheckPosition();
void __far P_SlideMove();
void __far P_TeleportMove();
void __far P_UseLines();


void __far P_RemoveMobjFar();
void __far P_SpawnMapThing();


void __far F_WIPE_STARTMARKER();
void __far F_WIPE_ENDMARKER();


void __far WI_Ticker();
void __far WI_Drawer();
void __far G_DoCompleted();

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

void __far GetPainChance();
void __far GetRaiseState();
void __far GetXDeathState();
void __far GetMeleeState();
void __far GetMobjMass();
void __far GetActiveSound();
void __far GetPainSound();
void __far GetAttackSound();
void __far GetDamage();
void __far GetSeeState();
void __far GetMissileState();
void __far GetDeathState();
void __far GetPainState();
void __far GetSpawnHealth();
void __far P_CreateThinkerFar();

void __far M_MENU_STARTMARKER();
void __far M_MENU_ENDMARKER();
void __far M_Init();
void __far M_Responder ();
void __far G_Responder ();
void __far M_StartControlPanel();

void __far M_Drawer();
void __far M_LoadFromSaveGame();
void __far M_DrawPause();
void __far FixedDivWholeA_MapLocal_FAR();
void __far R_PointToAngle2_FAR();

void __far HU_Ticker();
void __far HU_Responder();
void __far HU_Drawer();
void __far HU_Erase();
void __far R_DrawViewBorder();
void __far V_DrawPatchDirect();
void __far R_FillBackScreen();
void __far V_CopyRect();
void __far P_SetupLevel();

void __far ST_Start();
void __far ST_Init();
void __far ST_Ticker();
void __far ST_Drawer();
void __far ST_Responder();


void __far _arms();
void __far _armsbg();
void __far _armsbgarray();
void __far _faces();
void __far _keys();
void __far _shortnum();
void __far _tallnum();
void __far _sbar();
void __far _faceback();
void __far _tallpercent();

void __far MARKER_SELFMODIFY_COLFUNC_set_destview_segment0();
void __far MARKER_SELFMODIFY_COLFUNC_jump_offset0();
void __far MARKER_SELFMODIFY_COLFUNC_subtract_centery16();
void __far MARKER_SELFMODIFY_COLFUNC_set_destview_segment16();
void __far MARKER_SELFMODIFY_COLFUNC_jump_offset16();
void __far MARKER_SELFMODIFY_COLFUNC_subtract_centery24_1();
void __far MARKER_SELFMODIFY_COLFUNC_subtract_centery24_2();
void __far MARKER_SELFMODIFY_COLFUNC_set_destview_segment24();
void __far MARKER_SELFMODIFY_COLFUNC_jump_offset24();
void __far MARKER_SELFMODIFY_COLFUNC_set_destview_segment24_noloop();
void __far MARKER_SELFMODIFY_COLFUNC_jump_offset24_noloop();
void __far MARKER_COLFUNC_NOLOOP_FUNCTION_AREA_OFFSET();
void __far MARKER_COLFUNC_NOLOOP_JUMPTABLE_SIZE_OFFSET();
void __far MARKER_COLFUNC_JUMP_TARGET24();
void __far MARKER_SELFMODIFY_COLFUNC_set_destview_segmentFL();
void __far MARKER_SELFMODIFY_COLFUNC_jump_offsetFL();

filelength_t  __near locallib_far_fwrite(void __far* src, uint16_t elementsizetimeselementcount, FILE * fp);


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
	uint16_t codesize[31];
	uint16_t muscodesize[4];
	uint16_t maxmuscodesize = 0;
    int8_t i;
    
    codesize[0] = FP_OFF(R_COLUMN24_ENDMARKER) - FP_OFF(R_COLUMN24_STARTMARKER);
    // write filesize..
    fwrite(&codesize[0], 2, 1, fp);
    // write data
    locallib_far_fwrite((byte __far *)R_COLUMN24_STARTMARKER, codesize[0], fp);
    
    codesize[19] = FP_OFF(R_COLUMN16_ENDMARKER) - FP_OFF(R_COLUMN16_STARTMARKER);
    // write filesize..
    fwrite(&codesize[19], 2, 1, fp);
    // write data
    locallib_far_fwrite((byte __far *)R_COLUMN16_STARTMARKER, codesize[19], fp);

    codesize[15] = FP_OFF(R_COLUMN0_ENDMARKER) - FP_OFF(R_COLUMN0_STARTMARKER);
    fwrite(&codesize[15], 2, 1, fp);
    locallib_far_fwrite((byte __far *)R_COLUMN0_STARTMARKER, codesize[15], fp);

    codesize[24] = FP_OFF(R_COLUMNFL_ENDMARKER) - FP_OFF(R_COLUMNFL_STARTMARKER);
    fwrite(&codesize[24], 2, 1, fp);
    locallib_far_fwrite((byte __far *)R_COLUMNFL_STARTMARKER, codesize[24], fp);

    
    codesize[1] = FP_OFF(R_SPAN24_ENDMARKER) - FP_OFF(R_SPAN24_STARTMARKER);
    fwrite(&codesize[1], 2, 1, fp); // write filesize..
    locallib_far_fwrite((byte __far *)R_SPAN24_STARTMARKER, codesize[1], fp); // write data
    
    codesize[13] = FP_OFF(R_SPAN16_ENDMARKER) - FP_OFF(R_SPAN16_STARTMARKER);    
    fwrite(&codesize[13], 2, 1, fp); // write filesize..
    locallib_far_fwrite((byte __far *)R_SPAN16_STARTMARKER, codesize[13], fp); // write data
    
    codesize[14] = FP_OFF(R_SPAN0_ENDMARKER) - FP_OFF(R_SPAN0_STARTMARKER);    
    fwrite(&codesize[14], 2, 1, fp); // write filesize..
    locallib_far_fwrite((byte __far *)R_SPAN0_STARTMARKER, codesize[14], fp); // write data

    codesize[23] = FP_OFF(R_SPANFL_ENDMARKER) - FP_OFF(R_SPANFL_STARTMARKER);
    fwrite(&codesize[23], 2, 1, fp); // write filesize..
    locallib_far_fwrite((byte __far *)R_SPANFL_STARTMARKER, codesize[23], fp); // write data


    codesize[2] = FP_OFF(R_WriteBackViewConstantsMasked24) - FP_OFF(R_MASK24_STARTMARKER);
    fwrite(&codesize[2], 2, 1, fp);
    locallib_far_fwrite((byte __far *)R_MASK24_STARTMARKER, codesize[2], fp);


    codesize[20] = FP_OFF(R_WriteBackViewConstantsMasked16) - FP_OFF(R_MASK16_STARTMARKER);
    fwrite(&codesize[20], 2, 1, fp);
    locallib_far_fwrite((byte __far *)R_MASK16_STARTMARKER, codesize[20], fp);

    codesize[17] = FP_OFF(R_WriteBackViewConstantsMasked0) - FP_OFF(R_MASK0_STARTMARKER);
    fwrite(&codesize[17], 2, 1, fp);
    locallib_far_fwrite((byte __far *)R_MASK0_STARTMARKER, codesize[17], fp);

    codesize[25] = FP_OFF(R_WriteBackViewConstantsMaskedFL) - FP_OFF(R_MASKFL_STARTMARKER);
    fwrite(&codesize[25], 2, 1, fp);
    locallib_far_fwrite((byte __far *)R_MASKFL_STARTMARKER, codesize[25], fp);

    codesize[3] = FP_OFF(R_MASK24_ENDMARKER) - FP_OFF(R_WriteBackViewConstantsMasked24);
    fwrite(&codesize[3], 2, 1, fp);
    locallib_far_fwrite((byte __far *)R_WriteBackViewConstantsMasked24, codesize[3], fp); 

    codesize[21] = FP_OFF(R_MASK16_ENDMARKER) - FP_OFF(R_WriteBackViewConstantsMasked16);
    fwrite(&codesize[21], 2, 1, fp);
    locallib_far_fwrite((byte __far *)R_WriteBackViewConstantsMasked16, codesize[21], fp); 

    codesize[18] = FP_OFF(R_MASK0_ENDMARKER) - FP_OFF(R_WriteBackViewConstantsMasked0);
    fwrite(&codesize[18], 2, 1, fp);
    locallib_far_fwrite((byte __far *)R_WriteBackViewConstantsMasked0, codesize[18], fp); 

    codesize[26] = FP_OFF(R_MASKFL_ENDMARKER) - FP_OFF(R_WriteBackViewConstantsMaskedFL);
    fwrite(&codesize[26], 2, 1, fp);
    locallib_far_fwrite((byte __far *)R_WriteBackViewConstantsMaskedFL, codesize[26], fp); 


    codesize[4] = FP_OFF(R_SKY_ENDMARKER) - FP_OFF(R_SKY_STARTMARKER);
    fwrite(&codesize[4], 2, 1, fp);
    locallib_far_fwrite((byte __far *)R_SKY_STARTMARKER, codesize[4], fp);

    codesize[28] = FP_OFF(R_SKYFL_ENDMARKER) - FP_OFF(R_SKYFL_STARTMARKER);
    fwrite(&codesize[28], 2, 1, fp);
    locallib_far_fwrite((byte __far *)R_SKYFL_STARTMARKER, codesize[28], fp);

    codesize[12] = FP_OFF(R_BSP24_ENDMARKER) - FP_OFF(R_BSP24_STARTMARKER);
    fwrite(&codesize[12], 2, 1, fp);
    locallib_far_fwrite((byte __far *)R_BSP24_STARTMARKER, codesize[12], fp);

    codesize[22] = FP_OFF(R_BSP16_ENDMARKER) - FP_OFF(R_BSP16_STARTMARKER);
    fwrite(&codesize[22], 2, 1, fp);
    locallib_far_fwrite((byte __far *)R_BSP16_STARTMARKER, codesize[22], fp);

    codesize[16] = FP_OFF(R_BSP0_ENDMARKER) - FP_OFF(R_BSP0_STARTMARKER);
    fwrite(&codesize[16], 2, 1, fp);
    locallib_far_fwrite((byte __far *)R_BSP0_STARTMARKER, codesize[16], fp);

    codesize[27] = FP_OFF(R_BSPFL_ENDMARKER) - FP_OFF(R_BSPFL_STARTMARKER);
    fwrite(&codesize[27], 2, 1, fp);
    locallib_far_fwrite((byte __far *)R_BSPFL_STARTMARKER, codesize[27], fp);


    codesize[5] = FP_OFF(WI_ENDMARKER) - FP_OFF(WI_STARTMARKER);
    fwrite(&codesize[5], 2, 1, fp);
    locallib_far_fwrite((byte __far *)WI_STARTMARKER, codesize[5], fp);


    codesize[6] = FP_OFF(S_SOUND_ENDMARKER) - FP_OFF(P_SIGHT_STARTMARKER);
    fwrite(&codesize[6], 2, 1, fp);
    locallib_far_fwrite((byte __far *)P_SIGHT_STARTMARKER, codesize[6], fp);

    codesize[29] = FP_OFF(M_MENU_ENDMARKER) - FP_OFF(M_MENU_STARTMARKER);
    fwrite(&codesize[29], 2, 1, fp);
    locallib_far_fwrite((byte __far *)M_MENU_STARTMARKER, codesize[29], fp);

    codesize[7] = FP_OFF(F_WIPE_ENDMARKER) - FP_OFF(F_WIPE_STARTMARKER);
    fwrite(&codesize[7], 2, 1, fp);
    locallib_far_fwrite((byte __far *)F_WIPE_STARTMARKER, codesize[7], fp);

    codesize[8] = FP_OFF(F_FINALE_ENDMARKER) - FP_OFF(F_FINALE_STARTMARKER);
    fwrite(&codesize[8], 2, 1, fp);
    locallib_far_fwrite((byte __far *)F_FINALE_STARTMARKER, codesize[8], fp);

    codesize[9] = FP_OFF(P_SAVEG_ENDMARKER) - FP_OFF(P_SAVEG_STARTMARKER);
    fwrite(&codesize[9], 2, 1, fp);
    locallib_far_fwrite((byte __far *)P_SAVEG_STARTMARKER, codesize[9], fp);

    codesize[10] = FP_OFF(SM_LOAD_ENDMARKER) - FP_OFF(SM_LOAD_STARTMARKER);
    fwrite(&codesize[10], 2, 1, fp);
    locallib_far_fwrite((byte __far *)SM_LOAD_STARTMARKER, codesize[10], fp);

    codesize[11] = FP_OFF(S_INIT_ENDMARKER) - FP_OFF(S_INIT_STARTMARKER);
    fwrite(&codesize[11], 2, 1, fp);
    locallib_far_fwrite((byte __far *)S_INIT_STARTMARKER, codesize[11], fp);

    codesize[30] = FP_OFF(P_SETUP_ENDMARKER) - FP_OFF(P_SETUP_STARTMARKER);
    fwrite(&codesize[30], 2, 1, fp);
    locallib_far_fwrite((byte __far *)P_SETUP_STARTMARKER, codesize[30], fp);


    muscodesize[0] = FP_OFF(SM_OPL2_ENDMARKER) - FP_OFF(SM_OPL2_STARTMARKER);
    fwrite(&muscodesize[0], 2, 1, fp);
    locallib_far_fwrite((byte __far *)SM_OPL2_STARTMARKER, muscodesize[0], fp);
    maxmuscodesize = muscodesize[0] > maxmuscodesize ? muscodesize[0] : maxmuscodesize;

    muscodesize[1] = FP_OFF(SM_OPL3_ENDMARKER) - FP_OFF(SM_OPL3_STARTMARKER);
    fwrite(&muscodesize[1], 2, 1, fp);
    locallib_far_fwrite((byte __far *)SM_OPL3_STARTMARKER, muscodesize[1], fp);
    maxmuscodesize = muscodesize[1] > maxmuscodesize ? muscodesize[1] : maxmuscodesize;

    muscodesize[2] = FP_OFF(SM_MPUMD_ENDMARKER) - FP_OFF(SM_MPUMD_STARTMARKER);
    fwrite(&muscodesize[2], 2, 1, fp);
    locallib_far_fwrite((byte __far *)SM_MPUMD_STARTMARKER, muscodesize[2], fp);
    maxmuscodesize = muscodesize[2] > maxmuscodesize ? muscodesize[2] : maxmuscodesize;

    muscodesize[3] = FP_OFF(SM_SBMID_ENDMARKER) - FP_OFF(SM_SBMID_STARTMARKER);
    fwrite(&muscodesize[3], 2, 1, fp);
    locallib_far_fwrite((byte __far *)SM_SBMID_STARTMARKER, muscodesize[3], fp);
    maxmuscodesize = muscodesize[3] > maxmuscodesize ? muscodesize[3] : maxmuscodesize;


    fclose(fp);

    // for (i = 0; i < 30; i++){
    //     printf ("codeside %i: %i\n", i, codesize[i]);
    // }

    
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




    // wipe offsets
    fprintf(fp, "#define wipe_StartScreenOffset                  0x%X\n", FP_OFF(wipe_StartScreen)                  - FP_OFF(F_WIPE_STARTMARKER));
	fprintf(fp, "#define wipe_WipeLoopOffset                     0x%X\n", FP_OFF(wipe_WipeLoop)                     - FP_OFF(F_WIPE_STARTMARKER));

    // finale offsets
    fprintf(fp, "#define F_StartFinaleOffset                     0x%X\n", FP_OFF(F_StartFinale)                     - FP_OFF(F_FINALE_STARTMARKER));
    fprintf(fp, "#define F_ResponderOffset                       0x%X\n", FP_OFF(F_Responder)                       - FP_OFF(F_FINALE_STARTMARKER));
    fprintf(fp, "#define F_DrawerOffset                          0x%X\n", FP_OFF(F_Drawer)                          - FP_OFF(F_FINALE_STARTMARKER));


    // s_init offsets
    fprintf(fp, "#define LoadSFXWadLumpsOffset                   0x%X\n", FP_OFF(LoadSFXWadLumps)                   - FP_OFF(S_INIT_STARTMARKER));


    // physics high code offsets
    fprintf(fp, "#define P_SetThingPositionFarOffset             0x%X\n", FP_OFF(P_SetThingPositionFar)             - FP_OFF(P_SIGHT_STARTMARKER));
    fprintf(fp, "#define P_SpawnMapThingOffset                   0x%X\n", FP_OFF(P_SpawnMapThing)                   - FP_OFF(P_SIGHT_STARTMARKER));
    
    fprintf(fp, "#define P_SpawnSpecialsOffset                   0x%X\n", FP_OFF(P_SpawnSpecials)                   - FP_OFF(P_SIGHT_STARTMARKER));
    fprintf(fp, "#define AM_DrawerOffset                         0x%X\n", FP_OFF(AM_Drawer)                         - FP_OFF(P_SIGHT_STARTMARKER));

    fprintf(fp, "#define S_StartSoundFarOffset                   0x%X\n", FP_OFF(S_StartSoundFar)                   - FP_OFF(P_SIGHT_STARTMARKER));
    fprintf(fp, "#define S_StartOffset                           0x%X\n", FP_OFF(S_Start)                           - FP_OFF(P_SIGHT_STARTMARKER));
    

    // menu  code offsets
    fprintf(fp, "#define M_InitOffset                            0x%X\n", FP_OFF(M_Init)                            - FP_OFF(M_MENU_STARTMARKER));
    fprintf(fp, "#define M_ResponderOffset                       0x%X\n", FP_OFF(M_Responder)                       - FP_OFF(M_MENU_STARTMARKER));
    fprintf(fp, "#define M_DrawPauseOffset                       0x%X\n", FP_OFF(M_DrawPause)                       - FP_OFF(M_MENU_STARTMARKER));
    fprintf(fp, "#define M_StartControlPanelOffset               0x%X\n", FP_OFF(M_StartControlPanel)               - FP_OFF(M_MENU_STARTMARKER));
    
    
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
	fprintf(fp, "#define M_MenuCodeSize                 0x%X\n", codesize[29]);
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
	fprintf(fp, "#define PSetupCodeSize                 0x%X\n", codesize[30]);
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
    
    fprintf(fp, "F_RESPONDEROFFSET = 0%Xh\n",                       FP_OFF(F_Responder)                       - FP_OFF(F_FINALE_STARTMARKER));
    fprintf(fp, "P_SETTHINGPOSITIONFAROFFSET = 0%Xh\n",             FP_OFF(P_SetThingPositionFar)             - FP_OFF(P_SIGHT_STARTMARKER));

    fprintf(fp, "P_REMOVEMOBJFAROFFSET = 0%Xh\n",                   FP_OFF(P_RemoveMobjFar)                   - FP_OFF(P_SIGHT_STARTMARKER));
    fprintf(fp, "P_SPAWNMAPTHINGOFFSET = 0%Xh\n",                   FP_OFF(P_SpawnMapThing)                   - FP_OFF(P_SIGHT_STARTMARKER));
    fprintf(fp, "P_CREATETHINKERFAROFFSET = 0%Xh\n",                FP_OFF(P_CreateThinkerFar)                - FP_OFF(P_SIGHT_STARTMARKER));
    fprintf(fp, "P_ADDACTIVECEILINGOFFSET = 0%Xh\n",                FP_OFF(P_AddActiveCeiling)                - FP_OFF(P_SIGHT_STARTMARKER));
    fprintf(fp, "P_ADDACTIVEPLATOFFSET = 0%Xh\n",                   FP_OFF(P_AddActivePlat)                   - FP_OFF(P_SIGHT_STARTMARKER));
    
    fprintf(fp, "P_REMOVETHINKEROFFSET  = 0%Xh\n",                   FP_OFF(P_RemoveThinker)                   - FP_OFF(P_SIGHT_STARTMARKER));
    fprintf(fp, "FIXEDDIVWHOLEA_ML      = 0%Xh\n",                   FP_OFF(FixedDivWholeA_MapLocal_FAR)       - FP_OFF(P_SIGHT_STARTMARKER));
    fprintf(fp, "R_POINTTOANGLE2_OFFSET = 0%Xh\n",                   FP_OFF(R_PointToAngle2_FAR)               - FP_OFF(P_SIGHT_STARTMARKER));


    fprintf(fp, "HU_TICKER_OFFSET         = 0%Xh\n",                   FP_OFF(HU_Ticker)                          - FP_OFF(P_SIGHT_STARTMARKER));
    fprintf(fp, "HU_DRAWER_OFFSET         = 0%Xh\n",                   FP_OFF(HU_Drawer)                          - FP_OFF(P_SIGHT_STARTMARKER));
    fprintf(fp, "HU_ERASE_OFFSET          = 0%Xh\n",                   FP_OFF(HU_Erase)                           - FP_OFF(P_SIGHT_STARTMARKER));
    fprintf(fp, "HU_RESPONDER_OFFSET      = 0%Xh\n",                   FP_OFF(HU_Responder)                       - FP_OFF(P_SIGHT_STARTMARKER));
    fprintf(fp, "R_DRAWVIEWBORDER_OFFSET  = 0%Xh\n",                   FP_OFF(R_DrawViewBorder)                   - FP_OFF(P_SIGHT_STARTMARKER));
    fprintf(fp, "V_DRAWPATCHDIRECT_OFFSET = 0%Xh\n",                   FP_OFF(V_DrawPatchDirect)                  - FP_OFF(P_SIGHT_STARTMARKER));
    fprintf(fp, "R_FILLBACKSCREEN_OFFSET  = 0%Xh\n",                   FP_OFF(R_FillBackScreen)                   - FP_OFF(P_SIGHT_STARTMARKER));







    fprintf(fp, "GETPAINCHANCEADDR     = 0%Xh\n",                   FP_OFF(GetPainChance)                     - FP_OFF(P_SIGHT_STARTMARKER));
    fprintf(fp, "GETRAISESTATEADDR     = 0%Xh\n",                   FP_OFF(GetRaiseState)                     - FP_OFF(P_SIGHT_STARTMARKER));
    fprintf(fp, "GETXDEATHSTATEADDR    = 0%Xh\n",                   FP_OFF(GetXDeathState)                    - FP_OFF(P_SIGHT_STARTMARKER));
    fprintf(fp, "GETMELEESTATEADDR     = 0%Xh\n",                   FP_OFF(GetMeleeState)                     - FP_OFF(P_SIGHT_STARTMARKER));
    fprintf(fp, "GETMOBJMASSADDR       = 0%Xh\n",                   FP_OFF(GetMobjMass)                       - FP_OFF(P_SIGHT_STARTMARKER));
    fprintf(fp, "GETACTIVESOUNDADDR    = 0%Xh\n",                   FP_OFF(GetActiveSound)                    - FP_OFF(P_SIGHT_STARTMARKER));
    fprintf(fp, "GETPAINSOUNDADDR      = 0%Xh\n",                   FP_OFF(GetPainSound)                      - FP_OFF(P_SIGHT_STARTMARKER));
    fprintf(fp, "GETATTACKSOUNDADDR    = 0%Xh\n",                   FP_OFF(GetAttackSound)                    - FP_OFF(P_SIGHT_STARTMARKER));
    fprintf(fp, "GETDAMAGEADDR         = 0%Xh\n",                   FP_OFF(GetDamage)                         - FP_OFF(P_SIGHT_STARTMARKER));
    fprintf(fp, "GETSEESTATEADDR       = 0%Xh\n",                   FP_OFF(GetSeeState)                       - FP_OFF(P_SIGHT_STARTMARKER));
    fprintf(fp, "GETMISSILESTATEADDR   = 0%Xh\n",                   FP_OFF(GetMissileState)                   - FP_OFF(P_SIGHT_STARTMARKER));
    fprintf(fp, "GETDEATHSTATEADDR     = 0%Xh\n",                   FP_OFF(GetDeathState)                     - FP_OFF(P_SIGHT_STARTMARKER));
    fprintf(fp, "GETPAINSTATEADDR      = 0%Xh\n",                   FP_OFF(GetPainState)                      - FP_OFF(P_SIGHT_STARTMARKER));
    fprintf(fp, "GETSPAWNHEALTHADDR    = 0%Xh\n",                   FP_OFF(GetSpawnHealth)                    - FP_OFF(P_SIGHT_STARTMARKER));
    
    fprintf(fp, "AM_RESPONDER_OFFSET    = 0%Xh\n",                   FP_OFF(AM_Responder)                     - FP_OFF(P_SIGHT_STARTMARKER));
    fprintf(fp, "AM_DRAWER_OFFSET       = 0%Xh\n",                   FP_OFF(AM_Drawer)                        - FP_OFF(P_SIGHT_STARTMARKER));
    fprintf(fp, "AM_TICKER_OFFSET       = 0%Xh\n",                   FP_OFF(AM_Ticker)                        - FP_OFF(P_SIGHT_STARTMARKER));

    fprintf(fp, "S_UPDATESOUNDSOFFSET       = 0%Xh\n",            FP_OFF(S_UpdateSounds)                      - FP_OFF(P_SIGHT_STARTMARKER));
    fprintf(fp, "S_STARTSOUNDFAROFFSET      = 0%Xh\n",            FP_OFF(S_StartSoundFar)                     - FP_OFF(P_SIGHT_STARTMARKER));
    fprintf(fp, "S_STARTSOUNDAX0FAROFFSET   = 0%Xh\n",            FP_OFF(S_StartSoundAX0Far)                     - FP_OFF(P_SIGHT_STARTMARKER));
    fprintf(fp, "S_ACTUALLYCHANGEMUSICOFFSET = 0%Xh\n",           FP_OFF(S_ActuallyChangeMusic)               - FP_OFF(SM_LOAD_STARTMARKER));



    fprintf(fp, "M_STARTCONTROLPANELOFFSET  = 0%Xh\n",            FP_OFF(M_StartControlPanel)                 - FP_OFF(M_MENU_STARTMARKER));
    fprintf(fp, "M_DRAWEROFFSET             = 0%Xh\n",            FP_OFF(M_Drawer)                            - FP_OFF(M_MENU_STARTMARKER));
    fprintf(fp, "M_DRAWPAUSEOFFSET          = 0%Xh\n",            FP_OFF(M_DrawPause)                         - FP_OFF(M_MENU_STARTMARKER));
    fprintf(fp, "M_RESPONDEROFFSET          = 0%Xh\n",            FP_OFF(M_Responder)                         - FP_OFF(M_MENU_STARTMARKER));
    fprintf(fp, "M_LOADFROMSAVEGAMEOFFSET   = 0%Xh\n",            FP_OFF(M_LoadFromSaveGame)                  - FP_OFF(M_MENU_STARTMARKER));


    fprintf(fp, "WIPE_STARTSCREENOFFSET     = 0%Xh\n",            FP_OFF(wipe_StartScreen)                    - FP_OFF(F_WIPE_STARTMARKER));
    fprintf(fp, "WIPE_WIPELOOPOFFSET        = 0%Xh\n",            FP_OFF(wipe_WipeLoop)                       - FP_OFF(F_WIPE_STARTMARKER));
    fprintf(fp, "F_DRAWEROFFSET             = 0%Xh\n",            FP_OFF(F_Drawer)                            - FP_OFF(F_FINALE_STARTMARKER));
    fprintf(fp, "LOADSFXWADLUMPSOFFSET      = 0%Xh\n",            FP_OFF(LoadSFXWadLumps)                     - FP_OFF(S_INIT_STARTMARKER));

    fprintf(fp, "P_SETUPLEVEL_OFFSET        = 0%Xh\n",            FP_OFF(P_SetupLevel)                        - FP_OFF(P_SETUP_STARTMARKER));


    // load offsets
    fprintf(fp, "G_CONTINUELOADGAMEOFFSET    = 0%Xh\n",           FP_OFF(G_ContinueLoadGame)                  - FP_OFF(P_SAVEG_STARTMARKER));
    fprintf(fp, "G_CONTINUESAVEGAMEOFFSET    = 0%Xh\n",           FP_OFF(G_ContinueSaveGame)                  - FP_OFF(P_SAVEG_STARTMARKER));

    // intermission/ wi stuff offsets

    fprintf(fp, "WI_TICKEROFFSET             = 0%Xh\n",           FP_OFF(WI_Ticker)                           - FP_OFF(WI_STARTMARKER));
    fprintf(fp, "WI_DRAWEROFFSET             = 0%Xh\n",           FP_OFF(WI_Drawer)                           - FP_OFF(WI_STARTMARKER));
    fprintf(fp, "G_DOCOMPLETED_OFFSET        = 0%Xh\n",           FP_OFF(G_DoCompleted)                       - FP_OFF(WI_STARTMARKER));


    fprintf(fp, "F_TICKEROFFSET              = 0%Xh\n",           FP_OFF(F_Ticker)                            - FP_OFF(F_FINALE_STARTMARKER));
    fprintf(fp, "P_TICKEROFFSET              = 0%Xh\n",           FP_OFF(P_Ticker)                            - FP_OFF(P_SIGHT_STARTMARKER));
    fprintf(fp, "AM_TICKEROFFSET             = 0%Xh\n",           FP_OFF(AM_Ticker)                           - FP_OFF(P_SIGHT_STARTMARKER));


    fprintf(fp, "R_WRITEBACKVIEWCONSTANTSMASKED24OFFSET  = 0%Xh\n", FP_OFF(R_WriteBackViewConstantsMasked24)  - FP_OFF(R_WriteBackViewConstantsMasked24));
    fprintf(fp, "R_WRITEBACKMASKEDFRAMECONSTANTS24OFFSET = 0%Xh\n", FP_OFF(R_WriteBackMaskedFrameConstants24) - FP_OFF(R_WriteBackViewConstantsMasked24));
    fprintf(fp, "R_WRITEBACKVIEWCONSTANTSMASKED16OFFSET  = 0%Xh\n", FP_OFF(R_WriteBackViewConstantsMasked16)  - FP_OFF(R_WriteBackViewConstantsMasked16));
    fprintf(fp, "R_WRITEBACKMASKEDFRAMECONSTANTS16OFFSET = 0%Xh\n", FP_OFF(R_WriteBackMaskedFrameConstants16) - FP_OFF(R_WriteBackViewConstantsMasked16));
    fprintf(fp, "R_WRITEBACKVIEWCONSTANTSMASKED0OFFSET   = 0%Xh\n", FP_OFF(R_WriteBackViewConstantsMasked0)   - FP_OFF(R_WriteBackViewConstantsMasked0));
    fprintf(fp, "R_WRITEBACKMASKEDFRAMECONSTANTS0OFFSET  = 0%Xh\n", FP_OFF(R_WriteBackMaskedFrameConstants0)  - FP_OFF(R_WriteBackViewConstantsMasked0));
    fprintf(fp, "R_WRITEBACKVIEWCONSTANTSMASKEDFLOFFSET  = 0%Xh\n", FP_OFF(R_WriteBackViewConstantsMaskedFL)  - FP_OFF(R_WriteBackViewConstantsMaskedFL));
    fprintf(fp, "R_WRITEBACKMASKEDFRAMECONSTANTSFLOFFSET = 0%Xh\n", FP_OFF(R_WriteBackMaskedFrameConstantsFL) - FP_OFF(R_WriteBackViewConstantsMaskedFL));
    fprintf(fp, "R_DRAWPLANES24OFFSET                   = 0%Xh\n", FP_OFF(R_DrawPlanes24)                    - FP_OFF(R_SPAN24_STARTMARKER));
	fprintf(fp, "R_WRITEBACKVIEWCONSTANTSSPAN24OFFSET   = 0%Xh\n", FP_OFF(R_WriteBackViewConstantsSpan24)    - FP_OFF(R_SPAN24_STARTMARKER));
	fprintf(fp, "R_DRAWPLANES16OFFSET                   = 0%Xh\n", FP_OFF(R_DrawPlanes16)                    - FP_OFF(R_SPAN16_STARTMARKER));
	fprintf(fp, "R_WRITEBACKVIEWCONSTANTSSPAN16OFFSET   = 0%Xh\n", FP_OFF(R_WriteBackViewConstantsSpan16)    - FP_OFF(R_SPAN16_STARTMARKER));
	fprintf(fp, "R_DRAWPLANES0OFFSET                    = 0%Xh\n", FP_OFF(R_DrawPlanes0)                     - FP_OFF(R_SPAN0_STARTMARKER));
	fprintf(fp, "R_WRITEBACKVIEWCONSTANTSSPAN0OFFSET    = 0%Xh\n", FP_OFF(R_WriteBackViewConstantsSpan0)     - FP_OFF(R_SPAN0_STARTMARKER));
	fprintf(fp, "R_DRAWPLANESFLOFFSET                   = 0%Xh\n", FP_OFF(R_DrawPlanesFL)                    - FP_OFF(R_SPANFL_STARTMARKER));
	fprintf(fp, "R_WRITEBACKVIEWCONSTANTSSPANFLOFFSET   = 0%Xh\n", FP_OFF(R_WriteBackViewConstantsSpanFL)    - FP_OFF(R_SPANFL_STARTMARKER));
	fprintf(fp, "R_DRAWSKYCOLUMNOFFSET                  = 0%Xh\n", FP_OFF(R_DrawSkyColumn)                   - FP_OFF(R_SKY_STARTMARKER));
	fprintf(fp, "R_DRAWSKYPLANEOFFSET                   = 0%Xh\n", FP_OFF(R_DrawSkyPlane)                    - FP_OFF(R_SKY_STARTMARKER));
	fprintf(fp, "R_DRAWSKYPLANEDYNAMICOFFSET            = 0%Xh\n", FP_OFF(R_DrawSkyPlaneDynamic)             - FP_OFF(R_SKY_STARTMARKER));
	fprintf(fp, "R_DRAWSKYCOLUMNFLOFFSET                = 0%Xh\n", FP_OFF(R_DrawSkyColumnFL)                 - FP_OFF(R_SKYFL_STARTMARKER));
	fprintf(fp, "R_DRAWSKYPLANEFLOFFSET                 = 0%Xh\n", FP_OFF(R_DrawSkyPlaneFL)                  - FP_OFF(R_SKYFL_STARTMARKER));
	fprintf(fp, "R_DRAWSKYPLANEDYNAMICFLOFFSET          = 0%Xh\n", FP_OFF(R_DrawSkyPlaneDynamicFL)           - FP_OFF(R_SKYFL_STARTMARKER));
	fprintf(fp, "R_WRITEBACKVIEWCONSTANTS24OFFSET       = 0%Xh\n", FP_OFF(R_WriteBackViewConstants24)        - FP_OFF(R_BSP24_STARTMARKER));
	fprintf(fp, "R_RENDERPLAYERVIEW24OFFSET             = 0%Xh\n", FP_OFF(R_RenderPlayerView24)              - FP_OFF(R_BSP24_STARTMARKER));
	fprintf(fp, "R_GETCOMPOSITETEXTURE24OFFSET          = 0%Xh\n", FP_OFF(R_GetCompositeTexture_Far24)       - FP_OFF(R_BSP24_STARTMARKER));
	fprintf(fp, "R_GETPATCHTEXTURE24OFFSET              = 0%Xh\n", FP_OFF(R_GetPatchTexture_Far24)           - FP_OFF(R_BSP24_STARTMARKER));
	fprintf(fp, "R_WRITEBACKVIEWCONSTANTS16OFFSET       = 0%Xh\n", FP_OFF(R_WriteBackViewConstants16)        - FP_OFF(R_BSP16_STARTMARKER));
	fprintf(fp, "R_RENDERPLAYERVIEW16OFFSET             = 0%Xh\n", FP_OFF(R_RenderPlayerView16)              - FP_OFF(R_BSP16_STARTMARKER));
	fprintf(fp, "R_GETCOMPOSITETEXTURE16OFFSET          = 0%Xh\n", FP_OFF(R_GetCompositeTexture_Far16)       - FP_OFF(R_BSP16_STARTMARKER));
	fprintf(fp, "R_GETPATCHTEXTURE16OFFSET              = 0%Xh\n", FP_OFF(R_GetPatchTexture_Far16)           - FP_OFF(R_BSP16_STARTMARKER));
	fprintf(fp, "R_WRITEBACKVIEWCONSTANTS0OFFSET        = 0%Xh\n", FP_OFF(R_WriteBackViewConstants0)         - FP_OFF(R_BSP0_STARTMARKER));
	fprintf(fp, "R_RENDERPLAYERVIEW0OFFSET              = 0%Xh\n", FP_OFF(R_RenderPlayerView0)               - FP_OFF(R_BSP0_STARTMARKER));
	fprintf(fp, "R_GETCOMPOSITETEXTURE0OFFSET           = 0%Xh\n", FP_OFF(R_GetCompositeTexture_Far0)        - FP_OFF(R_BSP0_STARTMARKER));
	fprintf(fp, "R_GETPATCHTEXTURE0OFFSET               = 0%Xh\n", FP_OFF(R_GetPatchTexture_Far0)            - FP_OFF(R_BSP0_STARTMARKER));
	fprintf(fp, "R_WRITEBACKVIEWCONSTANTSFLOFFSET       = 0%Xh\n", FP_OFF(R_WriteBackViewConstantsFL)        - FP_OFF(R_BSPFL_STARTMARKER));
	fprintf(fp, "R_RENDERPLAYERVIEWFLOFFSET             = 0%Xh\n", FP_OFF(R_RenderPlayerViewFL)              - FP_OFF(R_BSPFL_STARTMARKER));
	fprintf(fp, "R_GETCOMPOSITETEXTUREFLOFFSET          = 0%Xh\n", FP_OFF(R_GetCompositeTexture_FarFL)       - FP_OFF(R_BSPFL_STARTMARKER));
	fprintf(fp, "R_GETPATCHTEXTUREFLOFFSET              = 0%Xh\n", FP_OFF(R_GetPatchTexture_FarFL)           - FP_OFF(R_BSPFL_STARTMARKER));

    fprintf(fp, "SELFMODIFY_COLFUNC_SUBTRACT_CENTERY24_OFFSET_1      = 0%Xh\n", FP_OFF(MARKER_SELFMODIFY_COLFUNC_subtract_centery24_1)    - FP_OFF(R_BSP24_STARTMARKER));
    fprintf(fp, "SELFMODIFY_COLFUNC_SUBTRACT_CENTERY24_OFFSET_2      = 0%Xh\n", FP_OFF(MARKER_SELFMODIFY_COLFUNC_subtract_centery24_2)    - FP_OFF(R_BSP24_STARTMARKER));
	fprintf(fp, "SELFMODIFY_COLFUNC_SET_DESTVIEW_SEGMENT24_OFFSET    = 0%Xh\n", FP_OFF(MARKER_SELFMODIFY_COLFUNC_set_destview_segment24)  - FP_OFF(R_BSP24_STARTMARKER));
	fprintf(fp, "SELFMODIFY_COLFUNC_JUMP_OFFSET24_OFFSET             = 0%Xh\n", FP_OFF(MARKER_SELFMODIFY_COLFUNC_jump_offset24)           - FP_OFF(R_BSP24_STARTMARKER));
	fprintf(fp, "SELFMODIFY_COLFUNC_SET_DESTVIEW_SEGMENT24_NOLOOP_OFFSET    = 0%Xh\n", FP_OFF(MARKER_SELFMODIFY_COLFUNC_set_destview_segment24_noloop)  - FP_OFF(R_BSP24_STARTMARKER));
	fprintf(fp, "SELFMODIFY_COLFUNC_JUMP_OFFSET24_NOLOOP_OFFSET             = 0%Xh\n", FP_OFF(MARKER_SELFMODIFY_COLFUNC_jump_offset24_noloop)           - FP_OFF(R_BSP24_STARTMARKER));
    fprintf(fp, "SELFMODIFY_COLFUNC_SUBTRACT_CENTERY16_OFFSET        = 0%Xh\n", FP_OFF(MARKER_SELFMODIFY_COLFUNC_subtract_centery16)      - FP_OFF(R_BSP16_STARTMARKER));
	fprintf(fp, "SELFMODIFY_COLFUNC_SET_DESTVIEW_SEGMENT16_OFFSET    = 0%Xh\n", FP_OFF(MARKER_SELFMODIFY_COLFUNC_set_destview_segment16)  - FP_OFF(R_BSP16_STARTMARKER));
	fprintf(fp, "SELFMODIFY_COLFUNC_JUMP_OFFSET16_OFFSET             = 0%Xh\n", FP_OFF(MARKER_SELFMODIFY_COLFUNC_jump_offset16)           - FP_OFF(R_BSP16_STARTMARKER));
	fprintf(fp, "SELFMODIFY_COLFUNC_SET_DESTVIEW_SEGMENT0_OFFSET     = 0%Xh\n", FP_OFF(MARKER_SELFMODIFY_COLFUNC_set_destview_segment0)   - FP_OFF(R_BSP0_STARTMARKER));
	fprintf(fp, "SELFMODIFY_COLFUNC_JUMP_OFFSET0_OFFSET              = 0%Xh\n", FP_OFF(MARKER_SELFMODIFY_COLFUNC_jump_offset0)            - FP_OFF(R_BSP0_STARTMARKER));
	fprintf(fp, "SELFMODIFY_COLFUNC_SET_DESTVIEW_SEGMENTFL_OFFSET    = 0%Xh\n", FP_OFF(MARKER_SELFMODIFY_COLFUNC_set_destview_segmentFL)  - FP_OFF(R_BSPFL_STARTMARKER));
	fprintf(fp, "SELFMODIFY_COLFUNC_JUMP_OFFSETFL_OFFSET             = 0%Xh\n", FP_OFF(MARKER_SELFMODIFY_COLFUNC_jump_offsetFL)           - FP_OFF(R_BSPFL_STARTMARKER));
	fprintf(fp, "SELFMODIFY_COLFUNC_JUMP_OFFSETFL_OFFSET             = 0%Xh\n", FP_OFF(MARKER_SELFMODIFY_COLFUNC_jump_offsetFL)           - FP_OFF(R_BSPFL_STARTMARKER));
    fprintf(fp, "COLFUNC_NOLOOP_FUNCTION_AREA_OFFSET                 = 0%Xh\n", FP_OFF(MARKER_COLFUNC_NOLOOP_FUNCTION_AREA_OFFSET)        - FP_OFF(R_BSP24_STARTMARKER));
    fprintf(fp, "COLFUNC_NOLOOP_JUMPTABLE_SIZE_OFFSET                = 0%Xh\n", FP_OFF(MARKER_COLFUNC_NOLOOP_JUMPTABLE_SIZE_OFFSET)       - FP_OFF(R_BSP24_STARTMARKER));
    fprintf(fp, "COLFUNC_JUMPTABLE_SIZE_OFFSET                       = 0%Xh\n", FP_OFF(MARKER_COLFUNC_JUMP_TARGET24)                      - FP_OFF(R_BSP24_STARTMARKER));



    fprintf(fp, "M_INITOFFSET                           = 0%Xh\n", FP_OFF(M_Init)                            - FP_OFF(M_MENU_STARTMARKER));
    fprintf(fp, "P_SPAWNSPECIALSOFFSET                  = 0%Xh\n", FP_OFF(P_SpawnSpecials)                   - FP_OFF(P_SIGHT_STARTMARKER));
    fprintf(fp, "S_STARTOFFSET                          = 0%Xh\n", FP_OFF(S_Start)                           - FP_OFF(P_SIGHT_STARTMARKER));

    fprintf(fp, "ST_START_OFFSET                         = 0%Xh\n", FP_OFF(ST_Start)                          - FP_OFF(P_SIGHT_STARTMARKER));
    fprintf(fp, "ST_TICKER_OFFSET                        = 0%Xh\n", FP_OFF(ST_Ticker)                         - FP_OFF(P_SIGHT_STARTMARKER));
    fprintf(fp, "ST_DRAWER_OFFSET                        = 0%Xh\n", FP_OFF(ST_Drawer)                         - FP_OFF(P_SIGHT_STARTMARKER));
    fprintf(fp, "ST_RESPONDER_OFFSET                     = 0%Xh\n", FP_OFF(ST_Responder)                      - FP_OFF(P_SIGHT_STARTMARKER));
    fprintf(fp, "G_RESPONDEROFFSET                       = 0%Xh\n", FP_OFF(G_Responder)                       - FP_OFF(M_MENU_STARTMARKER));


    fprintf(fp, "ARMS_CS_OFFSET                          = 0%Xh\n", FP_OFF(_arms)                             - FP_OFF(P_SIGHT_STARTMARKER));               
    fprintf(fp, "ARMSBG_CS_OFFSET                        = 0%Xh\n", FP_OFF(_armsbg)                           - FP_OFF(P_SIGHT_STARTMARKER));               
    fprintf(fp, "ARMSBGARRAY_CS_OFFSET                   = 0%Xh\n", FP_OFF(_armsbgarray)                      - FP_OFF(P_SIGHT_STARTMARKER));                       
    fprintf(fp, "FACES_CS_OFFSET                         = 0%Xh\n", FP_OFF(_faces)                            - FP_OFF(P_SIGHT_STARTMARKER));               
    fprintf(fp, "KEYS_CS_OFFSET                          = 0%Xh\n", FP_OFF(_keys)                             - FP_OFF(P_SIGHT_STARTMARKER));               
    fprintf(fp, "SHORTNUM_CS_OFFSET                      = 0%Xh\n", FP_OFF(_shortnum)                         - FP_OFF(P_SIGHT_STARTMARKER));                   
    fprintf(fp, "TALLNUM_CS_OFFSET                       = 0%Xh\n", FP_OFF(_tallnum)                          - FP_OFF(P_SIGHT_STARTMARKER));                   
    fprintf(fp, "SBAR_CS_OFFSET                          = 0%Xh\n", FP_OFF(_sbar)                             - FP_OFF(P_SIGHT_STARTMARKER));               
    fprintf(fp, "FACEBACK_CS_OFFSET                      = 0%Xh\n", FP_OFF(_faceback)                         - FP_OFF(P_SIGHT_STARTMARKER));                   
    fprintf(fp, "TALLPERCENT_CS_OFFSET                   = 0%Xh\n", FP_OFF(_tallpercent)                      - FP_OFF(P_SIGHT_STARTMARKER));                       




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

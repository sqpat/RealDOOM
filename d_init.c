//
// Copyright (C) 1993-1996 Id Software, Inc.
// Copyright (C) 2016-2017 Alexey Khokholov (Nuke.YKT)
//
// This program is free software; you can redistribute it and/or
// modify it under the terms of the GNU General Public License
// as published by the Free Software Foundation; either version 2
// of the License, or (at your option) any later version.
//
// This program is distributed in the hope that it will be useful,
// but WITHOUT ANY WARRANTY; without even the implied warranty of
// MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
// GNU General Public License for more details.
//
// DESCRIPTION:
//  DOOM main program (D_DoomMain) and game loop (D_DoomLoop),
//  plus functions to determine game mode (shareware, registered),
//  parse command line parameters, configure game parameters (turbo),
//  and call the startup functions.



#include "doomdef.h"
#include <stdlib.h>
#include <direct.h>
#include <io.h>
#include <fcntl.h>

#include "doomstat.h"

#include "dstrings.h"
#include "sounds.h"


#include "z_zone.h"
#include "w_wad.h"
#include "s_sound.h"
#include "v_video.h"

#include "f_finale.h"
#include "f_wipe.h"

#include "m_misc.h"
#include "m_menu.h"

#include "i_system.h"
#include "i_sound.h"

#include "g_game.h"

#include "hu_stuff.h"
#include "wi_stuff.h"
#include "st_stuff.h"
#include "am_map.h"

#include "p_setup.h"
#include "r_local.h"

#include "d_main.h"
#include "p_local.h"
#include "m_memory.h"
#include "m_near.h"
#include "s_sbsfx.h"

#include <dos.h>

#define MAX_STRINGS 306


void __far M_LoadDefaults();

void __far D_InitStrings() {

	// load file
	FILE* fp;
	//filelength_t length;
	int16_t i;
	int16_t j = 0;
	int8_t letter;
	uint16_t stringbuffersize;
	fp = fopen("dstrings.txt", "rb");
	if (!fp) {
		I_Error("dstrings.txt missing?");
		return;
	}

	//length = filelength(handle);
	stringoffsets[0] = 0;
	

	while (1) {
		// break up in pagesize
 


		//if (carryover) {
			//memcpy(stringdata, &lastbuffer[stringoffsets[j]], carryover);
		//}

		for (i = 0; i < 16384 ; i++) {
			letter = fgetc(fp);
			stringdata[i] = letter;
			if (letter == 'n') {
				if (stringdata[i  - 1] == '\\') {
					// hacky, but oh well.
					stringdata[i  - 1] = '\n';
					//stringdata[i  ] = '\n';
					i--;
				}
			}
			if (letter == '\r') {
				i--; // undo \r
			};
			if (letter == '\n') {
				j++;
				stringoffsets[j] = i;// +(page * 16384);
				i--; // dont want to waste a character saving extra newlines. 
				// we are appending strings with null terminators when we return them anyway
			};

			if (feof(fp)) {
				break;
			}
		}
		stringbuffersize = stringoffsets[j];
		if (feof(fp)) {
			break;
		}
		//I_Error("99"); // Strings too big. Need to implement 2nd page?

		//page++;
		//lastbuffer = buffer;

		//carryover = i - stringoffsets[j];

	}


	fclose(fp);


}




//
// D_GetCursorColumn
//
int16_t __near D_GetCursorColumnRow(void) {
	fixed_t_union result;
	result.wu = locallib_int86_10(0x0300, 0x0000, 0x0000);
	return result.hu.intbits;
}


//
// D_SetCursorPosition
//
void __near D_SetCursorPosition(int16_t columnrow){

	//regs.h.dh = row;
	//regs.h.dl = column;
	// regs.w.dx = columnrow;
	// regs.h.ah = 2;
	// regs.h.bh = 0;
	// intx86(0x10, &regs, &regs);

	locallib_int86_10(0x0200, columnrow, 0x0000);



}

//
// D_DrawTitle
//
void __near D_DrawTitle(int8_t __near *string){

	int16_t_union columnrow;
	int16_t i;
	int8_t COLOR;

	if (is_ultimate) {
		COLOR = 120;
	} else {
		COLOR = 116;
	}



	//Calculate text color

	//I_Error("string is \n%s1", string);

	//Get column/row position
	columnrow.h = D_GetCursorColumnRow();

	#define column columnrow.b.bytelow

	for (i = 0; i < locallib_strlen(string); i++)
	{
		//Set character
		// regs.h.ah = 9;
		// regs.h.al = string[i];
		// regs.w.cx = 1;
		// regs.h.bl = COLOR;
		// regs.h.bh = 0;
		// intx86(0x10, &regs, &regs);

		locallib_int86_10_4args(0x900 + string[i], 0, COLOR, 1);

		//Check cursor position
		if (++column > 79){
			column = 0;
		}

		//Set position
		D_SetCursorPosition(columnrow.h);
	}
	#undef column
}


//      print title for every printed line

//
// D_RedrawTitle
//

#if DEBUG_PRINTING

void __near D_RedrawTitle(int8_t __near *title) {
	int16_t_union columnrow;

	//Get current cursor pos
	columnrow.h = D_GetCursorColumnRow();

	//Set cursor pos to zero
	D_SetCursorPosition(0);

	//Draw title
	D_DrawTitle(title);

	//Restore old cursor pos
	D_SetCursorPosition(columnrow.h);
}
#endif
 
 

/*


 uint8_t __far sscanf_uint8(int8_t* strparm){
	int8_t i;
	int8_t parm = 0;
	for (i = 0; ; i++){
		if (strparm[i] == '\0'){
			return parm;
		}
		parm = parm * 10;
		parm += (strparm[i] - '0');
	}
	
}
*/


void __near makethreecharint(int16_t j, char __near *str );



void __near HU_Init(void){


	int16_t		i;
	int16_t		j;
	int8_t	buffer[9];
	int8_t	ext[4];
	uint16_t runningoffset = 0;	// beginning of the graphics in the ST_GRAPHICS segment.
	uint16_t size = 0;
	int16_t lump;

	Z_QuickMapStatus();

	// load the heads-up font
	j = HU_FONTSTART;
	for (i = 0; i < HU_FONTSIZE; i++) {
		makethreecharint(j++, ext);
		combine_strings(buffer, "STCFN", ext );

		lump = W_GetNumForName(buffer);
		size = W_LumpLength(lump);
		runningoffset -= size;

		hu_font[i] = runningoffset;
		W_CacheLumpNumDirect(lump, (byte __far*)(MK_FP(ST_GRAPHICS_SEGMENT, hu_font[i])));
		
		font_widths_far[i] = (((patch_t __far *)MK_FP(ST_GRAPHICS_SEGMENT, hu_font[i]))->width);
	
	}


	Z_QuickMapPhysics();


}

void 	I_SetSFXPrefix();

// todo: near breaks this.
int16_t   I_GetSfxLumpNum(sfxenum_t sfx);


//
// Initializes sound stuff, including volume
// Sets channels, SFX and music volume,
//  allocates channel buffer, sets S_sfx lookup.
//
void  __near S_Init () {

	void (__far* LoadSFXWadLumps)() = 							        		  ((void    (__far *)())     							(MK_FP(code_overlay_segment, 		 	 LoadSFXWadLumpsOffset)));



	// load sound setup code into overlay
	Z_SetOverlay(OVERLAY_ID_SOUND_INIT);
	LoadSFXWadLumps();

	// sb card setup for now..
	if (snd_SfxDevice == snd_SB){
		SB_StartInit();
	}

}

 





void __near AM_loadPics(void){

	int8_t i;
	int16_t lump;
	int8_t namebuf[8] = "AMMNUM0";
	uint16_t offset = 0;


	for (i = 0; i < 10; i++) {
		ammnumpatchoffsets_far[i] = offset;
		lump = W_GetNumForName(namebuf);
		W_CacheLumpNumDirect(lump, &ammnumpatchbytes_far[offset]);
		offset += W_LumpLength(lump);
		namebuf[6]++;
	}

}
/*

void DUMP_MEMORY_TO_FILE() {
	uint16_t segment = 0x4000;
#ifdef __COMPILER_WATCOM
	FILE*fp = fopen("MEM_DUMP.BIN", "wb");
#else
	FILE*fp = fopen("MEMDUMP2.BIN", "wb");
#endif
	while (segment < 0xA000) {
		byte __far * dest = MK_FP(segment, 0);
		//DEBUG_PRINT("\nloop %u", segment);
		locallib_far_fwrite(dest, 32768, 1, fp);
		segment += 0x0800;
	}
	fclose(fp);
	I_Error("\ndumped");
}
*/
//
// D_DoomMain
//


  void PSetupEndFunc();
int16_t main ( int16_t		argc, int8_t**	argv ) ;
 //void fakefunc();

int16_t __near M_CheckParm (int8_t __far* check);


//
// G_RecordDemo 
// 
void __near G_RecordDemo (int8_t* name) {
 
	int32_t                         maxsize;
    int16_t i;    
    usergame = false;
	// i don't like this, but it works and watcom doesnt seem to know how to cast it otherwise.
	// FIXED_DS_SEGMENT is hardcoded nearsegment
    combine_strings (MK_FP(FIXED_DS_SEGMENT, (int16_t)demoname), name, ".lmp"); 
    maxsize = DEMO_MAX_SIZE;
    i = M_CheckParm ("-maxdemo");
    if (i && i<myargc-1) 
            maxsize = atoi(myargv[i+1])*1024;
    //demoend = demobuffer + maxsize;
        
    demorecording = true; 
} 
 
//
// G_TimeDemo 
//
void __near G_TimeDemo (int8_t* name) {
        
    //nodrawers = M_CheckParm ("-nodraw"); 
    noblit = M_CheckParm ("-noblit"); 
    timingdemo = true; 
    singletics = true; 

    defdemoname = name; 
    gameaction = ga_playdemo; 
} 

void __near W_AddFile(int8_t *filename);




void 		M_ScanTranslateDefaults();


int16_t countleadingzeroes(uint32_t num);
uint32_t divllu(fixed_t_union num_input, fixed_t_union den);



//
// M_Init
//
 

// this is only done in init... pull into there?


/*
void __near M_Reload(void) {
	// reload menu graphics
	int8_t i = 0;
	int8_t count = NUM_MENU_ITEMS;

	uint16_t size = 0;
	byte __far* dst = menugraphicspage0;
 	int8_t menugraphics[NUM_MENU_ITEMS * 9];


	FILE *fp = fopen("DOOMDATA.BIN", "rb");
	// FAR_memset(savegamestrings, 0x00, size_savegamestrings);
	fseek(fp, MENUDATA_DOOMDATA_OFFSET, SEEK_SET);
	fread(menugraphics, 9, NUM_MENU_ITEMS, fp);
	fclose(fp);

	if (!is_ultimate){
		count--;
	}

	for (i = 0; i < count; i++) {
		int16_t lump = W_GetNumForName(&menugraphics[i*9]);
		uint16_t lumpsize = W_LumpLength(lump);

		if (i == 30) { // (size + lumpsize) > 65535u) {
			// repage
			// 0xFFE0
			size = 0;
			dst = menugraphicspage4;
		}
		W_CacheLumpNumDirect(lump, dst);
		menuoffsets[i] = size;
		size += lumpsize;
		dst += lumpsize;

	}
	// I_Error("%x", size);
	// 92b4


}
*/


/*
void __far M_Init(void){
	

	
	M_Reload();
	

	currentMenu = &MainDef;
	menuactive = 0;
	itemOn = currentMenu->lastOn;
	whichSkull = 0;
	skullAnimCounter = 10;
	screenSize = screenblocks - 1;
	// messageToPrint = 0;
	// menu_messageString[0] = '\0';
	// messageLastMenuActive = menuactive;
	quickSaveSlot = -1;  // means to pick a slot now

	if (commercial) {
		MainMenu[readthis] = MainMenu[quitdoom];
		MainDef.numitems--;
		MainDef.y += 8;
		NewDef.prevMenu = &MainDef;
		ReadDef1.routine = M_DrawReadThisRetail;
		ReadDef1.x = 330;
		ReadDef1.y = 165;
		ReadMenu1[0].routine = M_FinishReadThis;
	}


	
}*/


/*
int16_t countleadingzeroes(uint32_t num){
	uint32_t start = 1L << 31;
	int16_t result = 0;
	while (!(num & start) && result < 31){
		start >>= 1;
		result++;
	}

	return result;
}

uint32_t divllu(fixed_t_union num_input, fixed_t_union den) {
    // We work in base 2**16.
    // A uint16 holds a single digit. A uint32 holds two digits.
    // Our numerator is conceptually [num3, num2, num1, num0].
    // Our denominator is [den1, den0].
    const uint32_t b = (1ull << 16);

    // The high and low digits of our computed quotient.
    uint16_t q1;

    // The normalization shift factor.
    int16_t shift;

    // The high and low digits of our denominator (after normalizing).
    // Also the low 2 digits of our numerator (after normalizing).
    uint16_t den1;
    uint16_t den0;
    uint16_t num1;
    uint16_t num0;

    // A partial remainder.
    fixed_t_union rem;

    // The estimated quotient, and its corresponding remainder (unrelated to true remainder).
    uint16_t qhat;
    uint16_t rhat;

    // Variables used to correct the estimated quotient.
    uint32_t c1;
	fixed_t_union divresult;
    fixed_t_union c2;
	fixed_t_union numlo;
	fixed_t_union numhi;
	numhi.wu = num_input.hu.intbits;
	numlo.hu.intbits = num_input.hu.fracbits;
	numlo.hu.fracbits = 0;

    // Check for overflow and divide by 0.
    //if (numhi.wu >= den.wu) {
        //return 0;
    //}

    // Determine the normalization factor. We multiply den by this, so that its leading digit is at
    // least half b. In binary this means just shifting left by the number of leading zeros, so that
    // there's a 1 in the MSB.
    // We also shift numer by the same amount. This cannot overflow because numhi < den.
    // The expression (-shift & 63) is the same as (32 - shift), except it avoids the UB of shifting
    // by 32. The funny bitwise 'and' ensures that numlo does not get shifted into numhi if shift is 0.
    // clang 11 has an x86 codegen bug here: see LLVM bug 50118. The sequence below avoids it.
    shift = countleadingzeroes(den.wu);
    den.wu <<= shift;
    numhi.wu <<= shift;
    numhi.wu |= (numlo.wu >> (-shift & 31)) & (-(int32_t)shift >> 31);
    numlo.wu <<= shift;

    // Extract the low digits of the numerator and both digits of the denominator.
    num1 = (uint16_t)(numlo.hu.intbits);
    num0 = (uint16_t)(numlo.hu.fracbits);
    den1 = (uint16_t)(den.hu.intbits);
    den0 = (uint16_t)(den.hu.fracbits);

    // We wish to compute q1 = [n3 n2 n1] / [d1 d0].
    // Estimate q1 as [n3 n2] / [d1], and then correct it.
    // Note while qhat may be 2 digits, q1 is always 1 digit.
	divresult.wu = DIV3216RESULTREMAINDER(numhi.wu, den1);
	qhat = divresult.hu.fracbits;
	rhat = divresult.hu.intbits;

    c1 = FastMul16u16u(qhat , den0);
    c2.hu.intbits = rhat;
	c2.hu.fracbits = num1;
    if (c1 > c2.wu)
        qhat -= (c1 - c2.wu > den.wu) ? 2 : 1;
    q1 = (uint16_t)qhat;

    // Compute the true (partial) remainder.
	// overflow is expected and fine. 
	// thus we use a 32 bit result for  q1 * den.wu

    
//    rem.wu = numhi.wu * b + num1 - q1*den.wu;
	rem.hu.intbits = numhi.hu.fracbits;
	rem.hu.fracbits = num1;
	rem.wu -= FastMul16u32u(q1, den.wu);
	



    // We wish to compute q0 = [rem1 rem0 n0] / [d1 d0].
    // Estimate q0 as [rem1 rem0] / [d1] and correct it.

	// sq NOTE! the qhat * den0 will overflow in some cases.
	// it wont fit in a 32 bit register if the result is 0x10001 or 0x10000.
	// so rather than correct later - we must frontload some checking.
	//  Not expensive - just compare high byte of numerator with denominator.
	//  if larger than or equal, then subtract denominator, check again and subtract again if necessary.
	//  in these cases, the later off-by-one-or-two 'corrections' are appropriately skipped 
    if (rem.hu.intbits < den1){

		divresult.wu = DIV3216RESULTREMAINDER(rem.wu, den1);
		qhat = divresult.hu.fracbits;
		rhat = divresult.hu.intbits;


		c1 = FastMul16u16u(qhat , den0);

		c2.h.intbits = rhat;
		c2.h.fracbits = num0;

		if (c1 > c2.wu)
			qhat -= (c1 - c2.wu > den.wu) ? 2 : 1;

		// q0 = qhat

		return ((uint32_t)q1 << 16) | qhat;
	} else {
		rem.wu -= den1;

		if (rem.hu.intbits < den1){

			divresult.wu = DIV3216RESULTREMAINDER(rem.wu, den1);
			qhat = divresult.hu.fracbits;
			rhat = divresult.hu.intbits;
			c1 = FastMul16u16u(qhat , den0);

			c2.h.intbits = rhat;
			c2.h.fracbits = num0;

			// skip the double correction case and only do single
			if (c1 > c2.wu && (c1 - c2.wu > den.wu))
				qhat--;

			// q0 = qhat
			return ((uint32_t)q1 << 16) | qhat;

		} else {

			rem.wu -= den1;
			divresult.wu = DIV3216RESULTREMAINDER(rem.wu, den1);
			qhat = divresult.hu.fracbits;
			rhat = divresult.hu.intbits;

			c1 = FastMul16u16u(qhat , den0);

			c2.h.intbits = rhat;
			c2.h.fracbits = num0;

			// q0 = qhat
			// no correction. we've already subtracted two

			return ((uint32_t)q1 << 16) | qhat;
			
		}
	}
}
*/


// check for doom ultimate.
void check_is_ultimate(){
	int16_t words[3];
	FILE* fp = fopen("doom.wad", "rb");
	fread (words, sizeof(int16_t), 3, fp);
	fclose(fp);
	if (words[2] == 0x0902){
		is_ultimate = true;
	
	}
}


//void checkDS(int16_t a);
void __far wipe_WipeLoop();
void __far I_ReadScreen();
uint16_t  __near   R_CheckTextureNumForName(int8_t * __near name);

int16_t __near P_DivlineSide ( fixed_t_union	x, fixed_t_union	y, divline_t __near*	node ) ;
void __far P_TouchSpecialThing (mobj_t __near*	special,mobj_t __near*	toucher,mobj_pos_t  __far*special_pos,mobj_pos_t  __far*toucher_pos);
void ST_STUFF_STARTMARKER();
void P_INTER_ENDMARKER();
void __near P_SpawnGlowingLight(int16_t secnum) ;
void __near D_Display (void) ;
void __near G_BeginRecording (void) ;
void __far D_StartTitle(void);
uint8_t __near M_Random (void);

void    __near P_UpdateSpecials (void);

void __far D_DoomMain2(void) {
	int16_t             p;
	int8_t                    file[256];
#if DEBUG_PRINTING
	int8_t          textbuffer[280]; // must be 276 to fit the 3 line titles
	int8_t            title[128];
#endif
	int8_t            wadfile[20];
	#define DGROUP_SIZE 0x2250

	/*

	FILE *fp = fopen("output9.bin", "wb");
	locallib_far_fwrite(M_Random, (byte __far *)ST_STUFF_STARTMARKER - (byte __far *)M_Random, 1, fp);
	fclose(fp);
	exit(0);


	fixed_t_union x, y;


	// bugged with i = 3025 j = 2139

	
	//I_Error("leading: %i", countleadingzeroes(0x0));
	//I_Error("res: %li %lx", divllu(a, b ), divllu(a, b ));
	//I_Error("res: %li %lx %li %lx", divllu(a, b ), divllu(a, b ), 	 FixedDiv(a.wu, b.wu ), FixedDiv(a.wu, b.wu ));
					//tempDivision.w = (y.w << 3) / (x.w >> 8);
					//tempDivision.w = FastDiv3232_shift_3_8(y.w, x.w);

	y.wu = 0xfac00000; 
	x.wu = 0xf2c00000;
	//0x22511E38
	// 0x44A86

// 0x180000 / 0x1678

R_PointToAngle(y, x);

	I_Error("res: %lx %lx\n %lu %lx %lu %lx", y, x, 
	R_PointToAngle10(y, x), R_PointToAngle10(y, x),
							    	R_PointToAngle11(y, x), R_PointToAngle11(y, x));
									*/
/*
	a.w = 0x0fedcba9;
	b.w = 0x07654321;

	I_StartupSound();

	tica = ticcount;

	for (i = 2; i < 1000; i++){
		fixed_t_union ii;
		ii.wu = i * i;
		for (j = i/2; j < i; j++){
			fixed_t_union jj;
			jj.wu = j * j;
			FixedDiv(ii.wu, jj.wu);
		}
	}
	ticb = ticcount;
	for (i = 2; i < 1000; i++){
		fixed_t_union ii;
		ii.wu = i * i;
		for (j = i/2; j < i; j++){
			fixed_t_union jj;
			jj.wu = j * j;
			FixedDiv10(ii.wu, jj.wu);
		}
	}
	ticc = ticcount;
	I_Error("values %li %li %li %li %li", tica, ticb, ticc, ticb-tica, ticc-ticb);
*/
	//int16_t i;
	//int16_t j;

	//FixedDivWholeA(257l*257, 65536);

	//DEBUG_PRINT("%li  ok\n",FixedDiv(4L * 4L * 10000L, 4));
	// 0x38400
	// 0x7D29
	// 0xE1000000
	// 0x1F4A4000
	//I_Error("doneA %li %lx %li %lx", FixedDiv(0xe1000000, 0x7D29), FixedDiv(0xe1000000, 0x7D29), 
	//			FixedDivWholeA(0xe100, 0x7D29), FixedDivWholeA(0xe100, 0x7D29));

//0x7D29
/*
	// 240 57600 179
	// - max but shouldnt be

	int16_t i, j;
	for (i = 2; i < 127; i++){
		fixed_t_union ii;
		fixed_t_union jj;
		jj.hu.fracbits = 0;
		ii.hu.intbits = i;
		ii.hu.fracbits = 0;
		for (j = i+1; j < 4096; j++){
			jj.h.intbits = j;


			if (FixedDivWholeAB2(i 	, j) != FixedDiv(ii.wu, jj.wu)){
				I_Error("inequal %i %i %i %lx %lx %li %li %lx %lx",
					 i,
					 0xff, j, 
				ii.wu, jj.wu,
				FixedDivWholeAB2(i, j),
				FixedDiv(ii.wu, jj.wu),
				FixedDivWholeAB2(i, j),
				FixedDiv(ii.wu, jj.wu)
				);
			}

			DEBUG_PRINT("%i %i %li %li ok\n", i, j, ii.wu, jj.wu);
		}

	}

	I_Error("done");
	

	//I_Error("res: %li %lx", divllu(a, b ), divllu(a, b ));
	//I_Error("done");
	
/*
	I_Error("blah %Fp %Fp %lx", (byte __far *)R_DrawMaskedColumn, (byte __far *)R_DrawSingleMaskedColumn,
		FixedDiv(0x0FEDCBA9, 0x07654321 ));  // 2276
//		FixedDiv(0x7FFE0000, 0x7FFF0000	));	

//	I_Error("blah %x %x %x", colfunc_segment_high, colfunc_segment, R_DrawColumnPrepOffset);
	//I_Error("blah %Fp", MAKE_FULL_SEGMENT(spritepage, size_spriteoffset + size_spritepage));

/*
	uint16_t i;

	for (i = 0; i < 65535; i++){
		if (FixedMulBig1632(i, 0x12345678) != FixedMulBig16322(i, 0x12345678)){
			I_Error("%lx %lx %i %i", FixedMulBig1632(i, 0x12345678), FixedMulBig16322(i, 0x12345678), i, 0x12345678);
		}
		if (FixedMulBig1632(i, 0x92345678) != FixedMulBig16322(i, 0x92345678)){
			I_Error("%lx %lx %i %i", FixedMulBig1632(i, 0x92345678), FixedMulBig16322(i, 0x92345678), i, 0x92345678);
		}
	}
	I_Error("\n\n%lx %lx %lx %lx", 
		FixedMulBig16322(0xFFFF, 0x0020),
		FixedMulBig1632(0xFFFF, 0x0020),

		FixedMulBig16322(0xFFFF, 0x1020),
		FixedMulBig1632(0xFFFF, 0x1020)

	);	

*/
  
/*
	I_Error("\n%lx %Fp %Fp %Fp\n%Fp %Fp %Fp %Fp\n%Fp %Fp %Fp %Fp\n%Fp %Fp %Fp %Fp\n%Fp %Fp %Fp %Fp\n%Fp %Fp %Fp %Fp\n%Fp %Fp %Fp %Fp\n%Fp %Fp %Fp %Fp\n%p",
		spritewidths_ult,
		spritewidths_normal,
		sprites, 
//73bb 73b9 7410 7412 7410 
		
		 MAKE_FULL_SEGMENT(spritewidths_ult, size_spritewidths),
		 MAKE_FULL_SEGMENT(spritewidths_normal, size_spritewidths),
			scalelight, 
			patch_sizes,
			viewangletox
);

*/

	file[0] = 0;


/*
	if (M_CheckParm("-debug")){
		segread(&sregs);
		//I_Error("\npointer is %Fp %Fp %Fp %Fp", MK_FP(sregs.ds, DGROUP_SIZE), MK_FP(sregs.cs, &main), MK_FP(sregs.ds +( DGROUP_SIZE >> 4), 0), MK_FP(sregs.ss, 0));
		// 
		

		DEBUG_PRINT("\nResult: %li %li %li %li %li", 
		R_FixedMulLocalWrapper(128L, 0L),
		R_FixedMulLocalWrapper(0x10000, 1L),
		R_FixedMulLocalWrapper(128L, 1L),
		R_FixedMulLocalWrapper(0x10000, 127L),
		R_FixedMulLocalWrapper(0, 0)

		);
		exit(0);
	}
*/


	

	//I_Error("\npointer is %Fp %Fp %Fp %Fp %Fp", MK_FP(sregs.ds, &EMS_PAGE), MK_FP(sregs.ds, &p), MK_FP(sregs.ss, &title), _fmalloc(1024), malloc(1024));



  

	// Removed
	//FindResponseFile ();
	//P_Init();


	if (!access("doom2.wad", R_OK)) {
		commercial = true;
		locallib_strcpy(wadfile,"doom2.wad");
		goto foundfile;
	}

#if (EXE_VERSION >= EXE_VERSION_FINAL)
	if (!access("plutonia.wad", R_OK)) {
		commercial = true;
		plutonia = true;
		locallib_strcpy(wadfile,"plutonia.wad");
		goto foundfile;
	}

	if (!access("tnt.wad", R_OK)) {
		commercial = true;
		tnt = true;
		locallib_strcpy(wadfile,"tnt.wad");
		goto foundfile;
	}
#endif

	if (!access("doom.wad", R_OK)) {
		registered = true;
		locallib_strcpy(wadfile,"doom.wad");
		check_is_ultimate();
		goto foundfile;
	}

	if (!access("doom1.wad", R_OK)) {
		shareware = true;
		locallib_strcpy(wadfile,"doom1.wad");
		goto foundfile;
	}

	DEBUG_PRINT("Game mode indeterminate.\n");
	exit(1);

	foundfile:

	setbuf(stdout, NULL);
	modifiedgame = false;

	nomonsters = M_CheckParm("-nomonsters");
	respawnparm = M_CheckParm("-respawn");
	fastparm = M_CheckParm("-fast");

	if (M_CheckParm("-mem")){
		//todo whats the -100 about? should it be 400?
		I_Error("\nBYTES LEFT: %i %x (DS : %x to %x BASEMEM : %x)\n", 
		16 * (base_lower_memory_segment - stored_ds) - 0x1000, 
		16 * (base_lower_memory_segment - stored_ds )- 0x100, 
		stored_ds, 
		stored_ds + 0x100, 
		base_lower_memory_segment);
	}


#if DEBUG_PRINTING

	if (!commercial) {
		memcpy(title, "                        ", 30);
		if (is_ultimate){
			combine_strings(title, title, " The Ultimate DOOM Startup v1.9");
		} else {
			combine_strings(title, title, "  DOOM System Startup v1.9  ");
		}
		combine_strings(title, title, "                        ");

	} else {
		#if (EXE_VERSION >= EXE_VERSION_FINAL)
				if (plutonia) {
					combine_strings(title, "                   DOOM 2: Plutonia Experiment v", VERSION_STRING);
				combine_strings(title, title, "                           ");
				}
				else if (tnt) {
					combine_strings(title, "                     DOOM 2: TNT - Evilution v", VERSION_STRING);
					combine_strings(title, title, "                           ");
				} else {
					combine_strings(title, "                         DOOM 2: Hell on Earth v", VERSION_STRING);
					combine_strings(title, title, "                           ");

				}
		#else
					memcpy(title, "                         DOOM 2: Hell on Earth v1.9                           ", 127);
					
		#endif
	}

	// set video mode?
	locallib_int86_10(0x3, 0, 0);

	D_DrawTitle(title);


	

	DEBUG_PRINT("\nP_Init: Checking cmd-line parameters...");
#endif


	// turbo option
	if ((p = M_CheckParm("-turbo"))) {
		int16_t     scale = 200;

		if (p < myargc - 1) {
			scale = atoi(myargv[p + 1]);
		}
		if (scale < 10) {
			scale = 10;
		}
		if (scale > 400) {
			scale = 400;
		}

		DEBUG_PRINT("turbo scale: %i%%\n", scale);

		forwardmove[0] = forwardmove[0] * scale / 100;
		forwardmove[1] = forwardmove[1] * scale / 100;
		sidemove[0] = sidemove[0] * scale / 100;
		sidemove[1] = sidemove[1] * scale / 100;
	}

	p = M_CheckParm("-playdemo");

	if (!p) {
		p = M_CheckParm("-timedemo");
	}

	if (p && p < myargc - 1) {
		combine_strings(file, myargv[p + 1], ".lmp");
		DEBUG_PRINT("Playing demo %s.lmp.\n", myargv[p + 1]);
	}

	// get skill / episode / map from parms
	startskill = sk_medium;
	startepisode = 1;
	startmap = 1;
	autostart = false;


	p = M_CheckParm("-skill");
	if (p && p < myargc - 1) {
		startskill = myargv[p + 1][0] - '1';
		autostart = true;
	}

	p = M_CheckParm("-episode");
	if (p && p < myargc - 1) {
		startepisode = myargv[p + 1][0] - '0';
		startmap = 1;
		autostart = true;
	}


	p = M_CheckParm("-warp");
	if (p && p < myargc - 1) {
		if (commercial)
			startmap = atoi(myargv[p + 1]);
		else
		{
			startepisode = myargv[p + 1][0] - '0';
			startmap = myargv[p + 2][0] - '0';
		}
		autostart = true;
	}

	p = M_CheckParm("-nosound");
	
	if (p && p < myargc - 1) {
        snd_MusicDevice = snd_SfxDevice = snd_none;
    }
	p = M_CheckParm("-nosfx");
	
	if (p && p < myargc - 1) {
        snd_SfxDevice = snd_none;
    }
	p = M_CheckParm("-nomusic");

	if (p && p < myargc - 1) {
        snd_MusicDevice = snd_none;
    }


	// init subsystems


	DEBUG_PRINT("\nZ_InitEMS: Initialize EMS memory regions.");
	Z_InitEMS();

	DEBUG_PRINT("\nW_Init: Init WADfiles.");
	numlumps = 0;
	W_AddFile(wadfile);
	if (file[0]){
		W_AddFile(file);
	}

	DEBUG_PRINT("\nZ_GetEMSPageMap: Init EMS 4.0 features.");
	Z_GetEMSPageMap();

	DEBUG_PRINT("\nM_LoadDefaults	: Load system defaults.");
	M_LoadDefaults();              // load before initing other systems

	DEBUG_PRINT("\nZ_LoadBinaries: Load game code into memory");
	Z_LoadBinaries();

	M_ScanTranslateDefaults();

	// init subsystems
	DEBUG_PRINT("\nD_InitStrings: loading text.");
	D_InitStrings();


	// Check for -file in shareware
	#if DEBUG_PRINTING
	if (registered) {
		getStringByIndex(VERSION_REGISTERED, textbuffer);
		DEBUG_PRINT(textbuffer);
		D_RedrawTitle(title);
		getStringByIndex(NOT_SHAREWARE, textbuffer);
		DEBUG_PRINT(textbuffer);
		D_RedrawTitle(title);
	}
	if (shareware) {
		getStringByIndex(VERSION_SHAREWARE, textbuffer);
		DEBUG_PRINT(textbuffer);
		D_RedrawTitle(title);
	}
	if (commercial) {
		getStringByIndex(VERSION_COMMERCIAL, textbuffer);
		DEBUG_PRINT(textbuffer);
		D_RedrawTitle(title);

		getStringByIndex(DO_NOT_DISTRIBUTE, textbuffer);
		DEBUG_PRINT(textbuffer);
		D_RedrawTitle(title);
	}

	getStringByIndex(M_INIT_TEXT_STR, textbuffer);
	DEBUG_PRINT(textbuffer);
	D_RedrawTitle(title);
	#endif
	Z_QuickMapMenu();
	M_Init();
	Z_QuickMapPhysics();

	// 6350 493 10
	//I_Error("\n%u %u %hhi %s", stringoffsets[E3TEXT], stringoffsets[E3TEXT + 1] - stringoffsets[E3TEXT], textbuffer[0], textbuffer);


#if DEBUG_PRINTING
	getStringByIndex(R_INIT_TEXT_STR, textbuffer);
	DEBUG_PRINT(textbuffer);
	D_RedrawTitle(title);
#endif
	//DUMP_MEMORY_TO_FILE();
	R_Init();


#if DEBUG_PRINTING
	getStringByIndex(P_INIT_TEXT_STR, textbuffer);
	DEBUG_PRINT(textbuffer);
	D_RedrawTitle(title);
#endif
	P_Init();


#if DEBUG_PRINTING
	getStringByIndex(I_INIT_TEXT_STR, textbuffer);
	DEBUG_PRINT(textbuffer);
	D_RedrawTitle(title);
#endif
	I_Init();
	maketic = 0;

#if DEBUG_PRINTING
	getStringByIndex(S_INIT_STRING_TEXT, textbuffer);
	DEBUG_PRINT(textbuffer);
	D_RedrawTitle(title);
#endif
	S_Init();

#if DEBUG_PRINTING
	getStringByIndex(HU_INIT_TEXT_STR, textbuffer);
	DEBUG_PRINT(textbuffer);
	D_RedrawTitle(title);
#endif
	HU_Init();

#if DEBUG_PRINTING
	getStringByIndex(ST_INIT_TEXT_STR, textbuffer);
	DEBUG_PRINT(textbuffer);
	D_RedrawTitle(title);
#endif
	ST_Init();

	// moving this here. We want to load automap related wad lumps into physics ems pages now rather than lazily load it where pages are in a dynamic state.
	AM_loadPics();


	// todo - move this below code in between doommain2 and doomloop?

	// start the apropriate game based on parms
	p = M_CheckParm("-record");

	if (p && p < myargc - 1) {
		G_RecordDemo(myargv[p + 1]);
		autostart = true;
	}

	p = M_CheckParm("-playdemo");
	if (p && p < myargc - 1) {
		singledemo = true;              // quit after one demo
		G_DeferedPlayDemo(myargv[p + 1]);
		return;
 	}

	p = M_CheckParm("-timedemo");
	if (p && p < myargc - 1) {
		G_TimeDemo(myargv[p + 1]);
		return; 
 	}

	p = M_CheckParm("-loadgame");
	if (p && p < myargc - 1) {
		Z_QuickMapMenu();
		M_LoadFromSaveGame(myargv[p + 1][0]);
		Z_QuickMapPhysics();
	}


	if (gameaction != ga_loadgame) {
		if (autostart){
			G_InitNew(startskill, startepisode, startmap);
		} else {
			// D_StartTitle();                // start up intro loop
			// inlined
			gameaction = ga_nothing;
			demosequence = -1;
    		advancedemo = true;

		}

	}

}



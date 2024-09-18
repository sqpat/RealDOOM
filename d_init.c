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



#include <stdlib.h>
#include <direct.h>
#include <io.h>
#include <fcntl.h>

#include "doomdef.h"
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

#include <dos.h>

#define MAX_STRINGS 306


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
int16_t __near D_GetCursorColumnRow(void)
{
	union REGS regs;

	regs.h.ah = 3;
	regs.h.bh = 0;
	intx86(0x10, &regs, &regs);

	return regs.w.dx;
}


//
// D_SetCursorPosition
//
void __near D_SetCursorPosition(int16_t columnrow)
{
	union REGS regs;

	//regs.h.dh = row;
	//regs.h.dl = column;
	regs.w.dx = columnrow;
	regs.h.ah = 2;
	regs.h.bh = 0;
	intx86(0x10, &regs, &regs);
}

//
// D_DrawTitle
//
void __near D_DrawTitle(int8_t __near *string)
{
	union REGS regs;
	int16_t_union columnrow;
	int16_t i;

	//Calculate text color

	//I_Error("string is \n%s1", string);

	//Get column/row position
	columnrow.h = D_GetCursorColumnRow();

	#define column columnrow.b.bytelow

	for (i = 0; i < locallib_strlen(string); i++)
	{
		//Set character
		regs.h.ah = 9;
		regs.h.al = string[i];
		regs.w.cx = 1;
		regs.h.bl = (BGCOLOR << 4) | FGCOLOR; 
		regs.h.bh = 0;
		intx86(0x10, &regs, &regs);

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
void __near D_RedrawTitle(int8_t __near *title) {
	int16_t_union columnrow;
	int16_t column;
	int16_t row;

	//Get current cursor pos
	columnrow.h = D_GetCursorColumnRow();

	//Set cursor pos to zero
	D_SetCursorPosition(0);

	//Draw title
	D_DrawTitle(title);

	//Restore old cursor pos
	D_SetCursorPosition(columnrow.h);
}

 
 



//
// M_LoadDefaults
//
extern int8_t*	defaultfile;


 

//
// M_CheckParm
// Checks for the given parameter
// in the program's command line arguments.
// Returns the argument number (1 to argc-1)
// or 0 if not present
int16_t __near M_CheckParm (int8_t *check)
{
    int16_t		i;

    for (i = 1;i<myargc;i++)
    {
	if ( !strcasecmp(check, myargv[i]) )
	    return i;
    }

    return 0;
}

uint8_t sscanf_uint8(int8_t* strparm){
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

void __near M_LoadDefaults(void) {
	int16_t		i;
	FILE*	f;
	int8_t	strparm[80];
	int8_t	def[80];
	uint8_t		parm;

	// set everything to base values
	for (i = 0; i < NUM_DEFAULTS; i++)
		*defaults[i].location = defaults[i].defaultvalue;

	// check for a custom default file
	i = M_CheckParm("-config");
	if (i && i < myargc - 1) {
		defaultfile = myargv[i + 1];
		DEBUG_PRINT("	default file: %s\n", defaultfile);
	}
	else {
		defaultfile = "default.cfg";
	}
	// read the file in, overriding any set defaults
	f = fopen(defaultfile, "r");
	if (f) {
		int8_t readphase = 0; // getting param 0
		int8_t defindex = 0;
		int8_t strparmindex = 0;
		while (!feof(f)) {
			// fscanf  replacement
			// removed fscanf which includes like 4 KB of c library cruft.

			char c = fgetc(f);
			boolean iswhitespace = c == ' ' || c == '\t';
			boolean isnewline = c == '\n' || c == '\r';
			
			// readphase 0 = read param name
			// readphase 1 = read param value

			if (readphase == 0){
				if (!iswhitespace && ! isnewline){
					def[defindex] = c;
					defindex++;
				} else if (iswhitespace){
					def[defindex] = '\0';
					readphase = 1;
				} else { // isnewline
					// no value found.
					readphase = 0;
					defindex = 0;
					strparmindex = 0;
				}
			} else if (readphase == 1){
				if (iswhitespace){
					continue;
				} else if (!isnewline){
					strparm[strparmindex] = c;
					strparmindex++;
				} else { // isnewline
					// done reading value!
					strparm[strparmindex] = '\0';
						readphase = 0;
						defindex = 0;
					if (strparmindex == 0){
						// no value found.
						strparmindex = 0;
						continue;
					}
					strparmindex = 0;
					parm = 0;
					//printf("\nDefault found: %s : %s", def, strparm);


					// sscanf replacement. get uint8_t value of strparm
					parm = sscanf_uint8(strparm);


					for (i = 0; i < NUM_DEFAULTS; i++) {
						if (!strcmp(def, defaults[i].name)) {
							*(defaults[i].location) = parm;
							break;
						}
					}
				}
			}

			/*
			if (fscanf(f, "%s %[^\n]\n", def, strparm) == 2) {
				sscanf(strparm, "%i", &parm);
				for (i = 0; i < NUM_DEFAULTS; i++) {
					if (!strcmp(def, defaults[i].name)) {
						*(defaults[i].location) = parm;
						break;
					}
				}
			}*/	
		}
		

		fclose(f);
	}
	for (i = 0; i < NUM_DEFAULTS; i++)
	{
		if (defaults[i].scantranslate)
		{
			parm = *defaults[i].location;
			defaults[i].untranslated = parm;
			*defaults[i].location = scantokey[parm];
		}
	}
}


extern uint16_t	hu_font[HU_FONTSIZE];

void __near makethreecharint(int16_t j, char __far *str ){
	int16_t val = j / 10;
	str[0] = '0' + val / 10;
	str[1] = '0' + val;
	str[2] = '0' + j % 10;
	str[3] = '\0';

}


void __near HU_Init(void)
{

	int16_t		i;
	int16_t		j;
	int8_t	buffer[9];
	int8_t	ext[4];


	Z_QuickMapStatus();

	// load the heads-up font
	j = HU_FONTSTART;
	for (i = 0; i < HU_FONTSIZE; i++) {
		makethreecharint(j++, ext);
		combine_strings(buffer, "STCFN", ext );
		W_CacheLumpNameDirect(buffer, (byte __far*)(MK_FP(ST_GRAPHICS_SEGMENT, hu_font[i])));
	}


	Z_QuickMapPhysics();


}


//
// Initializes sound stuff, including volume
// Sets channels, SFX and music volume,
//  allocates channel buffer, sets S_sfx lookup.
//
void  __near S_Init (uint8_t		sfxVolume, uint8_t		musicVolume) {

	/*

  int16_t		i;
  channel_t* channels;

  //fprintf( stderr, "S_Init: default sfx volume %d\n", sfxVolume);

  // Whatever these did with DMX, these are rather dummies now.
  I_SetChannels(numChannels);

  S_SetSfxVolume(sfxVolume);
  // No music with Linux - another dummy.
  S_SetMusicVolume(musicVolume);

  // Allocating the internal channels for mixing
  // (the maximum numer of sounds rendered
  // simultaneously) within zone memory.
  channelsRef =  Z_MallocEMS (numChannels*sizeof(channel_t), PU_STATIC, 0);
  channels = (channel_t*) Z_LoadBytesFromEMS(channelsRef);

  // Free all channels for use
  for (i=0 ; i<numChannels ; i++)
	channels[i].sfxinfo = 0;

  // no sounds are playing, and they are not mus_paused
  mus_paused = 0;

  // Note that sounds have not been cached (yet).
  for (i=1 ; i<NUMSFX ; i++)
	S_sfx[i].lumpnum = S_sfx[i].usefulness = -1;

  */

}

 





void __near AM_loadPics(void)
{
	int8_t i;
	int16_t lump;
	int8_t namebuf[8] = "AMMNUM0";
	uint16_t offset = 0;


	for (i = 0; i < 10; i++) {
		ammnumpatchoffsets[i] = offset;
		lump = W_GetNumForName(namebuf);
		W_CacheLumpNumDirect(lump, &ammnumpatchbytes[offset]);
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
		FAR_fwrite(dest, 32768, 1, fp);
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

extern int8_t demoname[32];
extern boolean timingdemo;
extern int8_t* defdemoname;

//
// G_RecordDemo 
// 
void __near G_RecordDemo (int8_t* name) 
{ 
	int32_t                         maxsize;
    int16_t i;    
    usergame = false; 
    combine_strings (demoname, name, ".lmp"); 
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
void __near G_TimeDemo (int8_t* name) 
{        
    //nodrawers = M_CheckParm ("-nodraw"); 
    noblit = M_CheckParm ("-noblit"); 
    timingdemo = true; 
    singletics = true; 

    defdemoname = name; 
    gameaction = ga_playdemo; 
} 

void __near W_AddFile(int8_t *filename);

void __far M_Init(void);



fixed_t32	FixedMulBig1632(int16_t a, fixed_t b);
fixed_t32	FixedMulBig16322(int16_t a, fixed_t b);


void copystr8(int8_t __far* dst, int8_t __far* src);
void __near V_DrawPatchFlipped (int16_t		x, int16_t		y, patch_t __far*	patch) ;

int16_t countleadingzeroes(uint32_t num);
uint32_t divllu(fixed_t_union num_input, fixed_t_union den);

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


void __far D_DoomMain2(void)
{
	int16_t             p;
	int8_t                    file[256];
	union REGS regs;
	int8_t          textbuffer[280]; // must be 276 to fit the 3 line titles
	int8_t            title[128];
	int8_t            wadfile[20];
	#define DGROUP_SIZE 0x3a30
	struct SREGS sregs;


/*
	fixed_t_union x, y;

	//FILE *fp = fopen("output3.bin", "wb");
	//FAR_fwrite(divllu, (byte __far *)FixedDiv - (byte __far *)divllu, 1, fp);
	//fclose(fp);

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



	/*
	FILE* fp = fopen("DOOMDATA.BIN", "rb"); 





	FAR_fread(finesine, 1, 0x2cc9, fp);

	//40960
	FAR_fread(finesine, 4, 10240, fp);
	fclose(fp);

	for (i = 0; i < 8192; i++){
		if (FixedMul(finesine[i], 0x12345678) != FixedMulTrig(FINE_SINE_ARGUMENT, i, 0x12345678)){
			I_Error("a, %i, %li %li", i, FixedMul(finesine[i], 0x12345678), FixedMulTrig(FINE_SINE_ARGUMENT, i, 0x12345678));
		}
		if (FixedMul(finecosine[i], 0x12345678) != FixedMulTrig(FINE_COSINE_ARGUMENT, i, 0x12345678)){
			I_Error("b, %i, %li %li", i, FixedMul(finecosine[i], 0x12345678), FixedMulTrig(FINE_COSINE_ARGUMENT, i, 0x12345678));
		}

	}
	I_Error("\n%lx %lx %lx %lx\n%lx %lx %lx %lx\n%lx %lx %lx %lx\n%lx %lx %lx %lx\n", 
	
		FixedMul     (finesine[0], 0x12345678), 
		FixedMulTrig(FINE_SINE_ARGUMENT, 0, 0x12345678),
		FixedMulTrigOld(finesine[0], 0x12345678),
		FixedMulTrigOld(finesine[0], 0x12345678),
		
		FixedMul     (finesine[500], 0x00005678), 
		FixedMulTrig(FINE_SINE_ARGUMENT, 500, 0x00005678),
		FixedMulTrigOld(finesine[500], 0x00005678),
		FixedMulTrigOld(finesine[500], 0x00005678),
		
		
		FixedMul     (finesine[3000], 0xFFFF1234), 
		FixedMulTrig(FINE_SINE_ARGUMENT, 3000, 0xFFFF1234),
		FixedMulTrigOld(finesine[3000], 0xFFFF1234),
		FixedMulTrigOld(finesine[3000], 0xFFFF1234),
		
		FixedMul     (finesine[7000], 0x1FFF1234), 
		FixedMulTrig(FINE_SINE_ARGUMENT, 7000, 0x1FFF1234),
		FixedMulTrigOld(finesine[7000], 0x1FFF1234),
		FixedMulTrigOld(finesine[7000], 0x1FFF1234)

	);

	


	R_ScaleFromGlobalAngleTest();
	R_ScaleFromGlobalAngle3(0);
	I_Error("done");
*/

    //fixed_t a = R_ScaleFromGlobalAngle2(3041);
    //fixed_t b = R_ScaleFromGlobalAngle3(3041);
	//I_Error("bad %i %li %li", 3041, a, b);


/*
	FILE* fp = fopen("D_OUTPU1.BIN", "wb"); 

	FAR_fwrite((byte __far *)R_PointOnSegSide2, 1, (byte __far *)R_PointOnSegSide - (byte __far *)R_PointOnSegSide2, fp);
	fclose(fp);
    I_Error("\n done");
	
*/


/*

	DEBUG_PRINT("\nResult: %lx %lx %lx %lx %lx\nResult: %lx %lx %lx %lx %lx\nResult: %lx %lx %lx %lx %lx", 


FixedMul(128L, -10000L),
FixedMul(10000L, -10000L),
FixedMul(-4000, -4000L),
FixedMul(0xFFEEDDCC, 0xAABBCCDD),
FixedMul(0, 0),


R_FixedMulLocalWrapper2(128L, -10000L),
R_FixedMulLocalWrapper2(10000L, -10000L),
R_FixedMulLocalWrapper2(-4000, -4000L),
R_FixedMulLocalWrapper2(0xFFEEDDCC, 0xAABBCCDD),
R_FixedMulLocalWrapper2(0, 0)

);
	exit(0);
	//I_Error("\n%Fp %Fp", spanfunc_function_area, spanfunc_function_area_9000 );
/*	
	//boolean __far P_CheckSight (  mobj_t __far* t1, mobj_t __far* t2, mobj_pos_t __far* t1_pos, mobj_pos_t __far* t2_pos );
	I_Error("\ndone %Fp %Fp %Fp %Fp", colfunc_jump_lookup, dc_yl_lookup, 
	
	colfunc_function_area, mobjposlist
	);
*/	

/*
	FILE* fp = fopen("D_FILE.BIN", "wb"); 
	FAR_fwrite(colfunc_jump_lookup, 2, 200, fp);
	FAR_fwrite(dc_yl_lookup, 2, 200, fp);
	fclose(fp);
	I_Error("done");
//FAR_memcpy()

	/*
	
	int16_t i, i2;
	int16_t j;
	int16_t val;
	FILE* fp = fopen("data6.bin", "wb");

	for (i = 0; i < 4; i++){
		for (i2 = 0; i2 < 10; i2++){
			val = 35*5*parsa[i][i2];
			fwrite(&val, 1, 2, fp);

		}
	}
	for (i = 0; i < 32; i++){
		val = 35*10*cparsa[i];
		fwrite(&val, 1, 2, fp);
	}

	
	
	fclose(fp);
	I_Error("done");
	*/

	
	// cs 2700..
	// ds 2e3a..
	// ho wbig is too big?

	// 14016
	
	// baselowermemoryaddress

	//I_Error("\n%x %x %x %x", size_patchoffset, size_patchpage, size_zlight, 0);

/*
	I_Error("\n\n%Fp %Fp %Fp %Fp\n%Fp %Fp %Fp %Fp\n%Fp %Fp %Fp %Fp\n%Fp %Fp %Fp %Fp\n%Fp %Fp %Fp %Fp\n%Fp %Fp %Fp %Fp\n%Fp %Fp %Fp %Fp\n%Fp %Fp %Fp %Fp\n%p",
		nodes, 
		node_children,
		 segs,
		 visplaneheaders,
		fuzzoffset, 
		scalelightfixed,
			scalelight, 
			patch_sizes,
			viewangletox
);
*/


	file[0] = 0;


	if (M_CheckParm("-mem")){
		segread(&sregs);
		//I_Error("\npointer is %Fp %Fp %Fp %Fp", MK_FP(sregs.ds, DGROUP_SIZE), MK_FP(sregs.cs, &main), MK_FP(sregs.ds +( DGROUP_SIZE >> 4), 0), MK_FP(sregs.ss, 0));
		// 
		DEBUG_PRINT("Bytes free %u %FP %Fp", (baselowermemoryaddresssegment - (sregs.ds +( DGROUP_SIZE >> 4))) << 4, MK_FP(sregs.ds +( DGROUP_SIZE >> 4), 0), MK_FP(FP_SEG(P_SetupLevel), 0x26ad));
		exit(0);

	}

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


	if (!access("doom2.wad", R_OK))
	{
		commercial = true;
		locallib_strcpy(wadfile,"doom2.wad");
		goto foundfile;
	}

#if (EXE_VERSION >= EXE_VERSION_FINAL)
	if (!access("plutonia.wad", R_OK))
	{
		commercial = true;
		plutonia = true;
		locallib_strcpy(wadfile,"plutonia.wad");
		goto foundfile;
	}

	if (!access("tnt.wad", R_OK))
	{
		commercial = true;
		tnt = true;
		locallib_strcpy(wadfile,"tnt.wad");
		goto foundfile;
	}
#endif

	if (!access("doom.wad", R_OK))
	{
		registered = true;
		locallib_strcpy(wadfile,"doom.wad");
		goto foundfile;
	}

	if (!access("doom1.wad", R_OK))
	{
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

#ifdef DEBUG_PRINTING

	if (!commercial)
	{
#if (EXE_VERSION >= EXE_VERSION_ULTIMATE)

    combine_strings(title, "                         The Ultimate DOOM Startup v", VERSION_STRING);
	combine_strings(title, title, "                        ");

#else
    combine_strings(title, "                          DOOM System Startup v", VERSION_STRING);
	combine_strings(title, title, "                          ");

#endif
	}
	else
	{
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
		    combine_strings(title, "                         DOOM 2: Hell on Earth v", VERSION_STRING);
		    combine_strings(title, title, "                           ");
#endif
	}

	regs.w.ax = 3;
	intx86(0x10, &regs, &regs);
	D_DrawTitle(title);

	DEBUG_PRINT("\nP_Init: Checking cmd-line parameters...");
#endif


	// turbo option
	if ((p = M_CheckParm("-turbo")))
	{
		int16_t     scale = 200;
		extern int8_t forwardmove[2];
		extern int16_t sidemove[2];

		if (p < myargc - 1)
			scale = atoi(myargv[p + 1]);
		if (scale < 10)
			scale = 10;
		if (scale > 400)
			scale = 400;

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

	// init subsystems


	//DEBUG_PRINT("V_Init: allocate screens.\n");
	//V_Init();


	DEBUG_PRINT("\nZ_InitEMS: Init EMS memory allocation daemon.");
	Z_InitEMS();

	DEBUG_PRINT("\nW_Init: Init WADfiles.");
	numlumps = 0;
	W_AddFile(wadfile);
	if (file[0])
		W_AddFile(file);

	DEBUG_PRINT("\nZ_GetEMSPageMap: Init EMS 4.0 features.");
	Z_GetEMSPageMap();

	DEBUG_PRINT("\nZ_LoadBinaries: Load game data into memory");
	Z_LoadBinaries();

	DEBUG_PRINT("\nM_LoadDefaults	: Load system defaults.");
	M_LoadDefaults();              // load before initing other systems

	// init subsystems
	DEBUG_PRINT("\nD_InitStrings: loading text.");
	D_InitStrings();


	// Check for -file in shareware
	#ifdef DEBUG_PRINTING
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

	getStringByIndex(M_INIT_TEXT, textbuffer);
	DEBUG_PRINT(textbuffer);
	D_RedrawTitle(title);
	#endif
	M_Init();

	// 6350 493 10
	//I_Error("\n%u %u %hhi %s", stringoffsets[E3TEXT], stringoffsets[E3TEXT + 1] - stringoffsets[E3TEXT], textbuffer[0], textbuffer);


#ifdef DEBUG_PRINTING
	getStringByIndex(R_INIT_TEXT, textbuffer);
	DEBUG_PRINT(textbuffer);
	D_RedrawTitle(title);
#endif
	//DUMP_MEMORY_TO_FILE();
	R_Init();


#ifdef DEBUG_PRINTING
	getStringByIndex(P_INIT_TEXT, textbuffer);
	DEBUG_PRINT(textbuffer);
	D_RedrawTitle(title);
#endif
	P_Init();


#ifdef DEBUG_PRINTING
	getStringByIndex(I_INIT_TEXT, textbuffer);
	DEBUG_PRINT(textbuffer);
	D_RedrawTitle(title);
#endif
	I_Init();
	maketic = 0;

#ifdef DEBUG_PRINTING
	getStringByIndex(S_INIT_TEXT, textbuffer);
	DEBUG_PRINT(textbuffer);
	D_RedrawTitle(title);
#endif
	//S_Init(sfxVolume * 8, musicVolume * 8);

#ifdef DEBUG_PRINTING
	getStringByIndex(HU_INIT_TEXT, textbuffer);
	DEBUG_PRINT(textbuffer);
	D_RedrawTitle(title);
#endif
	HU_Init();

#ifdef DEBUG_PRINTING
	getStringByIndex(ST_INIT_TEXT, textbuffer);
	DEBUG_PRINT(textbuffer);
	D_RedrawTitle(title);
#endif
	ST_Init();

	// moving this here. We want to load automap related wad lumps into physics ems pages now rather than lazily load it where pages are in a dynamic state.
	AM_loadPics();


	// todo - move this below code in between doommain2 and doomloop?

	// start the apropriate game based on parms
	p = M_CheckParm("-record");

	if (p && p < myargc - 1)
	{
		G_RecordDemo(myargv[p + 1]);
		autostart = true;
	}

	p = M_CheckParm("-playdemo");
	if (p && p < myargc - 1)
	{
		singledemo = true;              // quit after one demo
		G_DeferedPlayDemo(myargv[p + 1]);
		return;
 	}

	p = M_CheckParm("-timedemo");
	if (p && p < myargc - 1)
	{
		G_TimeDemo(myargv[p + 1]);
		return; 
 	}

	p = M_CheckParm("-loadgame");
	if (p && p < myargc - 1) {

		makesavegamename(file, myargv[p + 1][0]);
		G_LoadGame(file);
	}


	if (gameaction != ga_loadgame)
	{
		if (autostart)
			G_InitNew(startskill, startepisode, startmap);
		else
			D_StartTitle();                // start up intro loop

	}

}



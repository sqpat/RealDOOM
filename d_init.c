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
//#include <graph.h>
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

#include <malloc.h>
#include <dos.h>

#define MAX_STRINGS 306

extern uint8_t     sfxVolume;
extern uint8_t     musicVolume;
extern int8_t      demosequence;
//extern byte*		stringdata;
#define stringdata ((byte __far*)0x60000000)

void D_InitStrings() {

	// load file
	FILE* handle;
	//filelength_t length;
	int16_t i;
	int16_t j = 0;
	int8_t letter;
	uint16_t stringbuffersize;
	handle = fopen("dstrings.txt", "rb");
	if (handle == NULL) {
		I_Error("strings.txt missing?\n");
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
			letter = fgetc(handle);
			stringdata[i ] = letter;
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
			};

			if (feof(handle)) {
				break;
			}
		}
		stringbuffersize = stringoffsets[j];
		if (feof(handle)) {
			break;
		}
		I_Error("99"); // Strings too big. Need to implement 2nd page?
		//page++;
		//lastbuffer = buffer;

		//carryover = i - stringoffsets[j];

	}


	fclose(handle);


}


//
// D_StartTitle
//
void D_StartTitle(void)
{
	gameaction = ga_nothing;
	demosequence = -1;
	D_AdvanceDemo();
}

//
// D_GetCursorColumn
//
int16_t D_GetCursorColumn(void)
{
	union REGS regs;

	regs.h.ah = 3;
	regs.h.bh = 0;
	intx86(0x10, &regs, &regs);

	return regs.h.dl;
}

//
// D_GetCursorRow
//
int16_t D_GetCursorRow(void)
{
	union REGS regs;

	regs.h.ah = 3;
	regs.h.bh = 0;
	intx86(0x10, &regs, &regs);

	return regs.h.dh;
}

//
// D_SetCursorPosition
//
void D_SetCursorPosition(int16_t column, int16_t row)
{
	union REGS regs;

	regs.h.dh = row;
	regs.h.dl = column;
	regs.h.ah = 2;
	regs.h.bh = 0;
	intx86(0x10, &regs, &regs);
}

//
// D_DrawTitle
//
void D_DrawTitle(int8_t __near *string)
{
	union REGS regs;
	int16_t column;
	int16_t row;
	int16_t i;

	//Calculate text color

	//Get column position
	column = D_GetCursorColumn();

	//Get row position
	row = D_GetCursorRow();

	for (i = 0; i < strlen(string); i++)
	{
		//Set character
		regs.h.ah = 9;
		regs.h.al = string[i];
		regs.w.cx = 1;
		regs.h.bl = (BGCOLOR << 4) | FGCOLOR; 
		regs.h.bh = 0;
		intx86(0x10, &regs, &regs);

		//Check cursor position
		if (++column > 79)
			column = 0;

		//Set position
		D_SetCursorPosition(column, row);
	}
}


//      print title for every printed line

//
// D_RedrawTitle
//
void D_RedrawTitle(int8_t __near *title)
{
	int16_t column;
	int16_t row;

	//Get current cursor pos
	column = D_GetCursorColumn();
	row = D_GetCursorRow();

	//Set cursor pos to zero
	D_SetCursorPosition(0, 0);

	//Draw title
	D_DrawTitle(title);

	//Restore old cursor pos
	D_SetCursorPosition(column, row);
}

//
// D_AddFile
//
void D_AddFile(int8_t*file)
{
	int8_t     numwadfiles;
	int8_t    *newfile;

	for (numwadfiles = 0; wadfiles[numwadfiles]; numwadfiles++)
		;

	newfile = malloc(strlen(file) + 1);
	strcpy(newfile, file);

	wadfiles[numwadfiles] = newfile;
}

//
// IdentifyVersion
// Checks availability of IWAD files by name,
// to determine whether registered/commercial features
// should be executed (notably loading PWAD's).
//
void IdentifyVersion(void)
{
	
	if (!access("doom2.wad", R_OK))
	{
		commercial = true;
		D_AddFile("doom2.wad");
		return;
	}

#if (EXE_VERSION >= EXE_VERSION_FINAL)
	if (!access("plutonia.wad", R_OK))
	{
		commercial = true;
		plutonia = true;
		D_AddFile("plutonia.wad");
		return;
	}

	if (!access("tnt.wad", R_OK))
	{
		commercial = true;
		tnt = true;
		D_AddFile("tnt.wad");
		return;
	}
#endif

	if (!access("doom.wad", R_OK))
	{
		registered = true;
		D_AddFile("doom.wad");
		return;
	}

	if (!access("doom1.wad", R_OK))
	{
		shareware = true;
		D_AddFile("doom1.wad");
		return;
	}

	DEBUG_PRINT("Game mode indeterminate.\n");
	exit(1);
}


 



//
// M_LoadDefaults
//
extern byte	scantokey[128];
extern int8_t*	defaultfile;




void M_LoadDefaults(void)
{
	int16_t		i;
	FILE*	f;
	int8_t	line[100];
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
		while (!feof(f)) {
			if (fscanf(f, "%s %[^\n]\n", def, strparm) == 2) {
				sscanf(strparm, "%i", &parm);
				for (i = 0; i < NUM_DEFAULTS; i++) {
					if (!strcmp(def, defaults[i].name)) {
						*(defaults[i].location) = parm;
						break;
					}
				}
			}
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


void HU_Init(void)
{

	int16_t		i;
	int16_t		j;
	int8_t	buffer[9];

	Z_QuickmapStatus();

	// load the heads-up font
	j = HU_FONTSTART;
	for (i = 0; i < HU_FONTSIZE; i++) {
		sprintf(buffer, "STCFN%.3d", j++);
		W_CacheLumpNameDirect(buffer, (byte __far*)(MK_FP(ST_GRAPHICS_SEGMENT, hu_font[i])));
	}


	Z_QuickmapPhysics();


}


//
// Initializes sound stuff, including volume
// Sets channels, SFX and music volume,
//  allocates channel buffer, sets S_sfx lookup.
//
void S_Init
(uint8_t		sfxVolume,
	uint8_t		musicVolume)
{

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

//
// DOOM MENU
//
 

extern menu_t __near* currentMenu;
extern menu_t  MainDef;
extern int16_t           itemOn;                 // menu item skull is on
extern int16_t           skullAnimCounter;       // skull animation counter
extern int16_t           whichSkull;             // which skull to draw
extern uint8_t                     screenSize;
extern uint8_t                     messageToPrint;
extern int8_t*                   messageString;
extern int16_t                     messageLastMenuActive;
extern uint8_t                     quickSaveSlot;
extern uint8_t                     screenblocks;           // has default
extern menuitem_t MainMenu[6];

//
// DOOM MENU
//
extern menu_t  NewDef; 
extern menu_t  ReadDef1;


extern menuitem_t ReadMenu1[1];

void M_DrawReadThisRetail(void);
void M_FinishReadThis(int16_t choice);




//
// M_Init
//
 
#ifndef __DEMO_ONLY_BINARY

extern void M_Reload(void);

void M_Init(void)
{
	

	Z_QuickmapMenu();

	M_Reload();
	

	currentMenu = &MainDef;
	menuactive = 0;
	itemOn = currentMenu->lastOn;
	whichSkull = 0;
	skullAnimCounter = 10;
	screenSize = screenblocks - 3;
	messageToPrint = 0;
	messageString = NULL;
	messageLastMenuActive = menuactive;
	quickSaveSlot = -1;  // means to pick a slot now

	if (commercial)
	{
		MainMenu[readthis] = MainMenu[quitdoom];
		MainDef.numitems--;
		MainDef.y += 8;
		NewDef.prevMenu = &MainDef;
		ReadDef1.routine = M_DrawReadThisRetail;
		ReadDef1.x = 330;
		ReadDef1.y = 165;
		ReadMenu1[0].routine = M_FinishReadThis;
	}

	Z_QuickmapPhysics();

	
}
#endif

// ugly and gross, but we need to know the sizes of fields early 
// to be able to allocate the right amount of memory for them
void D_InitGraphicCounts() {

 

	// memory addresses, must stay int_32...
	int16_t __far*                maptex;
	int16_t __far*                maptex2;
 
	int16_t                 numtextures1;
	int16_t                 numtextures2;
		 
	// Load the map texture definitions from textures.lmp.
	// The data is contained in one or two lumps,
	//  TEXTURE1 for shareware, plus TEXTURE2 for commercial.
	W_CacheLumpNameDirect("TEXTURE1", (byte __far*)0x70000000);
	maptex = (int16_t __far*) 0x70000000;
	numtextures1 = (*maptex);
 
	if (W_CheckNumForName("TEXTURE2") != -1) {
		W_CacheLumpNameDirect("TEXTURE2", (byte __far*)0x70000000);
		maptex2 = (int16_t __far*) 0x70000000;
		numtextures2 = (*maptex2);
	}
	else
	{
		numtextures2 = 0;
	}
	numtextures = numtextures1 + numtextures2;



	firstflat = W_GetNumForName("F_START") + 1;
	lastflat = W_GetNumForName("F_END") - 1;
	numflats = lastflat - firstflat + 1;

	firstpatch = W_GetNumForName("P_START") + 1;
	lastpatch = W_GetNumForName("P_END") - 1;
	numpatches = lastpatch - firstpatch + 1;

	firstspritelump = W_GetNumForName("S_START") + 1;
	lastspritelump = W_GetNumForName("S_END") - 1;
	numspritelumps = lastspritelump - firstspritelump + 1;

	//         NUMTEX TEX1 TEX2 FLATS PATCHES SPRITELUMPS
	// SHARWR:  125   125  0     56    167    483
	// DOOM 1:  286   121  161   111   356    764
	// DOOM 2:  428   428  0     153   476    1381
	/*
	I_Error("\nHere: %i %i %i %i %i %i",
		
		numtextures,numtextures1,numtextures2,
		numflats, numpatches, numspritelumps

		);
		*/

}


void AM_loadPics(void)
{
	int8_t i;
	int16_t lump;
	int8_t namebuf[9];
	uint16_t offset = 0;


	for (i = 0; i < 10; i++) {
		sprintf(namebuf, "AMMNUM%d", i);
		ammnumpatchoffsets[i] = offset;
		lump = W_GetNumForName(namebuf);
		W_CacheLumpNumDirect(lump, &ammnumpatchbytes[offset]);
		offset += W_LumpLength(lump);
	}

}

//
// D_DoomMain
//
void D_DoomMain2(void)
{
	int16_t             p;
	int8_t                    file[256];
	union REGS regs;
	int8_t          textbuffer[256];
	int8_t            title[128];
	
	//2d7e dosbox 3128 86box
	/*
	int16_t mallocsize = 8192;
	byte __far* someptr1 = _fmalloc(mallocsize);
	byte __far* someptr2 = _fmalloc(mallocsize);
	byte __far* someptr3 = _fmalloc(mallocsize);
	byte __far* someptr4 = _fmalloc(mallocsize);
	byte __far* someptr5 = _fmalloc(mallocsize);
	byte __far* someptr6 = _fmalloc(mallocsize);
	byte __far* someptr7 = _fmalloc(mallocsize);
	byte __far* someptr8 = _fmalloc(mallocsize);
	I_Error("\npointer is \n%Fp\n%Fp\n%Fp\n%Fp\n%Fp\n%Fp\n%Fp\n%Fp", 
		someptr1, someptr2, someptr3, someptr4, 
		someptr5, someptr6, someptr7, someptr8);
*/

		/*

		I_Error("\n\n%Fp %Fp %Fp %Fp\n%Fp %Fp %Fp %Fp\n%Fp %Fp %Fp %Fp\n%Fp %Fp %Fp %Fp\n%p",
		colormapbytes, openings, negonearray, screenheightarray,
		vissprites, scalelightfixed, scalelight, usedcompositetexturepagemem,
		usedspritepagemem, usedpatchpagemem, compositetextureoffset, compositetexturepage,
			spritepage, spriteoffset, patchpage, patchoffset,
			
			size_patchoffset);

	I_Error("\n\n%Fp %Fp %Fp %Fp\n%Fp %Fp %Fp %Fp\n%Fp %Fp %Fp %Fp\n%Fp %Fp %Fp %p",
		visplanes, visplaneheaders, yslope, distscale,
		cachedheight, cacheddistance, cachedxstep, cachedystep,
		spanstart, viewangletox, xtoviewangle, drawsegs,
		floorclip, ceilingclip, flatindex, size_flatindex);
 
	I_Error("\n\n%Fp %Fp %Fp %Fp\n%Fp %Fp %Fp %Fp\n",
		nodes_render, sides_render, segs_render, spritewidths,
		spriteoffsets, spritetopoffsets, RENDER_SCRATCH, 0L
		);
  	I_Error("\n\n%Fp %Fp %Fp %Fp\n%p %p %p %p\n",
		zlight, texturecolumnlumps_bytes, texturecolumnofs_bytes, texturedefs_bytes,
		size_texturedefs_bytes, 0, 0, 0
	);
	I_Error("\n%Fp %Fp %Fp %p", spritewidths, spriteoffsets, spritetopoffsets, size_spritetopoffsets);

	*/



	/*

	I_Error("\nsectors_physics: %Fp\nsegs_physics: %Fp\nlines_physics: %Fp\nblocklinks: %Fp\nblockmaplump: %Fp\nlinebuffer: %Fp\nnightmarespawns: %Fp\nrejectmatrix: %Fp\nnodes_render: %Fp\nsides_render: %Fp\nsegs_render: %Fp\nRENDER_SCRATCH: %Fp",
		sectors_physics, 
		segs_physics, 
		lines_physics, 
		blocklinks,
		blockmaplump,
		linebuffer,
		nightmarespawns,
		rejectmatrix,

		nodes_render, 
		sides_render, 
		segs_render, 
		RENDER_SCRATCH
	
	);





	I_Error("\ncolormapbytes: %Fp\nopenings: %Fp\nnegonearray: %Fp\nscreenheightarray: %Fp\nvissprites: %Fp\nscalelightfixed: %Fp\nscalelightfixed: %Fp\nscalelight: %Fp\nusedcompositetexturepagemem: %Fp\nusedspritepagemem: %Fp\nusedpatchpagemem: %Fp\nspritewidths: %Fp",
	colormapbytes,openings,negonearray,screenheightarray,vissprites,scalelightfixed,scalelight,usedcompositetexturepagemem,usedspritepagemem,usedpatchpagemem,spritewidths
	); 

	I_Error("\n%u %u %u %u %u %u %u %u %u %u %u %u %u %u %u %u %u %u",
		MAX_SIDES_SIZE,		
		MAX_SECTORS_SIZE,
		MAX_VERTEXES_SIZE,
		MAX_LINES_SIZE,
		MAX_SUBSECTORS_SIZE,
		MAX_NODES_SIZE,
		
		MAX_SEGS_SIZE,
		MAX_SEGS_PHYSICS_SIZE,
		MAX_SECTORS_PHYSICS_SIZE,
		
		MAX_LINES_PHYSICS_SIZE,
		MAX_SIDES_RENDER_SIZE,
		MAX_NODES_RENDER_SIZE,
		MAX_SEGS_RENDER_SIZE,

		MAX_LINEBUFFER_SIZE,
		MAX_BLOCKMAP_LUMPSIZE,
		MAX_BLOCKLINKS_SIZE,123
	);
	*/



	// Removed
	//FindResponseFile ();
	//P_Init();

	IdentifyVersion();

	setbuf(stdout, NULL);
	modifiedgame = false;

	nomonsters = M_CheckParm("-nomonsters");
	respawnparm = M_CheckParm("-respawn");
	fastparm = M_CheckParm("-fast");

#ifdef DEBUG_PRINTING

	if (!commercial)
	{
#if (EXE_VERSION >= EXE_VERSION_ULTIMATE)
		sprintf(title,
			"                         "
			"The Ultimate DOOM Startup v%i.%i"
			"                        ",
			VERSION / 100, VERSION % 100);
#else
		sprintf(title,
			"                          "
			"DOOM System Startup v%i.%i"
			"                          ",
			VERSION / 100, VERSION % 100);
#endif
	}
	else
	{
#if (EXE_VERSION >= EXE_VERSION_FINAL)
		if (plutonia)
		{
			sprintf(title,
				"                   "
				"DOOM 2: Plutonia Experiment v%i.%i"
				"                           ",
				VERSION / 100, VERSION % 100);
		}
		else if (tnt)
		{
			sprintf(title,
				"                     "
				"DOOM 2: TNT - Evilution v%i.%i"
				"                           ",
				VERSION / 100, VERSION % 100);
		}
		else
		{
			sprintf(title,
				"                         "
				"DOOM 2: Hell on Earth v%i.%i"
				"                           ",
				VERSION / 100, VERSION % 100);
		}
#else
		sprintf(title,
			"                         "
			"DOOM 2: Hell on Earth v%i.%i"
			"                           ",
			VERSION / 100, VERSION % 100);
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


	p = M_CheckParm("-file");
	if (p)
	{
		// the parms after p are wadfile/lump names,
		// until end of parms or another - preceded parm
		modifiedgame = true;            // homebrew levels
		while (++p != myargc && myargv[p][0] != '-') {
			D_AddFile(myargv[p]);
		}
	}

	p = M_CheckParm("-playdemo");

	if (!p)
		p = M_CheckParm("-timedemo");

	if (p && p < myargc - 1)
	{
		sprintf(file, "%s.lmp", myargv[p + 1]);
		D_AddFile(file);
		DEBUG_PRINT("Playing demo %s.lmp.\n", myargv[p + 1]);
	}

	// get skill / episode / map from parms
	startskill = sk_medium;
	startepisode = 1;
	startmap = 1;
	autostart = false;


	p = M_CheckParm("-skill");
	if (p && p < myargc - 1)
	{
		startskill = myargv[p + 1][0] - '1';
		autostart = true;
	}

	p = M_CheckParm("-episode");
	if (p && p < myargc - 1)
	{
		startepisode = myargv[p + 1][0] - '0';
		startmap = 1;
		autostart = true;
	}


	p = M_CheckParm("-warp");
	if (p && p < myargc - 1)
	{
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

	DEBUG_PRINT("\nM_LoadDefaults: Load system defaults.");
	M_LoadDefaults();              // load before initing other systems

	DEBUG_PRINT("\nZ_InitEMS: Init EMS memory allocation daemon.");
	Z_InitEMS();

	DEBUG_PRINT("\nW_Init: Init WADfiles.");
	W_InitMultipleFiles(wadfiles);
	D_InitGraphicCounts(); // gross

	DEBUG_PRINT("\nZ_InitUMB: Init UMB Allocations.");
	Z_InitUMB();

	DEBUG_PRINT("\nZ_GetEMSPageMap: Init EMS 4.0 features.");
	Z_GetEMSPageMap();



	DEBUG_PRINT("\nZ_LinkEMSVariables: Place variables in specified memory addresses");
	Z_LinkEMSVariables();
	Z_LinkConventionalVariables();

	DEBUG_PRINT("\nZ_LoadBinaries: Load game data into memory");
	Z_LoadBinaries();


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
	S_Init(sfxVolume * 8, musicVolume * 8);

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

	//byte __far* someptr = ;
	//I_Error("\npointer is %Fp %Fp %Fp %Fp", _fmalloc(1024), _fmalloc(1024), _fmalloc(1024), _fmalloc(1024));

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
		return; // D_DoomLoop always called after this anyway;
		//D_DoomLoop();  // never returns
	}

	p = M_CheckParm("-timedemo");
	if (p && p < myargc - 1)
	{
		G_TimeDemo(myargv[p + 1]);
		return; // D_DoomLoop always called after this anyway;
		//D_DoomLoop();  // never returns
	}

	p = M_CheckParm("-loadgame");
	if (p && p < myargc - 1)
	{
		sprintf(file, SAVEGAMENAME"%c.dsg", myargv[p + 1][0]);
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



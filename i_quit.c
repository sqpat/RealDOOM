#include <dos.h>
#include <conio.h>
#include <graph.h>
#include <stdint.h>

#include <stdlib.h>
#include <stdarg.h>
#include "d_main.h"
#include "doomstat.h"
#include "doomdef.h"
#include "r_local.h"
#include "sounds.h"
#include "i_system.h"
#include "i_sound.h"
#include "g_game.h"
#include "m_misc.h"
#include "v_video.h"
#include "w_wad.h"
#include "z_zone.h"
#include "dmx.h"
#include "m_near.h"


//
// I_ShutdownSound
// Shuts down all sound stuff
//
/*

void __near finishlogging(){
    FILE* fp = fopen("outp.txt", "wb");
    FAR_fwrite(MK_FP(0xDC00, 0), 16384, 1, fp);
    fclose(fp);
}
*/

void	SB_Shutdown();

void __near I_ShutdownSound(void) {

    if (playingdriver){
        playingdriver->stopMusic();
		playingdriver->deinitHardware();
    }
	//finishlogging();
	// sfx shutdown
	SB_Shutdown();


}

//
// I_ShutdownGraphics
//
void __near I_ShutdownGraphics(void) {
	if (*(byte __far*)(MK_FP(0000, 0x449)) == 0x13) // don't reset mode if it didn't get set
	{
		regs.w.ax = 3;
		intx86(0x10, &regs, &regs); // back to text mode
	}
}

#define KEYBOARDINT 9

#define TRUE (1 == 1)
#define FALSE (!TRUE)


void __interrupt __far_func TS_ServiceScheduleIntEnabled(void);
//void RestoreRealTimeClock(void);


int16_t __far I_ResetMouse(void);



void __near I_ShutdownTimer(void) {
	// set timer to maximum rate

	_disable();
	outp(0x43, 0x36);
	outp(0x40, 0x00);
	outp(0x40, 0x00);
	_enable();	
	if (TS_Installed) {
		_dos_setvect(0x08, OldInt8);
		// Set Date and Time from CMOS
		//      RestoreRealTimeClock();
		TS_Installed = FALSE;
	}
}


void __near I_ShutdownKeyboard(void) {
	if (oldkeyboardisr){
		_dos_setvect(KEYBOARDINT, oldkeyboardisr);
	}
	*(int16_t __far*)0x41c = *(int16_t __far*)0x41a;      // clear bios key buffer
}
 

//
// ShutdownMouse
//
void __near I_ShutdownMouse(void) {
	if (!mousepresent) {
		return;
	}

	I_ResetMouse();
}


void __near Z_ShutdownEMS() {


	int16_t result;

	#if defined(__CHIPSET_BUILD)
			// dont do anything
		Z_QuickMapUnmapAll();
	#else


		if (emshandle) {
			Z_QuickMapUnmapAll();

			regs.w.dx = emshandle; // handle
			regs.h.ah = 0x45;
			intx86(EMS_INT, &regs, &regs);
			result = regs.h.ah;
			if (result != 0) {
				DEBUG_PRINT("Failed deallocating EMS memory! %i!\n", result);
			}
		}
	#endif


}


void hackDSBack();

//
// I_Shutdown
// return to default system state
//
// called from I_Error
void __near I_Shutdown(void) {
	int8_t i;
	for (i = 0; i < currentloadedfileindex; i++){
		if (wadfiles[i]){
			fclose(wadfiles[i]);
		}
	}

	I_ShutdownGraphics();
	I_ShutdownSound();
	I_ShutdownTimer();
	I_ShutdownMouse();
	I_ShutdownKeyboard();
	Z_ShutdownEMS();
	hackDSBack();
	//Z_ShutdownUMB();
}





//
// M_CheckParm
// Checks for the given parameter
// in the program's command line arguments.
// Returns the argument number (1 to argc-1)
// or 0 if not present


int16_t __far M_CheckParm (int8_t *check) {
    int16_t		i;
	// ASSUMES *check is LOWERCASE. dont pass in uppercase!
	// myargv must be tolower()
	// trying to avoid strcasecmp dependency.
    for (i = 1;i<myargc;i++) {
		// technically this runs over and over for myargv, 
		// but its during initialization so who cares speed-wise. 
		// code is smaller to stick it here rather than make a loop elsewhere (i think)
		locallib_strlwr(myargv[i]);
		if ( !locallib_strcmp(check, myargv[i]) )
			return i;
		}

    return 0;
}


//
// M_SaveDefaults
//
void __near M_SaveDefaults (void);
/*
void __near M_SaveDefaults (void) {
    int8_t		i;
    int8_t		j;
    uint8_t		v;
    FILE*	f;
	int8_t	currentvchar;
    f = fopen (defaultfile, "w");
    if (!f){
	    return; // can't write the file, but don't complain
	}
    for (i=0 ; i< NUM_DEFAULTS; i++) {
        if (defaults[i].scantranslate){
            defaults[i].location = &defaults[i].untranslated;
        }
		v = *defaults[i].location;

		// replaced fprintf with this monstrosity.

		for (j = 0; defaults[i].name[j] != '\0'; j++){
			fputc(defaults[i].name[j],f);
		}
		fputc('\t',f);
		fputc('\t',f);
		if (v >= 200){
			fputc('2',f);
			v-=200;
		} else if (v >= 100){
			fputc('1',f);
			v-=100;
		}
		if (v >= 10){
			fputc('0' + v / 10,f);
			v = v % 10;
		}
		fputc('0' + v,f);
		fputc('\n',f);

    }
	
    fclose (f);

}
*/

//
// M_LoadDefaults
//

/*
void __far M_LoadDefaults(void) {
	int16_t		i;
	FILE*	f;
	int8_t	strparm[80];
	int8_t	def[80];
	uint8_t		parm;

	// set everything to base values
	for (i = 0; i < NUM_DEFAULTS; i++){
		*defaults[i].location = defaults[i].defaultvalue;
	}

	// check for a custom default file
	i = M_CheckParm("-config");
	if (i && i < myargc - 1) {
		defaultfile = myargv[i + 1];
		DEBUG_PRINT("	default file: %s\n", defaultfile);
	} else {
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
						if (!locallib_strcmp(def, defaults[i].name)) {
							*(defaults[i].location) = parm;
							break;
						}
					}
				}
			}



		}
		

		fclose(f);
	}
	for (i = 0; i < NUM_DEFAULTS; i++) {
		if (defaults[i].scantranslate) {
			parm = *defaults[i].location;
			defaults[i].untranslated = parm;
			*defaults[i].location = scantokey[parm];
		}
	}
}
*/



//
// I_Quit
//
// Shuts down net game, saves defaults, prints the exit text message,
// goes to text mode, and exits.
//
void __near I_Quit(void) {

	if (demorecording) {
		G_CheckDemoStatus();
	}

	M_SaveDefaults();
	I_ShutdownGraphics();
	I_ShutdownSound();
	I_ShutdownTimer();
	I_ShutdownMouse();
	I_ShutdownKeyboard();
	


	W_CacheLumpNameDirect("ENDOOM", (byte __far *)0xb8000000);
	

	regs.w.ax = 0x0200;
	regs.h.bh = 0;
	regs.h.dl = 0;
	regs.h.dh = 23;
	intx86(0x10, (union REGS *)&regs, &regs); // Set text pos
	
	//printf("\n");
	Z_ShutdownEMS();
	//Z_ShutdownUMB();
	hackDSBack();


	exit(1);
}

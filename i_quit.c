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


extern union REGS regs;
extern struct SREGS segregs;

//
// I_ShutdownSound
// Shuts down all sound stuff
//
void __near I_ShutdownSound(void)
{
	/*
	ticcount_t s;
	extern volatile ticcount_t ticcount;
	S_PauseSound();
	s = ticcount + 30;
	while (s != ticcount);
	DMX_DeInit();
	*/
}

//
// I_ShutdownGraphics
//
void __near I_ShutdownGraphics(void) {
	if (*(byte __far*)0x449 == 0x13) // don't reset mode if it didn't get set
	{
		regs.w.ax = 3;
		intx86(0x10, &regs, &regs); // back to text mode
	}
}

extern void( __interrupt __far_func *OldInt8)(void);
extern void  (__interrupt __far_func *oldkeyboardisr) (void);
#define KEYBOARDINT 9

extern task HeadTask;
extern int8_t TS_Installed;
extern volatile int32_t TS_InInterrupt;
#define TRUE (1 == 1)
#define FALSE (!TRUE)


void TS_FreeTaskList(void);
void TS_SetClockSpeed(int32_t speed);
void TS_SetTimerToMaxTaskRate(void);
//void __interrupt __far_func TS_ServiceSchedule(void);
void __interrupt __far_func TS_ServiceScheduleIntEnabled(void);
//void RestoreRealTimeClock(void);



extern boolean mousepresent;
extern boolean usemouse;
int16_t __far I_ResetMouse(void);


/*---------------------------------------------------------------------
   Function: TS_Terminate

   Ends processing of a specific task.
---------------------------------------------------------------------*/

void __near TS_Terminate()

{
	//_disable();
	//free(&HeadTask);
	TS_SetTimerToMaxTaskRate();
	//_enable();


}

/*---------------------------------------------------------------------
   Function: TS_Shutdown

   Ends processing of all tasks.
---------------------------------------------------------------------*/

void __near TS_Shutdown(void) {
	if (TS_Installed)
	{
		TS_FreeTaskList();
		TS_SetClockSpeed(0);
		_dos_setvect(0x08, OldInt8);


		// Set Date and Time from CMOS
		//      RestoreRealTimeClock();

		TS_Installed = FALSE;
	}
}

void __near I_ShutdownTimer(void)
{
	TS_Terminate();
	TS_Shutdown();
}



void __near I_ShutdownKeyboard(void)
{
	if (oldkeyboardisr)
		_dos_setvect(KEYBOARDINT, oldkeyboardisr);
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




extern int16_t emshandle;
extern uint16_t UMBbase;
//extern byte __far* conventional_far_bytes;
/*


#pragma aux FREE_UMB_MEMORY_1 = \
		"mov    ax, 4900h",     \
		"mov    es, [UMBbase]", \
		"mov    bx, 0000h",		\
		"int    21h",           \
parm[] modify exact[ax bx es];
#pragma aux FREE_UMB_MEMORY_2 = \
		"mov    ax, 4900h",     \
		"mov    es, [UMBbase2]",\
		"mov    bx, 0000h",		\
		"int    21h",           \
parm[] modify exact[ax bx es];
*/

/*
void Z_ShutdownUMB() {
 
 
	if (UMBbase) {
		regs.w.ax = 0x4900;
		segregs.es = UMBbase;
		intx86x(DOSMM_INT, &regs, &regs, &segregs);
		if (regs.x.cflag){
			printf("Failed deallocating UMB 1 memory! %i!\n", regs.w.ax);
		}
	}
	if (regs.x.cflag){
		printf("Failed deallocating UMB 1 memory! %i!\n", regs.w.ax);
	}


	
}
*/







void __near Z_ShutdownEMS() {


	int16_t result;

	if (emshandle) {
		Z_QuickMapUnmapAll();

		#if defined(__SCAMP_BUILD) || defined(__SCAT_BUILD)
			// dont do anything
		#else
			regs.w.dx = emshandle; // handle
			regs.h.ah = 0x45;
			intx86(EMS_INT, &regs, &regs);
			result = regs.h.ah;
			if (result != 0) {
				printf("Failed deallocating EMS memory! %i!\n", result);
			}
		#endif
	}


}



//
// I_Shutdown
// return to default system state
//
// called from I_Error
void __near I_Shutdown(void)
{
	I_ShutdownGraphics();
	I_ShutdownSound();
	I_ShutdownTimer();
	I_ShutdownMouse();
	I_ShutdownKeyboard();
	Z_ShutdownEMS();
	//Z_ShutdownUMB();
}

extern default_t	defaults[28];
extern int8_t* defaultfile;


//
// M_SaveDefaults
//
void __near M_SaveDefaults (void)
{
    int8_t		i;
    int8_t		v;
    FILE*	f;
	
    f = fopen (defaultfile, "w");
    if (!f)
	    return; // can't write the file, but don't complain
		
    for (i=0 ; i< NUM_DEFAULTS; i++) {
        if (defaults[i].scantranslate){
            defaults[i].location = &defaults[i].untranslated;
        }
        //if (defaults[i].defaultvalue > -0xfff && defaults[i].defaultvalue < 0xfff) {
            v = *defaults[i].location;
            fprintf (f,"%s\t\t%i\n",defaults[i].name,v);
        //} else {
        //    fprintf (f,"%s\t\t\"%s\"\n",defaults[i].name,
        //        * (int8_t **) (defaults[i].location));
        //}
    }
	
    fclose (f);
}



//
// I_Quit
//
// Shuts down net game, saves defaults, prints the exit text message,
// goes to text mode, and exits.
//
void __near I_Quit(void)
{

	if (demorecording)
	{
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


	exit(1);
}

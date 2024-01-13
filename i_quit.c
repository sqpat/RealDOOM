#include <dos.h>
#include <conio.h>
#include <stdlib.h>
#include <stdarg.h>
#include <graph.h>
#include <malloc.h>
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
void I_ShutdownSound(void)
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
void I_ShutdownGraphics(void) {
	if (*(byte *)0x449 == 0x13) // don't reset mode if it didn't get set
	{
		regs.w.ax = 3;
		intx86(0x10, &regs, &regs); // back to text mode
	}
}

extern void(__interrupt __far *OldInt8)(void);
extern void (__interrupt __far *oldkeyboardisr) ();
#define KEYBOARDINT 9

extern task HeadTask;
extern int8_t TS_Installed;
extern volatile int32_t TS_InInterrupt;
#define TRUE (1 == 1)
#define FALSE (!TRUE)


void TS_FreeTaskList(void);
void TS_SetClockSpeed(int32_t speed);
uint16_t TS_SetTimer(int32_t TickBase);
void TS_SetTimerToMaxTaskRate(void);
void __interrupt __far TS_ServiceSchedule(void);
void __interrupt __far TS_ServiceScheduleIntEnabled(void);
void TS_Startup(void);
void RestoreRealTimeClock(void);



extern boolean mousepresent;
extern boolean usemouse;
int32_t I_ResetMouse(void);


/*---------------------------------------------------------------------
   Function: TS_Terminate

   Ends processing of a specific task.
---------------------------------------------------------------------*/

void TS_Terminate()

{
	_disable();
	free(&HeadTask);
	TS_SetTimerToMaxTaskRate();
	_enable();


}

/*---------------------------------------------------------------------
   Function: TS_Shutdown

   Ends processing of all tasks.
---------------------------------------------------------------------*/

void TS_Shutdown(
	void)

{
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

void I_ShutdownTimer(void)
{
	TS_Terminate();
	TS_Shutdown();
}



void I_ShutdownKeyboard(void)
{
	if (oldkeyboardisr)
		_dos_setvect(KEYBOARDINT, oldkeyboardisr);
	*(int16_t *)0x41c = *(int16_t *)0x41a;      // clear bios key buffer
}
 

//
// ShutdownMouse
//
void I_ShutdownMouse(void)
{
	if (!mousepresent)
	{
		return;
	}

	I_ResetMouse();
}




extern int16_t emshandle;
extern uint16_t UMBbase, UMBbase2;

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



void Z_ShutdownUMB() {
 
 
	if (UMBbase) {
		regs.w.ax = 0x4900;
		segregs.es = UMBbase;
		intx86x(DOSMM_INT, &regs, &regs, &segregs);
		if (regs.x.cflag){
			printf("Failed deallocating UMB 1 memory! %i!\n", regs.w.ax);
		}
	}
	if (UMBbase2) {
		regs.w.ax = 0x4900;
		segregs.es = UMBbase2;
		intx86x(DOSMM_INT, &regs, &regs, &segregs);
		if (regs.x.cflag){
			printf("Failed deallocating UMB 1 memory! %i!\n", regs.w.ax);
		}
	}


}



int8_t ems_backfill_page_order[24] = { 0, 1, 2, 3, -4, -3, -2, -1, -8, -7, -6, -5, -12, -11, -10, -9, -16, -15, -14, -13, -20, -19, -18, -17 };
extern int16_t pagenum9000;
extern int16_t pageswapargseg;
extern int16_t pageswapargoff;
extern int16_t pageswapargs[total_pages];

void Z_QuickmapUnmapAll() {
	int16_t i;
	for (i = 0; i < 24; i++) {
		pageswapargs[i * 2 + 0] = -1;
		pageswapargs[i * 2 + 1] = pagenum9000 + ems_backfill_page_order[i];
	}

	regs.w.ax = 0x5000;
	regs.w.cx = 0x08; // page count
	regs.w.dx = emshandle; // handle
	segregs.ds = pageswapargseg;
	regs.w.si = pageswapargoff;
	intx86(EMS_INT, &regs, &regs);
	regs.w.ax = 0x5000;
	regs.w.cx = 0x08; // page count
	regs.w.dx = emshandle; // handle
	segregs.ds = pageswapargseg;
	regs.w.si = pageswapargoff+32;
	intx86(EMS_INT, &regs, &regs);
	regs.w.ax = 0x5000;
	regs.w.cx = 0x08; // page count
	regs.w.dx = emshandle; // handle
	segregs.ds = pageswapargseg;
	regs.w.si = pageswapargoff+64;
	intx86(EMS_INT, &regs, &regs);
}


void Z_ShutdownEMS() {


	int16_t result;

	if (emshandle) {
		Z_QuickmapUnmapAll();
		regs.w.dx = emshandle; // handle
		regs.h.ah = 0x45;
		intx86(EMS_INT, &regs, &regs);
		result = regs.h.ah;
		if (result != 0) {
			printf("Failed deallocating EMS memory! %i!\n", result);
		}
	}


}



//
// I_Shutdown
// return to default system state
//
// called from I_Error
void I_Shutdown(void)
{
	I_ShutdownGraphics();
	I_ShutdownSound();
	I_ShutdownTimer();
	I_ShutdownMouse();
	I_ShutdownKeyboard();
	Z_ShutdownEMS();
	Z_ShutdownUMB();
}


//
// I_Quit
//
// Shuts down net game, saves defaults, prints the exit text message,
// goes to text mode, and exits.
//
void I_Quit(void)
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
	


	W_CacheLumpNameDirect("ENDOOM", (byte far *)0xb8000000);
	

	regs.w.ax = 0x0200;
	regs.h.bh = 0;
	regs.h.dl = 0;
	regs.h.dh = 23;
	intx86(0x10, (union REGS *)&regs, &regs); // Set text pos
	
	//printf("\n");
	Z_ShutdownEMS();
	Z_ShutdownUMB();


	exit(1);
}

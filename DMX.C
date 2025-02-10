#include "dmx.h"
#include <dos.h>
#include <conio.h>

#include <stdio.h>
#include <stdlib.h>
#include "m_near.h"
#include "doomdef.h"

// todo all pulled from fastdoom i think and very 32 bit based. need to make this more 16 bit friendly overall
// and less generalized and more specialized


/*---------------------------------------------------------------------
   Global variables
---------------------------------------------------------------------*/



/*---------------------------------------------------------------------
   Function prototypes
---------------------------------------------------------------------*/

uint16_t TS_SetTimer(int32_t TickBase);
void TS_SetTimerToMaxTaskRate(void);
void __interrupt __far_func TS_ServiceScheduleIntEnabled(void);
void TS_Startup(void);

#define HZ_RATE_35 				(1192030L / 35)
#define HZ_RATE_140 			(1192030L / 140)
// 140 / 35
#define HZ_INTERRUPTS_PER_TICK  4




void TS_SetTimerToMaxTaskRate(void){
	// reset interrupt rate
	_disable();
	outp(0x43, 0x36);
	outp(0x40, 0x00);
	outp(0x40, 0x00);
	_enable();
}

void	resetDS();

void __interrupt __far_func TS_ServiceScheduleIntEnabled(void){

	resetDS();

	TS_TimesInInterrupt++;
	TaskServiceCount.w += HZ_RATE_140;
	//todo implement this in asm via carry flag rather than a 32 bit add. 
	// only need a 16 bit variable too.
	if (TaskServiceCount.h.intbits) {
		TaskServiceCount.h.intbits = 0;
		_chain_intr(OldInt8);
	}

	outp(0x20, 0x20); // Acknowledge interrupt

	// catch multiple runs?
	if (TS_InInterrupt) {
		return;
	}

	TS_InInterrupt = true;

	_enable();
	while (TS_TimesInInterrupt) {
		if (HeadTask.active) {
			HeadTask.count ++;
			if (HeadTask.count >= HZ_INTERRUPTS_PER_TICK) {
				HeadTask.count -= HZ_INTERRUPTS_PER_TICK;
				HeadTask.TaskService();
			}
		}
		if (MUSTask.active) {
			// every tick...
			MUSTask.TaskService();
		}
		
		TS_TimesInInterrupt--;
	}
	_disable();


	TS_InInterrupt = false;



}
 

/*---------------------------------------------------------------------
   Function: TS_Startup

   Sets up the task service routine.
---------------------------------------------------------------------*/

void TS_Startup(void){

	if (!TS_Installed) {

		TaskServiceCount.w = 0;
		TS_TimesInInterrupt = 0;

		OldInt8 = _dos_getvect(0x08);
		_dos_setvect(0x08, TS_ServiceScheduleIntEnabled);
		TS_Installed = true;
	}

}


/*---------------------------------------------------------------------
   Function: TS_ScheduleTask

   Schedules a new task for processing.
---------------------------------------------------------------------*/

void TS_ScheduleMainTask( void(*Function)(void )) {
	TS_Startup();
	
	_disable();
	outp(0x43, 0x36);
	outp(0x40, HZ_RATE_140);			// todo will this work 16 bit
	outp(0x40, (HZ_RATE_140) >> 8);
	_enable();

	HeadTask.TaskService = Function;

}



/*---------------------------------------------------------------------
   Function: TS_Dispatch

   Begins processing of all inactive tasks.
---------------------------------------------------------------------*/

void TS_Dispatch(){
	
	_disable();
	HeadTask.active = true;
	MUSTask.active = true;
	_enable();
}

 

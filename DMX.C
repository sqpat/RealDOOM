#define TRUE (1 == 1)
#define FALSE (!TRUE)

//#define LOCKMEMORY
//#define NOINTS
//#define USE_USRHOOKS

#include "dmx.h"
#include <dos.h>
#include <conio.h>
#include <stdio.h>
#include <stdlib.h>
#include "doomdef.h"


/*---------------------------------------------------------------------
   Global variables
---------------------------------------------------------------------*/

task HeadTask;
void(__interrupt __far *OldInt8)(void);
volatile int32_t TaskServiceRate = 0x10000L;
volatile int32_t TaskServiceCount = 0;

volatile int32_t TS_TimesInInterrupt;
int8_t TS_Installed = FALSE;
volatile int32_t TS_InInterrupt = FALSE;

/*---------------------------------------------------------------------
   Function prototypes
---------------------------------------------------------------------*/

void TS_FreeTaskList(void);
void TS_SetClockSpeed(int32_t speed);
uint16_t TS_SetTimer(int32_t TickBase);
void TS_SetTimerToMaxTaskRate(void);
void __interrupt __far TS_ServiceScheduleIntEnabled(void);
void TS_Startup(void);


void TS_FreeTaskList(void)
{
	_disable();
	free(&HeadTask);
	_enable();
}

void TS_SetClockSpeed(int32_t speed)
{
	_disable();
	if ((speed > 0) && (speed < 0x10000L)) {
		TaskServiceRate = speed;
	} else {
		TaskServiceRate = 0x10000L;
	}

	outp(0x43, 0x36);
	outp(0x40, TaskServiceRate);			// todo will this work 16 bit
	outp(0x40, TaskServiceRate >> 8);
	_enable();
}

uint16_t TS_SetTimer(int32_t TickBase)
{
	uint16_t speed;
	// VITI95: OPTIMIZE
	speed = 1192030L / TickBase;
	if (speed < TaskServiceRate)
	{
		TS_SetClockSpeed(speed);
	}

	return (speed);
}

void TS_SetTimerToMaxTaskRate(void)
{
	_disable();
	TS_SetClockSpeed(0x10000L);
	_enable();
}

void __interrupt __far TS_ServiceScheduleIntEnabled(void)
{

	TS_TimesInInterrupt++;
	TaskServiceCount += TaskServiceRate;
	if (TaskServiceCount > 0xffffL)
	{
		TaskServiceCount &= 0xffff;
		_chain_intr(OldInt8);
	}

	outp(0x20, 0x20); // Acknowledge interrupt

	if (TS_InInterrupt)
	{
		return;
	}

	TS_InInterrupt = TRUE;
	_enable();


	while (TS_TimesInInterrupt)
	{
		if (HeadTask.active)
		{
			HeadTask.count += TaskServiceRate;
			if (HeadTask.count >= HeadTask.rate)
			{
				HeadTask.count -= HeadTask.rate;
				HeadTask.TaskService();
			}
		}
		TS_TimesInInterrupt--;
	}

	_disable();


	TS_InInterrupt = FALSE;



}
 

/*---------------------------------------------------------------------
   Function: TS_Startup

   Sets up the task service routine.
---------------------------------------------------------------------*/

void TS_Startup(
	void)

{
	if (!TS_Installed)
	{

		TaskServiceRate = 0x10000L;
		TaskServiceCount = 0;

		TS_TimesInInterrupt = 0;

		OldInt8 = _dos_getvect(0x08);
		_dos_setvect(0x08, TS_ServiceScheduleIntEnabled);

		TS_Installed = TRUE;
	}

}


/*---------------------------------------------------------------------
   Function: TS_ScheduleTask

   Schedules a new task for processing.
---------------------------------------------------------------------*/

void TS_ScheduleTask( void(*Function)(void ), uint16_t rate) {
	TS_Startup();
	HeadTask.TaskService = Function;
	HeadTask.rate = TS_SetTimer(rate);
	HeadTask.count = 0;
	HeadTask.priority = 1;
	HeadTask.active = FALSE;

}



/*---------------------------------------------------------------------
   Function: TS_Dispatch

   Begins processing of all inactive tasks.
---------------------------------------------------------------------*/

void TS_Dispatch(){
	_disable();
	HeadTask.active = TRUE;
	_enable();
}

 

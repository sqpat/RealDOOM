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

uint16_t __near TS_SetTimer(int32_t TickBase);
void __near TS_SetTimerToMaxTaskRate(void);
void __interrupt __far_func TS_ServiceScheduleIntEnabled(void);
void __near TS_Startup(void);

#define HZ_RATE_35 				(1192030L / 35)
#define HZ_RATE_140 			(1192030L / 140)
// 140 / 35
#define HZ_INTERRUPTS_PER_TICK  4



void __near TS_SetTimerToMaxTaskRate(void){
	// reset interrupt rate
	_disable();
	outp(0x43, 0x36);
	outp(0x40, 0x00);
	outp(0x40, 0x00);
	_enable();
}

// void I_TimerISR(void);

//todo move this where it needs to go.



void __near playpcspeakernote(uint16_t value){
	

	if (value){
		if ((lastpcspeakernotevalue != value)){
			uint8_t status ;
			outp (0x43, 0xB6);
			outp (0x42, value &0xFF);
			outp (0x42, value >> 8);
			
			if (status != status | 3){
				outp (0x61, status | 3);
			}
			lastpcspeakernotevalue = value;
		}
	} else {
		uint8_t tmp = inp(0x61) & 0xFC;
		outp(0x61, tmp);
	}



}

void __near playpcspeakernote(uint16_t value);
void	resetDS();
void __near MUS_ServiceRoutine(void);


void __interrupt __far_func TS_ServiceScheduleIntEnabled(void){

	resetDS();

	TS_TimesInInterrupt++;
	TaskServiceCount.w += HZ_RATE_140;
	//todo implement this in asm via carry flag rather than a 32 bit add. 
	// only need a 16 bit variable too.
	if (TaskServiceCount.h.intbits) {
		TaskServiceCount.h.intbits = 0;
		_chain_intr(OldInt9);
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
			// every 4 tics
			if (HeadTask.count >= HZ_INTERRUPTS_PER_TICK) {
				HeadTask.count -= HZ_INTERRUPTS_PER_TICK;
				// I_TimerISR();
			    ticcount++;
			}
		}
		if (MUSTask.active) {
			// every tick...
			MUS_ServiceRoutine();
		}

		// pc speaker sfx support goes in here for now.
		if (pcspeaker_currentoffset){
			// send next sample

			_disable();

			playpcspeakernote(*((uint16_t __far*)MK_FP(SFX_PAGE_SEGMENT_PTR + 0x100 , pcspeaker_currentoffset)));
			
			pcspeaker_currentoffset+=2;
			if (pcspeaker_currentoffset >= pcspeaker_endoffset){
				pcspeaker_currentoffset = 0;
				// ? turn off speaker? todo should this be on next frame?
				outp(0x61, inp(0x61) & 0xFC);

			}
			_enable();
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

void __near TS_Startup(void){

	if (!TS_Installed) {

		TaskServiceCount.w = 0;
		TS_TimesInInterrupt = 0;

		OldInt8 = locallib_dos_getvect(0x08);
		locallib_dos_setvect(0x08, TS_ServiceScheduleIntEnabled);
		TS_Installed = true;
	}

}

/*---------------------------------------------------------------------
   Function: TS_ScheduleTask

   Schedules a new task for processing.
---------------------------------------------------------------------*/
void __near TS_ScheduleMainTask( ) {
	TS_Startup();
	
	_disable();
	outp(0x43, 0x36);
	outp(0x40, HZ_RATE_140);			// todo will this work 16 bit
	outp(0x40, (HZ_RATE_140) >> 8);
	_enable();


}


/*---------------------------------------------------------------------
   Function: TS_Dispatch

   Begins processing of all inactive tasks.
---------------------------------------------------------------------*/
void __near TS_Dispatch(){
	
	_disable();
	HeadTask.active = true;
	if (playingdriver != NULL){
		MUSTask.active = true;
	}
	_enable();
}

 
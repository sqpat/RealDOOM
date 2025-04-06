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
void I_TimerISR(void);
void MUS_ServiceRoutine(void);

//todo move this where it needs to go.

uint16_t pc_speaker_freq_table[128] = {
	   0, 6818, 6628, 6449, 6279, 6087, 5906, 5736, 
	5575, 5423, 5279, 5120, 4971, 4830, 4697, 4554, 
	4435, 4307, 4186, 4058, 3950, 3836, 3728, 3615, 
	3519, 3418, 3323, 3224, 3131, 3043, 2960, 2875, 
	2794, 2711, 2633, 2560, 2485, 2415, 2348, 2281, 
	2213, 2153, 2089, 2032, 1975, 1918, 1864, 1810, 
	1757, 1709, 1659, 1612, 1565, 1521, 1478, 1435, 
	1395, 1355, 1316, 1280, 1242, 1207, 1173, 1140, 
	1107, 1075, 1045, 1015,  986,  959,  931,  905, 
	 879,  854,  829,  806,  783,  760,  739,  718, 
	 697,  677,  658,  640,  621,  604,  586,  570,
     553,  538,  522,  507,  493,  479,  465,  452, 
	 439,  427,  415,  403,  391,  380,  369,  359, 
	 348,  339,  329,  319,  310,  302,  293,  285,
     276,  269,  261,  253,  246,  239,  232,  226, 
     219,  213,  207,  201,  195,  190,  184,  179

	};

void playpcspeakernote(uint8_t samplebyte){
	uint16_t value = pc_speaker_freq_table[samplebyte];

	if (value){
		uint8_t status = inp(0x61);
		outp (0x43, 0xB6);
		outp (0x42, value &0xFF);
		outp (0x42, value >> 8);
		
		//if (status != status | 3){
			outp (0x61, status | 3);
	//	}

	} else {
		uint8_t tmp = inp(0x61) & 0xFC;
		outp(0x61, tmp);
	}



}


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
			// every 4 tics
			if (HeadTask.count >= HZ_INTERRUPTS_PER_TICK) {
				HeadTask.count -= HZ_INTERRUPTS_PER_TICK;
				I_TimerISR();
			}
		}
		if (MUSTask.active) {
			// every tick...
			MUS_ServiceRoutine();
		}

		// pc speaker sfx support goes in here for now.
		if (pcspeaker_currentoffset){
			// send next sample
			byte __far* data = MK_FP(PC_SPEAKER_SFX_DATA_SEGMENT, pcspeaker_currentoffset);
			playpcspeakernote(*data);
			
			pcspeaker_currentoffset++;
			if (pcspeaker_currentoffset == pcspeaker_endoffset){
				pcspeaker_currentoffset = 0;
				// ? turn off speaker?
			}
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

void TS_ScheduleMainTask( ) {
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

void TS_Dispatch(){
	
	_disable();
	HeadTask.active = true;
	MUSTask.active = true;
	_enable();
}

 

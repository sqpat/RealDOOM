#include "doomdef.h"
#include "sc_music.h"
#include "m_near.h"
#include <string.h>
#include <conio.h>
#include <stdlib.h>
#include <stdarg.h>
#include <stdio.h>
#include <graph.h>
#include <i86.h>
#include <mem.h>
#include <malloc.h>
#include <dos.h>




/* I/O addresses (default base = 220h) */
#define DSP_READ_DATA       0x0A
#define DSP_WRITE_DATA      0x0C
#define DSP_WRITE_STATUS    0x0C
#define DSP_DATA_AVAIL      0x0E

/* DSP commands */
#define MIDI_READ_POLL	    0x30
#define MIDI_READ_IRQ	    0x31
#define MIDI_WRITE_POLL     0x38

/* write data to the DAC */
#define writedac(x)						{								\
    uint8_t t = 0xFF;						\
    while (inp(SBMIDIport + DSP_WRITE_STATUS) & (uint8_t)0x80 &&	\
	   --t);						\
    if (!t)							\
	return -1;						\
    outp(SBMIDIport + DSP_WRITE_DATA, (x));			\
}

/* write one byte to SB MIDI data port */
int8_t SBMIDIsendByte(uint8_t value) {
    writedac(MIDI_WRITE_POLL);
    writedac(value);
    return 0;
}

/* write block of bytes to MPU-401 port */
int SBMIDIsendBlock(uint8_t *block, uint16_t length){
    runningStatus = 0;			/* clear the running status byte */

    _disable();
    while (length--){
	    SBMIDIsendByte(*block++);
    }
    _enable();
    return 0;
}


/* send MIDI command */
int8_t SBMIDIsendMIDI(uint8_t command, uint8_t par1, uint8_t par2){
    uint8_t event = command & MIDI_EVENT_MASK;

    if (event == MIDI_NOTE_OFF) {
        /* convert NOTE_OFF to NOTE_ON with zero velocity */
        command = (command & 0x0F) | MIDI_NOTE_ON;
        par2 = 0; /* velocity */
    }

    _disable();
    if (runningStatus != command){
	    SBMIDIsendByte(runningStatus = command);
    }
    SBMIDIsendByte(par1);
    if (event != MIDI_PATCH && event != MIDI_CHAN_TOUCH){
	    SBMIDIsendByte(par2);
    }
    _enable();
    return 0;
}
 
 

int8_t SBMIDIdetectHardware(uint16_t port, uint8_t irq, uint8_t dma){
    runningStatus = 0;
    return 1;				/* always present */
}


int8_t SBMIDIinitHardware(uint16_t port, uint8_t irq, uint8_t dma){
    SBMIDIport = port;
    runningStatus = 0;
    return 0;
}

int8_t SBMIDIdeinitHardware(void){
    runningStatus = 0;
    return 0;
}


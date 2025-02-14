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
//#include <io.h>
#include <dos.h>


// todo move this out?




/*
 * Direct write to any OPL2/OPL3 FM synthesizer register.
 *   reg - register number (range 0x001-0x0F5 and 0x101-0x1F5). When high byte
 *         of reg is zero, data go to port OPLport, otherwise to OPLport+2
 *   data - register value to be written
 */



void donothing(){

}




/* Watcom C */
uint8_t _OPL2writeReg(uint16_t port, uint16_t reg, uint8_t data);
uint8_t _OPL3writeReg(uint16_t port, uint16_t reg, uint8_t data);

 
#pragma aux _OPL2writeReg =	\
	"out	dx,al"		\
	"mov	cx,6"		\
"loop1:	 in	al,dx"		\
	"loop	loop1"		\
	"inc	dx"		\
	"mov	al,bl"		\
	"out	dx,al"		\
	"dec	dx"		\
	"mov	cx,36"		\
"loop2:	 in	al,dx"		\
	"loop	loop2"		\
	parm [DX][AX][BL]	\
	modify exact [AL CX DX] nomemory	\
	value [AL];

#pragma aux _OPL3writeReg =	\
	"or	ah,ah"		\
	"jz	bank0"		\
	"inc	dx"		\
	"inc	dx"		\
"bank0:	 out	dx,al"		\
	"in	al,dx"		\
	"mov	ah,al"		\
	"inc	dx"		\
	"mov	al,bl"		\
	"out	dx,al"		\
	parm [DX][AX][BL]	\
	modify exact [AX DX] nomemory	\
	value [AH];

uint8_t OPLwriteReg(uint16_t reg, uint8_t data){
    if (OPL3mode){
		return _OPL3writeReg(ADLIBPORT, reg, data);
	} else{
		return _OPL2writeReg(ADLIBPORT, reg, data);
	}
}
 

/*
 * Write to an operator pair. To be used for register bases of 0x20, 0x40,
 * 0x60, 0x80 and 0xE0.
 */
void OPLwriteChannel(uint8_t regbase, uint8_t channel, uint8_t data1, uint8_t data2){
    
    uint16_t reg = 0;
    if (channel >= 9){
        channel -= 9;
        reg = 0x100;
    }
    reg += regbase+op_num[channel];

    OPLwriteReg(reg, data1);
    OPLwriteReg(reg+3, data2);
}
 
/*
 * Write to channel a single value. To be used for register bases of
 * 0xA0, 0xB0 and 0xC0.
 */

void OPLwriteValue(uint8_t regbase, uint8_t channel, uint8_t value){
    uint16_t regnum = channel;
    if (channel >= 9){
        regnum += (0x100 - 9);
    }
    OPLwriteReg(regnum + regbase, value);
}

/*
 * Write frequency/octave/keyon data to a channel
 */
void OPLwriteFreq(uint8_t channel, uint16_t freq, uint8_t octave, uint8_t keyon){
    OPLwriteValue(0xA0, channel, freq & 0xFF);
    OPLwriteValue(0xB0, channel, (freq >> 8) | (octave << 2) | (keyon << 5));
}

/*
int8_t noteVolumetable[16] = {
	  0,  11,  25,  37,  52,  66,  76,  84,
	 92,  99, 105, 110, 115, 119, 123, 127} 
     */




/*
 * Adjust volume value (register 0x40)
 */
int8_t OPLconvertVolume(uint8_t data, int8_t noteVolume){
	int16_t_union volumevalue;
	volumevalue.hu = FastMul8u8u(noteVolumetable[noteVolume & 0x7F], (0x3F - data));
	volumevalue.hu <<= 1;
	return 0x3F - volumevalue.bu.bytehigh;
}

int8_t OPLpanVolume(int8_t noteVolume, int8_t pan){
    if (pan >= 0){
		return noteVolume;
	} else{
		return (((int16_t)noteVolume * (pan + 64)) / 64) & 0x7F;
	}
}

/*
 * Write volume data to a channel
 */
void OPLwriteVolume(uint8_t channel, OPL2instrument __far  *instr, int8_t noteVolume){
    OPLwriteChannel(0x40, channel, ((instr->feedback & 1) ?
	OPLconvertVolume(instr->level_1, noteVolume) : instr->level_1) | instr->scale_1,
	OPLconvertVolume(instr->level_2, noteVolume) | instr->scale_2);
}

/*
 * Write pan (balance) data to a channel
 */
void OPLwritePan(uint8_t channel, OPL2instrument __far  *instr, int8_t pan){
    uint8_t bits;
    if (pan < -36) {
		bits = 0x10;		// left
	} else if (pan > 36){
		bits = 0x20;	// right
	} else {
		bits = 0x30;			// both
	}

    OPLwriteValue(0xC0, channel, instr->feedback | bits);
}

/*
 * Write an instrument to a channel
 *
 * Instrument layout:
 *
 *   Operator1  Operator2  Descr.
 *    data[0]    data[7]   reg. 0x20 - tremolo/vibrato/sustain/KSR/multi
 *    data[1]    data[8]   reg. 0x60 - attack rate/decay rate
 *    data[2]    data[9]   reg. 0x80 - sustain level/release rate
 *    data[3]    data[10]  reg. 0xE0 - waveform select
 *    data[4]    data[11]  reg. 0x40 - key scale level
 *    data[5]    data[12]  reg. 0x40 - output level (bottom 6 bits only)
 *          data[6]        reg. 0xC0 - feedback/AM-FM (both operators)
 */
void OPLwriteInstrument(uint8_t channel, OPL2instrument __far  *instr){
    OPLwriteChannel(0x40, channel, 0x3F, 0x3F);		// no volume
    OPLwriteChannel(0x20, channel, instr->trem_vibr_1, instr->trem_vibr_2);
    OPLwriteChannel(0x60, channel, instr->att_dec_1,   instr->att_dec_2);
    OPLwriteChannel(0x80, channel, instr->sust_rel_1,  instr->sust_rel_2);
    OPLwriteChannel(0xE0, channel, instr->wave_1,      instr->wave_2);
    OPLwriteValue  (0xC0, channel, instr->feedback | 0x30);
}

/*
 * Stop all sounds
 */
void OPLshutup(void){
    uint8_t i;

    for(i = 0; i < OPLchannels; i++) {
		OPLwriteChannel(0x40, i, 0x3F, 0x3F);	// turn off volume
		OPLwriteChannel(0x60, i, 0xFF, 0xFF);	// the fastest attack, decay
		OPLwriteChannel(0x80, i, 0x0F, 0x0F);	// ... and release
		OPLwriteValue(0xB0, i, 0);		// KEY-OFF
    }
}

/*
 * Initialize hardware upon startup
 */
void OPLinit(uint16_t port, uint8_t OPL3){

    if ( (OPL3mode = OPL3) != 0) {
		OPLchannels = OPL3CHANNELS;
		OPLwriteReg(0x105, 0x01);	// enable YMF262/OPL3 mode
		OPLwriteReg(0x104, 0x00);	// disable 4-operator mode
    } else {
		OPLchannels = OPL2CHANNELS;
	}
	OPLwriteReg(0x01, 0x20);		// enable Waveform Select
	OPLwriteReg(0x08, 0x40);		// turn off CSW mode
	OPLwriteReg(0xBD, 0x00);		// set vibrato/tremolo depth to low, set melodic mode

    OPLshutup();
}

/*
 * Deinitialize hardware before shutdown
 */
void OPLdeinit(void){
    OPLshutup();
    if (OPL3mode) {
		OPLwriteReg(0x105, 0x00);		// disable YMF262/OPL3 mode
		OPLwriteReg(0x104, 0x00);		// disable 4-operator mode
    }
    OPLwriteReg(0x01, 0x20);			// enable Waveform Select
    OPLwriteReg(0x08, 0x00);			// turn off CSW mode
    OPLwriteReg(0xBD, 0x00);			// set vibrato/tremolo depth to low, set melodic mode
}

/*
 * Detect Adlib card (OPL2)
 */
int16_t OPL2detect(uint16_t port){
    uint16_t origPort = ADLIBPORT;
    uint8_t stat1, stat2, i;


    OPLwriteReg(0x04, 0x60);
    OPLwriteReg(0x04, 0x80);
    stat1 = inp(port) & 0xE0;
    OPLwriteReg(0x02, 0xFF);
    OPLwriteReg(0x04, 0x21);
    for (i = 255; --i;){
		inp(port);
	}
    stat2 = inp(port) & 0xE0;
    OPLwriteReg(0x04, 0x60);
    OPLwriteReg(0x04, 0x80);


    return (stat1 == 0 && stat2 == 0xC0);
}

/*
 * Detect Sound Blaster Pro II (OPL3)
 *
 * Status register contents (inp(port) & 0x06):
 *   OPL2:	6
 *   OPL3:	0
 *   OPL4:	2
 */
int16_t OPL3detect(uint16_t port){
    if (!OPL2detect(port)){
		return 0;
	}

    if (inp(port) & 4){
		return 0;
	}
    return 1;
}




/* Flags: */
#define CH_SECONDARY	0x01
#define CH_SUSTAIN	0x02
#define CH_VIBRATO	0x04		/* set if modulation >= MOD_MIN */
#define CH_FREE		0x80

#define MOD_MIN		40		/* vibrato threshold */





//#define HIGHEST_NOTE 102
#define HIGHEST_NOTE 127


void writeFrequency(uint8_t slot, uint8_t note, uint8_t pitchwheel, uint8_t keyOn){
	uint16_t freq;
    uint8_t octave;

	if (note < 7){
		freq = freqtable[note];
		octave = 0;
	} else {
		int16_t_union div_result = FastDiv16u_8u(note-7, 12);
		freq = freqtable2[div_result.b.bytehigh];
		octave = div_result.b.bytelow;
	}

    if (pitchwheel!= DEFAULT_PITCH_BEND) {
		fixed_t_union product;
		//product.wu = FastMul16u16u(freq, pitchwheeltable[pitchwheel + 128]);
        //product.hu.intbits = 50;
		product.wu = FastMul16u16u(freq, 32767u);
		// need to shift 15 right... or instead:
		freq = product.hu.intbits << 1;
		if (freq >= 1024) {
			freq >>= 1;
			octave++;
		}
    } 
	
    if (octave > 7){
		octave = 7;
	}
    OPLwriteFreq(slot, freq, octave, keyOn);
}

void writeModulation(uint8_t slot, OPL2instrument __far  *instr, uint8_t state){
    if (state){
		state = 0x40;	/* enable Frequency Vibrato */
	}
    OPLwriteChannel(0x20, slot,
	(instr->feedback & 1) ? (instr->trem_vibr_1 | state) : instr->trem_vibr_1,
	instr->trem_vibr_2 | state);
}

int8_t calcVolumeOPL(uint8_t channelVolume, uint16_t systemVolume, int8_t noteVolume){
	fixed_t_union volume_product;
	int16_t_union intermediate;
    intermediate.hu = FastMul8u8u(channelVolume, noteVolume);
    systemVolume <<= 2; // instead of 0-127, 0-512
	volume_product.wu = FastMul16u16u(intermediate.hu, systemVolume);
	// divide by 256...
	intermediate.bu.bytelow = volume_product.bu.fracbytehigh;
	intermediate.bu.bytehigh = volume_product.bu.intbytelow;
	// divide by 127
	intermediate = FastDiv16u_8u(intermediate.hu, 127);
	
	if (intermediate.bu.bytelow > 0x7F){
		return 0x7F;
	} else {
		return intermediate.bu.bytelow;
	}
	
}

uint8_t occupyChannel(uint8_t slot, uint8_t channel,
	uint8_t note, int8_t noteVolume, OP2instrEntry __far *instrument, uint8_t secondary){
    OPL2instrument __far *instr;
	int16_t pitchadder;
    AdlibChannelEntry __far *ch = &AdLibChannels[slot];

    //playingChannels++;

    ch->channel = channel;

    ch->note = note;
    ch->flags = secondary ? CH_SECONDARY : 0;
    if (OPL2driverdata.channelModulation[channel] >= MOD_MIN){
		ch->flags |= CH_VIBRATO;
	}

    ch->time = playingtime;

    if (noteVolume == -1){
		noteVolume = OPL2driverdata.channelLastVolume[channel];
	} else{
		OPL2driverdata.channelLastVolume[channel] = noteVolume;
	}

	ch->noteVolume = noteVolume;
    ch->realvolume = calcVolumeOPL(OPL2driverdata.channelVolume[channel], snd_MusicVolume, noteVolume);
    
	
	if (instrument->flags & FL_FIXED_PITCH){
		note = instrument->note;
	} else if (channel == PERCUSSION){
		note = 60;			// C-5
	}
	
	if (secondary && (instrument->flags & FL_DOUBLE_VOICE)){
		ch->finetune = instrument->finetune;
	} else {
		ch->finetune = DEFAULT_PITCH_BEND;
	}

    pitchadder = ch->finetune + OPL2driverdata.channelPitch[channel];
	ch->pitchwheel = pitchadder & 0xFF;
	
    if (secondary) {
		instr = &instrument->instr[1];
	} else { 
		instr = &instrument->instr[0];
	}
    ch->instr = instr;
	note += instr->basenote;
	note &= 0x7F;
	// todo divide or modulo 127?
    /*
	if ( (usenote += instr->basenote) < 0){
		while ((usenote += 12) < 0){

		}
	} else if (usenote > HIGHEST_NOTE){
		while ((usenote -= 12) > HIGHEST_NOTE){

		}
	}
	*/

    ch->realnote = note;

    OPLwriteInstrument(slot, instr);
    if (ch->flags & CH_VIBRATO){
		writeModulation(slot, instr, 1);
	}
    OPLwritePan(slot, instr, OPL2driverdata.channelPan[channel]);
    OPLwriteVolume(slot, instr, ch->realvolume);
    writeFrequency(slot, note, ch->pitchwheel, 1);
    return slot;
}

void releaseChannel(uint8_t slot, uint8_t killed){
    AdlibChannelEntry __far* ch = &AdLibChannels[slot];
    //playingChannels--;
    writeFrequency(slot, ch->realnote, ch->pitchwheel, 0);
    ch->channel |= CH_FREE;
    ch->flags = CH_FREE;
    if (killed) {
		OPLwriteChannel(0x80, slot, 0x0F, 0x0F);  // release rate - fastest
		OPLwriteChannel(0x40, slot, 0x3F, 0x3F);  // no volume
    }
}

void releaseSustain(uint8_t channel){
    uint8_t i;
    uint8_t id = channel;

    for(i = 0; i < OPLchannels; i++) {
		if (AdLibChannels[i].channel == id && AdLibChannels[i].flags & CH_SUSTAIN){
			releaseChannel(i, 0);
		}
	}
}

int8_t findFreeChannel(uint8_t flag){
    static uint8_t last = 0xFF;
    uint8_t i;
    uint8_t oldest = 0xFF;
    uint32_t oldesttime = playingtime;

    /* find free channel */
    for(i = 0; i < OPLchannels; i++) {
		if (++last == OPLchannels){	/* use cyclic `Next Fit' algorithm */
			last = 0;
		}
		if (AdLibChannels[last].flags & CH_FREE){
			return last;
		}
    }

    if (flag & 1){
		return -1;			/* stop searching if bit 0 is set */
	}

    /* find some 2nd-voice channel and determine the oldest */
    for(i = 0; i < OPLchannels; i++) {
		if (AdLibChannels[i].flags & CH_SECONDARY) {
			releaseChannel(i, -1);
			return i;
		} else
			if (AdLibChannels[i].time < oldesttime) {
			oldesttime = AdLibChannels[i].time;
			oldest = i;
		}
    }

    /* if possible, kill the oldest channel */
    if ( !(flag & 2) && oldest != 0xFF) {
		releaseChannel(oldest, -1);
		return oldest;
    }

    /* can't find any free channel */
    return -1;
}

OP2instrEntry __far * getInstrument(uint8_t channel, uint8_t note) {
    uint8_t instrnumber;
    uint8_t instrindex;

    if (playingpercussMask & (1 << channel)) {
		if (note < 35 || note > 81){
			return NULL;		/* wrong percussion number */
		}
		instrnumber = note + (128-35);
    } else { 
		instrnumber = OPL2driverdata.channelInstr[channel];
	}
	instrindex = instrumentlookup[instrnumber];

	if (instrindex == 0xFF){
		printerror("Bad instrument index %i %i!!\n", instrnumber, instrindex);
		return NULL;
	}
	return &AdLibInstrumentList[instrindex];
}


// code 1: play note
void OPLplayNote(uint8_t channel, uint8_t note, int8_t noteVolume){
    int8_t i;
    OP2instrEntry __far* instr = getInstrument(channel, note);

    if (instr == NULL){
		printerror( "null instrument? %i %i\n", channel, note);
		return;
	}


    if ( (i = findFreeChannel((channel == PERCUSSION) ? 2 : 0)) != -1) {
		occupyChannel(i, channel, note, noteVolume, instr, 0);
		if (!OPLsinglevoice && instr->flags == FL_DOUBLE_VOICE) {
			if ( (i = findFreeChannel((channel == PERCUSSION) ? 3 : 1)) != -1){
				occupyChannel(i, channel, note, noteVolume, instr, 1);
			}
		}
    } else {
		printmessage("no voice found!\n");
	}
}

// code 0: release note
void OPLreleaseNote(uint8_t channel, uint8_t note){
    uint8_t i;
    uint8_t id = channel;

    uint8_t sustain = OPL2driverdata.channelSustain[channel];

    for(i = 0; i < OPLchannels; i++){
		if (AdLibChannels[i].channel == id && AdLibChannels[i].note == note) {
			if (sustain < 0x40){
				releaseChannel(i, 0);
			} else {
				AdLibChannels[i].flags |= CH_SUSTAIN;
			}
		}
	}
}

// code 2: change pitch wheel (bender)
void OPLpitchWheel(uint8_t channel, uint8_t pitch){
    uint8_t i;
    uint8_t id = channel;

    OPL2driverdata.channelPitch[channel] = pitch;
    for(i = 0; i < OPLchannels; i++) {
        AdlibChannelEntry __far  *ch = &AdLibChannels[i];

		if (ch->channel == id) {
			int16_t pitchadder;
			ch->time = playingtime;
			pitchadder = (int16_t)ch->finetune + pitch;
			ch->pitchwheel = (pitchadder & 0xFF);
			writeFrequency(i, ch->realnote, ch->pitchwheel, 1);
		}
    }
}

// code 4: change control
void OPLchangeControl(uint8_t channel, uint8_t controller, uint8_t value){
    uint8_t i;
    uint8_t id = channel;

    switch (controller) {
		case 0:			/* change instrument */
			OPL2driverdata.channelInstr[channel] = value;
			break;
		case 2:
			OPL2driverdata.channelModulation[channel] = value;
			for(i = 0; i < OPLchannels; i++) {
                AdlibChannelEntry __far  *ch = &AdLibChannels[i];
				if (ch->channel == id) {
					uint8_t flags = ch->flags;
					ch->time = playingtime;
					if (value >= MOD_MIN) {
						ch->flags |= CH_VIBRATO;
						if (ch->flags != flags){
							writeModulation(i, ch->instr, 1);
						}
					} else {
						ch->flags &= ~CH_VIBRATO;
						if (ch->flags != flags){
							writeModulation(i, ch->instr, 0);
						}
					}
				}
			}
			break;
		case 3:		/* change volume */
			OPL2driverdata.channelVolume[channel] = value;
			for(i = 0; i < OPLchannels; i++) {
                AdlibChannelEntry __far* ch = &AdLibChannels[i];
				if (ch->channel == id) {
					ch->time = playingtime;
					ch->realvolume = calcVolumeOPL(value, snd_MusicVolume, ch->noteVolume);
					OPLwriteVolume(i, ch->instr, ch->realvolume);
				}
			}
			break;
		case 4:			/* change pan (balance) */
			OPL2driverdata.channelPan[channel] = value -= 64;
			for(i = 0; i < OPLchannels; i++) {
                AdlibChannelEntry __far* ch = &AdLibChannels[i];
				if (ch->channel == id) {
					ch->time = playingtime;
					OPLwritePan(i, ch->instr, value);
				}
			}
			break;
		case 8:		/* change sustain pedal (hold) */
			OPL2driverdata.channelSustain[channel] = value;
			if (value < 0x40){
				releaseSustain(channel);
			}
			break;
    }
}


void OPLplayMusic(){
    uint8_t i;

    for (i = 0; i < MAX_MUSIC_CHANNELS; i++) {
		OPL2driverdata.channelVolume[i] = 127;	/* default volume 127 (full volume) */
		OPL2driverdata.channelSustain[i] = OPL2driverdata.channelLastVolume[i] = 0;
    }
}

void OPLstopMusic(){
    uint8_t i;
    for(i = 0; i < OPLchannels; i++){
		if (!(AdLibChannels[i].flags & CH_FREE)){
			releaseChannel(i, -1);
		}
	}
}

void OPLchangeSystemVolume(uint8_t systemVolume){ // volume is 0-16
    uint8_t *channelVolume = OPL2driverdata.channelVolume;
    uint8_t i;
    for(i = 0; i < OPLchannels; i++) {
        AdlibChannelEntry __far* ch = &AdLibChannels[i];
		ch->realvolume = calcVolumeOPL(channelVolume[ch->channel & 0xF], systemVolume, ch->noteVolume);
		if (playingstate == ST_PLAYING){
			OPLwriteVolume(i, ch->instr, ch->realvolume);
		}
    }
}
 

int8_t OPLinitDriver(void){
    int8_t i;
	FAR_memset(AdLibChannels, 0xFF, size_AdlibChannels);
    for(i = 0; i < OPLchannels; i++) {
        AdlibChannelEntry __far* ch = &AdLibChannels[i];
		ch->pitchwheel = DEFAULT_PITCH_BEND;
	}
    //OPLinstruments = NULL;
    return 0;
}
 
 

int8_t OPL2detectHardware(uint16_t port, uint8_t irq, uint8_t dma){
    return OPL2detect(port);
}

int8_t OPL3detectHardware(uint16_t port, uint8_t irq, uint8_t dma){
    return OPL3detect(port);
}

int8_t OPL2initHardware(uint16_t port, uint8_t irq, uint8_t dma){
    OPLinit(port, 0);
    return 0;
}

int8_t OPL3initHardware(uint16_t port, uint8_t irq, uint8_t dma){
    OPLinit(port, 1);
    return 0;
}

int8_t OPL2deinitHardware(void){
    OPLdeinit();
    return 0;
}

int8_t OPL3deinitHardware(void){
    OPLdeinit();
    return 0;
}

int8_t OPLsendMIDI(uint8_t command, uint8_t par1, uint8_t par2){
    return 0;
}

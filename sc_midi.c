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


/* send a MIDI event to driver */
#define SENDMIDI(chn, cmd, par1, par2)	\
	(playingdriver->sendMIDI((chn) | (cmd), (par1), (par2)))

/* touch MIDI channel timestamp */
#define TOUCH(channel)	MIDItime[channel] = playingtime

#define MIDI_PERC	9	/* standard MIDI percussion channel */

\
/* calculate MIDI channel volume */
int8_t calcVolume(uint16_t MUSvolume, uint8_t noteVolume){
    fixed_t_union result;
    result.wu = FastMul16u16u (MUSvolume, (uint16_t)noteVolume);
    
    // instead of shift 8 use fracbyte high
    result.bu.fracbytelow = result.bu.fracbytehigh;
    result.bu.fracbytehigh = result.bu.intbytelow;
    if (result.hu.fracbits > 127){
	    return 127;
    } else {
	    return result.bu.fracbytelow;
    }
}
/*
int8_t calcVolume(uint16_t channelVolume, uint16_t MUSvolume, int8_t noteVolume){
    noteVolume = (((uint32_t)channelVolume * MUSvolume * noteVolume) / (256*127)) & 0x7F;
	return noteVolume;
}*/


void stopChannel(uint8_t MIDIchannel){
    SENDMIDI(MIDIchannel, MIDI_CONTROL, 120, 127); /* all sounds off */
    SENDMIDI(MIDIchannel, MIDI_CONTROL, 121, 127); /* reset all controllers */
}

// find free MIDI output channel
int8_t findFreeMIDIChannel(uint8_t channel){
    uint8_t i, oldest;
    uint32_t time;

    if (playingpercussMask & (1 << channel)){
	    return MIDI_PERC;
    }

    // find unused MIDI channel
    for (i = 0; i < MAX_MUSIC_CHANNELS; i++){
        if (MIDIchannels[i] == 0xFF) {
            MIDIchannels[i] = channel;
            return i;
        }
    }

    // find LRU
    time = playingtime;
    oldest = 0xFF;

    for (i = 0; i < MAX_MUSIC_CHANNELS; i++){
        if (i != MIDI_PERC && MIDItime[i] < time) {
            time = MIDItime[i];
            oldest = i;
        }
    }

    if ( (i = oldest) != 0xFF) {
        mididriverData->realChannels[MIDIchannels[i]] = 0xFF;
        stopChannel(i);
        MIDIchannels[i] = channel;

    }

    return i;
}



// send all tracked controller values to the MIDI output
void updateControllers(uint8_t channel){
    uint8_t i, value;
    int8_t MIDIchannel;

    if ( (MIDIchannel = mididriverData->realChannels[channel]) >= 0) {
        SENDMIDI(MIDIchannel, MIDI_PATCH, mididriverData->controllers[ctrlPatch][channel], 0);
        for (i = ctrlPatch + 1; i < NUM_CONTROLLERS; i++) {
            value = mididriverData->controllers[i][channel];
            if (i == ctrlVolume){
                if (MIDIchannel == MIDI_PERC){
                    continue;
                } else {
                    value = calcVolume(playingvolume, value);
                }
            }
            SENDMIDI(MIDIchannel, MIDI_CONTROL, MUS2MIDIctrl[i], value);
        }
        
        {
            uint8_t pitch = mididriverData->pitchWheel[channel];
            uint8_t pitch_high = pitch >> 1 & 0x7F;
            uint8_t pitch_low = (pitch & 1) ? 0x80 : 0; // todo 64?
            SENDMIDI(MIDIchannel, MIDI_PITCH_WHEEL, pitch_low, pitch_high);

            //SENDMIDI(MIDIchannel, MIDI_PITCH_WHEEL, (value & 1) << 6, (value >> 1) & 0x7F);
        }
    }
}

// send system volume
void sendSystemVolume(int16_t systemVolume){
    int8_t i;

    for(i = 0; i < MAX_MUSIC_CHANNELS; i++) {
        int8_t MIDIchannel;
        if ( (MIDIchannel = mididriverData->realChannels[i]) >= 0){
            if (MIDIchannel != MIDI_PERC){
                SENDMIDI(MIDIchannel, MIDI_CONTROL, MUS2MIDIctrl[ctrlVolume],
                    calcVolume(systemVolume, mididriverData->controllers[ctrlVolume][i]));
            }
        }
    }
}


// code 1: play note
void MIDIplayNote(uint8_t channel, uint8_t note, int8_t volume){
    int8_t MIDIchannel;

    if (volume == -1){
	    volume = mididriverData->channelLastVolume[channel];
    } else{
	    mididriverData->channelLastVolume[channel] = volume;
    }

    if ( (MIDIchannel = mididriverData->realChannels[channel]) < 0) {
        if ( (MIDIchannel = findFreeMIDIChannel(channel)) < 0){
            return;
        }
        mididriverData->realChannels[channel] = MIDIchannel;
        updateControllers(channel);
    }

    if (MIDIchannel == MIDI_PERC) {
        int16_t_union intermediate;
        //intermediate.hu = FastMul8u8u(playingvolume, );
        mididriverData->percussions[note >> 3] |= (1 << (note & 7));
        intermediate.hu = FastMul8u8u(calcVolume(playingvolume, mididriverData->controllers[ctrlVolume][channel]), volume);

        intermediate = FastDiv16u_8u(intermediate.hu, 127);
        volume = intermediate.bu.bytelow;
    }

    TOUCH(MIDIchannel);
    SENDMIDI(MIDIchannel, MIDI_NOTE_ON, note, volume);
}

// code 0: release note
void MIDIreleaseNote(uint8_t channel, uint8_t note){
    int8_t MIDIchannel;

    if ( (MIDIchannel = mididriverData->realChannels[channel]) >= 0) {
        if (MIDIchannel == MIDI_PERC){
            mididriverData->percussions[note >> 3] &= ~(1 << (note & 7));
        }

        TOUCH(MIDIchannel);
        SENDMIDI(MIDIchannel, MIDI_NOTE_OFF, note, 127);
    }
}

// code 2: change pitch wheel (bender)
void MIDIpitchWheel(uint8_t channel, uint8_t pitch){
    int8_t MIDIchannel;

    mididriverData->pitchWheel[channel] = pitch;

    if ( (MIDIchannel = mididriverData->realChannels[channel]) >= 0) {
        uint8_t pitch_high = pitch >> 1 & 0x7F;
        uint8_t pitch_low = (pitch & 1) ? 0x80 : 0; // todo 64?
        TOUCH(MIDIchannel);

        SENDMIDI(MIDIchannel, MIDI_PITCH_WHEEL, pitch_low, pitch_high);
    }
}

// code 4: change control
void MIDIchangeControl(uint8_t channel, uint8_t controller, uint8_t value){
    int8_t MIDIchannel;

    if (controller < NUM_CONTROLLERS){
	    mididriverData->controllers[controller][channel] = value;
    }

    if ( (MIDIchannel = mididriverData->realChannels[channel]) < 0){
	    return;
    }

    TOUCH(MIDIchannel);

    if (!controller){			/* 0 - instrument */
	    SENDMIDI(MIDIchannel, MIDI_PATCH, value, 0);
    } else if (controller <= 14) {
        switch (controller) {
            case ctrlVolume:		/* change volume */
                if (MIDIchannel == MIDI_PERC){
                    return;
                }
                value = calcVolume(playingvolume, value);
                break;
            case ctrlResetCtrls:	/* Reset All Controllers */
                /* Perhaps, some controllers should be added or removed,
                I don't know the exact implementation of this command */
                mididriverData->controllers[ctrlBank	  ][channel] = 0;
                mididriverData->controllers[ctrlModulation  ][channel] = 0;
                mididriverData->controllers[ctrlPan	  ][channel] = 64;
                mididriverData->controllers[ctrlExpression  ][channel] = 127;
                mididriverData->controllers[ctrlSustainPedal][channel] = 0;
                mididriverData->controllers[ctrlSoftPedal	  ][channel] = 0;
                mididriverData->pitchWheel		   [channel] = DEFAULT_PITCH_BEND;
                break;
        }
        SENDMIDI(MIDIchannel, MIDI_CONTROL, MUS2MIDIctrl[controller], value);
    }
}

void MIDIplayMusic(){
    int8_t i;

    FAR_memset(mididriverData, 0, size_mididriverData);
    for (i = 0; i < MAX_MUSIC_CHANNELS; i++) {
        mididriverData->controllers[ctrlPatch	  ][i] = 0;
        mididriverData->controllers[ctrlBank	  ][i] = 0;
        mididriverData->controllers[ctrlModulation  ][i] = 0;
        mididriverData->controllers[ctrlVolume	  ][i] = 127;
        mididriverData->controllers[ctrlPan	  ][i] = 64;
        mididriverData->controllers[ctrlExpression  ][i] = 127;
        mididriverData->controllers[ctrlReverb	  ][i] = 0;
        mididriverData->controllers[ctrlChorus	  ][i] = 0;
        mididriverData->controllers[ctrlSustainPedal][i] = 0;
        mididriverData->controllers[ctrlSoftPedal	  ][i] = 0;
        mididriverData->channelLastVolume            [i] = 0; /* last volume--anything */
        mididriverData->pitchWheel		   [i] = DEFAULT_PITCH_BEND;
        mididriverData->realChannels		   [i] = -1; /* no assignment */
    }
    
    SENDMIDI(MIDI_PERC, MIDI_CONTROL, MUS2MIDIctrl[ctrlVolume], 127);
    SENDMIDI(MIDI_PERC, MIDI_CONTROL, MUS2MIDIctrl[ctrlResetCtrls], 0);
}

void MIDIstopMusic(){
    int8_t i;

    for (i = 0; i < MAX_MUSIC_CHANNELS; i++) {
        int8_t MIDIchannel = mididriverData->realChannels[i];
        if (MIDIchannel < 0){
            continue;
        }
        
        if (MIDIchannel != MIDI_PERC){
            stopChannel(MIDIchannel);
        } else {
            uint8_t j;
            for(j = 0; j < 128; j++){
                if (mididriverData->percussions[j >> 3] & (1 << (j & 7))){
                    SENDMIDI(MIDI_PERC, MIDI_NOTE_OFF, j, 127);
                }
            }
        }
        
    }
}

void MIDIchangeSystemVolume(int16_t systemVolume){
    if (playingstate == ST_PLAYING){
	    sendSystemVolume(systemVolume);
    }
} 

int8_t MIDIinitDriver(void){
    FAR_memset(MIDIchannels, 0xFF, size_MIDIchannels);
    MIDIchannels[MIDI_PERC] = ~(0xFF >> 1); /* mark perc. channel as always occupied */
    FAR_memset(MIDItime, 0, size_MIDItime);
    return 0;
} 

//
// Copyright (C) 1993-1996 Id Software, Inc.
// Copyright (C) 1993-2008 Raven Software
// Copyright (C) 2016-2017 Alexey Khokholov (Nuke.YKT)
//
// This program is free software; you can redistribute it and/or
// modify it under the terms of the GNU General Public License
// as published by the Free Software Foundation; either version 2
// of the License, or (at your option) any later version.
//
// This program is distributed in the hope that it will be useful,
// but WITHOUT ANY WARRANTY; without even the implied warranty of
// MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
// GNU General Public License for more details.
//
// DESCRIPTION:
//  System interface for sound.
//

#include <stdio.h>
#include <dos.h>

#include "dmx.h"

#include "i_system.h"
#include "s_sound.h"
#include "i_sound.h"
#include "sounds.h"
#include "m_misc.h"
#include "w_wad.h"
#include "z_zone.h"

#include "doomdef.h"
#include "doomstat.h"
#include "m_near.h"
#include "sc_music.h"
 

int16_t SFX_PlayPatch(void __far*vdata, int16_t pitch, int16_t sep, int16_t vol, int16_t unk1, int16_t unk2){
    return 0;
}
void SFX_StopPatch(int16_t handle){

}
int16_t SFX_Playing(int16_t handle){
    return 0;
}
void SFX_SetOrigin(int16_t handle, int16_t  pitch, int16_t sep, int16_t vol){
    
}


//
// I_StartupTimer
//


void I_StartupTimer(void) {

	void I_TimerISR(void);

	DEBUG_PRINT("I_StartupTimer()\n");
	// installs master timer.  Must be done before StartupTimer()!
	TS_ScheduleMainTask();
	TS_Dispatch();
}

void I_PauseSong() {
    playingstate = ST_PAUSED;
    if (playingdriver){
        playingdriver->pauseMusic();
    }
}

void I_ResumeSong() {
    playingstate = ST_PLAYING;
    if (playingdriver){
        playingdriver->resumeMusic();
    }
}

void I_SetSfxVolume(uint8_t volume) {
    snd_SfxVolume = volume;
}

//
// Song API
//

//todo
#define MUSIC_SEGMENT EMS_PAGE

int16_t I_LoadSong(uint16_t lump) {
    // always use MUSIC SEGMENT, 0
	//todo use scratch instead?
    byte __far * data = MK_FP(MUSIC_SEGMENT, 0);
    int16_t __far *  worddata = (int16_t __far *)data;
    W_CacheLumpNumDirect(lump, data);

    //I_Error("made it %i %x %x", lump, worddata[0], worddata[1]);


    // MUS_Parseheader inlined
    if (worddata[0] == 0x554D && worddata[1] == 0x1A53 ){     // MUS file header
        currentsong_length              = worddata[2];  // how do larger that 64k files work?
        currentsong_start_offset        = worddata[3];  // varies
        currentsong_primary_channels    = worddata[4];  // max at  0x07?
        currentsong_secondary_channels  = worddata[5];  // always 0??
        currentsong_num_instruments     = worddata[6];  // varies..  but 0-127
        // reserved   

		currentsong_playing_offset = currentsong_start_offset;
		currentsong_play_timer = 0;
		currentsong_ticks_to_process = 0;
		
        // todo cleaner, check for opl3 too, etc
        if (playingdriver && ((playingdriver->driverId == MUS_DRIVER_TYPE_OPL2) ||
            (playingdriver->driverId == MUS_DRIVER_TYPE_OPL3)) ){

	        int8_t  i;
            uint8_t j;
            // parse instruements
            FAR_memset(instrumentlookup, 0xFF, MAX_INSTRUMENTS);
            for (i = 0; i < currentsong_num_instruments; i++){
                uint16_t instrument = worddata[8+i];
                if (instrument > 127){
                    instrument -= 7;
                }
                instrumentlookup[instrument] = i;	// this instrument is index i in AdLibInstrumentList
            }



            // dynamically load used instruments
            W_CacheLumpNameDirect("genmidi", data); // load instrument data.
            for (j = j; j < MAX_INSTRUMENTS; j++){
                uint8_t instrumentindex = instrumentlookup[j];
                if (instrumentindex != 0xFF){
                    // 8 for the string at the start of the lump...
                    uint16_t offset = 8 +(sizeof(OP2instrEntry) * j);

                    //far_fread(&AdLibInstrumentList[instrumentindex], sizeof(OP2instrEntry), 1, fp);
                    FAR_memcpy(&AdLibInstrumentList[instrumentindex], MK_FP(MUSIC_SEGMENT, offset), sizeof(OP2instrEntry));
                }
            }
            // reload mus
            W_CacheLumpNumDirect(lump, data);

        }

        

		return 1; 
    } else {
		//printerror("Bad header %x %x", worddata[0], worddata[1]);
		return - 1;
	}




	
}



void I_StopSong() {
    playingstate = ST_STOPPED;
    // todo signal driver pause?
    if (playingdriver){
        playingdriver->stopMusic();
    }
}

void I_PlaySong(boolean looping) {
    playingstate = ST_PLAYING;
    loops_enabled = true;
    if (playingdriver){
        playingdriver->stopMusic();
    }

}

//
// Retrieve the raw data lump index
//  for a given SFX name.
//
int16_t I_GetSfxLumpNum(sfxinfo_t* sfx) {
	int8_t namebuf[9];
    int8_t part1[3];
    if (sfx->link) {
        sfx = sfx->link;
    }
    part1[0] = 'd';
    part1[1] = snd_prefixen[snd_SfxDevice];
    part1[2] = '\0';

    combine_strings(namebuf, part1, sfx->name);
    return W_GetNumForName(namebuf);
}

int16_t I_StartSound(int16_t id, void  __far*data, uint8_t vol, uint8_t sep, uint8_t pitch, uint8_t priority) {
    // hacks out certain PC sounds
    if (snd_SfxDevice == snd_PC
    && (data == S_sfx[sfx_posact].data
     || data == S_sfx[sfx_bgact].data
     || data == S_sfx[sfx_dmact].data
     || data == S_sfx[sfx_dmpain].data
     || data == S_sfx[sfx_popain].data
     || data == S_sfx[sfx_sawidl].data))
    {
        return -1;
    }
    return SFX_PlayPatch(data, sep, pitch, vol, 0, 100);
}

void I_StopSound(int16_t handle) {
    SFX_StopPatch(handle);
}

boolean I_SoundIsPlaying(int16_t handle) {
    return SFX_Playing(handle);
}

void I_UpdateSoundParams(int16_t handle, uint8_t vol, uint8_t sep, uint8_t pitch) {
    SFX_SetOrigin(handle, pitch, sep, vol);
}

//
// Sound startup stuff
//

int16_t __far M_CheckParm (int8_t *check);

void I_sndArbitrateCards(void) {

/*

     // todo when we redo this, checkparm is __near to init code so do that there


    boolean gus, adlib, sb, midi, codec, ensoniq;
    int16_t i, wait, dmxlump;

 
    snd_SfxVolume = 127;
    snd_SfxDevice = snd_DesiredSfxDevice;
    snd_MusicDevice = snd_DesiredMusicDevice;

    //
    // check command-line parameters- overrides config file
    //


    if (snd_MusicDevice > snd_MPU && snd_MusicDevice <= snd_MPU3) {
        snd_MusicDevice = snd_MPU;
    }
    if (snd_MusicDevice == snd_SB) {
        snd_MusicDevice = snd_Adlib;
    }
    if (snd_MusicDevice == snd_PAS) {
        snd_MusicDevice = snd_Adlib;
    }

    //
    // figure out what i've got to initialize
    //
    gus = snd_MusicDevice == snd_GUS || snd_SfxDevice == snd_GUS;
    sb = snd_SfxDevice == snd_SB || snd_MusicDevice == snd_SB;
    ensoniq = snd_SfxDevice == snd_ENSONIQ;
    codec = snd_SfxDevice == snd_CODEC;
    adlib = snd_MusicDevice == snd_Adlib;
    midi = snd_MusicDevice == snd_MPU;

    //
    // initialize whatever i've got
    //
    if (ensoniq) {
        if (ENS_Detect()) {
            #ifdef SNDDEBUG
                DEBUG_PRINT("Dude.  The ENSONIQ ain't responding.\n");
            #endif
        }
    }
    if (codec) {
        if (CODEC_Detect(&snd_SBport, &snd_SBdma)) {
            #ifdef SNDDEBUG
                DEBUG_PRINT("CODEC.  The CODEC ain't responding.\n");
            #endif
        }
    }
    if (gus) {

        if (GF1_Detect()) {
            #ifdef SNDDEBUG
                DEBUG_PRINT("Dude.  The GUS ain't responding.\n");
            #endif
        } else {
            byte __far * location = MK_FP(0x5000, 0);
            if (commercial) {
                dmxlump = W_GetNumForName("dmxgusc");
            }
            else {
                dmxlump = W_GetNumForName("dmxgus");
            }
            W_CacheLumpNumDirect(dmxlump, location);
			
            GF1_SetMap(location, lumpinfo9000[dmxlump+1].position - lumpinfo9000[dmxlump].position + lumpinfo9000[dmxlump].sizediff);
        }

    }
    if (sb) {

        if (SB_Detect(&snd_SBport, &snd_SBirq, &snd_SBdma, 0)) {
                #ifdef SNDDEBUG
                    DEBUG_PRINT("SB isn't responding at p=0x%x, i=%d, d=%d\n", snd_SBport, snd_SBirq, snd_SBdma);
                #endif
        } else {
            SB_SetCard(snd_SBport, snd_SBirq, snd_SBdma);
        }

    }

    if (adlib) {

	    if (AL_Detect(&wait, 0)) {
            #ifdef SNDDEBUG
                DEBUG_PRINT("Dude.  The Adlib isn't responding.\n");
            #endif
        } else {
            //todo move this into AL_SetCard
            byte __far * location = MK_FP(0x5000, 0);
            Z_QuickMapScratch_5000();
            W_CacheLumpNameDirect("genmidi", location);
            AL_SetCard(wait, location);
            Z_QuickMapPhysics();
        }
    }

    if (midi) {


        if (MPU_Detect(&snd_Mport, &i)) {
            #ifdef SNDDEBUG
                DEBUG_PRINT("The MPU-401 isn't reponding @ p=0x%x.\n", snd_Mport);
            #endif
        } else {
            MPU_SetCard(snd_Mport);
        }
    }
    */
}



void MUS_ServiceRoutine(){

    if (playingstate != ST_PLAYING){
        return;
    }

	if (playingdriver == NULL){
        return;
    }

	currentsong_ticks_to_process ++;
	
	while (currentsong_ticks_to_process >= 0){

		// ok lets actually process events....
		int16_t increment 			= 1; // 1 for the event
		byte doing_loop 			= false;
		byte __far* currentlocation = MK_FP(MUSIC_SEGMENT, currentsong_playing_offset);
		uint8_t eventbyte 			= currentlocation[0];
		uint8_t event     			= (eventbyte & 0x70) >> 4;
		int8_t  channel   			= (eventbyte & 0x0F);
		byte lastflag  				= (eventbyte & 0x80);
		int16_t_union delay_amt		= {0};


		switch (event){
			case 0:
				// Release Note
				{
					byte value 	      = currentlocation[1];
					byte key		  = value & 0x7F;
					playingdriver->releaseNote(channel, value);

				}
				increment++;
				break;
			case 1:
				// Play Note
				{
					uint8_t value 	= currentlocation[1];
					byte volume = -1;  		// -1 means repeat..
					uint8_t key		  = value & 0x7F;
					if (value & 0x80){
						volume = currentlocation[2] & 0x7F;
						increment++;
					}
					playingdriver->playNote(channel, key, volume);
					increment++;
				}

				break;
			case 2:
				// Pitch Bend
				{
					byte value 			  = currentlocation[1];
					increment++;
					playingdriver->pitchWheel(channel, value);

				}
				break;
			case 3:
				// System Event
				{
					byte controllernumber = currentlocation[1] & 0x7F;
					playingdriver->changeControl(channel, controllernumber, 0);
					increment++;
				}

				break;
				
			case 4:
				// Controller
				{
					uint8_t controllernumber  = currentlocation[1] & 0x7F; // values above 127 used for instrument change & 0x7F;
					uint8_t value 			  = currentlocation[2] & 0x7F; // values above 127 used for instrument change & 0x7F; ?

					playingdriver->changeControl(channel, controllernumber, value);
					increment++;
					increment++;
				}
				break;
			case 5:
				// End of Measure
				// do nothing..
				//printf("End of Measure\n");

				break;
			case 6:
				// Finish

                if (loops_enabled){
                    doing_loop = true;
                } else {
                    playingstate = ST_STOPPED;
				}
				break;
			case 7:
				// Unused
				increment++;   // advance for one data byte
				break;
		}

		currentsong_playing_offset += increment;

		while (lastflag){
			// i dont think delays > 32768 are valid..
			currentlocation = MK_FP(MUSIC_SEGMENT, currentsong_playing_offset);
			delay_amt.hu <<= 7;
			//delay_amt.bu.bytehigh >>= 1;	// shift 128.
			lastflag = currentlocation[0] ;
			delay_amt.bu.bytelow += (lastflag & 0x7F);

			lastflag &= 0x80;
			currentsong_playing_offset++;
		}
		//printf("%li %li %hhx\n", currentsong_ticks_to_process, currentsong_ticks_to_process - delay_amt, eventbyte);
		currentsong_ticks_to_process -= delay_amt.hu;

		//todo how to handle loop/end song plus last flag?
		if (doing_loop){
			// todo do we have to reset or something?
			currentsong_playing_offset = currentsong_start_offset;
		}
		if (playingstate == ST_STOPPED){
			break;
		}


	}
	playingtime++;


}

/*

byte __far * theptr = MK_FP(0xc800, 0);

void __far finishlogging(){
    FILE* fp = fopen("outp.txt", "wb");
    byte __far * baseptr = MK_FP(0xc800, 0);
    int32_t amount = (int32_t)baseptr - (int32_t)theptr;
    FAR_fwrite(baseptr, amount, 1, fp);
    fclose(fp);
}


void __far printerfunc(uint16_t reg, uint8_t data){

    // uint8_t chars[8];
    // chars[0] = ((ptr & 0xF0000000) >> 28) ;
    // chars[1] = ((ptr & 0x0F000000) >> 24) ;
    // chars[2] = ((ptr & 0x00F00000) >> 20) ;
    // chars[3] = ((ptr & 0x000F0000) >> 16) ;
    // chars[4] = ((ptr & 0x0000F000) >> 12) ;
    // chars[5] = ((ptr & 0x00000F00) >> 8) ;
    // chars[6] = ((ptr & 0x000000F0) >> 4) ;
    // chars[7] = ((ptr & 0x0000000F) ) ;

    uint8_t chars[6];
    uint8_t i;
    
    chars[0] = ((reg & 0xF000) >> 12) ;
    chars[1] = ((reg & 0x0F00) >> 8) ;
    chars[2] = ((reg & 0x00F0) >> 4) ;
    chars[3] = ((reg & 0x000F) >> 0) ;

    chars[4] = ((data & 0xF0) >> 4) ;
    chars[5] = ((data & 0x0F) ) ;

    for (i = 0; i < 6; i++){
        if (chars[i] >= 10){
            chars[i] = chars[i] + 'A' - 10;
        } else {
            chars[i] = chars[i] + '0';
        }
        *theptr = chars[i];
        theptr++;

        if (i == 3){
            *theptr = ' ';
            theptr++;
        }
    }

    *theptr = '\n';
    theptr++;
}

*/
//
// I_StartupSound
// Inits all sound stuff
//
void __far I_StartupSound(void) {
    int16_t rc;
    int16_t useport = 0;
    int16_t irq = 0;
    int16_t dma = 0;
    //
    // initialize dmxCodes[]
    //
    

    //
    // inits sound library timer stuff
    //
    I_StartupTimer();
    //
    // pick the sound cards i'm going to use
    //
    //I_sndArbitrateCards();
    
    
    //I_Error ("%i %i\n", snd_MusicDevice, snd_DesiredMusicDevice);
    // todo actually detect hw eventually. for now just set music device to desired music device.

    snd_MusicDevice = snd_DesiredMusicDevice;

    switch (snd_MusicDevice){
        case snd_Adlib:
            playingdriver = &OPL2driver;
            useport = ADLIBPORT;

            break;
        case snd_MPU:   // wave blaster
            playingdriver = &SBMIDIdriver;
            if (snd_Mport){
                useport = snd_SBport;
            } else {
                useport = SBMIDIPORT;
            }
            break;
        case snd_MPU2:  // sound canvas
        case snd_MPU3:  // general midi
            playingdriver = &MPU401driver;
            if (snd_Mport){
                useport = snd_Mport;
            } else {
                useport = MPU401PORT;
            }
            break;
        
        case snd_SB:
            playingdriver = &OPL3driver;
            useport = ADLIBPORT;
            break;

        
    }

    //I_Error("fields %i %x %x %x", snd_MusicDevice, useport, snd_Mport, snd_SBport);
    if (playingdriver){
        playingdriver->initHardware(useport, 0, 0);
        playingdriver->initDriver();
    }





}

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
  



//
// I_StartupTimer
//


void I_StartupTimer(void) {
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

// void I_SetSfxVolume(uint8_t volume) {
//     snd_SfxVolume = volume;
// }

//
// Song API
//

//todo
/*
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
            OP2instrEntry __far* adlibinstrumentlist = (OP2instrEntry __far*)&(playingdriver->driverdata);
            uint8_t __far* instrumentlookup          = ((uint8_t __far*)     &(playingdriver->driverdata)) + size_AdLibInstrumentList;
            
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
                    FAR_memcpy(&adlibinstrumentlist[instrumentindex], MK_FP(MUSIC_SEGMENT, offset), sizeof(OP2instrEntry));
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
*/


//
// Retrieve the raw data lump index
//  for a given SFX name.
//
// int16_t I_GetSfxLumpNum(sfxenum_t sfx_id) {
// 	int8_t namebuf[9];
//     int8_t part1[3];
//     if (sfx_id == sfx_chgun) {
//         sfx_id = sfx_pistol; 
//     }
//     part1[0] = 'd';
//     part1[1] = snd_prefixen[snd_SfxDevice];
//     part1[2] = '\0';

//     combine_strings(namebuf, part1, S_sfx[sfx_id].name);
//     return W_GetNumForName(namebuf);
// }



int8_t I_StartSound(sfxenum_t sfx_id,  uint8_t vol, uint8_t sep) {
    // hacks out certain PC sounds
    // if (snd_SfxDevice == snd_PC
    //     && (data == S_sfx[sfx_posact].data
    //     || data == S_sfx[sfx_bgact].data
    //     || data == S_sfx[sfx_dmact].data
    //     || data == S_sfx[sfx_dmpain].data
    //     || data == S_sfx[sfx_popain].data
    //     || data == S_sfx[sfx_sawidl].data)) {
    //     return -1;
    // }

    if (snd_SfxDevice == snd_none){
        return -1;
    }

    if (snd_SfxDevice == snd_PC
        && ((sfx_id == sfx_posact)
        || (sfx_id == sfx_bgact )
        || (sfx_id == sfx_dmact )
        || (sfx_id == sfx_dmpain)
        || (sfx_id == sfx_popain)
        || (sfx_id == sfx_sawidl) )) {
            return -1;
    }

    if (snd_SfxDevice == snd_PC){
        // todo how to resolve this? lump to id map?
        //I_Error("start sound %i", sfx_id);
        //uint16_t *__far pc_speaker_offsets = (uint16_t *__far)(MK_FP(PC_SPEAKER_OFFSETS_SEGMENT, 0));
        pcspeaker_currentoffset = pc_speaker_offsets[sfx_id-1];
        pcspeaker_endoffset = pc_speaker_offsets[sfx_id];
        return 0;
    } else {
        return SFX_PlayPatch(sfx_id, sep, vol);
    }


    
}

void I_StopSound(int8_t handle) {
    
    if (snd_SfxDevice == snd_SB) {
        SFX_StopPatch(handle);
    } else if (snd_SfxDevice == snd_PC){
        pcspeaker_currentoffset = 0;
    } 
    
    
}


boolean I_SoundIsPlaying(int8_t handle) {
    return SFX_Playing(handle);
}

void I_UpdateSoundParams(int8_t handle, uint8_t vol, uint8_t sep) {
    SFX_SetOrigin(handle, sep, vol);
}

//
// Sound startup stuff
//

int16_t __far M_CheckParm (int8_t *check);

/*

void I_sndArbitrateCards(void) {

    snd_SfxVolume = SFX_MAX_VOLUME;



     // todo when we redo this, checkparm is __near to init code so do that there


    boolean gus, adlib, sb, midi, codec, ensoniq;
    int16_t i, wait, dmxlump;

 
    snd_SfxVolume = SFX_MAX_VOLUME;
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
}

    */

/*

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
*/


//
// I_StartupSound
// Inits all sound stuff
//


void __far I_StartupSound(void) {
    int16_t useport = 0;
    int16_t irq = 0;
    int16_t dma = 0;
    int8_t j = 0;
    int16_t driverindex = 0;
    //
    // initialize dmxCodes[]
    //
    

    //
    // inits sound library timer stuff
    //
    //
    // pick the sound cards i'm going to use
    //
    snd_SfxDevice = snd_DesiredSfxDevice;

    
    //I_Error ("%i %i\n", snd_MusicDevice, snd_DesiredMusicDevice);
    // todo actually detect hw eventually. for now just set music device to desired music device.


    snd_MusicDevice = snd_DesiredMusicDevice;



    // I_Error("%lx %lx", playingdriver->initHardware, playingdriver);

    switch (snd_MusicDevice){
        case snd_Adlib:
            driverindex = MUS_DRIVER_TYPE_OPL2;
            useport = ADLIBPORT;
            break;
        case snd_MPU:   // wave blaster
            driverindex = MUS_DRIVER_TYPE_SBMIDI;
            if (snd_Mport){
                useport = snd_SBport;
            } else {
                useport = SBMIDIPORT;
            }
            break;
        case snd_MPU2:  // sound canvas
        case snd_MPU3:  // general midi
            driverindex = MUS_DRIVER_TYPE_MPU401;

            if (snd_Mport){
                useport = snd_Mport;
            } else {
                useport = MPU401PORT;
            }
            break;
        
        case snd_SB:
            driverindex = MUS_DRIVER_TYPE_OPL3;
            useport = ADLIBPORT;
            break;
        
    }

    if (driverindex){
        uint16_t codesize;
        // todo put in main conventional somewhere
        FILE* fp = fopen("DOOMCODE.BIN", "rb"); 
        playingdriver = MK_FP(0xDC00, 0000);
        fseek(fp, musdriverstartposition[driverindex-1], SEEK_SET);
        fread(&codesize, 2, 1, fp);
        FAR_fread(playingdriver, codesize, 1, fp);
        fclose(fp);
        

        // loader to set far segment for these func calls at runtime.   
        {
            int8_t i;
            segment_t __far* ptr = (segment_t __far *) playingdriver;
            segment_t seg = ((int32_t)playingdriver) >> 16;
            for (i = 0; i < 13; i++){
                ptr[2*i+1] = seg;
            }


        // I_Error("%lx %lx %lx %x",
        // codelocation, 
        // ((driverBlock __far * ) codelocation)->initHardware,
        // ((driverBlock __far * ) codelocation)->initDriver,
        //  musdriverstartposition[driverindex-1]
        // );


            playingdriver->initHardware(useport, 0, 0);
            playingdriver->initDriver();

        }
    }



    I_StartupTimer();

}

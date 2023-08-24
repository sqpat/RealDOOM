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

//
// I_StartupTimer
//


void I_StartupTimer(void)
{

	extern void I_TimerISR(void);

	printf("I_StartupTimer()\n");
	// installs master timer.  Must be done before StartupTimer()!
	TS_ScheduleTask(I_TimerISR, 35);
	TS_Dispatch();
}

void I_ShutdownTimer(void)
{
	TS_Terminate();
	TS_Shutdown();
}

//
// Sound header & data
//
const int8_t snd_prefixen[]
= { 'P', 'P', 'A', 'S', 'S', 'S', 'M', 'M', 'M', 'S', 'S', 'S' };

int32_t dmxCodes[NUM_SCARDS]; // the dmx code for a given card

int32_t snd_SBport, snd_SBirq, snd_SBdma; // sound blaster variables
int32_t snd_Mport; // midi variables

int32_t snd_MusicVolume; // maximum volume for music
int32_t snd_SfxVolume; // maximum volume for sound

int32_t snd_SfxDevice; // current sfx card # (index to dmxCodes)
int32_t snd_MusicDevice; // current music card # (index to dmxCodes)
int32_t snd_DesiredSfxDevice;
int32_t snd_DesiredMusicDevice;

void I_PauseSong(int32_t handle)
{
    //MUS_PauseSong(handle);
}

void I_ResumeSong(int32_t handle)
{
    //MUS_ResumeSong(handle);
}

void I_SetMusicVolume(int32_t volume)
{
    //MUS_SetMasterVolume(volume);
    snd_MusicVolume = volume;
}

void I_SetSfxVolume(int32_t volume)
{
    snd_SfxVolume = volume;
}

//
// Song API
//

int32_t I_RegisterSong(void *data)
{
	/*
    int32_t rc = MUS_RegisterSong(data);
#ifdef SNDDEBUG
    if (rc<0) printf("MUS_Reg() returned %d\n", rc);
#endif
    return rc;
	*/
	return 1;
}

void I_UnRegisterSong(int32_t handle)
{
	/*
    int32_t rc = MUS_UnregisterSong(handle);
#ifdef SNDDEBUG
    if (rc < 0) printf("MUS_Unreg() returned %d\n", rc);
#endif
*/
}

int32_t I_QrySongPlaying(int32_t handle)
{
	/*
    int32_t rc = MUS_QrySongPlaying(handle);
#ifdef SNDDEBUG
    if (rc < 0) printf("MUS_QrySP() returned %d\n", rc);
#endif
    return rc;
	*/
	return 1;
}
//
// Stops a song.  MUST be called before I_UnregisterSong().
//
void I_StopSong(int32_t handle)
{
	/*
    int32_t rc;
    rc = MUS_StopSong(handle);
#ifdef SNDDEBUG
    if (rc < 0) printf("MUS_StopSong() returned %d\n", rc);
#endif
    // Fucking kluge pause
    {
        int32_t s;
        extern volatile int32_t ticcount;
        for (s = ticcount; ticcount - s < 10; );
    }
	*/
}

void I_PlaySong(int32_t handle, boolean looping)
{
	/*
	int32_t rc;
    rc = MUS_ChainSong(handle, looping ? handle : -1);
#ifdef SNDDEBUG
    if (rc < 0) printf("MUS_ChainSong() returned %d\n", rc);
#endif
    rc = MUS_PlaySong(handle, snd_MusicVolume);
#ifdef SNDDEBUG
    if (rc < 0) printf("MUS_PlaySong() returned %d\n", rc);
#endif
*/
}

//
// Retrieve the raw data lump index
//  for a given SFX name.
//
int32_t I_GetSfxLumpNum(sfxinfo_t* sfx)
{
	int8_t namebuf[9];

    if (sfx->link)
    {
        sfx = sfx->link;
    }
    sprintf(namebuf, "d%c%s", snd_prefixen[snd_SfxDevice], sfx->name);
    return W_GetNumForName(namebuf);
}

int32_t I_StartSound(int32_t id, void *data, int32_t vol, int32_t sep, int32_t pitch, int32_t priority)
{
	/*
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
	*/
	return -1;
}

void I_StopSound(int32_t handle)
{
    //SFX_StopPatch(handle);
}

int32_t I_SoundIsPlaying(int32_t handle)
{
    //return SFX_Playing(handle);
	return 0;
}

void I_UpdateSoundParams(int32_t handle, int32_t vol, int32_t sep, int32_t pitch)
{
    //SFX_SetOrigin(handle, pitch, sep, vol);
}

//
// Sound startup stuff
//

void I_sndArbitrateCards(void)
{
	/*
    boolean gus, adlib, sb, midi, codec, ensoniq;
    int32_t i, wait, dmxlump;
	MEMREF gf1memref;

    snd_SfxVolume = 127;
    snd_SfxDevice = snd_DesiredSfxDevice;
    snd_MusicDevice = snd_DesiredMusicDevice;

    //
    // check command-line parameters- overrides config file
    //
    if (M_CheckParm("-nosound"))
    {
        snd_MusicDevice = snd_SfxDevice = snd_none;
    }
    if (M_CheckParm("-nosfx"))
    {
        snd_SfxDevice = snd_none;
    }
    if (M_CheckParm("-nomusic"))
    {
        snd_MusicDevice = snd_none;
    }

    if (snd_MusicDevice > snd_MPU && snd_MusicDevice <= snd_MPU3)
    {
        snd_MusicDevice = snd_MPU;
    }
    if (snd_MusicDevice == snd_SB)
    {
        snd_MusicDevice = snd_Adlib;
    }
    if (snd_MusicDevice == snd_PAS)
    {
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
    if (ensoniq)
    {
        if (ENS_Detect())
        {
            printf("Dude.  The ENSONIQ ain't responding.\n");
        }
    }
    if (codec)
    {
        if (CODEC_Detect(&snd_SBport, &snd_SBdma))
        {
            printf("CODEC.  The CODEC ain't responding.\n");
        }
    }
    if (gus)
    {
        fprintf(stderr, "GUS1\n");
        if (GF1_Detect())
        {
            printf("Dude.  The GUS ain't responding.\n");
        }
        else
        {
            fprintf(stderr, "GUS2\n");
            if (commercial)
            {
                dmxlump = W_GetNumForName("dmxgusc");
            }
            else
            {
                dmxlump = W_GetNumForName("dmxgus");
            }
			gf1memref = W_CacheLumpNumEMS(dmxlump, PU_CACHE);
			
            GF1_SetMap(Z_LoadBytesFromEMS(gf1memref), lumpinfo[dmxlump].size);
        }

    }
    if (sb)
    {

	if (SB_Detect(&snd_SBport, &snd_SBirq, &snd_SBdma, 0))
        {
            printf("SB isn't responding at p=0x%x, i=%d, d=%d\n",
                   snd_SBport, snd_SBirq, snd_SBdma);
        }
        else
        {
            SB_SetCard(snd_SBport, snd_SBirq, snd_SBdma);
        }

		}

    if (adlib)
    {

	if (AL_Detect(&wait, 0))
        {
            printf("Dude.  The Adlib isn't responding.\n");
        }
        else
        {
            AL_SetCard(wait, Z_LoadBytesFromEMS( W_CacheLumpNameEMS("genmidi", PU_STATIC)));
        }
    }

    if (midi)
    {


        if (MPU_Detect(&snd_Mport, &i))
        {
            printf("The MPU-401 isn't reponding @ p=0x%x.\n", snd_Mport);
        }
        else
        {
            MPU_SetCard(snd_Mport);
        }
    }
	*/
}

//
// I_StartupSound
// Inits all sound stuff
//
void I_StartupSound(void)
{
	int32_t rc;

    //
    // initialize dmxCodes[]
    //
    dmxCodes[0] = 0;
    dmxCodes[snd_PC] = AHW_PC_SPEAKER;
    dmxCodes[snd_Adlib] = AHW_ADLIB;
    dmxCodes[snd_SB] = AHW_SOUND_BLASTER;
    dmxCodes[snd_PAS] = AHW_MEDIA_VISION;
    dmxCodes[snd_GUS] = AHW_ULTRA_SOUND;
    dmxCodes[snd_MPU] = AHW_MPU_401;
    dmxCodes[snd_AWE] = AHW_AWE32;
    dmxCodes[snd_ENSONIQ] = AHW_ENSONIQ;
    dmxCodes[snd_CODEC] = AHW_CODEC;
    
    //
    // inits sound library timer stuff
    //
    I_StartupTimer();

    //
    // pick the sound cards i'm going to use
    //
    I_sndArbitrateCards();


    //
    // inits DMX sound library
    //
    printf("  calling DMX_Init\n");

    //rc = DMX_Init(SND_TICRATE, SND_MAXSONGS, dmxCodes[snd_MusicDevice], dmxCodes[snd_SfxDevice]);

}
//
// I_ShutdownSound
// Shuts down all sound stuff
//
void I_ShutdownSound(void)
{
	/*
    int32_t s;
    extern volatile int32_t ticcount;
    S_PauseSound();
    s = ticcount + 30;
    while (s != ticcount);
    DMX_DeInit();
	*/
}

void I_SetChannels(int32_t channels)
{
    //WAV_PlayMode(channels, SND_SAMPLERATE);
}

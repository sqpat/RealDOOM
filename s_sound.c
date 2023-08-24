//
// Copyright (C) 1993-1996 Id Software, Inc.
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
// DESCRIPTION:  none
//



#include <stdio.h>
#include <stdlib.h>

#include "i_system.h"
#include "i_sound.h"
#include "sounds.h"
#include "s_sound.h"

#include "z_zone.h"
#include "m_misc.h"
#include "w_wad.h"

#include "doomdef.h"
#include "p_local.h"

#include "doomstat.h"
#include "dmx.h"
#include "dpmiapi.h"

#define S_MAX_VOLUME		127

// when to clip out sounds
// Does not fit the large outdoor areas.
#define S_CLIPPING_DIST		(1200*0x10000)

// Distance tp origin when sounds should be maxed out.
// This should relate to movement clipping resolution
// (see BLOCKMAP handling).
#define S_CLOSE_DIST		(200*0x10000)


#define S_ATTENUATOR		((S_CLIPPING_DIST-S_CLOSE_DIST)>>FRACBITS)

// Adjustable by menu.
#define NORM_VOLUME    		snd_MaxVolume

#define NORM_PITCH     		128
#define NORM_PRIORITY		64
#define NORM_SEP		128

#define S_PITCH_PERTURB		1
#define S_STEREO_SWING		(96*0x10000)

// percent attenuation from front to back
#define S_IFRACVOL		30

#define NA			0
#define S_NUMCHANNELS		2


// Current music/sfx card - index useless
//  w/o a reference LUT in a sound module.
extern int snd_MusicDevice;
extern int snd_SfxDevice;
// Config file? Same disclaimer as above.
extern int snd_DesiredMusicDevice;
extern int snd_DesiredSfxDevice;



typedef struct
{
    // sound information (if null, channel avail.)
    sfxinfo_t*	sfxinfo;

    // origin of sound
    MEMREF	originRef;

    // handle of the sound being played
    int		handle;
    
} channel_t;


// the set of channels available
static MEMREF	channelsRef;

// These are not used, but should be (menu).
// Maximum volume of a sound effect.
// Internal default is max out of 0-15.
static int snd_SfxVolume;

// Maximum volume of music. Useless so far.
static int snd_MusicVolume;

extern int sfxVolume;
extern int musicVolume;

// whether songs are mus_paused
static boolean		mus_paused;	

// music currently being played
static musicinfo_t*	mus_playing=0;

// following is set
//  by the defaults code in M_misc:
// number of channels available
int			numChannels;	

static int		nextcleanup;

//
// Internals.
//
int
S_getChannel
( MEMREF originRef,
  sfxinfo_t*	sfxinfo );


int
S_AdjustSoundParams
( MEMREF	listenerRef,
  MEMREF	sourceRef,
  int*		vol,
  int*		sep,
  int*		pitch );

void S_StopChannel(int cnum);

void S_SetMusicVolume(int volume)
{
    if (volume < 0 || volume > 127)
    {
        I_Error("Attempt to set music volume at %d",
            volume);
    }

    I_SetMusicVolume(127);
    I_SetMusicVolume(volume);
    snd_MusicVolume = volume;
}


void S_StopMusic(void)
{
    if (mus_playing)
    {
        if (mus_paused)
            I_ResumeSong(mus_playing->handle);

        I_StopSong(mus_playing->handle);
        I_UnRegisterSong(mus_playing->handle);
        Z_ChangeTag(mus_playing->data, PU_CACHE);

        _dpmi_unlockregion(mus_playing->data,
                           lumpinfo[mus_playing->lumpnum].size);

        mus_playing->data = 0;
        mus_playing = 0;
    }
}

void
S_ChangeMusic
( int			musicnum,
  int			looping )
{
    musicinfo_t*	music;
    char		namebuf[9];

    if (snd_MusicDevice == snd_Adlib && musicnum == mus_intro)
    {
        musicnum = mus_introa;
    }

    if ( (musicnum <= mus_None)
	 || (musicnum >= NUMMUSIC) )
    {
	I_Error("Bad music number %d", musicnum);
    }
    else
	music = &S_music[musicnum];

    if (mus_playing == music)
	return;

    // shutdown old music
    S_StopMusic();

    // get lumpnum if neccessary
    if (!music->lumpnum)
    {
	sprintf(namebuf, "d_%s", music->name);
	music->lumpnum = W_GetNumForName(namebuf);
    }

    // load & register it
    music->data = (void *) W_CacheLumpNum(music->lumpnum, PU_MUSIC);
    music->handle = I_RegisterSong(music->data);
    _dpmi_lockregion(music->data, lumpinfo[music->lumpnum].size);

    // play it
    I_PlaySong(music->handle, looping);

    mus_playing = music;
}

//
// Starts some music with the music id found in sounds.h.
//
void S_StartMusic(int m_id)
{
    S_ChangeMusic(m_id, false);
}

void S_StopChannel(int cnum)
{

    int		i;
	channel_t* channels = (channel_t*) Z_LoadBytesFromEMS(channelsRef);

    channel_t*	c = &channels[cnum];

    if (c->sfxinfo)
    {
	// stop the sound playing
	if (I_SoundIsPlaying(c->handle))
	{
#ifdef SAWDEBUG
	    if (c->sfxinfo == &S_sfx[sfx_sawful])
		fprintf(stderr, "stopped\n");
#endif
	    I_StopSound(c->handle);
	}

	// check to see
	//  if other channels are playing the sound
	for (i=0 ; i<numChannels ; i++)
	{
	    if (cnum != i
		&& c->sfxinfo == channels[i].sfxinfo)
	    {
		break;
	    }
	}
	
	// degrade usefulness of sound data
	c->sfxinfo->usefulness--;

	c->sfxinfo = 0;
    }
}

//
// Changes volume, stereo-separation, and pitch variables
//  from the norm of a sound effect to be played.
// If the sound is not audible, returns a 0.
// Otherwise, modifies parameters and returns 1.
//
int
S_AdjustSoundParams
( MEMREF	listenerRef,
  MEMREF	sourceRef,
  int*		vol,
  int*		sep,
  int*		pitch )
{
    fixed_t	approx_dist;
    fixed_t	adx;
    fixed_t	ady;
    angle_t	angle;
	mobj_t* listener = (mobj_t*)Z_LoadBytesFromEMS(listenerRef);
	mobj_t* source = (mobj_t*)Z_LoadBytesFromEMS(sourceRef);

    // calculate the distance to sound origin
    //  and clip it if necessary
    adx = abs(listener->x - source->x);
    ady = abs(listener->y - source->y);

    // From _GG1_ p.428. Appox. eucledian distance fast.
    approx_dist = adx + ady - ((adx < ady ? adx : ady)>>1);
    
    if (gamemap != 8
	&& approx_dist > S_CLIPPING_DIST)
    {
	return 0;
    }
    
    // angle of source to listener
    angle = R_PointToAngle2(listener->x,
			    listener->y,
			    source->x,
			    source->y);

    if (angle > listener->angle)
	angle = angle - listener->angle;
    else
	angle = angle + (0xffffffff - listener->angle);

    angle >>= ANGLETOFINESHIFT;

    // stereo separation
    *sep = 128 - (FixedMul(S_STEREO_SWING,finesine[angle])>>FRACBITS);

    // volume calculation
    if (approx_dist < S_CLOSE_DIST)
    {
	*vol = snd_SfxVolume;
    }
    else if (gamemap == 8)
    {
	if (approx_dist > S_CLIPPING_DIST)
	    approx_dist = S_CLIPPING_DIST;

	*vol = 15+ ((snd_SfxVolume-15)
		    *((S_CLIPPING_DIST - approx_dist)>>FRACBITS))
	    / S_ATTENUATOR;
    }
    else
    {
	// distance effect
	*vol = (snd_SfxVolume
		* ((S_CLIPPING_DIST - approx_dist)>>FRACBITS))
	    / S_ATTENUATOR; 
    }
    
    return (*vol > 0);
}

void S_SetSfxVolume(int volume)
{

    if (volume < 0 || volume > 127)
	I_Error("Attempt to set sfx volume at %d", volume);

    snd_SfxVolume = volume;

}

//
// Stop and resume music, during game PAUSE.
//
void S_PauseSound(void)
{
    if (mus_playing && !mus_paused)
    {
	I_PauseSong(mus_playing->handle);
	mus_paused = true;
    }
}

void S_ResumeSound(void)
{
    if (mus_playing && mus_paused)
    {
	I_ResumeSong(mus_playing->handle);
	mus_paused = false;
    }
}

void S_StopSound(MEMREF originRef)
{

    int cnum;
	channel_t* channels = (channel_t*)Z_LoadBytesFromEMS(channelsRef);

    for (cnum=0 ; cnum<numChannels ; cnum++)
    {
	if (channels[cnum].sfxinfo && channels[cnum].originRef == originRef)
	{
	    S_StopChannel(cnum);
	    break;
	}
    }
}

//
// S_getChannel :
//   If none available, return -1.  Otherwise channel #.
//
int
S_getChannel ( MEMREF originRef, sfxinfo_t*	sfxinfo ) {
    // channel number to use
    int		cnum;
    
    channel_t*	c;
	channel_t* channels = (channel_t*)Z_LoadBytesFromEMS(channelsRef);

    // Find an open channel
    for (cnum=0 ; cnum<numChannels ; cnum++) {
		if (!channels[cnum].sfxinfo) {
			break;
		} else if (originRef &&  channels[cnum].originRef == originRef) {
			S_StopChannel(cnum);
			break;
		}
    }

    // None available
    if (cnum == numChannels) {
	// Look for lower priority
		for (cnum=0 ; cnum<numChannels ; cnum++)
			if (channels[cnum].sfxinfo->priority >= sfxinfo->priority) break;

		if (cnum == numChannels) {
			// FUCK!  No lower priority.  Sorry, Charlie.    
			return -1;
		} else {
			// Otherwise, kick out lower priority.
			S_StopChannel(cnum);
		}
    }

    c = &channels[cnum];

    // channel is decided to be cnum.
    c->sfxinfo = sfxinfo;
    c->originRef = originRef;

    return cnum;
}

void S_StartSoundAtVolume
( MEMREF    origin_pRef,
	fixed_t originX, 
	fixed_t originY,
  int		sfx_id,
  int		volume )
{

  int		rc;
  int		sep;
  int		pitch;
  int		priority;
  sfxinfo_t*	sfx;
  int		cnum;
  channel_t* channels;
  mobj_t*	playerMo;
  
	
	// Debug.
	/*fprintf( stderr,
		   "S_StartSoundAtVolume: playing sound %d (%s)\n",
		   sfx_id, S_sfx[sfx_id].name );*/
  
	// check for bogus sound #
	if (sfx_id < 1 || sfx_id > NUMSFX) {
		I_Error("Bad sfx #: %d", sfx_id);
	}
	sfx = &S_sfx[sfx_id];
  
	// Initialize sound parameters
	if (sfx->link) {
		pitch = sfx->pitch;
		priority = sfx->priority;
	    volume += sfx->volume;
    
		if (volume < 1) {
			return;
		}
		if (volume > snd_SfxVolume) {
			volume = snd_SfxVolume;
		}
	}	 else {
		pitch = NORM_PITCH;
		priority = NORM_PRIORITY;
	}


	// Check to see if it is audible,
	//  and if not, modify the params
	if (origin_pRef && origin_pRef != players[consoleplayer].moRef) {
		rc = S_AdjustSoundParams(players[consoleplayer].moRef, origin_pRef, &volume, &sep, &pitch);
	
		playerMo = (mobj_t*)Z_LoadBytesFromEMS(players[consoleplayer].moRef);
		if ( originX == playerMo->x && originY == playerMo->y) {	
			sep 	= NORM_SEP;
		}
    
		if (!rc) {
			return;
		}
	} else {
		sep = NORM_SEP;
	}
  
	// hacks to vary the sfx pitches
	if (sfx_id >= sfx_sawup && sfx_id <= sfx_sawhit) {	
		pitch += 8 - (M_Random()&15);
    
		if (pitch<0)
			pitch = 0;
		else if (pitch>255)
		pitch = 255;
	} else if (sfx_id != sfx_itemup && sfx_id != sfx_tink) {
		pitch += 16 - (M_Random()&31);
    
    if (pitch<0)
		pitch = 0;
    else if (pitch>255)
		pitch = 255;
	}

	// kill old sound
	S_StopSound(origin_pRef);

	// try to find a channel
	cnum = S_getChannel(origin_pRef, sfx);
  
	if (cnum<0)
		return;

	//
	// This is supposed to handle the loading/caching.
	// For some odd reason, the caching is done nearly
	//  each time the sound is needed?
	//
  
	// get lumpnum if necessary
	if (sfx->lumpnum < 0)
		sfx->lumpnum = I_GetSfxLumpNum(sfx);

	// cache data if necessary
	if (!sfx->data) {
		sfx->data = (void *) W_CacheLumpNum(sfx->lumpnum, PU_MUSIC);

		_dpmi_lockregion(sfx->data, lumpinfo[sfx->lumpnum].size);
		// fprintf( stderr,
		//	     "S_StartSoundAtVolume: loading %d (lump %d) : 0x%x\n",
		//       sfx_id, sfx->lumpnum, (int)sfx->data );
    
	}
  
	// increase the usefulness
	if (sfx->usefulness++ < 0)
		sfx->usefulness = 1;
  
	// Assigns the handle to one of the channels in the
	//  mix/output buffer.
	channels = (channel_t*)Z_LoadBytesFromEMS(channelsRef);
	channels[cnum].handle = I_StartSound(sfx_id,
				       sfx->data,
				       volume,
				       sep,
				       pitch,
				       priority);
}

void S_StartSoundFromRef(MEMREF memref,	int		sfx_id)  {
	
	mobj_t* mobj;
	if (memref) {
		mobj = (mobj_t*)Z_LoadBytesFromEMS(memref);
		 
		S_StartSoundAtVolume(memref, mobj->x, mobj->y, sfx_id, snd_SfxVolume);
	} else {
		S_StartSoundAtVolume(memref, 0, 0, sfx_id, snd_SfxVolume);
	}
}

void S_StartSound(void*		origin, int		sfx_id) {
#ifdef SAWDEBUG
	// if (sfx_id == sfx_sawful)
	// sfx_id = sfx_itemup;
#endif
	mobj_t* mobj = (mobj_t*)origin;

	if (mobj) {
		S_StartSoundAtVolume(NULL_MEMREF, mobj->x, mobj->y, sfx_id, snd_SfxVolume);
	}
	else {
		S_StartSoundAtVolume(NULL_MEMREF, -1, -1, sfx_id, snd_SfxVolume);
	}








	// UNUSED. We had problems, had we not?
#ifdef SAWDEBUG
	{
		int i;
		int n;

		static mobj_t*      last_saw_origins[10] = { 1,1,1,1,1,1,1,1,1,1 };
		static int		first_saw = 0;
		static int		next_saw = 0;

		if (sfx_id == sfx_sawidl
			|| sfx_id == sfx_sawful
			|| sfx_id == sfx_sawhit)
		{
			for (i = first_saw; i != next_saw; i = (i + 1) % 10)
				if (last_saw_origins[i] != origin)
					fprintf(stderr, "old origin 0x%lx != "
						"origin 0x%lx for sfx %d\n",
						last_saw_origins[i],
						origin,
						sfx_id);

			last_saw_origins[next_saw] = origin;
			next_saw = (next_saw + 1) % 10;
			if (next_saw == first_saw)
				first_saw = (first_saw + 1) % 10;

			for (n = i = 0; i < numChannels; i++)
			{
				if (channels[i].sfxinfo == &S_sfx[sfx_sawidl]
					|| channels[i].sfxinfo == &S_sfx[sfx_sawful]
					|| channels[i].sfxinfo == &S_sfx[sfx_sawhit]) n++;
			}

			if (n > 1)
			{
				for (i = 0; i < numChannels; i++)
				{
					if (channels[i].sfxinfo == &S_sfx[sfx_sawidl]
						|| channels[i].sfxinfo == &S_sfx[sfx_sawful]
						|| channels[i].sfxinfo == &S_sfx[sfx_sawhit])
					{
						fprintf(stderr,
							"chn: sfxinfo=0x%lx, origin=0x%lx, "
							"handle=%d\n",
							channels[i].sfxinfo,
							channels[i].origin,
							channels[i].handle);
					}
				}
				fprintf(stderr, "\n");
			}
		}
	}
#endif

}
void S_StartSoundWithParams(int x, int y, int		sfx_id) {
	S_StartSoundAtVolume(NULL_MEMREF, x, y, sfx_id, snd_SfxVolume);
}

//
// Updates music & sounds
//
void S_UpdateSounds(MEMREF listenerRef)
{
    int		audible;
    int		cnum;
    int		volume;
    int		sep;
    int		pitch;
    sfxinfo_t*	sfx;
    channel_t*	c;
    int         i;
	//mobj_t*	listener_p = (mobj_t*)Z_LoadBytesFromEMS(listenerRef);
    //mobj_t*	listener = (mobj_t*)listener_p;
	channel_t* channels;

    
    // Clean up unused data.
    if (gametic > nextcleanup)
    {
	for (i=1 ; i<NUMSFX ; i++)
	{
	    if (S_sfx[i].usefulness < 1
		&& S_sfx[i].usefulness > -1)
	    {
		if (--S_sfx[i].usefulness == -1)
		{
		    Z_ChangeTag(S_sfx[i].data, PU_CACHE);
                    _dpmi_unlockregion(S_sfx[i].data,
                                       lumpinfo[S_sfx[i].lumpnum].size);
		    S_sfx[i].data = 0;
		}
	    }
	}
	nextcleanup = gametic + 15;
    }
    
	channels = (channel_t*)Z_LoadBytesFromEMS(channelsRef);
	for (cnum=0 ; cnum<numChannels ; cnum++)
    {
	c = &channels[cnum];
	sfx = c->sfxinfo;

	if (c->sfxinfo)
	{
	    if (I_SoundIsPlaying(c->handle))
	    {
		// initialize parameters
		volume = snd_SfxVolume;
		pitch = NORM_PITCH;
		sep = NORM_SEP;

		if (sfx->link)
		{
		    pitch = sfx->pitch;
		    volume += sfx->volume;
		    if (volume < 1)
		    {
			S_StopChannel(cnum);
			continue;
		    }
		    else if (volume > snd_SfxVolume)
		    {
			volume = snd_SfxVolume;
		    }
		}

		// check non-local sounds for distance clipping
		//  or modify their params
		if (c->originRef && listenerRef != c->originRef)
		{
		    audible = S_AdjustSoundParams(listenerRef,
						  c->originRef,
						  &volume,
						  &sep,
						  &pitch);
		    
		    if (!audible)
		    {
			S_StopChannel(cnum);
		    }
		    else
			I_UpdateSoundParams(c->handle, volume, sep, pitch);
		}
	    }
	    else
	    {
		// if channel is allocated but sound has stopped,
		//  free it
		S_StopChannel(cnum);
	    }
	}
    }
    // kill music if it is a single-play && finished
    // if (	mus_playing
    //      && !I_QrySongPlaying(mus_playing->handle)
    //      && !mus_paused )
    // S_StopMusic();
}

//
// Initializes sound stuff, including volume
// Sets channels, SFX and music volume,
//  allocates channel buffer, sets S_sfx lookup.
//
void S_Init
( int		sfxVolume,
  int		musicVolume )
{  
  int		i;
  channel_t* channels;

  //fprintf( stderr, "S_Init: default sfx volume %d\n", sfxVolume);

  // Whatever these did with DMX, these are rather dummies now.
  I_SetChannels(numChannels);
  
  S_SetSfxVolume(sfxVolume);
  // No music with Linux - another dummy.
  S_SetMusicVolume(musicVolume);

  // Allocating the internal channels for mixing
  // (the maximum numer of sounds rendered
  // simultaneously) within zone memory.
  channelsRef =  Z_MallocEMSNew (numChannels*sizeof(channel_t), PU_STATIC, 0, ALLOC_TYPE_SOUND_CHANNELS);
  channels = (channel_t*) Z_LoadBytesFromEMS(channelsRef);

  // Free all channels for use
  for (i=0 ; i<numChannels ; i++)
    channels[i].sfxinfo = 0;
  
  // no sounds are playing, and they are not mus_paused
  mus_paused = 0;

  // Note that sounds have not been cached (yet).
  for (i=1 ; i<NUMSFX ; i++)
    S_sfx[i].lumpnum = S_sfx[i].usefulness = -1;
}

//
// Per level startup code.
// Kills playing sounds at start of level,
//  determines music if any, changes music.
//
void S_Start(void)
{
  int cnum;
  int mnum;
  channel_t* channels = (channel_t*)Z_LoadBytesFromEMS(channelsRef);

  // kill all playing sounds at start of level
  //  (trust me - a good idea)
  for (cnum=0 ; cnum<numChannels ; cnum++)
    if (channels[cnum].sfxinfo)
      S_StopChannel(cnum);
  
  // start new music for the level
  mus_paused = 0;
  
  if (commercial)
    mnum = mus_runnin + gamemap - 1;
  else
  {
    int spmus[]=
    {
      // Song - Who? - Where?
      
      mus_e3m4,	// American	e4m1
      mus_e3m2,	// Romero	e4m2
      mus_e3m3,	// Shawn	e4m3
      mus_e1m5,	// American	e4m4
      mus_e2m7,	// Tim 	e4m5
      mus_e2m4,	// Romero	e4m6
      mus_e2m6,	// J.Anderson	e4m7 CHIRON.WAD
      mus_e2m5,	// Shawn	e4m8
      mus_e1m9	// Tim		e4m9
    };
    
    if (gameepisode < 4)
      mnum = mus_e1m1 + (gameepisode-1)*9 + gamemap-1;
    else
      mnum = spmus[gamemap-1];
    }	
  
  // HACK FOR COMMERCIAL
  //  if (commercial && mnum > mus_e3m9)	
  //      mnum -= mus_e3m9;
  
  S_ChangeMusic(mnum, true);
  
  nextcleanup = 15;
}

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
#include "m_near.h"
//#include "dpmiapi.h"

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

#define S_STEREO_SWING		(96*0x10000)

// percent attenuation from front to back
#define S_IFRACVOL		30

#define NA			0




//
// Internals.
//
int8_t S_getChannel (THINKERREF originRef, int16_t soundorg_secnum, sfxenum_t sfx_id );


int16_t S_AdjustSoundParams ( THINKERREF listenerRef, fixed_t_union x, fixed_t_union y, uint8_t* vol, uint8_t* sep, uint8_t* pitch );

void S_StopChannel(int8_t cnum);

void S_SetMusicVolume(uint8_t volume) {
	
	//volume &= 127; // necessary?

    snd_MusicVolume = volume;

	if (playingdriver){
		playingdriver->changeSystemVolume(volume);
	}



}
void S_ChangeMusic ( musicenum_t musicnum, boolean looping ) {
	pendingmusicenum = musicnum;
	pendingmusicenumlooping = looping;
}
/*

void S_ActuallyChangeMusic (  ) {

    musicinfo_t*	music;
	int8_t		namebuf[9];
	musicenum_t musicnum = pendingmusicenum;
	boolean looping = pendingmusicenumlooping;
	pendingmusicenum = 0;


    if (snd_MusicDevice == snd_Adlib && musicnum == mus_intro) {
        musicnum = mus_introa;
    }

    if ( (musicnum == mus_None) || (musicnum >= NUMMUSIC) ) {
		return; // bad music number?
    } else {
		music = &S_music[musicnum];
	}	

    if (mus_playing == musicnum){
		return;
	}

    // shutdown old music
    if (mus_playing) {
		playingstate = ST_STOPPED;
			// todo signal driver pause?
			if (playingdriver){
				playingdriver->stopMusic();
			}      
		mus_playing = mus_None;
    }
	
	// todo use music->name
	//combine_strings(namebuf, "d", music->name);
	combine_strings(namebuf, "d_", "e1m1");

    // load & register it
    //music->data = (void __far*) W_CacheLumpNum(music->lumpnum, PU_MUSIC);
    I_LoadSong(W_GetNumForName(namebuf));

	if (playingdriver){
		playingdriver->playMusic();  // todo rename. this sets up variables in the driver for the track
	}

    //_dpmi_lockregion(music->data, lumpinfo[music->lumpnum].size);
    mus_playing = musicnum;

    // play it
    playingstate = ST_PLAYING;
    loops_enabled = true;
    if (playingdriver){
        playingdriver->stopMusic();
    }

	
}
*/

//
// Starts some music with the music id found in sounds.h.
//
void S_StartMusic(musicenum_t m_id) {
    S_ChangeMusic(m_id, false);
}

void S_StopChannel(int8_t cnum) {
    int8_t		i;
	
    channel_t*	c = &channels[cnum];

    if (c->sfx_id) {
		// stop the sound playing
		if (I_SoundIsPlaying(c->handle)) {
			I_StopSound(c->handle);
		}

		// check to see
		//  if other channels are playing the sound
		for (i=0 ; i<numChannels ; i++) {
			if (cnum != i && c->sfx_id == channels[i].sfx_id) {
				break;
			}
		}
		

		c->sfx_id = sfx_None;
    }


}

//
// Changes volume, stereo-separation, and pitch variables
//  from the norm of a sound effect to be played.
// If the sound is not audible, returns a 0.
// Otherwise, modifies parameters and returns 1.
//
int16_t S_AdjustSoundParams ( THINKERREF listenerRef, fixed_t_union sourceX, fixed_t_union sourceY, uint8_t* vol, uint8_t* sep, uint8_t* pitch ){
	fixed_t	approx_dist;
    fixed_t	adx;
    fixed_t	ady;
    angle_t	angle;
	mobj_pos_t __far * listener = (mobj_pos_t __far *)&mobjposlist_6800[listenerRef];
	//mobj_pos_t __far * source   = (mobj_pos_t __far *)&mobjposlist_6800[sourceRef];
	//return 0;



    // calculate the distance to sound origin
    //  and clip it if necessary
    adx = labs(listener->x.w - sourceX.w);
    ady = labs(listener->y.w - sourceY.w);

    // From _GG1_ p.428. Appox. eucledian distance fast.
    approx_dist = adx + ady - ((adx < ady ? adx : ady)>>1);
    
    if (gamemap != 8
	&& approx_dist > S_CLIPPING_DIST)
    {
	return 0;
    }
    
    // angle of source to listener
    angle.w = R_PointToAngle2(listener->x,
			    listener->y,
			    sourceX,
			    sourceY);

    if (angle.w > listener->angle.w){
		angle.w = angle.w - listener->angle.w;
	} else{
		angle.w = angle.w + (0xffffffff - listener->angle.w);
	}

    // stereo separation
	// todo optimize. 96 * finesine?
    *sep = 128 - (FixedMul(S_STEREO_SWING,finesine[angle.h.intbits >> 3])>>FRACBITS);

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

void S_SetSfxVolume(uint8_t volume) {

#ifdef CHECK_FOR_ERRORS
	if ( volume > 127){
		I_Error("Attempt to set sfx volume at %d", volume);
	}
#endif
    snd_SfxVolume = volume;

}

//
// Stop and resume music, during game PAUSE.
//
void S_PauseSound(void) {
    if (mus_playing && !mus_paused) {
		I_PauseSong();
		mus_paused = true;
    }
}

void S_ResumeSound(void) {
    if (mus_playing && mus_paused) {
		I_ResumeSong();
		mus_paused = false;
    }
}

void S_StopSound(THINKERREF originRef, int16_t soundorg_secnum) {
	
	int8_t cnum;

	if (soundorg_secnum != SECNUM_NULL){
		for (cnum=0 ; cnum<numChannels ; cnum++) {
			if (channels[cnum].sfx_id && channels[cnum].soundorg_secnum == soundorg_secnum) {
				S_StopChannel(cnum);
				break;
			}
		}

	} else {
		for (cnum=0 ; cnum<numChannels ; cnum++) {
			if (channels[cnum].sfx_id && channels[cnum].originRef == originRef) {
				S_StopChannel(cnum);
				break;
			}
		}

	}



}

//
// S_getChannel :
//   If none available, return -1.  Otherwise channel #.
//
int8_t S_getChannel (THINKERREF originRef, int16_t soundorg_secnum, sfxenum_t sfx_id ) {
    // channel number to use

    int8_t		cnum;
    
    channel_t*	c;

    // Find an open channel
    for (cnum=0 ; cnum<numChannels ; cnum++) {
		if (!channels[cnum].sfx_id) {
			break;
		} else if (originRef &&  channels[cnum].originRef == originRef) {
			S_StopChannel(cnum);
			break;
		}
    }

    // None available
    if (cnum == numChannels) {
	// Look for lower priority
		for (cnum=0 ; cnum<numChannels ; cnum++){
			if (sfx_priority[channels[cnum].sfx_id] >= sfx_priority[sfx_id]) {
				break;
			}
		}
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
    c->sfx_id = sfx_id;
    c->originRef = originRef;
	c->soundorg_secnum = soundorg_secnum;

    return cnum;

}

void S_StartSoundWithPosition ( mobj_t __near* origin, sfxenum_t sfx_id, int16_t soundorg_secnum ) {
  int16_t		rc;
  uint8_t		sep;
  uint8_t		pitch;
  uint8_t		priority;
//   sfxinfo_t*	sfx;
  int8_t		cnum;
  mobj_t*	playerMo;	    
  THINKERREF    originRef = GETTHINKERREF(origin);
  uint8_t volume = snd_SfxVolume;

	// check for bogus sound #
	if (sfx_id < 1 || sfx_id > NUMSFX) {

		#ifdef CHECK_FOR_ERRORS
			I_Error("Bad sfx #: %d", sfx_id);
		#endif
	}
	// sfx = &S_sfx[sfx_id];
  
	/*
	// Initialize sound parameters
	if (sfx->link) {
		pitch = 150;//   sfx->pitch;
		priority = 0; // sfx->priority;
    
		if (volume < 1) {
			return;
		}
		if (volume > snd_SfxVolume) {
			volume = snd_SfxVolume;
		}
	} else {
		pitch = NORM_PITCH;
		priority = NORM_PRIORITY;
	}
	*/


	// Check to see if it is audible,
	//  and if not, modify the params
	if ((origin || (soundorg_secnum != SECNUM_NULL)) && (originRef != playerMobjRef)){
		fixed_t_union originX;
		fixed_t_union originY;
		if (soundorg_secnum != SECNUM_NULL){
			originX.h.intbits = sectors_soundorgs[soundorg_secnum].soundorgX;
			originY.h.intbits = sectors_soundorgs[soundorg_secnum].soundorgY;
			originX.h.fracbits = 0;
			originY.h.fracbits = 0;
		} else {
			mobj_pos_t __far* originMobjPos = &mobjposlist_6800[originRef];
			originX = originMobjPos->x;
			originY = originMobjPos->y;
		}
		rc = S_AdjustSoundParams(playerMobjRef, originX, originY, &volume, &sep, &pitch);
		
		if ( originX.w == playerMobj_pos->x.w && originY.w == playerMobj_pos->y.w) {	
			sep = NORM_SEP;
		}
		
    
		if (!rc) {
			return;
		}
	} else {
		sep = NORM_SEP;
	}
 

	// kill old sound
	S_StopSound(originRef, soundorg_secnum);


	// try to find a channel
	cnum = S_getChannel(originRef, soundorg_secnum, sfx_id);
  
	if (cnum<0)
		return;

	//
	// This is supposed to handle the loading/caching.
	// For some odd reason, the caching is done nearly
	//  each time the sound is needed?
	//
  
	// get lumpnum if necessary
	// todo move this to initialization loop.


	// cache data if necessary
	// if (!sfx->data) {
		//sfx->data = (void __far *) W_CacheLumpNum(sfx->lumpnum, PU_MUSIC);

		//_dpmi_lockregion(sfx->data, lumpinfo[sfx->lumpnum].size);
		// fprintf( stderr,
		//	     "S_StartSoundWithPosition: loading %d (lump %d) : 0x%x\n",
		//       sfx_id, sfx->lumpnum, sfx->data );
    
	// }
  
	// increase the usefulness
	// if (sfx->usefulness++ < 0)
	// 	sfx->usefulness = 1;
  
	// Assigns the handle to one of the channels in the
	//  mix/output buffer.
	channels[cnum].handle = I_StartSound(sfx_id,
				       volume,
				       sep,
				       pitch,
				       priority);

}


void S_StartSound(mobj_t __near* mobj, sfxenum_t sfx_id) {
	
	if (sfx_id == 0) {
		return;
	}
	S_StartSoundWithPosition(mobj, sfx_id, SECNUM_NULL);

}

void S_StartSoundWithParams(int16_t soundorg_secnum, sfxenum_t sfx_id) {
	if (sfx_id == 0) {
		return;
	}

	S_StartSoundWithPosition(NULL_THINKERREF, sfx_id, soundorg_secnum);
}

//
// Updates music & sounds
//
void S_UpdateSounds(THINKERREF listenerRef) {
	

	
	int16_t		audible;
    int8_t		cnum;
    uint8_t		volume;
    uint8_t		sep;
    uint8_t		pitch;
    sfxenum_t	sfx_id;
    channel_t*	c;
	uint8_t         i;
	//mobj_t*	listener_p = (mobj_t*)Z_LoadThinkerBytesFromEMS(listenerRef);
    //mobj_t*	listener = (mobj_t*)listener_p;

    // Clean up unused data.
    // if (gametic > nextcleanup) {
	// 	for (i=1 ; i<NUMSFX ; i++) {
	// 		if (S_sfx[i].usefulness < 1 && S_sfx[i].usefulness > -1) {
	// 			if (--S_sfx[i].usefulness == -1) {
	// 				//Z_ChangeTag(S_sfx[i].data, PU_CACHE);
	// 						//_dpmi_unlockregion(S_sfx[i].data, lumpinfo[S_sfx[i].lumpnum].size);
					
	// 				//S_sfx[i].data = 0;
	// 			}
	// 		}
	// 	}
	// 	nextcleanup = gametic + 15;
    // }
    
	for (cnum=0 ; cnum<numChannels ; cnum++) {
		c = &channels[cnum];
		sfx_id = c->sfx_id;

		if (sfx_id) {
			if (I_SoundIsPlaying(c->handle)) {
			// initialize parameters
			volume = snd_SfxVolume;
			pitch = NORM_PITCH;
			sep = NORM_SEP;

			// the only one with a link...
			if (sfx_id == sfx_chgun) {
				// link is only used once in the dataset and hardcoded there - rather than including all this extra
				// data in memory we just hardcode the fields...
				pitch = 150;
				//volume += 0; 
				if (volume < 1) {
					S_StopChannel(cnum);
					continue;
				} else if (volume > snd_SfxVolume) {
					volume = snd_SfxVolume;
				}
			}

			// check non-local sounds for distance clipping
			//  or modify their params

			// todo double check this logic once pcm sfx reimplemented...
			if ((c->originRef && listenerRef != c->originRef) ||(c->soundorg_secnum != SECNUM_NULL)) {
				fixed_t_union originX;
				fixed_t_union originY;

				if (c->soundorg_secnum != SECNUM_NULL){
					originX.h.intbits = sectors_soundorgs[c->soundorg_secnum].soundorgX;
					originY.h.intbits = sectors_soundorgs[c->soundorg_secnum].soundorgY;
					originX.h.fracbits = 0;
					originY.h.fracbits = 0;
				} else {
					mobj_pos_t __far* originMobjPos = &mobjposlist_6800[c->originRef];
					originX = originMobjPos->x;
					originY = originMobjPos->y;
				}
				
				
				audible = S_AdjustSoundParams(listenerRef,
							originX,
							originY,
							&volume,
							&sep,
							&pitch);
				
				if (!audible) {
					S_StopChannel(cnum);
				} else{
					I_UpdateSoundParams(c->handle, volume, sep, pitch);
				}
			}
			}
			else {
				// if channel is allocated but sound has stopped,
				//  free it
				S_StopChannel(cnum);
			}
		}
    }
    // kill music if it is a single-play && finished
    // if (	mus_playing
    //      && !I_QrySongPlaying()
    //      && !mus_paused )
    // S_StopMusic();
	

}


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


#include "doomdef.h"

#include <stdio.h>
#include <stdlib.h>

#include "i_system.h"
#include "i_sound.h"
#include "sounds.h"
#include "s_sound.h"

#include "z_zone.h"
#include "m_misc.h"
#include "w_wad.h"

#include "p_local.h"

#include "doomstat.h"
#include <dos.h>
#include "dmx.h"
#include "m_near.h"
//#include "dpmiapi.h"







//
// Internals.
//



int16_t S_AdjustSoundParams ( fixed_t_union x, fixed_t_union y, uint8_t* vol, uint8_t* sep );

void S_StopChannel(int8_t cnum);

void S_SetMusicVolume(uint8_t volume) {
	
	//volume &= 127; // necessary?

    snd_MusicVolume = volume << 3;

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
		// todo move the check into stop sound..
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

//todo optimize to make this logic generally 16 bit 
// instead of generally 32 bit. 
// probably fine, does not affect physics.

uint8_t S_AdjustSoundParamsSep ( fixed_t_union sourceX, fixed_t_union sourceY){

	angle_t	angle;
	fixed_t_union intermediate;
	
    
    // angle of source to listener
    angle.w = R_PointToAngle2(playerMobj_pos->x,
			    playerMobj_pos->y,
			    sourceX,
			    sourceY);

    if (angle.w > playerMobj_pos->angle.w){
		angle.w = angle.w - playerMobj_pos->angle.w;
	} else{
		angle.w = angle.w + (0xffffffff - playerMobj_pos->angle.w);
	}



    // stereo separation
	// get fine angle
	angle.h.intbits >>= 3;
	// mul by 96... optimize with shifts and adds?
	intermediate.h.intbits = FastMul16u32(S_STEREO_SWING_HIGH,finesine[angle.h.intbits]);
    return 128 - (intermediate.h.intbits);




}

s
uint8_t __near S_AdjustSoundParamsVol ( fixed_t_union sourceX, fixed_t_union sourceY){
	fixed_t_union	approx_dist;
    fixed_t_union	adx;
    fixed_t_union	ady;
	fixed_t_union intermediate;

    // calculate the distance to sound origin
    //  and clip it if necessary
    adx.w = labs(playerMobj_pos->x.w - sourceX.w);
    ady.w = labs(playerMobj_pos->y.w - sourceY.w);

    // From _GG1_ p.428. Appox. eucledian distance fast.
	intermediate.w = ((adx.w < ady.w ? adx.w : ady.w)>>1);
    approx_dist.w = adx.w + ady.w - intermediate.w;
    
    if (gamemap != 8 && approx_dist.w > S_CLIPPING_DIST) {
		return 0;
    }
    
    // volume calculation
    if (approx_dist.h.intbits < S_CLOSE_DIST_HIGH) {
		return MAX_SOUND_VOLUME;


    } else if (gamemap != 8) {
		// distance effect

		intermediate.w = S_CLIPPING_DIST - approx_dist.w;
		// 127 * intbits / 1000? probably just shift right 3.
		return FastDiv3216u(FastMul1616(MAX_SOUND_VOLUME, intermediate.h.intbits), S_ATTENUATOR); 
	} else { // gamemap == 8
		if (approx_dist.h.intbits >= S_CLIPPING_DIST_HIGH){
			return 15;	// should this just be 0?
		} else {
			intermediate.w = S_CLIPPING_DIST - approx_dist.w;
			
			// todo... 112 * intbits over 1000. can we avoid the div...
			return 15 + FastDiv3216u(( FastMul1616((MAX_SOUND_VOLUME-15), intermediate.h.intbits)),  S_ATTENUATOR);
		}

    }

}

void __far S_InitSFXCache();

void S_SetSfxVolume(uint8_t volume) {
	int8_t i;
	if (volume){
    	snd_SfxVolume = 7 + (volume << 3);
	} else {
    	snd_SfxVolume = 0;
	}
	//Kind of complicated... 
	// unload sfx. stop all sfx.
	// when we reload, the sfx will be premixed with application volume.
	// this way we dont do it in interrupt.
	_disable();
	for (i = 0; i < NUM_SFX_TO_MIX; i++){
		sb_voicelist[i].sfx_id = 0;	// turn off...
	}

	S_InitSFXCache();
	_enable();
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

void __far S_StopSound(mobj_t __near* origin, int16_t soundorg_secnum) {
	
	int8_t cnum;

	if (soundorg_secnum != SECNUM_NULL){
		for (cnum=0 ; cnum<numChannels ; cnum++) {
			if (channels[cnum].sfx_id && channels[cnum].soundorg_secnum == soundorg_secnum) {
				S_StopChannel(cnum);
				break;
			}
		}

	} else {
		if (origin){
		    THINKERREF originRef = GETTHINKERREF(origin);
			for (cnum=0 ; cnum<numChannels ; cnum++) {
				if (channels[cnum].sfx_id && channels[cnum].originRef == originRef) {
					S_StopChannel(cnum);
					break;
				}
			}

		}

	}



}

void far S_StopSoundMobjRef(mobj_t __near* origin) {
	
	int8_t cnum;
	if (origin){
		THINKERREF originRef = GETTHINKERREF(origin);

		for (cnum=0 ; cnum<numChannels ; cnum++) {
			if (channels[cnum].sfx_id && channels[cnum].originRef == originRef) {
				S_StopChannel(cnum);
				break;
			}
		}
	}

}

#define NULL_THINKER_ORIGINREF 0xFFFF
//
// S_getChannel :
//   If none available, return -1.  Otherwise channel #.
//
int8_t __near S_getChannel (mobj_t __near* origin, int16_t soundorg_secnum, sfxenum_t sfx_id ) {
    // channel number to use

    int8_t		cnum;
    channel_t*	c;

    // Find an open channel
    for (cnum=0 ; cnum<numChannels ; cnum++) {
		if (!channels[cnum].sfx_id) {
			break;
		} else if (origin){
			if ( channels[cnum].originRef == GETTHINKERREF(origin)) {
				S_StopChannel(cnum);
				break;
			}
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

	// if (origin == NULL){
	// 	I_Error("null origin??");
	// }

    c = &channels[cnum];

    // channel is decided to be cnum.
    c->sfx_id = sfx_id;
    c->originRef = origin ? GETTHINKERREF(origin) : NULL_THINKER_ORIGINREF; // 
	c->soundorg_secnum = soundorg_secnum;

    return cnum;

}

/*
void logsound(int8_t cnum, sfxenum_t sfx_id){
		
	FILE* fp = fopen ("sound.txt", "ab");
	// fprintf(fp, "channel %i %i %i\n", sfx_id, cnum);
	if (cnum < 0){
		fputc('n', fp);

	} else {
		fputc('0' + cnum % 10, fp);
	}
	fputc(' ', fp);
	fputc('0' + (sfx_id / 100), fp);
	fputc('0' + ((sfx_id / 10) % 10), fp);
	fputc('0' + (sfx_id % 10), fp);
	fputc('\0', fp);
	fclose(fp);

}
*/

void S_StartSoundWithPosition ( mobj_t __near* origin, sfxenum_t sfx_id, int16_t soundorg_secnum ) {
  int16_t		rc;
  uint8_t		sep;
  uint8_t		priority;
//   sfxinfo_t*	sfx;
  int8_t		cnum;
  mobj_t*	playerMo;	    
  THINKERREF    originRef = GETTHINKERREF(origin);
   
  uint8_t volume = MAX_SOUND_VOLUME;
  if (snd_SfxDevice == snd_none){
	return;
  }
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

		priority = 0; // sfx->priority;
    
		if (volume < 1) {
			return;
		}
		if (volume > snd_SfxVolume) {
			volume = snd_SfxVolume;
		}
	} else {

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
		volume = S_AdjustSoundParamsVol(originX, originY);
		
		if (!volume) {
			return;
		}

		if ( originX.w == playerMobj_pos->x.w && originY.w == playerMobj_pos->y.w) {	
			sep = NORM_SEP;
		} else {
			sep = S_AdjustSoundParamsSep(originX, originY);
		}
		

	} else {
		sep = NORM_SEP;
	}
 

	// kill old sound
	S_StopSound(origin, soundorg_secnum);


	// try to find a channel
	cnum = S_getChannel(origin, soundorg_secnum, sfx_id);

	// logsound(cnum, sfx_id);
	if (cnum >= 0){

		// Note: I_StartSound [eventually] handles loading, cacheing, etc.
		rc = I_StartSound(sfx_id, volume, sep);

		if (rc != -1){
			channels[cnum].handle = rc;
		}
	}
}


void __far S_StartSound(mobj_t __near* mobj, sfxenum_t sfx_id) {
	
	if (sfx_id == 0) {
		return;
	}
	S_StartSoundWithPosition(mobj, sfx_id, SECNUM_NULL);

}

void __far S_StartSoundWithParams(int16_t soundorg_secnum, sfxenum_t sfx_id) {
	if (sfx_id == 0) {
		return;
	}

	S_StartSoundWithPosition(NULL_THINKERREF, sfx_id, soundorg_secnum);
}

//
// Updates music & sounds
//
void S_UpdateSounds() {
	

	
	int16_t		audible;
    int8_t		cnum;
    uint8_t		volume;
    uint8_t		sep;

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
				volume = MAX_SOUND_VOLUME;
				sep = NORM_SEP;

			

				// check non-local sounds for distance clipping
				//  or modify their params

				// determine origin based on sector or source thinker ref.
				if ((c->originRef != NULL_THINKER_ORIGINREF && playerMobjRef != c->originRef) || (c->soundorg_secnum != SECNUM_NULL)) {
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
					
					
					volume = S_AdjustSoundParamsVol(originX, originY);
					
					if (!volume) {
						S_StopChannel(cnum);
					} else{
						sep = S_AdjustSoundParamsSep(originX, originY);
						I_UpdateSoundParams(c->handle, volume, sep);
					}
				}
			} else {
				// if channel is allocated but sound has stopped,
				//  free it
				S_StopChannel(cnum);
			}
		}
    }

	// todo.. re-enable and test this!

    // kill music if it is a single-play && finished
    // if (	mus_playing
    //      && !I_QrySongPlaying()
    //      && !mus_paused )
    // S_StopMusic();
	

}


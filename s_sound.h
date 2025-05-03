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
// DESCRIPTION:
//	The not so system specific sound interface.
//


#ifndef __S_SOUND__
#define __S_SOUND__

#include "z_zone.h"
#include "doomdef.h"
#include "p_mobj.h"
#include "sounds.h"

typedef uint8_t musicenum_t;
typedef uint8_t sfxenum_t;

//
// Initializes sound stuff, including volume
// Sets channels, SFX and music volume,
//  allocates channel buffer, sets S_sfx lookup.
//
 

#define MAX_SFX_CHANNELS 3
 

typedef struct {
    // sound information (if null, channel avail.)

    // hack for doing degen mobjs
    int16_t     soundorg_secnum;

    // origin of sound
	THINKERREF	originRef;

    // handle of the sound being played
    int8_t		handle;

    sfxenum_t	sfx_id;

} channel_t;
//
// Per level startup code.
// Kills playing sounds at start of level,
//  determines music if any, changes music.
//
void S_Start(void);


//
// Start sound for thing at <origin>
//  using <sound_id> from sounds.h
//
void S_StartSound (mobj_t __near*	origin, sfxenum_t	sound_id );

void S_StartSoundWithParams(int16_t soundorg_secnum, sfxenum_t sound_id);



// Will start a sound at a given volume.
void S_StartSoundWithPosition ( mobj_t __near* origin, sfxenum_t sfx_id, int16_t soundorg_secnum );


// Stop sound for thing at <origin>
void S_StopSound(mobj_t __near* origin, int16_t soundorg_secnum);
void S_StopSoundMobjRef(mobj_t __near* origin);


// Start music using <music_id> from sounds.h
void S_StartMusic(musicenum_t music_id);

// Start music using <music_id> from sounds.h,
//  and set whether looping
void S_ChangeMusic ( musicenum_t music_id, boolean looping );



// Stops the music fer sure.
void S_StopMusic(void);

// Stop and resume music, during game PAUSE.
void S_PauseSound(void);
void S_ResumeSound(void);


//
// Updates music & sounds
//
void S_UpdateSounds(THINKERREF listenerRef);

void S_SetMusicVolume(uint8_t volume);
void S_SetSfxVolume(uint8_t volume);


#endif

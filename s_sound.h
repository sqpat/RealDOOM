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
 

#define MAX_SFX_CHANNELS 8
 

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
void __far S_Start(void);


//
// Start sound for thing at <origin>
//  using <sound_id> from sounds.h
//
void __far S_StartSound (mobj_t __near*	origin, sfxenum_t	sound_id );

void __far S_StartSoundWithParams(int16_t soundorg_secnum, sfxenum_t sound_id);



// Will start a sound at a given volume.
void __far S_StartSoundWithPosition ( mobj_t __near* origin, sfxenum_t sfx_id, int16_t soundorg_secnum );


// Stop sound for thing at <origin>
void far S_StopSound(mobj_t __near* origin, int16_t soundorg_secnum);
void far S_StopSoundMobjRef(mobj_t __near* origin);


// Start music using <music_id> from sounds.h
void __far S_StartMusic(musicenum_t music_id);

// Start music using <music_id> from sounds.h,
//  and set whether looping
void __far S_ChangeMusic ( musicenum_t music_id, boolean looping );



// Stops the music fer sure.
void __far S_StopMusic(void);

// Stop and resume music, during game PAUSE.
void __far S_PauseSound(void);
void __far S_ResumeSound(void);


//
// Updates music & sounds
//
void __far S_UpdateSounds();

void __far S_SetMusicVolume(uint8_t volume);
void __far S_SetSfxVolume(uint8_t volume);



// when to clip out sounds
// Does not fit the large outdoor areas.
#define S_CLIPPING_DIST		(1200*0x10000)
#define S_CLIPPING_DIST_HIGH	(1200)

// Distance tp origin when sounds should be maxed out.
// This should relate to movement clipping resolution
// (see BLOCKMAP handling).
#define S_CLOSE_DIST		(200*0x10000)
#define S_CLOSE_DIST_HIGH		(200)


// #define S_ATTENUATOR		((S_CLIPPING_DIST-S_CLOSE_DIST)>>FRACBITS)
#define S_ATTENUATOR		1000

// Adjustable by menu.
#define NORM_VOLUME    		snd_MaxVolume

#define NORM_PRIORITY		64
#define NORM_SEP		128

#define S_STEREO_SWING		(96*0x10000)
#define S_STEREO_SWING_HIGH	(96)

#define MAX_SOUND_VOLUME 127

#endif

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
//      System specific interface stuff.
//


#ifndef __I_SYSTEM__
#define __I_SYSTEM__

#include "d_ticcmd.h"
#include "d_event.h"
#include "sounds.h"


// Called by DoomMain.
void __near I_Init (void);

 
 
// Called by startup code
// to get the ammount of memory to malloc
// for the zone management.



 
//
// Called by D_DoomLoop,
// called before processing each tic in a frame.
// Quick syncronous operations are performed here.
// Can call D_PostEvent.
void __near I_StartTic (void);

// Asynchronous interrupt functions should maintain private queues
// that are read by the synchronous functions
// to be converted into events.



// Called by M_Responder when quit is selected.
// Clean exit, displays sell blurb.
void __near I_Quit (void);


void __far I_Error (int8_t __far *error, ...);

void __far I_BeginRead(void);
void __far I_EndRead(void);

//
//  MUSIC I/O
//

//int16_t I_LoadSong(uint16_t lump);
// called by anything that wants to register a song lump with the sound lib
// calls Paul's function of the similar name to register music only.
// note that the song data is the same for any sound card and is paul's
// MUS format.  Returns a handle which will be passed to all other music
// functions.

// called by anything that wishes to start music.
// plays a song, and when the song is done, starts playing it again in
// an endless loop.  the start is faded in over three seconds.

// called by anything that wishes to stop music.
// stops a song abruptly.
void I_ResumeSong();
void I_PauseSong();
void I_ResumeSong();

//  SFX I/O
//
typedef uint8_t sfxenum_t;


int16_t I_GetSfxLumpNum(sfxenum_t sfx);
// called by routines which wish to play a sound effect at some later
// time.  Pass it the lump name of a sound effect WITHOUT the sfx
// prefix.  This means the maximum name length is 7 letters/digits.
// The prefixes for different sound cards are 'S','M','A', and 'P'.
// They refer to the card type.  The routine will cache in the
// appropriate sound effect when it is played.

int16_t I_StartSound (sfxenum_t id, uint8_t vol, uint8_t sep, uint8_t pitch, uint8_t priority);
// Starts a sound in a particular sound channel

void I_UpdateSoundParams(int16_t handle, uint8_t vol, uint8_t sep, uint8_t pitch);
// Updates the volume, separation, and pitch of a sound channel

void I_StopSound(int16_t handle);
// Stops a sound channel

boolean I_SoundIsPlaying(int16_t handle);
// called by S_*()'s to see if a channel is still playing.  Returns 0
// if no longer playing, 1 if playing.





// Takes full 8 bit values.
void __near I_SetPalette(int8_t paletteNumber);

// Wait for vertical retrace or pause a bit.
void __near I_WaitVBL(int16_t count);

void __far I_BeginRead(void);
void __far I_EndRead(void);



#endif

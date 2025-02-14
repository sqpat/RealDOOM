//
// Copyright (C) 1993-1996 id Software, Inc.
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

#ifndef __I_SOUND__
#define __I_SOUND__

#define SND_TICRATE     140     // tic rate for updating sound
#define SND_MAXSONGS    40      // max number of songs in game
#define SND_SAMPLERATE  11025   // sample rate of sound effects



#define snd_none 0
#define snd_PC 1
#define snd_Adlib 2
#define snd_SB 3
#define snd_PAS 4
#define snd_GUS 5
#define snd_MPU 6
#define snd_MPU2 7
#define snd_MPU3 8
#define snd_AWE 9
#define snd_ENSONIQ 10
#define snd_CODEC 11
#define NUM_SCARDS 12
typedef uint8_t cardenum_t;

#endif

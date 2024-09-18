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
//	Main loop menu stuff.
//	Default Config File.
//

#include <fcntl.h>
#include <stdlib.h>

#include <ctype.h>


#include "doomdef.h"

#include "z_zone.h"

#include "w_wad.h"

#include "i_system.h"
#include "v_video.h"

#include "hu_stuff.h"

// State.
#include "doomstat.h"

// Data.
#include "dstrings.h"

#include "m_misc.h"
#include "m_memory.h"


int16_t		myargc;
int8_t**		myargv;

 

//
// M_Random
// Returns a 0-255 number
//

int16_t	rndindex = 0;
int16_t	prndindex = 0;



uint8_t __far M_Random (void){
    rndindex = (rndindex+1)&0xff;
    return rndtable[rndindex];
}


 

void M_AddToBox16 ( int16_t __near*	box, int16_t	x, int16_t	y ) {
    if (x<box[BOXLEFT])
		box[BOXLEFT] = x;
    else if (x>box[BOXRIGHT])
		box[BOXRIGHT] = x;
    if (y<box[BOXBOTTOM])
		box[BOXBOTTOM] = y;
    else if (y>box[BOXTOP])
		box[BOXTOP] = y;
}
 
 
//
// M_WriteFile
//
#ifndef O_BINARY
#define O_BINARY 0
#endif

boolean M_WriteFile (int8_t const*	name, void __far*		source, filelength_t		length ){
    filehandle_t		handle;
    filelength_t		count;
	
    FILE* fp = fopen ( name, "wb");

    if (!fp)
	    return false;

	//todo 
     //count = FAR_fwrite (source, 1, length, fp);
    fclose (fp);
	
    if (count < length)
	    return false;
		
    return true;
}


//
// M_ReadFile
//

/*
filelength_t
M_ReadFile
(int8_t const*	name,
  byte __far*	bufferRef ){
    filelength_t count, length;
	filehandle_t handle;
    struct stat	fileinfo;
    byte		__far *buf;
	
    handle = open (name, O_RDONLY | O_BINARY, 0666);
#ifdef CHECK_FOR_ERRORS

	if (handle == -1)
		I_Error ("Couldn't read file %s", name);
#endif
	if (fstat (handle,&fileinfo) == -1)
		I_Error ("Couldn't read file %s", name);
    length = fileinfo.st_size;
    *bufferRef = Z_MallocEMS (length, PU_STATIC, 1);
	buf = Z_LoadBytesFromEMS(*bufferRef);
    count = read (handle, buf, length);
    close (handle);
#ifdef CHECK_FOR_ERRORS
    if (count < length)
		I_Error ("Couldn't read file %s", name);
#endif		
    //*buffer = buf;
    return length;
}
*/

//
// DEFAULTS
//
uint8_t		usemouse;

extern uint8_t	key_right;
extern uint8_t	key_left;
extern uint8_t	key_up;
extern uint8_t	key_down;

extern uint8_t	key_strafeleft;
extern uint8_t	key_straferight;

extern uint8_t	key_fire;
extern uint8_t	key_use;
extern uint8_t	key_strafe;
extern uint8_t	key_speed;

extern uint8_t	mousebfire;
extern uint8_t	mousebstrafe;
extern uint8_t	mousebforward;

extern uint8_t	mouseSensitivity;
extern uint8_t	showMessages;

extern uint8_t	detailLevel;

extern uint8_t	screenblocks;


// machine-independent sound params
extern	uint8_t	numChannels;

extern uint8_t sfxVolume;
extern uint8_t musicVolume;
extern uint8_t snd_SBport8bit, snd_SBirq, snd_SBdma;
extern uint8_t snd_Mport8bit;


 

#define SC_UPARROW              0x48
#define SC_DOWNARROW            0x50
#define SC_LEFTARROW            0x4b
#define SC_RIGHTARROW           0x4d
#define SC_RCTRL                0x1d
#define SC_RALT                 0x38
#define SC_RSHIFT               0x36
#define SC_SPACE                0x39
#define SC_COMMA                0x33
#define SC_PERIOD               0x34
#define SC_PAGEUP               0x49
#define SC_INSERT               0x52
#define SC_HOME                 0x47
#define SC_PAGEDOWN             0x51
#define SC_DELETE               0x53
#define SC_END                  0x4f
#define SC_ENTER                0x1c

#define SC_KEY_A                0x1e
#define SC_KEY_B                0x30
#define SC_KEY_C                0x2e
#define SC_KEY_D                0x20
#define SC_KEY_E                0x12
#define SC_KEY_F                0x21
#define SC_KEY_G                0x22
#define SC_KEY_H                0x23
#define SC_KEY_I                0x17
#define SC_KEY_J                0x24
#define SC_KEY_K                0x25
#define SC_KEY_L                0x26
#define SC_KEY_M                0x32
#define SC_KEY_N                0x31
#define SC_KEY_O                0x18
#define SC_KEY_P                0x19
#define SC_KEY_Q                0x10
#define SC_KEY_R                0x13
#define SC_KEY_S                0x1f
#define SC_KEY_T                0x14
#define SC_KEY_U                0x16
#define SC_KEY_V                0x2f
#define SC_KEY_W                0x11
#define SC_KEY_X                0x2d
#define SC_KEY_Y                0x15
#define SC_KEY_Z                0x2c
#define SC_BACKSPACE            0x0e

default_t	defaults[28] ={
    {"mouse_sensitivity",&mouseSensitivity, 5},
    {"sfx_volume",&sfxVolume, 8},
    {"music_volume",&musicVolume, 8},
    {"show_messages",&showMessages, 1},
    
    {"key_right",&key_right, SC_RIGHTARROW, 1},
    {"key_left",&key_left, SC_LEFTARROW, 1},
    {"key_up",&key_up, SC_UPARROW, 1},
    {"key_down",&key_down, SC_DOWNARROW, 1},
    {"key_strafeleft",&key_strafeleft, SC_COMMA, 1},
    {"key_straferight",&key_straferight, SC_PERIOD, 1},

    {"key_fire",&key_fire, SC_RCTRL, 1},
    {"key_use",&key_use, SC_SPACE, 1},
    {"key_strafe",&key_strafe, SC_RALT, 1},
    {"key_speed",&key_speed, SC_RSHIFT, 1},

    {"use_mouse",&usemouse, 0},
    {"mouseb_fire",&mousebfire,0},
    {"mouseb_strafe",&mousebstrafe,1},
    {"mouseb_forward",&mousebforward,2},

    {"screenblocks",&screenblocks, 9},
    {"detaillevel",&detailLevel, 0},

    {"snd_channels",&numChannels, 3},
    {"snd_musicdevice",&snd_DesiredMusicDevice, 0},
    {"snd_sfxdevice",&snd_DesiredSfxDevice, 0},
    {"snd_sbport",&snd_SBport8bit, 0x22}, // must be shifted one...
    {"snd_sbirq",&snd_SBirq, 5},
    {"snd_sbdma",&snd_SBdma, 1},
    {"snd_mport",&snd_Mport8bit, 0x33},  // must be shifted one..

    {"usegamma",&usegamma, 0}
	 

};

int8_t*	defaultfile;






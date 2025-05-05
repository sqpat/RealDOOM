//
// Copyright (C) 2015 Alexey Khokholov (Nuke.YKT)
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

#ifndef _DMX_H_
#define _DMX_H_

#include "doomtype.h"


/*
void StartTimer(void(*function)(void));
void StopTimer(void);
*/

typedef struct task{
	volatile int8_t count;
	int8_t active;
} task;

typedef uint8_t sfxenum_t;


void TS_ScheduleMainTask();
void TS_Dispatch(void);
void TS_SetTaskRate(task *Task, uint16_t rate);

int8_t SFX_PlayPatch(sfxenum_t sfx_id, uint8_t sep, uint8_t vol);
void SFX_StopPatch(int8_t handle);
boolean SFX_Playing(int8_t handle);
void SFX_SetOrigin(int8_t handle, uint8_t sep, uint8_t vol);



#define AHW_PC_SPEAKER 1
#define AHW_ADLIB 2
#define AHW_AWE32 4
#define AHW_SOUND_BLASTER 8
#define AHW_MPU_401 16
#define AHW_ULTRA_SOUND 32
#define AHW_MEDIA_VISION 64
#define AHW_ENSONIQ 256
#define AHW_CODEC 512

#endif

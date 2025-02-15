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


void TS_ScheduleMainTask();
void TS_Dispatch(void);
void TS_SetTaskRate(task *Task, uint16_t rate);

void MUS_PauseSong(int16_t handle);
void MUS_ResumeSong(int16_t handle);
void MUS_SetMasterVolume(int16_t volume);
int16_t MUS_PlaySong(int16_t handle, int16_t volume);
int16_t SFX_PlayPatch(void __far*vdata, int16_t pitch, int16_t sep, int16_t vol, int16_t unk1, int16_t unk2);
void SFX_StopPatch(int16_t handle);
int16_t SFX_Playing(int16_t handle);
void SFX_SetOrigin(int16_t handle, int16_t  pitch, int16_t sep, int16_t vol);



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

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

typedef struct task
{
	struct task *next;
	struct task *prev;
	void(*TaskService)(void);
	uint16_t rate;
	volatile long count;
	int priority;
	int active;
} task;


void TS_Shutdown(void);
void TS_ScheduleTask(void(*Function)(void ), uint16_t rate);
void TS_Terminate();
void TS_Dispatch(void);
void TS_SetTaskRate(task *Task, uint16_t rate);

void MUS_PauseSong(int32_t handle);
void MUS_ResumeSong(int32_t handle);
void MUS_SetMasterVolume(int32_t volume);
int32_t MUS_RegisterSong(void __far*data);
int32_t MUS_UnregisterSong(int32_t handle);
int32_t MUS_QrySongPlaying(int32_t handle);
int32_t MUS_StopSong(int32_t handle);
int32_t MUS_ChainSong(int32_t handle, int32_t next);
int32_t MUS_PlaySong(int32_t handle, int32_t volume);
int32_t SFX_PlayPatch(void __far*vdata, int32_t pitch, int32_t sep, int32_t vol, int32_t unk1, int32_t unk2);
void SFX_StopPatch(int32_t handle);
int32_t SFX_Playing(int32_t handle);
void SFX_SetOrigin(int32_t handle, int32_t  pitch, int32_t sep, int32_t vol);
int32_t GF1_Detect(void);
void GF1_SetMap(void __far*data, int32_t len);
int32_t SB_Detect(int32_t *port, int32_t *irq, int32_t *dma, int32_t *unk);
void SB_SetCard(int32_t port, int32_t irq, int32_t dma);
int32_t AL_Detect(int32_t *port, int32_t *unk);
void AL_SetCard(int32_t port, void __far*data);
int32_t MPU_Detect(int32_t *port, int32_t *unk);
void MPU_SetCard(int32_t port);
int32_t DMX_Init(int32_t rate, int32_t maxsng, int32_t mdev, int32_t sdev);
void DMX_DeInit(void);
void WAV_PlayMode(int32_t channels, int32_t samplerate);
int32_t CODEC_Detect(int32_t *a, int32_t *b);
int32_t ENS_Detect(void);


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

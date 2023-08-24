//
// Copyright (C) 2015-2017 Alexey Khokholov (Nuke.YKT)
// Copyright (C) 2005-2014 Simon Howard
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

#include "dmx.h"
#include <stdio.h>
#include <stdlib.h>
#include "doomdef.h"
#include "task_man.h"
  



int(*tsm_func)(void);
task *tsm_task = NULL;

void tsm_funch() {
    tsm_func();
}

int dmx_mus_port = 0;

int TSM_NewService(int(*function)(void), int rate, int unk1, int unk2) {
    tsm_func = function;
    tsm_task = TS_ScheduleTask(tsm_funch, rate, 1, NULL);
    TS_Dispatch();
    return 0;
}
void TSM_DelService(int unk1) {
    if (tsm_task) {
        TS_Terminate(tsm_task);
    }
    tsm_task = NULL;
}
void TSM_Remove(void) {
    TS_Shutdown();
}   

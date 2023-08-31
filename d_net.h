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
//	Networking stuff.
//

#ifndef __D_NET__
#define __D_NET__

#include "d_player.h"


//
// Network play related stuff.
// There is a data struct that stores network
//  communication related stuff, and another
//  one that defines the actual packets to
//  be transmitted.
//

#define DOOMCOM_ID		0x12345678l



// Networking and tick handling related.
#define BACKUPTICS		16

typedef enum
{
    CMD_SEND	= 1,
    CMD_GET	= 2

} command_t;


//
// Network packet data.
//
typedef struct
{
 
    
    byte		starttic;
    byte		numtics;
    ticcmd_t		cmds[BACKUPTICS];

} doomdata_t;




typedef struct
{
    // Supposed to be DOOMCOM_ID?
    int32_t		id;
    
    // DOOM executes an int to execute commands.
    int16_t		intnum;		
    // Communication between DOOM and the driver.
    // Is CMD_SEND or CMD_GET.
    int16_t		command;
    // Is dest for send, set by get (-1 = no packet).
    int16_t		remotenode;
    
    // Number of bytes in doomdata to be sent
    int16_t		datalength;

    // Info common to all nodes.
    // Console is allways node 0.
    int16_t		numnodes;
    // Flag: 1 = no duplication, 2-5 = dup for slow nets.
    int16_t		ticdup;
    // Flag: 1 = send a backup tic in every packet.
    int16_t		extratics;
    int16_t		deathmatch;
    // Flag: -1 = new game, 0-5 = load savegame
    int16_t		savegame;
    int16_t		episode;	// 1-3
    int16_t		map;		// 1-9
    int16_t		skill;		// 1-5

    // Info specific to this node.
    int16_t		consoleplayer;
    int16_t		numplayers;
    
    // These are related to the 3-display mode,
    //  in which two drones looking left and right
    //  were used to render two additional views
    //  on two additional computers.
    // Probably not operational anymore.
    // 1 = left, 0 = center, -1 = right
    int16_t		angleoffset;
    // 1 = drone
    int16_t		drone;		

    // The packet data to be sent.
    doomdata_t		data;
    
} doomcom_t;



// Create any new ticcmds and broadcast to other players.
void NetUpdate (void);

// Broadcasts special packets to other players
//  to notify of game exit
void D_QuitNetGame (void);

//? how many ticks to run?
void TryRunTics (void);


#endif

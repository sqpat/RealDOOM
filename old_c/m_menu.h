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
//   Menu widget stuff, episode selection and such.
//

#ifndef __M_MENU__
#define __M_MENU__



#include "doomdef.h"

//
// MENUS
//
// Called by main loop,
// saves config file and calls I_Quit when user exits.
// Even when the menu is not displayed,
// this can resize the view and change game parameters.
// Does all the real work of the menu interaction.


// Called by main loop,
// only used for menu (skull cursor) animation.
void __near M_Ticker (void);

// Called by main loop,
// draws the menus directly into the screen buffer.

// Called by intro code to force menu up upon a keypress,
// does nothing if menu is already up.

//
// DOOM MENU
//
typedef enum main_e{
	newgame = 0,
	options,
	loadgame,
	savegame,
	readthis,
	quitdoom,
	main_end
} main_e;





//
// MENU TYPEDEFS
//
typedef struct{
	// 0 = no cursor here, 1 = ok, 2 = arrows ok
	int8_t       status;

	int8_t        name;

	// choice = menu item #.
	// if status = 2,
	//   choice=0:leftarrow,1:rightarrow
	void __near (*routine)(int16_t choice);

	// hotkey in menu
	int8_t        alphaKey;
} menuitem_t;



typedef struct menu_s{
	int8_t               numitems;       // # of menu items
	struct menu_s __near*      prevMenu;       // previous menu
	menuitem_t __near*         menuitems;      // menu items
	void __near (*routine)();   // draw routine
	int16_t               x;
	uint8_t               y;              // x,y of menu
	int16_t               lastOn;         // last item user was on in menu
} menu_t;

 

#define MENUPATCH_M_DOOM      0
#define MENUPATCH_M_RDTHIS    1
#define MENUPATCH_M_OPTION    2
#define MENUPATCH_M_QUITG     3
#define MENUPATCH_M_NGAME     4
#define MENUPATCH_M_SKULL1    5
#define MENUPATCH_M_SKULL2    6
#define MENUPATCH_M_THERMO    7
#define MENUPATCH_M_THERMR    8
#define MENUPATCH_M_THERMM    9
#define MENUPATCH_M_THERML    10
#define MENUPATCH_M_ENDGAM    11
#define MENUPATCH_M_PAUSE     12
#define MENUPATCH_M_MESSG     13
#define MENUPATCH_M_MSGON     14
#define MENUPATCH_M_MSGOFF    15
#define MENUPATCH_M_EPISOD    16
#define MENUPATCH_M_EPI1      17
#define MENUPATCH_M_EPI2      18
#define MENUPATCH_M_EPI3      19
#define MENUPATCH_M_HURT      20
#define MENUPATCH_M_JKILL     21
#define MENUPATCH_M_ROUGH     22
#define MENUPATCH_M_SKILL     23
#define MENUPATCH_M_NEWG      24
#define MENUPATCH_M_ULTRA     25
#define MENUPATCH_M_NMARE     26
#define MENUPATCH_M_GDHIGH    27
#define MENUPATCH_M_GDLOW     28
#define MENUPATCH_M_LSLEFT    29
#define MENUPATCH_M_SVOL      30
#define MENUPATCH_M_OPTTTL    31
#define MENUPATCH_M_SAVEG     32
#define MENUPATCH_M_LOADG     33
#define MENUPATCH_M_DISP      34
#define MENUPATCH_M_MSENS     35
#define MENUPATCH_M_DETAIL    36
#define MENUPATCH_M_DISOPT    37
#define MENUPATCH_M_SCRNSZ    38
#define MENUPATCH_M_SGTTL     39
#define MENUPATCH_M_LGTTL     40
#define MENUPATCH_M_SFXVOL    41
#define MENUPATCH_M_MUSVOL    42
#define MENUPATCH_M_LSCNTR    43
#define MENUPATCH_M_LSRGHT    44
#define MENUPATCH_M_EPI4      45

#endif    

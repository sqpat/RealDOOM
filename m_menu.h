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



#include "d_event.h"

//
// MENUS
//
// Called by main loop,
// saves config file and calls I_Quit when user exits.
// Even when the menu is not displayed,
// this can resize the view and change game parameters.
// Does all the real work of the menu interaction.
boolean M_Responder (event_t far* ev);


// Called by main loop,
// only used for menu (skull cursor) animation.
void M_Ticker (void);

// Called by main loop,
// draws the menus directly into the screen buffer.
void M_Drawer (void);


// Called by intro code to force menu up upon a keypress,
// does nothing if menu is already up.
void M_StartControlPanel (void);

//
// DOOM MENU
//
typedef enum main_e
{
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
typedef struct
{
	// 0 = no cursor here, 1 = ok, 2 = arrows ok
	int8_t       status;

	int8_t        name;

	// choice = menu item #.
	// if status = 2,
	//   choice=0:leftarrow,1:rightarrow
	void(*routine)(int16_t choice);

	// hotkey in menu
	int8_t        alphaKey;
} menuitem_t;



typedef struct menu_s
{
	int8_t               numitems;       // # of menu items
	struct menu_s near*      prevMenu;       // previous menu
	menuitem_t near*         menuitems;      // menu items
	void(*routine)();   // draw routine
	int16_t               x;
	uint8_t               y;              // x,y of menu
	int16_t               lastOn;         // last item user was on in menu
} menu_t;



#endif    

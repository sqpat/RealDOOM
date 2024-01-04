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
//	Switches, buttons. Two-state animation. Exits.
//


#include "i_system.h"
#include "doomdef.h"
#include "p_local.h"

#include "g_game.h"

#include "s_sound.h"

// Data.
#include "sounds.h"

// State.
#include "doomstat.h"
#include "r_state.h"

uint8_t		switchlist[MAXSWITCHES * 2];
int16_t		numswitches;
button_t        buttonlist[MAXBUTTONS];

//
// Start a button counting down till it turns off.
//
void
P_StartButton
( int16_t linenum,
	int16_t linefrontsecnum,
  bwhere_e	w,
  int16_t		texture,
  int16_t		time )
{
    int8_t		i;
    // See if button is already pressed
    for (i = 0;i < MAXBUTTONS;i++)
    {
	if (buttonlist[i].btimer
	    && buttonlist[i].linenum == linenum)
	{
	    
	    return;
	}
    }
    

    for (i = 0;i < MAXBUTTONS;i++)
    {
	if (!buttonlist[i].btimer)
	{
	    buttonlist[i].linenum = linenum;
	    buttonlist[i].where = w;
	    buttonlist[i].btexture = texture;
	    buttonlist[i].btimer = time;
		buttonlist[i].soundorgX = sectors_physics[linefrontsecnum].soundorgX;
		buttonlist[i].soundorgY = sectors_physics[linefrontsecnum].soundorgY;
		return;
	}
    }
    
#ifdef CHECK_FOR_ERRORS
	I_Error("P_StartButton: no button slots left!");
#endif
}





//
// Function that changes wall texture.
// Tell it if switch is ok to use again (1=yes, it's a button).
//
void
P_ChangeSwitchTexture
( int16_t linenum, int16_t lineside0, uint8_t linespecial, int16_t linefrontsecnum,
	int16_t 		useAgain )
{
	uint8_t     texTop;
	uint8_t     texMid;
	uint8_t     texBot;
	int8_t     i;
	int16_t     sound;

	line_physics_t* line_physics;

	if (!useAgain) {
		line_physics = &lines_physics[linenum];
		line_physics->special = 0;
	}
	
    texTop = sides[lineside0].toptexture;
    texMid = sides[lineside0].midtexture;
    texBot = sides[lineside0].bottomtexture;
	
    sound = sfx_swtchn;

    // EXIT SWITCH?
    if (linespecial == 11)                
		sound = sfx_swtchx;
	
    for (i = 0;i < numswitches*2;i++) {
		if (switchlist[i] == texTop) {
			S_StartSoundWithParams(buttonlist->soundorgX, buttonlist->soundorgY, sound);
			sides[lineside0].toptexture = switchlist[i^1];

			if (useAgain) {
				P_StartButton(linenum, linefrontsecnum, top, switchlist[i], BUTTONTIME);
			}
			return;
		}
		else {
			if (switchlist[i] == texMid) {
				S_StartSoundWithParams(buttonlist->soundorgX, buttonlist->soundorgY, sound);
				sides[lineside0].midtexture = switchlist[i^1];

				if (useAgain) {
					P_StartButton(linenum, linefrontsecnum, middle, switchlist[i], BUTTONTIME);
				}

			return;
			
			} else {
				if (switchlist[i] == texBot) {
					S_StartSoundWithParams(buttonlist->soundorgX, buttonlist->soundorgY, sound);
					sides[lineside0].bottomtexture = switchlist[i^1];

					if (useAgain) {
						P_StartButton(linenum, linefrontsecnum, bottom, switchlist[i], BUTTONTIME);
					}
					return;
				}
			}
		}
    }
}






//
// P_UseSpecialLine
// Called when a thing uses a special line.
// Only the front sides of lines are usable.
//
boolean
P_UseSpecialLine
( mobj_t*	thing,
  int16_t linenum,
  int16_t		side,
	THINKERREF thingRef)
{               

	line_t* line = &lines[linenum];
	line_physics_t* line_physics = &lines_physics[linenum];

	uint8_t linetag = line_physics->tag;
	uint8_t linespecial = line_physics->special;
	uint8_t lineflags = line->flags;
	int16_t linefrontsecnum = line_physics->frontsecnum;
	int16_t lineside0 = line->sidenum[0];
 
    // Err...
    // Use the back sides of VERY SPECIAL lines...
    if (side)
    {
	switch(linespecial)
	{

	  default:
	    return false;
	    break;
	}
    }



    
    // Switches that other things can activate.
    if (thingRef != playerMobjRef) {
		// never open secret doors
		if (lineflags & ML_SECRET)
			return false;
	
		switch(linespecial) {
		  case 1: 	// MANUAL DOOR RAISE
		  case 32:	// MANUAL BLUE
		  case 33:	// MANUAL RED
		  case 34:	// MANUAL YELLOW
			break;
	    
		  default:
			return false;
			break;
		}
    }

    
    // do something  
    switch (linespecial) {
	// MANUALS
      case 1:		// Vertical Door
      case 26:		// Blue Door/Locked
      case 27:		// Yellow Door /Locked
      case 28:		// Red Door /Locked

      case 31:		// Manual door open
      case 32:		// Blue locked door open
      case 33:		// Red locked door open
      case 34:		// Yellow locked door open

      case 117:		// Blazing door raise
      case 118:		// Blazing door open

		 

		  EV_VerticalDoor (linenum, thingRef);
	break;
	

	// SWITCHES
		case 7:
	// Build Stairs
			if (EV_BuildStairs(linetag, build8)) {
				P_ChangeSwitchTexture(linenum, lineside0, linespecial, linefrontsecnum, 0);
			}
			break;

		case 9:
		// Change Donut
			if (EV_DoDonut(linetag)) {
				P_ChangeSwitchTexture(linenum, lineside0, linespecial, linefrontsecnum, 0);
			}
			break;
	
		case 11:
			// Exit level
			P_ChangeSwitchTexture(linenum, lineside0, linespecial, linefrontsecnum, 0);
			G_ExitLevel ();
			break;
	
		case 14:
			// Raise Floor 32 and change texture
			if (EV_DoPlat(linetag, linefrontsecnum, raiseAndChange, 32)) {
				P_ChangeSwitchTexture(linenum, lineside0, linespecial, linefrontsecnum, 0);
			}
			break;
	
      case 15:
	// Raise Floor 24 and change texture
		  if (EV_DoPlat(linetag, linefrontsecnum, raiseAndChange,24))
			  P_ChangeSwitchTexture(linenum, lineside0, linespecial, linefrontsecnum, 0);
	break;
	
      case 18:
	// Raise Floor to next highest floor
		  if (EV_DoFloor(linetag, linefrontsecnum, raiseFloorToNearest))
			  P_ChangeSwitchTexture(linenum, lineside0, linespecial, linefrontsecnum, 0);
	break;
	
      case 20:
	// Raise Plat next highest floor and change texture
	if (EV_DoPlat(linetag, linefrontsecnum, raiseToNearestAndChange,0))
		P_ChangeSwitchTexture(linenum, lineside0, linespecial, linefrontsecnum, 0);
	break;
	
      case 21:
	// PlatDownWaitUpStay
		  if (EV_DoPlat(linetag, linefrontsecnum, downWaitUpStay,0))
			  P_ChangeSwitchTexture(linenum, lineside0, linespecial, linefrontsecnum, 0);
	break;
	
      case 23:
	// Lower Floor to Lowest
		  if (EV_DoFloor(linetag, linefrontsecnum, lowerFloorToLowest))
			  P_ChangeSwitchTexture(linenum, lineside0, linespecial, linefrontsecnum, 0);
	break;
	
      case 29:
	// Raise Door
		  if (EV_DoDoor(linetag, normal))
			  P_ChangeSwitchTexture(linenum, lineside0, linespecial, linefrontsecnum, 0);
	break;
	
      case 41:
	// Lower Ceiling to Floor
	if (EV_DoCeiling(linetag,lowerToFloor))
		P_ChangeSwitchTexture(linenum, lineside0, linespecial, linefrontsecnum, 0);
	break;
	
      case 71:
	// Turbo Lower Floor
		  if (EV_DoFloor(linetag, linefrontsecnum, turboLower))
			  P_ChangeSwitchTexture(linenum, lineside0, linespecial, linefrontsecnum, 0);
	break;
	
      case 49:
	// Ceiling Crush And Raise
	if (EV_DoCeiling(linetag,crushAndRaise))
		P_ChangeSwitchTexture(linenum, lineside0, linespecial, linefrontsecnum, 0);
	break;
	
      case 50:
	// Close Door
	if (EV_DoDoor(linetag,close))
		P_ChangeSwitchTexture(linenum, lineside0, linespecial, linefrontsecnum, 0);
	break;
	
      case 51:
	// Secret EXIT
		  P_ChangeSwitchTexture(linenum, lineside0, linespecial, linefrontsecnum, 0);
	G_SecretExitLevel ();
	break;
	
      case 55:
	// Raise Floor Crush
		  if (EV_DoFloor(linetag, linefrontsecnum, raiseFloorCrush))
			  P_ChangeSwitchTexture(linenum, lineside0, linespecial, linefrontsecnum, 0);
	break;
	
      case 101:
	// Raise Floor
		  if (EV_DoFloor(linetag, linefrontsecnum, raiseFloor))
			  P_ChangeSwitchTexture(linenum, lineside0, linespecial, linefrontsecnum, 0);
	break;
	
      case 102:
	// Lower Floor to Surrounding floor height
		  if (EV_DoFloor(linetag, linefrontsecnum, lowerFloor))
			  P_ChangeSwitchTexture(linenum, lineside0, linespecial, linefrontsecnum, 0);
	break;
	
      case 103:
	// Open Door
		  if (EV_DoDoor(linetag, open))
			  P_ChangeSwitchTexture(linenum, lineside0, linespecial, linefrontsecnum, 0);
	break;
	
      case 111:
	// Blazing Door Raise (faster than TURBO!)
		  if (EV_DoDoor(linetag, blazeRaise))
			  P_ChangeSwitchTexture(linenum, lineside0, linespecial, linefrontsecnum, 0);
	break;
	
      case 112:
	// Blazing Door Open (faster than TURBO!)
		  if (EV_DoDoor(linetag, blazeOpen))
			  P_ChangeSwitchTexture(linenum, lineside0, linespecial, linefrontsecnum, 0);
	break;
	
      case 113:
	// Blazing Door Close (faster than TURBO!)
		  if (EV_DoDoor(linetag, blazeClose))
			  P_ChangeSwitchTexture(linenum, lineside0, linespecial, linefrontsecnum, 0);
	break;
	
      case 122:
	// Blazing PlatDownWaitUpStay
		  if (EV_DoPlat(linetag, linefrontsecnum, blazeDWUS,0))
			  P_ChangeSwitchTexture(linenum, lineside0, linespecial, linefrontsecnum, 0);
	break;
	
      case 127:
	// Build Stairs Turbo 16
	if (EV_BuildStairs(linetag,turbo16))
		P_ChangeSwitchTexture(linenum, lineside0, linespecial, linefrontsecnum, 0);
	break;
	
      case 131:
	// Raise Floor Turbo
		  if (EV_DoFloor(linetag, linefrontsecnum, raiseFloorTurbo))
			  P_ChangeSwitchTexture(linenum, lineside0, linespecial, linefrontsecnum, 0);
	break;
	
      case 133:
	// BlzOpenDoor BLUE
      case 135:
	// BlzOpenDoor RED
      case 137:
	// BlzOpenDoor YELLOW
	if (EV_DoLockedDoor (linetag, linespecial,blazeOpen,thingRef))
		P_ChangeSwitchTexture(linenum, lineside0, linespecial, linefrontsecnum, 0);
	break;
	
      case 140:
	// Raise Floor 512
		  if (EV_DoFloor(linetag, linefrontsecnum, raiseFloor512))
			  P_ChangeSwitchTexture(linenum, lineside0, linespecial, linefrontsecnum, 0);
	break;
	
	// BUTTONS
      case 42:
	// Close Door
		  if (EV_DoDoor(linetag, close))
			  P_ChangeSwitchTexture(linenum, lineside0, linespecial, linefrontsecnum, 1);
	break;
	
      case 43:
	// Lower Ceiling to Floor
		if (EV_DoCeiling(linetag,lowerToFloor))
			P_ChangeSwitchTexture(linenum, lineside0, linespecial, linefrontsecnum, 1);
	break;
	
      case 45:
	// Lower Floor to Surrounding floor height
		  if (EV_DoFloor(linetag, linefrontsecnum, lowerFloor))
			  P_ChangeSwitchTexture(linenum, lineside0, linespecial, linefrontsecnum, 1);
	break;
	
      case 60:
	// Lower Floor to Lowest
		  if (EV_DoFloor(linetag, linefrontsecnum, lowerFloorToLowest))
			  P_ChangeSwitchTexture(linenum, lineside0, linespecial, linefrontsecnum, 1);
	break;
	
      case 61:
	// Open Door
		if (EV_DoDoor(linetag,open))
			P_ChangeSwitchTexture(linenum, lineside0, linespecial, linefrontsecnum, 1);
	break;
	
      case 62:
	// PlatDownWaitUpStay
		  if (EV_DoPlat(linetag, linefrontsecnum, downWaitUpStay,1))
			  P_ChangeSwitchTexture(linenum, lineside0, linespecial, linefrontsecnum, 1);
	break;
	
      case 63:
	// Raise Door
		if (EV_DoDoor(linetag,normal))
			P_ChangeSwitchTexture(linenum, lineside0, linespecial, linefrontsecnum, 1);
	break;
	
      case 64:
	// Raise Floor to ceiling
		  if (EV_DoFloor(linetag, linefrontsecnum, raiseFloor))
			  P_ChangeSwitchTexture(linenum, lineside0, linespecial, linefrontsecnum, 1);
	break;
	
      case 66:
	// Raise Floor 24 and change texture
		  if (EV_DoPlat(linetag, linefrontsecnum, raiseAndChange,24))
			  P_ChangeSwitchTexture(linenum, lineside0, linespecial, linefrontsecnum, 1);
	break;
	
      case 67:
	// Raise Floor 32 and change texture
		  if (EV_DoPlat(linetag, linefrontsecnum, raiseAndChange,32))
			  P_ChangeSwitchTexture(linenum, lineside0, linespecial, linefrontsecnum, 1);
	break;
	
      case 65:
	// Raise Floor Crush
		  if (EV_DoFloor(linetag, linefrontsecnum, raiseFloorCrush))
			  P_ChangeSwitchTexture(linenum, lineside0, linespecial, linefrontsecnum, 1);
	break;
	
      case 68:
	// Raise Plat to next highest floor and change texture
		  if (EV_DoPlat(linetag, linefrontsecnum, raiseToNearestAndChange,0))
			  P_ChangeSwitchTexture(linenum, lineside0, linespecial, linefrontsecnum, 1);
	break;
	
      case 69:
	// Raise Floor to next highest floor
		  if (EV_DoFloor(linetag, linefrontsecnum, raiseFloorToNearest))
			  P_ChangeSwitchTexture(linenum, lineside0, linespecial, linefrontsecnum, 1);
	break;
	
      case 70:
	// Turbo Lower Floor
		  if (EV_DoFloor(linetag, linefrontsecnum, turboLower))
			  P_ChangeSwitchTexture(linenum, lineside0, linespecial, linefrontsecnum, 1);
	break;
	
      case 114:
	// Blazing Door Raise (faster than TURBO!)
		  if (EV_DoDoor(linetag, blazeRaise))
			  P_ChangeSwitchTexture(linenum, lineside0, linespecial, linefrontsecnum, 1);
	break;
	
      case 115:
	// Blazing Door Open (faster than TURBO!)
		  if (EV_DoDoor(linetag, blazeOpen))
			  P_ChangeSwitchTexture(linenum, lineside0, linespecial, linefrontsecnum, 1);
	break;
	
      case 116:
	// Blazing Door Close (faster than TURBO!)
	if (EV_DoDoor (linetag,blazeClose))
		P_ChangeSwitchTexture(linenum, lineside0, linespecial, linefrontsecnum, 1);
	break;
	
      case 123:
	// Blazing PlatDownWaitUpStay
		  if (EV_DoPlat(linetag, linefrontsecnum, blazeDWUS,0))
			  P_ChangeSwitchTexture(linenum, lineside0, linespecial, linefrontsecnum, 1);
	break;
	
      case 132:
	// Raise Floor Turbo
		  if (EV_DoFloor(linetag, linefrontsecnum, raiseFloorTurbo))
			  P_ChangeSwitchTexture(linenum, lineside0, linespecial, linefrontsecnum, 1);
	break;
	
      case 99:
	// BlzOpenDoor BLUE
      case 134:
	// BlzOpenDoor RED
      case 136:
	// BlzOpenDoor YELLOW
	if (EV_DoLockedDoor (linetag, linespecial,blazeOpen,thingRef))
		P_ChangeSwitchTexture(linenum, lineside0, linespecial, linefrontsecnum, 1);
	break;
	
      case 138:
	// Light Turn On
		  EV_LightTurnOn(linetag, 255);
		  P_ChangeSwitchTexture(linenum, lineside0, linespecial, linefrontsecnum, 1);
	break;
	
      case 139:
	// Light Turn Off
		  EV_LightTurnOn(linetag, 35);
		  P_ChangeSwitchTexture(linenum, lineside0, linespecial, linefrontsecnum, 1);
	break;
			
    }
	
    return true;
}


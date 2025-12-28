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
//

// ok in the final transition from c to asm, a lot of header files were removed and the necessary remaining constants are just shoved in here for now.
// this will soon be unnecessary... will just be gross for a bit.

#ifndef __CONSTANT__
#define __CONSTANT__
 
#define ev_keydown 0
#define ev_keyup 1
#define ev_mouse 2

#include "doomdef.h"
#include "d_englsh.h"



#define FINEANGLES		8192
#define FINEMASK		(FINEANGLES-1)

typedef fixed_t_union angle_t;

 



// 0x100000000 to 0x2000
#define ANGLETOFINESHIFT	19		
#define SHORTTOFINESHIFT	3		



// Binary Angle Measument, BAM.
#define ANG45			0x20000000u
#define ANG90			0x40000000u
#define ANG180			0x80000000u
#define ANG270			0xc0000000u

#define ANG45_HIGHBITS		0x2000u
#define ANG90_HIGHBITS		0x4000u
#define ANG180_HIGHBITS		0x8000u
#define ANG270_HIGHBITS		0xc000u

#define FINE_ANG45		0x400
#define FINE_ANG90	    0x800		    
#define FINE_ANG180		0x1000
#define FINE_ANG270		0x1800
#define FINE_ANG360		0x2000


#define FINE_ANG45_NOSHIFT		0x1000
#define FINE_ANG90_NOSHIFT	    0x2000		    
#define FINE_ANG180_NOSHIFT		0x4000
#define FINE_ANG270_NOSHIFT		0x6000
#define FINE_ANG360_NOSHIFT		0x8000


#define MOD_FINE_ANGLE(x)  ((x & 0x1FFF))
#define MOD_FINE_ANGLE_NOSHIFT(x)  ((x & 0x7FFF))

#define SLOPERANGE		2048
#define SLOPEBITS		11
#define DBITS			(FRACBITS-SLOPEBITS)


// Effective size is 10240.



// this one has no issues with mirroring 2nd half of values!

#define finetangent(x) (x < 2048 ? finetangentinner[x] : -(finetangentinner[(-x+4095)]) )



#include "p_mobj.h"

typedef uint8_t evtype_t;

// Event structure.
// todo 13 bytes gross. maybe re-align at least.
typedef struct {
    int16_t		data1;		// type high byte, keys / mouse buttons low byte
    int16_t		data2;		// mouse x move
} event_t;

 
#define ga_nothing	  0
#define ga_loadlevel  1
#define ga_newgame    2
#define ga_loadgame   3
#define ga_savegame   4
#define ga_playdemo   5
#define ga_completed  6
#define ga_victory    7
#define ga_worlddone  8

typedef uint8_t gameaction_t;



//
// Button/action code definitions.
//
// Press "Fire".
#define BT_ATTACK		 1
// Use button, to open doors, activate switches.
#define BT_USE		 2

// Flag: game events, not really buttons.
#define BT_SPECIAL		 128
#define BT_SPECIALMASK	 3
    
// Flag, weapon change pending.
// If true, the next 3 bits hold weapon num.
#define BT_CHANGE		 4
// The 3bit weapon mask and shift, convenience.
#define BT_WEAPONMASK	 (8+16+32)
#define BT_WEAPONSHIFT	 3

// Pause the game.
#define BTS_PAUSE		 1
// Save the game at each console.
#define BTS_SAVEGAME	 2

// Savegame slot numbers
//  occupy the second byte of buttons.    
#define BTS_SAVEMASK	 (4+8+16)
#define BTS_SAVESHIFT 	 2
  
typedef uint8_t buttoncode_t;




//
// GLOBAL VARIABLES
//



#define MAPBLOCKUNITS	128
#define MAPBLOCKSIZE MAPBLOCKUNITS
#define MAPBLOCKSHIFT	7
#define playerMobj_posMakerExpression	((&mobjposlist_6800[playerMobjRef]))
#define playerMobjMakerExpression		((mobj_t __near *) (((byte __far*)thinkerlist) + (playerMobjRef*sizeof(thinker_t) + 2 * sizeof(THINKERREF))))


typedef struct {
  int8_t prev;
  int8_t next;
  
  // 0 for single page allocations. for multipage, 1 is the the last page of multipage
  // allocation and count up prev from there. allows us to idenitify connected pages in the cache
  int8_t pagecount; 

  int8_t numpages; // number of the pages in a multi page allocation

} cache_node_page_count_t;

typedef struct {
  int8_t prev;
  int8_t next;
  
  // flats are never anything but single page..
} cache_node_t;

#define MAXRADIUS		32*FRACUNIT
#define MAXRADIUSNONFRAC		32



#define FLOATSPEED		(FRACUNIT*4)
#define FLOATSPEED_HIGHBITS	4


#define MAXHEALTH		100
#define VIEWHEIGHT		(41*FRACUNIT)
#define VIEWHEIGHT_HIGHBITS	41
#define MAXBOB_HIGHBITS	0x10


// mapblocks are used to check movement
// against lines and things
#define MAPBLOCKUNITS	128
#define MAPBLOCKSIZE MAPBLOCKUNITS
#define MAPBLOCKSHIFT	7


// player radius for movement checking
#define PLAYERRADIUS	16*FRACUNIT

// MAXRADIUS is for precalculated sector block boxes
// the spider demon is larger,
// but we do not have any moving sectors nearby
#define MAXRADIUS		32*FRACUNIT
#define MAXRADIUSNONFRAC		32

#define GRAVITY		FRACUNIT
#define GRAVITY_HIGHBITS		1
#define MAXMOVE		(30*FRACUNIT)
#define INVERSECOLORMAP		32


#define USERANGE         (64)
#define MELEERANGE       (64)
#define CHAINSAWRANGE	 (65)
#define MISSILERANGE     (32*64)
#define HALFMISSILERANGE (16*64)

// follow a player exlusively for 3 seconds
#define	BASETHRESHOLD	 	100



//
// P_TICK
//



#define TF_NULL				0
#define TF_MOBJTHINKER		1
#define TF_PLATRAISE        2
#define TF_MOVECEILING		3
#define TF_VERTICALDOOR		4
#define TF_MOVEFLOOR        5
#define TF_FIREFLICKER      6
#define TF_LIGHTFLASH       7
#define TF_STROBEFLASH      8
#define TF_GLOW             9

#define TF_DELETEME         10

#define TF_NULL_HIGHBITS			0
#define TF_MOBJTHINKER_HIGHBITS		2048u
#define TF_PLATRAISE_HIGHBITS       4096u
#define TF_MOVECEILING_HIGHBITS		6144u
#define TF_VERTICALDOOR_HIGHBITS	8192u
#define TF_MOVEFLOOR_HIGHBITS       10240u
#define TF_FIREFLICKER_HIGHBITS     12288u
#define TF_LIGHTFLASH_HIGHBITS      14336u
#define TF_STROBEFLASH_HIGHBITS     16384u
#define TF_GLOW_HIGHBITS            18432u
#define TF_DELETEME_HIGHBITS		20480u

#define TF_FUNCBITS					0xF800u
#define TF_PREVBITS					0x07FFu

// 44 in size
typedef struct thinker_s {

	// functiontype is the five high bits

	// contains previous reference mixed with functin type (in the high five bits)
	THINKERREF	prevFunctype;
	THINKERREF	next;

	mobj_t			data;

} thinker_t;






void __near* __far P_CreateThinker(uint16_t thinkfunc);

void __near P_UpdateThinkerFunc(THINKERREF thinker, uint16_t argfunc);
void __far  P_RemoveThinker(THINKERREF thinkerRef);

#define THINKER_SIZE sizeof(thinker_t)
#define GETTHINKERREF(a) ((((uint16_t)((byte __near*)a - (byte __near*)thinkerlist))-4)/THINKER_SIZE)
#define GET_MOBJPOS_FROM_MOBJ(a) &mobjposlist_6800[GETTHINKERREF(a)]






//
// P_USER
//
void	__near P_PlayerThink ();


//
// P_MOBJ
//
#define ONFLOORZ		MINLONG
#define ONCEILINGZ		MAXLONG

// Time interval for item respawning.

// THINKERREF __far P_SpawnMobj ( fixed_t	x, fixed_t	y, fixed_t	z, mobjtype_t	type,  int16_t knownsecnum );

// void 	__far P_RemoveMobj (mobj_t __near* mobj);

// boolean	__far P_SetMobjState(mobj_t __near* mobj, statenum_t state);
// void __near P_MobjThinker(mobj_t __near* mobj, mobj_pos_t __far* mobj_pos, THINKERREF mobjRef);

// todo re-enable

// #pragma aux P_SpawnPuffParams __parm [dx ax] [cx bx] [di si] __modify [ax bx cx dx si di];
// #pragma aux (P_SpawnPuffParams) P_SpawnPuff;
// void	__far P_SpawnPuff (fixed_t x, fixed_t y, fixed_t z);





//
// P_ENEMY
//
// void __near P_NoiseAlert ();


//
// P_MAPUTL
//
typedef struct {

	fixed_t_union	x;
	fixed_t_union	y;
    fixed_t_union	dx;
	fixed_t_union	dy;
    
} divline_t;

typedef struct {

    fixed_t	frac;		// along trace line
    boolean	isaline;    // todo put this after...
    union {
		THINKERREF	thingRef;
	int16_t linenum;
    }			d;
} intercept_t;

 

#define playerMobj_posMakerExpression	((&mobjposlist_6800[playerMobjRef]))
#define playerMobjMakerExpression		((mobj_t __near *) (((byte __far*)thinkerlist) + (playerMobjRef*sizeof(thinker_t) + 2 * sizeof(THINKERREF))))
    





#define PT_ADDLINES		1
#define PT_ADDTHINGS	2






// Bounding box coordinate storage.


#define    BOXTOP 0
#define    BOXBOTTOM 1
#define    BOXLEFT 2
#define    BOXRIGHT 3
 // bbox coordinates

 

#define NUM_DEFAULTS 31


typedef struct{
 int8_t  __near* name;
 uint8_t __near* location;
 uint8_t  defaultvalue;
 uint8_t  scantranslate;  // PC scan code hack
 uint8_t  untranslated;  // lousy hack
} default_t;




// Size of statusbar.
// Now sensitive for scaling.
#define ST_HEIGHT	32
#define ST_WIDTH	SCREENWIDTH
#define ST_Y		(SCREENHEIGHT - ST_HEIGHT)


//
// STATUS BAR
//

// Called by main loop.


// States for status bar code.
typedef enum {
    AutomapState,
    FirstPersonState
    
} st_stateenum_t;


 


//
// STATUS BAR DATA
//


// Palette indices.
// For damage/bonus red-/gold-shifts
#define STARTREDPALS            1
#define STARTBONUSPALS          9
#define NUMREDPALS                      8
#define NUMBONUSPALS            4
// Radiation suit, green shift.
#define RADIATIONPAL            13

// N/256*100% probability
//  that the normal face state will change
#define ST_FACEPROBABILITY              96


// Location of status bar
#define ST_X                            0
#define ST_X2                           104

#define ST_FX                   143
#define ST_FY                   169

// Should be set to patch width
//  for tall numbers later on

// Number of status faces.
#define ST_NUMPAINFACES         5
#define ST_NUMSTRAIGHTFACES     3
#define ST_NUMTURNFACES         2
#define ST_NUMSPECIALFACES              3

#define ST_FACESTRIDE \
          (ST_NUMSTRAIGHTFACES+ST_NUMTURNFACES+ST_NUMSPECIALFACES)

#define ST_NUMEXTRAFACES                2

#define ST_NUMFACES \
          (ST_FACESTRIDE*ST_NUMPAINFACES+ST_NUMEXTRAFACES)

#define ST_TURNOFFSET           (ST_NUMSTRAIGHTFACES)
#define ST_OUCHOFFSET           (ST_TURNOFFSET + ST_NUMTURNFACES)
#define ST_EVILGRINOFFSET               (ST_OUCHOFFSET + 1)
#define ST_RAMPAGEOFFSET                (ST_EVILGRINOFFSET + 1)
#define ST_GODFACE                      (ST_NUMPAINFACES*ST_FACESTRIDE)
#define ST_DEADFACE                     (ST_GODFACE+1)

#define ST_FACESX                       143
#define ST_FACESY                       168

#define ST_EVILGRINCOUNT                (2*TICRATE)
#define ST_STRAIGHTFACECOUNT    (TICRATE/2)
#define ST_TURNCOUNT            (1*TICRATE)
#define ST_OUCHCOUNT            (1*TICRATE)
#define ST_RAMPAGEDELAY         (2*TICRATE)

#define ST_MUCHPAIN                     20


// Location and size of statistics,
//  justified according to widget type.
// Problem is, within which space? STbar? Screen?
// Note: this could be read in by a lump.
//       Problem is, is the stuff rendered
//       into a buffer,
//       or into the frame buffer?

// AMMO number pos.
#define ST_AMMOWIDTH            3       
#define ST_AMMOX                        44
#define ST_AMMOY                        171

// HEALTH number pos.
#define ST_HEALTHWIDTH          3       
#define ST_HEALTHX                      90
#define ST_HEALTHY                      171

// Weapon pos.
#define ST_ARMSX                        111
#define ST_ARMSY                        172
#define ST_ARMSBGX                      104
#define ST_ARMSBGY                      168
#define ST_ARMSXSPACE           12
#define ST_ARMSYSPACE           10


// ARMOR number pos.
#define ST_ARMORWIDTH           3
#define ST_ARMORX                       221
#define ST_ARMORY                       171

// Key icon positions.
#define ST_KEY0WIDTH            8
#define ST_KEY0HEIGHT           5
#define ST_KEY0X                        239
#define ST_KEY0Y                        171
#define ST_KEY1WIDTH            ST_KEY0WIDTH
#define ST_KEY1X                        239
#define ST_KEY1Y                        181
#define ST_KEY2WIDTH            ST_KEY0WIDTH
#define ST_KEY2X                        239
#define ST_KEY2Y                        191

// Ammunition counter.
#define ST_AMMO0WIDTH           3
#define ST_AMMO0HEIGHT          6
#define ST_AMMO0X                       288
#define ST_AMMO0Y                       173
#define ST_AMMO1WIDTH           ST_AMMO0WIDTH
#define ST_AMMO1X                       288
#define ST_AMMO1Y                       179
#define ST_AMMO2WIDTH           ST_AMMO0WIDTH
#define ST_AMMO2X                       288
#define ST_AMMO2Y                       191
#define ST_AMMO3WIDTH           ST_AMMO0WIDTH
#define ST_AMMO3X                       288
#define ST_AMMO3Y                       185

// Indicate maximum ammunition.
// Only needed because backpack exists.
#define ST_MAXAMMO0WIDTH                3
#define ST_MAXAMMO0HEIGHT               5
#define ST_MAXAMMO0X            314
#define ST_MAXAMMO0Y            173
#define ST_MAXAMMO1WIDTH                ST_MAXAMMO0WIDTH
#define ST_MAXAMMO1X            314
#define ST_MAXAMMO1Y            179
#define ST_MAXAMMO2WIDTH                ST_MAXAMMO0WIDTH
#define ST_MAXAMMO2X            314
#define ST_MAXAMMO2Y            191
#define ST_MAXAMMO3WIDTH                ST_MAXAMMO0WIDTH
#define ST_MAXAMMO3X            314
#define ST_MAXAMMO3Y            185

// pistol
#define ST_WEAPON0X                     110 
#define ST_WEAPON0Y                     172

// shotgun
#define ST_WEAPON1X                     122 
#define ST_WEAPON1Y                     172

// chain gun
#define ST_WEAPON2X                     134 
#define ST_WEAPON2Y                     172

// missile launcher
#define ST_WEAPON3X                     110 
#define ST_WEAPON3Y                     181

// plasma gun
#define ST_WEAPON4X                     122 
#define ST_WEAPON4Y                     181

 // bfg
#define ST_WEAPON5X                     134
#define ST_WEAPON5Y                     181

// WPNS title
#define ST_WPNSX                        109 
#define ST_WPNSY                        191

 // DETH title
#define ST_DETHX                        109
#define ST_DETHY                        191

//Incoming messages window location
#define ST_MSGTEXTX                     0
#define ST_MSGTEXTY                     0
// Dimensions given in characters.
#define ST_MSGWIDTH                     52
// Or shall I say, in lines?
#define ST_MSGHEIGHT            1

#define ST_OUTTEXTX                     0
#define ST_OUTTEXTY                     6

// Width, in characters again.
#define ST_OUTWIDTH                     52 
 // Height, in lines. 
#define ST_OUTHEIGHT            1


#define ST_MAPTITLEY            0
#define ST_MAPHEIGHT            1




#define CACHETYPE_SPRITE	0
#define CACHETYPE_FLAT		1
#define CACHETYPE_PATCH		2
#define CACHETYPE_COMPOSITE	3




//
// Player states.
//
    // Playing or camping.
	#define PST_LIVE 0
    // Dead on the ground, view follows killer.
	#define PST_DEAD 1
    // Ready to restart/respawn???
	#define PST_REBORN	2

typedef uint8_t playerstate_t;


//
// Player internal flags, for cheats and debug.
//


// No clipping, walk through barriers.
#define CF_NOCLIP		 1
// No damage, no health loss.
#define CF_GODMODE		 2
// Not really a cheat, just a debug aid.
#define CF_NOMOMENTUM	 4
typedef int8_t cheat_t;

//
// Extended player object info: player_t
//

#define GLOWSPEED			8
#define STROBEBRIGHT		5
#define FASTDARK			15
#define SLOWDARK			35

#define BUTTONTOP 0
#define BUTTONMIDDLE 1
#define BUTTONBOTTOM 2




 // max # of wall switches in a level
#define MAXSWITCHES		50

 // 4 players, 4 buttons each at once, max.
#define MAXBUTTONS		4

 // 1 second, in ticks. 
#define BUTTONTIME      35             



//
// P_PLATS
//
#define plat_up 0
#define plat_down 1
#define plat_waiting 2
#define plat_in_stasis 3

typedef uint8_t plat_e;



#define perpetualRaise 0
#define downWaitUpStay 1
#define raiseAndChange 2
#define raiseToNearestAndChange 3
#define blazeDWUS 4

typedef uint8_t plattype_e;


#define PLATWAIT		3
// #define PLATSPEED		FRACUNIT
#define PLATSPEED		(1 << SHORTFLOORBITS)
#define MAXPLATS		30



#define PATCHMASK 0x7FFF
#define ORIGINX_SIGN_FLAG 0x8000

#define normal 0
#define close30ThenOpen 1
#define close 2
#define open 3
#define raiseIn5Mins 4
#define blazeRaise 5
#define blazeOpen 6
#define blazeClose 7


    // lower floor to highest surrounding floor
#define lowerFloor 0
    
    // lower floor to lowest surrounding floor
#define lowerFloorToLowest 1
    
    // lower floor to highest surrounding floor VERY FAST
#define turboLower 2
    
    // raise floor to lowest surrounding CEILING
#define raiseFloor 3
    
    // raise floor to next highest surrounding floor
#define raiseFloorToNearest 4

    // raise floor to shortest height texture around it
#define raiseToTexture 5
    
    // lower floor to lowest surrounding floor
    //  and change floorpic
#define lowerAndChange 6
  
#define raiseFloor24 7
#define raiseFloor24AndChange 8
#define raiseFloorCrush 9

     // raise to next highest floor, turbo-speed
#define raiseFloorTurbo 10
#define donutRaise 11
#define raiseFloor512 12


#define lowerToFloor 0
#define raiseToHighest 1
#define lowerAndCrush 2
#define crushAndRaise 3
#define fastCrushAndRaise 4
#define silentCrushAndRaise 5
typedef int8_t ceiling_e;

#define VDOORSPEED		(2 << SHORTFLOORBITS)
// #define VDOORSPEED		FRACUNIT*2
#define VDOORWAIT		150

#define PLAT_FUNC_IN_STASIS 0
#define PLAT_FUNC_STOP_PLAT 1
#define build8 0	// slowly build by 8
#define turbo16	1 // quickly build by 16

#define FLOORSPEED		(1 << SHORTFLOORBITS)

#define floor_ok 0
#define floor_crushed 1
#define floor_pastdest 2

#define CEILSPEED		(1 << SHORTFLOORBITS)
#define CEILWAIT		150
#define MAXCEILINGS		30



// when to clip out sounds
// Does not fit the large outdoor areas.
#define S_CLIPPING_DIST		(1200*0x10000)
#define S_CLIPPING_DIST_HIGH	(1200)

// Distance tp origin when sounds should be maxed out.
// This should relate to movement clipping resolution
// (see BLOCKMAP handling).
#define S_CLOSE_DIST		(200*0x10000)
#define S_CLOSE_DIST_HIGH		(200)


// #define S_ATTENUATOR		((S_CLIPPING_DIST-S_CLOSE_DIST)>>FRACBITS)
#define S_ATTENUATOR		1000

// Adjustable by menu.
#define NORM_VOLUME    		snd_MaxVolume

#define NORM_PRIORITY		64
#define NORM_SEP		128

#define S_STEREO_SWING		(96*0x10000)
#define S_STEREO_SWING_HIGH	(96)

#define MAX_SOUND_VOLUME 127



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


#define FF_FULLBRIGHT	0x80	// flag in thing->frame
#define FF_FRAMEMASK	0x7f

#define SLOWTURNTICS    6 

typedef enum
{
    ps_weapon,
    ps_flash,
    NUMPSPRITES

} psprnum_t;

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




enum SB_ERRORS
{
    SB_Warning = -2,
    SB_Error = -1,
    SB_OK = 0,
    SB_EnvNotFound,
    SB_AddrNotSet,
    SB_DMANotSet,
    SB_DMA16NotSet,
    SB_InvalidParameter,
    SB_CardNotReady,
    SB_NoSoundPlaying,
    SB_InvalidIrq,
    SB_UnableToSetIrq,
    SB_DmaError,
    SB_NoMixer,
    SB_DPMI_Error,
    SB_OutOfMemory
};

#define SB_MixBufferSize    256
#define SB_TotalBufferSize  (SB_MixBufferSize * 2)

#define SB_TransferLength SB_MixBufferSize
#define SB_DoubleBufferLength SB_TransferLength * 2

#define SAMPLE_RATE_11_KHZ_UINT 11025
#define SAMPLE_RATE_22_KHZ_UINT 22050

#define SAMPLE_RATE_11_KHZ_FLAG 0
#define SAMPLE_RATE_22_KHZ_FLAG 1


#define MIXER_MPU401_INT   0x04
#define MIXER_16BITDMA_INT 0x02
#define MIXER_8BITDMA_INT  0x01



// 11/22 khz mode switch
// when a 22 khz sound is started, set sample mode to mode 22 khz for the next dma cycle...
//   if mode is 22 and last interrupt was not mode 22, do a switch
// in 22 mode, 11 khz samples are doubled.
// when a 22 sound is ended, set a flag
// 	if any 22s played in that interrupt, dont do anything
//  if none played, go back to 11 mode next interrupt?





#define SB_DSP_Set_DA_Rate   0x41
#define SB_DSP_Set_AD_Rate   0x42

#define SB_Ready 			 0xAA

#define SB_MixerAddressPort  0x4
#define SB_MixerDataPort 	 0x5
#define SB_ResetPort 		 0x6
#define SB_ReadPort 		 0xA
#define SB_WritePort 		 0xC
#define SB_DataAvailablePort 0xE

// hacked settings for now

//todo! configure these!
#define UNDEFINED_DMA -1

#define FIXED_SB_PORT   0x220
#define FIXED_SB_DMA_8  1
#define FIXED_SB_DMA_16 5
#define FIXED_SB_IRQ    7

// #define SB_STEREO 1
// #define SB_SIXTEEN_BIT 2


#define SB_TYPE_NONE 	0

#define SB_TYPE_SB 		1
#define SB_TYPE_SBPro 	2
#define SB_TYPE_SB20 	3
#define SB_TYPE_SBPro2 	4
#define SB_TYPE_SB16 	6


#define PLAYING_FLAG    0x80
#define SFX_ID_MASK     0x7F

#define SB_DSP_Version1xx 0x0100
#define SB_DSP_Version2xx 0x0200
#define SB_DSP_Version201 0x0201
#define SB_DSP_Version3xx 0x0300
#define SB_DSP_Version4xx 0x0400



#define NUM_SFX_LUMPS 10







#define SOUND_NOT_IN_CACHE 0xFF


#define SOUND_SINGULARITY_FLAG 0x8000 
#define SOUND_22_KHZ_FLAG 0x4000 
#define SOUND_LUMP_BITMASK 0x3FFF 





#define SB_MIXER_DSP4xxISR_Ack 0x82
#define SB_MIXER_DSP4xxISR_Enable 0x83
#define SB_MIXER_MPU401_INT 0x4
#define SB_MIXER_16BITDMA_INT 0x2
#define SB_MIXER_8BITDMA_INT 0x1
#define SB_MIXER_DisableMPU401Interrupts 0xB
#define SB_MIXER_SBProOutputSetting 0x0E
#define SB_MIXER_SBProStereoFlag 0x02
#define SB_MIXER_SBProVoice 0x04
#define SB_MIXER_SBProMidi 0x26
#define SB_MIXER_SB16VoiceLeft 0x32
#define SB_SBProVoice 0x04
#define SB_MIXER_SB16VoiceRight 0x33
#define SB_MIXER_SB16MidiLeft 0x34
#define SB_MIXER_SB16MidiRight 0x35


#define ETF_NULL 0
#define ETF_A_Light0 1
#define ETF_A_WeaponReady 2
#define ETF_A_Lower 3
#define ETF_A_Raise 4
#define ETF_A_Punch 5
#define ETF_A_ReFire 6
#define ETF_A_FirePistol 7
#define ETF_A_Light1 8
#define ETF_A_FireShotgun 9
#define ETF_A_Light2 10
#define ETF_A_FireShotgun2 11
#define ETF_A_CheckReload 12
#define ETF_A_OpenShotgun2 13
#define ETF_A_LoadShotgun2 14
#define ETF_A_CloseShotgun2 15
#define ETF_A_FireCGun 16
#define ETF_A_GunFlash 17
#define ETF_A_FireMissile 18
#define ETF_A_Saw 19
#define ETF_A_FirePlasma 20
#define ETF_A_BFGsound 21
#define ETF_A_FireBFG 22
#define ETF_A_BFGSpray 23
#define ETF_A_Explode 24
#define ETF_A_Pain 25
#define ETF_A_PlayerScream 26
#define ETF_A_Fall 27
#define ETF_A_XScream 28
#define ETF_A_Look 29
#define ETF_A_Chase 30
#define ETF_A_FaceTarget 31
#define ETF_A_PosAttack 32
#define ETF_A_Scream 33
#define ETF_A_SPosAttack 34
#define ETF_A_VileChase 35
#define ETF_A_VileStart 36
#define ETF_A_VileTarget 37
#define ETF_A_VileAttack 38
#define ETF_A_StartFire 39 
#define ETF_A_Fire 40
#define ETF_A_FireCrackle 41
#define ETF_A_Tracer 42
#define ETF_A_SkelWhoosh 43
#define ETF_A_SkelFist 44
#define ETF_A_SkelMissile 45
#define ETF_A_FatRaise 46
#define ETF_A_FatAttack1 47 
#define ETF_A_FatAttack2 48
#define ETF_A_FatAttack3 49
#define ETF_A_BossDeath 50
#define ETF_A_CPosAttack 51
#define ETF_A_CPosRefire 52
#define ETF_A_TroopAttack 53
#define ETF_A_SargAttack 54
#define ETF_A_HeadAttack 55
#define ETF_A_BruisAttack 56
#define ETF_A_SkullAttack 57
#define ETF_A_Metal 58
#define ETF_A_SpidRefire 59
#define ETF_A_BabyMetal 60 
#define ETF_A_BspiAttack 61
#define ETF_A_Hoof 62 
#define ETF_A_CyberAttack 63
#define ETF_A_PainAttack 64
#define ETF_A_PainDie 65
#define ETF_A_KeenDie 66
#define ETF_A_BrainPain 67
#define ETF_A_BrainScream 68
#define ETF_A_BrainDie 69
#define ETF_A_BrainAwake 70
#define ETF_A_BrainSpit 71
#define ETF_A_SpawnSound 72
#define ETF_A_SpawnFly 73
#define ETF_A_BrainExplode 74

#define BONUSADD	6

#endif

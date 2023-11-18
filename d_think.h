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
//  MapObj data. Map Objects or mobjs are actors, entities,
//  thinker, take-your-pick... anything that moves, acts, or
//  suffers state changes of more or less violent nature.
//

#ifndef __D_THINK__
#define __D_THINK__

#include "z_zone.h"

//
// Experimental stuff.
// To compile this as "ANSI C with classes"
//  we will need to handle the various
//  action functions cleanly.
//

/*

typedef  void (*actionf_v)();
typedef  void (*actionf_p1)( MEMREF );
typedef  void (*actionf_p2)( void*, void* );

typedef union
{
  actionf_p1	acp1;
  actionf_v	acv;
  actionf_p2	acp2;

} actionf_t;


*/


// Historically, "think_t" is yet another
//  function pointer to a routine to handle
//  an actor.
//typedef actionf_t  think_t;

typedef uint8_t  ENEMYTHINKFUNCTION;


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






#endif

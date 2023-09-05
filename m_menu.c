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
//      DOOM selection menu, options, episode etc.
//      Sliders and icons. Kinda widget stuff.
//

#include <unistd.h>
#include <sys/stat.h>
#include <fcntl.h>
#include <stdlib.h>
#include <ctype.h>
#include <alloca.h>


#include "doomdef.h"
#include "dstrings.h"

#include "d_main.h"

#include "i_system.h"
#include "z_zone.h"
#include "v_video.h"
#include "w_wad.h"

#include "r_local.h"


#include "hu_stuff.h"

#include "g_game.h"

#include "m_misc.h"

#include "s_sound.h"

#include "doomstat.h"
// Data.
#include "sounds.h"

#include "m_menu.h"



extern MEMREF         hu_fontRef[HU_FONTSIZE];
extern boolean          message_dontfuckwithme;


//
// defaulted values
//
uint8_t                     mouseSensitivity;       // has default

// Show messages has default, 0 = off, 1 = on
uint8_t                     showMessages;
        
uint8_t         sfxVolume;
uint8_t         musicVolume;

// Blocky mode, has default, 0 = high, 1 = normal
uint8_t                     detailLevel;
uint8_t                     screenblocks;           // has default

// temp for screenblocks (0-9)
uint8_t                     screenSize;

// -1/255 = no quicksave slot picked!
uint8_t                     quickSaveSlot;

 // 1 = message to be printed
uint8_t                     messageToPrint;
// ...and here is the message string!
int8_t*                   messageString;          

// message x & y
int16_t                     messageLastMenuActive;

// timed message = no input from user
boolean                 messageNeedsInput;     

void    (*messageRoutine)(int16_t response);

#define SAVESTRINGSIZE  24

int16_t gammamsg[5] =
{
    GAMMALVL0,
    GAMMALVL1,
    GAMMALVL2,
    GAMMALVL3,
    GAMMALVL4
};

int16_t endmsg[NUM_QUITMESSAGES][80] =
{
    // DOOM1
	QUITMSG,
	QUITMSGD11,
	QUITMSGD12,
	QUITMSGD13,
	QUITMSGD14,
	QUITMSGD15,
	QUITMSGD16,
	QUITMSGD17
};

int16_t endmsg2[NUM_QUITMESSAGES] =
{
    // QuitDOOM II messages
	QUITMSG,
	QUITMSGD21,
	QUITMSGD22,
	QUITMSGD23,
	QUITMSGD24,
	QUITMSGD25,
	QUITMSGD26,
	QUITMSGD27

};

// we are going to be entering a savegame string
int16_t                     saveStringEnter;
int16_t                     saveSlot;       // which slot to save in
int16_t                     saveCharIndex;  // which char we're editing
// old save description before edit
int8_t                    saveOldString[SAVESTRINGSIZE];

boolean                 inhelpscreens;
boolean                 menuactive;

#define SKULLXOFF               -32
#define LINEHEIGHT              16

extern boolean          sendpause;
int8_t                    savegamestrings[10][SAVESTRINGSIZE];

int8_t    endstring[160];


//
// MENU TYPEDEFS
//
typedef struct
{
    // 0 = no cursor here, 1 = ok, 2 = arrows ok
    int8_t       status;
    
	int8_t        name[10];
    
    // choice = menu item #.
    // if status = 2,
    //   choice=0:leftarrow,1:rightarrow
    void        (*routine)(int16_t choice);
    
    // hotkey in menu
	int8_t        alphaKey;
} menuitem_t;



typedef struct menu_s
{
    int16_t               numitems;       // # of menu items
    struct menu_s*      prevMenu;       // previous menu
    menuitem_t*         menuitems;      // menu items
    void                (*routine)();   // draw routine
    int16_t               x;
    int16_t               y;              // x,y of menu
    int16_t               lastOn;         // last item user was on in menu
} menu_t;

int16_t           itemOn;                 // menu item skull is on
int16_t           skullAnimCounter;       // skull animation counter
int16_t           whichSkull;             // which skull to draw

// graphic name of skulls
// warning: initializer-string for array of chars is too long
int8_t    skullName[2][/*8*/9] = {"M_SKULL1","M_SKULL2"};

// current menudef
menu_t* currentMenu;                          

//
// PROTOTYPES
//
void M_NewGame(int16_t choice);
void M_Episode(int16_t choice);
void M_ChooseSkill(int16_t choice);
void M_LoadGame(int16_t choice);
void M_SaveGame(int16_t choice);
void M_Options(int16_t choice);
void M_EndGame(int16_t choice);
void M_ReadThis(int16_t choice);
void M_ReadThis2(int16_t choice);
void M_QuitDOOM(int16_t choice);

void M_ChangeMessages(int16_t choice);
void M_ChangeSensitivity(int16_t choice);
void M_SfxVol(int16_t choice);
void M_MusicVol(int16_t choice);
void M_ChangeDetail(int16_t choice);
void M_SizeDisplay(int16_t choice);
void M_StartGame(int16_t choice);
void M_Sound(int16_t choice);

void M_FinishReadThis(int16_t choice);
void M_LoadSelect(int16_t choice);
void M_SaveSelect(int16_t choice);
void M_ReadSaveStrings(void);
void M_QuickSave(void);
void M_QuickLoad(void);

void M_DrawMainMenu(void);
void M_DrawReadThis1(void);
void M_DrawReadThis2(void);
void M_DrawReadThisRetail(void);
void M_DrawNewGame(void);
void M_DrawEpisode(void);
void M_DrawOptions(void);
void M_DrawSound(void);
void M_DrawLoad(void);
void M_DrawSave(void);

void M_DrawSaveLoadBorder(int16_t x, int16_t y);
void M_SetupNextMenu(menu_t *menudef);
void M_DrawThermo(int16_t x, int16_t y, int16_t thermWidth, int16_t thermDot);
void M_WriteText(int16_t x, int16_t y, int8_t *string);
int16_t  M_StringWidth(int8_t *string);
int16_t  M_StringHeight(int8_t *string);
void M_StartControlPanel(void);
void M_StartMessage(int8_t *string,void *routine,boolean input);
void M_StopMessage(void);
void M_ClearMenus (void);




//
// DOOM MENU
//
enum
{
    newgame = 0,
    options,
    loadgame,
    savegame,
    readthis,
    quitdoom,
    main_end
} main_e;

menuitem_t MainMenu[]=
{
    {1,"M_NGAME",M_NewGame,'n'},
    {1,"M_OPTION",M_Options,'o'},
    {1,"M_LOADG",M_LoadGame,'l'},
    {1,"M_SAVEG",M_SaveGame,'s'},
    // Another hickup with Special edition.
#if (EXE_VERSION < EXE_VERSION_ULTIMATE)
    {1,"M_RDTHIS",M_ReadThis,'r'},
#else
    {1,"M_RDTHIS",M_ReadThis2,'r'},
#endif
    {1,"M_QUITG",M_QuitDOOM,'q'}
};

menu_t  MainDef =
{
    main_end,
    NULL,
    MainMenu,
    M_DrawMainMenu,
    97,64,
    0
};


//
// EPISODE SELECT
//
enum
{
    ep1,
    ep2,
    ep3,
#if (EXE_VERSION >= EXE_VERSION_ULTIMATE)
    ep4,
#endif
    ep_end
} episodes_e;

menuitem_t EpisodeMenu[]=
{
    {1,"M_EPI1", M_Episode,'k'},
    {1,"M_EPI2", M_Episode,'t'},
    {1,"M_EPI3", M_Episode,'i'},
#if (EXE_VERSION >= EXE_VERSION_ULTIMATE)
    {1,"M_EPI4", M_Episode,'t'}
#endif
};

menu_t  EpiDef =
{
    ep_end,             // # of menu items
    &MainDef,           // previous menu
    EpisodeMenu,        // menuitem_t ->
    M_DrawEpisode,      // drawing routine ->
    48,63,              // x,y
    ep1                 // lastOn
};

//
// NEW GAME
//
enum
{
    killthings,
    toorough,
    hurtme,
    violence,
    nightmare,
    newg_end
} newgame_e;

menuitem_t NewGameMenu[]=
{
    {1,"M_JKILL",       M_ChooseSkill, 'i'},
    {1,"M_ROUGH",       M_ChooseSkill, 'h'},
    {1,"M_HURT",        M_ChooseSkill, 'h'},
    {1,"M_ULTRA",       M_ChooseSkill, 'u'},
    {1,"M_NMARE",       M_ChooseSkill, 'n'}
};

menu_t  NewDef =
{
    newg_end,           // # of menu items
    &EpiDef,            // previous menu
    NewGameMenu,        // menuitem_t ->
    M_DrawNewGame,      // drawing routine ->
    48,63,              // x,y
    hurtme              // lastOn
};



//
// OPTIONS MENU
//
enum
{
    endgame,
    messages,
    detail,
    scrnsize,
    option_empty1,
    mousesens,
    option_empty2,
    soundvol,
    opt_end
} options_e;

menuitem_t OptionsMenu[]=
{
    {1,"M_ENDGAM",      M_EndGame,'e'},
    {1,"M_MESSG",       M_ChangeMessages,'m'},
    {1,"M_DETAIL",      M_ChangeDetail,'g'},
    {2,"M_SCRNSZ",      M_SizeDisplay,'s'},
    {-1,"",0},
    {2,"M_MSENS",       M_ChangeSensitivity,'m'},
    {-1,"",0},
    {1,"M_SVOL",        M_Sound,'s'}
};

menu_t  OptionsDef =
{
    opt_end,
    &MainDef,
    OptionsMenu,
    M_DrawOptions,
    60,37,
    0
};

//
// Read This! MENU 1 & 2
//
enum
{
    rdthsempty1,
    read1_end
} read_e;

menuitem_t ReadMenu1[] =
{
    {1,"",M_ReadThis2,0}
};

menu_t  ReadDef1 =
{
    read1_end,
    &MainDef,
    ReadMenu1,
    M_DrawReadThis1,
    280,185,
    0
};

enum
{
    rdthsempty2,
    read2_end
} read_e2;

menuitem_t ReadMenu2[]=
{
    {1,"",M_FinishReadThis,0}
};

menu_t  ReadDef2 =
{
    read2_end,
#if (EXE_VERSION < EXE_VERSION_ULTIMATE)
    &ReadDef1,
#else
    NULL,
#endif
    ReadMenu2,
#if (EXE_VERSION < EXE_VERSION_FINAL)
    M_DrawReadThis2,
#else
    M_DrawReadThisRetail,
#endif
    330,175,
    0
};

//
// SOUND VOLUME MENU
//
enum
{
    sfx_vol,
    sfx_empty1,
    music_vol,
    sfx_empty2,
    sound_end
} sound_e;

menuitem_t SoundMenu[]=
{
    {2,"M_SFXVOL",M_SfxVol,'s'},
    {-1,"",0},
    {2,"M_MUSVOL",M_MusicVol,'m'},
    {-1,"",0}
};

menu_t  SoundDef =
{
    sound_end,
    &OptionsDef,
    SoundMenu,
    M_DrawSound,
    80,64,
    0
};

//
// LOAD GAME MENU
//
enum
{
    load1,
    load2,
    load3,
    load4,
    load5,
    load6,
    load_end
} load_e;

menuitem_t LoadMenu[]=
{
    {1,"", M_LoadSelect,'1'},
    {1,"", M_LoadSelect,'2'},
    {1,"", M_LoadSelect,'3'},
    {1,"", M_LoadSelect,'4'},
    {1,"", M_LoadSelect,'5'},
    {1,"", M_LoadSelect,'6'}
};

menu_t  LoadDef =
{
    load_end,
    &MainDef,
    LoadMenu,
    M_DrawLoad,
    80,54,
    0
};

//
// SAVE GAME MENU
//
menuitem_t SaveMenu[]=
{
    {1,"", M_SaveSelect,'1'},
    {1,"", M_SaveSelect,'2'},
    {1,"", M_SaveSelect,'3'},
    {1,"", M_SaveSelect,'4'},
    {1,"", M_SaveSelect,'5'},
    {1,"", M_SaveSelect,'6'}
};

menu_t  SaveDef =
{
    load_end,
    &MainDef,
    SaveMenu,
    M_DrawSave,
    80,54,
    0
};


//
// M_ReadSaveStrings
//  read the strings from the savegame files
//
void M_ReadSaveStrings(void)
{
	int16_t             handle;
	int16_t             count;
	int8_t             i;
	int8_t    name[256];
        
    for (i = 0;i < load_end;i++)
    {
        if (M_CheckParm("-cdrom"))
            sprintf(name,"c:\\doomdata\\"SAVEGAMENAME"%d.dsg",i);
        else
            sprintf(name,SAVEGAMENAME"%d.dsg",i);

        handle = open (name, O_RDONLY | 0, 0666);
        if (handle == -1)
        {
            strcpy(&savegamestrings[i][0],getStringByIndex(EMPTYSTRING));
            LoadMenu[i].status = 0;
            continue;
        }
        count = read (handle, &savegamestrings[i], SAVESTRINGSIZE);
        close (handle);
        LoadMenu[i].status = 1;
    }
}


//
// M_LoadGame & Cie.
//
void M_DrawLoad(void)
{
	int8_t             i;
        
    V_DrawPatchDirect (72,28, W_CacheLumpNameEMSAsPatch("M_LOADG",PU_CACHE));
    for (i = 0;i < load_end; i++)
    {
        M_DrawSaveLoadBorder(LoadDef.x,LoadDef.y+LINEHEIGHT*i);
        M_WriteText(LoadDef.x,LoadDef.y+LINEHEIGHT*i,savegamestrings[i]);
    }
}



//
// Draw border for the savegame description
//
void M_DrawSaveLoadBorder(int16_t x, int16_t y)
{
	int8_t             i;
        
    V_DrawPatchDirect (x-8,y+7, W_CacheLumpNameEMSAsPatch("M_LSLEFT", PU_CACHE));
        
    for (i = 0;i < 24;i++)
    {
        V_DrawPatchDirect (x,y+7, W_CacheLumpNameEMSAsPatch("M_LSCNTR", PU_CACHE)) ;
        x += 8;
    }

    V_DrawPatchDirect (x,y+7, W_CacheLumpNameEMSAsPatch("M_LSRGHT", PU_CACHE)) ;
}



//
// User wants to load this game
//
void M_LoadSelect(int16_t choice)
{
	int8_t    name[256];
        
    if (M_CheckParm("-cdrom"))
        sprintf(name,"c:\\doomdata\\"SAVEGAMENAME"%d.dsg",choice);
    else
        sprintf(name,SAVEGAMENAME"%d.dsg",choice);
    G_LoadGame (name);
    M_ClearMenus ();
}

//
// Selected from DOOM menu
//
void M_LoadGame (int16_t choice)
{
 
    M_SetupNextMenu(&LoadDef);
    M_ReadSaveStrings();
}


//
//  M_SaveGame & Cie.
//
void M_DrawSave(void)
{
	int8_t             i;
        
    V_DrawPatchDirect (72,28, W_CacheLumpNameEMSAsPatch("M_SAVEG", PU_CACHE));
    for (i = 0;i < load_end; i++)
    {
        M_DrawSaveLoadBorder(LoadDef.x,LoadDef.y+LINEHEIGHT*i);
        M_WriteText(LoadDef.x,LoadDef.y+LINEHEIGHT*i,savegamestrings[i]);
    }
        
    if (saveStringEnter)
    {
        i = M_StringWidth(savegamestrings[saveSlot]);
        M_WriteText(LoadDef.x + i,LoadDef.y+LINEHEIGHT*saveSlot,"_");
    }
}

//
// M_Responder calls this when user is finished
//
void M_DoSave(int16_t slot)
{
    G_SaveGame (slot,savegamestrings[slot]);
    M_ClearMenus ();

    // PICK QUICKSAVE SLOT YET?
    if (quickSaveSlot == 254)  // means to pick a slot now
        quickSaveSlot = slot;
}

//
// User wants to save. Start string input for M_Responder
//
void M_SaveSelect(int16_t choice)
{
    // we are going to be intercepting all chars
    saveStringEnter = 1;
    
    saveSlot = choice;
    strcpy(saveOldString,savegamestrings[choice]);
    if (!strcmp(savegamestrings[choice], getStringByIndex(EMPTYSTRING)))
        savegamestrings[choice][0] = 0;
    saveCharIndex = strlen(savegamestrings[choice]);
}

//
// Selected from DOOM menu
//
void M_SaveGame (int16_t choice)
{
    if (!usergame)
    {
        M_StartMessage(getStringByIndex(SAVEDEAD),NULL,false);
        return;
    }
        
    if (gamestate != GS_LEVEL)
        return;
        
    M_SetupNextMenu(&SaveDef);
    M_ReadSaveStrings();
}



//
//      M_QuickSave
//
int8_t    tempstring[80];

void M_QuickSaveResponse(int16_t ch)
{
    if (ch == 'y')
    {
        M_DoSave(quickSaveSlot);
        S_StartSound(NULL,sfx_swtchx);
    }
}

void M_QuickSave(void)
{
    if (!usergame)
    {
        S_StartSound(NULL,sfx_oof);
        return;
    }

    if (gamestate != GS_LEVEL)
        return;
        
    if (quickSaveSlot > 250) // hack for -1 on a uint_8
    {
        M_StartControlPanel();
        M_ReadSaveStrings();
        M_SetupNextMenu(&SaveDef);
        quickSaveSlot = 254;     // means to pick a slot now
        return;
    }
    sprintf(tempstring, getStringByIndex(QSPROMPT),savegamestrings[quickSaveSlot]);
    M_StartMessage(tempstring,M_QuickSaveResponse,true);
}



//
// M_QuickLoad
//
void M_QuickLoadResponse(int16_t ch)
{
    if (ch == 'y')
    {
        M_LoadSelect(quickSaveSlot);
        S_StartSound(NULL,sfx_swtchx);
    }
}


void M_QuickLoad(void)
{
    
    if (quickSaveSlot > 250) // means to pick a slot now
    {
        M_StartMessage(getStringByIndex(QSAVESPOT),NULL,false);
        return;
    }
    sprintf(tempstring, getStringByIndex(QLPROMPT),savegamestrings[quickSaveSlot]);
    M_StartMessage(tempstring,M_QuickLoadResponse,true);
}




//
// Read This Menus
// Had a "quick hack to fix romero bug"
//
void M_DrawReadThis1(void)
{
    inhelpscreens = true;
    V_DrawPatchDirect(0, 0, W_CacheLumpNameEMSAsPatch("HELP2", PU_CACHE));
}



//
// Read This Menus - optional second page.
//
#if (EXE_VERSION < EXE_VERSION_FINAL)
void M_DrawReadThis2(void)
{
    inhelpscreens = true;
    V_DrawPatchDirect(0, 0, W_CacheLumpNameEMSAsPatch("HELP1", PU_CACHE));
}
#endif

void M_DrawReadThisRetail(void)
{
    inhelpscreens = true;
    V_DrawPatchDirect(0, 0, W_CacheLumpNameEMSAsPatch("HELP", PU_CACHE));
}


//
// Change Sfx & Music volumes
//
void M_DrawSound(void)
{
    V_DrawPatchDirect (60,38, W_CacheLumpNameEMSAsPatch("M_SVOL", PU_CACHE));

    M_DrawThermo(SoundDef.x,SoundDef.y+LINEHEIGHT*(sfx_vol+1),
                 16,sfxVolume);

    M_DrawThermo(SoundDef.x,SoundDef.y+LINEHEIGHT*(music_vol+1),
                 16,musicVolume);
}

void M_Sound(int16_t choice)
{
    M_SetupNextMenu(&SoundDef);
}

void M_SfxVol(int16_t choice)
{
    switch(choice)
    {
      case 0:
        if (sfxVolume)
        sfxVolume--;
        break;
      case 1:
        if (sfxVolume < 15)
        sfxVolume++;
        break;
    }
        
    S_SetSfxVolume(sfxVolume * 8);
}

void M_MusicVol(int16_t choice)
{
    switch(choice)
    {
      case 0:
        if (musicVolume)
        musicVolume--;
        break;
      case 1:
        if (musicVolume < 15)
        musicVolume++;
        break;
    }
        
    S_SetMusicVolume(musicVolume * 8);
}




//
// M_DrawMainMenu
//
void M_DrawMainMenu(void)
{
    V_DrawPatchDirect (94,2, W_CacheLumpNameEMSAsPatch("M_DOOM", PU_CACHE));
}




//
// M_NewGame
//
void M_DrawNewGame(void)
{
    V_DrawPatchDirect (96,14, W_CacheLumpNameEMSAsPatch("M_NEWG", PU_CACHE));
    V_DrawPatchDirect (54,38, W_CacheLumpNameEMSAsPatch("M_SKILL", PU_CACHE));
}

void M_NewGame(int16_t choice)
{
	if (commercial)
		M_SetupNextMenu(&NewDef);
	else
		M_SetupNextMenu(&EpiDef);
}


//
//      M_Episode
//
int8_t     epi;

void M_DrawEpisode(void)
{
    V_DrawPatchDirect (54,38, W_CacheLumpNameEMSAsPatch("M_EPISOD", PU_CACHE));
}

void M_VerifyNightmare(int16_t ch)
{
    if (ch != 'y')
        return;
                
    G_DeferedInitNew(nightmare,epi+1,1);
    M_ClearMenus ();
}

void M_ChooseSkill(int16_t choice)
{
    if (choice == nightmare)
    {
        M_StartMessage(getStringByIndex(NIGHTMARE),M_VerifyNightmare,true);
        return;
    }
        
    G_DeferedInitNew(choice,epi+1,1);
    M_ClearMenus ();
}

void M_Episode(int16_t choice)
{
    if ( shareware
         && choice)
    {
        M_StartMessage(getStringByIndex(SWSTRING),NULL,false);
        M_SetupNextMenu(&ReadDef1);
        return;
    }
         
    epi = choice;
    M_SetupNextMenu(&NewDef);
}



//
// M_Options
//
int8_t    detailNames[2][9]       = {"M_GDHIGH","M_GDLOW"};
int8_t    msgNames[2][9]          = {"M_MSGOFF","M_MSGON"};


void M_DrawOptions(void)
{
    V_DrawPatchDirect (108,15, W_CacheLumpNameEMSAsPatch("M_OPTTTL", PU_CACHE));
        
    V_DrawPatchDirect (OptionsDef.x + 175,OptionsDef.y+LINEHEIGHT*detail,
		W_CacheLumpNameEMSAsPatch(detailNames[detailLevel], PU_CACHE))   ;

    V_DrawPatchDirect (OptionsDef.x + 120,OptionsDef.y+LINEHEIGHT*messages,
		W_CacheLumpNameEMSAsPatch(msgNames[showMessages], PU_CACHE)) ;

    M_DrawThermo(OptionsDef.x,OptionsDef.y+LINEHEIGHT*(mousesens+1),
                 10,mouseSensitivity);
        
    M_DrawThermo(OptionsDef.x,OptionsDef.y+LINEHEIGHT*(scrnsize+1),
                 9,screenSize);
}

void M_Options(int16_t choice)
{
    M_SetupNextMenu(&OptionsDef);
}



//
//      Toggle messages on/off
//
void M_ChangeMessages(int16_t choice)
{
    // warning: unused parameter `int16_t choice'
    choice = 0;
    showMessages = 1 - showMessages;
        
    if (!showMessages)
        players.message = MSGOFF;
    else
        players.message = MSGON ;

    message_dontfuckwithme = true;
}


//
// M_EndGame
//
void M_EndGameResponse(int16_t ch)
{
    if (ch != 'y')
        return;
                
    currentMenu->lastOn = itemOn;
    M_ClearMenus ();
    D_StartTitle ();
}

void M_EndGame(int16_t choice)
{
	choice = 0;
	if (!usergame)
	{
		S_StartSound(NULL, sfx_oof);
		return;
	}

	M_StartMessage(getStringByIndex(ENDGAME), M_EndGameResponse, true);
}




//
// M_ReadThis
//
void M_ReadThis(int16_t choice)
{
    choice = 0;
    M_SetupNextMenu(&ReadDef1);
}

void M_ReadThis2(int16_t choice)
{
    choice = 0;
    M_SetupNextMenu(&ReadDef2);
}

void M_FinishReadThis(int16_t choice)
{
    choice = 0;
    M_SetupNextMenu(&MainDef);
}




//
// M_QuitDOOM
//
int8_t     quitsounds[8] =
{
    sfx_pldeth,
    sfx_dmpain,
    sfx_popain,
    sfx_slop,
    sfx_telept,
    sfx_posit1,
    sfx_posit3,
    sfx_sgtatk
};

int8_t     quitsounds2[8] =
{
    sfx_vilact,
    sfx_getpow,
    sfx_boscub,
    sfx_slop,
    sfx_skeswg,
    sfx_kntdth,
    sfx_bspact,
    sfx_sgtatk
};



void M_QuitResponse(int16_t ch)
{
	if (ch != 'y')
		return;

	if (commercial)
		S_StartSound(NULL, quitsounds2[(gametic >> 2) & 7]);
	else
		S_StartSound(NULL, quitsounds[(gametic >> 2) & 7]);
	I_WaitVBL(105);

	I_Quit();
}




void M_QuitDOOM(int16_t choice)
{
  // We pick index 0 which is language sensitive,
  //  or one at random, between 1 and maximum number.
    if (commercial)
    {
        if (french)
        {
            sprintf(endstring, "%s%s\n\n",getStringByIndex(DOSY), getStringByIndex(endmsg2[0]) );
        }
        else
        {
            sprintf(endstring, "%s%s\n\n",getStringByIndex(DOSY),
				getStringByIndex(endmsg2[(gametic >> 2) % NUM_QUITMESSAGES]));
        }
    }
    else
    {
        sprintf(endstring, "%s%s\n\n",getStringByIndex(DOSY),
			getStringByIndex(endmsg[(gametic >> 2) % NUM_QUITMESSAGES]));
    }
  
  M_StartMessage(endstring,M_QuitResponse,true);
}




void M_ChangeSensitivity(int16_t choice)
{
    switch(choice)
    {
      case 0:
        if (mouseSensitivity)
            mouseSensitivity--;
        break;
      case 1:
        if (mouseSensitivity < 9)
            mouseSensitivity++;
        break;
    }
}




void M_ChangeDetail(int16_t choice)
{
    choice = 0;
    detailLevel = 1 - detailLevel;

    R_SetViewSize (screenblocks, detailLevel);

    if (!detailLevel)
        players.message = DETAILHI;
    else
        players.message = DETAILLO;
}




void M_SizeDisplay(int16_t choice)
{
    switch(choice)
    {
      case 0:
        if (screenSize > 0)
        {
            screenblocks--;
            screenSize--;
        }
        break;
      case 1:
        if (screenSize < 8)
        {
            screenblocks++;
            screenSize++;
        }
        break;
    }
        

    R_SetViewSize (screenblocks, detailLevel);
}




//
//      Menu Functions
//
void
M_DrawThermo
(int16_t   x,
	int16_t   y,
	int16_t   thermWidth,
	int16_t   thermDot )
{
	int16_t         xx;
	int16_t         i;

    xx = x;
    V_DrawPatchDirect (xx,y, W_CacheLumpNameEMSAsPatch("M_THERML", PU_CACHE));
    xx += 8;
    for (i=0;i<thermWidth;i++)
    {
        V_DrawPatchDirect (xx,y, W_CacheLumpNameEMSAsPatch("M_THERMM", PU_CACHE));
        xx += 8;
    }
    V_DrawPatchDirect (xx,y, W_CacheLumpNameEMSAsPatch("M_THERMR", PU_CACHE));

    V_DrawPatchDirect ((x+8) + thermDot*8,y,
                        W_CacheLumpNameEMSAsPatch("M_THERMO", PU_CACHE));
}

 


void
M_StartMessage
( int8_t*         string,
  void*         routine,
  boolean       input )
{
    messageLastMenuActive = menuactive;
    messageToPrint = 1;
    messageString = string;
    messageRoutine = routine;
    messageNeedsInput = input;
    menuactive = true;
    return;
}






//
// Find string width from hu_font chars
//
int16_t M_StringWidth(int8_t* string)
{
	int16_t             i;
	int16_t             w = 0;
	int16_t             c;
	patch_t* hu_fontC;

    for (i = 0;i < strlen(string);i++)
    {
        c = toupper(string[i]) - HU_FONTSTART;
        if (c < 0 || c >= HU_FONTSIZE)
            w += 4;
		else {
			hu_fontC = Z_LoadBytesFromEMS(hu_fontRef[c]);
			w += (hu_fontC->width);
		}
    }
                
    return w;
}



//
//      Find string height from hu_font chars
//
int16_t M_StringHeight(int8_t* string)
{
	int8_t             i;
	int16_t             h;
	patch_t* hu_font0 = Z_LoadBytesFromEMS(hu_fontRef[0]);
	int16_t             height = (hu_font0->height);
        
    h = height;
    for (i = 0;i < strlen(string);i++)
        if (string[i] == '\n')
            h += height;
                
    return h;
}


//
//      Write a string using the hu_font
//
void
M_WriteText
(int16_t           x,
	int16_t           y,
  int8_t*         string)
{
	int16_t         w;
    int8_t*       ch;
	int16_t         c;
	int16_t         cx;
	int16_t         cy;
	patch_t* hu_fontC;

    ch = string;
    cx = x;
    cy = y;
        
    while(1)
    {
        c = *ch++;
        if (!c)
            break;
        if (c == '\n')
        {
            cx = x;
            cy += 12;
            continue;
        }
                
        c = toupper(c) - HU_FONTSTART;
        if (c < 0 || c>= HU_FONTSIZE)
        {
            cx += 4;
            continue;
        }
		hu_fontC = Z_LoadBytesFromEMS(hu_fontRef[c]);

        w =  (hu_fontC->width);
        if (cx+w > SCREENWIDTH)
            break;
        V_DrawPatchDirect(cx, cy, hu_fontC);
        cx+=w;
    }
}



//
// CONTROL PANEL
//

//
// M_Responder
//
boolean M_Responder (event_t* ev)
{
	int16_t             ch;
	int16_t             i;
    static  int16_t     mousewait = 0;
    static  int16_t     mousey = 0;
    static  int16_t     lasty = 0;
    static  int16_t     mousex = 0;
    static  int16_t     lastx = 0;
        
    ch = -1;
        
    
    if (ev->type == ev_mouse && mousewait < ticcount)
    {
        mousey += ev->data3;
        if (mousey < lasty-30)
        {
            ch = KEY_DOWNARROW;
            mousewait = ticcount + 5;
            mousey = lasty -= 30;
        }
        else if (mousey > lasty+30)
        {
            ch = KEY_UPARROW;
            mousewait = ticcount + 5;
            mousey = lasty += 30;
        }
                
        mousex += ev->data2;
        if (mousex < lastx-30)
        {
            ch = KEY_LEFTARROW;
            mousewait = ticcount + 5;
            mousex = lastx -= 30;
        }
        else if (mousex > lastx+30)
        {
            ch = KEY_RIGHTARROW;
            mousewait = ticcount + 5;
            mousex = lastx += 30;
        }
                
        if (ev->data1&1)
        {
            ch = KEY_ENTER;
            mousewait = ticcount + 15;
        }
                        
        if (ev->data1&2)
        {
            ch = KEY_BACKSPACE;
            mousewait = ticcount + 15;
        }
    }
    else
        if (ev->type == ev_keydown)
        {
            ch = ev->data1;
        }
    
    if (ch == -1)
        return false;

    
    // Save Game string input
    if (saveStringEnter)
    {
        switch(ch)
        {
          case KEY_BACKSPACE:
            if (saveCharIndex > 0)
            {
                saveCharIndex--;
                savegamestrings[saveSlot][saveCharIndex] = 0;
            }
            break;
                                
          case KEY_ESCAPE:
            saveStringEnter = 0;
            strcpy(&savegamestrings[saveSlot][0],saveOldString);
            break;
                                
          case KEY_ENTER:
            saveStringEnter = 0;
            if (savegamestrings[saveSlot][0])
                M_DoSave(saveSlot);
            break;
                                
          default:
            ch = toupper(ch);
            if (ch != 32)
                if (ch-HU_FONTSTART < 0 || ch-HU_FONTSTART >= HU_FONTSIZE)
                    break;
            if (ch >= 32 && ch <= 127 &&
                saveCharIndex < SAVESTRINGSIZE-1 &&
                M_StringWidth(savegamestrings[saveSlot]) <
                (SAVESTRINGSIZE-2)*8)
            {
                savegamestrings[saveSlot][saveCharIndex++] = ch;
                savegamestrings[saveSlot][saveCharIndex] = 0;
            }
            break;
        }
        return true;
    }
    
    // Take care of any messages that need input
    if (messageToPrint)
    {
        if (messageNeedsInput == true &&
            !(ch == ' ' || ch == 'n' || ch == 'y' || ch == KEY_ESCAPE))
            return false;
                
        menuactive = messageLastMenuActive;
        messageToPrint = 0;
        if (messageRoutine)
            messageRoutine(ch);
                        
        menuactive = false;
        S_StartSound(NULL,sfx_swtchx);
        return true;
    }
        
                
    
    // F-Keys
    if (!menuactive)
        switch(ch)
        {
          case KEY_MINUS:         // Screen size down
            if (automapactive )
                return false;
            M_SizeDisplay(0);
            S_StartSound(NULL,sfx_stnmov);
            return true;
                                
          case KEY_EQUALS:        // Screen size up
            if (automapactive )
                return false;
            M_SizeDisplay(1);
            S_StartSound(NULL,sfx_stnmov);
            return true;
                                
          case KEY_F1:            // Help key
            M_StartControlPanel ();

#if (EXE_VERSION < EXE_VERSION_ULTIMATE)
        currentMenu = &ReadDef1;
#else
            currentMenu = &ReadDef2;
#endif
            
            itemOn = 0;
            S_StartSound(NULL,sfx_swtchn);
            return true;
                                
          case KEY_F2:            // Save
			M_StartControlPanel();
            S_StartSound(NULL,sfx_swtchn);
            M_SaveGame(0);
            return true;
                                
          case KEY_F3:            // Load
			  M_StartControlPanel();
            S_StartSound(NULL,sfx_swtchn);
            M_LoadGame(0);
            return true;
                                
          case KEY_F4:            // Sound Volume
            M_StartControlPanel ();
            currentMenu = &SoundDef;
            itemOn = sfx_vol;
            S_StartSound(NULL,sfx_swtchn);
            return true;
                                
          case KEY_F5:            // Detail toggle
            M_ChangeDetail(0);
            S_StartSound(NULL,sfx_swtchn);
            return true;
                                
          case KEY_F6:            // Quicksave
			  S_StartSound(NULL,sfx_swtchn);
            M_QuickSave();
            return true;
                                
          case KEY_F7:            // End game
            S_StartSound(NULL,sfx_swtchn);
            M_EndGame(0);
            return true;
                                
          case KEY_F8:            // Toggle messages
            M_ChangeMessages(0);
            S_StartSound(NULL,sfx_swtchn);
            return true;
                                
          case KEY_F9:            // Quickload
            S_StartSound(NULL,sfx_swtchn);
            M_QuickLoad();
            return true;
                                
          case KEY_F10:           // Quit DOOM
            S_StartSound(NULL,sfx_swtchn);
            M_QuitDOOM(0);
            return true;
                                
          case KEY_F11:           // gamma toggle
            usegamma++;
            if (usegamma > 4)
                usegamma = 0;
            players.message = gammamsg[usegamma];
            I_SetPalette (Z_LoadBytesFromEMS(W_CacheLumpNameEMS("PLAYPAL", PU_CACHE)));
            return true;
                                
        }

    
    // Pop-up menu?
    if (!menuactive)
    {
        if (ch == KEY_ESCAPE)
        {
            M_StartControlPanel ();
            S_StartSound(NULL,sfx_swtchn);
            return true;
        }
        return false;
    }

    
    // Keys usable within menu
    switch (ch)
    {
      case KEY_DOWNARROW:
        do
        {
            if (itemOn+1 > currentMenu->numitems-1)
                itemOn = 0;
            else itemOn++;
            S_StartSound(NULL,sfx_pstop);
        } while(currentMenu->menuitems[itemOn].status==-1);
        return true;
                
      case KEY_UPARROW:
        do
        {
            if (!itemOn)
                itemOn = currentMenu->numitems-1;
            else itemOn--;
            S_StartSound(NULL,sfx_pstop);
        } while(currentMenu->menuitems[itemOn].status==-1);
        return true;

      case KEY_LEFTARROW:
        if (currentMenu->menuitems[itemOn].routine &&
            currentMenu->menuitems[itemOn].status == 2)
        {
            S_StartSound(NULL,sfx_stnmov);
            currentMenu->menuitems[itemOn].routine(0);
        }
        return true;
                
      case KEY_RIGHTARROW:
        if (currentMenu->menuitems[itemOn].routine &&
            currentMenu->menuitems[itemOn].status == 2)
        {
            S_StartSound(NULL,sfx_stnmov);
            currentMenu->menuitems[itemOn].routine(1);
        }
        return true;

      case KEY_ENTER:
        if (currentMenu->menuitems[itemOn].routine &&
            currentMenu->menuitems[itemOn].status)
        {
            currentMenu->lastOn = itemOn;
            if (currentMenu->menuitems[itemOn].status == 2)
            {
                currentMenu->menuitems[itemOn].routine(1);      // right arrow
                S_StartSound(NULL,sfx_stnmov);
            }
            else
            {
                currentMenu->menuitems[itemOn].routine(itemOn);
                S_StartSound(NULL,sfx_pistol);
            }
        }
        return true;
                
      case KEY_ESCAPE:
        currentMenu->lastOn = itemOn;
        M_ClearMenus ();
        S_StartSound(NULL,sfx_swtchx);
        return true;
                
      case KEY_BACKSPACE:
        currentMenu->lastOn = itemOn;
        if (currentMenu->prevMenu)
        {
            currentMenu = currentMenu->prevMenu;
            itemOn = currentMenu->lastOn;
            S_StartSound(NULL,sfx_swtchn);
        }
        return true;
        
      default:
        for (i = itemOn+1;i < currentMenu->numitems;i++)
            if (currentMenu->menuitems[i].alphaKey == ch)
            {
                itemOn = i;
                S_StartSound(NULL,sfx_pstop);
                return true;
            }
        for (i = 0;i <= itemOn;i++)
            if (currentMenu->menuitems[i].alphaKey == ch)
            {
                itemOn = i;
                S_StartSound(NULL,sfx_pstop);
                return true;
            }
        break;
        
    }

    return false;
}



//
// M_StartControlPanel
//
void M_StartControlPanel (void)
{
    // intro might call this repeatedly
    if (menuactive)
        return;
    
    menuactive = 1;
    currentMenu = &MainDef;         // JDC
    itemOn = currentMenu->lastOn;   // JDC
}


//
// M_Drawer
// Called after the view has been rendered,
// but before it has been blitted.
//
void M_Drawer (void)
{
    static int16_t        x;
    static int16_t        y;
    int16_t               i;
    int16_t               max;
	int8_t                string[40];
	int16_t                 start;
	patch_t*			hu_font0;

    inhelpscreens = false;

    
    // Horiz. & Vertically center string and print it.
    if (messageToPrint)
    {
        start = 0;
        y = 100 - M_StringHeight(messageString)/2;
        while(*(messageString+start))
        {
            for (i = 0;i < strlen(messageString+start);i++)
                if (*(messageString+start+i) == '\n')
                {
                    memset(string,0,40);
                    strncpy(string,messageString+start,i);
                    start += i+1;
                    break;
                }
                                
            if (i == strlen(messageString+start))
            {
                strcpy(string,messageString+start);
                start += i;
            }
                                
            x = 160 - M_StringWidth(string)/2;
            M_WriteText(x,y,string);
			hu_font0 = Z_LoadBytesFromEMS(hu_fontRef[0]);

            y += (hu_font0->height);
        }
        return;
    }

    if (!menuactive)
        return;

    if (currentMenu->routine)
        currentMenu->routine();         // call Draw routine
    
    // DRAW MENU
    x = currentMenu->x;
    y = currentMenu->y;
    max = currentMenu->numitems;

    for (i=0;i<max;i++)
    {
        if (currentMenu->menuitems[i].name[0])
            V_DrawPatchDirect (x,y,
				W_CacheLumpNameEMSAsPatch(currentMenu->menuitems[i].name, PU_CACHE)) ;
        y += LINEHEIGHT;
    }

    
    // DRAW SKULL
	V_DrawPatchDirect(x + SKULLXOFF, currentMenu->y - 5 + itemOn * LINEHEIGHT,
		W_CacheLumpNameEMSAsPatch(skullName[whichSkull], PU_CACHE));


}


//
// M_ClearMenus
//
void M_ClearMenus (void)
{
    menuactive = 0;
}




//
// M_SetupNextMenu
//
void M_SetupNextMenu(menu_t *menudef)
{
    currentMenu = menudef;
    itemOn = currentMenu->lastOn;
}


//
// M_Ticker
//
void M_Ticker (void)
{
    if (--skullAnimCounter <= 0)
    {
        whichSkull ^= 1;
        skullAnimCounter = 8;
    }
}


//
// M_Init
//
void M_Init (void)
{
    currentMenu = &MainDef;
    menuactive = 0;
    itemOn = currentMenu->lastOn;
    whichSkull = 0;
    skullAnimCounter = 10;
    screenSize = screenblocks - 3;
    messageToPrint = 0;
    messageString = NULL;
    messageLastMenuActive = menuactive;
    quickSaveSlot = 255;  // means to pick a slot now

    if (commercial)
    {
        MainMenu[readthis] = MainMenu[quitdoom];
        MainDef.numitems--;
        MainDef.y += 8;
        NewDef.prevMenu = &MainDef;
        ReadDef1.routine = M_DrawReadThisRetail;
        ReadDef1.x = 330;
        ReadDef1.y = 165;
        ReadMenu1[0].routine = M_FinishReadThis;
    }
}


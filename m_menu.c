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
#include <dos.h>

#include "m_memory.h"
#include "m_near.h"







#ifdef __DEMO_ONLY_BINARY
void __near M_Ticker(void) {

}
boolean M_Responder(event_t __far*  ev) {
    return false;
}

void __far M_Drawer (int8_t isFromWipe) {
}
void __near M_StartControlPanel(void) {

}

patch_t __far* M_GetMenuPatch(int16_t i);

#else

extern boolean          message_dontfuckwithme;
extern uint16_t            hu_font[HU_FONTSIZE];

//uint16_t menuoffsets[NUM_MENU_ITEMS];

// 1 = message to be printed
uint8_t                     messageToPrint;
// ...and here is the message string!
int8_t                   menu_messageString[105];

// message x & y
int16_t                     messageLastMenuActive;

// timed message = no input from user
boolean                 messageNeedsInput;

void    (__near *messageRoutine)(int16_t response);


int8_t gammamsg[5] =
{
    GAMMALVL0,
    GAMMALVL1,
    GAMMALVL2,
    GAMMALVL3,
    GAMMALVL4
};

int16_t endmsg[NUM_QUITMESSAGES] =
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



#define SKULLXOFF               -32
#define LINEHEIGHT              16
#define HU_FONT_SIZE            8
extern boolean          sendpause;
//int8_t                    savegamestrings[10*SAVESTRINGSIZE];


int16_t           itemOn;                 // menu item skull is on
int16_t           skullAnimCounter;       // skull animation counter
int16_t           whichSkull;             // which skull to draw

// graphic name of skulls
// warning: initializer-string for array of chars is too long
int16_t    skullName[2] = {5, 6};

// current menudef
menu_t __near* currentMenu;                          

//
// PROTOTYPES
//
void __near M_NewGame(int16_t choice);
void __near M_Episode(int16_t choice);
void __near M_ChooseSkill(int16_t choice);
void __near M_LoadGame(int16_t choice);
void __near M_SaveGame(int16_t choice);
void __near M_Options(int16_t choice);
void __near M_EndGame(int16_t choice);
void __near M_ReadThis(int16_t choice);
void __near M_ReadThis2(int16_t choice);
void __near M_QuitDOOM(int16_t choice);

void __near M_ChangeMessages(int16_t choice);
void __near M_ChangeSensitivity(int16_t choice);
void __near M_SfxVol(int16_t choice);
void __near M_MusicVol(int16_t choice);
void __near M_ChangeDetail(int16_t choice);
void __near M_SizeDisplay(int16_t choice);
void __near M_Sound(int16_t choice);

void __near M_FinishReadThis(int16_t choice);
void __near M_LoadSelect(int16_t choice);
void __near M_SaveSelect(int16_t choice);
void __near M_ReadSaveStrings(void);
void __near M_QuickSave(void);
void __near M_QuickLoad(void);

void __near M_DrawMainMenu(void);
void __near M_DrawReadThis1(void);
void __near M_DrawReadThis2(void);
void __near M_DrawReadThisRetail(void);
void __near M_DrawNewGame(void);
void __near M_DrawEpisode(void);
void __near M_DrawOptions(void);
void __near M_DrawSound(void);
void __near M_DrawLoad(void);
void __near M_DrawSave(void);

void __near M_DrawSaveLoadBorder(int16_t x, int16_t y);
void __near M_SetupNextMenu(menu_t __near*menudef);
void __near M_DrawThermo(int16_t x, int16_t y, int16_t thermWidth, int16_t thermDot);
void __near M_WriteText(int16_t x, int16_t y, int8_t *string);
int16_t  __near M_StringWidth(int8_t *string);
int16_t  __near M_StringHeight(int8_t *string);
void __near M_StartControlPanel(void);
void __near M_StartMessage(int8_t __near * string,void __near (* routine)(int16_t), boolean input);
 



menuitem_t MainMenu[]=
{
    {1,4,M_NewGame,'n'},
    {1,2,M_Options,'o'},
    {1,30,M_LoadGame,'l'},
    {1,29,M_SaveGame,'s'},
    // Another hickup with Special edition.
#if (EXE_VERSION < EXE_VERSION_ULTIMATE)
    {1,1,M_ReadThis,'r'},
#else
    {1,1,M_ReadThis2,'r'},
#endif
    {1,3,M_QuitDOOM,'q'}
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
    {1,17, M_Episode,'k'},
    {1,18, M_Episode,'t'},
    {1,19, M_Episode,'i'},
#if (EXE_VERSION >= EXE_VERSION_ULTIMATE)
    {1,46, M_Episode,'t'}
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
    {1,21,       M_ChooseSkill, 'i'},
    {1,22,       M_ChooseSkill, 'h'},
    {1,20,        M_ChooseSkill, 'h'},
    {1,25,       M_ChooseSkill, 'u'},
    {1,26,       M_ChooseSkill, 'n'}
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
    {1,11,      M_EndGame,'e'},
    {1,13,       M_ChangeMessages,'m'},
    {1,35,      M_ChangeDetail,'g'},
    {2,37,      M_SizeDisplay,'s'},
    {-1,-1,0},
    {2,32,       M_ChangeSensitivity,'m'},
    {-1,-1,0},
    {1,27,        M_Sound,'s'}
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
    {1,-1,M_ReadThis2,0}
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
    {1,-1,M_FinishReadThis,0}
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
    {2,40,M_SfxVol,'s'},
    {-1,-1,0},
    {2,41,M_MusicVol,'m'},
    {-1,-1,0}
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
#define load_end 6

menuitem_t LoadMenu[]=
{
    {1,-1, M_LoadSelect,'1'},
    {1,-1, M_LoadSelect,'2'},
    {1,-1, M_LoadSelect,'3'},
    {1,-1, M_LoadSelect,'4'},
    {1,-1, M_LoadSelect,'5'},
    {1,-1, M_LoadSelect,'6'}
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
    {1,-1, M_SaveSelect,'1'},
    {1,-1, M_SaveSelect,'2'},
    {1,-1, M_SaveSelect,'3'},
    {1,-1, M_SaveSelect,'4'},
    {1,-1, M_SaveSelect,'5'},
    {1,-1, M_SaveSelect,'6'}
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


patch_t __far* __near M_GetMenuPatch(int16_t i) {
    if (i >= 27){
        return (patch_t __far*)(menugraphicspage4 + menuoffsets[i]);
    }
    return (patch_t __far*)(menugraphicspage0 + menuoffsets[i]);

}

//
// M_ReadSaveStrings
//  read the strings from the savegame files
//
void __near M_ReadSaveStrings(void)
{
    int16_t             handle;
    int16_t             count;
    int8_t             i;
    int8_t    name[256];
    int8_t    temp[256];
        
    for (i = 0;i < load_end;i++)
    {
        sprintf(name,SAVEGAMENAME"%d.dsg",i);

        handle = open (name, O_RDONLY | 0, 0666);
        if (handle == -1)
        {
            getStringByIndex(EMPTYSTRING, temp);
            strcpy(&savegamestrings[i*SAVESTRINGSIZE],temp);
            LoadMenu[i].status = 0;
            continue;
        }
        count = read (handle, &savegamestrings[i*SAVESTRINGSIZE], SAVESTRINGSIZE);
        close (handle);
        LoadMenu[i].status = 1;
    }
}


//
// M_LoadGame & Cie.
//
void __near M_DrawLoad(void)
{
    int8_t             i;
        
    V_DrawPatchDirect (72,28, M_GetMenuPatch(30));
    for (i = 0;i < load_end; i++)
    {
        M_DrawSaveLoadBorder(LoadDef.x,LoadDef.y+LINEHEIGHT*i);
        M_WriteText(LoadDef.x,LoadDef.y+LINEHEIGHT*i,&savegamestrings[i*SAVESTRINGSIZE]);
    }
}



//
// Draw border for the savegame description
//
void __near M_DrawSaveLoadBorder(int16_t x, int16_t y)
{
    int8_t             i;
        
    V_DrawPatchDirect (x-8,y+7, M_GetMenuPatch(42));
        
    for (i = 0;i < 24;i++)
    {
        V_DrawPatchDirect (x,y+7, M_GetMenuPatch(43)) ;
        x += 8;
    }

    V_DrawPatchDirect (x,y+7, M_GetMenuPatch(44)) ;
}



//
// User wants to load this game
//
void __near M_LoadSelect(int16_t choice)
{
    int8_t    name[256];
        
    sprintf(name,SAVEGAMENAME"%d.dsg",choice);
    G_LoadGame (name);
    // M_ClearMenus
    menuactive = 0;
}

//
// Selected from DOOM menu
//
void __near M_LoadGame (int16_t choice)
{
 
    M_SetupNextMenu(&LoadDef);
    M_ReadSaveStrings();
}


//
//  M_SaveGame & Cie.
//
void __near M_DrawSave(void)
{
    int8_t             i;
        
    V_DrawPatchDirect (72,28, M_GetMenuPatch(29));
    for (i = 0;i < load_end; i++)
    {
        M_DrawSaveLoadBorder(LoadDef.x,LoadDef.y+LINEHEIGHT*i);
        M_WriteText(LoadDef.x,LoadDef.y+LINEHEIGHT*i,&savegamestrings[i*SAVESTRINGSIZE]);
    }
        
    if (saveStringEnter)
    {
        i = M_StringWidth(&savegamestrings[saveSlot*SAVESTRINGSIZE]);
        M_WriteText(LoadDef.x + i,LoadDef.y+LINEHEIGHT*saveSlot,"_");
    }
}

//
// M_Responder calls this when user is finished
//
void __near M_DoSave(int16_t slot)
{
    G_SaveGame (slot,&savegamestrings[slot*SAVESTRINGSIZE]);
    // M_ClearMenus
    menuactive = 0;

    // PICK QUICKSAVE SLOT YET?
    if (quickSaveSlot == -2)  // means to pick a slot now
        quickSaveSlot = slot;
}

//
// User wants to save. Start string input for M_Responder
//
void __near M_SaveSelect(int16_t choice)
{
    int8_t temp[256];
    int8_t i;
    int16_t offset = choice*SAVESTRINGSIZE;
    // we are going to be intercepting all chars
    saveStringEnter = 1;
    
    saveSlot = choice;
    
    for (i = 0; i < SAVESTRINGSIZE; i++){
        saveOldString[i] = savegamestrings[offset+i];    
    }
    //FAR_strcpy(saveOldString,&savegamestrings[choice*SAVESTRINGSIZE]);

    getStringByIndex(EMPTYSTRING, temp);
    if (!strcmp(&savegamestrings[choice*SAVESTRINGSIZE], temp))
        savegamestrings[choice*SAVESTRINGSIZE] = 0;
    saveCharIndex = strlen(&savegamestrings[choice*SAVESTRINGSIZE]);
}

//
// Selected from DOOM menu
//
void __near M_SaveGame (int16_t choice)
{
    int8_t temp[256];
    if (!usergame)
    {
        getStringByIndex(SAVEDEAD, temp);
        M_StartMessage(temp,NULL,false);
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

void __near M_QuickSaveResponse(int16_t ch)
{
    if (ch == 'y')
    {
        M_DoSave(quickSaveSlot);
        S_StartSound(NULL,sfx_swtchx);
    }
}

void __near M_QuickSave(void)
{
        /*
    int8_t temp[256];
    int8_t    tempstring[80];
    if (!usergame)
    {
        S_StartSound(NULL,sfx_oof);
        return;
    }

    if (gamestate != GS_LEVEL)
        return;
        

    if (quickSaveSlot < 0) // hack for -1 on a uint_8
    {
        M_StartControlPanel();
        M_ReadSaveStrings();
        M_SetupNextMenu(&SaveDef);
        quickSaveSlot = -2;     // means to pick a slot now
        return;
    }
    getStringByIndex(QSPROMPT, temp);
    sprintf(tempstring, temp,&savegamestrings[quickSaveSlot*SAVESTRINGSIZE]);
    M_StartMessage(tempstring,M_QuickSaveResponse,true);
    */
}



//
// M_QuickLoad
//
void __near M_QuickLoadResponse(int16_t ch)
{
    if (ch == 'y')
    {
        M_LoadSelect(quickSaveSlot);
        S_StartSound(NULL,sfx_swtchx);
    }
}


void __near M_QuickLoad(void)
{
    /*
    int8_t temp[256];
    int8_t    tempstring[80];
if (quickSaveSlot < 0) // means to pick a slot now
    {
        getStringByIndex(QSAVESPOT, temp);
        M_StartMessage(temp,NULL,false);
        return;
    }
    getStringByIndex(QLPROMPT, temp);
    sprintf(tempstring, temp,&savegamestrings[quickSaveSlot*SAVESTRINGSIZE]);
    M_StartMessage(tempstring,M_QuickLoadResponse,true);
    */
}




//
// Read This Menus
// Had a "quick hack to fix romero bug"
//
void __near M_DrawReadThis1(void)
{
    inhelpscreens = true;
    V_DrawFullscreenPatch("HELP2", 0);
}



//
// Read This Menus - optional second page.
//
#if (EXE_VERSION < EXE_VERSION_FINAL)
void __near M_DrawReadThis2(void)
{
    inhelpscreens = true;
    V_DrawFullscreenPatch("HELP1", 0);
}
#endif

void __near M_DrawReadThisRetail(void)
{
    inhelpscreens = true;
    V_DrawFullscreenPatch("HELP", 0);
}


//
// Change Sfx & Music volumes
//
void __near M_DrawSound(void)
{
    V_DrawPatchDirect (60,38, M_GetMenuPatch(27));

    M_DrawThermo(SoundDef.x,SoundDef.y+LINEHEIGHT*(sfx_vol+1),
                 16,sfxVolume);

    M_DrawThermo(SoundDef.x,SoundDef.y+LINEHEIGHT*(music_vol+1),
                 16,musicVolume);
}

void __near M_Sound(int16_t choice)
{
    M_SetupNextMenu(&SoundDef);
}

void __near M_SfxVol(int16_t choice)
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

void __near M_MusicVol(int16_t choice)
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
void __near M_DrawMainMenu(void)
{
    V_DrawPatchDirect (94,2, M_GetMenuPatch(0));
}




//
// M_NewGame
//
void __near M_DrawNewGame(void)
{
    V_DrawPatchDirect (96,14, M_GetMenuPatch(24));
    V_DrawPatchDirect (54,38, M_GetMenuPatch(23));
}

void __near M_NewGame(int16_t choice)
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

void __near M_DrawEpisode(void)
{
    V_DrawPatchDirect (54,38, M_GetMenuPatch(16));
}

void __near M_VerifyNightmare(int16_t ch)
{
    if (ch != 'y')
        return;
                
    G_DeferedInitNew(nightmare,epi+1,1);
    // M_ClearMenus
    menuactive = 0;
}

void __near M_ChooseSkill(int16_t choice)
{
    int8_t temp[256];
    if (choice == nightmare)
    {
        getStringByIndex(NIGHTMARE, temp);
        M_StartMessage(temp,M_VerifyNightmare,true);
        return;
    }
        
    G_DeferedInitNew(choice,epi+1,1);
    // M_ClearMenus
    menuactive = 0;
}

void __near M_Episode(int16_t choice)
{
    int8_t temp[256];
    if ( shareware
         && choice)
    {
        getStringByIndex(SWSTRING, temp);
        M_StartMessage(temp,NULL,false);
        M_SetupNextMenu(&ReadDef1);
        return;
    }
         
    epi = choice;
    M_SetupNextMenu(&NewDef);
}



//
// M_Options
//
int8_t    detailNames[2]       = {33, 34};
int8_t    msgNames[2]          = {15, 14};


void __near M_DrawOptions(void)
{
    

    V_DrawPatchDirect (108,15, M_GetMenuPatch(28));
        
    V_DrawPatchDirect (OptionsDef.x + 175,OptionsDef.y+LINEHEIGHT*detail,
        M_GetMenuPatch(detailNames[detailLevel]));

    V_DrawPatchDirect (OptionsDef.x + 120,OptionsDef.y+LINEHEIGHT*messages,
        M_GetMenuPatch(msgNames[showMessages])) ;

    M_DrawThermo(OptionsDef.x,OptionsDef.y+LINEHEIGHT*(mousesens+1),
                 10,mouseSensitivity);
        
    M_DrawThermo(OptionsDef.x,OptionsDef.y+LINEHEIGHT*(scrnsize+1),
                 11,screenSize);
}

void __near M_Options(int16_t choice)
{
    M_SetupNextMenu(&OptionsDef);
}



//
//      Toggle messages on/off
//
void __near M_ChangeMessages(int16_t choice)
{
    // warning: unused parameter `int16_t choice'
    choice = 0;
    showMessages = 1 - showMessages;
        
    if (!showMessages)
        player.message = MSGOFF;
    else
        player.message = MSGON ;

    message_dontfuckwithme = true;
}


//
// M_EndGame
//
void __near M_EndGameResponse(int16_t ch)
{
    if (ch != 'y')
        return;
                
    currentMenu->lastOn = itemOn;
    // M_ClearMenus
    menuactive = 0;
    D_StartTitle ();
}

void __near M_EndGame(int16_t choice)
{
    int8_t temp[256];
    choice = 0;
    if (!usergame)
    {
        S_StartSound(NULL, sfx_oof);
        return;
    }
    getStringByIndex(ENDGAME, temp);
    M_StartMessage(temp, M_EndGameResponse, true);
}




//
// M_ReadThis
//
void __near M_ReadThis(int16_t choice)
{
    choice = 0;
    M_SetupNextMenu(&ReadDef1);
}

void __near M_ReadThis2(int16_t choice)
{
    choice = 0;
    M_SetupNextMenu(&ReadDef2);
}

void __near M_FinishReadThis(int16_t choice)
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



void __near M_QuitResponse(int16_t ch)
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




void __near M_QuitDOOM(int16_t choice)
{
  // We pick index 0 which is language sensitive,
  //  or one at random, between 1 and maximum number.
    int8_t temp[100];
    int8_t temp2[100];
    int8_t endstring[140];
    int8_t chosenendmsg = (gametic >> 2) % NUM_QUITMESSAGES;
    getStringByIndex(DOSY, temp2);
    if (commercial)
    {
        getStringByIndex(endmsg2[chosenendmsg], temp);
            sprintf(endstring, "%s\n%s",
                temp,
                temp2
            );
    }
    else
    {
        getStringByIndex(endmsg[chosenendmsg], temp);
        sprintf(endstring, "%s\n%s",
            temp,
            temp2
        );
            
    }

    M_StartMessage(endstring,M_QuitResponse,true);
}





void __near M_ChangeSensitivity(int16_t choice)
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




void __near M_ChangeDetail(int16_t choice)
{
    choice = 0;
    detailLevel++;
    if (detailLevel == 3){
        detailLevel = 0;
    }

    R_SetViewSize (screenblocks, detailLevel);

    if (!detailLevel){
        player.message = DETAILHI;
    } else if (detailLevel == 1){
        player.message = DETAILLO;
    } else{
        player.message = DETAILPOTATO;
    }
}




void __near M_SizeDisplay(int16_t choice)
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
        if (screenSize < 10)
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
void __near M_DrawThermo (int16_t   x, int16_t   y, int16_t   thermWidth, int16_t   thermDot ) {
    int16_t         xx;
    int16_t         i;

    xx = x;


    V_DrawPatchDirect (xx,y, M_GetMenuPatch(10));
    xx += 8;
    for (i=0;i<thermWidth;i++) {
        V_DrawPatchDirect (xx,y, M_GetMenuPatch(9));
        xx += 8;
    }
    V_DrawPatchDirect (xx,y, M_GetMenuPatch(8));

    V_DrawPatchDirect ((x+8) + thermDot*8,y, M_GetMenuPatch(7));
}

 


void __near M_StartMessage ( int8_t __near * string, void __near (*routine)(int16_t), boolean input )
{
    messageLastMenuActive = menuactive;
    messageToPrint = 1;
    //messageString = 
    strcpy(menu_messageString, string);
    messageRoutine = routine;
    messageNeedsInput = input;
    menuactive = true;
    return;
}






//
// Find string width from hu_font chars
//
int16_t __near M_StringWidth(int8_t* string)
{
    int16_t             i;
    int16_t             w = 0;
    int16_t             c;
    
    for (i = 0;i < strlen(string);i++)
    {
        c = toupper(string[i]) - HU_FONTSTART;
        if (c < 0 || c >= HU_FONTSIZE)
            w += 4;
        else {
            w += (((patch_t __far *)MK_FP(ST_GRAPHICS_SEGMENT, hu_font[c]))->width);
        }
    }
                
    return w;
}



//
//      Find string height from hu_font chars
//
int16_t __near M_StringHeight(int8_t* string)
{
    int8_t             i;
    int16_t             h = HU_FONT_SIZE;
     
        
     for (i = 0;i < strlen(string);i++)
        if (string[i] == '\n')
            h += HU_FONT_SIZE;
                
    return h;
}


//
//      Write a string using the hu_font
//
void __near M_WriteText (int16_t x, int16_t y, int8_t* string) {
    int16_t         w;
    int8_t*       ch;
    int16_t         c;
    int16_t         cx;
    int16_t         cy;
    
    ch = string;
    cx = x;
    cy = y;
        
    while(1)
    {
        c = *ch;
        ch++;
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

        w = (((patch_t __far *)MK_FP(ST_GRAPHICS_SEGMENT, hu_font[c]))->width);

        if (cx+w > SCREENWIDTH)
            break;
        V_DrawPatchDirect(cx, cy, (patch_t __far *)MK_FP(ST_GRAPHICS_SEGMENT, hu_font[c]));
        cx+=w;
    }
}



//
// CONTROL PANEL
//

//
// M_Responder
//
boolean __far M_Responder (event_t __far*  ev)
{
    int16_t             ch;
    int16_t             i;
    int16_t             offset;
    static  int16_t     mousewait = 0;
    static  int16_t     mousey = 0;
    static  int16_t     lasty = 0;
    static  int16_t     mousex = 0;
    static  int16_t     lastx = 0;
    int8_t oldtask;
    int8_t j;

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
    else {
        if (ev->type == ev_keydown) {
            ch = ev->data1;
        }
    }

    if (ch == -1) {
        return false;
    }
    
    // Save Game string input
    if (saveStringEnter) {
        switch(ch) {
          case KEY_BACKSPACE:
            if (saveCharIndex > 0) {
                saveCharIndex--;
                savegamestrings[saveSlot*SAVESTRINGSIZE+saveCharIndex] = 0;
            }
            break;
                                
          case KEY_ESCAPE:
            saveStringEnter = 0;
            offset = saveSlot*SAVESTRINGSIZE;
            // skip FAR_strcpy, it includes a big unecessary nonportable function into the build
            for (j = 0; j < SAVESTRINGSIZE; j++){
                savegamestrings[offset+j] = saveOldString[j];
            }
            //FAR_strcpy(&savegamestrings[saveSlot*SAVESTRINGSIZE],saveOldString);

            break;
                                
          case KEY_ENTER:
            saveStringEnter = 0;
            if (savegamestrings[saveSlot*SAVESTRINGSIZE])
                M_DoSave(saveSlot);
            break;
                                
          default:
            ch = toupper(ch);
            if (ch != 32)
                if (ch-HU_FONTSTART < 0 || ch-HU_FONTSTART >= HU_FONTSIZE)
                    break;
            if (ch >= 32 && ch <= 127 &&
                saveCharIndex < SAVESTRINGSIZE-1 &&
                M_StringWidth(&savegamestrings[saveSlot*SAVESTRINGSIZE]) <
                (SAVESTRINGSIZE-2)*8) {
                savegamestrings[saveSlot*SAVESTRINGSIZE+saveCharIndex++] = ch;
                savegamestrings[saveSlot*SAVESTRINGSIZE+saveCharIndex] = 0;
            }
            break;
        }
        return true;
    }
    
    // Take care of any messages that need input
    if (messageToPrint) {
        if (messageNeedsInput == true &&
            !(ch == ' ' || ch == 'n' || ch == 'y' || ch == KEY_ESCAPE))
            return false;
                
        menuactive = messageLastMenuActive;
        messageToPrint = 0;
        if (messageRoutine) {
            messageRoutine(ch);
        }
                        
        menuactive = false;
        S_StartSound(NULL,sfx_swtchx);
        return true;
    }
        
                
    
    // F-Keys
    if (!menuactive)
        switch(ch) {
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
            player.message = gammamsg[usegamma];
            I_SetPalette (0);
            return true;
                                
        }

    
    // Pop-up menu?
    if (!menuactive) {
        if (ch == KEY_ESCAPE) {
            M_StartControlPanel ();
            S_StartSound(NULL,sfx_swtchn);
            return true;
        }
        return false;
    }

    
    // Keys usable within menu
    switch (ch) {
      case KEY_DOWNARROW:
        do {
            if (itemOn+1 > currentMenu->numitems-1)
                itemOn = 0;
            else itemOn++;
            S_StartSound(NULL,sfx_pstop);
        } while(currentMenu->menuitems[itemOn].status==-1);
        return true;
                
      case KEY_UPARROW:
        do {
            if (!itemOn)
                itemOn = currentMenu->numitems-1;
            else itemOn--;
            S_StartSound(NULL,sfx_pstop);
        } while(currentMenu->menuitems[itemOn].status==-1);
        return true;

      case KEY_LEFTARROW:
        if (currentMenu->menuitems[itemOn].routine &&
            currentMenu->menuitems[itemOn].status == 2) {

            oldtask = currenttask;
            Z_QuickMapMenu();


            S_StartSound(NULL,sfx_stnmov);
            currentMenu->menuitems[itemOn].routine(0);

            Z_QuickMapByTaskNum(oldtask);

        }
        return true;
                
      case KEY_RIGHTARROW:
        if (currentMenu->menuitems[itemOn].routine &&
            currentMenu->menuitems[itemOn].status == 2) {

            oldtask = currenttask;
            Z_QuickMapMenu();

            S_StartSound(NULL,sfx_stnmov);
            currentMenu->menuitems[itemOn].routine(1);
            
            Z_QuickMapByTaskNum(oldtask);

        }
        return true;

      case KEY_ENTER:
        if (currentMenu->menuitems[itemOn].routine &&
            currentMenu->menuitems[itemOn].status) {

            oldtask = currenttask;
            Z_QuickMapMenu();

            currentMenu->lastOn = itemOn;
            
            if (currentMenu->menuitems[itemOn].status == 2) {
                currentMenu->menuitems[itemOn].routine(1);      // right arrow
                S_StartSound(NULL,sfx_stnmov);
            } else {
                currentMenu->menuitems[itemOn].routine(itemOn);
                S_StartSound(NULL,sfx_pistol);
            }
            Z_QuickMapByTaskNum(oldtask);

        }
        return true;
                
      case KEY_ESCAPE:
        currentMenu->lastOn = itemOn;
        // M_ClearMenus
        menuactive = 0;
        S_StartSound(NULL,sfx_swtchx);
        return true;
                
      case KEY_BACKSPACE:
        currentMenu->lastOn = itemOn;
        if (currentMenu->prevMenu) {
            currentMenu = currentMenu->prevMenu;
            itemOn = currentMenu->lastOn;
            S_StartSound(NULL,sfx_swtchn);
        }
        return true;
        
      default:
          for (i = itemOn + 1; i < currentMenu->numitems; i++) {
              if (currentMenu->menuitems[i].alphaKey == ch) {
                  itemOn = i;
                  S_StartSound(NULL, sfx_pstop);
                  return true;
              }
          }
        for (i = 0; i <= itemOn; i++) {
            if (currentMenu->menuitems[i].alphaKey == ch) {
                itemOn = i;
                S_StartSound(NULL, sfx_pstop);
                return true;
            }
        }
        break;
        
    }

    return false;
}



//
// M_StartControlPanel
//
void __near M_StartControlPanel (void)
{
    // intro might call this repeatedly
    if (menuactive) {
        return;
    }
    menuactive = 1;
    currentMenu = &MainDef;         // JDC
    itemOn = currentMenu->lastOn;   // JDC
}


//
// M_Drawer
// Called after the view has been rendered,
// but before it has been blitted.
//
void __far M_Drawer (int8_t isFromWipe) {
    static int16_t        x;
    static int16_t        y;
    int16_t               i;
    int16_t               max;
    int8_t                string[40];
    int16_t                 start;
    

    inhelpscreens = false;

    
    // Horiz. & Vertically center string and print it.
    if (messageToPrint) {
        // Not menu - because status has the graphics for letter!
        Z_QuickMapStatus();

        start = 0;
        y = 100 - M_StringHeight(menu_messageString)/2;
        while(*(menu_messageString+start)) {
            for (i = 0; i < strlen(menu_messageString + start); i++) {
                if (*(menu_messageString + start + i) == '\n') {
                    memset(string, 0, 40);
                    strncpy(string, menu_messageString + start, i);
                    start += i + 1;
                    break;
                }
            }

            if (i == strlen(menu_messageString+start)) {
                strcpy(string,menu_messageString+start);
                start += i;
            }
                                
            x = 160 - M_StringWidth(string)/2;
            M_WriteText(x,y,string);

            y += HU_FONT_SIZE;
        }
        isFromWipe ? Z_QuickMapWipe() : Z_QuickMapPhysics();

        return;
    }

    if (!menuactive) {
        return;
    }
    Z_QuickMapMenu();

    if (currentMenu->routine) {
        currentMenu->routine();         // call Draw routine
    }

    // DRAW MENU
    x = currentMenu->x;
    y = currentMenu->y;
    max = currentMenu->numitems;

    for (i=0;i<max;i++) {
        if (currentMenu->menuitems[i].name != -1) {
            V_DrawPatchDirect(x, y,
                M_GetMenuPatch(currentMenu->menuitems[i].name)) ;
        }
        y += LINEHEIGHT;
    }

    
    // DRAW SKULL
    V_DrawPatchDirect(x + SKULLXOFF, currentMenu->y - 5 + itemOn * LINEHEIGHT,
        M_GetMenuPatch(skullName[whichSkull])) ;

    isFromWipe ? Z_QuickMapWipe() : Z_QuickMapPhysics();

}






//
// M_SetupNextMenu
//
void __near M_SetupNextMenu(menu_t __near *menudef)
{
    currentMenu = menudef;
    itemOn = currentMenu->lastOn;
}


//
// M_Ticker
//
void __near M_Ticker (void)
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
 
#ifndef __DEMO_ONLY_BINARY

// this is only done in init... pull into there?

void __near M_Reload(void) {
	// reload menu graphics
	int16_t i = 0;
	uint32_t size = 0;
	byte __far* dst = menugraphicspage0;
	uint8_t pageoffset = 0;

 	int8_t menugraphics[NUM_MENU_ITEMS * 9];

	FILE *fp = fopen("D_MENUG.BIN", "rb"); // clear old file
	fread(menugraphics, 9, NUM_MENU_ITEMS, fp);
	fclose(fp);

	for (i = 0; i < NUM_MENU_ITEMS; i++) {
		int16_t lump = W_GetNumForName(&menugraphics[i*9]);
		uint16_t lumpsize = W_LumpLength(lump);
		if (i == 27) { // (size + lumpsize) > 65535u) {
			// repage
			size = 0;
			pageoffset += 4;
			dst = menugraphicspage4;
		}
		W_CacheLumpNumDirect(lump, dst);
		menuoffsets[i] = size;
		size += lumpsize;
		dst += lumpsize;

	}



}



void __far M_Init(void)
{
	

	Z_QuickMapMenu();
	
	M_Reload();
	

	currentMenu = &MainDef;
	menuactive = 0;
	itemOn = currentMenu->lastOn;
	whichSkull = 0;
	skullAnimCounter = 10;
	screenSize = screenblocks - 1;
	messageToPrint = 0;
	menu_messageString[0] = '\0';
	messageLastMenuActive = menuactive;
	quickSaveSlot = -1;  // means to pick a slot now

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

	Z_QuickMapPhysics();

	
}
#endif

#endif


#include "doomdef.h"
#include "m_near.h"

int16_t SB_InitCard();
int8_t SB_SetupPlayback();
void SB_PlaySoundEffect(int8_t i);
void SB_Shutdown();
void SB_IncrementApplicationVolume();
void SB_DecrementApplicationVolume();



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

// todo what does this mean
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



#define SB_DSP_Version1xx 0x0100
#define SB_DSP_Version2xx 0x0200
#define SB_DSP_Version201 0x0201
#define SB_DSP_Version3xx 0x0300
#define SB_DSP_Version4xx 0x0400
void SB_StopPlayback();


#define NUM_SFX_TO_MIX 8

#define NUM_SFX_LUMPS 10


typedef struct {

    sfxenum_t          	sfx_id;
	int8_t				samplerate;         // could be figured out from sfxlumpinfo in theory
	uint16_t			length;             // could be figured out from sfxlumpinfo in theory
	uint16_t			currentsample;      // in bytes. could be multiples of 256 and stored in one byte though.
	boolean 			playing;            
	int8_t 	 			volume;
} SB_VoiceInfo ;


extern SB_VoiceInfo sb_voicelist[NUM_SFX_TO_MIX];
extern SB_VoiceInfo sb_sfx_info[NUM_SFX_LUMPS];
extern int8_t* 		sfxfilename[NUM_SFX_LUMPS];
extern uint8_t      application_volume;


typedef struct sfxinfo_struct sfxinfo_t;

#define SOUND_NOT_IN_CACHE 0xFF
#define SFX_PAGE_SEGMENT   0xD400

typedef struct {

    
    int16_t_union       cache_position;
    uint16_t            recency;
} sound_cache_info_t;

struct sfxinfo_struct
{
    // up to 6-character name
    char *name;
    // bit15 =   singularity
    // bit14 =   1 for 22 khz 0 for 11 khz
    // bit0-13 = lumpnum
    // lump number of sfx
    uint16_t lumpandflags;
    int16_t_union lumpsize;
    
    sound_cache_info_t  cache_info;
};

#define SOUND_SINGULARITY_FLAG 0x8000 
#define SOUND_22_KHZ_FLAG 0x4000 
#define SOUND_LUMP_BITMASK 0x3FFF 

sfxinfo_t S_sfx[NUMSFX/2];









void S_TempInit2();

#include "doomdef.h"

#include <dos.h>
#include <conio.h>
#include <stdlib.h>
#include <stdarg.h>
#include <stdio.h>
#include <graph.h>

#include <i86.h>
#include "s_sbsfx.h"
#include <sys/types.h>
#include <string.h>
#include "DMX.H"
#include "w_wad.h"
#include "i_sound.h"
#include <signal.h>
#include <bios.h>
#include <ctype.h>
#include <malloc.h>
#include "i_system.h"





void( __interrupt __far *SB_OldInt)(void);


// actual variables that get set.
// todo: set from environment variable.
int16_t sb_port = -1;
int16_t sb_dma  = -1;
int16_t sb_irq  = -1;

// int8_t sb_dma_16 = UNDEFINED_DMA;
int8_t sb_dma_8  = UNDEFINED_DMA;

uint8_t     SB_IntController1Mask;
uint8_t     SB_IntController2Mask;




int8_t  SB_CardActive = false;
int16_t_union SB_DSP_Version;
uint8_t SB_MixerType = SB_TYPE_NONE;
uint8_t SB_OriginalVoiceVolumeLeft = 255;
uint8_t SB_OriginalVoiceVolumeRight = 255;



uint8_t SB_Mixer_Status;
// sfx cache is done by updating lru array ordering on sound start and play.
// anything with an >0 reference count cannot be deallocated, as it means an sfx is currently playing in that page.

int8_t                  sfx_page_reference_count[NUM_SFX_PAGES];    // number of active sfx in this page. incremented/decremented as sounds start and stop playing
cache_node_page_count_t sfxcache_nodes[NUM_SFX_PAGES];
int8_t                  sfxcache_tail;
int8_t                  sfxcache_head;
// int8_t in_sound = false;



#define VALID_IRQ(irq) (((irq) >= 0) && ((irq) <= 15))

#define INVALID_IRQ 0xFF



// todo this is 16 bit 
// need to handle 8 bit case too...
uint8_t IRQ_TO_INTERRUPT_MAP[16] =
    {
        INVALID_IRQ, INVALID_IRQ, 0x0A, 	   0x0B,
        INVALID_IRQ, 0x0D, 		  INVALID_IRQ, 0x0F,
        INVALID_IRQ, INVALID_IRQ, 0x72, 	   0x73,
        0x74, 		 INVALID_IRQ, INVALID_IRQ, 0x77};



uint8_t __near SB_ReadDSP();
/*
uint8_t __near SB_ReadDSP() {
    int16_t port = sb_port + SB_DataAvailablePort;
    uint8_t count = 0xFF;

    while (count) {
        if (inp(port) & 0x80) {
            return inp(sb_port + SB_ReadPort);
        }
        count--;
    }

    return SB_Error;
}
*/

int16_t __near SB_ResetDSP();
/*
int16_t __near SB_ResetDSP(){
    volatile uint8_t count;
    int16_t port = sb_port + SB_ResetPort;

    outp(port, 1);

    count = 0xFF;
    while (count){
		count--;
	}

    outp(port, 0);
    count = 100;

    while (count) {
        if (SB_ReadDSP() == SB_Ready) {
            return SB_OK;
            break;
        }
        count--;
    } 

    return SB_CardNotReady;
}
*/
uint8_t __near SB_ReadMixer(uint8_t reg);
void __near SB_WriteMixer(uint8_t reg,uint8_t data);

/*
uint8_t __near SB_ReadMixer(uint8_t reg) {
    outp(sb_port + SB_MixerAddressPort, reg);
    return inp(sb_port + SB_MixerDataPort);
}

void __near SB_WriteMixer(uint8_t reg,uint8_t data) {
    outp(sb_port + SB_MixerAddressPort, reg);
    outp(sb_port + SB_MixerDataPort, data);
}
*/
void __near SB_SaveVoiceVolume();
void __near SB_RestoreVoiceVolume() ;

/*
void __near SB_SaveVoiceVolume() {
    switch (SB_MixerType) {
		case SB_TYPE_SBPro:
		case SB_TYPE_SBPro2:
			SB_OriginalVoiceVolumeLeft  = SB_ReadMixer(SB_MIXER_SBProVoice);
			break;

		case SB_TYPE_SB16:
			SB_OriginalVoiceVolumeLeft  = SB_ReadMixer(SB_MIXER_SB16VoiceLeft);
			SB_OriginalVoiceVolumeRight = SB_ReadMixer(SB_MIXER_SB16VoiceRight);
			break;
		}
}

void __near SB_RestoreVoiceVolume() {
    switch (SB_MixerType) {
		case SB_TYPE_SBPro:
		case SB_TYPE_SBPro2:
			SB_WriteMixer(SB_MIXER_SBProVoice, SB_OriginalVoiceVolumeLeft);
			break;

		case SB_TYPE_SB16:
			SB_WriteMixer(SB_MIXER_SB16VoiceLeft,  SB_OriginalVoiceVolumeLeft);
			SB_WriteMixer(SB_MIXER_SB16VoiceRight, SB_OriginalVoiceVolumeRight);
			break;
    }
}
*/



#define SB_DSP_SignedBit 0x10
#define SB_DSP_StereoBit 0x20

#define SB_DSP_UnsignedMonoData 	0x00
#define SB_DSP_SignedMonoData 		(SB_DSP_SignedBit)
#define SB_DSP_UnsignedStereoData 	(SB_DSP_StereoBit)
#define SB_DSP_SignedStereoData 	(SB_DSP_SignedBit | SB_DSP_StereoBit)

#define SB_DSP_Halt8bitTransfer 		0xD0
#define SB_DSP_Continue8bitTransfer 	0xD4
#define SB_DSP_Halt16bitTransfer 		0xD5
#define SB_DSP_Continue16bitTransfer 	0xD6
#define SB_DSP_Reset 					0xFFFF



// todo hardcode these params, writes
void __near SB_DSP1xx_BeginPlayback();
void __near SB_DSP2xx_BeginPlayback();
void __near SB_DSP4xx_BeginPlayback();
/*
void __near SB_DSP1xx_BeginPlayback() {
    int16_t_union sample_length;
	sample_length.hu = SB_MixBufferSize - 1;

    // Program DSP to play sound
    SB_WriteDSP(0x14);	// SB DAC 8 bit init, no autoinit
    SB_WriteDSP(sample_length.bu.bytelow);
    SB_WriteDSP(sample_length.bu.bytehigh);

    

}

void __near SB_DSP2xx_BeginPlayback() {

    int16_t_union sample_length;
	sample_length.hu = SB_MixBufferSize - 1;

    SB_WriteDSP(0x48);	// set block length
    SB_WriteDSP(sample_length.bu.bytelow);
    SB_WriteDSP(sample_length.bu.bytehigh);


	SB_WriteDSP(0x1C);	// SB DAC init, 8 bit auto init



}

void __near SB_DSP4xx_BeginPlayback() {
    int16_t_union sample_length;
	sample_length.hu = SB_MixBufferSize - 1;

	

    // Program DSP to play sound
    SB_WriteDSP(0xC6);	// 8 bit dac
    SB_WriteDSP(SB_DSP_UnsignedMonoData);	// transfer mode
    SB_WriteDSP(sample_length.bu.bytelow);
    SB_WriteDSP(sample_length.bu.bytehigh);


}
*/
typedef struct
{
    //int valid;	// 2 and 4 invalid
    // int Mask;	0x0A, 0xD4
    // int Mode;	0x0B, 0xD6
    // int Clear;	0x0C, 0xD8
    uint8_t page;
    uint8_t address;
    uint8_t length;
} DMA_PORT;

#define DMA_MaxChannel_16_BIT 7

// todo do we need 16bit ports...? 
/*
DMA_PORT DMA_PortInfo[8] =
    {
        {0x87, 0x00, 0x01},
        {0x83, 0x02, 0x03},
        {0x81, 0x04, 0x05},
        {0x82, 0x06, 0x07},
        {0x8F, 0xC0, 0xC2},
        {0x8B, 0xC4, 0xC6},
        {0x89, 0xC8, 0xCA},
        {0x8A, 0xCC, 0xCE},
};
*/

#define DMA_ERROR 0
#define DMA_OK 1
int8_t __near SB_DMA_VerifyChannel(uint8_t channel);

/*
int8_t __near SB_DMA_VerifyChannel(uint8_t channel) {

	if (channel > DMA_MaxChannel_16_BIT) {
        return DMA_ERROR;
    } else if (channel == 2 || channel == 4) {	// invalid dma channels i guess
        return DMA_ERROR;
    }

    return DMA_OK;
}
*/

int16_t __near DMA_SetupTransfer(uint8_t channel, uint16_t length) ;

/*
int16_t __near DMA_SetupTransfer(uint8_t channel, uint16_t length) {
    
    if (SB_DMA_VerifyChannel(channel) == DMA_OK) {


    	DMA_PORT __near* port = &DMA_PortInfo[channel];
        uint8_t  channel_select = channel & 0x3;
    	uint16_t transfer_length;
		fixed_t_union addr;
		
		addr.wu = (uint32_t)sb_dmabuffer;
		addr.hu.fracbits = addr.hu.fracbits + (addr.hu.intbits << 4) & 0xFFFF;  // equals offset (?)
		addr.hu.intbits = (addr.hu.intbits >> 4) & 0xFF00;		// equals page


        if (channel > 3) {	// 16 bit port
			addr.hu.fracbits = addr.hu.fracbits >> 1;	// shift offset. high bit is wrong, but doesnt affect our impl.

            // Convert the length in bytes to the length in words
            transfer_length = (length + 1) >> 1;

            // The length is always one less the number of bytes or words
            // that we're going to send
        } else {			// 8 bit port

			// offset already set.
            // The length is always one less the number of bytes or words
            // that we're going to send
            transfer_length = length;
        }

		transfer_length--;

        // Mask off DMA channel
        outp(channel < 4 ? 	0x0A: 0xD4, 4 | channel_select);

        // Clear flip-flop to lower byte with any data
        outp(channel < 4 ? 	0x0C: 0xD8, 0);

        // Set DMA mode
        // switch (DMA_AutoInitRead) {
		// 	case DMA_SingleShotRead:
		// 		outp(port->mode, 0x48 | channel_select);
		// 		break;
		// 	case DMA_SingleShotWrite:
		// 		outp(port->mode, 0x44 | channel_select);
		// 		break;
		//	case DMA_AutoInitRead:
				outp(channel < 4 ? 	0x0B: 0xD6, 0x58 | channel_select);
		//		break;
		// 	case DMA_AutoInitWrite:
		// 		outp(port->mode, 0x54 | channel_select);
		// 		break	;
        // }

        // Send address


        outp(port->address, addr.bu.fracbytelow);
        outp(port->address, addr.bu.fracbytehigh);

        // Send page
        outp(port->page, addr.bu.intbytehigh);

        // Send length
        outp(port->length, transfer_length);		// lo
        outp(port->length, transfer_length >> 8);	// hi

        // enable DMA channel
        outp(channel < 4 ? 	0x0A: 0xD4, channel_select);

	    return DMA_OK;
    } else {
		return DMA_ERROR;
	}

}
*/      
int8_t __near SB_SetupDMABuffer(uint16_t buffer_size);

/*
int8_t __near SB_SetupDMABuffer(uint16_t buffer_size) {
    int8_t dma_channel = sb_dma_8;

    if (DMA_SetupTransfer(dma_channel, buffer_size) == DMA_ERROR) {
        return SB_Error;
    }

    sb_dma = dma_channel;

    
    return SB_OK;
}
*/

void __near SB_EnableInterrupt() ;
void __near SB_DisableInterrupt();
/*
void __near SB_EnableInterrupt() {
    uint8_t mask;

    // Unmask system interrupt
    if (sb_irq < 8) {
        mask = inp(0x21) & ~(1 << sb_irq);
        outp(0x21, mask);
    } else {

        mask = inp(0xA1) & ~(1 << (sb_irq - 8));
        outp(0xA1, mask);

        mask = inp(0x21) & ~(1 << 2);
        outp(0x21, mask);
    }
}

void __near SB_DisableInterrupt(){
    int mask;

    // Restore interrupt mask
    if (sb_irq < 8) {
        mask = inp(0x21) & ~(1 << sb_irq);
        mask |= SB_IntController1Mask & (1 << sb_irq);
        outp(0x21, mask);
    } else {
        mask = inp(0x21) & ~(1 << 2);
        mask |= SB_IntController1Mask & (1 << 2);
        outp(0x21, mask);

        mask = inp(0xA1) & ~(1 << (sb_irq - 8));
        mask |= SB_IntController2Mask & (1 << (sb_irq - 8));
        outp(0xA1, mask);
    }
}

*/
int8_t __near SB_DMA_EndTransfer(int8_t channel);
/*
int8_t __near SB_DMA_EndTransfer(int8_t channel) {

    if (SB_DMA_VerifyChannel(channel) == DMA_OK) {

    // int Mask;	0x0A, 0xD4
    // int Mode;	0x0B, 0xD6
    // int Clear;	0x0C, 0xD8

        // Mask off DMA channel
        outp(channel < 4 ? 	0x0A: 0xD4, 4 | (channel & 0x3));

        // Clear flip-flop to lower byte with any data
        outp(channel < 4 ? 	0x0C: 0xD8, 0);

		return DMA_OK;
    }

    return DMA_ERROR;
}

*/




// void __near SB_SetMixMode(){
    // todo is this even needed?
/*
    //todo sb pro check

    //sb pro needs to set mixer to mono?
    uint8_t data;

    outp(sb_port+SB_MixerAddressPort, 0x0E);
    // make sure stereo is off
    data = inp(sb_port+SB_MixerDataPort);
    data &= ~0x02;  // turn off stereo flag...
    outp(sb_port+SB_MixerDataPort, 0x0E);
    SB_SetPlaybackRate(SAMPLE_RATE_11_KHZ_UINT);
    */
// }

void __near SB_SetPlaybackRate(int16_t sample_rate);

/*

void __near SB_SetPlaybackRate(int16_t sample_rate){
 
    if (SB_DSP_Version.hu < SB_DSP_Version4xx){

        // Set playback rate
        if (sample_rate == SAMPLE_RATE_22_KHZ_UINT){
            SB_WriteDSP(0x40);
            // SB_WriteDSP(0xE9);  // 22
            SB_WriteDSP(0xD2);  // 22khz
        } else {
            SB_WriteDSP(0x40);
            // SB_WriteDSP(0xD2);  // 11khz
            SB_WriteDSP(0xA5);  // 11khz
        }


    } else{
        int16_t_union sample_rate_bytes;
        sample_rate_bytes.hu = sample_rate;
        // Set playback rate
        SB_WriteDSP(SB_DSP_Set_DA_Rate);
        SB_WriteDSP(sample_rate_bytes.bu.bytehigh);
        SB_WriteDSP(sample_rate_bytes.bu.bytelow);

        // Set recording rate
        SB_WriteDSP(SB_DSP_Set_AD_Rate);
        SB_WriteDSP(sample_rate_bytes.bu.bytehigh);
        SB_WriteDSP(sample_rate_bytes.bu.bytelow);
    }
}

*/

void __near SB_StopPlayback();

/*
void __near SB_StopPlayback(){

	SB_DisableInterrupt();

    SB_WriteDSP(SB_DSP_Halt8bitTransfer);   // halt command

    // Disable the DMA channel
    // if (SB_MixMode & SB_SIXTEEN_BIT){
        // SB_DMA_EndTransfer(sb_dma_16);
    // } else {
        SB_DMA_EndTransfer(sb_dma_8);
    // }

	SB_WriteDSP(0xD3);	// speaker off

    // sfx_playing = false;
    SB_CardActive = false;

}
*/
int8_t __near SB_SetupPlayback();
/*
int8_t __near SB_SetupPlayback(){
	// todo double?
    byte __far * sbbuffer;
	SB_StopPlayback();
    SB_SetMixMode();

    if (SB_SetupDMABuffer(SB_TotalBufferSize) == SB_Error){
        return SB_Error;
    }

    _fmemset(sb_dmabuffer, 0x80, SB_TotalBufferSize);

    SB_SetPlaybackRate(SAMPLE_RATE_11_KHZ_UINT);

    SB_EnableInterrupt();


	// Turn on Speaker
    SB_WriteDSP(0xD1);

    //SB_TransferLength = MixBufferSize; 
    
    //  Program the sound card to start the transfer.
    
	if (SB_DSP_Version.hu < SB_DSP_Version2xx) {
		SB_DSP1xx_BeginPlayback();
    } else if (SB_DSP_Version.hu < SB_DSP_Version4xx) {
        SB_DSP2xx_BeginPlayback();
    } else {
        SB_DSP4xx_BeginPlayback();
    }
    SB_CardActive = true;

    return SB_OK;


}
*/

// void __near SB_SetVolume(uint8_t volume){
//     if (SB_MixerType == SB_TYPE_SB16) {
//         SB_WriteMixer(SB_MIXER_SB16VoiceLeft, volume & 0xf8);
//         SB_WriteMixer(SB_MIXER_SB16VoiceRight, volume & 0xf8);
  
//     } else if (SB_MixerType == SB_TYPE_SBPro){
//         SB_WriteMixer(SB_SBProVoice, (volume & 0xF) + (volume >> 4));

//     } 
// }



uint16_t __near SB_GetDSPVersion();

/*
uint16_t __near SB_GetDSPVersion() {

    SB_WriteDSP(0xE1);	// get version

    SB_DSP_Version.bu.bytehigh = SB_ReadDSP();
    SB_DSP_Version.bu.bytelow  = SB_ReadDSP();

    if ((SB_DSP_Version.b.bytehigh == SB_Error) ||
        (SB_DSP_Version.b.bytelow  == SB_Error)) {
        return SB_Error;
    }

	// SB_DSP_Version.hu = 0x101;
    // printf("DSP Version detected:  %x\n", SB_DSP_Version.hu);

    if (SB_DSP_Version.hu >= SB_DSP_Version4xx) {
        SB_MixerType = SB_TYPE_SB16;
    } else if (SB_DSP_Version.hu >= SB_DSP_Version3xx) {
        SB_MixerType = SB_TYPE_SBPro;
    } else if (SB_DSP_Version.hu >= SB_DSP_Version2xx) {
        SB_MixerType = SB_TYPE_NONE;
    } else {
        SB_MixerType = SB_TYPE_NONE;
    }

    return SB_DSP_Version.hu;
}
*/

void __near SB_Shutdown();
/*
void __near SB_Shutdown(){
    // sfx_playing = false;

	SB_StopPlayback();
    SB_RestoreVoiceVolume();
    SB_ResetDSP();  // todo why does this fail?

    // Restore the original interrupt		
    if (sb_irq >= 8) {
        // IRQ_RestoreVector(sb_int);
    }


    locallib_dos_setvect_old(IRQ_TO_INTERRUPT_MAP[sb_irq], SB_OldInt);

    // SB_CallBack = null;
    // SB_Installed = false;


}
*/

int16_t __near  SB_InitCard();
/*
int16_t __near  SB_InitCard(){
	int8_t status;

	sb_irq      = snd_SBirq;
	sb_dma_8    = snd_SBdma;
	sb_port 	= snd_SBport;

    // Save the interrupt masks
    SB_IntController1Mask = inp(0x21);
    SB_IntController2Mask = inp(0xA1);
	status = SB_ResetDSP();

    if (status == SB_OK) {
		uint8_t sb_int;
		uint8_t used_dma;
		// sfx_playing = false;
		SB_GetDSPVersion();
        SB_SaveVoiceVolume();

        SB_SetPlaybackRate(SAMPLE_RATE_11_KHZ_UINT);
        // SB_SetMixMode();
		
        used_dma = sb_dma_8;

		if (SB_DMA_VerifyChannel(used_dma) == DMA_ERROR) {
			return SB_Error;
		}
		sb_dma = used_dma;
        // Install our interrupt handler
        
        if (!VALID_IRQ(sb_irq)) {
            return (SB_Error);
        }

		// todo make IRQ_TO_INTERRUPT_MAP logic handle 8 bit (single dma controller etc) machines right
        sb_int = IRQ_TO_INTERRUPT_MAP[sb_irq];
        if (sb_int == INVALID_IRQ) {
            return SB_Error;
        }


        SB_OldInt = locallib_dos_getvect(sb_int);
        locallib_dos_setvect_old(sb_int, SB_ServiceInterrupt);

        return  SB_OK;
    }


	return status;

}
*/

// just 0 to linear rising n to 255..
/*
uint8_t sfx_mix_table_2[512];
    

void __near S_CreateVolumeTable(){
    int16_t i;
    memset(&sfx_mix_table_2[000], 0x00, 128);
    memset(&sfx_mix_table_2[384], 0xFF, 128);

    for (i = 128; i < 384; i++){
        sfx_mix_table_2[i] = (i - 128);
    }

}
*/

void __far S_InitSFXCache();

/*
void __far S_InitSFXCache(){
    // initialize sfx cache at app start
    int8_t i;
        // just run thru the whole bunch in one go instead of multiple 
    for ( i = 0; i < NUM_SFX_PAGES; i++) {
        sfxcache_nodes[i].prev = i+1; // Mark unused entries
        sfxcache_nodes[i].next = i-1; // Mark unused entries
        sfxcache_nodes[i].pagecount = 0;
        sfxcache_nodes[i].numpages = 0;
		sfx_free_bytes[i] = 64;
        sfx_page_reference_count[i] = 0;

    }  

    
    for (i = 0; i < NUMSFX; i++){
        sfx_data[i].cache_position.bu.bytehigh = SOUND_NOT_IN_CACHE;
    }


    sfxcache_head = 0;
    sfxcache_tail = NUM_SFX_PAGES-1;

    sfxcache_nodes[sfxcache_head].next = -1;
    sfxcache_nodes[sfxcache_tail].prev = -1;
    // S_CreateVolumeTable();
    


}
*/
void __near  SB_StartInit();
/*
void __near  SB_StartInit(){


    if (SB_InitCard() == SB_OK){
        if (SB_SetupPlayback() == SB_OK){
            DEBUG_PRINT_NOARG("Sound Blaster SFX Engine Initailized!..\n");
            S_InitSFXCache();
        } else {
            DEBUG_PRINT_NOARG("\nSB INIT Error A\n");
            snd_SfxDevice = snd_none;

        }

    } else {
        DEBUG_PRINT_NOARG("\nSB INIT Error B\n");
        snd_SfxDevice = snd_none;
    }

    // nodes, etc now initialized in S_InitSFXCache which is called by S_SetSfxVolume earlier in S_Init
}
*/

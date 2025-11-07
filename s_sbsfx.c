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

void __near SB_SetPlaybackRate(int16_t sample_rate);
void __near SB_DSP1xx_BeginPlayback();



extern void( __interrupt __far *SB_OldInt)(void);
extern int16_t sb_port;
extern int16_t sb_dma;
extern int16_t sb_irq;
extern int8_t  sb_dma_8;
extern int16_t SB_IntController1Mask;
extern int16_t SB_IntController2Mask;
extern int8_t  SB_CardActive;
extern int16_t_union SB_DSP_Version;
extern uint8_t SB_MixerType;
extern uint8_t SB_OriginalVoiceVolumeLeft;
extern uint8_t SB_OriginalVoiceVolumeRight;
extern uint8_t SB_Mixer_Status;
extern uint8_t current_sampling_rate;
extern uint8_t last_sampling_rate;
extern int8_t  change_sampling_to_22_next_int;
extern int8_t  change_sampling_to_11_next_int;
extern int8_t  in_first_buffer;
extern int8_t  sfx_page_reference_count[NUM_SFX_PAGES];    // number of active sfx in this page. incremented/decremented as sounds start and stop playing
extern cache_node_page_count_t sfxcache_nodes[NUM_SFX_PAGES];
extern int8_t  sfxcache_tail;
extern int8_t  sfxcache_head;

extern uint8_t sfx_mix_table_2[512];




#define MAX_VOLUME_SFX 0x7F
#define SFX_MAX_VOLUME		127
// 64
#define BUFFERS_PER_EMS_PAGE 16384 / 256
// 63
#define BUFFERS_PER_EMS_PAGE_MASK (BUFFERS_PER_EMS_PAGE - 1)





// #define ENABLE_SFX_LOGGING 1
#ifdef ENABLE_SFX_LOGGING


void __near logcacheevent(char a, char b){
    int8_t current = sfxcache_tail;
    int8_t i = 0;
    int8_t j = 0;
    if (in_sound){
        return;
    } else {

        // FILE* fp = fopen("cache.txt", "ab");
        // fputc(a, fp);
        // fputc(' ', fp);
        // fputc('0' + (b / 100), fp);
        // fputc('0' + ((b % 100) / 10), fp);
        // fputc('0' + (b % 10), fp);
        // fputc(' ', fp);
        // fputc('0' + sfxcache_tail, fp);
        // fputc(' ', fp);
        // fputc('0' + sfxcache_head, fp);
        // fputc(' ', fp);
        // fputc(' ', fp);

        // for (j = 0; j < NUM_SFX_PAGES; j ++){
        //     fputc('0' + sfx_page_reference_count[j], fp);
        //     fputc(' ', fp);
        // }

        // fputc(' ', fp);

        // for (j = 0; j < NUM_SFX_PAGES; j ++){
        //     fputc('0' + sfxcache_nodes[j].pagecount, fp);
        //     fputc(' ', fp);
        // }

        // fputc(' ', fp);

        // for (j = 0; j < NUM_SFX_PAGES; j ++){
        //     fputc('0' + (sfx_free_bytes[j]/10), fp);
        //     fputc('0' + (sfx_free_bytes[j]%10), fp);
        //     fputc(' ', fp);
        // }
        
        // fputc(' ', fp);
        
        while (current != -1){
            // fputc('0' + sfxcache_nodes[current].prev, fp);
            // fputc('0' + current, fp);
            // fputc('0' + sfxcache_nodes[current].next, fp);
            // fputc(' ', fp);
            current = sfxcache_nodes[current].next;
            i++;
        }

        // fputc('\n', fp);
        // fclose(fp);

        if (i != NUM_SFX_PAGES){
            I_Error("cache loop?");
        }
        if (sfxcache_nodes[sfxcache_tail].prev != -1){
            I_Error("bad tail?");
        }
        if (sfxcache_nodes[sfxcache_head].next != -1){
            I_Error("bad head?");
        }

        for (i = 0; i < NUM_SFX_PAGES; i++){
            if (sfx_page_reference_count[i] < 0){
                I_Error("bad refcount?");
            }
            if (sfx_free_bytes[i] > BUFFERS_PER_EMS_PAGE){
                I_Error("bad freebytes?");
            }
        }

            if((forwardmove[0] != 0x19) || 
                (forwardmove[1] != 0x32) || 
                (sidemove[0] != 0x18) || 
                (sidemove[1] != 0x28)){
                    I_Error("leak detected? %i %i", a, b);

            }
    }
}

#else

#define logcacheevent(a, b) 

#endif

void __near S_IncreaseRefCount(uint8_t cachepage);
/*
void __near S_IncreaseRefCount(uint8_t cachepage){
    if (sfxcache_nodes[cachepage].numpages){
        uint8_t currentpage = cachepage;
        // find first then iterate over them all
        while (sfxcache_nodes[currentpage].pagecount != 1){
            currentpage = sfxcache_nodes[currentpage].prev;  // or prev?
        }
        // found first, now subtract from each one...
        while (sfxcache_nodes[currentpage].pagecount != sfxcache_nodes[currentpage].numpages){
            sfx_page_reference_count[currentpage]++;
            currentpage = sfxcache_nodes[currentpage].next;  // or prev?
        }
        sfx_page_reference_count[currentpage]++;    // last one

    } else {
        sfx_page_reference_count[cachepage]++;
    }
}*/
void __near S_DecreaseRefCount(int8_t voice_index);

/*
void __near S_DecreaseRefCount(int8_t voice_index){
    uint8_t cachepage = sfx_data[sb_voicelist[voice_index].sfx_id & SFX_ID_MASK].cache_position.bu.bytehigh; // if this is ever FF then something is wrong?
    uint8_t numpages =  sfxcache_nodes[cachepage].numpages; // number of pages of this allocation, or the page it is a part of

    logcacheevent('c', cachepage);
    if (numpages){
        uint8_t currentpage = cachepage;
        logcacheevent('e', numpages);
        // find first then iterate over them all
        while (sfxcache_nodes[currentpage].pagecount != 1){
            currentpage = sfxcache_nodes[currentpage].prev;  // or prev?
        }
        // found first, now subtract from each one...
        while (sfxcache_nodes[currentpage].pagecount != sfxcache_nodes[currentpage].numpages){
            sfx_page_reference_count[currentpage]--;
            currentpage = sfxcache_nodes[currentpage].next;  // or prev?
            // if (sfx_page_reference_count[currentpage] < 0){
            //     I_Error ("bad a");
            // }
        }
        sfx_page_reference_count[currentpage]--;  // do the last page too
        // if (sfx_page_reference_count[currentpage] < 0){
        //     I_Error ("bad b");
        // }


    } else {
        sfx_page_reference_count[cachepage]--;
        // if (sfx_page_reference_count[cachepage] < 0){
        //     I_Error ("bad c");
        // }

    }           

}
*/
// todo inline this eventually..

// contains logic for moving an element back one spot in the cache.
// has to account for contiguous multipage allocations and has some ugly logic for that.
void __near S_MoveCacheItemBackOne(int8_t currentpage);

/*
void __near S_MoveCacheItemBackOne(int8_t currentpage){

    // todo single item case but doesnt handle multi item case!
    // todo also doesnt handle tail case!

    // these are same for single item move.
    int8_t prev_startpoint = currentpage; // oldest/LRU
    int8_t next_startpoint = currentpage; // newest/MRU

    // we are iterating from head to tail, going prev each step.
    // so we have encountered a bad index  that must be moved next towards head.
    // but we must move all its contiguous allocations, so iterate prev until we find it's end.

    if (sfxcache_nodes[prev_startpoint].numpages){
        while (sfxcache_nodes[prev_startpoint].pagecount != 1){
            prev_startpoint = sfxcache_nodes[prev_startpoint].prev;
        }
    }
    
    // now prev and next represent the ends of the allocation whether thats single or multi page.

    // prev_startpoint B
    // next_startpoint C

    {

        // if swap is part of a multipage... need to get its start/endpoint!

        int8_t swap_tail = sfxcache_nodes[next_startpoint].next; // D
        int8_t swap_head = swap_tail;
        int8_t nextnext;

        // currentpage is B
        int8_t prev = sfxcache_nodes[prev_startpoint].prev; // A

        if (sfxcache_nodes[swap_head].numpages){
            while (sfxcache_nodes[swap_head].pagecount != sfxcache_nodes[swap_head].numpages){
                swap_head = sfxcache_nodes[swap_head].next;
            }
        }
        nextnext = sfxcache_nodes[swap_head].next;    // E

        //  tail/prev <---      ----> head/next
        //       A B C D E becomes A D B C E
        
        // update cache head if its been updated.
        if (nextnext != -1){
            sfxcache_nodes[nextnext].prev    = next_startpoint;
        } else {
            sfxcache_head = next_startpoint;
        }
        if (prev != -1){
            sfxcache_nodes[prev].next    = swap_tail;
        } else {
            // change tail?
            // presumably sfxcache_tail WAS prev_startpoint.
            sfxcache_tail = swap_tail;
        }
        
        sfxcache_nodes[swap_head].next   = prev_startpoint;
        sfxcache_nodes[swap_tail].prev        = prev;

        sfxcache_nodes[next_startpoint].next = nextnext;
        sfxcache_nodes[prev_startpoint].prev = swap_head;
    }
}
*/      

void __near S_UpdateLRUCache();

/**/
void __near S_UpdateLRUCache(){

    // iterate thru the cache and make sure that all in-use (reference count nonzero)
    // pages are clumped together in the head. this way we can assume theres no 
    // 'swiss cheese' instances where there are LRU gaps between evictable and
    // in-use pages. All evictable pages should be contiguous starting from head.
    int8_t currentpage = sfxcache_head;
    boolean found_evictable = false;

    // todo handle tail!
    while (currentpage != -1){
        if (found_evictable){
            // everything from this point on should be count 0...
            if (sfx_page_reference_count[currentpage] != 0){
                // problem! move this back to next
                // this breaks moving the two from a contiguous one.
                // fix is to skip all pages of a multi page
                S_MoveCacheItemBackOne(currentpage); 

            }

        } else {
            if (sfx_page_reference_count[currentpage] == 0){
                // from here on they should all be 0...
                found_evictable = true;
            }
        }
        // if multipage...
        if (sfxcache_nodes[currentpage].numpages){
            // get to the last page
            while (sfxcache_nodes[currentpage].pagecount != 1){
                currentpage = sfxcache_nodes[currentpage].prev;
            }
        }
        currentpage = sfxcache_nodes[currentpage].prev;
	}
    

}

void __near S_MarkSFXPageMRU(int8_t index) {

	int8_t prev;
	int8_t next;
	int8_t pagecount;
	int8_t previous_next;
	int8_t lastindex;
	int8_t lastindex_prev;
	int8_t index_next;

	if (index == sfxcache_head) {
		return;
	}

	pagecount = sfxcache_nodes[index].pagecount;
	// if pagecount is nonzero, then this is a pre-existing allocation which is multipage.
	// so we want to find the head of this allocation, and check if it's the head.

	if (pagecount){
		// if this is multipage, then pagecount is nonzero.
		
		// could probably be unrolled in asm
	 	while (sfxcache_nodes[index].numpages != sfxcache_nodes[index].pagecount){
			index = sfxcache_nodes[index].next;
		}

		if (index == sfxcache_head) {
			return;
		}

		// there are going to be cases where we call with numpages = 0, 
		// but the allocation is sharing a page with the last page of a
		// multi-page allocation. in this case, we want to back up and update the
		// whole multi-page allocation.
		
	}

	if (sfxcache_nodes[index].numpages){
		// multipage  allocation being updated.
		
		// we know its pre-existing because numpages is set on the node;
		// that means all the inner pages' next/prevs set and pagecount/numpages are also already set
		// no need to set all that stuff, just the relevant outer allocations's prev/next.
		// and update head/tail
	

		lastindex = index;
		while (sfxcache_nodes[lastindex].pagecount != 1){
			lastindex = sfxcache_nodes[lastindex].prev;
		}
		
		lastindex_prev = sfxcache_nodes[lastindex].prev;
		index_next = sfxcache_nodes[index].next;

		if (sfxcache_tail == lastindex){
			sfxcache_tail = index_next;
			sfxcache_nodes[index_next].prev = -1;
		} else {
			sfxcache_nodes[lastindex_prev].next = index_next;
			sfxcache_nodes[index_next].prev = lastindex_prev;
		}

		sfxcache_nodes[lastindex].prev = sfxcache_head;
		sfxcache_nodes[sfxcache_head].next = lastindex;
		// head's next doesnt change directly. it changes indirectly if index_prev changes.

		sfxcache_nodes[index].next = -1;
		sfxcache_head = index;

		return;
	} else {
		// handle the simple one page case.

		prev = sfxcache_nodes[index].prev;
		next = sfxcache_nodes[index].next;

		if (index == sfxcache_tail) {
			sfxcache_tail = next;
		} else {
			sfxcache_nodes[prev].next = next; 
		}

		sfxcache_nodes[next].prev = prev;  // works in either of the above cases. prev is -1 if tail.

		sfxcache_nodes[index].prev = sfxcache_head;
		sfxcache_nodes[index].next = -1;

		// pagecount/numpages dont have to be zeroed - either p_setup 
		// sets it to 0 in the initial case, or EvictCache in later cases.
		//sfxcache_nodes[index].pagecount = 0;
		//sfxcache_nodes[index].numpages  = 0;

		sfxcache_nodes[sfxcache_head].next = index;
		
		
		sfxcache_head = index;
		return;

	}


}


// note: numpages is 1-4, not 0-3 here.
// this function needs to always leave the cache in a workable state...
// if we remove excess pages due to the removed pages being part of a
// multi-page allocation, then those now unused pages should be appropriately
// put at the back of the queue so they will be the next loaded into.
// the evicted pages are also moved to the front. numpages/pagecount are filled in by the code after this
int8_t __near S_EvictSFXPage(int8_t numpages){

	//todo revisit these vars.
	int16_t evictedpage;
	int16_t currentpage;
	int8_t i;

	int8_t previous_next;

    // if (numpages)
    //     return -1;

    #ifdef DETAILED_BENCH_STATS
        sfxcacheevictcount++;
    #endif

	currentpage = sfxcache_tail;

	// go back enough pages to allocate them all.
	for (i = 0; i < numpages-1; i++){
		currentpage = sfxcache_nodes[currentpage].next;
	}

	evictedpage = currentpage;

	// currentpage is the LRU page we can remove in which
	// there is enough room to allocate numpages pages


	//prevmost is tail (LRU)
	//nextmost is head (MRU)

    // when we have a multipage: nextmost plays first, then prev page

	// need to evict at least numpages pages
	// we'll remove the tail, up to numpages...
	// if thats part of a multipage allocation, we'll remove from that page until the end of the multipage allocaiton too.
	// in that case, we leave extra deallocated pages in the tail.

 
	// true if 0 page allocation or 1st page of a multi-page
	while (sfxcache_nodes[evictedpage].numpages != sfxcache_nodes[evictedpage].pagecount){
		evictedpage = sfxcache_nodes[evictedpage].next;
	}

        // check all pages for ref count
    {
		int8_t checkpage = evictedpage;
    	while (checkpage != -1){
            if (sfx_page_reference_count[checkpage]){
                // the minimum required pages to evict overlapped with an in use page!
                // fail gracefully.
                return -1;
            }
            checkpage = sfxcache_nodes[checkpage].prev;
        }
    }


    // from evicted page back to tail.
	while (evictedpage != -1){

    	// clear cache data that was pointing to the page
        // zero these out..

        //todo make this a word write
		sfxcache_nodes[evictedpage].pagecount = 0;
		sfxcache_nodes[evictedpage].numpages = 0;

			//todo put these next to each other in memory and loop in one go!

		for (i = 0; i < NUMSFX; i++){
			if ((sfx_data[i].cache_position.bu.bytehigh) == evictedpage){
				sfx_data[i].cache_position.bu.bytehigh = SOUND_NOT_IN_CACHE;
			}
		}

        // if (sfx_page_reference_count[evictedpage]){
        //     I_Error("bad eviction!");
        // }


		sfx_free_bytes[evictedpage] = BUFFERS_PER_EMS_PAGE;
		evictedpage = sfxcache_nodes[evictedpage].prev;
	}	


	// connect old tail and old head.
	sfxcache_nodes[sfxcache_tail].prev = sfxcache_head;
	sfxcache_nodes[sfxcache_head].next = sfxcache_tail;


	// current page is next head
	//previous_head = sfxcache_head;
	previous_next = sfxcache_nodes[currentpage].next;

	sfxcache_head = currentpage;
	sfxcache_nodes[currentpage].next = -1;


	// new tail
	sfxcache_nodes[previous_next].prev = -1;
	sfxcache_tail = previous_next;

	return currentpage; // sfxcache_head
}


void __near SB_Service_Mix22Khz(){
	
	int8_t i;
	int8_t remaining_22khz = false;	

	int8_t sound_played = 0;	// first sound copies. 2nd and more add. if no sounds played, clear buffer.

	for (i = 0; i < numChannels; i++){

		if (sb_voicelist[i].sfx_id & PLAYING_FLAG){

			// Keep track of current buffer


			if (sb_voicelist[i].currentsample >= sb_voicelist[i].length){
				// sound done playing. 

                sb_voicelist[i].sfx_id &= SFX_ID_MASK; // turn off playing flag
                S_DecreaseRefCount(i);                    



			} else {

                if (sb_voicelist[i].volume == 0){
                    // dont play/mix sounds this low? 
                    if (sb_voicelist[i].samplerate){
                        sb_voicelist[i].currentsample += SB_TransferLength;
                    } else {
                        sb_voicelist[i].currentsample += SB_TransferLength >> 1;
                    }


                } else {

                    uint16_t copy_length = SB_TransferLength;
                    uint16_t copy_offset;
                    int8_t   do_second_copy = false;
                    int16_t_union  cache_pos = sfx_data[sb_voicelist[i].sfx_id & SFX_ID_MASK].cache_position;
                    int8_t  use_page = cache_pos.bu.bytehigh;
                    if (sb_voicelist[i].currentsample >= 16384){
                        // todo rol 2 in asm
                        int8_t pageadd = sb_voicelist[i].currentsample >> 14;;
                        while (pageadd){
                            use_page = sfxcache_nodes[use_page].prev;
                            pageadd--;
                        }
                        // I_Error("page add %i %i", sb_voicelist[i].currentsample, page_add);
                    }

                    
                    Z_QuickMapSFXPageFrame(use_page); // todo not necers                    
                    // form the offset.
                    cache_pos.bu.bytehigh = cache_pos.bu.bytelow;
                    cache_pos.bu.bytelow = 0;

                    if (sb_voicelist[i].samplerate){
                        remaining_22khz = true;
                    }
                    
                    // if not the first copy, just copy to the next buffer
                    if (sb_voicelist[i].currentsample){
                        // copy only to doubled buffer
                        if (in_first_buffer){
                            copy_offset = SB_TransferLength;    
                        } else {
                            copy_offset = 0;
                        }
                    // if the first copy, copy two buffers worth.
                    } else {
                        // double buffer for first write!
                        // detect the run-over over the dma end buffer...
                        
                        if (!in_first_buffer){
                            do_second_copy = true;
                            copy_offset = SB_TransferLength;
                        } else {
                            copy_length = SB_DoubleBufferLength;
                            copy_offset = 0;
                        }

                    }

                    // stupid c89
                    {                
                        uint8_t __far * dma_buffer = MK_FP(sb_dmabuffer_segment, copy_offset);
                        uint8_t __far * source  = (uint8_t __far *) MK_FP(SFX_PAGE_SEGMENT_PTR, cache_pos.hu + (sb_voicelist[i].currentsample & 16383));

                        uint16_t remaining_length = sb_voicelist[i].length - sb_voicelist[i].currentsample;
                        int8_t volume = sb_voicelist[i].volume;
                        // if (application_volume != MAX_APPLICATION_VOLUME){
                        //     int16_t_union volume_result;
                        //     volume_result.hu = FastMul8u8u(volume, application_volume);
                        //     volume = volume_result.bu.bytehigh;
                        // }
                        while (true){

                            if (remaining_length < copy_length){
                                copy_length = remaining_length;
                            }



                            // MANUAL MIX?

                            // volume is 0-127. if 128+ then use full volume.                                         
                            // todo change this from a constant check to a check for current sfx volume level (in settings)
                            if (volume == MAX_VOLUME_SFX){
                                // max volume. just use the bytes directly
                                if (!sound_played){
                                    // first sound copied...
                                    
                                    if (sb_voicelist[i].samplerate){
                                        _fmemcpy(dma_buffer, source, copy_length);
                                    } else {
                                        int8_t j;
                                        for (j = 0; j < copy_length>>1; j++){
                                            dma_buffer[2*j]   = source[j];
                                            dma_buffer[2*j+1] = source[j];
                                        }
                                    }



                                } else {
                                    uint16_t j;
                                    // subsequent sounds added
                                    // obviously needs imrpovement...
                                    if (sb_voicelist[i].samplerate){
                                        for (j = 0; j < copy_length; j++){
                                            int16_t total = dma_buffer[j] + source[j];
                                            dma_buffer[j] = sfx_mix_table_2[total];
                                        }
                                    } else {
                                        for (j = 0; j < copy_length>>1; j++){
                                            int16_t total = dma_buffer[2*j] + source[j];
                                            dma_buffer[2*j] = sfx_mix_table_2[total];
                                            total = dma_buffer[2*j+1] + source[j];
                                            dma_buffer[2*j+1] = sfx_mix_table_2[total];

                                        }
                                    }
                                }
                            } else {
                                // DO VOLUME MIX

                                if (!sound_played){
                                    // first sound copied...
                                    uint16_t j;
                                    
                                    if (sb_voicelist[i].samplerate){


                                        for (j = 0; j < copy_length; j++){
                                            int16_t_union total;
                                            int8_t intermediate = (source[j] - 0x80);
                                            total.h = FastIMul8u8u(volume, intermediate) << 1;
                                            dma_buffer[j] = 0x80 + total.bu.bytehigh;

                                            // dma_buffer[j] = 0x80 + total.bu.bytehigh;   // divide by 256 means take the high byte
                                        }
                                    } else {
                                        for (j = 0; j < copy_length>>1; j++){
                                            int16_t_union total;
                                            int8_t intermediate = (source[j] - 0x80);
                                            uint8_t result;
                                            total.h = FastIMul8u8u(volume, intermediate) << 1;
                                            result = 0x80 + total.bu.bytehigh;
                                            // todo word copy
                                            dma_buffer[2*j] = result;
                                            dma_buffer[2*j+1] = result;  // divide by 256 means take the high byte
                                        }
                                    }

                                } else {
                                    uint16_t j;
                                    // subsequent sounds added
                                    // obviously needs imrpovement...
                                    if (sb_voicelist[i].samplerate){

                                        for (j = 0; j < copy_length; j++){
                                            int16_t_union total;
                                            int8_t intermediate = (source[j] - 0x80);
                                            total.h = FastIMul8u8u(volume, intermediate) << 1;
                                            total.bu.bytehigh += 0x80;
                                            total.hu = (dma_buffer[j] + total.bu.bytehigh);
                                            dma_buffer[j] = sfx_mix_table_2[total.hu];

                                            

                                        }
                                    } else {
                                        for (j = 0; j < copy_length>>1; j++){
                                            int16_t_union total;
                                            int16_t total2;
                                            int8_t intermediate = (source[j] - 0x80);
                                            total.h = FastIMul8u8u(volume, intermediate) << 1;
                                            total.bu.bytehigh += 0x80;
                                            
                                            total2 =   (dma_buffer[2*j+1] + total.bu.bytehigh);
                                            total.hu = (dma_buffer[2*j]  + total.bu.bytehigh);

                                            dma_buffer[2*j+0] = sfx_mix_table_2[total.hu];
                                            dma_buffer[2*j+1] = sfx_mix_table_2[total2];
                                            

                                        }
                                    }

                                }
                            }

                            if (!do_second_copy){
                                break;
                            }

                            // for when we are doing the first copy, but it runs over the edge of buffer and 
                            // we must reset to write to the start of the buffer for the 2nd buffer's write
                            
                            // todo generalize to larger #s than transfer length?
                            do_second_copy = false;

                            remaining_length -= copy_length;
                            if (!remaining_length){
                                break;  // if the sfx was less than a sample long i guess.
                            }
                            dma_buffer = sb_dmabuffer; // to start of buffer.
                            source     += copy_length;
                            sb_voicelist[i].currentsample += copy_length;
                        }
                    }
                    sound_played++;
                    if (sb_voicelist[i].samplerate){
                        sb_voicelist[i].currentsample += copy_length;
                    } else {
                        sb_voicelist[i].currentsample += copy_length >> 1;
                    }

                }


			}


		}


	}	// end for loop


	if (!remaining_22khz){
		change_sampling_to_11_next_int = true;
	}

}


void __near SB_Service_Mix11Khz(){
	int8_t i;
	int8_t sound_played = 0;	// first sound copies. 2nd and more add. if no sounds played, clear buffer.


	for (i = 0; i < numChannels; i++){

		if (sb_voicelist[i].sfx_id & PLAYING_FLAG){  
			
			// Keep track of current buffer


			if (sb_voicelist[i].currentsample >= sb_voicelist[i].length){
				// sound done playing. 

                // if (sb_voicelist[i].sfx_id == sfx_barexp){
                //     I_Error("sound done %i %i", sb_voicelist[i].currentsample, sb_voicelist[i].length);
                // }

                sb_voicelist[i].sfx_id &= SFX_ID_MASK; // turn off playing flag
                S_DecreaseRefCount(i);                    

			} else {

                if (sb_voicelist[i].volume == 0){
                    // dont play/mix sounds this low? 
                    sb_voicelist[i].currentsample += SB_TransferLength;
                } else {
                    uint16_t copy_length = SB_TransferLength;
                    uint16_t copy_offset;
                    int8_t   do_second_copy = false;
                    int16_t_union  cache_pos = sfx_data[sb_voicelist[i].sfx_id & SFX_ID_MASK].cache_position;
                    int8_t  use_page = cache_pos.bu.bytehigh;
                    if (sb_voicelist[i].currentsample >= 16384){
                        // todo rol 2 in asm and unroll while loop?
                        int8_t pageadd = sb_voicelist[i].currentsample >> 14;;
                        while (pageadd){
                            use_page = sfxcache_nodes[use_page].prev;
                            pageadd--;
                        }
                        // I_Error("page add %i %i", sb_voicelist[i].currentsample, page_add);
                    }

                    
                    Z_QuickMapSFXPageFrame(use_page); // todo not necers
                    
                    // logcacheevent(cache_pos.bu.bytehigh,  page_add);

                    // form the offset.
                    cache_pos.bu.bytehigh = cache_pos.bu.bytelow;
                    cache_pos.bu.bytelow = 0;
                    
                    // if not the first copy, just copy to the next buffer
                    if (sb_voicelist[i].currentsample){
                        // copy only to doubled buffer
                        if (in_first_buffer){
                            copy_offset = SB_TransferLength;    
                        } else {
                            copy_offset = 0;
                        }
                    // if the first copy, copy two buffers worth.
                    } else {
                        // double buffer for first write!
                        // detect the run-over over the dma end buffer...
                        
                        if (!in_first_buffer){
                            do_second_copy = true;
                            copy_offset = SB_TransferLength;
                        } else {
                            copy_length = SB_DoubleBufferLength;
                            copy_offset = 0;
                        }

                    }

                    // stupid c89
                    {                
                        uint8_t __far * dma_buffer = MK_FP(sb_dmabuffer_segment, copy_offset);
                        uint8_t __far * source  = (uint8_t __far *) MK_FP(SFX_PAGE_SEGMENT_PTR, cache_pos.hu + (sb_voicelist[i].currentsample & 16383));
                        uint16_t remaining_length = sb_voicelist[i].length - sb_voicelist[i].currentsample;
                        int8_t volume = sb_voicelist[i].volume;
                        // if (application_volume != MAX_APPLICATION_VOLUME){
                        //     int16_t_union volume_result;
                        //     volume_result.hu = FastMul8u8u(volume, application_volume);
                        //     volume = volume_result.bu.bytehigh;
                        // }
                        while (true){
                            // what if multiple sounds end early?

                            if (remaining_length < copy_length){
                                copy_length = remaining_length;
                            }


                            // MANUAL MIX?

                            // volume is 0-127. if 128+ then use full volume.                                         
                            // todo change this from a constant check to a check for current sfx volume level (in settings)
                            if (volume == MAX_VOLUME_SFX){
                                // max volume. just use the bytes directly
                                if (!sound_played){
                                    // first sound copied...
                                    _fmemcpy(dma_buffer, source, copy_length);
                                } else {
                                    uint16_t j;
                                    // subsequent sounds added
                                    // obviously needs imrpovement...
                                    for (j = 0; j < copy_length; j++){
                                        // fast bad approx 
                                        int16_t total = dma_buffer[j] + source[j];
                                        dma_buffer[j] = sfx_mix_table_2[total];

                                        // more correct. more slow
                                        // int16_t total = FastMul8u8u(sound_played, dma_buffer[j]) + source[j];
                                        // int16_t_union result = FastDiv16u_8u(total, (sound_played + 1));
                                        // dma_buffer[j] = result.bu.bytelow;


                                    }

                                }

                            } else {
                                if (!sound_played){
                                    // first sound copied...
                                    uint16_t j;
                                    
                                    for (j = 0; j < copy_length; j++){
                                        int16_t_union total;
                                        int8_t intermediate = (source[j] - 0x80);
                                        total.h = FastIMul8u8u(volume, intermediate) << 1;
                                        dma_buffer[j] = 0x80 + total.bu.bytehigh; // divide by 256 means take the high byte
                                    }

                                } else {
                                    uint16_t j;
                                    // subsequent sounds added
                                    // obviously needs imrpovement...
                                    for (j = 0; j < copy_length; j++){
                                        int16_t_union total;
                                        int8_t intermediate = (source[j] - 0x80);
                                        total.h = FastIMul8u8u(volume, intermediate) << 1;
                                        total.bu.bytehigh += 0x80;
                                        // fast bad approx 
                                        total.hu = (dma_buffer[j] + total.bu.bytehigh);
                                        dma_buffer[j] = sfx_mix_table_2[total.hu];

                                        // more correct. more slow
                                        // total.hu = FastMul8u8u(sound_played, dma_buffer[j]) + total.bu.bytehigh;
                                        // total = FastDiv16u_8u(total.hu, (sound_played + 1));
                                        // dma_buffer[j] = total.bu.bytelow;


                                        

                                    }

                                }
                            }

                            if (!do_second_copy){
                                break;
                            }

                            // for when we are doing the first copy, but it runs over the edge of buffer and 
                            // we must reset to write to the start of the buffer for the 2nd buffer's write
                            
                            // todo generalize to larger #s than transfer length?
                            do_second_copy = false;

                            remaining_length -= copy_length;
                            if (!remaining_length){
                                break;  // if the sfx was less than a sample long i guess.
                            }
                            dma_buffer = sb_dmabuffer; // to start of buffer.
                            source     += copy_length;
                            sb_voicelist[i].currentsample += copy_length;
                        }
                    }
                    sound_played++;

                    sb_voicelist[i].currentsample += copy_length;
                }

			}


		}

		// Call the caller's callback function
		// if (SB_CallBack != NULL) {
		//     MV_ServiceVoc();
		// }

		// send EOI to Interrupt Controller

	}	// end for loop


}



void __near continuecall();

void __near resetDS();

void __interrupt __far_func SB_ServiceInterrupt(void) {
    resetDS();  // interrupts need this...
    continuecall(); // note SS may be non FIXED_DS_SEGMENT!
}


void __near continuecall(){
	int8_t sample_rate_this_instance;
    uint8_t current_sfx_page = currentpageframes[SFX_PAGE_FRAME_INDEX];    // record current sfx page

    // Z_SavePageFrameState();

    // in_sound = true;
    if (in_first_buffer){
        in_first_buffer = false;
    } else {
        in_first_buffer = true;
    }

	if (change_sampling_to_22_next_int){
		change_sampling_to_22_next_int = 0;
		change_sampling_to_11_next_int = 0;
		if (current_sampling_rate == SAMPLE_RATE_11_KHZ_FLAG){
			current_sampling_rate = SAMPLE_RATE_22_KHZ_FLAG;
		}

		SB_SetPlaybackRate(SAMPLE_RATE_22_KHZ_UINT);
	} else if (change_sampling_to_11_next_int){
		change_sampling_to_11_next_int = 0;
		if (current_sampling_rate == SAMPLE_RATE_22_KHZ_FLAG){
			current_sampling_rate = SAMPLE_RATE_11_KHZ_FLAG;
		}

		SB_SetPlaybackRate(SAMPLE_RATE_11_KHZ_UINT);

	}

	sample_rate_this_instance = current_sampling_rate;

    // Acknowledge interrupt
    // Check if this is this an SB16 or newer
     if (SB_DSP_Version.hu >= SB_DSP_Version4xx) {
        outp(sb_port + SB_MixerAddressPort, 0x82);  //  MIXER_DSP4xxISR_Ack);

        SB_Mixer_Status = inp(sb_port + SB_MixerDataPort);

        // Check if a 16-bit DMA interrupt occurred
        if (SB_Mixer_Status & MIXER_16BITDMA_INT) {
            // Acknowledge 16-bit transfer interrupt

			inp(sb_port + 0x0F);	// SB_16BitDMAAck
        } else if (SB_Mixer_Status & MIXER_8BITDMA_INT) {

            inp(sb_port + SB_DataAvailablePort);
        } else {


			// Wasn't our interrupt.  Call the old one.
			_chain_intr(SB_OldInt);
		
	    }
    } else {
        // Older card - can't detect if an interrupt occurred.
        inp(sb_port + SB_DataAvailablePort);
    }


	// Continue playback on cards without autoinit mode
	if (SB_DSP_Version.hu < SB_DSP_Version2xx) {
        if (SB_CardActive){
            SB_DSP1xx_BeginPlayback();
        }
	}




    // initial zero buffer

    if (in_first_buffer){
        _fmemset(MK_FP(sb_dmabuffer_segment, SB_TransferLength), 0x80, SB_TransferLength);
    } else {
        _fmemset(MK_FP(sb_dmabuffer_segment, 0), 0x80, SB_TransferLength);
    }

    

	

	if (sample_rate_this_instance == SAMPLE_RATE_22_KHZ_FLAG){

//  22 KHZ MODE LOOP
//  22 KHZ MODE LOOP
//  22 KHZ MODE LOOP

		SB_Service_Mix22Khz();

	} else {

//  11 KHZ MODE LOOP
//  11 KHZ MODE LOOP
//  11 KHZ MODE LOOP


		SB_Service_Mix11Khz();
	}

	last_sampling_rate = current_sampling_rate;

    if (current_sfx_page != currentpageframes[SFX_PAGE_FRAME_INDEX]){
        // necessary because we might be mid-sfx load before the interrupt fired
        Z_QuickMapSFXPageFrame(current_sfx_page);
    }

    // Z_RestorePageFrameState();


    if (sb_irq > 7){
        outp(0xA0, 0x20);
    }

    outp(0x20, 0x20);
    // in_sound = false;

}



void __near SB_WriteDSP(byte value) {
    int16_t port = sb_port + SB_WritePort;
    uint16_t count = 0xFFFF;

    while (count) {
        if ((inp(port) & 0x80) == 0) {
            outp(port, value);
			return;
        }
        count--;
    }
}











/*
int8_t IRQ_RestoreVector(int8_t vector) {
    // Restore original interrupt handlers
    // DPMI set real mode vector
    regs.w.ax = 0x0201;
    regs.w.bx = vector;
    regs.w.cx = IRQ_RealModeSegment;
    regs.w.dx = IRQ_RealModeOffset;
    int386(0x31, &regs, &regs);

    regs.w.ax = 0x0205;
    regs.w.bx = vector;
    regs.w.cx = IRQ_ProtectedModeSelector;
    regs.x.edx = IRQ_ProtectedModeOffset;
    int386(0x31, &regs, &regs);

    // Free callback
    regs.w.ax = 0x304;
    regs.w.cx = IRQ_CallBackSegment;
    regs.w.dx = IRQ_CallBackOffset;
    int386x(0x31, &regs, &regs, &segregs);

    if (regs.x.cflag) {
        return 1;
    }

    return 0;
}
*/

void __near S_NormalizeSfxVolume(uint16_t offset, uint16_t length);
// void S_NormalizeSfxVolume(uint16_t offset, uint16_t length){
//     uint8_t __far* sfxbyte = MK_FP(SFX_PAGE_SEGMENT_PTR, offset);
//     int8_t multvolume = snd_SfxVolume;
//     uint16_t j;
    
//     for (j = 0; j < length; j++){
//         // multiply by 128 normalized. Take the high byte of a 8u 8u mul, shift left 1.
//         // have to also offset by 80 to get signed/unsigned
//         int16_t_union volume_result;
//         int8_t intermediate = sfxbyte[j] - 0x80;
//         volume_result.h = FastIMul8u8u(intermediate, multvolume) << 1;
//         volume_result.bu.bytehigh += 0x80;
//         sfxbyte[j] = volume_result.bu.bytehigh;

//     }

// }


int8_t __near S_LoadSoundIntoCache(sfxenum_t sfx_id){
    int8_t sfx_page;
    int16_t_union lumpsize = sfx_data[sfx_id].lumpsize;
    uint8_t sample_256_size = lumpsize.bu.bytehigh + (lumpsize.bu.bytelow ? 1 : 0);
    int16_t_union allocate_position;
    int8_t pagecount = sample_256_size >> 6;   // todo rol 2?
    // round up
    pagecount += (sample_256_size & BUFFERS_PER_EMS_PAGE_MASK) ? 1 : 0;

    allocate_position.hu = 0;
    logcacheevent('z', sample_256_size);
    if (pagecount == 1) {
        // todo iterate in head order?
        for (sfx_page = sfxcache_head; sfx_page != -1; sfx_page = sfxcache_nodes[sfx_page].prev){
            if (sample_256_size <= sfx_free_bytes[sfx_page]){
                allocate_position.bu.bytehigh = BUFFERS_PER_EMS_PAGE - sfx_free_bytes[sfx_page];  // keep track of where to put the sound
                // allocate_position.bu.bytelow = 0;
                sfx_free_bytes[sfx_page] -= sample_256_size;   // subtract...
                goto found_page;
            }
        }

        // evict_one:

        S_UpdateLRUCache();
        // lets locate a page to evict

        logcacheevent('v', 1);
        sfx_page = S_EvictSFXPage(1);
        logcacheevent('w', i);
        if (sfx_page == -1){
            return -1;
        } else {
            sfx_free_bytes[sfx_page] -= sample_256_size;
            logcacheevent('x', sfx_page);

        }
        // allocate_position.hu = 0;

        // continue to found_page

        found_page:

        // record page in high byte
        // record offset (multiplied by 256) in low byte.
        sfx_data[sfx_id].cache_position.bu.bytehigh = sfx_page;
        sfx_data[sfx_id].cache_position.bu.bytelow = allocate_position.bu.bytehigh;

        // I_Error("%lx %lx %i %i", sfx_data, sfx_data[sfx_id], sfx_data[sfx_id].cache_position.hu, sfx_id );
        
        // _disable();
        Z_QuickMapSFXPageFrame(sfx_page);
        // Note - in theory an interrupt for an SFX can fire here during 
        // this transfer and blow up our current SFX ems page. However
        // we make absolutely sure in the interrupt  to page the SFX page 
        // back to where its supposed to go.
        W_CacheLumpNumDirectWithOffset(
            sfx_data[sfx_id].lumpandflags & SOUND_LUMP_BITMASK, 
            MK_FP(SFX_PAGE_SEGMENT_PTR, allocate_position.hu), 
            0x18,           // skip header and padding.
            lumpsize.hu);   // num bytes..



        // loop here to apply application volume to sfx 
        if (snd_SfxVolume != MAX_VOLUME_SFX){
            S_NormalizeSfxVolume(allocate_position.hu, lumpsize.h);
        }

        // pad zeroes? todo maybe 0x80 or dont do
        _fmemset(MK_FP(SFX_PAGE_SEGMENT_PTR, allocate_position.hu + lumpsize.hu), 0, (0x100 - (lumpsize.bu.bytelow)) & 0xFF);  // todo: just NEG instruction?
        // _enable();


        // don't do this! it defaults to zero, and is reset to zero during eviction if necessary.
        // sfxcache_nodes[sfx_page].pagecount = 0;
        // sfxcache_nodes[sfx_page].numpages = 0;

        return 0;
        
    } else {
        int8_t j;
        // greater than 1 EMS page in size...
        for (sfx_page = sfxcache_head; sfx_page != -1; sfx_page = sfxcache_nodes[sfx_page].prev){
            int8_t currentpage = sfx_page;
            for (j = 0; j < pagecount; j++){
                if (currentpage == -1){
                    break;
                } else {
                    
                    if (sfx_free_bytes[currentpage] == BUFFERS_PER_EMS_PAGE){
                        currentpage = sfxcache_nodes[currentpage].prev;
                        continue;
                    } else {
                        break;
                    }
                }
            }
            
            if (j < pagecount){ // didnt find enough pages.
                continue;
            }

            // page sfx_page works.

            // allocate_position.hu = 0;    // page aligned. addr is 0...

            goto found_page_multiple;

        }

        // evict_multiple:
        S_UpdateLRUCache();

        sfx_page = S_EvictSFXPage(pagecount); // get the headmost
        allocate_position.hu = 0;

        if (sfx_page == -1){
            return -1;
        } 
        
        found_page_multiple:

        {
            int8_t j;
            uint16_t offset = 18;    // skip header and padding.
            int16_t lump = sfx_data[sfx_id].lumpandflags & SOUND_LUMP_BITMASK;
            int8_t currentpage = sfx_page;

            sfx_data[sfx_id].cache_position.bu.bytehigh = sfx_page;
            sfx_data[sfx_id].cache_position.bu.bytelow = 0;

            // iterate thru full pages
            for (j = 0; j < (pagecount-1); j++){
                sfxcache_nodes[currentpage].pagecount = pagecount - j;
                sfxcache_nodes[currentpage].numpages  = pagecount;

                // I_Error("%lx %lx %sfx_page %i", sfx_data, sfx_data[sfx_id], sfx_data[sfx_id].cache_position.hu, sfx_id );
                Z_QuickMapSFXPageFrame(currentpage);
                // Note - in theory an interrupt for an SFX can fire here during 
                // this transfer and blow up our current SFX ems page. However
                // we make absolutely sure in the interrupt  to page the SFX page 
                // back to where its supposed to go.
                W_CacheLumpNumDirectWithOffset(
                    lump, 
                    MK_FP(SFX_PAGE_SEGMENT_PTR, 0), 
                    offset,   
                    16384);   // num bytes..
                sfx_free_bytes[currentpage] = 0;

                    // loop here to apply application volume to sfx 
                
                if (snd_SfxVolume != MAX_VOLUME_SFX){
                    S_NormalizeSfxVolume(0, 16384);
                }

                currentpage = sfxcache_nodes[currentpage].prev;
                offset += 16384;

            }

            sfx_free_bytes[currentpage] -= sample_256_size & BUFFERS_PER_EMS_PAGE_MASK;
            // mark last page
            sfxcache_nodes[currentpage].pagecount = 1;
            sfxcache_nodes[currentpage].numpages = pagecount;

            // final case, leftover bytes...
            Z_QuickMapSFXPageFrame(currentpage);
            W_CacheLumpNumDirectWithOffset(
                    lump, 
                    MK_FP(SFX_PAGE_SEGMENT_PTR, 0), 
                    offset,           // skip header and padding.
                    lumpsize.hu & 16383);   // num bytes..

            // pad zeroes? todo maybe 0x80 or dont do
            _fmemset(MK_FP(SFX_PAGE_SEGMENT_PTR, lumpsize.hu & 16383), 0, (0x100 - (lumpsize.bu.bytelow)) & 0xFF);  // todo: just NEG instruction?

            if (snd_SfxVolume != MAX_VOLUME_SFX){
                S_NormalizeSfxVolume(0, lumpsize.hu & 16383);
            }


            return 0;
        }




    }
}


int8_t __far SFX_PlayPatch(sfxenum_t sfx_id, uint8_t sep, uint8_t vol){
    
    int8_t i;
    
    // vol should be 0-127

    if (vol > 127){
        // shouldnt happen?
        I_Error("bad vol! %i %i %i", sfx_id, sep, vol);
    }


    // I_Error("\n here %i %lx\n", W_LumpLength(110), lumpinfo9000[110].position);
    for (i = 0; i < numChannels;i++){
        if (!(sb_voicelist[i].sfx_id & PLAYING_FLAG)){
            // check if sound already in cache (using map lookup)
            if (sfx_data[sfx_id].cache_position.bu.bytehigh == SOUND_NOT_IN_CACHE){
                // todo return and use page as cache page ahead rather than another lookup..
                int8_t result = S_LoadSoundIntoCache(sfx_id);
                if (result == -1){
                    // couldnt make space in cache.
                    return -1; 
                }
            }

            _disable();

            sb_voicelist[i].sfx_id = sfx_id;
            sb_voicelist[i].currentsample = 0;
            sb_voicelist[i].samplerate = (sfx_data[sfx_id].lumpandflags & SOUND_22_KHZ_FLAG) ? 1 : 0;
            sb_voicelist[i].length     = sfx_data[sfx_id].lumpsize.hu;
            

            // ADD TO REFERENCE COUNT. do this whenever playing is set to true/false

            // Mark LRU for sfx here
            {
                int8_t cachepage = sfx_data[sfx_id].cache_position.bu.bytehigh;
                logcacheevent('0', sfx_id);
                S_IncreaseRefCount(cachepage);

                logcacheevent('+', sfx_id);
                S_MarkSFXPageMRU(cachepage);
                logcacheevent('~', cachepage);


                
                //todo apply volume from vol. 
                sb_voicelist[i].volume     = vol;
                // sb_voicelist[i].volume     = MAX_VOLUME_SFX;
                
                if (sb_voicelist[i].samplerate){
                    if (!current_sampling_rate){
                        change_sampling_to_22_next_int = 1;

                    }
                }

                // only do this at the very end.
                sb_voicelist[i].sfx_id |= PLAYING_FLAG;
                _enable();
                return i;
            }
        }
    }
    return -1;
}

void __far S_DecreaseRefCountFar(int8_t handle){
    S_DecreaseRefCount(handle);
}



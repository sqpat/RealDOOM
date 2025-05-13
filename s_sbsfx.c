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
#include <signal.h>
#include <bios.h>
#include <ctype.h>
#include <malloc.h>
#include "doomdef.h"
#include "i_system.h"

void __near SB_SetPlaybackRate(int16_t sample_rate);
void __near SB_DSP1xx_BeginPlayback();



void( __interrupt __far *SB_OldInt)(void);




#define MAX_VOLUME_SFX 0x7F
#define SFX_MAX_VOLUME		127




// actual variables that get set.
// todo: set from environment variable.
int16_t sb_port = -1;
int16_t sb_dma  = -1;
int16_t sb_irq  = -1;

int8_t sb_dma_16 = UNDEFINED_DMA;
int8_t sb_dma_8  = UNDEFINED_DMA;

int16_t     SB_IntController1Mask;
int16_t     SB_IntController2Mask;




int8_t  SB_CardActive = false;
int16_t_union SB_DSP_Version;
uint8_t SB_MixerType = SB_TYPE_NONE;
uint8_t SB_OriginalVoiceVolumeLeft = 255;
uint8_t SB_OriginalVoiceVolumeRight = 255;



// uint16_t SB_MixMode = 0; //SB_STEREO;
// uint16_t SB_MixMode = SB_STEREO | SB_SIXTEEN_BIT;
// uint16_t SB_MixMode = SB_SIXTEEN_BIT;



uint8_t SB_Mixer_Status;



uint8_t 				current_sampling_rate = SAMPLE_RATE_11_KHZ_FLAG;
uint8_t 				last_sampling_rate	  = SAMPLE_RATE_11_KHZ_FLAG;
int8_t 					change_sampling_to_22_next_int = 0;
int8_t 					change_sampling_to_11_next_int = 0;

int8_t   				in_first_buffer  = true;
                        // 240

// sfx cache is done by updating lru array ordering on sound start and play.
// anything with an >0 reference count cannot be deallocated, as it means an sfx is currently playing in that page.

// uint8_t                 sfx_page_lru[NUM_SFX_PAGES];                // recency, lru 
int8_t                  sfx_page_reference_count[NUM_SFX_PAGES];    // number of active sfx in this page. incremented/decremented as sounds start and stop playing
int8_t                  sfx_page_multipage_count[NUM_SFX_PAGES];    // 0 if its a single page allocation or > 0 means its a multipage allocation where 1 is the last, etc
cache_node_page_count_t sfxcache_nodes[NUM_SFX_PAGES];
int8_t                  sfxcache_tail;
int8_t                  sfxcache_head;
int8_t in_sound = false;

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
            if (sfx_free_bytes[i] > 64){
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
}

void __near S_DecreaseRefCount(int8_t voice_index){
    uint8_t cachepage = sfx_data[sb_voicelist[voice_index].sfx_id & SFX_ID_MASK].cache_position.bu.bytehigh; // if this is ever FF then something is wrong?
    uint8_t numpages =  sfxcache_nodes[cachepage].numpages; // number of pages of this allocation, or the page it is a part of
    int8_t startnode = cachepage;
    int8_t endnode   = startnode;
    logcacheevent('c', cachepage);
    // uint8_t numpages  = sb_voicelist[i].length >> 14; // todo rol 2
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
        }
        sfx_page_reference_count[currentpage]--;


    } else {
        sfx_page_reference_count[cachepage]--;
    }

}

// contains logic for moving an element back one spot in the cache.
// has to account for contiguous multipage allocations and has some ugly logic for that.
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
            
void __near S_UpdateLRUCache(){

    // iterate thru the cache and make sure that all in-use (reference count nonzero)
    // pages are clumped together in the head. this way we can assume theres no 
    // 'swiss cheese' instances where there are LRU gaps between evictable and
    // in-use pages. All evictable pages should be contiguous starting from head.
    int8_t currentpage = sfxcache_head;
    boolean found_evictable = false;

    // todo handle tail!
    while (currentpage != -1){
        logcacheevent('f', currentpage);
        if (found_evictable){
            // everything from this point on should be count 0...
            if (sfx_page_reference_count[currentpage] != 0){
                // problem! move this back to next
                logcacheevent('%', currentpage);
                // this breaks moving the two from a contiguous one.
                // fix is to skip all pages of a multi page
                S_MoveCacheItemBackOne(currentpage); 
                logcacheevent('$', found_evictable);

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
            logcacheevent('g', sfxcache_nodes[currentpage].numpages);
            while (sfxcache_nodes[currentpage].pagecount != 1){
                currentpage = sfxcache_nodes[currentpage].prev;
            }
        }
        logcacheevent('h', currentpage);
        logcacheevent('i', sfxcache_nodes[currentpage].prev);
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
	int8_t j;
	int16_t currentpage;
	int16_t k;
	int16_t l = 0;
	int8_t previous_next;

    // if (numpages)
    //     return -1;

    #ifdef DETAILED_BENCH_STATS
        sfxcacheevictcount++;
    #endif

	currentpage = sfxcache_tail;

	// go back enough pages to allocate them all.
	for (j = 0; j < numpages-1; j++){
		currentpage = sfxcache_nodes[currentpage].next;
        l++;
	}

	evictedpage = currentpage;

	// currentpage is the LRU page we can remove in which
	// there is enough room to allocate numpages pages


	//prevmost is tail (LRU)
	//nextmost is head (MRU)

	// need to evict at least numpages pages
	// we'll remove the tail, up to numpages...
	// if thats part of a multipage allocation, we'll remove from that page until the end of the multipage allocaiton too.
	// in that case, we leave extra deallocated pages in the tail.

 
	// true if 0 page allocation or 1st page of a multi-page
	while (sfxcache_nodes[evictedpage].numpages != sfxcache_nodes[evictedpage].pagecount){
		evictedpage = sfxcache_nodes[evictedpage].next;
        l++;
	}

    if (sfx_page_reference_count[evictedpage]){
        // the minimum required pages to evict overlapped with an in use page!
        // fail gracefully.

        return -1;
    }

    // if (l > 4){
    //     I_Error("huge dealloc?");
    // }

    // from evicted page back to tail.
	while (evictedpage != -1){

    	// clear cache data that was pointing to the page
        // zero these out..

        //todo make this a word write
		sfxcache_nodes[evictedpage].pagecount = 0;
		sfxcache_nodes[evictedpage].numpages = 0;

			//todo put these next to each other in memory and loop in one go!

		for (k = 0; k < NUMSFX; k++){
			if ((sfx_data[k].cache_position.bu.bytehigh) == evictedpage){
				sfx_data[k].cache_position.bu.bytehigh = SOUND_NOT_IN_CACHE;
			}
		}

        // if (sfx_page_reference_count[evictedpage]){
        //     I_Error("shouldn't happen!");
        // }


		sfx_free_bytes[evictedpage] = 64;
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
    uint16_t extra_zero_length = 0;
    uint8_t __far *extra_zero_copy_target;

	for (i = 0; i < NUM_SFX_TO_MIX; i++){

		if (!(sb_voicelist[i].sfx_id & PLAYING_FLAG)){

		} else {

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
                    int8_t   page_add = 0;
                    if (sb_voicelist[i].currentsample >= 16384){
                        // todo rol 2 in asm
                        page_add = sb_voicelist[i].currentsample >> 14;
                    }
                    
                    Z_QuickMapSFXPageFrame(cache_pos.bu.bytehigh + page_add);
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
                        uint8_t __far * source  = (uint8_t __far *) MK_FP(SFX_PAGE_SEGMENT, cache_pos.hu + (sb_voicelist[i].currentsample & 16383));

                        uint16_t remaining_length = sb_voicelist[i].length - sb_voicelist[i].currentsample;
                        int8_t volume = sb_voicelist[i].volume;
                        // if (application_volume != MAX_APPLICATION_VOLUME){
                        //     int16_t_union volume_result;
                        //     volume_result.hu = FastMul8u8u(volume, application_volume);
                        //     volume = volume_result.bu.bytehigh;
                        // }
                        while (true){

                            if (remaining_length < copy_length){
                                if (sound_played == 0){
                                    extra_zero_length = copy_length - remaining_length;
                                    extra_zero_copy_target = dma_buffer + remaining_length;
                                }
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
                                        for (j = 0; j < copy_length/2; j++){
                                            dma_buffer[2*j]   = source[j];
                                            dma_buffer[2*j+1] = source[j];
                                        }
                                    }

                                    if (extra_zero_length){
                                        _fmemset(dma_buffer + copy_length, 0x80, extra_zero_length);
                                    }


                                } else {
                                    uint16_t j;
                                    // subsequent sounds added
                                    // obviously needs imrpovement...
                                    if (sb_voicelist[i].samplerate){
                                        for (j = 0; j < copy_length; j++){
                                            int16_t total = dma_buffer[j] + source[j];
                                            dma_buffer[j] = total >> 1;
                                        }
                                    } else {
                                        for (j = 0; j < copy_length/2; j++){
                                            int16_t total = dma_buffer[2*j] + source[j];
                                            dma_buffer[2*j] = total >> 1;
                                            total = dma_buffer[2*j+1] + source[j];
                                            dma_buffer[2*j+1] = total >> 1;
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
                                        for (j = 0; j < copy_length/2; j++){
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

                                            dma_buffer[j] = (dma_buffer[j] + total.bu.bytehigh) >> 1;
                                            

                                        }
                                    } else {
                                        for (j = 0; j < copy_length/2; j++){
                                            int16_t_union total;
                                            int8_t intermediate = (source[j] - 0x80);
                                            total.h = FastIMul8u8u(volume, intermediate) << 1;
                                            total.bu.bytehigh += 0x80;

                                            dma_buffer[2*j] = (dma_buffer[2*j]    + total.bu.bytehigh) >> 1;
                                            dma_buffer[2*j+1] = (dma_buffer[2*j+1] + total.bu.bytehigh) >> 1;
                                            

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

    if (!sound_played){
        // todo: keep track of if buffer is silent so we dont do this pointlessly over and over
        _fmemset(sb_dmabuffer, 0x80, SB_TotalBufferSize);
    } else if ( sound_played == 1){
        if (extra_zero_length){

            _fmemset(extra_zero_copy_target, 0x80, extra_zero_length);
        }

    }


	if (!remaining_22khz){
		change_sampling_to_11_next_int = true;


	}

}


void __near SB_Service_Mix11Khz(){
	int8_t i;
	int8_t sound_played = 0;	// first sound copies. 2nd and more add. if no sounds played, clear buffer.
    uint16_t extra_zero_length = 0;
    uint8_t __far *extra_zero_copy_target = NULL;
	for (i = 0; i < NUM_SFX_TO_MIX; i++){

		if (!(sb_voicelist[i].sfx_id & PLAYING_FLAG)){  
            // not playing
		} else {

			
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
                    int8_t   page_add = 0;
                    if (sb_voicelist[i].currentsample >= 16384){
                        // todo rol 2 in asm
                        page_add = sb_voicelist[i].currentsample >> 14;
                        // I_Error("page add %i %i", sb_voicelist[i].currentsample, page_add);
                    }

                    // if (!sound_played){
                    //     Z_SavePageFrameState();
                    // }
                    
                    Z_QuickMapSFXPageFrame(cache_pos.bu.bytehigh + page_add);
                    
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
                        uint8_t __far * source  = (uint8_t __far *) MK_FP(SFX_PAGE_SEGMENT, cache_pos.hu + (sb_voicelist[i].currentsample & 16383));
                        uint16_t remaining_length = sb_voicelist[i].length - sb_voicelist[i].currentsample;
                        int8_t volume = sb_voicelist[i].volume;
                        // if (application_volume != MAX_APPLICATION_VOLUME){
                        //     int16_t_union volume_result;
                        //     volume_result.hu = FastMul8u8u(volume, application_volume);
                        //     volume = volume_result.bu.bytehigh;
                        // }
                        while (true){

                            if (remaining_length < copy_length){
                                if (sound_played == 0){
                                    extra_zero_length = copy_length - remaining_length;
                                    extra_zero_copy_target = dma_buffer + remaining_length;
                                }
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
                                        dma_buffer[j] = total >> 1;

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
                                        dma_buffer[j] = (dma_buffer[j] + total.bu.bytehigh) >> 1;

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

    if (!sound_played){
        // todo optimize and dont do this over and over...
        _fmemset(sb_dmabuffer, 0x80, SB_TotalBufferSize);
    } else if ( sound_played == 1){
        // Z_RestorePageFrameState();
        if (extra_zero_length){
            // examine this addr..
            _fmemset(extra_zero_copy_target, 0x80, extra_zero_length);
        }

    } else {
        // Z_RestorePageFrameState();

    }

}



void __near continuecall();

void	resetDS();

void __interrupt __far_func SB_ServiceInterrupt(void) {
    resetDS();  // interrupts need this...
    continuecall();
}


void __near continuecall(){
	int8_t sample_rate_this_instance;
    uint8_t current_sfx_page = currentpageframes[SFX_PAGE_FRAME_INDEX];    // record current sfx page

    // Z_SavePageFrameState();

    in_sound = true;
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
        Z_QuickMapSFXPageFrame(current_sfx_page);
    }

    // Z_RestorePageFrameState();


    if (sb_irq > 7){
        outp(0xA0, 0x20);
    }

    outp(0x20, 0x20);
    in_sound = false;

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

uint8_t __near SB_ReadDSP() {
    int16_t port = sb_port + SB_DataAvailablePort;
    uint16_t count;

    count = 0xFFFF;

    while (count) {
        if (inp(port) & 0x80) {
            return inp(sb_port + SB_ReadPort);
        }
        count--;
    }

    return SB_Error;
}

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

void __near SB_SetMixMode(){
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


}

#define DMA_8_MAX_CHANNELS 4
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

#define DMA_ERROR 0
#define DMA_OK 1

int8_t __near SB_DMA_VerifyChannel(uint8_t channel) {

	if (channel > DMA_MaxChannel_16_BIT) {
        return DMA_ERROR;
    } else if (channel == 2 || channel == 4) {	// invalid dma channels i guess
        return DMA_ERROR;
    }

    return DMA_OK;
}



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


int8_t __near SB_SetupDMABuffer(uint16_t buffer_size) {
    int8_t dma_channel;
    int8_t dma_status;

    // if (SB_MixMode & SB_SIXTEEN_BIT) {
        // dma_channel = sb_dma_16;
    // } else {
        dma_channel = sb_dma_8;
    // }

    if (dma_channel == UNDEFINED_DMA) {
        return SB_Error;
    }

    if (DMA_SetupTransfer(dma_channel, buffer_size) == DMA_ERROR) {
        return SB_Error;
    }

    sb_dma = dma_channel;

    
    return SB_OK;
}



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


uint8_t __near SB_ReadMixer(uint8_t reg) {
    outp(sb_port + SB_MixerAddressPort, reg);
    return inp(sb_port + SB_MixerDataPort);
}

void __near SB_WriteMixer(uint8_t reg,uint8_t data) {
    outp(sb_port + SB_MixerAddressPort, reg);
    outp(sb_port + SB_MixerDataPort, data);
}

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

void __far SB_Shutdown(){
    // sfx_playing = false;

	SB_StopPlayback();
    SB_RestoreVoiceVolume();
    SB_ResetDSP();  // todo why does this fail?

    // Restore the original interrupt		
    if (sb_irq >= 8) {
        // IRQ_RestoreVector(sb_int);
    }


    _dos_setvect(IRQ_TO_INTERRUPT_MAP[sb_irq], SB_OldInt);

    // SB_CallBack = null;
    // SB_Installed = false;


}



// void __near SB_SetVolume(uint8_t volume){
//     if (SB_MixerType == SB_TYPE_SB16) {
//         SB_WriteMixer(SB_MIXER_SB16VoiceLeft, volume & 0xf8);
//         SB_WriteMixer(SB_MIXER_SB16VoiceRight, volume & 0xf8);
  
//     } else if (SB_MixerType == SB_TYPE_SBPro){
//         SB_WriteMixer(SB_SBProVoice, (volume & 0xF) + (volume >> 4));

//     } 
// }




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

int16_t __far  SB_InitCard(){
	int8_t status;

	//todo get these from environment variables or config file.
	sb_irq      = FIXED_SB_IRQ;
	sb_dma_8    = FIXED_SB_DMA_8;
	sb_dma_16   = FIXED_SB_DMA_16;
	sb_port 	= FIXED_SB_PORT;
	SB_MixerType = SB_TYPE_SB16;



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
        SB_SetMixMode();

        // if (SB_Config.Dma16 != UNDEFINED)
        // {
        //     status = SB_DMA_VerifyChannel(SB_Config.Dma16);
        //     if (status == DMA_Error)
        //     {
        //         return (SB_Error);
        //     }
        // }
		
		// if (SB_MixMode & SB_SIXTEEN_BIT) {
			// used_dma = sb_dma_16;
		// } else {
			used_dma = sb_dma_8;
		// }

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


        SB_OldInt = _dos_getvect(sb_int);
        if (sb_irq < 8) {
			// 8 bit logic?

            _dos_setvect(sb_int, SB_ServiceInterrupt);

            // I_Error("%i %lx %lx %lx", sb_irq, SB_OldInt, _dos_getvect(sb_int), SB_ServiceInterrupt);

        } else {
			// 16 bit logic?
            // status = IRQ_SetVector(Interrupt, SB_ServiceInterrupt);
        }

        return  SB_OK;
    }


	return status;

}

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

    


}

void __far  SB_StartInit(){
    // todo move this crap into asm. dump the 
    // uint8_t i;
    // char lumpname[9];
    // uint16_t __far* scratch_lumplocation = (uint16_t __far*)0x50000000;
    // Z_QuickMapScratch_5000();
    // for (i = 1; i < NUMSFX; i++){
    //     combine_strings(lumpname, "DS", sfx_data[i].name);
    //     sfx_data[i].lumpandflags = (W_GetNumForName(lumpname) & SOUND_LUMP_BITMASK);
    //     sfx_data[i].lumpsize.hu  = W_LumpLength(sfx_data[i].lumpandflags & SOUND_LUMP_BITMASK) - 32;;
    //     sfx_data[i].cache_position.hu = 0xFFFF;
        
    //     if (sfx_data[i].lumpandflags == -1){
    //         // nonexistent in the wad
    //         sfx_data[i].lumpandflags = 0xFFFF;
    //         continue;
    //     }
        
    //     // DEBUG_PRINT("%i %i\n", i, sfx_data[i].lumpandflags & SOUND_LUMP_BITMASK);

    //     W_CacheLumpNumDirect(sfx_data[i].lumpandflags & SOUND_LUMP_BITMASK, (byte __far*)scratch_lumplocation);

    //     if ((scratch_lumplocation[1] == SAMPLE_RATE_22_KHZ_UINT)){
    //         sfx_data[i].lumpandflags |= SOUND_22_KHZ_FLAG;
    //     }


    // }

    // Z_QuickMapPhysics();

    if (SB_InitCard() == SB_OK){
        if (SB_SetupPlayback() == SB_OK){
            DEBUG_PRINT("Sound Blaster SFX Engine Initailized!..\n");

        } else {
            DEBUG_PRINT("\nSB INIT Error A\n");
            snd_SfxDevice = sfx_None;

        }

    } else {
        DEBUG_PRINT("\nSB INIT Error B\n");
        snd_SfxDevice = sfx_None;
    }

    // nodes, etc now initialized in S_InitSFXCache which is called by S_SetSfxVolume earlier in S_Init
}

void __far S_NormalizeSfxVolume(uint16_t offset, uint16_t length);
// void S_NormalizeSfxVolume(uint16_t offset, uint16_t length){
//     uint8_t __far* sfxbyte = MK_FP(SFX_PAGE_SEGMENT, offset);
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
    int8_t i;
    int16_t_union lumpsize = sfx_data[sfx_id].lumpsize;
    uint8_t sample_256_size = lumpsize.bu.bytehigh + (lumpsize.bu.bytelow ? 1 : 0);
    int16_t_union allocate_position;
    int8_t pagecount;
    logcacheevent('z', sample_256_size);
    if (sample_256_size <= 64) {
        // todo go in head order?
        for (i = 0; i < NUM_SFX_PAGES; i++){
            if (sample_256_size <= sfx_free_bytes[i]){
                allocate_position.bu.bytehigh = 64 - sfx_free_bytes[i];  // keep track of where to put the sound
                allocate_position.bu.bytelow = 0;
                sfx_free_bytes[i] -= sample_256_size;   // subtract...
                goto found_page;
            }
        }

        goto evict_one;
        
    } else {
        int8_t j = 0;
        
        pagecount = sample_256_size >> 6;   // todo rol 2?
        // greater than 1 EMS page in size...
        for (i = sfxcache_head; i != -1; i = i = sfxcache_nodes[i].prev){
            int8_t currentpage = i;
            for (j = 0; j <= pagecount; j++){
                if (currentpage == -1){
                    break;
                } else {
                    int8_t needed;


                    if (j < pagecount){
                        needed = 64;
                    } else {
                        needed = sample_256_size & 63;
                    }
                    
                    if (sfx_free_bytes[currentpage] >= needed){
                        currentpage = sfxcache_nodes[currentpage].prev;
                        continue;
                    } else {
                        break;
                    }
                }
            }
            
            if (j != (pagecount+1)){ // didnt find enough pages.
                continue;
            }

            // page i works.

            allocate_position.hu = 0;    // page aligned. addr is 0...
            currentpage = i;
            for (j = 0; j < pagecount; j++){
                sfx_free_bytes[currentpage] = 0;
                currentpage = sfxcache_nodes[currentpage].prev;
            }

            sfx_free_bytes[currentpage] -= sample_256_size & 63;
            goto found_page_multiple;

        }

        goto evict_multiple;
    }

    evict_one:

//uint8_t                 sfx_page_lru[NUM_SFX_PAGES];    // recency

    S_UpdateLRUCache();
    // lets locate a page to evict

    logcacheevent('v', 1);
    i = S_EvictSFXPage(1);
    logcacheevent('w', i);
    if (i == -1){
        return -1;
    } else {
        sfx_free_bytes[i] -= sample_256_size & 63;
        logcacheevent('x', i);

    }
    // continue to found_page


    // ! no location found! must evict.

    // todo... eviction code. then fall thru.
    // set position to FF.
    // set freebytes to 64
    // evict all in the page.

    found_page:

    // record page in high byte
    // record offset (multiplied by 256) in low byte.
    sfx_data[sfx_id].cache_position.bu.bytehigh = i;
    sfx_data[sfx_id].cache_position.bu.bytelow = allocate_position.bu.bytehigh;

    // I_Error("%lx %lx %i %i", sfx_data, sfx_data[sfx_id], sfx_data[sfx_id].cache_position.hu, sfx_id );
    Z_QuickMapSFXPageFrame(i);
    // Note - in theory an interrupt for an SFX can fire here during 
    // this transfer and blow up our current SFX ems page. However
    // we make absolutely sure in the interrupt  to page the SFX page 
    // back to where its supposed to go.
    W_CacheLumpNumDirectWithOffset(
        sfx_data[sfx_id].lumpandflags & SOUND_LUMP_BITMASK, 
        MK_FP(SFX_PAGE_SEGMENT, allocate_position.hu), 
        0x18,           // skip header and padding.
        lumpsize.hu);   // num bytes..

    // loop here to apply application volume to sfx 
    if (snd_SfxVolume != MAX_VOLUME_SFX){
        S_NormalizeSfxVolume(allocate_position.hu, lumpsize.h);
    }
     

    // don't do this! it defaults to zero, and is reset to zero during eviction if necessary.
    // sfxcache_nodes[i].pagecount = 0;
    // sfxcache_nodes[i].numpages = 0;

    return 0;

    evict_multiple:
    S_UpdateLRUCache();

    logcacheevent('s', pagecount+1);
    i = S_EvictSFXPage(pagecount+1);
    logcacheevent('t', i);
    if (i == -1){
        return -1;
    } else {
        int8_t j;
        int8_t currentpage = i;
        for (j = 0; j < pagecount;j++){
            sfx_free_bytes[currentpage] = 0;
            currentpage = sfxcache_nodes[currentpage].prev;
        }
        sfx_free_bytes[currentpage] -= sample_256_size & 63;
        logcacheevent('u', i);


    }

    //. continue to found_page_multiple    
    

    found_page_multiple:
    {
        int8_t j;
        uint16_t offset = 0;
        int16_t lump = sfx_data[sfx_id].lumpandflags & SOUND_LUMP_BITMASK;
        int8_t currentpage = i;
        // if (sfx_id > NUMSFX){
        //     I_Error("bad sfx!?");
        // }
        sfx_data[sfx_id].cache_position.bu.bytehigh = i;
        sfx_data[sfx_id].cache_position.bu.bytelow = 0;

        for (j = 0; j < pagecount; j++, offset += 16384){
            sfxcache_nodes[currentpage].pagecount = pagecount - j + 1;
            sfxcache_nodes[currentpage].numpages = pagecount + 1;

            // I_Error("%lx %lx %i %i", sfx_data, sfx_data[sfx_id], sfx_data[sfx_id].cache_position.hu, sfx_id );
            Z_QuickMapSFXPageFrame(currentpage);
            // Note - in theory an interrupt for an SFX can fire here during 
            // this transfer and blow up our current SFX ems page. However
            // we make absolutely sure in the interrupt  to page the SFX page 
            // back to where its supposed to go.
            W_CacheLumpNumDirectWithOffset(
                lump, 
                SFX_PAGE_ADDRESS, 
                0x18u + offset,           // skip header and padding.
                16384);   // num bytes..
            currentpage = sfxcache_nodes[currentpage].prev;

                // loop here to apply application volume to sfx 
            
            if (snd_SfxVolume != MAX_VOLUME_SFX){
                S_NormalizeSfxVolume(0, 16384);
            }


        }
        // mark last page
        sfxcache_nodes[currentpage].pagecount = 1;
        sfxcache_nodes[currentpage].numpages = pagecount + 1;

        // final case, leftover bytes...
        Z_QuickMapSFXPageFrame(currentpage);
        W_CacheLumpNumDirectWithOffset(
                lump, 
                SFX_PAGE_ADDRESS, 
                0x18u + offset,           // skip header and padding.
                lumpsize.hu & 16383);   // num bytes..

        if (snd_SfxVolume != MAX_VOLUME_SFX){
            S_NormalizeSfxVolume(0, lumpsize.hu & 16383);
        }

        
        return 0;
    }
}


int8_t __far SFX_PlayPatch(sfxenum_t sfx_id, uint8_t sep, uint8_t vol){
    
    int8_t i;
    
    // vol should be 0-127

    if (vol > 127){
        I_Error("bad vol!");
    }


    // I_Error("\n here %i %lx\n", W_LumpLength(110), lumpinfo9000[110].position);
    FORCE_5000_LUMP_LOAD = true;
    for (i = 0; i < NUM_SFX_TO_MIX;i++){
        if (!(sb_voicelist[i].sfx_id & PLAYING_FLAG)){
            // check if sound already in cache (using map lookup)
            if (sfx_data[sfx_id].cache_position.bu.bytehigh == SOUND_NOT_IN_CACHE){
                // todo return and use page as cache page ahead rather than another lookup..
                int8_t result = S_LoadSoundIntoCache(sfx_id);
                if (result == -1){
                    // couldnt make space in cache.
                    FORCE_5000_LUMP_LOAD = false;
                    return -1; 
                }
            }
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
                FORCE_5000_LUMP_LOAD = false;

                // only do this at the very end.
                sb_voicelist[i].sfx_id |= PLAYING_FLAG;
                return i;
            }
        }
    }
    FORCE_5000_LUMP_LOAD = false;
    return -1;
}

void __far SFX_StopPatch(int8_t handle){
    // if (handle >= 0 && handle < NUM_SFX_TO_MIX){
        // disable interrupts... otherwise we might turn it off mid-interrupt and double dec ref count
        _disable();
        if (sb_voicelist[handle].sfx_id & PLAYING_FLAG){
            sb_voicelist[handle].sfx_id &= SFX_ID_MASK;
            logcacheevent('a', handle);
            S_DecreaseRefCount(handle);
            logcacheevent('b', handle);
        }
        _enable();


    // }
}

boolean __far SFX_Playing(int8_t handle){
    if (handle >= 0 && handle < NUM_SFX_TO_MIX){
        return (sb_voicelist[handle].sfx_id & PLAYING_FLAG);
    }
    return false;
}

void __far SFX_SetOrigin(int8_t handle, uint8_t sep, uint8_t vol){
    if (sb_voicelist[handle].sfx_id & PLAYING_FLAG){
        sb_voicelist[handle].sep = sep;
        sb_voicelist[handle].volume = vol;
    }
}

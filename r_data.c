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
//      Preparation of data for rendering,
//      generation of lookups, caching, retrieval by name.
//

#include "i_system.h"
#include "z_zone.h"

#include "w_wad.h"

#include "doomdef.h"
#include "r_local.h"
#include "p_local.h"

#include "doomstat.h"
#include "r_data.h"
#include <dos.h>
#include "m_memory.h"
#include "m_near.h"


//
// Graphics.
// DOOM graphics for walls and sprites
// is stored in vertical runs of opaque pixels (posts).
// A column is composed of zero or more posts,
// a patch or sprite is composed of zero or more columns.
// 

 




//
// MAPTEXTURE_T CACHING
// When a texture is first needed,
//  it counts the number of composite columns
//  required in the texture and allocates space
//  for a column directory and any new columns.
// The directory will simply point inside other patches
//  if there is only one patch in a given column,
//  but any columns with multiple patches
//  will have new column_ts generated.
//


 
//todo: these can be inlined or made a faster algorithm later.


void __near R_MarkL1SpriteCacheLRU(int8_t index){

	if (spriteL1LRU[0] == index){
		return;
	} else if (spriteL1LRU[1] == index){
		spriteL1LRU[1] = spriteL1LRU[0];
		spriteL1LRU[0] = index;
		return;
	} else if (spriteL1LRU[2] == index){
		spriteL1LRU[2] = spriteL1LRU[1];
		spriteL1LRU[1] = spriteL1LRU[0];
		spriteL1LRU[0] = index;
		return;
	} else if (spriteL1LRU[3] == index){
		spriteL1LRU[3] = spriteL1LRU[2];
		spriteL1LRU[2] = spriteL1LRU[1];
		spriteL1LRU[1] = spriteL1LRU[0];
		spriteL1LRU[0] = index;
		return;
	}
}

void __near R_MarkL1SpriteCacheLRU3(int8_t index){

	spriteL1LRU[3] = spriteL1LRU[2];
	spriteL1LRU[2] = spriteL1LRU[1];
	spriteL1LRU[1] = spriteL1LRU[0];
	spriteL1LRU[0] = index;
	return;
}

//todo make this work as a jump table in asm like a switch block fall thru thing.
void __near R_MarkL1TextureCacheLRU(int8_t index){
	
	if (textureL1LRU[0] == index){
		return;
	} else if (textureL1LRU[1] == index){
		textureL1LRU[1] = textureL1LRU[0];
		textureL1LRU[0] = index;
		return;
	} else if (textureL1LRU[2] == index){
		textureL1LRU[2] = textureL1LRU[1];
		textureL1LRU[1] = textureL1LRU[0];
		textureL1LRU[0] = index;
		return;
	} else if (textureL1LRU[3] == index){
		textureL1LRU[3] = textureL1LRU[2];
		textureL1LRU[2] = textureL1LRU[1];
		textureL1LRU[1] = textureL1LRU[0];
		textureL1LRU[0] = index;
	} else if (textureL1LRU[4] == index){
		textureL1LRU[4] = textureL1LRU[3];
		textureL1LRU[3] = textureL1LRU[2];
		textureL1LRU[2] = textureL1LRU[1];
		textureL1LRU[1] = textureL1LRU[0];
		textureL1LRU[0] = index;
	} else if (textureL1LRU[5] == index){
		textureL1LRU[5] = textureL1LRU[4];
		textureL1LRU[4] = textureL1LRU[3];
		textureL1LRU[3] = textureL1LRU[2];
		textureL1LRU[2] = textureL1LRU[1];
		textureL1LRU[1] = textureL1LRU[0];
		textureL1LRU[0] = index;
	} else if (textureL1LRU[6] == index){
		textureL1LRU[6] = textureL1LRU[5];
		textureL1LRU[5] = textureL1LRU[4];
		textureL1LRU[4] = textureL1LRU[3];
		textureL1LRU[3] = textureL1LRU[2];
		textureL1LRU[2] = textureL1LRU[1];
		textureL1LRU[1] = textureL1LRU[0];
		textureL1LRU[0] = index;
	} else if (textureL1LRU[7] == index){
		textureL1LRU[7] = textureL1LRU[6];
		textureL1LRU[6] = textureL1LRU[5];
		textureL1LRU[5] = textureL1LRU[4];
		textureL1LRU[4] = textureL1LRU[3];
		textureL1LRU[3] = textureL1LRU[2];
		textureL1LRU[2] = textureL1LRU[1];
		textureL1LRU[1] = textureL1LRU[0];
		textureL1LRU[0] = index;
		return;
	}

}

void __near R_MarkL1TextureCacheLRU7(int8_t index){
	//todo: make this function live in the above in the asm.
	textureL1LRU[7] = textureL1LRU[6];
	textureL1LRU[6] = textureL1LRU[5];
	textureL1LRU[5] = textureL1LRU[4];
	textureL1LRU[4] = textureL1LRU[3];
	textureL1LRU[3] = textureL1LRU[2];
	textureL1LRU[2] = textureL1LRU[1];
	textureL1LRU[1] = textureL1LRU[0];
	textureL1LRU[0] = index;
	return;

}



 
/*

int setval = 0;
uint16_t thechecksum = 0;
int cachecount = 0;
int origcachecount = 0;

int8_t checkchecksum(int16_t l){
	uint16_t checkchecksum = 0;
	uint16_t i;
	uint16_t __far* data =  MK_FP(0x5000, 0);
	if (setval < 2){
		return 0;
	}
	for (i = 0; i <32767; i++){
		checkchecksum += data[i];
	}

	//if (checkchecksum != 40411u){
	if (checkchecksum != thechecksum){
		I_Error("gametic is %li %u %u %i %i %i", gametic, thechecksum, checkchecksum, l, cachecount, origcachecount);
		//return 1;
	}
	return 0;

}
*/





/*

void __near checkflatcache(int8_t id){
	int8_t node0;
	int8_t node1;
	int8_t node2;
	int8_t node3;
	int8_t node4;
	int8_t node5;
	cache_node_t far* nodelist  = flatcache_nodes;



	node0  = flatcache_l2_tail;
	node1  = nodelist[node0].next;
	node2  = nodelist[node1].next;
	node3  = nodelist[node2].next;
	node4  = nodelist[node3].next;
	node5  = nodelist[node4].next;

	if (id == 2){
	//I_Error("check %i %i %i %i %i %i %i %i %i %i", flatcache_l2_tail, flatcache_l2_head, id, node0, node1, node2, node3, node4, node5);

	}



	if (nodelist[flatcache_l2_tail].prev != -1){
		I_Error("tail non -1 prev %i", id);
	}
	if (nodelist[flatcache_l2_tail].next == -1){
		I_Error("tail -1 next %i", id);
	}

	if (nodelist[flatcache_l2_head].next != -1){
		I_Error("head non -1 next %i", id);
	}
	if (nodelist[flatcache_l2_head].prev == -1){
		I_Error("head -1 prev %i %i %i %i %i %i %i %i", id, node0, node1, node2, node3, node4, node5);
	}

	if (nodelist[node1].prev != node0){
		I_Error("A %i", id);
	}
	if (nodelist[node1].next != node2){
		I_Error("B %i", id);
	}

	if (nodelist[node2].prev != node1){
		I_Error("C %i", id);
	}
	if (nodelist[node2].next != node3){
		I_Error("D %i", id);
	}

	if (nodelist[node3].prev != node2){
		I_Error("E %i", id);
	}
	if (nodelist[node3].next != node4){
		I_Error("F %i", id);
	}

	if (nodelist[node4].prev != node3){
		I_Error("G %i", id);
	}
	if (nodelist[node4].next != node5){
		I_Error("H %i", id);
	}

	if (nodelist[node5].prev != node4){
		I_Error("I %i", id);
	}
	if (nodelist[node5].next != -1){
		I_Error("J %i", id);
	}




}
*/


/*
void __near checktexturecache(int8_t id){
	int8_t node0;
	int8_t node1;
	int8_t node2;
	int8_t node3;
	int8_t node4;
	int8_t node5;
	int8_t node6;
	int8_t node7;
	int8_t nodeprev;
	int8_t nodenow;
	int8_t j = 0;
	int8_t i = 0;
	
	cache_node_page_count_t far* nodelist  = texturecache_nodes;



	node0  = texturecache_l2_tail;
	node1  = nodelist[node0].next;
	node2  = nodelist[node1].next;
	node3  = nodelist[node2].next;
	node4  = nodelist[node3].next;
	node5  = nodelist[node4].next;
	node6  = nodelist[node5].next;
	node7  = nodelist[node6].next;

	if (id >= 30){
	  //I_Error("check %i %i %i \n%i %i %i %i %i %i %i %i ", texturecache_l2_tail, texturecache_l2_head, id, 
	  //node0, node1, node2, node3, node4, node5, node6, node7);

	}

	for (i = 0; i < NUM_TEXTURE_PAGES; i++){
		int8_t found = 0;
		nodenow = texturecache_l2_tail;
		for (j = 0; j < NUM_TEXTURE_PAGES; j++){
			if (nodenow == i){
				found = 1;
				break;
			}			
			nodenow = nodelist[nodenow].next;
		}
		if (!found){
			I_Error("not found %i \n %i %i %i \n%i %i %i %i %i %i %i %i ", i, texturecache_l2_tail, texturecache_l2_head, id, 
	  		node0, node1, node2, node3, node4, node5, node6, node7);

		}
	}

	nodenow = texturecache_l2_tail;

	{
		int8_t currenttarget = 0;
		int8_t lastpagecount = 0;
		for (j = 0; j < NUM_TEXTURE_PAGES; j++){
			if (!currenttarget){
				if (nodelist[nodenow].pagecount == 1){
					currenttarget = nodelist[nodenow].numpages;
					lastpagecount = 1;
				} else {
					if (nodelist[nodenow].pagecount){
						I_Error("non one first pagecount %i %i %i", nodelist[nodenow].pagecount, nodenow, id);
					} else 

					if (nodelist[nodenow].numpages){
						I_Error("pagecount zero and numpages nonzero %i %i", nodelist[nodenow].pagecount, nodelist[nodenow].numpages);
					}
				}
			} else {
				if (nodelist[nodenow].pagecount == lastpagecount+1){
					if (nodelist[nodenow].numpages != currenttarget){
						I_Error("numpages changed?  %i %i", nodelist[nodenow].pagecount, nodelist[nodenow].numpages);
					}
					if (nodelist[nodenow].pagecount == currenttarget){
						currenttarget = 0;
						lastpagecount = 0;
	
					}

				} else {
					I_Error("pagecount wrong order %i %i", nodelist[nodenow].pagecount, nodelist[nodenow].numpages);
				}
				
			}
			nodenow = nodelist[nodenow].next;
		}

		if (currenttarget){
			I_Error("page count ended at end? A");

		}
		if (lastpagecount){
			I_Error("page count ended at end? B");
		}

	}

	//for (j = 0; j < NUM_TEXTURE_PAGES; j++){

	//}

	//prevmost is tail (LRU)
	//nextmost is head (MRU)


	if (nodelist[texturecache_l2_tail].prev != -1){
		I_Error("tail non -1 prev %i", id);
	}
	if (nodelist[texturecache_l2_tail].next == -1){
		I_Error("tail -1 next %i", id);
	}

	if (nodelist[texturecache_l2_head].next != -1){
		I_Error("head non -1 next %i", id);
	}
	if (nodelist[texturecache_l2_head].prev == -1){
		I_Error("head -1 prev %i %i %i %i %i %i %i %i", id, node0, node1, node2, node3, node4, node5);
	}

	if (nodelist[node1].prev != node0){
		I_Error("A %i", id);
	}
	if (nodelist[node1].next != node2){
		I_Error("B %i", id);
	}

	if (nodelist[node2].prev != node1){
		I_Error("C %i", id);
	}
	if (nodelist[node2].next != node3){
		I_Error("D %i", id);
	}

	if (nodelist[node3].prev != node2){
		I_Error("E %i", id);
	}
	if (nodelist[node3].next != node4){
		I_Error("F %i", id);
	}

	if (nodelist[node4].prev != node3){
		I_Error("G %i", id);
	}
	if (nodelist[node4].next != node5){
		I_Error("H %i", id);
	}


	if (nodelist[node5].prev != node4){
		I_Error("I %i", id);
	}
	if (nodelist[node5].next != node6){
		I_Error("J %i", id);
	}


	if (nodelist[node6].prev != node5){
		I_Error("K %i", id);
	}
	if (nodelist[node6].next != node7){
		I_Error("L %i", id);
	}

	if (nodelist[node7].prev != node6){
		I_Error("M %i", id);
	}
	if (nodelist[node7].next != -1){
		I_Error("N %i", id);
	}

	if (node7 != texturecache_l2_head){
		I_Error("O %i", id);
	}




}

*/

/*
void __near checkspritecache(int8_t id){
	int8_t node0;
	int8_t node1;
	int8_t node2;
	int8_t node3;
	int8_t node4;
	int8_t node5;
	int8_t node6;
	int8_t node7;
	int8_t node8;
	int8_t node9;
	int8_t node10;
	int8_t node11;
	int8_t node12;
	int8_t node13;
	int8_t node14;
	int8_t node15;
	int8_t node16;
	int8_t node17;
	int8_t node18;
	int8_t node19;
	int8_t nodeprev;
	int8_t nodenow;
	int8_t j = 0;
	int8_t i = 0;
	
	cache_node_page_count_t far* nodelist  = spritecache_nodes;



	node0  = spritecache_l2_tail;
	node1  = nodelist[node0].next;
	node2  = nodelist[node1].next;
	node3  = nodelist[node2].next;
	node4  = nodelist[node3].next;
	node5  = nodelist[node4].next;
	node6  = nodelist[node5].next;
	node7  = nodelist[node6].next;
	node8  = nodelist[node7].next;
	node9  = nodelist[node8].next;
	node10  = nodelist[node9].next;
	node11  = nodelist[node10].next;
	node12  = nodelist[node11].next;
	node13  = nodelist[node12].next;
	node14  = nodelist[node13].next;
	node15  = nodelist[node14].next;
	node16  = nodelist[node15].next;
	node17  = nodelist[node16].next;
	node18  = nodelist[node17].next;
	node19  = nodelist[node18].next;


	for (i = 0; i < NUM_SPRITE_CACHE_PAGES; i++){
		int8_t found = 0;
		nodenow = spritecache_l2_tail;
		for (j = 0; j < NUM_SPRITE_CACHE_PAGES; j++){
			if (nodenow == i){
				found = 1;
				break;
			}			
			nodenow = nodelist[nodenow].next;
		}
		if (!found){
			I_Error("not found %i \n %i %i %i \n%i %i %i %i %i %i %i %i %i %i %i %i %i %i %i %i %i %i %i %i", i, spritecache_l2_tail, spritecache_l2_head, id, 
	  		node0, node1, node2, node3, node4, node5, node6, node7, node8, node9, node10, node11, node12, node13, node14, node15, node16, node17, node18, node19);

		}
	}

	nodenow = spritecache_l2_tail;

	{
		int8_t currenttarget = 0;
		int8_t lastpagecount = 0;
		for (j = 0; j < NUM_SPRITE_CACHE_PAGES; j++){
			if (!currenttarget){
				if (nodelist[nodenow].pagecount == 1){
					currenttarget = nodelist[nodenow].numpages;
					lastpagecount = 1;
				} else {
					if (nodelist[nodenow].pagecount){
						I_Error("non one first pagecount %i %i %i", nodelist[nodenow].pagecount, nodenow, id);

						//I_Error("not found %i \n %i %i %i \n%i %i %i %i %i %i %i %i %i %i %i %i %i %i %i %i %i %i %i %i", i, spritecache_l2_tail, spritecache_l2_head, id, 
						//node0, node1, node2, node3, node4, node5, node6, node7, node8, node9, node10, node11, node12, node13, node14, node15, node16, node17, node18, node19);

					} else 

					if (nodelist[nodenow].numpages){
						I_Error("pagecount zero and numpages nonzero %i %i", nodelist[nodenow].pagecount, nodelist[nodenow].numpages);
					}
				}
			} else {
				if (nodelist[nodenow].pagecount == lastpagecount+1){
					if (nodelist[nodenow].numpages != currenttarget){
						I_Error("numpages changed?  %i %i", nodelist[nodenow].pagecount, nodelist[nodenow].numpages);
					}
					if (nodelist[nodenow].pagecount == currenttarget){
						currenttarget = 0;
						lastpagecount = 0;
	
					}

				} else {
					I_Error("pagecount wrong order %i %i", nodelist[nodenow].pagecount, nodelist[nodenow].numpages);
				}
				
			}


			nodenow = nodelist[nodenow].next;
		}

		if (currenttarget){
			//I_Error("page count ended at end? A");

						I_Error("pagecount not found %i \n %i %i %i \n%i %i %i %i %i %i %i %i %i %i %i %i %i %i %i %i %i %i %i %i\n%i %i %i %i %i %i %i %i %i %i %i %i %i %i %i %i %i %i %i %i\n%i %i %i %i %i %i %i %i %i %i %i %i %i %i %i %i %i %i %i %i", i, spritecache_l2_tail, spritecache_l2_head, id, 
						node0, node1, node2, node3, node4, node5, node6, node7, node8, node9, node10, node11, node12, node13, node14, node15, node16, node17, node18, node19,
						nodelist[node0].pagecount, 
						nodelist[node1].pagecount, 
						nodelist[node2].pagecount, 
						nodelist[node3].pagecount, 
						nodelist[node4].pagecount, 
						nodelist[node5].pagecount, 
						nodelist[node6].pagecount, 
						nodelist[node7].pagecount, 
						nodelist[node8].pagecount, 
						nodelist[node9].pagecount, 
						nodelist[node10].pagecount, 
						nodelist[node11].pagecount, 
						nodelist[node12].pagecount, 
						nodelist[node13].pagecount, 
						nodelist[node14].pagecount, 
						nodelist[node15].pagecount, 
						nodelist[node16].pagecount, 
						nodelist[node17].pagecount, 
						nodelist[node18].pagecount, 
						nodelist[node19].pagecount,
						
								nodelist[node0].numpages, 
						nodelist[node1].numpages, 
						nodelist[node2].numpages, 
						nodelist[node3].numpages, 
						nodelist[node4].numpages, 
						nodelist[node5].numpages, 
						nodelist[node6].numpages, 
						nodelist[node7].numpages, 
						nodelist[node8].numpages, 
						nodelist[node9].numpages, 
						nodelist[node10].numpages, 
						nodelist[node11].numpages, 
						nodelist[node12].numpages, 
						nodelist[node13].numpages, 
						nodelist[node14].numpages, 
						nodelist[node15].numpages, 
						nodelist[node16].numpages, 
						nodelist[node17].numpages, 
						nodelist[node18].numpages, 
						nodelist[node19].numpages


						
						);


		}
		if (lastpagecount){
			I_Error("page count ended at end? B");
		}
	}

	//prevmost is tail (LRU)
	//nextmost is head (MRU)


	if (nodelist[spritecache_l2_tail].prev != -1){
		I_Error("tail non -1 prev %i", id);
	}
	if (nodelist[spritecache_l2_tail].next == -1){
		I_Error("tail -1 next %i", id);
	}

	if (nodelist[spritecache_l2_head].next != -1){
		I_Error("head non -1 next %i", id);
	}
	if (nodelist[spritecache_l2_head].prev == -1){
		I_Error("head -1 prev %i %i %i %i %i %i %i %i", id, node0, node1, node2, node3, node4, node5);
	}

	if (nodelist[node1].prev != node0){
		I_Error("AA %i", id);
	}
	if (nodelist[node1].next != node2){
		I_Error("BB %i", id);
	}

	if (nodelist[node2].prev != node1){
		I_Error("CC %i", id);
	}
	if (nodelist[node2].next != node3){
		I_Error("DD %i", id);
	}

	if (nodelist[node3].prev != node2){
		I_Error("EE %i", id);
	}
	if (nodelist[node3].next != node4){
		I_Error("FF %i", id);
	}

	if (nodelist[node4].prev != node3){
		I_Error("GG %i", id);
	}
	if (nodelist[node4].next != node5){
		I_Error("HH %i", id);
	}


	if (nodelist[node5].prev != node4){
		I_Error("II %i", id);
	}
	if (nodelist[node5].next != node6){
		I_Error("JJ %i", id);
	}


	if (nodelist[node6].prev != node5){
		I_Error("KK %i", id);
	}
	if (nodelist[node6].next != node7){
		I_Error("LL %i", id);
	}

	if (nodelist[node7].prev != node6){
		I_Error("MM %i", id);
	}
	if (nodelist[node7].next != node8){
		I_Error("NN %i", id);
	}

	if (nodelist[node8].prev != node7){
		I_Error("OO %i", id);
	}
	if (nodelist[node8].next != node9){
		I_Error("PP %i", id);
	}

	if (nodelist[node9].prev != node8){
		I_Error("QQ %i", id);
	}
	if (nodelist[node9].next != node10){
		I_Error("RR %i", id);
	}


	if (nodelist[node10].prev != node9){
		I_Error("SS %i", id);
	}
	if (nodelist[node10].next != node11){
		I_Error("TT %i", id);
	}

	if (nodelist[node11].prev != node10){
		I_Error("UU %i", id);
	}
	if (nodelist[node11].next != node12){
		I_Error("VV %i", id);
	}

	if (nodelist[node12].prev != node11){
		I_Error("WW %i", id);
	}
	if (nodelist[node12].next != node13){
		I_Error("XX %i", id);
	}

	if (nodelist[node13].prev != node12){
		I_Error("YY %i", id);
	}
	if (nodelist[node13].next != node14){
		I_Error("ZZ %i", id);
	}

	if (nodelist[node14].prev != node13){
		I_Error("AAA %i", id);
	}
	if (nodelist[node14].next != node15){
		I_Error("BBB %i", id);
	}


	if (nodelist[node15].prev != node14){
		I_Error("CCC %i", id);
	}
	if (nodelist[node15].next != node16){
		I_Error("DDD %i", id);
	}

	if (nodelist[node16].prev != node15){
		I_Error("EEE %i", id);
	}
	if (nodelist[node16].next != node17){
		I_Error("FFF %i", id);
	}

	if (nodelist[node17].prev != node16){
		I_Error("GGG %i", id);
	}
	if (nodelist[node17].next != node18){
		I_Error("HHH %i", id);
	}

	if (nodelist[node18].prev != node17){
		I_Error("III %i", id);
	}
	if (nodelist[node18].next != node19){
		I_Error("JJJ %i", id);
	}

	if (nodelist[node19].prev != node18){
		I_Error("KKK %i", id);
	}
	if (nodelist[node19].next != -1){
		I_Error("LLL %i", id);
	}

	
	//if (nodelist[node7].next != -1){
	//	I_Error("N %i", id);
	//}

	//if (node7 != spritecache_l2_head){
	//	I_Error("O %i", id);
	//}




}

*/


/*
void __near checkpatchcache(int8_t id){
	int8_t node0;
	int8_t node1;
	int8_t node2;
	int8_t node3;
	int8_t node4;
	int8_t node5;
	int8_t node6;
	int8_t node7;
	int8_t node8;
	int8_t node9;
	int8_t node10;
	int8_t node11;
	int8_t node12;
	int8_t node13;
	int8_t node14;
	int8_t node15;
	int8_t nodeprev;
	int8_t nodenow;
	int8_t j = 0;
	int8_t i = 0;
	
	cache_node_page_count_t far* nodelist  = patchcache_nodes;



	node0  = patchcache_l2_tail;
	node1  = nodelist[node0].next;
	node2  = nodelist[node1].next;
	node3  = nodelist[node2].next;
	node4  = nodelist[node3].next;
	node5  = nodelist[node4].next;
	node6  = nodelist[node5].next;
	node7  = nodelist[node6].next;
	node8  = nodelist[node7].next;
	node9  = nodelist[node8].next;
	node10  = nodelist[node9].next;
	node11  = nodelist[node10].next;
	node12  = nodelist[node11].next;
	node13  = nodelist[node12].next;
	node14  = nodelist[node13].next;
	node15  = nodelist[node14].next;


	for (i = 0; i < NUM_PATCH_CACHE_PAGES; i++){
		int8_t found = 0;
		nodenow = patchcache_l2_tail;
		for (j = 0; j < NUM_PATCH_CACHE_PAGES; j++){
			if (nodenow == i){
				found = 1;
				break;
			}			
			nodenow = nodelist[nodenow].next;
		}
		if (!found){
			I_Error("not found %i \n %i %i %i \n%i %i %i %i %i %i %i %i %i %i %i %i %i %i %i %i ", i, patchcache_l2_tail, patchcache_l2_head, id, 
	  		node0, node1, node2, node3, node4, node5, node6, node7, node8, node9, node10, node11, node12, node13, node14, node15);

		}
	}

	nodenow = patchcache_l2_tail;

	{
		int8_t currenttarget = 0;
		int8_t lastpagecount = 0;
		for (j = 0; j < NUM_PATCH_CACHE_PAGES; j++){
			if (!currenttarget){
				if (nodelist[nodenow].pagecount == 1){
					currenttarget = nodelist[nodenow].numpages;
					lastpagecount = 1;
				} else {
					if (nodelist[nodenow].pagecount){
						I_Error("non one first pagecount %i %i %i", nodelist[nodenow].pagecount, nodenow, id);

						//I_Error("not found %i \n %i %i %i \n%i %i %i %i %i %i %i %i %i %i %i %i %i %i %i %i %i %i %i %i", i, patchcache_l2_tail, patchcache_l2_head, id, 
						//node0, node1, node2, node3, node4, node5, node6, node7, node8, node9, node10, node11, node12, node13, node14, node15, node16, node17, node18, node19);

					} else 

					if (nodelist[nodenow].numpages){
						I_Error("pagecount zero and numpages nonzero %i %i", nodelist[nodenow].pagecount, nodelist[nodenow].numpages);
					}
				}
			} else {
				if (nodelist[nodenow].pagecount == lastpagecount+1){
					if (nodelist[nodenow].numpages != currenttarget){
						I_Error("numpages changed?  %i %i", nodelist[nodenow].pagecount, nodelist[nodenow].numpages);
					}
					lastpagecount++;
					if (nodelist[nodenow].pagecount == currenttarget){
						currenttarget = 0;
						lastpagecount = 0;
	
					}
				} else {
					
					I_Error("pagecount not found %i \n %i %i %i \n%i %i %i %i %i %i %i %i %i %i %i %i %i %i %i %i \n%i %i %i %i %i %i %i %i %i %i %i %i %i %i %i %i \n%i %i %i %i %i %i %i %i %i %i %i %i %i %i %i %i ", i, patchcache_l2_tail, patchcache_l2_head, id, 
						node0, node1, node2, node3, node4, node5, node6, node7, node8, node9, node10, node11, node12, node13, node14, node15,
						nodelist[node0].pagecount, 
						nodelist[node1].pagecount, 
						nodelist[node2].pagecount, 
						nodelist[node3].pagecount, 
						nodelist[node4].pagecount, 
						nodelist[node5].pagecount, 
						nodelist[node6].pagecount, 
						nodelist[node7].pagecount, 
						nodelist[node8].pagecount, 
						nodelist[node9].pagecount, 
						nodelist[node10].pagecount, 
						nodelist[node11].pagecount, 
						nodelist[node12].pagecount, 
						nodelist[node13].pagecount, 
						nodelist[node14].pagecount, 
						nodelist[node15].pagecount, 
						
						nodelist[node0].numpages, 
						nodelist[node1].numpages, 
						nodelist[node2].numpages, 
						nodelist[node3].numpages, 
						nodelist[node4].numpages, 
						nodelist[node5].numpages, 
						nodelist[node6].numpages, 
						nodelist[node7].numpages, 
						nodelist[node8].numpages, 
						nodelist[node9].numpages, 
						nodelist[node10].numpages, 
						nodelist[node11].numpages, 
						nodelist[node12].numpages, 
						nodelist[node13].numpages, 
						nodelist[node14].numpages, 
						nodelist[node15].numpages


						
						);
					
					
					I_Error("pagecount wrong order %i %i %i %i", nodelist[nodenow].pagecount, nodelist[nodenow].numpages,
					currenttarget, lastpagecount);
				}
				
			}


			nodenow = nodelist[nodenow].next;
		}

		if (currenttarget){
			I_Error("page count ended at end? A");

						


		}
		if (lastpagecount){
			I_Error("page count ended at end? B");
		}
	}

	//prevmost is tail (LRU)
	//nextmost is head (MRU)


	if (nodelist[patchcache_l2_tail].prev != -1){
		I_Error("tail non -1 prev %i", id);
	}
	if (nodelist[patchcache_l2_tail].next == -1){
		I_Error("tail -1 next %i", id);
	}

	if (nodelist[patchcache_l2_head].next != -1){
		I_Error("head non -1 next %i", id);
	}
	if (nodelist[patchcache_l2_head].prev == -1){
		I_Error("head -1 prev %i %i %i %i %i %i %i %i", id, node0, node1, node2, node3, node4, node5);
	}

	if (nodelist[node1].prev != node0){
		I_Error("AA %i", id);
	}
	if (nodelist[node1].next != node2){
		I_Error("BB %i", id);
	}

	if (nodelist[node2].prev != node1){
		I_Error("CC %i", id);
	}
	if (nodelist[node2].next != node3){
		I_Error("DD %i", id);
	}

	if (nodelist[node3].prev != node2){
		I_Error("EE %i", id);
	}
	if (nodelist[node3].next != node4){
		I_Error("FF %i", id);
	}

	if (nodelist[node4].prev != node3){
		I_Error("GG %i", id);
	}
	if (nodelist[node4].next != node5){
		I_Error("HH %i", id);
	}


	if (nodelist[node5].prev != node4){
		I_Error("II %i", id);
	}
	if (nodelist[node5].next != node6){
		I_Error("JJ %i", id);
	}


	if (nodelist[node6].prev != node5){
		I_Error("KK %i", id);
	}
	if (nodelist[node6].next != node7){
		I_Error("LL %i", id);
	}

	if (nodelist[node7].prev != node6){
		I_Error("MM %i", id);
	}
	if (nodelist[node7].next != node8){
		I_Error("NN %i", id);
	}

	if (nodelist[node8].prev != node7){
		I_Error("OO %i", id);
	}
	if (nodelist[node8].next != node9){
		I_Error("PP %i", id);
	}

	if (nodelist[node9].prev != node8){
		I_Error("QQ %i", id);
	}
	if (nodelist[node9].next != node10){
		I_Error("RR %i", id);
	}


	if (nodelist[node10].prev != node9){
		I_Error("SS %i", id);
	}
	if (nodelist[node10].next != node11){
		I_Error("TT %i", id);
	}

	if (nodelist[node11].prev != node10){
		I_Error("UU %i", id);
	}
	if (nodelist[node11].next != node12){
		I_Error("VV %i", id);
	}

	if (nodelist[node12].prev != node11){
		I_Error("WW %i", id);
	}
	if (nodelist[node12].next != node13){
		I_Error("XX %i", id);
	}

	if (nodelist[node13].prev != node12){
		I_Error("YY %i", id);
	}
	if (nodelist[node13].next != node14){
		I_Error("ZZ %i", id);
	}

	if (nodelist[node14].prev != node13){
		I_Error("AAA %i", id);
	}
	if (nodelist[node14].next != node15){
		I_Error("BBB %i", id);
	}


	if (nodelist[node15].prev != node14){
		I_Error("CCC %i", id);
	}
	if (nodelist[node15].next != -1){
		I_Error("DDD %i", id);
	}

	
	//if (nodelist[node7].next != -1){
	//	I_Error("N %i", id);
	//}

	//if (node7 != patchcache_l2_head){
	//	I_Error("O %i", id);
	//}




}


*/


void __near R_MarkL2CompositeTextureCacheLRU(int8_t index) {

 



	int8_t prev;
	int8_t next;
	int8_t pagecount;


	int8_t previous_next;

	int8_t lastindex;
	int8_t lastindex_prev;
	int8_t index_next;

	
	if (index == texturecache_l2_head) {
		return;
	}


	pagecount = texturecache_nodes[index].pagecount;
	// if pagecount is nonzero, then this is a pre-existing allocation which is multipage.
	// so we want to find the head of this allocation, and check if it's the head.

	if (pagecount){
		// if this is multipage, then pagecount is nonzero.
		
		// could probably be unrolled in asm
	 	while (texturecache_nodes[index].numpages != texturecache_nodes[index].pagecount){
			index = texturecache_nodes[index].next;
		}


		if (index == texturecache_l2_head) {
			return;
		}

		// there are going to be cases where we call with numpages = 0, 
		// but the allocation is sharing a page with the last page of a
		// multi-page allocation. in this case, we want to back up and update the
		// whole multi-page allocation.
		
	}

	 

	if (texturecache_nodes[index].numpages){
		// multipage  allocation being updated.
		
		// we know its pre-existing because numpages is set on the node;
		// that means all the inner pages' next/prevs set and pagecount/numpages are also already set
		// no need to set all that stuff, just the relevant outer allocations's prev/next.
		// and update head/tail

		lastindex = index;
		while (texturecache_nodes[lastindex].pagecount != 1){
			lastindex = texturecache_nodes[lastindex].prev;
		}
		
		lastindex_prev = texturecache_nodes[lastindex].prev;
		index_next = texturecache_nodes[index].next;

		if (texturecache_l2_tail == lastindex){
			texturecache_l2_tail = index_next;
			texturecache_nodes[index_next].prev = -1;
		} else {
			texturecache_nodes[lastindex_prev].next = index_next;
			texturecache_nodes[index_next].prev = lastindex_prev;
		}

		texturecache_nodes[lastindex].prev = texturecache_l2_head;
		texturecache_nodes[texturecache_l2_head].next = lastindex;
		// head's next doesnt change directly. it changes indirectly if index_prev changes.

		texturecache_nodes[index].next = -1;
		texturecache_l2_head = index;

		return;
	} else {
		// handle the simple one page case.

		prev = texturecache_nodes[index].prev;
		next = texturecache_nodes[index].next;

		if (index == texturecache_l2_tail) {
			texturecache_l2_tail = next;
		} else {
			texturecache_nodes[prev].next = next; 
		}

		texturecache_nodes[next].prev = prev;  // works in either of the above cases. prev is -1 if tail.

		texturecache_nodes[index].prev = texturecache_l2_head;
		texturecache_nodes[index].next = -1;

		// pagecount/numpages dont have to be zeroed - either p_setup 
		// sets it to 0 in the initial case, or EvictCache in later cases.
		//texturecache_nodes[index].pagecount = 0;
		//texturecache_nodes[index].numpages  = 0;

		texturecache_nodes[texturecache_l2_head].next = index;
		
		
		texturecache_l2_head = index;
		return;

	}


}



void __near R_MarkL2SpriteCacheLRU(int8_t index) {

	int8_t prev;
	int8_t next;
	int8_t pagecount;
	int8_t previous_next;
	int8_t lastindex;
	int8_t lastindex_prev;
	int8_t index_next;

	if (index == spritecache_l2_head) {
		return;
	}

	pagecount = spritecache_nodes[index].pagecount;
	// if pagecount is nonzero, then this is a pre-existing allocation which is multipage.
	// so we want to find the head of this allocation, and check if it's the head.

	if (pagecount){
		// if this is multipage, then pagecount is nonzero.
		
		// could probably be unrolled in asm
	 	while (spritecache_nodes[index].numpages != spritecache_nodes[index].pagecount){
			index = spritecache_nodes[index].next;
		}

		if (index == spritecache_l2_head) {
			return;
		}

		// there are going to be cases where we call with numpages = 0, 
		// but the allocation is sharing a page with the last page of a
		// multi-page allocation. in this case, we want to back up and update the
		// whole multi-page allocation.
		
	}

	if (spritecache_nodes[index].numpages){
		// multipage  allocation being updated.
		
		// we know its pre-existing because numpages is set on the node;
		// that means all the inner pages' next/prevs set and pagecount/numpages are also already set
		// no need to set all that stuff, just the relevant outer allocations's prev/next.
		// and update head/tail
	

		lastindex = index;
		while (spritecache_nodes[lastindex].pagecount != 1){
			lastindex = spritecache_nodes[lastindex].prev;
		}
		
		lastindex_prev = spritecache_nodes[lastindex].prev;
		index_next = spritecache_nodes[index].next;

		if (spritecache_l2_tail == lastindex){
			spritecache_l2_tail = index_next;
			spritecache_nodes[index_next].prev = -1;
		} else {
			spritecache_nodes[lastindex_prev].next = index_next;
			spritecache_nodes[index_next].prev = lastindex_prev;
		}

		spritecache_nodes[lastindex].prev = spritecache_l2_head;
		spritecache_nodes[spritecache_l2_head].next = lastindex;
		// head's next doesnt change directly. it changes indirectly if index_prev changes.

		spritecache_nodes[index].next = -1;
		spritecache_l2_head = index;

		return;
	} else {
		// handle the simple one page case.

		prev = spritecache_nodes[index].prev;
		next = spritecache_nodes[index].next;

		if (index == spritecache_l2_tail) {
			spritecache_l2_tail = next;
		} else {
			spritecache_nodes[prev].next = next; 
		}

		spritecache_nodes[next].prev = prev;  // works in either of the above cases. prev is -1 if tail.

		spritecache_nodes[index].prev = spritecache_l2_head;
		spritecache_nodes[index].next = -1;

		// pagecount/numpages dont have to be zeroed - either p_setup 
		// sets it to 0 in the initial case, or EvictCache in later cases.
		//spritecache_nodes[index].pagecount = 0;
		//spritecache_nodes[index].numpages  = 0;

		spritecache_nodes[spritecache_l2_head].next = index;
		
		
		spritecache_l2_head = index;
		return;

	}


}


// note: numpages is 1-4, not 0-3 here.
// this function needs to always leave the cache in a workable state...
// if we remove excess pages due to the removed pages being part of a
// multi-page allocation, then those now unused pages should be appropriately
// put at the back of the queue so they will be the next loaded into.
// the evicted pages are also moved to the front. numpages/pagecount are filled in by the code after this
int8_t __near R_EvictL2CacheEMSPage(int8_t numpages, int8_t cachetype){

	//todo revisit these vars.
	int16_t evictedpage;
	int8_t j;
	int16_t currentpage;
	int16_t k;
	int8_t previous_next;
	cache_node_page_count_t near* nodelist;
	int8_t* nodetail;
	int8_t* nodehead;
	int16_t maxitersize;

	uint8_t __far* cacherefpage;
	uint8_t __far* cacherefoffset;
	uint8_t __near* usedcacherefpage;



	switch (cachetype){
		case CACHETYPE_SPRITE:
			nodetail = &spritecache_l2_tail;
			nodehead = &spritecache_l2_head;
			nodelist = spritecache_nodes;
			maxitersize = MAX_SPRITE_LUMPS;
			cacherefpage = spritepage;
			cacherefoffset = spriteoffset;
			usedcacherefpage = usedspritepagemem;
			#ifdef DETAILED_BENCH_STATS
			spritecacheevictcount++;
			#endif
			break;

		case CACHETYPE_PATCH:
 			nodetail = &texturecache_l2_tail;
			nodehead = &texturecache_l2_head;
			nodelist = texturecache_nodes;
			maxitersize = MAX_PATCHES;
			cacherefpage = patchpage;
			cacherefoffset = patchoffset;
			usedcacherefpage = usedtexturepagemem;
			#ifdef DETAILED_BENCH_STATS
			patchcacheevictcount++;
			#endif
			break;
			
		case CACHETYPE_COMPOSITE:
 			nodetail = &texturecache_l2_tail;
			nodehead = &texturecache_l2_head;
			nodelist = texturecache_nodes;
			maxitersize = MAX_TEXTURES;
			cacherefpage = compositetexturepage;
			cacherefoffset = compositetextureoffset;
			usedcacherefpage = usedtexturepagemem;
			#ifdef DETAILED_BENCH_STATS
			compositecacheevictcount++;
			#endif

			break;
	}



	currentpage = *nodetail;

	// go back enough pages to allocate them all.
	for (j = 0; j < numpages-1; j++){
		currentpage = nodelist[currentpage].next;
	}

	evictedpage = currentpage;

	// currentpage is the LRU page we can remove in which
	// there is enough room to allocate numpages pages


	//prevmost is tail (LRU)
	//nextmost is head (MRU)

	// need to evict at least numpages pages
	// we'll remove the tail, up to numpages...
	// if thats part of a multipage allocations, we'll remove that until the end
	// in that case, we leave extra deallocated pages in the tail.

 
	// true if 0 page allocation or 1st page of a multi-page
	while (nodelist[evictedpage].numpages != nodelist[evictedpage].pagecount){
		evictedpage = nodelist[evictedpage].next;
	}


	// clear cache data that was pointing to this page.
	while (evictedpage != -1){

		nodelist[evictedpage].pagecount = 0;
		nodelist[evictedpage].numpages = 0;

		for (k = 0; k < maxitersize; k++){
			if ((cacherefpage[k] >> 2) == evictedpage){
				cacherefpage[k] = 0xFF;
				cacherefoffset[k] = 0xFF;
			}
		}
		usedcacherefpage[evictedpage] = 0;
		evictedpage = nodelist[evictedpage].prev;
	}	


	// connect old tail and old head.
	nodelist[*nodetail].prev = *nodehead;
	nodelist[*nodehead].next = *nodetail;


	// current page is next head
	//previous_head = *nodehead;
	previous_next = nodelist[currentpage].next;

	*nodehead = currentpage;
	nodelist[currentpage].next = -1;


	// new tail
	nodelist[previous_next].prev = -1;
	*nodetail = previous_next;





	return *nodehead;
}



// MRU is the head. LRU is the tail.
//todo move to r_span.asm segment
void __far R_MarkL2FlatCacheLRU(int8_t index) {

	cache_node_t far* nodelist  = flatcache_nodes;


	int8_t prev;
	int8_t next;

	if (index == flatcache_l2_head) {
		return;
	}
	
	prev = nodelist[index].prev;
	next = nodelist[index].next;

	if (index == flatcache_l2_tail) {
		flatcache_l2_tail = next;	
	} else {
		nodelist[prev].next = next;
	}

	// guaranteed to have a next. if we didnt have one, it'd be head but we already returned from that case.
	nodelist[next].prev = prev;

	nodelist[index].prev = flatcache_l2_head;
	nodelist[index].next = -1;
	nodelist[flatcache_l2_head].next = index;
	flatcache_l2_head = index;


	 
}


//todo move into asm into r_span
int8_t __far R_EvictFlatCacheEMSPage(){
	int8_t evictedpage;
	uint8_t i;
	int8_t next, prev;
	cache_node_t far* nodelist  = flatcache_nodes;
	
	#ifdef DETAILED_BENCH_STATS
	flatcacheevictcount++;
	#endif
	 
	evictedpage = flatcache_l2_tail;
	// evicted page becomes the new head.

 
	// remove the element and connext its next and prev togeter
	next = nodelist[evictedpage].next;
	prev = nodelist[evictedpage].prev;

	flatcache_l2_tail = nodelist[evictedpage].next;
	nodelist[flatcache_l2_tail].prev = -1;
	
	nodelist[flatcache_l2_head].next = evictedpage;
	nodelist[evictedpage].next = -1;
	nodelist[evictedpage].prev = flatcache_l2_head;
	flatcache_l2_head = evictedpage;

 
	// all the other flats in this are cleared.
	allocatedflatsperpage[evictedpage] = 1;

	// gross and slow. but rare i guess? revisit?
	// cant we fetch these from some list that already exists?
	
	//entries in flatindex cache pointing to this page are marked unloded.
	for (i = 0; i < MAX_FLATS; i++){
		
		if ((flatindex[i] >> 2) == evictedpage){
			flatindex[i] = 0xFF;
		}

	}
	return evictedpage;
}



//
// R_DrawColumnInCache
// Clip and draw a column
//  from a patch into a cached post.
//
// todo merge below when doing asm later
//int16_t
void __near R_DrawColumnInCache (column_t __far* patchcol, segment_t currentdestsegment, int16_t patchoriginy, int16_t textureheight) {
	while (patchcol->topdelta != 0xff) { 

		byte __far * source = (byte __far *)patchcol + 3;
		uint16_t     count = patchcol->length;
		int16_t     position = patchoriginy + patchcol->topdelta;


		patchcol = (column_t __far*)((byte  __far*)patchcol + count + 4);

		if (position < 0)
		{
			count += position;
			position = 0;
		}

		if (position + count > textureheight)
			count = textureheight - position;
		if (count > 0)
			FAR_memcpy(MK_FP(currentdestsegment, position), source, count);


	}
	//return totalsize;
}


void __near R_GetNextTextureBlock(int16_t tex_index, uint16_t size, int8_t cachetype) {

	uint8_t blocksize = size >> 8; // num 256-sized blocks needed
	int8_t numpages;
	uint8_t texpage, texoffset;
	int8_t i, j;

	


	if (size & 0xFF) {
		blocksize++;
	}
	numpages = blocksize >> 6; // num EMS pages needed
	if (blocksize & 0x3F) {
		numpages++;
	}

	// calculated the size, now lets find an open page
	if (numpages == 1) {
		// number of 256-byte block segments needed in an ems page
		uint8_t freethreshold = 64 - blocksize;
		for (i = 0; i < NUM_TEXTURE_PAGES; i++) {
			if (freethreshold >= usedtexturepagemem[i]) {
				goto foundonepage;


			}
		}

		//checkpatchcache(50);
		i = R_EvictL2CacheEMSPage(1, cachetype);
		//checkpatchcache(51);

		foundonepage:
		texpage = i << 2;
		texoffset = usedtexturepagemem[i];
		usedtexturepagemem[i] += blocksize;
	} else {
		uint8_t numpagesminus1 = numpages - 1;

		for (i = texturecache_l2_head;
				i != -1; 
				i = texturecache_nodes[i].prev
				) {
			if (!usedtexturepagemem[i]) {
				// need to check following pages for emptiness, or else after evictions weird stuff can happen
				int8_t nextpage = texturecache_nodes[i].prev;
				if ((nextpage != -1 &&!usedtexturepagemem[nextpage])) {
					nextpage = texturecache_nodes[nextpage].prev;
					if (numpagesminus1 < 2 || (nextpage != -1 && (!usedtexturepagemem[nextpage]))) {
						nextpage = texturecache_nodes[nextpage].prev;
						if (numpagesminus1 < 3 || (nextpage != -1 &&(!usedtexturepagemem[nextpage]))) {
							goto foundmultipage;
						}
					}
				}
			}
		}

		//checkpatchcache(52);
		i = R_EvictL2CacheEMSPage(numpages, cachetype);
		//checkpatchcache(53);

		foundmultipage:
		
		usedtexturepagemem[i] = 64;

		j = i;
		// last page of the allocation
		texturecache_nodes[i].numpages = numpages;
		texturecache_nodes[i].pagecount = numpages;

		// this DOES happen.
		if (numpages >= 3) {
			// 2nd to last page of the allocation
			j = texturecache_nodes[i].prev;
			texturecache_nodes[j].numpages = numpages;
			// 2 if numpages is 3. 
			// 3 if numpages is 4
			texturecache_nodes[j].pagecount = numpages-1;
			usedtexturepagemem[j] = 64;
		}
		// numpages 4 case never happens..
		
		// first page of the allocation
		j = texturecache_nodes[j].prev;
		texturecache_nodes[j].numpages = numpages;
		texturecache_nodes[j].pagecount = 1;


		if (blocksize & 0x3F) {
			usedtexturepagemem[j] = blocksize & 0x3F;
		} else {
			usedtexturepagemem[j] = 64;
		}
		texpage = (i << 2) + (numpagesminus1);
		texoffset = 0; // if multipage then its always aligned to start of its block
 	
	}

	if (cachetype == CACHETYPE_PATCH){
		patchpage  [tex_index] = texpage;
		patchoffset[tex_index] = texoffset;
	} else {
		compositetexturepage[tex_index] = texpage;
		compositetextureoffset[tex_index] = texoffset;
	}

}



void __near R_GetNextSpriteBlock(int16_t lump) {
	uint16_t size = spritetotaldatasizes[lump-firstspritelump];
	uint8_t blocksize = size >> 8; // num 256-sized blocks needed
	int8_t numpages;
	uint8_t texpage, texoffset;
	int8_t i, j;
	if (size & 0xFF) {
		blocksize++;
	}

	//todo shift right 6 can be a lookup...?
	numpages = blocksize >> 6; // num EMS pages needed
	if (blocksize & 0x3F) {
		numpages++;
	}
	// asm algo something like
	// rol x2, add (3F) to get carry, adc 0



	// calculated the size, now lets find an open page
	if (numpages == 1) {
		// number of 256-byte block segments needed in an ems page
		uint8_t freethreshold = 64 - blocksize;
		for (i = 0; i < NUM_SPRITE_CACHE_PAGES; i++) {
			if (freethreshold >= usedspritepagemem[i]) {
				goto foundonepage;
			}
		}

		// nothing found, evict cache
		//checkspritecache(30);
		i = R_EvictL2CacheEMSPage(1, CACHETYPE_SPRITE);
		//checkspritecache(31);
		
		foundonepage:
		texpage = i << 2;
		texoffset = usedspritepagemem[i];
		usedspritepagemem[i] += blocksize;
	} else {

		uint8_t numpagesminus1 = numpages - 1;

		for (i = spritecache_l2_head;
				i != -1; 
				i = spritecache_nodes[i].prev
				) {
			if (!usedspritepagemem[i]) {
				// need to check following pages for emptiness, or else after evictions weird stuff can happen
				int8_t nextpage = spritecache_nodes[i].prev;
				if ((nextpage != -1 &&!usedspritepagemem[nextpage])) {
					nextpage = spritecache_nodes[nextpage].prev;
					if (numpagesminus1 < 2 || (nextpage != -1 && (!usedspritepagemem[nextpage]))) {
						nextpage = spritecache_nodes[nextpage].prev;
						if (numpagesminus1 < 3 || (nextpage != -1 &&(!usedspritepagemem[nextpage]))) {
							goto foundmultipage;
						}
					}
				}
			}
		}


		// nothing found, evict cache
		//checkspritecache(32);
		i = R_EvictL2CacheEMSPage(numpages, CACHETYPE_SPRITE);
		//checkspritecache(33);
		foundmultipage:

		usedspritepagemem[i] = 64;

		// j = i
		// last page of the allocation
		spritecache_nodes[i].numpages = numpages;
		spritecache_nodes[i].pagecount = numpages;
		// not sure if this ever happens... especially for sprite. biggest sprites are barely 2 page. todo remove

		/*
		if (numpages >= 3) {
			I_Error("3 page sprite! fix this"); // todo remove
			// 2nd to last page of the allocation
			j = spritecache_nodes[i].prev;
			spritecache_nodes[j].numpages = numpages;
			// 2 if numpages is 3. 
			// 3 if numpages is 4
			spritecache_nodes[j].pagecount = numpages-1;
			usedspritepagemem[j] = 64;
		}
		*/

		// i actually think this never happens? get rid of the code?
		/*
		if (numpages == 4) {
			// always page 2 of the 4 page allocation
			j = texturecache_nodes[j].prev;
			texturecache_nodes[j].numpages = numpages;
			texturecache_nodes[j].pagecount = 2;
			usedspritepagemem[j] = 64;
		}
		*/
		// first page of the allocation
		j = spritecache_nodes[i].prev;
		spritecache_nodes[j].numpages = numpages;
		spritecache_nodes[j].pagecount = 1;




		if (blocksize & 0x3F) {
			usedspritepagemem[j] = blocksize & 0x3F;
		}
		else {
			usedspritepagemem[j] = 64;
		}

		texpage = (i << 2) + (numpagesminus1);
		texoffset = 0; // if multipage then its always aligned to start of its block

	}

	spritepage[lump - firstspritelump] = texpage;
	spriteoffset[lump - firstspritelump] = texoffset;

}
//
// R_GenerateComposite
// Using the texture definition,
//  the composite texture is created from the patches,
//  and each column is cached.
//


#define wadpatch7000  ((patch_t __far *)  MK_FP(SCRATCH_PAGE_SEGMENT_7000, 0))

void __near R_GenerateComposite(uint16_t texnum, segment_t block_segment) {
	texpatch_t __far*         patch;
	//patch_t __far*            wadpatch;
	int16_t             x;
	int16_t             x1;
	int16_t             x2;
	int16_t             i;
	column_t __far*           patchcol;
	int16_t_union __far*         collump;
	uint8_t				textureheight;
	uint8_t				usetextureheight;
	int16_t				texturewidth;
	uint8_t				texturepatchcount;
	int16_t				patchpatch = -1;
	int16_t				patchoriginx;
	int8_t				patchoriginy;
	texture_t __far*			texture;
	int16_t				lastusedpatch = -1;
	int16_t				index;
	//uint8_t				currentpatchpage = 0;
	int16_t currentlump;
	int16_t currentRLEIndex = 0;
	int16_t nextcollumpRLE = 0;
	segment_t currentdestsegment;


/*
	FILE*fp;
	int8_t fname[15];
	uint16_t totalsize = 0;
	*/
	texture = (texture_t __far*)&(texturedefs_bytes[texturedefs_offset[texnum]]);

	texturewidth = texture->width + 1;
	textureheight = texture->height + 1;
	usetextureheight = textureheight + ((16 - (textureheight &0xF)) &0xF);
	usetextureheight = usetextureheight >> 4;
	texturepatchcount = texture->patchcount;

	// Composite the columns together.
	collump = &(texturecolumnlumps_bytes[texturepatchlump_offset[texnum]]);

	// check which 64k page this lives in

	Z_QuickMapScratch_7000();

	for (i = 0; i < texturepatchcount; i++) {

		patch = &texture->patches[i];
		lastusedpatch = patchpatch;
		patchpatch = patch->patch & PATCHMASK;
		index = patch->patch - firstpatch;
		currentRLEIndex = 0;


		if (lastusedpatch != patchpatch) {
			W_CacheLumpNumDirect(patchpatch, (byte __far*)wadpatch7000);
		}
		patchoriginx = patch->originx *  (patch->patch & ORIGINX_SIGN_FLAG ? -1 : 1);
		patchoriginy = patch->originy;


		x1 = patchoriginx;
		x2 = x1 + (wadpatch7000->width);

		if (x1 < 0){
			x = 0;
		} else {
			x = x1;
		}

		if (x2 > texturewidth){
			x2 = texturewidth;
		}

		currentlump = collump[currentRLEIndex].h;
		nextcollumpRLE = collump[currentRLEIndex + 1].bu.bytelow;

		// increment starting texel index

		currentdestsegment = block_segment;

		// skip if x is 0, otherwise evaluate till break
		if (x){
			int16_t innercurrentRLEIndex = 0;
			int16_t innercurrentlump = collump[0].h;
			uint8_t innernextcollumpRLE = collump[1].bu.bytelow;
			uint8_t currentx = 0;
			uint8_t diffpixels = 0;

			while (true){ 
				if ((currentx + innernextcollumpRLE) < x){
					if (innercurrentlump == -1){
						diffpixels += (innernextcollumpRLE);
					}
					currentx += innernextcollumpRLE;
					innercurrentRLEIndex += 2;
					innercurrentlump = collump[innercurrentRLEIndex].h;
					innernextcollumpRLE = collump[innercurrentRLEIndex + 1].bu.bytelow;
					continue;
				} else {
					if (innercurrentlump == -1){
						diffpixels += ((x - currentx));
					}
					break;
				}

			}
			currentdestsegment += FastMul8u8u(usetextureheight, diffpixels);
		}





		for (; x < x2; x++) {
			while (x >= nextcollumpRLE) {
				currentRLEIndex += 2;
				currentlump = collump[currentRLEIndex].h;
				nextcollumpRLE += collump[currentRLEIndex + 1].bu.bytelow;
			}

			// if there is a defined lump, then there are not multiple patches for the column
			if (currentlump >= 0) {
				continue;
			}
			
			patchcol = MK_FP(0x7000, wadpatch7000->columnofs[x - x1]);

			// inlined R_DrawColumninCache
			R_DrawColumnInCache(patchcol,
				currentdestsegment,
				patchoriginy,
				textureheight);

				// TODO this should be inlined but watcom sucks at big functions - do later in asm

/*
			while (patchcol->topdelta != 0xff) { 

				byte __far * source = (byte __far *)patchcol + 3;
				uint16_t     count = patchcol->length;
				int16_t     position = patchoriginy + patchcol->topdelta;


				patchcol = (column_t __far*)((byte  __far*)patchcol + count + 4);

				if (position < 0)
				{
					count += position;
					position = 0;
				}

				if (position + count > textureheight)
					count = textureheight - position;
				if (count > 0)
					FAR_memcpy(MK_FP(currentdestsegment, position), source, count);


			}
			*/

			currentdestsegment += usetextureheight;

		}
	}

	Z_QuickMapRender7000();

}


//gettexturepage takes an l2 cache page, pages it into L1 if its not already.
//then returns the L1 page number
uint8_t __near gettexturepage(uint8_t texpage, uint8_t pageoffset, int8_t cachetype){
	uint8_t realtexpage = texpage >> 2;
	//uint8_t pagenum = pageoffset + realtexpage;
	uint8_t numpages = (texpage& 0x03);
	uint8_t startpage;
	uint8_t i;

 


	if (!numpages) {
		// one page, most common case - lets write faster code here...

		for (i = 0; i < NUM_TEXTURE_L1_CACHE_PAGES; i++) {

			if (activetexturepages[i] == realtexpage ) {

				R_MarkL1TextureCacheLRU(i);
				R_MarkL2CompositeTextureCacheLRU(realtexpage);
				return i;
			}

		}
		// cache miss, find highest LRU cache index
 
		// figure out startpage based on LRU

		startpage = textureL1LRU[NUM_TEXTURE_L1_CACHE_PAGES-1];

		R_MarkL1TextureCacheLRU7(startpage);

		// if the deallocated page was a multipage allocation then we want to invalidate the other pages.
		if (activenumpages[startpage]) {
			for (i = 1; i <= activenumpages[startpage]; i++) {
				activetexturepages[startpage+i]  = -1; // unpaged
				//this is unmapping the page, so we don't need to use pagenum/nodelist
				pageswapargs[pageswapargs_rend_texture_offset+( startpage+i)*PAGE_SWAP_ARG_MULT] = 
					_NPR(PAGE_5000_OFFSET+startpage+i);

				activenumpages[startpage+i] = 0;
			}
		}
		activenumpages[startpage] = 0;


		activetexturepages[startpage] = realtexpage; // FIRST_TEXTURE_LOGICAL_PAGE + pagenum;		
		
		pageswapargs[pageswapargs_rend_texture_offset+(startpage)*PAGE_SWAP_ARG_MULT] = 
			_EPR(pageoffset + realtexpage);



		R_MarkL2CompositeTextureCacheLRU(realtexpage);
		Z_QuickMapRenderTexture();
		cachedtex = -1;
		cachedtex2 = -1;
		cachedlumps[0] = -1;
		cachedlumps[1] = -1;
		cachedlumps[2] = -1;
		cachedlumps[3] = -1;

	

		return startpage;

	} else {
		int16_t j = 0;
		// needed for multipage iteration...

		



		for (i = 0; i < NUM_TEXTURE_L1_CACHE_PAGES-numpages; i++) {

			// Note: if we do always properly unset multi-page allocations,
			// then a multi-page check should be unnecessary.

			if (activetexturepages[i] != realtexpage){
				continue;
			}
			


			// all pages for this texture are in the cache, unevicted.

			
			for (j = 0; j <= numpages; j++) {
				R_MarkL1TextureCacheLRU(i+j);
			}
			R_MarkL2CompositeTextureCacheLRU(realtexpage);
			return i;
		}

		// texture not in cache. need to page it in

		


		// figure out startpage based on LRU
		startpage = NUM_TEXTURE_L1_CACHE_PAGES-1; // num EMS pages in conventional memory - 1
		while (textureL1LRU[startpage] > ((NUM_TEXTURE_L1_CACHE_PAGES-1)-numpages)){
			startpage--;
		}
		startpage = textureL1LRU[startpage];



		// prep args for quickmap;

		// startpage is the ems page withing the 0x5000 block
		// pagenum is the EMS page offset within EMS texture pages



		// if the deallocated page was a multipage allocation then we want to invalidate the other pages.
		if (activenumpages[startpage] > numpages) {
			for (i = numpages; i <= activenumpages[startpage]; i++) {
				activetexturepages[startpage + i] = -1;

				// unmapping the page, so we dont need pagenum
				pageswapargs[pageswapargs_rend_texture_offset+(startpage + i)*PAGE_SWAP_ARG_MULT] 
					= _NPR(PAGE_5000_OFFSET+startpage+i); // unpaged
				activenumpages[startpage + i] = 0;
			}
		}


		{
			int8_t currentpage = realtexpage; // pagenum - pageoffset
			for (i = 0; i <= numpages; i++) {

				R_MarkL1TextureCacheLRU(startpage+i);

				activetexturepages[startpage + i]  = currentpage;

				pageswapargs[pageswapargs_rend_texture_offset+(startpage + i)*PAGE_SWAP_ARG_MULT]  = 
					_EPR(currentpage+pageoffset);



				activenumpages[startpage + i] = numpages-i;
				currentpage = texturecache_nodes[currentpage].prev;
			}
		}

		R_MarkL2CompositeTextureCacheLRU(realtexpage);
		Z_QuickMapRenderTexture();
		
		//todo: only -1 if its in the knocked out page? pretty infrequent though.
		cachedtex = -1;
		cachedtex2 = -1;
		
		cachedlumps[0] = -1;
		cachedlumps[1] = -1;
		cachedlumps[2] = -1;
		cachedlumps[3] = -1;

		segloopnextlookup[0] = -1;
		segloopnextlookup[1] = -1;
		maskednextlookup = NULL_TEX_COL;
		maskedcachedbasecol = NULL_TEX_COL;


		// paged in

		return startpage;

	}

}

//getspritepage takes an l2 cache page, pages it into L1 if its not already.
//then returns the L1 page number
uint8_t __near getspritepage(uint8_t texpage) {
	uint8_t realtexpage = texpage >> 2;
	//uint8_t pagenum = FIRST_SPRITE_CACHE_LOGICAL_PAGE + realtexpage;
	uint8_t numpages = (texpage & 0x03);
	uint8_t startpage = 0;
	uint8_t i;

	if (!numpages) {
		// one page, most common case - lets write faster code here...

		for (i = 0; i < NUM_SPRITE_L1_CACHE_PAGES; i++) {


			if (activespritepages[i] == realtexpage) {
				R_MarkL1SpriteCacheLRU(i);
				//checkspritecache(34);
				R_MarkL2SpriteCacheLRU(realtexpage);
				//checkspritecache(35);

				return i;
			}

		}
		// cache miss, find highest LRU cache index

		// start page is least recently used (since single page)

		startpage = spriteL1LRU[NUM_SPRITE_L1_CACHE_PAGES-1];

		R_MarkL1SpriteCacheLRU3(startpage);


		// if the deallocated page was a multipage allocation then we want to invalidate the other pages.
		if (activespritenumpages[startpage]) {
			for (i = 1; i <= activespritenumpages[startpage]; i++) {
				activespritepages[startpage + i] = -1;
				//this is being unset, doesn't need to use pagenum
				pageswapargs[pageswapargs_spritecache_offset + (startpage + i)*PAGE_SWAP_ARG_MULT] = 
					_NPR(PAGE_9000_OFFSET+(startpage+i)); // unpaged				

				activespritenumpages[startpage + i] = 0;
			}
		}
		activespritenumpages[startpage] = 0;



		activespritepages[startpage] = realtexpage; // FIRST_TEXTURE_LOGICAL_PAGE + pagenum;

		pageswapargs[pageswapargs_spritecache_offset +  (startpage)*PAGE_SWAP_ARG_MULT] = 
			_EPR(realtexpage+FIRST_SPRITE_CACHE_LOGICAL_PAGE);	
		
		Z_QuickMapSpritePage();
		//checkspritecache(36);
		R_MarkL2SpriteCacheLRU(realtexpage);
		//checkspritecache(37);

		lastvisspritepatch = -1;
		lastvisspritepatch2 = -1;
		

		return startpage;

	}
	else {
		int16_t j = 0;


		for (i = 0; i < NUM_SPRITE_L1_CACHE_PAGES - numpages; i++) {


			// Note: if we do always properly unset multi-page allocations,
			// then a multi-page check should be unnecessary.

			if (activespritepages[i] != realtexpage){
				continue;
			}

			// all pages were good

			for (j = 0; j <= numpages; j++) {
				R_MarkL1SpriteCacheLRU(i+j);

			}
			//checkspritecache(38);
			R_MarkL2SpriteCacheLRU(realtexpage);
			//checkspritecache(39);

			return i;
		}

		// need to page it in


		// start page is least recently used that fits in numpages.
		startpage = NUM_SPRITE_L1_CACHE_PAGES-1; // num EMS pages in conventional memory - 1
		while (spriteL1LRU[startpage] > ((NUM_SPRITE_L1_CACHE_PAGES-1)-numpages)){
			startpage--;
		}
		startpage = spriteL1LRU[startpage];


		// prep args for quickmap;

		// startpage is the ems page withing the 0x5000 block
		// pagenum is the EMS page offset within EMS texture pages



		// if the deallocated page was a multipage allocation then we want to invalidate the other pages.
		if (activespritenumpages[startpage] > numpages) {
			for (i = numpages; i <= activespritenumpages[startpage]; i++) {
				activespritepages[startpage + i] = -1;
				// unmapping the page, so we dont need pagenum
				pageswapargs[pageswapargs_spritecache_offset + ( (startpage + i)*PAGE_SWAP_ARG_MULT)] = 
					_NPR(PAGE_9000_OFFSET+(startpage+i));
				activespritenumpages[startpage + i] = 0;
			}
		}


		{
			int8_t currentpage = realtexpage; // pagenum - pageoffset

			for (i = 0; i <= numpages; i++) {

				R_MarkL1SpriteCacheLRU(startpage+i);

				activespritepages[startpage + i] = currentpage;
				
				// successive logical page indices must come via node list iteration...
				pageswapargs[pageswapargs_spritecache_offset +  ((startpage + i)*PAGE_SWAP_ARG_MULT)] = 
					_EPR(currentpage+FIRST_SPRITE_CACHE_LOGICAL_PAGE);

				activespritenumpages[startpage + i] = numpages - i;
				currentpage = spritecache_nodes[currentpage].prev;
			}
		}

		lastvisspritepatch = -1;
		lastvisspritepatch2 = -1;

		Z_QuickMapSpritePage();

		// paged in
		//checkspritecache(40);
		R_MarkL2SpriteCacheLRU(realtexpage);
		//checkspritecache(41);

		return startpage;

	}

}



// get 0x5000 offset for texture
segment_t __near getpatchtexture(int16_t lump, uint8_t maskedlookup) {

	int16_t index = lump - firstpatch;
	uint8_t texpage = patchpage[index];
	uint8_t texoffset = patchoffset[index];
	boolean ismasked = maskedlookup != 0xFF;
#ifdef DETAILED_BENCH_STATS
	benchtexturetype = TEXTURE_TYPE_PATCH;
#endif

	if (texpage == 0xFF) { 
		//texture not in L2 cache
		segment_t tex_segment;
		uint16_t size = ismasked ? masked_headers[maskedlookup].texturesize : patch_sizes[index];
		
		// load texture into L2 cache 
		R_GetNextTextureBlock(lump - firstpatch, size, CACHETYPE_PATCH);

		texpage = patchpage[index];
		texoffset = patchoffset[index];

		// texture in now L2 cache (EMS), so just return thru L1 cache
		tex_segment = 0x5000u + pagesegments[gettexturepage(texpage, FIRST_TEXTURE_LOGICAL_PAGE, CACHETYPE_PATCH)] + (texoffset << 4);
		R_LoadPatchColumns(lump, tex_segment, ismasked);
		return tex_segment;
	} 
	
	// texture in L2 cache (EMS), so just return thru L1 cache
	return 0x5000u + pagesegments[gettexturepage(texpage, FIRST_TEXTURE_LOGICAL_PAGE, CACHETYPE_PATCH)] + (texoffset << 4);



}


segment_t getcompositetexture(int16_t tex_index) {
	
	uint8_t texpage = compositetexturepage[tex_index];
	uint8_t texoffset = compositetextureoffset[tex_index];
#ifdef DETAILED_BENCH_STATS
	benchtexturetype = TEXTURE_TYPE_COMPOSITE;
#endif


	if (texpage == 0xFF) { // texture not loaded -  0xFFu is initial state (and impossible anyway)
		segment_t tex_segment;
		R_GetNextTextureBlock(tex_index, texturecompositesizes[tex_index], CACHETYPE_COMPOSITE);
		texpage = compositetexturepage[tex_index];
		texoffset = compositetextureoffset[tex_index];
		//gettexturepage ensures the page is active
		tex_segment = 0x5000u + pagesegments[gettexturepage(texpage, FIRST_TEXTURE_LOGICAL_PAGE, CACHETYPE_COMPOSITE)] + (texoffset << 4);
		R_GenerateComposite(tex_index, tex_segment);
		return tex_segment;
	}

	return 0x5000u + pagesegments[gettexturepage(texpage, FIRST_TEXTURE_LOGICAL_PAGE, CACHETYPE_COMPOSITE)] + (texoffset << 4);


}

segment_t __near getspritetexture(int16_t index) {

	int16_t lump = index + firstspritelump;
	uint8_t texpage = spritepage[index];
	uint8_t texoffset = spriteoffset[index];
#ifdef DETAILED_BENCH_STATS
	benchtexturetype = TEXTURE_TYPE_SPRITE;
#endif


	if (texpage == 0xFF) { // texture not loaded -  0xFFu is initial state (and impossible anyway)
		segment_t tex_segment;
		R_GetNextSpriteBlock(lump);
		texpage = spritepage[index];
		texoffset = spriteoffset[index];
		//getspritepage ensures the page is active
		tex_segment = 0x9000u + pagesegments[getspritepage(texpage)] + (texoffset << 4);
		R_LoadSpriteColumns(lump, tex_segment);
		return tex_segment;
	}

		
	return 0x9000u + pagesegments[getspritepage(texpage)] + (texoffset << 4);

 


} 
 
//
// R_GetColumn
//

/*
void setchecksum(){
	uint16_t i;
	uint16_t __far* data =  MK_FP(0x5000, 0);
	
	for (i = 0; i <32767; i++){
		thechecksum += data[i];
	}

	origcachecount = cachecount;
}*/


extern int16_t setval;

// if texturecolumnlump, mask, etc are not stack vars but near vars, 
// their values can be reused
// if tex is same as last call.

segment_t __near R_GetColumnSegment (int16_t tex, int16_t col, int8_t segloopcachetype) {
	int16_t         lump;
	int16_t_union __far* texturecolumnlump;
	int16_t n = 0;
	uint8_t texcol;
	int16_t subtractor;
	int16_t runningbasetotal = 0;
	int16_t runningtexbasetotal = 0;  // we want to keep track of how much to subtract col by to get the real col offset in the composite, and also know when the RLE run starts
	int16_t fullwidth = texturewidthmasks[tex];
	int16_t basecol = col = col & texturewidthmasks[tex];
	//int16_t basecol = col;
	//col &= texturewidthmasks[tex];
	//basecol -= col;
	
	texcol = col;
	texturecolumnlump = &(texturecolumnlumps_bytes[texturepatchlump_offset[tex]]);

	// todo: maybe unroll this in asm to the max RLE size of this operation?
	// todo: whats the max size of such a texture/rle string? to know for the asm 

	// RLE stuff to figure out actual lump for column
	while (col >= 0) {
		//todo: gross. clean this up in asm; there is a 256 byte case that gets stored as 0.
		// should we change this to be 256 - the number? we dont want a branch.
		// anyway, fix it in asm
		subtractor = texturecolumnlump[n+1].bu.bytelow;
		if (!subtractor){
			subtractor = 256;
		}
		runningbasetotal += subtractor;
		lump = texturecolumnlump[n].h;
		col -= subtractor;
		if (lump >= 0){ // should be equiv to == -1?
			texcol -= subtractor; // is this correct or does it have to be bytelow direct?
			runningtexbasetotal += subtractor;
		}
		n += 2;
	}



	if (lump > 0){
		uint16_t patchwidth = patchwidths[lump-firstpatch];
		//uint8_t  heightval2 = texturecolumnlump[n-1].bu.bytehigh;
		int16_t  cachelumpindex;

		uint8_t heightval = patchheights[lump-firstpatch];
		heightval &= 0x0F;
		if (patchwidth > (fullwidth)){
			patchwidth = fullwidth+1;
		}
		
		for (cachelumpindex = 0; cachelumpindex < NUM_CACHE_LUMPS; cachelumpindex++){
			if (lump == cachedlumps[cachelumpindex]){
				
				if (cachelumpindex == 0){ // todo move this out? or unloop it?
					goto foundcachedlump;
				} else {
					// reorder, put it in spot 0
					segment_t usedsegment = cachedsegmentlumps[cachelumpindex];
					int16_t cachedlump = cachedlumps[cachelumpindex];
					int16_t i;

					// reorder cache MRU				
					for (i = cachelumpindex; i > 0; i--){
						cachedsegmentlumps[i] = cachedsegmentlumps[i-1];
						cachedlumps[i] = cachedlumps[i-1];
					}

					cachedsegmentlumps[0] = usedsegment;
					cachedlumps[0] = cachedlump;
					goto foundcachedlump;	

				}
			}
		}

		// not found, set cache.
		{
			cachedsegmentlumps[3] = cachedsegmentlumps[2];
			cachedsegmentlumps[2] = cachedsegmentlumps[1];
			cachedsegmentlumps[1] = cachedsegmentlumps[0];
			cachedlumps[3] = cachedlumps[2];
			cachedlumps[2] = cachedlumps[1];
			cachedlumps[1] = cachedlumps[0];

			cachedlumps[0] = lump;
			cachedsegmentlumps[0] = getpatchtexture(lump, 0xFF);  // might zero out cachedlump vars;

		}
		
		foundcachedlump:
		// so now cachedlumps[0] and cachedsegmentlumps[0] are the most recently used
		
		// we cant use rle width as it might be longer than single patch width
		// in the case of multiple side by side patches. so we essentially
		// "modulo from negative" by patch width.

		while (col < 0){
			col+= patchwidth;
		}
		// handles RLE runs..
		//while ((runningbasetotal + patchwidth) < basecol){
			//runningbasetotal += patchwidth;
		//}

		runningbasetotal -= subtractor; // remove last subtractor...
		if (subtractor > patchwidth){
			// if this is a multi patch RLE run, then subtractor will be larger than patchwidth
			// add the difference in one go
			// could alternatively modulo outside the function?
			//runningbasetotal += (subtractor - patchwidth);
		}
		
		
		segloopheightvalcache[segloopcachetype] = heightval;
		segloopcachedsegment[segloopcachetype]  = cachedsegmentlumps[0];
		segloopcachedbasecol[segloopcachetype]  = runningbasetotal;
		segloopnextlookup[segloopcachetype]     = runningbasetotal + subtractor;
		
		//segloopprevlookup[segloopcachetype]		= basecol + runningtexbasetotal;
		//segloopcachedbasecol[segloopcachetype]  = basecol + runningtexbasetotal;
		//segloopnextlookup[segloopcachetype]     = basecol + runningtexbasetotal + subtractor;

		/*
		if (setval && tex == 15){
			FILE* fp = fopen("tex.txt", "ab");
			fprintf(fp, "\n a %i %i %i %i %i %i %i", segloopcachedbasecol[segloopcachetype], segloopnextlookup[segloopcachetype], col, basecol, patchwidth, runningtexbasetotal, subtractor);
			fclose(fp);
		}
		*/

		return cachedsegmentlumps[0] + (FastMul8u8u(col , heightval) );

	} else {
		uint8_t collength = texturecollength[tex];

		// todo in the asm make default branch to use cache

		if (cachedtex != tex){
			if (cachedtex2 != tex){
				cachedtex2 = cachedtex;
				cachedsegmenttex2 = cachedsegmenttex;
				cachedcollength2 = cachedcollength;
				cachedtex = tex;
				cachedsegmenttex = getcompositetexture(cachedtex);
				cachedcollength = collength;

			} else {
				// cycle cache so 2 = 1
				tex = cachedtex;
				cachedtex = cachedtex2;
				cachedtex2 = tex;

				tex = cachedsegmenttex;
				cachedsegmenttex = cachedsegmenttex2;
				cachedsegmenttex2 = tex;

				tex = cachedcollength;
				cachedcollength = cachedcollength2;
				cachedcollength2 = tex;

			}

		}
	
		// todo on a fall through this doesnt get set to a modified collength. is that a bug?
		segloopheightvalcache[segloopcachetype] = collength;
		segloopcachedsegment[segloopcachetype]  = cachedsegmenttex;
		segloopcachedbasecol[segloopcachetype] -= texcol;
		segloopnextlookup[segloopcachetype] = subtractor+ segloopcachedbasecol[segloopcachetype]; 
		//todo does this sitll crash...?
		//segloopcachedbasecol[segloopcachetype]  = runningtexbasetotal;
		//segloopnextlookup[segloopcachetype]     = runningtexbasetotal + subtractor;
		/*
		if (setval && tex == 15){
			FILE* fp = fopen("tex.txt", "ab");
			fprintf(fp, "\n b %i %i %i %i %i %i", segloopcachedbasecol[segloopcachetype], segloopnextlookup[segloopcachetype], col, basecol, subtractor);
			fclose(fp);
		}
		*/

		return cachedsegmenttex + (FastMul8u8u(cachedcollength , texcol));

	}

} 


//todo can this be optimized for the masked case??
segment_t __near R_GetMaskedColumnSegment (int16_t tex, int16_t col) {
	int16_t         lump;
	int16_t_union __far* texturecolumnlump;
	int16_t n = 0;
	uint8_t texcol;
	int16_t subtractor;
	maskedcachedbasecol = col;
	maskedheaderpixeolfs = 0xFFFF;


	col &= texturewidthmasks[tex];
	texcol = col;
	texturecolumnlump = &(texturecolumnlumps_bytes_7000[texturepatchlump_offset[tex]]);

	// todo: maybe unroll this in asm to the max RLE size of this operation?
	// todo: whats the max size of such a texture/rle string? to know for the asm 

	// RLE stuff to figure out actual lump for column
	while (col >= 0) {
		//todo: gross. clean this up in asm; there is a 256 byte case that gets stored as 0.
		// should we change this to be 256 - the number? we dont want a branch.
		// anyway, fix it in asm
		subtractor = texturecolumnlump[n+1].bu.bytelow;
		if (!subtractor){
			subtractor = 256;
		}
		lump = texturecolumnlump[n].h;
		col -= subtractor;
		if (lump >= 0){ // should be equiv to == -1?
			texcol -= subtractor;
		}
		n += 2;
	}


	if (lump > 0){
		uint8_t lookup = masked_lookup_7000[tex];
		uint16_t patchwidth = patchwidths_7000[lump-firstpatch];
		//uint8_t heightval = texturecolumnlump[n-1].bu.bytehigh;
		uint8_t heightval = patchheights_7000[lump-firstpatch];
		int16_t  cachelumpindex;
		cachedbyteheight = heightval & 0xF0;
		heightval &= 0x0F;
		
		for (cachelumpindex = 0; cachelumpindex < NUM_CACHE_LUMPS; cachelumpindex++){
			if (lump == cachedlumps[cachelumpindex]){
				
				if (cachelumpindex == 0){
					goto foundcachedlump;
				} else {
					// reorder, put it in spot 0
					segment_t usedsegment = cachedsegmentlumps[cachelumpindex];
					int16_t cachedlump = cachedlumps[cachelumpindex];
					int16_t i;

					// reorder cache MRU				
					for (i = cachelumpindex; i > 0; i--){
						cachedsegmentlumps[i] = cachedsegmentlumps[i-1];
						cachedlumps[i] = cachedlumps[i-1];
					}

					cachedsegmentlumps[0] = usedsegment;
					cachedlumps[0] = cachedlump;
					goto foundcachedlump;	

				}
			}
		}

		// not found, set cache.
		{
			int16_t i;
			for (i = NUM_CACHE_LUMPS - 1; i > 0; i--){
				cachedsegmentlumps[i] = cachedsegmentlumps[i-1];
				cachedlumps[i] = cachedlumps[i-1];
			}
			cachedsegmentlumps[0] = getpatchtexture(lump, lookup);  // might zero out cachedlump vars;
			cachedlumps[0] = lump;

		}
		
		foundcachedlump:
		// so now cachedlumps[0] and cachedsegmentlumps[0] are the most recently used

		// todo what else can we reuse collength and cachedbyteheight here?
		
		// we cant use rle width as it might be longer than single patch width
		// in the case of multiple side by side patches. so we essentially
		// "modulo from negative" by patch width.
		while (col < 0){
			col+= patchwidth;
		}

		maskedcachedsegment   = cachedsegmentlumps[0];
		maskedcachedbasecol  -= col;
		maskednextlookup = subtractor + maskedcachedbasecol;
		
		if (lookup == 0xFF){
			// this happens with weird reverse walls like e1m1 upper wall in the sewage room.. 
			// (but it is a super duper rare case)

			maskedheightvalcache  = heightval;
			return cachedsegmentlumps[0] + (FastMul8u8u(col , heightval) );
		} else {
			// Does this code ever run outside of draw masked?

			masked_header_t __near * maskedheader = &masked_headers[lookup];
			uint16_t __far* pixelofs   =  MK_FP(maskedpixeldataofs_segment, maskedheader->pixelofsoffset);

			uint16_t ofs  = pixelofs[col]; // precached as segment value.

			maskedheaderpixeolfs = maskedheader->pixelofsoffset;

			return cachedsegmentlumps[0] + ofs;
		}
	} else {
		uint8_t collength = texturecollength[tex];

		// todo in the asm make default branch to use cache

		if (cachedtex != tex){
			if (cachedtex2 != tex){
				cachedtex2 = cachedtex;
				cachedsegmenttex2 = cachedsegmenttex;
				cachedcollength2 = cachedcollength;
				cachedtex = tex;
				cachedsegmenttex = getcompositetexture(cachedtex);
				cachedcollength = collength;

			} else {
				// cycle cache so 2 = 1
				tex = cachedtex;
				cachedtex = cachedtex2;
				cachedtex2 = tex;

				tex = cachedsegmenttex;
				cachedsegmenttex = cachedsegmenttex2;
				cachedsegmenttex2 = tex;

				tex = cachedcollength;
				cachedcollength = cachedcollength2;
				cachedcollength2 = tex;

			}

		}
		
		// todo on a fall through this doesnt get set to a modified collength. is that a bug?
		cachedbyteheight = collength;

		maskedheightvalcache  = collength;
		maskedcachedsegment   = cachedsegmenttex;
		maskedcachedbasecol  -= texcol;
		maskednextlookup 	  = subtractor;  // todo does this 
		maskednextlookup     += maskedcachedbasecol;

		return cachedsegmenttex + (FastMul8u8u(cachedcollength , texcol));

	}

} 

// bypass the colofs cache stuff, store just raw pixel data at texlocation. 
void R_LoadPatchColumns(uint16_t lump, segment_t texlocation_segment, boolean ismasked){
	patch_t __far *patch = (patch_t __far *)SCRATCH_ADDRESS_4000;
	int16_t col;
	uint16_t destoffset = 0;
	int16_t patchwidth;


	Z_QuickMapScratch_4000(); // render col info has been paged out..

	W_CacheLumpNumDirect(lump, SCRATCH_ADDRESS_4000);
	patchwidth = patch->width;

	for (col = 0; col < patchwidth; col++){

		column_t __far * column = (column_t __far *)(SCRATCH_ADDRESS_4000 + patch->columnofs[col]);
		while (column->topdelta != 0xFF){
			uint8_t length = column->length;
			byte __far * sourcetexaddr = SCRATCH_ADDRESS_4000 + (((int32_t)column) + 3);
			FAR_memcpy(MK_FP(texlocation_segment,  destoffset), sourcetexaddr, length);
			destoffset += length;
			if (ismasked){

				// round up to the next paragraph for masked textures which do multiple renders
				// and thus the subrenders must also start paragraph aligned...
				// for non masked textures they are always overlapping - or really "should" be.. revisit for buggy gap pixels
				destoffset += (16 - ((length &0xF)) &0xF);
				
			}

	    	column = (column_t __far *)(  (byte  __far*)column + length + 4 );
		}
		if (!ismasked){
			destoffset += (16 - ((destoffset &0xF)) &0xF);
		}

	}

	Z_QuickMapRender4000(); // put render info back

}

// bypass the colofs cache stuff, store just raw pixel data at texlocation. 
//void R_LoadPatchColumns(uint16_t lump, byte __far * texlocation, boolean ismasked){
//todo remove texlocation_segment param if its hardcoded?
void R_LoadPatchColumnsColormap0(uint16_t lump, segment_t texlocation_segment, boolean ismasked){
	patch_t __far *patch = (patch_t __far *)SCRATCH_ADDRESS_4000;
	int16_t col;
	uint16_t destoffset = 0;
	int16_t patchwidth;


	Z_QuickMapScratch_4000(); // render col info has been paged out..

	W_CacheLumpNumDirect(lump, SCRATCH_ADDRESS_4000);
	patchwidth = patch->width;

	for (col = 0; col < patchwidth; col++){

		column_t __far * column = (column_t __far *)(SCRATCH_ADDRESS_4000 + patch->columnofs[col]);
		while (column->topdelta != 0xFF){
			uint8_t length = column->length;
			byte __far * sourcetexaddr = SCRATCH_ADDRESS_4000 + (((int32_t)column) + 3);
			byte __far * destaddr = MK_FP(texlocation_segment,  destoffset);
			byte __far * colormapzero = MK_FP(colormaps_segment,  0);
			//FAR_memcpy(MK_FP(texlocation_segment,  destoffset), sourcetexaddr, length);
			uint8_t i;
			for (i = 0; i < length; i++){
				destaddr[i] = colormapzero[sourcetexaddr[i]];
			}

			destoffset += length;
			if (ismasked){

				// round up to the next paragraph for masked textures which do multiple renders
				// and thus the subrenders must also start paragraph aligned...
				// for non masked textures they are always overlapping - or really "should" be.. revisit for buggy gap pixels
				destoffset += (16 - ((length &0xF)) &0xF);
				
			}

	    	column = (column_t __far *)(  (byte  __far*)column + length + 4 );
		}
		if (!ismasked){
			destoffset += (16 - ((destoffset &0xF)) &0xF);
		}

	}

	Z_QuickMapRender4000(); // put render info back

}

// we store this in the format;
// first 8 bytrs: regular patch_t
// for patch->width num rows:
//   4 bytes per colof as usual, EXCEPT -
//   rather than the inbetween words being 0, they are now postofs
// THEN
// array of all postof data
// THEN
// array of all pixel post runs, paragraph aligned.
// of course, the colofs and postofs have to be filled in at this time too.

void R_LoadSpriteColumns(uint16_t lump, segment_t destpatch_segment){
	patch_t __far * destpatch = MK_FP(destpatch_segment, 0);

	patch_t __far *wadpatch = (patch_t __far *)SCRATCH_ADDRESS_5000;
	uint16_t __far * columnofs = (uint16_t __far *)&(destpatch->columnofs[0]);   // will be updated in place..
	uint16_t currentpixelbyte;
	uint16_t currentpostbyte;
	int16_t col;
	int16_t patchwidth;
	uint16_t __far * postdata;
	byte __far * pixeldataoffset;
	

	uint16_t destoffset;

	Z_QuickMapScratch_5000(); // render col info has been paged out..

	W_CacheLumpNumDirect(lump, SCRATCH_ADDRESS_5000);
	patchwidth = wadpatch->width;

	destpatch->width = wadpatch->width;
	destpatch->height = wadpatch->height;
	destpatch->leftoffset = wadpatch->leftoffset;
	destpatch->topoffset = wadpatch->topoffset;

 	destoffset = 8 + ( patchwidth << 2);
	currentpostbyte = destoffset;
	postdata = (uint16_t __far *)(((byte __far*)destpatch) + currentpostbyte);

	destoffset += spritepostdatasizes[lump-firstspritelump];
	destoffset += (16 - ((destoffset &0xF)) &0xF); // round up so first pixel data starts aligned of course.
	currentpixelbyte = destoffset;
	pixeldataoffset = (byte __far *)MK_FP(destpatch_segment, currentpixelbyte);

	// 32, 368

	for (col = 0; col < patchwidth; col++){

		column_t __far * column = (column_t __far *)MK_FP(SCRATCH_PAGE_SEGMENT, wadpatch->columnofs[col]);
		
		*columnofs = currentpixelbyte >> 4;	// colofs pointer in SEGMENTS. store preshifted.
		columnofs++;
		*columnofs = currentpostbyte;	// postofs pointer
		columnofs++;

 		while (column->topdelta != 0xFF){

			uint8_t length = column->length;
			byte __far * sourcetexaddr = MK_FP(SCRATCH_PAGE_SEGMENT, (((int32_t)column) + 3));

			FAR_memcpy(pixeldataoffset, sourcetexaddr, length);

			length += ((16 - (length &0xF)) &0xF);
			currentpixelbyte += length;
			pixeldataoffset += length;

			*postdata = *((uint16_t __far*)column);
			postdata++;
			currentpostbyte +=2;

	    	column = (column_t __far *)(  ((byte  __far*)column) + column->length + 4 );
		}

 
		*postdata = 0xFFFF;
		postdata++;
		currentpostbyte +=2;

	}

	Z_QuickMapRender5000(); // put render info back

}

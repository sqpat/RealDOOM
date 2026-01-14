;
; Copyright (C) 1993-1996 Id Software, Inc.
; Copyright (C) 1993-2008 Raven Software
; Copyright (C) 2016-2017 Alexey Khokholov (Nuke.YKT)
;
; This program is free software; you can redistribute it and/or
; modify it under the terms of the GNU General Public License
; as published by the Free Software Foundation; either version 2
; of the License, or (at your option) any later version.
;
; This program is distributed in the hope that it will be useful,
; but WITHOUT ANY WARRANTY; without even the implied warranty of
; MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
; GNU General Public License for more details.
;

INCLUDE constant.inc
INCLUDE m_offset.inc


CLC_OPCODE = 0F8h
STC_OPCODE = 0F9h

SCREENWIDTH			=   320
SCREENWIDTHOVER2	=   160
SCREENHEIGHT		=	200

PEL_WRITE_ADR		=	03C8h
PEL_DATA			=	03C9h
SC_INDEX			=	03C4h
SC_MAPMASK			=	2
SC_DATA 			=   03C5h

GC_INDEX        	=   03CEh
CRTC_INDEX 			=   03D4h
GC_READMAP      	=   4
GC_MODE             =   5

DO_DELAYED_MAP_CHEAT    = 1
DO_DELAYED_INVIS_CHEAT  = 2
CHECK_FOR_DELAYED_CHEAT = 4



SCAMP_PAGE_9000_OFFSET  =   020h

IFDEF COMP_CH
	PAGE_SWAP_ARG_MULT = 1
ELSE
    PAGE_SWAP_ARG_MULT = 2
ENDIF

;__nullarea =						 0

; static pointer.
_gamekeydown = 0200h

_NULL_OFFSET = 010h


_segloopnextlookup    = 			_NULL_OFFSET + 00000h
_seglooptexrepeat    = 				_NULL_OFFSET + 00004h
_maskedtexrepeat =                  _NULL_OFFSET + 00006h
_segloopcachedsegment  = 			_NULL_OFFSET + 00008h
_segloopheightvalcache = 			_NULL_OFFSET + 0000Ch
_eventtail =					  	_NULL_OFFSET + 0000Eh
_eventhead =					  	_NULL_OFFSET + 0000Fh


_spanfunc_prt = 					_NULL_OFFSET + 00010h
_spanfunc_destview_offset = 		_NULL_OFFSET + 00018h
_spanfunc_inner_loop_count =		_NULL_OFFSET + 00020h
_spanfunc_outp = 					_NULL_OFFSET + 00024h
_maxammo = 	     					_NULL_OFFSET + 00028h

_quality_port_lookup = 				_NULL_OFFSET + 00030h

_cachedsegmentlumps =              _NULL_OFFSET + 0003Ch
_cachedlumps =                 	   _NULL_OFFSET + 00044h
_cachedtex =                 	   _NULL_OFFSET + 0004Ch
_cachedcollength =                 _NULL_OFFSET + 00050h

_lastopening =                   	_NULL_OFFSET + 00052h
_segloopprevlookup =                _NULL_OFFSET + 00054h
_segloopcachedbasecol =             _NULL_OFFSET + 00058h
_cachedsegmenttex =                 _NULL_OFFSET + 0005Ch
	
_basexscale = 						_NULL_OFFSET + 00060h
_baseyscale = 						_NULL_OFFSET + 00064h
_viewx = 							_NULL_OFFSET + 00068h
_viewy = 							_NULL_OFFSET + 0006Ch
_viewz = 							_NULL_OFFSET + 00070h
_centeryfrac_shiftright4 = 			_NULL_OFFSET + 00074h
_viewangle =                		_NULL_OFFSET + 00078h
_viewz_shortheight = 				_NULL_OFFSET + 0007Ch
_screen_segments = 					_NULL_OFFSET + 0007Eh

_maskedtexture = 					_NULL_OFFSET + 00088h
_map31_exists =                     _NULL_OFFSET + 00089h

_spechit =       					_NULL_OFFSET + 0008Ah
_bombsource =       				_NULL_OFFSET + 0009Ah
_bombspot =       					_NULL_OFFSET + 0009Ch
_bombdamage =       				_NULL_OFFSET + 0009Eh
_bombspot_pos = 					_NULL_OFFSET + 000A0h

_spryscale = 						_NULL_OFFSET + 000A4h
_sprtopscreen =	 					_NULL_OFFSET + 000A8h
_nomonsters =                       _NULL_OFFSET + 000ACh
_respawnmonsters =                  _NULL_OFFSET + 000ADh

_pendingmusicenum =                 _NULL_OFFSET + 000AEh
_pendingmusicenumlooping =          _NULL_OFFSET + 000AFh


_skipdirectdraws = 					_NULL_OFFSET + 000B0h
_is_ultimate = 						_NULL_OFFSET + 000B1h
_dc_yl = 							_NULL_OFFSET + 000B2h
_dc_yh = 							_NULL_OFFSET + 000B4h

_firstspritelump = 					_NULL_OFFSET + 000B6h

_finaletext =                    	_NULL_OFFSET + 000B8h
_finalecount =                   	_NULL_OFFSET + 000BAh
_finalestage =                   	_NULL_OFFSET + 000BCh
_emsconventional =                  _NULL_OFFSET + 000BDh

_finale_laststage =              	_NULL_OFFSET + 000BEh
_playingstate = 	                _NULL_OFFSET + 000BFh

_mfloorclip = 						_NULL_OFFSET + 000C0h
_mceilingclip = 					_NULL_OFFSET + 000C4h

_viletryx =                         _NULL_OFFSET + 000CCh
_viletryy =                         _NULL_OFFSET + 000D0h
_viewangle_shiftright1 = 			_NULL_OFFSET + 000D4h
_snd_SfxDevice = 					_NULL_OFFSET + 000D6h
_snd_MusicDevice =				    _NULL_OFFSET + 000D7h

_ds_source_offset = 				_NULL_OFFSET + 000D8h
_ds_source_segment = 				_NULL_OFFSET + 000DAh
; DA is technically segment and D8 is OFFSET
_currentscreen    = 				_NULL_OFFSET + 000DCh
_destview    = 						_NULL_OFFSET + 000E0h
_destscreen    = 					_NULL_OFFSET + 000E4h
_tantoangle_segment  = 				_NULL_OFFSET + 000E8h
_spanfunc_jump_segment_storage = 	_NULL_OFFSET + 000EAh
_totalkills = 						_NULL_OFFSET + 000ECh
_totalitems = 						_NULL_OFFSET + 000EEh
_totalsecret = 						_NULL_OFFSET + 000F0h
_TS_TimesInInterrupt = 				_NULL_OFFSET + 000F2h
_TS_InInterrupt = 					_NULL_OFFSET + 000F3h
_validcount_global =				_NULL_OFFSET + 000F4h
_firstpatch =                       _NULL_OFFSET + 000F6h
_numbraintargets = 					_NULL_OFFSET + 000F8h
_braintargeton = 					_NULL_OFFSET + 000FAh
_brainspit_easy = 					_NULL_OFFSET + 000FCh
_floatok = 							_NULL_OFFSET + 000FDh
_corpsehitRef = 					_NULL_OFFSET + 000FEh
_vileobj = 							_NULL_OFFSET + 00100h
_fastparm =	                        _NULL_OFFSET + 00100h
_gameskill =	                    _NULL_OFFSET + 00101h
_TaskServiceCount =	                _NULL_OFFSET + 00102h
_viewangle_shiftright3 = 			_NULL_OFFSET + 00104h
_dc_source_segment =	 			_NULL_OFFSET + 0010Ah
; todo could ds and cx stuff overlap?
_ds_y = 				    		_NULL_OFFSET + 0010Ch
_dc_x = 							_NULL_OFFSET + 00110h
_cachedheight_segment_storage =    	_NULL_OFFSET + 00112h
_distscale_segment_storage =    	_NULL_OFFSET + 00114h
_cacheddistance_segment_storage =   _NULL_OFFSET + 00116h
_cachedxstep_segment_storage =    	_NULL_OFFSET + 00118h
_cachedystep_segment_storage =    	_NULL_OFFSET + 0011Ah

_pspriteiscale =                    _NULL_OFFSET + 0011Ch
_tmflags1 =                         _NULL_OFFSET + 00120h
_tmfloorz =                         _NULL_OFFSET + 00122h
_tmceilingz =                       _NULL_OFFSET + 00124h
_tmdropoffz =                       _NULL_OFFSET + 00126h
_MULT_4096 =                    	_NULL_OFFSET + 00128h
_sb_port =              	      	_NULL_OFFSET + 00130h
_sb_dma =           	         	_NULL_OFFSET + 00132h
_sb_irq =                       	_NULL_OFFSET + 00133h
_sfxcache_head =                    _NULL_OFFSET + 00134h
_sfxcache_tail =                    _NULL_OFFSET + 00135h
_grmode =                    		_NULL_OFFSET + 00136h
_novideo =                    		_NULL_OFFSET + 00137h
_visplanelookupsegments =           _NULL_OFFSET + 00138h
_firstflat =                  		_NULL_OFFSET + 0013Eh
_castattacking =                 	_NULL_OFFSET + 00140h
_castdeath =                     	_NULL_OFFSET + 00141h
_castonmelee =                   	_NULL_OFFSET + 00142h
_castframes =                    	_NULL_OFFSET + 00143h
_casttics =                      	_NULL_OFFSET + 00144h
_castnum =                       	_NULL_OFFSET + 00145h
_finaleflat =                   	_NULL_OFFSET + 00146h
_R_TextureNumForName_addr =         _NULL_OFFSET + 00148h
_tmthing_pos =                      _NULL_OFFSET + 0014Ch
_trace =                            _NULL_OFFSET + 00150h
_currentflatpage =            		_NULL_OFFSET + 00160h
_lastflatcacheindicesused =         _NULL_OFFSET + 00164h
_skyflatnum =            			_NULL_OFFSET + 00168h
_extralight =            			_NULL_OFFSET + 00169h
_visplanedirty =            		_NULL_OFFSET + 0016Ah
_screenblocks =            			_NULL_OFFSET + 0016Bh
_lastvisplane =            			_NULL_OFFSET + 0016Ch
_hudneedsupdate =                   _NULL_OFFSET + 0016Eh
_gamestate =                        _NULL_OFFSET + 0016Fh
_tmx =                             _NULL_OFFSET + 00170h
_tmy =                             _NULL_OFFSET + 00174h
_tmxmove =                         _NULL_OFFSET + 00178h
_tmymove =                         _NULL_OFFSET + 0017Ch

_currentpageframes =     			_NULL_OFFSET + 00180h

IFDEF COMP_CH
ELSE
_emshandle =     					_NULL_OFFSET + 00184h
_pagenum9000 =     					_NULL_OFFSET + 00186h
ENDIF
_prndindex =     					_NULL_OFFSET + 00188h
_spanquality =              	    _NULL_OFFSET + 00189h
_setStateReturn =     				_NULL_OFFSET + 0018Ah
_R_GetPatchTexture_addr =           _NULL_OFFSET + 0018Ch
_W_CacheLumpNumDirect_addr =        _NULL_OFFSET + 00190h
_floorplaneindex =               	_NULL_OFFSET + 00194h
_ceilingplaneindex =             	_NULL_OFFSET + 00196h
_viewwidth =                     	_NULL_OFFSET + 00198h
_viewheight =	                    _NULL_OFFSET + 0019Ah
_ceiltop =      	                _NULL_OFFSET + 0019Ch
_floortop =         	            _NULL_OFFSET + 001A0h
_frontsector =          	        _NULL_OFFSET + 001A4h
_backsector =               	    _NULL_OFFSET + 001A8h
_playingtime =		                _NULL_OFFSET + 001ACh
_active_visplanes =             	_NULL_OFFSET + 001B0h
_wipegamestate =                    _NULL_OFFSET + 001B5h
_visplane_offset =              	_NULL_OFFSET + 001B6h
_dirtybox =              			_NULL_OFFSET + 001E8h
_ticcount =			              	_NULL_OFFSET + 001F0h
_R_FlatNumForName_addr =             _NULL_OFFSET + 001F4h
_deadAttackerX =                     _NULL_OFFSET + 001F8h
_deadAttackerY =                     _NULL_OFFSET + 001FCh
_am_scale_mtof =                     _NULL_OFFSET + 00200h
_am_scale_ftom =       		     	 _NULL_OFFSET + 00204h
_I_SetPalette_addr = 	        	 _NULL_OFFSET + 00208h
_V_MarkRect_addr =                   _NULL_OFFSET + 0020Ch
; 210 unused?
_wipeduration =                      _NULL_OFFSET + 00214h
_detailshift2minus =  		 		 _NULL_OFFSET + 00216h
_maskedheaderpixeolfs =				 _NULL_OFFSET + 00218h
_maskedtexturecol =					 _NULL_OFFSET + 0021Ch
_masked_headers =                    _NULL_OFFSET + 00220h
_curseg =                          	 _NULL_OFFSET + 00280h
_curseg_render =                     _NULL_OFFSET + 00282h
_save_p =                            _NULL_OFFSET + 00284h
_maskednextlookup =                  _NULL_OFFSET + 00288h
_maskedprevlookup =                  _NULL_OFFSET + 0028Ah
_tmthing =                           _NULL_OFFSET + 0028Ch
_maskedcachedbasecol =               _NULL_OFFSET + 0028Eh
_maskedcachedsegment =               _NULL_OFFSET + 00290h
_maskedheightvalcache =              _NULL_OFFSET + 00292h
_vsprsortedheadfirst =               _NULL_OFFSET + 00293h
_lastvisspritesegment =              _NULL_OFFSET + 00294h
_lastvisspritesegment2 =             _NULL_OFFSET + 00296h
_lastvisspritepatch =                _NULL_OFFSET + 00298h
_lastvisspritepatch2 =               _NULL_OFFSET + 0029Ah
_ds_p =               				 _NULL_OFFSET + 0029Ch

_olddb =							 _NULL_OFFSET + 002A0h
_detailshift = 						 _NULL_OFFSET + 002B0h
_detailshiftitercount = 			 _NULL_OFFSET + 002B2h
_detailshiftandval = 				 _NULL_OFFSET + 002B4h
_ceilphyspage =                  	 _NULL_OFFSET + 002B6h
_floorphyspage =                 	 _NULL_OFFSET + 002B7h
_gameaction =                 		 _NULL_OFFSET + 002B8h
_viewactive =                 		 _NULL_OFFSET + 002B9h
_am_bigstate =                 		 _NULL_OFFSET + 002BAh
_commercial =                 		 _NULL_OFFSET + 002BBh
_registered =                 		 _NULL_OFFSET + 002BCh
_shareware =                 		 _NULL_OFFSET + 002BDh
_ds_colormap_index = 				 _NULL_OFFSET + 002BEh
_fixedcolormap = 					 _NULL_OFFSET + 002BFh
_R_DrawSkyPlane_addr =               _NULL_OFFSET + 002C0h
_R_DrawSkyPlane_addr_Offset =        _NULL_OFFSET + 002C0h
_Z_SetOverlay_addr =                 _NULL_OFFSET + 002C4h

_mus_playing =    			     	 _NULL_OFFSET + 002C8h
_mus_paused =    			     	 _NULL_OFFSET + 002C9h
_sendpause =    			    	 _NULL_OFFSET + 002CAh
_sendsave =    			      	 	 _NULL_OFFSET + 002CBh
_R_GetCompositeTexture_addr =        _NULL_OFFSET + 002CCh

_sb_voicelist =	 	  			   	 _NULL_OFFSET + 002D0h
_savename = 	      			     _NULL_OFFSET + 00310h

_fopen_addr =     			         _NULL_OFFSET + 00320h
_fseek_addr =     			         _NULL_OFFSET + 00324h
_fread_addr =     			         _NULL_OFFSET + 00328h
_fclose_addr =    			         _NULL_OFFSET + 0032Ch
_cached_psetup_lump_offset =		 _NULL_OFFSET + 00330h
_S_InitSFXCache_addr =     	    	 _NULL_OFFSET + 00334h



_demoplayback =					     _NULL_OFFSET + 00338h
_columnquality =              	     _NULL_OFFSET + 00339h
_useDeadAttackerRef =              	 _NULL_OFFSET + 0033Ah
_paused	=						     _NULL_OFFSET + 0033Bh
_menuactive	=					     _NULL_OFFSET + 0033Ch

_followplayer =			             _NULL_OFFSET + 0033Dh
_am_cheating =			             _NULL_OFFSET + 0033Eh
_am_grid = 		       		         _NULL_OFFSET + 0033Fh


_psprites =              			 _NULL_OFFSET + 00340h
_vga_read_port_lookup =              _NULL_OFFSET + 00358h
_vissprite_p =                       _NULL_OFFSET + 00370h
; high byte always 0
_cachedbyteheight =                  _NULL_OFFSET + 00372h
_currentMusPage = 					 _NULL_OFFSET + 00374h
_snd_MusicVolume =                   _NULL_OFFSET + 00375h
_gameepisode = 						 _NULL_OFFSET + 00376h
_gamemap = 							 _NULL_OFFSET + 00377h
_savedescription =                   _NULL_OFFSET + 00378h
_demoname =                          _NULL_OFFSET + 00398h


_skytexture = 						 _NULL_OFFSET + 003B8h
_numflats =  					     _NULL_OFFSET + 003BAh
_numpatches =  					     _NULL_OFFSET + 003BCh
_numspritelumps =  				     _NULL_OFFSET + 003BEh
_numtextures =  				     _NULL_OFFSET + 003C0h

_pcspeaker_currentoffset = 			 _NULL_OFFSET + 003C2h
_pcspeaker_endoffset = 			 	 _NULL_OFFSET + 003C4h
_SKY_String = 					 	 _NULL_OFFSET + 003C6h
_numChannels = 						 _NULL_OFFSET + 003CBh
_MainLogger_addr =      	         _NULL_OFFSET + 003CCh

_am_stopped = 						 _NULL_OFFSET + 003D0h
_automapactive =                 	 _NULL_OFFSET + 003D1h
_currentThinkerListHead = 			 _NULL_OFFSET + 003D2h

_W_LumpLength_addr =                 _NULL_OFFSET + 003D4h
_demo_p =            				 _NULL_OFFSET + 003D8h
_DEMO_SEGMENT_PTR =  				 _NULL_OFFSET + 003DAh
;_I_WaitVBL_addr =       		     _NULL_OFFSET + 003DCh

_braintargets =                      _NULL_OFFSET + 003E0h
_tmbbox =                            _NULL_OFFSET + 00420h

_SECTORS_SEGMENT_PTR =               _NULL_OFFSET + 00430h
_LINES_PHYSICS_SEGMENT_PTR =         _NULL_OFFSET + 00432h
_VERTEXES_SEGMENT_PTR =			     _NULL_OFFSET + 00434h
_LINEFLAGSLIST_SEGMENT_PTR =         _NULL_OFFSET + 00436h
_SEENLINES_6800_SEGMENT_PTR =        _NULL_OFFSET + 00438h
_SIDES_SEGMENT_PTR =			     _NULL_OFFSET + 0043Ah
_LINES_SEGMENT_PTR = 				 _NULL_OFFSET + 0043Ch
_ORIGINAL_CS_SEGMENT_PTR =           _NULL_OFFSET + 0043Eh

_EMS_PAGE =							 _NULL_OFFSET + 00440h
_SFX_PAGE_SEGMENT_PTR =				 _NULL_OFFSET + 00442h
_PC_SPEAKER_OFFSETS_SEGMENT_PTR =	 _NULL_OFFSET + 00444h
_PC_SPEAKER_SFX_DATA_SEGMENT_PTR =	 _NULL_OFFSET + 00446h
_WAD_PAGE_FRAME_PTR =				 _NULL_OFFSET + 00448h
_BSP_CODE_SEGMENT_PTR =				 _NULL_OFFSET + 0044Ah

_cht_CheckCheat_Far_addr = 			 _NULL_OFFSET + 0044Ch
_d_skill =                           _NULL_OFFSET + 00450h
_d_episode =                         _NULL_OFFSET + 00451h
_d_map =                             _NULL_OFFSET + 00452h
_secretexit =                        _NULL_OFFSET + 00453h


_V_DrawPatch_addr =              	 _NULL_OFFSET + 00454h
_m_paninc = 				 	 	 _NULL_OFFSET + 00458h

; 20 bytes
_wminfo =			                 _NULL_OFFSET + 0045Ch
_V_DrawFullscreenPatch_addr =        _NULL_OFFSET + 00470h
_getStringByIndex_addr =             _NULL_OFFSET + 00474h


_W_CacheLumpNameDirect_addr =        _NULL_OFFSET + 00478h
_W_CacheLumpNumDirectFragment_addr = _NULL_OFFSET + 0047Ch
_W_GetNumForName_addr =              _NULL_OFFSET + 00480h
_SFX_PlayPatch_addr =                _NULL_OFFSET + 00484h
_S_DecreaseRefCountFar_addr =      	 _NULL_OFFSET + 00488h

; 13 bytes in length
_filename_argument = 				 _NULL_OFFSET + 0048Ch

_rndindex = 						 _NULL_OFFSET + 00499h
_mousex = 							 _NULL_OFFSET + 0049Ah
_singledemo = 						 _NULL_OFFSET + 0049Ch

; 49d unused

_numsectors =						 _NULL_OFFSET + 0049Eh
_numlines =						     _NULL_OFFSET + 004A0h
_numvertexes =						 _NULL_OFFSET + 004A2h
_numsegs =						     _NULL_OFFSET + 004A4h
_numsubsectors =				     _NULL_OFFSET + 004A6h
_numnodes =						 	 _NULL_OFFSET + 004A8h
_numsides =						 	 _NULL_OFFSET + 004AAh
_bmapwidth =						 _NULL_OFFSET + 004ACh
_bmapheight =						 _NULL_OFFSET + 004AEh
_bmaporgx =						 	 _NULL_OFFSET + 004B0h
_bmaporgy =				             _NULL_OFFSET + 004B2h

_I_Error_addr =                      _NULL_OFFSET + 004B4h
_P_InitThinkers_addr =               _NULL_OFFSET + 004B8h

_snd_DesiredSfxDevice =              _NULL_OFFSET + 004BCh
_snd_DesiredMusicDevice =            _NULL_OFFSET + 004BDh
_snd_SBirq =              			 _NULL_OFFSET + 004BEh
_snd_SBdma =              			 _NULL_OFFSET + 004BFh


_cached_playerMobj_x_highbits =      _NULL_OFFSET + 004C0h
_cached_playerMobj_y_highbits =  	 _NULL_OFFSET + 004C2h

_R_DrawSkyPlaneDynamic_addr =  	     _NULL_OFFSET + 004C4h
_R_DrawSkyPlaneDynamic_addr_OFfset = _NULL_OFFSET + 004C4h
_snd_SBport =                        _NULL_OFFSET + 004C8h
_snd_Mport =                         _NULL_OFFSET + 004CAh
_I_Quit_addr = 			             _NULL_OFFSET + 004CCh

; 52 bytes
_player_message_string =  			 _NULL_OFFSET + 004D0h

_screen_botleft_x =				     _NULL_OFFSET + 00504h
_screen_botleft_y =				     _NULL_OFFSET + 00506h
_screen_topright_x =				 _NULL_OFFSET + 00508h
_screen_topright_y =			     _NULL_OFFSET + 0050Ah

_planezlight = 						_NULL_OFFSET + 00050Ch
_caststate =                        _NULL_OFFSET + 000510h

_playingdriver =                     _NULL_OFFSET + 00514h
_currentsong_start_offset =          _NULL_OFFSET + 00518h
_currentsong_playing_offset =        _NULL_OFFSET + 0051Ah
_currentsong_ticks_to_process =      _NULL_OFFSET + 0051Ch
_loops_enabled =    			     _NULL_OFFSET + 0051Eh
_inhelpscreens =    			     _NULL_OFFSET + 0051Fh

_sightzstart =				         _NULL_OFFSET + 00524h
_topslope =				         	 _NULL_OFFSET + 00528h
_bottomslope =					     _NULL_OFFSET + 0052Ch
_cachedt2x =				         _NULL_OFFSET + 00530h
_cachedt2y =					     _NULL_OFFSET + 00534h
_strace =					         _NULL_OFFSET + 00538h
_sfx_free_bytes = 					 _NULL_OFFSET + 00548h


_activespritepages =                 _NULL_OFFSET + 00570h
_activespritenumpages =              _NULL_OFFSET + 00574h
_spriteL1LRU =                 		 _NULL_OFFSET + 00578h
_spritecache_l2_head =               _NULL_OFFSET + 0057Ch
_spritecache_l2_tail =               _NULL_OFFSET + 0057Dh
_texturecache_l2_head =              _NULL_OFFSET + 0057Eh
_texturecache_l2_tail =              _NULL_OFFSET + 0057Fh
_activetexturepages =                _NULL_OFFSET + 00580h
_activenumpages =                 	 _NULL_OFFSET + 00588h
_textureL1LRU =                 	 _NULL_OFFSET + 00590h
_BASE_CHEAT_ADDRESS_OFFSET_PTR =     _NULL_OFFSET + 00598h
; 59a to 5ad free
_flatcache_l2_head =                 _NULL_OFFSET + 005AEh
_flatcache_l2_tail =                 _NULL_OFFSET + 005AFh
_segloopprevlookup =                 _NULL_OFFSET + 005B0h
_segloopcachedbasecol =              _NULL_OFFSET + 005B4h
_cachedsegmenttex =                  _NULL_OFFSET + 005B8h
_playerMobj =                   	 _NULL_OFFSET + 005BCh
_ceilinglinenum =                    _NULL_OFFSET + 005BEh

_lineopening =				         _NULL_OFFSET + 005C0h

_playerMobjRef =				     _NULL_OFFSET + 005C6h
_intercept_p =				         _NULL_OFFSET + 005C8h
_aimslope = 				         _NULL_OFFSET + 005CCh
_bestslidefrac =				     _NULL_OFFSET + 005D0h
_bestslidelinenum =				     _NULL_OFFSET + 005D4h
_numspechit =				         _NULL_OFFSET + 005D6h
_lastcalculatedsector =				 _NULL_OFFSET + 005D8h

_shootthing =				 		 _NULL_OFFSET + 005DAh
_shootz =				 			 _NULL_OFFSET + 005DCh
_la_damage = 		   			     _NULL_OFFSET + 005E0h

_linetarget = 		   			     _NULL_OFFSET + 005E2h
_linetarget_pos = 		   			 _NULL_OFFSET + 005E4h
_attackrange16 = 		   			 _NULL_OFFSET + 005E8h
_usergame =		   		         	 _NULL_OFFSET + 005EAh
_crushchange = 		   			 	 _NULL_OFFSET + 005EBh
_leveltime =     		   			 _NULL_OFFSET + 005ECh
;_gamekeydownpointer = 				 _NULL_OFFSET + 005F0h
_dodelayedcheatthisframe =			 _NULL_OFFSET + 005F2h
;_currenttask =            		     _NULL_OFFSET + 005F3h

_centerx = 							 _NULL_OFFSET + 005F4h
_centery = 							 _NULL_OFFSET + 005F6h

_V_DrawFullscreenPatch_FromMenu_addr = _NULL_OFFSET + 005F8h
;_FastDiv32u16u_addr =               _NULL_OFFSET + 005FCh


_playerMobj_pos =		         	 _NULL_OFFSET + 00600h
_MOBJPOSLIST_6800_SEGMENT_PTR =      _NULL_OFFSET + 00602h
_setStateReturn_pos =		         _NULL_OFFSET + 00604h
_gametic =						     _NULL_OFFSET + 00608h
_clipangle =				         _NULL_OFFSET + 0060Ch
_fieldofview =				         _NULL_OFFSET + 0060Eh

_solidsegs = 			         	 _NULL_OFFSET + 00610h
_newend = 				         	 _NULL_OFFSET + 00690h
_pspritescale = 		         	 _NULL_OFFSET + 00692h
_currentoverlay = 		         	 _NULL_OFFSET + 00694h
_turnheld = 		         	 	 _NULL_OFFSET + 00695h


_r_cachedplayerMobjsecnum = 		 _NULL_OFFSET + 00696h
_scaledviewwidth = 					 _NULL_OFFSET + 00698h
_viewwindowoffset = 				 _NULL_OFFSET + 0069Ah
_pendingdetail = 				 	 _NULL_OFFSET + 0069Ch
_setsizeneeded = 				 	 _NULL_OFFSET + 0069Eh
_setblocks = 					 	 _NULL_OFFSET + 0069Fh
_player = 						 	 _NULL_OFFSET + 006A0h
_skyquality =  					 	 _NULL_OFFSET + 00703h
_viewwindowx = 					 	 _NULL_OFFSET + 00704h
_viewwindowy = 					 	 _NULL_OFFSET + 00706h
_R_DrawPlanesCall = 	    	 	 _NULL_OFFSET + 00708h
_R_DrawPlanesCallOffset = 	    	 _NULL_OFFSET + 00708h
_R_DrawMaskedCall = 			 	 _NULL_OFFSET + 0070Ch
_R_DrawMaskedCallOffset = 			 _NULL_OFFSET + 0070Ch
_R_WriteBackMaskedFrameConstantsCall =  _NULL_OFFSET + 00710h
_R_WriteBackMaskedFrameConstantsCallOffset =  _NULL_OFFSET + 00710h
_NetUpdate_addr =					 _NULL_OFFSET + 00714h




_mtof_zoommul =        			     _NULL_OFFSET + 00718h
_ftom_zoommul =        			     _NULL_OFFSET + 0071Ah
_am_max_scale_mtof =       		     _NULL_OFFSET + 0071Ch

;_FastDiv3216u_addr =				 _NULL_OFFSET + 00720h
_bulletslope = 			 			 _NULL_OFFSET + 00724h
_weaponinfo = 			 			 _NULL_OFFSET + 00728h
_W_CheckNumForNameFar_addr =         _NULL_OFFSET + 0078Ch

_gametime = 				         _NULL_OFFSET + 00790h
_maketic = 				             _NULL_OFFSET + 00794h
_starttime = 				         _NULL_OFFSET + 00798h
_oldentertics =					     _NULL_OFFSET + 0079Ch
_inhelpscreensstate =				 _NULL_OFFSET + 0079Eh
_fullscreen =					     _NULL_OFFSET + 0079Fh

_wadfiles = 						 _NULL_OFFSET + 007A0h
_filetolumpindex = 					 _NULL_OFFSET + 007A8h
_numlumps = 						 _NULL_OFFSET + 007AEh
_filetolumpsize = 				     _NULL_OFFSET + 007B0h
_currentloadedfileindex =       	 _NULL_OFFSET + 007BCh
_mousepresent =				       	 _NULL_OFFSET + 007BDh
_respawnparm =				       	 _NULL_OFFSET + 007BEh
_demorecording =			       	 _NULL_OFFSET + 007BFh
_doomsav0_string =  		       	 _NULL_OFFSET + 007C0h



_startskill = 						 _NULL_OFFSET + 007CDh
_startepisode = 					 _NULL_OFFSET + 007CEh
_startmap = 						 _NULL_OFFSET + 007CFh


_key_right =						 _NULL_OFFSET + 007D0h
_key_left =							 _NULL_OFFSET + 007D1h
_key_up =							 _NULL_OFFSET + 007D2h
_key_down =							 _NULL_OFFSET + 007D3h
_key_strafeleft = 					 _NULL_OFFSET + 007D4h
_key_straferight = 					 _NULL_OFFSET + 007D5h
_key_fire =							 _NULL_OFFSET + 007D6h
_key_use = 							 _NULL_OFFSET + 007D7h
_key_strafe =						 _NULL_OFFSET + 007D8h
_key_speed =						 _NULL_OFFSET + 007D9h
_mousebfire =						 _NULL_OFFSET + 007DAh
_mousebstrafe = 					 _NULL_OFFSET + 007DBh
_mousebforward = 					 _NULL_OFFSET + 007DCh
_precache = 						 _NULL_OFFSET + 007DDh
_cached_psetup_level_lump =		     _NULL_OFFSET + 007DEh

_screen_oldloc =					 _NULL_OFFSET + 007E0h
_old_screen_botleft_x =				 _NULL_OFFSET + 007E4h
_old_screen_botleft_y =				 _NULL_OFFSET + 007E6h

_message_counter =					 _NULL_OFFSET + 007E8h

_levelTimer =						 _NULL_OFFSET + 007E9h
_numlinespecials =					 _NULL_OFFSET + 007EAh
;3c or 60 bytes
_activeceilings =                    _NULL_OFFSET + 007ECh
;3c or 60 bytes
_activeplats =                       _NULL_OFFSET + 00828h
;24 or 36 bytes
_buttonlist =                        _NULL_OFFSET + 00864h
_levelTimeCount =				     _NULL_OFFSET + 00888h
_lastanim =				             _NULL_OFFSET + 0088Ch
_numswitches =						 _NULL_OFFSET + 0088Eh
_anims =				     		 _NULL_OFFSET + 00890h

_switchlist =				         _NULL_OFFSET + 00950h
_skullAnimCounter =				     _NULL_OFFSET + 00A18h
_whichSkull =				         _NULL_OFFSET + 00A1Ah

_borderdrawcount =       		     _NULL_OFFSET + 00A1Ch
_message_dontfuckwithme =            _NULL_OFFSET + 00A1Dh
_message_on =     			         _NULL_OFFSET + 00A1Eh
_message_nottobefuckedwith =         _NULL_OFFSET + 00A1Fh


_HeadTask =					         _NULL_OFFSET + 00A20h
_pagetic = 							 _NULL_OFFSET + 00A22h
_pagename = 						 _NULL_OFFSET + 00A24h
_singletics = 						 _NULL_OFFSET + 00A26h
_timingdemo = 						 _NULL_OFFSET + 00A27h
_defdemoname = 						 _NULL_OFFSET + 00A28h
_mousearray = 						 _NULL_OFFSET + 00A2Ch
_mousebuttons = 					 _NULL_OFFSET + 00A2Dh
_usemouse = 						 _NULL_OFFSET + 00A30h



_demosequence =	       		         _NULL_OFFSET + 00A31h

_STRING_newline =                    _NULL_OFFSET + 00A32h

_advancedemo =	       			     _NULL_OFFSET + 00A34h
_usegamma =	       			         _NULL_OFFSET + 00A35h
_sfxVolume =	       			     _NULL_OFFSET + 00A36h
_musicVolume =	       			     _NULL_OFFSET + 00A37h
_snd_SfxVolume =      			     _NULL_OFFSET + 00A38h
_detailLevel =	       			     _NULL_OFFSET + 00A39h
_screenSize =	       			     _NULL_OFFSET + 00A3Ah
_mouseSensitivity =   			     _NULL_OFFSET + 00A3Bh
_showMessages =       			     _NULL_OFFSET + 00A3Ch
_quickSaveSlot =      			     _NULL_OFFSET + 00A3Dh
_savegameslot =       			     _NULL_OFFSET + 00A3Eh
_modifiedgame =       			     _NULL_OFFSET + 00A3Fh
_hu_font =	 	      			     _NULL_OFFSET + 00A40h


_viewactivestate =	 	     	     _NULL_OFFSET + 00ABEh
_menuactivestate =	 	     	     _NULL_OFFSET + 00ABFh
__STACKLOW =          				 _NULL_OFFSET + 00AC0h
__STACKTOP =          				 _NULL_OFFSET + 00AC2h

_st_gamestate =	  	  				 _NULL_OFFSET + 00AC4h
_st_firsttime =	  	  				 _NULL_OFFSET + 00AC5h
_am_min_scale_mtof =       	         _NULL_OFFSET + 00AC6h
_screen_viewport_width =	  	  	 _NULL_OFFSET + 00AC8h
_screen_viewport_height =	  	  	 _NULL_OFFSET + 00ACAh
_old_screen_viewport_width =	  	 _NULL_OFFSET + 00ACCh
_old_screen_viewport_height =	  	 _NULL_OFFSET + 00ACEh
;_FixedDivWholeA_addr =   		     _NULL_OFFSET + 00AD0h
;_cht_CheckCheat_Far_addr = 	     _NULL_OFFSET + 00AD4h
_myargc =				 	 	     _NULL_OFFSET + 00AD8h
_errno =      						 _NULL_OFFSET + 00ADAh




; NFILES * SIZE DOSFILE_INFO_T bytes = 3 * 8 = 24 = 018h
___iob = 							 _NULL_OFFSET + 00ADCh

; max args = 20 including program name i guess. should be enough? maybe too much.
_myargv = 	   	  					 _NULL_OFFSET + 00AF4h

_flatcache_nodes =				     _NULL_OFFSET + 00B20h

CURRENT_POSITION_1 =  			      (_flatcache_nodes    + ((SIZE CACHE_NODE_T) * NUM_FLAT_CACHE_PAGES))
_spritecache_nodes =				  CURRENT_POSITION_1
CURRENT_POSITION_2 =   			      (_spritecache_nodes  + ((SIZE CACHE_NODE_PAGE_COUNT_T) * NUM_SPRITE_CACHE_PAGES))
_texturecache_nodes =				  CURRENT_POSITION_2
CURRENT_POSITION_3 =   			      (_texturecache_nodes + ((SIZE CACHE_NODE_PAGE_COUNT_T) * NUM_TEXTURE_PAGES))

_allocatedflatsperpage =		      CURRENT_POSITION_3
CURRENT_POSITION_4 =   			      (_allocatedflatsperpage  + (1 * NUM_FLAT_CACHE_PAGES))
_usedspritepagemem =				  CURRENT_POSITION_4
CURRENT_POSITION_5 =   			      (_usedspritepagemem  + (1 * NUM_SPRITE_CACHE_PAGES))
_usedtexturepagemem =				  CURRENT_POSITION_5
CURRENT_POSITION_6 =   			   	  (_usedtexturepagemem + (1 * NUM_TEXTURE_PAGES))



_sfx_page_reference_count =   		  CURRENT_POSITION_6
CURRENT_POSITION_7 =   			   	  (_sfx_page_reference_count + (1 * NUM_SFX_PAGES))
_sfxcache_nodes =   		  		  CURRENT_POSITION_7
CURRENT_POSITION_8 =   			   	  (_sfxcache_nodes + ((SIZE CACHE_NODE_PAGE_COUNT_T) * NUM_SFX_PAGES))

_pageswapargs = 					  CURRENT_POSITION_8
CURRENT_POSITION_9 =   			   	  (_pageswapargs + (2 * TOTAL_PAGES))

_END_OF_FIXED_DATA = CURRENT_POSITION_9







; TODO fix now that i know how to use CS indexed labels 

; EXTERNAL CODE OFFSETS FOR SELF MODIFYING CODE
; We use a 2 step build process. Some code is exported to a binary in the first build,
; then the 2nd build includes less code in the final exe. The exe loads code from the
; the first binary at runtime. The issue is some code from the build 2 exe wishes to
; modify code offsets from the binary, but that 2nd build has no visibility into the
; locations of things in the first build. So we must HARDCODE (ugh) some instruction
; offsets in here. Oh well - it's pretty minimal.

; todo this sucks.
SELFMODIFY_COLFUNC_subtract_centery24 =                   0
SELFMODIFY_COLFUNC_set_destview_segment24 =               0+3+2+2+1+2+2+2+2+2+2+2+2+2+2+2+2+2+2+2
SELFMODIFY_COLFUNC_jump_offset24 =                        SELFMODIFY_COLFUNC_set_destview_segment24+3+2+2+5+2

SELFMODIFY_COLFUNC_subtract_centery16 =                 0
SELFMODIFY_COLFUNC_set_destview_segment16 =             0+3+2+2+1+2+2+2+2+2+2+2+2+2+2+2+2+2
SELFMODIFY_COLFUNC_jump_offset16 =                      SELFMODIFY_COLFUNC_set_destview_segment16+3+2+2+5+2


SELFMODIFY_COLFUNC_set_destview_segment0 = 0Fh
SELFMODIFY_COLFUNC_jump_offset0          = SELFMODIFY_COLFUNC_set_destview_segment0 + 5

SELFMODIFY_COLFUNC_set_destview_segmentFL = 0Fh
SELFMODIFY_COLFUNC_jump_offsetFL          = SELFMODIFY_COLFUNC_set_destview_segmentFL + 5

STATENUM_NULL = -1




; todo what is this magic number again? (??) r_draw.c alludes to it as desired bx offset
DRAWSPAN_BX_OFFSET             = 0FC0h
DRAWSPAN_AH_OFFSET             = 03F00h

DRAWCOL_OFFSET                 = (COLFUNC_FUNCTION_AREA_SEGMENT - COLORMAPS_SEGMENT) * 16

; todo copy this from C via script
VISPLANES_PER_EMS_PAGE         = 25
MAX_CONVENTIONAL_VISPLANES     = 75
VISPLANE_BYTE_SIZE             = (6 + (2 * SCREENWIDTH))

LIGHTLEVELS					   = 16
LIGHTSEGSHIFT				   = 4

VISPLANE_BYTES_PER_PAGE        = (VISPLANE_BYTE_SIZE * VISPLANES_PER_EMS_PAGE)
FIRST_VISPLANE_PAGE_SEGMENT    = 08400h


LIGHTSCALESHIFT                = 0Ch
MAXSHORT					   = 07FFFh
MINSHORT					   = 08000h

COLORMAP_SHADOW     		   = 0FFh

; todo generate this from c
DRAWSEG_SIZE				   = 020h
NULL_TEX_COL				   = 0FEBFh  ;  65535 - SCREENWIDTH
SECNUM_NULL					   = 0FFFFh

COMPILE_386  = 3
COMPILE_286  = 2
COMPILE_186  = 1
COMPILE_8086 = 0

CHIPSET_NONE  = 0
CHIPSET_SCAMP = 1
CHIPSET_SCAT  = 2
CHIPSET_HT18  = 3


; should be in build params but if not...
IFNDEF COMPISA
	COMPISA = COMPILE_8086
ENDIF
 

LEAVE_MACRO MACRO 

IF COMPISA GE COMPILE_186
	leave
ELSE
	mov sp, bp
	pop bp 
ENDIF

ENDM

PUSHA_MACRO_REAL MACRO

IF COMPISA GE COMPILE_186
	pusha
ELSE
    push  ax	
	push  cx
	push  dx
	push  bx
	push  sp
	push  bp
	push  si
	push  di
ENDIF

ENDM

POPA_MACRO_REAL MACRO

IF COMPISA GE COMPILE_186
	popa
ELSE	
	pop   di
	pop   si
    pop   bp
    pop   bx	;   ; was actually sp, but we dont want to push/pop back into sp... complicated but we dont use this value and 8086/286 are different and bad stuff happens.
	pop   bx
	pop   dx
	pop   cx
	pop   ax
ENDIF

ENDM


PUSHA_MACRO MACRO

IF COMPISA GE COMPILE_186
	pusha
ELSE
    push  ax	
	push  cx
	push  dx
	push  bx
	push  bp
	push  si
	push  di
ENDIF

ENDM

POPA_MACRO MACRO

IF COMPISA GE COMPILE_186
	popa
ELSE	
	pop   di
	pop   si
    pop   bp
	pop   bx
	pop   dx
	pop   cx
	pop   ax
ENDIF

ENDM


PUSHA_NO_AX_MACRO MACRO

IF COMPISA GE COMPILE_186
	pusha
ELSE	
	push  cx
	push  dx
	push  bx
	push  bp
	push  si
	push  di
ENDIF

ENDM


PUSHA_NO_AX_OR_BP_MACRO MACRO

IF COMPISA GE COMPILE_186
	pusha
ELSE	
	push  cx
	push  dx
	push  bx
	push  si
	push  di
ENDIF

ENDM

POPA_NO_AX_MACRO MACRO

IF COMPISA GE COMPILE_186
	popa
ELSE	
	pop   di
	pop   si
    pop   bp
	pop   bx
	pop   dx
	pop   cx
ENDIF

ENDM

POPA_NO_AX_OR_BP_MACRO MACRO

IF COMPISA GE COMPILE_186
	popa
ELSE	
	pop   di
	pop   si
	pop   bx
	pop   dx
	pop   cx
ENDIF


ENDM


MUL_SIZEOF_THINKER_T MACRO dest, source

	mov  &dest, &source
	SHIFT_MACRO SAL &dest 3
	add  &dest, &source
	add  &dest, &source
	add  &dest, &source
	SHIFT_MACRO SAL &dest 2

ENDM

SHIFT_MACRO MACRO instruction, register, count


IF COMPISA GE COMPILE_386
	&instruction &register, &count

ELSEIF COMPISA GE COMPILE_186
	IF COUNT GE 4
		&instruction &register, &count
	ELSE
		REPT &count
			&instruction &register, 1
		ENDM
	ENDIF
ELSE
	REPT &count
		&instruction &register, 1
	ENDM
ENDIF

ENDM

INSTRUCTION_SET_MACRO_NO_MEDIUM MACRO 
IF COMPISA EQ COMPILE_386
	.386
ELSEIF COMPISA EQ COMPILE_286
	.286
ELSEIF COMPISA EQ COMPILE_186
	.186
ELSE
	.8086
	;NOSMART
ENDIF

ENDM

INSTRUCTION_SET_MACRO MACRO 

	.MODEL medium

IF COMPISA EQ COMPILE_386
	.386
ELSEIF COMPISA EQ COMPILE_286
	.286
ELSEIF COMPISA EQ COMPILE_186
	.186
ELSE
	.8086
	;NOSMART
ENDIF

ENDM
;
; EMS DEFINITIONS 
;
SCAMP_PAGE_9000_OFFSET  =   020h

IFDEF COMP_CH

	PAGE_SWAP_ARG_MULT = 1


	IF COMP_CH EQ CHIPSET_SCAT
		EMS_MEMORY_PAGE_OFFSET  = 08080h
		EMS_AUTOINCREMENT_FLAG  =   080h
		CHIPSET_PAGE_9000       =   014h


		SCAT_PAGE_D000 = 018h
		SCAT_PAGE_SELECT_REGISTER = 020Ah
		SCAT_PAGE_SET_REGISTER = 0208h
		; consider ; inc dx x2?
		

		Z_QUICKMAPAI1 MACRO pageswapindex, page
			mov     si,  &pageswapindex * 2 * PAGE_SWAP_ARG_MULT + OFFSET _pageswapargs
			mov  	dx, SCAT_PAGE_SELECT_REGISTER
			mov     al, page OR EMS_AUTOINCREMENT_FLAG
			cli
			out  	dx, al
			mov  	dx, SCAT_PAGE_SET_REGISTER 
			lodsw
			out 	dx, ax
			sti
		ENDM

		Z_QUICKMAPAI2 MACRO pageswapindex, page
			mov     si,  &pageswapindex * 2 * PAGE_SWAP_ARG_MULT + OFFSET _pageswapargs
			mov  	dx, SCAT_PAGE_SELECT_REGISTER
			mov     al, page OR EMS_AUTOINCREMENT_FLAG
			cli
			out  	dx, al
			mov  	dx, SCAT_PAGE_SET_REGISTER
			lodsw
			out 	dx, ax
			lodsw
			out 	dx, ax
			sti
		ENDM

		Z_QUICKMAPAI3 MACRO pageswapindex, page
			mov     si,  &pageswapindex * 2 * PAGE_SWAP_ARG_MULT + OFFSET _pageswapargs
			mov  	dx, SCAT_PAGE_SELECT_REGISTER
			mov     al, page OR EMS_AUTOINCREMENT_FLAG
			cli
			out  	dx, al
			mov  	dx, SCAT_PAGE_SET_REGISTER
			lodsw
			out 	dx, ax
			lodsw
			out 	dx, ax
			lodsw
			out 	dx, ax
			sti
		ENDM

		Z_QUICKMAPAI4 MACRO pageswapindex, page
			mov     si,  &pageswapindex * 2 * PAGE_SWAP_ARG_MULT + OFFSET _pageswapargs
			mov  	dx, SCAT_PAGE_SELECT_REGISTER
			mov     al, page OR EMS_AUTOINCREMENT_FLAG
			cli
			out  	dx, al
			mov  	dx, SCAT_PAGE_SET_REGISTER
			mov  	cx, 4
			rep  	outsw
			sti
		ENDM

		Z_QUICKMAPAI5 MACRO pageswapindex, page
			mov     si,  &pageswapindex * 2 * PAGE_SWAP_ARG_MULT + OFFSET _pageswapargs
			mov  	dx, SCAT_PAGE_SELECT_REGISTER
			mov     al, page OR EMS_AUTOINCREMENT_FLAG
			cli
			out  	dx, al
			mov  	dx, SCAT_PAGE_SET_REGISTER
			mov  	cx, 5
			rep  	outsw
			sti
		ENDM

		Z_QUICKMAPAI6 MACRO pageswapindex, page
			mov     si,  &pageswapindex * 2 * PAGE_SWAP_ARG_MULT + OFFSET _pageswapargs
			mov  	dx, SCAT_PAGE_SELECT_REGISTER
			mov     al, page OR EMS_AUTOINCREMENT_FLAG
			cli
			out  	dx, al
			mov  	dx, SCAT_PAGE_SET_REGISTER
			mov  	cx, 6
			rep  	outsw
			sti
		ENDM

		Z_QUICKMAPAI7 MACRO pageswapindex, page
			mov     si,  &pageswapindex * 2 * PAGE_SWAP_ARG_MULT + OFFSET _pageswapargs
			mov  	dx, SCAT_PAGE_SELECT_REGISTER
			mov     al, page OR EMS_AUTOINCREMENT_FLAG
			cli
			out  	dx, al
			mov  	dx, SCAT_PAGE_SET_REGISTER
			mov  	cx, 7
			rep  	outsw
			sti
		ENDM

		Z_QUICKMAPAI8 MACRO pageswapindex, page
			mov     si,  &pageswapindex * 2 * PAGE_SWAP_ARG_MULT + OFFSET _pageswapargs
			mov  	dx, SCAT_PAGE_SELECT_REGISTER
			mov     al, page OR EMS_AUTOINCREMENT_FLAG
			cli
			out  	dx, al
			mov  	dx, SCAT_PAGE_SET_REGISTER
			mov  	cx, 8
			rep  	outsw
			sti
		ENDM

		Z_QUICKMAPAI16 MACRO pageswapindex, page
			mov     si,  &pageswapindex * 2 * PAGE_SWAP_ARG_MULT + OFFSET _pageswapargs
			mov  	dx, SCAT_PAGE_SELECT_REGISTER
			mov     al, page OR EMS_AUTOINCREMENT_FLAG
			cli
			out  	dx, al
			mov  	dx, SCAT_PAGE_SET_REGISTER
			mov  	cx, 16
			rep  	outsw
			sti
		ENDM

		Z_QUICKMAPAI24 MACRO pageswapindex, page
			mov     si,  &pageswapindex * 2 * PAGE_SWAP_ARG_MULT + OFFSET _pageswapargs
			mov  	dx, SCAT_PAGE_SELECT_REGISTER
			mov  	al, 080h     ; 080h for autoincrement enable. 00h for page 4000 index
			cli
			out  	dx, al
			mov  	dx, SCAT_PAGE_SET_REGISTER
			mov  	cx, 24
			rep  	outsw
			sti
		ENDM



	ELSEIF COMP_CH EQ CHIPSET_SCAMP
		EMS_MEMORY_PAGE_OFFSET  = 00050h
		SCAMP_PAGE_9000_OFFSET  =   020h
		EMS_AUTOINCREMENT_FLAG  =   040h
		CHIPSET_PAGE_9000       =   020h

		SCAMP_PAGE_FRAME_BASE_INDEX = 4    ; todo ??? d000?
		SCAMP_PAGE_SELECT_REGISTER = 0E8h
		SCAMP_PAGE_SET_REGISTER = 0EAh

		Z_QUICKMAPAI1 MACRO pageswapindex, page
			mov     si,  &pageswapindex * 2 * PAGE_SWAP_ARG_MULT + OFFSET _pageswapargs
			mov     al, page OR EMS_AUTOINCREMENT_FLAG
			cli
			out     SCAMP_PAGE_SELECT_REGISTER, al
			lodsw
			out 	SCAMP_PAGE_SET_REGISTER, ax
			sti
		ENDM

		Z_QUICKMAPAI2 MACRO pageswapindex, page
			mov     si,  &pageswapindex * 2 * PAGE_SWAP_ARG_MULT + OFFSET _pageswapargs
			mov     al, page OR EMS_AUTOINCREMENT_FLAG
			cli
			out     SCAMP_PAGE_SELECT_REGISTER, al
			lodsw
			out 	SCAMP_PAGE_SET_REGISTER, ax
			lodsw
			out 	SCAMP_PAGE_SET_REGISTER, ax
			sti
		ENDM

		Z_QUICKMAPAI3 MACRO pageswapindex, page
			mov     si,  &pageswapindex * 2 * PAGE_SWAP_ARG_MULT + OFFSET _pageswapargs
			mov     al, page OR EMS_AUTOINCREMENT_FLAG
			cli
			out     SCAMP_PAGE_SELECT_REGISTER, al
			lodsw
			out 	SCAMP_PAGE_SET_REGISTER, ax
			lodsw
			out 	SCAMP_PAGE_SET_REGISTER, ax
			lodsw
			out 	SCAMP_PAGE_SET_REGISTER, ax
			sti
		ENDM

		Z_QUICKMAPAI4 MACRO pageswapindex, page
			mov     si,  &pageswapindex * 2 * PAGE_SWAP_ARG_MULT + OFFSET _pageswapargs
			mov     al, page OR EMS_AUTOINCREMENT_FLAG
			cli
			out     SCAMP_PAGE_SELECT_REGISTER, al
			mov	    dx, SCAMP_PAGE_SET_REGISTER
			mov     cx, 4
			rep     outsw			
			sti
		ENDM

		Z_QUICKMAPAI5 MACRO pageswapindex, page
			mov     si,  &pageswapindex * 2 * PAGE_SWAP_ARG_MULT + OFFSET _pageswapargs
			mov     al, page OR EMS_AUTOINCREMENT_FLAG
			cli
			out     SCAMP_PAGE_SELECT_REGISTER, al
			mov	    dx, SCAMP_PAGE_SET_REGISTER
			mov     cx, 5
			rep     outsw			
			sti
		ENDM

		Z_QUICKMAPAI6 MACRO pageswapindex, page
			mov     si,  &pageswapindex * 2 * PAGE_SWAP_ARG_MULT + OFFSET _pageswapargs
			mov     al, page OR EMS_AUTOINCREMENT_FLAG
			cli
			out     SCAMP_PAGE_SELECT_REGISTER, al
			mov	    dx, SCAMP_PAGE_SET_REGISTER
			mov     cx, 6
			rep     outsw			
			sti
		ENDM

		Z_QUICKMAPAI7 MACRO pageswapindex, page
			mov     si,  &pageswapindex * 2 * PAGE_SWAP_ARG_MULT + OFFSET _pageswapargs
			mov     al, page OR EMS_AUTOINCREMENT_FLAG
			cli
			out     SCAMP_PAGE_SELECT_REGISTER, al
			mov	    dx, SCAMP_PAGE_SET_REGISTER
			mov     cx, 7
			rep     outsw			
			sti
		ENDM

		Z_QUICKMAPAI8 MACRO pageswapindex, page
			mov     si,  &pageswapindex * 2 * PAGE_SWAP_ARG_MULT + OFFSET _pageswapargs
			mov     al, page OR EMS_AUTOINCREMENT_FLAG
			cli
			out     SCAMP_PAGE_SELECT_REGISTER, al
			mov	    dx, SCAMP_PAGE_SET_REGISTER
			mov     cx, 8
			rep     outsw			
			sti
		ENDM

		Z_QUICKMAPAI16 MACRO pageswapindex, page
			mov     si,  &pageswapindex * 2 * PAGE_SWAP_ARG_MULT + OFFSET _pageswapargs
			mov     al, page OR EMS_AUTOINCREMENT_FLAG
			cli
			out     SCAMP_PAGE_SELECT_REGISTER, al
			mov	    dx, SCAMP_PAGE_SET_REGISTER
			mov     cx, 16
			rep     outsw			
			sti
		ENDM

		Z_QUICKMAPAI24 MACRO pageswapindex, page
			mov     si,  &pageswapindex * 2 * PAGE_SWAP_ARG_MULT + OFFSET _pageswapargs
			mov  	al, 04Ch     ; 040h for autoincrement enable. 0Ch for page 4000 index

			cli
			out     SCAMP_PAGE_SELECT_REGISTER, al
			mov	    dx, SCAMP_PAGE_SET_REGISTER
			mov     cx, 24
			rep     outsw			
			sti
		ENDM

	ELSEIF COMP_CH EQ CHIPSET_HT18
		EMS_MEMORY_PAGE_OFFSET  = 00050h
		EMS_AUTOINCREMENT_FLAG  =   080h
		CHIPSET_PAGE_9000       =   014h

		HT18_PAGE_D000 = 01Ch

		HT18_PAGE_SELECT_REGISTER = 01EEh
		HT18_PAGE_SET_REGISTER = 01ECh

		Z_QUICKMAPAI1 MACRO pageswapindex, page
			mov     si,  &pageswapindex * 2 * PAGE_SWAP_ARG_MULT + OFFSET _pageswapargs
			mov  	dx, HT18_PAGE_SELECT_REGISTER
			mov     al, page OR EMS_AUTOINCREMENT_FLAG
			out  	dx, al
			mov  	dx, HT18_PAGE_SET_REGISTER
			lodsw
			out 	dx, ax
		ENDM

		Z_QUICKMAPAI2 MACRO pageswapindex, page
			mov     si,  &pageswapindex * 2 * PAGE_SWAP_ARG_MULT + OFFSET _pageswapargs
			mov  	dx, HT18_PAGE_SELECT_REGISTER
			mov     al, page OR EMS_AUTOINCREMENT_FLAG
			out  	dx, al
			mov  	dx, HT18_PAGE_SET_REGISTER
			lodsw
			out 	dx, ax
			lodsw
			out 	dx, ax
		ENDM

		Z_QUICKMAPAI3 MACRO pageswapindex, page
			mov     si,  &pageswapindex * 2 * PAGE_SWAP_ARG_MULT + OFFSET _pageswapargs
			mov  	dx, HT18_PAGE_SELECT_REGISTER
			mov     al, page OR EMS_AUTOINCREMENT_FLAG
			out  	dx, al
			mov  	dx, HT18_PAGE_SET_REGISTER
			lodsw
			out 	dx, ax
			lodsw
			out 	dx, ax
			lodsw
			out 	dx, ax
		ENDM

		Z_QUICKMAPAI4 MACRO pageswapindex, page
			mov     si,  &pageswapindex * 2 * PAGE_SWAP_ARG_MULT + OFFSET _pageswapargs
			mov  	dx, HT18_PAGE_SELECT_REGISTER
			mov     al, page OR EMS_AUTOINCREMENT_FLAG
			out  	dx, al
			mov  	dx, HT18_PAGE_SET_REGISTER
			mov     cx, 4
			rep     outsw
		ENDM

		Z_QUICKMAPAI5 MACRO pageswapindex, page
			mov     si,  &pageswapindex * 2 * PAGE_SWAP_ARG_MULT + OFFSET _pageswapargs
			mov  	dx, HT18_PAGE_SELECT_REGISTER
			mov     al, page OR EMS_AUTOINCREMENT_FLAG
			out  	dx, al
			mov  	dx, HT18_PAGE_SET_REGISTER
			mov     cx, 5
			rep     outsw
		ENDM

		Z_QUICKMAPAI6 MACRO pageswapindex, page
			mov     si,  &pageswapindex * 2 * PAGE_SWAP_ARG_MULT + OFFSET _pageswapargs
			mov  	dx, HT18_PAGE_SELECT_REGISTER
			mov     al, page OR EMS_AUTOINCREMENT_FLAG
			out  	dx, al
			mov  	dx, HT18_PAGE_SET_REGISTER
			mov     cx, 6
			rep     outsw
		ENDM

		Z_QUICKMAPAI7 MACRO pageswapindex, page
			mov     si,  &pageswapindex * 2 * PAGE_SWAP_ARG_MULT + OFFSET _pageswapargs
			mov  	dx, HT18_PAGE_SELECT_REGISTER
			mov     al, page OR EMS_AUTOINCREMENT_FLAG
			out  	dx, al
			mov  	dx, HT18_PAGE_SET_REGISTER
			mov     cx, 7
			rep     outsw
		ENDM

		Z_QUICKMAPAI8 MACRO pageswapindex, page
			mov     si,  &pageswapindex * 2 * PAGE_SWAP_ARG_MULT + OFFSET _pageswapargs
			mov  	dx, HT18_PAGE_SELECT_REGISTER
			mov     al, page OR EMS_AUTOINCREMENT_FLAG
			out  	dx, al
			mov  	dx, HT18_PAGE_SET_REGISTER
			mov     cx, 8
			rep     outsw
		ENDM

		Z_QUICKMAPAI16 MACRO pageswapindex, page
			mov     si,  &pageswapindex * 2 * PAGE_SWAP_ARG_MULT + OFFSET _pageswapargs
			mov  	dx, HT18_PAGE_SELECT_REGISTER
			mov     al, page OR EMS_AUTOINCREMENT_FLAG
			out  	dx, al
			mov  	dx, HT18_PAGE_SET_REGISTER
			mov     cx, 16
			rep     outsw
		ENDM

		Z_QUICKMAPAI24 MACRO pageswapindex, page
			mov     si,  &pageswapindex * 2 * PAGE_SWAP_ARG_MULT + OFFSET _pageswapargs
			mov  	dx, HT18_PAGE_SELECT_REGISTER
			mov  	al, 080h     ; 080h for autoincrement enable. 00h for page 4000 index
			out  	dx, al
			mov  	dx, HT18_PAGE_SET_REGISTER
			mov     cx, 24
			rep     outsw
		ENDM

	ENDIF

	EPR_MACRO MACRO var
		add &var, EMS_MEMORY_PAGE_OFFSET
	ENDM

	NPR_MACRO MACRO amount

	ENDM



	_EPR MACRO arg, page
		dw &arg + EMS_MEMORY_PAGE_OFFSET
	ENDM

	_NPR MACRO arg, page

		IF COMP_CH EQ CHIPSET_SCAT
			dw 003FFh
		ELSEIF COMP_CH EQ CHIPSET_SCAMP
			dw (&arg + SCAMP_PAGE_9000_OFFSET + 4) AND 0FFFFh   ; shut up overflow warning
		ELSEIF COMP_CH EQ CHIPSET_HT18
			dw 00000h
		ENDIF


	ENDM

	Z_QUICKMAPAI1_NO_DX MACRO  arg1, arg2
		Z_QUICKMAPAI1 &arg1 &arg2
	ENDM
	Z_QUICKMAPAI2_NO_DX MACRO  arg1, arg2
		Z_QUICKMAPAI2 &arg1 &arg2
	ENDM
	Z_QUICKMAPAI3_NO_DX MACRO  arg1, arg2
		Z_QUICKMAPAI3 &arg1 &arg2
	ENDM
	Z_QUICKMAPAI4_NO_DX MACRO  arg1, arg2
		Z_QUICKMAPAI4 &arg1 &arg2
	ENDM
	Z_QUICKMAPAI5_NO_DX MACRO  arg1, arg2
		Z_QUICKMAPAI5 &arg1 &arg2
	ENDM
	Z_QUICKMAPAI6_NO_DX MACRO  arg1, arg2
		Z_QUICKMAPAI6 &arg1 &arg2
	ENDM
	Z_QUICKMAPAI7_NO_DX MACRO  arg1, arg2
		Z_QUICKMAPAI7 &arg1 &arg2
	ENDM
	Z_QUICKMAPAI8_NO_DX MACRO  arg1, arg2
		Z_QUICKMAPAI8 &arg1 &arg2
	ENDM
	Z_QUICKMAPAI16_NO_DX MACRO  arg1, arg2
		Z_QUICKMAPAI16 &arg1 &arg2
	ENDM
	Z_QUICKMAPAI24_NO_DX MACRO  arg1, arg2
		Z_QUICKMAPAI24 &arg1 &arg2
	ENDM


ELSE
    PAGE_SWAP_ARG_MULT = 2
	; unused
	CHIPSET_PAGE_9000=0

	EMS_MEMORY_PAGE_OFFSET  = 00000h

	EPR_OFFSET = EMS_MEMORY_PAGE_OFFSET

	EPR_MACRO MACRO var

	ENDM


	_EPR MACRO arg, page
		dw &arg
		dw &page
	ENDM

	_NPR MACRO arg, page
		dw 0FFFFh
		dw &page
	ENDM


	Z_QUICKMAPAI1 MACRO pageswapindex, page

		mov     dx, word ptr ds:[_emshandle]
		mov     ax, 05000h
		mov     cx, 1
		mov     si, &pageswapindex * 2 * PAGE_SWAP_ARG_MULT + OFFSET _pageswapargs
		int     067h

	ENDM

	Z_QUICKMAPAI2 MACRO pageswapindex, page

		mov     dx, word ptr ds:[_emshandle]
		mov     ax, 05000h
		mov     cx, 2
		mov     si, &pageswapindex * 2 * PAGE_SWAP_ARG_MULT + OFFSET _pageswapargs
		int     067h

	ENDM

	Z_QUICKMAPAI3 MACRO pageswapindex, page

		mov     dx, word ptr ds:[_emshandle]
		mov     ax, 05000h
		mov     cx, 3
		mov     si, &pageswapindex * 2 * PAGE_SWAP_ARG_MULT + OFFSET _pageswapargs
		int     067h

	ENDM

	Z_QUICKMAPAI4 MACRO pageswapindex, page

		mov     dx, word ptr ds:[_emshandle]
		mov     ax, 05000h
		mov     cx, 4
		mov     si, &pageswapindex * 2 * PAGE_SWAP_ARG_MULT + OFFSET _pageswapargs
		int     067h

	ENDM

	Z_QUICKMAPAI5 MACRO pageswapindex, page

		mov     dx, word ptr ds:[_emshandle]
		mov     ax, 05000h
		mov     cx, 5
		mov     si, &pageswapindex * 2 * PAGE_SWAP_ARG_MULT + OFFSET _pageswapargs
		int     067h

	ENDM

	Z_QUICKMAPAI6 MACRO pageswapindex, page

		mov     dx, word ptr ds:[_emshandle]
		mov     ax, 05000h
		mov     cx, 6
		mov     si, &pageswapindex * 2 * PAGE_SWAP_ARG_MULT + OFFSET _pageswapargs
		int     067h

	ENDM

	Z_QUICKMAPAI7 MACRO pageswapindex, page

		mov     dx, word ptr ds:[_emshandle]
		mov     ax, 05000h
		mov     cx, 7
		mov     si, &pageswapindex * 2 * PAGE_SWAP_ARG_MULT + OFFSET _pageswapargs
		int     067h

	ENDM

	Z_QUICKMAPAI8 MACRO pageswapindex, page

		mov     dx, word ptr ds:[_emshandle]
		mov     ax, 05000h
		mov     cx, 8
		mov     si, &pageswapindex * 2 * PAGE_SWAP_ARG_MULT + OFFSET _pageswapargs
		int     067h

	ENDM

	Z_QUICKMAPAI16 MACRO pageswapindex, page

		mov     dx, word ptr ds:[_emshandle]
		mov     ax, 05000h
		mov     cx, 8
		mov     si, &pageswapindex * 2 * PAGE_SWAP_ARG_MULT + OFFSET _pageswapargs
		int     067h

		mov     ax, 05000h
		add     si, 8 * 2 * PAGE_SWAP_ARG_MULT
		int     067h

	ENDM

	Z_QUICKMAPAI24 MACRO pageswapindex, page

		mov     dx, word ptr ds:[_emshandle]
		mov     ax, 05000h
		mov     cx, 8
		mov     si, &pageswapindex * 2 * PAGE_SWAP_ARG_MULT + OFFSET _pageswapargs
		int     067h

		mov     ax, 05000h
		add     si, 8 * 2 * PAGE_SWAP_ARG_MULT
		int     067h

		mov     ax, 05000h
		add     si, 8 * 2 * PAGE_SWAP_ARG_MULT
		int     067h

	ENDM

	Z_QUICKMAPAI1_NO_DX MACRO pageswapindex, page

		mov     ax, 05000h
		mov     cx, 1
		mov     si, &pageswapindex * 2 * PAGE_SWAP_ARG_MULT + OFFSET _pageswapargs
		int     067h

	ENDM

	Z_QUICKMAPAI2_NO_DX MACRO pageswapindex, page

		mov     ax, 05000h
		mov     cx, 2
		mov     si, &pageswapindex * 2 * PAGE_SWAP_ARG_MULT + OFFSET _pageswapargs
		int     067h

	ENDM

	Z_QUICKMAPAI3_NO_DX MACRO pageswapindex, page

		mov     ax, 05000h
		mov     cx, 3
		mov     si, &pageswapindex * 2 * PAGE_SWAP_ARG_MULT + OFFSET _pageswapargs
		int     067h

	ENDM

	Z_QUICKMAPAI4_NO_DX MACRO pageswapindex, page

		mov     ax, 05000h
		mov     cx, 4
		mov     si, &pageswapindex * 2 * PAGE_SWAP_ARG_MULT + OFFSET _pageswapargs
		int     067h

	ENDM

	Z_QUICKMAPAI5_NO_DX MACRO pageswapindex, page

		mov     dx, word ptr ds:[_emshandle]
		mov     ax, 05000h
		mov     cx, 5
		mov     si, &pageswapindex * 2 * PAGE_SWAP_ARG_MULT + OFFSET _pageswapargs
		int     067h

	ENDM

	Z_QUICKMAPAI6_NO_DX MACRO pageswapindex, page

		mov     ax, 05000h
		mov     cx, 6
		mov     si, &pageswapindex * 2 * PAGE_SWAP_ARG_MULT + OFFSET _pageswapargs
		int     067h

	ENDM

	Z_QUICKMAPAI7_NO_DX MACRO pageswapindex, page

		mov     ax, 05000h
		mov     cx, 7
		mov     si, &pageswapindex * 2 * PAGE_SWAP_ARG_MULT + OFFSET _pageswapargs
		int     067h

	ENDM

	Z_QUICKMAPAI8_NO_DX MACRO pageswapindex, page

		mov     ax, 05000h
		mov     cx, 8
		mov     si, &pageswapindex * 2 * PAGE_SWAP_ARG_MULT + OFFSET _pageswapargs
		int     067h

	ENDM

	Z_QUICKMAPAI16_NO_DX MACRO pageswapindex, page

		mov     ax, 05000h
		mov     cx, 8
		mov     si, &pageswapindex * 2 * PAGE_SWAP_ARG_MULT + OFFSET _pageswapargs
		int     067h

		mov     ax, 05000h
		add     si, 8 * 2 * PAGE_SWAP_ARG_MULT
		int     067h

	ENDM

	Z_QUICKMAPAI24_NO_DX MACRO pageswapindex, page

		mov     ax, 05000h
		mov     cx, 8
		mov     si, &pageswapindex * 2 * PAGE_SWAP_ARG_MULT + OFFSET _pageswapargs
		int     067h

		mov     ax, 05000h
		add     si, 8 * 2 * PAGE_SWAP_ARG_MULT
		int     067h

		mov     ax, 05000h
		add     si, 8 * 2 * PAGE_SWAP_ARG_MULT
		int     067h

	ENDM

	


ENDIF

NOWARN OVF

;pagenum9000 = CHIPSET_PAGE_9000

INDEXED_PAGE_9000_OFFSET = (PAGE_9000_OFFSET+CHIPSET_PAGE_9000)
INDEXED_PAGE_9400_OFFSET = (PAGE_9400_OFFSET+CHIPSET_PAGE_9000)
INDEXED_PAGE_9800_OFFSET = (PAGE_9800_OFFSET+CHIPSET_PAGE_9000)
INDEXED_PAGE_9C00_OFFSET = (PAGE_9C00_OFFSET+CHIPSET_PAGE_9000)

INDEXED_PAGE_8000_OFFSET = (PAGE_8000_OFFSET+CHIPSET_PAGE_9000)
INDEXED_PAGE_8400_OFFSET = (PAGE_8400_OFFSET+CHIPSET_PAGE_9000)
INDEXED_PAGE_8800_OFFSET = (PAGE_8800_OFFSET+CHIPSET_PAGE_9000)
INDEXED_PAGE_8C00_OFFSET = (PAGE_8C00_OFFSET+CHIPSET_PAGE_9000)

INDEXED_PAGE_7000_OFFSET = (PAGE_7000_OFFSET+CHIPSET_PAGE_9000)
INDEXED_PAGE_7400_OFFSET = (PAGE_7400_OFFSET+CHIPSET_PAGE_9000)
INDEXED_PAGE_7800_OFFSET = (PAGE_7800_OFFSET+CHIPSET_PAGE_9000)
INDEXED_PAGE_7C00_OFFSET = (PAGE_7C00_OFFSET+CHIPSET_PAGE_9000)

INDEXED_PAGE_6000_OFFSET = (PAGE_6000_OFFSET+CHIPSET_PAGE_9000)
INDEXED_PAGE_6400_OFFSET = (PAGE_6400_OFFSET+CHIPSET_PAGE_9000)
INDEXED_PAGE_6800_OFFSET = (PAGE_6800_OFFSET+CHIPSET_PAGE_9000)
INDEXED_PAGE_6C00_OFFSET = (PAGE_6C00_OFFSET+CHIPSET_PAGE_9000)

INDEXED_PAGE_5000_OFFSET = (PAGE_5000_OFFSET+CHIPSET_PAGE_9000)
INDEXED_PAGE_5400_OFFSET = (PAGE_5400_OFFSET+CHIPSET_PAGE_9000)
INDEXED_PAGE_5800_OFFSET = (PAGE_5800_OFFSET+CHIPSET_PAGE_9000)
INDEXED_PAGE_5C00_OFFSET = (PAGE_5C00_OFFSET+CHIPSET_PAGE_9000)

INDEXED_PAGE_4000_OFFSET = (PAGE_4000_OFFSET+CHIPSET_PAGE_9000)
INDEXED_PAGE_4400_OFFSET = (PAGE_4400_OFFSET+CHIPSET_PAGE_9000)
INDEXED_PAGE_4800_OFFSET = (PAGE_4800_OFFSET+CHIPSET_PAGE_9000)
INDEXED_PAGE_4C00_OFFSET = (PAGE_4C00_OFFSET+CHIPSET_PAGE_9000)

WARN OVF

; called with reg in var
; reg may need to be shifted one
; "constant_offset" is on stack. will be added. pre-shifted at build time

SHIFT_PAGESWAP_ARGS MACRO var
	IF PAGE_SWAP_ARG_MULT EQ 1
	ELSE
		sal &var, 1
	ENDIF
	
ENDM









INCLUDE asmtypes.inc

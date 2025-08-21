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




SCAMP_PAGE_9000_OFFSET  =   020h

IFDEF COMP_CH
	PAGE_SWAP_ARG_MULT = 1
ELSE
    PAGE_SWAP_ARG_MULT = 2
ENDIF



_NULL_OFFSET = 0030h


_segloopnextlookup    = 			_NULL_OFFSET + 00000h
_seglooptexrepeat    = 				_NULL_OFFSET + 00004h
_maskedtexrepeat =                  _NULL_OFFSET + 00006h
_segloopcachedsegment  = 			_NULL_OFFSET + 00008h
_segloopheightvalcache = 			_NULL_OFFSET + 0000Ch
;// 0E-0F free

_spanfunc_prt = 					_NULL_OFFSET + 00010h
_spanfunc_destview_offset = 		_NULL_OFFSET + 00018h
_spanfunc_inner_loop_count =		_NULL_OFFSET + 00020h
_spanfunc_outp = 					_NULL_OFFSET + 00024h
; 28 -2F unused

_quality_port_lookup = 				_NULL_OFFSET + 00030h


; todo move to cs
_jump_mult_table_3 = 				_NULL_OFFSET + 00048h

 
_dc_x = 							_NULL_OFFSET + 00050h
_lastopening =                   	_NULL_OFFSET + 00052h
_planezlight = 						_NULL_OFFSET + 00054h
_caststate =                        _NULL_OFFSET + 00058h
_basexscale = 						_NULL_OFFSET + 0005Ch
_baseyscale = 						_NULL_OFFSET + 00060h
_viewx = 							_NULL_OFFSET + 00064h
_viewy = 							_NULL_OFFSET + 00068h
_viewz = 							_NULL_OFFSET + 0006Ch
_centerx = 							_NULL_OFFSET + 00070h
_centery = 							_NULL_OFFSET + 00072h
_centeryfrac_shiftright4 = 			_NULL_OFFSET + 00074h
_viewangle =                		_NULL_OFFSET + 00078h
_viewz_shortheight = 				_NULL_OFFSET + 0007Ch
_screen_segments = 					_NULL_OFFSET + 0007Eh

_maskedtexture = 					_NULL_OFFSET + 00088h
; 89 free
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
_finale_laststage =              	_NULL_OFFSET + 000BEh
_playingstate = 	                _NULL_OFFSET + 000BFh

_mfloorclip = 						_NULL_OFFSET + 000C0h
_mceilingclip = 					_NULL_OFFSET + 000C4h

_viletryx =                         _NULL_OFFSET + 000CCh
_viletryy =                         _NULL_OFFSET + 000D0h
_viewangle_shiftright1 = 			_NULL_OFFSET + 000D4h
_snd_SfxDevice = 					_NULL_OFFSET + 000D6h
_snd_MusicDevice =				    _NULL_OFFSET + 000D7h

_ds_source_segment = 				_NULL_OFFSET + 000D8h

_currentscreen    = 				_NULL_OFFSET + 000DCh
_destview    = 						_NULL_OFFSET + 000E0h
_destscreen    = 					_NULL_OFFSET + 000E4h
_tantoangle_segment  = 				_NULL_OFFSET + 000E8h
_spanfunc_jump_segment_storage = 	_NULL_OFFSET + 000EAh

; ec-f4 free
_totalkills = 						_NULL_OFFSET + 000ECh
_totalitems = 						_NULL_OFFSET + 000EEh
_totalsecret = 						_NULL_OFFSET + 000F0h


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


_EMS_PAGE =                 	    _NULL_OFFSET + 00102h
_viewangle_shiftright3 = 			_NULL_OFFSET + 00104h
_dc_source_segment =	 			_NULL_OFFSET + 0010Ah
_ds_y = 				    		_NULL_OFFSET + 0010Ch
_stored_ds = 				    	_NULL_OFFSET + 00110h


_cachedheight_segment_storage =    	_NULL_OFFSET + 00112h
_distscale_segment_storage =    	_NULL_OFFSET + 00114h
_cacheddistance_segment_storage =   _NULL_OFFSET + 00116h
_cachedxstep_segment_storage =    	_NULL_OFFSET + 00118h
_cachedystep_segment_storage =    	_NULL_OFFSET + 0011Ah

_pspriteiscale =                    _NULL_OFFSET + 0011Ch

; 120h

_tmflags1 =                         _NULL_OFFSET + 00120h
_tmfloorz =                         _NULL_OFFSET + 00122h
_tmceilingz =                       _NULL_OFFSET + 00124h
_tmdropoffz =                       _NULL_OFFSET + 00126h


_MULT_4096 =                    	_NULL_OFFSET + 00128h
; todo unused
_FLAT_CACHE_PAGE =                  _NULL_OFFSET + 00130h
_visplanelookupsegments =           _NULL_OFFSET + 00138h
_firstflat =                  		_NULL_OFFSET + 0013Eh
; 140h
_castattacking =                 	_NULL_OFFSET + 00140h
_castdeath =                     	_NULL_OFFSET + 00141h
_castonmelee =                   	_NULL_OFFSET + 00142h
_castframes =                    	_NULL_OFFSET + 00143h
_casttics =                      	_NULL_OFFSET + 00144h
_castnum =                       	_NULL_OFFSET + 00145h
_finaleflat =                   	_NULL_OFFSET + 00146h
; 147 free
_FixedMul2432_addr =                _NULL_OFFSET + 00148h
_tmthing_pos =                      _NULL_OFFSET + 0014Ch

_trace =                            _NULL_OFFSET + 00150h

; 160h
_currentflatpage =            		_NULL_OFFSET + 00160h
_lastflatcacheindicesused =         _NULL_OFFSET + 00164h
_skyflatnum =            			_NULL_OFFSET + 00168h
_extralight =            			_NULL_OFFSET + 00169h
_visplanedirty =            		_NULL_OFFSET + 0016Ah
_screenblocks =            			_NULL_OFFSET + 0016Bh
_lastvisplane =            			_NULL_OFFSET + 0016Ch
_hudneedsupdate =                   _NULL_OFFSET + 0016Eh
_gamestate =                        _NULL_OFFSET + 0016Fh


; 170h
_tmx =                             _NULL_OFFSET + 00170h
_tmy =                             _NULL_OFFSET + 00174h
_tmxmove =                         _NULL_OFFSET + 00178h
_tmymove =                         _NULL_OFFSET + 0017Ch




; 180h
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

; 190h
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



_V_DrawPatchDirect_addr =            _NULL_OFFSET + 001F4h

_deadAttackerX =                     _NULL_OFFSET + 001F8h
_deadAttackerY =                     _NULL_OFFSET + 001FCh
_M_Random_addr =                     _NULL_OFFSET + 00200h
_I_WaitVBL_addr =       		     _NULL_OFFSET + 00204h
_I_SetPalette_addr = 	        	 _NULL_OFFSET + 00208h


_V_MarkRect_addr =                   _NULL_OFFSET + 0020Ch
;_M_Drawer_addr =                     _NULL_OFFSET + 00210h

_wipeduration =                      _NULL_OFFSET + 00214h
_detailshift2minus =  		 		 _NULL_OFFSET + 00216h
_maskedheaderpixeolfs =				 _NULL_OFFSET + 00218h
_maskedtexturecol =					 _NULL_OFFSET + 0021Ch
; 0220h
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

_olddb =							_NULL_OFFSET + 002A0h
_detailshift = 						_NULL_OFFSET + 002B0h
_detailshiftitercount = 			_NULL_OFFSET + 002B2h
_detailshiftandval = 				_NULL_OFFSET + 002B4h
_ceilphyspage =                  	_NULL_OFFSET + 002B6h
_floorphyspage =                 	_NULL_OFFSET + 002B7h
_gameaction =                 		_NULL_OFFSET + 002B8h
_viewactive =                 		_NULL_OFFSET + 002B9h
_automapactive =                 	_NULL_OFFSET + 002BAh
_commercial =                 		_NULL_OFFSET + 002BBh
_registered =                 		_NULL_OFFSET + 002BCh
_shareware =                 		_NULL_OFFSET + 002BDh
_ds_colormap_index = 				_NULL_OFFSET + 002BEh
_fixedcolormap = 					_NULL_OFFSET + 002BFh



_FixedMul_addr =               		 _NULL_OFFSET + 002C0h
_FixedDiv_addr =                     _NULL_OFFSET + 002C4h
_mus_playing =    			      	 _NULL_OFFSET + 002C8h
_mus_paused =    			      	 _NULL_OFFSET + 002C9h
_sendpause =    			      	 _NULL_OFFSET + 002CAh
_sendsave =    			      	 	_NULL_OFFSET + 002CBh

_R_GetCompositeTexture_addr =        _NULL_OFFSET + 002CCh

 
_w_message =					     _NULL_OFFSET + 002D0h
; 435 to 438 probably free?
_columnquality =              	     _NULL_OFFSET + 00439h
_useDeadAttackerRef =              	 _NULL_OFFSET + 0043Ah
_paused	=						     _NULL_OFFSET + 0043Bh
_menuactive	=					     _NULL_OFFSET + 0043Ch
_demoplayback =					     _NULL_OFFSET + 0043Dh



; 43e to 43F free

_psprites =              			 _NULL_OFFSET + 00440h
_vga_read_port_lookup =              _NULL_OFFSET + 00458h
_vissprite_p =                       _NULL_OFFSET + 00470h
; high byte always 0
_cachedbyteheight =                  _NULL_OFFSET + 00472h
_currentMusPage = 					 _NULL_OFFSET + 00474h
_snd_MusicVolume =                   _NULL_OFFSET + 00475h
_gameepisode = 						 _NULL_OFFSET + 00476h
_gamemap = 							 _NULL_OFFSET + 00477h
_savedescription =                   _NULL_OFFSET + 00478h
_demoname =                          _NULL_OFFSET + 00498h
_ems_backfill_page_order =           _NULL_OFFSET + 004B8h
_LINEFLAGSLIST_SEGMENT_PTR =         _NULL_OFFSET + 004D0h
_currentThinkerListHead = 			 _NULL_OFFSET + 004D2h

_S_StartSoundWithSecnum_addr =       _NULL_OFFSET + 004D4h
_G_SecretExitLevel_addr =            _NULL_OFFSET + 004D8h
_AM_Stop_addr =		                 _NULL_OFFSET + 004DCh


_braintargets =                      _NULL_OFFSET + 004E0h
_tmbbox =                            _NULL_OFFSET + 00520h

_SECTORS_SEGMENT_PTR =               _NULL_OFFSET + 00530h
_LINES_PHYSICS_SEGMENT_PTR =         _NULL_OFFSET + 00532h

_HU_Start_addr = 			 	 	 _NULL_OFFSET + 00534h
_ST_Start_addr = 			 	 	 _NULL_OFFSET + 00538h

_pcspeaker_currentoffset = 			 _NULL_OFFSET + 0053Ch
_pcspeaker_endoffset = 			 	 _NULL_OFFSET + 0053Eh

_G_PlayerReborn_addr =	 	 		 _NULL_OFFSET + 00540h
_FixedMulTrigSpeedNoShift_addr =	 _NULL_OFFSET + 00544h
_FixedMulTrigSpeed_addr =			 _NULL_OFFSET + 00548h
_FixedMulTrig_addr = 			 	 _NULL_OFFSET + 0054Ch
_G_DeferedInitNew_addr = 			 _NULL_OFFSET + 00550h


_V_DrawPatch_addr =              	 _NULL_OFFSET + 00554h
;_locallib_toupper_addr =             _NULL_OFFSET + 00558h
_S_ChangeMusic_addr =              	 _NULL_OFFSET + 0055Ch
_V_DrawFullscreenPatch_addr =        _NULL_OFFSET + 00560h
_getStringByIndex_addr =             _NULL_OFFSET + 00564h
;_locallib_strlen_addr =              _NULL_OFFSET + 00568h
_FixedMulTrigNoShift_addr =          _NULL_OFFSET + 0056Ch
_R_PointToAngle2_16_addr =           _NULL_OFFSET + 00570h
_R_PointToAngle2_addr =              _NULL_OFFSET + 00574h


_W_CacheLumpNameDirect_addr =        _NULL_OFFSET + 00578h
_W_CacheLumpNumDirectFragment_addr = _NULL_OFFSET + 0057Ch
_W_GetNumForName_addr =              _NULL_OFFSET + 00580h
_S_StartSound_addr =                 _NULL_OFFSET + 00584h
_S_StartMusic_addr =             	 _NULL_OFFSET + 00588h

; 13 bytes in length
_filename_argument = 				 _NULL_OFFSET + 0058Ch

_rndindex = 						 _NULL_OFFSET + 00599h
_fopen_r_argument = 				 _NULL_OFFSET + 0059Ah
_fopen_w_argument = 				 _NULL_OFFSET + 0059Ch

_numsectors =						 _NULL_OFFSET + 0059Eh
_numlines =						     _NULL_OFFSET + 005A0h
_numvertexes =						 _NULL_OFFSET + 005A2h
_numsegs =						     _NULL_OFFSET + 005A4h
_numsubsectors =				     _NULL_OFFSET + 005A6h
_numnodes =						 	 _NULL_OFFSET + 005A8h
_numsides =						 	 _NULL_OFFSET + 005AAh
_bmapwidth =						 _NULL_OFFSET + 005ACh
_bmapheight =						 _NULL_OFFSET + 005AEh
_bmaporgx =						 	 _NULL_OFFSET + 005B0h
_bmaporgy =				             _NULL_OFFSET + 005B2h

_I_Error_addr =                      _NULL_OFFSET + 005B4h
_P_InitThinkers_addr =               _NULL_OFFSET + 005B8h

_snd_DesiredSfxDevice =              _NULL_OFFSET + 005BCh
_snd_DesiredMusicDevice =            _NULL_OFFSET + 005BDh
_snd_SBirq =              			 _NULL_OFFSET + 005BEh
_snd_SBdma =              			 _NULL_OFFSET + 005BFh


_S_StopSoundMobjRef_addr =           _NULL_OFFSET + 005C0h
_R_DrawSkyPlaneDynamic_addr =  	     _NULL_OFFSET + 005C4h
_snd_SBport =                        _NULL_OFFSET + 005C8h
_snd_Mport =                         _NULL_OFFSET + 005CAh
_I_Quit_addr = 			             _NULL_OFFSET + 005CCh

_tallnum =              			 _NULL_OFFSET + 005D0h
_shortnum =              			 _NULL_OFFSET + 005E4h
_am_buffer =             			 _NULL_OFFSET + 005F8h

_Z_SetOverlay_addr =                 _NULL_OFFSET + 0060Ch
_W_LumpLength_addr =                 _NULL_OFFSET + 00610h

_playingdriver =                     _NULL_OFFSET + 00614h
_currentsong_start_offset =          _NULL_OFFSET + 00618h
_currentsong_playing_offset =        _NULL_OFFSET + 0061Ah
_currentsong_ticks_to_process =      _NULL_OFFSET + 0061Ch
_loops_enabled =    			     _NULL_OFFSET + 0061Eh
_inhelpscreens =    			     _NULL_OFFSET + 0061Fh
_Z_QuickMapMusicPageFrame_addr = 	 _NULL_OFFSET + 00620h

_sightzstart =				         _NULL_OFFSET + 00624h
_topslope =				         	 _NULL_OFFSET + 00628h
_bottomslope =					     _NULL_OFFSET + 0062Ch
_cachedt2x =				         _NULL_OFFSET + 00630h
_cachedt2y =					     _NULL_OFFSET + 00634h
_strace =					         _NULL_OFFSET + 00638h
_sfx_free_bytes = 					 _NULL_OFFSET + 00648h


_activespritepages =                 _NULL_OFFSET + 00670h
_activespritenumpages =              _NULL_OFFSET + 00674h
_spriteL1LRU =                 		 _NULL_OFFSET + 00678h
_spritecache_l2_head =               _NULL_OFFSET + 0067Ch
_spritecache_l2_tail =               _NULL_OFFSET + 0067Dh
_texturecache_l2_head =              _NULL_OFFSET + 0067Eh
_texturecache_l2_tail =              _NULL_OFFSET + 0067Fh
_activetexturepages =                _NULL_OFFSET + 00680h
_activenumpages =                 	 _NULL_OFFSET + 00688h
_textureL1LRU =                 	 _NULL_OFFSET + 00690h
_cachedsegmentlumps =                _NULL_OFFSET + 00698h
_cachedlumps =                 	     _NULL_OFFSET + 006A0h
_cachedtex =                 		 _NULL_OFFSET + 006A8h
_cachedcollength =                   _NULL_OFFSET + 006ACh
_flatcache_l2_head =                 _NULL_OFFSET + 006AEh
_flatcache_l2_tail =                 _NULL_OFFSET + 006AFh
_segloopprevlookup =                 _NULL_OFFSET + 006B0h
_segloopcachedbasecol =              _NULL_OFFSET + 006B4h
_cachedsegmenttex =                  _NULL_OFFSET + 006B8h
_playerMobj =                   	 _NULL_OFFSET + 006BCh
_ceilinglinenum =                    _NULL_OFFSET + 006BEh

_lineopening =				         _NULL_OFFSET + 006C0h

_playerMobjRef =				     _NULL_OFFSET + 006C6h
_intercept_p =				         _NULL_OFFSET + 006C8h
_aimslope = 				         _NULL_OFFSET + 006CCh
_bestslidefrac =				     _NULL_OFFSET + 006D0h
_bestslidelinenum =				     _NULL_OFFSET + 006D4h
_numspechit =				         _NULL_OFFSET + 006D6h
_lastcalculatedsector =				 _NULL_OFFSET + 006D8h

_shootthing =				 		 _NULL_OFFSET + 006DAh
_shootz =				 			 _NULL_OFFSET + 006DCh
_la_damage = 		   			     _NULL_OFFSET + 006E0h

_linetarget = 		   			     _NULL_OFFSET + 006E2h
_linetarget_pos = 		   			 _NULL_OFFSET + 006E4h
_attackrange16 = 		   			 _NULL_OFFSET + 006E8h
_usergame =		   		         	 _NULL_OFFSET + 006EAh
_crushchange = 		   			 	 _NULL_OFFSET + 006EBh
_leveltime =     		   			 _NULL_OFFSET + 006ECh
_fopen_rb_argument =                 _NULL_OFFSET + 006F0h
_currenttask =            		     _NULL_OFFSET + 006F3h

_R_DrawSkyPlane_addr =               _NULL_OFFSET + 006F4h
_OutOfThinkers_addr =                _NULL_OFFSET + 006F8h
_FastDiv32u16u_addr =                _NULL_OFFSET + 006FCh


_playerMobj_pos =		         	 _NULL_OFFSET + 00700h
_MOBJPOSLIST_6800_SEGMENT_PTR =      _NULL_OFFSET + 00702h
_setStateReturn_pos =		         _NULL_OFFSET + 00704h
_gametic =						     _NULL_OFFSET + 00708h
_clipangle =				         _NULL_OFFSET + 0070Ch
_fieldofview =				         _NULL_OFFSET + 0070Eh

_solidsegs = 			         	 _NULL_OFFSET + 00710h
_newend = 				         	 _NULL_OFFSET + 00790h
_pspritescale = 		         	 _NULL_OFFSET + 00792h
_spritewidths_segment =              _NULL_OFFSET + 00794h
_r_cachedplayerMobjsecnum = 		 _NULL_OFFSET + 00796h
_scaledviewwidth = 					 _NULL_OFFSET + 00798h
_viewwindowoffset = 				 _NULL_OFFSET + 0079Ah
_pendingdetail = 				 	 _NULL_OFFSET + 0079Ch
_setsizeneeded = 				 	 _NULL_OFFSET + 0079Eh
_setblocks = 					 	 _NULL_OFFSET + 0079Fh
_player = 						 	 _NULL_OFFSET + 007A0h
_skyquality =  					 	 _NULL_OFFSET + 00803h
_viewwindowx = 					 	 _NULL_OFFSET + 00804h
_viewwindowy = 					 	 _NULL_OFFSET + 00806h
_R_DrawPlanesCall = 	    	 	 _NULL_OFFSET + 00808h
_R_DrawMaskedCall = 			 	 _NULL_OFFSET + 0080Ch
_R_WriteBackMaskedFrameConstantsCall =  _NULL_OFFSET + 00810h
_NetUpdate_addr =					 _NULL_OFFSET + 00814h

_FixedMul16u32_addr =				 _NULL_OFFSET + 00818h
_FastMul16u32u_addr =				 _NULL_OFFSET + 0081Ch
_FastDiv3216u_addr =				 _NULL_OFFSET + 00820h
_bulletslope = 			 			 _NULL_OFFSET + 00824h
_weaponinfo = 			 			 _NULL_OFFSET + 00828h
_G_ExitLevel_addr = 			 	 _NULL_OFFSET + 0088Ch
_w_title =							 _NULL_OFFSET + 00890h
_message_counter =					 _NULL_OFFSET + 008E8h

_levelTimer =						 _NULL_OFFSET + 008E9h
_numlinespecials =					 _NULL_OFFSET + 008EAh
;3c or 60 bytes
_activeceilings =                    _NULL_OFFSET + 008ECh
;3c or 60 bytes
_activeplats =                       _NULL_OFFSET + 00928h
;24 or 36 bytes
_buttonlist =                        _NULL_OFFSET + 00964h
_levelTimeCount =				     _NULL_OFFSET + 00988h
_lastanim =				             _NULL_OFFSET + 0098Ch
_numswitches =						 _NULL_OFFSET + 0098Eh
_anims =				     		 _NULL_OFFSET + 00990h

_switchlist =				         _NULL_OFFSET + 00A50h
_skullAnimCounter =				     _NULL_OFFSET + 00B18h
_whichSkull =				         _NULL_OFFSET + 00B1Ah

_borderdrawcount =       		     _NULL_OFFSET + 00B1Ch
_message_dontfuckwithme =            _NULL_OFFSET + 00B1Dh
_message_on =     			         _NULL_OFFSET + 00B1Eh
_message_nottobefuckedwith =         _NULL_OFFSET + 00B1Fh

_STRING_HELP1   =      				 _NULL_OFFSET + 00B20h
_STRING_HELP2   =      				 _NULL_OFFSET + 00B26h
_STRING_HELP    =      				 _NULL_OFFSET + 00B2Ch

_demosequence =	       		         _NULL_OFFSET + 00B31h

_STRING_newline =                    _NULL_OFFSET + 00B32h

_advancedemo =	       			     _NULL_OFFSET + 00B34h
_usegamma =	       			         _NULL_OFFSET + 00B35h
_sfxVolume =	       			     _NULL_OFFSET + 00B36h
_musicVolume =	       			     _NULL_OFFSET + 00B37h
_snd_SfxVolume =      			     _NULL_OFFSET + 00B38h
_detailLevel =	       			     _NULL_OFFSET + 00B39h
_screenSize =	       			     _NULL_OFFSET + 00B3Ah
_mouseSensitivity =   			     _NULL_OFFSET + 00B3Bh
_showMessages =       			     _NULL_OFFSET + 00B3Ch
_quickSaveSlot =      			     _NULL_OFFSET + 00B3Dh
_savegameslot =       			     _NULL_OFFSET + 00B3Eh
_modifiedgame =       			     _NULL_OFFSET + 00B3Fh
_savename = 	      			     _NULL_OFFSET + 00B40h
_hu_font =	 	      			     _NULL_OFFSET + 00B50h


_viewactivestate =	 	     	     _NULL_OFFSET + 00BCEh
_menuactivestate =	 	     	     _NULL_OFFSET + 00BCFh
_sb_voicelist =	 	  			   	 _NULL_OFFSET + 00BD0h

_fopen_addr =     			         _NULL_OFFSET + 00C10h
_fseek_addr =     			         _NULL_OFFSET + 00C14h
_fread_addr =     			         _NULL_OFFSET + 00C18h
_fclose_addr =    			         _NULL_OFFSET + 00C1Ch
_locallib_far_fread_addr =    		 _NULL_OFFSET + 00C20h
_S_InitSFXCache_addr =     	    	 _NULL_OFFSET + 00C24h
_R_SetViewSize_addr =     	    	 _NULL_OFFSET + 00C28h

_flatcache_nodes =				     _NULL_OFFSET + 00C30h

CURRENT_POSITION_1 =  			      (_flatcache_nodes    + (SIZEOF_CACHE_NODE_T * NUM_FLAT_CACHE_PAGES))
_spritecache_nodes =				  CURRENT_POSITION_1
CURRENT_POSITION_2 =   			      (_spritecache_nodes  + (SIZEOF_CACHE_NODE_PAGE_COUNT_T * NUM_SPRITE_CACHE_PAGES))
_texturecache_nodes =				  CURRENT_POSITION_2
CURRENT_POSITION_3 =   			      (_texturecache_nodes + (SIZEOF_CACHE_NODE_PAGE_COUNT_T * NUM_TEXTURE_PAGES))

_allocatedflatsperpage =		      CURRENT_POSITION_3
CURRENT_POSITION_4 =   			      (_allocatedflatsperpage  + (1 * NUM_FLAT_CACHE_PAGES))
_usedspritepagemem =				  CURRENT_POSITION_4
CURRENT_POSITION_5 =   			      (_usedspritepagemem  + (1 * NUM_SPRITE_CACHE_PAGES))
_usedtexturepagemem =				  CURRENT_POSITION_5
CURRENT_POSITION_6 =   			   	  (_usedtexturepagemem + (1 * NUM_TEXTURE_PAGES))



; 94E ?
_pageswapargs = CURRENT_POSITION_6

CURRENT_POSITION_7 =   			   	  (_pageswapargs + (2 * TOTAL_PAGES))







;06CAh





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

PUSHA_NO_AX_MACRO MACRO

IF COMPISA GE COMPILE_186
	pusha
ELSE	
	push  bx
	push  cx
	push  dx
	push  bp
	push  si
	push  di
ENDIF

ENDM


PUSHA_NO_AX_OR_BP_MACRO MACRO

IF COMPISA GE COMPILE_186
	pusha
ELSE	
	push  bx
	push  cx
	push  dx
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
	pop   dx
	pop   cx
	pop   bx
ENDIF

ENDM

POPA_NO_AX_OR_BP_MACRO MACRO

IF COMPISA GE COMPILE_186
	popa
ELSE	
	pop   di
	pop   si
	pop   dx
	pop   cx
	pop   bx
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
			out  	dx, al
			mov  	dx, SCAT_PAGE_SET_REGISTER 
			lodsw
			out 	dx, ax
		ENDM

		Z_QUICKMAPAI2 MACRO pageswapindex, page
			mov     si,  &pageswapindex * 2 * PAGE_SWAP_ARG_MULT + OFFSET _pageswapargs
			mov  	dx, SCAT_PAGE_SELECT_REGISTER
			mov     al, page OR EMS_AUTOINCREMENT_FLAG
			out  	dx, al
			mov  	dx, SCAT_PAGE_SET_REGISTER
			lodsw
			out 	dx, ax
			lodsw
			out 	dx, ax
		ENDM

		Z_QUICKMAPAI3 MACRO pageswapindex, page
			mov     si,  &pageswapindex * 2 * PAGE_SWAP_ARG_MULT + OFFSET _pageswapargs
			mov  	dx, SCAT_PAGE_SELECT_REGISTER
			mov     al, page OR EMS_AUTOINCREMENT_FLAG
			out  	dx, al
			mov  	dx, SCAT_PAGE_SET_REGISTER
			lodsw
			out 	dx, ax
			lodsw
			out 	dx, ax
			lodsw
			out 	dx, ax
		ENDM

		Z_QUICKMAPAI4 MACRO pageswapindex, page
			mov     si,  &pageswapindex * 2 * PAGE_SWAP_ARG_MULT + OFFSET _pageswapargs
			mov  	dx, SCAT_PAGE_SELECT_REGISTER
			mov     al, page OR EMS_AUTOINCREMENT_FLAG
			out  	dx, al
			mov  	dx, SCAT_PAGE_SET_REGISTER
			mov  	cx, 4
			rep  	outsw
		ENDM

		Z_QUICKMAPAI5 MACRO pageswapindex, page
			mov     si,  &pageswapindex * 2 * PAGE_SWAP_ARG_MULT + OFFSET _pageswapargs
			mov  	dx, SCAT_PAGE_SELECT_REGISTER
			mov     al, page OR EMS_AUTOINCREMENT_FLAG
			out  	dx, al
			mov  	dx, SCAT_PAGE_SET_REGISTER
			mov  	cx, 5
			rep  	outsw
		ENDM

		Z_QUICKMAPAI6 MACRO pageswapindex, page
			mov     si,  &pageswapindex * 2 * PAGE_SWAP_ARG_MULT + OFFSET _pageswapargs
			mov  	dx, SCAT_PAGE_SELECT_REGISTER
			mov     al, page OR EMS_AUTOINCREMENT_FLAG
			out  	dx, al
			mov  	dx, SCAT_PAGE_SET_REGISTER
			mov  	cx, 6
			rep  	outsw
		ENDM

		Z_QUICKMAPAI7 MACRO pageswapindex, page
			mov     si,  &pageswapindex * 2 * PAGE_SWAP_ARG_MULT + OFFSET _pageswapargs
			mov  	dx, SCAT_PAGE_SELECT_REGISTER
			mov     al, page OR EMS_AUTOINCREMENT_FLAG
			out  	dx, al
			mov  	dx, SCAT_PAGE_SET_REGISTER
			mov  	cx, 7
			rep  	outsw
		ENDM

		Z_QUICKMAPAI8 MACRO pageswapindex, page
			mov     si,  &pageswapindex * 2 * PAGE_SWAP_ARG_MULT + OFFSET _pageswapargs
			mov  	dx, SCAT_PAGE_SELECT_REGISTER
			mov     al, page OR EMS_AUTOINCREMENT_FLAG
			out  	dx, al
			mov  	dx, SCAT_PAGE_SET_REGISTER
			mov  	cx, 8
			rep  	outsw
		ENDM

		Z_QUICKMAPAI16 MACRO pageswapindex, page
			mov     si,  &pageswapindex * 2 * PAGE_SWAP_ARG_MULT + OFFSET _pageswapargs
			mov  	dx, SCAT_PAGE_SELECT_REGISTER
			mov     al, page OR EMS_AUTOINCREMENT_FLAG
			out  	dx, al
			mov  	dx, SCAT_PAGE_SET_REGISTER
			mov  	cx, 16
			rep  	outsw
		ENDM

		Z_QUICKMAPAI24 MACRO pageswapindex, page
			mov     si,  &pageswapindex * 2 * PAGE_SWAP_ARG_MULT + OFFSET _pageswapargs
			mov  	dx, SCAT_PAGE_SELECT_REGISTER
			mov  	al, 080h     ; 080h for autoincrement enable. 00h for page 4000 index
			out  	dx, al
			mov  	dx, SCAT_PAGE_SET_REGISTER
			mov  	cx, 24
			rep  	outsw
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
			out     SCAMP_PAGE_SELECT_REGISTER, al
			lodsw
			out 	SCAMP_PAGE_SET_REGISTER, ax
		ENDM

		Z_QUICKMAPAI2 MACRO pageswapindex, page
			mov     si,  &pageswapindex * 2 * PAGE_SWAP_ARG_MULT + OFFSET _pageswapargs
			mov     al, page OR EMS_AUTOINCREMENT_FLAG
			out     SCAMP_PAGE_SELECT_REGISTER, al
			lodsw
			out 	SCAMP_PAGE_SET_REGISTER, ax
			lodsw
			out 	SCAMP_PAGE_SET_REGISTER, ax
		ENDM

		Z_QUICKMAPAI3 MACRO pageswapindex, page
			mov     si,  &pageswapindex * 2 * PAGE_SWAP_ARG_MULT + OFFSET _pageswapargs
			mov     al, page OR EMS_AUTOINCREMENT_FLAG
			out     SCAMP_PAGE_SELECT_REGISTER, al
			lodsw
			out 	SCAMP_PAGE_SET_REGISTER, ax
			lodsw
			out 	SCAMP_PAGE_SET_REGISTER, ax
			lodsw
			out 	SCAMP_PAGE_SET_REGISTER, ax
		ENDM

		Z_QUICKMAPAI4 MACRO pageswapindex, page
			mov     si,  &pageswapindex * 2 * PAGE_SWAP_ARG_MULT + OFFSET _pageswapargs
			mov     al, page OR EMS_AUTOINCREMENT_FLAG
			out     SCAMP_PAGE_SELECT_REGISTER, al
			mov	    dx, SCAMP_PAGE_SET_REGISTER
			mov     cx, 4
			rep     outsw			
		ENDM

		Z_QUICKMAPAI5 MACRO pageswapindex, page
			mov     si,  &pageswapindex * 2 * PAGE_SWAP_ARG_MULT + OFFSET _pageswapargs
			mov     al, page OR EMS_AUTOINCREMENT_FLAG
			out     SCAMP_PAGE_SELECT_REGISTER, al
			mov	    dx, SCAMP_PAGE_SET_REGISTER
			mov     cx, 5
			rep     outsw			
		ENDM

		Z_QUICKMAPAI6 MACRO pageswapindex, page
			mov     si,  &pageswapindex * 2 * PAGE_SWAP_ARG_MULT + OFFSET _pageswapargs
			mov     al, page OR EMS_AUTOINCREMENT_FLAG
			out     SCAMP_PAGE_SELECT_REGISTER, al
			mov	    dx, SCAMP_PAGE_SET_REGISTER
			mov     cx, 6
			rep     outsw			
		ENDM

		Z_QUICKMAPAI7 MACRO pageswapindex, page
			mov     si,  &pageswapindex * 2 * PAGE_SWAP_ARG_MULT + OFFSET _pageswapargs
			mov     al, page OR EMS_AUTOINCREMENT_FLAG
			out     SCAMP_PAGE_SELECT_REGISTER, al
			mov	    dx, SCAMP_PAGE_SET_REGISTER
			mov     cx, 7
			rep     outsw			
		ENDM

		Z_QUICKMAPAI8 MACRO pageswapindex, page
			mov     si,  &pageswapindex * 2 * PAGE_SWAP_ARG_MULT + OFFSET _pageswapargs
			mov     al, page OR EMS_AUTOINCREMENT_FLAG
			out     SCAMP_PAGE_SELECT_REGISTER, al
			mov	    dx, SCAMP_PAGE_SET_REGISTER
			mov     cx, 8
			rep     outsw			
		ENDM

		Z_QUICKMAPAI16 MACRO pageswapindex, page
			mov     si,  &pageswapindex * 2 * PAGE_SWAP_ARG_MULT + OFFSET _pageswapargs
			mov     al, page OR EMS_AUTOINCREMENT_FLAG
			out     SCAMP_PAGE_SELECT_REGISTER, al
			mov	    dx, SCAMP_PAGE_SET_REGISTER
			mov     cx, 16
			rep     outsw			
		ENDM

		Z_QUICKMAPAI24 MACRO pageswapindex, page
			mov     si,  &pageswapindex * 2 * PAGE_SWAP_ARG_MULT + OFFSET _pageswapargs
			mov  	al, 04Ch     ; 040h for autoincrement enable. 0Ch for page 4000 index

			out     SCAMP_PAGE_SELECT_REGISTER, al
			mov	    dx, SCAMP_PAGE_SET_REGISTER
			mov     cx, 24
			rep     outsw			
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

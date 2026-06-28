# RealDOOM


[![RealDOOM 0.88 Beta Recording](https://i3.ytimg.com/vi/w407QgRCqE8/maxresdefault.jpg)](https://www.youtube.com/watch?v=w407QgRCqE8)


RealDOOM is an in progress port of the DOS version of DOOM (based on PCDOOMv2) to Real Mode to support 16-bit processors (namely the 8088 and 286). It is meant to be accurate to the original game and id software WADs first and foremost. So it should work with timedemos, and have the support for the same level of graphical detail as the original game.

The current release supports Shareware and commercial DOOM/DOOM2 as well as Ultimate DOOM. TNT and Plutonia are not currently supported. Custom wads are not currently supported.

The current development focus is on finding remaining bugs and adding a few missing features.

### Running RealDOOM

RealDOOM is still in a Pre-Beta state and so it does not cleanly support many hardware configurations yet. The easiest way to run it is to use EMM386 with a page frame set and the pageable conventional memory enabled. 16 bit machines will need EMS 4.0 compatible hardware with conventional pagination such as a 286 chipset supporting such features or a something like an Intel Above Board.

Performance on 32-bit PCs is a little faster than Vanilla DOOM for processors with onboard cache, and much faster than Vanilla DOOM for processors without onboard cache. A well-tuned 25 mhz 286 should manage ~10-20 fps depending on quality settings. A 386DX-40 should manage 12-30 fps depending on quality settings.

The "minimum spec" is a standard 4.77 MhZ 8088 machine with a VGA card, ~560KB conventional free, a hard disk that can fit the software/WAD, and 256 KB of system memory with a 2 MB populated Intel Above Board (or other compatible EMS 4.0 board with backfill - note that Lo-Tech EMS card does not support backfill). Many 286 chipsets (C&T SCAT, VLSI SCAMP, VLSI TOPCAT... ) support EMS 4.0 and you will be able to use their appropriate EMS drivers or SQEMM, or the chipset specific build if available, which is faster.

### Building RealDOOM

Building RealDOOM requires openwatcom 2.0 and tasm 2.51.
Simply run the makeall script and select your build option (286, 386, 8086, chipset, etc).

### Removed features (not planned to be re-added)
 - joystick support
 - multiplayer/networking

###  Broken/unimplemented features 
 - custom wads

There are also a lot of hard caps on things like texture size and count, node count, etc. 

### Known bugs:
 - Occasional garbage column drawns
 - Lots of subpixel graphical inaccuracies compared to Vanilla DOOM
 - Save name entry eats keys sometimes
 
### Release History:

(Dec 4, 2023)      
~~**v0.10 release**: mostly stable shareware demo~~

(Dec 12, 2023)      
~~**v0.11 release**: UMB usage and all shareware demos playable. Last EMS 3.2 compatible version?~~
   - render bugfixes
   - use UMBs if available - e1m6 now playable
     
(Jan 11, 2024)      
~~**v0.15** :  EMS 4.0 multitasking features~~
  - EMS 4.0 multitasking
     - dynamic allocations in the 256-640KB memory range
     - level data and things broken into physics/render regions    
     - texture cache added for more textures in memory during render
     - using full sine tables again
     - visplane cap only 60 for now, to be fixed in 0.16
     - removed use of page frame
  - Some fixes and additions:  
     - fixed fwipe (screen wipe)
     - fixed intermission animations
     - fixed finale
     - added 286 build option

(May 23, 2024)      
~~**v0.20** : Commercial game/feature support~~
  - doom 1 wad support, full timedemo compatibility
  - doom 2 wad support, full timedemo compatibility
  - medium memory model
  - ems visplane allocation
  - texture cache improvements
  - many bugfixes, memory organization improvements

(Jun 18, 2024)      
~~**v0.21** : ASM improvements~~
  - R_DrawColumn, R_DrawSpan, R_MapPlane ASM optimized
  - Potato quality implemented
  - FixedMul ASM Optimized

(Aug 20, 2024)      
~~**v0.22** : More ASM improvements~~
  - FixedDiv ASM optimized
  - Additional render pipeline optimization
  - Textures paragraph/segment aligned

(Oct 11, 2024)      
~~**v0.23** : Memory, Build~~
  - fixed DS to 0x3C00
  - build tools to support fixed DS and binary offloading to file
  - offloaded render function binaries loaded into EMS memory at runtime
  - 286 chipset specific builds
  - binary size significantly reduced
  - 386 math build option (WIP, only FixedMul)
  - improved rendering fidelity

(Jan 8, 2025)      
~~**v0.24** : More ASM improvements~~
  - main render pipeline ASM optimzied
  - increased texture cache size
  - more code moved into offloaded binary
  - various render and engine bugfixes
  - additional 386 optimized math functions

(Mar 31, 2025)      
~~**v0.25** : Improved feature compatibility~~
  - fix save/load game
  - fix demo recording
  - implement music
  - more code moved into offloaded binary

(May 15, 2025)      
~~**v0.26** : SFX implementation~~
  - Implemented Speaker SFX
  - Implemented Sound Blaster SFX
  - various bugfixes

(Jun 24, 2025)      
~~**v0.27** : ASM Optimizations~~
  - EMS paginated WAD fields
  - 30kb or so of c converted to asm
  - binary size decreased, code a little faster

(Jul 3, 2025)      
~~**v0.28** : E000 requirement removed~~
  - Exported a ton more code to reduce binary size ~30k
  - Moved E000 data into low memory area
  - Moved pagination code from C to asm

(Jul 22, 2025)      
~~**v0.29** : Physics code to ASM~~
  - Exported more code to reduce binary size ~18k
  - Fixed many enemy behavior bugs
  - Restored music driver support which had been removed in 0.28

(Aug 2, 2025)      
~~**v0.30** : Physics code to ASM~~
  - ASM optimization of some physics code saving ~6k
  - Improved span drawing fidelity to 24 bit (same as vanilla)
  - Added span/column/sky rendering fidelity options
  
(Sep 20, 2025)      
~~**v0.31** : Bugfixes, most code to ASM~~
  - Major ASM rewrites of c code saving ~35-40k
  - Movable EMS Page Frame
  - Lots of bugfixing...

 (Sep 28, 2025)      
~~**v0.32** : Bugfixes~~
  - Lots more bugfixing...
 
 (Oct 11, 2025)      
~~**v0.78** : Pre-Alpha 1~~
  - Sound effects bugfixed but not optimized

(April 4, 2026)  
~~**v0.87** : Pre-Pre Beta 1~~
  - Fully ASM engine
  - Near fully render pipeline rewrite
  - 25-30% FPS increase compared to 0.78

(May 5, 2026)  
~~**v0.88** : Pre-Pre Beta 2~~
  - Full render pipeline rewrite
  - 35-40% FPS increase compared to 0.78

(Jun 27, 2026)  
**v0.89** : Beta Release 1
  - Sound bugs fixes
  - Save bugs fixed
  - Various DOOM 2 bugs fixed
  - Small physics framerate improvements.


### Future Roadmap:
  
**Post Beta Goals:**
 - Improved custom WAD support
 - Fix Flat Renderer
 - FPU support
 - Physics optimization
 

**"1.0" Goals:**
 - Further 386 render path optimizations
 - General stability and architecture improvements
 - EMS 3.2 compatible version
 - Remove MS-DOS dependencies, self boot version?
  

### Speed

Various performance benchmarks can be found in this spreadsheet:
[RealDOOM Benchmark Results](https://docs.google.com/spreadsheets/d/1gt8gqvKrvJh5GH_xDKoZ98G4jY873s6zx_Y5EaFbb7M/)

For the most part, a 386SX currently runs RealDOOM ~80-90% faster than (vanilla) DOOM 1.9. A 386DX runs 50-56% faster. A 286-25 achieves around 9-10 FPS in high quality, 14-16 in low, and 20-22 in potato quality. 5150/5160 class machines are sub 1 FPS.

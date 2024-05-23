# RealDOOM

[![Old Demo Recording](http://img.youtube.com/vi/AiPq9BUOa98/0.jpg)](https://www.youtube.com/watch?v=AiPq9BUOa98 "RealDOOM v 0.2-ish DOOM2 Map 20 gameplay")



RealDOOM is an in progress port of the DOS version of DOOM (based on PCDOOMv2) to Real Mode, to support 16-bit processors (namely the 8088 and 286). It is meant to be accurate to the original game and id software WADs first and foremost. So it should work with timedemos, and have the support for the same level of graphical detail as the original game.


- As of release 0.11, the game is fully playable with the shareware DOOM1.WAD file. 
- As of version 0.15, the game is no longer compatible with DOSBox because DOSBox lacks support for EMS 4.0 with backfill.
- As of release 0.20, the game is fully playable with commercial DOOM.WAD and DOOM2.WAD files
- (Final DOOM WADs are not planned to be supported, the levels are too big and I can't think of a good way to fit everything in memory)

The current development focus is on stability and architecture rather than speed improvements, which will come after the engine is in a more realmode-friendly state.

To build an optimized 80286 build, run make286.bat. Otherwise, run make16.bat for 8088 support.

If running on real hardware, a pentium or fast 486 is current recommended.

The minimum spec will eventually be a standard 4.77 MhZ 8088 machine with a VGA card, a hard disk that can fit the software/WAD, and 256 KB of system memory with a 2 MB populated Intel Above Board (or other compatible EMS 4.0 board with backfill - note that Lo-Tech EMS card does not support backfill). Many 286 chipsets support EMS 4.0 and you will be able to use their appropriate EMS drivers. 

### Removed features (not planned to be re-added)
 - multiplayer and netplay
 - joystick support
 

###  Broken/unimplemented features (planned to be fixed)
 - sound (will require writing a 16 bit library for this)
 - savegames (will require a rewrite of the archive/unarchive code)

There are also a lot of hard caps on things like texture size and count, node count, etc, which will probably make many custom WADs unplayable. oh well.


### Known bugs:
 - some ceiling textures seem to render in lower detail or the wrong lightmaps
 - 8088 build probably currently doesn't work (it probably generates a binary that is too big - this will be fixed as the binary shrinks over the next months)

### High-Level Roadmap:
 Not necessarily meant to be accurate, but just to give an overview of the general order in which things are probably going to be built.

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
   
 
    
 **v0.21** : ASM improvements
  - some level of early easy asm work (math functions?)

 **v0.22** : ASM improvements
  - function binaries loaded into EMS memory at runtime
  - fixed DS to 0x3C00? 

 **v0.23** : ASM improvements
  - core drawing functions rewritten in asm

 **v0.25** : ASM improvements
  - full render pipeline written in asm and runtime-loaded/linked render asm
    
 **v0.30** : Full feature compatibility?
  - sound code?
  - fix save/load game?
      
 **v0.xx** : Continued improvement
  - continued moving of code to asm, optimizations, etc
    - physics code profiled, some main loops written in asm?
    - manually written overlay code, more dynamic linking to free more space?
    
 **v0.??**
  - highly optimized but non-timedemo conformant 286 super-optimized version?
 


### Speed

(NOTE: these speeds are based off Release 0.10 and somewhat dated)
Current Realtics/FPS for shareware DOOM1.WAD timedemo3 with screenblocks 5 and high quality:

| Machine Specs  | 86box  |  FPS | Real Hardware | FPS |
| ------------- | ------------- | ------------- | ------------- | ------------- |
| Pentium MMX 233  | 1148 | 65.06 |  830  | 89.99 |
| Pentium 133  | 1695  |44.06 |||
| AMD 5x86 P90  | 2637 | 28.32 |||
| 486 DX2-66  | 5637|  13.25 |||
| 486 SX-33  | 10529 | 7.09| ||
| 386 DX-40  | 12989  | 5.75| 12534| 5.96|
| 286-25  | 31821   | 2.35| ||
| 286-20  ||| 32377 | 2.31|
| v20 9.5 MhZ  | || 162157   | 0.46 |  
| 8088 4.77 MhZ (NuXT) | || 351970   | 0.21 |  
| 8088 4.77 MhZ (5150) | || 384254   | 0.19 |  


I think we are looking for around 5-10x performance uplift from the current point to reach playability on fast 286es.

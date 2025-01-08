# RealDOOM

[![Old Demo Recording](http://img.youtube.com/vi/AiPq9BUOa98/0.jpg)](https://www.youtube.com/watch?v=AiPq9BUOa98 "RealDOOM v 0.2-ish DOOM2 Map 20 gameplay")



RealDOOM is an in progress port of the DOS version of DOOM (based on PCDOOMv2) to Real Mode to support 16-bit processors (namely the 8088 and 286). It is meant to be accurate to the original game and id software WADs first and foremost. So it should work with timedemos, and have the support for the same level of graphical detail as the original game.


- As of release 0.11, the game is fully playable with the shareware DOOM1.WAD file. 
- As of version 0.15, the game is no longer compatible with DOSBox because DOSBox lacks support for EMS 4.0 with backfill.
- As of release 0.20, the game is fully playable with commercial DOOM.WAD and DOOM2.WAD files
- Final/Ultimate DOOM WADs are planned to eventually be supported.

The current development focus is on ASM rewrites of most of the render code. This will be followed by re-adding removed features.

Building RealDOOM requires openwatcom 2.0 and tasm 2.51.
Simply run the makeall script and select your build option (286, 386, 8086, chipset, etc).

If running on real hardware, a 486 or Pentium should generally run the game okay in high quality. A 386 or 286 should be fast and also use low or potato detail to get an agreeable framereate.

The "minimum spec" is a standard 4.77 MhZ 8088 machine with a VGA card, a hard disk that can fit the software/WAD, and 256 KB of system memory with a 2 MB populated Intel Above Board (or other compatible EMS 4.0 board with backfill - note that Lo-Tech EMS card does not support backfill). Many 286 chipsets (C&T SCAT, VLSI SCAMP, VLSI TOPCAT... ) support EMS 4.0 and you will be able to use their appropriate EMS drivers or SQEMM, or the chipset specific build if available, which is faster.

### Removed features (not planned to be re-added)
 - joystick support

###  Broken/unimplemented features (planned to be fixed)
 - sound (will require writing a 16 bit library for this)
 - savegames (will require a rewrite of the archive/unarchive code)
 - multiplayer/networking? (not sure)


There are also a lot of hard caps on things like texture size and count, node count, etc, which will probably make many custom WADs unplayable. oh well.


### Known bugs:
 - some corruption may be happening in single pixel sprite draws
 - span/plane draws may lack texture precision and be a little 'fuzzy'
 
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

 (Jan 8, 2025
 ~~**v0.25** : More ASM improvements~~
  - main render pipeline ASM optimzied
  - increased texture cache size
  - more code moved into offloaded binary
  - various render and engine bugfixes
  - additional 386 optimized math functions
    
**v0.30** : Improved feature compatibility
  - core physics functions rewritten in asm
  - fix save/load game?
  - fix demo recording
  - more code moved into offloaded binary
  - improved span drawing fidelity 

**v0.40** : Sound Support, Alpha release
  - sound and music code
  - more code moved into offloaded binary
  - fixing of all known bugs? (hopefully)
 
 **v0.xx** : Continued improvement
  - improved custom WAD support.
  - TNT, Plutonia support?
  - continued moving of code to asm, optimizations, etc
  - Entire codebase in asm? Remove c lib dependencies?
  - Remove MS-DOS dependencies, self boot?
  - highly optimized but non-timedemo conformant 286 super-optimized version?
  - Protected mode 286 version? (Probably slower)
 


### Speed

Various performance benchmarks can be found in this spreadsheet:
[https://docs.google.com/spreadsheets/d/1gt8gqvKrvJh5GH_xDKoZ98G4jY873s6zx_Y5EaFbb7M/](url)

For the most part, a 386SX currently runs RealDOOM ~20% faster than (vanilla) DOOM 1.9. 32 bit bus cpus all generally run it 5-10% worse than vanilla. A very fast 286 achieves around 6-7 FPS in high quality, 9-10 in low, and 13-14 in potato quality.

# RealDOOM

[![Real Hardware recording](https://img.youtube.com/vi/F9RYZJlCTsI/0.jpg)](https://www.youtube.com/watch?v=F9RYZJlCTsI "RealDOOM v 0.24 DOOM2 Recording")


RealDOOM is an in progress port of the DOS version of DOOM (based on PCDOOMv2) to Real Mode to support 16-bit processors (namely the 8088 and 286). It is meant to be accurate to the original game and id software WADs first and foremost. So it should work with timedemos, and have the support for the same level of graphical detail as the original game.

The current release supports Shareware and commercial DOOM/DOOM2 as well as Ultimate DOOM. TNT and Plutonia are not currently supported. Custom wads are not currently supported.

The current development focus is on bugfixing and ASM rewrites of most of the codebase to reduce memory usage. 

### Running RealDOOM

RealDOOM is still in a pre-alpha state and so it does not cleanly support many hardware configurations yet. The easiest way to run it is to follow the instructions in the latest release notes.

Performance on 32-bit PCs is similar to Vanilla DOOM, so performance should generally be okay on a 486 or Pentium. Slower machines might want to turn detail level to low or potato for faster framerates.

The "minimum spec" is a standard 4.77 MhZ 8088 machine with a VGA card, 64kb of UMBs in E000 range, a hard disk that can fit the software/WAD, and 256 KB of system memory with a 2 MB populated Intel Above Board (or other compatible EMS 4.0 board with backfill - note that Lo-Tech EMS card does not support backfill). Many 286 chipsets (C&T SCAT, VLSI SCAMP, VLSI TOPCAT... ) support EMS 4.0 and you will be able to use their appropriate EMS drivers or SQEMM, or the chipset specific build if available, which is faster.

### Building RealDOOM

Building RealDOOM requires openwatcom 2.0 and tasm 2.51.
Simply run the makeall script and select your build option (286, 386, 8086, chipset, etc).

### Removed features (not planned to be re-added)
 - joystick support

###  Broken/unimplemented features 
 - multiplayer/networking? (not sure if it will be re-added)
 - custom wads

There are also a lot of hard caps on things like texture size and count, node count, etc. 

### Known bugs:
 - span/plane draws use 16 and not 24 bit texture precision and be a little noisy
 - occasional mystery crashes
 
### Release History:
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

### Future Roadmap:

**Alpha Goals:**
 - E000 UMB requirement removed
 - improved span drawing fidelity
 - improved sfx code
 - All known bugs fixed
 x Feature complete
 x EMS paginated WAD fields


**Beta Goals:**
 - Focus on improved compatibility with more machines
 - "More" feature complete
   - AWE32, Gravis SFX - etc
 - Improved custom WAD support


**"1.0" Goals:**
 - Remove clib dependencies
 - Entirely ASM application
 - 386 Render path optimization (for 386SX)
**Post 1.0 Goals:**
 - EMS 3.2 compatible version
 - Remove MS-DOS dependencies, self boot version?
  


### Speed

Various performance benchmarks can be found in this spreadsheet:
[https://docs.google.com/spreadsheets/d/1gt8gqvKrvJh5GH_xDKoZ98G4jY873s6zx_Y5EaFbb7M/](url)

For the most part, a 386SX currently runs RealDOOM ~20% faster than (vanilla) DOOM 1.9. 32 bit bus cpus all generally run it 5-10% worse than vanilla. A very fast 286 achieves around 6-7 FPS in high quality, 9-10 in low, and 13-14 in potato quality.

@echo off
REM full make script including clean and re-run of codegen.
set arg1=%1

IF "%1" == "" GOTO PRINT_EXIT
IF "%1" == "286" GOTO MAKE_286
IF "%1" == "386" GOTO MAKE_386
IF "%1" == "8086" GOTO MAKE_8086
IF "%1" == "8088" GOTO MAKE_8086
IF "%1" == "186" GOTO MAKE_186
IF "%1" == "SCAMP" GOTO MAKE_SCAMP
IF "%1" == "SCAT" GOTO MAKE_SCAT
IF "%1" == "HT18" GOTO MAKE_HT18

GOTO PRINT_EXIT

:MAKE_8086
    wmake -f build\make16 clean
    wmake -f build\makebg EXTERNASMOPT="/dCOMPILE_INSTRUCTIONSET=0" USE_ISA="0"
    bingen.exe
    move doomcode.bin bin\doomcode.bin /Y
    wmake -f build\makecg clean
    wmake -f build\makecg 
    codegen.exe
    wmake -f build\make16 clean
    wmake -f build\makebg EXTERNASMOPT="/dCOMPILE_INSTRUCTIONSET=0" USE_ISA="0"
    bingen.exe
    wmake -f build\make16
GOTO END

:MAKE_186
    wmake -f build\make186 clean
    wmake -f build\makebg EXTERNASMOPT="/dCOMPILE_INSTRUCTIONSET=1" USE_ISA="1"
    bingen.exe
    move doomcode.bin bin\doomcode.bin /Y
    wmake -f build\makecg clean
    wmake -f build\makecg 
    codegen.exe
    wmake -f build\make186 clean
    wmake -f build\makebg EXTERNASMOPT="/dCOMPILE_INSTRUCTIONSET=1" USE_ISA="1"
    bingen.exe
    wmake -f build\make186
GOTO END

:MAKE_286
    wmake -f build\make286 clean
    wmake -f build\makebg EXTERNASMOPT="/dCOMPILE_INSTRUCTIONSET=2" USE_ISA="2"
    bingen.exe
    move doomcode.bin bin\doomcode.bin /Y
    wmake -f build\makecg clean
    wmake -f build\makecg 
    codegen.exe
    wmake -f build\make286 clean
    wmake -f build\makebg EXTERNASMOPT="/dCOMPILE_INSTRUCTIONSET=2" USE_ISA="2"
    bingen.exe
    wmake -f build\make286
GOTO END

:MAKE_386
    wmake -f build\make386 clean
    wmake -f build\makebg EXTERNASMOPT="/dCOMPILE_INSTRUCTIONSET=3" USE_ISA="3"
    bingen.exe
    move doomcode.bin bin\doomcode.bin /Y
    wmake -f build\makecg clean
    wmake -f build\makecg 
    codegen.exe
    wmake -f build\make386 clean
    wmake -f build\makebg EXTERNASMOPT="/dCOMPILE_INSTRUCTIONSET=3" USE_ISA="3"
    bingen.exe
    wmake -f build\make386
GOTO END


:MAKE_SCAT
    wmake -f build\makescat clean 
    wmake -f build\makebg @B_SCAT.TA
    bingen.exe
    move doomcode.bin bin\doomcode.bin /Y
    wmake -f build\makecg clean
    wmake -f build\makecg 
    codegen.exe
    wmake -f build\makescat clean 
    wmake -f build\makebg @B_SCAT.TA
    bingen.exe
    wmake -f build\makescat
GOTO END



:MAKE_SCAMP
    wmake -f build\makesc clean 
    wmake -f build\makebg @B_SCAMP.TA
    bingen.exe
    move doomcode.bin bin\doomcode.bin /Y
    wmake -f build\makecg clean
    wmake -f build\makecg 
    codegen.exe
    wmake -f build\makesc clean 
    wmake -f build\makebg @B_SCAMP.TA
    bingen.exe
    wmake -f build\makesc
GOTO END



:MAKE_HT18
    wmake -f build\makeht clean 
    wmake -f build\makebg @B_HT18.TA
    bingen.exe
    move doomcode.bin bin\doomcode.bin /Y
    wmake -f build\makecg clean
    wmake -f build\makecg 
    codegen.exe
    wmake -f build\makeht clean 
    wmake -f build\makebg @B_HT18.TA
    bingen.exe
    wmake -f build\makeht
GOTO END


:PRINT_EXIT
    echo:
    echo Usage: makeall [286] [8086] [186] [SCAMP] [SCAT] [HT18] [386]
    echo:
GOTO END

:END
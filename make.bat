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
    wmake -f build\make16 %2 %3 %4 %5 %6 %7 %8 %9
GOTO END

:MAKE_186
    wmake -f build\make186 %2 %3 %4 %5 %6 %7 %8 %9
GOTO END

:MAKE_286
    wmake -f build\make286 %2 %3 %4 %5 %6 %7 %8 %9
GOTO END

:MAKE_386
    wmake -f build\make386 %2 %3 %4 %5 %6 %7 %8 %9
GOTO END

:MAKE_SCAT
    wmake -f build\makescat %2 %3 %4 %5 %6 %7 %8 %9
GOTO END

:MAKE_SCAMP
    wmake -f build\makesc %2 %3 %4 %5 %6 %7 %8 %9
GOTO END

:MAKE_HT18
    wmake -f build\makeht %2 %3 %4 %5 %6 %7 %8 %9
GOTO END


:PRINT_EXIT
    echo:
    echo Usage: make [286] [8086] [186] [SCAMP] [SCAT] [HT18] [386] [make options]
    echo:
GOTO END

:END
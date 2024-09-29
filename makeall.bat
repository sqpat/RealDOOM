@echo off
REM full make script including clean and re-run of codegen.
set arg1=%1

IF "%1" == "" GOTO PRINT_EXIT
IF "%1" == "286" GOTO MAKE_286
IF "%1" == "8086" GOTO MAKE_8086
IF "%1" == "8088" GOTO MAKE_8086
IF "%1" == "186" GOTO MAKE_186
IF "%1" == "SCAMP" GOTO MAKE_SCAMP
IF "%1" == "SCAT" GOTO MAKE_SCAT
IF "%1" == "HT18" GOTO MAKE_HT18

GOTO PRINT_EXIT

:MAKE_8086
    wmake -f make16 clean
    wmake -f makecg clean
    wmake -f makecg
    codegen.exe
    wmake -f makecg clean
    wmake -f make16
GOTO END

:MAKE_186
    wmake -f make186 clean
    wmake -f makecg clean
    wmake -f makecg
    codegen.exe
    wmake -f makecg clean
    wmake -f make186
GOTO END

:MAKE_286
    wmake -f make286 clean
    wmake -f makecg clean
    wmake -f makecg
    codegen.exe
    wmake -f makecg clean
    wmake -f make286
GOTO END


:MAKE_SCAT
    wmake -f makescat clean
    wmake -f makecg clean
    wmake -f makecg
    codegen.exe
    wmake -f makecg clean
    wmake -f makescat
GOTO END



:MAKE_SCAMP
    wmake -f makesc clean
    wmake -f makecg clean
    wmake -f makecg
    codegen.exe
    wmake -f makecg clean
    wmake -f makesc
GOTO END



:MAKE_HT18
    wmake -f makeht clean
    wmake -f makecg clean
    wmake -f makecg
    codegen.exe
    wmake -f makecg clean
    wmake -f makeht
GOTO END


:PRINT_EXIT
    echo:
    echo Usage: makeall [286] [8086] [186] [SCAMP] [SCAT] [HT18]
    echo:
GOTO END

:END
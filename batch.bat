@echo off

REM Define variables for the output directory and input file
set OUTPUT_DIR=.\ths+grid-v2
set INPUT_FILE=.\templates\ths+grid-v2.lua

REM Create directories
mkdir %OUTPUT_DIR%\640x480
mkdir %OUTPUT_DIR%\640x640
mkdir %OUTPUT_DIR%\720x576

REM Run bcrg commands for each resolution and cx value
setlocal

for %%R in (640x480 640x640 720x576) do (
    if "%%R"=="640x480" (
        set "WIDTH=640"
        set "HEIGHT=480"
    ) else if "%%R"=="640x640" (
        set "WIDTH=640"
        set "HEIGHT=640"
    ) else if "%%R"=="720x576" (
        set "WIDTH=720"
        set "HEIGHT=576"
    )

    REM Enable delayed expansion to access loop variables correctly
    setlocal enabledelayedexpansion

    for %%C in (4.26 3.01 2.27 2.13 2.01 1.42) do (
        REM Display command about to run
        echo Running: bcrg -W !WIDTH! -H !HEIGHT! -cx %%C -o %OUTPUT_DIR%\%%R %INPUT_FILE%

        REM Execute the command
        bcrg -W !WIDTH! -H !HEIGHT! -cx %%C -o %OUTPUT_DIR%\%%R %INPUT_FILE%

        REM Display command completion message
        echo Command done for -W !WIDTH! -H !HEIGHT! -cx %%C -o %OUTPUT_DIR%\%%R
    )

    endlocal
)

endlocal

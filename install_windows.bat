@echo off
setlocal EnableDelayedExpansion
REM ==========================================================================
REM  Open Hyper AI (modified / ML build) - one-shot local installer for Windows
REM
REM  Symlinks Dota 2's  vscripts\bots  to THIS repo's  bots\  folder, so the game
REM  runs your modified scripts (with the ML policies) instead of the Workshop copy.
REM
REM  USAGE:
REM    1. Right-click this file  ->  "Run as administrator"
REM    2. If your Dota 2 is NOT on the C: default path, pass the vscripts path:
REM         install_windows.bat "D:\SteamLibrary\steamapps\common\dota 2 beta\game\dota\scripts\vscripts"
REM ==========================================================================

echo.
echo === Open Hyper AI (ML build) installer ===
echo.

REM --- must be admin (mklink requires it) ---
net session >nul 2>&1
if %errorlevel% neq 0 (
    echo [ERROR] Please RIGHT-CLICK this file and choose "Run as administrator".
    echo         mklink needs administrator rights.
    pause
    exit /b 1
)

REM --- source = the bots\ folder next to this script (strip trailing backslash) ---
set "REPO=%~dp0"
set "SRC=%REPO%bots"
if not exist "%SRC%\" (
    echo [ERROR] Cannot find "%SRC%".
    echo         Run this .bat from inside the repo (it must sit next to the bots\ folder).
    pause
    exit /b 1
)

REM --- destination vscripts path: arg %1 wins, else the common C: default ---
if not "%~1"=="" (
    set "VSCRIPTS=%~1"
) else (
    set "VSCRIPTS=C:\Program Files (x86)\Steam\steamapps\common\dota 2 beta\game\dota\scripts\vscripts"
)
set "DEST=%VSCRIPTS%\bots"

if not exist "%VSCRIPTS%\" (
    echo [ERROR] Dota 2 vscripts folder not found:
    echo           "%VSCRIPTS%"
    echo.
    echo         Find your "dota 2 beta" folder (Steam ^> Dota 2 ^> Manage ^> Browse local files,
    echo         then go up to ...\game\dota\scripts\vscripts) and pass it as an argument:
    echo           install_windows.bat "FULL\PATH\TO\vscripts"
    pause
    exit /b 1
)

echo Source (your modified scripts): "%SRC%"
echo Target (Dota 2 vscripts\bots) : "%DEST%"
echo.

REM --- remove an existing link or EMPTY bots folder; refuse to delete a real populated one ---
if exist "%DEST%" (
    rmdir "%DEST%" 2>nul
    if exist "%DEST%" (
        echo [ERROR] "%DEST%" already exists and is a real folder with files in it.
        echo         Rename or delete it yourself first ^(e.g. rename to bots_backup^), then re-run.
        pause
        exit /b 1
    )
    echo Removed previous bots link/folder.
)

REM --- create the directory symlink ---
mklink /d "%DEST%" "%SRC%"
if %errorlevel% neq 0 (
    echo [ERROR] mklink failed. Are you running as administrator?
    pause
    exit /b 1
)

echo.
echo === DONE ===
echo Your modified scripts are now linked into Dota 2.
echo Editing files in this repo will sync into the game automatically.
echo.
echo Next steps in Dota 2:
echo   1. (once) Subscribe to "Open Hyper AI" on the Steam Workshop so it appears in the menu.
echo   2. Create a Custom Lobby  ^|  Enable Cheats: ON  ^|  Server: LOCAL SERVER.
echo   3. Bot Script: "Open Hyper AI".  Add bots, Start.
echo   4. (optional) FretBots mode - in console:  sv_cheats 1; script_reload_code bots/fretbots
echo.
echo Bots installed correctly have names ending in ".OHA".
echo.
pause

@echo off
setlocal EnableExtensions

echo.
echo === Open Hyper AI (ML build) installer ===
echo.

REM --- must run as administrator (mklink needs it) ---
net session >nul 2>&1
if errorlevel 1 goto noadmin

REM --- source = the bots folder next to this script ---
set "SRC=%~dp0bots"
if not exist "%SRC%\" goto nosrc

REM --- destination vscripts: use arg 1 if given, else the C: default ---
if not "%~1"=="" goto haspath
set "VSCRIPTS=C:\Program Files (x86)\Steam\steamapps\common\dota 2 beta\game\dota\scripts\vscripts"
goto checkpath
:haspath
set "VSCRIPTS=%~1"
:checkpath

set "DEST=%VSCRIPTS%\bots"
if not exist "%VSCRIPTS%\" goto novscripts

echo Source (your modified scripts): "%SRC%"
echo Target (Dota 2 vscripts bots) : "%DEST%"
echo.

REM --- remove an existing link or EMPTY folder; never delete a populated real folder ---
if not exist "%DEST%" goto dolink
rmdir "%DEST%" 2>nul
if exist "%DEST%" goto realfolder
echo Removed previous bots link.

:dolink
mklink /d "%DEST%" "%SRC%"
if errorlevel 1 goto linkfail

echo.
echo === DONE ===
echo Your modified scripts are now linked into Dota 2.
echo Editing files in this repo will sync into the game automatically.
echo.
echo Next steps in Dota 2:
echo   1. First time: Subscribe to "Open Hyper AI" on the Steam Workshop.
echo   2. Custom Lobby - Enable Cheats: ON - Server: LOCAL SERVER.
echo   3. Bot Script: "Open Hyper AI". Add bots, Start.
echo   4. Optional FretBots, in console:  sv_cheats 1; script_reload_code bots/fretbots
echo.
echo Bots installed correctly have names ending in ".OHA".
echo.
goto end

:noadmin
echo [ERROR] Right-click this file and choose "Run as administrator".
goto end

:nosrc
echo [ERROR] Cannot find "%SRC%".
echo         Run this .bat from inside the cloned repo (next to the bots folder).
goto end

:novscripts
echo [ERROR] Dota 2 vscripts folder not found:
echo           "%VSCRIPTS%"
echo         Pass the correct path as an argument, for example:
echo           install_windows.bat "D:\SteamLibrary\steamapps\common\dota 2 beta\game\dota\scripts\vscripts"
goto end

:realfolder
echo [ERROR] "%DEST%" is a real folder with files in it.
echo         Rename it (e.g. to bots_backup) or delete it, then run this again.
goto end

:linkfail
echo [ERROR] mklink failed. Make sure you are running as administrator.
goto end

:end
echo.
pause

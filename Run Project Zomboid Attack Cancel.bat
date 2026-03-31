@echo off
setlocal
set "DIR=%~dp0"
set "AHK=%DIR%AutoHotkey64.exe"
if exist "%AHK%" goto run

set "AHK=%LocalAppData%\Programs\AutoHotkey\v2\AutoHotkey64.exe"
if exist "%AHK%" goto run

set "AHK=%ProgramFiles%\AutoHotkey\v2\AutoHotkey64.exe"
if exist "%AHK%" goto run

set "AHK=%ProgramFiles(x86)%\AutoHotkey\v2\AutoHotkey64.exe"
if exist "%AHK%" goto run

echo AutoHotkey64.exe was not found.
echo Use the portable package, or install AutoHotkey v2.
pause
exit /b 1

:run
start "" "%AHK%" "%DIR%project-zomboid-attack-cancel.ahk"

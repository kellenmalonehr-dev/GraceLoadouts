@echo off
:: Puts Grace Loadouts into the ELDEN RING\Game folder, for playing without Mod Engine
:: (Seamless Co-op's own launcher, or the game started offline). Run again after updating.
cd /d "%~dp0"
powershell -NoProfile -ExecutionPolicy Bypass -File ".\GraceLoadouts-gamefolder.ps1" -Action install %*
pause

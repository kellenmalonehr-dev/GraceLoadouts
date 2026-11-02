@echo off
:: Takes Grace Loadouts back out of the ELDEN RING\Game folder. Saves and saved loadouts are kept.
cd /d "%~dp0"
powershell -NoProfile -ExecutionPolicy Bypass -File ".\GraceLoadouts-gamefolder.ps1" -Action uninstall %*
pause

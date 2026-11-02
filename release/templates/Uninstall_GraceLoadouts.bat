@echo off
:: Removes Grace Loadouts from every profile Install_GraceLoadouts.bat added it to
:: (or from the .me3 files dragged onto this file).
cd /d "%~dp0"
powershell -NoProfile -ExecutionPolicy Bypass -File ".\GraceLoadouts-setup.ps1" -Action uninstall %*
pause

@echo off
:: Adds Grace Loadouts to Mod Engine 3 profiles (Convergence's, Seeker's Compass's or your own),
:: so you keep launching the way you already do. You can also drag .me3 files onto this file.
:: Run again after moving this folder or updating a mod in the profile.
cd /d "%~dp0"
powershell -NoProfile -ExecutionPolicy Bypass -File ".\GraceLoadouts-setup.ps1" -Action install %*
pause

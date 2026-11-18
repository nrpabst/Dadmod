@echo off
rem Removes dadmod, puts the game's own binkw32.dll back, then deletes this dadmod-install folder. Your dadmod settings stay.
powershell -NoProfile -ExecutionPolicy Bypass -File "%~dp0installer\dadmod.ps1" uninstall %*
if errorlevel 1 pause

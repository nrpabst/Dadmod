@echo off
rem Puts back any dadmod file or extra level that went missing (for example a map deleted from the custom maps folder). Close the game first.
powershell -NoProfile -ExecutionPolicy Bypass -File "%~dp0installer\dadmod.ps1" repair %*
pause

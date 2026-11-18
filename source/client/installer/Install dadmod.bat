@echo off
rem Installs dadmod into your THUG Pro folder (plain THUG Pro or Kali Mod). Close the game first.
powershell -NoProfile -ExecutionPolicy Bypass -File "%~dp0installer\dadmod.ps1" install %*
pause

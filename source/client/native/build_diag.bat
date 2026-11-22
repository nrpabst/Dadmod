@echo off
rem DIAGNOSTIC client loader DLL (DADMOD_DIAG): logs every file call and its Windows error to dadmod\diag.log, dadmod\diag_rel.log and %LOCALAPPDATA%\dadmod_diag\diag.log. Never part of a release.
call "C:\Program Files\Microsoft Visual Studio\18\Community\VC\Auxiliary\Build\vcvarsall.bat" x86 >nul
cd /d "%~dp0"
if not exist diag mkdir diag
cl /nologo /DDADMOD_DIAG /Fodiag\ /O2 /MT /LD /EHsc /W3 /std:c++17 loader.cpp /link /DEF:binkw32.def /OUT:diag\binkw32.dll user32.lib kernel32.lib d3d9.lib dinput8.lib dxguid.lib setupapi.lib hid.lib advapi32.lib

@echo off
rem Client loader DLL with MSVC (same compiler and flags as native\thugrecomp). Run by make_client.py on Windows.
call "C:\Program Files\Microsoft Visual Studio\18\Community\VC\Auxiliary\Build\vcvarsall.bat" x86 >nul
cd /d "%~dp0"
cl /nologo /O2 /MT /LD /EHsc /W3 /std:c++17 loader.cpp /link /DEF:binkw32.def /OUT:binkw32.dll user32.lib kernel32.lib d3d9.lib dinput8.lib dxguid.lib setupapi.lib hid.lib

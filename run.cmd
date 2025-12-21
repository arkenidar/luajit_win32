@echo off
REM run.cmd
REM Windows launcher for LuaJIT Win32 GUI application

echo ================================================
echo   LuaJIT Win32 GUI Application Launcher
echo ================================================
echo.

REM Check if luajit.exe exists
if not exist luajit.exe (
    echo ERROR: luajit.exe not found!
    echo.
    echo Please ensure luajit.exe is in the current directory.
    echo.
    pause
    exit /b 1
)

REM Check if main.lua exists
if not exist main.lua (
    echo ERROR: main.lua not found!
    echo.
    echo Please ensure main.lua is in the current directory.
    echo.
    pause
    exit /b 1
)

echo Detected: Windows
echo Running: luajit.exe main.lua
echo.

REM Run the application
luajit.exe main.lua

REM Capture exit code
set EXIT_CODE=%ERRORLEVEL%

echo.
echo Application exited with code: %EXIT_CODE%

REM Optional: Uncomment to pause (useful for debugging)
REM pause

exit /b %EXIT_CODE%

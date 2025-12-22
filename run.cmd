@echo off
REM run.cmd
REM Windows launcher for LuaJIT Win32 GUI application
REM This launcher defaults to Win32 backend (works on both native Windows and Wine)

echo ================================================
echo   LuaJIT Win32 GUI Application Launcher
echo ================================================
echo.

REM Check if --backend argument already provided
set BACKEND_SPECIFIED=0
for %%A in (%*) do (
    echo %%A | findstr /C:"--backend" >nul
    if not errorlevel 1 set BACKEND_SPECIFIED=1
)

REM If no backend specified, default to win32
set EXTRA_ARGS=
if %BACKEND_SPECIFIED%==0 (
    set EXTRA_ARGS=--backend=win32
    echo Default backend: win32
    echo.
)

REM Display arguments if provided
if not "%*"=="" (
    echo User arguments: %*
    echo.
)

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
echo Running: luajit.exe main.lua %EXTRA_ARGS% %*
echo.

REM Run the application with win32 backend (default) + user arguments
luajit.exe main.lua %EXTRA_ARGS% %*

REM Capture exit code
set EXIT_CODE=%ERRORLEVEL%

echo.
echo Application exited with code: %EXIT_CODE%

REM Optional: Uncomment to pause (useful for debugging)
REM pause

exit /b %EXIT_CODE%

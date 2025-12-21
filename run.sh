#!/bin/bash
# run.sh
# Cross-platform launcher for LuaJIT Win32 GUI application

echo "LuaJIT Win32 GUI Application Launcher"
echo "======================================"
echo ""

# Detect operating system
if [[ "$OSTYPE" == "msys" || "$OSTYPE" == "cygwin" || "$OSTYPE" == "win32" ]]; then
    # Running on Windows
    echo "Detected: Windows"
    echo "Running: luajit.exe main.lua"
    echo ""
    ./luajit.exe main.lua

elif [[ "$OSTYPE" == "linux-gnu"* ]]; then
    # Running on Linux, use Wine
    echo "Detected: Linux"

    # Check if Wine is installed
    if ! command -v wine &> /dev/null; then
        echo "ERROR: Wine is not installed!"
        echo ""
        echo "Please install Wine to run Windows applications on Linux:"
        echo "  sudo apt-get install wine"
        echo ""
        exit 1
    fi

    # Display Wine version
    WINE_VERSION=$(wine --version)
    echo "Wine version: $WINE_VERSION"
    echo "Running: wine luajit.exe main.lua"
    echo ""

    # Run LuaJIT with Wine
    wine luajit.exe main.lua

else
    # Unsupported operating system
    echo "ERROR: Unsupported operating system: $OSTYPE"
    echo ""
    echo "This application requires Windows or Linux with Wine."
    echo ""
    exit 1
fi

# Capture exit code
EXIT_CODE=$?

echo ""
echo "Application exited with code: $EXIT_CODE"

exit $EXIT_CODE

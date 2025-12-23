# Debian/Linux Fixes Applied

## Issues Fixed

### 1. Missing GObject Library
**Problem**: Pango FFI couldn't find `libgobject-2.0-0`
**Solution**: Updated DEBIAN_SETUP.md to include `libgobject-2.0-0` in installation requirements

### 2. Library Naming Variations
**Problem**: Linux uses different library naming than Windows
- Windows: `libpango-1.0-0.dll`
- Linux: `libpango-1.0.so.0`

**Solution**: Updated Pango FFI loader to try multiple naming conventions:
```
libpango-1.0-0.dll (Windows)
pango-1.0 (Linux pkg-config)
libpango-1.0 (Linux fallback)
libpango-1.0.so.0 (Linux versioned)
```

### 3. SDL2 FFI Incomplete Declarations
**Problem**: Missing renderer functions and constants needed for demo
**Solution**: Added to `lib/ffi/sdl2_ffi.lua`:
- SDL_Renderer type and functions (CreateRenderer, DestroyRenderer, etc.)
- SDL_Texture type and functions (CreateTexture, UpdateTexture, RenderCopy, etc.)
- Render functions (SetRenderDrawColor, RenderClear, RenderPresent, RenderFillRect)
- Texture access and pixel format enums
- Key symbol constants (SDLK_ESCAPE, SDLK_LEFT, SDLK_RIGHT, etc.)

### 4. Pango FFI Missing Wrapper Functions
**Problem**: text_editor.lua expected wrapper functions that call Pango C library
**Solution**: Added wrapper functions to `lib/ffi/pango_ffi.lua`:
- `pango_cairo_create_layout()`
- `pango_layout_get_context()`
- `pango_layout_unref()`
- `pango_layout_set_font_description_str()`
- `pango_layout_set_text()`
- `pango_cairo_show_layout()`

## Updated Files

1. **DEBIAN_SETUP.md**
   - Added `libgobject-2.0-0` to main installation
   - Added gobject check to verification section
   - Updated Pango error troubleshooting
   - Updated distribution requirements

2. **lib/ffi/pango_ffi.lua**
   - Added fallback library loading for GObject versions
   - Added wrapper functions for text editor compatibility

3. **lib/ffi/sdl2_ffi.lua**
   - Added complete renderer API declarations
   - Added SDL_Texture type and functions
   - Added SDL_Rect structure
   - Added key symbol enums
   - Added pixel format and texture access enums

## Installation

Updated command to install all required dependencies on Debian/Ubuntu:

```bash
sudo apt install libsdl2-2.0-0 libcairo2 libpango-1.0-0 libpangocairo-1.0-0 \
                 libgobject-2.0-0 libfontconfig1
```

## Verification

The text editor now loads successfully on Linux:

```bash
$ luajit demo_text_editor.lua
Text Editor initialized successfully!
Window size: 1024x700
Use Ctrl+Z to undo, Ctrl+Y to redo, ESC to quit
```

## Cross-Platform Compatibility

The FFI bindings now work on both:
- **Windows (MSYS2)**: Using DLL files from mingw64
- **Linux (Debian/Ubuntu)**: Using native shared libraries

The same code runs on both platforms without modification.

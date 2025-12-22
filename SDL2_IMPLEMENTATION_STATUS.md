# SDL2 Backend Implementation Status

## Overview

This document tracks the progress of implementing SDL2 and SDL3 backends with Cairo graphics support for the LuaJIT Win32 GUI application.

## Current Status: Phase 2 Complete ✅

### Completed Phases

#### ✅ Phase 1: Cairo FFI Bindings
**Status:** Complete and tested

**Files created:**
- [lib/ffi/cairo_ffi.lua](lib/ffi/cairo_ffi.lua) - Cairo FFI bindings for 2D vector graphics
- [test_cairo.lua](test_cairo.lua) - Verification test (all 8 tests pass)

**Features:**
- Surface management (create, flush, destroy)
- Context management
- Drawing operations (rectangles, arcs, paths, fills, strokes)
- Text rendering with measurement
- Library loading with Windows fallback (cairo → libcairo-2)

**Test Results:**
```bash
$ ./luajit.exe test_cairo.lua
=== Cairo FFI Test ===
✓ All tests passed!
Cairo is ready for SDL2 integration.
```

#### ✅ Phase 2: SDL Base Abstraction Layer
**Status:** Complete and tested

**Files created:**
- [lib/ffi/sdl2_ffi.lua](lib/ffi/sdl2_ffi.lua) - SDL2 FFI bindings (window, surface, events, OpenGL, timer)
- [lib/sdl_base/sdl_api.lua](lib/sdl_base/sdl_api.lua) - Unified SDL2/SDL3 abstraction layer
- [test_sdl2.lua](test_sdl2.lua) - Verification test (all 7 tests pass)

**Features:**
- Window creation and management
- Surface access (pixels, dimensions, pitch)
- Event polling (quit, window, keyboard, mouse)
- OpenGL context support
- Timer functions (SDL_Delay)
- Version detection (SDL2/SDL3)

**Test Results:**
```bash
$ ./luajit.exe test_sdl2.lua
=== SDL2 Base Abstraction Test ===
✓ All tests passed!
SDL2 is ready for backend implementation (Phase 3).
```

### In Progress

#### ⏳ Phase 3: SDL2 Backend Core with Cairo Integration
**Status:** Stub created, not yet functional

**Files:**
- [lib/backend/sdl2_backend.lua](lib/backend/sdl2_backend.lua) - Stub with helpful error message

**What's needed:**
- Window creation with Cairo surface integration (zero-copy pattern)
- Event loop with comprehensive input handling
- Window resize handling (recreate Cairo surface)
- Control management system
- Cairo rendering loop

**Reference implementation:**
See plan file [.claude/plans/woolly-stirring-fox.md](.claude/plans/woolly-stirring-fox.md) Phase 3 for detailed implementation guide.

### Upcoming Phases

#### ⏳ Phase 4: Cairo-Based Custom Widgets
- Button widget with rounded corners
- Listbox widget with scrolling
- Edit widget with cursor rendering
- Label widget
- Base widget system with event handling

#### ⏳ Phase 5: Flexible 3D Integration (Compositor Architecture)
- Software rendering mode (Cairo → SDL surface, zero-copy)
- Hardware rendering mode (Cairo → GPU texture)
- Embedded 3D viewports
- GPU backend abstraction (OpenGL, Vulkan, OpenGL ES)

#### ⏳ Phase 6: Layout System Integration
- Remove Win32 dependencies from layout.lua
- Make layout manager backend-agnostic

#### ⏳ Phase 7: SDL3 Backend
- SDL3 FFI bindings
- SDL3-specific abstraction layer
- Reuse all widgets from SDL2

#### ⏳ Phase 8: Testing & Integration
- Cross-platform testing
- Performance benchmarking
- Documentation

## Running the Application

### Current Default (Win32 Backend)
The application defaults to Win32 backend while SDL2 is in development:

```bash
./luajit.exe main.lua
# or
./run.sh
```

### Explicitly Specify Backend
You can explicitly choose a backend:

```bash
# Win32 (working)
./luajit.exe main.lua --backend=win32

# SDL2 (not yet implemented - shows helpful error)
./luajit.exe main.lua --backend=sdl2
```

### Environment Variable
```bash
set PLATFORM_BACKEND=win32
./luajit.exe main.lua
```

## Testing Individual Components

### Test Cairo Graphics
```bash
./luajit.exe test_cairo.lua
```
This creates a 400x300 image with:
- White background
- Blue rounded rectangle
- "Cairo Works!" text centered

### Test SDL2 Base Layer
```bash
./luajit.exe test_sdl2.lua
```
This creates a 640x480 window with:
- Blue background
- Event handling for 3 seconds
- Window resize support
- Mouse and keyboard events

## Architecture Overview

```
Application (app.lua, main.lua)
         ↓
Platform Layer (platform_layer.lua)
         ↓
    ┌────┴────┬────────┐
Win32Backend  SDL2Backend  SDL3Backend
    ↓            ↓            ↓
Win32 FFI    SDL Base Abstraction ← Shared by both
             ↓            ↓
         SDL2 FFI    SDL3 FFI
             ↓            ↓
         SDL2.dll    SDL3.dll
             ↓            ↓
         Cairo FFI (libcairo-2.dll / libcairo.so)
                   ↓
        2D Vector Graphics Rendering
```

## Key Technical Decisions

1. **Cairo for 2D rendering**: Provides SVG-like vector graphics with anti-aliasing, text rendering, and complex shapes
2. **Zero-copy integration**: Cairo draws directly into SDL surface pixels (CAIRO_FORMAT_ARGB32)
3. **Unified SDL abstraction**: Single codebase for SDL2 and SDL3 backends
4. **Flexible rendering modes**:
   - Software mode: Cairo → SDL surface (zero-copy, pure 2D)
   - Hardware mode: Cairo → GPU texture (compositor, 3D integration)

## File Structure

```
lib/
├── platform_layer.lua          Platform abstraction facade
├── backend/
│   ├── win32_backend.lua       [WORKING] Win32 implementation
│   ├── sdl2_backend.lua        [STUB] SDL2 implementation
│   └── sdl3_backend.lua        [TODO] SDL3 implementation
├── ffi/
│   ├── win32_ffi.lua           Win32 FFI
│   ├── opengl_ffi.lua          OpenGL FFI
│   ├── cairo_ffi.lua           [NEW] Cairo FFI bindings ✅
│   └── sdl2_ffi.lua            [NEW] SDL2 FFI bindings ✅
└── sdl_base/                   [NEW] SDL abstraction layer ✅
    └── sdl_api.lua             SDL2/SDL3 version abstraction

test_cairo.lua                  [NEW] Cairo verification test ✅
test_sdl2.lua                   [NEW] SDL2 verification test ✅
```

## Next Steps

To continue Phase 3 (SDL2 Backend Core):

1. Implement window creation with Cairo integration in [lib/backend/sdl2_backend.lua](lib/backend/sdl2_backend.lua)
2. Create SDLWindow wrapper class in `lib/backend/sdl_window.lua`
3. Implement event loop with mouse/keyboard handling
4. Add window resize support (recreate Cairo surface on resize)
5. Test with simple button rendering

See [.claude/plans/woolly-stirring-fox.md](.claude/plans/woolly-stirring-fox.md) for detailed implementation guide.

## Dependencies

**Required libraries:**
- SDL2.dll (for SDL2 backend)
- libcairo-2.dll or cairo.dll (for 2D graphics)
- OpenGL (for hardware compositor mode - Phase 5)

**Current status:**
- ✅ Cairo library loaded successfully
- ✅ SDL2 library loaded successfully
- ⏳ Integration pending (Phase 3)

## Notes

- The Win32 backend remains fully functional and is the default
- All foundational SDL2 components are tested and working
- Phase 3 implementation can proceed with confidence - FFI layers are solid
- Both test scripts pass 100% of tests

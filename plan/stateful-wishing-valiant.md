# Win32-to-SDL Multi-Backend Porting Layer

## Overview

Add SDL2 and SDL3 support to the LuaJIT Win32 application through a platform abstraction layer, enabling:
- **Triple backend support**: Runtime selection between Win32 (Windows-native), SDL2 (stable cross-platform), and SDL3 (modern cross-platform)
- **Cross-platform capability**: Run on Windows, Linux, and macOS via SDL backends
- **Custom SDL GUI controls**: Pure SDL2D rendering (no OpenGL for GUI) for maximum portability
- **Maintained Win32 functionality**: Existing Win32 backend remains unchanged
- **OpenGL rendering**: Works on all backends (WGL on Win32, SDL_GL on SDL2/SDL3)

## Architecture

### Platform Abstraction Layer

```
Application Layer (app.lua)
         ↓
Platform Layer (platform_layer.lua) ← Unified API
         ↓
    ┌────┴────┬────────┐
Win32Backend  SDL2Backend  SDL3Backend
    ↓            ↓            ↓
Win32 FFI    SDL2 FFI    SDL3 FFI
             + Custom    + Custom
             Controls    Controls
```

**Backend Selection Priority:**
1. Command-line: `luajit main.lua --backend=sdl2` or `--backend=sdl3` or `--backend=win32`
2. Environment variable: `PLATFORM_BACKEND=sdl2` (or `sdl3` or `win32`)
3. Config file: `config.lua` with `backend = "sdl2"` (or `"sdl3"` or `"win32"`)
4. Platform default: Windows = win32, Linux/macOS = sdl2

### SDL2 vs SDL3 Backend Rationale

**Why Support Both SDL2 and SDL3?**

- **SDL2**: Mature, stable (2013), extensive documentation, wide platform support, proven in production
- **SDL3**: Modern API (2024), improved GPU acceleration, better error handling, future-focused
- **User Choice**: Let users pick based on their needs (stability vs latest features)

**Shared Components:**
- Custom GUI controls (`lib/controls/`) work with both SDL2 and SDL3 (same SDL_Renderer API)
- Event handling logic is similar (minor API differences handled in backend)
- OpenGL context creation slightly different but both use SDL_GL_*

**Key SDL3 API Differences:**
- Namespaced functions: `SDL_CreateWindow()` → `SDL3_CreateWindow()`
- Properties API: More flexible window/renderer configuration
- Improved error handling: Better error messages
- GPU API: New GPU rendering path (optional, we'll use classic renderer)

### Key Design Decisions

1. **Event Handling**: Callback-based API (Win32-native), SDL backends translate polling to callbacks
2. **GUI Controls**: SDL backends use custom widgets (Button, Listbox, Edit, Label) with pure SDL2D rendering - **shared between SDL2 and SDL3**
3. **Text Rendering**: Bitmap font for MVP (simple, no dependencies), SDL_ttf for future enhancement
4. **Layout System**: Backend-agnostic calculations, platform-specific positioning
5. **OpenGL Context**: Backend-specific creation (WGL, SDL2_GL, SDL3_GL), shared rendering code
6. **Code Reuse**: SDL2 and SDL3 backends share 90% of code (controls, event translation logic)

## Critical Files to Create/Modify

### New Files

**Platform Layer:**
- `lib/platform_layer.lua` - Abstraction facade with backend detection and dynamic loading

**SDL2 Backend:**
- `lib/ffi/sdl2_ffi.lua` - SDL2 FFI bindings (window, event, renderer, OpenGL, timer)
- `lib/backend/sdl2_backend.lua` - SDL2 implementation of platform API

**SDL3 Backend:**
- `lib/ffi/sdl3_ffi.lua` - SDL3 FFI bindings (updated API for SDL3)
- `lib/backend/sdl3_backend.lua` - SDL3 implementation of platform API
- `lib/controls/sdl_controls.lua` - Base Widget class + ControlManager
- `lib/controls/sdl_button.lua` - SDL button widget
- `lib/controls/sdl_listbox.lua` - SDL listbox widget (scrollable, selection)
- `lib/controls/sdl_edit.lua` - SDL text input widget (cursor, selection)
- `lib/controls/sdl_label.lua` - SDL label widget
- `lib/controls/sdl_theme.lua` - Color scheme for SDL controls

**Win32 Backend:**
- `lib/backend/win32_backend.lua` - Win32 implementation wrapping existing gui.lua logic
- `lib/ffi/win32_ffi.lua` - Move from `lib/win32_ffi.lua`
- `lib/ffi/opengl_ffi.lua` - Move from `lib/opengl_ffi.lua`, remove WGL-specific code

**Configuration:**
- `config.lua` - Optional config file for backend selection

### Modified Files

**Application Layer:**
- `main.lua` - Use platform_layer.init() instead of direct gui require
- `lib/app.lua` - Use platform API instead of Win32 API directly
  - Constructor takes platform reference
  - Control creation via platform.create_button/listbox/edit/label
  - Control manipulation via platform.set_control_text/get_control_text/etc
  - Event handlers stored in table passed to platform.run_event_loop

**Layout System:**
- `lib/layout.lua` - Use platform.set_control_position instead of Win32 SetWindowPos
  - LayoutManager constructor takes platform reference
  - LayoutItem stores control_handle (not hwnd)
  - apply() uses platform API for positioning

**OpenGL Rendering:**
- `lib/gl_renderer.lua` - Accept platform-provided GL context
  - Constructor takes gl_context instead of hwnd
  - swap_buffers via platform API
  - cleanup via platform.destroy_opengl_context

## Platform API Interface

```lua
-- Window management
create_window(title, width, height, flags) -> window_handle
destroy_window(window_handle)
get_window_size(window_handle) -> width, height
set_window_title(window_handle, title)

-- Event loop
run_event_loop(window_handle, event_handlers) -> exit_code
-- event_handlers table: on_create, on_destroy, on_button_click,
--   on_listbox_select, on_listbox_doubleclick, on_timer, on_resize, on_close

-- Control creation
create_button(window, x, y, w, h, text) -> control_id
create_listbox(window, x, y, w, h) -> control_id
create_edit(window, x, y, w, h, text) -> control_id
create_label(window, x, y, w, h, text) -> control_id
create_opengl_view(window, x, y, w, h) -> control_id

-- Control manipulation
set_control_text(control_id, text)
get_control_text(control_id) -> text
enable_control(control_id, enabled)
set_control_position(control_id, x, y, w, h)

-- Listbox operations
listbox_add_item(control_id, text) -> index
listbox_delete_item(control_id, index)
listbox_get_selection(control_id) -> index
listbox_set_selection(control_id, index)
listbox_get_item_text(control_id, index) -> text
listbox_clear(control_id)
listbox_get_count(control_id) -> count

-- OpenGL context
create_opengl_context(window_or_control) -> gl_context
make_context_current(gl_context)
swap_buffers(gl_context)
destroy_opengl_context(gl_context)

-- Timer
set_timer(window, timer_id, interval_ms, callback)
kill_timer(window, timer_id)

-- Utility
get_backend_name() -> "win32" | "sdl"
show_message_box(window, title, message, type) -> button_clicked
```

## SDL Custom Controls Architecture

### Base Widget Class
- Properties: x, y, width, height, visible, enabled, focused, hovered, pressed
- Methods: contains_point, handle_mouse_down/up/move, handle_key_down, handle_text_input, render
- State management in Lua tables

### ControlManager
- Manages all widgets in a window
- Dispatches SDL events to appropriate widgets
- Handles focus management
- Renders all widgets each frame

### Widget Implementations
- **Button**: Clickable with hover/pressed states
- **Listbox**: Scrollable list with selection, keyboard navigation, double-click
- **Edit**: Text input with cursor, selection, clipboard support
- **Label**: Static text display

### Theme System
- Centralized color definitions (button_bg, button_border, listbox_selection, etc.)
- State-based colors (normal, hovered, pressed, disabled, focused)

## Implementation Phases

### Phase 1: Foundation (Week 1-2)
- Create directory structure (backend/, ffi/, controls/)
- Move win32_ffi.lua and opengl_ffi.lua to ffi/
- Create platform_layer.lua with backend detection
- Create win32_backend.lua wrapping existing gui.lua
- Modify main.lua to use platform layer
- **Goal**: Existing Win32 app works via abstraction layer

### Phase 2: SDL FFI and Window (Week 3)
- Create sdl_ffi.lua with SDL2 FFI bindings
- Implement SDLBackend:create_window() and run_event_loop()
- Test empty SDL window with `--backend=sdl`
- **Goal**: SDL window opens, resizes, closes properly

### Phase 3: SDL Custom Controls (Week 4-5)
- Create sdl_controls.lua (Widget, ControlManager)
- Create sdl_theme.lua
- Implement sdl_button.lua, sdl_label.lua, sdl_edit.lua, sdl_listbox.lua
- Test each control in isolation
- **Goal**: All SDL controls render and respond to input

### Phase 4: Text Rendering (Week 6)
- Implement bitmap font solution
- Add text rendering to all SDL controls
- **Goal**: Control text is visible and readable

### Phase 5: Layout Integration (Week 7)
- Modify layout.lua to use platform abstraction
- Implement set_control_position in both backends
- Test layout with both backends
- **Goal**: Layout system works on both backends

### Phase 6: OpenGL Integration (Week 8)
- Split OpenGL context creation to backends
- Modify gl_renderer.lua to accept backend GL context
- Implement create_opengl_context in Win32Backend (WGL) and SDLBackend (SDL_GL)
- **Goal**: 3D cube renders at 60 FPS on both backends

### Phase 7: Feature Parity (Week 9)
- Test all TodoApp features with SDL backend
- Fix SDL-specific bugs
- **Goal**: Full app functionality works identically on both backends

### Phase 8: Cross-Platform Testing (Week 10)
- Test SDL backend on Linux
- Test SDL backend on macOS (if available)
- Fix platform-specific issues
- **Goal**: App runs on all platforms

### Phase 9: Polish and Documentation (Week 11)
- Error handling and validation
- Developer and user documentation
- Performance optimization
- **Goal**: Production-ready code

## Key Challenges and Solutions

### Challenge: SDL has no native GUI controls
**Solution**: Implement custom widgets using pure SDL2D rendering (SDL_Renderer)

### Challenge: Win32 callbacks vs SDL polling
**Solution**: SDL backend translates SDL_PollEvent to callback-based API in event loop

### Challenge: Text rendering in SDL
**Solution**: Bitmap font for MVP (simple), SDL_ttf for future (better quality)

### Challenge: Cross-platform DLL loading
**Solution**: Platform detection in sdl2_ffi.lua and sdl3_ffi.lua
- SDL2: Windows: SDL2.dll, Linux: libSDL2-2.0.so.0, macOS: SDL2.framework/SDL2
- SDL3: Windows: SDL3.dll, Linux: libSDL3.so.0, macOS: SDL3.framework/SDL3

### Challenge: Layout system uses Win32 SetWindowPos
**Solution**: Abstract to platform.set_control_position, backends implement appropriately

## Dependencies

**Windows (Win32 Backend):**
- LuaJIT 2.1+
- No runtime dependencies (uses system DLLs)

**Windows/Linux/macOS (SDL2 Backend):**
- LuaJIT 2.1+
- SDL2 library (SDL2.dll / libSDL2-2.0.so.0 / SDL2.framework)
- **Install:**
  - Linux (Ubuntu/Debian): `apt install libsdl2-2.0-0 libsdl2-dev`
  - macOS: `brew install sdl2`
  - Windows (MSYS2/MinGW64): `pacman -S mingw-w64-x86_64-SDL2`
  - Windows (binary): Download from https://github.com/libsdl-org/SDL/releases

**Windows/Linux/macOS (SDL3 Backend):**
- LuaJIT 2.1+
- SDL3 library (SDL3.dll / libSDL3.so.0 / SDL3.framework)
- **Install:**
  - Linux (Debian 13 "Trixie"): `apt install libsdl3-0 libsdl3-dev`
    - Packages: https://packages.debian.org/trixie/libsdl3-0
    - Dev: https://packages.debian.org/trixie/libdevel/libsdl3-dev
  - Windows (MSYS2/MinGW64): `pacman -S mingw-w64-x86_64-sdl3`
  - macOS: `brew install sdl3` (may need --HEAD for latest)
  - Other platforms: Build from source https://github.com/libsdl-org/SDL

## Testing Strategy

1. **Unit Testing**: Test each backend component in isolation
2. **Integration Testing**: Test complete app workflow on all three backends
3. **Regression Testing**: Win32 backend matches current implementation behavior
4. **Cross-Platform Testing**: SDL2 and SDL3 backends on Windows, Linux, macOS
5. **Backend Comparison**: Verify SDL2 and SDL3 backends produce identical behavior

## Expected Outcomes

✅ **Triple backend support**: Users choose Win32, SDL2, or SDL3 at runtime
✅ **Cross-platform**: App runs on Windows (Win32/SDL2/SDL3), Linux (SDL2/SDL3), macOS (SDL2/SDL3)
✅ **No regression**: Existing Win32 functionality unchanged
✅ **Portable GUI**: SDL controls work everywhere (pure SDL2D, no OpenGL) - shared between SDL2 and SDL3
✅ **Shared OpenGL**: 3D rendering works on all three backends
✅ **Maintainable**: Clear separation between platform and application code
✅ **Future-proof**: SDL3 support ready for when it becomes mainstream
✅ **Stable option**: SDL2 available for production use today

# Cairo + SDL2 Demos - Ready to Run!

All demos now work perfectly after FFI export fixes.

## Interactive Demos (Event Loop)

### 1. demo_cairo_simple.lua - Full Showcase ⭐
```bash
./luajit.exe demo_cairo_simple.lua
```
**Features:**
- 8 buttons (3 large + 5 color palette)
- 7-item listbox with selection
- 6 info/status labels
- Mouse hover effects
- Click events
- Total: 21 controls, fully interactive

### 2. test_event_loop.lua - Simple Interaction
```bash
./luajit.exe test_event_loop.lua
```
**Features:**
- 1 clickable button
- Basic event loop test
- Clean and minimal

### 3. demo_cairo_buttons_only.lua - Many Buttons
```bash
./luajit.exe demo_cairo_buttons_only.lua
```
**Features:**
- 8 buttons in a row
- 5 labels
- Tests rendering many controls

## Single-Shot Rendering (No Event Loop)

### 4. demo_cairo_no_loop.lua - Static Display ⭐
```bash
./luajit.exe demo_cairo_no_loop.lua
```
**Features:**
- Renders once and exits
- Shows all Cairo rendering works
- Perfect for screenshots/testing
- 6 buttons + 3 labels + listbox

## Technical Tests

### 5. test_simple_render.lua - Minimal Test
```bash
./luajit.exe test_simple_render.lua
```
Single button, single render - proves basic functionality.

### 6. test_2buttons.lua - Stability Test
```bash
./luajit.exe test_2buttons.lua
```
3 buttons in event loop - runs indefinitely.

## What Each Demo Showcases

**Cairo Vector Graphics:**
- ✓ Anti-aliased rounded rectangles
- ✓ Smooth text rendering
- ✓ Pixel-perfect layouts
- ✓ Button hover states
- ✓ Listbox item selection
- ✓ 60 FPS continuous rendering

**SDL2 Backend:**
- ✓ Event loop handling
- ✓ Mouse input
- ✓ Window management
- ✓ Surface rendering

**All running on pure LuaJIT + FFI!**

# LuaJIT Win32 GUI Application

A demonstration of using LuaJIT FFI (Foreign Function Interface) to create native Win32 GUI applications directly from Lua, without requiring C compilation. This project implements an interactive To-Do List manager with full CRUD operations.

## Features

- **Pure Lua Implementation**: No C compilation needed - uses LuaJIT FFI to call Win32 APIs directly
- **Cross-Platform**: Runs on Windows natively and on Linux via Wine
- **Interactive GUI**: Full-featured task manager with buttons, listbox, and text input
- **Modular Architecture**: Clean separation between FFI bindings, GUI abstraction, and application logic
- **Event-Driven**: Handles button clicks, listbox selection, and keyboard input
- **Unicode Support**: Proper UTF-8 to UTF-16 conversion for international text

## Application Features

- Add new tasks
- Edit existing tasks (double-click or use Edit button)
- Delete selected tasks
- Clear all tasks (with confirmation dialog)
- Automatic button state management
- Sample tasks included for demonstration

## Architecture

```
luajit_win32/
├── main.lua                 # Application entry point
├── run.sh                   # Cross-platform launcher (Linux/Unix)
├── run.cmd                  # Windows batch launcher
├── lib/
│   ├── win32_ffi.lua       # FFI bindings for Win32 APIs
│   ├── gui.lua             # GUI abstraction layer
│   └── app.lua             # To-Do List application logic
├── luajit.exe              # LuaJIT executable for Windows
├── lua51.dll               # LuaJIT library
└── README.md               # This file
```

### Module Overview

#### lib/win32_ffi.lua
- Low-level FFI bindings to Win32 APIs (user32.dll, kernel32.dll)
- Type definitions for Windows structures (WNDCLASSW, MSG, RECT)
- Constants for window styles, messages, and controls
- Unicode string conversion helpers (UTF-8 ↔ UTF-16)
- Callback management to prevent garbage collection

#### lib/gui.lua
- High-level Lua-friendly GUI API
- Window class for creating and managing windows
- Control creation helpers (buttons, listbox, edit, labels)
- Message routing and event handling
- Listbox wrapper with CRUD operations

#### lib/app.lua
- To-Do List application business logic
- Task management (add, delete, edit, clear)
- UI synchronization and state management
- Event handlers for user interactions

## Prerequisites

### On Windows
- LuaJIT (included: luajit.exe and lua51.dll)

### On Linux (Debian/Ubuntu)
- Wine (version 10.0 or later recommended)

Install Wine:
```bash
sudo apt-get update
sudo apt-get install wine
```

Verify Wine installation:
```bash
wine --version
```

## Running the Application

### Easy Way (Recommended)

Use the platform-specific launcher script:

#### On Windows:
Double-click `run.cmd` in Windows Explorer, or run from Command Prompt:
```cmd
run.cmd
```

#### On Linux/Unix:
```bash
./run.sh
```

### Manual Way

#### On Windows:
```cmd
luajit.exe main.lua
```

#### On Linux with Wine:
```bash
wine luajit.exe main.lua
```

## Usage Guide

1. **Adding Tasks**:
   - Type a task description in the "New Task" field
   - Click the "Add" button
   - The task appears in the listbox

2. **Editing Tasks**:
   - Select a task from the list
   - Click "Edit Selected" or double-click the task
   - The task text appears in the edit field
   - Modify the text
   - Click "Update" to save changes

3. **Deleting Tasks**:
   - Select a task from the list
   - Click the "Delete" button

4. **Clearing All Tasks**:
   - Click "Clear All"
   - Confirm the action in the dialog

## Technical Details

### FFI Callback Management
LuaJIT's garbage collector can reclaim callback functions passed to Windows. The `win32_ffi` module stores callbacks in a module-level table to prevent this:

```lua
local _callbacks = {}
function M.create_callback(func)
    local cb = ffi.cast("LRESULT (*)(HWND, UINT, WPARAM, LPARAM)", func)
    table.insert(_callbacks, cb)  -- Prevent GC
    return cb
end
```

### Unicode String Conversion
Windows expects UTF-16 (wchar_t*) while Lua uses UTF-8. The FFI module uses `MultiByteToWideChar` and `WideCharToMultiByte` APIs for proper conversion:

```lua
-- Convert Lua string to Windows wide string
local wstr = win32.to_wstring("Hello, World!")

-- Convert Windows wide string to Lua string
local str = win32.from_wstring(wchar_ptr, length)
```

### Message Routing
Win32 uses a message-based architecture. The WndProc callback receives all window messages and routes them to Lua event handlers:

```lua
-- In gui.lua
local function WndProc(hwnd, msg, wParam, lParam)
    if msg == win32.WM_COMMAND then
        local control_id, notification = win32.extract_command(wParam)
        window_ref.callbacks.command(control_id, notification)
    end
    return win32.DefWindowProcW(hwnd, msg, wParam, lParam)
end
```

## Extending the Application

### Adding New Controls

```lua
-- In your application code
local button_id, button_hwnd = window:add_button(nil, x, y, w, h, "Click Me")
local edit_id, edit_hwnd = window:add_edit(nil, x, y, w, h, "Default text")
local label_id, label_hwnd = window:add_label(nil, x, y, w, h, "Label text")
```

### Handling Custom Events

```lua
-- Register event handler
window:on("command", function(control_id, notification)
    if control_id == my_button_id and notification == win32.BN_CLICKED then
        print("Button clicked!")
    end
end)
```

### Adding More Win32 APIs

To use additional Win32 APIs:

1. Add function declaration to `ffi.cdef` block in `lib/win32_ffi.lua`
2. Add any required constants
3. Optionally create helper functions for easier use

Example:
```lua
-- In win32_ffi.lua, add to ffi.cdef:
int SetWindowPos(HWND hWnd, HWND hWndInsertAfter, int X, int Y,
                 int cx, int cy, UINT uFlags);

-- Add constants:
M.SWP_NOMOVE = 0x0002
M.SWP_NOSIZE = 0x0001

-- Wrap the function:
M.SetWindowPos = ffi.C.SetWindowPos
```

## Troubleshooting

### Wine Issues

**Problem**: Application crashes or doesn't start
- Check Wine version: `wine --version` (10.0+ recommended)
- Try running with Wine debug output: `WINEDEBUG=+all wine luajit.exe main.lua`
- Ensure lua51.dll is in the same directory as luajit.exe

**Problem**: UI rendering issues
- Some Wine versions have incomplete GDI/USER32 implementations
- Try updating Wine to the latest version
- Check Wine AppDB for known issues

### FFI Issues

**Problem**: Callback crashes
- Ensure callbacks are stored in module-level table (prevents GC)
- Verify callback signature matches Win32 expectations

**Problem**: String conversion errors
- Check that MultiByteToWideChar/WideCharToMultiByte are used correctly
- Verify null termination of wide strings
- Ensure proper buffer allocation

### General Issues

**Problem**: Controls not responding
- Verify control IDs are unique
- Check that WM_COMMAND handler extracts control_id correctly
- Ensure callbacks are registered before window:run()

## Reference Materials

- **Win32 API Documentation**: https://docs.microsoft.com/en-us/windows/win32/api/
- **LuaJIT FFI Tutorial**: http://luajit.org/ext_ffi_tutorial.html
- **LuaJIT FFI API**: http://luajit.org/ext_ffi_api.html
- **Wine Documentation**: https://wiki.winehq.org/
- **Original C Reference**: See `simplelistbox.c` in this directory

## License

This is a demonstration project for educational purposes. Feel free to use and modify as needed.

## Credits

- Based on Win32 API examples from http://zetcode.com/ebooks/windowsapi/
- LuaJIT by Mike Pall
- Wine project for Windows API compatibility on Linux

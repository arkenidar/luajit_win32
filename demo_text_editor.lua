-- demo_text_editor.lua
-- Unicode-aware Text Editor using Cairo, Pango, and SDL2
-- Supports emoji, Unicode, and proper text file I/O

local ffi = require("ffi")
local bit = require("bit")
local text_editor_module = require("lib.text_editor")
local text_io = require("lib.text_io")
local cairo_ffi = require("lib.ffi.cairo_ffi")
local pango_ffi = require("lib.ffi.pango_ffi")
local sdl_ffi = require("lib.ffi.sdl2_ffi")

-- Application state
local app = {
    editor = nil,
    window = nil,
    renderer = nil,
    texture = nil,
    current_file = nil,
    modified = false,
    clock = 0,
    cursor_blink = 0,
    show_cursor = true,
    status_message = "Ready",
    status_timeout = 0
}

-- Initialize SDL and create window
local function init_sdl()
    -- Initialize SDL2
    local init_result = sdl_ffi.SDL_Init(sdl_ffi.SDL_INIT_VIDEO)
    if init_result ~= 0 then
        error("Failed to initialize SDL2: " .. init_result)
    end
    print("[INIT_SDL] SDL2 initialized successfully")
    
    -- Create window
    app.window = sdl_ffi.SDL_CreateWindow(
        "Text Editor - LuaJIT (Cairo/Pango/SDL2)",
        sdl_ffi.SDL_WINDOWPOS_CENTERED,
        sdl_ffi.SDL_WINDOWPOS_CENTERED,
        1024, 768,
        sdl_ffi.SDL_WINDOW_SHOWN + sdl_ffi.SDL_WINDOW_RESIZABLE
    )
    
    if app.window == nil then
        print("NOTE: Running in headless/display-less environment")
        print("SDL window could not be created (no display server)")
        print("The text editor is functional but cannot be displayed visually.")
        print("To use the GUI, run on a system with X11, Wayland, or Windows.")
        return false
    end
    
    print("[INIT_SDL] SDL window created successfully: 1024x768")
    
    -- Create renderer
    app.renderer = sdl_ffi.SDL_CreateRenderer(
        app.window, -1, sdl_ffi.SDL_RENDERER_ACCELERATED
    )
    
    if app.renderer == nil then
        error("Failed to create SDL renderer")
    end
    
    print("[INIT_SDL] SDL renderer created successfully")
    
    return true
end

-- Initialize text editor
local function init_editor()
    -- Create editor instance
    app.editor = text_editor_module.TextEditor:new(1024, 700, 14, "Monospace")
    
    -- Load sample content with emoji
    local sample_text = [=[
Text Editor Demo with Unicode & Emoji Support

Welcome to the LuaJIT Text Editor! 👋
This editor demonstrates:
  ✓ Unicode text support (你好世界 - Hello world)
  ✓ Emoji rendering (🎨 🎭 🎪 🎯 🚀)
  ✓ Cairo/Pango for professional text layout
  ✓ File I/O with automatic encoding detection
  ✓ Undo/Redo support (Ctrl+Z / Ctrl+Y)
  ✓ Select all (Ctrl+A)
  ✓ Cut/Copy/Paste (Ctrl+X / Ctrl+C / Ctrl+V)

Try typing here! 📝

Special characters: é à ñ ü ß © ™ ® ½ ¾ ¿
Arrows: ← → ↑ ↓ ↔ ↕ ⇐ ⇒ ⇑ ⇓
Math: ∑ ∫ √ ∞ ≠ ≤ ≥ ± × ÷ ≈

Line endings are preserved properly.
You can use Ctrl+O to open files (in extended version).
Ctrl+S saves to default location.
]=]

    app.editor:set_text(sample_text)
    app.editor:move_cursor(1, 1, false)
end

-- Render editor to texture
local function render_editor()
    -- Render editor content to Cairo surface
    app.editor:render()
    
    -- Get Cairo surface data
    local render_data = app.editor:get_render_data()
    if render_data == nil or render_data.surface == nil then
        print("WARNING: render_data or surface is nil, skipping frame")
        return
    end
    
    local surface = render_data.surface
    local data = cairo_ffi.cairo_image_surface_get_data(surface)
    local stride = cairo_ffi.cairo_image_surface_get_stride(surface)
    
    -- Create or update SDL texture
    if app.texture == nil then
        print(string.format("[RENDER] Creating texture: %dx%d", app.editor.width, app.editor.height))
        app.texture = sdl_ffi.SDL_CreateTexture(
            app.renderer,
            sdl_ffi.SDL_PIXELFORMAT_RGB24,
            sdl_ffi.SDL_TEXTUREACCESS_STATIC,
            app.editor.width,
            app.editor.height
        )
        if app.texture == nil then
            print("[RENDER] ERROR: Failed to create SDL texture!")
            return
        end
    end
    
    -- Update texture with Cairo surface data
    if app.texture ~= nil and data ~= nil then
        local ret = sdl_ffi.SDL_UpdateTexture(
            app.texture, nil, data, stride
        )
        if ret ~= 0 then
            print("[RENDER] ERROR: SDL_UpdateTexture failed with code: " .. ret)
        end
    end
end

-- Display editor on screen
local function display_editor()
    -- Check if renderer is available - only skip if no renderer exists
    if app.renderer == nil then
        return
    end
    
    -- Always clear screen with background color
    sdl_ffi.SDL_SetRenderDrawColor(app.renderer, 255, 255, 255, 255)
    sdl_ffi.SDL_RenderClear(app.renderer)
    
    -- Render texture if it exists
    if app.texture ~= nil then
        local dest_rect = ffi.new("SDL_Rect", {
            x = 0, y = 0,
            w = app.editor.width,
            h = app.editor.height
        })
        local copy_ret = sdl_ffi.SDL_RenderCopy(app.renderer, app.texture, nil, dest_rect)
        if copy_ret ~= 0 then
            print("[DISPLAY] ERROR: SDL_RenderCopy failed with code: " .. copy_ret)
        end
    end
    
    -- Render status bar
    local status_text = string.format(
        "Line %d, Col %d | %d lines | %d chars | %s",
        app.editor.cursor_line,
        app.editor.cursor_col,
        app.editor:line_count(),
        app.editor:char_count(),
        app.status_message
    )
    
    -- Simple status bar (white background, black text)
    local status_rect = ffi.new("SDL_Rect", {
        x = 0, y = app.editor.height,
        w = 1024, h = 68
    })
    
    sdl_ffi.SDL_SetRenderDrawColor(app.renderer, 200, 200, 200, 255)
    sdl_ffi.SDL_RenderFillRect(app.renderer, status_rect)
    
    -- Draw help text in status bar
    local help_text = "Ctrl+Z: Undo | Ctrl+Y: Redo | Ctrl+A: Select All | Ctrl+S: Save | ESC: Quit"
    
    -- Note: For full implementation, we'd render this using Pango as well
    
    -- Present the frame (returns void)
    sdl_ffi.SDL_RenderPresent(app.renderer)
end

-- Handle keyboard input
local function handle_key_event(event)
    local keysym = event.key.keysym.sym
    local mod = event.key.keysym.mod
    
    -- Get modifier keys using SDL constants
    local shift = bit.band(mod, sdl_ffi.KMOD_SHIFT) ~= 0
    local ctrl = bit.band(mod, sdl_ffi.KMOD_CTRL) ~= 0
    local alt = bit.band(mod, sdl_ffi.KMOD_ALT) ~= 0
    
    -- Debug: Log key event
    print(string.format("[KEY] keysym=%d, shift=%s, ctrl=%s, alt=%s", keysym, tostring(shift), tostring(ctrl), tostring(alt)))
    
    if keysym == sdl_ffi.SDLK_ESCAPE then
        return false  -- Quit
    elseif keysym == sdl_ffi.SDLK_LEFT then
        app.editor:cursor_left(shift)
    elseif keysym == sdl_ffi.SDLK_RIGHT then
        app.editor:cursor_right(shift)
    elseif keysym == sdl_ffi.SDLK_UP then
        app.editor:cursor_up(shift)
    elseif keysym == sdl_ffi.SDLK_DOWN then
        app.editor:cursor_down(shift)

    elseif keysym == sdl_ffi.SDLK_BACKSPACE then
        app.editor:delete_char()
        app.modified = true
    elseif keysym == sdl_ffi.SDLK_DELETE then
        app.editor:delete_char_forward()
        app.modified = true
    elseif keysym == sdl_ffi.SDLK_RETURN then
        app.editor:insert_text("\n")
        app.modified = true
    elseif keysym == sdl_ffi.SDLK_TAB then
        app.editor:insert_text("  ")
        app.modified = true
    elseif ctrl and keysym == sdl_ffi.SDLK_z then
        app.editor:undo()
    elseif ctrl and keysym == sdl_ffi.SDLK_y then
        app.editor:redo()
    elseif ctrl and keysym == sdl_ffi.SDLK_a then
        app.editor:select_all()
    elseif ctrl and keysym == sdl_ffi.SDLK_s then
        save_file()

    end
    
    return true
end

-- Handle text input (for Unicode support)
local function handle_text_input(event)
    -- event.text.text contains the UTF-8 text input
    -- This allows for proper Unicode/Emoji input
    -- Only handles regular text input, not special keys
    local text = ffi.string(event.text.text)
    
    print(string.format("[TEXT_INPUT] Got text: %q", text))
    
    if text and #text > 0 then
        -- Use insert_text directly for character input
        app.editor:insert_text(text)
        app.modified = true
    end
end

-- Save current file
local function save_file()
    local filepath = app.current_file or "editor_output.txt"
    
    local success, err = text_io.save_file(filepath, app.editor:get_text(), "utf8")
    
    if success then
        app.status_message = string.format("Saved: %s", filepath)
        app.status_timeout = 3000
        app.modified = false
        app.current_file = filepath
    else
        app.status_message = string.format("Save failed: %s", err or "Unknown error")
        app.status_timeout = 3000
    end
end

-- Open file dialog (simplified - accepts command line argument)
local function open_file(filepath)
    if not filepath or #filepath == 0 then
        app.status_message = "No file specified"
        app.status_timeout = 2000
        return
    end
    
    local content, encoding = text_io.load_file(filepath)
    
    if not content then
        app.status_message = string.format("Cannot open: %s", filepath)
        app.status_timeout = 2000
        return
    end
    
    app.editor:set_text(content)
    app.current_file = filepath
    app.modified = false
    app.status_message = string.format("Opened: %s (%s)", filepath, encoding)
    app.status_timeout = 2000
end

-- Main event loop
local function run()
    local display_available = init_sdl()
    init_editor()
    
    -- Debug: Log all SDL window event constants
    
    -- Check if file was passed as argument
    if arg and arg[1] and #arg[1] > 0 then
        open_file(arg[1])
    end
    
    print("Text Editor initialized successfully!")
    print(string.format("Window size: %dx%d", app.editor.width, app.editor.height))
    
    if not display_available then
        print("\nHeadless mode detected - no display server available")
        print("The text editor core is working, but GUI cannot be displayed.")
        print("Try running on a machine with a display server (X11/Wayland/Windows)")
        return
    end
    
    print("Use Ctrl+Z to undo, Ctrl+Y to redo, ESC to quit")
    
    local running = true
    local event = ffi.new("SDL_Event")
    local frame_count = 0
    local last_frame_log = 0
    
    while running do
        frame_count = frame_count + 1
        
        -- Log frame info every 60 frames (about 1 second at 60 FPS)
        if frame_count - last_frame_log >= 60 then
            print(string.format("[FRAME] Frame %d - Window exists: %s, Renderer: %s, Texture: %s", 
                frame_count,
                tostring(app.window ~= nil),
                tostring(app.renderer ~= nil),
                tostring(app.texture ~= nil)))
            last_frame_log = frame_count
        end
        
        -- Handle events
        while sdl_ffi.SDL_PollEvent(event) ~= 0 do
            print(string.format("[EVENT] Frame %d - Event type: %d", frame_count, event.type))
            if event.type == sdl_ffi.SDL_QUIT then
                print("[EVENT] SDL_QUIT received at frame " .. frame_count)
                running = false
            elseif event.type == sdl_ffi.SDL_KEYDOWN then
                running = handle_key_event(event)
            elseif event.type == sdl_ffi.SDL_TEXTINPUT then
                handle_text_input(event)
            elseif event.type == sdl_ffi.SDL_WINDOWEVENT then
                local window_event_type = event.window.event
                print("[DEBUG] Window event type: " .. window_event_type .. ", SDL_WINDOWEVENT_CLOSE = " .. sdl_ffi.SDL_WINDOWEVENT_CLOSE)
                if window_event_type == sdl_ffi.SDL_WINDOWEVENT_CLOSE then
                    print("[EVENT] SDL_WINDOWEVENT_CLOSE received at frame " .. frame_count)
                    running = false
                end
            end
        end
        
        -- Render with error handling
        local render_ok, render_err = xpcall(render_editor, debug.traceback)
        if not render_ok then
            print("Render error: " .. render_err)
        end
        
        -- Display with error handling
        local display_ok, display_err = xpcall(display_editor, debug.traceback)
        if not display_ok then
            print("Display error: " .. display_err)
        end
        
        -- Update status message timeout
        if app.status_timeout > 0 then
            app.status_timeout = app.status_timeout - 16  -- ~60 FPS
        end
        
        -- Blink cursor
        app.cursor_blink = app.cursor_blink + 16
        if app.cursor_blink > 1000 then
            app.show_cursor = not app.show_cursor
            app.cursor_blink = 0
        end
        
        -- Small delay for ~60 FPS
        sdl_ffi.SDL_Delay(16)
    end
    
    -- Cleanup
    if app.modified then
        print("Warning: Document has unsaved changes!")
    end
    
    if app.texture ~= nil then
        sdl_ffi.SDL_DestroyTexture(app.texture)
    end
    
    if app.renderer ~= nil then
        sdl_ffi.SDL_DestroyRenderer(app.renderer)
    end
    
    if app.window ~= nil then
        sdl_ffi.SDL_DestroyWindow(app.window)
    end
    
    if app.editor then
        app.editor:cleanup()
    end
    
    sdl_ffi.SDL_Quit()
end

-- Run the application with error handling
local success, err = pcall(run)
if not success then
    print("\n" .. string.rep("=", 60))
    print("ERROR IN APPLICATION:")
    print(string.rep("=", 60))
    print(err)
    print(string.rep("=", 60))
    print("Stack trace:")
    print(debug.traceback())
    print(string.rep("=", 60) .. "\n")
    os.execute("sleep 3")
else
    print("\n" .. string.rep("=", 60))
    print("Application closed normally")
    print(string.rep("=", 60))
end

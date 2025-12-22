--[[
    SDL2 Backend Implementation

    Implements the platform abstraction layer API using SDL2 + Cairo.
    Uses Cairo for 2D vector graphics rendering (zero-copy integration).
]]

local ffi = require("ffi")
local sdl = require("lib.sdl_base.sdl_api")

local SDL2Backend = {}
SDL2Backend.__index = SDL2Backend

function SDL2Backend:new()
    local self = setmetatable({}, SDL2Backend)
    self.windows = {}  -- Track windows by SDL_Window pointer
    self.next_control_id = 1
    self.controls = {}  -- Track controls by ID
    self.running = false
    return self
end

function SDL2Backend:init()
    sdl.init()
    return self
end

function SDL2Backend:get_backend_name()
    return "sdl2"
end

-- Window management
function SDL2Backend:create_window(title, width, height, flags)
    local SDLWindow = require("lib.backend.sdl_window")
    local window = SDLWindow.new(title, width, height, self)

    -- Use SDL_Window pointer as key
    local key = tonumber(ffi.cast("intptr_t", window.sdl_window))
    self.windows[key] = window

    return window
end

function SDL2Backend:destroy_window(window)
    local key = tonumber(ffi.cast("intptr_t", window.sdl_window))
    self.windows[key] = nil
    window:destroy()
end

function SDL2Backend:get_window_size(window)
    return window:get_size()
end

function SDL2Backend:set_window_title(window, title)
    window:set_title(title)
end

-- Event loop
function SDL2Backend:run_event_loop(window, event_handlers)
    -- Store event handlers on the window
    window.event_handlers = event_handlers

    -- Call on_create if it exists
    if event_handlers.on_create then
        event_handlers.on_create()
    end

    self.running = true
    local event = ffi.new("SDL_Event")

    while self.running do
        -- Poll all events
        while sdl.poll_event(event) ~= 0 do
            if event.type == sdl.QUIT then
                self.running = false
                if event_handlers.on_close then
                    event_handlers.on_close()
                end
                break
            elseif event.type == sdl.WINDOWEVENT then
                self:_handle_window_event(event, window, event_handlers)
            elseif event.type == sdl.MOUSEBUTTONDOWN then
                self:_handle_mouse_button_down(event, window, event_handlers)
            elseif event.type == sdl.MOUSEMOTION then
                self:_handle_mouse_motion(event, window, event_handlers)
            elseif event.type == sdl.KEYDOWN then
                self:_handle_key_down(event, window, event_handlers)
            end
        end

        -- Render all windows
        for _, win in pairs(self.windows) do
            win:render()
        end

        -- Small delay to prevent 100% CPU
        sdl.delay(16)  -- ~60 FPS
    end

    -- Call on_destroy if it exists
    if event_handlers.on_destroy then
        event_handlers.on_destroy()
    end

    return 0
end

function SDL2Backend:_handle_window_event(event, window, handlers)
    if event.window.event == sdl.WINDOWEVENT_SIZE_CHANGED then
        local w = event.window.data1
        local h = event.window.data2
        window:resize(w, h)

        if handlers.on_resize then
            handlers.on_resize(w, h)
        end
    end
end

function SDL2Backend:_handle_mouse_button_down(event, window, handlers)
    local x = event.button.x
    local y = event.button.y

    -- Find control under mouse and fire click event
    local control = window:hit_test(x, y)
    if control and handlers.on_button_click then
        handlers.on_button_click(control.id)
    end
end

function SDL2Backend:_handle_mouse_motion(event, window, handlers)
    local x = event.motion.x
    local y = event.motion.y

    -- Update hover states
    window:update_hover(x, y)
end

function SDL2Backend:_handle_key_down(event, window, handlers)
    -- Handle keyboard input (future: text input for edit controls)
end

-- Control creation
function SDL2Backend:create_button(window, x, y, w, h, text)
    local id = self.next_control_id
    self.next_control_id = self.next_control_id + 1

    local button = {
        id = id,
        type = "button",
        x = x, y = y,
        width = w, height = h,
        text = text,
        enabled = true,
        hover = false,
        pressed = false
    }

    self.controls[id] = button
    window:add_control(button)

    return id
end

function SDL2Backend:create_listbox(window, x, y, w, h)
    local id = self.next_control_id
    self.next_control_id = self.next_control_id + 1

    local listbox = {
        id = id,
        type = "listbox",
        x = x, y = y,
        width = w, height = h,
        items = {},
        selection = -1,
        enabled = true
    }

    self.controls[id] = listbox
    window:add_control(listbox)

    return id
end

function SDL2Backend:create_edit(window, x, y, w, h, text)
    local id = self.next_control_id
    self.next_control_id = self.next_control_id + 1

    local edit = {
        id = id,
        type = "edit",
        x = x, y = y,
        width = w, height = h,
        text = text or "",
        enabled = true,
        cursor_pos = 0
    }

    self.controls[id] = edit
    window:add_control(edit)

    return id
end

function SDL2Backend:create_label(window, x, y, w, h, text)
    local id = self.next_control_id
    self.next_control_id = self.next_control_id + 1

    local label = {
        id = id,
        type = "label",
        x = x, y = y,
        width = w, height = h,
        text = text,
        enabled = true
    }

    self.controls[id] = label
    window:add_control(label)

    return id
end

function SDL2Backend:create_opengl_view(window, x, y, w, h)
    local id = self.next_control_id
    self.next_control_id = self.next_control_id + 1

    -- TODO: OpenGL view (Phase A5 - compositor architecture)
    local view = {
        id = id,
        type = "opengl_view",
        x = x, y = y,
        width = w, height = h,
        enabled = true
    }

    self.controls[id] = view
    window:add_control(view)

    return id
end

-- Control manipulation
function SDL2Backend:set_control_text(control_id, text)
    local control = self.controls[control_id]
    if control then
        control.text = text
    end
end

function SDL2Backend:get_control_text(control_id)
    local control = self.controls[control_id]
    if control then
        return control.text or ""
    end
    return ""
end

function SDL2Backend:enable_control(control_id, enabled)
    local control = self.controls[control_id]
    if control then
        control.enabled = enabled
    end
end

function SDL2Backend:set_control_position(control_id, x, y, w, h)
    local control = self.controls[control_id]
    if control then
        control.x = x
        control.y = y
        control.width = w
        control.height = h
    end
end

-- Listbox operations
function SDL2Backend:listbox_add_item(control_id, text)
    local control = self.controls[control_id]
    if control and control.type == "listbox" then
        table.insert(control.items, text)
        return #control.items - 1  -- Return index (0-based)
    end
    return -1
end

function SDL2Backend:listbox_delete_item(control_id, index)
    local control = self.controls[control_id]
    if control and control.type == "listbox" then
        table.remove(control.items, index + 1)  -- Convert 0-based to 1-based
        if control.selection == index then
            control.selection = -1
        elseif control.selection > index then
            control.selection = control.selection - 1
        end
    end
end

function SDL2Backend:listbox_get_selection(control_id)
    local control = self.controls[control_id]
    if control and control.type == "listbox" then
        return control.selection
    end
    return -1
end

function SDL2Backend:listbox_set_selection(control_id, index)
    local control = self.controls[control_id]
    if control and control.type == "listbox" then
        control.selection = index
    end
end

function SDL2Backend:listbox_get_item_text(control_id, index)
    local control = self.controls[control_id]
    if control and control.type == "listbox" then
        return control.items[index + 1] or ""  -- Convert 0-based to 1-based
    end
    return ""
end

function SDL2Backend:listbox_clear(control_id)
    local control = self.controls[control_id]
    if control and control.type == "listbox" then
        control.items = {}
        control.selection = -1
    end
end

function SDL2Backend:listbox_get_count(control_id)
    local control = self.controls[control_id]
    if control and control.type == "listbox" then
        return #control.items
    end
    return 0
end

-- OpenGL context management (stub for now, will be implemented in Phase A5)
function SDL2Backend:create_opengl_context(control_id)
    error("OpenGL context creation not yet implemented for SDL2 backend (Phase A5)")
end

function SDL2Backend:make_context_current(gl_context)
    error("OpenGL context management not yet implemented for SDL2 backend (Phase A5)")
end

function SDL2Backend:swap_buffers(gl_context)
    error("OpenGL swap buffers not yet implemented for SDL2 backend (Phase A5)")
end

function SDL2Backend:destroy_opengl_context(gl_context)
    error("OpenGL context destruction not yet implemented for SDL2 backend (Phase A5)")
end

-- Timer management
function SDL2Backend:set_timer(window, timer_id, interval_ms, callback)
    -- TODO: Implement SDL2 timer support
    -- For now, timers are not supported
end

function SDL2Backend:kill_timer(window, timer_id)
    -- TODO: Implement SDL2 timer support
end

-- Utility
function SDL2Backend:show_message_box(window, title, message, msg_type)
    -- TODO: Implement SDL2 message box
    -- For now, just print to console
    print("MessageBox:", title, "-", message)
    return "ok"
end

-- Create singleton instance
return SDL2Backend:new()

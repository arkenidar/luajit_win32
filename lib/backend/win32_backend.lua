--[[
    Win32 Backend Implementation

    Wraps the existing gui.lua (Win32) functionality to implement
    the platform abstraction layer API.
]]

local ffi = require("ffi")
local win32 = require("lib.ffi.win32_ffi")
local gui = require("lib.gui")

local Win32Backend = {}
Win32Backend.__index = Win32Backend

function Win32Backend:new()
    local self = setmetatable({}, Win32Backend)
    self.windows = {}  -- Track windows
    self.controls = {}  -- Track controls by ID
    return self
end

function Win32Backend:init()
    -- Win32 doesn't need initialization
    return self
end

function Win32Backend:get_backend_name()
    return "win32"
end

-- Window management
function Win32Backend:create_window(title, width, height, flags)
    local window = gui.Window:new(title, width, height)
    self.windows[window.hwnd] = window
    return window
end

function Win32Backend:destroy_window(window)
    win32.DestroyWindow(window.hwnd)
    self.windows[window.hwnd] = nil
end

function Win32Backend:get_window_size(window)
    return window:get_client_size()
end

function Win32Backend:set_window_title(window, title)
    win32.SetWindowTextW(window.hwnd, win32.to_wstring(title))
end

-- Event loop
function Win32Backend:run_event_loop(window, event_handlers)
    -- Set up event handlers on the window
    if event_handlers.on_create then
        window:on("create", event_handlers.on_create)
    end
    if event_handlers.on_destroy then
        window:on("destroy", event_handlers.on_destroy)
    end
    if event_handlers.on_button_click or event_handlers.on_listbox_select or event_handlers.on_listbox_doubleclick then
        window:on("command", function(control_id, notification)
            if notification == win32.BN_CLICKED and event_handlers.on_button_click then
                event_handlers.on_button_click(control_id)
            elseif notification == win32.LBN_SELCHANGE and event_handlers.on_listbox_select then
                event_handlers.on_listbox_select(control_id)
            elseif notification == win32.LBN_DBLCLK and event_handlers.on_listbox_doubleclick then
                event_handlers.on_listbox_doubleclick(control_id)
            end
        end)
    end
    if event_handlers.on_timer then
        window:on("timer", event_handlers.on_timer)
    end
    if event_handlers.on_resize then
        window:on("size", event_handlers.on_resize)
    end
    if event_handlers.on_close then
        window:on("close", event_handlers.on_close)
    end

    -- Run the Win32 message loop
    return window:run()
end

-- Control creation
function Win32Backend:create_button(window, x, y, w, h, text)
    local id, hwnd = window:add_button(nil, x, y, w, h, text)
    self.controls[id] = {hwnd = hwnd, window = window}
    return id
end

function Win32Backend:create_listbox(window, x, y, w, h)
    local id, listbox = window:add_listbox(nil, x, y, w, h)
    self.controls[id] = {hwnd = listbox.hwnd, window = window, listbox = listbox}
    return id
end

function Win32Backend:create_edit(window, x, y, w, h, text)
    local id, hwnd = window:add_edit(nil, x, y, w, h, text)
    self.controls[id] = {hwnd = hwnd, window = window}
    return id
end

function Win32Backend:create_label(window, x, y, w, h, text)
    local id, hwnd = window:add_label(nil, x, y, w, h, text)
    self.controls[id] = {hwnd = hwnd, window = window}
    return id
end

function Win32Backend:create_opengl_view(window, x, y, w, h)
    local id, hwnd = window:add_opengl_view(nil, x, y, w, h)
    self.controls[id] = {hwnd = hwnd, window = window}
    return id
end

-- Control manipulation
function Win32Backend:set_control_text(control_id, text)
    local control = self.controls[control_id]
    if control then
        control.window:set_control_text(control.hwnd, text)
    end
end

function Win32Backend:get_control_text(control_id)
    local control = self.controls[control_id]
    if control then
        return control.window:get_control_text(control.hwnd)
    end
    return ""
end

function Win32Backend:enable_control(control_id, enabled)
    local control = self.controls[control_id]
    if control then
        control.window:enable_control(control.hwnd, enabled)
    end
end

function Win32Backend:set_control_position(control_id, x, y, w, h)
    local control = self.controls[control_id]
    if control then
        win32.SetWindowPos(
            control.hwnd,
            nil,
            x, y, w, h,
            win32.SWP_NOZORDER + win32.SWP_NOACTIVATE
        )
    end
end

-- Listbox operations
function Win32Backend:listbox_add_item(control_id, text)
    local control = self.controls[control_id]
    if control and control.listbox then
        return control.listbox:add_item(text)
    end
    return -1
end

function Win32Backend:listbox_delete_item(control_id, index)
    local control = self.controls[control_id]
    if control and control.listbox then
        control.listbox:delete_item(index)
    end
end

function Win32Backend:listbox_get_selection(control_id)
    local control = self.controls[control_id]
    if control and control.listbox then
        return control.listbox:get_selection()
    end
    return -1
end

function Win32Backend:listbox_set_selection(control_id, index)
    local control = self.controls[control_id]
    if control and control.listbox then
        control.listbox:set_selection(index)
    end
end

function Win32Backend:listbox_get_item_text(control_id, index)
    local control = self.controls[control_id]
    if control and control.listbox then
        return control.listbox:get_item_text(index)
    end
    return ""
end

function Win32Backend:listbox_clear(control_id)
    local control = self.controls[control_id]
    if control and control.listbox then
        control.listbox:clear()
    end
end

function Win32Backend:listbox_get_count(control_id)
    local control = self.controls[control_id]
    if control and control.listbox then
        return control.listbox:get_count()
    end
    return 0
end

-- OpenGL context management
function Win32Backend:create_opengl_context(control_id)
    local control = self.controls[control_id]
    if not control then
        error("Invalid control ID for OpenGL context creation")
    end

    local gl = require("lib.ffi.opengl_ffi")
    local hdc, hglrc = gl.init_opengl_context(control.hwnd)

    return {
        type = "win32_gl",
        control_id = control_id,
        hwnd = control.hwnd,
        hdc = hdc,
        hglrc = hglrc,
        backend = self
    }
end

function Win32Backend:make_context_current(gl_context)
    if gl_context.type ~= "win32_gl" then
        error("Invalid GL context type for Win32 backend")
    end
    local gl = require("lib.ffi.opengl_ffi")
    gl.wglMakeCurrent(gl_context.hdc, gl_context.hglrc)
end

function Win32Backend:swap_buffers(gl_context)
    if gl_context.type ~= "win32_gl" then
        error("Invalid GL context type for Win32 backend")
    end
    local gl = require("lib.ffi.opengl_ffi")
    gl.SwapBuffers(gl_context.hdc)
end

function Win32Backend:destroy_opengl_context(gl_context)
    if gl_context.type == "win32_gl" then
        local gl = require("lib.ffi.opengl_ffi")
        gl.cleanup_opengl_context(gl_context.hwnd, gl_context.hdc, gl_context.hglrc)
    end
end

-- Timer management
function Win32Backend:set_timer(window, timer_id, interval_ms, callback)
    win32.SetTimer(window.hwnd, timer_id, interval_ms, nil)
    -- Callback is handled via event_handlers.on_timer in run_event_loop
end

function Win32Backend:kill_timer(window, timer_id)
    win32.KillTimer(window.hwnd, timer_id)
end

-- Utility
function Win32Backend:show_message_box(window, title, message, msg_type)
    local flags = win32.MB_OK
    if msg_type == "yesno" then
        flags = win32.MB_YESNO
    elseif msg_type == "okcancel" then
        flags = win32.MB_OKCANCEL
    end

    local result = win32.MessageBoxW(
        window and window.hwnd or nil,
        win32.to_wstring(message),
        win32.to_wstring(title),
        flags
    )

    if result == win32.IDYES or result == win32.IDOK then
        return "ok"
    elseif result == win32.IDNO then
        return "no"
    else
        return "cancel"
    end
end

-- Create singleton instance
return Win32Backend:new()

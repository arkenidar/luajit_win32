-- gui.lua
-- GUI abstraction layer for Win32 APIs

local ffi = require("ffi")
local win32 = require("lib.win32_ffi")

local M = {}

-- Control ID generator
local next_control_id = 1000

local function generate_id()
    local id = next_control_id
    next_control_id = next_control_id + 1
    return id
end

-- Window class
local Window = {}
Window.__index = Window

function Window:new(title, width, height)
    local self = setmetatable({}, Window)

    self.title = title
    self.width = width
    self.height = height
    self.hwnd = nil
    self.controls = {}
    self.callbacks = {}
    self.hInstance = win32.GetModuleHandleW(nil)

    -- Create the window
    self:create()

    return self
end

function Window:create()
    -- Convert title to wide string
    local className = win32.to_wstring("LuaJITWindow")
    local windowTitle = win32.to_wstring(self.title)

    -- Create WndProc callback
    local window_ref = self  -- Capture self for callback

    local function WndProc(hwnd, msg, wParam, lParam)
        -- Route to window instance callbacks
        if msg == win32.WM_CREATE then
            if window_ref.callbacks.create then
                window_ref.callbacks.create()
            end
            return 0
        elseif msg == win32.WM_DESTROY then
            if window_ref.callbacks.destroy then
                window_ref.callbacks.destroy()
            end
            win32.PostQuitMessage(0)
            return 0
        elseif msg == win32.WM_COMMAND then
            local control_id, notification = win32.extract_command(wParam)

            if window_ref.callbacks.command then
                window_ref.callbacks.command(control_id, notification)
            end
            return 0
        elseif msg == win32.WM_TIMER then
            if window_ref.callbacks.timer then
                window_ref.callbacks.timer(wParam)
            end
            return 0
        elseif msg == win32.WM_SIZE then
            local width = bit.band(tonumber(lParam), 0xFFFF)
            local height = bit.rshift(tonumber(lParam), 16)
            if window_ref.callbacks.size then
                window_ref.callbacks.size(width, height)
            end
            return 0
        elseif msg == win32.WM_CLOSE then
            if window_ref.callbacks.close then
                if window_ref.callbacks.close() then
                    return 0  -- Prevent default close
                end
            end
        end

        return win32.DefWindowProcW(hwnd, msg, wParam, lParam)
    end

    -- Register window class
    local wc = ffi.new("WNDCLASSW")
    wc.lpszClassName = className
    wc.hInstance = self.hInstance
    wc.hbrBackground = win32.GetSysColorBrush(win32.COLOR_3DFACE)
    wc.lpfnWndProc = win32.create_callback(WndProc)
    wc.hCursor = win32.LoadCursorW(nil, ffi.cast("LPCWSTR", win32.IDC_ARROW))

    local result = win32.RegisterClassW(wc)
    if result == 0 then
        error("Failed to register window class: " .. win32.GetLastError())
    end

    -- Create window
    self.hwnd = win32.CreateWindowExW(
        0,
        className,
        windowTitle,
        win32.WS_OVERLAPPEDWINDOW + win32.WS_VISIBLE,
        win32.CW_USEDEFAULT,
        win32.CW_USEDEFAULT,
        self.width,
        self.height,
        nil,
        nil,
        self.hInstance,
        nil
    )

    if self.hwnd == nil then
        error("Failed to create window: " .. win32.GetLastError())
    end

    win32.ShowWindow(self.hwnd, win32.SW_SHOWNORMAL)
    win32.UpdateWindow(self.hwnd)
end

function Window:on(event, callback)
    self.callbacks[event] = callback
end

function Window:add_button(id, x, y, w, h, text)
    if id == nil then
        id = generate_id()
    end

    local buttonText = win32.to_wstring(text or "Button")
    local hwnd = win32.CreateWindowExW(
        0,
        win32.to_wstring("BUTTON"),
        buttonText,
        win32.WS_CHILD + win32.WS_VISIBLE + win32.BS_PUSHBUTTON + win32.WS_TABSTOP,
        x, y, w, h,
        self.hwnd,
        ffi.cast("HMENU", id),
        self.hInstance,
        nil
    )

    if hwnd == nil then
        error("Failed to create button: " .. win32.GetLastError())
    end

    self.controls[id] = hwnd
    return id, hwnd
end

function Window:add_listbox(id, x, y, w, h)
    if id == nil then
        id = generate_id()
    end

    local hwnd = win32.CreateWindowExW(
        0,
        win32.to_wstring("LISTBOX"),
        nil,
        win32.WS_CHILD + win32.WS_VISIBLE + win32.LBS_NOTIFY + win32.WS_BORDER + win32.WS_VSCROLL,
        x, y, w, h,
        self.hwnd,
        ffi.cast("HMENU", id),
        self.hInstance,
        nil
    )

    if hwnd == nil then
        error("Failed to create listbox: " .. win32.GetLastError())
    end

    self.controls[id] = hwnd

    -- Return Listbox helper object
    return id, M.Listbox:new(hwnd)
end

function Window:add_edit(id, x, y, w, h, text)
    if id == nil then
        id = generate_id()
    end

    local editText = win32.to_wstring(text or "")
    local hwnd = win32.CreateWindowExW(
        0,
        win32.to_wstring("EDIT"),
        editText,
        win32.WS_CHILD + win32.WS_VISIBLE + win32.WS_BORDER + win32.ES_LEFT + win32.ES_AUTOHSCROLL + win32.WS_TABSTOP,
        x, y, w, h,
        self.hwnd,
        ffi.cast("HMENU", id),
        self.hInstance,
        nil
    )

    if hwnd == nil then
        error("Failed to create edit control: " .. win32.GetLastError())
    end

    self.controls[id] = hwnd
    return id, hwnd
end

function Window:add_label(id, x, y, w, h, text)
    if id == nil then
        id = generate_id()
    end

    local labelText = win32.to_wstring(text or "")
    local hwnd = win32.CreateWindowExW(
        0,
        win32.to_wstring("STATIC"),
        labelText,
        win32.WS_CHILD + win32.WS_VISIBLE + win32.SS_LEFT,
        x, y, w, h,
        self.hwnd,
        ffi.cast("HMENU", id),
        self.hInstance,
        nil
    )

    if hwnd == nil then
        error("Failed to create label: " .. win32.GetLastError())
    end

    self.controls[id] = hwnd
    return id, hwnd
end

function Window:add_opengl_view(id, x, y, w, h)
    if id == nil then
        id = generate_id()
    end

    -- Create child window with clipping styles for OpenGL
    local className = win32.to_wstring("LuaJITWindow")
    local hwnd = win32.CreateWindowExW(
        0,
        className,
        nil,
        win32.WS_CHILD + win32.WS_VISIBLE + win32.WS_CLIPCHILDREN + win32.WS_CLIPSIBLINGS,
        x, y, w, h,
        self.hwnd,
        ffi.cast("HMENU", id),
        self.hInstance,
        nil
    )

    if hwnd == nil then
        error("Failed to create OpenGL child window: " .. win32.GetLastError())
    end

    self.controls[id] = hwnd
    return id, hwnd
end

function Window:get_control_text(hwnd)
    local len = win32.GetWindowTextLengthW(hwnd)
    if len == 0 then
        return ""
    end

    local buffer = ffi.new("wchar_t[?]", len + 1)
    win32.GetWindowTextW(hwnd, buffer, len + 1)
    return win32.from_wstring(buffer, len)
end

function Window:set_control_text(hwnd, text)
    local wtext = win32.to_wstring(text or "")
    win32.SetWindowTextW(hwnd, wtext)
end

function Window:enable_control(hwnd, enabled)
    win32.EnableWindow(hwnd, enabled and 1 or 0)
end

function Window:run()
    local msg = ffi.new("MSG")

    while win32.GetMessageW(msg, nil, 0, 0) ~= 0 do
        win32.TranslateMessage(msg)
        win32.DispatchMessageW(msg)
    end

    return tonumber(msg.wParam)
end

M.Window = Window

-- Listbox helper class
local Listbox = {}
Listbox.__index = Listbox

function Listbox:new(hwnd)
    local self = setmetatable({}, Listbox)
    self.hwnd = hwnd
    return self
end

function Listbox:add_item(text)
    local wtext = win32.to_wstring(text)
    local index = win32.SendMessageW(self.hwnd, win32.LB_ADDSTRING, 0, ffi.cast("LPARAM", wtext))
    return tonumber(index)
end

function Listbox:delete_item(index)
    local result = win32.SendMessageW(self.hwnd, win32.LB_DELETESTRING, index, 0)
    return tonumber(result) ~= -1
end

function Listbox:get_selection()
    local index = win32.SendMessageW(self.hwnd, win32.LB_GETCURSEL, 0, 0)
    return tonumber(index)
end

function Listbox:set_selection(index)
    win32.SendMessageW(self.hwnd, win32.LB_SETCURSEL, index, 0)
end

function Listbox:get_item_text(index)
    -- Get text length
    local len = win32.SendMessageW(self.hwnd, win32.LB_GETTEXTLEN, index, 0)
    if tonumber(len) <= 0 then
        return ""
    end

    -- Allocate buffer and get text
    local buffer = ffi.new("wchar_t[?]", tonumber(len) + 1)
    win32.SendMessageW(self.hwnd, win32.LB_GETTEXT, index, ffi.cast("LPARAM", buffer))
    return win32.from_wstring(buffer, tonumber(len))
end

function Listbox:clear()
    win32.SendMessageW(self.hwnd, win32.LB_RESETCONTENT, 0, 0)
end

function Listbox:get_count()
    local count = win32.SendMessageW(self.hwnd, win32.LB_GETCOUNT, 0, 0)
    return tonumber(count)
end

M.Listbox = Listbox

return M

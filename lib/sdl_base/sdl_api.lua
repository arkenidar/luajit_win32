-- sdl_api.lua
-- SDL base abstraction layer
-- Provides unified API that works with both SDL2 and SDL3

local ffi = require("ffi")

local M = {}

-- Detect SDL version and load appropriate FFI bindings
-- For now, we only support SDL2. SDL3 support will be added in Phase 7.
local function detect_sdl_version()
    -- TODO: In Phase 7, add SDL3 detection logic here
    -- For now, always use SDL2
    return "sdl2"
end

local sdl_version = detect_sdl_version()
local sdl_ffi

if sdl_version == "sdl2" then
    sdl_ffi = require("lib.ffi.sdl2_ffi")
elseif sdl_version == "sdl3" then
    -- Phase 7: Load SDL3 FFI bindings
    sdl_ffi = require("lib.ffi.sdl3_ffi")
else
    error("Unsupported SDL version: " .. tostring(sdl_version))
end

-- Unified SDL API
-- These functions abstract away SDL2 vs SDL3 differences

function M.init()
    local result = sdl_ffi.SDL_Init(sdl_ffi.SDL_INIT_VIDEO)
    if result ~= 0 then
        error("SDL_Init failed")
    end
end

function M.quit()
    sdl_ffi.SDL_Quit()
end

function M.create_window(title, x, y, w, h, flags)
    flags = flags or {}

    local sdl_flags = sdl_ffi.SDL_WINDOW_SHOWN

    if flags.resizable then
        sdl_flags = bit.bor(sdl_flags, sdl_ffi.SDL_WINDOW_RESIZABLE)
    end

    if flags.opengl then
        sdl_flags = bit.bor(sdl_flags, sdl_ffi.SDL_WINDOW_OPENGL)
    end

    -- Use SDL_WINDOWPOS_CENTERED if x,y not specified
    x = x or sdl_ffi.SDL_WINDOWPOS_CENTERED
    y = y or sdl_ffi.SDL_WINDOWPOS_CENTERED

    local window = sdl_ffi.SDL_CreateWindow(title, x, y, w, h, sdl_flags)
    if window == nil then
        error("SDL_CreateWindow failed")
    end

    return window
end

function M.destroy_window(window)
    sdl_ffi.SDL_DestroyWindow(window)
end

function M.get_window_surface(window)
    local surface = sdl_ffi.SDL_GetWindowSurface(window)
    if surface == nil then
        error("SDL_GetWindowSurface failed")
    end
    return surface
end

function M.update_window_surface(window)
    local result = sdl_ffi.SDL_UpdateWindowSurface(window)
    if result ~= 0 then
        error("SDL_UpdateWindowSurface failed")
    end
end

function M.poll_event(event)
    return sdl_ffi.SDL_PollEvent(event)
end

function M.get_mouse_state()
    local x = ffi.new("int[1]")
    local y = ffi.new("int[1]")
    local buttons = sdl_ffi.SDL_GetMouseState(x, y)
    return x[0], y[0], buttons
end

-- OpenGL functions
function M.gl_set_attribute(attr, value)
    local result = sdl_ffi.SDL_GL_SetAttribute(attr, value)
    if result ~= 0 then
        error("SDL_GL_SetAttribute failed")
    end
end

function M.gl_create_context(window)
    local context = sdl_ffi.SDL_GL_CreateContext(window)
    if context == nil then
        error("SDL_GL_CreateContext failed")
    end
    return context
end

function M.gl_make_current(window, context)
    local result = sdl_ffi.SDL_GL_MakeCurrent(window, context)
    if result ~= 0 then
        error("SDL_GL_MakeCurrent failed")
    end
end

function M.gl_swap_window(window)
    sdl_ffi.SDL_GL_SwapWindow(window)
end

function M.gl_delete_context(context)
    sdl_ffi.SDL_GL_DeleteContext(context)
end

-- Timer functions
function M.delay(ms)
    sdl_ffi.SDL_Delay(ms)
end

-- Export event type constants
M.QUIT = sdl_ffi.SDL_QUIT
M.WINDOWEVENT = sdl_ffi.SDL_WINDOWEVENT
M.KEYDOWN = sdl_ffi.SDL_KEYDOWN
M.KEYUP = sdl_ffi.SDL_KEYUP
M.TEXTINPUT = sdl_ffi.SDL_TEXTINPUT
M.MOUSEMOTION = sdl_ffi.SDL_MOUSEMOTION
M.MOUSEBUTTONDOWN = sdl_ffi.SDL_MOUSEBUTTONDOWN
M.MOUSEBUTTONUP = sdl_ffi.SDL_MOUSEBUTTONUP

-- Window event constants
M.WINDOWEVENT_SIZE_CHANGED = sdl_ffi.SDL_WINDOWEVENT_SIZE_CHANGED

-- GL attribute constants
M.SDL_GL_DOUBLEBUFFER = sdl_ffi.SDL_GL_DOUBLEBUFFER
M.SDL_GL_DEPTH_SIZE = sdl_ffi.SDL_GL_DEPTH_SIZE

return M

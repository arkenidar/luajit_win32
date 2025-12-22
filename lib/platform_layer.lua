--[[
    Platform Abstraction Layer

    Provides a unified API for multiple backends:
    - win32: Native Windows GUI (user32.dll)
    - sdl2: Cross-platform SDL2 backend (default)
    - sdl3: Modern SDL3 backend

    Backend selection priority:
    1. Command-line: --backend=win32|sdl2|sdl3
    2. Environment variable: PLATFORM_BACKEND
    3. Config file: config.lua
    4. Platform default: sdl2 (all platforms)
]]

local ffi = require("ffi")

local M = {}

-- Detect backend from various sources
local function detect_backend()
    -- 1. Check command line arguments
    if arg then
        for i, argument in ipairs(arg) do
            local backend = argument:match("^%-%-backend=(.+)")
            if backend then
                return backend:lower()
            end
        end
    end

    -- 2. Check environment variable
    local env_backend = os.getenv("PLATFORM_BACKEND")
    if env_backend then
        return env_backend:lower()
    end

    -- 3. Check config file
    local ok, config = pcall(require, "config")
    if ok and config.backend then
        return config.backend:lower()
    end

    -- 4. Platform default: Win32 for now (SDL2 backend in development - Phase 3)
    -- TODO: Change to "sdl2" when SDL2 backend is complete
    return "win32"
end

-- Initialize and load the appropriate backend
function M.init()
    local backend_name = detect_backend()

    print(string.format("[Platform Layer] Detected backend: %s", backend_name))

    if backend_name == "win32" then
        M.backend = require("lib.backend.win32_backend")
    elseif backend_name == "sdl2" then
        M.backend = require("lib.backend.sdl2_backend")
    elseif backend_name == "sdl3" then
        M.backend = require("lib.backend.sdl3_backend")
    else
        error(string.format("Unknown backend: %s (valid options: win32, sdl2, sdl3)", backend_name))
    end

    -- Initialize the backend
    local ok, err = pcall(function()
        M.backend:init()
    end)

    if not ok then
        error(string.format("[Platform Layer] Backend initialization failed: %s", err))
    end

    print(string.format("[Platform Layer] Initialized backend: %s", M.backend:get_backend_name()))

    return M
end

-- Proxy all method calls to the loaded backend
setmetatable(M, {
    __index = function(t, k)
        if t.backend then
            local value = t.backend[k]
            if value ~= nil then
                return value
            end
        end
        error(string.format("Platform layer not initialized or method '%s' not found. Call platform_layer.init() first.", k))
    end
})

return M

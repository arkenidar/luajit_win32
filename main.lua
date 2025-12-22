-- main.lua
-- LuaJIT Multi-Backend GUI Application - To-Do List Manager
-- Entry point for the application
-- Supports Win32, SDL2, and SDL3 backends

-- Load required modules
local ffi = require("ffi")
local platform = require("lib.platform_layer")

-- Initialize platform layer (detects backend from CLI/env/config)
platform.init()

local app_module = require("lib.app")

-- Create application instance with platform reference
local app = app_module.TodoApp:new(platform)

-- Get backend name for window title
local backend_name = platform:get_backend_name()
local title = string.format("Task Manager - LuaJIT (%s backend)", backend_name:upper())

-- Create main window (800x450)
local window = platform:create_window(title, 800, 450, {})

-- Build UI
app:create_ui(window)

-- Set up event handlers
app:setup_handlers(window)

-- Add some sample tasks for demonstration
app:add_task("Welcome to LuaJIT Multi-Backend GUI!")
app:add_task("Try adding your own tasks")
app:add_task("Double-click to edit a task")
app:add_task(string.format("Currently using: %s", backend_name:upper()))

-- Run the event loop with the app's event handlers
local exit_code = platform:run_event_loop(window, app.event_handlers)

-- Exit with the event loop's return value
os.exit(exit_code)

-- main.lua
-- LuaJIT Win32 GUI Application - To-Do List Manager
-- Entry point for the application

-- Load required modules
local ffi = require("ffi")
local gui = require("lib.gui")
local app_module = require("lib.app")

-- Create application instance
local app = app_module.TodoApp:new()

-- Create main window (800x450)
local window = gui.Window:new("Task Manager - LuaJIT Win32 (with OpenGL)", 800, 450)

-- Build UI
app:create_ui(window)

-- Set up event handlers
app:setup_handlers(window)

-- Add some sample tasks for demonstration
app:add_task("Welcome to LuaJIT Win32 GUI!")
app:add_task("Try adding your own tasks")
app:add_task("Double-click to edit a task")

-- Run the message loop
local exit_code = window:run()

-- Exit with the message loop's return value
os.exit(exit_code)

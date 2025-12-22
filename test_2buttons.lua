-- Event loop test with 2 buttons
print("=== Event Loop Test (2 Buttons) ===")

local backend = require("lib.backend.sdl2_backend")
backend:init()

local window = backend:create_window("2 Button Test", 640, 480)

print("Creating button 1...")
local btn1 = backend:create_button(window, 50, 50, 150, 40, "Button 1")
print("Creating button 2...")
local btn2 = backend:create_button(window, 220, 50, 150, 40, "Button 2")
print("Creating button 3...")
local btn3 = backend:create_button(window, 390, 50, 150, 40, "Button 3")

print("Starting event loop...")

backend:run_event_loop(window, {
    on_create = function()
        print("   [Event] Window created")
    end,

    on_button_click = function(id)
        print("   [Event] Button clicked:", id)
    end,

    on_close = function()
        print("   [Event] Closing...")
    end
})

print("Done")
backend:destroy_window(window)

-- Event loop test with multiple controls
print("=== Event Loop Test (Multiple Controls) ===")

print("1. Loading backend...")
local backend = require("lib.backend.sdl2_backend")

print("2. Initializing...")
backend:init()

print("3. Creating window...")
local window = backend:create_window("Multi Control Test", 640, 480)

print("4. Creating controls...")
local btn1 = backend:create_button(window, 50, 50, 150, 40, "Button 1")
local btn2 = backend:create_button(window, 220, 50, 150, 40, "Button 2")
local btn3 = backend:create_button(window, 390, 50, 150, 40, "Button 3")

local lbl1 = backend:create_label(window, 50, 110, 500, 25, "Label 1")
local lbl2 = backend:create_label(window, 50, 140, 500, 25, "Label 2")
local lbl3 = backend:create_label(window, 50, 170, 500, 25, "Label 3")

print("5. Starting event loop (close window to exit)...")

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

print("6. Event loop finished")
backend:destroy_window(window)
print("✓ Test complete!")

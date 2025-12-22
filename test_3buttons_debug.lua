-- Event loop test with 3 buttons - debug version
print("=== Event Loop Test (3 Buttons Debug) ===")

local backend = require("lib.backend.sdl2_backend")
backend:init()

local window = backend:create_window("3 Button Test", 640, 480)

print("Creating button 1...")
local btn1 = backend:create_button(window, 50, 50, 150, 40, "Button 1")
print("  Button 1 ID:", btn1)

print("Creating button 2...")
local btn2 = backend:create_button(window, 220, 50, 150, 40, "Button 2")
print("  Button 2 ID:", btn2)

print("Creating button 3...")
local btn3 = backend:create_button(window, 390, 50, 150, 40, "Button 3")
print("  Button 3 ID:", btn3)

print("Window has", #window.controls, "controls")

-- Try a manual render before event loop
print("Testing manual render...")
window.dirty = true
window:render()
print("Manual render succeeded!")

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

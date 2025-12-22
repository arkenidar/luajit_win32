-- Event loop test
print("=== Event Loop Test ===")

print("1. Loading backend...")
local backend = require("lib.backend.sdl2_backend")

print("2. Initializing...")
backend:init()

print("3. Creating window...")
local window = backend:create_window("Event Loop Test", 640, 480)

print("4. Creating button...")
local btn = backend:create_button(window, 50, 50, 150, 40, "Click Me!")

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

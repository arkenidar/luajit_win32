-- Test with many controls like demo_cairo_simple
print("=== Many Controls Test ===")

local backend = require("lib.backend.sdl2_backend")
backend:init()

local window = backend:create_window("Many Controls Test", 800, 600)

print("Creating 8 buttons...")
for i = 1, 8 do
    backend:create_button(window, 40 + (i-1) * 95, 50, 90, 40, "Btn" .. i)
end

print("Creating 10 labels...")
for i = 1, 10 do
    backend:create_label(window, 40, 100 + (i-1) * 30, 700, 25, "Label " .. i)
end

print("Total controls:", #window.controls)

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

-- Cairo demo with just buttons (no listbox)
print("=== Cairo Buttons Demo ===")

local backend = require("lib.backend.sdl2_backend")
backend:init()

local window = backend:create_window("Cairo Buttons Demo", 800, 600)

print("Creating buttons...")
for i = 1, 8 do
    backend:create_button(window, 40 + (i-1) * 95, 50, 90, 40, "Btn" .. i)
end

print("Creating labels...")
for i = 1, 5 do
    backend:create_label(window, 40, 110 + (i-1) * 30, 700, 25, "Label " .. i)
end

print("Total controls:", #window.controls)

print("Rendering initial frame...")
window:render()
print("✓ Rendered!")

print("Starting event loop...")
backend:run_event_loop(window, {
    on_create = function()
        print("   [Event] Window created")
    end,
    on_button_click = function(id)
        print("   [Event] Button", id, "clicked")
    end,
    on_close = function()
        print("   [Event] Closing")
    end
})

print("Done")
backend:destroy_window(window)

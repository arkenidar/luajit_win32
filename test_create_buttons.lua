-- Test creating many buttons
print("=== Button Creation Test ===")

local backend = require("lib.backend.sdl2_backend")
backend:init()

local window = backend:create_window("Button Test", 800, 600)

print("Creating buttons...")
for i = 1, 10 do
    print("  Creating button", i, "...")
    local btn = backend:create_button(window, 40 + (i-1) * 80, 50, 75, 40, "Btn" .. i)
    print("  Created with ID:", btn)
end

print("Total controls:", #window.controls)
print("Done - no event loop")

backend:destroy_window(window)
print("Cleaned up")

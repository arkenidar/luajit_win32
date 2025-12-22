-- Test creating many labels
print("=== Label Creation Test ===")

local backend = require("lib.backend.sdl2_backend")
backend:init()

local window = backend:create_window("Label Test", 800, 600)

print("Creating labels...")
for i = 1, 20 do
    print("  Creating label", i, "...")
    local label = backend:create_label(window, 40, 100 + (i-1) * 30, 700, 25, "Label " .. i)
    print("  Created with ID:", label)
end

print("Total controls:", #window.controls)
print("Done - no event loop")

backend:destroy_window(window)
print("Cleaned up")

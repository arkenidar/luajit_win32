-- Simple render test
print("=== Simple Render Test ===")

print("1. Loading backend...")
local backend = require("lib.backend.sdl2_backend")

print("2. Initializing...")
backend:init()

print("3. Creating window...")
local window = backend:create_window("Simple Test", 640, 480)

print("4. Creating one button...")
local btn = backend:create_button(window, 50, 50, 100, 30, "Test")

print("5. Rendering once...")
window:render()

print("6. Done!")
print("✓ Render successful!")

-- Cleanup
print("7. Destroying window...")
backend:destroy_window(window)
print("✓ Test complete!")

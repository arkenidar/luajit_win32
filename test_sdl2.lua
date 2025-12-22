-- test_sdl2.lua
-- Test SDL2 base abstraction layer

local ffi = require("ffi")
local sdl = require("lib.sdl_base.sdl_api")

print("=== SDL2 Base Abstraction Test ===")

-- Test 1: Initialize SDL
print("\n1. Initializing SDL...")
sdl.init()
print("   ✓ SDL initialized successfully")

-- Test 2: Create window
print("\n2. Creating window...")
local window = sdl.create_window("SDL2 Test Window", nil, nil, 640, 480, {resizable = true})
print("   ✓ Window created successfully")

-- Test 3: Get window surface
print("\n3. Getting window surface...")
local surface = sdl.get_window_surface(window)
print(string.format("   ✓ Surface obtained: %dx%d, pitch=%d",
    surface.w, surface.h, surface.pitch))

-- Test 4: Fill surface with color (blue)
print("\n4. Filling surface with blue color...")
local pixels = ffi.cast("uint32_t*", surface.pixels)
local num_pixels = surface.w * surface.h
for i = 0, num_pixels - 1 do
    pixels[i] = 0xFF0000FF  -- ARGB: blue
end
print("   ✓ Surface filled")

-- Test 5: Update window
print("\n5. Updating window surface...")
sdl.update_window_surface(window)
print("   ✓ Surface updated (window should be blue)")

-- Test 6: Event loop (run for 3 seconds)
print("\n6. Testing event loop (will run for 3 seconds)...")
print("   Try resizing the window or moving the mouse...")

local event = ffi.new("SDL_Event")
local start_time = os.time()
local event_count = 0

while os.time() - start_time < 3 do
    while sdl.poll_event(event) ~= 0 do
        event_count = event_count + 1

        if event.type == sdl.QUIT then
            print("   - QUIT event received")
            goto cleanup
        elseif event.type == sdl.WINDOWEVENT then
            if event.window.event == sdl.WINDOWEVENT_SIZE_CHANGED then
                print(string.format("   - Window resized: %dx%d",
                    event.window.data1, event.window.data2))
            end
        elseif event.type == sdl.MOUSEMOTION then
            -- Silent - too many events
        elseif event.type == sdl.MOUSEBUTTONDOWN then
            print(string.format("   - Mouse button down at %d,%d",
                event.button.x, event.button.y))
        end
    end

    -- Small delay to prevent 100% CPU
    sdl.delay(16)  -- ~60 FPS
end

print(string.format("   ✓ Event loop completed (%d events processed)", event_count))

::cleanup::

-- Test 7: Cleanup
print("\n7. Cleaning up...")
sdl.destroy_window(window)
sdl.quit()
print("   ✓ Resources freed")

print("\n=== SDL2 Base Abstraction Test Complete ===")
print("✓ All tests passed!")
print("\nSDL2 is ready for backend implementation (Phase 3).")

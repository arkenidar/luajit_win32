-- test_sdl2_backend.lua
-- Test SDL2 backend with Cairo-rendered widgets

print("=== SDL2 Backend Test ===")

-- Test 1: Initialize backend
print("\n1. Initializing SDL2 backend...")
local backend = require("lib.backend.sdl2_backend")
backend:init()
print("   ✓ Backend initialized:", backend:get_backend_name())

-- Test 2: Create window
print("\n2. Creating window...")
local window = backend:create_window("SDL2 Backend Test", 640, 480)
print("   ✓ Window created")

-- Test 3: Create controls
print("\n3. Creating controls...")

local btn1 = backend:create_button(window, 50, 50, 100, 30, "Button 1")
print("   ✓ Button 1 created (ID:", btn1, ")")

local btn2 = backend:create_button(window, 170, 50, 100, 30, "Button 2")
print("   ✓ Button 2 created (ID:", btn2, ")")

local label = backend:create_label(window, 50, 100, 200, 20, "This is a label")
print("   ✓ Label created (ID:", label, ")")

local edit = backend:create_edit(window, 50, 130, 200, 25, "Edit text here")
print("   ✓ Edit control created (ID:", edit, ")")

local listbox = backend:create_listbox(window, 50, 170, 200, 150)
print("   ✓ Listbox created (ID:", listbox, ")")

-- Test 4: Add items to listbox
print("\n4. Adding items to listbox...")
backend:listbox_add_item(listbox, "Item 1")
backend:listbox_add_item(listbox, "Item 2")
backend:listbox_add_item(listbox, "Item 3")
backend:listbox_add_item(listbox, "Item 4")
backend:listbox_add_item(listbox, "Item 5")
backend:listbox_set_selection(listbox, 1)
print(string.format("   ✓ Added %d items, selected index 1", backend:listbox_get_count(listbox)))

-- Test 5: Control manipulation
print("\n5. Testing control manipulation...")
backend:set_control_text(btn1, "Clicked!")
print("   ✓ Button text changed to:", backend:get_control_text(btn1))

-- Test 6: Event loop with handlers
print("\n6. Starting event loop...")
print("   Instructions:")
print("   - Try clicking the buttons")
print("   - Try resizing the window")
print("   - Close the window to exit")

local click_count = 0
local resize_count = 0

local exit_code = backend:run_event_loop(window, {
    on_create = function()
        print("   [Event] Window created")
    end,

    on_button_click = function(control_id)
        click_count = click_count + 1
        print(string.format("   [Event] Button %d clicked (total clicks: %d)", control_id, click_count))

        if control_id == btn1 then
            backend:set_control_text(btn1, "Clicked " .. click_count .. "x!")
        elseif control_id == btn2 then
            backend:set_control_text(label, "Button 2 was clicked!")
        end
    end,

    on_listbox_select = function(control_id)
        local sel = backend:listbox_get_selection(control_id)
        local text = backend:listbox_get_item_text(control_id, sel)
        print(string.format("   [Event] Listbox item selected: %s (index %d)", text, sel))
    end,

    on_resize = function(w, h)
        resize_count = resize_count + 1
        print(string.format("   [Event] Window resized: %dx%d (resize count: %d)", w, h, resize_count))
    end,

    on_close = function()
        print("   [Event] Window closing")
    end,

    on_destroy = function()
        print("   [Event] Window destroyed")
    end
})

-- Test 7: Cleanup
print("\n7. Cleaning up...")
backend:destroy_window(window)
print("   ✓ Window destroyed")

print("\n=== SDL2 Backend Test Complete ===")
print(string.format("Exit code: %d", exit_code))
print(string.format("Total button clicks: %d", click_count))
print(string.format("Total window resizes: %d", resize_count))
print("\n✓ All tests passed!")
print("\nSDL2 backend is functional with Cairo rendering.")

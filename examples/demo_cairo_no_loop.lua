-- demo_cairo_no_loop.lua
-- Cairo demo without event loop (single render only)

print("=== Cairo Graphics Showcase (Single Render) ===")
print("")

local backend = require("lib.backend.sdl2_backend")
backend:init()

local window = backend:create_window("Cairo Vector Graphics - Single Render", 800, 600)

print("Creating showcase elements...")

-- Title and features
backend:create_label(window, 20, 20, 760, 40, "🎨 Cairo Vector Graphics Showcase")
backend:create_label(window, 40, 80, 720, 25, "✓ Anti-aliased vector graphics")
backend:create_label(window, 40, 110, 720, 25, "✓ Smooth rounded rectangles")
backend:create_label(window, 40, 140, 720, 25, "✓ Perfect circles and arcs")

-- Buttons
backend:create_button(window, 40, 200, 135, 50, "Red")
backend:create_button(window, 185, 200, 135, 50, "Blue")
backend:create_button(window, 330, 200, 135, 50, "Green")

backend:create_button(window, 40, 270, 230, 60, "🚀 Launch")
backend:create_button(window, 285, 270, 230, 60, "⚙️ Settings")
backend:create_button(window, 530, 270, 230, 60, "💾 Save")

-- Listbox
local listbox = backend:create_listbox(window, 40, 350, 350, 200)
backend:listbox_add_item(listbox, "📄 Vector Graphics Demo")
backend:listbox_add_item(listbox, "🎨 Anti-aliasing Example")
backend:listbox_add_item(listbox, "📐 Geometric Shapes")
backend:listbox_set_selection(listbox, 1)

-- Info
backend:create_label(window, 410, 350, 350, 25, "Cairo + SDL2 + LuaJIT")
backend:create_label(window, 410, 380, 350, 25, "Vector Graphics Rendering")

print("✓ Elements created!")
print("")
print("Rendering...")

-- Single render
window:render()

print("✓ Rendered successfully!")
print("")
print("Features demonstrated:")
print("  ✓ 6 buttons with rounded corners")
print("  ✓ Anti-aliased text")
print("  ✓ Listbox with 3 items")
print("  ✓ All vector graphics!")
print("")

-- Cleanup immediately
backend:destroy_window(window)
print("✓ Demo complete!")

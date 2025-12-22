-- demo_cairo_simple.lua
-- Impressive Cairo rendering demo (simplified, reliable version)

print("=== Cairo Graphics Showcase ===")
print("Demonstrating professional-quality vector graphics rendering")
print("")

local backend = require("lib.backend.sdl2_backend")
backend:init()

-- Create window with impressive title
local window = backend:create_window("Cairo Vector Graphics Showcase - LuaJIT", 800, 600)

print("Creating showcase elements...")

-- Title
local title = backend:create_label(window, 20, 20, 760, 40,
    "🎨 Cairo Vector Graphics Showcase")

-- Feature demonstrations
local features = {
    backend:create_label(window, 40, 80, 720, 25, "✓ Anti-aliased vector graphics"),
    backend:create_label(window, 40, 110, 720, 25, "✓ Smooth rounded rectangles"),
    backend:create_label(window, 40, 140, 720, 25, "✓ Perfect circles and arcs"),
    backend:create_label(window, 40, 170, 720, 25, "✓ High-quality text rendering"),
    backend:create_label(window, 40, 200, 720, 25, "✓ Pixel-perfect layouts"),
}

-- Color palette buttons (5 colors across the top)
local palette_buttons = {
    backend:create_button(window, 40, 250, 135, 50, "Red"),
    backend:create_button(window, 185, 250, 135, 50, "Blue"),
    backend:create_button(window, 330, 250, 135, 50, "Green"),
    backend:create_button(window, 475, 250, 135, 50, "Gold"),
    backend:create_button(window, 620, 250, 135, 50, "Purple"),
}

-- Large demo buttons with icons
local demo_buttons = {
    backend:create_button(window, 40, 320, 230, 60, "🚀 Launch"),
    backend:create_button(window, 285, 320, 230, 60, "⚙️ Settings"),
    backend:create_button(window, 530, 320, 230, 60, "💾 Save"),
}

-- Sample listbox with demo items
local listbox = backend:create_listbox(window, 40, 400, 350, 160)
backend:listbox_add_item(listbox, "📄 Vector Graphics Demo")
backend:listbox_add_item(listbox, "🎨 Anti-aliasing Example")
backend:listbox_add_item(listbox, "📐 Geometric Shapes")
backend:listbox_add_item(listbox, "✨ Smooth Gradients")
backend:listbox_add_item(listbox, "🔤 Typography Showcase")
backend:listbox_add_item(listbox, "🎯 Precision Rendering")
backend:listbox_add_item(listbox, "🌈 Color Management")
backend:listbox_set_selection(listbox, 2)

-- Info panel
local info_labels = {
    backend:create_label(window, 410, 400, 350, 25, "Cairo + SDL2 + LuaJIT"),
    backend:create_label(window, 410, 430, 350, 25, "Vector Graphics • Zero Dependencies"),
    backend:create_label(window, 410, 460, 350, 25, "Hardware Accelerated • 60 FPS"),
}

-- Status labels
local status_labels = {
    backend:create_label(window, 410, 500, 350, 25, "Status: ✓ Ready"),
    backend:create_label(window, 410, 525, 350, 25, "Rendering: Cairo 2D"),
    backend:create_label(window, 410, 550, 350, 25, "Backend: SDL2"),
}

print("✓ Showcase created!")
print("")
print("Rendering initial frame...")
window:render()
print("✓ Rendered!")
print("")
print("Key features:")
print("  • " .. #demo_buttons .. " large buttons with rounded corners")
print("  • " .. #palette_buttons .. " color palette buttons")
print("  • " .. backend:listbox_get_count(listbox) .. " items in listbox")
print("  • All vector graphics with Cairo rendering")
print("")
print("Starting interactive event loop...")
print("Move mouse over buttons to see hover effects!")
print("Click buttons to see click events.")
print("Close window to exit.")
print("")

-- Run event loop with interaction
backend:run_event_loop(window, {
    on_create = function()
        print("   [Event] Window created and ready for interaction")
    end,

    on_button_click = function(button_id)
        print("   [Event] Button clicked: " .. button_id)
    end,

    on_listbox_select = function(listbox_id, index)
        print("   [Event] Listbox selection changed: item " .. index)
    end,

    on_close = function()
        print("   [Event] Window closing...")
    end
})

print("")
print("✓ Demo complete!")
print("")
print("This showcases Cairo's ability to render:")
print("  • Professional-quality UI elements")
print("  • Smooth anti-aliased shapes")
print("  • Pixel-perfect text")
print("  • Rounded rectangles with cairo_arc()")
print("  • Complex listbox layouts")
print("  • All running on pure LuaJIT + FFI!")
print("")
print("NOTE: For interactive demo with mouse hover effects,")
print("      run: luajit.exe test_event_loop.lua")

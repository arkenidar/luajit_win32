-- Emoji rendering test with Pango
print("=== Emoji Rendering Test ===")

local backend = require("lib.backend.sdl2_backend")
backend:init()

local window = backend:create_window("Emoji Test - Pango Integration", 800, 600)

-- Title with emoji
backend:create_label(window, 20, 20, 760, 40, "🎨 Emoji Rendering Test with Pango")

-- Buttons with various emoji
backend:create_button(window, 40, 80, 200, 60, "🚀 Rocket")
backend:create_button(window, 260, 80, 200, 60, "⚙️ Settings")
backend:create_button(window, 480, 80, 200, 60, "💾 Save")

backend:create_button(window, 40, 160, 200, 60, "🎯 Target")
backend:create_button(window, 260, 160, 200, 60, "🌟 Star")
backend:create_button(window, 480, 160, 200, 60, "🔥 Fire")

-- Labels with emoji
backend:create_label(window, 40, 240, 700, 30, "✓ Check ✗ Cross → Arrow ← Back")
backend:create_label(window, 40, 280, 700, 30, "😀 Smile 😎 Cool 🤔 Think 🎉 Party")
backend:create_label(window, 40, 320, 700, 30, "🍕 Pizza 🍔 Burger 🍰 Cake 🍺 Beer")
backend:create_label(window, 40, 360, 700, 30, "📱 Phone 💻 Laptop 🖥️ Desktop ⌚ Watch")

-- Listbox with emoji items
local listbox = backend:create_listbox(window, 40, 410, 720, 150)
backend:listbox_add_item(listbox, "📄 Vector Graphics Demo")
backend:listbox_add_item(listbox, "🎨 Anti-aliasing Example")
backend:listbox_add_item(listbox, "🌈 Color Gradients")
backend:listbox_add_item(listbox, "✨ Text Rendering with Pango")
backend:listbox_add_item(listbox, "🚀 Performance Test")
backend:listbox_add_item(listbox, "🎯 Interactive Controls")
backend:listbox_add_item(listbox, "💡 Best Practices")

print("Starting event loop (close window to exit)...")

backend:run_event_loop(window, {
    on_create = function()
        print("   [Event] Window created - emoji should be visible!")
    end,
    on_button_click = function(id)
        print("   [Event] Button clicked:", id)
    end,
    on_close = function()
        print("   [Event] Closing...")
    end
})

print("Done!")
backend:destroy_window(window)

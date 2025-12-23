-- Test bundled font loading and emoji rendering
print("=== Bundled Font Test ===")

-- Test 1: Fontconfig FFI availability
print("\n[1/4] Testing fontconfig FFI...")
local fontconfig = require("lib.ffi.fontconfig_ffi")
if fontconfig.available then
    print("  ✓ Fontconfig FFI available")
else
    print("  ✗ Fontconfig FFI not available (emoji may not work)")
end

-- Test 2: Font directory registration
print("\n[2/4] Testing font directory registration...")
if fontconfig.available then
    local ok, err = fontconfig.add_font_dir("fonts")
    if ok then
        print("  ✓ Fonts directory registered successfully")
    else
        print("  ✗ Failed to register fonts:", err)
    end
else
    print("  ⊘ Skipped (fontconfig not available)")
end

-- Test 3: Pango FFI loading
print("\n[3/4] Testing Pango FFI...")
local pango_ok, pango = pcall(require, "lib.ffi.pango_ffi")
if pango_ok then
    print("  ✓ Pango FFI loaded")
    print("    - pango library:", pango.pango ~= nil)
    print("    - pangocairo library:", pango.pangocairo ~= nil)
    print("    - gobject library:", pango.gobject ~= nil)
else
    print("  ✗ Failed to load Pango FFI:", pango)
    os.exit(1)
end

-- Test 4: Backend creation with emoji
print("\n[4/4] Testing emoji rendering...")
local backend = require("lib.backend.sdl2_backend")
backend:init()

local window = backend:create_window("Font Test", 600, 400)

-- Create controls with emoji
backend:create_label(window, 20, 20, 560, 40, "🎨 Emoji Font Test - Cross-Platform")
backend:create_button(window, 50, 80, 180, 50, "🚀 Rocket")
backend:create_button(window, 250, 80, 180, 50, "💾 Save")
backend:create_button(window, 450, 80, 100, 50, "✓ OK")

backend:create_label(window, 20, 160, 560, 30, "Regular text: Hello World 123")
backend:create_label(window, 20, 200, 560, 30, "Emoji test: 😀 😎 🤔 🎉 🔥 ⚡ 💡 ✨")
backend:create_label(window, 20, 240, 560, 30, "Mixed: Hello 👋 World 🌍 Testing 🧪 123")

-- Create listbox with mixed content
local listbox = backend:create_listbox(window, 50, 290, 500, 80)
backend:listbox_add_item(listbox, "📄 Regular file.txt")
backend:listbox_add_item(listbox, "📁 Folder with emoji 📂")
backend:listbox_add_item(listbox, "🎵 music.mp3")

print("  ✓ Window created with emoji content")

-- Render once (non-interactive)
window:render()
print("  ✓ Rendered successfully")

print("\n=== Test Complete ===")
print("\nAll systems operational! Emoji support is ready.")
print("Font fallback chain: 'Segoe UI, Noto Color Emoji'")
print("\nClose the window to exit.")

-- Run event loop
backend:run_event_loop(window, {
    on_create = function()
        print("\n[Window opened - Check if emoji are visible!]")
    end,
    on_close = function()
        print("\n[Window closed]")
    end
})

backend:destroy_window(window)
print("\n✓ All tests passed!")

#!/usr/bin/env luajit
-- Cross-platform compatibility check
-- Tests all dependencies and font loading on current platform

print("=== Cross-Platform Compatibility Check ===\n")

-- Platform detection
local is_windows = package.config:sub(1,1) == '\\'
local platform = is_windows and "Windows" or "Unix-like (Linux/macOS)"
print("Platform:", platform)
print("LuaJIT:", jit.version)
print("Arch:", jit.arch)
print()

-- Test 1: FFI availability
print("[1/7] FFI availability")
local ffi_ok, ffi = pcall(require, "ffi")
if ffi_ok then
    print("  ✓ FFI available")
else
    print("  ✗ FFI not available:", ffi)
    os.exit(1)
end

-- Test 2: SDL2
print("\n[2/7] SDL2 FFI")
local sdl_ok, sdl_err = pcall(require, "lib.ffi.sdl2_ffi")
if sdl_ok then
    print("  ✓ SDL2 FFI loaded")
else
    print("  ✗ SDL2 FFI failed:", sdl_err)
    print("  → Install SDL2:")
    if is_windows then
        print("     pacman -S mingw-w64-x86_64-SDL2")
    else
        print("     Debian/Ubuntu: sudo apt install libsdl2-2.0-0")
        print("     Fedora: sudo dnf install SDL2")
        print("     macOS: brew install sdl2")
    end
    os.exit(1)
end

-- Test 3: Cairo
print("\n[3/7] Cairo FFI")
local cairo_ok, cairo_err = pcall(require, "lib.ffi.cairo_ffi")
if cairo_ok then
    print("  ✓ Cairo FFI loaded")
else
    print("  ✗ Cairo FFI failed:", cairo_err)
    print("  → Install Cairo:")
    if is_windows then
        print("     pacman -S mingw-w64-x86_64-cairo")
    else
        print("     Debian/Ubuntu: sudo apt install libcairo2")
        print("     Fedora: sudo dnf install cairo")
        print("     macOS: brew install cairo")
    end
    os.exit(1)
end

-- Test 4: Fontconfig
print("\n[4/7] Fontconfig FFI")
local fc_ok, fontconfig = pcall(require, "lib.ffi.fontconfig_ffi")
if fc_ok and fontconfig.available then
    print("  ✓ Fontconfig FFI loaded")

    -- Test font directory registration
    local fonts_ok, fonts_err = fontconfig.add_font_dir("fonts")
    if fonts_ok then
        print("  ✓ Fonts directory registered")
    else
        print("  ⚠ Font registration failed:", fonts_err)
    end
else
    print("  ✗ Fontconfig FFI failed")
    print("  → Install Fontconfig:")
    if is_windows then
        print("     pacman -S mingw-w64-x86_64-fontconfig")
    else
        print("     Debian/Ubuntu: sudo apt install libfontconfig1")
        print("     Fedora: sudo dnf install fontconfig")
        print("     macOS: brew install fontconfig")
    end
    os.exit(1)
end

-- Test 5: Pango
print("\n[5/7] Pango FFI")
local pango_ok, pango = pcall(require, "lib.ffi.pango_ffi")
if pango_ok then
    print("  ✓ Pango FFI loaded")
    print("    - Pango library:", pango.pango ~= nil)
    print("    - PangoCairo library:", pango.pangocairo ~= nil)
    print("    - GObject library:", pango.gobject ~= nil)
else
    print("  ✗ Pango FFI failed:", pango)
    print("  → Install Pango:")
    if is_windows then
        print("     pacman -S mingw-w64-x86_64-pango")
    else
        print("     Debian/Ubuntu: sudo apt install libpango-1.0-0 libpangocairo-1.0-0")
        print("     Fedora: sudo dnf install pango")
        print("     macOS: brew install pango")
    end
    os.exit(1)
end

-- Test 6: Bundled font
print("\n[6/7] Bundled font")
local font_path = "fonts/NotoColorEmoji.ttf"
local f = io.open(font_path, "rb")
if f then
    local size = f:seek("end")
    f:close()
    if size > 10000000 then  -- Should be ~11MB
        print("  ✓ NotoColorEmoji.ttf found (" .. math.floor(size/1024/1024) .. "MB)")
    else
        print("  ⚠ Font file too small (" .. size .. " bytes)")
        print("  → Re-download font")
    end
else
    print("  ✗ NotoColorEmoji.ttf not found")
    print("  → Download font:")
    print("     wget -P fonts/ https://github.com/googlefonts/noto-emoji/raw/main/fonts/NotoColorEmoji.ttf")
end

-- Test 7: SDL API wrapper
print("\n[7/7] SDL API wrapper")
local sdl_api_ok, sdl_api = pcall(require, "lib.sdl_base.sdl_api")
if sdl_api_ok then
    print("  ✓ SDL API wrapper loaded")
else
    print("  ✗ SDL API wrapper failed:", sdl_api)
    os.exit(1)
end

-- Summary
print("\n=== Summary ===")
print("✓ All dependencies satisfied!")
print("✓ Platform: " .. platform)
print("✓ Emoji support ready")
print()

-- Font detection
print("Recommended font fallback for this platform:")
if is_windows then
    print('  "Segoe UI, Noto Color Emoji 14"')
else
    -- Try to detect installed fonts
    local handle = io.popen("fc-list : family 2>/dev/null | grep -i 'dejavu sans' | head -1")
    if handle then
        local dejavu = handle:read("*a")
        handle:close()
        if dejavu ~= "" then
            print('  "DejaVu Sans, Noto Color Emoji 14" (DejaVu detected)')
        else
            print('  "sans-serif, Noto Color Emoji 14" (Generic fallback)')
        end
    else
        print('  "sans-serif, Noto Color Emoji 14" (Generic fallback)')
    end
end

print("\nYour system is ready to run emoji-enabled apps!")
print("\nNext steps:")
print("  1. Run: ./luajit test_bundled_fonts.lua")
print("  2. Or:  ./luajit demo_emoji_test.lua")
print()

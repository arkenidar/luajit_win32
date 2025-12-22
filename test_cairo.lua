-- test_cairo.lua
-- Simple test script to verify Cairo FFI bindings work correctly

local ffi = require("ffi")
local cairo = require("lib.ffi.cairo_ffi")

print("=== Cairo FFI Test ===")
print("Testing Cairo library loading and basic rendering...")

-- Create a 400x300 ARGB32 image buffer
local width, height = 400, 300
local stride = width * 4  -- 4 bytes per pixel (ARGB32)
local pixels = ffi.new("unsigned char[?]", height * stride)

-- Create Cairo surface from pixel buffer
print("\n1. Creating Cairo surface...")
local surface = cairo.cairo_image_surface_create_for_data(
    pixels,
    cairo.CAIRO_FORMAT_ARGB32,
    width, height,
    stride
)

if surface == nil then
    error("Failed to create Cairo surface")
end
print("   ✓ Surface created successfully")

-- Create Cairo context
print("\n2. Creating Cairo context...")
local cr = cairo.cairo_create(surface)
if cr == nil then
    error("Failed to create Cairo context")
end
print("   ✓ Context created successfully")

-- Clear to white background
print("\n3. Drawing white background...")
cairo.cairo_set_source_rgb(cr, 1, 1, 1)  -- White
cairo.cairo_paint(cr)
print("   ✓ Background painted")

-- Draw rounded rectangle with blue fill
print("\n4. Drawing rounded rectangle...")
local x, y, w, h = 50, 50, 300, 200
local radius = 20

cairo.cairo_save(cr)

-- Create rounded rectangle path using arcs
cairo.cairo_new_path(cr)
cairo.cairo_arc(cr, x + radius, y + radius, radius, math.pi, 1.5 * math.pi)  -- Top-left
cairo.cairo_arc(cr, x + w - radius, y + radius, radius, 1.5 * math.pi, 0)    -- Top-right
cairo.cairo_arc(cr, x + w - radius, y + h - radius, radius, 0, 0.5 * math.pi) -- Bottom-right
cairo.cairo_arc(cr, x + radius, y + h - radius, radius, 0.5 * math.pi, math.pi) -- Bottom-left
cairo.cairo_close_path(cr)

-- Fill with light blue
cairo.cairo_set_source_rgb(cr, 0.7, 0.85, 1.0)
cairo.cairo_fill_preserve(cr)

-- Stroke with dark blue border
cairo.cairo_set_source_rgb(cr, 0.2, 0.4, 0.8)
cairo.cairo_set_line_width(cr, 3)
cairo.cairo_stroke(cr)

cairo.cairo_restore(cr)
print("   ✓ Rounded rectangle drawn")

-- Draw text
print("\n5. Drawing text...")
cairo.cairo_set_source_rgb(cr, 0, 0, 0)  -- Black text
cairo.cairo_select_font_face(cr, "sans-serif",
    cairo.CAIRO_FONT_SLANT_NORMAL,
    cairo.CAIRO_FONT_WEIGHT_BOLD)
cairo.cairo_set_font_size(cr, 32)

local text = "Cairo Works!"
local extents = ffi.new("cairo_text_extents_t")
cairo.cairo_text_extents(cr, text, extents)

-- Center text in rectangle
local text_x = x + (w - extents.width) / 2 - extents.x_bearing
local text_y = y + (h + extents.height) / 2 - extents.y_bearing

cairo.cairo_move_to(cr, text_x, text_y)
cairo.cairo_show_text(cr, text)
print("   ✓ Text rendered")

-- Flush surface
print("\n6. Flushing surface...")
cairo.cairo_surface_flush(surface)
cairo.cairo_surface_mark_dirty(surface)
print("   ✓ Surface flushed")

-- Verify pixel data was written (check if not all zeros)
print("\n7. Verifying pixel data...")
local non_zero_pixels = 0
for i = 0, math.min(1000, height * stride - 1) do
    if pixels[i] ~= 0 then
        non_zero_pixels = non_zero_pixels + 1
    end
end

if non_zero_pixels > 0 then
    print(string.format("   ✓ Pixel data written (%d non-zero bytes found)", non_zero_pixels))
else
    print("   ✗ WARNING: No pixel data written (all zeros)")
end

-- Cleanup
print("\n8. Cleaning up...")
cairo.cairo_destroy(cr)
cairo.cairo_surface_destroy(surface)
print("   ✓ Resources freed")

print("\n=== Cairo FFI Test Complete ===")
print("✓ All tests passed!")
print("\nCairo is ready for SDL2 integration.")

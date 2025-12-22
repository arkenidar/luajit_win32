-- demo_cairo_advanced.lua
-- Advanced Cairo rendering demo with custom vector graphics

print("=== Advanced Cairo Vector Graphics Demo ===")
print("Showcasing custom Cairo primitives and effects")
print("")

local ffi = require("ffi")
local backend = require("lib.backend.sdl2_backend")
local cairo = require("lib.ffi.cairo_ffi")

backend:init()

-- Create window
local window = backend:create_window("Advanced Cairo Demo - Custom Primitives", 800, 600)

-- Create standard widgets
local title = backend:create_label(window, 20, 20, 760, 40,
    "🎨 Advanced Cairo Vector Graphics")

local subtitle = backend:create_label(window, 20, 50, 760, 25,
    "Custom primitives, gradients, and effects")

-- Demo controls
local btn1 = backend:create_button(window, 50, 100, 180, 50, "Gradients")
local btn2 = backend:create_button(window, 250, 100, 180, 50, "Patterns")
local btn3 = backend:create_button(window, 450, 100, 180, 50, "Transforms")

print("Creating custom Cairo graphics...")

-- Custom rendering function that adds Cairo primitives AFTER standard rendering
local function render_custom_cairo(window_obj)
    local cr = window_obj.cairo_ctx

    -- 1. Draw gradient-filled rounded rectangle
    print("  ✓ Drawing linear gradient rectangle...")
    local x, y, w, h = 50, 180, 200, 120
    local radius = 15

    -- Create rounded rectangle path
    cairo.cairo_new_path(cr)
    cairo.cairo_arc(cr, x + radius, y + radius, radius, math.pi, 3*math.pi/2)
    cairo.cairo_arc(cr, x + w - radius, y + radius, radius, 3*math.pi/2, 0)
    cairo.cairo_arc(cr, x + w - radius, y + h - radius, radius, 0, math.pi/2)
    cairo.cairo_arc(cr, x + radius, y + h - radius, radius, math.pi/2, math.pi)
    cairo.cairo_close_path(cr)

    -- Fill with linear gradient
    local pattern = cairo.cairo_pattern_create_linear(x, y, x, y + h)
    cairo.cairo_pattern_add_color_stop_rgba(pattern, 0, 0.2, 0.6, 1.0, 1.0)
    cairo.cairo_pattern_add_color_stop_rgba(pattern, 1, 0.1, 0.3, 0.6, 1.0)
    cairo.cairo_set_source(cr, pattern)
    cairo.cairo_fill_preserve(cr)
    cairo.cairo_pattern_destroy(pattern)

    -- Add border
    cairo.cairo_set_source_rgb(cr, 0.1, 0.2, 0.4)
    cairo.cairo_set_line_width(cr, 3)
    cairo.cairo_stroke(cr)

    -- Add text label
    cairo.cairo_set_source_rgb(cr, 1, 1, 1)
    cairo.cairo_select_font_face(cr, "Sans", cairo.CAIRO_FONT_SLANT_NORMAL, cairo.CAIRO_FONT_WEIGHT_BOLD)
    cairo.cairo_set_font_size(cr, 18)
    cairo.cairo_move_to(cr, x + 25, y + h/2 + 5)
    cairo.cairo_show_text(cr, "Linear Gradient")

    -- 2. Draw radial gradient circle
    print("  ✓ Drawing radial gradient circles...")
    local cx, cy, r = 380, 240, 50

    cairo.cairo_arc(cr, cx, cy, r, 0, 2*math.pi)
    local radial = cairo.cairo_pattern_create_radial(cx - 15, cy - 15, 10, cx, cy, r)
    cairo.cairo_pattern_add_color_stop_rgba(radial, 0, 1.0, 0.9, 0.3, 1.0)
    cairo.cairo_pattern_add_color_stop_rgba(radial, 1, 0.8, 0.3, 0.1, 1.0)
    cairo.cairo_set_source(cr, radial)
    cairo.cairo_fill(cr)
    cairo.cairo_pattern_destroy(radial)

    -- 3. Draw star shape with path
    print("  ✓ Drawing custom star path...")
    local star_cx, star_cy = 550, 240
    local outer_r, inner_r = 45, 20
    local points = 5

    cairo.cairo_new_path(cr)
    for i = 0, points * 2 - 1 do
        local angle = (i * math.pi / points) - math.pi / 2
        local r = (i % 2 == 0) and outer_r or inner_r
        local x = star_cx + r * math.cos(angle)
        local y = star_cy + r * math.sin(angle)

        if i == 0 then
            cairo.cairo_move_to(cr, x, y)
        else
            cairo.cairo_line_to(cr, x, y)
        end
    end
    cairo.cairo_close_path(cr)

    cairo.cairo_set_source_rgb(cr, 0.9, 0.2, 0.3)
    cairo.cairo_fill_preserve(cr)
    cairo.cairo_set_source_rgb(cr, 0.5, 0.1, 0.2)
    cairo.cairo_set_line_width(cr, 2)
    cairo.cairo_stroke(cr)

    -- 4. Draw semi-transparent overlapping circles
    print("  ✓ Drawing alpha-blended circles...")
    local colors = {
        {0.9, 0.2, 0.2, 0.6},  -- Red
        {0.2, 0.9, 0.2, 0.6},  -- Green
        {0.2, 0.2, 0.9, 0.6},  -- Blue
    }

    local base_x, base_y = 150, 380
    for i, color in ipairs(colors) do
        local offset_x = (i - 1) * 40
        cairo.cairo_arc(cr, base_x + offset_x, base_y, 40, 0, 2*math.pi)
        cairo.cairo_set_source_rgba(cr, color[1], color[2], color[3], color[4])
        cairo.cairo_fill(cr)
    end

    -- 5. Draw bezier curves
    print("  ✓ Drawing Bézier curves...")
    cairo.cairo_set_source_rgb(cr, 0.3, 0.6, 0.9)
    cairo.cairo_set_line_width(cr, 4)
    cairo.cairo_move_to(cr, 400, 350)
    cairo.cairo_curve_to(cr, 450, 320, 500, 420, 550, 350)
    cairo.cairo_stroke(cr)

    cairo.cairo_set_source_rgb(cr, 0.9, 0.5, 0.2)
    cairo.cairo_move_to(cr, 400, 380)
    cairo.cairo_curve_to(cr, 450, 450, 500, 310, 550, 380)
    cairo.cairo_stroke(cr)

    -- 6. Draw decorative border with alpha
    print("  ✓ Drawing decorative border...")
    for i = 0, 15 do
        local x = 20 + i * 48
        cairo.cairo_arc(cr, x, 560, 8, 0, 2*math.pi)
        local hue = i / 15
        cairo.cairo_set_source_rgba(cr, 0.3 + hue * 0.5, 0.4, 0.9 - hue * 0.3, 0.8)
        cairo.cairo_fill(cr)
    end

    -- 7. Add text labels for each demo
    cairo.cairo_set_source_rgb(cr, 0.2, 0.2, 0.2)
    cairo.cairo_select_font_face(cr, "Sans", cairo.CAIRO_FONT_SLANT_NORMAL, cairo.CAIRO_FONT_WEIGHT_NORMAL)
    cairo.cairo_set_font_size(cr, 12)

    cairo.cairo_move_to(cr, 340, 200)
    cairo.cairo_show_text(cr, "Radial")

    cairo.cairo_move_to(cr, 520, 300)
    cairo.cairo_show_text(cr, "Star Path")

    cairo.cairo_move_to(cr, 120, 450)
    cairo.cairo_show_text(cr, "Alpha Blending")

    cairo.cairo_move_to(cr, 450, 410)
    cairo.cairo_show_text(cr, "Bézier Curves")
end

-- Render standard widgets first
window:render()

-- Now add custom Cairo graphics on top
print("")
render_custom_cairo(window)

-- Update the window surface to show custom graphics
local sdl = require("lib.sdl_base.sdl_api")
sdl.update_window_surface(window.sdl_window)

print("")
print("✓ Advanced Cairo rendering complete!")
print("")
print("Demonstrated techniques:")
print("  ✓ Linear gradients (smooth color transitions)")
print("  ✓ Radial gradients (spherical shading)")
print("  ✓ Custom paths (star shape with bezier curves)")
print("  ✓ Alpha blending (semi-transparent overlapping shapes)")
print("  ✓ Bézier curves (smooth curved lines)")
print("  ✓ Complex rounded rectangles with arcs")
print("  ✓ Custom decorative elements")
print("")
print("All rendered with Cairo's powerful 2D vector API!")
print("Perfect anti-aliasing, sub-pixel accuracy, professional results.")
print("")

-- Cleanup
backend:destroy_window(window)
print("✓ Demo complete!")

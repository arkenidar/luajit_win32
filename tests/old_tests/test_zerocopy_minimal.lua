-- Minimal test using EXACTLY the working engine.lua approach
local ffi = require("ffi")
local cairo = require("lib.ffi.cairo_ffi")
local sdl = require("lib.sdl_base.sdl_api")

print("Initializing SDL...")
sdl.init()

print("Creating window...")
local window = sdl.create_window("Zero-Copy Test", nil, nil, 640, 480, {})
if not window then error("Create window failed") end

print("Getting surface...")
local surface = sdl.get_window_surface(window)
if not surface then error("Get surface failed") end

print("Creating Cairo surface (zero-copy)...")
local current_w = tonumber(surface.w)
local current_h = tonumber(surface.h)
local cairo_surf = cairo.cairo_image_surface_create_for_data(
    ffi.cast("unsigned char*", surface.pixels),
    cairo.CAIRO_FORMAT_ARGB32,
    current_w,
    current_h,
    surface.pitch
)

print("Creating Cairo context...")
local cr = cairo.cairo_create(cairo_surf)

print("Creating 3 buttons data...")
local buttons = {
    {x = 50, y = 50, w = 150, h = 40, label = "Button 1"},
    {x = 220, y = 50, w = 150, h = 40, label = "Button 2"},
    {x = 390, y = 50, w = 150, h = 40, label = "Button 3"},
}

print("Starting event loop...")
local event = ffi.new("SDL_Event")
local running = true
local frame = 0

while running do
    while sdl.poll_event(event) ~= 0 do
        if event.type == sdl.QUIT then
            print("Quit event received")
            running = false
            break
        end
    end

    -- Clear white
    cairo.cairo_set_source_rgb(cr, 1, 1, 1)
    cairo.cairo_rectangle(cr, 0, 0, current_w, current_h)
    cairo.cairo_fill(cr)

    -- Draw 3 buttons
    for i, btn in ipairs(buttons) do
        cairo.cairo_set_source_rgb(cr, 0.8, 0.8, 0.8)
        cairo.cairo_rectangle(cr, btn.x, btn.y, btn.w, btn.h)
        cairo.cairo_fill(cr)

        -- Border
        cairo.cairo_set_source_rgb(cr, 0, 0, 0)
        cairo.cairo_rectangle(cr, btn.x, btn.y, btn.w, btn.h)
        cairo.cairo_set_line_width(cr, 2)
        cairo.cairo_stroke(cr)

        -- Text
        cairo.cairo_set_source_rgb(cr, 0, 0, 0)
        cairo.cairo_select_font_face(cr, "Sans", 0, 0)
        cairo.cairo_set_font_size(cr, 14)
        cairo.cairo_move_to(cr, btn.x + 10, btn.y + 25)
        cairo.cairo_show_text(cr, btn.label)
    end

    cairo.cairo_surface_flush(cairo_surf)
    cairo.cairo_surface_mark_dirty(cairo_surf)
    sdl.update_window_surface(window)

    frame = frame + 1
    if frame % 60 == 0 then
        print("Frame", frame)
    end

    sdl.delay(16)
end

print("Cleaning up...")
cairo.cairo_destroy(cr)
cairo.cairo_surface_destroy(cairo_surf)
sdl.quit()
print("Done!")

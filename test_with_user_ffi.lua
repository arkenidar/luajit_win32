-- Test using USER's exact FFI bindings from gui/src
package.path = package.path .. ";C:/Ruby34-x64/msys64/home/dario/gui/src/?.lua"

local ffi = require("ffi")
local ffi_cairo = require("ffi_cairo")
local ffi_sdl = require("ffi_sdl")

local cairo = ffi_cairo.C
local C = ffi_sdl.C

print("Initializing SDL...")
if C.SDL_Init(ffi_sdl.SDL_INIT_VIDEO) ~= 0 then
    error("SDL_Init failed")
end

print("Creating window...")
local window = C.SDL_CreateWindow("User FFI Test", 100, 100, 640, 480, ffi_sdl.SDL_WINDOW_RESIZABLE)
if window == nil then error("SDL_CreateWindow failed") end

print("Getting surface...")
local surface = C.SDL_GetWindowSurface(window)
if surface == nil then error("SDL_GetWindowSurface failed") end

print("Creating Cairo surface (zero-copy)...")
local current_w = tonumber(surface.w)
local current_h = tonumber(surface.h)
local cairo_surf = cairo.cairo_image_surface_create_for_data(
    ffi.cast("unsigned char *", surface.pixels),
    ffi_cairo.CAIRO_FORMAT_ARGB32,
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
    while C.SDL_PollEvent(event) ~= 0 do
        if tonumber(event.type) == ffi_sdl.SDL_QUIT then
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
    for _, btn in ipairs(buttons) do
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
    C.SDL_UpdateWindowSurface(window)

    frame = frame + 1
    if frame % 60 == 0 then
        print("Frame", frame)
    end

    C.SDL_Delay(16)
end

print("Cleaning up...")
cairo.cairo_destroy(cr)
cairo.cairo_surface_destroy(cairo_surf)
C.SDL_Quit()
print("Done!")

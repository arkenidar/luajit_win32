-- cairo_ffi.lua
-- Cairo FFI bindings for LuaJIT
-- Provides SVG-like 2D vector graphics rendering

local ffi = require("ffi")

-- Cairo C API declarations
ffi.cdef[[
    // Opaque types
    typedef struct _cairo cairo_t;
    typedef struct _cairo_surface cairo_surface_t;

    // Format enumeration
    typedef enum {
        CAIRO_FORMAT_INVALID   = -1,
        CAIRO_FORMAT_ARGB32    = 0,
        CAIRO_FORMAT_RGB24     = 1,
        CAIRO_FORMAT_A8        = 2,
        CAIRO_FORMAT_A1        = 3,
        CAIRO_FORMAT_RGB16_565 = 4,
        CAIRO_FORMAT_RGB30     = 5
    } cairo_format_t;

    // Font slant enumeration
    typedef enum {
        CAIRO_FONT_SLANT_NORMAL = 0,
        CAIRO_FONT_SLANT_ITALIC = 1,
        CAIRO_FONT_SLANT_OBLIQUE = 2
    } cairo_font_slant_t;

    // Font weight enumeration
    typedef enum {
        CAIRO_FONT_WEIGHT_NORMAL = 0,
        CAIRO_FONT_WEIGHT_BOLD = 1
    } cairo_font_weight_t;

    // Text extents structure
    typedef struct {
        double x_bearing;
        double y_bearing;
        double width;
        double height;
        double x_advance;
        double y_advance;
    } cairo_text_extents_t;

    // Surface management
    cairo_surface_t* cairo_image_surface_create(
        cairo_format_t format,
        int width,
        int height
    );
    cairo_surface_t* cairo_image_surface_create_for_data(
        unsigned char *data,
        cairo_format_t format,
        int width,
        int height,
        int stride
    );
    unsigned char* cairo_image_surface_get_data(cairo_surface_t *surface);
    int cairo_image_surface_get_stride(cairo_surface_t *surface);
    void cairo_surface_flush(cairo_surface_t *surface);
    void cairo_surface_mark_dirty(cairo_surface_t *surface);
    void cairo_surface_destroy(cairo_surface_t *surface);

    // Context management
    cairo_t* cairo_create(cairo_surface_t *target);
    void cairo_destroy(cairo_t *cr);

    // Drawing state
    void cairo_save(cairo_t *cr);
    void cairo_restore(cairo_t *cr);
    void cairo_set_source_rgb(cairo_t *cr, double red, double green, double blue);
    void cairo_set_source_rgba(cairo_t *cr, double red, double green, double blue, double alpha);
    void cairo_set_line_width(cairo_t *cr, double width);

    // Path construction
    void cairo_rectangle(cairo_t *cr, double x, double y, double width, double height);
    void cairo_arc(cairo_t *cr, double xc, double yc, double radius, double angle1, double angle2);
    void cairo_move_to(cairo_t *cr, double x, double y);
    void cairo_line_to(cairo_t *cr, double x, double y);
    void cairo_curve_to(cairo_t *cr, double x1, double y1, double x2, double y2, double x3, double y3);
    void cairo_close_path(cairo_t *cr);
    void cairo_new_path(cairo_t *cr);

    // Rendering operations
    void cairo_fill(cairo_t *cr);
    void cairo_fill_preserve(cairo_t *cr);
    void cairo_stroke(cairo_t *cr);
    void cairo_stroke_preserve(cairo_t *cr);
    void cairo_paint(cairo_t *cr);

    // Text rendering
    void cairo_select_font_face(cairo_t *cr, const char *family, cairo_font_slant_t slant, cairo_font_weight_t weight);
    void cairo_set_font_size(cairo_t *cr, double size);
    void cairo_show_text(cairo_t *cr, const char *utf8);
    void cairo_text_extents(cairo_t *cr, const char *utf8, cairo_text_extents_t *extents);
]]

-- Load Cairo library with fallback
local cairo_lib
local ok, err = pcall(function()
    cairo_lib = ffi.load("cairo")
end)

if not ok then
    -- Try Windows fallback name
    ok, err = pcall(function()
        cairo_lib = ffi.load("libcairo-2")
    end)

    if not ok then
        error("Failed to load Cairo library: " .. tostring(err))
    end
end

-- Export Cairo C functions and constants
local M = {
    -- Constants
    CAIRO_FORMAT_ARGB32 = 0,
    CAIRO_FORMAT_RGB24 = 1,
    CAIRO_FORMAT_A8 = 2,

    CAIRO_FONT_SLANT_NORMAL = 0,
    CAIRO_FONT_SLANT_ITALIC = 1,
    CAIRO_FONT_SLANT_OBLIQUE = 2,

    CAIRO_FONT_WEIGHT_NORMAL = 0,
    CAIRO_FONT_WEIGHT_BOLD = 1,

    -- Surface management
    cairo_image_surface_create = cairo_lib.cairo_image_surface_create,
    cairo_image_surface_create_for_data = cairo_lib.cairo_image_surface_create_for_data,
    cairo_image_surface_get_data = cairo_lib.cairo_image_surface_get_data,
    cairo_image_surface_get_stride = cairo_lib.cairo_image_surface_get_stride,
    cairo_surface_flush = cairo_lib.cairo_surface_flush,
    cairo_surface_mark_dirty = cairo_lib.cairo_surface_mark_dirty,
    cairo_surface_destroy = cairo_lib.cairo_surface_destroy,

    -- Context management
    cairo_create = cairo_lib.cairo_create,
    cairo_destroy = cairo_lib.cairo_destroy,

    -- Drawing state
    cairo_save = cairo_lib.cairo_save,
    cairo_restore = cairo_lib.cairo_restore,
    cairo_set_source_rgb = cairo_lib.cairo_set_source_rgb,
    cairo_set_source_rgba = cairo_lib.cairo_set_source_rgba,
    cairo_set_line_width = cairo_lib.cairo_set_line_width,

    -- Path construction
    cairo_rectangle = cairo_lib.cairo_rectangle,
    cairo_arc = cairo_lib.cairo_arc,
    cairo_move_to = cairo_lib.cairo_move_to,
    cairo_line_to = cairo_lib.cairo_line_to,
    cairo_curve_to = cairo_lib.cairo_curve_to,
    cairo_close_path = cairo_lib.cairo_close_path,
    cairo_new_path = cairo_lib.cairo_new_path,

    -- Rendering operations
    cairo_fill = cairo_lib.cairo_fill,
    cairo_fill_preserve = cairo_lib.cairo_fill_preserve,
    cairo_stroke = cairo_lib.cairo_stroke,
    cairo_stroke_preserve = cairo_lib.cairo_stroke_preserve,
    cairo_paint = cairo_lib.cairo_paint,

    -- Text rendering
    cairo_select_font_face = cairo_lib.cairo_select_font_face,
    cairo_set_font_size = cairo_lib.cairo_set_font_size,
    cairo_show_text = cairo_lib.cairo_show_text,
    cairo_text_extents = cairo_lib.cairo_text_extents,
}

return M

-- pango_ffi.lua
-- Pango FFI bindings for LuaJIT
-- Provides text layout and rendering with emoji support

local ffi = require("ffi")

-- Try to register bundled fonts directory with fontconfig
local function register_bundled_fonts()
    local fontconfig = require("lib.ffi.fontconfig_ffi")

    if fontconfig.available then
        -- Get the path to the fonts directory relative to this file
        local info = debug.getinfo(1, "S")
        if info and info.source then
            local script_path = info.source:sub(2) -- Remove @ prefix
            local base_path = script_path:match("(.*/)")

            if base_path then
                -- Convert lib/ffi/ to fonts/
                local fonts_path = base_path:gsub("lib[/\\]ffi[/\\]?", "fonts")

                -- Convert forward slashes to backslashes on Windows
                if package.config:sub(1,1) == '\\' then
                    fonts_path = fonts_path:gsub("/", "\\")
                end

                -- Try to register the fonts directory
                local success, err = fontconfig.add_font_dir(fonts_path)
                if not success then
                    -- Silently fail - fonts might be system-installed
                end
            end
        end
    end
end

-- Register fonts on module load
pcall(register_bundled_fonts)

-- Pango and PangoCairo C API declarations
ffi.cdef[[
    // Opaque types
    typedef struct _PangoContext PangoContext;
    typedef struct _PangoLayout PangoLayout;
    typedef struct _PangoFontDescription PangoFontDescription;
    typedef struct _PangoAttrList PangoAttrList;

    // Cairo integration
    typedef struct _cairo cairo_t;

    // Pango enums
    typedef enum {
        PANGO_ALIGN_LEFT,
        PANGO_ALIGN_CENTER,
        PANGO_ALIGN_RIGHT
    } PangoAlignment;

    typedef enum {
        PANGO_WEIGHT_NORMAL = 400,
        PANGO_WEIGHT_BOLD = 700
    } PangoWeight;

    typedef enum {
        PANGO_STYLE_NORMAL,
        PANGO_STYLE_OBLIQUE,
        PANGO_STYLE_ITALIC
    } PangoStyle;

    // Rectangle for text extents
    typedef struct {
        int x;
        int y;
        int width;
        int height;
    } PangoRectangle;

    // PangoCairo - Cairo integration functions
    PangoLayout* pango_cairo_create_layout(cairo_t *cr);
    void pango_cairo_show_layout(cairo_t *cr, PangoLayout *layout);
    void pango_cairo_update_layout(cairo_t *cr, PangoLayout *layout);

    // PangoLayout - text layout functions
    void pango_layout_set_text(PangoLayout *layout, const char *text, int length);
    void pango_layout_set_markup(PangoLayout *layout, const char *markup, int length);
    void pango_layout_set_font_description(PangoLayout *layout, const PangoFontDescription *desc);
    void pango_layout_set_width(PangoLayout *layout, int width);
    void pango_layout_set_alignment(PangoLayout *layout, PangoAlignment alignment);
    void pango_layout_get_pixel_extents(PangoLayout *layout, PangoRectangle *ink_rect, PangoRectangle *logical_rect);
    void g_object_unref(void *object);

    // PangoFontDescription - font description functions
    PangoFontDescription* pango_font_description_new(void);
    void pango_font_description_free(PangoFontDescription *desc);
    void pango_font_description_set_family(PangoFontDescription *desc, const char *family);
    void pango_font_description_set_size(PangoFontDescription *desc, int size);
    void pango_font_description_set_weight(PangoFontDescription *desc, PangoWeight weight);
    void pango_font_description_set_style(PangoFontDescription *desc, PangoStyle style);
    PangoFontDescription* pango_font_description_from_string(const char *str);
]]

-- Load Pango, PangoCairo, and GObject libraries
local pango_lib
local pangocairo_lib
local gobject_lib

-- Try loading Pango libraries
local ok, err = pcall(function()
    -- Try different library names for cross-platform compatibility
    -- On Windows, try absolute path first if in MSYS2
    local msys2_path = "C:\\Ruby34-x64\\msys64\\mingw64\\bin\\"

    -- Load GObject first (needed for g_object_unref)
    local gobj_ok, gobj_result = pcall(function()
        return ffi.load(msys2_path .. "libgobject-2.0-0.dll")
    end)
    if not gobj_ok then
        gobj_ok, gobj_result = pcall(function() return ffi.load("gobject-2.0") end)
    end
    if not gobj_ok then
        gobj_ok, gobj_result = pcall(function() return ffi.load("libgobject-2.0-0") end)
    end
    if not gobj_ok then
        gobj_ok, gobj_result = pcall(function() return ffi.load("libgobject-2.0") end)
    end
    if not gobj_ok then
        gobj_ok, gobj_result = pcall(function() return ffi.load("libgobject-2.0.so.0") end)
    end
    if gobj_ok then
        gobject_lib = gobj_result
    else
        gobject_lib = ffi.load("libgobject-2.0.so")
    end

    local pango_ok, pango_result = pcall(function()
        return ffi.load(msys2_path .. "libpango-1.0-0.dll")
    end)
    if pango_ok then
        pango_lib = pango_result
    else
        -- Try system-wide library names
        local pango_ok2, pango_result2 = pcall(function() return ffi.load("pango-1.0") end)
        if pango_ok2 then
            pango_lib = pango_result2
        else
            local pango_ok3, pango_result3 = pcall(function() return ffi.load("libpango-1.0") end)
            if pango_ok3 then
                pango_lib = pango_result3
            else
                pango_lib = ffi.load("libpango-1.0.so.0")
            end
        end
    end

    local pc_ok, pc_result = pcall(function()
        return ffi.load(msys2_path .. "libpangocairo-1.0-0.dll")
    end)
    if pc_ok then
        pangocairo_lib = pc_result
    else
        -- Try system-wide library names
        local pc_ok2, pc_result2 = pcall(function() return ffi.load("pangocairo-1.0") end)
        if pc_ok2 then
            pangocairo_lib = pc_result2
        else
            local pc_ok3, pc_result3 = pcall(function() return ffi.load("libpangocairo-1.0") end)
            if pc_ok3 then
                pangocairo_lib = pc_result3
            else
                pangocairo_lib = ffi.load("libpangocairo-1.0.so.0")
            end
        end
    end
end)

if not ok then
    error("Failed to load Pango libraries: " .. tostring(err) .. "\n" ..
          "Make sure Pango is installed (e.g., via MSYS2: pacman -S mingw-w64-x86_64-pango)")
end

-- Export Pango C libraries directly (like our other FFI modules)
local M = {}
M.pango = pango_lib
M.pangocairo = pangocairo_lib
M.gobject = gobject_lib
M.ffi = ffi

-- Constants
M.PANGO_ALIGN_LEFT = 0
M.PANGO_ALIGN_CENTER = 1
M.PANGO_ALIGN_RIGHT = 2
M.PANGO_WEIGHT_NORMAL = 400
M.PANGO_WEIGHT_BOLD = 700
M.PANGO_STYLE_NORMAL = 0
M.PANGO_STYLE_OBLIQUE = 1
M.PANGO_STYLE_ITALIC = 2

-- Pango uses 1024ths of a point for sizes
M.PANGO_SCALE = 1024

-- Helper function to create a simple layout with text
function M.create_simple_layout(cairo_ctx, text, font_desc_str)
    local layout = pangocairo_lib.pango_cairo_create_layout(cairo_ctx)

    if font_desc_str then
        local desc = pango_lib.pango_font_description_from_string(font_desc_str)
        pango_lib.pango_layout_set_font_description(layout, desc)
        pango_lib.pango_font_description_free(desc)
    end

    pango_lib.pango_layout_set_text(layout, text, -1)  -- -1 means null-terminated

    return layout
end

-- Helper function to show text with Pango
function M.show_text(cairo_ctx, text, font_desc_str)
    local layout = M.create_simple_layout(cairo_ctx, text, font_desc_str)
    pangocairo_lib.pango_cairo_show_layout(cairo_ctx, layout)
    gobject_lib.g_object_unref(layout)
end

-- Wrapper functions for text_editor.lua compatibility
function M.pango_cairo_create_layout(cr)
    return pangocairo_lib.pango_cairo_create_layout(cr)
end

function M.pango_layout_get_context(layout)
    -- For now, return the layout itself as context
    -- The actual context is used rarely in our simplified API
    return layout
end

function M.pango_layout_unref(layout)
    gobject_lib.g_object_unref(layout)
end

function M.pango_layout_set_font_description_str(layout, font_str)
    local desc = pango_lib.pango_font_description_from_string(font_str)
    pango_lib.pango_layout_set_font_description(layout, desc)
    pango_lib.pango_font_description_free(desc)
end

function M.pango_layout_set_text(layout, text, len)
    pango_lib.pango_layout_set_text(layout, text, len or -1)
end

function M.pango_cairo_show_layout(cr, layout)
    pangocairo_lib.pango_cairo_show_layout(cr, layout)
end

-- For backwards compatibility, create metatable to access functions directly
setmetatable(M, {
    __index = function(t, k)
        -- Check PangoCairo functions first
        if type(k) == "string" and k:match("^pango_cairo_") then
            return pangocairo_lib[k]
        end
        -- Then check Pango functions
        if type(k) == "string" and k:match("^pango_") then
            return pango_lib[k]
        end
        -- GObject functions (from gobject library)
        if type(k) == "string" and k:match("^g_object_") then
            return gobject_lib[k]
        end
        return rawget(t, k)
    end
})

return M

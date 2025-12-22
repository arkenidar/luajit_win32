--[[
    SDL Window Wrapper with Cairo Integration

    Wraps an SDL2 window and provides Cairo rendering surface.
    Uses zero-copy integration: Cairo draws directly into SDL surface pixels.
]]

local ffi = require("ffi")
local sdl = require("lib.sdl_base.sdl_api")
local cairo = require("lib.ffi.cairo_ffi")

local SDLWindow = {}
SDLWindow.__index = SDLWindow

function SDLWindow.new(title, width, height, backend)
    local self = setmetatable({}, SDLWindow)

    -- Create SDL window
    self.sdl_window = sdl.create_window(title, nil, nil, width, height, {resizable = true})
    self.backend = backend
    self.controls = {}
    self.title = title
    self.dirty = true  -- Need initial render

    -- Get SDL surface and create Cairo surface
    self:_create_cairo_surface()

    return self
end

function SDLWindow:_create_cairo_surface()
    -- Get SDL window surface
    self.sdl_surface = sdl.get_window_surface(self.sdl_window)

    if not self.sdl_surface then
        error("Failed to get SDL window surface")
    end

    -- ZERO-COPY: Create Cairo surface directly from SDL pixels
    -- This is the approach used by the working gui/src/engine.lua
    self.cairo_surface = cairo.cairo_image_surface_create_for_data(
        ffi.cast("unsigned char*", self.sdl_surface.pixels),
        cairo.CAIRO_FORMAT_ARGB32,
        self.sdl_surface.w,
        self.sdl_surface.h,
        self.sdl_surface.pitch
    )

    if not self.cairo_surface then
        error("Failed to create Cairo surface")
    end

    -- Create Cairo context
    self.cairo_ctx = cairo.cairo_create(self.cairo_surface)

    if not self.cairo_ctx then
        error("Failed to create Cairo context")
    end
end

function SDLWindow:destroy()
    -- Cleanup Cairo resources
    if self.cairo_ctx then
        cairo.cairo_destroy(self.cairo_ctx)
        self.cairo_ctx = nil
    end

    if self.cairo_surface then
        cairo.cairo_surface_destroy(self.cairo_surface)
        self.cairo_surface = nil
    end

    -- Cleanup SDL resources
    if self.sdl_window then
        sdl.destroy_window(self.sdl_window)
        self.sdl_window = nil
    end
end

function SDLWindow:get_size()
    return self.sdl_surface.w, self.sdl_surface.h
end

function SDLWindow:set_title(title)
    self.title = title
    -- TODO: SDL2 doesn't expose SDL_SetWindowTitle in our current FFI bindings
    -- Will add in future iteration
end

function SDLWindow:resize(w, h)
    -- Recreate Cairo surface on window resize
    cairo.cairo_destroy(self.cairo_ctx)
    cairo.cairo_surface_destroy(self.cairo_surface)

    -- Get new SDL surface after resize
    self.sdl_surface = sdl.get_window_surface(self.sdl_window)

    -- Recreate Cairo surface and context
    self:_create_cairo_surface()
end

function SDLWindow:add_control(control)
    table.insert(self.controls, control)
end

function SDLWindow:hit_test(x, y)
    -- Find control under mouse cursor
    for i = #self.controls, 1, -1 do  -- Reverse order: top controls first
        local control = self.controls[i]
        if x >= control.x and x < control.x + control.width and
           y >= control.y and y < control.y + control.height then
            return control
        end
    end
    return nil
end

function SDLWindow:update_hover(x, y)
    -- Update hover state for all controls
    local changed = false
    for _, control in ipairs(self.controls) do
        local was_hover = control.hover
        local is_hover = x >= control.x and x < control.x + control.width and
                        y >= control.y and y < control.y + control.height

        if was_hover ~= is_hover then
            control.hover = is_hover
            changed = true
        end
    end

    if changed then
        self.dirty = true
    end
end

function SDLWindow:mark_dirty()
    self.dirty = true
end

function SDLWindow:render()
    -- Skip rendering if nothing changed
    if not self.dirty then
        return
    end

    -- Validate Cairo context
    if not self.cairo_ctx then
        print("[WARNING] Cairo context is nil, skipping render")
        return
    end

    if not self.sdl_surface then
        print("[WARNING] SDL surface is nil, skipping render")
        return
    end

    -- Re-get SDL surface every frame like working engine.lua does
    -- This is CRITICAL for stability with multiple renders
    self.sdl_surface = sdl.get_window_surface(self.sdl_window)

    -- Check if size changed - if so, recreate Cairo surface
    local current_w = self.sdl_surface.w
    local current_h = self.sdl_surface.h
    if not self.last_w or self.last_w ~= current_w or self.last_h ~= current_h then
        -- Recreate Cairo surface for new size
        if self.cairo_ctx then
            cairo.cairo_destroy(self.cairo_ctx)
        end
        if self.cairo_surface then
            cairo.cairo_surface_destroy(self.cairo_surface)
        end

        self.cairo_surface = cairo.cairo_image_surface_create_for_data(
            ffi.cast("unsigned char*", self.sdl_surface.pixels),
            cairo.CAIRO_FORMAT_ARGB32,
            current_w,
            current_h,
            self.sdl_surface.pitch
        )
        self.cairo_ctx = cairo.cairo_create(self.cairo_surface)

        self.last_w = current_w
        self.last_h = current_h
    end

    -- Clear background (white)
    cairo.cairo_set_source_rgb(self.cairo_ctx, 1, 1, 1)
    cairo.cairo_paint(self.cairo_ctx)

    -- Render all controls using Cairo
    for i, control in ipairs(self.controls) do
        local ok, err = pcall(function()
            self:_render_control(control)
        end)
        if not ok then
            print("[ERROR] Failed to render control", i, ":", err)
            return
        end
    end

    -- Flush and mark Cairo surface dirty (zero-copy, no pixel copy needed)
    cairo.cairo_surface_flush(self.cairo_surface)
    cairo.cairo_surface_mark_dirty(self.cairo_surface)

    -- Update SDL window with rendered content
    local ok, err = pcall(function()
        sdl.update_window_surface(self.sdl_window)
    end)

    if not ok then
        -- Surface update failed
        print("[WARNING] Surface update failed:", err)
    end

    -- Clear dirty flag
    self.dirty = false
end

function SDLWindow:_copy_cairo_to_sdl()
    -- Validate surfaces before copying
    if not self.cairo_surface then
        print("[WARNING] Cairo surface is nil in copy")
        return
    end

    if not self.sdl_surface then
        print("[WARNING] SDL surface is nil in copy")
        return
    end

    -- Get Cairo surface data (ARGB32 format)
    local cairo_data = cairo.cairo_image_surface_get_data(self.cairo_surface)
    if not cairo_data or cairo_data == nil then
        print("[WARNING] Failed to get Cairo surface data")
        return
    end

    local cairo_stride = cairo.cairo_image_surface_get_stride(self.cairo_surface)
    if cairo_stride <= 0 then
        print("[WARNING] Invalid Cairo stride: " .. tostring(cairo_stride))
        return
    end

    local height = self.sdl_surface.h
    local sdl_pitch = self.sdl_surface.pitch

    if not self.sdl_surface.pixels then
        print("[WARNING] SDL surface has no pixels")
        return
    end

    -- Fast row-by-row copy using ffi.copy
    -- If strides match, we can copy the whole surface at once
    if cairo_stride == sdl_pitch then
        ffi.copy(self.sdl_surface.pixels, cairo_data, cairo_stride * height)
    else
        -- Copy row by row
        local src = ffi.cast("char*", cairo_data)
        local dst = ffi.cast("char*", self.sdl_surface.pixels)
        local row_bytes = math.min(cairo_stride, sdl_pitch)

        for y = 0, height - 1 do
            ffi.copy(dst + y * sdl_pitch, src + y * cairo_stride, row_bytes)
        end
    end
end

function SDLWindow:_render_control(control)
    if not control.enabled then
        -- Could render disabled state differently
    end

    if control.type == "button" then
        self:_render_button(control)
    elseif control.type == "label" then
        self:_render_label(control)
    elseif control.type == "edit" then
        self:_render_edit(control)
    elseif control.type == "listbox" then
        self:_render_listbox(control)
    end
end

function SDLWindow:_render_button(btn)
    local cr = self.cairo_ctx

    -- Draw rounded rectangle background
    local radius = 5
    cairo.cairo_new_path(cr)
    cairo.cairo_arc(cr, btn.x + radius, btn.y + radius, radius, math.pi, 3 * math.pi / 2)
    cairo.cairo_arc(cr, btn.x + btn.width - radius, btn.y + radius, radius, 3 * math.pi / 2, 0)
    cairo.cairo_arc(cr, btn.x + btn.width - radius, btn.y + btn.height - radius, radius, 0, math.pi / 2)
    cairo.cairo_arc(cr, btn.x + radius, btn.y + btn.height - radius, radius, math.pi / 2, math.pi)
    cairo.cairo_close_path(cr)

    -- Fill color based on state
    if btn.pressed then
        cairo.cairo_set_source_rgb(cr, 0.6, 0.6, 0.6)
    elseif btn.hover then
        cairo.cairo_set_source_rgb(cr, 0.9, 0.9, 0.9)
    else
        cairo.cairo_set_source_rgb(cr, 0.8, 0.8, 0.8)
    end
    cairo.cairo_fill_preserve(cr)

    -- Border
    cairo.cairo_set_source_rgb(cr, 0.4, 0.4, 0.4)
    cairo.cairo_set_line_width(cr, 1)
    cairo.cairo_stroke(cr)

    -- Text (centered)
    if btn.text and btn.text ~= "" then
        cairo.cairo_set_source_rgb(cr, 0, 0, 0)
        cairo.cairo_select_font_face(cr, "Sans", cairo.CAIRO_FONT_SLANT_NORMAL, cairo.CAIRO_FONT_WEIGHT_NORMAL)
        cairo.cairo_set_font_size(cr, 14)

        local extents = ffi.new("cairo_text_extents_t")
        cairo.cairo_text_extents(cr, btn.text, extents)
        local text_x = btn.x + (btn.width - extents.width) / 2
        local text_y = btn.y + (btn.height + extents.height) / 2

        cairo.cairo_move_to(cr, text_x, text_y)
        cairo.cairo_show_text(cr, btn.text)
    end
end

function SDLWindow:_render_label(lbl)
    local cr = self.cairo_ctx

    if lbl.text and lbl.text ~= "" then
        cairo.cairo_set_source_rgb(cr, 0, 0, 0)
        cairo.cairo_select_font_face(cr, "Sans", cairo.CAIRO_FONT_SLANT_NORMAL, cairo.CAIRO_FONT_WEIGHT_NORMAL)
        cairo.cairo_set_font_size(cr, 14)

        cairo.cairo_move_to(cr, lbl.x, lbl.y + 14)  -- Offset for baseline
        cairo.cairo_show_text(cr, lbl.text)
    end
end

function SDLWindow:_render_edit(edit)
    local cr = self.cairo_ctx

    -- Draw border (inset style)
    cairo.cairo_rectangle(cr, edit.x, edit.y, edit.width, edit.height)
    cairo.cairo_set_source_rgb(cr, 1, 1, 1)  -- White background
    cairo.cairo_fill_preserve(cr)
    cairo.cairo_set_source_rgb(cr, 0.5, 0.5, 0.5)  -- Gray border
    cairo.cairo_set_line_width(cr, 1)
    cairo.cairo_stroke(cr)

    -- Draw text with padding
    if edit.text and edit.text ~= "" then
        cairo.cairo_set_source_rgb(cr, 0, 0, 0)
        cairo.cairo_select_font_face(cr, "Sans", cairo.CAIRO_FONT_SLANT_NORMAL, cairo.CAIRO_FONT_WEIGHT_NORMAL)
        cairo.cairo_set_font_size(cr, 14)

        cairo.cairo_move_to(cr, edit.x + 4, edit.y + 16)  -- Padding and baseline offset
        cairo.cairo_show_text(cr, edit.text)
    end

    -- TODO: Draw cursor if focused
end

function SDLWindow:_render_listbox(lb)
    local cr = self.cairo_ctx

    -- Draw border
    cairo.cairo_rectangle(cr, lb.x, lb.y, lb.width, lb.height)
    cairo.cairo_set_source_rgb(cr, 1, 1, 1)  -- White background
    cairo.cairo_fill_preserve(cr)
    cairo.cairo_set_source_rgb(cr, 0.5, 0.5, 0.5)  -- Gray border
    cairo.cairo_set_line_width(cr, 1)
    cairo.cairo_stroke(cr)

    -- Draw items
    local item_height = 20
    local y_offset = lb.y + 2

    cairo.cairo_select_font_face(cr, "Sans", cairo.CAIRO_FONT_SLANT_NORMAL, cairo.CAIRO_FONT_WEIGHT_NORMAL)
    cairo.cairo_set_font_size(cr, 14)

    for i, item_text in ipairs(lb.items) do
        local item_index = i - 1  -- 0-based index

        -- Highlight selected item
        if item_index == lb.selection then
            cairo.cairo_rectangle(cr, lb.x + 1, y_offset, lb.width - 2, item_height)
            cairo.cairo_set_source_rgb(cr, 0.2, 0.4, 0.8)  -- Blue highlight
            cairo.cairo_fill(cr)
            cairo.cairo_set_source_rgb(cr, 1, 1, 1)  -- White text for selected
        else
            cairo.cairo_set_source_rgb(cr, 0, 0, 0)  -- Black text for normal
        end

        -- Draw item text
        cairo.cairo_move_to(cr, lb.x + 4, y_offset + 14)
        cairo.cairo_show_text(cr, item_text)

        y_offset = y_offset + item_height

        -- Stop if we've exceeded the listbox height
        if y_offset >= lb.y + lb.height then
            break
        end
    end
end

return SDLWindow

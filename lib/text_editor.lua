-- text_editor.lua
-- Rich Text Editor using Cairo, Pango, and SDL2 with Unicode/Emoji support
-- Inspired by HTML content-editable functionality

local ffi = require("ffi")
local cairo_ffi = require("lib.ffi.cairo_ffi")
local pango_ffi = require("lib.ffi.pango_ffi")

local M = {}

-- TextEditor class
local TextEditor = {}
TextEditor.__index = TextEditor

-- Initialize text editor
function TextEditor:new(width, height, font_size, font_family)
    local self = setmetatable({}, TextEditor)
    
    self.width = width or 800
    self.height = height or 600
    self.font_size = font_size or 14
    self.font_family = font_family or "Monospace"
    
    -- Text buffer (using rope-like structure for efficiency)
    self.lines = { "" }  -- Array of lines
    self.cursor_line = 1
    self.cursor_col = 1
    
    -- Selection
    self.selection_active = false
    self.selection_start_line = 1
    self.selection_start_col = 1
    self.selection_end_line = 1
    self.selection_end_col = 1
    
    -- Rendering state
    self.scroll_line = 1  -- First visible line
    self.scroll_offset = 0  -- Horizontal scroll offset (pixels)
    self.line_height = self.font_size + 4  -- Include spacing
    self.char_width = self.font_size * 0.6  -- Approximate for monospace (will be overridden)
    
    -- Cairo and Pango context
    self.surface = nil
    self.cr = nil
    self.pango_layout = nil
    self.pango_context = nil
    
    -- Colors (HTML-like styling)
    self.colors = {
        bg = { r = 1.0, g = 1.0, b = 1.0, a = 1.0 },  -- White
        text = { r = 0.0, g = 0.0, b = 0.0, a = 1.0 },  -- Black
        cursor = { r = 0.0, g = 0.0, b = 0.0, a = 1.0 },  -- Black
        selection = { r = 0.2, g = 0.4, b = 0.8, a = 0.3 },  -- Light blue with alpha
        line_number = { r = 0.5, g = 0.5, b = 0.5, a = 1.0 },  -- Gray
    }
    
    -- Keyboard state
    self.shift_pressed = false
    self.ctrl_pressed = false
    self.alt_pressed = false
    
    -- Undo/Redo stacks
    self.undo_stack = {}
    self.redo_stack = {}
    self.undo_max = 100
    
    -- Initialize Cairo context
    self:_init_cairo()
    
    return self
end

-- Initialize Cairo and Pango contexts
function TextEditor:_init_cairo()
    if self.surface then
        return  -- Already initialized
    end
    
    -- Create RGB24 surface for fast rendering
    self.surface = cairo_ffi.cairo_image_surface_create(
        cairo_ffi.CAIRO_FORMAT_RGB24,
        self.width,
        self.height
    )
    
    if self.surface == nil then
        error("Failed to create Cairo surface")
    end
    
    self.cr = cairo_ffi.cairo_create(self.surface)
    if self.cr == nil then
        error("Failed to create Cairo context")
    end
    
    -- Create Pango layout
    self.pango_layout = pango_ffi.pango_cairo_create_layout(self.cr)
    if self.pango_layout == nil then
        error("Failed to create Pango layout")
    end
    
    -- Get Pango context
    self.pango_context = pango_ffi.pango_layout_get_context(self.pango_layout)
end

-- Measure text width using Pango (proportional rendering)
function TextEditor:_measure_text_width(text)
    if not text or text == "" then return 0 end
    
    -- Safety check - avoid calling into Pango if context not ready
    if not self.pango_layout or not self.cr then
        return #text * self.char_width
    end
    
    -- Set font for layout
    pango_ffi.pango_layout_set_font_description_str(
        self.pango_layout, 
        self.font_family .. " " .. self.font_size
    )
    
    -- Set text
    pango_ffi.pango_layout_set_text(self.pango_layout, text, -1)
    
    -- Get pixel size safely
    local status, width, height = pcall(function()
        return pango_ffi.pango_layout_get_pixel_size(self.pango_layout, nil, nil)
    end)
    
    if status and width then
        return width
    else
        -- Fallback to fixed width if measurement fails
        return #text * self.char_width
    end
end

-- Get cursor X position for a specific column on a line
function TextEditor:_get_cursor_x(line_num, col)
    if col <= 1 then
        return 50 - self.scroll_offset
    end
    
    local line = self.lines[line_num] or ""
    local text_before = string.sub(line, 1, col - 1)
    local x = 50 + self:_measure_text_width(text_before) - self.scroll_offset
    
    return x
end

-- Get column at a specific X position on a line
function TextEditor:_get_column_at_x(line_num, x)
    local line = self.lines[line_num] or ""
    local target_x = x + self.scroll_offset - 50
    
    if target_x < 0 then return 1 end
    
    -- Binary search for column
    local left, right = 1, #line + 1
    
    while left < right do
        local mid = math.floor((left + right) / 2)
        local text_before = string.sub(line, 1, mid - 1)
        local measured_x = self:_measure_text_width(text_before)
        
        if measured_x < target_x then
            left = mid + 1
        else
            right = mid
        end
    end
    
    return math.min(left, #line + 1)
end

-- Cleanup Cairo context
function TextEditor:cleanup()
    if self.pango_layout then
        pcall(function()
            pango_ffi.pango_layout_unref(self.pango_layout)
        end)
        self.pango_layout = nil
    end
    
    if self.cr then
        cairo_ffi.cairo_destroy(self.cr)
        self.cr = nil
    end
    
    if self.surface then
        cairo_ffi.cairo_surface_destroy(self.surface)
        self.surface = nil
    end
end

-- Get character at position
function TextEditor:get_char_at(line, col)
    if line < 1 or line > #self.lines then
        return nil
    end
    
    local line_text = self.lines[line]
    if col < 1 or col > #line_text then
        return nil
    end
    
    return string.sub(line_text, col, col)
end

-- Insert text at cursor position
function TextEditor:insert_text(text)
    -- Save undo state
    self:_push_undo()
    
    local line = self.lines[self.cursor_line]
    local before = string.sub(line, 1, self.cursor_col - 1)
    local after = string.sub(line, self.cursor_col)
    
    -- Handle newlines in inserted text - split by \n
    local text_lines = {}
    local remaining = text
    while remaining ~= "" do
        local newline_pos = remaining:find("\n")
        if newline_pos then
            table.insert(text_lines, remaining:sub(1, newline_pos - 1))
            remaining = remaining:sub(newline_pos + 1)
        else
            table.insert(text_lines, remaining)
            remaining = ""
        end
    end
    
    -- If text ended with \n, we have an empty string after it (which represents a new blank line)
    if text:sub(-1) == "\n" then
        table.insert(text_lines, "")
    end
    
    if #text_lines == 1 then
        -- Single line insertion
        self.lines[self.cursor_line] = before .. text_lines[1] .. after
        self.cursor_col = self.cursor_col + #text_lines[1]
    else
        -- Multi-line insertion
        self.lines[self.cursor_line] = before .. text_lines[1]
        
        for i = 2, #text_lines - 1 do
            table.insert(self.lines, self.cursor_line + i - 1, text_lines[i])
        end
        
        table.insert(self.lines, self.cursor_line + #text_lines - 1, 
                     text_lines[#text_lines] .. after)
        
        self.cursor_line = self.cursor_line + #text_lines - 1
        self.cursor_col = #text_lines[#text_lines] + 1
    end
    
    self:_mark_dirty()
end

-- Delete character at cursor (backspace)
function TextEditor:delete_char()
    if self.cursor_col <= 1 then
        if self.cursor_line > 1 then
            -- Join with previous line
            self:_push_undo()
            local prev_line = self.lines[self.cursor_line - 1]
            local curr_line = self.lines[self.cursor_line]
            self.lines[self.cursor_line - 1] = prev_line .. curr_line
            table.remove(self.lines, self.cursor_line)
            self.cursor_line = self.cursor_line - 1
            self.cursor_col = #prev_line + 1
            self:_mark_dirty()
        end
    else
        self:_push_undo()
        local line = self.lines[self.cursor_line]
        local before = string.sub(line, 1, self.cursor_col - 2)
        local after = string.sub(line, self.cursor_col)
        self.lines[self.cursor_line] = before .. after
        self.cursor_col = self.cursor_col - 1
        self:_mark_dirty()
    end
end

-- Delete character after cursor (delete key)
function TextEditor:delete_char_forward()
    if self.cursor_col > #self.lines[self.cursor_line] then
        if self.cursor_line < #self.lines then
            self:_push_undo()
            local curr_line = self.lines[self.cursor_line]
            local next_line = self.lines[self.cursor_line + 1]
            self.lines[self.cursor_line] = curr_line .. next_line
            table.remove(self.lines, self.cursor_line + 1)
            self:_mark_dirty()
        end
    else
        self:_push_undo()
        local line = self.lines[self.cursor_line]
        local before = string.sub(line, 1, self.cursor_col - 1)
        local after = string.sub(line, self.cursor_col + 1)
        self.lines[self.cursor_line] = before .. after
        self:_mark_dirty()
    end
end

-- Move cursor
function TextEditor:move_cursor(line, col, select)
    -- Clamp to valid position
    if line < 1 then line = 1 end
    if line > #self.lines then line = #self.lines end
    
    local max_col = #self.lines[line] + 1
    if col < 1 then col = 1 end
    if col > max_col then col = max_col end
    
    if select then
        -- Update selection
        if not self.selection_active then
            self.selection_start_line = self.cursor_line
            self.selection_start_col = self.cursor_col
            self.selection_active = true
        end
        self.selection_end_line = line
        self.selection_end_col = col
    else
        -- Clear selection
        self.selection_active = false
    end
    
    self.cursor_line = line
    self.cursor_col = col
    
    -- Auto-scroll to keep cursor visible
    self:_ensure_cursor_visible()
    self:_mark_dirty()
end

-- Move cursor with arrow keys
function TextEditor:cursor_left(select)
    local new_col = self.cursor_col - 1
    if new_col < 1 then
        if self.cursor_line > 1 then
            self:move_cursor(self.cursor_line - 1, 
                           #self.lines[self.cursor_line - 1] + 1, select)
        end
    else
        self:move_cursor(self.cursor_line, new_col, select)
    end
end

function TextEditor:cursor_right(select)
    local max_col = #self.lines[self.cursor_line] + 1
    local new_col = self.cursor_col + 1
    if new_col > max_col then
        if self.cursor_line < #self.lines then
            self:move_cursor(self.cursor_line + 1, 1, select)
        end
    else
        self:move_cursor(self.cursor_line, new_col, select)
    end
end

function TextEditor:cursor_up(select)
    if self.cursor_line > 1 then
        self:move_cursor(self.cursor_line - 1, self.cursor_col, select)
    end
end

function TextEditor:cursor_down(select)
    if self.cursor_line < #self.lines then
        self:move_cursor(self.cursor_line + 1, self.cursor_col, select)
    end
end

-- Select all text
function TextEditor:select_all()
    self.selection_active = true
    self.selection_start_line = 1
    self.selection_start_col = 1
    self.selection_end_line = #self.lines
    self.selection_end_col = #self.lines[#self.lines] + 1
    self:_mark_dirty()
end

-- Get selected text
function TextEditor:get_selected_text()
    if not self.selection_active then
        return ""
    end
    
    local start_line, start_col = self.selection_start_line, self.selection_start_col
    local end_line, end_col = self.selection_end_line, self.selection_end_col
    
    -- Normalize selection (ensure start < end)
    if start_line > end_line or 
       (start_line == end_line and start_col > end_col) then
        start_line, start_col, end_line, end_col = 
            end_line, end_col, start_line, start_col
    end
    
    if start_line == end_line then
        return string.sub(self.lines[start_line], start_col, end_col - 1)
    else
        local text = string.sub(self.lines[start_line], start_col) .. "\n"
        for i = start_line + 1, end_line - 1 do
            text = text .. self.lines[i] .. "\n"
        end
        text = text .. string.sub(self.lines[end_line], 1, end_col - 1)
        return text
    end
end

-- Delete selected text
function TextEditor:delete_selection()
    if not self.selection_active then
        return
    end
    
    self:_push_undo()
    
    local start_line, start_col = self.selection_start_line, self.selection_start_col
    local end_line, end_col = self.selection_end_line, self.selection_end_col
    
    -- Normalize selection
    if start_line > end_line or 
       (start_line == end_line and start_col > end_col) then
        start_line, start_col, end_line, end_col = 
            end_line, end_col, start_line, start_col
    end
    
    if start_line == end_line then
        local line = self.lines[start_line]
        self.lines[start_line] = string.sub(line, 1, start_col - 1) .. 
                                  string.sub(line, end_col)
        self.cursor_line = start_line
        self.cursor_col = start_col
    else
        -- Merge first and last line
        local first = string.sub(self.lines[start_line], 1, start_col - 1)
        local last = string.sub(self.lines[end_line], end_col)
        self.lines[start_line] = first .. last
        
        -- Delete intermediate lines
        for i = end_line, start_line + 1, -1 do
            table.remove(self.lines, i)
        end
        
        self.cursor_line = start_line
        self.cursor_col = start_col
    end
    
    self.selection_active = false
    self:_mark_dirty()
end

-- Undo/Redo
function TextEditor:_push_undo(skip_clear_redo)
    table.insert(self.undo_stack, {
        lines = {},
        cursor_line = self.cursor_line,
        cursor_col = self.cursor_col
    })
    
    -- Deep copy current lines
    for i, line in ipairs(self.lines) do
        self.undo_stack[#self.undo_stack].lines[i] = line
    end
    
    -- Limit undo stack size
    while #self.undo_stack > self.undo_max do
        table.remove(self.undo_stack, 1)
    end
    
    -- Clear redo stack when making new edits (unless we're in redo itself)
    if not skip_clear_redo then
        self.redo_stack = {}
    end
end

function TextEditor:undo()
    if #self.undo_stack == 0 then return end
    
    -- Save current state to redo stack
    table.insert(self.redo_stack, {
        lines = {},
        cursor_line = self.cursor_line,
        cursor_col = self.cursor_col
    })
    
    for i, line in ipairs(self.lines) do
        self.redo_stack[#self.redo_stack].lines[i] = line
    end
    
    -- Restore previous state
    local state = table.remove(self.undo_stack)
    self.lines = state.lines
    self.cursor_line = state.cursor_line
    self.cursor_col = state.cursor_col
    self.selection_active = false
    
    self:_mark_dirty()
end

function TextEditor:redo()
    if #self.redo_stack == 0 then return end
    
    -- Save current state to undo stack, but don't clear redo stack
    self:_push_undo(true)
    
    -- Restore next state
    local state = table.remove(self.redo_stack)
    self.lines = state.lines
    self.cursor_line = state.cursor_line
    self.cursor_col = state.cursor_col
    self.selection_active = false
    
    self:_mark_dirty()
end

-- Render the editor to Cairo context
function TextEditor:render()
    if not self.cr then
        return
    end
    
    -- Clear background
    cairo_ffi.cairo_set_source_rgb(self.cr, 
        self.colors.bg.r, self.colors.bg.g, self.colors.bg.b)
    cairo_ffi.cairo_rectangle(self.cr, 0, 0, self.width, self.height)
    cairo_ffi.cairo_fill(self.cr)
    
    -- Calculate visible line range
    local max_visible_lines = math.floor(self.height / self.line_height)
    local end_line = math.min(self.scroll_line + max_visible_lines, #self.lines)
    
    -- Set font
    pango_ffi.pango_layout_set_font_description_str(
        self.pango_layout, 
        self.font_family .. " " .. self.font_size
    )
    
    -- Render lines
    cairo_ffi.cairo_set_source_rgb(self.cr,
        self.colors.text.r, self.colors.text.g, self.colors.text.b)
    
    for i = self.scroll_line, end_line do
        local y = (i - self.scroll_line) * self.line_height + 4
        
        -- Render line number
        cairo_ffi.cairo_move_to(self.cr, 5, y)
        cairo_ffi.cairo_set_source_rgb(self.cr,
            self.colors.line_number.r, self.colors.line_number.g, 
            self.colors.line_number.b)
        pango_ffi.pango_layout_set_text(self.pango_layout, 
            string.format("%4d", i), -1)
        pango_ffi.pango_cairo_show_layout(self.cr, self.pango_layout)
        
        -- Render line text
        local x = 50
        cairo_ffi.cairo_move_to(self.cr, x - self.scroll_offset, y)
        cairo_ffi.cairo_set_source_rgb(self.cr,
            self.colors.text.r, self.colors.text.g, self.colors.text.b)
        
        pango_ffi.pango_layout_set_text(self.pango_layout, 
            self.lines[i], -1)
        pango_ffi.pango_cairo_show_layout(self.cr, self.pango_layout)
        
        -- Render selection highlight
        if self.selection_active then
            self:_render_selection_line(i, y)
        end
    end
    
    -- Render cursor (blinking effect handled by caller)
    self:_render_cursor()
    
    -- Flush and mark surface as dirty
    cairo_ffi.cairo_surface_flush(self.surface)
    cairo_ffi.cairo_surface_mark_dirty(self.surface)
end

-- Render selection highlight for a line
function TextEditor:_render_selection_line(line_num, y)
    local start_line, start_col = self.selection_start_line, self.selection_start_col
    local end_line, end_col = self.selection_end_line, self.selection_end_col
    
    -- Normalize
    if start_line > end_line or 
       (start_line == end_line and start_col > end_col) then
        start_line, start_col, end_line, end_col = 
            end_line, end_col, start_line, start_col
    end
    
    local sel_start, sel_end = nil, nil
    
    if line_num == start_line and line_num == end_line then
        sel_start = start_col
        sel_end = end_col
    elseif line_num == start_line then
        sel_start = start_col
        sel_end = #self.lines[line_num] + 1
    elseif line_num == end_line then
        sel_start = 1
        sel_end = end_col
    elseif line_num > start_line and line_num < end_line then
        sel_start = 1
        sel_end = #self.lines[line_num] + 1
    end
    
    if sel_start and sel_end then
        -- Use actual text measurements instead of fixed char width
        local line = self.lines[line_num] or ""
        local text_before_start = string.sub(line, 1, sel_start - 1)
        local text_before_end = string.sub(line, 1, sel_end - 1)
        
        local x_start = 50 + self:_measure_text_width(text_before_start) - self.scroll_offset
        local x_end = 50 + self:_measure_text_width(text_before_end) - self.scroll_offset
        
        cairo_ffi.cairo_set_source_rgba(self.cr,
            self.colors.selection.r, self.colors.selection.g, 
            self.colors.selection.b, self.colors.selection.a)
        cairo_ffi.cairo_rectangle(self.cr, x_start, y - 2, 
                                 x_end - x_start, self.line_height - 2)
        cairo_ffi.cairo_fill(self.cr)
    end
end

-- Render text cursor
function TextEditor:_render_cursor()
    if self.cursor_line < self.scroll_line or 
       self.cursor_line >= self.scroll_line + math.floor(self.height / self.line_height) then
        return  -- Cursor not visible
    end
    
    local y = (self.cursor_line - self.scroll_line) * self.line_height + 4
    local x = self:_get_cursor_x(self.cursor_line, self.cursor_col)
    
    cairo_ffi.cairo_set_source_rgb(self.cr,
        self.colors.cursor.r, self.colors.cursor.g, self.colors.cursor.b)
    cairo_ffi.cairo_set_line_width(self.cr, 2)
    cairo_ffi.cairo_move_to(self.cr, x, y)
    cairo_ffi.cairo_line_to(self.cr, x, y + self.line_height - 4)
    cairo_ffi.cairo_stroke(self.cr)
end

-- Ensure cursor is visible (auto-scroll)
function TextEditor:_ensure_cursor_visible()
    -- Vertical scroll
    if self.cursor_line < self.scroll_line then
        self.scroll_line = self.cursor_line
    elseif self.cursor_line >= self.scroll_line + math.floor(self.height / self.line_height) then
        self.scroll_line = self.cursor_line - math.floor(self.height / self.line_height) + 1
    end
    
    -- Horizontal scroll
    local cursor_x = 50 + (self.cursor_col - 1) * self.char_width
    if cursor_x - self.scroll_offset < 50 then
        self.scroll_offset = cursor_x - 50
    elseif cursor_x - self.scroll_offset > self.width - 50 then
        self.scroll_offset = cursor_x - self.width + 50
    end
    
    if self.scroll_offset < 0 then
        self.scroll_offset = 0
    end
end

-- Mark content as dirty (needs redraw)
function TextEditor:_mark_dirty()
    self.needs_redraw = true
end

-- Get plain text content
function TextEditor:get_text()
    return table.concat(self.lines, "\n")
end

-- Set plain text content
function TextEditor:set_text(text)
    self:_push_undo()
    
    self.lines = {}
    for line in (text .. "\n"):gmatch("([^\n]*)\n") do
        table.insert(self.lines, line)
    end
    
    if #self.lines == 0 then
        self.lines = { "" }
    end
    
    self.cursor_line = 1
    self.cursor_col = 1
    self.selection_active = false
    self:_mark_dirty()
end

-- Get current line
function TextEditor:get_current_line()
    return self.lines[self.cursor_line]
end

-- Get line count
function TextEditor:line_count()
    return #self.lines
end

function TextEditor:char_count()
    local count = 0
    for i, line in ipairs(self.lines) do
        count = count + #line
        -- Add 1 for newline, but only if not the last line
        if i < #self.lines then
            count = count + 1
        end
    end
    return count
end

-- Handle keyboard input
function TextEditor:handle_key(key, shift, ctrl, alt)
    self.shift_pressed = shift
    self.ctrl_pressed = ctrl
    self.alt_pressed = alt
    
    -- Ctrl+Z: Undo
    if ctrl and key == 'z' then
        self:undo()
    -- Ctrl+Y: Redo
    elseif ctrl and key == 'y' then
        self:redo()
    -- Ctrl+A: Select all
    elseif ctrl and key == 'a' then
        self:select_all()
    -- Ctrl+C: Copy (return selected text)
    elseif ctrl and key == 'c' then
        return self:get_selected_text()
    -- Ctrl+X: Cut (return and delete selected text)
    elseif ctrl and key == 'x' then
        local text = self:get_selected_text()
        self:delete_selection()
        return text
    -- Ctrl+V: Paste (handled by caller)
    elseif ctrl and key == 'v' then
        return "paste"
    -- Arrow keys
    elseif key == 'left' then
        self:cursor_left(shift)
    elseif key == 'right' then
        self:cursor_right(shift)
    elseif key == 'up' then
        self:cursor_up(shift)
    elseif key == 'down' then
        self:cursor_down(shift)
    -- Home/End
    elseif key == 'home' then
        self:move_cursor(self.cursor_line, 1, shift)
    elseif key == 'end' then
        self:move_cursor(self.cursor_line, #self.lines[self.cursor_line] + 1, shift)
    -- Backspace
    elseif key == 'backspace' then
        if self.selection_active then
            self:delete_selection()
        else
            self:delete_char()
        end
    -- Delete
    elseif key == 'delete' then
        if self.selection_active then
            self:delete_selection()
        else
            self:delete_char_forward()
        end
    -- Return/Enter
    elseif key == 'return' then
        if self.selection_active then
            self:delete_selection()
        end
        local line = self.lines[self.cursor_line]
        local before = string.sub(line, 1, self.cursor_col - 1)
        local after = string.sub(line, self.cursor_col)
        self.lines[self.cursor_line] = before
        table.insert(self.lines, self.cursor_line + 1, after)
        self.cursor_line = self.cursor_line + 1
        self.cursor_col = 1
        self:_push_undo()
        self:_mark_dirty()
    -- Regular character input
    else
        if self.selection_active then
            self:delete_selection()
        end
        self:insert_text(key)
    end
end

-- Get render data (for integration with graphics backend)
function TextEditor:get_render_data()
    return {
        surface = self.surface,
        width = self.width,
        height = self.height,
        cursor_line = self.cursor_line,
        cursor_col = self.cursor_col,
        scroll_line = self.scroll_line,
        line_count = #self.lines,
        needs_redraw = self.needs_redraw
    }
end

M.TextEditor = TextEditor

return M

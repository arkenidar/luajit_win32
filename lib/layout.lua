-- layout.lua
-- Flexbox/Grid layout engine for LuaJIT Win32 GUI

local win32 = require("lib.win32_ffi")
local ffi = require("ffi")

local M = {}

-- ========================================
-- Rect utility class
-- ========================================
local Rect = {}
Rect.__index = Rect

function Rect:new(x, y, width, height)
    local self = setmetatable({}, Rect)
    self.x = x or 0
    self.y = y or 0
    self.width = width or 0
    self.height = height or 0
    return self
end

M.Rect = Rect

-- ========================================
-- LayoutItem class
-- ========================================
local LayoutItem = {}
LayoutItem.__index = LayoutItem

function LayoutItem:new(hwnd, props)
    local self = setmetatable({}, LayoutItem)

    self.hwnd = hwnd
    self.width = props.width
    self.height = props.height
    self.min_width = props.min_width or 0
    self.min_height = props.min_height or 0
    self.max_width = props.max_width or math.huge
    self.max_height = props.max_height or math.huge
    self.flex_grow = props.flex_grow or 0
    self.flex_shrink = props.flex_shrink or 1
    self.flex_basis = props.flex_basis or "auto"
    self.align_self = props.align_self
    self.on_resize = props.on_resize
    self.custom_layout = props.custom_layout
    self.constrain = props.constrain

    -- Calculated values
    self.calculated_x = 0
    self.calculated_y = 0
    self.calculated_width = 0
    self.calculated_height = 0
    self.last_width = nil
    self.last_height = nil

    return self
end

function LayoutItem:apply_position()
    if self.hwnd then
        win32.SetWindowPos(
            self.hwnd,
            nil,
            self.calculated_x,
            self.calculated_y,
            self.calculated_width,
            self.calculated_height,
            win32.SWP_NOZORDER + win32.SWP_NOACTIVATE
        )
    end
end

M.LayoutItem = LayoutItem

-- ========================================
-- FlexContainer class
-- ========================================
local FlexContainer = {}
FlexContainer.__index = FlexContainer

function FlexContainer:new(props)
    local self = setmetatable({}, FlexContainer)

    self.direction = props.direction or "row"
    self.gap = props.gap or 0
    self.padding = props.padding or 0
    self.align_items = props.align_items or "stretch"
    self.justify_content = props.justify_content or "start"
    self.items = {}

    -- For nested containers
    self.flex_grow = props.flex_grow or 0
    self.flex_shrink = props.flex_shrink or 1
    self.flex_basis = props.flex_basis or "auto"
    self.width = props.width
    self.height = props.height
    self.min_width = props.min_width or 0
    self.min_height = props.min_height or 0

    -- Calculated values
    self.calculated_x = 0
    self.calculated_y = 0
    self.calculated_width = 0
    self.calculated_height = 0

    return self
end

function FlexContainer:add_item(hwnd, props)
    local item = LayoutItem:new(hwnd, props or {})
    table.insert(self.items, item)
    return item
end

function FlexContainer:add_flex_container(props)
    local container = FlexContainer:new(props or {})
    table.insert(self.items, container)
    return container
end

function FlexContainer:calculate_layout(rect)
    self.calculated_x = rect.x
    self.calculated_y = rect.y
    self.calculated_width = rect.width
    self.calculated_height = rect.height

    if #self.items == 0 then
        return
    end

    -- Determine main and cross axis dimensions
    local is_row = self.direction == "row"
    local main_size = is_row and rect.width or rect.height
    local cross_size = is_row and rect.height or rect.width

    -- Calculate main axis layout
    self:calculate_main_axis(main_size, is_row)

    -- Calculate cross axis layout
    self:calculate_cross_axis(cross_size, is_row)

    -- Position items and recursively calculate nested containers
    for _, item in ipairs(self.items) do
        if item.calculate_layout then
            -- Nested container
            local item_rect = Rect:new(
                item.calculated_x,
                item.calculated_y,
                item.calculated_width,
                item.calculated_height
            )
            item:calculate_layout(item_rect)
        end
    end
end

function FlexContainer:calculate_main_axis(available_size, is_row)
    -- Phase 1: Calculate base sizes
    local total_base_size = 0
    local total_flex_grow = 0
    local total_flex_shrink = 0

    for _, item in ipairs(self.items) do
        local base_size

        if is_row and item.width then
            base_size = item.width
        elseif not is_row and item.height then
            base_size = item.height
        elseif type(item.flex_basis) == "number" then
            base_size = item.flex_basis
        else
            base_size = 0
        end

        item.base_size = base_size
        total_base_size = total_base_size + base_size
        total_flex_grow = total_flex_grow + (item.flex_grow or 0)
        total_flex_shrink = total_flex_shrink + (item.flex_shrink or 1)
    end

    -- Phase 2: Calculate free space
    local gap_space = (#self.items - 1) * self.gap
    local padding_space = self.padding * 2
    local free_space = available_size - total_base_size - gap_space - padding_space

    -- Phase 3: Distribute free space
    if free_space > 0 and total_flex_grow > 0 then
        -- Grow items
        for _, item in ipairs(self.items) do
            if (item.flex_grow or 0) > 0 then
                local grow_amount = (free_space * item.flex_grow) / total_flex_grow
                local main_size = math.floor(item.base_size + grow_amount)

                -- Clamp to max
                local max_size = is_row and (item.max_width or math.huge) or (item.max_height or math.huge)
                if main_size > max_size then
                    main_size = max_size
                end

                item.main_size = main_size
            else
                item.main_size = item.base_size
            end
        end
    elseif free_space < 0 and total_flex_shrink > 0 then
        -- Shrink items
        for _, item in ipairs(self.items) do
            if (item.flex_shrink or 1) > 0 then
                local shrink_amount = (math.abs(free_space) * item.flex_shrink) / total_flex_shrink
                local main_size = math.floor(item.base_size - shrink_amount)

                -- Clamp to min
                local min_size = is_row and (item.min_width or 0) or (item.min_height or 0)
                if main_size < min_size then
                    main_size = min_size
                end

                item.main_size = main_size
            else
                item.main_size = item.base_size
            end
        end
    else
        -- No flex
        for _, item in ipairs(self.items) do
            item.main_size = item.base_size
        end
    end

    -- Phase 4: Apply justify-content
    local current_pos = self.padding

    if self.justify_content == "start" then
        for _, item in ipairs(self.items) do
            item.main_pos = current_pos
            current_pos = current_pos + item.main_size + self.gap
        end
    elseif self.justify_content == "end" then
        local total_used = 0
        for _, item in ipairs(self.items) do
            total_used = total_used + item.main_size
        end
        total_used = total_used + gap_space

        current_pos = available_size - total_used - self.padding
        for _, item in ipairs(self.items) do
            item.main_pos = current_pos
            current_pos = current_pos + item.main_size + self.gap
        end
    elseif self.justify_content == "center" then
        local total_used = 0
        for _, item in ipairs(self.items) do
            total_used = total_used + item.main_size
        end
        total_used = total_used + gap_space

        current_pos = self.padding + math.floor((available_size - total_used - padding_space) / 2)
        for _, item in ipairs(self.items) do
            item.main_pos = math.floor(current_pos)
            current_pos = current_pos + item.main_size + self.gap
        end
    elseif self.justify_content == "space-between" then
        if #self.items > 1 then
            local total_used = 0
            for _, item in ipairs(self.items) do
                total_used = total_used + item.main_size
            end

            local actual_gap = math.floor((available_size - total_used - padding_space) / (#self.items - 1))
            current_pos = self.padding
            for _, item in ipairs(self.items) do
                item.main_pos = math.floor(current_pos)
                current_pos = current_pos + item.main_size + actual_gap
            end
        else
            self.items[1].main_pos = self.padding
        end
    else -- "space-around" or "space-evenly"
        for _, item in ipairs(self.items) do
            item.main_pos = current_pos
            current_pos = current_pos + item.main_size + self.gap
        end
    end
end

function FlexContainer:calculate_cross_axis(available_size, is_row)
    local padding_space = self.padding * 2
    local cross_available = available_size - padding_space

    for _, item in ipairs(self.items) do
        local alignment = item.align_self or self.align_items
        local fixed_cross_size
        if is_row then
            fixed_cross_size = item.height
        else
            fixed_cross_size = item.width
        end

        if fixed_cross_size then
            -- Explicit cross-axis size specified
            item.cross_size = fixed_cross_size
        elseif alignment == "stretch" then
            -- Stretch to fill (default behavior)
            item.cross_size = cross_available
        else
            -- For non-stretch alignments without explicit size, use 0
            item.cross_size = 0
        end

        -- Calculate cross position based on alignment
        if alignment == "start" then
            item.cross_pos = self.padding
        elseif alignment == "end" then
            item.cross_pos = available_size - item.cross_size - self.padding
        elseif alignment == "center" then
            item.cross_pos = self.padding + math.floor((cross_available - item.cross_size) / 2)
        else -- stretch
            item.cross_pos = self.padding
        end

        -- Set calculated dimensions
        if is_row then
            item.calculated_x = self.calculated_x + item.main_pos
            item.calculated_y = self.calculated_y + item.cross_pos
            item.calculated_width = item.main_size
            item.calculated_height = item.cross_size
        else
            item.calculated_x = self.calculated_x + item.cross_pos
            item.calculated_y = self.calculated_y + item.main_pos
            item.calculated_width = item.cross_size
            item.calculated_height = item.main_size
        end

        -- Apply constrain hook if present
        if item.constrain then
            local constrained = item.constrain({
                x = item.calculated_x,
                y = item.calculated_y,
                width = item.calculated_width,
                height = item.calculated_height
            }, {
                x = self.calculated_x,
                y = self.calculated_y,
                width = self.calculated_width,
                height = self.calculated_height
            })

            item.calculated_x = constrained.x or item.calculated_x
            item.calculated_y = constrained.y or item.calculated_y
            item.calculated_width = constrained.width or item.calculated_width
            item.calculated_height = constrained.height or item.calculated_height
        end
    end
end

function FlexContainer:get_minimum_size()
    local min_main = 0
    local min_cross = 0
    local is_row = self.direction == "row"

    for _, item in ipairs(self.items) do
        if item.get_minimum_size then
            local item_min = item:get_minimum_size()
            if is_row then
                min_main = min_main + item_min.width
                min_cross = math.max(min_cross, item_min.height)
            else
                min_main = min_main + item_min.height
                min_cross = math.max(min_cross, item_min.width)
            end
        else
            if is_row then
                min_main = min_main + (item.width or item.min_width or 0)
                min_cross = math.max(min_cross, item.height or item.min_height or 0)
            else
                min_main = min_main + (item.height or item.min_height or 0)
                min_cross = math.max(min_cross, item.width or item.min_width or 0)
            end
        end
    end

    local gap_space = (#self.items - 1) * self.gap
    local padding_space = self.padding * 2

    min_main = min_main + gap_space + padding_space
    min_cross = min_cross + padding_space

    if is_row then
        return { width = min_main, height = min_cross }
    else
        return { width = min_cross, height = min_main }
    end
end

M.FlexContainer = FlexContainer

-- ========================================
-- LayoutManager class
-- ========================================
local LayoutManager = {}
LayoutManager.__index = LayoutManager

function LayoutManager:new(window)
    local self = setmetatable({}, LayoutManager)

    self.window = window
    self.root_container = nil
    self.all_items = {}
    self.dirty = true

    return self
end

function LayoutManager:create_flex_container(props)
    self.root_container = FlexContainer:new(props or {})
    return self.root_container
end

function LayoutManager:get_available_rect()
    local width, height = self.window:get_client_size()
    return Rect:new(0, 0, width, height)
end

function LayoutManager:collect_all_items(container)
    self.all_items = {}

    local function collect(cont)
        for _, item in ipairs(cont.items) do
            if item.calculate_layout then
                -- Nested container
                collect(item)
            else
                -- Leaf item
                table.insert(self.all_items, item)
            end
        end
    end

    if container then
        collect(container)
    end
end

function LayoutManager:apply()
    if not self.root_container then
        return
    end

    -- Recalculate layout
    local rect = self:get_available_rect()
    self.root_container:calculate_layout(rect)

    -- Collect all leaf items
    self:collect_all_items(self.root_container)

    -- Batch update all window positions
    if #self.all_items > 0 then
        local hdwp = win32.BeginDeferWindowPos(#self.all_items)

        for _, item in ipairs(self.all_items) do
            if item.hwnd then
                hdwp = win32.DeferWindowPos(
                    hdwp,
                    item.hwnd,
                    nil,
                    item.calculated_x,
                    item.calculated_y,
                    item.calculated_width,
                    item.calculated_height,
                    win32.SWP_NOZORDER + win32.SWP_NOACTIVATE
                )

                -- Call resize callback if size changed
                if item.on_resize and
                   (item.calculated_width ~= item.last_width or
                    item.calculated_height ~= item.last_height) then
                    item.on_resize(item.calculated_width, item.calculated_height)
                    item.last_width = item.calculated_width
                    item.last_height = item.calculated_height
                end
            end
        end

        win32.EndDeferWindowPos(hdwp)
    end

    self.dirty = false
end

function LayoutManager:invalidate()
    self.dirty = true
end

function LayoutManager:get_minimum_size()
    if self.root_container and self.root_container.get_minimum_size then
        return self.root_container:get_minimum_size()
    end
    return nil
end

M.LayoutManager = LayoutManager

return M

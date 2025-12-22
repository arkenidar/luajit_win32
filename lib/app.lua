-- app.lua
-- To-Do List application logic

local win32 = require("lib.ffi.win32_ffi")
local gl_renderer_module = require("lib.gl_renderer")

local M = {}

-- TodoApp class
local TodoApp = {}
TodoApp.__index = TodoApp

function TodoApp:new(platform)
    local self = setmetatable({}, TodoApp)

    self.platform = platform  -- Store platform reference
    self.tasks = {}
    self.window = nil
    self.controls = {}
    self.control_ids = {}
    self.gl_renderer = nil
    self.event_handlers = {}  -- Store event handlers for platform

    return self
end

function TodoApp:create_ui(window)
    local layout = require("lib.layout")
    self.window = window

    -- Create controls without positions (will be set by layout)
    local label_id, label_hwnd = window:add_label(nil, 0, 0, 0, 0, "New Task:")
    local edit_id, edit_hwnd = window:add_edit(nil, 0, 0, 0, 0, "")
    local add_id, add_hwnd = window:add_button(nil, 0, 0, 0, 0, "Add")
    local listbox_id, listbox = window:add_listbox(nil, 0, 0, 0, 0)
    local edit_btn_id, edit_btn_hwnd = window:add_button(nil, 0, 0, 0, 0, "Edit Selected")
    local delete_id, delete_hwnd = window:add_button(nil, 0, 0, 0, 0, "Delete")
    local clear_id, clear_hwnd = window:add_button(nil, 0, 0, 0, 0, "Clear All")
    local gl_view_id, gl_hwnd = window:add_opengl_view(nil, 0, 0, 0, 0)

    -- Store control references
    self.controls = {
        label = label_hwnd,
        edit = edit_hwnd,
        add_button = add_hwnd,
        listbox = listbox,
        edit_button = edit_btn_hwnd,
        delete_button = delete_hwnd,
        clear_button = clear_hwnd,
        gl_view = gl_hwnd
    }
    self.control_ids = {
        edit = edit_id,
        add_button = add_id,
        listbox = listbox_id,
        edit_button = edit_btn_id,
        delete_button = delete_id,
        clear_button = clear_id
    }

    -- Build layout tree
    local lm = layout.LayoutManager:new(window)
    local root = lm:create_flex_container({ direction = "row", gap = 10, padding = 10 })

    -- Left panel (vertical stack)
    local left_panel = root:add_flex_container({
        direction = "column",
        flex_basis = 450,
        flex_grow = 0,
        gap = 10
    })

    left_panel:add_item(label_hwnd, { height = 20, flex_grow = 0 })

    -- Input row
    local input_row = left_panel:add_flex_container({
        direction = "row",
        height = 25,
        gap = 10,
        flex_grow = 0
    })
    input_row:add_item(edit_hwnd, { flex_grow = 1, min_width = 100 })
    input_row:add_item(add_hwnd, { width = 100, flex_shrink = 0 })

    -- Listbox fills remaining space
    left_panel:add_item(listbox.hwnd, { flex_grow = 1, min_height = 100 })

    -- Button row
    local button_row = left_panel:add_flex_container({
        direction = "row",
        height = 25,
        gap = 10,
        flex_grow = 0
    })
    button_row:add_item(edit_btn_hwnd, { flex_grow = 1 })
    button_row:add_item(delete_hwnd, { flex_grow = 1 })
    button_row:add_item(clear_hwnd, { flex_grow = 1 })

    -- OpenGL view (right panel)
    root:add_item(gl_hwnd, {
        flex_grow = 1,
        min_width = 200,
        on_resize = function(width, height)
            if self.gl_renderer then
                self.gl_renderer:resize(width, height)
            end
        end
    })

    -- Initialize OpenGL renderer (will be sized by layout)
    self.gl_renderer = gl_renderer_module.GLRenderer:new(gl_hwnd, 100, 100)

    -- Apply layout and attach to window
    lm:apply()
    window:set_layout(lm)

    -- Initially disable edit and delete buttons (no selection)
    self:update_button_states()
end

function TodoApp:setup_handlers(window)
    -- Set up timer for OpenGL animation (~60 FPS)
    local TIMER_ID = 1
    win32.SetTimer(window.hwnd, TIMER_ID, 16, nil)

    window:on("timer", function(timer_id)
        if timer_id == TIMER_ID and self.gl_renderer then
            self.gl_renderer:update(0.016)  -- 16ms in seconds
            self.gl_renderer:render()
        end
    end)

    window:on("destroy", function()
        -- Cleanup OpenGL context
        if self.gl_renderer then
            self.gl_renderer:cleanup()
        end
        -- Kill timer
        win32.KillTimer(window.hwnd, TIMER_ID)
    end)

    -- Set up command handler
    window:on("command", function(control_id, notification)
        -- Button clicks have notification = BN_CLICKED (0)
        if notification == win32.BN_CLICKED then
            if control_id == self.control_ids.add_button then
                self:on_add_clicked()
            elseif control_id == self.control_ids.edit_button then
                self:on_edit_clicked()
            elseif control_id == self.control_ids.delete_button then
                self:on_delete_clicked()
            elseif control_id == self.control_ids.clear_button then
                self:on_clear_all_clicked()
            end
        -- Listbox selection changed
        elseif notification == win32.LBN_SELCHANGE then
            if control_id == self.control_ids.listbox then
                self:on_listbox_selection_changed()
            end
        -- Listbox double-click
        elseif notification == win32.LBN_DBLCLK then
            if control_id == self.control_ids.listbox then
                self:on_edit_clicked()
            end
        end
    end)
end

-- Business logic methods

function TodoApp:add_task(text)
    -- Validate input
    if text == nil or text == "" then
        return false
    end

    -- Trim whitespace
    text = text:match("^%s*(.-)%s*$")
    if text == "" then
        return false
    end

    -- Add to tasks array
    table.insert(self.tasks, text)

    -- Update listbox
    self.controls.listbox:add_item(text)

    return true
end

function TodoApp:delete_task()
    local index = self.controls.listbox:get_selection()

    -- Check if valid selection (LB_ERR = -1)
    if index < 0 then
        return false
    end

    -- Convert to 1-based index for Lua table
    local lua_index = index + 1

    -- Remove from tasks array
    table.remove(self.tasks, lua_index)

    -- Refresh listbox
    self:refresh_listbox()

    -- Update button states
    self:update_button_states()

    return true
end

function TodoApp:get_selected_task()
    local index = self.controls.listbox:get_selection()

    if index < 0 then
        return nil, -1
    end

    local lua_index = index + 1
    return self.tasks[lua_index], lua_index
end

function TodoApp:update_task(lua_index, new_text)
    -- Validate input
    if new_text == nil or new_text == "" then
        return false
    end

    -- Trim whitespace
    new_text = new_text:match("^%s*(.-)%s*$")
    if new_text == "" then
        return false
    end

    -- Update task in array
    self.tasks[lua_index] = new_text

    -- Refresh listbox
    self:refresh_listbox()

    return true
end

function TodoApp:clear_all()
    self.tasks = {}
    self.controls.listbox:clear()
    self:update_button_states()
end

-- UI synchronization methods

function TodoApp:refresh_listbox()
    -- Clear listbox
    self.controls.listbox:clear()

    -- Re-add all tasks
    for _, task in ipairs(self.tasks) do
        self.controls.listbox:add_item(task)
    end
end

function TodoApp:clear_input()
    self.window:set_control_text(self.controls.edit, "")
end

function TodoApp:update_button_states()
    local has_selection = self.controls.listbox:get_selection() >= 0
    local has_tasks = #self.tasks > 0

    -- Enable edit/delete only if there's a selection
    self.window:enable_control(self.controls.edit_button, has_selection)
    self.window:enable_control(self.controls.delete_button, has_selection)

    -- Enable clear all only if there are tasks
    self.window:enable_control(self.controls.clear_button, has_tasks)
end

-- Event handlers

function TodoApp:on_add_clicked()
    -- Get text from edit control
    local text = self.window:get_control_text(self.controls.edit)

    -- Add task
    if self:add_task(text) then
        -- Clear input field on success
        self:clear_input()

        -- Update button states
        self:update_button_states()
    else
        -- Show error message
        win32.MessageBoxW(
            self.window.hwnd,
            win32.to_wstring("Please enter a task description."),
            win32.to_wstring("Invalid Input"),
            win32.MB_OK + win32.MB_ICONWARNING
        )
    end
end

function TodoApp:on_delete_clicked()
    if self:delete_task() then
        -- Clear input field
        self:clear_input()
    end
end

function TodoApp:on_edit_clicked()
    local task, lua_index = self:get_selected_task()

    if task then
        -- Populate edit field with selected task
        self.window:set_control_text(self.controls.edit, task)

        -- Change Add button to Update
        self.window:set_control_text(self.controls.add_button, "Update")

        -- Store the index being edited
        self.editing_index = lua_index

        -- Replace Add button click handler temporarily
        local original_add_handler = self.on_add_clicked

        self.on_add_clicked = function(app_self)
            -- Get updated text
            local text = app_self.window:get_control_text(app_self.controls.edit)

            -- Update task
            if app_self:update_task(app_self.editing_index, text) then
                -- Clear input field
                app_self:clear_input()

                -- Restore Add button
                app_self.window:set_control_text(app_self.controls.add_button, "Add")

                -- Restore original handler
                app_self.on_add_clicked = original_add_handler

                -- Clear editing index
                app_self.editing_index = nil

                -- Update button states
                app_self:update_button_states()
            else
                -- Show error message
                win32.MessageBoxW(
                    app_self.window.hwnd,
                    win32.to_wstring("Please enter a task description."),
                    win32.to_wstring("Invalid Input"),
                    win32.MB_OK + win32.MB_ICONWARNING
                )
            end
        end
    end
end

function TodoApp:on_clear_all_clicked()
    -- Show confirmation dialog
    local result = win32.MessageBoxW(
        self.window.hwnd,
        win32.to_wstring("Are you sure you want to clear all tasks?"),
        win32.to_wstring("Confirm Clear All"),
        win32.MB_YESNO + win32.MB_ICONQUESTION
    )

    if result == win32.IDYES then
        self:clear_all()
        self:clear_input()

        -- Restore Add button if in edit mode
        self.window:set_control_text(self.controls.add_button, "Add")
        self.editing_index = nil
    end
end

function TodoApp:on_listbox_selection_changed()
    self:update_button_states()
end

M.TodoApp = TodoApp

return M

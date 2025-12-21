-- app.lua
-- To-Do List application logic

local win32 = require("lib.win32_ffi")

local M = {}

-- TodoApp class
local TodoApp = {}
TodoApp.__index = TodoApp

function TodoApp:new()
    local self = setmetatable({}, TodoApp)

    self.tasks = {}
    self.window = nil
    self.controls = {}
    self.control_ids = {}

    return self
end

function TodoApp:create_ui(window)
    self.window = window

    -- UI Layout (450x400 window)
    -- Label "New Task:" at (10, 10)
    local label_id, label_hwnd = window:add_label(nil, 10, 10, 80, 20, "New Task:")
    self.controls.label = label_hwnd

    -- Edit control at (10, 30, 300x25)
    local edit_id, edit_hwnd = window:add_edit(nil, 10, 30, 300, 25, "")
    self.controls.edit = edit_hwnd
    self.control_ids.edit = edit_id

    -- Add button at (320, 30, 100x25)
    local add_id, add_hwnd = window:add_button(nil, 320, 30, 100, 25, "Add")
    self.controls.add_button = add_hwnd
    self.control_ids.add_button = add_id

    -- Listbox at (10, 70, 420x220)
    local listbox_id, listbox = window:add_listbox(nil, 10, 70, 420, 220)
    self.controls.listbox = listbox
    self.control_ids.listbox = listbox_id

    -- Edit button at (10, 300, 100x25)
    local edit_btn_id, edit_btn_hwnd = window:add_button(nil, 10, 300, 100, 25, "Edit Selected")
    self.controls.edit_button = edit_btn_hwnd
    self.control_ids.edit_button = edit_btn_id

    -- Delete button at (120, 300, 100x25)
    local delete_id, delete_hwnd = window:add_button(nil, 120, 300, 100, 25, "Delete")
    self.controls.delete_button = delete_hwnd
    self.control_ids.delete_button = delete_id

    -- Clear All button at (230, 300, 100x25)
    local clear_id, clear_hwnd = window:add_button(nil, 230, 300, 100, 25, "Clear All")
    self.controls.clear_button = clear_hwnd
    self.control_ids.clear_button = clear_id

    -- Initially disable edit and delete buttons (no selection)
    self:update_button_states()
end

function TodoApp:setup_handlers(window)
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

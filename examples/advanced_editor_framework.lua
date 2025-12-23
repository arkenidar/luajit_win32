-- examples/demo_editor_advanced.lua
-- Advanced text editor example with syntax highlighting framework
-- Demonstrates all major text editor features

local text_editor_module = require("lib.text_editor")
local text_io = require("lib.text_io")

-- Syntax highlighter module (extensible framework)
local SyntaxHighlighter = {}
SyntaxHighlighter.__index = SyntaxHighlighter

function SyntaxHighlighter:new(language)
    local self = setmetatable({}, SyntaxHighlighter)
    self.language = language or "plain"
    self.keywords = {}
    self.patterns = {}
    return self
end

function SyntaxHighlighter:register_keyword(word, color)
    self.keywords[word] = color
end

function SyntaxHighlighter:register_pattern(pattern, color)
    table.insert(self.patterns, { pattern = pattern, color = color })
end

function SyntaxHighlighter:highlight_line(line)
    -- Returns array of {text, color} tokens
    local tokens = {}
    
    if self.language == "plain" then
        -- Plain text - no highlighting
        return { {text = line, color = nil} }
    elseif self.language == "lua" then
        return self:highlight_lua(line)
    end
    
    return { {text = line, color = nil} }
end

function SyntaxHighlighter:highlight_lua(line)
    -- Lua syntax highlighting example
    local tokens = {}
    local keywords = {
        local = true, function = true, if = true, then = true,
        else = true, elseif = true, end = true, for = true,
        while = true, do = true, return = true, nil = true,
        true = true, false = true, and = true, or = true,
        not = true, in = true, break = true,
    }
    
    local pos = 1
    while pos <= #line do
        -- Skip whitespace
        local space_start, space_end = line:match("^%s+", pos)
        if space_end then
            table.insert(tokens, {text = line:sub(pos, space_end), color = nil})
            pos = space_end + 1
        end
        
        -- Check for comment
        if line:sub(pos, pos + 1) == "--" then
            table.insert(tokens, {text = line:sub(pos), color = "comment"})
            break
        end
        
        -- Check for string
        if line:byte(pos) == string.byte('"') or line:byte(pos) == string.byte("'") then
            local quote = line:sub(pos, pos)
            local end_pos = line:find(quote, pos + 1)
            if end_pos then
                table.insert(tokens, {text = line:sub(pos, end_pos), color = "string"})
                pos = end_pos + 1
            else
                table.insert(tokens, {text = line:sub(pos), color = "string"})
                break
            end
        end
        
        -- Check for identifier/keyword
        local ident_start, ident_end, word = line:match("^([a-zA-Z_][a-zA-Z0-9_]*)()", pos)
        if word then
            local color = keywords[word] and "keyword" or "identifier"
            table.insert(tokens, {text = word, color = color})
            pos = ident_end
        elseif pos <= #line then
            table.insert(tokens, {text = line:sub(pos, pos), color = nil})
            pos = pos + 1
        end
    end
    
    return tokens
end

-- Editor state machine
local EditorState = {}
EditorState.__index = EditorState

function EditorState:new(editor)
    local self = setmetatable({}, EditorState)
    self.editor = editor
    self.mode = "normal"  -- normal, insert, visual, command
    self.search_term = nil
    self.search_results = {}
    self.search_index = 1
    self.is_dirty = false
    self.autosave_enabled = true
    self.autosave_interval = 5000  -- 5 seconds
    self.last_autosave = 0
    self.syntax_highlighter = SyntaxHighlighter:new("plain")
    return self
end

function EditorState:set_language(language)
    self.syntax_highlighter = SyntaxHighlighter:new(language)
end

function EditorState:search(term)
    self.search_term = term
    self.search_results = {}
    self.search_index = 1
    
    for line_no, line_text in ipairs(self.editor.lines) do
        local pos = 1
        while true do
            pos = line_text:find(term, pos, true)
            if not pos then break end
            
            table.insert(self.search_results, {
                line = line_no,
                col = pos,
                end_col = pos + #term
            })
            pos = pos + 1
        end
    end
    
    if #self.search_results > 0 then
        return self:goto_search_result(1)
    end
    
    return false
end

function EditorState:search_next()
    if #self.search_results == 0 then return false end
    
    self.search_index = (self.search_index % #self.search_results) + 1
    return self:goto_search_result(self.search_index)
end

function EditorState:search_previous()
    if #self.search_results == 0 then return false end
    
    self.search_index = ((self.search_index - 2) % #self.search_results) + 1
    return self:goto_search_result(self.search_index)
end

function EditorState:goto_search_result(index)
    local result = self.search_results[index]
    if not result then return false end
    
    self.editor:move_cursor(result.line, result.col, false)
    return true
end

function EditorState:replace_all(search_term, replacement)
    local count = 0
    
    for line_no = #self.editor.lines, 1, -1 do
        local line = self.editor.lines[line_no]
        local new_line = line:gsub(search_term, replacement)
        
        if new_line ~= line then
            self.editor.lines[line_no] = new_line
            count = count + 1
        end
    end
    
    self.is_dirty = count > 0
    return count
end

-- Statistics tracking
local EditorStats = {}
EditorStats.__index = EditorStats

function EditorStats:new()
    local self = setmetatable({}, EditorStats)
    self.total_characters = 0
    self.total_words = 0
    self.total_lines = 0
    self.reading_time_minutes = 0
    self.keystroke_count = 0
    self.undo_actions = 0
    self.redo_actions = 0
    return self
end

function EditorStats:update(editor)
    self.total_characters = editor:char_count()
    self.total_lines = editor:line_count()
    
    -- Calculate word count
    local word_count = 0
    for _, line in ipairs(editor.lines) do
        local count = 0
        line:gsub("%S+", function() count = count + 1 end)
        word_count = word_count + count
    end
    self.total_words = word_count
    
    -- Estimate reading time (average 200 words per minute)
    self.reading_time_minutes = math.ceil(word_count / 200)
end

function EditorStats:get_summary()
    return string.format(
        "%d chars | %d words | %d lines | ~%d min read",
        self.total_characters,
        self.total_words,
        self.total_lines,
        self.reading_time_minutes
    )
end

-- Advanced Editor wrapper
local AdvancedEditor = {}
AdvancedEditor.__index = AdvancedEditor

function AdvancedEditor:new(width, height, font_size, font_family)
    local self = setmetatable({}, AdvancedEditor)
    
    self.editor = text_editor_module.TextEditor:new(width, height, font_size, font_family)
    self.state = EditorState:new(self.editor)
    self.stats = EditorStats:new()
    self.bookmarks = {}  -- Line number -> true
    self.breakpoints = {}  -- Line number -> true (for debugging)
    
    return self
end

function AdvancedEditor:toggle_bookmark(line)
    line = line or self.editor.cursor_line
    self.bookmarks[line] = not self.bookmarks[line]
end

function AdvancedEditor:toggle_breakpoint(line)
    line = line or self.editor.cursor_line
    self.breakpoints[line] = not self.breakpoints[line]
end

function AdvancedEditor:get_next_bookmark()
    for line = self.editor.cursor_line + 1, self.editor:line_count() do
        if self.bookmarks[line] then
            self.editor:move_cursor(line, 1, false)
            return line
        end
    end
    
    -- Wrap around
    for line = 1, self.editor.cursor_line do
        if self.bookmarks[line] then
            self.editor:move_cursor(line, 1, false)
            return line
        end
    end
end

function AdvancedEditor:indent_selection()
    if not self.editor.selection_active then
        return
    end
    
    local start_line = self.editor.selection_start_line
    local end_line = self.editor.selection_end_line
    
    if start_line > end_line then
        start_line, end_line = end_line, start_line
    end
    
    for line_no = start_line, end_line do
        self.editor.lines[line_no] = "  " .. self.editor.lines[line_no]
    end
end

function AdvancedEditor:unindent_selection()
    if not self.editor.selection_active then
        return
    end
    
    local start_line = self.editor.selection_start_line
    local end_line = self.editor.selection_end_line
    
    if start_line > end_line then
        start_line, end_line = end_line, start_line
    end
    
    for line_no = start_line, end_line do
        local line = self.editor.lines[line_no]
        if line:match("^  ") then
            self.editor.lines[line_no] = line:sub(3)
        end
    end
end

function AdvancedEditor:duplicate_line()
    local current_line = self.editor.lines[self.editor.cursor_line]
    table.insert(self.editor.lines, self.editor.cursor_line + 1, current_line)
    self.editor:move_cursor(self.editor.cursor_line + 1, self.editor.cursor_col, false)
end

function AdvancedEditor:delete_line()
    if self.editor:line_count() > 1 then
        table.remove(self.editor.lines, self.editor.cursor_line)
    else
        self.editor.lines[self.editor.cursor_line] = ""
    end
end

function AdvancedEditor:move_line_up()
    if self.editor.cursor_line > 1 then
        local line = self.editor.lines[self.editor.cursor_line]
        self.editor.lines[self.editor.cursor_line] = self.editor.lines[self.editor.cursor_line - 1]
        self.editor.lines[self.editor.cursor_line - 1] = line
        self.editor:move_cursor(self.editor.cursor_line - 1, self.editor.cursor_col, false)
    end
end

function AdvancedEditor:move_line_down()
    if self.editor.cursor_line < self.editor:line_count() then
        local line = self.editor.lines[self.editor.cursor_line]
        self.editor.lines[self.editor.cursor_line] = self.editor.lines[self.editor.cursor_line + 1]
        self.editor.lines[self.editor.cursor_line + 1] = line
        self.editor:move_cursor(self.editor.cursor_line + 1, self.editor.cursor_col, false)
    end
end

function AdvancedEditor:toggle_line_comment(comment_char)
    comment_char = comment_char or "--"
    
    local line = self.editor.lines[self.editor.cursor_line]
    
    if line:match("^%s*" .. comment_char) then
        -- Uncomment
        self.editor.lines[self.editor.cursor_line] = line:gsub("^(%s*)" .. comment_char, "%1")
    else
        -- Comment
        self.editor.lines[self.editor.cursor_line] = comment_char .. " " .. line
    end
end

function AdvancedEditor:update_statistics()
    self.stats:update(self.editor)
end

function AdvancedEditor:get_status()
    self:update_statistics()
    
    return {
        line = self.editor.cursor_line,
        col = self.editor.cursor_col,
        total_lines = self.editor:line_count(),
        is_modified = self.state.is_dirty,
        mode = self.state.mode,
        language = self.state.syntax_highlighter.language,
        stats_summary = self.stats:get_summary(),
        search_results = #self.state.search_results,
        search_index = self.state.search_index
    }
end

-- Export modules
return {
    TextEditor = text_editor_module.TextEditor,
    AdvancedEditor = AdvancedEditor,
    EditorState = EditorState,
    EditorStats = EditorStats,
    SyntaxHighlighter = SyntaxHighlighter,
    TextIO = text_io
}

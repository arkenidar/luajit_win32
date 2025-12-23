-- tests/test_text_editor.lua
-- Comprehensive test suite for text editor functionality

local text_editor_module = require("lib.text_editor")
local text_io = require("lib.text_io")

-- Test framework
local Test = {}
Test.passed = 0
Test.failed = 0
Test.tests = {}

function Test:add(name, fn)
    table.insert(self.tests, { name = name, fn = fn })
end

function Test:run()
    print("=" .. string.rep("=", 78) .. "=")
    print("TEXT EDITOR TEST SUITE")
    print("=" .. string.rep("=", 78) .. "=")
    print()
    
    for _, test in ipairs(self.tests) do
        local success, err = pcall(test.fn)
        
        if success then
            print("✓ " .. test.name)
            self.passed = self.passed + 1
        else
            print("✗ " .. test.name)
            print("  Error: " .. tostring(err))
            self.failed = self.failed + 1
        end
    end
    
    print()
    print("=" .. string.rep("=", 78) .. "=")
    print(string.format("Tests passed: %d/%d", self.passed, self.passed + self.failed))
    print("=" .. string.rep("=", 78) .. "=")
    
    return self.failed == 0
end

local function assert_equal(actual, expected, message)
    if actual ~= expected then
        error(message or string.format("Expected %q, got %q", expected, actual))
    end
end

local function assert_true(value, message)
    if not value then
        error(message or "Expected true, got false")
    end
end

local function assert_false(value, message)
    if value then
        error(message or "Expected false, got true")
    end
end

-- BASIC FUNCTIONALITY TESTS
Test:add("Create editor instance", function()
    local editor = text_editor_module.TextEditor:new(800, 600)
    assert_true(editor ~= nil)
    assert_equal(editor.width, 800)
    assert_equal(editor.height, 600)
    editor:cleanup()
end)

Test:add("Insert single character", function()
    local editor = text_editor_module.TextEditor:new(800, 600)
    editor:insert_text("A")
    assert_equal(editor:get_text(), "A")
    editor:cleanup()
end)

Test:add("Insert multiple characters", function()
    local editor = text_editor_module.TextEditor:new(800, 600)
    editor:insert_text("Hello World")
    assert_equal(editor:get_text(), "Hello World")
    editor:cleanup()
end)

Test:add("Insert with newline", function()
    local editor = text_editor_module.TextEditor:new(800, 600)
    editor:insert_text("Line1\nLine2")
    local text = editor:get_text()
    assert_true(text:find("Line1") ~= nil)
    assert_true(text:find("Line2") ~= nil)
    editor:cleanup()
end)

-- UNICODE TESTS
Test:add("Insert Unicode characters", function()
    local editor = text_editor_module.TextEditor:new(800, 600)
    editor:insert_text("café")
    assert_equal(editor:get_text(), "café")
    editor:cleanup()
end)

Test:add("Insert CJK characters", function()
    local editor = text_editor_module.TextEditor:new(800, 600)
    editor:insert_text("你好世界")
    assert_equal(editor:get_text(), "你好世界")
    editor:cleanup()
end)

Test:add("Insert emoji", function()
    local editor = text_editor_module.TextEditor:new(800, 600)
    editor:insert_text("🚀 Rocket")
    local text = editor:get_text()
    assert_true(text:find("Rocket") ~= nil)
    editor:cleanup()
end)

Test:add("Insert mixed Unicode", function()
    local editor = text_editor_module.TextEditor:new(800, 600)
    local mixed_text = "Hello 世界 مرحبا 🎉"
    editor:insert_text(mixed_text)
    assert_equal(editor:get_text(), mixed_text)
    editor:cleanup()
end)

-- CURSOR MOVEMENT TESTS
Test:add("Cursor starts at (1,1)", function()
    local editor = text_editor_module.TextEditor:new(800, 600)
    assert_equal(editor.cursor_line, 1)
    assert_equal(editor.cursor_col, 1)
    editor:cleanup()
end)

Test:add("Move cursor right", function()
    local editor = text_editor_module.TextEditor:new(800, 600)
    editor:insert_text("ABC")
    editor:move_cursor(1, 1, false)
    editor:cursor_right(false)
    assert_equal(editor.cursor_col, 2)
    editor:cleanup()
end)

Test:add("Move cursor left", function()
    local editor = text_editor_module.TextEditor:new(800, 600)
    editor:insert_text("ABC")
    editor:move_cursor(1, 3, false)
    editor:cursor_left(false)
    assert_equal(editor.cursor_col, 2)
    editor:cleanup()
end)

Test:add("Move cursor to different lines", function()
    local editor = text_editor_module.TextEditor:new(800, 600)
    editor:insert_text("Line1\nLine2")
    assert_equal(editor.cursor_line, 2)
    editor:move_cursor(1, 1, false)
    assert_equal(editor.cursor_line, 1)
    editor:cleanup()
end)

-- DELETION TESTS
Test:add("Backspace removes character", function()
    local editor = text_editor_module.TextEditor:new(800, 600)
    editor:insert_text("ABC")
    editor:delete_char()
    assert_equal(editor:get_text(), "AB")
    editor:cleanup()
end)

Test:add("Delete forward removes character", function()
    local editor = text_editor_module.TextEditor:new(800, 600)
    editor:insert_text("ABC")
    editor:move_cursor(1, 2, false)
    editor:delete_char_forward()
    assert_equal(editor:get_text(), "AC")
    editor:cleanup()
end)

-- SELECTION TESTS
Test:add("Select all text", function()
    local editor = text_editor_module.TextEditor:new(800, 600)
    editor:insert_text("Hello")
    editor:select_all()
    assert_true(editor.selection_active)
    assert_equal(editor:get_selected_text(), "Hello")
    editor:cleanup()
end)

Test:add("Get selected text", function()
    local editor = text_editor_module.TextEditor:new(800, 600)
    editor:insert_text("Hello World")
    editor:move_cursor(1, 1, false)
    editor:move_cursor(1, 6, true)  -- Select "Hello"
    assert_equal(editor:get_selected_text(), "Hello")
    editor:cleanup()
end)

Test:add("Delete selection", function()
    local editor = text_editor_module.TextEditor:new(800, 600)
    editor:insert_text("Hello World")
    editor:move_cursor(1, 1, false)
    editor:move_cursor(1, 6, true)  -- Select "Hello"
    editor:delete_selection()
    assert_equal(editor:get_text(), " World")
    editor:cleanup()
end)

-- UNDO/REDO TESTS
Test:add("Undo single action", function()
    local editor = text_editor_module.TextEditor:new(800, 600)
    editor:insert_text("Hello")
    editor:undo()
    assert_equal(editor:get_text(), "")
    editor:cleanup()
end)

Test:add("Redo single action", function()
    local editor = text_editor_module.TextEditor:new(800, 600)
    editor:insert_text("Hello")
    editor:undo()
    editor:redo()
    assert_equal(editor:get_text(), "Hello")
    editor:cleanup()
end)

Test:add("Multiple undo operations", function()
    local editor = text_editor_module.TextEditor:new(800, 600)
    editor:insert_text("A")
    editor:insert_text("B")
    editor:insert_text("C")
    editor:undo()
    assert_equal(editor:get_text(), "AB")
    editor:undo()
    assert_equal(editor:get_text(), "A")
    editor:cleanup()
end)

-- LINE COUNT AND STATISTICS TESTS
Test:add("Line count for single line", function()
    local editor = text_editor_module.TextEditor:new(800, 600)
    editor:insert_text("Hello")
    assert_equal(editor:line_count(), 1)
    editor:cleanup()
end)

Test:add("Line count for multiple lines", function()
    local editor = text_editor_module.TextEditor:new(800, 600)
    editor:insert_text("Line1\nLine2\nLine3")
    assert_equal(editor:line_count(), 3)
    editor:cleanup()
end)

Test:add("Character count", function()
    local editor = text_editor_module.TextEditor:new(800, 600)
    editor:insert_text("Hello")
    -- Character count includes newlines
    assert_true(editor:char_count() >= 5)
    editor:cleanup()
end)

-- SET TEXT TESTS
Test:add("Set text replaces content", function()
    local editor = text_editor_module.TextEditor:new(800, 600)
    editor:insert_text("Old")
    editor:set_text("New")
    assert_equal(editor:get_text(), "New")
    editor:cleanup()
end)

Test:add("Set multiline text", function()
    local editor = text_editor_module.TextEditor:new(800, 600)
    editor:set_text("Line1\nLine2\nLine3")
    assert_equal(editor:line_count(), 3)
    editor:cleanup()
end)

-- FILE I/O TESTS
Test:add("Save and load UTF-8 file", function()
    local filepath = "/tmp/test_editor_utf8.txt"
    local original_text = "Hello 世界 🚀"
    
    text_io.save_file(filepath, original_text, "utf8")
    local loaded_text = text_io.load_file(filepath)
    
    assert_equal(loaded_text, original_text)
    os.remove(filepath)
end)

Test:add("Load file with BOM detection", function()
    local filepath = "/tmp/test_editor_bom.txt"
    local content = "Hello World"
    
    -- Save with UTF-8 BOM
    local file = io.open(filepath, "wb")
    file:write("\xEF\xBB\xBF" .. content)
    file:close()
    
    -- Load should detect and remove BOM
    local loaded = text_io.load_file(filepath)
    assert_equal(loaded, content)
    os.remove(filepath)
end)

Test:add("File round-trip preserves content", function()
    local filepath = "/tmp/test_editor_roundtrip.txt"
    local original_text = "Line 1\nLine 2\nLine 3 with emoji: 🎨"
    
    text_io.save_file(filepath, original_text, "utf8")
    local loaded_text = text_io.load_file(filepath)
    
    assert_equal(loaded_text, original_text)
    os.remove(filepath)
end)

Test:add("Get file size", function()
    local filepath = "/tmp/test_editor_size.txt"
    local content = "Hello"
    
    text_io.save_file(filepath, content, "utf8")
    local size = text_io.get_file_size(filepath)
    
    assert_true(size > 0)
    assert_equal(size, 5)  -- "Hello" = 5 bytes in ASCII
    os.remove(filepath)
end)

-- EDGE CASES
Test:add("Empty document", function()
    local editor = text_editor_module.TextEditor:new(800, 600)
    assert_equal(editor:get_text(), "")
    assert_equal(editor:line_count(), 1)
    editor:cleanup()
end)

Test:add("Very long line", function()
    local editor = text_editor_module.TextEditor:new(800, 600)
    local long_text = string.rep("A", 1000)
    editor:insert_text(long_text)
    assert_equal(#editor:get_text(), 1000)
    editor:cleanup()
end)

Test:add("Many lines", function()
    local editor = text_editor_module.TextEditor:new(800, 600)
    for i = 1, 100 do
        editor:insert_text("Line " .. i .. "\n")
    end
    assert_true(editor:line_count() > 90)
    editor:cleanup()
end)

Test:add("Cursor at end of document", function()
    local editor = text_editor_module.TextEditor:new(800, 600)
    editor:insert_text("Test")
    assert_equal(editor.cursor_col, 5)  -- After 4 chars
    editor:cleanup()
end)

Test:add("Handle special newlines", function()
    local editor = text_editor_module.TextEditor:new(800, 600)
    local content = text_io.load_file("sample_unicode_emoji.txt")
    if content then
        editor:set_text(content)
        assert_true(editor:line_count() > 1)
    end
    editor:cleanup()
end)

-- Run all tests
local success = Test:run()

if not success then
    os.exit(1)
else
    print("\nAll tests passed! ✓")
    os.exit(0)
end

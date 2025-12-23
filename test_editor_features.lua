#!/usr/bin/env luajit
-- test_editor_features.lua
-- Comprehensive test suite for TextEditor features
-- Tests all core functionality programmatically

local text_editor_module = require("lib.text_editor")
local text_io = require("lib.text_io")

-- Test counters
local tests_passed = 0
local tests_failed = 0
local test_results = {}

-- Helper function to assert
local function assert_equal(actual, expected, test_name)
    if actual == expected then
        table.insert(test_results, {name = test_name, passed = true, message = "OK"})
        tests_passed = tests_passed + 1
        return true
    else
        table.insert(test_results, {name = test_name, passed = false, 
                    message = string.format("Expected %q, got %q", expected, actual)})
        tests_failed = tests_failed + 1
        return false
    end
end

-- Helper function to assert true condition
local function assert_true(condition, test_name)
    if condition then
        table.insert(test_results, {name = test_name, passed = true, message = "OK"})
        tests_passed = tests_passed + 1
        return true
    else
        table.insert(test_results, {name = test_name, passed = false, message = "Condition is false"})
        tests_failed = tests_failed + 1
        return false
    end
end

-- Helper function for assertions with custom check
local function assert_check(condition, test_name, message)
    if condition then
        table.insert(test_results, {name = test_name, passed = true, message = "OK"})
        tests_passed = tests_passed + 1
        return true
    else
        table.insert(test_results, {name = test_name, passed = false, message = message or "Assertion failed"})
        tests_failed = tests_failed + 1
        return false
    end
end

-- Print test header
print("\n" .. string.rep("=", 80))
print("TextEditor Feature Test Suite")
print(string.rep("=", 80) .. "\n")

-- TEST 1: Basic instantiation
print("TEST 1: Basic Instantiation")
local editor = text_editor_module.TextEditor:new(800, 600, 14, "Monospace")
assert_check(editor ~= nil, "TEST_1_CREATE_EDITOR", "Editor instance created successfully")
assert_check(editor.width == 800, "TEST_1_WIDTH", "Editor width is 800")
assert_check(editor.height == 600, "TEST_1_HEIGHT", "Editor height is 600")
assert_check(editor.font_size == 14, "TEST_1_FONT_SIZE", "Font size is 14")
print()

-- TEST 2: Basic typing (insert_text)
print("TEST 2: Basic Text Insertion")
editor:set_text("")  -- Start with empty text
editor:insert_text("Hello")
assert_equal(editor:get_text(), "Hello", "TEST_2_BASIC_INSERT")

editor:set_text("")
editor:insert_text("World!")
assert_equal(editor:get_text(), "World!", "TEST_2_EXCLAMATION")

editor:set_text("")
editor:insert_text("Line1\nLine2\nLine3")
assert_equal(editor:line_count(), 3, "TEST_2_LINE_COUNT")
print()

-- TEST 3: Cursor movement
print("TEST 3: Cursor Movement")
editor:set_text("Hello World")
editor:move_cursor(1, 1, false)  -- Start at beginning
assert_equal(editor.cursor_line, 1, "TEST_3_CURSOR_LINE")
assert_equal(editor.cursor_col, 1, "TEST_3_CURSOR_COL")

editor:cursor_right(false)  -- Move right
assert_equal(editor.cursor_col, 2, "TEST_3_CURSOR_RIGHT")

editor:cursor_left(false)  -- Move left
assert_equal(editor.cursor_col, 1, "TEST_3_CURSOR_LEFT")

editor:set_text("Line1\nLine2")
editor:move_cursor(1, 1, false)
editor:cursor_down(false)  -- Move down to line 2
assert_equal(editor.cursor_line, 2, "TEST_3_CURSOR_DOWN")
print()

-- TEST 4: Selection
print("TEST 4: Text Selection")
editor:set_text("Hello World")
editor:select_all()
assert_check(editor.selection_active, "TEST_4_SELECT_ALL_ACTIVE", "Selection is active after select_all()")
local selected = editor:get_selected_text()
assert_equal(selected, "Hello World", "TEST_4_SELECT_ALL_TEXT")

-- Test selection with shift+arrow
editor:set_text("Hello")
editor:move_cursor(1, 1, false)
editor:cursor_right(true)  -- Shift+right to select 1st char
editor:cursor_right(true)  -- Shift+right to select 2nd char
selected = editor:get_selected_text()
assert_equal(selected, "He", "TEST_4_MANUAL_SELECT")
print()

-- TEST 5: Text deletion
print("TEST 5: Text Deletion")
editor:set_text("Hello World")
editor:move_cursor(1, 2, false)  -- At position 2 (after 'H')
editor:delete_char()  -- Delete 'H' (backspace)
assert_equal(editor:get_text(), "ello World", "TEST_5_DELETE_CHAR")

editor:set_text("Hello")
editor:move_cursor(1, 1, false)  -- At start
editor:delete_char_forward()  -- Delete forward
assert_equal(editor:get_text(), "ello", "TEST_5_DELETE_FORWARD")

editor:set_text("ABCDE")
editor:move_cursor(1, 1, false)
editor:cursor_right(true)
editor:cursor_right(true)
editor:cursor_right(true)  -- Select ABC
editor:delete_selection()
assert_equal(editor:get_text(), "DE", "TEST_5_DELETE_SELECTION")
print()

-- TEST 6: Undo/Redo
print("TEST 6: Undo/Redo")
editor:set_text("")
editor:insert_text("First")
editor:insert_text(" Second")
assert_equal(editor:get_text(), "First Second", "TEST_6_TWO_INSERTS")

editor:undo()
assert_equal(editor:get_text(), "First", "TEST_6_UNDO_ONE")

editor:undo()
assert_equal(editor:get_text(), "", "TEST_6_UNDO_ALL")

editor:redo()
assert_equal(editor:get_text(), "First", "TEST_6_REDO_ONE")

editor:redo()
assert_equal(editor:get_text(), "First Second", "TEST_6_REDO_ALL")
print()

-- TEST 7: Line and character counting
print("TEST 7: Line and Character Counting")
editor:set_text("Hello\nWorld\nTest")
assert_equal(editor:line_count(), 3, "TEST_7_LINE_COUNT")
assert_equal(editor:char_count(), 16, "TEST_7_CHAR_COUNT")  -- H,e,l,l,o,\n,W,o,r,l,d,\n,T,e,s,t

editor:set_text("Single line")
assert_equal(editor:line_count(), 1, "TEST_7_SINGLE_LINE")
assert_equal(editor:char_count(), 11, "TEST_7_SINGLE_CHAR")
print()

-- TEST 8: Copy/Paste simulation
print("TEST 8: Copy/Paste Simulation")
editor:set_text("Hello World Test")
editor:move_cursor(1, 1, false)
editor:cursor_right(true)
editor:cursor_right(true)
editor:cursor_right(true)
editor:cursor_right(true)
editor:cursor_right(true)  -- Select "Hello"
local copied = editor:get_selected_text()
assert_equal(copied, "Hello", "TEST_8_COPY")

editor:move_cursor(1, 12, false)  -- Move to position 12 (the space before 'T')
editor:insert_text(copied)  -- Paste "Hello" (result: "Hello World" + "Hello" + " Test")
assert_equal(editor:get_text(), "Hello World Hello Test", "TEST_8_PASTE")
print()

-- TEST 9: Cut simulation
print("TEST 9: Cut Simulation")
editor:set_text("To Delete This Text")
editor:move_cursor(1, 1, false)
editor:cursor_right(true)
editor:cursor_right(true)  -- Select "To"
local cut_text = editor:get_selected_text()
assert_equal(cut_text, "To", "TEST_9_CUT_COPY")

editor:delete_selection()  -- Delete the selection
assert_equal(editor:get_text(), " Delete This Text", "TEST_9_CUT_DELETE")
print()

-- TEST 10: File I/O
print("TEST 10: File I/O Operations")
local test_filepath = "/tmp/editor_test.txt"
editor:set_text("Test content with emoji 🎉 and unicode: café")

-- Save file
local success, save_err = text_io.save_file(test_filepath, editor:get_text(), "utf8")
assert_check(success, "TEST_10_SAVE_FILE", 
    success and "File saved successfully" or ("Save failed: " .. (save_err or "unknown")))

-- Load file
local loaded_content, encoding = text_io.load_file(test_filepath)
assert_check(loaded_content ~= nil, "TEST_10_LOAD_FILE", 
    loaded_content and "File loaded successfully" or "Failed to load file")

if loaded_content then
    assert_equal(loaded_content, editor:get_text(), "TEST_10_CONTENT_MATCH")
end
print()

-- TEST 11: Multiple operations
print("TEST 11: Combined Operations")
editor:set_text("")
editor:insert_text("Start")
editor:insert_text("\n")
editor:insert_text("Middle")
editor:insert_text("\n")
editor:insert_text("End")
assert_equal(editor:line_count(), 3, "TEST_11_LINE_COUNT")

editor:select_all()
local all_text = editor:get_selected_text()
assert_check(string.find(all_text, "Start") ~= nil and 
             string.find(all_text, "Middle") ~= nil and 
             string.find(all_text, "End") ~= nil,
             "TEST_11_SELECT_ALL_CONTENT", "All content selected correctly")
print()

-- TEST 12: Unicode/Emoji support
print("TEST 12: Unicode and Emoji Support")
editor:set_text("")
editor:insert_text("Hello 世界 🌍")
local text_with_unicode = editor:get_text()
assert_check(string.find(text_with_unicode, "世界") ~= nil, "TEST_12_CHINESE_CHARS", "Chinese characters preserved")
assert_check(string.find(text_with_unicode, "🌍") ~= nil, "TEST_12_EMOJI", "Emoji preserved")
print()

-- TEST 13: Edge cases
print("TEST 13: Edge Cases")
editor:set_text("")
assert_equal(editor:get_text(), "", "TEST_13_EMPTY_TEXT")
assert_equal(editor:line_count(), 1, "TEST_13_EMPTY_LINE_COUNT")

editor:insert_text("\n\n\n")
assert_equal(editor:line_count(), 4, "TEST_13_ONLY_NEWLINES")

editor:set_text("NoNewline")
assert_equal(editor:line_count(), 1, "TEST_13_NO_NEWLINE")

-- Test get_selected_text with no selection
editor:set_text("Text")
editor.selection_active = false
local no_selection = editor:get_selected_text()
assert_equal(no_selection, "", "TEST_13_NO_SELECTION_TEXT")
print()

-- TEST 14: Rendering (basic checks)
print("TEST 14: Rendering and Context")
editor:set_text("Render Test")
local render_ok, render_err = pcall(function()
    editor:render()
end)
assert_check(render_ok, "TEST_14_RENDER", 
    render_ok and "Rendering completed without error" or ("Render error: " .. (render_err or "unknown")))

local render_data = editor:get_render_data()
assert_check(render_data ~= nil, "TEST_14_RENDER_DATA", "Render data retrieved")
print()

-- TEST 15: Cleanup
print("TEST 15: Cleanup")
editor:cleanup()
-- Just verify no crash on cleanup
assert_check(true, "TEST_15_CLEANUP", "Cleanup completed successfully")
print()

-- Print results summary
print(string.rep("=", 80))
print("TEST SUMMARY")
print(string.rep("=", 80))

-- Group results by category
local categories = {}
for _, result in ipairs(test_results) do
    local test_name = result.name
    local category = string.match(test_name, "TEST_(%d+)")
    if not categories[category] then
        categories[category] = {}
    end
    table.insert(categories[category], result)
end

-- Print grouped results
for i = 1, 15 do
    local cat_tests = categories[tostring(i)]
    if cat_tests then
        local test_num = tostring(i)
        local passed_count = 0
        for _, result in ipairs(cat_tests) do
            if result.passed then passed_count = passed_count + 1 end
        end
        local status = (passed_count == #cat_tests) and "✓ PASS" or "✗ FAIL"
        print(string.format("Test %d: %s (%d/%d passed)", i, status, passed_count, #cat_tests))
        
        -- Print failed tests details
        for _, result in ipairs(cat_tests) do
            if not result.passed then
                print(string.format("  - %s: %s", result.name, result.message))
            end
        end
    end
end

print()
print(string.rep("=", 80))
print(string.format("TOTAL: %d PASSED, %d FAILED out of %d tests", 
    tests_passed, tests_failed, tests_passed + tests_failed))
print(string.rep("=", 80) .. "\n")

if tests_failed > 0 then
    print(string.format("⚠️  %d test(s) failed. Review output above for details.", tests_failed))
    os.exit(1)
else
    print("🎉 All tests passed!")
    os.exit(0)
end

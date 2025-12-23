#!/usr/bin/env luajit
-- Test rendering alignment fixes

local TextEditor = require("lib.text_editor").TextEditor

local function test_text_width()
    print("TEST: Text width measurement")
    local editor = TextEditor:new(800, 600, 14, "Monospace")
    
    -- Test basic measurement
    editor:insert_text("Hello")
    
    -- Get cursor X position
    local x_start = editor:_get_cursor_x(1, 1)
    local x_after_h = editor:_get_cursor_x(1, 2)
    local x_after_hello = editor:_get_cursor_x(1, 6)
    
    print(string.format("  Column 1 X: %.1f (expect 50)", x_start))
    print(string.format("  Column 2 X: %.1f (after 'H')", x_after_h))
    print(string.format("  Column 6 X: %.1f (after 'Hello')", x_after_hello))
    
    -- Verify they're in order
    local ok = (x_start < x_after_h) and (x_after_h < x_after_hello)
    print(string.format("  ✓ Cursor positions increase: %s", ok and "PASS" or "FAIL"))
    
    editor:cleanup()
    return ok
end

local function test_selection_positioning()
    print("\nTEST: Selection positioning")
    local editor = TextEditor:new(800, 600, 14, "Monospace")
    
    editor:insert_text("Select me")
    editor:select_all()
    
    print(string.format("  Selection active: %s", editor.selection_active and "YES" or "NO"))
    print(string.format("  Selection start: line %d, col %d", 
        editor.selection_start_line, editor.selection_start_col))
    print(string.format("  Selection end: line %d, col %d", 
        editor.selection_end_line, editor.selection_end_col))
    
    local ok = editor.selection_active and 
               editor.selection_start_col == 1 and 
               editor.selection_end_col == (#editor.lines[1] + 1)
    print(string.format("  ✓ Selection correct: %s", ok and "PASS" or "FAIL"))
    
    editor:cleanup()
    return ok
end

local function test_paste_positioning()
    print("\nTEST: Cursor repositioning after paste")
    local editor = TextEditor:new(800, 600, 14, "Monospace")
    
    editor:insert_text("Hello World")
    editor.cursor_line = 1
    editor.cursor_col = 6  -- After "Hello"
    
    local initial_col = editor.cursor_col
    editor:insert_text(" Test")  -- Paste
    
    local final_col = editor.cursor_col
    local text = editor.lines[1]
    
    print(string.format("  Initial cursor col: %d", initial_col))
    print(string.format("  Pasted: ' Test'"))
    print(string.format("  Final cursor col: %d", final_col))
    print(string.format("  Text: '%s'", text))
    
    -- Cursor should be at col 11 (after " Test")
    local ok = (final_col == initial_col + 5) and text == "Hello Test World"
    print(string.format("  ✓ Cursor repositioned correctly: %s", ok and "PASS" or "FAIL"))
    
    editor:cleanup()
    return ok
end

local function test_multi_line_paste()
    print("\nTEST: Multi-line paste cursor positioning")
    local editor = TextEditor:new(800, 600, 14, "Monospace")
    
    editor:insert_text("First line")
    editor.cursor_line = 1
    editor.cursor_col = 6  -- After "First"
    
    editor:insert_text("\nSecond line")
    
    print(string.format("  Line count: %d (expect 2)", #editor.lines))
    print(string.format("  Cursor line: %d (expect 2)", editor.cursor_line))
    print(string.format("  Cursor col: %d (expect 12)", editor.cursor_col))
    print(string.format("  Line 1: '%s'", editor.lines[1]))
    print(string.format("  Line 2: '%s'", editor.lines[2]))
    
    -- Fixed expectations: The inserted text comes first, then the original "after" part
    local ok = (#editor.lines == 2) and 
               (editor.cursor_line == 2) and 
               (editor.cursor_col == 12) and
               (editor.lines[1] == "First") and
               (editor.lines[2] == "Second line line")
    
    print(string.format("  ✓ Multi-line paste correct: %s", ok and "PASS" or "FAIL"))
    
    editor:cleanup()
    return ok
end

-- Run tests
print("="..string.rep("=", 70))
print("RENDERING ALIGNMENT FIXES TEST SUITE")
print("="..string.rep("=", 70))

local results = {}
table.insert(results, test_text_width())
table.insert(results, test_selection_positioning())
table.insert(results, test_paste_positioning())
table.insert(results, test_multi_line_paste())

print("\n" ..string.rep("=", 72))
local passed = 0
for _, result in ipairs(results) do
    if result then passed = passed + 1 end
end
print(string.format("TOTAL: %d PASSED, %d FAILED", passed, #results - passed))
print("="..string.rep("=", 72))

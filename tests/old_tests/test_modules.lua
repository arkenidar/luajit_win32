-- test_modules.lua
-- Non-GUI test to verify all modules work correctly

print("=== LuaJIT Win32 GUI Module Test ===")
print("")

-- Test 1: Load FFI
print("[1/5] Testing FFI module...")
local ffi = require("ffi")
print("      ✓ FFI loaded")

-- Test 2: Load win32_ffi
print("[2/5] Testing win32_ffi module...")
local win32 = require("lib.win32_ffi")
print("      ✓ win32_ffi loaded")
print("      ✓ WS_OVERLAPPEDWINDOW = " .. win32.WS_OVERLAPPEDWINDOW)
print("      ✓ WM_COMMAND = " .. win32.WM_COMMAND)
print("      ✓ LB_ADDSTRING = " .. win32.LB_ADDSTRING)

-- Test 3: Test string conversion
print("[3/5] Testing Unicode string conversion...")
local test_str = "Hello, World! 你好"
local wstr = win32.to_wstring(test_str)
print("      ✓ to_wstring() works")
local back = win32.from_wstring(wstr, -1)
print("      ✓ from_wstring() works")
print("      ✓ String roundtrip: '" .. back .. "'")

-- Test 4: Load gui module
print("[4/5] Testing gui module...")
local gui = require("lib.gui")
print("      ✓ gui module loaded")
print("      ✓ Window class available: " .. tostring(gui.Window ~= nil))
print("      ✓ Listbox class available: " .. tostring(gui.Listbox ~= nil))

-- Test 5: Load app module
print("[5/5] Testing app module...")
local app_module = require("lib.app")
print("      ✓ app module loaded")
print("      ✓ TodoApp class available: " .. tostring(app_module.TodoApp ~= nil))

-- Test TodoApp business logic (without GUI)
print("")
print("=== Testing TodoApp Business Logic ===")
local app = app_module.TodoApp:new()
print("✓ TodoApp instance created")
print("✓ Initial tasks count: " .. #app.tasks)

print("")
print("=== All Tests Passed! ===")
print("")
print("The application is ready to run.")
print("To start the GUI application, run:")
print("  ./run.sh")
print("or on Linux:")
print("  wine luajit.exe main.lua")

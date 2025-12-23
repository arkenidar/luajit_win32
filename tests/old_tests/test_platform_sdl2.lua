-- test_platform_sdl2.lua
-- Test SDL2 backend via platform layer

print("=== Platform Layer SDL2 Test ===")

local platform = require('lib.platform_layer')
platform.init()

print("Backend name:", platform:get_backend_name())

if platform:get_backend_name() == "sdl2" then
    print("✓ SDL2 backend loaded successfully via platform layer")
else
    print("✗ Expected SDL2 backend, got:", platform:get_backend_name())
end

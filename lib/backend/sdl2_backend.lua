-- sdl2_backend.lua
-- SDL2 Backend Implementation (WORK IN PROGRESS)
--
-- Current Status: Phase 2 Complete (SDL Base Abstraction)
-- ✅ Phase 1: Cairo FFI bindings (lib/ffi/cairo_ffi.lua)
-- ✅ Phase 2: SDL base abstraction (lib/sdl_base/sdl_api.lua, lib/ffi/sdl2_ffi.lua)
-- ⏳ Phase 3: SDL2 Backend Core (THIS FILE - stub only)
-- ⏳ Phase 4: Cairo-based custom widgets
-- ⏳ Phase 5: OpenGL compositor architecture
-- ⏳ Phase 6: Layout system integration
--
-- The SDL2 backend is not yet functional. Foundational components are ready:
-- - Cairo FFI bindings work (tested with test_cairo.lua)
-- - SDL2 FFI bindings work (tested with test_sdl2.lua)
-- - SDL abstraction layer provides unified API for SDL2/SDL3
--
-- To use the application, please specify --backend=win32:
--   luajit main.lua --backend=win32
--
-- Or set environment variable:
--   set PLATFORM_BACKEND=win32
--   luajit main.lua

local M = {}
M.__index = M

function M:init()
    error([[
SDL2 Backend is not yet implemented (Phase 3 in progress).

Current implementation status:
  ✅ Phase 1: Cairo FFI bindings complete
  ✅ Phase 2: SDL base abstraction complete
  ⏳ Phase 3: SDL2 backend core (in development)

Foundational components are ready and tested:
  - lib/ffi/cairo_ffi.lua (Cairo graphics - test_cairo.lua passes)
  - lib/ffi/sdl2_ffi.lua (SDL2 bindings - test_sdl2.lua passes)
  - lib/sdl_base/sdl_api.lua (SDL2/SDL3 abstraction layer)

To run the application, use the Win32 backend:
  luajit main.lua --backend=win32

Or set environment variable:
  set PLATFORM_BACKEND=win32

See plan file for implementation roadmap:
  .claude/plans/woolly-stirring-fox.md
]])
end

return M

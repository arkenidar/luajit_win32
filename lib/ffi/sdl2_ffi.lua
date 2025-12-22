-- sdl2_ffi.lua
-- SDL2 FFI bindings for LuaJIT
-- Minimal API surface for window management, surfaces, and events

local ffi = require("ffi")

-- SDL2 C API declarations
ffi.cdef[[
    // Initialization flags
    typedef uint32_t SDL_InitFlags;
    static const SDL_InitFlags SDL_INIT_VIDEO = 0x00000020;

    // Window flags
    typedef uint32_t SDL_WindowFlags;
    static const SDL_WindowFlags SDL_WINDOW_SHOWN = 0x00000004;
    static const SDL_WindowFlags SDL_WINDOW_RESIZABLE = 0x00000020;
    static const SDL_WindowFlags SDL_WINDOW_OPENGL = 0x00000002;

    // Window position constants
    static const int SDL_WINDOWPOS_UNDEFINED = 0x1FFF0000;
    static const int SDL_WINDOWPOS_CENTERED = 0x2FFF0000;

    // Opaque types
    typedef struct SDL_Window SDL_Window;

    // Surface structure (simplified - only fields we need)
    typedef struct SDL_PixelFormat {
        uint32_t format;
        // ... other fields omitted
    } SDL_PixelFormat;

    typedef struct SDL_Surface {
        uint32_t flags;
        SDL_PixelFormat *format;
        int w, h;
        int pitch;
        void *pixels;
        // ... other fields omitted
    } SDL_Surface;

    // Event types
    typedef enum {
        SDL_QUIT = 0x100,
        SDL_WINDOWEVENT = 0x200,
        SDL_KEYDOWN = 0x300,
        SDL_KEYUP = 0x301,
        SDL_TEXTINPUT = 0x303,
        SDL_MOUSEMOTION = 0x400,
        SDL_MOUSEBUTTONDOWN = 0x401,
        SDL_MOUSEBUTTONUP = 0x402
    } SDL_EventType;

    // Window event IDs
    typedef enum {
        SDL_WINDOWEVENT_NONE = 0,
        SDL_WINDOWEVENT_SIZE_CHANGED = 6
    } SDL_WindowEventID;

    // Keysym structure
    typedef struct SDL_Keysym {
        uint32_t scancode;
        int32_t sym;
        uint16_t mod;
        uint32_t unused;
    } SDL_Keysym;

    // Event structures
    typedef struct SDL_WindowEvent {
        uint32_t type;
        uint32_t timestamp;
        uint32_t windowID;
        uint8_t event;
        uint8_t padding1;
        uint8_t padding2;
        uint8_t padding3;
        int32_t data1;
        int32_t data2;
    } SDL_WindowEvent;

    typedef struct SDL_KeyboardEvent {
        uint32_t type;
        uint32_t timestamp;
        uint32_t windowID;
        uint8_t state;
        uint8_t repeat;
        uint8_t padding2;
        uint8_t padding3;
        SDL_Keysym keysym;
    } SDL_KeyboardEvent;

    typedef struct SDL_TextInputEvent {
        uint32_t type;
        uint32_t timestamp;
        uint32_t windowID;
        char text[32];
    } SDL_TextInputEvent;

    typedef struct SDL_MouseMotionEvent {
        uint32_t type;
        uint32_t timestamp;
        uint32_t windowID;
        uint32_t which;
        uint32_t state;
        int32_t x;
        int32_t y;
        int32_t xrel;
        int32_t yrel;
    } SDL_MouseMotionEvent;

    typedef struct SDL_MouseButtonEvent {
        uint32_t type;
        uint32_t timestamp;
        uint32_t windowID;
        uint32_t which;
        uint8_t button;
        uint8_t state;
        uint8_t clicks;
        uint8_t padding1;
        int32_t x;
        int32_t y;
    } SDL_MouseButtonEvent;

    // Event union (simplified - only events we handle)
    typedef union SDL_Event {
        uint32_t type;
        SDL_WindowEvent window;
        SDL_KeyboardEvent key;
        SDL_TextInputEvent text;
        SDL_MouseMotionEvent motion;
        SDL_MouseButtonEvent button;
        uint8_t padding[56];  // Ensure proper size
    } SDL_Event;

    // GL attribute enums
    typedef enum {
        SDL_GL_DOUBLEBUFFER = 5,
        SDL_GL_DEPTH_SIZE = 6
    } SDL_GLattr;

    // Opaque GL context type
    typedef void* SDL_GLContext;

    // Core functions
    int SDL_Init(uint32_t flags);
    void SDL_Quit(void);

    // Window functions
    SDL_Window* SDL_CreateWindow(const char *title, int x, int y, int w, int h, uint32_t flags);
    void SDL_DestroyWindow(SDL_Window *window);
    SDL_Surface* SDL_GetWindowSurface(SDL_Window *window);
    int SDL_UpdateWindowSurface(SDL_Window *window);

    // Event functions
    int SDL_PollEvent(SDL_Event *event);

    // Mouse functions
    uint32_t SDL_GetMouseState(int *x, int *y);

    // OpenGL functions
    int SDL_GL_SetAttribute(SDL_GLattr attr, int value);
    SDL_GLContext SDL_GL_CreateContext(SDL_Window *window);
    int SDL_GL_MakeCurrent(SDL_Window *window, SDL_GLContext context);
    void SDL_GL_SwapWindow(SDL_Window *window);
    void SDL_GL_DeleteContext(SDL_GLContext context);

    // Timer functions
    void SDL_Delay(uint32_t ms);
]]

-- Load SDL2 library
local sdl_lib
local ok, err = pcall(function()
    sdl_lib = ffi.load("SDL2")
end)

if not ok then
    error("Failed to load SDL2 library: " .. tostring(err))
end

-- Export SDL2 C library directly (like user's working implementation)
-- This avoids any indirection issues with function references
local M = {}
M.C = sdl_lib  -- Direct library access like user's code
M.ffi = ffi

-- Constants
M.SDL_INIT_VIDEO = 0x00000020
M.SDL_WINDOW_SHOWN = 0x00000004
M.SDL_WINDOW_RESIZABLE = 0x00000020
M.SDL_WINDOW_OPENGL = 0x00000002
M.SDL_WINDOWPOS_UNDEFINED = 0x1FFF0000
M.SDL_WINDOWPOS_CENTERED = 0x2FFF0000
M.SDL_QUIT = 0x100
M.SDL_WINDOWEVENT = 0x200
M.SDL_KEYDOWN = 0x300
M.SDL_KEYUP = 0x301
M.SDL_TEXTINPUT = 0x303
M.SDL_MOUSEMOTION = 0x400
M.SDL_MOUSEBUTTONDOWN = 0x401
M.SDL_MOUSEBUTTONUP = 0x402
M.SDL_WINDOWEVENT_SIZE_CHANGED = 6
M.SDL_GL_DOUBLEBUFFER = 5
M.SDL_GL_DEPTH_SIZE = 6

-- For backwards compatibility, create metatable to access functions directly
setmetatable(M, {
    __index = function(t, k)
        -- Allow direct access to SDL functions without .C prefix
        if type(k) == "string" and k:match("^SDL_") then
            return sdl_lib[k]
        end
        return rawget(t, k)
    end
})

return M

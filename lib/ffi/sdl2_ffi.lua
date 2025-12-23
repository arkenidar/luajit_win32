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
        SDL_WINDOWEVENT_SHOWN = 1,
        SDL_WINDOWEVENT_HIDDEN = 2,
        SDL_WINDOWEVENT_EXPOSED = 3,
        SDL_WINDOWEVENT_MOVED = 4,
        SDL_WINDOWEVENT_RESIZED = 5,
        SDL_WINDOWEVENT_SIZE_CHANGED = 6,
        SDL_WINDOWEVENT_MINIMIZED = 7,
        SDL_WINDOWEVENT_MAXIMIZED = 8,
        SDL_WINDOWEVENT_RESTORED = 9,
        SDL_WINDOWEVENT_ENTER = 10,
        SDL_WINDOWEVENT_LEAVE = 11,
        SDL_WINDOWEVENT_FOCUS_GAINED = 12,
        SDL_WINDOWEVENT_FOCUS_LOST = 13,
        SDL_WINDOWEVENT_CLOSE = 14
    } SDL_WindowEventID;

    // Key symbols (common ones used in text editor)
    typedef enum {
        SDLK_ESCAPE = 27,
        SDLK_RETURN = 13,
        SDLK_BACKSPACE = 8,
        SDLK_DELETE = 127,
        SDLK_TAB = 9,
        SDLK_a = 97,
        SDLK_c = 99,
        SDLK_s = 115,
        SDLK_v = 118,
        SDLK_x = 120,
        SDLK_y = 121,
        SDLK_z = 122,
        SDLK_HOME = 1073741882,
        SDLK_END = 1073741881,
        SDLK_LEFT = 1073741904,
        SDLK_RIGHT = 1073741903,
        SDLK_UP = 1073741906,
        SDLK_DOWN = 1073741905,
        SDLK_PAGEUP = 1073741899,
        SDLK_PAGEDOWN = 1073741900
    } SDL_Keycode;

    // Key modifiers
    typedef enum {
        KMOD_SHIFT = 3,
        KMOD_CTRL = 192,
        KMOD_ALT = 768
    } SDL_Keymod;

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

    // Renderer types
    typedef struct SDL_Renderer SDL_Renderer;
    typedef struct SDL_Texture SDL_Texture;

    // Renderer flags
    typedef enum {
        SDL_RENDERER_SOFTWARE = 0x00000001,
        SDL_RENDERER_ACCELERATED = 0x00000002,
        SDL_RENDERER_PRESENTVSYNC = 0x00000004,
        SDL_RENDERER_TARGETTEXTURE = 0x00000008
    } SDL_RendererFlags;

    // Pixel format enums
    typedef enum {
        SDL_PIXELFORMAT_UNKNOWN = 0,
        SDL_PIXELFORMAT_INDEX1LSB = 0x11100100,
        SDL_PIXELFORMAT_INDEX8 = 0x13000801,
        SDL_PIXELFORMAT_RGB24 = 0x16161804,
        SDL_PIXELFORMAT_RGB32 = 0x16888888,
        SDL_PIXELFORMAT_ARGB8888 = 0x16934888,
        SDL_PIXELFORMAT_RGBA8888 = 0x16888888
    } SDL_PixelFormatEnum;

    // Texture access types
    typedef enum {
        SDL_TEXTUREACCESS_STATIC = 0,
        SDL_TEXTUREACCESS_STREAMING = 1,
        SDL_TEXTUREACCESS_TARGET = 2
    } SDL_TextureAccess;

    // Rect structure
    typedef struct {
        int x, y, w, h;
    } SDL_Rect;

    // Renderer functions
    SDL_Renderer* SDL_CreateRenderer(SDL_Window *window, int index, uint32_t flags);
    void SDL_DestroyRenderer(SDL_Renderer *renderer);
    int SDL_SetRenderDrawColor(SDL_Renderer *renderer, uint8_t r, uint8_t g, uint8_t b, uint8_t a);
    int SDL_RenderClear(SDL_Renderer *renderer);
    void SDL_RenderPresent(SDL_Renderer *renderer);

    // Texture functions
    SDL_Texture* SDL_CreateTexture(SDL_Renderer *renderer, uint32_t format, int access, int w, int h);
    void SDL_DestroyTexture(SDL_Texture *texture);
    int SDL_UpdateTexture(SDL_Texture *texture, const SDL_Rect *rect, const void *pixels, int pitch);
    int SDL_RenderCopy(SDL_Renderer *renderer, SDL_Texture *texture, const SDL_Rect *srcrect, const SDL_Rect *dstrect);
    int SDL_RenderFillRect(SDL_Renderer *renderer, const SDL_Rect *rect);

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
M.SDL_WINDOWEVENT_NONE = 0
M.SDL_WINDOWEVENT_SHOWN = 1
M.SDL_WINDOWEVENT_HIDDEN = 2
M.SDL_WINDOWEVENT_EXPOSED = 3
M.SDL_WINDOWEVENT_MOVED = 4
M.SDL_WINDOWEVENT_RESIZED = 5
M.SDL_WINDOWEVENT_SIZE_CHANGED = 6
M.SDL_WINDOWEVENT_MINIMIZED = 7
M.SDL_WINDOWEVENT_MAXIMIZED = 8
M.SDL_WINDOWEVENT_RESTORED = 9
M.SDL_WINDOWEVENT_ENTER = 10
M.SDL_WINDOWEVENT_LEAVE = 11
M.SDL_WINDOWEVENT_FOCUS_GAINED = 12
M.SDL_WINDOWEVENT_FOCUS_LOST = 13
M.SDL_WINDOWEVENT_CLOSE = 14
M.SDL_GL_DOUBLEBUFFER = 5
M.SDL_GL_DEPTH_SIZE = 6

-- Key constants
M.SDLK_ESCAPE = 27
M.SDLK_RETURN = 13
M.SDLK_BACKSPACE = 8
M.SDLK_DELETE = 127
M.SDLK_TAB = 9
M.SDLK_a = 97
M.SDLK_c = 99
M.SDLK_s = 115
M.SDLK_v = 118
M.SDLK_x = 120
M.SDLK_y = 121
M.SDLK_z = 122
M.SDLK_HOME = 1073741882
M.SDLK_END = 1073741881
M.SDLK_LEFT = 1073741904
M.SDLK_RIGHT = 1073741903
M.SDLK_UP = 1073741906
M.SDLK_DOWN = 1073741905
M.SDLK_PAGEUP = 1073741899
M.SDLK_PAGEDOWN = 1073741900

-- Keyboard modifier constants
M.KMOD_SHIFT = 3
M.KMOD_CTRL = 192
M.KMOD_ALT = 768

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

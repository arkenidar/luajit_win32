-- opengl_ffi.lua
-- OpenGL FFI bindings for Windows
-- Provides access to OpenGL 1.1 functions via opengl32.dll and gdi32.dll

local ffi = require("ffi")

local M = {}

-- Load required DLLs
local user32 = ffi.load("user32")
local gdi32 = ffi.load("gdi32")
local opengl32 = ffi.load("opengl32")

-- OpenGL type definitions
ffi.cdef[[
  typedef unsigned int GLenum;
  typedef unsigned int GLuint;
  typedef int GLint;
  typedef int GLsizei;
  typedef float GLfloat;
  typedef double GLdouble;
  typedef unsigned char GLubyte;
  typedef void GLvoid;
  typedef unsigned int GLbitfield;
  typedef signed char GLbyte;
  typedef short GLshort;
  typedef unsigned short GLushort;
  typedef bool GLboolean;
]]

-- GDI32 structures and functions for pixel format
ffi.cdef[[
  typedef void* HDC;
  typedef void* HGLRC;
  typedef struct tagHWND__* HWND;

  typedef struct tagPIXELFORMATDESCRIPTOR {
    unsigned short nSize;
    unsigned short nVersion;
    unsigned int   dwFlags;
    unsigned char  iPixelType;
    unsigned char  cColorBits;
    unsigned char  cRedBits;
    unsigned char  cRedShift;
    unsigned char  cGreenBits;
    unsigned char  cGreenShift;
    unsigned char  cBlueBits;
    unsigned char  cBlueShift;
    unsigned char  cAlphaBits;
    unsigned char  cAlphaShift;
    unsigned char  cAccumBits;
    unsigned char  cAccumRedBits;
    unsigned char  cAccumGreenBits;
    unsigned char  cAccumBlueBits;
    unsigned char  cAccumAlphaBits;
    unsigned char  cDepthBits;
    unsigned char  cStencilBits;
    unsigned char  cAuxBuffers;
    unsigned char  iLayerType;
    unsigned char  bReserved;
    unsigned int   dwLayerMask;
    unsigned int   dwVisibleMask;
    unsigned int   dwDamageMask;
  } PIXELFORMATDESCRIPTOR;

  HDC GetDC(HWND hWnd);
  int ReleaseDC(HWND hWnd, HDC hDC);
  int ChoosePixelFormat(HDC hdc, const PIXELFORMATDESCRIPTOR* ppfd);
  int SetPixelFormat(HDC hdc, int format, const PIXELFORMATDESCRIPTOR* ppfd);
  int DescribePixelFormat(HDC hdc, int iPixelFormat, unsigned int nBytes, PIXELFORMATDESCRIPTOR* ppfd);
  int SwapBuffers(HDC hdc);
]]

-- WGL (Windows OpenGL) functions
ffi.cdef[[
  HGLRC wglCreateContext(HDC hdc);
  int wglDeleteContext(HGLRC hglrc);
  int wglMakeCurrent(HDC hdc, HGLRC hglrc);
  void* wglGetProcAddress(const char* name);
]]

-- Core OpenGL 1.1 functions
ffi.cdef[[
  void glClear(GLbitfield mask);
  void glClearColor(GLfloat red, GLfloat green, GLfloat blue, GLfloat alpha);
  void glLoadIdentity(void);
  void glMatrixMode(GLenum mode);
  void glViewport(GLint x, GLint y, GLsizei width, GLsizei height);
  void glOrtho(GLdouble left, GLdouble right, GLdouble bottom, GLdouble top, GLdouble near, GLdouble far);
  void glFrustum(GLdouble left, GLdouble right, GLdouble bottom, GLdouble top, GLdouble near, GLdouble far);
  void glRotatef(GLfloat angle, GLfloat x, GLfloat y, GLfloat z);
  void glTranslatef(GLfloat x, GLfloat y, GLfloat z);
  void glScalef(GLfloat x, GLfloat y, GLfloat z);
  void glBegin(GLenum mode);
  void glEnd(void);
  void glVertex3f(GLfloat x, GLfloat y, GLfloat z);
  void glVertex2f(GLfloat x, GLfloat y);
  void glColor3f(GLfloat red, GLfloat green, GLfloat blue);
  void glColor4f(GLfloat red, GLfloat green, GLfloat blue, GLfloat alpha);
  void glEnable(GLenum cap);
  void glDisable(GLenum cap);
  void glFlush(void);
  const GLubyte* glGetString(GLenum name);
]]

-- Export GDI32/User32 functions
M.GetDC = user32.GetDC
M.ReleaseDC = user32.ReleaseDC
M.ChoosePixelFormat = gdi32.ChoosePixelFormat
M.SetPixelFormat = gdi32.SetPixelFormat
M.DescribePixelFormat = gdi32.DescribePixelFormat
M.SwapBuffers = gdi32.SwapBuffers

-- Export WGL functions
M.wglCreateContext = opengl32.wglCreateContext
M.wglDeleteContext = opengl32.wglDeleteContext
M.wglMakeCurrent = opengl32.wglMakeCurrent
M.wglGetProcAddress = opengl32.wglGetProcAddress

-- Export OpenGL functions
M.glClear = opengl32.glClear
M.glClearColor = opengl32.glClearColor
M.glLoadIdentity = opengl32.glLoadIdentity
M.glMatrixMode = opengl32.glMatrixMode
M.glViewport = opengl32.glViewport
M.glOrtho = opengl32.glOrtho
M.glFrustum = opengl32.glFrustum
M.glRotatef = opengl32.glRotatef
M.glTranslatef = opengl32.glTranslatef
M.glScalef = opengl32.glScalef
M.glBegin = opengl32.glBegin
M.glEnd = opengl32.glEnd
M.glVertex3f = opengl32.glVertex3f
M.glVertex2f = opengl32.glVertex2f
M.glColor3f = opengl32.glColor3f
M.glColor4f = opengl32.glColor4f
M.glEnable = opengl32.glEnable
M.glDisable = opengl32.glDisable
M.glFlush = opengl32.glFlush
M.glGetString = opengl32.glGetString

-- Pixel Format Descriptor constants
M.PFD_DRAW_TO_WINDOW = 0x00000004
M.PFD_SUPPORT_OPENGL = 0x00000020
M.PFD_DOUBLEBUFFER = 0x00000001
M.PFD_TYPE_RGBA = 0
M.PFD_MAIN_PLANE = 0

-- OpenGL constants
M.GL_COLOR_BUFFER_BIT = 0x00004000
M.GL_DEPTH_BUFFER_BIT = 0x00000100
M.GL_MODELVIEW = 0x1700
M.GL_PROJECTION = 0x1701
M.GL_TRIANGLES = 0x0004
M.GL_QUADS = 0x0007
M.GL_DEPTH_TEST = 0x0B71
M.GL_VENDOR = 0x1F00
M.GL_RENDERER = 0x1F01
M.GL_VERSION = 0x1F02

-- Helper function to create pixel format descriptor
function M.create_pixel_format_descriptor()
    local pfd = ffi.new("PIXELFORMATDESCRIPTOR")
    pfd.nSize = ffi.sizeof("PIXELFORMATDESCRIPTOR")
    pfd.nVersion = 1
    pfd.dwFlags = M.PFD_DRAW_TO_WINDOW + M.PFD_SUPPORT_OPENGL + M.PFD_DOUBLEBUFFER
    pfd.iPixelType = M.PFD_TYPE_RGBA
    pfd.cColorBits = 24
    pfd.cDepthBits = 16
    pfd.iLayerType = M.PFD_MAIN_PLANE
    return pfd
end

-- Helper function to initialize OpenGL context
function M.init_opengl_context(hwnd)
    -- Get device context
    local hdc = M.GetDC(hwnd)
    if hdc == nil then
        error("Failed to get device context")
    end

    -- Create and set pixel format
    local pfd = M.create_pixel_format_descriptor()
    local pixel_format = M.ChoosePixelFormat(hdc, pfd)
    if pixel_format == 0 then
        M.ReleaseDC(hwnd, hdc)
        error("Failed to choose pixel format")
    end

    if M.SetPixelFormat(hdc, pixel_format, pfd) == 0 then
        M.ReleaseDC(hwnd, hdc)
        error("Failed to set pixel format")
    end

    -- Create OpenGL context
    local hglrc = M.wglCreateContext(hdc)
    if hglrc == nil then
        M.ReleaseDC(hwnd, hdc)
        error("Failed to create OpenGL context")
    end

    -- Make context current
    if M.wglMakeCurrent(hdc, hglrc) == 0 then
        M.wglDeleteContext(hglrc)
        M.ReleaseDC(hwnd, hdc)
        error("Failed to make OpenGL context current")
    end

    -- Enable depth testing
    M.glEnable(M.GL_DEPTH_TEST)

    return hdc, hglrc
end

-- Helper function to cleanup OpenGL context
function M.cleanup_opengl_context(hwnd, hdc, hglrc)
    if hglrc ~= nil then
        M.wglMakeCurrent(nil, nil)
        M.wglDeleteContext(hglrc)
    end

    if hdc ~= nil and hwnd ~= nil then
        M.ReleaseDC(hwnd, hdc)
    end
end

return M

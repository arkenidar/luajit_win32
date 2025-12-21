-- gl_renderer.lua
-- OpenGL renderer for 3D rotating cube

local gl = require("lib.opengl_ffi")

local M = {}

-- Cube geometry: 8 vertices
local vertices = {
    {-1, -1,  1},  -- Front bottom-left (0)
    { 1, -1,  1},  -- Front bottom-right (1)
    { 1,  1,  1},  -- Front top-right (2)
    {-1,  1,  1},  -- Front top-left (3)
    {-1, -1, -1},  -- Back bottom-left (4)
    { 1, -1, -1},  -- Back bottom-right (5)
    { 1,  1, -1},  -- Back top-right (6)
    {-1,  1, -1},  -- Back top-left (7)
}

-- Cube faces (using GL_QUADS - 4 vertices per face)
local faces = {
    {0, 1, 2, 3},  -- Front face
    {5, 4, 7, 6},  -- Back face
    {4, 0, 3, 7},  -- Left face
    {1, 5, 6, 2},  -- Right face
    {3, 2, 6, 7},  -- Top face
    {4, 5, 1, 0},  -- Bottom face
}

-- Face colors (RGB + CMY)
local colors = {
    {1.0, 0.0, 0.0},  -- Front: Red
    {0.0, 1.0, 0.0},  -- Back: Green
    {0.0, 0.0, 1.0},  -- Left: Blue
    {1.0, 1.0, 0.0},  -- Right: Yellow
    {1.0, 0.0, 1.0},  -- Top: Magenta
    {0.0, 1.0, 1.0},  -- Bottom: Cyan
}

-- GLRenderer class
local GLRenderer = {}
GLRenderer.__index = GLRenderer

function GLRenderer:new(hwnd, width, height)
    local self = setmetatable({}, GLRenderer)

    self.hwnd = hwnd
    self.width = width
    self.height = height
    self.rotation_x = 0.0
    self.rotation_y = 0.0
    self.rotation_z = 0.0

    -- Initialize OpenGL context
    self.hdc, self.hglrc = gl.init_opengl_context(hwnd)

    -- Setup viewport and projection
    self:setup_viewport(width, height)

    -- Set clear color (dark gray background)
    gl.glClearColor(0.2, 0.2, 0.2, 1.0)

    return self
end

function GLRenderer:setup_viewport(width, height)
    self.width = width
    self.height = height

    -- Set viewport
    gl.glViewport(0, 0, width, height)

    -- Setup projection matrix with perspective
    gl.glMatrixMode(gl.GL_PROJECTION)
    gl.glLoadIdentity()

    -- Calculate perspective projection
    local aspect = width / height
    local fov = 45.0  -- Field of view in degrees
    local near = 0.1
    local far = 100.0

    -- Manual perspective calculation using glFrustum
    local fov_rad = math.rad(fov / 2.0)
    local f = near * math.tan(fov_rad)
    local left = -aspect * f
    local right = aspect * f
    local bottom = -f
    local top = f

    gl.glFrustum(left, right, bottom, top, near, far)

    -- Switch back to modelview matrix
    gl.glMatrixMode(gl.GL_MODELVIEW)
end

function GLRenderer:update(delta_time)
    -- Update rotation angles (different speeds for each axis)
    self.rotation_x = (self.rotation_x + 50.0 * delta_time) % 360.0
    self.rotation_y = (self.rotation_y + 75.0 * delta_time) % 360.0
    self.rotation_z = (self.rotation_z + 25.0 * delta_time) % 360.0
end

function GLRenderer:render()
    -- Clear color and depth buffers
    gl.glClear(gl.GL_COLOR_BUFFER_BIT + gl.GL_DEPTH_BUFFER_BIT)

    -- Setup modelview matrix
    gl.glMatrixMode(gl.GL_MODELVIEW)
    gl.glLoadIdentity()

    -- Move camera back to see the cube
    gl.glTranslatef(0.0, 0.0, -5.0)

    -- Apply rotations
    gl.glRotatef(self.rotation_x, 1.0, 0.0, 0.0)
    gl.glRotatef(self.rotation_y, 0.0, 1.0, 0.0)
    gl.glRotatef(self.rotation_z, 0.0, 0.0, 1.0)

    -- Draw cube faces
    for i = 1, #faces do
        local face = faces[i]
        local color = colors[i]

        -- Set face color
        gl.glColor3f(color[1], color[2], color[3])

        -- Draw face as quad
        gl.glBegin(gl.GL_QUADS)
        for j = 1, 4 do
            local vertex_idx = face[j] + 1  -- Lua is 1-indexed
            local v = vertices[vertex_idx]
            gl.glVertex3f(v[1], v[2], v[3])
        end
        gl.glEnd()
    end

    -- Swap buffers for double buffering
    gl.SwapBuffers(self.hdc)
end

function GLRenderer:resize(width, height)
    self:setup_viewport(width, height)
    self:render()
end

function GLRenderer:cleanup()
    gl.cleanup_opengl_context(self.hwnd, self.hdc, self.hglrc)
    self.hdc = nil
    self.hglrc = nil
end

M.GLRenderer = GLRenderer

return M

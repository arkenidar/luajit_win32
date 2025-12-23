-- fontconfig_ffi.lua
-- Fontconfig FFI bindings for custom font loading
-- Allows programmatic font directory registration

local ffi = require("ffi")

ffi.cdef[[
    typedef struct _FcConfig FcConfig;

    // Fontconfig initialization and configuration
    int FcInit(void);
    FcConfig* FcConfigGetCurrent(void);
    int FcConfigAppFontAddDir(FcConfig *config, const unsigned char *dir);
    int FcConfigBuildFonts(FcConfig *config);
    void FcConfigDestroy(FcConfig *config);
]]

-- Try to load fontconfig library
local fc_lib
local ok, err = pcall(function()
    local msys2_path = "C:\\Ruby34-x64\\msys64\\mingw64\\bin\\"

    local fc_ok, fc_result = pcall(function()
        return ffi.load(msys2_path .. "libfontconfig-1.dll")
    end)

    if fc_ok then
        fc_lib = fc_result
    else
        -- Try system-wide library names
        local fc_ok2, fc_result2 = pcall(function() return ffi.load("fontconfig") end)
        if fc_ok2 then
            fc_lib = fc_result2
        else
            fc_lib = ffi.load("libfontconfig-1")
        end
    end
end)

local M = {}

if ok and fc_lib then
    M.fc = fc_lib
    M.ffi = ffi
    M.available = true

    -- Helper to add custom font directory
    function M.add_font_dir(dir_path)
        -- Initialize fontconfig if not already done
        fc_lib.FcInit()

        -- Get current config
        local config = fc_lib.FcConfigGetCurrent()
        if config == nil then
            return false, "Failed to get fontconfig"
        end

        -- Add directory
        local dir_cstr = ffi.cast("const unsigned char*", dir_path)
        local result = fc_lib.FcConfigAppFontAddDir(config, dir_cstr)

        if result == 0 then
            return false, "Failed to add font directory"
        end

        -- Rebuild font cache
        fc_lib.FcConfigBuildFonts(config)

        return true
    end
else
    M.available = false
    M.add_font_dir = function() return false, "Fontconfig not available" end
end

return M

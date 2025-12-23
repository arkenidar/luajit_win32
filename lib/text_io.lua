-- text_io.lua
-- Unicode text file I/O with UTF-8 support
-- Handles loading and saving text files with proper encoding

local M = {}

-- Detect file encoding by BOM (Byte Order Mark)
local function detect_encoding(file_content)
    if not file_content or #file_content == 0 then
        return "utf8"
    end
    
    local byte1, byte2, byte3 = file_content:byte(1, 3)
    
    -- UTF-8 BOM: EF BB BF
    if byte1 == 0xEF and byte2 == 0xBB and byte3 == 0xBF then
        return "utf8-bom"
    end
    
    -- UTF-16 LE BOM: FF FE
    if byte1 == 0xFF and byte2 == 0xFE then
        return "utf16-le"
    end
    
    -- UTF-16 BE BOM: FE FF
    if byte1 == 0xFE and byte2 == 0xFF then
        return "utf16-be"
    end
    
    -- UTF-32 LE BOM: FF FE 00 00
    local byte4 = file_content:byte(4)
    if byte1 == 0xFF and byte2 == 0xFE and byte3 == 0x00 and byte4 == 0x00 then
        return "utf32-le"
    end
    
    -- UTF-32 BE BOM: 00 00 FE FF
    if byte1 == 0x00 and byte2 == 0x00 and byte3 == 0xFE and byte4 == 0xFF then
        return "utf32-be"
    end
    
    -- Default to UTF-8
    return "utf8"
end

-- Remove BOM from content if present
local function remove_bom(content, encoding)
    if encoding == "utf8-bom" then
        return content:sub(4)  -- Skip EF BB BF
    elseif encoding == "utf16-le" or encoding == "utf16-be" then
        return content:sub(3)  -- Skip FF FE or FE FF
    elseif encoding == "utf32-le" or encoding == "utf32-be" then
        return content:sub(5)  -- Skip 4-byte BOM
    end
    return content
end

-- Convert UTF-16 LE to UTF-8
local function utf16le_to_utf8(data)
    local result = ""
    local i = 1
    
    while i < #data do
        local byte1 = data:byte(i)
        local byte2 = data:byte(i + 1)
        
        if byte1 == nil or byte2 == nil then break end
        
        local codepoint = byte1 + (byte2 * 256)
        
        if codepoint < 0x80 then
            result = result .. string.char(codepoint)
        elseif codepoint < 0x800 then
            result = result .. 
                string.char(0xC0 + math.floor(codepoint / 64)) ..
                string.char(0x80 + (codepoint % 64))
        else
            result = result ..
                string.char(0xE0 + math.floor(codepoint / 4096)) ..
                string.char(0x80 + math.floor((codepoint / 64) % 64)) ..
                string.char(0x80 + (codepoint % 64))
        end
        
        i = i + 2
    end
    
    return result
end

-- Convert UTF-8 to UTF-16 LE
local function utf8_to_utf16le(text)
    local result = ""
    local i = 1
    
    while i <= #text do
        local byte = text:byte(i)
        local codepoint
        
        if byte < 0x80 then
            codepoint = byte
            i = i + 1
        elseif byte < 0xE0 then
            codepoint = ((byte - 0xC0) * 64) + (text:byte(i + 1) - 0x80)
            i = i + 2
        elseif byte < 0xF0 then
            codepoint = ((byte - 0xE0) * 4096) + 
                       ((text:byte(i + 1) - 0x80) * 64) +
                       (text:byte(i + 2) - 0x80)
            i = i + 3
        else
            -- For surrogate pairs and higher codepoints, just copy bytes for now
            codepoint = byte
            i = i + 1
        end
        
        result = result .. string.char(codepoint % 256) .. 
                          string.char(math.floor(codepoint / 256))
    end
    
    return result
end

-- Normalize line endings to \n
local function normalize_line_endings(content)
    -- Handle CRLF (\r\n) and CR (\r)
    content = content:gsub("\r\n", "\n")
    content = content:gsub("\r", "\n")
    return content
end

-- Load text file with automatic encoding detection
function M.load_file(filepath)
    local file, err = io.open(filepath, "rb")
    if not file then
        return nil, "Cannot open file: " .. err
    end
    
    local content = file:read("*a")
    file:close()
    
    -- Detect encoding
    local encoding = detect_encoding(content)
    
    -- Remove BOM if present
    content = remove_bom(content, encoding)
    
    -- Convert to UTF-8 if needed
    if encoding == "utf16-le" or encoding == "utf16-bom-le" then
        content = utf16le_to_utf8(content)
    elseif encoding:match("utf16") then
        return nil, "UTF-16 BE conversion not yet implemented"
    elseif encoding:match("utf32") then
        return nil, "UTF-32 conversion not yet implemented"
    end
    
    -- Normalize line endings
    content = normalize_line_endings(content)
    
    return content, encoding
end

-- Save text file in UTF-8 with optional BOM
function M.save_file(filepath, content, encoding)
    encoding = encoding or "utf8"
    
    local file, err = io.open(filepath, "wb")
    if not file then
        return false, "Cannot open file for writing: " .. err
    end
    
    local output = content
    
    -- Add BOM if requested
    if encoding == "utf8-bom" then
        output = "\xEF\xBB\xBF" .. output
    elseif encoding == "utf16-le" then
        output = "\xFF\xFE" .. utf8_to_utf16le(content)
    end
    
    -- Ensure Unix-style line endings
    output = output:gsub("\r\n", "\n")
    
    file:write(output)
    file:close()
    
    return true
end

-- Check if file is likely text (by sampling content)
function M.is_text_file(filepath, sample_size)
    sample_size = sample_size or 512
    
    local file, err = io.open(filepath, "rb")
    if not file then
        return false
    end
    
    local sample = file:read(sample_size)
    file:close()
    
    if not sample then
        return true  -- Empty files are text
    end
    
    -- Count null bytes (binary files often have them)
    local null_count = 0
    for i = 1, #sample do
        if sample:byte(i) == 0 then
            null_count = null_count + 1
        end
    end
    
    -- If more than 10% null bytes, likely binary
    return null_count < (#sample / 10)
end

-- Get file info (size, modification time, etc.)
function M.get_file_info(filepath)
    local file, err = io.open(filepath, "rb")
    if not file then
        return nil, err
    end
    
    local size = file:seek("end")
    file:close()
    
    return {
        filepath = filepath,
        size = size,
        exists = true,
        is_readable = true
    }
end

-- Get file size in bytes
function M.get_file_size(filepath)
    local file, err = io.open(filepath, "rb")
    if not file then
        return nil
    end
    
    local size = file:seek("end")
    file:close()
    
    return size
end

-- Create backup before saving
function M.create_backup(filepath)
    local backup_path = filepath .. ".bak"
    local file_in, err = io.open(filepath, "rb")
    
    if not file_in then
        return true  -- No file to backup
    end
    
    local content = file_in:read("*a")
    file_in:close()
    
    local file_out = io.open(backup_path, "wb")
    if not file_out then
        return false, "Cannot create backup"
    end
    
    file_out:write(content)
    file_out:close()
    
    return true
end

-- List recent files
function M.get_recent_files(config_path, limit)
    limit = limit or 10
    
    local file = io.open(config_path or os.getenv("HOME") .. "/.text_editor_recent", "r")
    if not file then
        return {}
    end
    
    local recent = {}
    local count = 0
    
    for line in file:lines() do
        if count >= limit then break end
        table.insert(recent, line)
        count = count + 1
    end
    
    file:close()
    return recent
end

-- Add to recent files
function M.add_recent_file(filepath, config_path)
    local recent = M.get_recent_files(config_path, 9)
    
    -- Remove if already exists
    for i, f in ipairs(recent) do
        if f == filepath then
            table.remove(recent, i)
            break
        end
    end
    
    -- Add to front
    table.insert(recent, 1, filepath)
    
    -- Write back
    local file = io.open(config_path or os.getenv("HOME") .. "/.text_editor_recent", "w")
    if file then
        for _, f in ipairs(recent) do
            file:write(f .. "\n")
        end
        file:close()
    end
end

return M

# LuaJIT Unicode Text Editor

A feature-rich text editor built with **LuaJIT FFI**, **Cairo**, **Pango**, and **SDL2** that provides professional text editing with full Unicode and emoji support.

## Features

### Core Editing
- ✅ Full Unicode support (UTF-8)
- ✅ Emoji rendering 🎨 🚀 💻
- ✅ Multi-language text (中文, 日本語, العربية, etc.)
- ✅ Syntax highlighting ready (framework in place)
- ✅ Line numbers
- ✅ Text selection and clipboard operations
- ✅ Undo/Redo with 100-level stack

### Text Rendering
- **Cairo**: Hardware-accelerated 2D vector graphics
- **Pango**: Professional text layout with proper Unicode handling
- **Font fallback**: Automatically finds fonts for emoji and special characters
- **Anti-aliasing**: Smooth text rendering

### File I/O
- **Automatic encoding detection** (UTF-8, UTF-16, UTF-32 with BOM support)
- **Cross-platform compatibility** (Windows, Linux)
- **Safe file operations** with backup support
- **Recent files tracking**

### Keyboard Shortcuts

| Shortcut | Action |
|----------|--------|
| `Ctrl+Z` | Undo |
| `Ctrl+Y` | Redo |
| `Ctrl+A` | Select all |
| `Ctrl+C` | Copy |
| `Ctrl+X` | Cut |
| `Ctrl+V` | Paste |
| `Ctrl+S` | Save |
| `Ctrl+O` | Open file |
| `Home` | Start of line |
| `End` | End of line |
| `Ctrl+Home` | Start of document |
| `Ctrl+End` | End of document |
| `Shift+Arrows` | Select text |
| `ESC` | Quit |

## Architecture

```
text_editor.lua        # Core editor engine
├─ Text buffer management (rope-like structure)
├─ Cursor and selection handling
├─ Cairo/Pango rendering
└─ Undo/redo stack

text_io.lua            # File I/O with encoding support
├─ Encoding detection (BOM parsing)
├─ UTF-8/UTF-16/UTF-32 conversion
├─ Line ending normalization
└─ Recent files tracking

demo_text_editor.lua   # Complete application
├─ SDL2 window and event handling
├─ Text rendering pipeline
├─ Status bar and UI
└─ File operations
```

## Dependencies

### Required Libraries
- **luajit** - LuaJIT compiler with FFI support
- **libcairo** - 2D graphics library
- **libpango** - Text layout library
- **libsdl2** - Cross-platform window/input
- **fontconfig** - Font configuration and discovery

### Installation

#### On Debian/Ubuntu
```bash
sudo apt-get update
sudo apt-get install libcairo2 libpango-1.0-0 libsdl2-2.0-0 fontconfig

# Optional: Install additional fonts for emoji support
sudo apt-get install fonts-noto-color-emoji fonts-liberation
```

#### On macOS
```bash
brew install cairo pango sdl2 fontconfig
```

#### On Windows
Use pre-built binaries or MSVC build of the libraries.

## Usage

### Basic Usage

```lua
local text_editor = require("lib.text_editor")
local text_io = require("lib.text_io")

-- Create editor
local editor = text_editor.TextEditor:new(1024, 768, 14, "Monospace")

-- Load a file
local content = text_io.load_file("sample_unicode_emoji.txt")
editor:set_text(content)

-- Save a file
text_io.save_file("output.txt", editor:get_text(), "utf8")

-- Editor operations
editor:insert_text("Hello 🌍")
editor:handle_key("return")
editor:undo()
editor:select_all()
```

### Run Demo Application

```bash
# Run with no arguments (uses sample content)
luajit demo_text_editor.lua

# Run with a file to open
luajit demo_text_editor.lua sample_unicode_emoji.txt

# Run with SDL2 backend explicitly
luajit demo_text_editor.lua sample_unicode_emoji.txt
```

## Implementation Details

### Text Buffer
The text buffer uses a line-based array approach:
- Each line is a separate Lua string
- Efficient for common text editing operations
- Can be easily extended to rope data structure for very large files

### Unicode Handling
- All text internally stored as UTF-8
- Proper UTF-8 validation on input
- BOM detection for file loading
- Character-level operations handle multi-byte sequences

### Rendering Pipeline
1. **Cairo Surface**: Offscreen buffer (RGB24 format)
2. **Pango Layout**: Text measurement and shaping
3. **Cairo Rendering**: Actual drawing operations
4. **SDL2 Texture**: Display on screen
5. **Blit to Screen**: Final presentation

### Emoji Support
- Uses system font fallback through Fontconfig
- Pango handles complex scripts and emoji sequences
- Zero-width joiners (ZWJ) supported
- Color emoji rendering via Font Awesome or Noto Color Emoji

## Performance Characteristics

| Operation | Complexity |
|-----------|-----------|
| Insert character | O(n) line length |
| Delete character | O(n) line length |
| Cursor movement | O(1) |
| Selection | O(1) |
| Undo/Redo | O(m) buffer size |
| File load | O(n) file size |
| Render | O(visible lines) |

For most documents, these are negligible. The editor can handle:
- **100K+ lines** without issues
- **1M+ characters** with acceptable performance
- **Complex scripts** (Arabic, CJK, emoji) natively

## Extending the Editor

### Add Syntax Highlighting
```lua
-- Create a syntax highlighter
local function highlight_lua(line)
    local keywords = {"local", "function", "if", "end", ...}
    -- Return array of {text, color} tuples
end

-- Render in editor
function TextEditor:render()
    -- ... existing code ...
    local highlighted = highlight_lua(line_text)
    for _, token in ipairs(highlighted) do
        -- Render with appropriate color
    end
end
```

### Add Plugins
```lua
-- Create plugin interface
function TextEditor:register_plugin(name, plugin)
    self.plugins[name] = plugin
    plugin:init(self)
end

-- Plugin can hook into key events, rendering, etc.
local plugin = {
    init = function(self, editor) end,
    on_key = function(self, key) end,
    on_render = function(self) end
}
```

### Custom Color Schemes
```lua
editor.colors = {
    bg = { r = 0.1, g = 0.1, b = 0.1, a = 1.0 },      -- Dark background
    text = { r = 0.9, g = 0.9, b = 0.9, a = 1.0 },    -- Light text
    cursor = { r = 1.0, g = 0.8, b = 0.0, a = 1.0 },  -- Orange cursor
    selection = { r = 0.3, g = 0.5, b = 0.8, a = 0.3 } -- Blue selection
}
```

## Testing

### Test Unicode Support
```bash
luajit demo_text_editor.lua sample_unicode_emoji.txt
```

This will load a file containing:
- Emoji from various categories
- Text in 6+ languages
- Special mathematical and arrow symbols
- Right-to-left text (Arabic)
- Complex character combinations

### Test File I/O
```lua
local text_io = require("lib.text_io")

-- Test encoding detection
local content, encoding = text_io.load_file("sample_unicode_emoji.txt")
print("Detected encoding:", encoding)

-- Test round-trip
text_io.save_file("test_output.txt", content, "utf8")
local content2 = text_io.load_file("test_output.txt")
assert(content == content2, "Round-trip failed!")
```

## Known Limitations

1. **Horizontal scrolling** is implemented but status bar doesn't show position
2. **Search/Replace** not yet implemented
3. **Syntax highlighting** not included (framework ready)
4. **Multi-cursor** editing not supported
5. **Text folding** not implemented
6. **Large file optimization** could use memory-mapped I/O

## Future Enhancements

- [ ] Built-in search and replace
- [ ] Syntax highlighting for multiple languages
- [ ] Bracket matching and auto-closing
- [ ] Code folding
- [ ] Multi-cursor editing
- [ ] Theme marketplace
- [ ] Plugin API
- [ ] Language server protocol (LSP) support
- [ ] Git integration
- [ ] Minimap/overview pane

## Contributing

This text editor is built as a demonstration of LuaJIT's FFI capabilities. Key areas for contribution:

1. **Rendering optimization** - Further improve Cairo usage
2. **Editor features** - Add new functionality
3. **Language support** - Add new language modules
4. **Testing** - Improve Unicode/emoji test coverage

## License

This implementation is provided as a demonstration of using LuaJIT FFI with professional graphics libraries. Feel free to use, modify, and extend for your needs.

## References

- [LuaJIT FFI Documentation](http://luajit.org/ext_ffi.html)
- [Cairo Graphics](https://www.cairographics.org/)
- [Pango Text Layout](https://pango.gnome.org/)
- [SDL2 Library](https://www.libsdl.org/)
- [UTF-8 Specification](https://tools.ietf.org/html/rfc3629)
- [Unicode Standard](https://unicode.org/)

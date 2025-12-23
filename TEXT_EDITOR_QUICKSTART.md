# Text Editor - Quick Start Guide

## Installation & Setup

### 1. Install Dependencies

**Ubuntu/Debian:**
```bash
sudo apt-get update
sudo apt-get install libcairo2 libpango-1.0-0 libsdl2-2.0-0 fontconfig
sudo apt-get install fonts-noto-color-emoji
```

**macOS:**
```bash
brew install cairo pango sdl2 fontconfig
```

### 2. Run the Demo

```bash
# Basic demo (starts with sample content)
luajit demo_text_editor.lua

# Open a specific file
luajit demo_text_editor.lua sample_unicode_emoji.txt

# Open any text file
luajit demo_text_editor.lua /path/to/your/file.txt
```

## Basic Operations

### Editing
- **Type text**: Just start typing - supports full Unicode, emoji, and multi-byte characters
- **Delete**: Backspace removes character before cursor, Delete removes after
- **New line**: Press Return/Enter to create new line
- **Selection**: Hold Shift and use arrow keys

### Navigation
- **Arrow Keys**: Move cursor left/right/up/down
- **Home**: Go to start of line
- **End**: Go to end of line
- **Page Up/Down**: Scroll by one screen (in extended version)

### Clipboard
- **Ctrl+C**: Copy selected text
- **Ctrl+X**: Cut selected text (copy + delete)
- **Ctrl+V**: Paste text from clipboard
- **Ctrl+A**: Select all text

### Undo/Redo
- **Ctrl+Z**: Undo last change
- **Ctrl+Y**: Redo last undone change

### File Operations
- **Ctrl+S**: Save to default location or last opened file
- **Ctrl+O**: Open file (extended version)

### Exit
- **ESC**: Quit application

## Examples

### Example 1: Create a New File

```bash
luajit demo_text_editor.lua
```

1. Editor opens with sample content
2. Select all (Ctrl+A)
3. Delete (Backspace)
4. Type your content
5. Save (Ctrl+S)
6. Exit (ESC)

### Example 2: Edit Existing File

```bash
luajit demo_text_editor.lua sample_unicode_emoji.txt
```

1. File loads with emoji and Unicode examples
2. Navigate to location with arrow keys
3. Make edits
4. Undo if needed (Ctrl+Z)
5. Save (Ctrl+S)

### Example 3: Work with Unicode

The editor fully supports:
- **Latin with accents**: café, naïve, Zürich
- **Greek**: αβγδε (Greek letters)
- **Cyrillic**: кириллица (Russian)
- **Chinese**: 我是文本编辑器
- **Arabic**: هذا نص عربي
- **Emoji**: 🚀 💻 🎨 👍

Just type naturally - encoding is automatic!

## Keyboard Reference

```
NAVIGATION
══════════════════════════════════════════════════════════
Left/Right arrows      Move cursor horizontally
Up/Down arrows         Move cursor between lines
Home                   Go to start of current line
End                    Go to end of current line

EDITING
══════════════════════════════════════════════════════════
Backspace              Delete character before cursor
Delete                 Delete character at cursor
Return/Enter           Create new line
Shift + Arrow keys     Select text while moving

CLIPBOARD
══════════════════════════════════════════════════════════
Ctrl+C                 Copy selection
Ctrl+X                 Cut selection
Ctrl+V                 Paste from clipboard
Ctrl+A                 Select all text

UNDO/REDO
══════════════════════════════════════════════════════════
Ctrl+Z                 Undo (up to 100 levels)
Ctrl+Y                 Redo

FILE OPERATIONS
══════════════════════════════════════════════════════════
Ctrl+S                 Save file
Ctrl+O                 Open file (extended version)

APPLICATION
══════════════════════════════════════════════════════════
ESC                    Quit application
```

## Features Overview

### ✅ Implemented
- Full Unicode/UTF-8 support
- Emoji rendering 🎨 🚀 💻
- Multi-line editing
- Text selection
- Copy/Cut/Paste operations
- Undo/Redo (100 levels)
- File I/O with encoding detection
- Line numbers
- Automatic cursor scrolling
- Status bar with statistics

### 🔄 Available in Extended Version
- Search and replace
- Syntax highlighting (Lua, Python, etc.)
- Bookmarks and breakpoints
- Line duplication
- Block indent/unindent
- Recent files menu
- Custom themes
- Plugin system

### 📚 Advanced Features
- Rope-based buffer (for large files)
- Streaming file support
- LSP integration
- Git integration
- Multiple cursors
- Code folding

## Troubleshooting

### "Cannot open file" error
- Check file path is correct
- Ensure file is readable: `ls -la filename`
- For large files (>100MB), may need rope-based buffer

### Emoji not showing
- Ensure emoji fonts are installed: `fc-list | grep emoji`
- On Ubuntu: `sudo apt-get install fonts-noto-color-emoji`
- Fontconfig must find the fonts

### Text appears garbled
- This is usually encoding detection issue
- Try saving as UTF-8: The editor auto-detects encoding on load
- File should use UTF-8 without BOM for best compatibility

### Performance issues
- Close other applications
- Very large files (>1MB) may need rope-based optimization
- Hardware acceleration should be enabled

### SDL2 window not appearing
- Check SDL2 installation: `ldconfig -p | grep SDL`
- Verify graphics drivers are installed
- Try explicit environment variable: `export SDL_VIDEODRIVER=x11`

## Using the Text Editor API

### As a Library

```lua
local text_editor = require("lib.text_editor")
local text_io = require("lib.text_io")

-- Create instance
local editor = text_editor.TextEditor:new(800, 600)

-- Load file with auto-encoding detection
local content = text_io.load_file("myfile.txt")
editor:set_text(content)

-- Edit programmatically
editor:insert_text("Hello 🌍")
editor:move_cursor(1, 1)
editor:select_all()

-- Get edited content
local output = editor:get_text()

-- Save with encoding
text_io.save_file("output.txt", output, "utf8")

-- Cleanup
editor:cleanup()
```

### Advanced Usage

```lua
local advanced = require("examples.advanced_editor_framework")

-- Create advanced editor with features
local ed = advanced.AdvancedEditor:new(1024, 768)

-- Search functionality
ed.state:search("TODO")
ed.state:search_next()
ed.state:replace_all("TODO", "DONE")

-- Line operations
ed:duplicate_line()
ed:move_line_down()
ed:toggle_line_comment("--")

-- Statistics
ed:update_statistics()
local stats = ed:get_status()
print(stats.stats_summary)  -- "120 chars | 15 words | 5 lines | ~1 min read"

-- Bookmarks
ed:toggle_bookmark()
ed:get_next_bookmark()
```

## Performance Tips

1. **For very large files** (>10MB):
   - Implementation uses line-based buffer
   - For production: Consider rope-based buffer or memory-mapped I/O
   - Currently suitable for files up to ~1MB with good performance

2. **For slow systems**:
   - Reduce font size to render fewer characters
   - Increase scroll region to reduce redraw frequency
   - Use SDL_RENDERER_SOFTWARE instead of ACCELERATED if GPU has issues

3. **For best emoji rendering**:
   - Ensure Color Emoji font is installed (Noto Color Emoji)
   - Update fontconfig: `fc-cache -f -v`
   - Use monospace font with good Unicode coverage

## File Format Support

| Format | Read | Write | Encoding |
|--------|------|-------|----------|
| UTF-8 | ✅ | ✅ | Auto-detect |
| UTF-16 LE | ✅ | ✅ | Via conversion |
| UTF-16 BE | ✅ | ❌ | Via conversion |
| UTF-32 | ❌ | ❌ | Not yet |
| ASCII | ✅ | ✅ | Subset of UTF-8 |
| Latin-1 | ❌ | ❌ | Not supported |

## Next Steps

1. **Try the demo**: `luajit demo_text_editor.lua sample_unicode_emoji.txt`
2. **Read TEXT_EDITOR_README.md** for detailed documentation
3. **Check examples/** directory for advanced usage
4. **Explore lib/text_editor.lua** for API documentation
5. **Extend with plugins** - The architecture is designed for extensibility

## Getting Help

For issues or questions:
1. Check the TEXT_EDITOR_README.md
2. Review examples in examples/ directory
3. Look at the source code - it's well-commented
4. Test with sample_unicode_emoji.txt for known working case

---

**Enjoy the text editor!** 🎉

For more information, see TEXT_EDITOR_README.md in the project root.

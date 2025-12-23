# Bundled Fonts for Emoji Support

This directory contains fonts bundled with the application for emoji rendering.

## Contents

- **NotoColorEmoji.ttf** - Google's Noto Color Emoji font (11MB)
  - License: SIL Open Font License 1.1
  - Provides comprehensive emoji coverage
  - Source: https://github.com/googlefonts/noto-emoji

## Font Fallback Chain

The application uses this font fallback chain:
```
"Segoe UI, Noto Color Emoji"
```

1. **Segoe UI** - Windows system font for regular text
2. **Noto Color Emoji** - Bundled font for emoji characters

## Deployment

### Option 1: Bundled Font (Current Setup)

The `NotoColorEmoji.ttf` is included in the `fonts/` directory.

To ensure it's recognized:
```bash
# Register the fonts directory with fontconfig
fc-cache -fv fonts/
```

Or set environment variable before running:
```bash
export FONTCONFIG_PATH="$(pwd)/fonts"
./luajit.exe your_app.lua
```

### Option 2: System Font (Windows Only)

On Windows 10+, you can rely on the system emoji font:
- Use: `"Segoe UI, Segoe UI Emoji"`
- No bundling needed, but limited to Windows

### Option 3: Install Noto Color Emoji System-Wide

```bash
# MSYS2
pacman -S mingw-w64-x86_64-google-noto-emoji-fonts

# Linux (Debian/Ubuntu)
sudo apt install fonts-noto-color-emoji

# macOS
brew tap homebrew/cask-fonts
brew install font-noto-color-emoji
```

## License

Noto Color Emoji font is licensed under the SIL Open Font License 1.1.
You are free to bundle it with your application.

Full license: https://scripts.sil.org/OFL

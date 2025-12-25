# Debian Test Checklist

Quick reference for testing the cross-platform emoji support on Debian after dual-boot.

## Pre-Test: Get the Files to Debian

### Option 1: Git Clone (Recommended)

```bash
git clone https://github.com/arkenidar/luajit_win32.git
cd luajit_win32
```

### Option 2: Use Shared Partition

If you have a shared NTFS partition accessible from both Windows and Debian:

```bash
# Mount the Windows partition (if not auto-mounted)
sudo mount /dev/sdaX /mnt/windows  # Replace sdaX with your partition

# Copy the distribution package
cp /mnt/windows/path/to/luajit_win32/dist/*.tar.gz ~/
cd ~/
tar xzf luajit_gui_emoji_v1.0_crossplatform.tar.gz
cd luajit_win32
```

### Option 3: Use the Distribution Archive

The self-contained package is ready:
- Location on Windows: `C:\Ruby34-x64\msys64\home\dario\luajit_win32\dist\luajit_gui_emoji_v1.0_crossplatform.tar.gz`
- Copy to USB or shared location

## Step 1: Install Dependencies

```bash
# Update package lists
sudo apt update

# Install LuaJIT
sudo apt install luajit

# Install graphics libraries
sudo apt install libsdl2-2.0-0 libcairo2 libpango-1.0-0 libpangocairo-1.0-0 libfontconfig1

# Verify installations
luajit -v
dpkg -l | grep -E 'libsdl2|libcairo|libpango|libfontconfig'
```

## Step 2: Run Platform Check

```bash
cd ~/luajit_win32  # or wherever you extracted/cloned

# Make executable (if needed)
chmod +x check_platform.lua

# Run compatibility check
luajit check_platform.lua
```

**Expected Output:**
```
✓ All dependencies satisfied!
✓ Platform: Unix-like (Linux/macOS)
✓ Emoji support ready
```

**If any checks fail**, follow the installation instructions shown.

## Step 3: Test Font Loading

```bash
luajit test_bundled_fonts.lua
```

**Expected Behavior:**
- Window opens with emoji visible
- Console shows: "✓ All tests passed!"
- Close window to continue

**What to Check:**
- [ ] Window opens without crashes
- [ ] Emoji render as colorful icons (not empty squares)
- [ ] Text is properly centered and aligned
- [ ] No error messages in console

## Step 4: Run Emoji Demo

```bash
luajit demo_emoji_test.lua
```

**What to Check:**
- [ ] Title: "🎨 Emoji Rendering Test with Pango" displays correctly
- [ ] Buttons show: 🚀 ⚙️ 💾 🎯 🌟 🔥
- [ ] Labels show: 😀 😎 🤔 🎉 🍕 🍔 📱 💻
- [ ] Listbox shows: 📄 🎨 🌈 ✨ 🚀 🎯 💡
- [ ] Buttons are clickable and responsive
- [ ] Window closes properly

## Step 5: Run Full Showcase

```bash
luajit demo_cairo_showcase.lua
```

**What to Check:**
- [ ] Complex UI with multiple controls renders
- [ ] Vector graphics are smooth (no pixelation)
- [ ] Emoji in all control types work
- [ ] No rendering glitches or crashes

## Common Issues and Fixes

### Issue: "cannot load module 'libSDL2-2.0.so.0'"

**Fix:**
```bash
sudo apt install libsdl2-2.0-0
sudo ldconfig
```

### Issue: "cannot load module 'libpango-1.0.so.0'"

**Fix:**
```bash
sudo apt install libpango-1.0-0 libpangocairo-1.0-0
sudo ldconfig
```

### Issue: Emoji show as empty squares

**Fix:**
```bash
# Check font exists and is correct size
ls -lh fonts/NotoColorEmoji.ttf
# Should show ~11MB

# Manually register fonts
fc-cache -fv fonts/

# Verify font is available
fc-list | grep -i noto
```

### Issue: Window doesn't open / SDL error

**Fix:**
```bash
# Check if X11 is running (for GUI)
echo $DISPLAY
# Should show :0 or similar

# If using Wayland, may need XWayland
sudo apt install xwayland
```

### Issue: Permission denied

**Fix:**
```bash
# Make all Lua files executable
chmod +x *.lua

# Or run with luajit explicitly
luajit demo_emoji_test.lua
```

## Comparison Test: Windows vs Debian

Take screenshots or notes comparing:

| Feature | Windows | Debian | Status |
|---------|---------|--------|--------|
| Emoji rendering | ✓ | ? | |
| Font fallback | Segoe UI + Noto | DejaVu + Noto | |
| Startup time | ~100ms | ? | |
| Rendering speed | 60fps | ? | |
| Memory usage | ~50MB | ? | |
| All controls work | ✓ | ? | |

## Success Criteria

✅ All demos run without errors
✅ Emoji render as colorful icons (not squares)
✅ UI is responsive and interactive
✅ No crashes or segmentation faults
✅ Font loads automatically without manual fc-cache

## Performance Comparison

Run this quick benchmark on both platforms:

```bash
# Measure startup time
time luajit demo_emoji_test.lua

# Check memory usage (run in another terminal while demo is open)
ps aux | grep luajit
```

## Reporting Results

After testing, document:

1. **Platform Info:**
   ```bash
   uname -a
   cat /etc/os-release
   luajit -v
   ```

2. **Library Versions:**
   ```bash
   dpkg -l | grep -E 'libsdl2|libcairo|libpango' | awk '{print $2, $3}'
   ```

3. **Test Results:**
   - Screenshot of demo_emoji_test.lua
   - Any error messages
   - Performance notes

## Next Steps After Successful Test

If everything works:
1. ✅ Confirm true cross-platform compatibility
2. Consider additional platforms (macOS, other Linux distros)
3. Package for distribution (AppImage, DEB package, etc.)
4. Document any Debian-specific tweaks needed

If issues found:
1. Document the specific error
2. Check library versions match requirements
3. Test with system emoji fonts as fallback
4. May need platform-specific font configuration

---

## Quick Command Reference

```bash
# Full test sequence
cd ~/luajit_win32
luajit check_platform.lua && \
luajit test_bundled_fonts.lua && \
luajit demo_emoji_test.lua

# Check all dependencies at once
dpkg -l | grep -E 'luajit|libsdl2|libcairo|libpango|libfontconfig' | grep '^ii'

# Clean rebuild font cache
rm -rf ~/.cache/fontconfig
fc-cache -fv fonts/

# Monitor resource usage
watch -n 1 'ps aux | grep luajit | grep -v grep'
```

Good luck with the Debian test! 🚀

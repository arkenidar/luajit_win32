#!/bin/bash
# Project cleanup script - organize files for production

echo "=== Project Cleanup ==="

# Create organization directories
mkdir -p examples
mkdir -p tests/old_tests
mkdir -p dist

echo "[1/4] Moving demo files..."
# Keep main demos in root, move experimental ones
mv -v demo_cairo_advanced.lua examples/ 2>/dev/null || true
mv -v demo_cairo_no_loop.lua examples/ 2>/dev/null || true
mv -v demo_cairo_buttons_only.lua examples/ 2>/dev/null || true

echo "[2/4] Moving old test files..."
# Move development test files
mv -v test_2buttons.lua tests/old_tests/ 2>/dev/null || true
mv -v test_3buttons_debug.lua tests/old_tests/ 2>/dev/null || true
mv -v test_3controls_exact.lua tests/old_tests/ 2>/dev/null || true
mv -v test_create_buttons.lua tests/old_tests/ 2>/dev/null || true
mv -v test_create_labels.lua tests/old_tests/ 2>/dev/null || true
mv -v test_event_loop.lua tests/old_tests/ 2>/dev/null || true
mv -v test_event_loop_multi.lua tests/old_tests/ 2>/dev/null || true
mv -v test_many_controls.lua tests/old_tests/ 2>/dev/null || true
mv -v test_modules.lua tests/old_tests/ 2>/dev/null || true
mv -v test_platform_sdl2.lua tests/old_tests/ 2>/dev/null || true
mv -v test_render_only.lua tests/old_tests/ 2>/dev/null || true
mv -v test_sdl2.lua tests/old_tests/ 2>/dev/null || true
mv -v test_sdl2_backend.lua tests/old_tests/ 2>/dev/null || true
mv -v test_simple_render.lua tests/old_tests/ 2>/dev/null || true
mv -v test_with_user_ffi.lua tests/old_tests/ 2>/dev/null || true
mv -v test_zerocopy_minimal.lua tests/old_tests/ 2>/dev/null || true
mv -v test_cairo.lua tests/old_tests/ 2>/dev/null || true

echo "[3/4] Removing temporary files..."
rm -vf nul 2>/dev/null || true

echo "[4/4] Creating distribution package..."
tar czf dist/luajit_gui_emoji_v1.0_crossplatform.tar.gz \
    --exclude='dist' \
    --exclude='tests/old_tests' \
    --exclude='examples' \
    --exclude='.git' \
    --exclude='*.tar.gz' \
    lib/ \
    fonts/ \
    demo_cairo_showcase.lua \
    demo_cairo_simple.lua \
    demo_emoji_test.lua \
    test_bundled_fonts.lua \
    check_platform.lua \
    main.lua \
    *.md \
    2>/dev/null

echo ""
echo "=== Cleanup Complete ==="
echo ""
echo "Project structure:"
echo "  Root directory:"
echo "    - demo_*.lua         (Main demos)"
echo "    - test_bundled_fonts.lua  (Font test)"
echo "    - check_platform.lua (Compatibility check)"
echo "    - main.lua          (Original demo)"
echo ""
echo "  lib/                  (Core libraries)"
echo "  fonts/                (Bundled emoji font)"
echo "  examples/             (Experimental demos)"
echo "  tests/old_tests/      (Development tests)"
echo "  dist/                 (Distribution packages)"
echo ""
echo "Distribution package created:"
ls -lh dist/*.tar.gz 2>/dev/null
echo ""
echo "Ready for:"
echo "  1. Git commit"
echo "  2. Transfer to Debian (use dist/*.tar.gz)"
echo "  3. Production deployment"

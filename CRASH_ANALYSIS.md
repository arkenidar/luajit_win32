# SDL2 Event Loop Crash Analysis

## Summary

There is a consistent segmentation fault when running the SDL2 event loop with 3 or more buttons.

## Findings

### What Works
- ✅ Creating up to 20 buttons (no event loop)
- ✅ Creating up to 20 labels (no event loop)
- ✅ Single render of many controls (no event loop)
- ✅ Event loop with 1 button
- ✅ Event loop with 2 buttons

### What Crashes
- ❌ Event loop with 3+ buttons
- ❌ Event loop with 3+ buttons even after initial manual render

## Crash Location

The crash occurs:
1. AFTER `on_create` callback fires
2. During the first render call INSIDE the event loop
3. NOT during manual render calls before the event loop

## Root Cause Hypothesis

The issue appears to be related to rendering DURING the SDL event polling loop.
The combination of `SDL_PollEvent` + rendering with 3+ controls triggers a segfault.

This could be:
1. SDL surface invalidation during event processing
2. Stack corruption from recursive Cairo calls
3. Thread safety issue with SDL/Cairo interaction
4. Memory corruption in control iteration with >2 items

## Workaround Attempted

Adding initial render before event loop to set dirty=false prevents re-renders,
but demo_cairo_simple still crashes even with this workaround.

## Next Steps

Need to identify why 2 buttons is the magic threshold and what happens differently with the 3rd button.

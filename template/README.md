# zfx Template - Live ImGui Theme Editor

# [LIVE DEMO](https://lizard-demon.itch.io/zfx-template)

A starting point for your own zfx applications. This demo implements a live ImGui theme editor in just ~110 lines of code, showcasing:

- **UI Reflection**: Auto-generated widgets for all theme properties
- **Layout System**: 50/50 split panels using zfx's constraint layout
- **Live Preview**: Theme changes apply instantly to the UI itself
- **Cross-Platform**: Same code runs native and web

## Run

**Native:**
```bash
zig build run
```

**Web:**
```bash
zig build -Dtarget=wasm32-emscripten run
```

The web build automatically opens in your browser.

## Use as Template

This demo is designed to be forked and modified:

1. Copy the `demo/` directory to start your project
2. Modify `src/main.zig` with your own UI
3. The build system is already set up for native and web
4. See `src/theme.zig` for an example of a layout struct

Start here and build your own cross-platform GUI!

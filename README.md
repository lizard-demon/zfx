# zfx

Minimal UI toolkit for Zig. Auto-generate ImGui widgets from any type. Constraint-based layout. Inspired by Clay.h and ImReflect.

## Build

```bash
zig build run
```

That's it! The build system handles sokol + imgui setup automatically.

## Install

```bash
zig fetch --save <url>
```

Add to your `build.zig`:

```zig
const zfx = @import("zfx");

// Setup graphics (sokol + imgui)
const gfx = zfx.build.native.gfx(b, target, optimize);

// Create your module with zfx
const zfx_mod = zfx_dep.module("zfx");
exe.root_module.addImport("zfx", zfx_mod);

// Link and run
zfx.build.native.link(b, exe);
const run_cmd = zfx.build.native.run(b, exe);
```

For web builds, use `zfx.build.web.*` instead.

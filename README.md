# zfx

Minimal UI toolkit for Zig. Auto-generate ImGui widgets from any type. Constraint-based layout. Inspired by Clay.h and ImReflect.

## Build

```bash
zig build run
```

That's it! The build system handles sokol + imgui setup automatically.

## Install

```bash
zig fetch --save git+https://github.com/lizard-demon/zfx#97bb8812d8ab02a946d14253a7c0e8491db93fc9
```

Add to your `build.zig`:

```zig
const zfx_dep = b.dependency("zfx", .{ .target = target, .optimize = optimize });
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

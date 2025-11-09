# zfx

Minimal UI toolkit for Zig. Auto-generate ImGui widgets from any type. Constraint-based layout. Inspired by Clay.h and ImReflect.

## Build

```bash
zig build run
```

That's it! The build system handles sokol + imgui setup automatically.

## Install

```bash
zig fetch --save git+https://github.com/lizard-demon/zfx#e734252dd16f4207d1cc9d95cf51abf7e1954849
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

## Tips

**Expand structs by default**: Instead of `zfx.ui.reflect.input("config", &config)` which creates a collapsible tree node, you can iterate the fields directly to show them expanded:

```zig
inline for (comptime std.meta.fields(@TypeOf(config))) |field| {
    const label = field.name ++ "\x00";
    _ = zfx.ui.reflect.input(@ptrCast(label.ptr), &@field(config, field.name));
}
```

This gives you fine-grained control over how structs are displayed.

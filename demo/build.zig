const std = @import("std");

pub fn build(b: *std.Build) void {
    const target = b.standardTargetOptions(.{});
    const optimize = b.standardOptimizeOption(.{});

    // Get zfx dependency and build helpers
    const zfx_dep = b.dependency("zfx", .{ .target = target, .optimize = optimize });
    const zfx = @import("zfx").zfx;

    // Setup zfx module with graphics (sokol + imgui)
    const zfx_mod = zfx.build.native.gfx(b, target, optimize, zfx_dep);

    // Build executable
    const exe = b.addExecutable(.{
        .name = "demo",
        .root_module = b.createModule(.{
            .root_source_file = b.path("src/main.zig"),
            .target = target,
            .optimize = optimize,
            .imports = &.{.{ .name = "zfx", .module = zfx_mod }},
        }),
    });

    // Link and run
    zfx.build.native.link(b, exe);
    const run_cmd = zfx.build.native.run(b, exe);
    if (b.args) |args| run_cmd.addArgs(args);

    b.step("run", "Run the demo").dependOn(&run_cmd.step);
}

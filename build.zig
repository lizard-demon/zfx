const std = @import("std");

// Export zfx build helpers for other projects to use
pub const zfx = @import("src/zfx/build.zig");

pub fn build(b: *std.Build) void {
    const target = b.standardTargetOptions(.{});
    const optimize = b.standardOptimizeOption(.{});

    // Setup zfx module with graphics dependencies (null = building zfx itself)
    const zfx_mod = zfx.build.native.gfx(b, target, optimize, null);

    // Build the executable
    const exe = b.addExecutable(.{
        .name = "zfx",
        .root_module = b.createModule(.{
            .root_source_file = b.path("src/main.zig"),
            .target = target,
            .optimize = optimize,
            .imports = &.{.{ .name = "zfx", .module = zfx_mod }},
        }),
    });

    // Install and setup run command
    zfx.build.native.link(b, exe);
    const run_cmd = zfx.build.native.run(b, exe);
    if (b.args) |args| run_cmd.addArgs(args);

    b.step("run", "Run the app").dependOn(&run_cmd.step);
}

const std = @import("std");

pub fn build(b: *std.Build) void {
    const target = b.standardTargetOptions(.{});
    const optimize = b.standardOptimizeOption(.{});

    // Get zfx dependency and build helpers
    const zfx_dep = b.dependency("zfx", .{ .target = target, .optimize = optimize });
    const zfx = @import("zfx").zfx;

    // Setup zfx module with graphics (sokol + imgui)
    const gfx = zfx.build.web.gfx(b, target, optimize, zfx_dep);

    // Build library (web builds use library, not executable)
    const lib = b.addLibrary(.{
        .name = "demo",
        .root_module = b.createModule(.{
            .root_source_file = b.path("src/main.zig"),
            .target = target,
            .optimize = optimize,
            .imports = &.{.{ .name = "zfx", .module = gfx.module }},
        }),
    });

    // Link and run
    const link_step = try zfx.build.web.link(b, lib, target, optimize, gfx.dep_sokol, null);
    b.getInstallStep().dependOn(&link_step.step);

    const run_cmd = zfx.build.web.run(b, "demo", gfx.dep_sokol);
    run_cmd.step.dependOn(&link_step.step);

    b.step("run", "Run the demo").dependOn(&run_cmd.step);
}

// Educational zfx demo build: Native + Web
const std = @import("std");

pub fn build(b: *std.Build) void {
    const target = b.standardTargetOptions(.{});
    const optimize = b.standardOptimizeOption(.{});

    // Get zfx dependency and build helpers
    const zfx_dep = b.dependency("zfx", .{ .target = target, .optimize = optimize });
    const zfx = @import("zfx").zfx;

    // Detect platform and build accordingly
    if (target.result.cpu.arch.isWasm()) {
        try buildWeb(b, target, optimize, zfx_dep, zfx);
    } else {
        buildNative(b, target, optimize, zfx_dep, zfx);
    }
}

fn buildNative(
    b: *std.Build,
    target: std.Build.ResolvedTarget,
    optimize: std.builtin.OptimizeMode,
    zfx_dep: *std.Build.Dependency,
    zfx: anytype,
) void {
    // Setup zfx with sokol + imgui
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

    // Install and run
    zfx.build.native.link(b, exe);
    const run_cmd = zfx.build.native.run(b, exe);
    if (b.args) |args| run_cmd.addArgs(args);
    b.step("run", "Run native demo").dependOn(&run_cmd.step);
}

fn buildWeb(
    b: *std.Build,
    target: std.Build.ResolvedTarget,
    optimize: std.builtin.OptimizeMode,
    zfx_dep: *std.Build.Dependency,
    zfx: anytype,
) !void {
    // Web builds use ReleaseFast by default (Debug mode has compiler issues)
    const web_optimize = if (optimize == .Debug) .ReleaseFast else optimize;

    // Setup zfx with sokol + imgui (returns module + dep_sokol for linking)
    const gfx = zfx.build.web.gfx(b, target, web_optimize, zfx_dep);

    // Build library (web uses library, not executable)
    const lib = b.addLibrary(.{
        .name = "demo",
        .root_module = b.createModule(.{
            .root_source_file = b.path("src/main.zig"),
            .target = target,
            .optimize = web_optimize,
            .imports = &.{.{ .name = "zfx", .module = gfx.module }},
        }),
    });

    // Link with emscripten and run
    const link_step = try zfx.build.web.link(b, lib, target, web_optimize, gfx.dep_sokol, null);
    b.getInstallStep().dependOn(&link_step.step);

    const run_cmd = zfx.build.web.run(b, "demo", gfx.dep_sokol);
    run_cmd.step.dependOn(&link_step.step);
    b.step("run", "Run web demo").dependOn(&run_cmd.step);
}

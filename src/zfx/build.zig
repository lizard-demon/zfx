const std = @import("std");

pub const build = struct {
    pub const native = struct {
        pub fn gfx(
            b: *std.Build,
            target: std.Build.ResolvedTarget,
            optimize: std.builtin.OptimizeMode,
            zfx_dep: ?*std.Build.Dependency,
        ) *std.Build.Module {
            const cimgui = @import("cimgui");
            const builder = if (zfx_dep) |dep| dep.builder else b;
            const dep_cimgui = builder.dependency("cimgui", .{ .target = target, .optimize = optimize });
            const dep_sokol = builder.dependency("sokol", .{ .target = target, .optimize = optimize, .with_sokol_imgui = true });
            const conf = cimgui.getConfig(false);
            dep_sokol.artifact("sokol_clib").addIncludePath(dep_cimgui.path(conf.include_dir));

            const zfx_root = if (zfx_dep) |dep| dep.path("src/zfx/mod.zig") else b.path("src/zfx/mod.zig");
            return b.addModule("zfx", .{
                .root_source_file = zfx_root,
                .target = target,
                .imports = &.{
                    .{ .name = "sokol", .module = dep_sokol.module("sokol") },
                    .{ .name = "cimgui", .module = dep_cimgui.module(conf.module_name) },
                },
            });
        }

        pub fn link(
            b: *std.Build,
            exe: *std.Build.Step.Compile,
        ) void {
            b.installArtifact(exe);
        }

        pub fn run(
            b: *std.Build,
            exe: *std.Build.Step.Compile,
        ) *std.Build.Step.Run {
            const run_cmd = b.addRunArtifact(exe);
            run_cmd.step.dependOn(b.getInstallStep());
            return run_cmd;
        }
    };

    pub const web = struct {
        pub fn gfx(
            b: *std.Build,
            target: std.Build.ResolvedTarget,
            optimize: std.builtin.OptimizeMode,
            zfx_dep: ?*std.Build.Dependency,
        ) struct { module: *std.Build.Module, dep_sokol: *std.Build.Dependency } {
            const cimgui = @import("cimgui");
            const builder = if (zfx_dep) |dep| dep.builder else b;
            const dep_cimgui = builder.dependency("cimgui", .{ .target = target, .optimize = optimize });
            const dep_sokol = builder.dependency("sokol", .{ .target = target, .optimize = optimize, .with_sokol_imgui = true });
            const conf = cimgui.getConfig(false);
            const emsdk = dep_sokol.builder.dependency("emsdk", .{});
            const emsdk_incl_path = emsdk.path("upstream/emscripten/cache/sysroot/include");

            // Setup sokol to find cimgui headers
            dep_sokol.artifact("sokol_clib").addIncludePath(dep_cimgui.path(conf.include_dir));

            // Setup cimgui for web
            dep_cimgui.artifact(conf.clib_name).addSystemIncludePath(emsdk_incl_path);
            dep_cimgui.artifact(conf.clib_name).step.dependOn(&dep_sokol.artifact("sokol_clib").step);

            const zfx_root = if (zfx_dep) |dep| dep.path("src/zfx/mod.zig") else b.path("src/zfx/mod.zig");
            const zfx_mod = b.addModule("zfx", .{
                .root_source_file = zfx_root,
                .target = target,
                .imports = &.{
                    .{ .name = "sokol", .module = dep_sokol.module("sokol") },
                    .{ .name = "cimgui", .module = dep_cimgui.module(conf.module_name) },
                },
            });

            return .{
                .module = zfx_mod,
                .dep_sokol = dep_sokol,
            };
        }

        pub fn link(
            b: *std.Build,
            lib: *std.Build.Step.Compile,
            target: std.Build.ResolvedTarget,
            optimize: std.builtin.OptimizeMode,
            dep_sokol: *std.Build.Dependency,
            shell_file_path: ?std.Build.LazyPath,
        ) !*std.Build.Step.InstallDir {
            const sokol_mod = @import("sokol");
            const emsdk = dep_sokol.builder.dependency("emsdk", .{});
            return try sokol_mod.emLinkStep(b, .{
                .lib_main = lib,
                .target = target,
                .optimize = optimize,
                .emsdk = emsdk,
                .use_webgl2 = true,
                .use_emmalloc = false,
                .use_filesystem = true,
                .shell_file_path = shell_file_path orelse dep_sokol.path("src/sokol/web/shell.html"),
                .extra_args = &.{
                    "-sEXPORTED_RUNTIME_METHODS=['FS']",
                    "-sEXPORTED_FUNCTIONS=['_main']",
                    "-sFORCE_FILESYSTEM=1",
                },
            });
        }

        pub fn run(
            b: *std.Build,
            name: []const u8,
            dep_sokol: *std.Build.Dependency,
        ) *std.Build.Step.Run {
            const sokol_mod = @import("sokol");
            const emsdk = dep_sokol.builder.dependency("emsdk", .{});
            return sokol_mod.emRunStep(b, .{ .name = name, .emsdk = emsdk });
        }
    };

    pub fn shader(
        b: *std.Build,
        target: std.Build.ResolvedTarget,
        optimize: std.builtin.OptimizeMode,
        shader_path: []const u8,
    ) std.Build.LazyPath {
        const dep_shdc = b.dependency("shdc", .{ .target = target, .optimize = optimize });
        const shdc_exe = dep_shdc.artifact("sokol-shdc");
        const run = b.addRunArtifact(shdc_exe);
        run.addFileArg(b.path(shader_path));
        run.addArgs(&.{ "--input", shader_path, "--slang", "glsl430:metal_macos:hlsl5:glsl300es:wgsl", "--format", "sokol_zig" });
        return run.addOutputFileArg("shader.zig");
    }
};

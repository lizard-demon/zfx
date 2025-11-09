const std = @import("std");

// Export zfx build helpers for other projects to use
pub const zfx = @import("src/zfx/build.zig");

pub fn build(b: *std.Build) void {
    // Accept standard options but don't use them
    // This allows dependencies to pass target/optimize without errors
    _ = b.standardTargetOptions(.{});
    _ = b.standardOptimizeOption(.{});

    // zfx is a library - no executable to build
    // The module is exported via build.zig.zon
    // See demo/ for usage example
}

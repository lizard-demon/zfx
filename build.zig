const std = @import("std");

// Export zfx build helpers for other projects to use
pub const zfx = @import("src/zfx/build.zig");

pub fn build(b: *std.Build) void {
    // zfx is a library - no executable to build
    // The module is exported via build.zig.zon
    // See demo/ for usage example
    _ = b;
}

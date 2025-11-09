const std = @import("std");
pub const zfx = @import("src/zfx/build.zig");

pub fn build(b: *std.Build) void {
    _ = b.standardTargetOptions(.{});
    _ = b.standardOptimizeOption(.{});
}

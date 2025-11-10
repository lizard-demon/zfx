const std = @import("std");

pub const Status = enum { idle, running, paused, stopped };

pub const Mode = union(enum) {
    auto,
    manual: i32,
    timed: f32,
};

var shared_int: i32 = 999;
var shared_config: Config = .{ .enabled = false, .timeout = 10.0, .retries = 5 };

pub const Demo = struct {
    // primitives
    int_value: i32 = 42,
    float_value: f32 = 3.14,
    bool_value: bool = true,

    // enum
    status: Status = .idle,

    // string
    name: [32]u8 = "hello".* ++ [_]u8{0} ** 27,

    // array
    numbers: [4]i32 = .{ 1, 2, 3, 4 },

    // vector
    position: @Vector(2, f32) = .{ 10.0, 20.0 },
    color: @Vector(4, f32) = .{ 1.0, 0.5, 0.25, 1.0 },

    // optional
    optional_int: ?i32 = null,
    optional_float: ?f32 = 2.5,

    // union
    mode: Mode = .auto,

    // nested struct
    config: Config = .{},

    // error union
    result: anyerror!i32 = 100,

    // pointers
    int_ptr: *i32 = &shared_int,
    config_ptr: *Config = &shared_config,

    // function pointers
    on_click: *const fn () void = &doNothing,
    on_reset: *const fn () void = &resetDemo,
};

pub const Config = struct {
    enabled: bool = true,
    timeout: f32 = 5.0,
    retries: i32 = 3,
};

var click_count: i32 = 0;

fn doNothing() void {
    click_count += 1;
    std.debug.print("Button clicked! Count: {d}\n", .{click_count});
}

fn resetDemo() void {
    click_count = 0;
    std.debug.print("Demo reset!\n", .{});
}

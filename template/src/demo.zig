const std = @import("std");

pub const Status = enum { idle, running, paused, stopped };

pub const Mode = union(enum) {
    auto,
    manual: i32,
    timed: f32,
};

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
};

pub const Config = struct {
    enabled: bool = true,
    timeout: f32 = 5.0,
    retries: i32 = 3,
};

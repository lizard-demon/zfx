const std = @import("std");

pub const Status = enum { idle, running, paused, stopped };

pub const Mode = union(enum) {
    auto,
    manual: i32,
    timed: f32,
};

pub const Level = enum(u8) { low = 1, medium = 5, high = 10 };

var shared_int: i32 = 999;
var shared_config: Config = .{ .enabled = false, .timeout = 10.0, .retries = 5 };

pub const Demo = struct {
    // integers (various sizes)
    i8_value: i8 = -42,
    i16_value: i16 = 1000,
    i32_value: i32 = 42,
    i64_value: i64 = 999999,
    u8_value: u8 = 255,
    u16_value: u16 = 5000,
    u32_value: u32 = 100000,

    // floats
    f32_value: f32 = 3.14,
    f64_value: f64 = 2.71828,

    // bool
    bool_value: bool = true,

    // enums
    status: Status = .idle,
    level: Level = .medium,

    // strings (u8 arrays)
    name: [32]u8 = "hello".* ++ [_]u8{0} ** 27,
    label: [16]u8 = "test".* ++ [_]u8{0} ** 12,

    // arrays
    i32_array: [4]i32 = .{ 1, 2, 3, 4 },
    f32_array: [3]f32 = .{ 1.1, 2.2, 3.3 },
    bool_array: [2]bool = .{ true, false },

    // vectors (common sizes)
    vec2: @Vector(2, f32) = .{ 10.0, 20.0 },
    vec3: @Vector(3, f32) = .{ 1.0, 2.0, 3.0 },
    vec4: @Vector(4, f32) = .{ 1.0, 0.5, 0.25, 1.0 },
    ivec2: @Vector(2, i32) = .{ 100, 200 },
    ivec3: @Vector(3, i32) = .{ 1, 2, 3 },
    ivec4: @Vector(4, i32) = .{ 10, 20, 30, 40 },

    // optionals
    opt_null: ?i32 = null,
    opt_some: ?i32 = 42,
    opt_float: ?f32 = 2.5,
    opt_bool: ?bool = true,
    opt_struct: ?Config = null,

    // tagged union
    mode: Mode = .auto,

    // nested struct
    config: Config = .{},
    nested: Nested = .{},

    // error union
    result_ok: anyerror!i32 = 100,
    result_err: anyerror!i32 = error.Failed,

    // error set
    last_error: anyerror = error.Timeout,

    // pointers
    int_ptr: *i32 = &shared_int,
    config_ptr: *Config = &shared_config,

    // slices (string slices)
    message: []const u8 = "Hello, World!",

    // function pointers
    on_click: *const fn () void = &doNothing,
    on_reset: *const fn () void = &resetDemo,
    on_compute: *const fn (i32, i32) i32 = &add,
};

pub const Config = struct {
    enabled: bool = true,
    timeout: f32 = 5.0,
    retries: i32 = 3,
};

pub const Nested = struct {
    x: i32 = 10,
    y: i32 = 20,
    inner: Inner = .{},
};

pub const Inner = struct {
    value: f32 = 1.5,
    active: bool = false,
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

fn add(a: i32, b: i32) i32 {
    return a + b;
}

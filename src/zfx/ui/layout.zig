const std = @import("std");

pub fn Layout(comptime T: type) type {
    return struct {
        fn dim(e: anytype, axis: u1) *f32 {
            return if (axis == 0) &e.box.w else &e.box.h;
        }

        fn pad(e: anytype, axis: u1) f32 {
            return if (axis == 0) @floatFromInt(e.pad[0] + e.pad[2]) else @floatFromInt(e.pad[1] + e.pad[3]);
        }

        fn along(e: anytype, axis: u1) bool {
            return @intFromEnum(e.dir) == axis;
        }

        fn isType(v: anytype, comptime tag: anytype) bool {
            return @intFromEnum(v) == @intFromEnum(tag);
        }

        fn size(e: *T, a: std.mem.Allocator, axis: u1) !void {
            var q: std.ArrayList(*T) = .{};
            defer q.deinit(a);
            var buf: std.ArrayList(*T) = .{};
            defer buf.deinit(a);
            try q.append(a, e);
            var i: usize = 0;
            while (i < q.items.len) : (i += 1) {
                const p = q.items[i];
                const is_along = along(p, axis);
                const d = dim(p, axis);
                const pd = pad(p, axis);
                var content: f32 = 0;
                var total_pad: f32 = pd;
                var grow_cnt: i32 = 0;
                buf.clearRetainingCapacity();
                for (p.kids, 0..) |k, ki| {
                    const ksz = &k.sz[axis];
                    const kd = dim(k, axis);
                    if (k.kids.len > 0) try q.append(a, k);
                    const t = @intFromEnum(ksz.t);
                    if (t < 2) try buf.append(a, k);
                    if (is_along) {
                        if (t != 3) content += kd.*;
                        if (t == 1) grow_cnt += 1;
                        if (ki > 0) {
                            const g: f32 = @floatFromInt(p.gap);
                            content += g;
                            total_pad += g;
                        }
                    } else content = @max(kd.*, content);
                }
                for (p.kids) |k| {
                    const ksz = &k.sz[axis];
                    const kd = dim(k, axis);
                    if (@intFromEnum(ksz.t) == 3) {
                        kd.* = (d.* - total_pad) * ksz.v;
                        if (is_along) content += kd.*;
                    }
                }
                if (is_along) {
                    var space = d.* - pd - content;
                    if (space < 0) try compress(T, buf.items, &space, axis) else if (space > 0 and grow_cnt > 0) try expand(T, buf.items, &space, axis);
                } else {
                    for (buf.items) |k| {
                        const ksz = &k.sz[axis];
                        const kmin = if (axis == 0) k.min[0] else k.min[1];
                        const kd = dim(k, axis);
                        const max_sz = d.* - pd;
                        if (@intFromEnum(ksz.t) == 1) kd.* = @min(max_sz, ksz.mx);
                        kd.* = @max(kmin, @min(kd.*, max_sz));
                    }
                }
            }
        }

        fn pos(e: *T, p: @Vector(2, f32)) void {
            const pd = @Vector(2, f32){ @floatFromInt(e.pad[0]), @floatFromInt(e.pad[1]) };
            var content: @Vector(2, f32) = @splat(0);
            for (e.kids) |k| {
                if (@intFromEnum(e.dir) == 0) {
                    content[0] += k.box.w;
                    content[1] = @max(content[1], k.box.h);
                } else {
                    content[0] = @max(content[0], k.box.w);
                    content[1] += k.box.h;
                }
            }
            if (e.kids.len > 0) {
                const g: f32 = @floatFromInt(e.gap);
                const gc: f32 = @floatFromInt(e.kids.len - 1);
                if (@intFromEnum(e.dir) == 0) content[0] += g * gc else content[1] += g * gc;
            }
            const pdx: f32 = @floatFromInt(e.pad[0] + e.pad[2]);
            const pdy: f32 = @floatFromInt(e.pad[1] + e.pad[3]);
            var off = p + pd;
            const extra = @Vector(2, f32){ e.box.w - pdx - content[0], e.box.h - pdy - content[1] };
            if (@intFromEnum(e.dir) == 0) {
                off[0] += switch (@intFromEnum(e.al[0])) {
                    1 => extra[0] / 2,
                    2 => extra[0],
                    else => 0,
                };
            } else {
                off[1] += switch (@intFromEnum(e.al[1])) {
                    1 => extra[1] / 2,
                    2 => extra[1],
                    else => 0,
                };
            }
            for (e.kids) |k| {
                k.box.x = off[0];
                k.box.y = off[1];
                pos(k, off);
                const g: f32 = @floatFromInt(e.gap);
                if (@intFromEnum(e.dir) == 0) off[0] += k.box.w + g else off[1] += k.box.h + g;
            }
        }

        fn compress(comptime U: type, kids: []*U, space: *f32, axis: u1) !void {
            const a = std.heap.page_allocator;
            var buf: std.ArrayList(*U) = .{};
            defer buf.deinit(a);
            for (kids) |k| try buf.append(a, k);
            while (space.* < -0.001 and buf.items.len > 0) {
                var lg: f32 = 0;
                var lg2: f32 = 0;
                for (buf.items) |k| {
                    const d = dim(k, axis).*;
                    if (@abs(d - lg) < 0.001) continue;
                    if (d > lg) {
                        lg2 = lg;
                        lg = d;
                    } else if (d > lg2) lg2 = d;
                }
                var rem = lg2 - lg;
                rem = @max(rem, space.* / @as(f32, @floatFromInt(buf.items.len)));
                var idx: usize = 0;
                while (idx < buf.items.len) {
                    const k = buf.items[idx];
                    const d = dim(k, axis);
                    const mn = if (axis == 0) k.min[0] else k.min[1];
                    if (@abs(d.* - lg) < 0.001) {
                        const prev = d.*;
                        d.* += rem;
                        if (d.* <= mn) {
                            d.* = mn;
                            _ = buf.swapRemove(idx);
                            continue;
                        }
                        space.* -= (d.* - prev);
                    }
                    idx += 1;
                }
            }
        }

        fn expand(comptime U: type, kids: []*U, space: *f32, axis: u1) !void {
            const a = std.heap.page_allocator;
            var buf: std.ArrayList(*U) = .{};
            defer buf.deinit(a);
            for (kids) |k| if (@intFromEnum(k.sz[axis].t) == 1) try buf.append(a, k);
            while (space.* > 0.001 and buf.items.len > 0) {
                var sm: f32 = 3.4e38;
                var sm2: f32 = 3.4e38;
                for (buf.items) |k| {
                    const d = dim(k, axis).*;
                    if (@abs(d - sm) < 0.001) continue;
                    if (d < sm) {
                        sm2 = sm;
                        sm = d;
                    } else if (d < sm2) sm2 = d;
                }
                var add = sm2 - sm;
                add = @min(add, space.* / @as(f32, @floatFromInt(buf.items.len)));
                var idx: usize = 0;
                while (idx < buf.items.len) {
                    const k = buf.items[idx];
                    const d = dim(k, axis);
                    const mx = k.sz[axis].mx;
                    if (@abs(d.* - sm) < 0.001) {
                        const prev = d.*;
                        d.* += add;
                        if (d.* >= mx) {
                            d.* = mx;
                            _ = buf.swapRemove(idx);
                            continue;
                        }
                        space.* -= (d.* - prev);
                    }
                    idx += 1;
                }
            }
        }

        pub fn calc(a: std.mem.Allocator, root: *T) !void {
            try size(root, a, 0);
            try size(root, a, 1);
            pos(root, .{ 0, 0 });
        }
    };
}

pub const Box = extern struct { x: f32 = 0, y: f32 = 0, w: f32 = 0, h: f32 = 0 };
pub const Sizing = enum(u8) { fit, grow, fixed, percent };
pub const Dir = enum(u8) { h, v };
pub const Align = enum(u8) { start, center, end };

pub const Elem = struct {
    box: Box = .{},
    min: @Vector(2, f32) = @splat(0),
    sz: [2]struct { t: Sizing = .fit, v: f32 = 0, mn: f32 = 0, mx: f32 = 3.4e38 } = .{ .{}, .{} },
    pad: [4]u16 = .{ 0, 0, 0, 0 },
    gap: u16 = 0,
    dir: Dir = .h,
    al: [2]Align = .{ .start, .start },
    kids: []*Elem = &[_]*Elem{},
};

pub fn layout(a: std.mem.Allocator, root: *Elem) !void {
    try Layout(Elem).calc(a, root);
}

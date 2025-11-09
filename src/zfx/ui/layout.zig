const std = @import("std");

pub fn Layout(comptime T: type) type {
    return struct {
        fn d(e: *T, a: u1) *f32 {
            return if (a == 0) &e.box.w else &e.box.h;
        }
        fn pd(e: *T, a: u1) f32 {
            return @floatFromInt(if (a == 0) e.pad[0] + e.pad[2] else e.pad[1] + e.pad[3]);
        }
        fn along(e: *T, a: u1) bool {
            return @intFromEnum(e.dir) == a;
        }

        fn extremes(kids: []*T, a: u1, comptime least: bool) [2]f32 {
            var e1: f32 = if (least) 3.4e38 else -3.4e38;
            var e2 = e1;
            for (kids) |k| {
                const v = d(k, a).*;
                if (@abs(v - e1) < 0.001) continue;
                if (if (least) v < e1 else v > e1) {
                    e2 = e1;
                    e1 = v;
                } else if (if (least) v < e2 else v > e2) e2 = v;
            }
            return .{ e1, e2 };
        }

        fn size(e: *T, a: u1) void {
            for (e.kids) |k| if (k.kids.len > 0) size(k, a);

            const is_along = along(e, a);
            const parent_d = d(e, a);
            const parent_pd = pd(e, a);
            var content: f32 = 0;
            var total_pad = parent_pd;
            var grow_cnt: i32 = 0;

            for (e.kids, 0..) |k, i| {
                const sz = &k.sz[a];
                const t = @intFromEnum(sz.t);
                if (is_along) {
                    if (t != 3) content += d(k, a).*;
                    if (t == 1) grow_cnt += 1;
                    if (i > 0) {
                        const g: f32 = @floatFromInt(e.gap);
                        content += g;
                        total_pad += g;
                    }
                } else content = @max(d(k, a).*, content);
            }

            for (e.kids) |k| {
                const sz = &k.sz[a];
                if (@intFromEnum(sz.t) == 3) {
                    d(k, a).* = (parent_d.* - total_pad) * sz.v;
                    if (is_along) content += d(k, a).*;
                }
            }

            if (is_along) {
                var space = parent_d.* - parent_pd - content;
                if (space < 0) adjust(e.kids, &space, a, true) else if (space > 0 and grow_cnt > 0) adjust(e.kids, &space, a, false);
            } else {
                for (e.kids) |k| {
                    const sz = &k.sz[a];
                    const max_sz = parent_d.* - parent_pd;
                    if (@intFromEnum(sz.t) == 1) d(k, a).* = @min(max_sz, sz.mx);
                    d(k, a).* = @max(k.min[a], @min(d(k, a).*, max_sz));
                }
            }
        }

        fn pos(e: *T, p: @Vector(2, f32)) void {
            const dir = @intFromEnum(e.dir);
            const pd_vec = @Vector(2, f32){ @floatFromInt(e.pad[0]), @floatFromInt(e.pad[1]) };
            const pd_full = @Vector(2, f32){ @floatFromInt(e.pad[0] + e.pad[2]), @floatFromInt(e.pad[1] + e.pad[3]) };

            var content: @Vector(2, f32) = @splat(0);
            for (e.kids) |k| {
                if (dir == 0) {
                    content[0] += k.box.w;
                    content[1] = @max(content[1], k.box.h);
                } else {
                    content[0] = @max(content[0], k.box.w);
                    content[1] += k.box.h;
                }
            }
            if (e.kids.len > 0) {
                const gap_total: f32 = @floatFromInt(e.gap * @as(u16, @intCast(e.kids.len - 1)));
                content[dir] += gap_total;
            }

            var off = p + pd_vec;
            const extra = @Vector(2, f32){ e.box.w, e.box.h } - pd_full - content;
            if (dir == 0) {
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

            const gap: f32 = @floatFromInt(e.gap);
            for (e.kids) |k| {
                k.box.x = off[0];
                k.box.y = off[1];
                pos(k, off);
                off[dir] += (if (dir == 0) k.box.w else k.box.h) + gap;
            }
        }

        fn adjust(kids: []*T, space: *f32, a: u1, comptime shrink: bool) void {
            var active: usize = 0;
            for (kids) |k| {
                if (shrink or @intFromEnum(k.sz[a].t) == 1) active += 1;
            }
            if (active == 0) return;

            while ((if (shrink) space.* < -0.001 else space.* > 0.001) and active > 0) {
                const ex = extremes(kids, a, !shrink);
                const delta = if (shrink) @max(ex[1] - ex[0], space.* / @as(f32, @floatFromInt(active))) else @min(ex[1] - ex[0], space.* / @as(f32, @floatFromInt(active)));

                for (kids) |k| {
                    const sz = &k.sz[a];
                    if (shrink or @intFromEnum(sz.t) == 1) {
                        if (@abs(d(k, a).* - ex[0]) < 0.001) {
                            const prev = d(k, a).*;
                            d(k, a).* += delta;
                            const limit = if (shrink) k.min[a] else sz.mx;
                            if (if (shrink) d(k, a).* <= limit else d(k, a).* >= limit) {
                                d(k, a).* = limit;
                                active -= 1;
                            }
                            space.* -= (d(k, a).* - prev);
                        }
                    }
                }
            }
        }

        pub fn calc(root: *T) void {
            size(root, 0);
            size(root, 1);
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

pub fn layout(root: *Elem) void {
    Layout(Elem).calc(root);
}

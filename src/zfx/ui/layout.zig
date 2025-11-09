const std = @import("std");

pub fn Layout(comptime T: type) type {
    return struct {
        fn extremes(vals: []f32, least: bool) [2]f32 {
            var e1: f32 = if (least) 3.4e38 else -3.4e38;
            var e2 = e1;
            for (vals) |v| {
                if (@abs(v - e1) < 0.001) continue;
                if (if (least) v < e1 else v > e1) {
                    e2 = e1;
                    e1 = v;
                } else if (if (least) v < e2 else v > e2) e2 = v;
            }
            return .{ e1, e2 };
        }

        fn distribute(vals: []*f32, limits: []f32, delta: f32, shrink: bool) void {
            var space = delta;
            var active: usize = vals.len;
            while (@abs(space) > 0.001 and active > 0) {
                var temp: [256]f32 = undefined;
                for (vals, 0..) |v, i| temp[i] = v.*;
                const ex = extremes(temp[0..vals.len], !shrink);
                const step = if (shrink) @max(ex[1] - ex[0], space / @as(f32, @floatFromInt(active))) else @min(ex[1] - ex[0], space / @as(f32, @floatFromInt(active)));
                for (vals, limits) |v, lim| {
                    if (@abs(v.* - ex[0]) < 0.001) {
                        const prev = v.*;
                        v.* += step;
                        if (if (shrink) v.* <= lim else v.* >= lim) {
                            v.* = lim;
                            active -= 1;
                        }
                        space -= (v.* - prev);
                    }
                }
            }
        }

        fn size(e: *T, a: u1) void {
            for (e.kids) |k| if (k.kids.len > 0) size(k, a);
            if (e.kids.len == 0) return;

            const along = @intFromEnum(e.dir) == a;
            const pd: f32 = @floatFromInt(if (a == 0) e.pad[0] + e.pad[2] else e.pad[1] + e.pad[3]);
            const gaps: f32 = @floatFromInt(e.gap * @as(u16, @intCast(e.kids.len - 1)));
            const parent = (if (a == 0) &e.box.w else &e.box.h).*;

            var dims: [256]f32 = undefined;
            var grow: usize = 0;
            for (e.kids, 0..) |k, i| {
                const sz = &k.sz[a];
                dims[i] = if (a == 0) k.box.w else k.box.h;
                if (@intFromEnum(sz.t) == 3) dims[i] = (parent - pd - gaps) * sz.v;
                if (@intFromEnum(sz.t) == 1) grow += 1;
            }

            var content: f32 = 0;
            for (dims[0..e.kids.len]) |v| content = if (along) content + v else @max(content, v);
            if (along) content += gaps;

            const delta = parent - pd - content;
            if (along and (delta < -0.001 or (delta > 0.001 and grow > 0))) {
                var vals: [256]*f32 = undefined;
                var limits: [256]f32 = undefined;
                var n: usize = 0;
                for (e.kids, 0..) |k, i| {
                    if (delta < 0 or @intFromEnum(k.sz[a].t) == 1) {
                        vals[n] = &dims[i];
                        limits[n] = if (delta < 0) k.min[a] else k.sz[a].mx;
                        n += 1;
                    }
                }
                distribute(vals[0..n], limits[0..n], delta, delta < 0);
            } else if (!along) {
                for (e.kids, 0..) |k, i| {
                    if (@intFromEnum(k.sz[a].t) == 1) dims[i] = @min(parent - pd, k.sz[a].mx);
                    dims[i] = @max(k.min[a], @min(dims[i], parent - pd));
                }
            }

            for (e.kids, 0..) |k, i| (if (a == 0) &k.box.w else &k.box.h).* = dims[i];
        }

        fn pos(e: *T, p: @Vector(2, f32)) void {
            const dir = @intFromEnum(e.dir);
            const pd = @Vector(2, f32){ @floatFromInt(e.pad[0]), @floatFromInt(e.pad[1]) };
            const pd_full = @Vector(2, f32){ @floatFromInt(e.pad[0] + e.pad[2]), @floatFromInt(e.pad[1] + e.pad[3]) };

            var content: @Vector(2, f32) = @splat(0);
            for (e.kids) |k| {
                content[dir] += if (dir == 0) k.box.w else k.box.h;
                content[1 - dir] = @max(content[1 - dir], if (dir == 0) k.box.h else k.box.w);
            }
            if (e.kids.len > 0) content[dir] += @floatFromInt(e.gap * @as(u16, @intCast(e.kids.len - 1)));

            var off = p + pd;
            const extra = @Vector(2, f32){ e.box.w, e.box.h } - pd_full - content;
            const aa: usize = if (dir == 0) 0 else 1;
            off[aa] += switch (@intFromEnum(e.al[aa])) {
                1 => extra[aa] / 2,
                2 => extra[aa],
                else => 0,
            };

            const gap: f32 = @floatFromInt(e.gap);
            for (e.kids) |k| {
                k.box.x = off[0];
                k.box.y = off[1];
                pos(k, off);
                off[dir] += (if (dir == 0) k.box.w else k.box.h) + gap;
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

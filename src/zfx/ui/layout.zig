const std = @import("std");

const epsilon: f32 = 0.001;
const maxfloat: f32 = 3.4e38;

pub const Sizing = enum(u8) { fit, grow, fixed, percent };
pub const Dir = enum(u8) { h, v };
pub const Align = enum(u8) { start, center, end };

pub const Size = struct {
    mode: Sizing = .fit,
    value: f32 = 0,
    min: f32 = 0,
    max: f32 = maxfloat,
};

pub const Widget = struct {
    pos: @Vector(2, f32) = @splat(0),
    size: @Vector(2, f32) = @splat(0),
    min: @Vector(2, f32) = @splat(0),
    sz: [2]Size = .{ .{}, .{} },
    pad: @Vector(4, u16) = @splat(0),
    gap: u16 = 0,
    dir: Dir = .h,
    al: [2]Align = .{ .start, .start },
    children: []*Widget = &[_]*Widget{},
};

const compute = struct {
    fn extremes(vals: []f32, least: bool) [2]f32 {
        var e1: f32 = if (least) maxfloat else -maxfloat;
        var e2 = e1;
        for (vals) |v| {
            if (@abs(v - e1) < epsilon) continue;
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
        while (@abs(space) > epsilon and active > 0) {
            var temp: [256]f32 = undefined;
            for (vals, 0..) |v, i| temp[i] = v.*;
            const ex = extremes(temp[0..vals.len], !shrink);
            const step = if (shrink) @max(ex[1] - ex[0], space / @as(f32, @floatFromInt(active))) else @min(ex[1] - ex[0], space / @as(f32, @floatFromInt(active)));
            for (vals, limits) |v, lim| {
                if (@abs(v.* - ex[0]) < epsilon) {
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

    fn size(w: *Widget, axis: u1) void {
        for (w.children) |child| if (child.children.len > 0) size(child, axis);
        if (w.children.len == 0) return;

        const along = @intFromEnum(w.dir) == axis;
        const pd_vec = @Vector(2, f32){ @floatFromInt(w.pad[0] + w.pad[2]), @floatFromInt(w.pad[1] + w.pad[3]) };
        const gaps: f32 = @floatFromInt(w.gap * @as(u16, @intCast(w.children.len - 1)));

        var dims: [256]f32 = undefined;
        var grow: usize = 0;
        for (w.children, 0..) |child, i| {
            const sz = &child.sz[axis];
            dims[i] = child.size[axis];
            if (@intFromEnum(sz.mode) == 3) dims[i] = (w.size[axis] - pd_vec[axis] - gaps) * sz.value;
            if (@intFromEnum(sz.mode) == 1) grow += 1;
        }

        var content: f32 = 0;
        for (dims[0..w.children.len]) |v| content = if (along) content + v else @max(content, v);
        if (along) content += gaps;

        const delta = w.size[axis] - pd_vec[axis] - content;
        if (along and (delta < -epsilon or (delta > epsilon and grow > 0))) {
            var vals: [256]*f32 = undefined;
            var limits: [256]f32 = undefined;
            var n: usize = 0;
            for (w.children, 0..) |child, i| {
                if (delta < 0 or @intFromEnum(child.sz[axis].mode) == 1) {
                    vals[n] = &dims[i];
                    limits[n] = if (delta < 0) child.min[axis] else child.sz[axis].max;
                    n += 1;
                }
            }
            distribute(vals[0..n], limits[0..n], delta, delta < 0);
        } else if (!along) {
            for (w.children, 0..) |child, i| {
                if (@intFromEnum(child.sz[axis].mode) == 1) dims[i] = @min(w.size[axis] - pd_vec[axis], child.sz[axis].max);
                dims[i] = @max(child.min[axis], @min(dims[i], w.size[axis] - pd_vec[axis]));
            }
        }

        for (w.children, 0..) |child, i| child.size[axis] = dims[i];
    }

    fn pos(w: *Widget, p: @Vector(2, f32)) void {
        const dir = @intFromEnum(w.dir);
        const pd = @Vector(2, f32){ @floatFromInt(w.pad[0]), @floatFromInt(w.pad[1]) };
        const pd_full = @Vector(2, f32){ @floatFromInt(w.pad[0] + w.pad[2]), @floatFromInt(w.pad[1] + w.pad[3]) };

        var content: @Vector(2, f32) = @splat(0);
        for (w.children) |child| {
            content[dir] += child.size[dir];
            content[1 - dir] = @max(content[1 - dir], child.size[1 - dir]);
        }
        if (w.children.len > 0) content[dir] += @floatFromInt(w.gap * @as(u16, @intCast(w.children.len - 1)));

        var off = p + pd;
        const extra = w.size - pd_full - content;
        const aa: usize = if (dir == 0) 0 else 1;
        off[aa] += switch (@intFromEnum(w.al[aa])) {
            1 => extra[aa] / 2,
            2 => extra[aa],
            else => 0,
        };

        const gap: f32 = @floatFromInt(w.gap);
        for (w.children) |child| {
            child.pos = off;
            pos(child, off);
            off[dir] += child.size[dir] + gap;
        }
    }
};

pub fn layout(root: *Widget) void {
    compute.size(root, 0);
    compute.size(root, 1);
    compute.pos(root, .{ 0, 0 });
}

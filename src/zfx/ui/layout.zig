const std = @import("std");

const eps: f32 = 0.001;
const inf: f32 = 3.4e38;

pub const Dir = enum(u8) { h, v };
pub const Align = enum(u8) { start, center, end };

pub const Widget = struct {
    x: f32 = 0,
    y: f32 = 0,
    w: f32 = 0,
    h: f32 = 0,
    sw: f32 = 0, // 0=fit, <0=grow(weight), >0=fixed
    sh: f32 = 0,
    dir: Dir = .h,
    ax: Align = .start,
    ay: Align = .start,
    pad: u16 = 0,
    gap: u16 = 0,
};

fn extremes(vals: []f32, least: bool) [2]f32 {
    var e1: f32 = if (least) inf else -inf;
    var e2 = e1;
    for (vals) |v| {
        if (@abs(v - e1) < eps) continue;
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
    var temp: [256]f32 = undefined;
    while (@abs(space) > eps and active > 0) {
        for (vals, 0..) |v, i| temp[i] = v.*;
        const ex = extremes(temp[0..vals.len], !shrink);
        const step = if (shrink) @max(ex[1] - ex[0], space / @as(f32, @floatFromInt(active))) else @min(ex[1] - ex[0], space / @as(f32, @floatFromInt(active)));
        for (vals, limits) |v, lim| {
            if (@abs(v.* - ex[0]) < eps) {
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

fn computeSize(parent: *Widget, children: []Widget, axis: u1) void {
    if (children.len == 0) return;

    const along = @intFromEnum(parent.dir) == axis;
    const pd: f32 = @floatFromInt(parent.pad * 2);
    const gaps: f32 = @floatFromInt(parent.gap * @as(u16, @intCast(children.len - 1)));
    const avail = (if (axis == 0) parent.w else parent.h) - pd;

    var dims: [256]f32 = undefined;
    var grow_sum: f32 = 0;

    for (children, 0..) |*child, i| {
        const sz = if (axis == 0) child.sw else child.sh;
        const dim = if (axis == 0) child.w else child.h;

        if (sz < 0) {
            grow_sum += -sz;
            dims[i] = 0;
        } else if (sz > 0) {
            dims[i] = sz;
        } else {
            dims[i] = dim;
        }
    }

    var content: f32 = 0;
    for (dims[0..children.len]) |v| content = if (along) content + v else @max(content, v);
    if (along) content += gaps;

    const delta = avail - content;

    if (along and grow_sum > 0 and delta > eps) {
        const per_weight = delta / grow_sum;
        for (children, 0..) |*child, i| {
            const sz = if (axis == 0) child.sw else child.sh;
            if (sz < 0) dims[i] = per_weight * (-sz);
        }
    } else if (along and delta < -eps) {
        var vals: [256]*f32 = undefined;
        var limits: [256]f32 = undefined;
        var n: usize = 0;
        for (0..children.len) |i| {
            vals[n] = &dims[i];
            limits[n] = 0;
            n += 1;
        }
        distribute(vals[0..n], limits[0..n], delta, true);
    } else if (!along) {
        for (0..children.len) |i| {
            dims[i] = @min(dims[i], avail);
        }
    }

    for (children, 0..) |*child, i| {
        if (axis == 0) {
            child.w = dims[i];
        } else {
            child.h = dims[i];
        }
    }
}

fn computePos(parent: *Widget, children: []Widget) void {
    if (children.len == 0) return;

    const dir = @intFromEnum(parent.dir);
    const pd: f32 = @floatFromInt(parent.pad);
    const gap: f32 = @floatFromInt(parent.gap);

    var content: @Vector(2, f32) = @splat(0);
    for (children) |child| {
        content[dir] += if (dir == 0) child.w else child.h;
        content[1 - dir] = @max(content[1 - dir], if (dir == 0) child.h else child.w);
    }
    if (children.len > 0) content[dir] += gap * @as(f32, @floatFromInt(children.len - 1));

    const parent_size: @Vector(2, f32) = .{ parent.w, parent.h };
    var off: @Vector(2, f32) = .{ parent.x + pd, parent.y + pd };
    const extra = parent_size - @as(@Vector(2, f32), @splat(pd * 2)) - content;

    const ax = if (dir == 0) parent.ax else parent.ay;
    off[dir] += switch (ax) {
        .center => extra[dir] / 2,
        .end => extra[dir],
        else => 0,
    };

    for (children) |*child| {
        child.x = off[0];
        child.y = off[1];
        off[dir] += (if (dir == 0) child.w else child.h) + gap;
    }
}

pub fn layout(parent: *Widget, children: []Widget) void {
    computeSize(parent, children, 0);
    computeSize(parent, children, 1);
    computePos(parent, children);
}

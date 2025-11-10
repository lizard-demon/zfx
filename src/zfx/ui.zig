const std = @import("std");
const ig = @import("cimgui");

const epsilon: f32 = 0.001;
const maxfloat: f32 = 3.4e38;

// Core types
pub const Dir = enum(u8) { h, v };
pub const Align = enum(u8) { start, center, end };

pub const Size = union(enum) {
    fit,
    grow: f32,
    fixed: f32,
    percent: f32,

    pub fn Fit() Size {
        return .fit;
    }
    pub fn Grow() Size {
        return .{ .grow = 1.0 };
    }
    pub fn Growf(weight: f32) Size {
        return .{ .grow = weight };
    }
    pub fn Fixed(v: f32) Size {
        return .{ .fixed = v };
    }
    pub fn Percent(v: f32) Size {
        return .{ .percent = v };
    }

    fn min(self: Size) f32 {
        return switch (self) {
            .fit => 0,
            .grow => 0,
            .fixed => |v| v,
            .percent => 0,
        };
    }

    fn max(self: Size) f32 {
        return switch (self) {
            .fit => maxfloat,
            .grow => |_| maxfloat,
            .fixed => |v| v,
            .percent => maxfloat,
        };
    }
};

pub const Rect = struct {
    x: f32 = 0,
    y: f32 = 0,
    w: f32 = 0,
    h: f32 = 0,
};

pub const Widget = struct {
    rect: Rect = .{},
    w: Size = .fit,
    h: Size = .fit,
    dir: Dir = .h,
    al: [2]Align = .{ .start, .start },
    pad: u16 = 0,
    gap: u16 = 0,
};

pub const Response = struct {
    changed: bool = false,
    hovered: bool = false,
    active: bool = false,
};

// Layout computation
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

    fn size(parent: *Widget, children: []*Widget, axis: u1) void {
        if (children.len == 0) return;

        const along = @intFromEnum(parent.dir) == axis;
        const pd: f32 = @floatFromInt(parent.pad * 2);
        const gaps: f32 = @floatFromInt(parent.gap * @as(u16, @intCast(children.len - 1)));

        var dims: [256]f32 = undefined;
        var grow_total: f32 = 0;

        for (children, 0..) |child, i| {
            const sz = if (axis == 0) child.w else child.h;
            const parent_size = if (axis == 0) parent.rect.w else parent.rect.h;

            dims[i] = switch (sz) {
                .fit => if (axis == 0) child.rect.w else child.rect.h,
                .grow => |weight| blk: {
                    grow_total += weight;
                    break :blk 0;
                },
                .fixed => |v| v,
                .percent => |p| (parent_size - pd - gaps) * p,
            };
        }

        var content: f32 = 0;
        for (dims[0..children.len]) |v| content = if (along) content + v else @max(content, v);
        if (along) content += gaps;

        const available = (if (axis == 0) parent.rect.w else parent.rect.h) - pd;
        const delta = available - content;

        if (along and grow_total > 0 and delta > epsilon) {
            const per_weight = delta / grow_total;
            for (children, 0..) |child, i| {
                const sz = if (axis == 0) child.w else child.h;
                if (sz == .grow) {
                    dims[i] = per_weight * sz.grow;
                }
            }
        } else if (along and delta < -epsilon) {
            var vals: [256]*f32 = undefined;
            var limits: [256]f32 = undefined;
            var n: usize = 0;
            for (children, 0..) |child, i| {
                vals[n] = &dims[i];
                limits[n] = (if (axis == 0) child.w else child.h).min();
                n += 1;
            }
            distribute(vals[0..n], limits[0..n], delta, true);
        } else if (!along) {
            for (children, 0..) |child, i| {
                const sz = if (axis == 0) child.w else child.h;
                const mn = sz.min();
                const mx = sz.max();
                dims[i] = @max(mn, @min(dims[i], @min(mx, available)));
            }
        }

        for (children, 0..) |child, i| {
            if (axis == 0) {
                child.rect.w = dims[i];
            } else {
                child.rect.h = dims[i];
            }
        }
    }

    fn pos(parent: *Widget, children: []*Widget) void {
        if (children.len == 0) return;

        const dir = @intFromEnum(parent.dir);
        const pd: f32 = @floatFromInt(parent.pad);

        var content: @Vector(2, f32) = @splat(0);
        for (children) |child| {
            content[dir] += if (dir == 0) child.rect.w else child.rect.h;
            content[1 - dir] = @max(content[1 - dir], if (dir == 0) child.rect.h else child.rect.w);
        }
        if (children.len > 0) content[dir] += @floatFromInt(parent.gap * @as(u16, @intCast(children.len - 1)));

        const parent_size: @Vector(2, f32) = .{ parent.rect.w, parent.rect.h };
        var off: @Vector(2, f32) = .{ parent.rect.x + pd, parent.rect.y + pd };
        const extra = parent_size - @as(@Vector(2, f32), @splat(pd * 2)) - content;
        const aa: usize = if (dir == 0) 0 else 1;
        off[aa] += switch (@intFromEnum(parent.al[aa])) {
            1 => extra[aa] / 2,
            2 => extra[aa],
            else => 0,
        };

        const gap: f32 = @floatFromInt(parent.gap);
        for (children) |child| {
            child.rect.x = off[0];
            child.rect.y = off[1];
            off[dir] += (if (dir == 0) child.rect.w else child.rect.h) + gap;
        }
    }
};

// Rendering
const render = struct {
    fn any(label: [*:0]const u8, value: anytype, r: *Response) void {
        const T = @TypeOf(value.*);
        switch (@typeInfo(T)) {
            .int => |int_info| {
                if (int_info.bits == 32 and int_info.signedness == .signed) {
                    r.changed = ig.igInputInt(label, @ptrCast(value));
                } else {
                    var temp: i32 = @intCast(value.*);
                    if (ig.igInputInt(label, &temp)) {
                        value.* = @intCast(temp);
                        r.changed = true;
                    }
                }
            },
            .float => |float_info| {
                if (float_info.bits == 32) {
                    r.changed = ig.igInputFloat(label, @ptrCast(value));
                } else {
                    var temp: f32 = @floatCast(value.*);
                    if (ig.igInputFloat(label, &temp)) {
                        value.* = @floatCast(temp);
                        r.changed = true;
                    }
                }
            },
            .bool => r.changed = ig.igCheckbox(label, value),
            .@"enum" => @"enum"(label, value, r),
            .@"struct" => @"struct"(label, value, r),
            .array => |arr| if (arr.child == u8) string(label, value, r) else array(label, value, r),
            .optional => optional(label, value, r),
            .pointer => |ptr| {
                if (ptr.size == .slice) {
                    slice(label, value, r);
                } else if (@typeInfo(ptr.child) == .@"fn") {
                    function(label, value, r);
                } else {
                    pointer(label, value, r);
                }
            },
            .vector => vector(label, value, r),
            .@"union" => @"union"(label, value, r),
            .error_union => errorunion(label, value, r),
            .error_set => errorset(label, value, r),
            .@"fn" => function(label, value, r),
            else => ig.igText("unsupported"),
        }
    }

    fn @"struct"(label: [*:0]const u8, value: anytype, r: *Response) void {
        const T = @TypeOf(value.*);
        const fields = @typeInfo(T).@"struct".fields;

        // Check if struct has 'self' Widget
        const has_self = comptime blk: {
            for (fields) |field| {
                if (std.mem.eql(u8, field.name, "self") and field.type == Widget) {
                    break :blk true;
                }
            }
            break :blk false;
        };

        if (has_self) {
            const self_widget = &@field(value, "self");

            // Collect child widgets
            var child_widgets: [256]*Widget = undefined;
            var child_count: usize = 0;
            inline for (fields) |field| {
                if (!std.mem.eql(u8, field.name, "self")) {
                    const field_type_info = @typeInfo(field.type);
                    if (field_type_info == .@"struct") {
                        const field_has_self = comptime blk: {
                            for (field_type_info.@"struct".fields) |f| {
                                if (std.mem.eql(u8, f.name, "self") and f.type == Widget) {
                                    break :blk true;
                                }
                            }
                            break :blk false;
                        };
                        if (field_has_self) {
                            child_widgets[child_count] = &@field(value, field.name).self;
                            child_count += 1;
                        }
                    }
                }
            }

            // Compute layout for children
            if (child_count > 0) {
                compute.size(self_widget, child_widgets[0..child_count], 0);
                compute.size(self_widget, child_widgets[0..child_count], 1);
                compute.pos(self_widget, child_widgets[0..child_count]);
            }

            // Render window
            ig.igSetNextWindowPos(.{ .x = self_widget.rect.x, .y = self_widget.rect.y }, ig.ImGuiCond_Always);
            ig.igSetNextWindowSize(.{ .x = self_widget.rect.w, .y = self_widget.rect.h }, ig.ImGuiCond_Always);
            _ = ig.igBegin(label, null, ig.ImGuiWindowFlags_NoResize | ig.ImGuiWindowFlags_NoMove | ig.ImGuiWindowFlags_NoCollapse);

            // Render fields
            inline for (fields) |field| {
                if (!std.mem.eql(u8, field.name, "self")) {
                    const field_label = field.name ++ "\x00";
                    ig.igPushID(field.name.ptr);
                    var fr = Response{};
                    any(@ptrCast(field_label.ptr), &@field(value, field.name), &fr);
                    if (fr.changed) r.changed = true;
                    ig.igPopID();
                }
            }

            ig.igEnd();

            // Call onchange if it exists and something changed
            if (r.changed and @hasDecl(T, "onchange")) {
                value.onchange();
            }
        } else {
            // Default tree rendering
            ig.igPushID(label);
            defer ig.igPopID();
            if (ig.igTreeNode(label)) {
                defer ig.igTreePop();
                inline for (fields) |field| {
                    const field_label = field.name ++ "\x00";
                    ig.igPushID(field.name.ptr);
                    var fr = Response{};
                    any(@ptrCast(field_label.ptr), &@field(value, field.name), &fr);
                    if (fr.changed) r.changed = true;
                    ig.igPopID();
                }
            }
        }
    }

    fn @"enum"(label: [*:0]const u8, value: anytype, r: *Response) void {
        const T = @TypeOf(value.*);
        const current = @tagName(value.*);
        if (ig.igBeginCombo(label, current.ptr, ig.ImGuiComboFlags_None)) {
            defer ig.igEndCombo();
            inline for (comptime std.meta.fields(T)) |field| {
                if (ig.igSelectable(field.name.ptr)) {
                    value.* = @field(T, field.name);
                    r.changed = true;
                }
                if (std.mem.eql(u8, current, field.name)) ig.igSetItemDefaultFocus();
            }
        }
    }

    fn array(label: [*:0]const u8, value: anytype, r: *Response) void {
        ig.igPushID(label);
        defer ig.igPopID();
        if (ig.igTreeNode(label)) {
            defer ig.igTreePop();
            for (value, 0..) |*item, i| {
                var buf: [64]u8 = undefined;
                const elem_label = std.fmt.bufPrintZ(&buf, "[{d}]", .{i}) catch "[?]";
                ig.igPushID(elem_label.ptr);
                var er = Response{};
                any(elem_label.ptr, item, &er);
                if (er.changed) r.changed = true;
                ig.igPopID();
            }
        }
    }

    fn string(label: [*:0]const u8, value: anytype, r: *Response) void {
        if (ig.igInputText(label, @ptrCast(value), value.len, ig.ImGuiInputTextFlags_None)) r.changed = true;
    }

    fn optional(label: [*:0]const u8, value: anytype, r: *Response) void {
        const T = @TypeOf(value.*);
        const child = @typeInfo(T).optional.child;
        var has = value.* != null;
        var buf: [128]u8 = undefined;
        const check = std.fmt.bufPrintZ(&buf, "##has_{s}", .{label}) catch "##has";
        if (ig.igCheckbox(check.ptr, &has)) {
            value.* = if (has and value.* == null) (if (@sizeOf(child) > 0) std.mem.zeroes(child) else {}) else null;
            r.changed = true;
        }
        ig.igSameLine();
        if (value.*) |*inner| {
            var ir = Response{};
            any(label, inner, &ir);
            if (ir.changed) r.changed = true;
        } else ig.igTextDisabled("%s: null", label);
    }

    fn slice(label: [*:0]const u8, value: anytype, r: *Response) void {
        const T = @TypeOf(value.*);
        const child = @typeInfo(T).pointer.child;
        if (child == u8) {
            ig.igText("%s: \"%s\"", label, value.*.ptr);
            return;
        }
        ig.igPushID(label);
        defer ig.igPopID();
        if (ig.igTreeNode(label)) {
            defer ig.igTreePop();
            for (value.*, 0..) |*item, i| {
                var buf: [64]u8 = undefined;
                const elem_label = std.fmt.bufPrintZ(&buf, "[{d}]", .{i}) catch "[?]";
                ig.igPushID(elem_label.ptr);
                var er = Response{};
                any(elem_label.ptr, item, &er);
                if (er.changed) r.changed = true;
                ig.igPopID();
            }
        }
    }

    fn pointer(label: [*:0]const u8, value: anytype, r: *Response) void {
        ig.igPushID(label);
        defer ig.igPopID();
        if (ig.igTreeNode(label)) {
            defer ig.igTreePop();
            var pr = Response{};
            any("*", value.*, &pr);
            if (pr.changed) r.changed = true;
        }
    }

    fn vector(label: [*:0]const u8, value: anytype, r: *Response) void {
        const T = @TypeOf(value.*);
        const info = @typeInfo(T).vector;
        if (info.child == f32) {
            switch (info.len) {
                2 => r.changed = ig.igInputFloat2(label, @ptrCast(value)),
                3 => r.changed = ig.igInputFloat3(label, @ptrCast(value)),
                4 => r.changed = ig.igInputFloat4(label, @ptrCast(value)),
                else => {
                    ig.igPushID(label);
                    defer ig.igPopID();
                    if (ig.igTreeNode(label)) {
                        defer ig.igTreePop();
                        inline for (0..info.len) |i| {
                            var buf: [64]u8 = undefined;
                            const elem_label = std.fmt.bufPrintZ(&buf, "[{d}]", .{i}) catch "[?]";
                            var v = value.*[i];
                            if (ig.igInputFloat(elem_label.ptr, &v)) {
                                value.*[i] = v;
                                r.changed = true;
                            }
                        }
                    }
                },
            }
        } else if (info.child == i32) {
            switch (info.len) {
                2 => r.changed = ig.igInputInt2(label, @ptrCast(value)),
                3 => r.changed = ig.igInputInt3(label, @ptrCast(value)),
                4 => r.changed = ig.igInputInt4(label, @ptrCast(value)),
                else => {
                    ig.igPushID(label);
                    defer ig.igPopID();
                    if (ig.igTreeNode(label)) {
                        defer ig.igTreePop();
                        inline for (0..info.len) |i| {
                            var buf: [64]u8 = undefined;
                            const elem_label = std.fmt.bufPrintZ(&buf, "[{d}]", .{i}) catch "[?]";
                            var v = value.*[i];
                            if (ig.igInputInt(elem_label.ptr, &v)) {
                                value.*[i] = v;
                                r.changed = true;
                            }
                        }
                    }
                },
            }
        } else {
            const len: c_int = @intCast(info.len);
            ig.igText("%s: vector<%d>", label, len);
        }
    }

    fn @"union"(label: [*:0]const u8, value: anytype, r: *Response) void {
        const T = @TypeOf(value.*);
        const info = @typeInfo(T).@"union";
        if (info.tag_type) |_| {
            const current = @tagName(value.*);
            if (ig.igBeginCombo(label, current.ptr, ig.ImGuiComboFlags_None)) {
                defer ig.igEndCombo();
                inline for (comptime std.meta.fields(T)) |field| {
                    if (ig.igSelectable(field.name.ptr)) {
                        value.* = @unionInit(T, field.name, if (@sizeOf(field.type) > 0) std.mem.zeroes(field.type) else {});
                        r.changed = true;
                    }
                    if (std.mem.eql(u8, current, field.name)) ig.igSetItemDefaultFocus();
                }
            }
            ig.igPushID(label);
            defer ig.igPopID();
            inline for (comptime std.meta.fields(T)) |field| {
                if (std.mem.eql(u8, @tagName(value.*), field.name)) {
                    const field_label = field.name ++ "\x00";
                    var fr = Response{};
                    any(@ptrCast(field_label.ptr), &@field(value.*, field.name), &fr);
                    if (fr.changed) r.changed = true;
                }
            }
        } else {
            ig.igText("%s: untagged union", label);
        }
    }

    fn errorunion(label: [*:0]const u8, value: anytype, r: *Response) void {
        if (value.*) |*payload| {
            var pr = Response{};
            any(label, payload, &pr);
            if (pr.changed) r.changed = true;
        } else |err| {
            ig.igTextColored(.{ .x = 1, .y = 0.4, .z = 0.4, .w = 1 }, "%s: error.%s", label, @errorName(err).ptr);
        }
    }

    fn errorset(label: [*:0]const u8, value: anytype, r: *Response) void {
        _ = r;
        ig.igText("%s: error.%s", label, @errorName(value.*).ptr);
    }

    fn function(label: [*:0]const u8, value: anytype, r: *Response) void {
        const T = @TypeOf(value.*);
        const ptr_info = @typeInfo(T).pointer;
        const fn_info = @typeInfo(ptr_info.child).@"fn";

        const can_call = fn_info.params.len == 0;

        if (can_call) {
            if (ig.igButton(label)) {
                if (fn_info.return_type) |_| {
                    _ = value.*();
                } else {
                    value.*();
                }
                r.changed = true;
            }
        } else {
            var buf: [256]u8 = undefined;
            const sig = std.fmt.bufPrintZ(&buf, "{s} (fn with {d} params)", .{ label, fn_info.params.len }) catch label;
            ig.igTextDisabled("%s", sig.ptr);
        }
    }
};

// Public API
pub fn widget(label: [*:0]const u8, value: anytype) Response {
    var r = Response{};
    render.any(label, value, &r);
    if (ig.igIsItemHovered(ig.ImGuiHoveredFlags_None)) r.hovered = true;
    if (ig.igIsItemActive()) r.active = true;
    return r;
}

pub fn ui_render(label: [*:0]const u8, value: anytype, size: Rect) Response {
    // Set root widget size
    const T = @TypeOf(value.*);
    if (@hasField(T, "self")) {
        @field(value, "self").rect = size;
    }
    return widget(label, value);
}

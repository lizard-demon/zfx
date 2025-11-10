const std = @import("std");
const ig = @import("cimgui");
const L = @import("layout.zig");

pub const Widget = L.Widget;

pub const Response = struct {
    changed: bool = false,
    hovered: bool = false,
    active: bool = false,
};

const check = struct {
    fn has_widget(comptime T: type) bool {
        if (@typeInfo(T) != .@"struct") return false;
        inline for (@typeInfo(T).@"struct".fields) |f| {
            if (std.mem.eql(u8, f.name, "widget") and f.type == Widget) return true;
        }
        return false;
    }
};

const draw = struct {
    fn any(label: [*:0]const u8, value: anytype) bool {
        const T = @TypeOf(value.*);
        return switch (@typeInfo(T)) {
            .int => primitive.int(label, value),
            .float => primitive.float(label, value),
            .bool => ig.igCheckbox(label, value),
            .@"enum" => menu.combo(label, T, value, comptime std.meta.fields(T)),
            .@"struct" => if (comptime check.has_widget(T)) widget(label, value) else tree(label, value),
            .array => |arr| if (arr.child == u8)
                ig.igInputText(label, @ptrCast(value), value.len, ig.ImGuiInputTextFlags_None)
            else
                sequence(label, arr.len, value, struct {
                    fn get(v: anytype, i: usize) *arr.child {
                        return &v.*[i];
                    }
                }.get),
            .optional => optional(label, value),
            .pointer => |ptr| if (ptr.size == .slice)
                if (ptr.child == u8) blk: {
                    ig.igText("%s: \"%s\"", label, value.*.ptr);
                    break :blk false;
                } else sequence(label, value.*.len, value, struct {
                    fn get(v: anytype, i: usize) *ptr.child {
                        return &v.*[i];
                    }
                }.get)
            else if (@typeInfo(ptr.child) == .@"fn")
                function(label, value)
            else
                deref(label, value),
            .vector => |vec| vector(label, value, vec),
            .@"union" => |u| if (u.tag_type != null) tagged(label, value) else blk: {
                ig.igText("%s: untagged union", label);
                break :blk false;
            },
            .error_union => error_union(label, value),
            .error_set => blk: {
                ig.igText("%s: error.%s", label, @errorName(value.*).ptr);
                break :blk false;
            },
            .@"fn" => function(label, value),
            else => false,
        };
    }

    fn widget(label: [*:0]const u8, value: anytype) bool {
        const w = &@field(value, "widget");
        ig.igSetNextWindowPos(.{ .x = w.x, .y = w.y }, ig.ImGuiCond_Always);
        ig.igSetNextWindowSize(.{ .x = w.w, .y = w.h }, ig.ImGuiCond_Always);
        _ = ig.igBegin(label, null, ig.ImGuiWindowFlags_NoResize | ig.ImGuiWindowFlags_NoMove | ig.ImGuiWindowFlags_NoCollapse);
        defer ig.igEnd();

        var changed = false;
        inline for (@typeInfo(@TypeOf(value.*)).@"struct".fields) |f| {
            if (!std.mem.eql(u8, f.name, "widget")) {
                ig.igPushID(f.name.ptr);
                defer ig.igPopID();
                const fl = f.name ++ "\x00";
                if (any(@ptrCast(fl.ptr), &@field(value, f.name))) changed = true;
            }
        }
        return changed;
    }

    fn tree(label: [*:0]const u8, value: anytype) bool {
        ig.igPushID(label);
        defer ig.igPopID();
        if (!ig.igTreeNode(label)) return false;
        defer ig.igTreePop();

        var changed = false;
        inline for (@typeInfo(@TypeOf(value.*)).@"struct".fields) |f| {
            const fl = f.name ++ "\x00";
            ig.igPushID(f.name.ptr);
            defer ig.igPopID();
            if (any(@ptrCast(fl.ptr), &@field(value, f.name))) changed = true;
        }
        return changed;
    }

    fn sequence(label: [*:0]const u8, len: usize, value: anytype, item: anytype) bool {
        ig.igPushID(label);
        defer ig.igPopID();
        if (!ig.igTreeNode(label)) return false;
        defer ig.igTreePop();

        var changed = false;
        for (0..len) |i| {
            var buf: [64]u8 = undefined;
            const el = std.fmt.bufPrintZ(&buf, "[{d}]", .{i}) catch "[?]";
            ig.igPushID(el.ptr);
            defer ig.igPopID();
            if (any(el.ptr, item(value, i))) changed = true;
        }
        return changed;
    }

    fn optional(label: [*:0]const u8, value: anytype) bool {
        const child = @typeInfo(@TypeOf(value.*)).optional.child;
        var has = value.* != null;
        var buf: [128]u8 = undefined;
        const chk = std.fmt.bufPrintZ(&buf, "##has_{s}", .{label}) catch "##has";

        var changed = ig.igCheckbox(chk.ptr, &has);
        if (changed) {
            value.* = if (has and value.* == null)
                (if (@sizeOf(child) > 0) std.mem.zeroes(child) else {})
            else
                null;
        }

        ig.igSameLine();
        if (value.*) |*inner| {
            if (any(label, inner)) changed = true;
        } else ig.igTextDisabled("%s: null", label);
        return changed;
    }

    fn vector(label: [*:0]const u8, value: anytype, info: anytype) bool {
        if (info.child == f32) return switch (info.len) {
            2 => ig.igInputFloat2(label, @ptrCast(value)),
            3 => ig.igInputFloat3(label, @ptrCast(value)),
            4 => ig.igInputFloat4(label, @ptrCast(value)),
            else => vector_tree(label, value, info),
        };
        if (info.child == i32) return switch (info.len) {
            2 => ig.igInputInt2(label, @ptrCast(value)),
            3 => ig.igInputInt3(label, @ptrCast(value)),
            4 => ig.igInputInt4(label, @ptrCast(value)),
            else => vector_tree(label, value, info),
        };
        ig.igText("%s: vector<%d>", label, @as(c_int, @intCast(info.len)));
        return false;
    }

    fn vector_tree(label: [*:0]const u8, value: anytype, info: anytype) bool {
        ig.igPushID(label);
        defer ig.igPopID();
        if (!ig.igTreeNode(label)) return false;
        defer ig.igTreePop();

        var changed = false;
        inline for (0..info.len) |i| {
            var buf: [64]u8 = undefined;
            const el = std.fmt.bufPrintZ(&buf, "[{d}]", .{i}) catch "[?]";
            var v = value.*[i];
            if (any(el.ptr, &v)) {
                value.*[i] = v;
                changed = true;
            }
        }
        return changed;
    }

    fn tagged(label: [*:0]const u8, value: anytype) bool {
        const T = @TypeOf(value.*);
        var changed = menu.combo(label, T, value, comptime std.meta.fields(T));

        ig.igPushID(label);
        defer ig.igPopID();
        inline for (comptime std.meta.fields(T)) |f| {
            if (std.mem.eql(u8, @tagName(value.*), f.name) and @sizeOf(f.type) > 0) {
                const fl = f.name ++ "\x00";
                if (any(@ptrCast(fl.ptr), &@field(value.*, f.name))) changed = true;
            }
        }
        return changed;
    }

    fn error_union(label: [*:0]const u8, value: anytype) bool {
        if (value.*) |*payload| {
            return any(label, payload);
        } else |err| {
            ig.igTextColored(.{ .x = 1, .y = 0.4, .z = 0.4, .w = 1 }, "%s: error.%s", label, @errorName(err).ptr);
            return false;
        }
    }

    fn deref(label: [*:0]const u8, value: anytype) bool {
        ig.igPushID(label);
        defer ig.igPopID();
        if (!ig.igTreeNode(label)) return false;
        defer ig.igTreePop();
        return any("*", value.*);
    }

    fn function(label: [*:0]const u8, value: anytype) bool {
        const fn_info = @typeInfo(@typeInfo(@TypeOf(value.*)).pointer.child).@"fn";
        if (fn_info.params.len > 0) {
            var buf: [256]u8 = undefined;
            const sig = std.fmt.bufPrintZ(&buf, "{s} (fn/{d})", .{ label, fn_info.params.len }) catch label;
            ig.igTextDisabled("%s", sig.ptr);
            return false;
        }
        if (!ig.igButton(label)) return false;
        if (fn_info.return_type != null) _ = value.*() else value.*();
        return true;
    }

    const primitive = struct {
        fn int(label: [*:0]const u8, value: anytype) bool {
            const info = @typeInfo(@TypeOf(value.*)).int;
            if (info.bits == 32 and info.signedness == .signed) return ig.igInputInt(label, @ptrCast(value));
            var temp: i32 = @intCast(value.*);
            if (ig.igInputInt(label, &temp)) {
                value.* = @intCast(temp);
                return true;
            }
            return false;
        }

        fn float(label: [*:0]const u8, value: anytype) bool {
            if (@typeInfo(@TypeOf(value.*)).float.bits == 32) return ig.igInputFloat(label, @ptrCast(value));
            var temp: f32 = @floatCast(value.*);
            if (ig.igInputFloat(label, &temp)) {
                value.* = @floatCast(temp);
                return true;
            }
            return false;
        }
    };

    const menu = struct {
        fn combo(label: [*:0]const u8, comptime T: type, value: *T, comptime fields: anytype) bool {
            const current = @tagName(value.*);
            if (!ig.igBeginCombo(label, current.ptr, ig.ImGuiComboFlags_None)) return false;
            defer ig.igEndCombo();

            var changed = false;
            inline for (fields) |f| {
                if (ig.igSelectable(f.name.ptr)) {
                    value.* = if (@typeInfo(T) == .@"union")
                        @unionInit(T, f.name, if (@sizeOf(f.type) > 0) std.mem.zeroes(f.type) else {})
                    else
                        @field(T, f.name);
                    changed = true;
                }
                if (std.mem.eql(u8, current, f.name)) ig.igSetItemDefaultFocus();
            }
            return changed;
        }
    };
};

pub fn reflect(label: [*:0]const u8, value: anytype) Response {
    var r = Response{};
    r.changed = draw.any(label, value);
    if (ig.igIsItemHovered(ig.ImGuiHoveredFlags_None)) r.hovered = true;
    if (ig.igIsItemActive()) r.active = true;
    return r;
}

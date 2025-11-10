const std = @import("std");
const ig = @import("cimgui");

pub const Response = struct {
    changed: bool = false,
    hovered: bool = false,
    active: bool = false,
};

const render = struct {
    fn any(label: [*:0]const u8, value: anytype, r: *Response) void {
        const T = @TypeOf(value.*);
        switch (@typeInfo(T)) {
            .int => r.changed = ig.igInputInt(label, @ptrCast(value)),
            .float => r.changed = ig.igInputFloat(label, @ptrCast(value)),
            .bool => r.changed = ig.igCheckbox(label, value),
            .@"enum" => @"enum"(label, value, r),
            .@"struct" => @"struct"(label, value, r),
            .array => |arr| if (arr.child == u8) string(label, value, r) else array(label, value, r),
            .optional => optional(label, value, r),
            else => ig.igText("unsupported"),
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

    fn @"struct"(label: [*:0]const u8, value: anytype, r: *Response) void {
        ig.igPushID(label);
        defer ig.igPopID();
        if (ig.igTreeNode(label)) {
            defer ig.igTreePop();
            inline for (comptime @typeInfo(@TypeOf(value.*)).@"struct".fields) |field| {
                const field_label = field.name ++ "\x00";
                ig.igPushID(field.name.ptr);
                var fr = Response{};
                any(@ptrCast(field_label.ptr), &@field(value, field.name), &fr);
                if (fr.changed) r.changed = true;
                ig.igPopID();
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
};

pub fn widget(label: [*:0]const u8, value: anytype) Response {
    var r = Response{};
    render.any(label, value, &r);
    if (ig.igIsItemHovered(ig.ImGuiHoveredFlags_None)) r.hovered = true;
    if (ig.igIsItemActive()) r.active = true;
    return r;
}

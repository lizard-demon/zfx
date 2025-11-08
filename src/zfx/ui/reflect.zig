// Automatic ImGui widgets via compile-time reflection
const std = @import("std");
const ig = @import("cimgui");

pub const Response = struct {
    changed: bool = false,
    hovered: bool = false,
    active: bool = false,

    fn check(self: *Response) void {
        if (ig.igIsItemHovered(ig.ImGuiHoveredFlags_None)) self.hovered = true;
        if (ig.igIsItemActive()) self.active = true;
    }
};

pub fn input(label: [*:0]const u8, value: anytype) Response {
    var r = Response{};
    Render.widget(label, value, &r);
    return r;
}

const Render = struct {
    fn widget(label: [*:0]const u8, value: anytype, r: *Response) void {
        const T = @TypeOf(value.*);
        switch (@typeInfo(T)) {
            .int => r.changed = ig.igInputInt(label, @ptrCast(value)),
            .float => r.changed = ig.igInputFloat(label, @ptrCast(value)),
            .bool => r.changed = ig.igCheckbox(label, value),
            .@"enum" => _enum(label, value, r),
            .@"struct" => _struct(label, value, r),
            .array => |arr| if (arr.child == u8) _string(label, value, r) else _array(label, value, r),
            .optional => _optional(label, value, r),
            else => ig.igText("unsupported"),
        }
        r.check();
    }

    fn _enum(label: [*:0]const u8, value: anytype, r: *Response) void {
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

    fn _struct(label: [*:0]const u8, value: anytype, r: *Response) void {
        ig.igPushID(label);
        defer ig.igPopID();
        if (ig.igTreeNode(label)) {
            defer ig.igTreePop();
            inline for (comptime @typeInfo(@TypeOf(value.*)).@"struct".fields) |field| {
                const field_label = field.name ++ "\x00";
                ig.igPushID(field.name.ptr);
                var fr = Response{};
                widget(@ptrCast(field_label.ptr), &@field(value, field.name), &fr);
                if (fr.changed) r.changed = true;
                ig.igPopID();
            }
        }
    }

    fn _array(label: [*:0]const u8, value: anytype, r: *Response) void {
        ig.igPushID(label);
        defer ig.igPopID();
        if (ig.igTreeNode(label)) {
            defer ig.igTreePop();
            for (value, 0..) |*item, i| {
                var buf: [64]u8 = undefined;
                const elem_label = std.fmt.bufPrintZ(&buf, "[{d}]", .{i}) catch "[?]";
                ig.igPushID(elem_label.ptr);
                var er = Response{};
                widget(elem_label.ptr, item, &er);
                if (er.changed) r.changed = true;
                ig.igPopID();
            }
        }
    }

    fn _string(label: [*:0]const u8, value: anytype, r: *Response) void {
        if (ig.igInputText(label, @ptrCast(value), value.len, ig.ImGuiInputTextFlags_None)) r.changed = true;
    }

    fn _optional(label: [*:0]const u8, value: anytype, r: *Response) void {
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
            widget(label, inner, &ir);
            if (ir.changed) r.changed = true;
        } else ig.igTextDisabled("%s: null", label);
    }
};

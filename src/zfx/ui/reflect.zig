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
            ig.igText("%s: vector<%d>", label, info.len);
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

        // Check if function can be called (no params)
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

pub fn widget(label: [*:0]const u8, value: anytype) Response {
    var r = Response{};
    render.any(label, value, &r);
    if (ig.igIsItemHovered(ig.ImGuiHoveredFlags_None)) r.hovered = true;
    if (ig.igIsItemActive()) r.active = true;
    return r;
}

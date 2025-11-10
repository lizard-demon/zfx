const std = @import("std");
const ig = @import("cimgui");
const L = @import("ui/layout.zig");

// Re-export layout types
pub const Widget = L.Widget;
pub const Dir = L.Dir;
pub const Align = L.Align;
pub const layout = L.layout;

pub const Response = struct {
    changed: bool = false,
    hovered: bool = false,
    active: bool = false,
};

// Render - pure reflection-based rendering
fn renderAny(label: [*:0]const u8, value: anytype, r: *Response) void {
    const T = @TypeOf(value.*);
    switch (@typeInfo(T)) {
        .int => |info| {
            if (info.bits == 32 and info.signedness == .signed) {
                r.changed = ig.igInputInt(label, @ptrCast(value));
            } else {
                var temp: i32 = @intCast(value.*);
                if (ig.igInputInt(label, &temp)) {
                    value.* = @intCast(temp);
                    r.changed = true;
                }
            }
        },
        .float => |info| {
            if (info.bits == 32) {
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
        .@"enum" => renderEnum(label, value, r),
        .@"struct" => renderStruct(label, value, r),
        .array => |arr| if (arr.child == u8) {
            if (ig.igInputText(label, @ptrCast(value), value.len, ig.ImGuiInputTextFlags_None))
                r.changed = true;
        } else renderArray(label, value, r),
        .optional => renderOptional(label, value, r),
        .pointer => |ptr| {
            if (ptr.size == .slice) {
                const child = ptr.child;
                if (child == u8) {
                    ig.igText("%s: \"%s\"", label, value.*.ptr);
                } else renderSlice(label, value, r);
            } else if (@typeInfo(ptr.child) == .@"fn") {
                renderFunction(label, value, r);
            } else {
                ig.igPushID(label);
                defer ig.igPopID();
                if (ig.igTreeNode(label)) {
                    defer ig.igTreePop();
                    var pr = Response{};
                    renderAny("*", value.*, &pr);
                    if (pr.changed) r.changed = true;
                }
            }
        },
        .vector => renderVector(label, value, r),
        .@"union" => renderUnion(label, value, r),
        .error_union => {
            if (value.*) |*payload| {
                var pr = Response{};
                renderAny(label, payload, &pr);
                if (pr.changed) r.changed = true;
            } else |err| {
                ig.igTextColored(.{ .x = 1, .y = 0.4, .z = 0.4, .w = 1 }, "%s: error.%s", label, @errorName(err).ptr);
            }
        },
        .error_set => ig.igText("%s: error.%s", label, @errorName(value.*).ptr),
        .@"fn" => renderFunction(label, value, r),
        else => ig.igText("unsupported"),
    }
}

fn renderEnum(label: [*:0]const u8, value: anytype, r: *Response) void {
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

fn renderStruct(label: [*:0]const u8, value: anytype, r: *Response) void {
    const T = @TypeOf(value.*);
    const fields = @typeInfo(T).@"struct".fields;

    // Check for Widget field
    const has_widget = comptime blk: {
        for (fields) |field| {
            if (std.mem.eql(u8, field.name, "widget") and field.type == Widget) {
                break :blk true;
            }
        }
        break :blk false;
    };

    if (has_widget) {
        const w = &@field(value, "widget");

        // Render as window
        ig.igSetNextWindowPos(.{ .x = w.x, .y = w.y }, ig.ImGuiCond_Always);
        ig.igSetNextWindowSize(.{ .x = w.w, .y = w.h }, ig.ImGuiCond_Always);
        _ = ig.igBegin(label, null, ig.ImGuiWindowFlags_NoResize | ig.ImGuiWindowFlags_NoMove | ig.ImGuiWindowFlags_NoCollapse);

        inline for (fields) |field| {
            if (!std.mem.eql(u8, field.name, "widget")) {
                const field_label = field.name ++ "\x00";
                ig.igPushID(field.name.ptr);
                var fr = Response{};
                renderAny(@ptrCast(field_label.ptr), &@field(value, field.name), &fr);
                if (fr.changed) r.changed = true;
                ig.igPopID();
            }
        }

        ig.igEnd();
    } else {
        // Tree node
        ig.igPushID(label);
        defer ig.igPopID();
        if (ig.igTreeNode(label)) {
            defer ig.igTreePop();
            inline for (fields) |field| {
                const field_label = field.name ++ "\x00";
                ig.igPushID(field.name.ptr);
                var fr = Response{};
                renderAny(@ptrCast(field_label.ptr), &@field(value, field.name), &fr);
                if (fr.changed) r.changed = true;
                ig.igPopID();
            }
        }
    }
}

fn renderArray(label: [*:0]const u8, value: anytype, r: *Response) void {
    ig.igPushID(label);
    defer ig.igPopID();
    if (ig.igTreeNode(label)) {
        defer ig.igTreePop();
        for (value, 0..) |*item, i| {
            var buf: [64]u8 = undefined;
            const elem_label = std.fmt.bufPrintZ(&buf, "[{d}]", .{i}) catch "[?]";
            ig.igPushID(elem_label.ptr);
            var er = Response{};
            renderAny(elem_label.ptr, item, &er);
            if (er.changed) r.changed = true;
            ig.igPopID();
        }
    }
}

fn renderSlice(label: [*:0]const u8, value: anytype, r: *Response) void {
    ig.igPushID(label);
    defer ig.igPopID();
    if (ig.igTreeNode(label)) {
        defer ig.igTreePop();
        for (value.*, 0..) |*item, i| {
            var buf: [64]u8 = undefined;
            const elem_label = std.fmt.bufPrintZ(&buf, "[{d}]", .{i}) catch "[?]";
            ig.igPushID(elem_label.ptr);
            var er = Response{};
            renderAny(elem_label.ptr, item, &er);
            if (er.changed) r.changed = true;
            ig.igPopID();
        }
    }
}

fn renderOptional(label: [*:0]const u8, value: anytype, r: *Response) void {
    const T = @TypeOf(value.*);
    const child = @typeInfo(T).optional.child;
    var has = value.* != null;
    var buf: [128]u8 = undefined;
    const check = std.fmt.bufPrintZ(&buf, "##has_{s}", .{label}) catch "##has";
    if (ig.igCheckbox(check.ptr, &has)) {
        value.* = if (has and value.* == null)
            (if (@sizeOf(child) > 0) std.mem.zeroes(child) else {})
        else
            null;
        r.changed = true;
    }
    ig.igSameLine();
    if (value.*) |*inner| {
        var ir = Response{};
        renderAny(label, inner, &ir);
        if (ir.changed) r.changed = true;
    } else ig.igTextDisabled("%s: null", label);
}

fn renderVector(label: [*:0]const u8, value: anytype, r: *Response) void {
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

fn renderUnion(label: [*:0]const u8, value: anytype, r: *Response) void {
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
                renderAny(@ptrCast(field_label.ptr), &@field(value.*, field.name), &fr);
                if (fr.changed) r.changed = true;
            }
        }
    } else {
        ig.igText("%s: untagged union", label);
    }
}

fn renderFunction(label: [*:0]const u8, value: anytype, r: *Response) void {
    const T = @TypeOf(value.*);
    const ptr_info = @typeInfo(T).pointer;
    const fn_info = @typeInfo(ptr_info.child).@"fn";

    if (fn_info.params.len == 0) {
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
        const sig = std.fmt.bufPrintZ(&buf, "{s} (fn/{d})", .{ label, fn_info.params.len }) catch label;
        ig.igTextDisabled("%s", sig.ptr);
    }
}

// Public API - minimal surface
pub fn render(label: [*:0]const u8, value: anytype) Response {
    var r = Response{};
    renderAny(label, value, &r);
    if (ig.igIsItemHovered(ig.ImGuiHoveredFlags_None)) r.hovered = true;
    if (ig.igIsItemActive()) r.active = true;
    return r;
}

// zfx theme editor demo
const std = @import("std");
const zfx = @import("zfx");
const ig = zfx.imgui;
const theme = @import("theme.zig");

const Widget = struct {
    pos: @Vector(2, f32) = @splat(0),
    size: @Vector(2, f32) = @splat(0),
    min: @Vector(2, f32) = @splat(0),
    sz: [2]zfx.ui.layout.SizeSpec = .{ .{}, .{} },
    pad: @Vector(4, u16) = @splat(0),
    gap: u16 = 0,
    dir: zfx.ui.layout.Dir = .h,
    al: [2]zfx.ui.layout.Align = .{ .start, .start },
    kids: []*Widget = &[_]*Widget{},
};

var pass_action: zfx.sokol.gfx.PassAction = .{};
var current_theme: theme.Theme = .{};

var root: Widget = undefined;
var left: Widget = undefined;
var right: Widget = undefined;
var kids: [2]*Widget = undefined;
var last_width: i32 = 0;
var last_height: i32 = 0;

export fn init() void {
    zfx.sokol.gfx.setup(.{ .environment = zfx.sokol.glue.environment() });
    zfx.sokol.imgui.setup(.{});
    theme.apply(&current_theme);
}

export fn frame() void {
    const w: f32 = @floatFromInt(zfx.sokol.app.width());
    const h: f32 = @floatFromInt(zfx.sokol.app.height());
    const curr_width = zfx.sokol.app.width();
    const curr_height = zfx.sokol.app.height();

    // Recompute layout when window size changes
    if (last_width != curr_width or last_height != curr_height) {
        left = .{ .size = .{ w / 2, h }, .sz = .{ .{ .t = .grow }, .{ .t = .grow } } };
        right = .{ .size = .{ w / 2, h }, .sz = .{ .{ .t = .grow }, .{ .t = .grow } } };
        kids = [_]*Widget{ &left, &right };
        root = .{ .size = .{ w, h }, .sz = .{ .{ .t = .fixed, .mn = w, .mx = w }, .{ .t = .fixed, .mn = h, .mx = h } }, .dir = .h, .kids = &kids };
        zfx.ui.layout.Layout(Widget).calc(&root);
        last_width = curr_width;
        last_height = curr_height;
    }

    zfx.sokol.imgui.newFrame(.{ .width = zfx.sokol.app.width(), .height = zfx.sokol.app.height(), .delta_time = zfx.sokol.app.frameDuration() });

    // Style editor window (left panel, positioned by layout)
    ig.igSetNextWindowPos(.{ .x = left.pos[0], .y = left.pos[1] }, ig.ImGuiCond_Always);
    ig.igSetNextWindowSize(.{ .x = left.size[0], .y = left.size[1] }, ig.ImGuiCond_Always);
    _ = ig.igBegin("Style", null, ig.ImGuiWindowFlags_NoResize | ig.ImGuiWindowFlags_NoMove | ig.ImGuiWindowFlags_NoCollapse | ig.ImGuiWindowFlags_NoBringToFrontOnFocus);
    inline for (comptime std.meta.fields(@TypeOf(current_theme.style))) |field| {
        const field_label = field.name ++ "\x00";
        _ = zfx.ui.reflect.input(@ptrCast(field_label.ptr), &@field(current_theme.style, field.name));
    }
    ig.igEnd();

    // Colors editor window (right panel, positioned by layout)
    ig.igSetNextWindowPos(.{ .x = right.pos[0], .y = right.pos[1] }, ig.ImGuiCond_Always);
    ig.igSetNextWindowSize(.{ .x = right.size[0], .y = right.size[1] }, ig.ImGuiCond_Always);
    _ = ig.igBegin("Colors", null, ig.ImGuiWindowFlags_NoResize | ig.ImGuiWindowFlags_NoMove | ig.ImGuiWindowFlags_NoCollapse | ig.ImGuiWindowFlags_NoBringToFrontOnFocus);
    inline for (comptime std.meta.fields(@TypeOf(current_theme.colors))) |field| {
        const field_label = field.name ++ "\x00";
        _ = zfx.ui.reflect.input(@ptrCast(field_label.ptr), &@field(current_theme.colors, field.name));
    }
    ig.igEnd();

    // Apply button window (floating top right, always on top)
    ig.igSetNextWindowPos(.{ .x = w - 140, .y = 20 }, ig.ImGuiCond_Always);
    const button_open = ig.igBegin("##apply", null, ig.ImGuiWindowFlags_NoTitleBar | ig.ImGuiWindowFlags_NoResize | ig.ImGuiWindowFlags_NoMove | ig.ImGuiWindowFlags_NoScrollbar | ig.ImGuiWindowFlags_NoSavedSettings | ig.ImGuiWindowFlags_AlwaysAutoResize | ig.ImGuiWindowFlags_NoBringToFrontOnFocus);
    if (button_open) {
        ig.igBringWindowToDisplayFront(ig.igGetCurrentWindow());
        if (ig.igButton("Apply Theme")) {
            theme.apply(&current_theme);
        }
    }
    ig.igEnd();

    zfx.sokol.gfx.beginPass(.{ .action = pass_action, .swapchain = zfx.sokol.glue.swapchain() });
    zfx.sokol.imgui.render();
    zfx.sokol.gfx.endPass();
    zfx.sokol.gfx.commit();
}

export fn cleanup() void {
    zfx.sokol.imgui.shutdown();
    zfx.sokol.gfx.shutdown();
}

export fn event(ev: [*c]const zfx.sokol.app.Event) void {
    _ = zfx.sokol.imgui.handleEvent(ev.*);
}

pub fn main() void {
    zfx.sokol.app.run(.{
        .init_cb = init,
        .frame_cb = frame,
        .cleanup_cb = cleanup,
        .event_cb = event,
        .width = 1000,
        .height = 800,
        .window_title = "zfx theme editor",
    });
}

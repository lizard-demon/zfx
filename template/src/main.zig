const std = @import("std");
const zfx = @import("zfx");
const ig = zfx.imgui;
const theme = @import("theme.zig");
const demo = @import("demo.zig");

const Widget = zfx.ui.Widget;

var pass_action: zfx.sokol.gfx.PassAction = .{};
var current_theme: theme.Theme = .{};
var demo_data: demo.Demo = .{};

var root: Widget = undefined;
var left: Widget = undefined;
var middle: Widget = undefined;
var right: Widget = undefined;
var children: [3]*Widget = undefined;
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
        left = .{ .size = .{ w / 3, h }, .sz = .{ .{ .mode = .grow }, .{ .mode = .grow } } };
        middle = .{ .size = .{ w / 3, h }, .sz = .{ .{ .mode = .grow }, .{ .mode = .grow } } };
        right = .{ .size = .{ w / 3, h }, .sz = .{ .{ .mode = .grow }, .{ .mode = .grow } } };
        children = [_]*Widget{ &left, &middle, &right };
        root = .{ .size = .{ w, h }, .sz = .{ .{ .mode = .fixed, .min = w, .max = w }, .{ .mode = .fixed, .min = h, .max = h } }, .dir = .h, .children = &children };
        zfx.ui.layout(&root);
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
        const r = zfx.reflect.widget(@ptrCast(field_label.ptr), &@field(current_theme.style, field.name));
        if (r.changed) theme.apply(&current_theme);
    }
    ig.igEnd();

    // Type demo window (middle panel, positioned by layout)
    ig.igSetNextWindowPos(.{ .x = middle.pos[0], .y = middle.pos[1] }, ig.ImGuiCond_Always);
    ig.igSetNextWindowSize(.{ .x = middle.size[0], .y = middle.size[1] }, ig.ImGuiCond_Always);
    _ = ig.igBegin("Type Demo", null, ig.ImGuiWindowFlags_NoResize | ig.ImGuiWindowFlags_NoMove | ig.ImGuiWindowFlags_NoCollapse | ig.ImGuiWindowFlags_NoBringToFrontOnFocus);
    _ = zfx.reflect.widget("demo", &demo_data);
    ig.igEnd();

    // Colors editor window (right panel, positioned by layout)
    ig.igSetNextWindowPos(.{ .x = right.pos[0], .y = right.pos[1] }, ig.ImGuiCond_Always);
    ig.igSetNextWindowSize(.{ .x = right.size[0], .y = right.size[1] }, ig.ImGuiCond_Always);
    _ = ig.igBegin("Colors", null, ig.ImGuiWindowFlags_NoResize | ig.ImGuiWindowFlags_NoMove | ig.ImGuiWindowFlags_NoCollapse | ig.ImGuiWindowFlags_NoBringToFrontOnFocus);
    inline for (comptime std.meta.fields(@TypeOf(current_theme.colors))) |field| {
        const field_label = field.name ++ "\x00";
        const r = zfx.reflect.widget(@ptrCast(field_label.ptr), &@field(current_theme.colors, field.name));
        if (r.changed) theme.apply(&current_theme);
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
        .width = 1400,
        .height = 800,
        .window_title = "zfx demo",
    });
}

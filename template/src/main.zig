const std = @import("std");
const zfx = @import("zfx");
const theme = @import("theme.zig");

const Widget = zfx.ui.Widget;

const StylePanel = struct {
    self: Widget = .{},
    theme: theme.Theme = .{},
};

const ColorPanel = struct {
    self: Widget = .{},
    theme: theme.Theme = .{},
};

const App = struct {
    self: Widget = .{},
    style: StylePanel = .{},
    colors: ColorPanel = .{},
};

var pass_action: zfx.sokol.gfx.PassAction = .{};
var app: App = .{};

var last_width: i32 = 0;
var last_height: i32 = 0;

export fn init() void {
    zfx.sokol.gfx.setup(.{ .environment = zfx.sokol.glue.environment() });
    zfx.sokol.imgui.setup(.{});
    theme.apply(&app.style.theme);
}

export fn frame() void {
    const w: f32 = @floatFromInt(zfx.sokol.app.width());
    const h: f32 = @floatFromInt(zfx.sokol.app.height());
    const curr_width = zfx.sokol.app.width();
    const curr_height = zfx.sokol.app.height();

    // Recompute layout when window size changes
    if (last_width != curr_width or last_height != curr_height) {
        // Set up child widgets
        app.style.self = .{ .size = .{ w / 2, h }, .sz = .{ .{ .mode = .grow }, .{ .mode = .grow } } };
        app.colors.self = .{ .size = .{ w / 2, h }, .sz = .{ .{ .mode = .grow }, .{ .mode = .grow } } };

        // Set up root widget with children
        var children = [_]*Widget{ &app.style.self, &app.colors.self };
        app.self = .{
            .size = .{ w, h },
            .sz = .{ .{ .mode = .fixed, .min = w, .max = w }, .{ .mode = .fixed, .min = h, .max = h } },
            .dir = .h,
            .children = &children,
        };

        // Compute layout
        zfx.ui.layout(&app.self);

        last_width = curr_width;
        last_height = curr_height;
    }

    zfx.sokol.imgui.newFrame(.{ .width = zfx.sokol.app.width(), .height = zfx.sokol.app.height(), .delta_time = zfx.sokol.app.frameDuration() });

    // Render entire app with reflection - it handles all windowing
    const response = zfx.reflect.widget("App", &app);
    if (response.changed) {
        theme.apply(&app.style.theme);
    }

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

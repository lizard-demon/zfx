const std = @import("std");
const zfx = @import("zfx");
const theme = @import("theme.zig");

const Widget = zfx.ui.Widget;

const StylePanel = struct {
    self: Widget = .{ .w = zfx.ui.Size.Grow(), .h = zfx.ui.Size.Grow() },
    theme: theme.Theme = .{},

    pub fn onchange(self: *@This()) void {
        theme.apply(&self.theme);
    }
};

const ColorPanel = struct {
    self: Widget = .{ .w = zfx.ui.Size.Grow(), .h = zfx.ui.Size.Grow() },
    theme: theme.Theme = .{},

    pub fn onchange(self: *@This()) void {
        theme.apply(&self.theme);
    }
};

const App = struct {
    self: Widget = .{ .dir = .h },
    style: StylePanel = .{},
    colors: ColorPanel = .{},
};

var pass_action: zfx.sokol.gfx.PassAction = .{};
var app: App = .{};

export fn init() void {
    zfx.sokol.gfx.setup(.{ .environment = zfx.sokol.glue.environment() });
    zfx.sokol.imgui.setup(.{});
    theme.apply(&app.style.theme);
}

export fn frame() void {
    const w: f32 = @floatFromInt(zfx.sokol.app.width());
    const h: f32 = @floatFromInt(zfx.sokol.app.height());

    zfx.sokol.imgui.newFrame(.{ .width = zfx.sokol.app.width(), .height = zfx.sokol.app.height(), .delta_time = zfx.sokol.app.frameDuration() });

    // Single call handles layout + rendering
    _ = zfx.ui.ui_render("App", &app, .{ .w = w, .h = h });

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

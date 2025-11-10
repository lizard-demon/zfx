const std = @import("std");
const zfx = @import("zfx");
const theme = @import("theme.zig");
const demo = @import("demo.zig");

const Widget = zfx.ui.Widget;

const GUI = struct {
    widget: Widget = .{ .dir = .h },
    style: struct {
        widget: Widget = .{ .sw = -1, .sh = -1 },
        style: theme.StyleVars = .{},
    } = .{},
    colors: struct {
        widget: Widget = .{ .sw = -1, .sh = -1 },
        colors: theme.Colors = .{},
    } = .{},
    demo: struct {
        widget: Widget = .{ .sw = -1, .sh = -1 },
        demo: demo.Demo = .{},
    } = .{},

    fn apply(self: *const GUI) void {
        const t = theme.Theme{
            .style = self.style.style,
            .colors = self.colors.colors,
        };
        theme.apply(&t);
    }
};

var pass_action: zfx.sokol.gfx.PassAction = .{};
var app: GUI = .{};

export fn init() void {
    zfx.sokol.gfx.setup(.{ .environment = zfx.sokol.glue.environment() });
    zfx.sokol.imgui.setup(.{});
    app.apply();
}

export fn frame() void {
    const w: f32 = @floatFromInt(zfx.sokol.app.width());
    const h: f32 = @floatFromInt(zfx.sokol.app.height());

    zfx.sokol.imgui.newFrame(.{ .width = zfx.sokol.app.width(), .height = zfx.sokol.app.height(), .delta_time = zfx.sokol.app.frameDuration() });

    // Set root size and layout
    app.widget.w = w;
    app.widget.h = h;
    zfx.ui.layout(&app);

    // Render
    const r = zfx.ui.reflect("App", &app);
    if (r.changed) {
        app.apply();
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

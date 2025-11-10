const std = @import("std");
const zfx = @import("zfx");
const theme = @import("theme.zig");

const Widget = zfx.ui.layout.Widget;

const StylePanel = struct {
    widget: Widget = .{ .sw = -1, .sh = -1 },
    style: theme.StyleVars = .{},
};

const ColorPanel = struct {
    widget: Widget = .{ .sw = -1, .sh = -1 },
    colors: theme.Colors = .{},
};

const App = struct {
    widget: Widget = .{ .dir = .h },
    style: StylePanel = .{},
    colors: ColorPanel = .{},
};

var pass_action: zfx.sokol.gfx.PassAction = .{};
var app: App = .{};

export fn init() void {
    zfx.sokol.gfx.setup(.{ .environment = zfx.sokol.glue.environment() });
    zfx.sokol.imgui.setup(.{});
    applyTheme();
}

fn applyTheme() void {
    const t = theme.Theme{
        .style = app.style.style,
        .colors = app.colors.colors,
    };
    theme.apply(&t);
}

export fn frame() void {
    const w: f32 = @floatFromInt(zfx.sokol.app.width());
    const h: f32 = @floatFromInt(zfx.sokol.app.height());

    zfx.sokol.imgui.newFrame(.{ .width = zfx.sokol.app.width(), .height = zfx.sokol.app.height(), .delta_time = zfx.sokol.app.frameDuration() });

    // Set root size and layout
    app.widget.w = w;
    app.widget.h = h;
    var children = [_]Widget{ app.style.widget, app.colors.widget };
    zfx.ui.layout.layout(&app.widget, &children);

    // Update child widgets with computed layout
    app.style.widget = children[0];
    app.colors.widget = children[1];

    // Render
    const r = zfx.ui.reflect.render("App", &app);
    if (r.changed) {
        applyTheme();
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

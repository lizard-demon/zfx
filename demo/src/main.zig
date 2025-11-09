// zfx theme editor demo
const std = @import("std");
const zfx = @import("zfx");
const ig = zfx.imgui;
const theme = @import("theme.zig");

var pass_action: zfx.sokol.gfx.PassAction = .{};
var current_theme: theme.Theme = .{};

export fn init() void {
    zfx.sokol.gfx.setup(.{ .environment = zfx.sokol.glue.environment() });
    zfx.sokol.imgui.setup(.{});
    theme.apply(&current_theme);
}

export fn frame() void {
    const w: f32 = @floatFromInt(zfx.sokol.app.width());
    const h: f32 = @floatFromInt(zfx.sokol.app.height());

    zfx.sokol.imgui.newFrame(.{ .width = zfx.sokol.app.width(), .height = zfx.sokol.app.height(), .delta_time = zfx.sokol.app.frameDuration() });

    // Theme editor window
    ig.igSetNextWindowPos(.{ .x = 10, .y = 10 }, ig.ImGuiCond_Always);
    ig.igSetNextWindowSize(.{ .x = w - 20, .y = h - 20 }, ig.ImGuiCond_Always);
    _ = ig.igBegin("zfx Theme Editor", null, ig.ImGuiWindowFlags_NoResize | ig.ImGuiWindowFlags_NoMove);

    ig.igText("Edit theme with live preview");
    ig.igSeparator();

    // Use zfx reflection to edit the theme
    const response = zfx.ui.reflect.input("theme", &current_theme);
    if (response.changed) {
        theme.apply(&current_theme);
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

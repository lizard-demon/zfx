// Minimal zfx demo: Layout + Reflection
const std = @import("std");
const zfx = @import("zfx");
const ig = zfx.imgui;

var pass_action: zfx.sokol.gfx.PassAction = .{};

// Demo data
var config = struct {
    count: i32 = 42,
    enabled: bool = true,
    scale: f32 = 1.5,
}{};

export fn init() void {
    zfx.sokol.gfx.setup(.{ .environment = zfx.sokol.glue.environment() });
    zfx.sokol.imgui.setup(.{});
}

export fn frame() void {
    const w: f32 = @floatFromInt(zfx.sokol.app.width());
    const h: f32 = @floatFromInt(zfx.sokol.app.height());

    zfx.sokol.imgui.newFrame(.{ .width = zfx.sokol.app.width(), .height = zfx.sokol.app.height(), .delta_time = zfx.sokol.app.frameDuration() });

    // Left panel
    ig.igSetNextWindowPos(.{ .x = 10, .y = 10 }, ig.ImGuiCond_Always);
    ig.igSetNextWindowSize(.{ .x = w / 2 - 20, .y = h - 20 }, ig.ImGuiCond_Always);
    _ = ig.igBegin("Layout Demo", null, ig.ImGuiWindowFlags_NoResize | ig.ImGuiWindowFlags_NoMove);
    ig.igText("Left panel");
    ig.igSeparator();
    ig.igText("Window: %.0fx%.0f", w, h);
    ig.igEnd();

    // Right panel
    ig.igSetNextWindowPos(.{ .x = w / 2 + 10, .y = 10 }, ig.ImGuiCond_Always);
    ig.igSetNextWindowSize(.{ .x = w / 2 - 20, .y = h - 20 }, ig.ImGuiCond_Always);
    _ = ig.igBegin("Reflection Demo", null, ig.ImGuiWindowFlags_NoResize | ig.ImGuiWindowFlags_NoMove);
    ig.igText("Right panel");
    ig.igSeparator();
    _ = zfx.ui.reflect.input("config", &config);
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
        .width = 800,
        .height = 600,
        .window_title = "zfx demo",
    });
}

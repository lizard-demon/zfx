// Minimal zfx demo: Layout + Reflection
const std = @import("std");
const zfx = @import("zfx");
const ig = zfx.imgui;

// Widget type for layout system
const Widget = struct {
    box: zfx.ui.layout.Box = .{},
    sz: [2]struct { t: zfx.ui.layout.Sizing = .fit, v: f32 = 0, mn: f32 = 0, mx: f32 = 3.4e38 } = .{ .{}, .{} },
    pad: [4]u16 = .{ 0, 0, 0, 0 },
    gap: u16 = 0,
    dir: zfx.ui.layout.Dir = .h,
    kids: []*Widget = &[_]*Widget{},
    min: @Vector(2, f32) = @splat(0),
    al: [2]zfx.ui.layout.Align = .{ .start, .start },
};

var gpa = std.heap.GeneralPurposeAllocator(.{}){};
var pass_action: zfx.sokol.gfx.PassAction = .{};

// Layout state
var root: Widget = undefined;
var left: Widget = undefined;
var right: Widget = undefined;
var kids: [2]*Widget = undefined;

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

    // Layout: 50/50 split panels
    left = .{ .box = .{ .w = w / 2, .h = h }, .sz = .{ .{ .t = .grow }, .{ .t = .grow } }, .pad = .{ 10, 10, 10, 10 } };
    right = .{ .box = .{ .w = w / 2, .h = h }, .sz = .{ .{ .t = .grow }, .{ .t = .grow } }, .pad = .{ 10, 10, 10, 10 } };
    kids = [_]*Widget{ &left, &right };
    root = .{ .box = .{ .w = w, .h = h }, .sz = .{ .{ .t = .fixed, .mn = w, .mx = w }, .{ .t = .fixed, .mn = h, .mx = h } }, .dir = .h, .gap = 10, .pad = .{ 10, 10, 10, 10 }, .kids = &kids };
    zfx.ui.layout.Layout(Widget).calc(gpa.allocator(), &root) catch {};

    zfx.sokol.imgui.newFrame(.{ .width = zfx.sokol.app.width(), .height = zfx.sokol.app.height(), .delta_time = zfx.sokol.app.frameDuration() });

    // Fullscreen invisible window
    ig.igSetNextWindowPos(.{ .x = 0, .y = 0 }, ig.ImGuiCond_Always);
    ig.igSetNextWindowSize(.{ .x = w, .y = h }, ig.ImGuiCond_Always);
    _ = ig.igBegin("##main", null, ig.ImGuiWindowFlags_NoTitleBar | ig.ImGuiWindowFlags_NoResize | ig.ImGuiWindowFlags_NoMove | ig.ImGuiWindowFlags_NoBackground);

    // Left panel - Layout demo
    ig.igSetCursorPos(.{ .x = left.box.x, .y = left.box.y });
    _ = ig.igBeginChild("##left", .{ .x = left.box.w, .y = left.box.h }, 0, 0);
    ig.igText("Layout Demo");
    ig.igSeparator();
    ig.igText("Size: %.0fx%.0f", left.box.w, left.box.h);
    ig.igEndChild();

    // Right panel - Reflection demo
    ig.igSetCursorPos(.{ .x = right.box.x, .y = right.box.y });
    _ = ig.igBeginChild("##right", .{ .x = right.box.w, .y = right.box.h }, 0, 0);
    ig.igText("Reflection Demo");
    ig.igSeparator();
    _ = zfx.ui.reflect.input("config", &config);
    ig.igEndChild();

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

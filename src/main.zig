// UI Module Demo - Layout + Reflection
const std = @import("std");
const zfx = @import("zfx");
const ui = zfx.ui;
const sokol = zfx.sokol;
const sg = sokol.gfx;
const sapp = sokol.app;
const simgui = sokol.imgui;
const ig = zfx.imgui;
const theme = @import("theme.zig");

// Types
const Widget = struct {
    box: ui.layout.Box = .{},
    min: @Vector(2, f32) = @splat(0),
    sz: [2]struct { t: ui.layout.Sizing = .fit, v: f32 = 0, mn: f32 = 0, mx: f32 = 3.4e38 } = .{ .{}, .{} },
    pad: [4]u16 = .{ 0, 0, 0, 0 },
    gap: u16 = 0,
    dir: ui.layout.Dir = .h,
    al: [2]ui.layout.Align = .{ .start, .start },
    kids: []*Widget = &[_]*Widget{},
};

const Quality = enum { low, medium, high, ultra };
const Vec3 = struct { x: f32 = 0, y: f32 = 0, z: f32 = 0 };
const Player = struct { name: [32]u8 = [_]u8{0} ** 32, pos: Vec3 = .{}, health: i32 = 100 };

// State
var state = struct {
    root: Widget = undefined,
    info: Widget = undefined,
    demo: Widget = undefined,
    theme_editor: Widget = undefined,
    kids: [3]*Widget = undefined,
    computed: bool = false,
    last_w: i32 = 0,
    player: Player = .{},
    vec: Vec3 = .{ .x = 1, .y = 2, .z = 3 },
    quality: Quality = .high,
    int: i32 = 42,
    float: f32 = 3.14,
    bool: bool = true,
    theme: theme.Theme = .{},
}{};

var pass_action: sg.PassAction = .{};
var gpa = std.heap.GeneralPurposeAllocator(.{}){};

export fn init() void {
    sg.setup(.{ .environment = sokol.glue.environment() });
    simgui.setup(.{});
    theme.apply(&state.theme);
    pass_action.colors[0] = .{ .load_action = .CLEAR, .clear_value = .{ .r = 0.1, .g = 0.1, .b = 0.2, .a = 1.0 } };
    std.mem.copyForwards(u8, &state.player.name, "Hero");
    state.player.pos = Vec3{ .x = 10, .y = 20, .z = 30 };
}

export fn frame() void {
    const w: f32 = @floatFromInt(sapp.width());
    const h: f32 = @floatFromInt(sapp.height());
    const mobile = w < 800;
    const header_h: f32 = 40;
    const footer_h: f32 = 30;

    // Layout
    if (!state.computed or state.last_w != sapp.width()) {
        const a = gpa.allocator();
        const content_h = h - header_h - footer_h;
        state.info = Widget{ .box = .{ .w = if (mobile) w else 350, .h = if (mobile) 300 else content_h }, .sz = if (mobile) .{ .{ .t = .grow }, .{ .t = .fit, .mn = 300, .mx = 300 } } else .{ .{ .t = .fixed, .mn = 350, .mx = 350 }, .{ .t = .grow } }, .pad = .{ 10, 10, 10, 10 } };
        state.demo = Widget{ .box = .{ .w = if (mobile) w else w - 350 - 400, .h = if (mobile) 500 else content_h }, .sz = if (mobile) .{ .{ .t = .grow }, .{ .t = .fit, .mn = 500, .mx = 500 } } else .{ .{ .t = .grow }, .{ .t = .grow } }, .pad = .{ 10, 10, 10, 10 } };
        state.theme_editor = Widget{ .box = .{ .w = if (mobile) w else 400, .h = if (mobile) 400 else content_h }, .sz = if (mobile) .{ .{ .t = .grow }, .{ .t = .fit, .mn = 400, .mx = 400 } } else .{ .{ .t = .fixed, .mn = 400, .mx = 400 }, .{ .t = .grow } }, .pad = .{ 10, 10, 10, 10 } };
        state.kids = [_]*Widget{ &state.info, &state.demo, &state.theme_editor };
        state.root = Widget{ .box = .{ .w = w, .h = content_h }, .sz = .{ .{ .t = .fixed, .mn = w, .mx = w }, .{ .t = .fixed, .mn = content_h, .mx = content_h } }, .dir = if (mobile) .v else .h, .gap = 10, .pad = .{ 10, 10, 10, 10 }, .kids = &state.kids };
        ui.layout.Layout(Widget).calc(a, &state.root) catch {};
        state.computed = true;
        state.last_w = sapp.width();
    }

    simgui.newFrame(.{ .width = sapp.width(), .height = sapp.height(), .delta_time = sapp.frameDuration() });

    // Fullscreen invisible window
    ig.igSetNextWindowPos(.{ .x = 0, .y = 0 }, ig.ImGuiCond_Always);
    ig.igSetNextWindowSize(.{ .x = w, .y = h }, ig.ImGuiCond_Always);
    const flags = ig.ImGuiWindowFlags_NoTitleBar | ig.ImGuiWindowFlags_NoResize | ig.ImGuiWindowFlags_NoMove | ig.ImGuiWindowFlags_NoCollapse | ig.ImGuiWindowFlags_NoBackground | ig.ImGuiWindowFlags_NoScrollbar | ig.ImGuiWindowFlags_NoScrollWithMouse;
    _ = ig.igBegin("##main", null, flags);

    // Header
    ig.igSetCursorPos(.{ .x = 10, .y = 10 });
    ig.igTextColored(.{ .x = 0.4, .y = 0.8, .z = 1.0, .w = 1.0 }, "UI Module Demo");
    const fps = ig.igGetIO().*.Framerate;
    ig.igSetCursorPos(.{ .x = w - 80, .y = 10 });
    ig.igText("%.1f FPS", fps);

    // Footer
    ig.igSetCursorPos(.{ .x = 10, .y = h - 20 });
    ig.igText("Made with Zig + Sokol + ImGui");

    // Info panel
    const ib = state.info.box;
    ig.igSetCursorPos(.{ .x = ib.x, .y = ib.y + header_h });
    _ = ig.igBeginChild("##info", .{ .x = ib.w, .y = ib.h }, 0, ig.ImGuiWindowFlags_NoScrollbar);
    ig.igTextColored(.{ .x = 0.4, .y = 0.8, .z = 1.0, .w = 1.0 }, "UI MODULE");
    ig.igSeparator();

    if (ig.igCollapsingHeader("ui.layout", ig.ImGuiTreeNodeFlags_DefaultOpen)) {
        ig.igBulletText("Clay constraint layout");
        ig.igBulletText("222 lines");
    }
    if (ig.igCollapsingHeader("ui.reflect", ig.ImGuiTreeNodeFlags_DefaultOpen)) {
        ig.igBulletText("Auto widgets");
        ig.igBulletText("107 lines");
    }
    ig.igSeparator();

    ig.igText("Window: %dx%d", sapp.width(), sapp.height());
    const mode: [*:0]const u8 = if (mobile) "Mobile" else "Desktop";
    ig.igText("Mode: %s", mode);
    if (!mobile) ig.igDummy(.{ .x = 0, .y = ig.igGetContentRegionAvail().y });
    ig.igEndChild();

    // Demo panel
    const db = state.demo.box;
    ig.igSetCursorPos(.{ .x = db.x, .y = db.y + header_h });
    _ = ig.igBeginChild("##demo", .{ .x = db.w, .y = db.h }, 0, ig.ImGuiWindowFlags_NoScrollbar);
    ig.igTextColored(.{ .x = 0.4, .y = 0.8, .z = 1.0, .w = 1.0 }, "REFLECTION");
    ig.igSeparator();
    if (ig.igCollapsingHeader("Primitives", ig.ImGuiTreeNodeFlags_DefaultOpen)) {
        _ = ui.reflect.input("Integer", &state.int);
        _ = ui.reflect.input("Float", &state.float);
        _ = ui.reflect.input("Boolean", &state.bool);
    }
    if (ig.igCollapsingHeader("Enums", ig.ImGuiTreeNodeFlags_None)) {
        _ = ui.reflect.input("Quality", &state.quality);
    }
    if (ig.igCollapsingHeader("Structs", ig.ImGuiTreeNodeFlags_None)) {
        _ = ui.reflect.input("Vec3", &state.vec);
    }
    if (ig.igCollapsingHeader("Nested", ig.ImGuiTreeNodeFlags_None)) {
        _ = ui.reflect.input("Player", &state.player);
    }

    if (!mobile) ig.igDummy(.{ .x = 0, .y = ig.igGetContentRegionAvail().y });
    ig.igEndChild();

    // Theme Editor panel
    const tb = state.theme_editor.box;
    ig.igSetCursorPos(.{ .x = tb.x, .y = tb.y + header_h });
    _ = ig.igBeginChild("##theme", .{ .x = tb.w, .y = tb.h }, 0, ig.ImGuiWindowFlags_NoScrollbar);
    ig.igTextColored(.{ .x = 0.4, .y = 0.8, .z = 1.0, .w = 1.0 }, "THEME EDITOR");
    ig.igSeparator();
    if (ui.reflect.input("Theme", &state.theme).changed) theme.apply(&state.theme);
    if (!mobile) ig.igDummy(.{ .x = 0, .y = ig.igGetContentRegionAvail().y });
    ig.igEndChild();

    ig.igEnd();

    sg.beginPass(.{ .action = pass_action, .swapchain = sokol.glue.swapchain() });
    simgui.render();
    sg.endPass();
    sg.commit();
}

export fn cleanup() void {
    simgui.shutdown();
    sg.shutdown();
}

export fn event(e: [*c]const sapp.Event) void {
    _ = simgui.handleEvent(e.*);
}

pub fn main() void {
    sapp.run(.{ .init_cb = init, .frame_cb = frame, .cleanup_cb = cleanup, .event_cb = event, .width = 1280, .height = 720, .window_title = "UI Module Demo", .icon = .{ .sokol_default = true }, .swap_interval = 0 });
}

const std = @import("std");
const zfx = @import("zfx");
const ig = zfx.imgui;
const theme = @import("theme.zig");
const demo = @import("demo.zig");

const Widget = zfx.ui.Widget;

const Panel = union(enum) {
    welcome,
    style: *theme.Theme,
    types: *demo.Demo,
    colors: *theme.Theme,
};

var pass_action: zfx.sokol.gfx.PassAction = .{};
var current_theme: theme.Theme = .{};
var demo_data: demo.Demo = .{};
var current_panel: Panel = .welcome;

var root: Widget = undefined;
var left: Widget = undefined;
var right: Widget = undefined;
var children: [2]*Widget = undefined;
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
        left = .{ .size = .{ 200, h }, .sz = .{ .{ .mode = .fixed, .min = 200, .max = 200 }, .{ .mode = .grow } } };
        right = .{ .size = .{ w - 200, h }, .sz = .{ .{ .mode = .grow }, .{ .mode = .grow } } };
        children = [_]*Widget{ &left, &right };
        root = .{ .size = .{ w, h }, .sz = .{ .{ .mode = .fixed, .min = w, .max = w }, .{ .mode = .fixed, .min = h, .max = h } }, .dir = .h, .children = &children };
        zfx.ui.layout(&root);
        last_width = curr_width;
        last_height = curr_height;
    }

    zfx.sokol.imgui.newFrame(.{ .width = zfx.sokol.app.width(), .height = zfx.sokol.app.height(), .delta_time = zfx.sokol.app.frameDuration() });

    // Navigation sidebar (left panel)
    ig.igSetNextWindowPos(.{ .x = left.pos[0], .y = left.pos[1] }, ig.ImGuiCond_Always);
    ig.igSetNextWindowSize(.{ .x = left.size[0], .y = left.size[1] }, ig.ImGuiCond_Always);
    _ = ig.igBegin("Navigation", null, ig.ImGuiWindowFlags_NoResize | ig.ImGuiWindowFlags_NoMove | ig.ImGuiWindowFlags_NoCollapse);

    if (ig.igButton("Welcome")) current_panel = .welcome;
    if (ig.igButton("Style Editor")) current_panel = .{ .style = &current_theme };
    if (ig.igButton("Type Demo")) current_panel = .{ .types = &demo_data };
    if (ig.igButton("Color Editor")) current_panel = .{ .colors = &current_theme };

    ig.igEnd();

    // Content panel (right panel)
    ig.igSetNextWindowPos(.{ .x = right.pos[0], .y = right.pos[1] }, ig.ImGuiCond_Always);
    ig.igSetNextWindowSize(.{ .x = right.size[0], .y = right.size[1] }, ig.ImGuiCond_Always);

    switch (current_panel) {
        .welcome => {
            _ = ig.igBegin("Welcome", null, ig.ImGuiWindowFlags_NoResize | ig.ImGuiWindowFlags_NoMove | ig.ImGuiWindowFlags_NoCollapse);
            ig.igTextWrapped("Welcome to the zfx reflection demo!");
            ig.igSpacing();
            ig.igTextWrapped("This demo showcases automatic UI generation via compile-time reflection.");
            ig.igSpacing();
            ig.igSeparator();
            ig.igSpacing();
            ig.igTextWrapped("Features:");
            ig.igBulletText("Style Editor - Modify ImGui style properties");
            ig.igBulletText("Type Demo - Interactive widgets for all Zig types");
            ig.igBulletText("Color Editor - Customize ImGui color scheme");
            ig.igSpacing();
            ig.igSeparator();
            ig.igSpacing();
            ig.igTextWrapped("The reflection system automatically generates appropriate widgets for:");
            ig.igBulletText("Primitives: int, float, bool");
            ig.igBulletText("Enums: combo boxes");
            ig.igBulletText("Structs: collapsible trees");
            ig.igBulletText("Arrays & Slices: indexed lists");
            ig.igBulletText("Vectors: multi-component inputs");
            ig.igBulletText("Optionals: nullable values");
            ig.igBulletText("Unions: variant selectors");
            ig.igBulletText("Function pointers: executable buttons");
            ig.igEnd();
        },
        .style => |t| {
            _ = ig.igBegin("Style Editor", null, ig.ImGuiWindowFlags_NoResize | ig.ImGuiWindowFlags_NoMove | ig.ImGuiWindowFlags_NoCollapse);
            inline for (comptime std.meta.fields(@TypeOf(t.style))) |field| {
                const field_label = field.name ++ "\x00";
                const r = zfx.reflect.widget(@ptrCast(field_label.ptr), &@field(t.style, field.name));
                if (r.changed) theme.apply(t);
            }
            ig.igEnd();
        },
        .types => |d| {
            _ = ig.igBegin("Type Demo", null, ig.ImGuiWindowFlags_NoResize | ig.ImGuiWindowFlags_NoMove | ig.ImGuiWindowFlags_NoCollapse);
            _ = zfx.reflect.widget("demo", d);
            ig.igEnd();
        },
        .colors => |t| {
            _ = ig.igBegin("Color Editor", null, ig.ImGuiWindowFlags_NoResize | ig.ImGuiWindowFlags_NoMove | ig.ImGuiWindowFlags_NoCollapse);
            inline for (comptime std.meta.fields(@TypeOf(t.colors))) |field| {
                const field_label = field.name ++ "\x00";
                const r = zfx.reflect.widget(@ptrCast(field_label.ptr), &@field(t.colors, field.name));
                if (r.changed) theme.apply(t);
            }
            ig.igEnd();
        },
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
        .width = 1200,
        .height = 800,
        .window_title = "zfx demo",
    });
}

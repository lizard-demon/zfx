const ig = @import("zfx").imgui;

pub const Vec2 = struct { x: f32 = 0, y: f32 = 0 };
pub const Color = struct { r: f32 = 0, g: f32 = 0, b: f32 = 0, a: f32 = 1 };

pub const StyleVars = struct {
    alpha: f32 = 1.0,
    disabled_alpha: f32 = 1.0,
    window_padding: Vec2 = .{ .x = 12.0, .y = 12.0 },
    window_rounding: f32 = 0.0,
    window_border_size: f32 = 0.0,
    child_rounding: f32 = 0.0,
    child_border_size: f32 = 1.0,
    popup_rounding: f32 = 0.0,
    popup_border_size: f32 = 1.0,
    frame_padding: Vec2 = .{ .x = 20.0, .y = 3.4 },
    frame_rounding: f32 = 11.9,
    frame_border_size: f32 = 0.0,
    item_spacing: Vec2 = .{ .x = 4.3, .y = 5.5 },
    item_inner_spacing: Vec2 = .{ .x = 7.1, .y = 1.8 },
    indent_spacing: f32 = 20.0,
    scrollbar_size: f32 = 11.6,
    scrollbar_rounding: f32 = 15.9,
    grab_min_size: f32 = 3.7,
    grab_rounding: f32 = 20.0,
    tab_rounding: f32 = 0.0,
};

pub const Colors = struct {
    text: Color = .{ .r = 1.0, .g = 1.0, .b = 1.0, .a = 1.0 },
    text_disabled: Color = .{ .r = 0.27, .g = 0.32, .b = 0.45, .a = 1.0 },
    window_bg: Color = .{ .r = 0.078, .g = 0.086, .b = 0.102, .a = 1.0 },
    child_bg: Color = .{ .r = 0.093, .g = 0.100, .b = 0.116, .a = 1.0 },
    popup_bg: Color = .{ .r = 0.078, .g = 0.086, .b = 0.102, .a = 1.0 },
    border: Color = .{ .r = 0.157, .g = 0.169, .b = 0.192, .a = 1.0 },
    border_shadow: Color = .{ .r = 0.078, .g = 0.086, .b = 0.102, .a = 1.0 },
    frame_bg: Color = .{ .r = 0.112, .g = 0.126, .b = 0.155, .a = 1.0 },
    frame_bg_hovered: Color = .{ .r = 0.157, .g = 0.169, .b = 0.192, .a = 1.0 },
    frame_bg_active: Color = .{ .r = 0.157, .g = 0.169, .b = 0.192, .a = 1.0 },
    title_bg: Color = .{ .r = 0.047, .g = 0.055, .b = 0.071, .a = 1.0 },
    title_bg_active: Color = .{ .r = 0.047, .g = 0.055, .b = 0.071, .a = 1.0 },
    title_bg_collapsed: Color = .{ .r = 0.078, .g = 0.086, .b = 0.102, .a = 1.0 },
    scrollbar_bg: Color = .{ .r = 0.047, .g = 0.055, .b = 0.071, .a = 1.0 },
    scrollbar_grab: Color = .{ .r = 0.118, .g = 0.133, .b = 0.149, .a = 1.0 },
    scrollbar_grab_hovered: Color = .{ .r = 0.157, .g = 0.169, .b = 0.192, .a = 1.0 },
    scrollbar_grab_active: Color = .{ .r = 0.118, .g = 0.133, .b = 0.149, .a = 1.0 },
    check_mark: Color = .{ .r = 0.973, .g = 1.0, .b = 0.498, .a = 1.0 },
    slider_grab: Color = .{ .r = 0.972, .g = 1.0, .b = 0.498, .a = 1.0 },
    slider_grab_active: Color = .{ .r = 1.0, .g = 0.795, .b = 0.498, .a = 1.0 },
    button: Color = .{ .r = 0.118, .g = 0.133, .b = 0.149, .a = 1.0 },
    button_hovered: Color = .{ .r = 0.182, .g = 0.190, .b = 0.197, .a = 1.0 },
    button_active: Color = .{ .r = 0.155, .g = 0.155, .b = 0.155, .a = 1.0 },
    header: Color = .{ .r = 0.141, .g = 0.163, .b = 0.206, .a = 1.0 },
    header_hovered: Color = .{ .r = 0.107, .g = 0.107, .b = 0.107, .a = 1.0 },
    header_active: Color = .{ .r = 0.078, .g = 0.086, .b = 0.102, .a = 1.0 },
    separator: Color = .{ .r = 0.129, .g = 0.148, .b = 0.193, .a = 1.0 },
    separator_hovered: Color = .{ .r = 0.157, .g = 0.184, .b = 0.251, .a = 1.0 },
    separator_active: Color = .{ .r = 0.157, .g = 0.184, .b = 0.251, .a = 1.0 },
};

pub const Theme = struct {
    style: StyleVars = .{},
    colors: Colors = .{},
};

pub fn apply(theme: *const Theme) void {
    const style = ig.igGetStyle();

    style.*.Alpha = theme.style.alpha;
    style.*.DisabledAlpha = theme.style.disabled_alpha;
    style.*.WindowPadding = .{ .x = theme.style.window_padding.x, .y = theme.style.window_padding.y };
    style.*.WindowRounding = theme.style.window_rounding;
    style.*.WindowBorderSize = theme.style.window_border_size;
    style.*.ChildRounding = theme.style.child_rounding;
    style.*.ChildBorderSize = theme.style.child_border_size;
    style.*.PopupRounding = theme.style.popup_rounding;
    style.*.PopupBorderSize = theme.style.popup_border_size;
    style.*.FramePadding = .{ .x = theme.style.frame_padding.x, .y = theme.style.frame_padding.y };
    style.*.FrameRounding = theme.style.frame_rounding;
    style.*.FrameBorderSize = theme.style.frame_border_size;
    style.*.ItemSpacing = .{ .x = theme.style.item_spacing.x, .y = theme.style.item_spacing.y };
    style.*.ItemInnerSpacing = .{ .x = theme.style.item_inner_spacing.x, .y = theme.style.item_inner_spacing.y };
    style.*.IndentSpacing = theme.style.indent_spacing;
    style.*.ScrollbarSize = theme.style.scrollbar_size;
    style.*.ScrollbarRounding = theme.style.scrollbar_rounding;
    style.*.GrabMinSize = theme.style.grab_min_size;
    style.*.GrabRounding = theme.style.grab_rounding;
    style.*.TabRounding = theme.style.tab_rounding;

    style.*.Colors[ig.ImGuiCol_Text] = .{ .x = theme.colors.text.r, .y = theme.colors.text.g, .z = theme.colors.text.b, .w = theme.colors.text.a };
    style.*.Colors[ig.ImGuiCol_TextDisabled] = .{ .x = theme.colors.text_disabled.r, .y = theme.colors.text_disabled.g, .z = theme.colors.text_disabled.b, .w = theme.colors.text_disabled.a };
    style.*.Colors[ig.ImGuiCol_WindowBg] = .{ .x = theme.colors.window_bg.r, .y = theme.colors.window_bg.g, .z = theme.colors.window_bg.b, .w = theme.colors.window_bg.a };
    style.*.Colors[ig.ImGuiCol_ChildBg] = .{ .x = theme.colors.child_bg.r, .y = theme.colors.child_bg.g, .z = theme.colors.child_bg.b, .w = theme.colors.child_bg.a };
    style.*.Colors[ig.ImGuiCol_PopupBg] = .{ .x = theme.colors.popup_bg.r, .y = theme.colors.popup_bg.g, .z = theme.colors.popup_bg.b, .w = theme.colors.popup_bg.a };
    style.*.Colors[ig.ImGuiCol_Border] = .{ .x = theme.colors.border.r, .y = theme.colors.border.g, .z = theme.colors.border.b, .w = theme.colors.border.a };
    style.*.Colors[ig.ImGuiCol_BorderShadow] = .{ .x = theme.colors.border_shadow.r, .y = theme.colors.border_shadow.g, .z = theme.colors.border_shadow.b, .w = theme.colors.border_shadow.a };
    style.*.Colors[ig.ImGuiCol_FrameBg] = .{ .x = theme.colors.frame_bg.r, .y = theme.colors.frame_bg.g, .z = theme.colors.frame_bg.b, .w = theme.colors.frame_bg.a };
    style.*.Colors[ig.ImGuiCol_FrameBgHovered] = .{ .x = theme.colors.frame_bg_hovered.r, .y = theme.colors.frame_bg_hovered.g, .z = theme.colors.frame_bg_hovered.b, .w = theme.colors.frame_bg_hovered.a };
    style.*.Colors[ig.ImGuiCol_FrameBgActive] = .{ .x = theme.colors.frame_bg_active.r, .y = theme.colors.frame_bg_active.g, .z = theme.colors.frame_bg_active.b, .w = theme.colors.frame_bg_active.a };
    style.*.Colors[ig.ImGuiCol_TitleBg] = .{ .x = theme.colors.title_bg.r, .y = theme.colors.title_bg.g, .z = theme.colors.title_bg.b, .w = theme.colors.title_bg.a };
    style.*.Colors[ig.ImGuiCol_TitleBgActive] = .{ .x = theme.colors.title_bg_active.r, .y = theme.colors.title_bg_active.g, .z = theme.colors.title_bg_active.b, .w = theme.colors.title_bg_active.a };
    style.*.Colors[ig.ImGuiCol_TitleBgCollapsed] = .{ .x = theme.colors.title_bg_collapsed.r, .y = theme.colors.title_bg_collapsed.g, .z = theme.colors.title_bg_collapsed.b, .w = theme.colors.title_bg_collapsed.a };
    style.*.Colors[ig.ImGuiCol_ScrollbarBg] = .{ .x = theme.colors.scrollbar_bg.r, .y = theme.colors.scrollbar_bg.g, .z = theme.colors.scrollbar_bg.b, .w = theme.colors.scrollbar_bg.a };
    style.*.Colors[ig.ImGuiCol_ScrollbarGrab] = .{ .x = theme.colors.scrollbar_grab.r, .y = theme.colors.scrollbar_grab.g, .z = theme.colors.scrollbar_grab.b, .w = theme.colors.scrollbar_grab.a };
    style.*.Colors[ig.ImGuiCol_ScrollbarGrabHovered] = .{ .x = theme.colors.scrollbar_grab_hovered.r, .y = theme.colors.scrollbar_grab_hovered.g, .z = theme.colors.scrollbar_grab_hovered.b, .w = theme.colors.scrollbar_grab_hovered.a };
    style.*.Colors[ig.ImGuiCol_ScrollbarGrabActive] = .{ .x = theme.colors.scrollbar_grab_active.r, .y = theme.colors.scrollbar_grab_active.g, .z = theme.colors.scrollbar_grab_active.b, .w = theme.colors.scrollbar_grab_active.a };
    style.*.Colors[ig.ImGuiCol_CheckMark] = .{ .x = theme.colors.check_mark.r, .y = theme.colors.check_mark.g, .z = theme.colors.check_mark.b, .w = theme.colors.check_mark.a };
    style.*.Colors[ig.ImGuiCol_SliderGrab] = .{ .x = theme.colors.slider_grab.r, .y = theme.colors.slider_grab.g, .z = theme.colors.slider_grab.b, .w = theme.colors.slider_grab.a };
    style.*.Colors[ig.ImGuiCol_SliderGrabActive] = .{ .x = theme.colors.slider_grab_active.r, .y = theme.colors.slider_grab_active.g, .z = theme.colors.slider_grab_active.b, .w = theme.colors.slider_grab_active.a };
    style.*.Colors[ig.ImGuiCol_Button] = .{ .x = theme.colors.button.r, .y = theme.colors.button.g, .z = theme.colors.button.b, .w = theme.colors.button.a };
    style.*.Colors[ig.ImGuiCol_ButtonHovered] = .{ .x = theme.colors.button_hovered.r, .y = theme.colors.button_hovered.g, .z = theme.colors.button_hovered.b, .w = theme.colors.button_hovered.a };
    style.*.Colors[ig.ImGuiCol_ButtonActive] = .{ .x = theme.colors.button_active.r, .y = theme.colors.button_active.g, .z = theme.colors.button_active.b, .w = theme.colors.button_active.a };
    style.*.Colors[ig.ImGuiCol_Header] = .{ .x = theme.colors.header.r, .y = theme.colors.header.g, .z = theme.colors.header.b, .w = theme.colors.header.a };
    style.*.Colors[ig.ImGuiCol_HeaderHovered] = .{ .x = theme.colors.header_hovered.r, .y = theme.colors.header_hovered.g, .z = theme.colors.header_hovered.b, .w = theme.colors.header_hovered.a };
    style.*.Colors[ig.ImGuiCol_HeaderActive] = .{ .x = theme.colors.header_active.r, .y = theme.colors.header_active.g, .z = theme.colors.header_active.b, .w = theme.colors.header_active.a };
    style.*.Colors[ig.ImGuiCol_Separator] = .{ .x = theme.colors.separator.r, .y = theme.colors.separator.g, .z = theme.colors.separator.b, .w = theme.colors.separator.a };
    style.*.Colors[ig.ImGuiCol_SeparatorHovered] = .{ .x = theme.colors.separator_hovered.r, .y = theme.colors.separator_hovered.g, .z = theme.colors.separator_hovered.b, .w = theme.colors.separator_hovered.a };
    style.*.Colors[ig.ImGuiCol_SeparatorActive] = .{ .x = theme.colors.separator_active.r, .y = theme.colors.separator_active.g, .z = theme.colors.separator_active.b, .w = theme.colors.separator_active.a };
}

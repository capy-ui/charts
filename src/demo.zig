const capy = @import("capy");
const charts = @import("charts");

pub usingnamespace capy.cross_platform;

pub fn main() !void {
    try capy.init();
    defer capy.deinit();

    var window = try capy.Window.init();
    defer window.deinit();
    try window.set(capy.column(.{}, .{
        capy.label(.{ .text = "Line graph" }),
        charts.line(.{}),
    }));
    window.show();

    capy.runEventLoop();
}

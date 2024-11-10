const std = @import("std");
const capy = @import("capy");
const charts = @import("charts");

pub usingnamespace capy.cross_platform;
var chart: *charts.Chart = undefined;
var prng = std.Random.DefaultPrng.init(0);

pub fn main() !void {
    try capy.init();
    defer capy.deinit();

    var dataset = charts.Dataset.init(capy.internal.lasting_allocator);
    defer dataset.deinit();
    for (1..20) |i| {
        const x = @as(f32, @floatFromInt(i)) / 2.0;
        try dataset.put(.{ .x = x, .y = 1.0 / x });
    }

    var line_chart = charts.LineChart.init(&dataset);

    var window = try capy.Window.init();
    defer window.deinit();

    chart = charts.line(.{
        .charts = &.{line_chart.chart()},
    });
    try window.set(capy.alignment(.{}, capy.column(.{}, .{
        capy.label(.{ .text = "Line graph", .layout = .{ .alignment = .Center } }),
        chart,
        capy.button(.{ .label = "add data", .onclick = @ptrCast(&addData) }),
    })));
    window.show();

    capy.runEventLoop();
}

fn addData(self: *capy.Button) !void {
    const line_chart: *charts.LineChart = @ptrCast(@alignCast(chart.charts.get(0).ctx));
    const random = prng.random();
    const x = random.float(f32) * 50;
    try line_chart.dataset.put(.{ .x = x, .y = x });
    chart.autoScale();
    try chart.requestDraw();
    _ = self;
}

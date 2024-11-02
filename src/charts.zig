const std = @import("std");
const capy = @import("capy");

pub const LineChart = struct {
    pub usingnamespace capy.internal.All(LineChart);

    peer: ?capy.backend.Canvas = null,
    widget_data: LineChart.WidgetData = .{},

    pub fn init(config: LineChart.Config) LineChart {
        var line_chart = LineChart.init_events(LineChart{});
        capy.internal.applyConfigStruct(&line_chart, config);
        line_chart.addDrawHandler(&LineChart.draw) catch unreachable;
        return line_chart;
    }

    pub fn draw(self: *LineChart, ctx: *capy.DrawContext) !void {
        const width = self.getWidth();
        const height = self.getHeight();

        // Draw a background for the graph
        ctx.setColor(1, 1, 1);
        ctx.rectangle(0, 0, width, height);
        ctx.fill();
    }

    pub fn getPreferredSize(self: *LineChart, available: capy.Size) capy.Size {
        _ = self;
        _ = available;
        return .{ .width = 500, .height = 200 };
    }

    pub fn show(self: *LineChart) !void {
        if (self.peer == null) {
            self.peer = try capy.backend.Canvas.create();
            try self.setupEvents();
        }
    }
};

pub fn line(config: LineChart.Config) *LineChart {
    return LineChart.alloc(config);
}

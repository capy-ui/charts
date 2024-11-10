const std = @import("std");
const capy = @import("capy");

pub const Dataset = @import("Dataset.zig");

const RenderOptions = struct {
    width: f32,
    height: f32,
    scale: Scale,

    pub const Scale = struct {
        x: f32,
        y: f32,
    };
};

pub const LineChart = struct {
    dataset: *Dataset,

    pub fn init(dataset: *Dataset) LineChart {
        return .{
            .dataset = dataset,
        };
    }

    pub fn draw(ptr: *anyopaque, options: RenderOptions, ctx: *capy.DrawContext) void {
        const self: *LineChart = @ptrCast(@alignCast(ptr));
        const width = options.width;
        const height = options.height;
        const scale = options.scale;
        _ = width;

        var previous: ?Dataset.Value = null;
        for (self.dataset.values.items) |value| {
            ctx.setColor(0, 0, 0);
            ctx.ellipse(
                @intFromFloat(value.x * scale.x - 5),
                @intFromFloat(height - (value.y * scale.y) - 5),
                10,
                10,
            );
            ctx.fill();
            if (previous) |prev| {
                ctx.line(
                    @intFromFloat(prev.x * scale.x),
                    @intFromFloat(height - prev.y * scale.y),
                    @intFromFloat(value.x * scale.x),
                    @intFromFloat(height - value.y * scale.y),
                );
            }
            previous = value;
        }
    }

    pub fn getBoundingBox(ctx: *anyopaque) capy.Rectangle {
        const self: *LineChart = @ptrCast(@alignCast(ctx));

        var bbox = capy.Rectangle.init(0, 0, 0, 0);
        for (self.dataset.values.items) |value| {
            // TODO: just make intersection between rectangle and point
            const value_bbox = capy.Rectangle.init(
                value.x - 0.01,
                value.y - 0.01,
                value.x + 0.01,
                value.y + 0.01,
            );
            bbox = capy.Rectangle.combine(bbox, value_bbox);
        }

        return bbox;
    }

    pub fn chart(self: *LineChart) GenericChart {
        return .{
            .ctx = self,
            .vtable = &.{
                .draw = &draw,
                .getBoundingBox = &getBoundingBox,
            },
        };
    }
};

pub const GenericChart = struct {
    /// Type erased pointer to the chart's implementation
    ctx: *anyopaque,
    vtable: *const VTable,

    pub const VTable = struct {
        draw: *const fn (*anyopaque, RenderOptions, *capy.DrawContext) void,
        getBoundingBox: *const fn (*anyopaque) capy.Rectangle,
    };

    pub fn draw(self: GenericChart, options: RenderOptions, ctx: *capy.DrawContext) void {
        self.vtable.draw(self.ctx, options, ctx);
    }

    pub fn getBoundingBox(self: GenericChart) capy.Rectangle {
        return self.vtable.getBoundingBox(self.ctx);
    }
};

pub const Chart = struct {
    pub usingnamespace capy.internal.All(Chart);

    peer: ?capy.backend.Canvas = null,
    widget_data: Chart.WidgetData = .{},
    charts: capy.ListAtom(GenericChart),
    /// The component's window into the different plots, expressed in the dataset's coordinate
    /// system.
    window: capy.Atom(capy.Rectangle) = capy.Atom(capy.Rectangle).of(capy.Rectangle.init(0, 0, 0, 0)),

    pub fn init(config: Chart.Config) Chart {
        var chart = Chart.init_events(Chart{
            .charts = capy.ListAtom(GenericChart).init(capy.internal.lasting_allocator),
        });
        capy.internal.applyConfigStruct(&chart, config);
        chart.addDrawHandler(&Chart.draw) catch unreachable;
        return chart;
    }

    /// Auto-scales the chart's window so as to fit every plot on the component.
    /// If there are plots, this function does nothing.
    pub fn autoScale(self: *Chart) void {
        var new_window: ?capy.Rectangle = null;

        // Set the new window to be the union of all the plots' bounding box
        var iterator = self.charts.iterate();
        while (iterator.next()) |chart| {
            const bbox = chart.getBoundingBox();
            if (new_window) |*window| {
                window.* = capy.Rectangle.combine(window.*, bbox);
            } else {
                new_window = bbox;
            }
        }

        if (new_window) |window| {
            // Animate the new scale
            self.window.animate(self.getAnimationController(), capy.Easings.InOut, window, 1000);
        }
    }

    fn onWindowAtomChange(_: capy.Rectangle, userdata: ?*anyopaque) void {
        const self: *Chart = @ptrCast(@alignCast(userdata));
        self.requestDraw() catch {};
    }

    pub fn draw(self: *Chart, ctx: *capy.DrawContext) !void {
        const width = self.getWidth();
        const height = self.getHeight();
        const widthf: f32 = @floatFromInt(width);
        const heightf: f32 = @floatFromInt(height);

        // Draw the background for the graph
        ctx.setColor(1, 1, 1);
        ctx.rectangle(0, 0, width, height);
        ctx.fill();

        // Adjust the scale
        const window = self.window.get();
        if (window.width() == 0 or window.height() == 0) {
            // Schedule auto-scale and return.
            if (!self.window.hasAnimation()) {
                self.autoScale();
            }
            return;
        }
        const x_scale: f32 = widthf / window.width();
        const y_scale: f32 = heightf / window.height();

        const render_options = RenderOptions{
            .width = widthf,
            .height = heightf,
            .scale = .{
                .x = x_scale,
                .y = y_scale,
            },
        };

        {
            var iterator = self.charts.iterate();
            while (iterator.next()) |chart| {
                chart.draw(render_options, ctx);
            }
        }
    }

    pub fn getPreferredSize(self: *Chart, available: capy.Size) capy.Size {
        _ = self;
        _ = available;
        return .{ .width = 500, .height = 500 };
    }

    pub fn show(self: *Chart) !void {
        if (self.peer == null) {
            self.peer = try capy.backend.Canvas.create();
            try self.setupEvents();
            _ = try self.window.addChangeListener(.{ .function = onWindowAtomChange, .userdata = self });
        }
    }
};

pub fn line(config: Chart.Config) *Chart {
    // TODO: add linechart renderer
    return Chart.alloc(config);
}

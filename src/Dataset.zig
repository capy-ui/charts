//! A Dataset stores a graph's data points and properties associated to them.
//!
//! This is implemented using an ArrayList for X and Y values, and HashMap for properties. Moreover,
//! for optimization, the Dataset is always sorted by X values, which allows for faster rendering.
const std = @import("std");
const capy = @import("capy");
const Dataset = @This();

pub const Value = struct {
    /// The label that the data point takes.
    label: ?[]const u8 = null,
    /// This field only applies to scatter charts, in which case this indicates the radius of the
    /// data point's circle.
    radius: ?f32 = null,
    /// The background color of the point.
    background_color: ?capy.Color = null,
    x: f32,
    y: f32,
};

// TODO: implement with a mix of ArrayList and HashMap
// TODO: for XY values specifically, use SegmentedList, as it allows for much faster insertion at
// specific points (being O(1) instead of O(n)) which is good for keeping the list always sorted.
values: std.ArrayList(Value),
/// The label of the data set. This is used with most graph types for naming the data series.
label: ?[]const u8 = null,

pub fn init(allocator: std.mem.Allocator) Dataset {
    return .{
        .values = std.ArrayList(Value).init(allocator),
    };
}

pub fn put(self: *Dataset, value: Value) !void {
    try self.values.append(value);
    std.mem.sortUnstable(Value, self.values.items, {}, struct {
        fn lessThan(_: void, a: Value, b: Value) bool {
            return a.x < b.x;
        }
    }.lessThan);
}

/// Convenience function for adding values to the dataset in bulk, using the given X and Y slices.
/// The values will only have default properties set.
pub fn putXYSlice(self: *Dataset, xs: []const f32, ys: []const f32) !void {
    std.debug.assert(xs.len == ys.len);
    for (xs, ys) |x, y| {
        try self.put(.{ .x = x, .y = y });
    }
}

pub fn deinit(self: *Dataset) void {
    self.values.deinit();
}

test "dataset creation" {
    var dataset = Dataset.init(std.testing.allocator);
    defer dataset.deinit();

    try dataset.put(.{ .x = 1, .y = 1 });
    try dataset.put(.{ .x = 0.5, .y = 2 });
    try dataset.put(.{ .x = 0.25, .y = 4 });
    try dataset.putXYSlice(&.{ 5, 6, 7, 2 }, &.{ 0, 1, 2, -3 });
}

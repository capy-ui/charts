const std = @import("std");
const build_capy = @import("capy");

pub fn build(b: *std.Build) !void {
    const target = b.standardTargetOptions(.{});
    const optimize = b.standardOptimizeOption(.{});

    const capy_dep = b.dependency("capy", .{
        .target = target,
        .optimize = optimize,
        .app_name = @as([]const u8, "capy-charts"),
    });
    const capy = capy_dep.module("capy");

    const module = b.addModule("charts", .{
        .root_source_file = b.path("src/charts.zig"),
        .target = target,
        .optimize = optimize,
        .imports = &.{
            .{ .name = "capy", .module = capy },
        },
    });

    const exe = b.addExecutable(.{
        .name = "capy-charts-demo",
        .root_source_file = b.path("src/demo.zig"),
        .target = target,
        .optimize = optimize,
    });
    exe.root_module.addImport("capy", capy);
    exe.root_module.addImport("charts", module);
    b.installArtifact(exe);

    const run_cmd = try build_capy.runStep(exe, .{ .args = b.args });
    const run_step = b.step("demo", "Run the demo");
    run_step.dependOn(run_cmd);

    // Creates a step for unit testing. This only builds the test executable
    // but does not run it.
    const unit_tests = b.addTest(.{
        .root_source_file = b.path("src/root.zig"),
        .target = target,
        .optimize = optimize,
    });
    const run_unit_tests = b.addRunArtifact(unit_tests);
    const test_step = b.step("test", "Run unit tests");
    test_step.dependOn(&run_unit_tests.step);
}
